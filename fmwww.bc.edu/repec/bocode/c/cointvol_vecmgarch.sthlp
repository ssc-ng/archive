{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol vecmgarch postestimation" "help cointvol_vecmgarch_postestimation"}{...}
{vieweralsosee "cointvol garchrank" "help cointvol_garchrank"}{...}
{vieweralsosee "cointvol restrict" "help cointvol_restrict"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{viewerjumpto "Syntax" "cointvol_vecmgarch##syntax"}{...}
{viewerjumpto "Description" "cointvol_vecmgarch##description"}{...}
{viewerjumpto "Options" "cointvol_vecmgarch##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_vecmgarch##methods"}{...}
{viewerjumpto "Remarks" "cointvol_vecmgarch##remarks"}{...}
{viewerjumpto "Examples" "cointvol_vecmgarch##examples"}{...}
{viewerjumpto "Stored results" "cointvol_vecmgarch##results"}{...}
{viewerjumpto "References" "cointvol_vecmgarch##references"}{...}
{viewerjumpto "Author" "cointvol_vecmgarch##author"}{...}
{title:Title}

{phang}
{bf:cointvol vecmgarch} {hline 2} Joint estimation of a cointegrated VAR (VECM) with
multivariate conditional heteroskedasticity


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cointvol vecmgarch} {varlist} {ifin}{cmd:,} {opt la:gs(#)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Mean equation}
{synopt:{opt la:gs(#)}}lag order k of the VAR in levels (k-1 lagged differences); required{p_end}
{synopt:{opt ra:nk(#)}}cointegration rank r, 0 <= r < p; default {cmd:rank(1)}{p_end}
{synopt:{opt full:rank}}unrestricted (stationary) VAR in ECM form{p_end}
{synopt:{opt beta(numlist)}}fixed, known cointegrating vector(s), column by column{p_end}
{synopt:{opt norm:alize(varlist)}}normalisation c'beta = I_r on these r variables{p_end}
{synopt:{opt tr:end(string)}}{cmd:none}, {cmd:rconstant}, {cmd:constant} (default), {cmd:rtrend}, {cmd:trend}{p_end}
{syntab:Variance equation}
{synopt:{opt var:iance(model)}}{cmd:dbekk} (default), {cmd:bekk}, {cmd:cccgarch}, {cmd:ecccgarch},
{cmd:darch}, {cmd:trigarch}, {cmd:none}{p_end}
{synopt:{opt arch(#)}}ARCH order q ({cmd:bekk}, {cmd:cccgarch}, {cmd:darch}); default 1{p_end}
{synopt:{opt garch(#)}}GARCH order ({cmd:bekk}, {cmd:cccgarch}); default 1{p_end}
{synopt:{opt garchx(ect|varlist)}}add D'D x{c 94}2(t-1) to a BEKK-type H_t (Lee 1994 GARCH-X){p_end}
{synopt:{opt uncon:strained}}do not impose covariance stationarity in the reparameterisation{p_end}
{syntab:Estimation}
{synopt:{opt m:ethod(string)}}{cmd:qmle} (default), {cmd:twostep}, {cmd:ls}{p_end}
{synopt:{opt tech:nique(string)}}{cmd:bfgs} (default), {cmd:bhhh}, {cmd:nr}, {cmd:dfp} or switching,
e.g. {cmd:bfgs 10 bhhh 10}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations per stage; default 500{p_end}
{synopt:{opt start:s(#)}}number of additional random starting points; default 0{p_end}
{synopt:{opt seed(string)}}random-number seed (for {opt starts()}){p_end}
{synopt:{opt nonconv:ok}}report a non-converged model (flagged {cmd:e(converged)} = 0){p_end}
{synopt:{opt log} / {opt nolog}}show / suppress the iteration log (default: suppressed){p_end}
{syntab:Reporting}
{synopt:{opt vce(vcetype)}}{cmd:robust} (default; QML sandwich), {cmd:oim}, {cmd:opg}{p_end}
{synopt:{opt novce}}do not compute the variance matrix{p_end}
{synopt:{opt lev:el(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt br:ief}}omit the short-run block from the table{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (no panel) with no gaps. Time-series operators are allowed in
{it:varlist}. Typing {cmd:cointvol vecmgarch} without arguments replays the results.
See {helpb cointvol_vecmgarch_postestimation:cointvol vecmgarch postestimation} for
{cmd:predict} and {cmd:estat}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol vecmgarch} estimates a cointegrated VAR in error-correction form

{p 8 8 2}
dX_t = alpha beta#'Z1_t + Gamma_1 dX_(t-1) + ... + Gamma_(k-1) dX_(t-k+1) + Phi D2_t + e_t,
{space 2}e_t | F_(t-1) ~ (0, H_t)

{pstd}
where Z1_t = (X_(t-1)', D1_t')' and H_t follows one of six multivariate (G)ARCH models. The
mean and the variance parameters are estimated {it:jointly} by Gaussian (quasi) maximum
likelihood; this is not a two-step "GARCH on the VECM residuals" procedure (that is available
as {cmd:method(twostep)} for comparison). Joint estimation is more efficient for beta and for
the short-run parameters when the conditional heteroskedasticity is strong (Li, Ling & Wong
2001; Wong, Li & Ling 2005; Seo 2007), and it gives the likelihood needed for GARCH-X tests of
"causality in variance through the error-correction term" (Lee 1994) and for LR rank tests in
the VAR-GARCH (Bauwens, Deprins & Vandeuren 1997).

{pstd}
Use it when the cointegration rank is known (or fixed by theory, e.g. a spread) and the
innovations show ARCH effects. Use {helpb cointvol_rank:cointvol rank} or
{helpb cointvol_garchrank:cointvol garchrank} first to determine the rank. Do not use it to
test the rank as a primary tool: {cmd:estat ranklr} relies on conjectured asymptotics.


{marker options}{...}
{title:Options}

{dlgtab:Mean equation}

{phang}
{opt lags(#)} sets the lag order k of the levels VAR (k >= 1); the ECM has k-1 lagged
differences. Lee's (1994) p lagged differences correspond to {cmd:lags(}p+1{cmd:)}.

{phang}
{opt rank(#)} sets r. With 1 <= r < p, beta is estimated under the normalisation
c'beta = I_r on the variables in {opt normalize()} (default: the first r variables); the free
part of beta (and any restricted deterministic coefficients rho) is estimated jointly with all
other parameters. {cmd:rank(0)} fits a VAR in differences. {it:Original}: LLW (2001, Sec. 5),
WLL (2005, Sec. 5), Seo (2007, eq. 1).

{phang}
{opt fullrank} estimates Pi = alpha beta#' unrestricted (LLW 2001, WLL 2005 full-rank MLE).

{phang}
{opt beta(numlist)} fixes the cointegrating vector(s). Give p*r numbers (coefficients of the
levels, column by column); with {cmd:trend(rconstant)} or {cmd:rtrend} the restricted
deterministic coefficient(s) are then estimated. Give p1*r numbers to fix them too. The rank
is inferred from the count unless {opt rank()} is given. Lee (1994) uses X = (log s, log f)
and z = f - s, i.e. {cmd:beta(-1 1)}. {it:Original}: Lee (1994, eq. 1).

{phang}
{opt normalize(varlist)} lists the r variables whose beta block equals I_r.

{phang}
{opt trend()} chooses the deterministic case as in Stata's {helpb vec}: {cmd:none},
{cmd:rconstant} (constant in the cointegration space; BDV 1997 eq. 4), {cmd:constant}
(unrestricted constant; Lee 1994 eq. 1; default), {cmd:rtrend}, {cmd:trend}.

{dlgtab:Variance equation}

{phang}
{opt variance(model)}; see {help cointvol_vecmgarch##methods:Methods}. Labels:
{cmd:dbekk} {it:Original}: Lee (1994, eq. 2);
{cmd:bekk} {it:Original}: BDV (1997, eqs 5-7);
{cmd:cccgarch} {it:Original}: Sin, Mi & Ling (2024, eq. 2.3);
{cmd:ecccgarch} {it:Original}: Wong, Li & Ling (2005, eq. 2.2);
{cmd:darch} {it:Original}: Li, Ling & Wong (2001, eq. 4.1);
{cmd:trigarch} {it:Original}: Seo (2007, eqs 3-4);
{cmd:none}: homoskedastic Gaussian VECM (Johansen RRR / LS).

{phang}
{opt arch(#)} and {opt garch(#)} set the orders of {cmd:bekk} (BEKK(q,p): q ARCH, p GARCH
matrices, BDV notation), {cmd:cccgarch} (GARCH(p,q)) and {cmd:darch} (ARCH(q)). The other
models are (1,1). {cmd:garch(0)} gives pure ARCH versions ({it:Extended implementation}).

{phang}
{opt garchx(ect|varlist)} adds sum_k D_k'D_k x{c 94}2_(k,t-1) to H_t, D_k upper triangular, exactly
as Lee (1994, eq. 2) (RATS {cmd:xbekk=separate}). {cmd:garchx(ect)} uses the lagged
error-correction term(s) z_(t-1) = beta#'Z1_t (one D matrix per relation); a {it:varlist} uses
the first lag of each variable. Allowed with {cmd:dbekk} ({it:Original}) and {cmd:bekk}
({it:Extended implementation}). {bf:Warning}: the score is zero at D = 0, so the starting value
of D is small but nonzero (about 0.1 in standardised units), and LR/Wald tests of D = 0 are
non-standard.

{phang}
{opt unconstrained}: by default covariance stationarity is imposed through the
reparameterisation ({cmd:dbekk}: a_i{c 94}2 + b_i{c 94}2 < 1, a_i, b_i >= 0; {cmd:cccgarch},
{cmd:darch}, {cmd:trigarch}: sum of ARCH and GARCH coefficients < 1; {cmd:ecccgarch}: b_i < 1).
With {opt unconstrained} only positivity is imposed ({cmd:dbekk}: a_i, b_i free up to a common
sign). {cmd:bekk} never imposes stationarity; check it with {cmd:estat moments}.

{dlgtab:Estimation}

{phang}
{opt method(qmle)} (default) maximises the Gaussian log likelihood over all parameters
jointly. {opt method(twostep)}: (1) variance parameters by ML on the LS/RRR residuals, (2) mean
parameters by ML with the variance parameters fixed (LLW 2001, WLL 2005; asymptotically
equivalent under their block-diagonality results). {opt method(ls)}: Johansen RRR / LS only
(homoskedastic Gaussian ML; Lee's Model 1).

{phang}
{opt technique()} is passed to Mata {helpb mf_optimize:optimize()} (evaluator type v0, so
{cmd:bhhh} is available). {opt iterate(#)} caps the iterations of each stage.

{phang}
{opt starts(#)} re-runs the joint optimisation from # random perturbations of the two-step
starting point and keeps the best converged solution; {opt seed()} makes this reproducible.

{phang}
{opt nonconvok}: by default a non-converged model is refused (error 430).

{dlgtab:Reporting}

{phang}
{opt vce(robust)} (default) is the Bollerslev-Wooldridge (1992) QML sandwich
H{c 94}-1 (sum s_t s_t') H{c 94}-1; {opt vce(oim)} the inverse negative Hessian; {opt vce(opg)} the
inverse outer product of the scores. Seo (2007, Thm 2) shows that only the sandwich Wald test
on beta is chi2 when the standardised errors are non-normal; the OIM and OPG versions are
scaled by mu/nu and (mu/nu){c 94}2 and over-reject under excess kurtosis.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Mean.} Z0_t = dX_t, Z1_t = (X_(t-1)', D1_t')', Z2_t = (dX_(t-1)', ..., D2_t')' as in
Johansen (1996); e_t = Z0_t - alpha beta#'Z1_t - Psi Z2_t. beta# = (beta', rho')' is p1 x r with
c'beta = I_r; its free rows, alpha and Psi are parameters. {cmd:fullrank} sets beta# = I and
alpha = Pi.

{pstd}
{bf:Likelihood} (LLW eq. 4.2; WLL eq. 4.2; Seo eq. 6; SML eq. 3.1):
l_t = -0.5 [ p log(2 pi) + log|H_t| + e_t'H_t{c 94}-1 e_t ], logL = sum_t l_t over the T
effective observations (the first k observations are initial values).

{pstd}
{bf:Variance models} (e2 = squared errors):

{p 8 12 2}{cmd:dbekk}: H_t = C'C + A'e_(t-1)e_(t-1)'A + B'H_(t-1)B [+ sum_k D_k'D_k x{c 94}2_(k,t-1)],
A = diag(a), B = diag(b), C and D_k upper triangular; h_ij,t = (C'C)_ij + a_i a_j e_i e_j +
b_i b_j h_ij + (D'D)_ij x{c 94}2 (Lee 1994, eq. 2).{p_end}
{p 8 12 2}{cmd:bekk}: H_t = C'C + sum_i A_i'e_(t-i)e_(t-i)'A_i + sum_j G_j'H_(t-j)G_j, A_i, G_j full
p x p, sign normalisation a_11 > 0, g_11 > 0 (BDV 1997, eqs 5-7).{p_end}
{p 8 12 2}{cmd:cccgarch}: h_it = w_i + sum_l a_il e2_(i,t-l) + sum_l b_il h_(i,t-l),
H_t = D_t Gamma D_t, D_t = diag(h_t){c 94}.5, Gamma a constant correlation matrix (SML 2024, eq. 2.3;
Bollerslev 1990).{p_end}
{p 8 12 2}{cmd:ecccgarch}: h_t = w + A e2_(t-1) + B h_(t-1), A full (volatility spill-overs), B
diagonal, Gamma = I (WLL 2005, eq. 2.2).{p_end}
{p 8 12 2}{cmd:darch}: h_kt = g_k + sum_i s_ki e2_(k,t-i), Gamma = I (LLW 2001, eq. 4.1).{p_end}
{p 8 12 2}{cmd:trigarch}: e_t = L u_t with L unit lower triangular,
s2_jt = w_j + psi_j e{c 94}2_(j,t-1) + phi_j s2_(j,t-1), Omega_t = L{c 94}-1 diag(s2_t) L{c 94}-1'
(Seo 2007, eqs 3-4).{p_end}

{pstd}
{bf:Presample values.} H_0 and e_0 e_0' are set to the sample covariance S0 of the initial
LS/RRR residuals (for {cmd:trigarch}: diag(L S0 L')); they do not change during the iterations.
Initial conditions are asymptotically negligible (Seo 2007, Sec. 2).

{pstd}
{bf:Algorithm.} (0) The series are multiplied internally by c = 1/(average standard deviation
of dX) for numerical stability; all results are transformed back (the log likelihood by
+T p log c). (1) Starting values of the mean: Johansen RRR (exact homoskedastic ML), normalised
so that c'beta = I_r; with {opt beta()} the RRR is done on H'Z1 (Johansen 1996, Thm 7.2). (2)
Starting values of the variance from moment conditions ({cmd:bekk}: a preliminary diagonal
BEKK fit); positivity and stationarity by squares / exp / logistic maps, correlation matrices
via a unit lower-triangular factor. (3) Stage 1: variance parameters by ML with the mean fixed
(= the two-step estimator of LLW/WLL). (4) Stage 2: {cmd:qmle} all parameters jointly
(Seo 2007, eq. 7), {cmd:twostep} the mean parameters with the variance fixed. (5)
{opt starts()} restarts. (6) The variance matrix is computed by numerical derivatives of l_t
with respect to the reported parameters (equivalent to the delta method applied to the
transformed parameters); for {cmd:twostep} it is block diagonal (mean, variance).

{pstd}
{bf:Step -> equation map.}
Mean: Lee (1994) eq. 1; LLW (2001) eq. 2.1; Seo (2007) eq. 1; BDV (1997) eqs 3-4.
Likelihood: LLW eq. 4.2; Seo eq. 6.
Variance models: see above.
RRR start: Seo (2007) Sec. 2.2; SML (2024) Sec. 4.1.
Two-step: LLW (2001) Secs 3-4; WLL (2005) Secs 3-4.
Sandwich: Bollerslev & Wooldridge (1992); Seo (2007) Thm 2.
BEKK stationarity: BDV (1997) eq. 8.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Convergence.} Multivariate GARCH likelihoods are flat in some directions. Use
{cmd:technique(bfgs 10 bhhh 10)} or {cmd:bhhh}, raise {opt iterate()}, or try
{opt starts()}. Lee (1994) could not estimate GARCH-X for two currencies. Non-converged models
are refused unless {opt nonconvok}.

{pstd}
{bf:Inference on beta.} beta is super-consistent and its QMLE is mixed normal (Seo 2007,
Thm 1), so z statistics and Wald tests are asymptotically standard {it:conditionally}; use the
robust (sandwich) variance. Estimates of GARCH parameters near a boundary (e.g. an ARCH
coefficient near 0 with the exp map) have unreliable standard errors.

{pstd}
{bf:trigarch.} Seo calls the model "constant-correlation GARCH", but the conditional
correlations of u_t vary over time unless L = I; results depend on the ordering of the
variables.

{pstd}
{bf:Comparisons.} {cmd:e(ll_0)} is the homoskedastic Gaussian log likelihood of the same mean
equation (Lee's Model 1), used by {cmd:estat garchx}. AIC = -2logL + 2K and BIC = -2logL + K
log T use the effective T (Lee used the full T = 1245).

{pstd}
{bf:Speed.} Each likelihood evaluation is vectorised; the variance matrix needs about 2K{c 94}2
evaluations (K = number of parameters). Use {opt novce} for exploratory fits.


{marker examples}{...}
{title:Examples}

{pstd}Simulated bivariate VECM with diagonal BEKK errors{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 600}{p_end}
{phang2}{cmd:. set seed 12}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen h = 1}{p_end}
{phang2}{cmd:. gen e1 = rnormal()}{p_end}
{phang2}{cmd:. replace h = 0.05 + 0.1*L.e1{c 94}2 + 0.85*L.h if t > 1}{p_end}
{phang2}{cmd:. replace e1 = sqrt(h)*rnormal() if t > 1}{p_end}
{phang2}{cmd:. gen x2 = sum(rnormal())}{p_end}
{phang2}{cmd:. gen x1 = x2 + e1}{p_end}

{pstd}Minimal{p_end}
{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1)}{p_end}

{pstd}Other variance models{p_end}
{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1) variance(cccgarch) trend(rconstant)}{p_end}
{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1) variance(trigarch)}{p_end}
{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1) variance(bekk) technique(bfgs 10 bhhh 10)}{p_end}

{pstd}Lee (1994) style: fixed spread, GARCH-X in the squared lagged spread{p_end}
{phang2}{cmd:. cointvol vecmgarch ls lf, lags(5) beta(-1 1) trend(constant) method(ls)}{p_end}
{phang2}{cmd:. cointvol vecmgarch ls lf, lags(5) beta(-1 1) variance(dbekk)}{p_end}
{phang2}{cmd:. cointvol vecmgarch ls lf, lags(5) beta(-1 1) variance(dbekk) garchx(ect)}{p_end}
{phang2}{cmd:. estat garchx}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol vecmgarch} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}effective observations T{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}homoskedastic Gaussian log likelihood of the same mean (LS/RRR){p_end}
{synopt:{cmd:e(k)}, {cmd:e(k_mean)}, {cmd:e(k_var)}, {cmd:e(k_0)}}numbers of parameters{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}}information criteria{p_end}
{synopt:{cmd:e(converged)}, {cmd:e(ic)}}convergence flag and iterations (final stage){p_end}
{synopt:{cmd:e(converged_v)}, {cmd:e(ic_v)}}the same for the variance stage{p_end}
{synopt:{cmd:e(rank)}}cointegration rank (p for {cmd:fullrank}){p_end}
{synopt:{cmd:e(rank_int)}}internal number of columns of beta# (p1 for {cmd:fullrank}){p_end}
{synopt:{cmd:e(lags)}, {cmd:e(p)}, {cmd:e(arch)}, {cmd:e(garch)}, {cmd:e(nx)}}model dimensions{p_end}
{synopt:{cmd:e(scale)}}internal scale factor c{p_end}
{synopt:{cmd:e(starts)}, {cmd:e(starts_conv)}}restarts requested / converged{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}, {cmd:e(tdelta)}}sample window including initial values{p_end}
{synopt:{cmd:e(vsing)}}number of singular directions of the information matrix{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cointvol vecmgarch}{p_end}
{synopt:{cmd:e(varlist)}}variables{p_end}
{synopt:{cmd:e(variance)}, {cmd:e(vlabel)}}variance model and label{p_end}
{synopt:{cmd:e(trend)}, {cmd:e(method)}, {cmd:e(technique)}, {cmd:e(vce)}, {cmd:e(vcetype)}}settings{p_end}
{synopt:{cmd:e(rmode)}}{cmd:est}, {cmd:fixed}, {cmd:full} or {cmd:zero}{p_end}
{synopt:{cmd:e(normalize)}, {cmd:e(betaspec)}, {cmd:e(garchx)}, {cmd:e(xvars)}}mean / X specification{p_end}
{synopt:{cmd:e(opt_core)}, {cmd:e(opt_mean)}}options used by {cmd:estat} refits{p_end}
{synopt:{cmd:e(predict)}, {cmd:e(estat_cmd)}}{cmd:cointvol_vecmgarch_p}, {cmd:cointvol_vecmgarch_estat}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients (equation-labelled) and variance{p_end}
{synopt:{cmd:e(V_oim)}, {cmd:e(V_opg)}}alternative variance estimates{p_end}
{synopt:{cmd:e(alpha)}, {cmd:e(beta)}, {cmd:e(Pi)}, {cmd:e(bfree)}}long-run parameters{p_end}
{synopt:{cmd:e(Gamma)}}short-run and unrestricted deterministic coefficients{p_end}
{synopt:{cmd:e(H)}, {cmd:e(Hbar)}, {cmd:e(H0)}}last, average and presample conditional covariance{p_end}
{synopt:{cmd:e(persist)}}persistence measures{p_end}
{synopt:model matrices}{cmd:dbekk}: {cmd:e(C)}, {cmd:e(Omega)}, {cmd:e(A)}, {cmd:e(B)}, {cmd:e(D)};
{cmd:bekk}: {cmd:e(C)}, {cmd:e(Omega)}, {cmd:e(A1)}..., {cmd:e(G1)}...;
{cmd:cccgarch}: {cmd:e(garchpar)}, {cmd:e(Corr)}; {cmd:ecccgarch}: {cmd:e(W)}, {cmd:e(A)}, {cmd:e(B)};
{cmd:darch}: {cmd:e(garchpar)}; {cmd:trigarch}: {cmd:e(L)}, {cmd:e(garchpar)}; {cmd:none}: {cmd:e(Sigma)}{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Bauwens, L., D. Deprins and J.-P. Vandeuren. 1997. Modelling interest rates with a
cointegrated VAR-GARCH model. CORE Discussion Paper 9780, Universite catholique de Louvain.

{phang}
Bollerslev, T. 1986. Generalized autoregressive conditional heteroskedasticity.
{it:Journal of Econometrics} 31: 307-327. doi:10.1016/0304-4076(86)90063-1.

{phang}
Bollerslev, T. 1990. Modelling the coherence in short-run nominal exchange rates: a
multivariate generalized ARCH model. {it:Review of Economics and Statistics} 72: 498-505.
doi:10.2307/2109358.

{phang}
Bollerslev, T. and J. M. Wooldridge. 1992. Quasi-maximum likelihood estimation and inference
in dynamic models with time-varying covariances. {it:Econometric Reviews} 11: 143-172.
doi:10.1080/07474939208800229.

{phang}
Engle, R. F. and K. F. Kroner. 1995. Multivariate simultaneous generalized ARCH.
{it:Econometric Theory} 11: 122-150. doi:10.1017/S0266466600009063.

{phang}
Johansen, S. 1996. {it:Likelihood-Based Inference in Cointegrated Vector Autoregressive Models}.
Oxford: Oxford University Press.

{phang}
Lee, T.-H. 1994. Spread and volatility in spot and forward exchange rates.
{it:Journal of International Money and Finance} 13: 375-383. doi:10.1016/0261-5606(94)90034-5.

{phang}
Li, W. K., S. Ling and H. Wong. 2001. Estimation for partially nonstationary multivariate
autoregressive models with conditional heteroscedasticity. {it:Biometrika} 88: 1135-1152.
doi:10.1093/biomet/88.4.1135.

{phang}
Seo, B. 2007. Asymptotic distribution of the cointegrating vector estimator in error
correction models with conditional heteroskedasticity. {it:Journal of Econometrics} 137: 68-111.
doi:10.1016/j.jeconom.2006.03.008.

{phang}
Sin, C.-y., Z. Mi and S. Ling. 2024. On a partially non-stationary vector AR model with vector
GARCH noises: estimation and testing. {it:Communications in Mathematics Research} 40: 64-101.
doi:10.4208/cmr.2023-0005.

{phang}
Wong, H., W. K. Li and S. Ling. 2005. Joint modeling of cointegration and conditional
heteroscedasticity with applications. {it:Annals of the Institute of Statistical Mathematics}
57: 83-103. doi:10.1007/BF02506881.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
