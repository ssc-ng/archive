{smcl}
{* *! version 1.0.0  09nov2026}{...}
{title:Title}

{p 4 8 2}
{bf:tsrobdiag} {hline 2} Normality and parameter-stability tests for serially correlated time series


{title:Commands in the package}

{p 4 8 2}{helpb tsnormal} {hline 2} normality tests for a series or for regression residuals that remain
valid under serial correlation: Bai and Ng (2005) skewness, kurtosis and joint tests with HAC variances,
the Lobato and Velasco (2004) test, and Anderson-Darling and Jarque-Bera tests with an AR-sieve
bootstrap under the Gaussian null; the classical Jarque-Bera test is shown for comparison.{p_end}

{p 4 8 2}{helpb hansenstab} {hline 2} Nyblom (1989) and Hansen (1992) tests of parameter stability in a
linear regression, for each coefficient, the coefficients jointly and all parameters including the error
variance, with iid or HAC (Bartlett, quadratic-spectral) variances, exact asymptotic p-values for any
number of parameters, and wild or dependent wild bootstrap p-values.{p_end}


{title:Why these tests}

{p 4 4 2}
The Jarque-Bera test and the textbook Hansen test assume independent observations or serially
uncorrelated errors. In simulations reported in the accompanying article, with AR(1) dependence the
Jarque-Bera test rejected a true null in up to 23% of samples at the 5% level and the textbook Hansen
test in up to 93%, while the Lobato-Velasco test, the sieve bootstrap and the HAC versions of the
Hansen test stayed close to the nominal level.{p_end}


{title:Examples}

{p 4 4 2}Wooldridge's data through {cmd:bcuse} ({cmd:ssc install bcuse}):{p_end}
{phang2}{cmd:. bcuse nyse, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tsnormal return, boot(999) seed(20261025)}{p_end}
{phang2}{cmd:. bcuse intdef, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. regress i3 inf def}{p_end}
{phang2}{cmd:. hansenstab, kernel(qs)}{p_end}

{p 4 4 2}The file {cmd:tsrobdiag_example.do}, installed with the package, runs all the examples.{p_end}


{title:References}

{p 4 8 2}Bai, J., and S. Ng. 2005. Tests for skewness, kurtosis, and normality for time series data.
{it:Journal of Business and Economic Statistics} 23: 49-60.{p_end}
{p 4 8 2}Hansen, B. E. 1992. Testing for parameter instability in linear models.
{it:Journal of Policy Modeling} 14: 517-533.{p_end}
{p 4 8 2}Lobato, I. N., and C. Velasco. 2004. A simple test of normality for time series.
{it:Econometric Theory} 20: 671-689.{p_end}
{p 4 8 2}Nyblom, J. 1989. Testing for the constancy of parameters over time.
{it:Journal of the American Statistical Association} 84: 223-230.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University,
Malete, Nigeria. yusuf.yusuf@kwasu.edu.ng{p_end}


{title:Also see}

{p 4 4 2}{helpb tsnormal}, {helpb hansenstab}{p_end}
