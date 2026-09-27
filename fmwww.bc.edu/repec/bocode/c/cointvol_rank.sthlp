{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol select" "help cointvol_select"}{...}
{vieweralsosee "cointvol adaptive" "help cointvol_adaptive"}{...}
{vieweralsosee "cointvol garchrank" "help cointvol_garchrank"}{...}
{vieweralsosee "cointvol diag" "help cointvol_diag"}{...}
{vieweralsosee "[TS] vecrank" "help vecrank"}{...}
{viewerjumpto "Syntax" "cointvol_rank##syntax"}{...}
{viewerjumpto "Description" "cointvol_rank##description"}{...}
{viewerjumpto "Options" "cointvol_rank##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_rank##methods"}{...}
{viewerjumpto "Remarks" "cointvol_rank##remarks"}{...}
{viewerjumpto "Examples" "cointvol_rank##examples"}{...}
{viewerjumpto "Stored results" "cointvol_rank##results"}{...}
{viewerjumpto "References" "cointvol_rank##references"}{...}
{viewerjumpto "Author" "cointvol_rank##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:cointvol rank} {hline 2}}Johansen cointegration-rank tests with bootstrap
inference robust to conditional and nonstationary volatility{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol rank} {varlist} {ifin}{cmd:,} {opt l:ags(#)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt l:ags(#)}}lag order {it:k} of the VAR in levels; {it:k} {ul:>} 1{p_end}
{synopt:{opt tr:end(string)}}deterministic case: {cmd:none}, {cmd:rconstant} (default),
{cmd:constant}, {cmd:rtrend} or {cmd:trend}{p_end}
{synopt:{opt r:ank(numlist)}}null ranks to test; default all {it:r} = 0,...,{it:p}-1{p_end}

{syntab:Inference}
{synopt:{opt m:ethod(string)}}{cmd:wild} (default), {cmd:iid} or {cmd:asy}{p_end}
{synopt:{opt alg:orithm(string)}}bootstrap DGP: {cmd:crt14} (default) or {cmd:crt10}{p_end}
{synopt:{opt mult:iplier(string)}}wild multiplier: {cmd:gauss} (default), {cmd:rademacher},
{cmd:mammen}{p_end}
{synopt:{opt r:eps(#)}}bootstrap replications; default {cmd:999}; minimum 19{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt pval:ue(string)}}{cmd:strict} (default) or {cmd:plusone}{p_end}
{synopt:{opt l:evel(#)}}significance level for stars and sequential selection;
default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt cv}}also display asymptotic and bootstrap critical values{p_end}
{synopt:{opt gr:aph}}plot the bootstrap distributions of the trace statistics{p_end}
{synopt:{opt graphn:ame(name)}}name of the combined graph; default {cmd:cointvol_rank}{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the bootstrap statistics to a dataset{p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required. The data must be {helpb tsset} as a time series
(not a panel) without gaps in the estimation sample. {it:varlist} may contain
time-series operators.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol rank} computes the Johansen (1996) trace and maximum-eigenvalue
statistics for the cointegration rank of a {it:p}-dimensional VAR({it:k}) and
reports three sets of p-values side by side: asymptotic, i.i.d.-bootstrap and
wild-bootstrap. It also selects the rank by the usual sequential procedure.

{pstd}
The standard Johansen p-values assume homoskedastic innovations. Under
{it:nonstationary} (unconditional) volatility, such as variance breaks or
trending volatility, the limiting distributions are no longer the Johansen ones.
The asymptotic test can then over-reject badly: Cavaliere, Rahbek and Taylor
(2010a) report sizes above 60% at a nominal 5%. The wild bootstrap
restores correct size under both conditional (GARCH-type) and nonstationary
volatility (Cavaliere, Rahbek and Taylor 2010a, 2010b, 2014). The i.i.d.
bootstrap (Swensen 2006; Cavaliere, Rahbek and Taylor 2012) is valid under
homoskedasticity and conditional heteroskedasticity only.

{pstd}
Use {cmd:method(wild)} as the default in applied work with financial or
macroeconomic data. When volatility is visibly time-varying, compare it with
{helpb cointvol_adaptive:cointvol adaptive}, which gains power by reweighting
with a nonparametric volatility estimate. Use {helpb cointvol_select:cointvol select}
to choose the lag order and the rank jointly.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} is the lag order {it:k} of the VAR in levels, so the VECM has
{it:k}-1 lagged differences (same convention as {helpb vec} and {helpb vecrank}).

{phang}
{opt trend(string)} specifies the deterministic terms, using the keywords of
{helpb vec}: {cmd:none} (no deterministics), {cmd:rconstant} (constant restricted
to the cointegration space; the default, which is the case used in the CRT papers),
{cmd:constant} (unrestricted constant), {cmd:rtrend} (restricted trend and
unrestricted constant), and {cmd:trend} (unrestricted trend). Abbreviations
{cmd:rc}, {cmd:c}, {cmd:rt} and {cmd:t} are allowed.

{phang}
{opt rank(numlist)} restricts the tests to the listed null ranks. The sequential
selection is reported only when the full sequence 0,...,{it:p}-1 is tested.

{dlgtab:Inference}

{phang}
{opt method(string)}: {cmd:wild} is the wild bootstrap (Original: CRT 2010a,
Algorithm 1; CRT 2014); {cmd:iid} is the i.i.d. bootstrap resampling recentred
residuals (Original: Swensen 2006; CRT 2012); {cmd:asy} reports only the
asymptotic p-values.

{phang}
{opt algorithm(string)} chooses the bootstrap data-generating process.
{cmd:crt14} (Original: CRT 2012, 2014; CDRT 2018, Algorithm 1) estimates all
parameters under H(r), recentres the restricted residuals, uses the data as
initial values and includes the deterministics in the recursion. {cmd:crt10}
(Original: CRT 2010a, Algorithm 1; Swensen 2006 for {cmd:iid}) takes
{it:alpha} and {it:beta} from H(r), but the short-run matrices, unrestricted
deterministics and residuals from the unrestricted model H(p). {cmd:crt14} has
the better theoretical properties and is the default.

{phang}
{opt multiplier(string)}: the wild-bootstrap weights {it:w_t}: {cmd:gauss}
N(0,1) (used in the CRT papers), {cmd:rademacher} (+1/-1 with probability 1/2),
or {cmd:mammen} (Mammen's two-point distribution). The option is ignored unless
{cmd:method(wild)} is specified.

{phang}
{opt reps(#)} is the number of bootstrap replications B. CRT use 399; 999 is the
default here.

{phang}
{opt seed(string)} sets the seed. Results are reproducible given the seed.

{phang}
{opt pvalue(string)}: {cmd:strict} gives p = B{c 94}-1 sum 1(Q* > Q) (CRT 2010a,
Remark 4.4); {cmd:plusone} gives p = (#{Q* {ul:>} Q} + 1)/(B + 1) (the R package
{it:VARtests} convention).

{phang}
{opt level(#)} sets the level used for the stars and for the sequential
selection. A test rejects when p < 1 - {it:level}/100.

{dlgtab:Reporting}

{phang}
{opt cv} adds a table of 5% asymptotic and {it:level}% bootstrap critical values.

{phang}
{opt graph} draws, for each H0, a histogram and kernel density of the bootstrap
trace statistics, with the observed statistic as a dashed line.

{phang}
{opt saving()} saves the B x (number of tests) bootstrap trace and
max-eigenvalue statistics to a Stata dataset.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model.} The VECM is
{p_end}
{p 8 8 2}
{it:dX_t = alpha beta'X_{t-1} + sum_{i=1}{c 94}{k-1} Gamma_i dX_{t-i} + (deterministics) + e_t},
{p_end}
{pstd}
with {it:e_t} a martingale difference sequence that may display conditional
heteroskedasticity (CRT 2010b) or nonstationary volatility
{it:e_t = sigma(t/T) z_t} (CRT 2010a, eqs. 1-3).

{pstd}
{bf:Statistics.} With {it:Z0 = dX_t}, {it:Z1 = (X_{t-1}', D1_t')'} and
{it:Z2} = (lagged differences, unrestricted deterministics), let {it:S_ij} be the
product-moment matrices of the residuals from regressing {it:Z0} and {it:Z1} on
{it:Z2}. The eigenvalues 1 > lambda_1 > ... > lambda_p solve
|lambda S11 - S10 S00{c 94}-1 S01| = 0. The trace and max-eigenvalue statistics are
{p_end}
{p 8 8 2}
Q_r = -T sum_{i=r+1}{c 94}p log(1 - lambda_i),{space 4}Q_r,max = -T log(1 - lambda_{r+1})
{p_end}
{pstd}
(Johansen 1996; CRT 2010a, eq. 8). These match {helpb vecrank} exactly.

{pstd}
{bf:Asymptotic p-values.} The limit of Q_r under homoskedasticity is a functional
of an ({it:p}-{it:r})-dimensional Brownian motion that depends on the
deterministic case. Its mean and variance were simulated for {it:m} = {it:p}-{it:r}
= 1,...,12 and each case (T = 1000 steps, 20,000 replications). A Gamma
distribution with those two moments approximates the limit (Doornik 1998). The
resulting 5% critical values agree with the MacKinnon, Haug and Michelis (1999)
tables to about 0.1.

{pstd}
{bf:Bootstrap, algorithm crt14} (CRT 2012, 2014; CDRT 2018, Algorithm 1):{p_end}
{p 8 12 2}1. Estimate the VECM under H(r) by reduced-rank regression: alpha, beta,
Gamma_i, the deterministics and the residuals e_t. Recentre the residuals.{p_end}
{p 8 12 2}2. For b = 1,...,B, draw bootstrap errors: e*_t = e_t w_t with w_t i.i.d.
multipliers (wild), or resample the e_t with replacement (iid).{p_end}
{p 8 12 2}3. Build X*_t recursively from the restricted VECM, using the observed
X_1,...,X_k as initial values and including the deterministics.{p_end}
{p 8 12 2}4. Compute Q*_r and Q*_r,max on X*_t with the same lag order and
deterministic case.{p_end}
{p 8 12 2}5. p-value = B{c 94}-1 sum_b 1(Q*_r > Q_r).{p_end}
{pstd}
In algorithm {cmd:crt10}, step 1 takes Gamma, the unrestricted deterministics and
the residuals from the unrestricted model (CRT 2010a, Algorithm 1).

{pstd}
{bf:Sequential selection.} Test H(0), H(1), ... in turn. The selected rank is the
first {it:r} whose p-value is at least 1 - {it:level}/100, or {it:p} if every null
is rejected. This procedure is consistent for both bootstraps
(CRT 2010a, footnote 1; CDRT 2018).

{pstd}
{bf:Explosive bootstrap roots.} When the restricted estimates imply companion
roots with modulus > 1, the table says so. CDRT (2018) and Cavaliere, Taylor and
Trenkler (2015) show that this does not affect first-order validity. Singular
bootstrap samples are redrawn and counted in the footnote.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Original vs extended.} The trace statistic with wild or i.i.d. bootstrap, and
the crt10/crt14 algorithms, are Original (sources above). Bootstrap p-values for
the max-eigenvalue statistic are Extended implementation: the same bootstrap DGP
is used, as is common practice, but the CRT validity proofs cover the trace
statistic. The Gamma approximation to the asymptotic p-values follows Doornik
(1998), with moments simulated by {cmd:cointvol} (Extended implementation).

{pstd}
{bf:Choosing B.} With B = 399 the Monte Carlo standard error of a p-value near
0.05 is about 0.011. Use {cmd:reps(999)} or more for final results.

{pstd}
{bf:Validation.} The eigenvalues and statistics match {helpb vecrank}. The
crt14 wild and iid bootstrap follows the same algorithm as {cmd:cointBootTest}
in the R package {it:VARtests} (Belfrage, Catani and Ahlgren). See
{cmd:tests/test_rank.do}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse balance2, clear}{p_end}

{pstd}Asymptotic p-values only (instant){p_end}
{phang2}{cmd:. cointvol rank y i c, lags(2) method(asy)}{p_end}

{pstd}Wild bootstrap, CRT (2014) algorithm, Rademacher weights{p_end}
{phang2}{cmd:. cointvol rank y i c, lags(2) trend(rconstant) method(wild) multiplier(rademacher) reps(499) seed(2026)}{p_end}

{pstd}i.i.d. bootstrap with the CRT (2010) algorithm (Swensen 2006), critical values and graph{p_end}
{phang2}{cmd:. cointvol rank y i c, lags(2) method(iid) algorithm(crt10) reps(399) seed(1) cv graph}{p_end}

{pstd}Simulated data with a variance break (CRT 2010a design){p_end}
{phang2}{cmd:. cointvol simulate, nobs(200) dgp(vecm) clear seed(7)}{p_end}
{phang2}{cmd:. cointvol rank y1 y2, lags(1) method(wild) reps(399) seed(7)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol rank} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}effective number of observations T{p_end}
{synopt:{cmd:r(p)}}number of variables{p_end}
{synopt:{cmd:r(lags)}}lag order k{p_end}
{synopt:{cmd:r(level)}}level{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(rank_asy_trace)}}selected rank, asymptotic trace{p_end}
{synopt:{cmd:r(rank_asy_max)}}selected rank, asymptotic max-eigenvalue{p_end}
{synopt:{cmd:r(rank_boot_trace)}}selected rank, bootstrap trace{p_end}
{synopt:{cmd:r(rank_boot_max)}}selected rank, bootstrap max-eigenvalue{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol rank}{p_end}
{synopt:{cmd:r(varlist)}}variables{p_end}
{synopt:{cmd:r(trend)}}deterministic case{p_end}
{synopt:{cmd:r(method)}}{cmd:asy}, {cmd:iid} or {cmd:wild}{p_end}
{synopt:{cmd:r(algorithm)}}{cmd:crt14} or {cmd:crt10}{p_end}
{synopt:{cmd:r(multiplier)}}wild multiplier{p_end}
{synopt:{cmd:r(pvalue)}}p-value convention{p_end}
{synopt:{cmd:r(seed)}}seed{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}one row per H0: r, eigenvalue, trace, asy. p, boot. p,
asy. cv, boot. cv, max-eig, asy. p, boot. p, asy. cv, boot. cv, explosive-root
flag, redraw count{p_end}
{synopt:{cmd:r(eigenvalues)}}eigenvalues{p_end}
{synopt:{cmd:r(beta)}}eigenvectors (unrestricted beta, including restricted
deterministic rows){p_end}
{synopt:{cmd:r(boot_trace)}}B x tests bootstrap trace statistics{p_end}
{synopt:{cmd:r(boot_max)}}B x tests bootstrap max-eigenvalue statistics{p_end}


{marker references}{...}
{title:References}

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010a. Testing for co-integration
in vector autoregressions with non-stationary volatility.
{it:Journal of Econometrics} 158: 7-24.
{browse "https://doi.org/10.1016/j.jeconom.2010.03.003":doi:10.1016/j.jeconom.2010.03.003}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2010b. Cointegration rank testing
under conditional heteroskedasticity. {it:Econometric Theory} 26: 1719-1760.
{browse "https://doi.org/10.1017/S0266466609990776":doi:10.1017/S0266466609990776}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2012. Bootstrap determination of
the co-integration rank in vector autoregressive models. {it:Econometrica} 80:
1721-1740.
{browse "https://doi.org/10.3982/ECTA9099":doi:10.3982/ECTA9099}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2014. Bootstrap determination of
the co-integration rank in heteroskedastic VAR models. {it:Econometric Reviews}
33: 606-650.
{browse "https://doi.org/10.1080/07474938.2013.825175":doi:10.1080/07474938.2013.825175}.

{phang}
Cavaliere, G., L. De Angelis, A. Rahbek, and A. M. R. Taylor. 2018. Determining
the cointegration rank in heteroskedastic VAR models of unknown order.
{it:Econometric Theory} 34: 349-382.
{browse "https://doi.org/10.1017/S0266466616000335":doi:10.1017/S0266466616000335}.

{phang}
Cavaliere, G., A. M. R. Taylor, and C. Trenkler. 2015. Bootstrap co-integration
rank testing: The effect of bias-correcting parameter estimates.
{it:Oxford Bulletin of Economics and Statistics} 77: 740-759.
{browse "https://doi.org/10.1111/obes.12090":doi:10.1111/obes.12090}.

{phang}
Doornik, J. A. 1998. Approximations to the asymptotic distributions of
cointegration tests. {it:Journal of Economic Surveys} 12: 573-593.
{browse "https://doi.org/10.1111/1467-6419.00068":doi:10.1111/1467-6419.00068}.

{phang}
Johansen, S. 1996. {it:Likelihood-Based Inference in Cointegrated Vector
Autoregressive Models}. Oxford: Oxford University Press.

{phang}
Swensen, A. R. 2006. Bootstrap algorithms for testing and determining the
cointegration rank in VAR models. {it:Econometrica} 74: 1699-1714.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00723.x":doi:10.1111/j.1468-0262.2006.00723.x}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
