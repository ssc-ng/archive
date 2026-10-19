{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtcoint##syntax"}{...}
{viewerjumpto "Description" "tvtcoint##description"}{...}
{viewerjumpto "What makes this different" "tvtcoint##different"}{...}
{viewerjumpto "Options" "tvtcoint##options"}{...}
{viewerjumpto "The two tests" "tvtcoint##tests"}{...}
{viewerjumpto "Ties, and why they matter" "tvtcoint##ties"}{...}
{viewerjumpto "The grids" "tvtcoint##grids"}{...}
{viewerjumpto "Inference, and what is NOT reported" "tvtcoint##inference"}{...}
{viewerjumpto "Where this implementation and the shipped code differ" "tvtcoint##divergence"}{...}
{viewerjumpto "Examples" "tvtcoint##examples"}{...}
{viewerjumpto "Stored results" "tvtcoint##results"}{...}
{viewerjumpto "Validation" "tvtcoint##validation"}{...}
{viewerjumpto "References" "tvtcoint##references"}{...}
{viewerjumpto "Author" "tvtcoint##author"}{...}
{title:Title}

{phang}
{bf:tvtcoint} {hline 2} Threshold cointegration with a covariate-driven
threshold


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtcoint} {depvar} {it:indepvars} {ifin}{cmd:,}
{opth thr:eshvar(varname)} {opth z:vars(varlist)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opth thr:eshvar(varname)}}the threshold variable {it:q_t}; it is
compared against the moving threshold{p_end}
{synopt :{opth z:vars(varlist)}}the variables the threshold is a linear
function of; one or two{p_end}

{syntab:Search}
{synopt :{opt trim(#)}}smallest share each regime may hold; default
{cmd:trim(0.10)}, which is the authors' own rule{p_end}
{synopt :{opt gstep(#)}}step of the gamma_1 grid; default
{cmd:gstep(0.1)}{p_end}
{synopt :{opt grid0(numlist)}}the gamma_0 grid; default, the distinct
values of {it:q}{p_end}
{synopt :{opt grid1(numlist)}}the gamma_1 grid; default, built from the
range of {it:q} (see {help tvtcoint##grids:The grids}){p_end}
{synopt :{opt ties(nested|flat)}}how tied minimisers are resolved; default
{cmd:ties(nested)}{p_end}
{synopt :{opt maxp:oints(#)}}refuse a grid larger than this; default
20,000,000{p_end}

{syntab:Inference and reporting}
{synopt :{opt reps(#)}}bootstrap replications; default {cmd:reps(0)},
which gives {bf:no p-values}{p_end}
{synopt :{opt gauss:ian}}use the shipped code's parametric Gaussian
bootstrap instead of the paper's multiplier bootstrap{p_end}
{synopt :{opt nocons:tant}}suppress the constant in both regimes{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}
{cmd:tvtcoint} is for a single equation on time-series data. It does not
require {helpb tsset} but will use it if present.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtcoint} fits the threshold cointegrating regression

{p 8 8 2}
{it:y_t} = {it:b1'x_t} + {it:e_t}{col 42}if {it:q_t} <= {it:gamma_t}{break}
{it:y_t} = {it:b2'x_t} + {it:e_t}{col 42}if {it:q_t} >  {it:gamma_t}

{pstd}
in which the threshold itself moves with observed covariates,

{p 8 8 2}
{it:gamma_t} = {it:gamma_0} + {it:gamma_1'z_t}.

{pstd}
{it:x_t} is a vector of I(1) variables, so each regime is a genuine
long-run (cointegrating) relation with its own coefficients; {it:q_t} and
{it:z_t} are stationary and observed. This is the model of
{browse "https://doi.org/10.1515/snde-2018-0101":Yang (2022)}, which
extends Gonzalo and Pitarakis (2006) and Chen (2015) from a constant
threshold to one driven by covariates.

{pstd}
The threshold parameters are estimated by concentrated least squares over
a grid, eq (7): for each candidate ({it:gamma_0}, {it:gamma_1}) the sample
is split, both regimes are fitted by OLS, and the pair minimising the
total sum of squared residuals is kept.


{marker different}{...}
{title:What makes this different from the rest of the library}

{pstd}
Two things at once, and both matter when choosing a command.

{pstd}
{bf:The regression is cointegrating.} {it:x_t} is I(1). There is no
separate cointegration stage and no error-correction term: eq (1) {it:is}
the long-run relation, estimated piecewise. If your regressors are
stationary this is the wrong command -- use
{helpb tvtfourier} or {helpb tvtcotar} instead.

{pstd}
{bf:The threshold is a function of OTHER OBSERVED VARIABLES.} That is a
third way for a threshold to move, and the library keeps the three apart:

{p2colset 8 34 36 2}{...}
{p2col :{helpb tvtfourier}}the threshold is a function of {bf:time}{p_end}
{p2col :{helpb tvtcotar}, {helpb tvtcotrk}}the threshold is a function of
the threshold variable's {bf:own recent past}{p_end}
{p2col :{bf:tvtcoint}}the threshold is a function of {bf:other observed
variables}{p_end}
{p2colreset}{...}

{pstd}
In the paper's application the threshold on industrial-production growth
moves with the change in inflation: what counts as "high economic
activity" is itself conditional on where inflation is going.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} gives the threshold variable {it:q_t}. It must
not also appear in {it:indepvars}: Assumption 1 makes {it:q_t} stationary
and Assumption 5 makes {it:x_t} I(1), so a variable cannot be both. The
command refuses it.

{phang}
{opth zvars(varlist)} gives the variables driving the threshold. One or
two. The gamma_1 grid is a cartesian product over them, so three would be
a grid of 64,000 slope combinations at every gamma_0; the paper's
application uses one and its simulations use two, and the command refuses
more.

{phang}
{opt trim(#)} is the smallest share of the sample either regime may hold.
{bf:The paper states no trimming at all}, but the authors' code imposes
10% and that is the default here. It is not cosmetic: on the paper's own
Fisher data, dropping it finds a 15-observation lower regime with a sum of
squares of 1041.58, {bf:below} the published 1059.79. A better fit on 15
points is not an estimate of anything.

{phang}
{opt gstep(#)}, {opt grid0(numlist)} and {opt grid1(numlist)} control the
search; see {help tvtcoint##grids:The grids}.

{phang}
{opt ties(nested|flat)} chooses how tied minimisers are resolved; see
{help tvtcoint##ties:Ties}.

{phang}
{opt reps(#)} asks for bootstrap p-values. Without it the two statistics
are printed but have {bf:no p-values at all}, because their null
distributions are non-standard. Each replication re-runs the whole
two-dimensional search twice, so time is roughly {it:reps} x 4 x the time
of one estimation.

{phang}
{opt gaussian} runs the bootstrap the shipped GAUSS runs rather than the
one the paper describes; see
{help tvtcoint##divergence:Where this implementation and the shipped code
differ}. It is there so the difference can be measured, not because it is
recommended.

{phang}
{opt noconstant} drops the constant from both regimes. Rarely sensible in
a cointegrating regression.


{marker tests}{...}
{title:The two tests}

{pstd}
They answer different questions and are not substitutes.

{p2colset 8 16 18 2}{...}
{p2col :{bf:F1}}{it:H0}: {it:b1} = {it:b2}. Is there a threshold effect at
all? The null model is the single cointegrating regression, eq (8).{p_end}
{p2col :{bf:F2}}{it:H0}: {it:gamma_1} = 0. Given a threshold, is it
{bf:constant}? The null model is the constant-threshold cointegration
model of Gonzalo and Pitarakis (2006) and Chen (2015).{p_end}
{p2colreset}{...}

{pstd}
Both are sup-statistics, eqs (9)-(10), over the same grid. Under {it:H0}
for F1 the threshold is not identified at all, which is Davies' problem,
so neither has a standard distribution and both need
{opt reps()}.

{pstd}
{bf:Read them in order.} F2 presumes there is a threshold. A large F2 with
a small F1 is not evidence of a moving threshold; it is evidence that the
grid found something in noise.

{pstd}
{bf:F2 can come out negative, and that is not a bug.} The constant
threshold is only nested inside the moving one if the gamma_1 grid
contains zero, and the default grid -- which starts at {it:-max(q)} and
steps by {opt gstep()} -- generally does not. When the threshold really is
constant, the moving model is then fitting a slightly worse approximation
to it than the constant model achieves exactly, and F2 goes below zero. A
negative F2 is strong evidence {bf:for} the null of constancy. (Measured
on a constant-threshold design: F2 = -5.75 against +2730 when the
threshold genuinely moves.) Put 0 in the grid with {opt grid1()} if you
want exact nesting.

{pstd}
{bf:The bootstrap re-runs the search on every replication}, which is what
makes it slow and what makes it right: the observed statistic is a
supremum over the grid and so enjoys a selection advantage. Holding
({it:gamma_0}, {it:gamma_1}) fixed at the observed minimiser would ignore
that and over-reject.


{marker ties}{...}
{title:Ties, and why they matter}

{pstd}
Many ({it:gamma_0}, {it:gamma_1}) pairs produce the {bf:identical} sample
split and therefore the identical sum of squares: the criterion is a step
function of the parameters and the grid is far finer than the number of
distinct splits. A naive argmin returns whichever tied point the loop
reached first, which depends on the grid's {bf:order} and not on the data.

{pstd}
The paper's footnote 2, citing Yu and Fan (2020), says to average over the
minimisers, and {cmd:tvtcoint} does. {cmd:e(n_ties)} reports how many
there were.

{pstd}
The two readings differ in one detail:

{phang2}
{cmd:ties(nested)}, the default, follows the authors' code: for each
{it:gamma_0} take the best {it:gamma_1} (the first, if several tie), then
average over the tied {it:gamma_0} and their stored {it:gamma_1}. This is
the reading that reproduces the published estimates.

{phang2}
{cmd:ties(flat)} averages over every tied ({it:gamma_0}, {it:gamma_1})
pair, which is the literal reading of footnote 2. The two coincide unless
some {it:gamma_0} has several equally good {it:gamma_1}.

{pstd}
The constant-threshold model is never tie-averaged: there the authors use
Hansen's routine unchanged, which takes the first minimiser, and so does
{cmd:tvtcoint}.


{marker grids}{...}
{title:The grids}

{pstd}
The paper describes the parameter spaces only as "strict subsets of the
support of {it:q_t}", which is not a usable specification -- and for
{it:Gamma_1}, which is a space of {bf:slopes}, not a meaningful one
either. The authors' own two programs then disagree with each other:

{p2colset 8 26 28 2}{...}
{p2col :{bf:empirical code}}gamma_0 over the distinct values of {it:q};
gamma_1 over {it:-max(q)} upward in steps of 0.1{p_end}
{p2col :{bf:simulation code}}gamma_0 over 0(0.05)1.95 and gamma_1 over
-1(0.1)2.9, both hard-coded and independent of the data{p_end}
{p2colreset}{...}

{pstd}
{cmd:tvtcoint} follows the {bf:empirical} version, which is the one that
generalises, and that default reproduces the published estimates. Note
{it:max(q)}, not {it:max|q|}: on the Fisher data those differ by a factor
of two and only {it:max(q)} gives the published gamma_1.

{pstd}
{bf:Check e(gamma1) against the grid's endpoints.} In the paper's own
application the estimate 1.9475 is exactly the {bf:top} of the authors'
data-driven gamma_1 grid. A boundary estimate means the grid may be too
narrow; widen it with {opt grid1()} and see whether the estimate moves.

{pstd}
Use {opt grid0()} and {opt grid1()} to reproduce the simulation code, or
any other grid you want to defend.


{marker inference}{...}
{title:Inference, and what is NOT reported}

{pstd}
{bf:No interval is reported for the threshold.} Theorem 1 does give the
limiting distribution of ({it:gamma_0}, {it:gamma_1}) -- the same form as
Hansen (2000) and Chen (2015) -- but its scale factors depend on the joint
density of ({it:q_t}, {it:z_t}), and the paper proposes no estimator for
them and reports no interval. Shipping one would mean inventing the
nuisance-parameter estimation, which is a research task, not an
implementation detail.

{pstd}
{bf:The standard errors on the slopes are conditional on the estimated
threshold path, and they are not the paper's.} The paper derives no
distribution for {it:beta} at all; its argument is that the threshold
estimator's consistency means observations are correctly classified, so
the regime coefficients can be consistently estimated. That justifies the
point estimates, not the standard errors. The ones printed are ordinary
OLS given {cmd:e(path)}, and they are valid only if the regressors
are strictly exogenous. With endogenous I(1) regressors the second-order
bias of OLS in a cointegrating regression makes the usual t-statistics
non-standard; see Chen (2015) for the constant-threshold case.

{pstd}
{bf:Treat them as descriptive dispersion, not as a test.} Use the
bootstrap for the questions the paper does answer: F1 and F2.

{pstd}
{bf:Cointegration itself is assumed, not tested.} Assumption 1 makes
{it:e_t} stationary; that is what separates this from a spurious
regression. The command reports the residuals' first-order autocorrelation
as a flag only, and warns when it is close to the value a genuine unit
root would produce at that sample size (about 1 - 5/T, which is where the
downward bias of the OLS estimate puts it). Test the residuals yourself
before reading anything else in the output.


{marker divergence}{...}
{title:Where this implementation and the shipped code differ}

{pstd}
The authors' GAUSS was read and run to produce the reference numbers. On
one point it disagrees with the paper it accompanies, and the {bf:paper}
is what is implemented here:

{phang2}
{bf:The bootstrap.} The paper's Step 1 (p. 5) is Hansen's (1996)
multiplier bootstrap: draw {it:u_t} ~ N(0,1) and form {it:u*_t} =
{it:e_t}{it:u_t} from the null model's residuals. The shipped code instead
draws from a single fitted normal -- a homoskedastic parametric bootstrap
-- and, in that code, the quantity passed as the standard deviation is the
residual {bf:variance}. {cmd:tvtcoint} implements the paper's version by
default; {opt gaussian} gives the code's, without the variance/standard
deviation slip, for comparison.

{pstd}
Everything else -- the nested search, the 10% trimming, the tie averaging,
the data-driven grids, the use of Hansen's unchanged routine for the
constant-threshold model -- follows the code, because the code is what
produced the published numbers.


{marker examples}{...}
{title:Examples}

{pstd}The Fisher application: the threshold on industrial-production
growth moves with the change in inflation{p_end}
{phang2}{cmd:. tvtcoint ir infl, threshvar(ipigrowth) zvars(d_infl)}{p_end}

{pstd}With bootstrap p-values for both tests{p_end}
{phang2}{cmd:. tvtcoint ir infl, threshvar(ipigrowth) zvars(d_infl) reps(500)}{p_end}

{pstd}Is the estimate on the edge of the grid? Widen it and look{p_end}
{phang2}{cmd:. tvtcoint ir infl, threshvar(ipigrowth) zvars(d_infl) grid1(-5(0.1)5)}{p_end}

{pstd}Plot the fitted threshold path against the threshold variable{p_end}
{phang2}{cmd:. tvtcoint ir infl, threshvar(ipigrowth) zvars(d_infl)}{p_end}
{phang2}{cmd:. tvtplot, path}{p_end}

{pstd}Reproduce the paper's simulation grids rather than the data-driven
ones{p_end}
{phang2}{cmd:. tvtcoint y x, threshvar(q) zvars(z1 z2) grid0(0(0.05)1.95) grid1(-1(0.1)2.9)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tvtcoint} is {cmd:e}-class. It stores

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(gamma0)}}the intercept of the threshold function{p_end}
{synopt:{cmd:e(gamma_const)}}the constant threshold, for comparison{p_end}
{synopt:{cmd:e(N_lower)}, {cmd:e(N_upper)}}regime sizes{p_end}
{synopt:{cmd:e(ssr)}}sum of squared residuals at the estimate{p_end}
{synopt:{cmd:e(ssr_grid)}}the grid minimum, which should equal
{cmd:e(ssr)}{p_end}
{synopt:{cmd:e(ssr_lin)}}sum of squares of the linear model, eq (8){p_end}
{synopt:{cmd:e(ssr_const)}}sum of squares of the constant-threshold
model{p_end}
{synopt:{cmd:e(F1)}, {cmd:e(F2)}}the two statistics{p_end}
{synopt:{cmd:e(p_F1)}, {cmd:e(p_F2)}}bootstrap p-values, if
{opt reps()}{p_end}
{synopt:{cmd:e(n_boot)}}usable replications{p_end}
{synopt:{cmd:e(n_ties)}}how many minimisers were averaged{p_end}
{synopt:{cmd:e(n_cand)}, {cmd:e(n_feasible)}}grid points, and how many
passed the trimming rule{p_end}
{synopt:{cmd:e(n_grid0)}, {cmd:e(n_grid1)}}the two grids' sizes{p_end}
{synopt:{cmd:e(minreg)}}smallest admissible regime size{p_end}
{synopt:{cmd:e(rho_e)}}first-order autocorrelation of the residuals{p_end}
{synopt:{cmd:e(trim)}, {cmd:e(gstep)}, {cmd:e(reps)}}as specified{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtcoint}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}the I(1) regressors{p_end}
{synopt:{cmd:e(threshvar)}}the threshold variable{p_end}
{synopt:{cmd:e(zvars)}}the variables driving the threshold{p_end}
{synopt:{cmd:e(ties)}}the tie rule used{p_end}
{synopt:{cmd:e(boottype)}}which bootstrap was run{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients in two equations,
{cmd:lower} and {cmd:upper}{p_end}
{synopt:{cmd:e(gamma1)}}the threshold function's slopes{p_end}
{synopt:{cmd:e(path)}}the fitted threshold, observation by
observation{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
{cmd:tvtcoint} is a clean-room implementation from the published
equations. The authors' GAUSS carries no licence and is therefore
all-rights-reserved; it was read to understand its behaviour and run to
produce reference numbers, and no line of it is reproduced.

{pstd}
It is locked twice.

{phang2}
{bf:Against the authors' own executed code.} Running their
{cmd:CO_THR_EST.PRC} on their own {cmd:usdata.txt} gives
{it:gamma_t} = -0.33552 + 1.94754 {it:z_t} and a constant threshold of
-0.23139, reproducing the published -0.336 + 1.948 and -0.231.
{cmd:tvtcoint} matches those, the global OLS fit, both regimes'
coefficients and all three sums of squares to the figures in the lock.

{phang2}
{bf:Against the paper's own Monte Carlo.} Table 1 Panel A's means and
standard deviations for ({it:gamma_0}, {it:gamma_1}, {it:gamma_2},
{it:beta_1}, {it:beta_2}), including the convergence rate implied by
Theorem 1: the threshold estimates' dispersion halves from T = 100 to
T = 200.

{pstd}
Both suites are in {cmd:tests/reference/tvtcoint/} and the
equation-by-equation map is in
{cmd:validation/tvthresh/tvtcoint_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Chen, H. 2015. Robust estimation and inference for threshold models with
integrated regressors. {it:Econometric Theory} 31(4): 778-810.

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is
present only under the alternative. {it:Biometrika} 74: 33-43.

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2006. Threshold effects in cointegrating
relationships. {it:Oxford Bulletin of Economics and Statistics} 68:
813-833.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.

{phang}
Yang, L. 2022. Time-varying threshold cointegration with an application to
the Fisher hypothesis. {it:Studies in Nonlinear Dynamics & Econometrics}
26(2): 257-274.
{browse "https://doi.org/10.1515/snde-2018-0101":doi:10.1515/snde-2018-0101}

{phang}
Yu, P., and X. Fan. 2020. Threshold regression with a threshold boundary.
{it:Journal of Business & Economic Statistics} 39(4): 953-971.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
