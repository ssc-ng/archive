{smcl}
{* *! version 1.0.0  21nov2026}{...}
{vieweralsosee "tvpc" "help tvpc"}{...}
{vieweralsosee "tvpcmci" "help tvpcmci"}{...}
{vieweralsosee "tvpcsens" "help tvpcsens"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:tvpcgraph} {hline 2}}Graphs of time-lagged causal structures after
{cmd:tvpc} or {cmd:tvpcmci}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:tvpcgraph} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt grid}}time-lag grid: variables by time slices {it:t-m}...{it:t} (Fig. 13 style); the default{p_end}
{synopt:{opt map(varlist|_all)}}causal relationship map of each listed variable (Figs. 3-11 style){p_end}
{synopt:{opt heat:map}}lag-link heat map, cause x effect, cells list the lags{p_end}
{synopt:{opt deg:ree}}in-links and out-links by variable{p_end}
{synopt:{opt net:work}}radial network of all active nodes (Fig. 2 style){p_end}
{synopt:{opt all}}grid, heatmap, degree and network{p_end}
{synopt:{opt name(stub)}}graph names {it:stub}{cmd:_grid}, {it:stub}{cmd:_map_}{it:var}, ...; default {cmd:tvpc}{p_end}
{synopt:{opt saving(filename)}}also save each graph as {it:filename}_{it:name}.gph{p_end}
{synopt:{opt ti:tle(string)}}override the titles{p_end}
{synopt:{opt nodraw}}build the graphs without displaying them{p_end}
{synopt:{opt nolab:els}}no node labels in {opt network}{p_end}
{synopt:{opt sch:eme(name)}}graph scheme{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:tvpcgraph} draws the estimated time-lagged causal structure, reading the
results stored by {helpb tvpc} or {helpb tvpcmci}.

{phang2}{opt grid}: rows are variables and columns are {it:t-m}, ..., {it:t}.
Orange arrows show lagged links X(t-k){c 45}{c 62}Y(t). Blue arcs at {it:t} show
contemporaneous links, dashed when undirected. Lagged nodes with an outgoing link are
shaded.{p_end}
{phang2}{opt map(var)}: reproduces the layout of the paper's relationship maps. The
top row holds the drivers of {it:var}({it:t}), with its own lags in yellow. The
middle row holds {it:var}({it:t}) in blue and the lags of {it:var} that drive other
variables. The bottom row holds the variables at {it:t} driven by {it:var}. Lags
with identical targets are grouped, as in "(t-3),(t-4)".{p_end}
{phang2}{opt heatmap}: a cause-by-effect grid shaded by the number of linking lags,
with each cell listing the lags.{p_end}
{phang2}{opt degree}: horizontal bars of in-links and out-links per variable.{p_end}
{phang2}{opt network}: variables at {it:t} on the inner ring and lags on outer rings,
with arrows for every link.{p_end}


{title:Examples}

{phang2}{cmd:. use tvpc_macro, clear}{p_end}
{phang2}{cmd:. tvpc cpi-hpi, lags(4) lagstep(3) notable}{p_end}
{phang2}{cmd:. tvpcgraph, map(cpi wage hpi)}{p_end}
{phang2}{cmd:. tvpcgraph, all name(macro)}{p_end}
{phang2}{cmd:. graph export cpi_map.png, name(tvpc_map_cpi) width(2000) replace}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
