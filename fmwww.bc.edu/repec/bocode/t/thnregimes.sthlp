{smcl}
{* *! version 1.0.0  03oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thselect" "help thselect"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{viewerjumpto "Syntax" "thnregimes##syntax"}{...}
{viewerjumpto "Description" "thnregimes##description"}{...}
{viewerjumpto "Options" "thnregimes##options"}{...}
{viewerjumpto "gridn() and the sequential test" "thnregimes##gridsize"}{...}
{viewerjumpto "Why the non-adjacent tests matter" "thnregimes##triangle"}{...}
{viewerjumpto "Which bootstrap" "thnregimes##boot"}{...}
{viewerjumpto "thnregimes or thselect?" "thnregimes##versus"}{...}
{viewerjumpto "Examples" "thnregimes##examples"}{...}
{viewerjumpto "Stored results" "thnregimes##results"}{...}
{viewerjumpto "References" "thnregimes##refs"}{...}
{title:Title}

{phang}
{bf:thnregimes} {hline 2} How many regimes? The full triangle of sequential
threshold tests, with a recursive bootstrap for autoregressions


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thnregimes} {it:depvar} [{it:indepvars}] {ifin}{cmd:,}
{opth thresh:var(varname)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth threshvar(varname)}}the threshold variable{p_end}
{synopt:{opth inv:ariant(varlist)}}regressors whose coefficients do {it:not} switch{p_end}
{synopt:{opt maxthresh(#)}}largest number of thresholds to consider; default 2{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points{p_end}
{synopt:{opt refine(#)}}refinement sweeps after the sequential search{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 500, 0 for none{p_end}
{synopt:{opt boot(string)}}{opt normal} (default), {opt wild}, {opt recursive}, {opt recwild}{p_end}
{synopt:{opt arl:ags(numlist)}}lag order of each regressor that is a lag of {it:depvar}{p_end}
{synopt:{opt ql:ag(#)}}the threshold variable is this lag of {it:depvar}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt alpha(#)}}significance level for the sequential rule; default 0.10{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required. {cmd:thnregimes} is {cmd:rclass}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thnregimes} answers "how many regimes" by testing {it:i} thresholds
against {it:j} thresholds for {bf:every} pair {it:i} < {it:j} up to
{opt maxthresh()}, not only the adjacent pairs. Labels are in regimes:
{bf:F(2|1)} is one threshold against none, {bf:F(3|1)} is two thresholds
against none, {bf:F(3|2)} is two against one. With {cmd:maxthresh(2)} those
three are Hansen's (1999) {bf:F12}, {bf:F13} and {bf:F23}, and the command
generalises the battery to any number of thresholds.

{pstd}
Each statistic is the sequential F

{p 8 8 2}
F({it:j}|{it:i}) = {it:n} ( SSR({it:i}) - SSR({it:j}) ) / SSR({it:j})

{pstd}
and under the null of {it:i} thresholds the extra ones are unidentified, so
none of these is chi-squared and all of them are bootstrapped.

{pstd}
The second thing the command adds is a {bf:recursive bootstrap} for
autoregressive models. See {help thnregimes##boot:below}: this is not a
refinement, it is the difference between a valid and an invalid p-value when
the regressors are lags of the dependent variable.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is the threshold variable. For a self-exciting
autoregression it is a lag of {it:depvar}, and then {opt qlag()} should say
which lag so the bootstrap can rebuild it.

{phang}
{opth invariant(varlist)} lists regressors whose coefficients are common to
every regime. Everything in {it:indepvars} switches.

{phang}
{opt maxthresh(#)} is the largest number of thresholds considered, up to 6.
The cost is roughly quadratic in it, because the triangle has
{it:maxthresh}({it:maxthresh}+1)/2 entries and each one bootstraps two
sequential fits.

{phang}
{opt refine(#)} re-optimises each threshold with the others held fixed, after
the sequential search has placed them all. One sweep is usually enough and is
worth having: a threshold found first is conditional on a model that did not
yet contain the second.

{phang}
{opt gridn(#)} caps the number of candidate thresholds at {it:#} sample
quantiles. The default searches {bf:every} admissible order statistic, and
{bf:here that default matters more than it does elsewhere in this package} --
see {help thnregimes##gridsize:below} before setting it.

{phang}
{opt reps(0)} computes the statistics with no bootstrap. Useful for a quick
look at the SSR table and the F values before paying for p-values.

{phang}
{opt boot(normal|wild|recursive|recwild)} chooses the null data-generating
process; see {help thnregimes##boot:below}.

{phang}
{opt arlags(numlist)} is {bf:required} by {opt boot(recursive)} and
{opt boot(recwild)}. It gives the lag order of each regressor that is a lag of
{it:depvar}, in the order the regressors appear in {it:indepvars}. So for
{cmd:thnregimes y L1y L2y, arlags(1 2)} the first regressor is lag 1 and the
second is lag 2. A regressor that is not a lag of {it:depvar} is left out of
the list and held fixed, which is right for a genuinely exogenous variable.

{phang}
{opt qlag(#)} says the threshold variable is that lag of {it:depvar}, so the
recursive bootstrap rebuilds it from the simulated series {it:and} recomputes
its grid. Without it the threshold variable is held at its sample values,
which is a hybrid: honest for an exogenous threshold variable, wrong for a
self-exciting one.

{phang}
{opt alpha(#)} is the level at which the {it:sequential rule} stops. The rule
is reported as a rule, not as a truth.


{marker gridsize}{...}
{title:gridn() and the sequential test: a coarse grid inflates the size}

{pstd}
In the least-squares commands {opt gridn()} is a pure speed option: it cannot
improve the estimate and it leaves inference alone. {bf:Here it is not.} A
coarse grid makes the sequential tests {bf:over-reject}, so the rule chooses
{bf:too many} regimes.

{pstd}
The reason is worth understanding, because it tells you when it bites. The
bootstrap imposes the null by generating from the {bf:fitted} {it:i}-threshold
model, so the bootstrap data's threshold sits exactly {bf:on} a grid point --
it {it:is} a grid point. The real threshold does not. The observed
{it:i}-threshold fit therefore pays a grid-misalignment penalty that no
bootstrap draw ever pays, the extra threshold of the alternative partly
compensates for that penalty, and the observed statistic comes out too large
against a null distribution built without it.

{pstd}
Measured, on data with {bf:one} true threshold, {it:n} = 250, a slope
difference of 4 and unit errors, over the same fifteen data sets:

{p 8 8 2}
{cmd:gridn(20)}{space 6}F(3|2) rejected in {bf:6 of 15} at the 5% level{break}
default (full grid){space 1}F(3|2) rejected in {bf:2 of 15}

{pstd}
At fifteen replications 2 of 15 is within sampling noise of the nominal 5%, so
the {bf:default is sound} and the coarse grid roughly tripled the rejection
rate. The first test, F(2|1), was unaffected: it rejected in all fifteen,
correctly, because under {it:its} null there is no estimated threshold to be
misaligned. That contrast is the signature of the mechanism -- only the steps
whose null contains an estimated threshold are distorted.

{pstd}
{bf:What to do.} Leave {opt gridn()} alone -- the default is the full grid and
is the right choice for this command. If the sample is large enough that the
full grid is genuinely too slow, use {opt reps(0)} to look at the SSR and IC
table first, and treat a coarse-grid sequential p-value as a lower bound on
the true one. The same reasoning applies to the sequential bootstrap test in
{helpb thselect}, which is built the same way.

{marker triangle}{...}
{title:Why the non-adjacent tests matter}

{pstd}
The sequential rule stops at the first adjacent test that does not reject. That
is standard, and it can stop too early.

{pstd}
Suppose the true model has two thresholds that split the sample into three
regimes with the {it:outer} two similar to each other and the middle one
different. Fitting a single threshold then produces a bad model: it has to put
the dividing line somewhere, and wherever it goes it pools a part of the middle
regime with one of the outer ones. SSR(1) is barely below SSR(0), F(2|1) fails
to reject, and the sequence stops with one regime having never looked at two
thresholds — which would have fitted far better.

{pstd}
{bf:F(3|1) catches exactly that case.} It compares two thresholds with none
directly, bypassing the one-threshold model that the data has no use for. So
read the whole triangle: a pattern of {it:small} F(2|1) with {it:large} F(3|1)
is the signature of this situation and is not rare in practice.

{pstd}
The converse pattern — a large F(2|1) and an F(3|2) that does not reject — is
the ordinary case, and then the sequential rule and the triangle agree.


{marker boot}{...}
{title:Which bootstrap}

{synoptset 14}{...}
{p2col 5 14 18 2: boot()}what it does{p_end}
{p2line}
{p2col 5 14 18 2:{opt normal}}fixed regressors, iid normal errors. Hansen's
fixed-regressor convention. Correct when the regressors are exogenous.{p_end}
{p2col 5 14 18 2:{opt wild}}fixed regressors, each residual multiplied by one
standard normal draw. Same as above but robust to heteroskedasticity.{p_end}
{p2col 5 14 18 2:{opt recursive}}model based. The series is rebuilt
{it:forward} from the fitted null model with resampled residuals, and the
threshold variable is rebuilt with it when {opt qlag()} says so.{p_end}
{p2col 5 14 18 2:{opt recwild}}the same, with wild errors.{p_end}
{p2line}

{pstd}
{bf:The choice is not cosmetic.} A fixed-regressor bootstrap holds the
regressors at their sample values. In a cross-section that is exactly right:
the regressors are what they are, and only the errors are random. In an
{it:autoregression} the regressors {bf:are} lags of the dependent variable, so
holding them fixed while redrawing the errors generates a sample that could
not have come from the null model at all. The p-value is then for a null
nobody specified.

{pstd}
Hansen (1999) is explicit about this and uses the recursive scheme for
autoregressive threshold models. {cmd:thnregimes} refuses
{opt boot(recursive)} without {opt arlags()} rather than guessing which
regressors are lags, because guessing wrong produces a number that looks
fine and is not.

{pstd}
The recursive bootstrap keeps the first {it:max}({opt arlags()}, {opt qlag()})
observations at their observed values as a burn-in, so the simulated and
observed samples are comparable, and it recomputes the threshold grid in every
replication when {opt qlag()} is given — because a rebuilt threshold variable
has different order statistics.


{marker versus}{...}
{title:thnregimes or thselect?}

{synoptset 16}{...}
{p2col 5 16 20 2: question}command{p_end}
{p2line}
{p2col 5 16 20 2:how many regimes, by information criteria}{helpb thselect}{p_end}
{p2col 5 16 20 2:how many regimes, by adjacent sequential tests}{helpb thselect}{cmd:, test}{p_end}
{p2col 5 16 20 2:how many regimes, with the non-adjacent tests too}{cmd:thnregimes}{p_end}
{p2col 5 16 20 2:how many regimes in an {it:autoregression}}{cmd:thnregimes, boot(recursive)}{p_end}
{p2col 5 16 20 2:is there a threshold at all (one against none)}{helpb thtest}{p_end}
{p2line}

{pstd}
{helpb thselect} and {cmd:thnregimes} overlap deliberately: {cmd:thselect} is
the information-criterion command that also offers the adjacent tests, and
{cmd:thnregimes} is the testing command that also prints the criteria.
{cmd:thnregimes} adds the triangle and the recursive bootstrap; {cmd:thselect}
is quicker when you only want the criteria.

{pstd}
Whichever you use: {bf:having chosen the number of regimes from the data,
every p-value you report afterwards is conditional on that choice}, and the
honest thing is to say so. {helpb thnltest} is the step before this one — it
asks whether there is any nonlinearity to model.


{marker examples}{...}
{title:Examples}

{pstd}Cross-section: the whole triangle with the fixed-regressor bootstrap{p_end}
{phang2}{cmd:. use threshkit_dj}{p_end}
{phang2}{cmd:. thnregimes diff gdp60 iony pgro sch, threshvar(q) maxthresh(2) reps(1000) seed(1)}{p_end}

{pstd}A quick look first, with no bootstrap{p_end}
{phang2}{cmd:. thnregimes diff gdp60 iony pgro sch, threshvar(q) maxthresh(3) reps(0)}{p_end}

{pstd}An autoregression, where only the recursive bootstrap is valid{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. generate double l1 = L1.y}{p_end}
{phang2}{cmd:. generate double l2 = L2.y}{p_end}
{phang2}{cmd:. thnregimes y l1 l2, threshvar(l1) maxthresh(2) reps(500) ///}{p_end}
{phang2}{cmd:      boot(recursive) arlags(1 2) qlag(1) seed(7)}{p_end}

{pstd}Compare with the fixed-regressor p-value, to see what it costs{p_end}
{phang2}{cmd:. thnregimes y l1 l2, threshvar(l1) maxthresh(2) reps(500) seed(7)}{p_end}

{pstd}Then estimate with the number of regimes the triangle supports{p_end}
{phang2}{cmd:. thtar y, ar(1 2) delay(1) nthresh(2)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(n_grid)}}grid points searched{p_end}
{synopt:{cmd:r(m_seq)}}thresholds chosen by the sequential rule{p_end}
{synopt:{cmd:r(reps)}}, {cmd:r(alpha)}{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:r(boot)}}the bootstrap used{p_end}
{synopt:{cmd:r(threshvar)}}the threshold variable{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:r(seqtri)}}one row per pair: m0, m1, F, p, mcse, reps_used{p_end}
{synopt:{cmd:r(table)}}one row per m: m, SSR, aic, bic, hqic, bic_gp{p_end}


{marker refs}{...}
{title:References}

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based
inference in single and multiple threshold models.
{it:Journal of Econometrics} 110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under
the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Hansen, B. E. 1999. Testing for linearity. {it:Journal of Economic Surveys}
13: 551-576.
{browse "https://doi.org/10.1111/1467-6419.00098":doi:10.1111/1467-6419.00098}

{phang}
Bai, J. 1997. Estimating multiple breaks one at a time.
{it:Econometric Theory} 13: 315-352.
{browse "https://doi.org/10.1017/S0266466600005831":doi:10.1017/S0266466600005831}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit}, {helpb threshkit_choose}, {helpb thselect},
{helpb thtest}, {helpb thnltest}, {helpb thregress}, {helpb thtar}
{p_end}
