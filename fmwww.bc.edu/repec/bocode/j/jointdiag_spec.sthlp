{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag port" "help jointdiag_port"}{...}
{viewerjumpto "Syntax" "jointdiag_spec##syntax"}{...}
{viewerjumpto "Description" "jointdiag_spec##description"}{...}
{viewerjumpto "Options" "jointdiag_spec##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_spec##interpret"}{...}
{viewerjumpto "Remarks" "jointdiag_spec##remarks"}{...}
{viewerjumpto "Examples" "jointdiag_spec##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_spec##results"}{...}

{title:Title}

{phang}
{bf:jointdiag spec} {hline 2} Generalised-spectral joint and marginal tests for
the conditional mean and variance, with a wild bootstrap


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:spec} [{cmd:,} {it:options}]

{p 4 4 2}
A postestimation command for {helpb regress} and {helpb arch}.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt w:eight(string)}}{cmd:exp} (default), {cmd:ind}, or {cmd:both}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(299)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt norefit}}hold the parameters fixed in the bootstrap (faster, and
only approximate){p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
Escanciano (2008) tests a {it:pair} of conditional moment restrictions at once:
that the conditional mean is right {bf:and} that the conditional variance is
right.  His statistic is a Cramer-von Mises norm of a generalised spectral
distribution, which has four practical virtues:

{p 4 7 2}
{bf:*}  no bandwidth, no kernel, no lag order to choose;
{p 4 7 2}
{bf:*}  it works with an infinite-dimensional conditioning set, so highly
persistent volatility is not a problem;
{p 4 7 2}
{bf:*}  it is robust to higher-order conditional dependence, in particular to
time-varying conditional skewness and kurtosis;
{p 4 7 2}
{bf:*}  it is consistent against Pitman alternatives converging at the
parametric rate.

{pstd}
The marginal tests ({it:mean} only, {it:variance} only) come from the same
machinery by changing a weight matrix, so they are directly comparable with the
joint test.


{marker options}{...}
{title:Options}

{phang}
{opt weight()} picks the family of functions used to span the conditional
moment restriction.  {cmd:exp} uses exp({it:ixY}) with a standard-normal
integrating measure; {cmd:ind} uses the indicator 1({it:Y} <= {it:x}) with the
empirical cdf.  In Escanciano's simulations the exponential version was the
better of the two in almost every design, which is why it is the default; it
mirrors the known result that indicator-based goodness-of-fit tests have low
power against changes in scale.

{phang}
{opt reps(#)} sets the number of wild-bootstrap replications.  299 is a
sensible default; raise it before quoting a borderline p-value.

{phang}
{opt norefit} skips step 4 of the algorithm, in which the model is
re-estimated on each bootstrap sample.  It is much faster, but it ignores the
estimation effect and can over-reject.  The output says so in red when you use
it.  Prefer raising {cmd:reps()} over using {cmd:norefit}.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
Three rows per weight family: joint, mean, variance.  The reading rule is the
one Escanciano's own simulations force on you:

{pstd}
{bf:An insignificant variance marginal does not mean the variance is fine.}
In his Tables 2 and 3, the marginal variance test has rejection rates of 2.7 to
4.0 percent against a GARCH-M alternative and 1.0 to 3.5 percent against
AR(2)-CH(1).  At a 5 percent nominal level that is {it:no power at all} - and
the reason is that the conditional mean is misspecified in both designs.  So:

{p 4 7 2}
{bf:1.}  Look at the mean marginal first.
{p 4 7 2}
{bf:2.}  If it rejects, fix the mean and re-run everything.  Only then is the
variance marginal informative.
{p 4 7 2}
{bf:3.}  The joint test is the one that keeps its size and power throughout;
quote it as the omnibus verdict.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The S&P 500 application.}  Escanciano fitted this battery to daily S&P 500
log differences from January 1988 to May 1993 and reached a conclusion at odds
with the finance literature: a linear AR(1) with conditionally homoskedastic
martingale-difference errors fits the data, and the AR(1)-GARCH(1,1) model of
Bera and Higgins (1997) is strongly rejected.  He attributes the usual finding
to the lack of robustness of standard ARCH tests to higher-order conditional
dependence, while noting the question is not settled.  It is a good reminder
that a joint test can overturn a conclusion built from marginals.

{pstd}
{bf:Cost.}  The statistic is a sum of quadratic forms in an n-by-n weight
matrix, truncated at 25 lags because the 1/(j*pi)^2 weighting makes later lags
negligible.  Samples above 3000 observations are refused rather than left to
thrash.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc}{p_end}
{phang2}{cmd:. jointdiag spec, reps(299) seed(1)}{p_end}

{pstd}After a GARCH fit, both weight families{p_end}
{phang2}{cmd:. arch dln_inv dln_inc, ar(1) arch(1) garch(1)}{p_end}
{phang2}{cmd:. jointdiag spec, weight(both) reps(499) seed(7)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat_cj)}, {cmd:r(p_cj)}}exponential weight, joint{p_end}
{synopt:{cmd:r(stat_cm)}, {cmd:r(p_cm)}}exponential weight, mean{p_end}
{synopt:{cmd:r(stat_cv)}, {cmd:r(p_cv)}}exponential weight, variance{p_end}
{synopt:{cmd:r(stat_ij)}, {cmd:r(p_ij)}}indicator weight, joint{p_end}
{synopt:{cmd:r(stat_im)}, {cmd:r(p_im)}}indicator weight, mean{p_end}
{synopt:{cmd:r(stat_iv)}, {cmd:r(p_iv)}}indicator weight, variance{p_end}
{synopt:{cmd:r(N)}, {cmd:r(reps)}}observations and replications{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(boot)}}the bootstrap distribution, reps x 6{p_end}


{title:References}

{phang}Escanciano, J. C. 2008. {it:J. Econometrics} 143: 74{c 150}87.
{browse "https://doi.org/10.1016/j.jeconom.2007.08.010"}{p_end}
{phang}Escanciano, J. C. 2007. CAEPR Working Paper 2007-009, Indiana University.{p_end}
{phang}Stute, W., W. Gonzalez-Manteiga, and M. Presedo-Quindimil. 1998.
{it:JASA} 93: 141{c 150}149.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
