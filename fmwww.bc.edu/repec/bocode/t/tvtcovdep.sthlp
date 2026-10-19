{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtboundary" "help tvtboundary"}{...}
{vieweralsosee "tvtcoint" "help tvtcoint"}{...}
{vieweralsosee "tvtindex" "help tvtindex"}{...}
{vieweralsosee "tvtexport" "help tvtexport"}{...}
{viewerjumpto "Syntax" "tvtcovdep##syntax"}{...}
{viewerjumpto "Description" "tvtcovdep##description"}{...}
{viewerjumpto "What this chooses, and from what" "tvtcovdep##what"}{...}
{viewerjumpto "When to use this and not tvtboundary" "tvtcovdep##versus"}{...}
{viewerjumpto "Options" "tvtcovdep##options"}{...}
{viewerjumpto "How the problem is solved" "tvtcovdep##algorithm"}{...}
{viewerjumpto "The level constant" "tvtcovdep##constant"}{...}
{viewerjumpto "Why there are no standard errors" "tvtcovdep##nose"}{...}
{viewerjumpto "The penalty lambda" "tvtcovdep##lambda"}{...}
{viewerjumpto "Examples" "tvtcovdep##examples"}{...}
{viewerjumpto "Stored results" "tvtcovdep##results"}{...}
{viewerjumpto "Validation" "tvtcovdep##validation"}{...}
{viewerjumpto "References" "tvtcovdep##references"}{...}
{viewerjumpto "Author" "tvtcovdep##author"}{...}
{title:Title}

{phang}
{bf:tvtcovdep} {hline 2} Variable selection in a threshold model whose
threshold depends on covariates


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtcovdep} {depvar} {it:indepvars} {ifin}{cmd:,}
{opth thr:eshvar(varname)} {opth z:vars(varlist)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:The model}
{synopt :{opth thr:eshvar(varname)}}required: the threshold variable
{it:q_t}{p_end}
{synopt :{opth z:vars(varlist)}}required: the candidate variables that may
move the threshold{p_end}
{synopt :{opt nocons:tant}}no intercept in either regime{p_end}

{syntab:The selection}
{synopt :{opt lambda(#)}}the l0 penalty; the default is the paper's BIC
value {it:sigma^2 log(T)/T}{p_end}
{synopt :{opt selectcons}}select over the level constant too, as the
paper's own criterion does{p_end}
{synopt :{opt maxs:ubsets(#)}}refuse to run if a block would need more than
this many subsets; default 200000{p_end}

{syntab:The search}
{synopt :{opt trim(#)}}minimum share of the sample in each regime; default
0.15, which is the paper's{p_end}
{synopt :{opt gridn(#)}}points per threshold-slope direction; default 21{p_end}
{synopt :{opt ref:ine(#)}}grid refinement levels; default 2{p_end}
{synopt :{opt cyc:les(#)}}coordinate-descent cycles per level; default 3{p_end}
{synopt :{opt it:erate(#)}}block coordinate descent iterations; default 3{p_end}
{synopt :{opt l:evel(#)}}set confidence level; has no effect here, see
{it:Why there are no standard errors}{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{it:indepvars} may contain factor variables; see {help fvvarlist}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtcovdep} fits the threshold regression

{p 8 8 2}
{it:y_t} = {it:b1}'{it:x_t} + {it:d}'{it:x_t} 1{c -(}{it:q_t} >
{it:gamma_t}{c )-} + {it:e_t},{break}
{it:gamma_t} = {it:gamma_0} + {it:gamma_1}'{it:z_t}

{pstd}
and {bf:decides which terms belong in it}. Three selections happen at once
and they are not separable:

{phang2}
{bf:1.} which of {it:x_t} enter the level equation at all;{p_end}
{phang2}
{bf:2.} which of those {bf:shift} between the two regimes;{p_end}
{phang2}
{bf:3.} which of {it:z_t} move the threshold.{p_end}

{pstd}
They are not separable because the split {it:1{c -(}q > gamma_t{c )-}} that
decides whether a coefficient shifts is itself determined by the {it:z}'s
that are selected, and the {it:z}'s that matter depend on where the shift
is. Choosing them one at a time gives a different answer from choosing them
together. This command implements Yang (2023), which poses the three as one
l0-penalised problem.

{pstd}
Everything else in {bf:tvthresh} takes the specification as given and
estimates it. This is the only command that chooses the specification.


{marker what}{...}
{title:What this chooses, and from what}

{pstd}
With {it:px} regressors (plus a constant) and {it:pz} candidate threshold
variables the candidate terms number {it:2px + pz}: each regressor may be
in or out of the level equation, in or out of the shift, and each {it:z} may
be in or out of the threshold. The threshold intercept {it:gamma_0} is never
penalised and is always present. At the paper's own dimensions
{it:px} = {it:pz} = 5 that is 15 binary choices, so 32768 specifications.

{pstd}
They are not searched blindly: see {it:How the problem is solved}.


{marker versus}{...}
{title:When to use this and not tvtboundary}

{pstd}
{helpb tvtboundary} estimates a covariate-dependent threshold for a
specification you have already decided on, and gives you standard errors
and a score test. {cmd:tvtcovdep} decides the specification and gives you
{bf:no} standard errors.

{pstd}
So the honest sequence, when the specification is genuinely in doubt, is:

{phang2}
{bf:1.} {cmd:tvtcovdep} on one sample to find the specification;{p_end}
{phang2}
{bf:2.} {helpb tvtboundary} on an {bf:independent} sample to estimate and
test it.{p_end}

{pstd}
Running {helpb tvtboundary} on the same data that chose the specification
gives standard errors that ignore the choosing, which is the standard
objection to post-selection inference. This command will not pretend
otherwise; see {it:Why there are no standard errors}.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is required and names the threshold variable
{it:q_t}. It may not also appear in {it:indepvars}.

{phang}
{opth zvars(varlist)} is required and names the candidate variables that
may move the threshold. If none of them is selected, the threshold is
constant and the command says so.

{phang}
{opt lambda(#)} sets the l0 penalty paid per retained term. The default,
and the paper's recommendation for applications, is {it:sigma^2 log(T)/T},
with {it:sigma^2} taken from the full unselected model; this is the BIC
member of the l0 family and gives consistent selection.
{bf:The default is not a formality.} On a single draw from the paper's own
design a hand-set {opt lambda(0.02)} selected the wrong model where the BIC
value 0.035 selected the right one exactly. {cmd:e(lambda_auto)} records
which was used.

{phang}
{opt selectcons} applies the penalty to the level constant as well, which
is what the paper's own criterion does. By default the level constant is
kept in; see {it:The level constant}.

{phang}
{opt maxsubsets(#)} caps the enumeration. If a block would need more
subsets than this, the command {bf:refuses to run} rather than quietly
falling back on something worse. Raise it if you are willing to wait.

{phang}
{opt trim(#)} is the minimum share of the sample required in each regime,
the paper's constraint (14). The default 0.15 is the paper's own choice.
{cmd:e(minreg)} reports the resulting count.

{phang}
{opt gridn(#)}, {opt refine(#)} and {opt cycles(#)} control the search over
the threshold slopes {it:gamma_1}. {cmd:e(g1step)} reports the finest step
the settings can actually reach: {it:gamma_1} cannot be resolved below it,
so if you need it sharper, raise {opt refine()} rather than
{opt gridn()} -- each refinement level divides the step by
({it:gridn}-1)/4, so the default two levels already give a step five times
finer than the grid alone.

{phang}
{opt iterate(#)} is the number of block coordinate descent passes. The
paper uses two, following Lee et al. (2021); the default here is three.


{marker algorithm}{...}
{title:How the problem is solved}

{pstd}
{bf:The paper solves its l0 problem with mixed integer quadratic
programming, through Gurobi. Stata and Mata have no mixed integer solver.}
That route is simply unavailable here.

{pstd}
What is available is the paper's own fallback. Its section 2.1 gives a
{bf:block coordinate descent} algorithm precisely because the MIQP "may run
slowly", splitting the problem into two blocks. Here each block is solved
by {bf:exhaustive enumeration of its subsets} -- which at the paper's own
dimensions is not an approximation of the MIO answer but the exact
minimiser of that block, found by inspecting every candidate:

{phang2}
{bf:block (b)}, the slopes given the split, is a best-subset least-squares
problem on [{it:x}, {it:x}*{it:d}]: 2^(2{it:px}) fits, 1024 at
{it:px} = 5.{p_end}
{phang2}
{bf:block (a)}, the threshold given the slopes, enumerates the 2^{it:pz}
subsets of {it:z}, 32 at {it:pz} = 5.{p_end}

{pstd}
Block (a) has a structure the paper does not exploit. Its objective is
{bf:linear in the regime indicator} -- once the slopes are fixed, the
quadratic part of the sum of squares does not involve the threshold at all.
So with {it:a_t} for the per-observation contribution the problem is just
"choose the split minimising sum {it:a_t d_t}". And since
{it:d_t} = 1{c -(}{it:q_t} > {it:gamma_0} + {it:gamma_1}'{it:z_t}{c )-} is
{it:w_t} > {it:gamma_0} with {it:w_t} = {it:q_t} -
{it:gamma_1}'{it:z_t}, sorting by {it:w} and walking {it:gamma_0} downwards
accumulates {it:a_t} one observation at a time: {bf:every distinct split is
visited in one pass and the threshold intercept is exact and free}. Only
the {it:gamma_1} directions need a grid, and they get coordinate descent
with refinement.

{pstd}
{bf:The paper's own table says this costs nothing.} Its Table 1, panel A at
{it:T} = 100, reports perfect-selection rates of 0.801 for MIQP against
0.832 for the grid-started BCD: the exact solver does {it:worse}, because
it is given a 60-second budget and returns whatever incumbent it has
reached when the clock stops. An exhaustive block solve has no clock.

{pstd}
The start is the full model -- every {it:x}, every shift, every {it:z}
active -- whose threshold is found by the same exact sweep. The paper's
MIQP start and its uniform-draw start are both unavailable and neither is
needed: this one is deterministic, so two runs on the same data agree
exactly.

{pstd}
{cmd:e(n_visited)} counts the models actually fitted and
{cmd:e(greedy)} is 1 if any block ever had to abandon its enumeration, in
which case the output says the answer is not the exact block minimiser.


{marker constant}{...}
{title:The level constant}

{pstd}
The paper's penalty sums over all {it:2px + pz} indicators, {bf:the level
intercept among them}, so in the paper the level constant can be dropped.
(The "+1" in its "{it:2px + pz + 1} parameters" is {it:gamma_0}, which is
never penalised.)

{pstd}
By default this command {bf:keeps the level constant in} rather than
selecting over it, because a threshold regression whose lower regime has no
intercept is almost never what an applied user means, and a command that
silently removed it would be reporting a different model from the one asked
for. {opt selectcons} restores the paper's criterion exactly.
{cmd:e(selectcons)} records which was used, and the output says so.

{pstd}
Under either setting the {bf:all-zero} slope model is never visited: with no
active slope term there is no regression, the trimming constraint is vacuous
and the threshold is unidentified. Every non-empty subset is visited.


{marker nose}{...}
{title:Why there are no standard errors}

{pstd}
{bf:This command reports no standard errors, and that is deliberate.} Any
it reported would be conditional on the selection while ignoring that the
selection happened -- the standard objection to post-selection inference.
The paper derives no post-selection distribution and neither does this
command. {cmd:e(V)} is posted as a matrix of zeros only because
{cmd:ereturn post} requires one; it is not an estimate of anything and
must not be read as one.

{pstd}
{opt level()} is accepted so that the command composes with the rest of the
library, and has no effect.

{pstd}
If you need inference on the selected specification, refit it with
{helpb tvtboundary} on data that did not choose it.


{marker lambda}{...}
{title:The penalty lambda}

{pstd}
Model selection criteria sit inside the l0 framework through the penalty
(Buhlmann and van de Geer 2011):
{it:lambda} = {it:sigma^2 log(T)/T} is BIC and {it:lambda} =
{it:2 sigma^2/T} is AIC. The paper recommends the BIC value for
applications because it gives consistent selection, following
Wang, Li and Leng (2009), and that is the default; {cmd:e(lambda)} reports the value used and
{cmd:e(lambda_auto)} whether it was computed or given.

{pstd}
To use AIC instead, pass it explicitly:

{p 8 12 2}
{cmd:. quietly regress y x2 x3 x4 x5}{break}
{cmd:. local aic = 2*e(rss)/e(df_r)/_N}{break}
{cmd:. tvtcovdep y x2 x3 x4 x5, threshvar(q) zvars(z1 z2) lambda(`aic')}

{pstd}
AIC does not give consistent selection and will keep more terms. The
paper's own consistency result is for the BIC value.


{marker examples}{...}
{title:Examples}

{pstd}
The paper's own design: five candidate regressors, five candidate threshold
variables, and a truth in which only two of each matter.{p_end}

{phang2}{cmd:. set seed 4242}{p_end}
{phang2}{cmd:. set obs 250}{p_end}
{phang2}{cmd:. generate int t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. forvalues j = 2/5 {c -(}}{p_end}
{phang2}{cmd:.     generate double x`j' = rnormal(0, 0.5)}{p_end}
{phang2}{cmd:.     quietly replace x`j' = 0.5*x`j'[_n-1] + rnormal(0, 0.5) in 2/l}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. forvalues j = 1/5 {c -(}}{p_end}
{phang2}{cmd:.     generate double z`j' = rnormal()}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. generate double q = rnormal()}{p_end}
{phang2}{cmd:. generate double y = 1 + x2 + (1 + x2)*(q > 0.1 + 0.5*z1 + 0.5*z2) + rnormal(0, 0.5)}{p_end}
{phang2}{cmd:. drop in 1/50}{p_end}

{pstd}
Select:{p_end}
{phang2}{cmd:. tvtcovdep y x2 x3 x4 x5, threshvar(q) zvars(z1 z2 z3 z4 z5)}{p_end}

{pstd}
The paper's own criterion, with the level constant penalised too:{p_end}
{phang2}{cmd:. tvtcovdep y x2 x3 x4 x5, threshvar(q) zvars(z1 z2 z3 z4 z5) selectcons}{p_end}

{pstd}
A sharper threshold slope, at the cost of more sweeps:{p_end}
{phang2}{cmd:. tvtcovdep y x2 x3 x4 x5, threshvar(q) zvars(z1 z2 z3 z4 z5) refine(3)}{p_end}
{phang2}{cmd:. display e(g1step)}{p_end}

{pstd}
What was chosen, as matrices:{p_end}
{phang2}{cmd:. matrix list e(selected)}{p_end}
{phang2}{cmd:. matrix list e(zselected)}{p_end}
{phang2}{cmd:. matrix list e(gamma1)}{p_end}

{pstd}
And the fitted threshold path, one value per observation:{p_end}
{phang2}{cmd:. matrix p = e(path)}{p_end}
{phang2}{cmd:. svmat double p, name(gamhat)}{p_end}
{phang2}{cmd:. twoway line gamhat1 t || scatter q t if q > gamhat1, msize(tiny)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtcovdep} is {cmd:eclass} and stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(gamma0)}}the threshold intercept{p_end}
{synopt:{cmd:e(ssr)}}sum of squared residuals at the selected model{p_end}
{synopt:{cmd:e(ssr_full)}}sum of squared residuals at the full model{p_end}
{synopt:{cmd:e(sigma2)}}residual variance used for the BIC penalty{p_end}
{synopt:{cmd:e(crit)}}the l0 criterion attained{p_end}
{synopt:{cmd:e(lambda)}}the penalty used{p_end}
{synopt:{cmd:e(lambda_auto)}}1 if {cmd:e(lambda)} was computed by BIC{p_end}
{synopt:{cmd:e(N_lower)}}observations in the lower regime{p_end}
{synopt:{cmd:e(N_upper)}}observations in the upper regime{p_end}
{synopt:{cmd:e(k_sel)}}terms selected in all{p_end}
{synopt:{cmd:e(k_slope)}}slope terms selected{p_end}
{synopt:{cmd:e(k_thresh)}}threshold variables selected{p_end}
{synopt:{cmd:e(n_visited)}}models fitted{p_end}
{synopt:{cmd:e(iterations)}}block coordinate descent passes used{p_end}
{synopt:{cmd:e(greedy)}}1 if an enumeration was abandoned{p_end}
{synopt:{cmd:e(minreg)}}minimum regime size imposed{p_end}
{synopt:{cmd:e(trim)}}the trimming fraction{p_end}
{synopt:{cmd:e(refine)}}refinement levels used{p_end}
{synopt:{cmd:e(g1step)}}finest reachable {it:gamma_1} step{p_end}
{synopt:{cmd:e(selectcons)}}1 if the level constant was selected over{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtcovdep}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}the candidate regressors{p_end}
{synopt:{cmd:e(threshvar)}}the threshold variable{p_end}
{synopt:{cmd:e(zvars)}}the candidate threshold variables{p_end}
{synopt:{cmd:e(title)}}title in the output{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficients, zero where excluded, in two equations
{cmd:level:} and {cmd:shift:}{p_end}
{synopt:{cmd:e(V)}}zeros; see {it:Why there are no standard errors}{p_end}
{synopt:{cmd:e(selected)}}0/1 indicators matching {cmd:e(b)}{p_end}
{synopt:{cmd:e(zselected)}}0/1 indicators over {cmd:e(zvars)}{p_end}
{synopt:{cmd:e(gamma1)}}the threshold slopes, zero where excluded{p_end}
{synopt:{cmd:e(path)}}the fitted threshold, one row per observation{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker validation}{...}
{title:Validation}

{pstd}
No reference code ships with the paper; the paper's simulations were run in
R with Gurobi. The implementation here is clean-room from the published
equations and is validated against the paper's own Table 1, panel A, which
reports perfect-selection rates and three error rates for the Oracle, the
MIQP, the BCD and the GBCD at {it:T} = 100 and 200.

{pstd}
Two things the paper leaves implicit had to be settled from the table
itself, and both are recorded in full in
{bf:validation/tvthresh/tvtcovdep_equation_map.md}:

{phang2}
{bf:1. The error variance is never stated.} Equation (20) has an error
{it:epsilon_t}; the only variance given is for the covariates' AR(1)
innovations, under the same symbol. Table 1's MSE column settles it: every
row reports 0.25 to 0.26, and the Oracle's mean square prediction error
{it:is} the error variance. So sigma = 0.5. At sigma = 1 every selection
statistic in the table collapses.{p_end}

{phang2}
{bf:2. FNZ and FZ are per-replication frequencies, not parameter ratios},
despite the words "the ratio of the number of ... parameters". Under the
ratio reading GBCD's FZ = 0.153 would mean 0.92 true terms dropped per
replication, each contributing at least 0.5 to the l1 error, forcing
l1 >= 0.99 where the table reports 0.587 against an oracle of 0.531 -- and
that contradiction appears in five of the seven published rows. Reading
them as the fraction of replications containing at least one such error
reproduces the l1 column everywhere.{p_end}

{pstd}
The certification suite is
{bf:tests/reference/tvtcovdep/certify_tvtcovdep.do}. It pins both blocks at
their limits without reference to any data -- with {it:lambda} = 0 block (b)
must keep every term and reproduce the full model's sum of squares exactly,
with {it:lambda} enormous only the forced one -- then measures the paper's
four statistics at both sample sizes, repeats the whole comparison under
{opt selectcons}, and checks structure, determinism and ten guards.


{marker references}{...}
{title:References}

{phang}
Yang, L. 2023. Variable selection in threshold model with a
covariate-dependent threshold. {it:Empirical Economics} 65: 189-202.
{browse "https://doi.org/10.1007/s00181-022-02340-3":doi:10.1007/s00181-022-02340-3}

{phang}
Lee, S., Y. Liao, M. H. Seo, and Y. Shin. 2021. Factor-driven two-regime
regression. {it:Annals of Statistics} 49: 1656-1678.
{browse "https://doi.org/10.1214/20-AOS2017":doi:10.1214/20-AOS2017}

{phang}
Buhlmann, P., and S. van de Geer. 2011. {it:Statistics for
High-Dimensional Data: Methods, Theory and Applications}. Berlin: Springer.

{phang}
Wang, H., B. Li, and C. Leng. 2009. Shrinkage tuning parameter selection
with a diverging number of parameters. {it:Journal of the Royal
Statistical Society, Series B} 71: 671-683.
{browse "https://doi.org/10.1111/j.1467-9868.2008.00693.x":doi:10.1111/j.1467-9868.2008.00693.x}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
