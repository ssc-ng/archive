{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "START HERE: find your situation" "threshkit_choose##start"}{...}
{viewerjumpto "The whole package at a glance" "threshkit_choose##glance"}{...}
{viewerjumpto "Step 1: is it a threshold at all?" "threshkit_choose##step1"}{...}
{viewerjumpto "Step 2: which model class?" "threshkit_choose##step2"}{...}
{viewerjumpto "Step 3: which test?" "threshkit_choose##step3"}{...}
{viewerjumpto "Step 4: which confidence interval?" "threshkit_choose##step4"}{...}
{viewerjumpto "Step 5: how many regimes?" "threshkit_choose##step5"}{...}
{viewerjumpto "Step 6: systems of equations" "threshkit_choose##step6"}{...}
{viewerjumpto "Step 7: which threshold variable?" "threshkit_choose##step7"}{...}
{viewerjumpto "Step 8: is the series even stationary?" "threshkit_choose##step8"}{...}
{viewerjumpto "Step 9: are the regressors endogenous?" "threshkit_choose##step9"}{...}
{viewerjumpto "Step 10: forecasting a threshold model" "threshkit_choose##step10"}{...}
{viewerjumpto "Step 11: impulse responses -- which one?" "threshkit_choose##step11"}{...}
{viewerjumpto "Reporting checklist" "threshkit_choose##report"}{...}
{viewerjumpto "Common mistakes" "threshkit_choose##mistakes"}{...}
{viewerjumpto "References" "threshkit_choose##refs"}{...}
{title:Title}

{phang}
{bf:threshkit choose} {hline 2} A researcher's guide: choosing the model, the test
and the confidence interval for threshold analysis

{marker intro}{...}
{title:Why this page exists}

{pstd}
Threshold modelling goes wrong in predictable ways. A researcher picks a model whose
assumptions the data violate, tests the wrong null, or reports a confidence interval
that is invalid for the estimator that produced it. This page is the decision tree.
Each step states {it:what to ask}, {it:what the answer implies}, and {it:what the
theory forbids}. Every claim is sourced.

{pstd}
Read it top to bottom once before your first threshold paper. After that use the
jump links.

{marker start}{...}
{title:START HERE: find your situation}

{pstd}
The eleven steps below are the full argument, and they are worth reading once
in order. This table is for every time after that. Find the row that sounds
like {it:your} problem -- the wording is deliberately how a researcher would
describe the situation, not how the method is named, because that gap is what
makes a large package hard to enter.

{synoptset 34 tabbed}{...}
{p2coldent:{bf:My situation}}{bf:Start with}{p_end}
{synoptline}
{syntab:Cross-section}
{p2col:"The effect of x on y might differ above and below some level of z"}{helpb thtest} then {helpb thregress}{p_end}
{p2col:"The relationship bends rather than jumps"}{helpb thkink}{p_end}
{p2col:"I don't know whether it bends or jumps"}{helpb thkink} then {cmd:estat continuity}{p_end}
{p2col:"The change is gradual, not sudden"}{helpb thstr}{p_end}
{p2col:"I care about the tails, not the mean"}{helpb thqreg}, {helpb thqtest}{p_end}
{p2col:"A regressor is endogenous"}{helpb thivreg}, {helpb thivtest}{p_end}
{p2col:"The THRESHOLD VARIABLE is endogenous"}{helpb thendog} -- and read its consistency warning{p_end}
{p2col:"Two regimes or three?"}{helpb thnregimes}, {helpb thselect}, {helpb thnseq}{p_end}
{p2col:"Which variable splits the sample?"}{helpb thsearch}{p_end}

{syntab:One time series}
{p2col:"My series behaves differently in booms and recessions"}{helpb thtar}{p_end}
{p2col:"...and the dynamics look richer in one regime"}{helpb thsubtar}{p_end}
{p2col:"I don't know the lag order, delay or regime count"}{helpb thtarsel}{p_end}
{p2col:"The switch is smooth, not sharp"}{helpb thstar}, then {helpb thstarcycle}{p_end}
{p2col:"Logistic or exponential transition?"}{helpb thstrtype}{p_end}
{p2col:"Adjustment is faster upward than downward"}{helpb thmtar}{p_end}
{p2col:"My model has a moving-average part"}{helpb thtarma}{p_end}
{p2col:"I want the tails of a time series"}{helpb thtqar}{p_end}
{p2col:"Is it a unit root, or a threshold that looks like one?"}{helpb thunitroot}{p_end}
{p2col:"...with a band of inaction in the middle"}{helpb thbandur}{p_end}
{p2col:"I need forecasts from a nonlinear model"}{helpb thforecast}{p_end}

{syntab:Systems}
{p2col:"Two or more series, with regimes"}{helpb thtvar}{p_end}
{p2col:"...and they are cointegrated"}{helpb thtvecm}{p_end}
{p2col:"...and the regime change is gradual"}{helpb thstvar}{p_end}
{p2col:"Lag order and delay for a system"}{helpb thtvarsel}{p_end}
{p2col:"The response to a shock depends on the state"}{cmd:estat girf} after any of them{p_end}

{syntab:Whatever the model}
{p2col:"How confident am I about WHERE the threshold is?"}{helpb threshkit_choose##step4:Step 4}, and {helpb thsubci}{p_end}
{p2col:"I need a table for the paper"}{helpb thexport}{p_end}
{p2col:"I want to check the method on data I control"}{helpb thsim}{p_end}
{p2col:"Is my series nonlinear at all?"}{helpb thnltest}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{bf:If your situation is not in the table}, the likeliest reasons are that the
threshold variable is not observed (this package is for {it:observed}
thresholds -- for latent regimes see {helpb mswitch}), that your data are a
panel (out of scope here), or that you want a threshold in a variance rather
than a mean (not provided). Say so in the paper rather than forcing the
nearest available model onto the question.


{marker glance}{...}
{title:The whole package at a glance}

{pstd}
Thirty-four commands, grouped by what they are for. Every one has its own help
page with its own worked examples; this is the catalogue, not the manual.

{synoptset 16 tabbed}{...}
{syntab:Before you estimate: is there anything there?}
{synopt:{helpb thnltest}}classical linearity tests of an autoregression{p_end}
{synopt:{helpb thtest}}threshold-effect test with a fixed-regressor bootstrap{p_end}
{synopt:{helpb thqtest}}the same question at a quantile{p_end}
{synopt:{helpb thivtest}}the same question with endogenous regressors{p_end}
{synopt:{helpb thtarma}}the same question when the model has an MA part{p_end}
{synopt:{helpb thstrtype}}logistic or exponential, once smooth is indicated{p_end}

{syntab:How many regimes, and split on what?}
{synopt:{helpb thnregimes}}the full triangle of sequential tests{p_end}
{synopt:{helpb thnseq}}sequential count without a bootstrap{p_end}
{synopt:{helpb thselect}}information criteria plus a sequential test{p_end}
{synopt:{helpb thsearch}}which variable is the threshold variable{p_end}
{synopt:{helpb thtarsel}}order, delay and regime count for a SETAR, together{p_end}
{synopt:{helpb thtvarsel}}the same for a system{p_end}

{syntab:Cross-sectional estimation}
{synopt:{helpb thregress}}threshold regression, the workhorse{p_end}
{synopt:{helpb thkink}}continuous (kink) regression{p_end}
{synopt:{helpb thstr}}smooth transition regression{p_end}
{synopt:{helpb thqreg}}threshold quantile regression{p_end}
{synopt:{helpb thqkink}}bent-line quantile regression{p_end}
{synopt:{helpb thivreg}}endogenous regressors{p_end}
{synopt:{helpb thendog}}endogenous threshold variable{p_end}

{syntab:One time series}
{synopt:{helpb thtar}}SETAR / TAR, with a delay search{p_end}
{synopt:{helpb thsubtar}}a different AR order in each regime{p_end}
{synopt:{helpb thstar}}smooth transition autoregression{p_end}
{synopt:{helpb thstarcycle}}the specification cycle for a STAR{p_end}
{synopt:{helpb thmtar}}asymmetric adjustment and threshold cointegration{p_end}
{synopt:{helpb thtqar}}threshold quantile autoregression{p_end}
{synopt:{helpb thunitroot}}unit root against a stationary threshold{p_end}
{synopt:{helpb thbandur}}unit root against a band of inaction{p_end}

{syntab:Systems}
{synopt:{helpb thtvar}}threshold VAR{p_end}
{synopt:{helpb thtvecm}}threshold VECM{p_end}
{synopt:{helpb thstvar}}vector smooth transition VAR{p_end}

{syntab:After the fit}
{synopt:{helpb thsubci}}subsampling interval for the threshold{p_end}
{synopt:{helpb thforecast}}multi-step forecasts, densities, fan charts{p_end}
{synopt:{helpb thsim}}simulate from a model you specify{p_end}
{synopt:{helpb thexport}}publication tables in LaTeX, RTF, Markdown{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Post-estimation is {cmd:estat} after each command: regime summaries and
tables, profile and likelihood-ratio plots, residual diagnostics tested
against the regime-split design, impulse responses and variance
decompositions, the deterministic skeleton, HAC standard errors, and equality
tests across regimes. Each command's help lists its own.


{marker step1}{...}
{title:Step 1. Is there a threshold at all?}

{pstd}
{bf:Run {helpb thnltest} first.} It costs nothing, needs no threshold to be
estimated, and reports the four classical tests of linearity of an
autoregression: Keenan (1985), Tsay (1986), Tsay's (1989) arranged
autoregression over candidate delays, and a CUSUM portmanteau. Two things to
know when reading it. Keenan and Tsay (1986) test against general second-order
curvature and need no ordering, so a threshold model whose two regimes are both
{it:linear} leaves them nothing to find -- their failure to reject is not
evidence against a threshold. The arranged autoregression is the one aimed at a
threshold, and the delay it selects is the natural candidate threshold variable
to carry forward. And because that delay was chosen by minimising a p-value, use
{cmd:reps()} and quote the bootstrap p-value.


{pstd}
{bf:Do not estimate a threshold before testing for one.} A threshold estimate always
exists: the grid search returns its argmin whatever the data look like. Reporting
{it:gamma}-hat without a test is reporting the minimum of a random function.

{pstd}
The complication is that under the null of no threshold the threshold parameter
{it:gamma} is {bf:not identified}. The usual chi-square and F distributions do not
apply. This is the Davies problem, and it is why
{help thtest} simulates p-values instead of reading them off a table
({help threshkit_choose##refs:Hansen 1996}).

{pstd}
{bf:What this forbids.}

{phang2}
o {bf:Do not} compare SSR(threshold model) with SSR(linear model) using an F table.
The statistic is not F under the null.

{phang2}
o {bf:Do not} use the {help threshkit_choose##refs:Davies (1987)} upper bound for a
{it:discontinuous} (jump) threshold. Hansen (1996, p.8, Table I) shows it is invalid
there. It is legitimate only against {it:smooth} or {it:kink} alternatives, which is
why {cmd:thregress} refuses it and {helpb thkink} offers it.

{phang2}
o {bf:Do not} use {helpb estat sbsingle} as a threshold test. It tests for a break at
an unknown {it:date}; it cannot sort by a covariate. Breaks in time and thresholds in
a covariate are different models with different asymptotics.

{pstd}
{bf:What to do.} Run {helpb thtest} (or {cmd:thregress, test}). If you have any doubt
about homoskedasticity, use the heteroskedasticity-robust version — see Step 3.

{marker step2}{...}
{title:Step 2. Which model class?}

{pstd}
{bf:If the regime shift may differ across the distribution rather than in the mean}, the model class is a quantile one: {helpb thqreg} for a threshold quantile regression, {helpb thtqar} for a threshold quantile AUTOregression, and {helpb thqkink} when the fitted quantile is CONTINUOUS at the break -- a bent line rather than a step. A shift confined to one tail is invisible to anything fitted to the mean.

{pstd}
{bf:If the transition is smooth rather than abrupt}, two further questions follow and neither answers itself. {helpb thstrtype} decides WHICH shape -- logistic (monotone in the transition variable) or exponential (symmetric about its centre) -- because {helpb thstar} makes you pick and fitting both and keeping the better likelihood is selection by eye. {helpb thstarcycle} then runs Teraesvirta's whole specification cycle end to end: order, linearity, transition variable, family, estimation, evaluation, report.

{pstd}
Four questions settle it. Answer them in order.

{pstd}
{bf:Q1. Is the regression discontinuous at the threshold, or only its slope?}

{p2colset 8 34 36 2}{...}
{p2col:{bf:Jump} (level shifts)}{cmd:thregress} {p_end}
{p2col:{bf:Kink} (continuous, slope shifts)}{cmd:thkink} {p_end}
{p2colreset}{...}

{phang2}
This is not a matter of taste. Hansen (2000) Assumption 1.7 ({it:c'Dc > 0}, p.580)
{bf:excludes} the continuous-threshold model, citing Chan and Tsay (1998). Running
{cmd:thregress} on data generated by a kink gives an inconsistent threshold estimate.
If you are not sure which you have, estimate the kink model and use
{cmd:estat continuity} (after {cmd:thkink}), or use a confidence interval that is
valid under both — see Step 4.

{phang2}
Economic reasoning usually decides it. A policy that switches on at a cut-off
(eligibility, a tax bracket) is a jump. A relationship that bends (a capacity
constraint, diminishing returns above a level) is a kink.

{pstd}
{bf:Q2. Is the transition abrupt or gradual?}

{p2colset 8 34 36 2}{...}
{p2col:{bf:Abrupt} at a point}{cmd:thregress}, {cmd:thtar}, {cmd:thtvar} {p_end}
{p2col:{bf:Gradual} over a range}{helpb thstr}, {cmd:thstar}, {cmd:thstvar} {p_end}
{p2colreset}{...}

{phang2}
Smooth-transition models (STR/STAR/STVAR) replace the indicator with a continuous
function {it:G(z; gamma, c)}. They are the right choice when the regime change is an
aggregation over heterogeneous units, or when adjustment is gradual. They are
{bf:harder to estimate}: the likelihood is flat in the smoothness parameter, so
starting values matter and the "estimated" {it:gamma} is often not identified in
practice. If a sharp threshold fits, prefer it: it is more stable and its inference
theory is complete.

{pstd}
{bf:Q3. What generates the threshold variable?}

{p2colset 8 34 36 2}{...}
{p2col:An {bf:exogenous covariate}}{cmd:thregress}, {cmd:thkink} {p_end}
{p2col:The {bf:dependent variable's own past}}{cmd:thtar} (SETAR) {p_end}
{p2col:An {bf:endogenous} variable}{cmd:thivreg} {p_end}
{p2col:A {bf:latent} state, not observed}{helpb mswitch} (not a threshold model) {p_end}
{p2colreset}{...}

{phang2}
The last row matters. If the regime is {it:unobserved} and follows a Markov chain,
you need Markov switching, not a threshold model, and official Stata already has it.
Threshold models require you to {bf:name} the variable that does the switching. That
is their strength (interpretable, testable) and their restriction.

{phang2}
If the threshold variable is endogenous, {cmd:thregress} is inconsistent. See
{help threshkit_choose##refs:Yu, Liao and Phillips (2024)} and
{help threshkit_choose##refs:Kourtellos, Stengos and Tan (2016)}.

{pstd}
{bf:Q4. What is the data structure?}

{p2colset 8 34 36 2}{...}
{p2col:Cross-section}{cmd:thregress}, {cmd:thkink}, {helpb thqreg}, {cmd:thivreg} {p_end}
{p2col:One time series}{cmd:thtar}, {cmd:thstar}, {cmd:thtarma}, {cmd:thmtar}; test first with {cmd:thnltest}, count regimes with {cmd:thnregimes} {p_end}
{p2col:Several time series}{cmd:thtvar}, {cmd:thtvecm}, {cmd:thstvar} {p_end}
{p2col:Panel}out of scope; see {helpb xthreg} (SSC) {p_end}
{p2colreset}{...}

{phang2}
{cmd:thregress} is legitimate on time-series data — Hansen (2000) Assumption 1 allows
{it:rho}-mixing stationary data — but it does {bf:not} model dynamics. If the
threshold variable is a lag of the dependent variable, you want {cmd:thtar}.

{marker step3}{...}
{title:Step 3. Which test?}

{pstd}
{bf:The short answer: use the heteroskedasticity-robust sup-LM test, with a bootstrap
p-value.} In {cmd:thregress} that is the default ({cmd:vce(robust)}).

{pstd}
{bf:That is for a conditional-mean regression. Four other settings have their own test, and the ordinary one does not substitute for any of them.}

{phang2}
{bf:Endogenous regressors} {hline 2} {helpb thivtest}. The sup-Wald test comparing GMM fits either side of each split. Use the default, corrected form: Rothfelder and Boldea show the original Caner-Hansen version is badly sized at the sample sizes applied work actually uses.{p_end}
{phang2}
{bf:A quantile, not the mean} {hline 2} {helpb thqtest}. The sup-score test at one quantile, and the sup-Wald test uniform over a SET of quantiles. A threshold confined to one tail is invisible to a test at the median.{p_end}
{phang2}
{bf:An ARMA, not an AR} {hline 2} {helpb thtarma}. Nothing can be profiled out of an ARMA residual, so this needs its own engine and its own bootstrap.{p_end}
{phang2}
{bf:A unit root in the middle regime} {hline 2} {helpb thbandur}, and Step 8.{p_end}

{pstd}
{bf:Why sup-LM and not sup-Wald.} Hansen (1996, p.11, Table II) reports that the
robust {it:sup-Wald} test is badly oversized in finite samples — rejection rates of
.14 to .32 at a nominal 5% with n = 100. The {it:sup-LM} version is well sized. This
is one of the clearest finite-sample results in the literature and it is routinely
ignored.

{pstd}
{bf:sup, ave, or exp?} All three are available through {cmd:stat()}.

{p2colset 8 20 22 2}{...}
{p2col:{cmd:stat(sup)}}Best power against a {it:single, sharp} threshold effect. The default.{p_end}
{p2col:{cmd:stat(ave)}}Better power when the effect is spread over a range of candidate thresholds.{p_end}
{p2col:{cmd:stat(exp)}}The Andrews-Ploberger optimal test. A good default if you have no prior about where the threshold is.{p_end}
{p2colreset}{...}

{phang2}
They test the same null. Choose {it:before} looking at the results and say which you
chose. Reporting the largest of the three is a specification search.

{pstd}
{bf:Homoskedastic or robust?} If the error variance may depend on the regressors,
use the robust form. The cost of robustness here is small; the cost of a spurious
threshold is a wrong paper. Note that the robust test and the robust confidence
interval rely on {it:different} assumptions — see Step 4.

{pstd}
{bf:Bootstrap residuals.} There is a genuine ambiguity in the literature. Hansen
(2000, p.587) describes drawing {it:y*} using residuals from the {bf:threshold} fit;
the author's own published code uses residuals from the {bf:null} (global OLS) fit.
On the Durlauf-Johnson data this moves the p-value from {bf:0.062} to {bf:0.085}.
{cmd:thregress} defaults to the paper and reproduces the code under
{cmd:hansencompat}. {bf:Say which you used.}

{pstd}
{bf:Replications.} 1000 is the published default. The Monte Carlo standard error is
reported; at p = .09 with B = 1000 it is about .009, so a p-value of .09 and one of
.07 are not distinguishable. If your conclusion turns on the third decimal, raise
{cmd:reps()} to 5000 or more.

{marker step4}{...}
{title:Step 4. Which confidence interval for the threshold?}

{pstd}
This is where most applied work is weakest. Official Stata's {helpb threshold}
reports no confidence interval at all, and a point estimate without one invites the
reader to believe the threshold is known.

{pstd}
{bf:The default: invert the likelihood ratio.} The confidence set is
{it:{c -(}gamma: LR_n(gamma) <= c{c )-}} with {it:c = -2 ln(1 - sqrt(level))}
(Hansen 2000, eq. 8 and Table I; {it:c} = 7.35 at 95%). {cmd:thregress} reports it,
and {cmd:estat lrplot} draws it.

{pstd}
{bf:A third route, when you do not know whether the model has a jump or a kink:} {helpb thsubci}. The rate of convergence is {it:n} for a jump and the square root of {it:n} for a kink, so the two differ by a factor that GROWS with the sample, and an interval built on the wrong one is not slightly wrong. Subsampling estimates that rate from the data -- from the speed at which subsample estimates concentrate as the block grows -- so the interval is valid either way, and the estimated exponent is itself a diagnostic of which case you are in.

{pstd}
{bf:Four things the theory says that applied papers routinely get wrong.}

{phang2}
{bf:1. The confidence set is a {it:set}, not an interval.} The LR profile can cross
the critical line several times. Hansen reports the convex hull, and so does
{cmd:thregress} — but it {bf:warns you} when the set is not contiguous and stores the
accepted points in {cmd:e(ci_set)}. On the Durlauf-Johnson data the 95% set is 20
grid points and is {it:not} an interval, even though "[594, 1794]" looks like one.
Show {cmd:estat lrplot} in the paper.

{phang2}
{bf:2. {cmd:ci(lrstar)} assumes away regime-dependent heteroskedasticity.} The
{it:eta}-squared correction (Hansen 2000, p.583) handles heteroskedasticity that is
{it:continuous} in the threshold variable. Assumption 1.5 (p.579) {bf:excludes} a
variance that jumps with the regime. {cmd:estat hettest} tests exactly this and warns
you. If it rejects, report {cmd:ci(lr)} as well and say the robust set is not
justified.

{phang2}
{bf:3. The bootstrap is {it:invalid} for the threshold confidence interval.}
{help threshkit_choose##refs:Yu (2014)} shows the nonparametric, wild and residual
bootstraps do not deliver valid coverage for {it:gamma}. {cmd:thregress} does not
warn about this — it {bf:refuses} with an error naming the paper. The same bootstraps
remain perfectly valid for test p-values under the null, which is a different problem.

{phang2}
{bf:4. "Conservative" is an asymptotic statement with conditions.} Hansen (2000)
Theorem 3 shows the LR set is conservative under a fixed threshold effect, but only
for iid Gaussian errors independent of {it:(x, q)}.
{help threshkit_choose##refs:Donayre, Eo and Morley (2018)} report finite-sample
{bf:under}-coverage when the threshold effect is large. Do not promise your reader
conservative coverage.

{pstd}
{bf:Choosing.}

{p2colset 8 26 28 2}{...}
{p2col:{cmd:ci(lrstar)}}Default with {cmd:vce(robust)}. Use unless {cmd:estat hettest} flags regime dependence.{p_end}
{p2col:{cmd:ci(lr)}}Default with {cmd:vce(ols)}. Report alongside {cmd:lrstar} whenever heteroskedasticity is in doubt.{p_end}
{p2col:{cmd:ci(none)}}Only when the threshold is known a priori.{p_end}
{p2colreset}{...}

{pstd}
{bf:Slope intervals.} The default coefficient table treats {it:gamma} as known: that
is justified, because the slope estimator is sqrt(n)-normal with the same variance as
if {it:gamma} were known (Hansen 2000, eq. 11). If you want intervals that carry the
threshold uncertainty, use {cmd:estat twostep} — the union over the {it:rho}-level
threshold set (pp.585-586, {it:rho} = .8 recommended). They are wider, and honest.

{marker step5}{...}
{title:Step 5. How many regimes?}

{pstd}
{bf:Two routes, and they differ in what they cost.} {helpb thnregimes} bootstraps, {helpb thnseq} does not, and the reason {cmd:thnseq} can avoid it is worth knowing: threshold estimates are SUPER-CONSISTENT and stay so even when fewer thresholds are fitted than the truth, so at each stage the thresholds already found can be treated as KNOWN. 'Is there one more regime?' is then an ordinary linearity test with a chi-squared limit. That is an asymptotic argument resting on a rate, so in a short sample prefer the bootstrap and check the two against each other. {helpb thtarsel} chooses the order, the delay and the regime count together for a SETAR, with ONE order shared by both regimes; {helpb thsubtar} is the one to use when the regimes should have DIFFERENT orders, SETAR(2; k1, k2), which is what Tong and Lim's own lynx and sunspot fits are.

{pstd}
{bf:Use {helpb thnregimes}.} It tests {it:i} thresholds against {it:j} for
{bf:every} pair {it:i} < {it:j}, not only the adjacent ones, which matters more
often than people expect. The sequential rule stops at the first adjacent test
that does not reject, and it can stop too early: if the truth is three regimes
whose outer two resemble each other, the one-threshold model is a bad
compromise, F(2|1) fails to reject, and the sequence never looks at two
thresholds. {bf:F(3|1)} compares two thresholds with none directly and catches
exactly that case. A small F(2|1) with a large F(3|1) is the signature.

{pstd}
{bf:And if the model is an autoregression, use {cmd:boot(recursive)}.} A
fixed-regressor bootstrap holds the regressors at their sample values, which is
right in a cross-section and wrong in an autoregression, where the regressors
{it:are} lags of the dependent variable: holding them fixed while redrawing the
errors generates samples that could not have come from the null model.
{cmd:thnregimes} refuses {cmd:boot(recursive)} without {cmd:arlags()} rather
than guessing which regressors are lags.


{pstd}
Two regimes is a hypothesis, not a fact. Three procedures exist and they do not
always agree.

{p2colset 8 26 28 2}{...}
{p2col:{bf:Sequential testing}}Estimate the first threshold, split the sample, test again in each subsample. Stop when the test no longer rejects. This is what Hansen (2000, section 5) does on the growth data, and what {cmd:thtest} supports.{p_end}
{p2col:{bf:Information criteria}}Official {helpb threshold}{cmd:, optthresh()} uses BIC/AIC/HQIC; {helpb thselect} adds the Gonzalo-Pitarakis (2002) BIC-type criterion. Fast, but it is model selection, not inference: no p-value, no size control.{p_end}
{p2col:{bf:Bootstrap sup-F(m+1|m)}}Tests m thresholds against m+1 with a bootstrap p-value. The statistically honest version, and the most expensive.{p_end}
{p2colreset}{...}

{pstd}
{bf:Practical advice.} Use the sequential test for the headline result and report the
IC as a robustness check. If they disagree, say so: it usually means the second
threshold is weakly identified, and the honest conclusion is "two regimes, with some
evidence of a third".

{pstd}
{bf:A warning about confidence intervals for later thresholds.} The LR inversion in
Hansen (2000) is for a single threshold. Intervals for the second and later
thresholds need {help threshkit_choose##refs:Donayre (2024)}. Do not reuse the
one-threshold critical value for a multi-threshold model.

{marker step6}{...}
{title:Step 6. Systems of equations}

{pstd}
{bf:Before fitting one, choose its dimensions:} {helpb thtvarsel} picks the lag order, the delay and the threshold for a TVAR together, on one fixed sample, and prints the linear VAR beside them so the comparison is visible rather than asserted.

{pstd}
Four commands fit threshold models to several series at once. Choosing between
them is three decisions, taken in this order.

{pstd}
{bf:6a. Are the series cointegrated?}

{pstd}
Test it first, with {helpb vecrank} on the linear system. If they are
cointegrated, a threshold VAR in levels is misspecified and a threshold VAR in
differences throws away the long-run relation that the whole exercise is about.
Use {helpb thtvecm}, whose threshold variable is the error-correction term
itself, so the regime is defined by {it:how far the system is from its own
equilibrium}. If only one adjustment equation interests you, the
single-equation alternative is {helpb thmtar}, which also gives you the
Enders-Granger sign asymmetry and, with {opt band}, a band of inaction.

{pstd}
{bf:But test the cointegration against the right alternative.} {helpb vecrank}
is a {it:linear} cointegration test, and it has poor power when adjustment is
threshold-dependent: it can report no cointegration about a system that plainly
has it, simply because the adjustment is slow near equilibrium. If you are
already contemplating a threshold VECM, fit one and run
{cmd:estat seotest} after it. That is Seo's (2006) sup-Wald test, whose null is
no cointegration and whose {it:alternative} is threshold cointegration, so it
is the test matched to the model you have in mind. The two tests after
{cmd:thtvecm} answer different questions and are easy to confuse:

{p 8 12 2}
{cmd:estat seotest} -- is there any long-run relation at all? Run this
{bf:first}.

{p 8 12 2}
{cmd:thtvecm, test} -- given that there is one, is the adjustment towards it
threshold-dependent? Run this {bf:second}.

{pstd}
A threshold VECM fitted to a system that fails the first is describing
adjustment towards a relation for which there is no evidence, and its
error-correction coefficients should not be reported as speeds of adjustment.

{pstd}
{bf:6a-bis. Two regimes or three?}

{pstd}
{opt nthresh(2)} fits the three-regime {bf:band} model of Balke and Fomby
(1997) and Lo and Zivot (2001): a middle band in which the gap is too small to
be worth closing, and an outer regime on each side where adjustment switches
on. Transaction costs, menu costs and an announced currency band all produce
it, and it is the right default {it:when you have a reason to expect inaction
near equilibrium} -- not otherwise, because the two thresholds are searched
jointly over every ordered pair and a three-regime model needs a much longer
series than a two-regime one.

{pstd}
Two restrictions sharpen the band into a hypothesis. {opt restrict(band)} holds
the middle regime's error-correction coefficient at zero, so inside the band
the system does not adjust at all. {opt restrict(equal)} makes the two outer
regimes share one coefficient block, so adjustment is symmetric either side.
{bf:Test them, do not assume them}: refit without the restriction and compare
ln|Sigma|. The restricted fit is nested, so it can never do better; the
question is only whether it does much worse. Asymmetric adjustment is the usual
empirical finding, so {opt restrict(equal)} deserves particular suspicion.

{pstd}
{bf:6a-ter. Do you need a standard error on the adjustment speed?}

{pstd}
Then use {opt sls}. In a sharp threshold model the slopes and the threshold
converge at different rates and their limits are entangled, so the standard
errors printed beside the slopes are {bf:not valid for inference} -- in
{cmd:thtvecm} as in every other sharp-threshold command here. {opt sls}
replaces the indicator by an integrated normal kernel, which Seo (2011) shows
makes the slopes asymptotically normal and asymptotically {it:independent} of
the threshold; the conventional standard errors then do apply to them. The
threshold still has none, because its limit is a functional of a vector
Brownian motion rather than a normal.

{pstd}
Two cautions. The bandwidth constant is a choice, so refit at a different
{opt bwscale()} and check the conclusions hold. And {opt sls} cannot be
combined with {opt test}: the Hansen-Seo sup-LM statistic is derived for the
sharp indicator. Fit twice -- without {opt sls} for the test, with it for the
standard errors.

{phang2}
A caution worth knowing: threshold adjustment weakens the power of linear
cointegration tests, so a {helpb vecrank} that fails to reject is weak evidence.
{cmd:thmtar}'s {opt coint} option runs the Engle-Granger first stage with the
asymmetric alternative in view, and Seo (2006) gives a bootstrap test of no
cointegration {it:against} a threshold VECM.

{pstd}
{bf:6b. Is the regime a switch or a matter of degree?}

{p2colset 8 24 26 2}{...}
{p2col:{bf:A switch}}{cmd:thtvar}, {cmd:thtvecm}{p_end}
{p2col:{bf:A degree}}{cmd:thstvar}{p_end}
{p2colreset}{...}

{pstd}
A binding constraint, a credit limit, a policy rule with a trigger: those are
switches. Slack, sentiment, financial tightness, the depth of a recession: those
are degrees. Aggregation also matters — a mechanism that is sharp for each firm
is smooth in the aggregate, which argues for {cmd:thstvar} on macro data even
when the micro story is a threshold.

{pstd}
There is also an empirical check, and it is the useful one. Fit
{helpb thstvar} and run {cmd:estat transition}. If almost every observation
sits in a corner ({it:G} < .1 or {it:G} > .9), the estimated transition
{it:is} a sharp threshold: switch to {helpb thtvar}, which spends two fewer
parameters and gives the threshold a proper confidence set. If the transition
spends its life in the middle, {it:gamma} is barely identified and the two
regimes are not really separated — look again at the transition variable before
interpreting anything.

{phang2}
The log likelihoods of {cmd:thtvar}, {cmd:thstvar}, {cmd:thtvecm} and official
{helpb var} are all on the same scale (THRESHKIT uses
-({it:n}/2)({it:k}(ln 2{it:pi}+1) + ln|Sigma|) throughout, not the variant in the
published Tsay 1998 paper), so their AIC, BIC and HQIC are directly comparable.
Treat a BIC difference under about 2 as no evidence either way and report both.

{pstd}
{bf:6c. Which test, and what does rejection mean?}

{p2colset 8 24 26 2}{...}
{p2col:{cmd:thtvar, test}}sup/ave/exp-LR against a linear VAR, fixed-regressor bootstrap{p_end}
{p2col:{cmd:thtvecm, test}}Hansen-Seo sup/ave/exp-LM, fixed-design bootstrap{p_end}
{p2col:{cmd:thstvar}}LM linearity sequence, reported automatically{p_end}
{p2colreset}{...}

{pstd}
In every case the threshold or the transition is {it:unidentified} under the
null, so none of these statistics is chi-squared and none of them may be read
off a table. {cmd:thtvar} and {cmd:thtvecm} simulate the null distribution with
the design held fixed. {cmd:thstvar} takes the other route: it replaces the
transition by its Taylor expansion (Luukkonen, Saikkonen and Terasvirta 1988),
which turns the problem into a test of a linear restriction and needs no
bootstrap.

{pstd}
Three things to keep straight when reading them.

{phang2}
{bf:A system test does not say which equation differs.} Rejection is about the
whole coefficient matrix. Look at {cmd:estat regimes}, and in {cmd:thstvar} at
the {bf:Delta} block, to see where the difference actually is.

{phang2}
{bf:Report the F version of the STVAR tests.} The chi-squared forms of the
multivariate LM and LR statistics are heavily oversized at the sample sizes used
in this literature; Rao's F approximation is what Terasvirta and Yang (2014a)
recommend and what {cmd:thstvar} puts in its main table. The per-equation F
tests reported by {cmd:estat misspec} are the small-sample reliable version: if
the system statistic rejects and no single equation does, suspect size
distortion rather than a finding.

{phang2}
{bf:Rejecting linearity is not the end of the specification search.}
{cmd:thstvar}'s {cmd:estat misspec} runs three further tests. Residual
autocorrelation usually means too few lags, and should be fixed before any
regime conclusion is drawn. Remaining nonlinearity points to a third regime or
a second transition variable. Failure of parameter constancy means the regimes
themselves drift, which no two-regime model can absorb.

{pstd}
{bf:6d. Then do not read the coefficients as effects.}

{pstd}
In a nonlinear system the response to a shock depends on where the system
currently is, on the size of the shock, and on its sign, because a shock can
move the system across the threshold. The coefficient matrices describe the two
limiting regimes and nothing else. The object to report is the generalised
impulse response of Koop, Pesaran and Potter (1996),
{cmd:estat girf} after {cmd:thtvar} or {cmd:thstvar}, and in particular
{cmd:estat girf, compare}, which computes it separately from regime-1 and
regime-2 histories. Run it at {opt size(1)} and {opt size(-1)}, and at
{opt size(1)} and {opt size(3)}: in a linear VAR those would be exact multiples
of one another, and the departure {it:is} the result.

{phang2}
A generalised impulse response needs a model that can simulate its own
transition variable, so fit with {opt delay()} rather than {opt thvar()} (and
{opt delay()} no greater than {opt lags()}). {bf:e(girf_ok)} says whether it is
available.


{marker step7}{...}
{title:Step 7. Which threshold variable, and which delay?}

{pstd}
This step comes {it:before} Step 1 in logic and is almost always skipped in
practice. A threshold model needs a variable to split on. If you tried several
and kept the best, the p-value in Step 1 is wrong, and wrong in the direction
that manufactures findings.

{pstd}
{bf:7a. How bad is it?} With eight roughly independent candidates, a nominal
5% test that ignores the search rejects about a third of the time under the
null. That is not a rounding error.

{pstd}
{bf:7b. What to do.} Run {helpb thsearch} with the whole candidate set. Its
bootstrap redraws the data and then {it:repeats the entire search} on every
replication, which is Hansen's (1996) equation (7). The p-value it reports is
a p-value of the searched statistic. The per-candidate column is each
candidate's own marginal p-value and is valid only for a candidate you fixed
on theoretical grounds before looking.

{pstd}
{bf:7c. Which criterion picks the winner?}

{phang2}
{bf:Minimum SSR} if the transition is abrupt. It is the least-squares answer
and is what {helpb thtar} and {helpb thregress} will reproduce.

{phang2}
{bf:Smallest linearity p-value} if the transition is smooth — that is, if the
model you will fit is {helpb thstar} or {helpb thstvar}. This is the
Lundbergh-Terasvirta-van Dijk rule. A smooth transition spreads the regime
change over many observations, and the sharp-threshold SSR can then prefer the
wrong variable.

{phang2}
{bf:Never the test statistic itself.} Selecting on the statistic you are about
to test is the circularity the correction exists to handle.

{pstd}
{bf:7d. When the criteria disagree}, or when the SSR is nearly flat across
candidates, the threshold variable is not identified by the data. Say so, fit
the one theory prefers, and report the alternative in a footnote. Do not pick
the one with the smallest p-value.

{pstd}
{bf:7e. Delay only.} For a SETAR the candidate set is
y{subscript:t-1}, ..., y{subscript:t-d}. {helpb thtar} will search it with
{opt delay(numlist)} and warns that the test is then conditional;
{cmd:thsearch} is where the valid p-value comes from. Get the delay there,
then fix it in {cmd:thtar} with {cmd:delay(}{it:d}{cmd:)}.


{marker step8}{...}
{title:Step 8. Is the series even stationary?}

{pstd}
Every time-series command in this package except one assumes the series is
stationary. {helpb thtar}'s confidence interval for the threshold,
{helpb thstar}'s standard errors and {helpb thtvar}'s bootstrap all rely on
it. If the series has a unit root, those numbers are not wrong by a little.

{pstd}
{bf:Two commands, and they are not interchangeable.} {helpb thunitroot} is Caner-Hansen: TWO regimes, and the transition variable must be a lagged DIFFERENCE because it has to be stationary under the null. That rules out the lagged LEVEL, which is exactly what a band-of-inaction story needs. {helpb thbandur} is Kapetanios-Shin: THREE regimes, a random walk imposed inside the corridor and mean reversion outside it, with the lagged level as the transition variable. If your alternative is a band around a long-run relationship -- purchasing power parity, a price spread, an interest-rate differential -- that is the one aimed at it.

{pstd}
{bf:8a. A linear} {helpb dfuller} {bf:is not enough.} It fits one
{&rho} to the whole sample. A series that reverts strongly in one regime and
wanders in the other has an average {&rho} close to zero, so the ADF fails to
reject — and the conclusion "unit root" is then an artefact of forcing one
regime on two.

{pstd}
{bf:8b. Use} {helpb thunitroot}. It tests for a threshold and for a unit root
at the same time, because neither question can be settled without the other:
Caner and Hansen (2001) show that the limit distribution of the threshold
statistic depends on whether {&rho} = 0, which is exactly what is unknown. It
prints the linear ADF beside its own statistics on the same sample, so the
comparison is direct.

{pstd}
{bf:8c. Read the two regime-specific t statistics together.}

{phang2}
Both reject {&rarr} stationary in both regimes. Go on to {helpb thtar} for the
richer post-estimation.

{phang2}
Neither rejects {&rarr} no evidence against a unit root. Do not fit
{cmd:thtar}: its inference is not valid here. Difference the series, or model
it as a threshold cointegrating system with {helpb thtvecm} or
{helpb thmtar}.

{phang2}
One rejects and the other does not {&rarr} a {bf:partial unit root}:
mean-reverting in one regime, a random walk in the other. This is a real
finding, it is a stationary ergodic process overall, and it is invisible to a
linear ADF. It is also the thing to report, because it is the economics.

{pstd}
{bf:8d. Two bootstrap p-values, and why.} {cmd:thunitroot} reports the
threshold test under a stationary DGP and under a random-walk DGP, and tells
you to use the larger. That is not indecision: neither bootstrap is valid in
both cases, which case holds is the open question, and taking the larger is
conservative in the direction that matters — it stops you claiming a threshold
that is an artefact of nonstationarity.

{pstd}
{bf:8e. What it cannot do.} There is no heteroskedasticity-robust version of
these statistics anywhere in the literature; the theory assumes i.i.d. errors
and the bootstrap resamples them. If the residuals are visibly
heteroskedastic, say so and treat the p-values as indicative. And there is no
confidence interval for the threshold under a near unit root, because the
usual critical values do not apply; {cmd:estat delay} is the honest
sensitivity check instead.


{marker step9}{...}
{title:Step 9. Are the regressors endogenous?}

{pstd}
If they are, every command in Steps 1 to 6 is estimating the wrong thing, and
the threshold is not rescued by the fact that it was estimated by least
squares: a biased slope moves the sum of squares, so it moves the argmin too.

{pstd}
{bf:9a. Use} {helpb thivreg}. It estimates the threshold by concentrated 2SLS,
the slopes by regime GMM, and reports slope intervals that do {it:not}
condition on the estimated threshold. Syntax follows {helpb ivregress}:

{phang2}{cmd:. thivreg y x1 (y1 = z1 z2), threshvar(q)}{p_end}

{pstd}
{bf:9b. If the threshold variable is endogenous, {helpb thivreg} is the wrong
command} {hline 2} use {helpb thendog}. Yu (2013) shows the 2SLS threshold
estimator is {bf:inconsistent} when q is endogenous, and no number of
instruments repairs it, because the problem is not the slopes: the REGIME
ITSELF becomes correlated with the error, so each regime is a SELECTED
sample and the conditional mean inside it is not the regression function.
That is Heckman's problem, and {cmd:thendog} applies Heckman's answer --
an inverse-Mills correction in each regime, with ONE coefficient shared
between them.

{pstd}
That coefficient is also the test. Under an exogenous threshold it is zero,
the correction drops out and the model collapses to {cmd:thivreg}, so a t
test on it {bf:is} a test of threshold exogeneity and {cmd:thendog} names the
better-suited command in each direction. Run it when you are unsure rather
than arguing from first principles.

{pstd}
A lag, a predetermined characteristic, or an aggregate the unit cannot
influence is still the safest threshold variable; a same-period choice of
the same agents is not.

{pstd}
{bf:9c. Check instrument strength inside each regime}, with
{bf:estat firststage}. An instrument can be strong in the full sample and weak
or constant inside one regime, and then that regime is not identified while
the pooled first stage looks healthy. No official command can see this,
because none of them knows the regimes exist. This is the single most common
way an IV threshold model fails.

{pstd}
{bf:9d. Does the first stage switch too?} If the relation between the
endogenous regressors and the instruments plausibly changes with q, use
{cmd:reduced(threshold)}. Modelling a switching first stage as linear gives a
fitted value that is wrong in both regimes, and the threshold search inherits
that error.

{pstd}
{bf:9e. There is no test of no threshold under endogeneity} in this package,
because Caner and Hansen (2004) do not provide one and inventing inference is
worse than not having it. Report the confidence interval for {&gamma}: if it
covers the trimmed range, there is no identified threshold. Say that, rather
than reporting a point estimate as if it were a finding.

{pstd}
{bf:9f. Report the union intervals}, from {bf:estat twostep}, not the
coefficient table. The table conditions on {&gamma}-hat and is too narrow.


{marker step10}{...}
{title:Step 10. Forecasting a threshold model}

{pstd}
The single most common error in applied work with these models. It has nothing
to do with estimation and everything to do with what a forecast {it:is}.

{pstd}
{bf:10a. Do not iterate the model with zero errors.} For a linear AR that
gives the conditional expectation, because E[f(y)] = f(E[y]) when f is linear.
A threshold model's f is not linear, so iterating with zeros gives the
{bf:deterministic skeleton} — what the system does if nothing further happens
to it. That is a description of the dynamics, not a forecast, and the gap does
{bf:not} shrink as the sample grows, because it is the wrong object rather
than sampling error. Clements and Smith (1997) show the gap is big enough to
{it:reverse} forecast-accuracy rankings between a SETAR and a linear AR.

{pstd}
{bf:10b. Simulate instead}, with {helpb thforecast}. It recomputes the regime
at every step from the path itself, which is the point: a shock can push the
process across the threshold, and from then on the dynamics are the other
regime's. {cmd:thforecast} prints the skeleton beside the simulated forecast
by default so the size of the gap is visible.

{pstd}
{bf:10c. Which error distribution?} {cmd:method(bootstrap)} resamples the
fitted residuals and is the default: threshold series often have skewed
residuals, and skewness interacts with the regime boundary because it makes
one direction of crossing more likely. {cmd:method(montecarlo)} draws Gaussian
errors and is smoother in the tails; prefer it in short samples, where there
are too few residuals to resample from. {bf:If the two disagree materially,
the residuals are not Gaussian and the bootstrap is the one to trust} — that
comparison costs one extra command and belongs in the paper.

{pstd}
{bf:10d. Report the density, not a standard error.} A threshold model's
forecast density can be skewed, because the regimes have different means, and
{bf:bimodal}, because the paths split into those that crossed and those that
did not. When it is bimodal the point forecast sits in the trough between the
modes and is the {it:least} likely value, so a symmetric interval is wrong in
both directions at once. {cmd:thforecast} reports empirical quantiles for
exactly this reason. Three warning signs: mean far from median; regime share
near 0.5 at some horizon; interval visibly asymmetric about the point.

{pstd}
{bf:10e. Check whether the threshold is doing anything.} The regime-share
column says what fraction of simulated paths is in regime 1 at each horizon.
If it is 0 or 1 everywhere, every path stayed in one regime, the threshold
never binds over this horizon from this starting point, and a linear model
fitted to that regime would have forecast the same thing. Say so. The regime
share depends on where you are starting from, so this is a statement about
{it:this} forecast origin, not about the model.

{pstd}
{bf:10f. The intervals are too narrow, and the help says so.} The simulation
treats the coefficients and the threshold as known and propagates only future
shocks. Parameter uncertainty is not included — a full treatment would
re-estimate the threshold inside every draw — and the shortfall is worst at
short horizons, where shock uncertainty is small relative to estimation
uncertainty. Report that limitation rather than letting the reader assume it
away.

{pstd}
{bf:10g. An exogenous threshold variable cannot be forecast dynamically}, and
{cmd:thforecast} refuses rather than freezing it at its last value. The future
regime would depend on that variable's own future path. Either forecast it
with its own model and present the result as a joint statement about two
models, or state the scenario you are conditioning on.


{marker step11}{...}
{title:Step 11. Impulse responses: which one?}

{pstd}
A threshold model has {bf:no single impulse response}. There are two honest
objects and they answer different questions, so the choice has to be made and
reported, not defaulted into.

{pstd}
{bf:11a. The generalised impulse response} ({bf:estat girf} after
{helpb thtvar} or {helpb thstvar}). Koop, Pesaran and Potter (1996): simulate
the actual nonlinear system twice from the same history with the same future
shocks, once with the shock added, and take the difference. A shock may push
the process across the threshold, and the response averages over that. It
depends on the history and on the {it:sign and size} of the shock — which is
not a defect, it is the economics: in a threshold model a big shock and a
small one are not proportional, and a positive and a negative shock are not
mirror images. Use it when the question is "what happens if I shock this
system now".

{pstd}
{bf:11b. The conditionally linear impulse response} ({bf:estat irf}, and
{bf:estat fevd} for the variance decomposition). Take one regime's
coefficients and treat them as a linear VAR. This is the propagation you
would see if the system {it:stayed in that regime forever}. Use it when the
question is "how does this state propagate shocks", and when you want the
regime's own dynamics isolated from the probability of leaving it. Balke
(2000) reports exactly this, and labels it.

{pstd}
{bf:11c. Neither approximates the other.} Reporting the conditionally linear
response as "the impulse response of the TVAR" is wrong, and the output of
both commands says which object it is. If you report one, say which.

{pstd}
{bf:11d. Check the eigenvalue modulus per regime first}
({bf:estat stability}, or the line {bf:estat irf} prints). A modulus of 1 or
more means that regime's conditional response {bf:diverges}. That is correct:
a threshold model can be globally stationary with one locally explosive
regime, and finding one is usually the point. But the long-horizon numbers for
that regime are then not a forecast of anything, and the GIRF — which lets the
process leave — is the one to report.

{pstd}
{bf:11e. The Cholesky ordering is an identifying assumption}, in both
commands: it says shock m cannot affect variables before m within the period.
It is the order of your {it:varlist}. State it. {opt nocholesky} avoids the
assumption at the cost of reporting a response to a unit innovation, which is
not an economically interpretable shock.

{pstd}
{bf:11f. Bands.} The GIRF's uncertainty is simulation uncertainty over
histories and shocks. The conditionally linear band ({opt reps()}) holds the
regime split fixed and resamples residuals, so it conditions on the
classification — consistent with the object, but narrower than a band that
re-estimated the threshold. Neither includes uncertainty about {&gamma}.
Say so.


{marker report}{...}
{title:Reporting checklist}

{pstd}
A threshold result is reproducible only if the reader can see these. Every one is
stored in {cmd:e()} after {cmd:thregress}.

{pstd}
{bf:{helpb thexport} writes all of it for you}, as LaTeX, Markdown or CSV. Its footer is not decoration: it carries the threshold, its confidence SET, an explicit warning when that set is not an interval, the regime sizes and the BOOTSTRAP p-value of the no-threshold test. A generic table exporter does not know to ask for any of them, which is why reporting a threshold model through one tends to drop exactly the items below.

{phang2}{bf:1.} The threshold estimate {bf:and} its confidence set — and whether that
set is an interval.

{phang2}{bf:2.} The test statistic, which statistic it is (sup/ave/exp, LM/F),
whether it is heteroskedasticity-robust, the bootstrap p-value, the number of
replications, and the Monte Carlo standard error.

{phang2}{bf:3.} The trimming fraction. Results can depend on it; {cmd:trim(.15)} is
the THRESHKIT default, official Stata uses 10%, and Hansen's own code leaves the
estimation grid untrimmed.

{phang2}{bf:4.} Which {it:eta}-squared estimator produced the robust interval. On the
Durlauf-Johnson data the three available choices differ by a factor of two.

{phang2}{bf:5.} The number of observations in each regime. A regime with 8
observations and 5 regressors is not an estimate, whatever the table says.

{phang2}{bf:6.} The threshold profile plot ({cmd:estat lrplot}). It shows the reader
what the point estimate hides.

{phang2}{bf:7.} The seed, if any p-value is bootstrapped.

{phang2}{bf:8.} If the threshold variable or the delay was chosen from the data:
the candidate set, and the search-corrected p-value from {helpb thsearch}. A
p-value that ignores the search is not a p-value.

{phang2}{bf:9.} For a time series: the evidence that it is stationary, from
{helpb thunitroot} rather than from a linear {helpb dfuller}. If the result is
a partial unit root, which regime has the unit root.

{phang2}{bf:10.} With endogenous regressors: the first-stage F {it:inside each
regime} ({helpb thivreg}, {bf:estat firststage}), the argument that the
threshold variable is exogenous, and the union slope intervals rather than the
conditional ones.

{phang2}{bf:11.} For a forecast: that it was {it:simulated} and not obtained by
iterating with zero errors, which method generated the errors, the number of
paths, the seed, and that the intervals omit parameter uncertainty. Report the
regime share so the reader can see whether the threshold bound at all.

{phang2}{bf:12.} For an impulse response: {it:which} response — generalised or
conditionally linear — the Cholesky ordering, the eigenvalue modulus of each
regime, and what the band does and does not cover.

{phang2}{bf:13.} For a threshold VECM, {it:which null} you tested. "We
reject linearity" is ambiguous here: {cmd:estat seotest} rejects {it:no
cointegration}, while {cmd:thtvecm, test} rejects {it:linear adjustment given
cointegration}. Name the statistic, the null and the bootstrap, in that order.

{phang2}{bf:14.} If you impose a band or a symmetry restriction, what it
{it:cost}: ln|Sigma| for the free fit and for the restricted one. A
restriction imposed without that number is an assumption presented as a
finding.

{marker mistakes}{...}

{pstd}
{bf:Before trusting any of the above on your own design, generate data you already know the answer to.} {helpb thsim} simulates from a threshold model you specify -- SETAR, STAR, TVAR, or a cross-sectional kink or jump -- with normal, t, chi-squared, mixture, GARCH or resampled errors. A test whose size you have not checked on YOUR sample size and YOUR error distribution is a test you are trusting on the strength of someone else's simulation table.

{title:Seven mistakes to avoid}

{phang2}
{bf:1. Estimating without testing.} A grid search always returns a threshold.

{phang2}
{bf:2. Reporting the hull as if it were an interval.} Check {cmd:e(ci_contiguous)}.

{phang2}
{bf:3. Using a bootstrap CI for gamma.} Invalid (Yu 2014). THRESHKIT blocks it.

{phang2}
{bf:4. Choosing the threshold variable by trying several and keeping the smallest
p-value.} That is a specification search and the reported p-value is meaningless.
Hansen (2000, p.587) compares candidate threshold variables explicitly and reports
{it:both} p-values. Do that.

{phang2}
{bf:5. Fitting a jump model to a kink.} Assumption 1.7 excludes it and the estimator
is inconsistent. Use {cmd:thkink}.

{phang2}
{bf:6. Ignoring regime-dependent heteroskedasticity.} It invalidates the LR*
interval. {cmd:estat hettest} checks it.

{phang2}
{bf:7. Splitting the sample by hand at a round number} and then reporting
regime-specific regressions as if the split were exogenous. The whole point of the
threshold literature is that the split is estimated, which changes the inference.

{marker refs}{...}
{title:References}

{phang}
Andrews, D. W. K., and W. Ploberger. 1994. Optimal tests when a nuisance parameter is
present only under the alternative. {it:Econometrica} 62: 1383-1414.
{browse "https://doi.org/10.2307/2951753":doi:10.2307/2951753}.

{phang}
Balke, N. S. 2000. Credit and economic activity: credit regimes and nonlinear
propagation of shocks. {it:Review of Economics and Statistics} 82: 344-349.
{browse "https://doi.org/10.1162/rest.2000.82.2.344":doi:10.1162/rest.2000.82.2.344}.

{phang}
Balke, N. S., and T. B. Fomby. 1997. Threshold cointegration.
{it:International Economic Review} 38: 627-645.
{browse "https://doi.org/10.2307/2527284":doi:10.2307/2527284}.

{phang}
Caner, M., and B. E. Hansen. 2001. Threshold autoregression with a unit root.
{it:Econometrica} 69: 1555-1596.
{browse "https://doi.org/10.1111/1468-0262.00257":doi:10.1111/1468-0262.00257}.

{phang}
Caner, M., and B. E. Hansen. 2004. Instrumental variable estimation of a
threshold model. {it:Econometric Theory} 20: 813-843.
{browse "https://doi.org/10.1017/S0266466604205011":doi:10.1017/S0266466604205011}.

{phang}
Chan, K. S., and R. S. Tsay. 1998. Limiting properties of the least squares estimator
of a continuous threshold autoregressive model. {it:Biometrika} 85: 413-426.
{browse "https://doi.org/10.1093/biomet/85.2.413":doi:10.1093/biomet/85.2.413}.

{phang}
Clements, M. P., and J. Smith. 1997. The performance of alternative
forecasting methods for SETAR models. {it:International Journal of
Forecasting} 13: 463-475.
{browse "https://doi.org/10.1016/S0169-2070(97)00017-4":doi:10.1016/S0169-2070(97)00017-4}.

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present only under
the alternative. {it:Biometrika} 74: 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}.

{phang}
Donayre, L. 2024. Likelihood-ratio-based confidence intervals for multiple threshold
parameters. {it:Studies in Nonlinear Dynamics & Econometrics} 29: 561-573.
{browse "https://doi.org/10.1515/snde-2023-0029":doi:10.1515/snde-2023-0029}.

{phang}
Donayre, L., Y. Eo, and J. Morley. 2018. Improving likelihood-ratio-based confidence
intervals for threshold parameters in finite samples. {it:Studies in Nonlinear
Dynamics & Econometrics} 22: 20160084.
{browse "https://doi.org/10.1515/snde-2016-0084":doi:10.1515/snde-2016-0084}.

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based inference
in single and multiple threshold models. {it:Journal of Econometrics} 110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under the
null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation. {it:Econometrica} 68:
575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}.

{phang}
Hansen, B. E. 2017. Regression kink with an unknown threshold. {it:Journal of Business
& Economic Statistics} 35: 228-240.
{browse "https://doi.org/10.1080/07350015.2015.1073595":doi:10.1080/07350015.2015.1073595}.

{phang}
Keenan, D. M. 1985. A Tukey nonadditivity-type test for time series
nonlinearity. {it:Biometrika} 72: 39-44.
{browse "https://doi.org/10.1093/biomet/72.1.39":doi:10.1093/biomet/72.1.39}.

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis in
nonlinear multivariate models. {it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}

{phang}
Kourtellos, A., T. Stengos, and C. M. Tan. 2016. Structural threshold regression.
{it:Econometric Theory} 32: 827-860.
{browse "https://doi.org/10.1017/S0266466615000067":doi:10.1017/S0266466615000067}.

{phang}
Lo, M. C., and E. Zivot. 2001. Threshold cointegration and nonlinear adjustment
to the law of one price. {it:Macroeconomic Dynamics} 5: 533-576.
{browse "https://doi.org/10.1017/S1365100501023057":doi:10.1017/S1365100501023057}.

{phang}
Luukkonen, R., P. Saikkonen, and T. Teräsvirta. 1988. Testing linearity against
smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.2307/2336599":doi:10.2307/2336599}.

{phang}
Seo, B. 2006. Bootstrap testing for the null of no cointegration in a threshold
vector error correction model. {it:Journal of Econometrics} 134: 129-150.
{browse "https://doi.org/10.1016/j.jeconom.2005.06.018":doi:10.1016/j.jeconom.2005.06.018}

{phang}
Terasvirta, T., and Y. Yang. 2014a. Linearity and misspecification tests for
vector smooth transition regression models. CREATES Research Paper 2014-04,
Aarhus University.

{phang}
Tsay, R. S. 1986. Nonlinearity tests for time series.
{it:Biometrika} 73: 461-466.
{browse "https://doi.org/10.1093/biomet/73.2.461":doi:10.1093/biomet/73.2.461}.

{phang}
Tsay, R. S. 1989. Testing and modeling threshold autoregressive processes.
{it:Journal of the American Statistical Association} 84: 231-240.
{browse "https://doi.org/10.1080/01621459.1989.10478760":doi:10.1080/01621459.1989.10478760}.

{phang}
Tsay, R. S. 1998. Testing and modeling multivariate threshold models.
{it:Journal of the American Statistical Association} 93: 1188-1202.
{browse "https://doi.org/10.1080/01621459.1998.10473779":doi:10.1080/01621459.1998.10473779}.

{phang}
Yu, P. 2014. The bootstrap in threshold regression. {it:Econometric Theory} 30:
676-714.
{browse "https://doi.org/10.1017/S0266466614000012":doi:10.1017/S0266466614000012}.

{phang}
Yu, P., Q. Liao, and P. C. B. Phillips. 2024. New control function approaches in
threshold regression with endogeneity. {it:Econometric Theory} 40: 1065-1119.
{browse "https://doi.org/10.1017/S0266466623000014":doi:10.1017/S0266466623000014}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Manual:  {manlink TS threshold}

{psee}
Help:  {helpb thregress}, {helpb thtest}, {helpb threshkit}
{p_end}
