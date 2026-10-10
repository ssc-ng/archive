{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "threshkit choose (which test?)" "help threshkit_choose"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{viewerjumpto "Syntax" "thtest##syntax"}{...}
{viewerjumpto "Description" "thtest##description"}{...}
{viewerjumpto "Options" "thtest##options"}{...}
{viewerjumpto "Remarks" "thtest##remarks"}{...}
{viewerjumpto "Which statistic?" "thtest##which"}{...}
{viewerjumpto "Examples" "thtest##examples"}{...}
{viewerjumpto "Stored results" "thtest##results"}{...}
{viewerjumpto "References" "thtest##refs"}{...}
{title:Title}

{phang}
{bf:thtest} {hline 2} Test of no threshold effect against a two-regime threshold
model with an unknown threshold

{marker davies}{...}
{title:The Davies bound: a p-value that needs no bootstrap}

{pstd}
The threshold is not identified under the null, so {it:S}({it:gamma}) is a
whole {bf:process} and sup {it:S} is {bf:not} chi-squared however large the
sample. That is the whole difficulty, and it is why this command bootstraps.

{pstd}
Davies (1987) bounds the tail analytically instead:

{p 8 8 2}
P(sup {it:S} > {it:M}) {ul:<} P(chi2_{it:q} > {it:M}) + {it:V} {it:M}^(({it:q}-1)/2) exp(-{it:M}/2) 2^(-{it:q}/2) / Gamma({it:q}/2)

{pstd}
where {it:M} is the observed maximum, {it:q} the number of restrictions, and
{it:V} the {bf:total variation} of sqrt({it:S}({it:gamma})) along the grid.
The first term is what you would get if the threshold were known. The second
is {bf:the price of having searched for it}, and it grows with how much the
path moves — which is exactly the right penalty, because a path that wanders
a long way has had more chances to throw up a large maximum by luck.

{pstd}
{bf:It is an upper bound, not a p-value.} The true tail probability is
smaller, so the bound is conservative: a rejection by Davies is a {bf:safe}
rejection, and a non-rejection is {bf:not} evidence of linearity. Its value
here is as an {bf:independent cross-check} on the bootstrap. The two are
computed from entirely different arguments — one analytic, one by
simulation — so when they agree you have real reassurance, and when they
disagree by a lot one of them is being asked for something it cannot give.

{pstd}
Both are reported whenever {opt davies} is specified, side by side. The
bound is computed in any case and returned in {cmd:r(davies_F)} and
{cmd:r(davies_LM)}; the option only controls whether it is displayed.

{pstd}
Two cautions. {it:V} is measured {bf:on the grid}, so a coarse grid
understates the variation and makes the bound look tighter than it is —
compare across {opt gridn()} before leaning on it. And the bound assumes the
pointwise statistic is chi-squared under the null, which the LM form is by
construction; under strong heteroskedasticity use the bootstrap, which does
not need that assumption.

{pstd}
{cmd:r(pathF)} and {cmd:r(pathLM)} hold the statistic at {bf:every} candidate
threshold, which is what the bound is computed from and what
{cmd:estat lrplot} draws after a fit.


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtest} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth threshvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth threshvar(varname)}}candidate threshold variable{p_end}
{synopt:{opth inv:ariant(varlist)}}extra regressors that are conditioned on but never switch{p_end}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}search {it:#} sample quantiles instead of all distinct values{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(1000)}, minimum 100{p_end}
{synopt:{opt dav:ies}}also report the Davies (1987) analytic upper bound on the p-value{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt hansencompat}}bootstrap from the null residuals, as Hansen's code does{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thtest} tests

{p 12 12 2}H0: the regression is linear{break}
H1: it has two regimes split at an unknown value of {opt threshvar()}

{pstd}
and reports {bf:six} statistics: sup, ave and exp of the homoskedastic F process
and of the White-robust LM process, each with a fixed-regressor bootstrap p-value
and its Monte Carlo standard error.

{pstd}
Official Stata has no such test. {helpb estat sbsingle} tests for a break at an
unknown {it:date} and cannot sort by a covariate, which is a different model.

{pstd}
{bf:Why the p-value must be simulated.} Under H0 the threshold is not identified:
it appears only under the alternative. The limiting null distribution is a
functional of a chi-square process whose covariance kernel depends on the data,
and Hansen (1996, Theorem 1) shows it is {bf:not tabulable}. There is no table to
look the statistic up in. Any threshold test reported against an F or chi-square
critical value is wrong.

{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is the candidate splitting variable. It should be
continuously distributed.

{phang}
{opth invariant(varlist)} adds regressors that are included in both the null and
the alternative but never switch. The test then asks whether the {it:other}
coefficients change.

{phang}
{opt trim(#)} excludes that fraction of the sample at each end of the candidate
range. The default 0.15 follows Andrews (1993) and Hansen's own applications.
Results depend on it: {bf:report the value you used}.

{phang}
{opt reps(#)} and {opt seed(#)} control the fixed-regressor bootstrap. The Monte
Carlo standard error of each p-value is printed; at p = .09 with 1000
replications it is about .009, so p = .09 and p = .07 are not distinguishable.

{phang}
{opt hansencompat} draws the bootstrap errors from the {it:null} (global OLS)
residuals, which is what Hansen's published code does. The default follows the
text of Hansen (2000, p.587) and uses residuals from the threshold fit. The
choice is not cosmetic: on the shipped growth data it moves the sup-LM p-value
from 0.062 to 0.085.

{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The fixed-regressor bootstrap.} The regressors and the threshold variable are
held fixed and only the dependent variable is redrawn, so the bootstrap respects
the design and the unidentified-nuisance-parameter structure. For the robust
family the errors are multiplied by N(0,1) draws, which preserves each
observation's own scale and so allows conditional heteroskedasticity.

{pstd}
{bf:The Davies bound is not available here and that is deliberate.} Davies (1987)
gives a cheap upper bound for problems with a nuisance parameter identified only
under the alternative, but Hansen (1996, p.8, Table I) shows it is {bf:invalid}
for a discontinuous threshold. It is legitimate for smooth or kink alternatives,
which is why {helpb thkink} offers it and {cmd:thtest} does not.

{marker which}{...}
{title:Which statistic should you report?}

{pstd}
Decide {it:before} you look at the output. Reporting the smallest of six p-values
is a specification search and the reported p-value is then meaningless.

{p2colset 6 22 24 2}{...}
{p2col:{bf:sup-LM}}The default recommendation. Hansen (1996, Table II) reports that the robust sup-{it:Wald} test rejects 14-32% of the time at a nominal 5% when n = 100, while the sup-{it:LM} version is correctly sized. Best power against a single sharp threshold.{p_end}
{p2col:{bf:ave-LM}}Better power when the effect is spread over a range of candidate thresholds rather than concentrated at one.{p_end}
{p2col:{bf:exp-LM}}The Andrews-Ploberger (1994) optimal test. A defensible default when you have no prior about where the threshold lies.{p_end}
{p2col:{bf:the F family}}Use only when you are willing to assert conditional homoskedasticity. Compare the two families in the output: if they disagree materially, the error variance depends on the regressors and you should report the LM family.{p_end}
{p2colreset}{...}

{pstd}
{bf:Choosing the threshold variable.} If several candidates are plausible, run
{cmd:thtest} once per candidate and {bf:report all of them}, as Hansen (2000,
p.587) does for income and literacy. Keeping only the most significant one
invalidates the p-value.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use threshkit_dj}{p_end}

{pstd}Is there a growth threshold in 1960 income?{p_end}
{phang2}{cmd:. thtest diff gdp60 iony pgro sch, threshvar(q)}{p_end}

{pstd}Reproduce Hansen (2000): sup-LM = 12.60, p about 0.088{p_end}
{phang2}{cmd:. set seed 20261001}{p_end}
{phang2}{cmd:. thtest diff gdp60 iony pgro sch, threshvar(q) hansencompat}{p_end}

{pstd}The competing candidate, reported alongside, not instead{p_end}
{phang2}{cmd:. thtest diff gdp60 iony pgro sch, threshvar(lit) hansencompat}{p_end}

{pstd}More replications when the decision is marginal{p_end}
{phang2}{cmd:. thtest diff gdp60 iony pgro sch, threshvar(q) reps(10000)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:thtest} is {it:rclass}. It stores{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(supF)}, {cmd:r(aveF)}, {cmd:r(expF)}}homoskedastic statistics{p_end}
{synopt:{cmd:r(supLM)}, {cmd:r(aveLM)}, {cmd:r(expLM)}}White-robust statistics{p_end}
{synopt:{cmd:r(p_supF)} … {cmd:r(p_expLM)}}the six bootstrap p-values{p_end}
{synopt:{cmd:r(gamma_f)}, {cmd:r(gamma_lm)}}grid point maximising each family{p_end}
{synopt:{cmd:r(N)}, {cmd:r(reps)}, {cmd:r(trim)}, {cmd:r(n_grid)}}sample and settings{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(statF)}, {cmd:r(statLM)}}statistics, columns sup/ave/exp{p_end}
{synopt:{cmd:r(pF)}, {cmd:r(pLM)}}p-values, columns sup/ave/exp{p_end}
{p2colreset}{...}

{marker refs}{...}
{title:References}

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present
only under the alternative. {it:Biometrika} 74: 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}

{phang}
Andrews, D. W. K. 1993. {it:Econometrica} 61: 821-856.
{browse "https://doi.org/10.2307/2951764":doi:10.2307/2951764}.

{phang}
Andrews, D. W. K., and W. Ploberger. 1994. {it:Econometrica} 62: 1383-1414.
{browse "https://doi.org/10.2307/2951753":doi:10.2307/2951753}.

{phang}
Davies, R. B. 1987. {it:Biometrika} 74: 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under
the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation. {it:Econometrica}
68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thregress},
{helpb thselect}, {helpb thkink}, {helpb thnregimes}, {helpb thnltest}

{psee}
The same question in other settings:
{helpb thtarma} (a threshold in an ARMA), {helpb thqtest} (at a quantile),
{helpb thivtest} (with endogenous regressors), {helpb thstrtype} (logistic or
exponential, once a smooth transition is indicated)
{p_end}
