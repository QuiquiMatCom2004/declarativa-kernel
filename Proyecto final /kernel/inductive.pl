%% ---------------------------------------------------------------
%% inductive.pl — Signature de inductivos y eliminación Case (R-05, R-06)
%% Implementa MODELO_LOGICO.md §6 y §7
%% ---------------------------------------------------------------

:- module(inductive,
    [inductive_sort/2,
     inductive_ctors/2,
     constructor_type/2,
     inductive_param_types/2,
     coverage_check/2,
     check_branches/5,
     apply_motive/3,
     build_branch_motive/4]).

:- use_module(bidirectional, [check/3]).

%% -----------------------------------------------------------------
%% inductive_sort(+Name, -UniverseLevel)
%% -----------------------------------------------------------------

inductive_sort(nat,   0).
inductive_sort(list,  1).
inductive_sort(vec,   1).
inductive_sort(sigma, 1).
inductive_sort(unit,  0).
inductive_sort(empty, 0).
inductive_sort(bool,  0).
inductive_sort(prod,  1).

%% -----------------------------------------------------------------
%% inductive_ctors(+Name, -ListOfCtorNames)
%% -----------------------------------------------------------------

inductive_ctors(nat,   [zero, succ]).
inductive_ctors(list,  [nil, cons]).
inductive_ctors(vec,   [vnil, vcons]).
inductive_ctors(bool,  [true_, false_]).
inductive_ctors(unit,  [unit_mk]).
inductive_ctors(empty, []).
inductive_ctors(prod,  [mk_prod]).
inductive_ctors(sigma, [mk_sigma]).

%% -----------------------------------------------------------------
%% constructor_type(+Name, -Type)
%%   Tipo en sintaxis core (índices de Bruijn), completamente anotado.
%% -----------------------------------------------------------------

%% zero : Nat
constructor_type(zero, inductive(nat, [])).

%% succ : Nat → Nat
constructor_type(succ, pi(inductive(nat, []), inductive(nat, []))).

%% nil : Π(A : Type 0). List A
constructor_type(nil,
    pi(sort(0),
       inductive(list, [var(0)]))).

%% cons : Π(A : Type). A → List A → List A
constructor_type(cons,
    pi(sort(0),
    pi(var(0),
    pi(inductive(list, [var(1)]),
       inductive(list, [var(2)]))))).

%% vnil : Π(A : Type). Vec A zero
constructor_type(vnil,
    pi(sort(0),
       inductive(vec, [var(0), constructor(zero, [])]))).

%% vcons : Π(A : Type). Π(n : Nat). A → Vec A n → Vec A (succ n)
constructor_type(vcons,
    pi(sort(0),
    pi(inductive(nat, []),
    pi(var(1),
    pi(inductive(vec, [var(2), var(1)]),
       inductive(vec, [var(3), constructor(succ, [var(2)])])))))).

%% unit_mk : Unit
constructor_type(unit_mk, inductive(unit, [])).

%% true_, false_ : Bool
constructor_type(true_,   inductive(bool, [])).
constructor_type(false_,  inductive(bool, [])).

%% mk_prod : Π(A : Type). Π(B : Type). A → B → Prod A B
constructor_type(mk_prod,
    pi(sort(0),
    pi(sort(0),
    pi(var(1),
    pi(var(1),
       inductive(prod, [var(3), var(2)])))))).

%% mk_sigma : Π(A : Type). Π(B : A → Type). Π(a : A). B a → Sigma A B
constructor_type(mk_sigma,
    pi(sort(0),
    pi(pi(var(0), sort(0)),
    pi(var(1),
    pi(app(var(1), var(0)),
       inductive(sigma, [var(3), var(2)])))))).

%% -----------------------------------------------------------------
%% inductive_param_types(+Name, -ListOfParamTypes)
%%   Tipos de los parámetros del inductivo (para R-Ind).
%% -----------------------------------------------------------------

inductive_param_types(nat,   []).
inductive_param_types(list,  [sort(0)]).           % A : Type 0
inductive_param_types(vec,   [sort(0), inductive(nat, [])]).  % A : Type 0, n : Nat
inductive_param_types(sigma, [sort(0), pi(var(0), sort(0))]). % A : Type0, B : A→Type0
inductive_param_types(unit,  []).
inductive_param_types(empty, []).
inductive_param_types(bool,  []).
inductive_param_types(prod,  [sort(0), sort(0)]).  % A:Type0, B:Type0

%% -----------------------------------------------------------------
%% coverage_check(+InductiveName, +Branches)
%%   Verifica que las ramas cubren TODOS los constructores exactamente una vez.
%% -----------------------------------------------------------------

coverage_check(I, Branches) :-
    inductive_ctors(I, Required),
    maplist(branch_ctor, Branches, CtorNames),
    sort(Required, SortedReq),
    sort(CtorNames, SortedCtor),
    SortedReq = SortedCtor,
    length(Required, Len),
    length(Branches, Len).

branch_ctor(branch(Ctor, _Ar, _Body), Ctor).

%% -----------------------------------------------------------------
%% check_branches(+Ctx, +I, +Ps, +Motive, +Branches)
%%   Verifica cada rama contra su tipo de motivo.
%% -----------------------------------------------------------------

check_branches(_Ctx, _I, _Ps, _Motive, []).

check_branches(Ctx, I, Ps, Motive, [branch(Ctor, Arity, Body) | Rest]) :-
    constructor_type(Ctor, ConTy),
    build_branch_ctx(Ctx, ConTy, Arity, BCtx),
    build_branch_motive(Motive, Ctor, Arity, BMotiveTy),
    check(BCtx, Body, BMotiveTy),
    check_branches(Ctx, I, Ps, Motive, Rest).

%% -----------------------------------------------------------------
%% build_branch_ctx(+Ctx, +ConTy, +Arity, -BCtx)
%%   Contexto extendido con los tipos de los argumentos del constructor.
%%   ConTy tiene la forma Π p₁. ... Π pₙ. Π args. Inductive I ps
%%   y Arity es el número de argumentos del constructor.
%% -----------------------------------------------------------------

build_branch_ctx(Ctx, ConTy, Arity, BCtx) :-
    extract_arg_types(ConTy, ArgTypes),
    length(ArgTypes, Total),
    Arity =< Total,
    ( Arity =:= 0
    -> BCtx = Ctx
    ;  N1 is Total - Arity,
       drop_n(N1, ArgTypes, LastArgs),
       prepend_all(LastArgs, Ctx, BCtx)
    ).

drop_n(0, L, L).
drop_n(N, [_|L], Rest) :-
    N > 0,
    N1 is N - 1,
    drop_n(N1, L, Rest).

prepend_all([], Ctx, Ctx).
prepend_all([T|Ts], Ctx, Result) :-
    prepend_all(Ts, [T|Ctx], Result).

%% Extrae los tipos de argumento de un tipo con forma Π...Π.Inductive
extract_arg_types(pi(A, B), [A | Rest]) :-
    extract_arg_types(B, Rest).
extract_arg_types(inductive(_, _), []).

%% -----------------------------------------------------------------
%% build_branch_motive(+Motive, +Ctor, +Arity, -MotiveType)
%%   Tipo del cuerpo de la rama: tipo de retorno del motivo (aplicado
%%   al constructor). Para el MVP, infiere el tipo del motivo y extrae
%%   el codominio del Pi.
%% -----------------------------------------------------------------

build_branch_motive(Motive, _Ctor, _Arity, BMotiveTy) :-
    infer([], Motive, pi(_Dom, BMotiveTy)).

%% -----------------------------------------------------------------
%% apply_motive(+Motive, +Scrut, -Result)
%%   Result = Motive aplicado a Scrut
%% -----------------------------------------------------------------

apply_motive(Motive, Scrut, app(Motive, Scrut)).
