%% ---------------------------------------------------------------
%% kernel.pl — Módulo principal del kernel de tipos dependientes
%% Implementa MODELO_LOGICO.md §3 (API pública)
%% ---------------------------------------------------------------

:- module(kernel,
    [check/4,          % check(+Ctx, +Term, +Type, -Result)
     infer/3,          % infer(+Ctx, +Term, -Type)
     convert/4,        % convert(+Ctx, +T1, +T2, -Result)
     nbe/3,            % nbe(+Ctx, +Term, -NormalForm)
     well_formed_ctx/1, % well_formed_ctx(+Ctx)
     inductive_signature/1 % inductive_signature(-Sig)
    ]).

:- use_module(bidirectional, [infer/3, check/3, nth_type/3]).
:- use_module(conversion, [conversion/3]).
:- use_module(nbe, [nbe/3]).
:- use_module(inductive,
    [inductive_sort/2,
     inductive_ctors/2,
     constructor_type/2]).

%% -----------------------------------------------------------------
%% check(+Ctx, +Term, +Type, -Result)
%%   Result = ok  si Γ ⊢ t ⇐ T
%%   Result = error(Code, Msg) en caso contrario
%% -----------------------------------------------------------------

check(Ctx, Term, Type, ok) :-
    check(Ctx, Term, Type),
    !.

check(Ctx, Term, Type, error(type_error, Term)) :-
    \+ check(Ctx, Term, Type).

%% -----------------------------------------------------------------
%% infer(+Ctx, +Term, -Type)
%%   Γ ⊢ t ⇒ T
%% -----------------------------------------------------------------

%% (delegado a bidirectional:infer/3)

%% -----------------------------------------------------------------
%% convert(+Ctx, +T1, +T2, -Result)
%%   Result = ok  si Γ ⊢ T1 ≡ T2
%%   Result = error(conversion_error, T1/T2) en caso contrario
%% -----------------------------------------------------------------

convert(Ctx, T1, T2, ok) :-
    conversion(Ctx, T1, T2),
    !.

convert(_Ctx, T1, T2, error(conversion_error, T1/T2)).

%% -----------------------------------------------------------------
%% nbe(+Ctx, +Term, -NormalForm)
%%   Forma normal βδιζη de Term en Ctx.
%% -----------------------------------------------------------------

%% (delegado a nbe:nbe/3)

%% -----------------------------------------------------------------
%% well_formed_ctx(+Ctx)
%%   El contexto está bien formado: cada tipo en Ctx es un tipo válido.
%% -----------------------------------------------------------------

well_formed_ctx([]).

well_formed_ctx([T|Ctx]) :-
    well_formed_ctx(Ctx),
    infer(Ctx, T, sort(_)).

%% -----------------------------------------------------------------
%% inductive_signature(-Sig)
%%   Devuelve la signature completa de inductivos del kernel.
%% -----------------------------------------------------------------

inductive_signature(Sig) :-
    findall(inductive(Name, SortLevel, Ctors),
        ( inductive_sort(Name, SortLevel),
          inductive_ctors(Name, Ctors) ),
        Sig).

%% -----------------------------------------------------------------
%% Directivas de inicialización
%% -----------------------------------------------------------------

:- initialization(writeln('Kernel de tipos dependientes cargado.')).
