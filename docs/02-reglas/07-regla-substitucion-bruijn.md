# R-07 · Regla de Sustitución y Shift (índices de Bruijn)

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-07` |
| **Nombre** | Sustitución (`subst`) y shift (deslizamiento) |
| **Módulo Prolog** | `substitution.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

- **Shift**: deslizamiento de variables libres por debajo de binders:
  `shift(T, d, k)` incrementa las variables libres ≥ `k` en `d`, respetando los binders.
- **Subst**: `B[a/0]` = sustitución de la variable de índice 0 de la codominio por el argumento
  (consumida por la regla R-04).

## 3. Formalización en Prolog (contrato)

```prolog
substitute(B, Arg, BSubst).

shift(T, Delta, K).
```

## 4. Por qué es así

Sin una sustitución y un shift correctas, las reglas posteriores (R-04, R-08) producen tipos y
códigos incorrectos. Un bug aquí contamina todos los predicados derivados.

## 5. Bibliografía y demostración

1. de Bruijn — técnica de índices de variables.
2. TAPL — *Types and Programming Languages* (shift / substitution).
3. `ESPECIFICACION_KERNEL.md` §12 — riesgo: *substitución de Bruijn buggy*.

## 6. Ejemplo mínimo

```prolog
% Tests de regresión (Hito H0): shift y substitute con binders anidados.
test(shift_basic).
test(subst_basic).
```

## 7. Límites

La definición exacta de los casos (Var, Lam, App, Π, Σ, Pair, Fst/Snd, etc.) vive en
`substitution.pl`; el kernel solo expone los predicados superiores.
