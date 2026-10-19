{smcl}
{* *! version 1.0.0  17oct2026}{...}
{vieweralsosee "lassour" "help lassour"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "bootur" "help bootur"}{...}
{viewerjumpto "Overview" "lassour_methods##overview"}{...}
{viewerjumpto "The model" "lassour_methods##model"}{...}
{viewerjumpto "The adaptive Lasso and the activation knot" "lassour_methods##knot"}{...}
{viewerjumpto "The test statistics" "lassour_methods##stats"}{...}
{viewerjumpto "The J statistic and the enriched weight" "lassour_methods##J"}{...}
{viewerjumpto "A documented discrepancy" "lassour_methods##discrep"}{...}
{viewerjumpto "Deterministic components" "lassour_methods##det"}{...}
{viewerjumpto "Lag selection (RSMAIC)" "lassour_methods##rsmaic"}{...}
{viewerjumpto "The sieve wild bootstrap" "lassour_methods##boot"}{...}
{viewerjumpto "Step to equation map" "lassour_methods##map"}{...}
{viewerjumpto "Numerical validation" "lassour_methods##valid"}{...}
{viewerjumpto "Limitations" "lassour_methods##limits"}{...}
{viewerjumpto "Author" "lassour_methods##author"}{...}

{title:Title}

{phang}
{bf:lassour methods} {hline 2} methods and formulas for {helpb lassour}


{marker overview}{...}
{title:Overview}

{pstd}
This page documents exactly what {helpb lassour} computes and where each
quantity comes from in the source papers. Throughout:

{phang2}
{bf:[T]} = Arnold and Reinschluessel (2026), {it:Bootstrap Adaptive Lasso}
{it:Solution Path Unit Root Tests}, arXiv:2409.07859v2 {hline 1} the target
paper.

{phang2}
{bf:[AR24]} = Arnold and Reinschluessel (2024), arXiv:2404.06205v3 {hline 1}
defines the statistics, Definition 1, Algorithm 1 and the critical values.

{pstd}
Equation numbers in parentheses refer to {bf:[T]} unless stated otherwise.


{marker model}{...}
{title:The model}

{pstd}
The series is generated as, {bf:[T]} eq. (1),

{p 8 8 2}
{it:y(t) = z(t)'beta + x(t)},   {it:x(t) = rho x(t-1) + u(t)},
{it:t = 0, ..., T}

{pstd}
with {it:z(t)} an {it:m}th order deterministic component. The series has a
unit root when {it:rho = 1} and is stationary when {it:|rho| < 1}. Note the
sample runs from {it:t = 0}, so {it:T+1} values are observed and the ADF
regression has {it:T} rows.

{pstd}
Testing is based on the approximating ADF({it:p}) regression,
{bf:[T]} eq. (3),

{p 8 8 2}
{it:D y(t) = rho* y(t-1) + sum_j theta*(j) D y(t-j) + eps*(t)}

{pstd}
where {it:D} is the first-difference operator and
{it:rho* = rho - 1} in {it:(-2, 0]}. The hypotheses are

{p 8 8 2}
{bf:H0}: {it:rho* = 0} (unit root)   against
{bf:H1}: {it:rho*} in {it:(-2, 0)} (stationary).

{pstd}
Errors satisfy a linear-process condition ({bf:[T]} Assumption 1). Crucially,
{bf:[T]} replaces the constant-variance Assumption 2 with Assumption 2',
which allows the unconditional volatility to be any non-stochastic cadlag
function of {it:t/T}: variance breaks, polynomial trends and smooth
transitions are all permitted. That is what the bootstrap is for.


{marker knot}{...}
{title:The adaptive Lasso and the activation knot}

{pstd}
{bf:The penalised objective}, {bf:[T]} eq. (4):

{p 8 8 2}
{it:sum_t ( D y(t) - rho y(t-1) - sum_j theta(j) D y(t-j) )^2}
{it: + 2 lambda ( w1^g1 |rho| + sum_j w2(j)^g2 |theta(j)| )}

{pstd}
with {bf:adaptive weights} formed from the initial OLS fit of eq. (3),

{p 8 8 2}
{it:w1 = 1 / |rho-hat|},   {it:w2(j) = 1 / |theta-hat(j)|}.

{pstd}
{bf:The factor 2 lambda is not cosmetic.} Differentiating the sum of squares
produces a factor 2 that cancels it, so the Karush-Kuhn-Tucker entry
condition is {it:lambda w(i) = |x(i)' r|} with no extra one-half and no
division by {it:T}. {cmd:lassour} therefore computes entry penalties as
{it:|x(i)' r| / w(i)}. Using any other convention rescales every statistic.

{pstd}
{bf:The activation knot}, {bf:[AR24]} Definition 1. Along the solution path
the coefficient functions are piecewise linear in {it:lambda}; the
{it:earliest} (largest-{it:lambda}) point at which {it:x(i)} becomes active is

{p 8 8 2}
{it:lambda0(i) = max}{c 123} {it:lambda} : {it:d+ b(i)(lambda) = 0} and
{it:d- b(i)(lambda) != 0} and {it:b(i)(lambda) = 0} {c 125}

{pstd}
For the lagged level this evaluates to

{p 8 8 2}
{it:lambda0 = w1^(-g1) | sum_t y(t-1) ( D y(t) - sum_j theta-dot(j) D y(t-j) ) |}

{pstd}
where the {it:theta-dot(j)} are the path coefficients {it:at that knot}. This
is a genuine path computation, not a closed form, except when {it:p = 0}.

{pstd}
{bf:How lassour computes it.} The design is rescaled column by column as
{it:x-tilde(i) = x(i) / w(i)}, which turns the weighted problem into a plain
Lasso whose entry condition is {it:|x-tilde(i)' r| = lambda}. A LARS-Lasso
{it:homotopy} is then run in the {it:lambda} parameterisation. With active set
{it:A}, signs {it:s}, and {it:G = X-tilde(A)' X-tilde(A)}:

{p 8 8 2}
{it:b(A)(lambda) = G^(-1) X-tilde(A)' Y - lambda G^(-1) s}

{p 8 8 2}
{it:c(j)(lambda) = d(j) + lambda e(j)} for inactive {it:j}

{pstd}
so a {bf:join} happens at {it:lambda = d(j)/(1 - e(j))} or
{it:-d(j)/(1 + e(j))}, and a {bf:drop} (the Lasso sign-change modification of
Efron et al. 2004, sec. 3.1) at
{it:lambda = b(A,i)^(ols) / (G^(-1) s)(i)}. The algorithm takes the largest
event penalty strictly below the current one and {bf:stops as soon as the}
{bf:lagged level joins}, which is all the test needs and makes the bootstrap
affordable.

{pstd}
No column standardisation and no intercept are applied: the data are already
adjusted for deterministics, and standardising would change the knot.

{pstd}
{bf:Why the SSC command} {helpb lars} {bf:cannot be used.} Mander's {cmd:lars}
is a partial port that returns only step indices, RSS, R-squared, Mallows' Cp
and coefficients. It returns no penalty values, so {it:tau} cannot be formed,
and it accepts no per-variable penalty weights, so the {it:adaptive} Lasso
cannot be fitted at all. {cmd:lassour} therefore ships its own Mata engine.


{marker stats}{...}
{title:The test statistics}

{pstd}
{bf:[T]} adopts {it:g1 = g2 = 1}, which avoids having to adjust for
{it:phi(1)}. Then {it:T^(1-g1) = 1} and, with {bf:[AR24]} eq. (22),

{p 8 8 2}
{it:tau   = lambda0  / sigma2-hat}

{p 8 8 2}
{it:tauIE = lambda0~ / sigma2-hat}

{p 8 8 2}
{it:sigma2-hat = (T - p - 1)^(-1) sum_t eps-hat(p,t)^2}

{pstd}
where {it:lambda0~} is the knot computed with the enriched weight and the
residuals are those of the OLS penalty-weight regression. Limiting null
distributions, {bf:[T]} eq. (8):

{p 8 8 2}
{it:tau   -> ( W(c,1)^2 - 1 )^2 / ( 4 int W(c,r)^2 dr )}

{p 8 8 2}
{it:tauIE -> (1/J(alpha,c)) ( W(c,1)^2 - 1 )^2 / ( 4 int W(c,r)^2 dr )}

{pstd}
with {it:W(c, .)} an Ornstein-Uhlenbeck process. Both are
{bf:right-sided} tests.

{pstd}
{bf:A useful sanity check.} At {it:p = 0} the path has a single column, so the
knot is available in closed form and

{p 8 8 2}
{it:tau = ( sum_t y(t-1) D y(t) )^2 / ( sum_t y(t-1)^2 * sigma2-hat )}

{pstd}
Substituting the standard limits
{it:sum y D y -> T sigma^2 (W(1)^2-1)/2} and
{it:sum y^2 -> T^2 sigma^2 int W^2} reproduces eq. (8) exactly. {cmd:lassour}
is checked against this identity to machine precision.


{marker J}{...}
{title:The J statistic and the enriched weight}

{pstd}
{bf:Information enrichment} sharpens the penalty on the lagged level using a
statistic that is itself informative about {it:rho*}. Following
{bf:[AR24]} Algorithm 1 (after Herwartz and Siedenburg 2010):

{phang2}
{bf:1.} Adjust {it:y(t)} for the deterministic component, then estimate the
long-run variance by the autoregressive estimator

{p 12 12 2}
{it:omega-hat^2 = sigma-hat(k)^2 / ( 1 - sum_j delta-hat(j) )^2},
{it:sigma-hat(k)^2 = (T-k)^(-1) sum_t e-hat(t,k)^2}

{phang2}
{bf:2.} Scale {it:y(t)} by {it:omega-hat^(-1)}.

{phang2}
{bf:3.} Form the {bf:range} statistic
{it:J(alpha) = zeta-hat(1-alpha/2) - zeta-hat(alpha/2)}, the inter-quantile
range of the simulated OLS slopes {it:zeta-hat(r)} in

{p 12 12 2}
{it:y(t) = mu(r) + varsigma(r) t + zeta(r) x(r,t) + nu(r,t)},
{it:r = 1, ..., R}

{p 12 12 2}
where each {it:x(r,.)} is an independent Gaussian random walk with zero
initial condition. Published tuning: {it:alpha = .1}, {it:R = 150}, computed
on OLS-adjusted data.

{phang2}
{bf:4.} Form the enriched weight (see the next section).

{pstd}
{cmd:lassour} computes step 3 by Frisch-Waugh:
{it:zeta-hat(r) = (x-tilde(r)' y-tilde) / (x-tilde(r)' x-tilde(r))} with both
residualised on {it:(1, t)}. All {it:R} walks are drawn and projected in one
pass, which is algebraically identical to running {it:R} regressions but far
faster.

{pstd}
{bf:Why J is informative.} If {it:y} has a unit root it is a spurious
regression on an independent random walk, so {it:zeta-hat = O(1)} and the
range is wide. If {it:y} is stationary then
{it:zeta-hat = O(T^(-3/2))}, so the range collapses. Hence
{bf:J is large under H0 and small under H1}.


{marker discrep}{...}
{title:A documented discrepancy in the source papers}

{pstd}
{bf:The enriched weight is printed two different ways in [AR24]}, and the two
are reciprocals. {cmd:lassour} implements

{p 8 8 2}
{bf:w1-breve = J(alpha) / |rho-hat|}

{pstd}
{bf:Evidence for this form} (four places):

{phang2}
{bf:(i)} {bf:[AR24]} main text: "the enriched weight
{it:w1-breve = |rho-hat/J(alpha)|^(-1)} scales {it:w1} ...".

{phang2}
{bf:(ii)} {bf:[AR24]} restatement of Definition 1: "computed using the
adaptive weights {it:w1-breve = |rho-hat/J(alpha)|^(-1)}".

{phang2}
{bf:(iii)} {bf:[AR24]} simulation table headers:
"{it:w1-breve = |J(alpha)/rho-hat|}" and
"weight {it:w1-breve = (rho-hat/J(alpha))^(-1)}".

{phang2}
{bf:(iv)} {bf:[T]} main text: "information enrichment of {it:w1} proceeds as
{it:w1-breve = w1 * J(alpha)}"; since {it:w1 = 1/|rho-hat|} this is
{it:J(alpha)/|rho-hat|}.

{pstd}
{bf:[AR24] Appendix B, Algorithm 1, step 4 prints}
"{it:w1-breve := |rho-hat/J(alpha)|}", {bf:dropping the exponent -1}. Taken
literally that is the reciprocal of the four statements above.

{pstd}
{bf:Three independent confirmations that the appendix line is a typo:}

{phang2}
{bf:(a)} {bf:Asymptotics.} Eq. (7) states
{it:tauIE -> T(c,g1) / J(alpha,c)} and eq. (8) likewise {it:divides} by
{it:J}. Only {it:w1-breve = J/|rho-hat|} delivers that, because the knot
enters as {it:w1-breve^(-1)}.

{phang2}
{bf:(b)} {bf:Power direction.} Under H1, {it:J} is small and
{it:|rho-hat|} is bounded away from zero, so {it:J/|rho-hat|} is small, the
knot {it:lambda0~ = w1-breve^(-1) |.|} is large, and the right-sided test
rejects. The appendix form reverses this and would destroy power.

{phang2}
{bf:(c)} {bf:Numerical.} Simulating 5% critical values for Gaussian random
walks under FD-constant adjustment:

{cmd}
      orientation             T=50    T=100   T=250   T=1000   published
      J/|rho-hat|             5.04     5.39    5.66     5.13    5.32-5.65
      |rho-hat|/J             5907    22151  140264  2337861    5.32-5.65
{txt}

{p 6 6 2}
The appendix orientation is wrong by three to six orders of magnitude and
diverges in {it:T}. The implemented orientation reproduces the published
values.

{pstd}
{bf:A second, genuinely open choice.} {bf:[AR24]} Algorithm 1 step 1 says only
"for suitable {it:k}" and never specifies the long-run-variance lag. Since
{it:tauIE} is proportional to {it:omega-hat}, which rises with {it:k}, the
published {it:tauIE} critical values cannot be reproduced exactly without it.
A sweep at the 5% level under FD-constant adjustment gives:

{cmd}
      T          k=0     k=1     k=2     Schwert   published
      100       5.19    5.35    5.45     5.72        5.49
      1000      5.20    5.37    5.37     5.77        5.65
{txt}

{pstd}
No single fixed {it:k} matches both sample sizes, which suggests the authors
used a data-dependent rule. {cmd:lassour} therefore

{phang2}
{bf:1.} defaults to {it:k = p} and exposes {opt lrvlags()};

{phang2}
{bf:2.} reports the {bf:authors' published} critical values in
{opt nobootstrap} mode rather than its own simulated ones, so the asymptotic
test is exactly as calibrated as the source paper; and

{phang2}
{bf:3.} defaults to the bootstrap, which does not use those critical values at
all and is therefore unaffected.

{pstd}
{bf:tau is not affected by any of this} {hline 1} it does not involve {it:J}.


{marker det}{...}
{title:Deterministic components}

{pstd}
Both source papers use {bf:first-difference (FD) detrending}
(Schmidt and Phillips 1992), applied {it:before} the Lasso solution is
computed. From the notes to {bf:[AR24]} Table D1:

{p 8 8 2}
{cmd:constant}: {it:y(t) - y(1)}

{p 8 8 2}
{cmd:trend}:    {it:y(t) - y(1) - ((t-1)/(T-1)) ( y(T) - y(1) )}

{pstd}
The {it:J} statistic is instead computed on {bf:OLS}-adjusted data, and its
auxiliary regression always includes both a constant and a trend, as
Algorithm 1 writes it.

{pstd}
{bf:A consistency check worth knowing.} Because the sample starts at
{it:t = 0} with {it:x(0) = 0}, FD-constant adjustment is a no-op for a pure
random walk. That is exactly why {bf:[AR24]} Table 1 (no adjustment) and
Table D1 (FD constant) are numerically almost identical, and it is how the
sample convention was verified during development.


{marker rsmaic}{...}
{title:Lag selection (RSMAIC)}

{pstd}
{bf:[T]} Remark 1 uses the {bf:RSMAIC} of Cavaliere, Phillips, Smeekes and
Taylor (2015) throughout. The modified criteria of Ng and Perron (2001) are

{p 8 8 2}
{it:MIC(k) = ln sigma-hat(k)^2 + ( k C(T) + tau(T,k) ) / n},
{it:tau(T,k) = sigma-hat(k)^(-2) rho-hat^2 sum_t y(t-1)^2}

{pstd}
with {it:C(T) = 2} for MAIC and {it:C(T) = ln n} for MBIC. The comparison
sample is held fixed at {it:t = pmax+1, ..., T} for every {it:k} so the
criteria are comparable.

{pstd}
The {bf:RS} (re-scaled) variants do not change the criterion; they change its
{it:input}. The volatility is estimated nonparametrically by the local
constant (Nadaraya-Watson) estimator, CPST eq. (6),

{p 8 8 2}
{it:omega-hat^2(r) = sum_t K((t/T - r)/h) e(t)^2 / sum_t K((t/T - r)/h)}

{pstd}
with a Gaussian kernel and {it:h = 0.1}, and the series is then re-scaled,
CPST eq. (7),

{p 8 8 2}
{it:y-tilde(t) = sum_(s<=t) D y(s) / sigma-hat(s)},   {it:y-tilde(0) = 0}

{pstd}
which renders it approximately homoskedastic before the criterion is applied.
This stops a variance break from inflating the selected lag order, which is
the whole point of RSMAIC. The implementation deliberately mirrors
{helpb bootur}'s {cmd:bu_npve()} so the two commands agree.

{pstd}
{bf:Which series the criterion sees:} a second unspecified choice. Perron and
Qu (2007), adopted by CPST, recommend applying the criterion to
{bf:OLS}-detrended data. The {cmd:lassour} test itself uses {bf:FD}
detrending, and the source paper does not say which transform feeds the
criterion. {opt icdetrend()} exposes the choice and defaults to {cmd:ols},
for three reasons: it is the convention of the cited source, it makes
{cmd:lassour} agree with {helpb bootur} on the selected lag, and it does not
over-fit the lag order on a pure random walk. Empirical size and power are
equivalent under the two:

{cmd}
      design                        icdetrend(ols)      icdetrend(fd)
                                    tau     tauIE       tau     tauIE
      ----------------------------------------------------------------
      T=75,  i.i.d., constant      0.040   0.033       0.040   0.033
      T=100, i.i.d., constant      0.043   0.053       0.043   0.053
      T=100, i.i.d., trend         0.040   0.037       0.043   0.040
      T=100, volatility shift up   0.057   0.040       0.057   0.040
      T=100, c = -7 (power)        0.384   0.332       0.388   0.332
      ----------------------------------------------------------------
{txt}

{p 6 6 2}
300 Monte Carlo replications (250 for power), {it:B} = 199, nominal 5%. The
two can still select a different lag on an individual series, so state which
you used.


{marker boot}{...}
{title:The sieve wild bootstrap}

{pstd}
{bf:[T]} Algorithm 1, implemented verbatim:

{phang2}
{bf:1.} FD-adjust the series for {it:z(t)}, giving {it:y-d(t)}.

{phang2}
{bf:2.} Choose {it:q} and fit eq. (3) by OLS at lag {it:q}, giving residuals
{it:eps-hat-d(q,t)}, {it:t = 1..T}, with the initial lagged differences
{bf:set to zero} rather than dropped (as eq. (15) prescribes), so a full
{it:T} residuals are available. Compute the observed {it:tau} (and
{it:tauIE}).

{phang2}
{bf:3.} Draw wild innovations {it:eps*(t) = eta(t) eps-hat-d(q,t)} with
{it:eta(t)} i.i.d., mean 0, variance 1. {cmd:lassour} uses {bf:Gaussian}
multipliers: {bf:[T]} Remark 3 reports that Rademacher and Mammen's
two-point distribution give no significant difference.

{phang2}
{bf:4.} {bf:Recolour} with the estimated sieve dynamics,
{it:u*(t) = sum_j theta-hat(q,j) u*(t-j) + eps*(t)}, initialised at zero, and
cumulate to {it:y*(t) = sum_(i<=t) u*(i)} with {it:y*(0) = 0}. Recolouring is
what makes the bootstrap reproduce the effect of stationary serial
correlation; see {bf:[T]} eq. (14) and Smeekes and Taylor (2012).

{phang2}
{bf:5.} Re-adjust {it:y*} exactly as in step 1, {bf:re-select the lag order}
{it:p*} and recompute the statistic, giving {it:tau*(b)}.

{phang2}
{bf:6.} The level-{it:alpha} critical value is
{it:max}{c 123}{it:x : B^(-1) sum_b I(x < tau*(b)) >= alpha}{c 125}, eq. (17),
and H0 is rejected when it does not exceed the observed statistic.
Equivalently the p-value is {it:B^(-1) sum_b I(tau*(b) >= tau)}.

{pstd}
{bf:Two fidelity points that a resampling test gets wrong easily.} The
bootstrap must replicate the {it:whole} observed statistic. In every
replication {cmd:lassour} therefore

{phang2}
{bf:(a)} {bf:re-estimates the adaptive penalty weights} from the bootstrap
sample, and

{phang2}
{bf:(b)} {bf:re-selects the lag order} by the same criterion.

{pstd}
Freezing either at its observed value ignores the selection advantage the
observed statistic enjoys and makes the test over-reject. {bf:[T]} Remark 1
additionally notes that selecting {it:p*} independently of {it:p} and {it:q}
helps control upward size distortion under a large negative MA component.

{pstd}
The residuals are recentred before resampling, following
Chatterjee and Lahiri (2011).


{marker map}{...}
{title:Step to equation map}

{pstd}
Every computational block of {cmd:lassour} against its source:

{cmd}
    Mata function        does                          source
    ------------------------------------------------------------------------
    lsr_fd()             FD detrending                 SP92; [AR24] Tab. D1
    lsr_olsadj()         OLS adjustment for J          [AR24] Alg. 1 step 1
    lsr_adf()            ADF(p) design, zero-padded    [T] eq. (3), (15)
    lsr_knot1()          LARS-Lasso homotopy, first
                         activation knot               [AR24] Def. 1; EHJT
    lsr_npve()           Nadaraya-Watson volatility    CPST eq. (6)
    lsr_rescale()        volatility re-scaling         CPST eq. (7)
    lsr_ic()             (RS)(M)AIC / (M)BIC           NP01; CPST sec. 3.3
    lsr_lagsel()         lag order selection           [T] Remark 1
    lsr_J()              J(alpha) range statistic      [AR24] Alg. 1; HS10
    lsr_stats()          weights, sigma2-hat, tau,
                         tauIE                         [T] eq. (4), (8)
    lsr_boot()           sieve wild bootstrap          [T] Algorithm 1
    lsr_cvmat()          published critical values     [AR24] Tab. 1, D1
    ------------------------------------------------------------------------
{txt}

{pstd}
{bf:Why the engine ships as a library.} The Mata code lives in a compiled
library, {cmd:llassour.mlib}, rather than inside {cmd:lassour.ado}. Some
packages {hline 1} {helpb bootur} among them {hline 1} issue
{cmd:mata clear}, which drops embedded Mata functions while leaving the ado
program in memory, so the next call fails with
{cmd:lsr_main() not found}. Functions resolved from a {cmd:.mlib} on the
adopath are re-found automatically, so {cmd:lassour} and {cmd:bootur} can be
used in the same session in any order. The source and its build script are in
{cmd:lassour_mata.do}; rebuild with {cmd:do lassour_mata.do}.


{marker valid}{...}
{title:Numerical validation}

{pstd}
{cmd:lassour} was validated against every number the source papers publish.

{pstd}
{bf:1. Closed form at p = 0.} The engine reproduces
{it:(sum y D y)^2 / (sum y^2 sigma2-hat)} to 1.1e-16.

{pstd}
{bf:2. The limiting distribution.} Simulated quantiles of
{it:(W(1)^2-1)^2/(4 int W^2)}: 6.93 (1%), 4.11 (5%), 2.96 (10%), against the
{it:T} = 1000 row of {bf:[AR24]} Table 1: 6.97, 4.13, 2.97.

{pstd}
{bf:3. Finite-sample critical values for tau}, 40000 replications against
{bf:[AR24]} Tables 1 and D1 (published 500000 replications). All differences
at the 5% and 10% levels fall within +/- 0.11, mixed in sign, consistent with
Monte Carlo error:

{cmd}
      5% level, T =        50    75   100   150   250   500  1000
      no adjustment    -0.10 -0.03 -0.08 +0.01 -0.03 -0.00 -0.04
      FD constant      -0.05 -0.10 -0.05 -0.07 +0.02 +0.05 +0.01
      FD trend         -0.11 -0.11 -0.08 -0.02 +0.08 +0.06 -0.06
{txt}

{p 6 6 2}
This single check simultaneously pins the adaptive weights, the
{it:2 lambda} convention, the knot definition, {it:sigma2-hat}, both FD
transforms and the sample convention.

{pstd}
{bf:4. The tauIE orientation.} See
{help lassour_methods##discrep:the discrepancy section} above.

{pstd}
{bf:5. Bootstrap size and power}, 400 Monte Carlo replications, {it:B} = 199,
nominal 5%, DGP (18) of {bf:[T]}:

{cmd}
      design                            tau    tauIE   paper [T] Tab. 1
      ------------------------------------------------------------------
      T=75,  i.i.d., constant          0.048   0.045   0.049 / 0.046
      T=100, i.i.d., constant          0.043   0.055   approx. 0.05
      T=100, i.i.d., trend             0.040   0.035   approx. 0.05
      T=100, volatility shift down     0.037   0.048   size controlled
      T=100, volatility shift up       0.058   0.045   size controlled
      T=100, c = -7,  constant         0.400   0.347   (power)
      T=100, c = -13.5, trend          0.363   0.337   (power)
      ------------------------------------------------------------------
{txt}

{p 6 6 2}
The volatility rows use the logistic smooth transition of {bf:[T]} eq. (20)
and confirm the paper's central claim: the bootstrap keeps size under control
when the unconditional variance shifts, where fixed critical values fail.


{marker limits}{...}
{title:Limitations}

{pstd}
{bf:1.} Published critical values exist only for FD adjustment and for
{it:T} in {c 123}50, ..., 1000{c 125}. {cmd:lassour} interpolates linearly in
{it:T} and holds the end values flat outside the grid. Off-grid or other
designs should use the bootstrap.

{pstd}
{bf:2.} {it:tauIE} is random even in {opt nobootstrap} mode because {it:J} is
simulated, and it depends on the unspecified {opt lrvlags()}. Report
{opt seed()}.

{pstd}
{bf:3.} Only {opt level(90)}, {opt level(95)} and {opt level(99)} are
tabulated for {opt nobootstrap}; other levels fall back to the 95% column.
Bootstrap p-values are unaffected.

{pstd}
{bf:4.} {bf:[T]} Remark 2 sketches an adaptive-Lasso fallback for the sieve
residuals when OLS is infeasible ({it:p} >= {it:T}, or collinearity).
{cmd:lassour} does not implement it and errors with a clear message instead,
matching the paper's own view that OLS residuals are preferable when
feasible.

{pstd}
{bf:5.} The source papers provide a test, not a confidence interval for
{it:rho*}. None is reported.

{pstd}
{bf:6.} The series fed to the information criterion is an unspecified choice
in the source paper; see {opt icdetrend()} above.

{pstd}
{bf:7.} A single series at a time. For many series, loop (see
{helpb lassour##examples:help lassour}); for joint and panel bootstrap unit
root testing with multiple-testing control, see {helpb bootur}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb lassour}, {helpb bootur}, {helpb dfgls}, {helpb dfuller}
{p_end}
