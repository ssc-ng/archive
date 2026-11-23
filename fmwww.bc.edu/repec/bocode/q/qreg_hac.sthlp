{smcl}
{* *! version 1.0.0  18nov2026}{...}
{p2colset 1 14 15 2}{...}
{p2col:{bf:qreg_hac} {hline 2}}Quantile regression with heteroskedasticity- and autocorrelation-consistent (HAC) standard errors{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:qreg_hac} {depvar} [{indepvars}] {ifin} [{it:{help qreg_hac##weight:weight}}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt q:uantile(#)}}estimate {it:#} quantile; default is {cmd:quantile(.5)}{p_end}

{syntab:HAC}
{synopt :{opt lag(#|auto)}}HAC lag order; default is {cmd:lag(auto)}{p_end}
{synopt :{opt ker:nel(kernel)}}HAC kernel: {cmd:qs}, {cmd:bartlett}, or {cmd:parzen}; default is {cmd:qs} with {cmd:lag(auto)} and {cmd:bartlett} with {cmd:lag(}{it:#}{cmd:)}{p_end}
{synopt :{opt phi(bc|sample)}}estimator of the score autocorrelation used by {cmd:lag(auto)}; default is {cmd:phi(bc)}{p_end}
{synopt :{opt den:sity(fitted|kernel)}}density estimator; default is {cmd:density(fitted)}{p_end}
{synopt :{opt bw:idth(bwidth)}}bandwidth for the density estimator: {cmd:hsheather} (the default), {cmd:bofinger}, or {cmd:chamberlain}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{it:{help qreg_hac##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Optimization}
{synopt :{it:{help qreg_hac##optimize:optimization_options}}}control the
optimization process; seldom used{p_end}
{synopt :{opt wls:iter(#)}}attempt {it:#} weighted least-squares iterations before doing linear programming iterations{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:tsset} or {cmd:xtset} your data before using {cmd:qreg_hac}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables and time-series operators, including
within interactions; see {help fvvarlist} and {help tsvarlist}.{p_end}
{marker weight}{...}
{p 4 6 2}
{cmd:iweight}s and {cmd:pweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2}
See {manhelp qreg_postestimation R:qreg postestimation} for features available after estimation.{p_end}


{marker postestimation}{...}
{title:Postestimation syntax}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {opt xb} | {opt stdp} | {opt r:esiduals}]

{pstd}
{opt xb}, the default, calculates the linear prediction; {opt stdp} calculates
its standard error; {opt residuals} calculates {it:depvar} - {opt xb}.
{opt stdp}, {cmd:lincom}, {cmd:nlcom}, {cmd:test}, and {cmd:margins} all use the
HAC variance-covariance matrix in {cmd:e(V)}.

{pstd}
HAC standard errors account for autocorrelation without removing it: the
coefficients and residuals are identical to those of {helpb qreg}, so the
residuals remain autocorrelated.


{marker description}{...}
{title:Description}

{pstd}
{cmd:qreg_hac} fits quantile regression models to time-series and panel data and
reports standard errors that are robust to heteroskedasticity and
autocorrelation (HAC). The coefficients are identical to those of {helpb qreg};
the variance-covariance matrix is the sandwich estimator of
{help qreg_hac##GY2024:Galvao and Yoon (2024)},
{it:D}^-1 {it:J} {it:D}^-1, where {it:D} is estimated from the conditional
density of the errors and {it:J} is a kernel-weighted (HAC) estimate of the
long-run variance of the quantile scores.



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt quantile(#)} specifies the quantile to be estimated and should be a number
between 0 and 1, exclusive. Numbers larger than 1 are interpreted as
percentages. The default value of 0.5 corresponds to the median.

{dlgtab:HAC}

{phang}
{opt lag(#|auto)} specifies the HAC lag order. {cmd:lag(}{it:#}{cmd:)} sets the
kernel bandwidth to {it:#}+1, so that with the default Bartlett kernel the
weights are those of {helpb newey} with {cmd:lag(}{it:#}{cmd:)}; {it:#} must be
smaller than the length of the shortest segment. If {cmd:kernel(qs)} is
specified with {cmd:lag(}{it:#}{cmd:)}, every lag receives some weight, so
{cmd:lag(0)} does not remove the autocorrelation correction. {cmd:lag(auto)}, the
default, selects the bandwidth with the plug-in rule of
{help qreg_hac##A1991:Andrews (1991)} as adapted by
{help qreg_hac##GY2024:Galvao and Yoon (2024)}; see
{it:{help qreg_hac##remarks:Remarks}}.

{phang}
{opt kernel(kernel)} specifies the HAC kernel: {cmd:qs} (quadratic spectral),
{cmd:bartlett}, or {cmd:parzen}. The default is {cmd:qs} when the bandwidth is
selected automatically and {cmd:bartlett} when {cmd:lag(}{it:#}{cmd:)} is
specified, so that {cmd:lag(}{it:#}{cmd:)} gives the weights of {helpb newey}.

{phang}
{opt phi(bc|sample)} specifies how the autocorrelation of the quantile scores is
estimated for {cmd:lag(auto)}. {cmd:phi(bc)}, the default, uses the
bias-corrected estimator of {help qreg_hac##GY2024:Galvao and Yoon (2024)},
which they recommend for samples of about 100 or fewer. {cmd:phi(sample)} uses
the sample autocorrelation of each score. {opt phi()} is ignored when
{cmd:lag(}{it:#}{cmd:)} is specified.

{phang}
{opt density(fitted|kernel)} specifies the estimator of the error density in
{it:D}. {cmd:density(fitted)}, the default, uses the difference quotient of
fitted quantiles, as in {cmd:qreg, vce(robust)};
{cmd:density(kernel)} uses the Powell kernel estimator with an Epanechnikov
kernel, as in {cmd:qreg, vce(robust, kernel)}.

{phang}
{opt bwidth(bwidth)} specifies the bandwidth method used by the density
estimator: {cmd:hsheather} (Hall-Sheather, the default), {cmd:bofinger}, or
{cmd:chamberlain}; see {help qreg##qreg_bwidth:qreg}.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.

{marker display_options}{...}
INCLUDE help displayopts_list

{marker optimize}{...}
{dlgtab:Optimization}

{phang}
{it:optimization_options}: {opt iter:ate(#)}, [{cmd:no}]{opt log},
{opt tr:ace}; see {help qreg##qreg_optimize:qreg}.

{phang}
{opt wlsiter(#)} specifies the number of weighted least-squares iterations that
will be attempted before the linear programming iterations are started. The
default is {cmd:wlsiter(1)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
The quantile score of observation {it:t} is
{it:z_t} = {it:w_t} ({it:tau} - 1[{it:e_t} < 0]) {it:x_t}, where {it:e_t} is the
residual and {it:w_t} the weight. Residuals that are zero up to numerical
precision (the observations defining the linear programming solution) are
treated as exactly zero, so the results do not depend on rounding error.
{it:J} is the kernel-weighted sum of the score autocovariances,
{it:k}({it:j}/{it:S}), within segments, where {it:S} is the bandwidth.

{pstd}
{cmd:lag(auto)} follows the AR(1) plug-in rule of
{help qreg_hac##A1991:Andrews (1991)} applied to each column of the scores, as
in the replication code of {help qreg_hac##GY2024:Galvao and Yoon (2024)}; the
bandwidth is rounded to an integer. {cmd:qreg_hac} extends the rule to panels
and gaps in two ways: {it:T} in the rule is the mean segment length (the number
of observations divided by the number of segments) rather than the number of
observations, and the autocorrelations are pooled over segments. For
{cmd:phi(bc)}, the autocorrelation of each regressor is computed without
centering, which equals one for the constant and is close to one for the
deterministic trend and step terms of interrupted time-series designs.

{pstd}
In quantile regression, consistency of the HAC estimator requires the
bandwidth to grow more slowly than the square root of {it:T}
({help qreg_hac##GY2024:Galvao and Yoon 2024}); {cmd:qreg_hac} displays a note
when {cmd:lag(}{it:#}{cmd:)} exceeds this.

{pstd}
Fixed effects may be included as factor variables, for example, {cmd:i.}{it:panelvar}.
With short panels, quantile regression with fixed effects is subject to
incidental-parameter bias ({help qreg_hac##K2004:Koenker 2004}).


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}

{pstd}Median regression with HAC standard errors, automatic bandwidth{p_end}
{phang2}{cmd:. qreg_hac dln_consump dln_inc L.dln_consump}{p_end}

{pstd}0.25 quantile, Newey-West (Bartlett) weights with 4 lags{p_end}
{phang2}{cmd:. qreg_hac dln_consump dln_inc L.dln_consump, quantile(.25) lag(4)}{p_end}

{pstd}Panel data{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. qreg_hac invest mvalue kstock, quantile(.75)}{p_end}

{pstd}Panel data with panel fixed effects{p_end}
{phang2}{cmd:. qreg_hac invest mvalue kstock i.company, quantile(.75)}{p_end}

{pstd}Interrupted time series: intervention in 1971q1{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. gen _t = qtr - tq(1960q1)}{p_end}
{phang2}{cmd:. gen _x = qtr >= tq(1971q1)}{p_end}
{phang2}{cmd:. gen _x_t = _x * (qtr - tq(1971q1))}{p_end}
{phang2}{cmd:. qreg_hac ln_consump _t _x _x_t}{p_end}

{pstd}Post-intervention trend of the median, with HAC confidence interval{p_end}
{phang2}{cmd:. lincom _t + _x_t}{p_end}

{pstd}Intervention effect on the median in 1975q1 (16 quarters after the intervention){p_end}
{phang2}{cmd:. lincom _x + 16*_x_t}{p_end}

{pstd}Fitted median with HAC confidence limits{p_end}
{phang2}{cmd:. predictnl pred = predict() if e(sample), ci(lcl ucl) df(`e(df_r)')}{p_end}
{phang2}{cmd:. twoway (scatter ln_consump qtr) (line pred qtr, lpattern(solid)) (line lcl qtr, lpattern(shortdash)) (line ucl qtr, lpattern(shortdash)), tline(1971q1)}{p_end}

{pstd}Compare the 0.1 and 0.9 quantiles of the post-intervention level change{p_end}
{phang2}{cmd:. qreg_hac ln_consump _t _x _x_t, quantile(.1)}{p_end}
{phang2}{cmd:. qreg_hac ln_consump _t _x _x_t, quantile(.9)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:qreg_hac} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(N_seg)}}number of segments{p_end}
{synopt:{cmd:e(Tbar)}}mean segment length{p_end}
{synopt:{cmd:e(minseg)}}length of the shortest segment{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(q)}}quantile requested{p_end}
{synopt:{cmd:e(q_v)}}value of the quantile{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(sum_adev)}}sum of absolute deviations{p_end}
{synopt:{cmd:e(sum_rdev)}}sum of raw deviations{p_end}
{synopt:{cmd:e(sum_w)}}sum of weights{p_end}
{synopt:{cmd:e(hac_bw)}}HAC bandwidth {it:S}{p_end}
{synopt:{cmd:e(lag)}}lags with nonzero weight ({cmd:bartlett} and {cmd:parzen}){p_end}
{synopt:{cmd:e(phi1)}}estimated score autocorrelation ({cmd:lag(auto)}){p_end}
{synopt:{cmd:e(bwidth)}}density bandwidth{p_end}
{synopt:{cmd:e(kbwidth)}}kernel bandwidth ({cmd:density(kernel)}){p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(convcode)}}{cmd:0} if converged; otherwise, return code for why nonconvergence{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qreg_hac}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(panelvar)}}panel variable{p_end}
{synopt:{cmd:e(hac_kernel)}}HAC kernel{p_end}
{synopt:{cmd:e(lagmethod)}}{cmd:auto} or {cmd:user}{p_end}
{synopt:{cmd:e(phimethod)}}{cmd:bc} or {cmd:sample}{p_end}
{synopt:{cmd:e(denmethod)}}{cmd:fitted} or {cmd:kernel}{p_end}
{synopt:{cmd:e(bwmethod)}}density bandwidth method{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(vce)}}{cmd:hac}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:HAC}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {cmd:margins}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker A1991}{...}
{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica} 59: 817-858.

{marker GY2024}{...}
{phang}
Galvao, A. F., and J. Yoon. 2024. HAC covariance matrix estimation in quantile
regression. {it:Journal of the American Statistical Association} 119:
2305-2316.

{marker K2004}{...}
{phang}
Koenker, R. 2004. Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74-89.

{marker K2005}{...}
{phang}
Koenker, R. 2005. {it:Quantile Regression}. New York: Cambridge University Press.


{marker citation}{...}
{title:Citation of {cmd:qreg_hac}}

{p 4 8 2}{cmd:qreg_hac} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. QREG_HAC: Stata module for computing quantile regression with heteroskedasticity- and autocorrelation-consistent (HAC) standard errors.
Statistical Software Components sXXXXXX, Boston College Department of Economics.{p_end}



{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


{title:Also see}

{p 4 8 2}
Online: {helpb qreg}, {helpb qreg postestimation}, {helpb newey},
{helpb itsa} (if installed), {helpb praisk} (if installed),
{helpb betark} (if installed), {helpb xtpraisk} (if installed),
{helpb xtbetark} (if installed){p_end}
