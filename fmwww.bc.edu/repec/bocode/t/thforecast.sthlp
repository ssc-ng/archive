{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thstar" "help thstar"}{...}
{vieweralsosee "forecast" "help forecast"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thforecast##syntax"}{...}
{viewerjumpto "Description" "thforecast##description"}{...}
{viewerjumpto "Options" "thforecast##options"}{...}
{viewerjumpto "Why iterating with zero errors is wrong" "thforecast##skeleton"}{...}
{viewerjumpto "Which method to use" "thforecast##which"}{...}
{viewerjumpto "Reading the forecast density" "thforecast##density"}{...}
{viewerjumpto "Why an exogenous threshold is refused" "thforecast##exog"}{...}
{viewerjumpto "What is NOT provided" "thforecast##limits"}{...}
{viewerjumpto "Examples" "thforecast##examples"}{...}
{viewerjumpto "Stored results" "thforecast##results"}{...}
{viewerjumpto "References" "thforecast##refs"}{...}
{title:Title}

{phang}
{bf:thforecast} {hline 2} Multi-step forecasts, forecast densities and fan
charts from a fitted threshold autoregression


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thforecast} [{it:newvarstub}] [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt h:orizon(#)}}steps ahead; default {cmd:horizon(12)}{p_end}
{synopt:{opt meth:od(string)}}{opt bootstrap} (default), {opt montecarlo} or {opt skeleton}{p_end}
{synopt:{opt reps(#)}}simulated paths; default 1000{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt l:evel(numlist)}}one to three interval levels; default {cmd:level(95)}{p_end}
{synopt:{opt graph}}fan chart of the history and the forecast{p_end}
{synopt:{opt saving(filename)}}export that graph{p_end}
{synopt:{opt replace}}overwrite the forecast variables{p_end}
{synopt:{opt noskel:eton}}suppress the skeleton comparison table{p_end}
{synoptline}
{p 4 6 2}
{cmd:thforecast} is {helpb return:rclass} and runs after {helpb thtar} or
{helpb thstar}. The threshold variable must be a lag of the series being
forecast; see {it:Why an exogenous threshold is refused}.{p_end}
{p 4 6 2}
With {it:newvarstub} it creates {it:stub}, {it:stub}{cmd:_lo} and
{it:stub}{cmd:_hi} and fills them at the future dates. Run
{helpb tsappend}{cmd:, add(}{it:h}{cmd:)} first to make room.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thforecast} produces h-step-ahead forecasts from a fitted threshold
autoregression by simulating the model forward, recomputing the regime at
every step from the path itself.

{pstd}
That last clause is the whole command. A shock can push the process across
the threshold, and from then on the dynamics are the other regime's. No
closed-form formula captures this, which is why the forecast has to be
simulated and why the forecast {it:density} — not just a point and a standard
error — is the natural object.

{pstd}
Three things are reported:

{p 8 8 2}
o the point forecast at each horizon, with its median and standard
deviation across paths;{p_end}
{p 8 8 2}
o empirical forecast intervals at up to three levels, taken as quantiles of
the simulated paths rather than as point ± z·s.d.;{p_end}
{p 8 8 2}
o the share of simulated paths in regime 1 at each horizon — the diagnostic
that says whether the threshold is doing anything to this forecast at all.{p_end}

{pstd}
And, unless you switch it off, a fourth: a side-by-side comparison with the
{bf:deterministic skeleton}, which is what you get by iterating the model with
the errors set to zero. For a linear model that equals the conditional
expectation. For a threshold model it does not, and the next section explains
why that matters more than it sounds.


{marker options}{...}
{title:Options}

{phang}
{opt horizon(#)} is the number of steps ahead. There is no upper limit, but
remember that the interval widens toward the model's unconditional
distribution and stops being informative well before it stops being
computable.

{phang}
{opt method(bootstrap|montecarlo|skeleton)} chooses how the future errors are
generated. See {it:Which method to use}. The default {opt bootstrap} resamples
the fitted residuals; they are {bf:centred} first, because an uncentred draw
adds the residual mean to every step and over h steps that accumulates into a
visible drift that is pure artefact.

{phang}
{opt reps(#)} is the number of simulated paths. The Monte Carlo error in the
point forecast falls like 1/sqrt(reps); the error in a 2.5% quantile falls
much more slowly, so raise it when the interval matters. {opt reps()} is
ignored by {opt method(skeleton)}, which has one path by construction.

{phang}
{opt seed(string)} sets the seed. Always set it: a simulated forecast is not
reproducible without one, and an unseeded forecast interval cannot be checked
by a referee.

{phang}
{opt level(numlist)} gives one to three interval levels, e.g.
{cmd:level(50 80 95)}. The first one is the one written to
{it:stub}{cmd:_lo} / {it:stub}{cmd:_hi} and drawn by {opt graph}.

{phang}
{opt graph} draws a fan chart: the last observations, the forecast path and
the first requested band, joined at the last observation so the chart is
continuous.

{phang}
{opt noskeleton} suppresses the skeleton comparison. Use it only once you have
looked at it; it is the table that tells you whether the nonlinearity is
affecting the forecast.


{marker skeleton}{...}
{title:Why iterating with zero errors is wrong}

{pstd}
For a linear AR the h-step forecast is obtained by iterating the model with
the errors set to zero, because E[f(y)] = f(E[y]) when f is linear. A
threshold model's f is not linear, so

{p 8 8 2}
f(f(...f(y{subscript:T})))   {&ne}   E[y{subscript:T+h} {c |} y{subscript:T}]

{pstd}
and the two differ by exactly the amount the nonlinearity bends the
conditional mean. The left-hand object is the {bf:deterministic skeleton}. It
is a perfectly legitimate description of the model's dynamics — it is what the
system does if nothing further happens to it, and it is how you find the
model's fixed points and limit cycles — but it is {bf:not} a conditional
expectation and should never be reported as a forecast.

{pstd}
The gap does {bf:not} shrink as the sample grows. It is bias from computing
the wrong object, not sampling error. Clements and Smith (1997) show it is
large enough to reverse forecast-accuracy rankings between a SETAR and a
linear AR: evaluate the SETAR by its skeleton and the linear model wins;
evaluate it by simulation and the SETAR wins. That is why the comparison table
is printed by default.

{pstd}
A practical rule: if the largest skeleton gap is small relative to the
forecast standard deviation, the nonlinearity is not biting over this horizon
from this starting point, and you should say so. If it is large, report the
simulated forecast and say that the skeleton would have been misleading.


{marker which}{...}
{title:Which method to use}

{pstd}
{bf:bootstrap} (the default). Future errors are resampled from the fitted
residuals. Unbiased for the conditional expectation without assuming
Gaussianity, which matters here more than in a linear model: threshold series
often have skewed residuals, and a skewed error distribution interacts with
the regime boundary — it makes one direction of crossing more likely than the
other. Use this unless you have a reason not to.

{pstd}
{bf:montecarlo}. Future errors are drawn N(0, {&sigma}-hat{sup:2}). Unbiased
if the errors really are Gaussian, and smoother in the tails of the forecast
density because it is not limited to the residual values actually observed.
Prefer it when the sample is short, so there are too few residuals to resample
from, and when a normality test on the residuals does not reject
({helpb thtar}'s {bf:estat normality}).

{pstd}
{bf:skeleton}. One deterministic path, no shocks. Report it as a description
of the dynamics, never as a forecast. It is also the fastest way to see
whether the fitted model is explosive in one regime.

{pstd}
{bf:The two stochastic methods should agree.} If {opt bootstrap} and
{opt montecarlo} give materially different point forecasts, the residuals are
not Gaussian and the bootstrap is the one to trust. That comparison costs one
extra command and is worth reporting.


{marker density}{...}
{title:Reading the forecast density}

{pstd}
The interval columns are {bf:empirical quantiles} of the simulated paths, not
point forecast ± z·s.d. This is deliberate and it matters.

{pstd}
A threshold model's forecast density can be {bf:skewed}, because the two
regimes have different means, and it can be {bf:bimodal}, because the paths
split into those that crossed the threshold and those that did not. When it is
bimodal, the point forecast sits in the {it:trough} between the two modes and
is the least likely value in the distribution — a symmetric interval around it
is then wrong in both directions at once.

{pstd}
Three signs to look for in the output:

{p 8 8 2}
1. the mean and the median far apart {&rarr} skewed;{p_end}
{p 8 8 2}
2. the regime-1 share near 0.5 at some horizon {&rarr} the paths are
splitting, so look for bimodality;{p_end}
{p 8 8 2}
3. the interval markedly asymmetric about the point forecast {&rarr} report
the quantiles, not a standard error.{p_end}

{pstd}
The regime-share column is the cheapest diagnostic in the table. If it is 0 or
1 at every horizon, every simulated path stayed in one regime, the threshold
never binds over this horizon from this starting point, and a linear model
fitted to that regime would have produced the same forecast. Say so rather
than claiming the nonlinearity mattered.

{pstd}
After {helpb thstar} there are no regimes to count, so the column reports the
average weight the transition function puts on the lower block instead, which
is what actually drives the forecast.


{marker exog}{...}
{title:Why an exogenous threshold is refused}

{pstd}
A dynamic forecast has to know the regime at every future date. That means the
threshold variable must be computable from the forecast path itself — a lag of
the series being forecast. {cmd:thtar} without {opt thvar()}, and
{cmd:thstar} with {opt delay()}, both satisfy this.

{pstd}
With an exogenous threshold variable the future regime depends on {it:that}
variable's own future path, which this command does not have. There are two
honest options and {cmd:thforecast} does neither silently:

{p 8 8 2}
o forecast the threshold variable with its own model and condition on that
path, which makes the forecast a joint statement about two models and should
be reported as such; or{p_end}
{p 8 8 2}
o treat the threshold variable's path as given by the scenario you are
interested in, and say what the scenario is.{p_end}

{pstd}
What it will not do is substitute the threshold variable's last observed value
and carry on. That is a forecast of a different model — one in which the
threshold variable is frozen — and nothing in the output would tell you.

{pstd}
The same restriction applies to {helpb thtvar}'s and {helpb thstvar}'s
{bf:estat girf}, for the same reason.


{marker limits}{...}
{title:What is NOT provided}

{pstd}
Stated plainly.

{phang}
o {bf:Parameter uncertainty is not included.} The simulation treats the
estimated coefficients and the threshold as known and propagates only future
shocks. The intervals are therefore {bf:too narrow}, and more so at short
horizons where shock uncertainty is small relative to estimation uncertainty.
A full treatment would resample the parameters as well, which for a threshold
model means re-estimating the threshold inside each draw; that is not
implemented and is not approximated.

{phang}
o {bf:No multivariate forecast.} After {helpb thtvar}, {helpb thstvar} or
{helpb thtvecm} every equation's future path is needed at once, which is a
different object; use {bf:estat girf} for the dynamics of those models.

{phang}
o {bf:No forecast evaluation.} There is no rolling-origin loop, no RMSE table
and no Diebold-Mariano test. Those are the right next step and are not here.

{phang}
o {bf:No conditional forecast.} You cannot pin y at a future date and
simulate around it.

{phang}
o {bf:Not after} {helpb thmtar}{bf:,} {helpb thqreg}{bf:,} {helpb thtqar} or
{helpb thqkink}. The first needs a cointegrating system's future path; the
quantile commands estimate a conditional quantile, which does not iterate —
the quantile of a sum is not the sum of quantiles.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Fit a SETAR and forecast 12 steps by bootstrap{p_end}
{phang2}{cmd:. thtar dy, ar(1 2) delay(1)}{p_end}
{phang2}{cmd:. thforecast, horizon(12) reps(2000) seed(20261006)}{p_end}

{pstd}Three bands and a fan chart{p_end}
{phang2}{cmd:. thforecast, horizon(24) level(50 80 95) graph seed(20261006)}{p_end}

{pstd}Compare the two stochastic methods: if they differ, the residuals are not Gaussian{p_end}
{phang2}{cmd:. thforecast, horizon(12) method(bootstrap) seed(1)}{p_end}
{phang2}{cmd:. thforecast, horizon(12) method(montecarlo) seed(1)}{p_end}

{pstd}The skeleton on its own, as a description of the dynamics{p_end}
{phang2}{cmd:. thforecast, horizon(40) method(skeleton)}{p_end}

{pstd}Write the forecasts into the data{p_end}
{phang2}{cmd:. tsappend, add(12)}{p_end}
{phang2}{cmd:. thforecast fc, horizon(12) seed(20261006)}{p_end}
{phang2}{cmd:. twoway (line dy t) (line fc t) (rarea fc_hi fc_lo t)}{p_end}

{pstd}After a smooth transition fit{p_end}
{phang2}{cmd:. thstar dy, ar(1 2 3) type(lstar1) delay(1)}{p_end}
{phang2}{cmd:. thforecast, horizon(12) seed(20261006)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thforecast} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(horizon)}}steps ahead{p_end}
{synopt:{cmd:r(n_paths)}}simulated paths{p_end}
{synopt:{cmd:r(delay)}}delay of the threshold variable{p_end}
{synopt:{cmd:r(skel_gap)}}largest simulated-minus-skeleton gap{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thforecast}{p_end}
{synopt:{cmd:r(method)}}the method used{p_end}
{synopt:{cmd:r(depvar)}}series forecast{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(forecast)}}horizon x (4 + 2·levels): {cmd:forecast median sd
regime1_share}, then a lower/upper pair per level{p_end}
{synopt:{cmd:r(skeleton)}}horizon x 1, the deterministic path{p_end}
{synopt:{cmd:r(shares)}}horizon x regimes, the full regime-share matrix{p_end}


{marker refs}{...}
{title:References}

{phang}
Clements, M. P., and J. Smith. 1997. The performance of alternative
forecasting methods for SETAR models. {it:International Journal of
Forecasting} 13: 463-475.
{browse "https://doi.org/10.1016/S0169-2070(97)00017-4":doi:10.1016/S0169-2070(97)00017-4}.

{phang}
Tong, H. 1990. {it:Non-linear Time Series: A Dynamical System Approach}.
Oxford: Oxford University Press.

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis in
nonlinear multivariate models. {it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com
{p_end}


{title:Also see}

{psee}
Manual: {helpb threshkit}, {helpb threshkit_choose}

{psee}
Online: {helpb thtar}, {helpb thstar}, {helpb thsearch},
{helpb thunitroot}, {helpb tsappend}, {helpb forecast}
{p_end}
