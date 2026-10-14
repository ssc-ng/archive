{smcl}
{* *! version 0.9.2  2026  Juan Marcelo Gutierrez Miranda | TodoEconometria}{...}
{vieweralsosee "table" "help table"}{...}
{vieweralsosee "collect" "help collect"}{...}
{vieweralsosee "graph bar" "help graph bar"}{...}
{viewerjumpto "Syntax" "cruceandino##syntax"}{...}
{viewerjumpto "Description" "cruceandino##description"}{...}
{viewerjumpto "Options" "cruceandino##options"}{...}
{viewerjumpto "Examples" "cruceandino##examples"}{...}
{viewerjumpto "Stored results" "cruceandino##results"}{...}
{viewerjumpto "Working with R" "cruceandino##r"}{...}
{viewerjumpto "Author" "cruceandino##author"}{...}
{title:Title}

{phang}
{bf:cruceandino} {hline 2} Multiway cross of an outcome by 1-3 categoricals:
a coherent table ({helpb collect}) and figure from a single command.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cruceandino}
{it:outcome} {it:factor1} [{it:factor2} [{it:factor3}]]
{ifin}
{weight}
{cmd:,}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt by(varname)}}outer grouping: the leftmost block of the table and the figure panels{p_end}
{synopt:{opt stat:istic(name)}}statistic to tabulate/plot (default {cmd:mean}){p_end}
{synopt:{opt pct}}scale the outcome to percent (prevalence for a 0/1 variable){p_end}
{synopt:{opt fr:eq}}add the frequency to the {helpb collect} table left in memory{p_end}
{synopt:{opt li:ne}}line (series) plot instead of bars; x = {it:factor1}{p_end}
{synopt:{opt heat:map}}heatmap of the outcome over {it:factor1} (x) by {it:factor2} (y); class-binned colour, scales to hundreds of cells{p_end}
{synopt:{opt comp:osition}}% of the (sub)sample per cell (as {cmd:catplot, percent}); no outcome{p_end}
{synopt:{opt pan:el}}small multiples: one mini-panel per category; x = {it:factor1}{p_end}
{synopt:{opt dual}}two margins of an ordinal outcome (0=none): % consuming (bars) + frequency among consumers (line, second axis){p_end}
{synopt:{opt sort}}order the bars, and the table, by value (descending){p_end}
{synopt:{opt nby}}in the table, report the N split by the {opt by()} group (one N row per group) instead of a single pooled total{p_end}
{synopt:{opt hbar}}horizontal bars (automatic with >12 categories or long labels){p_end}

{syntab:Output}
{synopt:{opt ti:tle(string)}}title of the figure and of the table; built from the measure if omitted{p_end}
{synopt:{opt note(string)}}footnote of the figure and of the table (e.g. the source){p_end}
{synopt:{opt sav:ing(file)}}export the table ({cmd:.md}, {cmd:.docx}, {cmd:.html}, {cmd:.tex}, {cmd:.xlsx}){p_end}
{synopt:{opt gra:ph(file.png)}}save the figure (PNG, 2200 px wide){p_end}
{synopt:{opt for:mat(%fmt)}}numeric format (default {cmd:%6.2f}; sums and counts {cmd:%12.0fc}){p_end}
{synopt:{opt lang(en|es)}}language of the texts the command writes (axis and legend titles); default {cmd:en}{p_end}
{synopt:{opt sch:eme(name)}}graph scheme (default: the user's; {cmd:s1color} is clean){p_end}
{synopt:{opt col:or(colorstyle)}}bar/line colour (default a legible green){p_end}
{synopt:{opt gr:opts(options)}}pass options through to the inner {helpb twoway}/{helpb graph bar} (escape hatch){p_end}
{synopt:{opt nog:raph}}suppress the figure{p_end}
{synoptline}
{p 4 6 2}
{cmd:fweight}, {cmd:aweight} and {cmd:pweight} are allowed; see {helpb weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cruceandino} summarizes an {it:outcome} variable (binary or continuous) cross-classified
by 1 to 3 {it:categorical} variables and, optionally, a {opt by()} variable. In one step it
produces (i) a {bf:table} that reads as a tree (groups merged on the left, the categories of
{it:factor1} in columns, one N row at the bottom), exported to Markdown, HTML, LaTeX, Excel or
Word, (ii) a coherent {bf:figure} in one of seven modes (grouped bars, horizontal bars, lines,
heatmap, composition, small multiples, dual margins), and (iii) the figures of the table as a
matrix, {cmd:r(table)}. Sample, weights, labels and percentages are the same in all three.
The {helpb table}/{helpb collect} table is also left in memory.

{pstd}
It is aimed at household-survey consumption studies (e.g. coca, alcohol, tobacco), where one
crosses prevalences by income, ethnicity, education, area, or time. Requires {bf:Stata 17 or
later}.


{marker options}{...}
{title:Options}

{phang}
{opt by(varname)} numeric variable for an outer grouping: the leftmost block of the exported
table and the panels of the figure. It may not also be one of the factors.

{phang}
{opt statistic(name)} statistic to compute: {cmd:mean} (default), {cmd:median}, {cmd:sum},
{cmd:count}, {cmd:sd}, {cmd:p90}, or any other statistic of {helpb collapse}.

{phang}
{opt pct} multiplies the outcome by 100; with a 0/1 variable this gives the {bf:percentage} with the
outcome, and the axis is titled {it:% <variable label>} (for example {it:% Union worker}).

{phang}
{opt freq} adds the frequency to the {helpb collect} table left in memory. The exported table
always carries the N of each column in its last row.

{phang}
{opt line} draws a {bf:line} plot ({helpb twoway} connected) instead of bars. The X axis is
{it:factor1} (typically the {bf:year}); one line is drawn per level of {it:factor2} (or of
{opt by()} when there is no {it:factor2}); {it:factor3} and/or {opt by()} generate panels.
Useful for the evolution of a prevalence over time.

{phang}
{opt heatmap} draws a {bf:heatmap}: {it:factor1} on the X axis, {it:factor2} on the Y axis, each
cell coloured by the outcome. Colour is binned into {bf:6 classes} (one series per class, not one
plot per cell), so it {bf:scales to hundreds of cells} without hitting the {helpb twoway} layer
limit. In-cell numbers are printed only for a small grid (<=48 cells). Needs 2 factors.

{phang}
{opt composition} {bf:composition} mode: there is NO outcome, the whole {it:varlist} are
categoricals, and the {bf:percent of the (sub)sample} in each cell is shown. Reproduces
{cmd:catplot, percent}; best with an {cmd:if} (e.g. the composition of consumers: {cmd:... if coca==1}).

{phang}
{opt panel} {bf:small multiples} mode: a grid of mini line plots, one per category of {it:factor2}
(and {it:factor3}/{opt by()} if present), with {it:factor1} on the X axis (typically the {bf:year}).
It is the counterpart of R's {cmd:facet_wrap}; ideal for the evolution of X across many categories
(e.g. by department) without crowding every series on one axis. Needs 2 factors.

{phang}
{opt dual} {bf:dual-margin} mode (the double hurdle drawn): from an {bf:ordinal outcome} where
{bf:0 = none} (e.g. {cmd:freq_coca} 0-3), it decomposes and shows at once the {bf:extensive} margin
= {bf:% consuming} ({cmd:100*mean(outcome>0)}, bars, left axis) and the {bf:intensive} margin =
{bf:frequency among consumers} ({cmd:mean(outcome | outcome>0)}, line, right axis). {it:factor1} is
the X axis; {it:factor2}/{it:factor3}/{opt by()} generate panels. The intensive axis is fixed to
{cmd:[1, max]} (common across panels) so the reading is honest. The table carries the % consuming
and, among consumers, the % in each category of the outcome (they add up to 100), with the
category value labels as headers. Useful to see the {bf:dissociation of margins}: what raises
participation need not raise frequency.

{phang}
{opt sort} orders the bars by value (descending), for ranking-style reading. In the table it orders
the rows (one value column) or the columns (from the highest overall value to the lowest).

{phang}
{opt nby} splits the table's {bf:N row by the} {opt by()} {bf:group}: with {cmd:by(country)} it prints
one N row per country (e.g. "N (observations) {c 183} Bolivia", "{c 183} Peru") instead of a single
pooled column total. It only affects the table (every export format and the Results window); it needs
{opt by()} and is ignored without it. The default (a single total N row) is unchanged.

{phang}
{opt hbar} draws {bf:horizontal bars}. It is {bf:automatic} when the axis factor has more than 12
categories or long labels (so horizontal labels do not collide); {opt hbar} forces it even
with few. Category labels longer than 30 characters are wrapped on several lines.

{phang}
{opt title(string)} title of the figure and of the table; it should say what the figures are
(e.g. {it:% of union members by race}). If omitted, the table gets one built from the measure
and the variable labels, and the subsample of an {cmd:if} is printed under it.

{phang}
{opt note(string)} footnote of the figure and, in small type, of the table (for example, the data
source). None by default.

{phang}
{opt saving(file)} exports the table; the type is inferred from the extension ({cmd:.md},
{cmd:.docx}, {cmd:.html}, {cmd:.tex}, {cmd:.xlsx}). The table reads as a tree, left to right: the
groups on the left from the widest to the narrowest ({opt by()}, {it:factor3}, {it:factor2}; the
reverse of the figure), the categories of {it:factor1} as columns, and one row at the bottom with
the N behind each column. Outer groups are merged cells with vertical text in {cmd:.html},
{cmd:.tex} (needs {cmd:booktabs}, {cmd:multirow}, {cmd:graphicx}) and {cmd:.xlsx}; merged with
horizontal text in {cmd:.docx}; flat in {cmd:.md}. Only the outer group is written vertically, and in
{cmd:.tex} only when each of its blocks spans 4 rows or more. Other extensions stop with an
error. A plain two-way cross (one group, no {opt by()} nor {it:factor3}) with more than 12
columns, and more columns than rows, is turned to portrait: the long factor goes down. With
nested groups the tree is never turned. A factor holding years is shown as the plain number. The
{helpb collect} table is always left in memory, so {cmd:putdocx collect} and {cmd:putpdf collect} keep
working.

{phang}
{opt graph(file.png)} exports the figure as PNG (2200 px wide).

{phang}
{opt format(%fmt)} numeric format of the table/labels (default {cmd:%6.2f}; {cmd:%12.0fc} for
{cmd:sum} and {cmd:count}).

{phang}
{opt lang(en|es)} language of the texts {cmd:cruceandino} writes itself: axis titles
({it:Percent (%)} / {it:Porcentaje (%)} when the outcome has no short label), the {opt dual} legend and subtitle, and the statistic
names in the table. Variable and value labels are always the user's. Default {cmd:en}.

{phang}
{opt scheme(name)} Stata graph scheme. None is imposed by default (the user's is respected). For a
cleaner Stata 17 look: {cmd:set scheme s1color} or {opt scheme(s1color)}.

{phang}
{opt color(colorstyle)} colour of the bars (or of the single line). Default a legible green; accepts
any {helpb colorstyle} ({cmd:navy}, {cmd:"56 142 60"}, etc.).

{phang}
{opt gropts(options)} {bf:escape hatch}: passes any {helpb twoway} or {helpb graph bar} option
through to the inner graph, placed last so it {bf:wins} over the defaults. For the rare case the
defaults do not anticipate (e.g. {cmd:gropts(ylabel(0(10)70) ysize(8))}).

{phang}
{opt nograph} produces no figure (table only).


{marker examples}{...}
{title:Examples}

{pstd}The examples use {cmd:nlsw88}, shipped with Stata; {cmd:union} is 0/1.{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}

{pstd}Union membership (%) by race and college, table + bars:{p_end}
{phang2}{cmd:. cruceandino union race collgrad, pct title("Union membership") saving("c1.md") graph("c1.png")}{p_end}

{pstd}Same, split by region ({cmd:south}) in columns/panels:{p_end}
{phang2}{cmd:. cruceandino union race, by(south) pct title("Union membership")}{p_end}

{pstd}Prevalence by years of schooling and race (lines), with a source note:{p_end}
{phang2}{cmd:. cruceandino union grade race, line pct title("Union membership") note("Source: NLSW 1988")}{p_end}

{pstd}Heatmap of membership (%) by race and college:{p_end}
{phang2}{cmd:. cruceandino union race collgrad, heatmap pct title("Union membership")}{p_end}

{pstd}Composition of members by race and college (as catplot, percent):{p_end}
{phang2}{cmd:. cruceandino race collgrad if union==1, composition title("Composition of members")}{p_end}

{pstd}Bars ordered by value (ranking); with many categories it switches to horizontal:{p_end}
{phang2}{cmd:. cruceandino union occupation, pct sort}{p_end}

{pstd}Small multiples (evolution by category); x = {cmd:grade}, one panel per race:{p_end}
{phang2}{cmd:. cruceandino union grade race, panel pct title("Union membership by schooling")}{p_end}

{pstd}Dual margins of an ordinal (0=none): % with tenure + tenure among those who have it:{p_end}
{phang2}{cmd:. cruceandino tenure race, dual title("Margins of tenure")}{p_end}

{pstd}Escape hatch: force a custom {cmd:ylabel} via passthrough:{p_end}
{phang2}{cmd:. cruceandino union race, pct gropts(ylabel(0(10)50, angle(0)))}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cruceandino} stores in {cmd:r()}:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cruceandino}{p_end}
{synopt:{cmd:r(outcome)}}outcome variable{p_end}
{synopt:{cmd:r(factors)}}list of crossed factors{p_end}
{synopt:{cmd:r(by)}}{opt by()} variable{p_end}
{synopt:{cmd:r(statistic)}}statistic computed{p_end}
{synopt:{cmd:r(pct)}}1 if scaled to percent, 0 otherwise{p_end}
{synopt:{cmd:r(mode)}}figure type: {cmd:bars}, {cmd:line}, {cmd:heatmap}, {cmd:composition}, {cmd:panel} or {cmd:dual}{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}the figures of the table at full precision, one row per row of the table and
one column per column; nested rows are named {it:outer group}:{it:level}{p_end}
{synopt:{cmd:r(Ncol)}}observations behind each column (the N row of the table){p_end}

{pstd}
For example, the gap between two groups, or the table into Excel:{p_end}
{phang2}{cmd:. cruceandino union race married, pct nograph}{p_end}
{phang2}{cmd:. matrix list r(table), format(%9.2f)}{p_end}
{phang2}{cmd:. matrix T = r(table)}{p_end}
{phang2}{cmd:. display T[2,2] - T[1,2]}{p_end}
{phang2}{cmd:. putexcel set cross.xlsx, replace}{p_end}
{phang2}{cmd:. putexcel A1 = matrix(T), names}{p_end}


{marker r}{...}
{title:Working with R}

{pstd}
{cmd:cruceandino} does not need R, but data and results move between the two with standard
packages: R writes a labelled {cmd:.dta} with {cmd:haven}, Stata crosses it, and the table saved with
{cmd:saving(.xlsx)} goes back to R with {cmd:readxl}, at full precision. Value and variable labels
travel with the data. In R, add a wage quartile to {cmd:nlsw88}:{p_end}
{phang2}{cmd:url <- "https://www.stata-press.com/data/r17/nlsw88.dta"}{p_end}
{phang2}{cmd:d <- haven::read_dta(url)}{p_end}
{phang2}{cmd:q <- c("Q1 (lowest)" = 1, Q2 = 2, Q3 = 3, "Q4 (highest)" = 4)}{p_end}
{phang2}{cmd:d$wageq <- haven::labelled(dplyr::ntile(d$wage, 4), q)}{p_end}
{phang2}{cmd:attr(d$wageq, "label") <- "Wage quartile"}{p_end}
{phang2}{cmd:haven::write_dta(d, "nlsw88_r.dta")}{p_end}

{pstd}In Stata:{p_end}
{phang2}{cmd:. use nlsw88_r, clear}{p_end}
{phang2}{cmd:. cruceandino union wageq, by(race) pct saving("cross.xlsx")}{p_end}

{pstd}Back in R, the table as a data frame: row groups in the first column, one column per
category of the first factor, then the N row (and the note, if any):{p_end}
{phang2}{cmd:x <- readxl::read_excel("cross.xlsx", skip = 1)}{p_end}

{pstd}Recomputing the same percentages in R ({cmd:dplyr}: {cmd:group_by(race, wageq)},
{cmd:mean(union)}) gives the same figures, which is a quick check that nothing was lost on the way.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Juan Marcelo Gutierrez Miranda {hline 1} TodoEconometria, Madrid, Spain.{break}
The command was developed for a comparative study of coca-leaf consumption in the Andes
(Encuesta de Hogares of Bolivia, 2005-2025, and ENAHO of Peru, 2012-2025). Available from the SSC archive: type {stata ssc install cruceandino}.
Cite as: Gutierrez Miranda, J. M. (2026). {it:cruceandino: one-step multiway crosstabulation with a coherent table and figure}.
Statistical Software Components, Boston College Department of Economics.
