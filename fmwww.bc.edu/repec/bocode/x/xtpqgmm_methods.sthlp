{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "xtpqgmm" "help xtpqgmm"}{...}
{viewerjumpto "The model" "xtpqgmm_methods##model"}{...}
{viewerjumpto "Identification" "xtpqgmm_methods##ident"}{...}
{viewerjumpto "What beta means" "xtpqgmm_methods##interp"}{...}
{viewerjumpto "Smoothing" "xtpqgmm_methods##smooth"}{...}
{viewerjumpto "The kernel" "xtpqgmm_methods##kernel"}{...}
{viewerjumpto "Profiling out the fixed effects" "xtpqgmm_methods##profile"}{...}
{viewerjumpto "Multiple roots" "xtpqgmm_methods##roots"}{...}
{viewerjumpto "The GMM steps" "xtpqgmm_methods##gmm"}{...}
{viewerjumpto "Bandwidth" "xtpqgmm_methods##bw"}{...}
{viewerjumpto "The optimiser" "xtpqgmm_methods##optim"}{...}
{viewerjumpto "Inference" "xtpqgmm_methods##inference"}{...}
{viewerjumpto "Uniform inference" "xtpqgmm_methods##uniform"}{...}
{viewerjumpto "The n/T condition" "xtpqgmm_methods##nT"}{...}
{viewerjumpto "Assumptions" "xtpqgmm_methods##assume"}{...}
{viewerjumpto "Limitations" "xtpqgmm_methods##limits"}{...}
{viewerjumpto "Step-to-equation map" "xtpqgmm_methods##map"}{...}
{viewerjumpto "References" "xtpqgmm_methods##refs"}{...}

{p2colset 1 24 26 2}{...}
{p2col:{bf:xtpqgmm_methods} {hline 2}}Methods and formulas for
{helpb xtpqgmm}{p_end}
{p2colreset}{...}

{pstd}
This page is written to be read next to the source paper:

{pmore}
Galvao, A. F., U. Hounyo, and J. Lin. 2026. GMM for panel data quantile
regression. arXiv:2610.12824 [econ.EM].
{browse "https://doi.org/10.48550/arXiv.2610.12824":doi:10.48550/arXiv.2610.12824}

{pstd}
Every equation number below is the paper's own. Where {helpb xtpqgmm}
departs from the paper, or where the paper leaves a choice open, this page
says so explicitly rather than quietly picking one. The paper labels the
estimators {bf:SP-GMM} (smoothed panel GMM) and {bf:SP-MM} (the exactly
identified method-of-moments version).


{marker model}{...}
{title:The model}

{pstd}
For a fixed quantile index {it:tau} in (0,1), unit {it:i} = 1,...,{it:n} and
period {it:t} = 1,...,{it:T}:

{p 8 8 2}
{it:y(i,t)} is the outcome;{break}
{it:x(i,t)} is a {it:d}-vector of explanatory variables, {bf:possibly
endogenous};{break}
{it:z(i,t)} is a {it:dz}-vector of instruments, {it:dz} {ul:>} {it:d};{break}
{it:alpha(i)} is a scalar fixed effect, which {bf:may depend on tau}.

{pstd}
The structural residual is

{p 8 8 2}
{it:u(i,t)}({it:alpha}, {it:beta}) = {it:y(i,t)} {c -} {it:alpha} {c -}
{it:x(i,t)}'{it:beta}

{pstd}
and the population parameter is defined by the conditional quantile
restriction

{p 8 8 2}
{bf:(1)}{col 14}{it:Q}({it:tau})[ {it:u(i,t)}({it:alpha(i)},{it:beta}) {c |}
{it:z(i,t)}, {it:alpha(i)} ] = 0,

{pstd}
equivalently {it:E}[ 1{c -(}{it:y(i,t)} {ul:<} {it:alpha(i)} +
{it:x(i,t)}'{it:beta}{c )-} {c -} {it:tau} {c |} {it:z(i,t)},
{it:alpha(i)} ] = 0.

{pstd}
Note what {it:alpha(i)} is and is not. It is {bf:not} a dummy variable in the
regression: it is a nuisance parameter, one per unit, carrying the intercept,
and it is allowed to differ across quantiles. Koenker (2004), by contrast,
forces the individual intercepts to be common across quantiles. Because the
quantile restriction is non-linear in the distribution of the data, the fixed
effects {bf:cannot} be removed by differencing the way they can in a linear
mean model. That single fact is why this estimator exists.

{pstd}
The instrument vector {it:z(i,t)} may contain the exogenous components of
{it:x(i,t)}, excluded instruments, transformations and lags. It must {bf:not}
contain unit dummies: the fixed effects are handled by the profiling step
instead.


{marker ident}{...}
{title:Identification}

{pstd}
The conditional restriction (1) implies two sets of unconditional ones. First,
for each unit,

{p 8 8 2}
{bf:(2)}{col 14}{it:E}[ 1{c -(}{it:y(i,t)} {ul:<} {it:alpha(i)} +
{it:x(i,t)}'{it:beta}{c )-} {c -} {it:tau} ] = 0,

{pstd}
which pins down the fixed effect given {it:beta}. Second,

{p 8 8 2}
{bf:(3)}{col 14}{it:E}[ {it:z(i,t)} ( 1{c -(}{it:y(i,t)} {ul:<}
{it:alpha(i)} + {it:x(i,t)}'{it:beta}{c )-} {c -} {it:tau} ) ] = 0,

{pstd}
which identifies the common parameter. {cmd:xtpqgmm} uses exactly these two:
the scalar restrictions (2) profile out the fixed effects, and the vector
restrictions (3) are what GMM weights.

{pstd}
The logic of identification is therefore: for each candidate {it:beta}, let
each {it:alpha(i)} adjust so that (2) holds for that unit; then {it:beta} is
identified from whatever is left in (3). Global identification in a general
IVQR setting is hard; the paper leans on Chernozhukov and Hansen (2005,
Theorem 2 and Appendix C) and imposes it as Assumption (A5).


{marker interp}{...}
{title:What beta means}

{pstd}
This is the part most easily got wrong, and the paper is careful about it.

{pstd}
The estimator and all of its asymptotic theory are built on the
{bf:unconditional} moment restrictions (2) and (3), not on the conditional
restriction (1). Two consequences:

{p 4 7 2}
1. {bf:If} the structural IVQR conditions of Chernozhukov and Hansen (2005)
hold -- in particular a latent-rank representation monotone in the rank --
then {it:beta} is a {bf:structural quantile response parameter}, and you may
read it causally: the effect of {it:x} on the {it:tau}-th structural quantile
of {it:y}.

{p 4 7 2}
2. {bf:If} the conditional quantile model is misspecified but the
unconditional moments remain correctly specified, the estimator still
converges -- to the parameter those moments identify. Relative to the
misspecified conditional model this is a {bf:pseudo-true parameter}, in the
sense of Angrist, Chernozhukov and Fernandez-Val (2006). It need not have any
causal reading.

{pstd}
{cmd:xtpqgmm} cannot tell which case you are in, and neither can the data. The
distinction belongs in your write-up.


{marker smooth}{...}
{title:Smoothing}

{pstd}
The sample analogue of (3) is discontinuous in ({it:alpha},{it:beta}) because
of the indicator, which makes direct GMM minimisation ill-behaved -- see
Chernozhukov and Hong (2003, Figure 1(a) and Example 3, p. 297). The paper
replaces the indicator with a smooth approximation.

{pstd}
Let {it:K} be a kernel with integral one and
{it:G}({it:w}) = {it:integral from -infinity to w} of {it:K}, and write
{it:G_h}({it:w}) = {it:G}({it:w}/{it:h}). Since

{p 8 8 2}
{it:G_h}( {c -}({it:y(i,t)} {c -} {it:alpha} {c -} {it:x(i,t)}'{it:beta}) )
= {it:G}( ({it:alpha} + {it:x(i,t)}'{it:beta} {c -} {it:y(i,t)})/{it:h} ),

{pstd}
this is a smooth stand-in for the indicator. The smoothed moment, equation
(7), is

{p 8 8 2}
{bf:(7)}{col 14}{it:H_n}({it:alpha},{it:beta}) =
(1/{it:nT}) {it:sum over i,t} {it:z(i,t)}
[ {it:G_h}(...) {c -} {it:tau} ].

{pstd}
Smoothing buys two things: moments that are differentiable, so numerical
optimisation is stable; and Taylor expansions in the proofs, so the effect of
estimating the fixed effects can be controlled. The same device appears in
Horowitz (1998), Galvao and Kato (2016) and Kaplan and Sun (2017).


{marker kernel}{...}
{title:The kernel}

{pstd}
{cmd:xtpqgmm} uses the paper's kernel and only that one:

{p 8 8 2}
{it:K}({it:w}) = (105/64)(1 {c -} 5{it:w}^2 + 7{it:w}^4 {c -} 3{it:w}^6)
{c |} {it:w} {c |} {ul:<} 1,

{pstd}
which is of order {bf:r = 4}. Integrating and fixing {it:G}({c -}1) = 0,

{p 8 8 2}
{it:G}({it:w}) = 1/2 + (105/64)( {it:w} {c -} (5/3){it:w}^3 +
(7/5){it:w}^5 {c -} (3/7){it:w}^7 ){break}
{col 13}= 1/2 + (1/64)( 105{it:w} {c -} 175{it:w}^3 + 147{it:w}^5 {c -}
45{it:w}^7 )

{pstd}
on [{c -}1,1], with {it:G} = 0 below and 1 above. These were verified
numerically: the integral of {it:K} is 1 and its first, second and third
moments are 0, while the fourth is {c -}0.0303, confirming {it:r} = 4
exactly; and {it:G}({c -}1) = 0, {it:G}(0) = 0.5, {it:G}(1) = 1 to machine
precision.

{pstd}
{bf:Two properties of this kernel that matter in practice.}

{p 4 7 2}
{bf:It is not non-negative.} Writing {it:w}^2 = {it:s},
1 {c -} 5{it:s} + 7{it:s}^2 {c -} 3{it:s}^3 =
{c -}3({it:s}{c -}1)^2({it:s} {c -} 1/3), so {it:K} {ul:>} 0 exactly when
{c |}{it:w}{c |} {ul:<} 1/sqrt(3) = 0.5774. The paper notes that
non-negativity is not required for a higher-order kernel; the consequence for
the code is in {help xtpqgmm_methods##roots:Multiple roots}.

{p 4 7 2}
{bf:{it:G} is not confined to [0,1].} It turns where {it:K} changes sign, so
its extremes are {it:G}({c -}1/sqrt(3)) = {c -}0.053294 and
{it:G}(+1/sqrt(3)) = 1.053294 -- an overshoot of about 0.053 at each end. The
smoothed indicator is therefore {bf:not a probability}, and nothing derived
from it should be reported as one.

{pstd}
A second-order kernel is not offered. It would violate the requirement
{it:r} {ul:>} 4 behind Assumptions (A6) and (A8) and the bandwidth rate (A9),
and it is not a cosmetic change: switching from the integrated uniform kernel
to this one moves estimates in the {bf:third} decimal in our tests.


{marker profile}{...}
{title:Profiling out the fixed effects}

{pstd}
For each unit and each candidate {it:beta}, {cmd:xtpqgmm} solves the smoothed
version of (2), the paper's equation (8):

{p 8 8 2}
{bf:(8)}{col 14}{it:A_i}({it:alpha},{it:beta}) =
(1/{it:T}) {it:sum over t} [ {it:G_h}(
({it:alpha} + {it:x(i,t)}'{it:beta} {c -} {it:y(i,t)})/{it:h} ) {c -}
{it:tau} ] = 0

{pstd}
and substitutes the solution {it:alpha_i}({it:beta}) into (7). The outer
problem is then over {it:beta} alone: {it:n} + {it:d} parameters with {it:n}
constraints become {it:d} parameters. The resulting profiled moment is

{p 8 8 2}
{bf:(13)}{col 14}{it:m_n}({it:beta}) =
{it:H_n}({it:alpha}({it:beta}), {it:beta}).

{pstd}
{bf:Why this and not stacked GMM.} One could instead stack the {it:n} unit
restrictions together with the {it:dz} instrument moments in a single
criterion. With {it:dz} > {it:d} that trades off the unit restrictions against
the instrument moments, so some units end up with {it:A_i} not equal to zero.
Profiling instead {bf:imposes the unit restrictions exactly} for every
candidate {it:beta}, and applies GMM weighting only to the instrument moments.
In the over-identified case that is a substantive part of the estimator's
definition, not a computational convenience.

{pstd}
{bf:How the inner solve is done.} {it:A_i} is bounded: it tends to
{c -}{it:tau} as {it:alpha} falls and to 1{c -}{it:tau} as it rises, so a root
always exists for {it:tau} in (0,1). {cmd:xtpqgmm} starts from the
{bf:unsmoothed} {it:tau}-quantile of the residual {it:y} {c -} {it:x}'{it:beta},
expands a bracket until the sign changes, then runs a safeguarded Newton step
using the analytic derivative

{p 8 8 2}
{it:A_i}'({it:alpha}) = (1/{it:T}) {it:sum over t} {it:K_h}(...) / {it:h},

{pstd}
falling back to bisection whenever the Newton step would leave the bracket or
the kernel average is not positive. Each iteration costs {it:O}({it:T}) and
convergence takes about twenty iterations. The largest
{c |}{it:A_i}{c |} at the solution is returned in {cmd:e(maxA)}; it should be
at machine-precision level.

{pstd}
In an unbalanced panel each unit's own {it:T(i)} is used in (8).


{marker roots}{...}
{title:Multiple roots}

{pstd}
Because {it:K} takes negative values, {it:G} is monotone only on
{c |}{it:w}{c |} {ul:<} 1/sqrt(3), so {it:A_i}(.,{it:beta}) need {bf:not} be
monotone and equation (8) can have more than one root. The paper flags this
on p. 15: the sample root correspondence may contain several points in finite
samples.

{pstd}
The paper's own tie-break is to minimise the GMM criterion over the
combinations of roots and then take the lexicographically smallest vector.
With {it:n} units that is 2^{it:n} combinations, which the paper itself calls
potentially costly. {cmd:xtpqgmm} instead:

{p 4 7 2}
{bf:(a)} brackets from the unsmoothed quantile and takes the root nearest it;

{p 4 7 2}
{bf:(b)} counts, once at the solution, how many units have more than one root,
and reports that count in {cmd:e(n_multiroot)} and in the footer.

{pstd}
This is a documented deviation, not an equivalence. In every design we have
tested the count was zero or one root per unit, and the profiled criterion was
locally linear through the root with a healthy slope -- consistent with
Lemma A.4, which asserts the sample profile is locally unique and
differentiable near {it:beta}(0). But a non-zero {cmd:e(n_multiroot)} is a
signal to check sensitivity to {cmd:bandwidth()}: a larger {it:h} smooths more
and makes extra roots more likely, since more observations fall in the region
where {it:K} < 0.

{pstd}
{cmd:e(n_profilefail)} counts unit-evaluations where no root could be
bracketed at all. It should be zero. Any other value means the estimates rest
on a fallback and should not be reported without investigation.


{marker gmm}{...}
{title:The GMM steps}

{pstd}
{bf:SP-MM, equation (9).} Exactly identified. Solve (8) for every unit and
{it:H_n} = 0 for {it:beta} simultaneously. When {it:dz} > {it:d} there is no
exact solution, so {cmd:xtpqgmm} uses the {it:d} within-projection
combinations of the instruments. SP-MM is cheap, well behaved, and is always
computed first as the starting value; it is returned in {cmd:e(b_mm)}. The
paper recommends exactly this, because the GMM criterion may be non-convex and
initialisation matters.

{pstd}
{bf:One-step SP-GMM, equation (10).} Minimise
{it:m_n}({it:beta})'{it:W} {it:m_n}({it:beta}) with {it:W} = {it:I}, subject to
{it:A_i} = 0 for every unit.

{pstd}
{bf:Two-step SP-GMM, equation (11), the default.} Re-minimise with
{it:W} = {it:Omega}-hat^{c -}1, where {it:Omega}-hat is the estimated long-run
variance of the profiled moment evaluated at the one-step estimate. "Two-step"
refers to {bf:updating the weighting matrix}, not to a first-stage
transformation of the data. With {it:W} = {it:Omega}^{c -}1 the asymptotic
variance collapses to ({it:D}'{it:Omega}^{c -}1{it:D})^{c -}1.


{marker bw}{...}
{title:Bandwidth}

{pstd}
Assumption (A9) requires {it:h} proportional to {it:T}^({c -}{it:c}) with
1/{it:r} < {it:c} < 1/3. With {it:r} = 4 that is 0.25 < {it:c} < 0.3333. The
rule used in the paper's simulations and application, and the default here,
takes {it:c} = 2/7 = 0.2857 -- inside the range, with 0.036 of slack above
the lower bound:

{p 8 8 2}
{it:h} = {it:c}({it:tau}) {it:T}^({c -}2/7),{break}
{it:c}({it:tau}) = [ 4.5 {it:phi}({it:Phi}^{c -}1({it:tau}))^4 /
(2{it:Phi}^{c -}1({it:tau})^2 + 1)^2 ]^(1/5),

{pstd}
the normal-reference constant familiar from quantile regression bandwidth
selection, with {it:T} the average observations per unit. Representative
values: {it:c}(0.5) = 0.6477, {it:c}(0.25) = {it:c}(0.75) = 0.4168,
{it:c}(0.1) = {it:c}(0.9) = 0.1876.

{pstd}
{bf:This is a rate-admissible rule, not an optimal one.} The paper names
bandwidth choice as an open question for future research. The MSE-optimal
plug-in of Kaplan and Sun (2017) is a different object and is {bf:not} what
{helpb sivqr} and {cmd:xtpqgmm} have in common -- {helpb sivqr} uses the
Kaplan-Sun plug-in, {cmd:xtpqgmm} uses the rule above. Comparing the two
commands therefore requires passing the same {cmd:bandwidth()} to both.

{pstd}
Treat {cmd:bandwidth()} as a sensitivity dimension and report a range.


{marker optim}{...}
{title:The optimiser}

{pstd}
{bf:A deliberate deviation from the paper.} The paper's implementation
minimises the constrained GMM criterion with simulated annealing, via R's
{cmd:GenSA} package (Xiang et al. 2013), initialised at the SP-MM estimate,
because the criterion may be non-convex.

{pstd}
{bf:Mata has no simulated annealing.} {cmd:xtpqgmm} therefore uses a
Gauss-Newton step on the profiled moment from the SP-MM start, with a
Nelder-Mead polish (Mata's {helpb mf_optimize:optimize()} with the {cmd:nm}
technique) taken whenever Gauss-Newton fails to converge or Nelder-Mead
attains a lower criterion value. {opt nonmfallback} turns the polish off.

{pstd}
This is deterministic, so results replicate exactly, which simulated annealing
would not. It is {bf:not} the paper's optimiser, and on a badly non-convex
surface it could in principle find a different local minimum. Two practical
safeguards: the SP-MM start is the same one the paper recommends, and
{cmd:e(gnorm)} and {cmd:e(mnorm)} let you confirm the moment conditions were
actually solved. If you need reassurance on a particular dataset, re-run from
several {cmd:bandwidth()} values and check the estimates agree.


{marker inference}{...}
{title:Inference}

{pstd}
Estimating the fixed effects changes the influence function: the instrument
{it:z(i,t)} is replaced by a {bf:residualised} instrument
{it:z(i,t)} {c -} {it:delta(i)}, which removes the first-order effect of
having estimated {it:alpha(i)}. This is what distinguishes the covariance here
from cross-sectional smoothed IVQR inference, which has no estimated fixed
effects and no within-unit dependence.

{pstd}
With {it:u}-hat({it:i,t}) = {it:y(i,t)} {c -} {it:alpha}-hat({it:i}) {c -}
{it:x(i,t)}'{it:beta}-hat and
{it:K_h}({it:w}) = {it:K}({it:w}/{it:h})/{it:h}, Section 5 estimates

{p 8 8 2}
{it:f}-hat({it:i}) = (1/{it:T}) {it:sum} {it:K_h}({it:u}-hat),
{col 48}{it:s}-hat({it:i}) = 1/{it:f}-hat({it:i}){break}
{it:gamma}-hat({it:i}) = {it:s}-hat({it:i}) (1/{it:T}) {it:sum}
{it:K_h}({it:u}-hat) {it:x(i,t)}{break}
{it:delta}-hat({it:i}) = {it:s}-hat({it:i}) (1/{it:T}) {it:sum}
{it:K_h}({it:u}-hat) {it:z(i,t)}{break}
{it:D}-hat = (1/{it:nT}) {it:sum over i,t} {it:K_h}({it:u}-hat)
{it:z(i,t)} ( {it:x(i,t)} {c -} {it:gamma}-hat({it:i}) )'{break}
{it:psi}-hat({it:i,t}) = ( {it:z(i,t)} {c -} {it:delta}-hat({it:i}) )
( 1{c -(}{it:u}-hat {ul:<} 0{c )-} {c -} {it:tau} )

{pstd}
and then, with the Bartlett kernel {it:k}({it:a}) = (1 {c -}
{c |}{it:a}{c |})+ and truncation lag {it:L},

{p 8 8 2}
{it:Omega}-hat({it:i}) = (1/{it:T}) [ {it:sum over t}
{it:psi}-hat {it:psi}-hat'{break}
{col 22}+ {it:sum over j=1..L} {it:k}({it:j}/({it:L}+1))
{it:sum over t} ( {it:psi}-hat({it:i,t}) {it:psi}-hat({it:i,t+j})'
+ {it:psi}-hat({it:i,t+j}) {it:psi}-hat({it:i,t})' ) ]

{pstd}
averaged over units to give {it:Omega}-hat. The covariance is

{p 8 8 2}
{it:Sigma}-hat = ({it:D}'{it:WD})^{c -}1 {it:D}'{it:W}
{it:Omega}-hat {it:WD} ({it:D}'{it:WD})^{c -}1,

{pstd}
collapsing to ({it:D}'{it:Omega}-hat^{c -}1{it:D})^{c -}1 for the efficient
two-step estimator. Reported standard errors are
sqrt(diag({it:Sigma}-hat)/({it:nT})), and {cmd:e(V)} is
{it:Sigma}-hat/({it:nT}), which is what {helpb test} and {helpb lincom} need.

{pstd}
{bf:No small-sample correction is applied anywhere.} The paper writes
1/{it:T} and 1/({it:nT}) throughout with no degrees-of-freedom adjustment, and
{cmd:xtpqgmm} follows it exactly. That is part of why the paper's own coverage
was 0.896 rather than 0.95 at ({it:n},{it:T}) = (20,20).

{pstd}
{bf:The truncation lag.} The default is max(1, floor({it:T}^(1/5))), the rule
used in the paper. Theorem 5.1 needs {it:L} to grow with
{it:L}^2 log({it:nT})/({it:T h}^2) tending to zero; {cmd:xtpqgmm} evaluates
that expression and notes it in the footer when it is uncomfortable, returning
the verdict in {cmd:e(haclagok)}. Remark 5.2 suggests {it:L} = 1 for small
{it:T} following Hahn and Kuersteiner (2011), and offers Andrews (1991) as
{it:informal} guidance only. The paper states plainly that the optimal lag for
this estimator {bf:remains an open problem}.

{pstd}
{bf:Hypothesis tests.} For {it:H0}: {it:R beta} = {it:r} with {it:R} of full
row rank {it:q}, the Wald statistic
{it:nT}({it:R beta}-hat {c -} {it:r})'({it:R Sigma}-hat {it:R}')^{c -}1
({it:R beta}-hat {c -} {it:r}) is chi-squared with {it:q} degrees of freedom
under the null. Because {cmd:e(V)} is posted correctly, {helpb test},
{helpb testnl}, {helpb lincom} and {helpb nlcom} all deliver this.


{marker uniform}{...}
{title:Uniform inference, and why {cmd:xtpqgmmplot} draws pointwise bands}

{pstd}
Theorem 4.1 is a {bf:pointwise} result. It fixes one {it:tau} in (0,1) and
gives the limit distribution of {it:beta}-hat({it:tau}) at that one
{it:tau}. The paper proves nothing about the process
{it:tau} {c -}> {it:beta}-hat({it:tau}) viewed as a random function, and in
particular it establishes no weak convergence to a Gaussian process in
{it:l}-infinity(T) over a closed subinterval T of (0,1).

{pstd}
Three things follow, and they are the reason {helpb xtpqgmmplot} is a
separate command with a warning in its footer rather than a {cmd:graph}
option on {cmd:xtpqgmm}:

{phang2}
1. The bands {cmd:xtpqgmmplot} draws are correct {bf:one quantile at a time}.
At each plotted {it:tau} the interval covers the true
{it:beta}({it:tau}) with the stated probability.

{phang2}
2. They are {bf:not} a confidence band for the whole path. The event "the
estimated path stays inside the band at every plotted {it:tau}" has coverage
well below the nominal level, and the shortfall grows with the number of
quantiles plotted. Reading a path that wanders outside the band as evidence
against a constant coefficient is not a valid test.

{phang2}
3. {bf:There is no cross-quantile covariance to build one from.} {cmd:xtpqgmm}
fits each quantile separately and posts a block-diagonal {cmd:e(V)}; the
off-diagonal blocks are exactly zero because the paper supplies no estimator
for them, not because they are zero in truth. A {helpb test} comparing
coefficients {it:across} quantiles will therefore run and report a number,
and that number is {bf:not} valid. The command says so in its own footer
whenever more than one quantile is fitted.

{pstd}
What would be needed: a functional central limit theorem for the smoothed
profiled moment process, uniformly in {it:tau}, together with a resampling
scheme for the limit's supremum. Galvao and Kato (2016) supply the
uniform-convergence machinery for the {it:un}instrumented smoothed FE
estimator, and Chernozhukov and Hansen (2006) handle the cross-sectional IVQR
process, but neither covers this estimator. Until that gap is filled, a
uniform band here would be decoration, so {cmd:xtpqgmmplot} does not draw one.

{pstd}
{bf:If you need a statement about the whole path today}, the defensible
options are a Bonferroni correction across the plotted grid, which
{cmd:xtpqgmmplot} does not apply for you, or a pairwise comparison of two
quantiles by a panel bootstrap that resamples whole units and refits both
quantiles on each draw. The second is correct but expensive, and the package
does not ship it.


{marker nT}{...}
{title:The n/T condition}

{pstd}
Theorem 4.1 gives asymptotic normality under {it:n}/{it:T} tending to zero.
That condition is not decoration. The incidental-parameter bias from
estimating the {it:n} fixed effects is {it:O}(1/{it:T}), so after
sqrt({it:nT}) normalisation its contribution is of order
{bf:sqrt({it:n}/{it:T})}. If {it:n}/{it:T} tends to a positive constant
instead, that term {bf:stays in the limiting distribution} and would require
explicit bias correction -- which the paper places outside its scope.

{pstd}
{cmd:xtpqgmm} therefore:

{p 4 7 2}
{bf:estimates anyway}, because the paper's own simulations deliberately report
all nine combinations of {it:n} and {it:T} in {c -(}20, 50, 100{c )-},
including {it:n} = {it:T} and {it:n} > {it:T};

{p 4 7 2}
{bf:prints the magnitude} sqrt({it:n}/{it:T}-bar) when {it:n} is not small
relative to {it:T}-bar, and returns the ratio in {cmd:e(n_over_T)};

{p 4 7 2}
{bf:applies no correction}, because the paper derives none. Inventing one
would be worse than reporting the exposure honestly.

{pstd}
The practical reading: this estimator wants {bf:long} panels. A long-{it:T},
moderate-{it:n} macro panel -- the paper's own application is 27 countries by
225 months -- is the comfortable case. A wide short panel is not.


{marker assume}{...}
{title:Assumptions}

{pstd}
Condensed from Section 4.2. Each is the paper's own numbering.

{p 4 8 2}
{bf:(A1)} Within each unit, {c -(}({it:y},{it:x},{it:z}){c )-} is strictly
stationary and beta-mixing with geometrically decaying coefficients; units are
{bf:independent of one another}.

{p 4 8 2}
{bf:(A2)} {it:x} and {it:z} are bounded almost surely.

{p 4 8 2}
{bf:(A3)} The parameter spaces are compact and the truth is interior.

{p 4 8 2}
{bf:(A4)} The conditional density of {it:u} given ({it:x},{it:z}) exists and
is bounded away from zero at 0, uniformly in {it:i}.

{p 4 8 2}
{bf:(A5)} Global identification: the fixed-effect restriction has a solution
for every {it:beta}, and the profiled population moment separates from zero
away from {it:beta}(0).

{p 4 8 2}
{bf:(A6)} The density is {it:r} times continuously differentiable with
{it:r} {ul:>} 4 even, plus a uniform local anti-concentration bound on pairs
of residual dates. This last part is {bf:weaker} than requiring a bounded
joint conditional density at both dates, which matters: in a dynamic model,
conditioning on adjacent regressors can reveal the earlier outcome and make
that joint density singular.

{p 4 8 2}
{bf:(A7)} Local full rank: {it:D} converges to a limit of full rank and
{it:D}'{it:WD} is non-singular.

{p 4 8 2}
{bf:(A8)} The kernel is symmetric, compactly supported, continuously
differentiable with Lipschitz derivative, and of order {it:r}.
Non-negativity is {bf:not} required.

{p 4 8 2}
{bf:(A9)} {it:h} proportional to {it:T}^({c -}{it:c}) with
1/{it:r} < {it:c} < 1/3.

{p 4 8 2}
{bf:(A10)} The average long-run variance of the residualised scores converges
to a finite positive definite limit.

{pstd}
Plus, for Theorem 4.1, {bf:{it:n}/{it:T} tends to 0}, and for Lemma 4.1 and
Proposition 4.1, log({it:n})/sqrt({it:T}) tends to 0.


{marker limits}{...}
{title:Limitations}

{pstd}
What {cmd:xtpqgmm} does {bf:not} do, and why. None of these is an oversight;
each is something the source paper does not provide, and inventing it would
mean shipping a statistic with no justification.

{p 4 7 2}
{bf:No overidentification (J / Hansen-Sargan) test.} The model is usually
over-identified and a {it:J} test would be the natural diagnostic, but the
paper derives none, and the distribution of a {it:J} statistic after profiling
out {it:n} fixed effects from a smoothed moment is not established.
{cmd:e(mnorm)} and {cmd:e(Qval)} are reported for your own judgement.

{p 4 7 2}
{bf:No weak-instrument or instrument-relevance diagnostic.} Likewise absent
from the paper, despite its own application using six to twelve instruments
for three parameters.

{p 4 7 2}
{bf:No incidental-parameter bias correction.} See
{help xtpqgmm_methods##nT:the n/T condition}.

{p 4 7 2}
{bf:No cross-quantile inference.} Quantiles are estimated separately and the
off-diagonal blocks of {cmd:e(V)} are exactly zero. Tests across quantiles are
invalid, and no uniform confidence band over {it:tau} is available, because
the paper supplies no joint covariance. Monotonicity is not imposed.

{p 4 7 2}
{bf:No cross-sectional dependence.} (A1) makes units independent, and the
paper's own application concedes in a footnote that general cross-country
dependence would require an extension. No Driscoll-Kraay option is offered.

{p 4 7 2}
{bf:No weights.}

{p 4 7 2}
{bf:No gaps in time.} The Bartlett sums are undefined across a gap, so the
command refuses rather than silently dropping or interpolating.

{p 4 7 2}
{bf:No predict.} The smoothed indicator leaves [0,1] by construction, so it is
not a fitted probability, and the paper defines no residual or prediction of
interest beyond {it:u}-hat, which you can form yourself from {cmd:e(b)} and
{cmd:e(alpha)}.

{p 4 7 2}
{bf:Not the paper's optimiser.} See
{help xtpqgmm_methods##optim:The optimiser}.

{p 4 7 2}
{bf:The multiple-root rule is a documented heuristic}, not the paper's
combinatorial tie-break. See {help xtpqgmm_methods##roots:Multiple roots}.


{marker map}{...}
{title:Step-to-equation map}

{pstd}
What the code does, and where in the paper each step comes from.

{synoptset 34 tabbed}{...}
{synopthdr:step}
{synoptline}
{synopt :smoothed indicator {it:G}, kernel {it:K}}Section 6, Appendix B{p_end}
{synopt :bandwidth {it:h} = {it:c}({it:tau}){it:T}^({c -}2/7)}Section 6,
Appendix B; rate from (A9){p_end}
{synopt :profile {it:alpha_i} per unit}equation (8){p_end}
{synopt :profiled moment {it:m_n}({it:beta})}equations (7) and (13){p_end}
{synopt :drop the {it:K}-tilde terms}Remark 3.1, justified by Galvao and
Kato (2016, Theorem 3.1){p_end}
{synopt :SP-MM start}equation (9){p_end}
{synopt :one-step GMM, {it:W} = {it:I}}equation (10){p_end}
{synopt :two-step GMM, {it:W} = {it:Omega}^{c -}1}equation (11){p_end}
{synopt :{it:gamma}-hat, {it:delta}-hat, {it:f}-hat, {it:D}-hat}Section 5{p_end}
{synopt :{it:psi}-hat, Bartlett {it:Omega}-hat}Section 5{p_end}
{synopt :{it:Sigma}-hat and standard errors}Theorem 5.1{p_end}
{synopt :Wald test}Section 5{p_end}
{synopt :HAC lag max(1, {it:T}^(1/5))}Section 6; Remark 5.2{p_end}
{synopt :{it:n}/{it:T} warning}Theorem 4.1, Remark 4.1{p_end}
{synopt :minimum-{it:T} refusal}p. 13, after Graham, Hahn and Powell (2009){p_end}
{synopt :multiple-root count}p. 15, Lemma 4.1, Lemma A.4{p_end}
{synoptline}
{p2colreset}{...}


{marker refs}{...}
{title:References}

{pstd}
Each entry says what it is load-bearing for, so you can see which part of the
estimator rests on which source.

{phang}
{bf:Andrews, D. W. K.} 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica} 59(3): 817-858.
{browse "https://doi.org/10.2307/2938229":doi:10.2307/2938229}{break}
{it:Informal guidance only for the HAC lag; Remark 5.2 is explicit that it is
not optimal here.}

{phang}
{bf:Angrist, J., V. Chernozhukov, and I. Fernandez-Val.} 2006. Quantile
regression under misspecification, with an application to the U.S. wage
structure. {it:Econometrica} 74(2): 539-563.{break}
{it:The pseudo-true-parameter reading when the conditional model is
misspecified.}

{phang}
{bf:Chernozhukov, V., and C. Hansen.} 2005. An IV model of quantile treatment
effects. {it:Econometrica} 73(1): 245-261.
{browse "https://doi.org/10.1111/j.1468-0262.2005.00570.x":doi:10.1111/j.1468-0262.2005.00570.x}{break}
{it:The structural IVQR conditions that make beta causal, and the global
identification results behind (A5).}

{phang}
{bf:Chernozhukov, V., and C. Hansen.} 2006. Instrumental quantile regression
inference for structural and treatment effect models.
{it:Journal of Econometrics} 132(2): 491-525.
{browse "https://doi.org/10.1016/j.jeconom.2005.02.009":doi:10.1016/j.jeconom.2005.02.009}{break}
{it:The inverse-QR procedure this estimator's nested structure is related to,
and the computational problem it avoids.}

{phang}
{bf:Chernozhukov, V., and H. Hong.} 2003. An MCMC approach to classical
estimation. {it:Journal of Econometrics} 115(2): 293-346.
{browse "https://doi.org/10.1016/S0304-4076(03)00100-3":doi:10.1016/S0304-4076(03)00100-3}{break}
{it:Figure 1(a) and Example 3: why the unsmoothed criterion is intractable.}

{phang}
{bf:de Castro, L., A. F. Galvao, D. M. Kaplan, and X. Liu.} 2019. Smoothed GMM
for quantile models. {it:Journal of Econometrics} 213(1): 121-144.
{browse "https://doi.org/10.1016/j.jeconom.2019.04.008":doi:10.1016/j.jeconom.2019.04.008}{break}
{it:The cross-sectional smoothed-GMM-quantile estimator this one generalises
to panels.}

{phang}
{bf:Firpo, S., A. F. Galvao, C. Pinto, A. Poirier, and G. Sanroman.} 2022. GMM
quantile regression. {it:Journal of Econometrics} 230(2): 432-452.
{browse "https://doi.org/10.1016/j.jeconom.2020.11.014":doi:10.1016/j.jeconom.2020.11.014}

{phang}
{bf:Galvao, A. F., U. Hounyo, and J. Lin.} 2026. GMM for panel data quantile
regression. arXiv:2610.12824 [econ.EM].
{browse "https://doi.org/10.48550/arXiv.2610.12824":doi:10.48550/arXiv.2610.12824}{break}
{bf:The source paper. Cite this when you use} {cmd:xtpqgmm}{bf:.}

{phang}
{bf:Galvao, A. F., J. Gu, and S. Volgushev.} 2020. On the unbiased asymptotic
normality of quantile regression with fixed effects.
{it:Journal of Econometrics} 218(1): 178-215.
{browse "https://doi.org/10.1016/j.jeconom.2020.04.006":doi:10.1016/j.jeconom.2020.04.006}{break}
{it:Why n/T tending to zero removes the first-order incidental-parameter bias.}

{phang}
{bf:Galvao, A. F., and K. Kato.} 2016. Smoothed quantile regression for panel
data. {it:Journal of Econometrics} 193(1): 92-112.
{browse "https://doi.org/10.1016/j.jeconom.2016.01.008":doi:10.1016/j.jeconom.2016.01.008}{break}
{it:The smoothed panel quantile framework this extends. Theorem 3.1 justifies
dropping the K-tilde terms from the estimating equation -- the single most
load-bearing borrowed result. Lemma B.2 and the Appendix C lemmas supply the
uniform rates.}

{phang}
{bf:Graham, B. S., J. Hahn, and J. L. Powell.} 2009. The incidental parameter
problem in a non-differentiable panel data model.
{it:Economics Letters} 105(2): 181-182.
{browse "https://doi.org/10.1016/j.econlet.2009.07.012":doi:10.1016/j.econlet.2009.07.012}{break}
{it:Non-identification at T = 2, behind the minimum-T refusal.}

{phang}
{bf:Hahn, J., and G. M. Kuersteiner.} 2011. Bias reduction for dynamic
nonlinear panel models with fixed effects.
{it:Econometric Theory} 27(6): 1152-1191.
{browse "https://doi.org/10.1017/S0266466611000028":doi:10.1017/S0266466611000028}{break}
{it:Behind the suggestion of lag 1 in short panels.}

{phang}
{bf:Horowitz, J. L.} 1998. Bootstrap methods for median regression models.
{it:Econometrica} 66(6): 1327-1351.
{browse "https://doi.org/10.2307/2999619":doi:10.2307/2999619}{break}
{it:Origin of the smoothing device, the r {ul:>} 4 requirement, and the
bandwidth rate restrictions. Lemma 3 is the ancestor of Galvao-Kato's
Lemma B.2.}

{phang}
{bf:Kaplan, D. M.} 2022. Smoothed instrumental variables quantile regression.
{it:Stata Journal} 22(2): 379-403.{break}
{it:The} {helpb sivqr} {it:implementation paper.}

{phang}
{bf:Kaplan, D. M., and Y. Sun.} 2017. Smoothed estimating equations for
instrumental variables quantile regression.
{it:Econometric Theory} 33(1): 105-157.
{browse "https://doi.org/10.1017/S0266466615000407":doi:10.1017/S0266466615000407}{break}
{it:The smoothed IVQR approach, the fourth-order kernel, the MSE-optimal
bandwidth theory, and optimal instruments (Section 2.1).}

{phang}
{bf:Kato, K., A. F. Galvao, and G. Montes-Rojas.} 2012. Asymptotics for panel
quantile regression models with individual effects.
{it:Journal of Econometrics} 170(1): 76-91.
{browse "https://doi.org/10.1016/j.jeconom.2012.02.007":doi:10.1016/j.jeconom.2012.02.007}{break}
{it:The definition of weak consistency used in Proposition 4.1.}

{phang}
{bf:Koenker, R.} 2004. Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91(1): 74-89.{break}
{it:The fixed-effects quantile estimator whose quantile-invariant intercept
this model relaxes.}

{phang}
{bf:Melly, B., and M. Pons.} 2025. Minimum distance estimation of quantile
panel data models. arXiv:2502.18242.
{browse "https://doi.org/10.48550/arXiv.2502.18242":doi:10.48550/arXiv.2502.18242}{break}
{it:The main alternative; implemented in Stata as} {helpb xtmdqr}{it:.}

{phang}
{bf:Xiang, Y., S. Gubian, B. Suomela, and J. Hoeng.} 2013. Generalized
simulated annealing for global optimization: the GenSA package.
{it:The R Journal} 5(1): 13-28.
{browse "https://doi.org/10.32614/RJ-2013-002":doi:10.32614/RJ-2013-002}{break}
{it:The optimiser the paper used and Mata does not have; see} {bf:The
optimiser}{it:.}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb xtpqgmm}, {helpb sivqr}, {helpb xtmdqr}, {helpb mmqreg},
{helpb qregfe}, {helpb gmm}
{p_end}
