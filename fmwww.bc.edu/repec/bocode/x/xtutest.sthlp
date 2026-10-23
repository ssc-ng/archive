{smcl}
{* *! version 1.3.0  20oct2026}{...}
{viewerjumpto "Syntax" "xtutest##syntax"}{...}
{viewerjumpto "Description" "xtutest##description"}{...}
{viewerjumpto "Options" "xtutest##options"}{...}
{viewerjumpto "Remarks" "xtutest##remarks"}{...}
{viewerjumpto "Stored results" "xtutest##results"}{...}
{viewerjumpto "Examples" "xtutest##examples"}{...}
{viewerjumpto "References" "xtutest##references"}{...}
{title:Title}

{p 4 8 2}
{bf:xtutest} {hline 2} Test for an inverse U-shaped (or U-shaped) relationship and estimate its
turning point in heterogeneous panels with cross-sectional dependence


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtutest} {depvar} {it:xvar} [{it:controls}] {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt est:imator(name)}}{cmd:cce} (default), {cmd:mg}, {cmd:ccep}, {cmd:fe}, {cmd:re}, {cmd:iv} or {cmd:gmm}; see {help xtutest##estimators:Estimators}{p_end}
{synopt:{opt iv:inst(varlist)}}excluded instruments for {it:xvar} and its square with {cmd:estimator(iv)}; default: their first lags{p_end}
{synopt:{opt endog}}with {cmd:estimator(gmm)}: treat {it:xvar} and its square as endogenous{p_end}
{synopt:{opt gmml:ags(#)}}with {cmd:estimator(gmm)}: deepest lag used as instrument; default {cmd:2}{p_end}
{synopt:{opt one:step}}with {cmd:estimator(gmm)}: one-step robust estimator instead of two-step{p_end}
{synopt:{opt notime}}{cmd:fe}, {cmd:re}, {cmd:iv}, {cmd:gmm}: omit the time dummies{p_end}
{synopt:{opt int:erval(# #)}}interval [xL, xH] for the shape test; default: 5th and 95th percentiles of {it:xvar}{p_end}
{synopt:{opt u:shape}}test for a U shape instead of an inverse U{p_end}
{synopt:{opt nocce}}synonym for {cmd:estimator(mg)}{p_end}
{synopt:{opt norm:al}}use N(0,1) instead of t(N-1) for p-values and intervals{p_end}
{synopt:{opt pool:ed}}also report the pooled two-way fixed-effects test, for comparison{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt unit:s}}list the unit coefficients and turning points{p_end}
{synopt:{opt di:ag}}also list the unit-level residual-test p-values ({cmd:cce}, {cmd:mg}){p_end}
{synopt:{opt gr:aph}}draw the mean curve and the unit turning points{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb xtset} with a panel and a time variable. Unbalanced panels are allowed:
the cross-section averages are computed period by period over the units observed in that period,
and each unit regression uses its own periods; units with too few observations for their
regression ({cmd:cce}, {cmd:mg}, {cmd:ccep}) are dropped with a note.
{it:xvar} enters linearly and squared; do not include its square yourself. At least 10 units are
required. Typing {cmd:xtutest} alone redisplays the results.


{marker description}{...}
{title:Description}

{p 4 4 2}
For each unit i, {cmd:xtutest} estimates

{p 8 8 2}
y_it = a_i + b1_i x_it + b2_i x_it^2 + c_i' w_it + d_i' zbar_t + e_it,

{p 4 4 2}
where w are the controls and zbar_t are the cross-section averages of (y, x, x^2, w), which
absorb unobserved common factors (common correlated effects; Pesaran 2006). The mean-group
estimate is the average of the unit coefficients, and its variance is estimated from their
dispersion (Pesaran and Smith 1995). Slopes may differ freely across units.

{p 4 4 2}
{bf:Shape test.} The slope of the mean curve b1 + 2 b2 x is evaluated at xL and xH. An inverse U
on [xL, xH] requires a positive slope at xL and a negative slope at xH. The intersection-union
statistic S = min(t_L, -t_H) (Sasabuchi 1980; Lind and Mehlum 2010) rejects H0 (monotone or U-shaped)
when both slopes are significant with the right signs; its size is at most the nominal level.
A significant b2 alone is not evidence of an inverse U.

{p 4 4 2}
{bf:Turning points.} Two estimands are reported because they differ when slopes are heterogeneous:

{p 8 12 2}(1) the turning point of the mean curve, -b1/(2 b2), with Fieller (1954) and delta-method
intervals. The Fieller interval is preferred: it is exact for a ratio under normality and is
reported as unbounded when the curvature is not significant;{p_end}
{p 8 12 2}(2) the median of the unit turning points -b1_i/(2 b2_i) among the units with the relevant
curvature, with a distribution-free order-statistic interval. The mean of unit turning points is not
reported: ratios of estimates have no finite mean.{p_end}

{p 4 4 2}
{bf:Diagnostics.} The Pesaran (2004) CD test is applied to the unit residuals (in an unbalanced
panel, each pair of units uses the periods they share, as in Pesaran 2015). With {opt pooled}, the
usual pooled two-way fixed-effects quadratic with a cluster-robust variance and the same
intersection-union test is shown for comparison.


{marker estimators}{...}
{title:Estimators}

{p 4 4 2}
{cmd:cce} and {cmd:mg} allow every unit its own curve and are the estimators the shape test is
designed for. {cmd:ccep} is the CCE pooled estimator of Pesaran (2006): one common curve, with
unit-specific coefficients on the cross-section averages, and the nonparametric variance of his
equation (69), built from the dispersion of the unit CCE slopes. It is the homogeneous-slope
estimator to use when the panel has cross-sectional dependence. The other four impose the same
slopes on all units without modelling common factors, as most applied work does, and
are offered as comparisons and robustness checks. With heterogeneous slopes they estimate a
weighted average that need not be the mean curve, and their inverse U can be spurious (see the
article). All four include unit effects and, unless {cmd:notime} is given, time dummies; their
coefficient covariance is cluster-robust by unit (Windmeijer-corrected for {cmd:gmm}), and the shape
test and intervals use t(N-1) ({cmd:fe}, {cmd:re}, {cmd:iv}) or N(0,1) ({cmd:gmm}).

{phang}
{cmd:fe}: {helpb xtreg}, {cmd:fe vce(cluster} {it:panelvar}{cmd:)}.{p_end}
{phang}
{cmd:re}: {helpb xtreg}, {cmd:re vce(cluster} {it:panelvar}{cmd:)}, with a cluster-robust Mundlak (1978) test of
random against fixed effects (unit means of the regressors added; H0: they are jointly zero).{p_end}
{phang}
{cmd:iv}: two-stage least squares on unit-demeaned data ({helpb ivregress} with {cmd:vce(cluster)}), with
{it:xvar} and its square endogenous. Instruments are {cmd:ivinst()} or, by default, the first lags of
{it:xvar} and of its square. Reported: first-stage cluster-robust F statistics of the excluded
instruments and, when overidentified, the score test of overidentifying restrictions.{p_end}
{phang}
{cmd:gmm}: system GMM ({helpb xtdpdsys}) with one lag of {it:depvar}, two-step, Windmeijer-robust. With few
units the two-step weight matrix is often singular; the command then says so and uses the one-step
robust estimator ({cmd:onestep} requests it directly). If that also fails, there are too many
instruments for the number of units: add {cmd:notime} or lower {cmd:gmmlags()}. The turning
point of the long-run curve equals that of the short-run curve, because both slopes are divided by
1 - rho. Reported: the Arellano-Bond AR(1) and AR(2) tests. System GMM is designed for many units and
few periods; with few units its instrument count can be large relative to N, and {cmd:gmmlags()}
should be kept small.{p_end}


{marker robust}{...}
{title:What each estimator is robust to}

{p 4 4 2}
The shape test is only as reliable as the standard errors behind it. The default does not need
the residual problems to be absent:

{p2colset 5 26 28 2}{...}
{p2col:{cmd:cce}, {cmd:ccep}}robust to heteroskedasticity (within and across units), serial correlation of
any form within units, non-normal errors, and cross-sectional dependence from unobserved common
factors, which the cross-section averages remove from the slopes themselves, not only from the
standard errors.{p_end}
{p2col:{cmd:mg}}as {cmd:cce}, except for common factors: if they are correlated with {it:xvar}, the slopes are biased.{p_end}
{p2col:{cmd:fe}, {cmd:re}, {cmd:iv}}cluster-robust: robust to heteroskedasticity, serial correlation within units and
non-normality, but not to cross-sectional dependence; time dummies remove common shocks only if every
unit responds to them equally.{p_end}
{p2col:{cmd:gmm}}Windmeijer-robust; valid if AR(2) does not reject; not robust to cross-sectional dependence.{p_end}
{p2colreset}{...}

{p 4 4 2}
In simulations with AR(1) errors (coefficient 0.5), unit-specific error variances, t(5) shocks, and one
common factor in {it:xvar} and the error with unit-specific loadings (N = 16 to 60, T = 24 to 50), the
5% t tests on b1 and b2 rejected in 2.9-6.3% of samples with {cmd:cce} and {cmd:ccep}, 4.2-9.6% with
{cmd:fe} and cluster-robust errors, and 12-49% with {cmd:fe} and Driscoll-Kraay errors. Driscoll-Kraay
errors are therefore not offered: with a common factor correlated with {it:xvar} the problem is bias in
the fixed-effects slopes, which no standard-error correction removes, and with T below 50 the
Driscoll-Kraay variance is itself unreliable. The residual tests below then serve to describe the
data, not to decide whether the inference can be trusted.


{marker diagnostics}{...}
{title:Residual diagnostics}

{p 4 4 2}
Every run reports tests for serial correlation, heteroskedasticity, normality and stability.

{p 4 4 2}
{bf:cce, mg}: each unit regression is tested with the Breusch-Godfrey LM(1) test, the Koenker form of the
Breusch-Pagan test (on the unit's own regressors), the Jarque-Bera test and the CUSUM test of
Brown, Durbin and Evans (1975), with p-value 2{c -(}1 - Phi(3a) + exp(-4a^2)Phi(a){c )-} for the largest
scaled crossing a. The table shows the number of units rejecting at 5% and two combinations of the
unit p-values: Fisher (Maddala and Wu 1999), -2 sum ln p ~ chi2(2N), and inverse normal (Choi 2001).
The combinations assume independent units; check the CD test first. {cmd:diag} lists the unit
p-values.

{p 4 4 2}
{bf:fe, re, iv}: Wooldridge (2002) test for first-order serial correlation (first-difference
regression, H0: corr(du_t, du_t-1) = -0.5, cluster-robust F); modified Wald test for groupwise
heteroskedasticity (Greene 2000), chi2(N); Jarque-Bera test on the pooled residuals; and, for
{cmd:fe} and {cmd:re}, a cluster-robust Wald test that the coefficients on {it:xvar} and its square are the
same in the two halves of the sample. {bf:gmm}: the Arellano-Bond AR(2) test replaces the Wooldridge
test; the stability test is not computed.

{p 4 4 2}
Heteroskedasticity and non-normality do not invalidate the shape test: the mean-group and
cluster-robust variances are robust to both. Serial correlation within units is also allowed by
the mean-group and cluster-robust variances; it matters mainly for {cmd:gmm}, where AR(2) must not
reject. Instability (a rejection of the CUSUM or split-sample test) means the curve changed over
the sample and a single turning point may not describe it.


{marker options}{...}
{title:Options}

{phang}
{opt interval(# #)} sets [xL, xH]. Choose a range of economically relevant values of {it:xvar},
such as the observed range. The default uses the 5th and 95th percentiles, which avoids testing
the slope at extreme observations.

{phang}
{opt normal} uses the standard normal reference distribution. The default t(N-1) is more
accurate with few units; the two coincide as N grows.

{phang}
{opt nocce} drops the cross-section averages. Use it only if the CD test does not reject.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Simulation evidence.} In a design with a common factor and heterogeneous, correlated slopes
(N = 15 to 60, T = 25 to 50), the CCE mean-group shape test had a rejection rate close to the nominal
level when the true turning point is at xH, while the pooled fixed-effects test found a
spurious inverse U in 29-42% of samples when the mean curve is linear but slopes are correlated
with the level of x. The Fieller interval covered the turning point of the mean curve in about
95% of samples. See the accompanying article for the tables.

{p 4 4 2}
{bf:Requirements.} Each unit regression has 3 + #controls coefficients, plus 3 + #controls
averages with CCE, so T must exceed this comfortably. Nonstationary data are allowed by the CCE
mean-group estimator (Kapetanios, Pesaran and Yamagata 2011), but a quadratic in an I(1)
regressor raises issues of its own; see the article.


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(N_g)}, {cmd:e(T)}}observations, units, periods{p_end}
{synopt:{cmd:e(sL)}, {cmd:e(sH)}, {cmd:e(tL)}, {cmd:e(tH)}}slopes of the mean curve at xL and xH and their t statistics{p_end}
{synopt:{cmd:e(S)}, {cmd:e(p)}}intersection-union statistic and p-value{p_end}
{synopt:{cmd:e(tp)}, {cmd:e(f_lo)}, {cmd:e(f_hi)}, {cmd:e(f_bounded)}}mean-curve turning point and Fieller interval{p_end}
{synopt:{cmd:e(d_lo)}, {cmd:e(d_hi)}}delta-method interval{p_end}
{synopt:{cmd:e(tp_median)}, {cmd:e(m_lo)}, {cmd:e(m_hi)}}median unit turning point and interval{p_end}
{synopt:{cmd:e(share)}, {cmd:e(n_curv)}}share and number of units with the relevant curvature{p_end}
{synopt:{cmd:e(cd)}, {cmd:e(cd_p)}}CD statistic and p-value{p_end}
{synopt:{cmd:e(xL)}, {cmd:e(xH)}, {cmd:e(df)}, {cmd:e(level)}, {cmd:e(cce)}, {cmd:e(het)}, {cmd:e(ushape)}, {cmd:e(normal)}}settings{p_end}
{synopt:{cmd:e(balanced)}, {cmd:e(T_min)}, {cmd:e(T_avg)}}balanced-panel indicator; shortest and mean unit time span{p_end}
{synopt:{cmd:e(mundlak)}, {cmd:e(mundlak_df)}, {cmd:e(mundlak_p)}}{cmd:re}: Mundlak test{p_end}
{synopt:{cmd:e(rho)}}{cmd:gmm}: coefficient on the lagged dependent variable{p_end}
{synopt:{cmd:e(tbreak)}}{cmd:fe}, {cmd:re}: last period of the first half in the stability test{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}, {cmd:e(cmdline)}, {cmd:e(depvar)}, {cmd:e(xvar)}, {cmd:e(controls)}, {cmd:e(ivar)}, {cmd:e(tvar)}, {cmd:e(estimator)}, {cmd:e(estname)}, {cmd:e(vce)}, {cmd:e(interval)}}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}mean-group coefficients on {it:xvar}, its square and the controls, and their variance{p_end}
{synopt:{cmd:e(units)}}unit id, b(x), b(x^2), turning point, curvature indicator, p-values of BG(1), Koenker, JB, CUSUM{p_end}
{synopt:{cmd:e(diag)}}{cmd:cce}, {cmd:mg}: 4 x 6 (rows serial, hetero, normality, stability; columns share rejecting, units, Fisher statistic and p, inverse-normal statistic and p); other estimators: 4 x 3 (statistic, df, p){p_end}
{synopt:{cmd:e(ivgmm)}}{cmd:iv}, {cmd:gmm}: first-stage F for x and x^2, overidentification statistic and p, AR(1) and AR(2) p{p_end}
{synopt:{cmd:e(pooled)}}with {opt pooled}: sL, sH, tL, tH, S, p, turning point, b(x), b(x^2) and their standard errors{p_end}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. net get xtutest}{space 6}(example dataset, if installed with {cmd:net install}){p_end}
{phang2}{cmd:. use xtutest_apec, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. generate lnEF = ln(EF)}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, pooled}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, interval(0 100) units graph}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, diag}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, estimator(ccep)}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, estimator(fe)}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, estimator(re)}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, estimator(iv)}{p_end}
{phang2}{cmd:. xtutest lnEF NET GLB, estimator(gmm) gmmlags(2)}{p_end}

{p 4 4 2}
A simulated example with known turning point is in {cmd:xtutest_example.do}.


{marker references}{...}
{title:References}

{p 4 8 2}Arellano, M. and S. Bond. 1991. Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations. {it:Review of Economic Studies} 58: 277-297.{p_end}
{p 4 8 2}Blundell, R. and S. Bond. 1998. Initial conditions and moment restrictions in dynamic panel data models. {it:Journal of Econometrics} 87: 115-143.{p_end}
{p 4 8 2}Brown, R. L., J. Durbin and J. M. Evans. 1975. Techniques for testing the constancy of regression relationships over time. {it:Journal of the Royal Statistical Society, Series B} 37: 149-192.{p_end}
{p 4 8 2}Choi, I. 2001. Unit root tests for panel data. {it:Journal of International Money and Finance} 20: 249-272.{p_end}
{p 4 8 2}Drukker, D. M. 2003. Testing for serial correlation in linear panel-data models. {it:Stata Journal} 3: 168-177.{p_end}
{p 4 8 2}Fieller, E. C. 1954. Some problems in interval estimation. {it:Journal of the Royal Statistical Society, Series B} 16: 175-185.{p_end}
{p 4 8 2}Kapetanios, G., M. H. Pesaran and T. Yamagata. 2011. Panels with non-stationary multifactor error structures. {it:Journal of Econometrics} 160: 326-348.{p_end}
{p 4 8 2}Lind, J. T. and H. Mehlum. 2010. With or without U? The appropriate test for a U-shaped relationship. {it:Oxford Bulletin of Economics and Statistics} 72: 109-118.{p_end}
{p 4 8 2}Greene, W. H. 2000. {it:Econometric Analysis}. 4th ed. Upper Saddle River, NJ: Prentice Hall.{p_end}
{p 4 8 2}Maddala, G. S. and S. Wu. 1999. A comparative study of unit root tests with panel data and a new simple test. {it:Oxford Bulletin of Economics and Statistics} 61: 631-652.{p_end}
{p 4 8 2}Mundlak, Y. 1978. On the pooling of time series and cross section data. {it:Econometrica} 46: 69-85.{p_end}
{p 4 8 2}Windmeijer, F. 2005. A finite sample correction for the variance of linear efficient two-step GMM estimators. {it:Journal of Econometrics} 126: 25-51.{p_end}
{p 4 8 2}Wooldridge, J. M. 2002. {it:Econometric Analysis of Cross Section and Panel Data}. Cambridge, MA: MIT Press.{p_end}
{p 4 8 2}Pesaran, M. H. 2004. General diagnostic tests for cross section dependence in panels. Cambridge Working Papers in Economics 0435.{p_end}
{p 4 8 2}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels. {it:Econometric Reviews} 34: 1089-1117.{p_end}
{p 4 8 2}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}
{p 4 8 2}Pesaran, M. H. and R. Smith. 1995. Estimating long-run relationships from dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.{p_end}
{p 4 8 2}Sasabuchi, S. 1980. A test of a multivariate normal mean with composite hypotheses determined by linear inequalities. {it:Biometrika} 67: 429-439.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}
