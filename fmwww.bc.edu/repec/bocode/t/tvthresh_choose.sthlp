{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{viewerjumpto "The decision" "tvthresh_choose##decision"}{...}
{viewerjumpto "Step 1 - is a threshold there at all" "tvthresh_choose##step1"}{...}
{viewerjumpto "Step 2 - is it constant" "tvthresh_choose##step2"}{...}
{viewerjumpto "Step 3 - reading a rejection" "tvthresh_choose##step3"}{...}
{viewerjumpto "What a rejection does not tell you" "tvthresh_choose##ambiguity"}{...}
{viewerjumpto "Reading a non-rejection" "tvthresh_choose##nonreject"}{...}
{viewerjumpto "Practical settings" "tvthresh_choose##settings"}{...}
{viewerjumpto "Mistakes worth avoiding" "tvthresh_choose##mistakes"}{...}
{viewerjumpto "Author" "tvthresh_choose##author"}{...}
{title:Title}

{phang}
{bf:tvthresh choose} {hline 2} Choosing between threshold specifications:
a decision guide


{marker decision}{...}
{title:The decision}

{pstd}
This page is about one question: {bf:which threshold specification should you
be fitting?} It is written to be read before estimating, not after.

{pstd}
The order matters, because each step is only interpretable if the one before
it held.

{p 8 10 2}{bf:1.} Is there a threshold effect at all, or is the relation
linear?{p_end}
{p 8 10 2}{bf:2.} If there is one, is the threshold {bf:constant} across
observations?{p_end}
{p 8 10 2}{bf:3.} If it is not constant, {it:how} does it vary?{p_end}

{pstd}
Skipping step 1 is the common error. A test of threshold constancy assumes a
threshold model; run on genuinely linear data its answer is not meaningful,
because the "estimated threshold" it standardises at is noise. Skipping step
2 is the costly one, and it is what this library exists for.


{marker step1}{...}
{title:Step 1 - is a threshold there at all}

{pstd}
This is the classical question and it is not what TVTHRESH is for. Use a test
of linearity against a threshold alternative {hline 2} Hansen's (1996)
bootstrap test and its relatives, available in {bf:THRESHKIT} and
elsewhere.

{pstd}
{bf:For a univariate series there is a sharper tool.} If the question is
whether an autoregression {it:became} a threshold autoregression at some
unknown date, {helpb tvtlr} tests exactly that, and it is unusually clean:
no bootstrap, no trimming, nothing to tune, and three fixed critical values
that depend on nothing. Its model is narrow {hline 2} AR(1), no intercept,
delay 1 {hline 2} so check that before reaching for it.

{pstd}
Two things to know before reading a linearity test's result:

{phang}
{bf:The threshold is not identified under the null}, which is why these tests
need a bootstrap or a simulated p-value rather than a chi-squared table. A
test that hands you a clean asymptotic p-value for this hypothesis is doing
something you should check.

{phang}
{bf:A rejection of linearity is not evidence of a threshold specifically.}
Smooth nonlinearity in the same variable rejects linearity too. If a smooth
transition is plausible on substantive grounds, test threshold against smooth
transition directly rather than inferring it.


{marker step2}{...}
{title:Step 2 - is the threshold constant}

{pstd}
Run {helpb tvthomog}. This is the step that decides which library you need,
and it is cheap: one least-squares fit, no bootstrap, no search under the
alternative, pivotal tabulated critical values.

{pstd}
Why it is worth running rather than assuming: if the threshold is not
constant and you fit as though it were, the estimator is not estimating a
noisy version of the right thing. It is estimating some average of a moving
boundary, the limit of which depends on how the boundary moved, and the
reported confidence interval for it is not a confidence interval for
anything in particular.

{pstd}
The practical cost of the test is one command. The practical cost of skipping
it is a parameter that cannot be interpreted.


{marker step3}{...}
{title:Step 3 - reading a rejection}

{pstd}
{helpb tvthomog} rejects. {bf:It has told you that the threshold moves. It
has not told you how}, and the distinction is the whole content of this
section.

{pstd}
The specification that replaces the constant has to come from the
substantive question, not from the test, because {bf:several quite different
departures all violate the same null and all produce a large statistic}. What
to ask, in order of how often it settles the matter:

{phang}
{bf:Is there a reason the boundary would move with time?} A policy regime, a
structural reform, financial liberalisation, a change in the measurement of
the threshold variable. If the mechanism is a dated event, a shift
specification is the honest one and the date should be tested rather than
imposed. If the mechanism is gradual {hline 2} learning, diffusion, slow
institutional change {hline 2} a smooth specification is the honest one.

{phang}
{bf:Is there a reason the boundary would depend on something observable?}
Boundaries that depend on size, development, or openness are threshold
functions of covariates, not of time, and treating them as time-varying will
fit badly for a reason that has nothing to do with time.

{phang}
{bf:Could it be two thresholds rather than one that moves?} This is the
answer most often missed, because a two-regime model with a moving boundary
and a three-regime model with two fixed boundaries can look similar in a
rejection. They are different objects with different policy readings, and
the second is usually the simpler claim. Test the number of thresholds
before concluding that one of them moves.

{phang}
{bf:Could the threshold variable be measured with error, or endogenous?}
Both can produce a rejection of constancy that is really a rejection of the
measurement. This is worth ruling out before adopting a richer
specification, because no amount of flexibility in the threshold fixes it.

{pstd}
{bf:If the answer is "gradual movement over time"}, that is what
{helpb tvtfourier} fits: the threshold becomes a Fourier function of time,
so a whole unknown path is summarised by a level, two coefficients and an
integer frequency. It also carries its own two tests {hline 2} one for
whether a threshold exists at all, one for whether it is constant {hline 2}
so it can confirm the diagnosis that sent you to it.

{pstd}
{bf:If the answer is "it depends on what the variable has recently been
doing"}, that is a different idea again, and {helpb tvtcotar} fits it: the
threshold becomes a rolling quantile of the threshold variable's own recent
past, so what counts as a high value is judged against recent experience
rather than against a fixed number or a date. Reach for it when the story is
"the regime switches when the variable is unusual by recent standards".

{pstd}
{bf:If the series is naturally about horizons} {hline 2} realised
volatility, trading activity, a macro series with monthly, quarterly and
annual structure {hline 2} and the threshold you have in mind is simply
"above or below the recent norm at that horizon", then {helpb tvtmathar} is
both the right model and much the cheapest: its threshold is an observed
moving average, so nothing is unidentified, no bootstrap is needed and the
test is an ordinary Wald test. It cannot place the threshold anywhere but
the middle, which is exactly what {helpb tvtcotar} relaxes.

{pstd}
{bf:And decide whether you believe a jump or a kink.} {helpb tvtcotar} and
{helpb tvtcotrk} use the same rolling-quantile threshold but differ in what
happens at it: a jump shifts the level of the relation, a kink changes its
slope while the relation stays continuous. Fitting one when the truth is the
other misstates the economics even when the fit looks acceptable, so this is
a substantive choice and not a technical one.

{pstd}
{bf:If your regressors are I(1), none of the above applies and
{helpb tvtcoint} is the command.} A threshold regression on integrated
variables is a piecewise COINTEGRATING regression: each regime has its own
long-run relation, and the asymptotics are not those of the stationary
case. Fitting a stationary threshold command to I(1) data is not a
conservative approximation, it is the wrong limit theory. {helpb tvtcoint}
also offers the third way for a threshold to move {hline 2} as a linear
function of OTHER observed variables, {it:gamma_t} = {it:g0} +
{it:g1'z_t} {hline 2} which is the right description when the story is
"what counts as a high value depends on where something else is". Its F1
asks whether there is a threshold and its F2 whether the threshold moves,
and they must be read in that order.

{pstd}
{bf:If the threshold depends on who or what the observation is, and your
regressors are stationary, {helpb tvtboundary} is the command.} It has the
same threshold function as {helpb tvtcoint} {hline 2} {it:gamma} =
{it:g1} + {it:g2'z} {hline 2} but for stationary or cross-sectional data,
and the choice between the two is settled by your regressors, not by
taste: I(1) regressors mean {helpb tvtcoint}, stationary ones mean
{helpb tvtboundary}. Two things make it worth reaching for. It carries the
{bf:only valid interval for a moving threshold} anywhere in this library,
the nonparametric posterior interval {hline 2} and its source paper
{bf:proves that inverting the likelihood ratio, the usual device, is NOT
valid here}, so do not reach for that. And its score test for the
existence of a threshold only ever fits the null model, so it is cheap
even on large samples.

{pstd}
{bf:And if you want a t-statistic ON the threshold, {helpb tvtindex} is
the only command here that can give you one.} It smooths the criterion so
that it becomes differentiable, which makes the threshold estimate
asymptotically normal {hline 2} unusual in this literature, where the
limits are normally a compound Poisson functional or need the threshold
effect to vanish. Two things follow. Discrete variables can enter the
threshold, so "the threshold level differs by sex" is a model you can
write; and whether a variable belongs in the threshold at all becomes an
ordinary t-test. The price is a slower rate and a bandwidth to choose,
and {helpb tvtboundary} is the alternative when you would rather not
choose one.

{pstd}
{bf:And if you want a SMOOTH transition rather than a sharp split,
{helpb tvtstar} is the one.} Everything else in this library assigns each
observation to a regime; this weights it between two, and the weight is
not a free logistic curve but a probability the model itself implies, so
it depends on every parameter at once. Its threshold moves with observed
state variables, which is the same idea as {helpb tvtcoint} and
{helpb tvtboundary} but inside a smooth transition. Its test of "is the
threshold state dependent" is {bf:regular} {hline 2} an ordinary
chi-squared {hline 2} which is rare here; its test of linearity is not,
and gets no p-value.

{pstd}
{bf:And if you do not yet know which variables belong in the model at all,
{helpb tvtcovdep} is the one to start with.} It is the only command here
that chooses the specification rather than estimating one you have fixed,
and it chooses three things together because they cannot be separated:
which regressors enter, which of those shift between regimes, and which
variables move the threshold. The split that decides whether a coefficient
shifts is itself determined by the threshold variables selected, and which
threshold variables matter depends on where the split falls, so choosing
them one at a time gives a different answer from choosing them together.

{pstd}
{bf:It reports no standard errors, and that is the point.} Any it reported
would condition on the selection while ignoring that selection happened.
So the honest sequence is {helpb tvtcovdep} on one sample to find the
specification, then {helpb tvtboundary} on an {bf:independent} sample to
estimate and test it. If you have only one sample, you have a choice to
make, not a result: either fix the specification on theory and go straight
to {helpb tvtboundary}, or use {helpb tvtcovdep} and report what it found
as a specification search rather than as inference.

{pstd}
{bf:And if there are more candidate regressors than you can fit, or more
than there are observations, {helpb tvtlasso} is the one.} It is
{helpb tvtfourier}'s high-dimensional counterpart -- the same Fourier
threshold in time -- but penalised, so it selects the covariates instead of
taking them as given. It also answers "is there a threshold effect at all"
by selection rather than by a test: if no shift term survives, the evidence
is for a linear model, and no pretest was needed to get there.

{pstd}
{bf:Choosing between the two selection commands is about what moves the
threshold, not about the dimension.} {helpb tvtlasso}'s threshold moves
with {bf:time}, through a Fourier term; {helpb tvtcovdep}'s moves with
{bf:observed covariates}. If you believe the threshold drifts with the
calendar -- a natural rate, a slowly changing norm -- it is
{helpb tvtlasso}. If you believe it depends on measured conditions, it is
{helpb tvtcovdep}. Both report no standard errors, for the same reason, and
both want an independent sample before you quote inference.

{pstd}
{bf:Three cases the questions above do not reach.}

{phang}
{bf:Your dependent variable is a count.} Then the family is wrong before
the threshold is even considered, and {helpb tvtinar} is the command: an
integer-valued autoregression built on binomial thinning, with the
threshold set by the empirical quantile of the recent counts. Fitting a
Gaussian threshold model to integer data is not a lesser approximation,
it is the wrong model.

{phang}
{bf:You think the threshold moved but cannot say what moved it.} Every
estimator above needs you to name the driver -- time, the variable's own
past, or some observed covariate. {helpb tvtlatent} does not: it makes
the threshold an unobserved AR(1) state and estimates the path itself.
That freedom is also the risk, because a latent path can track noise, so
read its {bf:sigma2_u} and look at the path with {helpb tvtplot} before
reading the slopes -- and note it needs about 500 observations before the
persistence parameters mean much.

{phang}
{bf:You are forecasting, and want to know whether the predictive
relation itself changed.} {helpb tvtpredreg} tests a predictive
regression against the alternative that at some unknown date it became a
threshold predictive regression. It asks about the {it:relation}, not
about a threshold in the dependent variable.

{pstd}
{bf:And if you would rather have the data narrow this down first},
{helpb tvtsel} runs the diagnostics in this guide against your own data and
ranks what they point to, with the evidence attached. It is a starting
point, not a verdict: read the rest of this page before acting on it,
because the warnings below are the part a test cannot give you.

{pstd}
{bf:But check the shape first}, because this is where the choice is most
often got wrong. A Fourier approximation is built for {it:smooth} change and
is weak against a {it:step}. From the source paper's own simulations, the
power to detect a non-constant threshold at {it:T} = 100 is about 0.53 when
the change is smooth and about 0.21 when it is a single abrupt shift; even
at {it:T} = 500 the step case reaches only 0.57 against 1.00 for the smooth
one. So a non-rejection from {cmd:tvtfourier}'s constancy test is weak
evidence when the mechanism you have in mind is a dated event, and a
specification built for shifts is the honest choice there.


{marker ambiguity}{...}
{title:What a rejection does not tell you}

{pstd}
Set out plainly, because the temptation is to read more into it:

{p 8 10 2}{bf:.} not the number of thresholds,{p_end}
{p 8 10 2}{bf:.} not whether the variation is in time or in a covariate,{p_end}
{p 8 10 2}{bf:.} not whether it is smooth or abrupt,{p_end}
{p 8 10 2}{bf:.} not the direction of the movement,{p_end}
{p 8 10 2}{bf:.} not whether the threshold {it:variable} is the right
one.{p_end}

{pstd}
A specification search run on the same data that produced the rejection will
find something, and what it finds will be overfitted to that rejection.
Where the sample allows it, decide the specification on substantive grounds
or on a held-out period, and report that you did.


{marker nonreject}{...}
{title:Reading a non-rejection}

{pstd}
{bf:A non-rejection is not proof that the threshold is constant}, and the
paper's own simulations say where the test is weak. At the 5% level, with
{it:n} = 500:

{p2colset 8 46 48 2}{...}
{p2col :against an added smooth drift in {it:q}}power about 0.72{p_end}
{p2col :against two thresholds, jumps of 0.25}power about 0.24{p_end}
{p2col :against two thresholds, jumps of 0.50}power about 0.70{p_end}
{p2colreset}{...}

{pstd}
So the case the test is weakest against is {bf:two thresholds whose jumps are
small}, and in a short sample a non-rejection is weak evidence against that
specifically. It is much stronger evidence against a pronounced smooth drift.

{pstd}
Power rises sharply with the sample: against two small-jump thresholds it is
about 0.24 at {it:n} = 500, 0.50 at 1,000 and 0.66 at 1,500. If your sample
is at the low end, say so rather than reporting constancy as established.


{marker settings}{...}
{title:Practical settings}

{phang}
{bf:Trimming is the one setting that matters, and the default is the right
one.} {opt trim(0.10)} is the paper's. Measured on the paper's designs at
{it:n} = 500 with a small effect size, raising it costs a great deal of
power and buys nothing:

{p2colset 12 30 32 2}{...}
{p2col :{space 4}{it:tau}}{space 3}size{space 6}power, smooth drift{space 4}power, two thresholds{p_end}
{p2col :{space 4}0.10}{space 3}0.035{space 10}0.93{space 20}0.18{p_end}
{p2col :{space 4}0.15}{space 3}0.020{space 10}0.76{space 20}0.14{p_end}
{p2col :{space 4}0.20}{space 3}0.005{space 10}0.49{space 20}0.05{p_end}
{p2colreset}{...}

{pstd}
{bf:So it is a size-power trade-off in which 0.10 is already the conservative
end}: size is at or below the nominal 5% at all three, and power falls by
half between 0.10 and 0.20. {opt trim()} sets how much of the threshold
variable's range the statistic integrates over, so raising it discards the
evidence along with the tails.

{pstd}
Raise it only for a reason: a regressor confined to one tail of the
threshold variable, or a refusal for a degenerate design moment. Lowering it
below 0.10 is not recommended {hline 2} the conditional moments are then
estimated from very few neighbours, and the paper's tabulated critical values
are reported for 0.10. Either way, if you change it, report it.

{phang}
{bf:Bandwidth and kernel.} Leave them alone. The critical values are pivotal
and the paper reports that reasonable alternatives change results
negligibly.

{phang}
{bf:The direction vector.} Valid for any choice, so this is about power and
interpretation rather than correctness. Use {opt direction(j)} when one
switching coefficient is the object of interest. The results are not
sensitive to it, which the paper's footnote 6 states and the certification
suite checks.

{phang}
{bf:Scale and units.} Nothing needs rescaling: the statistic is invariant to
any strictly increasing transformation of the threshold variable and to the
scale and location of the dependent variable. If a transformation of the
threshold variable changes your result, something is wrong {hline 2} report
it as a bug.


{pstd}
{bf:And if you want to know what any of this looks like before committing to
it}, {helpb tvtsim} generates data from each of the published threshold
paths {hline 2} smooth, single-shift, double-shift, logistic, two-dip,
constant, and none at all {hline 2} leaving the true path in the data as a
variable. Fitting a specification to a design whose answer you already know
is the cheapest way to find out whether it can detect what you think it can.


{marker mistakes}{...}
{title:Mistakes worth avoiding}

{phang}
{bf:Testing constancy without first testing for a threshold.} The statistic
is standardised at the estimated threshold's rank. On linear data that rank
is noise.

{phang}
{bf:Reading a rejection as an estimate.} It is not one. Nothing about the
path of the threshold is estimated by this test.

{phang}
{bf:Treating a non-rejection as a validation of the constant-threshold
model.} It is a failure to detect, and the power table above says how much
that is worth.

{phang}
{bf:Forcing a number out of a refusal.} When the command declines, the
statistic is not defined on those data. Lowering {opt trim()} until it
returns something produces a number computed where the construction does not
hold.

{phang}
{bf:Choosing the specification by fit on the same data.} Several
specifications will improve the fit over a constant threshold once the
constant threshold has been rejected. That they do is not evidence for any
one of them.

{phang}
{bf:Reporting a fitted threshold path without looking at it.} {helpb tvtplot}
draws it against the data in one line. The thing to check is whether either
regime empties out over part of the sample: a path that runs above almost
every point for a stretch is identifying one regime's coefficients from a
handful of observations, and that is invisible in the coefficient table.

{phang}
{bf:Ignoring a low} {cmd:r(rcond)}. It means some regressor is nearly
constant over part of the range of the threshold variable, so the statistic
is noisier than the sample size suggests. The test is still valid; the
precision is not what it appears.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:References}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64(2): 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Lee, Y., and Y. Wang. 2024. Testing for homogeneous thresholds in threshold
regression models. {it:Econometric Theory} 40(3): 608-651.
{browse "https://doi.org/10.1017/S0266466622000512":doi:10.1017/S0266466622000512}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvthomog}, {helpb tvtfourier}, {helpb tvtlr}, {helpb tvtcotar}, {helpb tvtmathar}, {helpb tvtcotrk}, {helpb tvtcoint}, {helpb tvtboundary}, {helpb tvtindex}, {helpb tvtstar}, {helpb tvtcovdep}, {helpb tvtlasso}, {helpb tvtinar}, {helpb tvtlatent}, {helpb tvtpredreg}, {helpb tvtsel}, {helpb tvtexport},
{helpb tvtsim}, {helpb tvtplot}
{p_end}
