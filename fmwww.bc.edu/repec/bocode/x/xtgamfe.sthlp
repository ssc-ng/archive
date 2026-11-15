{smcl}
{* xtgamfe.sthlp  version 1.1.0  2026-11-13}{...}
{vieweralsosee "[XT] xtpoisson" "help xtpoisson"}{...}
{vieweralsosee "[R] glm" "help glm"}{...}
{vieweralsosee "ppmlhdfe (if installed)" "help ppmlhdfe"}{...}
{vieweralsosee "xtspj (if installed)" "help xtspj"}{...}
{viewerjumpto "Syntax" "xtgamfe##syntax"}{...}
{viewerjumpto "Description" "xtgamfe##description"}{...}
{viewerjumpto "Options" "xtgamfe##options"}{...}
{viewerjumpto "Weights" "xtgamfe##weights"}{...}
{viewerjumpto "Postestimation" "xtgamfe##postestimation"}{...}
{viewerjumpto "Stored results" "xtgamfe##results"}{...}
{viewerjumpto "Methods" "xtgamfe##methods"}{...}
{viewerjumpto "When the estimator is valid" "xtgamfe##caveats"}{...}
{viewerjumpto "Other commands" "xtgamfe##benchmark"}{...}
{viewerjumpto "Examples" "xtgamfe##examples"}{...}
{viewerjumpto "References" "xtgamfe##references"}{...}
{hline}
help for {cmd:xtgamfe}{right:version 1.1.0}
{hline}

{title:Title}

{phang}
{cmd:xtgamfe} {hline 2} Fixed-effects gamma regression with log link for
strictly positive panel outcomes

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
{synopt:{opt vce(oim)}}observed information of the gamma model{p_end}
{synopt:{opt vce(boot:strap)}}bootstrap that resamples panels; see
{helpb bootstrap}{p_end}
{synopt:{opt vce(jack:knife)}}jackknife that deletes one panel at a time; see
{helpb jackknife}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:c(level)} at
estimation and stored {cmd:e(level)} at replay{p_end}
{synopt:{opt ef:orm}}report exponentiated coefficients{p_end}
{synopt:{it:display_options}}{opt noci}, {opt nopv:alues},
{opt noomit:ted}, {opt vsquish}, {opt base:levels}, {opt cformat(%fmt)},
and the other options described in {helpb estimation options##display_options:[R] Estimation options}{p_end}

{syntab:Optimization}
{synopt:{opt tol:erance(#)}}strictly positive tolerance for the Newton
decrement; default {cmd:1e-6}{p_end}
{synopt:{opt iter:ate(#)}}maximum Newton iterations, at least 1; default
{cmd:1000}{p_end}
{synopt:{opt nolog}}suppress the iteration log{p_end}
{synopt:{opt from(matname)}}finite 1 x K or K x 1 vector of starting values{p_end}
{synoptline}

{pstd}
The data must be {helpb xtset}.  There is no constant because it is absorbed
by the panel effects.{p_end}
{pstd}
{it:indepvars} may contain factor variables and time-series operators; see
{help fvvarlist} and {help tsvarlist}.  {it:depvar} may not.{p_end}
{pstd}
{cmd:fweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed; see
{help xtgamfe##weights:Weights}.{p_end}
{pstd}
{cmd:by}, {cmd:svy}, and {cmd:margins} are not supported.  {cmd:estat ape}
reports average partial effects; see
{help xtgamfe##postestimation:Postestimation}.

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
are created, and run time grows linearly with the number of observations.

{pstd}
The estimator is not new.  Dhaene and Jochmans (2019) show that, under the
gamma model, the coefficients are estimated consistently as the number of
panels grows with the number of periods fixed, and that only the shape
suffers from the incidental-parameter problem.  The same coefficients are
produced by {cmd:glm}
with family gamma, log link, and an indicator for every panel; by
{cmd:xtspj} with {cmd:model(exponential)} or {cmd:model(gamma)} and
{cmd:method(none)} (Sun and Dhaene 2019); and by a conditional fixed-effects
Poisson regression of a constant on the same regressors with ln(y) as offset,
with the signs reversed.  See
{help xtgamfe##benchmark:Other commands}.  What {cmd:xtgamfe} adds is one
command that reports the coefficients on their natural scale with standard
errors clustered on panels or on a higher level, accepts weights, factor
variables, and time-series operators, estimates the gamma shape, and provides
fitted means, fixed effects, and average partial effects afterwards.

{pstd}
Before using the estimator, read
{help xtgamfe##caveats:When the estimator is valid}.  In particular,
fixed-effects Poisson regression of the outcome itself
({cmd:xtpoisson, fe vce(robust)}) is consistent under weaker conditions, and
period indicators should be included when the errors may be serially
correlated.

{marker requirements}{...}
{title:Sample rules}

{pstd}
{ul:Observations.}  {cmd:if}, {cmd:in}, and weights select observations in
the order in which the data are held when the command is typed, also with
{cmd:vce(bootstrap)} and {cmd:vce(jackknife)} in any of their spellings.
With the {helpb bootstrap} prefix typed directly, Stata reorders the data
before the command sees them, and it drops the observations excluded by
{cmd:if} or {cmd:in} before it resamples: select observations with a
variable, not with {cmd:in} or {cmd:_n}, and note that a model with
time-series operators is refused there when the selection excludes part of a
panel, because the rows that supply lags and leads would be lost in every
replication.  {cmd:vce(bootstrap)} keeps those rows.  Time-series operators
are not allowed in the weight expression.

{pstd}
{ul:Positive outcomes.}  Panels with one usable observation are removed
first, because they carry no information about beta.  Every outcome in the
remaining panels must be strictly positive; a zero or negative value stops
the command.

{pstd}
{ul:Panels and clusters.}  At least two panels, and two clusters, are
required.  The command warns when there are fewer than 30 clusters.  The
warning does not make normal-theory cluster-robust inference reliable; with
few clusters use a method suited to that case.

{pstd}
{ul:Identification.}  Every regressor is centered within panels.  A term with
no within-panel variation, or one that is an exact linear combination of
earlier terms after centering, is omitted with a note: its coefficient and
variance are posted as zero, it is displayed as omitted, and it is listed in
{cmd:e(omitted)}.  Of two collinear terms the later one is omitted.  So with
a time-invariant factor {cmd:g}, {cmd:c.x##i.g} estimates the coefficient on
{cmd:x} and the interactions and omits the main effects of {cmd:g}, as
{cmd:xtpoisson, fe} does.  A regressor is treated as having no within-panel
variation when its largest within-panel deviation is no more than 1e-12 of
its largest absolute value.  Both checks are relative, so they do not depend
on the units of a regressor.  If no term is identified, the command stops.

{pstd}
{ul:Units and origin.}  Estimation is carried out on within-centered
regressors scaled to unit within-panel root mean square, and the results are
mapped back to the original units.  Coefficients are therefore equivariant to
rescaling a regressor and invariant to adding a constant to it, up to the
precision with which the shifted values can be stored.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt offset(varname)} adds {it:varname} to the log mean with its coefficient
constrained to one.  It enters the fixed effects, {cmd:predict, mu}, and
(following official convention) the default {cmd:predict, xb}.

{dlgtab:SE/Robust}

{phang}
{opt vce(robust)}, the default, is the sandwich estimator clustered on the
panel variable, with the factor G/(G-1) for G panels.

{phang}
{opt vce(cluster clustvar)} clusters on {it:clustvar}, which may be numeric
or string.  Every panel must lie within one cluster (households within
sampling units, persons within states); otherwise the command stops with
return code 498.  The factor is M/(M-1) for M clusters.  Clustering on the
panel variable itself is {cmd:vce(robust)}.

{phang}
{opt vce(oim)} is the inverse observed information of the gamma model for the
within-panel shares of the outcome: the inverse Hessian of the criterion
divided by the maximum likelihood estimate of the shape,
{cmd:e(kappa_ml)}.  It is valid only if the errors are independent gamma
variates with a common shape.  It is not allowed with {cmd:pweight}s or
{cmd:iweight}s.

{phang}
{opt vce(bootstrap)} and {opt vce(jackknife)} resample or delete whole
panels.  Suboptions such as {cmd:reps()} and {cmd:seed()} go inside the
parentheses, for example {cmd:vce(bootstrap, reps(500) seed(1))}.  Weights
are not allowed with {cmd:vce(bootstrap)}; {cmd:vce(jackknife)} allows
them.  To resample clusters that nest panels, use the
{helpb bootstrap} prefix with its {cmd:cluster()}, {cmd:idcluster()}, and
{cmd:group()} options (see {help xtgamfe##requirements:Observations} for
its limits with {cmd:if}, {cmd:in}, and time-series operators).  If the
command stops with an error under either option, the estimation results that
were in memory are left in place.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb level}.

{phang}
{opt eform} reports exp(b), the ratio of conditional means for a one-unit
change in the regressor, with standard errors and confidence limits
transformed accordingly.  {cmd:e(b)} and {cmd:e(V)} stay on the coefficient
scale.

{dlgtab:Optimization}

{phang}
{opt tolerance(#)} sets the convergence tolerance.  A fit is declared
converged when the Newton decrement, sqrt(g'H^-1 g), is no larger than the
tolerance.  The decrement does not depend on the units of the regressors;
half its square approximates the remaining reduction in the criterion.  The
gradient norm is reported but is not a stopping rule.  If no step yields a
representable decrease of the criterion and the decrease predicted by the
decrement is below the resolution of the criterion in double precision, the
fit is returned with {cmd:e(converged_by)} set to {cmd:objective_resolution}
and a note; this is what a tolerance below double precision produces.

{phang}
{opt iterate(#)} sets the maximum number of Newton iterations.

{phang}
{opt nolog} suppresses the iteration log.

{phang}
{opt from(matname)} supplies starting values for the nonbase terms of
{it:indepvars}, in order.  By default the command starts from the
within-panel least-squares regression of ln(y)-offset on the regressors.
Because the criterion is convex and has one minimum, starting values do not
change the solution, up to the convergence tolerance, although poor ones can
prevent convergence.  The tolerance is absolute: when the outcome is almost an exact
function of the regressors (a coefficient of variation near 1e-6 or less),
the error it allows can be material next to the very small standard errors,
and a smaller {opt tolerance()} should be used.

{marker weights}{...}
{title:Weights}

{pstd}
With weights w_it the command minimizes the weighted criterion; the fixed
effect of panel i becomes the log of the weighted mean of
y_it exp(-x_it'beta-offset_it).

{phang}
{cmd:fweight}s must be integers and constant within panel.  A weight of k
stands for k identical panels: results equal those from the data expanded k
times with each copy given its own panel identifier.  {cmd:e(N)} and
{cmd:e(N_g)} are the expanded counts.

{phang}
{cmd:pweight}s may vary within panel.  They enter the sandwich through the
weighted panel scores.  {cmd:e(N)} is the number of observations.  The
conditions in {help xtgamfe##caveats:When the estimator is valid} carry over
when the weights are constant within panel.  When they vary within panel,
the shares in the score are weighted and exchangeable errors no longer
center them, even under the gamma model: weights whose within-panel
pattern follows that of the regressors can then bias the coefficients.  In
simulations with gamma errors, weights that rose
from 1 to 4 over four periods biased the coefficient of a treatment that
switched on in the last period by -0.09 (true value 0.5), and weights of 1
and 2 over two periods by -0.17; period indicators removed that bias because the weights
followed the same pattern in every panel and the errors were independent of
the regressors, and they need not when the pattern
differs between panels in a way related to the regressors.  The command
prints a note when the weights vary within panel.  ({cmd:xtpoisson, fe} does
not have this problem and does not allow such weights.)

{phang}
{cmd:iweight}s are treated as {cmd:pweight}s in the estimates and in the
robust and clustered covariance matrices.  (With {cmd:vce(jackknife)} the
two can give different standard errors, because Stata's jackknife treats the
two kinds of weight differently.)

{pstd}
Results do not depend on the scale of {cmd:pweight}s or {cmd:iweight}s.

{pstd}
The shape estimates and the log likelihood are computed only when the weights
are constant within panel; otherwise they are missing and
{cmd:e(shape_status)} is {cmd:weights_vary_within_panel}.

{marker postestimation}{...}
{title:Postestimation}

{pstd}
{cmd:test}, {cmd:testparm}, {cmd:lincom}, {cmd:nlcom}, {cmd:contrast},
{cmd:pwcompare}, {cmd:estimates}, and {cmd:estat summarize} and
{cmd:estat vce} work as after official estimators.  {cmd:e(b)} has one column
for every term of the expanded factor-variable list, including base levels.
In version 1.0.0 it did not, and {cmd:contrast} and {cmd:pwcompare} could
return wrong degrees of freedom; refit with this version before using them.

{title:predict}

{p 8 16 2}
{cmd:predict} [{it:type}] {newvar} {ifin} [{cmd:,} {it:statistic}
{cmd:nooffset} {opt alpha(varname)}]

{synoptset 14 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}x_it'b+offset_it, without the fixed effect; the default{p_end}
{synopt:{opt stdp}}standard error of x_it'b{p_end}
{synopt:{opt fe}}fixed effect a_i{p_end}
{synopt:{opt mu}}fitted mean exp(a_i+x_it'b+offset_it){p_end}
{synopt:{opt r:esiduals}}y_it - mu_it{p_end}
{synopt:{opt sc:ore}}y_it/mu_it - 1{p_end}
{synoptline}

{pstd}
{cmd:xb} and {cmd:stdp} are available for any observation.  {cmd:nooffset},
allowed only with {cmd:xb}, leaves the offset out.

{pstd}
{cmd:fe}, {cmd:mu}, and {cmd:residuals} are returned for every observation
of a panel that was in the estimation sample, including observations that
were not.  The fixed effect is always computed from the estimation sample:

{phang2}a_i = ln[ sum_t w_it y_it exp(-x_it'b-offset_it) / sum_t w_it ].

{pstd}
{cmd:score} is the derivative of minus the criterion with respect to the
linear index, and equals the Pearson residual.  It is returned for the
estimation sample, where it sums to zero within each panel (with weights, its
weighted sum does) and is orthogonal to the regressors.

{pstd}
Because the fixed effects are recomputed from the data, {cmd:fe}, {cmd:mu},
{cmd:residuals}, and {cmd:score} require that the outcome, regressors, panel
and time identifiers, offset, and weights be unchanged since estimation; if
they are not, {cmd:predict} stops with "data have changed since estimation"
(return code 459).  The check covers storage types as well as values, so
{cmd:compress} or {cmd:recast} after estimation also triggers it.  With time-series operators the check also covers the
observations that supply lags and leads, and the data must be {cmd:xtset} as
they were at estimation.  These statistics are not available after
{cmd:estimates use}, which does not restore the estimation sample.

{phang}
{opt alpha(varname)} takes the fixed effects from {it:varname} instead, with
no check on the data.  This gives fitted means at changed covariate values:
save the fixed effects with {cmd:predict, fe}, change the covariates, and
type {cmd:predict} {it:newvar}{cmd:, mu alpha(}{it:varname}{cmd:)}.  It is
allowed with {cmd:mu}, {cmd:residuals}, and {cmd:score}.

{pstd}
With a fixed number of periods an individual fixed effect is a noisy estimate
and does not become precise as the number of panels grows.  exp(a_i) is
unbiased for exp(alpha_i) at the true coefficients when the errors have mean
one; a_i itself is biased downward.

{title:estat ape}

{p 8 16 2}
{cmd:estat ape} [{varlist}] [{cmd:,} {opt l:evel(#)}]

{pstd}
reports average partial effects on the conditional mean, averaged over the
estimation sample with the estimated fixed effects (and the estimation
weights, if any).  For a continuous variable the effect is the average
derivative of mu_it, taken through any polynomial or interaction terms in
which the variable appears.  For a factor variable it is, for each level, the
average change in mu_it from the base level, holding everything else fixed.
With no {it:varlist}, every variable in the model is reported, with four
exceptions that are listed in notes: variables that enter the model with a
time-series operator (the command does not differentiate through lags and
leads); variables that do not vary within panel in the estimation sample;
variables in a term that was omitted because of collinearity; and factor
levels that are part of an empty cell of an interaction, for which the mean
of an observation moved to that level is not estimable.  The effect of a
time-invariant variable on the mean is absorbed by the fixed effects and is
not identified, even when its interaction with another variable is.  When
the model has no base level for a factor (as with {cmd:ibn.}) and
{cmd:xtgamfe} omitted one of its levels, that level is the base.

{pstd}
The standard errors come from the influence functions of the averages.  They
allow for the sampling variation of the coefficients, of the fixed effects,
and of the sample over which the average is taken, and they are clustered on
the cluster variable of the fitted model, {cmd:e(clustvar)}, or on panels
when the fitted model has none (as with {cmd:vce(oim)}).  The average is
consistent as the number of panels grows with the number of periods fixed
when the condition displayed in
{help xtgamfe##caveats:When the estimator is valid} holds and the outcome has
a finite mean (a finite variance for the standard error).  It is in
general not consistent when that condition fails and the coefficients are
consistent only because period indicators are included: the period
coefficients then absorb the differences between periods in the errors, and
the fitted means are off by a factor.  In that case the product of the coefficient and the
sample mean of the outcome estimates the average effect of a regressor that
enters linearly.

{pstd}
{cmd:estat ape} stores {cmd:r(b)}, {cmd:r(V)}, {cmd:r(N)},
{cmd:r(N_clust)}, {cmd:r(level)}, and {cmd:r(clustvar)}.

{title:estat ic}

{p 8 16 2}
{cmd:estat ic} [{cmd:,} {opt n(#)}]

{pstd}
reports Akaike's and the Bayesian information criterion from {cmd:e(ll)},
the log likelihood of the within-panel shares at the coefficients and the
maximum likelihood shape.  The parameter count is the number of estimated
coefficients plus one for the shape.  ({cmd:estimates stats} counts the
coefficients only, so its criteria are lower by 2 and by ln(N).)  The
criteria compare {cmd:xtgamfe}
models fit to the same sample; {cmd:e(ll)} is not comparable with the log
likelihood of a model for the outcome itself.  {cmd:estat ic} stores
{cmd:r(S)}.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtgamfe} stores the following in {cmd:e()}.

{pstd}
{ul:Scalars}

{synoptset 29}{...}
{synopt:{cmd:e(N)}}observations (with {cmd:fweight}s, their sum){p_end}
{synopt:{cmd:e(N_g)}, {cmd:e(N_panels)}}panels{p_end}
{synopt:{cmd:e(N_clust)}}clusters; not stored with {cmd:vce(oim)}{p_end}
{synopt:{cmd:e(N_singletons)}}singleton observations removed{p_end}
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
{cmd:e(rank_v)} is below the number of coefficients{p_end}
{synopt:{cmd:e(p)}}its p-value{p_end}
{synopt:{cmd:e(converged)}}1 for a converged fit{p_end}
{synopt:{cmd:e(iterations)}}completed Newton iterations{p_end}
{synopt:{cmd:e(gnorm)}}gradient norm for the standardized regressors{p_end}
{synopt:{cmd:e(newton_decrement)}}achieved Newton decrement{p_end}
{synopt:{cmd:e(tolerance)}}requested tolerance{p_end}
{synopt:{cmd:e(kappa)}}moment estimate of the gamma shape{p_end}
{synopt:{cmd:e(phi)}}1/{cmd:e(kappa)}{p_end}
{synopt:{cmd:e(kappa_ml)}}maximum likelihood estimate of the gamma shape{p_end}
{synopt:{cmd:e(kappa_ml_se)}}its standard error{p_end}
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
{synopt:{cmd:e(b)}}coefficient vector, one column per expanded term; base,
empty-cell, and omitted terms have a zero coefficient{p_end}
{synopt:{cmd:e(V)}}covariance matrix, with zero rows and columns for those
terms{p_end}
{synopt:{cmd:e(fe)}}fixed effects, one row per panel in the data; posted
for up to 5,000 panels (creating a larger Stata matrix is slow);
{cmd:predict, fe} returns the same values for any number{p_end}
{synopt:{cmd:e(fe_id)}}panel identifiers, row for row with
{cmd:e(fe)}{p_end}
{synoptline}

{pstd}
With {cmd:vce(bootstrap)} or {cmd:vce(jackknife)} the results of those
prefix commands are stored as well, and they replace {cmd:e(V)} and the model
test (the jackknife stores {cmd:e(F)} and {cmd:e(df_r)} in place of
{cmd:e(chi2)}).  {cmd:e(vcetype)} is not stored with {cmd:vce(oim)}.

{pstd}
{ul:Macros}

{synoptset 29}{...}
{synopt:{cmd:e(cmd)}}{cmd:xtgamfe}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
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
{synopt:{cmd:e(vcetype)}}title of the standard-error column{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald}{p_end}
{synopt:{cmd:e(converged_by)}}{cmd:newton_decrement} or
{cmd:objective_resolution}{p_end}
{synopt:{cmd:e(shape_status)}}{cmd:finite}, {cmd:infinite_precision},
{cmd:no_positive_root}, {cmd:unbracketed}, {cmd:invalid_moment}, or
{cmd:weights_vary_within_panel}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtgamfe_p}{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtgamfe_estat}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
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

{marker methods}{...}
{title:Methods and formulas}

{pstd}
{ul:Criterion.}  Write u_it = ln(y_it) - offset_it - x_it'beta and
W_i = sum_t w_it (the number of periods T_i when there are no weights).  For
given beta the fixed effect is alpha_i(beta) = ln[sum_t w_it exp(u_it)/W_i],
and the command minimizes

{phang2}Q(beta) = sum_i W_i alpha_i(beta) + sum_it w_it x_it'beta.

{pstd}
The Hessian of the contribution of panel i is W_i times a weighted
within-panel covariance matrix of the regressors, so Q is convex, and
strictly convex when the within-centered regressors have full column rank.
The score of panel i is

{phang2}g_i(beta) = sum_t w_it x_it (1 - y_it/mu_it).

{pstd}
{ul:Covariance.}  {cmd:vce(robust)} and {cmd:vce(cluster)} report
H^-1 B H^-1 M/(M-1), where H is the Hessian of Q, B is the sum over clusters
of the outer products of the cluster totals of g_i, and M is the number of
clusters.  The rank of the covariance matrix cannot exceed M-1.  When it is
below the number of coefficients the command warns and does not report the
Wald test of all coefficients: a quadratic form in a generalized inverse of
a singular covariance matrix tests only some of the coefficients, and which
ones depends on the units of the regressors.  {cmd:xtreg} with a clustered
VCE does the same.

{pstd}
{ul:Shape.}  Under the gamma model with common shape kappa,
Var(y_it|x,alpha) = mu_it^2/kappa.  Two estimates are reported.

{pstd}
{cmd:e(kappa)} is a moment estimate.  With rho_it = y_it/mu_it - 1,
E[sum_t rho_it^2] = T_i(T_i-1)/(kappa T_i+1) at the true coefficients, and
{cmd:e(kappa)} solves

{phang2}sum_it rho_it^2 = sum_i T_i(T_i-1)/(kappa T_i+1).

{pstd}
{cmd:e(kappa_ml)} maximizes the likelihood of the within-panel shares
s_it = y_it/sum_s y_is, whose distribution does not involve the fixed
effects.  With A_i = sum_t ln[(y_it/mu_it)/T_i], the log likelihood of panel i
is

{phang2}lngamma(T_i kappa) - T_i lngamma(kappa) + kappa A_i
- sum_t ln(s_it).

{pstd}
For any kappa this is maximized over beta by the {cmd:xtgamfe} coefficients,
because its beta-dependent part is -kappa Q(beta) up to a constant.  It is
strictly concave in kappa.  {cmd:e(ll)} is its maximized value and
{cmd:e(kappa_ml_se)} the standard error of {cmd:e(kappa_ml)}, from the
information with {cmd:vce(oim)} and from the sandwich otherwise.  Both shape
estimates are consistent as the number of panels grows with the number of
periods fixed, if the errors are independent gamma variates with a common
shape; the maximum likelihood estimate is the more precise.  When the data
support no finite positive value, the estimate is missing and
{cmd:e(shape_status)} says why.  The coefficients do not depend on either
estimate.

{pstd}
{cmd:e(kappa_pearson)} = (n-G-K)/sum_it rho_it^2 is the usual
degrees-of-freedom-corrected Pearson value.  It is not consistent with the
number of periods fixed (in a balanced panel it converges to kappa + 1/T)
and is reported for reference.

{marker caveats}{...}
{title:When the estimator is valid}

{pstd}
Write y_it = exp(alpha_i + x_it'beta_0 + offset_it) eps_it.  The estimator
is consistent, as the number of panels grows with the number of periods
fixed, when the panel score has mean zero at beta_0.  A sufficient condition
that does not involve the regressors is

{phang2}E[ eps_it / sum_s eps_is | X_i, alpha_i ] = 1/T_i for every t,

{pstd}
which holds when the errors of a panel are exchangeable given the regressors
and the fixed effect.  Independent and identically distributed errors of any
positive distribution satisfy it, so the gamma distribution is not required
for the coefficients.  A constant coefficient of variation (variance
proportional to the squared mean) is not enough: the condition concerns how
the errors of a panel relate to each other across periods.  The modified
Park test of Manning and Mullahy (2001), which chooses a variance function
for a cross-sectional model, therefore does not test it.

{pstd}
{ul:Serial correlation.}  The condition generally fails when the dependence
between the errors of two periods weakens with the distance between them, as
with autoregressive errors, or when the distribution of the errors differs
across periods.  (Errors that share a common component and are otherwise
independent and identically distributed are exchangeable and satisfy it.)  In simulations with first-order
autoregressive errors and four or more periods, the coefficient on a
regressor that trends within panels, such as a treatment that switches on
and stays on, was biased by 4 to 17 percent of its value, and the bias was
about as large (autocorrelation 0.4) or twice as large (0.8) with eight
periods as with four; with an autocorrelation of 0.8 it peaks, among the
panel lengths evaluated, between 12 and 20 periods.  Including period
indicators ({cmd:i.}{it:timevar}) removed it in every balanced design tried.
{it:Include period indicators unless there is a reason not to.}  In
balanced panels they restore consistency of the other coefficients when the
errors are independent of the regressors.  In unbalanced panels
calendar-period indicators do so only if, in addition, the period means of
the regressors do not depend on which periods a panel is observed in;
otherwise include indicators for period within each pattern of observation.
When panels are observed for consecutive periods, indicators for the
observation's position within its panel, by the number of periods observed,
serve (in simulations in which treatment was timed relative to each panel's
own window, calendar-period indicators left the bias in place and these
removed it).  The coefficients on the indicators themselves are in general
not consistent for the period effects in these cases, and neither are fitted
means or {cmd:estat ape}.

{pstd}
{ul:Comparison with fixed-effects Poisson.}  {cmd:xtpoisson} {it:y x}{cmd:, fe vce(robust)}
is consistent whenever the conditional mean is correctly specified and the
regressors are strictly exogenous, with no condition on the errors of the
kind above (Wooldridge 1999), and it allows zeros.  Weidner and Zylkin (2021)
advise against gamma pseudo-maximum likelihood with fixed effects because it
is consistent only under the stronger assumptions.  The gamma estimator weights observations by their share of the
panel's mean-scaled outcome instead of by their level, and can be much more
precise when the level of the outcome differs greatly across panels.  A
sensible use is to fit both to the same observations.  A material difference
between them calls for a check of the mean specification, of strict
exogeneity, and of the condition above; when the first two are credible,
Poisson is the estimator that needs the weaker assumptions.

{pstd}
{ul:Strict exogeneity.}  Like other fixed-effects estimators for short
panels, {cmd:xtgamfe} requires that the regressors be uncorrelated with past
and future errors.  Lagged outcomes, and regressors that respond to past
outcomes, violate this.

{pstd}
{ul:Positive outcomes.}  Dropping zeros changes what is estimated: the model
describes the mean among positive outcomes.  If whether an outcome is
positive depends on the same shock that determines its size, the estimates
are subject to selection.

{pstd}
{ul:Bias.}  Consistency is not unbiasedness; a finite-sample bias, in
general of order 1/G, remains.  No bias correction is applied.

{marker benchmark}{...}
{title:Other commands that fit the same model}

{pstd}
The coefficients of {cmd:xtgamfe} can be reproduced as follows.

{phang}
{cmd:glm} {it:y x} {cmd:i.}{it:panelvar}{cmd:, family(gamma) link(log) vce(cluster} {it:panelvar}{cmd:)}
gives the same coefficients and standard errors.  It estimates one parameter
per panel and is practical only for a modest number of panels.

{phang}
{cmd:generate byte one = 1}, {cmd:generate double lny = ln(}{it:y}{cmd:)},
then {cmd:xtpoisson one} {it:x}{cmd:, fe offset(lny) vce(robust)} gives the
coefficients with reversed signs; its covariance matrix times G/(G-1) is that
of {cmd:xtgamfe}.  This uses only official Stata.  With an offset in the gamma model, use
ln(y) - offset.  {cmd:xtpoisson, fe} does not accept {cmd:vce(cluster)},
{cmd:pweight}s, or weights that vary within panel.

{phang}
{cmd:xtspj} {it:y x}{cmd:, model(exponential) method(none)} (Sun and Dhaene
2019) gives the same coefficients with information-based standard errors
for a shape of one.  {cmd:model(gamma)} estimates the shape jointly; in the
author's tests it did not always converge.  {cmd:xtspj} also offers split-panel
jackknife bias correction, which {cmd:xtgamfe} does not.

{phang}
{cmd:ppmlhdfe one} {it:x}{cmd:, absorb(}{it:panelvar}{cmd:) offset(lny)}
(Correia, Guimaraes, and Zylkin 2020) is the same auxiliary regression and
extends to more than one set of fixed effects.

{marker examples}{...}
{title:Examples}

{pstd}Setup.  The example dataset is an ancillary file of the package:
{cmd:ssc install xtgamfe, all} (or {cmd:net get xtgamfe}) copies it to the
current directory, where {cmd:sysuse} finds it.{p_end}
{phang2}{cmd:. sysuse xtgamfe_example, clear}{p_end}
{phang2}{cmd:. xtset id time}{p_end}

{pstd}Basic fit, with period indicators{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time}{p_end}

{pstd}Ratios of means, fitted values, and average partial effects{p_end}
{phang2}{cmd:. xtgamfe, eform}{p_end}
{phang2}{cmd:. predict double muhat, mu}{p_end}
{phang2}{cmd:. estat ape x1 x2}{p_end}

{pstd}Fitted means with x1 raised by one unit{p_end}
{phang2}{cmd:. predict double a, fe}{p_end}
{phang2}{cmd:. clonevar x1_saved = x1}{p_end}
{phang2}{cmd:. replace x1 = x1 + 1}{p_end}
{phang2}{cmd:. predict double mu_plus, mu alpha(a)}{p_end}
{phang2}{cmd:. replace x1 = x1_saved}{p_end}

{pstd}Standard errors clustered above the panel; a lagged regressor{p_end}
{phang2}{cmd:. generate long hh = ceil(id/4)}{p_end}
{phang2}{cmd:. xtgamfe cost L.x1 x2 i.time, vce(cluster hh)}{p_end}

{pstd}Comparison with fixed-effects Poisson on the same sample{p_end}
{phang2}{cmd:. xtgamfe cost x1 x2 i.time}{p_end}
{phang2}{cmd:. xtpoisson cost x1 x2 i.time if e(sample), fe vce(robust)}{p_end}

{pstd}The auxiliary Poisson regression that gives the same coefficients with
reversed signs{p_end}
{phang2}{cmd:. generate byte one = 1}{p_end}
{phang2}{cmd:. generate double lny = ln(cost)}{p_end}
{phang2}{cmd:. xtpoisson one x1 x2 i.time, fe offset(lny) vce(robust)}{p_end}

{marker references}{...}
{title:References}

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
Sun, Y., and G. Dhaene. 2019. xtspj: A command for split-panel jackknife
estimation. {it:Stata Journal} 19: 335-374.

{phang}
Weidner, M., and T. Zylkin. 2021. Bias and consistency in three-way gravity
models. {it:Journal of International Economics} 132: 103513.

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
Please cite as: Roebuck, M. C. 2026. xtgamfe: Stata module for
fixed-effects gamma regression with log link. Version 1.1.0.

{pstd}
The command is written for Stata 15 and later.  Version 1.1.0 was tested
with StataNow 19.5 on Linux and Windows and with Stata 15.1 on Windows.

{title:Also see}

{psee}
{manhelp xtpoisson XT}, {manhelp glm R}, {helpb ppmlhdfe} (if installed),
{helpb xtspj} (if installed)
{p_end}
