{smcl}
{* *! xtgamfe_technical.sthlp  version 1.1.1  2026-11-23}{...}
{vieweralsosee "xtgamfe" "help xtgamfe"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtpoisson" "help xtpoisson"}{...}
{vieweralsosee "[R] glm" "help glm"}{...}
{viewerjumpto "Technical notes" "xtgamfe_technical##technotes"}{...}
{viewerjumpto "   Sample rules" "xtgamfe_technical##tn_sample"}{...}
{viewerjumpto "   Weight expressions and frozen weights" "xtgamfe_technical##tn_weights"}{...}
{viewerjumpto "   Resampling" "xtgamfe_technical##tn_resample"}{...}
{viewerjumpto "   Omitted terms" "xtgamfe_technical##tn_ident"}{...}
{viewerjumpto "   Units, origins and numeric range" "xtgamfe_technical##tn_units"}{...}
{viewerjumpto "   Convergence" "xtgamfe_technical##tn_conv"}{...}
{viewerjumpto "   Exact fits" "xtgamfe_technical##tn_exact"}{...}
{viewerjumpto "   Coefficients identified by one cluster" "xtgamfe_technical##tn_onecl"}{...}
{viewerjumpto "   Covariate values the sample does not identify" "xtgamfe_technical##tn_support"}{...}
{viewerjumpto "   Data checks" "xtgamfe_technical##tn_data"}{...}
{viewerjumpto "   Sort order and reproducibility" "xtgamfe_technical##tn_order"}{...}
{viewerjumpto "   Saved results and identifiers" "xtgamfe_technical##tn_saved"}{...}
{viewerjumpto "   Intervals for average partial effects" "xtgamfe_technical##tn_apeci"}{...}
{viewerjumpto "   estat fepoisson: the model compared" "xtgamfe_technical##tn_fep"}{...}
{viewerjumpto "   estat park: special cases" "xtgamfe_technical##tn_park"}{...}
{viewerjumpto "   Platforms" "xtgamfe_technical##tn_platform"}{...}
{viewerjumpto "Methods and formulas" "xtgamfe_technical##methods"}{...}
{p2colset 1 28 30 2}{...}
{p2col:{bf:xtgamfe technical notes} {hline 2}}Technical notes and formulas for {help xtgamfe}{p_end}
{p2colreset}{...}


{pstd}
This file is the companion of {help xtgamfe}, which documents the syntax,
options, postestimation commands, the conditions under which the estimator
is valid, stored results, and examples.  The references cited here are
listed in {help xtgamfe##references:References} there.


{marker technotes}{...}
{title:Technical notes}

{pstd}
The notes below give the rules that {cmd:xtgamfe} and its postestimation
commands follow in particular cases: {help xtgamfe_technical##tn_sample:sample rules},
{help xtgamfe_technical##tn_weights:weight expressions and frozen weights},
{help xtgamfe_technical##tn_resample:resampling},
{help xtgamfe_technical##tn_ident:omitted terms},
{help xtgamfe_technical##tn_units:units, origins and numeric range},
{help xtgamfe_technical##tn_conv:convergence},
{help xtgamfe_technical##tn_exact:exact fits},
{help xtgamfe_technical##tn_onecl:coefficients identified by one cluster},
{help xtgamfe_technical##tn_support:covariate values the sample does not identify},
{help xtgamfe_technical##tn_data:data checks},
{help xtgamfe_technical##tn_order:sort order and reproducibility},
{help xtgamfe_technical##tn_saved:saved results and identifiers},
{help xtgamfe_technical##tn_apeci:intervals for average partial effects},
{help xtgamfe_technical##tn_fep:estat fepoisson: the model compared},
{help xtgamfe_technical##tn_park:estat park: special cases}, and
{help xtgamfe_technical##tn_platform:platforms}.

{marker tn_sample}{...}
{pstd}
{ul:Sample rules.}  {cmd:if}, {cmd:in}, and weights select observations in
the order in which the data are held when the command is typed, also with
{cmd:vce(bootstrap)} and {cmd:vce(jackknife)} in any of their spellings.
With the {helpb bootstrap} prefix typed directly, Stata reorders the data
before the command sees them, and it drops the observations excluded by
{cmd:if} or {cmd:in} before it resamples: select observations with a
variable, not with {cmd:in} or {cmd:_n}, and note that a model with
time-series operators is refused there when the selection excludes part of a
panel, because the rows that supply lags and leads would be lost in every
replication.  {cmd:vce(bootstrap)} keeps those rows.  Panels with one usable
observation are removed first, because they carry no information about
beta.  Every outcome in the remaining panels must be strictly positive; a
zero or negative value stops the command.  At least two panels, and two
clusters, are required.  The command warns when there are fewer than 30
clusters.  The warning does not make normal-theory cluster-robust inference
reliable; with few clusters use a method suited to that case, such as
{opt small}, which gives t and F statistics with M-1 degrees of freedom, or
{cmd:vce(jackknife)}.

{marker tn_weights}{...}
{pstd}
{ul:Weight expressions and frozen weights.}  The weights are evaluated in
the current data order, and the fit freezes that single realized set of
weights.  Those values select and weight the observations, and
{cmd:vce(jackknife)} reuses them across replications rather than
re-evaluating the expression ({cmd:vce(bootstrap)} and the {helpb bootstrap}
prefix do not allow weights; a user-typed {helpb jackknife} prefix likewise
evaluates a weight expression once before its replications).

{pmore}
To detect order-dependent expressions (such as those using {cmd:_n},
subscripts, running sums, or random numbers), the command evaluates the
expression in the current order, in reverse order, with odd-numbered rows
first, and with the first row moved to the end.  If the values differ, it
stops with return code 198; generate the weight variable first.  Because no
finite set of permutations proves order-independence, a row-by-row hash of
the realized weights together with the other estimation inputs (outcome,
regressors, panel and time variables, offset, and cluster variable; rows
that tie on the panel and time variables, as with missing time values or no
time variable, in the order of all their values) is stored.  {cmd:predict}, {cmd:estat ape},
and {cmd:estat park} re-evaluate {cmd:e(wexp)} and stop with return code 459
if the values differ or move to other rows, while accepting a re-sort of the
data.  A named weight variable is checked the same way.

{pmore}
Time-series operators ({cmd:L.}, {cmd:F2.}, {cmd:D.}, {cmd:LD.},
{cmd:L(1/2).}, ...) are disallowed in weight expressions and recognized by
the operator-dot syntax; functions such as {cmd:F()} (the F distribution
function) and {cmd:Fden()} are allowed, whereas operators such as {cmd:F.}
are not.

{marker tn_resample}{...}
{pstd}
{ul:Resampling.}  Under {cmd:vce(bootstrap)}, {cmd:vce(jackknife)}, or a
{cmd:bootstrap} or {cmd:jackknife} prefix, only the coefficients are
resampled.  The standard error of the maximum likelihood shape,
{cmd:e(kappa_ml_se)}, is then the analytic one of the full-sample fit,
clustered on panels: the header says so in a note, and it does not show it
when the replications resampled clusters other than the panels, as
{cmd:jackknife, cluster(}{it:clustvar}{cmd:)} does (the prefix drops the
{cmd:vce()} option of {cmd:xtgamfe}).  For a standard error of the shape
clustered on {it:clustvar}, fit with {cmd:vce(cluster} {it:clustvar}{cmd:)};
to resample it as well, add it to the statistics of the prefix, for example
{cmd:jackknife _b kappa=e(kappa_ml), cluster(}{it:clustvar}{cmd:):}
{cmd:xtgamfe} ...  The results are then those of {cmd:jackknife} ({cmd:e(cmd)}
is {cmd:jackknife}), after which {cmd:predict} and the {cmd:estat} commands
are not available; refit with {cmd:xtgamfe} for them.  If the command stops with an error under
{cmd:vce(bootstrap)} or {cmd:vce(jackknife)}, the estimation results that
were in memory are left in place.

{pmore}
With weights, the replications and the full-sample fit receive a temporary
double copy of the weights.  The fit signs that copy row by row with the
other estimation inputs (and Stata's data signature, which would record the
copy's storage type, leaves the weights out), so {cmd:predict},
{cmd:estat ape}, and {cmd:estat park} accept the unchanged data whatever the
storage type of the weight variable, and refuse them when a weight has
changed.  After {cmd:vce(jackknife)} with {cmd:fweight}s, {cmd:e(N_clust)}
counts the panels as held in the data, one replicate per panel as held,
counted with its weight (18 in a dataset of 18 panels whose weights stand
for 45), while
{cmd:e(N_g)} and the degrees of freedom {cmd:e(df_r)} = {cmd:e(N_g)} - 1
count the panels that the weights stand for, as the expanded data would.

{pmore}
{cmd:estat ape}, {cmd:estat park}, and {cmd:estat fepoisson} cluster on
{cmd:e(clustvar)}, which must nest the panels: {cmd:xtgamfe}'s own
{cmd:vce(cluster)} requires it, but a {cmd:bootstrap} or {cmd:jackknife}
prefix with {cmd:cluster()} accepts clusters that cross the panels, such as
periods ({cmd:jackknife, cluster(time):}), whose replications treat the
observations of one panel in different clusters as independent.  After such
a prefix the display warns, and the three commands stop with return code 498
and a message about the clusters before computing anything; they stop with
return code 111 when the cluster variable is no longer in the data.

{marker tn_ident}{...}
{pstd}
{ul:Omitted terms.}  Every regressor is centered within panels.  A term with
no within-panel variation, or one that is a linear combination of earlier
terms after centering, to Stata's collinearity tolerance (as {cmd:glm}
omits it; checked separately), is omitted with a note: its coefficient and
variance are posted as zero, it is displayed as omitted, and it is listed in
{cmd:e(omitted)}.  Of two collinear terms the later one is omitted.  So with
a time-invariant factor {cmd:g}, {cmd:c.x##i.g} estimates the coefficient on
{cmd:x} and the interactions and omits the main effects of {cmd:g}, as
{cmd:xtpoisson, fe} does.  A regressor has no within-panel variation when its
stored values are equal within every panel; the check is exact, so it does
not depend on the origin or the units of the regressor, and the collinearity
check uses the centered and rescaled regressors.  When a regressor varies
within panels by no more than 1e-10 of its largest absolute value, it is
kept, and a note says to how many significant digits its stored values
resolve that variation.  If no term is identified, the command stops.  The
levels of one factor variable omitted for the same reason are noted in one
note.

{marker tn_units}{...}
{pstd}
{ul:Units, origins and numeric range.}  Estimation is carried out on
within-centered regressors scaled to unit within-panel root mean square, and
results are mapped back to the original units.  Coefficients are therefore
equivariant to rescaling a design column and invariant to adding a constant
to it, up to storage precision.  (Shifting a variable that enters through a
polynomial or interaction changes the other columns as well, so those
coefficients change.)

{pmore}
Fitted means, residuals, scores, and {cmd:estat ape} are computed from the
panel-centered index whenever sum_j |x_itj b_j| + |offset_it| exceeds 1024
for any observation, keeping them invariant to regressor origins even when
large terms cancel (such as two regressors with large origins and opposite
slopes).  {cmd:estat ape} also centers the design within panels whenever any
term's largest absolute value exceeds 1024 times its largest deviation from
the first value of a panel, regardless of its coefficient, so an exact
origin shift leaves effects and standard errors unchanged even at a zero
slope.  Only {cmd:predict}'s {cmd:fe}, {cmd:xb}, and {cmd:stdp}, defined on
the uncentered scale, change with the origin.

{pmore}
Fitted means and effects are proportional to the units of the outcome, and
{cmd:e(ll)} does not depend on those units even when panel outcome sums
exceed Stata's numeric range.  The offset enters only through within-panel
differences: its minimum in each panel is subtracted before combining it
with ln(y) and added back to the fixed effects.  Thus coefficients, their
covariance, both shape estimates, {cmd:e(ll)}, recomputed fitted means, and
{cmd:estat ape} are invariant to adding a common or panel-specific constant
to the offset, up to storage precision, while {cmd:e(fe)} and
{cmd:predict, fe} shift by the opposite of that constant.  (With
{cmd:alpha()}, the fixed effects given are used on the uncentered scale, and
precision is lost with very large offsets or origins.)

{pmore}
Results do not depend on the scale of {cmd:pweight}s or {cmd:iweight}s:
the fit and {cmd:estat ape} scale them to mean one (first by an exact power
of two, so that their total does not overflow), {cmd:predict} and
{cmd:estat park} bring weights of extreme scale to order one by an exact
power of two, and all give the same results, to rounding, at any
representable scale, also when the total of the weights as given exceeds
Stata's numeric range ({cmd:fweight}s keep their counts).

{pmore}
{cmd:predict}'s {cmd:mu}, {cmd:residuals}, and {cmd:score} stop with return
code 459 when a value that they return is outside Stata's numeric range (for
{cmd:score}, also when the outcome divided by a representable fitted mean
overflows, as it can with a fixed effect given with {cmd:alpha()}), or
outside the range of the storage type requested ("use predict double"); an
observation whose prediction is missing because its covariate values are not
identified does not count.

{pmore}
When the fitted means that the effects use, the effects, or their variances
are outside Stata's numeric range, {cmd:estat ape} stops with return code
459: when they overflow, and when they underflow, that is, when an effect is
nonzero but its variance is zero or too small to be stored with full
precision (below about 2.2e-308), or the effect itself is.  The coefficients
do not depend on the units of the outcome, so rescale it (multiply or divide
it by a power of 10) and refit.  Within those bounds the variances of the
effects are computed without underflow or overflow in their intermediate
sums.

{pmore}
A variance that is zero because every cluster contributes the same to the
influence function of the effect is not an underflow: when the largest
absolute contribution of a cluster is at most 1e-10 times the largest
cluster sum of the absolute values from which the contributions are formed
(rounding leaves far less, and contributions that genuinely differ differ by
far more), the effect is reported without standard error, test, and
interval, with a note, and {cmd:r(zerovar)} names it.  Finite changes
({opt finite}, {opt delta()}) and the contrasts of factor levels also stop
with return code 459 when the multiplier exp(b*h) (or the exponential of the
contrast) overflows, even when the effect itself would be representable, as
with {cmd:delta(1500)} for a coefficient of 0.5: use a smaller change
(rescaling does not help, because the multiplier does not depend on the
units).

{marker tn_conv}{...}
{pstd}
{ul:Convergence.}  If no step yields a representable decrease of the
criterion and the decrease predicted by the Newton decrement is below the
resolution of the criterion in double precision, the fit is returned with
{cmd:e(converged_by)} set to {cmd:objective_resolution} and a note; this is
what a tolerance below double precision produces.  For a near-exact fit
only, further Newton steps can follow convergence (see
{help xtgamfe_technical##tn_exact:Exact fits}); they count against {opt iterate()}.  A
fit that has not converged within {opt iterate()} iterations, whose line
search fails, or whose Hessian loses rank during the iterations stops with
return code 430 and posts nothing: {cmd:e()} keeps the estimation results
that were in memory before the command (those of an earlier fit, of
{cmd:xtgamfe} or of another command, if any), so after a return code of 430
{cmd:e(converged)} and the other results describe that earlier fit, not the
failed one.  The same holds when the command stops with any other error.
Because the criterion is convex and has one minimum, starting values do not
change the solution, up to the convergence tolerance, although poor ones can
prevent convergence; when the outcome varies within panels by many orders
of magnitude that the regressors do not explain, the default starting values
can be too far from the solution, and a message suggests {opt from()}.  The
tolerance is absolute: when the outcome is almost an exact function of the
regressors (a coefficient of variation near 1e-6 or less), the error it
allows can be material next to the very small standard errors, and a smaller
{opt tolerance()} should be used.

{marker tn_exact}{...}
{pstd}
{ul:Exact fits.}  When fitted within-panel shares are exactly equal, the
share likelihood grows without bound in kappa and its maximum lies at
infinite precision.  A dispersion that is not zero but is too small to be
told apart from rounding or from what the convergence tolerance leaves has a
finite maximizer in exact arithmetic that the command does not resolve: it
classifies the fit as numerically exact.  In an exact fit in this sense (the
regressors and fixed effects reproduce the outcome up to rounding or the
convergence tolerance), both shape estimates are missing with
status {cmd:infinite_precision}, and {cmd:e(kappa_ml_se)}, {cmd:e(ll)},
{cmd:estat ic}, {cmd:estat park}, and {cmd:vce(oim)} are unavailable (with a
note).  Because the scores and standard errors are then rounding error, the
Wald test is withheld ({cmd:e(chi2)} is missing) and the coefficient table
leaves standard errors, z statistics, p-values, and intervals blank, with a
note ({cmd:e(V)} still holds the computed values).

{pmore}
{cmd:estat ape} still reports standard errors after an exact fit, with a
note: because scores are zero to rounding, the influence function reduces to
each panel's deviation from the overall average, so the standard errors
reflect only the sampling of the averaged panels (if every cluster's average
is identical, the variance is zero and the effect is shown without a
standard error; see
{help xtgamfe_technical##tn_units:Units, origins and numeric range}).  The
exact-fit test runs with any weights; when weights vary within panel, the
shape estimates are missing for that reason and the Wald test is withheld
the same way.

{pmore}
For a near-exact fit (mean squared within-panel deviation of log residuals
at most 1e-4) whose dispersion is not well above what the tolerance leaves,
the command takes extra Newton steps within {opt iterate()} before deciding;
ordinary fits are not judged against the tolerance.  A small but real
dispersion yields a large finite shape: above 1e4, the likelihood, score,
and information are evaluated via their asymptotic series in 1/kappa to
avoid cancellation.

{marker tn_onecl}{...}
{pstd}
{ul:Coefficients identified by one cluster.}  A coefficient rests on one
cluster when the other clusters do not identify it.  The simplest case is a
term that varies within panels in only one cluster (for example a regressor
that is nonzero in a single panel, with the panels as clusters, or in two
panels of one household, with households as clusters).  The same holds after
a change of coordinates: with r such a term, the regressors x1 and
mix = x1 + r are collinear within panels outside that cluster, and so are
a = x1 + r and b = x1 - r, so that each of their coefficients rests on the
one cluster, although each term varies in every cluster.  The clusters
cannot estimate the sampling variation of such a coefficient: moving the
coefficients along a direction that the other clusters do not identify
changes no fitted mean outside the cluster, so the score along it is zero in
every other cluster; the scores sum to zero at the optimum, so it is zero in
that cluster too, up to rounding and the convergence tolerance.

{pstd}
The command counts, for each term, the clusters with a panel in which the
term varies (copies of a frequency-weighted panel count once, whereas the
data expanded with each copy a panel count each copy as a cluster), and it
finds the directions of the coefficients that lose identification when one
cluster is left out: those in which the within-panel cross products of the
other clusters' observations are collinear, by the collinearity rule of the
fit (the cross products, scaled to a unit diagonal, are swept in term order,
and a pivot that is zero to the tolerance of {cmd:invsym()} marks a term
collinear with the earlier ones).  A coefficient rests on one cluster when
its unit vector has a part along such a direction (above 1e-6 on the scale of
the other clusters' design columns), and {cmd:e(onecl)} names these terms.
A combination of coefficients that has no part along those directions does
not rest on the cluster: with a and b above, a + b does not, and
{cmd:lincom a + b} is meaningful.

{pstd}
A cluster can lose a direction only if
its leverage, the sum over its observations of x_it'S^-1 x_it (with x_it
the within-panel deviations and S their cross products), is at least 1.
The leverages of all clusters sum to the number of estimated coefficients,
and the command examines every cluster whose leverage is at least 1/2, of
which there are at most twice that number, so the check adds little to the
run time.  With the panels as clusters such
coefficients also give {cmd:e(V)} deficient rank, and the command warns
that joint tests are not available; with clusters that nest the panels the
computed rank can stay full.  Whatever the rank, for a coefficient that
rests on one cluster:

{phang2}
o  The coefficient table shows the coefficient with the standard error,
test statistic, p-value, and interval left blank, and a note under the table
names the term; a second note says that tables made from {cmd:e(V)}, as by
{cmd:estimates table}, {cmd:etable}, or {cmd:esttab}, will show a standard
error for it.  The Wald test of all coefficients is not reported:
{cmd:e(chi2)} (or {cmd:e(F)} with {opt small}) and {cmd:e(p)} are missing,
and the header says why.  {cmd:e(V)} keeps the computed values, which are
not meaningful for that coefficient.  {cmd:test}, {cmd:testparm}, and
{cmd:lincom} use {cmd:e(V)}, so a test or linear combination that involves
the coefficient is not meaningful either, unless it has no part along the
directions that rest on the cluster (as a + b above); one that involves only
the other coefficients is not affected (in that cluster their scores are
those of the variation that the terms concerned do not explain, as in a
regression with those terms partialled out).

{phang2}
o  {cmd:estat ape} shows without standard errors, test statistics,
p-values, and intervals the effects of the variables that enter a term that
varies within panels in only one cluster, and the effects whose derivative,
through the change that they describe (not through the fitted means), has a
part along a direction that rests on one cluster ({cmd:r(V)} keeps the
computed values; {cmd:r(onecl)} lists those effects).  Any other effect
depends on those coefficients only through the fitted means of the panels of
that cluster (for a term that varies in one cluster, of the panels in which
it varies), and with {opt ybar} not at all: its standard error leaves out
the part of its sampling variation that comes from them, which involves only
those panels and is small when they hold a small share of the sample.  A
note under the table says which case applies.

{phang2}
o  {cmd:estat fepoisson} shows the term's difference without a bootstrap
standard error, test, and interval, and the term without its {cmd:xtgamfe}
standard error unless the fit used {cmd:vce(oim)}, whose standard errors do
not use the clusters.  The difference is not resampled, and the joint test covers
the other k differences ({cmd:r(df)} = {cmd:r(df_m)} = k,
{cmd:r(df_r)} = B-k, {cmd:r(V_diff)} is k by k, and {cmd:r(onecl)} names the
terms); a note says so.  When the clusters of the fit are the panels (unless
the fit used {cmd:vce(cluster)} with a variable other than the panel
variable), the {cmd:xtpoisson} standard error of the term is not shown
either: its sandwich clusters on the same panels and cannot measure that
term's sampling variation.  With such a variable it is shown as
{cmd:xtpoisson} reports it, also when that variable only relabels the
panels; for a term that varies within panels in only one panel, it does not
measure that variation either.  A resample of M clusters omits a given cluster with
probability (1 - 1/M)^M, about e^-1 = 0.37.  In such a replication the term
(or one term of the direction) drops out of both refits, and the
replication is kept when every other tested difference is still estimated
in it: the bootstrap of the other differences is not conditional on drawing
that cluster.  Replications that fail, such as a tested
coefficient that either refit does not estimate, are left out, and a note
gives their number.  When every term compared rests on one cluster, nothing
is resampled: the differences are shown without standard errors, tests, or
intervals (the coefficients' own standard errors follow the rules above, so
the {cmd:xtgamfe} one is shown after {cmd:vce(oim)}), no bootstrap is run, a note says why, and
{cmd:r(N_reps)}, {cmd:r(df)}, and {cmd:r(rank)} are 0, {cmd:r(p)} is
missing, and {cmd:r(V_diff)} is not stored.

{phang2}
o  {cmd:predict, stdp} is missing, with a note, for the observations in
which the linear prediction depends on such a coefficient: where a term that
varies within panels in only one cluster is not zero, and where x_it'v is not
zero (above 1e-6 of the sum of |x_itj v_j|) for a direction v that rests on
one cluster; elsewhere it does not involve them.

{pstd}
Under {cmd:vce(bootstrap)}, {cmd:vce(jackknife)}, or a {cmd:bootstrap} or
{cmd:jackknife} prefix, the count and the directions are those of the
clusters of the full-sample fit (the panels, under {cmd:vce(bootstrap)} and
{cmd:vce(jackknife)}), and a flagged coefficient is treated in the same way:
its resampled standard error is not meaningful either.  After
{cmd:vce(bootstrap)} or {cmd:vce(jackknife)} the resampled test of all
coefficients is not kept; after a prefix typed by the user it is left in
{cmd:e()} but not shown.  A coefficient that rests on several panels that
lie in one of the prefix's own clusters is not flagged in the coefficient
table or by {cmd:predict, stdp} (the full-sample fit cannot see the
prefix's clusters); fit with {cmd:vce(cluster} {it:clustvar}{cmd:)} to have
the check made with those clusters there.

{pstd}
{cmd:estat ape} and {cmd:estat fepoisson} make the check for the clusters
that they use ({cmd:e(clustvar)} when it nests the panels, otherwise the
panels) whatever the variance of the fit.  {cmd:estat ape} after
{cmd:vce(oim)}, {cmd:vce(bootstrap)}, {cmd:vce(jackknife)}, or a
{cmd:bootstrap} or {cmd:jackknife} prefix, and {cmd:estat fepoisson} after
{cmd:vce(oim)}, {cmd:vce(bootstrap)}, or {cmd:vce(jackknife)} (it does not
accept results fitted under a prefix), fit the model again, quietly, with
{cmd:vce(cluster)} on those clusters, to the terms of the fit on the
estimation sample (with its weights and offset), starting from the
coefficients of the results, and take the terms and directions from that
fit.  ({cmd:vce(oim)} computes no clustered variance and makes no such check,
so {cmd:e(onecl)} is then empty, whereas both commands cluster on the
panels.)  The check depends on the design, the weights, and the clusters,
not on the coefficients, and the results in memory, the data, and their sort
order are left as they were.  Started from the coefficients of the results,
the refit converges at once, whatever the starting values, tolerance, and
iterations of the fit, and it must reproduce them (their names, the number
of observations, and their values to a relative 1e-12, that is, to
rounding); otherwise, as when {cmd:e(b)} was changed after the fit, or if
the refit fails, the command stops with return code 498.  {cmd:estat park}
and {cmd:estat ic} do not use {cmd:e(V)} and are not affected.  The rank of
{cmd:e(V)} can also fall short because there are too few clusters (fewer
than the coefficients plus one); the warning then says so, and, when some
coefficients also rest on one cluster, it says that too.

{marker tn_support}{...}
{pstd}
{ul:Covariate values the sample does not identify.}  {cmd:predict}'s
{cmd:xb}, {cmd:stdp}, {cmd:mu}, {cmd:residuals}, and {cmd:score} are
missing, with a note, for an observation whose covariate values the model
does not identify.  The checks are of two kinds.

{phang2}
o  Global checks, for all five statistics: a value of a factor variable
that has no term in the model (a period outside the estimation sample after
{cmd:i.}{it:timevar}, for example), unless the estimation sample itself
contains values of that factor without a term of their own (as after
{cmd:2.}{it:timevar} or {cmd:i(2 4)bn.}{it:timevar}, whose other periods all
have every indicator equal to zero, a coding that the sample contains and
that any other value shares); a cell of an interaction that the sample
does not contain; and values that break a relation by which a term was
omitted and whose constant is the same in every panel (a duplicate
regressor that no longer equals its copy).

{phang2}
o  Panel checks, for {cmd:mu}, {cmd:residuals}, and {cmd:score}: a term
omitted by a relation whose constant differs between panels (a term without
within-panel variation, or one collinear with the fixed effects and the
other terms) must keep its panel's relation as on the estimation sample.
Without {cmd:alpha()} the data are verified unchanged, and the comparison
is with the estimation sample.  An observation of a panel that has no
observations in the estimation sample has no such relation to keep: with
{cmd:alpha()} the statistic is missing there, with a note, because the
fitted mean would depend on which term of the relation the fit omitted
(without {cmd:alpha()} such a panel has no fixed effect).  In a model
without such a relation, {cmd:alpha()} gives predictions in new panels.
With {cmd:alpha()} the values that define
those relations on the estimation sample are first compared with a hash
stored at estimation; if they have changed (for example, a regressor in the
relation was changed everywhere, which moves it away from the omitted term
it is tied to), the statistic is missing for every observation, with a
note, because the fitted means at the new values are not identified.  These
checks need {cmd:e(sample)}: after {cmd:estimates use}, {cmd:alpha()} stops
with return code 459 when the model has such a relation.

{pmore}
{cmd:fe} is not affected by these checks.  With time-series operators,
every statistic requires the data to be {cmd:xtset} with the panel variable,
time variable, and delta of the estimation.

{pmore}
{cmd:estat ape} checks identification for each effect and each factor level:
the change that the effect describes, made for every observation of the
estimation sample, must leave the fitted index determined.  It must not move
an observation into a cell of an interaction that the sample does not
contain, or change a term that {cmd:xtgamfe} omitted, or a term collinear
with one, without the terms it is tied to.  So neither copy of a regressor
duplicated under another name (x1 and a copy x1c of it) is reported, and
both are listed as not identified; the same term entered twice under its
own name (as in {cmd:x1 x2 x1}, or {cmd:x1} next to the {cmd:x1} of
{cmd:i.k##c.x1}) is one variable, whose second term {cmd:xtgamfe} omits,
and its effect is reported (the commands find the omitted terms by their
position in {cmd:e(b)}, not by name).  With an empty cell a contrast is
reported when it avoids that cell, whatever the bases of the other
factors.  A factor level
is reported only if its effect is identified for every observation; a
variable requested by name whose effect is not identified is an error.  When
the model has no base level for a factor, the base is chosen in this order.
First, when {cmd:xtgamfe} omitted exactly one level of its main effect (as
can happen with {cmd:ibn.}), that level is the base.  Otherwise, when the
estimation sample contains values of the factor that no term names (as
after {cmd:2.time}, or {cmd:i(2 4)bn.time}), those values share the coding
in which every indicator of the factor is zero, and that coding is the
base; a note shows the lowest such value.  Otherwise the numerically lowest
named level is the base, with a note.

{marker tn_data}{...}
{pstd}
{ul:Data checks.}  Because the fixed effects are recomputed from the data,
{cmd:predict}'s {cmd:fe}, {cmd:mu}, {cmd:residuals}, and {cmd:score}, and
{cmd:estat ape}, {cmd:estat park}, and {cmd:estat fepoisson} require that
the outcome, regressors, panel and time identifiers, offset, weights, and
cluster variable be unchanged since estimation; if they are not, they stop
with "data have changed since estimation" (return code 459).  For the
variables of the model (outcome, regressors, panel and time identifiers,
offset, and cluster variable) and a weight variable named directly, the
check covers storage types as well as values (Stata's data signature), so
{cmd:compress} or {cmd:recast} after estimation also triggers it, except for
weights that a resampling prefix passed to the fit as a temporary copy,
which the hash below covers whatever their storage type (see
{help xtgamfe_technical##tn_resample:Resampling}).  A weight expression is
signed through a float copy of its values (as {cmd:signestimationsample}
signs one), so recasting a variable used only inside the expression is
accepted when its values do not change (the hash below covers the
expression's values).

{pmore}
The check also covers the assignment of the values to observations: a hash
of the rows of the estimation sample, taken in the order of the panel and
time variables (rows that tie on them, as with missing time values or no
time variable, in the order of their values), is stored at estimation and
compared, so values moved to other observations, as a mistaken merge or sort
of one variable would move them, are refused, while sorting the data again
is not.  With time-series operators the check also covers the observations
that supply lags and leads, and the data must be {cmd:xtset} as they were at
estimation.  These commands need the estimation sample and are not available
after {cmd:estimates use}, which does not restore it; {cmd:xb}, {cmd:stdp},
and {cmd:mu} or {cmd:residuals} with {cmd:alpha()} are.

{marker tn_order}{...}
{pstd}
{ul:Sort order and reproducibility.}  Every sum is formed in an order that
does not depend on how the data are sorted or on how Stata breaks ties when
it sorts: each panel's fixed effect is summed by time, then by the values
summed; the clusters' sums of the fit and of {cmd:estat ape} are formed in a
fixed order; and {cmd:estat park} sorts by cluster, panel, and time.  So the
predictions are the same, to the last bit, whatever the order of the data,
and within any one release (Stata 15 or later), identical calls give
identical results to the last bit.

{marker tn_saved}{...}
{pstd}
{ul:Saved results and identifiers.}  By default {cmd:e(fe)} and
{cmd:e(fe_id)} hold one row per panel with the panel's identifier, and
saved estimates (the {cmd:.ster} file that {cmd:estimates save} writes, and
the results kept by {cmd:estimates store}) carry them, which matters when
the data are restricted and individual records may not leave the place where
they are held: specify {opt nofe} for estimates that are to be saved or
exported.  {opt nofe} omits the panel-level matrices {cmd:e(fe)} and
{cmd:e(fe_id)}, and stores {cmd:e(cmdline)} without the {cmd:if} and
{cmd:in} qualifier and, when the weights are given by an expression, without
the expression (shown as {cmd:[pweight=...]}), because either can name
values of the data, such as a panel identifier; after {cmd:vce(bootstrap)}
or {cmd:vce(jackknife)} the same holds for {cmd:e(command)}.  A note says
what was left out.

{pmore}
Saved estimates retain the fitted command and its coefficient labels: the
rest of the command line, the weight expression in {cmd:e(wexp)} (which
{cmd:predict} and {cmd:estat} need), and the coefficient names, which for a
factor variable include its levels (a factor of panel codes puts every code
in the names of {cmd:e(b)}).  Check those fields for identifiers before
exporting a fit from restricted data.  After a prefix typed by the user
({cmd:jackknife: xtgamfe} ...) the prefix stores its own {cmd:e(cmdline)}
and {cmd:e(command)}, as typed.  Apart from these, the saved results hold
the coefficients, their covariance, the shape estimates, counts, the means
of the regressors over the estimation sample (with which {cmd:predict}
checks new covariate values when a term was omitted as collinear), and
hashes of the data, and no value of any single observation.

{marker tn_apeci}{...}
{pstd}
{ul:Intervals for average partial effects.}  The interval that
{cmd:estat ape} reports is the effect plus or minus z (or t) times its
standard error.  When the level of the outcome is highly skewed across
panels (widely dispersed fixed effects, heavy-tailed errors, or sampling
weights that give a few panels much of the weight), the interval can cover
the population effect less often than its nominal level.  In the
simulations of Roebuck (2026, sec. 4.8) with 250 panels and widely
dispersed fixed effects, nominal 95 percent intervals covered the effect in
86 to 95 percent of the replications.  The misses were mostly from below:
the effect and its standard error were positively correlated, so that
samples with a small effect also had a small standard error.  Substituting a
jackknife or bootstrap standard error, or t critical values, scarcely
changed the coverage (by less than 0.01).

{pmore}
Two intervals that follow the skewness narrowed the gap without closing it;
more panels remain the remedy.  The interval on the log scale,
sign(theta) exp(ln|theta| -/+ z se/|theta|), needs no refitting and raised
the coverage in every design of those simulations in which the effects were
centered; it cannot contain zero, and those simulations had effects well
away from zero, so it describes the size of an effect whose sign is known on
other grounds.  A panel bootstrap-t, which resamples the panels (the
clusters, after {cmd:vce(cluster)}), refits, and divides each resampled
effect's deviation from the estimate by the standard error that
{cmd:estat ape} reports for it in that resample, helped more for a
continuous regressor (with 250 panels, in the three designs with the lowest
coverage, it raised the coverage by 0.03 to 0.05), at the cost of one fit
per resample.  Both were evaluated for the effects from the fitted means;
code for both is under {help xtgamfe##examples:Examples}.

{marker tn_fep}{...}
{pstd}
{ul:estat fepoisson: the model compared.}  The model compared is the one
that was fitted.  Its terms are taken from {cmd:e(indepvars_full)}, the
expanded term list of the fit with its factor levels and base levels, not
from the command line, so a variable created since the fit is not picked up
by a wildcard and a later {cmd:fvset base} does not change a contrast.  The
data are {cmd:xtset} with the panel variable, time variable, and delta of
the fit while the command runs, and the settings in place before it are
restored afterwards.  Each estimated term is formed as a variable on the
estimation sample (a factor level as its indicator, a lag or lead with the
delta of the fit), and both estimators are fitted to these variables, in
the full sample and in every replication; so each Poisson coefficient is
that of the same term and reference level as the {cmd:xtgamfe} coefficient
beside it, and a lag keeps its meaning in every replication.  The clusters
are resampled through identifiers numbered 1, 2, ... in their own order,
which gives the same replications as the following, run on the data in
memory with the same {opt reps()} and {opt seed()}, with any panel
identifiers (shown for a fit clustered on panels):

{phang2}{cmd:. program define gpdiff, rclass}{p_end}
{phang2}{cmd:  1.     xtgamfe cost x1 x2 i.time, nolog}{p_end}
{phang2}{cmd:  2.     tempname bg}{p_end}
{phang2}{cmd:  3.     scalar `bg' = _b[x1]}{p_end}
{phang2}{cmd:  4.     tempvar s}{p_end}
{phang2}{cmd:  5.     generate byte `s' = e(sample)}{p_end}
{phang2}{cmd:  6.     xtpoisson cost x1 x2 i.time if `s', fe}{p_end}
{phang2}{cmd:  7.     return scalar diff = `bg' - _b[x1]}{p_end}
{phang2}{cmd:  8. end}{p_end}
{phang2}{cmd:. generate long newid = id}{p_end}
{phang2}{cmd:. xtset newid time}{p_end}
{phang2}{cmd:. bootstrap diff=r(diff), cluster(id) idcluster(newid) reps(999) seed(20261117): gpdiff}{p_end}

{pmore}
The replications are run through {cmd:xtgamfe}, which the bootstrap names
when it starts.  An {cmd:xtpoisson} fit that does not converge
({cmd:e(converged)} not 1) counts as failed: on the full sample the command
stops with return code 430, and a replication in which either estimator
fails, does not converge, or does not estimate a coefficient that is tested
is left out, with a note; a coefficient that rests on one cluster, which is
not tested, may drop out of both refits.  Nothing is printed for each
replication, apart from the dots.  The refits use the {opt tolerance()} and
{opt iterate()} of the fit and start from the default values, so a fit
capped by a small {opt iterate()}, as one started with {opt from()} can be,
should be fitted again without the cap first: otherwise the bootstrap can
stop with return code 430 when it runs the command on the full sample, or
leave out replications whose refits do not converge.  When a coefficient rests on one cluster,
the replications that do not draw that cluster leave the term out of both
fits, and the {cmd:bootstrap} prefix would refuse them after the program
above, because the omitted terms of the {cmd:e(b)} that it leaves differ
from those of the full sample; on data that hold only the estimation sample
({cmd:keep if e(sample)} first), ending the program with
{cmd:ereturn clear}, and adding {cmd:nowarn} to {cmd:bootstrap}, keeps
them, as {cmd:estat fepoisson} does (it posts {cmd:e(sample)} instead).

{marker tn_park}{...}
{pstd}
{ul:estat park: special cases.}  The log squared residual is formed as
2 ln|y_it - mu_it|, so it does not overflow or underflow with the units of
the outcome, and the slope and its test do not depend on them.  An
observation whose residual is exactly zero has no logarithm and is left
out, with a note.  After an exact or near-exact fit the residuals are
rounding error, and {cmd:estat park} stops with return code 498; it stops
with the same return code when ln(mu_it) does not vary over the observations
used, so that the slope is not identified.  When the slope is estimated but
its clustered variance is zero or not available (as when the observations
with a nonzero residual lie in one cluster), the slope is reported without a
standard error, interval, or test, and {cmd:r(se)}, {cmd:r(t)}, and
{cmd:r(p)} are missing.

{marker tn_platform}{...}
{pstd}
{ul:Platforms.}  The command is written for Stata 15 and later.  Version
1.1.1 was tested with StataNow/MP 19.5 on Linux and Windows and with
Stata/MP 15.1 on Windows; other flavors (Stata/BE, Stata/SE) were not
tested.  {cmd:e(fe)} and {cmd:e(fe_id)} are never posted for more panels
than {cmd:c(max_matdim)}, the largest matrix dimension of the Stata in use
(800 in Stata/BE and in Stata 15 IC).  Where official commands work
differently across releases (as in the labels of the columns of a
coefficient table), the output follows the release in use.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{ul:Criterion.}  Write u_it = ln(y_it) - offset_it - x_it'beta, a_it for
the weights (one when there are none), and A_i = sum_t a_it (the number of
periods T_i when there are no weights).  For given beta the fixed effect is
alpha_i(beta) = ln[sum_t a_it exp(u_it)/A_i], and the command minimizes

{phang2}Q(beta) = sum_i A_i alpha_i(beta) + sum_it a_it x_it'beta.

{pstd}
The Hessian of the contribution of panel i is A_i times a weighted
within-panel covariance matrix of the regressors, so Q is convex, and
strictly convex when the within-centered regressors have full column rank.
The score of panel i is

{phang2}g_i(beta) = sum_t a_it x_it (1 - y_it/mu_it).

{pstd}
{ul:Covariance.}  {cmd:vce(robust)} and {cmd:vce(cluster)} report
H^-1 B H^-1 M/(M-1), where H is the Hessian of Q, B is the sum over clusters
of the outer products of the centered cluster totals of g_i (the totals
minus their mean, which is zero at an exact minimum), and M is the number of
clusters.  The rank of the covariance matrix cannot exceed M-1, and
{cmd:e(rank)} never exceeds that bound (a pivot at the level of rounding
error is not counted).  When it is below the number of coefficients the
command warns and does not report the Wald test of all coefficients: a
quadratic form in a generalized inverse of a singular covariance matrix
tests only some of the coefficients, and which ones depends on the units of
the regressors.  {cmd:xtreg} with a clustered VCE does the same.  Nor is the
test reported, whatever the rank, when a coefficient rests on one cluster
(see
{help xtgamfe_technical##tn_onecl:Coefficients identified by one cluster}).

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
effects (Chamberlain 1985).  With w_it = (y_it/mu_it)/T_i the fitted shares
and Lambda_i(b) = sum_t ln w_it, the log likelihood of panel i is

{phang2}lngamma(T_i kappa) - T_i lngamma(kappa) + kappa Lambda_i(b)
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
{cmd:e(shape_status)} or {cmd:e(kappa_ml_status)} says why (see
{help xtgamfe_technical##tn_exact:Exact fits}).  The coefficients do not depend on
either estimate.

{pstd}
{cmd:e(kappa_pearson)} = (n-G-K)/sum_it rho_it^2 is the usual
degrees-of-freedom-corrected Pearson value.  It is not consistent with the
number of periods fixed (in a balanced panel it converges to kappa + 1/T)
and is reported for reference.

{pstd}
{ul:Average partial effects.}  See {help xtgamfe##ape:estat ape}: each
effect is an average of f_it over the estimation sample, and its standard
error comes from the influence function sum_t a_it(f_it - theta)/sum(a) -
J H^-1 g_i of each panel, clustered as the fit; for the finite change the
step is h, set by {opt delta()}.

{pstd}
{ul:Notation.}  As in Roebuck (2026): a_it are the weights and A_i their
panel total, w_it the shares, Lambda_i the sum of the log fitted shares, D
the Wald statistic of {cmd:estat fepoisson}, and h the step of the finite
change of {cmd:estat ape}.

{title:Also see}

{psee}
{help xtgamfe}, {manhelp xtpoisson XT}, {manhelp glm R}
{p_end}
