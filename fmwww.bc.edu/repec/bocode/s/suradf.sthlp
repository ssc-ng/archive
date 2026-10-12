{smcl}
{* *! version 1.0.0  11oct2026}{...}
{vieweralsosee "[R] sureg" "help sureg"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "suradf methods" "help suradf_methods"}{...}
{viewerjumpto "Syntax" "suradf##syntax"}{...}
{viewerjumpto "Description" "suradf##description"}{...}
{viewerjumpto "Options" "suradf##options"}{...}
{viewerjumpto "Interpreting the output" "suradf##output"}{...}
{viewerjumpto "Decision guide" "suradf##guidance"}{...}
{viewerjumpto "Stored results" "suradf##results"}{...}
{viewerjumpto "Examples" "suradf##examples"}{...}
{viewerjumpto "References" "suradf##refs"}{...}
{viewerjumpto "Author" "suradf##author"}{...}
{title:Title}

{phang}
{bf:suradf} {hline 2} Series-specific SUR-ADF panel unit root test
(Breuer, McNown and Wallace 2002)


{marker syntax}{...}
{title:Syntax}

{pstd}Panel data, declared with {helpb xtset}:

{p 8 15 2}
{cmd:suradf} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}Time-series data in wide form, declared with {helpb tsset}:

{p 8 15 2}
{cmd:suradf} {it:var1} {it:var2} [{it:var3} ...] {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt lags(spec)}}lag order: {cmd:bmw} (default), {cmd:aic}, {cmd:bic},
one integer, or one integer per series{p_end}
{synopt :{opt maxlags(#)}}longest lag searched; default {cmd:maxlags(8)}{p_end}
{synopt :{opt trend}}add a linear trend to each test equation{p_end}
{synopt :{opt isure}}iterate the FGLS to convergence instead of two-step{p_end}
{synopt :{opt dfk}}small-sample divisor for the covariance matrix{p_end}

{syntab:Panel membership}
{synopt :{opt adfp:retest}}exclude series that reject a single-equation ADF
before testing (Breuer, McNown and Wallace 2006){p_end}
{synopt :{opt ptl:evel(#)}}level for that pre-test: 1, 5 or 10; default 5{p_end}

{syntab:Simulation}
{synopt :{opt reps(#)}}replications for the critical values; default {cmd:reps(1000)}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synopt :{opt burn(#)}}burn-in observations discarded; default {cmd:burn(50)}{p_end}
{synopt :{opt dist(dname)}}innovations: {cmd:normal} (default) or {cmd:bootstrap}{p_end}
{synopt :{opt savedist(name)}}save the simulated statistics to a matrix{p_end}
{synopt :{opt nodots}}suppress the progress dots{p_end}

{syntab:Reporting}
{synopt :{opt graph}}plot each statistic against its own critical values{p_end}
{synopt :{opt distp:lot}}plot the simulated null densities{p_end}
{synopt :{opt graphopts(str)}}options passed to the {helpb twoway} call{p_end}
{synopt :{opt name(str)}}name for the graphs{p_end}
{synopt :{opt notab:le}}suppress the output tables{p_end}
{synoptline}

{pstd}
The panel must be balanced and the time variable contiguous over the estimation
sample. {cmd:suradf} is a small-{it:N} large-{it:T} procedure: it refuses to run
when the usable sample is not comfortably larger than the number of equations.


{marker description}{...}
{title:Description}

{pstd}
{cmd:suradf} tests the null of a unit root {bf:separately for every member of a
panel}, inside a system of seemingly unrelated regressions. For {it:N} series it
estimates

{p 8 8 2}
{bf:Dy(i,t) = a(i) + b(i)*y(i,t-1) + SUM(j=1..k(i)) d(i,j)*Dy(i,t-j) + u(i,t)}

{pstd}
jointly by feasible GLS, allowing the lag order {bf:k(i)} to differ across
members and the errors {bf:u(i,t)} to be contemporaneously correlated across
them. It then tests {it:N} separate hypotheses

{p 8 8 2}
{bf:H0(i): b(i) = 0}  against  {bf:H1(i): b(i) < 0},  for i = 1, ..., N

{pstd}
and reports a verdict for each series.

{pstd}
{bf:This is what distinguishes the test.} Levin-Lin, Im-Pesaran-Shin,
Maddala-Wu, and the multivariate ADF of Sarno and Taylor all test a {it:joint}
hypothesis. When they reject, you learn that {it:at least one} member of the
panel is stationary, with no indication of how many or which. Breuer, McNown and
Wallace's point is that this is of little practical use: in a mixed panel, the
joint null is correctly rejected while the joint alternative ("all stationary")
is also false. {cmd:suradf} gives you the mix and the identity of the
stationary members instead of a single panel-wide verdict.

{pstd}
The gain over the single-equation {helpb dfuller} test comes entirely from the
cross-equation error covariance. When residual cross-correlations are weak the
two tests perform almost identically; when they are strong the SUR estimator is
far more efficient and the test substantially more powerful.

{pstd}
Because the statistic's distribution depends on the estimated covariance matrix
of the system, {bf:there are no tabulated critical values}. {cmd:suradf}
simulates them for your panel, under the null, from your own estimated
parameters. The values it reports apply to this panel and no other.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(spec)} sets the lag order of each test equation.

{pmore}
{cmd:bmw} (the default) reproduces the rule in Section V of the paper: regress
the first difference of each series on {opt maxlags()} of its own lagged
differences {bf:without an intercept}, then drop the highest lag while it is
insignificant at the 10% level {bf:and} dropping it leaves no serial correlation
by a Ljung-Box Q statistic at 4, 8 and 12 lags. A lag is retained even when
insignificant if its removal induces serial correlation.

{pmore}
{cmd:aic} and {cmd:bic} minimise the corresponding information criterion over
0...{opt maxlags()}, on a sample held fixed at {opt maxlags()} so the orders are
compared on identical observations. Neither is in the paper.

{pmore}
A single integer applies that order to every series. {it:N} integers set them
individually, in the order the series appear in the output.

{pmore}
{bf:The result depends on this choice}, which is why the selected {bf:k} is
always printed. If a verdict flips between {cmd:bmw} and {cmd:aic}, report both.

{phang}
{opt maxlags(#)} is the longest lag searched; the default of 8 is the paper's.
It is reduced automatically, with a note, when the sample is too short to
support it alongside {it:N} equations.

{phang}
{opt trend} adds a linear trend to each test equation. {bf:The paper validates
no such case.} Footnote 9 argues explicitly against it for the application at
hand, since a drift would impart a deterministic trend inconsistent with the
data. Use it only if theory demands it, and say so when you report.

{phang}
{opt isure} iterates the feasible GLS to convergence (Zellner's iterated
estimator) rather than stopping at the two-step estimator. The paper says only
"SUR"; two-step is the default and the conventional reading.

{phang}
{opt dfk} divides the cross-equation covariance by
sqrt((T-k(i))(T-k(j))) instead of T. The same convention is used for the
observed statistic and for every simulated one, so the critical values stay
internally consistent either way.

{dlgtab:Panel membership}

{phang}
{opt adfpretest} runs a single-equation ADF test on every series first and
{bf:excludes those that reject}, then applies SURADF to the remainder. This is
the rule Breuer, McNown and Wallace (2006, p. 515) recommend for small {it:T},
on the ground that the SUR critical values are simulated under a null in which
every member has a unit root, so a member already known to be stationary
distorts the rest. The excluded series are listed in the output. Off by
default; see the decision guide in {helpb suradf##guidance:help suradf}.

{phang}
{opt ptlevel(#)} is the level of that pre-test: {cmd:1}, {cmd:5} (default) or
{cmd:10}. A stricter level excludes fewer series.

{dlgtab:Simulation}

{phang}
{opt reps(#)} sets the number of replications. The default of 1,000 is the
figure generally recommended; Breuer, McNown and Wallace use 10,000. A warning
is printed below the table whenever fewer than 1,000 are used. {cmd:reps(0)}
returns the statistics with no critical values, which is useful when you only
want the point estimates.

{phang}
{opt seed(#)} makes the simulation reproducible. {bf:Always set it in work you
intend to publish}, and report the value.

{phang}
{opt burn(#)} is the number of initial simulated observations discarded, from
zero starting values. The default of 50 is the paper's.

{phang}
{opt dist(normal)} draws the innovations from a multivariate normal with the
estimated covariance matrix, through its Cholesky factor. This is what the paper
does (footnote 10). {opt dist(bootstrap)} resamples whole rows of the observed
residual matrix instead, which preserves the cross-sectional dependence without
assuming normality. {bf:This is an extension the paper does not define};
treat it as a robustness check, not as the headline result.

{phang}
{opt savedist(name)} stores the full {it:reps} x {it:N} matrix of simulated
statistics, for your own quantiles or plots.

{dlgtab:Reporting}

{phang}
{opt graph} draws each series' statistic against its own simulated 1%-10%
critical range, with the 5% value marked. A marker below the dashed line
rejects. This is the plot to put in a paper.

{phang}
{opt distplot} draws the simulated null density for each series (up to nine)
with the observed statistic and the 5% critical value marked. Useful for showing
a referee how far into the tail a borderline statistic falls.


{marker output}{...}
{title:Interpreting the output}

{pstd}
The main table has one row per series and the following columns.

{p 6 10 2}
{bf:k} {space 6}the lag order chosen for that equation. Differences across the
panel are expected and allowed; a {bf:k} at the {opt maxlags()} ceiling is a
warning that the search was truncated.

{p 6 10 2}
{bf:AVECOR} {space 1}the mean residual correlation of that series with the rest
of the panel, computed from the restricted null model. {bf:Read this column
first.} It is the quantity that drives everything else: when it is near zero the
test has no advantage over {helpb dfuller}, and when it is high the critical
values move far out into the tail and the power gain is large.

{p 6 10 2}
{bf:ADF} {space 4}the single-equation Dickey-Fuller statistic from the same
specification, shown for comparison. It is {bf:not} the test; it is the
benchmark the SUR statistic is meant to improve on.

{p 6 10 2}
{bf:SURADF} {space 1}the t-ratio on the lagged level from the SUR system. This
is the test statistic.

{p 6 10 2}
{bf:1% 5% 10%} the simulated critical values {bf:for that series}. They differ
across rows because each series has a different position in the covariance
structure. They are left-tail values: reject when the statistic is {bf:more
negative}.

{p 6 10 2}
{bf:p-val} {space 2}the share of simulated statistics below the observed one. A
convenience; the original paper reports critical values only.

{pstd}
Below the table, the {bf:panel average} line reports the Table 1 form of the
critical values, and the {bf:Dickey-Fuller 5%} line gives the standard critical
value at the same sample size. The gap between them is the whole point: with
high cross-correlations the SURADF critical value can be two or three units more
negative than the Dickey-Fuller one, so using Dickey-Fuller tables on a SUR
statistic would reject far too often.

{pstd}
The {bf:series-specific inference} block converts the table into the answer the
test exists to give: how many and which members are I(0), and how many and which
are I(1), at the 5% level.


{marker guidance}{...}
{title:Decision guide}

{dlgtab:Should you use this test at all?}

{pstd}
Work through these in order.

{p 4 8 2}
{bf:1. Is T long enough?} This is the binding constraint, and the published
evidence is specific. Ford, Jackson and Kline (2006) worked with 44 usable
observations and found verdicts flipping as panel membership changed. Breuer,
McNown and Wallace (2006) replied by computing the power of the test at exactly
that sample size: with the mean-reversion coefficient at -0.05 the power never
exceeds {bf:0.21} for any series in any of the three panels, and at -0.10 it
never exceeds {bf:0.5}. At {bf:T = 100} the same exercise gives power around
0.5 at -0.05 and close to {bf:1.0} at -0.10. Their 2002 paper uses 91
observations across three overlapping panels - two series appear in all three
and seven in two - and reports {bf:no conflicting verdict anywhere}.

{pmore}
So: around 90-100 usable observations is where this test has been shown to
behave. In the forties it demonstrably does not. Between the two, say so when
you report.

{p 4 8 2}
{bf:2. Is N small relative to T?} SUR estimates an {it:N} x {it:N} covariance
matrix from {it:T_eff} observations. As {it:N} approaches {it:T} the estimate
degenerates and, in Ford, Jackson and Kline's words, SUR will not estimate at
all - which is what first drew them to the problem, having tried a panel
"wider than deep". {cmd:suradf} refuses outright when the usable sample is not
larger than {it:N}+2, but passing that check is a floor, not a recommendation.

{p 4 8 2}
{bf:3. Are the series actually cross-correlated?} Check the {bf:AVECOR}
column. If it is near zero across the board, the SUR machinery buys you almost
nothing and you should use {helpb dfuller} series by series, or
{helpb xtunitroot} if a joint verdict is what you want. The paper's own
simulations show the SURADF and ADF within a percentage point or two of each
other when correlations sit in the 0.20-0.30 range.

{p 4 8 2}
{bf:4. Do you need to know {it:which} series are stationary?} If a single
panel-wide verdict answers your question, a second-generation panel test with
better power near the unit circle may serve you better. Use {cmd:suradf} when
the identity of the stationary members is itself the result - testing PPP
country by country, classifying series as I(0) or I(1) before fitting an ARDL
or a cointegrating system, or demonstrating that a panel is mixed.

{p 4 8 2}
{bf:5. Is your panel composition defensible?} See the next section. This is the
test's most serious practical weakness, and it has a documented remedy.

{dlgtab:Panel composition is not innocent}

{pstd}
The critical values are a function of the estimated covariance matrix of the
{bf:whole system}. Add one country, and every other country's critical value
changes. This is not a hypothetical.

{pstd}
Ford, Jackson and Kline (2006) took the ten-country OECD real exchange rate
panel of Breuer, McNown and Wallace (2001), in which three countries reject the
unit root - Norway at 5%, Denmark at 10%, Greece at 5%. They then
{bf:replaced a single member}, Spain with Iceland. Norway and Denmark both lost
significance; only Greece survived. Replacing four of the ten removed all three,
leaving {bf:no stationary series at all}. Their conclusion was that membership
is often settled by something arbitrary - data availability, or belonging to an
organisation - so arbitrary criteria produce fragile conclusions.

{pstd}
Breuer, McNown and Wallace (2006) {bf:accepted the mechanism} - they note they
never claimed invariance, and that panel composition affects any panel study -
but argued the case is overstated, because those panels have only 44 usable
observations. At that length they show the test's power never exceeds 0.21 at
a mean-reversion coefficient of -0.05, so {bf:Type II error}, not fragility of
the method, is the better explanation for verdicts that move. Two further
details are worth knowing: the two sets of authors obtained {bf:different
critical values from identical data}, which the original authors attribute to
simulation error; and at 91 observations across three overlapping panels, no
verdict conflicts at all.

{pstd}
What follows for practice:

{p 6 10 2}o {space 1}Decide the panel membership {bf:before} you see the
results, on economic grounds, and say in the paper what the grounds were.

{p 6 10 2}o {space 1}Consider the authors' own remedy, {opt adfpretest} -
see below. It is the one procedure anybody in this exchange proposed for
settling membership non-arbitrarily.

{p 6 10 2}o {space 1}Do not add or drop members until a verdict flips. The
critical values move with you, so this is not a neutral robustness exercise.

{p 6 10 2}o {space 1}If you report more than one panel, report {bf:all} of
them, and note that statistics and critical values are not comparable across
them.

{p 6 10 2}o {space 1}Always report {opt seed()} and {opt reps()}. Two sets of
competent authors got different critical values from the same data because the
values must be simulated. Yours are reproducible only if you say how they were
produced.

{p 6 10 2}o {space 1}Longer {it:T} is the real fix. Note that Ford, Jackson and
Kline explicitly did {bf:not} test whether the sensitivity diminishes with
sample size; Breuer, McNown and Wallace did, and found that it does.

{dlgtab:The authors' remedy for short panels}

{pstd}
In the reply, Breuer, McNown and Wallace propose a concrete rule for choosing
panel membership when {it:T} is small: {bf:pre-test each series with the
single-equation ADF, and exclude those that reject.} The series that fail to
reject are the ones the panel should contain.

{pstd}
The logic is that SURADF critical values are simulated under a null in which
{it:every} member carries a unit root. A member already known to be stationary
contradicts that null and distorts the critical values of the rest.

{pstd}
{opt adfpretest} implements it, with {opt ptlevel()} setting the level (1, 5 or
10; 5 by default). The command reports which series were excluded and the
Dickey-Fuller critical value used, then runs SURADF on what remains.

{phang2}{cmd:. suradf lgdp, adfpretest seed(1)}{p_end}
{phang2}{cmd:. suradf lgdp, adfpretest ptlevel(10) seed(1)}{p_end}

{pstd}
Two cautions. The excluded series have {bf:not} been tested by SURADF - report
them as stationary on ADF evidence, separately. And this is a pre-test, so the
usual pre-testing caveats about the size of the combined procedure apply; the
authors recommend it for the small-{it:T} case, not as a default. It is off
unless you ask for it.

{dlgtab:What a non-rejection does and does not mean}

{pstd}
Power is modest when the sample is short and the largest root is close to one.
In the 2002 paper's simulations at T = 50, the SURADF rejects a false null
between 8% and 22% of the time depending on the correlation structure; even at
T = 100 with an autoregressive root of 0.95 it is well under 50% unless
correlations are high. The 2006 reply is blunter still: at the 44 observations
of the Ford-Jackson-Kline panels, power never exceeds {bf:0.21} when the
mean-reversion coefficient is -0.05, and never exceeds {bf:0.5} at -0.10.
{cmd:suradf} prints a warning when the usable sample is under 60 observations.

{pstd}
So: a {bf:rejection} is informative - the test is conservative in these
settings. A {bf:failure to reject} at short T is weak evidence, and should be
reported as "cannot reject", not as "the series has a unit root". If every
member fails to reject in a short panel, the honest reading is that the test
had little chance of doing otherwise.

{pstd}
Note also that the paper's own simulations find power is generally {it:higher}
when only a few members of the panel are stationary than when all are, because
stationary and non-stationary regressors are asymptotically uncorrelated and the
efficiency gain from SUR is larger. A mixed panel is a good setting for this
test, not a problem for it.

{dlgtab:Reporting checklist}

{pstd}
For a result to be reproducible, report: the panel membership and why;
{it:N}, {it:T} and the usable sample; the lag-selection rule and the chosen
{bf:k} per series; {opt reps()} and {opt seed()}; the AVECOR column; and the
series-specific critical values, not just the statistics. Without the critical
values the statistics are uninterpretable, since no table exists to look them up
in.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:suradf} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of series (equations){p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(Teff)}}usable observations per equation{p_end}
{synopt:{cmd:r(kmax)}}largest lag order used{p_end}
{synopt:{cmd:r(reps)}}replications{p_end}
{synopt:{cmd:r(burn)}}burn-in observations{p_end}
{synopt:{cmd:r(avecor)}}average off-diagonal residual correlation{p_end}
{synopt:{cmd:r(nI0)}}series rejecting the unit root at 5%{p_end}
{synopt:{cmd:r(nI1)}}series not rejecting at 5%{p_end}
{synopt:{cmd:r(ptdrop)}}1 if {opt adfpretest} excluded any series, 0 otherwise{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:suradf}{p_end}
{synopt:{cmd:r(depvar)}}variable(s) tested{p_end}
{synopt:{cmd:r(lags)}}lag-selection rule used{p_end}
{synopt:{cmd:r(dist)}}innovation distribution used{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}{it:N} x 8: k, AVECOR, ADF, SURADF, cv1, cv5, cv10, p{p_end}
{synopt:{cmd:r(stat)}}{it:N} x 1 SURADF statistics{p_end}
{synopt:{cmd:r(cv)}}{it:N} x 3 series-specific critical values{p_end}
{synopt:{cmd:r(corr)}}{it:N} x {it:N} residual correlation matrix{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Renewable energy consumption in six ASEAN economies, 1990-2024:{p_end}
{phang2}{cmd:. use suradf_asean6}{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. suradf rec, seed(20021128)}{p_end}

{pstd}With the paper's own number of replications, and the decision plot:{p_end}
{phang2}{cmd:. suradf rec, reps(10000) seed(20021128) graph}{p_end}

{pstd}Fix the lag order at one for every series, and compare:{p_end}
{phang2}{cmd:. suradf rec, lags(1) seed(20021128)}{p_end}

{pstd}Different orders per series, in output order:{p_end}
{phang2}{cmd:. suradf rec, lags(2 1 1 3 0 2) seed(20021128)}{p_end}

{pstd}Wide form, four series declared with {helpb tsset}:{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. suradf lrer_uk lrer_fr lrer_de lrer_jp, seed(1) graph distplot}{p_end}

{pstd}Robustness: resample the residuals instead of assuming normality:{p_end}
{phang2}{cmd:. suradf rec, dist(bootstrap) reps(5000) seed(20021128)}{p_end}

{pstd}Recover the verdict programmatically:{p_end}
{phang2}{cmd:. suradf rec, seed(1) notable}{p_end}
{phang2}{cmd:. display "stationary members: " r(nI0) " of " r(N)}{p_end}
{phang2}{cmd:. matrix list r(table)}{p_end}


{marker refs}{...}
{title:References}

{phang}
Breuer, J. B., R. McNown, and M. Wallace. 2001. Misleading inferences from panel
unit-root tests with an illustration from purchasing power parity.
{it:Review of International Economics} 9(3): 482-493.
{browse "https://doi.org/10.1111/1467-9396.00294":doi:10.1111/1467-9396.00294}

{phang}
Breuer, J. B., R. McNown, and M. Wallace. 2002. Series-specific unit root tests
with panel data. {it:Oxford Bulletin of Economics and Statistics} 64(5):
527-546.
{browse "https://doi.org/10.1111/1468-0084.00276":doi:10.1111/1468-0084.00276}

{phang}
Breuer, J. B., R. McNown, and M. Wallace. 2006. Misleading inferences from panel
unit root tests: a reply. {it:Review of International Economics} 14(3): 512-516.
{browse "https://doi.org/10.1111/j.1467-9396.2006.00588.x":doi:10.1111/j.1467-9396.2006.00588.x}

{phang}
Ford, G. S., J. D. Jackson, and A. D. Kline. 2006. Misleading inferences from
panel unit root tests: a comment. {it:Review of International Economics} 14(3):
508-511.
{browse "https://doi.org/10.1111/j.1467-9396.2006.00592.x":doi:10.1111/j.1467-9396.2006.00592.x}

{phang}
Taylor, M. P., and L. Sarno. 1998. The behavior of real exchange rates during
the post-Bretton Woods period. {it:Journal of International Economics} 46(2):
281-312.

{phang}
West, K. D. 1988. Asymptotic normality when regressors have a unit root.
{it:Econometrica} 56(6): 1397-1418.
{browse "https://doi.org/10.2307/1912517":doi:10.2307/1912517}

{phang}
Zellner, A. 1962. An efficient method of estimating seemingly unrelated
regressions and tests for aggregation bias.
{it:Journal of the American Statistical Association} 57(298): 348-368.

{pstd}
See {helpb suradf_methods:help suradf methods} for the equation-by-equation
derivation and the map from each step of the algorithm to the paper.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Comments and bug reports are welcome.


{title:Also see}

{psee}
Manual: {manlink R sureg}, {manlink TS dfuller}, {manlink XT xtunitroot}

{psee}
Help: {manhelp sureg R}, {manhelp dfuller TS}, {manhelp xtunitroot XT},
{helpb suradf_methods:suradf methods}
