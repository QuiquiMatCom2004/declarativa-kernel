# Profundidad Teórica — Axiomas, Cálculos y Conexión con el Kernel

> Complemento técnico a `TEORIA_FUNDAMENTOS.md`.
> Profundiza cada teoría con sus axiomas exactos y su impacto en el kernel.

---

## 1. El reto central — profundizado

El kernel debe ser el **Trusted Code Base (TCB)**: el único código que, si es correcto,
garantiza que el sistema completo sea sonido. Todo lo demás (elaborador, tácticas,
inferencia de tipos) puede tener bugs; si el kernel no los acepta, el sistema sigue
siendo correcto.

Requisitos formales del TCB:

| Propiedad | Significado | Cómo la garantiza el kernel |
|-----------|-------------|----------------------------|
| Soundness | `check(Γ,t,T,ok) ⇒ Γ ⊢ t : T` en el sistema formal | Implementar solo las reglas del §4 de `MODELO_LOGICO.md` |
| Consistencia | No `check([],t,empty,ok)` para ningún `t` | Jerarquía de universos + no permitir Type:Type |
| Decidibilidad | `check` siempre termina | NbE total + estructura de los términos core (no hay Lam sin anotación en infer) |
| Canonicity | Todo término de tipo Nat se reduce a `zero` o `succ(…)` | NbE produce forma normal canónica |

---

## 2. Lógica constructiva — axiomas exactos

### 2.1 Axiomas que el kernel acepta (intuicionismo)

```
(∧-I)   Γ ⊢ a : A    Γ ⊢ b : B          ⟹  Γ ⊢ pair(a,b) : A × B
(∧-E₁)  Γ ⊢ p : A × B                   ⟹  Γ ⊢ fst(p) : A
(→-I)   Γ, x:A ⊢ b : B                  ⟹  Γ ⊢ lam(b) : A → B
(→-E)   Γ ⊢ f : A → B    Γ ⊢ a : A      ⟹  Γ ⊢ app(f,a) : B
(∀-I)   Γ, x:A ⊢ b : B(x)              ⟹  Γ ⊢ lam(b) : Π(x:A).B(x)
(∃-I)   Γ ⊢ a : A    Γ ⊢ b : B(a)      ⟹  Γ ⊢ pair(a,b) : Σ(x:A).B(x)
```

### 2.2 Axiomas que el kernel NO acepta (clásicos)

```
LEM         : A ∨ ¬A           — inhabitable solo con axioma explícito
DNE         : ¬¬A → A          — ídem
Hilbert ε   : (∃x.P(x)) → A   — no constructivo
```

**Impacto en el kernel**: ningún término `t` del lenguaje core representa LEM.
Si el usuario quiere LEM como axioma, debe añadirlo como parámetro del teorema
(`Π(lem : ∀A. A ∨ ¬A). ...`), lo que hace visible el coste.

---

## 3. Historia y axiomas de cada teoría

### 3.1 Russell (1908): jerarquía de tipos ramificada

**Problema**: paradoja de Russell — `{x | x ∉ x}` es inconsistente.
**Solución**: estratificar los tipos en órdenes.
**Axioma de reducibilidad**: un propositional function de orden superior se puede
reemplazar por una de orden 1 equivalente. Este axioma fue criticado por no ser
puramente lógico y fue abandonado en la teoría de tipos moderna.
**Legado en el kernel**: la jerarquía `Sort(u) : Sort(u+1)` es el descendiente
directo de este principio, pero sin el axioma de reducibilidad (no necesario
en un sistema predicativo).

### 3.2 Church (1940): λ-cálculo simplemente tipado (STLC)

**Contribución**: añadir tipos al λ-cálculo para eliminar la auto-aplicación.
**Axiomas** (en notación moderna):

```
  ───────────────── [Var]      Γ,A ⊢ b:B
  Γ, A ⊢ var(0) : A           ────────────── [Abs]
                               Γ ⊢ lam(b) : A→B

  Γ ⊢ f:A→B    Γ ⊢ a:A
  ──────────────────────── [App]
        Γ ⊢ app(f,a) : B
```

**Propiedades**:
- Strong normalization: toda secuencia de reducciones termina.
- Subject reduction: si `Γ ⊢ t:T` y `t → t'`, entonces `Γ ⊢ t':T`.
- Tipos no dependientes: `A→B` no depende del valor de `a`.

**Limitación que lleva al kernel**: no puede expresar `Vec A n` (el tipo depende del
valor `n`).

### 3.3 Hindley–Milner (1978)

**Contribución**: inferencia de tipos completa para polimorfismo paramétrico
(sin anotaciones).
**Restricción**: polimorfismo de rango 1 (let-polymorphism). No dependiente.
**Algoritmo W**: genera restricciones de unificación, las resuelve con Robinson
unification, produce el tipo principal.
**Por qué no es suficiente**: no tiene tipos dependientes. `length : List A → Nat`
devuelve un Nat, pero no puede expresar `Π(n:Nat). Vec A n → Vec A (n+1)`.

### 3.4 Martin-Löf ITT (1975, 1984)

**Contribución**: primer sistema de tipos dependientes consistente e intuicionista.
**Axiomas clave**:

```
(Sort)      Γ ⊢ Sort(u) : Sort(u+1)
(Π-F)       Γ ⊢ A : Sort(u)    Γ,A ⊢ B : Sort(v)
            ──────────────────────────────────────
            Γ ⊢ Π(A,B) : Sort(max u v)
(Σ-F)       análogo a Π-F
(Id-F)      Γ ⊢ a:A    Γ ⊢ b:A
            ────────────────────────
            Γ ⊢ Id(A,a,b) : Sort(u)   (tipo identidad)
```

**Lo que añade al STLC**:
- Tipos pueden depender de valores.
- `Π` generaliza `→`.
- `Σ` generaliza `×`.
- Tipos inductivos con recursores.

**Lo que el kernel NO implementa de MLTT completo**: tipo identidad (Id), K-axiom,
transport. Quedan para extensión HoTT.

### 3.5 Girard: System F y la paradoja (1972 / 1986)

**System F**: `∀α. τ` — polimorfismo de segundo orden impredicativo.
Impredicativo = cuantificar sobre todos los tipos, incluyendo el tipo que se
está definiendo.
Ejemplo: `id : ∀α. α → α`; al instanciar α con `∀α.α→α` se obtiene el tipo
de id aplicado a sí mismo.

**System U** (extensión de F): permite cuantificación sobre tipos de tipos.
**Paradoja de Girard** (1986): System U es **inconsistente** — se puede derivar
`⊢ False` sin axiomas. La causa: la impredicatividad sin jerarquía permite
auto-referencia circular de tipos.

**Lección para el kernel**: la jerarquía `Sort(u) : Sort(u+1)` es **obligatoria**.
Permitir `Sort(0) : Sort(0)` hace el kernel inconsistente.

### 3.6 CoC y Lean 4 / Coq

**Calculus of Constructions** (Coquand & Huet, 1988):
- Unifica System F con tipos dependientes.
- Impredicativo en Prop (como Coq), predicativo en Type (como el kernel).
- El kernel implementa CIC predicativo simplificado.

**Lean 4**: CIC + inductivos + quotients. El kernel del proyecto es una versión
mínima del kernel de Lean 4.

---

## 4. Lógica formal — juicios y reglas completos

### 4.1 Reglas de formación de contexto

```
──────────  [Ctx-Empty]        Γ ⊢ T : Sort(u)
Γ = [] ok                      ──────────────────── [Ctx-Extend]
                                Γ, T ok
```

En Prolog:
```prolog
well_formed_ctx([]).
well_formed_ctx([T|Ctx]) :-
    well_formed_ctx(Ctx),
    infer(Ctx, T, sort(_)).
```

### 4.2 Regla de Var con contexto bien formado

```
Γ ok    var(i) ∈ dom(Γ)    Γ(i) = T
──────────────────────────────────────── [Var-wf]
         Γ ⊢ var(i) ⇒ T
```

### 4.3 Regla de conversión (subsumción) — formal

```
Γ ⊢ t ⇒ T    Γ ⊢ T ≡ U    Γ ⊢ U : Sort(u)
─────────────────────────────────────────────── [Conv]
                Γ ⊢ t ⇐ U
```

La condición `Γ ⊢ U : Sort(u)` asegura que U es un tipo bien formado antes de
usarlo en check.

### 4.4 Regla β (computación)

```
Γ, A ⊢ b : B    Γ ⊢ a : A
──────────────────────────── [β]
   Γ ⊢ app(lam(b), a) ≡ b[a/0]
```

### 4.5 Regla η (extensionalidad funcional)

```
Γ ⊢ f : Π(A,B)
─────────────────────────────── [η]
Γ ⊢ f ≡ lam(app(shift(f,1,0), var(0)))
```

(shift eleva las vars libres de f al nuevo contexto bajo el lam)

---

## 5. Definiciones formales

### 5.1 Forma normal

Un término `t` está en **forma normal** si no contiene redexes β activos
(ningún `app(lam(b), a)` a nivel de tipo) y está η-expandido para todos los
tipos función y producto.

### 5.2 Término neutro

Un término es **neutro** si su cabeza es una variable `var(i)` o un
constructor aplicado parcialmente — no puede reducirse más pero tampoco
está completamente evaluado.

### 5.3 Clausura (para NbE)

`closure(Env, Body)` = par (entorno de valores, término a evaluar).
La aplicación de una clausura a un valor `V` produce un nuevo valor:
```prolog
apply_closure(closure(Env, Body), V, Result) :-
    eval([V|Env], Body, Result).
```

### 5.4 Sustitución simultánea vs. individual

La sustitución del kernel es **individual** (un término por la variable de índice 0)
porque los binders en `pi/lam/sigma` ligan de uno en uno.
La sustitución simultánea se implementa como composición de individuales.

---

## 6. Conexiones y propiedades del sistema

### 6.1 Curry–Howard–Lambek

| Dimensión | Proposiciones | Tipos | Categorías |
|-----------|---------------|-------|------------|
| Objetos | fórmulas | tipos | objetos de categoría |
| Morfismos | pruebas | términos | morfismos |
| `→` | implicación | función | exponencial |
| `∧` | conjunción | producto | producto cartesiano |
| `⊤` | verdad | Unit | objeto terminal |
| `⊥` | falsedad | Empty | objeto inicial |

El kernel verifica la dimensión "tipos–términos" de esta correspondencia.

### 6.2 Strong normalization (SN)

**Teorema**: en el CIC predicativo (el sistema del kernel), toda secuencia de
reducciones β termina.

**Por qué importa**: garantiza que NbE siempre termina; sin SN la conversión
podría ciclar.

**Prueba idea**: se asigna una medida de tamaño a los términos que decrece
estrictamente con cada β-paso (interpretación de tipos como conjuntos de
candidatos de reducibilidad, Girard).

### 6.3 Decidibilidad del type checking

**Teorema**: `Γ ⊢ t : T` es decidible en el kernel (CIC predicativo + inductivos fijos).

**Por qué**: 
- SN garantiza que NbE termina.
- El árbol de derivación está guiado por la estructura del término (no hay búsqueda).
- La unificación en Prolog produce la derivación directamente.

---

## 7. Los cálculos en detalle

### 7.1 λ-cálculo no tipado — las tres reglas

```
(α) λx.t  ≡  λy.t[y/x]        renombrado (irrelevante con índices Bruijn)
(β) (λx.t) s  →  t[s/x]       reducción  (= subst en el kernel)
(η) λx.(f x)  ≡  f             expansión  (si x ∉ FV(f))
```

Con índices de Bruijn:
```
(β) app(lam(b), a)  →  subst(b, a)
(η) lam(app(shift(f,1,0), var(0)))  ≡  f
```

### 7.2 STLC — soundness (prueba esquema)

**Teorema**: si `Γ ⊢ t : T` y `t → t'` entonces `Γ ⊢ t' : T`.

Prueba por inducción en la derivación del juicio. El caso App:
- Por hipótesis: `Γ ⊢ f : A→B`, `Γ ⊢ a : A`.
- Si `app(f,a) → app(f',a)` (reducción interna en f): por h.i. `Γ ⊢ f':A→B`, luego `Γ ⊢ app(f',a):B`.
- Si `app(lam(b),a) → subst(b,a)` (β): por sustitución lemma `Γ ⊢ subst(b,a) : B`.

El **sustitución lemma** es el corazón: si `Γ,A ⊢ b:B` y `Γ ⊢ a:A`, entonces
`Γ ⊢ subst(b,a):subst(B,a)`. Esto es exactamente R-04 del kernel.

### 7.3 Hindley–Milner — inferencia

Algoritmo W (simplificado):
```
W(Γ, app(f, a)) =
  let (S1, T1) = W(Γ, f)
      (S2, T2) = W(S1 Γ, a)
      S3       = unify(S2 T1, T2 → fresh_α)
  in  (S3 ∘ S2 ∘ S1, S3 fresh_α)
```

El kernel NO usa H-M (requiere tipos completos), pero el elaborador futuro podría
usarlo para inferir tipos en términos surface.

### 7.4 Martin-Löf — tipos como conjuntos de pruebas

En MLTT, el tipo `Nat` es el conjunto:
```
Nat = { zero, succ(zero), succ(succ(zero)), ... }
```

El tipo `Vec A n` es el conjunto de vectores de longitud n con elementos de A:
```
Vec A 0 = { vnil }
Vec A (n+1) = { vcons h t | h ∈ A, t ∈ Vec A n }
```

El kernel puede verificar que un término concreto pertenece a uno de estos conjuntos.

### 7.5 System F — polimorfismo

```
id : ∀α. α → α
id = Λα. λx:α. x
```

Con índices de Bruijn: `lam(lam(var(0)))` y tipo `pi(sort(0), pi(var(0), var(0)))`.

El kernel actual tiene esto: `pi(sort(0), pi(var(0), var(0)))` es el tipo de la
función identidad polimórfica. No hace falta Λ explícito porque Sort es un tipo
como cualquier otro.

### 7.6 CoC — el cubo de tipos

El "cubo λ" (Barendregt) organiza los sistemas de tipos por las combinaciones de
dependencias permitidas entre términos y tipos:

```
  termino → termino     (STLC)
  tipo    → término     (System F — polimorfismo)
  termino → tipo        (LF — tipos dependientes)
  tipo    → tipo         (Fω — operadores de tipo)
```

CoC = todas las combinaciones. El kernel implementa CoC predicativo.

### 7.7 HoTT — más allá del kernel

HoTT añade:
- **Univalencia**: `(A ≃ B) ≃ (A = B)` — equivalencias son igualdades.
- **Tipos inductivos superiores (HIT)**: constructores de path.
- Requiere un sistema de tipos más rico (cubical type theory).

Referencia para el futuro: HoTT Book (2013), Cubical Agda.

---

## 8. Del formalismo al kernel Prolog

### 8.1 Por qué Prolog es natural para el kernel

1. **Unificación nativa**: la comparación de tipos es unificación estructural,
   que Prolog provee de forma primitiva.
2. **Backtracking**: permite explorar múltiples ramas de derivación.
3. **Términos como árboles**: los términos del λ-cálculo son árboles de Herbrand;
   Prolog los maneja directamente.
4. **DCG**: para el parser de sintaxis surface.
5. **CLP(QR)**: para aritmética sobre índices de universos y longitudes de vectores.

### 8.2 Trampas de la implementación Prolog

| Trampa | Efecto | Solución |
|--------|--------|----------|
| Usar `=:=` en vez de `==` | Falla en comparación de tipos no numéricos | `==` para términos estructurales |
| Extender Γ con nombres en vez de tipos | El índice Bruijn apunta al nombre, no al tipo | Γ = lista de tipos únicamente |
| Usar `is` en la sustitución | No funciona con términos no evaluados | `subst/3` manual |
| `Lam(body)` en `infer` | A no está disponible → falla o es nondeterminista | Lam solo en `check` |
| Comparar formas normales con `=` en vez de `==` | Prolog puede unificar vars no instanciadas | Siempre `==` después de NbE |

### 8.3 El ciclo verificación completo

```
Input: Γ, t, T
         │
         ▼
  check(Γ, t, T)
   ├─ reglas específicas (Lam, Pair)
   └─ fallback: infer(Γ, t, T') → conversion(Γ, T', T)
                                       │
                              nbe(Γ, T) ─────► NF1
                              nbe(Γ, T') ────► NF2
                              NF1 == NF2 ?
                                   │
                              ok / fail
```

---

## 9. Bibliografía técnica adicional

1. **de Bruijn, N.G.** — *Lambda Calculus Notation with Nameless Dummies*, Indagationes
   Mathematicae 34, 1972.
2. **Barendregt, H.** — *Lambda Calculi with Types*, Handbook of Logic in CS, 1992.
   El cubo λ.
3. **Abel, A., Coquand, T., Dybjer, P.** — *Normalization by Evaluation for MLTT with
   Typed Equality Judgements*, LICS 2007.
4. **The Univalent Foundations Program** — *Homotopy Type Theory*, 2013.
5. **Coquand, T.** — *An Algorithm for Type-Checking Dependent Types*, 1996.
   Base del algoritmo bidireccional para tipos dependientes.
6. **Norell, U.** — *Towards a Practical Programming Language Based on Dependent Type
   Theory*, PhD thesis, Chalmers, 2007. Implementación de Agda.
7. **Lean 4 source** — `src/Lean/Kernel.lean`. Referencia de implementación real.

---

## 10. Lectura sugerida (en orden)

1. Pierce — TAPL, cap. 5–9: λ-cálculo, sustitución, STLC.
2. TEORIA_FUNDAMENTOS.md §7: resumen de cada sistema de tipos.
3. Abel et al. 2007: NbE para tipos dependientes (§7.3 de este documento).
4. Dunfield & Krishnaswami 2021: algoritmo bidireccional (R-10).
5. Goguen & McKinna 2006: eliminación con motivo (R-06).
6. MODELO_LOGICO.md §4: las reglas del kernel una a una.

---

## 11. Conexión final con las reglas del kernel

Cada regla en `reglas/` tiene un fundamento exacto en este documento:

| Regla | Teoría fuente | Sección aquí |
|-------|--------------|--------------|
| R-01 Sort | Russell + Girard (jerarquía) | §3.1, §3.5 |
| R-02 Π-F | Martin-Löf §3.4, CoC §3.6 | §3.4, §7.5 |
| R-03 λ-I | STLC §3.2, CoC | §7.2 |
| R-04 App | STLC + subst lemma | §7.2, §8.2 |
| R-05 Ind | Inductivos CIC | §3.6 |
| R-06 Case | Goguen & McKinna | §3.4 (elim con motivo) |
| R-07 Bruijn | de Bruijn 1972 | §3 (índices) |
| R-08 Conv β | NbE, Berger & Schwichtenberg | §8.1 |
| R-09 η | NbE, Abel et al. | §8.1 |
| R-10 Bidireccional | Dunfield & Krishnaswami | §4 (juicios) |
