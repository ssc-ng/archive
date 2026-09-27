{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol simulate" "help cointvol_simulate"}{...}
{vieweralsosee "cointvol vecmgarch" "help cointvol_vecmgarch"}{...}
{vieweralsosee "[TS] vec postestimation" "help vec_postestimation"}{...}
{vieweralsosee "[TS] arch" "help arch"}{...}
{viewerjumpto "Syntax" "cointvol_diag##syntax"}{...}
{viewerjumpto "Description" "cointvol_diag##description"}{...}
{viewerjumpto "Options" "cointvol_diag##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_diag##methods"}{...}
{viewerjumpto "Remarks" "cointvol_diag##remarks"}{...}
{viewerjumpto "Examples" "cointvol_diag##examples"}{...}
{viewerjumpto "Stored results" "cointvol_diag##results"}{...}
{viewerjumpto "References" "cointvol_diag##references"}{...}
{viewerjumpto "Author" "cointvol_diag##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:cointvol diag} {hline 2}}Residual diagnostics for a VAR / VECM: ARCH,
CCC-ARCH and covariance-constancy LM tests, Ling-Li portmanteau test for conditional
heteroskedasticity, heteroskedasticity-robust autocorrelation tests, portmanteau,
variance profiles, companion roots and a two-step spread GARCH{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol diag} {varlist} {ifin}{cmd:,} {opt l:ags(#)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt l:ags(#)}}lag order {it:k} of the VAR in levels, {it:k} {ul:>} 1{p_end}
{synopt:{opt tr:end(string)}}{cmd:none}, {cmd:rconstant} (default), {cmd:constant},
{cmd:rtrend} or {cmd:trend}{p_end}
{synopt:{opt ra:nk(#)}}cointegration rank {it:r} of the fitted VECM; default {it:r} = {it:p}
(unrestricted VAR){p_end}

{syntab:Tests ({it:h} = lag order of the test)}
{synopt:{opt arch:lm(h)}}univariate Engle ARCH-LM test in each equation{p_end}
{synopt:{opt march(h)}}multivariate ARCH-LM (MARCH) test{p_end}
{synopt:{opt ca(h)}}Catani-Ahlgren combined LM test (bootstrap p-value always computed){p_end}
{synopt:{opt et(h)}}Eklund-Terasvirta LM test against CCC-ARCH({it:h}){p_end}
{synopt:{opt etch:ol}}compute {cmd:et()} on Cholesky-standardised residuals (VARtests
convention){p_end}
{synopt:{opt etst(s)}}Eklund-Terasvirta LM test against smoothly time-varying variances
({it:s} = 1: paper; {it:s} = 2-4: polynomial in t/T){p_end}
{synopt:{opt ling:li(M)}}Ling-Li multivariate portmanteau test for remaining conditional
heteroskedasticity, lags 1..{it:M}{p_end}
{synopt:{opt llar:ch(r)}}also report Q(r,M) for an ARCH({it:r}) conditional covariance,
0 {ul:<} {it:r} < {it:M}{p_end}
{synopt:{opt llv:cov(varlist)}}fitted conditional covariance V_t for {cmd:lingli()}:
K(K+1)/2 variables holding vech(V_t){p_end}
{synopt:{opt aclm(h)}}residual autocorrelation LM tests (LM, HC0-HC3){p_end}
{synopt:{opt hc(list)}}versions displayed: any of {cmd:lm hc0 hc1 hc2 hc3} (default all){p_end}
{synopt:{opt port:manteau(h)}}multivariate portmanteau (Ljung-Box type) test{p_end}
{synopt:{opt varprof:ile}}variance profiles of the residuals{p_end}
{synopt:{opt roots}}moduli of the companion matrix of the fitted model{p_end}
{synopt:{opt spread:garch}}EXTENDED: two-step GARCH(1,1) on the estimated
error-correction terms (requires 0 < {it:r} < {it:p}){p_end}

{syntab:Bootstrap}
{synopt:{opt boot:strap}}bootstrap p-values for {cmd:march()}, {cmd:et()}, {cmd:etst()}
(parametric) and {cmd:aclm()} (wild){p_end}
{synopt:{opt r:eps(#)}}replications; default {cmd:499}; minimum 19{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt mult:iplier(string)}}wild multiplier for {cmd:aclm()}: {cmd:rademacher}
(default), {cmd:gauss}, {cmd:mammen}{p_end}
{synopt:{opt wb:type(string)}}{cmd:recursive}, {cmd:fixed} or {cmd:both} (default){p_end}
{synopt:{opt nodots}}suppress replication dots{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}level for the stars; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}plot the variance profiles against the 45-degree line (implies
{cmd:varprofile}){p_end}
{synopt:{opt graphn:ame(name)}}graph name; default {cmd:cointvol_varprofile}{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required. The data must be {helpb tsset} as a time series
without gaps; {it:varlist} may contain time-series operators. If no test option is
given, {cmd:archlm(2) march(2) aclm(2) varprofile roots} are run.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol diag} fits the Gaussian VECM

{p 8 8 2}
dX_t = alpha beta*'(X_'_{t-1}, D1_t')' + Gamma_1 dX_{t-1} + ... + Gamma_{k-1} dX_{t-k+1}
+ Phi D2_t + e_t

{pstd}
by Johansen reduced-rank regression under rank {it:r} (with the core engine of
{cmd:cointvol}; {it:r} = {it:p} gives the unrestricted VAR in levels) and runs a battery
of diagnostics on the residuals e_t. The purpose is to document the features that
make the {cmd:cointvol} estimators and bootstrap tests necessary: conditional
heteroskedasticity (ARCH-LM, MARCH, CCC-ARCH, combined LM, Ling-Li portmanteau),
smooth or abrupt changes in the error variances (Eklund-Terasvirta smooth-transition
LM, variance profiles), and remaining serial correlation that must be judged with
heteroskedasticity-robust statistics.

{pstd}
Use it (i) before {helpb cointvol_rank:cointvol rank} to choose between the i.i.d. and
wild bootstrap and to check the lag order, and (ii) after estimation to check the
residuals of the selected model. It does not test the cointegration rank.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} lag order {it:k} of the levels VAR ({it:k} - 1 lagged differences).

{phang}
{opt trend(string)} deterministic case, as in {helpb vec}: {cmd:none},
{cmd:rconstant} (constant restricted to the cointegration space, default),
{cmd:constant}, {cmd:rtrend}, {cmd:trend}.

{phang}
{opt rank(#)} rank {it:r} imposed by reduced-rank regression, 0 {ul:<} {it:r} {ul:<} {it:p}.
Default {it:r} = {it:p}.

{dlgtab:Tests}

{phang}
{opt archlm(h)} Original: Engle (1982). (T - h) R2 of the regression of e_it^2 on a
constant and e_{i,t-1}^2, ..., e_{i,t-h}^2, compared with chi2(h), for each equation.

{phang}
{opt march(h)} Original: Lutkepohl (2006, sec. 16.5); implementation as in VARtests
(Belfrage, Catani and Ahlgren). Computed on the Cholesky-standardised residuals;
chi2 with K^2(K+1)^2 h/4 degrees of freedom; bootstrap p-value with {opt bootstrap}.

{phang}
{opt ca(h)} Original: Catani and Ahlgren (2017). Combined LM statistic max_i LM_i,
LM_i = N R2_i from the Engle regression on the i-th standardised residual. Its
null distribution is not chi2; the parametric bootstrap p-value is always computed
({opt reps()} draws). Equation-by-equation LM_i with asymptotic and bootstrap
p-values are also shown.

{phang}
{opt et(h)} Original: Eklund and Terasvirta (2007), LM statistic (14) built from
Theorem 1, eqs. (12)-(13), with the CCC-ARCH({it:h}) alternative (6)/(23) and h_i the
identity. Computed on the model residuals e_t, with the nuisance parameters (variances
and correlations) at their Gaussian ML values under H0; chi2(K h).

{phang}
{opt etchol} Extended implementation (VARtests convention): {cmd:et()} is computed on the
Cholesky-standardised residuals w_t with sample-moment nuisance values, as in
{cmd:computeET_LM} of VARtests (Catani and Ahlgren 2017). Use it only to reproduce
VARtests output; the default is the statistic of the paper.

{phang}
{opt etst(s)} Original ({it:s} = 1): Eklund and Terasvirta (2007, sec. 5.3), LM test of
constant variances against smoothly and monotonically changing variances,
omega_iit = sigma_i^2 + lambda_i F_i(gamma_i(t/T - c_i)), F logistic (eqs. 24, 28-29),
through the first-order Taylor approximation (26)-(27): v_it = (1, t/T)'; chi2(K).
{it:s} = 2, 3, 4: extended, v_it = (1, t/T, ..., (t/T)^s)' (higher-order polynomial,
suggested on p. 762 of the paper); chi2(K s).

{phang}
{opt lingli(M)} Original: Ling and Li (1997). Portmanteau test on the autocorrelations
R_l, l = 1..M, of q_t = e_t' V_t^-1 e_t (eq. 2.11). Without {opt llvcov()}, V_t is the
unconditional ML covariance E'E/T: then X = 0 in their Theorem and Q(M) = T sum R_l^2 is
asymptotically chi2(M) (eq. 3.10 with Omega = I_M), a multivariate McLeod-Li test for
(G)ARCH effects in the VAR/VECM residuals. Also reported: the finite-sample version
(4.6), factor (T - M - 2K - k - q + 1), with k the levels lag order and q = {opt llarch()}.
Ling and Li suggest M = k + r + 1 for an AR(k)-ARCH(r) model.

{phang}
{opt llarch(r)} Original: Ling and Li (1997, eq. 3.11): Q(r,M) = T sum_{l=r+1}^M R_l^2,
chi2(M - r), for a V_t of multivariate linear ARCH({it:r}) form; default 0 (not shown).

{phang}
{opt llvcov(varlist)} passes a fitted conditional covariance matrix V_t (for example
from {cmd:mgarch} {cmd:predict, variance} or from {cmd:cointvol vecmgarch}) as K(K+1)/2
variables in vech order, v11 v21 ... vK1 v22 v32 ... vKK (for K = 2: v11 v21 v22).
They must be nonmissing on the effective sample t = k+1, ..., T0 and V_t must be
positive definite. See Remarks for what is and is not computed in that case.

{phang}
{opt aclm(h)} Original: Ahlgren and Catani (2017). LM test of no residual
autocorrelation up to lag {it:h} and its HCCME versions HC0-HC3; chi2(h K^2). With
{opt bootstrap}, wild bootstrap p-values from the recursive design (the fitted VECM is
re-simulated from the data initial values with multiplied residuals and re-estimated
with rank {it:r}) and the fixed design (regressors held fixed).

{phang}
{opt hc(list)} selects the rows of the autocorrelation table that are displayed; all
five are always computed and returned.

{phang}
{opt portmanteau(h)} Original: Lutkepohl (2006, secs. 4.4.3 and 8.4.1). Q_h and the
small-sample adjusted Q_h; chi2 with K^2(h - k + 1) - K r degrees of freedom
(= K^2(h - k) for the unrestricted VAR). Requires positive degrees of freedom.

{phang}
{opt varprofile} Original: Cavaliere, Rahbek and Taylor (2010, JoE, sec. 6), after
Cavaliere and Taylor (2007). Reports max_u |eta_i(u) - u| and its location.

{phang}
{opt roots} moduli of the companion matrix of the fitted model, with the number of unit
roots (should equal {it:p} - {it:r}) and explosive roots.

{phang}
{opt spreadgarch} Extended implementation (contrast case; see Remarks). For each
error-correction term ECT_j = beta_j*'(X_'_{t-1}, D1_t')', with beta normalised
on the first {it:r} variables, fits a GARCH(1,1) with {helpb arch} and reports omega,
the ARCH and GARCH coefficients, persistence a + b, half-life ln(0.5)/ln(a + b), log
likelihood and convergence. The user's {cmd:e()} results are preserved.

{dlgtab:Bootstrap}

{phang}
{opt bootstrap} adds bootstrap p-values for {cmd:march()}, {cmd:et()} and {cmd:etst()}
(parametric, Catani and Ahlgren Algorithm 1; Eklund and Terasvirta 2007, sec. 6.1,
recommend parametric-bootstrap p-values for ET) and for {cmd:aclm()} (wild).
{cmd:ca()} always uses the bootstrap. {cmd:lingli()} is asymptotic only.

{phang}
{opt reps(#)} number of bootstrap samples; default 499.

{phang}
{opt seed(string)} sets the Stata random-number seed.

{phang}
{opt multiplier(string)} wild-bootstrap multiplier w_t: {cmd:rademacher} (default, as in
Ahlgren and Catani 2017), {cmd:gauss} (N(0,1)) or {cmd:mammen} (two-point).

{phang}
{opt wbtype(string)} {cmd:recursive}, {cmd:fixed} or {cmd:both} (default).

{dlgtab:Reporting}

{phang}
{opt level(#)}; a star marks p-values below 1 - level/100.

{phang}
{opt graph} draws the variance profiles of all equations with the 45-degree line (white
background); {opt graphname()} names the graph.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model.} Z0_t = dX_t, Z1_t = (X_'_{t-1}, D1_t')', Z2_t = (dX_'_{t-1}, ...,
dX_'_{t-k+1}, D2_t')', t = k+1, ..., T0; T = T0 - k. Johansen reduced-rank regression
with rank {it:r} gives alpha, beta*, Psi = (Gamma_1, ..., Gamma_{k-1}, Phi) and residuals
e_t, which coincide with the OLS residuals of Z0_t on Zr_t = (beta*'Z1_t, Z2_t). K = {it:p}
denotes the number of equations and N = T.

{pstd}
{bf:Standardisation.} Sigma = T^-1 sum e_t e_t' = L L' (Cholesky); w_t = L^-1 e_t.

{pstd}
{bf:ARCH-LM (Engle 1982).} Regress e_it^2 on (1, e_{i,t-1}^2, ..., e_{i,t-h}^2),
t = h+1, ..., T; LM_i = (T - h) R2_i ~ chi2(h) under H0: no ARCH.

{pstd}
{bf:MARCH.} u_t = vech(w_t w_t') (K(K+1)/2 elements). Regress u_t on
(1, u_'_{t-1}, ..., u_'_{t-h}), t = 1, ..., N, with zero pre-sample values;
Omega_res = residual cross-product, Omega_0 = centred cross-product of u_t;
MARCH = 0.5 N K(K+1) - N tr(Omega_res Omega_0^-1) ~ chi2(K^2(K+1)^2 h/4).

{pstd}
{bf:Combined LM (Catani and Ahlgren 2017).} LM_i = N R2_i from the Engle regression on
w_it^2; CA = max_i LM_i, equivalent to 1 - min_i p(LM_i) because all LM_i have h degrees
of freedom. Parametric bootstrap (Algorithm 1, Gaussian errors): for b = 1..B,
(1) draw w*_t ~ N(0, I_K) i.i.d.; (2) U*_t = L w*_t; (3) Y*_t = fitted values + U*_t;
(4) regress Y*_t on the fixed regressors Zr_t, obtain e*_t, standardise with its own
Cholesky factor; (5) compute LM*_i, CA*, MARCH*, ET*. p = (#{c -(}CA* {ul:>} CA{c )-} + 1)/(B + 1).
The same draws give the bootstrap p-values of MARCH and ET under {opt bootstrap}.

{pstd}
{bf:ET (Eklund and Terasvirta 2007).} Error covariance Omega_t = D_t P D_t (eqs. 3, 8),
D_t = diag(omega_11t^1/2, ..., omega_KKt^1/2), omega_iit = phi_i'v_it (eq. 2 with h_i
the identity), P constant; theta = (phi_1', ..., phi_K', rho')'. H0: omega_iit =
sigma_i^2 (eq. 4). Alternatives: CCC-ARCH(h), v_it = (1, e_{i,t-1}^2, ..., e_{i,t-h}^2)'
(eqs. 6, 23; t = h+1, ..., T, the first h residuals are presample); smooth transition,
v_it = (1, t/T)' (eqs. 24, 27-29). The nuisance parameters take their ML values under H0
on the sample used, Omega~ = n^-1 sum e_t e_t' = D P D, so that their scores vanish. With
z_t = D^-1 e_t and dvec(D_t^-1)/dphi_i' = -v_it'/(2 D_ii^3) (Appendix B, eq. B.3), the
variance block of the score (12) is, for phi_i, sum_t x_it g_it with
x_it = -v_it/(2 D_ii^3) and g_it = D_ii - e_it (P^-1 z_t)_i, and for rho_ab,
sum_t (P^-1 z_t z_t' P^-1 - P^-1)_ab. The information (13) has blocks
[D_ii^2 1(i=j) + (P^-1)_ij Omega_ij] sum_t x_it x_jt' (from D (x) D + (P^-1 (x) Omega +
Omega (x) P^-1)/2), -(sum_t x_it)[D_ii (P^-1)_ia 1(i=b) + D_ii (P^-1)_ib 1(i=a)]
(cross block), and (P^-1)_ac(P^-1)_bd + (P^-1)_ad(P^-1)_bc (correlation block).
LM = T s_T' I_T^-1 s_T (eq. 14), asymptotically chi2 with p1 + ... + pK degrees of
freedom: K h (ARCH), K (smooth transition, s = 1), K s (polynomial of order s).
With {opt etchol}, e_t is replaced by w_t and the moments by sample moments over all
T residuals (VARtests).

{pstd}
{bf:Ling-Li portmanteau (Ling and Li 1997).} Model Y_t - mu_t = e_t = V_t^1/2 eta_t
(eqs. 2.1-2.2). q_t = e_t' V_t^-1 e_t, E q_t = K; R_l = sum_{t=l+1}^T (q_t - K)
(q_{t-l} - K) / sum_{t=1}^T (q_t - K)^2 (eq. 2.11); sqrt(T) R -> N(0, Omega),
Omega = I_M - X(cB^-1 - B^-1 A B^-1)X'/(cK)^2 (Theorem); Q(M) = T R' Omega^-1 R ~ chi2(M)
(eq. 3.10). When V_t is constant, X = 0 and Omega = I_M exactly (p. 453), so
Q(M) = T sum_{l=1}^M R_l^2; this is the statistic computed here with V_t = E'E/T.
Q(r,M) = T sum_{l=r+1}^M R_l^2 ~ chi2(M - r) (eq. 3.11). Finite-sample versions (eq. 4.6)
replace T by T - M - 2K - k - q + 1.

{pstd}
{bf:Autocorrelation (Ahlgren and Catani 2017).} E_t^(h) = (e_'_{t-1}, ..., e_'_{t-h})'
with zero pre-sample values. LM = vec(E'E^(h))' [S^-1 (x) Sigma^-1] vec(E'E^(h)),
S = E^(h)'M_Z E^(h) (Breusch-Godfrey form, their eqs. 8-9). HCCME versions: regress e_t
on x_t = (Zr_t', E_t^(h)')'; psi = coefficients on E^(h); covariance of psi from the
psi-block of (X'X)^-1 [sum_t x_t x_t' (x) e_t e_t'] (X'X)^-1 (their eq. 11);
HC0 uses e_t e_t', HC1 multiplies HC0 by (T - m)/T (m = number of model regressors),
HC2 uses e_t e_t'/(1 - l_t), HC3 e_t e_t'/(1 - l_t)^2, l_t = leverage of Zr_t;
Q = psi' V^-1 psi ~ chi2(h K^2). Wild bootstrap: e*_t = w_t e_t, w_t i.i.d. from the
chosen multiplier (one scalar per t, shared across equations).
Recursive design (Algorithm 1): X*_t is generated from the fitted VECM with data initial
values and deterministic terms, then the VECM of rank {it:r} is re-estimated by Johansen
RRR and the statistics recomputed. Fixed design (Algorithm 2): Y*_t = fitted + e*_t,
residuals from the regression on the original Zr_t. p = (#{c -(}Q* {ul:>} Q{c )-} + 1)/(B + 1).

{pstd}
{bf:Portmanteau.} C_j = T^-1 sum_{t>j} e_t e_'_{t-j};
Q_h = T sum_{j=1}^h tr(C_j' C_0^-1 C_j C_0^-1); adjusted
Q*_h = T^2 sum_j tr(.)/(T - j); chi2(K^2(h - k + 1) - K r).

{pstd}
{bf:Variance profile.} eta_i(u) = sum_{t=1}^{floor(Tu)} e_it^2 / sum_{t=1}^T e_it^2,
u in [0,1]. Under constant variance eta_i(u) = u; a break upward at tau pushes the
profile below the 45-degree line.

{pstd}
{bf:Roots.} Levels VAR A_1 = I + Pi + Gamma_1, A_j = Gamma_j - Gamma_{j-1},
A_k = -Gamma_{k-1}; moduli of the eigenvalues of the companion matrix (core routine
{cmd:cv_roots}).

{pstd}
{bf:Step -> source map.} fit: Johansen (1996), CRT (2010) eqs. (3), (7); ARCH-LM: Engle
(1982); MARCH: Lutkepohl (2006) sec. 16.5; CA: Catani and Ahlgren (2017) Algorithm 1;
ET: Eklund and Terasvirta (2007) Theorem 1, eqs. (12)-(14), (6), (23), (24)-(29), (B.3);
Ling-Li: Ling and Li (1997) eqs. (2.11), (3.10), (3.11), (4.6);
AC: Ahlgren and Catani (2017) eqs. (6), (8), (9),
(11), Algorithms 1-2; portmanteau: Lutkepohl (2006) sec. 8.4.1; variance profile:
CRT (2010, JoE) sec. 6; spread GARCH: extended (contrast case, Yang 2026).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Original vs extended.} archlm, march, ca, et, etst(1), lingli, llarch, aclm (LM,
HC0-HC3, both wild bootstraps), portmanteau, varprofile and roots are original methods
from the cited papers. {cmd:etchol} (VARtests convention) and {cmd:etst()} with
{it:s} > 1 are extended. {cmd:spreadgarch} is an extended convenience: a two-step univariate GARCH on a
generated regressor. It ignores the estimation error in beta and the interaction
between the mean and the variance, which the joint VECM-GARCH estimators of
{cmd:cointvol vecmgarch} and {cmd:cointvol garchrank} are designed to handle; it is
reported only as the contrast case discussed in the literature.

{pstd}
{bf:VECM regressors.} In a VECM of rank {it:r} < {it:p}, the auxiliary regressions of
the ARCH and autocorrelation tests use Zr_t = (beta*'Z1_t, Z2_t), i.e. beta is treated
as known (super-consistent). For {it:r} = {it:p} this is exactly the regressor set of
the unrestricted levels VAR used by VARtests.

{pstd}
{bf:Deviations from VARtests (algorithm reference, GPL; no code copied).} (i) HC1 uses
the MacKinnon-White factor N/(N - m) with m the number of regressors per equation of the
fitted model (the package manual's description); the VARtests C++ code uses
N/(N - K - 1). (ii) In the ET score and information the derivatives are written for a
general diagonal D; on standardised residuals D is a scalar multiple of I and the two
forms coincide. (iii) The CA statistic is reported as max_i LM_i; VARtests reports
1 - min_i p_i (also returned as {cmd:r(ca_g)}); the bootstrap p-values are identical.
(iv) VARtests applies the ET statistic to w_t with sample moments (n - 1 divisor, all T
rows) while summing the score over t = h+1, ..., T; the paper's statistic (14) uses the
residuals e_t of model (1) and ML nuisance values under H0. The two are asymptotically
equivalent under H0 but differ in finite samples; {cmd:et()} now follows the paper and
{cmd:etchol} reproduces VARtests.

{pstd}
{bf:Eklund-Terasvirta closed form (30).} For K = 2 and the smooth-transition
alternative the paper prints a closed form (30). As printed it is not invariant to the
scale of e_1t and e_2t (it contains sigma_i^4 rather than a scale-free combination), and it
uses the uncentred sum of (t/T)^2 although the information matrix has a non-zero
sigma^2-lambda cross block. {cmd:etst()} therefore evaluates the general statistic (14)
from Theorem 1 directly, as the paper's Remark 1 prescribes; the result is scale invariant
(checked in {cmd:tests/test_diag.do}).

{pstd}
{bf:Ling-Li test after a fitted multivariate GARCH.} The statistic of Ling and Li is
meant for the standardised residuals of a fitted conditional covariance model, as in
Sin, Mi and Ling (2024, Table 6). With {opt llvcov()} the command uses the supplied V_t
in q_t but sets Omega = I_M, because the X, A and B matrices of the Theorem require the
score and Hessian of the fitted variance model. Since the asymptotic standard errors of
R_l are generally below 1/sqrt(T) (p. 453), chi2(M) is then typically conservative;
Q(r,M) (eq. 3.11) is the simple version the authors propose for an ARCH(r) V_t. The
mean-equation residuals are those of the Johansen fit of this command; after a joint
VECM-GARCH fit they differ from the QML residuals in finite samples. The exact Q(M) with
the estimated Omega belongs to the postestimation of {cmd:cointvol vecmgarch}, which has
the required derivatives.

{pstd}
{bf:Bootstrap validity.} The asymptotic validity of the bootstrap MARCH and ET tests has
not been established (VARtests manual); treat them as finite-sample refinements.
The recursive wild bootstrap redraws a sample when the re-estimated model is singular;
the number of redraws is returned in {cmd:r(boot_fail_wild)}.

{pstd}
{bf:Non-normal errors.} Eklund and Terasvirta (2007, sec. 6.1) find that their LM test
over-rejects under t(5) or skewed errors and recommend bootstrap p-values; the Ling-Li
Q(M) does not require normality (only E eta_it^3 = 0 and finite fourth moments).

{pstd}
{bf:Sample size.} MARCH needs T well above 1 + h K(K+1)/2; the HC tests need T well above
m + h K. Keep h small (1-5) in small samples.


{marker examples}{...}
{title:Examples}

{pstd}Simulated cointegrated VAR with GARCH(1,1) errors{p_end}
{phang2}{cmd:. cointvol simulate, nobs(400) dgp(vecm) innov(garch) arch(0.3) garch(0.65) seed(12345) clear}{p_end}

{pstd}Default battery on the unrestricted VAR(2){p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(2)}{p_end}

{pstd}Multivariate ARCH tests with bootstrap p-values{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(2) rank(1) march(2) et(2) ca(2) bootstrap reps(199) seed(1)}{p_end}

{pstd}Covariance-constancy LM tests (CCC-ARCH and smooth transition) and the Ling-Li
portmanteau test with M = k + r + 1 = 4{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(2) rank(1) et(2) etst(1) lingli(4) llarch(1)}{p_end}

{pstd}Ling-Li test with a fitted conditional covariance (here the true CCC variances of
the simulated design, zero correlation){p_end}
{phang2}{cmd:. generate double h12 = 0}{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(2) rank(1) lingli(4) llarch(1) llvcov(h1 h12 h2)}{p_end}

{pstd}Autocorrelation tests with recursive and fixed wild bootstrap{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(2) rank(1) aclm(4) bootstrap reps(199) seed(2) nodots}{p_end}

{pstd}Variance profiles under a late upward variance break (CDRT 2018 case C){p_end}
{phang2}{cmd:. cointvol simulate, nobs(300) dgp(vecm) innov(break) tau(0.6667) varratio(3) seed(3) clear}{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(1) rank(1) varprofile roots graph}{p_end}

{pstd}Contrast case: two-step GARCH on the error-correction term{p_end}
{phang2}{cmd:. cointvol diag y1 y2, lags(1) rank(1) spreadgarch}{p_end}

{pstd}Replication-style check with VARtests' Vodafone CDS data (VARtests example uses a
VAR(3) with constant, h = 5, B = 199){p_end}
{phang2}{cmd:. cointvol diag cds swsp, lags(3) trend(constant) march(5) et(5) etchol ca(5) bootstrap reps(199)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol diag} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}effective observations T{p_end}
{synopt:{cmd:r(p)}}number of variables{p_end}
{synopt:{cmd:r(lags)}}lag order k{p_end}
{synopt:{cmd:r(rank)}}rank r{p_end}
{synopt:{cmd:r(level)}}level{p_end}
{synopt:{cmd:r(ll)}}Gaussian log likelihood of the fitted model{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications (if a bootstrap ran){p_end}
{synopt:{cmd:r(boot_fail_arch)}, {cmd:r(boot_fail_wild)}}redrawn bootstrap samples{p_end}
{synopt:{cmd:r(march)}, {cmd:r(p_march)}, {cmd:r(pb_march)}}MARCH statistic, asymptotic and bootstrap p{p_end}
{synopt:{cmd:r(et)}, {cmd:r(p_et)}, {cmd:r(pb_et)}}ET statistic and p-values{p_end}
{synopt:{cmd:r(etst)}, {cmd:r(p_etst)}, {cmd:r(pb_etst)}}ET smooth-transition LM and p-values{p_end}
{synopt:{cmd:r(lingli)}, {cmd:r(p_lingli)}}Ling-Li Q(M) and p{p_end}
{synopt:{cmd:r(lingli_adj)}, {cmd:r(p_lingli_adj)}}finite-sample Q(M) (eq. 4.6) and p{p_end}
{synopt:{cmd:r(lingli_r)}, {cmd:r(p_lingli_r)}}Q(r,M) and p (if {opt llarch()} > 0){p_end}
{synopt:{cmd:r(llarch)}}r of Q(r,M){p_end}
{synopt:{cmd:r(ca)}, {cmd:r(ca_g)}, {cmd:r(pb_ca)}}max LM_i, 1 - min p_i, bootstrap p{p_end}
{synopt:{cmd:r(aclm)}, {cmd:r(p_aclm)}}AC LM statistic and asymptotic p{p_end}
{synopt:{cmd:r(port)}, {cmd:r(p_port)}}portmanteau Q_h and p{p_end}
{synopt:{cmd:r(h_}{it:test}{cmd:)}}lag order of each test run{p_end}
{synopt:{cmd:r(n_unit)}, {cmd:r(n_explosive)}}unit and explosive companion roots{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol diag}{p_end}
{synopt:{cmd:r(varlist)}, {cmd:r(trend)}}variables, deterministic case{p_end}
{synopt:{cmd:r(multiplier)}, {cmd:r(wbtype)}, {cmd:r(seed)}}bootstrap settings{p_end}
{synopt:{cmd:r(et_type)}}{cmd:residuals} (paper) or {cmd:cholesky} ({opt etchol}){p_end}
{synopt:{cmd:r(llvcov)}}variables passed in {opt llvcov()}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(archlm)}}K x 4: LM, df, p, R2{p_end}
{synopt:{cmd:r(multarch)}}4 x 4 (MARCH, ET, CA, ETST): stat, df, asy. p, boot. p{p_end}
{synopt:{cmd:r(lingli_tab)}}4 x 3 (Q(M), Q(M) adj., Q(r,M), Q(r,M) adj.): stat, df, p{p_end}
{synopt:{cmd:r(lingli_acf)}}M x 3: R_l, 1/sqrt(T), sqrt(T) R_l{p_end}
{synopt:{cmd:r(ca)}}K x 4: LM_i, df, asy. p, boot. p{p_end}
{synopt:{cmd:r(aclm_tab)}}5 x 5 (LM, HC0-HC3): Q, df, asy. p, recursive-WB p, fixed-WB p{p_end}
{synopt:{cmd:r(portmanteau)}}1 x 5: Q, adjusted Q, df, p, adjusted p{p_end}
{synopt:{cmd:r(vprofile)}}T x K variance profiles (if T {ul:<} matsize){p_end}
{synopt:{cmd:r(vprofile_max)}}K x 3: max deviation, its u, signed deviation{p_end}
{synopt:{cmd:r(roots)}}companion moduli{p_end}
{synopt:{cmd:r(alpha)}, {cmd:r(beta)}}estimates (if r > 0){p_end}
{synopt:{cmd:r(spreadgarch)}, {cmd:r(beta_norm)}}GARCH results and normalised beta{p_end}


{marker references}{...}
{title:References}

{phang}
Ahlgren, N., and P. Catani. 2017. Wild bootstrap tests for autocorrelation in vector
autoregressive models. {it:Statistical Papers} 58: 1189-1216.
{browse "https://doi.org/10.1007/s00362-016-0744-0":doi:10.1007/s00362-016-0744-0}.

{phang}
Belfrage, M., with P. Catani and N. Ahlgren. 2025. VARtests: Tests for error
autocorrelation, ARCH errors, and cointegration in vector autoregressive models.
R package version 2.0.7, CRAN.

{phang}
Catani, P., and N. Ahlgren. 2017. Combined Lagrange multiplier test for ARCH in vector
autoregressive models. {it:Econometrics and Statistics} 1: 62-84.
{browse "https://doi.org/10.1016/j.ecosta.2016.10.006":doi:10.1016/j.ecosta.2016.10.006}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010. Testing for co-integration in
vector autoregressions with non-stationary volatility. {it:Journal of Econometrics}
158: 7-24.
{browse "https://doi.org/10.1016/j.jeconom.2010.03.003":doi:10.1016/j.jeconom.2010.03.003}.

{phang}
Cavaliere, G., and A. M. R. Taylor. 2007. Testing for unit roots in time series models
with non-stationary volatility. {it:Journal of Econometrics} 140: 919-947.

{phang}
Eklund, B., and T. Terasvirta. 2007. Testing constancy of the error covariance matrix
in vector models. {it:Journal of Econometrics} 140: 753-780.
{browse "https://doi.org/10.1016/j.jeconom.2006.07.012":doi:10.1016/j.jeconom.2006.07.012}.

{phang}
Engle, R. F. 1982. Autoregressive conditional heteroscedasticity with estimates of the
variance of United Kingdom inflation. {it:Econometrica} 50: 987-1007.

{phang}
Johansen, S. 1996. {it:Likelihood-Based Inference in Cointegrated Vector
Autoregressive Models}. Oxford: Oxford University Press.

{phang}
Ling, S., and W. K. Li. 1997. Diagnostic checking of nonlinear multivariate time series
with multivariate ARCH errors. {it:Journal of Time Series Analysis} 18: 447-464.
{browse "https://doi.org/10.1111/1467-9892.00061":doi:10.1111/1467-9892.00061}.

{phang}
Lutkepohl, H. 2006. {it:New Introduction to Multiple Time Series Analysis}. Berlin:
Springer.

{phang}
Sin, C.-y., Z. Mi and S. Ling. 2024. On a partially non-stationary vector AR model with
vector GARCH noises: estimation and testing. {it:Communications in Mathematical Research}
40(1): 64-101. {browse "https://doi.org/10.4208/cmr.2023-0005":doi:10.4208/cmr.2023-0005}.

{phang}
Yang (2026). Cointegration, spread dynamics, and GARCH-type volatility modeling: an
empirical econometrics framework. SSRN working paper 7025142.
{browse "https://doi.org/10.2139/ssrn.7025142":doi:10.2139/ssrn.7025142}.
(Cited only as an example of the two-step spread-GARCH approach.)


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
