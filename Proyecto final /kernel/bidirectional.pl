%% ---------------------------------------------------------------
%% bidirectional.pl — Chequeo e inferencia de tipos (R-01, R-02, R-03, R-04, R-10)
%% Implementa MODELO_LOGICO.md §3 y §4
%% ---------------------------------------------------------------

:- module(bidirectional,
    [infer/3,
     check/3,
     nth_type/3,
     check_args_ret/4,
     strip_pis/3]).

:- use_module(substitution).
:- use_module(conversion).
:- use_module(inductive).

:- discontiguous infer/3.
:- discontiguous check/3.

%% -----------------------------------------------------------------
%% nth_type(+Ctx, +I, -T)
%%   Tipo de la variable de índice I en el contexto Ctx.
%%   Ctx = lista de tipos; posición 0 = tipo de var(0).
%% -----------------------------------------------------------------

nth_type([T|_], 0, T) :- !.
nth_type([_|Ctx], I, T) :-
    I > 0,
    I1 is I - 1,
    nth_type(Ctx, I1, T).

%% -----------------------------------------------------------------
%% infer(+Ctx, +Term, -Type)
%%   Γ ⊢ t ⇒ T  — t sintetiza su tipo T
%% -----------------------------------------------------------------

%% R-01: Sort
infer(_Ctx, sort(U), sort(U1)) :-
    integer(U),
    U >= 0,
    U1 is U + 1.

%% R-Var: Variable
infer(Ctx, var(I), T) :-
    nth_type(Ctx, I, T).

%% R-02: Π-formación
infer(Ctx, pi(A, B), sort(Max)) :-
    infer(Ctx, A, sort(U)),
    infer([A | Ctx], B, sort(V)),   % B se chequea en [A|Ctx]
    Max is max(U, V).

%% R-Sigma: Σ-formación
%%   B : Π(x:A). Type v  (familia de tipos sobre A)
infer(Ctx, sigma(A, B), sort(Max)) :-
    infer(Ctx, A, sort(U)),
    infer([A | Ctx], B, pi(A, sort(V))),   % B : A → Type v
    Max is max(U, V).

%% R-04: Aplicación (eliminación de Π)
infer(Ctx, app(F, A), BSubst) :-
    infer(Ctx, F, pi(Dom, Cod)),
    check(Ctx, A, Dom),
    subst(Cod, A, BSubst).           % B[a/0] mediante subst/3

%% R-Fst: primera proyección
%%   P : Sigma(A, B)  →  fst(P) : A
infer(Ctx, fst(P), A) :-
    check(Ctx, P, sigma(A, _B)).

%% R-Snd: segunda proyección
%%   P : Sigma(A, B)  →  snd(P) : B[fst(P)/0]
infer(Ctx, snd(P), BSubst) :-
    check(Ctx, P, sigma(_A, B)),
    subst(B, fst(P), BSubst).

%% R-Ind: tipo inductivo aplicado
infer(Ctx, inductive(Name, Params), sort(U)) :-
    inductive_sort(Name, U),
    inductive_param_types(Name, PTs),
    check_args(Ctx, Params, PTs).

%% R-Ctor: constructor aplicado
infer(Ctx, constructor(C, Args), RetType) :-
    constructor_type(C, ConTy),
    check_args_ret(Ctx, Args, ConTy, RetType).

%% R-Case: eliminación inductiva
infer(Ctx, case(Scrut, Motive, Branches), MotiveApplied) :-
    infer(Ctx, Scrut, inductive(I, Ps)),
    inductive_sort(I, _UI),
    check_motive(Ctx, I, Ps, Motive),
    coverage_check(I, Branches),
    check_branches(Ctx, I, Ps, Motive, Branches),
    apply_motive(Motive, Scrut, MotiveApplied).

%% -----------------------------------------------------------------
%% check(+Ctx, +Term, +Type)
%%   Γ ⊢ t ⇐ T — t chequea contra tipo T
%% -----------------------------------------------------------------

%% R-03: λ-introducción (check)
check(Ctx, lam(A, Body), pi(A, B)) :-
    infer(Ctx, A, sort(_)),
    check([A | Ctx], Body, B).

%% R-03: λ-introducción (infer — el cuerpo sintetiza B)
infer(Ctx, lam(A, Body), pi(A, B)) :-
    infer(Ctx, A, sort(_)),
    infer([A | Ctx], Body, B).

%% R-Pair: par dependiente (introducción de Σ)
check(Ctx, pair(A, B), sigma(TA, TB)) :-
    check(Ctx, A, TA),
    subst(TB, A, TBInst),
    check(Ctx, B, TBInst).

%% R-Conv: subsumción (fallback universal)
check(Ctx, Term, Expected) :-
    infer(Ctx, Term, Inferred),
    conversion(Ctx, Inferred, Expected).

%% -----------------------------------------------------------------
%% check_args(+Ctx, +Args, +ParamTypes)
%%   Verifica que cada argumento tiene el tipo de parámetro esperado.
%% -----------------------------------------------------------------

check_args(_Ctx, [], []).
check_args(Ctx, [A|As], [T|Ts]) :-
    check(Ctx, A, T),
    check_args(Ctx, As, Ts).

%% -----------------------------------------------------------------
%% check_args_ret(+Ctx, +Args, +ConTy, -RetType)
%%   Verifica args contra ConTy y devuelve el tipo resultante.
%%   ConTy = Π params. Π args. Inductive I params
%% -----------------------------------------------------------------

check_args_ret(Ctx, Args, ConTy, RetType) :-
    strip_pis(ConTy, RetType0, ArgTypes),
    check_args(Ctx, Args, ArgTypes),
    substitute_all(RetType0, Args, RetType).

%% Sustituye var(0) por cada argumento sucesivamente (orden de fuera a dentro).
substitute_all(T, [], T).
substitute_all(T, [A | As], Ret) :-
    subst(T, A, T1),
    substitute_all(T1, As, Ret).

%% Extrae los tipos de argumento de un tipo Pi-iterado.
%% strip_pis(+Type, -RetType, -ArgTypes)
%%   ArgTypes: lista de tipos de argumento (el último elemento = tipo de var(0)).
strip_pis(pi(A, B), RetType, [A | Rest]) :-
    strip_pis(B, RetType, Rest).
strip_pis(inductive(I, Ps), inductive(I, Ps), []).

%% -----------------------------------------------------------------
%% check_motive(+Ctx, +I, +Ps, +Motive)
%%   Motive : Π(x : Inductive I ps). Type
%% -----------------------------------------------------------------

check_motive(Ctx, _I, _Ps, Motive) :-
    infer(Ctx, Motive, pi(inductive(_, _), sort(_))).
