{smcl}
{* *! version 1.0.1  10oct2026}{...}
{vieweralsosee "surardl" "help surardl"}{...}
{vieweralsosee "surardl postestimation" "help surardl_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Model" "surardl_methods##model"}{...}
{viewerjumpto "Estimation" "surardl_methods##est"}{...}
{viewerjumpto "Bounds test" "surardl_methods##bounds"}{...}
{viewerjumpto "Critical values" "surardl_methods##cv"}{...}
{viewerjumpto "Bootstrap" "surardl_methods##boot"}{...}
{viewerjumpto "Long run" "surardl_methods##lr"}{...}
{viewerjumpto "Cross-equation tests" "surardl_methods##cross"}{...}
{viewerjumpto "Step to equation map" "surardl_methods##map"}{...}
{viewerjumpto "Departures and open points" "surardl_methods##dep"}{...}
{viewerjumpto "Validation" "surardl_methods##val"}{...}
{viewerjumpto "Author" "surardl_methods##author"}{...}

{title:Title}

{phang}
{bf:surardl methods} {hline 2} Methods and formulas for {helpb surardl}

{pstd}
Equation numbers refer to Arif and Furuoka (2026) unless stated otherwise.


{marker model}{...}
{title:Model}

{pstd}
For unit {it:i} = 1, ..., {it:N} the ARDL({it:p_i}, {it:q_1i}, ..., {it:q_Ki})
model, equation (1), is reparameterised into the conditional error-correction
form of equation (7):

{p 8 8 2}
D.y(i,t) = mu(i) + delta(i) t + lambda(i) y(i,t-1)
+ sum_k beta(k,i) x(k,i,t-1)
+ sum_{j=1}^{p_i-1} psi(j,i) D.y(i,t-j)
+ sum_k sum_{j=0}^{q_ki-1} gamma(k,j,i) D.x(k,i,t-j) + u(i,t)

{pstd}
with, from equations (8)-(11),

{p 8 8 2}
lambda(i)   = -(1 - sum_j phi(j,i))  = -Phi(i)(1){break}
beta(k,i)   = sum_j varphi(k,j,i)    = Psi(k,i)(1){break}
psi(j,i)    = -sum_{l>j} phi(l,i){break}
gamma(k,0,i)= varphi(k,0,i),  gamma(k,j,i) = -sum_{l>j} varphi(k,l,i)

{pstd}
The reparameterisation is exact; no restriction is imposed. {cmd:surardl}
builds the design directly from the level series, so the differences and lags
in the regressor matrix are constructed once and reused unchanged by the
bootstrap. The effective sample loses max({it:p_i}, max_k {it:q_ki})
observations, taken as the maximum over units so that every equation shares one
time window -- a requirement for Sigma-hat.

{pstd}
Stacking over units gives the system of equation (32), {bf:Y} = {bf:Z theta} +
{bf:eps}, with {bf:Z_t} block diagonal, equation (30), and
Var({bf:eps}) = {bf:I_T} kron {bf:Sigma}, equation (39).


{marker est}{...}
{title:Estimation}

{pstd}
{bf:Step 1, equation (18).} Each equation is estimated by OLS, giving
residuals u-hat(i,t), equation (54).

{pstd}
{bf:Step 2, equations (55)-(56).} The contemporaneous covariance is

{p 8 8 2}
sigma-hat(ij) = (1/d_f) sum_t u-hat(i,t) u-hat(j,t)

{pstd}
with d_f set by {opt sigmadf()}. The default d_f = {it:T} is the Zellner
maximum likelihood form, the {helpb sureg} default, and the divisor used by the
authors' own code.

{pstd}
{bf:Step 3, equations (50)-(53) and (57)-(58).} Rather than form the
{it:NT} x {it:NT} matrix Omega, {cmd:surardl} assembles

{p 8 8 2}
{bf:A} = sum_t {bf:Z_t}' Sigma-hat^(-1) {bf:Z_t},  with ({it:i},{it:j}) block
sigma^(ij) {bf:X_i}'{bf:X_j}{break}
{bf:b} = sum_t {bf:Z_t}' Sigma-hat^(-1) {bf:y_t},  with {it:i}-th block
sum_j sigma^(ij) {bf:X_i}'{bf:y_j}

{pstd}
and solves theta-hat = {bf:A}^(-1){bf:b}, Var(theta-hat) = {bf:A}^(-1).
With {opt method(iterated)} Sigma-hat is recomputed from the FGLS residuals and
the solve repeated until max|theta^(s+1) - theta^(s)| < {opt tolerance()}.
Under normality the iterated estimator is the maximum likelihood estimator
(Oberhofer and Kmenta 1974). With {opt method(ols)} the point estimates are the
OLS ones and Var is block diagonal with blocks
s2(i) ({bf:X_i}'{bf:X_i})^(-1).

{pstd}
Theorem 2 gives the mixed-normal limit; Theorem 4 gives chi-squared limits for
linear restrictions satisfying the rate condition.


{marker bounds}{...}
{title:Bounds test}

{pstd}
The equation null, equation (61), is

{p 8 8 2}
H0(i): lambda(i) = beta(1,i) = ... = beta(K,i) = 0

{pstd}
plus the deterministic term in cases 2 and 4, so the number of restrictions is
{it:q} = {it:K}+1 in cases 1, 3 and 5 and {it:q} = {it:K}+2 in cases 2 and 4
(Kripfganz and Schneider 2020, footnote 12). {cmd:surardl} derives {it:q} from
the case and {it:K}; it is never a hard-coded constant. The selection matrix is
equation (63), embedded in the system by equation (64).

{pstd}
{bf:Wald form}, the default, equations (77) and (112):

{p 8 8 2}
W(i) = (R(i) theta-hat)' [R(i) {bf:A}^(-1) R(i)']^(-1) (R(i) theta-hat),
F(i) = W(i)/q

{pstd}
{bf:RSS form}, equations (69)-(76). The system is re-estimated with the level
terms removed from equation {it:i} only, holding Sigma-hat at its unrestricted
value as equation (73) specifies, and

{p 8 8 2}
F(i) = [(RSS_R(i) - RSS_U(i))/q] / [RSS_U(i)/(T - m_i)]

{pstd}
{opt fstat(rssall)} removes the level terms from every equation at once, which
is what the authors' own OxGauss and Stata scripts do. The paper states the two
forms are asymptotically equivalent. They are not equal in finite samples: the
Wald form embeds Sigma-hat with divisor {it:T}, whereas the RSS form divides by
RSS/({it:T} - {it:m_i}), so the Wald statistic is larger by roughly
{it:T}/({it:T} - {it:m_i}). On the ASEAN-6 example ({it:T} = 34, {it:m} = 8)
that factor is about 1.31. {cmd:surardl} reports the Wald form by default
because it is the form behind the published application; both are available and
both are honestly labelled.

{pstd}
The {it:t} statistic on lambda(i) addresses the first degenerate case of PSS,
and the F statistic on the beta terms alone addresses the second; the latter is
the multivariate analogue of the t_IDV statistic of McNown, Sam and Goh (2018)
and has no tabulated critical values, so it is reported with bootstrap values
only.

{pstd}
The joint test over all equations, equations (65)-(67) and (78)-(79), stacks
the individual restriction matrices.


{marker cv}{...}
{title:Critical values}

{pstd}
{cmd:surardl} carries three tabulations and two resampling schemes.

{pstd}
{bf:PSS (2001) Table CI} for the F statistic, cases 1-5, {it:K} = 0-10, at the
10%, 5%, 2.5% and 1% levels, and {bf:Table CII} for the t statistic. PSS
tabulate the t bounds for cases I, III and V only; because the deterministic
restrictions are irrelevant to this single-coefficient test, case 2 uses the
case 3 bounds and case 4 the case 5 bounds.

{pstd}
{bf:Narayan (2005)} small-sample bounds, cases 2-5, {it:n} = 30(5)80,
{it:K} = 0-7, at 10%, 5% and 1%, linearly interpolated in {it:n} and clamped
outside the range. Two documented departures from the printed tables:

{phang2}
(a) case 2, 10%, {it:n} = 80: the published {it:I}(0) entry for {it:K} = 5
repeats the {it:K} = 4 entry (2.303). {cmd:surardl} uses 2.180, the value
printed for the same row on Narayan's case 4 page.

{phang2}
(b) case 4, {it:n} = 80: all three published rows are verbatim copies of the
case 2 {it:n} = 80 rows and are evidently a typesetting error. They are not
stored, so case 4 interpolation is clamped at {it:n} = 75, which is mildly
conservative.

{pstd}
{bf:These tabulations are for the single-equation OLS F statistic.} The SUR
statistic has a more dispersed null distribution in small samples because Sigma
is estimated jointly. Using them on a SUR statistic over-rejects; see the
Remarks in {helpb surardl}.

{pstd}
{bf:Simulated SUR bounds}, {opt simulate()}, is Approach A of section 2.4. Data
are generated under the null with Sigma-hat as the innovation covariance and
the regressors either purely {it:I}(1) (upper bound) or purely {it:I}(0) (lower
bound), following the design in the notes to PSS Table CI. {opt simrho()}
controls how far the regressor innovations are correlated across units:
0 is the PSS design, 1 the authors' OxGauss design.


{marker boot}{...}
{title:Bootstrap}

{pstd}
{opt bootstrap()} implements Approach B of section 2.4, which the paper calls
for but does not specify. The design is that of McNown, Sam and Goh (2018,
section 3.2), itself the procedure of Palm, Smeekes and Urbain (2010, section
3.2 and Remark 2), extended to the {it:N}-equation system.

{p 4 8 2}1. Fit the generating models. The y-equation of the unit under test is
fitted with the null imposed (level terms, and the restricted deterministic
term in cases 2 and 4, removed); the other y-equations are left unrestricted.
Sigma-hat comes from this null-imposed system, so the resampled innovations
satisfy the null. The regressors get a marginal model: a random walk under
{opt bootdgp(rw)}, or an unrestricted VECM of order {opt bootlags()} under
{opt bootdgp(vecm)}.

{p 4 8 2}2. Rescale and recentre each residual series by sqrt(n/(n-k)),
following Davidson and MacKinnon (2004), as in equation (13) of McNown et al.

{p 4 8 2}3. Draw {it:T} time indices with replacement, {bf:one draw shared by
every equation}. This is what makes the critical values SUR-specific: the
contemporaneous cross-equation covariance Sigma and the within-unit y-x
dependence are both carried into the pseudo-data.

{p 4 8 2}4. Generate the pseudo-levels recursively, regressors first (they do
not depend on the current D.y), then the dependent variables using the
just-generated D.x. Initial observations are held at their observed values.

{p 4 8 2}5. Re-run the {bf:entire} statistic on the pseudo-data: build the
design, first-step OLS, re-estimate Sigma-hat, FGLS solve, Wald form. Nothing
is held fixed from the observed fit, so the bootstrap distribution carries the
same estimation noise as the observed statistic.

{p 4 8 2}6. Repeat and take empirical quantiles. The p-value is
(1 + #{F* >= F})/(B+1).

{pstd}
Replications in which a generated series diverges, the design becomes singular
or Sigma-hat fails to invert are discarded and counted in {cmd:e(bfail)}. A
large failure count under {opt bootdgp(vecm)} means the fitted marginal VECM
has explosive roots, which is common when {it:T} is short; use the default
{opt bootdgp(rw)} there.

{pstd}
{bf:When a bootstrap critical value comes out very large.} The bootstrap
conditions on the data, so it reflects features the tabulated DGP never
contemplates. The clearest case is an equation whose differenced dependent
variable is dominated by the contemporaneous differenced regressors with large
coefficients. The pseudo-dependent variable is then close to a linear
combination of the pseudo-regressors plus a random walk, the lagged level terms
in the bounds regression are nearly collinear, and the null distribution of the
statistic acquires a much heavier right tail. On the shipped ASEAN-6 example
this happens for Singapore, whose impact coefficients on D.lgdp and D.lto are
1.51 and -1.11; its bootstrap critical values run an order of magnitude above
the others while the tabulated bounds would declare a rejection. That is the
bootstrap doing its job: the tabulated bounds assume the regressors are
independent of the dependent variable, and that assumption is badly violated
there. Treat a large bootstrap critical value as a diagnostic about the
equation, not as a numerical failure -- inspect the impact coefficients, and
consider whether the deterministic case is right for that series.

{pstd}
{opt nodrift} is the one lever over this. By default the fitted intercept and
trend are propagated into the level of the pseudo-dependent variable, which is
the literal reading of step 4 of McNown et al. With {opt nodrift} the
pseudo-dependent variable is a driftless random walk, as in the PSS Table CI
design. Neither is uniformly conservative: on the shipped example the default
gives smaller critical values for five of six equations.

{pstd}
{opt boottarget(joint)} imposes the null on every equation at once. That is
one pass rather than {it:N}, it matches the design of the authors' own Monte
Carlo code, and it also calibrates the joint test.


{marker lr}{...}
{title:Long-run coefficients}

{pstd}
From equations (82) and (84), theta(k,i) = -beta(k,i)/lambda(i), with
long-run intercept and trend -mu(i)/lambda(i) and -delta(i)/lambda(i),
equation (83).

{pstd}
The delta-method variance is equation (89),

{p 8 8 2}
Var(theta-hat) = (beta^2/lambda^4) v_ll - (2 beta/lambda^3) v_lb
+ (1/lambda^2) v_bb

{pstd}
which {cmd:surardl} computes as g' {bf:V} g with g the gradient of equation
(86), so that the same machinery serves the multivariate case.

{pstd}
Simulation 5 of the paper shows this interval under-covers badly, and worse as
{it:T} grows, because theta is super-consistent while the delta-method standard
error is calibrated to a root-{it:T} consistent estimator. Section 6 of the
paper recommends Fieller sets or bootstrap intervals. Both are provided.

{pstd}
{bf:Fieller set.} {cmd:estat longrun, fieller} inverts H0: beta + theta lambda
= 0, which never divides by lambda-hat. Writing z for the normal quantile,
A = lambda^2 - z^2 v_ll, B = 2(beta lambda - z^2 v_lb) and
C = beta^2 - z^2 v_bb, the set is {theta: A theta^2 + B theta + C <= 0}:

{p2colset 12 30 32 2}{...}
{p2col :A > 0, discriminant > 0}a bounded interval{p_end}
{p2col :A > 0, discriminant <= 0}the empty set{p_end}
{p2col :A < 0, discriminant > 0}the complement of an interval, unbounded{p_end}
{p2col :A <= 0, discriminant <= 0}the entire real line{p_end}
{p2colreset}{...}

{pstd}
An unbounded set means lambda is too weakly identified to pin the ratio down.
That is the correct answer, and it is one the delta-method interval cannot
give.

{pstd}
{bf:Bootstrap intervals.} {cmd:estat longrun, bootstrap(}#{cmd:)} resamples
under the alternative, using the unrestricted residuals and the same shared
time index, and reports percentile and bias-corrected percentile intervals.


{marker cross}{...}
{title:Cross-equation tests}

{pstd}
All of these use the off-diagonal blocks of {bf:A}^(-1), which
equation-by-equation OLS sets to zero.

{pstd}
{bf:Poolability}, section 4.5(a). H0: beta(k,i) = beta(k,1) for
{it:i} = 2..{it:N} and all {it:k}, with {it:K}({it:N}-1) restrictions.
{cmd:estat poolability} also offers the lambda, short-run and joint variants.

{pstd}
{bf:Speed-of-adjustment equality}, section 4.5(c). Pairwise
H0: lambda(i) = lambda(j) and the joint H0 that all are equal.

{pstd}
{bf:Long-run equality}, Remark 10 and equations (92)-(93). {cmd:surardl} builds
the full ({it:NK}) x {it:M} gradient matrix {bf:G} of the long-run coefficients
once, so any linear hypothesis {bf:C} theta^LR = 0 is tested as

{p 8 8 2}
W = ({bf:C} theta-hat^LR)' [{bf:C G V G}' {bf:C}']^(-1) ({bf:C} theta-hat^LR)

{pstd}
Simulation 4 reports a maximum pairwise rejection rate of 53% at {it:N} = 5,
{it:T} = 50 without a multiple-testing correction, so {cmd:estat lrequal} and
{cmd:estat ecequal} apply one by default; {opt mtest()} selects Holm (the
default), Bonferroni, Sidak or none.


{marker map}{...}
{title:Step to equation map}

{pstd}
Every computational step and the equation or source it implements:

{p2colset 8 46 48 2}{...}
{p2col :{bf:Code step}}{bf:Source}{p_end}
{p2col :conditional ECM design}eq. (7), (12)-(15){p_end}
{p2col :equation-by-equation OLS}eq. (18){p_end}
{p2col :contemporaneous covariance}eq. (55)-(56){p_end}
{p2col :FGLS cross-products}eq. (50)-(53){p_end}
{p2col :two-step FGLS and variance}eq. (57)-(58){p_end}
{p2col :iterated FGLS}sec. 2.3, steps (a)-(d){p_end}
{p2col :equation restriction matrix}eq. (61), (63)-(64){p_end}
{p2col :number of restrictions q}eq. (61); KS (2020) fn. 12{p_end}
{p2col :bounds F, Wald form}eq. (76)-(77), (112){p_end}
{p2col :bounds F, RSS form}eq. (69)-(76){p_end}
{p2col :joint / subset bounds test}eq. (65)-(67), (78)-(79){p_end}
{p2col :bounds decision rule}eq. (118){p_end}
{p2col :tabulated F bounds}PSS (2001) Table CI{p_end}
{p2col :tabulated t bounds}PSS (2001) Table CII{p_end}
{p2col :small-sample F bounds}Narayan (2005){p_end}
{p2col :simulated SUR bounds}sec. 2.4, Approach A{p_end}
{p2col :residual bootstrap}sec. 2.4, Approach B;{p_end}
{p2col :}MSG (2018); PSU (2010){p_end}
{p2col :long-run coefficients}eq. (82)-(84){p_end}
{p2col :delta-method variance}eq. (85)-(91){p_end}
{p2col :Fieller set}Fieller (1954); sec. 4.6{p_end}
{p2col :cross-equation long-run tests}eq. (92)-(93), Remark 10{p_end}
{p2col :poolability}sec. 4.5(a){p_end}
{p2col :lambda equality}sec. 4.5(c){p_end}
{p2col :efficiency gain}eq. (95){p_end}
{p2col :Breusch-Pagan LM}eq. (96)-(99){p_end}
{p2col :Pesaran CD}eq. (100); Pesaran (2004){p_end}
{p2col :Breusch-Godfrey}Remark 5{p_end}
{p2col :lag selection by AIC / SBC}Remark 2, eq. (19)-(20){p_end}
{p2colreset}{...}


{marker dep}{...}
{title:Departures from the draft, and open points}

{pstd}
These are stated plainly rather than hidden, because each one is a decision a
reader may want to revisit.

{phang}
{bf:1. The Pesaran CD statistic.} As printed, equation (100) omits the factor 2
under the square root. {cmd:surardl} implements Pesaran's own formula,
CD = sqrt(2T/(N(N-1))) sum_{i<j} r(ij), which reproduces the value CD = 1.32
reported in section 5 from the correlation matrix in the paper's own Table 9.
The printed version does not.

{phang}
{bf:2. The restricted system in the RSS form.} Equation (69) restricts
equation {it:i} and says the other equations "remain unrestricted". The
authors' OxGauss and Stata scripts restrict all equations simultaneously.
{cmd:surardl} implements the paper's version as {opt fstat(rss)} and the
scripts' version as {opt fstat(rssall)}, and reports which was used.

{phang}
{bf:3. The deterministic case of the published application.} The authors'
posted scripts include a trend in the unrestricted model and drop it from the
restricted one, which is case 4 with {it:q} = 5. The published Table 10 is
reproduced exactly by case 3 with {it:q} = 4 and no trend. {cmd:surardl}
defaults to case 3 and lets you set any case explicitly.

{phang}
{bf:4. The Monte Carlo baseline.} Section 4.1 states lambda = -0.3,
beta = -0.09 and theta = 0.3. Those are mutually inconsistent, since
theta = -beta/lambda = -0.3 for that pair. The shipped self-test uses the
internally consistent set beta = +0.09.

{phang}
{bf:5. Equation numbering.} Sections 3.3 and 4 of the draft cite equations
(159), (164), (170), (178) and (189)-(195), which do not appear in the
58-page document. The restriction matrices for the poolability, long-run
equality and lambda equality tests are therefore reconstructed from the
hypotheses as stated in words in section 4.5, not copied from a displayed
equation.

{phang}
{bf:6. The quantity called RFN.} Section 5 refers to a "relative Frobenius
norm" measuring the quality of Sigma-hat but does not define it. {cmd:surardl}
reports its own definition, ||Sigma - diag(Sigma)||_F / ||Sigma||_F, and labels
it as such.

{phang}
{bf:7. Heterogeneous lag orders.} The paper assumes a common lag order and
lists unit-specific orders as future work (section 6). {cmd:surardl} supports
them via {opt maxlags()} or {opt lagmatrix()}; the asymptotic theory of
Theorems 2 and 4 carries over by Remark 1, but the Monte Carlo evidence in
section 4 does not cover this case.

{phang}
{bf:8. What is not provided.} The paper offers no constancy test, no uniform
confidence band for the long-run relationship and no finite-sample correction
for the cross-equation Wald tests; section 6 lists the last of these as future
work. None of them is invented here.


{marker val}{...}
{title:Validation}

{pstd}
The build was checked against external benchmarks rather than against itself:

{phang}
{bf:Against sureg.} On an identical design the coefficient vector and
covariance matrix agree with {helpb sureg} to about 1e-10, and with
{cmd:sureg, isure} to six decimals under {opt method(iterated)}.

{phang}
{bf:Against regress.} Under {opt method(ols)} the Wald form of the bounds
statistic equals the F statistic from {helpb regress} followed by
{helpb test}, to six decimals.

{phang}
{bf:Against nlcom.} The delta-method standard errors of the long-run
coefficients equal those from {helpb nlcom} applied to the same ratio.

{phang}
{bf:Against PSS Table CI.} With Sigma = {bf:I} and {it:T} = 500 the
{opt simulate()} engine reproduces the published asymptotic bounds to
simulation error; for case 5, {it:K} = 3 the simulated {it:I}(0) bounds are
3.481 and 4.010 against published values of 3.47 and 4.01. This exercises the
design construction, the restriction set, the FGLS solve and the Wald form
together, from first principles.

{phang}
{bf:Against the paper's own tables.} On the shipped ASEAN-6 data the command
reproduces Table 9 (the residual correlation matrix), the Breusch-Pagan
statistic (28.84 against 28.91), the Pesaran CD statistic (1.30 against 1.32)
and both the OLS and SUR columns of Table 10, including the speeds of
adjustment, their standard errors, the bounds F statistics and the long-run
coefficients.

{phang}
{bf:Against the DGP.} {cmd:surardl_example.do} regenerates the paper's own
Monte Carlo design with known parameters and checks parameter recovery,
consistency as {it:T} grows, the relative-efficiency pattern of Tables 1-2,
bootstrap size under H0 and power under H1.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
