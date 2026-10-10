{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Description" "threshkit##description"}{...}
{viewerjumpto "Start here" "threshkit##start"}{...}
{viewerjumpto "Commands: by what kind" "threshkit##bykind"}{...}
{viewerjumpto "Commands: in detail" "threshkit##bydata"}{...}
{viewerjumpto "What is shared across the package" "threshkit##shared"}{...}
{viewerjumpto "Conventions" "threshkit##conventions"}{...}
{viewerjumpto "Example data" "threshkit##data"}{...}
{viewerjumpto "Validation" "threshkit##validation"}{...}
{viewerjumpto "What is out of scope" "threshkit##scope"}{...}
{viewerjumpto "References" "threshkit##refs"}{...}
{title:Title}

{phang}
{bf:threshkit} {hline 2} Threshold models for cross-sectional, univariate and
multivariate data: estimation, testing, inference and post-estimation


{marker description}{...}
{title:Description}

{pstd}
THRESHKIT implements the threshold-model literature in Stata: models in which
the relationship between variables changes when an {it:observed} variable
crosses a value that is itself estimated. That covers abrupt thresholds,
continuous kinks, smooth transitions, asymmetric adjustment, and their
multivariate counterparts, together with the tests of whether a threshold
exists at all and the confidence sets for where it is.

{pstd}
Official Stata's {helpb threshold} gives a point estimate of one or more
thresholds by conditional least squares, with information-criterion choice of
how many, for one equation on {helpb tsset} data. THRESHKIT adds the rest: the
linearity and threshold-existence tests, the confidence sets for the threshold,
the kink and smooth-transition families, asymmetric adjustment and bands of
inaction, the multivariate models, and the generalised impulse responses that a
nonlinear system needs instead of ordinary ones.

{pstd}
Every module is a clean-room implementation from the methodological papers, and
every one is covered by a certification suite that checks it against an
independent computation -- official Stata commands, or the same quantity rebuilt
by hand in Stata matrix algebra. See {help threshkit##validation:Validation}.


{marker start}{...}
{title:Start here}

{pstd}
{bf:{help threshkit_choose:help threshkit_choose}} is the guide to choosing
among these commands. It is not a list of syntax: it works through the questions
in the order they actually arise -- is there a threshold at all, which model
class, which test, which confidence interval, how many regimes, and for systems
of equations which multivariate model -- and says what each choice commits you
to. Read it before fitting anything.

{pstd}
If thirty-four commands is too many to start from, that page opens with two
tables built for exactly that moment:

{phang2}
{bf:{help threshkit_choose##start:START HERE}} -- a situation-to-command
table. The left column is phrased the way a researcher would describe their
own problem ("the relationship bends rather than jumps", "adjustment is faster
upward than downward"), not the way the method is named, because the distance
between those two is what makes a large package hard to enter.{p_end}

{phang2}
{bf:{help threshkit_choose##glance:The whole package at a glance}} -- all
thirty-four commands grouped by what they are for, one line each, so the
catalogue fits on one screen.{p_end}

{pstd}
The eleven steps after them are the full argument, with every claim sourced.
Read those once before your first threshold paper; use the two tables every
time after that.


{marker commands}{...}
{title:Commands}

{pstd}
All thirty-four, twice over. {bf:This first list groups them by what kind of
command each one is} -- a model to fit, a hypothesis to test, a specification
to choose, something to do after the fit -- which is the quickest way in when
you know the sort of thing you want but not its name. The
{help threshkit##bydata:detailed descriptions} below group the same commands
by the data they are for, and say what each one actually does.

{marker bykind}{...}

{synoptset 15 tabbed}{...}
{syntab:Fit a model}
{synopt:{helpb thregress}}a threshold (jump) in a cross-section{p_end}
{synopt:{helpb thkink}}a kink: continuous, the slope changes{p_end}
{synopt:{helpb thstr}}a smooth transition in a cross-section{p_end}
{synopt:{helpb thqreg}}a threshold at a quantile{p_end}
{synopt:{helpb thqkink}}a kink at a quantile, one or more{p_end}
{synopt:{helpb thivreg}}a threshold with endogenous regressors{p_end}
{synopt:{helpb thendog}}a threshold whose THRESHOLD VARIABLE is endogenous{p_end}
{synopt:{helpb thtar}}a SETAR / TAR in one time series{p_end}
{synopt:{helpb thsubtar}}a SETAR with a different AR order per regime{p_end}
{synopt:{helpb thstar}}a smooth transition autoregression{p_end}
{synopt:{helpb thmtar}}asymmetric adjustment, momentum thresholds{p_end}
{synopt:{helpb thtqar}}a SETAR at a quantile{p_end}
{synopt:{helpb thtvar}}a threshold VAR{p_end}
{synopt:{helpb thtvecm}}a threshold VECM{p_end}
{synopt:{helpb thstvar}}a vector smooth transition VAR{p_end}

{syntab:Test a hypothesis}
{synopt:{helpb thnltest}}is the series nonlinear at all?{p_end}
{synopt:{helpb thtest}}is there a threshold effect?{p_end}
{synopt:{helpb thqtest}}...at a quantile{p_end}
{synopt:{helpb thivtest}}...with endogenous regressors{p_end}
{synopt:{helpb thtarma}}...when the model has a moving-average part{p_end}
{synopt:{helpb thstrtype}}logistic or exponential transition?{p_end}
{synopt:{helpb thunitroot}}unit root, or a stationary threshold?{p_end}
{synopt:{helpb thbandur}}unit root, or a band of inaction?{p_end}

{syntab:Choose a specification}
{synopt:{helpb thnregimes}}how many regimes? (bootstrapped, full triangle){p_end}
{synopt:{helpb thnseq}}how many regimes? (sequential, no bootstrap){p_end}
{synopt:{helpb thselect}}how many thresholds? (criteria plus a test){p_end}
{synopt:{helpb thsearch}}which variable is the threshold variable?{p_end}
{synopt:{helpb thtarsel}}order, delay and regime count for a SETAR{p_end}
{synopt:{helpb thtvarsel}}the same for a system{p_end}

{syntab:After the fit}
{synopt:{helpb thsubci}}an interval for the threshold by subsampling{p_end}
{synopt:{helpb thforecast}}forecasts, densities and fan charts{p_end}
{synopt:{helpb thstarcycle}}the specification cycle for a STAR{p_end}
{synopt:{helpb thexport}}a publication table in LaTeX, RTF or Markdown{p_end}
{synopt:{helpb thsim}}simulate from a model you specify{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Post-estimation beyond those is {cmd:estat} and {cmd:predict} after each
command rather than separate commands: regime summaries and tables, profile
and likelihood-ratio plots, residual diagnostics tested against the
regime-split design, impulse responses and variance decompositions, the
deterministic skeleton, HAC standard errors, and equality tests across
regimes. Each command's own help lists the ones it provides.

{pstd}
If you know the question but not which of these answers it, go to
{helpb threshkit_choose##start:threshkit choose}, which maps a plain-language
description of a situation onto a command.


{marker bydata}{...}
{title:Commands in detail, by the data they are for}

{pstd}
{bf:Cross-sectional and general}

{synoptset 14 tabbed}{...}
{synopt:{helpb thregress}}threshold regression with one or more thresholds:
profile least squares, LR-inversion confidence sets for the threshold
(benchmark and conservative), two-step slope intervals{p_end}
{synopt:{helpb thkink}}continuous threshold (kink) regression: the threshold is
root-n normal, so its interval is a Wald interval{p_end}
{synopt:{helpb thstr}}cross-sectional smooth transition regression{p_end}
{synopt:{helpb thivreg}}threshold regression with ENDOGENOUS regressors:
concentrated 2SLS for the threshold, regime GMM for the slopes, and slope
intervals that do not condition on the estimated threshold{p_end}
{synopt:{helpb thtest}}tests of no threshold effect: sup, ave and exp of both F
and White-LM, with a fixed-regressor bootstrap{p_end}
{synopt:{helpb thendog}}threshold regression whose THRESHOLD VARIABLE is
endogenous: an inverse-Mills correction in each regime, and a t test on its
coefficient that IS a test of threshold exogeneity{p_end}
{synopt:{helpb thivtest}}sup-Wald test for a threshold WITH endogenous
regressors, in the size-corrected form: the Caner-Hansen test is badly sized
at the sample sizes applied work uses{p_end}
{synopt:{helpb thselect}}how many thresholds: information criteria and the
sequential bootstrap F(m+1|m){p_end}
{synopt:{helpb thsearch}}WHICH threshold variable, and which delay: a search
over a candidate set whose bootstrap repeats the search, so the p-value is a
p-value of the searched statistic{p_end}
{synopt:{helpb thnltest}}pre-estimation linearity tests: Keenan, Tsay (1986),
Tsay's (1989) arranged autoregression and CUSUM for one series; Tsay's (1998)
multivariate C(d) test for a system{p_end}
{synopt:{helpb thnregimes}}how many regimes: the full triangle of sequential
tests F(j|i), with a recursive bootstrap for autoregressions{p_end}
{synopt:{helpb thnseq}}how many regimes, the sequential way: each stage is an
ordinary linearity test because the thresholds already found are
super-consistent, so NO bootstrap is needed anywhere{p_end}

{pstd}
{bf:Univariate time series}

{synopt:{helpb thtar}}SETAR / TAR: self-exciting or exogenous threshold
variable, delay search, multiple thresholds{p_end}
{synopt:{helpb thtarsel}}joint selection of the autoregressive order, the
delay and the number of regimes for a SETAR, on ONE fixed sample, with the
whole trace{p_end}
{synopt:{helpb thsubtar}}subset SETAR with a DIFFERENT autoregressive order in
each regime, SETAR(2; k1, k2), by the Tong-Lim minimum-AIC procedure{p_end}
{synopt:{helpb thstar}}smooth transition autoregression: LSTAR, ESTAR and
second-order LSTAR, fitted by concentrated NLS{p_end}
{synopt:{helpb thstrtype}}WHICH smooth transition, logistic or exponential:
the Escribano-Jorda rule, with Teraesvirta's earlier sequence beside it and a
warning when the two disagree{p_end}
{synopt:{helpb thtarma}}threshold ARMA: the supLM test of an ARMA against a
TARMA, with the recursive bootstrap its non-pivotal limit needs{p_end}
{synopt:{helpb thstarcycle}}Terasvirta's seven-step specification cycle for a
smooth transition AR, run end to end: AR order, linearity, transition
variable, family, estimation, evaluation, report{p_end}
{synopt:{helpb thmtar}}asymmetric adjustment: Enders-Granger TAR and momentum-TAR,
and with {opt band} the Balke-Fomby band of inaction{p_end}
{synopt:{helpb thunitroot}}threshold AND unit root together: the Caner-Hansen
battery, including the partial unit root a linear ADF cannot see{p_end}
{synopt:{helpb thbandur}}unit root against a globally stationary THREE-regime
SETAR: a random walk inside a band of inaction, mean reversion outside it{p_end}
{synopt:{helpb thsubci}}subsampling confidence interval for a SETAR threshold
with the convergence RATE estimated from the data, so it is valid whether the
model has a jump or a kink{p_end}
{synopt:{helpb thforecast}}multi-step forecasts, forecast DENSITIES and fan
charts by simulation, with the regime recomputed at every step{p_end}
{synopt:{helpb thsim}}simulate data from a threshold model you specify, for
size and power studies, checks and teaching{p_end}

{pstd}
{bf:Quantile regression}

{synopt:{helpb thqreg}}threshold quantile regression: the regime shift is
allowed to differ across the distribution{p_end}
{synopt:{helpb thtqar}}threshold quantile autoregression for a time series{p_end}
{synopt:{helpb thqkink}}bent-line (kink) quantile regression with one or
several unknown kink points{p_end}
{synopt:{helpb thqtest}}threshold tests IN quantile regression: the sup-score
test at one quantile and the sup-Wald test uniform over a set of them{p_end}

{pstd}
{bf:Multivariate time series}

{synopt:{helpb thtvar}}threshold VAR: the whole coefficient matrix jumps at an
observed threshold{p_end}
{synopt:{helpb thtvarsel}}joint selection of the lag order, the delay and the
threshold for a TVAR, with the linear VAR printed beside it{p_end}
{synopt:{helpb thstvar}}vector smooth transition autoregression: the same two
regimes joined gradually{p_end}
{synopt:{helpb thtvecm}}threshold VECM: the speed of adjustment switches with
the size of the disequilibrium. {opt nthresh(2)} gives the three-regime
{bf:band} model, {opt sls} gives slope standard errors that are valid, and
{cmd:estat seotest} tests whether there is any cointegration at all{p_end}

{pstd}
{bf:Reporting}

{synopt:{helpb thexport}}export a publication table from ANY fit above, as
LaTeX, Markdown or CSV. The footer carries what a threshold table must report
and a generic exporter would not know to ask for: the threshold, its
confidence SET, a warning when that set is not an interval, the regime sizes
and the bootstrap p-value of the no-threshold test{p_end}


{marker shared}{...}
{title:What is shared across the package}

{pstd}
The commands are not independent programs that happen to sit in one folder.

{pstd}
{bf:One search engine.} {cmd:thregress}, {cmd:thtar} and {cmd:thselect} share a
single profile least-squares engine with incremental cross-products, so a grid
of every order statistic costs little more than a coarse one. {cmd:thstar},
{cmd:thstr} and {cmd:thstvar} share one concentrated-NLS engine and one set of
transition functions. {cmd:thtvar} and {cmd:thstvar} share one impulse-response
simulator: a sharp threshold is the limit of a logistic transition as the
smoothness goes to infinity, so there is no second implementation to keep in
step.

{pstd}
{bf:One bootstrap philosophy.} Wherever the threshold is unidentified under the
null -- which is everywhere a linearity test appears -- the p-value is simulated
with the design held fixed rather than read off a table. The Monte Carlo
standard error of each bootstrap p-value is reported, so you can see whether
your conclusion is distinguishable from the alternative at the number of
replications you used.

{pstd}
{bf:One likelihood convention.} All the multivariate commands report
-({it:n}/2)({it:k}(ln 2{it:pi} + 1) + ln|Sigma|), the same form official
{helpb var} uses, so their AIC, BIC and HQIC are comparable with each other and
with Stata's. The variant used in the published Tsay (1998) paper is not used;
see {help thtvar##ll:thtvar} for why that matters.

{pstd}
{bf:One side of the boundary.} An observation whose threshold variable equals
the threshold exactly belongs to regime 1, in every command.


{marker conventions}{...}
{title:Conventions}

{pstd}
{bf:Trimming.} {opt trim(0.15)} is the default everywhere: the threshold search
excludes the outer 15 per cent of the sorted threshold variable at each end, so
that no regime is too small to estimate. Lower it deliberately or not at all.

{pstd}
{bf:Three functionals.} Where a statistic is maximised over a nuisance
parameter, {opt stat(sup)}, {opt stat(ave)} and {opt stat(exp)} are all
available and all three are stored. Choose {it:before} looking at the results.
Reporting the largest of the three is a specification search.

{pstd}
{bf:Residual diagnostics are shared.} Every estimation command answers
{cmd:estat serial}, {cmd:estat archlm} and {cmd:estat normality}, and the
single-equation ones also {cmd:estat mcleodli}; {cmd:estat diag} runs them
together. They are not Stata's post-{cmd:regress} diagnostics with a different
name: the null regressors are the fitted model's {it:gradient}, which is what
makes each one a Lagrange-multiplier test rather than a residual regression
with the wrong null distribution, and the degrees of freedom are the rank
increase of the design. The multivariate versions are system tests with Rao's
F, and their Jarque-Bera statistics are computed on Cholesky-orthogonalised
residuals so the per-equation parts sum to the system statistic.

{pstd}
{bf:{cmd:estat} and {cmd:predict}.} Every estimation command has both.
{cmd:estat table} gives a publication summary; {cmd:estat regimes} gives the
regimes side by side; graph-producing subcommands take a {opt graph} option and
the usual {it:twoway} options.

{pstd}
{bf:Multi-equation prediction.} The system commands predict one equation at a
time: {cmd:predict} {it:newvar}{cmd:, residuals equation(}{it:name}{cmd:)}.


{marker data}{...}
{title:Example data}

{pstd}
Four datasets ship with the package, each built in Stata {it:directly from the
original author's text file} rather than imported through another language --
a CSV round trip through R costs eight significant digits, which is enough to
break a numerical comparison.

{synoptset 24 tabbed}{...}
{synopt:{cmd:threshkit_dj.dta}}Durlauf-Johnson cross-country growth, the data of
Hansen (2000){p_end}
{synopt:{cmd:threshkit_kink.dta}}Reinhart-Rogoff US debt and growth, the data of
Hansen (2017){p_end}
{synopt:{cmd:threshkit_ur.dta}}US unemployment 1959m1-1996m7, the data of
Hansen (1997){p_end}
{synopt:{cmd:threshkit_rates.dta}}US interest rates 1959m1-1993m2, the data of
Tsay (1998) and of Hansen and Seo (2002){p_end}
{synopt:{cmd:threshkit_example.do}}a guided tour over all four, in the order the
questions actually arise{p_end}
{p2colreset}{...}

{pstd}
These five live in a {bf:companion package}, {cmd:threshkitdata}, and not in
this one. The reason is a hard limit rather than a choice: a Stata
{cmd:.pkg} file lists at most {bf:100} files, and this package's commands,
help pages and compiled Mata library come to exactly 100. Nothing is missing
from {cmd:threshkit} as a result -- every command and every help page is here
and works without the data, which is needed only to {it:run} the examples.

{phang2}{cmd:. ssc install threshkitdata}{p_end}
{phang2}{cmd:. threshkitdata, get}{p_end}
{phang2}{cmd:. do threshkit_example.do}{p_end}

{pstd}
They are {bf:ancillary} files, so {cmd:ssc install} does not place them in the
adopath -- that is true of every package that ships data -- and
{cmd:threshkitdata, get} (equivalently {cmd:net get threshkitdata}) fetches
them into the current directory.

{pstd}
The tour is not a test -- the package's 48 certification suites do that. It is
for a reader who has just installed this and wants to see which command answers
which question, because the hard part of threshold modelling is not running a
command: it is choosing between a jump and a kink, between two regimes and
three, and between a threshold that is real and one the search found in noise.


{marker validation}{...}
{title:Validation}

{pstd}
Eleven certification suites live under {cmd:tests/reference/} and
{cmd:threshkit/build/runall_certifications.do} rebuilds the Mata library and
runs all of them in one session. They do not check the code against itself. Each
quantity is compared with an independent computation: official
{helpb regress}, {helpb var}, {helpb vec} and {helpb threshold}; the same
statistic rebuilt by hand from {helpb matrix accum}, {cmd:det()} and
{cmd:trace()}; the published numbers of the original papers; or the authors' own
R, MATLAB and GAUSS code where it exists. Tolerances are 1e-9 to 1e-12 for
anything that should agree exactly.

{pstd}
Several checks are identities that must hold whatever the data: a kink model is
a restricted jump model, so its residual sum of squares must be larger; a
threshold fit must beat the linear one; the two regimes must partition the
sample; a generalised impulse response at horizon one must reproduce the shock
vector exactly, because both simulated paths share the same future shocks.

{pstd}
Where the implementation departs from a published formula, the departure is
documented in the relevant help file rather than buried: the Tsay (1998)
likelihood, the use of a bootstrap in place of the Enders-Siklos tables, and the
two-step cointegrating vector in {cmd:thtvecm} are the three to know about.


{marker scope}{...}
{title:What is out of scope}

{pstd}
{bf:Panel data.} THRESHKIT does not fit panel threshold models. See
{helpb xthreg} (SSC).

{pstd}
{bf:Unobserved regimes.} If the regime is latent and follows a Markov chain, the
model is Markov switching, not a threshold model, and official Stata has it:
{helpb mswitch}. Threshold models require you to {bf:name} the variable that
does the switching, which is both their strength and their restriction.

{pstd}
{bf:Threshold GARCH} is official {helpb arch}; {bf:state-dependent local
projections} are SSC {cmd:locproj}.


{marker refs}{...}
{title:References}

{pstd}
Each command's help file carries the references for its own methods, with
verified DOIs. The two foundations of the whole package are:

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified under
the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit_choose}, {helpb thregress}, {helpb thkink},
{helpb thstr}, {helpb thtest}, {helpb thnltest}, {helpb thnregimes},
{helpb thselect}, {helpb thsearch}, {helpb thtar}, {helpb thstar},
{helpb thmtar}, {helpb thstarcycle}, {helpb thunitroot},
{helpb thivreg}, {helpb thqreg},
{helpb thtqar},
{helpb thqkink}, {helpb thforecast}, {helpb thsim},
{helpb thsubtar}, {helpb thtvar},
{helpb thtvarsel},
{helpb thstvar}, {helpb thtvecm}
{p_end}

{psee}
Official Stata: {helpb threshold}, {helpb mswitch}, {helpb var},
{helpb vec}, {helpb arch}, {helpb nl}
{p_end}
