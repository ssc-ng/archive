{smcl}
{* *! version 1.0.0  25sep2026}{...}
{viewerjumpto "Syntax" "lillardhaz##syntax"}{...}
{viewerjumpto "Description" "lillardhaz##description"}{...}
{viewerjumpto "Options" "lillardhaz##options"}{...}
{viewerjumpto "The model" "lillardhaz##model"}{...}
{viewerjumpto "Stored results" "lillardhaz##stored"}{...}
{viewerjumpto "predict" "lillardhaz##predict"}{...}
{viewerjumpto "Examples" "lillardhaz##examples"}{...}
{viewerjumpto "Author" "lillardhaz##author"}{...}
{viewerjumpto "References" "lillardhaz##references"}{...}
{title:Title}

{phang}
{bf:lillardhaz} {hline 2} Simultaneous-equations hazard/probit models with a Gaussian-copula correlation (Lillard 1993)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:lillardhaz} {it:depvars} {ifin}{cmd:,}
{cmdab:eq1(}{it:type}{cmd:)}
{cmdab:eq2(}{it:type}{cmd:)}
[{it:options}]

{pstd}
{it:depvars} depends on {cmd:eq1()}:{p_end}
{p 8 8 2}if {cmd:eq1(probit)}: exactly 3 variables, {it:y1 time2 event2}{p_end}
{p 8 8 2}otherwise ({cmd:eq1(lognormal)} or {cmd:eq1(pgompertz)}): exactly 4 variables, {it:time1 event1 time2 event2}{p_end}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt eq1(type)}}model for equation 1: {cmd:probit}, {cmd:lognormal}, or {cmd:pgompertz}{p_end}
{synopt:{opt eq2(type)}}model for equation 2 (always a hazard): {cmd:lognormal} or {cmd:pgompertz}{p_end}

{syntab:Optional}
{synopt:{opt x1(varlist)}}covariates for equation 1's location index{p_end}
{synopt:{opt x2(varlist)}}covariates for equation 2's location index{p_end}
{synopt:{opt noc:orr}}fit the two equations independently (rho fixed at 0) instead of via the Gaussian copula{p_end}
{synopt:{opt nodes1(numlist)}}interior nodes (ascending) for equation 1's piecewise-Gompertz hazard; required if {cmd:eq1(pgompertz)}{p_end}
{synopt:{opt nodes2(numlist)}}interior nodes (ascending) for equation 2's piecewise-Gompertz hazard; required if {cmd:eq2(pgompertz)}{p_end}
{synopt:{opt tech:nique(algorithm)}}optimization technique passed to {helpb ml}; default is {cmd:bfgs}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:iterate(300)}{p_end}
{synopt:{opt lev:el(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt nol:og}}suppress the iteration log{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lillardhaz} fits a two-equation simultaneous model of the kind
introduced in Lillard (1993): a pair of processes -- each a binary
probit outcome or a continuous-time hazard duration -- linked through a
single correlation parameter {it:rho} between their underlying error
terms, estimated jointly by maximum likelihood via a Gaussian copula.
Equation 1 ({cmd:eq1()}) may be a probit, a log-normal hazard, or a
piecewise (linear-log-hazard) Gompertz hazard with an arbitrary number
of user-specified nodes; equation 2 ({cmd:eq2()}) is always a hazard,
log-normal or piecewise Gompertz. With {opt nocorr}, the two equations
are fit under the (testable) restriction {it:rho}=0, which -- as shown
in {help lillardhaz##model:The model} below -- reduces exactly to two
independent univariate fits.

{pstd}
{cmd:lillardhaz} is a from-scratch Stata implementation of the
simultaneous-equations hazard framework of Lillard (1993), built to
replace a family of widely-circulated {cmd:ml} programs (for the
various eq1 x eq2 combinations, with and without correlation) that used
an algebraically incorrect bivariate density in the correlated case;
see {help lillardhaz##model:The model} for the corrected joint
likelihood and its simulation-based verification.

{pstd}
A companion Python/R toolkit for the underlying (univariate)
split-population survival models is available at
{browse "https://github.com/nobifukuda/splitpopsurv":github.com/nobifukuda/splitpopsurv}.


{marker options}{...}
{title:Options}

{phang}
{opt eq1(type)} sets equation 1's model: {cmd:probit} (a binary
outcome, latent index N(0,1)), {cmd:lognormal} (an accelerated
failure-time log-normal hazard), or {cmd:pgompertz} (a piecewise
linear-in-time log-hazard, i.e. piecewise Gompertz, with nodes given by
{cmd:nodes1()}). Required.

{phang}
{opt eq2(type)} sets equation 2's model: {cmd:lognormal} or
{cmd:pgompertz}. Equation 2 is always a duration/hazard equation.
Required.

{phang}
{opt x1(varlist)} / {opt x2(varlist)} specify the covariates entering
each equation's location index. Either may be omitted for an
intercept-only equation.

{phang}
{opt nocorr} fits the two equations independently, fixing {it:rho}=0
and dropping the copula correlation parameter from the model. Useful
as a nested baseline for a likelihood-ratio test of {it:rho}=0 against
the correlated model.

{phang}
{opt nodes1(numlist)} / {opt nodes2(numlist)} give the interior time
nodes (ascending, e.g. {cmd:nodes1(3 7 12)}) at which the piecewise
Gompertz log-hazard's slope is allowed to change. {it:K} nodes define
{it:K}+1 segments. Required exactly when the corresponding equation is
{cmd:pgompertz}.

{phang}
{opt technique(algorithm)}, {opt iterate(#)}, {opt level(#)}, and
{opt nolog} are passed through to {helpb ml maximize}. The default
technique is {cmd:bfgs}, found in testing to converge substantially
more reliably than Newton-Raphson for these likelihoods.


{marker model}{...}
{title:The model}

{pstd}
For a hazard equation with location index {it:theta} = X{it:b}, log-normal
timing gives {it:z} = (log {it:t} {char 45} {it:theta}) / {it:sigma} ~
N(0,1), survival {it:S}(t) = 1 {char 45} Phi({it:z}), density {it:f}(t) =
phi({it:z})/({it:sigma t}). Piecewise Gompertz timing gives a log-hazard
that is continuous and piecewise linear in {it:t} across the
{cmd:nodes()}, with closed-form cumulative hazard by segment-wise
integration of an exponential (see the source comments in
{cmd:_lillardhaz_pgomp.ado} for the exact recursion); either way, a
copula residual {it:z} = Phi{superscript:-1}(1{char 45}{it:S}(t)) is
defined via the probability integral transform. For a probit equation,
the latent index {it:theta} = X{it:b} is itself already the copula
residual (its own error is already N(0,1)).

{pstd}
The two equations' copula residuals (z1, z2) [or (theta1, z2) if
equation 1 is a probit] are modeled as jointly bivariate normal with
correlation {it:rho}. The joint density (both events observed) is the
product of the two marginal densities times the bivariate-normal
density ratio phi2(z1,z2;{it:rho}) / (phi(z1) phi(z2)); a censored
observation contributes the corresponding bivariate-normal survival
probability, using the inclusion-exclusion identity P(Z1>z1,Z2>z2) =
Phi2({char 45}z1,{char 45}z2;{it:rho}). When {it:rho}=0 these formulas
collapse algebraically to the product of the two independent marginal
likelihoods -- Lillard's own identification result -- which is exactly
what {opt nocorr} fits, and this reduction was confirmed empirically
(see {browse "https://github.com/nobifukuda/lillardhaz-stata":the
repository}'s test suite): a {opt nocorr} fit with true {it:rho}=0
recovers coefficients matching Stata's own {helpb streg} univariate
fits to 5+ significant figures.

{pstd}
{cmd:atanh_rho} is estimated on the unrestricted (-infinity,infinity)
scale and back-transformed as {it:rho} = tanh({cmd:atanh_rho}), reported
after estimation and stored in {cmd:e(rho)}.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:lillardhaz} stores the following in {cmd:e()}, in addition to the
usual results from {helpb ml maximize}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lillardhaz}{p_end}
{synopt:{cmd:e(eq1type)}}the fitted {cmd:eq1()} choice{p_end}
{synopt:{cmd:e(eq2type)}}the fitted {cmd:eq2()} choice{p_end}
{synopt:{cmd:e(nodes1)} / {cmd:e(nodes2)}}the {cmd:nodes1()}/{cmd:nodes2()} used, if any{p_end}
{synopt:{cmd:e(predict)}}{cmd:lillardhaz_p}{p_end}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(corr)}}1 if fit with correlation, 0 if {cmd:nocorr}{p_end}
{synopt:{cmd:e(rho)}}estimated copula correlation (only if {cmd:e(corr)}==1){p_end}
{synopt:{cmd:e(rho_se)}}delta-method standard error of {cmd:e(rho)}{p_end}


{marker predict}{...}
{title:predict}

{p 8 17 2}
{cmd:predict} [{it:type}] {it:newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt su:rv2}}predicted S2(t), evaluated at each observation's own equation-2 duration; the default{p_end}
{synopt:{opt su:rv1}}predicted S1(t) (equation 1 only, and only if equation 1 is a hazard type){p_end}
{synopt:{opt d:ens2}}predicted f2(t){p_end}
{synopt:{opt d:ens1}}predicted f1(t) (equation 1 only, hazard types){p_end}
{synopt:{opt pr1}}predicted Pr(y1=1) (equation 1 only, and only if {cmd:eq1(probit)}){p_end}
{synopt:{opt xb1}}the fitted equation-1 linear index{p_end}
{synopt:{opt xb2}}the fitted equation-2 linear index{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}Probit & log-normal hazard, correlated{p_end}
{phang2}{cmd:. lillardhaz y1 time2 event2, eq1(probit) eq2(lognormal) x1(x1) x2(x2)}{p_end}

{pstd}Log-normal hazard & log-normal hazard, correlated{p_end}
{phang2}{cmd:. lillardhaz time1 event1 time2 event2, eq1(lognormal) eq2(lognormal) x1(x1) x2(x2)}{p_end}

{pstd}Piecewise Gompertz & piecewise Gompertz, correlated, two interior nodes each{p_end}
{phang2}{cmd:. lillardhaz time1 event1 time2 event2, eq1(pgompertz) eq2(pgompertz) x1(x1) x2(x2) nodes1(5) nodes2(4)}{p_end}

{pstd}Same, but independent (nested test of rho=0){p_end}
{phang2}{cmd:. lillardhaz time1 event1 time2 event2, eq1(pgompertz) eq2(pgompertz) x1(x1) x2(x2) nodes1(5) nodes2(4) nocorr}{p_end}

{pstd}Predicted survival, density, and linear indices{p_end}
{phang2}{cmd:. predict S2_hat}{p_end}
{phang2}{cmd:. predict f2_hat, dens2}{p_end}
{phang2}{cmd:. predict xb1_hat, xb1}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Nobutaka Fukuda, Tohoku University{break}
{browse "mailto:nobutaka.fukuda@tohoku.ac.jp":nobutaka.fukuda@tohoku.ac.jp}


{marker references}{...}
{title:References}

{phang}
Lillard, L. A. 1993. Simultaneous equations for hazards: Marriage
duration and fertility timing. {it:Journal of Econometrics} 56(1{char 45}2):
189{char 45}217.

{phang}
Waite, L. J., and L. A. Lillard. 1991. Children and marital disruption.
{it:American Journal of Sociology} 96(4): 930{char 45}953.
