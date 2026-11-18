{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid postestimation" "help cdid_postestimation"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{viewerjumpto "Syntax" "cdid_chain##syntax"}{...}
{viewerjumpto "Description" "cdid_chain##description"}{...}
{viewerjumpto "Options" "cdid_chain##options"}{...}
{viewerjumpto "Remarks" "cdid_chain##remarks"}{...}
{viewerjumpto "Examples" "cdid_chain##examples"}{...}
{viewerjumpto "Stored results" "cdid_chain##results"}{...}
{viewerjumpto "References" "cdid_chain##references"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{cmd:cdid_chain} {hline 2}}Comparisons and GMM weights behind chained {cmd:cdid} estimates{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:cdid_chain} [{cmd:,} {it:options}]

{synoptset 30}{...}
{synopthdr}
{synoptline}
{synopt :{opth c:ohort(numlist)}}report only the cells of these cohorts{p_end}
{synopt :{opth t:ime(numlist)}}report only the cells of these dates{p_end}
{synopt :{opt pre}}include pretreatment and reference cells{p_end}
{synopt :{opt weights}}list the GMM weight of each comparison{p_end}
{synopt :{opt tol(#)}}treat GMM weights smaller than {it:#} in absolute value as zero; default {cmd:1e-10}{p_end}
{synopt :{cmd:saving(}{it:filename}[{cmd:, replace}]{cmd:)}}save one table as a Stata dataset{p_end}
{synopt :{opt tab:le(name)}}table to save: {opt summary} (default), {opt witness}, or {opt weights}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_chain} describes how each group-time effect of the current
{helpb cdid} fit is identified and estimated from the two-date comparisons.
For each cell, it reports whether a single comparison spans the cell's base
and target dates ({cmd:direct}) or the cell is identified only by chaining
several comparisons through intermediate dates; a witness path, which is one
shortest combination of comparisons that identifies the cell; and, with
{opt weights}, the GMM weights of all comparisons, whose contributions (weight
times comparison estimate) sum to the reported estimate. It corresponds to
{cmd:chain_report()} of {browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}.

{pstd}
{cmd:cdid_chain} is available after {cmd:cdid} with {opt gvar()} in chained
mode, including {opt crosspair}, {cmd:method(custom)},
{cmd:selection(conditional_mtar)}, covariates or weights that vary over time,
and {cmd:gmmweighting(within)}. It is not available after
{cmd:preset(cohort_time_fe)}, whose estimates do not come from chained
comparisons, after {opt dvar()}, or in ordinary mode. After {cmd:estat},
{cmd:cdid_chain} reports the comparisons of the fit from which the aggregation
was computed in the same session. The information is kept with stored
estimates, saved by {cmd:saving()} of {cmd:cdid}, and restored by
{helpb cdid_load}; files saved by {cmd:estat} do not contain it.


{marker options}{...}
{title:Options}

{phang}
{opth cohort(numlist)} and {opth time(numlist)} restrict the report to the
cells whose cohort is listed in {opt cohort()} and whose date is listed in
{opt time()}; each option accepts several values. Without {opt time()}, only
post-treatment cells are reported unless {opt pre} is specified.

{phang}
{opt pre} adds the pretreatment and reference cells.

{phang}
{opt weights} lists, below each available cell, the comparisons with nonzero
GMM weight: the cohort and dates of the comparison, its control set
({cmd:K={c -(}}...{cmd:{c )-}}, where {cmd:Inf} denotes the never-treated
cohort) or, with {opt crosspair}, its role (the target cohort
{cmd:g=}{it:g} or a control cohort {cmd:ctrl{c -(}}{it:k}{cmd:{c )-}}), the
weight, the comparison estimate, and the contribution.

{phang}
{opt tol(#)} sets the threshold below which GMM weights are treated as zero
in the weight list and in the count of active comparisons.

{phang}
{cmd:saving(}{it:filename}[{cmd:, replace}]{cmd:)} saves the table selected by
{opt table()} for the cells selected by the other options. The {opt summary}
table has one observation per cell with the cohort, date, event time,
reference and base dates, role, availability, whether chaining is required,
the numbers of witness comparisons and of comparisons with nonzero weight, the
estimate and standard error, the witness path, and the reason a cell is
unavailable. The {opt witness} and {opt weights} tables have one observation
per cell and comparison. {opt table()} requires {opt saving()}.


{marker remarks}{...}
{title:Remarks}

{pstd}
Without {opt crosspair}, each comparison is a difference in outcome changes
between the target cohort and a set of control cohorts observed at the same two
dates, estimated with the treatment adjustment of {opt method()}. A witness path such as

{p 8 8 2}
{cmd:2004->2005 [K={c -(}2006,2007{c )-}] + 2005->2008 [K={c -(}Inf{c )-}]}

{pstd}
reads: the comparison of the target cohort between 2004 and 2005 with control
cohorts 2006 and 2007, plus its comparison between 2005 and 2008 with the
never-treated cohort.

{pstd}
With {opt crosspair}, each comparison is the mean change of one cohort between
two dates. A witness path such as

{p 8 8 2}
{cmd:2->4 [g=3] - 2->3 [ctrl{c -(}4{c )-}] - 3->4 [ctrl{c -(}5{c )-}]}

{pstd}
reads: the change of cohort 3 between dates 2 and 4, minus the change of
cohort 4 between dates 2 and 3, minus the change of cohort 5 between dates 3
and 4. The effect of cohort 3 at date 4 is identified although no control
cohort is observed at both dates 2 and 4.

{pstd}
The witness path is one identifying combination; the estimate uses all
comparisons with the GMM weights listed by {opt weights}. Weights are reported
for the comparisons retained by the fit; comparisons that are exact linear
combinations of retained ones have no separate weight.


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

{pstd}Same-pair comparisons{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. cdid_chain}{p_end}

{pstd}Cross-pair comparisons, with the weights of one cell saved to a dataset{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) crosspair controlgroup(notyettreated) ptassumption(ctrl) gmmweighting(within) baseperiod(universal) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. cdid_chain, cohort(2006) time(2007) weights}{p_end}
{phang2}{cmd:. tempfile w}{p_end}
{phang2}{cmd:. cdid_chain, cohort(2006) time(2007) saving(`w') table(weights)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_chain} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(n_cells)}}number of cells reported{p_end}
{synopt:{cmd:r(n_available)}}number of available cells{p_end}
{synopt:{cmd:r(n_chained)}}number of available cells that require chaining{p_end}
{synopt:{cmd:r(n_moments)}}number of comparisons used by GMM{p_end}
{synopt:{cmd:r(overid_df)}}number of overidentifying restrictions{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(kind)}}crosspair or samepair{p_end}

{p2colreset}{...}

{pstd}
{cmd:cdid_chain} clears the results that other commands left in {cmd:r()}.


{marker references}{...}
{title:References}

{phang}
Callaway, B., and P. H. C. Sant'Anna. 2021. Difference-in-differences with
multiple time periods. {it:Journal of Econometrics} 225: 200-230.
{browse "https://doi.org/10.1016/j.jeconom.2020.12.001"}.


{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
