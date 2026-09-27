{smcl}
{* *! version 0.1.0  26sep2026}{c -(}...{c )-}
{vieweralsosee "cointvol" "help cointvol"}{c -(}...{c )-}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{c -(}...{c )-}
{vieweralsosee "[TS] vecrank" "help vecrank"}{c -(}...{c )-}
{viewerjumpto "Syntax" "cointvol_garchrank##syntax"}{c -(}...{c )-}
{viewerjumpto "Description" "cointvol_garchrank##description"}{c -(}...{c )-}
{viewerjumpto "Options" "cointvol_garchrank##options"}{c -(}...{c )-}
{viewerjumpto "Methods and formulas" "cointvol_garchrank##methods"}{c -(}...{c )-}
{viewerjumpto "Remarks" "cointvol_garchrank##remarks"}{c -(}...{c )-}
{viewerjumpto "Examples" "cointvol_garchrank##examples"}{c -(}...{c )-}
{viewerjumpto "Stored results" "cointvol_garchrank##results"}{c -(}...{c )-}
{viewerjumpto "References" "cointvol_garchrank##references"}{c -(}...{c )-}
{viewerjumpto "Author" "cointvol_garchrank##author"}{c -(}...{c )-}
{title:Title}

{p2colset 5 28 30 2}{c -(}...{c )-}
{p2col:{hi:cointvol garchrank} {hline 2}}Cointegration-rank tests designed for CCC-GARCH
errors: LR_G and Hausman H_G (one-step QMLE), W_G and robust W*_G (one-step WLS){p_end}
{p2colreset}{c -(}...{c )-}


{marker syntax}{c -(}...{c )-}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol garchrank} {varlist} {ifin}{cmd:,} {opt l:ags(#)}
[{it:options}]

{synoptset 24 tabbed}{c -(}...{c )-}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt l:ags(#)}}lag order {it:s} of the VAR in levels (ECM has {it:s}-1 lagged
differences){p_end}
{synopt:{opt tr:end(string)}}{cmd:none} or {cmd:rconstant} (default){p_end}
{synopt:{opt garch(p q)}}CCC-GARCH orders: {it:p} lagged variances, {it:q} lagged squared
errors; default {cmd:garch(1 1)}{p_end}
{synopt:{opt m:ethod(string)}}{cmd:qmle} (default; Sin, Mi & Ling 2024) or {cmd:wls} (Sin c.
2004){p_end}
{synopt:{opt r:ank(numlist)}}null ranks to test; default 0,...,m-1{p_end}

{syntab:Inference}
{synopt:{opt cv(string)}}{cmd:table} (default) or {cmd:sim}{p_end}
{synopt:{opt simr:eps(#)}}replications for simulated limits; default 20000{p_end}
{synopt:{opt simn(#)}}random-walk length in the simulation; default 1000{p_end}
{synopt:{opt seed(string)}}random-number seed for the simulation{p_end}
{synopt:{opt l:evel(#)}}test level; default {cmd:level(95)}; 90, 95 or 99 with
{cmd:cv(table)}{p_end}

{syntab:Reporting}
{synopt:{opt nodots}}suppress simulation progress messages{p_end}
{synopt:{opt nogarch:table}}suppress the table of CCC-GARCH estimates{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required. The data must be {cmd:tsset} (not panel) with no gaps;
time-series operators are allowed.{p_end}


{marker description}{c -(}...{c )-}
{title:Description}

{pstd}
{cmd:cointvol garchrank} tests the cointegration rank of a partially nonstationary VAR
whose errors follow a constant-conditional-correlation (CCC) GARCH(p,q) model. Unlike the
Johansen trace test, which ignores the volatility dynamics (and keeps its asymptotic size
under this model), the tests here estimate the mean and variance equations jointly and
exploit the GARCH weighting, which yields substantially higher power (SML, Table 5).

{pstd}
For each null H0: rank(C) <= r against rank(C) = m the command reports, side by side,

{p 8 10 2}- LR_NG: the conventional Johansen (1988) trace statistic (core engine of
{cmd:cointvol});{p_end}
{p 8 10 2}- {cmd:method(qmle)}: the likelihood-ratio statistic LR_G and the Hausman-type
statistic H_G of Sin, Mi & Ling (2024), based on one-step full-rank and reduced-rank QMLE;{p_end}
{p 8 10 2}- {cmd:method(wls)}: the Wald statistic W_G and its misspecification-robust
version W*_G of Sin (c. 2004), based on one-step weighted least squares (feasible GLS).{p_end}

{pstd}
The limit distributions of LR_G, H_G, W_G and W*_G depend on d = m - r nuisance
eigenvalues lambda in [0,1). These are estimated and critical values are either
interpolated from the published tables (d = 1, 2) or simulated for the estimated lambda.
lambda = 0 gives the Johansen distribution; lambda -> 1 gives a chi-squared(d{c 94}2).

{pstd}
Use it when the residuals of a cointegrated VAR show clear ARCH effects (e.g. financial
or interest-rate data). Do not use it when the volatility is nonstationary (breaks,
trending variance): use {helpb cointvol_rank:cointvol rank} (wild bootstrap) instead. Only
the no-constant and constant-without-trend cases are covered by the theory.


{marker options}{c -(}...{c )-}
{title:Options}

{phang}
{opt lags(#)} sets the lag order {it:s} >= 1 of the VAR in levels; the ECM contains
{it:s}-1 lagged differences (SML (2.5)).

{phang}
{opt trend(string)}: {cmd:none} fits W_t = C Y_{c -(}t-1{c )-} + sum Phi*_j W_{c -(}t-j{c )-} + e_t
(SML (2.5)); {cmd:rconstant} adds an intercept mu that is estimated freely under both the
full-rank and reduced-rank models, while the data are assumed to have no linear trend
(mu in the column space of A), SML (2.7) and (5.9). Default {cmd:rconstant}. See Remarks.

{phang}
{opt garch(p q)} sets the CCC-GARCH orders of SML (2.3): h_it = a_i0 + sum_{c -(}l=1{c )-}{c 94}q
a_il e_{c -(}i,t-l{c )-}{c 94}2 + sum_{c -(}l=1{c )-}{c 94}p b_il h_{c -(}i,t-l{c )-}. {it:q} >= 1, 0 <= {it:p},
both <= 4. {cmd:garch(1 1)} is the default; {cmd:garch(0 1)} is an ARCH(1).

{phang}
{opt method(string)}: {cmd:qmle} (Original: SML Sections 3-5) or {cmd:wls}
(Original: Sin c. 2004, Sections 3-5).

{phang}
{opt rank(numlist)} restricts the null ranks tested. Sequential rank selection is reported
only when all ranks 0,...,m-1 are tested.

{phang}
{opt cv(string)}: {cmd:table} interpolates bilinearly in lambda in the published tables
(d = 1, 2); rows with d > 2 are simulated automatically. {cmd:sim} simulates the limit
for every row and also yields p-values.

{phang}
{opt simreps(#)} and {opt simn(#)} set the number of replications (>= 100, default 20000)
and the random-walk length (>= 100, default 1000) of the simulated limit. The published
tables used 100,000 replications and n = 2,000.

{phang}
{opt seed(string)} sets the seed before the simulation. The estimation itself is
deterministic.

{phang}
{opt level(#)} sets the level used for the critical value column, the rejection stars
and the sequential selection. With {cmd:cv(table)} it must be 90, 95 or 99.

{phang}
{opt nodots} and {opt nogarchtable} control the output.


{marker methods}{c -(}...{c )-}
{title:Methods and formulas}

{pstd}
{ul:Model} (SML (2.1)-(2.5)). Y_t is m x 1, W_t = Y_t - Y_{c -(}t-1{c )-},
W_t = C Y_{c -(}t-1{c )-} + sum_{c -(}j=1{c )-}{c 94}{c -(}s-1{c )-} Phi*_j W_{c -(}t-j{c )-} [+ mu] + e_t, C = AB with A m x r,
B r x m. e_it = eta_it h_{c -(}i,t-1{c )-}{c 94}(1/2), V_{c -(}t-1{c )-} = D_{c -(}t-1{c )-} Gamma D_{c -(}t-1{c )-},
D = diag(h{c 94}(1/2)), Gamma the constant correlation matrix. X_{c -(}t-1{c )-} = (Y'_{c -(}t-1{c )-},
W'_{c -(}t-1{c )-}, ..., W'_{c -(}t-s+1{c )-} [,1])', phi = vec(C, Phi*_1, ..., [mu]).
Assumptions: roots outside the unit circle or at 1, no I(2), strictly stationary GARCH
with finite fourth moments, symmetric eta (SML Assumptions 2.1-2.5).

{pstd}
{ul:Step 1: initial full-rank estimator} (SML Sec. 3). Least squares of W_t on X_{c -(}t-1{c )-}.
A CCC-GARCH(p,q) is fitted to the LS residuals: Gaussian QMLE equation by equation
(numerical Newton-Raphson, BFGS fallback) and Gamma = correlation matrix of the
standardised residuals (Bollerslev 1990). Pre-sample e{c 94}2 and h are set to the sample
mean of e{c 94}2.

{pstd}
{ul:Step 2: one-step full-rank QMLE} (SML (3.2), (3.4), (B.1)).
phi_dot = phi_hat - (sum F_t){c 94}(-1) sum grad l_t with score
grad l_t = -1/2 grad h_{c -(}t-1{c )-} [(iota - w(e_t e_t' V{c 94}-1)) .* H_{c -(}t-1{c )-}] + (X_{c -(}t-1{c )-} # I_m)
V{c 94}-1 e_t
and expected Hessian F_t = -(X X' # V{c 94}-1) - 1/4 grad h D{c 94}-2 (Gamma{c 94}-1 .* Gamma +
I) D{c 94}-2 grad h'.
The derivative of the conditional variances is computed by the recursion
grad h_{c -(}t-1{c )-} = -2 sum_{c -(}l=1{c )-}{c 94}q (X_{c -(}t-1-l{c )-} # I) diag(a_l .* e_{c -(}t-l{c )-}) + sum_{c -(}l=1{c )-}{c 94}p grad
h_{c -(}t-1-l{c )-} diag(b_l),
with zero pre-sample values, which equals the expansion with nu_l from a(z)/b(z) in (B.1).

{pstd}
{ul:Step 3: variance parameters} delta_dot. The CCC-GARCH is re-estimated on the one-step
full-rank residuals (see Remarks).

{pstd}
{ul:Step 4: initial reduced-rank estimator} (SML Sec. 4.1): Johansen reduced-rank regression
ignoring the GARCH, giving A_hat, B_hat, Phi*_hat [,mu_hat].

{pstd}
{ul:Step 5: one-step reduced-rank QMLE} (SML (4.5)-(4.8)), both at (alpha_hat, delta_dot):
vec(B_dot) = vec(B_hat) - (sum R_1t){c 94}-1 sum grad_{c -(}alpha1{c )-} l_t with regressor (Y_{c -(}t-1{c )-} # A'),
R_1t = -(Y Y' # A'V{c 94}-1 A) - 1/4 grad h D{c 94}-2 (Gamma{c 94}-1 .* Gamma + I) D{c 94}-2 grad
h' (4.7);
alpha_2 = vec(A, Phi*, [mu]) updated with U_{c -(}t-1{c )-} = (Y'_{c -(}t-1{c )-}B', W'_{c -(}t-1{c )-}, ... [,1])' (4.6),
(4.8).

{pstd}
{ul:Step 6: statistics}. With phi_ddot = vec(A_dot B_dot, Phi*_ddot [, mu_ddot]),
{p_end}
{p 8 8 2}LR_G = (phi_dot - phi_ddot)'(-sum F_t)(phi_dot - phi_ddot), F_t at (phi_dot, delta_dot)
(SML (5.4));{p_end}
{p 8 8 2}H_G = (phi_dot - phi_ddot)'(-sum F{c 94}H_t)(phi_dot - phi_ddot),
F{c 94}H_t = -(X X' # A_p (A_p'O1{c 94}-1 O1* O1{c 94}-1 A_p){c 94}-1 A_p') (SML
(5.5)-(5.6)).{p_end}

{pstd}
{ul:Step 7: nuisance parameters} (SML Sec. 6). EV = n{c 94}-1 sum V_{c -(}t-1{c )-};
A_p = (I - c c'A_dot (A_dot'c c'A_dot){c 94}-1 A_dot') c_perp, c = (I_r, 0)', c_perp = (0, I_d)';
xi_t = sum_{c -(}l=1{c )-}{c 94}q diag(a_l .* e_{c -(}t-l{c )-}) + sum_{c -(}l=1{c )-}{c 94}p xi_{c -(}t-l{c )-} diag(b_l), xi_0 = 0;
Omega_1 = n{c 94}-1 sum V{c 94}-1 + n{c 94}-1 sum xi_t D{c 94}-2 (Gamma{c 94}-1 .* Gamma + I)
D{c 94}-2 xi_t;
Omega*_1 = the same with (Delta - iota iota'), Delta = n{c 94}-1 sum w(eta eta'Gamma{c 94}-1)
w(.)'.
lambda = eig{c -(}I_d - (A_p'O1{c 94}-1 A_p){c 94}(1/2) (A_p' EV A_p){c 94}-1 (A_p'O1{c 94}-1 A_p){c 94}(1/2){c )-} (Thm 5.2), used for LR_G;
lambda{c 94}H = eig{c -(}I_d - T{c 94}(-1/2) (A_p'O1{c 94}-1 A_p)(A_p' EV A_p){c 94}-1 (A_p'O1{c 94}-1 A_p) T{c 94}(-1/2){c )-},
T = A_p'O1{c 94}-1 O1* O1{c 94}-1 A_p (Thm 5.1), used for H_G.

{pstd}
{ul:Limit distribution} (SML (5.7)-(5.8), (5.10)-(5.11), (6.1)-(6.4)):
tr{c -(}[zeta (I - L){c 94}(1/2) + Phi L{c 94}(1/2)]'[zeta (I - L){c 94}(1/2) + Phi L{c 94}(1/2)]{c )-}, L
= diag(lambda),
Phi a d x d matrix of iid N(0,1), zeta = (int B B'){c 94}(-1/2) int B dB' (B demeaned under
{cmd:trend(rconstant)}). Simulation: zeta = (n{c 94}-2 sum y y'){c 94}(-1/2)(n{c 94}-1 sum
y_{c -(}t-1{c )-} e_t')
from Gaussian random walks; the same draws (common random numbers) are used for LR_NG
(lambda = 0) and both GARCH-based statistics. p = share of simulated values >= the statistic.

{pstd}
{ul:Critical-value tables}. {cmd:method(qmle)}: SML Tables 1-3 (90/95/99%, lambda = 0,...,0.9,
d = 1 and 2, with and without constant); for {cmd:trend(none)} the lambda = 1.0 edge is taken from
Sin Tables A.1-A.2 (same functional). {cmd:method(wls)}: Sin Tables A.1-A.2 (no constant,
lambda up to 1.0); with {cmd:trend(rconstant)} the constant blocks of SML Tables 1-3
(Extended implementation). Interpolation is bilinear on the 0.1 grid; the d = 2 tables are
symmetric in (lambda_1, lambda_2).

{pstd}
{ul:method(wls)} (Sin c. 2004). V_hat_t from the GARCH fitted to the LS residuals is held
fixed. Full rank: vec(C_dot, Phi*_dot) = (sum X X' # V_hat{c 94}-1){c 94}-1 sum (X #
V_hat{c 94}-1) W_t
(Sin (3.3)-(3.4)); reduced rank: (4.9)-(4.10) with R~_1t = -(Y Y' # A'V{c 94}-1 A),
R~_2t = -(U U' # V{c 94}-1). W_G = vec(C_dot - A_dot B_dot)'(sum Y_{c -(}t-1{c )-}Y'_{c -(}t-1{c )-} #
V_hat{c 94}-1)vec(.)
(5.2). W*_G = vec(C* - A_dot B*)'(sum Y Y' # V{c 94}-1 e e' V{c 94}-1)vec(.) with
vec(C*) = (sum F*){c 94}-1 (sum F) vec(C_dot), B* = (A'O1* A){c 94}-1 (A'O1 A) B_dot (5.4).
Omega_1 = n{c 94}-1 sum V_hat{c 94}-1, Omega*_1 = n{c 94}-1 sum V{c 94}-1 e e' V{c 94}-1,
V_* = n{c 94}-1 sum e e' (reduced-rank WLS residuals); lambda uses (Omega_1, V_*) (Thm 5.1),
lambda* uses (Omega*_1, V_*) (Cor 5.1).

{pstd}
{ul:Sequential selection}: the selected rank is the first r whose statistic does not exceed
its critical value at {opt level()}; m if all nulls are rejected.


{marker remarks}{c -(}...{c )-}
{title:Remarks}

{pstd}
{ul:Original versus extended.} Original: LR_G, H_G, one-step estimators, nuisance
estimation, the limit and its simulation, SML Tables 1-3 (SML 2024); W_G, W*_G and Tables
A.1-A.2 (Sin c. 2004); the Johansen LR_NG. Extended implementation: {cmd:cv(sim)} for d > 2
(the method is the one of SML Sec. 6), W_G/W*_G with a constant, automatic simulation for
d > 2 under {cmd:cv(table)}, the lambda = 1.0 edge for SML none tables, and the numerical
choices listed below.

{pstd}
{ul:Implementation choices and corrections} (documented deviations):{p_end}
{p 8 10 2}1. delta_dot is obtained by re-estimating the CCC-GARCH (equation-by-equation QMLE
plus the correlation of standardised residuals) on the one-step full-rank residuals,
instead of the one-step Newton update (3.3) with S_t. Any root-n consistent variance
estimator leaves the limits of the mean-parameter estimators unchanged under symmetric eta
(SML Assumption 2.5, Sec. 4.2). The same delta_dot is used in both likelihoods (as in
(5.2)).{p_end}
{p 8 10 2}2. phi_ddot uses the reduced-rank one-step estimates of all short-run parameters
(SML allow Phi*_ddot in place of Phi*_dot after (5.4)); then LR_G is the quadratic
approximation of 2[l_F(phi_dot) - l_R(alpha_dot)].{p_end}
{p 8 10 2}3. Phi in Theorems 5.1-5.2 is simulated as a d x d matrix of iid N(0,1) (the text
says N(0, I_d), exact only for d = 1).{p_end}
{p 8 10 2}4. {cmd:trend(rconstant)}: SML (5.9) print the restriction as B_perp mu = 0; with
C = AB the no-trend condition is A_perp'mu = 0 (mu = A mu_0). The tabulated limits (demeaned
Brownian motion, e.g. 8.167 at d = 1, lambda = 0, 95%, i.e. the squared Dickey-Fuller
t with constant) are those of the statistic in which mu is estimated freely in both models,
as in Reinsel & Ahn (1992); SML's own Table 7 LR_NG p-values (15.60, p = .101 at d = 2)
agree with these limits. The Johansen restricted-constant estimator (mu = A mu_0 imposed
under H0) has a different limit (9.24 at d = 1, 95%), so it is not used here. Hence
{cmd:rconstant} means: constant in the model, no linear trend in the data.{p_end}
{p 8 10 2}5. Sin's W_G is written with F~_t built on the full X_{c -(}t-1{c )-} although vec(C_dot -
A_dot B_dot) is m{c 94}2-dimensional; the Y_{c -(}t-1{c )-}Y'_{c -(}t-1{c )-} # V{c 94}-1 block is used (likewise
for F*_t in W*_G).{p_end}
{p 8 10 2}6. A_perp: when c'A_dot is singular the orthonormal complement of A_dot is used;
the eigenvalues are invariant to the basis of sp(A_perp). SML and Sin print two algebraically
different but equally valid formulas.{p_end}
{p 8 10 2}7. Estimated eigenvalues are truncated to [0, 1] before the look-up; when a
lambda exceeds the tabulated range (0.9 for SML constant tables) the value at 0.9 is used,
which is conservative because critical values decrease in lambda.{p_end}

{pstd}
{ul:Which statistic?} LR_G's limit with lambda is valid when Omega*_1 = Omega_1 (e.g.
Gaussian eta); H_G is valid more generally. W_G assumes a correctly specified conditional
variance; W*_G is robust to its misspecification. With estimated lambda the tests are
asymptotically valid for the estimated nuisance; with n = 200-400 SML report slight
over-rejection similar to Johansen's test.

{pstd}
{ul:Limitations.} Diagonal CCC-GARCH only (no spillovers); no deterministic trend; one-step
estimators only; GARCH orders up to 4; computational cost grows with (m{c 94}2 s){c 94}2.


{marker examples}{c -(}...{c )-}
{title:Examples}

{pstd}Simulated trivariate VAR(1) with GARCH(1,1) errors (SML Sec. 7, DGP (a)){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2024}{p_end}
{phang2}{cmd:. set obs 500}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. foreach v in z1 z2 z3 {c -(}}{p_end}
{phang2}{cmd:.     gen double `v' = rnormal()}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. foreach v in h1 h2 h3 {c -(}}{p_end}
{phang2}{cmd:.     gen double `v' = 1}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. foreach v in e1 e2 e3 y1 y2 y3 {c -(}}{p_end}
{phang2}{cmd:.     gen double `v' = 0}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. forvalues s = 2/500 {c -(}}{p_end}
{phang2}{cmd:.     local u = `s' - 1}{p_end}
{phang2}{cmd:.     foreach i in 1 2 3 {c -(}}{p_end}
{phang2}{cmd:.         qui replace h`i' = 0.1 + 0.3*e`i'[`u']{c 94}2 + 0.6*h`i'[`u'] in `s'}{p_end}
{phang2}{cmd:.         qui replace e`i' = z`i'*sqrt(h`i') in `s'}{p_end}
{phang2}{cmd:.     {c )-}}{p_end}
{phang2}{cmd:.     local ec = y1[`u'] - 2.5*y2[`u']}{p_end}
{phang2}{cmd:.     qui replace y1 = y1[`u'] - 0.40*`ec' + e1 in `s'}{p_end}
{phang2}{cmd:.     qui replace y2 = y2[`u'] + 0.12*`ec' + e2 in `s'}{p_end}
{phang2}{cmd:.     qui replace y3 = y3[`u'] + 0.12*`ec' + e3 in `s'}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}QMLE tests, tabulated critical values (no constant, as in the DGP){p_end}
{phang2}{cmd:. cointvol garchrank y1 y2 y3, lags(1) trend(none)}{p_end}

{pstd}Simulated critical values and p-values{p_end}
{phang2}{cmd:. cointvol garchrank y1 y2 y3, lags(1) trend(none) cv(sim) simreps(5000) seed(1)}{p_end}

{pstd}WLS Wald tests with a constant, GARCH(1,2){p_end}
{phang2}{cmd:. cointvol garchrank y1 y2 y3, lags(2) method(wls) garch(1 2)}{p_end}

{pstd}Replication style (SML Sec. 8): logs of FEDFUNDS, TB3MS and GS1, monthly 1960-1979,
VAR(4), GARCH(1,1), constant{p_end}
{phang2}{cmd:. cointvol garchrank lff ltb3 lgs1 if tin(1960m1,1979m12), lags(4) trend(rconstant) cv(sim)}{p_end}


{marker results}{c -(}...{c )-}
{title:Stored results}

{pstd}{cmd:cointvol garchrank} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{c -(}...{c )-}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}effective number of observations n{p_end}
{synopt:{cmd:r(m)}}number of variables{p_end}
{synopt:{cmd:r(lags)}}lag order s{p_end}
{synopt:{cmd:r(level)}}test level{p_end}
{synopt:{cmd:r(garch_p)}, {cmd:r(garch_q)}}GARCH orders{p_end}
{synopt:{cmd:r(simreps)}, {cmd:r(simn)}}simulation settings{p_end}
{synopt:{cmd:r(nsim)}}number of rows whose critical values were simulated{p_end}
{synopt:{cmd:r(garch_fail)}}number of non-converged univariate GARCH fits{p_end}
{synopt:{cmd:r(rank_LRNG)}}selected rank, Johansen{p_end}
{synopt:{cmd:r(rank_LRG)}, {cmd:r(rank_HG)}}selected ranks, {cmd:method(qmle)}{p_end}
{synopt:{cmd:r(rank_WG)}, {cmd:r(rank_WsG)}}selected ranks, {cmd:method(wls)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol garchrank}{p_end}
{synopt:{cmd:r(varlist)}}variables{p_end}
{synopt:{cmd:r(trend)}}{cmd:none} or {cmd:rconstant}{p_end}
{synopt:{cmd:r(method)}}{cmd:qmle} or {cmd:wls}{p_end}
{synopt:{cmd:r(cv)}}{cmd:table} or {cmd:sim}{p_end}
{synopt:{cmd:r(stat1)}, {cmd:r(stat2)}}names of the two GARCH-based statistics{p_end}
{synopt:{cmd:r(seed)}}seed{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}one row per null rank: r, d, LR_NG, its c.v. and p, statistic 1, c.v., p,
statistic 2, c.v., p, c.v. source (1 table, 2 simulation), 90/95/99% c.v. of each statistic,
lambda-truncation flag{p_end}
{synopt:{cmd:r(lambda1)}}lambda-hat (LR_G or W_G) per null rank, padded with missing{p_end}
{synopt:{cmd:r(lambda2)}}lambda-hat{c 94}H (H_G) or lambda-hat* (W*_G){p_end}
{synopt:{cmd:r(eigenvalues)}}Johansen eigenvalues{p_end}
{synopt:{cmd:r(Pi_ls)}, {cmd:r(Pi_fr)}}LS and one-step full-rank coefficients (C, Phi*_1, ...,
[mu]){p_end}
{synopt:{cmd:r(garch0)}, {cmd:r(Gamma0)}}CCC-GARCH on the LS residuals{p_end}
{synopt:{cmd:r(garch)}, {cmd:r(Gamma)}}CCC-GARCH used for the tests (delta-dot for qmle){p_end}
{synopt:{cmd:r(Omega1)}}Omega_1-hat{p_end}
{synopt:{cmd:r(Omega1s)}, {cmd:r(EV)}, {cmd:r(Delta)}}Omega*_1-hat, EV-hat, Delta-hat
({cmd:method(qmle)}){p_end}
{synopt:{cmd:r(A_r#)}, {cmd:r(B_r#)}}one-step reduced-rank A_dot (m x r) and B_dot (r x m) for
H0: rank = #{p_end}


{marker references}{c -(}...{c )-}
{title:References}

{phang}
Sin, C.-y., Z. Mi and S. Ling. 2024. On a partially non-stationary vector AR model with
vector GARCH noises: estimation and testing. {it:Communications in Mathematical Research}
40(1): 64-101. {browse "https://doi.org/10.4208/cmr.2023-0005":doi:10.4208/cmr.2023-0005}.

{phang}
Sin, C.-y. c. 2004. Estimation and testing for partially nonstationary vector
autoregressive models with GARCH: WLS versus QMLE. Working paper, Department of Economics,
Hong Kong Baptist University; Econometric Society 2004 North American Summer Meetings,
paper 92.

{phang}
Bollerslev, T. 1990. Modelling the coherence in short-run nominal exchange rates: a
multivariate generalized ARCH model. {it:Review of Economics and Statistics} 72: 498-505.

{phang}
Johansen, S. 1995. {it:Likelihood-Based Inference in Cointegrated Vector Autoregressive
Models}. Oxford: Oxford University Press.

{phang}
Reinsel, G. C. and S. K. Ahn. 1992. Vector autoregressive models with unit roots and
reduced rank structure: estimation, likelihood ratio test, and forecasting.
{it:Journal of Time Series Analysis} 13: 353-375.


{marker author}{c -(}...{c )-}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original method papers above together with the {cmd:cointvol} package.
{p_end}
