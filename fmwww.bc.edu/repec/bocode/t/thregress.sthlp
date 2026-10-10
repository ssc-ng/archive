{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "threshkit choose (model/test guide)" "help threshkit_choose"}{...}
{vieweralsosee "[TS] threshold" "mansection TS threshold"}{...}
{viewerjumpto "Syntax" "thregress##syntax"}{...}
{viewerjumpto "Description" "thregress##description"}{...}
{viewerjumpto "Options" "thregress##options"}{...}
{viewerjumpto "Remarks: the model" "thregress##model"}{...}
{viewerjumpto "Remarks: what the theory requires" "thregress##scope"}{...}
{viewerjumpto "Remarks: inference for gamma" "thregress##inference"}{...}
{viewerjumpto "Differences from official threshold" "thregress##diffs"}{...}
{viewerjumpto "Post-estimation" "thregress##postest"}{...}
{viewerjumpto "Examples" "thregress##examples"}{...}
{viewerjumpto "Stored results" "thregress##results"}{...}
{viewerjumpto "References" "thregress##refs"}{...}
{title:Title}

{phang}
{bf:thregress} {hline 2} Threshold regression with an unknown threshold: estimation,
threshold-effect test, and confidence sets for the threshold

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thregress} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth threshvar(varname)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opth threshvar(varname)}}variable that splits the sample{p_end}
{synopt:{opth inv:ariant(varlist)}}regressors whose coefficients do {it:not} switch{p_end}
{synopt:{opt thresh:old(#)}}treat {it:#} as a known threshold; no search{p_end}
{synopt:{opt nocons:tant}}suppress the (switching) constant{p_end}

{syntab:Search}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}search over {it:#} sample quantiles instead of all distinct values{p_end}
{synopt:{opt nthresh(#)}}number of thresholds; default 1{p_end}
{synopt:{opt refine(#)}}refinement sweeps when {cmd:nthresh()} > 1; default 0{p_end}
{synopt:{opt minobs(#)}}minimum observations per regime{p_end}
{synopt:{opt est:imator(left|midpoint)}}point-estimate convention; default {cmd:left}{p_end}

{syntab:SE/Robust}
{synopt:{opt vce(vcetype)}}{opt ols}, {opt r:obust} (= HC0, the default), {opt hc1}, {opt hc2}, {opt hc3}{p_end}

{syntab:Threshold inference}
{synopt:{opt ci(method)}}{opt lr}, {opt lrstar} or {opt none}; see {help thregress##options:Options}{p_end}
{synopt:{opt eta2(method)}}{opt hansen} (default), {opt quadratic} or {opt kernel}{p_end}
{synopt:{opt bw:idth(#)}}bandwidth for {cmd:eta2(kernel)}{p_end}
{synopt:{opt rho(#)}}level of the threshold set used by {cmd:estat twostep}; default {cmd:rho(0.8)}{p_end}
{synopt:{opt het:var}}a separate innovation variance in each regime: the Gaussian criterion, not the total SSR{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Threshold test}
{synopt:{opt test}}also test H0: no threshold effect{p_end}
{synopt:{opt stat(sup|ave|exp)}}test statistic; default {cmd:stat(sup)}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Replication}
{synopt:{opt hansencompat}}reproduce Hansen's published code exactly; see below{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt threshvar()} is required.{p_end}
{p 4 6 2}{it:depvar} and {it:indepvars} may contain time-series and factor-variable operators.{p_end}
{p 4 6 2}{cmd:by} is not supported. Weights are not supported in this release.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thregress} fits the two-regime threshold regression of
{help thregress##refs:Hansen (2000)},

{p 12 12 2}
{it:y_i} = {it:theta_1'x_i} + {it:beta'z_i} + {it:e_i}   if {it:q_i} {c -} {it:gamma}{break}
{it:y_i} = {it:theta_2'x_i} + {it:beta'z_i} + {it:e_i}   if {it:q_i} > {it:gamma}

{pstd}
where {it:q} is the threshold variable named in {opt threshvar()}, {it:x} are the
switching regressors ({it:indepvars}), and {it:z} are optional regime-invariant
regressors ({opt invariant()}). The threshold {it:gamma} is {bf:unknown} and is
estimated by minimising the concentrated sum of squared residuals over the candidate
grid.

{pstd}
The regression is {bf:discontinuous} at {it:gamma}: the level of the fitted function
jumps. For a continuous (kink) threshold use {helpb thkink}; for a self-exciting
threshold in a time series use {helpb thtar}; for an endogenous threshold or
endogenous regressors use {helpb thivreg}.

{pstd}
What {cmd:thregress} adds over official {helpb threshold}: a test of the threshold
effect with a bootstrap p-value, a confidence set for {it:gamma}, heteroskedasticity-
robust inference throughout, two-step slope intervals, regime diagnostics, and the
threshold profile plot. It also runs on cross-sectional data without {helpb tsset}.

{pstd}
{bf:New users should read {helpb threshkit_choose:help threshkit choose} first.} It is
a decision guide for picking the model, the test and the confidence interval, and it
lists the mistakes this literature punishes.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth threshvar(varname)} specifies the variable that splits the sample. It must be
continuously distributed for the asymptotic theory to apply. Required.

{phang}
{opth invariant(varlist)} lists regressors whose coefficients are common to both
regimes. Hansen (2000, p.577) allows this explicitly. Use it when theory says only
part of the relationship changes; it saves degrees of freedom and sharpens the
threshold estimate.

{phang}
{opt threshold(#)} fixes the threshold at {it:#} rather than estimating it. No
confidence set is produced, and the slope inference is the usual OLS inference. Use
this only when the cut-off is known by institution or design.

{phang}
{opt noconstant} suppresses the constant. The constant switches by default, which is
usually what you want: a threshold model in which only slopes change but the
intercept does not is a strong restriction.

{dlgtab:Search}

{phang}
{opt trim(#)} is the fraction of observations excluded at each end of the candidate
grid, so that each regime keeps at least {it:#} of the sample. The default
{cmd:trim(0.15)} follows Hansen's own applications and
{help thregress##refs:Andrews (1993)}. {bf:Report the value you used}: estimates can
move with it. Hansen (2000) Assumption 1.8 requires the threshold to lie in a bounded
interior set, so trimming is required by the theory, not just convenient.

{phang}
{opt gridn(#)} searches {it:#} sample quantiles of {it:q} instead of every distinct
value. Hansen (2000, p.578) defines this approximation for large {it:n}. It is a
speed option: it cannot improve the estimate.

{pmore}
{bf:{it:#} is an upper bound, not the grid size.} The {it:#} quantiles are taken
across the {bf:whole} distribution of {it:q} and the grid is trimmed
{it:afterwards}, so the points falling outside the trimmed interior are dropped
and {cmd:e(n_grid)} comes back {bf:smaller} than {it:#} -- with
{cmd:trim(0.15)} roughly 70% of it, so {cmd:gridn(20)} leaves about 14 or 15
candidates. Read {cmd:e(n_grid)} rather than assuming, and raise {it:#} if the
profile looks ragged. Every command in this package that takes {cmd:gridn()}
behaves this way.

{phang}
{opt nthresh(#)} fits {it:#} thresholds, giving {it:#}+1 regimes. They are found
{it:sequentially}: each stage adds the single grid point that most reduces the SSR
given the thresholds already found, which is the standard device that turns an
infeasible {it:#}-dimensional search into {it:#} one-dimensional ones. The sequential
path is not guaranteed to reach the global minimum, which is what {cmd:refine()}
is for.

{pmore}
Two things change with several thresholds. Each threshold still gets an
inverted-LR interval, but from a {it:conditional} profile that holds the other
thresholds at their estimates, so the interval treats them as known rather than
estimated. And {cmd:test} is a test of no threshold against {it:one}, whatever
{cmd:nthresh()} says; it does not test {it:#} thresholds against fewer. To choose
the number of regimes use {helpb thnregimes} or {helpb thnseq}, which are built for
that question. {cmd:hetvar}, {cmd:estat twostep} and {cmd:estat gridboot} are for a
single threshold only and refuse with an explanation when there are more.

{phang}
{opt refine(#)} runs up to {it:#} refinement sweeps after the sequential search.
A sweep re-optimises each threshold in turn, holding the others fixed, and the
sweeps stop early as soon as one of them moves nothing. This recovers most of the
gap between the sequential path and the joint minimum at a cost of {it:#} times the
single-threshold search, not the {it:#}-dimensional one. {cmd:e(n_moved)} reports
how many times a threshold actually moved, and the output says so: if it is 0 the
sequential path was already a sweep-stable point. The default {cmd:refine(0)} does
no sweeps. Values above 50 are refused.

{phang}
{opt minobs(#)} requires at least {it:#} observations in every regime. The binding
floor is {bf:max(}{it:#}{bf:, k+1)} where {it:k} is the number of switching
regressors, since a regime with fewer observations than coefficients cannot be
fitted at all. It is a second restriction alongside {cmd:trim()}: trimming bounds
the threshold in the {it:distribution} of {it:q}, while this bounds the regime in
{it:counts}, which is the one that matters when {it:q} is discrete or heavily tied.

{phang}
{opt estimator(left|midpoint)} chooses the point-estimate convention. The SSR is a
step function of {it:gamma}, constant between adjacent order statistics, so the
minimiser is an {it:interval}. {cmd:left} (default) reports its left endpoint, as
Hansen does. {cmd:midpoint} reports the midpoint, the estimator of Yu (2012), which
is more efficient under fixed-effect asymptotics. On the shipped growth data the two
give 863 and 871.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} sets the variance estimator for the regime coefficients.
{cmd:vce(robust)} (the default) is {bf:HC0} with no degrees-of-freedom correction,
matching Hansen's reference implementation; {cmd:vce(hc1)}, {cmd:vce(hc2)} and
{cmd:vce(hc3)} are clearly-labelled finite-sample variants. {cmd:vce(ols)} assumes
homoskedasticity and uses the pooled variance.

{phang}
The choice also sets the defaults for {opt ci()} and for the test statistic: with
{cmd:vce(ols)} the homoskedastic sup-F and the LR set; with {cmd:vce(robust)} the
robust sup-LM and the LR* set.

{dlgtab:Threshold inference}

{phang}
{opt ci(method)} selects the confidence set for {it:gamma}.

{phang2}
{cmd:ci(lr)} inverts {it:LR_n(gamma)} = {it:n}[S({it:gamma}) - S({it:gamma}-hat)] /
S({it:gamma}-hat) against {it:c} = -2 ln(1 - sqrt(level)); {it:c} = 7.35 at 95%
(Hansen 2000, Table I). Valid under conditional homoskedasticity.

{phang2}
{cmd:ci(lrstar)} divides the profile by {it:eta}-squared to allow heteroskedasticity
(Hansen 2000, p.584). Default with {cmd:vce(robust)}.

{phang2}
{cmd:ci(none)} skips it.

{phang2}
{bf:Bootstrap confidence intervals for {it:gamma} are refused}, with an error.
{help thregress##refs:Yu (2014)} shows the nonparametric, wild and residual
bootstraps are invalid for {it:gamma}. They remain valid for the {it:test} p-value,
which is a different problem and is what {opt reps()} controls.

{phang}
{opt eta2(method)} selects the estimator of {it:eta}-squared used by
{cmd:ci(lrstar)}. {cmd:hansen} (default) reproduces the author's two-stage plug-in
bandwidth and therefore the published numbers; {cmd:quadratic} fits
{it:r_j} on (1, {it:q}, {it:q}^2) and evaluates at {it:gamma}-hat;
{cmd:kernel} is Nadaraya-Watson with an Epanechnikov kernel and a rule-of-thumb
bandwidth. {bf:These can differ materially} — by a factor of two on the shipped data
— and {it:eta}-squared scales the whole profile, so the confidence set moves with it.
State in your paper which you used.

{phang}
{opt rho(#)} is the level of the threshold confidence set over which
{cmd:estat twostep} takes the union. Hansen (2000, Table III) recommends 0.8.

{dlgtab:Threshold test}

{phang}
{opt test} computes the test of H0: no threshold effect and reports a bootstrap
p-value. Under H0 the threshold is not identified, so the limiting distribution is
not tabulable and the p-value must be simulated (Hansen 1996). The fixed-regressor
bootstrap holds {it:x}, {it:z} and {it:q} fixed and redraws {it:y}.

{phang}
{opt stat(sup|ave|exp)} selects sup (default), ave, or the Andrews-Ploberger exp
statistic. Choose before you look at the output.

{phang}
{opt reps(#)} and {opt seed(#)} control the bootstrap. The Monte Carlo standard error
of the p-value is reported and stored in {cmd:e(p_mcse)}.

{dlgtab:Replication}

{phang}
{opt hansencompat} switches three conventions to those of Hansen's published code
rather than of the paper, so that published results can be reproduced bit for bit:

{phang2}(a) the bootstrap uses the {it:null} (global OLS) residuals instead of the
threshold-fit residuals;{p_end}
{phang2}(b) the estimation grid is untrimmed (the hard guard of at least
{it:k}+2 observations per regime still applies);{p_end}
{phang2}(c) the author's degenerate second-stage bandwidth for {it:eta}-squared.{p_end}

{phang}
On the shipped growth data, (a) alone moves the bootstrap p-value from 0.062 to
0.085.

{marker model}{...}
{title:Remarks: how the threshold is estimated}

{pstd}
For each candidate {it:gamma} the command computes the concentrated sum of squared
residuals S({it:gamma}) by least squares on
[{it:x}, {it:x}{c 183}1{c -(}{it:q} {c -} {it:gamma}{c )-}, {it:z}], and takes the
minimiser over the grid. The grid is the set of {bf:distinct} values of {it:q} inside
the trimmed range: when {it:q} has ties, sorting is not well defined (Hansen 2000,
p.578) and all tied observations must fall in the same regime.

{pstd}
The regime rule uses a {bf:weak} inequality on the lower regime,
1{c -(}{it:q} {c -} {it:gamma}{c )-}. This matters on ties and in small samples; it is
the convention of Hansen (1996, 2000) and of the reference code. Some papers
(Hidalgo, Lee and Seo 2019) write the indicator the other way; that is a sign
convention only.

{pstd}
Least squares here is also the Gaussian maximum likelihood estimator (p.577).

{marker scope}{...}
{title:Remarks: what the theory requires}

{pstd}
Four conditions from Hansen (2000) Assumption 1 decide whether {cmd:thregress} is the
right command. Each has a diagnostic.

{phang}
{bf:1. The regression must jump, not bend.} Assumption 1.7 ({it:c'Dc} > 0, p.580)
{bf:excludes} the continuous-threshold model. If the true model is a kink,
{cmd:thregress} is inconsistent for {it:gamma}. Use {helpb thkink}, and
{cmd:estat continuity} to decide.

{phang}
{bf:2. The error variance may not jump with the regime.} Assumption 1.5 (p.579)
requires E({it:e}^2 | {it:q}) to be continuous at {it:gamma}. If it jumps, the
{it:eta}-squared correction and hence {cmd:ci(lrstar)} are not justified.
{cmd:estat hettest} tests this and warns you.

{phang}
{bf:3. The threshold must lie in the interior.} Assumption 1.8 requires a bounded
proper subset of the support of {it:q}. This is what {opt trim()} delivers. A
threshold estimate at the edge of the trimmed grid is a warning sign, not a result.

{phang}
{bf:4. The asymptotics are for a shrinking effect.} The limit theory assumes
{it:delta_n} = {it:c n}^(-{it:alpha}) with 0 < {it:alpha} < 1/2. Under a fixed, large
effect Theorem 3 says the LR confidence set is conservative, {it:but} only for iid
Gaussian errors independent of ({it:x}, {it:q}); and Donayre, Eo and Morley (2018)
report finite-sample under-coverage when the effect is large. Do not promise
conservative coverage.

{pstd}
The data may be {it:rho}-mixing and stationary, so {cmd:thregress} is legitimate on a
time series. It does not, however, model dynamics: if {it:q} is a lag of {it:y},
use {helpb thtar}.

{marker inference}{...}
{title:Remarks: the confidence set is a set}

{pstd}
The confidence set {c -(}{it:gamma} : {it:LR_n(gamma)} {c -} {it:c}{c )-} need not be
an interval: the profile can cross the critical line more than once. {cmd:thregress}
reports the convex hull, as Hansen does, but {bf:tells you} when the set is not
contiguous and stores every accepted grid point in {cmd:e(ci_set)}. Always look at
{cmd:estat lrplot} before quoting the interval.

{pstd}
Inference on the {it:slopes} treats {it:gamma} as known. That is justified: the slope
estimator is sqrt({it:n})-consistent and asymptotically normal with the same variance
as if {it:gamma} were known (eq. 11, p.585). For intervals that carry the threshold
uncertainty use {cmd:estat twostep}.

{marker hetvar}{...}
{title:When the regimes do not share one variance}

{pstd}
The default criterion minimises the {bf:total} sum of squares. That is the
Gaussian likelihood {it:only} when the two regimes have the same innovation
variance. When they do not, minimising the total sum of squares is not
merely inefficient — it is {bf:biased towards the noisy regime}, because
that regime's observations contribute more squared error at {it:every}
candidate threshold, so the search is pulled towards making it smaller.

{pstd}
{opt hetvar} minimises the actual concentrated Gaussian criterion instead:

{p 8 8 2}
{it:n1} ln({it:s1}^2) + {it:n2} ln({it:s2}^2),{space 3}{it:s_j}^2 = SSR_{it:j} / {it:n_j}

{pstd}
which weights each regime by how much information it carries rather than by
how much noise it has. It is a {bf:different objective} and it generally
gives a {bf:different threshold}.

{pstd}
Whether or not you use it, {cmd:thregress} now always reports
{cmd:e(sigma2_1)} and {cmd:e(sigma2_2)} and a likelihood-ratio statistic
{cmd:e(lr_var)} for the hypothesis that they are equal. Look at that first:
if the variances are close, the two criteria agree and the default is fine;
if they are far apart, the default was answering the wrong question. The
statistic conditions on the estimated threshold, so read it as a description
of how unequal the variances are rather than as a test with exact size.

{pstd}
Two restrictions, both refused with a reason rather than ignored.
{opt hetvar} needs {bf:one} threshold: with several, the Gaussian criterion
carries a variance per regime through the sequential search, and that is not
implemented. And it cannot be combined with {opt invariant()}: with a
separate variance per regime the two regimes are fitted {bf:separately}, and
an invariant regressor is by definition shared, so the model does not
separate.


{marker gridboot}{...}
{title:estat gridboot: a critical value that depends on gamma}

{pstd}
The interval above inverts the {it:LR} statistic against {bf:one} asymptotic
critical value, {bf:-2 ln(1 - sqrt(s))}. Hansen (2000) derives that limit under
{it:shrinking} threshold effects -- the jump is allowed to go to zero as the
sample grows -- and says himself that the finite-sample approximation is poor.
The error is also {bf:not uniform in gamma}, so the interval can be too short
at one end and too long at the other.

{pstd}
{cmd:estat gridboot} replaces the single number by a {bf:function} of
{it:gamma}, estimated by bootstrapping the statistic under the hypothesis that
the threshold {it:is gamma}, and inverts the test pointwise:

{p 8 8 2}
CI = {c -(} {it:gamma} : {it:QLR_n(gamma)} / {it:xi-hat} {ul:<}
{it:F_n}({it:s} | {it:gamma}) {c )-}

{pstd}
At each candidate the procedure refits the model with the design imposed at
that candidate, draws wild-bootstrap errors, {bf:searches the whole grid again},
and takes the {it:s}-quantile of the rescaled statistic. Repeating the search
inside every replication is the point: a bootstrap that held the search fixed
would be answering a different question. Because that is expensive, the
quantile function is estimated at {opt points()} anchors and interpolated
between them, which is what Hidalgo, Lee and Seo do as well.

{pstd}
{bf:It is not a bootstrap for gamma-hat.} Yu (2014) shows that resampling
{it:gamma-hat} and reading off its quantiles is {bf:invalid}, which is why
{cmd:ci(boot)} is refused. Inverting a test whose null fixes {it:gamma} is
valid, and that is what this does.

{pstd}
{bf:Valid under a kink as well as a jump} -- if the threshold variable is one
of the switching regressors. Hidalgo, Lee and Seo (2019) show that the kink
restriction makes {it:gamma-hat} converge at the {bf:cube root} rather than at
rate {it:n}, and yet the QLR statistic keeps the same limit distribution as in
the jump case, up to a single scale factor. One kernel estimator,
{it:xi-hat}, converges to the right factor in each case {bf:without being told
which}, so the interval does not require you to decide first whether the
conditional mean jumps or kinks. {cmd:estat gridboot} reports {it:xi-hat} and
says on its face whether the kink case was nested in what you fitted; if the
threshold variable is {it:not} among the switching regressors it says so and
the interval is the ordinary heteroskedasticity-corrected one.

{pstd}
The rescaled statistic itself is not new here: {cmd:ci(lrstar)} already divides
by the same Nadaraya-Watson ratio. What {cmd:estat gridboot} adds is the
critical value.

{pstd}
Two practical notes. The confidence {bf:set} can have holes, and the command
says so rather than quietly reporting the hull; read {cmd:r(path)}. And
{cmd:estat gridboot} is for a {bf:single} threshold -- with more than one, each
would need its own null with the others held fixed, and the joint confidence
set is not the product of the separate intervals.

{pstd}
Expect it to be slow: {opt points()} times {opt reps()} full threshold searches.
Start with the defaults and raise them once the answer looks stable.

{synoptset 20 tabbed}{...}
{synopthdr:gridboot option}
{synoptline}
{synopt:{opt reps(#)}}bootstrap replications at each anchor; default 199{p_end}
{synopt:{opt po:ints(#)}}anchor points at which the quantile function is
estimated; default 15{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt wild(string)}}{opt rademacher} (default), {opt normal} or
{opt mammen} multipliers{p_end}
{synopt:{opt bw:idth(#)}}bandwidth for {it:xi-hat}; default is
2.344 sd({it:q}) {it:n}^(-1/5){p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt gr:aph}}plot the statistic against both critical values{p_end}
{synopt:{opt sav:ing()}}save that graph{p_end}
{synoptline}

{pstd}
{cmd:estat gridboot} always estimates {it:xi-hat} with the {bf:Epanechnikov}
kernel and the 2.344 sd({it:q}) {it:n}^(-1/5) bandwidth, {bf:whatever}
{opt eta2()} the fit used. Hidalgo, Lee and Seo's Assumption K requires a
kernel whose second moment is non-zero and a bandwidth with {it:a} going to
zero while {it:a}^3 {it:n} grows; Hansen's two-stage plug-in, which is
{cmd:thregress}'s default for {opt eta2()}, is built for a different purpose
and does not carry that guarantee. So {cmd:r(xi)} will generally differ a
little from {cmd:e(eta2)}/{cmd:e(sigma2)} unless the model was fitted with
{cmd:eta2(kernel)}, in which case the two are identical.

{pstd}
Higher-order kernels are deliberately not offered. Hidalgo, Lee and Seo's
Assumption K1 requires the kernel's second moment to be non-zero, and they show
that {it:xi-hat} is {bf:not consistent} with a higher-order kernel -- it
converges to a ratio of second derivatives instead. Epanechnikov is used.

{marker diffs}{...}
{title:Differences from official {help threshold}}

{pstd}
Both commands estimate a threshold by conditional least squares and will agree on the
point estimate under matching options. {cmd:thregress} differs as follows.

{p2colset 4 30 32 2}{...}
{p2col:{bf:official threshold}}{bf:thregress}{p_end}
{p2line}
{p2col:requires {helpb tsset}}no time-series structure needed{p_end}
{p2col:{cmd:trim(10)}, integer percent, symmetric}{cmd:trim(0.15)}, fractions allowed{p_end}
{p2col:constant-only switching by default}all of {it:indepvars} switch by default{p_end}
{p2col:no test for a threshold}{opt test}, bootstrap p-value{p_end}
{p2col:no confidence interval for {it:gamma}}{opt ci(lr)} / {opt ci(lrstar)}{p_end}
{p2col:{cmd:vce(oim|robust)}}{cmd:vce(ols|robust|hc1|hc2|hc3)}{p_end}
{p2col:{cmd:ssrs()} saves the SSR as variables}{cmd:e(profile)} plus {cmd:estat lrplot}{p_end}
{p2col:{cmd:optthresh()} chooses the number by IC}{helpb thselect}: IC {bf:and} bootstrap sequential test{p_end}
{p2colreset}{...}

{pstd}
{cmd:thregress} stores {cmd:e(bic_gp)}, the criterion in the form used by
{cmd:optthresh()} and by Gonzalo and Pitarakis (2002), so the two are comparable.

{marker postest}{...}
{title:Post-estimation}

{pstd}
{helpb predict} and the following {cmd:estat} subcommands are available after
{cmd:thregress} (and after {helpb thtar}, which shares this suite).

{synoptset 24 tabbed}{...}
{p2coldent:{bf:Subcommand}}{bf:What it does}{p_end}
{synoptline}
{syntab:The threshold}
{synopt:{cmd:estat lrplot}}the {it:LR} / {it:LR}* profile with the critical-value line; {cmd:estat profileplot} is a synonym{p_end}
{synopt:{cmd:estat gridboot}}a critical value that depends on {it:gamma}; see {help thregress##gridboot:below}{p_end}
{synopt:{cmd:estat twostep}}slope intervals that carry the uncertainty about {it:gamma}{p_end}

{syntab:The regimes}
{synopt:{cmd:estat regimes}}regime-by-regime summary{p_end}
{synopt:{cmd:estat regimeplot}}the data and the fitted regime lines against {it:q}{p_end}
{synopt:{cmd:estat table}}a publication-ready regime comparison table{p_end}
{synopt:{cmd:estat eqtest}}Wald tests that a coefficient is the {it:same} in every regime; {cmd:estat equality} is a synonym{p_end}

{syntab:Residual diagnostics}
{synopt:{cmd:estat hettest}}heteroskedasticity, including dependence on the regime{p_end}
{synopt:{cmd:estat serial}}no error autocorrelation, against the regime design{p_end}
{synopt:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{synopt:{cmd:estat mcleodli}}McLeod-Li portmanteau on the squared residuals{p_end}
{synopt:{cmd:estat normality}}Jarque-Bera, with its skewness and kurtosis components{p_end}
{synopt:{cmd:estat diag}}all four of the above in one table{p_end}

{syntab:Standard errors, dynamics}
{synopt:{cmd:estat hac}}Newey-West HAC standard errors for the regime coefficients{p_end}
{synopt:{cmd:estat skeleton}}the deterministic skeleton: stability, limit cycles, half-lives; {cmd:estat skel} is a synonym{p_end}
{synopt:{cmd:estat girf}}generalised impulse response ({helpb thtar} only){p_end}
{synoptline}
{p2colreset}{...}

{marker eqtest}{...}
{pstd}
{bf:estat eqtest} reports Chow-type Wald tests that a single coefficient, or the
whole coefficient vector, takes the same value in every regime. {opt nojoint}
suppresses the joint test and reports only the coefficient-by-coefficient ones.

{pstd}
{bf:Read the caveat.} This conditions on {it:gamma}-hat. Under the null of
{it:no} threshold the threshold is not identified, so the statistic does
{bf:not} have a chi-squared distribution and a small p-value here is {bf:not}
evidence against linearity. The test for that is {helpb thtest}, or
{cmd:thregress, test}, which bootstraps the sup over the whole grid. What
{cmd:eqtest} is good for is the different and often more interesting question:
{it:given} that a threshold exists, which coefficients actually move across it.
The coefficient table answers that informally, one regime at a time, with no
joint test.

{marker resdiag}{...}
{pstd}
{bf:The residual diagnostics} all test the fitted residuals against the
{bf:regime-split design} -- the same columns the estimator used -- rather than
against the unsplit regressors, so they ask whether anything is left over
{it:after} the threshold has been accounted for. A rejection from
{cmd:estat serial} on a cross-section usually means the observations are
ordered on something that matters; on a time series it means the lag structure
is short, and {cmd:estat hac} is then the minimum response.

{marker hac}{...}
{pstd}
{bf:estat hac} gives heteroskedasticity- and autocorrelation-consistent standard
errors for the regime coefficients, conditional on the estimated threshold
({help thregress##refs:Newey and West 1987}; {help thregress##refs:Andrews 1991}).
The kernel is Bartlett. {opt lags(#)} fixes the truncation lag; left out, it comes
from {opt rule(neweywest|andrews)}. {cmd:neweywest} (the default) is the plug-in
{it:L} = floor(4({it:n}/100)^(2/9)): fast, reproducible and completely blind to
the data, and it is what most software uses and what a reader expects.
{cmd:andrews} fits an AR(1) to each score series and chooses {it:L} from the
estimated persistence; it adapts, and it is the better choice when the serial
correlation is strong, but it is not what a reader assumes on seeing
"Newey-West". Either way the bandwidth is {bf:reported}, because a HAC standard
error without its bandwidth is not reproducible and the number changes the
answer. {opt nodfadj} drops the small-sample degrees-of-freedom adjustment.

{pstd}
Why it is here: the package's {opt vce(robust)} is HC, which lets the error
variance differ across observations but assumes they are {bf:uncorrelated}. On a
time series that is usually wrong, and threshold models are fitted to time series
more often than not. Serially correlated errors leave the coefficients consistent
and make the HC standard errors {bf:too small} -- often badly so, and always in
the direction that makes a result look stronger than it is.

{pstd}
{bf:What it does not fix.} These are the standard errors of the {it:slopes}
conditional on {it:gamma}-hat, and they carry no uncertainty about the threshold.
A HAC standard error is not a licence to treat the threshold as known; it only
stops the slope's standard error being wrong for a second, separate reason. For
the threshold use {cmd:estat gridboot}; for slope intervals that do not condition
on {it:gamma}-hat use {cmd:estat twostep}.

{marker skeleton}{...}
{pstd}
{bf:estat skeleton} iterates the fitted model with the errors set to zero and
reports three things. First, the companion eigenvalues of each regime. A modulus
of 1 or more means that regime is {bf:locally explosive}, and that is {bf:not} a
defect of the fit: a threshold model can be globally stationary with an explosive
inner regime, because the system is thrown out of it before it can run away.
Second, the skeleton's long-run behaviour. A {bf:fixed point} means the
deterministic model converges; a {bf:limit cycle} of period {it:k} means it
settles into {it:k} repeating values and never converges, which was Tong's whole
point -- a linear model cannot do it. Third, the half-life of a shock, measured
from each regime separately: in a linear model that is one number, in a threshold
model it is not, and the difference between regimes is usually the economically
interesting quantity. {opt horizon(#)}, {opt tolerance(#)} and {opt maxcycle(#)}
control the iteration.

{pstd}
The skeleton is {bf:not a forecast}. Clements and Smith (1997) show the
deterministic path differs from E[{it:y_t+h}] for a nonlinear model and that the
gap does not shrink with the sample. For forecasts use {helpb thforecast}.

{marker examples}{...}
{title:Examples}

{pstd}The shipped data are the Durlauf-Johnson (1995) cross-country growth data as
used by Hansen (2000). {cmd:q} is 1960 per-capita GDP in levels.{p_end}

{phang2}{cmd:. use threshkit_dj}{p_end}

{pstd}Fit the model, test for a threshold, and get the confidence set:{p_end}

{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q) test}{p_end}

{pstd}Reproduce the published numbers exactly (gamma = 863, 95% set [594, 1794],
p = 0.088 up to Monte Carlo error):{p_end}

{phang2}{cmd:. set seed 20261001}{p_end}
{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q) test hansencompat}{p_end}

{pstd}Look at the profile before trusting the interval:{p_end}

{phang2}{cmd:. estat lrplot}{p_end}

{pstd}Check the assumption that the LR* interval depends on:{p_end}

{phang2}{cmd:. estat hettest}{p_end}

{pstd}Regime summary, publication table, and intervals that carry the threshold
uncertainty:{p_end}

{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat table}{p_end}
{phang2}{cmd:. estat twostep}{p_end}

{pstd}A critical value that depends on the candidate threshold, and that is
valid whether the conditional mean jumps or kinks at it:{p_end}

{phang2}{cmd:. estat gridboot, reps(199) points(15) seed(1)}{p_end}
{phang2}{cmd:. estat gridboot, reps(199) points(15) seed(1) graph}{p_end}

{pstd}
Compare the two intervals it prints. If they disagree materially, prefer the
bootstrap one: the asymptotic critical value is a single number for every
{it:gamma} and its error is known not to be uniform in {it:gamma}.{p_end}

{pstd}Is literacy a better threshold variable than income? Compare the p-values,
and report both (Hansen 2000, p.587):{p_end}

{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(lit) test}{p_end}

{pstd}Only the slopes switch; the constant is common:{p_end}

{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q) invariant(sch) test}{p_end}

{pstd}A second split inside the upper regime (Hansen's sequential procedure):{p_end}

{phang2}{cmd:. thregress diff gdp60 iony pgro sch if q > 863, threshvar(lit) test}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:thregress} is {it:eclass}. It stores{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(gamma)}}threshold estimate{p_end}
{synopt:{cmd:e(gamma_lo)}, {cmd:e(gamma_hi)}}convex hull of the confidence set{p_end}
{synopt:{cmd:e(ci_contiguous)}}1 if the confidence set is an interval, 0 if not{p_end}
{synopt:{cmd:e(ci_npoints)}}number of accepted grid points{p_end}
{synopt:{cmd:e(cv)}}critical value {it:c}{p_end}
{synopt:{cmd:e(eta2)}}{it:eta}-squared{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}observations per regime{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(ssr0)}}SSR of the threshold model and of the pooled model{p_end}
{synopt:{cmd:e(ssr1)}, {cmd:e(ssr2)}}SSR by regime{p_end}
{synopt:{cmd:e(sigma2)}, {cmd:e(rmse)}}residual variance (divisor {it:n}) and root MSE{p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_0)}}R-squared of the threshold model and of the pooled model{p_end}
{synopt:{cmd:e(het_p_global)}, {cmd:e(het_p_thresh)}}heteroskedasticity test p-values{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(hqic)}}log likelihood and information criteria{p_end}
{synopt:{cmd:e(bic_gp)}}BIC in the Gonzalo-Pitarakis / {cmd:optthresh()} form{p_end}
{synopt:{cmd:e(trim)}, {cmd:e(rho)}, {cmd:e(level)}}option values in force{p_end}
{synopt:{cmd:e(n_grid)}, {cmd:e(grid_skipped)}}grid points searched and skipped{p_end}
{synopt:{cmd:e(stat)}, {cmd:e(p)}, {cmd:e(p_mcse)}}test statistic, bootstrap p-value, its MC s.e.{p_end}
{synopt:{cmd:e(supf)}, {cmd:e(suplm)}}homoskedastic and robust statistics{p_end}
{synopt:{cmd:e(gamma_test)}}grid point maximising the test statistic{p_end}
{synopt:{cmd:e(boot_reps)}}bootstrap replications{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thregress}{p_end}
{synopt:{cmd:e(threshold_var)}}name of the threshold variable{p_end}
{synopt:{cmd:e(model)}}{cmd:jump}{p_end}
{synopt:{cmd:e(ci_method)}, {cmd:e(eta2_method)}, {cmd:e(point_est)}}conventions in force{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcelab)}}variance estimator{p_end}
{synopt:{cmd:e(boot)}, {cmd:e(boot_resid)}}bootstrap scheme and which residuals{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and variance, in equations {cmd:Region1}, {cmd:Region2} and {cmd:Invariant}{p_end}
{synopt:{cmd:e(profile)}}grid by 4: {it:gamma}, SSR, LR, LR*{p_end}
{synopt:{cmd:e(ci_set)}}every accepted grid point{p_end}
{synopt:{cmd:e(twostep1)}, {cmd:e(twostep2)}}two-step slope intervals by regime{p_end}
{synopt:{cmd:e(bdist)}}bootstrap distribution of the test statistic{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}
{p2colreset}{...}

{marker valid}{...}
{title:Validation}

{pstd}
Every number this command produces on the shipped data has been checked against
Bruce Hansen's own R, GAUSS, MATLAB and Stata code and against the printed article:
{it:gamma}-hat = 863, 95% set [594, 1794], 18 and 78 observations by regime,
SSR = 8.024881, {it:eta}-squared = 0.0750938, sup-LM = 12.60184 at 833, and all
regime coefficients and HC0 standard errors. The lock file is
{bf:validation/thregress/reference_lock.yml} and the equation-by-equation
correspondence with the paper is {bf:validation/thregress/equation_map.md}.

{pstd}
{cmd:thregress} is a clean-room implementation: the algorithm was taken from the
published papers, not from any reference implementation's source. See
{bf:_knowledge/provenance.tsv}.

{pstd}
{cmd:estat gridboot} returns {cmd:r(gamma)}, {cmd:r(xi)}, {cmd:r(lo)},
{cmd:r(hi)}, {cmd:r(contiguous)}, the asymptotic counterparts
{cmd:r(lo_asym)}, {cmd:r(hi_asym)}, {cmd:r(contiguous_asym)} and
{cmd:r(cv_asym)}, the dimensions {cmd:r(N)}, {cmd:r(n_grid)},
{cmd:r(n_anchor)}, {cmd:r(reps)}, {cmd:r(level)}, the flag
{cmd:r(kink_nested)}, the macro {cmd:r(wild)}, the matrix {cmd:r(path)} with
one row per grid point holding {it:gamma}, the rescaled statistic, the
interpolated bootstrap critical value and an accept indicator, and
{cmd:r(anchors)} holding the quantile actually bootstrapped at each anchor.

{marker refs}{...}
{title:References}


{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica} 59: 817-858.
{browse "https://doi.org/10.2307/2938229":doi:10.2307/2938229}.

{phang}
Andrews, D. W. K. 1993. Tests for parameter instability and structural change with
unknown change point. {it:Econometrica} 61: 821-856.
{browse "https://doi.org/10.2307/2951764":doi:10.2307/2951764}.

{phang}
Chan, K. S., and H. Tong. 1986. On estimating thresholds in autoregressive
models. {it:Journal of Time Series Analysis} 7: 179-190.
{browse "https://doi.org/10.1111/j.1467-9892.1986.tb00501.x":doi:10.1111/j.1467-9892.1986.tb00501.x}.

{phang}
Clements, M. P., and J. Smith. 1997. The performance of alternative
forecasting methods for SETAR models. {it:International Journal of
Forecasting} 13: 463-475.
{browse "https://doi.org/10.1016/S0169-2070(97)00017-4":doi:10.1016/S0169-2070(97)00017-4}.

{phang}
Donayre, L., Y. Eo, and J. Morley. 2018. Improving likelihood-ratio-based confidence
intervals for threshold parameters in finite samples. {it:Studies in Nonlinear
Dynamics & Econometrics} 22: 20160084.
{browse "https://doi.org/10.1515/snde-2016-0084":doi:10.1515/snde-2016-0084}.

{phang}
Durlauf, S. N., and P. A. Johnson. 1995. Multiple regimes and cross-country growth
behaviour. {it:Journal of Applied Econometrics} 10: 365-384.
{browse "https://doi.org/10.1002/jae.3950100404":doi:10.1002/jae.3950100404}.

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based inference
in single and multiple threshold models. {it:Journal of Econometrics} 110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under the
null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 1999. The grid bootstrap and the autoregressive model.
{it:Review of Economics and Statistics} 81: 594-607.
{browse "https://doi.org/10.1162/003465399558463":doi:10.1162/003465399558463}.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation. {it:Econometrica} 68:
575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}.

{phang}
Hansen, B. E. 2017. Regression kink with an unknown threshold.
{it:Journal of Business and Economic Statistics} 35: 228-240.
{browse "https://doi.org/10.1080/07350015.2015.1073595":doi:10.1080/07350015.2015.1073595}.

{phang}
Hidalgo, J., J. Lee, and M. H. Seo. 2019. Robust inference for threshold regression
models. {it:Journal of Econometrics} 210: 291-309.
{browse "https://doi.org/10.1016/j.jeconom.2019.01.008":doi:10.1016/j.jeconom.2019.01.008}.

{phang}
Newey, W. K., and K. D. West. 1987. A simple, positive semi-definite,
heteroskedasticity and autocorrelation consistent covariance matrix.
{it:Econometrica} 55: 703-708.
{browse "https://doi.org/10.2307/1913610":doi:10.2307/1913610}.

{phang}
Tong, H., and K. S. Lim. 1980. Threshold autoregression, limit cycles and
cyclical data. {it:Journal of the Royal Statistical Society B} 42: 245-292.
{browse "https://doi.org/10.1111/j.2517-6161.1980.tb01126.x":doi:10.1111/j.2517-6161.1980.tb01126.x}.

{phang}
Yu, P. 2014. The bootstrap in threshold regression. {it:Econometric Theory} 30:
676-714.
{browse "https://doi.org/10.1017/S0266466614000012":doi:10.1017/S0266466614000012}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Manual:  {manlink TS threshold}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thkink}, {helpb thtar},
{helpb thtest}, {helpb thselect}, {helpb thnregimes}, {helpb thivreg},
{helpb thendog}, {helpb thexport} (publication tables from this fit),
{helpb thsim} (simulate from this model), {helpb threshold}, {helpb mswitch}
{p_end}
