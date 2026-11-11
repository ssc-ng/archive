{smcl}
{* *! version 1.2.2  09nov2026}{...}
{vieweralsosee "idxnl" "help idxnl"}{...}
{vieweralsosee "idxdescribe" "help idxdescribe"}{...}
{vieweralsosee "idxint" "help idxint"}{...}
{vieweralsosee "idxtp" "help idxtp"}{...}
{viewerjumpto "Syntax" "idxspec##syntax"}{...}
{viewerjumpto "Description" "idxspec##description"}{...}
{viewerjumpto "Options" "idxspec##options"}{...}
{viewerjumpto "Decision rule" "idxspec##rule"}{...}
{viewerjumpto "Examples" "idxspec##examples"}{...}
{viewerjumpto "Stored results" "idxspec##results"}{...}
{viewerjumpto "References" "idxspec##references"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{bf:idxspec} {hline 2}}Compare and interpret nonlinear specifications for an index covariate{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:idxspec} {depvar} {it:indexvar} [{it:controls}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt fe}}within (fixed-effects) estimation with {cmd:xtreg, fe}; data must be {cmd:xtset}{p_end}
{synopt:{opth vce(vcetype)}}variance estimator passed to {cmd:regress} or {cmd:xtreg}, e.g. {cmd:vce(cluster} {it:id}{cmd:)}{p_end}
{synopt:{opt cce}}common correlated effects (CCE) pooled estimator for cross-sectional dependence; requires {opt fe}{p_end}
{synopt:{opt two:way}}two-way clustered standard errors by panel and time (Cameron, Gelbach, and Miller 2011){p_end}
{synopt:{opt dk}}Driscoll-Kraay standard errors robust to cross-sectional and serial dependence; data must be {cmd:xtset} with a time variable{p_end}
{synopt:{opt dkl:ag(#)}}Bartlett lag for {opt dk}; default floor(4(T/100)^(2/9)){p_end}
{syntab:Endogeneity, measurement error, scale}
{synopt:{opth iv(varlist)}}excluded instruments for {it:indexvar}; every function f(x) is instrumented by f(xhat){p_end}
{synopt:{opt simex(#)}}SIMEX correction of the quadratic for classical measurement error with standard deviation {it:#}{p_end}
{synopt:{opt pse:udo(#)}}pseudo-samples per SIMEX step; default 50{p_end}
{synopt:{opt br:eps(#)}}cluster-bootstrap replications for SIMEX standard errors; default 199{p_end}
{synopt:{opt rank}}apply the protocol to the percentile rank of {it:indexvar} (ordinal indices){p_end}
{synopt:{opth rankb:y(varlist)}}compute percentile ranks within groups, e.g. {cmd:rankby(year)}{p_end}
{synopt:{opt pow:er(#)}}power used for the minimum detectable slope; default 0.8{p_end}
{syntab:Support and bases}
{synopt:{opt trim(#)}}tail share excluded from the supported interval S; default {cmd:trim(0.05)}{p_end}
{synopt:{opt nk:nots(#)}}knots of the restricted cubic spline (3-7), placed at Harrell's percentiles; default {cmd:nknots(4)}{p_end}
{synopt:{opt ng:rid(#)}}grid points for the kink search over S; default {cmd:ngrid(41)}{p_end}
{syntab:Comparison}
{synopt:{opt kf:old(#)}}folds for cross-validation; default {cmd:kfold(5)}{p_end}
{synopt:{opth fold:var(varname)}}user-supplied fold identifiers{p_end}
{synopt:{opt seed(#)}}random fold assignment with the given seed (default is systematic assignment){p_end}
{syntab:Inference and reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt alp:ha(#)}}one-sided level of the shape tests; default {cmd:alpha(0.05)}{p_end}
{synopt:{opt gr:aph}}plot marginal effects of the quadratic, spline, and kink models over S{p_end}
{synopt:{opt graphopt:s(string)}}twoway options for the graph{p_end}
{synopt:{opt notab:le}}suppress output{p_end}
{synoptline}
{p 4 6 2}{it:controls} may contain factor variables, for example {cmd:i.year}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:idxspec} fits five specifications of the index covariate {it:indexvar} with the same
controls and estimator: linear, quadratic, cubic, restricted cubic spline (RCS), and a
continuous kink (regression kink) model whose threshold is located by grid search over the
supported interval S. It reports information criteria, K-fold cross-validated root mean
squared error, and Wald tests of nonlinearity. It then evaluates any U-shaped or
inverted-U-shaped claim with three complementary pieces of evidence that are restricted to
S rather than to the observed range:

{phang2}1. the Lind-Mehlum (Sasabuchi) test with slopes evaluated at the bounds of S;{p_end}
{phang2}2. the Fieller confidence interval of the turning point, which must be bounded and lie inside S;{p_end}
{phang2}3. a two-lines test (separate slopes below and above the turning point, or the kink when
the turning point lies outside S) that does not depend on the quadratic functional form.{p_end}

{pstd}
The supported interval S is [p({it:trim}), p(1-{it:trim})] of {it:indexvar} in the estimation sample.
All bases are functions of {it:indexvar} that are invariant to affine recoding, so results are
unchanged (up to the corresponding rescaling) when, for example, a -2.5 to 2.5 index is
re-expressed on a 0-100 scale.

{marker options}{...}
{title:Options}

{phang}
{opt fe} estimates every model with {cmd:xtreg, fe}. Cross-validation then uses folds within
panels; unit effects for held-out observations are predicted from training-fold unit means.

{phang}
{opt trim(#)} sets the tail share removed on each side when defining S. The default 0.05 gives
S = [p5, p95].

{phang}
{opt kfold(#)}, {opt foldvar()}, {opt seed()}: by default, for {cmd:xtset} data, observations are
assigned to folds by fold = mod(panel index + time index, K), where the indices number the panels
and periods of the estimation sample consecutively; every period and every panel then appears in
every fold, so period effects and unit effects are estimable for held-out observations. Without
{cmd:xtset}, fold = mod(running index, K) in the current sort order. Both rules are deterministic and
reproducible across software.

{phang}
{opt cce} implements the common correlated effects pooled estimator of Pesaran (2006). Cross-sectional
(period) averages of the dependent variable, the index, its square, and every continuous control are
computed in the estimation sample and interacted with panel indicators, so that unobserved common
factors with heterogeneous loadings are absorbed. The augmented regressors are added to all
specifications, including the cross-validation, the kink search, and the two-lines check. Combine
{opt cce} with {cmd:vce(cluster} {it:panelvar}{cmd:)}. CCE removes cross-sectional dependence that
arises from common factors and the bias that occurs when those factors also drive the index; it
requires that the factors are reflected in the averages (loadings with a non-zero mean) and costs
degrees of freedom (one coefficient per average and panel). The CD statistic reported after
{opt cce} refers to the CCE residuals and indicates whether dependence remains.

{phang}
{opt twoway} replaces the variance matrix of every fitted model by the two-way cluster estimator
V(panel) + V(time) - V(panel x time), each with its own small-sample factor, with negative eigenvalues
set to zero; inference uses min(G_panel, G_time) - 1 degrees of freedom.

{phang}
{opt dk} replaces the variance matrix of every fitted model by the Driscoll and Kraay (1998)
estimator, computed from time-aggregated scores with a Bartlett kernel and the small-sample factor
(N-1)/(N-K); inference uses T-1 degrees of freedom. With or without {opt dk}, {cmd:idxspec}
reports the Pesaran (2015) CD test on the residuals of the quadratic model whenever the data are
{cmd:xtset}. The Driscoll-Kraay estimator requires a long time dimension and weak temporal
dependence of the errors; it should be combined with {opt fe}, because persistent unit effects left in
pooled errors invalidate it, and with T below about 50 it can over-reject. In short panels, {opt fe cce}
with {cmd:vce(cluster} {it:panelvar}{cmd:)} is the recommended response to a significant CD test.

{phang}
{opth iv(varlist)} estimates the specifications by two-stage least squares. The first stage regresses
{it:indexvar} on the instruments and controls (with fixed effects under {opt fe}); its fitted value xhat
(including unit effects) generates instruments f(xhat) for each basis f(x): (xhat, xhat^2) for the
quadratic, the spline basis of xhat (with the knots of x) for the spline, and the two-lines terms of
xhat. The first-stage F statistic for the excluded instruments, a control-function test of exogeneity,
the linear IV effect, and the turning-point protocol are reported. Model comparison by information
criteria and cross-validation is not reported under {opt iv()}.

{phang}
{opt simex(#)} applies simulation-extrapolation (Cook and Stefanski 1994) to the quadratic model:
noise with variance lambda*#^2 is added to the index for lambda = 0.5, 1, 1.5, 2, the coefficients are
averaged over {opt pseudo()} pseudo-samples, and a quadratic extrapolant gives the estimate at
lambda = -1. Controls and fixed effects are partialled out. Standard errors come from a cluster
bootstrap over panels; the corrected turning point, its Fieller interval, and the Lind-Mehlum test are
reported. Published margins of error (for example, of the Worldwide Governance Indicators) can
guide the choice of #; a range of values gives a sensitivity analysis. Results depend on the random-
number seed.

{phang}
{opt rank} replaces the index by 100 x rank/N in the estimation sample (within {opt rankby()} groups if
specified). For ordinal indices, the existence of a turning point and its quantile location are
invariant to admissible recodings, but curvature is not; the protocol is then read as a test of a sign
change, and the turning point is a percentile.

{phang}
For thin tails, {cmd:idxspec} reports the number of observations beyond the turning point (or kink)
and the minimum detectable opposite-sign slope, (t(1-alpha) + t(power)) times the standard error of
the slope beyond that point. A negative verdict with a large minimum detectable slope means that a
decline is not established, not that it is absent.

{marker rule}{...}
{title:Decision rule}

{pstd}
A turning point is reported as supported only when all three criteria pass at level
{opt alpha()}. Otherwise {cmd:idxspec} reports whether the evidence indicates a nonlinear but
monotone relationship (RCS or quadratic nonlinearity test significant, kink slopes of equal
sign), a nonlinear relationship without an established turning point, or no evidence against
linearity. The conventional rule (significance of the squared term alone) is shown for
comparison.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use idxnl_example, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, vce(cluster id)}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe vce(cluster id) graph}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe cce vce(cluster id)}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe twoway}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe dk}{p_end}
{phang2}{cmd:. generate double gov_l2 = L2.gov}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe iv(gov_l2) vce(cluster id)}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, fe vce(cluster id) simex(0.10)}{p_end}
{phang2}{cmd:. idxspec y gov w1 w2 i.year, rank rankby(year) vce(cluster id)}{p_end}
{phang2}{cmd:. return list}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:idxspec} stores the following in {cmd:r()}:{p_end}
{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(lo)}, {cmd:r(hi)}}bounds of S{p_end}
{synopt:{cmd:r(tp)}, {cmd:r(se_tp)}, {cmd:r(tp_pct)}}turning point, delta-method SE, percentile position{p_end}
{synopt:{cmd:r(delta_lb)}, {cmd:r(delta_ub)}}delta-method interval{p_end}
{synopt:{cmd:r(fieller_lb)}, {cmd:r(fieller_ub)}}Fieller interval limits{p_end}
{synopt:{cmd:r(lm_t)}, {cmd:r(lm_p)}}Lind-Mehlum test on S{p_end}
{synopt:{cmd:r(lmfull_t)}, {cmd:r(lmfull_p)}}Lind-Mehlum test on [min, max]{p_end}
{synopt:{cmd:r(kink)}, {cmd:r(kink_lb)}, {cmd:r(kink_ub)}}kink location and likelihood-ratio set{p_end}
{synopt:{cmd:r(slope_below)}, {cmd:r(slope_above)}}kink-model slopes{p_end}
{synopt:{cmd:r(twolines_b1)}, {cmd:r(twolines_b2)}, {cmd:r(twolines_t1)}, {cmd:r(twolines_t2)}, {cmd:r(twolines_at)}}two-lines results{p_end}
{synopt:{cmd:r(p_quad)}, {cmd:r(p_rcs)}, {cmd:r(p_kink)}}nonlinearity tests{p_end}
{synopt:{cmd:r(supported)}}1 if all three criteria pass{p_end}
{synopt:{cmd:r(adhoc)}}1 if the squared term is significant{p_end}
{synopt:{cmd:r(mds)}, {cmd:r(n_beyond)}}minimum detectable slope and observations beyond the turning point{p_end}
{synopt:{cmd:r(cd)}, {cmd:r(cd_p)}, {cmd:r(cd_absrho)}}Pesaran CD test{p_end}
{synopt:{cmd:r(simex_b1)}, {cmd:r(simex_b2)}, {cmd:r(simex_se1)}, {cmd:r(simex_se2)}, {cmd:r(simex_tp)}, {cmd:r(simex_lm_t)}, {cmd:r(simex_lm_p)}}SIMEX results (with {opt simex()}){p_end}
{synopt:{cmd:r(F_first)}, {cmd:r(p_endog)}, {cmd:r(b_lin)}, {cmd:r(se_lin)}}IV results (with {opt iv()}; model-comparison results are then not stored){p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}verbal summary{p_end}
{synopt:{cmd:r(shape)}}{cmd:invU} or {cmd:U}{p_end}
{synopt:{cmd:r(fieller_type)}}{cmd:bounded}, {cmd:union}, or {cmd:unbounded}{p_end}
{synopt:{cmd:r(best_cv)}, {cmd:r(best_bic)}}preferred models{p_end}
{synopt:{cmd:r(knots)}}RCS knots{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(compare)}}k, AIC, BIC, CV-RMSE, nonlinearity F and p for each model{p_end}

{marker references}{...}
{title:References}

{phang}Cameron, A. C., J. B. Gelbach, and D. L. Miller. 2011. Robust inference with multiway clustering. {it:Journal of Business & Economic Statistics} 29: 238-249.{p_end}
{phang}Cook, J. R., and L. A. Stefanski. 1994. Simulation-extrapolation estimation in parametric measurement error models. {it:Journal of the American Statistical Association} 89: 1314-1328.{p_end}
{phang}Driscoll, J. C., and A. C. Kraay. 1998. Consistent covariance matrix estimation with spatially dependent panel data. {it:Review of Economics and Statistics} 80: 549-560.{p_end}
{phang}Fieller, E. C. 1954. Some problems in interval estimation. {it:Journal of the Royal Statistical Society, Series B} 16: 175-185.{p_end}
{phang}Hansen, B. E. 2017. Regression kink with an unknown threshold. {it:Journal of Business & Economic Statistics} 35: 228-240.{p_end}
{phang}Lind, J. T., and H. Mehlum. 2010. With or without U? The appropriate test for a U-shaped relationship. {it:Oxford Bulletin of Economics and Statistics} 72: 109-118.{p_end}
{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}
{phang}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels. {it:Econometric Reviews} 34: 1089-1117.{p_end}
{phang}Simonsohn, U. 2018. Two lines: A valid alternative to the invalid testing of U-shaped relationships with quadratic regressions. {it:Advances in Methods and Practices in Psychological Science} 1: 538-555.{p_end}

{title:Authors}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com{p_end}
{pstd}Francis Baidoo, Faculty of Business and Management Studies, Koforidua Technical University, Koforidua, Ghana{p_end}
