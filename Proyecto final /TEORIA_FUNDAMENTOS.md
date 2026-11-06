# Fundamentos Teóricos del Kernel

> Justificación teórica del modelo lógico en `MODELO_LOGICO.md`.
> Cada sección responde: **¿qué necesita el kernel y por qué la teoría lo exige?**

---

## 1. El reto central

El kernel es un **verificador de tipos dependientes**: recibe un término y un tipo,
y devuelve "correcto" o "error con traza". Para que ese veredicto sea fiable necesita:

1. **Consistencia** — que ningún tipo vacío sea habitado (sin paradojas).
2. **Decidibilidad** — que la comprobación termine siempre.
3. **Soundness** — que todo término aceptado tenga exactamente el tipo asignado.
4. **Completitud** (relativa) — que no rechace términos bien formados.

Estas cuatro propiedades se garantizan eligiendo el sistema de tipos correcto,
no escribiendo código defensivo.

---

## 2. Lógica constructiva / intuicionismo

El kernel está construido sobre **lógica intuicionista** (Brouwer, Heyting).
La diferencia clave con la lógica clásica:

| Principio | Lógica clásica | Lógica intuicionista |
|-----------|----------------|----------------------|
| LEM `A ∨ ¬A` | axioma | no es un axioma (puede añadirse, con coste) |
| Doble negación `¬¬A ⇒ A` | válido | no válido en general |
| Prueba de existencia | puede ser no constructiva | **debe exhibir testigo** |

**Consecuencia para el kernel**: toda prueba es un programa; `Σ(x:A).P(x)` = existe x
tal que P(x) **y** lo tenemos explícito. `Π(x:A).B(x)` = para todo x:A, B(x)
**y** tenemos la función que lo construye.

---

## 3. Tipos, términos y juicios

### 3.1 El juicio fundamental

```
Γ ⊢ t : T
```

- `Γ` = **contexto** — lista de tipos de las variables en scope.
- `t` = **término** — el programa o la prueba.
- `T` = **tipo** — la especificación o proposición.
- `⊢` = **turnstile** — "en el contexto Γ, t tiene tipo T".

### 3.2 Los cuatro juicios del kernel

| Juicio | Lectura | Prolog |
|--------|---------|--------|
| `Γ ⊢ T type` | T es un tipo bien formado | `well_typed(Ctx, T)` |
| `Γ ⊢ t ⇒ T`  | t sintetiza tipo T (inferencia) | `infer(Ctx, t, T)` |
| `Γ ⊢ t ⇐ T`  | t chequea contra T (verificación) | `check(Ctx, t, T)` |
| `Γ ⊢ t ≡ u`  | t y u son definitivamente iguales | `conversion(Ctx, t, u)` |

### 3.3 Inhabitation vs. derivación

Un tipo `T` es **habitado** si existe `t` tal que `[] ⊢ t : T`.
En lógica esto equivale a "T es demostrable".
El kernel acepta `t` si puede construir la derivación completa del juicio.

---

## 4. Tipos dependientes: Π y Σ

### 4.1 Π (producto dependiente)

`Π(x : A). B(x)` generaliza la función: el **tipo del resultado** puede depender
del **valor del argumento**.

- Si `B` no depende de `x`: `Π(x:A).B ≡ A → B` (función ordinaria).
- Si `B` depende de `x`: permite expresar `Vec A n` (vector de longitud exacta n).

**Regla de formación**:
```
Γ ⊢ A : Type u    Γ, A ⊢ B : Type v
────────────────────────────────────────
      Γ ⊢ Π(A, B) : Type (max u v)
```

**Por qué `Γ, A ⊢ B`**: B puede mencionar la variable `x` (índice 0); debe chequear
en el contexto **extendido** con el tipo de esa variable.

### 4.2 Σ (suma dependiente)

`Σ(x : A). B(x)` = par `(a, b)` donde `b : B(a)`.

- Si `B` no depende de `x`: `Σ(x:A).B ≡ A × B` (producto cartesiano).
- Si `B` depende de `x`: permite empaquetar datos + su propiedad.

Ejemplo: `Σ(n : Nat). Vec A n` = lista de longitud desconocida (el primero es la
longitud, el segundo es el vector de esa longitud).

### 4.3 Por qué los índices de Bruijn

Las variables con nombre crean problemas de captura en la sustitución.
Con **índices de Bruijn** (de Bruijn, 1972):
- No hay nombres de variable.
- `var(0)` = variable ligada por el binder más cercano.
- `var(1)` = binder a un nivel más arriba, etc.
- La sustitución y el shift son funciones totales y libres de errores de captura.

---

## 5. Tipos inductivos

### 5.1 Qué es un inductivo

Un tipo inductivo `I` se define por:
1. Sus **parámetros** (tipos que lo parametrizan).
2. Sus **constructores** (las únicas formas de construir valores de tipo `I`).

Ejemplo:
```
Nat ::= zero : Nat
      | succ : Nat → Nat
```

### 5.2 Eliminación con motivo (Goguen & McKinna, 2006)

Para razonar sobre un valor de tipo `I`, se usa un **recursor** que requiere:
- Un **motivo** `M : I → Type` (qué queremos probar sobre el valor).
- Una **rama** por cada constructor (cómo probarlo para cada caso).

```
I.rec : Π(M : I → Type).
         (∀ constructores c. Π args. M (c args)) →
         Π(x : I). M x
```

El `case` del kernel se **compila** a esta aplicación de recursor.

### 5.3 Cobertura exhaustiva

El kernel debe verificar que el `case` cubre **todos** los constructores
exactamente una vez. Sin esto, el recursor no existe (está indefinido).

---

## 6. Universos y jerarquía

### 6.1 El problema de Type : Type

Si `Type : Type`, se puede construir la **paradoja de Girard** (análoga a la
paradoja de Russell): el tipo de todos los tipos se contiene a sí mismo, y eso
genera inconsistencia.

### 6.2 Solución: jerarquía de universos

```
Type 0 : Type 1 : Type 2 : ...
```

`Type 0` contiene los tipos "normales" (Nat, Bool, etc.).
`Type 1` contiene `Type 0` y los tipos parametrizados por tipos.
Ningún universo se contiene a sí mismo.

**Regla Sort**:
```
Γ ⊢ Sort(u) : Sort(u+1)      (no Sort(u) : Sort(u))
```

---

## 7. λ-cálculo: de no tipado a dependiente

### 7.1 λ-cálculo no tipado (Church, 1932)

Sintaxis: `t ::= x | λx.t | t t`

Regla β: `(λx.t) s → t[s/x]`

Paradoja: `(λx. x x)(λx. x x)` reduce a sí mismo infinitamente.
No hay modelo de tipos sin inconsistencias si se permite auto-aplicación irrestricta.

### 7.2 λ-cálculo simplemente tipado (Church, 1940)

Tipos: `τ ::= B | τ → τ`

Reglas:
```
─────────────── [Var]        Γ,x:τ ⊢ t : σ
Γ, x:τ ⊢ x : τ              ─────────────────── [Abs]
                             Γ ⊢ λx.t : τ → σ

Γ ⊢ f : τ → σ    Γ ⊢ a : τ
──────────────────────────── [App]
        Γ ⊢ f a : σ
```

Propiedades: **terminación** (todas las reducciones terminan), **soundness**.
Limitación: no hay polimorfismo ni dependencia.

### 7.3 Hindley–Milner (Milner, 1978)

Añade **polimorfismo paramétrico** (`let`-polymorphism) con inferencia de tipos
(algoritmo W). No tiene tipos dependientes.

### 7.4 Martin-Löf ITT (1975)

Primer sistema con tipos dependientes completo y consistente.
`Π` = ∀, `Σ` = ∃. Base del kernel del proyecto.

**Axiomas clave**:
- No LEM (`A ∨ ¬A` no es axioma).
- `Sort u : Sort (u+1)` (no impredicativo).
- `Σ` y `Π` dependientes.

### 7.5 System F (Girard, 1972)

Polimorfismo de segundo orden impredicativo: `∀α. τ`.
**Paradoja de Girard** surge en System U (extensión de System F con
auto-cuantificación de tipos de tipos), probando que la impredicatividad
sin restricción es inconsistente.

### 7.6 Calculus of Constructions (CoC, Coquand & Huet, 1988)

Unifica System F con tipos dependientes. Es la base de Coq.
El kernel del proyecto es un CIC simplificado (CoC + inductivos).

### 7.7 HoTT (Homotopy Type Theory, 2013)

Extiende Martin-Löf con identidad homotópica (univalencia).
Fuera del scope del kernel MVP pero es el estado del arte.

---

## 8. Conversión definicional y NbE

### 8.1 ¿Por qué hace falta conversión?

En tipos dependientes, tipos distintos **sintácticamente** pueden ser iguales
**semánticamente**. Por ejemplo:

```
app(lam(var(0)), sort(0))  ≡  sort(0)       (β-reducción)
lam(app(f, var(0)))        ≡  f              (η-expansión, si f : Π A B)
```

El kernel debe decidir esta igualdad para aceptar términos correctos.

### 8.2 NbE (Normalization by Evaluation)

**Idea** (Berger & Schwichtenberg, 1991): en lugar de reducir con reescrituras
(que pueden ciclar o ser lentas), **evaluar semánticamente** a un dominio de
valores y luego **reificar** a forma normal.

```
eval : Term → Value       (semántica denotacional)
reify : Type × Value → Term   (vuelta a sintaxis normal)
```

Propiedades:
- **Total**: siempre termina.
- **Correcto**: el resultado es la forma β,η-normal del término.
- **Eficiente**: no requiere buscar redexes.

### 8.3 η-expansión

`η` dice que `f ≡ λx. f x` si `f : Π A B`.
Sin η, el kernel rechazaría términos equivalentes que difieren en forma
(p. ej. una función punto libre vs. punto a punto).
Se implementa en la fase de **reificación** de NbE.

---

## 9. Correspondencia Curry–Howard

| Lógica | Teoría de tipos | Prolog/Programa |
|--------|-----------------|-----------------|
| Proposición | Tipo | Especificación |
| Prueba | Término | Programa |
| `A → B` | `Π(x:A).B` (no dep.) | Función |
| `A ∧ B` | `Σ(x:A).B` (no dep.) | Par |
| `∀x. P(x)` | `Π(x:A).P(x)` | Función dependiente |
| `∃x. P(x)` | `Σ(x:A).P(x)` | Par dependiente |
| Contradicción | Tipo vacío `Empty` | Programa que nunca devuelve |

El kernel es un **verificador de pruebas**: `check([], t, T, ok)` confirma que
`t` es una prueba del teorema `T`.

---

## 10. Bibliografía normativa

1. **Dunfield & Krishnaswami** — *Bidirectional Typechecking*, JFP 31(4), 2021.
   Base del algoritmo check/infer del kernel.
2. **Berger & Schwichtenberg** — *An Inverse of the Evaluation Functional for Typed
   λ-calculi*, LICS 1991. NbE original.
3. **Abel, Coquand & Dybjer** — *Normalization by Evaluation for Martin-Löf Type Theory
   with Typed Equality Judgements*, LICS 2007. NbE para tipos dependientes.
4. **Goguen & McKinna** — *Eliminating Dependent Pattern Matching*, JFP 16(3), 2006.
   Eliminación con motivo (compilación de case a recursor).
5. **de Bruijn** — *Lambda-Calculus Notation with Nameless Dummies*, 1972.
   Índices de Bruijn.
6. **Martin-Löf** — *Intuitionistic Type Theory*, Bibliopolis, 1984.
   Sistema de tipos base.
7. **Coquand & Huet** — *The Calculus of Constructions*, Information and Computation,
   1988. CIC simplificado.
8. **Pierce** — *Types and Programming Languages*, MIT Press, 2002. Cap. 6–9 para
   λ-cálculo, sustitución y shift.

---

## 11. Conexión directa con las reglas del kernel

| Teoría | Regla(s) en `reglas/` | Módulo |
|--------|-----------------------|--------|
| Sort/universos (§6) | R-01 | `syntax.pl` |
| Π-formación (§4.1) | R-02 | `bidirectional.pl` |
| λ-intro (§7.2) | R-03 | `bidirectional.pl` |
| App / eliminación Π (§4.1) | R-04 | `bidirectional.pl` |
| Inductivos (§5) | R-05 | `inductive.pl` |
| Case → recursor (§5.2) | R-06 | `inductive.pl` |
| de Bruijn (§4.3) | R-07 | `substitution.pl` |
| Conversión β / NbE (§8) | R-08 | `conversion.pl` |
| η-expansión (§8.3) | R-09 | `nbe.pl` |
| Bidireccional (§3.2) | R-10 | `bidirectional.pl` |
