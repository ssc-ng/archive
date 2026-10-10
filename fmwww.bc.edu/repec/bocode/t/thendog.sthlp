{smcl}
{* *! version 1.0.0  07oct2026}{...}
{vieweralsosee "thivreg" "help thivreg"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "thsubci" "help thsubci"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thendog##syntax"}{...}
{viewerjumpto "Description" "thendog##description"}{...}
{viewerjumpto "Options" "thendog##options"}{...}
{viewerjumpto "Which command for which endogeneity" "thendog##which"}{...}
{viewerjumpto "How the correction works" "thendog##how"}{...}
{viewerjumpto "kappa is the endogeneity test" "thendog##kappa"}{...}
{viewerjumpto "The threshold estimate may be inconsistent" "thendog##consistency"}{...}
{viewerjumpto "Remarks" "thendog##remarks"}{...}
{viewerjumpto "Stored results" "thendog##results"}{...}
{viewerjumpto "Examples" "thendog##examples"}{...}
{viewerjumpto "References" "thendog##refs"}{...}
{viewerjumpto "Author" "thendog##author"}{...}

{title:Title}

{phang}
{bf:thendog} {hline 2} Structural threshold regression with an endogenous
threshold variable


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thendog} {depvar} [{it:varlist1}]
{cmd:(}[{it:varlist2}] {cmd:=} {it:varlist_iv}{cmd:)} {ifin}{cmd:,}
{opt thresh:var(varname)} [{it:options}]

{pstd}
{it:varlist1} are exogenous regressors, {it:varlist2} endogenous regressors
and {it:varlist_iv} the instruments. {it:varlist2} may be {bf:empty}: the
threshold variable is treated as endogenous here, so instruments are needed
even when every regressor is exogenous.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt thresh:var(varname)}}the threshold variable, treated as
{bf:endogenous}; required{p_end}
{synopt :{opt trim(#)}}quantile trimming of the threshold grid; default
{cmd:trim(0.15)}{p_end}
{synopt :{opt gridn(#)}}cap on grid points; {cmd:gridn(0)}, the default,
searches every distinct value{p_end}
{synopt :{opt mino:bs(#)}}minimum observations per regime{p_end}
{synopt :{opt nom:ills}}omit the inverse Mills terms {bf:(see below)}{p_end}
{synopt :{opt nodf:adj}}no small-sample adjustment in the variance{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{title:Description}

{pstd}
{cmd:thendog} fits a two-regime threshold regression in which the
{bf:threshold variable itself is endogenous}, following Kourtellos, Stengos
and Tan (2016). Endogenous regressors are handled at the same time.


{marker which}{title:Which command for which endogeneity}

{pstd}
The package has three threshold-regression commands and they are not
interchangeable. What differs is {it:what} is endogenous.

{p2colset 6 24 26 2}{...}
{p2col :{it:threshold}}{it:regressors}{space 6}{it:command}{p_end}
{p2col :exogenous}exogenous{space 7}{helpb thregress}{p_end}
{p2col :exogenous}{bf:ENDOGENOUS}{space 6}{helpb thivreg}{p_end}
{p2col :{bf:ENDOGENOUS}}either{space 10}{bf:thendog}{p_end}
{p2colreset}{...}

{pstd}
{bf:An endogenous threshold variable is a different problem from endogenous
regressors, and instrumenting the regressors does not touch it.} The trouble
is that the {bf:regime itself} becomes correlated with the error: which side
of the threshold an observation falls on carries information about its
disturbance. Each regime is then a {bf:selected sample}, and the conditional
mean inside a regime is not the regression function. Fitting such data with
{helpb thregress} or {helpb thivreg} gives biased slopes in both regimes, and
the bias does not shrink with the sample.

{pstd}
This is Heckman's selection problem, with one difference the paper is
explicit about. In a limited-dependent-variable model the latent variable is
unobserved and the split is observed. Here the {bf:split value is what we do
not know} and have to estimate.


{marker how}{title:How the correction works}

{pstd}
The model is

{p 8 8 2}
y(i) = b1'x(i) + u(i){space 6}if q(i) <= gamma{break}
y(i) = b2'x(i) + u(i){space 6}if q(i) >  gamma

{pstd}
with a {bf:selection equation} for the threshold variable,
q(i) = pi'z(i) + v(i). With (u, v) jointly normal, the truncated-normal mean
gives the expected error inside each regime:

{p 8 8 2}
E[u | z, q <= gamma] = kappa * lambda1,{space 3}lambda1 = -phi(a)/Phi(a){break}
E[u | z, q >  gamma] = kappa * lambda2,{space 3}lambda2 =  phi(a)/(1-Phi(a))

{pstd}
where a(i) = (gamma - z(i)'pi)/sigma_v. Adding those terms removes the
selection bias, and the estimating equations become

{p 8 8 2}
y(i) = b1'g(i) + kappa*lambda1(i) + e(i){space 3}in regime 1{break}
y(i) = b2'g(i) + kappa*lambda2(i) + e(i){space 3}in regime 2

{pstd}
with g(i) = E[x(i)|z(i)] the reduced-form fitted values. The threshold is
chosen by concentrated least squares over a grid.

{pstd}
{bf:There is ONE kappa, shared by both regimes.} That is not a simplification:
kappa is the covariance between the structural error and the selection error,
a single number, and the regimes differ only in which branch of the
truncation they sit on. Two separate kappas would be a different and
unidentified model. The posted coefficient vector therefore has 2k+1 entries,
not 2k+2.

{pstd}
{bf:Why the threshold still needs a grid.} The Mills ratios depend on gamma
at every observation, so nothing can be accumulated along a sorted walk the
way the exogenous-threshold profile can. Every candidate needs its own
regression. That is the price of the correction.


{marker kappa}{title:kappa is the endogeneity test}

{pstd}
Under an exogenous threshold kappa is zero, the Mills terms drop out, and the
model collapses to Caner-Hansen. So a t test on kappa-hat {bf:is} a test of
threshold exogeneity, and the command reports it.

{pstd}
{bf:If kappa is significant}, the threshold variable is endogenous and
{helpb thregress} or {helpb thivreg} would be biased on these data.

{pstd}
{bf:If kappa is not significant}, there is no evidence of threshold
endogeneity, and the simpler command is the better fit: it is more efficient,
and it does not spend a degree of freedom on a correction the data do not
support.

{pstd}
{cmd:nomills} fits the same model {it:without} the correction, which is the
honest way to see what the correction is doing to your estimates. Report both
if they differ materially.


{marker consistency}{title:The threshold estimate may be inconsistent, and the output says so}

{pstd}
{bf:Read this before quoting the threshold.} The correction above fixes the
{it:slopes}. It does {bf:not} make the threshold estimate consistent.
{help thendog##refs:Yu, Liao and Phillips (2024)}, section 2.2, prove that the
Kourtellos-Stengos-Tan estimator of {it:gamma} -- which is what this command
computes -- is {bf:inconsistent} unless

{p 8 8 2}
|{it:kappa}| / |{it:delta}|{space 2}<={space 2}0.587

{pstd}
where {it:delta} is the size of the regime difference. Worse, no value of
{it:kappa} makes it consistent for {it:every} {it:delta}: in their words, only
if {it:q} is exogenous is the KST estimator consistent for any
{it:delta} {c 185}= 0. And the bound is {bf:necessary, not sufficient} -- the
estimator may be inconsistent even below it.

{pstd}
So the case this command exists for -- an endogenous threshold variable -- is
exactly the case in which its threshold estimate may not converge to the truth.
Because that is too important to leave in a help file, {cmd:thendog} computes
the ratio from its own output and prints it against the bound, with a warning
when it is exceeded. {it:delta} is taken as the {bf:largest} absolute regime
difference across the coefficients, which is the most favourable reading: the
paper's bound is derived for a scalar jump, so with several coefficients there
is no single ratio the theorem speaks to, and if even the most favourable
choice fails the bound the warning is unambiguous.

{pstd}
{bf:What to do about it.} The slopes and the {it:kappa} test remain the useful
output; treat the threshold as indicative rather than estimated. If the
threshold itself is the quantity of interest, this estimator is not the right
tool for it, and Yu, Liao and Phillips propose control-function approaches built
for an endogenous threshold from the start.


{marker remarks}{title:Remarks}

{pstd}
{bf:Joint normality is assumed}, and the inverse Mills ratio is exactly where
it enters. The correction is a parametric one; if the errors are badly
non-normal the correction is misspecified, and a large kappa may be telling
you about that rather than about endogeneity.

{pstd}
{bf:The instruments do double duty} here: they instrument the endogenous
regressors {it:and} identify the selection equation for the threshold
variable. Weak instruments therefore hurt twice. The command refuses an
under-identified specification but cannot judge instrument strength for you;
check the first stage.

{pstd}
{bf:The small-threshold asymptotics.} The paper assumes the regime difference
and kappa both shrink with the sample. That assumption is what makes the bias
correction vanish when the model is in fact linear, so the procedure does not
manufacture an endogeneity correction for a model with only one regime.

{pstd}
{bf:Standard errors condition on the estimated threshold} and are
heteroskedasticity-robust. They do {bf:not} carry the first-stage estimation
error, so treat them as the usual two-step understatement. The paper's own
slope inference is GMM.

{pstd}
{bf:The threshold has no standard error.} Its limit distribution is
non-standard, as in every threshold model, and the paper recommends a
bootstrap interval. {helpb thsubci} offers a subsampling interval that needs
no limiting distribution, though it is written for the SETAR case.

{pstd}
{bf:When the selection equation fits too well}, the regime becomes nearly
deterministic given the instruments, Phi(a) underflows at every candidate and
the command stops with an explicit message rather than returning a threshold
decided by one exploded column.


{marker results}{title:Stored results}

{pstd}{cmd:thendog} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(gamma)}}the threshold estimate{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(sigma2)}}residual sum of squares and variance{p_end}
{synopt:{cmd:e(sigma_v)}}standard deviation of the selection equation{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}regime sizes{p_end}
{synopt:{cmd:e(ngrid)}, {cmd:e(npoints)}}grid points offered and usable{p_end}
{synopt:{cmd:e(trim)}, {cmd:e(level)}, {cmd:e(k_coef)}}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thendog}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}}{p_end}
{synopt:{cmd:e(endogvars)}, {cmd:e(exogvars)}, {cmd:e(insts)}}{p_end}
{synopt:{cmd:e(threshold_var)}}the endogenous threshold variable{p_end}
{synopt:{cmd:e(vcelab)}}description of the variance estimator{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients in equations {cmd:r1}, {cmd:r2}
and {cmd:mills}{p_end}
{synopt:{cmd:e(profile)}}the threshold grid and its sum of squares{p_end}
{synopt:{cmd:e(piq)}}the fitted selection equation{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}An endogenous threshold, all regressors exogenous{p_end}
{phang2}{cmd:. thendog y x1 x2 (= z1 z2), threshvar(q)}{p_end}

{pstd}An endogenous threshold {it:and} an endogenous regressor{p_end}
{phang2}{cmd:. thendog y x2 (x1 = z1 z2), threshvar(q)}{p_end}

{pstd}Reading the endogeneity test{p_end}
{phang2}{cmd:. thendog y x (= z1 z2), threshvar(q)}{p_end}
{phang2}{cmd:. display "kappa = " _b[mills:kappa] "  z = " _b[mills:kappa]/_se[mills:kappa]}{p_end}

{pstd}Seeing what the correction does, by switching it off{p_end}
{phang2}{cmd:. thendog y x (= z1 z2), threshvar(q)}{p_end}
{phang2}{cmd:. estimates store corrected}{p_end}
{phang2}{cmd:. thendog y x (= z1 z2), threshvar(q) nomills}{p_end}
{phang2}{cmd:. estimates store uncorrected}{p_end}
{phang2}{cmd:. estimates table corrected uncorrected, b se}{p_end}

{pstd}Against the exogenous-threshold fit on the same data{p_end}
{phang2}{cmd:. thregress y x, threshvar(q)}{p_end}
{phang2}{cmd:. thendog y x (= z1 z2), threshvar(q)}{p_end}

{pstd}Looking at the concentrated criterion{p_end}
{phang2}{cmd:. matrix P = e(profile)}{p_end}
{phang2}{cmd:. svmat double P, name(prof)}{p_end}
{phang2}{cmd:. twoway line prof2 prof1, xline(`=e(gamma)')}{p_end}


{marker refs}{title:References}

{phang}
Caner, M., and B. E. Hansen. 2004. Instrumental variable estimation of a
threshold model. {it:Econometric Theory} 20: 813-843.
{browse "https://doi.org/10.1017/S0266466604205011":doi:10.1017/S0266466604205011}

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}

{phang}
Heckman, J. J. 1979. Sample selection bias as a specification error.
{it:Econometrica} 47: 153-161.
{browse "https://doi.org/10.2307/1912352":doi:10.2307/1912352}

{phang}
Kourtellos, A., T. Stengos, and C. M. Tan. 2016. Structural threshold
regression. {it:Econometric Theory} 32: 827-860.
{browse "https://doi.org/10.1017/S0266466615000067":doi:10.1017/S0266466615000067}

{phang}
Yu, P., Q. Liao, and P. C. B. Phillips. 2024. New control function approaches in
threshold regression with endogeneity. {it:Econometric Theory} 40: 1065-1119.
{browse "https://doi.org/10.1017/S0266466623000014":doi:10.1017/S0266466623000014}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
