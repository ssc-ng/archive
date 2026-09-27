{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol stoch" "help cointvol_stoch"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{viewerjumpto "Syntax" "cointvol_hetcoint##syntax"}{...}
{viewerjumpto "Description" "cointvol_hetcoint##description"}{...}
{viewerjumpto "Options" "cointvol_hetcoint##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_hetcoint##methods"}{...}
{viewerjumpto "Remarks" "cointvol_hetcoint##remarks"}{...}
{viewerjumpto "Examples" "cointvol_hetcoint##examples"}{...}
{viewerjumpto "Stored results" "cointvol_hetcoint##results"}{...}
{viewerjumpto "References" "cointvol_hetcoint##references"}{...}
{viewerjumpto "Author" "cointvol_hetcoint##author"}{...}
{title:Title}

{p2colset 5 27 29 2}{...}
{p2col:{bf:cointvol hetcoint} {hline 2}}Heteroskedastic cointegration: OLS with HAC Wald
inference (bandwidth o(T{c 94}(1/4))) and a split-sample test of equal error variance{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol hetcoint} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt bw:idth(#)}}HAC bandwidth B; default {cmd:floor(T{c 94}(1/5))}{p_end}
{synopt:{opt ker:nel(name)}}{cmd:bartlett} (default), {cmd:parzen} or {cmd:qs}{p_end}
{synopt:{opt splitt:est}}report Hansen's split-sample test of equal error variance{p_end}
{synopt:{opt splitl:ag(#)}}Bartlett lag of the split-sample t-test; default {cmd:5}{p_end}
{synopt:{opt lev:el(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (not a panel) with no gaps. Time-series operators are allowed.
After estimation, {helpb test}, {helpb lincom}, {helpb nlcom} and {cmd:predict} ({cmd:xb},
{cmd:residuals}) work as usual; typing {cmd:cointvol hetcoint} alone replays the table.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol hetcoint} implements Hansen (1992). The cointegrating regression is

{p 8 8 2}
y_t = b0 + b1'x_t + w_t,  x_t = x_(t-1) + u_3t,  w_t = sigma_t u_1t,  sigma_t = sigma_(t-1) + u_2t.

{pstd}
The scale sigma_t of the equilibrium error is itself I(1), so w_t is "bi-integrated": its variance
grows like t, as do the variances of the regressors, yet w_t keeps crossing its mean. Hansen calls
this heteroskedastic cointegration (HCI). Under HCI:

{p 8 12 2}
(i) the OLS slope is sqrt(T)-consistent even with endogenous regressors (Theorem 1);{p_end}
{p 8 12 2}
(ii) the OLS intercept is {it:not} consistent: it converges to b0 + Lambda_21 (Theorem 1);{p_end}
{p 8 12 2}
(iii) under long-run orthogonality (Assumption 3) the slope is a variance mixture of normals whose
variance is not proportional to the OLS moment matrix, so the usual OLS standard errors are
invalid (Theorem 2);{p_end}
{p 8 12 2}
(iv) a HAC Wald statistic with bandwidth B = o(T{c 94}(1/4)) is asymptotically chi2(q)
(Theorem 3).{p_end}

{pstd}
The command estimates by OLS and reports HAC standard errors built with Hansen's bandwidth rule.
{helpb test} then delivers the chi2 Wald test of Theorem 3. The option {cmd:splittest} reproduces
Hansen's Table 1 diagnostic: a HAC t-test that the error variance is the same in both halves of
the sample.

{pstd}
{it:When to use.} The regressors are I(1), and the residual variance of the levels regression
appears to grow over time (the split-sample test rejects). {it:When not to use.} If a regressor
may itself be heteroskedastically integrated, OLS is inconsistent; use
{helpb cointvol_stoch:cointvol stoch} (AIV) instead. If the errors are I(1), there is no
cointegration at all.


{marker options}{...}
{title:Options}

{phang}
{opt bwidth(#)} sets the bandwidth (lag truncation) B >= 0. Theorem 3 requires B -> infinity
with B = o(T{c 94}(1/4)), slower than the usual o(T{c 94}(1/2)). The default floor(T{c 94}(1/5))
satisfies this; it gives B = 2 for 32 <= T < 243 and B = 3 for 243 <= T < 1024. Hansen gives no
constant, so the default rule is an implementation choice consistent with the theorem. A warning
is printed when B > T{c 94}(1/4).

{phang}
{opt kernel(name)} sets the kernel weights k_m. {cmd:bartlett} (default) uses
k_m = 1 - |m|/(B+1), |m| <= B, the Newey-West (1987) convention. Hansen's Theorem 3 holds for
any weights with k_m -> 1 for each m. Hansen's Table 1 uses Bartlett weights (Original).
{cmd:parzen} uses Parzen weights with x = m/(B+1). {cmd:qs} uses quadratic spectral weights with
x = m/B over all lags, as in Andrews (1991). Both are Extended implementations.

{phang}
{opt splittest} regresses the squared OLS residuals on a constant and a dummy equal to 1 in the
second half of the sample (t > floor(T/2)). It reports the two half-sample error variances and the
HAC t-ratio of the dummy (Original: Hansen 1992, Table 1). Hansen describes this as a t-test of
the hypothesis that the regression error variance is the same in the two halves, computed with
Bartlett weights and a lag window of five.

{phang}
{opt splitlag(#)} sets that lag window; the default is 5.

{phang}
{opt level(#)} sets the confidence level and the level used for the star in the split test.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Step 1. OLS} of y_t on (x_t', 1). The residuals are w_t = y_t - b0 - x_t'b1.

{pstd}
{bf:Step 2. HAC covariance} (Hansen 1992, Theorem 3). Let xt~ = x_t - xbar and
M1 = T{c 94}-1 sum xt~ xt~'. Then

{p 8 8 2}
V1 = T{c 94}-1 sum_(m=-B..B) k_m sum_t xt~_(t+m) xt~_t' w_(t+m) w_t,{break}
W = T (R'b1 - r)' (R' M1{c 94}-1 V1 M1{c 94}-1 R){c 94}-1 (R'b1 - r) -> chi2(q).

{pstd}
Hence the variance of b1 is T{c 94}-1 M1{c 94}-1 V1 M1{c 94}-1. The command computes the full
sandwich (X'X){c 94}-1 G (X'X){c 94}-1 with a_t = X_t w_t, X_t = (x_t', 1)' and
G = sum_m k_m sum_t a_(t+m) a_t'. By the Frisch-Waugh-Lovell theorem its slope block equals
Hansen's expression exactly. No small-sample correction is applied, so e(V) equals the
{helpb newey} covariance times (T - K)/T, where K is the number of coefficients. {helpb test}
reports W as chi2 because no residual degrees of freedom are posted.

{pstd}
{bf:Step 3. Split-sample test} (Hansen 1992, Table 1). Regress w_t{c 94}2 on (1, D_t), where
D_t = 1(t > floor(T/2)). The intercept is the first-half variance, and intercept + slope is the
second-half variance. The t-ratio of the slope uses a Bartlett HAC covariance with lag
{cmd:splitlag()}. Its p-value is two-sided N(0,1).

{pstd}
{bf:Step -> equation map.} Model: eqs (1)-(4); consistency and intercept bias: Theorem 1;
mixed normality: Theorem 2 and eq. (8)-(10); HAC Wald and B = o(T{c 94}(1/4)): Theorem 3;
split-sample test: Table 1.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Intercept.} The pseudo-true intercept is b0 + Lambda_21, where Lambda_21 is the one-sided
long-run covariance between the scale shocks u_2t and the error shocks u_1t. Do not interpret
{cmd:_cons}, and do not test it.

{pstd}
{bf:Assumption 3.} Chi2 inference needs long-run independence of u_1t from (u_2t, u_3t). When
it fails, Hansen (Section 4) shows that the t-ratio has a non-normal limit. The distortion is
negligible when the scale process moves with the regressor (B2 = B3). It can be noticeable when
the scale is independent of x but u_1t is strongly correlated with x.

{pstd}
{bf:Logs.} In Hansen's examples the heteroskedasticity disappears when the regressions are run in
logs (Hansen 1992, footnote 5). Compare the split-sample test in levels and in logs before
concluding in favour of HCI.

{pstd}
{bf:Replication.} Hansen's Table 1 data (Campbell 1987; Shiller; Citibase) are not distributed
with this package. The published split tests are 2.77, 1.36, 4.00 and 3.80.


{marker examples}{...}
{title:Examples}

{pstd}Simulate an HCI model with b0 = 1, b1 = 2 and an I(1) error scale{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 1992}{p_end}
{phang2}{cmd:. set obs 400}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen x = sum(rnormal())}{p_end}
{phang2}{cmd:. gen sigma = 1 + sum(0.2*rnormal())}{p_end}
{phang2}{cmd:. gen y = 1 + 2*x + sigma*rnormal()}{p_end}

{pstd}OLS with HAC standard errors (default B) and the split-sample diagnostic{p_end}
{phang2}{cmd:. cointvol hetcoint y x, splittest}{p_end}

{pstd}HAC Wald test of b1 = 2 (chi2(1)){p_end}
{phang2}{cmd:. test x = 2}{p_end}

{pstd}Other kernels and bandwidths{p_end}
{phang2}{cmd:. cointvol hetcoint y x, bwidth(3) kernel(parzen)}{p_end}
{phang2}{cmd:. cointvol hetcoint y x, bwidth(2) kernel(qs)}{p_end}

{pstd}Residuals{p_end}
{phang2}{cmd:. predict what, residuals}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cointvol hetcoint} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(bwidth)}}bandwidth B{p_end}
{synopt:{cmd:e(chi2)}, {cmd:e(df_m)}, {cmd:e(p)}}HAC Wald test that all slopes are zero{p_end}
{synopt:{cmd:e(sigma2)}}mean squared residual{p_end}
{synopt:{cmd:e(split_s1)}, {cmd:e(split_s2)}}first- and second-half error variances
({cmd:splittest}){p_end}
{synopt:{cmd:e(split_t)}, {cmd:e(split_p)}}split-sample t-test and p-value{p_end}
{synopt:{cmd:e(split_lag)}}Bartlett lag of the split test{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}, {cmd:e(tdelta)}}sample time range and delta{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cointvol hetcoint}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}}variables{p_end}
{synopt:{cmd:e(kernel)}}kernel{p_end}
{synopt:{cmd:e(bwsource)}}how B was set{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcetype)}}{cmd:hac}, {cmd:HAC}{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(predict)}}{cmd:cointvol_stoch_p}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}OLS coefficients and HAC covariance{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Hansen, B. E. 1992. Heteroskedastic cointegration. {it:Journal of Econometrics} 54(1-3):
139-158. {browse "https://doi.org/10.1016/0304-4076(92)90103-X":doi:10.1016/0304-4076(92)90103-X}.

{phang}
Newey, W. K. and K. D. West. 1987. A simple, positive semi-definite, heteroskedasticity and
autocorrelation consistent covariance matrix. {it:Econometrica} 55(3): 703-708.
{browse "https://doi.org/10.2307/1913610":doi:10.2307/1913610}.

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix
estimation. {it:Econometrica} 59(3): 817-858.
{browse "https://doi.org/10.2307/2938229":doi:10.2307/2938229}.

{phang}
Harris, D., B. McCabe and S. Leybourne. 2002. Stochastic cointegration: estimation and
inference. {it:Journal of Econometrics} 111(2): 363-384.
{browse "https://doi.org/10.1016/S0304-4076(02)00111-2":doi:10.1016/S0304-4076(02)00111-2}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite Hansen (1992) and the {cmd:cointvol} package.

{title:Also see}

{psee}
{helpb cointvol}, {helpb cointvol_stoch:cointvol stoch}, {helpb cointvol_rank:cointvol rank},
{helpb newey}
{p_end}
