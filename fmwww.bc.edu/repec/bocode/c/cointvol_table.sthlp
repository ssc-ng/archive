{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol graph" "help cointvol_graph"}{...}
{viewerjumpto "Syntax" "cointvol_table##syntax"}{...}
{viewerjumpto "Description" "cointvol_table##description"}{...}
{viewerjumpto "Options" "cointvol_table##options"}{...}
{viewerjumpto "Examples" "cointvol_table##examples"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:cointvol table} {hline 2}}Display and export the results table of the last cointvol command{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol table} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat:rix(name)}}table a named Stata matrix instead of the last cointvol result{p_end}
{synopt:{opt exp:ort(filename)}}export; the format follows the extension:
{cmd:.tex} (booktabs LaTeX), {cmd:.html}, {cmd:.csv}, {cmd:.xlsx}, {cmd:.docx} (Stata 15+), {cmd:.md}{p_end}
{synopt:{opt replace}}overwrite an existing export file{p_end}
{synopt:{opt ti:tle(string)}}table title (default: the command that produced the results){p_end}
{synopt:{opt note:s(string)}}footnote text{p_end}
{synopt:{opt f:ormat(%fmt)}}numeric display format; default {cmd:%9.3f}{p_end}
{synopt:{opt star:s(numlist)}}significance levels for stars, up to three values in (0,1), e.g. {cmd:stars(.1 .05 .01)}{p_end}
{synopt:{opt pcol:umn(name)}}name of the p-value column used to attach stars{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
Each {cmd:cointvol} subcommand caches its main results matrix (for example
{cmd:r(stats)} after {cmd:cointvol rank}, {cmd:e(tests)} after
{cmd:cointvol restrict}, or the coefficient table built from {cmd:e(b)} and
{cmd:e(V)} after an estimator). {cmd:cointvol table} displays that matrix as a
clean table and exports it in journal-ready formats. LaTeX output uses the
{cmd:booktabs} rules; Word and Excel output use {helpb putdocx} and
{helpb putexcel}.


{marker options}{...}
{title:Options}

{phang}
{opt matrix(name)} tables any Stata matrix, which is useful to combine results
from several runs.

{phang}
{opt export(filename)} writes the table to a file whose type is taken from
the extension. Without {opt export()} the table is only displayed.

{phang}
{opt stars()} and {opt pcolumn()} attach significance stars to the row
statistic using the named p-value column; by default the first column whose
name starts with {cmd:p} is used.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse balance2, clear}{p_end}
{phang2}{cmd:. cointvol rank y i c, lags(2) trend(rconstant) method(wild) reps(499) seed(1)}{p_end}
{phang2}{cmd:. cointvol table, export(ranktests.tex) replace title("Rank tests, wild bootstrap")}{p_end}
{phang2}{cmd:. cointvol table, export(ranktests.xlsx) replace}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
