# R-01 · Regla de Universidad (jerarquía de niveles)

> Mini-especificación de regla del kernel.
> Documento padre: `ESPECIFICACION_KERNEL.md` (§2.1, §9, §12).

## 1. Identidad

| Campo | Valor |
|---|---|
| **ID** | `R-01` |
| **Nombre** | Universidad / bien formación de `Sort u` |
| **Módulo Prolog** | `syntax.pl`, `kernel.pl` |
| **Estado** | ✅ Aceptada |

## 2. Enunciado

Toda expresión de tipo `Sort u` es bien formada **si y solo si** pertenece al universo de nivel
inmediatamente superior:

```
Γ ⊢ Sort u : Sort (u + 1)
```

Es decir: `Sort u` tiene tipo `Sort (u+1)`. Prohibido: `Sort u : Sort u`.

## 3. Formalización en Prolog (contrato)

```prolog
% Inferencia: todo Sort(u) sintetiza Sort(u+1)
infer(Γ, Sort(u), Sort(u + 1)).

% Chequeo: el término a verificar debe vivir en el universo esperado
check(Γ, Sort(u), Sort(u + 1), ok).
```

## 4. Por qué es así

Sin jerarquía de universos no existe un modelo de tipos consistente: permitir `Type : Type`
habilita la auto-aplicación del tipo sobre sí mismo (paradoja de Girard). Exigir
`Sort u : Sort (u+1)` elimina la auto-referencia y mantiene cada capa contenida en la siguiente.

## 5. Bibliografía y demostración

1. Dunfield & Krishnaswami — *Bidirectional Type Checking*, JFP 31(4) (2021): manejo de
   restricciones de universo / rank.
2. Girard — lógica de tipos dependientes e impredicativos (sistema con jerarquía de universos).
3. Lean 4 — `Init/Lean/Kernel`: niveles `Sort` / `Type`.
4. `ESPECIFICACION_KERNEL.md` §11 — referencia normativa 1.

## 6. Ejemplo mínimo

```prolog
test(sort_ok) :- check([], Sort(0), Sort(1), ok).
test(universidad_inconsistent, fail) :- \+ check([], Sort(0), Sort(0), ok).
```

## 7. Límites

El MVP implementa una jerarquía **rígida** (`u → u+1`). No maneja niveles variables ni el universo
ω; eso queda fuera del scope del kernel.
