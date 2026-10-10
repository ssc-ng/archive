{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtvar" "help thtvar"}{...}
{vieweralsosee "thmtar" "help thmtar"}{...}
{viewerjumpto "Syntax" "thtvecm##syntax"}{...}
{viewerjumpto "Description" "thtvecm##description"}{...}
{viewerjumpto "Options" "thtvecm##options"}{...}
{viewerjumpto "The cointegrating vector, and why two steps are enough" "thtvecm##beta"}{...}
{viewerjumpto "The SupLM test" "thtvecm##test"}{...}
{viewerjumpto "Choosing between this and the alternatives" "thtvecm##choose"}{...}
{viewerjumpto "Postestimation" "thtvecm##postest"}{...}
{viewerjumpto "Examples" "thtvecm##examples"}{...}
{viewerjumpto "Stored results" "thtvecm##results"}{...}
{viewerjumpto "References" "thtvecm##refs"}{...}
{title:Title}

{phang}
{bf:thtvecm} {hline 2} Threshold vector error correction model, with the
Hansen-Seo SupLM test


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtvecm} {it:varlist} {ifin} [{cmd:,} {it:options}]

{pstd}
{it:varlist} holds two or more {it:I}(1) series believed to be cointegrated.
The data must be {helpb tsset}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lags(#)}}lags of the first differences; default 1{p_end}
{synopt:{opt beta(numlist)}}impose the cointegrating vector instead of estimating it{p_end}
{synopt:{opt joint:beta}}search {it:beta} and {it:gamma} jointly (full ML, bivariate only){p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt nocons:tant}}suppress the constants{p_end}
{synopt:{opt nthresh(#)}}1 (default) or 2; {cmd:nthresh(2)} fits the
three-regime band model{p_end}
{synopt:{opt restrict(string)}}{opt none} (default), {opt band} or
{opt equal}; needs {cmd:nthresh(2)}{p_end}
{synopt:{opt sls}}smoothed least squares, which gives the slopes valid
standard errors{p_end}
{synopt:{opt bwscale(#)}}multiply the smoothing bandwidth; default 1{p_end}
{synopt:{opt test}}compute the SupLM test and its bootstrap p-value{p_end}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 500{p_end}
{synopt:{opt boot(string)}}{opt resample} (default) or {opt wild}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thtvecm} fits the two-regime threshold vector error correction model of
Hansen and Seo (2002),

{p 8 8 2}
D{it:y_t} = {bf:A1}' {it:X_t}({it:beta}) 1{c -(}{it:w_t} <= {it:gamma}{c )-} +
{bf:A2}' {it:X_t}({it:beta}) 1{c -(}{it:w_t} > {it:gamma}{c )-} + {it:u_t}

{pstd}
where {it:w_t} = {it:beta}'{it:y_{t-1}} is the error-correction term and
{it:X_t} = (1, {it:w_t}, D{it:y_{t-1}}', ..., D{it:y_{t-p}}')'. The threshold
variable is the error-correction term itself: the regime is defined by how far
the system is from its own long-run equilibrium.

{pstd}
That is the economically interesting case. In regime 1 the system may barely
adjust at all while in regime 2 it adjusts fast, or the signs may differ. The
coefficient on {bf:ec} is the fraction of the equilibrium gap closed in one
period, so comparing it across regimes is the substantive output of the model;
{cmd:estat adjust} lays the two side by side with a Wald test that they are
equal.

{pstd}
Estimation is in two steps. The cointegrating vector comes first (from a
Johansen reduced-rank regression on the linear VECM, or from {opt beta()}), and
then {it:gamma} is the minimiser of the concentrated ln|Sigma| over a trimmed
grid of the error-correction term, with the regime coefficients by least
squares. Observations with {it:w_t} exactly equal to {it:gamma} belong to
regime 1.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} is the number of lagged first differences, so the corresponding
VAR in levels has {opt lags()}+1 lags. Choose it from the linear VECM before
looking for a threshold.

{phang}
{opt beta(numlist)} imposes the cointegrating vector, one number per variable,
and it is normalised by whatever you give (if you pass {cmd:beta(1 -1)} the
error-correction term is the first variable minus the second). Impose it when
theory gives it: a spread, a parity condition, a ratio in logs. Imposing a
known {it:beta} removes a nuisance parameter and makes the threshold better
identified. If {opt beta()} is omitted, the first element of the estimated
vector is normalised to 1, so the {it:first} variable in {it:varlist} should be
one with a non-zero loading.

{phang}
{opt jointbeta} searches the cointegrating vector and the threshold
{it:together} instead of taking {it:beta} from a first-stage linear VECM. This is
the full maximum-likelihood estimator of
{help thtvecm##refs:Hansen and Seo (2002)}: with {it:beta} normalised to
(1, {it:b})', the free element {it:b} is put on a grid of {opt gridn()} points
(20 when {opt gridn()} is not given), spanning
{it:b}-hat {c 177} (0.5|{it:b}-hat| + 0.5), and every ({it:b}, {it:gamma}) pair on
the resulting two-dimensional grid is evaluated by ln|{bf:Sigma}|. It matters
because the first-stage {it:beta} is estimated under {bf:linearity}, which is the
null being tested; if the threshold is real, that estimate is not consistent for
the threshold model's {it:beta}, and the error-correction term fed to the search
is then the wrong variable. The cost is {opt gridn()} times the one-dimensional
search. {cmd:e(beta_src)} and the header record whether the vector was refined
this way.

{pmore}
It requires a {bf:bivariate} system and {bf:refuses} otherwise: normalisation
leaves {it:k}-1 free elements, and the joint grid is implemented for the single
free element of the two-variable case. With more variables, impose the vector
with {opt beta()} on theoretical grounds instead. It also cannot be combined
with {opt sls}, which already searches the threshold with a differentiable
criterion of its own.

{phang}
{opt trim(#)} trims the grid of the error-correction term. Note that the
error-correction term is concentrated near zero by construction, so a given
trimming fraction can cut much more of the {it:range} than it would for a
diffuse threshold variable. Check with {cmd:estat ecplot}.

{phang}
{opt test} computes the Hansen-Seo SupLM test; see {help thtvecm##test:below}.

{phang}
{opt boot(resample|wild)} selects the bootstrap error generator, as in
{helpb thtvar}.


{marker beta}{...}
{title:The cointegrating vector, and why two steps are enough}

{pstd}
Hansen and Seo (2002) maximise the likelihood over {it:beta} and {it:gamma}
jointly. {cmd:thtvecm} estimates {it:beta} from the linear VECM and then
searches over {it:gamma}. That is not a shortcut taken for convenience: Seo
(2007) shows that in this model the cointegrating vector converges at rate
{it:n}^(3/2), far faster than the {it:n} rate of the short-run parameters and
the {it:n} rate of the threshold. {it:beta} is therefore {it:super}consistent
relative to everything else, and the first-step estimation error is of smaller
order than the sampling error in the parameters you care about. Seo also
establishes an asymptotic independence that leaves ordinary Wald tests on the
short-run parameters valid.

{pstd}
Two practical consequences. First, {cmd:estat adjust}'s Wald test that the
speeds of adjustment are equal across regimes is legitimate even though
{it:beta} was estimated. Second, the reported standard errors treat {it:beta}
as known; that understates the uncertainty by an amount of smaller order, which
is the standard and defensible position in this literature. If you want to see
how much {it:beta} matters, refit with {opt beta()} set to a plausible
alternative and compare: {bf:e(lndet)} and the threshold are both reported, and
the certification suite includes exactly that comparison.

{pstd}
What is {it:not} valid is to treat a {it:rejected} cointegration test as a
licence to fit this model. Establish cointegration first with
{helpb vecrank} (and, because threshold adjustment weakens linear
cointegration tests, consider the asymmetric alternative in
{helpb thmtar} with {opt coint}).


{marker test}{...}
{title:The SupLM test}

{pstd}
The null is a linear VECM; the alternative is the threshold VECM above. For a
fixed {it:gamma} the Hansen-Seo LM statistic is

{p 8 8 2}
LM({it:gamma}) = tr( {bf:D}' {bf:M}^-1 {bf:D} {bf:Sigma_0}^-1 )

{pstd}
built from the linear fit: {bf:D} is the moment condition that the two regimes'
coefficients are equal, {bf:M} is its variance, and {bf:Sigma_0} is the
residual covariance of the {it:linear} VECM. Using the linear covariance is the
point of an LM test: nothing has to be estimated under the alternative except
the partition.

{pstd}
Under the null {it:gamma} is unidentified, so SupLM is not chi-squared and the
critical values depend on the design. {cmd:thtvecm} simulates them with the
regressors and the error-correction term held fixed, redrawing only the errors.
{opt stat(ave)} and {opt stat(exp)} are also available and all three are stored;
they have more power when the two regimes differ moderately over a wide range
of {it:gamma} rather than sharply at one point.

{pstd}
Read the test together with {cmd:estat ecplot}. A rejection accompanied by a
threshold sitting out in the tail of the error-correction term, with one regime
holding a handful of observations, is a finding about a few episodes, not about
the system.


{marker three}{...}
{title:Three regimes: the band model}

{pstd}
{opt nthresh(2)} fits

{p 8 8 2}
D{it:y_t} = A1' {it:w_t-1} 1{c -}{it:w_t-1} {ul:<} {it:g1}{c )-} +
A2' {it:w_t-1} 1{c -}{it:g1} < {it:w_t-1} {ul:<} {it:g2}{c )-} +
A3' {it:w_t-1} 1{c -}{it:w_t-1} > {it:g2}{c )-} + {it:e_t}

{pstd}
where {it:w_t-1} collects the constant, the error-correction term
{it:beta'y_t-1} and the lagged differences. The two thresholds are searched
{bf:jointly} over every ordered pair on the trimmed grid, minimising
ln|Sigma| exactly as the two-regime fit does. That is a quadratic number of
cells: a 300-point grid gives roughly 45,000 fits, so the command is slower
than {cmd:nthresh(1)} by about that factor. {opt gridn()} caps it.

{pstd}
This is the structure Balke and Fomby (1997) argue for and Lo and Zivot
(2001) estimate: a {bf:band of inaction} around equilibrium, inside which
the gap is too small to be worth closing, with adjustment switching on
outside it. Transaction costs, menu costs and the width of a currency band
all produce it. Note the economics: in a band model the middle regime is
where {it:nothing} happens, so the interesting coefficients are the outer
ones, and the usual mistake is to report the middle regime's
error-correction coefficient as if its insignificance were a finding rather
than the hypothesis.

{pstd}
A three-regime model needs a much longer series than a two-regime one.
Every regime must hold more observations than there are regressors, and the
middle regime is bounded by {it:both} thresholds, so trimming bites twice.
If no ordered pair leaves all three regimes populated the command says so
and stops rather than returning a fit built on four observations.

{marker restrict}{...}
{title:The two restrictions, and why they are hypotheses}

{pstd}
{opt restrict(band)} holds the {bf:middle regime's error-correction
coefficient at zero} in every equation. Inside the band the system then
moves as a VAR in differences and does not adjust towards the long-run
relation at all. This is the band of inaction in its strict form.

{pstd}
{opt restrict(equal)} makes the {bf:two outer regimes share one coefficient
block}, so adjustment is symmetric above and below the band. The free fit
lets the system close a positive gap faster than a negative one of the same
size; {opt equal} says it does not.

{pstd}
Both are {bf:substantive restrictions, not conveniences}. Impose one only
after checking what it costs: refit without it and compare ln|Sigma|. The
restricted fit can never do better, since it is nested, so the question is
only whether it does much worse. On data with a genuine band the band
restriction costs almost nothing; on data that adjusts everywhere it costs a
great deal, and imposing it anyway would attribute to transaction costs
something the data say is not there.

{pstd}
Asymmetric adjustment is the common empirical finding, which is a reason to
treat {opt equal} with particular suspicion. If you cannot reject it, say
so; do not assume it.

{marker sls}{...}
{title:Smoothed least squares: standard errors you can use}

{pstd}
In a sharp threshold model the slope estimates and the threshold converge at
different rates and their limits are entangled, so the conventional standard
errors printed next to the slopes are {bf:not valid for inference}. That is
not a defect of this implementation; it is the model.

{pstd}
{opt sls} replaces the indicator 1{c -}{it:w} {ul:<} {it:g}{c )-} by the
integrated normal kernel

{p 8 8 2}
{it:Phi}(({it:g} {c -} {it:w})/{it:h})

{pstd}
which Seo (2011) shows makes the criterion differentiable in the threshold.
Three things follow. The slope estimates become asymptotically normal; they
become asymptotically {bf:independent} of the threshold; and therefore the
usual standard errors {bf:do} apply to them. This is the reason to use the
option: it is the only route in this command to a slope confidence interval
that means what it says.

{pstd}
The threshold itself still has {bf:no standard error}. Its limit is a
functional of a vector Brownian motion, not a normal. Report it as a point
estimate.

{pstd}
The bandwidth is {it:h} = {it:c} {c -}{it:sd}({it:w}){c )-} {it:n}^(-1/5),
the rate Seo uses, with {it:c} set by {opt bwscale()}. The rate matters:
{it:h} must shrink with {it:n} or the smoothed estimator is not consistent
for the sharp model at all. Because the constant is a choice, {bf:refit with
a different} {opt bwscale()} {bf:and check that the conclusions hold} — if
they move with the bandwidth, the data are not telling you where the
threshold is.

{pstd}
{opt sls} cannot be combined with {opt test}. The Hansen-Seo SupLM test is
derived for the sharp indicator and is not valid for the smoothed fit. Fit
twice: without {opt sls} for the test, with it for the slope standard
errors.

{marker seo}{...}
{title:estat seotest: a different null}

{pstd}
{cmd:estat seotest} runs Seo's (2006) sup-Wald test of

{p 8 8 2}
H0: there is {bf:no error correction in any regime} — the system is a VAR in
differences and there is no cointegration

{p 8 8 2}
H1: there {bf:is} error correction, in at least one outer regime —
threshold cointegration

{pstd}
This is {bf:not} the test that {opt test} reports, and confusing the two is
easy. {opt test} takes cointegration {it:as given} and asks whether
adjustment is threshold-dependent. {cmd:estat seotest} asks whether there is
any long-run relation at all, while allowing the alternative to be
regime-dependent — which matters because a linear cointegration test has
poor power against threshold adjustment, and may well say "no cointegration"
about a system that plainly has it.

{pstd}
The order to use them in: {cmd:estat seotest} first, {opt test} second. A
threshold VECM fitted to a system that fails the first is describing
adjustment towards a relation for which there is no evidence, and its
error-correction coefficients should not be reported as speeds of
adjustment.

{pstd}
Under the null {it:w_t-1} has a unit root, so the statistic's limit is
non-standard {bf:and} badly size-distorted at realistic sample lengths. Seo
therefore bootstraps under the unit-root null: the levels are rebuilt by
cumulating the residuals from the restricted fit, so each replication has no
cointegration by construction, and the threshold search is repeated inside
every replication. {bf:No asymptotic p-value is offered}, deliberately —
there is no table here that would be honest.

{pstd}
The cointegrating vector used is the {bf:fitted} one, not re-estimated
inside the test; re-estimating it under the alternative would change the
null being tested.

{marker choose}{...}
{title:Choosing between this and the alternatives}

{synoptset 16}{...}
{p2col 5 16 20 2: situation}command{p_end}
{p2line}
{p2col 5 16 20 2:cointegrated system, the whole adjustment structure switches
with the size of the disequilibrium}{helpb thtvecm}{p_end}
{p2col 5 16 20 2:cointegrated pair, only one adjustment equation of interest,
possibly asymmetric in the sign of the gap}{helpb thmtar}{p_end}
{p2col 5 16 20 2:cointegrated pair with a band of inaction, no adjustment while
inside transaction costs}{helpb thmtar} with {opt band}{p_end}
{p2col 5 16 20 2:cointegrated {it:system} with a band of inaction, the whole
short-run structure switching outside it}{cmd:thtvecm, nthresh(2)}{p_end}
{p2col 5 16 20 2:you need a usable standard error on an adjustment
speed}{cmd:thtvecm, sls}{p_end}
{p2col 5 16 20 2:you are not yet sure the system is cointegrated at
all}{cmd:estat seotest} first{p_end}
{p2col 5 16 20 2:stationary system, threshold on something other than a
disequilibrium}{helpb thtvar}{p_end}
{p2col 5 16 20 2:the state is a matter of degree, not a switch}{helpb thstvar}{p_end}
{p2line}

{pstd}
{cmd:thtvecm} and {cmd:thmtar} are not rivals so much as different scopes.
{cmd:thmtar} estimates one equation and gives you the Enders-Granger
asymmetry machinery; {cmd:thtvecm} estimates the system and lets the short-run
dynamics as well as the adjustment speed switch. If the two disagree about
whether adjustment is asymmetric, the single-equation result is the one to
distrust, because it conditions on the other equations.


{marker postest}{...}
{title:Postestimation}

{synoptset 22 tabbed}{...}
{synopt:{cmd:estat regimes}}regime sizes and the two coefficient matrices with
their difference{p_end}
{synopt:{cmd:estat adjust}}the speeds of adjustment side by side, with a
per-equation test and a joint Wald test that they are equal across regimes{p_end}
{synopt:{cmd:estat ecplot}}the error-correction term over time with the
threshold drawn{p_end}
{synopt:{cmd:estat bootdist}}the bootstrap distribution of SupLM;
{opt graph} draws it{p_end}
{synopt:{cmd:estat seotest}}Seo (2006) sup-Wald test of {bf:no}
cointegration against threshold cointegration, with a unit-root bootstrap;
{opt graph} draws the bootstrap distribution{p_end}
{synopt:{cmd:estat table}}a publication summary{p_end}
{synopt:{cmd:estat serial}}no residual autocorrelation, tested against the regime design{p_end}
{synopt:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{synopt:{cmd:estat normality}}Jarque-Bera, with its skewness and kurtosis components{p_end}
{synopt:{cmd:estat diag}}all three of the above in one table{p_end}

{pstd}
{bf:The residual diagnostics} ({cmd:estat serial}, {cmd:estat archlm},
{cmd:estat normality}, and {cmd:estat diag} for all three at once) test the
residuals against the {bf:regime-split VECM design} the estimator actually used,
so they ask whether anything is left over {it:after} the threshold has been
accounted for. They are {bf:system} tests, computed on all equations jointly
rather than one at a time, so a rejection does not identify which equation is at
fault. {opt lags(#)} sets the order of the serial-correlation and ARCH tests;
the default is 4. They matter more here than in a plain VECM:
the error-correction term is a {it:generated} regressor built from an estimated
{it:beta}, so a rejection can mean the cointegrating vector is wrong rather than
that the dynamics are. Check it against {opt beta()} imposed on theoretical
grounds before concluding the threshold is at fault.

{pstd}
{cmd:predict} supports {opt xb} and {opt residuals} (with {opt equation()}),
{opt ec} for the error-correction term, and {opt regime}. Note that the
dependent variables are the {it:first differences}, so {opt xb} predicts
D{it:y}, not {it:y}.


{marker examples}{...}
{title:Examples}

{pstd}Setup: the US term structure, which is Hansen and Seo's own application{p_end}
{phang2}{cmd:. use threshkit_rates}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. generate double lfcm3 = log(fcm3)}{p_end}
{phang2}{cmd:. generate double lftb3 = log(ftb3)}{p_end}

{pstd}Establish cointegration first{p_end}
{phang2}{cmd:. vecrank lftb3 lfcm3, lags(2)}{p_end}

{pstd}Fit and test{p_end}
{phang2}{cmd:. thtvecm lftb3 lfcm3, lags(1) test reps(500) seed(7)}{p_end}

{pstd}Where is the threshold relative to the disequilibrium itself?{p_end}
{phang2}{cmd:. estat ecplot}{p_end}

{pstd}The substantive result: does adjustment differ across regimes?{p_end}
{phang2}{cmd:. estat adjust}{p_end}

{pstd}Is there any cointegration to begin with? Ask before interpreting the
adjustment speeds{p_end}
{phang2}{cmd:. estat seotest, reps(499) seed(1)}{p_end}

{pstd}A band of inaction: three regimes, searched jointly{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) nthresh(2) trim(0.20)}{p_end}

{pstd}Is the band strict? Compare the restricted criterion with the free one{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) nthresh(2) trim(0.20) restrict(band)}{p_end}

{pstd}Is adjustment symmetric on the two sides of the band?{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) nthresh(2) trim(0.20) restrict(equal)}{p_end}

{pstd}Standard errors you can report on the adjustment speeds{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) sls}{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) sls bwscale(2)}{p_end}
{phang2}{cmd:. thtvecm y x, lags(1) sls bwscale(0.5)}{p_end}

{pstd}
The last three are one exercise, not three results: if the conclusions
change with the bandwidth, report that they do.{p_end}

{pstd}Impose the theoretical spread instead of estimating beta{p_end}
{phang2}{cmd:. thtvecm lftb3 lfcm3, lags(1) beta(1 -1) test reps(500) seed(7)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(gamma)}}threshold on the error-correction term{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}regime sizes{p_end}
{synopt:{cmd:e(lndet)}, {cmd:e(lndet0)}}ln|Sigma| of the fit and of the linear VECM{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(ll_0)}}log likelihoods{p_end}
{synopt:{cmd:e(lm)}}the requested statistic{p_end}
{synopt:{cmd:e(lm_sup)}, {cmd:e(lm_ave)}, {cmd:e(lm_exp)}}all three functionals{p_end}
{synopt:{cmd:e(gamma_test)}}argmax of the pointwise statistic{p_end}
{synopt:{cmd:e(p)}, {cmd:e(p_mcse)}}bootstrap p-value and its Monte Carlo s.e.{p_end}
{synopt:{cmd:e(lags)}, {cmd:e(k_var)}, {cmd:e(trim)}}dimensions and trimming{p_end}

{pstd}With {opt nthresh(2)}{p_end}
{synopt:{cmd:e(gamma1)}, {cmd:e(gamma2)}}the two thresholds, ordered{p_end}
{synopt:{cmd:e(N_regime1)}-{cmd:e(N_regime3)}}low, middle and high regime sizes{p_end}
{synopt:{cmd:e(n_cells)}}admissible threshold pairs searched{p_end}
{synopt:{cmd:e(k_coef)}}coefficients per equation{p_end}

{pstd}With {opt sls}{p_end}
{synopt:{cmd:e(bw)}}the bandwidth actually used{p_end}
{synopt:{cmd:e(bwscale)}}the multiplier supplied{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}observations with transition
weight above and below one half{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:e(beta_src)}}where the cointegrating vector came from{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}stacked coefficients and covariance{p_end}
{synopt:{cmd:e(A1)}, {cmd:e(A2)}}the two regime coefficient matrices{p_end}
{synopt:{cmd:e(beta)}}the cointegrating vector, normalised{p_end}
{synopt:{cmd:e(Sigma)}}residual covariance{p_end}
{synopt:{cmd:e(bdist)}}bootstrap distribution{p_end}
{synopt:{cmd:e(grid3)}}with {opt nthresh(2)}: every admissible (g1, g2, ln|Sigma|){p_end}
{synopt:{cmd:e(profile)}}with {opt sls}: the smoothed criterion over the grid{p_end}

{pstd}
{cmd:estat seotest} returns {cmd:r(sup)}, {cmd:r(ave)}, {cmd:r(exp)},
{cmd:r(stat)}, {cmd:r(gamma)}, {cmd:r(p)}, {cmd:r(N)}, {cmd:r(n_grid)},
{cmd:r(reps)}, {cmd:r(trim)}, the macros {cmd:r(teststat)} and
{cmd:r(boot)}, the matrix {cmd:r(path)} holding the statistic at every
threshold, and {cmd:r(bdist)} holding the bootstrap draws.


{marker refs}{...}
{title:References}

{phang}
Balke, N. S., and T. B. Fomby. 1997. Threshold cointegration.
{it:International Economic Review} 38: 627-645.
{browse "https://doi.org/10.2307/2527284":doi:10.2307/2527284}

{phang}
Hansen, B. E., and B. Seo. 2002. Testing for two-regime threshold
cointegration in vector error-correction models.
{it:Journal of Econometrics} 110: 293-318.
{browse "https://doi.org/10.1016/S0304-4076(02)00097-0":doi:10.1016/S0304-4076(02)00097-0}

{phang}
Lo, M. C., and E. Zivot. 2001. Threshold cointegration and nonlinear
adjustment to the law of one price.
{it:Macroeconomic Dynamics} 5: 533-576.
{browse "https://doi.org/10.1017/S1365100501023057":doi:10.1017/S1365100501023057}

{phang}
Seo, M. H. 2011. Estimation of nonlinear error correction models.
{it:Econometric Theory} 27: 201-234.
{browse "https://doi.org/10.1017/S026646661000023X":doi:10.1017/S026646661000023X}

{phang}
Seo, B. 2006. Bootstrap testing for the null of no cointegration in a threshold
vector error correction model. {it:Journal of Econometrics} 134: 129-150.
{browse "https://doi.org/10.1016/j.jeconom.2005.06.018":doi:10.1016/j.jeconom.2005.06.018}

{phang}
Seo, M. H. 2007. Estimation of nonlinear error-correction models. STICERD
Econometrics Discussion Paper EM/2007/517, London School of Economics.

{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit_choose}, {helpb thtvar}, {helpb thstvar},
{helpb thmtar}, {helpb vec}, {helpb vecrank}
{p_end}
