%% ---------------------------------------------------------------
%% substitution.pl — Shift y substitución de índices de Bruijn
%% Implementa R-07 del kernel (MODELO_LOGICO.md §2)
%% ---------------------------------------------------------------

:- module(substitution, [shift/4, subst/3, substitute/4]).

%% -----------------------------------------------------------------
%% shift(+Term, +Delta, +Cutoff, -Result)
%%   Incrementa en Delta todas las variables libres con índice >= Cutoff.
%%   Se llama al atravesar un binder: Cutoff crece en 1 por cada
%%   lam/pi/sigma anidado.
%% -----------------------------------------------------------------

%% variable Prolog sin vincular: devolver sin cambios
shift(V, _, _, V) :- var(V), !.

%% var
shift(var(I), D, C, var(I1)) :-
    I >= C, !,
    I1 is I + D.
shift(var(I), _, _, var(I)).

%% constantes (sin variables libres)
shift(sort(U), _, _, sort(U)).

%% pi(A, B) — ambos hijos comparten el mismo cutoff en A; B va a C+1
shift(pi(A, B), D, C, pi(A1, B1)) :-
    shift(A, D, C, A1),
    C1 is C + 1,
    shift(B, D, C1, B1).

%% lam(A, Body) — A es el tipo de dominio (anotación)
shift(lam(A, Body), D, C, lam(A1, Body1)) :-
    shift(A, D, C, A1),
    C1 is C + 1,
    shift(Body, D, C1, Body1).

%% app(F, A)
shift(app(F, A), D, C, app(F1, A1)) :-
    shift(F, D, C, F1),
    shift(A, D, C, A1).

%% sigma(A, B)
shift(sigma(A, B), D, C, sigma(A1, B1)) :-
    shift(A, D, C, A1),
    C1 is C + 1,
    shift(B, D, C1, B1).

%% pair(X, Y)
shift(pair(X, Y), D, C, pair(X1, Y1)) :-
    shift(X, D, C, X1),
    shift(Y, D, C, Y1).

%% fst(P) / snd(P)
shift(fst(P), D, C, fst(P1))  :- shift(P, D, C, P1).
shift(snd(P), D, C, snd(P1))  :- shift(P, D, C, P1).

%% inductive(Name, Params)
shift(inductive(N, Ps), D, C, inductive(N, Ps1)) :-
    maplist(shift_arg(D, C), Ps, Ps1).

%% constructor(Name, Args)
shift(constructor(N, As), D, C, constructor(N, As1)) :-
    maplist(shift_arg(D, C), As, As1).

%% case(Scrut, Motive, Branches) — ramas: Arity bindings después del scrut
shift(case(S, Mo, Brs), D, C, case(S1, Mo1, Brs1)) :-
    shift(S, D, C, S1),
    shift(Mo, D, C, Mo1),
    maplist(shift_branch(D, C), Brs, Brs1).

%% -----------------------------------------------------------------
%% Ayudantes para listas de argumentos / ramas
%% -----------------------------------------------------------------

shift_arg(D, C, T, T1) :- shift(T, D, C, T1).

shift_branch(D, C, branch(N, Ar, Body), branch(N, Ar, Body1)) :-
    C1 is C + Ar,
    shift(Body, D, C1, Body1).

%% -----------------------------------------------------------------
%% subst(+Term, +Repl, -Result)   = Term[Repl/0]
%%   Interfaz pública: sustituye var(0) por Repl, cerrando el hueco.
%% -----------------------------------------------------------------

subst(Term, Repl, Result) :-
    substitute(Term, Repl, 0, Result).

%% substitute(+Term, +Repl, +Depth, -Result)
%%   Reemplaza var(Depth) por Repl (substituyendo var(0) del cuerpo
%%   desplazado por Depth).
%% -----------------------------------------------------------------

%% variable Prolog sin vincular: devolver sin cambios
substitute(V, _, _, V) :- var(V), !.

%% var: caso base (variable ligada de Bruijn)
substitute(var(I), Repl, D, Result) :-
    ( I =:= D
    -> shift(Repl, D, 0, Result)      % Repl se ajusta a profundidad D
    ; ( I > D
      -> Result = var(I1), I1 is I - 1   % cerrar hueco de la var sustituida
      ; Result = var(I) )                % índice inferior: sin cambio
    ).

%% sort
substitute(sort(U), _, _, sort(U)).

%% pi(A, B)
substitute(pi(A, B), R, D, pi(A1, B1)) :-
    substitute(A, R, D, A1),
    D1 is D + 1,
    substitute(B, R, D1, B1).

%% lam(A, Body)
substitute(lam(A, Body), R, D, lam(A1, Body1)) :-
    substitute(A, R, D, A1),
    D1 is D + 1,
    substitute(Body, R, D1, Body1).

%% app(F, A)
substitute(app(F, A), R, D, app(F1, A1)) :-
    substitute(F, R, D, F1),
    substitute(A, R, D, A1).

%% sigma(A, B)
substitute(sigma(A, B), R, D, sigma(A1, B1)) :-
    substitute(A, R, D, A1),
    D1 is D + 1,
    substitute(B, R, D1, B1).

%% pair(X, Y)
substitute(pair(X, Y), R, D, pair(X1, Y1)) :-
    substitute(X, R, D, X1),
    substitute(Y, R, D, Y1).

%% fst(P) / snd(P)
substitute(fst(P), R, D, fst(P1))  :- substitute(P, R, D, P1).
substitute(snd(P), R, D, snd(P1))  :- substitute(P, R, D, P1).

%% inductive(Name, Params)
substitute(inductive(N, Ps), R, D, inductive(N, Ps1)) :-
    maplist(subst_arg(R, D), Ps, Ps1).

%% constructor(Name, Args)
substitute(constructor(N, As), R, D, constructor(N, As1)) :-
    maplist(subst_arg(R, D), As, As1).

%% case(Scrut, Motive, Branches)
substitute(case(S, Mo, Brs), R, D, case(S1, Mo1, Brs1)) :-
    substitute(S, R, D, S1),
    substitute(Mo, R, D, Mo1),
    maplist(subst_branch(R, D), Brs, Brs1).

%% -----------------------------------------------------------------
%% Ayudantes para listas
%% -----------------------------------------------------------------

subst_arg(R, D, T, T1) :- substitute(T, R, D, T1).

subst_branch(R, D, branch(N, Ar, Body), branch(N, Ar, Body1)) :-
    D1 is D + Ar,
    substitute(Body, R, D1, Body1).
