{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtboundary" "help tvtboundary"}{...}
{vieweralsosee "tvtcoint" "help tvtcoint"}{...}
{viewerjumpto "Syntax" "tvtindex##syntax"}{...}
{viewerjumpto "Description" "tvtindex##description"}{...}
{viewerjumpto "Why smooth at all" "tvtindex##why"}{...}
{viewerjumpto "Options" "tvtindex##options"}{...}
{viewerjumpto "The bandwidth" "tvtindex##bandwidth"}{...}
{viewerjumpto "Reading the output" "tvtindex##output"}{...}
{viewerjumpto "Choosing among tvtindex, tvtboundary and tvtcoint" "tvtindex##versus"}{...}
{viewerjumpto "Examples" "tvtindex##examples"}{...}
{viewerjumpto "Stored results" "tvtindex##results"}{...}
{viewerjumpto "Validation" "tvtindex##validation"}{...}
{viewerjumpto "References" "tvtindex##references"}{...}
{viewerjumpto "Author" "tvtindex##author"}{...}
{title:Title}

{phang}
{bf:tvtindex} {hline 2} Smoothed least squares: a threshold on a linear
index, with normal inference


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtindex} {depvar} {it:indepvars} {ifin}{cmd:,}
{opth thr:eshvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:The index}
{synopt :{opth thr:eshvar(varname)}}required: the index's leading
variable, whose coefficient is normalised to one. It must be
continuous{p_end}
{synopt :{opth i:vars(varlist)}}further variables in the index; their
coefficients are estimated. {bf:These may be discrete}{p_end}
{synopt :{opth sh:iftvars(varlist)}}the regressors whose coefficients
shift; the default is all of them{p_end}

{syntab:Estimation}
{synopt :{opt bw:idth(#)}}the smoothing bandwidth; the default is
log(n)/sqrt(n){p_end}
{synopt :{opt gridn(#)}}points per index direction; default
{cmd:gridn(41)}{p_end}
{synopt :{opt ref:ine(#)}}refinement rounds; default {cmd:refine(4)}{p_end}
{synopt :{opt ir:ange(# #)}}bounds for the estimated index
coefficients{p_end}
{synopt :{opt hac(#)}}Bartlett lag for the slope variance; default
{cmd:hac(0)}, the heteroskedasticity-robust form{p_end}

{syntab:Reporting}
{synopt :{opt nocons:tant}}suppress the constant{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtindex} fits

{p 8 8 2}
{it:y_t} = {it:x_t'b} + {it:d'xtilde_t} {bf:1}{c -(}{it:index_t} >
0{c )-} + {it:e_t},{break}
{it:index_t} = {it:threshvar_t} + {it:g_0} + {it:g'ivars_t}

{pstd}
so the regime is decided by the sign of a {bf:linear index of observed
variables}. This is
{browse "https://doi.org/10.1016/j.jeconom.2006.11.002":Seo and Linton},
and it buys two things that the rest of this literature does not give.

{pstd}
{bf:Discrete variables can split the sample.} An ordinary threshold model
needs one pre-assigned continuous variable and gives everybody the same
threshold level. Here the index may carry dummies, so "the threshold level
of education differs between men and women" is a model you can write down
{hline 2} and because {it:g} is an estimated parameter with a standard
error, {bf:whether a variable belongs in the threshold is an ordinary
t-test}.

{pstd}
{bf:The threshold estimate is asymptotically normal.} That is unusual.
Chan's (1993) limit is a functional of a compound Poisson process, too
complicated to use. Hansen's (2000) needs the threshold effect to vanish
asymptotically {hline 2} the "small effect" case {hline 2} and its
distribution is unbounded at zero. Here neither assumption is needed and the
limit is normal, so ordinary t-statistics, Wald tests and confidence
intervals apply to the threshold itself.


{marker why}{...}
{title:Why smooth at all}

{pstd}
The least-squares criterion for a threshold model is a {bf:step function}
of the threshold parameter: it changes only when an observation crosses.
That is what makes the usual asymptotics awkward {hline 2} the criterion is
not differentiable, there is no Taylor expansion, and the limit is
non-standard.

{pstd}
Writing the criterion exactly (the indicator is idempotent, so this is an
identity, not an approximation)

{p 8 8 2}
{it:S_n} = (1/n) {c -(}sum ({it:y} - {it:x'b})^2{c )-} + (1/n)
{c -(}sum [({it:xtilde'd})^2 - 2{it:xtilde'd}({it:y} - {it:x'b})]
{bf:1}{c -(}{it:index} > 0{c )-}{c )-}

{pstd}
the estimator replaces the indicator by {it:K}({it:index}/{it:bandwidth})
for a smooth {it:K} that behaves like a {bf:cumulative distribution
function}, not like a density. The criterion becomes differentiable, and
normal theory follows.

{pstd}
The device is borrowed from Horowitz's (1992) smoothed maximum score
estimator, with one reversal worth knowing: there smoothing {it:slows}
convergence, here it also slows it, but the bandwidth enters the rate with
the opposite sign, so the two literatures give opposite advice about how
big to make it.

{pstd}
The kernel is the paper's own, {it:K}(x) = Phi(x) + x phi(x). Two
consequences are worth knowing:

{phang2}
{bf:K is a higher-order kernel, so K' takes negative values}, K is not
monotone, and {it:K}(x) can fall outside [0,1]. Assumption 3(b) requires
exactly that. The command reports the range it reached; it is not a defect.

{phang2}
{bf:The price of smoothing is a slower rate.} The slopes are still root-n
normal, but the threshold converges at sqrt(n/bandwidth), which with the
default bandwidth is about n^(3/4) rather than Chan's n. The two blocks are
asymptotically independent, which is why {cmd:e(V)} is block diagonal.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is the index's leading variable. Its coefficient
is {bf:normalised to one}, which is what identifies the rest of the index,
so it must be continuous and it cannot also appear in {opt ivars()}.

{phang}
{opth ivars(varlist)} adds variables to the index. One or two; each adds a
dimension to the search. {bf:These are the variables that may be discrete.}

{phang}
{opth shiftvars(varlist)} chooses which regressors get a regime shift. The
default is all of them plus the constant, which is the paper's leading
case; a proper subset is allowed and is often what the economics implies.

{phang}
{opt bwidth(#)} sets the smoothing bandwidth; see
{help tvtindex##bandwidth:The bandwidth}.

{phang}
{opt gridn(#)}, {opt refine(#)} and {opt irange(# #)} control the search.
Smoothing makes the criterion differentiable but {bf:not convex}, and with
a higher-order kernel local minima are real, so a coarse grid with
refinement rounds is used rather than a hill climb from a single start. It
is deterministic and cannot stall on a saddle.

{phang}
{opt hac(#)} gives the Bartlett lag for the slope variance. The paper is
explicit that with serial correlation the effect "does not die out", so
{bf:time-series users should set this}; {cmd:hac(0)}, the default, is the
heteroskedasticity-robust form that cross-sectional work wants.


{marker bandwidth}{...}
{title:The bandwidth}

{pstd}
{bf:Smaller is better for estimation here, which is the opposite of a
density bandwidth.} The rate of convergence is sqrt(n/bandwidth), so faster
shrinkage means a faster rate. The default log(n)/sqrt(n) is the paper's
own choice in its simulations and is the smallest the theory permits in the
i.i.d. case.

{pstd}
Two things follow:

{phang2}
as the bandwidth goes to zero the criterion approaches the unsmoothed
least-squares one, so the estimate approaches the ordinary threshold
estimate {hline 2} and loses the normal limit that is the point of the
command;

{phang2}
{bf:for testing, small is not necessarily best}. The paper's closing
remark is that bandwidth affects size and power differently. If you are
using the index coefficients to test, try more than one bandwidth and say
which you used.


{marker output}{...}
{title:Reading the output}

{pstd}
The coefficient table has three blocks:

{p2colset 8 20 22 2}{...}
{p2col :{bf:base}}the coefficient where the index is negative{p_end}
{p2col :{bf:shift}}what is ADDED where the index is positive{p_end}
{p2col :{bf:index}}the threshold parameters themselves{p_end}
{p2colreset}{...}

{pstd}
{cmd:index:_cons} is {bf:minus} the threshold level, so with no
{opt ivars()} the split is at {it:threshvar} = -{cmd:index:_cons}, which
the header prints directly and {cmd:e(threshold)} stores.

{pstd}
{bf:The standard errors in the index block are the reason to use this
command.} They are ordinary asymptotic standard errors, and the
t-statistics beside them are ordinary t-statistics {hline 2} on a threshold
parameter, which almost nothing else in this area can offer.

{pstd}
If the Hessian in the index parameters is not invertible the command says
so and reports no standard errors for that block rather than inventing
them. That means the criterion is flat or the optimum is at a saddle: try a
larger {opt bwidth()} or more {opt refine()} rounds.


{marker versus}{...}
{title:Choosing among tvtindex, tvtboundary and tvtcoint}

{pstd}
All three put the threshold at a linear function of observed variables.
They differ in what they assume and what inference they can deliver:

{p2colset 6 20 22 2}{...}
{p2col :{bf:tvtindex}}stationary or cross-sectional data; the criterion is
SMOOTHED, so the threshold estimate is asymptotically normal and you get
t-statistics on the index{p_end}
{p2col :{helpb tvtboundary}}stationary or cross-sectional data; the
criterion is left as a step function, so inference on the threshold comes
from a posterior interval instead{p_end}
{p2col :{helpb tvtcoint}}{bf:I(1)} regressors, a piecewise cointegrating
regression; no interval for the threshold at all{p_end}
{p2colreset}{...}

{pstd}
{bf:I(1) regressors settle it: use {helpb tvtcoint}.} Between the other
two, the question is what you want to say about the threshold. If you want
to {it:test} whether a variable belongs in it, use this command. If you
want an interval and are unwilling to choose a bandwidth, use
{helpb tvtboundary}. Running both is cheap and a disagreement is
informative.


{marker examples}{...}
{title:Examples}

{pstd}An ordinary threshold, but with a normally-distributed threshold
estimate{p_end}
{phang2}{cmd:. tvtindex y x2, threshvar(q)}{p_end}

{pstd}The threshold level differs by sex {hline 2} and the t-statistic says
whether it really does{p_end}
{phang2}{cmd:. tvtindex logwage educ exper, threshvar(educ_level) ivars(female)}{p_end}
{phang2}{cmd:. test [index]female}{p_end}

{pstd}Only the slope on {cmd:educ} shifts, not the intercept{p_end}
{phang2}{cmd:. tvtindex logwage educ exper, threshvar(educ_level) shiftvars(educ)}{p_end}

{pstd}Time-series data, so the slope variance needs a HAC{p_end}
{phang2}{cmd:. tvtindex y L.y L2.y, threshvar(L.y) hac(4)}{p_end}

{pstd}How much does the bandwidth matter? Report more than one{p_end}
{phang2}{cmd:. foreach b in 0.3 0.2 0.1 {c -(}}{p_end}
{phang2}{cmd:.     tvtindex y x2, threshvar(q) bwidth(`b')}{p_end}
{phang2}{cmd:.     display "`b'  " e(threshold) "  " _se[index:_cons]}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tvtindex} is {cmd:e}-class. It stores

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(threshold)}}minus {cmd:index:_cons}; meaningful when the
index has no other variables{p_end}
{synopt:{cmd:e(bwidth)}}the bandwidth used{p_end}
{synopt:{cmd:e(sn)}}the minimised smoothed criterion{p_end}
{synopt:{cmd:e(ssr)}}sum of squared residuals at the fit{p_end}
{synopt:{cmd:e(ssr_lin)}}the linear model's{p_end}
{synopt:{cmd:e(N_above)}, {cmd:e(N_below)}}observations either side of the
index{p_end}
{synopt:{cmd:e(K_min)}, {cmd:e(K_max)}}the range the kernel reached{p_end}
{synopt:{cmd:e(n_eval)}}criterion evaluations{p_end}
{synopt:{cmd:e(vfailed)}}1 if the index Hessian was not invertible{p_end}
{synopt:{cmd:e(k_base)}, {cmd:e(k_shift)}, {cmd:e(k_index)}}block
sizes{p_end}
{synopt:{cmd:e(gridn)}, {cmd:e(refine)}, {cmd:e(hac)}}as specified{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtindex}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}the regressors{p_end}
{synopt:{cmd:e(shiftvars)}}those that shift{p_end}
{synopt:{cmd:e(threshvar)}}the index's leading variable{p_end}
{synopt:{cmd:e(ivars)}}the rest of the index{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust} or {cmd:HAC}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients in three equations,
{cmd:base}, {cmd:shift} and {cmd:index}. {cmd:e(V)} is block diagonal
between slopes and index, which is a {it:result} (Theorem 2), not an
approximation{p_end}
{synopt:{cmd:e(gamma2)}}the index coefficients{p_end}
{synopt:{cmd:e(path)}}the fitted index, observation by observation{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
No code ships with this paper, so {cmd:tvtindex} is clean-room from the
published equations and is checked three ways.

{phang2}
{bf:The kernel, exactly.} The paper states {it:K}'(0) = 0.798 and
||{it:K}'||^2 = 0.776 for its kernel. Both are reproduced, the first to
machine precision as sqrt(2/pi). The higher-order condition of Assumption
3(b) is verified by numerical integration.

{phang2}
{bf:The paper's own Table 1a.} The robust dispersion of the threshold
estimate in Hansen's (2000) design, at {it:n} = 500 and 1000, in both the
{it:x2} = {it:q} and the independent-{it:x2} cases.

{phang2}
{bf:Structure.} That a shrinking bandwidth drives the estimate to the
unsmoothed least-squares threshold; that a discrete index variable is
recovered with a significant coefficient; the identities and the guards.

{pstd}
The suite is {cmd:tests/reference/tvtindex/certify_tvtindex.do} and the
equation-by-equation map is in
{cmd:validation/tvthresh/tvtindex_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least
squares estimator of a threshold autoregressive model. {it:Annals of
Statistics} 21: 520-533.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.

{phang}
Horowitz, J. L. 1992. A smoothed maximum score estimator for the binary
response model. {it:Econometrica} 60: 505-531.

{phang}
Seo, M. H., and O. Linton. 2007. A smoothed least squares estimator for
threshold regression models. {it:Journal of Econometrics} 141(2): 704-735.
{browse "https://doi.org/10.1016/j.jeconom.2006.11.002":doi:10.1016/j.jeconom.2006.11.002}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
