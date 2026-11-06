# R-03 · Regla de Introducción de λ

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-03` |
| **Nombre** | Introducción de la función (`λ`) |
| **Módulo Prolog** | `bidirectional.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
Γ, A ⊢ b : B
--------------------------------
Γ ⊢ λ b : Π (x : A), B
```

## 3. Formalización en Prolog (contrato)

```prolog
check(Γ, Lam(body), Pi(A, B), ok) :-
    check(Γ, A, Sort(_), _),
    check([A | Γ], body, B, _).
```

## 4. Por qué es así

Para introducir `λ` se **extiende el contexto** con el dominio `A` y se verifica el cuerpo bajo ese
contexto. La variable de la función queda como variable interna (índice 0 en la codominio dependiente).

## 5. Bibliografía y demostración

1. Dunfield & Krishnaswami — *Bidirectional Type Checking*, JFP 31(4) (2021).
2. CoC — Huet & Paulin-Mitchell, *The Calculus of Constructions* (regla `λ`).

## 6. Ejemplo mínimo

```prolog
test(lambda_ok) :- check([], Lam(Var(0)), Pi(Sort(0), Sort(0)), ok).
```

## 7. Límites

La formación de `Π` ya garantizó que `B` es un tipo; aquí solo se verifica el cuerpo con el dominio
añadido al contexto.
