{smcl}
{* *! version 1.1.0  13oct2026}{...}
{vieweralsosee "[R] estimates" "help estimates"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtexport##syntax"}{...}
{viewerjumpto "Description" "tvtexport##description"}{...}
{viewerjumpto "The four panels" "tvtexport##panels"}{...}
{viewerjumpto "Options" "tvtexport##options"}{...}
{viewerjumpto "Examples" "tvtexport##examples"}{...}
{viewerjumpto "Limitations" "tvtexport##limits"}{...}
{viewerjumpto "Author" "tvtexport##author"}{...}
{title:Title}

{phang}
{bf:tvtexport} {hline 2} Publication tables for TVTHRESH estimates


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtexport} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt est(namelist)}}the stored estimates to tabulate, one column
each; the default is whatever is in memory{p_end}
{synopt :{opt format(string)}}{bf:latex}, {bf:markdown}, {bf:rtf} or
{bf:csv}; the default is read from the file extension{p_end}
{synopt :{opt t:itle(string)}}table title{p_end}
{synopt :{opt note(string)}}replaces the default note{p_end}
{synopt :{opt stars(numlist)}}three significance levels, largest first;
default {cmd:stars(0.10 0.05 0.01)}{p_end}
{synopt :{opt nocoefs}}omit panel A{p_end}
{synopt :{opt nothr:eshold}}omit panel B{p_end}
{synopt :{opt notests}}omit panel C{p_end}
{synopt :{opt nodiag:nostics}}omit panel D, the fit statistics{p_end}
{synopt :{opt replace}}overwrite the file{p_end}
{synoptline}
{p 4 6 2}
With no {cmd:using}, the table is printed to the Results window as
Markdown, which is the quickest way to see what it will contain.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtexport} writes a publication table from one or more TVTHRESH
estimates.

{pstd}
It is not a general-purpose table writer and does not try to be one;
{cmd:estout} and {cmd:esttab} do that job better. What it knows that they
do not is {bf:where each command in this library puts its threshold}. A
general writer tabulates {cmd:e(b)} and stops, which for a threshold model
leaves out the threshold, the regime sizes and the specification tests
{hline 2} that is, everything the paper is actually about. This command
reads them out of {cmd:e()} per command and lays them out in panels.


{marker panels}{...}
{title:The four panels}

{p2colset 8 16 18 2}{...}
{p2col :{bf:A}}{bf:Coefficients}, grouped by equation, with standard errors
beneath in parentheses and significance stars{p_end}
{p2col :{bf:B}}{bf:The threshold}: the threshold parameters themselves, the
constant-threshold comparison where the command reports one, the estimated
memory and percentile for the rolling-quantile commands, the bandwidth
where there is one, and the regime sizes{p_end}
{p2col :{bf:C}}{bf:Tests}, with p-values in brackets beneath. Each command's
own tests appear under their own names {hline 2} F1 and F2, F1C and F1T,
the score test, the Wald test{p_end}
{p2col :{bf:D}}{bf:Fit}: the sums of squares for the threshold model and for
the models it is being compared against, the number of bootstrap or
posterior draws, and the sample size{p_end}
{p2colreset}{...}

{pstd}
A row appears only if at least one column has something to put in it, so a
table of two commands that report different things does not fill with
blanks.

{pstd}
{bf:Reporting the number of draws is not decoration.} A bootstrap p-value
from 199 replications and one from 2000 are not the same evidence, and a
reader cannot tell them apart unless the table says. Panel D says.


{marker options}{...}
{title:Options}

{phang}
{opt est(namelist)} names the stored estimates, in column order. Store them
with {helpb estimates store} as you go. Without it the command uses the
results in memory, which gives a one-column table.

{phang}
{opt format(string)} picks the output. {bf:latex} writes a {cmd:booktabs}
{cmd:table} environment, so {cmd:\usepackage{c -(}booktabs{c )-}} is needed
in the preamble; underscores in variable names are escaped. {bf:markdown}
writes a pipe table that pastes into anything. {bf:rtf} opens in Word.
{bf:csv} is for reading back into a spreadsheet. If you give a filename and
no format, the extension decides: {bf:.tex}, {bf:.md}, {bf:.rtf},
{bf:.csv}.

{phang}
{opt stars(numlist)} sets the three levels, {bf:largest first}. The default
is the usual 0.10 / 0.05 / 0.01. The order is enforced, not just asked
for: the three cutoffs are applied in sequence, so an ascending list would
award three stars to a result significant only at the loosest level, and
the table would carry inverted stars with nothing on its face to show it.
An ascending or out-of-range list is refused.

{phang}
The four {opt no*} options drop panels. {opt nocoefs} with the others left
in gives the compact specification-and-tests table that often belongs in
the body of a paper, with the coefficients in an appendix.


{marker examples}{...}
{title:Examples}

{pstd}Look at it on screen before writing anything{p_end}
{phang2}{cmd:. tvtcoint ir infl, threshvar(ipi) zvars(dinfl) reps(500)}{p_end}
{phang2}{cmd:. tvtexport}{p_end}

{pstd}Three specifications side by side, to LaTeX{p_end}
{phang2}{cmd:. tvtboundary y x w, threshvar(q) zvars(z) npi(4000)}{p_end}
{phang2}{cmd:. estimates store boundary}{p_end}
{phang2}{cmd:. tvtindex y x w, threshvar(q)}{p_end}
{phang2}{cmd:. estimates store smoothed}{p_end}
{phang2}{cmd:. tvtcotar y, delay(1) memory(60) reps(500)}{p_end}
{phang2}{cmd:. estimates store cotar}{p_end}
{phang2}{cmd:. tvtexport using table2.tex, est(boundary smoothed cotar) ///}{p_end}
{phang2}{cmd:      title("Threshold specifications") replace}{p_end}

{pstd}The compact table for the body of the paper, coefficients omitted{p_end}
{phang2}{cmd:. tvtexport using table1.tex, est(boundary smoothed cotar) nocoefs replace}{p_end}

{pstd}Into Word{p_end}
{phang2}{cmd:. tvtexport using table2.rtf, est(boundary smoothed) replace}{p_end}


{marker limits}{...}
{title:Limitations}

{pstd}
{bf:Only the estimators, not the two test commands.} {helpb tvthomog} and
{helpb tvtlr} are {cmd:r}-class: they report a test, not a fitted model, so
there is nothing to {helpb estimates store} and nothing for this command to
read. Report them in the text, or in their own small table built by hand
from {cmd:r()}.

{pstd}
{bf:One set of estimates per column.} There is no facility for stacking
panels of several dependent variables; run the command once per table.

{pstd}
{bf:A threshold that moves gets a row per variable.} {helpb tvtcoint} and
{helpb tvtcovdep} both make the threshold a linear function of observed
covariates, so their {cmd:e(gamma1)} is a vector rather than a scalar.
Panel B writes it out as one row per variable, labelled
{bf:gamma_1 on} {it:zname}, and lines the rows up by name across columns so
two specifications with different {opt zvars()} lists can sit side by side.
Where a command {it:selected} its threshold variables, the ones it dropped
are left blank rather than printed as an exact zero, since an exclusion is
not an estimate.

{pstd}
{bf:A command that reports no standard errors gets none here either.}
{helpb tvtcovdep} posts a zero {cmd:e(V)} deliberately, because its
coefficients follow a selection and any standard error would ignore that.
Those cells are left blank and the table's footnote says so, rather than
printing {cmd:(0.0000)}.

{pstd}
{bf:The LaTeX output assumes {cmd:booktabs}} and writes
{cmd:\toprule}, {cmd:\midrule} and {cmd:\bottomrule}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
