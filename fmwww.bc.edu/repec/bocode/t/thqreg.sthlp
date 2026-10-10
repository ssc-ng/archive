{smcl}
{* *! version 1.0.0  03oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{viewerjumpto "Syntax" "thqreg##syntax"}{...}
{viewerjumpto "Description" "thqreg##description"}{...}
{viewerjumpto "Options" "thqreg##options"}{...}
{viewerjumpto "Why there is a solver inside" "thqreg##solver"}{...}
{viewerjumpto "The threshold moves across quantiles" "thqreg##moves"}{...}
{viewerjumpto "The test" "thqreg##test"}{...}
{viewerjumpto "What is NOT provided" "thqreg##limits"}{...}
{viewerjumpto "Examples" "thqreg##examples"}{...}
{viewerjumpto "Stored results" "thqreg##results"}{...}
{viewerjumpto "References" "thqreg##refs"}{...}
{title:Title}

{phang}
{bf:thqreg} {hline 2} Threshold quantile regression with an unknown threshold


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thqreg} {it:depvar} [{it:indepvars}] {ifin}{cmd:,}
{opth thresh:var(varname)} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth threshvar(varname)}}the threshold variable{p_end}
{synopt:{opt q:uantile(numlist)}}quantiles to fit; default {cmd:quantile(0.5)}{p_end}
{synopt:{opth inv:ariant(varlist)}}regressors whose coefficients do {it:not} switch{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points; default 50{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt test}}compute the sup/ave/exp-LR test of no threshold effect{p_end}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 0 (none){p_end}
{synopt:{opt boot(string)}}{opt resample} (default) or {opt wild}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt vce(string)}}{opt robust} (default) or {opt iid}, passed to {helpb qreg}{p_end}
{synopt:{opt maxit(#)}}inner iterations of the search solver; default 25{p_end}
{synopt:{opt qtol(#)}}convergence tolerance of the search solver{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required. {opt noconstant} is {bf:not} available;
see {help thqreg##limits:below}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thqreg} fits

{p 8 8 2}
Q{sub:tau}({it:y} | {it:x}, {it:q}) = {it:x}'{bf:beta1}({it:tau})
1{c -(}{it:q} <= {it:gamma}{c )-} + {it:x}'{bf:beta2}({it:tau})
1{c -(}{it:q} > {it:gamma}{c )-}

{pstd}
one quantile at a time. The threshold is estimated by minimising the
check-function objective

{p 8 8 2}
V({it:gamma}, {it:tau}) = {it:sum}{sub:i} rho{sub:tau}({it:y_i} -
{it:x_i}'{bf:beta}-hat({it:gamma}, {it:tau})),{space 3}
rho{sub:tau}({it:u}) = {it:u}({it:tau} - 1{c -(}{it:u} < 0{c )-})

{pstd}
over a trimmed grid, which is exactly what the least-squares version
({helpb thregress}) does to the residual sum of squares. A threshold quantile
regression asks a question an ordinary one cannot: whether the regime
structure is the same in the tails as at the centre.

{pstd}
{bf:The coefficients and standard errors printed are official Stata's.} At the
estimated threshold {cmd:thqreg} runs {helpb qreg} on the regime-split design
and reports what {cmd:qreg} returns, under {cmd:vce()} as asked. The solver
described {help thqreg##solver:below} is used to {it:search} for the threshold
and to bootstrap, never for what is printed.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is the threshold variable: the variable whose value
decides which regime an observation is in.

{phang}
{opt quantile(numlist)} lists the quantiles, each strictly between 0 and 1.
Each is fitted independently, with its {it:own} threshold. The coefficient
table shows the {bf:first} quantile only; {cmd:e(byquantile)} holds the
threshold, the objective and the test for every one of them.

{phang}
{opth invariant(varlist)} lists regressors whose coefficients are common to
both regimes. Everything in {it:indepvars} switches.

{phang}
{opt gridn(#)} caps the grid. Unlike the least-squares commands, where a grid
of every order statistic is nearly free, here each grid point costs a quantile
regression, so the default is a cap of 50 rather than everything. Raise it when
the profile looks ragged; lower it before using {opt test}.

{phang}
{opt test} computes the sup/ave/exp-LR test; see {help thqreg##test:below}.
{opt reps()} is required for a p-value and the cost is
{opt reps()} x grid points x quantiles quantile regressions, so start small:
3 quantiles x 14 grid points x 50 replications takes about a minute.

{phang}
{opt vce(robust|iid)} is handed to {helpb qreg} for the final fit.
{opt robust} is the default and gives the Hendricks-Koenker sandwich, which
does not assume the conditional density is the same across observations.

{phang}
{opt maxit(#)} and {opt qtol(#)} control the search solver. The defaults are
set so that it reaches the check-function minimum to about 1e-10 relative,
which the certification suite verifies against {helpb qreg} at five quantiles.
There is no reason to change them.

{phang}
{opt qvarname(string)} is a {bf:programmer's option}. It sets the text stored in
{cmd:e(threshold_var)} and printed in the header, without changing which variable
is actually searched. {helpb thtqar} uses it: that command builds a temporary
variable to hold a lag of the dependent variable, and passes the real expression
through here so the output reads {cmd:L1.y} rather than a temporary name. There is
no reason to set it interactively.


{marker solver}{...}
{title:Why there is a solver inside, and why that is safe}

{pstd}
The search needs one quantile regression per grid point, and the bootstrap
needs one per grid point {it:per replication}. Calling {helpb qreg} inside
that loop is not feasible, so {cmd:thqreg} carries its own solver: the
Hunter-Lange (2000) MM algorithm, in which |{it:r}| is majorised by
({it:r}{sup:2}/({it:eps} + |{it:r_m}|) + {it:eps} + |{it:r_m}|)/2 and each step
becomes a weighted least squares,

{p 8 8 2}
{bf:b} = ({it:X}'{it:WX}){sup:-1} ( {it:X}'{it:Wy} +
(2{it:tau} - 1) {it:X}'1 ),{space 4}
{it:w_i} = 1/({it:eps} + |{it:r_i}|)

{pstd}
iterated with {it:eps} driven down to machine scale, so the limit is the exact
check-function minimiser and not a smoothed approximation of it.

{pstd}
Two things make this safe rather than a shortcut. First, the solver is
{bf:certified against official qreg} at tau = .1, .25, .5, .75 and .9: the
objective agrees to all printed digits and the coefficients to about 5e-11.
Second, and more to the point, {bf:nothing the solver computes is reported}.
Its only job is to say which grid point has the smallest objective, and the
certification also checks that the winning grid point beats the runner-up by
six orders of magnitude more than the solver's own error -- so the solver
cannot change the chosen threshold. If it could, the threshold would not be
identified and the profile would say so.


{marker moves}{...}
{title:The threshold moves across quantiles, and that is the point}

{pstd}
Nothing requires the regimes of the median to be the regimes of the tenth
percentile. A {it:gamma} that moves across quantiles is a finding, not an
error, and it is often the most interesting thing in the output: it says the
{it:location} of the regime boundary itself depends on where in the
distribution you look.

{pstd}
Read {cmd:e(byquantile)} as a whole rather than one row at a time. Three
patterns recur:

{phang2}
{bf:gamma stable, coefficients changing.} One regime boundary, different
effects along the distribution. This is the clean case and the easiest to
report.

{phang2}
{bf:gamma moving monotonically.} The boundary drifts with the quantile. Often a
sign that the true transition is smooth rather than sharp -- compare
{helpb thstr}.

{phang2}
{bf:gamma jumping about with no pattern.} Usually weak identification, not a
discovery. Look at {cmd:e(profile)}: if it is flat for that quantile, the
threshold there is not pinned down and should not be interpreted.


{marker test}{...}
{title:The test}

{pstd}
{opt test} reports

{p 8 8 2}
LR({it:gamma}) = 2 ( V{sub:0} - V({it:gamma}) )

{pstd}
where V{sub:0} is the check-function objective of the {it:linear} quantile
regression, together with its sup, ave and exp over the grid and a bootstrap
p-value. Under the null of no threshold effect the threshold is unidentified,
so no functional of this is chi-squared and no table applies; the p-value is
simulated from the linear quantile regression with the regressors and the
threshold variable held fixed.

{pstd}
{bf:Why an LR form and not a Wald.} A quantile Wald statistic needs the
sparsity 1/{it:f}(0), which has to be estimated at {it:every} candidate
threshold -- in practice two extra quantile fits per grid point for a
difference quotient, so three fits instead of one, inside a bootstrap that
already costs reps x grid fits. In the LR form that sparsity enters as a single
multiplicative constant, common to the observed statistic and to every
bootstrap replication, so it {bf:cancels exactly} in the p-value.
{cmd:thqreg} therefore does not estimate it at all. The cost is that the
statistic has no asymptotic critical value -- which it would not have had
anyway, the threshold being unidentified under the null.


{marker limits}{...}
{title:What is NOT provided, and why}

{phang}
{bf:No confidence set for gamma.} Caner (2002) gives the convergence rate and
the limit distribution of the threshold estimator in this model, and it is not
the one that makes the least-squares inverted-LR construction work. Rather than
print an interval built on the wrong limit, {cmd:thqreg} prints none. Use
{cmd:e(profile)} to see how sharply the threshold is identified, and treat the
point estimate as a point estimate.

{phang}
{bf:The reported standard errors condition on gamma.} They come from
{helpb qreg} at the estimated threshold and do not account for the threshold
having been estimated. That is the standard practice in this literature and it
is stated in the output, not hidden.

{phang}
{bf:No {opt noconstant}.} Official {helpb qreg} does not allow it, and the
reported coefficients come from {cmd:qreg}, so {cmd:thqreg} refuses it rather
than silently reporting something from a different estimator. (Internally the
design carries the regime-1 {it:indicator} and {cmd:qreg}'s own constant; the
two regime constants and their standard errors are then recovered by a linear
map applied to {cmd:b} and {cmd:V}, which the certification checks against
{cmd:qreg} directly.)


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_dj}{p_end}

{pstd}The median{p_end}
{phang2}{cmd:. thqreg diff gdp60 iony pgro sch, threshvar(q)}{p_end}

{pstd}Three quantiles: does the regime boundary move?{p_end}
{phang2}{cmd:. thqreg diff gdp60 iony pgro sch, threshvar(q) quantile(0.25 0.5 0.75)}{p_end}
{phang2}{cmd:. matrix list e(byquantile)}{p_end}

{pstd}With the test. Start with few replications and few grid points{p_end}
{phang2}{cmd:. thqreg diff gdp60 iony pgro sch, threshvar(q) quantile(0.25 0.5 0.75) ///}{p_end}
{phang2}{cmd:      gridn(20) test reps(50) seed(3)}{p_end}

{pstd}Is the threshold sharply identified at this quantile?{p_end}
{phang2}{cmd:. thqreg diff gdp60 iony pgro sch, threshvar(q) quantile(0.1)}{p_end}
{phang2}{cmd:. matrix list e(profile)}{p_end}

{pstd}Compare with the least-squares threshold on the same data{p_end}
{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(n_tau)}}number of quantiles{p_end}
{synopt:{cmd:e(tau)}}the quantile the coefficient table is for{p_end}
{synopt:{cmd:e(gamma)}}its threshold{p_end}
{synopt:{cmd:e(obj)}, {cmd:e(obj0)}}check-function objective, split and linear{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}regime sizes{p_end}
{synopt:{cmd:e(n_grid)}}grid points searched{p_end}
{synopt:{cmd:e(lr)}, {cmd:e(lr_sup)}, {cmd:e(lr_ave)}, {cmd:e(lr_exp)}}the test statistics{p_end}
{synopt:{cmd:e(gamma_test)}}argmax of the LR{p_end}
{synopt:{cmd:e(p)}, {cmd:e(p_mcse)}, {cmd:e(boot_reps)}}bootstrap p-value and its Monte Carlo s.e.{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}lower slopes, lower {cmd:_cons}, upper slopes, upper {cmd:_cons}, then the invariant block{p_end}
{synopt:{cmd:e(byquantile)}}one row per quantile: tau, gamma, obj, obj0, n1, n2, lr_sup, lr_ave, lr_exp, gmax, p, reps{p_end}
{synopt:{cmd:e(profile)}}the grid, then one column of objectives per quantile{p_end}

{pstd}
{cmd:predict} supports {opt xb} (the fitted conditional quantile),
{opt residuals} (deviations from it -- about {it:tau} of them are negative,
which is the model and not a defect) and {opt regime}.


{marker refs}{...}
{title:References}

{phang}
Caner, M. 2002. A note on least absolute deviation estimation of a threshold
model. {it:Econometric Theory} 18: 800-814.
{browse "https://doi.org/10.1017/s0266466602183113":doi:10.1017/s0266466602183113}

{phang}
Galvao, A. F., G. Montes-Rojas, and J. Olmo. 2011. Threshold quantile
autoregressive models. {it:Journal of Time Series Analysis} 32: 253-267.
{browse "https://doi.org/10.1111/j.1467-9892.2010.00696.x":doi:10.1111/j.1467-9892.2010.00696.x}

{phang}
Hunter, D. R., and K. Lange. 2000. Quantile regression via an MM algorithm.
{it:Journal of Computational and Graphical Statistics} 9: 60-77.
{browse "https://doi.org/10.1080/10618600.2000.10474866":doi:10.1080/10618600.2000.10474866}

{phang}
Koenker, R., and G. Bassett. 1978. Regression quantiles.
{it:Econometrica} 46: 33-50.
{browse "https://doi.org/10.2307/1913643":doi:10.2307/1913643}

{phang}
Lee, S., M. H. Seo, and Y. Shin. 2011. Testing for threshold effects in
regression models. {it:Journal of the American Statistical Association}
106: 220-231.
{browse "https://doi.org/10.1198/jasa.2011.tm09800":doi:10.1198/jasa.2011.tm09800}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit}, {helpb threshkit_choose}, {helpb thqtest} (the
threshold-existence test in this setting), {helpb thtqar}, {helpb thqkink},
{helpb thregress}, {helpb thkink}, {helpb thnregimes}, {helpb thexport},
{helpb qreg}
{p_end}
