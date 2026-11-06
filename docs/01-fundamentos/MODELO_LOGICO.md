# Modelo Lógico del Kernel — Especificación Formal Completa

> **Documento normativo central.** Toda implementación Prolog debe derivarse de este archivo.
> Corrige erratas detectadas en `ESPECIFICACION_KERNEL.md` (ver §8).
> Versión 1.0

---

## 1. Sintaxis Abstracta (índices de Bruijn)

```prolog
%% Términos del lenguaje core
%%
%%  sort(U)                 universo de nivel U ∈ ℕ        ( = Type U )
%%  var(I)                  variable ligada (índice de Bruijn ≥ 0)
%%  pi(A, B)                Π(x:A).B    — B tiene var(0) libre
%%  lam(Body)               λx.Body     — Body tiene var(0) libre
%%  app(F, A)               F aplicado a A
%%  sigma(A, B)             Σ(x:A).B    — B tiene var(0) libre
%%  pair(X, Y)              par dependiente
%%  fst(P)                  primera proyección de P
%%  snd(P)                  segunda proyección de P
%%  inductive(Name, Params) tipo inductivo aplicado (nat, list, vec …)
%%  constructor(Name, Args) constructor aplicado (zero, succ, nil, cons …)
%%  case(Scrut, Motive, Branches)  eliminación inductiva
%%    Branches = [branch(CtorName, Arity, Body), ...]
```

**Invariante de bien formación**: todas las ocurrencias de `var(I)` en un término
abierto de profundidad `d` satisfacen `I < d`; en un término cerrado no hay variables
libres.

### 1.1 Contexto

```prolog
%% Γ ::= []              contexto vacío
%%     | [T | Γ]         T es el tipo de var(0); el resto se indexa a partir de 1
%%
%% nth_type(+Ctx, +I, -T)
nth_type([T|_],  0, T) :- !.
nth_type([_|Ctx], I, T) :- I > 0, I1 is I - 1, nth_type(Ctx, I1, T).
```

---

## 2. Operaciones sobre índices de Bruijn

### 2.1 Shift

`shift(+Term, +Delta, +Cutoff, -Result)`

Incrementa en `Delta` todas las variables libres con índice ≥ `Cutoff`.
Se llama al atravesar un binder: `Cutoff` crece en 1 por cada `lam/pi/sigma` anidado.

```prolog
shift(var(I), D, C, var(I1)) :- I >= C, !, I1 is I + D.
shift(var(I), _, _, var(I)).
shift(sort(U), _, _, sort(U)).
shift(pi(A,B),    D, C, pi(A1,B1))    :- shift(A,D,C,A1), C1 is C+1, shift(B,D,C1,B1).
shift(lam(Body),  D, C, lam(Body1))   :- C1 is C+1, shift(Body,D,C1,Body1).
shift(app(F,A),   D, C, app(F1,A1))   :- shift(F,D,C,F1), shift(A,D,C,A1).
shift(sigma(A,B), D, C, sigma(A1,B1)) :- shift(A,D,C,A1), C1 is C+1, shift(B,D,C1,B1).
shift(pair(X,Y),  D, C, pair(X1,Y1))  :- shift(X,D,C,X1), shift(Y,D,C,Y1).
shift(fst(P),  D, C, fst(P1))  :- shift(P,D,C,P1).
shift(snd(P),  D, C, snd(P1))  :- shift(P,D,C,P1).
shift(inductive(N,Ps), D, C, inductive(N,Ps1)) :- maplist(shift_at(D,C), Ps, Ps1).
shift(constructor(N,As),D,C,constructor(N,As1)):- maplist(shift_at(D,C), As, As1).
shift(case(S,Mo,Brs),D,C,case(S1,Mo1,Brs1))   :-
    shift(S,D,C,S1), shift(Mo,D,C,Mo1),
    maplist(shift_branch(D,C), Brs, Brs1).

shift_at(D,C,T,T1)                              :- shift(T,D,C,T1).
shift_branch(D,C, branch(N,Ar,Body), branch(N,Ar,Body1)) :-
    C1 is C + Ar, shift(Body,D,C1,Body1).
```

### 2.2 Sustitución

`subst(+Term, +Repl, -Result)` — sustituye `var(0)` por `Repl` en `Term`
(= `Term[Repl/0]`), cerrando el hueco de índices.

```prolog
%% Interfaz pública
subst(Term, Repl, Result) :- substitute(Term, Repl, 0, Result).

%% substitute(+Term, +Repl, +Depth, -Result)
substitute(var(I), Repl, D, Result) :- !,
    ( I =:= D
    -> shift(Repl, D, 0, Result)      % sustituir, ajustar Repl para profundidad D
    ; ( I > D
      -> Result = var(I1), I1 is I-1  % cerrar hueco
      ;  Result = var(I) )             % índice inferior: sin cambio
    ).
substitute(sort(U), _, _, sort(U)).
substitute(pi(A,B),    R, D, pi(A1,B1))    :- substitute(A,R,D,A1), D1 is D+1, substitute(B,R,D1,B1).
substitute(lam(Body),  R, D, lam(Body1))   :- D1 is D+1, substitute(Body,R,D1,Body1).
substitute(app(F,A),   R, D, app(F1,A1))   :- substitute(F,R,D,F1), substitute(A,R,D,A1).
substitute(sigma(A,B), R, D, sigma(A1,B1)) :- substitute(A,R,D,A1), D1 is D+1, substitute(B,R,D1,B1).
substitute(pair(X,Y),  R, D, pair(X1,Y1))  :- substitute(X,R,D,X1), substitute(Y,R,D,Y1).
substitute(fst(P),  R, D, fst(P1))  :- substitute(P,R,D,P1).
substitute(snd(P),  R, D, snd(P1))  :- substitute(P,R,D,P1).
substitute(inductive(N,Ps), R,D, inductive(N,Ps1)) :- maplist(substitute_at(R,D), Ps, Ps1).
substitute(constructor(N,As),R,D,constructor(N,As1)):- maplist(substitute_at(R,D), As, As1).
substitute(case(S,Mo,Brs),R,D,case(S1,Mo1,Brs1))   :-
    substitute(S,R,D,S1), substitute(Mo,R,D,Mo1),
    maplist(substitute_branch(R,D), Brs, Brs1).

substitute_at(R,D,T,T1)                                     :- substitute(T,R,D,T1).
substitute_branch(R,D, branch(N,Ar,Body), branch(N,Ar,Body1)) :-
    D1 is D+Ar, substitute(Body,R,D1,Body1).
```

---

## 3. Juicios de tipo (judgment forms)

```
Γ ⊢ T type         T es un tipo bien formado en Γ
Γ ⊢ t ⇒ T         t sintetiza (infiere) tipo T
Γ ⊢ t ⇐ T         t chequea contra tipo T
Γ ⊢ t ≡ u         t y u son definitivamente iguales en Γ
```

Predicados Prolog internos:

```prolog
infer(+Ctx, +Term, -Type)         % Γ ⊢ t ⇒ T
check(+Ctx, +Term, +Type)         % Γ ⊢ t ⇐ T  (falla si incorrecto)
conversion(+Ctx, +T1, +T2)        % Γ ⊢ t ≡ u  (falla si distintos)
```

API pública exportada por `kernel.pl`:

```prolog
check/4    % check(+Ctx, +Term, +Type, -Result)   Result = ok | error(Code,Msg)
infer/3    % infer(+Ctx, +Term, -Type)
convert/4  % convert(+Ctx, +T1, +T2, -Result)
nbe/3      % nbe(+Ctx, +Term, -NormalForm)
```

---

## 4. Reglas de inferencia (completas y correctas)

### R-01 · Sort / Universidad

```
              u ∈ ℕ
    ─────────────────────────────  [Sort]
    Γ ⊢ sort(u) ⇒ sort(u+1)
```

```prolog
infer(_, sort(U), sort(U1)) :-
    integer(U), U >= 0, U1 is U + 1.
```

### R-Var · Variable

```
    var(i) ∈ dom(Γ)    Γ(i) = T
    ──────────────────────────────  [Var]
         Γ ⊢ var(i) ⇒ T
```

```prolog
infer(Ctx, var(I), T) :-
    nth_type(Ctx, I, T).
```

### R-02 · Π-formación

```
    Γ ⊢ A ⇒ sort(u)    Γ, A ⊢ B ⇒ sort(v)
    ──────────────────────────────────────────  [Π-F]
         Γ ⊢ pi(A,B) ⇒ sort(max(u,v))
```

**Nota**: B se infiere en el contexto **extendido** `[A|Γ]`; no en Γ solo.

```prolog
infer(Ctx, pi(A, B), sort(Max)) :-
    infer(Ctx, A, sort(U)),
    infer([A|Ctx], B, sort(V)),       % ← [A|Ctx], no Ctx
    Max is max(U, V).
```

### R-03 · λ-introducción  (solo check — Lam NO es inferable sin anotación)

```
    Γ ⊢ A ⇒ sort(_)    Γ, A ⊢ b ⇐ B
    ────────────────────────────────────  [Λ-I]
         Γ ⊢ lam(b) ⇐ pi(A, B)
```

```prolog
check(Ctx, lam(Body), pi(A, B)) :-
    infer(Ctx, A, sort(_)),
    check([A|Ctx], Body, B).
```

### R-04 · Aplicación (eliminación de Π)

```
    Γ ⊢ f ⇒ pi(A, B)    Γ ⊢ a ⇐ A
    ──────────────────────────────────  [App-E]
        Γ ⊢ app(f,a) ⇒ B[a/0]
```

```prolog
infer(Ctx, app(F, A), BSubst) :-
    infer(Ctx, F, pi(Dom, Cod)),
    check(Ctx, A, Dom),
    subst(Cod, A, BSubst).            % B[a/0]  — NO =:=; es subst/3
```

### R-Sigma · Σ-formación

```
    Γ ⊢ A ⇒ sort(u)    Γ, A ⊢ B ⇒ sort(v)
    ──────────────────────────────────────────  [Σ-F]
         Γ ⊢ sigma(A,B) ⇒ sort(max(u,v))
```

```prolog
infer(Ctx, sigma(A, B), sort(Max)) :-
    infer(Ctx, A, sort(U)),
    infer([A|Ctx], B, sort(V)),
    Max is max(U, V).
```

### R-Pair · par dependiente (introducción de Σ)

```
    Γ ⊢ a ⇐ A    Γ ⊢ b ⇐ B[a/0]
    ───────────────────────────────  [Pair-I]
    Γ ⊢ pair(a,b) ⇐ sigma(A, B)
```

```prolog
check(Ctx, pair(A, B), sigma(TA, TB)) :-
    check(Ctx, A, TA),
    subst(TB, A, TBInst),
    check(Ctx, B, TBInst).
```

### R-Fst / R-Snd · proyecciones

```
    Γ ⊢ p ⇒ sigma(A, B)          Γ ⊢ p ⇒ sigma(A, B)
    ───────────────────── [Fst]   ─────────────────────────── [Snd]
    Γ ⊢ fst(p) ⇒ A               Γ ⊢ snd(p) ⇒ B[fst(p)/0]
```

```prolog
infer(Ctx, fst(P), A) :-
    infer(Ctx, P, sigma(A, _)).

infer(Ctx, snd(P), BSubst) :-
    infer(Ctx, P, sigma(_, B)),
    subst(B, fst(P), BSubst).
```

### R-Ind · tipo inductivo

```
    Name ∈ Sig    Γ ⊢ Params : inductive_param_types(Name)
    ─────────────────────────────────────────────────────────  [Ind]
    Γ ⊢ inductive(Name, Params) ⇒ sort(U)
```

```prolog
infer(Ctx, inductive(Name, Params), sort(U)) :-
    inductive_sort(Name, U),
    inductive_param_types(Name, PTs),
    check_args(Ctx, Params, PTs).
```

### R-Ctor · constructor

```
    c ∈ ctors(I)    Γ ⊢ Args : constructor_arg_types(c, Params)
    ───────────────────────────────────────────────────────────────  [Ctor]
    Γ ⊢ constructor(c, Args) ⇒ inductive(I, Params_inst)
```

```prolog
infer(Ctx, constructor(C, Args), RetType) :-
    constructor_type(C, ConTy),
    check_args_ret(Ctx, Args, ConTy, RetType).
```

### R-Case · eliminación inductiva

```
    Γ ⊢ scrut ⇒ inductive(I, Ps)
    Γ ⊢ Motive : inductive(I,Ps) → sort(u)
    ∀ cᵢ ∈ ctors(I):  Γ, args_i ⊢ branchᵢ ⇐ Motive(constructor(cᵢ, args_i))
    coverage(I, branches) = exhaustivo
    ─────────────────────────────────────────────────────────────────────────── [Case-E]
    Γ ⊢ case(scrut, Motive, branches) ⇒ Motive(scrut)
```

```prolog
infer(Ctx, case(Scrut, Motive, Branches), MotiveApplied) :-
    infer(Ctx, Scrut, inductive(I, Ps)),
    check_motive(Ctx, I, Ps, Motive),
    coverage_check(I, Branches),
    check_branches(Ctx, I, Ps, Motive, Branches),
    apply_motive(Motive, Scrut, MotiveApplied).
```

### R-Conv · subsumción (fallback universal de check)

```
    Γ ⊢ t ⇒ T    Γ ⊢ T ≡ U
    ───────────────────────────  [Conv]
    Γ ⊢ t ⇐ U
```

```prolog
% Cláusula de último recurso en check: infer + conversión
check(Ctx, Term, Expected) :-
    infer(Ctx, Term, Inferred),
    conversion(Ctx, Inferred, Expected).
```

---

## 5. Conversión definicional (NbE)

### 5.1 Dominio semántico (valores)

```prolog
%  vsort(U)                   universo evaluado
%  vpi(VDom, Closure)         tipo función: dominio evaluado + clausura del codominio
%  vsigma(VDom, Closure)      tipo suma:    dominio evaluado + clausura
%  vlam(Closure)              función: clausura del cuerpo
%  vpair(V1, V2)              par de valores
%  vneutral(Head, Spine)      término en forma normal neutra
%     Head  ::= var(I) | fst(V) | snd(V) | case(V,VM)
%     Spine ::= [] | [Arg|Spine]   (args acumulados, primero = más reciente)
%  vinductive(Name, PVals)
%  vconstructor(Name, AVals)
%
%  closure(Env, Term)   — entorno de evaluación + término a evaluar
```

### 5.2 Evaluación

```prolog
%% eval(+Env, +Term, -Value)
%%   Env = lista de Values (posición 0 = valor de var(0))

eval(_, sort(U),         vsort(U)).
eval(Env, var(I), V)    :- ( nth0(I, Env, V) -> true ; V = vneutral(var(I), []) ).
eval(Env, pi(A,B),   vpi(VA, closure(Env,B)))    :- eval(Env, A, VA).
eval(Env, sigma(A,B), vsigma(VA, closure(Env,B))) :- eval(Env, A, VA).
eval(Env, lam(Body), vlam(closure(Env,Body))).
eval(Env, app(F,A),  VR) :- eval(Env,F,VF), eval(Env,A,VA), do_apply(VF,VA,VR).
eval(Env, pair(X,Y), vpair(VX,VY)) :- eval(Env,X,VX), eval(Env,Y,VY).
eval(Env, fst(P), V) :- eval(Env,P,VP), do_fst(VP,V).
eval(Env, snd(P), V) :- eval(Env,P,VP), do_snd(VP,V).
eval(Env, inductive(N,Ps),  vinductive(N,PVs))   :- maplist(eval(Env), Ps, PVs).
eval(Env, constructor(N,As),vconstructor(N,AVs)) :- maplist(eval(Env), As, AVs).
eval(Env, case(Scrut,Motive,Brs), V) :-
    eval(Env, Scrut, VS),
    ( VS = vconstructor(N, ArgVs)
    ->  select_branch(N, Brs, _Ar, Body),
        append(ArgVs, Env, Env2),          % args de constructor al frente del entorno
        eval(Env2, Body, V)
    ;   eval(Env, Motive, VM),
        V = vneutral(case(VS,VM), [])
    ).

%% do_apply(+VFun, +VArg, -VResult)
do_apply(vlam(closure(Env,Body)), VA, V) :- eval([VA|Env], Body, V).
do_apply(vneutral(H,Sp), VA, vneutral(H,[VA|Sp])).

%% do_fst / do_snd
do_fst(vpair(V,_), V).
do_fst(vneutral(H,Sp), vneutral(fst(H),Sp)).

do_snd(vpair(_,V), V).
do_snd(vneutral(H,Sp), vneutral(snd(H),Sp)).
```

### 5.3 Reificación (quote: valor → forma normal)

```prolog
%% reify(+Lvl, +Type, +Value, -NormalForm)
%%   Lvl = número de variables de tipo introducidas (para η-expansión con vars frescas)

reify(_,   _,          vsort(U),     sort(U)).
reify(Lvl, vsort(_),   vpi(VA,Clos), pi(A_nf, B_nf)) :-
    reify(Lvl, vsort(0), VA, A_nf),
    FreshV = vneutral(var(Lvl),[]),
    apply_closure(Clos, FreshV, VB),
    Lvl1 is Lvl + 1,
    reify(Lvl1, vsort(0), VB, B_nf).
reify(Lvl, vpi(VA,TClos), VF, lam(Body_nf)) :-   % η-expansión para funciones
    FreshV = vneutral(var(Lvl),[]),
    do_apply(VF, FreshV, VBody),
    apply_closure(TClos, FreshV, VBTy),
    Lvl1 is Lvl + 1,
    reify(Lvl1, VBTy, VBody, Body_nf).
reify(Lvl, vsigma(VA,_), vpair(V1,V2), pair(A_nf,B_nf)) :-
    reify(Lvl, VA, V1, A_nf),
    reify(Lvl, unknown, V2, B_nf).
reify(Lvl, _, vneutral(H,Sp), Term) :-
    reify_neutral(Lvl, H, Sp, Term).
reify(Lvl, _, vinductive(N,PVs), inductive(N,Ps)) :-
    maplist(reify(Lvl, unknown), PVs, Ps).
reify(Lvl, _, vconstructor(N,AVs), constructor(N,As)) :-
    maplist(reify(Lvl, unknown), AVs, As).

reify_neutral(_Lvl, var(I), [], var(I)).
reify_neutral(Lvl,  H, [VA|Sp], app(F,A_nf)) :-
    reify_neutral(Lvl, H, Sp, F),
    reify(Lvl, unknown, VA, A_nf).

%% apply_closure(+closure(Env,Body), +Value, -ResultValue)
apply_closure(closure(Env,Body), V, VR) :- eval([V|Env], Body, VR).
```

### 5.4 NbE y conversión

```prolog
%% nbe(+Ctx, +Term, -NormalForm)
nbe(Ctx, Term, NF) :-
    length(Ctx, Lvl),
    mk_env(Ctx, Lvl, Env),
    eval(Env, Term, V),
    reify(Lvl, unknown, V, NF).

%% mk_env: construye un entorno de valores neutros para las variables del contexto
mk_env([], _, []).
mk_env([_|Ctx], Lvl, [vneutral(var(I),[])|Env]) :-
    length(Ctx, I),
    mk_env(Ctx, Lvl, Env).

%% conversion(+Ctx, +T1, +T2)   — falla si distintos
conversion(Ctx, T1, T2) :-
    nbe(Ctx, T1, NF1),
    nbe(Ctx, T2, NF2),
    NF1 == NF2.                   % comparación estructural, NO =:= (aritmético)
```

---

## 6. Signature de inductivos (hechos Prolog)

```prolog
%% inductive_sort(+Name, -UniverseLevel)
inductive_sort(nat,   0).
inductive_sort(list,  1).
inductive_sort(vec,   1).
inductive_sort(sigma, 1).
inductive_sort(unit,  0).
inductive_sort(empty, 0).
inductive_sort(bool,  0).
inductive_sort(prod,  1).

%% inductive_ctors(+Name, -ListOfCtorNames)
inductive_ctors(nat,   [zero, succ]).
inductive_ctors(list,  [nil, cons]).
inductive_ctors(vec,   [vnil, vcons]).
inductive_ctors(bool,  [true_, false_]).
inductive_ctors(unit,  [unit_mk]).
inductive_ctors(empty, []).
inductive_ctors(prod,  [mk_prod]).
inductive_ctors(sigma, [mk_sigma]).

%% constructor_type(+Name, -Type)
%%   Tipo codificado en la sintaxis del kernel (índices de Bruijn)
constructor_type(zero,  inductive(nat,[])).
constructor_type(succ,  pi(inductive(nat,[]), inductive(nat,[]))).

%  nil : Π(A : Type 0). List A
constructor_type(nil,
    pi(sort(0),
       inductive(list, [var(0)]))).

%  cons : Π(A:Type). A → List A → List A
constructor_type(cons,
    pi(sort(0),
    pi(var(0),
    pi(inductive(list,[var(1)]),
       inductive(list,[var(2)]))))).

%  vnil : Π(A:Type). Vec A zero
constructor_type(vnil,
    pi(sort(0),
       inductive(vec,[var(0), constructor(zero,[])]))).

%  vcons : Π(A:Type). Π(n:Nat). A → Vec A n → Vec A (succ n)
constructor_type(vcons,
    pi(sort(0),
    pi(inductive(nat,[]),
    pi(var(1),
    pi(inductive(vec,[var(2),var(1)]),
       inductive(vec,[var(3), constructor(succ,[var(2)])])))))).

constructor_type(unit_mk, inductive(unit,[])).
constructor_type(true_,   inductive(bool,[])).
constructor_type(false_,  inductive(bool,[])).

%  mk_sigma : Π(A:Type). Π(B:A→Type). Π(a:A). B a → Sigma A B
constructor_type(mk_sigma,
    pi(sort(0),
    pi(pi(var(0), sort(0)),
    pi(var(1),
    pi(app(var(1),var(0)),
       inductive(sigma,[var(3),var(2)])))))).

%  mk_prod : Π(A:Type). Π(B:Type). A → B → Prod A B
constructor_type(mk_prod,
    pi(sort(0),
    pi(sort(0),
    pi(var(1),
    pi(var(1),
       inductive(prod,[var(3),var(2)])))))).
```

---

## 7. Coverage check y compilación de Case a recursor

```prolog
%% coverage_check(+InductiveName, +Branches)
%%   Verifica que las ramas cubren TODOS los constructores exactamente una vez.
coverage_check(I, Branches) :-
    inductive_ctors(I, Required),
    maplist([branch(N,_,_)]>>(member(N, Required)), Branches),
    length(Required, Len),
    length(Branches, Len).          % ni faltan ni sobran ramas

%% check_branches(+Ctx, +I, +Ps, +Motive, +Branches)
check_branches(_Ctx, _I, _Ps, _Motive, []).
check_branches(Ctx, I, Ps, Motive, [branch(C, Ar, Body)|Rest]) :-
    constructor_type(C, ConTy),
    build_branch_ctx(Ctx, ConTy, Ar, BCtx),
    build_branch_motive(Motive, C, Ar, BMotiveTy),
    check(BCtx, Body, BMotiveTy),
    check_branches(Ctx, I, Ps, Motive, Rest).

%% apply_motive(+Motive, +Scrut, -Result)
apply_motive(Motive, Scrut, app(Motive, Scrut)).
```

---

## 8. Errores en la spec anterior — tabla de correcciones

| # | Archivo | Problema | Corrección aplicada en §4 |
|---|---------|----------|--------------------------|
| 1 | `ESPECIFICACION_KERNEL.md` §4 | `infer(Γ, Lam(body), Pi(A,B)) :- infer(Γ, A, …)` — `A` no está en el término; Lam es **no inferable** sin anotación | R-03 solo en `check`, no en `infer` |
| 2 | `04-regla-eliminacion-aplicacion.md` | `B =:= substitute(BCod, a, B)` — `=:=` es comparación aritmética, no sustitución | Usar `subst(Cod, A, BSubst)` |
| 3 | `10-regla-chequeo-inferencia-bidirional.md` | Mismo error `=:=` | Ídem |
| 4 | `02-regla-formacion-pi.md` | `infer(Γ, B, Sort(V), _)` chequea B en `Γ` — falta extender con A | `infer([A\|Ctx], B, sort(V))` |
| 5 | Varias | Mezcla de `infer/3` e `infer/4` | Interno = `infer/3`; público = `check/4` |
| 6 | `08-regla-conversion-beta.md` | `V1 =:= V2` — comparación aritmética | `NF1 == NF2` (comparación estructural) |

---

## 9. Tests mínimos de validación (Prolog)

```prolog
%% swipl -g "run_tests, halt" -t "halt(1)" -l test_modelo.pl
:- use_module(kernel).
:- begin_tests(modelo_logico).

%% Sort
test(sort_ok)         :- infer([], sort(0), sort(1)).
test(sort_bad,  fail) :- infer([], sort(0), sort(0)).

%% Var
test(var_ok) :-
    infer([sort(0)], var(0), sort(0)).

%% Π
test(pi_ok) :-
    infer([], pi(sort(0), sort(0)), sort(1)).
test(pi_extendido) :-
    % Π(A:Type0). A → Type0  — el codominio usa var(0)
    infer([], pi(sort(0), pi(var(0), sort(0))), sort(1)).

%% λ (solo check)
test(lam_check_ok) :-
    check([], lam(var(0)), pi(sort(0), sort(0))).
test(lam_infer_falla, fail) :-
    infer([], lam(var(0)), _).         % Lam no es inferable

%% App
test(app_ok) :-
    infer([], app(lam(var(0)), sort(0)), sort(0)).

%% Sustitución
test(subst_var0) :-
    subst(var(0), sort(1), sort(1)).
test(subst_lam_deep) :-
    subst(lam(var(0)), sort(0), lam(var(0))).  % var(0) en cuerpo del lam = profundidad 1

%% Conversión β
test(beta_conv) :-
    conversion([], app(lam(var(0)), sort(0)), sort(0)).

%% Conversión η
test(eta_conv) :-
    % f : Π(A:Type).A → λx.f x  ≡  f
    Ctx = [pi(sort(0), sort(0))],
    conversion(Ctx, lam(app(var(1), var(0))), var(0)).

%% Inductivos
test(nat_zero) :-
    infer([], constructor(zero, []), inductive(nat, [])).
test(nat_succ) :-
    infer([], constructor(succ, [constructor(zero,[])]), inductive(nat,[])).

%% Consistencia (Sort u ≠ Sort u)
test(no_impredicativo, fail) :-
    infer([], sort(0), sort(0)).

:- end_tests(modelo_logico).
```

---

## 10. Mapa de módulos → reglas

| Módulo Prolog       | Reglas que implementa |
|---------------------|-----------------------|
| `substitution.pl`   | Shift (§2.1), Subst (§2.2) |
| `nbe.pl`            | eval (§5.2), reify (§5.3), apply_closure |
| `conversion.pl`     | nbe (§5.4), conversion |
| `bidirectional.pl`  | R-01, R-Var, R-02, R-03, R-04, R-Sigma, R-Pair, R-Fst/Snd, R-Conv |
| `inductive.pl`      | R-Ind, R-Ctor, R-Case, coverage_check, signature fija |
| `kernel.pl`         | API pública check/4, infer/3, convert/4, nbe/3 |
| `errors.pl`         | Wrappers con reporte de error |
| `test_kernel.pl`    | §9 y tests adicionales |
