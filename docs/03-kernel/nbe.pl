%% ---------------------------------------------------------------
%% nbe.pl — Normalization by Evaluation
%% Implementa R-08 (conversión β) y R-09 (expansión η) del kernel
%% Implementa MODELO_LOGICO.md §5 (dominio semántico, eval, reify)
%% ---------------------------------------------------------------

:- module(nbe, [eval/3, reify/4, apply_closure/3, nbe/3]).

:- use_module(substitution, [shift/4]).

%% -----------------------------------------------------------------
%% Dominio semántico (valores):
%%
%%   vsort(U)                    universo
%%   vpi(VDom, Closure)          tipo Π: dominio + clausura del codominio
%%   vsigma(VDom, Closure)       tipo Σ: dominio + clausura
%%   vlam(Closure)               función lambda
%%   vpair(V1, V2)               par dependiente
%%   vneutral(Head, Spine)       término neutro bloqueado
%%     Head  ::= var(I) | fst(V) | snd(V) | case(V, VMotive)
%%     Spine ::= [] | [Arg|Rest]   (args acumulados, primero = más reciente)
%%   vinductive(Name, PVals)     tipo inductivo aplicado
%%   vconstructor(Name, AVals)   constructor aplicado
%%
%%   closure(Env, Term)          entorno + término a evaluar
%% -----------------------------------------------------------------

%% -----------------------------------------------------------------
%% eval(+Env, +Term, -Value)
%%   Env = lista de Values; posición 0 = valor de var(0).
%% -----------------------------------------------------------------

%% Variable Prolog sin vincular: valor neutro bloqueado (DEBE ir antes de sort)
eval(_Env, V, vneutral(V, [])) :- var(V), !.

eval(_Env, sort(U), vsort(U)).

eval(Env, var(I), V) :-
    ( nth0(I, Env, V)
    -> true
    ; V = vneutral(var(I), [])
    ).

eval(Env, pi(A, B), vpi(VA, closure(Env, B))) :-
    eval(Env, A, VA).

eval(Env, sigma(A, B), vsigma(VA, closure(Env, B))) :-
    eval(Env, A, VA).

eval(Env, lam(_A, Body), vlam(closure(Env, Body))).

eval(Env, app(F, A), VR) :-
    eval(Env, F, VF),
    eval(Env, A, VA),
    do_apply(VF, VA, VR).

eval(Env, pair(X, Y), vpair(VX, VY)) :-
    eval(Env, X, VX),
    eval(Env, Y, VY).

eval(Env, fst(P), V) :-
    eval(Env, P, VP),
    do_fst(VP, V).

eval(Env, snd(P), V) :-
    eval(Env, P, VP),
    do_snd(VP, V).

eval(Env, inductive(N, Ps), vinductive(N, PVs)) :-
    maplist(eval_arg(Env), Ps, PVs).

eval(Env, constructor(N, As), vconstructor(N, AVs)) :-
    maplist(eval_arg(Env), As, AVs).

eval(Env, case(Scrut, Motive, Brs), V) :-
    eval(Env, Scrut, VS),
    ( VS = vconstructor(N, ArgVs)
    -> select_branch(N, Brs, _Ar, Body),
       append(ArgVs, Env, Env2),
       eval(Env2, Body, V)
    ;  eval(Env, Motive, VM),
       V = vneutral(case(VS, VM), [])
    ).

eval_arg(Env, T, V) :- eval(Env, T, V).

%% -----------------------------------------------------------------
%% do_apply(+VFun, +VArg, -VResult)
%% -----------------------------------------------------------------

do_apply(vlam(closure(Env, Body)), VA, V) :-
    eval([VA | Env], Body, V).

do_apply(vneutral(H, Sp), VA, vneutral(H, [VA | Sp])).

%% -----------------------------------------------------------------
%% do_fst / do_snd
%% -----------------------------------------------------------------

do_fst(vpair(V, _), V).
do_fst(vneutral(H, Sp), vneutral(fst(H), Sp)).

do_snd(vpair(_, V), V).
do_snd(vneutral(H, Sp), vneutral(snd(H), Sp)).

%% -----------------------------------------------------------------
%% select_branch(+CtorName, +Branches, -Arity, -Body)
%% -----------------------------------------------------------------

select_branch(N, [branch(N, Ar, Body) | _], Ar, Body).
select_branch(N, [_ | Rest], Ar, Body) :-
    select_branch(N, Rest, Ar, Body).

%% -----------------------------------------------------------------
%% reify(+Lvl, +Type, +Value, -NormalForm)
%%   Lvl = número de vars de tipo introducidas (para η-expansión)
%% -----------------------------------------------------------------

reify(_Lvl, _Type, vsort(U), sort(U)).

%% Π: reificar dominio, luego cuerpo con var fresca (η-expansión)
%%   El tipo (2º arg) no se usa aquí; se ignora con _Type.
reify(Lvl, _Type, vpi(VA, Clos), pi(A_nf, B_nf)) :-
    reify(Lvl, vsort(0), VA, A_nf),
    FreshV = vneutral(var(Lvl), []),
    apply_closure(Clos, FreshV, VB),
    Lvl1 is Lvl + 1,
    reify(Lvl1, vsort(0), VB, B_nf).

%% η-expansión para funciones: reify un valor en tipo Pi como lam(A, Body)
reify(Lvl, vpi(VA, TClos), VF, lam(A_nf, Body_nf)) :-
    reify(Lvl, vsort(0), VA, A_nf),
    FreshV = vneutral(var(Lvl), []),
    do_apply(VF, FreshV, VBody),
    apply_closure(TClos, FreshV, VBTy),
    Lvl1 is Lvl + 1,
    reify(Lvl1, VBTy, VBody, Body_nf).

%% Función lambda sin tipo conocido (fallback para conversión):
%%   se reifica el cuerpo aplicado a una var fresca, con dominio sort(0) por defecto.
reify(Lvl, unknown, vlam(closure(Env, Body)), lam(sort(0), Body_nf)) :-
    FreshV = vneutral(var(Lvl), []),
    eval([FreshV | Env], Body, VBody),
    Lvl1 is Lvl + 1,
    reify(Lvl1, unknown, VBody, Body_nf).

%% Σ: reificar par
reify(Lvl, vsigma(VA, _), vpair(V1, V2), pair(A_nf, B_nf)) :-
    reify(Lvl, VA, V1, A_nf),
    reify(Lvl, unknown, V2, B_nf).

%% valor neutro → forma normal neutral
reify(Lvl, _Type, vneutral(H, Sp), Term) :-
    reify_neutral(Lvl, H, Sp, Term).

%% inductivo aplicado
reify(Lvl, _Type, vinductive(N, PVs), inductive(N, Ps)) :-
    maplist(reify_val(Lvl), PVs, Ps).

%% constructor aplicado
reify(Lvl, _Type, vconstructor(N, AVs), constructor(N, As)) :-
    maplist(reify_val(Lvl), AVs, As).

%% -----------------------------------------------------------------
%% reify_neutral(+Lvl, +Head, +Spine, -Term)
%% -----------------------------------------------------------------

reify_neutral(_Lvl, V, [], V) :- var(V), !.

reify_neutral(_Lvl, var(I), [], var(I)).

reify_neutral(Lvl, H, [VA | Sp], app(F, A_nf)) :-
    reify_neutral(Lvl, H, Sp, F),
    reify(Lvl, unknown, VA, A_nf).

%% -----------------------------------------------------------------
%% apply_closure(+Closure, +Value, -ResultValue)
%% -----------------------------------------------------------------

apply_closure(closure(Env, Body), V, VR) :-
    eval([V | Env], Body, VR).

%% -----------------------------------------------------------------
%% nbe(+Ctx, +Term, -NormalForm)
%%   Construye entorno de vars neutras para el contexto, evalúa y reifica.
%% -----------------------------------------------------------------

nbe(Ctx, Term, NF) :-
    length(Ctx, Lvl),
    mk_env(Ctx, Env),
    eval(Env, Term, V),
    reify(Lvl, unknown, V, NF).

mk_env([], []).
mk_env([_ | Ctx], [vneutral(var(I), []) | Env]) :-
    length(Ctx, I),
    mk_env(Ctx, Env).

%% -----------------------------------------------------------------
%% Ayudante genérico para maplist de valores
%% -----------------------------------------------------------------

reify_val(Lvl, V, T) :- reify(Lvl, unknown, V, T).
