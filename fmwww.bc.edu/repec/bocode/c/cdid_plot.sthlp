{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{vieweralsosee "[G-2] graph twoway" "help twoway"}{...}
{viewerjumpto "Syntax" "cdid_plot##syntax"}{...}
{viewerjumpto "Description" "cdid_plot##description"}{...}
{viewerjumpto "Options" "cdid_plot##options"}{...}
{viewerjumpto "Plotted values" "cdid_plot##plotdata"}{...}
{viewerjumpto "Examples" "cdid_plot##examples"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:cdid_plot} {hline 2}}Graph {cmd:cdid} estimates{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cdid_plot} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt group(numlist)}}cohorts to plot{p_end}
{synopt:{opt cells}}plot the group-time estimates after {cmd:estat}{p_end}
{synopt:{opt sav:ing}{cmd:(}{it:filename}[{cmd:, replace}]{cmd:)}}save the graph as a {cmd:.gph} file{p_end}
{synopt:{opt exp:ort}{cmd:(}{it:filename}[{cmd:, replace} {it:export_options}]{cmd:)}}export the graph with {helpb graph export}{p_end}
{synopt:{opt plotd:ata}{cmd:(}{it:filename}[{cmd:, replace}]{cmd:)}}save the plotted values as a dataset{p_end}
{synopt:{opt replace}}allow all output files to be overwritten{p_end}
{synopt:{it:twoway_options}}options of {helpb twoway}, such as {opt title()} or {opt scheme()}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_plot} graphs the current {helpb cdid} estimates with their
confidence intervals: markers for the estimates, capped spikes for the
intervals, a dashed line at zero, and different colors for pretreatment and
post-treatment effects (reference periods are hollow).

{pstd}
After {cmd:cdid}, the graph shows ATT({it:g},{it:t}) by period, with one
panel per cohort. After {cmd:estat dynamic}, {cmd:estat group}, or
{cmd:estat calendar}, the horizontal axis is the time since adoption, the
cohort, or the period. {cmd:estat simple} produces a single number; use
{opt cells} to plot the group-time estimates instead.

{pstd}
The intervals are those reported by {cmd:cdid}: simultaneous bands when they
were requested, pointwise intervals otherwise. Unavailable estimates are not
drawn; a note gives their number. {cmd:cdid_plot} uses the stored results and
leaves the data, {cmd:e()}, and {cmd:r()} unchanged. It corresponds to
{cmd:ggdid()} of R {cmd:cdid} and is not available after
{cmd:cdid} with {opt dvar()}.


{marker options}{...}
{title:Options}

{phang}
{opt group(numlist)} restricts the graph to the listed cohorts, after
{cmd:cdid} or {cmd:estat group}. If a listed cohort is not in the results, all
cohorts are plotted and a note says so.

{phang}
{opt cells} plots the group-time estimates when the current results are an
{cmd:estat} aggregation.

{phang}
{opt saving(filename[, replace])} saves the graph as a Stata graph file;
{cmd:.gph} is added if {it:filename} has no extension. Names in
{cmd:c(tmpdir)}, such as those created by {helpb tempfile}, are accepted as
given, here and in {opt plotdata()}.

{phang}
{opt export(filename[, replace export_options])} also writes the graph with
{helpb graph export}; the extension ({cmd:.png}, {cmd:.pdf}, {cmd:.svg}, ...)
sets the format, and {it:export_options} such as {cmd:width()} are passed to
{cmd:graph export}.

{phang}
{opt plotdata(filename[, replace])} saves the plotted values; see
{help cdid_plot##plotdata:Plotted values}.

{phang}
{opt replace} allows all output files to be overwritten. Without it, an
existing file is not overwritten and nothing is drawn.

{phang}
{it:twoway_options} are passed to {helpb twoway}. Titles, axis labels,
legends, and notes that you specify replace the defaults.


{marker plotdata}{...}
{title:Plotted values}

{pstd}
The dataset saved by {opt plotdata()} has one observation per estimate,
including estimates not drawn: {cmd:series} ({cmd:Pre}, {cmd:Post}, or
{cmd:Reference}), {cmd:x}, {cmd:x_label}, {cmd:estimate}, {cmd:ci_low},
{cmd:ci_high}, {cmd:group}, {cmd:time}, {cmd:event_time}, {cmd:available},
{cmd:drawn}, {cmd:interval_kind}, and {cmd:reason}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20261116}{p_end}
{phang2}{cmd:. set obs 600}{p_end}
{phang2}{cmd:. generate id = _n}{p_end}
{phang2}{cmd:. generate G = cond(runiform() < .4, 0, cond(runiform() < .5, 2004, 2006))}{p_end}
{phang2}{cmd:. generate x = rnormal()}{p_end}
{phang2}{cmd:. expand 8}{p_end}
{phang2}{cmd:. bysort id: generate year = 2000 + _n}{p_end}
{phang2}{cmd:. generate y = x + .2*(year - 2000) + (G > 0 & year >= G)*(1 + .25*(year - G)) + rnormal()}{p_end}
{phang2}{cmd:. replace y = . if runiform() < .2}{p_end}

{pstd}Effects by cohort, then the event study{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G)}{p_end}
{phang2}{cmd:. cdid_plot}{p_end}
{phang2}{cmd:. cdid_plot, group(2006) title("Cohort 2006")}{p_end}
{phang2}{cmd:. estat dynamic}{p_end}
{phang2}{cmd:. cdid_plot, export(event_study.png, replace width(1600))}{p_end}
{phang2}{cmd:. cdid_plot, cells plotdata(cdid_plotdata, replace)}{p_end}



{title:Acknowledgment}

{pstd}
The graph layout follows {cmd:csdid_plot} 2.0.2 by Brantly Callaway, Fernando
Rios-Avila, and Pedro H. C. Sant'Anna (MIT License).


{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
