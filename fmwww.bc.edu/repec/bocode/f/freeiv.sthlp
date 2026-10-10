{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "freeivmenu" "help freeivmenu"}{...}
{vieweralsosee "freeivdiag" "help freeivdiag"}{...}
{vieweralsosee "freeivtest" "help freeivtest"}{...}
{vieweralsosee "freeivreport" "help freeivreport"}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{viewerjumpto "Syntax" "freeiv##syntax"}{...}
{viewerjumpto "Description" "freeiv##description"}{...}
{viewerjumpto "Options" "freeiv##options"}{...}
{viewerjumpto "The routes, one by one" "freeiv##routes"}{...}
{viewerjumpto "Standard errors, weights and survey data" "freeiv##se"}{...}
{viewerjumpto "How to read the output" "freeiv##reading"}{...}
{viewerjumpto "What freeiv refuses" "freeiv##refused"}{...}
{viewerjumpto "Routes removed in 1.0.0" "freeiv##removed"}{...}
{viewerjumpto "What the third order cannot tell apart" "freeiv##caveat"}{...}
{viewerjumpto "Examples" "freeiv##examples"}{...}
{viewerjumpto "Stored results" "freeiv##results"}{...}
{viewerjumpto "References" "freeiv##references"}{...}
{title:Title}

{phang}
{bf:freeiv} {hline 2} Instrument-free estimation of a linear model with an
endogenous regressor

{p 4 4 2}{txt}Package {cmd:freeiv}, version {res}1.0.0{txt} (06/10/2026) {c |} Stata {res}16{txt} or later {c |} first release {res}0.8.0{txt} (14/09/2026){p_end}


{marker syntax}{...}
{title:Syntax}

{pstd}One endogenous regressor (model A){p_end}

{p 8 17 2}
{cmd:freeiv} {depvar} [{indepvars}] {cmd:(}{it:endogvar}{cmd:)}
{ifin} {weight}
[{cmd:,} {it:options}]

{pstd}Two indicators of the same confounder (model B){p_end}

{p 8 17 2}
{cmd:freeiv} {depvar} [{indepvars}] {cmd:(}{it:endogvar1} {it:endogvar2}{cmd:)}
{ifin} {weight}
[{cmd:,} {cmd:vce(svy)} {cmd:level(}{it:#}{cmd:)} {cmd:noheader}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt meth:od(name)}}the route; default {cmd:method(qme)}; see below{p_end}
{synopt:{opt del:ta(#)}}selection ratio assumed by {cmd:method(oster)}; default {cmd:delta(1)}{p_end}
{synopt:{opt rmax(#)}}R-squared assumed by {cmd:method(oster)}; default min(1.3 R1, 1){p_end}
{synopt:{opt sign(#)}}branch of {cmd:method(lsz)}, 1 or -1; default {cmd:sign(1)}{p_end}

{syntab:SE}
{synopt:{opt vce(svy)}}linearize over the design declared by {helpb svyset}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt nohead:er}}suppress the header{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{it:pweight}s and {it:aweight}s are allowed; see {help weight}.  Under
{cmd:vce(svy)} the weights are those of {cmd:svyset}.{p_end}
{p 4 6 2}{it:indepvars} may contain factor variables ({cmd:i.sex},
{cmd:ib2.region}, {cmd:c.age##c.age}); the estimate is the one obtained from
indicators built by hand.  {it:depvar} and the endogenous variables are plain
numeric variables.{p_end}
{p 4 6 2}The {cmd:bootstrap} and {cmd:jackknife} prefixes are allowed.  The
{cmd:svy} prefix is not: use {cmd:vce(svy)}.{p_end}
{p 4 6 2}A dialog box is available: {dialog freeiv:db freeiv}; the examples
below fill it in from their links.{p_end}

{pstd}
{it:name} in {cmd:method(}{it:name}{cmd:)} is one of the following, in the
order in which they impose the model{p_end}

{synoptset 12 tabbed}{...}
{synopthdr:name}
{synoptline}
{syntab:The interval: second moments}
{synopt:{opt bounds}}the identified set, which assumes nothing beyond the model{p_end}
{synopt:{opt ols}}the OLS slope, the upper end of the set{p_end}
{syntab:Order 3: exactly identified}
{synopt:{opt qme}}the quadratic moment estimator {bf:(the default)}{p_end}
{synopt:{opt hme}}the higher-moment estimator; adds V1 and V2 symmetric{p_end}
{syntab:Order 4: over-identified}
{synopt:{opt gmm}}the joint GMM on nine moments, its J and its region{p_end}
{synopt:{opt pgmm}}the same moments with orders 2 and 3 fitted exactly{p_end}
{syntab:Other maintained models, for comparison}
{synopt:{opt lsz}}Lewbel, Schennach and Zhang (2024){p_end}
{synopt:{opt lewbel12}}Lewbel (2012), heteroskedasticity-based instruments{p_end}
{synopt:{opt copula}}Park and Gupta (2012), Gaussian copula{p_end}
{synopt:{opt rank}}Breitung, Mayer and Wied (2024), rank control function{p_end}
{synopt:{opt oster}}Oster (2019), coefficient stability{p_end}
{syntab:Everything}
{synopt:{opt all}}every route side by side, each judged against the interval{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:freeiv} estimates the effect of an endogenous regressor without an external
instrument.  An unobserved confounder U moves both the regressor and the
outcome:

{p 8 8 2}Y2 = X'b2 + a2 U + V2{p_end}
{p 8 8 2}Y1 = X'b1 + g Y2 + a1 U + V1{p_end}

{pstd}
with U, V1 and V2 independent of one another and of the exogenous controls X.
The coefficient wanted is g.  OLS is biased because U enters both equations;
the bias is proportional to a1 a2, so a confounder that moved the regressor
alone would be harmless.

{pstd}
{bf:Scale consistency.}  Model A maintains a1 = g a2: the confounder moves the
outcome directly by exactly as much as it moves it through the regressor.
This is a substantive restriction, plausible in some applications and not in
others.  It has one consequence a practitioner should keep in view: under it,
OLS can only exaggerate the size of g, never understate it, so any value
beyond the OLS slope (above it, for a positive effect) -- an
instrumental-variable estimate, or the truth when the regressor is measured
with error and OLS is attenuated -- is incompatible with it.  It can be tested
with a second indicator of the same confounder (model B below).

{pstd}
{bf:One structure, one missing number.}  Under scale consistency the second
moments of the two first-stage residuals give three equations in four
unknowns.  The missing number is the confounder's share of the first-stage
residual variance, c = theta/(theta + sigma2_V2), between 0 and 1, and the
OLS slope gamma-tilde satisfies

{p 8 8 2}gamma-tilde = g (1 + c){p_end}
{p 8 8 2}g in [gamma-tilde/2, gamma-tilde]{p_end}

{pstd}
That interval assumes nothing more: it is exactly the set of values of g that
keep every implied variance non-negative.  Every route of model A obtains the
missing number by imposing the same linear structure on the moments of the
next order:

{p2colset 9 26 28 2}{...}
{p2col:{bf:moments}}{bf:what the structure gives}{p_end}
{p2line}
{p2col:order 2}three equations for four unknowns: the interval
({cmd:bounds}){p_end}
{p2col:order 3}three more for two more unknowns: g exactly identified
({cmd:qme}; {cmd:hme} if the noise is symmetric){p_end}
{p2col:order 4}three more for two more: one over-identifying restriction, a J
on 1 degree of freedom ({cmd:gmm}, {cmd:pgmm}){p_end}
{p2col:two indicators}sixteen moments for twelve parameters with a1 free: four
over-identifying restrictions, and scale consistency itself tested (model B){p_end}
{p2line}
{p2colreset}{...}

{pstd}
The other maintained models -- {cmd:lsz}, {cmd:lewbel12}, {cmd:copula},
{cmd:rank} and {cmd:oster} -- close the system with an assumption of their own.
They are reported on the same data so that the interval judges them all: an
estimate outside it implies a negative variance under scale consistency.

{pstd}
{bf:Two indicators.}  Two variables inside the parentheses switch to model B:
Y2 and Y3 both load on U, both may affect the outcome, and the confounder's
direct loading a1 is free.  The closed form of Araar (2026d) identifies the
coefficients of both and a1 from the second and third moments, so that scale
consistency becomes a hypothesis to test rather than an assumption.

{pstd}
{bf:Companion commands.}  {helpb freeivmenu} says, before any estimation, which
routes the data can carry; {helpb freeivdiag} says what a value of g implies
for the unobservables; {helpb freeivtest} tests endogeneity, the agreement
between routes and an outside estimate against the interval;
{helpb freeivreport} assembles the three in one table.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt method(name)} selects the route of model A.  Every route estimates the
same g; what separates them is the assumption each adds.  The default,
{cmd:qme}, adds the least.  {cmd:method(all)} prints every route against the
interval, which is how they are meant to be read.  The option is refused with
two endogenous regressors, where a single closed form is the method.

{phang}
{opt delta(#)} and {opt rmax(#)} act on {cmd:method(oster)}: Oster's ratio of
selection on unobservables to selection on observables (1: they matter as much
as the controls), and the R-squared a regression including the unobservables
would reach, by default min(1.3 R1, 1) with R1 the R-squared of the controlled
regression.  Both are assumed, not estimated: report a range.  {opt rmax()}
lies in (0, 1].

{phang}
{opt sign(#)} acts on {cmd:method(lsz)} and takes 1 or -1.  The moments of LSZ
identify g up to an orientation; the option picks the branch the solver
follows, as {cmd:trigmm} does.  Keep the branch whose implied parameters are
admissible.

{pstd}
In model A these three options are accepted with every route and act only on
their own ({cmd:method(all)} uses all three); with two endogenous regressors
they are refused, together with {opt method()}, rather than ignored.

{dlgtab:SE}

{phang}
{opt vce(svy)} computes the standard errors by linearization over the design
declared by {helpb svyset}: its weights, strata, primary sampling units and
finite-population correction.  See
{help freeiv##se:Standard errors, weights and survey data}.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level.  {cmd:freeiv, level(}{it:#}{cmd:)}
redisplays the last estimates at another level.

{phang}
{opt noheader} suppresses the header.


{marker routes}{...}
{title:The routes, one by one}

{pstd}
Each route: the model in plain words, what it adds to scale consistency, how it
fails and what announces it, its references.  Read it with {helpb freeivmenu}
at hand: for each route the menu prints the statistic that says whether these
data carry it.  A route whose signal is absent still returns a number, and that
number means little.

{pstd}{bf:bounds} {hline 2} the identified set{p_end}

{pstd}
Not an estimator but the most the data say without a further assumption: g lies
in [gamma-tilde/2, gamma-tilde] (in [gamma-tilde, gamma-tilde/2] when the slope
is negative).  The width is gamma-tilde/2: under scale consistency OLS
overstates g by at most a factor of two.  Each end has its standard error.  The
interval fails only when the model fails -- a regressor measured with error, a
confounder whose direct effect exceeds or opposes the one it transmits -- and
nothing in model A can see that; model B can.  (Araar 2026a, 2026c.)

{pstd}{bf:ols} {hline 2} the upper end{p_end}

{pstd}
The OLS slope with the controls, reported because under scale consistency it
{it:is} the upper end of the interval.

{pstd}{bf:qme} {hline 2} the quadratic moment estimator, the default{p_end}

{pstd}
The three third-order cross-moments of the two residuals satisfy the
quadratic

{p 8 8 2}2 m03 g^2 - 3 m12 g + m21 = 0{p_end}

{pstd}
Write A = a2^3 E[U^3], the confounder's part of the third moment of the
first-stage residual, and B = E[V2^3], the rest: the roots are g and
g (4A + B)/(2(A + B)), and the discriminant is

{p 8 8 2}D = g^2 (2A - B)^2{p_end}

{pstd}
The route keeps the root inside the interval.  It needs a third-order signal in
the first-stage residual that is not split as B = 2A.  A skewed confounder
provides it; a skewed V2 alone does too, the other root being then g/2, below
the interval.  Araar (2026b) finds the route usable from a skewness of the
first-stage residual of 0.5 and reliable from 1.

{pstd}
How it fails is printed, not hidden.  Near D = 0 the two roots merge and the
standard error, proportional to 1/sqrt(D), grows.  When D falls below zero
the vertex 3 m12/(4 m03), where the roots merge, is returned and flagged; it
coincides with g when B = 2A.  A D below zero by more than its sampling noise
cannot come from the model at all, and the output then says that the data
reject it.  When no root lies inside the interval, the model is refuted on
these data, and the output says that too.  Read the z of m03 and the z of D in
{helpb freeivmenu} first.  (Araar 2026b, 2026c.)

{pstd}{bf:hme} {hline 2} the higher-moment estimator{p_end}

{pstd}
The closed form (1/2)(m30/m03)^(1/3).  It adds to the qme's requirement that
V1 and V2 be symmetric: then m30/m03 = 8 g^3.  It fails quietly: with a skewed
noise it still returns a plausible number.  The output and {helpb freeivmenu}
read B = E[V2^3] at the retained value; E[V1^3] cannot be read.  When m30/m03
does not have the sign of gamma-tilde the route returns nothing.  (Araar
2026a.)

{pstd}{bf:gmm} {hline 2} the joint GMM on the moments of orders 2, 3 and 4{p_end}

{pstd}
Nine moment conditions in eight parameters: one over-identifying restriction
and a J on 1 degree of freedom.  The fourth order imposes the same linear
structure once more, and the structure becomes testable.  The criterion is
minimised on a deterministic grid: once g and theta are fixed the nine
residuals are linear in the six other parameters, so there is no seed and no
starting value -- multi-start over the eight parameters stops at local minima
on six of the eight applications of Araar (2026c).

{pstd}
The route reports the region of g where the profiled J stays within 3.84 of its
minimum, and its share of the interval.  Read that share before the point: it
does not rest on a standard error, and when it fills the whole interval -- as
on seven of the eight applications of Araar (2026c) -- the moments of orders 3
and 4 have added nothing to the bounds, and the interval is what to report.  A
minimum on the boundary of the parameter space gets no standard error.  The J
tests scale consistency and the linearity of the confounder's effect jointly.
It cannot test when V2 is normal: the Jacobian of the model with a1 free has a
determinant proportional to B kurt_U - A kurt_V2, which a normal V2 sets to
zero; read {cmd:e(idfac)} and its z before reading a non-rejection.  The route
is computed under {cmd:method(gmm)} and {cmd:method(all)}.  (Araar 2026c.)

{pstd}{bf:pgmm} {hline 2} the profiled GMM, the companion of gmm{p_end}

{pstd}
The same nine moments with the conditions of orders 2 and 3 fitted exactly,
which leaves four residuals in three unknowns: again a J on 1 degree of
freedom.  A different estimator, not the same one solved differently.  Its
search is one-dimensional and cheap, so its J is printed under every route as
the test at order four; its fifth residual is the qme's quadratic itself.  A
wide gap between {cmd:e(g_gmm)} and {cmd:e(g_pgmm)} signals a flat criterion,
not an error in either.  (Araar 2026c, section 6.3.)

{pstd}{bf:lsz} {hline 2} Lewbel, Schennach and Zhang (2024){p_end}

{pstd}
The same triangular system with the confounder's direct loading free -- not
scale consistency -- identified by non-Gaussian errors, through moments up to
order five.  With p(0 1), as {cmd:trigmm} implements it, the system is exactly
identified and solved as a root; {cmd:freeiv} reproduces {cmd:trigmm}'s
estimate within its stopping tolerance.  Read {cmd:e(lsz_conv)} first: a solver
that did not converge shows no standard error, and its point is not an
estimate; under {cmd:method(lsz)} the command then ends with r(430), as Stata's
estimators do when they do not converge, so that the {cmd:bootstrap} prefix
drops and counts such a draw (see {help freeiv##se:Standard errors}).  Where the
solver stops, {cmd:trigmm} with several starts remains the reference.
Confronting the route with the interval tests the scale-consistent model, not
LSZ.  It runs under {cmd:method(lsz)} and {cmd:method(all)}.
(Lewbel, Schennach and Zhang 2024; Lee et al. 2026.)

{pstd}{bf:lewbel12} {hline 2} heteroskedasticity-based instruments{p_end}

{pstd}
Two-stage least squares with the instruments (X - mean X) eps2.  It needs the
first-stage error to be heteroskedastic in X -- {helpb freeivmenu} prints the F
-- and X uncorrelated with eps1 eps2; in the one-factor model the second holds
when the heteroskedasticity comes from V2, not from U (Araar 2026a).  At least
one control is needed.  It reproduces {cmd:ivreg2h}.  (Lewbel 2012; Baum and
Schaffer 2012.)

{pstd}{bf:copula} {hline 2} Gaussian copula{p_end}

{pstd}
Adds the control function Phi^-1(F-hat(Y2)) to the outcome equation.  It
assumes a Gaussian copula between the regressor and the structural error, and a
non-normal regressor: with a normal one the control is collinear with Y2.
(Park and Gupta 2012.)

{pstd}{bf:rank} {hline 2} rank control function{p_end}

{pstd}
The same idea applied to the ranks of the first-stage residual, which takes
the controls out of the transformation.  It needs a non-Gaussian residual and
at least one control (with none it is the copula).  (Breitung, Mayer and Wied
2024.)

{pstd}{bf:oster} {hline 2} coefficient stability{p_end}

{pstd}
The bias-adjusted coefficient b1 - delta (b0 - b1)(rmax - R1)/(R1 - R0) under
proportional selection on observables and unobservables, b0 and R0 coming from
the regression without controls.  delta and rmax are assumed: report a range.
It reproduces {cmd:psacalc}.  (Oster 2019, 2013.)

{pstd}{bf:Model B} {hline 2} two indicators of one confounder{p_end}

{pstd}
Y2 and Y3 both load on U (Y3 = X'b3 + a3 U + V3) and both may affect the
outcome, with a1 free.  Under one factor (U, V1, V2, V3 independent), a skewed
confounder, relevant indicators, and an indicator not caused by the regressor
(Y2 does not enter the equation of Y3), Theorem 1 of Araar (2026d) gives g2,
g3, a1, the loadings, E[U^3] and the idiosyncratic variances in closed form.
Three guards refuse the closed form when the moments contradict one factor:
(1) the two third-order cross-moments have opposite signs, (2) the product of
the loadings would be negative, (3) an implied variance is negative.  The
command then ends with r(498) after its display, {cmd:e(guard)} posted.

{pstd}
Scale consistency becomes a test, a1 against g2 a2 + g3 a3; a one-factor check
compares three estimates of a2/a3; a GMM on sixteen moments gives a J on 4
degrees of freedom.  The output also prints what Y3 would return as an
instrument for Y2: when Y3 has no effect of its own on the outcome, that is
g2 + a1/a2 -- twice g2 under scale consistency.  Araar (2026d) asks for a
correlation between the two indicators with t above 10.  (Araar 2026d.)


{marker se}{...}
{title:Standard errors, weights and survey data}

{pstd}
{bf:The analytic standard errors.}  The two ends of the interval, {cmd:qme},
{cmd:hme}, {cmd:gmm}, {cmd:pgmm}, {cmd:lsz} and the closed form of model B have
one: the delta method on the covariance of the moment contributions, the
estimation of the coefficients on X accounted for.  {cmd:lewbel12},
{cmd:copula}, {cmd:rank} and {cmd:oster} return a point only: use the
{cmd:bootstrap} prefix -- 500 replications take about 20 seconds on the
examples below.

{pstd}
{bf:The qme near the edge.}  The qme's standard error is proportional to
1/sqrt(D), and the delta method understates its sampling error when the z of D
is below 2: on {cmd:freeiv_sim1} (z of D 1.49), 0.044 against 0.053 for a
bootstrap of 500 replications.  Prefer {cmd:bootstrap} there -- but not near
zero.  Where the two roots merge, as where the third-order signal is weak (a
small z of m03) or a minimum lies on the boundary, the estimator is no longer a
smooth function of the data, and the bootstrap is no remedy (Andrews 2000;
Andrews and Cheng 2012): no standard error holds, and the interval, which rests
on the second order alone, is the answer, with the region of the GMM after it.

{pstd}
{bf:The bootstrap.}  Under the {cmd:bootstrap} prefix each replication runs the
whole route again.  A replication in which the route has no estimate -- an LSZ
solver that does not converge, an hme that does not exist, a guard of model B
-- ends with r(430) or r(498): the prefix drops it, and the output says how many
replications have an estimate.  The standard error and the other statistics
are computed on those only, the draws in which the data meet the conditions of
the route's model: a selected subset.  Read them when nearly all replications
succeed.  When many fail, the share is the result: on {cmd:wage1}, LSZ has an
estimate in 20 of 50 draws, and its bootstrap standard error is not read.  A
minimum of {cmd:gmm} on the boundary is an estimate, and its draw is kept.

{pstd}
{bf:Weights.}  Every moment is weighted.  With {it:aweight}s the covariance of
the contributions is their weighted mean square.  With {it:pweight}s it takes
the sandwich form, every observation its own primary unit; with all weights
equal to 1 that is the unweighted standard error times sqrt(n/(n-1)).

{pstd}
{bf:Survey data.}  Under {cmd:vce(svy)} the design declared by {helpb svyset}
enters the covariance of the contributions: linearized values summed by primary
sampling unit, deviations within strata, the finite-population correction
(given as a sampling rate or as the number of units in the stratum), and t on
the design degrees of freedom, the number of units minus the number of strata.
This is the linearization {helpb svy} uses: on the {cmd:ols} route it
reproduces {cmd:svy: regress}.  The first stage of the design is used; a
multistage design with an fpc at the first stage has that fpc dropped, which
treats the units as drawn with replacement and errs towards a larger variance,
and the output says so.  A stratum with a single unit makes the standard
errors missing under {cmd:singleunit(missing)}, as {cmd:svy} does, and
contributes nothing under {cmd:singleunit(certainty)}; {cmd:scaled},
{cmd:centered} and poststratification are refused.  The two GMM build their
weight from the design's covariance, so where it is missing they return no
estimate.  {cmd:if} and {cmd:in} restrict the design to the observations
selected, as with {cmd:svy}; there is no {cmd:subpop()}.


{marker reading}{...}
{title:How to read the output}

{phang}1. {helpb freeivmenu}, before estimating: which routes the data carry.
The z of m03 says whether there is a third-order signal, the z of D whether the
qme can use it (far below zero, it refutes the model), the count of roots
inside the interval whether its value is admissible.{p_end}

{phang}2. The interval.  An estimate outside it, from any route, implies a
negative variance under scale consistency; {helpb freeivdiag} says which.{p_end}

{phang}3. The point and its precision.  With a z of D below 2 the qme's
interval is too narrow: bootstrap it; near zero, read the interval instead.{p_end}

{phang}4. The block on over-identification: under {cmd:method(gmm)} and
{cmd:method(all)}, the share of the interval covered by the region first; then
the J, with the factor that says whether it can test anything.{p_end}

{phang}5. {helpb freeivtest}: endogeneity itself (it needs no estimate of g),
the agreement between routes, an outside estimate against the interval.{p_end}


{marker refused}{...}
{title:What freeiv refuses}

{pstd}
An option quietly absorbed is worse than one refused, because the result still
looks like a result.  These are refused with a message naming the constraint,
before any computation:

{phang}{cmd:sign()} other than 1 or -1, {cmd:rmax()} outside (0, 1], a missing
{cmd:delta()}.{p_end}

{phang}{cmd:vce()} other than {cmd:svy}; {cmd:vce(svy)} with weights on the
command line, on data not {cmd:svyset}, with {cmd:singleunit(scaled)} or
{cmd:singleunit(centered)}, or with poststratification; {it:fweight}s.{p_end}

{phang}A variable in two roles: {it:depvar} also endogenous or a control, an
endogenous variable also a control, the same variable twice inside the
parentheses.{p_end}

{phang}{cmd:method(lewbel12)}, {cmd:method(rank)} or {cmd:method(oster)} with
no exogenous control; under {cmd:method(all)} they are then missing and a note
says why.{p_end}

{phang}{cmd:method()}, {cmd:delta()}, {cmd:rmax()} or {cmd:sign()} with two
endogenous regressors.{p_end}

{phang}A route removed in 1.0.0 ({cmd:sce}, {cmd:rre}, {cmd:qbe}, {cmd:rpiv},
{cmd:ape}), with a pointer to the section below.{p_end}

{pstd}
Numerical and statistical failures are reported, not hidden: the vertex of the
qme, no root inside the interval, a discriminant below zero beyond its noise,
an LSZ solver that did not converge, a guard of model B, a GMM minimum on the
boundary, a design whose variance is missing.  A route asked for alone that has
no estimate ends with a return code after its display, {cmd:e()} posted: r(430)
for an LSZ solver that does not converge, r(498) for a route with no value or a
guard of model B; {cmd:method(all)} never does.


{marker removed}{...}
{title:Routes removed in 1.0.0}

{pstd}
Five routes of earlier versions are no longer offered.

{phang}{cmd:sce} and {cmd:rre} set the missing number instead of learning it,
from a restriction outside the structure: equal noise variances,
Var(V1) = Var(V2), which depends on the units of the two variables, or its
scale-free variant Var(V1) = g^2 Var(V2), which appears in none of the papers.
{helpb freeivdiag} prints the variances a value of g implies.{p_end}

{phang}{cmd:qbe}, the quantile bias extrapolation, with its option
{cmd:quantile()}: its bias ratio was a regression calibrated on simulated laws
of a positively skewed confounder -- an auxiliary check in Araar (2026c), not an
estimator of the model.{p_end}

{phang}{cmd:rpiv}, residual purging, is inconsistent (Araar 2026a), and
{cmd:ape} chose between OLS and RPIV.{p_end}

{pstd}
{it:fweight}s are removed as well: use {it:pweight}s, or {cmd:expand} the
data.


{marker caveat}{...}
{title:What the third order cannot tell apart}

{pstd}
One caveat applies to every instrument-free route, not only to these.  With one
indicator the three third-order moments serve three unknowns (g, A, B): the
system is just identified, so any triple (m03, m12, m21) can be rationalised by
a confounder, and a mechanism with no confounder at all produces the same
triple.  Take y1 = a y2 + b y2^2 + e with y2 standard normal, e independent and
no latent factor.  Then m03 = 0, m12 = 2b, m21 = 4ab, and the qme's quadratic
reduces to -6b g + 4ab = 0: {cmd:method(qme)} returns 2a/3 for every b other
than zero -- a correction of one third of the OLS slope that does not depend on
the size of the quadratic term, lies inside the interval, has a positive
discriminant, and implies a confounder share of one half with positive
variances.  Nothing at order three can object, because nothing at order three
is over-identified.

{pstd}
The fourth order can: on that design with b = 0.1 and n = 20,000 the J of
{cmd:method(pgmm)} is 14 and that of {cmd:method(gmm)} is 5.4, both rejecting.
But the power of the test falls with b^2 and with n while the bias does not: at
b = 0.02 the J is 0.2 and the estimate is still 0.70.  So read the z of the
discriminant in {helpb freeivmenu} as the strength of a third-order signal, not
as its source: a curvature in E[xi | eps2] is what a skewed confounder and a
non-linear outcome equation both produce.  The two-indicator model is the least
exposed route, because its loading layer never reads y1.  A valid external
instrument, where one exists, does not rest on the third-order structure at
all: an instrument-free route complements one, it does not replace it.


{marker examples}{...}
{title:Examples}

{pstd}
Every example runs from its links, in three forms that give the same commands:
in the command window; in the dialog box of {cmd:freeiv}, filled in, where
{bf:OK} runs the command; or as a do-file in the Do-file Editor.  The
estimations, the {cmd:freeiv} lines of a listing, run from the links below it,
under the same labels in the command window and in the dialog box; each loads
its data itself.  The other lines that are links run in the command window:
the first loads the example data, the others ({helpb freeivmenu},
{helpb freeivtest}, ...) run on the data in memory.  The do-file holds the
whole example.  The example data stay in memory; data with changes not saved
are never replaced: save them, or {cmd:clear}, first.  The four datasets of the
package are read from the current folder
({stata "ssc install freeiv, all replace"} or {cmd:net get freeiv} copies them
there), otherwise from the SSC archive or from GitHub; example 7 uses
{cmd:nlsw88}, shipped with Stata, and example 8 {cmd:nhanes2}, read with
{cmd:webuse} (an internet connection is needed).  The syntax is
{cmd:freeiv_examples} {it:#} [{it:k}] [{cmd:, db} | {cmd:do} | {cmd:data}],
{it:k} the estimation of an example that has several.

{pstd}
Simulated data first, where the truth is known and each route can be judged
against it; then real data, where the diagnostics say how much one regressor
can carry, and a second indicator what it adds.


{pstd}{bf:Example 1.} Where the model holds{p_end}

{pstd}
{cmd:freeiv_sim1.dta} is generated from{p_end}

{phang2}{cmd:u  = (chi2(3) - 3)/sqrt(6)}{space 5}{it:skewed, unit variance}{p_end}
{phang2}{cmd:y2 = 0.30 x + 0.80 u + v2}{space 6}{it:v1, v2, x standard normal}{p_end}
{phang2}{cmd:y1 = 0.60 x + 0.40 y2 + 0.32 u + v1}{p_end}

{pstd}
The truth is g = 0.40, and 0.32 = 0.40 x 0.80 is scale consistency, holding
by construction{p_end}

{phang2}{stata "freeiv_examples 1, data":. use freeiv_sim1}{p_end}
{phang2}{stata "freeivmenu y1 x (y2)":. freeivmenu y1 x (y2)}{p_end}
{phang2}{cmd:. freeiv y1 x (y2)}{p_end}
{phang2}{cmd:. freeiv y1 x (y2), method(all)}{p_end}
{phang2}{cmd:. freeiv y1 x (y2), method(gmm)}{p_end}
{phang2}{stata "display e(g_gmm), e(ar_lo), e(ar_hi), e(ar_frac)":. display e(g_gmm), e(ar_lo), e(ar_hi), e(ar_frac)}{p_end}
{phang2}{cmd:. freeiv y1 x (y2), method(pgmm)}{p_end}
{p 8 8 2}{txt}(example 1: click to run in command window: {stata "freeiv_examples 1 1":qme, the default} |
{stata "freeiv_examples 1 2":method(all)} | {stata "freeiv_examples 1 3":method(gmm)} |
{stata "freeiv_examples 1 4":method(pgmm)}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 1 1, db":qme, the default} |
{stata "freeiv_examples 1 2, db":method(all)} | {stata "freeiv_examples 1 3, db":method(gmm)} |
{stata "freeiv_examples 1 4, db":method(pgmm)}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 1, do":open as a do-file}){p_end}

{pstd}
The interval is [0.282, 0.565]; the qme returns 0.436 (standard error 0.044),
the hme 0.449, the joint GMM 0.445, and the region where its J stays within
3.84 of its minimum covers 65% of the interval: here the moments of orders 3 and
4 narrow what the second order gives.  {cmd:lewbel12}, {cmd:copula} and
{cmd:rank} land far outside the interval (1.35 to 1.39): their own assumptions
do not hold in this design, and the interval shows it.  The two GMM agree
(0.4455 and 0.4453): the criterion is not flat.


{pstd}{bf:Example 2.} The edge of identification{p_end}

{pstd}
{cmd:freeiv_sim2.dta} differs in one respect: {cmd:v2} has the same skewed law
as {cmd:u}.  Scale consistency still holds and the truth is still 0.40, but now
B = E[V2^3] = 1.633 nearly equals 2A = 2 x 0.8^3 x 1.633 = 1.672, so the
discriminant D = g^2 (2A - B)^2 is almost zero by construction (0.0002, against
0.45 in {cmd:freeiv_sim1}){p_end}

{phang2}{stata "freeiv_examples 2, data":. use freeiv_sim2}{p_end}
{phang2}{stata "freeivmenu y1 x (y2)":. freeivmenu y1 x (y2)}{p_end}
{phang2}{cmd:. freeiv y1 x (y2), method(all)}{p_end}
{p 8 8 2}{txt}(example 2: click to run in command window: {stata "freeiv_examples 2":method(all)}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 2, db":method(all)}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 2, do":open as a do-file}){p_end}

{pstd}
In this sample D is slightly negative (z = -0.85, within its noise): the two
roots merge, and the qme returns the vertex, 0.420, and says so.  The hme
returns 0.336 with a standard error of 0.015 -- and is wrong, because the
symmetry it assumes, B = 0, is violated by construction; the menu reads B at
the vertex, 1.49, and calls that symmetry doubtful.  A route that fails loudly
is safer than one that fails quietly.


{pstd}{bf:Example 3.} Real data with one regressor: the interval is the
result{p_end}

{pstd}
{cmd:freeiv_card.dta} is the Card (1995) extract used in Araar (2026d), with
the controls of that paper; then the same model with fewer controls{p_end}

{phang2}{stata "freeiv_examples 3, data":. use freeiv_card}{p_end}
{phang2}{stata "freeivmenu lwage exper expersq black south smsa (educ)":. freeivmenu lwage exper expersq black south smsa (educ)}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ), method(all)}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq (educ)}{p_end}
{phang2}{stata "freeivdiag":. freeivdiag}{p_end}
{p 8 8 2}{txt}(example 3: click to run in command window: {stata "freeiv_examples 3 1":all the controls, method(all)} | {stata "freeiv_examples 3 2":exper expersq only}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 3 1, db":all the controls, method(all)} | {stata "freeiv_examples 3 2, db":exper expersq only}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 3, do":open as a do-file}){p_end}

{pstd}
The interval is [0.037, 0.074].  The third-order signal the qme needs is weak:
the skewness of the first-stage residual is 0.17, the menu calls the z of m03
(2.43) weak and the z of D (0.01) absent, and the qme, 0.072, comes with a
standard error of 0.25.  The region of the joint GMM covers the whole interval,
and its minimum sits on the boundary.  The package's diagnostics say it
themselves: on these data the result is the interval, and the qme is reported
with its precision, not read as a point.  That is the ordinary case with one
endogenous regressor.

{pstd}
With fewer controls the qme moves within its noise: its root now lies above
the interval, 0.119 against [0.047, 0.093], though not significantly given its
standard error of 0.040, and {helpb freeivdiag} shows the negative variance
such a value implies.  Removing controls also changes the model itself -- the
OLS slope goes from 0.074 to 0.093 -- so the move is not noise alone.


{pstd}{bf:Example 4.} An estimate from elsewhere, against the interval{p_end}

{pstd}
Card's instrumental-variable estimate with college proximity is 0.132
(standard error 0.049), above the OLS slope.  Under scale consistency OLS can
only overstate g, so the two are incompatible -- at what precision?{p_end}

{phang2}{stata "freeiv_examples 4, data":. use freeiv_card}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ)}{p_end}
{phang2}{stata "freeivtest, gamma(0.132) segamma(0.049)":. freeivtest, gamma(0.132) segamma(0.049)}{p_end}
{p 8 8 2}{txt}(example 4: click to run in command window: {stata "freeiv_examples 4":qme, the default}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 4, db":qme, the default}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 4, do":open as a do-file}){p_end}

{pstd}
The distance to the upper end is 0.058, with z = 1.18: outside the set, not
significantly.  Choosing between the instrument and scale consistency is the
researcher's call; these data do not make it.


{pstd}{bf:Example 5.} A second indicator of the confounder{p_end}

{pstd}
Mother's education loads on the family background that confounds schooling,
and may affect wages itself: it is an indicator, not an instrument.  Two other
indicators of the file follow, which the guards refuse{p_end}

{phang2}{stata "freeiv_examples 5, data":. use freeiv_card}{p_end}
{phang2}{stata "freeivmenu lwage exper expersq black south smsa (educ motheduc)":. freeivmenu lwage exper expersq black south smsa (educ motheduc)}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ motheduc)}{p_end}
{phang2}{stata "freeivtest":. freeivtest}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ IQ)}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ KWW)}{p_end}
{p 8 8 2}{txt}(example 5: click to run in command window: {stata "freeiv_examples 5 1":motheduc} | {stata "freeiv_examples 5 2":IQ} | {stata "freeiv_examples 5 3":KWW}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 5 1, db":motheduc} | {stata "freeiv_examples 5 2, db":IQ} | {stata "freeiv_examples 5 3, db":KWW}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 5, do":open as a do-file}){p_end}

{pstd}
Now the coefficient on schooling is a point, 0.066 (standard error 0.016), and
the confounder's direct effect a1 = 0.067 is estimated rather than assumed.
Scale consistency is tested: a1 - (g2 a2 + g3 a3) = 0.032 with a standard error
of 0.21 -- not rejected, and, at this skewness of the confounder (0.47), not
informative either.  Used as an instrument for schooling, mother's education
would return 0.102, 0.036 above g2.  These numbers reproduce Table 6b of Araar
(2026d); with {cmd:fatheduc} the coefficient is 0.035.  {cmd:IQ} implies a
negative idiosyncratic variance (guard 3) and {cmd:KWW} third-order
cross-moments of opposite signs (guard 1): Table 6a of Araar (2026d).  Both end
with r(498), and the do-file runs them under {cmd:capture noisily}.


{pstd}{bf:Example 6.} Two indicators with a known truth{p_end}

{pstd}
{cmd:freeiv_proxy.dta} is simulated, n = 5,000, from{p_end}

{phang2}{cmd:y2 = 0.3 x + 0.8 u + v2}{p_end}
{phang2}{cmd:y3 = 0.2 x + 0.6 u + v3}{p_end}
{phang2}{cmd:y1 = 0.6 x + 0.40 y2 + 0.20 y3 + 0.10 u + v1}{p_end}

{pstd}
with {cmd:v1 v2 v3 x} standard normal and {cmd:u} skewed (skewness 1, unit
variance).  Scale consistency does {it:not} hold, deliberately: it would
require a1 = g2 a2 + g3 a3 = 0.44 against 0.10{p_end}

{phang2}{stata "freeiv_examples 6, data":. use freeiv_proxy}{p_end}
{phang2}{cmd:. freeiv y1 x (y2 y3)}{p_end}
{phang2}{stata "freeivtest":. freeivtest}{p_end}
{p 8 8 2}{txt}(example 6: click to run in command window: {stata "freeiv_examples 6":two indicators}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 6, db":two indicators}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 6, do":open as a do-file}){p_end}

{pstd}
The closed form returns 0.442 and 0.219 for the two coefficients, and the test
rejects scale consistency (z = -3.71), as it should.


{pstd}{bf:Example 7.} A model the data refute{p_end}

{phang2}{stata "freeiv_examples 7, data":. sysuse nlsw88}{p_end}
{phang2}{stata "generate lwage = ln(wage)":. generate lwage = ln(wage)}{p_end}
{phang2}{stata "freeivmenu lwage grade age i.race (tenure)":. freeivmenu lwage grade age i.race (tenure)}{p_end}
{phang2}{cmd:. freeiv lwage grade age i.race (tenure)}{p_end}
{p 8 8 2}{txt}(example 7: click to run in command window: {stata "freeiv_examples 7":qme, the default}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 7, db":qme, the default}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 7, do":open as a do-file}){p_end}

{pstd}
The signal is strong -- skewness of the first-stage residual 1.00, z of D 5.66
-- and the qme is precise, 0.046 with a standard error of 0.003; but neither
root lies inside the interval [0.014, 0.027], the implied confounder variance is
negative, and the J at order four rejects (26.7 for the profiled GMM, 34.4 for
the joint one).  A precise estimate is not a valid one: the one-factor model
with scale consistency does not describe tenure and wages in these data, and
the output says so.


{pstd}{bf:Example 8.} Survey data{p_end}

{phang2}{stata "freeiv_examples 8, data":. webuse nhanes2}{p_end}
{phang2}{stata "svyset":. svyset}{p_end}
{phang2}{cmd:. freeiv bpsystol age female black (bmi), vce(svy)}{p_end}
{phang2}{cmd:. freeiv bpsystol age female black (bmi) [pweight=finalwgt]}{p_end}
{p 8 8 2}{txt}(example 8: click to run in command window: {stata "freeiv_examples 8 1":vce(svy)} | {stata "freeiv_examples 8 2":pweights}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 8 1, db":vce(svy)} | {stata "freeiv_examples 8 2, db":pweights}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 8, do":open as a do-file}){p_end}

{pstd}
The design has 31 strata and 62 primary units, hence 31 degrees of freedom and
t-based intervals; the standard error of the OLS slope is 0.050 under the
design against 0.047 for the sandwich of the second line, which ignores the
clustering.  And the diagnostics speak: the discriminant is negative beyond its
noise (z = -2.45), which no one-factor model can produce, and the J rejects
(9.5 for the profiled GMM; 8.5 for the joint one under {cmd:method(gmm)}).
Body-mass index and blood pressure in NHANES II do not fit this model.


{pstd}{bf:Example 9.} Inference for a route with no analytic standard
error{p_end}

{phang2}{stata "freeiv_examples 9, data":. use freeiv_card}{p_end}
{phang2}{cmd:. set seed 20261006}{p_end}
{phang2}{cmd:. bootstrap, reps(500): freeiv lwage exper expersq black south smsa (educ), method(lewbel12)}{p_end}
{p 8 8 2}{txt}(example 9: click to run in command window: {stata "freeiv_examples 9":the bootstrap of lewbel12}){p_end}
{p 8 8 2}{txt}(no dialog box: the dialog box of {cmd:freeiv} does not write the {cmd:bootstrap} prefix){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 9, do":open as a do-file}){p_end}


{pstd}{bf:Example 10.} The qme near the edge: the bootstrap against the delta
method{p_end}

{phang2}{stata "freeiv_examples 10, data":. use freeiv_sim1}{p_end}
{phang2}{cmd:. freeiv y1 x (y2)}{p_end}
{phang2}{cmd:. set seed 20261006}{p_end}
{phang2}{cmd:. bootstrap, reps(500): freeiv y1 x (y2)}{p_end}
{p 8 8 2}{txt}(example 10: click to run in command window: {stata "freeiv_examples 10 1":the delta method} | {stata "freeiv_examples 10 2":the bootstrap}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 10 1, db":the delta method}; the dialog box does not write the {cmd:bootstrap} prefix){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 10, do":open as a do-file}){p_end}

{pstd}
The z of D is 1.49 here, and the bootstrap standard error, 0.053, exceeds the
delta method's, 0.044: prefer the bootstrap when the z of D is below 2 --
but not near zero, where no standard error holds (see
{help freeiv##se:Standard errors}).


{pstd}{bf:Example 11.} Oster's answer depends on what is assumed: report a
range{p_end}

{phang2}{stata "freeiv_examples 11, data":. use freeiv_card}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ), method(oster) rmax(0.5)}{p_end}
{phang2}{cmd:. freeiv lwage exper expersq black south smsa (educ), method(oster) delta(2) rmax(0.8)}{p_end}
{p 8 8 2}{txt}(example 11: click to run in command window: {stata "freeiv_examples 11 1":rmax(0.5)} | {stata "freeiv_examples 11 2":delta(2) rmax(0.8)}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 11 1, db":rmax(0.5)} | {stata "freeiv_examples 11 2, db":delta(2) rmax(0.8)}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 11, do":open as a do-file}){p_end}

{pstd}
Both values, 0.098 and 0.190, lie above the OLS slope, 0.074, and so outside
the interval: under scale consistency proportional selection of that size is
not possible.


{pstd}{bf:Example 12.} Factor variables among the controls give what
hand-made terms give{p_end}

{phang2}{stata "freeiv_examples 12, data":. use freeiv_card}{p_end}
{phang2}{cmd:. freeiv lwage c.exper##c.exper i.black i.south i.smsa (educ), method(all)}{p_end}
{p 8 8 2}{txt}(example 12: click to run in command window: {stata "freeiv_examples 12":factor variables, method(all)}){p_end}
{p 8 8 2}{txt}(click to run in dialog box: {stata "freeiv_examples 12, db":factor variables, method(all)}){p_end}
{p 8 8 2}{txt}({stata "freeiv_examples 12, do":open as a do-file}){p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:freeiv} stores the following in {cmd:e()}; {cmd:ereturn list} shows them
all.  Model A:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(gamma)}, {cmd:e(se)}}the retained estimate and its standard error{p_end}
{synopt:{cmd:e(lo)}, {cmd:e(hi)}}the interval{p_end}
{synopt:{cmd:e(gt)}, {cmd:e(ols)}}the OLS slope gamma-tilde{p_end}
{synopt:{cmd:e(se_gt)}, {cmd:e(se_lo)}}standard errors of gamma-tilde and gamma-tilde/2{p_end}
{synopt:{cmd:e(qme)}, {cmd:e(se_qme)}}the qme (missing when D < 0){p_end}
{synopt:{cmd:e(vertex)}, {cmd:e(se_vertex)}}the vertex, retained when D < 0{p_end}
{synopt:{cmd:e(at_vertex)}}1 if the third-order quantities are read at the vertex{p_end}
{synopt:{cmd:e(hme)}, {cmd:e(se_hme)}}the hme{p_end}
{synopt:{cmd:e(disc)}, {cmd:e(disc_se)}, {cmd:e(disc_z)}}the discriminant D, its standard error and z{p_end}
{synopt:{cmd:e(root1)}, {cmd:e(root2)}, {cmd:e(nroots)}}the roots and how many lie inside the interval{p_end}
{synopt:{cmd:e(skew2)}}skewness of the first-stage residual{p_end}
{synopt:{cmd:e(theta)}, {cmd:e(sV2)}, {cmd:e(sV1)}}implied variances, at the qme or the vertex{p_end}
{synopt:{cmd:e(cshare)}}c = theta/(theta + sigma2_V2), likewise{p_end}
{synopt:{cmd:e(A)}, {cmd:e(B)}, {cmd:e(mu)}}A, B and A/(A + B), likewise{p_end}
{synopt:{cmd:e(g_gmm)}, {cmd:e(se_gmm)}}the joint GMM ({cmd:gmm} and {cmd:all}; missing otherwise){p_end}
{synopt:{cmd:e(J_gmm)}, {cmd:e(p_gmm)}}its J and p-value{p_end}
{synopt:{cmd:e(ar_lo)}, {cmd:e(ar_hi)}, {cmd:e(ar_frac)}}its region and the region's share of the interval{p_end}
{synopt:{cmd:e(gmm_bound)}, {cmd:e(gmm_weak)}}minimum on the boundary; theta below 0.05{p_end}
{synopt:{cmd:e(g_pgmm)}, {cmd:e(se_pgmm)}}the profiled GMM{p_end}
{synopt:{cmd:e(J_pgmm)}, {cmd:e(p_pgmm)}}its J and p-value{p_end}
{synopt:{cmd:e(idfac)}, {cmd:e(z_idfac)}}B kurt_U - A kurt_V2 and its z{p_end}
{synopt:{cmd:e(lsz)}, {cmd:e(se_lsz)}}LSZ ({cmd:lsz} and {cmd:all}; missing otherwise){p_end}
{synopt:{cmd:e(lsz_conv)}, {cmd:e(lsz_crit)}}its convergence and final criterion{p_end}
{synopt:{cmd:e(lewbel12)}, {cmd:e(copula)}}the comparison routes{p_end}
{synopt:{cmd:e(g_rank)}, {cmd:e(oster)}}idem{p_end}
{synopt:{cmd:e(N_pop)}}sum of the weights{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 24 28 2: Under vce(svy)}{p_end}
{synopt:{cmd:e(N_strata)}, {cmd:e(N_psu)}}number of strata and of primary units{p_end}
{synopt:{cmd:e(df_r)}}design degrees of freedom{p_end}
{synopt:{cmd:e(N_single)}}strata with a single primary unit{p_end}
{synopt:{cmd:e(fpc_dropped)}}1 if a first-stage fpc was dropped{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:freeiv}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(model)}}{cmd:A} or {cmd:B}{p_end}
{synopt:{cmd:e(method)}}the route{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(endog)}, {cmd:e(exog)}}the variables{p_end}
{synopt:{cmd:e(qme_flag)}}{cmd:vertex} when the vertex is retained{p_end}
{synopt:{cmd:e(wtype)}, {cmd:e(wexp)}}weight type and expression{p_end}
{synopt:{cmd:e(vce)}}{cmd:delta}, {cmd:robust} (pweights) or {cmd:linearized} ({cmd:vce(svy)}){p_end}
{synopt:{cmd:e(strata1)}, {cmd:e(su1)}, {cmd:e(fpc1)}}the design under {cmd:vce(svy)}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}the retained estimate and its variance; at a
boundary minimum of {cmd:method(gmm)}, {cmd:e(V)} still carries the
delta-method variance the display suppresses ({cmd:e(se)} missing), so that a
bootstrap draw on the boundary is kept{p_end}
{synopt:{cmd:e(moments)}}every moment and derived quantity, named{p_end}
{synopt:{cmd:e(Vmom)}, {cmd:e(grad)}}the covariance of the moments and the gradients, for {helpb freeivtest}{p_end}
{synopt:{cmd:e(lit)}, {cmd:e(pgmm)}, {cmd:e(gmm)}, {cmd:e(lszmat)}}the routes' own results{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}

{pstd}Model B adds{p_end}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(g2)}, {cmd:e(g3)}, {cmd:e(a1)}}the coefficients and the free loading{p_end}
{synopt:{cmd:e(se_g2)}, {cmd:e(se_g3)}, {cmd:e(se_a1)}}their standard errors{p_end}
{synopt:{cmd:e(a2)}, {cmd:e(a3)}, {cmd:e(mu3)}}the loadings and E[U^3]{p_end}
{synopt:{cmd:e(s2)}, {cmd:e(s3)}}the idiosyncratic variances{p_end}
{synopt:{cmd:e(sc)}}g2 a2 + g3 a3, what model A would call a1{p_end}
{synopt:{cmd:e(sc_d)}, {cmd:e(se_sc)}, {cmd:e(z_sc)}}the scale-consistency test{p_end}
{synopt:{cmd:e(of_d)}, {cmd:e(se_of)}, {cmd:e(z_of)}}the one-factor test, R1 - R3{p_end}
{synopt:{cmd:e(z_m223)}, {cmd:e(z_m233)}}the z of the two third-order cross-moments{p_end}
{synopt:{cmd:e(q_J)}, {cmd:e(q_pJ)}}the J of the sixteen-moment GMM, 4 df{p_end}
{synopt:{cmd:e(ivgap)}}what Y3 would return as an instrument for Y2{p_end}
{synopt:{cmd:e(t_rho)}}t of the correlation of the two indicators{p_end}
{synopt:{cmd:e(guard)}}0, or the guard that fired{p_end}
{p2colreset}{...}


{marker references}{...}
{title:Documentation}

{pstd}
{bf:freeiv_paper.pdf} presents the models, the command and worked examples at
article length.  It comes down with {cmd:net get freeiv}, next to the datasets,
and is kept at {browse "https://github.com/aabbdd12/freeiv"}.  To cite the
package, cite that paper: Araar, A. 2026.  freeiv: Instrument-free estimation of
a linear structural model with an endogenous regressor.  Zenodo,
doi:10.5281/zenodo.22770175.


{title:References}

{pstd}
The four papers of the series are cited by their concept DOI, which resolves to
the latest version.

{phang}
Andrews, D. W. K.  2000.  Inconsistency of the bootstrap when a parameter is on
the boundary of the parameter space.  {it:Econometrica} 68: 399-405.

{phang}
Andrews, D. W. K., and X. Cheng.  2012.  Estimation and inference with weak,
semi-strong, and strong identification.  {it:Econometrica} 80: 2153-2211.

{phang}
Araar, A. 2026a.  Correcting endogeneity without external instruments: Four
closed-form estimators for the linear structural model.  Zenodo,
doi:10.5281/zenodo.20312356.

{phang}
------. 2026b.  The quadratic moment estimator for instrument-free endogeneity
correction.  Zenodo, doi:10.5281/zenodo.22068003.

{phang}
------. 2026c.  Instrument-free estimation under linear scale-consistency:
Closed-form identification, partial bounds, and higher-moment GMM.  Zenodo,
doi:10.5281/zenodo.22119231.

{phang}
------. 2026d.  Two indicators of one latent confounder: Closed-form
identification of the triangular model with a free proxy effect.  Zenodo,
doi:10.5281/zenodo.22207331.

{phang}
Baum, C. F., and M. E. Schaffer.  2012.  ivreg2h: Stata module to perform
instrumental variables estimation using heteroskedasticity-based instruments.
Statistical Software Components S457555, Boston College Department of
Economics.

{phang}
Breitung, J., A. Mayer, and D. Wied.  2024.  Asymptotic properties of
endogeneity corrections using nonlinear transformations.
{it:Econometrics Journal} 27: 362-383.

{phang}
Card, D.  1995.  Using geographic variation in college proximity to estimate
the return to schooling.  In
{it:Aspects of Labour Market Behaviour: Essays in Honour of John Vanderkamp},
ed. L. N. Christofides, E. K. Grant, and
R. Swidinsky, 201-222.  Toronto: University of Toronto Press.  The extract
shipped as {cmd:freeiv_card.dta} comes from the datasets distributed with
Wooldridge's {it:Introductory Econometrics}.

{phang}
Lee, H., A. Lewbel, S. M. Schennach, and L. Zhang.  2026.  Instrument-free
estimation of triangular equation systems with the trigmm command.
{it:Stata Journal} 26: 68-89.

{phang}
Lewbel, A.  2012.  Using heteroscedasticity to identify and estimate
mismeasured and endogenous regressor models.
{it:Journal of Business and Economic Statistics} 30: 67-80.

{phang}
Lewbel, A., S. M. Schennach, and L. Zhang.  2024.  Identification of a
triangular two equation system without instruments.
{it:Journal of Business and Economic Statistics} 42: 14-25.

{phang}
Oster, E.  2013.  psacalc: Stata module to calculate treatment effects and
relative degree of selection under proportional selection of observables and
unobservables.  Statistical Software Components S457677, Boston College
Department of Economics.

{phang}
------.  2019.  Unobservable selection and coefficient stability: Theory and
evidence.  {it:Journal of Business and Economic Statistics} 37: 187-204.

{phang}
Park, S., and S. Gupta.  2012.  Handling endogenous regressors by joint
estimation using copulas.  {it:Marketing Science} 31: 567-586.


{title:Author}

{pstd}
Abdelkrim Araar, Universite Laval and PEP{break}
{browse "mailto:aabd@ecn.ulaval.ca":aabd@ecn.ulaval.ca}{p_end}
{pstd}Version 1.0.0.  Requires Stata 16 or later.  License: MIT.{p_end}


{title:Also see}

{psee}
Online: {helpb freeivmenu}, {helpb freeivdiag}, {helpb freeivtest},
{helpb freeivreport}, {helpb svyset}, {helpb ivregress}
{p_end}
