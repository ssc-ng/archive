{smcl}
{* *! version 1.0.0  25oct2026}{...}
{viewerjumpto "Syntax" "hansenstab##syntax"}{...}
{viewerjumpto "Description" "hansenstab##description"}{...}
{viewerjumpto "Options" "hansenstab##options"}{...}
{viewerjumpto "Remarks" "hansenstab##remarks"}{...}
{viewerjumpto "Stored results" "hansenstab##results"}{...}
{viewerjumpto "Examples" "hansenstab##examples"}{...}
{viewerjumpto "References" "hansenstab##references"}{...}
{title:Title}

{p 4 8 2}
{bf:hansenstab} {hline 2} Hansen (1992) and Nyblom (1989) tests for parameter stability in linear
regression, with HAC variances and exact asymptotic p-values


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}After {helpb regress}

{p 8 16 2}
{cmd:hansenstab} [{cmd:,} {it:options}]

{p 4 8 2}Standalone

{p 8 16 2}
{cmd:hansenstab} {depvar} {indepvars} {ifin} [{cmd:,} {cmdab:noc:onstant} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ker:nel(name)}}variance of the scores: {cmd:none} (iid, Hansen 1992; default), {cmd:bartlett} or
{cmd:qs} (HAC){p_end}
{synopt:{opt bw(#)}}HAC bandwidth; default: Andrews (1991) AR(1) plug-in, averaged over the scores{p_end}
{synopt:{opt nov:ariance}}leave the error variance out of the tests{p_end}
{synopt:{opt boot(#)}}bootstrap replications: wild bootstrap with {cmd:kernel(none)}, dependent wild bootstrap
otherwise; default {cmd:0}{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb tsset} (one time series), and the estimation sample must be a run of
consecutive periods. {it:indepvars} may contain factor variables and time-series operators.
Weights are not allowed.


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:hansenstab} tests whether the coefficients and the error variance of a linear regression
are constant over the sample against the alternative that they follow a martingale (a random
walk is the leading case). For each parameter it forms the cumulative sums S_t of the score
f_t (x_t e_t for a coefficient, e_t^2 - s^2 for the variance) and reports

{p 8 8 2}
L_i = (1/(T V_i)) sum_t S_it^2,

{p 4 4 2}
and the joint statistics L_b (all coefficients) and L_c (coefficients and variance),
L = (1/T) sum_t S_t' V^(-1) S_t, where V is the variance of the scores (Hansen 1992; Nyblom
1989). The tests need no break date and detect gradual as well as abrupt change.

{p 4 4 2}
The asymptotic null distribution of a statistic on m parameters is that of the integral over
[0,1] of B(r)'B(r), with B an m-dimensional Brownian bridge. Hansen tabulated a few quantiles of
it; {cmd:hansenstab} computes exact asymptotic p-values for any m by numerical inversion of the
characteristic function (Imhof 1961). With serially correlated errors the iid variance V is
wrong and the tests over-reject heavily; {opt kernel()} replaces it by a long-run (HAC)
variance.


{marker options}{...}
{title:Options}

{phang}{opt kernel(name)} sets the variance of the scores: {cmd:none}, the outer product of the
scores as in Hansen (1992), valid for serially uncorrelated errors; {cmd:bartlett} or {cmd:qs},
heteroskedasticity- and autocorrelation-consistent variances with the Bartlett or
quadratic-spectral kernel.

{phang}{opt bw(#)} sets the bandwidth of the HAC variance.

{phang}{opt novariance} omits the error variance from the individual and joint tests. By default
the variance is tested, and the joint test L_b of the coefficients is reported separately.

{phang}{opt boot(#)} adds bootstrap p-values from the fixed-regressor wild bootstrap (Rademacher
weights; Hansen 2000) or, with a HAC kernel, from the dependent wild bootstrap (Shao 2010) with
block length equal to the bandwidth plus one. Because the wild bootstrap keeps the size pattern of
the residuals, its p-value for the variance has no power and is shown only for completeness.

{phang}{opt seed(#)} sets the random-number seed.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{bf:Which variance.} In the simulations reported in the accompanying article (static regression
with an AR(1) regressor, 2,000 replications), the iid version rejected a true null in 36-42% of
samples when the errors were AR(1) with coefficient 0.5 and in 77-93% with 0.8. The Bartlett and
quadratic-spectral versions rejected in 2.0-8.0% of samples. Check residual autocorrelation before
reading the iid version, or use a HAC kernel by default.

{p 4 4 2}
{bf:Power.} The HAC versions lose power when the errors are persistent, as part of a slow
parameter change is absorbed by the long-run variance. A non-rejection is not evidence of
stability. For a single break at an unknown date, see also {helpb estat sbsingle}; for multiple
breaks, {cmd:xtbreak} (Ditzen, Karavias and Westerlund) works with time series too.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:hansenstab} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of coefficients{p_end}
{synopt:{cmd:r(Lc)}, {cmd:r(p_Lc)}}joint statistic for all parameters and asymptotic p-value{p_end}
{synopt:{cmd:r(Lb)}, {cmd:r(p_Lb)}}joint statistic for the coefficients and asymptotic p-value{p_end}
{synopt:{cmd:r(Lvar)}, {cmd:r(p_Lvar)}}statistic for the error variance and p-value{p_end}
{synopt:{cmd:r(pb_Lc)}, {cmd:r(pb_Lb)}}bootstrap p-values (with {cmd:boot()}){p_end}
{synopt:{cmd:r(bw)}}bandwidth{p_end}
{synopt:{cmd:r(boot)}}bootstrap replications{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(kernel)}}kernel{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}statistic, asymptotic and bootstrap p-values, one row per parameter and joint
test{p_end}
{synopt:{cmd:r(b)}}least-squares coefficients{p_end}


{marker examples}{...}
{title:Examples}

{p 4 4 2}Interest rates, inflation and deficits, 1948-2003 (Wooldridge's {cmd:intdef} data;
{cmd:ssc install bcuse}):{p_end}
{phang2}{cmd:. bcuse intdef, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. regress i3 inf def}{p_end}
{phang2}{cmd:. hansenstab}{p_end}
{phang2}{cmd:. hansenstab, kernel(qs)}{p_end}

{p 4 4 2}Expectations-augmented Phillips curve, standalone with bootstrap:{p_end}
{phang2}{cmd:. bcuse phillips, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. hansenstab cinf unem, boot(999) seed(20261025)}{p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix
estimation. {it:Econometrica} 59: 817-858.{p_end}
{p 4 8 2}Hansen, B. E. 1992. Testing for parameter instability in linear models.
{it:Journal of Policy Modeling} 14: 517-533.{p_end}
{p 4 8 2}Hansen, B. E. 2000. Testing for structural change in conditional models. {it:Journal of Econometrics}
97: 93-115.{p_end}
{p 4 8 2}Imhof, J. P. 1961. Computing the distribution of quadratic forms in normal variables. {it:Biometrika}
48: 419-426.{p_end}
{p 4 8 2}Nyblom, J. 1989. Testing for the constancy of parameters over time.
{it:Journal of the American Statistical Association} 84: 223-230.{p_end}
{p 4 8 2}Shao, X. 2010. The dependent wild bootstrap. {it:Journal of the American Statistical Association}
105: 218-235.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb tsnormal} (same package), {helpb estat sbcusum}, {helpb estat sbsingle}{p_end}
