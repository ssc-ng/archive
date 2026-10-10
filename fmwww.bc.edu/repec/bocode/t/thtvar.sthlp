{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thstvar" "help thstvar"}{...}
{vieweralsosee "thtvecm" "help thtvecm"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{viewerjumpto "Syntax" "thtvar##syntax"}{...}
{viewerjumpto "Description" "thtvar##description"}{...}
{viewerjumpto "Options" "thtvar##options"}{...}
{viewerjumpto "Which multivariate threshold model?" "thtvar##choose"}{...}
{viewerjumpto "The test, and why it is bootstrapped" "thtvar##test"}{...}
{viewerjumpto "The log likelihood" "thtvar##ll"}{...}
{viewerjumpto "Postestimation" "thtvar##postest"}{...}
{viewerjumpto "Examples" "thtvar##examples"}{...}
{viewerjumpto "Stored results" "thtvar##results"}{...}
{viewerjumpto "References" "thtvar##refs"}{...}
{title:Title}

{phang}
{bf:thtvar} {hline 2} Threshold vector autoregression: two regimes, unknown
threshold, bootstrap test of linearity


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtvar} {it:varlist} {ifin}{cmd:,} {opt lags(#)} [{it:options}]

{pstd}
{it:varlist} holds two or more time series. The data must be {helpb tsset}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt lags(#)}}lags of every variable in the system{p_end}
{synopt:{opth thv:ar(varname)}}threshold variable; default {cmd:L}{it:d}{cmd:.}{it:first variable}{p_end}
{synopt:{opt delay(#)}}delay {it:d} for the default threshold variable; default 1{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points; default: every order statistic{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt nthresh(#)}}number of thresholds, 1 to 4; default 1{p_end}
{synopt:{opt refine(#)}}refinement sweeps when {cmd:nthresh()} > 1; default 0{p_end}
{synopt:{opt nocons:tant}}suppress the constants{p_end}
{synopt:{opt test}}compute the linearity test and its bootstrap p-value{p_end}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 500{p_end}
{synopt:{opt boot(string)}}{opt resample} (default) or {opt wild}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thtvar} fits the two-regime threshold vector autoregression

{p 8 8 2}
{it:y_t} = {bf:B1}' {it:w_t} 1{c -(}{it:q_t} <= {it:gamma}{c )-} +
{bf:B2}' {it:w_t} 1{c -(}{it:q_t} > {it:gamma}{c )-} + {it:e_t}

{pstd}
with {it:w_t} = (1, {it:y_{t-1}}', ..., {it:y_{t-p}}')'. The whole coefficient
matrix changes at the threshold, so the system switches regime as a block: it
is one model of the economy below the threshold and a different one above.

{pstd}
Inside a regime every equation has the {it:same} regressors, so least squares
equation by equation is the Gaussian maximum likelihood estimator and the
concentrated objective collapses to {bf:ln|Sigma(gamma)|}. {cmd:thtvar}
therefore searches a one-dimensional grid, evaluating each candidate in
{it:O(kw^3)} after a single {it:O(T kw^2)} pass: the cross-product blocks are
accumulated incrementally along the sorted threshold variable, so a grid of
every order statistic costs little more than a grid of thirty points.

{pstd}
The threshold is estimated jointly with everything else, by taking the
minimiser of {bf:ln|Sigma|}; it is not chosen in a first step and then
conditioned on. Observations with {it:q_t} exactly equal to {it:gamma} belong
to regime 1, as in the whole THRESHKIT package.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} is the lag order of the system. Choose it {it:before} looking for
a threshold, from the linear VAR: {helpb varsoc} on the same sample is the
natural tool. Searching lags and thresholds at the same time invalidates both
sets of p-values.

{phang}
{opth thvar(varname)} gives the threshold variable explicitly. It may be a
lag of a variable in the system, a transformation of them (a spread, a moving
average), or an outside variable. A contemporaneous variable makes the model
simultaneous and is almost never what you want: use a lag.

{phang}
{opt delay(#)} sets the delay {it:d} when no {opt thvar()} is given, in which
case the threshold variable is {cmd:L}{it:d}{cmd:.}{it:first variable of
varlist}. Searching over {it:d} by refitting invalidates the nominal p-value of
the linearity test in the same way that searching over lags does; if you do
search, report that you did and bootstrap over the whole procedure.

{phang}
{opt trim(#)} is the fraction of the sorted threshold variable excluded at each
end, so that no regime is too small to estimate. 0.15 is the convention. Below
about 0.10 the sup statistic starts to be driven by the tails.

{phang}
{opt minobs(#)} imposes a floor on the number of observations in a regime,
over and above what {opt trim()} implies. With {it:k} equations and {it:kw}
regressors, a regime needs well over {it:kw} observations before the regime
covariance is usable.

{phang}
{opt nthresh(#)} fits {it:#} thresholds, giving {it:#}+1 regimes, and is limited
to 4. They are found {it:sequentially}: each stage adds the grid point that most
reduces ln|Sigma| given the thresholds already found. The limit is not arbitrary.
A threshold VAR with {it:k} equations, {it:p} lags and {it:#}+1 regimes has
({it:#}+1){it:k}({it:kp}+1) coefficients and a regime covariance to estimate in
each regime, so the parameter count grows fast enough that a fifth threshold
cannot be estimated from any series this command is likely to be given.

{phang}
{opt refine(#)} runs up to {it:#} refinement sweeps after the sequential search,
each re-optimising one threshold at a time holding the others fixed, stopping
early when a sweep moves nothing. The sequential path minimises stage by stage
and need not reach the joint minimum; this recovers most of the difference at
{it:#} times the cost of one search rather than the cost of an {it:#}-dimensional
one.

{phang}
{bf:What {opt test} tests changes with {opt nthresh()}.} With one threshold the
null is {bf:linearity} and the statistic is the {opt stat()} functional of the
pointwise LR over the grid. With {cmd:nthresh()} = {it:m} > 1 the null is
{bf:{it:m}-1 thresholds against {it:m}}, and the statistic is the plain LR: there
is no sup to take, because {it:m}-1 of the thresholds are already in the model and
only the new one is being searched over. {cmd:e(test_m0)} and {cmd:e(test_m1)}
record which pair was tested and {cmd:e(teststat)} becomes {cmd:lr}, so the
output never leaves it ambiguous. To build up the number of regimes, run the
sequence {cmd:nthresh(1)}, {cmd:nthresh(2)}, ... and stop at the first
non-rejection; note that the overall size of such a sequence is not the nominal
size of any single step.

{phang}
{opt test} computes the linearity test. It costs {opt reps()} refits of the
whole grid, so it is not done unless asked.

{phang}
{opt stat(sup|ave|exp)} selects which functional of the pointwise statistic is
reported and bootstrapped. See {help thtvar##test:the test} below.

{phang}
{opt boot(resample|wild)} selects the bootstrap error generator:
{opt resample} resamples the rows of the linear VAR residual matrix, which
keeps the contemporaneous covariance across equations intact; {opt wild}
multiplies each residual vector by one standard normal draw, which also keeps
that covariance and is more robust to conditional heteroskedasticity.


{marker choose}{...}
{title:Which multivariate threshold model?}

{pstd}
Four commands cover the multivariate threshold family. They differ in what
switches and in how it switches.

{synoptset 16}{...}
{p2col 5 16 20 2: command}what it is{p_end}
{p2line}
{p2col 5 16 20 2:{helpb thtvar}}threshold VAR: all coefficients jump at an
observed threshold. Use when regimes are genuinely discrete (a binding
constraint, a policy switch, a credit limit).{p_end}
{p2col 5 16 20 2:{helpb thstvar}}smooth transition VAR: the same two regimes,
but the economy moves between them gradually. Use when the state is a matter of
degree (how deep a recession is, how tight financial conditions are).{p_end}
{p2col 5 16 20 2:{helpb thtvecm}}threshold VECM: the variables are
cointegrated and it is the {it:speed of adjustment} that switches, with the
error-correction term itself as the threshold variable.{p_end}
{p2col 5 16 20 2:{helpb thmtar}}single-equation asymmetric adjustment, and with
{opt band} a band of inaction. Use when only one adjustment equation is of
interest.{p_end}
{p2line}

{pstd}
Two practical tests of {cmd:thtvar} against {cmd:thstvar}. First fit
{cmd:thstvar} and run {cmd:estat transition}: if nearly every observation sits
in a corner ({it:G} < .1 or {it:G} > .9) the transition is effectively sharp
and {cmd:thtvar} is the simpler, better-identified model. Second, compare BIC;
they are computed on the same scale (see {help thtvar##ll:the log likelihood}).
If the two disagree about where the regimes lie, that disagreement is the
finding, and both should be reported.

{pstd}
If the series are {it:I}(1) and cointegrated, {cmd:thtvar} on the levels is
misspecified and {cmd:thtvar} on the differences throws away the long-run
relation. Use {helpb thtvecm}.


{marker test}{...}
{title:The test, and why it is bootstrapped}

{pstd}
The pointwise likelihood-ratio statistic is

{p 8 8 2}
LR({it:gamma}) = {it:n} ( ln|{bf:Sigma_0}| - ln|{bf:Sigma}({it:gamma})| )

{pstd}
where {bf:Sigma_0} is the linear VAR covariance. Under the null of a linear VAR
the threshold does not appear in the model at all, so it is {it:unidentified}
and LR({it:gamma}) is not asymptotically chi-squared for any fixed
{it:gamma}, let alone at its maximiser. This is the Davies problem; in this
setting it is Hansen (1996).

{pstd}
Three functionals are reported. {opt sup} takes the maximum over the grid and
has most power against a single sharp break. {opt ave} averages, and {opt exp}
takes ln of the average of exp(LR/2); both are the optimal tests of Andrews and
Ploberger (1994) against particular alternatives and have more power when the
regime difference is spread out rather than concentrated. Reporting all three
(they are all stored) is good practice: if they disagree, the evidence for two
regimes is not robust.

{pstd}
The p-value comes from a {it:fixed-regressor} bootstrap. The regressors
{it:w_t} and the threshold variable {it:q_t} are held at their sample values;
only the errors are redrawn, and the series are {it:not} rebuilt recursively.
That is deliberate: the asymptotic null distribution depends on the regressors,
which the fixed-regressor scheme reproduces exactly, and it avoids having to
take a stand on the dynamics under the null. The Monte Carlo standard error of
the p-value is reported as {bf:e(p_mcse)}; if it is large relative to the
distance from your significance level, raise {opt reps()}.

{pstd}
Two cautions. The test answers "is there a threshold at all", not "is the
threshold here". For the second question look at the profile
({cmd:estat profile, graph}): a flat profile means a weakly identified
threshold even when the test rejects decisively. And because the test is a
test of the whole system, rejection does not tell you which equations differ
across regimes; {cmd:estat regimes} and the coefficient table do.


{marker ll}{...}
{title:The log likelihood}

{pstd}
{cmd:thtvar} reports

{p 8 8 2}
ln {it:L} = -({it:n}/2) ( {it:k}(ln 2{it:pi} + 1) + ln|{bf:Sigma}| )

{pstd}
with {bf:Sigma} = {bf:S}/{it:n}. The RATS replication of Tsay (1998)
distributed by Estima records that the published paper used
-({it:T}/2) ln|{it:T} {bf:Sigma}| instead, which is larger by
({it:T k}/2) ln {it:T}. That constant cancels when two models are compared on
the {it:same} sample, so Tsay's reported differences stand, but it does not
cancel across samples and it inflates every information criterion. THRESHKIT
uses the form above throughout, so its AIC, BIC and HQIC are comparable with
official {helpb var} and with {cmd:thstvar} and {cmd:thtvecm}.


{marker postest}{...}
{title:Postestimation}

{pstd}
{cmd:estat} subcommands:

{synoptset 22 tabbed}{...}
{synopt:{cmd:estat profile}}the profile of ln|Sigma| over the grid;
{opt graph} draws it with the estimate and the linear-VAR level marked{p_end}
{synopt:{cmd:estat regimes}}regime sizes and the two coefficient matrices,
with their difference{p_end}
{synopt:{cmd:estat stability}}the largest companion-matrix eigenvalue modulus
of each regime{p_end}
{synopt:{cmd:estat bootdist}}the bootstrap distribution of the test
statistic; {opt graph} draws it{p_end}
{synopt:{cmd:estat girf}}generalised impulse response{p_end}
{synopt:{cmd:estat irf}}regime-specific {it:conditionally linear} impulse
responses{p_end}
{synopt:{cmd:estat fevd}}the matching forecast-error variance
decomposition{p_end}
{synopt:{cmd:estat table}}a publication summary{p_end}
{synopt:{cmd:estat serial}}no residual autocorrelation, tested against the regime design{p_end}
{synopt:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{synopt:{cmd:estat normality}}Jarque-Bera, with its skewness and kurtosis components{p_end}
{synopt:{cmd:estat diag}}all three of the above in one table{p_end}

{pstd}
{bf:The residual diagnostics} ({cmd:estat serial}, {cmd:estat archlm},
{cmd:estat normality}, and {cmd:estat diag} for all three at once) test the
fitted residuals against the {bf:regime-split design} -- the same columns the
estimator used, which for a jump-threshold VAR is its gradient -- rather than
against an unsplit VAR, so they ask whether anything is left over {it:after} the
thresholds have been accounted for. They are {bf:system} tests, computed on all
equations jointly rather than one at a time, so a single rejection does not say
which equation is at fault. {opt lags(#)} sets the order of the serial-correlation
and ARCH tests; the default is 4. A rejection from {cmd:estat serial} says
{opt lags()} is too short rather than that the threshold is wrong: fix the lag
order first and re-search, because a threshold fitted to serially correlated
residuals can pick up dynamics that belong in the lag structure.

{pstd}
{cmd:estat stability} deserves a word. A single regime of a threshold model
{it:may} be explosive while the whole process is stationary and ergodic,
because the process leaves that regime. What matters is the {it:outer} regime:
if the regime the process visits when it is far from the threshold is
explosive, nothing pulls it back and the model has no stationary law. An inner
regime with a unit root is the band-of-inaction case and is perfectly normal
(compare {cmd:thmtar, band}).

{pstd}
{cmd:estat girf} computes the generalised impulse response of Koop, Pesaran and
Potter (1996). A threshold model has no single impulse response: the effect of
a shock depends on the history, and on the sign and size of the shock, because
a shock can push the process across the threshold. Each response is therefore
averaged over simulated futures,

{p 8 8 2}
GIRF({it:h}, {it:delta}, {it:omega}) = E[{it:y_{t+h}} | {it:e_t} =
{it:delta}, {it:omega}] - E[{it:y_{t+h}} | {it:omega}]

{pstd}
with the two paths driven by the {it:same} future shocks, so the difference is
the effect of {it:delta} and not simulation noise. {opt compare} computes it
separately from regime-1 and regime-2 histories, which is usually the result
worth reporting. Options: {opt shock()}, {opt size()} in standard deviations,
{opt horizon()}, {opt histories(low|high|#)}, {opt reps()},
{opt nocholesky}, {opt graph}, {opt seed()}. By default the shock is the
Cholesky column of {bf:e(Sigma)} for the shocked variable, so the ordering of
{it:varlist} is the identifying assumption; {opt nocholesky} shocks that
equation alone.


{pstd}
{cmd:estat irf} and {cmd:estat fevd} compute the {bf:conditionally linear}
responses, which answer a {it:different question} from {cmd:estat girf}, and
the difference matters enough that both tables say so on their face.

{pstd}
Take one regime's coefficient matrix and treat it as a linear VAR: form the
companion matrix, and let {&Psi}{subscript:h} be the upper-left k x k block of
its h-th power. That is the propagation you would see {it:if the system stayed
in that regime forever}. {cmd:estat girf} instead simulates the actual
nonlinear system, in which a shock may push the process across the threshold
and change the dynamics for the rest of the horizon.

{pstd}
Neither is an approximation to the other:

{p 8 8 2}
o the {bf:conditionally linear} response isolates a regime's own dynamics from
the probability of leaving it, which is what you want when the economic
question is "how does this state propagate shocks";{p_end}
{p 8 8 2}
o the {bf:generalised} response includes the chance of leaving, which is what
you want when the question is "what happens if I shock this system now".{p_end}

{pstd}
Reporting the first as "the impulse response of the threshold VAR" would be
wrong. Say which one you used.

{pstd}
Three things to read in the output.

{phang2}
{bf:1. The maximum eigenvalue modulus per regime.} If it is 1 or more, that
regime's conditional response {bf:diverges}. This is correct arithmetic, not a
failure: a threshold model can be globally stationary with one locally
explosive regime, and that is often the interesting finding. Do not read the
long-horizon numbers for that regime as a forecast. Compare
{cmd:estat stability}.

{phang2}
{bf:2. The innovation covariance.} After {helpb thtvar} each regime is
orthogonalised with its {bf:own} {&Sigma}, estimated from that regime's
residuals, because a conditionally linear system in regime j has regime j's
innovation covariance — and the regimes usually differ in variance, which is
often why the threshold was found. Both are returned, along with the pooled
one, so the choice can be inspected. After {helpb thstvar} there is no regime
membership to split the residuals by, so the model's single {&Sigma} is used
for both limiting systems and the output says so; dichotomising the transition
function at 0.5 to manufacture a split would produce numbers for a model you
did not fit.

{phang2}
{bf:3. The Cholesky ordering} is the order of {it:varlist}, and it is an
identifying assumption: shock m cannot affect variables before m within the
period. {opt nocholesky} reports the response to a unit innovation instead,
which needs no ordering but is not a response to an economically interpretable
shock.

{pstd}
Options: {opt horizon()}, {opt nocholesky}, {opt regime(1|2)} to print one
regime only, {opt reps()} and {opt level()} for a percentile band,
{opt wild} for a wild rather than a resampling bootstrap, {opt seed()},
{opt graph} and {opt saving()}.

{pstd}
{bf:What the band does and does not cover.} With {opt reps()} the regime
indicator and the regressors are held {bf:fixed} and only the residuals are
resampled; both regimes are refitted and the responses recomputed. The band
therefore conditions on the regime classification — which is exactly what a
conditionally linear response already conditions on, so the band is
internally consistent with the object it surrounds. It does {bf:not} include
uncertainty about the threshold or about which observations belong to which
regime, and a band that did would be wider. {opt reps()} is refused after
{helpb thstvar}, because there the band would need {&gamma} and c
re-estimated in every draw.

{pstd}
{cmd:predict} supports {opt xb}, {opt residuals} (both with
{opt equation()}) and {opt regime}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_rates}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Choose the lag order from the linear VAR first{p_end}
{phang2}{cmd:. varsoc g3month g3year, maxlag(6)}{p_end}

{pstd}Fit, with the smoothed spread as the threshold variable, and test{p_end}
{phang2}{cmd:. thtvar g3month g3year, lags(2) thvar(L.sspread) test reps(500) seed(1)}{p_end}

{pstd}Look at the profile before believing the threshold{p_end}
{phang2}{cmd:. estat profile, graph}{p_end}

{pstd}The two regimes side by side, and their stability{p_end}
{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat stability}{p_end}

{pstd}Self-exciting threshold, so a generalised impulse response is available{p_end}
{phang2}{cmd:. thtvar g3month g3year, lags(2) delay(1)}{p_end}
{phang2}{cmd:. estat girf, shock(g3month) horizon(24) compare graph seed(7)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(gamma)}}threshold estimate{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}regime sizes{p_end}
{synopt:{cmd:e(lndet)}, {cmd:e(lndet0)}}ln|Sigma| of the fit and of the linear VAR{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(ll_0)}}log likelihoods{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(hqic)}}information criteria{p_end}
{synopt:{cmd:e(lr)}}the requested statistic{p_end}
{synopt:{cmd:e(lr_sup)}, {cmd:e(lr_ave)}, {cmd:e(lr_exp)}}all three functionals{p_end}
{synopt:{cmd:e(gamma_test)}}argmax of the pointwise statistic{p_end}
{synopt:{cmd:e(p)}, {cmd:e(p_mcse)}}bootstrap p-value and its Monte Carlo s.e.{p_end}
{synopt:{cmd:e(k_var)}, {cmd:e(lags)}, {cmd:e(trim)}}dimensions and trimming{p_end}
{synopt:{cmd:e(girf_ok)}}1 if {cmd:estat girf} can be simulated{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}stacked coefficients and covariance{p_end}
{synopt:{cmd:e(B1)}, {cmd:e(B2)}}the two regime coefficient matrices{p_end}
{synopt:{cmd:e(Sigma)}}residual covariance{p_end}
{synopt:{cmd:e(profile)}}the grid and ln|Sigma| at each point{p_end}
{synopt:{cmd:e(bdist)}}bootstrap distribution{p_end}


{marker refs}{...}
{title:References}

{phang}
Andrews, D. W. K., and W. Ploberger. 1994. Optimal tests when a nuisance
parameter is present only under the alternative. {it:Econometrica} 62: 1383-1414.
{browse "https://doi.org/10.2307/2951753":doi:10.2307/2951753}

{phang}
Balke, N. S. 2000. Credit and economic activity: credit regimes and nonlinear
propagation of shocks. {it:Review of Economics and Statistics} 82: 344-349.
{browse "https://doi.org/10.1162/rest.2000.82.2.344":doi:10.1162/rest.2000.82.2.344}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under
the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis in
nonlinear multivariate models. {it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}

{phang}
Lo, M. C., and E. Zivot. 2001. Threshold cointegration and nonlinear adjustment
to the law of one price. {it:Macroeconomic Dynamics} 5: 533-576.
{browse "https://doi.org/10.1017/S1365100501023057":doi:10.1017/S1365100501023057}

{phang}
Tsay, R. S. 1998. Testing and modeling multivariate threshold models.
{it:Journal of the American Statistical Association} 93: 1188-1202.
{browse "https://doi.org/10.1080/01621459.1998.10473779":doi:10.1080/01621459.1998.10473779}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit_choose}, {helpb thstvar}, {helpb thtvecm},
{helpb thtar}, {helpb thmtar}, {helpb var}, {helpb varsoc}
{p_end}
