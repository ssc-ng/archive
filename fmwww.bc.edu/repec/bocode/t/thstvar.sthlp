{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtvar" "help thtvar"}{...}
{vieweralsosee "thtvecm" "help thtvecm"}{...}
{vieweralsosee "thstar" "help thstar"}{...}
{viewerjumpto "Syntax" "thstvar##syntax"}{...}
{viewerjumpto "Description" "thstvar##description"}{...}
{viewerjumpto "Options" "thstvar##options"}{...}
{viewerjumpto "The modelling cycle" "thstvar##cycle"}{...}
{viewerjumpto "Choosing the transition function" "thstvar##type"}{...}
{viewerjumpto "Choosing the transition variable" "thstvar##zvar"}{...}
{viewerjumpto "Smooth or sharp? thstvar or thtvar?" "thstvar##sharp"}{...}
{viewerjumpto "Reading the tests" "thstvar##tests"}{...}
{viewerjumpto "Reading the coefficients" "thstvar##coef"}{...}
{viewerjumpto "Generalised impulse responses" "thstvar##girf"}{...}
{viewerjumpto "gamma is weakly identified" "thstvar##gamma"}{...}
{viewerjumpto "Postestimation" "thstvar##postest"}{...}
{viewerjumpto "Examples" "thstvar##examples"}{...}
{viewerjumpto "Stored results" "thstvar##results"}{...}
{viewerjumpto "References" "thstvar##refs"}{...}
{title:Title}

{phang}
{bf:thstvar} {hline 2} Vector smooth transition autoregression (VSTAR / STVAR):
logistic and exponential transitions, linearity and misspecification tests,
generalised impulse responses


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thstvar} {it:varlist} {ifin}{cmd:,} {opt lags(#)} [{it:options}]

{pstd}
{it:varlist} holds two or more time series. The data must be {helpb tsset}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt lags(#)}}lags of every variable in the system{p_end}
{synopt:{opt ty:pe(string)}}{opt lstar} (default), {opt estar}, {opt lstar2}{p_end}
{synopt:{opt delay(#)}}delay {it:d} for the self-exciting transition variable; default 1{p_end}
{synopt:{opth thv:ar(varname)}}use this transition variable instead{p_end}
{synopt:{opth ex:og(varlist)}}extra exogenous regressors in every equation{p_end}
{synopt:{opt trim(#)}}trimming of the location grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt ngamma(#)}}grid points for the smoothness; default 20{p_end}
{synopt:{opt nc(#)}}grid points for the location; default: every order statistic
(25 for {opt lstar2}){p_end}
{synopt:{opt fixg:amma(#)}}calibrate the smoothness instead of estimating it{p_end}
{synopt:{opt ord:er(#)}}order of the Taylor expansion in the linearity test; default 3{p_end}
{synopt:{opt nocons:tant}}suppress the constants{p_end}
{synopt:{opt r:obust}}sandwich standard errors{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt lags()} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thstvar} fits the two-regime vector smooth transition autoregression

{p 8 8 2}
{it:y_t} = {bf:Phi1}' {it:w_t} (1 - {it:G}({it:z_t})) + {bf:Phi2}' {it:w_t}
{it:G}({it:z_t}) + {it:e_t}

{pstd}
with {it:w_t} = (1, {it:y_{t-1}}', ..., {it:y_{t-p}}', {it:x_t}')' and
{it:G} a transition function rising from 0 to 1. Writing
{bf:Delta} = {bf:Phi2} - {bf:Phi1} gives the equivalent form

{p 8 8 2}
{it:y_t} = {bf:Phi1}' {it:w_t} + {bf:Delta}' {it:w_t} {it:G}({it:z_t}) + {it:e_t}

{pstd}
which is the one {cmd:thstvar} estimates and reports, because it is
{it:linear} in ({bf:Phi1}, {bf:Delta}) once the transition parameters are
fixed. Two facts then make the problem small. First, those linear parameters
can be concentrated out. Second, every equation has the same regressors
{it:U} = ({it:W}, {it:W} o {it:G}), so the Gaussian maximum likelihood
estimator of the slopes is multivariate least squares and the concentrated
objective is just {bf:ln|Sigma(gamma, c)|}. The search is therefore over two
numbers (three for {opt lstar2}), not over the whole parameter vector: a grid
over ({it:gamma}, {it:c}) followed by Nelder-Mead on (ln {it:gamma}, {it:c}).

{pstd}
The economics of the model is that the state of the world is a matter of
{it:degree}. {it:G} = 0 is one regime and {it:G} = 1 the other, and the data
sit somewhere between: the depth of a recession, the tightness of financial
conditions, the size of a disequilibrium. A sharp threshold VAR
({helpb thtvar}) says the economy is in one regime or the other; this says it
is 70 per cent of the way into the second.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} is the lag order. Choose it from the linear VAR with
{helpb varsoc} {it:before} testing for nonlinearity. A nonlinearity test on an
underspecified lag structure rejects for the wrong reason, and the
misspecification test for residual autocorrelation will tell you so.

{phang}
{opt type(lstar|estar|lstar2)} is the transition function; see
{help thstvar##type:below}. {opt lstar1} is accepted as a synonym for
{opt lstar}.

{phang}
{opt delay(#)} sets the delay when no {opt thvar()} is given, so the transition
variable is {cmd:L}{it:d}{cmd:.}{it:first variable of varlist}. This
self-exciting form is what makes {cmd:estat girf} possible, because the
simulator can then update the transition variable from the simulated path.

{phang}
{opth thvar(varname)} gives the transition variable explicitly. Anything may be
used, including an outside variable, but note that a transition variable the
model does not generate rules out {cmd:estat girf}.

{phang}
{opth exog(varlist)} adds regressors that enter every equation and whose
coefficients also switch. Deterministic terms, dummies, and genuinely
exogenous drivers belong here.

{phang}
{opt ngamma(#)} and {opt nc(#)} set the starting grid. The concentrated
likelihood is very flat in {it:gamma} and often multimodal in {it:c}, so the
grid is not a luxury: it is what keeps Nelder-Mead out of a local minimum.
Raise {opt ngamma()} if the reported {it:gamma} sits at the edge of the grid
range (0.5 to 100 on the scaled measure). {opt lstar2} searches {it:pairs} of
locations, so its starting grid is quadratic in {opt nc()} and defaults to 25
points rather than every order statistic; raise it deliberately.

{phang}
{opt trim(#)} keeps the location {it:c} away from the ends of the sorted
transition variable, so that both regimes are populated.

{phang}
{opt fixgamma(#)} holds the smoothness at a calibrated value and searches only
over the location. This is what Auerbach and Gorodnichenko (2012) do: they set
{it:gamma} so that the economy spends a chosen fraction of the sample in the
recession regime, rather than letting the likelihood pick it, precisely because
{it:gamma} is so weakly identified (see {help thstvar##gamma:below}). A
calibrated {it:gamma} is {it:not} posted as a coefficient and has no standard
error; the header marks it {bf:(calibrated)} and {bf:e(fix_gamma)} records it.
Everything else -- the standard errors of the slopes, the misspecification
tests, the impulse responses -- then correctly treats {it:gamma} as known
rather than paying for having estimated it. To pick the value, fit once
without the option, read {cmd:estat transition}, and choose the {it:gamma} that
puts the share of observations you want on each side.

{phang}
{opt order(#)} is the order of the Taylor expansion used in the linearity test.
3 is the Luukkonen-Saikkonen-Terasvirta default and is what the
{it:H}04/{it:H}03/{it:H}02 sequence needs; 2 or 1 give a shorter, more powerful
test when you already know the shape.

{phang}
{opt robust} replaces the information matrix with the sandwich
{it:I}^-1 ({it:sum} {it:s_t} {it:s_t}') {it:I}^-1, built from the exact scores
{it:s_t} = {it:J_t}' {bf:Sigma}^-1 {it:e_t}. Use it when the errors are
conditionally heteroskedastic, which in a two-regime model they very often are:
regime-dependent volatility is common and is not what this model captures.


{marker cycle}{...}
{title:The modelling cycle}

{pstd}
Teraesvirta's modelling cycle, in the order you should actually run it.

{pstd}
{bf:1. Specify the linear VAR.} Pick {opt lags()} with {helpb varsoc}. Check it
is stable ({helpb varstable}) and that the residuals are not autocorrelated.

{pstd}
{bf:2. Test linearity, once per candidate transition variable.} Fit
{cmd:thstvar} with each candidate and read the linearity table, or use
{cmd:estat lintest, zvar()} to sweep candidates from one fit. The transition
variable is the one with the smallest p-value for the omnibus test. This is a
{it:selection} rule, not a test: having searched over candidates, the reported
p-value of the winner is optimistic.

{pstd}
{bf:3. Choose the transition function} from the
{it:H}04/{it:H}03/{it:H}02 sequence, which {cmd:thstvar} reports and
interprets. See {help thstvar##type:below}.

{pstd}
{bf:4. Estimate.} Check {cmd:e(converged)} and, with
{cmd:estat transition}, that the fitted {it:G} actually moves.

{pstd}
{bf:5. Evaluate.} {cmd:estat misspec} runs the three tests: no error
autocorrelation, no remaining nonlinearity, parameter constancy. Each adds a
block to the {it:gradient} of the fitted model, which is what makes them LM
tests rather than residual regressions.

{pstd}
{bf:6. Interpret.} {cmd:estat regimes} and {cmd:estat phi2} for the two
regimes; {cmd:estat girf} for the dynamics. Do not read the coefficients of a
nonlinear VAR as multipliers; read the impulse responses.


{marker type}{...}
{title:Choosing the transition function}

{synoptset 12}{...}
{p2col 5 12 16 2: type}{it:G}({it:z}){p_end}
{p2line}
{p2col 5 12 16 2:{opt lstar}}1/(1 + exp(-{it:gamma}({it:z}-{it:c})/sd({it:z}))){p_end}
{p2col 5 12 16 2:{opt estar}}1 - exp(-{it:gamma}({it:z}-{it:c})^2/sd({it:z})^2){p_end}
{p2col 5 12 16 2:{opt lstar2}}1/(1 + exp(-{it:gamma}({it:z}-{it:c})({it:z}-{it:c2})/sd({it:z})^2)){p_end}
{p2line}

{pstd}
{it:gamma} is divided by the standard deviation of {it:z} (Terasvirta 1994,
p.209) so that it is free of the units of {it:z} and comparable across
specifications. {bf:e(sd_z)} reports the divisor.

{pstd}
{opt lstar} is {it:monotone}: one regime below {it:c}, the other above. Use it
when the two states are ordered, which is the usual macro case (expansion
versus recession, loose versus tight credit).

{pstd}
{opt estar} is {it:symmetric} about {it:c}: the middle is one regime and
{it:both} tails are the other. Use it when what matters is the {it:distance}
from a central value, not its sign: adjustment that kicks in once a
disequilibrium is large either way, or a band of inaction.

{pstd}
{opt lstar2} is the general two-location logistic, which nests the shape
{opt estar} describes but approaches its outer regime more slowly. If
{opt estar} fits but you suspect the two tails behave differently, this is the
test of that.

{pstd}
The {it:H}04/{it:H}03/{it:H}02 sequence decides between them, and
{cmd:thstvar} applies the rule for you. In the Taylor expansion of
{it:G} about {it:gamma} = 0, a {it:monotone} transition contributes odd-order
terms and a {it:symmetric} one contributes the even-order term. So: if
{it:H}03 (the second-order block) is the most strongly rejected of the three,
choose {opt estar} or {opt lstar2}; otherwise choose {opt lstar}. Report the
whole sequence, not just the verdict, so the reader can see how close the call
was.


{marker zvar}{...}
{title:Choosing the transition variable}

{pstd}
This choice does more to the results than the choice of transition function,
and it is where judgment is unavoidable. Three rules.

{pstd}
{bf:Let the question pick the candidates.} If the question is whether fiscal
multipliers are larger in slumps, the candidates are measures of slack, not
whichever variable minimises ln|Sigma|. Auerbach and Gorodnichenko (2012) use a
moving average of output growth precisely so that the state is a persistent
feature of the cycle rather than a one-quarter blip; build such a variable and
pass it in {opt thvar()}.

{pstd}
{bf:Smooth it if the state is persistent.} A single lag is noisy and will put
adjacent quarters in different regimes. A moving average of three or four
periods usually produces a far more interpretable {it:G}, and
{cmd:estat transition, timegraph} shows you whether it has.

{pstd}
{bf:Then test, and say that you searched.} {cmd:estat lintest, zvar()}
recomputes the linearity sequence for any candidate from a single fit. Choose by
the omnibus p-value, but report that the choice was made that way.

{pstd}
If you want a generalised impulse response, the transition variable must be
something the model generates: use {opt delay()}, with
{opt delay()} no greater than {opt lags()}. {bf:e(girf_ok)} records whether
{cmd:estat girf} is available.


{marker sharp}{...}
{title:Smooth or sharp? thstvar or thtvar?}

{pstd}
The two models are not nested in a way that a test can settle, so decide on
three grounds.

{pstd}
{bf:Does the fitted transition move?} Run {cmd:estat transition}. If almost
every observation sits in a corner ({it:G} < .1 or {it:G} > .9) the estimated
transition {it:is} a sharp threshold, and {helpb thtvar} says so with two fewer
parameters and a threshold whose confidence set can be constructed properly. A
very large {it:gamma} is the same message read off the coefficient table.

{pstd}
{bf:Is the mechanism a switch or a matter of degree?} A binding constraint, a
policy rule with a trigger, a credit limit: these are switches, so use
{helpb thtvar}. Slack, sentiment, financial tightness: these are degrees, so
use {cmd:thstvar}. Aggregation across heterogeneous units also smooths a
mechanism that is sharp at the micro level, which is an argument for
{cmd:thstvar} on aggregate data even when the micro story is a threshold.

{pstd}
{bf:Compare BIC.} The log likelihoods of {cmd:thstvar}, {helpb thtvar},
{helpb thtvecm} and official {helpb var} are all on the same scale, so their
information criteria are comparable. Treat a BIC difference under about 2 as no
evidence either way and report both fits.


{marker tests}{...}
{title:Reading the tests}

{pstd}
{bf:Why there is no likelihood-ratio test of linearity.} Under linearity
{bf:Delta} = 0, and then {it:gamma} and {it:c} do not appear in the model at
all. They are unidentified, the information matrix is singular, and the
likelihood-ratio statistic is not chi-squared. {bf:e(lr)} is reported for
reference only and the output says so.

{pstd}
{bf:What is done instead.} Luukkonen, Saikkonen and Terasvirta (1988) replace
{it:G} by its Taylor expansion about {it:gamma} = 0, which turns the
unidentified problem into a test of a linear restriction. The auxiliary
regression adds {it:w_t} {it:z_t}^{it:j}, {it:j} = 1..{opt order()}, and the
hypothesis is that the whole added block is zero. The system version is
Terasvirta and Yang (2014a).

{pstd}
{bf:Three statistics are reported} for each hypothesis. With {bf:S0} and
{bf:S1} the residual cross-product matrices under the null and the
alternative,

{p 8 8 2}
LM = {it:n} ({it:k} - tr({bf:S0}^-1 {bf:S1})){space 6}
LR = {it:n} ln(|{bf:S0}|/|{bf:S1}|){space 6}
{it:F} from Rao's approximation to Wilks' lambda = |{bf:S1}|/|{bf:S0}|

{pstd}
LM is the exact score statistic, LR is the Wilks statistic, and both are
chi-squared with {it:k} x {it:r} degrees of freedom. {bf:Report the F version.}
The chi-squared forms are heavily oversized at the sample sizes used in this
literature, which is the central practical message of Terasvirta and Yang
(2014a); Rao's {it:F} is exact when there are two equations or two restrictions
and an excellent approximation otherwise.

{pstd}
{bf:Degrees of freedom are counted by rank, not by columns.} When the
transition variable is itself one of the regressors (the self-exciting case
{it:z} = L{it:y}), the auxiliary block is rank deficient: the constant times
{it:z}^{it:j} reproduces a column that is already there. Counting columns would
give too many restrictions and too small a statistic. {cmd:thstvar} computes the
rank increase of the design and uses that. The certification suite checks the
difference explicitly.

{pstd}
{bf:The three misspecification tests} ({cmd:estat misspec}) all add a block to
the fitted model's {it:gradient}, not to the regressors:

{p 8 12 2}
{bf:no error autocorrelation} adds the lagged residual vectors. Rejection
almost always means too few lags; fix {opt lags()} before concluding anything
about regimes.

{p 8 12 2}
{bf:no remaining nonlinearity} adds a second Taylor block, in {it:z} or in
another variable through {opt zvar()}. Rejection points to a third regime, or
to a second transition variable, or to the wrong transition function.

{p 8 12 2}
{bf:parameter constancy} adds the same block in a smooth trend. Rejection means
the two regimes themselves drift over the sample, which no two-regime model can
absorb: the honest responses are a shorter sample, a structural break, or a
time-varying specification.

{pstd}
Per-equation {it:F} tests are reported alongside the system statistics and are
the small-sample reliable version. If the system test rejects but no single
equation does, suspect the chi-squared size distortion rather than a real
feature.


{marker coef}{...}
{title:Reading the coefficients}

{pstd}
The table has {it:2k}+1 blocks: {bf:Phi1_}{it:y} and {bf:Delta_}{it:y} for each
equation, then {bf:Transition} holding {it:gamma} and {it:c}.

{pstd}
{bf:Phi1} is the regime reached as {it:G} -> 0 and {bf:Delta} is the change on
the way to {it:G} -> 1. So the {bf:Delta} block {it:is} the test of regime
difference, coefficient by coefficient: its p-values answer "does this
regressor act differently in the two regimes". {cmd:estat phi2} gives
{bf:Phi2} = {bf:Phi1} + {bf:Delta}, with delta-method standard errors, for
reporting the second regime in levels.

{pstd}
{bf:The standard errors are joint, not conditional.} The information matrix
includes the cross-blocks between the slopes and ({it:gamma}, {it:c}), so
inverting it partials the transition parameters out and the slope standard
errors account for having estimated the transition. They are therefore slightly
larger than a regression on the fitted ({it:W}, {it:W} o {it:G}) would report.
That difference is the cost of estimating the transition, and treating it as
zero is the most common mistake in applied STVAR work.

{pstd}
{bf:Do not read the coefficients as effects.} In a nonlinear VAR the response
to a shock depends on where the system is and on the shock itself. The
coefficients describe the two limiting regimes; the dynamics live in
{cmd:estat girf}.


{marker girf}{...}
{title:Generalised impulse responses}

{pstd}
{cmd:estat girf} computes the generalised impulse response of Koop, Pesaran and
Potter (1996),

{p 8 8 2}
GIRF({it:h}, {it:delta}, {it:omega}) = E[{it:y_{t+h}} | {it:e_t} = {it:delta},
{it:omega}] - E[{it:y_{t+h}} | {it:omega}]

{pstd}
A nonlinear model has no single impulse response. The response depends on the
history {it:omega}, because that fixes where on the transition the system
starts; on the {it:size} of the shock, because a large shock can move the
system across the transition and a small one cannot; and on its {it:sign}, for
the same reason. Both expectations are computed by simulation, and both paths
are driven by the {it:same} drawn future shocks, so the difference isolates the
effect of {it:delta} rather than simulation noise.

{pstd}
{opt compare} is the option to use: it computes the response separately from
regime-1 histories ({it:G} < .5) and regime-2 histories, which is the
comparison the model exists to make. {opt graph} draws them together.

{pstd}
{opt size()} is in standard deviations and {opt shock()} names the variable.
By default the shock vector is the Cholesky column of {bf:e(Sigma)} for that
variable, so the {it:order of varlist is the identifying assumption} exactly as
in a linear VAR; {opt nocholesky} shocks that equation alone and leaves the
others' contemporaneous errors at zero. Run the thing at {opt size(1)} and
{opt size(-1)} to see the asymmetry, and at {opt size(1)} and {opt size(3)} to
see the size dependence. In a linear VAR those would be exact multiples of each
other; here they are not, and the departure is the result.

{pstd}
{opt reps()} is the number of simulated futures per history and
{opt histories()} selects the histories ({opt low}, {opt high}, or a number for
a random sample). Use {opt seed()} so the numbers are reproducible, and raise
{opt reps()} until the response stops moving between seeds.


{marker gamma}{...}
{title:gamma is weakly identified}

{pstd}
Expect a large standard error on {it:gamma}, and do not treat that as a failure
of the model. The concentrated likelihood is extremely flat in {it:gamma} once
the transition is steep enough to separate the regimes: {it:gamma} = 30 and
{it:gamma} = 300 fit almost identically, because the handful of observations
near {it:c} is all that distinguishes them. The slope parameters and the
location {it:c} are usually estimated far more sharply.

{pstd}
The practical consequences. Report {it:gamma} but do not interpret its
magnitude or build an argument on its significance. Do interpret {it:c}, which
is usually well identified and economically meaningful. And check that the
reported {it:gamma} is not pinned at the end of the starting grid; if it is,
widen it with {opt ngamma()} and look again at whether the transition is really
smooth (see {help thstvar##sharp:smooth or sharp}).


{marker postest}{...}
{title:Postestimation}

{synoptset 24 tabbed}{...}
{synopt:{cmd:estat transition}}summary of the fitted {it:G}; {opt graph} plots
it against {it:z}, {opt timegraph} against time{p_end}
{synopt:{cmd:estat regimes}}{bf:Phi1}, {bf:Phi2} and the regime weights{p_end}
{synopt:{cmd:estat phi2}}{bf:Phi2} with delta-method standard errors{p_end}
{synopt:{cmd:estat lintest}}the linearity sequence; {opt zvar()} recomputes it
for another candidate transition variable, {opt order()} for another expansion{p_end}
{synopt:{cmd:estat misspec}}the three misspecification tests;
{opt arlags()} sets the autocorrelation order, {opt zvar()} the second
transition variable{p_end}
{synopt:{cmd:estat girf}}generalised impulse response{p_end}
{synopt:{cmd:estat irf}}regime-specific {it:conditionally linear} impulse
responses{p_end}
{synopt:{cmd:estat fevd}}the matching forecast-error variance
decomposition{p_end}
{synopt:{cmd:estat table}}a publication summary{p_end}
{synopt:{cmd:estat serial}}no residual autocorrelation, tested against the model gradient{p_end}
{synopt:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{synopt:{cmd:estat normality}}Jarque-Bera, with its skewness and kurtosis components{p_end}
{synopt:{cmd:estat mvdiag}}all three of the above in one table{p_end}

{pstd}
{bf:The residual diagnostics} ({cmd:estat serial}, {cmd:estat archlm},
{cmd:estat normality}, and {cmd:estat mvdiag} for all three at once) are
{bf:system} tests: the common block and the equation-specific transition columns
are stacked into {bf:one} design, because that is what a system test needs, and
the null regressors are the {bf:model gradient} rather than the levels of the
regressors. Testing against the gradient is what makes them tests of the
{it:fitted smooth-transition model} and not of some linear approximation to it.
A single rejection therefore does not say which equation is at fault.
{opt lags(#)} sets the order of the serial-correlation and ARCH tests; the
default is 4. The name is {cmd:mvdiag} rather than {cmd:diag} as a reminder that
nothing here is computed one equation at a time.

{pstd}
{cmd:predict} supports {opt xb} and {opt residuals} (both with
{opt equation()}) and {opt transition} for {it:G}({it:z}).



{pstd}
{cmd:estat irf} and {cmd:estat fevd} compute the {bf:conditionally linear}
responses, which answer a {it:different question} from {cmd:estat girf}, and
the difference matters enough that both tables say so on their face.

{pstd}
Take one regime's coefficient matrix and treat it as a linear VAR: form the
companion matrix, and let {&Psi}{subscript:h} be the upper-left k x k block of
its h-th power. That is the propagation you would see {it:if the system stayed
in that regime forever}. {cmd:estat girf} instead simulates the actual
nonlinear system, in which a shock may push the process across the threshold
and change the dynamics for the rest of the horizon.

{pstd}
Neither is an approximation to the other:

{p 8 8 2}
o the {bf:conditionally linear} response isolates a regime's own dynamics from
the probability of leaving it, which is what you want when the economic
question is "how does this state propagate shocks";{p_end}
{p 8 8 2}
o the {bf:generalised} response includes the chance of leaving, which is what
you want when the question is "what happens if I shock this system now".{p_end}

{pstd}
Reporting the first as "the impulse response of the threshold VAR" would be
wrong. Say which one you used.

{pstd}
Three things to read in the output.

{phang2}
{bf:1. The maximum eigenvalue modulus per regime.} If it is 1 or more, that
regime's conditional response {bf:diverges}. This is correct arithmetic, not a
failure: a threshold model can be globally stationary with one locally
explosive regime, and that is often the interesting finding. Do not read the
long-horizon numbers for that regime as a forecast. Compare
{cmd:estat stability}.

{phang2}
{bf:2. The innovation covariance.} After {helpb thtvar} each regime is
orthogonalised with its {bf:own} {&Sigma}, estimated from that regime's
residuals, because a conditionally linear system in regime j has regime j's
innovation covariance — and the regimes usually differ in variance, which is
often why the threshold was found. Both are returned, along with the pooled
one, so the choice can be inspected. After {helpb thstvar} there is no regime
membership to split the residuals by, so the model's single {&Sigma} is used
for both limiting systems and the output says so; dichotomising the transition
function at 0.5 to manufacture a split would produce numbers for a model you
did not fit.

{phang2}
{bf:3. The Cholesky ordering} is the order of {it:varlist}, and it is an
identifying assumption: shock m cannot affect variables before m within the
period. {opt nocholesky} reports the response to a unit innovation instead,
which needs no ordering but is not a response to an economically interpretable
shock.

{pstd}
Options: {opt horizon()}, {opt nocholesky}, {opt regime(1|2)} to print one
regime only, {opt reps()} and {opt level()} for a percentile band,
{opt wild} for a wild rather than a resampling bootstrap, {opt seed()},
{opt graph} and {opt saving()}.

{pstd}
{bf:What the band does and does not cover.} With {opt reps()} the regime
indicator and the regressors are held {bf:fixed} and only the residuals are
resampled; both regimes are refitted and the responses recomputed. The band
therefore conditions on the regime classification — which is exactly what a
conditionally linear response already conditions on, so the band is
internally consistent with the object it surrounds. It does {bf:not} include
uncertainty about the threshold or about which observations belong to which
regime, and a band that did would be wider. {opt reps()} is refused after
{helpb thstvar}, because there the band would need {&gamma} and c
re-estimated in every draw.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_rates}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Lag order from the linear VAR first{p_end}
{phang2}{cmd:. varsoc g3month g3year, maxlag(6)}{p_end}

{pstd}Fit the self-exciting LSTAR, which also makes a GIRF available{p_end}
{phang2}{cmd:. thstvar g3month g3year, lags(2) delay(1)}{p_end}

{pstd}Does the transition actually move, or is this a sharp threshold?{p_end}
{phang2}{cmd:. estat transition, graph timegraph}{p_end}

{pstd}Sweep candidate transition variables without refitting{p_end}
{phang2}{cmd:. estat lintest, zvar(L.sspread)}{p_end}
{phang2}{cmd:. estat lintest, zvar(L2.g3year)}{p_end}

{pstd}Evaluate{p_end}
{phang2}{cmd:. estat misspec, arlags(4)}{p_end}

{pstd}The two regimes, and the asymmetry of the dynamics{p_end}
{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat girf, shock(g3month) horizon(24) compare graph seed(7)}{p_end}

{pstd}Size dependence: in a linear VAR these would be exact multiples{p_end}
{phang2}{cmd:. estat girf, shock(g3month) size(1) horizon(12) seed(7)}{p_end}
{phang2}{cmd:. estat girf, shock(g3month) size(3) horizon(12) seed(7)}{p_end}

{pstd}An exponential transition, when the distance from a central value is
what matters{p_end}
{phang2}{cmd:. thstvar g3month g3year, lags(2) delay(1) type(estar)}{p_end}

{pstd}An outside, smoothed transition variable with robust standard errors{p_end}
{phang2}{cmd:. thstvar g3month g3year, lags(2) thvar(L.sspread) robust}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(gamma)}}smoothness, scaled by sd({it:z}){p_end}
{synopt:{cmd:e(c)}, {cmd:e(c2)}}location(s){p_end}
{synopt:{cmd:e(sd_z)}}the scaling divisor{p_end}
{synopt:{cmd:e(G_min)}, {cmd:e(G_max)}, {cmd:e(G_mean)}}range and mean of the transition{p_end}
{synopt:{cmd:e(N_low)}, {cmd:e(N_high)}}observations with {it:G} below and above .5{p_end}
{synopt:{cmd:e(lndet)}, {cmd:e(lndet0)}}ln|Sigma| of the fit and of the linear VAR{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(ll_0)}}log likelihoods{p_end}
{synopt:{cmd:e(lr)}}Wilks LR against the linear VAR, {bf:not} chi-squared{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(hqic)}}information criteria{p_end}
{synopt:{cmd:e(k_par)}}free parameters{p_end}
{synopt:{cmd:e(converged)}}1 if the optimiser converged{p_end}
{synopt:{cmd:e(typenum)}}1 lstar, 2 estar, 3 lstar2{p_end}
{synopt:{cmd:e(fix_gamma)}}the calibrated smoothness, or 0 if estimated{p_end}
{synopt:{cmd:e(n_tpar)}}number of {it:estimated} transition parameters{p_end}
{synopt:{cmd:e(girf_ok)}}1 if {cmd:estat girf} can be simulated{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and covariance, including
{it:gamma} and {it:c}{p_end}
{synopt:{cmd:e(Bmat)}}({bf:Phi1} \ {bf:Delta}) as a matrix{p_end}
{synopt:{cmd:e(Sigma)}}residual covariance{p_end}
{synopt:{cmd:e(lintest)}}the linearity sequence: LM LR F df1 df2 chi2_df p_LM p_LR p_F{p_end}


{marker refs}{...}
{title:References}

{phang}
Auerbach, A. J., and Y. Gorodnichenko. 2012. Measuring the output responses to
fiscal policy. {it:American Economic Journal: Economic Policy} 4: 1-27.
{browse "https://doi.org/10.1257/pol.4.2.1":doi:10.1257/pol.4.2.1}

{phang}
Eitrheim, O., and T. Terasvirta. 1996. Testing the adequacy of smooth
transition autoregressive models. {it:Journal of Econometrics} 74: 59-75.
{browse "https://doi.org/10.1016/0304-4076(95)01751-8":doi:10.1016/0304-4076(95)01751-8}

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis in
nonlinear multivariate models. {it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}

{phang}
Luukkonen, R., P. Saikkonen, and T. Terasvirta. 1988. Testing linearity against
smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.2307/2336599":doi:10.2307/2336599}

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}

{phang}
Terasvirta, T., and Y. Yang. 2014a. Linearity and misspecification tests for
vector smooth transition regression models. CREATES Research Paper 2014-04,
Aarhus University.

{phang}
Terasvirta, T., and Y. Yang. 2014b. Specification, estimation and evaluation of
vector smooth transition autoregressive models with applications. CREATES
Research Paper 2014-08, Aarhus University.

{phang}
Weise, C. L. 1999. The asymmetric effects of monetary policy: a nonlinear
vector autoregression approach. {it:Journal of Money, Credit and Banking}
31: 85-108. {browse "https://doi.org/10.2307/2601141":doi:10.2307/2601141}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit_choose}, {helpb thtvar}, {helpb thtvecm},
{helpb thstar}, {helpb thstr}, {helpb var}, {helpb varsoc}
{p_end}
