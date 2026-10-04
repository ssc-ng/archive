{smcl}
{* *! version 0.9  2026  Juan Marcelo Gutierrez Miranda | TodoEconometria}{...}
{vieweralsosee "table" "help table"}{...}
{vieweralsosee "collect" "help collect"}{...}
{vieweralsosee "graph bar" "help graph bar"}{...}
{viewerjumpto "Syntax" "cruceandino##syntax"}{...}
{viewerjumpto "Description" "cruceandino##description"}{...}
{viewerjumpto "Options" "cruceandino##options"}{...}
{viewerjumpto "Examples" "cruceandino##examples"}{...}
{viewerjumpto "Stored results" "cruceandino##results"}{...}
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
{synopt:{opt by(varname)}}variable that splits the table columns and the figure panels{p_end}
{synopt:{opt stat:istic(name)}}statistic to tabulate/plot (default {cmd:mean}){p_end}
{synopt:{opt pct}}scale the outcome to percent (prevalence for a 0/1 variable){p_end}
{synopt:{opt fr:eq}}add the frequency (N) to the table{p_end}
{synopt:{opt li:ne}}line (series) plot instead of bars; x = {it:factor1}{p_end}
{synopt:{opt heat:map}}heatmap of the outcome over {it:factor1} (x) by {it:factor2} (y); class-binned colour, scales to hundreds of cells{p_end}
{synopt:{opt comp:osition}}% of the (sub)sample per cell (as {cmd:catplot, percent}); no outcome{p_end}
{synopt:{opt pan:el}}small multiples: one mini-panel per category; x = {it:factor1}{p_end}
{synopt:{opt dual}}two margins of an ordinal outcome (0=none): % consuming (bars) + frequency among consumers (line, second axis){p_end}
{synopt:{opt sort}}order the bars by value (descending){p_end}
{synopt:{opt hbar}}horizontal bars (automatic if the axis factor has >12 categories){p_end}

{syntab:Output}
{synopt:{opt ti:tle(string)}}axis/figure title{p_end}
{synopt:{opt note(string)}}figure footnote (e.g. the source); none by default{p_end}
{synopt:{opt sav:ing(file)}}export the table ({cmd:.md}, {cmd:.docx}, {cmd:.html}, {cmd:.tex}){p_end}
{synopt:{opt gra:ph(file.png)}}save the figure (PNG, 2200 px wide){p_end}
{synopt:{opt for:mat(%fmt)}}numeric format (default {cmd:%5.1f}){p_end}
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
produces (i) a {bf:table} on the Stata 17 {helpb table}/{helpb collect} framework, exportable
to Markdown, Word, HTML or LaTeX, and (ii) a coherent {bf:figure} (bars by default, or lines
with {opt line}), with labels and percentages consistent across the table and the graph.

{pstd}
It is aimed at household-survey consumption studies (e.g. coca, alcohol, tobacco), where one
crosses prevalences by income, ethnicity, education, area, or time. Requires {bf:Stata 17 or
later}.


{marker options}{...}
{title:Options}

{phang}
{opt by(varname)} numeric variable defining the table columns and the figure panels.

{phang}
{opt statistic(name)} {helpb table} statistic: {cmd:mean} (default), {cmd:sum}, {cmd:median},
etc.

{phang}
{opt pct} multiplies the outcome by 100; with a 0/1 variable this gives the {bf:prevalence (%)}.

{phang}
{opt freq} adds a frequency (N) row/column to the table.

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
{cmd:[1, max]} (common across panels) so the reading is honest. The table carries extensive +
intensive + N per cell. Useful to see the {bf:dissociation of margins}: what raises participation
need not raise frequency.

{phang}
{opt sort} orders the bars by value (descending), for ranking-style reading.

{phang}
{opt hbar} draws {bf:horizontal bars}. It is {bf:automatic} when the axis factor has more than 12
categories (so horizontal labels do not collide); {opt hbar} forces it even with few.

{phang}
{opt title(string)} Y-axis / figure title.

{phang}
{opt note(string)} figure footnote (for example, the data source or a signature). By default the
figure carries no note.

{phang}
{opt saving(file)} exports the table; the type is inferred from the extension ({cmd:.md},
{cmd:.docx}, {cmd:.html}, {cmd:.tex}).

{phang}
{opt graph(file.png)} exports the figure as PNG (2200 px wide).

{phang}
{opt format(%fmt)} numeric format of the table/labels (default {cmd:%5.1f}).

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


{marker author}{...}
{title:Author}

{pstd}
Juan Marcelo Gutierrez Miranda {hline 1} TodoEconometria, Madrid, Spain.{break}
The command was developed for a comparative study of coca-leaf consumption in the Andes
(Bolivia and Peru). Cite as: Gutierrez Miranda, J. M. (2026). {it:cruceandino: one-step
multiway crosstabulation with a coherent table and figure}.
