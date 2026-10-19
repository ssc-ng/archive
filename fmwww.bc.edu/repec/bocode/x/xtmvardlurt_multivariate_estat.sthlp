{smcl}
{* *! version 1.0.6  11oct2026}{...}
{title:Title}

{p 4 8 2}
{bf:estat} after {cmd:xtmvardlurt_multivariate} {hline 2} Post-estimation tools for the panel multivariate ARDL unit root / cointegration test

{title:Syntax}

{p 8 15 2}{cmd:estat} {opt dia:gnostics} [{cmd:,} {opt all}]{p_end}
{p 8 15 2}{cmd:estat} {opt pan:eltests}{p_end}
{p 8 15 2}{cmd:estat} {opt col:linearity} [{cmd:,} {opt all}]{p_end}
{p 8 15 2}{cmd:estat} {opt cas:es} [{cmd:,} {opt nolist}]{p_end}
{p 8 15 2}{cmd:estat} {opt lag:s}{p_end}
{p 8 15 2}{cmd:estat} {opt unitd:ata} {cmd:,} {c -(}{opt sav:ing(filename)} [{opt replace}] | {opt clear}{c )-}{p_end}

{p 4 4 2}
Graphs are drawn with {cmd:xtmvardlurt_multivariate_graph}.

{title:Description}

{p 4 8 2}
{cmd:estat diagnostics} reports (1) the Pesaran (2004) CD test for cross-sectional dependence
and which bootstrap was used; (2) for every unit, the Breusch-Godfrey (order 1) p-value of the
ARDL residuals, the number of parameters and the observations per parameter, with a count of the units that reject
at 5% and a binomial p-value for that count; (3) the share of units rejecting five further residual tests,
which are also stored in {cmd:e(diag)}: Breusch-Godfrey of order 2, Jarque-Bera (normality), Breusch-Pagan/Koenker
(heteroskedasticity), ARCH(1) and Ramsey RESET; (4) a collinearity line: a warning when the VIF among the stationary regressors exceeds 10 in any unit (details in {cmd:estat collinearity}); (5) a plain reading, for example whether more lags are needed.
Option {opt all} lists every unit when there are more than 40.

{p 4 8 2}
Which tests matter. The bootstrap relies on serially uncorrelated residuals, so the serial-correlation tests are the ones
to act on. In simulations, heavy-tailed errors, a variance break and ARCH(1) errors did not distort the size of the
bootstrap tests, so Jarque-Bera, Breusch-Pagan and ARCH are shown for information only. RESET can point to omitted terms.

{p 4 8 2}
Structural breaks are not tested. A level shift in y appears as one spike in the differenced ARDL equation, so
residual-based stability tests such as CUSUM have no power there (a CUSUM test rejected in 0% of units in
simulations with a large level shift), and a level shift can also produce false F-test rejections.
Check each series for breaks (for example with a Zivot-Andrews or Lee-Strazicich test) and, if there is one, treat
the F-based and cointegration conclusions with care.

{p 4 8 2}
{cmd:estat paneltests} reports three panel-level residual tests. (1) Serial correlation: the Breusch-Godfrey tests of
order 1 and 2 are computed unit by unit and their p-values are combined, by the Fisher statistic -2*sum(ln p) (chi2 with 2N
degrees of freedom) and by the inverse-normal statistic sum(invnormal(p))/sqrt(N) (rejects for large negative values).
(2) Normality: a Jarque-Bera test on the residuals of all units pooled after standardising each unit (skewness and
kurtosis are averaged with weights equal to the unit sizes), and the Fisher and inverse-normal combinations of the unit
Jarque-Bera p-values. (3) Heteroskedasticity: the same two combinations for the Breusch-Pagan/Koenker and ARCH(1) tests,
and Bartlett's test that the residual variance is the same in every unit.
The combined tests assume that the units are independent. With cross-sectional dependence (see the CD test) they
over-reject, so they are a guide, not exact tests. As in {cmd:estat diagnostics}, only serial correlation matters for the
bootstrap; the Bartlett test is sensitive to non-normality, and different residual variances across units are expected.

{p 4 8 2}
{cmd:estat collinearity} reports variance inflation factors (VIF) of the lagged-level regressors (L.y and L.x for each
covariate) and the largest VIF among the stationary regressors (lags of D.y and D.x, and contemporaneous D.x), for each
unit, with the mean, the maximum and the number of units above 10 for each; and the condition number of the design
matrix with unit-length columns (Belsley), with the number of units above 30. The lagged levels of I(1) series share
stochastic trends, so large VIFs among them are usual. The VIF of the stationary regressors is the better sign of trouble. The statistics are also in {cmd:e(pdiag)}. In simulations with correlation 0.9 and 0.99
between the covariate innovations (N = 10, T = 40, 1000 replications), size stayed at 2-5%. The t-side lost no power. The F-side lost power with
3 covariates (about 50% without correlation, 36-38% at 0.9 and 33-34% at 0.99) but not with 6 covariates (26-33% without, 29-35% with).
In those designs the VIF of the stationary regressors was above 10 in about 90% of the units at correlation 0.9 with 3 covariates and in all units at 0.99;
without correlation it was above 10 in under 1% of units. Collinearity among covariates therefore threatens power and precision, not the size. The estimation output and {cmd:estat diagnostics}
warn when the VIF of the stationary regressors exceeds 10 in any unit. The condition number does not trigger the warning: it includes the
lagged levels of I(1) series and the constant, so it is above 30 in most panels without any problem for the test.

{p 4 8 2}
{cmd:estat cases} counts the units in each of the four cases (I neither test rejects, II t only, III F only,
IV both) at the level used in the estimation and lists the unit identifiers of each case.

{p 4 8 2}
{cmd:estat lags} tabulates the lags p (of D.y) and q (of D.x) used by the units, with their means.

{p 4 8 2}
{cmd:estat unitdata} puts the unit-level results (unit, T, p, q, t_stat, F_stat, p_t, p_F, case, bg_p, case_label)
in a dataset, saved with {opt saving()} or left in memory with {opt clear}, so that a table can be built for a paper.

{title:Methods and references}

{p 4 4 2}
None of the residual tests is new. They are standard tests applied to the residuals of each unit's ARDL regression and,
in {cmd:estat paneltests}, combined across units. The package contributes the implementation, the ranking of the tests
by what matters for the bootstrap (serial correlation), and the simulation evidence for that ranking; it does not claim a
new test. Sources, to be checked against the originals before citing:

{p 4 8 2}Serial correlation: Breusch (1978); Godfrey (1978) {hline 2} LM test on the residuals, orders 1 and 2.{p_end}
{p 4 8 2}Normality: Jarque and Bera (1980) {hline 2} skewness and kurtosis of the residuals.
The pooled version (skewness and kurtosis averaged over units after standardising each unit, weights equal to unit
size) is a simple construction of this package, not a published test.{p_end}
{p 4 8 2}Heteroskedasticity: Breusch and Pagan (1979) in the studentised form of Koenker (1981); Engle (1982) for ARCH(1);
Bartlett (1937) for equality of the residual variance across units.{p_end}
{p 4 8 2}Misspecification: Ramsey (1969) RESET, squares and cubes of the fitted values.{p_end}
{p 4 8 2}Combining unit p-values: Fisher (1932) chi-squared statistic, as used for panel unit root tests by Maddala and Wu (1999); inverse-normal statistic of
Choi (2001). Both assume independent units.{p_end}
{p 4 8 2}Cross-sectional dependence: Pesaran (2004) CD test.{p_end}
{p 4 8 2}Collinearity: variance inflation factors (the diagonal of the inverse correlation matrix of the regressors); condition number of the
design matrix with unit-length columns, Belsley, Kuh and Welsch (1980).{p_end}

{p 4 8 2}Bartlett, M. S. (1937). Properties of sufficiency and statistical tests. {it:Proceedings of the Royal Society A} 160.{p_end}
{p 4 8 2}Belsley, D. A., Kuh, E. and Welsch, R. E. (1980). {it:Regression Diagnostics}. Wiley.{p_end}
{p 4 8 2}Breusch, T. S. (1978). Testing for autocorrelation in dynamic linear models. {it:Australian Economic Papers} 17.{p_end}
{p 4 8 2}Breusch, T. S. and Pagan, A. R. (1979). A simple test for heteroscedasticity and random coefficient variation. {it:Econometrica} 47.{p_end}
{p 4 8 2}Choi, I. (2001). Unit root tests for panel data. {it:Journal of International Money and Finance} 20.{p_end}
{p 4 8 2}Engle, R. F. (1982). Autoregressive conditional heteroscedasticity. {it:Econometrica} 50.{p_end}
{p 4 8 2}Fisher, R. A. (1932). {it:Statistical Methods for Research Workers}. Oliver and Boyd.{p_end}
{p 4 8 2}Godfrey, L. G. (1978). Testing against general autoregressive and moving average error models when the regressors include lagged dependent variables. {it:Econometrica} 46.{p_end}
{p 4 8 2}Jarque, C. M. and Bera, A. K. (1980). Efficient tests for normality, homoscedasticity and serial independence of regression residuals. {it:Economics Letters} 6.{p_end}
{p 4 8 2}Koenker, R. (1981). A note on studentizing a test for heteroscedasticity. {it:Journal of Econometrics} 17.{p_end}
{p 4 8 2}Maddala, G. S. and Wu, S. (1999). A comparative study of unit root tests with panel data and a new simple test. {it:Oxford Bulletin of Economics and Statistics} 61.{p_end}
{p 4 8 2}Pesaran, M. H. (2004). General diagnostic tests for cross section dependence in panels. Cambridge Working Papers in Economics 0435.{p_end}
{p 4 8 2}Ramsey, J. B. (1969). Tests for specification errors in classical linear least-squares regression analysis. {it:Journal of the Royal Statistical Society B} 31.{p_end}

{title:Why the residual check matters}

{p 4 4 2}
The bootstrap resamples residuals as if they were serially uncorrelated. Too few lags leave serial correlation
in the residuals and make the bootstrap p-values unreliable, whatever the sample size; a small number of
observations per parameter is a much weaker warning sign. With T below 35 the Breusch-Godfrey test over-rejects,
so use its flags to compare lag choices rather than as a verdict.

{title:Stored results}

{p 4 8 2}{cmd:estat diagnostics}: {cmd:r(vif_n)}, {cmd:r(vif_max)}, {cmd:r(CD)}, {cmd:r(CD_p)}, {cmd:r(bg_n)}, {cmd:r(bg_share)}, {cmd:r(bg_binom_p)}, {cmd:r(min_ratio)}.{p_end}
{p 4 8 2}{cmd:estat paneltests}: {cmd:r(bg1_F)}, {cmd:r(bg1_pF)}, {cmd:r(bg1_Z)}, {cmd:r(bg1_pZ)} (and {cmd:bg2_}...), {cmd:r(jb_pooled)}, {cmd:r(jb_pooled_p)}, {cmd:r(skew)}, {cmd:r(kurt)}, {cmd:r(jb_F)}...{cmd:r(jb_pZ)}, {cmd:r(bp_F)}...{cmd:r(bp_pZ)}, {cmd:r(arch_F)}...{cmd:r(arch_pZ)}, {cmd:r(bartlett)}, {cmd:r(bartlett_p)}, {cmd:r(CD_p)}, {cmd:r(N)}.{p_end}
{p 4 8 2}{cmd:estat collinearity}: {cmd:r(vif_mean0)}, {cmd:r(vif_max0)} (L.y), {cmd:r(vif_mean}{it:j}{cmd:)}, {cmd:r(vif_max}{it:j}{cmd:)} (covariate {it:j}), {cmd:r(vif_stat_mean)}, {cmd:r(vif_stat_max)}, {cmd:r(vif_stat_n10)}, {cmd:r(cond_mean)}, {cmd:r(cond_max)}, {cmd:r(cond_n30)}, {cmd:r(N)}.{p_end}
{p 4 8 2}{cmd:estat cases}: {cmd:r(N)}, {cmd:r(n_case1)}-{cmd:r(n_case4)}, {cmd:r(share_case1)}-{cmd:r(share_case4)}.{p_end}
{p 4 8 2}{cmd:estat lags}: {cmd:r(mean_p)}, {cmd:r(mean_q)}, {cmd:r(max_p)}, {cmd:r(max_q)}.{p_end}

{title:Example}

{phang2}{cmd:. xtmvardlurt_multivariate y x1 x2 x3, fixlag(1 1) reps(999)}{p_end}
{phang2}{cmd:. estat diagnostics}{p_end}
{phang2}{cmd:. estat paneltests}{p_end}
{phang2}{cmd:. estat collinearity}{p_end}
{phang2}{cmd:. estat cases}{p_end}
{phang2}{cmd:. estat lags}{p_end}
{phang2}{cmd:. estat unitdata, saving(unit_results) replace}{p_end}

{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Kwara State University, yusuf.yusuf@kwasu.edu.ng{p_end}
