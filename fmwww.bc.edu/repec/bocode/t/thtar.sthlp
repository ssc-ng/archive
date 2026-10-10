{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{viewerjumpto "Syntax" "thtar##syntax"}{...}
{viewerjumpto "Description" "thtar##description"}{...}
{viewerjumpto "Options" "thtar##options"}{...}
{viewerjumpto "Remarks: the delay trap" "thtar##delay"}{...}
{viewerjumpto "Remarks: TAR vs the alternatives" "thtar##alt"}{...}
{viewerjumpto "Examples" "thtar##examples"}{...}
{viewerjumpto "Stored results" "thtar##results"}{...}
{viewerjumpto "References" "thtar##refs"}{...}
{title:Title}

{phang}
{bf:thtar} {hline 2} Threshold autoregression: SETAR({it:m}+1; {it:p}, {it:d}) and
TAR with an exogenous threshold variable

{marker continuous}{...}
{title:The continuous SETAR, and why its threshold has a standard error}

{pstd}
{opt continuous} fits

{p 8 8 2}
{it:y_t} = {it:phi0} + {it:phi1 y_t-d} + {it:phi2} ({it:y_t-d} {c -} {it:r}) 1{c -}{it:y_t-d} > {it:r}{c )-} + (other lags) + {it:e_t}

{pstd}
The slope on the delay lag changes at {it:r} and {bf:the level does not jump}.
That single restriction changes the asymptotics completely.

{pstd}
In the ordinary SETAR the mean jumps, the threshold converges at rate
{it:n}, and its limit distribution is {bf:not normal} — which is why
{cmd:thtar} gives it an inverted-likelihood-ratio confidence set and
{bf:no standard error}, and why this package refuses to print one.

{pstd}
Chan and Tsay (1998) show that under continuity {it:r} is {bf:root-n
consistent and asymptotically normal}. So it has an ordinary standard error
and an ordinary Wald interval, and both are reported. The same result was
later obtained by Hansen (2017) for the cross-sectional kink, which is why
this option is implemented by handing the problem to {helpb thkink} on the
autoregressive design rather than by writing a second engine: the delay lag
becomes the kink variable and carries its own linear term, and the other
{opt ar()} lags are ordinary regressors.

{pstd}
Every option that concerns the inverted-likelihood-ratio set —
{opt ci()}, {opt eta2()}, {opt conservative}, {opt estimator()},
{opt hansencompat}, {opt bwidth()} — is {bf:refused} with {opt continuous},
not quietly ignored. They all describe a limit distribution that does not
apply here.

{pstd}
{bf:Which one should you fit?} That is a modelling question, not a
technical one, and the honest answer is usually "both". A continuous SETAR
says the economy's response changes {it:gradually in level} at the
threshold; a discontinuous one says it {it:jumps}. If you do not know which,
fit both and compare, and use {cmd:estat gridboot} after the discontinuous
fit — its confidence interval for the threshold is valid under {bf:either}
specification, which is precisely what it was built for.


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtar} {depvar} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt ar(numlist)}}lags of {it:depvar} to include{p_end}
{synopt:{opt delay(numlist)}}candidate delays for the self-exciting threshold; default 1{p_end}
{synopt:{opth thv:ar(varname)}}use this exogenous threshold variable instead{p_end}
{synopt:{opt nthresh(#)}}number of thresholds; default 1{p_end}
{synopt:{opt cont:inuous}}fit the CONTINUOUS (kink) SETAR, whose threshold has a standard error{p_end}
{synopt:{opt refine(#)}}refinement sweeps when {cmd:nthresh()} > 1{p_end}
{synopt:{opt regimevar(name)}}save the regime indicator in a new variable{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}

{syntab:Search and inference}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}search {it:#} quantiles instead of all distinct values{p_end}
{synopt:{opt minobs(#)}}minimum observations per regime{p_end}
{synopt:{opt vce(vcetype)}}{opt ols}, {opt r:obust} (default), {opt hc1}, {opt hc2}, {opt hc3}{p_end}
{synopt:{opt ci(method)}}{opt lr}, {opt lrstar}, {opt none}{p_end}
{synopt:{opt conserv:ative}}report the conservative inverted-LR intervals{p_end}
{synopt:{opt eta2(method)}}{opt hansen}, {opt quadratic}, {opt kernel}{p_end}
{synopt:{opt est:imator(left|midpoint)}}point-estimate convention{p_end}
{synopt:{opt het:var}}a separate innovation variance in each regime: the Gaussian criterion, not the total SSR{p_end}
{synopt:{opt rho(#)}}level of the threshold set used by {cmd:estat twostep}; default {cmd:rho(0.8)}{p_end}
{synopt:{opt level(#)}}confidence level{p_end}

{syntab:Test}
{synopt:{opt test}}test H0: no threshold effect{p_end}
{synopt:{opt stat(sup|ave|exp)}}test statistic; default {cmd:sup}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 1000{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt hansencompat}}reproduce Hansen's published code conventions{p_end}
{synoptline}
{p 4 6 2}* {opt ar()} is required. The data must be {helpb tsset}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thtar} fits a threshold autoregression. In the self-exciting case
(SETAR) the series switches on its own past:

{p 12 12 2}
{it:y_t} = (φ{sub:1}'{it:x_t})·1{c -(}{it:y_{t-d}} {c -} {it:γ}{c )-} +
(φ{sub:2}'{it:x_t})·1{c -(}{it:y_{t-d}} > {it:γ}{c )-} + {it:e_t}

{pstd}
with {it:x_t} = (1, {it:y_{t-j}} for {it:j} in {opt ar()}). With
{opt thvar()} the switch is driven by any other observed series instead.

{pstd}
{cmd:thtar} builds the autoregression for you, searches the delay, and hands
the design to the same engine that {helpb thregress} uses, so everything that
command offers — the inverted-LR confidence set, the heteroskedasticity-robust
test, the bootstrap, {cmd:estat}, {cmd:predict} — is available here unchanged.

{pstd}
Official Stata's {helpb threshold} can fit a threshold model on time-series data
but has no test, no confidence interval for the threshold, and no delay search.

{marker options}{...}
{title:Options}

{phang}
{opt ar(numlist)} lists the lags. {cmd:ar(1 2 3)} is an AR(3); {cmd:ar(1 12)} is
a subset autoregression with only the first and twelfth lags, which is often what
monthly data want.

{phang}
{opt delay(numlist)} gives the candidate delays {it:d} for the self-exciting
threshold variable {it:y_{t-d}}. With one value the delay is fixed; with several
the one minimising the SSR is selected and reported. {bf:Read the next section
before combining a delay search with {cmd:test}.}

{phang}
{opth thvar(varname)} replaces the self-exciting threshold by an observed series.
It may be any time-series expression, for instance a {it:k}-period change in the
level. It cannot be combined with a multi-value {opt delay()}.

{phang}
{opt regimevar(name)} saves the regime classification, which is usually the first
thing you want to plot against the series.

{pstd}
All remaining options behave exactly as in {helpb thregress}; see that help file
for the inference details, in particular why bootstrap confidence intervals for
the threshold are refused. Two of them are worth naming here because they change
results rather than presentation. {opt hetvar} replaces the total-SSR criterion by
the concentrated Gaussian one, which gives each regime its own innovation
variance; with regimes of very different volatility -- common in the threshold
autoregressions this command is for -- it generally selects a {bf:different}
threshold, and the default criterion is pulled towards the noisier regime. See
{help thregress##hetvar:thregress} for the criterion and its one-threshold
restriction. {opt rho(#)} sets the level of the threshold confidence set over
which {cmd:estat twostep} takes its union; Hansen (2000, Table III) recommends
the default 0.8.

{marker delay}{...}
{title:Remarks: the delay trap}

{pstd}
If you search over several delays {bf:and} ask for the threshold test, the
reported p-value is not a valid test of linearity: the delay was chosen to
minimise the SSR, so the test is conditional on a data-dependent choice and the
nominal size is wrong. {cmd:thtar} prints a warning when you do this.

{pstd}
Two defensible routes:

{phang2}
{bf:1.} Fix the delay on theory ({cmd:delay(1)}, or {cmd:delay(12)} for monthly
seasonal adjustment) and report that test.

{phang2}
{bf:2.} Treat the search as exploratory, say so, and get the p-value from a
procedure that searches inside the bootstrap. That is on the roadmap; it is not
what {opt test} does today.

{pstd}
The same caution applies to choosing {opt ar()} by looking at the data.

{marker alt}{...}
{title:Remarks: TAR, STAR or Markov switching?}

{p2colset 6 24 26 2}{...}
{p2col:{bf:thtar}}The regime is decided by an {it:observed} value — the series' own past, or another series. Sharp switch. Interpretable and testable.{p_end}
{p2col:{bf:thstar}}Same idea but the switch is gradual. Harder to estimate: the smoothness parameter is often weakly identified.{p_end}
{p2col:{helpb mswitch}}The regime is {it:latent} and follows a Markov chain. Nothing observable triggers it. Already in official Stata.{p_end}
{p2colreset}{...}

{pstd}
The choice is substantive, not statistical. If you can name the variable that
does the switching, a threshold model says more than a latent-state model, and it
is falsifiable: {opt test} can reject it.

{marker examples}{...}
{title:Examples}

{pstd}The shipped data are Hansen's (1997) US unemployment series, men 20+,
1959m1-1996m7.{p_end}

{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Reproduce Hansen (1997): twelve lags of the first difference, with the
12-month change in the level as the threshold variable{p_end}

{phang2}{cmd:. thtar dy, ar(1/12) thvar(q) hansencompat}{p_end}

{pstd}A plain SETAR with the delay fixed at 1{p_end}
{phang2}{cmd:. thtar dy, ar(1/3) delay(1) test}{p_end}

{pstd}Search the delay (exploratory — note the warning){p_end}
{phang2}{cmd:. thtar dy, ar(1/3) delay(1 2 3 6 12)}{p_end}

{pstd}Three regimes, with refinement, and save the classification{p_end}
{phang2}{cmd:. thtar dy, ar(1/3) delay(12) nthresh(2) refine(10) regimevar(reg)}{p_end}
{phang2}{cmd:. tsline dy if reg==1}{p_end}

{pstd}Post-estimation is the {helpb thregress} suite{p_end}
{phang2}{cmd:. estat lrplot}{p_end}
{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat table}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thtar} is {it:eclass} and stores everything {helpb thregress} stores, plus{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(delay)}}selected delay (self-exciting case){p_end}
{synopt:{cmd:e(k_lags)}}number of autoregressive lags{p_end}
{synopt:{cmd:e(pmax)}}largest lag used{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thtar}{p_end}
{synopt:{cmd:e(model)}}{cmd:setar} or {cmd:tar}{p_end}
{synopt:{cmd:e(arlags)}, {cmd:e(arnames)}}the lags requested and their names{p_end}
{synopt:{cmd:e(delays)}}the candidate delays searched{p_end}
{synopt:{cmd:e(timevar)}}time variable from {cmd:tsset}{p_end}
{p2colreset}{...}

{marker valid}{...}
{title:Validation}

{pstd}
Checked against Hansen's own {bf:snde_97} R code on his own data: threshold
0.3020402, 95% interval [0.212918, 0.339885], joint SSR 11.73065, 438
observations split 314/124 — all reproduced exactly. See
{bf:tests/reference/thtar/certify_thtar.do}.

{marker ugirf}{...}
{title:estat girf: the response to a shock, when there is no single response}

{pstd}
In a linear model the response to a shock is a property of the model alone:
invert the lag polynomial and you are done. In a threshold model it is not.
The response depends on

{p 8 12 2}
the {bf:history} the shock arrives into, because that decides which regime
the system is in and how close it is to switching;

{p 8 12 2}
the {bf:sign} of the shock, because a shock that pushes the system across
the threshold does something a shock of the same size the other way does
not;

{p 8 12 2}
the {bf:size} of the shock, for the same reason — {bf:responses do not
scale}. The answer to a two-sigma shock is not twice the answer to a
one-sigma shock.

{pstd}
So {cmd:estat girf} computes the generalised impulse response of Koop,
Pesaran and Potter (1996),

{p 8 8 2}
GIRF({it:h}, {it:delta}, {it:omega}) = E[{it:y_t+h} | {it:e_t} = {it:delta}, {it:omega}] {c -} E[{it:y_t+h} | {it:omega}]

{pstd}
by simulation. Both expectations are simulated and the two paths share the
{bf:same future shocks}, so their difference isolates the effect of
{it:delta} rather than Monte Carlo noise.

{pstd}
Four responses are printed together, and {bf:the comparison is the point}:
to +{it:delta}, to {c -}{it:delta}, and conditional on the shock arriving
in each regime. In a linear model the first two would be exact mirror
images and the last two identical. {bf:Where they are not, that difference
is the nonlinearity} — and it is the only part of the table a linear model
could not have produced. A GIRF whose four columns agree is telling you the
threshold is not doing any work.

{pstd}
Two requirements, both refused with a reason rather than worked around. The
model must be {bf:self-exciting}: the transition variable has to be a lag of
the dependent variable, so the simulation can compute it forward. With an
exogenous threshold variable the future path is unknown, and freezing it
would answer a different question. And the delay must be one of the
autoregressive lags, or the transition variable is not part of the state the
model propagates.

{synoptset 20 tabbed}{...}
{synopthdr:girf option}
{synoptline}
{synopt:{opt size(#)}}shock size in the units of {it:y}; default 1. The
residual standard deviation is printed beside it for scale{p_end}
{synopt:{opt h:orizon(#)}}horizons; default 12{p_end}
{synopt:{opt reps(#)}}simulated paths per history; default 200{p_end}
{synopt:{opt hist:ories(#)}}histories averaged over; default 150, taken
evenly spaced through the sample so the answer does not move with the
seed for a reason unrelated to the model{p_end}
{synopt:{opt boot(string)}}{opt resample} (default) draws shocks from the
residuals; {opt normal} draws them from a fitted normal. Resampling is the
default because a threshold model's residuals are routinely skewed, and the
response to a large shock is exactly where that matters{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt gr:aph}}plot all four responses{p_end}
{synopt:{opt sav:ing()}}save that graph{p_end}
{synoptline}


{marker refs}{...}
{title:References}

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis
in nonlinear multivariate models.
{it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}

{phang}
Chan, K. S., and R. S. Tsay. 1998. Limiting properties of the least squares
estimator of a continuous threshold autoregressive model.
{it:Biometrika} 85: 413-426.
{browse "https://doi.org/10.1093/biomet/85.2.413":doi:10.1093/biomet/85.2.413}

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics} 21:
520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}.

{phang}
Hansen, B. E. 1996. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 1997. Inference in TAR models. {it:Studies in Nonlinear Dynamics &
Econometrics} 2(1): 1-14.
{browse "https://doi.org/10.2202/1558-3708.1024":doi:10.2202/1558-3708.1024}.

{phang}
Hansen, B. E. 1999. Testing for linearity. {it:Journal of Economic Surveys} 13:
551-576.
{browse "https://doi.org/10.1111/1467-6419.00098":doi:10.1111/1467-6419.00098}.

{phang}
Tong, H. 1990. {it:Non-linear Time Series: A Dynamical System Approach}. Oxford
University Press.

{phang}
Tsay, R. S. 1989. Testing and modeling threshold autoregressive processes.
{it:JASA} 84: 231-240.
{browse "https://doi.org/10.1080/01621459.1989.10478760":doi:10.1080/01621459.1989.10478760}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thregress}, {helpb thtest},
{helpb thselect}, {helpb thkink}, {helpb thsubtar}, {helpb thtarsel},
{helpb thforecast}, {helpb thexport} (publication tables from this fit),
{helpb thsim} (simulate from this model), {helpb mswitch}
{p_end}
