{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag postestimation" "help jointdiag_postestimation"}{...}
{viewerjumpto "Purpose of this page" "jointdiag_methods##purpose"}{...}
{viewerjumpto "Notation" "jointdiag_methods##notation"}{...}
{viewerjumpto "1 The additivity theorem" "jointdiag_methods##additivity"}{...}
{viewerjumpto "2 lm" "jointdiag_methods##lm"}{...}
{viewerjumpto "3 im" "jointdiag_methods##im"}{...}
{viewerjumpto "4 arch" "jointdiag_methods##arch"}{...}
{viewerjumpto "5 bilinear" "jointdiag_methods##bilinear"}{...}
{viewerjumpto "6 bc" "jointdiag_methods##bc"}{...}
{viewerjumpto "7 score" "jointdiag_methods##score"}{...}
{viewerjumpto "8 port" "jointdiag_methods##port"}{...}
{viewerjumpto "9 spec" "jointdiag_methods##spec"}{...}
{viewerjumpto "10 mpi" "jointdiag_methods##mpi"}{...}
{viewerjumpto "11 nonnest" "jointdiag_methods##nonnest"}{...}
{viewerjumpto "Numerical cross-checks" "jointdiag_methods##checks"}{...}
{viewerjumpto "Conventions we had to choose" "jointdiag_methods##choices"}{...}
{viewerjumpto "Limitations" "jointdiag_methods##limits"}{...}
{viewerjumpto "Full bibliography" "jointdiag_methods##bib"}{...}

{title:Title}

{phang}
{bf:jointdiag methods} {hline 2} derivations, the step{c 174}equation map, and
the numerical cross-checks


{marker purpose}{...}
{title:Purpose of this page}

{pstd}
This page documents, for every subcommand, {it:which equation of which paper}
each block of code computes, which conventions were chosen where a paper is
silent, and which built-in Stata command reproduces the result exactly.  Open
it with{p_end}
{phang2}{cmd:. help jointdiag methods}{p_end}


{marker notation}{...}
{title:Notation}

{pstd}
Throughout, {it:y_t} is the dependent variable, {it:x_t} the {it:k}-vector of
regressors (a constant included unless said otherwise), {it:u_t} the OLS
residual, {it:s2} = {it:n}{c 94}(-1) {&Sigma} {it:u_t}{c 94}2 the ML variance
estimate, {it:b1} and {it:b2} the sample skewness and kurtosis of the residuals,
{it:e_t} the standardised residual of a conditional-variance model, and
{it:h_t} its conditional variance.  {it:M_X} = {it:I} - {it:X}({it:X'X}){c 94}(-1){it:X'}.


{marker additivity}{...}
{title:1  The additivity theorem}

{pstd}
Everything in {helpb jointdiag_lm:lm}, {helpb jointdiag_im:im} and
{helpb jointdiag_bilinear:bilinear} rests on one result.

{pstd}
{bf:Bera{c 150}McKenzie condition} (stated in Higgins and Bera 1988, sec. 2).
Partition the null {it:H0: h(}{&theta}{it:) = 0} into {it:H_A: h1 = 0} and
{it:H_B: h2 = 0}.  The LM statistics are {bf:additive},
{it:T_AB} = {it:T_A} + {it:T_B}, if and only if the information matrix is block
diagonal between the two sets of restrictions after the nuisance parameters are
concentrated out, i.e. if

{p 8 8 2}
{it:J22} - {it:J21} {it:J11}{c 94}(-1) {it:J12}

{pstd}
is block diagonal.  Bera and Jarque (1982, sec. 3.2) verify this for the four
directions N, H, I, F by exhibiting the locally equivalent alternative (LEA)
model of Godfrey and Wickens: the regressors attached to {it:c1}, {it:c2},
{&alpha}, {&gamma}, {&lambda} and {&delta} are mutually asymptotically
orthogonal.  Bera and Lee (1993) verify it again for the six blocks of the
information-matrix test when the null has AR({it:p}) errors {c 150} which is the
step Hall (1987, p. 262) had conjectured would fail.

{pstd}
Consequences used by the package: (i) every joint statistic is the sum of its
parts and every degree-of-freedom count is the sum of the parts' counts;
(ii) the one-directional statistics are asymptotically independent, which is
what makes the multiple-comparison procedure of {helpb jointdiag_lm:lm} valid.


{marker lm}{...}
{title:2  jointdiag lm}

{pstd}
{bf:Target} {c 150} Bera and Jarque (1982), eq. (4):

{p 8 8 2}
LM_NHIF = LM_N + LM_H + LM_I + LM_F {space 4}~{space 2}chi2(2 + q + p + r + L)

{synoptset 12 tabbed}{...}
{synopthdr:block}
{synoptline}
{synopt:LM_N}{it:n}[{it:b1}/6 + ({it:b2}-3){c 94}2/24], Jarque and Bera (1980)
eq. (4), published form in Jarque and Bera (1987).  Moments use the divisor
{it:n}; {cmd:dfadj} switches to {it:n-k}.{p_end}
{synopt:LM_H}(1/2) {it:f'Z}({it:Z'M1 Z}){c 94}(-1){it:Z'f} with
{it:f_i} = {it:u_i}{c 94}2/{it:s2} - 1 (Breusch and Pagan 1979).
{cmd:studentize} replaces the Gaussian scale 2{it:s2}{c 94}2 by the empirical
fourth moment (Koenker 1981) {c 150} this {it:is} the factor-2 correction that
Godfrey and Wickens (1982, p. 86) and Bera, McAleer and Pesaran (1989, p. 12)
insist on.{p_end}
{synopt:LM_I}{it:n r'r} with {it:r_j} = {&Sigma}{it:u_t u_{t-j}} /
{&Sigma}{it:u_t}{c 94}2 (Breusch 1978).  {cmd:fullbg} runs the full
Breusch{c 150}Godfrey auxiliary regression instead, which is what you need when
the regressors include lagged dependent variables (Godfrey 1978b).{p_end}
{synopt:LM_F}{it:u'W}({it:W'M_D W}){c 94}(-1){it:W'u}/{it:s2}, Bera and Jarque
(1982) footnote 3, i.e. Engle's (1979) variable-addition form.  {it:W} is
powers of the fitted values (Ramsey 1969) or, with {cmd:tspowers}, powers of
each regressor (Thursby and Schmidt 1977), which is the set Ghali and Snow
(1987) eq. (27) uses.{p_end}
{synoptline}

{pstd}
{bf:Multiple comparison procedure} {c 150} Bera and Jarque (1982, sec. 5),
steps (i){c 150}(iv).  Marginal level {&alpha}/4 per direction; the overall
level under asymptotic independence is
1 - (1 - {&alpha}/4){c 94}4, and the Bonferroni bound is {&alpha}.
With {cmd:sim(#)} the critical values come from {it:#} Gaussian replications on
the same design matrix instead of the chi-squared table; the statistics are
scale invariant, so {it:sigma} = 1 is without loss of generality (their
footnote 12).


{marker im}{...}
{title:3  jointdiag im}

{pstd}
{bf:Target} {c 150} White (1982) indicator
{it:d_t} = {&part}{c 94}2{it:l_t}/{&part}{&theta}{&part}{&theta}' +
({&part}{it:l_t}/{&part}{&theta})({&part}{it:l_t}/{&part}{&theta})',
decomposed as in Hall (1987) and extended to AR({it:p}) errors by Bera and Lee
(1993) eq. (5).

{pstd}
With {cmd:ar(0)} ({cmd:hall}) three blocks, Hall's Theorem:

{p 8 8 2}
{it:T_n} = {it:T1n} + {it:T2n} + {it:T3n} {space 2}asymptotically independent

{synoptset 12 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:T1n}heteroskedasticity.  Hall's {&Delta}1 with
{it:psi_t} = vech({it:x_t x_t'}), i.e. White's (1980) auxiliary regressors.
Default is the studentised (White) form; {cmd:bp} gives the un-studentised
Breusch{c 150}Pagan form Hall writes.{p_end}
{synopt:T2n}skewness, {&Delta}2:
[{&Sigma}{it:u}{c 94}3{it:x'}][{&Sigma}{it:x x'}]{c 94}(-1)[{&Sigma}{it:u}{c 94}3{it:x}]
/ (6{it:s2}{c 94}3).{p_end}
{synopt:T3n}kurtosis, {&Delta}3: {it:n}({it:b2}-3){c 94}2/24.{p_end}
{synoptline}

{pstd}
With {cmd:ar(}{it:p}{cmd:)} six blocks, Bera and Lee eq. (5):
{it:d1} static heteroskedasticity, {it:d2} conditional heteroskedasticity,
{it:d3} kurtosis, {it:d4} the {it:x}{&times}{&epsilon} interaction,
{it:d5} static and {it:d6} conditional "heteroclicity" (variation in the third
moment).  The headline result is

{p 8 8 2}
{bf:T2 is exactly Engle's (1982) LM test for ARCH} (their eq. 7), and the
AARCH version when the cross-products of lagged residuals are included.

{pstd}
Because the covariance matrix of {it:d} stays block diagonal {c 150} the point
Hall doubted {c 150} the six statistics are additive.


{marker arch}{...}
{title:4  jointdiag arch}

{pstd}
{bf:Target} {c 150} Bera, Higgins and Lee (1992), model (1.1):

{p 8 8 2}
{it:y_t} = {it:x_t'}{&beta} + {&epsilon}_t,{space 3}
{&epsilon}_t = {&Sigma}_j ({&phi}_j + {&eta}_jt) {&epsilon}_{t-j} + {it:u_t}

{pstd}
i.e. {bf:ARCH is random variation in the autoregressive coefficients}.  With
{&Sigma} = E({&eta}{&eta}') diagonal this is Engle's ARCH; with {&Sigma} full
it is the authors' {bf:augmented ARCH (AARCH)},
{it:h_t} = {it:s2} + {&epsilon}_{t-}'{it:C}{&epsilon}_{t-}.

{pstd}
{bf:Panel B tests} (their sec. 3).  LM(ARCH | AR) regresses {it:u_t}{c 94}2 on
a constant and the lagged squares of the residual {it:from an AR(p) fit};
LM(AR | ARCH) uses the {it:standardised} residuals {it:e_t}/sqrt({it:h_t}) from
an ARCH fit.  {cmd:robust} switches both to Wooldridge's (1990) form, which is
what their Table 2 reports as LM_R-AR.

{pstd}
{bf:Stationarity} (their Proposition 1, from Andel 1976 and Nicholls{c 150}Quinn
1982).  Two conditions:

{p 8 8 2}
(a) the eigenvalues of the AR companion matrix {it:M} lie inside the unit
circle;{break}
(b) vec({it:C})'{it:a} < 1, where {it:a} is the last column of
({it:I} - {it:M}{c 174}{it:M}){c 94}(-1).

{pstd}
For AR({it:p}) + ARCH({it:p}) this reduces to
{it:w}({&phi}) {&Sigma}_j {&gamma}_j < 1.  The package reports {it:w}({&phi})
explicitly because {bf:autocorrelation can destroy a stationarity region that
the pure ARCH condition says is safe}: for AR(1), {it:w}({&phi}) =
1/(1-{&phi}{c 94}2), so with {&phi} = 0.27 and {&phi} = 0.33 the authors obtain
{it:w} = 1.34 and any {&gamma} above 0.75 is non-stationary even though
{&gamma} < 1.


{marker bilinear}{...}
{title:5  jointdiag bilinear}

{pstd}
{bf:Target} {c 150} Higgins and Bera (1988) sec. 3 and Bera and Higgins (1997)
sec. 3.  GARCH and bilinear processes share their unconditional moment
structure {c 150} both are uncorrelated in levels and autocorrelated in
squares {c 150} so the usual diagnostics cannot tell them apart.  The joint LM
statistic is the sum of the two individual ones, additivity holding by the
Bera{c 150}McKenzie condition.

{pstd}
With {cmd:fform} the package uses the locally equivalent alternative
regression, Bera and Higgins (1997) eq. (3.4),

{p 8 8 2}
{it:y_t} = {it:x_t'b} + {&Sigma}_i {it:a_i}({it:e}{c 94}2_{t-i} - {it:s2})
+ {&Sigma}_ij {it:b_ij e_{t-i} e_{t-j}} + {it:e_t}

{pstd}
and reports ({it:q}/2){it:F_a} + {it:d F_b}.  {bf:The division by 2 is not
optional}: the OLS variance of the ARCH block is half the correct asymptotic
variance (their p. 14{c 150}15, following Godfrey and Wickens 1982 p. 86 and
Koenker 1981), so an uncorrected {it:F} over-rejects by a factor of two.
Constraints: {it:b_ij} = 0 for {it:i} < {it:j}, because no LM test exists
against an alternative containing both {it:u_{t-i}e_{t-j}} and
{it:u_{t-j}e_{t-i}} (Saikkonen and Luukkonen 1988); and ARCH rather than GARCH,
because no LM test exists against lagged {it:h_t} (Bollerslev 1986).


{marker bc}{...}
{title:6  jointdiag bc}

{pstd}
{bf:Target} {c 150} the most general model of the four papers, Ghali and Snow
(1987) eq. (19){c 150}(25):

{p 8 8 2}
{it:y_t}{c 94}({&lambda}) = {it:x_t'}{&beta} + {it:x*_t'}{&beta}* + {it:u_t},
{space 2}{it:u_t} = {&rho}{it:u_{t-1}} + {it:e_t},
{space 2}Var({it:u_t}) = {it:s2 z_t}{c 94}{&delta}

{pstd}
Concentrated log likelihood, their eq. (25):

{p 8 8 2}
{it:L}({&delta},{&lambda},{&rho}) = -({it:T}/2)[ln 2{&pi} + 1]
+ ({it:T}/2)ln(1-{&rho}{c 94}2) - {it:T} ln {it:sigma0}
- ({&delta}/2){&Sigma}ln {it:z_t} + ({&lambda}-1){&Sigma}ln {it:y_t}

{pstd}
The code applies, in exactly the order the paper writes them: the Box{c 150}Cox
transform to {it:y}; then the Prais{c 150}Winsten AR(1) transform; then the
weights {it:z}{c 94}(-{&delta}/2).  Maximisation is a coarse grid on {&lambda}
followed by the zig-zag coordinate refinement of Oberhofer and Kmenta (1974)
that Lahiri and Egy (1981) use, with golden-section search in each coordinate.

{pstd}
{bf:The two families of test} (Savin and White 1978, Table 1):

{p 8 8 2}
{it:C}(.) {c 150} {bf:conditional}: the other parameters are {it:fixed} at
their null values.{break}
{it:G}(.) {c 150} {bf:unconditional}: the other parameters are {it:free} under
both hypotheses.

{pstd}
The gap between them is the whole point.  Their artificial example (sec. 3.4)
generates {it:ln(Y)} = 0.1 + 0.1{it:X} + {it:u} with {bf:independent} errors;
the fitted linear model gives DW = 0.675, {it:C}({&rho}) = 53.6 (overwhelming
rejection of independence) and {it:G}({&rho}) = 0.97 (comfortable acceptance).
{cmd:jointdiag bc} reproduces this; see the example do-file.

{pstd}
Special cases: {&delta} = 0 is Savin and White's BCA model; {&rho} = 0 is
Lahiri and Egy's BCH model; both free with {it:x*} is Ghali and Snow's
generalised test, from which they derive a hierarchy of 65 conditional tests.
{cmd:lm} gives the Tse (1984) eq. (10){c 150}(11) score versions, and
{cmd:lm studentize} the expected-information robust versions of Yang and Tse
(2008, Cor. 3.2).


{marker score}{...}
{title:7  jointdiag score}

{pstd}
{bf:Target} {c 150} Tsai (1986) eq. (2-4):

{p 8 8 2}
{it:S} = {it:S1} + {it:S2},{space 3}
{it:S1} = ({it:T rho_hat}){c 94}2/({it:T}-1),{space 3}
{it:S2} = (1/2){it:V'Dbar}({it:Dbar'Dbar}){c 94}(-1){it:Dbar'V}

{pstd}
with {it:V_t} = {it:e_t}{c 94}2/{it:s2}, {it:D} the derivative of the weight
function and {it:Dbar} = {it:D} - {it:11'D/T}; and
{it:rho_hat} = {&Sigma}'{it:e_t e_{t-1}}/{&Sigma}{it:e_t}{c 94}2 (his eq. 2-5).
{it:S1} ~ chi2(1), {it:S2} ~ chi2({it:q}), {it:S} ~ chi2({it:q}+1).

{pstd}
Tsai's sec. 3 result, which the help text reports: {it:S} is large exactly when
Cook's geometric normal curvature of the influence graph is large, or when the
GLS coefficient estimates are sensitive to the perturbation.

{pstd}
{cmd:bilinear} adds the Liu, Wei and Wang (2003) extension to nonlinear
regression with DBL({it:p},0,1) errors,
{it:u_t} = {&Sigma}{&phi}_i{it:u_{t-i}} + {&psi}{it:u_{t-1}e_{t-1}} + {it:e_t}:
their eq. (3.2) SCa for {&psi} = 0, eq. (3.3) SCb for ({&phi},{&psi}) = 0 and
eq. (3.5) SCd for the variance and correlation jointly.


{marker port}{...}
{title:8  jointdiag port}

{pstd}
{bf:Target} {c 150} Wong and Ling (2005) Theorem 1 and Corollary 1:

{p 8 8 2}
sqrt({it:n})({it:rho_hat}', {it:r_hat}')' {space 2}->{space 2}
{it:N}(0, {it:V}{&Omega}{it:V}'),{space 4}
{it:Q_M} = {it:n}({it:rho},{it:r})'[{it:V}{&Omega}{it:V}']{c 94}(-1)({it:rho},{it:r})
~ chi2(2{it:M})

{pstd}
where {it:rho_l} are the autocorrelations of the standardised residuals and
{it:r_l} those of their squares.  The covariance blocks are
{it:I} - {it:X_q R}{c 94}(-1){it:X_q}' for the mean,
{it:I} - (1/4){it:X_r R}{c 94}(-1){it:X_r}' for the variance (Li and Mak 1994)
and -(1/2){it:X_q R}{c 94}(-1){it:X_r}' for the covariance (Ling and Li 1997).

{pstd}
{it:Q_S} is their eq. (12), the Ljung{c 150}Box-corrected sum; {it:Q1M} uses
only lags from {it:L0} onward in the mean block, their recommendation being
{it:L0} = 1.

{pstd}
{bf:Velasco and Wang (2015)} remove the estimation effect entirely with a
recursive projection, their sec. 2:

{p 8 8 2}
{it:nu}({it:i}) = {it:Lam}({it:i})[ {it:Q}({it:i}) - {it:C}({it:i})
({&Sigma}_{j>i}{it:C}({it:j})'{it:C}({it:j})){c 94}(-1)
{&Sigma}_{j>i}{it:C}({it:j})'{it:Q}({it:j}) ]

{p 8 8 2}
{it:Lam}({it:i}) = [ {it:I2} + {it:C}({it:i})
({&Sigma}_{j>i}{it:C}({it:j})'{it:C}({it:j})){c 94}(-1){it:C}({it:i})' ]{c 94}(-1/2)

{pstd}
The transformed pairs are asymptotically {it:N}(0,{it:I}), so a plain
Box{c 150}Pierce sum of them is chi-squared with {bf:no} estimation correction
and no restriction on the lag order.  Only {it:M} - {it:k} pairs can be
projected, so choose {cmd:lags()} comfortably larger than the number of
estimated parameters.

{pstd}
{bf:Mahdi (2024)} adds the cross-correlations between residuals and their
squares, eq. (3.1){c 150}(3.8), giving {it:C_12} (positive lags) and
{it:C_21} (negative lags), each ~ chi2(3{it:m}).

{pstd}
{bf:Derivatives.}  {it:X_q} and {it:X_r} are obtained by numerically
perturbing each coefficient of {cmd:e(b)} and recomputing the autocorrelations.
Velasco and Wang (2015, p. 44) explicitly permit this: "can also be
approximated with numerical methods perturbing the residuals autocorrelations
around the parameter estimate".


{marker spec}{...}
{title:9  jointdiag spec}

{pstd}
{bf:Target} {c 150} Escanciano (2008).  The null is a {it:pair} of conditional
moment restrictions, his eq. (2):

{p 8 8 2}
E[{it:e1_t} | {it:I_{t-1}}] = 0 {space 2}{bf:and}{space 2}
E[{it:e2_t} | {it:I_{t-1}}] = 0,{space 4}
{it:e2_t} = {it:e1_t}{c 94}2 - {it:h}{c 94}2

{pstd}
The Cram{c 130}r{c 150}von Mises statistic is his eq. (9),

{p 8 8 2}
{it:J}{c 94}2_{n,w} = {&Sigma}_j {it:n_j}/({it:j}{&pi}){c 94}2
{&int} |{it:gamma_j,w}({it:x})|{c 94}2_M {it:W}({it:dx})

{pstd}
with {it:M} = diag({it:m1},{it:m2}): (1,1) gives the joint test, (1,0) the mean
marginal and (0,1) the variance marginal.  Two weight families are implemented,
the exponential one ({it:w} = exp({it:ixY}), {it:W} standard normal) and the
indicator one ({it:w} = 1({it:Y} <= {it:x}), {it:W} the empirical cdf).
The 1/({it:j}{&pi}){c 94}2 weight makes lags beyond about 25 contribute under
0.2 percent, so the sum is truncated there.

{pstd}
{bf:The bootstrap is not optional.}  The asymptotic null distribution depends
on the data-generating process, so critical values must be simulated.  The
package follows his steps 1{c 150}4 with the two-point weights of his eq. (11),
and {bf:re-estimates the model in every replication} (step 4).  The validity of
that step rests on Assumption A6 of Escanciano (2007, CAEPR WP 2007-009), which
requires the bootstrap estimator to satisfy the same Bahadur expansion as the
original and which he notes "has to be studied on a case-by-case basis".
{cmd:norefit} skips the refit; it is faster but ignores the estimation effect
and can over-reject, and the output says so.

{pstd}
{bf:The finding that motivates the whole subcommand} (his Tables 2{c 150}3):
the marginal variance test has rejection rates of 2.7{c 150}4.0 percent against
a GARCH-M alternative and 1.0{c 150}3.5 percent against AR(2)-CH(1) {c 150} that
is, {it:no power at all} {c 150} purely because the conditional mean is
misspecified.  Never read a marginal variance test without the mean test beside
it.


{marker mpi}{...}
{title:10  jointdiag mpi}

{pstd}
{bf:Target} {c 150} King and Evans (1984) eq. (2):

{p 8 8 2}
{it:r}({&rho}1) = {it:u~'}{&Sigma}{c 94}(-1)({&rho}1){it:u~} / {it:e'e}

{pstd}
Reject {it:H0} for {bf:small} values.  By Theorem 3 of King (1980) this is most
powerful invariant against the simple alternative {&rho} = {&rho}1, and the
authors recommend {&rho}1 = 0.5 against positive and -0.5 against negative
autocorrelation.  The numerator is the OLS sum of squares of the model
transformed by {it:R}({&rho}) = {it:D}{c 94}(-1/2){it:G}({&rho}){c 94}(-1)
(their eq. 3).

{pstd}
By the Durbin{c 150}Watson lemma the statistic is a ratio of quadratic forms,
{it:r} = {&Sigma}{it:v_i}{&xi}_i{c 94}2 / {&Sigma}{&xi}_i{c 94}2, so the exact
critical value solves

{p 8 8 2}
Pr[ {&Sigma}({it:v_i} - {it:r}*){&xi}_i{c 94}2 < 0 ] = {&alpha}

{pstd}
The paper used the FQUAD subroutine of Koerts and Abrahamse (1969); the package
uses {bf:Imhof's (1961) numerical inversion} instead, computed in logarithms so
that the characteristic function does not overflow when {it:n} is large.  The
Henshaw (1966) first two moments are reported as a sanity check.

{pstd}
{bf:Why one-sided.}  Their Table 1 at {it:n} = 20: the one-sided test has power
0.134, 0.228, 0.320, 0.403, 0.475 at {&lambda} = 1.0, 2.5, 5.0, 10.0, 25.0
against 0.082, 0.143, 0.211, 0.278, 0.341 for the two-sided LM test.  Roughly a
third of the power is thrown away by ignoring the sign.


{marker nonnest}{...}
{title:11  jointdiag nonnest}

{pstd}
{bf:Target} {c 150} Bera, McAleer and Pesaran (1989) eq. (6){c 150}(7).  The
auxiliary regression is

{p 8 8 2}
{it:y_t} = {it:x_t'b} + {&Sigma}_j {&rho}_j{it:u0_{t-j}}
+ {&Sigma}_i {&phi}_i{it:v_it} + {it:c1 r_t} + {&alpha}{it:y1_hat_t} + {it:e_t}

{pstd}
and the joint null is {&rho} = 0, {&phi} = 0, {it:c1} = 0, {&alpha} = 0, where
{it:y1_hat} is the fitted value from the non-nested rival (the
Davidson{c 150}MacKinnon {it:J}-test regressor).

{pstd}
{bf:Two variance corrections, both essential.}

{phang2}
{bf:Factor 2} on the heteroskedasticity block.  Var({it:u}{c 94}2 - {it:s2}) =
2{it:s2}{c 94}2 but the regression formula computes {it:s2}{c 94}2.  Their
p. 12, citing Godfrey and Wickens (1982, p. 86).

{phang2}
{bf:Factor 7} on the non-normality block.  They derive the correct asymptotic
variance as 21{it:s}{c 94}8/8 while the regression formula gives
3{it:s}{c 94}8/8 {c 150} {bf:one seventh of the truth} (their p. 12{c 150}13,
with the eighth-moment algebra shown in full).

{pstd}
So the decomposition the package reports is

{p 8 8 2}
({it:p0}+1){it:F1} + ({it:q0}/2){it:F2} + (1/7){it:F3}
{space 2}->{space 2}chi2({it:p0}+{it:q0}+2)

{pstd}
The package prints both the raw {it:F}s and the corrected chi-squares so the
size of the correction is visible.  The paper's own caveat is reproduced in the
output: a rejection does not say whether the rival model or the error
specification is responsible.


{marker checks}{...}
{title:Numerical cross-checks}

{pstd}
Several blocks are {it:provably} identical to a Stata built-in.  The example
do-file verifies each of these to the last printed digit; a mismatch is a bug.

{synoptset 34 tabbed}{...}
{synopthdr:jointdiag}
{synoptline}
{synopt:{cmd:lm, notable} {cmd:r(lm_H)}}= {cmd:estat hettest} {cmd:r(chi2)}{p_end}
{synopt:{cmd:lm, studentize} {cmd:r(lm_H)}}= {cmd:estat hettest, iid}{p_end}
{synopt:{cmd:lm, rhs} {cmd:r(lm_H)}}= {cmd:estat hettest, rhs}{p_end}
{synopt:{cmd:lm, fullbg} {cmd:r(lm_I)}}= {cmd:estat bgodfrey}{p_end}
{synopt:{cmd:im, hall} {cmd:r(T1)}}= {cmd:estat imtest} {cmd:r(chi2_h)}
= {cmd:estat imtest, white}{p_end}
{synopt:{cmd:im, ar(0) archlags(}{it:q}{cmd:)} {cmd:r(T2)}}=
{cmd:estat archlm, lags(}{it:q}{cmd:)}{p_end}
{synoptline}

{pstd}
Two blocks deliberately do {bf:not} match {cmd:estat imtest}: the skewness and
kurtosis components.  Stata reports the Cameron{c 150}Trivedi (1990) OPG forms;
{cmd:jointdiag} reports Hall's (1987) {&Delta}2 and {&Delta}3 as written in the
paper.  {cmd:im, compare} prints both side by side and says so.


{marker choices}{...}
{title:Conventions we had to choose}

{pstd}
Where a paper is silent the package picks a default, documents it, and exposes
the alternative.

{p 4 7 2}
1.  {bf:Moment divisor in LM_N.}  {it:n} (the papers' own form).
{cmd:dfadj} gives {it:n-k}.

{p 4 7 2}
2.  {bf:The} {it:z} {bf:variables of LM_H.}  Fitted values by default
(Cook{c 150}Weisberg).  {cmd:rhs} uses all regressors; {cmd:het()} names them.

{p 4 7 2}
3.  {bf:MCP marginal level.}  {&alpha}/4 (strict Bonferroni).  Bera and Jarque
chose 0.03 each to reach an overall 0.10; the exact level under asymptotic
independence is printed alongside.

{p 4 7 2}
4.  {bf:Box{c 150}Cox grid.}  25 points on [-2, 3] then golden-section
refinement.  {cmd:grid()} and {cmd:lrange()} change both.

{p 4 7 2}
5.  {bf:Portmanteau lag order.}  min(floor(sqrt({it:n})), 20).  The Velasco{c 150}Wang
transform additionally needs {it:M} > {it:k}.

{p 4 7 2}
6.  {bf:L0 in Q1M.}  1, which is Wong and Ling's own simulation recommendation.

{p 4 7 2}
7.  {bf:Derivatives in} {cmd:port}.  Central numerical differences with step
1e-5 {&times} max(|{it:theta_j}|, 1).

{p 4 7 2}
8.  {bf:Bootstrap replications in} {cmd:spec}.  299 (odd, so no ties in the
p-value).  Escanciano used 500, Li et al. 100.

{p 4 7 2}
9.  {bf:Singular matrices.}  A generalised inverse is used and the effective
rank becomes the degrees of freedom, with the reduction visible in the printed
{it:df}.  Silent failure is worse than a reported rank deficiency.


{marker limits}{...}
{title:Limitations}

{pstd}
These are documented, not invented around.

{p 4 7 2}
{bf:*}  {cmd:score} is a {it:local} test.  Liu, Wei and Wang (2003, sec. 4)
show its power rises near the null and then {it:falls} once |{&psi}| passes
about 0.5.  Their Figure 1 is the picture to have in mind.

{p 4 7 2}
{bf:*}  {cmd:bilinear} cannot test GARCH against bilinearity, only ARCH: no LM
test exists against lagged {it:h_t} (Bollerslev 1986).  The simulated Cox test
of Bera and Higgins (1997, sec. 4) that {it:can} choose between them is not
implemented; it needs a full likelihood simulation per replication.

{p 4 7 2}
{bf:*}  {cmd:spec} supports {helpb regress} and {helpb arch} nulls.  Other
estimators would need their own refit step.

{p 4 7 2}
{bf:*}  {cmd:port}'s {it:Q_M} and the Velasco{c 150}Wang transform need an
estimated model with recoverable derivatives; with user-supplied residuals only
the derivative-free statistics are reported.

{p 4 7 2}
{bf:*}  {cmd:mpi} requires the {it:z_t} of the heteroskedastic alternative to
be known up to a scalar.  King and Evans (1984, sec. 3) acknowledge this as a
weakness of their test and suggest fixing {it:z} at "reasonable" values chosen
without reference to {it:y}.

{p 4 7 2}
{bf:*}  {cmd:im} with {cmd:ar(}{it:p}{cmd:)} fits the AR null with
{helpb arima} (or {helpb prais} for {it:p} = 1).  Bera, Lee and Higgins's
treatment of {it:lagged dependent variables} among the regressors is not
implemented; with a lagged dependent variable the block diagonality that makes
the six components additive can fail.


{marker bib}{...}
{title:Full bibliography}

{pstd}Every DOI below resolves.{p_end}

{phang}Bera, A. K., and C. M. Jarque. 1982. {it:J. Econometrics} 20: 59{c 150}82.
{browse "https://doi.org/10.1016/0304-4076(82)90103-8"}{p_end}
{phang}Bera, A. K., M. L. Higgins, and S. Lee. 1992. {it:JBES} 10: 133{c 150}142.
{browse "https://doi.org/10.1080/07350015.1992.10509893"}{p_end}
{phang}Bera, A. K., and M. L. Higgins. 1997. {it:JBES} 15: 43{c 150}50.
{browse "https://doi.org/10.1080/07350015.1997.10524685"}{p_end}
{phang}Bera, A. K., and S. Lee. 1993. {it:Rev. Econ. Studies} 60: 229{c 150}240.
{browse "https://doi.org/10.2307/2297820"}{p_end}
{phang}Bera, A. K., M. McAleer, and M. H. Pesaran. 1989. BEBR WP 89-1616,
Univ. of Illinois.{p_end}
{phang}Breusch, T. S., and A. R. Pagan. 1979. {it:Econometrica} 47: 1287{c 150}1294.
{browse "https://doi.org/10.2307/1911963"}{p_end}
{phang}Chesher, A. 1983. {it:Economics Letters} 13: 45{c 150}48.
{browse "https://doi.org/10.1016/0165-1765(83)90009-5"}{p_end}
{phang}Chesher, A. 1984. {it:Econometrica} 52: 865{c 150}872.
{browse "https://doi.org/10.2307/1911188"}{p_end}
{phang}Engle, R. F. 1982. {it:Econometrica} 50: 987{c 150}1007.
{browse "https://doi.org/10.2307/1912773"}{p_end}
{phang}Escanciano, J. C. 2008. {it:J. Econometrics} 143: 74{c 150}87.
{browse "https://doi.org/10.1016/j.jeconom.2007.08.010"}{p_end}
{phang}Ghali, M. A., and M. S. Snow. 1987. {it:Economic Modelling} 4: 65{c 150}76.
{browse "https://doi.org/10.1016/0264-9993(87)90004-6"}{p_end}
{phang}Hall, A. 1987. {it:Rev. Econ. Studies} 54: 257{c 150}263.
{browse "https://doi.org/10.2307/2297515"}{p_end}
{phang}Higgins, M. L., and A. K. Bera. 1988. {it:Econometric Reviews} 7: 171{c 150}181.
{browse "https://doi.org/10.1080/07474938808800151"}{p_end}
{phang}Jarque, C. M., and A. K. Bera. 1980. {it:Economics Letters} 6: 255{c 150}259.
{browse "https://doi.org/10.1016/0165-1765(80)90024-5"}{p_end}
{phang}Jarque, C. M., and A. K. Bera. 1987. {it:Int. Statistical Review} 55: 163{c 150}172.
{browse "https://doi.org/10.2307/1403192"}{p_end}
{phang}King, M. L., and M. A. Evans. 1984. {it:Economics Letters} 16: 297{c 150}302.
{browse "https://doi.org/10.1016/0165-1765(84)90179-4"}{p_end}
{phang}Koenker, R. 1981. {it:J. Econometrics} 17: 107{c 150}112.
{browse "https://doi.org/10.1016/0304-4076(81)90062-2"}{p_end}
{phang}Lahiri, K., and D. Egy. 1981. {it:J. Econometrics} 15: 299{c 150}307.
{browse "https://doi.org/10.1016/0304-4076(81)90119-6"}{p_end}
{phang}Li, W. K., and T. K. Mak. 1994. {it:J. Time Series Analysis} 15: 627{c 150}636.
{browse "https://doi.org/10.1111/j.1467-9892.1994.tb00217.x"}{p_end}
{phang}Ling, S., and W. K. Li. 1997. {it:J. Time Series Analysis} 18: 447{c 150}464.
{browse "https://doi.org/10.1111/1467-9892.00061"}{p_end}
{phang}Liu, Y.-A., B.-C. Wei, and H.-B. Wang. 2003. {it:Comm. Statist. A} 32: 2441{c 150}2463.
{browse "https://doi.org/10.1081/sta-120025387"}{p_end}
{phang}Mahdi, E. 2024. {it:Statistics and Computing} 34: 76.
{browse "https://doi.org/10.1007/s11222-024-10393-w"}{p_end}
{phang}Savin, N. E., and K. J. White. 1978. {it:J. Econometrics} 8: 1{c 150}12.
{browse "https://doi.org/10.1016/0304-4076(78)90085-4"}{p_end}
{phang}Tsai, C.-L. 1986. {it:Biometrika} 73: 455{c 150}460.
{browse "https://doi.org/10.2307/2336222"}{p_end}
{phang}Tse, Y. K. 1984. {it:Economics Letters} 14: 333{c 150}337.
{browse "https://doi.org/10.1016/0165-1765(84)90007-7"}{p_end}
{phang}Velasco, C., and X. Wang. 2015. {it:J. Time Series Analysis} 36: 39{c 150}60.
{browse "https://doi.org/10.1111/jtsa.12091"}{p_end}
{phang}White, H. 1982. {it:Econometrica} 50: 1{c 150}25.
{browse "https://doi.org/10.2307/1912526"}{p_end}
{phang}Wong, H., and S. Ling. 2005. {it:J. Time Series Analysis} 26: 569{c 150}579.
{browse "https://doi.org/10.1111/j.1467-9892.2005.00420.x"}{p_end}
{phang}Wooldridge, J. M. 1990. {it:Econometric Theory} 6: 17{c 150}43.
{browse "https://doi.org/10.1017/s0266466600004898"}{p_end}
{phang}Yang, Z., and Y. K. Tse. 2008. {it:Econometrics Journal} 11: 349{c 150}376.
{browse "https://doi.org/10.1111/j.1368-423x.2008.00242.x"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
