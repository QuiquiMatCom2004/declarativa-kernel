# R-09 · Regla de Expansión η (eta)

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-09` |
| **Nombre** | Expansión η (eta) |
| **Módulo Prolog** | `nbe.pl` (reify) |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

```
λ x. f x ≡ f
```

Aplicable a funciones (Π) y de forma análoga a Σ / inductivos (registros: `mk (fst p) (snd p) ≡ p`).

## 3. Formalización en Prolog (contrato)

```prolog
reify(Pi(A, B), VPi(Vdom, Vcod), Pi(A_nf, Lam(B_nf))).
```

## 4. Por qué es así

La conversión definicional (R-08) debe considerar la equivalencia η, o se rechazarían términos
equivalentes. En NbE la reificación de un valor funcional genera la forma `λx. body` con variable
fresca; la conversión debe cerrar esa equivalencia.

## 5. Bibliografía y demostración

1. Berger & Schwichtenberg — *Normalization by Evaluation*, 1991.
2. Lean 4 — teoremas de η.
3. Martin-Löf — lógica de predicados dependientes.

## 6. Ejemplo mínimo

```prolog
test(eta_ok) :- conversion([], Lam(App(Var(1), Var(0))), Var(1), ok).
```

## 7. Límites

La implementación vive en la fase de reificación de `nbe.pl`; no añade nuevas reglas al kernel.
