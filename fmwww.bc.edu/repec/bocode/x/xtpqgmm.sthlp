{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "xtpqgmm postestimation" "help xtpqgmm_postestimation"}{...}
{vieweralsosee "xtpqgmm_methods" "help xtpqgmm_methods"}{...}
{vieweralsosee "xtpqgmmplot" "help xtpqgmmplot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "sivqr" "help sivqr"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{vieweralsosee "qregfe" "help qregfe"}{...}
{vieweralsosee "xtqreg" "help xtqreg"}{...}
{vieweralsosee "xtmdqr" "help xtmdqr"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "ivregress" "help ivregress"}{...}
{vieweralsosee "gmm" "help gmm"}{...}
{viewerjumpto "Syntax" "xtpqgmm##syntax"}{...}
{viewerjumpto "Description" "xtpqgmm##description"}{...}
{viewerjumpto "Quick start" "xtpqgmm##quickstart"}{...}
{viewerjumpto "Options" "xtpqgmm##options"}{...}
{viewerjumpto "What the command needs from your data" "xtpqgmm##data"}{...}
{viewerjumpto "Reading the output" "xtpqgmm##output"}{...}
{viewerjumpto "Remarks" "xtpqgmm##remarks"}{...}
{viewerjumpto "Examples" "xtpqgmm##examples"}{...}
{viewerjumpto "Postestimation" "xtpqgmm##post"}{...}
{viewerjumpto "Stored results" "xtpqgmm##results"}{...}
{viewerjumpto "References" "xtpqgmm##references"}{...}
{viewerjumpto "Author" "xtpqgmm##author"}{...}

{p2colset 1 16 18 2}{...}
{p2col:{bf:xtpqgmm} {hline 2}}Smoothed profiled GMM for panel quantile
regression with fixed effects and endogenous regressors{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpqgmm} {depvar} [{it:exogvars}]
{cmd:(}{it:endogvars} {cmd:=} {it:instruments}{cmd:)}
{ifin}{cmd:,} {opth q:uantile(numlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opth q:uantile(numlist)}}quantile(s) to estimate; give either
percentages ({cmd:25 50 75}) or proportions ({cmd:.25 .5 .75}){p_end}

{syntab:Model}
{synopt :{opth id(varname)}}panel identifier; default is the {helpb xtset}
panel variable{p_end}
{synopt :{opt mm}}SP-MM, the exactly identified method-of-moments estimator
(eq. 9){p_end}
{synopt :{opt one:step}}one-step SP-GMM with identity weighting (eq. 10){p_end}
{synopt :{opt smoothw:eight}}build the two-step weighting matrix from the
smoothed score instead of the unsmoothed one{p_end}

{syntab:Smoothing and inference}
{synopt :{opt b:andwidth(#)}}smoothing bandwidth {it:h}; default is the
plug-in {it:h} = {it:c}({it:tau}) {it:T}^(-2/7){p_end}
{synopt :{opt lag:s(#)}}Bartlett truncation lag for the HAC covariance;
default is max(1, floor({it:T}^(1/5))){p_end}
{synopt :{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}

{syntab:Numerical}
{synopt :{opt nonmf:allback}}do not polish with Nelder-Mead when the
Gauss-Newton step struggles{p_end}
{synopt :{opt iter:log}}show the optimiser's iteration log{p_end}

{syntab:Reporting and guard rails}
{synopt :{opt mint(#)}}smallest number of observations a unit may have;
default {cmd:mint(5)}, below which the command refuses{p_end}
{synopt :{opt warnt(#)}}warn when the shortest unit is below this;
default {cmd:warnt(20)}{p_end}
{synopt :{opt nowar:nings}}suppress the advisory notes (the diagnostics in the
footer are still shown){p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
The data must be {helpb xtset} unless {opt id()} is given.{p_end}
{p 4 6 2}
{it:endogvars} and {it:instruments} may use time-series operators, so
{cmd:L.y} and {cmd:L(2/5).y} work; see {helpb tsvarlist}.{p_end}
{p 4 6 2}
Weights are {bf:not} allowed. {cmd:by} is allowed; see {helpb by}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqgmm} fits the panel data quantile regression model

{p 8 8 2}
{it:Q}({it:tau})[ {it:y(i,t)} {c -} {it:alpha(i)} {c -}
{it:x(i,t)}'{it:beta} {c |} {it:z(i,t)}, {it:alpha(i)} ] {cmd:=} 0

{pstd}
by the smoothed profiled GMM estimator of
{browse "https://arxiv.org/abs/2610.12824":Galvao, Hounyo and Lin (2026)}. The
regressors {it:x(i,t)} may be {bf:endogenous}; the instruments {it:z(i,t)}
supply the identifying moments; and each unit has its own fixed effect
{it:alpha(i)}, which may differ across quantiles.

{pstd}
Three features distinguish it from the other panel quantile commands:

{p 4 7 2}
1. It handles {bf:endogenous regressors} inside a panel with fixed effects.
{helpb mmqreg}, {helpb qregfe} and {helpb xtqreg} do not; {helpb sivqr} and
{helpb ivqreg2} do but have no fixed effects.

{p 4 7 2}
2. It is {bf:computationally tractable}. The indicator in the quantile moment
is replaced by a smooth function, so ordinary GMM machinery applies instead of
the repeated inverse-quantile-regression search of
Chernozhukov and Hansen (2006).

{p 4 7 2}
3. Inference allows {bf:serial dependence} within a unit, so dynamic panels,
lagged instruments and HAC standard errors are all accommodated.

{pstd}
The fixed effects are not dummy variables. For each candidate {it:beta} the
command solves one scalar quantile restriction per unit and substitutes the
result, which reduces the optimisation to {it:beta} alone. See
{help xtpqgmm_methods:{bf:xtpqgmm_methods}} for the full account, written to be
read alongside the paper.

{pstd}
{bf:Interpretation.} Under the structural IVQR conditions of
Chernozhukov and Hansen (2005), {it:beta} is a structural quantile response
parameter. Without them, it is the parameter identified by the unconditional
moment restrictions, which need not have a causal reading. This matters, and
{help xtpqgmm_methods##interp:the methods page} spells it out.


{marker quickstart}{...}
{title:Quick start}

{pstd}
A static panel, one endogenous regressor {cmd:x}, two excluded instruments,
median:

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(50)}{p_end}

{pstd}
Three quantiles in one call:

{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(25 50 75)}{p_end}

{pstd}
With an exogenous control {cmd:w} alongside the endogenous {cmd:x}:

{phang2}{cmd:. xtpqgmm y w (x = z1 z2), quantile(50)}{p_end}

{pstd}
A dynamic panel, instrumenting the lagged outcome with deeper lags:

{phang2}{cmd:. xtpqgmm y w (L.y = L2.y L3.y), quantile(25 50 75)}{p_end}

{pstd}
Afterwards, the usual postestimation works:

{phang2}{cmd:. test x = 1}{p_end}
{phang2}{cmd:. lincom x - 1}{p_end}
{phang2}{cmd:. estimates store q50}{p_end}
{phang2}{cmd:. esttab q25 q50 q75, se}{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth q:uantile(numlist)} gives the quantile or quantiles to estimate. Both
conventions are accepted: {cmd:quantile(25)} and {cmd:quantile(.25)} mean the
same thing, as in {helpb qreg} and {helpb sivqr}. Values must lie strictly
between 0 and 100 (or 0 and 1).

{pmore}
With more than one quantile, each is estimated {bf:separately} and the results
are stacked into one {cmd:e(b)} and {cmd:e(V)} with equation names
{cmd:q25}, {cmd:q50}, and so on. The off-diagonal blocks of {cmd:e(V)} are
{bf:exactly zero}, because the paper supplies no cross-quantile covariance.
Tests {it:within} a quantile are valid; tests {it:across} quantiles are not.
Monotonicity across quantiles is not imposed.

{dlgtab:Model}

{phang}
{opth id(varname)} names the panel identifier. Omit it and the {helpb xtset}
panel variable is used. The variable may be numeric or string.

{phang}
{opt mm} fits SP-MM, the exactly identified method-of-moments estimator of
equation (9). When there are more instruments than parameters, SP-MM uses the
{it:d} within-projection combinations of the instruments. SP-MM is always
computed internally as the starting value and is returned in {cmd:e(b_mm)};
this option simply reports it as the final answer.

{phang}
{opt onestep} fits the one-step SP-GMM of equation (10), with the identity
weighting matrix. The default is the two-step estimator of equation (11),
which reweights by the inverse of the estimated long-run variance and is the
paper's headline estimator.

{phang}
{opt smoothweight} builds the first-step weighting matrix from the
{it:smoothed} score rather than the unsmoothed indicator. Both are
first-order equivalent. The default follows the paper's own simulations.

{dlgtab:Smoothing and inference}

{phang}
{opt bandwidth(#)} sets the smoothing bandwidth {it:h} directly. The default
is the plug-in rule of Section 6,

{p 12 12 2}
{it:h} = {it:c}({it:tau}) {it:T}^(-2/7),{break}
{it:c}({it:tau}) = [ 4.5 {it:phi}({it:Phi}^-1({it:tau}))^4 /
(2 {it:Phi}^-1({it:tau})^2 + 1)^2 ]^(1/5),

{pmore}
with {it:T} the average number of observations per unit. The bandwidth
actually used is reported in the header and returned in {cmd:e(bwidth)}.
Bandwidth choice matters in finite samples and the paper names it as an open
question; {help xtpqgmm_methods##bw:the methods page} explains the admissible
range.

{phang}
{opt lags(#)} sets the Bartlett truncation lag for the HAC covariance of
Section 5. The default is max(1, floor({it:T}^(1/5))), the rule used in the
paper. The theory requires the lag to grow with {it:T} while
lag^2 log({it:nT})/({it:T h}^2) tends to zero; the command checks that
condition and notes it in the footer when it is uncomfortable. The
{bf:optimal} lag for this estimator is an unsolved problem, so treat
{cmd:lags()} as a sensitivity dimension, not a tuned parameter.

{phang}
{opt level(#)} sets the confidence level for the reported intervals.

{dlgtab:Numerical}

{phang}
{opt nonmfallback} turns off the Nelder-Mead polish. By default, when the
Gauss-Newton step fails to converge, or when Nelder-Mead finds a lower
criterion value, the Nelder-Mead result is taken. The profiled GMM criterion
can be non-convex, which is why the fallback exists.

{pmore}
The paper's own implementation used simulated annealing (R's {cmd:GenSA}).
Mata has no simulated annealing, so {cmd:xtpqgmm} uses a Gauss-Newton step
from the SP-MM start with a Nelder-Mead polish. This is a {bf:deliberate
deviation} from the paper's optimiser and is recorded as such in
{help xtpqgmm_methods##optim:the methods page}.

{phang}
{opt iterlog} shows the optimiser's iteration log, and is also what to use
when an estimation fails and you want to see why.

{dlgtab:Reporting and guard rails}

{phang}
{opt mint(#)} is the smallest number of usable observations a unit may have.
Below it the command refuses to estimate. The default is 5. Graham, Hahn and
Powell (2009) show the common slope is not identified at {it:T} = 2, and the
profiled restriction needs enough within-unit variation to have a root at all.
Lower it only if you know why you are doing so.

{phang}
{opt warnt(#)} is the threshold below which the command warns about short
units. The default is 20, the smallest {it:T} in the paper's own simulations,
where coverage of a nominal 95% interval was 0.896.

{phang}
{opt nowarnings} suppresses the advisory notes printed before estimation. The
diagnostics printed {it:after} the table are not suppressed: they report what
actually happened and are not optional.


{marker data}{...}
{title:What the command needs from your data}

{pstd}
{cmd:xtpqgmm} is strict about shape, because the estimator and its covariance
are only defined for certain shapes. Each requirement below is enforced, with
a message that says what to do.

{p 4 7 2}
{bf:A panel.} {helpb xtset} the data, or give {opt id()}.

{p 4 7 2}
{bf:At least one endogenous regressor.} With none, there is nothing to
instrument: use {helpb mmqreg} or {helpb qregfe}.

{p 4 7 2}
{bf:At least as many instruments as regressors.} Equation (3) needs
{it:dz} {ul:>} {it:d}. Under-identified models are refused.

{p 4 7 2}
{bf:No internal gaps in time.} The HAC covariance sums products at
{it:t} and {it:t+j} within a unit, which is undefined across a gap. If your
panel has holes, fill them, drop them, or restrict to a contiguous span.
Nothing is interpolated for you, and no silent dropping happens.

{p 4 7 2}
{bf:Enough observations per unit.} See {opt mint()} and {opt warnt()}.
Unbalanced panels are allowed as long as each unit's span is contiguous; the
profile is solved unit by unit using that unit's own {it:T}.

{p 4 7 2}
{bf:No weights.} The asymptotic theory and the bandwidth rule are stated for
unweighted panels.

{pstd}
{bf:Cross-sectional dependence} is assumed away. The covariance of Section 5
treats units as independent, and the paper's own empirical application
concedes this in a footnote. {cmd:xtpqgmm} offers no Driscoll-Kraay option,
because the paper provides no basis for one.


{marker output}{...}
{title:Reading the output}

{pstd}
The header reports the things that change the answer: the estimator variant,
the bandwidth and HAC lag actually used, the number of over-identifying
restrictions, the ratio {it:n}/{it:T}, and the norm of the moment vector at
the optimum. A small {cmd:||g||} means the moment conditions were actually
solved; a large one means they were not, and the command says so.

{pstd}
Below the table, {cmd:xtpqgmm} prints diagnostics whenever they apply:

{p 4 7 2}
{bf:n / T-bar.} Theorem 4.1 assumes {it:n}/{it:T} tends to zero. When
{it:n} is not small relative to {it:T}, the incidental-parameter bias is of
order sqrt({it:n}/{it:T}) and is {bf:not} corrected. The command prints the
magnitude so you can judge it. See {help xtpqgmm_methods##nT:here}.

{p 4 7 2}
{bf:Multiple roots.} The fourth-order kernel takes negative values, so the
smoothed indicator is not monotone and the profiled restriction can have more
than one root. The command counts the affected units and reports the count in
{cmd:e(n_multiroot)}; the root nearest the unsmoothed quantile is used. This
is a property of the kernel, not of your data. See
{help xtpqgmm_methods##roots:here}.

{p 4 7 2}
{bf:Profile failures.} If the restriction had no root for some unit, the count
appears in {cmd:e(n_profilefail)} and a warning is printed. Any non-zero count
deserves investigation.

{p 4 7 2}
{bf:Convergence.} The optimiser's tolerance on {cmd:||g||} is very tight. A
near miss is reported as a note; a genuine failure as a warning.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Comparing with} {helpb sivqr} {bf:on cross-sectional data.} With a single
unit and no fixed effect, this estimator's moment system coincides with the
one {helpb sivqr} solves. Two differences will still show up, and neither is a
bug:

{p 8 11 2}
(a) {helpb sivqr} as shipped uses the integrated {bf:uniform}
(second-order) smoothed indicator, not the fourth-order kernel of Kaplan and
Sun (2017) and of this paper. Its own source carries the fourth-order line
commented out. Switching kernels moves the estimate in the {bf:third}
decimal, so this is the larger of the two differences.

{p 8 11 2}
(b) {helpb sivqr} stops when its solver is satisfied, which leaves the
moment vector around 1e-5; {cmd:xtpqgmm} drives it to roughly 1e-15. That
accounts for a difference in the {bf:fifth} decimal.

{pstd}
{bf:There is no overidentification test.} The model is typically
over-identified, and a Hansen-Sargan {it:J} statistic would be the natural
diagnostic, but the paper does not derive one, and the distribution of a
{it:J} statistic after profiling out {it:n} fixed effects from a smoothed
moment is not established. {cmd:xtpqgmm} therefore reports no {it:J} test
rather than reporting one that cannot be justified. Nor is there a
weak-instrument diagnostic. {cmd:e(mnorm)} and {cmd:e(Qval)} are made
available for your own judgement.

{pstd}
{bf:The kernel is not a tuning knob.} Only the paper's fourth-order kernel is
offered. A second-order kernel would violate the assumptions behind the
bandwidth rate, and would change the estimates materially.

{pstd}
{bf:The smoothed indicator is not a probability.} It leaves the unit interval
by about 0.053 at either end, by construction. Do not read it, or anything
derived from it, as a fitted probability.

{pstd}
{bf:Speed.} The inner profile is solved once per unit per evaluation of the
criterion, so cost grows with {it:n} and with the number of quantiles. The
inner solve is a safeguarded Newton step and is cheap; the outer search is
where the time goes. {opt nonmfallback} is noticeably faster when the criterion
is well behaved.


{marker examples}{...}
{title:Examples}

{pstd}
A reproducible endogenous panel, built to satisfy the quantile restriction at
the median:

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20261014}{p_end}
{phang2}{cmd:. set obs 1800}{p_end}
{phang2}{cmd:. generate int id = ceil(_n/60)}{p_end}
{phang2}{cmd:. bysort id: generate int t = _n}{p_end}
{phang2}{cmd:. bysort id: generate double a = runiform(-1,1)}{p_end}
{phang2}{cmd:. by id: replace a = a[1]}{p_end}
{phang2}{cmd:. generate double z1 = rnormal()}{p_end}
{phang2}{cmd:. generate double z2 = rnormal()}{p_end}
{phang2}{cmd:. generate double v = rnormal()}{p_end}
{phang2}{cmd:. generate double u = 0.6*v + sqrt(1-0.36)*rnormal()}{p_end}
{phang2}{cmd:. generate double x = z1 + z2 + v}{p_end}
{phang2}{cmd:. generate double y = a + x + u}{p_end}
{phang2}{cmd:. xtset id t}{p_end}

{pstd}
{cmd:x} is correlated with {cmd:u} through {cmd:v}, while {cmd:z1} and
{cmd:z2} are not, so the instruments are valid and the regressor is
endogenous. The true slope is 1.

{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(50)}{p_end}

{pstd}
Compare with the fixed-effects quantile estimators, which do not correct for
endogeneity and should be visibly biased here:

{phang2}{cmd:. qregfe y x, id(id) quantile(50)}{p_end}
{phang2}{cmd:. mmqreg y x, absorb(id) quantile(50)}{p_end}

{pstd}
Across quantiles, then a publication table:

{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(10 25 50 75 90)}{p_end}
{phang2}{cmd:. estimates store sp}{p_end}
{phang2}{cmd:. esttab sp, se nostar scalars("bwidth Bandwidth" "N_g Groups")}{p_end}

{pstd}
Sensitivity to the two tuning choices that matter:

{phang2}{cmd:. foreach h in 0.1 0.15 0.2 0.3 {c -(}}{p_end}
{phang2}{cmd:.     xtpqgmm y (x = z1 z2), quantile(50) bandwidth(`h')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. forvalues L = 1/4 {c -(}}{p_end}
{phang2}{cmd:.     xtpqgmm y (x = z1 z2), quantile(50) lags(`L')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker post}{...}
{title:Postestimation}

{pstd}
{helpb xtpqgmm_postestimation:[xtpqgmm] postestimation} documents these in
full. In brief:

{phang}
{helpb xtpqgmmplot} draws the coefficient path {it:beta}-hat({it:tau}) over a
grid of quantiles, with {bf:pointwise} bands.

{phang}
{cmd:predict} offers {opt xba} (the fitted conditional quantile, the default),
{opt xb}, {opt alpha} and {opt residuals}. There is deliberately no
probability statistic: the smoothed indicator is not a CDF, since the
fourth-order kernel makes it leave [0,1].

{phang}
{cmd:estat overid} reports Hansen's J, {cmd:estat diagnostics} prints every
number the fit knows about its own quality, and {cmd:estat alpha} summarises
the profiled-out fixed effects and can write them out as a variable.

{phang}
{helpb test}, {helpb lincom} and the rest work normally {it:within} a
quantile. {bf:Across} quantiles they are not valid -- {cmd:e(V)} is block
diagonal with exactly zero off-diagonal blocks because the paper supplies no
cross-quantile covariance.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqgmm} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of units{p_end}
{synopt:{cmd:e(T_bar)}}average observations per unit{p_end}
{synopt:{cmd:e(T_min)}, {cmd:e(T_max)}}shortest and longest unit{p_end}
{synopt:{cmd:e(n_over_T)}}{it:n} / {it:T}-bar{p_end}
{synopt:{cmd:e(q)}}the quantile, when only one was requested{p_end}
{synopt:{cmd:e(n_q)}}number of quantiles estimated{p_end}
{synopt:{cmd:e(df_m)}}number of parameters {it:d}{p_end}
{synopt:{cmd:e(n_inst)}}number of instruments {it:dz}{p_end}
{synopt:{cmd:e(n_over)}}over-identifying restrictions, {it:dz} {c -} {it:d}{p_end}
{synopt:{cmd:e(bwidth)}}smoothing bandwidth used{p_end}
{synopt:{cmd:e(korder)}}kernel order (4){p_end}
{synopt:{cmd:e(haclag)}}Bartlett truncation lag used{p_end}
{synopt:{cmd:e(haclagok)}}1 if the lag condition is comfortably satisfied{p_end}
{synopt:{cmd:e(mnorm)}}norm of the profiled moment vector at the estimate{p_end}
{synopt:{cmd:e(gnorm)}}norm of the GMM gradient at the optimum{p_end}
{synopt:{cmd:e(Qval)}}value of the GMM criterion{p_end}
{synopt:{cmd:e(ic)}}iterations used{p_end}
{synopt:{cmd:e(converged)}}1 if the optimiser met its tolerance{p_end}
{synopt:{cmd:e(maxA)}}largest absolute value of the profiled restriction (8){p_end}
{synopt:{cmd:e(n_multiroot)}}units with several roots of (8) at the solution{p_end}
{synopt:{cmd:e(n_profilefail)}}unit-evaluations where (8) had no root{p_end}
{synopt:{cmd:e(jstat)}}Hansen's J, when one quantile and over-identified{p_end}
{synopt:{cmd:e(jstat_df)}}its degrees of freedom, {it:dz} {c -} {it:d}{p_end}
{synopt:{cmd:e(jstat_p)}}its p-value{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpqgmm}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(estimator)}}which variant was fitted{p_end}
{synopt:{cmd:e(instd)}}endogenous regressors{p_end}
{synopt:{cmd:e(exogr)}}exogenous regressors{p_end}
{synopt:{cmd:e(insts)}}full instrument list{p_end}
{synopt:{cmd:e(idvar)}}panel variable{p_end}
{synopt:{cmd:e(timevar)}}time variable, when set{p_end}
{synopt:{cmd:e(quantiles)}}quantiles estimated, as proportions{p_end}
{synopt:{cmd:e(eqnames)}}equation names, when several quantiles{p_end}
{synopt:{cmd:e(kernel)}}kernel description{p_end}
{synopt:{cmd:e(hackernel)}}{cmd:Bartlett}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:HAC}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtpqgmm_p}{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtpqgmm_estat}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix, {it:Sigma}/({it:nT}){p_end}
{synopt:{cmd:e(alpha)}}profiled fixed effects: one row per unit, one
{bf:column per quantile}{p_end}
{synopt:{cmd:e(jtable)}}over-identification table: one row per quantile,
columns {cmd:tau}, {cmd:J}, {cmd:df}, {cmd:p}{p_end}
{synopt:{cmd:e(b_mm)}}the SP-MM estimate used as the starting value{p_end}
{synopt:{cmd:e(Sigma)}}{it:Sigma}, before division by {it:nT}{p_end}
{synopt:{cmd:e(D)}}Jacobian {it:D}-hat of Section 5{p_end}
{synopt:{cmd:e(Omega)}}long-run variance {it:Omega}-hat{p_end}
{synopt:{cmd:e(Wmat)}}weighting matrix used{p_end}
{synopt:{cmd:e(mvec)}}profiled moment vector at the estimate{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}

{pstd}
The matrices {cmd:e(Sigma)}, {cmd:e(D)}, {cmd:e(Omega)}, {cmd:e(Wmat)},
{cmd:e(mvec)} and {cmd:e(b_mm)} are stored only when a single quantile was
requested, since with several they would be ambiguous.


{marker references}{...}
{title:References}

{phang}
Chernozhukov, V., and C. Hansen. 2005. An IV model of quantile treatment
effects. {it:Econometrica} 73(1): 245-261.
{browse "https://doi.org/10.1111/j.1468-0262.2005.00570.x":doi:10.1111/j.1468-0262.2005.00570.x}

{phang}
Chernozhukov, V., and C. Hansen. 2006. Instrumental quantile regression
inference for structural and treatment effect models.
{it:Journal of Econometrics} 132(2): 491-525.
{browse "https://doi.org/10.1016/j.jeconom.2005.02.009":doi:10.1016/j.jeconom.2005.02.009}

{phang}
Galvao, A. F., U. Hounyo, and J. Lin. 2026. GMM for panel data quantile
regression. arXiv:2610.12824 [econ.EM].
{browse "https://doi.org/10.48550/arXiv.2610.12824":doi:10.48550/arXiv.2610.12824}

{phang}
Galvao, A. F., and K. Kato. 2016. Smoothed quantile regression for panel data.
{it:Journal of Econometrics} 193(1): 92-112.
{browse "https://doi.org/10.1016/j.jeconom.2016.01.008":doi:10.1016/j.jeconom.2016.01.008}

{phang}
Galvao, A. F., and C. Lamarche. 2026. A practitioner's guide to panel data
quantile regression. {it:Econometric Reviews} 45(6): 774-799.
{browse "https://doi.org/10.1080/07474938.2026.2642065":doi:10.1080/07474938.2026.2642065}

{phang}
Graham, B. S., J. Hahn, and J. L. Powell. 2009. The incidental parameter
problem in a non-differentiable panel data model.
{it:Economics Letters} 105(2): 181-182.
{browse "https://doi.org/10.1016/j.econlet.2009.07.012":doi:10.1016/j.econlet.2009.07.012}

{phang}
Kaplan, D. M. 2022. Smoothed instrumental variables quantile regression.
{it:Stata Journal} 22(2): 379-403.

{phang}
Kaplan, D. M., and Y. Sun. 2017. Smoothed estimating equations for
instrumental variables quantile regression.
{it:Econometric Theory} 33(1): 105-157.
{browse "https://doi.org/10.1017/S0266466615000407":doi:10.1017/S0266466615000407}

{pstd}
The full reference list, with each item tied to the step of the algorithm it
justifies, is in {help xtpqgmm_methods##refs:xtpqgmm_methods}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please report problems with a reproducible example and the output of
{cmd:xtpqgmm ..., iterlog}.


{title:Also see}

{psee}
Manual: {manlink R ivregress}, {manlink R gmm}, {manlink R qreg}

{psee}
Help: {help xtpqgmm_methods}, {helpb sivqr}, {helpb ivqreg2},
{helpb mmqreg}, {helpb qregfe}, {helpb xtqreg}, {helpb xtmdqr},
{helpb qregplot}
{p_end}
