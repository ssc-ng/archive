{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch cg" "help xtpanelgarch_cg"}{...}
{vieweralsosee "xtpanelgarch vt" "help xtpanelgarch_vt"}{...}
{vieweralsosee "xtpanelgarch cl" "help xtpanelgarch_cl"}{...}
{vieweralsosee "xtpanelgarch pretest" "help xtpanelgarch_pretest"}{...}
{viewerjumpto "cg" "xtpanelgarch_methods##cg"}{...}
{viewerjumpto "vt" "xtpanelgarch_methods##vt"}{...}
{viewerjumpto "cl" "xtpanelgarch_methods##cl"}{...}
{viewerjumpto "armagarch" "xtpanelgarch_methods##armagarch"}{...}
{viewerjumpto "qgarch" "xtpanelgarch_methods##qgarch"}{...}
{viewerjumpto "hgarch" "xtpanelgarch_methods##hgarch"}{...}
{viewerjumpto "cluster" "xtpanelgarch_methods##cluster"}{...}
{viewerjumpto "msgarch" "xtpanelgarch_methods##msgarch"}{...}
{viewerjumpto "pretest" "xtpanelgarch_methods##pretest"}{...}
{viewerjumpto "Validation" "xtpanelgarch_methods##validation"}{...}
{viewerjumpto "Decisions" "xtpanelgarch_methods##decisions"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch methods} {hline 2} Equations, step-to-equation maps and validation record


{marker cg}{...}
{title:1. Cermeño and Grier (2001, 2006): xtpanelgarch cg}

{pstd}{bf:Model.} For i = 1..N, t = 1..T,{p_end}
{p 8 8 2}y_it = mu_i + x_it'beta + kappa g(sigma2_it) + u_it,  E(u_it u_js | F_t-1) = 0 for t != s{p_end}
{p 8 8 2}sigma2_it = alpha_i + sum_{l=1..q} gamma_l u{c 94}2_i,t-l + sum_{l=1..p} delta_l sigma2_i,t-l + lambda u{c 94}2_i,t-1 1(u_i,t-1<0) + z_it'theta{p_end}
{p 8 8 2}sigma_ij,t = eta_ij + rho u_i,t-1 u_j,t-1 + lambda_c sigma_ij,t-1   (i != j){p_end}

{pstd}{bf:Likelihood.} With u_t = (u_1t,...,u_Nt)' ~ N(0, Omega_t),{p_end}
{p 8 8 2}l = -(NT/2) ln 2pi - (1/2) sum_t ln|Omega_t| - (1/2) sum_t u_t' Omega_t{c 94}-1 u_t     [CG 2006 eq. 10.7]{p_end}
{pstd}and under cross-sectional independence it is the sum of univariate GARCH likelihoods [CG 2001 eq. 7; CG 2006 eq. 10.8].{p_end}

{p2colset 5 40 42 2}{...}
{p2col:{bf:Code step}}{bf:Source}{p_end}
{p2line}
{p2col:mean residual e_it = y_it - mu_i - x_it'beta}CG 2001 eq. (2), (10); CG 2006 eq. (10.1){p_end}
{p2col:in-mean term kappa sigma_it}CG 2006 eq. (10.9a); Engle, Lilien and Robins (1987){p_end}
{p2col:variance recursion}CG 2001 eq. (4), (9), (11); CG 2006 eq. (10.3), (10.10a){p_end}
{p2col:asymmetry 1(u<0)}Glosten, Jagannathan and Runkle (1993){p_end}
{p2col:covariance recursion (common, pair)}CG 2006 eq. (10.4), Models 2-3{p_end}
{p2col:CCC covariance}Cermeño-Sanin 2015 eq. (3); Bollerslev (1990){p_end}
{p2col:Omega_t = Cholesky, log-det, quadratic form}CG 2006 eq. (10.6)-(10.7){p_end}
{p2col:models A-D}CG 2001 sec. 4{p_end}
{p2col:V: -H{c 94}-1 / OPG / sandwich}CG 2006 p. 264 / CG 2001 fn. 4 / Bollerslev-Wooldridge (1992){p_end}
{p2col:PD check of Omega_t}Asai 2023 Props. 1-2 (not in CG){p_end}
{p2line}


{marker vt}{...}
{title:2. Asai (2023): xtpanelgarch vt}

{pstd}Asai shows that CG's Omega_t is guaranteed positive definite only if gamma = rho and delta = lambda_c
(Remark 2.4; Scherrer and Ribarits 2007). The feasible specification is then{p_end}
{p 8 8 2}H_t = (1 - gamma - phi) Sigma + gamma u_t-1 u_t-1' + phi H_t-1     [eq. 14, 17]{p_end}
{pstd}with Sigma = E(u_t u_t') and stationarity gamma + phi < 1 [eq. 10].{p_end}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:1. within (FE) estimator of theta and alpha_i}eq. (18)-(19){p_end}
{p2col:2. Sigma-hat = T{c 94}-1 sum u_t u_t'}eq. (20){p_end}
{p2col:3. maximise QL over (gamma, phi), H_1 = Sigma-hat}eq. (21)-(22){p_end}
{p2col:step-1 robust variance}eq. (25), Omega_m-hat / T{p_end}
{p2col:step-1 model-based variance}eq. (26), uses H_t(psi-hat){p_end}
{p2col:step-3 variance P0 Omega_v P0' / T}Prop. 4 with Xi_lambda, Xi_sigma of eq. (A.13), numerical derivatives, vech(Sigma) coordinates{p_end}
{p2col:CCP alternative}eq. (27){p_end}
{p2line}
{pstd}The mean and variance blocks are uncorrelated under a symmetric error distribution (Remark 3.2), so
{cmd:e(V)} is block diagonal. Asai's Appendix A.2 writes l_t with aggregated scalars u-bar_t and h-bar_t.
{cmd:vt} maximises the multivariate QL of eq. (22) itself and takes the derivatives numerically.{p_end}


{marker cl}{...}
{title:3. Pakel, Shephard and Sheppard (2011): xtpanelgarch cl}

{p 8 8 2}sigma2_it = gamma_i (1 - a - b) + a y{c 94}2_i,t-1 + b sigma2_i,t-1,  E(y{c 94}2_it) = gamma_i     [eq. 2.3-2.4]{p_end}
{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:gamma_i-hat = T{c 94}-1 sum_t y{c 94}2_it}eq. (2.6){p_end}
{p2col:sigma2_i0 = mean of first floor(T{c 94}1/2) y{c 94}2}p. 309{p_end}
{p2col:CL = T{c 94}-1 sum_t N{c 94}-1 sum_i log f}eq. (2.5), (2.9){p_end}
{p2col:sqrt(T)(theta-hat - theta) -> N(0, J{c 94}-1 I~ J{c 94}-1)}eq. (2.10){p_end}
{p2col:z_t,N with nuisance correction, HAC for I~}p. 313 (Newey-West, Bartlett){p_end}
{p2col:MacGyver median blend}sec. 4; Engle (2009){p_end}
{p2line}


{marker armagarch}{...}
{title:3b. Su and Zhu (2024): xtpanelgarch armagarch}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:V = A_phi y - X beta, presample y = u = 0}eq. (2.2)-(2.3){p_end}
{p2col:mu-hat(lambda) = (l'Sigma{c 94}-1 l){c 94}-1 l'Sigma{c 94}-1 V, Sigma = B B'}eq. (2.4); computed with the B{c 94}-1 recursion{p_end}
{p2col:lambda-hat = argmin Q_lambda}eq. (2.5){p_end}
{p2col:w_i-hat = T{c 94}-1 sum u{c 94}2; VT-QML over (tau, nu)}eq. (2.6)-(2.9); softmax keeps tau, nu > 0 and sum < 1{p_end}
{p2col:presample u{c 94}2 = h = w_i-hat}authors' code (paper text: h_0 = c_h){p_end}
{p2col:Var(lambda): sandwich on concentrated residuals}Thm 4.1 (Sigma1 under MDS errors){p_end}
{p2col:Var(zeta): Gamma2{c 94}-1 Omega2 Gamma2{c 94}-1, w- and lambda-effects}Thm 4.4 (supplement not public: numerical derivatives){p_end}
{p2col:mu_i, w_i, varpi_i and their SEs}Thms 4.2, 4.5{p_end}
{p2col:half-panel jackknife}eq. (4.4), (4.11); Dhaene and Jochmans (2015){p_end}
{p2line}


{marker qgarch}{...}
{title:3c. Zhu, Li, Zhang and Li (2026): xtpanelgarch qgarch}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:q_it = w + a S_it, S_it = |y_i,t-1| + b S_i,t-1, S_i1 = 0}eq. (3), y_{c -(}t<=0{c )-} = 0{p_end}
{p2col:self-weights, c_i = 95% quantile of y_i}eq. (9); authors' weight_function_HeYi2021_cpp{p_end}
{p2col:Stage I start: GARCH(1,1) on sqrt|y|sgn(y) + 9{c 94}3 grid}Zhu et al. (2023) code fit1_optim, fit1_optim_grid{p_end}
{p2col:binary segmentation, CUSUM}eq. (6); authors' fc_changepoints{p_end}
{p2col:BIC3 = loss + g ln N, adaptive grid on [0, 2]}authors' fc3_select_delta_l_tau_BIC{p_end}
{p2col:Stage III pooled CQE}eq. (7); Nelder-Mead with restarts from the change-point start and the group-mean start{p_end}
{p2col:Omega0, Omega1, difference-quotient density}Thm 3.1; supplement eq. (S.51); n = NT (not stated in the paper){p_end}
{p2line}


{marker hgarch}{...}
{title:3d. Brownlees (2019): xtpanelgarch hgarch}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:level I factor GARCH, (h, lambda, pi) parameterisation}eqs. (1)-(2){p_end}
{p2col:level II links: identity, log, probit, probit}eqs. (3)-(6){p_end}
{p2col:simulated ML with common draws, log-sum-exp}eqs. (7)-(9){p_end}
{p2col:coefficient estimates E(g_i | data), importance weights}eqs. (10)-(12){p_end}
{p2col:naive start: series ML + level-II OLS}sec. 3{p_end}
{p2col:presample h_i0 = e{c 94}2_i0 = h_i}not stated in the paper{p_end}
{p2line}


{marker cluster}{...}
{title:3e. Bauwens and Rombouts (2007): xtpanelgarch cluster}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:mixture of G VT-GARCH(1,1), w_j = sample variance}eqs. (1)-(3), (29)-(31){p_end}
{p2col:allocations S_j}eq. (13){p_end}
{p2col:eta ~ Dir(a0 + x)}eqs. (14)-(15){p_end}
{p2col:griddy-Gibbs on alpha_g | beta_g, beta_g | alpha_g}eqs. (16)-(17); Bauwens, Lubrano and Richard (1999, ch. 3){p_end}
{p2col:trapezium uniform priors, separated supports}secs. 3.4, 5.1{p_end}
{p2col:log marginal likelihood}eq. (28): ordinates (23) and (24)-(27), m(y_g) by 2-D quadrature (25){p_end}
{p2line}


{marker msgarch}{...}
{title:3f. Casarin, Costantini and Osuntuyi (2024): xtpanelgarch msgarch}

{p2col:{bf:Step}}{bf:Source}{p_end}
{p2line}
{p2col:MS-GARCH with switching mean}eqs. (1)-(5){p_end}
{p2col:hierarchical + Pitman-Yor prior}eqs. (6)-(16); slice representation (24)-(25){p_end}
{p2col:V, U}A.1 eqs. (29)-(30){p_end}
{p2col:P_i rows, r_k (MH, Dir(d + m_k) proposal)}A.2 eqs. (31)-(34){p_end}
{p2col:atoms mu* (conjugate), g*, a*, b*}A.3 eq. (35); exact beta conditionals by griddy-Gibbs instead of the approximate (36)-(37){p_end}
{p2col:mu_i: MH, mixture proposal}A.4 eq. (39), full Hastings ratio{p_end}
{p2col:(g, a, b)_i: Nakatsuma-Ardia proposal}A.4 eqs. (41)-(50), full Hastings ratio{p_end}
{p2col:paths: MH with Klaassen-FFBS proposal}A.5 eqs. (51)-(57); Billio et al. (2016) sec. 3.2.5{p_end}
{p2col:allocations D_ik}A.6{p_end}
{p2col:co-clustering probabilities}eq. (28){p_end}
{p2line}


{marker pretest}{...}
{title:4. Pre-tests: xtpanelgarch pretest}

{p2col:{bf:Test}}{bf:Source}{p_end}
{p2line}
{p2col:Wald H0: mu_1 = ... = mu_N, LSDV + HAC, chi2(N-1)}CG 2001 sec. 5.1; CG 2006 sec. 10.3.1{p_end}
{p2col:PACF of squared residuals, LM-ARCH(j)}CG 2001 sec. 5.2, Table 1; Engle (1982){p_end}
{p2col:unit intercepts in AR of u{c 94}2: F and chi2}CG 2001 sec. 5.2 (F(4,94), chi2(4) in sec. 7.1){p_end}
{p2col:LR groupwise heteroskedasticity, chi2(N-1)}CG 2006 sec. 10.4.1{p_end}
{p2col:LR cross-sectional correlation, chi2(N(N-1)/2)}CG 2006 sec. 10.4.1{p_end}
{p2col:Breusch-Pagan LM, Pesaran CD}added (Apostolakis et al. 2025 use CD){p_end}
{p2col:AR of cross products, pair effects}CG 2006 sec. 10.3.2{p_end}
{p2line}


{marker validation}{...}
{title:5. Validation record}

{p2col:{bf:Check}}{bf:Result}{p_end}
{p2line}
{p2col:{cmd:cg}, N = 1, GARCH(1,1) vs {helpb arch}}identical b and log likelihood (369.754580); OPG SEs identical{p_end}
{p2col:{cmd:cg}, N = 1, ARCH(2)-M vs {helpb arch}}identical maximum (389.6292) with multistart{p_end}
{p2col:{cmd:cg, egarch}, N = 1, EGARCH(1,1) vs {helpb arch}}log likelihood at {helpb arch}'s estimates identical (372.960253); our maximum 373.036{p_end}
{p2col:{cmd:cg, cov(pair) model(D)} vs constrained {helpb mgarch dvech}}identical log likelihood (-2679.7915), b and SEs to 4 decimals{p_end}
{p2col:{cmd:cg, cov(ccc) model(D)} vs constrained {helpb mgarch ccc}}identical log likelihood (-2743.3603), b and SEs{p_end}
{p2col:{cmd:cg} on Grunfeld (5 firms), Model D}ARCH 0.9054 (CG 2001: 0.9004), F 0.0458 (0.0457), C 0.1515 (0.1518),
mu_GE -51.74 (-51.74), LL -502.93 (-503.65). Remaining gaps: Greene's (1997) corrected data vs {cmd:webuse grunfeld}
(OLS LL -625.69 vs -624.99){p_end}
{p2col:{cmd:vt} on Asai's DGP (n = 5, T = 500)}gamma 0.035 (truth 0.04), phi 0.937 (0.94); SE 0.0044 / 0.0070 vs Asai's
Monte Carlo SD 0.0057 / 0.0112 (Table 1){p_end}
{p2col:{cmd:vt, qml} on Asai's DGP (n = 5, T = 500)}gamma .036, phi .936 (VT: .035, .937; truth .04, .94); QML and VT close, as in Asai's Tables 4-5{p_end}
{p2col:{cmd:armagarch} on Su-Zhu DGP (5.1), N = 50, T = 200}beta 3.007, phi .300, psi .308, tau .174, nu .398 (truth 3, .3, .3, .2, .4);
SEs .014/.005/.013/.013/.048 vs paper Monte Carlo SDs .015/.005/.013/.014/.044 (Table 2); jackknife tau .176, nu .443{p_end}
{p2col:{cmd:hgarch} on Brownlees's design (N = 100, T = 500, S = 100)}lambda delta (-.118, .050, -1.447) vs (-.1, .1, -1.5);
ln h delta (.117, -.025, -7.08) vs (.1, -.1, -7); MSE of series ln h .086 (HG) vs .147 (naive), lambda .0006 vs .0008,
as in the paper's Table 1 (gains on the volatility dynamics){p_end}
{p2col:{cmd:cluster} on Bauwens-Rombouts sec. 5 (J = 100, T = 1000, G = 3)}alpha (.037, .110, .200), beta (.896, .621, .381) vs paper
Table 1 (.044, .104, .198), (.876, .592, .437) and truth (.04, .12, .20), (.90, .60, .40); 84% of series in their true group{p_end}
{p2col:{cmd:msgarch} on Casarin et al. sec. 4.1 (N = 30, T = 300, K = 2)}corr(mu-hat, mu) .99 and .92 by regime; MAP clusters 1 in
regime 1 (as in the paper) and 2 in regime 2 (true 3); GARCH parameters weakly identified at T = 300{p_end}
{p2col:{cmd:qgarch, factors()} on eq. (10)-(12) design (N = 30, T = 1000)}loadings .46 and .99 (truth .5, 1.0), exact loading
partition; alpha and beta over-split into 4 groups whose values bracket the truth{p_end}
{p2col:{cmd:cl} on Pakel et al.'s DGP (N = 20, T = 1000)}alpha 0.047 (0.05), beta 0.936 (0.93); SE 0.0048 / 0.0072, between
their N = 10 and N = 50 Monte Carlo SDs (Table 4){p_end}
{p2line}


{marker decisions}{...}
{title:6. Decisions where the papers are silent or ambiguous}

{phang}1. Pre-sample sigma2_i0 in {cmd:cg}: unit mean of squared mean-residuals (as {helpb arch}). CG are silent.{p_end}
{phang}2. In-mean pre-sample: residuals without the in-mean term. This causes a tiny difference from {helpb arch}
when {cmd:archm} is specified (386.8180 vs 386.8488 at {helpb arch}'s optimum).{p_end}
{phang}3. GJR indicator 1(u<0), as in GJR (1993), not Stata's 1(u>0).{p_end}
{phang}4. {cmd:cl}: the nuisance correction uses (1/T) sum_s d2 l_is/d theta d gamma_i times (y{c 94}2_it - gamma_i),
which is the influence function of gamma_i-hat. The printed formula on p. 313 omits the 1/T factor.{p_end}
{phang}5. HAC lag default floor(4(T/100){c 94}(2/9)), the rule CG (2006) use for their unit-root tests.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
