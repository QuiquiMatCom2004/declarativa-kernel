# Especificación del Proyecto: Kernel Mínimo de Teoremas (Mini-Lean Kernel)

**Curso**: Programación Declarativa
**Lenguaje objetivo**: SWI-Prolog (recomendado) / Haskell / OCaml
**Alcance**: Solo **Kernel** (núcleo de confianza) — extensible a motor de tácticas posterior

---

> **Mapa de documentos**: esta es la especificación global. Cada regla que compone el kernel
> tiene su propio mini-`.md` en [`reglas/`](reglas/) — índice: [`reglas/README.md`](reglas/README.md).
> Para entender el proyecto completo léelos en orden; para implementar una regla, léela aislada.

---

## 1. Objetivo

Implementar un **kernel de tipo de tipos dependientes** (basado en *Calculus of Inductive Constructions* simplificado) capaz de:

- Verificar términos bien tipados en un lenguaje core mínimo
- Realizar conversión definicional (βδιζη) via **Normalization by Evaluation (NbE)**
- Soportar **tipos inductivos** (Nat, List, Vec, Σ, Π) con *pattern matching* compilado a recursores primitivos
- Servir como *trusted code base* (TCB) mínimo sobre el que luego se pueda construir un elaborador y motor de tácticas

**Filosofía**: El kernel **solo verifica**. No infiere, no resuelve implícitos, no hace typeclass resolution. Recibe términos *totalmente anotados* (explicit substitutions) y responde `ok` / `error` con traza.

---

## 2. Lenguaje Core (Sintaxis Abstracta)

```prolog
% Términos core (de Bruijn indices para bound vars)
term ::
  | Var(n)                    % variable de Bruijn (n ≥ 0)
  | Sort(u)                   % universo: Type u (u ∈ ℕ)
  | Pi(dom, cod)              % Π (x : dom), cod   — cod tiene x libre (índice 0)
  | Lam(body)                 % λ x. body          — body tiene x libre (índice 0)
  | App(fn, arg)              % fn arg
  | Sigma(dom, cod)           % Σ (x : dom), cod
  | Pair(fst, snd)            % (fst, snd)
  | Fst(p)                    % p.1
  | Snd(p)                    % p.2
  | Inductive(name, params)   % tipo inductivo aplicado: Nat, List A, Vec A n
  | Constructor(name, args)   % constructor aplicado: zero, succ n, nil, cons a as
  | Case(scrut, motives, branches)  % case scrut of { branches }
  | Let(binding, body)        % let x := binding in body  (desazucarado en kernel opcional)

% Contexto: lista de (nombre, tipo) — nombres solo para pretty-printing
context ::= [] | [(name, term)] ++ context
```

### Restricciones de bien formación (kernel las verifica)

1. **Universalidad**: `Sort u : Sort (u+1)` — no `Type 0 : Type 0`
2. **Π-formation**: `Γ ⊢ A : Type u`  y  `Γ, A ⊢ B : Type v`  ⇒  `Γ ⊢ Π A B : Type (max u v)`
3. **Λ-intro**: `Γ, A ⊢ b : B`  ⇒  `Γ ⊢ λ b : Π A B`
4. **App-elim**: `Γ ⊢ f : Π A B`  y  `Γ ⊢ a : A`  ⇒  `Γ ⊢ f a : B[a/0]` (sustitución)
5. **Inductivos**: Declarados *a priori* en **signature** (ver §3). Cada constructor tiene tipo `Π params. Π args. Inductive name params`
6. **Case**: `scrut : Inductive I ps`, cada rama `c_i args_i → motive_i` donde `motive_i` puede depender de `scrut` (pattern matching dependiente)

---

## 3. Signature de Inductivos (Hardcoded en Kernel MVP)

El kernel incluye una **tabla fija** de inductivos primitivos. No hay `data`/`inductive` definidos por usuario en el MVP.

| Nombre | Parámetros | Constructores (tipo) |
|--------|------------|---------------------|
| `Nat` | `[]` | `zero : Nat`<br>`succ : Nat → Nat` |
| `List` | `[A : Type u]` | `nil : List A`<br>`cons : A → List A → List A` |
| `Vec` | `[A : Type u]` | `vnil : Vec A zero`<br>`vcons : Π (n : Nat). A → Vec A n → Vec A (succ n)` |
| `Sigma` | `[A : Type u, B : A → Type v]` | `mk : Π (a : A). B a → Sigma A B` |
| `Unit` | `[]` | `unit : Unit` |
| `Empty` | `[]` | *(ninguno)* |
| `Bool` | `[]` | `true : Bool`<br>`false : Bool` |
| `Prod` | `[A : Type u, B : Type v]` | `mk : A → B → Prod A B` |

> **Nota**: `Pi`, `Sigma`, `Vec` etc. son *constructores de tipos* en el kernel, no sintaxis surface. El surface syntax (elaborador futuro) los mapea aquí.

### Recursores primitivos (generados automáticamente por kernel)

Para cada inductivo `I`, el kernel proporciona un **recursor** `I.rec` con tipo:

```
I.rec : Π (motive : I params → Type u).
         (∀ (c : constructors I). Π (args : c.args). motive (c args)) →
         Π (x : I params). motive x
```

El `Case` se **compila** a aplicación del recursor (ver §5.3). El kernel **verifica** que las ramas cubran todos los constructores (exhaustividad) y que los motivos sean bien tipados.

---

## 4. Algoritmo de Type Checking (Bidireccional)

### Juicios

```
Γ ⊢ t ⇐ T    (checking: t tiene tipo T esperado)
Γ ⊢ t ⇒ T    (inference: t sintetiza tipo T)
Γ ⊢ T type   (T es un tipo válido en Γ)
Γ ⊢ t ≡ u    (conversión definicional)
```

### Reglas principales (pseudocódigo)

```prolog
% INFERENCE
infer(Γ, Sort(u), Sort(u+1)).
infer(Γ, Var(i), T) :- nth_type(Γ, i, T).
infer(Γ, Pi(A,B), Sort(max(u,v))) :- check(Γ, A, Sort(u)), infer(Γ, B, Sort(v)).
infer(Γ, Lam(body), Pi(A,B)) :- infer(Γ, A, Sort(u)), check([A|Γ], body, B).
infer(Γ, App(f,a), Bsubst) :- infer(Γ, f, Pi(A,B)), check(Γ, a, A), substitute(B, a, Bsubst).
infer(Γ, Constructor(c, args), T) :-
    constructor_type(c, Tcon),  % Tcon = Π params. Π args. Inductive ...
    check_args(Γ, args, Tcon, T).  % unifica params + args, devuelve tipo resultante
infer(Γ, Inductive(name, params), Sort(u)) :-
    inductive_sort(name, u), check_args(Γ, params, ...).
infer(Γ, Case(scrut, motive, branches), motive_applied) :-
    infer(Γ, scrut, Inductive(I, ps)),
    check_motive(Γ, scrut, motive),
    check_branches(Γ, I, ps, scrut, motive, branches),
    apply_motive(motive, scrut, motive_applied).

% CHECKING
check(Γ, t, T) :- infer(Γ, t, Tinf), conversion(Γ, Tinf, T).
check(Γ, Lam(body), Pi(A,B)) :- check(Γ, A, Sort(_)), check([A|Γ], body, B).
check(Γ, Pair(a,b), Sigma(A,B)) :- check(Γ, a, A), check(Γ, b, substitute(B, a, _)).
check(Γ, Case(scrut, motive, branches), T) :-
    infer(Γ, scrut, Inductive(I, ps)),
    check_motive(Γ, scrut, motive),
    check_branches(Γ, I, ps, scrut, motive, branches),
    conversion(Γ, apply_motive(motive, scrut), T).

% CONVERSIÓN (NbE)
conversion(Γ, t, u) :- nbe(Γ, t, Vt), nbe(Γ, u, Vu), Vt == Vu.
```

### Normalization by Evaluation (NbE)

**Dominio semántico** (valores):

```prolog
value ::
  | VSort(u)
  | VPi(Vdom, Vcod_closure)     % Vcod_closure = closure(Γ, cod)
  | VLam(closure)               % closure(Γ, body)
  | VNeutral(n, spine)          % cabeza neutra (var, constructor, fst, snd) + espina de args
  | VInductive(name, params_v)
  | VConstructor(name, args_v)
  | VPair(v1, v2)
  | VCase(scrut_v, motive_v, branches_v)  % case atascado en scrut neutro
```

**Funciones clave**:

- `eval(Γ, t) → value` — evaluación en entorno
- `reify(T, v) → term` — reificación (quote) de valor a forma normal βδιζη
- `reflect(T, t) → value` — reflexión (unquote) de término neutro a valor
- `nbe(Γ, t, nf) :- eval(Γ, t, v), reify(infer_type(Γ,t), v, nf).`

**η-expansión** (para Π, Σ, inductivos):
- `reify(Pi(A,B), VPi(Vdom, Vcod))` → `Pi(A_nf, Lam(body_nf))` donde `body_nf = reify(B, Vcod(quote_fresh_var))`
- Análogamente para Σ, inductivos (η para registros: `mk (fst p) (snd p) ≡ p`)

---

## 5. Módulos del Kernel (Arquitectura Prolog)

```
kernel/
├── kernel.pl              % Entry point: check(Module, Term, Type) / infer / convert
├── syntax.pl              % term, context, signature (hechos estáticos)
├── bidirectional.pl       % check/3, infer/3, check_args/4, check_branches/5
├── nbe.pl                 % eval/3, reify/3, reflect/3, nbe/3
├── substitution.pl        % substitute/3, shift/3, compose/3 (de Bruijn)
├── inductive.pl           % signature_inductive/3, constructor_type/2,
                           % recursor_type/2, compile_case_to_recursor/3,
                           % coverage_check/2
├── conversion.pl          % conversion/3 (usa nbe), definitional_eq/3
├── errors.pl              % error(Code, Msg, Location), pretty_error/2
├── parser.pl              % DCG para sintaxis surface → core (mínimo: solo para tests)
└── test_kernel.pl         % Suite de tests (ver §7)
```

### Principales predicados exportados

```prolog
% API pública
:- module(kernel, [
    check/4,           % check(+Ctx, +Term, +Type, -ErrorOrOk)
    infer/3,           % infer(+Ctx, +Term, -Type)
    convert/4,         % convert(+Ctx, +Term1, +Term2, -ErrorOrOk)
    nbe/3,             % nbe(+Ctx, +Term, -NormalForm)
    well_formed_ctx/1, % well_formed_ctx(+Ctx)
    inductive_signature/1  % inductive_signature(-Sig) para introspección
]).
```

---

## 6. Hitos y Entregables (Solo Kernel)

| Hito | Semana | Entregable | Criterio de aceptación |
|------|--------|------------|------------------------|
| **H0** | 1 | `syntax.pl`, `substitution.pl` | Tests unitarios de shift/substitute/de Bruijn |
| **H1** | 2 | `nbe.pl` (eval/reify/reflect para Π, λ, Sort, Var) | `nbe([], Lam(Var(0)), Lam(Var(0)))` — identidad |
| **H2** | 2-3 | `bidirectional.pl` (check/infer para Π, λ, App, Sort, Var) | `check([], Lam(Var(0)), Pi(Sort(0), Sort(0)), ok)` |
| **H3** | 3 | `inductive.pl` (signature fija, constructor_type, recursor_type) | `infer([], Constructor(zero, []), Nat)` |
| **H4** | 4 | `Case` + compilación a recursor + coverage check | `Case(Var(0), ..., [zero→_, succ→_])` compila y typecheckea |
| **H5** | 4 | `conversion.pl` (NbE completo con η para Π, Σ, inductivos) | `convert([], App(Lam(Var(0)), t), t, ok)` |
| **H6** | 5 | `errors.pl` + pretty printing + test suite completa | Todos tests pasan; errores legibles con ubicación |
| **H7** | 5 | **Demo final**: `Vec` + `append` + prueba `length (append xs ys) = length xs + length ys` verificada | Kernel acepta término de prueba completo |

---

## 7. Suite de Tests Mínima (kernel/test_kernel.pl)

```prolog
% Cada test: test(Name, Condition) :- ...
% Ejecutar: run_tests.

% --- Básicos ---
test(id_type) :- check([], Sort(0), Sort(1), ok).
test(var) :- check([(x, Sort(0))], Var(0), Sort(0), ok).

% --- Π / λ / App ---
test(pi_formation) :- check([], Pi(Sort(0), Sort(0)), Sort(1), ok).
test(lambda_intro) :- check([], Lam(Var(0)), Pi(Sort(0), Sort(0)), ok).
test(app_elim) :-
    check([], App(Lam(Var(0)), Sort(0)), Sort(0), ok).

% --- Conversión β ---
test(beta_reduce) :-
    nbe([], App(Lam(Var(0)), Sort(0)), Sort(0)).

% --- Nat ---
test(nat_zero) :- infer([], Constructor(zero, []), Nat).
test(nat_succ) :- infer([], Constructor(succ, [Constructor(zero, [])]), Nat).

% --- Inductivos: Case → recursor ---
test(case_nat_zero) :-
    Term = Case(Constructor(zero, []), Motive, [Branch(zero, []), Branch(succ, [Var(0))]]),
    check([], Term, MotiveApplied, ok).

% --- Vec (índice dependiente) ---
test(vec_vnil) :- infer([], Constructor(vnil, [A]), Vec A zero).
test(vec_vcons) :-
    infer([(A, Sort(0)), (n, Nat), (a, A), (as, Vec A n)],
          Constructor(vcons, [Var(2), Var(1), Var(0)]),
          Vec A (Constructor(succ, [Var(2)]))).

% --- Σ / Pair / Projections ---
test(sigma_formation) :- check([], Sigma(Sort(0), Lam(Sort(0))), Sort(1), ok).
test(pair_proj) :-
    check([], Fst(Constructor(mk, [Var(0), Var(1)])), A, ok).

% --- Errores esperados ---
test(universe_inconsistency, fail) :- check([], Sort(0), Sort(0), ok).
test(app_non_pi, fail) :- check([], App(Sort(0), Sort(0)), _, ok).
test(missing_case_branch, fail) :-
    % Case en Nat sin rama para succ
    check([], Case(Var(0), _, [Branch(zero, [])]), _, ok).
```

---

## 8. Extensión Futura: Motor de Tácticas (Opcional, Post-Kernel)

> **Este bloque NO es parte del entregable obligatorio**. Se documenta para que la arquitectura del kernel lo permita sin reescritura.

### 8.1 Interfaz Kernel → Tácticas

El kernel expone **solo** primitivas de construcción de términos verificados:

```prolog
% En kernel.pl (añadido para extensión)
% Construye un término *ya verificado* y devuelve su tipo
kernel_construct(:Goal, +Context, -Term, -Type).

% Aplica un constructor/lemma ya verificado a argumentos verificados
kernel_apply(+ConstructorTerm, +ArgTerms, -ResultTerm, -ResultType).

% Normaliza un término (para rw/simp)
kernel_nbe(+Term, -NormalForm).
```

### 8.2 Arquitectura del Motor de Tácticas (Capa Separada)

```
tactics/
├── tactic_monad.pl       % TacticM = StateT(Goals, Backtrack) — metainterpreter
├── goal.pl               % Goal = (ctx, target_type, metavars)
├── tactics/
│   ├── apply.pl          % apply : Lemma → TacticM
│   ├── rw.pl             % rw : Eq → TacticM (usa kernel_nbe + unificación)
│   ├── simp.pl           % simp : [Lemmas] → TacticM (rewrite system)
│   ├── induction.pl      % induction : Var → TacticM (genera Case + IH)
│   └── linarith.pl       % linarith : TacticM (usa clp(qr) nativo)
├── elaborator.pl         % Surface (con _, have, show) → Core + metavariables
├── typeclass.pl          % Resolución de typeclasses (Prolog nativo)
└── repl.pl               % REPL interactivo: goal → tácticas → proof term → kernel.check
```

### 8.3 Flujo de trabajo con tácticas

```
Usuario escribe:
  theorem add_comm : ∀ a b : Nat, a + b = b + a := by
    intro a b
    induction a with
    | zero => simp [add_zero]
    | succ a ih => simp [add_succ, ih]
    <;> linarith

Elaborador → genera meta-término con holes (_)
Tácticas → resuelven holes, construyen proof term core
Kernel → check(proof_term, theorem_type) = ok
```

### 8.4 Requisitos del Kernel para soportar tácticas

1. **Metavariables** (`?m`) en términos core — kernel las trata como *variables libres* con tipo conocido; `check` acepta términos con metas si el resto typecheckea.
2. **Unificación de metas** — expuesta via `kernel_unify_meta(+MetaVar, +Term)`.
3. **Sustitución de metas resueltas** — `kernel_subst_metas(+Term, -TermResuelto)`.
4. **Inferencia de tipo de metas** — `kernel_meta_type(+MetaVar, -Type)`.

> **Decisión de diseño**: El kernel **no** gestiona metas. El motor de tácticas mantiene su propio estado de metas y solo llama a `kernel.check` cuando un goal está *cerrado* (sin metas). Esto mantiene el TCB mínimo.

---

## 9. Criterios de Evaluación (Rúbrica)

| Criterio | Peso | Descripción |
|----------|------|-------------|
| **Correctitud del Kernel** | 40% | Todos los tests pasan; soundness: no acepta términos mal tipados |
| **NbE + Conversión** | 20% | βδιζη correcto; η para Π, Σ, inductivos; terminación garantizada |
| **Inductivos + Case** | 15% | Compilación a recursor correcta; coverage checking exhaustivo |
| **Código Declarativo** | 10% | Uso intensivo de unificación, backtracking, DCGs, clp(qr); sin cortes verdes innecesarios |
| **Documentación + Tests** | 10% | Spec coincide con implementación; tests cubren边界 cases |
| **Extensibilidad** | 5% | Interfaz limpia para tácticas (metas, unificación, construcción) |

---

## 10. Entrega Final

**Directorio**: `Declarativa/Proyecto final/kernel/`

**Archivos obligatorios**:
- `kernel.pl` (módulo principal)
- `syntax.pl`, `bidirectional.pl`, `nbe.pl`, `substitution.pl`, `inductive.pl`, `conversion.pl`, `errors.pl`, `parser.pl`
- `test_kernel.pl` (suite completa)
- `README.md` con:
  - Instrucciones de ejecución: `swipl -g "run_tests, halt" -t "halt(1)" -l test_kernel.pl`
  - Ejemplo de término verificado (append Vec + prueba longitud)
  - Límite conocido del kernel (qué NO hace: inferencia, typeclasses, parser surface)

**Opcional (bonus)**: `demo_vec_append.pl` — término core completo de `append` + prueba de longitud que el kernel acepta.

---

## 11. Referencias Normativas

1. **Bidirectional Typechecking** — Dunfield & Krishnaswami, *JFP* 2021 (algoritmo base)
2. **Normalization by Evaluation** — Berger & Schwichtenberg, 1991; Abel et al., *POPL* 2007 (NbE para TT)
3. **Pattern Unification** — Miller, *LICS* 1991 (unificación HO decidible para patrones)
4. **Elimination with a Motive** — Goguen, McKinna, *JFP* 2006 (case → recursor dependiente)
5. **Lean 4 Kernel** — `lean4/src/Init/Lean/Kernel` (referencia de implementación real)
6. **SWI-Prolog CLP(QR)** — `library(clpqr)` para `linarith` futuro

---

## 12. Riesgos Técnicos y Mitigación (Solo Kernel)

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| NbE no termina (η-loops) | Media | Alto | Ordenación RPO en reify; límite de pasos configurable; test de regresión con `Vec` anidados |
| Coverage checking incompleto | Media | Medio | Implementar *pattern matrix* (Augustsson) simplificado; test con `Vec` (índice dependiente) |
| Substitución de Bruijn buggy | Alta | Crítico | Tests exhaustivos de `shift`/`subst` en H0; property-based testing (QuickCheck-style en Prolog) |
| Universo inconsistency no detectada | Baja | Crítico | `Sort u : Sort (u+1)` hardcoded; test `Sort(0) : Sort(0)` debe fallar |
| Performance en términos grandes | Media | Bajo | Hash-consing en `nbe`; memoización de `eval`; no optimizar prematuramente |

---

## 13. Firma y Aprobación

**Estudiante**: _________________________
**Fecha**: _________________________
**Tutor**: _________________________

> **Nota**: Este documento es **contrato de scope**. Cualquier cambio al kernel (añadir typeclasses, parser surface, etc.) requiere enmienda firmada. La extensión de tácticas es **proyecto separado** (próximo cuatrimestre / TFG).