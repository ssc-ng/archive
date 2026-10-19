{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "mvardlurt_multivariate" "help mvardlurt_multivariate"}{...}
{viewerjumpto "Syntax" "fmvardlurt##syntax"}{...}
{viewerjumpto "Description" "fmvardlurt##description"}{...}
{viewerjumpto "Options" "fmvardlurt##options"}{...}
{viewerjumpto "Bootstrap" "fmvardlurt##bootstrap"}{...}
{viewerjumpto "Remarks" "fmvardlurt##remarks"}{...}
{viewerjumpto "Postestimation" "fmvardlurt##postest"}{...}
{viewerjumpto "Stored results" "fmvardlurt##results"}{...}
{viewerjumpto "Examples" "fmvardlurt##examples"}{...}
{viewerjumpto "References" "fmvardlurt##references"}{...}
{title:Title}

{p 4 8 2}
{bf:fmvardlurt} {hline 2} Fourier multivariate ARDL unit-root and cointegration test with
any number of covariates and bootstrap critical values


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:fmvardlurt} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt c:ase(#)}}{cmd:3} intercept (default) or {cmd:5} intercept and linear trend{p_end}
{synopt:{opt kmax(#)}}largest Fourier frequency searched, 1-5; default {cmd:3}{p_end}
{synopt:{opt freq(#)}}fixed frequency; {cmd:freq(0)} drops the Fourier terms (plain test){p_end}
{synopt:{opt maxl:ag(#)}}largest lag searched, 0-8; default {cmd:2}{p_end}
{synopt:{opt ic(aic|bic)}}information criterion; default {cmd:bic}{p_end}
{synopt:{opt fixl:ag(numlist)}}fixed lags {it:p q} (common q) or {it:p q1 ... qk}{p_end}
{synopt:{opt nocont:emp}}drop the contemporaneous differences of the covariates{p_end}

{syntab:Inference}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:999} (minimum 99){p_end}
{synopt:{opt seed(#)}}random-number seed; default {cmd:12345}{p_end}
{synopt:{opt l:evel(#)}}decision level for the four-case table; default {cmd:95}{p_end}
{synopt:{opt nores:elect}}keep the selected lags and frequency fixed in the bootstrap draws{p_end}
{synopt:{opt noboot}}statistics only{p_end}

{syntab:Reporting}
{synopt:{opt not:able}}suppress the selection table{p_end}
{synopt:{opt nodisplay}}suppress all output{p_end}
{synopt:{opt di:ag}}residual diagnostics after estimation{p_end}
{synopt:{opt nog:raph}}suppress the graphs{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb tsset} as a single time series without gaps in the estimation sample;
at least 30 observations are required. Typing {cmd:fmvardlurt} alone redisplays the results.


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:fmvardlurt} adds a Fourier approximation of smooth, unknown structural change
(Enders and Lee 2012) to the multivariate ARDL unit-root test of Sam, McNown, Goh and Goh (2025):

{p 8 8 2}
D.y = c [+ b t] + a1 sin(2 pi k t/T) + a2 cos(2 pi k t/T) + pi L.y + delta' L.x
+ sum_j phi_j Lj.D.y + sum_i sum_j gamma_ij Lj.D.x_i + omega' D.x + u

{p 4 4 2}
Three statistics are reported:

{p 8 12 2}- {bf:t} on L.y, H0: pi = 0 (unit root), lower tail;{p_end}
{p 8 12 2}- {bf:F} = Wald/k on the lagged covariate levels, H0: delta = 0 (no level relationship), upper tail;{p_end}
{p 8 12 2}- {bf:F Fourier} = Wald/2 on (a1, a2), H0: no Fourier component, upper tail.{p_end}

{p 4 4 2}
The four-case rule of Sam et al. (2025) combines the t and F decisions:
{bf:Case I} neither rejects (unit root, no cointegration);
{bf:Case II} t only (y stationary, here around a smooth break);
{bf:Case III} F only (degenerate; possibly I(2));
{bf:Case IV} both (cointegration, with a smooth break in the intercept).

{p 4 4 2}
The Fourier F statistic is a pre-test. If it does not reject, the Fourier terms only cost
degrees of freedom and the plain test ({cmd:freq(0)}) is more powerful.


{marker options}{...}
{title:Options}

{phang}
{opt case(#)}: 3 (intercept, default) or 5 (intercept and trend). The Fourier terms shift the
intercept; with {cmd:case(5)} the trend is linear and the Fourier terms add the smooth deviation.

{phang}
{opt kmax(#)} and {opt freq(#)}: by default the frequency k is chosen from 1, ..., {cmd:kmax()}
together with the lags. With {cmd:fixlag()}, k minimises the sum of squared residuals
(Enders and Lee 2012); otherwise the information criterion is minimised over (p, q, k) jointly,
which for given lags is the same rule. {cmd:freq(#)} fixes k; {cmd:freq(0)} gives the plain
multivariate ARDL test with the same bootstrap. Low frequencies (k = 1, 2) describe one or two
smooth breaks; Enders and Lee recommend kmax no larger than 3 to 5.

{phang}
{opt maxlag(#)}, {opt ic()}, {opt fixlag()}: lag search over p = 0..maxlag lags of D.y and a
common q = 0..maxlag lags of each D.x on one common sample (models with fewer than 5 residual
degrees of freedom are skipped), or fixed lags. {cmd:fixlag(p q1 ... qk)} gives each covariate
its own lag order.

{phang}
{opt nocontemp}: by default the contemporaneous D.x enter the regression (a conditional
error-correction model). They absorb correlation between the shocks to y and to the covariates
and raise power.

{phang}
{opt noreselect}: keep the selected lags and frequency fixed in the bootstrap. Not recommended:
the bootstrap then ignores the search that produced the observed statistics.


{marker bootstrap}{...}
{title:Bootstrap}

{p 4 4 2}
All p-values and critical values come from a residual bootstrap that

{p 8 12 2}1. imposes the joint null pi = 0 and delta = 0 in one restricted regression;{p_end}
{p 8 12 2}2. leaves the intercept, the trend and the Fourier terms out of the generating process,
so the bootstrap series are driftless unit-root processes without a Fourier component;{p_end}
{p 8 12 2}3. centres the restricted residuals, rescales them by sqrt(n/(n-m)), resamples them with
replacement and rebuilds D.y* and y* recursively, holding the covariates at their observed values;{p_end}
{p 8 12 2}4. repeats the lag and frequency search on every bootstrap sample;{p_end}
{p 8 12 2}5. stores t*, F* and the Fourier F* from the same draw.{p_end}

{p 4 4 2}
p-values are (1 + #{t* <= t})/(B + 1) and (1 + #{F* >= F})/(B + 1). The Fourier F test is thus
calibrated under a unit root without a Fourier component.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Simulation evidence} (2,000 replications per design; 2, 3 and 5 covariates; T = 50, 100, 200;
smooth level shifts of 0, 3 and 6 innovation standard deviations). Under the null the t and F
tests rejected in 3-7% of samples at a nominal 5%, with or without breaks and with fixed or
BIC-selected lags, and the Fourier F test in 4-8%. With T = 100 or 200 and a smooth break in a
stationary or cointegrated series, the Fourier version was much more powerful than the test
without Fourier terms (for example 74% against 12% correct Case II decisions with a temporary
break at T = 100). With T = 50 it was less powerful than the plain test even when a break was
present, and without a break it was less powerful at T = 50 and 100; this is why the Fourier F pre-test is
reported. A smooth Fourier term absorbs a single large level shift only in part, so the F test can
still over-reject a level relation for a stationary series with such a shift (though much less than
the plain test). See the article that accompanies the package for the full tables.

{p 4 4 2}
{bf:Short samples, many covariates.} With T below 50 and four or more covariates, the selected
model can leave few residual degrees of freedom; the bootstrap then has little power. Check the
residual degrees of freedom in Table 1, compare {cmd:fixlag(1 1)}, and read a Case I result as an
absence of evidence.

{p 4 4 2}
{bf:Limits.} The F test assumes at most one cointegrating relation and no feedback from y to the
covariates in levels. A smooth Fourier function approximates gradual or temporary shifts; it does
not date sharp breaks, and a large single shift is only partly absorbed by one frequency.
Residual serial correlation invalidates the bootstrap; check {cmd:fmvardlurt_diag}.


{marker postest}{...}
{title:Postestimation}

{p 4 8 2}{cmd:fmvardlurt_diag} - Breusch-Godfrey(1), RESET, Breusch-Pagan (Koenker), ARCH(1), Jarque-Bera; {cmd:r(diag)}.{p_end}
{p 4 8 2}{cmd:fmvardlurt_graph} [{cmd:, scheme(}{it:name}{cmd:) nocombine}] - Fourier component, bootstrap distributions, CUSUM.{p_end}
{p 4 8 2}{cmd:predict} {it:newvar} [{cmd:, xb residuals fourier}] - fitted D.y, residuals, or the fitted Fourier component.{p_end}
{p 4 4 2}
These use objects kept in Mata; after {cmd:mata clear}, re-run {cmd:fmvardlurt}.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(T)}}observations used / in the sample{p_end}
{synopt:{cmd:e(tstat)}, {cmd:e(fstat)}, {cmd:e(ffstat)}}t, F and Fourier F statistics{p_end}
{synopt:{cmd:e(p_t)}, {cmd:e(p_f)}, {cmd:e(p_ff)}}bootstrap p-values{p_end}
{synopt:{cmd:e(B)}}valid bootstrap draws{p_end}
{synopt:{cmd:e(opt_p)}, {cmd:e(freq)}}lags of D.y; selected frequency (0 = none){p_end}
{synopt:{cmd:e(k)}, {cmd:e(case)}, {cmd:e(kmax)}, {cmd:e(maxlag)}, {cmd:e(reps)}, {cmd:e(seed)}}settings{p_end}
{synopt:{cmd:e(level)}, {cmd:e(alpha)}, {cmd:e(boot)}, {cmd:e(reselect)}, {cmd:e(contemp)}}settings{p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_a)}, {cmd:e(rss)}, {cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(df_r)}}fit{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}, {cmd:e(cmdline)}, {cmd:e(depvar)}, {cmd:e(indepvars)}, {cmd:e(opt_q)}}{p_end}
{synopt:{cmd:e(casename)}, {cmd:e(ic)}, {cmd:e(lags)}, {cmd:e(freqsel)}, {cmd:e(t_start)}, {cmd:e(t_end)}}{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients of the D.y regression{p_end}
{synopt:{cmd:e(cv)}}3 x 5 critical values (rows t, F, F Fourier; columns 10%, 5%, 2.5%, 1%, decision level){p_end}
{synopt:{cmd:e(ic_table)}}information criteria; rows (p, q) with p outer and q inner, columns frequencies{p_end}
{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. fmvardlurt ln_inv ln_inc ln_consump}{p_end}
{phang2}{cmd:. fmvardlurt ln_inv ln_inc ln_consump, fixlag(1 1) kmax(2)}{p_end}
{phang2}{cmd:. fmvardlurt ln_inv ln_inc ln_consump, freq(0) nograph}{p_end}
{phang2}{cmd:. fmvardlurt_diag}{p_end}
{phang2}{cmd:. predict double fc, fourier}{p_end}

{p 4 4 2}
More examples, including simulated series with a smooth break, are in {cmd:fmvardlurt_example.do}.


{marker references}{...}
{title:References}

{p 4 8 2}Enders, W. and J. Lee. 2012. A unit root test using a Fourier series to approximate smooth breaks.
{it:Oxford Bulletin of Economics and Statistics} 74: 574-599.{p_end}
{p 4 8 2}Becker, R., W. Enders and J. Lee. 2006. A stationarity test in the presence of an unknown number of smooth breaks.
{it:Journal of Time Series Analysis} 27: 381-409.{p_end}
{p 4 8 2}Sam, C. Y., R. McNown, S. K. Goh and K. L. Goh. 2025. A multivariate autoregressive distributed lag unit root test.
{it:Studies in Economics and Econometrics} 49: 17-33.{p_end}
{p 4 8 2}McNown, R., C. Y. Sam and S. K. Goh. 2018. Bootstrapping the autoregressive distributed lag test for cointegration.
{it:Applied Economics} 50: 1509-1521.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}
