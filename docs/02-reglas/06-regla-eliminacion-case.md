# R-06 · Regla de Eliminación por `Case` (→ recursor)

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-06` |
| **Nombre** | `Case(scrut, motive, branches)` y exhaustividad |
| **Módulo Prolog** | `inductive.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
Case(scrut, motive, branches)
```

- `scrut : Inductive I ps`.
- Cada rama: `c_i args_i → motive_i`, donde `motive_i` puede depender del scrutinee
  (pattern matching dependiente).
- El `Case` se **compila** al recursor `I.rec`.
- Debe verificarse **cobertura exhaustiva** de constructores.

## 3. Formalización en Prolog (contrato)

```prolog
check_branches(Γ, I, ps, scrut, motive, branches).
coverage_check(I, branches).
compile_case_to_recursor(scrut, motive, branches, recursor).
```

## 4. Por qué es así

La eliminación con motivo (Goguen / McKinna) generaliza el caso sobre el scrutinee: sin una
cobertura completa de constructores no existe recursor que construir.

## 5. Bibliografía y demostración

1. Goguen, McKinna — *Elimination with a Motive*, JFP 2006.
2. Miller — *pattern unification*, LICS 1991.
3. `ESPECIFICACION_KERNEL.md` §11 — referencia normativa 4.

## 6. Ejemplo mínimo

```prolog
test(case_nat) :-
    Term = Case(Constructor(zero, []), Motive, [Branch(zero, []), Branch(succ, [Var(0)])]),
    check([], Term, MotiveApplied, ok).
```

## 7. Límites

El MVP exige que el Case sea compilable a un único recursor; el generador de casos (induction
tactic) queda en el motor de tácticas futuro.
