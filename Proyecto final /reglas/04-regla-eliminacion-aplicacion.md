# R-04 · Regla de Eliminación por Aplicación

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-04` |
| **Nombre** | Eliminación (`App(f, a) : B[a/0]`) |
| **Módulo Prolog** | `bidirectional.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
Γ ⊢ f : Π A B
Γ ⊢ a : A
--------------------------------
Γ ⊢ f a : B[a / 0]
```

## 3. Formalización en Prolog (contrato)

```prolog
infer(Ctx, app(F, A), BSubst) :-
    infer(Ctx, F, pi(Dom, Cod)),
    check(Ctx, A, Dom),
    subst(Cod, A, BSubst).            % B[a/0] mediante subst/3, NO =:=
```

## 4. Por qué es así

El tipo del resultado nace de la **sustitución** de la variable de índice 0 de la codominio por el
argumento. Esta es la regla que habilita los inductivos dependientes (p. ej. `Vec A n`).

## 5. Bibliografía y demostración

1. Dunfield & Krishnaswami — *Bidirectional Type Checking*, JFP 31(4) (2021).
2. CoC — Huet & Paulin-Mitchell, *The Calculus of Constructions* (regla de aplicación).
3. `ESPECIFICACION_KERNEL.md` §11 — referencia normativa 1.

## 6. Ejemplo mínimo

```prolog
test(app_ok) :- check([], App(Lam(Var(0)), Sort(0)), Sort(0), ok).
```

## 7. Límites

Requiere que la sustitución (R-07) esté implementada y correcta.
