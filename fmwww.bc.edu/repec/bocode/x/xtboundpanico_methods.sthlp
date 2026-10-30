{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "xtboundpanico" "help xtboundpanico"}{...}
{vieweralsosee "xtboundpanico bounds" "help xtboundpanico_bounds"}{...}
{vieweralsosee "xtboundpanico panico" "help xtboundpanico_panico"}{...}
{vieweralsosee "xtboundpanico nfactors" "help xtboundpanico_nfactors"}{...}
{viewerjumpto "Model" "xtboundpanico_methods##model"}{...}
{viewerjumpto "Step to equation map" "xtboundpanico_methods##map"}{...}
{viewerjumpto "Bounds testing" "xtboundpanico_methods##bounds"}{...}
{viewerjumpto "Critical values" "xtboundpanico_methods##cv"}{...}
{viewerjumpto "PANICO" "xtboundpanico_methods##panico"}{...}
{viewerjumpto "p-values" "xtboundpanico_methods##pvalues"}{...}
{viewerjumpto "Factor number" "xtboundpanico_methods##nfac"}{...}
{viewerjumpto "Readings of the paper" "xtboundpanico_methods##readings"}{...}
{viewerjumpto "Numerical validation" "xtboundpanico_methods##validation"}{...}
{viewerjumpto "Limitations" "xtboundpanico_methods##limits"}{...}
{viewerjumpto "Author" "xtboundpanico_methods##author"}{...}

{title:Title}

{phang}
{bf:xtboundpanico methods} {hline 2} equation-by-equation derivation and the
step-to-equation map


{pstd}
Equation numbers refer to Banerjee and Carrion-i-Silvestre (2026), University
of Canterbury Working Paper 8/2026, dated 25 September 2026, unless another
source is named.


{marker model}{...}
{title:Model and assumptions}

{pstd}
Let Y_it = (y_it, x_it')' be a (1+k)-vector of I(1) processes, i = 1..N,
t = 1..T:

{p 8 8 2}
Y_it = D_it + L_i F_t + U_it{col 55}(1){p_end}
{p 8 8 2}
(1 - L) F_t = v_t{col 55}(2){p_end}
{p 8 8 2}
(1 - L) U_it = e_it{col 55}(3){p_end}

{pstd}
D_it = d_t' delta_i with d_t = 0 (Model 0), d_t = 1 (Model 1) or
d_t = (1, t)' (Model 2). F_t is an r-vector of common factors, partitioned as
F_t = (F_0t', F_1t')' with r_0 stationary and r_1 = r - r_0 nonstationary
components according to the rank of C(1) in Assumption B.

{pstd}
Assumptions A-F are those of Bai and Ng (2004) and Banerjee and
Carrion-i-Silvestre (2015, 2017). Assumption C(i) makes the long-run covariance
matrix of e_it positive definite, which rules out cointegration among the
elements of Y_it and places the analysis in a panel spurious regression
framework. Assumption F is the stability condition that delivers the VECM
representation (7). Assumption G is the rank condition
rank(Lbar) = r <= 1+k, needed only by the bounds branch.

{pstd}
Equation (6) imposes a zero lower-left block on the autoregressive matrices,
which is the {bf:weak exogeneity} of x_it maintained throughout, exactly as in
Pesaran, Shin and Smith (2001) and Gengenbach, Urbain and Westerlund (2016).
Equation (10) then imposes {bf:slope homogeneity}: alpha_yi = rho_yi (1, -theta')
with a common theta. The speed of adjustment rho_yi, the factor loadings and the
short-run dynamics stay heterogeneous.


{marker map}{...}
{title:Step to equation map}

{synoptset 34}{...}
{synopthdr:code block}
{synoptline}
{synopt:{bf:_xbp_csamat}}cross-section averages hbar_t{space 10}eq. (1), Assumption G{p_end}
{synopt:{bf:_xbp_cce}}pooled CCE estimator of theta{space 8}eq. (13){p_end}
{synopt:{bf:_xbp_cce} (variance)}HPY sandwich{space 23}HPY (2010) eq. (3.12)-(3.13){p_end}
{synopt:{bf:_xbp_yhat}}yhat_it = thetahat' Y_it{space 10}eq. (14){p_end}
{synopt:{bf:_xbp_ecm_build}}conditional ECM design matrix{space 4}eq. (15), (16){p_end}
{synopt:{bf:_xbp_ols_t}}t-ratio of rho_yi{space 17}eq. (17); 2022 WP appendix{p_end}
{synopt:{bf:_xbp_run_bounds}}tybar = N^-1 sum t_rho_yi{space 9}Section 3{p_end}
{synopt:{bf:_xbp_surface}}finite-sample critical values{space 5}eq. (B.15), Table C.2{p_end}
{synopt:{bf:_xbp_tabc1}}asymptotic critical values{space 8}Corollary 1, Table C.1{p_end}
{synopt:{bf:_xbp_cadf}}CADF / CIPS comparator{space 12}eq. (18){p_end}
{synopt:{bf:_xbp_pca}}defactor D.yhat, recumulate{space 7}eq. (19)-(21){p_end}
{synopt:{bf:_xbp_adfu}}per-unit ADF on uhat*{space 13}eq. (22){p_end}
{synopt:{bf:_xbp_group}}P, Pm, Z{space 26}Theorem 2; BN (2004) Thm 4{p_end}
{synopt:{bf:_xbp_pooled}}Pa, Pb, PMSB{space 22}BN (2010) eq. (6)-(11){p_end}
{synopt:{bf:_xbp_adff}}ADF on Fhat{space 23}BN (2004) Thm 1.2, 3.2{p_end}
{synopt:{bf:_xbp_mq}}MQc, MQf{space 26}BN (2004) Thm 1.3, 3.3, Table I{p_end}
{synopt:{bf:_xbp_ictab}}ICp, PCp, AIC3, BIC3{space 14}BN (2002) eq. (9) and p. 14{p_end}
{synopt:{bf:_xbp_ictab} (ER/GR)}eigenvalue and growth ratios{space 6}AH (2013) Sec. 2, eq. (4){p_end}
{synopt:{bf:_xbp_ed}}edge-distribution estimator{space 7}Onatski (2010) Sec. IV{p_end}
{synopt:{bf:_xbp_rwic}}CA information criterion{space 10}RW (2016) p. 10{p_end}
{synopt:{bf:_xbp_nw}, {bf:_xbp_nuis}}bandwidth and nuisance set{space 8}BN (2010) eq. (4){p_end}
{synoptline}


{marker bounds}{...}
{title:The bounds branch, step by step}

{pstd}
{bf:Step 1. Factor proxies.} Averaging (1) across i gives
Ybar_t = Dbar_t + Lbar F_t + Ubar_t. Under Assumption G and Ubar_t -> 0,
F_t - (Lbar'Lbar)^-1 Lbar' (Ybar_t - Dbar_t) -> 0, so the observable
hbar_t = Ybar_t (Model 0), (1, Ybar_t')' (Model 1) or (1, t, Ybar_t')' (Model 2)
spans the factor space for N large.

{pstd}
{bf:Step 2. Pooled CCE.} With Mh = I_T - hbar (hbar'hbar)^-1 hbar',

{p 8 8 2}
thetahat_x = [ sum_i x_i' Mh x_i ]^-1 [ sum_i x_i' Mh y_i ]{col 55}(13){p_end}

{pstd}
Banerjee and Carrion-i-Silvestre (2017) show thetahat_x - theta_x =
O_p(C_NT^-1) with C_NT = min(sqrt(T), sqrt(N)) {bf:under the null}. That is the
result on which everything else rests: it lets a cointegration test be converted
into a unit root test. The code mirrors the authors' own GAUSS procedure
{bf:CADFcoin_multiple} (option = 2) exactly, including the order
hbar = [d_t, ybar, xbar].

{pstd}
Its variance is Holly, Pesaran and Yamagata (2010) eq. (3.12)-(3.13),

{p 8 8 2}
Var(thetahat) = N^-1 Psihat^-1 Rhat Psihat^-1,{p_end}
{p 8 8 2}
Psihat = N^-1 sum_i A_i,{space 3}A_i = x_i' Mh x_i / T,{p_end}
{p 8 8 2}
Rhat = (N-1)^-1 sum_i A_i (b_i - bbar)(b_i - bbar)' A_i,{p_end}

{pstd}
with b_i the unit-level CCE estimate and bbar the CCEMG average. Units whose
A_i is singular are excluded from Rhat and bbar and counted in the report.

{pstd}
{bf:Step 3. The error-correction term.} yhat_it = thetahat' Y_it, eq. (14).

{pstd}
{bf:Step 4. The conditional ECM.} For Case 5, eq. (15) is

{p 8 8 2}
D.y_it = c_i0 + c_i1 t + alpha_i' z_i,t-1
         + sum_{j=1}^{p_i-1} Gamma_ij' D.Y_i,t-j
         + sum_{j=0}^{p_i-1} Lambda_ij' D.Ybar_t-j
         + omega_i' D.x_it + xi_it{p_end}

{pstd}
with z_it = (yhat_it, Ybar_t')' and alpha_i = rho_yi (1, -theta_i')'. The
Ybar_t terms are the first {it:r} cross-section averages, in the order
(ybar, xbar_1, ..., xbar_{r-1}). The columns are assembled in exactly that
order, so rho_yi is the coefficient on yhat_i,t-1 and its position is 1, 2 or 3
according to Model 0, 1 or 2. The effective sample is held at the p_max sample
while the lag criterion is minimised, so that competing orders are compared on
identical observations.

{pstd}
{bf:Step 5. The statistic.} Eq. (17) reads

{p 8 8 2}
t_rho_yi = rho_yihat omegahat_i,xixi^(-1/2),{p_end}

{pstd}
which as printed is not scale free. The appendix of the authors' February 2022
working paper writes it in full,

{p 8 8 2}
t_rho_yi = D.y_i' M_i yhat_i,-1 /
           [ omegahat^(1/2) (yhat_i,-1' M_i yhat_i,-1)^(1/2) ],{p_end}

{pstd}
i.e. the ordinary OLS t-ratio of rho_yi, M_i being the projection off the
remaining regressors. That is what is computed. The panel statistic is
tybar = N^-1 sum_i t_rho_yi.

{pstd}
{bf:Step 6. Theorem 1 and Corollary 1.} t_rho_yi converges, sequentially and
jointly, to a Dickey-Fuller type functional involving 1 + r_1 stochastic trends.
Because theta is pooled and consistently estimated, the observable regressors
drop out of the limit - under the heterogeneous framework of Gengenbach, Urbain
and Westerlund (2016) the same statistic would carry 1 + k + r_1 trends.
Corollary 1 gives the two polar cases: r = r_0, all factors I(0) (lower bound)
and r = r_1, all factors I(1) (upper bound).


{marker cv}{...}
{title:Critical values}

{pstd}
{bf:Response surfaces} ({opt cvmethod(surface)}, the default). Eq. (B.15),

{p 8 8 2}
q(a) = th0 + th1/N + th2/N^2 + th3/T + th4/T^2 + th5/(NT)
       + th6 r + th7 r/N + th8 r/T + th9 r^2
       + th10 k + th11 k/N + th12 k/T + th13 k^2 + th14 r k{p_end}

{pstd}
with the coefficients of Table C.2 for a in {c -(}1, 2.5, 5, 10{c )-} per cent,
each model and each polar case. Table C.2 prints its coefficient rows as
0..12, 12, 14; the second "12" is th13, the coefficient on k^2, and that is the
reading used. {bf:Confirm it against the published table before relying on the
printed critical values} - every finite-sample critical value depends on it.

{pstd}
The surface was fitted on r in 1..6, k in 0..5 with r <= k+1, T in
{c -(}50, 100, 200{c )-} and N in {c -(}20, 40, 60{c )-}. Outside that box the
command still evaluates it but prints a warning that the result is an
extrapolation.

{pstd}
{bf:Asymptotic values} ({opt cvmethod(asymptotic)}). Table C.1, 5% only,
indexed by model, r_1 in 0..5 and N in {c -(}20, 40, 60{c )-}, linearly
interpolated in N and clamped outside. These were obtained by simulating the
limit functional with 1,000 steps and 50,000 replications.

{pstd}
The two agree closely in the I(1) case: for Model 0, r = 1, k = 0, T = 200 the
surface gives -1.523 at N = 60 and -1.610 at N = 20 against Table C.1's -1.53
and -1.60; for Model 2, r = 1, k = 0, N = 20 it gives -2.691 against -2.70. In
the {bf:I(0)} case they do not nest: the surface is noticeably more negative
than Table C.1 at every (T, N) in the fitted box, because the I(0) design still
leaves an O(N^(-1/2)) stochastic trend inside the cross-section averages that
only vanishes as N grows. The paper's own simulations use the surfaces, so they
are the default here; {opt cvmethod(asymptotic)} is offered as a cross-check,
not as an equivalent.


{marker panico}{...}
{title:The PANICO branch, step by step}

{pstd}
{bf:Step 8.} Substituting thetahat into the long-run relation, eq. (19),

{p 8 8 2}
yhat_i = D_i + F theta_i + u*_i,{space 3}u*_i = u_i - x_i (thetahat - theta),{p_end}

{pstd}
then differencing and projecting out the deterministic component, eq. (20)-(21),

{p 8 8 2}
D.yhat_i^d = M_{T-1} D.yhat_i = f lambda_i' + z_i,{p_end}

{pstd}
with M_{T-1} = I for Models 0 and 1 (case c) and the demeaning projector for
Model 2 (case tau). The demeaning in {bf:differences} is what removes the slope
of the trend in levels, exactly as in Bai and Ng (2010) p. 1092.

{pstd}
{bf:Factors.} {cmd:panico} takes the first r principal components of
D.yhat^d D.yhat^d' / (N(T-1)), scaled so that f'f/(T-1) = I.
{cmd:panicca} replaces f by the differenced, demeaned cross-section averages -
D.ybar^d for r = 1 and (D.ybar^d, D.xbar_1^d, ..., D.xbar_{r-1}^d) for
1 < r <= 1+k - and obtains lambda_i by least squares. Both then recumulate,
Fhat_t = sum_{s=2}^t fhat_s and uhat*_it = sum_{s=2}^t zhat_is.

{pstd}
{bf:Step 9. Idiosyncratic component.} Eq. (22) is an ADF regression with
{bf:no deterministic terms},

{p 8 8 2}
D.uhat*_it = d_i0 uhat*_i,t-1 + sum_{j=1}^{p_i} d_ij D.uhat*_i,t-j + error,{p_end}

{pstd}
giving t_uhat(i) and its p-value p_uhat(i). Then, by Theorem 2 and Bai and Ng
(2004) Theorem 4,

{p 8 8 2}
P = -2 sum_i ln p_uhat(i){space 10}-> chi2(2N){p_end}
{p 8 8 2}
Pm = (P - 2N) / sqrt(4N){space 10}-> N(0,1){p_end}
{p 8 8 2}
Z = (N^(-1/2) sum_i t_uhat(i) - sqrt(N) mu_j) / sigma_j{space 2}-> N(0,1){p_end}

{pstd}
with the moments of footnote 3 of the paper,
(mu_c, sigma^2_c) = (-0.42608, 0.95743) and
(mu_tau, sigma^2_tau) = (-1.53627, 0.34107), used verbatim.

{pstd}
{bf:Step 10. Pooled statistics.} Bai and Ng (2010) eq. (6)-(11). With
rhohat = tr(uhat*_-1' uhat*) / tr(uhat*_-1' uhat*_-1) and the nuisance set
(sigmahat^2, omegahat^2, phihat^4, lambdahat) of their eq. (4) - Bartlett
kernel, Andrews AR(1) plug-in bandwidth, the rule used in the PANIC code:

{p 8 8 2}
cases c: rhohat+ = rhohat - NT lambdahat / tr(uhat*_-1' uhat*_-1){p_end}
{p 8 8 2}
case tau: rhohat+ = rhohat + 3 sigmahat^2 / (T omegahat^2){p_end}

{pstd}
and Pa, Pb, PMSB as in their eq. (6)-(7) and (10) for cases c, eq. (8)-(9) and
(11) for case tau. Note that in their notation sigmahat^4 means (sigmahat^2)^2
and omegahat^8 means (omegahat^2)^4; getting those exponents wrong leaves the
statistics looking plausible but wrong, so they are written out explicitly in
the code.

{pstd}
{bf:Step 11. Common component.} For r = 1 the ADF on Fhat carries an intercept
(case c) or an intercept and a trend (case tau), per step 2 of Bai and Ng (2004)
Theorems 1 and 3, and the ordinary Dickey-Fuller critical values apply. For
r > 1 the MQc and MQf statistics are applied sequentially from
m = min(r, 6) downwards, with the critical values of their Table I; MQc removes
serial correlation nonparametrically with a Bartlett kernel, MQf by filtering
with an estimated VAR.

{pstd}
{bf:Remarks.} Theorem 2 strengthens Assumption C(ii) to cross-sectional
independence of the idiosyncratic innovations, as all pooled PANIC tests do.
The limiting distributions are {bf:identical} to those of PANIC for panel unit
roots - the invariance result - and PANICO does {bf:not} require the rank
condition.


{marker pvalues}{...}
{title:p-values}

{pstd}
Section 5.2 of the paper states that the group statistics use {bf:asymptotic}
moments and p-values, and attributes their mild small-T over-rejection to that
choice. The same is done here.

{pstd}
{bf:Case c.} ADF^c on uhat* has the Dickey-Fuller limit with no deterministic
terms (Bai and Ng 2004, Theorem 1.1; their 5% point is -1.95).

{pstd}
{bf:Case tau.} Bai and Ng (2004) Theorem 3.1 gives
ADF^tau on uhat* => -(1/2) (int_0^1 V(s)^2 ds)^(-1/2) with V a Brownian bridge.
This is {bf:not} a Dickey-Fuller distribution - it is proportional to the
reciprocal of a Brownian bridge functional - so Dickey-Fuller tables must not be
used for it.

{pstd}
Both limits were simulated with 1,000 steps and 1,000,000 replications and are
stored as 112-point quantile grids, interpolated linearly in
(statistic, invnormal(p)) and clamped to [1e-6, 1-1e-6]. The simulation
reproduces the paper's own footnote-3 moments, which is the check that the
reading of both theorems is right:

{p 8 12 2}case c:{space 5}mean -0.4258, variance 0.9645{space 3}(paper -0.42608, 0.95743){p_end}
{p 8 12 2}case tau:{space 3}mean -1.5347, variance 0.3409{space 3}(paper -1.53627, 0.34107){p_end}

{pstd}
and the case-c 5% point comes out at -1.938 against Bai and Ng's -1.95. The
grids are rebuilt by {bf:xtboundpanico_cvgen.do}, shipped with the
package.


{marker nfac}{...}
{title:Estimating the number of factors}

{pstd}
All criteria are applied to the {bf:differenced, projected} data D.yhat^d, as
PANIC prescribes, not to the levels. With V(k) the average residual variance
after k factors and C2 = min(N, T):

{p 8 8 2}
ICp1 = ln V(k) + k ((N+T)/(NT)) ln(NT/(N+T)){p_end}
{p 8 8 2}
ICp2 = ln V(k) + k ((N+T)/(NT)) ln C2{p_end}
{p 8 8 2}
ICp3 = ln V(k) + k (ln C2)/C2{p_end}

{pstd}
PCp1-PCp3 replace ln V(k) by V(k) and scale the penalty by
sigmahat^2 = V(rmax); AIC3 and BIC3 use the penalties
2(N+T-k)/(NT) and (N+T-k) ln(NT)/(NT). ICp1 is the panel BIC of the paper.

{pstd}
{bf:ER and GR} (Ahn and Horenstein 2013). On the eigenvalues mutilde of
XX'/(TN), with V(k) = sum_{j=k+1}^{m} mutilde_j and m = min(N,T),

{p 8 8 2}
ER(k) = mutilde_k / mutilde_{k+1},{p_end}
{p 8 8 2}
GR(k) = ln(V(k-1)/V(k)) / ln(V(k)/V(k+1)),{p_end}

{pstd}
both {bf:maximised}. Their eq. (4) mock eigenvalue
mutilde_0 = V(0)/ln(m) makes rhat = 0 admissible and is included.

{pstd}
{bf:ED} (Onatski 2010, Section IV). Starting from j = rmax+1: regress
(lambda_j, ..., lambda_{j+4}) on a constant and
((j-1)^(2/3), ..., (j+3)^(2/3)), set delta = 2 |betahat| from the slope, take
rhat(delta) = max{c -(}i <= rmax : lambda_i - lambda_{i+1} >= delta{c )-} (zero
if the set is empty), then set j = rhat(delta)+1 and iterate to convergence.
The iteration is capped at 20 passes and ED returns missing unless at least
rmax+5 eigenvalues exist.

{pstd}
{bf:RW} (Reese and Westerlund 2016, p. 10), used by {cmd:panicca}:

{p 8 8 2}
IC(s) = ln det[Sigmahat_v(s)] + s (m+1) N^-1 ln N,{p_end}

{pstd}
minimised over s = 0..1+k, with Sigmahat_v(s) the residual second moment after
fitting s cross-section averages and m+1 = 1+k. The penalty is that of ICp3
with T = 0, because the CA estimator's rate depends on N alone. The paper notes
that this criterion, being a multivariate ICp3, can over-estimate r.


{marker readings}{...}
{title:Readings of the paper that the code had to settle}

{pstd}
Each of the following is a place where the printed text is ambiguous or
inconsistent. The choice made is stated so that it can be audited.

{phang}
{bf:1. Eq. (17) is not scale free as printed.} Taken literally,
rho_yihat omegahat^(-1/2), the statistic would diverge. The 2022 working-paper
appendix supplies the missing (yhat'M yhat)^(-1/2) factor. {bf:The OLS t-ratio
is computed.} No option: the printed form is a typographical slip.

{phang}
{bf:2. omegahat_i,xixi is written with sum xihat, not sum xihat^2.} Treated as
a typographical slip; the squared residuals are summed.

{phang}
{bf:3. m_i.} The paper writes m_i = 2 + k + (1+r) p_i and calls it "the number
of estimated parameters for Case 5". Counting the Case-5 regressors of eq. (15)
gives 2 + r + p_i + k p_i + r p_i instead; the two agree only when k = r. The
paper's stated {it:intent} wins, so the {bf:actual column count} of the design
matrix is used. {opt dfpaper} imposes the literal formula.

{phang}
{bf:4. Full T or the effective sample in (T - m_i)?} Eq. (17) writes a full T,
and the authors' GAUSS CADF code does divide by full T. But 500 replications on
the paper's own DGP show that the full-T readings roughly {bf:double} the
empirical size that Table C.3 reports, while the ordinary OLS denominator
reproduces it:

{p 8 8 2}{space 42}ty(1){space 4}ty(0){p_end}
{p 8 8 2}T = 50, rho = 1, phi = 1, Table C.3{space 7}0.07{space 5}0.24{p_end}
{p 8 8 2}{space 4}full T minus parameters ({opt dffull}){space 4}0.135{space 4}0.378{p_end}
{p 8 8 2}{space 4}full T minus literal m_i ({opt dfpaper}){space 3}0.220{space 4}0.485{p_end}
{p 8 8 2}{space 4}effective sample (default){space 14}0.062{space 4}0.234{p_end}

{pstd}
so the {bf:effective sample is the default}. The CIPS comparator of eq. (18)
keeps the GAUSS code's full-T convention, since for that statistic the authors'
own source is authoritative.

{phang}
{bf:5. Lag selection.} BIC with p_max = floor(4 (T/100)^(1/4)), as the paper
specifies. Competing orders are compared on the p_max sample so the criteria are
commensurable. AIC over-selects badly here (empirical size 0.225 against 0.07 at
T = 50) and is offered only for completeness.

{phang}
{bf:6. Degenerate units.} A unit whose individual regression is singular is
dropped from the panel average, counted, and its position returned in
{cmd:r(dropped)} - never silently absorbed.

{phang}
{bf:7. Which cross-section averages enter z_it.} The first r of
(ybar, xbar_1, ..., xbar_k). When the rank condition holds with equality,
r = 1+k and all of them enter.


{marker validation}{...}
{title:Numerical validation}

{pstd}
The package is validated against the paper's own Table C.3 (r = 1, k = 1,
rhat = 2, N = 20, lambda ~ U[0,1], Model 2, 5% level), using the paper's DGP of
eq. (23)-(26) with 500 replications:

{p2colset 8 24 40 2}{...}
{p2col :{space 10}rho, T}tybar(1) here / paper{space 3}tybar(0) here / paper{space 3}Amb here / paper{p_end}
{p2col :{space 10}1,  50}0.062 / 0.07{space 11}0.234 / 0.24{space 12}0.172 / 0.17{p_end}
{p2col :{space 10}1, 100}0.048 / 0.04{space 11}0.144 / 0.13{space 12}0.096 / 0.09{p_end}
{p2col :{space 10}1, 200}0.052 / 0.05{space 11}0.088 / 0.08{space 12}0.036 / 0.04{p_end}
{p2col :{space 8}0.9,  50}0.070 / 0.05{space 11}0.224 / 0.20{space 12}0.154 / 0.15{p_end}
{p2col :{space 8}0.9, 100}0.030 / 0.02{space 11}0.090 / 0.09{space 12}0.060 / 0.06{p_end}
{p2col :{space 8}0.9, 200}0.018 / 0.01{space 11}0.028 / 0.03{space 12}0.010 / 0.01{p_end}
{p2colreset}{...}

{pstd}
Every cell is within Monte Carlo error. Mean thetahat - theta is within +/-0.008
throughout, power rises to 1 by T = 200 under phi = 0.9, and the rho = 0 column
is the most conservative - all as the paper describes. The 11 factor-number
criteria recover the true r = 1 on the baseline design, except AIC3, which
selects rmax, exactly the behaviour Bai and Ng (2002) warn about.

{pstd}
{bf:xtboundpanico_example.do} reproduces all of this.


{marker limits}{...}
{title:Limitations, stated rather than worked around}

{phang}
{bf:Slope homogeneity is assumed and not tested.} Eq. (10) imposes it, and no
test is implemented because the paper provides none. For heterogeneous slopes
see Gengenbach, Urbain and Westerlund (2016).

{phang}
{bf:No Wald or F variant.} Section 3 reports that F-type and Wald statistics for
the joint significance of alpha_i perform comparably to t_rho_yi, but the 2026
paper tabulates critical values only for t_rho_yi. They are therefore not
computed. (The February 2022 working paper does carry response surfaces for W.)

{phang}
{bf:No confidence interval for the speed of adjustment.}

{phang}
{bf:No critical values for the CIPS comparator.} It is printed for comparison
only; take its critical values from Banerjee and Carrion-i-Silvestre (2017) or
Pesaran, Smith and Yamagata (2013).

{phang}
{bf:Table C.2 row labelling is unconfirmed.} See {help xtboundpanico_methods##cv:Critical values}.

{phang}
{bf:The I(0) response surface and Table C.1 do not nest.} Documented above
rather than reconciled; the paper's own simulations use the surfaces.

{phang}
{bf:Balanced panels only}, and the MQ critical values cover at most 6 factors.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane
