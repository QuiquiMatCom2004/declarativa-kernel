# R-08 · Regla de Conversión Deficional (β / NbE)

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-08` |
| **Nombre** | Conversión definicional (`≡`) mediante Normalización por Evaluación |
| **Módulo Prolog** | `conversion.pl`, `nbe.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
Γ ⊢ t ≡ u    ⇔    NbE(Γ, t, Vt) ∧ NbE(Γ, u, Vu) ∧ Vt =:= Vu
```

Donde β dice: `App(Lam(b), a) ≡ b[a/0]`.

## 3. Formalización en Prolog (contrato)

```prolog
conversion(Ctx, T1, T2) :-
    nbe(Ctx, T1, NF1),
    nbe(Ctx, T2, NF2),
    NF1 == NF2.                       % == comparación estructural, NO =:= (aritmético)
```

## 4. Por qué es así

La igualdad definicional es la base de la verificación (`check` compara tipos esperado vs. inferido
a través de conversión). NbE la implementa de forma total y sin bucles de auto-adjunción.

## 5. Bibliografía y demostración

1. Berger & Schwichtenberg — *Normalization by Evaluation*, 1991.
2. Abel et al. — NbE para cálculo de tipos dependiente, POPL 2007.
3. Lean 4 kernel — reducibilidad / conversión.
4. `ESPECIFICACION_KERNEL.md` §11 — referencia normativa 2.

## 6. Ejemplo mínimo

```prolog
test(beta_ok) :- conversion([], App(Lam(Var(0)), Sort(0)), Sort(0), ok).
```

## 7. Límites

La normalización debe respetar shift/subst (R-07) y η (R-09).
