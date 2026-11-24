{smcl}
{* *! version 1.0.0  23nov2026}{...}
{vieweralsosee "xtdosekc" "help xtdosekc"}{...}
{viewerjumpto "Model" "xtdosekc_methods##model"}{...}
{viewerjumpto "Static estimation" "xtdosekc_methods##static"}{...}
{viewerjumpto "Dynamic estimation" "xtdosekc_methods##dynamic"}{...}
{viewerjumpto "Optimiser" "xtdosekc_methods##optim"}{...}
{viewerjumpto "Smoother" "xtdosekc_methods##smoother"}{...}
{viewerjumpto "Bootstrap" "xtdosekc_methods##bootstrap"}{...}
{viewerjumpto "Turning point" "xtdosekc_methods##tp"}{...}
{viewerjumpto "Diagnostics" "xtdosekc_methods##diag"}{...}
{viewerjumpto "Step map" "xtdosekc_methods##map"}{...}
{viewerjumpto "Validation" "xtdosekc_methods##validation"}{...}
{title:Title}

{p2colset 5 26 28 2}{...}
{p2col:{bf:xtdosekc methods} {hline 2}}Methods and formulas, with the step-to-equation map{p_end}
{p2colreset}{...}

{pstd}
Equation numbers refer to Amoroso, Garcia-Martos and Koopman (2026). Code references
refer to the Mata functions at the bottom of {cmd:xtdosekc.ado} and to the authors'
R replication package ({cmd:R/01_helper_functions.R}, scripts 04-10).


{marker model}{...}
{title:1. Model}

{pstd}For units i = 1..N and periods t = 1..T, with logistic sigma(x; c, s) = 1/(1 + exp(-s(x - c))), eq. (2.2):

{p 8 8 2}(2.1)  y_it = mu_i + gamma [ sigma(x_it; c1, s1) - sigma(x_it; c2, s2) ] + eps_it{p_end}
{p 8 8 2}(2.3)  y_it = mu_i + tau_it + gamma [ ... ] + eps_it,  tau_i,t+1 = tau_it + eta_it{p_end}

{pstd}with eps ~ (0, sigma_eps^2), eta ~ (0, sigma_eta^2), tau_i1 diffuse, s1, s2 > 0 and
c1 < c2. The Regional model replaces c2 by c2 + delta for units with {opt shift()} != 0.
{opt model(trend)} replaces mu_i by mu_i + delta_i t.


{marker static}{...}
{title:2. Static estimation (Sections 3.1, 4.2-4.3)}

{pstd}Minimise S_eps(psi) = sum_i sum_t eps_it^2 (eq. 3.2) by L-BFGS-B, parameterised as in
the replication code: c2 = c1 + c2gap + 0.001, lower bounds 1e-6 on gamma, c1, c2gap, s1,
s2; the fixed effects (and trend slopes) are free. Starting values are the R defaults:
mu_i = unit means, gamma = range(y), c1 and c2 = the 25% and 70% quantiles of the
integer-step sequence min(x):max(x), s1 = s2 = 1. The Gaussian log-likelihood
-n/2 [ln 2 pi + ln(SSR/n) + 1] is reported for comparisons (Table S3).


{marker dynamic}{...}
{title:3. Dynamic estimation (Section 3.2)}

{pstd}For a candidate psi = (gamma, c1, c2[, delta], s1, s2, ln sigma_eps, ln sigma_eta):

{p 8 8 2}(3.3)  z_it = y_it - gamma [ sigma1 - sigma2 ]{p_end}
{p 8 8 2}(3.5)  mu_i = (1/T) sum_t z_it,   z*_it = z_it - mu_i  (fixed effects concentrated out){p_end}
{p 8 8 2}(3.6)-(3.7)  z*_t = alpha_t + eps_t,  alpha_t+1 = alpha_t + eta_t  (Z = T = R = I_N, H = sigma_eps^2 I, Q = sigma_eta^2 I){p_end}

{pstd}Because H and Q are scalar multiples of I_N and every trend starts diffuse, the N
filters share P_t, F_t and K_t. With exact diffuse initialisation the first observation
only initialises the state (a_2 = z_1, P_2 = sigma_eps^2 + sigma_eta^2) and contributes
nothing to the likelihood, exactly as in KFAS:

{p 8 8 2}(3.9)  ln L = -1/2 sum_{t=2..T} [ N (ln 2 pi + ln F_t) + sum_i v_it^2 / F_t ],{p_end}
{p 8 8 2}F_t = P_t + sigma_eps^2,  K_t = P_t/F_t,  a_t+1 = a_t + K_t v_t,  P_t+1 = P_t (1 - K_t) + sigma_eta^2.{p_end}

{pstd}The objective (3.10)-(3.11) is

{p 8 8 2}S_v = -ln L + lambda_snr 1(sigma_eta > 0.5 sigma_eps)(sigma_eta - 0.5 sigma_eps)^2 + lambda_ekc 1(gamma < 1)(1 - gamma)^2,{p_end}

{pstd}set to 1e10 when c1 >= c2 (or c1 >= c2 + delta). The reported log-likelihood is -S_v
(the "maximised, penalised log-likelihood" of Table 2).


{marker optim}{...}
{title:4. Optimiser}

{pstd}{cmd:dos_lbfgsb()} is a port of L-BFGS-B version 2.3 as shipped with R
({cmd:optim(method = "L-BFGS-B")}): generalized Cauchy point with heap-sorted breakpoints,
direct primal subspace minimisation with backtracking into the box, compact limited-memory
BFGS matrices (m = 5), More-Thuente line search (ftol = 1e-3, gtol = 0.9, xtol = 0.1),
relative-reduction stopping rule factr x eps with factr = 1e7, and pgtol = 0. The gradient
is R's central difference with step 1e-3, shortened at the bounds. Bounds are those of the
replication code: gamma >= 1, c1, c2 >= min(x), s1, s2 in [1e-3, 5], ln sigma_eps in
[-10, -0.7], ln sigma_eta in [-10, -2.5], delta in [-2, 2].

{pstd}Mata's {cmd:optimize()} would give a slightly different point on these flat surfaces;
the port is what makes the published numbers reproducible.


{marker smoother}{...}
{title:5. Smoother and trend extraction (Section 3.3, eq. 3.12)}

{pstd}Backward recursions for t = T..2 with r_T = 0, N_T = 0:
r_t-1 = v_t/F_t + (1 - K_t) r_t,  N_t-1 = 1/F_t + (1 - K_t)^2 N_t,
tau_t = a_t + P_t r_t-1,  V_t = P_t - P_t^2 N_t-1;
and for the diffuse step tau_1 = z_1 + sigma_eps^2 r_1, V_1 = sigma_eps^2 - sigma_eps^4 N_1.
The residual is e_it = z*_it - tau_it = y_it - mu_i - DoS - tau_it (Table 3), and the
structural points of Figures 6-7 are y_it - mu_i - tau_it.


{marker bootstrap}{...}
{title:6. Bootstrap (Section 3.4)}

{pstd}As in {cmd:prepare_bootstrap()}, {cmd:generate_y_star()} and {cmd:run_bootstrap()}:

{p 8 12 2}1. At psi-hat, collect the (T - 1) x N innovations v_t (t >= 2) and their sample covariance S.{p_end}
{p 8 12 2}2. Whiten with the symmetric root S^(-1/2) and centre each column.{p_end}
{p 8 12 2}3. Draw (T - 1) N elements with replacement from all whitened innovations, recolour with S^(1/2).{p_end}
{p 8 12 2}4. Rebuild z*_1 = 0, z*_t = zhat_t|t-1 + v*_t, zhat_t+1|t = zhat_t|t-1 + K_t v*_t; add back the DoS curve and mu_i.{p_end}
{p 8 12 2}5. Re-estimate with identical start values, bounds, penalties and optimiser settings; discard non-converged draws and draws with gamma > 15 (and delta < -1.5); repeat until B draws are kept.{p_end}

{pstd}SEs are standard deviations of the draws, intervals are type-7 percentiles, and the
contrasts and turning points are recomputed for every draw.


{marker tp}{...}
{title:7. Turning point (Section 2.1)}

{pstd}x* = argmax DoS(x) over [min x, max x] of the estimation sample, by Brent's
golden-section/parabolic search (R {cmd:optimize}, tol = eps^(1/4)). It is reported only
when it lies strictly inside the range (more than 0.001 from either end), as in Table 2.


{marker diag}{...}
{title:8. Diagnostics and factor model}

{pstd}Per unit: ACF(1) with denominator sum (e - e-bar)^2; Ljung-Box(1) Q = n(n + 2) r1^2/(n - 1);
ADF of {cmd:tseries::adf.test(k = 1)}: regression of Delta e_t on e_t-1, constant, trend and
Delta e_t-1, with the p-value interpolated in the Banerjee et al. (1993) table (bounded in
[0.01, 0.99]); Shapiro-Wilk from Stata's {cmd:swilk} (Royston), which matches R's
{cmd:shapiro.test}. The dynamic factor model (Pena and Box 1987) uses the eigen-decomposition
of cov(tau): loadings Lambda = E_r diag(sqrt lambda_r), factors F = tau E_r, with signs chosen
so that loadings sum to a positive number.


{marker map}{...}
{title:9. Step-to-equation map}

{p2colset 5 24 26 2}{...}
{p2col:{bf:Mata function}}{bf:paper / replication code}{p_end}
{p2col:{cmd:dos_curve}}eqs (2.1)-(2.2){p_end}
{p2col:{cmd:dos_obj_ssr}}eq (3.2); {cmd:loss_fn}, {cmd:loss_fn_fe}, {cmd:loss_fn_fe_trend}{p_end}
{p2col:{cmd:dos_obj_dyn}}eqs (3.3)-(3.5), (3.10)-(3.11); {cmd:objective_fn_tw}, {cmd:objective_function_regional_c2}{p_end}
{p2col:{cmd:dos_llf}}eqs (3.6)-(3.9); KFAS {cmd:logLik}{p_end}
{p2col:{cmd:dos_lbfgsb}}Section 3.2; R {cmd:optim(method = "L-BFGS-B")}{p_end}
{p2col:{cmd:dos_grad}}R {cmd:optim} finite-difference gradient{p_end}
{p2col:{cmd:dos_kfs}}eq (3.12); KFAS {cmd:KFS}{p_end}
{p2col:{cmd:dos_boot}}Section 3.4; {cmd:prepare_bootstrap}, {cmd:generate_y_star}, {cmd:run_bootstrap}{p_end}
{p2col:{cmd:dos_tp}}Section 2.1; {cmd:turning_point}{p_end}
{p2col:{cmd:dos_adf}, {cmd:dos_ljungbox}}Figure 5, Table 3; {cmd:res_diagnostics}{p_end}
{p2col:{cmd:dos_cd}}Table S7; {cmd:plm::pcdtest}{p_end}
{p2colreset}{...}


{marker validation}{...}
{title:10. Validation against the paper}

{p2colset 5 34 36 2}{...}
{p2col:{bf:Quantity}}{bf:paper / xtdosekc}{p_end}
{p2col:Global gamma, c1, c2}3.715 1.106 4.564 / 3.715 1.106 4.564{p_end}
{p2col:Global s1, s2, x*}1.040 4.501 3.631 / 1.040 4.501 3.631{p_end}
{p2col:Global log-likelihood}984.83 / 984.83{p_end}
{p2col:Regional c2, c2(Eur), x*, x*(Eur)}4.935 4.492 3.779 3.406 / 4.935 4.492 3.779 3.406{p_end}
{p2col:Regional log-likelihood}992.39 / 992.39{p_end}
{p2col:E7 gamma, c2, LL}9.132 5.518 459.41 / 9.115 5.524 459.41{p_end}
{p2col:G7 gamma, c1, x*, LL}6.092 4.215 3.645 516.43 / 6.088 4.210 3.645 516.43{p_end}
{p2col:Table 3 Argentina LB, ADF, SW}0.1360 0.0100 0.4764 / 0.1360 0.0100 0.4765{p_end}
{p2col:Figure 1 turning point}6.01 / 6.0115{p_end}
{p2colreset}{...}

{pstd}A simulated panel with known parameters is recovered in {cmd:xtdosekc_example.do}.


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
