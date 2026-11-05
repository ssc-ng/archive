{smcl}
{* v 1.0.0 Leonelo Bautista 19Nov2025 }
{cmd:Help for epidem}{right: }
{hline}

{title:Title}
{p 4 4 2}{hi:epidem}{hline 2}Suite of tools to detect outbreaks from
{it:surveillance data}:

{phang}{hi:channel} – uses different methods to classify epidemiologic weeks
as {it:Baseline/Alarm/Alert/Epidemic} and draws the endemic channel.{p_end}

{phang}{hi:rregmm} – classifies weeks in the evaluation year using robust MM
regression and draws an epidemic curve by week type.{p_end}

{phang}{hi:ppvalue} – estimates the posterior probability of a progressive
increase in cases in the two weeks following the week being evaluated.{p_end}

{title:Jump to}

{p 4 8 2}
{help epidem##overview:Overview}{break}
{help epidem##syntax:Syntax}{break}
{help epidem##weeks:Epidemiologic weeks}{break}
{help epidem##channel:channel}{break}
{help epidem##rregmm:rregmm}{break}
{help epidem##ppvalue:ppvalue}{break}
{help epidem##references:References}{break}
{help epidem##author:Author}{break}
{help epidem##alsosee:Also see}

{marker overview}{...}
{title:Overview}

{pstd}
{hi:epidem} is a wrapper that provides a unified entry point for four related tools:

{phang}
1) {hi:epidem channel} – calls {hi:channel} to construct the endemic channel
using the average number of cases and its lower and upper historical
limits in the corresponding week and adjacent weeks from previous (reference)
years as cut points, and classifies each week as
{it:Baseline}, {it:Alarm}, {it:Alert}, or {it:Epidemic}. The average number of
cases and its confidence interval is calculated using different
methods. Depending on the method selected with {hi:met()}, the historical
limits are estimated either as 95% prediction intervals ({hi:regmean}
and {hi:robmean}) or as 95% bootstrap confidence intervals ({hi:bsmedian}).

{phang}
2) {hi:epidem rregmm} – calls {hi:rregmm} to classify weeks in the evaluation
year {it:yeval} using robust MM regression fitted to data from the {it:ryspan}
preceding years. It produces robust standardized residuals, labels each week
as {it:Baseline}, {it:Alarm}, {it:Alert}, or {it:Epidemic}, and graphs the
epidemic curve by week type.

{phang}
3) {hi:epidem ppvalue} – calls {hi:ppvalue} to estimate, for a user-selected
week and year, the posterior probability of a {it:progressive increase}
in cases over the next two weeks. {hi:ppvalue} uses the same methods as
{hi:channel} to estimate the sensitivity and specificity of the method and the
method- and week-specific prevalence of a progressive increase in case counts
during the reference period. These estimates are then combined using a
Bayesian approach to estimate the posterior probability of a progressive
increase in the number of cases in the two weeks following the week of
interest
(usually the current or index week).

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}{hi:Main suite command}

{p 4 12 1}
{cmd:epidem} {it:subcommand} {it:casevar} {it:yearvar} {it:weekvar} [{cmd:,} {it:options}]

{pstd}
where {it:subcommand} is one of:

{p 8 14 2}
{cmd:channel} constructs the endemic channel using a user-selected method. {break}

{p 8 14 2}
{cmd:rregmm} classifies weeks in the year been evaluated ({it:yeval}) using
robust MM regression and draws an epidemic curve by week type. {break}

{p 8 14 2}
{cmd:ppvalue} computes the week-specific posterior probability of a
progressive increase in the number of cases over the next two weeks. {break}

{p 4 12 1}
Subcommands {cmd:channel}, {cmd:rregmm}, and {cmd:ppvalue} have their own
options and behavior (see below).

{marker weeks}{...}
{title:A note on epidemiologic weeks}

{pstd}
Many public health surveillance systems define epidemiologic years as
containing either 52 or 53 epidemiologic
weeks. epidem requires that all years in the input dataset contain the same
number of weeks. Therefore, datasets
containing a mixture of 52- and 53-week years must be harmonized before
analysis. This may be accomplished,
for example, by redistributing cases from week 53 between week 52 of the same
year and week 1 of the following
year to obtain a 52-week series, or by adding week 53 to years with only 52
weeks to obtain a balanced 53-week
series.

{hline}
{marker channel}{...}
{title:Subcommand channel}

{title:Syntax for channel}

{p 4 12 1}
{cmd:epidem} {cmd:channel} {it:casevar} {it:yearvar} {it:weekvar} {break}
[{cmd:,} {it:options} {cmd:yeval}{cmd:(}{it:#}{cmd:)}
{cmd:yspan}{cmd:(}{it:#}{cmd:)} {cmd:wspan}{cmd:(}{it:#}{cmd:)}
{cmd:smoother}{cmd:(}{it:string}{cmd:)}
{cmd:met}{cmd:(}{it:regmean|bsmedian|robmean}{cmd:)} {cmd:jitter}
{cmd:seed}{cmd:(}{it:#}{cmd:)} {cmd:reps}{cmd:(}{it:#}{cmd:)}
{cmd:grsave}{cmd:(}{it:string}{cmd:)} {cmd:fsave}{cmd:(}{it:string}{cmd:)}
{cmd:meanopts}{cmd:(}{it:line_options}{cmd:)}
{cmd:lbopts}{cmd:(}{it:line_options}{cmd:)}
{cmd:ubopts}{cmd:(}{it:line_options}{cmd:)}
{cmd:obsopts}{cmd:(}{it:line_options}{cmd:)} {cmd:xlines}
{cmd:xlineopts}{cmd:(}{it:line_options}{cmd:)} ]

{p 4 4 2}
{cmd:met() is required} and must be one of {cmd:regmean}, {cmd:bsmedian}, or {cmd:robmean}.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt yeval}}Year being evaluated for potential {it:casevar} epidemic weeks.{p_end}
{synopt :{opt yspan}}Number of previous years (usually 5) used to estimate the expected number of cases for {it:casevar} in {it:yeval}.{p_end}
{synopt :{opt wspan}}Half-window size (± weeks) used to estimate the expected number of cases for each week in {it:yeval}.{p_end}
{synopt :{opt met(regmean)}}Uses linear regression to estimate the expected number of cases and its 95% predcition interval (see {helpb regress}) and graphs the endemic channel (Stroup et al.).{p_end}
{synopt :{opt met(robmean)}}Uses robust regression to estimate the expected number of cases and its 95% prediction interval (see {helpb rreg}), and graphs the endemic channel.{p_end}
{synopt :{opt met(bsmedian)}}Estimates the bootstrapped median and its bias-corrected and accelerated (BCa) 95% confidence interval (see {helpb bootstrap}), smoothes them with {helpb tssmooth nl} with {it: 8453EH, twice} as the default smoother, and graphs the endemic channel.{p_end}
{synopt :{opt smoother}}Nonlinear smoother for the mean and bounds. Defaults are method-specific (see below).{p_end}
{synopt :{opt jitter}}jitter adds a small positive random perturbation to the case counts before estimation. The perturbation is used only during the internal estimation procedure to reduce convergence problems caused by zero counts or long runs of identical values, particularly when using {cmd:met}({it:bsmedian}) or {cmd:met}({it:robmean}).{p_end}
{synopt :{opt seed(#)}}Specifies the random-number seed used by procedures involving random-number generation. The default is {cmd:seed(313151)}, which ensures reproducibility when a seed is not explicitly specified.{p_end}
{synopt :{opt reps(#)}}For {cmd:met(bsmedian)} only. Specifies the number of bootstrap replications used to estimate the median confidence interval. The default is {cmd:reps(1000)}.{p_end}
{synopt :{opt logcases}}For {cmd:met(regmean)} only. It uses {cmd:ln({it:casevar}+1)} to estimate the mean and reports results on the original count scale (default).{p_end}
{synopt :{opt rawcases}}For {cmd:met(regmean)} only. It estimates the mean using the original counts ({cmd:{it:casevar}}) without log transformation.{p_end}
{synopt :{opt grsave(filename)}}Saves the endemic-channel graph (see graph) using the filename specified by the user. See additional graph options below.{p_end}
{synopt :{opt meanopts(line_options)}}Specifies line options for the mean or median line.{p_end}
{synopt :{opt lbopts(line_options)}}Specifies line options for the lower-limit line.{p_end}
{synopt :{opt ubopts(line_options)}}Specifies line options for the upper-limit line.{p_end}
{synopt :{opt obsopts(line_options)}}Specifies line options for the observed-case line.{p_end}
{synopt :{opt xlines}}Adds vertical reference lines at the x-axis tick values. Vertical reference lines are omitted by default.{p_end}
{synopt :{opt xlineopts(line_options)}}Specifies line options for the vertical reference lines requested with {opt xlines}.{p_end}
{synopt :{opt nograph}}Prevents the plotting of the endemic channel.{p_end}
{synopt :{opt fsave(filename)}}Saves the output dataset. If fsave() is not used the file is saved with a default name {it:casevar}{it:yeval}{it:wspan}_{it:method}{cmd:.dta}, where {it:method} is {cmd:regmean}, {cmd:robmean}, or {cmd:bsmedian}.{p_end}
{synoptline}

{title:A note on the default smoother}

{pstd}
{cmd:regmean} and {cmd:robmean} use {cmd:3S5RHE, twice} as the default
smoother, whereas {cmd:bsmedian} uses {cmd:8453EH, twice}. These defaults
were selected empirically through evaluation of surveillance datasets and
simulations to provide stable endemic channels under a wide range of
surveillance scenarios. In particular, the more aggressive {cmd:3S5RHE}
smoother occasionally produced unstable results when applied to the
bootstrap median, whose resampling-based estimates generally required less
post-estimation smoothing than the regression-based methods.

{pstd}
{cmd:8453EH} is a sequence of nonlinear median smoothers with robustness
iterations, endpoint corrections, and a final Hanning smoothing. The
numeric pattern (8-4-5-3) identifies the smoothing window span used at each
step. The letter {cmd:E} indicates that endpoint corrections are
applied, whereas {cmd:H} indicates that the final smooth is a Hanning weighted
moving average with weights 1/4, 1/2, and 1/4.

{pstd}
{cmd:3S5RHE} consists of a running median of three observations followed by
Tukey's splitter ({cmd:S}), which breaks flat hills and valleys
created by repeated values, a running median of five observations, repeated
Hanning smoothing ({cmd:H}), and endpoint corrections ({cmd:E}).
The splitter is particularly useful when case counts are low or unchanged over
several consecutive weeks because it preserves local features
that would otherwise be flattened by repeated median smoothing.

{pstd}
The {cmd:twice} option performs a second-stage smoothing intended to restore
short-term features that may have been attenuated by the initial
smoothing. It does this by computing the differences between the observed and
smoothed values (the {it:rough}), smoothing these differences,
and adding the smoothed rough back to the original smooth.

{pstd}
Although {cmd:twice} often improves the fit, applying it separately to the
central estimate and its limits can occasionally compromise their
expected ordering. The smoothed lower limit may exceed the smoothed central
estimate, or the smoothed upper limit may fall below it. These
inconsistencies are most likely when case counts are low and can often be
resolved by omitting {cmd:twice} or by using a less aggressive smoother,
such as {cmd:3RSSH} or {cmd:4253H}.

{synoptline}

{title:Graph options for channel}

{phang}
{opt logscale} specifies that the endemic channel is graphed using a
logarithmic y-axis. By default, the graph is drawn on the original (linear)
scale.
Logarithmic scaling may be useful when the number of cases varies widely
across weeks or when large peaks dominate the pattern. The option applies only
to
the displayed graph; all calculations are performed on the use selected scale
(see options: {opt logcases} and {opt rawcases}).

{phang}
{opt ysrange(# #)} forces the y-axis to span the specified minimum and maximum
values. When used without {opt logscale}, the scale remains linear.
When used together with {opt logscale}, the specified range is applied to the
logarithmic axis, and values must be positive.

{phang}
{opt grtitle(string)} specifies a custom title for the endemic-channel graph.
If omitted, a default title is constructed using the outcome variable,
the evaluated year, the reference years, the week span, and the selected method.

{phang}
{opt yvalues(numlist)} specifies the exact tick marks to be displayed on the
y-axis. This option overrides the default {cmd:ylabel()} values and any
values implied by {opt ysrange()}. It may be used with or without {opt logscale}. The default is to let Stata choose the y-axis tick values.{p_end}

{phang}
{opt grsave(filename)} saves the endemic-channel graph for {it:casevar} in
year {it:yeval} with the file name provided by the user, in Stata format (see
{helpb graph}).{p_end}

{phang}
{opt meanopts(line_options)} specifies line options for the mean or median
line. By default, its appearance is determined by the active Stata graph
scheme. For example, {cmd:meanopts(lcolor(black) lpattern(solid))} draws the
line in black with a solid pattern.{p_end}

{phang}
{opt lbopts(line_options)} specifies line options for the lower-limit line. By
default, its appearance is determined by the active Stata graph scheme.{p_end}

{phang}
{opt ubopts(line_options)} specifies line options for the upper-limit line. By
default, its appearance is determined by the active Stata graph scheme.{p_end}

{phang}
{opt obsopts(line_options)} specifies line options for the observed-case line.
By default, its appearance is determined by the active Stata graph scheme. For
example, {cmd:obsopts(lcolor(black) lpattern(solid))} draws the observed-case
line in black with a solid pattern.{p_end}

{phang}
{opt xlines} adds vertical reference lines at the x-axis tick values. These
lines are omitted by default.{p_end}

{phang}
{opt xlineopts(line_options)} specifies line options for the vertical
reference lines requested with {opt xlines}. For example, {cmd:xlines xlineopts(lpattern(dash))} requests vertical reference lines with a dashed
pattern.{p_end}

{title:Description for channel}

{p 4 4 2}
{hi:epidem channel} calculates the mean number of cases of a disease
({it:casevar}) for each unit of time, usually an epidemiologic week
({it:weekvar}),
using data from a selected number of years ({it:yspan}) that immediately
precede the year being evaluated ({it:yeval}). It then calculates the
predicted mean of the
number of cases for each week of {it:yeval}. {hi:epidem channel} does not work
with individual-level datasets (i.e., datasets with one observation per case).
Before
using {hi:epidem channel}, the data must be collapsed by year and week (see
{helpb collapse}), plus any other variable of interest (e.g., region,
province, age).
The predicted mean number of cases for a given week is calculated using the
number of cases for that week and the number of cases in weeks preceding and
following
that week, as defined by {it:wspan}, in the reference years, as defined by
{it:yspan}. The program also calculates 95% confidence limits for the
predicted mean,
based on the {it:t}-distribution for {cmd:regmean} and {cmd:robmean}, and the
empirical 2.5% and 97.5% percentiles for {cmd:bsmedian}. The mean and its
limits are
then smoothed using a nonlinear smoother (3S5RHE) (see {helpb tssmooth} and
the description of the default smoother above).

{p 4 4 2}
{hi:epidem channel} generates an output file (see option: {cmd:fsave()}) that
can be used for further analyses, and restores the original dataset. The
output file includes
the following variables:

{synoptset 26 tabbed}{...}
{synopthdr:Variable:Description}
{synoptline}
{synopt :{hi:ytested}}Year tested{p_end}
{synopt :{hi:week}}Epidemiologic week{p_end}
{synopt :{hi:obscases}}Observed cases of {it:casevar}{p_end}
{synopt :{hi:ystart}}Earliest reference year{p_end}
{synopt :{hi:yend}}Latest reference year{p_end}
{synopt :{hi:mean_casevar}}Non-smoothed mean/median/robust mean of cases{p_end}
{synopt :{hi:stdp}}Standard error of the mean (if applicable){p_end}
{synopt :{hi:stdf}}Standard error of the predicted mean (if applicable){p_end}
{synopt :{hi:lb}}Lower 95% bound (non-smoothed){p_end}
{synopt :{hi:ub}}Upper 95% bound (non-smoothed){p_end}
{synopt :{hi:meansmooth}}Smoothed mean/median/robust mean{p_end}
{synopt :{hi:lbsmooth}}Smoothed lower 95% bound{p_end}
{synopt :{hi:ubsmooth}}Smoothed upper 95% bound{p_end}
{synopt :{hi:wtype}}Epidemic week type{p_end}
{synopt :{hi:ws}}Week span (± weeks){p_end}
{synopt :{hi:wref}}Number of reference weeks (2*ws+1){p_end}
{synopt :{hi:met}}Method used (regmean, robmean, bsmedian){p_end}
{synoptline}

{title:Specific options for channel}

{phang}
{opt yeval} specifies the year being evaluated, usually the current year.{p_end}

{phang}
{opt yspan} specifies the number of immediately preceding years used as
reference to estimate the expected number of cases in {it:yeval}.
Traditionally, five years are used for this purpose, but a longer span may be
appropriate if incidence is stable.{p_end}

{phang}
{opt wspan} specifies the number of weeks before and after the corresponding
week of {it:yeval} included in the estimation. For instance, if W is the week
being evaluated and {it:wspan}=2, weeks W-2 through W+2 are used. If
{it:yspan}=5 and {it:wspan}=2, then 25 observations contribute to week W
(five weeks for each of five years). If {cmd:channel} encounters a convergence
problem for a given week when using {cmd:met(robmean)}, {cmd:met(regmean)}, or
{cmd:met(bsmedian)}, the program automatically increases {it:wspan} by 1 week
for that week only and continues. A note is displayed when running
{cmd:channel} directly, but it is not shown when {cmd:channel} is invoked
internally by {cmd:ppvalue}.{p_end}

{phang}
{opt met(regmean)} calculates predicted means and 95% confidence intervals
using a null linear regression model (see {helpb regress}).{p_end}

{phang}
{opt met(robmean)} calculates predicted means and 95% confidence intervals
using robust regression (see {helpb rreg}).{p_end}

{phang}
{opt met(bsmedian)} estimates the median using bootstrap resampling (see
{helpb bootstrap}) and constructs confidence intervals from the bootstrap
distribution.{p_end}

{phang}
{opt jitter} adds a small random perturbation to the case variable before
estimation in {cmd:bsmedian} and {cmd:robmean}. The jitter is drawn from
N(1,0.5) and is used only for internal computations; the original case counts
are preserved for reporting and plotting.{p_end}

{phang}
{opt seed(#)} specifies the random-number seed used by procedures involving
random-number generation, including jitter and bootstrap resampling. The
default is {cmd:seed(313151)}, which ensures reproducibility when a seed is
not explicitly specified.{p_end}

{phang}
{opt reps(#)} specifies the number of bootstrap replications used by
{cmd:met(bsmedian)} to estimate the bootstrap confidence interval. The default
is {cmd:reps(1000)}.{p_end}

{title:Examples for channel}

{pstd}
Detect possible outbreaks of dengue in the year 2007, using the previous five
years as reference and two adjacent weeks on each side of each calendar week,
using the regression-mean method:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean)}

{pstd}
Use robust regression and plot the endemic channel on a logarithmic scale:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(robmean) logscale}

{pstd}
Use linear regression, restrict the y-axis to a specific range (linear scale),
and saves the output file:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean) ysrange(0 80) fsave(example_save_file)}

{pstd}
Use linear regression, restrict the y-axis on a log scale, and saves the graph:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean) logscale ysrange(1 100) grsave(example_save_graph)}

{pstd}
Use robust mean and add a custom graph title:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(robmean) grtitle("Endemic channel for dengue, 2007")}

{pstd}
Use the bootstrap-median method with a custom smoother and add jitter to
handle low-variability periods:

{pmore}
{cmd:. epidem channel dengue year week, yeval(2007) yspan(5) wspan(2) met(bsmedian) smoother(3RSSH) jitter seed(313151)}

{hline}
{marker rregmm}{...}
{title:Subcommand rregmm}

{title:Syntax for rregmm}

{p 4 12 1}
{cmd:epidem} {cmd:rregmm} {it:casevar} {it:yearvar} {it:weekvar} {break}
[{cmd:,} {it:options} {cmd:yeval}{cmd:(}{it:#}{cmd:)}
{cmd:ryspan}{cmd:(}{it:#}{cmd:)} {cmd:seed}{cmd:(}{it:#}{cmd:)}
{cmd:jitter} {cmd:logscale} {cmd:ysrange}{cmd:(}{it:# #}{cmd:)}
{cmd:yvalues}{cmd:(}{it:numlist}{cmd:)} {cmd:grtitle}{cmd:(}{it:string}{cmd:)}
{cmd:baselineopts}{cmd:(}{it:marker_options}{cmd:)}
{cmd:alarmopts}{cmd:(}{it:marker_options}{cmd:)}
{cmd:alertopts}{cmd:(}{it:marker_options}{cmd:)}
{cmd:epidemicopts}{cmd:(}{it:marker_options}{cmd:)}
{cmd:grsave}{cmd:(}{it:string}{cmd:)} {cmd:fsave}{cmd:(}{it:string}{cmd:)} ]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt yeval}}Evaluation year.{p_end}
{synopt :{opt ryspan}}Number of preceding years used to fit robust MM regressions and identify unusual weeks.{p_end}
{synopt :{opt seed}}Seed to obtain reproducible results (see {cmd:seed()}).{p_end}
{synopt :{opt jitter}}Adds random noise to the case variable before smoothing and robust regression.{p_end}
{synopt :{opt logscale}}Graphs the epidemic curve using a logarithmic y-axis.{p_end}
{synopt :{opt ysrange(# #)}}Forces the y-axis range (positive values required with {opt logscale}).{p_end}
{synopt :{opt yvalues(numlist)}}Specifies y-axis tick marks.{p_end}
{synopt :{opt grtitle(string)}}Custom graph title.{p_end}
{synopt :{opt baselineopts(marker_options)}}Specifies marker options for Baseline weeks.{p_end}
{synopt :{opt alarmopts(marker_options)}}Specifies marker options for Alarm weeks.{p_end}
{synopt :{opt alertopts(marker_options)}}Specifies marker options for Alert weeks.{p_end}
{synopt :{opt epidemicopts(marker_options)}}Specifies marker options for Epidemic weeks.{p_end}
{synopt :{opt grsave(filename)}}Saves the epidemic-curve graph as a Stata {cmd:.gph} file.{p_end}
{synopt :{opt fsave(filename)}}Saves the output dataset (evaluation-year observations only).{p_end}
{synoptline}

{title:Graph options for rregmm}

{pstd}
By default, the appearance of the markers for the four week types is
determined by the active Stata graph scheme. The following options allow users
to override the scheme for individual week types.

{phang}
{opt baselineopts(marker_options)} specifies marker options for Baseline weeks.{p_end}

{phang}
{opt alarmopts(marker_options)} specifies marker options for Alarm weeks.{p_end}

{phang}
{opt alertopts(marker_options)} specifies marker options for Alert weeks.{p_end}

{phang}
{opt epidemicopts(marker_options)} specifies marker options for Epidemic
weeks. For example, {cmd:epidemicopts(mcolor(black))} displays Epidemic weeks
in black while leaving the appearance of the other week types
unchanged.{p_end}

{title:Description for rregmm}

{pstd}
{hi:epidem rregmm} is a wrapper for {helpb robreg} (Jann 2021), which fits MM
regression models (Yohai 1987) by combining an initial high-breakdown S
estimator with a subsequent redescending M estimator. The program calls {helpb robreg} with the {cmd:mm} option to fit a robust regression of weekly case
counts
using data from the {it:ryspan} years preceding the evaluation year
{it:yeval}. The model includes only an intercept term and is estimated by
minimizing
a ρ-function of the residuals.

{pstd}
The resulting robust standardized residuals (SR) quantify each week’s
departure from the expected number of cases based on past data. {hi:epidem rregmm} uses
these SR values to classify weeks in the evaluation year. Specifically,
{it:Baseline} weeks are defined as SR ≤ -2.5; {it:Alarm} weeks as -2.5 < SR ≤
mean(SR);
{it:Alert} weeks as mean(SR) < SR < 2.5; and {it:Epidemic} weeks as SR ≥ 2.5.
Although {hi:rregmm} uses data from previous years to estimate the expected
number of cases and residual variability, unusual weeks are defined using
standardized residuals from a regression model rather than by comparison with
the
empirical percentiles of historical weekly counts.

{pstd}
{hi:epidem rregmm} saves its results in a dataset that can be used to draw the
epidemic curve for {it:yeval} and to conduct further analyses.

{pstd}
The output dataset includes the following variables:

{synoptset 30 tabbed}{...}
{synopthdr:Variable:Description}
{synoptline}
{synopt :{hi:ytested}}Evaluation year (renamed from {it:yearvar}){p_end}
{synopt :{hi:week}}Week variable (from the original data){p_end}
{synopt :{hi:{it:casevar}}}Variable corresponding to the disease of interest{p_end}
{synopt :{hi:date}}Stata weekly date created with {cmd:yw(year, week)}{p_end}
{synopt :{hi:log_{it:casevar}}}Log of (possibly jittered) case counts (with offset for zeros){p_end}
{synopt :{hi:{it:casevar}sm}}Smoothed case counts{p_end}
{synopt :{hi:log{it:casevar}sm}}Log of smoothed number of cases of {it:casevar}{p_end}
{synopt :{hi:{it:casevar}sm_no_{it:yeval}}}Smoothed case count in non-outlier weeks{p_end}
{synopt :{hi:residual{it:yeval}}}Robust standardized residuals for {it:yeval}{p_end}
{synopt :{hi:outlier_{it:yeval}}}Outlier indicator for {it:yeval}{p_end}
{synoptline}

{title:Examples for rregmm}

{pstd}
Draw the epidemic curve for 2007 using {cmd:rregmm} and the previous
{cmd:ryspan} years as reference:

{pmore}
{cmd:. epidem rregmm dengue year week, yeval(2007) ryspan(10) seed(1234)}

{pstd}
Save the epidemic-curve graph and the output dataset:

{pmore}
{cmd:. epidem rregmm dengue year week, yeval(2007) ryspan(10) seed(1234) grsave(grtest_delete) fsave(ftest_delete)}

{hline}
{marker ppvalue}{...}
{title:Subcommand ppvalue}

{title:Syntax for ppvalue}

{p 4 12 1}
{cmd:epidem} {cmd:ppvalue} {it:casevar} {it:yearvar} {it:weekvar}
[{cmd:,} {it:options}]

{pstd}
The varlist must contain three numeric variables:
{it:casevar} (weekly case counts), {it:yearvar} (year), and {it:weekvar} (week: 1–52).

{title:Options for ppvalue}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt yeval(#)}}Evaluation year (required).{p_end}
{synopt :{opt yspan(#)}}Number of reference years used (reference years are {it:yeval-yspan} through {it:yeval-1}).{p_end}
{synopt :{opt wspan(#)}}Defines the number of weeks around the index week ({it:w}) used to estimate the week-specific prevalence of progressive growth weeks (PGW, see below) in the reference years: {it:w} {it:±} {cmd:wspan}.{p_end}
{synopt :{opt met(method)}}Method ({cmd:regmean}, {cmd:bsmedian}, or {cmd:robmean})) used to define the type of week ({it:Baseline/Alarm/Alert/Epidemic}). Computation time may increase when using bsmedian or robmean, particularly with a large number of reference windows ({cmd:wspan(#)}).{p_end}
{synopt :{opt iweek(#)}}Week of interest -index week (1–52). If the data include week 53 (e.g., ISO weeks), {cmd:ppvalue} ignores observations from week 53. Users should recode or collapse week 53 before running the program. If {opt iweek(#)} is not specified, {cmd:ppvalue} uses week 52.{p_end}
{synopt :{opt draws(#)}}Number of Monte Carlo draws for Bayesian estimates (median and 95% credible interval). The default is {opt draws}(50,000).{p_end}
{synopt :{opt seprior(# #)}}Prior parameters for sensitivity {it:Se}: Beta(a b), where a = number of pseudo–true positives and b = number of pseudo-false negatives with respect to PGW (see below).{p_end}
{synopt :{opt spprior(# #)}}Prior parameters for specificity {it:Sp}: Beta(a b), where a = number of pseudo–true negatives and b = number of pseudo-false positives with respect to PGW (see below).{p_end}
{synopt :{opt prevprior(# #)}}Prior parameters for prevalence {it:Prev}: Beta(a b), where a = pseudo–PGW-positive weeks and b = pseudo–PGW-negative weeks.{p_end}
{synopt :{opt seed(#)}}Optional for reproducible simulation-based summaries (see {helpb seed}).{p_end}
{synopt :{opt fsave(filename)}}Save results (behavior depends on implementation).{p_end}
{synopt :{opt dograph}}Displays the endemic channel graph (see {helpb graph}) for each reference year based on the selected method ({cmd:regmean}, {cmd:bsmedian}, or {cmd:robmean}).{p_end}
{synopt :{opt nograph}}Prevents the endemic channel graphs and output messages from being shown.This is the default.{p_end}
{synoptline}

{title:Description for ppvalue}

{pstd}
{cmd:ppvalue} estimates, for a single epidemiologic week specified in {cmd:iweek()}, the probability that reported cases {it:will progressively increase}
over the following two weeks. A week {it:w} is classified as a progressive
growth week (PGW) if the number of reported cases satisfies Yw <Yw+1 <Yw+2;
that is, if cases increase monotonically over the following two weeks. PGW
status is determined only for the reference years defined by {cmd:yspan()}.

{pstd}
{cmd:ppvalue} also calls {cmd:channel} with the selected method
({cmd:regmean}, {cmd:robmean}, or {cmd:bsmedian}) to classify each
reference week according to three cumulative historical-limit thresholds:
Alarm or higher, Alert or higher, and Epidemic. Each threshold is treated
as a diagnostic test, and its sensitivity ({it:Se}) and specificity ({it:Sp})
for identifying PGWs are estimated using PGW status as the reference
standard. For the evaluation week specified in {cmd:iweek()}, {cmd:ppvalue}
applies Bayes' theorem to combine the week-specific prior prevalence of
PGWs with the sensitivity and specificity corresponding to the observed
threshold, thereby estimating the posterior probability that the selected
week is a PGW.

{pstd}
The procedure consists of three steps:

{phang}
1) {cmd:Week-specific prevalence of progressive growth weeks (PGWs)}.
Using the reference years ({cmd:yeval()} − {cmd:yspan()} through {cmd:yeval()}
− 1) and the week window defined by {cmd:wspan()}, {cmd:ppvalue} estimates
the historical prevalence of PGWs, {it:Prev(w)}, for each epidemiologic week.
{it:Prev(w)} represents the prevalence of PGWs around epidemiologic
week {it:w}; it does not represent the prevalence of Baseline, Alarm, Alert,
or Epidemic weeks.

{phang}
2) {cmd:Method-specific sensitivity (Se) and specificity (Sp)}.
The selected {cmd:channel} method is applied to the reference years to create
three cumulative threshold indicators: Alarm or higher, Alert or higher, and
Epidemic. These thresholds are evaluated as diagnostic tests for identifying
PGWs, and their {it:Se} and {it:Sp} are estimated from the reference years.
Because the historical limits depend on the selected method, the resulting
estimates of {it:Se} and {it:Sp} are method-specific.

{phang}
3) {cmd:Bayesian updating}.
For the evaluation year, {cmd:ppvalue} determines the threshold classification
of the week specified in {cmd:iweek()}. The week-specific prior probability
of a PGW is converted to prior odds and updated using the likelihood ratio
corresponding to the observed threshold. Beta priors are assigned to
{it:Prev(w)},
{it:Se}, and {it:Sp}, with prior parameters specified by {cmd:prevprior()},
{cmd:seprior()}, and {cmd:spprior()}. By default, ppvalue uses a Jeffreys
prior,
Beta(0.5,0.5), for all three parameters. Posterior summaries are obtained by
Monte Carlo simulation ({cmd:draws()}); medians and central 95% credible
intervals are reported. Use {cmd:seed()} to obtain reproducible results.

{pstd}
{bf:Output and saved results.}
If {cmd:fsave()} is specified, {cmd:ppvalue} saves a dataset containing, for
each week in {cmd:yeval()}, the observed cases, smoothed endemic channel
parameters, endemic zone classification, threshold classification, pooled
reference-year counts (true positives (TP), false positives (FP), true
negatives (TN), false negatives (FN)), week-specific prevalence components (A
= PGW-positive weeks, B = PGW-negative weeks), and posterior summaries
for {it:Se}, {it:Sp}, {it:Prev}, and PPV.

{pstd}
{bf:Interpretation.}
The PPV for {cmd:iweek()} is the probability that the selected week is a PGW;
that is, that reported cases will progressively increase over the following
two weeks. It does not necessarily indicate movement to a higher endemic zone.

{pstd}
{bf:Data requirements.}
ppvalue expects one observation per epidemiologic week in the analysis series.
The variables specified in yearvar and weekvar must uniquely identify
observations in the dataset. If the dataset contains multiple series (for
example, repeated year-week combinations by region, sex, or age group),
either subset the data to a single series before running ppvalue, or run the
command separately for each group (e.g., by region:), ensuring that
observations are unique within each series.

{pstd}
{bf:The output dataset includes the following variables:}

{synoptset 26 tabbed}{...}
{synopthdr:Variable:Description}
{synoptline}
{synopt :{hi:ytested}}Evaluation year (renamed from yearvar){p_end}
{synopt :{hi:week}}Epidemiologic week{p_end}
{synopt :{hi:obscases}}Observed number of cases{p_end}
{synopt :{hi:meansmooth}}Smoothed expected mean of cases{p_end}
{synopt :{hi:lbsmooth}}Lower 95% bound of the smoothed expected mean{p_end}
{synopt :{hi:ubsmooth}}Upper 95% bound of the smoothed expected mean{p_end}
{synopt :{hi:wtype}}Endemic zone classification (0 Baseline, 1 Alarm, 2 Alert, 3 Epidemic){p_end}
{synopt :{hi:thresmet}}Threshold met (0 No, 1 Yes){p_end}
{synopt :{hi:threshold}}Threshold classification (< lower bound, ≥ lower bound, ≥ mean, ≥ upper bound){p_end}
{synopt :{hi:truepos}}Number of reference-year weeks with PGW=1 and thresmet=1{p_end}
{synopt :{hi:falseneg}}Number of reference-year weeks with PGW=1 and thresmet=0{p_end}
{synopt :{hi:trueneg}}Number of reference-year weeks with PGW=0 and thresmet=0{p_end}
{synopt :{hi:falsepos}}Number of reference-year weeks with PGW=0 and thresmet=1{p_end}
{synopt :{hi:prev}}Observed prevalence of PGWs in the reference years{p_end}
{synopt :{hi:pgwpos}}Number of PGW-positive weeks in the reference window{p_end}
{synopt :{hi:pgwneg}}Number of PGW-negative weeks in the reference window{p_end}
{synopt :{hi:se_med}}Posterior median sensitivity{p_end}
{synopt :{hi:se_lo}}Posterior 2.5th percentile of sensitivity{p_end}
{synopt :{hi:se_hi}}Posterior 97.5th percentile of sensitivity{p_end}
{synopt :{hi:sp_med}}Posterior median specificity{p_end}
{synopt :{hi:sp_lo}}Posterior 2.5th percentile of specificity{p_end}
{synopt :{hi:sp_hi}}Posterior 97.5th percentile of specificity{p_end}
{synopt :{hi:prev_med}}Posterior median prevalence of PGWs{p_end}
{synopt :{hi:prev_lo}}Posterior 2.5th percentile of prevalence{p_end}
{synopt :{hi:prev_hi}}Posterior 97.5th percentile of prevalence{p_end}
{synopt :{hi:ppv_med}}Posterior median probability that the week is a PGW{p_end}
{synopt :{hi:ppv_lo}}Posterior 2.5th percentile of the probability{p_end}
{synopt :{hi:ppv_hi}}Posterior 97.5th percentile of the probability{p_end}
{synoptline}

{pstd}
Note: threshold identifies the historical-limit threshold applicable to the
week, whereas thresmet indicates whether the observed number of cases
meets or exceeds that threshold.

{title:Examples for ppvalue}

{pstd}
Compute the probability of a progressive increase in the number of cases after
week 40 of 2007 using the regression-mean endemic-channel method:

{pmore}
{cmd:. epidem ppvalue dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean) iweek(40)}

{pstd}
Compute the same quantity using week classification from {cmd:robmean} and
saves the output file:

{pmore}
{cmd:. epidem ppvalue dengue year week, yeval(2007) yspan(5) wspan(2) met(robmean) iweek(40) fsave(filename)}

{pstd}
Compute the same quantity using week classification from {cmd:bsmedian}, saves
the output file, and graph the endemic channel:

{pmore}
{cmd:. epidem ppvalue dengue year week, yeval(2007) yspan(5) wspan(2) met(bsmedian) iweek(40)} dograph

{title:Stored results for ppvalue}

{p 4 4 2}
{cmd:ppvalue} returns results in {cmd:r()} (exact names depend on
implementation). Typical returns include:
{cmd:r(Se)} {cmd:r(Sp)} {cmd:r(Prev_i)} {cmd:r(PPV)} {cmd:r(iweek)} and
zone/test indicators (if implemented).

{marker references}{...}
{title:References}
{pstd}
Stroup DF, Williamson GD, Herndon JL, Karon JM. Detection of aberrations in
the occurrence of notifiable
diseases surveillance data. {it:"Stat Med"}. 1989;8(3):323-9.

{pstd}
Yohai, V.J. 1987. High Breakdown-Point and High Efficiency Robust Estimates
for Regression. {it:"The Annals of Statistics"} 15: 642-656.

{pstd}
Jann, B. (2021). robreg: Stata module providing robust regression estimators.
Available from
http://ideas.repec.org/c/boc/bocode/s458931.html
.

{marker author}{...}
{title:Author}

{pstd}
Leonelo Bautista, University of Wisconsin at Madison,{break}
School of Medicine and Public Health, USA{break}
{browse lebautista@wisc.edu}{break}

{marker alsosee}{...}
{title:Also see}

{pstd}
Help: {helpb epidem}, {helpb channel}, {helpb rregmm}, {helpb ppvalue}, {helpb robreg}, {helpb rreg}, {helpb mmregress}, {helpb tsset}, {helpb tssmooth}
{p_end}
