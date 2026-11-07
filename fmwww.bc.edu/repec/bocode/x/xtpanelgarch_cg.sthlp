{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch pretest" "help xtpanelgarch_pretest"}{...}
{vieweralsosee "xtpanelgarch vt" "help xtpanelgarch_vt"}{...}
{vieweralsosee "xtpanelgarch postestimation" "help xtpanelgarch_postestimation"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods"}{...}
{viewerjumpto "Syntax" "xtpanelgarch_cg##syntax"}{...}
{viewerjumpto "Description" "xtpanelgarch_cg##description"}{...}
{viewerjumpto "Options" "xtpanelgarch_cg##options"}{...}
{viewerjumpto "Interpreting the output" "xtpanelgarch_cg##output"}{...}
{viewerjumpto "Remarks" "xtpanelgarch_cg##remarks"}{...}
{viewerjumpto "Examples" "xtpanelgarch_cg##examples"}{...}
{viewerjumpto "Stored results" "xtpanelgarch_cg##results"}{...}
{viewerjumpto "Author" "xtpanelgarch_cg##author"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch cg} {hline 2} Cermeño-Grier panel GARCH and DPD-CCV models by maximum likelihood


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch cg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt arch(#)}}ARCH order q; default {cmd:arch(1)}{p_end}
{synopt:{opt garch(#)}}GARCH order p; default {cmd:garch(0)}{p_end}
{synopt:{opt mod:el(A|B|C|D)}}CG (2001) model: A pooled, B fixed effects in mean, C in variance, D in both{p_end}
{synopt:{opt mean:fe}}individual effects mu_i in the mean equation{p_end}
{synopt:{opt var:fe}}individual effects alpha_i in the variance equation{p_end}
{synopt:{opth het(varlist)}}exogenous regressors in the variance equation (CG 2001 eq. 9){p_end}
{synopt:{opt archm}}conditional standard deviation in the mean (GARCH-M; CG 2006 eq. 10.9a){p_end}
{synopt:{opt archmt:ype(sd|var|logvar)}}form of the in-mean term; default {cmd:sd}{p_end}
{synopt:{opt tarch}}GJR (1993) asymmetry term lambda u{c 94}2_i,t-1 1(u_i,t-1 < 0){p_end}
{synopt:{opt egarch}}EGARCH variance of Nelson (1991) in logs{p_end}
{synopt:{opt cov(none|common|pair|ccc)}}cross-sectional covariance model; default {cmd:none}{p_end}
{synopt:{opt dist:ribution(normal|t)}}conditional distribution; default {cmd:normal}{p_end}

{syntab:SE / maximisation}
{synopt:{opt vce(oim|opg|robust)}}{cmd:oim} (default), {cmd:opg}, or Bollerslev-Wooldridge {cmd:robust}{p_end}
{synopt:{opt tech:nique(string)}}{helpb mf_optimize##i_technique:optimize} technique; default {cmd:nr} for {cmd:cov(none)}, {cmd:bfgs} for covariance models (with automatic fallback to {cmd:nr} and {cmd:bhhh}){p_end}
{synopt:{opt starts(#)}}number of screened starting values; default {cmd:starts(10)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default 300{p_end}
{synopt:{opt from(matname)}}starting values (row vector in the order of {cmd:e(b)}){p_end}
{synopt:{opt nolog}}suppress the iteration log{p_end}
{synopt:{opt notable}}suppress the coefficient table{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpanelgarch cg} fits the panel GARCH model of Cermeño and Grier (2001, 2006):

{p 8 8 2}
mean: y_it = mu_i + x_it'beta + kappa g(sigma2_it) + u_it{break}
variance: sigma2_it = alpha_i + sum_l gamma_l u{c 94}2_i,t-l + sum_l delta_l sigma2_i,t-l [+ lambda u{c 94}2_i,t-1 1(u<0)] [+ z_it'theta]{break}
covariance: sigma_ij,t = eta_ij + rho u_i,t-1 u_j,t-1 + lambda_c sigma_ij,t-1

{pstd}
Lags of the dependent variable enter through {it:indepvars} (for example {cmd:L(1/12).y}), so the
dynamic panel data (DPD) mean of CG (2006) eq. (10.1) is covered. With {cmd:cov(none)} the units are
conditionally independent and the log likelihood is CG (2001) eq. (7) = CG (2006) eq. (10.8).
With {cmd:cov()} the full multivariate normal likelihood CG (2006) eq. (10.7) is maximised, with
Omega_t built from the variance and covariance recursions:

{p2colset 9 26 28 2}{...}
{p2col:{cmd:cov(common)}}eta_ij = eta: CG (2006) Model 2{p_end}
{p2col:{cmd:cov(pair)}}pair-specific eta_ij: CG (2006) Model 3; Lee (2010); Apostolakis et al. (2025){p_end}
{p2col:{cmd:cov(ccc)}}sigma_ij,t = r_ij sigma_i,t sigma_j,t: constant conditional correlation (Bollerslev 1990; Cermeño-Sanin 2015){p_end}


{marker options}{...}
{title:Options}

{phang}{opt model(A|B|C|D)} reproduces the four CG (2001, sec. 4) cases. {cmd:meanfe} and {cmd:varfe} are the
explicit equivalents; {cmd:model()} overrides them.{p_end}

{phang}{opt het(varlist)} adds regressors to every unit's variance equation: lagged inflation for the
Friedman-Ball hypothesis (CG 2006 eq. 10.10a), exchange-rate regime dummies (Cermeño-Sanin 2015 eq. 8),
or geopolitical risk (Apostolakis et al. 2025). Positivity of sigma2_it is enforced during estimation.{p_end}

{phang}{opt archm} adds kappa sigma_it to the mean (CG 2006 Model 4; Lee 2010). {cmd:archmtype(var)} uses
sigma2_it (as Stata's {helpb arch} with {cmd:archm}); {cmd:archmtype(logvar)} uses ln sigma2_it.{p_end}

{phang}{opt tarch} follows Glosten, Jagannathan and Runkle (1993): the indicator is 1(u<0), so a positive
lambda means that bad news raises volatility more. Stata's {helpb arch}'s {cmd:tarch()} uses 1(u>0). The
two are reparameterisations: gamma(ours) = gamma(arch) + lambda(arch), and lambda(ours) = -lambda(arch).{p_end}

{phang}{opt egarch} replaces the variance equation by Nelson's (1991) exponential GARCH:
ln sigma2_it = alpha_i + sum_l [theta_l z_i,t-l + gamma_l (|z_i,t-l| - sqrt(2/pi))] + sum_l delta_l ln sigma2_i,t-l,
with z = u/sigma. Coefficients are named {cmd:L#.earch} (theta, sign), {cmd:L#.earch_a} (gamma, size) and {cmd:L#.egarch} (delta),
as in Stata's {helpb arch}. Positivity holds by construction; persistence is sum(delta).{p_end}

{phang}{opt starts(#)} draws a grid of starting values for the variance dynamics. It keeps the # best
by likelihood, runs 25 BFGS iterations from each, and fully optimises from the best. Panel GARCH
likelihoods are often multimodal (CG 2001 note that their GAUSS optimiser did not always converge), so
the default is 10. {cmd:starts(0)} uses the OLS/LSDV-based start only.{p_end}

{phang}{opt vce()}: {cmd:oim} is the negative inverse Hessian (CG 2006, p. 264); {cmd:opg} is the
outer product of gradients (CG 2001, fn. 4). {cmd:robust} is the Bollerslev-Wooldridge (1992)
QML sandwich, valid when the conditional distribution is not normal. Scores are period-t contributions,
so the robust and OPG estimators allow arbitrary cross-sectional correlation of the scores.{p_end}


{marker output}{...}
{title:Interpreting the output}

{phang}{bf:mean} block: mu (or mu_i, one per panel) and beta. Lags of {it:depvar} appear under their
operator names.{p_end}
{phang}{bf:ARCHM}: kappa. A positive, significant kappa supports Cukierman-Meltzer (uncertainty raises the
mean); CG (2006) find kappa < 0 for G7 inflation (a stabilisation motive).{p_end}
{phang}{bf:variance} block: alpha (or alpha_i), L#.arch = gamma_l, L#.garch = delta_l, L1.tarch =
lambda, and the {cmd:het()} coefficients theta.{p_end}
{phang}{bf:covariance} block: eta (or eta_ij), L1.uu = rho, L1.cov = lambda_c; with {cmd:cov(ccc)} the
{bf:correlation} block holds r_ij.{p_end}
{phang}{bf:Volatility dynamics}: variance persistence sum(gamma)+sum(delta) (+ lambda/2 with {cmd:tarch}),
with a z test of H0: persistence = 1 and the half-life ln(0.5)/ln(persistence). For covariance models:
covariance persistence rho+lambda_c, and the smallest eigenvalue of Omega_t over the sample. Asai (2023)
proves that the CG specification need not be positive definite, so this is reported every time.{p_end}


{marker remarks}{...}
{title:Remarks / practical guidance}

{pstd}
{bf:Sample regime.} The asymptotics are N fixed and T to infinity (CG 2006, p. 264). {cmd:cov(pair)}
has N(N-1)/2 covariance intercepts, so keep N small (CG use N = 7). For larger N use {cmd:cov(none)},
{helpb xtpanelgarch_vt:vt} or {helpb xtpanelgarch_cl:cl}.{p_end}

{pstd}
{bf:Panel shape.} The panel must be balanced, without gaps, on a common time span. The recursion runs
on Omega_t, an N x N matrix at each t.{p_end}

{pstd}
{bf:Pre-sample values.} sigma2_i0 = u{c 94}2_i0 = T{c 94}-1 sum_t e{c 94}2_it, and sigma_ij,0 =
T{c 94}-1 sum_t e_it e_jt. These use the mean residuals at the current parameters, as {helpb arch}'s default
{cmd:arch0(xb)} does. With N = 1 and no in-mean term, {cmd:cg} reproduces {helpb arch} to the last digit
(see {cmd:xtpanelgarch_example.do}).{p_end}

{pstd}
{bf:Model choice.} CG (2006, p. 270) stress that the pre-test strategy is informal ({helpb xtpanelgarch_pretest}).
Estimate the candidate models, compare them by {helpb lrtest} or {cmd:estat ic}, and confirm with
{cmd:estat diagnostics} that no ARCH remains in the squared standardised residuals.{p_end}

{pstd}
{bf:Validation.} With the CG (2006) Model-3 restrictions imposed as constraints, {helpb mgarch dvech}
gives the same likelihood and estimates as {cmd:cg, cov(pair) model(D)}. The test file reproduces this.{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. keep if inlist(company, 1, 2, 3, 4, 8)}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtpanelgarch cg invest mvalue kstock, arch(1) model(A)}{p_end}
{phang2}{cmd:. estimates store A}{p_end}
{phang2}{cmd:. xtpanelgarch cg invest mvalue kstock, arch(1) model(D)}{p_end}
{phang2}{cmd:. lrtest A .}{p_end}

{pstd}GARCH-M with lagged inflation in the variance (CG 2006 Model 4){p_end}
{phang2}{cmd:. xtpanelgarch cg infl L(1/12).infl, arch(1) garch(1) varfe cov(pair) archm het(L.infl)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpanelgarch cg} stores the following in {cmd:e()}:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(T)}}time periods{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(k)}, {cmd:e(rank)}}number of parameters{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}}information criteria{p_end}
{synopt:{cmd:e(arch)}, {cmd:e(garch)}}orders{p_end}
{synopt:{cmd:e(minpd)}}smallest eigenvalue of Omega_t (covariance models){p_end}
{synopt:{cmd:e(converged)}, {cmd:e(iterations)}}convergence information{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpanelgarch}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:cg}{p_end}
{synopt:{cmd:e(model)}}A, B, C or D{p_end}
{synopt:{cmd:e(cov)}}covariance model{p_end}
{synopt:{cmd:e(units)}}panel identifiers in estimation order{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and variance{p_end}
{synopt:{cmd:e(sigma2)}}T x N conditional variances{p_end}
{synopt:{cmd:e(resid)}}T x N residuals{p_end}
{synopt:{cmd:e(covt)}}T x N(N-1)/2 conditional covariances; pair order in {cmd:e(pairs)}{p_end}
{synopt:{cmd:e(ll_t)}}period log-likelihood contributions{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
