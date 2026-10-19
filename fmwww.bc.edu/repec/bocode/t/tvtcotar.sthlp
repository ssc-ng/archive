{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{viewerjumpto "Syntax" "tvtcotar##syntax"}{...}
{viewerjumpto "Description" "tvtcotar##description"}{...}
{viewerjumpto "Reading m and c" "tvtcotar##mc"}{...}
{viewerjumpto "Options" "tvtcotar##options"}{...}
{viewerjumpto "The test, and which row to read" "tvtcotar##test"}{...}
{viewerjumpto "Things the paper's code settles" "tvtcotar##choices"}{...}
{viewerjumpto "Examples" "tvtcotar##examples"}{...}
{viewerjumpto "Stored results" "tvtcotar##results"}{...}
{viewerjumpto "Validation" "tvtcotar##validation"}{...}
{viewerjumpto "References" "tvtcotar##references"}{...}
{viewerjumpto "Author" "tvtcotar##author"}{...}
{title:Title}

{phang}
{bf:tvtcotar} {hline 2} Conditional threshold autoregression: a threshold
that tracks the recent past


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtcotar} {depvar} {ifin}{cmd:,} {opt mem:ory(#)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt mem:ory(#)}}length {it:m} of the rolling window{p_end}
{synopt :{opth thr:eshvar(varname)}}threshold variable; default is
{depvar} itself{p_end}
{synopt :{opt lags(#)}}AR order {it:p}; default {cmd:lags(1)}{p_end}
{synopt :{opt d:elays(numlist)}}candidate delays; default
{cmd:delays(1 2 3)}{p_end}
{synopt :{opt trim(#)}}minimum regime share; default {cmd:trim(0.15)}{p_end}
{synopt :{opt reps(#)}}bootstrap replications; default {cmd:reps(0)}, which
gives {bf:no p-values}{p_end}
{synopt :{opt norob:ust}}non-robust covariance{p_end}
{synopt :{opt level(#)}}confidence level for the coefficient table{p_end}
{synoptline}
{p 4 6 2}* {opt memory()} is required.{p_end}
{p 4 6 2}
The series must be contiguous in time; a gapped sample is refused.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtcotar} fits a two-regime autoregression in which the threshold is
{bf:not a constant and not a function of the clock}, but an empirical
quantile of the threshold variable's own recent past:

{p 8 8 2}
{it:y_t} = {it:a1} + {it:phi_1}({it:L}){it:y_t} + {it:u_t}{space 3}if
{it:x_{c -(}t-d{c )-}} < {it:mu}{c -(}{it:t-d-1}{c )-}({it:c}){break}
{it:y_t} = {it:a2} + {it:phi_2}({it:L}){it:y_t} + {it:u_t}{space 3}otherwise

{pstd}
where {it:mu_t}({it:c}) is the ({it:m}{bf:·}{it:c})-th smallest of the last
{it:m} values of {it:x}. So the boundary between regimes moves with the
data.

{pstd}
{bf:Why that is a different idea from the rest of this library.} A Fourier
or shift specification says the threshold moved {it:on a date}. This says it
moves {it:with the series}: what counts as a high value of {it:x} is judged
against what {it:x} has recently been doing. If the story is "the regime
switches when the variable is unusual by recent standards" rather than
"something changed in 1998", this is the specification for it.

{pstd}
By default {it:x} = {depvar}, the {bf:self-exciting} case, in which the
series thresholds itself.

{pstd}
As {it:m} grows the rolling quantile stabilises and the model tends to an
ordinary threshold autoregression. At {it:m} = 1 it degenerates into a
threshold model in the {it:differenced} threshold variable with a known
threshold of zero, which is a different model, so {cmd:tvtcotar} refuses it.


{marker mc}{...}
{title:Reading m and c}

{pstd}
These two numbers carry the whole idea, and they are worth reading together.

{phang}
{bf:m} is how far back "recent" reaches. It is {bf:your choice, not
estimated} {hline 2} the paper treats it as known, and so does this command.
Choose it from the substance: a month of daily data, a business cycle of
quarterly data. A large {it:m} makes the threshold nearly constant; a small
one makes it jumpy.

{phang}
{bf:c} is {bf:how unusual} a value has to be. It is estimated, over the grid
{it:1/m}, {it:2/m}, ..., 1.

{pmore}
{it:c} near the middle makes the threshold the {bf:local median}: the regime
switch asks whether {it:x} is above or below its recent normal, and both
regimes are busy.

{pmore}
{it:c} near {it:1/m} or 1 makes the threshold a {bf:local extreme}: the
switch fires only when {it:x} is unusual by recent standards, so one regime
is rare and is identified by few observations. The {opt trim()} rule keeps
that from going too far.

{pstd}
So a fitted {it:c} of 0.5 says "it matters whether the variable is above or
below its recent middle", while a fitted {it:c} of 0.9 says "only a locally
high value changes the dynamics". That is a substantive finding and worth
reporting as one.


{marker options}{...}
{title:Options}

{phang}
{opt memory(#)} sets {it:m}. Required, and at least 2.

{phang}
{opth threshvar(varname)} gives {it:x}. Omit it for the self-exciting case,
which is the paper's main object.

{phang}
{opt lags(#)} is the AR order {it:p}, the same in both regimes.

{phang}
{opt delays(numlist)} lists candidate delays {it:d}. The paper uses
{cmd:delays(1 2 3)} throughout its simulations.

{phang}
{opt trim(#)} is the minimum share of observations each regime must hold for
a candidate ({it:d},{it:c}) to be admissible. The default 0.15 follows the
paper and Andrews (1993). Infeasible candidates are dropped entirely, so
they also leave the {bf:ave} and {bf:exp} denominators.

{phang}
{opt reps(#)} is the number of wild multiplier bootstrap replications.
{bf:The default 0 gives no p-values}, and without them the test statistics
cannot be interpreted {hline 2} see the next section.

{phang}
{opt norobust} uses the non-robust covariance. The paper uses the
heteroskedasticity-robust form throughout, even where its own simulations
have homoskedastic errors, and that is the default here.


{marker test}{...}
{title:The test, and which row to read}

{pstd}
Every fit reports a test of {bf:no threshold effect}: the null that the two
regimes share one AR({it:p}). Under that null the threshold parameters
({it:d},{it:c}) {bf:do not appear in the model at all}, so they are
unidentified and the statistics have non-standard distributions. They
{bf:cannot} be compared with a chi-squared table. Set {opt reps()} to get
bootstrap p-values.

{pstd}
Six statistics are reported: {bf:Wald} and {bf:LM}, each summarised over the
({it:d},{it:c}) grid by {bf:sup}, {bf:ave} and {bf:exp}.

{pstd}
{bf:Prefer the LM row.} This is not a stylistic preference. In the paper's
own Table 1, at a nominal 5%:

{p2colset 8 32 34 2}{...}
{p2col :}{it:n}=125{space 5}250{space 5}500{space 4}1000{p_end}
{p2col :sup-Wald}0.197{space 3}0.100{space 3}0.070{space 3}0.068{p_end}
{p2col :ave-Wald}0.120{space 3}0.085{space 3}0.064{space 3}0.058{p_end}
{p2col :sup-LM}0.045{space 3}0.026{space 3}0.041{space 3}0.054{p_end}
{p2col :ave-LM}0.040{space 3}0.044{space 3}0.046{space 3}0.049{p_end}
{p2colreset}{...}

{pstd}
The Wald functionals over-reject substantially in short samples {hline 2}
sup-Wald rejects a true null nearly four times too often at {it:n} = 125
{hline 2} while the LM versions sit near nominal throughout. A separate
paper by two of the same authors is devoted to this over-rejection.

{pstd}
{bf:On the bootstrap.} It is a {bf:multiplier} bootstrap, not a data
bootstrap: no pseudo-series is generated and {bf:nothing is re-estimated}.
The scores and covariance matrices are computed once, and only the normal
multipliers are redrawn, with the {bf:same draw shared across the whole
grid} so that the dependence across ({it:d},{it:c}) is preserved. That is
what makes the sup, ave and exp distributions right. It is deliberately
unlike the bootstrap in {helpb tvtfourier}, which must re-run its search
because the observed statistic there selected a frequency.


{marker choices}{...}
{title:Things the paper's code settles}

{pstd}
Several choices are not in the paper but are visible in the authors' own
MATLAB, and they change the numbers. This command follows the code, so that
its results match theirs:

{phang}
{bf:The quantile is a raw order statistic.} The window is sorted and the
{it:floor}({it:m}{bf:·}{it:c})-th element taken: no interpolation. Stata's
own {helpb _pctile} and {helpb centile} interpolate by default and would
{bf:not} reproduce these numbers.

{phang}
{bf:The effective sample depends on the delay.} Observations lost at the
start are {it:max}({it:p}, {it:m}+{it:d}), so the sums of squares compared
across the grid are computed on {bf:different-length samples} as {it:d}
varies. That is a property of the published procedure, not an error here,
and "fixing" it would stop the results matching the authors'. It is
reproduced and reported: {cmd:e(N_eff)} is the length at the selected
({it:d},{it:c}).

{phang}
{bf:The reported standard errors and the test statistics use different
normalisations} {hline 2} the reporting path divides by the effective
sample, the test path by the full one. Again the authors' own convention.
Do not expect {cmd:e(V)} and the Wald statistic to sit on a common scale.

{pstd}
{bf:No confidence interval is reported for} {it:d} {bf:or} {it:c}, because
the paper does not derive their asymptotic distribution. Reporting one would
be inventing it.


{marker examples}{...}
{title:Examples}

{pstd}Self-exciting, a window of six, AR(1).{p_end}
{phang2}{cmd:. tvtcotar y, memory(6)}{p_end}

{pstd}With bootstrap p-values.{p_end}
{phang2}{cmd:. tvtcotar y, memory(6) reps(500)}{p_end}

{pstd}A longer memory, AR(2), and a wider set of delays.{p_end}
{phang2}{cmd:. tvtcotar y, memory(12) lags(2) delays(1/5) reps(500)}{p_end}

{pstd}An external threshold variable rather than the series itself.{p_end}
{phang2}{cmd:. tvtcotar y, threshvar(x) memory(10) reps(500)}{p_end}

{pstd}Is the fitted percentile a local median or a local extreme?{p_end}
{phang2}{cmd:. display e(c)}{p_end}

{pstd}Compare memories before settling on one.{p_end}
{phang2}{cmd:. foreach m in 4 6 12 24 {c -(}}{p_end}
{phang2}{cmd:.     quietly tvtcotar y, memory(`m')}{p_end}
{phang2}{cmd:.     display "`m'  c=" e(c) "  d=" e(d) "  ssr=" e(ssr)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtcotar} is {bf:e-class}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations in the sample{p_end}
{synopt:{cmd:e(N_eff)}}observations actually used at the selected
({it:d},{it:c}){p_end}
{synopt:{cmd:e(d)}, {cmd:e(c)}, {cmd:e(memory)}}the threshold
parameters{p_end}
{synopt:{cmd:e(share_lo)}}share of observations below the rolling
quantile{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(sigma2)}}fit at the selected
({it:d},{it:c}){p_end}
{synopt:{cmd:e(supW)}, {cmd:e(aveW)}, {cmd:e(expW)}}Wald functionals{p_end}
{synopt:{cmd:e(supLM)}, {cmd:e(aveLM)}, {cmd:e(expLM)}}LM functionals{p_end}
{synopt:{cmd:e(p_supW)} ... {cmd:e(p_expLM)}}bootstrap p-values, when
{opt reps()} is set{p_end}
{synopt:{cmd:e(n_feasible)}, {cmd:e(n_grid)}}feasible and total grid
points{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtcotar}{p_end}
{synopt:{cmd:e(threshvar)}}the threshold variable{p_end}
{synopt:{cmd:e(delays)}}the delay candidates searched{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients, {bf:below} regime then
{bf:above}{p_end}
{synopt:{cmd:e(grid)}}one row per ({it:d},{it:c}): feasibility, effective
{it:n}, SSR, Wald, LM{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
The authors ship their MATLAB, so this implementation is checked against it
directly rather than against a printed table. Their code was run on a fixed
sample to produce a reference lock, and this clean-room Stata version
reproduces, on that same sample, {bf:all six test statistics, the selected
({it:d},{it:c}), the effective sample size, the error variance and every
coefficient, to within 3e-13} {hline 2} floating-point noise. The feasible
grid count matches exactly.

{pstd}
The bootstrap p-values are deliberately not part of that lock: they depend
on MATLAB's own random stream and no Stata implementation can match it
draw-for-draw. The statistics are what must agree.

{pstd}
No line of the authors' code is used here; the archive carries no licence,
so it is treated as all-rights-reserved and was read and run only. See
{bf:validation/tvthresh/tvtcotar_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Motegi, K., J. W. Dennis, and S. Hamori. 2024. Conditional Threshold
Autoregression (CoTAR). SSRN Working Paper No. 3960058.
{browse "https://doi.org/10.2139/ssrn.3960058":doi:10.2139/ssrn.3960058}

{phang}
Andrews, D. W. K. 1993. Tests for parameter instability and structural
change with unknown change point. {it:Econometrica} 61(4): 821-856.
{browse "https://doi.org/10.2307/2951764":doi:10.2307/2951764}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64(2): 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Tong, H., and K. S. Lim. 1980. Threshold autoregression, limit cycles and
cyclical data. {it:Journal of the Royal Statistical Society, Series B}
42(3): 245-292.
{browse "https://doi.org/10.1111/j.2517-6161.1980.tb01126.x":doi:10.1111/j.2517-6161.1980.tb01126.x}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb tvtfourier},
{helpb tvtlr}
{p_end}
