# Declarativa Kernel — Kernel Mínimo de Tipos Dependientes en SWI-Prolog

> **Proyecto Final — Programación Declarativa**
> Kernel de verificación de tipos para un lenguaje con **tipos dependientes**, implementado en **SWI-Prolog**, inspirado en el kernel de **Lean 4** y **Coq** (Calculus of Inductive Constructions simplificado).

---

## 🎯 ¿Qué es este proyecto?

Un **kernel de verificación de tipos** (Trusted Code Base, TCB) que:

- Verifica términos **totalmente anotados** en un lenguaje core mínimo
- Realiza **conversión definicional βδιζη** vía **Normalization by Evaluation (NbE)**
- Soporta **tipos inductivos** fijos (`Nat`, `List`, `Vec`, `Σ`, `Unit`, `Empty`, `Bool`, `Prod`) con eliminación `Case` compilada a recursores con motivo
- Responde `ok` / `error` con traza — **no infiere, no resuelve implícitos**

**Filosofía:** El kernel solo verifica. Es el TCB mínimo sobre el que se construirá un elaborador y motor de tácticas en fases futuras.

### ¿Por qué Prolog?

1. **Unificación nativa** — la comparación de tipos es unificación estructural, que Prolog provee primitivamente
2. **Términos como árboles de Herbrand** — los términos del λ-cálculo se representan directamente
3. **Backtracking** — permite explorar derivaciones alternativas sin código extra
4. **Curry–Howard en acción** — cada regla de inferencia es una cláusula Horn; una derivación de tipo es una prueba SLD

### ¿Por qué es correcto?

- **Consistencia:** jerarquía de universos `Sort(u) : Sort(u+1)` — sin `Type : Type` (evita la paradoja de Girard)
- **Terminación:** NbE evalúa semánticamente y reifica — sin bucles de reducción
- **Soundness:** toda derivación corresponde exactamente a una prueba formal de las reglas de `MODELO_LOGICO.md`

---

## 📂 Estructura del repositorio

```
declarativa-kernel/
├── docs/
│   ├── 01-fundamentos/              # Teoría y especificaciones
│   │   ├── Orientacion.md           # Alcance y objetivo
│   │   ├── ESPECIFICACION_KERNEL.md # Especificación global (contrato de scope)
│   │   ├── TEORIA_FUNDAMENTOS.md    # Fundamentos teóricos (λ-cálculo → CIC)
│   │   ├── DEEP_DIVE_TEORIA.md      # Profundidad: axiomas, cubo λ, NbE
│   │   └── MODELO_LOGICO.md         # Modelo lógico formal completo ★
│   ├── 02-reglas/                   # Reglas R-01 a R-10 (mini-nums .md)
│   │   ├── README.md                # Plantilla y orden de lectura
│   │   ├── 01-regla-universidad-sort.md
│   │   ├── ...
│   │   └── 10-regla-chequeo-inferencia-bidirional.md
│   ├── 03-kernel/                   # Implementación Prolog (copia documentada)
│   └── 04-documentacion-completa/
│       └── DOCUMENTACION_COMPLETA.md  # Por qué cada línea está en cada sitio ★
└── Proyecto final/
    └── kernel/                      # Fuentes Prolog del kernel
        ├── kernel.pl                # API pública
        ├── substitution.pl          # R-07
        ├── nbe.pl                   # R-08, R-09
        ├── conversion.pl            # R-08
        ├── inductive.pl             # R-05, R-06
        ├── bidirectional.pl         # R-01 a R-04, R-10
        ├── test_kernel.pl           # 31 tests
        └── demo_vec.pl              # Demo ejecutable
```

★ = documento normativo: es la fuente de verdad del diseño.

---

## 🚀 Cómo ejecutar

Requisitos: **SWI-Prolog 10.x** (`swipl` en PATH).

```bash
git clone https://github.com/QuiquiMatCom2004/declarativa-kernel.git
cd declarativa-kernel/"Proyecto final"/kernel
```

### Suite completa de tests (31 tests)

```bash
swipl -q -l test_kernel.pl -t "run_tests, halt"
```

Salida esperada: los 11 grupos de tests con `PASS` en todos.

### Demo ejecutable (7 secciones)

```bash
swipl -q -l demo_vec.pl -t "run_demo, halt"
```

Demuestra: Nat, Vec (tipos dependientes), Σ, conversión β, conversión η, consistencia de universos y la API pública.

### Uso interactivo

```bash
swipl -l kernel.pl
```

```prolog
?- check([], sort(0), sort(1), ok).
true.

?- infer([], lam(sort(0), var(0)), T).
T = pi(sort(0), sort(0)).

?- nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF).
NF = var(0).
```

---

## 📐 Las 10 reglas del kernel

| Regla | Nombre | Módulo | Fundamento teórico |
|-------|--------|--------|--------------------|
| **R-01** | Sort / jerarquía de universos | `bidirectional.pl` | Jerarquía de universos, evita paradoja de Girard |
| **R-Var** | Variable | `bidirectional.pl` | Juicios de Martin-Löf |
| **R-02** | Π-formación | `bidirectional.pl` | Tipos dependientes de Martin-Löf |
| **R-03** | λ-introducción | `bidirectional.pl` | STLC de Church |
| **R-04** | Aplicación | `bidirectional.pl` | Eliminación Π, lemma de sustitución |
| **R-Σ** | Σ-formación | `bidirectional.pl` | Sumas dependientes (Curry–Howard: ∃) |
| **R-Pair** | Par dependiente | `bidirectional.pl` | Introducción Σ |
| **R-Fst/Snd** | Proyecciones | `bidirectional.pl` | Eliminación Σ |
| **R-05** | Inductivos | `inductive.pl` | Signature fija (Lean 4, CoC) |
| **R-06** | Case → recursor | `inductive.pl` | Eliminación con motivo (Goguen & McKinna) |
| **R-07** | Shift / Subst | `substitution.pl` | Índices de de Bruijn (de Bruijn, 1972) |
| **R-08** | Conversión β / NbE | `nbe.pl`, `conversion.pl` | Normalization by Evaluation (Berger & Schwichtenberg, 1991) |
| **R-09** | Expansión η | `nbe.pl` | NbE con η (Abel, Coquand, Dybjer, 2007) |
| **R-10** | Bidireccional | `bidirectional.pl` | Check/Infer (Dunfield & Krishnaswami, 2021) |

Cada regla tiene su mini-especificación completa en [`docs/02-reglas/`](docs/02-reglas/) con: juicio formal, contrato Prolog, invariante, bibliografía, test mínimo y límites.

---

## 🧠 Fundamentos teóricos (resumen)

### El juicio fundamental

```
Γ ⊢ t : T
```

> "En el contexto Γ, el término `t` tiene tipo `T`" — cada verificación exitosa del kernel es una derivación de este juicio.

### Correspondencia Curry–Howard

| Lógica | Teoría de tipos | En este kernel |
|--------|-----------------|----------------|
| Proposición | Tipo | `pi(A,B)`, `sigma(A,B)` |
| Prueba | Término | `lam(A,Body)`, `pair(a,b)` |
| `∀x. P(x)` | `Π(x:A).P(x)` | `pi/2` |
| `∃x. P(x)` | `Σ(x:A).P(x)` | `sigma/2` |

### ¿Por qué NbE?

En lugar de buscar redexes sintácticamente (reescritura, puede no terminar), el kernel **evalúa semánticamente** a un dominio de valores y **reifica** de vuelta a forma normal βδη. Esto garantiza terminación y maneja η de forma natural.

### ¿Por qué índices de de Bruijn?

Sin nombres de variable, la sustitución es mecánica y libre de errores de captura — un bug aquí comprometería la soundness de todo el kernel.

### ¿Por qué jerarquía de universos?

Permitir `Type : Type` habilita la paradoja de Girard (inconsistencia). `Sort(u) : Sort(u+1)` elimina la auto-referencia. El test `no_impredicativo_fail` verifica esto.

📖 La justificación completa está en [`docs/04-documentacion-completa/DOCUMENTACION_COMPLETA.md`](docs/04-documentacion-completa/DOCUMENTACION_COMPLETA.md) y en [`docs/01-fundamentos/TEORIA_FUNDAMENTOS.md`](docs/01-fundamentos/TEORIA_FUNDAMENTOS.md).

---

## 📊 Estado del proyecto

### ✅ Completado

- [x] Modelo lógico formal completo (R-01 a R-10) con correcciones
- [x] Kernel Prolog funcional: check, infer, convert, nbe
- [x] Conversión definicional βδη vía NbE
- [x] Tipos inductivos fijos con Case → recursor + coverage checking
- [x] Suite de 31 tests — todos pasando
- [x] Demo ejecutable con 7 secciones
- [x] Documentación completa línea por línea con bibliografía

### 🔮 Trabajo futuro (fuera del MVP)

| Extensión | Por qué se dejó fuera |
|-----------|----------------------|
| Elaborador de superficie (parser → core) | El kernel solo verifica; la inferencia es trabajo separado |
| Motor de tácticas (induction, simp, rw) | Requiere metavariables — capa separada del TCB |
| Inductivos definidos por usuario | Requiere verificación de definiciones inductivas |
| Tipo identidad (Id) y HoTT | Fuera del scope del cuatrimestre |

---

## 📚 Bibliografía principal

1. **Pierce, B.C.** — *Types and Programming Languages*, MIT Press, 2002 (TAPL).
2. **Martin-Löf, P.** — *Intuitionistic Type Theory*, Bibliopolis, 1984.
3. **de Bruijn, N.G.** — *Lambda Calculus Notation with Nameless Dummies*, 1972.
4. **Berger, U. & Schwichtenberg, H.** — *An Inverse of the Evaluation Functional for Typed λ-calculi*, LICS 1991.
5. **Abel, A., Coquand, T., Dybjer, P.** — *Normalization by Evaluation for MLTT*, LICS 2007.
6. **Goguen, H. & McKinna, J.** — *Eliminating Dependent Pattern Matching*, JFP 16(3), 2006.
7. **Dunfield, J. & Krishnaswami, N.** — *Bidirectional Typechecking*, JFP 31(4), 2021.
8. **Girard, J.Y.** — *Proofs and Types*, CUP, 1989.
9. **The Univalent Foundations Program** — *Homotopy Type Theory*, 2013.
10. **Lean 4 Team** — *src/Lean/Kernel*, código fuente de referencia.

---

## 🧑‍🎓 Contexto académico

Proyecto final de la asignatura **Programación Declarativa** (3er año, CS). El objetivo: presentar e implementar una idea usando programación declarativa como base — aquí, un verificador de tipos donde cada regla de inferencia es una cláusula Prolog y cada derivación de tipo es una prueba en el sistema lógico.

---

## 📄 Licencia

Material académico. Uso libre con atribución para fines educativos.
