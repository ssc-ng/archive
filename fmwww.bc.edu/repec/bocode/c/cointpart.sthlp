{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "cointpart methods" "help cointpart_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "egranger (if installed)" "help egranger"}{...}
{vieweralsosee "radf (if installed)" "help radf"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "cointpart##syntax"}{...}
{viewerjumpto "Description" "cointpart##description"}{...}
{viewerjumpto "Options" "cointpart##options"}{...}
{viewerjumpto "Interpreting the output" "cointpart##output"}{...}
{viewerjumpto "Remarks and practical guidance" "cointpart##remarks"}{...}
{viewerjumpto "Examples" "cointpart##examples"}{...}
{viewerjumpto "Stored results" "cointpart##results"}{...}
{viewerjumpto "References" "cointpart##references"}{...}
{viewerjumpto "Author" "cointpart##author"}{...}

{title:Title}

{phang}
{bf:cointpart} {hline 2} Cointegration by Parts: FIEG, BIEG and GIEG tests for
cointegration over part of the sample


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:cointpart} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{pstd}
{it:depvar} and {it:indepvars} must be {help tsvarlist:time-series operated}
numeric variables, and the data must be {helpb tsset}. The sample must be
gap free.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth cas:e(string)}}deterministic specification: {cmd:n}, {cmd:c} (default) or {cmd:ct}{p_end}
{synopt :{opt tr:im(#)}}minimum window as a fraction of {it:T}; default {cmd:trim(0.15)}{p_end}

{syntab:Lag selection}
{synopt :{opt crit:erion(string)}}{cmd:bic} (default), {cmd:sic} (= {cmd:bic}) or {cmd:aic}{p_end}
{synopt :{opt maxl:ag(#)}}cap on the ADF lag order; default is Schwert's rule{p_end}
{synopt :{opt dof:ratio(#)}}require {it:n_eff} >= {it:#}({it:p}+1) in each ADF regression; default {cmd:dofratio(4)}{p_end}

{syntab:Inference}
{synopt :{opt reps(#)}}simulate p-values from {it:#} draws of the null DGP; default {cmd:reps(0)}{p_end}
{synopt :{opt se:ed(#)}}random-number seed for {opt reps()}{p_end}

{syntab:Reporting}
{synopt :{opt beta:s}}report the cointegrating vector re-estimated on each minimizing window{p_end}
{synopt :{opt pre:fix(string)}}save the FIEG and BIEG statistic sequences as variables{p_end}
{synopt :{opt gr:aph}}plot the statistic sequences with the critical value and the GIEG window{p_end}
{synopt :{opt name(string)}}name for the graph; default {cmd:name(cointpart)}{p_end}
{synopt :{opt notab:le}}suppress the output table{p_end}
{synoptline}


{marker description}{title:Description}

{pstd}
{cmd:cointpart} tests whether two or more I(1) series cointegrate over {it:part}
of the sample rather than throughout it. It implements the three statistics of
{help cointpart##KV2026:Kvist and Vera-Valdes (2026)}, each an infimum of the
Engle-Granger statistic taken over a different family of windows:

{p 8 12 2}
{bf:FIEG} {hline 1} the {it:forward-infimum} statistic. Windows start at the
first observation and the endpoint varies, so the search is recursive.

{p 8 12 2}
{bf:BIEG} {hline 1} the {it:backward-infimum} statistic. Windows end at the last
observation and the start point varies.

{p 8 12 2}
{bf:GIEG} {hline 1} the {it:generalized-infimum} statistic. Both endpoints vary,
so the search is doubly flexible.

{pstd}
The hypotheses are

{p 8 12 2}
{bf:H0}: the series do not cointegrate {it:anywhere} in the sample; the residual
of the cointegrating regression has a unit root throughout.

{p 8 12 2}
{bf:H1}: they cointegrate over {it:some} subinterval, of length at least
{cmd:trim()} as a fraction of {it:T}.

{pstd}
Within each candidate window the cointegrating vector is re-estimated by OLS,
an augmented Dickey-Fuller regression is run on that window's residuals, and the
resulting t-statistic is recorded. Because more negative statistics are stronger
evidence against a unit root, the infimum locates the stretch of the sample over
which the evidence for a long-run relationship is strongest. A single scan yields
all three statistics, since the FIEG and BIEG window sets are subsets of the GIEG
window set.

{pstd}
A rejection therefore says two things: that a cointegrating relationship is
present somewhere, and where the evidence for it is concentrated. It does
{it:not} say that a relationship which once held has since broken down {hline 2}
that is a different hypothesis, and this test does not address it. See
{helpb cointpart_methods:help cointpart methods} for the derivation, the
step-to-equation map, and the limitations in full.

{pstd}
All three statistics have non-standard limiting distributions, and the critical
values are far more negative than those of a single-window Engle-Granger test:
at {it:T} = 200 with one regressor and a constant, the 5% value is about
{bf:-4.39} for FIEG and {bf:-6.00} for GIEG, against roughly {bf:-3.37} for the
static test. A subsample search cannot be conducted with off-the-shelf
Engle-Granger critical values.


{marker options}{title:Options}

{dlgtab:Model}

{phang}
{opth case(string)} sets the deterministic component of the cointegrating
regression, following equation (3.2) of the paper:

{p 12 16 2}
{cmd:n} {hline 1} no deterministic term, so the relation is forced through the
origin. Rarely appropriate, because the levels of the series usually have an
arbitrary origin. No critical values are tabulated for this case.

{p 12 16 2}
{cmd:c} {hline 1} a constant. The default, and the specification underlying most
of the published tabulation.

{p 12 16 2}
{cmd:ct} {hline 1} a constant and a linear trend. {bf:Required when the series
are integrated with drift.} Under {cmd:case(c)} the two drifts dominate the
regression, the OLS estimator converges to the ratio of the drifts rather than
to the cointegrating parameter, and critical values calibrated on driftless
random walks no longer apply. Test your series for drift before choosing.

{phang}
{opt trim(#)} sets the minimum window length to floor({it:#} * {it:T})
observations. The default, 0.15, is the convention of the parameter-instability
literature ({help cointpart##Andrews1993:Andrews 1993}) and is the value the
tabulated critical values are indexed by; any other value suppresses them. The
fraction is applied as a pure fraction, with no floor in observations, because a
fixed floor would let the effective fraction drift with {it:T}. A cointegration
episode shorter than {cmd:trim()} is contained in no admissible window, and no
test in this class has power against it.

{dlgtab:Lag selection}

{phang}
{opt criterion(string)} selects the information criterion used to choose the ADF
lag order within each window: {cmd:bic} (the default, and what the paper uses),
{cmd:sic} (a synonym for {cmd:bic}), or {cmd:aic}. Candidate orders are always
scored on a {it:common} sample {hline 2} the one available at the largest
candidate order {hline 2} so that the criterion compares likelihoods over
identical observations.

{phang}
{opt maxlag(#)} caps the ADF lag order. By default the cap is Schwert's rule,
floor(12 ({it:n}/100){c 94}0.25), applied to the {it:window} length {it:n} and
not to the full sample. Set {opt maxlag()} only to tighten that cap; the
tabulated critical values assume the default.

{phang}
{opt dofratio(#)} requires each ADF regression to retain at least
{it:#}({it:p}+1) usable observations, reducing the order until it does. The
default of 4 is the paper's rule. Without it Schwert's bound assigns eight lags
to a twenty-observation window, leaving two residual degrees of freedom.

{dlgtab:Inference}

{phang}
{opt reps(#)} computes a p-value for each statistic by simulating {it:#} draws
from the null data-generating process of section 4.1 {hline 2} independent
driftless random walks of the same length and dimension {hline 2} and reporting
the fraction of draws whose statistic is at least as negative as the observed
one. The {it:entire} statistic is recomputed on every draw, scan and lag
selection included, because the observed statistic's search advantage must be
reproduced or the test over-rejects. This is expensive: each replication costs a
full scan. See {it:Remarks} below on why a simulated p-value is offered instead
of a lookup.

{phang}
{opt seed(#)} sets the random-number seed, so that a {opt reps()} p-value is
reproducible.

{dlgtab:Reporting}

{phang}
{opt betas} additionally reports the cointegrating vector re-estimated on each
of the three minimizing windows. The paper recommends this as the first
diagnostic for distinguishing cointegration over part of the sample from a
relationship that holds throughout but whose coefficients shift; see
{it:Remarks}.

{phang}
{opt prefix(string)} creates two new variables, {it:string}{cmd:_fieg} and
{it:string}{cmd:_bieg}, holding the forward- and backward-infimum statistic
sequences. {it:string}{cmd:_bieg} is the more useful of the two: its minimum
over the sample is the GIEG statistic and its last value is the BIEG statistic,
so it is the natural object to plot and to date-stamp from. The command stops
rather than overwrite existing variables.

{phang}
{opt graph} plots both sequences against the time variable, marks the GIEG 5%
critical value with a horizontal dashed line, and marks the GIEG window with
vertical lines. {opt name(string)} names the graph; a trailing {cmd:, replace}
is accepted and ignored, since the graph is always drawn with {cmd:replace}.

{phang}
{opt notable} suppresses the table, leaving only the stored results.


{marker output}{title:Interpreting the output}

{pstd}
The header reports the sample size, the number of regressors {it:N}, the
deterministic case, the lag criterion, the trimming fraction, the resulting
minimum window in observations, and how many windows were scanned. A line
reporting {it:degenerate windows skipped} appears only if some window could not
support the regression; a non-zero count there is worth investigating, since it
usually means near-collinearity or a near-constant stretch.

{pstd}
The table then gives one row per statistic:

{p 8 12 2}
{bf:Statistic} {hline 1} the infimum of the Engle-Granger t-statistic over that
statistic's window family. More negative is stronger evidence. Stars mark
rejection at the 10%, 5% and 1% levels.

{p 8 12 2}
{bf:1% / 5% / 10%} {hline 1} critical values from the MacKinnon-type response
surfaces of the paper's table 3, evaluated at the sample size in hand. {bf:The
test is left tailed: reject when the statistic is at or below the critical
value.} These columns are blank, with the reason printed, whenever the
tabulation does not cover the configuration.

{p 8 12 2}
{bf:Window} {hline 1} the window that attains the infimum, in the units of the
time variable. By construction the FIEG window always starts at the first
observation and the BIEG window always ends at the last; only the GIEG window is
free at both ends.

{pstd}
With {opt reps()} a {bf:p-value} column is inserted, holding the simulated
probability under the null of a statistic at least as negative as the observed
one.

{pstd}
Note on precision: the critical values are computed from the response-surface
coefficients {it:as printed} in the paper's table 3, which are themselves
rounded. Reproducing the paper's own table 5 from them agrees to within 0.001,
which is the accumulated rounding, not a difference in method.


{marker remarks}{title:Remarks and practical guidance}

{pstd}
{bf:Choosing among the three statistics.} This is the single most consequential
choice, because picking the wrong direction {it:eliminates} power rather than
merely reducing it. By proposition A.1 of the paper, FIEG has power only when
the cointegrating episode begins at the start of the sample, and BIEG only when
it runs to the end; GIEG has power in either case. Use FIEG or BIEG only where
directional prior knowledge is genuinely available {hline 2} FIEG if the
relationship is believed to hold from the outset and break down later, BIEG if it
is believed to hold now but not at the beginning. {bf:Use GIEG whenever the
location of the episode is in doubt.}

{pstd}
{bf:But GIEG is not the safe default.} Consistency is an asymptotic property and
is not the same as finite-sample power. Because GIEG searches both endpoints it
pays a much larger critical-value penalty, and in each one-sided statistic's own
favourable direction it is the {it:weaker} test. In the Monte Carlo shipped as
{bf:cointpart_example.do} {hline 2} 60 replications at {it:T} = 120, a break at
mid-sample, 5% nominal {hline 2} the rejection rates are:

{p 8 8 2}
forward break{col 30}FIEG 0.98{col 44}BIEG 0.07{col 58}GIEG 0.28{break}
reverse break{col 30}FIEG 0.17{col 44}BIEG 0.95{col 58}GIEG 0.53{break}
middle window{col 30}FIEG 0.30{col 44}BIEG 0.17{col 58}GIEG 0.48

{pstd}
Read across the first two rows and proposition A.1 is visible: the wrong
direction has no power to lose. Read down the GIEG column and the price of
generality is visible too. GIEG wins only in the third row, where no one-sided
search set contains a clean window. Note also that FIEG and BIEG are not
powerless there: at this sample size their windows still overlap much of the
stationary stretch, so inconsistency bites as {it:T} grows rather than at every
sample size. Choose a one-sided statistic when the direction is genuinely known,
and GIEG when it is not; choosing GIEG "to be safe" costs real power.

{pstd}
{bf:Where the tabulation is valid.} The critical values are reported only for
{it:T} >= 100, {it:N} <= 3 regressors, {cmd:trim(0.15)}, and {cmd:case(c)} or
{cmd:case(ct)}. Outside that region the statistic and its window are still
reported, but the critical values are suppressed and the reason is printed. The
floor at {it:T} = 100 is not cosmetic: the paper documents the test over-rejecting
by up to 0.076 against a nominal 0.05 at {it:T} = 90, where the response surface
is extrapolated rather than interpolated.

{pstd}
{bf:Why p-values are simulated rather than looked up.} The paper builds a
numerical distribution function from response surfaces fitted at 184
probabilities, and states that its replication repository provides them. At the
time of writing the repository does not: it contains the code but none of the
fitted surfaces, and only the three conventional levels are printed in the paper.
{cmd:cointpart} therefore carries the printed surfaces for critical values, and
offers {opt reps()} for an exact simulated p-value. If the authors release the
184-probability table, it can be substituted without changing anything the user
sees.

{pstd}
{bf:Direction of the regression matters.} The test is single-equation and
residual based, so the result depends on which series is on the left-hand side.
In the paper's own application no statistic rejects once the normalization is
reversed. Choose {it:depvar} on substantive grounds {hline 2} a weak-exogeneity
result, or theory {hline 2} not by convenience, and report that you did.

{pstd}
{bf:A rejection does not identify a breakdown.} The null is no cointegration
anywhere, so a rejection localizes evidence {it:for} a relationship. Testing
whether a relationship that once held has since broken down requires the
complementary pairing, with cointegration throughout the sample as the null,
which this command does not provide.

{pstd}
{bf:A rejection is also consistent with a shifted cointegrating vector.} Because
the vector is re-estimated inside every window, a relationship that holds
throughout with coefficients that change at some date can produce the same
rejection as one confined to a sub-period. Use {opt betas} and compare the rows:
coefficients that are stable across the three windows point to a genuine
sub-period, coefficients that move point to instability in the vector itself.
{helpb ghansen} tests the latter hypothesis directly.

{pstd}
{bf:Using the test recursively.} A rejection locates one window, not the only
one. The paper's recommended practice is to remove the located window and re-run
GIEG on each remaining segment, repeating until nothing rejects or the segments
become too short. Two cautions: the tabulated critical values apply to the
{it:first} stage only, because every later segment is selected by the outcome of
the stage before it; and no segment shorter than 100 observations should be
tested at all. On the paper's own sample the remaining segments are 67 and 52
observations, so the honest answer there is that the recursion cannot be run.

{pstd}
{bf:Pre-test for integration.} The framework assumes all series are I(1). Check
with {helpb dfuller} on the levels and on the first differences before running
{cmd:cointpart}; a stationary series invalidates the whole setup.

{pstd}
{bf:Computational cost.} The scan evaluates O({it:T}{c 94}2) windows, each
requiring a window regression and a lag search, so cost grows quickly in {it:T}.
Samples above 2,000 observations are refused; the published tabulation stops
there in any case. If a long sample is unavoidable, raising {cmd:trim()} reduces
the number of admissible windows substantially. With {opt reps()} the cost is
multiplied by the number of replications, so start small and scale up.

{pstd}
{bf:Relation to the bubble-testing literature.} The three statistics are the
left-tailed, residual-based counterparts of the SADF, BSADF and GSADF statistics
of {help cointpart##PSY2015a:Phillips, Shi and Yu (2015a,b)}, which
{helpb radf} implements for the right-tailed, single-series case. The window
families are the same; what differs is that here the object tested is a
cointegrating residual whose coefficient vector must itself be estimated, and
re-estimated in every window. That estimation step is why the critical values
here are not those of the bubble literature.


{marker examples}{title:Examples}

{pstd}
{bf:The paper's application: global mean sea level and surface temperature,
1880-2019.} Both series drift, so {cmd:case(ct)} is the appropriate
specification; temperature is the regressand, following the weak-exogeneity
result of {help cointpart##Schmith2012:Schmith, Johansen and Thejll (2012)}.{p_end}

{phang2}{cmd:. use cointpart_sealevel}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. cointpart temperature sea_level, case(ct)}{p_end}

{pstd}
All three statistics reject at the 5% level, and GIEG places the evidence in
1947-1967 {hline 2} a window that covers the two decades after the wartime
change in sea surface temperature measurement documented by
{help cointpart##Thompson2008:Thompson et al. (2008)}.

{pstd}
{bf:With the diagnostic for a shifted vector, and a plot.}{p_end}

{phang2}{cmd:. cointpart temperature sea_level, case(ct) betas graph}{p_end}

{pstd}
{bf:Robustness to the trimming fraction.} The GIEG window above is exactly as
long as the trimming admits, which makes the result sensitive to that choice;
check it.{p_end}

{phang2}{cmd:. foreach r in 0.10 0.15 0.20 {c -(}}{p_end}
{phang2}{cmd:.         cointpart temperature sea_level, case(ct) trim(`r')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
{bf:The normalization matters; show both.}{p_end}

{phang2}{cmd:. cointpart temperature sea_level, case(ct)}{p_end}
{phang2}{cmd:. cointpart sea_level temperature, case(ct)}{p_end}

{pstd}
{bf:A simulated p-value.} Expensive; raise {opt reps()} once you know how long
one replication takes.{p_end}

{phang2}{cmd:. cointpart temperature sea_level, case(ct) reps(199) seed(20260907)}{p_end}

{pstd}
{bf:Saving the sequences for your own graph.} {cmd:cbp_bieg} has the GIEG
statistic as its minimum and the BIEG statistic as its last value.{p_end}

{phang2}{cmd:. cointpart temperature sea_level, case(ct) prefix(cbp)}{p_end}
{phang2}{cmd:. twoway line cbp_bieg year, yline(`=r(cv)[3,2]')}{p_end}

{pstd}
{bf:Three regressors, a constant only.}{p_end}

{phang2}{cmd:. cointpart y x1 x2 x3, case(c)}{p_end}

{pstd}
A fuller, self-checking demonstration ships with the package as
{bf:cointpart_example.do}; retrieve it with {stata "net get cointpart"}.


{marker results}{title:Stored results}

{pstd}
{cmd:cointpart} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(nreg)}}number of regressors {it:N}{p_end}
{synopt:{cmd:r(trim)}}trimming fraction{p_end}
{synopt:{cmd:r(minwin)}}minimum window, in observations{p_end}
{synopt:{cmd:r(nwindows)}}number of windows scanned{p_end}
{synopt:{cmd:r(nmissing)}}degenerate windows skipped{p_end}
{synopt:{cmd:r(reps)}}replications used for the simulated p-values{p_end}
{synopt:{cmd:r(fieg)}, {cmd:r(bieg)}, {cmd:r(gieg)}}the three statistics{p_end}
{synopt:{cmd:r(fieg_t1)}, {cmd:r(fieg_t2)}}FIEG window, in time-variable units{p_end}
{synopt:{cmd:r(bieg_t1)}, {cmd:r(bieg_t2)}}BIEG window{p_end}
{synopt:{cmd:r(gieg_t1)}, {cmd:r(gieg_t2)}}GIEG window{p_end}
{synopt:{cmd:r(p_fieg)}, {cmd:r(p_bieg)}, {cmd:r(p_gieg)}}simulated p-values, with {opt reps()}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointpart}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(case)}}deterministic case{p_end}
{synopt:{cmd:r(criterion)}}lag criterion used{p_end}
{synopt:{cmd:r(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:r(indepvars)}}names of {it:indepvars}{p_end}
{synopt:{cmd:r(timevar)}}time variable from {helpb tsset}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(cv)}}3 x 3 critical values (rows FIEG, BIEG, GIEG; columns 1%, 5%, 10%){p_end}
{synopt:{cmd:r(pvalue)}}3 x 1 simulated p-values, with {opt reps()}{p_end}
{synopt:{cmd:r(beta)}}3 x ({it:k}) cointegrating vector on each minimizing window{p_end}
{synopt:{cmd:r(windows)}}({it:nwindows}) x 5 matrix: start, end, length, statistic, selected lag, for every window scanned{p_end}
{p2colreset}{...}

{pstd}
{cmd:r(windows)} is the full scan. It is what the {opt prefix()} sequences are
condensed from, and it lets you reconstruct any window-level quantity yourself.


{marker references}{title:References}

{marker Andrews1993}{...}
{phang}
Andrews, D. W. K. 1993. Tests for Parameter Instability and Structural Change
With Unknown Change Point. {it:Econometrica} 61: 821-856.
{browse "https://doi.org/10.2307/2951764":doi:10.2307/2951764}

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Co-Integration and Error Correction:
Representation, Estimation, and Testing. {it:Econometrica} 55: 251-276.
{browse "https://doi.org/10.2307/1913236":doi:10.2307/1913236}

{marker GH1996}{...}
{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in
models with regime shifts. {it:Journal of Econometrics} 70: 99-126.
{browse "https://doi.org/10.1016/0304-4076(69)41685-7":doi:10.1016/0304-4076(69)41685-7}

{marker KV2026}{...}
{phang}
Kvist, O., and J. E. Vera-Valdes. 2026. Cointegration by Parts: Locating
Cointegration in Time. Submitted to {it:Econometric Reviews}.
{browse "https://arxiv.org/abs/2609.10020":arXiv:2609.10020}

{phang}
MacKinnon, J. G. 1994. Approximate Asymptotic Distribution Functions for
Unit-Root and Cointegration Tests. {it:Journal of Business & Economic Statistics}
12: 167-176.
{browse "https://doi.org/10.2307/1391481":doi:10.2307/1391481}

{phang}
MacKinnon, J. G. 2010. Critical Values for Cointegration Tests. Queen's Economics
Department Working Paper No. 1227.

{marker Otero2021}{...}
{phang}
Otero, J., and C. F. Baum. 2021. Unit-root tests for explosive behavior.
{it:Stata Journal} 21: 999-1020.
{browse "https://doi.org/10.1177/1536867X211063405":doi:10.1177/1536867X211063405}

{marker PSY2015a}{...}
{phang}
Phillips, P. C. B., S. Shi, and J. Yu. 2015a. Testing for Multiple Bubbles:
Historical Episodes of Exuberance and Collapse in the S&P 500.
{it:International Economic Review} 56: 1043-1078.
{browse "https://doi.org/10.1111/iere.12132":doi:10.1111/iere.12132}

{phang}
Phillips, P. C. B., S. Shi, and J. Yu. 2015b. Testing for Multiple Bubbles: Limit
Theory of Real-Time Detectors. {it:International Economic Review} 56: 1079-1134.
{browse "https://doi.org/10.1111/iere.12131":doi:10.1111/iere.12131}

{marker Schmith2012}{...}
{phang}
Schmith, T., S. Johansen, and P. Thejll. 2012. Statistical Analysis of Global
Surface Temperature and Sea Level Using Cointegration Methods.
{it:Journal of Climate} 25: 7822-7833.
{browse "https://doi.org/10.1175/JCLI-D-11-00598.1":doi:10.1175/JCLI-D-11-00598.1}

{phang}
Schwert, G. W. 1989. Tests for Unit Roots: A Monte Carlo Investigation.
{it:Journal of Business & Economic Statistics} 7: 147-159.
{browse "https://doi.org/10.2307/1391432":doi:10.2307/1391432}

{marker Thompson2008}{...}
{phang}
Thompson, D. W. J., J. J. Kennedy, J. M. Wallace, and P. D. Jones. 2008. A large
discontinuity in the mid-twentieth century in observed global-mean surface
temperature. {it:Nature} 453: 646-649.
{browse "https://doi.org/10.1038/nature06982":doi:10.1038/nature06982}

{pstd}
The full reference list, with the role each result plays in the derivation, is in
{helpb cointpart_methods:help cointpart methods}.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Comments and bug reports are welcome. The command was validated against the
authors' own R and C++ reference implementation, window by window, across all
three deterministic specifications and {it:N} = 1, 2 and 3.
