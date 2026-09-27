{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol adaptive" "help cointvol_adaptive"}{...}
{vieweralsosee "cointvol vecmgarch" "help cointvol_vecmgarch"}{...}
{vieweralsosee "[TS] vec" "help vec"}{...}
{viewerjumpto "Syntax" "cointvol_restrict##syntax"}{...}
{viewerjumpto "Description" "cointvol_restrict##description"}{...}
{viewerjumpto "Options" "cointvol_restrict##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_restrict##methods"}{...}
{viewerjumpto "Remarks" "cointvol_restrict##remarks"}{...}
{viewerjumpto "Examples" "cointvol_restrict##examples"}{...}
{viewerjumpto "Stored results" "cointvol_restrict##results"}{...}
{viewerjumpto "References" "cointvol_restrict##references"}{...}
{viewerjumpto "Author" "cointvol_restrict##author"}{...}
{title:Title}

{p2colset 5 27 29 2}{...}
{p2col:{cmd:cointvol restrict} {hline 2}}Inference on the cointegrating vectors (beta) and
adjustment coefficients (alpha) of a VAR with conditional and nonstationary volatility:
restricted PML, PLR and sandwich Wald tests, wild bootstrap and Bartlett correction{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol restrict} {varlist} {ifin}{cmd:,} {opt la:gs(#)} {opt ra:nk(#)}
{it:hypothesis} [{it:options}]

{p 4 4 2}
where {it:hypothesis} is at least one restriction on beta and/or on alpha:

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt la:gs(#)}}lag order {it:k} of the VAR in levels; {it:k} {ul:>} 1{p_end}
{p2coldent:* {opt ra:nk(#)}}cointegration rank {it:r}, 1 {ul:<} {it:r} {ul:<} {it:p}-1{p_end}
{synopt:{opt tr:end(string)}}{cmd:rconstant} (default), {cmd:rtrend}, {cmd:none},
{cmd:constant} or {cmd:trend}{p_end}
{synopt:{opt norm:alize(varlist)}}the {it:r} variables with c'beta = I_r; default: the first
{it:r} variables (variables 2,...,{it:r}+1 with {opt spreads}){p_end}

{syntab:Hypotheses on beta (at most one)}
{synopt:{opt spr:eads}}every cointegrating vector is a combination of spreads x_i - x_1
(expectations hypothesis; beta# = H*phi){p_end}
{synopt:{opt kn:own(numlist|matname)}}beta fully specified{p_end}
{synopt:{opt hmat:rix(matname)}}Johansen form beta# = H*phi{p_end}
{synopt:{opt bcon:straints(R_b [q_b])}}general R_b vec(beta2#) = q_b (BCRT 2016, eq. 5){p_end}

{syntab:Hypotheses on alpha (may be combined)}
{synopt:{opt ex:og(varlist)}}weak exogeneity: the rows of alpha of these variables are zero{p_end}
{synopt:{opt acon:straints(R_a [q_a])}}general R_a vec(alpha') = q_a (BCRT 2016, eq. 5){p_end}
{synopt:{opt sep:arate}}with restrictions on both, also test H0 beta and H0 alpha separately{p_end}

{syntab:Inference}
{synopt:{opt m:ethod(string)}}{cmd:wild} (default), {cmd:iid} or {cmd:asy}{p_end}
{synopt:{opt mult:iplier(string)}}{cmd:gauss} (default), {cmd:rademacher} or {cmd:mammen}{p_end}
{synopt:{opt re:ps(#)}}bootstrap replications; default {cmd:999}; minimum 19{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt pval:ue(string)}}{cmd:strict} (default) or {cmd:plusone}{p_end}
{synopt:{opt bart:lett}}Bartlett-corrected PLR, Johansen (2000) Cor. 6 (beta# = H*phi){p_end}
{synopt:{opt lev:el(#)}}level for the stars and bootstrap critical values; default 95{p_end}

{syntab:Optimisation and reporting}
{synopt:{opt tol:erance(#)}}convergence tolerance of the switching algorithm; default 1e-8{p_end}
{synopt:{opt iter:ate(#)}}maximum switching iterations; default 5000{p_end}
{synopt:{opt br:ief}}suppress the tables of estimates{p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} and {opt rank()} are required. The data must be {helpb tsset} as
a time series (not a panel) without gaps. {it:varlist} may contain time-series operators.
Typing {cmd:cointvol restrict} without arguments replays the last results
({opt brief} and {opt level()} allowed).{p_end}

{p 4 4 2}
{cmd:predict} after {cmd:cointvol restrict}:

{p 8 16 2}
{cmd:predict} {dtype} {newvarlist} {ifin} [{cmd:,} {opt ect} {opt unr:estricted}
{opt eq:uation(#)}]

{p 4 4 2}
creates the error-correction terms beta_j#'(X(t-1)', D1(t)')' (restricted estimates by
default, the unrestricted PML estimates with {opt unrestricted}); up to {it:r} new
variables, or one with {opt equation(#)}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol restrict} estimates the cointegrated VAR

{p 8 8 2}
dX(t) = alpha (beta' X(t-1) + rho1' D1(t)) + Gamma_1 dX(t-1) + ... +
Gamma_(k-1) dX(t-k+1) + mu2 D2(t) + e(t)

{pstd}
by Gaussian pseudo maximum likelihood (PML, Johansen's estimator) without and with linear
restrictions on beta# = (beta', rho1')' and on alpha, and tests the restrictions with

{p 8 11 2}
- the pseudo likelihood-ratio test LR_T = T log(|Sigma~|/|Sigma^|);{p_end}
{p 8 11 2}
- the Wald test based on the PML sandwich variance (Boswijk, Cavaliere, Rahbek and
Taylor 2016, BCRT, eq. 18);{p_end}
{p 8 11 2}
- asymptotic chi2 p-values, and p-values from the wild bootstrap of BCRT (Algorithm 1)
or its iid counterpart;{p_end}
{p 8 11 2}
- optionally, the Bartlett correction of Johansen (2000, Corollary 6) for hypotheses
beta# = H*phi, which Kurita (2013) applies heuristically under multivariate GARCH
errors.{p_end}

{pstd}
Use it after the cointegration rank has been chosen (for example with
{helpb cointvol_rank:cointvol rank}, whose wild bootstrap is robust to the same forms of
heteroskedasticity). BCRT show that, when the innovation variance changes over time
(breaks, trends, smooth transitions) and/or displays GARCH-type clustering, the standard
chi2 PLR tests on alpha and beta are oversized, possibly badly; the Wald test on alpha
remains asymptotically chi2, the Wald test on beta only under "common volatility", and the
wild bootstrap PLR test has the best finite-sample size overall. Do not use the
asymptotic p-values as your main evidence when volatility is not constant.

{pstd}
The unrestricted PML estimates with sandwich standard errors are posted in {cmd:e(b)} and
{cmd:e(V)}; restricted estimates, test statistics and p-values are stored as well.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} is the lag order {it:k} of the VAR in levels, so the model has {it:k}-1
lagged differences; the first {it:k} observations are initial values (T = N - {it:k}).

{phang}
{opt rank(#)} is the cointegration rank {it:r}, taken as known (BCRT, Sec. 2).

{phang}
{opt trend(string)} sets the deterministic case (Stata {helpb vec} keywords):
{cmd:rconstant} restricted constant, D1 = 1 (BCRT case (i), default); {cmd:rtrend}
restricted trend with unrestricted constant, D1 = t, D2 = 1 (BCRT case (ii));
{cmd:none}; {cmd:constant} (unrestricted constant) and {cmd:trend} (unrestricted trend),
which have no restricted deterministic rows in beta#. {cmd:rconstant} and {cmd:rtrend}
are Original (BCRT eq. 1); {cmd:none}, {cmd:constant} and {cmd:trend} are Extended
implementation.

{phang}
{opt normalize(varlist)} lists the {it:r} normalising variables: c is the selection matrix
of these variables, c'beta = I_r, so the {it:j}-th cointegrating vector has coefficient 1
on the {it:j}-th listed variable and 0 on the other listed variables (BCRT, Sec. 2.2).
beta2# collects the remaining rows of beta# (the non-normalising variables in varlist
order, then the restricted deterministic row). The PLR test does not depend on the
normalisation; the Wald test does (it is not invariant to reparameterisation).
Original: BCRT Sec. 2.2.

{dlgtab:Hypotheses}

{phang}
{opt spreads} imposes beta# = H*phi with H = blockdiag(H0, I_d1), where the columns of
H0 are e_i - e_1, i = 2,...,p: in every cointegrating vector the coefficients on the
variables sum to zero, i.e. beta'X is a combination of the spreads x_i - x_1 (x_1 = first
variable of {it:varlist}; reorder the varlist to change the reference). The restricted
deterministic terms are free. With r = p-1 this is the expectations hypothesis of the
term structure tested in BCRT (Sec. 6: normalised on x_2,...,x_p, R_b = I_4 # (1 0),
q_b = (-1,...,-1)'); with r < p-1 it is the hypothesis beta'(1,...,1)' = 0 of BCRT
Sec. 6. df = r. Original: BCRT Sec. 6.

{phang}
{opt known(numlist|matname)} fully specifies beta. A numlist of p*r numbers (vector 1
first) or a p x r matrix fixes the levels coefficients and leaves the restricted
deterministic coefficients free (beta# = blockdiag(beta0, I_d1) phi, df = r(p-r)); a
list of p#*r numbers or a p# x r matrix also fixes rho1 (df = r(p#-r)). Only the space
spanned by beta0 matters. The normalising variables must have a nonsingular block in
beta0; use {opt normalize()} otherwise. Original: BCRT Sec. 6 (Nelson-Siegel example).

{phang}
{opt hmatrix(matname)} tests beta# = H*phi (Johansen 1996, ch. 7; Boswijk and Doornik
2004, eq. 33; Kurita 2013, eq. 5) with H of dimension p# x s or p x s (then the
deterministic rows are left free), r {ul:<} s < p#. df = r(p#-s). Original: Johansen
(1996, Thm 7.2).

{phang}
{opt bconstraints(R_b [q_b])} names a matrix R_b (r_b x (p#-r)r) and optionally a vector
q_b (default 0) for H0: R_b vec(beta2#) = q_b, with vec(beta2#) stacking the columns of
beta2# (see {opt normalize()}). Original: BCRT eq. (5).

{phang}
{opt exog(varlist)} imposes weak exogeneity of the listed variables: their rows of alpha
are zero (BCRT Sec. 6: R_a = [I_4 0], q_a = 0 for the 3-month rate). Original: BCRT Sec. 6.

{phang}
{opt aconstraints(R_a [q_a])} names R_a (r_a x pr) and optionally q_a for
H0: R_a vec(alpha') = q_a. {bf:Note: vec(alpha')} stacks the {it:rows} of alpha:
element (i-1)r+j is alpha[i,j]. May be combined with {opt exog()} (rows are stacked).
Original: BCRT eq. (5).

{phang}
{opt separate}: with restrictions on both beta and alpha the default is the joint test
H0 alpha-beta; {opt separate} additionally reports H0 beta and H0 alpha, each with its own
restricted estimates and its own bootstrap (as in BCRT Sec. 6).

{dlgtab:Inference}

{phang}
{opt method(string)}: {cmd:wild} (default) is BCRT Algorithm 1; {cmd:iid} resamples the
recentred restricted residuals with replacement (BCRT Sec. 4.1, valid under conditional
but not under nonstationary heteroskedasticity); {cmd:asy} reports chi2 p-values only.

{phang}
{opt multiplier(string)}: distribution of the wild-bootstrap weights w_t: {cmd:gauss}
N(0,1) (default, used in BCRT's simulations), {cmd:rademacher} (+-1 with probability 1/2),
{cmd:mammen} (two-point, Remark 4.1). Original: BCRT Algorithm 1 and Remark 4.1.

{phang}
{opt reps(#)} bootstrap replications B; default 999 (BCRT Sec. 6).

{phang}
{opt seed(string)} sets the random-number seed for reproducibility.

{phang}
{opt pvalue(string)}: {cmd:strict} p = B^-1 sum 1(S* > S) (BCRT Algorithm 1 (iii));
{cmd:plusone} p = (#(S* >= S) + 1)/(B + 1) (Extended implementation).

{phang}
{opt bartlett} reports LR_T/BC with a chi2(df) p-value for hypotheses beta# = H*phi
({opt spreads}, {opt known()}, {opt hmatrix()}) without restrictions on alpha; BC is
Johansen's (2000) Bartlett correction factor E(LR_T)/df of Corollary 6, evaluated at the
restricted estimates (see Methods and formulas). With {opt separate} it is computed for
the H0 beta row. Original: Johansen (2000), Cor. 6 (H with p rows) and Cor. 5 (beta#
fully known, including rho1); Extended implementation for a general p# x s matrix H that
also restricts rho1.

{phang}
{opt level(#)} sets the level for the stars and for the bootstrap critical values stored
in {cmd:e(tests)}.

{dlgtab:Optimisation and reporting}

{phang}
{opt tolerance(#)} stops the switching algorithm when |log|Sigma(n)| - log|Sigma(n-1)|| <
#, i.e. when the likelihood has converged (Boswijk and Doornik 2004, Sec. 3.2); default
1e-8. {opt iterate(#)} caps the number of iterations (default 5000).

{phang}
{opt brief} suppresses the tables of unrestricted and restricted estimates.
{opt nodots} suppresses the bootstrap progress dots.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model and moments.} Z0t = dX(t), Z1t = (X(t-1)', D1(t)')' (p# = p + d1 rows),
Z2t = (dX(t-1)',...,dX(t-k+1)', D2(t)')'. M_ij = T^-1 sum Z_it Z_jt',
S_ij = M_ij - M_i2 M22^-1 M_2j (BCRT eqs 4, 7). The pseudo log-likelihood is
l(alpha, beta#, Sigma) = -T/2 log|Sigma| - T/2 tr Sigma^-1 (S00 - 2 alpha beta#'S10 +
alpha beta#'S11 beta# alpha') (eq. 8).

{pstd}
{bf:Unrestricted PML} (eq. 9): the eigenvectors of |lambda S11 - S10 S00^-1 S01| = 0 for
the r largest eigenvalues give beta_u#; beta^# = beta_u#(c#'beta_u#)^-1,
alpha^ = S01 beta^#(beta^#'S11 beta^#)^-1, |Sigma^| = |S00| prod(1 - lambda_i).

{pstd}
{bf:Hypotheses} (eq. 5): H0b: R_b vec(beta2#) = q_b; H0a: R_a vec(alpha') = q_a; H0ab:
both. They are written (eq. 6) as vec beta# = H phi + h, vec alpha' = G psi + g with
Q = [(I_r # c#), (I_r # cperp#)R_b'], H = Q_perp, h = Q(Q'Q)^-1((vec I_r)', q_b')',
G = (R_a')_perp, g = R_a'(R_a R_a')^-1 q_a. A Johansen-form hypothesis beta# = H_J phi is
converted with R_b = I_r # (H_J,perp' cperp#), q_b = -vec(H_J,perp' c#).

{pstd}
{bf:Restricted PML.} For beta# = H_J phi with alpha unrestricted the maximum is in closed
form: solve |lambda H_J'S11H_J - H_J'S10 S00^-1 S01 H_J| = 0 (Johansen 1996, Thm 7.2;
Boswijk and Doornik 2004, B&D, Sec. 4.2) and
LR_T = T sum_(i<=r) log((1 - lambda~_i)/(1 - lambda^_i)), which is Kurita's (2013) QLR,
eq. (6). Otherwise the explicit switching algorithm for linear restrictions of B&D
(Sec. 4.4, eq. 39 and the three steps that follow it) is used, with vec alpha' =
G psi + g and vec beta# = H phi + h (the normalisation c'beta = I_r is part of h and H).
With Pi'_LS = S11^-1 S10 the steps are{break}
(a) phi = [H'(alpha'Omega^-1 alpha # S11)H]^-1 H'(alpha'Omega^-1 # S11)
[vec(Pi'_LS) - (alpha # I_p#)h];{break}
(b) psi = [G'(Omega^-1 # beta#'S11 beta#)G]^-1 G'[(Omega^-1 # beta#'S11)vec(Pi'_LS)
- (Omega^-1 # beta#'S11 beta#)g];{break}
(c) Omega = S00 - S01 beta# alpha' - alpha beta#'S10 + alpha beta#'S11 beta# alpha',{break}
in the order phi_j = phi(psi_(j-1), Omega_(j-1)), psi_j = psi(phi_j, Omega_(j-1)),
Omega_j = Omega(psi_j, phi_j), starting from Omega_0 = Omega(alpha_0, beta_0). For g = 0
the steps are exactly those of B&D; g <> 0 (non-homogeneous restrictions on alpha, i.e.
q_a <> 0 in {opt aconstraints()}) is the generalisation that B&D attribute to Hansen
(2002) and is an Extended implementation. The iterations stop when log|Omega| (-2/T times
the concentrated log-likelihood, B&D eq. 22) changes by less than {opt tolerance()}; no
line search is used (none is used by B&D). No step decreases the likelihood (B&D
Sec. 3.2). Starting values: the unrestricted PML estimates, or the closed-form H_J
solution when available.

{pstd}
{bf:Identification check.} At the restricted estimates the command evaluates the Jacobian
J(theta) = [(I_p # beta#)G : (alpha # I_p#)H] of vec(beta# alpha') with respect to the
free parameters theta = (psi', phi')' (B&D eq. 40) and its numerical rank (the number of
singular values above 10{c 94}4 eps max_i sum_j |J_ij|, the rule quoted in B&D
Sec. 3.1). Full column rank l is the sufficient condition for local identification in
B&D Theorem 1 (eq. 20). Under it the chi2 df of B&D Theorem 2 equals the number of
restrictions used here. The rank and l are stored in {cmd:e(tests)} (columns rank_J,
n_free), and a warning is shown if rank < l.

{pstd}
{bf:PLR test.} LR_T = T log(|Sigma~|/|Sigma^|) (BCRT Sec. 3.1), asymptotic p-value from
chi2(df), df = r_b + r_a. Under Assumption 2 of BCRT the limit is chi2 only if Sigma(u)
is constant (and, for alpha, no volatility clustering) (Thm 1, Remarks 3.3-3.6).

{pstd}
{bf:Wald test} (eq. 18): W_T = (R theta^ - q)'(R Var[theta^] R')^-1 (R theta^ - q),
theta = ((vec beta2#)', (vec alpha')')', R = diag(R_b, R_a). With
J_d = [(alpha # cperp#), (I_p # beta#)],
Hs = T[J_d'(Sigma^-1 # M11)J_d, J_d'(Sigma^-1 # M12); (Sigma^-1 # M21)J_d,
Sigma^-1 # M22] and the outer product of gradients
I = sum_t s_t s_t', s_t = (J_d'(Sigma^-1 e_t # Z1t)', (Sigma^-1 e_t # Z2t)')',
Var[theta^] = (I_l 0) Hs^-1 I Hs^-1 (I_l 0)', all at the unrestricted PML estimates.
W_T(alpha) is asymptotically chi2(r_a) under Assumption 2; W_T(beta) is chi2(r_b) under
the condition of Corollary 1 (e.g. common volatility).

{pstd}
{bf:Wild bootstrap} (BCRT Algorithm 1), for each hypothesis:{break}
(0) compute the restricted PML estimates alpha~, beta~#, Psi~ = (Gamma~, mu~2) and the
restricted residuals e~_t = Z0t - alpha~ beta~#'Z1t - Psi~ Z2t;{break}
(i) recentre e~_c,t = e~_t - T^-1 sum e~_i and set e*_t = e~_c,t w_t, w_t iid from
{opt multiplier()} ({cmd:iid}: e*_t drawn with replacement from e~_c,t);{break}
(ii) generate dX*_t = alpha~ beta~#'(X*_(t-1)', D1(t)')' + sum Gamma~_j dX*_(t-j) +
mu~2 D2(t) + e*_t (eq. 21) with X*_t = X_t for the k initial values;{break}
(iii) re-compute on the bootstrap sample X*_t the unrestricted and restricted PML
estimates, LR*_T and
W*_T (with its own sandwich variance), exactly as on the data;{break}
(iv) p* = B^-1 sum 1(S*_T > S_T).{break}
Singular or explosive bootstrap samples (eigenvalue >= 1) are redrawn and counted. The
number of explosive companion roots of the restricted bootstrap DGP is reported (the
root check "can safely be ignored", BCRT Sec. 4.1).

{pstd}
{bf:Validity} (BCRT Cor. 2, Thm 5): bootstrap PLR for H0b valid under Assumption 2; for
H0a it needs 8+ moments (Assumption 2') and tau = 0 (no asymmetric volatility clustering);
for H0ab also rho = 0 (no leverage). Bootstrap Wald: H0b under Assumption 2, H0a under
Assumption 2', H0ab under 2' and rho = 0.

{pstd}
{bf:Bartlett correction} (Johansen 2000). Take H0: beta = H tau (H p x s, rho1 free) in a
model with n_D = d1 restricted and n_d unrestricted deterministic terms and lag order
k. Johansen's Corollary 6 gives E(LR_T)/(r(p - s)) = BC + O(T{c 94}-3/2) with{break}
BC = 1 + T^-1[(p + s - r + 1 + 2n_D)/2 + n_d + kp]
+ (Tr)^-1[(2p + s - 3r - 1 + 2n_D) v(alpha) + 2(c(alpha) + c_d(alpha))].{break}
The coefficients are those of Theorem 4. They are built from the stationary process
Y_t = (X_t'beta, dX_t', ..., dX_(t-k+2)')', of dimension m = r + (k-1)p, which satisfies
Y_t = P Y_(t-1) + Q e_t. P has first block row (I_r + beta'alpha, beta'Gamma_1, ...,
beta'Gamma_(k-1)), second block row (alpha, Gamma_1, ..., Gamma_(k-1)) and identity
blocks I_p below; Q = (beta, I_p, 0, ..., 0)' (eq. 30). Then:{break}
Sigma = Var(Y_t) = sum_v P{c 94}v Q Omega Q' P'{c 94}v (eq. 31), computed by the doubling
algorithm;{break}
V = kt kt' Sigma^-1 with kt = (I_r, 0)'(alpha'Omega^-1 alpha)^(-1/2) (eqs 34-35). V is an
m x m matrix: its first r rows are (alpha'Omega^-1 alpha)^-1 times the first r rows of
Sigma^-1, and its other rows are zero;{break}
v(alpha) = tr V = tr{(alpha'Omega^-1 alpha)^-1 Sigma_bb.z^-1};{break}
c(alpha) = tr{P(I_m + P)^-1 V} + tr{[P # (I_m - P)V][I_m # I_m - P # P]^-1};{break}
c_d(alpha) = tr{[M # (I_m - P)V][I_m # I_m - M # P]^-1} = n_d v(alpha). This holds
because every {opt trend()} case has d_t = 1 or (1,t)', so tr M{c 94}h = n_d (Johansen
2000, p. 757).{break}
Internally the hypothesis matrix is H# = blockdiag(H, I_d1) with s# = s + d1 columns. In
terms of s# the factor is
BC = 1 + T^-1[(p + s# - r + 1 + n_D)/2 + n_d + kp]
+ (Tr)^-1[(2p + s# - 3r - 1 + n_D)v + 2(c + n_d v)]. This is Theorem 4 at n_a = p# - r
(unrestricted) minus Theorem 4 at n_a = s# - r (restricted). It therefore reproduces
Corollary 6 when H has p rows and Corollary 5 when beta# (including rho1) is fully known
(s# = r). It is used unchanged for a general p# x s# matrix H (Extended
implementation).{break}
The evaluation point follows Johansen (2000, Secs 1 and 5): the parameters of the null
model (alpha, beta, Gamma, Omega) are replaced by their restricted (H0) PML estimates,
and the resulting error is O_P(T{c 94}-3/2). If the estimated P has an eigenvalue of
modulus {ul:>} 1, the I(1) assumption fails at the estimates and BC is set to missing.
The corrected statistic is LR_T/BC with a chi2(df) p-value. v(alpha) and c(alpha) are
stored in {cmd:e(tests)} (columns bc_v, bc_c).{break}
Not covered: Corollary 7 (only some cointegrating vectors known), R_b-form restrictions
that cannot be written as beta# = H*phi, and hypotheses that also restrict alpha.

{pstd}
{bf:Step -> equation map.} normalisation: BCRT Sec. 2.2 (B&D Sec. 2.3); hypotheses: BCRT
eq. (5); parameterisation: BCRT eq. (6), B&D eq. (39); moments and likelihood: BCRT eqs
(7)-(9); switching: B&D Sec. 4.4 (explicit phi, psi and Omega steps) and Sec. 3.2
(order, likelihood-based stopping); identification: B&D Thm 1, eqs (20), (40); closed
form beta# = H phi: Johansen (1996) Thm 7.2, B&D Sec. 4.2, Kurita (2013) eq. (6); PLR:
BCRT Sec. 3.1, B&D eq. (27); Wald: BCRT eq. (18); limits: BCRT Thms 1-2, Cor. 1;
bootstrap: BCRT Algorithm 1, eq. (21); Bartlett: Johansen (2000) Cor. 6 with Thm 4 and
eqs (30)-(35); corrected statistic: Johansen (2000) Sec. 1, Kurita (2013) eq. (8).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which test?} In BCRT's simulations the asymptotic tests are oversized even in their
valid cases (e.g. 13-49% at a nominal 5% for p = 3, T = 100), the distortions grow with
p, and the wild-bootstrap PLR test has the most accurate size, especially for joint
hypotheses; the wild-bootstrap Wald test is also good for alpha. Report the wild
bootstrap PLR p-value as the main result.

{pstd}
{bf:Normalisation.} The normalising variables must have a nonsingular r x r block in
beta (and must not be restricted to zero by the hypothesis); the command stops with a
message otherwise. Restrictions on rho1 are allowed through {opt bconstraints()} and
{opt hmatrix()}, but BCRT's asymptotic theory covers restrictions on beta2 only.

{pstd}
{bf:Bartlett correction: status.} The factor is implemented from Johansen (2000),
Corollary 6 and Theorem 4. tests/test_restrict.do checks it against Johansen's closed
form for the model with one lag and one cointegrating vector (Corollary 8, and v(alpha)
and c(alpha) of Sec. 5.1), and against the four special cases worked out in Sec. 5.2.
The correction is derived for iid Gaussian errors.{p_end}

{pstd}
Kurita (2013, eq. 9) uses Corollary 6 with Omega replaced by the unconditional error
variance under BEKK-GARCH errors. There it reduces the size distortion but does not
remove it (Kurita 2013, Table 1). It does not correct for nonstationary volatility; use
the wild bootstrap for that. Johansen (2000, Sec. 5.1) also warns that the correction
works poorly near the boundary of the I(1) model (weak adjustment, eta = beta'alpha
close to 0). There v(alpha) and c(alpha) are large and BC can be far from 1.{p_end}

{pstd}
Kurita's eq. (9) is Corollary 6 specialised to one restricted constant and no
unrestricted deterministic terms (n_D = 1, n_d = 0), with s the number of columns of the
beta-part of H. Earlier versions of this command took the factor from Kurita's 2009
working paper, and differed from Johansen's in four ways, all now corrected:{p_end}
{p 8 11 2}- the constant column of H was counted in s;{p_end}
{p 8 11 2}- n_d and c_d were ignored;{p_end}
{p 8 11 2}- n_D = 1 was fixed;{p_end}
{p 8 11 2}- only the leading r x r block of V was kept, so c(alpha) was wrong for
k > 1.{p_end}

{pstd}
{bf:Kurita's bootstrap.} In the published version (Kurita 2013, Sec. 4.3) the bootstrap
data are built from the {it:restricted} coefficients; the 2009 working paper used the
unrestricted ones. The {it:unrestricted} residuals, "sampled with replacement", are
multiplied by Gaussian (Case 1) or Rademacher (Case 2) weights, and
p = B^-1 sum 1(QLR* > QLR). Resampling the residuals destroys the time pattern of the
volatility, so this variant is not implemented. {cmd:method(wild)} (BCRT Algorithm 1)
keeps the recentred restricted residual e~_t at date t, and
{cmd:multiplier(rademacher)} gives Kurita's Case 2 weights.

{pstd}
{bf:Kurita's QLR} for beta* = H phi under BEKK-GARCH errors is exactly the PLR statistic
computed here with {opt hmatrix()}; its chi2 limit (Kurita 2013, eq. 7) requires
stationary GARCH (the spectral-radius regularity condition, Assumption 2.2) and no
unconditional variance changes.

{pstd}
{bf:Computation.} Each bootstrap replication re-estimates the unrestricted model, the
restricted model (closed form or switching) and the sandwich variance, so B = 999 with
{opt separate} takes three bootstrap loops. The switching algorithm can converge slowly
for some hypotheses on beta; non-convergence within {opt iterate()} is reported.

{pstd}
{bf:Not implemented.} Omtzigt and Fachin's (2006) unrestricted bootstrap (BCRT Remark
4.2), restrictions linking alpha and beta, and nonlinear restrictions.


{marker examples}{...}
{title:Examples}

{pstd}Simulated trivariate system with a variance break, r = 1{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen s = cond(t < 100, 2, 0.7)}{p_end}
{phang2}{cmd:. gen e1 = s*rnormal()}{p_end}
{phang2}{cmd:. gen e2 = s*rnormal()}{p_end}
{phang2}{cmd:. gen e3 = s*rnormal()}{p_end}
{phang2}{cmd:. gen y2 = sum(e2)}{p_end}
{phang2}{cmd:. gen y3 = sum(e3)}{p_end}
{phang2}{cmd:. gen y1 = 0}{p_end}
{phang2}{cmd:. replace y1 = L.y1 - 0.3*(L.y1 - L.y2) + e1 if t > 1}{p_end}

{pstd}Homogeneity (spreads) with asymptotic p-values only{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) spreads method(asy)}{p_end}

{pstd}Known cointegrating vector (1, -1, 0), wild bootstrap{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) known(1 -1 0) reps(199) seed(1)}{p_end}

{pstd}Weak exogeneity of y2 and y3, and joint test with beta = (1,-1,0)'{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) exog(y2 y3) reps(199) seed(1)}{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) known(1 -1 0) exog(y2 y3)}
{cmd:separate reps(199) seed(1)}{p_end}

{pstd}General restrictions: beta2# = (y2, y3, _cons) coefficients; H0: y3 coefficient = 0{p_end}
{phang2}{cmd:. matrix R = (0, 1, 0)}{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) bconstraints(R)}
{cmd:reps(199) seed(1)}{p_end}

{pstd}Johansen form with the Bartlett correction (Johansen 2000, Cor. 6), and
error-correction term{p_end}
{phang2}{cmd:. matrix H = (1, 0 \ -1, 0 \ 0, 0 \ 0, 1)}{p_end}
{phang2}{cmd:. cointvol restrict y1 y2 y3, lags(2) rank(1) hmatrix(H) bartlett method(asy)}{p_end}
{phang2}{cmd:. predict ect1, ect}{p_end}

{pstd}Replication of BCRT (2016) Sec. 6 (US term structure; see tests/test_restrict.do){p_end}
{phang2}{cmd:. cointvol restrict R3 R12 R36 R60 R120, lags(2) rank(4) spreads exog(R3)}
{cmd:separate reps(999) seed(20160101)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cointvol restrict} stores the following in {cmd:e()}. Scalars refer to the main
(last listed) hypothesis; all hypotheses are in {cmd:e(tests)}.

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}effective number of observations T{p_end}
{synopt:{cmd:e(lr)}, {cmd:e(lr_df)}}PLR statistic LR_T and its degrees of freedom{p_end}
{synopt:{cmd:e(lr_p_asy)}, {cmd:e(lr_p_boot)}}asymptotic and bootstrap p-values of LR_T{p_end}
{synopt:{cmd:e(wald)}, {cmd:e(wald_df)}}sandwich Wald statistic and df{p_end}
{synopt:{cmd:e(wald_p_asy)}, {cmd:e(wald_p_boot)}}asymptotic and bootstrap p-values of W_T{p_end}
{synopt:{cmd:e(bc)}, {cmd:e(lr_bc)}, {cmd:e(lr_bc_p)}}Bartlett factor, LR_T/BC, p-value{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(ll_r)}}unrestricted and restricted log pseudo-likelihood{p_end}
{synopt:{cmd:e(iter)}, {cmd:e(converged)}}switching iterations (0 = closed form), converged{p_end}
{synopt:{cmd:e(rank_J)}, {cmd:e(n_free)}}numerical rank of J(theta) at the restricted
estimates and number of free parameters l (Boswijk and Doornik 2004, eqs 20, 40){p_end}
{synopt:{cmd:e(rank)}, {cmd:e(lags)}, {cmd:e(p)}}r, k, number of variables{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(level)}, {cmd:e(tolerance)}}level and switching tolerance{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}, {cmd:e(tdelta)}}sample time range and delta{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cointvol restrict}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(varlist)}}variables{p_end}
{synopt:{cmd:e(trend)}}deterministic case{p_end}
{synopt:{cmd:e(normalize)}}normalising variables{p_end}
{synopt:{cmd:e(method)}, {cmd:e(multiplier)}, {cmd:e(pvalue)}}inference settings{p_end}
{synopt:{cmd:e(seed)}}seed as specified{p_end}
{synopt:{cmd:e(h_beta)}, {cmd:e(h_alpha)}}descriptions of the hypotheses{p_end}
{synopt:{cmd:e(hlabels)}}labels of the rows of {cmd:e(tests)}{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcetype)}}{cmd:sandwich}{p_end}
{synopt:{cmd:e(predict)}}{cmd:cointvol_restrict_p}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}unrestricted theta^ = ((vec beta2#)', (vec alpha')') and its
sandwich variance (BCRT eq. 18){p_end}
{synopt:{cmd:e(tests)}}one row per hypothesis: df, lr, lr_p_asy, lr_p_boot, lr_cv_boot, bc,
lr_bc, lr_bc_p, wald, wald_p_asy, wald_p_boot, wald_cv_boot, iter, converged, explosive,
redrawn, nonconv, rank_J, n_free, bc_v (v(alpha)), bc_c (c(alpha)){p_end}
{synopt:{cmd:e(beta)}, {cmd:e(alpha)}}unrestricted normalised PML estimates (p# x r, p x r){p_end}
{synopt:{cmd:e(se_beta)}, {cmd:e(se_alpha)}}their sandwich standard errors{p_end}
{synopt:{cmd:e(beta_r)}, {cmd:e(alpha_r)}}restricted PML estimates{p_end}
{synopt:{cmd:e(Pi)}, {cmd:e(Pi_r)}}alpha beta#' (p x p#){p_end}
{synopt:{cmd:e(Gamma)}, {cmd:e(Gamma_r)}}short-run and unrestricted deterministic
coefficients Psi (if any){p_end}
{synopt:{cmd:e(Omega)}, {cmd:e(Omega_r)}}PML residual covariance matrices{p_end}
{synopt:{cmd:e(eigenvalues)}}eigenvalues of the unrestricted problem{p_end}
{synopt:{cmd:e(boot_lr)}, {cmd:e(boot_wald)}}bootstrap statistics (B x #hypotheses){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample (excluding the k initial values){p_end}


{marker references}{...}
{title:References}

{phang}
Boswijk, H. P., G. Cavaliere, A. Rahbek, and A. M. R. Taylor. 2016. Inference on
co-integration parameters in heteroskedastic vector autoregressions.
{it:Journal of Econometrics} 192: 64-85.
{browse "https://doi.org/10.1016/j.jeconom.2015.07.005":doi:10.1016/j.jeconom.2015.07.005}.

{phang}
Boswijk, H. P., and J. A. Doornik. 2004. Identifying, estimating and testing restricted
cointegrated systems: An overview. {it:Statistica Neerlandica} 58: 440-465.
{browse "https://doi.org/10.1111/j.1467-9574.2004.00270.x":doi:10.1111/j.1467-9574.2004.00270.x}.
(Section and equation numbers cited in this help file follow the authors' version of
the paper, January 2003.)

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010. Testing for co-integration in
vector autoregressions with non-stationary volatility. {it:Journal of Econometrics} 158:
7-24. {browse "https://doi.org/10.1016/j.jeconom.2010.03.003":doi:10.1016/j.jeconom.2010.03.003}.

{phang}
Johansen, S. 1996. {it:Likelihood-Based Inference in Cointegrated Vector
Autoregressive Models}. Oxford: Oxford University Press.

{phang}
Johansen, S. 2000. A Bartlett correction factor for tests on the cointegrating
relations. {it:Econometric Theory} 16: 740-778.
{browse "https://doi.org/10.1017/S0266466600165065":doi:10.1017/S0266466600165065}.

{phang}
Hansen, P. R. 2002. Generalized reduced rank regression. Economics Working Paper
2002-02, Brown University.

{phang}
Kurita, T. 2013. Exploring the impact of multivariate GARCH innovations on hypothesis
testing for cointegrating vectors. {it:Communications in Statistics - Simulation and
Computation} 42: 1785-1800.
{browse "https://doi.org/10.1080/03610918.2012.677920":doi:10.1080/03610918.2012.677920}.
(Earlier version: CAES Working Paper WP-2009-006, Fukuoka University, 2009.)


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}

{pstd}
Please cite the original method papers above and the {cmd:cointvol} package.
{p_end}
