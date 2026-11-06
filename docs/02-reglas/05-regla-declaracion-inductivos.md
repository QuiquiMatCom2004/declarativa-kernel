# R-05 · Regla de Declaración de Inductivos

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-05` |
| **Nombre** | Declaración de inductivos (`Inductive` / `Constructor`) |
| **Módulo Prolog** | `inductive.pl`, `syntax.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

El kernel incluye una **signature fija** de inductivos:

| Inductivo | Parámetros | Constructores |
|---|---|---|
| `Nat` | `[]` | `zero : Nat`, `succ : Nat → Nat` |
| `List` | `[A : Type u]` | `nil : List A`, `cons : A → List A → List A` |
| `Vec` | `[A : Type u]` | `vnil : Vec A zero`, `vcons : Π n : Nat. A → Vec A n → Vec A (succ n)` |
| `Sigma` | `[A, B : A → Type v]` | `mk : Π a : A. B a → Sigma A B` |
| `Unit` / `Empty` / `Bool` / `Prod` | — | — |

Cada constructor tiene tipo `Π params. Π args. Inductive I params`.

## 3. Formalización en Prolog (contrato)

```prolog
inductive_signature(Sig).
constructor_type(c, Tcon).
recursor_type(I, TRec).
```

## 4. Por qué es así

TCB mínimo: el MVP no permite inductivos definidos por el usuario (sin `data` / `inductive`).
La extensión hacia inductivos de usuario queda en el motor de tácticas / elaborador futuro.

## 5. Bibliografía y demostración

1. Lean 4 kernel — tipos inductivos.
2. Goguen, McKinna — *Elimination with a Motive*, JFP 2006.
3. Miller — *pattern unification*, LICS 1991.
4. `ESPECIFICACION_KERNEL.md` §11 — referencias 3 y 4.

## 6. Ejemplo mínimo

```prolog
test(nat_zero) :- infer([], Constructor(zero, []), Nat).
```

## 7. Límites

Solo la signature fija del MVP; los inductivos dependientes (p. ej. `Vec`) se declaran pero sus
recursos se generan del recursor con motivo (R-06).
