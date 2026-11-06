%% ---------------------------------------------------------------
%% demo_vec.pl — Demo del Kernel de Tipos Dependientes
%% Demuestra verificación de términos con tipos dependientes (Vec)
%% y otros constructos del kernel.
%%
%% Ejecutar: swipl -q -l demo_vec.pl -t "run_demo, halt"
%% ---------------------------------------------------------------

:- use_module(kernel).
:- use_module(conversion).
:- use_module(nbe).
:- use_module(inductive, [inductive_sort/2, inductive_ctors/2, constructor_type/2, coverage_check/2]).

%% ---------------------------------------------------------------
%% run_demo — ejecuta la demostración completa
%% ---------------------------------------------------------------

run_demo :-
    writeln('========================================'),
    writeln('  DEMO — Kernel de Tipos Dependientes'),
    writeln('  Proyecto Final — Programación Declarativa'),
    writeln('========================================'),
    nl,

    demo_section('1. Tipo Nat y sus constructores', demo_nat),
    nl,
    demo_section('2. Tipo Vec (dependiente)', demo_vec),
    nl,
    demo_section('3. Tipo Sigma (par dependiente)', demo_sigma),
    nl,
    demo_section('4. Conversión definicional (β)', demo_beta),
    nl,
    demo_section('5. Conversión definicional (η)', demo_eta),
    nl,
    demo_section('6. Consistencia (no Type : Type)', demo_consistencia),
    nl,
    demo_section('7. API pública del kernel', demo_api),
    nl,
    writeln('========================================'),
    writeln('  Demo completada con éxito'),
    writeln('========================================'),
    !.

demo_section(Titulo, Goal) :-
    writeln('--- '), writeln(Titulo),
    maplist(writeln, ['', '']),  % espaciado visual
    once(Goal),
    writeln('  ✓ OK'),
    nl.

%% ---------------------------------------------------------------
%% 1. Nat
%% ---------------------------------------------------------------

demo_nat :-
    % zero : Nat
    infer([], constructor(zero, []), inductive(nat, [])),
    writeln('  zero : Nat'),

    % succ zero : Nat
    infer([], constructor(succ, [constructor(zero, [])]), inductive(nat, [])),
    writeln('  succ zero : Nat'),

    % succ (succ zero) : Nat
    infer([], constructor(succ, [constructor(succ, [constructor(zero, [])])]), inductive(nat, [])),
    writeln('  succ (succ zero) : Nat'),

    % Nat : Type 0
    infer([], inductive(nat, []), sort(0)),
    writeln('  Nat : Type 0').

%% ---------------------------------------------------------------
%% 2. Vec (dependiente)
%% ---------------------------------------------------------------

demo_vec :-
    % vnil : Π(A:Type). Vec A zero
    % vnil Nat : Vec Nat zero
    infer([], constructor(vnil, [inductive(nat, [])]), inductive(vec, [inductive(nat, []), constructor(zero, [])])),
    writeln('  vnil Nat : Vec Nat zero'),

    % Vec Nat zero : Type 1 (porque Vec vive en Type 1)
    infer([], inductive(vec, [inductive(nat, []), constructor(zero, [])]), sort(1)),
    writeln('  Vec Nat zero : Type 1'),

    % Vec Nat (succ zero) : Type 1
    infer([], inductive(vec, [inductive(nat, []), constructor(succ, [constructor(zero, [])])]), sort(1)),
    writeln('  Vec Nat (succ zero) : Type 1'),

    % vcons Nat : Π(n:Nat). Nat → Vec Nat n → Vec Nat (succ n)
    constructor_type(vcons, ConTy),
    ( strip_and_show(ConTy, '  vcons : ') ; true ).

%% Mostrar el tipo de vcons de forma legible
strip_and_show(Type, Prefix) :-
    ( Type = pi(A, B)
    -> writeln(Prefix), writeln('    Π('), write(A), writeln(') → .'),
       strip_and_show(B, '      ')
    ;  writeln(Prefix), write(Type), nl
    ).

%% ---------------------------------------------------------------
%% 3. Sigma (par dependiente)
%% ---------------------------------------------------------------

demo_sigma :-
    % Sigma(Type0, λ(A:Type0). Type0) : Type1
    check([], sigma(sort(0), lam(sort(0), sort(0))), sort(1), ok),
    writeln('  Σ(A:Type0). A → Type0 : Type1'),

    % pair(var(0), lam(sort(0), var(0))) : Σ(A:Type0). (A → Type0)
    % en contexto [Type0]
    check([sort(0)], pair(var(0), lam(sort(0), var(0))), sigma(sort(0), pi(sort(0), sort(0))), ok),
    writeln('  pair(var(0), λ(A:Type0). A) : Σ(A:Type0). (A → Type0)  [en contexto Type0]'),

    % fst del par = var(0) : Type0
    infer([sort(0)], fst(pair(var(0), lam(sort(0), var(0)))), sort(0)),
    writeln('  fst(pair(...)) : Type0'),

    % snd del par = λ(A:Type0). A → Type0  (la familia de tipos)
    infer([sort(0)], snd(pair(var(0), lam(sort(0), var(0)))), pi(sort(0), sort(0))),
    writeln('  snd(pair(...)) : Π(A:Type0). A → Type0').

%% ---------------------------------------------------------------
%% 4. Conversión β
%% ---------------------------------------------------------------

demo_beta :-
    % (λ(x:Type0). x) Type0 ≡ Type0  (β-reducción)
    conversion([sort(0)], app(lam(sort(0), var(0)), var(0)), var(0)),
    writeln('  (λ(x:Type0). x) Type0 ≡ Type0  (β)'),

    % NbE confirma la forma normal
    nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF),
    NF = var(0),
    writeln('  NbE confirma: forma normal es Type0').

%% ---------------------------------------------------------------
%% 5. Conversión η
%% ---------------------------------------------------------------

demo_eta :-
    % λ(x:Type0). (id x) ≡ id  (η-expansión)
    % donde id = λ(y:Type0). y
    Id = lam(sort(0), var(0)),
    conversion([], lam(sort(0), app(Id, var(0))), Id),
    writeln('  λ(x:Type0). (id x) ≡ id  (η)'),

    % NbE confirma
    nbe([], lam(sort(0), app(Id, var(0))), NF1),
    nbe([], Id, NF2),
    NF1 = NF2,
    writeln('  NbE confirma: η-expansión válida').

%% ---------------------------------------------------------------
%% 6. Consistencia
%% ---------------------------------------------------------------

demo_consistencia :-
    % Type 0 : Type 0 está PROHIBIDO (jerarquía de universos)
    \+ check([], sort(0), sort(0), ok),
    writeln('  Type 0 : Type 0  →  RECHAZADO (consistencia)'),

    % Type 0 : Type 1 está permitido
    check([], sort(0), sort(1), ok),
    writeln('  Type 0 : Type 1  →  ACEPTADO'),

    % app(sort(0), sort(0)) falla porque sort(0) no es Π
    \+ infer([], app(sort(0), sort(0)), _),
    writeln('  app(Type0, Type0)  →  RECHAZADO (no es función)').

%% ---------------------------------------------------------------
%% 7. API pública
%% ---------------------------------------------------------------

demo_api :-
    % check/4
    check([], sort(0), sort(1), ok),
    writeln('  check([], Type0, Type1) = ok'),

    % check/4 con error
    check([], sort(0), sort(0), error(_, _)),
    writeln('  check([], Type0, Type0) = error'),

    % convert/4
    convert([sort(0)], app(lam(sort(0), var(0)), var(0)), var(0), ok),
    writeln('  convert(..., (λx.x) Type0, Type0) = ok'),

    % nbe/3
    nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF),
    NF = var(0),
    writeln('  nbe((λx.x) Type0) = Type0'),

    % inductive_signature/1
    kernel:inductive_signature(Sig),
    length(Sig, L),
    format('  Inductivos registrados: ~d~n', [L]).

%% ---------------------------------------------------------------
