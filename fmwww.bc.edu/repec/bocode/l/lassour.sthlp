{smcl}
{* *! version 1.0.0  17oct2026}{...}
{vieweralsosee "lassour methods" "help lassour_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "pperron" "help pperron"}{...}
{vieweralsosee "dfgls" "help dfgls"}{...}
{vieweralsosee "bootur" "help bootur"}{...}
{viewerjumpto "Syntax" "lassour##syntax"}{...}
{viewerjumpto "Description" "lassour##description"}{...}
{viewerjumpto "Quick start for beginners" "lassour##quickstart"}{...}
{viewerjumpto "Options" "lassour##options"}{...}
{viewerjumpto "Interpreting the output" "lassour##interpret"}{...}
{viewerjumpto "Remarks and practical guidance" "lassour##remarks"}{...}
{viewerjumpto "Examples" "lassour##examples"}{...}
{viewerjumpto "Stored results" "lassour##results"}{...}
{viewerjumpto "References" "lassour##references"}{...}
{viewerjumpto "Author" "lassour##author"}{...}

{title:Title}

{phang}
{bf:lassour} {hline 2} Adaptive Lasso activation knot unit root tests with
sieve wild bootstrap


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:lassour} {it:varname} {ifin} [{cmd:,} {it:options}]

{p 8 15 2}
{cmd:lassour cv} [{cmd:,} {cmdab:d:eterministics(}{it:string}{cmd:)}]

{pstd}
{it:varname} is a single time series. The data must be {helpb tsset} and the
sample must be contiguous (no internal gaps).

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth d:eterministics(string)}}deterministic component:
{cmd:none}, {cmd:constant} (default) or {cmd:trend}{p_end}
{synopt :{opt t:est(string)}}which statistic: {cmd:tau}, {cmd:tauie} or
{cmd:both} (default){p_end}

{syntab:Lag selection}
{synopt :{opt lag:s(#)}}use a fixed ADF lag order {it:#} instead of selecting
one{p_end}
{synopt :{opt crit:erion(string)}}{cmd:rsmaic} (default), {cmd:rsmbic},
{cmd:maic}, {cmd:mbic}, {cmd:aic} or {cmd:bic}{p_end}
{synopt :{opt max:lag(#)}}maximum lag considered; default
{cmd:floor(12*(T/100)^0.25)}{p_end}
{synopt :{opt min:lag(#)}}minimum lag considered; default {cmd:0}{p_end}
{synopt :{opt icd:etrend(string)}}series fed to the criterion: {cmd:ols}
(default) or {cmd:fd}{p_end}
{synopt :{opt sieve:lags(#)}}sieve (recolouring) lag order {it:q}; default
{it:q} = {it:p}{p_end}

{syntab:Bootstrap}
{synopt :{opt noboot:strap}}use published asymptotic critical values instead of
the bootstrap{p_end}
{synopt :{opt r:eps(#)}}bootstrap replications {it:B}; default {cmd:499}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synopt :{opt nodots}}suppress the progress dots{p_end}

{syntab:Tuning}
{synopt :{opt al:pha(#)}}{it:alpha} for the J statistic; default {cmd:.1}{p_end}
{synopt :{opt jr:eps(#)}}replications {it:R} for the J statistic; default
{cmd:150}{p_end}
{synopt :{opt lrv:lags(#)}}lag {it:k} for the long-run variance in Algorithm 1
step 1; default {it:k} = {it:p}{p_end}
{synopt :{opt band:width(#)}}bandwidth {it:h} for the volatility estimator;
default {cmd:.1}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt graph}}draw the four-panel diagnostic figure{p_end}
{synopt :{opt grapho:pts(string)}}options passed to {helpb graph combine}{p_end}
{synopt :{opt name(string)}}stub for the graph names; default
{cmd:lassour}{p_end}
{synopt :{opt notab:le}}suppress the results table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lassour} tests the null hypothesis that a time series contains a
{bf:unit root} (is non-stationary) against the alternative that it is
{bf:stationary}, using the adaptive Lasso activation knot tests of
{help lassour##AR24:Arnold and Reinschluessel (2024)} and the sieve wild
bootstrap analogues of
{help lassour##AR26:Arnold and Reinschluessel (2026)}.

{pstd}
The idea is different from a classical Dickey-Fuller test. Instead of looking
at a t-statistic, {cmd:lassour} fits an adaptively penalised (adaptive Lasso)
augmented Dickey-Fuller regression and records {bf:how early the lagged level}
{bf:of the series enters the Lasso solution path}. That entry point is called
an {it:activation knot}. Under a unit root the knot behaves very differently
from under stationarity, and the test exploits exactly that difference.

{pstd}
Two statistics are reported:

{phang2}
{bf:tau} {hline 1} the basic activation knot statistic.

{phang2}
{bf:tauIE} {hline 1} the {it:information-enriched} version, which sharpens the
penalty weight on the lagged level using an auxiliary statistic (J) that is
itself informative about whether a unit root is present. See
{helpb lassour_methods:help lassour methods}.

{pstd}
Both are {bf:right-sided} tests: large values are evidence {it:against} the
unit root, i.e. in favour of stationarity.

{pstd}
By default {cmd:lassour} obtains critical values and p-values from a
{bf:sieve wild bootstrap}. This is the recommended mode: it keeps the test
valid when the error variance changes over time
({it:non-stationary volatility}) and improves finite-sample accuracy when the
errors are serially correlated. With {opt nobootstrap} the command instead
reports the published simulated critical values.


{marker quickstart}{...}
{title:Quick start for beginners}

{pstd}
If you have never used a time-series command in Stata, this section is a
complete recipe. Copy the lines one at a time.

{pstd}
{bf:Step 1. Open your data.}

{phang2}{cmd:. use "mydata.dta", clear}{p_end}

{pstd}
{bf:Step 2. Tell Stata which variable measures time.} Every time-series
command needs this, and {cmd:lassour} will refuse to run without it. If your
time variable is called {cmd:year}:

{phang2}{cmd:. tsset year}{p_end}

{pstd}
If you have quarterly or monthly dates, create a proper Stata date first. For
example, for quarterly data held as {cmd:1990q1} in a string variable
{cmd:datestr}:

{phang2}{cmd:. gen tq = quarterly(datestr, "YQ")}{p_end}
{phang2}{cmd:. format tq %tq}{p_end}
{phang2}{cmd:. tsset tq}{p_end}

{pstd}
If you have no time variable at all, but the rows are already in time order:

{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}
{bf:Step 3. Run the test.} The simplest possible call is just the command and
your series:

{phang2}{cmd:. lassour gdp}{p_end}

{pstd}
That uses every sensible default: a constant as the deterministic term, the
lag order chosen automatically by RSMAIC, 499 bootstrap replications, and both
statistics. Nothing else is required.

{pstd}
{bf:Step 4. Read the answer.} Look at the {bf:p-value} column. If it is below
0.05, you reject the unit root at the 5% level and conclude the series looks
{bf:stationary}. If it is above 0.05 you cannot reject, and the series is
treated as having a {bf:unit root} (non-stationary).

{pstd}
{bf:Step 5. Make the result reproducible.} A bootstrap uses random numbers, so
two runs give slightly different p-values. Fix the seed and they will not:

{phang2}{cmd:. lassour gdp, seed(12345)}{p_end}

{pstd}
{bf:Step 6. If your series trends upward or downward} over time (GDP, prices,
population), include a linear trend, otherwise the test has very little power:

{phang2}{cmd:. lassour gdp, deterministics(trend) seed(12345)}{p_end}

{pstd}
{bf:Step 7. Look at the picture} to check nothing odd is going on:

{phang2}{cmd:. lassour gdp, deterministics(trend) seed(12345) graph}{p_end}

{pstd}
{bf:Step 8. Grab the numbers for a table in your paper.} Everything is stored
in {cmd:r()}:

{phang2}{cmd:. lassour gdp, seed(12345)}{p_end}
{phang2}{cmd:. display r(tau)}{p_end}
{phang2}{cmd:. display r(tau_p)}{p_end}

{pstd}
{bf:Step 9. Test several series in a loop} and collect the results:

{phang2}{cmd:. foreach v of varlist gdp cons inv {c -(}}{p_end}
{phang2}{cmd:.     quietly lassour `v', deterministics(trend) seed(999)}{p_end}
{phang2}{cmd:.     display "`v': tau = " %6.3f r(tau) "  p = " %5.3f r(tau_p)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
{bf:A note on speed.} The bootstrap refits the model {it:B} times, and each
refit also re-selects the lag order and recomputes a simulated auxiliary
statistic. With the defaults a single call takes a few seconds. While you are
exploring, {cmd:reps(199)} is plenty; use {cmd:reps(499)} or more for the
results you report.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth deterministics(string)} chooses what deterministic component is removed
from the series {it:before} the Lasso solution is computed. Removal uses the
{bf:first-difference (FD)} method of
{help lassour##SP92:Schmidt and Phillips (1992)}, which is what the source
papers use.

{phang2}
{cmd:none} {hline 1} no adjustment. Only sensible for a series already known
to have zero mean and no trend.

{phang2}
{cmd:constant} {hline 1} (the default) removes a level, as
{it:y(t) - y(1)}. Use this for a series that fluctuates around a constant
mean: an interest rate, an inflation rate, an unemployment rate, a spread.

{phang2}
{cmd:trend} {hline 1} removes a level and a linear trend, as
{it:y(t) - y(1) - ((t-1)/(T-1)) (y(T) - y(1))}. Use this for a series that
drifts steadily up or down: real GDP, a price index, population.

{pstd}
Choosing {cmd:constant} for a clearly trending series destroys power; choosing
{cmd:trend} for a series with no trend costs some power. When in doubt, plot
the series first.

{phang}
{opt test(string)} selects which statistic to compute. {cmd:both} (the
default) reports {bf:tau} and {bf:tauIE}. Use {cmd:test(tau)} to skip the J
statistic entirely, which is noticeably faster because J is simulated.

{dlgtab:Lag selection}

{pstd}
The test is built on an augmented Dickey-Fuller regression with {it:p} lagged
differences. {it:p} soaks up short-run dynamics; too few lags distorts the
size of the test, too many costs power.

{phang}
{opt lags(#)} fixes {it:p} at {it:#} and switches selection off. With
{cmd:lags(0)} you get the plain (unaugmented) case.

{phang}
{opt criterion(string)} picks the selection rule when {opt lags()} is not
given.

{phang2}
{cmd:rsmaic} {hline 1} (the default) the {it:re-scaled} modified AIC of
{help lassour##CPST:Cavaliere, Phillips, Smeekes and Taylor (2015)}. The
series is first divided by a nonparametric estimate of its own time-varying
volatility, which stops a variance break from inflating the chosen lag order.
This is what the source paper uses throughout.

{phang2}
{cmd:maic}, {cmd:mbic} {hline 1} the modified criteria of
{help lassour##NP01:Ng and Perron (2001)} without the re-scaling.

{phang2}
{cmd:aic}, {cmd:bic} {hline 1} the plain criteria. These tend to pick too few
lags for unit root testing and are offered only for comparison.

{phang}
{opt maxlag(#)} and {opt minlag(#)} bound the search. The default maximum is
the Schwert-type rule {cmd:floor(12*(T/100)^0.25)}, capped so that enough
observations remain.

{phang}
{opt icdetrend(string)} chooses which transform of the series is fed to the
information criterion. The {it:test} always uses FD detrending; this option
concerns only lag selection, which the source paper leaves unspecified.

{phang2}
{cmd:ols} {hline 1} (the default) the OLS-detrended series, following
Perron and Qu (2007) as adopted by
{help lassour##CPST:Cavaliere, Phillips, Smeekes and Taylor (2015)}, whose
RSMAIC the source paper uses. This also makes {cmd:lassour} agree with
{helpb bootur} on the selected lag.

{phang2}
{cmd:fd} {hline 1} the same FD-detrended series the test itself uses.

{pstd}
Empirical size and power are equivalent under the two
(see {helpb lassour_methods:help lassour methods}); they can nevertheless
select a different lag order on a given series, so report which you used.

{phang}
{opt sievelags(#)} sets the lag order {it:q} of the sieve regression that
colours the bootstrap errors. The default {it:q} = {it:p} follows Remark 1 of
the source paper. {cmd:sievelags(0)} gives the plain (uncoloured) wild
bootstrap, which is less accurate under serially correlated errors.

{dlgtab:Bootstrap}

{phang}
{opt nobootstrap} reports the published simulated critical values of
{help lassour##AR24:Arnold and Reinschluessel (2024)} instead of bootstrapping,
interpolated linearly in the sample size. It is fast, but valid only under
homoskedastic errors. See {helpb lassour_methods:help lassour methods} for the
caveats; {cmd:lassour cv} prints the whole table.

{phang}
{opt reps(#)} is the number of bootstrap replications {it:B}. The minimum is
99. The source paper uses 499.

{phang}
{opt seed(#)} sets the seed so results are reproducible. {bf:Always set it in}
{bf:work you report.}

{phang}
{opt nodots} suppresses the progress dots.

{dlgtab:Tuning}

{pstd}
These rarely need changing. They are exposed because the source papers leave
some of them open.

{phang}
{opt alpha(#)} is the tail probability defining the J statistic, which is an
inter-quantile {it:range}. The published choice is {cmd:.1}.

{phang}
{opt jreps(#)} is the number of simulated regressions {it:R} behind J. The
published choice is {cmd:150}. Larger values reduce the simulation noise in
{bf:tauIE} at a linear cost in time.

{phang}
{opt lrvlags(#)} is the lag {it:k} used for the long-run-variance estimate in
step 1 of Algorithm 1 for the enriched weight. {bf:The source paper says only}
{bf:"for suitable k" and does not specify it}; {cmd:lassour} defaults to
{it:k} = {it:p}. {bf:tauIE} is mildly sensitive to this choice (see
{helpb lassour_methods:help lassour methods}); {bf:tau} is not affected at all.

{phang}
{opt bandwidth(#)} is the bandwidth {it:h} of the Nadaraya-Watson volatility
estimator used by the RSMAIC criterion and by panel D of the graph. The
published choice is {cmd:.1}.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the level for the reported critical value. With
{opt nobootstrap} only {cmd:level(90)}, {cmd:level(95)} and {cmd:level(99)}
are tabulated; other levels fall back to the 95% column. p-values are
unaffected.

{phang}
{opt graph} draws a four-panel figure: {bf:A} the series with its
deterministic adjustment, {bf:B} the adaptive Lasso solution path with the
path of the lagged level highlighted, {bf:C} the bootstrap null distribution
with the observed statistic and the critical value marked, and {bf:D} the
estimated volatility profile. Each panel is also saved separately as
{it:name}{cmd:_series}, {it:name}{cmd:_path}, {it:name}{cmd:_boot} and
{it:name}{cmd:_vol} so you can {helpb graph combine} or export them
individually.

{phang}
{opt graphopts(string)} passes any {helpb graph combine} option through, e.g.
{cmd:graphopts(xsize(8) ysize(6))}.

{phang}
{opt name(string)} is the stub for the graph names. The default is
{cmd:lassour}.

{phang}
{opt notable} suppresses the printed table while still filling {cmd:r()}.
Useful inside loops and simulations.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
A typical table looks like this:

{cmd}
    Adaptive Lasso activation knot unit root test
    Sieve wild bootstrap   (Arnold & Reinschluessel 2026)
    -------------------------------------------------------------------------
    Series                     |  lrhpi
    Deterministics             |  linear trend (FD, Schmidt-Phillips)
    ADF observations           |  120
    ADF lag order p            |  2   (selected by rsmaic)
    Sieve lag order q          |  2
    Bootstrap replications B   |  499
    -------------------------------------------------------------------------
    H0: unit root (rho* = 0)             H1: stationary (rho* < 0)
    -------------------------------------------------------------------------
    Statistic          value    boot. c.v.     p-value   decision
    -------------------------------------------------------------------------
    tau              11.4821        7.1043      0.0180  **  reject H0
    tauIE            19.3350       11.2871      0.0240  **  reject H0
    -------------------------------------------------------------------------
{txt}

{pstd}
Line by line:

{phang2}
{bf:Series} {hline 1} the variable tested.

{phang2}
{bf:Deterministics} {hline 1} what was removed before testing, and by which
method.

{phang2}
{bf:ADF observations} {hline 1} the number of rows in the ADF regression.
Initial lagged differences are set to zero rather than dropped (as the source
paper's Algorithm 1 prescribes), so this is T, not T minus p.

{phang2}
{bf:ADF lag order p} {hline 1} the lag order used, and how it was chosen.

{phang2}
{bf:Sieve lag order q} {hline 1} the lag order used to colour the bootstrap
errors.

{phang2}
{bf:value} {hline 1} the observed statistic. It has no natural scale: judge it
only against the critical value beside it.

{phang2}
{bf:boot. c.v.} {hline 1} the bootstrap critical value at the chosen level.
{bf:Reject when the statistic exceeds it} (the test is right-sided).

{phang2}
{bf:p-value} {hline 1} the bootstrap p-value: the fraction of bootstrap
statistics at least as large as the observed one. This is the number to
report.

{phang2}
{bf:decision} {hline 1} the verdict at the chosen level, with
{bf:*} p<.10, {bf:**} p<.05, {bf:***} p<.01.

{pstd}
{bf:Rejecting H0 means the series looks stationary.} Failing to reject means
you cannot rule out a unit root, and you would normally difference the series
before using it in a regression.

{pstd}
The {bf:Auxiliary quantities} block reports the ingredients, which are worth a
glance:

{phang2}
{bf:rho-hat} {hline 1} the OLS estimate of the lagged-level coefficient used
to build the penalty weight. Near zero is the unit root case.

{phang2}
{bf:sigma2-hat} {hline 1} the error-variance estimate that scales the
statistic.

{phang2}
{bf:J} {hline 1} the auxiliary range statistic behind {bf:tauIE}. It is
{bf:large under a unit root} and {bf:small under stationarity}, so a small J
pushes {bf:tauIE} up. If J looks implausible, raise {opt jreps()}.

{phang2}
{bf:LRV lag k} {hline 1} the lag used inside J (see {opt lrvlags()}).


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:1. Which statistic should I report?} Report both, as the source papers do.
{bf:tauIE} is designed to have better power, but it carries simulation noise
from J and depends on the unspecified {opt lrvlags()}. If you must pick one,
{bf:tau} is the more transparent and fully pinned-down choice.

{pstd}
{bf:2. Bootstrap or asymptotic?} Use the bootstrap (the default). The
asymptotic critical values assume a constant error variance. Macroeconomic and
financial series very often have variance breaks, and then the fixed critical
values are simply wrong, whereas the bootstrap stays valid. The
{opt nobootstrap} mode is there for speed, for replication of the 2024 paper,
and for teaching.

{pstd}
{bf:3. Sample size.} The command requires at least 20 observations and the
published critical values are tabulated from T = 50. Below about T = 50 any
unit root test is unreliable; treat such results as indicative only.

{pstd}
{bf:4. Serially correlated errors.} The hardest case for every unit root test
is a large {it:negative} moving-average component. The source paper documents
that the bootstrap tests remain over-sized there in small samples, improving
only slowly with T, although the sieve (recolouring) step helps a lot. If you
suspect a strong negative MA root, interpret a marginal rejection cautiously
and report results for more than one lag order.

{pstd}
{bf:5. Conservative size is safe.} In some designs the test rejects slightly
less often than the nominal level. That controls Type-I error and is not a
defect.

{pstd}
{bf:6. No confidence interval is reported.} The source papers provide a test
of the unit root null, not an interval for the autoregressive parameter, so
none is invented here.

{pstd}
{bf:7. Internal gaps are not allowed.} Leading and trailing missing values are
fine; a hole in the middle of the sample is not, because differencing across
it is meaningless. Fill or split the sample first.

{pstd}
{bf:8. Reproducibility.} Set {opt seed()}. Note that {bf:tauIE} is random even
with {opt nobootstrap}, because J is simulated.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup} {hline 1} a simulated random walk and a simulated stationary
series:

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 20261017}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen double rw = sum(rnormal())}{p_end}
{phang2}{cmd:. gen double ar = 0}{p_end}
{phang2}{cmd:. replace ar = 0.5*ar[_n-1] + rnormal() if _n > 1}{p_end}

{pstd}
The simplest call {hline 1} should {it:not} reject for a random walk:

{phang2}{cmd:. lassour rw, seed(1)}{p_end}

{pstd}
and should reject for the stationary series:

{phang2}{cmd:. lassour ar, seed(1)}{p_end}

{pstd}
A trending series, with the diagnostic figure:

{phang2}{cmd:. lassour rw, deterministics(trend) seed(1) graph}{p_end}

{pstd}
Only {bf:tau}, with a fixed lag order, and more replications:

{phang2}{cmd:. lassour ar, test(tau) lags(4) reps(999) seed(1)}{p_end}

{pstd}
Published asymptotic critical values instead of the bootstrap:

{phang2}{cmd:. lassour rw, nobootstrap}{p_end}

{pstd}
Print the published critical value table for the trend case:

{phang2}{cmd:. lassour cv, deterministics(trend)}{p_end}
{phang2}{cmd:. matrix list r(cv)}{p_end}

{pstd}
Compare lag selection rules:

{phang2}{cmd:. foreach c in rsmaic maic bic {c -(}}{p_end}
{phang2}{cmd:.     quietly lassour ar, criterion(`c') seed(7) notable}{p_end}
{phang2}{cmd:.     display "`c': p = " r(p) "  tau = " %7.3f r(tau) "  pval = " %5.3f r(tau_p)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
Build a publication table across several series:

{phang2}{cmd:. tempname M}{p_end}
{phang2}{cmd:. matrix `M' = J(2, 4, .)}{p_end}
{phang2}{cmd:. matrix rownames `M' = rw ar}{p_end}
{phang2}{cmd:. matrix colnames `M' = tau p_tau tauIE p_tauIE}{p_end}
{phang2}{cmd:. local i = 0}{p_end}
{phang2}{cmd:. foreach v in rw ar {c -(}}{p_end}
{phang2}{cmd:.     local ++i}{p_end}
{phang2}{cmd:.     quietly lassour `v', seed(2024) notable}{p_end}
{phang2}{cmd:.     matrix `M'[`i',1] = r(tau)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',2] = r(tau_p)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',3] = r(tauie)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',4] = r(tauie_p)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. matrix list `M', format(%8.4f)}{p_end}

{pstd}
Inspect the bootstrap null distribution yourself:

{phang2}{cmd:. quietly lassour ar, reps(999) seed(5)}{p_end}
{phang2}{cmd:. matrix B = r(bootdist)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double B, name(bs)}{p_end}
{phang2}{cmd:. summarize bs1 bs2}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
A full worked script is shipped with the package. After installing, run:

{phang2}{cmd:. net get lassour}{p_end}
{phang2}{cmd:. do lassour_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lassour} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations in the sample{p_end}
{synopt:{cmd:r(N_adf)}}rows in the ADF regression{p_end}
{synopt:{cmd:r(p)}}ADF lag order used{p_end}
{synopt:{cmd:r(q)}}sieve lag order used{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications (bootstrap mode only){p_end}
{synopt:{cmd:r(rho)}}OLS estimate of the lagged-level coefficient{p_end}
{synopt:{cmd:r(sigma2)}}error-variance estimate{p_end}
{synopt:{cmd:r(J)}}the J range statistic (when {bf:tauIE} is computed){p_end}
{synopt:{cmd:r(lrvlags)}}lag {it:k} used inside J{p_end}
{synopt:{cmd:r(lambda)}}activation knot of the lagged level{p_end}
{synopt:{cmd:r(tau)}}the tau statistic{p_end}
{synopt:{cmd:r(tau_cv)}}critical value for tau{p_end}
{synopt:{cmd:r(tau_p)}}bootstrap p-value for tau{p_end}
{synopt:{cmd:r(lambda_ie)}}activation knot under the enriched weight{p_end}
{synopt:{cmd:r(tauie)}}the tauIE statistic{p_end}
{synopt:{cmd:r(tauie_cv)}}critical value for tauIE{p_end}
{synopt:{cmd:r(tauie_p)}}bootstrap p-value for tauIE{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:lassour}{p_end}
{synopt:{cmd:r(depvar)}}name of the series tested{p_end}
{synopt:{cmd:r(det)}}deterministic component{p_end}
{synopt:{cmd:r(criterion)}}lag selection criterion{p_end}
{synopt:{cmd:r(icdetrend)}}transform fed to the criterion{p_end}
{synopt:{cmd:r(method)}}{cmd:sieve wild bootstrap} or {cmd:asymptotic ...}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(bootdist)}}{it:B} x 2 bootstrap statistics (tau, tauIE){p_end}
{synopt:{cmd:r(path)}}adaptive Lasso solution path: column 1 is the penalty,
column 2 the lagged-level coefficient, the rest the lagged differences{p_end}

{pstd}
{cmd:lassour cv} stores {cmd:r(cv)}, the 7 x 6 published critical value table,
and {cmd:r(det)}.


{marker references}{...}
{title:References}

{marker AR26}{...}
{phang}
Arnold, M. C., and T. Reinschluessel. 2026. Bootstrap adaptive Lasso solution
path unit root tests. arXiv:2409.07859.

{marker AR24}{...}
{phang}
Arnold, M. C., and T. Reinschluessel. 2024. Adaptive unit root inference in
autoregressions using the Lasso solution path. arXiv:2404.06205.

{marker RA24}{...}
{phang}
Reinschluessel, T., and M. C. Arnold. 2024. Information-enriched selection of
stationary and non-stationary autoregressions using the adaptive Lasso.
arXiv:2402.16580.

{marker CT07}{...}
{phang}
Cavaliere, G., and A. M. R. Taylor. 2007. Testing for unit roots in time
series models with non-stationary volatility.
{it:Journal of Econometrics} 140: 919-947.

{marker CT08}{...}
{phang}
Cavaliere, G., and A. M. R. Taylor. 2008. Bootstrap unit root tests for time
series with nonstationary volatility.
{it:Econometric Theory} 24: 43-71.

{marker CPST}{...}
{phang}
Cavaliere, G., P. C. B. Phillips, S. Smeekes, and A. M. R. Taylor. 2015.
Lag length selection for unit root tests in the presence of nonstationary
volatility. {it:Econometric Reviews} 34: 512-536.

{marker EHJT}{...}
{phang}
Efron, B., T. Hastie, I. Johnstone, and R. Tibshirani. 2004. Least angle
regression. {it:Annals of Statistics} 32: 407-499.

{marker HS10}{...}
{phang}
Herwartz, H., and F. Siedenburg. 2010. A new approach to unit root testing.
Kiel University Economics Working Paper 2009-06.

{marker NP01}{...}
{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit
root tests with good size and power. {it:Econometrica} 69: 1519-1554.

{marker SP92}{...}
{phang}
Schmidt, P., and P. C. B. Phillips. 1992. LM tests for a unit root in the
presence of deterministic trends.
{it:Oxford Bulletin of Economics and Statistics} 54: 257-287.

{marker ST12}{...}
{phang}
Smeekes, S., and A. M. R. Taylor. 2012. Bootstrap union tests for unit roots
in the presence of nonstationary volatility.
{it:Econometric Theory} 28: 422-456.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite Arnold and Reinschluessel (2024, 2026) when using {cmd:lassour}.


{title:Also see}

{psee}
Help: {helpb lassour_methods:lassour methods},
{helpb dfuller}, {helpb pperron}, {helpb dfgls}, {helpb bootur}
{p_end}
