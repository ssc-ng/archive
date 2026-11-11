{smcl}
{* *! version 1.0.0  09nov2026}{...}
{vieweralsosee "csdlp" "help csdlp"}{...}
{vieweralsosee "csdlp postestimation" "help csdlp_postestimation"}{...}
{vieweralsosee "csdlp_graph" "help csdlp_graph"}{...}
{viewerjumpto "Identification" "csdlp_methods##ident"}{...}
{viewerjumpto "Linear LPs" "csdlp_methods##linear"}{...}
{viewerjumpto "Estimation" "csdlp_methods##est"}{...}
{viewerjumpto "Inference" "csdlp_methods##inf"}{...}
{viewerjumpto "Step map" "csdlp_methods##map"}{...}
{viewerjumpto "Decisions" "csdlp_methods##decisions"}{...}
{viewerjumpto "Validation" "csdlp_methods##valid"}{...}
{title:Title}

{phang}
{bf:csdlp methods} {hline 2} Methods, formulas and the step-to-equation map
for {helpb csdlp} (David, Giacomini, Jiao and Wang 2026)


{marker ident}{...}
{title:1. Identification (Section 3)}

{pstd}
Data {c -(}Y_it, X_t, Z_it, W_it{c )-}, i=1..N, t=1..T. Information set
F_{c -(}t-1{c )-} = sigma({c -(}Y_is, Z_is, W_is{c )-}_{c -(}s<=t-1{c )-}, {c -(}X_s{c )-}_{c -(}s<=t-1{c )-}). Potential outcomes
Y_{c -(}i,t+h{c )-}(x). Target: the finite-delta state-dependent IRF

{p 8 8 2}IRF_h(z;delta) = E[Y_{c -(}i,t+h{c )-}(X_t+delta) - Y_{c -(}i,t+h{c )-}(X_t) | Z_{c -(}i,t-1{c )-}=z].{p_end}

{pstd}
Assumptions: (1i) E[Y_{c -(}i,t+h{c )-}(x)|F_{c -(}t-1{c )-},X_t] = E[Y_{c -(}i,t+h{c )-}(x)|F_{c -(}t-1{c )-}];
(1ii) E[X_t|F_{c -(}t-1{c )-}] = 0; (2) Z and W are F_{c -(}t-1{c )-}-measurable;
(3) E[Y_{c -(}i,t+h{c )-}|F_{c -(}t-1{c )-},X_t] = g_h(Z_{c -(}i,t-1{c )-}) X_t + r_{c -(}i,h{c )-}(F_{c -(}t-1{c )-}).
Then IRF_h(z;delta) = g_h(z) delta and

{p 8 8 2}g_h(z) = E[X_t Y_{c -(}i,t+h{c )-} | Z=z] / E[X_t^2 | Z=z].{p_end}

{pstd}
Proposition 1: if the true state is s and Z is any predetermined state, then
g_h(z) = E[w_h(s;z) g~_h(s) | Z=z] with w_h(s;z) = E[X^2|s,Z=z]/E[X^2|Z=z] >= 0,
a convex, variance-weighted subpopulation average.


{marker linear}{...}
{title:2. What the linear-interaction LP estimates (Prop. 2, Lemma 1)}

{pstd}
For Y = (alpha_h + beta_h Z) X + u with true Y = g_h(Z) X + u:

{p 8 8 2}beta_h = E[X^2 (Z - mu) g_h(Z)] / D,   mu = E[X^2 Z]/E[X^2],   D = E[X^2 (Z-mu)^2]{p_end}
{p 8 8 2}beta_h = integral omega_h(z) g_h'(z) dz,   omega_h(z) = E[X^2 (Z-mu) 1{c -(}Z>=z{c )-}]/D >= 0,  integral omega = 1.{p_end}

{pstd}
Under conditional homoskedasticity, beta_h = Cov(Z, g_h(Z))/Var(Z). {cmd:csdlp}
reports the sample analogue of the first expression (column {it:Proj.}) by
plugging in the sieve g_h, and stores omega_h(z) and g_h'(z) on the grid
({cmd:csdlp_graph, lemma}).


{marker est}{...}
{title:3. Sieve estimation (Section 4.1, Algorithm 1)}

{p 8 12 2}Step 1. Cubic B-splines phi_J(z) on [min Z, max Z]; J-4 interior knots at the
empirical quantiles l/(J-3), l=1..J-4; the basis spans the constant.{p_end}
{p 8 12 2}Step 2. Regressors D_it(J) = (X_t phi_J(Z_{c -(}i,t-1{c )-})', W_{c -(}i,t-1{c )-}')' (eq. 7).{p_end}
{p 8 12 2}Step 3. OLS theta_h(J) (eq. 8).{p_end}
{p 8 12 2}Step 4. AIC_h(J) = N(T-h) log(SSR/N(T-h)) + 2 K_J, K_J = J + dim(W) (eq. 10); J in {c -(}4,...,20{c )-}.
Also BIC, GCV_h(J) = (SSR/n)/(1-K_J/n)^2, and LASSO (Section 5).{p_end}
{p 8 12 2}Step 5. g_h(z) = phi_J(z)' b_h at the selected J (eq. 12).{p_end}


{marker inf}{...}
{title:4. Inference (Section 4.2)}

{pstd}
Partialled-out sieve regressor and score (eq. 13-14):

{p 8 8 2}P~_{c -(}h,i,t{c )-} = X_t phi(Z_{c -(}i,t-1{c )-}) - A12 A22^-1 W_{c -(}i,t-1{c )-},   s_{c -(}h,t{c )-} = N^(-1/2) sum_i P~_{c -(}h,i,t{c )-} u_{c -(}i,t+h{c )-}{p_end}

{pstd}
Long-run covariance (eq. 15), Bartlett weights w_k = 1-k/(L+1),
L_h = floor(4((T-h)/100)^(2/9)); variance (eq. 16)
V_h = [N(T-h)]^-1 A~11^-1 Omega_h A~11^-1, A~11 = A11 - A12 A22^-1 A21.
Pointwise: sigma_h^2(z) = phi(z)'V_h phi(z), I_h(z) = g_h(z) +/- z_{c -(}1-a/2{c )-} sigma_h(z) (eq. 17-18).

{pstd}
Uniform band (eq. 19-21): for b=1..B draw xi ~ N(0,I_J),
G(z_m) = phi(z_m)' V^(1/2) xi, T_b = max_m |G(z_m)/sigma_h(z_m)|, c = (1-a)
quantile of T_b; C_h(z) = g_h(z) +/- c sigma_h(z). Studentising keeps the
process non-degenerate when the rate of convergence varies with z (Theorem 2).


{marker map}{...}
{title:5. Step -> equation map (code in csdlp.ado)}

{p2colset 6 34 36 2}{...}
{p2col:{bf:Code}}{bf:Paper}{p_end}
{p2col:{cmd:_csdlp_knots()}}Alg. 1 step 1: quantile knots{p_end}
{p2col:{cmd:_csdlp_bs()}}eq. (6): cubic B-splines; local de Boor evaluation, checked equal (to 1e-15) to the Cox-de Boor recursion {cmd:_csdlp_bsref()}{p_end}
{p2col:{cmd:X :* Phi}, {cmd:WJ}}eq. (7){p_end}
{p2col:{cmd:_csdlp_ols()}: bb}eq. (8){p_end}
{p2col:{cmd:ic[.,3..5]}}eq. (10)-(11) and Section 5 (BIC, GCV){p_end}
{p2col:{cmd:_csdlp_lassoJ}}Section 5 LASSO selector (J_lasso = 50){p_end}
{p2col:{cmd:Pt = D1 - W(W'W)^-1 W'D1}}eq. (13) (FWL: identical to A12 A22^-1){p_end}
{p2col:{cmd:S = panelsum(Pt:*u)} by time}eq. (14) times N^(1/2){p_end}
{p2col:{cmd:Om}, Bartlett loop}eq. (15) times (T-h){p_end}
{p2col:{cmd:V = Mi*Om*Mi}}eq. (16): the 1/(N(T-h)) and N^(-1/2) factors cancel exactly, so V = (sum P~P~')^-1 Omega_raw (sum P~P~')^-1{p_end}
{p2col:{cmd:se = sqrt(rowsum((Pg*V):*Pg))}}eq. (17){p_end}
{p2col:{cmd:irf[.,5..6]}}eq. (18){p_end}
{p2col:{cmd:_csdlp_supt()}}eq. (19)-(21), V^(1/2) by symmetric eigen-decomposition{p_end}
{p2col:{cmd:philin}, linear fit}eq. (2b), (26){p_end}
{p2col:{cmd:bproj}, {cmd:om}, {cmd:gp}}Lemma 1 / Proposition 2{p_end}
{p2col:{cmd:_csdlp_lcdiff()}}Section 6.1 and footnote 17 (differential IRFs){p_end}
{p2col:{cmd:_csdlp_aggm()}}Section 6.2 (aggregate responsiveness){p_end}


{marker decisions}{...}
{title:6. Decisions the paper leaves open}

{phang}
(a) Quantile rule for the knots: linear interpolation of order statistics;
duplicate knots (discrete states) are merged, which lowers the effective J
(column 2 of {cmd:e(ic_h#)}).

{phang}
(b) Constant in W: eq. (3) has none; {cmd:csdlp} adds one unless
{cmd:noconstant} or {cmd:absorb()} is given. Because E[X]=0, this does not
affect identification.

{phang}
(c) Absorbed common component (Section 6): when the FE absorb X_t, the basis
is reparametrised as phi_j - mean(phi_j), j=2..J. This spans the same space
modulo the absorbed constant, and fixes g_h to have zero sample mean. The
linear function becomes beta_h (z - zbar).

{phang}
(d) Intermediate shocks: X_{c -(}t+j{c )-} phi_J(Z_{c -(}i,t-1{c )-}), j=1..h, with the same J,
treated as part of W in eq. (13).

{phang}
(e) Auxiliary Wald tests. A cubic spline with knot vector t is linear iff its
B-spline coefficients equal a + b t*_j, with Greville abscissae
t*_j = (t_{c -(}j+1{c )-}+t_{c -(}j+2{c )-}+t_{c -(}j+3{c )-})/3. The test projects the coefficient vector on
the orthogonal complement of span(1, t*). These tests are not part of the
paper's theory.


{marker valid}{...}
{title:7. Validation}

{pstd}
{cmd:csdlp_mc.do} replicates Section 5. With N=100, T=120, AIC, 50 replications
it gives coverage 0.84 / 0.88 and widths 0.083 / 2.20 at h = 0 / 4, against the
paper's (Table 3) 0.83 / 0.82 and 0.08 / 2.01. With N=500, T=200, one draw,
the widths are 0.026 / 1.32 against 0.03 / 1.30, and the sieve RIMSE beats the
linear LP by orders of magnitude at h=0, as in Table 2.


{title:Author}

{pstd}
Dr Merwan Roudane, {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com},
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
