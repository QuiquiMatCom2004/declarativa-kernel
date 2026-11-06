# R-10 · Regla de Chequeo / Inferencia Bidireccional

> Mini-especificación de regla del kernel.

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-10` |
| **Nombre** | Control de flujo bidireccional (check / infer) |
| **Módulo Prolog** | `bidirectional.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

- `check(Γ, t, T)` — `t` tiene tipo `T`:
  se implementa como `infer(Γ, t, Tinf)` + `conversion(Γ, Tinf, T)`.
- Introducción de Π / λ: verificar sub-derivaciones (dominio + cuerpo).
- Eliminación (App): inferir tipo de la función, comprobar argumento, sustituir (R-04).

## 3. Formalización en Prolog (contrato)

```prolog
%% Regla general (fallback): infer + conversión
check(Ctx, Term, Expected) :-
    infer(Ctx, Term, Inferred),
    conversion(Ctx, Inferred, Expected).  % == estructural dentro de conversion/3

%% Regla específica para λ (introducción de Π, solo check)
check(Ctx, lam(Body), pi(A, B)) :-
    infer(Ctx, A, sort(_)),
    check([A|Ctx], Body, B).

%% Regla específica para App (se delega a infer)
%%   App es inferable; check lo resuelve por fallback arriba.
```

## 4. Por qué es así

Chequear directamente contra tipos dependientes es engorroso; la inferencia + conversión reutiliza
las reglas de formación y permite verificar sin proveer el tipo cuando no hace falta.

## 5. Bibliografía y demostración

1. Dunfield & Krishnaswami — *Bidirectional Type Checking*, JFP 31(4) (2021).
2. `ESPECIFICACION_KERNEL.md` §4 — algoritmos de verificación.

## 6. Ejemplo mínimo

```prolog
test(check_infer) :- check([], Lam(Var(0)), Pi(Sort(0), Sort(0)), ok).
```

## 7. Límites

El kernel **solo verifica**: no infiere tipos de metas ni resuelve implicaciones (fuera de scope).
