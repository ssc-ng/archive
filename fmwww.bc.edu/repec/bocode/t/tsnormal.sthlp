{smcl}
{* *! version 1.0.0  21oct2026}{...}
{viewerjumpto "Syntax" "tsnormal##syntax"}{...}
{viewerjumpto "Description" "tsnormal##description"}{...}
{viewerjumpto "Options" "tsnormal##options"}{...}
{viewerjumpto "Remarks" "tsnormal##remarks"}{...}
{viewerjumpto "Stored results" "tsnormal##results"}{...}
{viewerjumpto "Examples" "tsnormal##examples"}{...}
{viewerjumpto "References" "tsnormal##references"}{...}
{title:Title}

{p 4 8 2}
{bf:tsnormal} {hline 2} Normality tests for time series and regression residuals that remain
valid under serial correlation


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}Test one or more series

{p 8 16 2}
{cmd:tsnormal} {varlist} {ifin} [{cmd:,} {it:options}]

{p 4 8 2}Test the residuals of the last estimation ({helpb regress}, {helpb arima}, {helpb ardl},
{helpb newey}, ...)

{p 8 16 2}
{cmd:tsnormal} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ker:nel(name)}}kernel of the long-run variance in the Bai-Ng tests: {cmd:qs} (quadratic spectral,
default) or {cmd:bartlett}{p_end}
{synopt:{opt bw(#)}}bandwidth; default: Andrews (1991) AR(1) plug-in, computed separately for each
moment{p_end}
{synopt:{opt boot(#)}}number of AR-sieve bootstrap replications for the Anderson-Darling and Jarque-Bera
tests; default {cmd:0} (no bootstrap); 499 or 999 recommended{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synopt:{opt pmax(#)}}largest AR order considered by AIC for the sieve; default min(10 log10 T, T/4){p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb tsset} (one time series, no panel variable), and the sample must be a run
of consecutive periods. {it:varlist} may contain time-series operators. At least 20 observations
are required.


{marker description}{...}
{title:Description}

{p 4 4 2}
Classical normality tests, such as the Jarque-Bera test, {helpb sktest} and {helpb swilk}, assume
independent observations. With serially correlated data their variance formulas are wrong, and
they over-reject a true null of normality, increasingly so as persistence rises. {cmd:tsnormal}
reports tests that allow for serial correlation:

{p 8 12 2}
1. the {bf:Bai and Ng (2005)} tests of zero skewness (pi3), of kurtosis equal to 3 (pi4), and the
joint test, which standardize the sample skewness and kurtosis with heteroskedasticity- and
autocorrelation-consistent (HAC) variances. The skewness test is a test of symmetry and does not
require normality under the null;

{p 8 12 2}
2. the {bf:Lobato and Velasco (2004)} test G, which replaces the variances of the Jarque-Bera
statistic by consistent estimates of their values for a Gaussian process with the sample
autocovariances, without a bandwidth, with its skewness and kurtosis components;

{p 8 12 2}
3. with {opt boot(#)}, the {bf:Anderson-Darling} and {bf:Jarque-Bera} statistics with p-values from an
AR-sieve bootstrap that imposes the Gaussian null: an AR(p) chosen by AIC is fitted to the series,
and bootstrap series are generated from it with Gaussian innovations, in the spirit of
Psaradakis and Vavra (2017);

{p 8 12 2}
4. the classical Jarque-Bera test, for comparison.

{p 4 4 2}
Without a {it:varlist}, {cmd:tsnormal} tests the residuals of the last estimation command (obtained
with {cmd:predict, residuals}) over the estimation sample.


{marker options}{...}
{title:Options}

{phang}{opt kernel(name)} and {opt bw(#)} set the long-run variance of the Bai-Ng tests. The
default, the quadratic-spectral kernel with the Andrews (1991) AR(1) plug-in bandwidth, follows
Bai and Ng (2005). {cmd:bw(0)} gives the iid variance.

{phang}{opt boot(#)} requests the sieve bootstrap. Each replication simulates an AR(p) series of the
same length with Gaussian innovations and the estimated coefficients and innovation variance (the
coefficients are shrunk towards zero if the fitted AR is not stationary), and recomputes the
statistics.

{phang}{opt seed(#)} sets the random-number seed, for reproducible bootstrap p-values.

{phang}{opt pmax(#)} sets the largest AR order of the sieve.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Which test to read.} In the simulations reported in the accompanying article, the
Lobato-Velasco test and the sieve bootstrap tests kept their size close to 5% for AR(1) series with
coefficients up to 0.8 and 100 to 500 observations (Lobato-Velasco 1.9-4.8%, sieve bootstrap
3.8-6.9% at the 5% level), whereas the Jarque-Bera test rejected a true null in up to 23% of
samples. The Bai-Ng skewness test rejected in 4.5-7.4% of samples. The Bai-Ng kurtosis test, and
therefore the joint test, over-rejected (9-22%) even with 500 observations, as the sampling
distribution of the kurtosis is skewed; use them only with long series.

{p 4 4 2}
{bf:Volatility clustering.} The Lobato-Velasco test and the sieve bootstrap approximate the null by
a linear Gaussian process. Series with conditional heteroskedasticity (GARCH-type volatility
clustering, as in asset returns) are not linear processes even when their marginal distribution is
normal, and these tests can then reject because of the dependence in the squares. The Bai-Ng
tests allow for such dependence through the HAC variance of the higher moments.

{p 4 4 2}
{bf:Residuals.} The tests can be applied to regression residuals when the model includes a
constant. The simulations in the article cover a static regression with autocorrelated regressor
and errors.

{p 4 4 2}
{bf:Power.} Tests that allow for serial correlation have less power than the Jarque-Bera test in
iid data, and all normality tests have little power in short series. A non-rejection is not
evidence of normality.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:tsnormal} stores the following in {cmd:r()} (scalars refer to the last series tested):

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(skew)}, {cmd:r(kurt)}}sample skewness and kurtosis{p_end}
{synopt:{cmd:r(pi3)}, {cmd:r(p_pi3)}}Bai-Ng skewness statistic and p-value{p_end}
{synopt:{cmd:r(pi4)}, {cmd:r(p_pi4)}}Bai-Ng kurtosis statistic and p-value{p_end}
{synopt:{cmd:r(bn)}, {cmd:r(p_bn)}}Bai-Ng joint statistic and p-value{p_end}
{synopt:{cmd:r(lv)}, {cmd:r(p_lv)}}Lobato-Velasco G and p-value{p_end}
{synopt:{cmd:r(lv3)}, {cmd:r(lv4)}}skewness and kurtosis components of G (p-values {cmd:r(p_lv3)},
{cmd:r(p_lv4)}){p_end}
{synopt:{cmd:r(jb)}, {cmd:r(p_jb)}}Jarque-Bera statistic and asymptotic p-value{p_end}
{synopt:{cmd:r(ad)}}Anderson-Darling statistic{p_end}
{synopt:{cmd:r(p_ad)}, {cmd:r(p_jbboot)}}sieve-bootstrap p-values (with {cmd:boot()}){p_end}
{synopt:{cmd:r(arp)}}AR order of the sieve{p_end}
{synopt:{cmd:r(bw3)}, {cmd:r(bw4)}}bandwidths for the skewness and kurtosis variances{p_end}
{synopt:{cmd:r(boot)}}number of bootstrap replications{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(kernel)}}kernel{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}one row per series, all statistics{p_end}


{marker examples}{...}
{title:Examples}

{p 4 4 2}Weekly NYSE returns (Wooldridge's {cmd:nyse} data; {cmd:ssc install bcuse}):{p_end}
{phang2}{cmd:. bcuse nyse, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tsnormal return, boot(999) seed(20261025)}{p_end}

{p 4 4 2}Residuals of a regression:{p_end}
{phang2}{cmd:. regress return L.return}{p_end}
{phang2}{cmd:. tsnormal, boot(999) seed(20261025)}{p_end}

{p 4 4 2}Several series:{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsnormal dln_inv dln_inc dln_consump}{p_end}

{p 4 4 2}More examples are in {cmd:tsnormal_example.do}.


{marker references}{...}
{title:References}

{p 4 8 2}Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix
estimation. {it:Econometrica} 59: 817-858.{p_end}
{p 4 8 2}Anderson, T. W. and D. A. Darling. 1954. A test of goodness of fit.
{it:Journal of the American Statistical Association} 49: 765-769.{p_end}
{p 4 8 2}Bai, J. and S. Ng. 2005. Tests for skewness, kurtosis, and normality for time series data.
{it:Journal of Business and Economic Statistics} 23: 49-60.{p_end}
{p 4 8 2}Jarque, C. M. and A. K. Bera. 1987. A test for normality of observations and regression residuals.
{it:International Statistical Review} 55: 163-172.{p_end}
{p 4 8 2}Lobato, I. N. and C. Velasco. 2004. A simple test of normality for time series.
{it:Econometric Theory} 20: 671-689.{p_end}
{p 4 8 2}Psaradakis, Z. and M. Vavra. 2017. A distance test of normality for a wide class of stationary
processes. {it:Econometrics and Statistics} 2: 50-60.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb hansenstab} (same package), {helpb sktest}, {helpb swilk},
{helpb regress postestimation time series}{p_end}
