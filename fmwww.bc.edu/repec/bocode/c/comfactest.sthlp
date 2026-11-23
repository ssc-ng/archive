{smcl}
{* *! comfactest v1.23.7 - November 2026}{...}
{viewerjumpto "Syntax" "comfactest##syntax"}{...}
{viewerjumpto "Description" "comfactest##description"}{...}
{viewerjumpto "Options" "comfactest##options"}{...}
{viewerjumpto "Examples" "comfactest##examples"}{...}
{viewerjumpto "Stored results" "comfactest##results"}{...}
{viewerjumpto "Remarks" "comfactest##remarks"}{...}
{viewerjumpto "Replication" "comfactest##replication"}{...}
{viewerjumpto "References" "comfactest##references"}{...}
{viewerjumpto "Author" "comfactest##author"}{...}
{title:Title}

{phang}
{bf:comfactest} {hline 2} Testing common factor (COMFAC) restrictions for EGLS estimation with AR(1) to AR(4) errors

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:comfactest} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 16 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ar(#)}}order of the AR errors, 1 to 4; default is {cmd:ar(1)}{p_end}
{synopt:{opt lrnogrid}}add the likelihood ratio test without a grid search{p_end}
{synopt:{opt ftest}}add an additional asymptotic F test (with a grid search){p_end}
{synopt:{opt ftestco}}add the F test with Cochrane-Orcutt (without a grid search), as in gretl; {cmd:ar(1)} only{p_end}
{synopt:{opt reg}}show the regressions behind the tests{p_end}
{synopt:{opt print}}show the common factor restrictions in symbols{p_end}
{synoptline}
{p 4 6 2}
The data must be {cmd:tsset} as a single time series. Time-series operators are allowed.
The model always has a constant.

{marker description}{...}
{title:Description}

{pstd}
{cmd:comfactest} tests whether a static regression with AR(p) errors, p = 1, 2, 3 or 4, can be used in place
of the unrestricted regression that adds lags 1 to p of the dependent variable and of every
non-constant regressor. Write b(0,j) for the coefficient of regressor j, b(l,j) for the coefficient of its
lag l, and c(l) for the coefficient of lag l of the dependent variable in the unrestricted regression. AR(p)
errors imply the common factor restrictions

{p 12 12 2}
b(l,j) = -c(l)*b(0,j),  l = 1, ..., p,  for every non-constant regressor j.

{pstd}
If the restrictions are rejected, an AR(p) error is not an adequate description of the autocorrelation and
EGLS with AR(p) errors should not be used (Hendry and Mizon, 1978). The Wald test and the likelihood ratio
test are always shown.

{pstd}
{bf:Wald test.} This is the main test. It is the test of Sargan (1980), and it uses the unrestricted regression only. The lag polynomials of the regressors and of the
dependent variable have a common factor of degree p when the restrictions hold; the constraints that express
this are obtained by the row-reduction algorithm of Sargan (1980), and the statistic is
W = g'(G V G')^(-1) g, where g holds the constraints, G their derivatives with respect to the coefficients
and V the variance matrix of the OLS coefficients. W is chi-squared with as many degrees of freedom as
restrictions.

{pstd}
{bf:Likelihood ratio test.} The test goes back to Sargan (1964). The statistic is

{p 12 12 2}
LR = T * ln(SSRr / SSRu),

{pstd}
where SSRr and SSRu are the error sums of squares of the restricted and unrestricted models and T is the
number of observations (PcGive; Dougherty, 2006). LR is chi-squared with as many degrees of freedom as
restrictions. The sum of squares of the restricted model can have more than one minimum (Sargan, 1980; Mizon
and Hendry, 1980). For this reason the restricted model is estimated with a grid search: SSRr is the smallest
error sum of squares over the stationary region of the AR coefficients, found by a grid search followed by a
simplex search; when the sum of squares keeps falling towards the edge of that region, the value at the edge
of the search is used.

{pstd}
{bf:Likelihood ratio test without a grid search} ({opt lrnogrid}). The same statistic with the restricted
model estimated by an iteration (Cochrane-Orcutt) started from the OLS estimates of the static regression.
PcGive computes the test in a similar way, by nonlinear least squares from the same kind of starting values,
so the two results are generally the same. They can differ in two cases: when the PcGive iteration stops
before the minimum of the sum of squares is reached, and when PcGive moves an AR coefficient outside the
stationary region. Without a grid search the iteration can stop at a local minimum, and the statistic is
then too large and the p-value too small; this is why the default likelihood ratio test uses a grid search. If the iteration fails,
the row is left empty and a line under the table gives the reason.

{pstd}
{bf:F test} ({opt ftest}). This is an additional asymptotic F test, that of Davidson and MacKinnon (1999),

{p 12 12 2}
F = ((SSRr - SSRu) / r) / (SSRu / (T - K)),

{pstd}
where r is the number of restrictions and K the number of coefficients of the unrestricted regression; it is
compared with the F(r, T - K) distribution. SSRr is the same smallest error sum of squares that the
likelihood ratio test uses, so this is the F test with a grid search. The test is asymptotic: the usual exact F test does not apply because the restrictions are
nonlinear (Dougherty, 2006). With AR(1) errors this F is close to the one gretl reports after {cmd:ar1} with
the {cmd:--hilu} option.

{pstd}
{bf:F test with Cochrane-Orcutt} ({opt ftestco}, {cmd:ar(1)} only). The same F statistic without a grid search:
SSRr is taken from the AR(1) model estimated by Cochrane-Orcutt as in gretl; it reproduces {cmd:ar1} followed by
{cmd:modtest --comfac} in gretl. The Cochrane-Orcutt iteration can stop at a local minimum, and this F is
then too large and the p-value too small. If the iteration does not converge, as in gretl, the row is left empty.

{pstd}
{bf:Reading the two tests together.} If the Wald test and the likelihood ratio test disagree at the 5%
level, a Wald test that does not reject is not by itself evidence that the common factor restrictions hold
(Mizon and Hendry, 1980).

{marker options}{...}
{title:Options}

{phang}
{opt ar(#)} sets the order of the autoregressive error process, 1 to 4; the default is {cmd:ar(1)}.

{phang}
{opt lrnogrid} adds the likelihood ratio test whose restricted model is estimated without a grid search;
PcGive computes the test in a similar way.

{phang}
{opt ftest} adds an additional asymptotic F test, that of Davidson and MacKinnon (1999), to the tests shown.

{phang}
{opt ftestco} adds the F test whose restricted model is estimated by Cochrane-Orcutt as in gretl; it is
allowed only with {cmd:ar(1)}.

{phang}
{opt reg} shows, before the table of tests, the unrestricted regression and the estimates of the restricted
models that the requested tests use. With {cmd:ar(2)} to {cmd:ar(4)} it adds, after the table, the Wald
tests for 1 to p common factors, cumulative and incremental.

{phang}
{opt print} shows, before the results, the restricted model with AR(p) errors, the unrestricted model and
the common factor restrictions in symbols, with the names of the variables of the command.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/AWM18.dta, clear}{p_end}
{phang2}{cmd:. tsset quarter}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(2)}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(2) lrnogrid}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(1) ftest ftestco}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(2) ftest}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(2) reg}{p_end}
{phang2}{cmd:. comfactest YER PCR GCR, ar(2) print}{p_end}
{phang2}{cmd:. return list}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:comfactest} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(ar)}}order of the autoregressive error{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(chi2)}}Wald statistic{p_end}
{synopt:{cmd:r(p_chi2)}}its p-value{p_end}
{synopt:{cmd:r(df_chi2)}}number of restrictions{p_end}
{synopt:{cmd:r(lr)}}likelihood ratio statistic{p_end}
{synopt:{cmd:r(p_lr)}}its p-value{p_end}
{synopt:{cmd:r(df_lr)}}number of restrictions{p_end}
{synopt:{cmd:r(ssr_u)}}error sum of squares of the unrestricted regression{p_end}
{synopt:{cmd:r(ssr_r_lr)}}error sum of squares of the restricted model of the likelihood ratio test{p_end}
{synopt:{cmd:r(lr_nogrid)}}likelihood ratio statistic without a grid search ({opt lrnogrid}){p_end}
{synopt:{cmd:r(p_lr_nogrid)}}its p-value{p_end}
{synopt:{cmd:r(df_lr_nogrid)}}number of restrictions{p_end}
{synopt:{cmd:r(F)}}F statistic ({opt ftest}){p_end}
{synopt:{cmd:r(p)}}its p-value{p_end}
{synopt:{cmd:r(df_n)}}its numerator degrees of freedom{p_end}
{synopt:{cmd:r(df_d)}}its denominator degrees of freedom{p_end}
{synopt:{cmd:r(F_co)}}F statistic with Cochrane-Orcutt ({opt ftestco}){p_end}
{synopt:{cmd:r(p_co)}}its p-value{p_end}
{synopt:{cmd:r(df_n_co)}}its numerator degrees of freedom{p_end}
{synopt:{cmd:r(df_d_co)}}its denominator degrees of freedom{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(wald)}}sequence of Wald tests: number of common factors, cumulative chi2, df, p-value, incremental chi2, df, p-value{p_end}
{synopt:{cmd:r(b_aug)}}coefficients of the unrestricted regression{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
The Wald statistic depends on the order of the regressors (PcGive), because a Wald test of nonlinear
restrictions is sensitive to how the restrictions are formulated (Gregory and Veall, 1985). With the AWM18 data,
{cmd:comfactest YER PCR GCR, ar(2)} gives chi2(4) = 4.5486 while {cmd:comfactest YER GCR PCR, ar(2)} gives
chi2(4) = 31.058.

{marker replication}{...}
{title:Replication}

{pstd}
The examples use the AWM18 data. In Stata the data are loaded once with

{p 12 12 2}{cmd:. use https://eruygurakademi.com/datasets/AWM18.dta, clear}{p_end}
{p 12 12 2}{cmd:. tsset quarter}{p_end}

{hline}

{pstd}
{bf:A. PcGive: Wald test}

{pstd}
Data for PcGive: download {browse "https://eruygurakademi.com/datasets/AWM18_oxdata.zip"} and unzip it. It holds
{cmd:AWM18.oxdata}, the same data as a quarterly OxMetrics database for 1970(1) to 2017(4). Open
{cmd:AWM18.oxdata} in OxMetrics (File, Open File). Then choose Model, Batch, paste the batch code of the
example and press Run batch. The result is in the last row of the COMFAC Wald test table of PcGive.

{pstd}
{it:Example A1}

{p 8 8 2}PcGive batch code:{p_end}
{p 12 12 2}{cmd:module("PcGive");}{p_end}
{p 12 12 2}{cmd:package("PcGive", "Single-equation");}{p_end}
{p 12 12 2}{cmd:usedata("AWM18.oxdata");}{p_end}
{p 12 12 2}{cmd:system}{p_end}
{p 12 12 2}{cmd:{c -(}}{p_end}
{p 12 12 2}{cmd:Y = YER;}{p_end}
{p 12 12 2}{cmd:X = YER_1, YER_2, Constant, PCR, PCR_1, PCR_2, GCR, GCR_1, GCR_2;}{p_end}
{p 12 12 2}{cmd:{c )-}}{p_end}
{p 12 12 2}{cmd:estimate("OLS", 1970, 3, 2017, 4);}{p_end}
{p 12 12 2}{cmd:test("comfac");}{p_end}

{p2colset 9 28 30 2}{...}
{p2col:PcGive result}Chi^2(4) = 4.5486 [0.3368]{p_end}
{p2col:Stata command}{cmd:. comfactest YER PCR GCR, ar(2)}{p_end}
{p2col:Stata result}Wald chi2 = 4.5486, df = 4, p-value = 0.3368{p_end}

{pstd}
{it:Example A2 (the two regressors in the other order)}

{p 8 8 2}PcGive batch code:{p_end}
{p 12 12 2}{cmd:module("PcGive");}{p_end}
{p 12 12 2}{cmd:package("PcGive", "Single-equation");}{p_end}
{p 12 12 2}{cmd:usedata("AWM18.oxdata");}{p_end}
{p 12 12 2}{cmd:system}{p_end}
{p 12 12 2}{cmd:{c -(}}{p_end}
{p 12 12 2}{cmd:Y = YER;}{p_end}
{p 12 12 2}{cmd:X = YER_1, YER_2, Constant, GCR, GCR_1, GCR_2, PCR, PCR_1, PCR_2;}{p_end}
{p 12 12 2}{cmd:{c )-}}{p_end}
{p 12 12 2}{cmd:estimate("OLS", 1970, 3, 2017, 4);}{p_end}
{p 12 12 2}{cmd:test("comfac");}{p_end}

{p2colset 9 28 30 2}{...}
{p2col:PcGive result}Chi^2(4) = 31.058 [0.0000]{p_end}
{p2col:Stata command}{cmd:. comfactest YER GCR PCR, ar(2)}{p_end}
{p2col:Stata result}Wald chi2 = 31.0581, df = 4, p-value = 0.0000{p_end}

{hline}

{pstd}
{bf:B. gretl: F tests}

{pstd}
Data for gretl: the same data come with gretl as {cmd:AWM18.gdt}; nothing has to be downloaded. Type the
commands of the example in the gretl console.

{pstd}
{it:Example B1 (F test with Cochrane-Orcutt, option ftestco)}

{p 8 8 2}gretl commands:{p_end}
{p 12 12 2}{cmd:open AWM18.gdt}{p_end}
{p 12 12 2}{cmd:ar1 YER const PCR GCR}{p_end}
{p 12 12 2}{cmd:modtest --comfac}{p_end}

{p2colset 9 28 30 2}{...}
{p2col:gretl result}F(2, 185) = 5.1358, p-value = 0.00674949{p_end}
{p2col:Stata command}{cmd:. comfactest YER PCR GCR, ftestco}{p_end}
{p2col:Stata result}F (CO) = 5.1358, df = 2 and 185, p-value = 0.0067{p_end}

{pstd}
{it:Example B2 (F test with Cochrane-Orcutt, option ftestco)}

{p 8 8 2}gretl commands:{p_end}
{p 12 12 2}{cmd:open AWM18.gdt}{p_end}
{p 12 12 2}{cmd:ar1 PCD const YED}{p_end}
{p 12 12 2}{cmd:modtest --comfac}{p_end}

{p2colset 9 28 30 2}{...}
{p2col:gretl result}F(1, 187) = 8.96722, p-value = 0.00312065{p_end}
{p2col:Stata command}{cmd:. comfactest PCD YED, ftestco}{p_end}
{p2col:Stata result}F (CO) = 8.9672, df = 1 and 187, p-value = 0.0031{p_end}

{pstd}
{it:Example B3 (F test with a grid search, option ftest)}

{p 8 8 2}gretl commands:{p_end}
{p 12 12 2}{cmd:open AWM18.gdt}{p_end}
{p 12 12 2}{cmd:ar1 YER const PCR GCR --hilu}{p_end}
{p 12 12 2}{cmd:modtest --comfac}{p_end}

{p2colset 9 28 30 2}{...}
{p2col:gretl result}F(2, 185) = 1.63478, p-value = 0.197799{p_end}
{p2col:Stata command}{cmd:. comfactest YER PCR GCR, ftest}{p_end}
{p2col:Stata result}F = 1.6348, df = 2 and 185, p-value = 0.1978{p_end}

{p 8 8 2}In this example the two results are close but not identical (gretl 1.634783, {cmd:comfactest} 1.634807): gretl stops its search earlier than {cmd:comfactest}. In other models the difference can show in the fourth decimal.{p_end}

{marker references}{...}
{title:References}

{phang}
Cottrell, A., and R. Lucchetti. {it:gretl: Gnu Regression, Econometrics and Time-series Library}.

{phang}
Davidson, R., and J. G. MacKinnon. 1999. {it:Econometric Theory and Methods}. Oxford University Press.

{phang}
Doornik, J. A., and D. F. Hendry. 2026. {it:Empirical Econometric Modelling - PcGive 17: Volume I}.
Timberlake Consultants. Cited as PcGive.

{phang}
Dougherty, C. 2006. {it:Introduction to Econometrics}. 3rd ed. Oxford University Press.

{phang}
Gregory, A. W., and M. R. Veall. 1985. Formulating Wald tests of nonlinear restrictions.
{it:Econometrica} 53: 1465-1468.

{phang}
Hendry, D. F., and G. E. Mizon. 1978. Serial correlation as a convenient simplification, not a nuisance.
{it:Economic Journal} 88: 549-563.

{phang}
Mizon, G. E., and D. F. Hendry. 1980. An empirical application and Monte Carlo analysis of tests of dynamic
specification. {it:Review of Economic Studies} 47: 21-45.

{phang}
Sargan, J. D. 1964. Wages and prices in the United Kingdom: a study in econometric methodology. In
{it:Econometric Analysis for National Economic Planning}, ed. P. E. Hart, G. Mills and J. K. Whitaker.
Butterworths.

{phang}
Sargan, J. D. 1980. Some tests of dynamic specification for a single equation. {it:Econometrica} 48: 879-897.

{marker author}{...}
{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://ozaneruygur.com":ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye{break}
{browse "https://eruygurakademi.com":eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pstd}
The Wald test was written from Sargan (1980) and reproduces the COMFAC test of PcGive by Jurgen A. Doornik
and David F. Hendry; no PcGive code was used. The F test of {opt ftest} was written from Davidson and
MacKinnon (1999). The F test of {opt ftestco} is a port of the AR(1) estimator and the common factor test of
gretl by Allin Cottrell and Riccardo "Jack" Lucchetti.

{pstd}
comfactest v1.23.7 - November 2026

{pstd}
{ul:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:comfactest}: Testing common factor (COMFAC) restrictions for EGLS estimation with AR(1) to AR(4) errors. Stata package version 1.23.7. Available from: eruygurakademi.com
