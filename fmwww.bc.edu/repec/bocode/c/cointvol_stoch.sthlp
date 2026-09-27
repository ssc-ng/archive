{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol hetcoint" "help cointvol_hetcoint"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{viewerjumpto "Syntax" "cointvol_stoch##syntax"}{...}
{viewerjumpto "Description" "cointvol_stoch##description"}{...}
{viewerjumpto "Options" "cointvol_stoch##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_stoch##methods"}{...}
{viewerjumpto "Remarks" "cointvol_stoch##remarks"}{...}
{viewerjumpto "Examples" "cointvol_stoch##examples"}{...}
{viewerjumpto "Stored results" "cointvol_stoch##results"}{...}
{viewerjumpto "References" "cointvol_stoch##references"}{...}
{viewerjumpto "Author" "cointvol_stoch##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:cointvol stoch} {hline 2}}Stochastic cointegration: AIV estimation with HAC
inference and residual-based tests of stochastic cointegration, heteroskedastic
cointegration and heteroskedastic integration{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol stoch} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Estimation}
{synopt:{opt est:imator(aiv|ols)}}estimator; default {cmd:aiv}{p_end}
{synopt:{opt k(#)}}instrument lag k of the AIV estimator; default {cmd:ceil(T{c 94}(1/2))}{p_end}
{synopt:{opt l(#|nw)}}HAC truncation l for the coefficient covariance; default
{cmd:ceil(T{c 94}(1/3))}; must satisfy l < k{p_end}
{synopt:{opt tr:end}}add a linear trend to the regression (and to the instrument){p_end}

{syntab:Residual tests}
{synopt:{opt tests(list)}}any of {cmd:snc shc shi}; default all three{p_end}
{synopt:{opt notests}}skip the residual tests{p_end}
{synopt:{opt kt:est(#)}}lag k used by the tests; default {cmd:[T{c 94}(1/2)]}, or {cmd:k()}
if given{p_end}
{synopt:{opt lt:est(#|fixed|nw)}}HAC truncation of the tests; default {cmd:fixed} =
[12(T/100){c 94}(1/4)]{p_end}

{syntab:Reporting}
{synopt:{opt lev:el(#)}}confidence level and test level; default {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (not a panel) with no gaps in the estimation sample.
{it:depvar} and {it:indepvars} may contain time-series operators.
{cmd:predict} is available after estimation (options {cmd:xb}, {cmd:residuals}), as are
{helpb test}, {helpb lincom} and {helpb nlcom}. Typing {cmd:cointvol stoch} without arguments
replays the results.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol stoch} estimates a single-equation cointegrating regression

{p 8 8 2}
y_t = alpha + [kappa t] + x_t'beta + u_t

{pstd}
in the stochastic cointegration framework of Harris, McCabe and Leybourne (2002, HML) and
McCabe, Leybourne and Harris (2006, MLH). The variables are generated as
z_t = mu + [delta t] + Pi w_t + epsilon_t + V_t h_t, where w_t and h_t are random walks and V_t
is a stationary random coefficient. A series is {it:heteroskedastically integrated} (HI) when
it has a random-walk component whose loading varies stochastically. It then has a variance that
trends like an I(1) process but it is not I(1). The variables are {it:stochastically cointegrated}
when c'Pi = 0. The cointegration is {it:stationary} (Engle-Granger) when c'V_t = 0, and
{it:heteroskedastic} otherwise: the equilibrium error u_t then has no stochastic trend but its
variance grows over time.

{pstd}
When a regressor is HI, OLS is inconsistent (HML, Theorem 1). The asymptotic instrumental
variables (AIV) estimator uses X_(t-k) as instrument for X_t with k growing like T{c 94}(1/2).
It is sqrt(T)-consistent and, under the exogeneity condition (8) of HML, mixed normal, so HAC
t and Wald tests are asymptotically N(0,1) and chi2.

{pstd}
On the AIV residuals the command computes the three MLH tests:

{p 8 12 2}
S_nc: H0 stochastic cointegration (stationary or heteroskedastic) against no cointegration.{p_end}
{p 8 12 2}
S_hc: H0 stationary cointegration against heteroskedastic cointegration.{p_end}
{p 8 12 2}
S_hi: for each series in the model, H0 I(1) against heteroskedastic integration.{p_end}

{pstd}
{it:When to use.} Use it when volatility appears to grow with the level of the series (interest
rates, prices in levels), when an Engle-Granger or Johansen analysis looks fragile, or to find
out whether an apparent failure of cointegration is only heteroskedastic cointegration.
{it:When not to use.} Do not use it for systems with more than one cointegrating vector: the
regression assumes rank(Pi_x) = m - 1. For conditional (GARCH-type) or deterministic
nonstationary volatility in a VECM, use {helpb cointvol_rank:cointvol rank}. If only the
dependent variable has an I(1) scale and all regressors are I(1), see
{helpb cointvol_hetcoint:cointvol hetcoint}.


{marker options}{...}
{title:Options}

{phang}
{opt estimator(aiv|ols)} picks the estimator. {cmd:aiv} (default; Original: HML 2002, eq. 6,
MLH 2006, eq. 7) is b_k = (sum X_(t-k)X_t'){c 94}-1 sum X_(t-k)y_t over t = k+1,...,T, with
X_t = (x_t', [t], 1)'. {cmd:ols} (Extended implementation) is OLS with the same HAC covariance
on X_t u_t. It is inconsistent under heteroskedastic cointegration and is provided only for
comparison. The residual tests always use AIV residuals, whatever {cmd:estimator()} is.

{phang}
{opt k(#)} sets the instrument lag k >= 1. The default ceil(T{c 94}(1/2)) is the HML Monte Carlo
rule (Original: HML 2002, Section 4). Theory needs k -> infinity with k = O(T{c 94}(1/2)).

{phang}
{opt l(#|nw)} sets the Bartlett truncation l for the covariance of the estimator. The default
is ceil(T{c 94}(1/3)) (Original: HML 2002, Section 4). If this default is not below k, it is
reset to k - 1 with a note. A user value must be a nonnegative integer smaller than k
(Assumption KN: l = o(k)); otherwise the command stops with an error. {cmd:l(nw)} selects l by
the Newey-West (1994) automatic rule applied to the sum of the non-constant elements of
X_(t-k)u_t, capped at k - 1 (Extended implementation).

{phang}
{opt trend} adds a linear trend t = 1,...,T to X_t, and hence to the instrument (MLH 2006,
eqs. 3 and 7). With {cmd:trend}, S_hi is computed on demeaned differences.

{phang}
{opt tests(list)} selects the tests to display: {cmd:snc}, {cmd:shc}, {cmd:shi}. All are
computed internally. {opt notests} skips them altogether.

{phang}
{opt ktest(#)} sets the lag k used by the tests. It is used both for the AIV residuals entering
the tests and for the lag of S_nc. The default [T{c 94}(1/2)] (integer part) is the MLH
recommendation (Original: MLH 2006, Section 4). When {cmd:k()} is given and {cmd:ktest()} is
not, the tests use the same k. It must be at least 2.

{phang}
{opt ltest(#|fixed|nw)} sets the Bartlett truncation of the long-run variances in the tests.
{cmd:fixed} (default) is l = [12(T/100){c 94}(1/4)]. {cmd:nw} is the Newey-West (1994) automatic
rule, applied separately to each test's series (Original: MLH 2006, Section 4). For S_nc and
S_hc the condition l < k of MLH Theorem 1 is {it:always} enforced: a larger l is reset to k - 1
and marked "a" in the table. MLH enforce it only for the automatic rule; enforcing it for the
fixed rule too is an extension. S_hi involves no k, so no cap applies to it.

{phang}
{opt level(#)} sets the confidence level of the intervals. 100 - {it:#} is the level used for
the stars in the test table.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model} (MLH 2006, eqs. 1-4). With z_t = (y_t, x_t')', c = (1, -beta')':
u_t = e_t + q'w_t + nu_t'h_t, where e_t = c'epsilon_t, q' = c'Pi and nu_t' = c'V_t.
The hypotheses are H0: q = 0 (stochastic cointegration) against H1: q != 0. Within H0 they are
H0{c 94}0: E(nu_t'nu_t) = 0 (stationary cointegration) against H1{c 94}0: E(nu_t'nu_t) > 0
(heteroskedastic cointegration).

{pstd}
{bf:Step 1. AIV estimator} (HML 2002, eq. 6; MLH 2006, eq. 7):

{p 8 8 2}
b_k = (sum_(t=k+1..T) X_(t-k) X_t'){c 94}-1 sum_(t=k+1..T) X_(t-k) y_t.

{pstd}
HML print the top-right block of the moment matrix as sum x'_(t-k). The IV definition, and MLH
eq. (7), give sum x_t'. The command uses the IV form; the two are asymptotically equivalent.
With {cmd:trend}, using t or t-k in the instrument spans the same space, so the estimates are
identical.

{pstd}
{bf:Step 2. HAC covariance} (HML 2002, eq. 9 and Theorem 4):

{p 8 8 2}
Sigma_k = T (sum X_(t-k)X_t'){c 94}-1 Omega(X_(t-k)u_t) (sum X_t X_(t-k)'){c 94}-1,{break}
Omega(a) = Gamma_0 + sum_(j=1..l) lambda(j/l)(Gamma_j + Gamma_j'),
Gamma_j = T{c 94}-1 sum_t a_t a_(t-j)',

{pstd}
with the Bartlett window lambda(x) = 1 - x as printed, so lags j = 1,...,l-1 carry weight, and
autocovariances not demeaned. Because of the factor T, Sigma_k is the variance of b_k itself.
The reported standard errors are sqrt((Sigma_k)_ii), the t-ratio is
(b_ki - b_i0)/sqrt((Sigma_k)_ii), and e(V) = Sigma_k.

{pstd}
{it:Correction.} HML eq. (10) prints the denominator as sqrt((Sigma_k{c 94}-1)_ii). Theorem 4
states Sigma_k{c 94}(-1/2)(b_k - b) -> N(0, I), so Sigma_k is the variance and the inverse is a
misprint. With the inverse the t-ratio would diverge.

{pstd}
{bf:Step 3. Residuals} u_t = y_t - alpha_k - kappa_k t - x_t'beta_k for all t = 1,...,T
(MLH 2006, eq. 8). The tests use the AIV fit with lag {cmd:ktest()}.

{pstd}
{bf:Long-run variance} (MLH 2006, eq. 5): omega2(a) = gamma_0(a) + 2 sum_(j=1..l) lambda(j/l)
gamma_j(a), gamma_j(a) = T{c 94}-1 sum_(s=j+1..T) a_s a_(s-j). The autocovariances are not
demeaned, and lambda is Bartlett.

{pstd}
{bf:Step 4. S_nc} (MLH 2006, eq. 6 and Theorem 1):

{p 8 8 2}
S_nc = T{c 94}(-1/2) sum_(t=k+1..T) u_t u_(t-k) / sqrt(omega2(u_t u_(t-k))).

{pstd}
It is N(0,1) under stochastic cointegration when k = O(T{c 94}(1/2)), l = o(k) and l < k, and
|S_nc| diverges under no cointegration. The test is two-sided.

{pstd}
{bf:Step 5. S_hc} (MLH 2006, eq. 9 and Theorem 2):

{p 8 8 2}
S_hc = sqrt(12) T{c 94}(-3/2) sum_(t=1..T) t (u_t{c 94}2 - s2) / sqrt(omega2(u_t{c 94}2 - s2)),
s2 = T{c 94}-1 sum u_t{c 94}2.

{pstd}
It is N(0,1) under stationary cointegration and diverges under heteroskedastic cointegration.
The test is two-sided.

{pstd}
{it:Correction.} The working-paper version prints the scale factor as (1/12){c 94}(1/2). Under
H0{c 94}0, T{c 94}(-3/2) sum t(u_t{c 94}2 - s2) = T{c 94}(-3/2) sum (t - (T+1)/2)(u_t{c 94}2 - s2)
converges to N(0, omega2/12), because the integral of (s - 1/2){c 94}2 over [0,1] is 1/12. The
proof's "12 omega2" contains the same slip. Standardisation therefore requires sqrt(12). The
printed factor would give a variance of 1/144 and a size close to zero, which contradicts the
paper's own simulated sizes of about 0.05. The command uses sqrt(12). This is pending
confirmation against the published text (Econometric Theory 22, 2006).

{pstd}
{bf:Step 6. S_hi} (MLH 2006, Section 3.2): the S_hc formula applied to u_t = Delta y_t - d_y,
t = 2,...,T, with d_y = mean(Delta y_t) when {cmd:trend} is specified, and u_t = Delta y_t
otherwise, as the paper states. Following MLH footnote 9, it is computed for every series in
the model. It is N(0,1) under I(1) and diverges under HI.

{pstd}
{bf:Newey-West (1994) automatic lag} (Bartlett): n = floor(4(T/100){c 94}(2/9));
s0 = g_0 + 2 sum_(j<=n) g_j and s1 = 2 sum_(j<=n) j g_j, where g_j are uncentred
autocovariances of the series; gamma = 1.1447 ((s1/s0){c 94}2){c 94}(1/3); m = floor(gamma
T{c 94}(1/3)). The command uses l = m + 1, so that lambda(j/l) = 1 - j/(m+1) reproduces the NW
weights exactly. If s0 <= 0, the fixed rule is used instead.

{pstd}
{bf:Inference.} All p-values are two-sided N(0,1) p-values. Wald tests from {helpb test} use
e(V) = Sigma_k and are chi2(q). The command posts no residual degrees of freedom.

{pstd}
{bf:Step -> equation map.}{break}
AIV: HML (6), MLH (7) | covariance: HML (9), Thm 4 | t-ratio: HML (10), corrected |
residuals: MLH (8) | omega2: MLH (5) | S_nc: MLH (6), Thm 1 | S_hc: MLH (9), Thm 2, corrected |
S_hi: MLH Sec. 3.2 | lag rules: HML Sec. 4, MLH Sec. 4.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Intercept.} Under heteroskedastic cointegration the AIV intercept is O_p(1) but not
consistent (HML, Theorem 2). Its t-ratio is still asymptotically N(0,1) under the exogeneity
condition, but it has no power. HML recommend always keeping the constant.

{pstd}
{bf:Choice of k.} MLH recommend k = [T{c 94}(1/2)] for the tests. Power of S_nc falls quickly
as k grows (MLH, Table 3). Values around 0.75T{c 94}(1/2) give S_nc slightly more power but
over-reject with strongly persistent errors. The estimator uses ceil(T{c 94}(1/2)) as in HML.
The two coincide when T is a perfect square.

{pstd}
{bf:Size in finite samples.} The AIV t-test over-rejects for positively autocorrelated
equilibrium errors (for example about 0.14 at phi = 0.8, T = 200; HML Table 1). S_nc and S_hc
over-reject when the stationary component is close to a unit root (phi = 0.9; MLH Table 1).
Treat marginal rejections with caution.

{pstd}
{bf:Exogeneity.} Mixed normality of the AIV estimator requires HML condition (8),
E(vec(V_t) eta_(t-j)') = 0. MLH report that moderate violations barely affect the size of the
tests.

{pstd}
{bf:Labels.} Original: AIV, HAC covariance, corrected t-ratio (HML 2002); S_nc, S_hc, S_hi,
fixed and NW automatic l (MLH 2006). Extended implementation: {cmd:estimator(ols)}, {cmd:l(nw)}
for the estimator covariance, S_hi for the regressors (suggested in MLH footnote 9), and the
l < k cap under the fixed rule.


{marker examples}{...}
{title:Examples}

{pstd}Simulate the HML (2002) design (y is I(1), x is heteroskedastically integrated,
beta = 1){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2002}{p_end}
{phang2}{cmd:. set obs 400}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen e4 = rnormal()}{p_end}
{phang2}{cmd:. gen w1 = sum(e4)}{p_end}
{phang2}{cmd:. gen ey = 0.5*e4 + sqrt(0.75)*rnormal()}{p_end}
{phang2}{cmd:. gen ex = 0.5*e4 + sqrt(0.75)*rnormal()}{p_end}
{phang2}{cmd:. gen vx = sqrt(0.05)*rnormal()}{p_end}
{phang2}{cmd:. gen y = w1 + ey}{p_end}
{phang2}{cmd:. gen x = w1 + vx*w1 + ex}{p_end}

{pstd}AIV estimation with the default k, l and all three tests{p_end}
{phang2}{cmd:. cointvol stoch y x}{p_end}

{pstd}Test beta = 1 with the HAC Wald test{p_end}
{phang2}{cmd:. test x = 1}{p_end}

{pstd}OLS for comparison; automatic lag selection in the tests{p_end}
{phang2}{cmd:. cointvol stoch y x, estimator(ols) ltest(nw)}{p_end}

{pstd}MLH-style choice of k, with a trend{p_end}
{phang2}{cmd:. cointvol stoch y x, k(15) ltest(nw) trend}{p_end}

{pstd}Residuals and replay{p_end}
{phang2}{cmd:. predict uhat, residuals}{p_end}
{phang2}{cmd:. cointvol stoch, level(90)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cointvol stoch} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations T{p_end}
{synopt:{cmd:e(N_eff)}}observations in the moment sums (T - k for AIV){p_end}
{synopt:{cmd:e(k)}}instrument lag of the estimator{p_end}
{synopt:{cmd:e(l)}}HAC truncation used for e(V){p_end}
{synopt:{cmd:e(k_test)}}lag k of the tests{p_end}
{synopt:{cmd:e(l_test)}}fixed or user l of the tests, before the l < k cap{p_end}
{synopt:{cmd:e(chi2)}, {cmd:e(df_m)}, {cmd:e(p)}}Wald test that all slopes are zero{p_end}
{synopt:{cmd:e(S_nc)}, {cmd:e(p_nc)}, {cmd:e(l_nc)}}S_nc, p-value, l used{p_end}
{synopt:{cmd:e(S_hc)}, {cmd:e(p_hc)}, {cmd:e(l_hc)}}S_hc, p-value, l used{p_end}
{synopt:{cmd:e(S_hi)}, {cmd:e(p_hi)}, {cmd:e(l_hi)}}S_hi of {it:depvar}, p-value, l used{p_end}
{synopt:{cmd:e(sigma2)}}mean squared residual of the reported fit{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}, {cmd:e(tdelta)}}sample time range and delta{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cointvol stoch}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}}variables{p_end}
{synopt:{cmd:e(estimator)}}{cmd:aiv} or {cmd:ols}{p_end}
{synopt:{cmd:e(trend)}}{cmd:trend} or {cmd:none}{p_end}
{synopt:{cmd:e(lrule)}}{cmd:default}, {cmd:user} or {cmd:nw}{p_end}
{synopt:{cmd:e(ltestrule)}}{cmd:fixed}, {cmd:user} or {cmd:nw}{p_end}
{synopt:{cmd:e(testlist)}}tests requested{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcetype)}}{cmd:hac}, {cmd:HAC}{p_end}
{synopt:{cmd:e(kernel)}}{cmd:bartlett}{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(predict)}}{cmd:cointvol_stoch_p}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients (slopes, {cmd:_trend}, {cmd:_cons}) and Sigma_k{p_end}
{synopt:{cmd:e(tests)}}rows S_nc, S_hc, S_hi_{it:var}...; columns stat, pvalue, k, l,
l_adjusted{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Harris, D., B. McCabe and S. Leybourne. 2002. Stochastic cointegration: estimation and
inference. {it:Journal of Econometrics} 111(2): 363-384.
{browse "https://doi.org/10.1016/S0304-4076(02)00111-2":doi:10.1016/S0304-4076(02)00111-2}.

{phang}
McCabe, B., S. Leybourne and D. Harris. 2006. A residual-based test for stochastic
cointegration. {it:Econometric Theory} 22(3): 429-456.
{browse "https://doi.org/10.1017/S026646660606021X":doi:10.1017/S026646660606021X}.

{phang}
Hansen, B. E. 1992. Heteroskedastic cointegration. {it:Journal of Econometrics} 54(1-3):
139-158. {browse "https://doi.org/10.1016/0304-4076(92)90103-X":doi:10.1016/0304-4076(92)90103-X}.

{phang}
Newey, W. K. and K. D. West. 1994. Automatic lag selection in covariance matrix estimation.
{it:Review of Economic Studies} 61(4): 631-653.
{browse "https://doi.org/10.2307/2297912":doi:10.2307/2297912}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original method papers above and the {cmd:cointvol} package.

{title:Also see}

{psee}
{helpb cointvol}, {helpb cointvol_hetcoint:cointvol hetcoint},
{helpb cointvol_rank:cointvol rank}, {helpb newey}
{p_end}
