{smcl}
{* *! xtgamfe.sthlp  version 1.1.1  2026-11-23}{...}
{vieweralsosee "xtgamfe technical notes" "help xtgamfe_technical"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtpoisson" "help xtpoisson"}{...}
{vieweralsosee "[R] glm" "help glm"}{...}
{vieweralsosee "ppmlhdfe (if installed)" "help ppmlhdfe"}{...}
{vieweralsosee "xtspj (if installed)" "help xtspj"}{...}
{viewerjumpto "Syntax" "xtgamfe##syntax"}{...}
{viewerjumpto "Quick start" "xtgamfe##quickstart"}{...}
{viewerjumpto "Description" "xtgamfe##description"}{...}
{viewerjumpto "Options" "xtgamfe##options"}{...}
{viewerjumpto "Weights" "xtgamfe##weights"}{...}
{viewerjumpto "Postestimation" "xtgamfe##postestimation"}{...}
{viewerjumpto "   predict" "xtgamfe##predict"}{...}
{viewerjumpto "   estat ape" "xtgamfe##ape"}{...}
{viewerjumpto "   estat ic" "xtgamfe##ic"}{...}
{viewerjumpto "   estat fepoisson" "xtgamfe##fepoisson"}{...}
{viewerjumpto "   estat park" "xtgamfe##park"}{...}
{viewerjumpto "When the estimator is valid" "xtgamfe##caveats"}{...}
{viewerjumpto "Other commands" "xtgamfe##benchmark"}{...}
{viewerjumpto "Stored results" "xtgamfe##results"}{...}
{viewerjumpto "Examples" "xtgamfe##examples"}{...}
{viewerjumpto "References" "xtgamfe##references"}{...}
{viewerjumpto "Author" "xtgamfe##author"}{...}
{p2colset 1 12 14 2}{...}
{p2col:{bf:xtgamfe} {hline 2}}Fixed-effects gamma regression with log link
for strictly positive panel outcomes{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtgamfe} {depvar} {indepvars} {ifin} {weight}
[{cmd:,} {it:options}]

{p 8 16 2}
{cmd:xtgamfe} [{cmd:,} {opt l:evel(#)} {opt ef:orm} {it:display_options}]

{pstd}
The second form replays the previous {cmd:xtgamfe} results.  At estimation,
an omitted {cmd:level()} uses {cmd:c(level)}.  At replay, an omitted
{cmd:level()} uses the confidence level stored in {cmd:e(level)}.

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt off:set(varname)}}log-scale offset in
log(mu_it)=alpha_i+x_it'beta+offset_it{p_end}

{syntab:SE/Robust}
{synopt:{opt vce(robust)}}sandwich standard errors clustered on the panel
variable; the default{p_end}
{synopt:{opt vce(cl:uster clustvar)}}sandwich standard errors clustered on
{it:clustvar}, in which the panels must be nested{p_end}
{synopt:{opt r:obust}, {opt cl:uster(clustvar)}}synonyms of {cmd:vce(robust)}
and {cmd:vce(cluster} {it:clustvar}{cmd:)}{p_end}
{synopt:{opt vce(oim)}}observed information of the share likelihood at the
maximum likelihood shape{p_end}
{synopt:{opt vce(boot:strap)}}bootstrap that resamples panels; see
{helpb bootstrap}{p_end}
{synopt:{opt vce(jack:knife)}}jackknife that deletes one panel at a time; see
{helpb jackknife}{p_end}
{synopt:{opt small}}t and F statistics with M-1 degrees of freedom, M the
number of clusters{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:c(level)} at
estimation and stored {cmd:e(level)} at replay{p_end}
{synopt:{opt ef:orm}}report exponentiated coefficients{p_end}
{synopt:{opt nofe}}do not store the fixed effects in {cmd:e(fe)} and
{cmd:e(fe_id)}, and store the command line without its {cmd:if} and {cmd:in}
qualifier and weight expression{p_end}
{synopt:{it:display_options}}{opt noci}, {opt nopv:alues},
{opt noomit:ted}, {opt vsquish}, {opt base:levels}, {opt cformat(%fmt)},
and the other options described in {helpb estimation options##display_options:[R] Estimation options}{p_end}

{syntab:Optimization}
{synopt:{opt tol:erance(#)}}strictly positive tolerance for the Newton
decrement; default {cmd:1e-6}{p_end}
{synopt:{opt iter:ate(#)}}maximum Newton iterations, at least 1; default
{cmd:1000}{p_end}
{synopt:{opt nolog}}suppress the iteration log{p_end}
{synopt:{opt from(matname)}}starting values: a vector with the terms' column
names, such as {cmd:e(b)}, or a 1 x K or K x 1 vector in term order{p_end}
{synoptline}

{pstd}
The data must be {helpb xtset}.  There is no constant because it is absorbed
by the panel effects, and there is no option {cmd:fe}: the fixed effects are
always estimated ({cmd:fe} is refused with a message).{p_end}
{pstd}
{it:indepvars} may contain factor variables and time-series operators; see
{help fvvarlist} and {help tsvarlist}.  {it:depvar} may not.{p_end}
{pstd}
{cmd:fweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed; see
{help xtgamfe##weights:Weights}.{p_end}
{pstd}
{cmd:by} and {cmd:svy} are not supported, and neither is {cmd:margins}:
{cmd:estat ape} reports average partial effects (see
{help xtgamfe##ape:estat ape} for why {cmd:margins} is not supported),
{cmd:estat fepoisson} compares the coefficients with fixed-effects Poisson,
and {cmd:estat park} runs Park's (1966) test of the variance function; see
{help xtgamfe##postestimation:Postestimation}.  {cmd:suest} and
{cmd:hausman} are not supported; to compare the coefficients with those of
fixed-effects Poisson, use {cmd:estat fepoisson}.


{marker quickstart}{...}
{title:Quick start}

{pstd}Fit with period indicators, standard errors clustered on the panels{p_end}
{phang2}{cmd:. xtset id time}{p_end}
{phang2}{cmd:. xtgamfe y x1 x2 i.time}{p_end}

{pstd}Average partial effects in the units of y, from the observed outcome,
which stay consistent for x1 and x2 when the period indicators absorb a
period pattern in the errors and the coefficients of x1 and x2 are
consistent{p_end}
{phang2}{cmd:. estat ape x1 x2, ybar}{p_end}

{pstd}Compare the coefficients with fixed-effects Poisson, with a bootstrap of
the clusters{p_end}
{phang2}{cmd:. estat fepoisson, seed(12345)}{p_end}

{pstd}With few clusters (households, say), t and F statistics on M-1 degrees
of freedom{p_end}
{phang2}{cmd:. xtgamfe y x1 x2 i.time, vce(cluster hh) small}{p_end}

{pstd}For restricted data: no fixed effects or panel identifiers in
{cmd:e()}, and {cmd:e(cmdline)} without its {cmd:if} and {cmd:in} qualifier
and weight expression{p_end}
{phang2}{cmd:. xtgamfe y x1 x2 i.time, nofe}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtgamfe} fits a gamma regression with a log link and a fixed effect for
each panel to a strictly positive outcome.  The conditional mean is

{phang2}mu_it = exp(alpha_i + x_it'beta + offset_it).

{pstd}
For any value of beta the fixed effects have a closed-form solution, so they
are substituted out and the coefficients are found by Newton's method on a
criterion in beta alone.  That criterion is convex.  No indicator variables
are created, and the cost per iteration is linear in the number of
observations for a given number of regressors.  Roebuck (2026) describes the
estimator, the conditions under which it is consistent, and the simulations
quoted below.

{pstd}
Under the gamma model the within-panel shares of the outcome have a
distribution that does not involve the fixed effects (Chamberlain 1985),
and the coefficients are estimated consistently as the number of panels
grows with the number of periods fixed; only the shape suffers from the
incidental-parameter problem (Dhaene and Jochmans 2019).

{pstd}
The same coefficients are produced by {cmd:glm} with family gamma, log link,
and an indicator for every panel; by {cmd:xtspj} with
{cmd:model(exponential)} or {cmd:model(gamma)} and {cmd:method(none)} (Sun
and Dhaene 2019), when its optimizer reaches the minimum; and by a
conditional fixed-effects Poisson regression of a constant on the same
regressors with ln(y) as offset, with the signs reversed.  After {cmd:glm}
with panel indicators, {cmd:predict, mu} and {cmd:margins, dydx()} with
{cmd:vce(unconditional)} give the same fitted means and average partial
effects with the same standard errors; see
{help xtgamfe##benchmark:Other commands}.

{pstd}
What {cmd:xtgamfe} adds is one-step fitting at a cost per iteration linear
in the number of observations, with standard errors clustered on panels or
on a higher level, weights, factor variables, and time-series operators; two
estimates of the gamma shape that are consistent with the number of periods
fixed under the gamma model; average partial effects from the observed
outcome ({cmd:estat ape, ybar}); and integrated postestimation (fitted
means, fixed effects, average partial effects, and comparisons with
fixed-effects Poisson).

{pstd}
Before using the estimator, read
{help xtgamfe##caveats:When the estimator is valid}.  In particular,
fixed-effects Poisson regression of the outcome itself
({cmd:xtpoisson, fe vce(robust)}) is consistent under weaker conditions on
how the errors of a panel relate to one another (though it needs moment
conditions on the level-weighted errors that {cmd:xtgamfe} does not), and
period indicators should be included when the errors may be serially
correlated.  The rules for edge cases (which observations are used, weight
expressions, omitted terms, numeric range, exact fits, the checks that
{cmd:predict} and {cmd:estat} make, saved results, and the platforms tested)
are collected in {help xtgamfe_technical##technotes:Technical notes}, in the companion
help file {help xtgamfe_technical}, with the
{help xtgamfe_technical##methods:Methods and formulas}.

{marker tn_onecl}{...}
{pstd}
Coefficients identified by one cluster (a term that varies within panels in
only one cluster, or a direction of the coefficients that the other clusters
do not identify), what the command reports for them, and which combinations
of them keep a meaningful standard error are described in
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt offset(varname)} adds {it:varname} to the log mean with its coefficient
constrained to one.  It enters the fixed effects, {cmd:predict, mu}, and
(following official convention) the default {cmd:predict, xb}.  It enters
only through its differences within panels; see
{help xtgamfe_technical##tn_units:Units, origins and numeric range}.

{dlgtab:SE/Robust}

{phang}
{opt vce(robust)}, the default, is the sandwich estimator clustered on the
panel variable, with the factor G/(G-1) for G panels.

{phang}
{opt vce(cluster clustvar)} clusters on {it:clustvar}, which may be numeric
or string.  {opt robust} and {opt cluster(clustvar)}, as official commands
accept them, are synonyms of {cmd:vce(robust)} and
{cmd:vce(cluster} {it:clustvar}{cmd:)}; neither may be combined with
{cmd:vce()}.  Every panel must lie within one cluster (households within
sampling units, persons within states); otherwise the command stops with
return code 498.  The factor is M/(M-1) for M clusters.  Clustering on the
panel variable itself is {cmd:vce(robust)}.

{phang}
{opt vce(oim)} is the inverse observed information of the share likelihood
(the gamma model's likelihood of the within-panel shares of the outcome,
which does not involve the fixed effects; see
{help xtgamfe_technical##methods:Methods}) at the maximum likelihood estimate of the
shape, {cmd:e(kappa_ml)}: the inverse Hessian of the criterion divided by
{cmd:e(kappa_ml)}.  The coefficient table labels its standard errors OIM.
It is valid if the errors are independent gamma variates with a common
shape and the panels are independent of each other.  That is sufficient,
not necessary: a correctly specified share likelihood (within-panel shares
that follow the law it assumes, whatever the law of the panel totals), with
independent panels, also justifies the information matrix and the shape
estimate; reading {cmd:e(kappa_ml)} as the shape of the outcome's marginal
gamma distribution, or its inverse as the dispersion, needs the gamma model
itself.  It is not allowed with
{cmd:pweight}s, {cmd:iweight}s, or {opt small}, and it is not available for
an exact or near-exact fit, whose shape is not finite (see
{help xtgamfe_technical##tn_exact:Exact fits}).

{phang}
{opt vce(bootstrap)} and {opt vce(jackknife)} resample or delete whole
panels.  Suboptions such as {cmd:reps()} and {cmd:seed()} go inside the
parentheses, for example {cmd:vce(bootstrap, reps(500) seed(1))}.  Weights
are not allowed with {cmd:vce(bootstrap)}; {cmd:vce(jackknife)} allows
them.  Both treat the panel as the independent unit, also when panels are
nested in larger clusters, and neither accepts a {cmd:cluster()} suboption
(the command stops with return code 198 and points to the prefixes).  To
resample or delete clusters that nest panels (households, sites), use the
prefix: {cmd:jackknife, cluster(}{it:clustvar}{cmd:):} {cmd:xtgamfe} ...,
which deletes one cluster at a time and reports t statistics with M-1
degrees of freedom, or the {helpb bootstrap} prefix with its
{cmd:cluster()}, {cmd:idcluster()}, and {cmd:group()} options (the data
{cmd:xtset} on the variable named in {cmd:group()}; see
{help xtgamfe_technical##tn_sample:Sample rules} for its limits with {cmd:if},
{cmd:in}, and time-series operators).  Only the coefficients are resampled;
see {help xtgamfe_technical##tn_resample:Resampling} for the shape's standard error,
for the clusters of a prefix, and for what {cmd:e(N_clust)} counts.

{phang}
{opt small} posts {cmd:e(df_r)} = M-1, where M is the number of clusters
({cmd:e(N_clust)}: the panels under {cmd:vce(robust)}, the clusters under
{cmd:vce(cluster} {it:clustvar}{cmd:)}), so that the coefficient table,
{cmd:test}, and {cmd:lincom} report t and F statistics, and the test of all
coefficients is reported as F = chi2/df with (df, M-1) degrees of freedom,
as {cmd:regress} does with clustered standard errors.  The standard errors
themselves do not change.  {cmd:estat ape} and {cmd:estat fepoisson} then
use t critical values as well.  {opt small} is not allowed with
{cmd:vce(oim)}, whose standard errors rest on the information, or with
{cmd:vce(bootstrap)}; with {cmd:vce(jackknife)}, which already reports t
statistics with M-1 degrees of freedom, it changes nothing.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb level}.

{phang}
{opt eform} exponentiates each coefficient, exp(b_j), with standard errors
and confidence limits transformed accordingly.  For a regressor that enters
the index linearly and without interactions, exp(b_j) is the ratio of
conditional means for a one-unit change in it; for a term of a polynomial
or an interaction it is not the ratio for a change in one variable.
{cmd:e(b)} and {cmd:e(V)} stay on the coefficient scale.

{phang}
{opt nofe} omits the panel-level matrices {cmd:e(fe)} and {cmd:e(fe_id)}
(by default both are stored, one row per panel of the estimation sample with
the panel's identifier, for up to 5,000 panels, and a one-line note says
so), and stores {cmd:e(cmdline)} without the {cmd:if} and {cmd:in}
qualifier and without a weight expression, which can name values of the
data, with a note.  Saved estimates retain the rest of the fitted
command, the weight expression in {cmd:e(wexp)}, and the coefficient labels,
which for a factor variable include its levels.  Check those fields for
identifiers before exporting a fit from restricted data; see
{help xtgamfe_technical##tn_saved:Saved results and identifiers}.
{cmd:predict, fe} gives the fixed effects with or without {opt nofe}.

{dlgtab:Optimization}

{phang}
{opt tolerance(#)} sets the convergence tolerance.  A fit is declared
converged when the Newton decrement, sqrt(g'H^-1 g), is no larger than the
tolerance.  The decrement does not depend on the units of the regressors;
half its square approximates the remaining reduction in the criterion.  The
gradient norm is reported but is not a stopping rule.  See
{help xtgamfe_technical##tn_conv:Convergence} for a tolerance below double precision
and for near-exact fits.

{phang}
{opt iterate(#)} sets the maximum number of Newton iterations, including
any taken after convergence for a near-exact fit; {cmd:e(iterations)} never
exceeds it.  A fit that does not converge stops with return code 430 and
posts nothing (see {help xtgamfe_technical##tn_conv:Convergence}).

{phang}
{opt nolog} suppresses the iteration log, as {cmd:set iterlog off} does
unless the option {opt log} is typed.

{phang}
{opt from(matname)} supplies starting values for the estimated terms of
{it:indepvars}, which are listed in {cmd:e(indepvars)}.  A vector whose
column names (row names, for a column vector) are those terms, such as
{cmd:e(b)} from the same specification ({cmd:matrix b0 = e(b)}), is matched
by name: every term needs one column, and a column that is not a term of the
model must be a base level or an omitted term, which are ignored.  A vector
none of whose names is a term of the model is taken in the order of the
terms, as a 1 x K or K x 1 vector.  Otherwise the command stops with a
message that lists the terms.  By default the command starts from the
within-panel least-squares regression of ln(y)-offset on the regressors.


{marker weights}{...}
{title:Weights}

{pstd}
With weights a_it the command minimizes the weighted criterion; the fixed
effect of panel i becomes the log of the weighted mean of
y_it exp(-x_it'beta-offset_it).  The fit freezes one realized set of
weights; see {help xtgamfe_technical##tn_weights:Weight expressions and frozen weights}.

{phang}
{cmd:fweight}s must be integers and constant within panel.  A weight of k
stands for k identical panels: results equal those from the data expanded k
times with each copy given its own panel identifier and, when the standard
errors are clustered on a variable that nests the panels, the cluster of the
original panel, with one exception: the check for coefficients identified
by one cluster counts the copies of a panel once, whereas the expanded data
count each copy as a cluster (see
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).
After {cmd:vce(jackknife)} the covariance matrix and its degrees of freedom
equal those of the expanded data, but {cmd:e(N_clust)} counts the panels as
held in the data (see
{help xtgamfe_technical##tn_resample:Resampling}).
{cmd:e(N)} and {cmd:e(N_g)} are the expanded counts.

{phang}
{cmd:pweight}s may vary within panel.  They enter the sandwich through the
weighted panel scores.  {cmd:e(N)} is the number of observations.  The
conditions in {help xtgamfe##caveats:When the estimator is valid} carry over
when the weights are constant within panel.

{pmore}
When they vary within panel, the shares in the score are weighted and
exchangeable errors no longer center them, even under the gamma model:
weights whose within-panel pattern follows that of the regressors can then
bias the coefficients.  With gamma errors of shape 2 and weights that rise
from 1 to 4 over four periods, the coefficient of a treatment that switches
on in the last period (true value 0.5) is biased by -0.085 as the number of
panels grows, and by -0.17 with two periods and weights of 1 and 2 (Roebuck
2026, sec. 2.8).  Period indicators remove that bias for the other
identified slopes (not for the contrasts of the period indicators
themselves, nor for a regressor whose own time pattern is that of the
weights, which the indicators absorb) when the weights follow the same
deterministic pattern in every panel and the errors are independent of the
regressors; they need not when the pattern differs between panels in a way
related to the regressors.  The command prints a note when the weights vary
within panel.  ({cmd:xtpoisson, fe} does not have this problem and does not
allow such weights.)

{phang}
{cmd:iweight}s are treated as {cmd:pweight}s in the estimates and in the
robust and clustered covariance matrices.  (With {cmd:vce(jackknife)} the
two can give different standard errors, because Stata's jackknife treats the
two kinds of weight differently.)

{pstd}
Results do not depend on the scale of {cmd:pweight}s or {cmd:iweight}s
(see {help xtgamfe_technical##tn_units:Units, origins and numeric range}).  The shape
estimates and the log likelihood are computed only when the weights are
constant within panel; otherwise they are missing and {cmd:e(shape_status)}
is {cmd:weights_vary_within_panel}.


{marker postestimation}{...}
{title:Postestimation}

{pstd}
{cmd:test}, {cmd:testparm}, {cmd:lincom}, {cmd:nlcom}, {cmd:contrast},
{cmd:pwcompare}, {cmd:estimates}, and {cmd:estat summarize} and
{cmd:estat vce} work as after official estimators.  {cmd:e(b)} has one column
for every term of the expanded factor-variable list, including base levels.
{cmd:predict}, {cmd:estat ape}, {cmd:estat park}, and {cmd:estat fepoisson}
check that the data are those of the fit (see
{help xtgamfe_technical##tn_data:Data checks}).

{marker predict}{...}
{title:predict}

{p 8 16 2}
{cmd:predict} [{it:type}] {newvar} {ifin} [{cmd:,} {it:statistic}
{cmd:nooffset} {opt alpha(varname)}]

{synoptset 14 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}x_it'b+offset_it: includes the offset and excludes the
fixed effect; the default{p_end}
{synopt:{opt stdp}}standard error of x_it'b, from {cmd:e(V)}; the offset and
the fixed effect contribute nothing{p_end}
{synopt:{opt fe}}fixed effect alpha_hat_i of the observation's panel{p_end}
{synopt:{opt mu}}fitted mean exp(alpha_hat_i+x_it'b+offset_it){p_end}
{synopt:{opt r:esiduals}}y_it - mu_it{p_end}
{synopt:{opt sc:ore}}y_it/mu_it - 1{p_end}
{synoptline}

{pstd}
With no statistic, {cmd:xb} is assumed, and a note says so.  {cmd:xb} and
{cmd:stdp} describe the linear index under the normalization of the fit (an
omitted term has a zero coefficient, and the fixed effect is left out).
They are available for any observation whose covariate values the model's
coding represents, in any panel, and they are not compared with the values
of the observation's panel.  {cmd:xb} is formed in double precision, offset
included, and stored once in the type requested.  {cmd:nooffset}, allowed
only with {cmd:xb}, leaves the offset out.  {cmd:stdp} is missing, with a
note, where the linear prediction depends on a coefficient that rests on
one cluster (see {help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).

{pstd}
{cmd:fe} belongs to the panel, not to the observation: it is returned for
every observation of a panel that was in the estimation sample, whatever
that observation's covariate values, and it is always computed from the
estimation sample:

{phang2}alpha_hat_i = ln[ sum_t a_it y_it exp(-x_it'b-offset_it) / sum_t a_it ].

{pstd}
{cmd:mu} and {cmd:residuals} describe the fitted mean of the observation's
panel, exp(alpha_hat_i+x_it'b+offset_it), and are returned for the
observations of an estimated panel, including observations outside the
estimation sample, whose covariate values the estimation sample identifies
for that panel (see {help xtgamfe_technical##tn_support:Covariate values the sample does not identify}).

{pstd}
{cmd:score} is the derivative of minus the criterion with respect to the
linear index, and equals the Pearson residual: one relative residual per
observation, not the score vector of the coefficients (that is x_it times
it) and not standardized by the shape.  It is returned for the estimation
sample only, where, at the fitted fixed effects and coefficients (to
optimization error), it sums to zero within each panel (with weights, its
weighted sum does) and is orthogonal to the regressors; at other fixed
effects given with {cmd:alpha()} it need not (with the fitted ones plus
ln(2) its mean is -1/2).  It needs
{cmd:e(sample)}, also with {cmd:alpha()} (after {cmd:estimates use} it
stops with return code 459).  It is computed, and its values checked, on
the estimation sample alone, so observations outside it, whatever their
values, do not affect it.

{pstd}
{cmd:fe}, {cmd:mu}, {cmd:residuals}, and {cmd:score} recompute the fixed
effects from the estimation sample, which must be unchanged since estimation
(see {help xtgamfe_technical##tn_data:Data checks}); they are not available after
{cmd:estimates use}, which does not restore the estimation sample.

{phang}
{opt alpha(varname)} takes the fixed effects from {it:varname} instead of
recomputing them from the estimation sample.  This gives fitted means at
changed covariate values: save the fixed effects with {cmd:predict, fe},
change the covariates, and type {cmd:predict} {it:newvar}{cmd:, mu alpha(}{it:varname}{cmd:)}.
It is allowed with {cmd:mu}, {cmd:residuals}, and {cmd:score}.  The fixed
effects given are used on the uncentered scale, as the sum of the fixed
effect, x_it'b and the offset: with very large origins or offsets (as an
offset of 2^52) a saved fixed effect cannot hold enough digits, and the
fitted means lose precision.  For a change in a regressor that enters
linearly, the fitted mean times the exponential of the change in the index
is exact (see {help xtgamfe##examples:Examples}).  Because the
fixed effects are not recomputed, the data are not compared with the
estimation sample: {cmd:predict} does not check that the outcome, weights,
offset, or other inputs are unchanged, or that {it:varname} holds the fixed
effects of the results in memory; that responsibility passes to the user.
The checks of the covariate values still apply (see
{help xtgamfe_technical##tn_support:Covariate values the sample does not identify}),
and so does the check of the {cmd:xtset} settings when the model has
time-series operators.

{pstd}
With a fixed number of periods an individual fixed effect is a noisy estimate
and does not become precise as the number of panels grows.  At the true
coefficients exp(alpha_hat_i) is unbiased for exp(alpha_i) when the errors
have mean one, so the fitted mean of a panel is unbiased there but stays
noisy; alpha_hat_i itself is biased downward.  With estimated coefficients,
and when period indicators absorb a period pattern in the errors (see
{help xtgamfe##caveats:When the estimator is valid}), the fitted means can
also be off in level.

{marker ape}{...}
{title:estat ape}

{p 8 16 2}
{cmd:estat ape} [{varlist}] [{cmd:,} {opt l:evel(#)} {opt yb:ar}
{opt fin:ite} {opt del:ta(#)}]

{pstd}
reports average partial effects on the conditional mean, averaged over the
observations of the estimation sample (so a panel with more observations
counts for more) with the estimated fixed effects (and the estimation
weights, if any).  For a continuous variable the effect is the average
derivative of mu_it, taken through any polynomial or interaction terms in
which the variable appears; with {opt finite}, the average change in mu_it
when the variable rises by one unit, or by {opt delta(#)}.  For a factor
variable it is, for each level, the average change in mu_it from the base
level, holding everything else fixed.  A variable that is also the offset
moves the offset with it: its effect includes the offset's (whose
coefficient is one), so it equals the effect of the same variable in the
equivalent model without the offset.  An offset in a different variable is
held fixed.

{pstd}
The {it:varlist} names variables of the fitted model; a factor-variable
prefix is removed ({cmd:i.time} is {cmd:time}), and a wildcard or a range
is matched against the variables of the model, not of the dataset.  The
effect of a variable takes in all its interactions, so an interaction
({cmd:c.x1#c.x2}) is refused, as are a lag or lead ({cmd:L.x1}) and a
prefix that is not an operator ({cmd:junk.x1}), with a message that lists
the variables that can be requested.

{pstd}
With no {it:varlist}, every variable in the model is reported, with four
exceptions that are listed in notes:

{phang2}
o  Variables that enter the model with a time-series operator.  The command
does not report effects for time-series terms, whose coefficients can still
be well identified.  To report the effect of a lag, generate it as an
ordinary variable, as in {cmd:generate double x_l1 = L.x}, and fit the model
with it in place of {cmd:L.x}: in {cmd:estat ape x x_l1, ybar}, the sum of
the two effects is the average derivative of the mean for a common small
shift in x and its lag, which is a long-run effect only under a
distributed-lag reading with no further dynamics in the outcome, and
{cmd:r(V)} gives the variances and the covariance from which its variance
follows.

{phang2}
o  Variables that do not vary within panel in the estimation sample; their
effect on the mean is absorbed by the fixed effects and is not reported,
even when an interaction of the variable with another variable is
identified.

{phang2}
o  Variables that enter both as a factor and as a continuous variable (as
{cmd:time} in {cmd:i.time i.g#c.time}), which, requested by name, are
refused.

{phang2}
o  Effects that the estimation sample does not identify; see
{help xtgamfe_technical##tn_support:Covariate values the sample does not identify}.

{pstd}
When the model has no base level for a factor, the base is chosen in this
order: the level of its main effect that {cmd:xtgamfe} omitted, if it
omitted exactly one; otherwise the coding of the values of the factor that
no term names, if the estimation sample has such values; otherwise the
numerically lowest named level.  A note says which and shows the value.

{pstd}
The effects are averaged over the whole estimation sample.  Effects for a
subpopulation ({cmd:if} or {cmd:in}, or {cmd:over()}) are not available in
this version, and {cmd:margins} is not supported: the fitted mean depends on
fixed effects that are recomputed from the data when the coefficients
change, and {cmd:margins} would treat them as fixed and omit that source of
variation, whereas {cmd:estat ape} reports standard errors that allow for
it.

{pstd}
{cmd:estat ape} computes its own standard errors, from the influence
functions of the averages, without using {cmd:e(V)}.  The sandwich allows
for the sampling variation of the coefficients, of the fixed effects, and of
the sample over which the average is taken, clustered on {cmd:e(clustvar)}
with the factor M/(M-1).  It reports normal (z) intervals, or t intervals
with {cmd:e(df_r)} degrees of freedom when the fit posted {cmd:e(df_r)}
(with {opt small}, or {cmd:vce(jackknife)}).  After {cmd:vce(oim)},
{cmd:vce(bootstrap)}, or {cmd:vce(jackknife)}, the same sandwich, clustered
on panels, is reported: neither the observed information nor the
replications enter (after the {cmd:jackknife} or {cmd:bootstrap} prefix with
{cmd:cluster()}, it is clustered on that variable, which must nest the
panels; see {help xtgamfe_technical##tn_resample:Resampling}).

{pstd}
The average is consistent as the number of panels grows with the number of
periods fixed when the condition displayed in
{help xtgamfe##caveats:When the estimator is valid} holds and the averaged
quantity has a finite mean (for a polynomial or an interaction, a finite
mean of the outcome alone is not enough: the effect must be integrable); the
standard error needs, in addition, finite second moments of the panels'
(clusters') contributions to the influence function.  It is in general not
consistent when that condition fails and the coefficients are consistent
only because period indicators are included: the period coefficients then
absorb the differences between periods in the errors, and the fitted means
are off by a factor.  Use {opt ybar} in that case: it estimates an effect
consistently when the coefficients that enter the change are consistent.

{pstd}
Without {opt ybar}, after a model with an estimated term that has a level of
the time variable, alone or in an interaction with other factor variables
({cmd:i.time}, {cmd:i.g#i.time}), a note under the table points to
{opt ybar} on that condition.  Levels of the time variable that enter only
in interactions with continuous variables ({cmd:c.x#i.time}) let slopes vary
by period and are not period indicators; the note then says that an effect
with {opt ybar} is consistent when the coefficients that enter the change
are consistent, and an effect without it, which comes from the fitted means,
when every coefficient is consistent.

{pstd}
When a coefficient rests on one of the clusters used, the effects that
depend on it through the change they describe are shown without standard
errors, and a note says what the other standard errors leave out.  The check
is made for those clusters whatever the variance of the fit: after
{cmd:vce(oim)}, {cmd:vce(bootstrap)}, {cmd:vce(jackknife)}, or a
{cmd:bootstrap} or {cmd:jackknife} prefix, by fitting the model again,
quietly, with {cmd:vce(cluster)} on them (the results in memory and the data
are left as they were).  When the fit warned for another reason that
{cmd:e(V)} has deficient rank, the note is repeated under the table (see
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).
When every cluster contributes the same, to rounding, to the influence
function of an effect (as with identical panels), the variance of that
effect is zero: the effect is shown without standard error, test, and
interval, with a note, and {cmd:r(zerovar)} names it.  After an exact fit, a
note says that the standard errors reflect only the sampling of the panels
over which the effects are averaged (see
{help xtgamfe_technical##tn_exact:Exact fits}).  For intervals when the
level of the outcome is skewed, see
{help xtgamfe_technical##tn_apeci:Intervals for average partial effects}.

{phang}
{opt ybar} computes each effect with the observed outcome in place of the
fitted mean.  For a regressor that enters the index linearly, the effect is
b_j times the mean of the outcome over the estimation sample (weighted as in
the fit):

{phang2}theta_j = b_j ybar,   ybar = sum_it a_it y_it / sum_it a_it.

{pmore}
Because E(y_it | X_i, alpha_i) = mu_it, the population average of the
derivative, E[sum_t b_j mu_it]/E[T_i], equals b_j E[sum_t y_it]/E[T_i], so
theta_j is consistent whenever b_j is and that conditional mean holds on the
periods averaged (below), also when period indicators absorb a period
pattern in the errors and the fitted means are off.  Santos Silva and Kemp
(2016, slide 17) and Martin (2017) give this identity, and the estimate
b_j ybar, for the exponential model fitted by fixed-effects Poisson
regression.  The identity needs that conditional mean on the periods
actually averaged: given the pattern of observation, and given the weights
if any.  Share centering and consistent slopes do not supply it when which
periods are observed, or the weights, depend on the errors.

{pmore}
The same holds in general: for a continuous variable the effect is the
weighted average of y_it times the derivative of the index (through
polynomials and interactions), and for a factor level it is the weighted
average of y_it[exp(x_it(l)'b - x_it'b) - exp(x_it(base)'b - x_it'b)], which
needs consistent coefficients for the terms that the change moves (it does
not help for the contrasts of the period indicators themselves).  For
changes other than the derivative of a term that enters linearly, it needs
in addition an integrable envelope: the outcome times the proportional
change must be bounded, for coefficients near their limits, by a quantity
with a finite mean (bounded counterfactual designs with an outcome of finite
mean are a simple case).

{pmore}
Its standard error comes from its own influence function, clustered as
above: per panel, sum_t a_it(f_it - theta)/sum(a) - J H^-1 g_i, with f_it
the averaged quantity, g_i the panel score, H the Hessian, and J the
derivative of theta with respect to b, which for a regressor that enters
linearly is ybar times the unit vector of b_j.  The fitted means are not
used with {opt ybar}, and are not checked: an offset that makes some of them
overflow does not prevent the effects.  When share centering holds, the two
kinds of effect estimate the same quantity.  Their precision is similar: on
the example data the standard error with {opt ybar} is about 5 percent
larger, and in a simulation with period-specific dispersion its sampling
standard deviation was about 1.9 to 3.4 percent smaller (Roebuck 2026,
sec. 4.8).  With {opt ybar}, when the table includes contrasts of the period
indicators ({cmd:i.}{it:timevar}, alone or in an interaction), a note under
it recalls that these contrasts are not consistent when the indicators
absorb a period pattern in the errors.

{phang}
{opt finite} reports, for a continuous variable x_j, the average change in
the mean when x_j rises by h (one by default; {opt delta(#)} sets h and
implies {opt finite}), all else fixed: the average of
mu_it[exp(c_it'b) - 1], where c_it is the change in the terms.  For a
regressor that enters linearly this is

{phang2}theta_j = c m,   c = exp(b_j h) - 1,   m = sum_it a_it mu_it / sum_it a_it,

{pmore}
the average fitted mean times the relative change of the mean.  Its
standard error comes from the influence function above, with
J = sum_it a_it mu_it[(exp(v_it) - 1)(x_it - xbar_i) + exp(v_it) c_it]'/sum_it a_it,
v_it = c_it'b, which for a linear regressor is
J = c dm/db' + h exp(b_j h) m e_j', where
dm/db' = sum_it a_it mu_it (x_it - xbar_i)'/sum_it a_it and xbar_i is the
mean of x over panel i weighted by p_it = a_it y_it/mu_it (minus xbar_i is
the derivative of the profiled fixed effect with respect to b).  exp(v) - 1 is evaluated without cancellation,
so a small change is not lost: as h goes to zero, the effect divided by h,
and its standard error divided by |h|, tend to the derivative and its
standard error, also when the regressor is measured in very large units.

{pmore}
{opt finite} thus has two variants.  Without {opt ybar} it is the change in
the average fitted mean, as above.  With {opt ybar} as well, the observed
outcome replaces the fitted mean: the effect is the average of
y_it[exp(c_it'b) - 1], the observed outcome times the relative change of the
mean, which is theta_j = c ybar for a linear regressor and, like the other
effects of {opt ybar}, is consistent when the coefficients that the change
moves are, also when period indicators absorb a period pattern in the
errors; its standard error comes from its own influence function, with
J = sum_it a_it y_it exp(v_it) c_it'/sum_it a_it, which for a linear
regressor is h exp(b_j h) ybar e_j'.  Factor levels are reported as
without {opt finite}, and the note on the change is printed only when the
table has a continuous variable.

{pstd}
{cmd:estat ape} stores {cmd:r(b)}, {cmd:r(V)}, {cmd:r(N)},
{cmd:r(N_clust)}, {cmd:r(level)}, {cmd:r(clustvar)}, {cmd:r(method)}
({cmd:fitted} or {cmd:ybar}), {cmd:r(change)} ({cmd:derivative} or
{cmd:finite}), {cmd:r(skipped)} (the variables and effects listed in the
notes as not reported, if any), {cmd:r(onecl)} (the effects shown without
standard errors because they depend on a coefficient that rests on one
cluster, if any), {cmd:r(zerovar)} (the effects shown without standard
errors because every cluster contributes the same to their influence
functions, if any), with {opt ybar} {cmd:r(ybar)}, with
{opt finite} {cmd:r(delta)} (the step h), and, with t intervals,
{cmd:r(df_r)}.

{marker ic}{...}
{title:estat ic}

{p 8 16 2}
{cmd:estat ic} [{cmd:,} {opt n(#|exp)}]

{pstd}
reports Akaike's and the Bayesian information criterion from {cmd:e(ll)},
the log likelihood of the within-panel shares at the coefficients and the
maximum likelihood shape.  The parameter count is the number of estimated
coefficients plus one for the shape.  Use {cmd:estat ic} rather than
{cmd:estimates stats}: {cmd:estimates stats} counts the rank of {cmd:e(V)}
and leaves out the shape, so when {cmd:e(V)} has full rank and N is the
same, its criteria are lower by 2 and by ln(N), and when the clustered
{cmd:e(V)} has deficient rank (fewer clusters than coefficients, or a
coefficient that rests on one cluster), it counts fewer parameters still.

{pstd}
BIC uses N = {cmd:e(N)}, the number of observations; {opt n()} sets another
count, a positive number or an expression that evaluates to one, such as the
number of panels, {cmd:n(e(N_g))}.  The independent contributions to the
unweighted likelihood are the panels, so {cmd:n(e(N_g))} is the choice that
matches it; the default, as after official estimators, is the number of
observations.

{pstd}
The criteria compare only {cmd:xtgamfe} models whose likelihoods are of the
same shares: the same outcome (so the same observed within-panel shares),
the same panel variable (the same grouping of the observations), the same
estimation sample, and the same weights; changing any of these changes the
response or the objective.  {cmd:e(ll)} is not comparable with the log
likelihood of {cmd:glm}, {cmd:poisson}, or any other model of the outcome
itself.  With {cmd:fweight}s, which stand for replicated panels, {cmd:e(ll)}
is the likelihood of the replicated data.  With {cmd:pweight}s or
{cmd:iweight}s constant within panel, {cmd:e(ll)} is a weighted
pseudo-likelihood, and reading AIC and BIC from it as from a likelihood
needs a justification that the command does not supply; a note under the
table says so.  The criteria are not available when {cmd:e(ll)} is missing
(weights that vary within panel, or an exact fit).  {cmd:estat ic} stores
{cmd:r(S)}.

{marker fepoisson}{...}
{title:estat fepoisson}

{p 8 16 2}
{cmd:estat fepoisson} [{cmd:,} {opt r:eps(#)} {opt seed(#)} {opt l:evel(#)}
{opt nodots}]

{pstd}
fits fixed-effects Poisson regression, {cmd:xtpoisson} {it:depvar}
{it:indepvars} {cmd:if e(sample), fe vce(robust)} (with the offset of the
fit, if any), to the observations of the {cmd:xtgamfe} fit, shows the two
coefficient vectors side by side, and tests the difference of each pair,
and all of them jointly, with a bootstrap of the differences.  Each
replication fits both estimators to a resample of the clusters of the fit
(the panels, or the clusters in {cmd:e(clustvar)} when they nest the
panels), in which each resampled cluster gets its own identifier; see
{help xtgamfe_technical##tn_fep:estat fepoisson: the model compared} for the details
and for the do-file code that gives the same replications.  The standard
errors shown for {cmd:xtpoisson} are its {cmd:vce(robust)} ones, clustered
on panels ({cmd:xtpoisson, fe} does not allow {cmd:vce(cluster)}).  For a
coefficient that rests on one cluster, the {cmd:xtgamfe} standard error is
not shown when the fit's standard errors are clustered or resampled (the
clusters cannot measure that coefficient's sampling variation), but it is
after {cmd:vce(oim)}, whose standard errors do not use the clusters; the
{cmd:xtpoisson} standard error is not shown when the clusters of the fit
are the panels (unless the fit used {cmd:vce(cluster)} with a variable other
than the panel variable), because its sandwich clusters on the panels too.
With such a variable it is shown as {cmd:xtpoisson} reports it, also when
that variable only relabels the panels; for a term that varies within
panels in only one panel, it does not measure the term's sampling variation
either.  Weights
are not allowed (the {cmd:bootstrap} prefix does not accept them), and the
results must come from {cmd:xtgamfe} itself, not from a prefix typed before
it; after {cmd:vce(oim)}, {cmd:vce(bootstrap)}, or {cmd:vce(jackknife)} the
panels are resampled.  The refits use the fit's {opt tolerance()} and
{opt iterate()} and start from the default values, so after a fit capped by
a small {opt iterate()} (as one started with {opt from()} can be), fit the
model again without the cap before {cmd:estat fepoisson}; otherwise the
bootstrap can stop with return code 430, or leave out replications whose
refits do not converge.

{pstd}
The differences are tested one by one with the bootstrap standard errors
and z statistics (t with {cmd:e(df_r)} degrees of freedom after {opt small}
or {cmd:vce(jackknife)}).  The joint test refers the Wald statistic D of the
bootstrap covariance matrix of the k differences to a Hotelling-type F
approximation: F = (B-k)/{c -(}k(B-1){c )-} D, with k and B-k degrees of
freedom, B being the number of replications used.  The F distribution is
exact for a normal vector and an independent Wishart estimate of its
covariance; a bootstrap covariance is neither, and the approximation allows,
under a normal approximation to the differences, for the variability of a
covariance estimated from a finite number of resamples.  The joint test is
reported only when that matrix has full rank (its rank, found from its
eigenvalues on the correlation scale, is at most B-1); otherwise it is
withheld with a note, because a quadratic form in a generalized inverse of a
singular covariance tests only some of the differences, and which ones would
depend on their order.

{pstd}
Use many more successful resamples than tested coefficients (the default,
999, is ample for a few differences).  With fewer than 199 replications used,
a note says that the standard errors, the p-values of the single
differences, and the joint test rest on few draws: a bootstrap standard
error from B replications has a relative error of about 1/sqrt(2B) (about 5
percent with 199, 10 percent with 50).  Referred to a chi-squared
distribution, D rejects far too often when B is not much larger than k: on
the first 120 panels of the example data, after
{cmd:xtgamfe cost x1 x2 i.time} (five differences),
{cmd:estat fepoisson, reps(7) seed(1)} gave D = 290, a chi-squared p-value
below 0.0001, and the F approximation a p-value of 0.05.

{pstd}
In simulations with four periods, gamma errors, and 199 bootstrap
replications, in which both estimators were consistent, the tests at the
nominal 5 percent level rejected in 4 to 7 percent of samples when the
standard deviation of the log of the panel-level mean was 0.25 or 0.75, and
in 6 to 8.5 percent when it was 1.25, with 250 or 1,000 panels (Roebuck
2026, sec. 4.4).  The bootstrap standard errors of the differences were then
10 to 16 percent too small, because a few panels with high levels dominate
the Poisson fit, and the F approximation does not correct this; p-values
between about 0.01 and 0.05 therefore call for caution when panel levels are
very dispersed.  With four periods the tests also had limited power against
variances proportional to the mean to the power 1.5 or 2.5 (the joint test
rejected in 22 and 59 percent of samples with 250 and 1,000 panels under the
first, and in 11 percent under the second), so the absence of a difference
does not establish that {cmd:xtgamfe} is consistent.  When the mean
specification and strict exogeneity are credible, a material difference is
evidence against share centering, the condition of {cmd:xtgamfe} (see
{help xtgamfe##caveats:When the estimator is valid}).

{pstd}
A term whose coefficient rests on one of the clusters resampled is compared
but not resampled: its difference is shown without standard errors, and the
joint test covers the other differences; replications that do not draw that
cluster are not left out for that reason: the term is left out of both
refits, and such a replication is used unless another compared coefficient
cannot be estimated in it, as with any replication that fails.  The check is made
for those clusters also after {cmd:vce(oim)}, {cmd:vce(bootstrap)}, or
{cmd:vce(jackknife)}, by fitting the model again, quietly, with
{cmd:vce(cluster)} on them.  When every term compared rests on one cluster,
no difference can be resampled: the differences are shown without standard
errors, tests, or intervals (the coefficients' own standard errors follow
the rules of the side-by-side table above, so the {cmd:xtgamfe} one is shown
after {cmd:vce(oim)}), no bootstrap is run, and a note says why (see
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).
When the fit warned for another reason that {cmd:e(V)} has deficient rank,
the note is repeated under the table.

{pstd}
The difference is assessed by a bootstrap; no analytic variance of the
difference from the stacked scores of the two estimators is offered.  The
bootstrap refits both estimators in every replication, so it takes far
longer than the fit: on the example data, after
{cmd:xtgamfe cost x1 x2 i.time} (800 observations, five differences),
{cmd:estat fepoisson, reps(999)} took about a minute on one processor with
StataNow/MP 19.5 on Linux, and a weighted analysis cannot use it.  Weidner and Zylkin (2021, supplementary appendix, p. 30, n. 11) note
that a comparison of the Poisson and gamma pseudo-maximum likelihood
estimators is not straightforward in their three-way gravity setting,
because the gamma estimator is likely to be inconsistent there.  Here too
the gamma estimator can be inconsistent, when share centering fails, which
is why a material difference is read as evidence against share centering,
the mean specification, or strict exogeneity, without saying which.

{phang}
{opt reps(#)} sets the number of bootstrap replications; the default is
{cmd:reps(999)}.  {opt seed(#)} sets the random-number seed before the
replications, as {cmd:bootstrap}'s {opt seed()} does.  {opt nodots}
suppresses the replication dots.

{pstd}
{cmd:estat fepoisson} stores {cmd:r(b_xtgamfe)}, {cmd:r(b_poisson)},
{cmd:r(diff)} (the differences of all the terms compared), {cmd:r(V_diff)}
(the bootstrap covariance matrix of the k differences resampled, which are
all of them unless a coefficient rests on one cluster; not stored when every
term compared rests on one cluster, and then {cmd:r(N_reps)}, {cmd:r(df)},
and {cmd:r(rank)} are 0 and {cmd:r(p)} is missing),
{cmd:r(F)} (the F statistic of the joint test), {cmd:r(df_m)} and
{cmd:r(df_r)} (its degrees of freedom, k and B-k), {cmd:r(p)} (its
p-value), {cmd:r(chi2)} (the Wald statistic D, for reference), {cmd:r(df)}
(the number of differences tested jointly, k), {cmd:r(rank)} (the rank of
{cmd:r(V_diff)}; when it is below {cmd:r(df)}, {cmd:r(F)}, {cmd:r(df_m)},
{cmd:r(df_r)} and {cmd:r(chi2)} are not stored and {cmd:r(p)} is missing),
{cmd:r(df_t)} (the degrees of freedom of the t statistics of the single
differences, after {opt small} or {cmd:vce(jackknife)}), {cmd:r(N)},
{cmd:r(N_clust)}, {cmd:r(reps)}, {cmd:r(N_reps)} (B, the replications
used), {cmd:r(level)}, {cmd:r(clustvar)}, {cmd:r(seed)} if {opt seed()} was
given, {cmd:r(skipped)} (terms that {cmd:xtpoisson} did not estimate),
if any, and {cmd:r(onecl)} (terms compared but not resampled, because their
coefficients rest on one cluster), if any.

{marker park}{...}
{title:estat park}

{p 8 16 2}
{cmd:estat park} [{cmd:,} {opt l:evel(#)}]

{pstd}
runs Park's (1966) test of the variance function on the estimation sample:
the OLS regression of the log squared residual, ln[(y_it - mu_it)^2], on
ln(mu_it) and a constant, with the fitted means of the model, and the test
that the slope of this regression is 2.  (Manning and Mullahy (2001) give a
GLM form of the test, the modified Park test, which {cmd:estat park} does not
run.)  The regression uses the weights of the fit ({cmd:fweight}s as
frequency weights, {cmd:pweight}s and {cmd:iweight}s as sampling weights),
and standard errors clustered as in the fit (on panels after {cmd:vce(oim)},
{cmd:vce(bootstrap)}, or {cmd:vce(jackknife)}), with t statistics on M-1
degrees of freedom as {cmd:regress} reports them: the standard error shown
is that of this auxiliary clustered OLS regression, which treats the fitted
means and the residuals as data, although both are estimated.  The row of
the table and the line below it give the test of slope 2, whose p-value is
therefore nominal: its calibration depends on the design.  A frequency weight of k stands for k panels, as in the fit:
clustered on panels, each copy of a panel is a cluster, so the standard
error, M, and the degrees of freedom are those of the data expanded k times
with each copy given its own panel identifier; with a cluster variable that
nests the panels, the copies of a panel stay in its cluster, as in the fit.

{pstd}
The slope is 2 under these conditions: balanced panels, in the sense of the
same number of observations in every panel of the estimation sample; no
weights, or weights constant within panel; and independent gamma errors with
one shape.  The relative residuals y_it/mu_it are then T_i times the shares
of the mean-scaled outcomes, which are independent of the fitted means.  The
test of slope 2 therefore checks the gamma model; it is not a test of the
condition under which {cmd:xtgamfe} is consistent (see
{help xtgamfe##caveats:When the estimator is valid}).

{pstd}
When the weights of the fit vary within panel, the slope can differ from 2
even under the gamma model: {cmd:estat park} then reports the slope, its
standard error, and its interval, but not the test of slope 2, with a note,
and {cmd:r(t)} and {cmd:r(p)} are missing.  So it does when the panels have
different numbers of observations in the estimation sample: the relative
residuals of a panel are independent of its fitted mean given its length,
but their distribution depends on the length, so the slope can differ from
2, most of all when the length of a panel is related to its level (with
exponential errors, that is, gamma errors of shape 1, half the panels of two
observations at a mean of 1 and half of eight at a mean of e^2, it is 2.18;
with gamma errors of shape 2 it is 2.22), and the slope stays descriptive.

{pstd}
Although its standard error treats estimated quantities as data, under the
gamma model the test of slope 2 rejected in 3.8 to 6.0 percent of
replications at the nominal 5 percent level, in six designs of 500
replications each with 250 or 1,000 panels and two, four, or eight periods
(Roebuck 2026, sec. 6).  Under lognormal errors with a variance proportional
to the squared mean, for which the estimator is consistent, the slopes were
above 2, and the test rejected slope 2 in 93 to 98 percent of simulated
samples (Roebuck 2026, sec. 6).  The fitted means include estimated fixed
effects and the residuals reflect them, so the slope is a descriptive check
of the variance function.  See
{help xtgamfe_technical##tn_park:estat park: special cases} for observations
left out and the cases in which the test is not reported.  Without frequency
weights, the same regression can be run by hand (with the weights of the
fit, if any): {cmd:predict double mu, mu},
{cmd:generate double lr2 = 2*ln(abs(}{it:depvar}{cmd: - mu))},
{cmd:generate double lmu = ln(mu)}, and
{cmd:regress lr2 lmu if e(sample), vce(cluster} {it:clustvar}{cmd:)}.

{pstd}
{cmd:estat park} stores {cmd:r(slope)}, {cmd:r(se)}, {cmd:r(cons)} (the
intercept), {cmd:r(t)} and {cmd:r(p)} (the test of slope 2; missing when the
weights vary within panel or the panels have different numbers of
observations), {cmd:r(df_r)},
{cmd:r(N)}, {cmd:r(N_clust)}, {cmd:r(N_zero)} (observations left out),
{cmd:r(level)}, and {cmd:r(clustvar)}.


{marker caveats}{...}
{title:When the estimator is valid}

{pstd}
Write y_it = exp(alpha_i + x_it'beta_0 + offset_it) eps_it.  The estimator
is consistent, as the number of panels grows with the number of periods
fixed, when the panel score has mean zero at beta_0.  A sufficient condition
that restricts only the errors, given the regressors, is

{phang2}E[ eps_it / sum_s eps_is | X_i, alpha_i ] = 1/T_i for every t,

{pstd}
which is called share centering here.  It holds when the errors of a panel
are exchangeable given the regressors and the fixed effect.  Independent
and identically distributed errors of any positive distribution satisfy
it, so the gamma distribution is not required for the coefficients.
A constant coefficient of variation (variance
proportional to the squared mean) is not enough: the condition concerns how
the errors of a panel relate to each other across periods.  The Park test
(Park 1966; Manning and Mullahy 2001 give its GLM form, the modified Park
test), which chooses a variance function for a cross-sectional model,
therefore does not test it.  The condition can
also fail when the distribution of the errors depends on the regressors: for
example, when the variance is proportional to a power of the mean other than
two, the relative dispersion of the errors changes with the regressors, and
the coefficients can be biased (fixed-effects Poisson is then still
consistent).  A Park slope well away from two ({cmd:estat park}) is a
warning of that kind, though not a test of the condition.

{pstd}
{ul:Serial correlation.}  Share centering generally fails when error
dependence weakens with distance (as with autoregressive errors) or when the
error distribution differs across periods.  (Errors that share a common
component and are otherwise i.i.d. remain exchangeable and satisfy it.)  In
simulations with first-order autoregressive errors in balanced panels of
four or eight periods (Roebuck 2026, sec. 4.3), the coefficient on a
treatment switching on in the last period was biased upward by 5 to 17
percent of its value, and one switching on in the second period and staying
on was biased by about as much in the opposite direction.  The bias with
eight periods was about as large as with four at autocorrelation 0.4 and
nearly twice as large at 0.8; by numerical integration at 0.8, it peaks at
about 13 periods (gamma margin) or 15 (lognormal margin) and declines only
slowly thereafter.

{pstd}
Including period indicators ({cmd:i.}{it:timevar}) removed this bias in
every balanced design tried.  {it:Include period indicators unless there is a reason not to.}
They are added to the model's own mean specification, which must still
include any real period effects.  In balanced panels they restore
consistency of the other coefficients when panel error vectors have a common
distribution independent of the regressors.

{pstd}
In unbalanced panels with errors independent of both the regressors and the
pattern of observation, calendar-period indicators suffice if the period
means of the regressors do not depend on the observation pattern apart from
a constant (a sufficient, not necessary, condition); otherwise include
indicators for period within each observation pattern.  When panels are
observed for consecutive periods and the error process is stationary,
indicators for an observation's position within its panel by panel length
adjust for the errors (real calendar effects on the mean must still be in
the model; in simulations with treatment timed relative to each panel's
window, calendar-period indicators left the bias intact while position
indicators removed it).  In these cases, the period-indicator coefficients
themselves are generally inconsistent for period effects, and so are fitted
means and the default {cmd:estat ape}; use {cmd:estat ape, ybar} for effects
that do not move the period indicators themselves.

{pstd}
{ul:Comparison with fixed-effects Poisson.}  {cmd:xtpoisson} {it:y x}{cmd:, fe vce(robust)}
is consistent whenever the conditional mean is correctly specified and the
regressors are strictly exogenous, with no condition on how the errors of a
panel relate to one another, such as share centering (Wooldridge 1999), and
it allows zeros.  Its score weights each panel by its level, however, so
its consistency needs a law of large numbers for those level-weighted
terms, and its clustered standard errors need their finite second moments:
moment conditions on the level-weighted errors that the gamma estimator,
whose score is bounded given the regressors, does not need.  Weidner and Zylkin (2021)
advise against gamma pseudo-maximum likelihood in gravity models with three
sets of fixed effects and few periods because, they state, it is consistent
only if the conditional variance is proportional to the squared mean.  The gamma estimator weights observations by their share of the
panel's mean-scaled outcome instead of by their level, and can be much more
precise when the level of the outcome differs greatly across panels.  A
sensible use is to fit both to the same observations, as
{cmd:estat fepoisson} does, which also tests the difference with a panel
bootstrap.  A material difference
between them calls for a check of the mean specification, of strict
exogeneity, and of the condition above; when the first two are credible,
Poisson is the estimator that needs the weaker assumptions about how the
errors of a panel relate to one another.

{pstd}
{ul:Strict exogeneity.}  Like other fixed-effects estimators for short
panels, {cmd:xtgamfe} requires that the regressors be uncorrelated with past
and future errors.  Lagged outcomes, and regressors that respond to past
outcomes, violate this; with the dependent variable under a time-series
operator among the regressors (for example {cmd:L.}{it:depvar}), the
command prints a note.

{pstd}
{ul:Positive outcomes.}  Dropping zeros changes what is estimated: the model
describes the mean among positive outcomes.  If whether an outcome is
positive depends on the same shock that determines its size, the estimates
are subject to selection.

{pstd}
{ul:Bias.}  Consistency is not unbiasedness; a finite-sample bias, in
general of order 1/G, remains.  No bias correction is applied.

{pstd}
{ul:Workflow.}  In short (Roebuck 2026, sec. 6): (1) fit {cmd:xtgamfe},
with period indicators when the panel has a common time dimension, and in
unbalanced panels describe the pattern of observation; (2) fit
fixed-effects Poisson regression to the same observations and report both:
{cmd:estat fepoisson} tests the difference (in an unweighted fit), and a
material difference calls
for a check of the mean specification, strict exogeneity, and share
centering; (3) from a model with period indicators, report the average
partial effects of {cmd:estat ape, ybar}; (4) read the slope of
{cmd:estat park} and a difference between the two shape estimates as
warnings, not as tests of share centering; (5) with few clusters, use
{opt small} or {cmd:vce(jackknife)}, and for effects in the units of the
outcome whose sign is not in doubt, consider the interval on the log scale
(see {help xtgamfe_technical##tn_apeci:Intervals for average partial effects}).

{marker benchmark}{...}
{title:Other commands that fit the same model}

{pstd}
The coefficients of {cmd:xtgamfe} can be reproduced as follows.

{phang}
{cmd:glm} {it:y x} {cmd:i.}{it:panelvar}{cmd:, family(gamma) link(log) vce(cluster} {it:panelvar}{cmd:)}
gives the same coefficients and standard errors, when it is fit to the same
observations ({cmd:xtgamfe} drops singleton panels) and with its default
maximum likelihood optimization.  With {cmd:irls}, {cmd:glm} forms the
clustered standard errors from the expected information of the gamma
model instead of the observed curvature of the likelihood that
{cmd:xtgamfe} and the default use.  When share centering holds, the
expected information exceeds the observed curvature on average.  In
balanced panels under the gamma model with one shape and independent
panels, it is (T*kappa+1)/(T*kappa) times the expected curvature, so the
clustered standard errors of {cmd:irls} are too small in large samples (on
the example data with {cmd:i.time}, 0.029 against 0.034 for x1).  Outside
that case the two sandwiches can differ in either direction, and even
within it the observed curvature can be the larger in a particular
sample.  Use the
default for this comparison.  After it, {cmd:predict, mu} gives the same fitted
means, and {cmd:margins, dydx(}{it:x}{cmd:) vce(unconditional)} gives the
average partial effects of {cmd:estat ape} with the same standard errors.
It estimates one parameter per panel, so its run time grows quickly with
the number of panels.  {cmd:xtgamfe} adds the two shape estimates that are
consistent with the number of periods fixed under the gamma model, the effects from the
observed outcome ({cmd:estat ape, ybar}), one-step fitting at a cost per
iteration that is linear in the number of observations, and the
postestimation commands above.

{phang}
{cmd:generate byte one = 1}, {cmd:generate double lny = ln(}{it:y}{cmd:)},
then {cmd:xtpoisson one} {it:x}{cmd:, fe offset(lny) vce(robust)} gives the
coefficients with reversed signs; its covariance matrix times G/(G-1) is that
of {cmd:xtgamfe}.  This uses only official Stata.  With an offset in the gamma model, use
ln(y) - offset.  {cmd:xtpoisson, fe} does not accept {cmd:vce(cluster)},
{cmd:pweight}s, or weights that vary within panel.

{phang}
{cmd:xtspj} {it:y x}{cmd:, model(exponential) method(none)} (Sun and Dhaene
2019) gives the same coefficients when its optimizer reaches the minimum,
with information-based standard errors that assume a shape of one (under
gamma errors with shape kappa they are sqrt(kappa) times the correct ones).
In the simulations of Roebuck (2026, sec. 4.1) with an outcome of order
one, its default settings reported convergence at wrong coefficients in 590
of 600 datasets.
Whether it reaches the minimum depends on the units of the outcome in a way
that no rescaling reliably fixes: on the example data its defaults reach it
with the outcome in its own units and report convergence at wrong
coefficients once the outcome is multiplied by 1,000 or by 0.01.  Compare
its coefficients with {cmd:xtgamfe} or the auxiliary regression.
{cmd:model(gamma)} estimates the shape jointly and often stopped with a
convergence error.  {cmd:xtspj} also offers split-panel
jackknife bias correction, which {cmd:xtgamfe} does not.

{phang}
{cmd:ppmlhdfe one} {it:x}{cmd:, absorb(}{it:panelvar}{cmd:) offset(lny)}
(Correia, Guimaraes, and Zylkin 2020) is the same auxiliary regression and
extends to more than one set of fixed effects.  With
{cmd:vce(cluster} {it:panelvar}{cmd:)} or a cluster variable that nests the
panels, and with {cmd:pweight}s, also ones that vary within panel, it gives
the coefficients with reversed signs and the clustered standard errors of
{cmd:xtgamfe} without a correction factor (to 1e-6 on the example data,
also with sampling weights that vary within panel, at the default
tolerances).  It does not report the gamma shape, the gamma fitted means, or
effects in the units of the outcome; they can be computed from its
results.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtgamfe} stores the following in {cmd:e()}.

{pstd}
{ul:Scalars}

{synoptset 29}{...}
{synopt:{cmd:e(N)}}observations (with {cmd:fweight}s, their sum){p_end}
{synopt:{cmd:e(N_g)}, {cmd:e(N_panels)}}panels{p_end}
{synopt:{cmd:e(N_clust)}}clusters; not stored with {cmd:vce(oim)}; after
{cmd:vce(jackknife)} with {cmd:fweight}s, the panels as held in the data
(see {help xtgamfe_technical##tn_resample:Resampling}){p_end}
{synopt:{cmd:e(N_singletons)}}singleton observations removed (with
{cmd:fweight}s, the observations they stand for, as {cmd:e(N)}){p_end}
{synopt:{cmd:e(g_min)}, {cmd:e(g_avg)}, {cmd:e(g_max)}}minimum, mean, and
maximum observations per panel{p_end}
{synopt:{cmd:e(rank)}, {cmd:e(rank_v)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(rank_h)}}rank of the Hessian, equal to the number of
estimated coefficients{p_end}
{synopt:{cmd:e(hcondition)}}condition number of the Hessian for the
standardized regressors{p_end}
{synopt:{cmd:e(k_omitted)}}number of terms omitted as not identified{p_end}
{synopt:{cmd:e(few_clusters)}}1 with a clustered VCE and fewer than 30
clusters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom, equal to {cmd:e(rank_v)}{p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared for all coefficients; missing when
{cmd:e(rank_v)} is below the number of coefficients, a coefficient rests on
one cluster, or the fit is exact; not stored with
{opt small}{p_end}
{synopt:{cmd:e(F)}}with {opt small}: F = chi2/{cmd:e(df_m)} for all
coefficients, missing when {cmd:e(chi2)} would be{p_end}
{synopt:{cmd:e(df_r)}}with {opt small}: M-1 for M clusters{p_end}
{synopt:{cmd:e(p)}}p-value of the chi-squared or F test{p_end}
{synopt:{cmd:e(converged)}}1 for a converged fit{p_end}
{synopt:{cmd:e(iterations)}}completed Newton iterations, at most
{opt iterate()}{p_end}
{synopt:{cmd:e(gnorm)}}gradient norm for the standardized regressors{p_end}
{synopt:{cmd:e(newton_decrement)}}achieved Newton decrement{p_end}
{synopt:{cmd:e(tolerance)}}requested tolerance{p_end}
{synopt:{cmd:e(kappa)}}moment estimate of the gamma shape{p_end}
{synopt:{cmd:e(phi)}}1/{cmd:e(kappa)}{p_end}
{synopt:{cmd:e(kappa_ml)}}maximum likelihood estimate of the gamma shape;
missing unless {cmd:e(kappa_ml_status)} is {cmd:finite}{p_end}
{synopt:{cmd:e(kappa_ml_se)}}its standard error; after resampling, the
analytic one of the full-sample fit (see
{help xtgamfe_technical##tn_resample:Resampling}){p_end}
{synopt:{cmd:e(ll)}}log likelihood of the within-panel shares at
{cmd:e(kappa_ml)}{p_end}
{synopt:{cmd:e(kappa_pearson)}}(n-G-K)/sum of squared Pearson residuals; a
reference value, not a consistent estimate{p_end}
{synopt:{cmd:e(pearson_ss)}}sum of squared Pearson residuals{p_end}
{synopt:{cmd:e(df_kappa)}}n-G-K{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synoptline}

{pstd}
{ul:Matrices}

{synoptset 29}{...}
{synopt:{cmd:e(b)}}coefficient vector, one column per expanded term, in one
equation named after the outcome (as {cmd:xtpoisson} and {cmd:glm} name
theirs, so that {cmd:estimates table} sets them side by side); base,
empty-cell, and omitted terms have a zero coefficient{p_end}
{synopt:{cmd:e(V)}}covariance matrix, with zero rows and columns for those
terms{p_end}
{synopt:{cmd:e(fe)}}fixed effects, one row per panel of the estimation
sample; posted, with a note, for up to 5,000 panels (and never for more than
{cmd:c(max_matdim)}) unless {opt nofe} is given; {cmd:predict, fe} returns
the same values for any number{p_end}
{synopt:{cmd:e(fe_id)}}panel identifiers, row for row with
{cmd:e(fe)}{p_end}
{synoptline}

{pstd}
With {cmd:vce(bootstrap)} or {cmd:vce(jackknife)} the results of those
prefix commands are stored as well, and they replace {cmd:e(V)} and the model
test (the jackknife stores {cmd:e(F)} and {cmd:e(df_r)} in place of
{cmd:e(chi2)}); the model test is set to missing when a coefficient rests on
one panel (see
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).

{pstd}
{ul:Macros}

{synoptset 29}{...}
{synopt:{cmd:e(cmd)}}{cmd:xtgamfe}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed; with {opt nofe}, without the
{cmd:if} and {cmd:in} qualifier and without a weight expression{p_end}
{synopt:{cmd:e(version)}}command version{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}nonbase terms, including any that were omitted{p_end}
{synopt:{cmd:e(omitted)}}terms omitted as not identified{p_end}
{synopt:{cmd:e(indepvars_full)}}full expanded term list, including bases{p_end}
{synopt:{cmd:e(panvar)}}panel variable{p_end}
{synopt:{cmd:e(timevar)}}time variable, if set{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable; not stored with {cmd:vce(oim)}{p_end}
{synopt:{cmd:e(offset)}}offset variable, if specified{p_end}
{synopt:{cmd:e(wtype)}, {cmd:e(wexp)}}weight type and expression, if
specified{p_end}
{synopt:{cmd:e(vce)}}{cmd:cluster}, {cmd:oim}, {cmd:bootstrap}, or
{cmd:jackknife}{p_end}
{synopt:{cmd:e(vcetype)}}title of the standard-error column: {cmd:Robust};
{cmd:OIM}, {cmd:Bootstrap}, or {cmd:Jackknife} with {cmd:vce(oim)},
{cmd:vce(bootstrap)}, or {cmd:vce(jackknife)}{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald}; not stored with {opt small}{p_end}
{synopt:{cmd:e(small)}}{cmd:small}, if specified{p_end}
{synopt:{cmd:e(onecl)}}the terms whose coefficients rest on one cluster, if
any (see {help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}):
{cmd:e(V)} holds computed values for them that are not meaningful; not
stored with {cmd:vce(oim)}, which makes no such check ({cmd:estat ape} and
{cmd:estat fepoisson} make it themselves){p_end}
{synopt:{cmd:e(converged_by)}}{cmd:newton_decrement} or
{cmd:objective_resolution}{p_end}
{synopt:{cmd:e(shape_status)}}status of {cmd:e(kappa)}: {cmd:finite},
{cmd:infinite_precision}, {cmd:no_positive_root}, {cmd:unbracketed},
{cmd:invalid_moment}, or {cmd:weights_vary_within_panel}{p_end}
{synopt:{cmd:e(kappa_ml_status)}}status of {cmd:e(kappa_ml)}:
{cmd:finite}, {cmd:infinite_precision}, {cmd:unbracketed}, or
{cmd:weights_vary_within_panel}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtgamfe_p}{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtgamfe_estat}{p_end}
{synopt:{cmd:e(title)}}title in estimation output, {cmd:Fixed-effects gamma regression (log link)}{p_end}
{synopt:{cmd:e(datasignature)}, {cmd:e(datasignaturevars)}}signature of the
estimation sample and the variables in it{p_end}
{synopt:{cmd:e(marginsnotok)}}{cmd:_ALL}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synoptline}

{pstd}
{ul:Functions}

{synoptset 29}{...}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}Setup.  The example dataset is an ancillary file of the package:
{cmd:ssc install xtgamfe, all} (or
{cmd:net get xtgamfe, from("http://fmwww.bc.edu/repec/bocode/x")}) copies it
to the current directory, where {cmd:sysuse} finds it.{p_end}
{phang2}{cmd:. sysuse xtgamfe_example, clear}{p_end}
{phang2}{cmd:. xtset id time}{p_end}

{pstd}Basic fit, with period indicators{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time}{p_end}

{pstd}Ratios of means, fitted values, and average partial effects{p_end}
{phang2}{cmd:. xtgamfe, eform}{p_end}
{phang2}{cmd:. predict double muhat, mu}{p_end}
{phang2}{cmd:. estat ape x1 x2}{p_end}

{pstd}Average partial effects from the observed outcome (b times the mean
outcome for x1 and x2), which stay consistent when the period indicators
absorb a period pattern in the errors and the coefficients of x1 and x2 are
consistent{p_end}
{phang2}{cmd:. estat ape x1 x2, ybar}{p_end}

{pstd}Fitted means with x1 raised by one unit: x1 enters linearly, so each
fitted mean is multiplied by exp(b_x1); the mean of mu_plus - muhat over the
estimation sample is the finite change that {cmd:estat ape x1, finite}
reports, with its standard error{p_end}
{phang2}{cmd:. generate double mu_plus = muhat*exp(_b[x1]) if e(sample)}{p_end}
{phang2}{cmd:. estat ape x1, finite}{p_end}

{pstd}The same fitted means from the fixed effects and the changed regressor,
the route for any change (it loses precision with very large origins or
offsets; see {opt alpha()} under {help xtgamfe##predict:predict}){p_end}
{phang2}{cmd:. predict double a, fe}{p_end}
{phang2}{cmd:. clonevar x1_saved = x1}{p_end}
{phang2}{cmd:. replace x1 = x1 + 1}{p_end}
{phang2}{cmd:. predict double mu_plus2, mu alpha(a)}{p_end}
{phang2}{cmd:. replace x1 = x1_saved}{p_end}

{pstd}Intervals for average partial effects on the log scale and by a panel
bootstrap-t with 999 resamples (see
{help xtgamfe_technical##tn_apeci:Intervals for average partial effects}),
in a do-file.  The code uses temporary names throughout so that {cmd:e()},
the data, stored estimates, defined programs, and the working directory are
left unchanged.  It uses fitted-mean effects, for which both intervals were
evaluated in Roebuck (2026, sec. 4.8).{p_end}

{pstd}Adapting the do-file: for a model with period indicators,
whose effects should come from the observed outcome, change both
{cmd:estat ape x1 x2} lines to {cmd:estat ape x1 x2, ybar}; with sampling
weights, add them to both {cmd:xtgamfe} lines.  With clusters {it:g}
(numeric or string) that nest the panels, fit with
{cmd:vce(cluster} {it:g}{cmd:)}, add {cmd:tempvar newg} and
{cmd:egen long `newg' = group(}{it:g}{cmd:)} before the bootstrap, fit
inside the program with {cmd:vce(cluster `1')} and call it as
{cmd:`apeboot' `newg'}, and pass
{cmd:cluster(}{it:g}{cmd:) idcluster(`newg') group(`newid')} to
{cmd:bootstrap} in place of {cmd:cluster(id) idcluster(`newid')}.{p_end}

        {cmd:xtset id time}
        {cmd:xtgamfe cost x1 x2 i.time}
        {cmd:tempname fit ape_b ape_V ape_z ape_e ape_h apeboot}
        {cmd:estimates store `fit'}
        {cmd:estat ape x1 x2}
        {cmd:matrix `ape_b' = r(b)}
        {cmd:matrix `ape_V' = r(V)}
        {cmd:scalar `ape_z' = cond(r(df_r) < ., invttail(r(df_r), 0.025), ///}
        {cmd:    invnormal(0.975))}
        {cmd:forvalues j = 1/2 {c -(}}
        {cmd:    scalar `ape_e' = `ape_b'[1,`j']}
        {cmd:    scalar `ape_h' = sign(`ape_e')*`ape_z'* ///}
        {cmd:        sqrt(`ape_V'[`j',`j'])/abs(`ape_e')}
        {cmd:    display "effect `j': log-scale interval " ///}
        {cmd:        `ape_e'*exp(-`ape_h') "  " `ape_e'*exp(`ape_h')}
        {cmd:{c )-}}
        {cmd:program define `apeboot', rclass}
        {cmd:    xtgamfe cost x1 x2 i.time}
        {cmd:    estat ape x1 x2}
        {cmd:    tempname b V}
        {cmd:    matrix `b' = r(b)}
        {cmd:    matrix `V' = r(V)}
        {cmd:    return scalar b1 = `b'[1,1]}
        {cmd:    return scalar se1 = sqrt(`V'[1,1])}
        {cmd:    return scalar b2 = `b'[1,2]}
        {cmd:    return scalar se2 = sqrt(`V'[2,2])}
        {cmd:end}
        {cmd:tempvar newid}
        {cmd:tempfile draws}
        {cmd:generate long `newid' = id}
        {cmd:xtset `newid' time}
        {cmd:bootstrap b1=r(b1) se1=r(se1) b2=r(b2) se2=r(se2), ///}
        {cmd:    cluster(id) idcluster(`newid') reps(999) seed(20261119) ///}
        {cmd:    saving(`draws', double replace): `apeboot'}
        {cmd:xtset id time}
        {cmd:drop `newid'}
        {cmd:program drop `apeboot'}
        {cmd:estimates restore `fit'}
        {cmd:estimates drop `fit'}
        {cmd:preserve}
        {cmd:use `draws', clear}
        {cmd:forvalues j = 1/2 {c -(}}
        {cmd:    generate double t`j' = (b`j' - `ape_b'[1,`j'])/se`j'}
        {cmd:    _pctile t`j', percentiles(2.5 97.5)}
        {cmd:    display "effect `j': bootstrap-t interval " ///}
        {cmd:        `ape_b'[1,`j'] - r(r2)*sqrt(`ape_V'[`j',`j']) "  " ///}
        {cmd:        `ape_b'[1,`j'] - r(r1)*sqrt(`ape_V'[`j',`j'])}
        {cmd:{c )-}}
        {cmd:restore}

{pstd}Standard errors clustered above the panel; a lagged regressor{p_end}
{phang2}{cmd:. generate long hh = ceil(id/4)}{p_end}
{phang2}{cmd:. xtgamfe cost L.x1 x2 i.time, vce(cluster hh)}{p_end}

{pstd}Comparison with fixed-effects Poisson on the same sample, with a panel
bootstrap test of the differences, and the Park test{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time}{p_end}
{phang2}{cmd:. estat fepoisson, reps(999) seed(20261117)}{p_end}
{phang2}{cmd:. estat park}{p_end}

{pstd}t and F statistics with few clusters{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time if id <= 20, small}{p_end}
{phang2}{cmd:. estat ape x1}{p_end}

{pstd}Starting values from an earlier fit of the same specification{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time}{p_end}
{phang2}{cmd:. matrix b0 = e(b)}{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time, from(b0)}{p_end}

{pstd}The auxiliary Poisson regression that gives the same coefficients with
reversed signs{p_end}
{phang2}{cmd:. generate byte one = 1}{p_end}
{phang2}{cmd:. generate double lny = ln(cost)}{p_end}
{phang2}{cmd:. xtpoisson one x1 x2 i.time, fe offset(lny) vce(robust)}{p_end}

{marker references}{...}
{title:References}

{phang}
Chamberlain, G. 1985. Heterogeneity, omitted variable bias, and duration
dependence. In {it:Longitudinal Analysis of Labor Market Data}, ed.
J. J. Heckman and B. Singer, 3-38. Cambridge: Cambridge University Press.

{phang}
Correia, S., P. Guimaraes, and T. Zylkin. 2020. Fast Poisson estimation with
high-dimensional fixed effects. {it:Stata Journal} 20: 95-115.

{phang}
Dhaene, G., and K. Jochmans. 2019. Profile-score adjustments for
incidental-parameter problems. Cambridge Working Papers in Economics 1959,
University of Cambridge.

{phang}
Manning, W. G., and J. Mullahy. 2001. Estimating log models: To transform or
not to transform? {it:Journal of Health Economics} 20: 461-494.

{phang}
Martin, R. S. 2017. Estimation of average marginal effects in
multiplicative unobserved effects panel models. BLS Working Paper 497,
U.S. Bureau of Labor Statistics.

{phang}
Park, R. E. 1966. Estimation with heteroscedastic error terms.
{it:Econometrica} 34: 888.

{phang}
Roebuck, M. C. 2026. xtgamfe: Fixed-effects gamma regression with a log
link for strictly positive panel outcomes in Stata. RxEconomics working
paper, version of November 2026 (command version 1.1.1).

{phang}
Santos Silva, J. M. C., and G. C. R. Kemp. 2016. Partial effects in
fixed-effects models. Presentation at the 22nd London Stata Users Group
Meeting, 8 September 2016.

{phang}
Sun, Y., and G. Dhaene. 2019. xtspj: A command for split-panel jackknife
estimation. {it:Stata Journal} 19: 335-374.

{phang}
Weidner, M., and T. Zylkin. 2021. Bias and consistency in three-way gravity
models. {it:Journal of International Economics} 132: 103513 (with an online
supplementary appendix).

{phang}
Wooldridge, J. M. 1999. Distribution-free estimation of some nonlinear panel
data models. {it:Journal of Econometrics} 90: 77-97.

{marker author}{...}
{title:Author}

{pstd}
M. Christopher Roebuck{break}
RxEconomics LLC{break}
Miami, FL{break}
mcr@rxeconomics.com{break}
www.rxeconomics.com

{pstd}
Please cite as: Roebuck, M. C. 2026. XTGAMFE: Stata module for
fixed-effects gamma regression with log link. Statistical Software
Components, Boston College Department of Economics.

{pstd}
The estimator, its conditions, and the simulations quoted in this help file
are described in Roebuck (2026); see {help xtgamfe##references:References}.

{pstd}
The command is written for Stata 15 and later; see
{help xtgamfe_technical##tn_platform:Platforms} for the versions and flavors tested.

{title:Also see}

{psee}
{help xtgamfe_technical:xtgamfe technical notes},
{manhelp xtpoisson XT}, {manhelp glm R}, {helpb ppmlhdfe} (if installed),
{helpb xtspj} (if installed)
{p_end}
