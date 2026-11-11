{smcl}
{* *! version 1.1.0  10nov2026}{...}
{viewerjumpto "Syntax" "hdhettest##syntax"}{...}
{viewerjumpto "Description" "hdhettest##description"}{...}
{viewerjumpto "Options" "hdhettest##options"}{...}
{viewerjumpto "Remarks" "hdhettest##remarks"}{...}
{viewerjumpto "Stored results" "hdhettest##results"}{...}
{viewerjumpto "Examples" "hdhettest##examples"}{...}
{viewerjumpto "References" "hdhettest##references"}{...}
{title:Title}

{p 4 8 2}
{bf:hdhettest} {hline 2} Heteroskedasticity tests with exact Monte Carlo p-values for linear
regressions with many regressors


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}After {helpb regress}

{p 8 16 2}
{cmd:hdhettest} [{cmd:,} {it:options}]

{p 4 8 2}Standalone

{p 8 16 2}
{cmd:hdhettest} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt r:eps(#)}}Monte Carlo draws; default {cmd:999}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt rob:ust}}draw Student-t errors with the estimated excess kurtosis instead of Gaussian
errors{p_end}
{synopt:{opt nom:oments}}skip the exact null moments of the CVT (saves time when n is very large){p_end}
{synopt:{opth ind:icators(varlist)}}also report the Koenker test on these variables{p_end}
{synopt:{opt sq:uares}}also report the Koenker test on the regressors and their squares{p_end}
{synopt:{opt white}}also report the Koenker test on the regressors, their squares and cross-products{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
{it:indepvars} may contain factor variables and time-series operators. The model must include a
constant. Weights are not allowed.


{marker description}{...}
{title:Description}

{p 4 4 2}
The Breusch-Pagan and White tests rely on asymptotics with a fixed number of regressors p. When
p is a sizeable fraction of n, as with many indicator variables or fixed effects, they lose their
nominal size (the Koenker version of the Breusch-Pagan test becomes very conservative) and the
White test cannot be computed. {cmd:hdhettest} reports:

{p 8 12 2}
1. the {bf:coefficient-of-variation test (CVT)} of the squared residuals,
CVT = mean((e_i^2 - mean(e^2))^2)/mean(e^2)^2, proposed for high-dimensional regressions by
Li and Yao (2019) and Bai, Pan and Yin (2018); its asymptotic p-value uses the exact mean and
variance of the statistic for the design at hand under Gaussian errors;

{p 8 12 2}
2. the {bf:approximate likelihood-ratio test (ALRT)} of Li and Yao (2019),
ln mean(e^2) - mean(ln e^2), the log ratio of the arithmetic and geometric means of the squared
residuals;

{p 8 12 2}
3. the {bf:Koenker (1981)} studentized Breusch-Pagan test, n R^2 of e^2 on all regressors, and on
the fitted values;

{p 8 12 2}
4. the {bf:Jarque-Bera} test, as a pre-test of the Gaussian errors that the CVT and ALRT rely on;

{p 8 12 2}
5. optionally, the Koenker test against chosen indicator variables: variables named in
{opt indicators()}, the regressors and their squares ({opt squares}), or the regressors, their
squares and cross-products ({opt white}, the indicator set of White 1980). After OLS, with
exogenous regressors, the Pagan and Hall (1983) statistic has the same limiting distribution as
this statistic for the same indicators; after instrumental-variables estimation use
{helpb ivhettest} (Baum, Schaffer and Stillman 2003) if installed.

{p 4 4 2}
Each statistic depends on the residuals only through their direction. Under homoskedastic Gaussian
errors with the regressors held fixed, its distribution is therefore known for the given design,
and drawing {opt reps()} error vectors gives Monte Carlo p-values with exact size for any n and p
(Dufour et al. 1998, 2004).


{marker options}{...}
{title:Options}

{phang}{opt reps(#)} sets the number of Monte Carlo draws. The smallest attainable p-value is
1/(reps + 1).

{phang}{opt seed(#)} sets the random-number seed.

{phang}{opt robust} draws the errors from a Student t distribution whose excess kurtosis equals an
unbiased moment estimate from the residuals; with nonpositive estimated excess kurtosis, Gaussian
errors are used. This protects the Koenker test against heavy tails; the CVT becomes
conservative and the ALRT remains invalid under non-normal errors.

{phang}{opt nomoments} skips the exact null mean and variance of the CVT, which needs O(n^2 p)
operations.

{phang}{opth indicators(varlist)} adds the Koenker test, n R^2 of e^2 on a constant and the
variables in {it:varlist}, with an asymptotic chi-squared p-value and an exact Monte Carlo
p-value. The variables may be any exogenous variables, including variables not in the model, but
not the dependent variable. Factor variables and time-series operators are allowed.

{phang}{opt squares} adds the Koenker test on the regressors and their squares.

{phang}{opt white} adds the Koenker test on the regressors, their squares and their
cross-products; its statistic equals that of {cmd:estat imtest, white}. With k regressors this
uses k + k(k + 1)/2 indicators, which must be fewer than n - 4. Indicators that duplicate others
(such as the square of a 0/1 variable) are dropped. Only one of {opt indicators()}, {opt squares}
and {opt white} may be given.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Simulations.} In the accompanying article (n = 100 and 400, p/n = 0.1 to 0.5, Gaussian and
skewed designs with high-leverage dummies, 2,000 replications), all Monte Carlo tests rejected a
true null in 3.6-5.7% of samples at the 5% level under Gaussian errors. The asymptotic Koenker test
rejected in 0.2-2.4% of samples when p/n was 0.3 or more, and lost power accordingly.

{p 4 4 2}
{bf:Non-normal errors.} The CVT and ALRT measure the dispersion of the squared residuals, which
heavy tails raise as much as heteroskedasticity does. With homoskedastic t(5), Laplace or skewed
errors they rejected in most samples. Read them together with the Jarque-Bera pre-test: when
normality is rejected, rely on the Koenker test, whose Monte Carlo p-value rejected a true null in
3.2-8.0% of samples with these errors (3.3-7.7% with {opt robust}).

{p 4 4 2}
{bf:Leverage-one observations.} Observations fitted exactly (for example the only observation in a
category of a factor variable) have zero residuals whatever the errors; they are excluded from the
statistics and counted in the output.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:hdhettest} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(p)}}number of parameters{p_end}
{synopt:{cmd:r(ratio)}}p/n{p_end}
{synopt:{cmd:r(}{it:test}{cmd:)}}statistic; {it:test} is {cmd:cvt}, {cmd:alrt}, {cmd:koenker},
{cmd:koenker_fitted}, {cmd:jb}, or {cmd:koenker_ind} (with {opt indicators()}, {opt squares} or
{opt white}){p_end}
{synopt:{cmd:r(p_}{it:test}{cmd:)}}Monte Carlo p-value{p_end}
{synopt:{cmd:r(p_}{it:test}{cmd:_asy)}}asymptotic p-value{p_end}
{synopt:{cmd:r(nu4)}, {cmd:r(df_t)}}estimated excess kurtosis and t degrees of freedom ({opt robust}){p_end}
{synopt:{cmd:r(reps)}}draws{p_end}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables{p_end}
{synopt:{cmd:r(errors)}}error distribution of the draws{p_end}
{synopt:{cmd:r(indicators)}}indicator variables of the added Koenker test{p_end}
{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}statistic, df, asymptotic and Monte Carlo p-values{p_end}


{marker examples}{...}
{title:Examples}

{p 4 4 2}Wage equation (Wooldridge's {cmd:wage1} data; {cmd:ssc install bcuse}):{p_end}
{phang2}{cmd:. bcuse wage1, clear}{p_end}
{phang2}{cmd:. regress lwage educ exper expersq tenure tenursq nonwhite female married numdep smsa ///}{p_end}
{phang3}{cmd:northcen south west construc ndurman trcommpu trade services profserv profocc clerocc servocc}{p_end}
{phang2}{cmd:. hdhettest, seed(20261025)}{p_end}

{p 4 4 2}Many indicator regressors:{p_end}
{phang2}{cmd:. regress lwage i.educ i.exper i.tenure i.numdep ///}{p_end}
{phang3}{cmd:i.female##(i.married i.nonwhite i.construc i.ndurman i.trcommpu i.trade i.services ///}{p_end}
{phang3}{cmd:i.profserv i.profocc i.clerocc i.servocc) smsa northcen south west}{p_end}
{phang2}{cmd:. hdhettest, seed(20261025)}{p_end}
{phang2}{cmd:. hdhettest, seed(20261025) robust}{p_end}

{p 4 4 2}Koenker tests on chosen indicators (first wage equation):{p_end}
{phang2}{cmd:. regress lwage educ exper tenure female married nonwhite smsa}{p_end}
{phang2}{cmd:. hdhettest, white seed(20261025)}{p_end}
{phang2}{cmd:. hdhettest, indicators(educ exper tenure) seed(20261025)}{p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Bai, Z., G. Pan, and Y. Yin. 2018. A central limit theorem for sums of functions of residuals in a
high-dimensional regression model with an application to variance homoscedasticity test. {it:TEST} 27:
896-920. doi:10.1007/s11749-017-0575-x.{p_end}
{p 4 8 2}Baum, C. F., M. E. Schaffer, and S. Stillman. 2003. Instrumental variables and GMM: Estimation and
testing. {it:Stata Journal} 3: 1-31.{p_end}
{p 4 8 2}Dufour, J.-M., A. Farhat, L. Gardiol, and L. Khalaf. 1998. Simulation-based finite sample normality
tests in linear regressions. {it:Econometrics Journal} 1: C154-C173.{p_end}
{p 4 8 2}Dufour, J.-M., L. Khalaf, J.-T. Bernard, and I. Genest. 2004. Simulation-based finite-sample tests
for heteroskedasticity and ARCH effects. {it:Journal of Econometrics} 122: 317-347.{p_end}
{p 4 8 2}Koenker, R. 1981. A note on studentizing a test for heteroscedasticity. {it:Journal of Econometrics}
17: 107-112.{p_end}
{p 4 8 2}Li, Z., and J. Yao. 2019. Testing for heteroscedasticity in high-dimensional regressions.
{it:Econometrics and Statistics} 9: 122-139.{p_end}
{p 4 8 2}Pagan, A. R., and D. Hall. 1983. Diagnostic tests as residual analysis. {it:Econometric Reviews}
2: 159-218.{p_end}
{p 4 8 2}White, H. 1980. A heteroskedasticity-consistent covariance matrix estimator and a direct test
for heteroskedasticity. {it:Econometrica} 48: 817-838.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb regress postestimation}, {helpb ivhettest} (if installed){p_end}
