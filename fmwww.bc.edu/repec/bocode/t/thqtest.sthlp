{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thqreg" "help thqreg"}{...}
{vieweralsosee "thtqar" "help thtqar"}{...}
{vieweralsosee "thqkink" "help thqkink"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thqtest##syntax"}{...}
{viewerjumpto "Description" "thqtest##description"}{...}
{viewerjumpto "Two different nulls" "thqtest##nulls"}{...}
{viewerjumpto "Options" "thqtest##options"}{...}
{viewerjumpto "Why a score test" "thqtest##score"}{...}
{viewerjumpto "Reading the output" "thqtest##reading"}{...}
{viewerjumpto "What it does NOT do" "thqtest##limits"}{...}
{viewerjumpto "Examples" "thqtest##examples"}{...}
{viewerjumpto "Stored results" "thqtest##results"}{...}
{viewerjumpto "References" "thqtest##refs"}{...}

{title:Title}

{phang}
{bf:thqtest} {hline 2} Threshold-existence tests in quantile regression: at
one quantile, or uniformly over a set of them


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thqtest} {it:depvar} [{it:indepvars}] {ifin}{cmd:,}
{opth thresh:var(varname)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth thresh:var(varname)}}the candidate threshold variable{p_end}
{synopt:{opt q:uantile(#)}}test ONE quantile; default {cmd:quantile(0.5)}{p_end}
{synopt:{opt quant:iles(numlist)}}test UNIFORMLY over a set — a different and
stronger null{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default 0.15{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points{p_end}
{synopt:{opt minobs(#)}}minimum observations on each side{p_end}
{synopt:{opt nocons:tant}}no constant{p_end}
{synopt:{opt reps(#)}}multiplier replications; default 499{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt maxit(#)}}iterations for the restricted quantile fit; default 200{p_end}
{synopt:{opt qtol(#)}}its tolerance; default 1e-8{p_end}
{synopt:{opt gr:aph}}histogram of the multiplier null with the statistic marked{p_end}
{synopt:{opt bins(#)}}bins for that histogram{p_end}
{synopt:{opt sav:ing()}}save the graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thqtest} tests whether a covariate threshold exists in a {it:quantile}
regression — that is, whether the conditional {bf:quantile} function of
{it:depvar} given {it:indepvars} changes when {it:threshvar} crosses some
unknown value.

{pstd}
This is not the same question as {helpb thtest} answers. That one asks about
the conditional {bf:mean}. A threshold can move the tails of a distribution
while leaving its mean almost untouched — which is precisely the situation a
quantile threshold model exists for, and precisely the situation a
mean-based test will miss.


{marker nulls}{...}
{title:Two different nulls, and the difference is the whole point}

{pstd}
{bf:{opt quantile(#)} — the single-quantile test} (Zhang, Wang and Zhu 2014)

{p 8 8 2}
H0: at {it:this} quantile there is no covariate threshold.

{pstd}
{bf:{opt quantiles(numlist)} — the uniform test} (Galvao, Kato, Montes-Rojas
and Olmo 2014)

{p 8 8 2}
H0: there is no threshold effect at {bf:any} quantile in the set.

{pstd}
The second is strictly stronger and it is usually the one you want. A
threshold that bites only in the lower tail — a borrowing constraint that
binds for the poor, a floor that matters only in bad states — will not show
up at {it:tau} = 0.5, and testing the median alone would licence the
conclusion that there is no threshold when there plainly is one.

{pstd}
The price is that the statistic searches over {bf:two} sets, the threshold
grid and the quantile set, so the p-value must be corrected for both. It is:
every multiplier replication repeats the whole double search. A p-value read
off the winning ({it:tau}, {it:gamma}) pair would be {bf:the p-value of a
test nobody ran} — it would condition on a choice the data made.

{pstd}
Within a replication, {bf:one} multiplier draw is reused across the
quantiles, deliberately. The subgradients at different quantiles come from
the same observations, and their dependence across {it:tau} is part of what
the uniform limit describes; drawing independent multipliers per quantile
would destroy exactly that dependence and give a critical value for a
different statistic.


{marker options}{...}
{title:Options}

{phang}
{opt quantile()} and {opt quantiles()} cannot both be given — they test
different nulls. {opt quantiles()} needs at least two values: the uniform
test over a single point {it:is} the single-quantile test, and calling it
uniform would overstate what was done.

{phang}
{opt reps()} must be at least 100. The multiplier simulation {bf:refits
nothing} (see below), so it is cheap and there is no reason to economise;
499 or 999 costs little.


{marker score}{...}
{title:Why a score test, and why that makes it cheap}

{pstd}
Both statistics are built from the {bf:subgradient} of the check function at
the {bf:restricted} fit:

{p 8 8 2}
psi_{it:i} = {it:tau} {c -} 1{c -(}{it:y_i} {ul:<} {it:x_i}'bhat({it:tau}){c )-}

{pstd}
where bhat({it:tau}) is the ordinary quantile regression with {bf:no}
threshold in it. Accumulate psi over the observations on one side of each
candidate threshold and standardise; under the null that partial sum behaves
like a Brownian bridge in the threshold index.

{pstd}
Three consequences, and they are why this command is fast where a
Wald-type test would not be:

{p 8 12 2}
1. Nothing is estimated under the {it:alternative}. There is no threshold to
fit, at any grid point, ever.

{p 8 12 2}
2. The multiplier simulation {bf:refits nothing} — it redraws signs and
re-accumulates. So 999 replications cost about what one quantile regression
costs.

{p 8 12 2}
3. The null distribution depends on the design and on the restricted sign
pattern, {bf:both of which are observed}. That is what makes the multiplier
scheme valid here rather than an approximation.


{marker reading}{...}
{title:Reading the output}

{pstd}
With {opt quantiles()} a per-quantile table is printed. {bf:Read that before
the single p-value.} If one quantile dominates the sup, the threshold effect
lives in that part of the distribution — and that is the finding, not a
detail. A threshold in the lower tail and nothing at the median is a
substantively different model from a threshold everywhere, and only the
table distinguishes them.

{pstd}
The Monte Carlo standard error of the p-value is printed. If it is large
relative to the distance from your significance level, raise {opt reps()};
it is cheap here.


{marker limits}{...}
{title:What it does NOT do}

{pstd}
{bf:It does not locate the threshold.} The argmax reported is where the
score is largest, not an estimate with a confidence set. A score test's
whole economy comes from never fitting the alternative, so it has no
threshold estimate to report. Fit {helpb thqreg} for that — and note that
{cmd:thqreg} estimates one threshold {it:per quantile}, which is the natural
next step after this test rejects.

{pstd}
{bf:It does not test the mean.} If you want the conditional-mean question,
that is {helpb thtest}. Running both is often informative: a rejection in
the tails with none at the mean is a real pattern and worth reporting as
one.

{pstd}
{bf:It assumes the threshold variable is exogenous.} So does every other
threshold test in this package except {helpb thivreg}'s machinery; with an
endogenous threshold variable the null distribution is not the one simulated
here.


{marker examples}{...}
{title:Examples}

{pstd}The median only{p_end}

{phang2}{cmd:. thqtest y x1 x2, threshvar(q) quantile(0.5) reps(999) seed(1)}{p_end}

{pstd}Uniformly over the distribution — the test to prefer{p_end}

{phang2}{cmd:. thqtest y x1 x2, threshvar(q) quantiles(0.1(0.1)0.9) reps(999) seed(1)}{p_end}

{pstd}Look at where the effect is{p_end}

{phang2}{cmd:. matrix list r(bytau)}{p_end}

{pstd}And see the null distribution the p-value came from{p_end}

{phang2}{cmd:. thqtest y x1 x2, threshvar(q) quantiles(0.1(0.2)0.9) reps(999) seed(1) graph}{p_end}

{pstd}If it rejects, estimate{p_end}

{phang2}{cmd:. thqreg y x1 x2, threshvar(q) quantiles(0.1(0.2)0.9)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}}the statistic — sup over the grid, and over the
quantiles too in uniform mode{p_end}
{synopt:{cmd:r(p)}, {cmd:r(p_mcse)}}p-value and its Monte Carlo s.e.{p_end}
{synopt:{cmd:r(gamma)}}the threshold attaining the sup{p_end}
{synopt:{cmd:r(tau)}}the quantile tested, or the one attaining the sup{p_end}
{synopt:{cmd:r(N)}, {cmd:r(n_grid)}, {cmd:r(n_tau)}}dimensions searched{p_end}
{synopt:{cmd:r(reps)}, {cmd:r(trim)}}settings{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:r(mode)}}{cmd:single} or {cmd:uniform}{p_end}
{synopt:{cmd:r(depvar)}}the dependent variable{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:r(path)}}single mode: the standardised score at every grid point{p_end}
{synopt:{cmd:r(bytau)}}uniform mode: one row per quantile — tau, sup, argmax{p_end}
{synopt:{cmd:r(bdist)}}the multiplier draws{p_end}


{marker refs}{...}
{title:References}

{phang}
Zhang, L., H. J. Wang, and Z. Zhu. 2014. Testing for change points due to a
covariate threshold in quantile regression.
{it:Statistica Sinica} 24: 1859-1877.
{browse "https://doi.org/10.5705/ss.2012.322":doi:10.5705/ss.2012.322}

{phang}
Galvao, A. F., K. Kato, G. Montes-Rojas, and J. Olmo. 2014. Testing
linearity against threshold effects: uniform inference in quantile
regression. {it:Annals of the Institute of Statistical Mathematics}
66: 413-439.
{browse "https://doi.org/10.1007/s10463-013-0418-9":doi:10.1007/s10463-013-0418-9}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com


{title:Also see}

{psee}
Estimate it: {helpb thqreg}, {helpb thtqar}, {helpb thqkink}{break}
The conditional-MEAN test: {helpb thtest}{break}
Which command at all: {helpb threshkit_choose}
{p_end}
