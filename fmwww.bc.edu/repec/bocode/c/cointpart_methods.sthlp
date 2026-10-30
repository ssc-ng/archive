{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "cointpart" "help cointpart"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "egranger (if installed)" "help egranger"}{...}
{vieweralsosee "ghansen (if installed)" "help ghansen"}{...}
{vieweralsosee "radf (if installed)" "help radf"}{...}
{viewerjumpto "The model" "cointpart_methods##model"}{...}
{viewerjumpto "The window statistic" "cointpart_methods##window"}{...}
{viewerjumpto "The three statistics" "cointpart_methods##three"}{...}
{viewerjumpto "Assumptions and limiting theory" "cointpart_methods##limit"}{...}
{viewerjumpto "Which alternatives each statistic detects" "cointpart_methods##consistency"}{...}
{viewerjumpto "Lag selection" "cointpart_methods##lags"}{...}
{viewerjumpto "Critical values" "cointpart_methods##cv"}{...}
{viewerjumpto "Step-to-equation map" "cointpart_methods##map"}{...}
{viewerjumpto "Algebraic equivalences used" "cointpart_methods##equiv"}{...}
{viewerjumpto "Numerical validation" "cointpart_methods##validation"}{...}
{viewerjumpto "Limitations" "cointpart_methods##limits"}{...}
{viewerjumpto "References" "cointpart_methods##references"}{...}
{viewerjumpto "Author" "cointpart_methods##author"}{...}

{title:Title}

{phang}
{bf:cointpart methods} {hline 2} derivation, step-to-equation map and
limitations of the Cointegration by Parts tests

{pstd}
This page documents how {helpb cointpart} implements
{help cointpart_methods##KV2026:Kvist and Vera-Valdes (2026)}. Equation numbers
are the paper's. Appendix results are cited as the paper labels them (lemma A.1,
proposition A.1, and so on). For syntax and practical guidance see
{helpb cointpart}.


{marker model}{title:The model}

{pstd}
{bf:Definition 3.1.} For {it:N}+1 series {it:y_t} and
{it:x_t} = ({it:x_1t},...,{it:x_Nt}), all integrated of order one, observed for
{it:t} = 1,...,{it:T}:

{p 8 8 2}{bf:(3.1)}{space 4}{it:y_t} = {it:d_t}'{it:delta} + {it:x_t}'{it:beta} + {it:eps_t}

{pstd}
where {it:d_t} collects the deterministic regressors and {it:beta} is the
potential cointegrating vector. Whether the series cointegrate is decided by the
integration order of {it:eps_t}. The procedure is indexed by the deterministic
specification, because the limiting distributions differ across the three
standard cases:

{p 8 8 2}{bf:(3.2)}{space 4}Case n: {it:d_t} = 0{space 6}Case c: {it:d_t} = 1{space 6}Case ct: {it:d_t} = (1, {it:t}/{it:T})

{pstd}
Case c is the default. Case ct is required when the series are integrated with
drift: under Case c the drifts dominate the regression, the OLS estimator
converges to the ratio of the two drifts at rate {it:T}{c 94}(3/2) rather than to
the cointegrating parameter, and critical values calibrated on driftless random
walks no longer apply. This is the distinction between deterministic and
stochastic cointegration of
{help cointpart_methods##Hansen1992:Hansen (1992)}.

{pstd}
The deterministic term is not cosmetic for a window-based statistic. A window
beginning at {it:T r_1} with {it:r_1} > 0 opens after the integrated regressors
have already accumulated to a level of order sqrt({it:T}), which the residual
process on that window would otherwise inherit as an unmodelled initial
condition. Including {it:d_t} removes it, because the fitted residuals are
orthogonal to {it:d_t} by construction; in Case c they therefore sum to zero over
every window. {bf:This is why the ADF regression in (3.7) carries no
deterministic terms of its own}, and {cmd:cointpart} includes none.

{pstd}
{bf:Definition 3.2.} The residual process exhibits a break at the fraction
{it:tau_0} in (0,1) if {it:eps_t} is I(0) for {it:t} < {it:T tau_0} and I(1)
thereafter (a {it:forward} break), or I(1) then I(0) (a {it:reverse} break).
Neither {it:tau_0} nor the direction is known, so the stationary sub-interval must
be searched for rather than assumed. Write {it:S} for that stationary segment.

{pstd}
The two hypotheses, equation (3.13), are

{p 8 12 2}
{bf:H0}: {it:eps_t} is I(1) for all {it:t} {hline 1} the series do not
cointegrate anywhere;

{p 8 12 2}
{bf:H1}: {it:eps_t} satisfies definition 3.2 for some {it:tau_0}, with
|{it:S}| >= {it:r_0}.


{marker window}{title:The window statistic}

{pstd}
Stack the regressors as {it:z_t} = ({it:d_t}', {it:x_t}')'. On the window
[{it:T r_1}+1, {it:T r_2}] the coefficient vector is estimated by OLS,

{p 8 8 2}{bf:(3.5)/(A.1)}{space 4}{it:theta-hat}({it:r_1},{it:r_2}) = (sum {it:z_t z_t}'){c 94}(-1) (sum {it:z_t y_t})

{pstd}
and the window residuals are

{p 8 8 2}{bf:(3.6)}{space 4}{it:eps-hat_t} = {it:y_t} - {it:d_t}'{it:delta-hat} - {it:x_t}'{it:beta-hat}

{pstd}
{bf:The coefficient vector is re-estimated inside every window.} That is the
substantive difference from applying a change-in-persistence test to one set of
full-sample residuals, which would not be valid here: under H1 the full-sample
estimate of {it:beta} is not consistent for the cointegrating vector that holds
on the stationary segment.

{pstd}
Those residuals are then tested with an ADF regression over the same window,

{p 8 8 2}{bf:(3.7)}{space 4}{it:D eps-hat_t} = {it:gamma eps-hat_(t-1)} + sum_(i=1..p) {it:phi_i} {it:D eps-hat_(t-i)} + {it:u_t}

{pstd}
where {it:D} is the first-difference operator. This is the usual
reparameterisation of an autoregression of order {it:p}+1, so the unit-root
hypothesis is {bf:H0: gamma = 0}. The window statistic is the t-ratio

{p 8 8 2}{bf:(3.8)}{space 4}EG({it:r_1},{it:r_2}) = {it:gamma-hat} / se({it:gamma-hat})

{pstd}
with se({it:gamma-hat}) the OLS standard error. Differences are taken within the
window, so the regression uses only observations from [{it:T r_1}+1, {it:T r_2}].


{marker three}{title:The three statistics}

{pstd}
Let {it:R}({it:r_0}) = {c -(}({it:r_1},{it:r_2}) : {it:r_2} in [{it:r_0},1],
{it:r_1} in [0, {it:r_2}-{it:r_0}]{c )-} be the admissible windows. The three
statistics are infima of (3.8) over different subsets of it:

{p 8 8 2}{bf:(3.9)}{space 5}FIEG({it:r_0}) = inf over {it:r} in [{it:r_0},1] of EG(0,{it:r})

{p 8 8 2}{bf:(3.16)}{space 4}BIEG({it:r_0},{it:r_2}) = inf over {it:r_1} in [0,{it:r_2}-{it:r_0}] of EG({it:r_1},{it:r_2})

{p 8 8 2}{bf:(3.17)}{space 4}GIEG({it:r_0}) = inf over ({it:r_1},{it:r_2}) in {it:R}({it:r_0}) of EG({it:r_1},{it:r_2})

{pstd}
{cmd:cointpart} reports BIEG({it:r_0},1), the fixed-endpoint version, as "BIEG".
Because the FIEG and BIEG window sets are subsets of the GIEG window set, {bf:one
scan yields all three}, and that is how the command computes them.

{pstd}
The {opt prefix()} option saves the two sequences this induces. Writing
{it:b}({it:r_2}) = BIEG({it:r_0},{it:r_2}) for the backward infimum at each
endpoint, the minimum of {it:b} over the sample is GIEG and its last value is
BIEG. The sequence {it:b} is the natural object to plot and to date-stamp from,
and it is the left-tailed counterpart of the BSADF sequence that {helpb radf}
plots.


{marker limit}{title:Assumptions and limiting theory}

{pstd}
{bf:Assumption 3.1(i).} The innovations of {it:x_t} and {it:y_t} satisfy a joint
functional central limit theorem, with limiting Brownian motion
({it:B_x},{it:B_y}) and long-run covariance matrix {it:Omega}, assumed positive
definite. In general the two are correlated.

{pstd}
{bf:Assumption 3.1(ii).} The lag order follows a deterministic rule
{it:p}({it:T}), common to all windows, under either of two regimes: a finite
autoregressive order, or an order diverging with {it:p} -> infinity and
{it:p}{c 94}3/{it:T} -> 0, which is the
{help cointpart_methods##Said1984:Said and Dickey (1984)} condition that renders
the errors asymptotically serially uncorrelated.

{pstd}
{bf:The limiting objects.} Because the estimator includes the deterministic
regressors, the limits are built from projection residuals rather than from the
Brownian motions themselves. Equation (A.2) defines, for a window and any scalar
process {it:B}, the L2 projection residual of {it:B} off the limiting
deterministic regressors over that window: {it:B} itself in Case n, {it:B}
demeaned in Case c, {it:B} demeaned and detrended in Case ct. This is the
continuous-time counterpart of partialling {it:d_t} out of the regression.
Equation (A.3) then forms the limiting projection coefficient
{it:b}({it:r_1},{it:r_2}), the residual process, and its variance rate; and
{it:W} denotes the residual process standardized by that rate.

{pstd}
The limit itself is, for each window,

{p 8 8 2}{bf:(A.5)}{space 4}{it:Q}({it:r_1},{it:r_2}) = [{it:W}({it:r_2}){c 94}2 - {it:W}({it:r_1}){c 94}2 - ({it:r_2}-{it:r_1})] / (2 [integral {it:W(s)}{c 94}2 ds]{c 94}(1/2))

{pstd}
This is the Dickey-Fuller limit written for a process of unit variance rate. The
paper writes it in endpoint form rather than as a stochastic integral
deliberately: the projection coefficient in (A.3) is a functional of the whole
Brownian path over the window, so the standardized process is {it:not} adapted
and the stochastic integral would not be an Ito integral. The endpoint form
involves only two endpoint values and the quadratic variation, and the two agree
by the pathwise Ito formula, which needs no adaptedness.

{pstd}
{bf:Theorem 3.1}, and {bf:theorems B.1 and B.2} for BIEG and GIEG, then give the
null limits: each statistic converges in distribution to the infimum of {it:Q}
over the corresponding window set. Four lemmas carry the argument:

{p 8 12 2}
{bf:Lemma A.1} {hline 1} the limiting window Gram matrix is uniformly
non-degenerate, {it:at every window simultaneously}. This is stronger than
non-singularity at each fixed window, because the minimizing window is random.
It follows from the quadratic variation of the limiting process alone:
degeneracy at any window would force a Brownian path to be affine on an interval
of positive length. The trimming {it:r_0} enters here, and the result fails at
{it:r_0} = 0.

{p 8 12 2}
{bf:Lemma A.2} {hline 1} the whole process {c -(}EG({it:r_1},{it:r_2}){c )-},
indexed by the window, converges uniformly. Convergence at each window
separately would not be enough: taking an infimum in the limit requires
convergence of the process, so that the continuous mapping theorem applies.

{p 8 12 2}
{bf:Lemma A.3} {hline 1} on a window contained entirely inside the stationary
segment (a {it:clean} window) the window regression is a genuine cointegrating
regression, OLS is super-consistent, and the statistic diverges to minus infinity
at rate sqrt({it:T}).

{p 8 12 2}
{bf:Lemma A.4} {hline 1} a family of windows kept a fixed distance away from the
stationary segment stays bounded in probability. A window that merely overlaps
the segment retains an I(1) stretch of non-vanishing length and contributes
nothing to the divergence.

{pstd}
{bf:Lemma A.5} {hline 1} {bf:invariance.} The limiting distributions do not depend on
the long-run covariance matrix {it:Omega}, but only on {it:N}, {it:r_0} and the
deterministic case. This is what makes a single tabulation usable on any data
set, and it parallels the corresponding result for static residual-based tests in
{help cointpart_methods##PO1990:Phillips and Ouliaris (1990)}.


{marker consistency}{title:Which alternatives each statistic detects}

{pstd}
{bf:Proposition A.1 (directional consistency).} A statistic of the form
inf over {it:W} of EG diverges to minus infinity if its search set {it:W}
contains a clean window, and is bounded in probability if its windows are kept
uniformly away from the stationary segment. Consequently:

{p 8 12 2}
{bf:FIEG} diverges under a forward break with {it:tau_0} >= {it:r_0}, and is
{it:O_p}(1) under a reverse break {hline 1} for {it:every} {it:tau_0}.

{p 8 12 2}
{bf:BIEG}({it:r_0},1) diverges under a reverse break with
1-{it:tau_0} >= {it:r_0}, and is {it:O_p}(1) under a forward break.

{p 8 12 2}
{bf:GIEG} diverges under {it:either} direction, provided only that
|{it:S}| >= {it:r_0}.

{pstd}
Every FIEG window begins at the start of the sample and every BIEG window ends at
its end, which is exactly what keeps those windows a fixed distance from the
segment under the wrong break direction. {bf:Choosing the wrong direction
eliminates power rather than reducing it}, and no amount of data repairs it.
GIEG restricts neither endpoint and is the only one of the three consistent
against H1 as stated in (3.13). This is why {helpb cointpart} recommends GIEG
whenever the direction is in doubt, and why its considerably more negative
critical value is the price of that generality rather than a defect.


{marker lags}{title:Lag selection}

{pstd}
The asymptotic theory fixes the lag order by a deterministic rule; the
implementation selects it from the data. {bf:Remark A.1} reconciles the two: if
the selected order is eventually constant across the windows actually scanned,
the statistic process computed with selected lags coincides {it:path by path}
with the one computed under the deterministic rule, so the theorems apply
unchanged. The argument needs no continuity of the selected order in the window.
BIC is order consistent in each window, since every admissible window has at
least {it:r_0 T} observations and consistency of the criterion survives unit
roots ({help cointpart_methods##Paulsen1984:Paulsen 1984}). Uniformity over the
O({it:T}{c 94}2) windows a GIEG scan visits requires in addition that the
per-window misselection probability be {it:o}({it:T}{c 94}(-2)), which the paper
assumes rather than establishes.

{pstd}
{cmd:cointpart} implements the paper's finite-sample rule exactly. In each window
of length {it:n}:

{p 8 12 2}
1. The maximum order is Schwert's bound, floor(12 ({it:n}/100){c 94}0.25),
applied to the {bf:window} length and not to the full sample
({help cointpart_methods##Schwert1989:Schwert 1989}). Because {it:n} <= {it:T},
this bounds the selected order by O({it:T}{c 94}0.25) uniformly, so the
{it:p}{c 94}3/{it:T} -> 0 restriction holds in every window.

{p 8 12 2}
2. That bound is then reduced until the ADF regression retains at least
max({it:p}+3, {opt dofratio()} ({it:p}+1)) usable observations. Without the
second term Schwert's bound assigns eight lags to a twenty-observation window,
leaving two residual degrees of freedom.

{p 8 12 2}
3. Candidate orders 0,...,{it:p_max} are scored on a {bf:common sample} {hline 1}
the one available at {it:p_max} {hline 1} so that the criterion compares
likelihoods over identical observations. The effective sample size is therefore
the same for every candidate, and it is that size, not the per-order sample, that
enters the penalty.

{pstd}
Step 3 is easy to get wrong and changes the answer silently. So does step 1:
applying Schwert's rule to {it:T} instead of to {it:n} gives a different order in
almost every short window.


{marker cv}{title:Critical values}

{pstd}
All three statistics have non-standard limiting distributions, so critical values
come from simulation. The paper simulates under definition 3.1 with independent
driftless random walks, and summarizes the result through a response surface in
the manner of {help cointpart_methods##MacKinnon2010:MacKinnon (2010)}:

{p 8 8 2}{bf:(4.18)}{space 4}cv({it:T}) = {it:b_inf} + {it:b_1}/{it:T} + {it:b_2}/{it:T}{c 94}2 + {it:b_3}/{it:T}{c 94}3

{pstd}
fitted by weighted least squares with weights the inverse squared Monte Carlo
standard error of each simulated quantile, the cubic term retained only when it
exceeds 1.96 of its own standard errors. {cmd:cointpart} carries all 54 fitted
cells printed in the paper's table 3 {hline 2} three statistics, {it:N} = 1,2,3,
the 1%, 5% and 10% levels, Cases c and ct {hline 2} and evaluates (4.18) at the
sample size in hand.

{pstd}
Two consequences the user sees:

{p 8 12 2}
{bf:Coverage.} Critical values are reported only for {it:T} >= 100,
{it:N} <= 3, {it:r_0} = 0.15, and Cases c and ct. Case n is not tabulated.
{it:r_0} is different in kind from the other three: it enters the {it:definition}
of the statistic through the admissible set, so it changes the null distribution
rather than merely the point at which it is evaluated. Outside the covered region
{cmd:cointpart} reports the statistic and its window and suppresses the critical
values, naming the reason. It never extrapolates (4.18) below {it:T} = 100, where
the paper itself documents over-rejection of up to 0.076 against a nominal 0.05.

{p 8 12 2}
{bf:Precision.} The coefficients are used as printed, and are themselves rounded.
Evaluating (4.18) with them reproduces all eighteen critical values printed in
the paper's table 5 to within 0.0008, which is the accumulated rounding. Expect
agreement with the paper's own tables to about three decimals, not more.

{pstd}
{bf:The numerical distribution function.} Section 4.3 of the paper converts a
statistic into a p-value by fitting (4.18) at a dense grid of 184 probabilities
and interpolating linearly in the {it:normal quantile} of {it:p} rather than in
{it:p},

{p 8 8 2}{bf:(4.19)}{space 4}p-hat = Phi( Phi{c 94}(-1)({it:p_(i-1)}) + lambda [Phi{c 94}(-1)({it:p_i}) - Phi{c 94}(-1)({it:p_(i-1)})] )

{pstd}
with lambda the position of the statistic between two adjacent fitted quantiles.
Interpolating in the normal quantile is the device
{help cointpart_methods##MacKinnon1994:MacKinnon (1994)} uses to stay accurate
far into the tail. Those 184 surfaces per configuration {hline 2} more than three
thousand in all {hline 2} are not printed in the paper, and at the time of
writing are not in its replication repository either. {cmd:cointpart} therefore
offers {opt reps()}, which simulates the null distribution directly at the sample
size and dimension in hand. The simulation recomputes the {bf:entire} statistic
on every replication, scan and lag selection included, because the observed
statistic's search advantage must be reproduced or the test over-rejects.


{marker map}{title:Step-to-equation map}

{pstd}
Each block of the Mata engine against the result it implements:

{synoptset 26 tabbed}{...}
{synopthdr:Mata function}
{synoptline}
{synopt :{cmd:cbp_detdim}}(3.2) {hline 1} dimension of the deterministic block per case{p_end}
{synopt :{cmd:cbp_Zwin}}(3.2) {hline 1} window regressor matrix [{it:d_t}, {it:x_t}]{p_end}
{synopt :{cmd:cbp_minwindow}}Sec. 4.1 {hline 1} minimum window = floor({it:r_0 T}), a pure fraction{p_end}
{synopt :{cmd:cbp_pmaxrule}}Schwert (1989) {hline 1} lag bound on the {it:window} length{p_end}
{synopt :{cmd:cbp_window}}(3.5), (3.6), (3.7), (3.8) {hline 1} window OLS, window residuals, ADF regression, t-ratio; plus the Sec. 4.1 common-sample and degrees-of-freedom rules{p_end}
{synopt :{cmd:cbp_scancore}}(3.9), (3.16), (3.17) {hline 1} the three infima and their argmin windows, from one scan{p_end}
{synopt :{cmd:cbp_surftab}}Table 3 {hline 1} the 54 fitted response-surface cells{p_end}
{synopt :{cmd:cbp_cvat}, {cmd:cbp_fillcv}}(4.18) {hline 1} critical value at the sample size in hand{p_end}
{synopt :{cmd:cbp_simpval}}Sec. 4.1 null DGP {hline 1} simulated p-value, repeating the whole statistic per replication{p_end}
{synopt :{cmd:cbp_putseq}}(3.16) as a sequence in {it:r_2} {hline 1} the {opt prefix()} variables{p_end}
{synoptline}

{pstd}
Results the command deliberately does {bf:not} implement, because the paper does
not provide them: the numerical distribution function of (4.19) as a lookup (see
above), and any test of the complementary null.


{marker equiv}{title:Algebraic equivalences used}

{pstd}
Three places where the implementation uses a cheaper form than the paper's
notation suggests. Each is an exact identity, not an approximation.

{pstd}
{bf:1. Trend scaling in Case ct.} Equation (3.2) scales the trend by {it:T}. The
command uses a window-local trend, {it:t}/{it:n} on a window of length {it:n}.
Once the constant is present, the two span the same two-dimensional space on any
window, and OLS is invariant to a non-singular linear reparameterisation of the
regressors, so the fitted residuals {hline 2} and hence every statistic {hline 2}
are identical. The paper makes the same point about its own scaling.

{pstd}
{bf:2. Residual sums of squares from one Cholesky factor.} Let {it:M} be the
cross-product matrix of [{it:eps-hat_(t-1)}, {it:D eps-hat_(t-1)},...,
{it:D eps-hat_(t-p_max)}, {it:D eps-hat_t}] with the dependent variable {it:last},
and {it:L} its lower Cholesky factor. Then the residual sum of squares from
regressing the last variable on the first {it:j} equals
{it:M}[last,last] - sum_(i<=j) {it:L}[last,{it:i}]{c 94}2. One factorization
therefore yields the fit of {it:every} candidate lag order, which is what makes a
full lag search affordable at every one of O({it:T}{c 94}2) windows.

{pstd}
{bf:3. The standard error of gamma-hat.} The required variance element is
[({it:X}'{it:X}){c 94}(-1)]_(11). Solving {it:L w} = {it:e_1} on the leading
{it:j} by {it:j} block gives it as {it:w}'{it:w}, with no explicit inverse. The
exact rate of this standard error matters: lemma A.3 turns a fixed negative
probability limit for {it:gamma-hat} into divergence of the {it:ratio}, so an
upper bound on the standard error would not suffice.


{marker validation}{title:Numerical validation}

{pstd}
The engine was validated against the authors' own reference implementation {hline 2}
their R package with its Rcpp/C++ engine, which they in turn validated against a
naive brute-force reference {hline 2} not only at the reported minima but
{bf:window by window}. For each configuration every admissible window's
statistic and selected lag order were compared.

{synoptset 34 tabbed}{...}
{synopthdr:Check}
{synoptline}
{synopt :Deterministic cases}{n, c and ct}{p_end}
{synopt :Regressors}{N = 1, 2, 3}{p_end}
{synopt :Sample sizes}{T = 60, 100, 140}{p_end}
{synopt :Criteria}{BIC and AIC}{p_end}
{synopt :Drift}{driftless and drifting null}{p_end}
{synopt :Windows compared}about 60,000{p_end}
{synopt :Worst statistic discrepancy}of order 1e-10 or smaller{p_end}
{synopt :Lag orders differing}none{p_end}
{synopt :Published numbers}tables 5 and 6 reproduced, statistics and windows{p_end}
{synoptline}

{pstd}
The agreement on the selected lag order is the sharpest of these: any error in
the common-sample rule, in applying Schwert's bound to the window rather than the
sample, or in the degrees-of-freedom floor would have produced hundreds of
differences. The validation harness ships with the source as
{bf:cointpart_verify.do}.


{marker limits}{title:Limitations}

{pstd}
These are the paper's own, and each points to a natural extension. None is worked
around in the command, and none should be papered over in applied work.

{p 8 12 2}
{bf:1. The null is no cointegration anywhere.} A rejection localizes evidence
{it:for} a long-run relationship; it does not establish that a relationship which
once held has since broken down. That claim needs the complementary pairing, with
cointegration over the full sample as the null.

{p 8 12 2}
{bf:2. The procedure is single-equation and residual based.} It detects at most
one cointegrating relationship, and it inherits the dependence on which series is
the regressand. A system analogue, testing the rank of the cointegrating space
window by window in the manner of Johansen, would relax both restrictions; the
authors report this as ongoing work.

{p 8 12 2}
{bf:3. A rejection does not separate partial cointegration from a shifted
cointegrating vector.} Because the vector is re-estimated in every window, a
relationship holding throughout with coefficients that shift at some date can
produce the same rejection as one confined to a sub-period. The paper's
recommended first diagnostic is to report the window-by-window estimates
alongside the statistics, which is the {opt betas} option.
{helpb ghansen} tests the shifted-vector hypothesis directly.

{p 8 12 2}
{bf:4. No confidence interval for the located window.} The command reports the
argmin window, not a set estimate for it. When the argmin sits on the boundary of
the admissible set {hline 1} a window exactly {it:r_0 T} long {hline 1} the
result is sensitive to {opt trim()}, and should be reported as suggestive. This
happens in the paper's own application.

{p 8 12 2}
{bf:5. Episodes shorter than {it:r_0} are undetectable.} They are contained in no
admissible window, and no test in this class has power against them.

{p 8 12 2}
{bf:6. The tabulated critical values are first-stage only.} In the recursive
scheme of section 4.4 every later segment is selected by the outcome of the stage
before it, so the unconditional critical values no longer have the nominal level.


{marker references}{title:References}

{marker Andrews1993}{...}
{phang}
Andrews, D. W. K. 1993. Tests for Parameter Instability and Structural Change
With Unknown Change Point. {it:Econometrica} 61: 821-856.
{browse "https://doi.org/10.2307/2951764":doi:10.2307/2951764}
{break}{it:Source of the r_0 = 0.15 trimming convention.}

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Co-Integration and Error Correction:
Representation, Estimation, and Testing. {it:Econometrica} 55: 251-276.
{browse "https://doi.org/10.2307/1913236":doi:10.2307/1913236}
{break}{it:The statistic (3.8) is their residual-based test, applied to a window.}

{marker GH1996}{...}
{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in
models with regime shifts. {it:Journal of Econometrics} 70: 99-126.
{browse "https://doi.org/10.1016/0304-4076(69)41685-7":doi:10.1016/0304-4076(69)41685-7}
{break}{it:The closest precedent: also an infimum of an ADF statistic over an
unknown date. They hold the estimation sample fixed and vary the form of the
regression; here the form is fixed and the estimation window varies.}

{marker Hansen1992}{...}
{phang}
Hansen, B. E. 1992. Efficient estimation and testing of cointegrating vectors in
the presence of deterministic trends. {it:Journal of Econometrics} 53: 87-121.
{break}{it:Deterministic versus stochastic cointegration: why Case ct is required
for drifting series.}

{marker KV2026}{...}
{phang}
Kvist, O., and J. E. Vera-Valdes. 2026. Cointegration by Parts: Locating
Cointegration in Time. Submitted to {it:Econometric Reviews}, Special Issue in
Honor of James G. MacKinnon.
{browse "https://arxiv.org/abs/2609.10020":arXiv:2609.10020}
{break}{it:The paper this command implements.}

{marker MacKinnon1994}{...}
{phang}
MacKinnon, J. G. 1994. Approximate Asymptotic Distribution Functions for
Unit-Root and Cointegration Tests. {it:Journal of Business & Economic Statistics}
12: 167-176.
{browse "https://doi.org/10.2307/1391481":doi:10.2307/1391481}
{break}{it:Equation (4.19): interpolation linear in the normal quantile of p.}

{marker MacKinnon2010}{...}
{phang}
MacKinnon, J. G. 2010. Critical Values for Cointegration Tests. Queen's Economics
Department Working Paper No. 1227.
{break}{it:The response-surface form (4.18) and the Case n/c/ct indexing.}

{marker Paulsen1984}{...}
{phang}
Paulsen, J. 1984. Order Determination of Multivariate Autoregressive Time Series
with Unit Roots. {it:Journal of Time Series Analysis} 5: 115-127.
{browse "https://doi.org/10.1111/j.1467-9892.1984.tb00381.x":doi:10.1111/j.1467-9892.1984.tb00381.x}
{break}{it:BIC order consistency survives unit roots (remark A.1).}

{marker PO1990}{...}
{phang}
Phillips, P. C. B., and S. Ouliaris. 1990. Asymptotic Properties of Residual Based
Tests for Cointegration. {it:Econometrica} 58: 165-193.
{browse "https://doi.org/10.2307/2938339":doi:10.2307/2938339}
{break}{it:The invariance result lemma A.5 parallels.}

{marker PSY2015a}{...}
{phang}
Phillips, P. C. B., S. Shi, and J. Yu. 2015a. Testing for Multiple Bubbles:
Historical Episodes of Exuberance and Collapse in the S&P 500.
{it:International Economic Review} 56: 1043-1078.
{browse "https://doi.org/10.1111/iere.12132":doi:10.1111/iere.12132}

{phang}
Phillips, P. C. B., S. Shi, and J. Yu. 2015b. Testing for Multiple Bubbles: Limit
Theory of Real-Time Detectors. {it:International Economic Review} 56: 1079-1134.
{browse "https://doi.org/10.1111/iere.12131":doi:10.1111/iere.12131}
{break}{it:The window families and the form of (A.5) are adapted from these two.}

{marker Said1984}{...}
{phang}
Said, S. E., and D. A. Dickey. 1984. Testing for unit roots in
autoregressive-moving average models of unknown order. {it:Biometrika} 71:
599-607.
{browse "https://doi.org/10.1093/biomet/71.3.599":doi:10.1093/biomet/71.3.599}
{break}{it:The p -> infinity, p^3/T -> 0 condition in assumption 3.1(ii).}

{marker Schmith2012}{...}
{phang}
Schmith, T., S. Johansen, and P. Thejll. 2012. Statistical Analysis of Global
Surface Temperature and Sea Level Using Cointegration Methods.
{it:Journal of Climate} 25: 7822-7833.
{browse "https://doi.org/10.1175/JCLI-D-11-00598.1":doi:10.1175/JCLI-D-11-00598.1}
{break}{it:Fixes the normalization in the application through weak exogeneity.}

{marker Schwert1989}{...}
{phang}
Schwert, G. W. 1989. Tests for Unit Roots: A Monte Carlo Investigation.
{it:Journal of Business & Economic Statistics} 7: 147-159.
{browse "https://doi.org/10.2307/1391432":doi:10.2307/1391432}
{break}{it:The maximum-lag rule, applied here to the window length.}

{phang}
Schwarz, G. 1978. Estimating the Dimension of a Model. {it:The Annals of
Statistics} 6: 461-464.
{browse "https://doi.org/10.1214/aos/1176344136":doi:10.1214/aos/1176344136}

{marker Thompson2008}{...}
{phang}
Thompson, D. W. J., J. J. Kennedy, J. M. Wallace, and P. D. Jones. 2008. A large
discontinuity in the mid-twentieth century in observed global-mean surface
temperature. {it:Nature} 453: 646-649.
{browse "https://doi.org/10.1038/nature06982":doi:10.1038/nature06982}
{break}{it:The 1945 sea surface temperature discontinuity the application's
window coincides with.}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
