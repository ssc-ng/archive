{smcl}
{* *! version 1.0.0  07oct2026}{...}
{vieweralsosee "thivreg" "help thivreg"}{...}
{vieweralsosee "thendog" "help thendog"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thivtest##syntax"}{...}
{viewerjumpto "Description" "thivtest##description"}{...}
{viewerjumpto "Options" "thivtest##options"}{...}
{viewerjumpto "Why two variants" "thivtest##variants"}{...}
{viewerjumpto "Which test for which problem" "thivtest##which"}{...}
{viewerjumpto "Remarks" "thivtest##remarks"}{...}
{viewerjumpto "Stored results" "thivtest##results"}{...}
{viewerjumpto "Examples" "thivtest##examples"}{...}
{viewerjumpto "References" "thivtest##refs"}{...}
{viewerjumpto "Author" "thivtest##author"}{...}

{title:Title}

{phang}
{bf:thivtest} {hline 2} Sup-Wald test for a threshold with endogenous
regressors


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thivtest} {depvar} [{it:varlist1}]
{cmd:(}{it:varlist2} {cmd:=} {it:varlist_iv}{cmd:)} {ifin}{cmd:,}
{opt thresh:var(varname)} [{it:options}]

{pstd}
{it:varlist1} are exogenous regressors, {it:varlist2} endogenous regressors
and {it:varlist_iv} the excluded instruments.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt thresh:var(varname)}}the threshold variable, assumed
{bf:exogenous}; required{p_end}
{synopt :{opt trim(#)}}quantile trimming; default {cmd:trim(0.15)}{p_end}
{synopt :{opt gridn(#)}}cap on grid points; default {cmd:gridn(100)}{p_end}
{synopt :{opt mino:bs(#)}}minimum observations per regime{p_end}

{syntab:Inference}
{synopt :{opt reps(#)}}bootstrap replications; default {cmd:reps(499)}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synopt :{opt ch:test}}the original Caner-Hansen variant
{bf:(not recommended)}{p_end}
{synopt :{opt nobo:otstrap}}skip the bootstrap, leaving {bf:no p-value}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{title:Description}

{pstd}
{cmd:thivtest} tests the null of {bf:no threshold} in a model with endogenous
regressors:

{p 8 8 2}
y(t) = w(t)'theta1 * 1[q(t) <= gamma] + w(t)'theta2 * 1[q(t) > gamma] + e(t)

{pstd}
with w = (endogenous, exogenous), instruments z, and an {bf:exogenous}
threshold variable q. The null is theta1 = theta2.

{pstd}
Because gamma does not appear under the null it is unidentified, so the
statistic is the supremum of a sequence of Wald tests over a grid. Its limit
is {bf:not pivotal} and must be bootstrapped; there is no table to look the
statistic up in.


{marker variants}{title:Why two variants}

{pstd}
Caner and Hansen (2004) proposed this test. Rothfelder and Boldea show by
simulation that it is {bf:severely size-distorted} in small and even
moderately large samples {hline 2} the sizes applied work actually uses {hline 2}
oversized in small samples and undersized in larger ones.

{pstd}
They trace it to one underlying cause: {bf:subsample residuals are poor near
the edges of the grid}, because an estimator fitted to one side of an extreme
split uses very few observations. Two corrections follow, and they only work
as a pair.

{p 8 11 2}
{bf:1. The bootstrap.} Caner and Hansen draw the pseudo-series as
{it:ehat(t,gamma)} * eta(t), with residuals recomputed at every candidate
threshold. Replacing them with {bf:full-sample residuals under the null}
removes the undersizing.{p_end}

{p 8 11 2}
{bf:2. The variance.} Correction 1 alone leaves the test {it:oversized}. So
the heteroskedasticity-robust weight matrices are built from full-sample
residuals too.{p_end}

{pstd}
{bf:Neither correction works alone}: the first trades undersizing for
oversizing. That is why {cmd:thivtest} applies both by default and why it is
worth knowing that a partial correction would be worse than none.

{pstd}
Every run reports the {it:other} variant's statistic alongside, so you can
see what the correction did to your data. Use {cmd:chtest} only to reproduce
a published Caner-Hansen result.


{marker which}{title:Which test for which problem}

{p2colset 6 22 24 2}{...}
{p2col :{it:what is endogenous}}{it:command}{p_end}
{p2col :nothing}{helpb thtest}{p_end}
{p2col :the regressors}{bf:thivtest}{p_end}
{p2col :the threshold variable}{helpb thendog}{p_end}
{p2colreset}{...}

{pstd}
{cmd:thivtest} assumes the {bf:threshold variable is exogenous}. If it is
not, this is the wrong test: the regime itself becomes correlated with the
error, each regime is a selected sample, and no amount of instrumenting the
regressors repairs it. {helpb thendog} handles that case and tests the
threshold's endogeneity directly, so run it first if you are unsure.

{pstd}
Having rejected with {cmd:thivtest}, estimate the model with
{helpb thivreg}.


{marker remarks}{title:Remarks}

{pstd}
{bf:There is no p-value without the bootstrap.} The limit distribution
depends on the data, so {cmd:nobootstrap} gives you a number that cannot be
compared with anything. It exists for inspecting the statistic quickly, not
for reporting.

{pstd}
{bf:Every replication re-searches the whole grid}, because the observed
statistic is a supremum taken over that grid. A bootstrap that fixed the
winning threshold would be the distribution of a statistic nobody computed,
and would over-reject.

{pstd}
{bf:Instrument strength matters more here than usual.} The test compares GMM
fits in two subsamples, so the instruments must be strong enough to identify
the model {it:within each regime}, not just overall. A split that leaves one
regime with weak identification produces a large Wald statistic for the wrong
reason. Check the first stage, and consider raising {cmd:trim()}.

{pstd}
{bf:Rejection says there is a threshold, not where it is.} The reported
threshold is where the statistic peaked and carries no confidence set, for
the usual reason: under the null it is not identified at all.

{pstd}
{bf:The two other tests in the paper} {hline 2} the two based on
unconventional 2SLS estimators that exploit information about first-stage
linearity {hline 2} are not implemented here. Only the GMM-based corrected
test is, and the help says so rather than implying the paper is fully
covered.


{marker results}{title:Stored results}

{pstd}{cmd:thivtest} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}the sup-Wald statistic of the reported variant{p_end}
{synopt:{cmd:r(p)}}bootstrap p-value; missing under {cmd:nobootstrap}{p_end}
{synopt:{cmd:r(gamma)}}threshold at which it peaked{p_end}
{synopt:{cmd:r(stat_alt)}, {cmd:r(gamma_alt)}}the other variant{p_end}
{synopt:{cmd:r(N)}, {cmd:r(k)}, {cmd:r(q)}}observations, coefficients,
instruments{p_end}
{synopt:{cmd:r(ngrid)}, {cmd:r(npoints)}}grid points offered and usable{p_end}
{synopt:{cmd:r(reps)}}replications used{p_end}
{synopt:{cmd:r(trim)}}as specified{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(variant)}}{cmd:rb} or {cmd:ch}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(depvar)}, {cmd:r(endogvars)}}{p_end}
{synopt:{cmd:r(insts)}, {cmd:r(threshold_var)}}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}the full-sample GMM fit under the null{p_end}
{synopt:{cmd:r(grid)}}the thresholds searched{p_end}
{synopt:{cmd:r(bootdist)}}the bootstrap statistics{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}The usual case{p_end}
{phang2}{cmd:. thivtest y x2 (x1 = z1 z2), threshvar(q) reps(499) seed(42)}{p_end}

{pstd}Then estimate, having rejected{p_end}
{phang2}{cmd:. thivreg y x2 (x1 = z1 z2), threshvar(q)}{p_end}

{pstd}Reproducing a published Caner-Hansen result{p_end}
{phang2}{cmd:. thivtest y x2 (x1 = z1 z2), threshvar(q) chtest reps(499)}{p_end}

{pstd}Checking first whether the threshold variable is itself endogenous{p_end}
{phang2}{cmd:. thendog y x2 (x1 = z1 z2), threshvar(q)}{p_end}
{phang2}{cmd:. thivtest y x2 (x1 = z1 z2), threshvar(q)}{p_end}

{pstd}Looking at the bootstrap distribution{p_end}
{phang2}{cmd:. thivtest y x2 (x1 = z1 z2), threshvar(q) reps(999) seed(1)}{p_end}
{phang2}{cmd:. matrix B = r(bootdist)}{p_end}
{phang2}{cmd:. svmat double B, name(bw)}{p_end}
{phang2}{cmd:. histogram bw1, xline(`=r(stat)')}{p_end}


{marker refs}{title:References}

{phang}
Caner, M., and B. E. Hansen. 2004. Instrumental variable estimation of a
threshold model. {it:Econometric Theory} 20: 813-843.
{browse "https://doi.org/10.1017/S0266466604205011":doi:10.1017/S0266466604205011}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Rothfelder, M. P., and O. Boldea. 2022. Testing for a threshold in models
with endogenous regressors. {it:arXiv} 2207.10076.
{browse "https://arxiv.org/abs/2207.10076":arXiv:2207.10076}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
