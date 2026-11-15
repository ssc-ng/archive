{smcl}
{* *! version 2.1.0  10nov2026}{...}
{vieweralsosee "[CAUSAL] mediate" "help mediate"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpmed##syntax"}{...}
{viewerjumpto "Description" "xtpmed##description"}{...}
{viewerjumpto "Estimators" "xtpmed##estimators"}{...}
{viewerjumpto "Effects" "xtpmed##effects"}{...}
{viewerjumpto "Diagnostics" "xtpmed##diagnostics"}{...}
{viewerjumpto "Options" "xtpmed##options"}{...}
{viewerjumpto "Examples" "xtpmed##examples"}{...}
{viewerjumpto "Stored results" "xtpmed##results"}{...}
{viewerjumpto "References" "xtpmed##references"}{...}
{title:Title}

{phang}
{bf:xtpmed} {hline 2} Causal mediation analysis for balanced or unbalanced panel
data with one or more mediators, nine panel estimators, joint cross-equation
inference and built-in residual diagnostics


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpmed} {depvar} {ifin}{cmd:,}
{opth treat:ment(varname)} {opth med:iators(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opth treat:ment(varname)}}treatment (binary, multivalued or continuous){p_end}
{p2coldent:* {opth med:iators(varlist)}}one or more parallel mediators{p_end}
{synopt:{opth cont:rols(varlist)}}time-varying controls{p_end}
{synopt:{opt est:imator(name)}}{cmd:dml} (default), {cmd:fe}, {cmd:re}, {cmd:dfe}, {cmd:mg}, {cmd:pmg}, {cmd:ccep}, {cmd:ccemg}, {cmd:csardl}{p_end}
{synopt:{opt time:fe}}add period fixed effects ({cmd:fe}, {cmd:re}, {cmd:dfe}){p_end}

{syntab:Standard errors}
{synopt:{opt vce(cluster|dk)}}cluster by panel (default) or Driscoll-Kraay{p_end}
{synopt:{opt dkl:ag(#)}}Driscoll-Kraay lag truncation; default floor(4(T/100)^(2/9)){p_end}
{synopt:{opt boot:strap(#)}}unit (block) bootstrap of the effects with {it:#} replications{p_end}
{synopt:{opt nodots}}suppress bootstrap dots{p_end}

{syntab:DML only}
{synopt:{opt lag:s(#)}}lags of treatment and mediators; default {cmd:1}{p_end}
{synopt:{opt ivl:ags(#)}}lags of residualized instruments; default {cmd:3}{p_end}
{synopt:{opt poly(#)}}degree of the series learner (1-3); default {cmd:2}{p_end}
{synopt:{opt ridge(#)}}ridge penalty in the treatment learner{p_end}
{synopt:{opt fold:s(#)}}cross-fitting folds (>= 3); default {cmd:5}{p_end}
{synopt:{opt rep:eat(#)}}repeated sample splits, median aggregation{p_end}
{synopt:{opt dsq}}add the squared treatment{p_end}
{synopt:{opt one:step}}one-step GMM{p_end}
{synopt:{opt nocol:lapse}}period-specific instruments{p_end}

{syntab:Effects and diagnostics}
{synopt:{opt d1(#)}, {opt d0(#)}}treatment contrast; defaults 1 and 0{p_end}
{synopt:{opt break(#)}}break date for the Chow-type stability test; default mid-sample{p_end}
{synopt:{opt nodiag}}skip the residual diagnostics{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* required. The data must be {helpb xtset}. Gaps and unequal panel lengths are allowed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpmed} estimates a system of one outcome equation and one equation per
mediator,

{p 8 8 2}M_j = a_j D + controls + unit/period effects + e_j,   j = 1,...,k{p_end}
{p 8 8 2}Y = c D + b_1 M_1 + ... + b_k M_k + controls + unit/period effects + e_Y{p_end}

{pstd}
with the panel estimator of your choice, and reports natural direct, indirect and
total effects with standard errors from the {it:joint} variance of all equations.
Every estimator is written as a sum of influence-function contributions per
unit and period. Stacking these across equations gives the cross-equation
covariance needed for the indirect effect, under clustering by panel or
Driscoll-Kraay (cross-sectional and serial dependence).

{pstd}
Unbalanced panels are placed on a rectangular unit-by-period grid. Lags and
differences respect gaps, period and cross-section averages use the available
units, and mean-group estimators use each unit's own sample.


{marker estimators}{...}
{title:Estimators}

{p2colset 6 18 20 2}{...}
{p2col:{cmd:dml}}Double/debiased machine-learning GMM of Wu and Xiao (2026):
two-way fixed effects, sequentially exogenous treatment, nonlinear confounding
learned by cross-fitted series regressions, lag dynamics.  Effects are
{it:sustained} (treatment held at the new level) and {it:impact} effects.{p_end}
{p2col:{cmd:fe}}Within estimator (optionally two-way with {cmd:timefe}).{p_end}
{p2col:{cmd:re}}Random-effects GLS with Swamy-Arora-type variance components (unbalanced-panel version).{p_end}
{p2col:{cmd:dfe}}Dynamic fixed effects, ARDL(1,1) in error-correction form; long-run coefficients.{p_end}
{p2col:{cmd:mg}}Pesaran-Smith mean group of unit ARDL(1,1)-ECM regressions; long-run coefficients.{p_end}
{p2col:{cmd:pmg}}Pooled mean group (Pesaran, Shin and Smith 1999): common long-run
coefficients by maximum likelihood (back-substitution algorithm), heterogeneous
short-run dynamics and speed of adjustment.{p_end}
{p2col:{cmd:ccep}}Common correlated effects pooled (Pesaran 2006): unit-specific
projection on cross-section averages of all variables.{p_end}
{p2col:{cmd:ccemg}}Common correlated effects mean group.{p_end}
{p2col:{cmd:csardl}}Cross-sectionally augmented ARDL(1,1) mean group (Chudik
and Pesaran 2015; Chudik et al. 2016) with floor(T^(1/3)) lags of the
cross-section averages; long-run coefficients.{p_end}
{p2colreset}{...}

{pstd}
For the error-correction estimators ({cmd:dfe}, {cmd:mg}, {cmd:pmg},
{cmd:csardl}) the reported coefficients and the mediation effects are
long-run, and {cmd:ec} is the (average) speed of adjustment.  For mean-group
estimators the variance is the mean-group variance across units; {cmd:vce(dk)}
is not available for them.  Dynamic estimators need moderately long panels: the
usual O(1/T) small-T bias applies.  CS-ARDL in particular is recommended for
T of roughly 50 or more.


{marker effects}{...}
{title:Effects}

{pstd}
For a change in the treatment from {it:d0} to {it:d1} (delta = d1 - d0):

{p 8 12 2}NIE_j = a_j b_j delta (indirect effect through mediator j),{p_end}
{p 8 12 2}NIE = sum_j NIE_j,  NDE = c delta,  TE = NDE + NIE,  PM = NIE/TE.{p_end}

{pstd}
Mediators are treated as parallel (no mediator causes another).  With
{cmd:dml}, sums of lag coefficients replace a_j, b_j and c, and impact
(same-period) effects are also reported.  Standard errors come from the delta
method applied to the joint covariance of all equations, or from a unit
bootstrap that re-estimates the whole system.


{marker diagnostics}{...}
{title:Diagnostics}

{pstd}
Unless {opt nodiag} is given, the following tests are reported for the residuals
of every equation and stored in {cmd:e(diag)}:

{p 6 10 2}{bf:Serial correlation}: Wooldridge (2002) test (level-residual estimators);
Arellano-Bond (1991) AR(1) and AR(2) statistics for the first-differenced DML
residuals, including the correction for the estimated coefficients (computed from the
influence functions; in simulations the corrected AR(2) test had size 3% at the 5% level,
against 7% uncorrected).{p_end}
{p 6 10 2}{bf:Heteroskedasticity}: Brown-Forsythe/Levene test of equal error variance
across panels; modified Wald test (Greene 2000), which over-rejects in short panels;
Koenker's studentized Breusch-Pagan test on the equation's regressors.{p_end}
{p 6 10 2}{bf:Cross-sectional dependence}: Pesaran (2004, 2015) CD test (unbalanced
version), the Juodis-Reese (2022) weighted CDw test, the Pesaran (2004) scaled LM
test with the Baltagi, Feng and Kao (2012) bias correction (powerful when factor
loadings average zero), and the mean absolute pairwise correlation.{p_end}
{p 6 10 2}{bf:Normality}: Jarque-Bera test, skewness and kurtosis.{p_end}
{p 6 10 2}{bf:Stability}: Chow-type parameter-constancy test (the model is re-estimated
before and after {opt break()}, Wald test of equal key coefficients, per
equation and jointly); Pesaran-Yamagata (2008) slope-homogeneity tests (delta
and adjusted delta, static FE version), which indicate whether pooled or
mean-group estimators are appropriate; for error-correction models, the
speed-of-adjustment coefficient (should lie in (-2, 0)).{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt vce(dk)} computes Driscoll-Kraay standard errors by summing the stacked
influence contributions over units within each period and applying Newey-West
weights.  They require reasonably long T.

{phang}
{opt bootstrap(#)} resamples whole units with replacement and re-estimates all
equations (including cross-fitting for {cmd:dml}).  Effects then use bootstrap
standard errors and percentile intervals.

{phang}
{opt break(#)} is a value of the time variable.  The Chow-type test is reported as
n/a when either subsample is too short for the chosen estimator.

{phang}
For the DML options, see the description in Wu and Xiao (2026) and {cmd:help xtdmlmed}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtpmed gdpg, treatment(fd) mediators(inv hc) controls(trade infl) seed(1)}{p_end}
{phang2}{cmd:. xtpmed gdpg, treatment(fd) mediators(inv hc) controls(trade infl) estimator(fe) timefe vce(dk)}{p_end}
{phang2}{cmd:. xtpmed gdpg, treatment(fd) mediators(inv hc) controls(trade infl) estimator(re)}{p_end}
{phang2}{cmd:. xtpmed gdpg, treatment(fd) mediators(inv hc) estimator(pmg) break(2010)}{p_end}
{phang2}{cmd:. xtpmed gdpg, treatment(fd) mediators(inv hc) estimator(csardl) bootstrap(199) seed(1)}{p_end}
{phang2}{cmd:. matrix list e(effects)}{p_end}
{phang2}{cmd:. matrix list e(diag)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(N_g)}, {cmd:e(T)}}observations, panels, grid periods{p_end}
{synopt:{cmd:e(km)}}number of mediators{p_end}
{synopt:{cmd:e(d1)}, {cmd:e(d0)}}treatment contrast{p_end}
{synopt:{cmd:e(J)}, {cmd:e(J_df)}, {cmd:e(J_p)}}Hansen J ({cmd:dml}){p_end}
{synopt:{cmd:e(dklag)}, {cmd:e(break_t)}}DK lag; break date{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(estimator)}, {cmd:e(vce)}, {cmd:e(treatment)}, {cmd:e(mediators)}, {cmd:e(controls)}}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients of all equations and their joint variance{p_end}
{synopt:{cmd:e(effects)}}effects table (b, se, z, p, ll, ul){p_end}
{synopt:{cmd:e(b_eff)}, {cmd:e(V_eff)}}effects and their covariance{p_end}
{synopt:{cmd:e(diag)}}16 tests x (stat, df1, df2, p) for each equation{p_end}
{synopt:{cmd:e(chow)}}joint Chow-type test (stat, df, p){p_end}
{synopt:{cmd:e(eff_boot)}}bootstrap draws of the effects{p_end}


{marker references}{...}
{title:References}

{phang}Arellano, M., and S. Bond. 1991. Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations. {it:Review of Economic Studies} 58: 277-297.{p_end}
{phang}Baltagi, B. H., Q. Feng, and C. Kao. 2012. A Lagrange multiplier test for cross-sectional dependence in a fixed effects panel data model. {it:Journal of Econometrics} 170: 164-177.{p_end}
{phang}Brown, M. B., and A. B. Forsythe. 1974. Robust tests for the equality of variances. {it:Journal of the American Statistical Association} 69: 364-367.{p_end}
{phang}Chudik, A., and M. H. Pesaran. 2015. Common correlated effects estimation of heterogeneous dynamic panel data models with weakly exogenous regressors. {it:Journal of Econometrics} 188: 393-420.{p_end}
{phang}Chudik, A., K. Mohaddes, M. H. Pesaran, and M. Raissi. 2016. Long-run effects in large heterogeneous panel data models with cross-sectionally correlated errors. {it:Advances in Econometrics} 36: 85-135.{p_end}
{phang}Driscoll, J. C., and A. C. Kraay. 1998. Consistent covariance matrix estimation with spatially dependent panel data. {it:Review of Economics and Statistics} 80: 549-560.{p_end}
{phang}Juodis, A., and S. Reese. 2022. The incidental parameters problem in testing for remaining cross-section correlation. {it:Journal of Business and Economic Statistics} 40: 1191-1203.{p_end}
{phang}Koenker, R. 1981. A note on studentizing a test for heteroscedasticity. {it:Journal of Econometrics} 17: 107-112.{p_end}
{phang}Pesaran, M. H. 2004. General diagnostic tests for cross section dependence in panels. CESifo Working Paper 1229.{p_end}
{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}
{phang}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels. {it:Econometric Reviews} 34: 1089-1117.{p_end}
{phang}Pesaran, M. H., Y. Shin, and R. P. Smith. 1999. Pooled mean group estimation of dynamic heterogeneous panels. {it:Journal of the American Statistical Association} 94: 621-634.{p_end}
{phang}Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships from dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.{p_end}
{phang}Pesaran, M. H., and T. Yamagata. 2008. Testing slope homogeneity in large panels. {it:Journal of Econometrics} 142: 50-93.{p_end}
{phang}Wooldridge, J. M. 2002. {it:Econometric Analysis of Cross Section and Panel Data}. Cambridge, MA: MIT Press.{p_end}
{phang}Wu, P., and Z. Xiao. 2026. Causal mediation analysis for panel data with double/debiased machine learning. arXiv:2610.21339.{p_end}


{title:Author}

{pstd}
Yusuf Toyin Yusuf{break}
Department of Economics and Development Studies{break}
Kwara State University, Malete, Nigeria{p_end}
