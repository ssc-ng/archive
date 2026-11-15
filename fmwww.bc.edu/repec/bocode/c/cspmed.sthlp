{smcl}
{* *! version 1.1.0  11nov2026}{...}
{vieweralsosee "xtpmed" "help xtpmed"}{...}
{vieweralsosee "tspmed" "help tspmed"}{...}
{vieweralsosee "[SVY] svyset" "help svyset"}{...}
{title:Title}

{phang}
{bf:cspmed} {hline 2} Causal mediation analysis for cross-sectional and complex-survey
data with one or more mediators: weighted OLS, logit, probit, 2SLS and DML, with
design-based (Taylor-linearised) inference and diagnostics


{title:Syntax}

{p 8 17 2}
{cmd:cspmed} {depvar} {ifin} [{it:pweight}]{cmd:,}
{opth treat:ment(varname)} {opth med:iators(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opth treat:ment(varname)}}treatment (binary or continuous){p_end}
{p2coldent:* {opth med:iators(varlist)}}one or more parallel mediators (continuous or 0/1){p_end}
{synopt:{opth cont:rols(varlist)}}confounders{p_end}
{synopt:{opt est:imator(name)}}{cmd:ols} (default), {cmd:logit}, {cmd:probit}, {cmd:iv}, {cmd:dml}{p_end}
{synopt:{opt inter:action}}treatment x mediator interactions in the outcome model{p_end}
{synopt:{opth ivs(varlist)}}excluded instruments for the treatment ({cmd:iv}){p_end}
{synopt:{opth medivs(varlist)}}excluded instruments for the mediators ({cmd:iv}){p_end}
{synopt:{opt lew:bel(which)}}Lewbel (2012) internal instruments for {cmd:mediators}, {cmd:treatment} or {cmd:both} ({cmd:iv}){p_end}
{synopt:{opth lewbelv:ars(varlist)}}heteroskedasticity drivers for {opt lewbel()}; default {opt controls()}{p_end}

{syntab:Survey design}
{synopt:{opt svy}}take weights, PSU and strata from {helpb svyset}{p_end}
{synopt:{opth cl:uster(varname)}}primary sampling units / clusters{p_end}
{synopt:{opth str:ata(varname)}}strata{p_end}

{syntab:Settings}
{synopt:{opt poly(#)}, {opt fold:s(#)}, {opt ridge(#)}}DML series degree, folds (formed by PSU) and ridge penalty{p_end}
{synopt:{opt gh:nodes(#)}}Gauss-Hermite nodes for continuous mediators with a binary outcome; default 15{p_end}
{synopt:{opt d1(#)}, {opt d0(#)}}treatment contrast; defaults 1 and 0{p_end}
{synopt:{opt boot:strap(#)}}PSU bootstrap within strata{p_end}
{synopt:{opt nodiag}}skip diagnostics{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* required.{p_end}


{title:Description}

{pstd}
{cmd:cspmed} fits one outcome model and one model per mediator and computes
counterfactual means mu(d, d') = E[Y(d, M(d'))] for every observation, averaged with
the sampling weights:

{p 8 12 2}NDE = mu(d1, d0) - mu(d0, d0),  NIE = mu(d1, d1) - mu(d1, d0),  TE = NDE + NIE,  PM = NIE/TE,{p_end}
{p 8 12 2}NIE_j = mu(d1; M_j(d1), other mediators at d0) - mu(d1, d0).{p_end}

{pstd}
With linear models and no interaction these reduce to the familiar products
a_j b_j (d1-d0).  With {cmd:logit} or {cmd:probit} the outcome is binary; 0/1
mediators get the same link and continuous mediators a Gaussian linear model, and
the counterfactual means are computed exactly (binary mediators) or by
Gauss-Hermite quadrature (continuous mediators), following Imai, Keele and
Tingley (2010) and VanderWeele (2015).

{pstd}
Standard errors use Taylor linearisation with strata and PSUs.  The linearised
influence function of each effect combines the parameter influence functions of all
equations with the variation from averaging predictions over the sample, so the
variance is design-based and accounts for the covariance between equations.

{p2colset 6 16 18 2}{...}
{p2col:{cmd:iv}}2SLS.  If the treatment is endogenous, the mediators are generally
endogenous in the outcome equation as well; supply {opt medivs()} or {opt lewbel()} to
identify NDE and NIE separately (TE does not need it).{p_end}
{p2col:{cmd:dml}}partially linear partialling-out with cross-fitting over PSUs and a
polynomial series learner in the controls.{p_end}
{p2colreset}{...}


{title:Lewbel instruments}

{pstd}
When no external instruments exist for an endogenous mediator (or treatment) v,
{opt lewbel()} regresses v on the constant and the controls, keeps the residual e_v, and
uses (Z - mean(Z)) x e_v as excluded instruments, where Z are the variables in
{opt lewbelvars()}.  Identification requires that the first-stage error of v is
heteroskedastic in Z while Z is uncorrelated with the product of the structural errors
(Lewbel 2012).  Check the Koenker/White tests on the mediator equations (heteroskedasticity
is needed), the first-stage F and Hansen's J.  External instruments, when given, take
precedence.  In simulations with an unobserved mediator-outcome confounder, Lewbel
instruments removed the bias in NDE and NIE (coverage 0.92-0.98), while OLS was biased.


{title:Diagnostics}

{pstd}
Linear equations: Koenker-Breusch-Pagan, White, Jarque-Bera, design-based RESET
and the largest variance inflation factor.  IV equations: first-stage F of the
excluded instruments for each endogenous regressor (design-based), Hansen J
overidentification test and a control-function endogeneity test.  Logit/probit
equations: McFadden pseudo-R2, Hosmer-Lemeshow test and link test.


{title:Examples}

{phang2}{cmd:. svyset psu [pw = wt], strata(stratum)}{p_end}
{phang2}{cmd:. cspmed income, treatment(educ) mediators(skills network) controls(age female rural) svy}{p_end}
{phang2}{cmd:. cspmed employed, treatment(training) mediators(cert) controls(age female) estimator(probit) svy}{p_end}
{phang2}{cmd:. cspmed income [pw = wt], treatment(educ) mediators(skills) controls(age) estimator(iv) ivs(distance) medivs(test_center) cluster(psu)}{p_end}
{phang2}{cmd:. cspmed income, treatment(educ) mediators(skills) controls(age female rural) estimator(dml) poly(3) svy seed(1)}{p_end}
{phang2}{cmd:. cspmed income, treatment(educ) mediators(skills) controls(age female rural) estimator(iv) lewbel(mediators) svy}{p_end}


{title:Stored results}

{pstd}
{cmd:e(b)}, {cmd:e(V)} (all equations, design-based joint variance), {cmd:e(effects)},
{cmd:e(V_eff)}, {cmd:e(diag)} (14 tests by stat, df1, df2, p for each equation),
{cmd:e(eff_boot)}; scalars {cmd:e(N)}, {cmd:e(N_psu)}, {cmd:e(N_strata)}, {cmd:e(km)};
macros {cmd:e(estimator)}, {cmd:e(mlinks)} (0 linear, 1 logit, 2 probit for each
mediator), {cmd:e(treatment)}, {cmd:e(mediators)}, {cmd:e(controls)}.


{title:References}

{phang}Binder, D. A. 1983. On the variances of asymptotically normal estimators from complex surveys. {it:International Statistical Review} 51: 279-292.{p_end}
{phang}Hosmer, D. W., and S. Lemeshow. 1980. Goodness of fit tests for the multiple logistic regression model. {it:Communications in Statistics - Theory and Methods} 9: 1043-1069.{p_end}
{phang}Lewbel, A. 2012. Using heteroscedasticity to identify and estimate mismeasured and endogenous regressor models. {it:Journal of Business and Economic Statistics} 30: 67-80.{p_end}
{phang}Imai, K., L. Keele, and D. Tingley. 2010. A general approach to causal mediation analysis. {it:Psychological Methods} 15: 309-334.{p_end}
{phang}VanderWeele, T. J. 2015. {it:Explanation in Causal Inference: Methods for Mediation and Interaction}. New York: Oxford University Press.{p_end}
{phang}Wooldridge, J. M. 2010. {it:Econometric Analysis of Cross Section and Panel Data}. 2nd ed. Cambridge, MA: MIT Press.{p_end}


{title:Author}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria{p_end}
