{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thkink" "help thkink"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thexport##syntax"}{...}
{viewerjumpto "Description" "thexport##description"}{...}
{viewerjumpto "Options" "thexport##options"}{...}
{viewerjumpto "What the footer carries" "thexport##footer"}{...}
{viewerjumpto "Remarks" "thexport##remarks"}{...}
{viewerjumpto "Stored results" "thexport##results"}{...}
{viewerjumpto "Examples" "thexport##examples"}{...}
{viewerjumpto "Author" "thexport##author"}{...}

{title:Title}

{phang}
{bf:thexport} {hline 2} Export a publication table from a THRESHKIT fit


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thexport} {cmd:using} {it:filename} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt form:at(type)}}{cmd:latex}, {cmd:markdown} or {cmd:csv}; the
default is taken from the file extension{p_end}
{synopt :{opt replace}}overwrite {it:filename} if it exists{p_end}
{synopt :{opt title(string)}}table caption{p_end}
{synopt :{opt dec:imals(#)}}decimals for coefficients and thresholds;
default {cmd:decimals(3)}{p_end}
{synopt :{opt l:evel(#)}}confidence level for the CSV interval columns;
default is {cmd:c(level)}{p_end}
{synopt :{opt note(string)}}one extra line appended to the footer{p_end}
{synopt :{opt nostars}}suppress significance stars and their legend{p_end}
{synopt :{opt nof:ooter}}suppress the footer {bf:(read the warning below)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:using} may be omitted, in which case the table is previewed in the
Results window instead of written to a file.

{pstd}
{cmd:thexport} may be used after
{helpb thregress}, {helpb thtar}, {helpb thkink}, {helpb thstar},
{helpb thmtar}, {helpb thqreg}, {helpb thqkink}, {helpb thivreg},
{helpb thtvar}, {helpb thtvecm}, {helpb thstvar} and
{helpb thunitroot}.


{marker description}{title:Description}

{pstd}
{cmd:thexport} writes the estimation results in memory as a table ready to
drop into a paper: a LaTeX {cmd:table} environment using {cmd:booktabs}
rules, a GitHub-flavoured Markdown table, or a machine-readable CSV.

{pstd}
Coefficients are grouped into panels by equation, so a two-regime fit prints
its regime-1 block, then its regime-2 block, then any regime-invariant
regressors, under their own subheadings. Each row carries the coefficient,
its standard error, the {it:z} statistic and the two-sided {it:p} value; the
CSV form adds the confidence-interval endpoints as separate columns.

{pstd}
The reason this command exists rather than leaving the job to a generic table
exporter is the {bf:footer}. A threshold model's table has to report things an
ordinary regression table does not, and a generic exporter will not know to
ask for them. See {it:{help thexport##footer:What the footer carries}}.


{marker options}{title:Options}

{phang}
{opt format(type)} selects {cmd:latex}, {cmd:markdown} or {cmd:csv}. When it
is not given the extension decides: {cmd:.tex} gives LaTeX, {cmd:.md} and
{cmd:.txt} give Markdown, {cmd:.csv} gives CSV, and anything else gives
LaTeX.

{phang}
{opt decimals(#)} sets the number of decimals for coefficients, standard
errors and thresholds, between 1 and 8. The {it:z} statistic always prints
with 2 and the {it:p} value with 3, because those conventions are near
universal and varying them makes tables harder to compare, not easier.

{phang}
{opt level(#)} sets the confidence level used for the {cmd:ci_low} and
{cmd:ci_high} columns of the CSV form. It does {bf:not} affect the interval
printed for the threshold in the footer: that comes from the fitting command
and was computed by whatever method that command used, which is almost never
a normal-approximation interval. See the remarks.

{phang}
{opt nostars} removes the {cmd:*}/{cmd:**}/{cmd:***} markers and their
legend. Many journals forbid them.

{phang}
{opt nofooter} suppresses the whole footer block. {bf:Think before using it.}
It removes the threshold, its confidence set, the regime sizes and the
no-threshold test, and a reader cannot tell from the remaining table that
any of them is absent. The command prints a warning when you use it. The
legitimate use is assembling a multi-model table whose notes you write by
hand; stripping the footer to make a table look tidier is not one.


{marker footer}{title:What the footer carries}

{pstd}
Each of these appears only when the fit actually stored it.

{phang2}
{bf:The threshold, and its confidence set.} For a single-threshold fit the
estimate is printed with the interval in {cmd:e(ci)} beside it, when the
fitting command computed one. For a multiple-threshold fit all thresholds in
{cmd:e(gammas)} are listed.

{phang2}
{bf:A warning when the confidence set is not an interval.} Inverting a
likelihood-ratio statistic for the threshold can produce a disconnected set
{hline 2} two or more separated regions of threshold values that the data
cannot distinguish. When the fitting command recorded that this happened
({cmd:e(ci_contig)} equal to zero), the footer says so and says that the
printed bracket is the convex hull. Reporting the hull of a disconnected set
as though it were an interval overstates what the data settled, and the
reader has no way to know.

{phang2}
{bf:The regime sizes, and N.} A regime holding 18 of 200 observations is a
regime whose slopes are estimated from 18 observations, and no coefficient in
that panel should be read without knowing that.

{phang2}
{bf:The no-threshold test with its bootstrap p-value}, the number of
replications, and the name of the statistic. A nominal {it:p} value for a
statistic that was maximised over a grid of candidate thresholds is not a
{it:p} value, so the bootstrap figure is the one reported.

{phang2}
{bf:The two standing caveats.} That the threshold has no standard error,
because its limit distribution is not normal; and that the slope inference
conditions on the estimated threshold. Both are properties of every threshold
model, not of a particular fit, which is why they are printed unconditionally.


{marker remarks}{title:Remarks}

{pstd}
{bf:The threshold's interval is not a normal-approximation interval, and
{cmd:level()} does not change it.} Whatever interval appears in the footer
was computed by the fitting command {hline 2} by inverting a likelihood-ratio
statistic, or by the grid bootstrap of
{helpb thregress postestimation##gridboot:estat gridboot} {hline 2} because
the threshold's limit distribution is not normal and a point estimate plus
1.96 standard errors would be meaningless for it. To change the level of
{it:that} interval, refit with the level you want.

{pstd}
{bf:The slope standard errors do condition on the estimated threshold.} They
treat the threshold as known at its estimate. For the jump case this is
asymptotically defensible, because the threshold converges fast enough that
its estimation error does not enter the slopes' first-order distribution; for
the kink case the threshold converges at a cube-root rate and the
approximation is weaker. Routes that do not condition this way are described
in the post-estimation help of each fitting command.

{pstd}
{bf:LaTeX requirements.} The output uses {cmd:\toprule}, {cmd:\midrule},
{cmd:\bottomrule} and {cmd:\addlinespace}, so the document needs
{cmd:\usepackage{c -(}booktabs{c )-}}. Underscores, hashes, ampersands and
percent signs in coefficient names are escaped, so names such as
{cmd:_cons} and factor-variable interactions compile as they stand.

{pstd}
{bf:The screen preview.} Without {cmd:using} the table is written to the
Results window. For Markdown and CSV that preview is exactly the file
content. For LaTeX, Stata's own output formatter may render some brace
groups differently from the file, so use the preview to check the numbers
and the file to check the markup.

{pstd}
{bf:Multi-model tables.} {cmd:thexport} writes one fit at a time. To put
several fits side by side, export each to CSV and combine them, which keeps
every model's own threshold, regime sizes and test with it {hline 2} the
information that is lost first when threshold models are stacked into a
single column-per-model table.


{marker results}{title:Stored results}

{pstd}
{cmd:thexport} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(k_coef)}}number of coefficients written{p_end}
{synopt:{cmd:r(n_eq)}}number of equation panels; 0 if the table is flat{p_end}
{synopt:{cmd:r(n_note)}}number of footer lines written{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(format)}}{cmd:latex}, {cmd:markdown} or {cmd:csv}{p_end}
{p2colreset}{...}

{pstd}
{cmd:thexport} does not modify {cmd:e()}, so the fit stays in memory and can
be exported again in another format.


{marker examples}{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse set} {it:...}{p_end}
{phang2}{cmd:. use threshkit_kink}{p_end}

{pstd}A cross-section threshold regression, exported to LaTeX{p_end}
{phang2}{cmd:. thregress y x, threshold(z) trim(0.15) reps(300)}{p_end}
{phang2}{cmd:. thexport using table1.tex, replace title("Threshold in z")}{p_end}

{pstd}The same fit as Markdown, for a README or an appendix{p_end}
{phang2}{cmd:. thexport using table1.md, replace}{p_end}

{pstd}Preview on screen before committing to a file{p_end}
{phang2}{cmd:. thexport, format(markdown)}{p_end}

{pstd}CSV, for assembling a multi-model table{p_end}
{phang2}{cmd:. thexport using m1.csv, replace level(90)}{p_end}

{pstd}A journal that forbids stars, with an added source line{p_end}
{phang2}{cmd:. thexport using table2.tex, replace nostars note("Quarterly data, 1960-2019.")}{p_end}

{pstd}After a SETAR, where the footer also carries the delay and the regime sizes{p_end}
{phang2}{cmd:. use threshkit_rates, clear}{p_end}
{phang2}{cmd:. thtar g3month, arlags(1 2) delay(1) trim(0.15) reps(300)}{p_end}
{phang2}{cmd:. thexport using setar.tex, replace decimals(4)}{p_end}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
