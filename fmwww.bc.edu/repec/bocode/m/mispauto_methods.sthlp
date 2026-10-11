{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto thursby" "help mispauto_thursby"}{...}
{vieweralsosee "mispauto godfrey" "help mispauto_godfrey"}{...}
{vieweralsosee "mispauto ghutton" "help mispauto_ghutton"}{...}
{vieweralsosee "mispauto knottnerus" "help mispauto_knottnerus"}{...}
{viewerjumpto "The map" "mispauto_methods##map"}{...}
{viewerjumpto "Thursby (1981)" "mispauto_methods##thursby"}{...}
{viewerjumpto "Knottnerus (1985)" "mispauto_methods##knott"}{...}
{viewerjumpto "Godfrey (1987)" "mispauto_methods##godfrey"}{...}
{viewerjumpto "Godfrey and Hutton (1994)" "mispauto_methods##gh"}{...}
{viewerjumpto "Supporting algorithms" "mispauto_methods##support"}{...}
{viewerjumpto "Equivalences verified" "mispauto_methods##equiv"}{...}
{viewerjumpto "Decisions the papers leave open" "mispauto_methods##decisions"}{...}
{viewerjumpto "Limitations" "mispauto_methods##limits"}{...}
{viewerjumpto "References" "mispauto_methods##refs"}{...}

{title:Title}

{phang}
{bf:mispauto methods} {hline 2} Derivations, and the map from each step of the
code to the equation it implements


{marker map}{...}
{title:How to read this page}

{pstd}
Every computation {cmd:mispauto} performs is listed below against the numbered
equation, lemma or algorithm step of the source paper that defines it. Where a
cheaper but algebraically equivalent form is used, the equivalence is stated
and, where possible, verified numerically against a Stata built-in. Where a
paper leaves a choice open, the choice made and the reason are recorded under
{help mispauto_methods##decisions:Decisions}.

{pstd}
Throughout, the maintained model is

{p 12 12 2}
{cmd:(1)   y(t) = x(t)'b + e(t),      t = 1, ..., T}

{pstd}
with {cmd:k} regressors and an intercept.


{marker thursby}{...}
{title:Thursby (1981): DW, RESET and LRS}

{pstd}
{bf:Step T1 -- the Durbin{c 150}Watson statistic on (1).}
{cmd:d = sum (e(t)-e(t-1))^2 / sum e(t)^2} computed from the OLS residuals of
(1). Thursby runs it at a nominal level and reads a significant value as
"nonrandom disturbances or misspecification". The p-value is obtained exactly;
see {help mispauto_methods##support:Supporting algorithms}.

{pstd}
{bf:Step T2 -- RESET on (1).} An F test of {cmd:theta = 0} in the augmented
regression of Thursby's section II.A,

{p 12 12 2}
{cmd:y(t) = x(t)'b + z(t)'theta + e(t)}

{pstd}
where {cmd:z(t)} holds the squares, cubes and fourth powers of the explanatory
variables. Thursby adopts this set on the authority of Thursby and Schmidt
(1977), whose section 4 compares it with three others; it is {cmd:resetvars(pox)}
here and is the default. Thursby notes that a degrees-of-freedom problem can
arise when {cmd:k} is large and that {cmd:z} should then be reduced to squares
and cubes, or to squares alone; the command does this automatically and reports
the set used.

{pstd}
{bf:Step T3 -- the unrestricted transformed equation, Thursby's (2).}
Substituting {cmd:e(t) = rho*e(t-1) + u(t)} into (1) and relaxing the implied
restrictions gives

{p 8 12 2}
{cmd:(2)   y(t) = b0 + sum b(i) x(i,t) + sum b(k+i) x(i,t-1) + b(2k+1) y(t-1) + u(t)}

{pstd}
estimated by OLS. The AR(1) hypothesis is the set of {cmd:k} nonlinear
restrictions

{p 8 12 2}
{cmd:(3)   b(i)*b(2k+1) + b(k+i) = 0,    i = 1, ..., k}

{pstd}
{bf:Step T4 -- Durbin's S-test on (2).} Thursby's section II.B step 1 regresses
the residuals of (2) on {cmd:u(t-1)} {it:and the right-hand-side variables of
(2)}, and tests the significance of the coefficient on {cmd:u(t-1)}. That is
exactly what {helpb regress postestimation time series##durbinalt:estat durbinalt}
computes at {cmd:lags(1)}, so the built-in is called rather than reimplemented.
A significant value rejects the null immediately.

{pstd}
{bf:Step T5 -- the restricted fit.} Thursby's step 3 writes the restricted
estimation explicitly as Durbin's procedure: with {cmd:b(2k+1)} taken from (2),
regress

{p 12 12 2}
{cmd:y(t) - b(2k+1) y(t-1)  on  x(i,t) - b(2k+1) x(i,t-1)}

{pstd}
and take the residual sum of squares. Thursby reports that it made almost no
difference whether Cochrane{c 150}Orcutt or Durbin's procedure was used;
{opt rtemethod()} exposes both, with Durbin's as the default because it is the
one the paper writes down.

{pstd}
{bf:Step T6 -- the likelihood ratio, Thursby's (4).}

{p 12 12 2}
{cmd:LR = -T * ln( S2u / S2r )}

{pstd}
asymptotically chi-squared with {cmd:k} degrees of freedom, where {cmd:S2u} is
the residual sum of squares from (2) and {cmd:S2r} that from step T5. Because
{cmd:S2r >= S2u}, the statistic is non-negative.

{pstd}
{bf:Step T7 -- the level allocation, Thursby's (6) and (8).} For an overall
level {cmd:a} across the three procedures,

{p 12 12 2}
{cmd:(8)   a* = 1 - (1-a)^(1/3)}

{pstd}
and within the two tests of the LRS procedure the relation
{cmd:(1-a**)a** + a** = a*} of his (6), solved in closed form as

{p 12 12 2}
{cmd:(6)   a** = 1 - sqrt(1 - a*)}

{pstd}
Both rest on the independence of the component tests, which Thursby's section
III establishes by Monte Carlo rather than analytically.

{pstd}
{bf:Step T8 -- the decision rule.} LRS is significant if the S-test is
significant, or if the S-test is insignificant and the LR is significant. With
D, R and L denoting insignificant and D', R', L' significant outcomes, the eight
combinations of Thursby's table on page 118 reduce to: R' implies MS; otherwise
L' implies NAR; otherwise D' implies AR(1); otherwise NP.


{marker knott}{...}
{title:Knottnerus (1985): the blind spots}

{pstd}
{bf:Step K1 -- equation (12).} Knottnerus's section III proves that, for the
probability limits of the OLS estimators of (2),

{p 12 12 2}
{cmd:plim( b(2k+1)*b(i) + b(k+i) ) = 0}

{pstd}
for {it:any} stationary error process, not only an AR(1) one. The restrictions
(3) that Thursby's LR stage tests are therefore satisfied whatever the errors
do, and the asymptotic power of that stage equals its nominal size. The command
reports the sample value of {cmd:b3*b1 + b2} with the standard error from
{helpb nlcom}, and warns whenever it is indistinguishable from zero. The LR
stage is still computed, because the package implements Thursby (1981) as
published and because Thursby's reply notes it can be sensitive to non-AR(1)
processes in small samples; {opt slrs} drops it.

{pstd}
{bf:Step K2 -- equation (15).} Knottnerus shows

{p 12 12 2}
{cmd:plim T^-1 sum u(t) u(t-1) = g1 * ( g2 - g1^2 )}

{pstd}
where {cmd:g(s)} is the autocorrelation of the disturbances at lag {cmd:s}. Two
consequences follow and both are reported:

{phang2}
(i) if {cmd:g1 = 0} the expression vanishes, so Durbin's S-test is
insignificant; and because {cmd:plim d = 2} as well, so is Durbin{c 150}Watson.
Thursby's strategy then returns {bf:NP} however strongly the errors are
autocorrelated. Knottnerus's footnote 1 names pure seasonal autocorrelation as
the leading case.

{phang2}
(ii) if {cmd:g2 = g1^2} with {cmd:g1} non-zero, the S-test is insignificant
while Durbin{c 150}Watson is significant, so genuinely non-AR(1) errors are
labelled {bf:AR(1)}.

{pstd}
{bf:Step K3 -- equation (8).} For an AR(2) error process Knottnerus derives the
correlation between consecutive residuals of (2),

{p 12 12 2}
{cmd:R = -rho1*rho2 / (1 - rho2)}

{pstd}
and notes from his footnote 2 that {cmd:g1 = rho1/(1-rho2)} and
{cmd:g2 = rho2 + rho1*g1}. The command fits an AR(2) to the residuals and
reports all four quantities, which is how his non-monotonic power argument can
be checked on real data.

{pstd}
{bf:Step K4 -- the seasonal check.} An F test of the joint significance of
lags {cmd:s}, {cmd:2s} and {cmd:3s} in a regression of the residual on those
lags alone, where {cmd:s} is the period detected from {helpb tsset}. This is not
in Knottnerus; it is the operational form of the case he identified, and it is
labelled as Godfrey's remedy rather than as his result.


{marker godfrey}{...}
{title:Godfrey (1987): the ordered sequence}

{pstd}
The four hypotheses of his section III, from least to most restrictive:
{bf:(a)} regression function misspecified and errors ARMA of unknown order;
{bf:(b)} regression function correct, errors ARMA of unknown order;
{bf:(c)} regression function correct, errors AR(1);
{bf:(d)} regression function correct, errors independent. Testing proceeds
along the sequence and stops at the first rejection; the last hypothesis not
rejected is adopted. The overall level is at most the sum of the three
component levels, which is why the default allocation is Bonferroni.

{pstd}
{bf:Step G1 -- testing (b), equations (7) to (10).} With
{cmd:W = (X, Z)} and {cmd:theta = (b', alpha')'}, his (9) gives

{p 12 12 2}
{cmd:V(theta) = (W'W)^-1 (W'Omega W) (W'W)^-1}

{pstd}
and his (10) is the Wald statistic

{p 8 12 2}
{cmd:(10)  (R theta)' [ R (W'W)^-1 (W' Sigma_j W) (W'W)^-1 R' ]^-1 (R theta)}

{pstd}
compared with chi-squared on {cmd:m} degrees of freedom, where
{cmd:R = (0, I_m)} and {cmd:Sigma_j} is the White and Domowitz (1984) estimator
whose {cmd:(t,s)} element is {cmd:e(t)e(s)} when {cmd:|t-s| <= j} and zero
otherwise. The middle matrix is formed as

{p 12 12 2}
{cmd:W'Sigma_j W = G(0) + sum_{tau=1}^{j} ( G(tau) + G(tau)' )}

{p 12 12 2}
{cmd:G(tau) = sum_t e(t) e(t-tau) W(t) W(t-tau)'}

{pstd}
which is the same matrix in {cmd:O(j T k^2)} rather than {cmd:O(T^2 k^2)}
operations.

{pstd}
{bf:Step G2 -- testing (c), equations (11) and (18).} The alternative is the
AR(1+q) scheme of his (11). His argument that the estimators of the {cmd:delta}
obtained with {cmd:beta} fixed at {cmd:b} have the same asymptotic distribution
as the full maximum likelihood estimators licenses the simple auxiliary
regression (18),

{p 8 12 2}
{cmd:(18)  e(t) = d(1) e(t-1) + ... + d(1+q) e(t-1-q) + a(t)}

{pstd}
run on the OLS residuals of (1), with an F test of
{cmd:d(2) = ... = d(1+q) = 0}. The AR(p) generalisation replaces {cmd:1} by
{cmd:p} throughout and tests the last {cmd:q} coefficients. Godfrey (1981)
shows the same test is appropriate against ARMA(p,q).

{pstd}
{bf:Equation (18) deliberately excludes the regressors.} Breusch{c 150}Godfrey
and {cmd:estat durbinalt} both include them; Godfrey's derivation does not,
because {cmd:beta} is held at {cmd:b}. The command follows the paper. This is
the single place where {cmd:mispauto} and the familiar Stata built-ins compute
different auxiliary regressions on purpose.

{pstd}
{bf:Step G3 -- testing (d), section III.} A t test of {cmd:rho = 0} in
{cmd:e(t) = rho e(t-1) + a(t)} on the OLS residuals, or the
Durbin{c 150}Watson statistic. Godfrey notes that Knottnerus's criticism of
Durbin{c 150}Watson does not apply here, because in this sequence it is used
only to test (d) against (c) and only after (c) has been accepted.

{pstd}
{bf:Step G4 -- section IV, lagged dependent variables.} When the regressors
include lags of {cmd:y}, the White and Domowitz results are unavailable and
Godfrey imposes an AR(1+q) or ARMA(1,q) error model and tests by likelihood
ratio. {opt lagdep} implements this: {helpb arima} fits the augmented and
restricted models, {helpb lrtest} tests (b) and then (c), and (d) is tested by
Durbin's h. The command requires {cmd:L.}{it:depvar} to be among the regressors
and refuses otherwise.


{marker gh}{...}
{title:Godfrey and Hutton (1994): errors in variables and simultaneity}

{pstd}
{bf:Step H1 -- stage 1, equation (13).} With {cmd:e} the IV residual vector and
{cmd:Z} the full instrument matrix,

{p 12 12 2}
{cmd:(13)  J = n * R2u  ~  chi2(p - k)}

{pstd}
where {cmd:R2u} is the possibly uncentred R-squared from the OLS regression of
{cmd:e} on {cmd:Z}. They note {cmd:J = 0} identically when {cmd:p = k}, so the
command refuses an exactly identified equation with a message saying how many
further instruments are needed. The statistic is obtained from
{helpb ivregress postestimation##overid:estat overid}; the equivalence is
verified below.

{pstd}
{bf:Step H2 -- stage 2, equations (10) and (11).} Hausman's test of
{cmd:Omega = 0}, either as the estimator contrast of their (10) or as the
variable-addition regression of their (11). {opt hausman(contrast)}, the
default, calls the built-in {helpb hausman} on stored OLS and IV fits;
{opt hausman(augmented)} uses
{helpb ivregress postestimation##endogenous:estat endogenous}. The built-in is
called rather than reimplemented because the generalized inverse used when
{cmd:V(b)-V(B)} is not positive definite is pivot-order dependent, and Stata's
degrees-of-freedom convention would not otherwise be reproduced.

{pstd}
{bf:Step H3 -- the overall level, section 2.} They prove that {cmd:J} and
{cmd:H} are asymptotically independent under the stage-2 null, by showing that
the covariance matrix between {cmd:Z'P(X)u} and {cmd:X'u} vanishes because
{cmd:X} satisfies the normal equations and {cmd:Z} contains {cmd:Z1}. Hence

{p 12 12 2}
{cmd:overall level = 1 - (1 - pJ)(1 - pH)}

{pstd}
{bf:Step H4 -- the decision.} A significant {cmd:J} means IV estimates are of
little value and the specification or the instruments must be reconsidered.
An insignificant {cmd:J} with a significant {cmd:H} supports presenting IV; an
insignificant {cmd:H} supports presenting OLS. Their section 2 explains why a
joint test, or separate tests after OLS estimation of their (17), would not
serve the purpose: under the stage-1 null with {cmd:Omega} non-zero those OLS
estimators are inconsistent and the restrictions would be rejected with
probability tending to one.


{marker support}{...}
{title:Supporting algorithms implemented, not merely cited}

{pstd}
{bf:Exact Durbin{c 150}Watson p-values: Imhof (1961).} Stata returns only the
statistic. Writing {cmd:d = e'Ae/e'e} with {cmd:e = My}, under the null

{p 12 12 2}
{cmd:P(d <= d0) = P( sum (lam(i) - d0) * chi2_1(i) <= 0 )}

{pstd}
where the {cmd:lam(i)} are the eigenvalues of {cmd:Q'AQ} and {cmd:Q} is an
orthonormal basis of the range of {cmd:M}, obtained as the eigenvectors of the
idempotent {cmd:M} with unit eigenvalue. Imhof's (3.2) is then inverted
numerically:

{p 8 12 2}
{cmd:F(0) = 1/2 - (1/pi) * integral_0^inf  sin(th(u)) / (u*rh(u))  du}

{p 8 12 2}
{cmd:th(u) = 0.5 * sum atan(h(i) u),    rh(u) = prod (1 + h(i)^2 u^2)^(1/4)}

{pstd}
Two details follow Imhof's own numerical advice rather than convention. First,
the upper limit is {it:computed}, not searched for, from his truncation bound:
with all multiplicities one and {cmd:m} terms, {cmd:kk = m/2} and the tail is
bounded by {cmd:1/(pi*kk*U^kk*prod|h(i)|^(1/2))}, which is solved for {cmd:U}.
Second, the quadrature uses the {bf:trapezoidal} rule, not Simpson's: Imhof
reports that "to achieve a given accuracy, longer steps are permissible with
the trapezoidal rule than with Simpson's rule", and that accuracy degrades as
the degree of the approximating polynomial rises; his Table 1 is computed with
the trapezoid alone. The step is halved until two consecutive results agree, as
he describes. The route needs a {cmd:T} by {cmd:T} eigendecomposition and is
capped by {opt maxtdw()}, above which the large-sample p-value is used and a
note is printed.

{pstd}
{bf:Choosing the truncation lag: White and Domowitz (1984), section 4.} Godfrey
refers to their selection procedure without reproducing it. Their equation (4.2)
regresses, for each lag,

{p 12 12 2}
{cmd:e(t) e(t-tau)  on  psi(tau,t)}

{pstd}
where {cmd:psi(tau,t)} holds the distinct elements of the outer product
{cmd:x(t) x(t-tau)'} -- for a linear regression function the gradient is
{cmd:x(t)} -- and their Theorem 4.2 gives {cmd:(n-tau)*R2_0}, with {cmd:R2_0}
the {it:constant-unadjusted} R-squared, as asymptotically chi-squared. They
offer two rules: a joint test summing the statistics, which is valid because
they are asymptotically independent, and a sequential rule with Bonferroni
bounds because tests at adjacent lags are dependent. {cmd:truncate(auto)}
implements the sequential rule and reports the joint statistic alongside.
Their Theorem 3.5 requires {cmd:l = o(T^(1/3))}, which caps the search.

{pstd}
{bf:Durbin's h: Durbin (1970), equation (11).}

{p 12 12 2}
{cmd:K2 = n * alpha^2 / ( 1 - n * V(b1) )}

{pstd}
where {cmd:alpha} is the coefficient from regressing the OLS residual on its own
lag without a constant and {cmd:V(b1)} is the least-squares variance estimate of
the coefficient on {cmd:y(t-1)} specifically. The procedure requires
{cmd:n*V(b1) < 1}, and the command reports a missing value and says why when it
is not.


{marker equiv}{...}
{title:Equivalences, verified numerically}

{pstd}
{bf:1. Rescaling the regressors before taking powers changes nothing.}
{cmd:resetvars(pox)} maps each regressor to the unit interval before forming
powers, as {helpb regress postestimation##ovtest:estat ovtest, rhs} does. With
the constant and {cmd:x} already in the regression,

{p 12 12 2}
{cmd:span{ (a+bx)^2, (a+bx)^3, (a+bx)^4 } + span{ 1, x }  =  span{ x^2, x^3, x^4 } + span{ 1, x }}

{pstd}
so the joint F statistic is numerically identical. The rescaling exists only to
condition the design matrix, which matters once fourth powers of a trended
series are involved. The command nonetheless builds the test variables itself
rather than calling {cmd:estat ovtest, rhs}, because that command refuses any
model containing time-series operators and silently drops indicator variables,
neither of which is acceptable inside a strategy that must also run on (2).

{pstd}
{bf:2. The {cmd:Sigma_j} engine at {cmd:j = 0} is White's estimator.} Setting
{cmd:j = 0} leaves {cmd:G(0)} alone, which is the heteroskedasticity-consistent
sandwich. Checked against
{cmd:regress y x z*, vce(robust)} followed by {cmd:testparm z*}: on a test
sample the built-in returned 7.506473 and {cmd:mispauto} 7.698946, a ratio of
1.025641, which is exactly {cmd:n/(n-k) = 200/195}. The difference is Stata's
finite-sample adjustment. Godfrey's (10) is written asymptotically with no such
adjustment, so the unadjusted form is the faithful one, and that is what the
command reports.

{pstd}
{bf:3. Stata's Sargan statistic is Godfrey and Hutton's {cmd:J}.}
{cmd:estat overid} after {cmd:ivregress 2sls} computes
{cmd:N*(1 - rss/eqnrss)}, which is {cmd:n} times the uncentred R-squared from
regressing the IV residual on the full instrument list -- their (13) exactly.
The built-in is therefore called rather than reimplemented. It is suppressed
under a robust or HAC {cmd:vce()}, and the command fits the equation without
one for this purpose.

{pstd}
{bf:4. Durbin's S-test is {cmd:estat durbinalt} at one lag.} Thursby's
description of step 1 of the LRS procedure and the auxiliary regression in
{cmd:durbina.ado} are the same regression and the same test.


{marker decisions}{...}
{title:Decisions the papers leave open}

{pstd}
Each entry gives the default, the alternative, and the reason.

{phang}
{bf:1. RESET test variables.} Default {cmd:pox}, powers of the regressors,
because that is what Thursby and Schmidt recommend and what Thursby (1981)
uses. Ramsey's {cmd:poy} is available; Stata's bare {cmd:estat ovtest} uses it,
which is why the two commands can disagree.

{phang}
{bf:2. Truncation lag.} Default {cmd:truncate(auto)}, the White and Domowitz
procedure above. {cmd:truncate(seasonal)} uses the period from {helpb tsset},
which is Godfrey's only published guidance ("use j >= 4 when the observations
are quarterly"), falling back to the Newey{c 150}West rule when the frequency
is unknown. An explicit integer overrides both.

{phang}
{bf:3. Kernel.} Default {cmd:truncated}, the uniform weighting that
{cmd:Sigma_j} literally specifies. It is not guaranteed positive semi-definite;
when it is not, a spectral generalized inverse keeping the positive eigenvalues
is used, the rank actually used becomes the degrees of freedom, and a warning
is printed. {cmd:kernel(bartlett)} routes to {helpb newey} and is positive
semi-definite by construction. The command never switches silently.

{phang}
{bf:4. The order q.} Default {cmd:s-1} where {cmd:s} is the detected period,
giving 3 for quarterly and 11 for monthly data, which are the values Godfrey
names.

{phang}
{bf:5. The LR stage of LRS.} Retained, because the package implements Thursby
(1981) as published, with the Knottnerus result printed beside it whenever it
rejects. {opt slrs} drops it and runs the S-test at the full level, which
Thursby's reply reports costs about two percentage points of power, citing his
unpublished 1983 mimeo. That claim cannot be verified here and is attributed
rather than asserted.

{phang}
{bf:6. The restricted fit.} Default Durbin's transform, written out in
Thursby's step 3. {cmd:rtemethod(corc)} and {cmd:rtemethod(prais)} use
{helpb prais}.

{phang}
{bf:7. Leading missing lagged residuals.} Zero-filled, following
{cmd:estat durbinalt}'s default, so that results reconcile with the built-in.
{opt nomiss0} drops them instead.

{phang}
{bf:8. Side of the Durbin{c 150}Watson test.} Default lower tail, which is what
Thursby's positive-autocorrelation designs require and what the
{cmd:dL}/{cmd:dU} tables are built for. {cmd:dwside(two)} is available and is
the safer choice when misspecification rather than AR(1) is the suspected
alternative.

{phang}
{bf:9. Degrees of freedom for RESET.} The power set is reduced automatically
until at least 10 residual degrees of freedom remain, and the set used is
reported. Thursby flags the problem without prescribing a rule.


{marker limits}{...}
{title:Limitations}

{pstd}
{bf:The robust Wald statistic has a finite-sample size problem when j is
large.} This is a property of HAC-based Wald tests generally, not of this
implementation. In a Monte Carlo on a correctly specified model with
independent errors at T = 200, forcing {cmd:j = 6} produced rejection rates of
about 33% for the truncated kernel and about 24% for the Bartlett kernel routed
through Stata's own {helpb newey}, against a nominal 5%, while the plain OLS F
test held its size at 5.3%. The two kernels failing together, one of them
StataCorp's code, locates the problem in the statistic rather than in either
implementation. This is precisely why the truncation lag must be chosen from the
data: do not set {opt truncate()} generously "to be safe".

{pstd}
{bf:There is no finite-sample theory for (10) at all}, and Godfrey reports no
size or power evidence for his sequence.

{pstd}
{bf:Thursby's independence assumptions are Monte Carlo results}, established on
his 22 designs at T = 30, 60 and 90, not theorems. The level allocations (6)
and (8) inherit that status.

{pstd}
{bf:The asymptotic independence of J and H is proved only under the stage-2
null}, so the overall level of the Godfrey{c 150}Hutton procedure is exact only
when {cmd:Omega = 0}.

{pstd}
{bf:RESET's documented failures are reproduced faithfully, not patched.} See
the Remarks section of {helpb mispauto}.


{marker refs}{...}
{title:References}

{pstd}
The five primary papers are listed in {helpb mispauto}. The supporting results
implemented here are:

{phang}
Durbin, J. 1970. Testing for serial correlation in least-squares regression when
some of the regressors are lagged dependent variables.
{it:Econometrica} 38(3): 410{c 150}421.
{browse "https://doi.org/10.2307/1909547":doi:10.2307/1909547}.

{phang}
Godfrey, L. G. 1981. On the invariance of the Lagrange multiplier test with
respect to certain changes in the alternative hypothesis.
{it:Econometrica} 49(6): 1443{c 150}1455.
{browse "https://doi.org/10.2307/1911410":doi:10.2307/1911410}.

{phang}
Imhof, J. P. 1961. Computing the distribution of quadratic forms in normal
variables. {it:Biometrika} 48(3{c 150}4): 419{c 150}426.
{browse "https://doi.org/10.1093/biomet/48.3-4.419":doi:10.1093/biomet/48.3-4.419}.

{phang}
Porter, R. D., and A. K. Kashyap. 1984. Autocorrelation and the sensitivity of
RESET. {it:Economics Letters} 14(2{c 150}3): 229{c 150}233.
{browse "https://doi.org/10.1016/0165-1765(84)90087-9":doi:10.1016/0165-1765(84)90087-9}.

{phang}
Ramsey, J. B. 1969. Tests for specification errors in classical linear
least-squares regression analysis.
{it:Journal of the Royal Statistical Society, Series B} 31(2): 350{c 150}371.
{browse "https://doi.org/10.1111/j.2517-6161.1969.tb00796.x":doi:10.1111/j.2517-6161.1969.tb00796.x}.

{phang}
Thursby, J. G., and P. Schmidt. 1977. Some properties of tests for specification
error in a linear regression model.
{it:Journal of the American Statistical Association} 72(359): 635{c 150}641.
{browse "https://doi.org/10.1080/01621459.1977.10480627":doi:10.1080/01621459.1977.10480627}.

{phang}
White, H., and I. Domowitz. 1984. Nonlinear regression with dependent
observations. {it:Econometrica} 52(1): 143{c 150}161.
{browse "https://doi.org/10.2307/1911465":doi:10.2307/1911465}.

{pstd}
Amemiya (1973),
{browse "https://doi.org/10.2307/1914092":doi:10.2307/1914092}, is cited as the
estimator Godfrey recommends after AR(1) is rejected, and is not on the
estimation path.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
