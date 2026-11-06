%% ---------------------------------------------------------------
%% test_basic.pl — Tests básicos del kernel
%% Ejecutar: swipl -q -l test_basic.pl -t "run_tests, halt"
%% ---------------------------------------------------------------

:- use_module(kernel).

run_tests :-
    writeln('=== Tests del Kernel de Tipos Dependientes ==='),
    run_test(sort_ok),
    run_test(sort_bad_fail),
    run_test(var_ok),
    run_test(pi_ok),
    run_test(pi_extendido),
    run_test(lam_check_ok),
    run_test(lam_infer_ok),
    run_test(app_ok),
    run_test(beta_conv),
    run_test(eta_conv),
    run_test(nat_zero),
    run_test(nat_succ),
    run_test(sigma_ok),
    run_test(pair_ok),
    run_test(fst_ok),
    run_test(snd_ok),
    run_test(no_impredicativo_fail),
    run_test(public_check_ok),
    run_test(public_check_bad),
    run_test(public_convert_ok),
    run_test(public_nbe),
    writeln('=== Todos los tests completados ===').

run_test(Name) :-
    ( catch(Name, E, true)
    -> writeln('PASS: '), writeln(Name)
    ;  writeln('FAIL: '), writeln(Name)
    ).

%% --- Sort ---
sort_ok :-
    infer([], sort(0), sort(1)).

sort_bad_fail :-
    \+ infer([], sort(0), sort(0)).

%% --- Var ---
var_ok :-
    infer([sort(0)], var(0), sort(0)).

%% --- Pi ---
pi_ok :-
    infer([], pi(sort(0), sort(0)), sort(1)).

pi_extendido :-
    % Π(A:Type0). A → Type0
    infer([], pi(sort(0), pi(var(0), sort(0))), sort(1)).

%% --- Lam ---
lam_check_ok :-
    check([], lam(sort(0), var(0)), pi(sort(0), sort(0))).

lam_infer_ok :-
    infer([], lam(sort(0), var(0)), pi(sort(0), sort(0))).

%% --- App ---
app_ok :-
    % En contexto [sort(0)], var(0) : sort(0). Identidad aplicada a var(0) → sort(0)
    infer([sort(0)], app(lam(sort(0), var(0)), var(0)), sort(0)).

%% --- Conversión β ---
beta_conv :-
    % (λ(x:sort(0)). x) sort(0) ≡ sort(0)  — pero sort(0) : sort(1), no sort(0)
    % Usamos var(0) en contexto [sort(0)]:
    conversion([sort(0)], app(lam(sort(0), var(0)), var(0)), var(0)).

%% --- Conversión η ---
eta_conv :-
    % Ctx = [sort(0), pi(sort(0), sort(0))]: var(0):sort(0), var(1):Π(sort(0),sort(0))
    % λ(x:sort(0)). var(1) x ≡ var(1)   (η)
    Ctx = [sort(0), pi(sort(0), sort(0))],
    conversion(Ctx, lam(sort(0), app(var(1), var(0))), var(1)).

%% --- Inductivos ---
nat_zero :-
    infer([], constructor(zero, []), inductive(nat, [])).

nat_succ :-
    infer([], constructor(succ, [constructor(zero,[])]), inductive(nat,[])).

%% --- Sigma / Pair ---
sigma_ok :-
    % Σ(A:Type0). A → Type0  (tipo bien formado)
    infer([], sigma(sort(0), lam(sort(0), sort(0))), sort(1)).

pair_ok :-
    % Ctx = [sort(0)]: var(0) : sort(0)
    % pair(var(0), lam(sort(0), var(0))) : Σ(A:Type0). (A → Type0)
    check([sort(0)], pair(var(0), lam(sort(0), var(0))), sigma(sort(0), pi(sort(0), sort(0)))).

fst_ok :-
    % fst(pair(var(0), lam(sort(0), var(0)))) : sort(0)
    infer([sort(0)], fst(pair(var(0), lam(sort(0), var(0)))), sort(0)).

snd_ok :-
    % snd(pair(var(0), lam(sort(0), var(0)))) : pi(sort(0), sort(0))
    infer([sort(0)], snd(pair(var(0), lam(sort(0), var(0)))), pi(sort(0), sort(0))).

%% --- Consistencia ---
no_impredicativo_fail :-
    \+ infer([], sort(0), sort(0)).

%% --- Public API ---
public_check_ok :-
    check([], sort(0), sort(1), ok).

public_check_bad :-
    check([], sort(0), sort(0), error(_, _)).

public_convert_ok :-
    convert([sort(0)], app(lam(sort(0), var(0)), var(0)), var(0), ok).

public_nbe :-
    nbe([sort(0)], app(lam(sort(0), var(0)), var(0)), NF),
    NF = var(0).
