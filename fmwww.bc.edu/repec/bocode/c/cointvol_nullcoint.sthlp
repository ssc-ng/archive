{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "cointvol_nullcoint##syntax"}{...}
{viewerjumpto "Description" "cointvol_nullcoint##description"}{...}
{viewerjumpto "Options" "cointvol_nullcoint##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_nullcoint##methods"}{...}
{viewerjumpto "Remarks" "cointvol_nullcoint##remarks"}{...}
{viewerjumpto "Examples" "cointvol_nullcoint##examples"}{...}
{viewerjumpto "Stored results" "cointvol_nullcoint##results"}{...}
{viewerjumpto "References" "cointvol_nullcoint##references"}{...}
{viewerjumpto "Author" "cointvol_nullcoint##author"}{...}
{title:Title}

{phang}
{bf:cointvol nullcoint} {hline 2} Tests of the null of linear or nonlinear cointegration
robust to variance breaks and nonstationary volatility


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cointvol} {cmdab:null:coint} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(spec)}}{cmd:linear} (default), {cmd:poly(}{it:#}{cmd:)}, {cmd:quadratic},
{cmd:cubic}, {cmd:str} or {cmd:threshold(}{it:varname}{cmd:)}{p_end}
{synopt:{opt tr:end(det)}}deterministic polynomial: {cmd:none}, {cmd:constant} (default),
{cmd:trend}, or an integer degree {it:q} = 0,...,4{p_end}
{synopt:{opt trans:var(varname)}}transition variable of {cmd:model(str)}; default the first
regressor{p_end}
{synopt:{opt sl:ope(#)}}fix the logistic slope of {cmd:model(str)}; default: estimated{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}

{syntab:Estimation}
{synopt:{opt est:imator(est)}}{cmd:dnls} (default; alias {cmd:dols}) or {cmd:ols}
(aliases {cmd:nls}, {cmd:static}); {cmd:model(threshold())} forces {cmd:ols}{p_end}
{synopt:{opt lead:s(#)}}number {it:K} of leads of Dx; default {cmd:leads(1)}{p_end}
{synopt:{opt lag:s(#)}}number of lags of Dx; default equal to {opt leads()}{p_end}
{synopt:{opt lrv(type)}}{cmd:bartlett} (default), {cmd:qs} (quadratic spectral; default with
{cmd:method(cs)}) or {cmd:ols} (residual variance){p_end}
{synopt:{opt bw:idth(#)}}Bartlett truncation lag; default floor(4(T/100){c 94}(1/4)){p_end}

{syntab:Inference}
{synopt:{opt met:hod(type)}}{cmd:kpss} (default; full-residual statistic) or {cmd:cs}
(Choi-Saikkonen subresidual test with Bonferroni){p_end}
{synopt:{opt block(# [#])}}{cmd:method(cs)}: fixed block size b, or the range searched by
the minimum-volatility rule; default floor(T{c 94}0.7) to floor(T{c 94}0.9){p_end}
{synopt:{opt mv:width(#)}}{cmd:method(cs)}: half-width m of the minimum-volatility window;
default 2{p_end}
{synopt:{opt csl:ag(#)}}{cmd:method(cs)}: constant c of the block bandwidth
floor(c(b/100){c 94}(1/4)); default 4{p_end}
{synopt:{opt boot:strap(type)}}{cmd:frwild} (default), {cmd:sieve} or {cmd:none}{p_end}
{synopt:{opt r:eps(#)}}bootstrap replications; default {cmd:reps(500)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt mult:iplier(type)}}{cmd:gauss} (default), {cmd:rademacher} or {cmd:mammen}{p_end}
{synopt:{opt pval:ue(type)}}{cmd:weak} (default), {cmd:strict} or {cmd:plusone}{p_end}
{synopt:{opt cv(type)}}asymptotic reference: {cmd:shin} (Shin 1994 Table 1; default when
tabulated) or {cmd:sim} (simulated){p_end}
{synopt:{opt asyr:eps(#)}}draws for {cmd:cv(sim)}; default 5000; 0 = none{p_end}
{synopt:{opt sieve:max(#)}}maximum VAR order for {cmd:bootstrap(sieve)}; default
floor(4(T/100){c 94}(1/4)){p_end}
{synopt:{opt l:evel(#)}}significance level for the stars; default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt gr:aph}}plot the empirical variance profile of the residuals{p_end}
{synopt:{opt graphn:ame(name)}}name of the graph; default {cmd:cointvol_nullcoint}{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the bootstrap statistics{p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}
{synoptline}
{p 4 6 2}
The data must be {cmd:tsset} (not as a panel) and the sample must be free of gaps.
{it:depvar} and {it:indepvars} may contain time-series operators.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol nullcoint} tests the null hypothesis of cointegration, i.e. that the error of the
cointegrating regression

{p 8 8 2}
y{sub:t} = [1, t, ..., t{c 94}q]delta + g(x{sub:t}, theta) + u{sub:t}

{pstd}
is I(0), against the alternative that u{sub:t} contains a random-walk component (no
cointegration). The statistic is the KPSS/Shin (1994) statistic computed from the regression
residuals (Shin's C, C{sub:mu} and C{sub:tau} statistics). Shin's (1994) asymptotic critical
values (Table 1, embedded) are reported for the linear model. The null distribution of the
statistic is not pivotal when the innovations display breaks in
variance or other forms of nonstationary (unconditional) volatility (Cavaliere and Taylor
2006, Theorem 1), so inference is by the heteroskedastic fixed-regressor wild bootstrap of
Hansen (2000), shown to be valid by Cavaliere and Taylor (2006) for static linear regressions
with serially uncorrelated errors and by Hanck and Massing (2025) for nonlinear regressions,
serial correlation and endogeneity when the regression is estimated by dynamic (nonlinear)
least squares with leads and lags.

{pstd}
With {cmd:method(cs)} the command instead computes the subresidual-based KPSS tests of Choi and
Saikkonen (2010): the (dynamic) nonlinear regression is estimated on the full sample, KPSS
statistics are computed on M blocks of b consecutive residuals, and the largest one is compared
with the alpha/M critical value of int W{c 94}2 (Bonferroni). Their limit does not depend on
the (non-standard) distribution of the nonlinear estimator, so asymptotic inference is
available for any smooth g, at the price of power.

{pstd}
Use it when the question is "is this relation cointegrated?" and the natural null is
cointegration (e.g. confirming an equilibrium relation, an EKC, a money-demand function),
and when the residuals show variance shifts (check with {opt graph}). Do {it:not} use it to
test for the cointegrating rank of a system (see {helpb cointvol_rank:cointvol rank}); the
regressors must themselves be I(1) and not cointegrated among themselves.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(spec)} specifies g(x, theta).
{cmd:linear} (Original: Cavaliere and Taylor 2006, eq. 1): g = x'theta, any number of
regressors.
{cmd:poly(}{it:#}{cmd:)} (Original: Hanck and Massing 2025, Sect. 4.2): powers 1,...,# of each
regressor; {cmd:quadratic} = {cmd:poly(2)}, {cmd:cubic} = {cmd:poly(3)}; # <= 6.
With more than one regressor the powers of each regressor enter additively without cross
products (Extended implementation).
{cmd:str} (Original: Hanck and Massing 2025, Sect. 4.3 and 5.2): logistic smooth transition
g = x'theta{sub:1} + theta{sub:2}/(1 + exp(-theta{sub:4}(s - theta{sub:3}))), where s is
the transition variable (one of the regressors, see {opt transvar()}).
{cmd:threshold(}{it:q}{cmd:)} (Original: Hanck and Massing 2025, Sect. 4.4; Gonzalo and
Pitarakis 2006): g = x'theta{sub:1} + x'theta{sub:2} 1(q{sub:t-1} > theta{sub:3}); the
threshold variable enters with a one-period lag, so the first observation is lost.

{phang}
{opt trend(det)} sets the deterministic polynomial [1, t, ..., t{c 94}q]:
{cmd:none}, {cmd:constant} (q = 0; default), {cmd:trend} (q = 1) or an integer q between 0 and
4 (Original: C&T 2006 cases none/constant/trend; H&M 2025 eq. 1 for general q).

{phang}
{opt transvar(varname)} names the transition variable of {cmd:model(str)}; it must be one of
{it:indepvars}. Default: the first regressor.

{phang}
{opt slope(#)} fixes the logistic slope theta{sub:4} at # > 0. {cmd:slope(1)} reproduces the
Monte Carlo design of Hanck and Massing (2025, Sect. 4.3). By default theta{sub:4} is estimated,
as in their money-demand application.

{phang}
{opt trim(#)} is the fraction of the threshold-variable distribution trimmed from each tail of
the grid for theta{sub:3}; 0 < # < 0.5; default 0.15. At most 200 grid points are used
(Extended implementation: the paper does not state its grid).

{dlgtab:Estimation}

{phang}
{opt estimator(est)}: {cmd:ols}/{cmd:nls}/{cmd:static} estimates the static regression by OLS
(models linear in the parameters; Original: Shin 1994 eqs. 1-3 and Theorem 1, C&T 2006) or
NLS (Original: H&M 2025 eq. 10);
{cmd:dnls}/{cmd:dols} adds K leads and lags of Dx and uses the one-step dynamic NLS
estimator of Choi and Saikkonen (2010) (Original: H&M 2025 eqs. 18-21). For models linear in
the parameters DNLS is DOLS (OLS on the regressors and the leads/lags), as in H&M (2025,
footnote 8). For {cmd:model(linear)}, {cmd:estimator(dols)} is the leads-and-lags (dynamic
OLS) estimator of Saikkonen (1991) that Shin (1994, eqs. 10-12, Lemma 1, Theorem 2)
recommends when the regressors are endogenous (Original: Shin 1994). The default is
{cmd:dnls}, except for {cmd:model(threshold())}, which only supports {cmd:ols}.

{phang}
{opt leads(#)} is the number K >= 0 of leads of Dx; default 1 (as reported in H&M 2025,
Sect. 4). Only used with {cmd:estimator(dnls)}. Shin (1994, Sect. 3) uses the same truncation
K for leads and lags, requires K -> infinity with K{c 94}3/T -> 0, and uses K = 5
(approximately T{c 94}(1/3), T = 178) in his application (Sect. 5).

{phang}
{opt lags(#)} is the number of lags of Dx; default equal to {opt leads()} (Original: Shin
1994; H&M 2025). If only {opt lags()} is given, the number of leads is set equal to it.
{opt leads()} different from {opt lags()} is an Extended implementation.

{phang}
{opt lrv(type)}: {cmd:bartlett} uses a Bartlett-kernel long-run variance of the residuals
(Original: H&M 2025, Sect. 4.1; Shin 1994, Sect. 5); {cmd:qs} uses the quadratic spectral
kernel of Andrews (1991) with bandwidth l and all lags (Original with {cmd:method(cs)}: Choi
and Saikkonen 2010, Sect. 5; Extended implementation with {cmd:method(kpss)}); {cmd:ols} uses the residual variance T{c 94}-1 sum u{c 94}2
(Original: C&T 2006 eq. 6; H&M 2025 footnote 5), appropriate only without serial correlation.
The bootstrap always uses the same estimator and bandwidth as the observed statistic.

{phang}
{opt bwidth(#)} is the Bartlett truncation lag l >= 0; default
floor(4(T/100){c 94}(1/4)) (Kwiatkowski et al. 1992; H&M 2025).

{dlgtab:Inference}

{phang}
{opt method(type)}: {cmd:kpss} (default) computes the full-residual statistic (Shin 1994;
C&T 2006; H&M 2025; C&S 2010 eqs. 9-10) with bootstrap and/or asymptotic inference.
{cmd:cs} computes the subresidual test of Choi and Saikkonen (2010) (Original: C&S 2010,
eqs. 11-13, Theorem 1, Sect. 4.2): C{sub:NLLS}{c 94}(b,max) with {cmd:estimator(nls)} and
C{sub:LL}{c 94}(b,max) with {cmd:estimator(dnls)} (default). {cmd:method(cs)} is not available
for {cmd:model(threshold())} (g must be smooth, C&S Assumption 4) and uses no bootstrap.

{phang}
{opt block(# [#])} ({cmd:method(cs)} only). One number fixes the block size b (10 <= b <= number
of residuals). Two numbers give the range [b{sub:small}, b{sub:big}] searched by the
minimum-volatility rule (Original: C&S 2010, Sect. 4.2.2); default
[floor(T{c 94}0.7), floor(T{c 94}0.9)] as in C&S (Sect. 4.2.2; 33 and 90 for T = 150). The range is
shrunk if needed so that b{sub:big} + m does not exceed the number of residuals and
b{sub:small} - m >= 10.

{phang}
{opt mvwidth(#)} ({cmd:method(cs)} only) is the half-width m >= 1 of the minimum-volatility
window; default 2 (C&S 2010, Sect. 4.2.2, following Romano and Wolf 2001).

{phang}
{opt cslag(#)} ({cmd:method(cs)} only) sets c in the block bandwidth l{sub:b} =
floor(c(b/100){c 94}(1/4)); default 4; C&S (2010, Sect. 5) also report c = 12.

{phang}
{opt bootstrap(type)}: {cmd:frwild} is the fixed-regressor wild bootstrap (Original: C&T 2006
Sect. 4; H&M 2025 Sect. 3.4); {cmd:sieve} is the sieve wild bootstrap (H&M 2025 Sect. 4.6,
exploratory: no asymptotic theory); {cmd:none} reports the statistic (and the simulated
asymptotic inference for the linear model) only.

{phang}
{opt reps(#)} is the number of bootstrap replications B; default 500 (C&T 2006; H&M 2025 MC).
The applications of H&M (2025) use 2000. Minimum 19.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility.

{phang}
{opt multiplier(type)}: distribution of the wild-bootstrap multipliers z{sub:t}. {cmd:gauss}
N(0,1) is the Original (both papers); {cmd:rademacher} and {cmd:mammen} are Extended
implementations.

{phang}
{opt pvalue(type)}: {cmd:weak} p = B{c 94}-1 sum 1(eta*{sub:b} >= eta)
(Original: C&T 2006, Sect. 4); {cmd:strict} p = 1 - G*(eta) = B{c 94}-1 sum 1(eta*{sub:b}
> eta) (Original: H&M 2025, Sect. 3.4); {cmd:plusone} p = (#{c -(}eta*>=eta{c )-}+1)/(B+1)
(Extended). With a continuous statistic the three differ by O(1/B) at most.

{phang}
{opt cv(type)} selects the asymptotic (homoskedastic) reference distribution reported for
{cmd:model(linear)}. {cmd:cv(shin)} uses the critical values of Shin (1994, Table 1), embedded
exactly, with an interpolated p-value (Original: Shin 1994); it is the default whenever the
case is tabulated, i.e. 1 <= m <= 5 regressors and {cmd:trend(none)}, {cmd:trend(constant)} or
{cmd:trend(trend)}. {cmd:cv(sim)} simulates the same limit (Extended implementation); it is
the default for untabulated cases (m > 5 or a polynomial trend of degree 2-4).
{cmd:cv(shin)} for an untabulated case is an error. Asymptotic values are not computed for
nonlinear models.

{phang}
{opt asyreps(#)} is the number of Monte Carlo draws used by {cmd:cv(sim)} to simulate the
homoskedastic asymptotic null distribution (default 5000; 0 suppresses it). Ignored with
{cmd:cv(shin)}. See Methods.

{phang}
{opt sievemax(#)} is the largest VAR order considered by AIC in {cmd:bootstrap(sieve)}.

{phang}
{opt level(#)} sets the level at which rejections are starred.

{dlgtab:Reporting}

{phang}
{opt graph} draws the empirical variance profile of the (D)NLS residuals, H&M (2025) eq. (28),
against the 45-degree line that corresponds to homoskedasticity. {opt graphname()} names it.

{phang}
{opt saving(filename[, replace])} saves the B bootstrap statistics (variables {cmd:rep},
{cmd:eta_boot}).

{phang}
{opt nodots} suppresses the progress dots.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model and hypotheses.} (C&T 2006 eqs. 1-4; H&M 2025 eqs. 1-3.)
y{sub:t} = h(t, x{sub:t}, vartheta) + u{sub:t}, h = [1,t,...,t{c 94}q]delta + g(x{sub:t},theta),
u{sub:t} = v{sub:t} + mu{sub:t}, mu{sub:t} = mu{sub:t-1} + rho{sub:mu}zeta{sub:mu,t},
x{sub:t} = x{sub:t-1} + zeta{sub:x,t}. The innovations are zeta{sub:t} =
Sigma{sub:t}{c 94}(1/2)zeta*{sub:t} with a deterministic, possibly discontinuous variance
path Sigma{sub:[Ts]} = Sigma(s) (breaks, trends, smooth transitions).
H0: rho{sub:mu}{c 94}2 = 0 (cointegration); H1: rho{sub:mu}{c 94}2 > 0.

{pstd}
{bf:Statistic.} (Shin 1994 eqs. 6 and 13.) With residuals e{sub:t} over N observations and
partial sums S{sub:t} = sum{sub:j<=t} e{sub:j},

{p 8 8 2}
eta = (N{c 94}2 omega{c 94}2){c 94}-1 sum{sub:t} S{sub:t}{c 94}2

{pstd}
(C&T 2006 eq. 6 with N = T and omega{c 94}2 = T{c 94}-1 sum e{c 94}2; H&M 2025 eq. 12 for NLS
and eq. 22 for DNLS, with N = T - 2K - 1 and t = K+2,...,T-K). The Bartlett estimator is
omega{c 94}2 = N{c 94}-1 sum e{c 94}2 + 2 sum{sub:s=1..l}(1 - s/(l+1))N{c 94}-1 sum{sub:t>s}e{sub:t}e{sub:t-s}
(Shin 1994, Appendix: s{c 94}2(l) with the Bartlett window w(s,l) = 1 - s/(l+1); Kwiatkowski
et al. 1992). Large values reject. For {cmd:trend(none)}, {cmd:trend(constant)} and
{cmd:trend(trend)} with the linear model, eta is Shin's C, C{sub:mu} and C{sub:tau}
(regressions 1, 2, 3 estimated by OLS, or 10, 11, 12 estimated by DOLS); with
{cmd:lrv(ols)} it is the LM form of Shin's footnote 2, used by C&T (2006).

{pstd}
{bf:Estimators.}
(i) OLS/NLS of y on h (C&T 2006; H&M 2025 eq. 10). NLS for {cmd:model(str)} is computed by
Levenberg-Marquardt, started from the best point of a grid (location at the 10%,...,90%
quantiles of s; slope in {c -(}0.5,1,2,4,8,16{c )-}/sd(s)) with the linear parameters
concentrated out by OLS. {cmd:model(threshold())}: theta{sub:3} minimises the SSR over the
trimmed grid of observed values of q{sub:t-1}; the other parameters are OLS (H&M 2025, Sect. 4.4).
(ii) One-step DNLS (Choi and Saikkonen 2010, eqs. 7-8 and the two-step estimator below eq. 8;
H&M 2025 eqs. 18-21): with
V{sub:t} = (Dx'{sub:t-K},...,Dx'{sub:t+K})' and p{sub:t} =
(dh(t,x{sub:t},vartheta{sub:NLS})/dvartheta', V'{sub:t})',
(vartheta{sup:(1)}; pi{sup:(1)}) = (vartheta{sub:NLS}; 0) + (sum p{sub:t}p'{sub:t}){c 94}-1 sum p{sub:t}u{sub:t},
sums over t = K+2,...,T-K; residuals e{sub:t} = y{sub:t} - h(t,x{sub:t},vartheta{sup:(1)}) -
V'{sub:t}pi{sup:(1)}. For models linear in vartheta this equals OLS of y on (h-regressors,
V{sub:t}) (DOLS), which is what is computed. The index range t = K+2,...,T-K for both
sums, the regressor vector p{sub:t} = (dg/dtheta' at the NLS estimate, V'{sub:t})' and
N = T-2K-1 are exactly those of C&S (2010, eq. 8 and Theorem A.2); deterministic terms are
part of theta. The rate conditions are K -> infinity, K{c 94}3/T -> 0 and
T{c 94}(1/2) sum{sub:|j|>K}|pi{sub:j}| -> 0 (C&S Theorem A.2). This is exactly Shin's (1994) modified
regression y{sub:t} = [deterministics] + x'{sub:t}theta + sum{sub:j=-K..K} Dx'{sub:t-j}pi{sub:j}
+ e{sub:t} (eqs. 10-12), whose residuals give C, C{sub:mu}, C{sub:tau} with the same
nuisance-parameter-free limit as in the strictly exogenous case (Lemma 1, Theorem 2). With
{opt leads()} = a and {opt lags()} = b the regression runs over t = b+2,...,T-a
(N = T-a-b-1).

{pstd}
{bf:Fixed-regressor wild bootstrap} (Hansen 2000; C&T 2006 Sect. 4; H&M 2025 Sect. 3.4):

{p 8 12 2}
1. Estimate the model, save the residuals e{sub:t} and eta.{p_end}
{p 8 12 2}
2. Draw z{sub:t} i.i.d. N(0,1) and set y*{sub:t} = e{sub:t}z{sub:t} (linear-in-parameter
models) or y*{sub:t} = h(t,x{sub:t},vartheta-hat) + e{sub:t}z{sub:t} (STR, threshold; see Remarks),
t over the residual sample.{p_end}
{p 8 12 2}
3. Re-estimate by the {it:same} estimator on the {it:same, fixed} regressors (and the same
leads/lags of Dx; the threshold grid search is repeated), obtain e*{sub:t} and
eta* with the same long-run-variance estimator and bandwidth.{p_end}
{p 8 12 2}
4. Repeat B times; p = B{c 94}-1 sum 1(eta*{sub:b} >= eta) (see {opt pvalue()}).
Bootstrap critical values are the 90/95/99% empirical quantiles of eta*.{p_end}

{pstd}
Under H0 the bootstrap reproduces the non-pivotal, variance-profile dependent limit
(C&T 2006 Theorem 3; H&M 2025 Theorem 3 and Corollary 1); under H1 eta = O{sub:p}(T/l)
while eta* = O{sub:p}(1), so the test is consistent.

{pstd}
{bf:Sieve wild bootstrap} (H&M 2025 Sect. 4.6, exploratory): fit a VAR(p) with intercept to
w{sub:t} = (e{sub:t}, Dx'{sub:t})', p <= {opt sievemax()} by AIC; centre the
residuals and multiply by z{sub:t}; generate w*{sub:t} recursively from the first p observed
values; x*{sub:t} = x*{sub:t-1} + Dx*{sub:t}; y*{sub:t} = h(t,x*{sub:t},vartheta-hat) +
e*{sub:t}; recompute eta on (y*, x*) with the same estimator. No asymptotic theory is
available for this scheme.

{pstd}
{bf:Asymptotic inference (model(linear) only).} Under homoskedasticity and H0 the limit of
eta is Shin's (1994, Theorems 1-2) functional
int Q{c 94}2 with Q = V - (int W{sub:2})'(int W{sub:2}W'{sub:2}){c 94}-1(int W{sub:2}dW{sub:1}),
built from a (first- or second-level) Brownian bridge V of the regression error and the
(demeaned / detrended) m-vector Brownian motion W{sub:2} of the regressors (C&T 2006 eq. 8).
It depends only on m and on the deterministic case.

{p 8 12 2}
{cmd:cv(shin)}: Shin (1994, Table 1) tabulates this distribution for m = 1,...,5 and the
standard (C), demeaned (C{sub:mu}) and detrended (C{sub:tau}) cases at the fractiles 0.010,
0.025, 0.050, 0.100, 0.200, ..., 0.900, 0.950, 0.975, 0.990 (Monte Carlo, T = 2000; 50,000
replications for m <= 3, 20,000 for m = 4, 5). The full table is embedded exactly. The
10/5/2.5/1% critical values are the 0.900/0.950/0.975/0.990 fractiles. The asymptotic p-value
is p = 1 - F(eta), with F linear in eta between the 0.900, 0.950, 0.975 and 0.990 fractiles;
outside that range it is reported as a bound, ">0.100" (eta below the 10% value;
r(p_asy) = 0.10 and r(p_asy_bound) = 1) or "<0.010" (eta above the 1% value; r(p_asy) = 0.01
and r(p_asy_bound) = -1). The star uses the Table 1 value at fractile {opt level()}/100,
interpolated linearly between the tabulated fractiles (identical to comparing the
interpolated p-value with 1 - {opt level()}/100 inside the 90-99% range).{p_end}
{p 8 12 2}
{cmd:cv(sim)}: the functional is simulated ({opt asyreps()} draws of T = 500 observations:
i.i.d. N(0,1) errors, m independent Gaussian random walks, the same deterministic polynomial,
OLS residuals, residual-variance normalisation) and the simulated 10/5/2.5/1% critical values
and p-value are reported. A fixed internal seed is used so that these values are
reproducible and do not alter the user's random-number stream. For m = 1 the simulated 5%
values are about 0.313 (constant) and 1.22 (none), against Shin's 0.314 and 1.199.{p_end}

{pstd}
Both are {it:not} valid under variance breaks (C&T 2006 Theorem 1 and Table I; H&M 2025
Table 2) and are shown for comparison with the bootstrap.

{pstd}
{bf:Choi and Saikkonen (2010) subresidual test ({cmd:method(cs)}).} The full-residual
statistics C{sub:NLLS} (eq. 9, NLS residuals) and C{sub:LL} (eq. 10, leads-and-lags
residuals) have limits that depend on the limit of the nonlinear estimator (C&S Lemma A.3),
except in the linear and polynomial cases for C{sub:LL} (Shin's Theorem 2). C&S therefore use
blocks of the full-sample residuals:

{p 8 8 2}
C{c 94}(b,i) = b{c 94}-2 omega{sub:i}{c 94}-2 sum{sub:t=i..i+b-1}(sum{sub:j=i..t} r{sub:j}){c 94}2
(eqs. 11-12),

{pstd}
where r are the NLS residuals (C{sub:NLLS}) or the leads-and-lags residuals (C{sub:LL}),
the partial sums restart at the start of the block, and omega{sub:i}{c 94}2 is the long-run
variance of the block residuals (QS kernel, bandwidth floor(c(b/100){c 94}(1/4)), C&S Sect. 5).
If b -> infinity and b/T -> 0, C{c 94}(b,i) => int W{c 94}2 for every block (Theorem 1), whose
cdf is (eq. 13, Appendix B)

{p 8 8 2}
F(z) = sqrt(2) sum{sub:n>=0} [Gamma(n+1/2)/(n! Gamma(1/2))] (-1){c 94}n
[1 - Erf(u{sub:n}/(2 sqrt(z)))], u{sub:n} = sqrt(2)/2 + 2n sqrt(2)

{pstd}
(101 terms are used; C&S use 11, which gives the same values to 1e-9 for z <= 10; the 90/95/99%
points are 1.196, 1.656 and 2.787). The blocks start at i{sub:1} = 1, i{sub:2} = n-b+1,
i{sub:3} = b+1, i{sub:4} = n-2b+1, ..., M = ceil(n/b) of them (Sect. 4.2.1), so that the whole
residual sample is covered, where n = T for NLS residuals and n = T-2K-1 (the effective sample)
for leads-and-lags residuals. The test statistic is C{c 94}(b,max) = max{sub:k} C{c 94}(b,i{sub:k});
H0 is rejected at level alpha when C{c 94}(b,max) >= c{sub:alpha/M}, the upper alpha/M point of
int W{c 94}2 (Bonferroni). The reported p-value is p = 1 - F(C{c 94}(b,max)) (as in C&S Table 5),
to be compared with alpha/M; the Bonferroni p-value min(1, Mp) is compared with alpha. The
block size b minimises over b{sub:i} in [b{sub:small}, b{sub:big}] the standard deviation of
C{c 94}(b{sub:i}-m,max), ..., C{c 94}(b{sub:i}+m,max) (minimum-volatility rule, Sect. 4.2.2).

{pstd}
{bf:Empirical variance profile} (H&M 2025 eq. 28): rho-hat(s) =
[sum{sub:t<=[Ns]}e{sub:t}{c 94}2 + (sN - [Ns])e{sub:[Ns]+1}{c 94}2] / sum e{sub:t}{c 94}2,
plotted at s = 0, 1/N, ..., 1 (linear interpolation between these points is exactly (28)).
Under homoskedasticity rho-hat(s) ~ s.

{pstd}
{bf:Step -> equation map.}
statistic: Shin (1994) eqs. (6), (13), C&T eq. (6), H&M eqs. (12), (22);
long-run variance: Shin (1994) Appendix (s{c 94}2(l), Bartlett window);
DOLS (linear model): Shin (1994) eqs. (10)-(12), Lemma 1, Theorem 2; Saikkonen (1991);
Table 1 critical values and p-value: Shin (1994) Table 1;
NLS: H&M eq. (10); DNLS: H&M eqs. (18)-(21);
bootstrap: C&T Sect. 4 (steps 1-4), H&M Sect. 3.4, Thm 3, Cor. 1;
LRV bandwidth: H&M Sect. 4.1 (KPSS 1992);
variance profile: H&M eq. (28);
simulated asymptotic limit: C&T eq. (8), Shin (1994) Theorem 1;
C&S (2010): NLLS and two-step leads-and-lags estimator eqs. (7)-(8), Theorem A.2;
full-residual statistics eqs. (9)-(10), Lemma A.3; subresidual statistics eqs. (11)-(12),
Theorem 1; Bonferroni and block choice Sect. 4.2, 4.2.1; block size Sect. 4.2.2;
cdf of int W{c 94}2 eq. (13), Appendix B; QS kernel and bandwidth Sect. 5.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which options reproduce the papers.}
Shin (1994): {cmd:model(linear) estimator(dols) leads(}{it:K}{cmd:) lrv(bartlett)
bwidth(}{it:l}{cmd:) cv(shin)} with {cmd:trend(none|constant|trend)}; his application uses
K = 5 and l = 10 (Sect. 5, Table 3) and reads the result against Table 1 (add
{cmd:bootstrap(none)} to suppress the bootstrap). Under strictly exogenous regressors
(Theorem 1) {cmd:estimator(ols)} may be used instead.
Choi and Saikkonen (2010): {cmd:method(cs)} with {cmd:estimator(dnls) leads(}{it:K}{cmd:)}
(C{sub:LL}{c 94}(b,max), K = 1, 2, 3) or {cmd:estimator(nls)} (C{sub:NLLS}{c 94}(b,max)),
{cmd:lrv(qs)} (default) and {cmd:cslag(4)} or {cmd:cslag(12)}.
Cavaliere and Taylor (2006): {cmd:model(linear) estimator(ols) lrv(ols) bootstrap(frwild)
reps(500)}, with {cmd:trend(none|constant|trend)}.
Hanck and Massing (2025), linear/polynomial Monte Carlo: {cmd:trend(none) estimator(dnls)
leads(1)} with {cmd:lrv(ols)} when rho = 0 and {cmd:lrv(bartlett)} otherwise; NLS-residual
variant: {cmd:estimator(nls)}. Smooth transition MC: {cmd:model(str) slope(1) reps(200)}.
Threshold MC: {cmd:model(threshold(q)) trend(none)}. EKC application:
{cmd:model(cubic) trend(trend) reps(2000)}.

{pstd}
{bf:Implementation choices and corrections} (documented deviations from the printed papers):

{p 8 12 2}
(a) H&M (2025) define the DNLS sums with lower index K+2 for sum pp' but K+1 for
sum pu; both are taken over t = K+2,...,T-K (the only range where V{sub:t} exists).{p_end}
{p 8 12 2}
(b) H&M state the rate condition "K{c 94}3/T -> infinity"; the correct condition (Saikkonen
1991; Choi and Saikkonen 2010, Theorem A.2) is K{c 94}3/T -> 0. This does not affect the
computation.{p_end}
{p 8 12 2}
(c) For models nonlinear in the parameters ({cmd:str}, {cmd:threshold()}) the bootstrap
sample is y* = h(vartheta-hat) + e z rather than y* = e z. Residuals are invariant to this choice
for linear-in-parameter models (H&M Remark 4), but with y* = e z the location/threshold
parameter is not identified (the transition coefficient is near zero), and the linearisation
in the proof is at the true parameter. Bootstrap NLS starts at vartheta-hat; samples in which NLS
fails to converge are redrawn (H&M drop them) and counted in r(fails).{p_end}
{p 8 12 2}
(d) In the DNLS bootstrap the static NLS stage is run on t = K+2,...,T-K, the range on which
y* exists; in the data it is run on t = 1,...,T (H&M eq. 10).{p_end}
{p 8 12 2}
(e) In the money-demand model of H&M (2025, Sect. 5.2) the symbol theta{sub:3} is used both for
the transition coefficient and the location; here they are separate parameters
({cmd:str_coef}, {cmd:str_loc}, {cmd:str_slope}) and the transition variable is chosen with
{opt transvar()}.{p_end}
{p 8 12 2}
(f) Shin's (1994) Table 1 is embedded exactly as printed. The entry 0.046 at fractile 0.500 of
C{sub:mu} for m = 5 is out of order (0.031 at 0.400, 0.041 at 0.600) and is presumably a
misprint (0.036 would restore monotonicity); it is kept as printed. It never enters the
p-value, which only uses the 0.900-0.990 fractiles, and affects the star only for
{opt level()} between 40 and 60.{p_end}
{p 8 12 2}
(g) Shin (1994) runs the DOLS regression over t = K+1,...,T-K (Dx{sub:1} available); here
Dx{sub:1} is not observed, so it runs over t = K+2,...,T-K (N = T-2K-1), as in H&M (2025).
Shin also normalises by T{c 94}2 with T the number of residuals ("T instead of T-2K without
loss of generality", Appendix); N is used here. Both choices are asymptotically
irrelevant.{p_end}
{p 8 12 2}
(h) Shin (1994, Sect. 5) stresses that the test is sensitive to the bandwidth l: he uses the
Bartlett window with l = 10 for T = 178 and warns that the Andrews (1991) plug-in bandwidth
is very large under strong autocorrelation (so the null is rarely rejected) and that a
prewhitened kernel with plug-in bandwidth makes the test inconsistent. The default
bandwidth here is floor(4(T/100){c 94}(1/4)) (KPSS l4, as in H&M 2025); set {opt bwidth()}
to reproduce other choices.{p_end}

{p 8 12 2}
(i) C&S (2010) define the leads-and-lags subresiduals as {c -(}e{sub:Kt}{c )-} over t = i,...,i+b-1
(b residuals, the same block definition as for the NLS residuals, and the effective sample
T-2K-1 in the block selection), but eq. (12) prints the sums over t = i+K+2,...,i+b-K with the
factor (b-2K-1){c 94}-2. The two are asymptotically equivalent (K/b -> 0); the command uses
b consecutive leads-and-lags residuals of the effective sample with the factor b{c 94}-2, which
makes C{c 94}(b,i) for {cmd:estimator(dnls)} and {cmd:estimator(nls)} identical in form and
reproduces the reported M in C&S Table 5.{p_end}
{p 8 12 2}
(j) The block long-run variance is computed from the block residuals without re-centring, like
the full-sample estimator (the residuals have mean zero only over the full sample; the effect
is asymptotically negligible under H0). C&S do not state their minimum block size; the
command requires b >= 10. Ties in the minimum-volatility criterion are resolved by the smallest
b.{p_end}
{p 8 12 2}
(k) The subresidual tests are conservative because of the Bonferroni inequality (C&S Tables
1-3: sizes well below nominal for moderate serial correlation, but oversized when the AR
coefficient of the error is 0.95 with l = floor(4(b/100){c 94}(1/4)), which cslag(12) corrects),
and they are less powerful than the full-residual tests (C&S Tables 3-4). Their critical values
assume a constant variance and are not robust to variance breaks; with heteroskedastic
innovations prefer {cmd:method(kpss)} with the bootstrap.{p_end}

{pstd}
{bf:Shin's critical values and variance breaks.} Shin's (1994) Table 1 values (and the
{cmd:cv(sim)} values) are derived under a constant (homoskedastic) long-run variance.
Cavaliere and Taylor (2006, Theorem 1 and Table I) show that the limiting null distribution
of the statistic depends on the variance profile when the innovations have breaks in
variance or other nonstationary volatility, so tests based on these critical values are
invalid: an early downward variance shift makes them oversized (C&T 2006 Table I: about
11-16% rejections at nominal 5% for a break at 10% of the sample with delta = 4, T = 100),
while upward shifts can make them undersized (H&M 2025 Table 2, DNLS version: 1.7% for
sigma{sub:1}{c 94}2 = 16 at mid-sample). In that situation base inference on the
fixed-regressor wild bootstrap ({cmd:bootstrap(frwild)}, the default), which remains valid;
check the variance profile with {opt graph}.

{pstd}
{bf:Warnings.} The theory requires the regressors to be I(1) and not cointegrated among
themselves, the transition variable of the STR model to be I(1) (H&M footnote 9), and a
correctly specified g: a misspecified g (e.g. a quadratic fitted to a cubic relation) leads to
rejections of the null (H&M online appendix B). The threshold model is supported with NLS
residuals only, as in H&M (2025). With strong serial correlation the DNLS bootstrap is
oversized in small samples (H&M Table 1(b): 11-20% at T = 100 when the AR coefficient is
0.8), converging to the nominal level as T grows (Table 3). NLS for smooth-transition models is
computationally demanding: bootstrap times scale with B.


{marker examples}{...}
{title:Examples}

{pstd}Simulated cointegrated data with a variance break in the error at 30% of the sample{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 150}{p_end}
{phang2}{cmd:. set seed 2006}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen x = sum(rnormal())}{p_end}
{phang2}{cmd:. gen u = rnormal()*cond(t > 45, 0.25, 1)}{p_end}
{phang2}{cmd:. gen y = 1 + x + u}{p_end}

{pstd}Cavaliere and Taylor (2006) test (static OLS, residual variance, B = 500){p_end}
{phang2}{cmd:. cointvol nullcoint y x, estimator(ols) lrv(ols) seed(1)}{p_end}

{pstd}Shin (1994) test: DOLS with K = 5 leads and lags, Bartlett l = 10, Table 1 critical
values (demeaned case, C{sub:mu}) and interpolated asymptotic p-value only{p_end}
{phang2}{cmd:. cointvol nullcoint y x, estimator(dols) leads(5) bwidth(10) cv(shin) bootstrap(none)}{p_end}

{pstd}The same with the detrended statistic C{sub:tau}, now also with the bootstrap, which is
valid under the variance break; the full Table 1 panel is returned in r(shin_table){p_end}
{phang2}{cmd:. cointvol nullcoint y x, trend(trend) leads(5) bwidth(10) seed(1)}{p_end}
{phang2}{cmd:. matrix list r(shin_table)}{p_end}

{pstd}Simulated instead of tabulated asymptotic critical values{p_end}
{phang2}{cmd:. cointvol nullcoint y x, cv(sim) asyreps(20000) bootstrap(none)}{p_end}

{pstd}Hanck and Massing (2025) DOLS version with Bartlett long-run variance, and the
variance-profile graph{p_end}
{phang2}{cmd:. cointvol nullcoint y x, leads(2) seed(1) graph}{p_end}

{pstd}Polynomial (cubic) cointegration with a linear trend, as in the EKC application{p_end}
{phang2}{cmd:. gen y3 = 1 + x + 0.2*x{c 94}2 + 0.01*x{c 94}3 + u}{p_end}
{phang2}{cmd:. cointvol nullcoint y3 x, model(cubic) trend(trend) reps(999) seed(1)}{p_end}

{pstd}Smooth transition and threshold cointegration{p_end}
{phang2}{cmd:. summarize x, meanonly}{p_end}
{phang2}{cmd:. gen ys = x + 3/(1 + exp(-(x - r(mean)))) + u}{p_end}
{phang2}{cmd:. cointvol nullcoint ys x, model(str) slope(1) reps(199) seed(1)}{p_end}
{phang2}{cmd:. gen q = rnormal()}{p_end}
{phang2}{cmd:. replace q = 0.5*L.q + rnormal() if t > 1}{p_end}
{phang2}{cmd:. gen yt = x + 0.15*x*(L.q > 0) + u}{p_end}
{phang2}{cmd:. cointvol nullcoint yt x, model(threshold(q)) trend(none) reps(199) seed(1)}{p_end}

{pstd}Choi and Saikkonen (2010) subresidual test with leads-and-lags residuals (K = 2) and the
minimum-volatility block size, and the NLS-residual version with a fixed block{p_end}
{phang2}{cmd:. cointvol nullcoint y3 x, model(cubic) method(cs) leads(2)}{p_end}
{phang2}{cmd:. cointvol nullcoint ys x, model(str) slope(1) method(cs) estimator(nls) block(50)}{p_end}
{phang2}{cmd:. matrix list r(cs_blocks)}{p_end}

{pstd}Exploratory sieve bootstrap and saved bootstrap distribution{p_end}
{phang2}{cmd:. cointvol nullcoint y x, bootstrap(sieve) reps(199) seed(1) saving(boot, replace)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cointvol nullcoint} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(eta)}}KPSS/Shin statistic{p_end}
{synopt:{cmd:r(p_boot)}}bootstrap p-value{p_end}
{synopt:{cmd:r(p_asy)}}asymptotic p-value (Shin Table 1 interpolation or simulation; linear
model only, missing otherwise); with {cmd:cv(shin)} a bound (0.10 or 0.01) outside the
tabulated range{p_end}
{synopt:{cmd:r(p_asy_bound)}}{cmd:cv(shin)}: 0 interpolated, 1 true p > 0.10, -1 true p < 0.01;
missing otherwise{p_end}
{synopt:{cmd:r(cv_boot_10)}, {cmd:r(cv_boot_5)}, {cmd:r(cv_boot_2p5)}, {cmd:r(cv_boot_1)}}bootstrap
critical values{p_end}
{synopt:{cmd:r(cv_asy_10)}, {cmd:r(cv_asy_5)}, {cmd:r(cv_asy_2p5)}, {cmd:r(cv_asy_1)}}asymptotic
critical values (Shin Table 1 or simulated){p_end}
{synopt:{cmd:r(omega2)}}(long-run) variance estimate used in the statistic{p_end}
{synopt:{cmd:r(ssr)}}sum of squared residuals{p_end}
{synopt:{cmd:r(N)}}number of residuals N{p_end}
{synopt:{cmd:r(T)}}sample size T{p_end}
{synopt:{cmd:r(m)}}number of regressors{p_end}
{synopt:{cmd:r(K)}}number of leads (0 for static estimators){p_end}
{synopt:{cmd:r(lags)}}number of lags (0 for static estimators){p_end}
{synopt:{cmd:r(bwidth)}}Bartlett bandwidth{p_end}
{synopt:{cmd:r(level)}}significance level{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(fails)}}redrawn (failed) bootstrap samples{p_end}
{synopt:{cmd:r(sieve_p)}}VAR order of the sieve bootstrap{p_end}
{synopt:{cmd:r(asyreps)}}draws of the asymptotic simulation (set when asymptotic values are
reported){p_end}
{synopt:{cmd:r(degree)}}polynomial degree ({cmd:poly()}){p_end}
{synopt:{cmd:r(slope)}}fixed logistic slope ({cmd:slope()}){p_end}
{synopt:{cmd:r(threshold)}}estimated threshold; {cmd:r(trim)} trimming{p_end}
{synopt:{cmd:r(cs_stat)}}{cmd:method(cs)}: C{c 94}(b,max){p_end}
{synopt:{cmd:r(cs_p)}}p = 1 - F(C{c 94}(b,max)), compare with alpha/M{p_end}
{synopt:{cmd:r(cs_pbonf)}}Bonferroni p-value min(1, M p){p_end}
{synopt:{cmd:r(cs_b)}, {cmd:r(cs_M)}}block size and number of blocks{p_end}
{synopt:{cmd:r(cs_bw)}}block bandwidth floor(c(b/100){c 94}(1/4)); {cmd:r(cslag)} c{p_end}
{synopt:{cmd:r(cs_cv10)}, {cmd:r(cs_cv5)}, {cmd:r(cs_cv2p5)}, {cmd:r(cs_cv1)}}Bonferroni critical
values c{sub:alpha/M}{p_end}
{synopt:{cmd:r(cs_bmin)}, {cmd:r(cs_bmax)}, {cmd:r(mvwidth)}}minimum-volatility search range and
m{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol nullcoint}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables{p_end}
{synopt:{cmd:r(model)}}description of g{p_end}
{synopt:{cmd:r(trend)}}deterministic case{p_end}
{synopt:{cmd:r(estimator)}}{cmd:static} or {cmd:dnls}{p_end}
{synopt:{cmd:r(lrv)}}{cmd:bartlett}, {cmd:qs} or {cmd:ols}{p_end}
{synopt:{cmd:r(bootstrap)}}{cmd:frwild}, {cmd:sieve} or {cmd:none}{p_end}
{synopt:{cmd:r(multiplier)}}multiplier distribution{p_end}
{synopt:{cmd:r(pvalue)}}p-value convention{p_end}
{synopt:{cmd:r(seed)}}seed{p_end}
{synopt:{cmd:r(cv)}}asymptotic reference used: {cmd:shin}, {cmd:sim} or {cmd:none}{p_end}
{synopt:{cmd:r(method)}}{cmd:kpss} or {cmd:cs}{p_end}
{synopt:{cmd:r(transvar)}, {cmd:r(thrvar)}}transition / threshold variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}1 x 11: eta, p_boot, p_asy, bootstrap and asymptotic 10/5/1% critical
values, then bootstrap and asymptotic 2.5% critical values{p_end}
{synopt:{cmd:r(shin_table)}}15 x 6 panel of Shin (1994) Table 1 for the deterministic case
(fractile, m = 1,...,5); {cmd:cv(shin)} only{p_end}
{synopt:{cmd:r(b)}}parameter estimates (leads/lags coefficients excluded){p_end}
{synopt:{cmd:r(profile)}}(N+1) x 2 empirical variance profile (s, rho){p_end}
{synopt:{cmd:r(boot)}}B x 1 bootstrap statistics{p_end}
{synopt:{cmd:r(cs_blocks)}}{cmd:method(cs)}: M x 4 (start, end (residual index), C{c 94}(b,i),
p-value){p_end}
{synopt:{cmd:r(cs_mv)}}{cmd:method(cs)}: (b, SC(b)) of the minimum-volatility search{p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix
estimation. {it:Econometrica} 59(3): 817-858.
{browse "https://doi.org/10.2307/2938229":doi:10.2307/2938229}

{phang}
Cavaliere, G. and A. M. R. Taylor. 2006. Testing the null of co-integration in the presence
of variance breaks. {it:Journal of Time Series Analysis} 27(4): 613-636.
{browse "https://doi.org/10.1111/j.1467-9892.2006.00475.x":doi:10.1111/j.1467-9892.2006.00475.x}

{phang}
Choi, I. and P. Saikkonen. 2010. Tests for nonlinear cointegration. {it:Econometric Theory}
26(3): 682-709.
{browse "https://doi.org/10.1017/S0266466609990065":doi:10.1017/S0266466609990065}

{phang}
Gonzalo, J. and J.-Y. Pitarakis. 2006. Threshold effects in cointegrating relationships.
{it:Oxford Bulletin of Economics and Statistics} 68(s1): 813-833.
{browse "https://doi.org/10.1111/j.1468-0084.2006.00458.x":doi:10.1111/j.1468-0084.2006.00458.x}

{phang}
Hanck, C. and T. Massing. 2025. Testing for nonlinear cointegration under heteroskedasticity.
{it:Econometric Reviews} 44(4): 512-543.
{browse "https://doi.org/10.1080/07474938.2024.2429598":doi:10.1080/07474938.2024.2429598}
(arXiv:2102.08809).

{phang}
Hansen, B. E. 2000. Testing for structural change in conditional models.
{it:Journal of Econometrics} 97(1): 93-115.
{browse "https://doi.org/10.1016/S0304-4076(99)00068-8":doi:10.1016/S0304-4076(99)00068-8}

{phang}
Kwiatkowski, D., P. C. B. Phillips, P. Schmidt and Y. Shin. 1992. Testing the null hypothesis
of stationarity against the alternative of a unit root. {it:Journal of Econometrics} 54:
159-178.
{browse "https://doi.org/10.1016/0304-4076(92)90104-Y":doi:10.1016/0304-4076(92)90104-Y}

{phang}
Saikkonen, P. 1991. Asymptotically efficient estimation of cointegration regressions.
{it:Econometric Theory} 7(1): 1-21.
{browse "https://doi.org/10.1017/S0266466600004217":doi:10.1017/S0266466600004217}

{phang}
Shin, Y. 1994. A residual-based test of the null of cointegration against the alternative of
no cointegration. {it:Econometric Theory} 10(1): 91-115.
{browse "https://doi.org/10.1017/S0266466600008240":doi:10.1017/S0266466600008240}

{phang}
Stock, J. H. and M. W. Watson. 1993. A simple estimator of cointegrating vectors in higher
order integrated systems. {it:Econometrica} 61(4): 783-820.
{browse "https://doi.org/10.2307/2951763":doi:10.2307/2951763}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original method papers above together with the {cmd:cointvol} package.

{title:Also see}

{psee}
{helpb cointvol}, {helpb cointvol_rank:cointvol rank}, {helpb tsset}
{p_end}
