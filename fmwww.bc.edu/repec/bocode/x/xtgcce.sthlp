{smcl}
{* *! version 1.0.0  12oct2026}{...}
{vieweralsosee "xtdyngcce" "help xtdyngcce"}{...}
{vieweralsosee "xtdyncce" "help xtdyncce"}{...}
{vieweralsosee "xtdyngcce methods" "help xtdyngcce_methods"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{viewerjumpto "Syntax" "xtgcce##syntax"}{...}
{viewerjumpto "Description" "xtgcce##description"}{...}
{viewerjumpto "Options" "xtgcce##options"}{...}
{viewerjumpto "How to write the command" "xtgcce##howto"}{...}
{viewerjumpto "Interpreting the output" "xtgcce##interpret"}{...}
{viewerjumpto "Remarks and practical guidance" "xtgcce##remarks"}{...}
{viewerjumpto "Examples" "xtgcce##examples"}{...}
{viewerjumpto "Stored results" "xtgcce##results"}{...}
{viewerjumpto "References" "xtgcce##references"}{...}
{viewerjumpto "Author" "xtgcce##author"}{...}

{title:Title}

{phang}
{bf:xtgcce} {hline 2} Generalized Common Correlated Effects mean-group
estimation, robust to failure of the rank condition


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtgcce} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt cce}}also report the conventional CCE-MG estimator for comparison{p_end}
{synopt :{opt noj:ackknife}}point estimates only; skip the jackknife variance{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt maxu:nits(#)}}guard on N x k; default {cmd:2000}{p_end}

{syntab:Reporting}
{synopt :{opt gr:aph}}coefficient plot with jackknife intervals{p_end}
{synopt :{opt hist:ogram}}histograms of the unit-specific slopes{p_end}
{synopt :{opt name(string)}}stub for the graph names{p_end}
{synopt :{opt tr:ace}}show jackknife progress{p_end}
{synopt :{opt notab:le}}suppress the output table{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
A panel must be declared with {helpb xtset} beforehand. The estimation sample
must be balanced and free of gaps. {it:indepvars} must not contain a lag of
{it:depvar}; see {help xtgcce##remarks:Remarks}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtgcce} fits the heterogeneous panel data model with interactive fixed
effects

{p 8 8 2}
y(i,t) = b(i)'x(i,t) + lambda(i)'f(t) + u(i,t){break}
x(i,t) = gamma(i)'f(t) + v(i,t)

{pstd}
by the {it:Generalized} Common Correlated Effects mean-group (GCCE-MG)
estimator of {help xtgcce##LSB2026:Lu, Su and Ba (2026)}, and reports
leave-one-out jackknife standard errors and confidence intervals.

{pstd}
{bf:The idea in one sentence.} The conventional CCE estimator augments the
regression with the {it:cross-section} averages zbar(t). GCCE augments it with
the cross-section averages {bf:and} the {it:time-series} averages xbar(i) of
the regressors. The time-series averages act as control variables for the
factor loadings: projecting lambda(i) on xbar(i) leaves a residual that is
(almost) uncorrelated with gamma(i), which removes the endogeneity that breaks
CCE when the rank condition fails.

{pstd}
{bf:Why you would use it.} CCE requires a rank condition on the mean factor
loadings. When that condition fails {it:and} the loadings of the x- and
y-equations are correlated, CCE is {bf:inconsistent} - its bias does not shrink
as N grows. GCCE is {it:doubly robust}: it is consistent under {bf:either} the
rank condition {bf:or} the control-variable condition. When the rank condition
does hold the two estimators are asymptotically equivalent, with no efficiency
loss. In short, there is nothing to lose by using GCCE.

{pstd}
GCCE also strictly nests the two-way fixed effects estimator: restricting the
coefficient on ybar(t) to zero and holding the remaining parameters constant
reduces equation (7) to the two-way Mundlak regression, which is numerically
identical to TWFE.

{pstd}
For {bf:dynamic, pooled} models see {helpb xtdyncce} instead. GCCE as published
excludes lagged dependent variables; the authors list the dynamic extension as
future research.


{marker options}{...}
{title:Options}

{phang}
{opt cce} additionally computes the conventional CCE-MG estimator on the same
sample and prints a comparison block. {bf:This is the single most useful
diagnostic the command offers}: a large gap between CCE-MG and GCCE-MG is
evidence that the rank condition fails, because the two are asymptotically
equivalent when it holds.

{phang}
{opt nojackknife} skips the leave-one-out jackknife. The point estimates and
the unit-specific slopes are still computed and stored, but no standard errors,
test statistics or confidence intervals are produced. Use it for a fast first
look, or when N is large enough that the jackknife is costly.

{phang}
{opt maxunits(#)} refuses to run when N x k exceeds this value. The GCCE system
matrix is (N x k) by (N x k) and the jackknife solves it N times, so the cost
grows quickly. The default 2000 permits, for example, N = 1000 with two
regressors. Raise it deliberately.

{phang}
{opt graph} draws a coefficient plot with the jackknife confidence intervals.
{opt histogram} additionally draws one histogram per regressor of the
unit-specific slopes b(i), with the mean-group estimate marked - the figure
reported in the source paper. {opt name(string)} sets the graph-name stub
(graphs are named {it:stub}{cmd:_coef}, {it:stub}{cmd:_hist}).

{phang}
{opt trace} reports progress every 25 jackknife units.


{marker howto}{...}
{title:How to write the command}

{pstd}
{bf:Step 1 - declare the panel.}

{phang2}{cmd:. xtset pair year}{p_end}

{pstd}
{bf:Step 2 - run GCCE against CCE in one go.} Almost always start here:

{phang2}{cmd:. xtgcce lexport lgdp, cce}{p_end}

{pstd}
{bf:Step 3 - read the comparison block.} This is the decision point:

{p 8 10 2}
{bf:o} If CCE-MG and GCCE-MG are {it:close}, the rank condition is plausibly
satisfied and the two estimators agree, as the theory says they must. Report
either; GCCE costs nothing.

{p 8 10 2}
{bf:o} If they are {it:far apart}, especially if their confidence intervals do
not overlap, the rank condition is in doubt. Report {bf:GCCE}, which is
consistent either way, and say so.

{pstd}
{bf:Step 4 - look at the heterogeneity.} The dispersion block reports the
standard deviation and the 10th, 50th and 90th percentiles of the
unit-specific slopes. Wide dispersion is the normal finding in macro panels and
is precisely why a mean-group estimator is used rather than a pooled one. Add
{cmd:histogram} for the picture.

{pstd}
{bf:Step 5 - report.}

{phang2}{cmd:. xtgcce lexport lgdp, cce graph histogram name(fig2)}{p_end}
{phang2}{cmd:. ereturn list}{p_end}

{pstd}
{bf:Writing the varlist.} All regressors go in {indepvars} in the usual way;
time-series operators are allowed. Do {bf:not} include a lag of {depvar} -
the estimator's theory excludes it. Time-invariant regressors cannot be
identified and should be omitted; they are absorbed by the interactive fixed
effects anyway.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Coefficient table.} Each row is the mean-group estimate
b0(j) = (1/N) sum_i b(i,j), the average marginal effect of regressor j. The
standard error is the square root of Omegahat/N, where Omegahat is the
leave-one-out jackknife variance of equation (15). Intervals are symmetric
normal intervals, as in the source paper.

{pstd}
{bf:Comparison with the conventional CCE-MG estimator} (with {cmd:cce}).
The {it:difference} column is GCCE minus CCE. Under the rank condition this
difference is asymptotically zero; a difference that is large relative to the
standard errors is the diagnostic described above. The source paper's own trade
application finds CCE 1.51 against GCCE 0.80 with non-overlapping intervals -
a factor of nearly two.

{pstd}
{bf:Dispersion of the unit-specific slopes.} The standard deviation and
percentiles of b(i) across units. These are {it:estimates} of heterogeneous
slopes, so their dispersion overstates true heterogeneity by the estimation
noise in each b(i); read them as descriptive, not as a variance decomposition.

{pstd}
{bf:Footer.} Confirms the augmentation actually used, and reminds you that
ybar(i) is deliberately excluded. That exclusion is not an oversight: the
time-series average of y mixes lambda(i) with gamma(i)b(i) and therefore
proxies nothing (Remark 2 of the source paper).


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:There is no cost to using GCCE instead of CCE.} This is the source paper's
central practical claim and its Monte Carlo supports it: when the rank
condition holds, GCCE-MG matches both CCE-MG and the infeasible oracle
estimator that knows the true factors; when it fails, CCE is inconsistent and
GCCE is not.

{pstd}
{bf:Computation.} The estimator is {it:not} a per-unit regression. All N sets
of slopes are estimated jointly because the across-unit projection
M(xbar) couples them. The system matrix is (N x k) by (N x k); the Kronecker
product that defines it is never formed explicitly, but the solve is still
O((Nk)^3). The leave-one-out jackknife repeats that solve N times, so cost
grows as N^4 k^3. For N in the hundreds this is seconds to minutes; for
N above roughly 1000 use {cmd:nojackknife} first and budget time before asking
for the jackknife.

{pstd}
{bf:The jackknife keeps zbar(t) fixed.} In equation (14) the leave-one-out
estimator drops unit i from X, Y and xbar, but leaves the cross-section
averages zbar(t) at their full-sample values, because zbar(t) is treated as a
proxy for a factor that does not vary across i. {cmd:xtgcce} follows the paper
exactly. This is also why the jackknife here is {bf:not} the same object as a
cluster jackknife from a general-purpose command.

{pstd}
{bf:Sample-size regime.} The asymptotics are joint, (N,T) -> infinity. The
paper's simulations cover N and T from 50 to 200 and the estimator behaves well
throughout. There is no fixed-T theory for GCCE; the authors list it as an open
question.

{pstd}
{bf:Unbalanced panels and gaps.} The double projection requires a common time
grid. Panels with a shorter span are dropped and the count is reported; gaps
inside a panel are an error. The source paper provides no theory for unbalanced
GCCE.

{pstd}
{bf:Correlated random coefficients.} The model allows b(i) to be correlated
with x(i,t). This is why a {it:pooled} version is not offered: imposing a
constant slope makes the composite error correlated with the regressors and
every estimator of b0 becomes inconsistent (Remark 1 of the source paper).

{pstd}
{bf:What this command does not do.} It does not test the rank condition - it
is robust to its failure, which is different. It provides no weak-factor
theory, no fixed-T inference and no formal test of the CCE-versus-GCCE
difference. The comparison block is a diagnostic to read, not a hypothesis
test; the source paper does not provide one and none is invented here. For a
rank-condition test see
{help xtgcce##DVES2024:De Vos, Everaert and Sarafidis (2024)}, implemented for
static panels in {helpb xtdcce2} via {cmd:cr(..., rcclassifier)}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}GCCE-MG with jackknife inference{p_end}
{phang2}{cmd:. xtgcce invest mvalue kstock}{p_end}

{pstd}The standard workflow: GCCE against CCE{p_end}
{phang2}{cmd:. xtgcce invest mvalue kstock, cce}{p_end}

{pstd}Fast point estimates on a large panel{p_end}
{phang2}{cmd:. xtgcce invest mvalue kstock, nojackknife}{p_end}

{pstd}Full reporting with both figures{p_end}
{phang2}{cmd:. xtgcce invest mvalue kstock, cce graph histogram name(fig2)}{p_end}

{pstd}Recover the unit-specific slopes for further work{p_end}
{phang2}{cmd:. xtgcce invest mvalue kstock}{p_end}
{phang2}{cmd:. matrix B = e(b_i)}{p_end}
{phang2}{cmd:. svmat double B, name(bhat)}{p_end}

{pstd}A full worked example on simulated data with known truth is shipped with
the package:{p_end}
{phang2}{cmd:. net get xtdyngcce}{p_end}
{phang2}{cmd:. do xtdyngcce_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtgcce} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels used{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(k_x)}}number of regressors{p_end}
{synopt:{cmd:e(jack)}}1 if the jackknife variance was computed{p_end}
{synopt:{cmd:e(N_drop)}}panels dropped for unbalancedness{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtgcce}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(indeps)}}names of the regressors{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(estimator)}}{cmd:GCCE-MG}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:leave-one-out jackknife}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}mean-group coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(ci_lo)}}lower confidence limits{p_end}
{synopt:{cmd:e(ci_hi)}}upper confidence limits{p_end}
{synopt:{cmd:e(b_i)}}N x k matrix of unit-specific slopes{p_end}
{synopt:{cmd:e(b_loo)}}N x k matrix of leave-one-out mean-group estimates{p_end}
{synopt:{cmd:e(b_cce)}}conventional CCE-MG estimates (with {cmd:cce}){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker B2023}{...}
{phang}
Baltagi, B. H. 2023. The two-way Mundlak estimator. {it:Econometric Reviews}
42(2): 240-246. {browse "https://doi.org/10.1080/07474938.2023.2178139"}

{marker DVES2024}{...}
{phang}
De Vos, I., G. Everaert, and V. Sarafidis. 2024. A method to evaluate the rank
condition for CCE estimators. {it:Econometric Reviews} 43(2-4): 123-155.
{browse "https://doi.org/10.1080/07474938.2023.2292383"}

{marker EHS2013}{...}
{phang}
Eberhardt, M., C. Helmers, and H. Strauss. 2013. Do spillovers matter when
estimating private returns to R&D? {it:Review of Economics and Statistics}
95(2): 436-448. {browse "https://doi.org/10.1162/REST_a_00272"}

{marker KRW2017}{...}
{phang}
Karabiyik, H., S. Reese, and J. Westerlund. 2017. On the role of the rank
condition in CCE estimation of factor-augmented panel regressions.
{it:Journal of Econometrics} 197(1): 60-64.
{browse "https://doi.org/10.1016/j.jeconom.2016.10.006"}

{marker LSB2026}{...}
{phang}
Lu, X., L. Su, and Y. Ba. 2026. On generalized CCE estimation.
{it:Journal of Econometrics} 253: 106183.
{browse "https://doi.org/10.1016/j.jeconom.2026.106183"}

{marker M1978}{...}
{phang}
Mundlak, Y. 1978. On the pooling of time series and cross section data.
{it:Econometrica} 46(1): 69-85.

{marker P2006}{...}
{phang}
Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels
with a multifactor error structure. {it:Econometrica} 74(4): 967-1012.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00692.x"}

{marker WU2013}{...}
{phang}
Westerlund, J., and J.-P. Urbain. 2013. On the estimation and inference in
factor-augmented panel regressions with correlated loadings.
{it:Economics Letters} 119(3): 247-250.

{marker W2025}{...}
{phang}
Wooldridge, J. M. 2025. Two-way fixed effects, the two-way Mundlak regression,
and difference-in-differences estimators. {it:Empirical Economics} 69(5):
2545-2587. {browse "https://doi.org/10.1007/s00181-025-02807-z"}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See also: {helpb xtdyncce}, {helpb xtdyngcce}, {helpb xtdyngcce_methods},
{helpb xtdcce2}, {helpb xtcd2}, {helpb xtcse2}.
