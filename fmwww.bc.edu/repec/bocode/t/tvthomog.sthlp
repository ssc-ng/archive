{smcl}
{* *! version 1.1.0  13oct2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{viewerjumpto "Syntax" "tvthomog##syntax"}{...}
{viewerjumpto "Description" "tvthomog##description"}{...}
{viewerjumpto "What it does and does not tell you" "tvthomog##scope"}{...}
{viewerjumpto "Options" "tvthomog##options"}{...}
{viewerjumpto "The direction vector v" "tvthomog##direction"}{...}
{viewerjumpto "How it works" "tvthomog##method"}{...}
{viewerjumpto "When the test declines" "tvthomog##declines"}{...}
{viewerjumpto "Examples" "tvthomog##examples"}{...}
{viewerjumpto "Stored results" "tvthomog##results"}{...}
{viewerjumpto "Validation" "tvthomog##validation"}{...}
{viewerjumpto "References" "tvthomog##references"}{...}
{viewerjumpto "Author" "tvthomog##author"}{...}
{title:Title}

{phang}
{bf:tvthomog} {hline 2} Test whether a regression threshold is constant
(the CT test of Lee and Wang)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvthomog} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth thr:eshvar(varname)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opth thr:eshvar(varname)}}the threshold variable {it:q}{p_end}
{synopt :{opt nocons:tant}}suppress the constant from the switching
set{p_end}

{syntab:Test}
{synopt :{opt trim(#)}}trimming fraction {it:tau}; default
{cmd:trim(0.10)}, the paper's{p_end}
{synopt :{opt gridn(#)}}cap the number of threshold candidates{p_end}
{synopt :{opt mino:bs(#)}}minimum observations per regime{p_end}
{synopt :{opt bw:idth(#)}}kernel bandwidth; default is the paper's rule of
thumb{p_end}
{synopt :{opt d:irection(#)}}use {it:v} = {it:e_j}, the {it:j}th switching
coefficient alone{p_end}
{synopt :{opt dv:ector(numlist)}}give the direction vector {it:v}
outright{p_end}
{synopt :{opt l:evel(#)}}report at 90, 95 or 99; default
{cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required.{p_end}
{p 4 6 2}
{it:q} may be a time-series operated variable, and {cmd:tvthomog} is
{helpb by} -prefixable only in the sense that {helpb if} and {helpb in}
restrict the sample.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvthomog} tests whether the threshold in a threshold regression is the
{bf:same for every observation}. The model is

{p 8 8 2}
{it:y_i} = {it:x_i'beta} + {it:x_i'delta} 1[{it:q_i} {ul:<} {it:gamma_0i}] +
{it:u_i}

{pstd}
where the threshold carries a subscript {it:i}: it is allowed to differ
across observations. The hypotheses are

{p 8 8 2}
H0: P({it:gamma_0i} = {it:gamma_0}) = 1 for some constant {it:gamma_0}{break}
H1: no constant {it:gamma_0} does that

{pstd}
so under the null this is the ordinary constant-threshold regression of
Hansen (2000), which {bf:THRESHKIT} and its relatives estimate, and under
the alternative it is not.

{pstd}
This is the gateway command of the {helpb tvthresh} library. Fail to reject
and a constant-threshold command is the right tool, and the more efficient
one. Reject and a constant-threshold model is misspecified, and the question
becomes which time-varying specification fits.

{pstd}
The test is unusually cheap for this literature because it needs the model
fitted {bf:only under the null}. There is no search under the alternative, no
bootstrap, and no simulation: the limiting distribution is pivotal and its
critical values are tabulated. One profile least-squares fit and its
residuals are the whole input.


{marker scope}{...}
{title:What it does and does not tell you}

{pstd}
{bf:It answers one question: is the threshold constant?} It does not estimate
how the threshold varies, and a rejection is not an estimate of anything. In
particular it does not distinguish between

{p 8 10 2}{bf:.} a threshold that drifts smoothly over time,{p_end}
{p 8 10 2}{bf:.} a threshold that shifts once,{p_end}
{p 8 10 2}{bf:.} a threshold that depends on a covariate,{p_end}
{p 8 10 2}{bf:.} two or more constant thresholds rather than one,{p_end}
{p 8 10 2}{bf:.} a threshold effect contaminated by a smooth nonlinearity in
{it:q}.{p_end}

{pstd}
All five violate the null and all five can produce a large statistic. Which
of them you have is a separate modelling question.

{pstd}
{bf:Failing to reject is not proof of constancy.} Like any test it has
limited power against small departures, and the paper's own simulations show
where: against two thresholds whose jumps are small (their DGP-3 with
{it:delta} = 0.25) power is about 0.24 at {it:n} = 500 and only reaches 0.66
by {it:n} = 1,500. Against an added smooth drift in {it:q} it is much
stronger, about 0.72 at {it:n} = 500. So a non-rejection in a short sample is
weak evidence.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} gives the threshold variable {it:q}. Required.
Only its {bf:ordering} matters: the statistic is invariant to any strictly
increasing transformation of {it:q}, because every moment in the
construction is smoothed over ranks rather than over {it:q} itself. Taking
logs of {it:q}, or cubing it, returns exactly the same statistic with the
threshold reported on the new scale.

{phang}
{opt noconstant} removes the constant from the set of coefficients allowed to
switch. The constant is included by default, and included in the
{bf:switching} set, matching the paper: both {it:beta} and {it:delta} are
full-length vectors.

{phang}
{opt trim(#)} is the trimming fraction {it:tau}. Candidate thresholds, and
the interval over which the statistic is built, are confined to the ranks
strictly inside ({it:tau}, 1 - {it:tau}). The default 0.10 is the paper's and
{bf:is the setting to keep}. Values outside (0, 0.5) are refused.

{pmore}
It is the one option with a large effect on the result, so it is worth
knowing the direction. Measured on the paper's designs at {it:n} = 500 with a
small effect size, raising {it:tau} from 0.10 to 0.20 took size from 0.035 to
0.005 and power against a smooth drift from 0.93 to 0.49. {opt trim()} sets
how much of the range of {it:q} the statistic integrates over, so raising it
discards evidence along with the tails, and 0.10 is already the conservative
end of the trade-off. Raise it only for a reason {hline 2} a regressor
confined to one tail, or a refusal for a degenerate design moment {hline 2}
and report it when you do. See {helpb tvthresh_choose}.

{phang}
{opt gridn(#)} caps the number of threshold candidates by thinning them to
quantiles of {it:q}. Note that it is an {bf:upper bound, not the grid size}:
the quantiles are taken across the whole distribution and then trimmed, so
the surviving count is smaller, and {cmd:r(n_grid)} reports what was
actually used. Omit it, or give 0, to search every distinct value in the
trimmed range.

{phang}
{opt minobs(#)} sets a floor on the observations in each regime, in addition
to the floor that {opt trim()} already implies. Rarely needed.

{phang}
{opt bwidth(#)} is the bandwidth of the kernel smoothers. The default is the
paper's rule of thumb, sqrt(1/12) {it:n}^(-1/5), and the paper reports that
other reasonable choices change the results negligibly. The kernel is
Gaussian and is not an option, because the tabulated critical values are
pivotal and do not depend on it.

{phang}
{opt direction(#)} and {opt dvector(numlist)} both set the direction vector
{it:v} {hline 2} see {help tvthomog##direction:the next section}. They
cannot both be given.

{phang}
{opt level(#)} selects which of the paper's tabulated critical values to
decide at: 90, 95 or 99. Any other level is reported at 5% with a note. The
critical values come from a table, so interpolating one the paper does not
give would be inventing it; {cmd:r(cv90)}, {cmd:r(cv95)} and {cmd:r(cv99)}
are all returned so you can decide at any of the three without re-running.


{marker direction}{...}
{title:The direction vector v}

{pstd}
The statistic is built from a scalar projection of the score, and {it:v} is
the unit vector that projects it. The paper is explicit that {it:v} is a
{bf:user choice}, "guided by the empirical context", and that the limiting
distribution {bf:does not depend on it} as long as {it:v'v} = 1. So the test
is valid for any {it:v}; only its power varies, and the paper's footnote 6
reports that two quite different choices give "very similar" results.

{pstd}
Two ways to set it:

{phang2}
{opt direction(j)} uses {it:v} = {it:e_j}, which is the {it:j}th switching
coefficient on its own. This is what the paper's own application does, with
{it:j} = 1. It is the choice to make when one coefficient is the object of
interest.

{phang2}
{opt dvector(numlist)} gives {it:v} outright, one number per switching
coefficient. It is normalised internally, so only the direction matters and
{cmd:dvector(1 1)} and {cmd:dvector(5 5)} are the same thing. This is the
choice to make when reproducing the paper's Monte Carlo, which takes {it:v}
proportional to (1, 1/E[{it:x_2}{c 94}2])'.

{pstd}
{bf:The ordering.} {opt dvector()} follows the order of the coefficients as
Stata reports them, which means {bf:the constant comes last}:
{it:indepvars} in the order given, then {cmd:_cons}. The paper writes
{it:x} = (1, {it:x_2})' with the constant {bf:first}, so a {it:v} taken
from the paper has to be reordered. {cmd:r(v)} returns the vector actually
used, with column names, so the ordering can be checked rather than
assumed.


{marker method}{...}
{title:How it works}

{pstd}
Four steps, following the paper's own recipe.

{phang}
1. Fit the constant-threshold model by profile least squares, giving
{it:gammahat} and the residuals. This is the only estimation performed.

{phang}
2. Estimate the conditional moments {it:D}({it:r}) = E[{it:xx'} | {it:q} =
{it:Q}({it:r})] and {it:V}({it:r}) = E[{it:xx'u}{c 94}2 | {it:q} =
{it:Q}({it:r})] by Gaussian kernel smoothing {bf:over the rank} {it:i}/{it:n}
of {it:q}, with the regressors and residuals reordered by {it:q}. Smoothing
over ranks rather than over {it:q} is what lets the test avoid estimating the
density of {it:q} anywhere, and is why the statistic is invariant to a
monotone transformation of {it:q}.

{phang}
3. Build a weighted partial-sum process of the scores, rescale time by
{it:g}({it:r}), and split it at the rank of {it:gammahat}. The two halves,
standardised, behave as {bf:independent} standard Brownian bridges in the
limit. That independence is what makes the limit pivotal, and it is why the
split must be at the estimated threshold's own rank and not at an arbitrary
point.

{phang}
4. The statistic is the Cramer-von Mises functional of the pair,

{p 8 8 2}
CT {it:->d} integral from 0 to 1 of {it:B_2}({it:t})'{it:B_2}({it:t})
{it:dt}

{pstd}
with {it:B_2} a {bf:two}-dimensional standard Brownian bridge. Reject for
large CT. The 5% critical value is {bf:0.745}.

{pstd}
The form of the statistic {hline 2} an average of squared standardised
partial sums {hline 2} follows Nyblom (1989) and Elliott and Muller (2007),
and the tabulated critical values are the {it:k} = 2 case of the latter.
What is specific to this test is the rescaling of time by {it:g}({it:r}) and
the split at the estimated threshold, which together deliver two
{bf:independent} bridges from a problem in which the threshold has been
estimated.


{marker declines}{...}
{title:When the test declines}

{pstd}
{cmd:tvthomog} refuses rather than reporting a number it cannot stand behind.
Two cases arise in practice.

{phang}
{bf:The estimated threshold sits at the edge of the trimmed range} (exit
498). The construction standardises at {it:g}({it:r_0}), which requires
{it:r_0} strictly inside ({it:tau}, 1 - {it:tau}); at the edge the
standardisation divides by zero. Raise {opt trim()}, or check that {it:q}
really does split the sample. This also happens when the data have two
widely separated thresholds and the best single split is pushed to the
boundary.

{phang}
{bf:The smoothed design moment is not invertible at some rank} (exit 498,
with the rank and the condition number reported). {it:D}({it:r}) is estimated
from the observations whose rank in {it:q} is near that point, so a regressor
that is locally constant, or locally collinear with another, makes
{it:D}({it:r}) degenerate {bf:even when the full-sample design matrix has
full rank}. A dummy that switches on only in one tail of {it:q} is the usual
cause. Drop it, or {bf:raise} {opt trim()} so the affected tail is excluded
{hline 2} lowering {opt trim()} makes it worse.

{pstd}
Neither is a bug, and neither should be worked around by forcing a number
out of the command.

{pstd}
{bf:Between those and a healthy fit there is a continuum}, and
{cmd:tvthomog} reports where in it you are. {cmd:r(rcond)} is the worst
reciprocal condition number of {it:D}({it:r}) over the whole trimmed range,
measured in global column units so that it reflects collinearity and not the
units the regressors happen to be in: a clean design sits near 1, and the
command refuses below 1e-12. When it falls below 1e-6 the output carries a
note. The test is still valid there {hline 2} nothing about its distribution
depends on the conditioning {hline 2} but {it:a}({it:r}) is estimated
imprecisely over that stretch of {it:q}, so the statistic is noisier than its
nominal sample size suggests. A dummy confined to a tail of {it:q} is again
the thing to look for.


{marker examples}{...}
{title:Examples}

{pstd}Setup: a genuinely constant threshold at {it:q} = 0.{p_end}
{phang2}{cmd:. set seed 60221}{p_end}
{phang2}{cmd:. set obs 500}{p_end}
{phang2}{cmd:. generate double q  = rnormal()}{p_end}
{phang2}{cmd:. generate double x2 = rnormal()}{p_end}
{phang2}{cmd:. generate double y  = (1 + 0.75*(q<=0)) + x2*(1 + 0.75*(q<=0)) + rnormal()}{p_end}

{pstd}The test, at the paper's settings.{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(q)}{p_end}

{pstd}
With the paper's Monte Carlo direction vector. {it:x_2} is standard normal
here so E[{it:x_2}{c 94}2] = 1, and the constant comes last, so the paper's
(1, 1/E[{it:x_2}{c 94}2])' becomes {cmd:dvector(1 1)}.{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(q) dvector(1 1)}{p_end}

{pstd}The same data with the threshold variable transformed {hline 2} the
statistic does not move.{p_end}
{phang2}{cmd:. generate double logq = exp(q)}{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(logq)}{p_end}

{pstd}Now an alternative: a threshold {it:plus} a smooth drift in {it:q}.
This is the paper's DGP-2 and the test should reject.{p_end}
{phang2}{cmd:. replace y = (1 + 0.75*(q<=0) + abs(q)) + x2*(1 + 0.75*(q<=0) + abs(q)) + rnormal()}{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(q) dvector(1 1)}{p_end}

{pstd}Decide at 1% instead, and read the decision out of {cmd:r()}.{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(q) level(99)}{p_end}
{phang2}{cmd:. display r(CT) > r(cv99)}{p_end}

{pstd}A tighter trim, for a threshold variable with long tails.{p_end}
{phang2}{cmd:. tvthomog y x2, threshvar(q) trim(0.15)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvthomog} is {bf:r-class}. It fits no model that survives the command,
so nothing is left in {cmd:e()} and the estimation results in memory when it
is called are not disturbed.

{pstd}
{cmd:tvthomog} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(CT)}}the CT statistic{p_end}
{synopt:{cmd:r(reject)}}1 if rejected at {cmd:r(level)}, 0 otherwise{p_end}
{synopt:{cmd:r(level)}}the level the decision was taken at{p_end}
{synopt:{cmd:r(cv)}}the critical value used{p_end}
{synopt:{cmd:r(cv90)}}10% critical value, 0.600{p_end}
{synopt:{cmd:r(cv95)}}5% critical value, 0.745{p_end}
{synopt:{cmd:r(cv99)}}1% critical value, 1.067{p_end}
{synopt:{cmd:r(gamma)}}the threshold estimated under H0{p_end}
{synopt:{cmd:r(r0)}}its quantile rank{p_end}
{synopt:{cmd:r(g0)}}the rescaled split {it:g}({it:r_0}){p_end}
{synopt:{cmd:r(i_split)}}the split index, floor({cmd:r(g0)} * {cmd:r(N)}){p_end}
{synopt:{cmd:r(ssr)}}sum of squared residuals under H0{p_end}
{synopt:{cmd:r(bandwidth)}}the kernel bandwidth used{p_end}
{synopt:{cmd:r(rcond)}}worst reciprocal condition number of
{it:D}({it:r}){p_end}
{synopt:{cmd:r(trim)}}the trimming fraction{p_end}
{synopt:{cmd:r(direction)}}{it:j}, when {it:v} = {it:e_j}{p_end}
{synopt:{cmd:r(n_grid)}}threshold candidates actually searched{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of switching coefficients{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:tvthomog}{p_end}
{synopt:{cmd:r(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}names of the regressors{p_end}
{synopt:{cmd:r(threshvar)}}name of the threshold variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}the null fit, ({it:betahat}, {it:deltahat}){p_end}
{synopt:{cmd:r(v)}}the direction vector actually used{p_end}

{pstd}
{cmd:r()} is replaced wholesale by the next r-class command, so harvest what
you need immediately rather than after an intervening {helpb summarize}.


{marker validation}{...}
{title:Validation}

{pstd}
The critical values this command ships are reproduced by simulating the limit
process directly, and all seven of the paper's tabulated quantiles are
matched; the limit's analytic mean, exactly 1/3, is checked too. Size and
power are measured against the paper's own Monte Carlo designs and compared
with its reported rejection probabilities, at four effect sizes and on all
three of its data-generating processes. The exact invariances the
construction implies {hline 2} to a monotone transformation of {it:q}, to
the scale and location of {it:y}, and to the scale of {it:v} {hline 2} are
checked to machine precision, because each of them fails under a specific and
plausible mis-implementation.

{pstd}
No reference code was published with the paper, so this is a clean-room
implementation from the published equations. See
{bf:validation/tvthresh/tvthomog_equation_map.md} in the distribution for the
equation-by-equation concordance, the measured Monte Carlo comparison, and a
record of the implementation errors that comparison caught.


{marker references}{...}
{title:References}

{phang}
Lee, Y., and Y. Wang. 2024. Testing for homogeneous thresholds in threshold
regression models. {it:Econometric Theory} 40(3): 608-651.
{browse "https://doi.org/10.1017/S0266466622000512":doi:10.1017/S0266466622000512}

{phang}
Bai, J., and P. Perron. 1998. Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66(1): 47-78.
{browse "https://doi.org/10.2307/2998540":doi:10.2307/2998540}

{phang}
Elliott, G., and U. K. Muller. 2007. Confidence sets for the date of a single
break in linear time series regressions. {it:Journal of Econometrics} 141(2):
1196-1218.
{browse "https://doi.org/10.1016/j.jeconom.2007.02.001":doi:10.1016/j.jeconom.2007.02.001}

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based
inference in single and multiple threshold models. {it:Journal of
Econometrics} 110(2): 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68(3): 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}

{phang}
Nyblom, J. 1989. Testing for the constancy of parameters over time.
{it:Journal of the American Statistical Association} 84(405): 223-230.
{browse "https://doi.org/10.1080/01621459.1989.10478759":doi:10.1080/01621459.1989.10478759}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Manual:  {manlink R regress}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb regress}
{p_end}
