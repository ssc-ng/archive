{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtcoint" "help tvtcoint"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtboundary##syntax"}{...}
{viewerjumpto "Description" "tvtboundary##description"}{...}
{viewerjumpto "When to use this and not tvtcoint" "tvtboundary##versus"}{...}
{viewerjumpto "Options" "tvtboundary##options"}{...}
{viewerjumpto "The search" "tvtboundary##search"}{...}
{viewerjumpto "The score test" "tvtboundary##score"}{...}
{viewerjumpto "Intervals: what is valid and what is not" "tvtboundary##intervals"}{...}
{viewerjumpto "Examples" "tvtboundary##examples"}{...}
{viewerjumpto "Stored results" "tvtboundary##results"}{...}
{viewerjumpto "Validation" "tvtboundary##validation"}{...}
{viewerjumpto "References" "tvtboundary##references"}{...}
{viewerjumpto "Author" "tvtboundary##author"}{...}
{title:Title}

{phang}
{bf:tvtboundary} {hline 2} Threshold regression with a threshold boundary


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtboundary} {depvar} {it:indepvars} {ifin}{cmd:,}
{opth thr:eshvar(varname)} [{opth z:vars(varlist)} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:The threshold}
{synopt :{opth thr:eshvar(varname)}}required: the threshold variable
{it:q_i}{p_end}
{synopt :{opth z:vars(varlist)}}the variables the threshold is a linear
function of; one or two. {bf:Omit it and the threshold is an ordinary
constant.}{p_end}

{syntab:The search}
{synopt :{opt trim(#)}}smallest share each regime may hold; default
{cmd:trim(0.05)}, the authors' own rule{p_end}
{synopt :{opt gridn(#)}}points per gamma_2 direction; default
{cmd:gridn(41)}{p_end}
{synopt :{opt ref:ine(#)}}refinement rounds around the identified set;
default {cmd:refine(2)}{p_end}
{synopt :{opt g2r:ange(# #)}}bounds for every gamma_2 direction; the
default is read from the data{p_end}

{syntab:Inference}
{synopt :{opt sim:reps(#)}}multiplier draws for the score test's p-value;
default {cmd:simreps(200)}{p_end}
{synopt :{opt npi(#)}}posterior draws for the threshold's interval;
default {cmd:npi(0)}, which gives {bf:no interval}{p_end}
{synopt :{opt burn:in(#)}}burn-in draws; default {cmd:burnin(500)}{p_end}
{synopt :{opt mesh(#)}}mesh for the bandwidth; a power of two, default
{cmd:mesh(16384)}{p_end}

{syntab:Reporting}
{synopt :{opt nocons:tant}}suppress the constant in both regimes{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}
Standard errors are always heteroskedasticity-robust, which is what the
source code uses.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtboundary} fits

{p 8 8 2}
{it:y_i} = {it:b1'x_i} + {it:e_i}{col 44}if {it:q_i} <=
{it:gamma'z_i}{break}
{it:y_i} = {it:b2'x_i} + {it:e_i}{col 44}if {it:q_i} >  {it:gamma'z_i}

{pstd}
where {it:z_i} = (1, {it:z_2i}, ...)', so the threshold is
{it:gamma_1} + {it:gamma_2'z_2i}: a {bf:boundary} in ({it:q}, {it:z}) space
rather than a point on the {it:q} line. This is
{browse "https://doi.org/10.1080/07350015.2020.1740712":Yu and Fan (2020)}.

{pstd}
The motivating example is the classical return to schooling. With {it:y}
the log wage and {it:q} the education level, an ordinary threshold model
says the return differs above and below one education level -- {bf:the same
level for everybody}. It is more natural to let that level differ by sex,
or by any other observed characteristic, which is exactly
{it:gamma_1} + {it:gamma_2}{bf:D}. Writing that as a conventional
multiple-threshold model is impossible when {bf:D} is continuous and
burdensome when it is discrete.

{pstd}
{bf:With {opt zvars()} omitted this is an ordinary constant-threshold
regression}, estimated by the same exact search, which is both a useful
command in its own right and the natural comparison.


{marker versus}{...}
{title:When to use this and not tvtcoint}

{pstd}
{helpb tvtcoint} has the {it:same} threshold function. That is not a
coincidence: its source paper cites this one for the averaging rule. Choose
between them on the {bf:regressors}, which is a question about your data,
not about the model you want:

{p2colset 8 26 28 2}{...}
{p2col :{bf:tvtboundary}}{it:x} is stationary, or the data are
cross-sectional{p_end}
{p2col :{helpb tvtcoint}}{it:x} is {bf:I(1)}, so the regression is a
piecewise cointegrating one{p_end}
{p2colreset}{...}

{pstd}
This is not a matter of taste. With I(1) regressors the limit theory is
different and the stationary asymptotics do not apply; with stationary
regressors the cointegration machinery has nothing to attach to. Fitting
the wrong one is not a conservative approximation.

{pstd}
In exchange, this command gives something {helpb tvtcoint} cannot: a
{bf:valid interval for the threshold}. See
{help tvtboundary##intervals:Intervals}.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} gives the threshold variable {it:q_i}. It cannot
also be a regressor.

{phang}
{opth zvars(varlist)} gives the variables the threshold moves with. One or
two; the gamma_2 grid is a cartesian product over them, so three would be a
grid of {cmd:gridn()}{c 94}3 points, and the paper's own applications use
one or two. {bf:Omit it for a constant threshold.}

{phang}
{opt trim(#)} is the smallest share of the sample either regime may hold.
The authors' code uses 5% each side, which is the default.

{phang}
{opt gridn(#)} and {opt refine(#)} control the search; see
{help tvtboundary##search:The search}. {opt gridn()} applies only to the
gamma_2 directions -- gamma_1 is never gridded.

{phang}
{opt g2range(# #)} fixes the bounds for every gamma_2 direction. The
default takes, for each {it:z}, the slope just large enough to move the
threshold across the whole range of {it:q} over the observed range of that
{it:z}, and no larger. Widen it if the estimate lands on the edge.

{phang}
{opt simreps(#)} sets the multiplier draws behind the score test's
p-value. {cmd:simreps(0)} reports the statistic with no p-value.

{phang}
{opt npi(#)} asks for the nonparametric posterior interval and is the only
way to get an interval for the threshold. At least 200 draws are required
and 2000 is a sensible floor; the chain is cheap. Without it no interval
is reported.

{phang}
{opt mesh(#)} is the mesh for the Botev, Grotowski and Kroese (2010)
bandwidth used by the posterior. {bf:It is not innocuous}: on the authors'
own residuals the bandwidth moves by 5% between 2{c 94}10 and 2{c 94}14.
The default matches the shipped code.


{marker search}{...}
{title:The search}

{pstd}
The paper's Algorithm M simulates a Markov chain over the parameter space,
keeps the best points, refines around them and repeats. {cmd:tvtboundary}
keeps the shape of that and replaces the chain, for two reasons.

{pstd}
{bf:gamma_1 is swept exactly, never gridded.} For a fixed gamma_2 the split
{it:q_i} <= gamma_1 + gamma_2'{it:z_i} is {it:w_i} <= gamma_1 with
{it:w_i} = {it:q_i} - gamma_2'{it:z_i}, so the criterion is a step function
of gamma_1 that changes only at the sorted {it:w}. Sweeping the midpoints
of consecutive distinct {it:w} therefore visits {bf:every} distinct split,
exactly, at the cost of one sort.

{pstd}
{bf:The result is reproducible.} Only the gamma_2 directions are gridded,
and the refinement -- Algorithm M's own Steps 4 and 5 -- re-grids the box
around the identified set. Two runs on the same data give the same answer,
which an MCMC search cannot promise.

{pstd}
{bf:Why this matters, measured on the authors' own CEO data.} Their shipped
empirical code pins gamma_1 to a 0.01 lattice. Over their whole 201 x 201
grid the unique best point is (0.1, 0) -- a {it:constant} threshold -- with
a sum of squares of 8491.93, while their own constant-threshold routine,
which searches the midpoints of every distinct {it:q}, finds 0.1077758 with
8490.82. The lattice costs more than the extra dimension gains. (In their
script that point is only a starting value for a sampler that refines it
off the lattice.) The exact sweep is also {bf:28 times faster} there: 5.5
seconds against 152.6.

{pstd}
{bf:The estimate is the centre of gravity of the identified set}, not any
single minimiser. The criterion is a step function, so the minimiser is
generally a {it:set}; averaging over it is the paper's own rule (Algorithm
M, Step 5) and is what makes the answer independent of the grid's order.
{cmd:e(n_set)} reports how many points were averaged.


{marker score}{...}
{title:The score test}

{pstd}
{it:H0}: {it:b1} = {it:b2}, there is no threshold effect at all. Under it
the threshold is unidentified -- Davies' problem -- so the statistic is a
supremum over the parameter space and its distribution is non-standard.
The paper's score form is cheaper than the usual Wald test because it only
ever fits the {bf:null} model, and its critical values come from simulation.

{pstd}
The p-value replaces the residuals {it:e} by {it:e}{bf:.}*{it:v} with
{it:v} ~ iid N(0,1), {bf:shared across the parameter space within a
replication}, which is what preserves the covariance kernel of the process.
That device is Hansen's (1996), and the comparison the paper draws is with
the sup-Wald test of Hansen (2000), which has to fit {it:both} regimes at
every candidate.

{pstd}
{bf:Measured size.} On 40 null replications at {it:n} = 300 the test
rejected {bf:0 times} at a nominal 5%. It is conservative rather than
oversized, which controls Type-I error; a non-rejection is correspondingly
weaker evidence than its p-value suggests.


{marker intervals}{...}
{title:Intervals: what is valid and what is not}

{pstd}
{bf:Do not invert the likelihood ratio for this threshold.} The paper
proves that method {it:invalid} for a threshold boundary. This is a live
warning rather than an abstract one: inverting the likelihood ratio is the
standard device for a threshold point, and it is the default in the sister
library THRESHKIT. It does not carry over, and {cmd:tvtboundary} does not
offer it.

{pstd}
{bf:The nonparametric posterior interval is valid}, and {opt npi(#)} is how
to get it. The quasi-posterior holds the slopes and the regime variances at
their least-squares values so that the threshold is the only free
parameter, and smooths the likelihood with a kernel density of the pooled
standardised residuals. The reported interval is the equal-tailed
percentile interval of the retained draws.

{pstd}
Two things to check in the output:

{phang2}
{bf:the acceptance rate}. The proposal scale is tuned during burn-in and
then frozen. A rate between about 0.2 and 0.5 means the chain is exploring;
far outside that, lengthen {opt burnin()} and treat the interval with
suspicion.

{phang2}
{bf:the bandwidth}. If it is implausible for your residuals, the posterior
is being smoothed wrongly and the interval will be too.

{pstd}
{bf:Measured coverage.} On 25 replications at {it:n} = 500 the nominal 95%
intervals covered the true gamma_1 23 times and the true gamma_2 22 times.

{pstd}
{bf:The slope standard errors} are the heteroskedasticity-robust sandwich
the authors use, conditional on the estimated boundary, with no
degrees-of-freedom correction.


{marker examples}{...}
{title:Examples}

{pstd}The threshold education level differs by sex{p_end}
{phang2}{cmd:. tvtboundary logwage educ exper exper2, threshvar(educ_level) zvars(female)}{p_end}

{pstd}With the interval the paper licenses{p_end}
{phang2}{cmd:. tvtboundary logwage educ exper exper2, threshvar(educ_level) zvars(female) npi(4000)}{p_end}

{pstd}An ordinary constant threshold, for comparison{p_end}
{phang2}{cmd:. tvtboundary logwage educ exper exper2, threshvar(educ_level)}{p_end}

{pstd}Is the boundary worth the extra parameter? Compare the two sums of
squares{p_end}
{phang2}{cmd:. tvtboundary y x w, threshvar(q) zvars(z)}{p_end}
{phang2}{cmd:. scalar ssr_b = e(ssr)}{p_end}
{phang2}{cmd:. tvtboundary y x w, threshvar(q)}{p_end}
{phang2}{cmd:. display "boundary " ssr_b "  constant " e(ssr)}{p_end}

{pstd}A finer search, and a wider slope range when the estimate lands on
the edge{p_end}
{phang2}{cmd:. tvtboundary y x w, threshvar(q) zvars(z) gridn(81) refine(3) g2range(-5 5)}{p_end}

{pstd}Plot the fitted boundary against the threshold variable{p_end}
{phang2}{cmd:. tvtboundary y x w, threshvar(q) zvars(z)}{p_end}
{phang2}{cmd:. tvtplot}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tvtboundary} is {cmd:e}-class. It stores

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(gamma1)}}the boundary's intercept{p_end}
{synopt:{cmd:e(N_lower)}, {cmd:e(N_upper)}}regime sizes{p_end}
{synopt:{cmd:e(ssr)}}total sum of squared residuals{p_end}
{synopt:{cmd:e(ssr1)}, {cmd:e(ssr2)}}by regime{p_end}
{synopt:{cmd:e(ssr_lin)}}the no-threshold model's{p_end}
{synopt:{cmd:e(sigma1)}, {cmd:e(sigma2)}}regime residual scales, dividing
by {it:n_j}{p_end}
{synopt:{cmd:e(n_set)}}points in the identified set, averaged{p_end}
{synopt:{cmd:e(n_cand)}, {cmd:e(n_feasible)}}gamma_2 grid points, and
splits searched{p_end}
{synopt:{cmd:e(minreg)}}smallest admissible regime size{p_end}
{synopt:{cmd:e(score)}}the score statistic{p_end}
{synopt:{cmd:e(p_score)}}its simulated p-value, if {opt simreps()}{p_end}
{synopt:{cmd:e(bandwidth)}}the posterior's kernel bandwidth{p_end}
{synopt:{cmd:e(accept)}}post-burn-in acceptance rate{p_end}
{synopt:{cmd:e(trim)}, {cmd:e(gridn)}, {cmd:e(refine)}, {cmd:e(simreps)},
{cmd:e(npi)}, {cmd:e(mesh)}}as specified{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtboundary}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}the regressors{p_end}
{synopt:{cmd:e(threshvar)}}the threshold variable{p_end}
{synopt:{cmd:e(zvars)}}the boundary's variables{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients in two equations,
{cmd:lower} and {cmd:upper}{p_end}
{synopt:{cmd:e(gamma2)}}the boundary's slopes, when {opt zvars()} is
given{p_end}
{synopt:{cmd:e(path)}}the fitted boundary, observation by
observation{p_end}
{synopt:{cmd:e(supgamma)}}where the score statistic attained its
supremum{p_end}
{synopt:{cmd:e(npi_ci)}}the posterior interval, lower and upper for each
threshold parameter{p_end}
{synopt:{cmd:e(npi_draws)}}the retained draws{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
{cmd:tvtboundary} is a clean-room implementation from the published
equations. The archive {cmd:TRBoundary.zip} carries no licence and is
therefore all-rights-reserved; its MATLAB was read to understand its
behaviour and run to produce reference numbers, and no line of it is
reproduced.

{pstd}
It is locked against that run, {bf:37 checks}, on the authors' own
26,039-observation CEO data: the constant threshold 0.1077758, both
regimes' sums of squares, all nine coefficients and robust standard errors
in each regime, the sum of squares at their own grid's optimum, the score
statistic at eight points, and the Botev bandwidth at three meshes -- the
last to eleven significant digits.

{pstd}
A further {bf:44 checks} cover what a single dataset cannot: recovery of a
known boundary, the score test's size, the posterior interval's coverage,
and the guards. Both suites are in {cmd:tests/reference/tvtboundary/} and
the equation-by-equation map is in
{cmd:validation/tvthresh/tvtboundary_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Botev, Z. I., J. F. Grotowski, and D. P. Kroese. 2010. Kernel density
estimation via diffusion. {it:Annals of Statistics} 38(5): 2916-2957.

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present
only under the alternative. {it:Biometrika} 74: 33-43.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.

{phang}
Yu, P., and X. Fan. 2020. Threshold regression with a threshold boundary.
{it:Journal of Business & Economic Statistics}.
{browse "https://doi.org/10.1080/07350015.2020.1740712":doi:10.1080/07350015.2020.1740712}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
