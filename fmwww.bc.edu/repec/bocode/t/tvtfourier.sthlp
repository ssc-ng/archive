{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtfourier##syntax"}{...}
{viewerjumpto "Description" "tvtfourier##description"}{...}
{viewerjumpto "What it is good at, and what it is not" "tvtfourier##scope"}{...}
{viewerjumpto "Options" "tvtfourier##options"}{...}
{viewerjumpto "How long it takes" "tvtfourier##cost"}{...}
{viewerjumpto "How it works" "tvtfourier##method"}{...}
{viewerjumpto "The two tests" "tvtfourier##tests"}{...}
{viewerjumpto "Inference" "tvtfourier##inference"}{...}
{viewerjumpto "Choices the paper leaves open" "tvtfourier##choices"}{...}
{viewerjumpto "Examples" "tvtfourier##examples"}{...}
{viewerjumpto "Stored results" "tvtfourier##results"}{...}
{viewerjumpto "Validation" "tvtfourier##validation"}{...}
{viewerjumpto "References" "tvtfourier##references"}{...}
{viewerjumpto "Author" "tvtfourier##author"}{...}
{title:Title}

{phang}
{bf:tvtfourier} {hline 2} Threshold regression with a Fourier time-varying
threshold


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtfourier} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth thr:eshvar(varname)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opth thr:eshvar(varname)}}the threshold variable {it:q}{p_end}
{synopt :{opt kmax(#)}}largest frequency searched; default {cmd:kmax(5)},
the paper's{p_end}
{synopt :{opt nocons:tant}}suppress the constant{p_end}

{syntab:Search}
{synopt :{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt :{opt ng:rid(#)}}points per side of the Fourier-coefficient grid;
default {cmd:ngrid(15)}{p_end}
{synopt :{opt amp:litude(#)}}grid half-width in robust standard deviations
of {it:q}; default {cmd:amplitude(2)}{p_end}
{synopt :{opt ref:ine(#)}}coarse-to-fine passes; default
{cmd:refine(2)}{p_end}

{syntab:Inference}
{synopt :{opt reps(#)}}wild bootstrap replications; default {cmd:reps(0)},
which gives {bf:no p-values}{p_end}
{synopt :{opt bl:evel(#)}}level for the bootstrap intervals; default
{cmd:blevel(95)}{p_end}
{synopt :{opt noci}}skip the bootstrap confidence intervals{p_end}
{synopt :{opt level(#)}}level for the coefficient table{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required.{p_end}
{p 4 6 2}
The data must be equally spaced in time, because the threshold is a function
of time. If the data are {helpb tsset} and the estimation sample has a gap,
{cmd:tvtfourier} refuses rather than fit the wrong basis.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtfourier} fits

{p 8 8 2}
{it:y_t} = {it:b1'x_t} + {it:e_t}{space 4}if {it:q_t} {ul:<}
{it:gamma_t}{break}
{it:y_t} = {it:b2'x_t} + {it:e_t}{space 4}if {it:q_t} > {it:gamma_t}

{pstd}
where the threshold is a {bf:Fourier function of time},

{p 8 8 2}
{it:gamma_t} = {it:g0} + {it:g1} sin(2{it:pi k t/T}) + {it:g2}
cos(2{it:pi k t/T})

{pstd}
rather than a constant. The level {it:g0}, the two Fourier coefficients
{it:g1} and {it:g2}, the integer frequency {it:k}, and the regime
coefficients are all estimated jointly by profiled least squares.

{pstd}
Any absolutely integrable path of the threshold over time can be
approximated to arbitrary accuracy by a long enough Fourier series. The
point of using {bf:one} frequency, following Becker, Enders and Lee (2006),
is that a gradually evolving threshold is captured by very few parameters:
three numbers and an integer replace a whole unknown function. The cost is
that the approximation is good for {bf:gradual} change and poor for abrupt
change {hline 2} see the next section, which is not a caveat to bury.

{pstd}
With {it:g1} = {it:g2} = 0 the model {bf:is} the constant-threshold
regression of Hansen (2000), and {cmd:tvtfourier} computes that case with
the same code. Whether the extra two parameters are warranted is exactly what
the {bf:F2} statistic below tests.


{marker scope}{...}
{title:What it is good at, and what it is not}

{pstd}
The paper is explicit, and its own simulations bear it out: this
specification "is designed to work best when the actual change is gradual,
because the Fourier approximation seems to be less effective when the actual
change is discrete".

{pstd}
From the paper's Table IV, the power of {bf:F2} to detect a non-constant
threshold at the 5% level, by the shape of the true change:

{p2colset 8 44 46 2}{...}
{p2col :true threshold change}{it:T}=100{space 5}{it:T}=200{space 5}{it:T}=500{p_end}
{p2col :smooth, Fourier-shaped}0.53{space 9}0.91{space 9}1.00{p_end}
{p2col :one abrupt shift}0.21{space 9}0.32{space 9}0.57{p_end}
{p2col :two abrupt shifts}0.26{space 9}0.41{space 9}0.76{p_end}
{p2colreset}{...}

{pstd}
So against a genuine step the test needs roughly {bf:five times the sample}
to reach the power it has against a smooth drift. If you have reason to
think the threshold moved {it:on a date} {hline 2} a policy change, a
reform, a regime switch {hline 2} this is not the specification to reach for
first, and a shift specification will both fit better and be easier to
interpret. Use this one when the mechanism is gradual: learning, diffusion,
slow institutional change, an evolving long-run equilibrium.

{pstd}
{bf:This is a time-series command.} The threshold moves with {it:t}, so the
observations must be ordered in time and equally spaced. A threshold that
varies with a {it:covariate} rather than with time is a different model
entirely.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} gives the threshold variable {it:q}. Required.
Unlike {helpb tvthomog}, this estimator is {bf:not} invariant to a monotone
transformation of {it:q}: the Fourier threshold is additive in {it:q}'s own
units. It {bf:is} exactly equivariant to shifting and scaling {hline 2}
replacing {it:q} by {it:a} + {it:cq} shifts {it:g0} by {it:a} and scales all
three of {it:g0}, {it:g1}, {it:g2} by {it:c}, leaving {it:k}, the
coefficients and the SSR untouched.

{phang}
{opt kmax(#)} is the largest integer frequency searched; the search runs over
1, 2, ..., {it:kmax}. The default 5 is the paper's, following Becker, Enders
and Lee (2006). Higher frequencies mean a threshold that oscillates faster;
the paper warns that large {it:k} invites over-fitting and that higher
frequencies tend to pick up stochastic parameter variation rather than a
genuine gradual path.

{phang}
{opt trim(#)} keeps both regimes populated: a candidate path is admissible
only if at least this fraction of the sample falls on each side of it. Note
this is applied to the {bf:pooled} counts over the whole sample, not at each
{it:t} separately {hline 2} see {help tvtfourier##choices:Choices the paper
leaves open}.

{phang}
{opt ngrid(#)} and {opt amplitude(#)} set the grid over {it:g1} and {it:g2}:
{cmd:ngrid()} points per side, spanning plus and minus {cmd:amplitude()}
robust standard deviations of {it:q}. The defaults cover the paper's own
simulation designs comfortably. Raise {cmd:amplitude()} if the fitted
{it:g1} or {it:g2} lands on the edge of the grid, which is the symptom of a
box too small.

{phang}
{opt refine(#)} is the number of coarse-to-fine passes after the initial
sweep. Each pass re-searches a grid of the same size spanning one coarse
spacing either side of the current winner, so the resolution improves by a
factor of about ({cmd:ngrid}-1)/2 per pass at the cost of one more sweep.
{bf:This matters more than it looks.} With the default {cmd:ngrid(15)} the
coarse spacing on a standard normal {it:q} is about 0.30, while the paper's
Table I reports standard deviations for {it:g1} and {it:g2} of 0.13 to 0.22:
without refinement the grid would be coarser than the sampling variability
and the estimates would be quantised to grid points. {cmd:refine(0)} turns
it off and is useful only for checking that behaviour.

{phang}
{opt reps(#)} is the number of wild bootstrap replications. {bf:The default
is 0, which means no p-values at all} {hline 2} the two test statistics are
reported but cannot be interpreted, because their null distributions are
non-standard. Set it to get p-values, and read
{help tvtfourier##cost:How long it takes} first.

{phang}
{opt blevel(#)} is the level for the bootstrap confidence intervals, and
{opt noci} skips them. They are computed only when {cmd:reps()} is positive.

{phang}
{opt level(#)} sets the level for the coefficient table only.


{marker cost}{...}
{title:How long it takes}

{pstd}
Worth reading before setting {cmd:reps()}, because this command is not
cheap and the reason is structural.

{pstd}
A single fit searches {cmd:kmax} frequencies times {cmd:ngrid}^2 pairs of
Fourier coefficients, times one pass per {cmd:refine()}. Every bootstrap
replication {bf:repeats that entire search}, including re-selecting the
frequency {hline 2} and that is not an implementation choice that could be
economised away. Holding the selected frequency fixed across replications
would ignore the selection advantage the observed statistic enjoyed and the
test would over-reject.

{pstd}
Measured on this machine, 200 observations, two regressors, defaults
throughout:

{p2colset 8 46 48 2}{...}
{p2col :one fit, {cmd:reps(0)}}about 7 seconds{p_end}
{p2col :one bootstrap replication}about 0.8 seconds{p_end}
{p2col :{cmd:reps(199)}, both tests}about 5 minutes{p_end}
{p2col :{cmd:reps(199)} with intervals}about 8 minutes{p_end}
{p2colreset}{...}

{pstd}
Cost scales roughly with {cmd:reps()} times {cmd:kmax} times
{cmd:ngrid}^2 times (1 + {cmd:refine()}). If that is too slow, reduce
{cmd:ngrid()} and {cmd:refine()} rather than {cmd:reps()}: a bootstrap with
too few replications gives a p-value with a granularity you cannot see,
whereas a coarser grid degrades the fit visibly and reports a {it:g1} and
{it:g2} you can check against the grid spacing.


{marker method}{...}
{title:How it works}

{pstd}
Profiled least squares, the paper's equations (4) to (10). For any candidate
path the model is linear, so the coefficients are least squares and the
criterion is the resulting sum of squared residuals; the search is over the
path.

{pstd}
Two exact reformulations make the search affordable, and neither costs any
accuracy.

{phang}
{bf:1. The level is not a grid parameter.} Since

{p 12 12 2}
1{c -(}{it:q_t} {ul:<} {it:g0} + {it:g1 s_t} + {it:g2 c_t}{c )-} =
1{c -(}{it:q_t} - {it:g1 s_t} - {it:g2 c_t} {ul:<} {it:g0}{c )-}

{pmore}
the problem for fixed ({it:g1}, {it:g2}) is an ordinary single-threshold
search in a derived variable, and {it:g0} is profiled {bf:exactly} by
walking that variable's distinct values. The grid is therefore
two-dimensional, not three, and {it:g0} carries no discretisation error at
all.

{phang}
{bf:2. The sweep costs a rank-one update, not a regression.} By
Frisch-Waugh the criterion depends on the candidate only through two running
cross-products; the matrices that do {it:not} involve the threshold are
computed once for the whole command and reused by every candidate, every
frequency and every bootstrap replication.

{pstd}
The only remaining discretisation is the grid over {it:g1} and {it:g2},
which {opt refine()} sharpens.


{marker tests}{...}
{title:The two tests}

{pstd}
Both are reported automatically; both need {cmd:reps()} to be interpretable.

{phang}
{bf:F1: is there a threshold effect at all?} The null is {it:b1} = {it:b2},
under which the model is a linear regression. {bf:Run this first}: if there
is no threshold, nothing else here means anything, because the estimated
threshold path is then fitting noise.

{phang}
{bf:F2: is the threshold constant?} The null is {it:g1} = {it:g2} = 0, under
which the model is Hansen's (2000) constant-threshold regression. This is
the test that justifies using this command rather than an ordinary threshold
regression.

{pstd}
{bf:Why neither can be read off an F table.} Under each null a parameter
disappears from the model {hline 2} the whole threshold path under the first,
the frequency under the second {hline 2} so it is not identified and the
usual asymptotics fail. This is Davies' problem. The null distributions are
non-standard and the command obtains p-values by a {bf:two-point wild
bootstrap} with Mammen's golden-ratio weights, each test generating data
under its {bf:own} null: F1 under the linear model, F2 under the
constant-threshold model. The wild bootstrap is used rather than a residual
bootstrap because it remains consistent under heteroskedasticity and under
misspecification.

{pstd}
Note on the statistic's scale: both divide by SSR/({it:T}-{it:m}) with
{it:m} the number of regressors, i.e. the {bf:null} model's degrees of
freedom, which is how the paper defines them. Since the p-value comes from a
bootstrap recomputing the same statistic, the convention cancels and only
the printed number depends on it.

{pstd}
{helpb tvthomog} answers a related but distinct question: it tests
constancy of the threshold {bf:without} committing to how it varies, and it
needs no bootstrap. Rejecting with {cmd:tvthomog} and then fitting
{cmd:tvtfourier} is a reasonable sequence; so is going straight to
{bf:F2} here if a Fourier path is the specific alternative of interest.
{helpb tvthresh_choose} discusses the choice.


{marker inference}{...}
{title:Inference}

{pstd}
{bf:The coefficient table} reports standard errors from the least-squares
fit {bf:conditional on the estimated threshold path}. Hansen's (2000)
argument carries over: the threshold is estimated fast enough that the slope
coefficients have their usual asymptotics given it. These standard errors
therefore do {bf:not} reflect uncertainty about the path itself.

{pstd}
{bf:The bootstrap intervals} do. Following the paper's own procedure, data
are regenerated under the {it:fitted} model, the whole thing is re-estimated,
and intervals are formed by the {bf:symmetric percentile} method {hline 2}
the estimate plus and minus the quantile of the absolute centred bootstrap
deviations. These are the intervals the paper reports, and the ones to quote
for {it:g0}, {it:g1} and {it:g2}. Being symmetric by construction they can
extend into regions the bootstrap distribution never visited; that is the
price of the method.

{pstd}
{bf:No interval is reported for the frequency} {it:k}, and this is
deliberate. The paper proves the estimator of {it:k} is consistent but
shows its convergence rate and limiting distribution {bf:cannot be
obtained}. A standard error for a selected frequency would be an invention.
Report {it:k} as a selected value, and if the conclusion depends on it, say
so and show the fit at neighbouring frequencies.


{marker choices}{...}
{title:Choices the paper leaves open}

{pstd}
The paper specifies the estimator completely but says of the search only
that the parameter space is "a bounded set" and that it uses "a combination
of concentration and grid search, as is typical in the literature". It never
states the bounds or the resolution, and they matter. The choices made here
are therefore stated rather than buried, and all are options:

{phang}
{bf:The level} {it:g0} {bf:is not gridded}, being profiled exactly. This
removes the most consequential of the three resolution choices entirely.

{phang}
{bf:The box for} {it:g1} {bf:and} {it:g2} is symmetric, with half-width
{cmd:amplitude()} robust standard deviations of {it:q} {hline 2} robust
rather than the plain standard deviation, so that a long-tailed {it:q} does
not inflate the box and spend the grid on amplitudes that empty a regime.

{phang}
{bf:Trimming is on the pooled regime counts}, not pointwise at each {it:t}.
Pointwise trimming would be wrong here. Under the paper's own simulation
parameters the fitted threshold sweeps from roughly the 18th to the 97th
percentile of {it:q}, so near the peak of the sinusoid the upper regime
legitimately contains about 3% of the sample. What has to be estimable is
the pooled fit, and that is what the pooled counts govern.

{pstd}
If the fitted {it:g1} or {it:g2} sits at the edge of the box, the box is too
small: raise {cmd:amplitude()}.


{marker examples}{...}
{title:Examples}

{pstd}Setup: the paper's own simulation design, a threshold tracing one
Fourier cycle.{p_end}
{phang2}{cmd:. set seed 71010}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. generate int t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. generate double x = rnormal()*2}{p_end}
{phang2}{cmd:. generate double q = rnormal()}{p_end}
{phang2}{cmd:. generate double g = 0.5 + sin(2*_pi*t/200) + cos(2*_pi*t/200)}{p_end}
{phang2}{cmd:. generate double y = cond(q<=g, 10 + 10*x, 10 + 20*x) + rnormal()}{p_end}

{pstd}Fit it. Fast, but with no p-values.{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}

{pstd}With p-values and intervals. {bf:This takes minutes}, not
seconds.{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q) reps(199)}{p_end}

{pstd}Quicker, by coarsening the search rather than the bootstrap.{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q) reps(199) ngrid(9) refine(1)}{p_end}

{pstd}Restrict to a slowly moving threshold.{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q) kmax(2)}{p_end}

{pstd}Plot the fitted threshold against the threshold variable.{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}
{phang2}{cmd:. tvtplot}{p_end}

{pstd}Check whether the constant-threshold model would have done
{hline 2} compare the two SSRs, then read {bf:F2}.{p_end}
{phang2}{cmd:. display e(ssr_const), e(ssr)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtfourier} is {bf:e-class}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_lower)}}observations in the lower regime{p_end}
{synopt:{cmd:e(N_upper)}}observations in the upper regime{p_end}
{synopt:{cmd:e(gamma0)}}{it:g0}, the level of the threshold{p_end}
{synopt:{cmd:e(gamma1)}}{it:g1}, the sine coefficient{p_end}
{synopt:{cmd:e(gamma2)}}{it:g2}, the cosine coefficient{p_end}
{synopt:{cmd:e(k)}}the selected frequency{p_end}
{synopt:{cmd:e(gamma_c)}}the threshold of the {it:constant}-threshold fit,
for comparison{p_end}
{synopt:{cmd:e(ssr)}}SSR of the Fourier-threshold model{p_end}
{synopt:{cmd:e(ssr_const)}}SSR of the constant-threshold model{p_end}
{synopt:{cmd:e(ssr_lin)}}SSR of the linear model{p_end}
{synopt:{cmd:e(F1)}}statistic for no threshold effect{p_end}
{synopt:{cmd:e(F2)}}statistic for a constant threshold{p_end}
{synopt:{cmd:e(p1)}}bootstrap p-value for {cmd:e(F1)}{p_end}
{synopt:{cmd:e(p2)}}bootstrap p-value for {cmd:e(F2)}{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(amp)}}half-width of the grid actually used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtfourier}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(threshvar)}}name of the threshold variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficients: the {bf:upper} regime first, then the
{bf:differential}{p_end}
{synopt:{cmd:e(V)}}covariance, conditional on the fitted path{p_end}
{synopt:{cmd:e(path)}}the fitted threshold {it:gamma_t}, one row per
observation{p_end}
{synopt:{cmd:e(ci)}}bootstrap intervals for the coefficients then
{it:g0}, {it:g1}, {it:g2}{p_end}
{synopt:{cmd:e(ssrk)}}minimised SSR at each frequency{p_end}

{pstd}
{bf:On the ordering of} {cmd:e(b)}. It follows the paper's equation (4):
the first block is the {bf:upper} regime's coefficient vector, and the
second is the {bf:difference} (lower minus upper), not the lower regime's
own coefficients. The lower regime's coefficient on a regressor is therefore
the sum of its two entries, and the equation names {cmd:upper:} and
{cmd:diff:} say which is which. A test of no threshold effect on a single
regressor is a test that its {cmd:diff:} coefficient is zero {hline 2} but
see the caution under {help tvtfourier##tests:The two tests} about reading
such a test when the threshold itself is estimated.


{marker validation}{...}
{title:Validation}

{pstd}
The estimator is checked against the paper's Table I, which reports means
and standard deviations of every estimated parameter across its own
simulation design at several sample sizes and frequencies. The two
reformulations in {help tvtfourier##method:How it works} are verified to be
exact rather than assumed: the Frisch-Waugh sweep is checked against a
direct least-squares fit, and the two-dimensional search with the level
profiled is checked against a brute-force three-dimensional grid, which must
return the identical optimum. The constant-threshold reduction is checked
against {helpb regress} with a split dummy. The wild bootstrap weights are
checked to have mean zero and variance one.

{pstd}
No reference code was published with the paper, so this is a clean-room
implementation from the published equations. See
{bf:validation/tvthresh/tvtfourier_equation_map.md} in the distribution for
the equation-by-equation concordance, the full reference lock, the record of
which choices the paper leaves open, and a typo in the paper's own equation
(22) resolved from its Figure 1.


{marker references}{...}
{title:References}

{phang}
Yang, L., C. Lee, and I.-P. Chen. 2021. Threshold model with a time-varying
threshold based on Fourier approximation. {it:Journal of Time Series
Analysis} 42(4): 406-430.
{browse "https://doi.org/10.1111/jtsa.12574":doi:10.1111/jtsa.12574}

{phang}
Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the presence
of an unknown number of smooth breaks. {it:Journal of Time Series Analysis}
27(3): 381-409.
{browse "https://doi.org/10.1111/j.1467-9892.2006.00478.x":doi:10.1111/j.1467-9892.2006.00478.x}

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present
only under the alternative. {it:Biometrika} 74(1): 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68(3): 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}

{phang}
Kline, P., and A. Santos. 2012. A score based approach to wild bootstrap
inference. {it:Journal of Econometric Methods} 1(1): 23-41.
{browse "https://doi.org/10.1515/2156-6674.1006":doi:10.1515/2156-6674.1006}

{phang}
Mammen, E. 1993. Bootstrap and wild bootstrap for high dimensional linear
models. {it:Annals of Statistics} 21(1): 255-285.
{browse "https://doi.org/10.1214/aos/1176349025":doi:10.1214/aos/1176349025}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Manual:  {manlink R regress}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb tvthomog},
{helpb tvtplot}, {helpb tvtsim}, {helpb regress}
{p_end}
