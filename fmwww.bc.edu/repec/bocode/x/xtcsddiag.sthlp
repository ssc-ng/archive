{smcl}
{* *! version 1.0.0  25oct2026}{...}
{viewerjumpto "Syntax" "xtcsddiag##syntax"}{...}
{viewerjumpto "Description" "xtcsddiag##description"}{...}
{viewerjumpto "Options" "xtcsddiag##options"}{...}
{viewerjumpto "Remarks" "xtcsddiag##remarks"}{...}
{viewerjumpto "Stored results" "xtcsddiag##results"}{...}
{viewerjumpto "Examples" "xtcsddiag##examples"}{...}
{viewerjumpto "References" "xtcsddiag##references"}{...}
{title:Title}

{p 4 8 2}
{bf:xtcsddiag} {hline 2} Residual diagnostics for heterogeneous panels with cross-sectional
dependence: serial correlation, heteroskedasticity, normality and parameter stability


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtcsddiag} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt est:imator(name)}}model whose residuals are tested: {cmd:cce} (default), {cmd:mg} or
{cmd:fe}{p_end}
{synopt:{opt l:ags(#)}}order of the Breusch-Godfrey test; default {cmd:1}{p_end}
{synopt:{opt r:eps(#)}}Monte Carlo draws for each unit p-value; default {cmd:999}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt gen:erate(newvar)}}save the residuals{p_end}
{synopt:{opt unit:s}}list the unit p-values{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb xtset}. Unbalanced panels are allowed, but the observations of each unit
must be consecutive periods. {it:depvar} and {it:indepvars} may contain time-series operators.


{marker description}{...}
{title:Description}

{p 4 4 2}
The residual tests in common use for panels (for example {cmd:xtserial}, {cmd:xttest3},
{cmd:xtqptest}) are built for fixed-effects models with homogeneous slopes and assume that the
units are independent. With common factors in the errors, as in most macro panels, they
over-reject, and they cannot be applied to the unit regressions of mean-group or common
correlated effects (CCE) estimators. {cmd:xtcsddiag} fits the model unit by unit, tests the
residuals of each unit, and combines the unit results:

{p 8 12 2}
1. {bf:Estimation.} {cmd:estimator(cce)} regresses each unit on its regressors and the
cross-section averages of the dependent and independent variables (Pesaran 2006), which remove
the common factors; {cmd:estimator(mg)} omits the averages (Pesaran and Smith 1995);
{cmd:estimator(fe)} fits the two-way fixed-effects model with common slopes.

{p 8 12 2}
2. {bf:Unit tests.} For each unit: the Breusch-Godfrey F test of serial correlation of order
{opt lags()}; the Koenker (1981) studentized test of heteroskedasticity on the unit's regressors;
the Jarque-Bera test of normality; the OLS-CUSUM test of Ploberger and Kraemer (1992); and the
joint Hansen (1992) test of the stability of the unit's coefficients.

{p 8 12 2}
3. {bf:Exact unit p-values.} With short unit series and many regressors (the CCE averages count
as regressors), the asymptotic distributions of these statistics are poor. Every statistic
depends on the residuals only through their direction, so under Gaussian errors with the
regressors held fixed its distribution is known: {cmd:xtcsddiag} draws {opt reps()} error vectors,
computes the residuals with the unit's design, and reports the Monte Carlo p-value
(1 + #{S* >= S})/(reps + 1), which has exact size for any T_i (Dufour et al. 1998, 2004). For
{cmd:fe} the draws use the pooled design and the estimated unit variances.

{p 8 12 2}
4. {bf:Panel tests.} The N unit p-values are combined by Fisher's method, -2 sum ln p_i ~ chi2(2N),
and by the inverse-normal method, sum invnorm(p_i)/sqrt(N) ~ N(0,1) (Choi 2001). The share of
units rejecting at 5% is also shown.

{p 8 12 2}
5. {bf:Remaining dependence.} The Pesaran (2015) CD test and the CDw test of Juodis and Reese (2022)
are applied to the residuals. The combined tests assume that the unit residuals are independent;
after CCE, CD is biased and CDw should be read instead. For more tests of cross-sectional
dependence, use {helpb xtcdmax} on the residuals saved with {opt generate()}.


{marker options}{...}
{title:Options}

{phang}{opt estimator(name)} chooses the model: {cmd:cce}, {cmd:mg} or {cmd:fe}. Each unit regression
under {cmd:cce} has 2 + 2k coefficients, k the number of regressors, plus the test's own
parameters; units with fewer than (number of coefficients) + {opt lags()} + 3 observations are
skipped.

{phang}{opt lags(#)} sets the order of the Breusch-Godfrey test.

{phang}{opt reps(#)} sets the number of Monte Carlo draws per unit. The smallest attainable unit
p-value is 1/(reps + 1). With 999 draws the p-values vary by about 0.01 between seeds.

{phang}{opt seed(#)} sets the random-number seed, for reproducible p-values; it also fixes the random
weights of CDw.

{phang}{opt generate(newvar)} saves the residuals of the chosen model.

{phang}{opt units} lists the five p-values of each unit.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Simulations.} In the accompanying article, with a serially correlated common factor in y and x,
N = 20 or 50 and T = 30 or 60, the combined tests on CCE residuals rejected a true null in
2.4-4.5% of samples at the 5% level. On mean-group residuals, which keep the factor, the CUSUM
and Hansen tests rejected in up to 56% of samples, and the Wooldridge test of {cmd:xtserial}
rejected in 36-80%: these tests detect the omitted factor, not a property of the idiosyncratic
errors. A break shared by all units is a common factor and is absorbed by the CCE averages;
breaks in the slopes are detected.

{p 4 4 2}
{bf:Interpretation.} A rejection by the combined tests says that the property fails in at least
some units. The share of units rejecting and option {opt units} show how many and which.
The Monte Carlo p-values assume Gaussian errors under the null; the Koenker test is studentized and
the serial-correlation and stability tests are robust to moderate departures, but the
Jarque-Bera test is a test of exactly that assumption.

{p 4 4 2}
{bf:Not covered.} Lagged dependent variables in the unit regressions make the regressors
stochastic; the Monte Carlo p-values are then approximate.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:xtcsddiag} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N_g)}}units tested{p_end}
{synopt:{cmd:r(N_all)}}units in the sample{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(T_min)}, {cmd:r(T_max)}}shortest and longest unit series tested{p_end}
{synopt:{cmd:r(p_}{it:test}{cmd:_fisher)}}Fisher p-value; {it:test} is {cmd:serial}, {cmd:hetero},
{cmd:normality}, {cmd:cusum} or {cmd:hansen}{p_end}
{synopt:{cmd:r(p_}{it:test}{cmd:_invnorm)}}inverse-normal p-value{p_end}
{synopt:{cmd:r(CD)}, {cmd:r(p_CD)}}Pesaran CD statistic and p-value{p_end}
{synopt:{cmd:r(CDw)}, {cmd:r(p_CDw)}}Juodis-Reese CDw statistic and p-value{p_end}
{synopt:{cmd:r(lags)}, {cmd:r(reps)}}options{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(estimator)}}{cmd:cce}, {cmd:mg} or {cmd:fe}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}combined tests: units, Fisher statistic and p-value, inverse-normal Z and p-value,
share rejecting{p_end}
{synopt:{cmd:r(units)}}unit id, T_i, five statistics and five Monte Carlo p-values{p_end}
{synopt:{cmd:r(cd)}}CD, CDw, number of pairs, mean |rho|{p_end}
{synopt:{cmd:r(b)}}mean of the unit slopes (common slopes for {cmd:fe}){p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use xtcsddiag_apec, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. generate lnEF = ln(EF)}{p_end}
{phang2}{cmd:. generate NET2 = NET^2}{p_end}
{phang2}{cmd:. xtcsddiag lnEF NET NET2 GLB, seed(20261025)}{p_end}
{phang2}{cmd:. xtcsddiag lnEF NET NET2 GLB, estimator(mg) seed(20261025) units}{p_end}
{phang2}{cmd:. xtcsddiag lnEF NET NET2 GLB, estimator(fe) seed(20261025) generate(e_fe)}{p_end}
{phang2}{cmd:. xtcdmax e_fe}{p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Choi, I. 2001. Unit root tests for panel data. {it:Journal of International Money and Finance} 20:
249-272.{p_end}
{p 4 8 2}Dufour, J.-M., A. Farhat, L. Gardiol, and L. Khalaf. 1998. Simulation-based finite sample normality
tests in linear regressions. {it:Econometrics Journal} 1: C154-C173.{p_end}
{p 4 8 2}Dufour, J.-M., L. Khalaf, J.-T. Bernard, and I. Genest. 2004. Simulation-based finite-sample tests
for heteroskedasticity and ARCH effects. {it:Journal of Econometrics} 122: 317-347.{p_end}
{p 4 8 2}Hansen, B. E. 1992. Testing for parameter instability in linear models.
{it:Journal of Policy Modeling} 14: 517-533.{p_end}
{p 4 8 2}Juodis, A., and S. Reese. 2022. The incidental parameters problem in testing for remaining
cross-section correlation. {it:Journal of Business and Economic Statistics} 40: 1191-1203.{p_end}
{p 4 8 2}Koenker, R. 1981. A note on studentizing a test for heteroscedasticity. {it:Journal of Econometrics}
17: 107-112.{p_end}
{p 4 8 2}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error
structure. {it:Econometrica} 74: 967-1012.{p_end}
{p 4 8 2}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} 34: 1089-1117.{p_end}
{p 4 8 2}Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships from dynamic heterogeneous
panels. {it:Journal of Econometrics} 68: 79-113.{p_end}
{p 4 8 2}Ploberger, W., and W. Kraemer. 1992. The CUSUM test with OLS residuals. {it:Econometrica} 60:
271-285.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb xtcdmax}, {helpb xtcollin} (same package){p_end}
