# R-02 · Regla de Formación de Π

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-02` |
| **Nombre** | Formación de la función dependiente `Π (x : A), B` |
| **Módulo Prolog** | `bidirectional.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
Γ ⊢ A : Type u
Γ, A ⊢ B : Type v
--------------------------------
Γ ⊢ Π (x : A), B : Type (max u v)
```

## 3. Formalización en Prolog (contrato)

```prolog
infer(Ctx, pi(A, B), sort(Max)) :-
    infer(Ctx, A, sort(U)),
    infer([A|Ctx], B, sort(V)),        % B se chequea en [A|Ctx], no en Ctx
    Max is max(U, V).

check(Γ, Pi(A, B), T, ok) :- infer(Γ, Pi(A, B), T, ok).
```

## 4. Por qué es así

`Π` es el tipo de funciones dependientes. Para formarlo se requieren dominio y codominio bien
formados; el nivel resultante es el máximo (`max u v`) de ambos.

## 5. Bibliografía y demostración

1. Dunfield & Krishnaswami — *Bidirectional Type Checking*, JFP 31(4) (2021).
2. Martin-Löf — predicados dependientes.
3. CoC — Huet & Paulin-Mitchell, *The Calculus of Constructions*.

## 6. Ejemplo mínimo

```prolog
test(pi_ok) :- check([], Pi(Sort(0), Sort(0)), Sort(1), ok).
```

## 7. Límites

Para `Pi` el chequeo se reduce a inferencia + conversión (ver R-10).
