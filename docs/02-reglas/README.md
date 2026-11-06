# Reglas del Kernel — Mini Especificaciones

**Proyecto**: Programación Declarativa — Proyecto Final
**Documento padre**: [`ESPECIFICACION_KERNEL.md`](../ESPECIFICACION_KERNEL.md)

## Objetivo

El kernel se especifica **regla por regla**. Esta carpeta contiene **un mini-`.md` por regla**,
cada uno con el contrato necesario para que un implementador (humano o modelo de lenguaje) pueda:

1. entender **por qué** la regla existe,
2. implementarla en Prolog **sin improvisar**,
3. comprobar que su implementación es correcta.

## Plantilla de cada mini-md de regla

Cada mini-md debe contener estas secciones, en este orden:

1. **Identidad** — ID (`R-XXX`), nombre, módulo Prolog, estado (`propuesta` / `aceptada` / `implementada`).
2. **Enunciado** — la regla formal (judgios de tipo) y su equivalente con el predicado Prolog.
3. **Formalización en Prolog (contrato)** — los predicados exactos que la implementan.
4. **Por qué es así** — intuición, invariante y por qué no debe cambiarse.
5. **Bibliografía y demostración** — papers, libros o documentación que avalan la regla.
6. **Ejemplo mínimo** — término mínimo + test.
7. **Límites** — qué excluye el kernel en esa regla.

## Índice de reglas

| ID | Regla | Archivo | Módulo Prolog | Padre |
|----|-------|---------|----------------|-------|
| R-01 | Universidad: `Sort u : Sort (u+1)` | [01-regla-universidad-sort.md](01-regla-universidad-sort.md) | `syntax.pl` | §2.1 |
| R-02 | Formación de Π | [02-regla-formacion-pi.md](02-regla-formacion-pi.md) | `bidirectional.pl` | §2.2 |
| R-03 | Introducción de λ | [03-regla-introduccion-lambda.md](03-regla-introduccion-lambda.md) | `bidirectional.pl` | §2.3 |
| R-04 | Eliminación por aplicación | [04-regla-eliminacion-aplicacion.md](04-regla-eliminacion-aplicacion.md) | `bidirectional.pl` | §2.4 |
| R-05 | Declaración de inductivos | [05-regla-declaracion-inductivos.md](05-regla-declaracion-inductivos.md) | `inductive.pl` | §3 |
| R-06 | Eliminación `Case` → recursor | [06-regla-eliminacion-case.md](06-regla-eliminacion-case.md) | `inductive.pl` | §2.6 |
| R-07 | Sustitución y shift (Bruijn) | [07-regla-substitucion-bruijn.md](07-regla-substitucion-bruijn.md) | `substitution.pl` | §2 (impl.) |
| R-08 | Conversión definicional (β / NbE) | [08-regla-conversion-beta.md](08-regla-conversion-beta.md) | `conversion.pl` | §4 |
| R-09 | Expansión η | [09-regla-eta-expansion.md](09-regla-eta-expansion.md) | `nbe.pl` | §4 |
| R-10 | Chequeo / inferencia bidireccional | [10-regla-chequeo-inferencia-bidirional.md](10-regla-chequeo-inferencia-bidirional.md) | `bidirectional.pl` | §4 |

## Orden de lectura

1. R-01 → R-04: núcleo del cálculo (universo, Π, λ, aplicación).
2. R-05 → R-06: inductivos y eliminación (`Case` → recursor).
3. R-07 → R-09: sustitución, conversión definicional y η (NbE).
4. R-10: algoritmo bidireccional que orquesta chequeo/inferencia/conversión.

## Protocolo de handoff a un modelo (implementación sin razonamiento)

Objetivo: que un modelo con bajo razonamiento no tenga que pensar para implementar una regla.

Prompt base sugerido:

```text
Actúa como implementador de un kernel de tipos dependientes en SWI-Prolog.
Eres de alto rigor: no añades reglas que no estén especificadas.

Tarea: implementar la regla <R-0X> descrita en <ruta-del-mini-md>.

Restricciones:
1. Implementa exactamente lo descrito en la sección "Formalización en Prolog".
2. No modifiques ni añadas predicados fuera del contrato de esa sección.
3. Añade el test de la sección "Ejemplo mínimo" y verifica que pasa.

Devuelve:
- El fragmento Prolog a añadir al módulo indicado.
- El resultado de correr el test.
```

## Cómo añadir una nueva regla

1. Copiar la plantilla de las secciones fijas anteriores a `NN-regla-<nombre>.md`.
2. Numerar en orden consecutivo.
3. Añadir la fila al índice y a esta lista de lectura.
4. Referenciar la sección de la `ESPECIFICACION_KERNEL.md` correspondiente.
