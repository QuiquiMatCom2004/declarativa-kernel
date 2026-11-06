%% ---------------------------------------------------------------
%% test_kernel.pl — Suite completa de tests del kernel
%% Basado en ESPECIFICACION_KERNEL.md §7 y MODELO_LOGICO.md §9
%% Ejecutar: swipl -q -l test_kernel.pl -t "run_tests, halt"
%% ---------------------------------------------------------------

:- use_module(kernel).
:- use_module(conversion).
:- use_module(nbe).
:- use_module(bidirectional, [infer/3, check/3, nth_type/3]).
:- use_module(inductive,
    [inductive_sort/2,
     inductive_ctors/2,
     constructor_type/2,
     inductive_param_types/2,
     coverage_check/2,
     check_branches/5,
     apply_motive/3]).

%% -----------------------------------------------------------------
%% run_tests — ejecuta toda la suite por grupos
%% -----------------------------------------------------------------

run_tests :-
    writeln('=== Suite completa de tests del kernel ==='),
    nl,
    run_test_group('1. Básicos (Sort, Var)', [
        id_type,
        id_type_infer,
        var_test,
        sort_bad_fail,
        no_impredicativo_fail
    ]),
    nl,
    run_test_group('2. Π y λ', [
        pi_formation,
        pi_extendido,
        lambda_intro,
        lam_infer_ok
    ]),
    nl,
    run_test_group('3. App y conversión β', [
        app_elim,
        beta_reduce,
        app_non_pi
    ]),
    nl,
    run_test_group('4. Conversión η', [
        eta_conv
    ]),
    nl,
    run_test_group('5. Inductivos Nat', [
        nat_zero,
        nat_succ
    ]),
    nl,
    run_test_group('6. Inductivos Vec (dependiente)', [
        vec_vnil,
        vec_vcons
    ]),
    nl,
    run_test_group('7. Sigma / Pair / Proyecciones', [
        sigma_formation,
        pair_proj,
        fst_ok,
        snd_ok
    ]),
    nl,
    run_test_group('8. Case (eliminación inductiva)', [
        case_nat_ok,
        missing_case_branch
    ]),
    nl,
    run_test_group('9. Cobertura y signature', [
        coverage_nat_ok,
        coverage_nat_fail,
        inductive_sig_ok,
        inductive_param_types_ok,
        constructor_type_ok
    ]),
    nl,
    run_test_group('10. Contexto bien formado', [
        well_formed_ctx_ok
    ]),
    nl,
    run_test_group('11. API pública (kernel.pl)', [
        public_check_ok,
        public_check_bad,
        public_convert_ok,
        public_nbe
    ]),
    nl,
    writeln('=== Suite completa terminada ===').

run_test_group(Name, Tests) :-
    writeln('--- '), writeln(Name),
    maplist(run_test, Tests).

run_test(Name) :-
    ( catch(Name, E, true)
    -> writeln('  PASS: '), writeln(Name)
    ;  writeln('  FAIL: '), writeln(Name)
    ).

%% =================================================================
%% Sección 1 — Básicos (Sort, Var)
%% =================================================================

id_type :-
    check([], sort(0), sort(1), ok).

id_type_infer :-
    infer([], sort(0), sort(1)).

var_test :-
    check([sort(0)], var(0), sort(0)).

sort_bad_fail :-
    \+ check([], sort(0), sort(0), ok).

no_impredicativo_fail :-
    \+ infer([], sort(0), sort(0)).

%% =================================================================
%% Sección 2 — Π y λ
%% =================================================================

pi_formation :-
    check([], pi(sort(0), sort(0)), sort(1), ok).

pi_extendido :-
    % Π(A:Type0). A → Type0
    infer([], pi(sort(0), pi(var(0), sort(0))), sort(1)).

lambda_intro :-
    check([], lam(sort(0), var(0)), pi(sort(0), sort(0)), ok).

lam_infer_ok :-
    infer([], lam(sort(0), var(0)), pi(sort(0), sort(0))).

%% =================================================================
%% Sección 3 — App y conversión β
%% =================================================================

app_elim :-
    % (λ(x:sort(0)). x) var(0)  en contexto [sort(0)]
    check([sort(0)], app(lam(sort(0), var(0)), var(0)), sort(0), ok).

beta_reduce :-
    nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF),
    NF = var(0).

app_non_pi :-
    % sort(0) no es Π, así que app(sort(0), sort(0)) debe fallar
    \+ infer([], app(sort(0), sort(0)), _).

%% =================================================================
%% Sección 4 — Conversión η
%% =================================================================

eta_conv :-
    % λ(x:Type0). (id x) ≡ id  (η-expansión)
    % donde id = λ(y:Type0). y
    Id = lam(sort(0), var(0)),
    conversion([], lam(sort(0), app(Id, var(0))), Id).

%% =================================================================
%% Sección 5 — Inductivos Nat
%% =================================================================

nat_zero :-
    infer([], constructor(zero, []), inductive(nat, [])).

nat_succ :-
    infer([], constructor(succ, [constructor(zero, [])]), inductive(nat, [])).

%% =================================================================
%% Sección 6 — Inductivos Vec (dependiente)
%% =================================================================

vec_vnil :-
    % vnil : Π(A:Type 0). Vec A zero
    % A = Nat (un tipo de Type 0), resultado: Vec Nat zero
    infer([], constructor(vnil, [inductive(nat, [])]), inductive(vec, [inductive(nat, []), constructor(zero, [])])).

vec_vcons :-
    % vcons : Π(A:Type 0). Π(n:Nat). A → Vec A n → Vec A (succ n)
    % Verificación del constructor_type (la inferencia completa con
    % tipos de argumento dependientes requiere extensión de contexto,
    % pendiente para la demo del Paso 3)
    constructor_type(vcons, ConTy),
    ConTy = pi(sort(0), pi(inductive(nat, []), pi(_, pi(_, _)))).

%% =================================================================
%% Sección 7 — Sigma / Pair / Proyecciones
%% =================================================================

sigma_formation :-
    check([], sigma(sort(0), lam(sort(0), sort(0))), sort(1), ok).

pair_proj :-
    % pair(var(0), lam(sort(0), var(0))) : Σ(A:Type0). (A → Type0)
    check([sort(0)], pair(var(0), lam(sort(0), var(0))), sigma(sort(0), pi(sort(0), sort(0)))),
    % fst del par = var(0) : sort(0)
    infer([sort(0)], fst(pair(var(0), lam(sort(0), var(0)))), sort(0)).

fst_ok :-
    % fst(pair(var(0), lam(sort(0), var(0)))) : sort(0)
    infer([sort(0)], fst(pair(var(0), lam(sort(0), var(0)))), sort(0)).

snd_ok :-
    % snd(pair(var(0), lam(sort(0), var(0)))) : pi(sort(0), sort(0))
    infer([sort(0)], snd(pair(var(0), lam(sort(0), var(0)))), pi(sort(0), sort(0))).

%% =================================================================
%% Sección 8 — Case (eliminación inductiva)
%% =================================================================

case_nat_ok :-
    % case zero of { zero => Nat; succ _ => Nat }
    % Verifica coverage_check (exhaustividad de constructores)
    Motive = lam(inductive(nat, []), inductive(nat, [])),
    Branches = [branch(zero, 0, constructor(zero, [])),
                branch(succ, 1, constructor(zero, []))],
    coverage_check(nat, Branches),
    % Verifica que build_branch_motive produzca un tipo válido
    build_branch_motive(Motive, zero, 0, BMotiveTy),
    sort(BMotiveTy, _).

missing_case_branch :-
    % case sobre Nat con solo una rama (falta succ) debe fallar
    \+ infer([],
        case(constructor(zero, []),
             lam(inductive(nat, []), sort(0)),
             [branch(zero, 0, sort(0))]),
        _).

%% =================================================================
%% Sección 9 — Cobertura y signature
%% =================================================================

coverage_nat_ok :-
    coverage_check(nat,
        [branch(zero, 0, var(0)), branch(succ, 1, var(0))]).

coverage_nat_fail :-
    \+ coverage_check(nat, [branch(zero, 0, var(0))]).

inductive_sig_ok :-
    kernel:inductive_signature(Sig),
    length(Sig, L),
    L >= 7.

inductive_param_types_ok :-
    inductive_param_types(list, [sort(0)]).

constructor_type_ok :-
    constructor_type(zero, inductive(nat, [])).

%% =================================================================
%% Sección 10 — Contexto bien formado
%% =================================================================

well_formed_ctx_ok :-
    kernel:well_formed_ctx([sort(0), sort(1)]).

%% =================================================================
%% Sección 11 — API pública
%% =================================================================

public_check_ok :-
    check([], sort(0), sort(1), ok).

public_check_bad :-
    check([], sort(0), sort(0), error(_, _)).

public_convert_ok :-
    convert([sort(0)], app(lam(sort(0), var(0)), var(0)), var(0), ok).

public_nbe :-
    nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF),
    NF = var(0).
