{smcl}
{* *! version 1.0.1  10oct2026}{...}
{vieweralsosee "surardl postestimation" "help surardl_postestimation"}{...}
{vieweralsosee "surardl methods" "help surardl_methods"}{...}
{vieweralsosee "sureg" "help sureg"}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "surardl##syntax"}{...}
{viewerjumpto "Description" "surardl##description"}{...}
{viewerjumpto "Options" "surardl##options"}{...}
{viewerjumpto "Remarks" "surardl##remarks"}{...}
{viewerjumpto "Interpreting the output" "surardl##output"}{...}
{viewerjumpto "Examples" "surardl##examples"}{...}
{viewerjumpto "Stored results" "surardl##results"}{...}
{viewerjumpto "References" "surardl##references"}{...}
{viewerjumpto "Author" "surardl##author"}{...}

{title:Title}

{phang}
{bf:surardl} {hline 2} Seemingly unrelated ARDL (SUR-ARDL) cointegration:
estimation, bounds testing and cross-equation inference


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:surardl} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{pstd}
The data must be {helpb xtset}. Each panel is one equation of the system.
{it:depvar} and {it:indepvars} are measured in {bf:levels}; {cmd:surardl}
builds the conditional error-correction form itself.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt lags(numlist)}}lag orders {it:p q1 ... qK}; default {cmd:lags(1)}{p_end}
{synopt :{opt maxl:ags(numlist)}}maximum orders for automatic selection{p_end}
{synopt :{opt aic}}select lags by the AIC{p_end}
{synopt :{opt bic}}select lags by the SBC; the default when {opt maxlags()} is used{p_end}
{synopt :{opt lagm:atrix(name)}}{it:N} x ({it:K}+1) matrix of unit-specific orders{p_end}
{synopt :{opt maxcombs(#)}}cap on lag permutations; default {cmd:maxcombs(20000)}{p_end}
{synopt :{opt qmin(#)}}minimum distributed-lag order; default {cmd:qmin(1)}{p_end}

{syntab:Deterministic components}
{synopt :{opt cas:e(#)}}PSS case 1-5; default {cmd:case(3)}{p_end}
{synopt :{opt nocon:stant}}no constant and no trend (case 1){p_end}
{synopt :{opt trend}}add a linear trend (case 5, or case 4 with {opt restricted}){p_end}
{synopt :{opt restricted}}restrict the constant or trend under H0 (case 2 or 4){p_end}
{synopt :{opt trendv:ar(varname)}}use {it:varname} as the trend{p_end}

{syntab:Estimation}
{synopt :{opt meth:od(string)}}{cmd:twostep} (default), {cmd:iterated} or {cmd:ols}{p_end}
{synopt :{opt iter:ate(#)}}iteration limit; default {cmd:iterate(200)}{p_end}
{synopt :{opt tol:erance(#)}}convergence tolerance; default {cmd:tolerance(1e-9)}{p_end}
{synopt :{opt sig:madf(string)}}divisor for Sigma-hat: {cmd:t} (default), {cmd:dfmax}, {cmd:dfk}, {cmd:dfk2}{p_end}
{synopt :{opt small}}report t and F rather than z and chi-squared{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Bounds test}
{synopt :{opt f:stat(string)}}{cmd:wald} (default), {cmd:rss} or {cmd:rssall}{p_end}
{synopt :{opt boot:strap(#)}}SUR residual-bootstrap critical values and p-values{p_end}
{synopt :{opt seed(#)}}random-number seed; default {cmd:seed(20261010)}{p_end}
{synopt :{opt boott:arget(string)}}{cmd:equation} (default) or {cmd:joint} null{p_end}
{synopt :{opt bootd:gp(string)}}{cmd:rw} (default) or {cmd:vecm} marginal process{p_end}
{synopt :{opt bootl:ags(#)}}order of the marginal VECM; default {cmd:bootlags(1)}{p_end}
{synopt :{opt nodr:ift}}generate y* under the null without a drift{p_end}
{synopt :{opt sim:ulate(#)}}simulated SUR I(0)/I(1) critical value bounds{p_end}
{synopt :{opt simr:ho(#)}}cross-unit correlation of the simulated regressors{p_end}

{syntab:Reporting}
{synopt :{opt bgl:ags(#)}}order of the Breusch-Godfrey test; default {cmd:bglags(1)}{p_end}
{synopt :{opt eq:names(string)}}names for the {it:N} equations{p_end}
{synopt :{opt nocta:ble}}suppress the coefficient table{p_end}
{synopt :{opt nohe:ader}}suppress the header{p_end}
{synopt :{opt nolr:table}}suppress the long-run table{p_end}
{synopt :{opt nobounds}}suppress the bounds test{p_end}
{synopt :{opt nodiag:nostics}}suppress the diagnostics block{p_end}
{synopt :{opt gr:aph}}draw the standard figure set{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:surardl} estimates the seemingly unrelated autoregressive distributed lag
model of {help surardl##AF2026:Arif and Furuoka (2026)}. The conditional
error-correction specification of {help surardl##PSS2001:Pesaran, Shin and
Smith (2001)} is written for each of {it:N} cross-sectional units and the
{it:N} equations are estimated jointly as a {help surardl##Z1962:Zellner
(1962)} SUR system by feasible GLS.

{pstd}
For unit {it:i} the estimated equation is the conditional ECM

{p 8 8 2}
D.y(i,t) = mu(i) + delta(i) t + lambda(i) y(i,t-1)
+ sum_k beta(k,i) x(k,i,t-1)
+ sum_j psi(j,i) D.y(i,t-j)
+ sum_k sum_j gamma(k,j,i) D.x(k,i,t-j) + u(i,t),

{pstd}
with E[u(i,t) u(j,t)] = sigma(ij) left unrestricted. The long-run
coefficients are the ratios theta(k,i) = -beta(k,i)/lambda(i).

{pstd}
Because the ARDL lag structure absorbs short-run dynamics and regressor
endogeneity parametrically, the estimator needs only the {it:N} x {it:N}
contemporaneous covariance Sigma, not the 2{it:N} x 2{it:N} long-run
covariance required by the FM-SUR estimator of
{help surardl##WGH2020:Wagner, Grabarczyk and Hong (2020)} or the banded
inverse autocovariance of {help surardl##LR2025:Lin and Reuvers (2025)}.

{pstd}
{cmd:surardl} is designed for panels with small {it:N} and moderate to large
{it:T}; the covariance matrix needs {it:T} > {it:N} to be invertible and
{it:T}/{it:N} of at least about 5 to be estimated with reasonable precision.

{pstd}
The engine is numerically identical to {helpb sureg} on the same design
(agreement to about 1e-10), so everything Stata offers after {cmd:sureg} --
{helpb test}, {helpb lincom}, {helpb nlcom}, {helpb testnl} -- works here,
with coefficients addressed as {cmd:[}{it:eqname}{cmd:]L.}{it:varname}.

{pstd}
See {helpb surardl_methods:help surardl methods} for the equation-by-equation
derivation and the map from each code step to the paper, and
{helpb surardl_postestimation:help surardl postestimation} for the
{cmd:estat} suite.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(numlist)} sets the autoregressive order {it:p} for {it:depvar} and
the distributed-lag orders {it:q1 ... qK} for {it:indepvars}. Supply either a
single number, applied to every variable, or {it:K}+1 numbers. {it:p} must be
at least 1. The default {cmd:lags(1)} gives the ARDL(1,1,...,1) specification
on which sections 2 to 5 of the paper are built.

{phang}
{opt maxlags(numlist)} triggers automatic lag selection by information
criterion, equation by equation, over all admissible combinations. Every
candidate is fitted on the {it:same} effective sample -- the one implied by the
maximum orders -- so the criteria are comparable and Sigma-hat is defined on a
common window. This extends the paper, which assumes a common lag order; see
Remark 1 and the final paragraph of section 6.

{phang}
{opt qmin(#)} is the smallest distributed-lag order the search may choose. The
default {cmd:qmin(1)} always keeps the contemporaneous D.x term, which is what
makes the conditional model's error orthogonal to the regressor innovations
(Appendix A, equation A.13). Set {cmd:qmin(0)} to allow a regressor to enter
in lagged levels only, as {helpb ardl} does; the weak-exogeneity argument then
no longer applies to that regressor.

{phang}
{opt lagmatrix(name)} supplies unit-specific orders directly as an {it:N} x
({it:K}+1) matrix, rows in the sort order of the panel variable.

{dlgtab:Deterministic components}

{phang}
{opt case(#)} selects the deterministic specification, in the numbering of
Pesaran, Shin and Smith (2001):

{p2colset 12 24 26 2}{...}
{p2col :{bf:1}}no constant, no trend; {it:q} = {it:K}+1 restrictions{p_end}
{p2col :{bf:2}}restricted constant, no trend; {it:q} = {it:K}+2{p_end}
{p2col :{bf:3}}unrestricted constant, no trend; {it:q} = {it:K}+1 (default){p_end}
{p2col :{bf:4}}unrestricted constant, restricted trend; {it:q} = {it:K}+2{p_end}
{p2col :{bf:5}}unrestricted constant, unrestricted trend; {it:q} = {it:K}+1{p_end}
{p2colreset}{...}

{phang}
In cases 2 and 4 the deterministic term is part of the null hypothesis and is
therefore {it:removed} from the restricted model, which is why the number of
restrictions rises by one. {cmd:surardl} derives {it:q} from the case and
{it:K}; it is never hard-coded.

{phang}
{opt noconstant}, {opt trend} and {opt restricted} are the equivalent
{helpb ardl}-style switches and simply map onto {opt case()}. Specifying both
a switch and {opt case()} is allowed only if they agree.

{phang}
{opt trendvar(varname)} uses an existing variable as the trend instead of the
default sequence 1, 2, ..., {it:T} over the estimation sample.

{dlgtab:Estimation}

{phang}
{opt method(string)} chooses {cmd:twostep} feasible GLS (equations 55-58, the
default and what the paper recommends), {cmd:iterated} FGLS (which converges to
the maximum likelihood estimator under normality) or {cmd:ols}
equation-by-equation estimation as a benchmark. Simulation 6 of the paper finds
iteration brings negligible gains.

{phang}
{opt sigmadf(string)} sets the divisor in equation (55):
{cmd:t} divides by {it:T} (the Zellner maximum likelihood form, the
{helpb sureg} default, and the divisor used by the authors' own code);
{cmd:dfmax} uses {it:T} - max({it:m_i}, {it:m_j});
{cmd:dfk} and {cmd:dfk2} reproduce the corresponding {helpb sureg} options.
When every equation has the same number of regressors these choices differ only
by a scale factor, so they change the standard errors but not the point
estimates.

{dlgtab:Bounds test}

{phang}
{opt fstat(string)} selects the form of the equation bounds statistic.
{cmd:wald} (default) uses the Wald form of equations (77) and (112),
{it:F} = {it:W}/{it:q}, computed from the unrestricted system alone. This is
the form behind the published application. {cmd:rss} re-estimates the system
with the level terms removed from equation {it:i} only, as equations (69)-(76)
specify, and forms the RSS-based {it:F}. {cmd:rssall} removes them from every
equation at once, which is what the authors' own OxGauss and Stata scripts do.
The three agree asymptotically but differ in finite samples, chiefly by a
factor of about {it:T}/({it:T} - {it:m_i}); see {helpb surardl_methods}.

{phang}
{opt bootstrap(#)} computes SUR-specific critical values and p-values by the
residual bootstrap described in {helpb surardl_methods}, following
{help surardl##MSG2018:McNown, Sam and Goh (2018)} and
{help surardl##PSU2010:Palm, Smeekes and Urbain (2010)}. The innovations of all
{it:N} equations are resampled as one time-indexed vector, so the
contemporaneous cross-equation covariance is preserved, and every replication
re-runs the complete statistic. This is the recommended inference route, and
the only one the paper endorses without qualification.

{phang}
{opt boottarget(string)} controls which null is imposed when generating the
pseudo-data. {cmd:equation} (default) imposes H0 on the equation being tested
and leaves the others unrestricted, as McNown et al. do. {cmd:joint} imposes H0
on every equation at once, matching the design of the authors' own Monte Carlo
code; it is one pass rather than {it:N} and also calibrates the joint test.

{phang}
{opt bootdgp(string)} sets the marginal process for the regressors.
{cmd:rw} (default) regenerates them as random walks driven by the resampled
innovations, which is the data-generating process behind the PSS and Narayan
tabulations and cannot diverge. {cmd:vecm} instead fits an unrestricted VECM of
order {opt bootlags()} to each unit's regressors. {cmd:vecm} uses more of the
data's own dynamics but needs a long sample: on short {it:T} the fitted VECM
often has explosive roots, and those replications are discarded and reported as
failures.

{phang}
{opt nodrift} generates the pseudo-dependent variable under the null as a
driftless random walk, as in the PSS Table CI design, instead of propagating
the fitted intercept and trend into its level. The default follows McNown et
al. literally and keeps the bootstrap faithful to the data's own deterministic
behaviour; {opt nodrift} makes the critical values more directly comparable
with the tabulated ones. On the shipped example the default gives smaller
critical values for five of six equations, so it is not a conservative choice
in either direction -- it is a different question. See
{helpb surardl_methods##boot:help surardl methods}.

{phang}
{opt simulate(#)} computes SUR-specific {it:I}(0) lower and {it:I}(1) upper
critical value {it:bounds} by Monte Carlo under the null, using the estimated
Sigma-hat as the innovation covariance. This is Approach A of section 2.4.
It has been validated against the published tables: with Sigma = I and
{it:T} = 500 it reproduces the PSS asymptotic bounds to simulation error.

{phang}
{opt simrho(#)} equicorrelates the simulated regressor innovations across
units. The default 0 reproduces the PSS design, in which the regressors are
independent across units; 1 reproduces the authors' OxGauss design, in which
every unit's regressors are driven by the same shocks. Theorem 3(c) makes the
null distribution depend on the other equations' regressors, so this matters.


{marker remarks}{...}
{title:Remarks}

{dlgtab:Sample requirements}

{pstd}
{cmd:surardl} uses the longest run of consecutive periods in which {it:every}
panel is observed with no missing values, because Sigma-hat is built from
contemporaneous residuals and therefore needs synchronised observations. Any
complete periods outside that run are dropped and the count is reported. The
command will not silently use an unbalanced window.

{dlgtab:Which critical values to use}

{pstd}
This is the single most important practical decision, and the tabulated values
are not a safe default. The PSS and Narayan bounds are calibrated for the
{it:single-equation OLS} F statistic. The SUR statistic has a more dispersed
null distribution in small samples, because Sigma is estimated jointly from the
same {it:T} observations, so the tabulated bounds are {it:liberal} here and
over-reject. Simulation 2 of the paper measures the distortion and finds it
worst when {it:N} is large and the cross-equation correlation strong; equation
(193) of the paper gives the rule

{p 8 8 2}
use tabulated values if {it:N} <= 3 or mean correlation <= 0.3;
use bootstrap values if {it:N} >= 5 and mean correlation >= 0.5.

{pstd}
{cmd:surardl} reports the tabulated bounds for reference and prints a note
whenever no resampling has been requested. When the decision matters, run
{opt bootstrap()}.

{dlgtab:Long-run coefficients}

{pstd}
Simulation 5 of the paper documents severe under-coverage of the delta-method
confidence interval for theta = -beta/lambda, which worsens as {it:T} grows
because theta is super-consistent while the delta-method standard error is
calibrated to a root-{it:T} consistent estimator. {cmd:surardl} reports the
delta-method interval because it is the paper's equation (89), but
{cmd:estat longrun, fieller} gives the Fieller (1954) set, which inverts
H0: beta + theta lambda = 0 and never divides by lambda-hat. When lambda is
weakly identified the Fieller set is unbounded; that is the honest answer, and
the delta-method interval cannot express it. {cmd:estat longrun, bootstrap(}#{cmd:)}
gives percentile and bias-corrected intervals.

{dlgtab:Checking the maintained assumptions}

{pstd}
Two assumptions carry the framework and both are testable. Sigma must be
non-diagonal for SUR to beat OLS at all (Proposition 1); the Breusch-Pagan LM
test in the diagnostics block is the check. The conditional errors must be
serially uncorrelated for Sigma, rather than a long-run covariance matrix, to
be the right GLS weight (Remark 4); the Breusch-Godfrey test is the check, and
if it rejects, raise {opt lags()}.

{dlgtab:Relation to other commands}

{pstd}
{helpb ardl} (Kripfganz and Schneider) is the single-equation reference. Use it
to see what one country's ARDL looks like on its own; {cmd:surardl} is what
makes the {it:N} equations talk to each other. Do not take critical values from
{cmd:estat ectest} and apply them to a SUR statistic.

{pstd}
{helpb sureg} is the estimation engine's benchmark: {cmd:surardl} reproduces it
exactly on the same design. What {cmd:surardl} adds is the ECM construction,
the derivation of the restriction set from the deterministic case, the bounds
machinery, the long-run inference, and the cross-equation tests.


{marker output}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.} Reports the estimator, the deterministic case, the lag structure,
the number of equations, the effective number of time periods {it:T}, the total
observations {it:NT}, the number of system parameters {it:M}, and the number of
restrictions {it:q} that the bounds test imposes per equation.

{pstd}
{bf:Conditional error-correction estimates.} One block per equation, split
into {bf:ADJ} (the speed of adjustment lambda, equation 8), {bf:LR} (the lagged
level terms beta, whose ratios to lambda give the long-run coefficients) and
{bf:SR} (lagged differences, impact elasticities and deterministic terms).
A negative, significant lambda is a necessary condition for a valid
error-correction mechanism.

{pstd}
{bf:Long-run coefficients.} theta = -beta/lambda with delta-method standard
errors. Read these together with the caveat above.

{pstd}
{bf:SUR bounds test.} The {it:F} column is the statistic for
H0: lambda(i) = beta(1,i) = ... = beta(K,i) = 0. The {it:t} column is the
statistic on lambda alone, which rules out the first degenerate case of PSS.
The decision codes are {bf:R} reject (the statistic lies beyond the {it:I}(1)
bound), {bf:N} do not reject (inside the {it:I}(0) bound), {bf:-} inconclusive
(between them) and {bf:.} bounds unavailable for this case or {it:K}. A
bootstrap p-value column appears when {opt bootstrap()} was used, and it
supersedes the decision codes.

{pstd}
{bf:Joint test.} The system-wide test of equations (78)-(79) that no equation
has a level relationship. Rejection says at least one does, not which.

{pstd}
{bf:Diagnostics.} The Breusch-Pagan LM test justifies system estimation; the
Pesaran CD test is a robustness check with limited power at small {it:N}. The
Sigma-hat block reports {it:T}/{it:N}, the conditioning of Sigma-hat and
whether it is positive definite. The Breusch-Godfrey block tests the no-serial-
correlation assumption equation by equation.


{marker examples}{...}
{title:Examples}

{pstd}Setup: the ASEAN-6 renewable energy panel shipped with the package{p_end}
{phang2}{cmd:. net get surardl}{p_end}
{phang2}{cmd:. use surardl_asean6}{p_end}
{phang2}{cmd:. generate double lrec = ln(rec)}{p_end}
{phang2}{cmd:. generate double lgdp = ln(gdp)}{p_end}
{phang2}{cmd:. generate double lfdi = ln(fdi + 4)}{p_end}
{phang2}{cmd:. generate double lto  = ln(to)}{p_end}
{phang2}{cmd:. xtset country year}{p_end}

{pstd}Baseline ARDL(1,1,1,1) with an unrestricted constant{p_end}
{phang2}{cmd:. surardl lrec lgdp lfdi lto}{p_end}

{pstd}The same with SUR-specific bootstrap critical values{p_end}
{phang2}{cmd:. surardl lrec lgdp lfdi lto, bootstrap(999) seed(20261010)}{p_end}

{pstd}A linear trend, restricted under the null (case 4){p_end}
{phang2}{cmd:. surardl lrec lgdp lfdi lto, case(4)}{p_end}

{pstd}Unit-specific lag orders chosen by the SBC{p_end}
{phang2}{cmd:. surardl lrec lgdp lfdi lto, maxlags(3) bic}{p_end}

{pstd}Long-run coefficients with a Fieller confidence set{p_end}
{phang2}{cmd:. estat longrun, fieller}{p_end}

{pstd}Are the adjustment speeds equal across countries?{p_end}
{phang2}{cmd:. estat ecequal, mtest(holm)}{p_end}

{pstd}Cross-equation restrictions by hand, using the full SUR covariance{p_end}
{phang2}{cmd:. test [Thailand]L.lrec = [Vietnam]L.lrec}{p_end}
{phang2}{cmd:. nlcom -_b[Thailand:L.lgdp]/_b[Thailand:L.lrec]}{p_end}

{pstd}The figure set{p_end}
{phang2}{cmd:. estat graph}{p_end}

{pstd}Run the self-test on the paper's own Monte Carlo design{p_end}
{phang2}{cmd:. do surardl_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:surardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations ({it:N} x {it:T}){p_end}
{synopt:{cmd:e(T)}}effective number of time periods{p_end}
{synopt:{cmd:e(N_eq)}}number of equations{p_end}
{synopt:{cmd:e(k_x)}}number of long-run regressors {it:K}{p_end}
{synopt:{cmd:e(M)}}number of system parameters{p_end}
{synopt:{cmd:e(case)}}deterministic case{p_end}
{synopt:{cmd:e(df_q)}}restrictions per equation bounds test{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(n_gaps)}}complete periods dropped outside the longest run{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}}first and last estimation period{p_end}
{synopt:{cmd:e(iterations)}, {cmd:e(converged)}}FGLS iteration count and flag{p_end}
{synopt:{cmd:e(chi2_joint)}, {cmd:e(df_joint)}, {cmd:e(F_joint)}, {cmd:e(p_joint)}}joint bounds test{p_end}
{synopt:{cmd:e(bp)}, {cmd:e(bp_df)}, {cmd:e(bp_p)}}Breusch-Pagan LM test{p_end}
{synopt:{cmd:e(cd)}, {cmd:e(cd_p)}}Pesaran CD test{p_end}
{synopt:{cmd:e(avg_absr)}}mean absolute off-diagonal correlation{p_end}
{synopt:{cmd:e(sig_rcond)}, {cmd:e(sig_mineig)}, {cmd:e(sig_pd)}, {cmd:e(sig_rfn)}}Sigma-hat diagnostics{p_end}
{synopt:{cmd:e(TN)}}{it:T}/{it:N} ratio{p_end}
{synopt:{cmd:e(reps)}, {cmd:e(seed)}, {cmd:e(bfail)}}bootstrap settings and failures{p_end}
{synopt:{cmd:e(simreps)}, {cmd:e(sfail)}, {cmd:e(simrho)}}simulation settings and failures{p_end}
{synopt:{cmd:e(numcombs)}}lag combinations evaluated{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:surardl}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}}dependent variable and regressors{p_end}
{synopt:{cmd:e(ivar)}, {cmd:e(tvar)}}panel and time variables{p_end}
{synopt:{cmd:e(eqnames)}, {cmd:e(ids)}}equation names and panel values{p_end}
{synopt:{cmd:e(method)}, {cmd:e(sigmadf)}, {cmd:e(fstat)}}estimation choices{p_end}
{synopt:{cmd:e(det)}}description of the deterministic case{p_end}
{synopt:{cmd:e(lagsel)}}criterion used for lag selection{p_end}
{synopt:{cmd:e(boottarget)}, {cmd:e(bootdgp)}}bootstrap design{p_end}
{synopt:{cmd:e(predict)}, {cmd:e(estat_cmd)}, {cmd:e(properties)}}program hooks{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficient vector and covariance matrix{p_end}
{synopt:{cmd:e(lags)}}{it:N} x ({it:K}+1) selected lag orders{p_end}
{synopt:{cmd:e(Sigma)}, {cmd:e(Corr)}}Sigma-hat and its correlation matrix{p_end}
{synopt:{cmd:e(bounds)}}{it:N} x 5: F, Wald, t, q, F on the beta terms{p_end}
{synopt:{cmd:e(Frss)}}RSS-based F, when {opt fstat()} requests it{p_end}
{synopt:{cmd:e(longrun)}}{it:NK} x 8: unit, regressor, theta, se, z, p, ci{p_end}
{synopt:{cmd:e(fieller)}}{it:NK} x 3: Fieller set and its type{p_end}
{synopt:{cmd:e(cvF)}, {cmd:e(cvt)}, {cmd:e(cvN)}}PSS and Narayan bounds{p_end}
{synopt:{cmd:e(decF)}, {cmd:e(decN)}, {cmd:e(dect)}}decision codes{p_end}
{synopt:{cmd:e(bootcv)}, {cmd:e(bootp)}, {cmd:e(bootdist)}}bootstrap results{p_end}
{synopt:{cmd:e(simcv0)}, {cmd:e(simcv1)}}simulated I(0) and I(1) bounds{p_end}
{synopt:{cmd:e(eqfit)}}{it:N} x 5: RSS, OLS RSS, R-squared, df, k{p_end}
{synopt:{cmd:e(efficiency)}}{it:M} x 3: SE(OLS), SE(SUR), gain{p_end}
{synopt:{cmd:e(resid)}, {cmd:e(residols)}}{it:T} x {it:N} residual matrices{p_end}
{synopt:{cmd:e(bgodfrey)}}Breusch-Godfrey results{p_end}
{synopt:{cmd:e(lv)}, {cmd:e(tr)}}level series and trend, for postestimation{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker AF2026}{...}
{phang}
Arif, M. A., and F. Furuoka. 2026. Seemingly unrelated cointegrating
regressions with autoregressive distributed lag dynamics: Estimation, bounds
testing, and cross-equation inference. Research Square preprint.
{browse "https://doi.org/10.21203/rs.3.rs-9237078/v1":doi:10.21203/rs.3.rs-9237078/v1}.

{marker BP1980}{...}
{phang}
Breusch, T. S., and A. R. Pagan. 1980. The Lagrange multiplier test and its
applications to model specification in econometrics.
{it:Review of Economic Studies} 47: 239-253.
{browse "https://doi.org/10.2307/2297111":doi:10.2307/2297111}.

{marker F1954}{...}
{phang}
Fieller, E. C. 1954. Some problems in interval estimation.
{it:Journal of the Royal Statistical Society, Series B} 16: 175-185.
{browse "https://doi.org/10.1111/j.2517-6161.1954.tb00159.x":doi:10.1111/j.2517-6161.1954.tb00159.x}.

{marker KS2020}{...}
{phang}
Kripfganz, S., and D. C. Schneider. 2020. Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction
models. {it:Oxford Bulletin of Economics and Statistics} 82: 1456-1481.
{browse "https://doi.org/10.1111/obes.12377":doi:10.1111/obes.12377}.

{marker KS2023}{...}
{phang}
Kripfganz, S., and D. C. Schneider. 2023. ardl: Estimating autoregressive
distributed lag and equilibrium correction models.
{it:Stata Journal} 23: 983-1019.
{browse "https://doi.org/10.1177/1536867X231212434":doi:10.1177/1536867X231212434}.

{marker LR2025}{...}
{phang}
Lin, Y., and H. Reuvers. 2025. FM-GLS estimation and inference for seemingly
unrelated cointegrating polynomial regressions.
{it:Oxford Bulletin of Economics and Statistics}.
{browse "https://doi.org/10.1111/obes.70030":doi:10.1111/obes.70030}.

{marker MSG2018}{...}
{phang}
McNown, R., C. Y. Sam, and S. K. Goh. 2018. Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics} 50: 1509-1521.
{browse "https://doi.org/10.1080/00036846.2017.1366643":doi:10.1080/00036846.2017.1366643}.

{marker N2005}{...}
{phang}
Narayan, P. K. 2005. The saving and investment nexus for China: Evidence from
cointegration tests. {it:Applied Economics} 37: 1979-1990.
{browse "https://doi.org/10.1080/00036840500278103":doi:10.1080/00036840500278103}.

{marker PSU2010}{...}
{phang}
Palm, F. C., S. Smeekes, and J.-P. Urbain. 2010. A sieve bootstrap test for
cointegration in a conditional error correction model.
{it:Econometric Theory} 26: 647-681.
{browse "https://doi.org/10.1017/S0266466609990053":doi:10.1017/S0266466609990053}.

{marker P2004}{...}
{phang}
Pesaran, M. H. 2004. General diagnostic tests for cross section dependence in
panels. Cambridge Working Papers in Economics 0435.

{marker PS1999}{...}
{phang}
Pesaran, M. H., and Y. Shin. 1999. An autoregressive distributed lag modelling
approach to cointegration analysis. In {it:Econometrics and Economic Theory in
the 20th Century}, ed. S. Strom, 371-413. Cambridge University Press.

{marker PSS2001}{...}
{phang}
Pesaran, M. H., Y. Shin, and R. J. Smith. 2001. Bounds testing approaches to
the analysis of level relationships.
{it:Journal of Applied Econometrics} 16: 289-326.
{browse "https://doi.org/10.1002/jae.616":doi:10.1002/jae.616}.

{marker WGH2020}{...}
{phang}
Wagner, M., P. Grabarczyk, and S. H. Hong. 2020. Fully modified OLS estimation
and inference for seemingly unrelated cointegrating polynomial regressions and
the environmental Kuznets curve for carbon dioxide emissions.
{it:Journal of Econometrics} 218: 456-480.
{browse "https://doi.org/10.1016/j.jeconom.2019.05.012":doi:10.1016/j.jeconom.2019.05.012}.

{marker Z1962}{...}
{phang}
Zellner, A. 1962. An efficient method of estimating seemingly unrelated
regressions and tests for aggregation bias.
{it:Journal of the American Statistical Association} 57: 348-368.
{browse "https://doi.org/10.1080/01621459.1962.10480664":doi:10.1080/01621459.1962.10480664}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please report bugs, and cite the paper above when you use the command.
