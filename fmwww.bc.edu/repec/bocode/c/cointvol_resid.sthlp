{smcl}
{* *! version 0.2.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol ecm" "help cointvol_ecm"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "[TS] arch" "help arch"}{...}
{viewerjumpto "Syntax" "cointvol_resid##syntax"}{...}
{viewerjumpto "Description" "cointvol_resid##description"}{...}
{viewerjumpto "Options" "cointvol_resid##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_resid##methods"}{...}
{viewerjumpto "Published critical values" "cointvol_resid##tables"}{...}
{viewerjumpto "Remarks" "cointvol_resid##remarks"}{...}
{viewerjumpto "Examples" "cointvol_resid##examples"}{...}
{viewerjumpto "Stored results" "cointvol_resid##results"}{...}
{viewerjumpto "References" "cointvol_resid##references"}{...}
{viewerjumpto "Author" "cointvol_resid##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:cointvol resid} {hline 2}}Residual-based tests of no cointegration under GARCH
errors{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 22 2}
{cmd:cointvol resid} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Tests}
{synopt:{opt test(list)}}any of {cmd:eg ta1 crdw hc0 tar mtar kss kssecm gh ghzt ghza}
{cmd:hj hjzt hjza vr}, or {cmd:all}; default {cmd:eg ta1 crdw hc0}{p_end}
{synopt:{opt tr:end(string)}}deterministic terms: {cmd:none}, {cmd:constant} (default) or
{cmd:trend}{p_end}
{synopt:{opt lag:s(#|aic|bic|tsig)}}lags of the differenced residual; default {cmd:aic}{p_end}
{synopt:{opt maxl:ags(#)}}maximum lag for {cmd:aic}/{cmd:bic}/{cmd:tsig}; default
int(4(T/100){c 94}0.25){p_end}
{synopt:{opt trim(#)}}trimming for thresholds and break dates; default 0.15{p_end}
{synopt:{opt thr:eshold(string)}}TAR/MTAR threshold: {cmd:estimate} (Chan 1993; default) or
{cmd:zero}{p_end}
{synopt:{opt shift(string)}}break tests: {cmd:regime} (level and slopes; default) or
{cmd:level}{p_end}

{syntab:Critical values}
{synopt:{opt cv(list)}}{cmd:auto} (default), {cmd:table}, {cmd:sim}, {cmd:fkm}, {cmd:none};
combinations such as {cmd:cv(sim table)} or {cmd:cv(sim fkm)} are allowed{p_end}
{synopt:{opt garch(a b)}}GARCH(1,1) ARCH and GARCH coefficients of the simulated null
innovations (and of the FKM look-up){p_end}
{synopt:{opt simr:eps(#)}}Monte Carlo replications; default 10000 (1000 for the break
tests){p_end}

{syntab:Bootstrap (extended implementation)}
{synopt:{opt boot:strap(wild|none)}}null-imposed wild bootstrap; default {cmd:none}{p_end}
{synopt:{opt r:eps(#)}}bootstrap replications; default 499{p_end}
{synopt:{opt mult:iplier(name)}}{cmd:rademacher} (default), {cmd:mammen} or {cmd:gauss}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}decision level; default {cmd:level(95)}{p_end}
{synopt:{opt nodots}}suppress replication dots{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (not as a panel) with no gaps in the estimation sample.
{it:depvar} and {it:indepvars} may contain time-series operators.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol resid} computes single-equation residual-based tests of the null hypothesis
of {it:no cointegration} between {it:depvar} and {it:indepvars}. The first step is the
static OLS regression of {it:depvar} on the deterministic terms and {it:indepvars}. The
statistics are then computed from its residuals (or, for {cmd:vr}, from the levels).

{pstd}
Each statistic is implemented as defined in its original paper, and each test uses by
default the critical values {it:published} in that paper whenever the configuration (number
of regressors, deterministic terms, trimming, lags) is tabulated. Otherwise the finite-sample
null distribution is simulated. The column {cmd:Src} of the output shows the source
({cmd:tab} published table, {cmd:sim} simulated, {cmd:fkm} Franses-Kofman-Moser).

{pstd}
Conditional heteroskedasticity (GARCH) makes these tables unreliable. Franses, Kofman and
Moser (1994) show that the Engle-Granger critical values shift to the left under
(near-)integrated GARCH. Lee and Tse (1996) document over-rejection of the EG, T(a-1) and
CRDW tests. Maki (2013) finds that the threshold and structural-break tests are affected most,
while Breitung's variance ratio is almost unaffected. The command therefore also offers
simulated critical values under user-specified GARCH(1,1) innovations ({cmd:cv(sim)} with
{opt garch()}), the FKM GARCH-adjusted value ({cmd:cv(fkm)}) and a null-imposed wild
bootstrap ({cmd:bootstrap(wild)}).

{pstd}
Use this command for a single cointegrating relation with a known normalisation. For
system rank tests that are robust to heteroskedasticity, use
{helpb cointvol_rank:cointvol rank}; for error-correction tests use
{helpb cointvol_ecm:cointvol ecm}. The tests are not invariant to the choice of
{it:depvar}.


{marker options}{...}
{title:Options}

{phang}
{opt test(list)} selects the tests; the order of the list is irrelevant.

{p2colset 9 20 22 2}{...}
{p2col:{cmd:eg}}Engle-Granger ADF t-statistic on the residuals (left tail).
Original: Engle and Granger (1987); FKM (1994) eqs (5)-(6).{p_end}
{p2col:{cmd:ta1}}coefficient statistic T(a-1) (left tail). Original: Lee and Tse
(1996).{p_end}
{p2col:{cmd:crdw}}cointegrating-regression Durbin-Watson (right tail). Original: Lee and
Tse (1996).{p_end}
{p2col:{cmd:hc0}}DF t-statistic with White (1980) HC0 standard error, "tau-White" (left
tail). Original: Lee and Tse (1996).{p_end}
{p2col:{cmd:tar}}Enders-Siklos TAR F for rho1 = rho2 = 0 (right tail). Original: Enders and
Siklos (2001) eqs (6)-(7), (10).{p_end}
{p2col:{cmd:mtar}}Enders-Siklos momentum-TAR F(M) (right tail). Original: Enders and Siklos
(2001) eq (11).{p_end}
{p2col:{cmd:kss}}KSS t_NLEG: residual-based t on u(t-1){c 94}3 (left tail). Original:
Kapetanios, Shin and Snell (2006) eqs (3.4)-(3.6); the variant used by Maki (2013).{p_end}
{p2col:{cmd:kssecm}}KSS t_NLECM: nonlinear STAR error-correction t (left tail). Original:
KSS (2006) eqs (3.1)-(3.3), (3.13)-(3.16).{p_end}
{p2col:{cmd:gh}}Gregory-Hansen ADF* (left tail). Original: GH (1996) eq (3.3).{p_end}
{p2col:{cmd:ghzt}}Gregory-Hansen Zt* (left tail). Original: GH (1996) eq (3.2).{p_end}
{p2col:{cmd:ghza}}Gregory-Hansen Z_alpha* (left tail). Original: GH (1996) eq (3.1).{p_end}
{p2col:{cmd:hj}}Hatemi-J two-regime-shift ADF* (left tail). Original: Hatemi-J (2008)
eq (7).{p_end}
{p2col:{cmd:hjzt}}Hatemi-J Zt* (left tail). Original: Hatemi-J (2008) eq (8).{p_end}
{p2col:{cmd:hjza}}Hatemi-J Z_alpha* (left tail). Original: Hatemi-J (2008) eq (9).{p_end}
{p2col:{cmd:vr}}Breitung variance ratio Lambda_q for r = 0 (right tail). Original: Breitung
(2002) eq (12).{p_end}
{p2colreset}{...}

{phang}
{opt trend(string)} sets the deterministic terms of the cointegrating regression (and the
adjustment for {cmd:vr} and {cmd:kssecm}): {cmd:none}, {cmd:constant} (default) or
{cmd:trend} (constant and linear trend). In the break tests the constant shifts with each
regime; the trend does not shift.

{phang}
{opt lags(#|aic|bic|tsig)} gives the number of lagged differences in the ADF-type
regressions. {cmd:aic} or {cmd:bic} choose it from 0 to {opt maxlags()} on a common sample.
{cmd:tsig} is the general-to-specific rule of Gregory and Hansen (1996, p. 110): start at
{opt maxlags()} and drop the last lag until it is significant at 5% with normal critical
values (GH use a maximum of 6: {cmd:maxlags(6)}). The lag chosen on the static residual is
used by {cmd:eg ta1 hc0 tar mtar kss kssecm}; {cmd:gh} and {cmd:hj} select the lag afresh at
every break date. {cmd:crdw}, {cmd:vr} and the Phillips Z tests use no lags. Default
{cmd:aic}.

{phang}
{opt maxlags(#)} is the maximum lag for data-dependent selection. The default is
int(4(T/100){c 94}0.25).

{phang}
{opt trim(#)}, 0 < # < 0.5, is the trimming fraction. For {cmd:tar}/{cmd:mtar} with an
estimated threshold, the threshold is searched over the [#, 1-#] order statistics of the
threshold variable. For {cmd:gh*} the break fraction lies in [#, 1-#]. For {cmd:hj*}, tau1
lies in [#, 1-2#] and tau2 in [tau1+#, 1-#] (this needs # < 1/3). The default 0.15 follows
Enders-Siklos, Gregory-Hansen and Hatemi-J, and is the trimming of their tables; Maki
(2013) uses 0.05.

{phang}
{opt threshold(estimate|zero)}: {cmd:estimate} (default) chooses the threshold that
minimises the sum of squared residuals (the consistent estimator of Chan 1993, used by
Enders and Siklos in their application and by Maki 2013); {cmd:zero} fixes it at the
attractor 0, the case tabulated in Enders-Siklos Tables 1-2.

{phang}
{opt shift(regime|level)}: {cmd:regime} shifts the intercept and all slopes (GH model C/S,
eq. 2.3; Hatemi-J eq. 2); {cmd:level} shifts only the intercept (GH model C, or C/T with
{cmd:trend(trend)}, eq. 2.2). {cmd:level} requires an intercept.

{phang}
{opt cv(list)} selects the critical values:

{p2colset 9 20 22 2}{...}
{p2col:{cmd:auto}}(default) the published table when the configuration is tabulated (see
{help cointvol_resid##tables:Published critical values}); otherwise simulated as in
{cmd:sim}. With {opt garch()}, every test is simulated.{p_end}
{p2col:{cmd:table}}published values only; untabulated tests get no critical values.{p_end}
{p2col:{cmd:sim}}finite-sample values simulated for every test: independent random walks
with the same T, number of regressors, deterministic terms, lag rule, threshold rule,
shift model and trimming; the lag selection and all grid searches are re-run in each
replication. The published values are listed below the table for comparison.{p_end}
{p2col:{cmd:fkm}}the Franses-Kofman-Moser 5% value for {cmd:eg} (adds {cmd:eg} if
necessary).{p_end}
{p2col:{cmd:none}}no critical values.{p_end}
{p2colreset}{...}

{phang}
{opt garch(a b)} sets the ARCH coefficient {it:a} and GARCH coefficient {it:b} of the
GARCH(1,1) innovations used in the simulation. The intercept is 1-a-b, so the unconditional
variance is 1 (Lee and Tse 1996); it is 1 when a+b >= 1 (FKM 1994). The same (a, b) are used
by {cmd:cv(fkm)}. Without {opt garch()}, the simulation uses iid N(0,1) innovations and
{cmd:cv(fkm)} estimates (a, b).

{phang}
{opt simreps(#)} is the number of Monte Carlo replications, at least 20. The default is
10000 for the non-break tests and 1000 for the break tests. A value given here applies to
all tests.

{phang}
{opt bootstrap(wild)} adds a null-imposed wild bootstrap p-value ({bf:extended
implementation}; see {help cointvol_resid##boot:the algorithm}). {opt reps(#)} gives the
number of replications (default 499, minimum 19). {opt multiplier()} is {cmd:rademacher}
(default), {cmd:mammen} (Mammen 1993 two-point) or {cmd:gauss}.

{phang}
{opt seed(#)} sets the random-number seed before the simulation and the bootstrap.

{phang}
{opt level(#)} sets the level of the decision column. The decision uses the bootstrap
p-value when {cmd:bootstrap(wild)} is specified; otherwise the simulated p-value or, for
published tables, the tabulated critical value (available for {cmd:level(90)},
{cmd:level(95)} and {cmd:level(99)} only); with {cmd:cv(fkm)} alone, the FKM 5% value for
{cmd:eg}.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model and hypotheses.} Let y(t) be {it:depvar} and x(t) the m x 1 vector of
{it:indepvars}. Under H0 all m+1 series are I(1) and not cointegrated; under H1,
y(t) - d(t)'delta - x(t)'b is I(0) (or a stationary nonlinear process). The first step is OLS

{p 8 8 2}y(t) = d(t)'delta + x(t)'b + u(t),   t = 1,...,T,{p_end}

{pstd}
with d(t) = {} (none), 1 (constant) or (1, t) (trend); u^(t) are the residuals.

{pstd}
{bf:ADF regression.} Du^(t) = rho u^(t-1) + sum_(j=1..p) phi_j Du^(t-j) + e(t),
t = p+2,...,T, with n observations.

{p 8 12 2}{cmd:eg}: t = rho^/se(rho^) (OLS). FKM (1994) eq. (6); Engle and Granger
(1987).{p_end}
{p 8 12 2}{cmd:ta1}: n rho^/(1 - sum phi^_j) (Lee and Tse's T(a-1) for p = 0).{p_end}
{p 8 12 2}{cmd:hc0}: rho^/sqrt(V[1,1]), V = (Z'Z){c 94}-1 Z'diag(e^{c 94}2)Z (Z'Z){c 94}-1
(White 1980; Lee and Tse 1996 "tau-White").{p_end}
{p 8 12 2}{cmd:crdw}: DW = sum (Du^(t)){c 94}2 / sum u^(t){c 94}2 (Sargan and Bhargava
1983; Lee and Tse 1996). Rejects for large values.{p_end}

{pstd}
{bf:Enders-Siklos TAR / M-TAR} (2001, eqs 6, 7, 10, 11, 16):

{p 8 8 2}Du^(t) = I(t) rho1 u^(t-1) + (1-I(t)) rho2 u^(t-1) + sum_(i=1..p) gamma_i Du^(t-i)
+ e(t),  I(t) = 1{c -(}z(t-1) >= tau{c )-},{p_end}

{pstd}
with z(t-1) = u^(t-1) (TAR) or Du^(t-1) (M-TAR). The statistic is the usual regression
F-statistic for H0: rho1 = rho2 = 0,

{p 8 8 2}F = [(S0 - S1)/2] / [S1/(n - 2 - p)],{p_end}

{pstd}
where S1 is the SSR of the regression above and S0 the SSR with rho1 = rho2 = 0. With
{cmd:threshold(zero)}, tau = 0 (E-S Tables 1-2). With {cmd:threshold(estimate)}, tau
minimises S1 over the trimmed order statistics of z (Chan 1993), the "consistent threshold"
version (E-S call its statistic Phi*). Maki (2013) reports n(S0 - S1)/S1 = 2nF/(n-2-p), a
monotone transformation of F for given n and p; decisions based on simulated critical
values are therefore identical, but only the E-S form can be compared with the E-S tables.

{pstd}
{bf:KSS t_NLEG} (Kapetanios, Shin and Snell 2006, eqs 3.4-3.6): the t-ratio on delta in
Du^(t) = delta u^(t-1){c 94}3 + sum phi_i Du^(t-i) + eta(t), with sigma{c 94}2 = SSR/T
(no degrees-of-freedom correction, eq. 3.6). This residual-based form is the test used by
Maki (2013).

{pstd}
{bf:KSS t_NLECM} (eqs 3.1-3.3, 3.13-3.16): y and x are demeaned ({cmd:trend(constant)}) or
demeaned and detrended ({cmd:trend(trend)}), u^ = y* - x*'b^ (OLS without intercept), and
t_NLECM is the t-ratio on delta in

{p 8 8 2}Dy*(t) = delta u^(t-1){c 94}3 + omega'Dx*(t) + sum_(i=1..p) gamma_i'Dz*(t-i) + e(t),
z = (y, x')',{p_end}

{pstd}
with sigma{c 94}2 = SSR/T. The lag order p is the one selected on the static residual.

{pstd}
{bf:Gregory-Hansen} (1996): for each break date TB = [T tau], tau in [trim, 1-trim], OLS of
y on d(t), phi(t) = 1(t > TB) and x(t) (model C; C/T with {cmd:trend(trend)}), plus
x(t)phi(t) with {cmd:shift(regime)} (model C/S). From the residuals e(t) (GH p. 105):

{p 8 12 2}ADF(TB): the ADF t-ratio with lag chosen by {opt lags()};{p_end}
{p 8 12 2}rho = sum e(t)e(t+1)/sum e(t){c 94}2, v(t) = e(t) - rho e(t-1),
sigma{c 94}2 = gamma(0) + 2 lambda (long-run variance of v),
rho* = sum (e(t)e(t+1) - lambda)/sum e(t){c 94}2;{p_end}
{p 8 12 2}Z_alpha(TB) = T(rho* - 1), Z_t(TB) = (rho* - 1)/s, s{c 94}2 = sigma{c 94}2/sum
e(t){c 94}2.{p_end}

{pstd}
ADF*, Zt* and Z_alpha* are the infima over TB (eqs 3.1-3.3); each statistic has its own
minimising break date. As in GH (and Hatemi-J, fn. 3), sigma{c 94}2 is a prewhitened
quadratic-spectral estimate: AR(1) prewhitening, Andrews (1991) AR(1) plug-in bandwidth
S = 1.3221(a2 N){c 94}(1/5), a2 = 4rho{c 94}2/(1-rho){c 94}4 (Andrews and Monahan 1992),
recoloured by (1-phi){c 94}-2; autocovariances use the divisor T.

{pstd}
{bf:Hatemi-J} (2008): D1(t) = 1(t > TB1), D2(t) = 1(t > TB2), each shifting the constant and
the slopes (eq. 2); tau1 in [trim, 1-2trim], tau2 in [tau1+trim, 1-trim]. ADF*, Zt* and
Z_alpha* are the infima over (TB1, TB2) of the same three statistics (eqs 3-9).

{pstd}
{bf:Breitung (2002) variance ratio}: z(t) = (y(t), x(t)')' is mean- or trend-adjusted
according to {opt trend()}; Z(t) = sum_(s<=t) z(s), A = sum z z', B = sum Z Z'. With
lambda_1 <= ... <= lambda_n the eigenvalues of A B{c 94}-1, Lambda_q = T{c 94}2
sum_(j=1..q) lambda_j (eq. 12). H0: r = 0 means q = n = m+1 stochastic trends, so
Lambda_n = T{c 94}2 trace(A B{c 94}-1). It diverges under cointegration and rejects for
large values.

{marker sim}{...}
{pstd}
{bf:Simulated critical values} ({cmd:cv(sim)}; Lee and Tse 1996 sec. 2, Maki 2013
sec. 3). In each of R replications, m+1 independent random walks of length T are generated
with (a) iid N(0,1) innovations or (b) GARCH(1,1) innovations
h(t) = w0 + a eps(t-1){c 94}2 + b h(t-1), h(0) = 1, eps(0) = 0, 500 burn-in draws
discarded (w0 = 1-a-b if a+b < 1, else 1). The first series is the regressand. Every
requested statistic is recomputed exactly as for the data. Critical values are the
empirical 1/5/10% quantiles (99/95/90% for right-tailed tests); the p-value is
(#{c -(}more extreme or equal{c )-} + 1)/(R + 1).

{marker fkm}{...}
{pstd}
{bf:FKM critical value} ({cmd:cv(fkm)}; Franses, Kofman and Moser 1994): the 5% critical
value of the EG t-test for T = 250, one regressor, a constant and no lags. (a, b) come from
{opt garch()} or, as FKM did, from the average of GARCH(1,1) estimates ({helpb arch}) on the
first differences of every series. |a+b-1| < 0.02: eq. (7), cv = -3.20 - 2.02a + 1.25a{c 94}2;
a+b >= 1.02: eq. (8), cv = -3.428 - 1.79a; a+b <= 0.98: Table 1 at the nearest design point
within distance 0.05, otherwise -3.38.

{marker boot}{...}
{pstd}
{bf:Wild bootstrap} ({cmd:bootstrap(wild)}; {bf:extended implementation}).

{p 8 12 2}1. v(t) = Dy(t) - mean(Dy), t = 2,...,T.{p_end}
{p 8 12 2}2. For b = 1,...,B draw iid multipliers w(t) and build y*(1) = y(1),
y*(t) = y*(t-1) + v(t) w(t): an I(1) process, not cointegrated with x, that inherits the
heteroskedasticity pattern of Dy.{p_end}
{p 8 12 2}3. Regress y* on d(t) and the {it:original} x(t) and recompute every requested
statistic (lag selection, threshold and break searches included).{p_end}
{p 8 12 2}4. p = share of bootstrap statistics at least as extreme as the observed one.{p_end}

{pstd}
{bf:Step -> source map.}{break}
static regression, ADF t: FKM (1994) eqs (5)-(6); Engle and Granger (1987){break}
T(a-1), CRDW, tau-White, tau'-White: Lee and Tse (1996), sec. 2 and Table 1{break}
TAR/M-TAR F: Enders and Siklos (2001) eqs (6)-(7), (10)-(11), (16); Chan (1993){break}
t_NLEG, t_NLECM: KSS (2006) eqs (3.1)-(3.6), (3.13)-(3.16){break}
GH ADF*, Zt*, Za*: Gregory and Hansen (1996) eqs (2.2)-(2.3), (3.1)-(3.3), p. 105{break}
HJ ADF*, Zt*, Za*: Hatemi-J (2008) eqs (2)-(9){break}
VR: Breitung (2002) eqs (10)-(12){break}
published critical values: see {help cointvol_resid##tables:below}{break}
GARCH null DGP: Lee and Tse (1996) sec. 2; FKM (1994) sec. 3; Maki (2013) eqs (32)-(33){break}
FKM critical value: FKM (1994) Table 1, eqs (7)-(8){break}
wild bootstrap: extended implementation


{marker tables}{...}
{title:Published critical values}

{pstd}
The following tables are embedded ({cmd:cv(auto)} and {cmd:cv(table)}); all were
transcribed from page images of the source papers and are checked in the test file.

{p2colset 5 18 20 2}{...}
{p2col:{cmd:tar}, {cmd:mtar}}Enders and Siklos (2001), working-paper version, Tables 1
and 2: threshold 0 ({cmd:threshold(zero)}), {cmd:trend(constant)}, m = 1 or 2, T = 100 and
500, 0, 1 or 4 lags (the lag actually used). For 100 < T < 500 the value is interpolated
linearly in 1/T; outside that range the nearest tabulated T is used (noted in the output).
The Phi* table for the estimated threshold is not in the working paper supplied, so
{cmd:threshold(estimate)} uses simulated values.{p_end}
{p2col:{cmd:kss}, {cmd:kssecm}}KSS (2006; WP 497) Table 1 (T = 1000, 50000 replications,
asymptotic): m = 1..5; Case 1 {cmd:trend(none)}, Case 2 {cmd:trend(constant)}, Case 3
{cmd:trend(trend)}.{p_end}
{p2col:{cmd:gh*}}Gregory and Hansen (1996) Table 1 (asymptotic, response-surface intercept
psi_0): m = 1..4, trim = 0.15; model C ({cmd:shift(level) trend(constant)}), C/T
({cmd:shift(level) trend(trend)}), C/S ({cmd:shift(regime) trend(constant)}). ADF* and Zt*
share the same values.{p_end}
{p2col:{cmd:hj*}}Hatemi-J (2008) Table 1 (asymptotic): m = 1..4, trim = 0.15,
{cmd:shift(regime) trend(constant)}.{p_end}
{p2col:{cmd:vr}}Breitung (2002; SFB 373 DP 1999) Table A.2 (T = 500): q = m+1 = 1..8,
mean adjusted ({cmd:trend(constant)}) or trend adjusted ({cmd:trend(trend)}).{p_end}
{p2col:{cmd:eg ta1 crdw hc0}}no table in the sources used here: simulated.{p_end}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which inference?} The published tables assume iid (or weakly dependent, homoskedastic)
innovations and are asymptotic or for a fixed T. Under stationary GARCH with moderate
persistence the tests are close to nominal size once T is a few hundred (Lee and Tse 1996).
With a+b close to 1 and a large ARCH coefficient the EG-type tests over-reject, and the
threshold and break tests over-reject heavily (Maki 2013: M-TAR 34-39% at nominal 5% for
ARCH 0.64, GARCH 0.16). Use {cmd:cv(sim)} with {opt garch(a b)} set to estimated values, or
{cmd:bootstrap(wild)}, which needs no parametric volatility model.

{pstd}
{bf:tau'-White.} Lee and Tse's tau'-White compares the HC0 t-statistic with the ordinary
DF-tau critical value: compare {cmd:hc0} with the {cmd:eg} critical values.

{pstd}
{bf:Computing time.} {cmd:hj*} evaluate about (1-3 trim){c 94}2 T{c 94}2/2 break pairs; the
Phillips Z forms also need a kernel long-run variance at each pair. With simulated critical
values or the bootstrap this is repeated in every replication. The published tables avoid
this cost in the tabulated configurations.

{pstd}
{bf:Labels.} Original: every statistic listed under {opt test()}; the published tables;
{cmd:cv(sim)} (Lee and Tse 1996; Maki 2013); {cmd:cv(fkm)} (FKM 1994); {cmd:lags(tsig)}
(GH 1996). Extended implementation: {cmd:bootstrap(wild)}; information-criterion lag
selection; untabulated configurations (for example {cmd:trend(none)} or
{cmd:shift(regime) trend(trend)} in the break tests, level shifts in {cmd:hj*}); the
1/T interpolation of the E-S table; the Table 1 look-up rule of FKM.

{pstd}
{bf:Corrections and discrepancies documented.}{break}
(i) Maki (2013) computes the TAR/M-TAR statistic as n(S0-S1)/S1 with 5-95% trimming; the
E-S statistic is the regression F with 15-85% trimming (default here). The two are monotone
transformations of each other. Earlier versions of this command reported Maki's form.{break}
(ii) KSS define sigma{c 94}2 = SSR/T (eqs 3.3, 3.6); the t-ratio therefore equals the OLS
t-ratio times sqrt(n/(n-k)). Maki (2013) does not state the variance estimator; the KSS
definition is used.{break}
(iii) Maki (2013) uses only the residual-based t_NLEG of KSS; the ECM-based t_NLECM
({cmd:kssecm}) is also provided.{break}
(iv) Maki (2013) uses only the ADF* form of the GH and HJ tests; Zt* and Z_alpha* are now
provided as in the original papers.{break}
(v) Breitung Table A.2 labels its rows "r = n - q"; the values are those of q, the number of
stochastic trends (row 1 equals the reciprocal of Table A.1 at T = 500).{break}
(vi) Hatemi-J Table 1 reports -52.232 as the 10% value of Z_alpha* for m = 1, out of line
with the other entries (-76.003 at 5%); it is embedded as printed.{break}
(vii) The Enders-Siklos working paper compares its M-TAR statistic with 5.98, a Table 1 (TAR)
value; the M-TAR values are in Table 2 and are used here.{break}
(viii) Lee and Tse (1996) print the GARCH recursion with the ARCH and GARCH labels swapped;
FKM's text mentions cubic terms in eq. (7), but the printed equation is quadratic.


{marker examples}{...}
{title:Examples}

{pstd}Simulated data: two independent random walks and a cointegrated pair{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen x = sum(rnormal())}{p_end}
{phang2}{cmd:. gen u = rnormal()}{p_end}
{phang2}{cmd:. replace u = 0.6*L.u + rnormal() in 2/l}{p_end}
{phang2}{cmd:. gen y = 1 + 0.8*x + u}{p_end}
{phang2}{cmd:. gen w = sum(rnormal())}{p_end}

{pstd}Minimal: the Lee-Tse set with simulated critical values{p_end}
{phang2}{cmd:. cointvol resid y x, lags(0) simreps(2000) seed(1)}{p_end}

{pstd}Nonlinear and break tests with their published critical values{p_end}
{phang2}{cmd:. cointvol resid y x, test(kss kssecm gh ghzt ghza vr) lags(tsig) maxlags(6)}{p_end}

{pstd}Enders-Siklos with the threshold at zero (tabulated) and estimated (simulated){p_end}
{phang2}{cmd:. cointvol resid w x, test(tar mtar) lags(1) threshold(zero)}{p_end}
{phang2}{cmd:. cointvol resid w x, test(tar mtar) lags(1) simreps(2000) seed(1)}{p_end}

{pstd}Simulated and published values side by side{p_end}
{phang2}{cmd:. cointvol resid y x, test(kss vr gh) lags(0) cv(sim table) simreps(1000) seed(1)}{p_end}

{pstd}GARCH-calibrated critical values and the FKM value{p_end}
{phang2}{cmd:. cointvol resid y x, test(eg crdw) lags(0) cv(sim fkm) garch(0.3 0.69) seed(2)}{p_end}

{pstd}Two regime shifts, all three Hatemi-J statistics{p_end}
{phang2}{cmd:. cointvol resid y x, test(hj hjzt hjza) lags(0)}{p_end}

{pstd}Wild bootstrap including a break test (slow){p_end}
{phang2}{cmd:. cointvol resid y x, test(eg gh) lags(1) cv(none) bootstrap(wild) reps(199) seed(3)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol resid} stores the following in {cmd:r()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(m)}}number of regressors{p_end}
{synopt:{cmd:r(lags)} / {cmd:r(maxlags)}}fixed lag / maximum lag for data-dependent selection{p_end}
{synopt:{cmd:r(trim)}}trimming fraction{p_end}
{synopt:{cmd:r(level)}}decision level{p_end}
{synopt:{cmd:r(simreps)}}simulation replications (non-break tests; only if simulated){p_end}
{synopt:{cmd:r(simreps_break)}}simulation replications for the break tests (if simulated){p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(garch_a)}, {cmd:r(garch_b)}}user GARCH coefficients{p_end}
{synopt:{cmd:r(}{it:test}{cmd:)}}statistic, e.g. {cmd:r(eg)}, {cmd:r(ghza)}{p_end}
{synopt:{cmd:r(cv05_}{it:test}{cmd:)}}5% critical value used (table or simulated){p_end}
{synopt:{cmd:r(tcv05_}{it:test}{cmd:)}}published 5% critical value (tabulated tests){p_end}
{synopt:{cmd:r(p_}{it:test}{cmd:)}}simulated p-value{p_end}
{synopt:{cmd:r(pb_}{it:test}{cmd:)}}bootstrap p-value{p_end}
{synopt:{cmd:r(tar_threshold)}}TAR threshold (also {cmd:r(mtar_threshold)}){p_end}
{synopt:{cmd:r(gh_break)}}first period of the new regime at the ADF* infimum (also
{cmd:r(ghzt_break)}, {cmd:r(ghza_break)}){p_end}
{synopt:{cmd:r(hj_break1)}, {cmd:r(hj_break2)}}first periods of the HJ regimes (also
{cmd:hjzt_}, {cmd:hjza_}){p_end}
{synopt:{cmd:r(fkm_cv)}}FKM 5% critical value{p_end}
{synopt:{cmd:r(fkm_alpha)}, {cmd:r(fkm_beta)}}(averaged) GARCH coefficients used{p_end}
{synopt:{cmd:r(fkm_region)}}1 Table 1, 2 eq. (7), 3 eq. (8){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol resid}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables{p_end}
{synopt:{cmd:r(tests)}}tests computed{p_end}
{synopt:{cmd:r(trend)}, {cmd:r(lags)}, {cmd:r(cv)}}options used{p_end}
{synopt:{cmd:r(threshold)}, {cmd:r(shift)}}options used{p_end}
{synopt:{cmd:r(bootstrap)}, {cmd:r(multiplier)}, {cmd:r(seed)}}bootstrap settings{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}one row per test; columns {cmd:stat cv01 cv05 cv10 p_sim p_boot
lags tail param1 param2 bcv05 simreps reject} (cv columns = the critical values used;
tail -1 left / +1 right; param1 = threshold or first break index, param2 = second break
index; bcv05 = bootstrap 5% critical value){p_end}
{synopt:{cmd:r(cvtable)}}one row per test; columns {cmd:tcv01 tcv05 tcv10 tabcode cvsrc}:
published values, tabcode (0 not tabulated, 1 tabulated, 2 interpolated in 1/T, 3 nearest
tabulated T) and cvsrc (0 none, 1 table, 2 simulated, 3 FKM){p_end}
{synopt:{cmd:r(boot)}}B x 15 bootstrap statistics (columns
{cmd:eg ta1 crdw hc0 tar mtar kss gh hj vr kssecm ghzt ghza hjzt hjza}){p_end}
{synopt:{cmd:r(fkm_garch)}}per-series GARCH(1,1) estimates used by {cmd:cv(fkm)}{p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance
matrix estimation. {it:Econometrica} 59: 817-858. doi:10.2307/2938229.

{phang}
Andrews, D. W. K., and J. C. Monahan. 1992. An improved heteroskedasticity and
autocorrelation consistent covariance matrix estimator. {it:Econometrica} 60: 953-966.
doi:10.2307/2951574.

{phang}
Breitung, J. 2002. Nonparametric tests for unit roots and cointegration.
{it:Journal of Econometrics} 108: 343-363. doi:10.1016/S0304-4076(01)00139-7.
(Working-paper version used for Table A.2: Some nonparametric tests for unit roots and
cointegration, SFB 373 Discussion Paper 1999-36, Humboldt University Berlin.)

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares estimator of
a threshold autoregressive model. {it:Annals of Statistics} 21: 520-533.
doi:10.1214/aos/1176349040.

{phang}
Enders, W., and P. L. Siklos. 2001. Cointegration and threshold adjustment.
{it:Journal of Business and Economic Statistics} 19: 166-176.
doi:10.1198/073500101316970395. (Tables 1-2 taken from the working-paper version.)

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Co-integration and error correction:
Representation, estimation, and testing. {it:Econometrica} 55: 251-276.
doi:10.2307/1913236.

{phang}
Franses, P. H., P. Kofman, and J. Moser. 1994. GARCH effects on a test of cointegration.
{it:Review of Quantitative Finance and Accounting} 4: 19-26. doi:10.1007/BF01082662.

{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in models
with regime shifts. {it:Journal of Econometrics} 70: 99-126.
doi:10.1016/0304-4076(69)41685-7.

{phang}
Hatemi-J, A. 2008. Tests for cointegration with two unknown regime shifts with an
application to financial market integration. {it:Empirical Economics} 35: 497-505.
doi:10.1007/s00181-007-0175-9.

{phang}
Kapetanios, G., Y. Shin, and A. Snell. 2006. Testing for cointegration in nonlinear smooth
transition error correction models. {it:Econometric Theory} 22: 279-303.
doi:10.1017/S0266466606060129. (Working-paper version: Queen Mary, University of London,
Department of Economics Working Paper 497, 2003.)

{phang}
Lee, T.-H., and Y. Tse. 1996. Cointegration tests with conditional heteroskedasticity.
{it:Journal of Econometrics} 73: 401-410. doi:10.1016/S0304-4076(95)01745-3.

{phang}
Maki, D. 2013. The influence of heteroskedastic variances on cointegration tests: A
comparison using Monte Carlo simulations. {it:Computational Statistics} 28: 179-198.
doi:10.1007/s00180-011-0293-x.

{phang}
Mammen, E. 1993. Bootstrap and wild bootstrap for high dimensional linear models.
{it:Annals of Statistics} 21: 255-285. doi:10.1214/aos/1176349025.

{phang}
White, H. 1980. A heteroskedasticity-consistent covariance matrix estimator and a direct
test for heteroskedasticity. {it:Econometrica} 48: 817-838. doi:10.2307/1912934.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original method papers above together with the {cmd:cointvol} package.

{title:Also see}

{psee}
{helpb cointvol}, {helpb cointvol_ecm:cointvol ecm}, {helpb cointvol_rank:cointvol rank},
{helpb arch}
{p_end}
