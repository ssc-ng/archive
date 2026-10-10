{smcl}
{* *! version 1.0.0  03oct2026}{...}
{vieweralsosee "thqreg" "help thqreg"}{...}
{vieweralsosee "thkink" "help thkink"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thqkink##syntax"}{...}
{viewerjumpto "Description" "thqkink##description"}{...}
{viewerjumpto "Options" "thqkink##options"}{...}
{viewerjumpto "Kink or jump? thqkink or thqreg?" "thqkink##versus"}{...}
{viewerjumpto "Reading the slopes" "thqkink##slopes"}{...}
{viewerjumpto "How many kinks" "thqkink##howmany"}{...}
{viewerjumpto "The test" "thqkink##test"}{...}
{viewerjumpto "What is NOT provided" "thqkink##limits"}{...}
{viewerjumpto "Examples" "thqkink##examples"}{...}
{viewerjumpto "Stored results" "thqkink##results"}{...}
{viewerjumpto "References" "thqkink##refs"}{...}
{title:Title}

{phang}
{bf:thqkink} {hline 2} Bent-line (kink) quantile regression with one or
several unknown kink points


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thqkink} {it:depvar} {ifin}{cmd:,} {opth kink:var(varname)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth kinkvar(varname)}}the variable the fit bends in{p_end}
{synopt:{opt nk:inks(#)}}number of kinks, 1 to 4; default 1{p_end}
{synopt:{opt q:uantile(numlist)}}quantiles to fit; default {cmd:quantile(0.5)}{p_end}
{synopt:{opth inv:ariant(varlist)}}other regressors, entering linearly{p_end}
{synopt:{opt trim(#)}}trimming of the kink grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points; default 50{p_end}
{synopt:{opt refine(#)}}refinement sweeps after the sequential search; default 1{p_end}
{synopt:{opt minobs(#)}}minimum observations in a segment{p_end}
{synopt:{opt test}}sup/ave/exp-LR test of one fewer kink{p_end}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 0 (none){p_end}
{synopt:{opt boot(string)}}{opt resample} (default) or {opt wild}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt vce(string)}}{opt robust} (default) or {opt iid}, passed to {helpb qreg}{p_end}
{synopt:{opt maxit(#)}, {opt qtol(#)}}the search solver's controls{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt kinkvar()} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thqkink} fits

{p 8 8 2}
Q{sub:tau}({it:y} | {it:x}, {it:z}) = {it:b}{sub:0} + {it:b}{sub:1}{it:x} +
{it:sum}{sub:k} {it:b}{sub:k+1}({it:x} - {it:g_k}){sub:+} + {it:z}'{it:d}

{pstd}
where ({it:u}){sub:+} is max({it:u}, 0). The fitted conditional quantile is
{bf:continuous} in {it:x} and changes {it:slope} at each estimated kink
{it:g_k}: the slope on the first segment is {it:b}{sub:1}, on the second
{it:b}{sub:1} + {it:b}{sub:2}, and so on.

{pstd}
The kinks are found by minimising the check-function objective over a trimmed
grid -- sequentially for more than one, then refined with the others held
fixed. {bf:The coefficients and standard errors printed are official Stata's:}
at the estimated kinks {cmd:thqkink} runs {helpb qreg} on the bent-line basis
and reports what it returns.

{pstd}
The search uses the same certified quantile solver as {helpb thqreg} -- see
{help thqreg##solver:help thqreg} for why there is one and why it is safe. The
only new thing here is the basis.


{marker options}{...}
{title:Options}

{phang}
{opth kinkvar(varname)} is the variable the relationship bends in. There is
exactly one, which is what makes the model a bent line rather than a general
spline.

{phang}
{opt nkinks(#)} is the number of kinks. Each one costs a grid pass, and with
more than one the search is sequential, so the cost grows roughly linearly
rather than as a power. See {help thqkink##howmany:how many kinks}.

{phang}
{opth invariant(varlist)} lists other regressors, which enter {it:linearly}
and do not bend. Everything that is not {opt kinkvar()} belongs here.

{phang}
{opt refine(#)} re-optimises each kink with the others held fixed, after the
sequential search has placed them all. The default is one sweep, and it is
worth having: a kink found first is conditional on a model that did not yet
contain the second.

{phang}
{opt test} tests {opt nkinks()}-1 kinks against {opt nkinks()}. With
{cmd:nkinks(1)} that is a straight line against a kink. {opt reps()} is
required for a p-value.

{phang}
{opt vce(robust|iid)} is handed to {helpb qreg} for the final fit.

{pstd}
{opt maxit()} and {opt qtol()} control the search solver and should be left
alone; see {helpb thqreg}.


{marker versus}{...}
{title:Kink or jump? thqkink or thqreg?}

{pstd}
This is the decision to make first, and it is substantive, not technical.

{synoptset 14}{...}
{p2col 5 14 18 2: command}what happens at the threshold{p_end}
{p2line}
{p2col 5 14 18 2:{cmd:thqkink}}the fitted quantile is {bf:continuous}; its
{it:slope} changes{p_end}
{p2col 5 14 18 2:{helpb thqreg}}the fitted quantile {bf:jumps}; the whole
coefficient vector changes{p_end}
{p2line}

{pstd}
{bf:Use a kink when the mechanism is a change in a rate.} Debt starts to hurt
growth beyond some level; a tax schedule's marginal rate steps up; a dose
stops helping beyond a point. In all of these, nothing discontinuous happens
{it:at} the threshold -- what changes is how fast the outcome moves with the
regressor.

{pstd}
{bf:Use a jump when something discrete switches.} A constraint binds, a rule
triggers, an eligibility rule changes. Then the level itself shifts.

{pstd}
{bf:And if you are unsure, fit both and compare the objectives.} The kink is a
{it:restricted} version of the jump -- it imposes continuity -- so its
check-function objective can never be smaller. If the two are close, the
continuity restriction costs nothing and the kink is the better model: fewer
parameters and a threshold that is far better identified, because a kink is
pinned down by the curvature of the whole fit rather than by the handful of
observations nearest the threshold.

{pstd}
The same choice at the conditional mean is {helpb thkink} against
{helpb thregress}, and {helpb thkink}{cmd: , estat continuity} tests it
formally there.


{marker slopes}{...}
{title:Reading the slopes}

{pstd}
The coefficient table reports the {it:base} slope on {opt kinkvar()} and then
one {bf:slope_change}{it:k} per kink. The slope on segment {it:k}+1 is the
base slope plus every slope change to its left. So read it this way:

{phang2}
{bf:A slope change whose confidence interval contains zero means that kink is
not doing anything}, whatever the kink's location says. Drop it, or lower
{opt nkinks()}.

{phang2}
{bf:The slopes themselves need {cmd:estat slopes}}, not mental arithmetic. It
cumulates them for you {it:and} gets their standard errors right: the variance
of a sum of coefficients is the sum of the whole relevant block of the
covariance matrix, not one diagonal element. Adding coefficients by hand and
taking a single standard error is the standard way to get a segmented fit's
inference wrong.

{phang2}
{bf:A sign change across a kink is the interesting case} -- a relationship that
is positive below and negative above. {cmd:estat slopes} gives the test of each
segment slope against zero directly.


{marker howmany}{...}
{title:How many kinks}

{pstd}
{cmd:thqkink} prints, for every quantile, the objective and two information
criteria for {it:every} number of kinks from 0 up to {opt nkinks()}:

{p 8 8 2}
BIC = {it:n} ln(V/{it:n}) + {it:p} ln({it:n}){space 6}
sBIC = {it:n} ln(V/{it:n}) + {it:p} ln({it:n}) ln(ln({it:n}))

{pstd}
with {it:p} counting the intercept, the base slope, one slope change per kink,
the invariant block {bf:and the kink locations themselves} -- an estimated
kink is a parameter, and a criterion that does not charge for it will
over-select.

{pstd}
Zhong, Wan and Zhang (2022) argue for a penalty inflated like the second one
when choosing the {it:number} of kinks, because the plain BIC over-selects
here. The inflation factor is a tuning choice, so {cmd:thqkink} prints both and
calls neither the answer. {cmd:estat select} shows the table again.

{pstd}
Use the criteria {it:and} the slope changes together: a kink that BIC keeps but
whose slope change is indistinguishable from zero is a kink in name only.


{marker test}{...}
{title:The test}

{pstd}
{opt test} reports

{p 8 8 2}
LR({it:g}) = 2 ( V{sub:null} - V({it:g}) )

{pstd}
with its sup, ave and exp over the grid and a bootstrap p-value. The null has
one kink fewer; with {cmd:nkinks(1)} it is a straight line in
{opt kinkvar()}. The extra kink is {it:unidentified} under the null whatever
the number, so none of these is chi-squared and no table applies: the p-value
is simulated with {opt kinkvar()} and the invariant block held fixed.

{pstd}
As in {helpb thqreg}, the LR form is used rather than a Wald so that the
sparsity 1/{it:f}(0) -- which a Wald would need at every grid point -- cancels
between the observed statistic and every bootstrap draw and is never estimated.


{marker limits}{...}
{title:What is NOT provided, and why}

{phang}
{bf:No confidence interval for a kink location.} Li, Wei, Chappell and He
(2011) give an asymptotic theory for the bent-line quantile estimator in which
the kink is root-{it:n} consistent and asymptotically normal -- unlike the
jump case. {cmd:thqkink} nevertheless does not print an interval, because the
variance requires a sparsity estimate at the kink that is sensitive to
bandwidth in exactly the region where the data are thinnest. Use
{cmd:estat profile} to see how sharply the kink is located: it prints the
distance from the winning grid point to the runner-up, and a gap of the same
order as the search solver's accuracy means the location is a near-tie.

{phang}
{bf:The reported standard errors condition on the kinks.} They come from
{helpb qreg} at the estimated locations. That is the standard practice, and it
is stated in the output rather than hidden.

{phang}
{bf:One kink variable only.} A model that bends in two different variables is a
different object (an additive spline model) and is not what these papers are
about.


{marker examples}{...}
{title:Examples}

{pstd}Setup: the Reinhart-Rogoff debt and growth data{p_end}
{phang2}{cmd:. use threshkit_kink}{p_end}

{pstd}One kink at the median{p_end}
{phang2}{cmd:. thqkink gdp, kinkvar(debt1) invariant(gdp1)}{p_end}
{phang2}{cmd:. estat slopes}{p_end}
{phang2}{cmd:. estat kinkplot}{p_end}

{pstd}Does the kink sit in the same place across the distribution?{p_end}
{phang2}{cmd:. thqkink gdp, kinkvar(debt1) invariant(gdp1) quantile(0.1 0.25 0.5 0.75 0.9)}{p_end}
{phang2}{cmd:. estat kinks, graph}{p_end}

{pstd}Is the kink sharply located, or a near-tie on the grid?{p_end}
{phang2}{cmd:. estat profile, graph}{p_end}

{pstd}Two kinks, and the criteria for how many{p_end}
{phang2}{cmd:. thqkink gdp, kinkvar(debt1) invariant(gdp1) nkinks(2) refine(2)}{p_end}
{phang2}{cmd:. estat select}{p_end}
{phang2}{cmd:. estat slopes}{p_end}

{pstd}Test a straight line against one kink{p_end}
{phang2}{cmd:. thqkink gdp, kinkvar(debt1) invariant(gdp1) gridn(20) test reps(199) seed(7)}{p_end}

{pstd}Kink or jump? Compare the objectives -- the kink is the restricted model{p_end}
{phang2}{cmd:. thqkink gdp, kinkvar(debt1) invariant(gdp1)}{p_end}
{phang2}{cmd:. thqreg gdp gdp1, threshvar(debt1)}{p_end}

{pstd}And the same question at the conditional mean{p_end}
{phang2}{cmd:. thkink gdp gdp1, kinkvar(debt1) grange(10 70) gstep(0.1)}{p_end}
{phang2}{cmd:. estat continuity}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(nkinks)}}number of kinks{p_end}
{synopt:{cmd:e(kink1)} ... }the kink locations at the reported quantile{p_end}
{synopt:{cmd:e(tau)}}the quantile the coefficient table is for{p_end}
{synopt:{cmd:e(n_tau)}}number of quantiles fitted{p_end}
{synopt:{cmd:e(obj)}, {cmd:e(obj0)}}objective, kinked and straight line{p_end}
{synopt:{cmd:e(n_grid)}}grid points searched{p_end}
{synopt:{cmd:e(lr_sup)}, {cmd:e(lr_ave)}, {cmd:e(lr_exp)}}the test statistics{p_end}
{synopt:{cmd:e(p)}, {cmd:e(p_mcse)}, {cmd:e(boot_reps)}}bootstrap p-value and its Monte Carlo s.e.{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}base slope, the slope changes, the invariant block, {cmd:_cons}{p_end}
{synopt:{cmd:e(kinks)}}one row per quantile, one column per kink{p_end}
{synopt:{cmd:e(byquantile)}}tau, obj, obj0, lr_sup, lr_ave, lr_exp, gmax, p, reps{p_end}
{synopt:{cmd:e(select)}}tau, K, objective, BIC, sBIC for every K{p_end}
{synopt:{cmd:e(profile)}}the grid, then one objective column per quantile{p_end}

{pstd}
{cmd:estat}: {cmd:kinkplot}, {cmd:kinks}, {cmd:slopes}, {cmd:profile},
{cmd:select}, {cmd:table}. {cmd:predict} supports {opt xb},
{opt residuals} and {opt segment}.


{marker refs}{...}
{title:References}

{phang}
Hansen, B. E. 2017. Regression kink with an unknown threshold.
{it:Journal of Business and Economic Statistics} 35: 228-240.
{browse "https://doi.org/10.1080/07350015.2015.1073595":doi:10.1080/07350015.2015.1073595}

{phang}
Li, C., Y. Wei, R. Chappell, and X. He. 2011. Bent line quantile regression
with application to an allometric study of land mammals' speed and mass.
{it:Biometrics} 67: 242-249.
{browse "https://doi.org/10.1111/j.1541-0420.2010.01436.x":doi:10.1111/j.1541-0420.2010.01436.x}

{phang}
Muggeo, V. M. R. 2003. Estimating regression models with unknown break-points.
{it:Statistics in Medicine} 22: 3055-3071.
{browse "https://doi.org/10.1002/sim.1545":doi:10.1002/sim.1545}

{phang}
Zhong, W., C. Wan, and W. Zhang. 2022. Estimation and inference for multi-kink
quantile regression. {it:Journal of Business and Economic Statistics}
40: 1123-1139.
{browse "https://doi.org/10.1080/07350015.2021.1901720":doi:10.1080/07350015.2021.1901720}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb thqreg}, {helpb thkink}, {helpb threshkit},
{helpb threshkit_choose}, {helpb thregress}, {helpb qreg}
{p_end}
