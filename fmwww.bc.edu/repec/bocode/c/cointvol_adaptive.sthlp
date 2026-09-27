{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol select" "help cointvol_select"}{...}
{vieweralsosee "[TS] vecrank" "help vecrank"}{...}
{viewerjumpto "Syntax" "cointvol_adaptive##syntax"}{...}
{viewerjumpto "Description" "cointvol_adaptive##description"}{...}
{viewerjumpto "Options" "cointvol_adaptive##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_adaptive##methods"}{...}
{viewerjumpto "Remarks" "cointvol_adaptive##remarks"}{...}
{viewerjumpto "Examples" "cointvol_adaptive##examples"}{...}
{viewerjumpto "Stored results" "cointvol_adaptive##results"}{...}
{viewerjumpto "References" "cointvol_adaptive##references"}{...}
{viewerjumpto "Author" "cointvol_adaptive##author"}{...}
{title:Title}

{p2colset 5 27 29 2}{...}
{p2col:{bf:cointvol adaptive} {hline 2}}Adaptive likelihood-ratio cointegration rank test under
nonstationary volatility (Boswijk and Zu 2022){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cointvol adaptive} {varlist} {ifin}{cmd:,} {opt l:ags(#)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt l:ags(#)}}lag order {it:k} of the VAR in levels{p_end}
{synopt:{opt tr:end(dcase)}}deterministic case: {cmd:none}, {cmd:rconstant} (default),
{cmd:constant}, {cmd:rtrend}{p_end}
{synopt:{opt r:ank(numlist)}}null ranks to test; default 0,...,{it:p}-1{p_end}

{syntab:Volatility}
{synopt:{opt bw(cv|#)}}bandwidth {it:h} as a fraction of the sample; {cmd:cv} (default) =
leave-one-out cross-validation{p_end}
{synopt:{opt ker:nel(gauss)}}kernel; only the Gaussian kernel is available (default){p_end}

{syntab:Bootstrap}
{synopt:{opt m:ethod(list)}}{cmd:vbs} (volatility bootstrap) and/or {cmd:wild}; default both{p_end}
{synopt:{opt boot:dgp(type)}}restricted estimates of the bootstrap DGP: {cmd:adaptive}
(default) or {cmd:johansen}{p_end}
{synopt:{opt r:eps(#)}}bootstrap replications; default {cmd:999}; {cmd:0} = statistics only{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}

{syntab:Algorithm and reporting}
{synopt:{opt tol:erance(#)}}convergence tolerance of the switching algorithm; default 1e-7{p_end}
{synopt:{opt iter:ate(#)}}maximum number of switching iterations; default 1000{p_end}
{synopt:{opt l:evel(#)}}level used for stars and sequential rank selection; default
{cmd:c(level)}{p_end}
{synopt:{opt gr:aph}}plot the estimated volatilities sqrt(Sigma_t,ii){p_end}
{synopt:{opt graphn:ame(name)}}name of the graph; default {cmd:cointvol_adaptive}{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required. The data must be {helpb tsset} (not a panel) with no gaps;
time-series operators are allowed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol adaptive} computes the adaptive likelihood-ratio (ALR) test of the cointegration
rank of Boswijk and Zu (2022). Under nonstationary (time-varying, deterministic) volatility
Sigma_t, the Johansen trace test remains valid with a wild bootstrap but loses power, because
it weights all observations equally. The ALR test replaces the constant covariance matrix in the
Gaussian likelihood by a two-sided kernel estimate of Sigma_t and maximises the resulting
generalized least-squares likelihood by generalized reduced-rank regression. The test is
adaptive: it has the same asymptotic local power as the infeasible test that knows Sigma_t.

{pstd}
Its null distribution depends on the volatility path, so p-values are obtained by the
volatility bootstrap (VBS) and by the wild bootstrap (WBS). The standard Johansen trace
statistic (PLR) is reported side by side with its asymptotic, VBS and WBS p-values, as in
Tables 1, 4 and 5 of the paper.

{pstd}
Use it when the variables show volatility shifts or trending volatility (e.g. the Great
Moderation, crisis periods). With conditionally heteroskedastic but unconditionally stationary
errors the ALR offers no power gain (Boswijk et al. 2023, Remark 2); use {helpb cointvol_rank}
there. The volatility must be smooth or have a finite number of breaks; the method is not
designed for very short samples (the paper uses n = 500, 1000).


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets the lag order {it:k} >= 1 of the VAR in levels, as in {helpb vec}. The model
has {it:k}-1 lagged differences. {cmd:cointvol select} can choose {it:k}.
Original: BZ (2022) eq. (2).

{phang}
{opt trend(dcase)} sets the deterministic terms. {cmd:none}: no deterministics (BZ eq. 2).
{cmd:rconstant}: constant restricted to the cointegration space (BZ eq. 17; default).
{cmd:rtrend}: linear trend restricted to the cointegration space plus unrestricted constant
(BZ eq. 18). {cmd:constant}: unrestricted constant (Extended implementation: the GRRR and
bootstrap are identical; the paper does not discuss this case). {cmd:trend} is not allowed.

{phang}
{opt rank(numlist)} lists the null ranks r to test (0 <= r <= p-1). The sequential rank
selection is reported only when all of 0,...,p-1 are tested.

{phang}
{opt bw(cv|#)} sets the bandwidth h of the Gaussian kernel as a fraction of the effective sample
size n, i.e. the weights are phi((t-s)/(n h)); h_obs = n h is the bandwidth in observations
(the convention of the authors' TermStructure program; the Monte Carlo library uses h_obs).
{cmd:bw(cv)} (default) minimises the leave-one-out cross-validation criterion (BZ eq. 20):
a log-spaced grid of 40 values on [1/n, 1] is followed by a golden-section refinement.
Original: BZ (2022) eqs. (19)-(20).

{phang}
{opt kernel(gauss)}: the Gaussian kernel used in all of the authors' code. BZ Assumption 3 allows
any bounded, continuous, two-sided kernel; only the Gaussian one is implemented.

{phang}
{opt method(list)} chooses the bootstrap(s): {cmd:vbs}, e*_t = Sigma_t{c 94}(1/2) z_t with z_t iid
N(0, I_p) and the symmetric square root; {cmd:wild}, e*_t = e_t w_t with e_t the unrestricted
OLS residuals and w_t iid N(0,1) (a scalar per t). Default: both. Original: BZ (2022) Sec. 4.2.

{phang}
{opt bootdgp(type)}: restricted rank-r estimates used in the bootstrap recursion (BZ eq. 21).
{cmd:adaptive} (default) uses the GRRR estimates (alpha~, beta~, Gamma~, deterministics), as in
the authors' term-structure and PPP programs; {cmd:johansen} uses the Gaussian reduced-rank
estimates, as in the authors' Monte Carlo library and BCDT (2023) eq. (3.7). The two are
first-order equivalent. The same DGP and the same draws are used for PLR* and ALR*.

{phang}
{opt reps(#)} number of bootstrap replications B (default 999, as in the empirical section of
the paper; 499 in its Monte Carlo). {cmd:reps(0)} reports statistics and asymptotic PLR
p-values only.

{phang}
{opt seed(string)} sets the random-number seed (see {helpb set seed}).

{phang}
{opt tolerance(#)} and {opt iterate(#)}: the switching algorithm stops when the concentrated
log-likelihood changes by less than {it:#} (the authors use 1e-6) or after {opt iterate()}
iterations.

{phang}
{opt level(#)} sets the level for the significance stars and the sequential rank choice
(first r whose p-value exceeds 1-level/100).

{phang}
{opt graph} draws the estimated volatilities sqrt(Sigma_t,ii) over time (cf. BZ Figures 1-2).
{opt graphname()} names it.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model.} The VECM (BZ eq. 2), with deterministic terms as in eqs. (17)-(18),

{p 8 8 2}
dX_t = alpha beta#' X#(t-1) + Gamma_1 dX(t-1) + ... + Gamma(k-1) dX(t-k+1) + mu d_t + e_t,
{space 2}e_t = sigma_t z_t, {space 2}Sigma_t = sigma_t sigma_t',

{pstd}
with X#(t-1) = X(t-1) ({cmd:none}, {cmd:constant}), (X(t-1)', 1)' ({cmd:rconstant}) or
(X(t-1)', t)' ({cmd:rtrend}), and d_t = 1 for {cmd:constant} and {cmd:rtrend}. sigma(u) is
nonstochastic, nonsingular and piecewise Lipschitz; z_t is a martingale difference sequence
with identity conditional variance (BZ Assumption 2). H(r): rank(alpha beta#') <= r against
H(p).

{pstd}
{bf:Step 1: volatility estimate.} e_t are the OLS residuals of the unrestricted model H(p)
(including deterministics). With the Gaussian kernel K,

{p 8 8 2}
Sigma_t = sum_s K((t-s)/(n h)) e_s e_s' / sum_s K((t-s)/(n h)){space 4}(BZ eq. 19)

{pstd}
a two-sided Nadaraya-Watson smoother; near the sample ends the weights are simply renormalised
(no boundary correction, as in BZ Assumption 3 and the authors' code). The bandwidth minimises
CV(h) = sum_t ||Sigma_t{c 94}(-t)(h) - e_t e_t'||{c 94}2 (Frobenius norm, BZ eq. 20),
where Sigma_t{c 94}(-t)
omits observation t; it is computed with the exact identity
e_t e_t' - Sigma_t{c 94}(-t) = (e_t e_t' - Sigma_t)/(1 - w_tt).

{pstd}
{bf:Step 2: adaptive estimation.} With Sigma_t plugged in, the Gaussian log-likelihood is
-(1/2) sum_t log|Sigma_t| - (1/2) sum_t e_t' Sigma_t{c 94}(-1) e_t (BZ eq. 7). The unrestricted
H(p) estimates are GLS (BZ eqs. 11-12). Under H(r) the switching algorithm of BZ eqs. (9)-(10)
(Hansen 2003) alternates GLS for (alpha, Gamma) given beta and GLS for beta given (alpha,
Gamma), starting from the Johansen eigenvectors, until the log-likelihood increase is below
{opt tolerance()}. Gamma and the unrestricted deterministics are concentrated out exactly.

{pstd}
{bf:Step 3: statistics.}
ALR(r) = sum_t (e~_t' Sigma_t{c 94}(-1) e~_t - e{c 94}_t' Sigma_t{c 94}(-1) e{c 94}_t)
(BZ eq. 13), e~_t restricted and e{c 94}_t unrestricted GLS residuals; the log|Sigma_t| terms
cancel. The Johansen trace PLR(r) = -n sum(i>r) log(1-lambda_i) is computed from the same
sample, with an asymptotic p-value from the Gamma approximation to the Johansen limit (valid
only when volatility is constant).

{pstd}
{bf:Step 4: bootstrap} (BZ Sec. 4.2, eq. 21). For b = 1,...,B: (i) draw e*_t = Sigma_t{c 94}(1/2)
z*_t (VBS) or e*_t = e_t w*_t (WBS); (ii) generate X*_t recursively from the restricted rank-r
estimates (see {opt bootdgp()}), deterministics included, initialised at the observed first k
values; (iii) on X*_t compute PLR*(r) and ALR*(r), the latter with the ORIGINAL Sigma_t (Sigma_t
is not re-estimated); (iv) p = B{c 94}(-1) sum_b 1(Q*_b > Q). Samples whose Johansen moment
matrices are singular are redrawn and counted. The sequential rank estimate is the first r in
0,1,...,p-1 with p-value > 1-level/100 (p if all reject).

{pstd}
{bf:Step-to-source map.} e_t, Sigma_t: BZ eq. (19), Sec. 4.1; bandwidth: eq. (20); GRRR:
eqs. (9)-(10); GLS: eqs. (11)-(12); ALR: eq. (13); deterministics: eqs. (17)-(18); bootstrap:
eq. (21), Sec. 4.2, Theorem 3; asymptotics: Theorems 1-2.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Original versus extended.} Original (BZ 2022): the ALR statistic, Gaussian-kernel Sigma_t,
leave-one-out CV bandwidth, VBS and WBS p-values, restricted constant and restricted trend,
PLR with VBS/WBS p-values. Extended implementation: {cmd:trend(constant)}; the choice
{opt bootdgp(johansen)} for the ALR (it is the choice of BCDT 2023 eq. 3.7 and of the authors'
Monte Carlo code); the asymptotic PLR p-value column.

{pstd}
{bf:Generalisation of the authors' code.} The Ox library files that accompany the paper
(lib_const.ox, lib_trend.ox) are hard-coded for p = 2 variables and test only r = 0, and the
bootstrap routines of TermStructure.ox are hard-coded for k = 2 lags. {cmd:cointvol adaptive}
implements the method for any p >= 2, any lag order k >= 1, every null rank r = 0,...,p-1 and
all four deterministic cases, using an independent implementation of the paper's equations.

{pstd}
{bf:Switching algorithm.} The algorithm maximises the likelihood without normalising beta;
beta is rescaled to beta'beta = I between iterations (the likelihood is invariant). The
number of iterations used on the data is stored in r(stats). Very slow convergence may occur
close to rank deficiency; increase {opt iterate()} if a note is printed.

{pstd}
{bf:Choosing the bootstrap.} In the paper's simulations the VBS controls size slightly better
than the WBS, and the ALR is much more powerful than the PLR whenever volatility varies (e.g.
a late upward shift). With constant volatility the ALR loses little. Size distortions of the
ALR grow with the roughness of the volatility path; use B >= 499.

{pstd}
{bf:Cost.} Each replication and null rank requires a Johansen fit and a GRRR fit. For p = 5,
n = 478, B = 999 and five ranks with both bootstraps expect a few minutes. The kernel smoother
uses an n x n weight matrix for n <= 2500 and a loop beyond.

{pstd}
{bf:Lag order.} BZ select k by BIC in the unrestricted VAR (Cavaliere et al. 2018); the
estimation error in k does not affect validity. See {helpb cointvol_select}.


{marker examples}{...}
{title:Examples}

{pstd}Simulated bivariate system with a late upward volatility shift{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 400}{p_end}
{phang2}{cmd:. set seed 101}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen s = cond(t > 320, 3, 0.5)}{p_end}
{phang2}{cmd:. gen x2 = sum(s*rnormal())}{p_end}
{phang2}{cmd:. gen x1 = x2 + s*rnormal()}{p_end}

{pstd}Statistics and asymptotic PLR p-values only{p_end}
{phang2}{cmd:. cointvol adaptive x1 x2, lags(2) reps(0)}{p_end}

{pstd}Both bootstraps (standard use){p_end}
{phang2}{cmd:. cointvol adaptive x1 x2, lags(2) reps(499) seed(1234) graph}{p_end}

{pstd}Volatility bootstrap only, fixed bandwidth, Johansen-based bootstrap DGP{p_end}
{phang2}{cmd:. cointvol adaptive x1 x2, lags(2) method(vbs) bw(0.05) bootdgp(johansen)}{break}
{cmd:reps(499)}{p_end}

{pstd}Replication of BZ (2022) Table 4 (US term structure; data file TermStructure.xlsx from the
authors' replication package){p_end}
{phang2}{cmd:. import excel using TermStructure.xlsx, firstrow clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. cointvol adaptive R3 R12 R36 R60 R120, lags(2) trend(rconstant)}{break}
{cmd:reps(999) seed(12345678)}{p_end}
{pstd}(paper: h = 0.0217; ALR-VBS p-values .000 .000 .000 .038 .172; ALR-WBS .000 .000 .001 .011
.124; bootstrap p-values agree up to simulation error.){p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol adaptive} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}effective number of observations n{p_end}
{synopt:{cmd:r(p)}}number of variables{p_end}
{synopt:{cmd:r(lags)}}lag order k{p_end}
{synopt:{cmd:r(level)}}level{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(h)}}bandwidth (fraction of n){p_end}
{synopt:{cmd:r(h_obs)}}bandwidth in observations, n h{p_end}
{synopt:{cmd:r(cvcrit)}}cross-validation criterion at h (mean over t){p_end}
{synopt:{cmd:r(rank_plr_asy)}}sequential rank, PLR asymptotic p-values{p_end}
{synopt:{cmd:r(rank_plr_vbs)}}sequential rank, PLR-VBS{p_end}
{synopt:{cmd:r(rank_plr_wbs)}}sequential rank, PLR-WBS{p_end}
{synopt:{cmd:r(rank_alr_vbs)}}sequential rank, ALR-VBS{p_end}
{synopt:{cmd:r(rank_alr_wbs)}}sequential rank, ALR-WBS{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol adaptive}{p_end}
{synopt:{cmd:r(varlist)}}variables{p_end}
{synopt:{cmd:r(trend)}}deterministic case{p_end}
{synopt:{cmd:r(method)}}bootstrap(s){p_end}
{synopt:{cmd:r(bootdgp)}}bootstrap DGP estimates{p_end}
{synopt:{cmd:r(kernel)}}{cmd:gauss}{p_end}
{synopt:{cmd:r(bw)}}{cmd:cv} or the supplied bandwidth{p_end}
{synopt:{cmd:r(seed)}}seed{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}one row per null rank: r, eigenvalue, trace, p_asy, p_plr_vbs,
p_plr_wbs, alr, p_alr_vbs, p_alr_wbs, iterations, redrawn, explosive{p_end}
{synopt:{cmd:r(select)}}sequential ranks (plr_asy plr_vbs plr_wbs alr_vbs alr_wbs){p_end}
{synopt:{cmd:r(eigenvalues)}}Johansen eigenvalues{p_end}
{synopt:{cmd:r(vol)}}n x p(p+1)/2 matrix of vech(Sigma_t), columns s{it:i}_{it:j}{p_end}


{marker references}{...}
{title:References}

{phang}
Boswijk, H. P., and Y. Zu. 2022. Adaptive testing for cointegration with nonstationary
volatility. {it:Journal of Business & Economic Statistics} 40(2): 744-755.
{browse "https://doi.org/10.1080/07350015.2020.1867558":doi:10.1080/07350015.2020.1867558}.
(Online appendix and Ox replication code by the authors.)

{phang}
Boswijk, H. P., G. Cavaliere, L. De Angelis, and A. M. R. Taylor. 2023. Adaptive
information-based methods for determining the co-integration rank in heteroskedastic VAR
models. {it:Econometric Reviews} 42(9-10): 725-757.
{browse "https://doi.org/10.1080/07474938.2023.2222633":doi:10.1080/07474938.2023.2222633}.

{phang}
Cavaliere, G., L. De Angelis, A. Rahbek, and A. M. R. Taylor. 2018. Determining the
cointegration rank in heteroskedastic VAR models of unknown order. {it:Econometric Theory}
34(2): 349-382.
{browse "https://doi.org/10.1017/S0266466616000335":doi:10.1017/S0266466616000335}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010. Testing for co-integration in vector
autoregressions with non-stationary volatility. {it:Journal of Econometrics} 158(1): 7-24.
{browse "https://doi.org/10.1016/j.jeconom.2010.03.003":doi:10.1016/j.jeconom.2010.03.003}.

{phang}
Hansen, P. R. 2003. Structural changes in the cointegrated vector autoregressive model.
{it:Journal of Econometrics} 114(2): 261-295.
{browse "https://doi.org/10.1016/S0304-4076(03)00085-X":doi:10.1016/S0304-4076(03)00085-X}.

{phang}
Johansen, S. 1991. Estimation and hypothesis testing of cointegration vectors in Gaussian vector
autoregressive models. {it:Econometrica} 59(6): 1551-1580.
{browse "https://doi.org/10.2307/2938278":doi:10.2307/2938278}.

{phang}
Patilea, V., and H. Raissi. 2012. Adaptive estimation of vector autoregressive models with
time-varying variance: application to testing linear causality in mean. {it:Journal of
Statistical Planning and Inference} 142(11): 2891-2912.
{browse "https://doi.org/10.1016/j.jspi.2012.04.005":doi:10.1016/j.jspi.2012.04.005}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See also: {helpb cointvol}, {helpb cointvol_rank:cointvol rank},
{helpb cointvol_select:cointvol select}.
{p_end}
