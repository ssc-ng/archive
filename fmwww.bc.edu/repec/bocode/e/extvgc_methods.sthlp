{smcl}
{* *! version 1.0.0  25nov2026}{...}
{vieweralsosee "extvgc" "help extvgc"}{...}
{viewerjumpto "Shocks" "extvgc_methods##shocks"}{...}
{viewerjumpto "LA-VAR and Wald" "extvgc_methods##wald"}{...}
{viewerjumpto "Time variation" "extvgc_methods##tv"}{...}
{viewerjumpto "Bootstrap" "extvgc_methods##boot"}{...}
{viewerjumpto "Step map" "extvgc_methods##map"}{...}
{viewerjumpto "Decisions" "extvgc_methods##decisions"}{...}
{title:Title}

{phang}
{bf:extvgc methods} {hline 2} Equations of Hong, Guo & Zhao (2025) and how
{helpb extvgc} implements them


{marker shocks}{...}
{title:1. Extreme, normal shocks (Eqs. 1-7)}

{pstd}
Each variable is a random walk, x_t = x_0 + sum_{i<=t} e_1i (Eq. 1); the shock
e is the first difference (or the variable itself with {opt differenced}).
For quantile level theta1 (theta2 = 1 - theta1) the common thresholds
(Eq. 2, following Wang et al. 2020, Eq. 5) are

{p 8 8 2}q   = max( Q_1(theta2), Q_2(theta2) ){break}
q_v = min( Q_1(theta1), Q_2(theta1) ){p_end}

{pstd}
where Q_k is the empirical quantile of the shocks of variable k. Hong et al.
print the indices of Eq. (2) the other way round; with theta1 = 0.1 that would
make the extreme-positive threshold a 10th percentile. Wang et al. (2020) use
the upper-tail (VaR) convention and state in words that an extreme shock
belongs to "the 10% most negative returns ... or the 10% of the most positive
log-changes"; Section 4.1 of Hong et al. ("a smaller value indicates more
intense extreme shocks") agrees. {cmd:extvgc} follows that reading.

{pstd}
The shocks are split as (Eqs. 3-5)

{p 8 8 2}extreme positive: e if e > q, else 0{break}
extreme negative: e if e < q_v, else 0{break}
normal: e if q_v <= e <= q, else 0{p_end}

{pstd}
so e = e(+) + e(-) + e(#), and the components are cumulated (Eq. 6):
x(+)_t = sum_{i<=t} e(+)_1i, etc. A pair (cause shock, dependent shock) gives
the bivariate system z_t = (dep component, cause component)'. The overall test
uses z_t = (y_t, x_t)'.

{pstd}
{opt threshold(own)}: q_k = Q_k(theta2), q_v,k = Q_k(theta1) per variable.
{opt threshold(zero)}: q = q_v = 0, the Hatemi-J (2012) split; the normal
component is then empty.


{marker wald}{...}
{title:2. LA-VAR and the Wald statistic (Eqs. 8-18)}

{pstd}
For the dependent variable the LA-VAR(p, d) of Eq. (8) is

{p 8 8 2}z1_t = a0 + a1 t + sum_{i=1}^{p+d} b_i z1_{t-i} + sum_{i=1}^{p+d} c_i z2_{t-i} + u_t{p_end}

{pstd}
and H0 (Eq. 10): c_1 = ... = c_p = 0; the d extra lags are left unrestricted
(Toda & Yamamoto 1995). p is chosen by (Eq. 12)

{p 8 8 2}HJC(j) = ln|Omega_j| + j (n^2 ln T + 2 n^2 ln ln T) / (2T){p_end}

{pstd}
on a fixed estimation sample of T - maxlag observations (Hatemi-J 2003), with
an intercept, n = 2. AIC, SBC and HQC are also available.

{pstd}
The Wald statistic (Eq. 18) is

{p 8 8 2}exW = (R phi)' [ R ( Sigma_e (x) (U'QU)^-1 ) R' ]^-1 (R phi),  Sigma_e = e'e / T{p_end}

{pstd}
where Q partials out the deterministic terms and the augmentation lags. For
the single restricted equation this equals
c' [ s2 (X'X)^-1_cc ]^-1 c with s2 = SSR/T (Frisch-Waugh), i.e.
{cmd:regress} + {cmd:test} multiplied by N/(N-k). Note the divisor T, not T - k,
as written in the paper.

{pstd}
{bf:Numerical form.} {cmd:extvgc} estimates the equivalent regression

{p 8 8 2}Dz1_t = a0 + a1 t + g0' z_{t-1} + sum_{j=1}^{m-1} g_j' Dz_{t-j} + u_t,  m = p + d{p_end}

{pstd}
which spans the same space and has the same residuals. The levels coefficients
are b_1 = g0 + g1, b_j = g_j - g_{j-1} (2 <= j <= m-1), b_m = -g_{m-1}; H0 is
imposed through this linear map. The Wald statistic is invariant to the
nonsingular reparameterisation; the form avoids near-collinear level lags.


{marker tv}{...}
{title:3. Time variation (Eq. 19)}

{pstd}
Let exW(r1, r2) be the statistic on the subsample of regression rows r1..r2
and tau0 the minimum window. For each end date r2 >= tau0:

{p 8 8 2}forward:   F_r2 = exW(1, r2){break}
rolling:   R_r2 = exW(r2 - tau0 + 1, r2){break}
recursive evolving: SEW_r2 = sup_{1 <= r1 <= r2 - tau0 + 1} exW(r1, r2){p_end}

{pstd}
All subsample regressions use running sums of the cross-products of
[X, y], so each exW costs one small inversion. Subsamples use the rows of the
full-sample design, so the first lags may come from before r1 (as in
Shi et al.'s code). Default tau0 = floor(T(0.01 + 1.8/sqrt(T)))
(Phillips, Shi & Yu 2015); the paper uses 72 months.


{marker boot}{...}
{title:4. Bootstrap critical values (Eqs. 20-22)}

{p 8 12 2}(a) Fit the VAR(p) with intercept under H0 (the dependent equation
excludes the cause's lags) on the full sample of the pair (Eq. 20; the paper
writes it for p = 1).{p_end}
{p 8 12 2}(b) Generate z^b_t recursively with residuals redrawn with replacement,
separately for each equation (Eq. 21: "randomly substituted from e1 and e2,
respectively"; {opt resample(joint)} redraws rows), starting from the first
p observations of the data, for tau0 + tb - 1 regression rows
(tb = {opt control()}).{p_end}
{p 8 12 2}(c) Compute the same statistic sequence on z^b and keep its maximum over
the tb end dates (Eq. 22).{p_end}
{p 8 12 2}(d) Repeat B times ({opt reps()}, paper 499); the 90/95/99% quantiles
of the maxima are the critical values. Reject at date t when SEW_t > CV.{p_end}

{pstd}
The lag order and the window are held at their observed values in every
replication, so the bootstrap reproduces the whole observed statistic.


{marker map}{...}
{title:5. Step map: paper -> code}

{p2colset 5 28 30 2}{...}
{p2col:Paper}{cmd:extvgc} (Mata function){p_end}
{p2line}
{p2col:Eq. (1) shocks}{cmd:_extvgc_shocks()}{p_end}
{p2col:Eq. (2) thresholds}{cmd:_extvgc_thr()}, {cmd:_extvgc_q()}{p_end}
{p2col:Eqs. (3)-(7) components}{cmd:_extvgc_one()}, {cmd:_extvgc_pair()}{p_end}
{p2col:Eq. (12) HJC lag order}{cmd:_extvgc_lagsel()}{p_end}
{p2col:Eqs. (8)-(16) LA-VAR}{cmd:_extvgc_design()}, {cmd:_extvgc_R()}{p_end}
{p2col:Eq. (18) Wald exW}{cmd:_extvgc_w()}{p_end}
{p2col:Eq. (19) SEW_t}{cmd:_extvgc_seq()}{p_end}
{p2col:Eqs. (20)-(22) bootstrap}{cmd:_extvgc_boot()}{p_end}
{p2col:Steps 1-8 (Sec. 2)}{cmd:_extvgc_run()} and the ado tables/graphs{p_end}
{p2col:Table 1}{opt descriptive} (JB, ADF with AIC lag, KPSS){p_end}
{p2col:Table 2}{opt diagnostics} (Doornik-Hansen via {cmd:mvtest}; multivariate ARCH-LM){p_end}
{p2col:Table 3}{opt diagnostics} (AIC, SBC, HQC, HJC){p_end}
{p2col:Figs. 2-3}{cmd:extvgc_overall}, {cmd:extvgc_pairs}{p_end}
{p2line}


{marker decisions}{...}
{title:6. Choices the paper leaves open}

{p 8 12 2}1. Threshold indices of Eq. (2): resolved with Wang et al. (2020), see Section 1.{p_end}
{p 8 12 2}2. Quantile definition: piecewise linear with plotting position (k - 0.5)/n.{p_end}
{p 8 12 2}3. Bootstrap VAR order: the selected p (the paper's Eq. 20 shows p = 1).{p_end}
{p 8 12 2}4. One lag order for all pairs (Table 3), chosen on the overall system; {opt lagmode(pair)} as an alternative.{p_end}
{p 8 12 2}5. Multivariate ARCH: asymptotic LM test of Lutkepohl (2005, Sec. 16.5); the paper cites the bootstrap version of Hacker & Hatemi-J (2005).{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
