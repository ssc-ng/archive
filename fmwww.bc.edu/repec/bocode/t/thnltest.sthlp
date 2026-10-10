{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thstar" "help thstar"}{...}
{viewerjumpto "Syntax" "thnltest##syntax"}{...}
{viewerjumpto "Description" "thnltest##description"}{...}
{viewerjumpto "Options" "thnltest##options"}{...}
{viewerjumpto "Which test has power against what" "thnltest##power"}{...}
{viewerjumpto "The arranged autoregression" "thnltest##arranged"}{...}
{viewerjumpto "The CUSUM, and what it is not" "thnltest##cusum"}{...}
{viewerjumpto "Searching the delay" "thnltest##delay"}{...}
{viewerjumpto "Two or more variables" "thnltest##multi"}{...}
{viewerjumpto "Where this fits in the workflow" "thnltest##workflow"}{...}
{viewerjumpto "Examples" "thnltest##examples"}{...}
{viewerjumpto "Stored results" "thnltest##results"}{...}
{viewerjumpto "References" "thnltest##refs"}{...}
{title:Title}

{phang}
{bf:thnltest} {hline 2} Tests of linearity of an autoregression: Keenan, Tsay,
the arranged autoregression and a CUSUM portmanteau


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thnltest} {it:varname} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{pstd}
With {bf:two or more} variables it runs Tsay's (1998) multivariate test
instead; see {help thnltest##multi:below}.

{p 8 15 2}
{cmd:thnltest} {it:varlist} {ifin}{cmd:,} {opt ar(numlist)}
[{opth thv:ar(varlist)} {it:options}]

{pstd}
The data must be {helpb tsset}.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt ar(numlist)}}lags of {it:varname} in the autoregression{p_end}
{synopt:{opt delay(numlist)}}candidate delays for the arranged autoregression;
default: every lag in {opt ar()}{p_end}
{synopt:{opt start:up(#)}}observations used to start the recursion{p_end}
{synopt:{opt reps(#)}}residual-bootstrap replications; default 0 (none){p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synoptline}
{p 4 6 2}* {opt ar()} is required. {cmd:thnltest} is {cmd:rclass}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thnltest} runs four classical tests of whether an autoregression is
linear. It is the command to run {it:before} fitting any threshold model: it
costs nothing, it needs no threshold to be estimated, and if none of its tests
rejects then the case for a two-regime model rests on theory rather than on the
data.

{pstd}
{bf:Keenan (1985)} adds the squared fitted value of the linear autoregression
and tests its single coefficient. {bf:Tsay (1986)} adds every distinct product
of two lags and tests the whole block. Neither needs the data to be put in any
particular order, so neither is aimed at a threshold specifically: both test
against general second-order curvature.

{pstd}
{bf:Tsay (1989)} is the one aimed at a threshold. It orders the observations by
a candidate threshold variable, runs recursive least squares through them in
that order, and regresses the standardised one-step predictive residuals on the
autoregressive regressors. Under linearity the ordering is irrelevant and those
residuals are white noise whatever order you use. Under a threshold the
recursion is still fitting the first regime when the ordering crosses the
threshold, so the residuals acquire a systematic relation to the regressors,
which is what the F statistic picks up. The {bf:CUSUM} portmanteau is computed
from the same recursive residuals and looks for the same thing in a different
way: a drift in their cumulative sum.


{marker options}{...}
{title:Options}

{phang}
{opt ar(numlist)} lists the lags of {it:varname} in the autoregression, and
they need not be consecutive: {cmd:ar(1 2 12)} is allowed. Choose the lag set
first, from the linear model, exactly as you would for any autoregression. A
nonlinearity test on an underspecified lag structure rejects because of the
missing lags.

{phang}
{opt delay(numlist)} gives the candidate delays {it:d} for the arranged
autoregression, so the threshold variable is {it:y_{t-d}}. Every value must be
one of the lags in {opt ar()}, because a lag the model does not contain cannot
order a recursion through its own design. The default is every lag in
{opt ar()}.

{phang}
{opt startup(#)} is the number of arranged observations used to initialise the
recursive least squares before the first predictive residual is formed. The
default follows Tsay's suggestion of roughly one tenth of the sample plus the
number of parameters. Too small a startup makes the early recursive residuals
enormous and noisy; too large wastes observations the test could have used.
Vary it: a conclusion that flips between {cmd:startup(30)} and
{cmd:startup(60)} is not a conclusion.

{phang}
{opt reps(#)} simulates the null distribution of all four statistics with a
{it:residual bootstrap}: the linear autoregression is refitted, its residuals
are resampled, and the series is rebuilt {bf:recursively} from the fitted
autoregression, so each bootstrap sample has the dynamics the null specifies.
Every statistic is then recomputed on it. This is the right bootstrap here
because the null is a fully specified linear autoregression -- unlike the
fixed-regressor bootstrap used in {helpb thtest}, which exists because there
the {it:threshold} is the unidentified parameter.

{phang}
{opt seed(string)} makes the bootstrap reproducible. Always set it.


{marker power}{...}
{title:Which test has power against what}

{synoptset 20}{...}
{p2col 5 20 24 2: test}has power against{p_end}
{p2line}
{p2col 5 20 24 2:Keenan (1985)}a single quadratic direction: the squared fitted
value. One degree of freedom, so it is the most powerful of the four when the
nonlinearity really is in that direction, and nearly powerless otherwise.{p_end}
{p2col 5 20 24 2:Tsay (1986)}any second-order curvature. {it:p}({it:p}+1)/2
degrees of freedom, so it spreads its power widely and loses to Keenan when
Keenan happens to be right.{p_end}
{p2col 5 20 24 2:Tsay (1989)}a threshold at an unknown point in a {it:named}
ordering variable. This is the one to read if you are deciding whether to fit a
threshold model.{p_end}
{p2col 5 20 24 2:CUSUM}the same thing, through a drift in the cumulative sum
rather than a regression. Often better than the F when the regime difference is
concentrated in the intercept.{p_end}
{p2line}

{pstd}
The practical consequence. A threshold model whose two regimes have the
{it:same} curvature -- the usual case, two linear regimes -- leaves no
second-order signature for Keenan or Tsay (1986) to find. So those two can both
fail to reject on data that plainly has a threshold. Reading them as evidence
{it:against} a threshold is the mistake this command exists to prevent; read
the arranged autoregression for that.

{pstd}
Conversely, Keenan or Tsay (1986) rejecting while the arranged autoregression
does not says the series is nonlinear but not in a way that ordering by any of
your candidate delays reveals. Consider a different threshold variable, a
smooth transition ({helpb thstar}), or a genuinely nonlinear model that is not a
threshold model at all.


{marker arranged}{...}
{title:The arranged autoregression}

{pstd}
The recursion is

{p 8 8 2}
{it:ehat_i} = ({it:y_i} - {it:x_i}'{it:bhat_{i-1}}) / sqrt(1 +
{it:x_i}'{it:S_{i-1}}^-1 {it:x_i})

{pstd}
over the observations {it:sorted by the candidate threshold variable}, where
{it:bhat_{i-1}} and {it:S_{i-1}} use only the observations before {it:i} in that
order. The denominator is the standard deviation of a one-step forecast error up
to scale, so under linearity the {it:ehat_i} are homoskedastic and uncorrelated
with {it:x_i}, {it:whatever ordering was used}. That is the whole idea: the
ordering is informative under the alternative and irrelevant under the null.

{pstd}
Tsay's F statistic tests that every coefficient in the regression of
{it:ehat_i} on {it:x_i} is zero, the constant included, with
({it:k}, {it:M}-{it:k}) degrees of freedom where {it:k} is the number of
autoregressive parameters and {it:M} the length of the recursion. It is an
approximation, which is one more reason to use {opt reps()}.

{pstd}
Note what the test does {bf:not} give you: the location of the threshold. It
answers "does the relationship change somewhere along this ordering", not
"where". Use {helpb thtar} to estimate the threshold and {helpb thtest} for a
sup-type test whose p-value already accounts for the threshold being unknown.


{marker cusum}{...}
{title:The CUSUM, and what it is not}

{pstd}
{cmd:thnltest} reports the {it:re-centred} cumulative sum of the recursive
residuals,

{p 8 8 2}
{it:Z_j} = ( {it:sum}_{i<=j} {it:ehat_i} - ({it:j}/{it:M})
{it:sum}_{i<=M} {it:ehat_i} ) / ({it:sigmahat} sqrt({it:M})),
{space 4}statistic = max_j |{it:Z_j}|

{pstd}
Re-centring makes the partial-sum process a Brownian bridge under the null, and
the bridge has an exact asymptotic law,
P(sup|{it:B}| > {it:a}) = 2 {it:sum}_{k>=1} (-1)^{k+1} exp(-2{it:k}^2{it:a}^2),
so the p-value needs no table.

{pstd}
Petruccelli and Davies (1986) tabulate a slightly different normalisation of the
same idea. {cmd:thnltest} does {bf:not} claim to reproduce their table: it
reports the bridge form because its null distribution is exact asymptotically
and can be checked, and because {opt reps()} gives an exact finite-sample
p-value for whichever form is computed. If you need Petruccelli and Davies's own
critical values, read them from the paper and compare them with the statistic
there rather than with this one.


{marker delay}{...}
{title:Searching the delay}

{pstd}
With more than one candidate delay, {cmd:thnltest} reports the test for each and
marks the smallest p-value with an asterisk. {bf:That smallest p-value is not a
valid p-value.} Having chosen the delay by minimising it, the minimum is biased
downwards, and the more candidates the worse it is.

{pstd}
{opt reps()} fixes this: the bootstrap recomputes the statistic at the
{it:selected} delay on each bootstrap sample, so the reported bootstrap p-value
is the one to quote when the delay was searched. The difference between the two
p-values is a direct measure of how much the search cost you, and it is usually
larger than people expect.


{marker multi}{...}
{title:Two or more variables: Tsay's (1998) multivariate test}

{pstd}
With two or more variables {cmd:thnltest} switches to the multivariate
arranged regression of Tsay (1998), the C(d) test of a linear VAR against a
threshold VAR. The idea is identical to the univariate case: order the
observations by a candidate threshold variable, run recursive {it:multivariate}
least squares through them, and standardise each one-step predictive residual
{it:vector} by the same scalar sqrt(1 + {it:x_i}'{it:S_{i-1}}^-1{it:x_i}).
Under linearity the ordering is irrelevant and the standardised residuals are
orthogonal to the regressors whatever order was used.

{p 8 15 2}
{cmd:thnltest} {it:varlist} {ifin}{cmd:,} {opt ar(numlist)}
[{opt delay(numlist)} {opth thv:ar(varlist)} {opt start:up(#)} {opt nocons:tant}]

{pstd}
{opt ar()} gives the lag orders of the VAR, so {cmd:ar(1 2)} puts every
listed variable at lags 1 and 2 into every equation. Candidate orderings come
from {opth thvar(varlist)} if given, otherwise from {opt delay()} applied to
the {it:first} variable in {it:varlist}. {opt reps()} is not available in this
form.

{pstd}
Three statistics are reported for each candidate ordering, from the
cross-product matrices {bf:S0} = Ehat'Ehat and {bf:S1} after regressing the
standardised residuals on the arranged design:

{p 8 8 2}
LM = {it:M}({it:k} - tr({bf:S0}^-1{bf:S1})){space 4}
LR = {it:M} ln(|{bf:S0}|/|{bf:S1}|){space 4}
{it:F} from Rao's approximation to lambda = |{bf:S1}|/|{bf:S0}|

{pstd}
{bf:Report the F version.} The chi-square forms of multivariate LM and LR
statistics are heavily oversized at these sample sizes, and Rao's F is exact
when there are two equations. Degrees of freedom are {it:k} times the
{bf:rank} of the arranged design, not its column count.

{pstd}
{bf:One honest difference from the paper.} Tsay's published C(d) scales the log
ratio by [{it:M} - {it:b} - {it:kw}] rather than {it:M}, where {it:b} is the
startup. The difference is O(1/{it:M}) and does not change any conclusion, but
it does mean the number printed here is not byte-identical to the one in the
paper. {cmd:thnltest} reports the {it:M} scaling because that is the form whose
Wilks and Rao distributions are the ones being used.

{pstd}
As in the univariate case, the test says whether the VAR changes somewhere
along the chosen ordering, {bf:not where}. Take the selected ordering to
{helpb thtvar} for the threshold itself and for a bootstrap p-value that
accounts for the threshold being unknown, and to {helpb thnregimes} for how
many regimes.


{marker workflow}{...}
{title:Where this fits in the workflow}

{pstd}
{bf:1.} Choose the lag set from the linear autoregression.

{pstd}
{bf:2.} Run {cmd:thnltest} with {opt reps()}. If nothing rejects, stop and say
so; a threshold model fitted to a series with no evidence of nonlinearity will
still produce a threshold, a confidence interval and two regimes, all of them
meaningless.

{pstd}
{bf:3.} If the arranged autoregression rejects, the delay it selects is the
natural candidate threshold variable. Take it to {helpb thtar}, which estimates
the threshold and its confidence set, and to {helpb thtest}, whose sup/ave/exp
statistics test the same null with a p-value that already accounts for the
threshold being unknown.

{pstd}
{bf:4.} If Keenan or Tsay (1986) rejects but the arranged autoregression does
not, try {helpb thstar} for a smooth transition and {cmd:estat lintest} after it
to sweep other candidate transition variables.

{pstd}
{helpb threshkit_choose} walks through the whole sequence.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}The four tests, with every lag as a candidate delay{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3)}{p_end}

{pstd}With a bootstrap, which is what to report once the delay was searched{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3) reps(1000) seed(7)}{p_end}

{pstd}Restrict the candidate delays on theoretical grounds{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3 12) delay(1 12) reps(1000) seed(7)}{p_end}

{pstd}Check that the conclusion survives a different startup{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3) startup(30)}{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3) startup(70)}{p_end}

{pstd}Then estimate, if something rejected{p_end}
{phang2}{cmd:. thtar y, ar(1 2 3) delay(1) test reps(1000) seed(7)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(k_lags)}}number of lags{p_end}
{synopt:{cmd:r(startup)}}startup of the recursion{p_end}
{synopt:{cmd:r(F_keenan)}, {cmd:r(p_keenan)}}Keenan's statistic and p-value{p_end}
{synopt:{cmd:r(F_tsay86)}, {cmd:r(p_tsay86)}}Tsay (1986){p_end}
{synopt:{cmd:r(delay)}}the delay with the smallest Tsay (1989) p-value{p_end}
{synopt:{cmd:r(F_tsay89)}, {cmd:r(p_tsay89)}}Tsay (1989) at that delay{p_end}
{synopt:{cmd:r(delay_cusum)}, {cmd:r(cusum)}, {cmd:r(p_cusum)}}the CUSUM{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications, if any{p_end}
{synopt:{cmd:r(pb_keenan)}, {cmd:r(pb_tsay86)}, {cmd:r(pb_tsay89)}, {cmd:r(pb_cusum)}}bootstrap p-values{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:r(keenan)}, {cmd:r(tsay86)}}{it:F}, df and p{p_end}
{synopt:{cmd:r(arranged)}}one row per candidate delay: delay, F, df1, df2, p,
CUSUM, p_cusum, M{p_end}
{synopt:{cmd:r(bdist)}}the bootstrap distributions, one column per statistic{p_end}


{marker refs}{...}
{title:References}

{phang}
Keenan, D. M. 1985. A Tukey nonadditivity-type test for time series
nonlinearity. {it:Biometrika} 72: 39-44.
{browse "https://doi.org/10.1093/biomet/72.1.39":doi:10.1093/biomet/72.1.39}

{phang}
Petruccelli, J. D., and N. Davies. 1986. A portmanteau test for self-exciting
threshold autoregressive-type nonlinearity in time series.
{it:Biometrika} 73: 687-694.
{browse "https://doi.org/10.1093/biomet/73.3.687":doi:10.1093/biomet/73.3.687}

{phang}
Tsay, R. S. 1986. Nonlinearity tests for time series.
{it:Biometrika} 73: 461-466.
{browse "https://doi.org/10.1093/biomet/73.2.461":doi:10.1093/biomet/73.2.461}

{phang}
Tsay, R. S. 1998. Testing and modeling multivariate threshold models.
{it:Journal of the American Statistical Association} 93: 1188-1202.
{browse "https://doi.org/10.1080/01621459.1998.10473779":doi:10.1080/01621459.1998.10473779}

{phang}
Tsay, R. S. 1989. Testing and modeling threshold autoregressive processes.
{it:Journal of the American Statistical Association} 84: 231-240.
{browse "https://doi.org/10.1080/01621459.1989.10478760":doi:10.1080/01621459.1989.10478760}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit}, {helpb threshkit_choose}, {helpb thtest},
{helpb thnregimes}, {helpb thtar}, {helpb thstar}, {helpb thtvar}, {helpb thselect}
{p_end}
