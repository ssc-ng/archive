{smcl}
{* *! version 1.2.0  15nov2026}{...}
{vieweralsosee "xtpmed" "help xtpmed"}{...}
{vieweralsosee "cspmed" "help cspmed"}{...}
{title:Title}

{phang}
{bf:tspmed} {hline 2} Causal mediation analysis for time series with one or more
mediators: OLS-HAC, ARDL, FMOLS, DOLS and DML, joint HAC inference and residual diagnostics


{title:Syntax}

{p 8 17 2}
{cmd:tspmed} {depvar} {ifin}{cmd:,}
{opth treat:ment(varname)} {opth med:iators(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opth treat:ment(varname)}}treatment{p_end}
{p2coldent:* {opth med:iators(varlist)}}one or more parallel mediators{p_end}
{synopt:{opth cont:rols(varlist)}}controls (confounders){p_end}
{synopt:{opt est:imator(name)}}{cmd:ols} (default), {cmd:ardl}, {cmd:fmols}, {cmd:dols}, {cmd:dml}{p_end}
{synopt:{opt tr:end}}include a linear trend ({cmd:ols}, {cmd:ardl}, {cmd:fmols}, {cmd:dols}){p_end}

{syntab:Inference}
{synopt:{opt vce(qs|hac|robust)}}prewhitened quadratic-spectral kernel with Andrews bandwidth (default), Newey-West, or White{p_end}
{synopt:{opt hacl:ag(#)}}Newey-West lag for {cmd:vce(hac)}; default floor(4(T/100)^(2/9)){p_end}
{synopt:{opt fmbw(#)}}fixed FMOLS bandwidth; default Andrews (1991) automatic{p_end}
{synopt:{opt noprew:hite}}FMOLS long-run variance without VAR(1) prewhitening{p_end}
{synopt:{opt boot:strap(#)}}bootstrap replications for the effects{p_end}
{synopt:{opt bm:ethod(block|sieve)}}moving-block percentile (default for ols, ardl, dml) or sieve (VAR) bootstrap-t (default for fmols, dols){p_end}
{synopt:{opt block:len(#)}}block length; default round(T^(1/3)){p_end}
{synopt:{opt simr:eps(#)}}replications for simulated critical values and p-values; default 999{p_end}

{syntab:Estimator settings}
{synopt:{opt ardl:lags(p q)}}fixed ARDL lags; default: select by {opt ic()} up to {opt maxp()}, {opt maxq()}{p_end}
{synopt:{opt maxp(#)}, {opt maxq(#)}}maximum lags for selection; defaults 4 and 4{p_end}
{synopt:{opt ic(aic|bic)}}lag-selection criterion{p_end}
{synopt:{opt lead:s(#)}, {opt dlag:s(#)}}DOLS leads and lags of differences; defaults 1 and 1{p_end}
{synopt:{opt poly(#)}, {opt fold:s(#)}, {opt ridge(#)}, {opt gap(#)}}DML series degree, blocks, ridge penalty and buffer between blocks{p_end}

{syntab:Effects and diagnostics}
{synopt:{opt d1(#)}, {opt d0(#)}}treatment contrast; defaults 1 and 0{p_end}
{synopt:{opt bgl:ags(#)}}lags for Breusch-Godfrey and Ljung-Box; default 4{p_end}
{synopt:{opt archl:ags(#)}}lags for the ARCH test; default 2{p_end}
{synopt:{opt break(#)}}last pre-break period for the Chow test; default mid-sample{p_end}
{synopt:{opt nodiag}}skip diagnostics{p_end}
{synopt:{opt seed(#)}}random-number seed (bootstrap){p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* required. The data must be {helpb tsset}. Gaps in the time variable are treated as missing periods.{p_end}


{title:Description}

{pstd}
{cmd:tspmed} estimates one outcome equation and one equation per mediator,

{p 8 8 2}M_j = a_j D + controls + e_j,   Y = c D + b_1 M_1 + ... + b_k M_k + controls + e_Y,{p_end}

{pstd}
and reports NDE = c(d1-d0), NIE_j = a_j b_j (d1-d0), NIE, TE and the proportion
mediated.  Every estimator is written as a sum of per-period influence
contributions; stacking them across equations and applying Newey-West weights gives
the joint covariance used for the indirect effects.

{p2colset 6 16 18 2}{...}
{p2col:{cmd:ols}}static regression; coefficients are contemporaneous effects.{p_end}
{p2col:{cmd:ardl}}ARDL(p,q) for each equation; effects use long-run coefficients
(sum of distributed-lag coefficients divided by one minus the sum of autoregressive
coefficients); {cmd:ec} is the speed of adjustment.  Bounds-test F and t statistics
(Pesaran, Shin and Smith 2001) are reported.  A second table gives the short-run
coefficients of each equation in error-correction form: {cmd:ec}, {cmd:D.}x, {cmd:LD.}x,
..., {cmd:L}(q-1){cmd:D.}x for every regressor, {cmd:LD.}y, ..., {cmd:L}(p-1){cmd:D.}y,
{cmd:_cons} (and {cmd:trend}).  They are an exact reparameterization of the estimated
levels ARDL, and their standard errors use the same long-run variance estimator as the
long-run coefficients (the {opt vce()} choice); stored in {cmd:e(sr)}.{p_end}
{p2col:{cmd:fmols}}fully modified OLS (Phillips and Hansen 1990) for I(1) variables.{p_end}
{p2col:{cmd:dols}}dynamic OLS (Saikkonen 1991; Stock and Watson 1993) with leads and lags of differences.{p_end}
{p2col:{cmd:dml}}partially linear model; treatment, mediators and outcome are
residualized on a polynomial series in the controls with blocked cross-fitting
(blocks separated by {opt gap()} periods), then regressed on each other.{p_end}
{p2colreset}{...}


{title:Inference}

{pstd}
The default long-run variance is the quadratic-spectral kernel with the Andrews (1991)
automatic bandwidth after VAR(1) prewhitening (Andrews and Monahan 1992).  FMOLS uses the
same kernel for its endogeneity and serial-correlation corrections and a mixed-normal
covariance across equations, V_ij = A_i (Z_i'Z_j) A_j omega_ij, where omega is the
long-run covariance of the equations' u+ errors.  {opt bmethod(sieve)} fits a VAR to the
long-run residuals and the differences of the I(1) regressors, rebuilds the cointegrated
system from resampled innovations (Chang, Park and Song 2006) and reports bootstrap-t
confidence intervals and p-values for the effects.


{title:Diagnostics}

{pstd}
For each equation: Breusch-Godfrey LM, Ljung-Box Q, Durbin-Watson; Koenker-Breusch-Pagan,
White and ARCH LM; Jarque-Bera, skewness and kurtosis; Ramsey RESET; CUSUM (ratio of the
largest recursive-residual cumulative sum to the Brown-Durbin-Evans line) and CUSUMSQ
(largest deviation from the expected path); Chow breakpoint test.  {cmd:ardl} adds the
selected lags and the Pesaran-Shin-Smith bounds F and t statistics; {cmd:fmols} and
{cmd:dols} add the Engle-Granger ADF t statistic on the residuals.

{pstd}
CUSUM, CUSUMSQ, bounds and Engle-Granger critical values and p-values are simulated under
the null for the actual sample size, number of regressors, deterministic terms and lag
structure: recursive residuals are independent normal under the null; for the bounds
test the dependent variable is a random walk with all regressors either I(0) (lower bound)
or I(1) (upper bound), and the unrestricted error-correction regression is re-estimated
with the selected lags; for the Engle-Granger test all variables are independent random
walks and the residual ADF lag is chosen by AIC as in the estimation sample.  The bounds
decision is "level relationship" if the I(1) p-value is below 0.05, "inconclusive" if only
the I(0) p-value is, and "no level relationship" otherwise.


{title:Remarks}

{pstd}
Mediation effects are causal under sequential ignorability: no unmeasured
treatment-outcome, treatment-mediator or mediator-outcome confounding given the
controls (and the dynamics).  Long-run variances need long series.  In simulations
with T = 200-400 the default prewhitened QS variance gave 95% interval coverage of
0.89-0.95 for FMOLS and DOLS (0.80-0.88 with a fixed-lag Newey-West variance).


{title:Examples}

{pstd}The dataset is installed with the package ({cmd:net get tspmed}); it is simulated
with AR(1) errors and known effects (NDE = 1.5, NIE = 0.5 via m1 0.8 and m2 -0.3).
The example do-file {cmd:tspmed_example.do} also illustrates {cmd:fmols} and {cmd:dols}
with simulated cointegrated series and {cmd:dml} with nonlinear confounding.{p_end}

{phang2}{cmd:. use mediation_ts, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tspmed y, treatment(d) mediators(m1 m2) controls(x)}{p_end}
{phang2}{cmd:. tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(ardl) ic(bic)}{p_end}
{phang2}{cmd:. matrix list e(sr)}{p_end}
{phang2}{cmd:. tspmed y, treatment(d) mediators(m1 m2) controls(x) vce(hac) haclag(4) nodiag}{p_end}
{phang2}{cmd:. tspmed y, treatment(d) mediators(m1 m2) controls(x) bootstrap(499) seed(1) nodiag}{p_end}


{title:Stored results}

{pstd}
{cmd:e(b)}, {cmd:e(V)} (coefficients of all equations and their joint HAC variance),
{cmd:e(effects)} (b, se, z, p, ll, ul), {cmd:e(V_eff)}, {cmd:e(sr)} (short-run
coefficients of {cmd:ardl}: b, se, z, p, ll, ul), {cmd:e(diag)} (17 tests by
stat, df1, df2, p for each equation), {cmd:e(eff_boot)}; scalars {cmd:e(N)},
{cmd:e(T)}, {cmd:e(km)}, {cmd:e(haclag)}, {cmd:e(break_t)}; macros
{cmd:e(estimator)}, {cmd:e(treatment)}, {cmd:e(mediators)}, {cmd:e(controls)}.


{title:References}

{phang}Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix estimation. {it:Econometrica} 59: 817-858.{p_end}
{phang}Andrews, D. W. K., and J. C. Monahan. 1992. An improved heteroskedasticity and autocorrelation consistent covariance matrix estimator. {it:Econometrica} 60: 953-966.{p_end}
{phang}Brown, R. L., J. Durbin, and J. M. Evans. 1975. Techniques for testing the constancy of regression relationships over time. {it:Journal of the Royal Statistical Society B} 37: 149-192.{p_end}
{phang}Chang, Y., J. Y. Park, and K. Song. 2006. Bootstrapping cointegrating regressions. {it:Journal of Econometrics} 133: 703-739.{p_end}
{phang}Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey, and J. Robins. 2018. Double/debiased machine learning for treatment and structural parameters. {it:Econometrics Journal} 21: C1-C68.{p_end}
{phang}Engle, R. F., and C. W. J. Granger. 1987. Co-integration and error correction: representation, estimation, and testing. {it:Econometrica} 55: 251-276.{p_end}
{phang}Newey, W. K., and K. D. West. 1987. A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. {it:Econometrica} 55: 703-708.{p_end}
{phang}Pesaran, M. H., Y. Shin, and R. J. Smith. 2001. Bounds testing approaches to the analysis of level relationships. {it:Journal of Applied Econometrics} 16: 289-326.{p_end}
{phang}Phillips, P. C. B., and B. E. Hansen. 1990. Statistical inference in instrumental variables regression with I(1) processes. {it:Review of Economic Studies} 57: 99-125.{p_end}
{phang}Stock, J. H., and M. W. Watson. 1993. A simple estimator of cointegrating vectors in higher order integrated systems. {it:Econometrica} 61: 783-820.{p_end}


{title:Author}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria{p_end}
