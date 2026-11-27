{smcl}
{* *! version 1.0.0 24Nov2026}{...}
{title:Title}

{phang}
{bf:qregark} {hline 2} Quantile regression with AR(k) errors, by Prais-Winsten or Cochrane-Orcutt estimation


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:qregark}
{depvar}
[{indepvars}]
{ifin}
{cmd:,} {opt lag(#)} [{it:options}]



{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt lag(#)}}set the order of the AR(k) error process{p_end}
{synopt:{opt q:uantile(#)}}estimate {it:#} quantile; default is {cmd:quantile(.5)}{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt corc}}conditional (Cochrane-Orcutt-type) estimator of
{help qregark##T2018:Tian et al. (2018)}; default is Prais-Winsten-type{p_end}
{synopt:{opt bias:correct}}correct the small-sample bias of the AR coefficients{p_end}

{syntab:SE}
{synopt:{opt vce(vcetype)}}{it:vcetype} may be {cmd:iid} (the default) or
{cmd:bootstrap}[{cmd:,} {opt r:eps(#)} {opt seed(#)}]{p_end}
{synopt:{opt bw:idth(bwidth)}}bandwidth for the sparsity estimate: {cmd:hsheather} (the default), {cmd:bofinger}, or {cmd:chamberlain}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt nol:og}}suppress the iteration log{p_end}
{synopt:{it:{help qregark##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Convergence}
{synopt:{opt start(ols|median)}}starting values; default is {cmd:start(ols)}{p_end}
{synopt:{opt from(matrix)}}user-supplied starting values{p_end}
{synopt:{opt tol:erance(#)}}convergence criterion; default is {cmd:tolerance(1e-8)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations per stage; default is {cmd:iterate(10000)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt lag(#)} is required.{p_end}
{p 4 6 2}
You must {cmd:tsset} or {cmd:xtset} your data before using {cmd:qregark}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables and time-series operators, including
within interactions; see {help fvvarlist} and {help tsvarlist}.{p_end}
{p 4 6 2}
{opt biascorrect} may not be combined with {cmd:vce(bootstrap)}.{p_end}
{p 4 6 2}
Typing {cmd:qregark} without arguments replays the last estimation results.{p_end}



{marker postestimation}{...}
{title:Postestimation syntax}

{p 8 17 2}
{cmdab:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}linear prediction x'b, {bf:without} the AR adjustment; the default{p_end}
{synopt:{opt q:uantile}}one-step-ahead conditional quantile of {it:depvar}, x_t'b + sum_j rho_j ({it:depvar}_t-j - x_t-j'b){p_end}
{synopt:{opt r:esiduals}}residuals, {it:depvar} - {opt xb}{p_end}
{synopt:{opt i:nnovations}}innovations, {it:depvar} - {opt quantile}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{opt xb} and {opt residuals} are available both in and out of sample. {opt quantile}
and {opt innovations} require lagged values and are computed only where the full
AR({it:k}) history is available within a contiguous time segment. The innovations
should show no remaining autocorrelation if {opt lag()} is adequate; examine them
with {helpb ac}, adding {cmd:if e(sample)}.

{pstd}
{cmd:_cons} is the baseline level of the {it:tau}th quantile; {opt xb} and {opt residuals} use it,
whereas {opt quantile} and {opt innovations} use the structural intercept
{cmd:e(b0_struct)}, so that the one-step quantile is that of the fitted AR model.

{pstd}
{cmd:lincom}, {cmd:nlcom}, {cmd:test}, and {cmd:predictnl} use {cmd:e(V)}.



{marker description}{...}
{title:Description}

{pstd}
{cmd:qregark} fits a linear quantile regression model with autoregressive errors of
order {it:k}. The regression coefficients b and the AR coefficients rho_1,...,rho_k 
are estimated jointly by minimizing the quantile check function. {cmd:qregark} extends 
{helpb qreg} to AR({it:k}) errors in the same way that {helpb prais} extends {helpb regress}.
By default, {cmd:qregark} uses a Prais-Winsten-type estimator, which also uses the
first {it:k} observations of each time segment, transformed by the stationary
covariance of the errors ({help qregark##PW1954:Prais and Winsten 1954};
{help qregark##V2021:Vougas 2021}; {help qregark##DR1994:Dielman and Rose 1994}).
With option {opt corc}, {cmd:qregark} uses the conditional (Cochrane-Orcutt-type)
estimator of {help qregark##T2018:Tian et al. (2018)}, which conditions on the first
{it:k} observations of each segment.{p_end}



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lag(#)} specifies the order of the AR(k) error process and must be a positive
integer; {cmd:lag()} is required.

{phang}
{opt quantile(#)} specifies the quantile to be estimated and should be a number
between 0 and 1, exclusive. Numbers larger than 1 are interpreted as percentages.
The default value of 0.5 corresponds to the median.

{phang}
{opt noconstant} suppresses the constant term.

{phang}
{opt corc} requests the conditional (Cochrane-Orcutt-type) estimator of
{help qregark##T2018:Tian et al. (2018)}. The default Prais-Winsten-type estimator
estimates the level and trends of trending series considerably more precisely when
the errors are persistent.

{phang}
{opt biascorrect} corrects the AR coefficients for their small-sample bias,
re-estimates b with the corrected AR coefficients held fixed, adjusts the variance
matrix for the correction, and adjusts {cmd:_cons} for small-sample bias.

{dlgtab:SE}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported.

{phang2}
{cmd:vce(iid)}, the default, uses tau(1-tau) s^2 (G'G)^-1, where {it:G} holds the
derivatives of the transformed observations with respect to b and rho and s is the
sparsity, estimated as in {cmd:qreg, vce(iid, residual)}. For the default
estimator this is a working approximation.

{phang2}
{cmd:vce(bootstrap} [{cmd:,} {opt reps(#)} {opt seed(#)}]{cmd:)} uses the residual
bootstrap, holding the initial errors of each segment fixed. The default is
{cmd:reps(500)}. Percentile confidence intervals are stored in
{cmd:e(ci_percentile)}.

{phang}
{opt bwidth(bwidth)} specifies the bandwidth method for the sparsity estimate:
{cmd:hsheather} (the default), {cmd:bofinger}, or {cmd:chamberlain}; see
{help qreg##qreg_bwidth:qreg}. At extreme quantiles in short series (for example,
{it:tau} = .9 with fewer than about 50 observations) the sparsity cannot be
estimated; use a quantile closer to the median or {cmd:vce(bootstrap)}.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.

{phang}
{opt nolog} suppresses the iteration log and the bootstrap replication dots.

{marker display_options}{...}
INCLUDE help displayopts_list

{dlgtab:Convergence}

{phang}
{opt start(ols|median)} specifies the starting values: least-squares (the default)
or median regression estimates of b, with rho from an AR(k) regression of the
residuals.

{phang}
{opt from(matrix)} supplies starting values, in the order of {cmd:e(b)}; for
example, {cmd:from(e(b))} from a previous {cmd:qregark} fit.

{phang}
{opt tolerance(#)} specifies the convergence criterion for the maximum relative
change in the parameters. The default is {cmd:tolerance(1e-8)}.

{phang}
{opt iterate(#)} specifies the maximum number of iterations in each stage of the
algorithm. The default is {cmd:iterate(10000)}.



{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. gen _t = qtr - tq(1960q1)}{p_end}
{phang2}{cmd:. gen _x = qtr >= tq(1971q1)}{p_end}
{phang2}{cmd:. gen _x_t = _x * (qtr - tq(1971q1))}{p_end}

{pstd}Median regression with AR(4) errors (quarterly data), Prais-Winsten-type{p_end}
{phang2}{cmd:. qregark ln_consump _t _x _x_t, lag(4)}{p_end}

{pstd}Same model, conditional estimator of Tian et al. (2018){p_end}
{phang2}{cmd:. qregark ln_consump _t _x _x_t, lag(4) corc}{p_end}

{pstd}Check the innovations for remaining autocorrelation{p_end}
{phang2}{cmd:. qregark ln_consump _t _x _x_t, lag(4)}{p_end}
{phang2}{cmd:. predict eta, innovations}{p_end}
{phang2}{cmd:. ac eta if e(sample), lags(12)}{p_end}

{pstd}Post-intervention trend of the median{p_end}
{phang2}{cmd:. lincom _t + _x_t}{p_end}

{pstd}Predicted pre- and post-intervention trend lines of the median, with 95% confidence intervals{p_end}
{phang2}{cmd:. predictnl double fit = predict(xb), ci(lb ub)}{p_end}
{phang2}{cmd:. twoway (rarea lb ub qtr if _x == 0, color(gs13)) (rarea lb ub qtr if _x == 1, color(gs13))}{p_end}
{phang3}{cmd:(scatter ln_consump qtr, msize(small) mcolor(gs8)) (line fit qtr if _x == 0, lcolor(navy))}{p_end}
{phang3}{cmd:(line fit qtr if _x == 1, lcolor(navy)), xline(`=tq(1971q1)', lpattern(dash)) legend(off)}{p_end}
{phang3}{cmd:ytitle("ln_consump") xtitle("Quarter")}{p_end}

{pstd}0.9 quantile, residual bootstrap{p_end}
{phang2}{cmd:. qregark ln_consump _t _x _x_t, lag(4) quantile(.9) vce(bootstrap, reps(500) seed(1234))}{p_end}
{phang2}{cmd:. matrix list e(ci_percentile)}{p_end}

{pstd}Bias correction in a short ITSA series (48 months, intervention at month 25){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2026}{p_end}
{phang2}{cmd:. set obs 148}{p_end}
{phang2}{cmd:. gen double e = rnormal()}{p_end}
{phang2}{cmd:. replace e = .6*e[_n-1] + e in 2/l}{p_end}
{phang2}{cmd:. keep in 101/148}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen _t = t - 1}{p_end}
{phang2}{cmd:. gen _x = t >= 25}{p_end}
{phang2}{cmd:. gen _x_t = _x*(t - 25)}{p_end}
{phang2}{cmd:. gen double y = 50 + .5*_t - 4*_x - .3*_x_t + 2*e}{p_end}
{phang2}{cmd:. qregark y _t _x _x_t, lag(1)}{p_end}
{phang2}{cmd:. qregark y _t _x _x_t, lag(1) biascorrect}{p_end}
{phang2}{cmd:. matrix list e(rho_uncorrected)}{p_end}
{phang2}{cmd:. qregark y _t _x _x_t, lag(1) quantile(.25) biascorrect}{p_end}

{pstd}Panel data with panel fixed effects{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. qregark invest mvalue kstock i.company, lag(1) quantile(.75)}{p_end}



{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:qregark} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (with {opt corc}, excludes the first
{it:k} observations of each segment){p_end}
{synopt:{cmd:e(q)}}quantile requested{p_end}
{synopt:{cmd:e(p_lag)}}order of the AR process fitted{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared statistic for the non-constant regression coefficients{p_end}
{synopt:{cmd:e(p)}}p-value for Wald chi-squared{p_end}
{synopt:{cmd:e(ll)}}asymmetric Laplace working criterion (log likelihood for {opt corc}){p_end}
{synopt:{cmd:e(sigma)}}asymmetric Laplace scale{p_end}
{synopt:{cmd:e(sum_adev)}}sum of check-function deviations{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(N_seg)}}number of segments{p_end}
{synopt:{cmd:e(ngaps)}}number of gaps in sample (includes panel changes){p_end}
{synopt:{cmd:e(iterations)}}total number of EM iterations{p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance used{p_end}
{synopt:{cmd:e(stationary)}}1 if all eigenvalues of the AR companion matrix lie inside the unit circle, 0 otherwise{p_end}
{synopt:{cmd:e(at_limit)}}1 if the largest modulus of the eigenvalues of the AR companion matrix (uncorrected) is at the limit of .995, 0 otherwise{p_end}
{synopt:{cmd:e(sparsity)}}sparsity estimate ({cmd:vce(iid)}){p_end}
{synopt:{cmd:e(bwidth)}}bandwidth of the sparsity estimate ({cmd:vce(iid)}){p_end}
{synopt:{cmd:e(N_reps)}}number of bootstrap replications ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(N_misreps)}}number of replications that did not converge ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(biascorrect)}}1 if {opt biascorrect} was specified, 0 otherwise{p_end}
{synopt:{cmd:e(b0_struct)}}structural intercept (with a constant){p_end}
{synopt:{cmd:e(b0_unadjusted)}}baseline level before the small-sample adjustment ({opt biascorrect}){p_end}
{synopt:{cmd:e(sum_rho)}}sum of the bias-corrected AR coefficients ({opt biascorrect}){p_end}
{synopt:{cmd:e(phi_bound)}}calibration bound for the sum of the AR coefficients ({opt biascorrect}){p_end}
{synopt:{cmd:e(capped)}}1 if the calibration bound or stationarity limit was reached, or no correction was made, 0 otherwise ({opt biascorrect}){p_end}
{synopt:{cmd:e(ac_res}{it:#}{cmd:)}}autocorrelation of the residuals at lag {it:#}{p_end}
{synopt:{cmd:e(ac_inn}{it:#}{cmd:)}}autocorrelation of the innovations at lag {it:#}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qregark}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(method)}}{cmd:pw} or {cmd:corc}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable (if panel data){p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant}, if specified{p_end}
{synopt:{cmd:e(start)}}{cmd:ols}, {cmd:median}, or {cmd:from}{p_end}
{synopt:{cmd:e(vce)}}{cmd:iid} or {cmd:bootstrap}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Bootstrap} ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(bwmethod)}}bandwidth method of the sparsity estimate{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}{cmd:qregark_p}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector, with two equation blocks: the regression
(named after {it:depvar}) and {cmd:ar} (rho_1,...,rho_k){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(rho_uncorrected)}}AR coefficients before the bias correction ({opt biascorrect}){p_end}
{synopt:{cmd:e(ci_percentile)}}bootstrap percentile confidence intervals ({cmd:vce(bootstrap)}){p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{marker flags}{...}
{title:Stored flags}

{pstd}
The following conditions are reported through stored results rather than warnings.

{phang2}o {cmd:e(capped)} = 1 ({opt biascorrect}): in the simulations, the intervals
for the level and trends of capped fits were usually much wider than needed, and
those of uncapped fits in very short, persistent series were too narrow.{p_end}

{phang2}o {cmd:e(at_limit)} = 1: the fitted persistence has reached the imposed
boundary (largest modulus of the eigenvalues of the AR companion matrix, .995). This
is not a unit-root test, but ordinary inference is unreliable there: the standard
errors of the AR coefficients are not valid, and the level terms and trends are
imprecisely estimated. It happens mainly with long series or pooled panels.
Reconsider the specification, for example whether the mean structure omits a trend
or level shift, or whether a model in first differences is more appropriate.{p_end}



{marker references}{...}
{title:References}

{marker DR1994}{...}
{phang}
Dielman, T. E., and E. L. Rose. 1994. Estimation in least absolute value regression
with autocorrelated errors. {it:Journal of Statistical Computation and Simulation}
50: 29-43.

{marker GMR1993}{...}
{phang}
Gouri{c e'}roux, C., A. Monfort, and E. Renault. 1993. Indirect inference.
{it:Journal of Applied Econometrics} 8: S85-S118.

{marker MS1998}{...}
{phang}
MacKinnon, J. G., and A. A. Smith, Jr. 1998. Approximate bias correction in
econometrics. {it:Journal of Econometrics} 85: 205-230.

{marker PW1954}{...}
{phang}
Prais, S. J., and C. B. Winsten. 1954. Trend estimators and serial correlation.
Cowles Commission Discussion Paper: Statistics No. 383. Chicago: Cowles Commission.

{marker T2018}{...}
{phang}
Tian, Y., M. Tang, Y. Zang, and M. Tian. 2018. Quantile regression for linear
models with autoregressive errors using EM algorithm. {it:Computational Statistics}
33: 1605-1625.

{marker V2021}{...}
{phang}
Vougas, D. V. 2021. Prais-Winsten algorithm for regression with second or higher
order autoregressive errors. {it:Econometrics} 9: 32.


{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


{title:Citation of {cmd:qregark}}

{p 4 8 2}{cmd:qregark} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. 2026. QREGARK: Stata module for quantile regression with AR(k) errors, by Prais-Winsten or Cochrane-Orcutt estimation.
Statistical Software Components S460048, Boston College Department of Economics.{p_end}


{title:Also see}

{psee}
Online: {helpb qreg}, {helpb prais}, {helpb qreg_hac} (if installed), {helpb itsa} (if installed),
{helpb praisk} (if installed), {helpb betark} (if installed),
{helpb xtpraisk} (if installed), {helpb xtbetark} (if installed){p_end}
