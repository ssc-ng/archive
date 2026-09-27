{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol diag" "help cointvol_diag"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol stoch" "help cointvol_stoch"}{...}
{vieweralsosee "cointvol hetcoint" "help cointvol_hetcoint"}{...}
{vieweralsosee "[R] simulate" "help simulate"}{...}
{viewerjumpto "Syntax" "cointvol_simulate##syntax"}{...}
{viewerjumpto "Description" "cointvol_simulate##description"}{...}
{viewerjumpto "DGPs" "cointvol_simulate##dgps"}{...}
{viewerjumpto "Options" "cointvol_simulate##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_simulate##methods"}{...}
{viewerjumpto "Remarks" "cointvol_simulate##remarks"}{...}
{viewerjumpto "Examples" "cointvol_simulate##examples"}{...}
{viewerjumpto "Stored results" "cointvol_simulate##results"}{...}
{viewerjumpto "References" "cointvol_simulate##references"}{...}
{viewerjumpto "Author" "cointvol_simulate##author"}{...}
{title:Title}

{p2colset 5 28 30 2}{...}
{p2col:{cmd:cointvol simulate} {hline 2}}Data-generating processes of the Monte Carlo
studies on cointegration under conditional and nonstationary volatility{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol simulate}{cmd:,} {opt n:obs(#)} {opt dgp(name)} [{it:options}]

{p 4 4 2}
{it:name} is one of {cmd:iid garch egarch agarch gjr sv break bekk ccc figarch oupath}
(innovation models; the output levels are random walks), {cmd:vecm} (cointegrated VAR
with any innovation model in {cmd:innov()}), {cmd:stochcoint} and {cmd:hci}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:General}
{p2coldent:* {opt n:obs(#)}}number of observations kept, {ul:>} 10{p_end}
{p2coldent:* {opt dgp(name)}}data-generating process{p_end}
{synopt:{opt clear}}replace the data in memory{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt burn:in(#)}}discarded start-up draws of the innovation recursion (defaults below){p_end}
{synopt:{opt nv:ars(#)}}number of series {it:p}; default 2{p_end}
{synopt:{opt pre:fix(name)}}stub of the level variables; default {cmd:y}{p_end}
{synopt:{opt epre:fix(name)}}stub of the innovations; default {cmd:e}{p_end}
{synopt:{opt hpre:fix(name)}}stub of the (conditional) variances; default {cmd:h}{p_end}
{synopt:{opt tv:ar(name)}}time variable; default {cmd:t}{p_end}
{synopt:{opt preset(name)}}parameter set of a published design (see {help cointvol_simulate##dgps:DGPs}){p_end}
{synopt:{opt dist:ribution(string)}}{cmd:normal} (default), {cmd:t} (unit variance) or
{cmd:skewt} (Hansen 1994){p_end}
{synopt:{opt df(#)}}degrees of freedom of t / skewed t; default 5{p_end}
{synopt:{opt skew(#)}}skewness parameter lambda in (-1,1) of the skewed t; default 0{p_end}
{synopt:{opt rho(#)}}equicorrelation of the standardised shocks (CCC correlation or
Sigma){p_end}
{synopt:{opt sig:ma(matname)}}p x p base covariance / correlation matrix (overrides {opt rho()}){p_end}

{syntab:GARCH family ({cmd:garch ccc egarch agarch gjr})}
{synopt:{opt omega(#)} {opt arch(#)} {opt garch(#)}}intercept, ARCH and GARCH coefficients{p_end}
{synopt:{opt asym(#)}}GJR asymmetry coefficient g{p_end}
{synopt:{opt shift(#)}}AGARCH shift gamma{p_end}
{synopt:{opt theta(#)}}EGARCH asymmetry theta{p_end}
{synopt:{opt nocenter}}EGARCH without the E|z| centring{p_end}
{synopt:{opt sq:uared}}EGARCH with z^2 in place of |z| (literal reading of CRT model C){p_end}

{syntab:Stochastic volatility, FIGARCH, BEKK}
{synopt:{opt lam:bda(#)} {opt sigxi(#)}}AR(1) SV persistence and s.d. of xi{p_end}
{synopt:{opt fracd(#)} {opt fcon:st(#)} {opt fphi(#)} {opt trunc(#)}}FIGARCH d, c, phi,
truncation lag (default 1000){p_end}
{synopt:{opt cmat(matname)} {opt amat(matname)} {opt bmat(matname)}}BEKK C, A, B{p_end}

{syntab:Volatility paths ({cmd:break oupath})}
{synopt:{opt tau(numlist)}}break fractions in (0,1){p_end}
{synopt:{opt sdr:atio(numlist)} | {opt varr:atio(numlist)}}post-break s.d. or variance ratio{p_end}
{synopt:{opt ser:ies(numlist)}}series affected (default all){p_end}
{synopt:{opt bspec(matname)}}rows (series, tau, variance ratio): per-component breaks{p_end}
{synopt:{opt base(#)}}pre-break variance multiplier; default 1{p_end}
{synopt:{opt vcase(2|3)}}Sigma_t = D_t Sigma D_t (2, default) or diag(v_t - 1) + Sigma (3){p_end}
{synopt:{opt kappa(#)} {opt zeta(#)}}OU mean reversion and volatility; default 1, 1{p_end}
{synopt:{opt pathseed(#)}}seed of the OU volatility path (hold the path fixed across
replications){p_end}

{syntab:VECM ({cmd:dgp(vecm)})}
{synopt:{opt innov(name)}}innovation model; default {cmd:iid}{p_end}
{synopt:{opt alp:ha(matname)} {opt bet:a(matname)}}p x r loadings and cointegrating vectors{p_end}
{synopt:{opt gam:ma(matname)}}p x p(k-1) matrix [Gamma_1, ..., Gamma_{k-1}]{p_end}
{synopt:{opt rcon:st(matname)}}1 x r restricted constant rho'{p_end}
{synopt:{opt mu(matname)}}1 x p unrestricted drift{p_end}
{synopt:{opt pres:ample(#)}}initial level observations discarded; default 0{p_end}

{syntab:{cmd:stochcoint} and {cmd:hci}}
{synopt:{opt type(hml|mlh)}}HML (2002) or MLH (2006) design{p_end}
{synopt:{opt phi() piy() pix() rho34() vsd()}}HML parameters{p_end}
{synopt:{opt d1() d2() d3() phiey() phiex() phivy() phivx()}}MLH parameters{p_end}
{synopt:{opt b0() b1() sigma0() s2() r12() r13() r23()}}Hansen (1992) parameters{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol simulate} replaces the data in memory by {opt nobs()} observations of a
data-generating process (DGP) from the Monte Carlo designs of the literature on
cointegration with GARCH, stochastic volatility and variance breaks. It is meant to
be used in {helpb simulate} or {helpb postfile} loops to study size and power of
{cmd:cointvol} (or any) tests, and to build examples. Every DGP states its source
paper and equation; parameters not given in the source are labelled provisional.

{pstd}
Innovation DGPs create {cmd:y1..yp} (random walks, y_t = y_{t-1} + e_t, y_0 = 0),
{cmd:e1..ep} (innovations) and {cmd:h1..hp} (conditional variances, or the variance
path for {cmd:break} and {cmd:oupath}); {cmd:bekk} with p = 2 also creates the
covariance {cmd:h12}. {cmd:dgp(vecm)} creates the same variables with the levels
generated by the cointegrated VAR. The data are {helpb tsset} by {cmd:t}.


{marker dgps}{...}
{title:DGPs, presets and sources}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:iid}}e_t = Sigma^{1/2} z_t. Benchmark.{p_end}
{p2col:{cmd:garch}}e_it = h_it^{1/2} z_it, h_it = omega + a e_{i,t-1}^2 + b h_{i,t-1},
independent across i. Original: Lee and Tse (1996, sec. 2); Franses, Kofman and Moser
(1994); CRT (2010, ET) model A. Defaults a = 0.3, b = 0.65, omega = 1 - a - b (unit
unconditional variance), burn-in 500, h_0 = omega/(1 - a - b). If a + b {ul:>} 1
(IGARCH), omega = 1 as in FKM (1994). Presets: {cmd:lt1}-{cmd:lt6} (Lee-Tse Table 1:
(0.3,0.6), (0.3,0.65), (0.3,0.699), (0.1,0.8), (0.1,0.85), (0.1,0.899)); {cmd:ltig}
(Table 3, a=0.3, b=0.7, omega=1); {cmd:ks1}, {cmd:ks09}, {cmd:ks001} (Table 4:
omega = 0.01 gamma, a = 0.3 gamma^{1/2}, b = 1 - a); {cmd:maki1}-{cmd:maki4} (Maki 2013
eqs. 32-33, C = I, a = psi^2, b = omega^2: (0.09,0.09), (0.36,0.36), (0.16,0.64),
(0.64,0.16)); {cmd:crt1}-{cmd:crt5} (CRT 2010 model A: (0,0), (0.5,0), (0.3,0.65),
(0.2,0.79), (0.05,0.94); omega = 1 - a - b assumed, not printed).{p_end}
{p2col:{cmd:ccc}}as {cmd:garch} with z_t having constant correlation matrix R
(equicorrelation {opt rho()}, default 0.5): z_2t = rho z_1t + (1-rho^2)^{1/2} z_3t for
p = 2. Original: Lee and Tse (1996) Table 6.{p_end}
{p2col:{cmd:egarch}}ln h_t = omega + a(|z_{t-1}| - E|z|) + theta z_{t-1} + b ln h_{t-1},
E|z| = (2/pi)^{1/2}. Presets {cmd:leetse} (default: omega = -0.0082, a = 0.19, theta =
-0.19, b = 0.91; Lee and Tse Table 6 after French and Sichel 1993), {cmd:leetse50}
(theta = -0.50), {cmd:crt} (CRT 2010 model C: ln h = -0.23 + 0.9 ln h + 0.25|z| -
0.075 z, no centring). The source prints |v^2_{t-1}| in model C; option {opt squared}
gives the literal z^2 reading (provisional).{p_end}
{p2col:{cmd:agarch}}h_t = omega + a(e_{t-1} - gamma)^2 + b h_{t-1}; default CRT (2010)
model D: omega = 0.0216, a = 0.3174, gamma = 0.1108, b = 0.6896.{p_end}
{p2col:{cmd:gjr}}h_t = omega + a e_{t-1}^2 + g 1(e_{t-1}<0) e_{t-1}^2 + b h_{t-1}.
Preset {cmd:cdrt} (default; CDRT 2018 case A: a = 0.03, g = 0.04, b = 0.92, skewed t
with nu = 5 degrees of freedom and skewness parameter delta = -0.1, mapped to Hansen's
(1994) eta = 5 and lambda = -0.1; omega is not reported by CDRT and is set to the
unit-variance normalisation omega = 1 - a - g kappa - b = 0.0283377, kappa =
E[z^2 1(z<0)] = 0.5415574, returned in {cmd:r(gjr_kappa)}; see Methods). Preset
{cmd:crt} (CRT 2010 model E, h = 0.005 + 0.7 h + 0.28(|e| - 0.23 e)^2, which equals
GJR with a = 0.28(0.77)^2 = 0.166012 and g = 0.28(1.23^2 - 0.77^2) = 0.2576).{p_end}
{p2col:{cmd:sv}}e_t = v_t exp(h_t), h_t = lambda h_{t-1} + 0.5 xi_t, xi_t ~ N(0,
sigma_xi^2); variance exp(2 h_t). Presets {cmd:crt} (lambda = 0.951, sigma_xi = 0.314;
CRT 2010 model F, CDRT case B, BCDT) and {cmd:crt2} (0.936, 0.424).{p_end}
{p2col:{cmd:break}}Sigma_t built from variance multipliers v_it = base before
floor(tau T) and base x ratio after. Presets {cmd:cdrt} (default; tau = 2/3,
variance ratio 3, CDRT case C), {cmd:bcdt} (tau = 2/3, s.d. ratio 3 = variance 9),
{cmd:bz} (base 0.5, ratio 6, tau = 0.8, rho = 0.4: Boswijk-Zu cases 2-3),
{cmd:bcrt} (base 2, ratio 0.25, tau = 1/3, rho = 0.4: BCRT 2016). CRT (2010, JoE):
common break on the first j series with s.d. ratio delta: {cmd:series(1/j) sdratio(delta)};
Maki (2013) VB1-12: {cmd:varratio()}; Cavaliere and Taylor (2006) component-specific
breaks: {opt bspec()}.{p_end}
{p2col:{cmd:bekk}}H_t = C + A e_{t-1}e_{t-1}' A' + B H_{t-1} B', e_t = chol(H_t) z_t,
H_0 = unconditional covariance when rho(A (x) A + B (x) B) < 1. Presets
{cmd:maki5}-{cmd:maki8} (default {cmd:maki5}; Maki 2013 eqs. 37-38: C = [1 .5; .5 1],
A = [psi .5; 0 psi], B = [w .5; 0 w], (psi, w) = (.3,.3), (.6,.6), (.4,.8), (.8,.4)) and
{cmd:kurita70}, {cmd:kurita80}, {cmd:kurita85}, {cmd:kurita90} (Kurita 2009: C =
0.06^2 [1 .5; .5 1], A = [.5 .5; 0 .5], B = [phi .5; 0 phi]).{p_end}
{p2col:{cmd:figarch}}CCC-FIGARCH(1,d,1): h_t = c + b h_{t-1} + [1 - bL - (1 - phi L)(1-L)^d]
e_t^2, truncated at {opt trunc()} lags. Presets {cmd:maki1}-{cmd:maki12} (Maki 2013
FIGARCH1-12: (d,a,b) = (.4,.4,.4), (.4,.2,.6), (.4,.6,.2), (.8,.4,.4), (.8,.2,.6), (.8,.6,.2),
rho = 0 for 1-6 and 0.8 for 7-12), phi = 1 - a - b as printed by Maki. c is not given in
the source: default {opt fconst(0.1)} (provisional). Default burn-in = trunc + 500.{p_end}
{p2col:{cmd:oupath}}Sigma_t = exp(2 H(t/T)) Sigma, H(u) Euler OU:
H_t = (1 - kappa/T) H_{t-1} + zeta T^{-1/2} eta_t, H_0 = 0 (Boswijk and Zu 2022,
case 4; kappa = zeta = 1, rho = 0.4). With {opt pathseed()} the volatility path is drawn
from its own seed and is identical across calls, as in BZ.{p_end}
{p2col:{cmd:vecm}}dX_t = alpha(beta'X_{t-1} + rho') + sum_j Gamma_j dX_{t-j} + mu + e_t,
X_0 = 0, dX_{c -(}t{ul:<}0{c )-} = 0, e_t from {opt innov()}. Default (p = 2): alpha =
(-0.2, 0)', beta = (1, -1)' (Lee and Tse 1996 power design). CRT (2010ab), CDRT (2018),
BCDT (2022) and BCRT (2016) designs are obtained with the corresponding alpha, beta,
gamma and {opt innov()}.{p_end}
{p2col:{cmd:stochcoint}}{cmd:type(hml)} (default): Harris, McCabe and Leybourne (2002,
sec. 4): y = pi_y w + e_y, x = pi_x w + v_x w + e_x, AR(phi) components, v_x innovation
s.d. {opt vsd()} (default 0.05^{1/2}), corr(e1,e4) = corr(e2,e4) = 0.5,
corr(e3,e4) = {opt rho34()}. {cmd:type(mlh)}: McCabe, Leybourne and Harris (2006) eq. (10),
y = w1 + e_y + nu_y h1, x = w1 + d1 w2 + e_x + nu_x h2, burn-in 100. Creates
{cmd:y1} (y), {cmd:y2} (x) and {cmd:y_w} (w1).{p_end}
{p2col:{cmd:hci}}Hansen (1992) eqs. (1)-(4): y = b0 + b1 sum x + sigma_t u1,
sigma_t = sigma_{t-1} + u2 (sigma_0 = {opt sigma0()}), x_t = x_{t-1} + u3; (u1, u2, u3)
normal with s.d. (1, {opt s2()}, 1) and correlations r12, r13, r23. Creates y1 (y),
y2..yp (regressors), e1 (sigma_t u1) and h1 (sigma_t^2).{p_end}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{phang}
{opt nobs(#)}, {opt dgp()} are required. {opt clear} must be specified if data are in
memory. {opt seed()} sets the Stata seed; all draws use the Stata RNG so results are
reproducible.

{phang}
{opt burnin(#)} start-up draws discarded from the innovation recursion. Defaults: 500
for {cmd:garch ccc egarch agarch gjr sv bekk} (Lee and Tse 1996), trunc + 500 for
{cmd:figarch}, 100 for {cmd:stochcoint, type(mlh)}, 0 otherwise. The VECM levels always
start at X_0 = 0; use {opt presample()} to discard initial level observations.

{phang}
{opt distribution()}, {opt df()}, {opt skew()} choose the standardised shocks z_t.
{cmd:t}: Student t scaled to unit variance (CRT 2010 model B uses df = 5). {cmd:skewt}:
Original: Hansen (1994, eqs. 10-13) skewed t with zero mean and unit variance, degrees of
freedom eta = {opt df()} > 2 and skewness lambda = {opt skew()} in (-1, 1)
(lambda < 0: left skew, mode to the right of zero); exact inverse-CDF draws.

{phang}
{opt rho()} / {opt sigma()}: for {cmd:iid break oupath} Sigma is the base covariance;
for the GARCH family, SV and FIGARCH it is converted to a correlation matrix R (CCC).

{phang}
All other options are listed with their DGP above; unspecified parameters take the
values of the default preset.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Recursions.} For the GARCH family the recursion is started at the unconditional
variance (or 1 if it does not exist), run for burn-in + 1 + T periods and the first
burn-in + 1 draws are discarded. EGARCH is started at exp(E ln h).

{pstd}
{bf:Skewed t (Hansen 1994, verified against the published scan).} Density (10):
g(z|eta,lambda) = b c [1 + ((b z + a)/(1 - lambda))^2/(eta - 2)]^{-(eta+1)/2} for
z < -a/b and the same with 1 + lambda for z {ul:>} -a/b, 2 < eta < inf, -1 < lambda < 1,
with a = 4 lambda c (eta-2)/(eta-1) (11), b^2 = 1 + 3 lambda^2 - a^2 (12) and
c = Gamma((eta+1)/2)/[(pi(eta-2))^{1/2} Gamma(eta/2)] (13); E z = 0, Var z = 1, lambda = 0
gives the unit-variance t (9). With y = b z + a and F_q the unit-variance t cdf,
the cdf is G(z) = (1-lambda) F_q(y/(1-lambda)) for y < 0 and
(1-lambda)/2 + (1+lambda)[F_q(y/(1+lambda)) - 1/2] for y {ul:>} 0. Draws use the exact
inverse: for u ~ U(0,1), y = (1-lambda) F_q^-1(u/(1-lambda)) if u < (1-lambda)/2, else
y = (1+lambda) F_q^-1(1/2 + (u - (1-lambda)/2)/(1+lambda)); z = (y - a)/b, with
F_q^-1(p) = ((eta-2)/eta)^{1/2} {cmd:invttail}(eta, 1 - p).

{pstd}
{bf:GJR with skewed-t shocks.} E h_t = omega/(1 - a - g kappa - b) with
kappa = E[z^2 1(z<0)] (1/2 for symmetric shocks). For Hansen's density kappa has a closed
form from the truncated moments of the unit-variance t, M_k(x) = int_{-inf}^x v^k f_q(v)dv:
M_0 = F_eta(x/s), M_1 = -c(eta-2)/(eta-1) [1 + x^2/(eta-2)]^{-(eta-1)/2},
M_2 = (eta-1) F_{eta-2}(x) - (eta-2) F_eta(x/s), s = ((eta-2)/eta)^{1/2}. For CDRT case A
(eta, lambda) = (5, -0.1): a = -0.1470210, b = 1.0041837, c = 0.4900701,
kappa = 0.5415574, E z^3 = -0.4375, P(z < 0) = 0.4783754.

{pstd}
{bf:FIGARCH.} (1-L)^d = sum_k pi_k L^k with pi_0 = 1, pi_k = pi_{k-1}(k-1-d)/k;
lambda_1 = -b - (pi_1 - phi) = d + phi - b, lambda_k = -(pi_k - phi pi_{k-1}) for k {ul:>} 2;
h_t = c + b h_{t-1} + sum_{k=1}^{trunc} lambda_k e_{t-k}^2, pre-sample e^2 = 1.
Non-positive variances are floored at 1e-8 and counted in {cmd:r(n_negvar)}.

{pstd}
{bf:Variance paths.} vcase 2: e_t = D_t chol(Sigma) z_t, D_t = diag(v_t^{1/2}) (for a common
v_t this is Sigma_t = v_t Sigma, BZ/BCRT case 2). vcase 3: e_t = chol(diag(v_t - 1) + Sigma) z_t
(BCRT case 3). Breaks occur after floor(tau T) (CDRT convention).

{pstd}
{bf:VECM.} Companion moduli of the specified VECM are computed and reported (unit roots
should equal p - r; explosive roots trigger a warning).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Original vs extended / provisional.} All DGP formulas are original (source given
above). CDRT (2018) describe case A only as a skewed t with nu degrees of freedom and
skewness parameter delta; the Hansen (1994) density is the standard skewed t with exactly
these two parameters and an admissible range containing delta = -0.1, and is used here.
Choices where the source is silent: omega in CRT model A/B; omega in CDRT case A (set to
the unit-variance normalisation above); FIGARCH constant c (Maki gives none) and
the reading phi = 1 - a - b (Maki's print; with phi = a + b FIGARCH1 violates the
Bollerslev-Mikkelsen positivity conditions, whereas Maki's reading satisfies them for all
twelve designs); EGARCH |z| vs z^2 in CRT model C; the OU path is simulated on the
sample grid (BZ use a grid of 1000 points and subsample).

{pstd}
{bf:Monte Carlo loops.} Vary {opt seed()} across replications, or set the seed once
before the loop and omit {opt seed()} inside it. Use {opt pathseed()} to keep one OU
volatility path across replications, as Boswijk and Zu (2022) do.

{pstd}
{bf:Lee-Tse burn-in.} Lee and Tse (1996, fn. 1) show that a short burn-in with a tiny
omega (IGARCH) distorts size badly; keep the default 500.


{marker examples}{...}
{title:Examples}

{pstd}Lee-Tse null DGP: two independent GARCH(1,1) random walks{p_end}
{phang2}{cmd:. cointvol simulate, nobs(100) dgp(garch) preset(lt3) seed(101) clear}{p_end}

{pstd}CRT (2010) model F stochastic volatility, p = 5{p_end}
{phang2}{cmd:. cointvol simulate, nobs(200) dgp(sv) nvars(5) seed(1) clear}{p_end}

{pstd}CRT (2010, JoE): common s.d. break delta = 3 at tau = 1/3 on the first 2 of 5 series{p_end}
{phang2}{cmd:. cointvol simulate, nobs(200) dgp(break) nvars(5) tau(0.3333) sdratio(3) series(1 2) seed(2) clear}{p_end}

{pstd}Maki (2013) BEKK GARCH8 and FIGARCH7{p_end}
{phang2}{cmd:. cointvol simulate, nobs(400) dgp(bekk) preset(maki8) seed(3) clear}{p_end}
{phang2}{cmd:. cointvol simulate, nobs(400) dgp(figarch) preset(maki7) seed(4) clear}{p_end}

{pstd}CDRT (2018) VAR(2), r = 1, gamma = 0.5, GJR skewed-t errors{p_end}
{phang2}{cmd:. matrix a = (-0.4 \ 0 \ 0 \ 0)}{p_end}
{phang2}{cmd:. matrix b = (1 \ 0 \ 0 \ 0)}{p_end}
{phang2}{cmd:. matrix G = 0.5*I(4)}{p_end}
{phang2}{cmd:. cointvol simulate, nobs(200) dgp(vecm) alpha(a) beta(b) gamma(G) innov(gjr) seed(5) clear}{p_end}
{phang2}{cmd:. cointvol rank y1 y2 y3 y4, lags(2) reps(199) seed(6)}{p_end}

{pstd}Boswijk-Zu case 4 with a fixed OU volatility path{p_end}
{phang2}{cmd:. cointvol simulate, nobs(500) dgp(oupath) pathseed(20160119) seed(7) clear}{p_end}

{pstd}Stochastic and heteroskedastic cointegration{p_end}
{phang2}{cmd:. cointvol simulate, nobs(400) dgp(stochcoint) type(hml) phi(0.4) seed(8) clear}{p_end}
{phang2}{cmd:. cointvol simulate, nobs(400) dgp(hci) seed(9) clear}{p_end}

{pstd}Size of the wild bootstrap rank test under strong GARCH (sketch){p_end}
{phang2}{cmd:. program define mysim, rclass}{p_end}
{phang2}{cmd:.     cointvol simulate, nobs(100) dgp(garch) preset(lt3) clear}{p_end}
{phang2}{cmd:.     cointvol rank y1 y2, lags(1) rank(0) reps(99) nodots}{p_end}
{phang2}{cmd:.     return scalar rej = (el(r(stats),1,5) < 0.05)}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. simulate rej = r(rej), reps(200): mysim}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol simulate} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(p)}}observations, series{p_end}
{synopt:{cmd:r(burnin)}, {cmd:r(presample)}}discarded draws / levels{p_end}
{synopt:{cmd:r(omega)}, {cmd:r(arch)}, {cmd:r(garch)}, ...}parameters actually used
({cmd:asym shift theta lambda sigxi fracd fconst fphi base kappa zeta df skew trunc}){p_end}
{synopt:{cmd:r(n_negvar)}}floored FIGARCH variances{p_end}
{synopt:{cmd:r(gjr_kappa)}}kappa = E[z^2 1(z<0)] used for the GJR normalisation{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol simulate}{p_end}
{synopt:{cmd:r(dgp)}, {cmd:r(innov)}, {cmd:r(preset)}}DGP, innovation model, preset{p_end}
{synopt:{cmd:r(distribution)}, {cmd:r(vcase)}, {cmd:r(seed)}}settings{p_end}
{synopt:{cmd:r(varlist)}}variables created{p_end}
{synopt:{cmd:r(source)}}source papers of the design{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(Sigma)}}base covariance / correlation{p_end}
{synopt:{cmd:r(bspec)}}break specification (series, tau, variance ratio){p_end}
{synopt:{cmd:r(C)}, {cmd:r(A)}, {cmd:r(B)}}BEKK matrices{p_end}
{synopt:{cmd:r(alpha)}, {cmd:r(beta)}, {cmd:r(gamma)}, {cmd:r(rconst)}, {cmd:r(mu)}}VECM matrices{p_end}
{synopt:{cmd:r(roots)}}companion moduli of the specified VECM{p_end}


{marker references}{...}
{title:References}

{phang}
Boswijk, H. P., G. Cavaliere, A. Rahbek, and A. M. R. Taylor. 2016. Inference on
co-integration parameters in heteroskedastic vector autoregressions.
{it:Journal of Econometrics} 192: 64-85.
{browse "https://doi.org/10.1016/j.jeconom.2015.07.005":doi:10.1016/j.jeconom.2015.07.005}.

{phang}
Boswijk, H. P., and Y. Zu. 2022. Adaptive testing for cointegration with nonstationary
volatility. {it:Journal of Business & Economic Statistics} 40: 744-755.
{browse "https://doi.org/10.1080/07350015.2020.1867558":doi:10.1080/07350015.2020.1867558}.

{phang}
Boswijk, H. P., G. Cavaliere, L. De Angelis, and A. M. R. Taylor. 2022. Adaptive
information-based methods for determining the co-integration rank in heteroskedastic
VAR models. arXiv:2202.02532.

{phang}
Cavaliere, G., L. De Angelis, A. Rahbek, and A. M. R. Taylor. 2018. Determining the
cointegration rank in heteroskedastic VAR models of unknown order.
{it:Econometric Theory} 34: 349-382.
{browse "https://doi.org/10.1017/S0266466616000335":doi:10.1017/S0266466616000335}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010. Co-integration rank testing under
conditional heteroskedasticity. {it:Econometric Theory} 26: 1719-1760.
{browse "https://doi.org/10.1017/S0266466609990776":doi:10.1017/S0266466609990776}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010. Testing for co-integration in
vector autoregressions with non-stationary volatility. {it:Journal of Econometrics}
158: 7-24.
{browse "https://doi.org/10.1016/j.jeconom.2010.03.003":doi:10.1016/j.jeconom.2010.03.003}.

{phang}
Cavaliere, G., and A. M. R. Taylor. 2006. Testing the null of co-integration in the
presence of variance breaks. {it:Journal of Time Series Analysis} 27: 613-636.
{browse "https://doi.org/10.1111/j.1467-9892.2006.00475.x":doi:10.1111/j.1467-9892.2006.00475.x}.

{phang}
Franses, P. H., P. Kofman, and J. Moser. 1994. GARCH effects on a test of
cointegration. {it:Review of Quantitative Finance and Accounting} 4: 19-26.
{browse "https://doi.org/10.1007/BF01082662":doi:10.1007/BF01082662}.

{phang}
Hansen, B. E. 1992. Heteroskedastic cointegration. {it:Journal of Econometrics} 54:
139-158.
{browse "https://doi.org/10.1016/0304-4076(92)90103-X":doi:10.1016/0304-4076(92)90103-X}.

{phang}
Hansen, B. E. 1994. Autoregressive conditional density estimation.
{it:International Economic Review} 35: 705-730.
{browse "https://doi.org/10.2307/2527081":doi:10.2307/2527081}.

{phang}
Harris, D., B. McCabe, and S. Leybourne. 2002. Stochastic cointegration: estimation and
inference. {it:Journal of Econometrics} 111: 363-384.
{browse "https://doi.org/10.1016/S0304-4076(02)00111-2":doi:10.1016/S0304-4076(02)00111-2}.

{phang}
Kurita, T. 2013. Exploring the impact of multivariate GARCH innovations on hypothesis
testing for cointegrating vectors. {it:Communications in Statistics - Simulation and
Computation}.
{browse "https://doi.org/10.1080/03610918.2012.677920":doi:10.1080/03610918.2012.677920}.
(Working paper version: CAES WP-2009-006, Fukuoka University.)

{phang}
Lee, T.-H., and Y. Tse. 1996. Cointegration tests with conditional heteroskedasticity.
{it:Journal of Econometrics} 73: 401-410.
{browse "https://doi.org/10.1016/S0304-4076(95)01745-3":doi:10.1016/S0304-4076(95)01745-3}.

{phang}
Maki, D. 2013. The influence of heteroskedastic variances on cointegration tests: A
comparison using Monte Carlo simulations. {it:Computational Statistics} 28: 179-198.
{browse "https://doi.org/10.1007/s00180-011-0293-x":doi:10.1007/s00180-011-0293-x}.

{phang}
McCabe, B., S. Leybourne, and D. Harris. 2006. A residual-based test for stochastic
cointegration. {it:Econometric Theory} 22(3).
{browse "https://doi.org/10.1017/S026646660606021X":doi:10.1017/S026646660606021X}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
