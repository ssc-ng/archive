{smcl}
{* *! version 1.0.0  11oct2026}{...}
{vieweralsosee "suradf" "help suradf"}{...}
{vieweralsosee "[R] sureg" "help sureg"}{...}
{viewerjumpto "Model" "suradf_methods##model"}{...}
{viewerjumpto "Estimator" "suradf_methods##estimator"}{...}
{viewerjumpto "Why no critical value table" "suradf_methods##nocv"}{...}
{viewerjumpto "Algorithm" "suradf_methods##algorithm"}{...}
{viewerjumpto "Step-equation map" "suradf_methods##map"}{...}
{viewerjumpto "Departures from the paper" "suradf_methods##departures"}{...}
{viewerjumpto "Limitations" "suradf_methods##limits"}{...}
{viewerjumpto "Validation" "suradf_methods##validation"}{...}
{viewerjumpto "References" "suradf_methods##refs"}{...}
{title:Title}

{phang}
{bf:suradf methods} {hline 2} Methods and formulas for the series-specific
SUR-ADF test


{marker model}{...}
{title:The model}

{pstd}
Equation (1) of Breuer, McNown and Wallace (2002, p. 529) is a system of {it:N}
augmented Dickey-Fuller regressions, one per panel member, with no restriction
imposed across members under either hypothesis:

{p 8 8 2}
{bf:Dy(1,t) = a(1) + b(1)*y(1,t-1) + SUM(j=1..k1) d(1,j)*Dy(1,t-j) + u(1,t)}{break}
{bf:   ...}{break}
{bf:Dy(N,t) = a(N) + b(N)*y(N,t-1) + SUM(j=1..kN) d(N,j)*Dy(N,t-j) + u(N,t)}

{pstd}
for {bf:t = 1, ..., T}. Two features matter. First, the lag orders {bf:k(i)}
are free to differ, so heterogeneous serial correlation is handled directly.
Second, the errors are allowed to be contemporaneously correlated,

{p 8 8 2}
{bf:E[u(i,t) u(j,t)] = sigma(i,j)},   collected in the {it:N} x {it:N} matrix
{bf:Sigma},

{pstd}
while remaining serially uncorrelated once the lagged differences are in. The
{it:N} hypotheses

{p 8 8 2}
{bf:H0(i): b(i) = 0}  against  {bf:H1(i): b(i) < 0},   i = 1, ..., N

{pstd}
are tested {bf:individually}. There is no joint panel hypothesis anywhere in
the procedure. This is the whole departure from Levin-Lin, Im-Pesaran-Shin,
Maddala-Wu and the Sarno-Taylor MADF, all of which test one hypothesis about
the panel as a whole.

{pstd}
Deterministic terms: each test equation carries an intercept, and the data
generating process under the null is a {bf:driftless} unit-root process. The
asymmetry is deliberate - the intercept admits a non-zero mean under the
stationary alternative, while a drift under the null would impart a
deterministic trend. Footnote 9 of the paper appeals to West (1988) for the
distributional consequences.


{marker estimator}{...}
{title:The estimator}

{pstd}
Write equation {bf:i} as {bf:Dy(i) = X(i)*beta(i) + u(i)}, where {bf:X(i)} is
{it:T_eff} x {it:p(i)} with {bf:p(i) = 2 + k(i)} columns: the lagged level, an
intercept, and {bf:k(i)} lagged differences. Because the lag orders differ, the
columns of {bf:X(i)} differ across equations, which is exactly the setting
Zellner's (1962) seemingly unrelated regressions estimator was designed for.

{pstd}
{cmd:suradf} uses the two-step feasible GLS estimator. Stage one fits each
equation by OLS and forms

{p 8 8 2}
{bf:Sigma-hat(i,j) = e(i)'e(j) / T_eff}

{pstd}
(or {bf:e(i)'e(j) / sqrt((T_eff-p(i))(T_eff-p(j)))} under {opt dfk}). Stage two
solves the stacked generalised least squares problem. Writing {bf:S = inverse of
Sigma-hat}, the normal equations have the block form

{p 8 8 2}
{bf:A(i,j) = S(i,j) * X(i)'X(j)},{space 6}{bf:c(i) = SUM(j) S(i,j) * X(i)'Dy(j)}

{p 8 8 2}
{bf:beta-hat = A-inverse * c},{space 8}{bf:V = A-inverse}

{pstd}
The SURADF statistic for series {bf:i} is the t-ratio on its lagged level,

{p 8 8 2}
{bf:SURADF(i) = beta-hat(i,1) / sqrt(V(i,1;i,1))}

{pstd}
Implementation note: rather than building the {it:T_eff*N} x {it:p} block-diagonal
design and an {it:T_eff*N} x {it:T_eff*N} Kronecker weight matrix, the engine lays the
{bf:X(i)} side by side in one {it:T_eff} x {it:K} matrix {bf:W}, records which
equation owns each column in an index vector {bf:q}, and forms the system in one
elementwise product,

{p 8 8 2}
{bf:A = S[q,q] :* (W'W)},{space 10}{bf:c = rowsum( S[q,.] :* (W'Dy) )}

{pstd}
This is algebraically identical to the Kronecker form - verified to within
5e-16 - and is what makes 10,000 replications of a twenty-equation system
feasible. With {opt isure} the covariance matrix is re-formed from the SUR
residuals and the step repeated to convergence, giving Zellner's iterated
estimator.


{marker nocv}{...}
{title:Why there is no critical value table}

{pstd}
Under the null the lagged level is an {bf:I(1)} regressor, so the statistic has
a Dickey-Fuller type limiting distribution rather than a normal one. But unlike
the single-equation case, the SUR weighting makes the limit depend on {bf:Sigma}
itself - on the full pattern of cross-equation correlations, on {it:N}, and on
{it:T}. The paper is explicit about the consequence (p. 531): the critical
values reported there "cannot be applied directly to other data sets."

{pstd}
Three regularities hold, and are visible in the paper's Table 1 and in this
command's output:

{p 6 10 2}o {space 1}absolute critical values {bf:fall} as {it:T} rises, as in
the Dickey-Fuller case;

{p 6 10 2}o {space 1}they {bf:rise} with {it:N}, holding everything else fixed -
the opposite of the usual panel intuition;

{p 6 10 2}o {space 1}they {bf:rise} with the residual cross-correlation. At
{it:T}=100 and {it:N}=10, moving the correlations from 0.20-0.30 to 0.70-0.80
moves the 5% value from about -3.42 to about -4.65.

{pstd}
Against the Dickey-Fuller 5% value of roughly -2.89 at these sample sizes, the
practical message is blunt: {bf:reading a SUR t-ratio against a Dickey-Fuller
table over-rejects, badly, and more so the more correlated the panel is.} The
simulation is not optional refinement; it is the test.


{marker algorithm}{...}
{title:The algorithm}

{pstd}
{bf:1. Lag selection} (by default, the rule in Section V). For each series
regress {bf:Dy(i,t)} on {opt maxlags()} of its own lagged differences {bf:with
no intercept}. Drop the highest lag while its t-ratio is below 1.645 in absolute
value {bf:and} the fit without it shows no serial correlation by Ljung-Box Q at
4, 8 and 12 lags at the 10% level. A lag is kept even when insignificant if
dropping it induces serial correlation.

{pstd}
{bf:2. Observed statistics.} Fit the full system above by SUR on the common
sample, which starts at {bf:max(k)+2} so that all equations share identical
observations, and take the {it:N} t-ratios on the lagged levels.

{pstd}
{bf:3. The null model.} Fit a {bf:restricted} SUR of {bf:Dy(i,t)} on its own
lagged differences only - no intercept and no lagged level - and treat the
resulting lag coefficients {bf:d-hat(i,j)} and covariance matrix
{bf:Sigma-hat(0)} as the truth.

{pstd}
{bf:4. Simulate.} Repeat {opt reps()} times:

{p 10 14 2}
(a) draw {bf:u(t) = S*z(t)} with {bf:z(t)} standard normal and {bf:S} the lower
Cholesky factor of {bf:Sigma-hat(0)}, so that {bf:Sigma-hat(0) = S*S'};

{p 10 14 2}
(b) build {bf:Dy*(i,t) = SUM(j) d-hat(i,j)*Dy*(i,t-j) + u*(i,t)} - strictly own
lags, never a cross-equation term - from zero starting values;

{p 10 14 2}
(c) cumulate to levels, {bf:y*(i,t) = y*(i,t-1) + Dy*(i,t)}, so each simulated
series has exactly one unit root and no drift;

{p 10 14 2}
(d) discard the first {opt burn()} observations, leaving the same usable sample
as the real data;

{p 10 14 2}
(e) re-estimate the {bf:full} system - {bf:intercept and lagged level included},
although the simulated data have neither - and store the {it:N} t-ratios.

{pstd}
{bf:5. Critical values.} For each series take the empirical 1st, 5th and 10th
percentiles of its own {opt reps()} simulated statistics. These are
series-specific, as in Table 5 of the paper; the panel average reported below
the table is the Table 1 form.

{pstd}
Step 4(e) is the one most easily got wrong. The simulated data contain no
intercept and no lagged level, yet both must appear in the fitted equation,
because the observed statistic was computed from an equation that contains them.
Fitting the simulated data under the true restriction would produce critical
values that do not describe the observed statistic at all.


{marker map}{...}
{title:Step-equation map}

{pstd}
Each block of the engine against the place in the paper that defines it.

{p2colset 8 18 20 2}{...}
{p2col :{bf:S1}}Eq. (1), p. 529 - design matrices with heterogeneous {bf:k(i)}{p_end}
{p2col :{bf:S2}}Sec. V, pp. 539-540 - general-to-specific lag selection{p_end}
{p2col :{bf:S3}}Eq. (3), p. 532 and Sec. III, p. 531 - SUR fit, t on lagged level{p_end}
{p2col :{bf:S4}}Sec. V, p. 540 - restricted null SUR, no intercept, no level{p_end}
{p2col :{bf:S5}}Eq. (2), p. 532 and fn. 10, p. 540 - Cholesky-correlated normals{p_end}
{p2col :{bf:S6}}Sec. V, p. 540 - driftless unit-root recursion, own lags only{p_end}
{p2col :{bf:S7}}fn. 5, p. 532 and Sec. V, p. 540 - 50 burn-in, zero start{p_end}
{p2col :{bf:S8}}Sec. III, p. 532 - re-estimate with intercept and lagged level{p_end}
{p2col :{bf:S9}}Sec. III, p. 532 and Table 5 - series-specific quantiles{p_end}
{p2col :{bf:S10}}Table 5 note, p. 541 - AVECOR from the null-model covariance{p_end}
{p2col :{bf:S11}}p. 533 - Dickey-Fuller benchmark via the MacKinnon surface{p_end}


{marker departures}{...}
{title:Departures from the paper, and why}

{pstd}
Everything below is a deliberate choice, flagged so it can be checked.

{p 6 10 2}
{bf:reps(1000) by default.} The paper uses 10,000, which is minutes rather than
seconds for a large system. A note prints whenever fewer than 1,000 are used,
and {cmd:reps(10000)} reproduces the paper's setting.

{p 6 10 2}
{bf:p-values are reported.} The paper gives critical values only. The p-value is
the left-tail share of simulated statistics. The verdict block takes its
decisions from the critical values, not from the p-value.

{p 6 10 2}
{bf:lags(aic) and lags(bic) exist.} The paper specifies only the Section V rule,
which is the default. The information criteria are conveniences outside the
paper; the selected {bf:k} is always printed because the result depends on it.

{p 6 10 2}
{bf:dist(bootstrap) exists.} The paper assumes normal innovations (fn. 10).
Resampling whole residual rows preserves cross-sectional dependence without
normality, but no critical values in the paper cover it.

{p 6 10 2}
{bf:trend exists.} The paper has no trend case and argues against one for real
exchange rates. A warning is printed.

{p 6 10 2}
{bf:Ljung-Box degrees of freedom.} The paper says "a Q-stat at 4, 8 and 12 lags"
without stating the degrees of freedom. {cmd:suradf} uses {bf:m}, matching
{helpb wntestq}.

{p 6 10 2}
{bf:AVECOR is read from the null model.} The note to Table 5 describes AVECOR as
coming from "the SUR regressions estimated without intercepts and lagged
differences", which can be read either as the restricted null model of Section V
(no intercept, {it:with} lagged differences) or as a model with neither, whose
residuals would simply be the first differences. {cmd:suradf} takes the first
reading, because it is what the prose of Section V describes and what the
independent gretl implementation of the same paper does. If you need the second,
the residual correlation matrix is returned in {cmd:r(corr)} and the raw
differences are one {helpb correlate} away.

{p 6 10 2}
{bf:Covariance divisor matches sureg.} The paper does not state one. The default
is {bf:T_eff}, which is what {helpb sureg} uses, so a hand-built {cmd:sureg}
replication of the point estimates will agree; {opt dfk} switches to
{helpb sureg}'s {cmd:dfk} convention. Whichever is chosen is applied identically
to the observed statistic and to every simulated one.


{marker limits}{...}
{title:Limitations}

{pstd}
These are properties of the method, not of this implementation, and none of them
is filled in by invention.

{p 6 10 2}
{bf:No asymptotic theory.} The paper provides no limiting distribution and no
closed-form critical values. Every reported critical value comes from
simulation.

{p 6 10 2}
{bf:Small N, large T only.} Feasible GLS needs an invertible {it:N} x {it:N}
covariance matrix estimated from {it:T_eff} observations. As {it:N} approaches
{it:T}, the estimate degenerates and the procedure fails - the historical
implementations of this test failed here first. {cmd:suradf} refuses to run
rather than return a number it cannot stand behind.

{p 6 10 2}
{bf:Balanced panels only.} SUR requires a common sample. The paper never treats
unbalanced panels or gaps, so neither does this command.

{p 6 10 2}
{bf:Modest power at short T near a unit root.} The authors say so themselves:
other panel tests have more power in that region. Their defence is that those
tests answer a different and less useful question.

{p 6 10 2}
{bf:Results depend on panel composition.} The critical values are a function of
the covariance matrix of the whole system, so changing membership changes every
member's critical value. See the decision guide in
{helpb suradf##guidance:help suradf}.

{p 6 10 2}
{bf:Not a cointegration test.} Applying the procedure to residuals from a
first-stage regression would require critical values that account for the
estimated cointegrating vector, which this command does not provide.


{marker validation}{...}
{title:Validation}

{pstd}
The engine was checked three ways before release.

{p 6 10 2}
{bf:1. Algebra.} The indexed form of the FGLS normal equations was verified
against a brute-force Kronecker construction on a system with lag orders
(1,2,0,3); the coefficient vectors and covariance matrices agree to 5e-16.

{p 6 10 2}
{bf:2. The paper's own published numbers.} An independent implementation of the
algorithm reproduces five cells of Table 1 of the paper, spanning {it:N} = 5,
10 and 20 and correlations from 0.20 to 0.80, with discrepancies between 0.005
and 0.032 at 10,000 replications - within Monte Carlo error. The MacKinnon
surface used for the Dickey-Fuller benchmark reproduces the -2.93, -2.89 and
-2.88 quoted on p. 533.

{p 6 10 2}
{bf:3. Size and power.} A Monte Carlo study of the full procedure - including
lag selection and the null-model simulation - confirms the rejection rate under
a true unit root sits at the nominal level, and reports power against a
stationary alternative. See {bf:VALIDATION.md} in the package folder for the
tables, and {cmd:suradf_example.do} to reproduce them in Stata.


{marker refs}{...}
{title:References}

{phang}
Breuer, J. B., R. McNown, and M. Wallace. 2002. Series-specific unit root tests
with panel data. {it:Oxford Bulletin of Economics and Statistics} 64(5):
527-546.
{browse "https://doi.org/10.1111/1468-0084.00276":doi:10.1111/1468-0084.00276}

{phang}
MacKinnon, J. G. 2010. Critical values for cointegration tests. Queen's
University Economics Department Working Paper 1227.

{phang}
West, K. D. 1988. Asymptotic normality when regressors have a unit root.
{it:Econometrica} 56(6): 1397-1418.
{browse "https://doi.org/10.2307/1912517":doi:10.2307/1912517}

{phang}
Zellner, A. 1962. An efficient method of estimating seemingly unrelated
regressions and tests for aggregation bias.
{it:Journal of the American Statistical Association} 57(298): 348-368.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb suradf}, {manhelp sureg R}, {manhelp dfuller TS}
