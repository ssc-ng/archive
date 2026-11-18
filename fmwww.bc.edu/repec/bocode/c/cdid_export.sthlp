{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_diagnostics" "help cdid_diagnostics"}{...}
{vieweralsosee "cdid_plot" "help cdid_plot"}{...}
{viewerjumpto "Syntax" "cdid_export##syntax"}{...}
{viewerjumpto "Description" "cdid_export##description"}{...}
{viewerjumpto "Options" "cdid_export##options"}{...}
{viewerjumpto "Contents of the datasets" "cdid_export##layouts"}{...}
{viewerjumpto "Examples" "cdid_export##examples"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd:cdid_export} {hline 2}}Save {cmd:cdid} results as a Stata dataset{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
{cmd:cdid_export} {cmd:using} {it:{help filename}} [{cmd:,} {opt type(table)} {opt replace}]

{p 8 8 2}
{it:table} is {opt cells} (the default), {opt aggregate}, {opt units},
{opt influence}, or {opt summary}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_export} writes the current {helpb cdid} results to a {cmd:.dta}
dataset: the group-time estimates, an {cmd:estat} aggregation, the units, the
influence functions, or a summary of the settings. It uses the stored results
and leaves the data in memory, {cmd:e()}, {cmd:r()}, and the random-number
state unchanged.

{pstd}
After {cmd:cdid} with {opt dvar()}, {cmd:type(cells)} and {cmd:type(aggregate)}
are available; {cmd:type(aggregate)} then holds the switcher-weighted average
and needs no {cmd:estat}.

{pstd}
If {it:filename} has no extension, {cmd:.dta} is added; other extensions are
not allowed, except for names in {cmd:c(tmpdir)}, such as those created by
{helpb tempfile}, which are accepted as given. Use {helpb export delimited} on
the saved dataset for other formats.


{marker options}{...}
{title:Options}

{phang}
{opt type(table)} selects the dataset; see
{help cdid_export##layouts:Contents of the datasets}.

{phang}
{opt replace} allows {it:filename} to be overwritten.


{marker layouts}{...}
{title:Contents of the datasets}

{pstd}
After {cmd:cdid} with {opt gvar()}, each dataset records the export type, the
estimation mode, the number of units and cells, and the {cmd:cdid} command line
as dataset characteristics ({cmd:char list}). Variables beginning with {cmd:src_} contain additional
stored columns; their variable labels give the original column names.

{dlgtab:type(cells)}

{pstd}
One observation per group-time cell, including pretreatment, reference, and
unavailable cells:

{p2colset 9 26 28 2}{...}
{p2col :{cmd:cell}}cell number{p_end}
{p2col :{cmd:g}, {cmd:time}}cohort and period{p_end}
{p2col :{cmd:ref}, {cmd:base}}reference and base periods ({cmd:ref} is missing in ordinary mode){p_end}
{p2col :{cmd:event}}{cmd:time} - {cmd:g}{p_end}
{p2col :{cmd:role_code}, {cmd:role}}1 reference, 2 pretreatment, 3 post-treatment{p_end}
{p2col :{cmd:available}}1 if estimated; otherwise {cmd:reason} explains why not{p_end}
{p2col :{cmd:estimate}}estimated effect{p_end}
{p2col :{cmd:se}}reported standard error{p_end}
{p2col :{cmd:analytic_se}}analytical standard error{p_end}
{p2col :{cmd:lower}, {cmd:upper}}reported interval or simultaneous band{p_end}
{p2col :{cmd:ci_lower}, {cmd:ci_upper}}pointwise confidence interval{p_end}
{p2col :{cmd:zstat}, {cmd:pvalue}}z statistic and p-value (chained mode){p_end}
{p2col :{cmd:interval_kind}, {cmd:se_kind}}type of interval and standard error{p_end}
{p2colreset}{...}

{pstd}
With the multiplier bootstrap, {cmd:se} is the bootstrap standard error and
can differ from {cmd:analytic_se}. After {cmd:estat}, {cmd:type(cells)} still
describes the group-time estimates.

{dlgtab:type(aggregate)}

{pstd}
After {opt gvar()} estimation, requires a current {cmd:estat} aggregation. The variable {cmd:record}
identifies the observations: {cmd:bin} (one per aggregation bin),
{cmd:overall} (the overall estimate), {cmd:member} (the cells in each bin,
with their weights), {cmd:overall_member} (the components of the overall
estimate), and {cmd:na_rm_excluded} (cells dropped by {cmd:narm}). Bin
observations contain {cmd:key} (cohort, period, or event time), {cmd:label},
{cmd:estimate}, {cmd:se}, {cmd:analytic_se}, {cmd:lower}, {cmd:upper},
{cmd:ci_lower}, {cmd:ci_upper}, {cmd:available}, and {cmd:reason}.

{dlgtab:type(cells) and type(aggregate) after dvar()}

{pstd}
After {cmd:cdid} with {opt dvar()}, {cmd:type(cells)} has one observation per
requested cell, with the variables {cmd:time} (the date {it:t}), {cmd:tprev}
(the preceding study date), {cmd:direction} ({cmd:entry} or {cmd:exit}),
{cmd:sign}, {cmd:available}, {cmd:switchers}, {cmd:stayers}, {cmd:att},
{cmd:theta}, {cmd:se}, {cmd:lower}, {cmd:upper}, {cmd:analytic_se},
{cmd:bootstrap_se}, and {cmd:status}, defined as the columns of {cmd:e(cells)}
in {helpb cdid_dvar##results:cdid with dvar()}. {cmd:type(aggregate)} has one
observation with {cmd:estimate} (the switcher-weighted average), {cmd:se},
{cmd:analytic_se}, {cmd:bootstrap_se}, {cmd:switchers}, and {cmd:level}.

{dlgtab:type(units)}

{pstd}
One observation per unit of the study population: {cmd:unit}, {cmd:id},
{cmd:cohort}, {cmd:cohort_status} ({cmd:treated}, {cmd:never_treated}, or
{cmd:unknown}), {cmd:weight}, and {cmd:cluster}, with the number of observed
periods and related information in {cmd:src_} variables.

{dlgtab:type(influence)}

{pstd}
One observation per unit and estimated quantity: {cmd:unit}, {cmd:id},
{cmd:family}, {cmd:target}, {cmd:g}, {cmd:time}, {cmd:key}, {cmd:available},
and {cmd:value}, the influence function. {cmd:family} distinguishes
group-time cells ({cmd:cell}), cohort shares ({cmd:fit_share}), and, after
{cmd:estat}, the aggregation bins and the overall estimate. Values are those
used to compute the standard errors. This type is not available after
{cmd:noinffunc} and is refused when the number of observations would exceed
Stata's limit.

{dlgtab:type(summary)}

{pstd}
One observation per reported quantity or setting, with variables
{cmd:category}, {cmd:key}, {cmd:text}, {cmd:value}, and {cmd:cohort}. The
categories cover the quantities shown by {helpb cdid_diagnostics}, every
estimation setting, the cohort shares, and the contents of {cmd:e()}.


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

{pstd}Export the cells, the units, and an event study{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. cdid_export using cdid_cells, type(cells) replace}{p_end}
{phang2}{cmd:. cdid_export using cdid_units, type(units) replace}{p_end}
{phang2}{cmd:. estat dynamic}{p_end}
{phang2}{cmd:. cdid_export using cdid_dynamic, type(aggregate) replace}{p_end}
{phang2}{cmd:. describe using cdid_dynamic}{p_end}



{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
