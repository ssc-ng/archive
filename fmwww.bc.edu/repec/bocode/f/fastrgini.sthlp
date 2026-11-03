{smcl}
{* *! version 1.1  02nov2026}{...}
{vieweralsosee "fastgini" "help fastgini"}{...}
{vieweralsosee "jackknife" "help jackknife"}{...}
{viewerjumpto "Syntax" "fastrgini##syntax"}{...}
{viewerjumpto "Description" "fastrgini##description"}{...}
{viewerjumpto "Options" "fastrgini##options"}{...}
{viewerjumpto "Examples" "fastrgini##examples"}{...}
{viewerjumpto "Stored results" "fastrgini##results"}{...}
{viewerjumpto "References" "fastrgini##references"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{hi:fastrgini} {hline 2}}Fast calculation of conventional and reciprocal Gini coefficients, bilateral inequality level, and orientation{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fastrgini} {varname} [{varname}] {ifin} {weight}
[{cmd:,} {opt jk} {opt bin(#)} {opt noch:eck} {opt level(#)}]

{pstd}
{cmd:fweight}s, {cmd:pweight}s, {cmd:aweight}s, and {cmd:iweight}s are accepted; see {help weight}.
Internally, {cmd:aweight}s and {cmd:iweight}s are treated as {cmd:pweight}s.

{marker description}{...}
{title:Description}

{pstd}
{cmd:fastrgini} calculates six distributional statistics for one positive-valued
variable, using sorted-data algorithms implemented in Mata. It extends the
approach of {help fastgini} (Sajaia, 2007) by calculating the conventional
Gini together with its reciprocal counterpart and associated measures.
The six reported statistics are:

{p2colset 8 19 21 2}{...}
{p2col:{cmd:G}}Conventional Gini coefficient of income y.{p_end}
{p2col:{cmd:rG}}Reciprocal Gini: conventional Gini evaluated on 1/y (related to Ryu's 2013 pgini).{p_end}
{p2col:{cmd:mG}}Bilateral inequality level: (G + rG)/2.{p_end}
{p2col:{cmd:sG}}Signed orientation: (G - rG)/(G + rG).{p_end}
{p2col:{cmd:A2}}Atkinson inequality index with inequality-aversion parameter 2.{p_end}
{p2col:{cmd:p_pd}}Auxiliary quantile threshold: (1 - rG)/2.{p_end}
{p2colreset}{...}

{pstd}
The reciprocal Gini measures dispersion of inverse income and thus places
particular emphasis on the lower end of the original income distribution.
The bilateral index {cmd:mG} is unchanged if every positive income is
replaced by its reciprocal. The orientation statistic {cmd:sG} changes sign
under the same transformation: positive values indicate relatively stronger
upper-side inequality, and negative values indicate relatively stronger
lower-side inequality. At equality, {cmd:sG} is mathematically undefined
(0/0); users should not interpret a missing result as evidence of orientation.

{pstd}
{cmd:A2} = 1 - 1/[mean(y)*mean(1/y)], with weighted means where applicable.
The statistic {cmd:p_pd} is an auxiliary threshold motivated by marginal
progressive-transfer analysis; it is not a p-value or a general test of the
Pigou-Dalton principle. In particular, {cmd:mG} does not satisfy that
principle for every possible progressive transfer.

{pstd}
With two variables, {cmd:fastrgini} computes the six statistics for each
variable on a common sample and reports the difference (second minus first)
and percentage change. With {opt jk}, it uses matched leave-one-out
replicates to estimate the standard errors of the differences. This is
useful for paired income concepts, before-and-after comparisons, and
simulated reforms on the same observational units.

{pstd}
By default, observations with zero or negative values in either specified
variable are excluded, with a warning. Missing values and observations
with missing or nonpositive weights are also excluded. Reciprocal
statistics require strictly positive values; {opt nocheck} should be used
only when positivity has already been verified.

{marker options}{...}
{title:Options}

{phang}
{opt jk} requests leave-one-out jackknife standard errors. In the
one-variable case, normal-approximation confidence intervals are displayed
for all six statistics. In the two-variable case, the output includes
jackknife standard errors, z statistics, and two-sided normal-approximation
p-values for the paired differences. With {cmd:pweight}s, an observation
is removed as a whole; with no weights or {cmd:fweight}s, one frequency
unit is removed. Standard errors are calculated from the corresponding
leave-one-out statistics; these are not survey-design linearized standard
errors. The option cannot be combined with {opt bin(#)}.

{phang}
{opt bin(#)} approximates the statistics by grouping positive values into
{it:#} equal-width intervals on the log-income scale. Each occupied bin is
represented by the weighted arithmetic mean of the original observations
in that bin. With two variables, binning is performed separately for each
variable. Larger numbers of bins generally improve resolution but require
more computation. Results are approximations to the ungrouped estimates;
in particular, the reciprocal Gini can be sensitive to aggregation near
zero. {opt bin(#)} cannot be combined with {opt jk}.

{phang}
{opt nocheck} suppresses the default exclusion check for nonpositive
values. This does not remove the mathematical requirement that values be
strictly positive for reciprocal calculations. Use only with validated
positive data.

{phang}
{opt level(#)} sets the confidence level for the displayed jackknife
confidence intervals in the one-variable case; the default is the current
Stata confidence level (normally 95). The two-variable comparison reports
z tests rather than confidence intervals.

{marker examples}{...}
{title:Examples}

{pstd}Calculate the Gini family for one positive variable:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. fastrgini price}{p_end}

{pstd}Request jackknife standard errors and 90% confidence intervals:{p_end}
{phang2}{cmd:. fastrgini price, jk level(90)}{p_end}

{pstd}Two ALOM distributions with (approximately) the same conventional Gini
but different reciprocal and bilateral Ginis:{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 10000}{p_end}
{phang2}{cmd:. generate double p = (_n - 0.5)/_N}{p_end}
{phang2}{cmd:. generate double y1 = p^0.20 / (1-p)^0.40}{p_end}
{phang2}{cmd:. generate double y2 = p^0.50 / (1-p)^0.2490698434}{p_end}
{phang2}{cmd:. fastrgini y1}{p_end}
{phang2}{cmd:. fastrgini y2}{p_end}

{pstd}
The two positive quantile functions follow the ALOM form
{it:y(p) = p^alpha / (1-p)^omega}, evaluated at 10,000 equally
spaced midpoint ranks. Both yield G approximately 0.33268, but
mG is approximately 0.30268 for {cmd:y1} and 0.37948 for
{cmd:y2}. The corresponding sG values are approximately +0.09912
and -0.12333. This example illustrates that equal conventional
Ginis need not imply equal bilateral inequality levels or orientations.
The two calls are independent single-variable calculations; no
paired-comparison functionality is required.

{pstd}Use frequency weights or a log-binned approximation:{p_end}
{phang2}{cmd:. fastrgini price [fw=rep78] }{p_end}
{phang2}{cmd:. fastrgini price, bin(100)}{p_end}

{pstd}Access returned results:{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. matrix list r(results)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fastrgini} is an {cmd:rclass} command. For a single variable it stores:

{synoptset 21 tabbed}{...}
{synopt:{cmd:r(G)}}conventional Gini{p_end}
{synopt:{cmd:r(rG)}}reciprocal Gini{p_end}
{synopt:{cmd:r(mG)}}bilateral inequality level{p_end}
{synopt:{cmd:r(sG)}}signed inequality orientation{p_end}
{synopt:{cmd:r(A2)}}Atkinson index with parameter 2{p_end}
{synopt:{cmd:r(p_pd)}}auxiliary quantile threshold{p_end}
{synopt:{cmd:r(se_}{it:x}{cmd:)}}jackknife standard error for statistic {it:x}, with {opt jk}{p_end}
{synopt:{cmd:r(results)}}6 x 1 matrix, rows {cmd:G rG mG sG A2 p_pd}{p_end}
{synopt:{cmd:r(se)}}6 x 1 standard-error matrix, with {opt jk}{p_end}

{pstd}
For two variables, {it:x} denotes any of {cmd:G}, {cmd:rG}, {cmd:mG},
{cmd:sG}, {cmd:A2}, or {cmd:p_pd}:

{synopt:{cmd:r(}{it:x}{cmd:_1)}}statistic for first variable{p_end}
{synopt:{cmd:r(}{it:x}{cmd:_2)}}statistic for second variable{p_end}
{synopt:{cmd:r(d_}{it:x}{cmd:)}}second minus first{p_end}
{synopt:{cmd:r(se_d_}{it:x}{cmd:)}}paired jackknife standard error of difference, with {opt jk}{p_end}
{synopt:{cmd:r(results)}}6 x 4 matrix: first, second, difference, percent change{p_end}
{synopt:{cmd:r(se)}}6 x 4 jackknife standard-error matrix, with {opt jk}{p_end}

{pstd}
In both modes, {cmd:r(N)} contains the number of included observations;
{cmd:r(sum_w)} contains the sum of weights when weights are specified.

{title:Remarks}

{pstd}
The reciprocal Gini is calculated by applying the ordinary Gini functional
to inverse income; no median normalization is required because the Gini is
scale invariant. Both {cmd:G} and {cmd:rG} lie between zero and one for
well-defined, positive finite distributions. The derived indices are
{cmd:mG} = (G + rG)/2 and {cmd:sG} = (G - rG)/(G + rG).
The transformation is reversible: G = mG*(1 + sG) and
rG = mG*(1 - sG), whenever sG is defined.

{pstd}
Results involving reciprocals may be highly sensitive to very small
positive incomes, measurement error, or data heaping in the lower tail.
Users should check data quality and consider sensitivity analyses.

{marker references}{...}
{title:References}

{phang}
Chauvel, L. 2026. Level and orientation of inequality: Reciprocal Gini
and income vulnerability in distributional analysis. Working paper.

{phang}
Ryu, H. K. 2013. A bottom poor sensitive Gini coefficient and maximum
entropy estimation of income distributions. {it:Economics Letters}
118(2): 370-374.

{phang}
Sajaia, Z. 2007. fastgini: Stata module to calculate Gini coefficient
with jackknife standard errors. Statistical Software Components,
Boston College Department of Economics.

{title:Author}

{pstd}
Louis Chauvel, University of Luxembourg.

{title:Also see}

{psee}
{help fastgini}, {help jackknife}, {help inequality}
{p_end}
