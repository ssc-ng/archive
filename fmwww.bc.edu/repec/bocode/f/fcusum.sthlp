{smcl}
{* *! version 1.1.0  24nov2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[TS] vecrank" "help vecrank"}{...}
{viewerjumpto "Syntax" "fcusum##syntax"}{...}
{viewerjumpto "Description" "fcusum##description"}{...}
{viewerjumpto "Options" "fcusum##options"}{...}
{viewerjumpto "Remarks" "fcusum##remarks"}{...}
{viewerjumpto "Examples" "fcusum##examples"}{...}
{viewerjumpto "Stored results" "fcusum##results"}{...}
{viewerjumpto "References" "fcusum##references"}{...}
{viewerjumpto "Author" "fcusum##author"}{...}
{title:Title}

{phang}
{bf:fcusum} {hline 2} Fourier CUSUM test for the null hypothesis of cointegration


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:fcusum} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Fourier terms}
{synopt:{opt kstar(#)}}largest Fourier frequency searched; default is {cmd:kstar(3)}{p_end}
{synopt:{opt freq(grid)}}{cmd:fractional} (default) or {cmd:integer} frequency grid{p_end}
{synopt:{opt step(#)}}step of the fractional grid; default is {cmd:step(0.01)}{p_end}
{synopt:{opt four:ier(rule)}}{cmd:auto} (default), {cmd:always} or {cmd:never}{p_end}
{synopt:{opt pre:test(#)}}significance level of the sup-F pre-test; default is {cmd:pretest(0.05)}{p_end}

{syntab:Critical values}
{synopt:{opt cv(method)}}{cmd:bootstrap} (default) or {cmd:table}{p_end}
{synopt:{opt boot(scheme)}}{cmd:iid} (default) or {cmd:sieve}{p_end}
{synopt:{opt reps(#)}}bootstrap or simulation replications; default is {cmd:reps(499)}{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}

{syntab:Estimation}
{synopt:{opt q(#)}}number of DOLS leads and lags; default is selection by BIC{p_end}
{synopt:{opt qmax(#)}}largest number of leads/lags considered by BIC{p_end}
{synopt:{opt bw(rule)}}Bartlett bandwidth: {cmd:nw} (default), {cmd:kurozumi} or {cmd:andrews}{p_end}

{syntab:Reporting}
{synopt:{opt resid(newvar)}}save the residuals of the reported model{p_end}
{synopt:{opt graph}}plot the scaled CUSUM path with the critical band{p_end}
{synopt:{opt glev:el(#)}}level of the band in the graph: 1, 5 (default) or 10{p_end}
{synopt:{opt nocoef}}suppress the table of DOLS coefficients{p_end}
{synoptline}
{p 4 6 2}
You must {helpb tsset} your data before using {cmd:fcusum}; the estimation
sample must be a single time series without gaps. {it:depvar} and
{it:indepvars} may contain time-series operators.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fcusum} tests the null hypothesis of cointegration between {it:depvar}
and the I(1) regressors in {it:indepvars} against the alternative of no
cointegration. The test allows for smooth structural change in the
intercept of the cointegrating relation, approximated by a Fourier pair at
a fractional or integer frequency. It extends the residual-based CUSUM test
of Xiao and Phillips (2002) with the flexible Fourier form and proceeds in
three steps:

{phang2}
1. The cointegrating regression is estimated by dynamic OLS (Stock and
Watson 1993), and the Fourier frequency that minimizes the residual sum of
squares is selected from the grid.{p_end}

{phang2}
2. A sup-F pre-test (Becker, Enders and Lee 2006; Tsong et al. 2016)
decides whether the Fourier terms are needed.{p_end}

{phang2}
3. If the Fourier terms are significant, the Fourier CUSUM statistic is
computed, with bootstrap critical values that replicate the frequency
search. Otherwise, the Xiao-Phillips CUSUM statistic without Fourier terms
is computed, with tabulated critical values.{p_end}

{pstd}
Large values of the statistic reject cointegration.

{pstd}
{cmd:fcusum} is the Stata version of the R package {bf:FCUSUM} 1.1.0
(CRAN) by the same author. It uses the same algorithm and the same
critical-value tables, so the deterministic quantities (selected
leads/lags, frequency, sup-F, both CUSUM statistics and tabulated critical
values) agree with the R package. Bootstrap critical values differ between
the two programs only by simulation noise, because the random-number
generators differ.


{marker options}{...}
{title:Options}

{dlgtab:Fourier terms}

{phang}
{opt kstar(#)} sets the largest frequency in the search grid. The default
is {cmd:kstar(3)}. Tabulated sup-F critical values cover {it:kstar} = 1,...,5;
larger values trigger simulated critical values.

{phang}
{opt freq(grid)} chooses the frequency grid. {cmd:fractional} (default)
searches 0.1, 0.1+{it:step}, ..., {it:kstar}; {cmd:integer} searches 1, 2,
..., {it:kstar}.

{phang}
{opt step(#)} sets the increment of the fractional grid; the default is
{cmd:step(0.01)}. Tabulated sup-F critical values for the fractional grid
assume {cmd:step(0.01)}; other steps trigger simulated critical values.

{phang}
{opt fourier(rule)} controls the pre-test. {cmd:auto} (default) keeps the
Fourier terms only when the sup-F statistic exceeds its critical value at
the {opt pretest()} level. {cmd:always} reports the Fourier CUSUM test
regardless of the pre-test; {cmd:never} reports the Xiao-Phillips CUSUM test
without Fourier terms.

{phang}
{opt pretest(#)} sets the significance level of the sup-F pre-test. The
default is {cmd:pretest(0.05)}.

{dlgtab:Critical values}

{phang}
{opt cv(method)} chooses the critical values of the Fourier CUSUM test.
{cmd:bootstrap} (default) generates data under the null with a Fourier
break at the estimated frequency and amplitudes and repeats the whole
procedure (DOLS, frequency search, long-run variance) on each sample.
{cmd:table} uses asymptotic critical values at the selected frequency; this
is fast but conservative in finite samples because it ignores the frequency
search. The Xiao-Phillips test always uses tabulated values (for up to four
regressors; more regressors trigger simulated values).

{phang}
{opt boot(scheme)} chooses the bootstrap errors. {cmd:iid} (default) draws
iid N(0,1) errors and has the best power. {cmd:sieve} draws errors from an
AR(p) sieve (p <= 4, chosen by AIC) fitted to the residuals; it has better
size with highly persistent errors and lower power.

{phang}
{opt reps(#)} sets the number of bootstrap replications, also used for
simulated critical values outside the built-in tables. The default is
{cmd:reps(499)}; the minimum is 19.

{phang}
{opt seed(#)} sets the random-number seed before the bootstrap. The state
of the random-number generator is restored afterwards.

{dlgtab:Estimation}

{phang}
{opt q(#)} sets the number of leads and lags of the differenced regressors
in the DOLS regression. By default, {it:q} is chosen by BIC between 0 and
{opt qmax()} on a common sample.

{phang}
{opt qmax(#)} sets the largest {it:q} considered by BIC. The default is
min(4, floor(4(T/100)^(1/4))).

{phang}
{opt bw(rule)} sets the bandwidth of the Bartlett long-run variance
estimator: {cmd:nw} (Newey-West 1994 rule floor(4(T/100)^(2/9)), default),
{cmd:kurozumi} (Andrews 1991 AR(1) plug-in bounded as in Kurozumi 2002;
better size with persistent errors) or {cmd:andrews} (unbounded AR(1)
plug-in).

{dlgtab:Reporting}

{phang}
{opt resid(newvar)} saves the residuals of the model behind the reported
test (with or without Fourier terms) in {it:newvar}.

{phang}
{opt graph} plots the scaled cumulative sum of residuals of the reported
model against time, with dashed lines at plus and minus the critical value.

{phang}
{opt glevel(#)} sets the significance level of the band in the graph: 1, 5
(default) or 10.

{phang}
{opt nocoef} suppresses the table of DOLS coefficients.


{marker remarks}{...}
{title:Remarks}

{pstd}
The Fourier cointegrating regression is

{p 8 8 2}
y_t = a0 + a1 sin(2πkt/T) + a2 cos(2πkt/T) + b'x_t +
sum(j = -q..q) g_j' Δx(t-j) + u_t,

{pstd}
and the statistic is

{p 8 8 2}
CS = max(t) | u_1 + ... + u_t | / (w sqrt(T)),

{pstd}
where w^2 is a Bartlett long-run variance estimate of u_t.

{pstd}
{bf:Why a pre-test and a bootstrap.} With a fractional frequency, the null
distribution of the Fourier CUSUM statistic depends on the true frequency,
and the search over k shrinks the statistic. When there is no break the
selected frequency is spurious; when there is one, it is estimated with
error. The sup-F pre-test sends samples without a break to the standard
Xiao-Phillips test, and the bootstrap reproduces the frequency search
around the estimated break, so the Fourier CUSUM test keeps close to its
nominal size with and without a break.

{pstd}
The coefficient table shows the constant, the long-run coefficients and,
when retained, the Fourier pair. Leads and lags of the differenced
regressors are not shown. No standard errors are reported because OLS
standard errors are not valid for DOLS inference.


{marker examples}{...}
{title:Examples}

{pstd}Simulated cointegrated series with a smooth break at k = 1.5{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 150}{p_end}
{phang2}{cmd:. set seed 123}{p_end}
{phang2}{cmd:. generate t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. generate x = sum(rnormal())}{p_end}
{phang2}{cmd:. generate y = 2 + 2*sin(2*_pi*1.5*t/150) + 1.5*x + rnormal()}{p_end}

{pstd}Default procedure: sup-F pre-test, then bootstrap Fourier CUSUM{p_end}
{phang2}{cmd:. fcusum y x, seed(1)}{p_end}

{pstd}Integer frequencies and fast tabulated critical values{p_end}
{phang2}{cmd:. fcusum y x, kstar(2) freq(integer) cv(table)}{p_end}

{pstd}Two regressors, sieve bootstrap, Kurozumi bandwidth, graph{p_end}
{phang2}{cmd:. generate x2 = sum(rnormal())}{p_end}
{phang2}{cmd:. generate y2 = 1 + 2*sin(2*_pi*1.5*t/150) + x - 0.5*x2 + rnormal()}{p_end}
{phang2}{cmd:. fcusum y2 x x2, boot(sieve) bw(kurozumi) seed(1) graph}{p_end}

{pstd}Standard Xiao-Phillips CUSUM test only{p_end}
{phang2}{cmd:. fcusum y2 x x2, fourier(never)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fcusum} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}CUSUM statistic of the reported test{p_end}
{synopt:{cmd:r(p)}}p-value of the reported test{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(supF)}}sup-F pre-test statistic{p_end}
{synopt:{cmd:r(supF_p)}}p-value of the sup-F statistic{p_end}
{synopt:{cmd:r(supF_cv)}}sup-F critical value at the {opt pretest()} level{p_end}
{synopt:{cmd:r(supF_cv10)}}sup-F 10% critical value{p_end}
{synopt:{cmd:r(supF_cv5)}}sup-F 5% critical value{p_end}
{synopt:{cmd:r(supF_cv1)}}sup-F 1% critical value{p_end}
{synopt:{cmd:r(fourier)}}1 if the Fourier terms were retained, 0 otherwise{p_end}
{synopt:{cmd:r(khat)}}selected Fourier frequency{p_end}
{synopt:{cmd:r(stat_fourier)}}Fourier CUSUM statistic{p_end}
{synopt:{cmd:r(stat_plain)}}Xiao-Phillips CUSUM statistic{p_end}
{synopt:{cmd:r(lrv)}}long-run variance of the reported model's residuals{p_end}
{synopt:{cmd:r(bwlags)}}number of Bartlett lags{p_end}
{synopt:{cmd:r(q)}}number of DOLS leads and lags{p_end}
{synopt:{cmd:r(kstar)}}largest frequency searched{p_end}
{synopt:{cmd:r(reps)}}replications{p_end}
{synopt:{cmd:r(n_regs)}}number of regressors{p_end}
{synopt:{cmd:r(N)}}observations used in the DOLS regression{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:fcusum}{p_end}
{synopt:{cmd:r(test)}}{cmd:Fourier CUSUM} or {cmd:Xiao-Phillips CUSUM}{p_end}
{synopt:{cmd:r(decision)}}text of the decision{p_end}
{synopt:{cmd:r(cvsource)}}source of the critical values{p_end}
{synopt:{cmd:r(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}names of the regressors{p_end}
{synopt:{cmd:r(freq)}}frequency grid{p_end}
{synopt:{cmd:r(bw)}}bandwidth rule{p_end}
{synopt:{cmd:r(boot)}}bootstrap scheme{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}DOLS coefficients: constant, regressors and, if retained, the Fourier pair{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series Analysis} 27: 381-409.

{phang}
Kurozumi, E. 2002. Testing for stationarity with a break.
{it:Journal of Econometrics} 108: 63-99.

{phang}
Newey, W. K., and K. D. West. 1994. Automatic lag selection in covariance
matrix estimation. {it:Review of Economic Studies} 61: 631-653.

{phang}
Stock, J. H., and M. W. Watson. 1993. A simple estimator of cointegrating
vectors in higher order integrated systems. {it:Econometrica} 61: 783-820.

{phang}
Tsong, C.-C., C.-F. Lee, L.-J. Tsai, and T.-C. Hu. 2016. The Fourier
approximation and testing for the null of cointegration.
{it:Empirical Economics} 51: 1085-1113.

{phang}
Xiao, Z., and P. C. B. Phillips. 2002. A CUSUM test for cointegration
using regression residuals. {it:Journal of Econometrics} 108: 43-61.


{marker author}{...}
{title:Author}

{pstd}
Taha Zaghdoudi{break}
Faculté des Sciences Juridiques, Économiques et de Gestion de Jendouba, Tunisia{break}
zedtaha@gmail.com

{pstd}
R version: {browse "https://CRAN.R-project.org/package=FCUSUM":FCUSUM on CRAN}.
