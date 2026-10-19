{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtsim" "help tvtsim"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{vieweralsosee "tvtlr" "help tvtlr"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{vieweralsosee "tvtmathar" "help tvtmathar"}{...}
{vieweralsosee "tvtcotrk" "help tvtcotrk"}{...}
{vieweralsosee "tvtcoint" "help tvtcoint"}{...}
{vieweralsosee "tvtboundary" "help tvtboundary"}{...}
{vieweralsosee "tvtindex" "help tvtindex"}{...}
{vieweralsosee "tvtstar" "help tvtstar"}{...}
{vieweralsosee "tvtcovdep" "help tvtcovdep"}{...}
{vieweralsosee "tvtlasso" "help tvtlasso"}{...}
{vieweralsosee "tvtpredreg" "help tvtpredreg"}{...}
{vieweralsosee "tvtinar" "help tvtinar"}{...}
{vieweralsosee "tvtlatent" "help tvtlatent"}{...}
{vieweralsosee "tvtsel" "help tvtsel"}{...}
{vieweralsosee "tvtexport" "help tvtexport"}{...}
{viewerjumpto "Description" "tvthresh##description"}{...}
{viewerjumpto "Start here" "tvthresh##start"}{...}
{viewerjumpto "The commands" "tvthresh##commands"}{...}
{viewerjumpto "Scope" "tvthresh##scope"}{...}
{viewerjumpto "Relation to THRESHKIT" "tvthresh##threshkit"}{...}
{viewerjumpto "Conventions" "tvthresh##conventions"}{...}
{viewerjumpto "Author" "tvthresh##author"}{...}
{title:Title}

{phang}
{bf:tvthresh} {hline 2} Time-varying threshold models and tests: library
overview


{marker description}{...}
{title:Description}

{pstd}
{bf:TVTHRESH} is a library for threshold models whose {bf:threshold itself
is not constant}. An ordinary threshold regression,

{p 8 8 2}
{it:y_i} = {it:x_i'beta} + {it:x_i'delta} 1[{it:q_i} {ul:<} {it:gamma}] +
{it:u_i},

{pstd}
assumes one number {it:gamma} governs every observation. That assumption is
testable, and when it fails the usual estimators are inconsistent for
anything interpretable. This library provides the test and the specifications
that replace the constant.

{pstd}
Every command is implemented from the published equations of its source
paper, validated numerically against whatever the paper reports {hline 2}
tabulated critical values, published size and power tables, replicated
applications {hline 2} and documented with an equation-by-equation
concordance in the {bf:validation/} directory of the distribution.


{marker start}{...}
{title:Start here}

{pstd}
{bf:Run} {helpb tvthomog} {bf:first.} It tests whether the threshold is
constant and it is cheap: no bootstrap, no search under the alternative,
pivotal tabulated critical values, one least-squares fit.

{phang2}
{bf:Not rejected} {hline 2} a constant-threshold command is the right tool
and the more efficient one. Use {bf:THRESHKIT} (a separate package) or
{helpb regress}-based alternatives, and stop here. (Bear in mind that
non-rejection is not proof: the test has limited power against two thresholds
with small jumps.)

{phang2}
{bf:Rejected} {hline 2} a constant-threshold model is misspecified. Which
time-varying specification fits is a separate question that the test does not
answer, because several quite different departures all violate the same null.

{pstd}
The test tells you {it:that} the threshold moves, never {it:how}. Working
out which specification the data call for is a separate step, and
{helpb tvthresh_choose} is the guide to it.


{marker commands}{...}
{title:The commands}

{pstd}
{bf:Specification testing}

{synoptset 20 tabbed}{...}
{synopt :{helpb tvthomog}}test whether the threshold is constant (Lee and
Wang's CT test){p_end}
{synopt :{helpb tvtlr}}test whether an AR model became a threshold AR model
at an unknown date{p_end}
{synopt :{helpb tvtpredreg}}test whether a PREDICTIVE regression became a
threshold predictive regression at an unknown date (Zhu, Liu, Ling and
Cai){p_end}

{pstd}
{bf:Estimation}

{synopt :{helpb tvtfourier}}threshold regression with a Fourier
time-varying threshold (Yang, Lee and Chen){p_end}
{synopt :{helpb tvtcotar}}conditional threshold autoregression: the
threshold tracks the recent past (Motegi, Dennis and Hamori){p_end}
{synopt :{helpb tvtmathar}}moving average threshold HAR: the threshold is an
observed moving average, so no bootstrap is needed (Motegi, Cai, Hamori and
Xu){p_end}
{synopt :{helpb tvtcotrk}}conditional threshold regression KINK: continuous
at the threshold, with the memory estimated (Yang){p_end}
{synopt :{helpb tvtcoint}}threshold COINTEGRATION with the threshold a
linear function of observed covariates (Yang){p_end}
{synopt :{helpb tvtboundary}}threshold BOUNDARY: the same threshold
function on stationary data, with the interval that is actually valid
(Yu and Fan){p_end}
{synopt :{helpb tvtindex}}threshold on a linear INDEX, estimated by
SMOOTHED least squares so that the threshold is asymptotically normal and
discrete variables can split the sample (Seo and Linton){p_end}
{synopt :{helpb tvtstar}}SMOOTH transition whose threshold depends on
observed state variables; the weights are probabilities the model itself
implies (Dueker, Psaradakis, Sola and Spagnolo){p_end}
{synopt :{helpb tvtcovdep}}CHOOSES the specification: which regressors,
which of them shift between regimes, and which variables move the
threshold, all at once (Yang){p_end}
{synopt :{helpb tvtinar}}COUNTS: an integer-valued autoregression whose
threshold is the empirical quantile of recent counts. The only count
command here, and a Gaussian threshold model is the wrong family for
integer data however the threshold behaves (Jia, Zhu, Wang and Li){p_end}
{synopt :{helpb tvtlatent}}the threshold is a LATENT AR(1) state -- a
function of nothing observed at all -- estimated by MCMC (Zhu, Chen and
Lin){p_end}
{synopt :{helpb tvtlasso}}HIGH-DIMENSIONAL Fourier threshold: weighted
LASSO when there may be more candidate regressors than observations;
selects them and decides whether there is a threshold effect at all
(Yang){p_end}

{pstd}
{bf:Guides}

{synopt :{helpb tvtsel}}runs the diagnostics below on YOUR data and ranks
the specifications they point to; start here when the choice is open{p_end}
{synopt :{helpb tvthresh_choose}}which specification to fit, and how to read
a rejection{p_end}

{pstd}
{bf:Tools}

{synopt :{helpb tvtsim}}simulate from any of the published threshold-path
designs{p_end}
{synopt :{helpb tvtplot}}plot a fitted threshold path against the data{p_end}
{synopt :{helpb tvtexport}}publication tables in LaTeX, Markdown, RTF or
CSV, with the threshold and the tests in them, not just the
coefficients{p_end}

{pstd}
Further commands are added to this library as each is implemented and
validated; this page lists only what is installed and certified. The
development plan, with the source paper behind each planned command, is in
{bf:research/TVTHRESH_DISCOVERY.md} in the distribution.


{marker scope}{...}
{title:Scope}

{pstd}
{bf:In scope:} cross-sectional and time-series threshold models in which the
threshold varies {hline 2} smoothly over time, in discrete shifts, as a
function of covariates, or latently.

{pstd}
{bf:Out of scope:} panel-data threshold estimators. They are a separate
literature with their own identification problems and are deliberately not
addressed here.


{marker threshkit}{...}
{title:Relation to THRESHKIT}

{pstd}
TVTHRESH is an {bf:independent} library. It installs separately, it does not
require THRESHKIT, and nothing in it will break if THRESHKIT is absent or at
a different version.

{pstd}
The two are complements, and the division is clean: THRESHKIT estimates and
tests threshold models whose threshold is a constant; TVTHRESH tests that
assumption and provides the models for when it fails. {helpb tvthomog} is the
command that tells you which library you need. Where the two fit the same
object {hline 2} the constant-threshold model under the null {hline 2} they
are checked against each other and agree to machine precision.


{marker conventions}{...}
{title:Conventions}

{pstd}
Shared across the library, so they need learning once.

{phang}
{bf:Threshold variable.} Always named by a {cmd:threshvar()} option, never
taken positionally.

{phang}
{bf:Trimming.} {cmd:trim()} is a fraction in (0, 0.5) and confines both the
candidate thresholds and the test construction to the ranks strictly inside
({it:tau}, 1 - {it:tau}). The default follows each source paper.

{phang}
{bf:Grid caps.} {cmd:gridn()} is an {bf:upper bound} on the number of
candidates, not the number used; the realised count is always returned.

{phang}
{bf:Refusing beats guessing.} When a construction is not defined on the data
{hline 2} a threshold at the boundary, a locally singular design matrix
{hline 2} the command exits with a diagnosis naming the cause and what to do,
rather than returning a number it cannot stand behind.

{phang}
{bf:Stored results.} Tests are {cmd:r}-class and leave {cmd:e()} untouched;
estimators are {cmd:e}-class. Critical values are returned at all tabulated
levels, so a decision at another level needs no re-run.

{phang}
{bf:No invented numbers.} Where a paper tabulates critical values, those are
shipped and reproduced by simulation in the certification suite. A level the
paper does not tabulate is reported as such rather than interpolated.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthomog}, {helpb tvtfourier}, {helpb tvtlr}, {helpb tvtcotar}, {helpb tvtmathar}, {helpb tvtcotrk}, {helpb tvtcoint}, {helpb tvtboundary}, {helpb tvtindex}, {helpb tvtstar}, {helpb tvtcovdep}, {helpb tvtlasso}, {helpb tvtinar}, {helpb tvtlatent}, {helpb tvtpredreg}, {helpb tvtsel}, {helpb tvtexport},
{helpb tvtsim}, {helpb tvtplot},
{helpb tvthresh_choose}, {helpb regress}
{p_end}
