%% ---------------------------------------------------------------
%% conversion.pl — Conversión definicional (R-08)
%% Implementa MODELO_LOGICO.md §5.4
%% ---------------------------------------------------------------

:- module(conversion, [conversion/3, nbe_export/3]).

:- use_module(nbe).

%% -----------------------------------------------------------------
%% conversion(+Ctx, +T1, +T2)
%%   T1 y T2 son definitivamente iguales en Ctx.
%%   Se implementa con NbE: normalizar ambos y comparar estructuralmente.
%% -----------------------------------------------------------------

conversion(Ctx, T1, T2) :-
    nbe_export(Ctx, T1, NF1),
    nbe_export(Ctx, T2, NF2),
    NF1 = NF2.   % = unificación (== es estricta y no vincula variables)

%% -----------------------------------------------------------------
%% nbe_export(+Ctx, +Term, -NormalForm)
%%   Wrapper que expone nbe/3 de nbe.pl.
%% -----------------------------------------------------------------

nbe_export(Ctx, Term, NF) :-
    nbe:nbe(Ctx, Term, NF).
