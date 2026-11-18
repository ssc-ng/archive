{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{vieweralsosee "cdid_plot" "help cdid_plot"}{...}
{viewerjumpto "Syntax" "cdid_diagnostics##syntax"}{...}
{viewerjumpto "Description" "cdid_diagnostics##description"}{...}
{viewerjumpto "Option" "cdid_diagnostics##options"}{...}
{viewerjumpto "Examples" "cdid_diagnostics##examples"}{...}
{viewerjumpto "Stored results" "cdid_diagnostics##results"}{...}
{title:Title}

{p2colset 5 25 27 2}{...}
{p2col :{cmd:cdid_diagnostics} {hline 2}}Summary of the sample, model, and inference behind {cmd:cdid} results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 24 2}
{cmd:cdid_diagnostics} [{cmd:,} {opt det:ail}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_diagnostics} summarizes the current {helpb cdid} results (or the
current {cmd:estat} aggregation) and returns the summary in {cmd:r()}. It
reports:

{p 8 11 2}1. the result type, estimation mode, and aggregation, if any;{p_end}
{p 8 11 2}2. the population: units, treated and never-treated units, units supplied only through {cmd:frame()}, units with at least one observed outcome and with at least two, clusters, and the range of the weights;{p_end}
{p 8 11 2}3. the group-time cells by role (post-treatment, pretreatment, reference) and availability;{p_end}
{p 8 11 2}4. identification status and, in chained mode, the GMM weighting and the rank and regularization of its covariance;{p_end}
{p 8 11 2}5. the model, missing-outcome, weight, and computation settings;{p_end}
{p 8 11 2}6. the pretrend Wald test;{p_end}
{p 8 11 2}7. the inference settings; and{p_end}
{p 8 11 2}8. after {cmd:estat}, the counts of aggregation bins and the availability of the overall estimate.{p_end}

{pstd}
The rank of the GMM covariance concerns the weighting of the chained
comparisons; it does not indicate whether an effect is identified.

{pstd}
{cmd:cdid_diagnostics} uses the stored results only. It does not use the data
in memory, does not refit, and leaves the data, {cmd:e()}, and the
random-number state unchanged. It is not available after {cmd:cdid} with
{opt dvar()}. A quantity that was not stored with the
results is shown as {cmd:not retained} and returned as missing, never as zero.


{marker options}{...}
{title:Option}

{phang}
{opt detail} also lists each unavailable group-time cell and aggregation bin
with the reason it is unavailable.


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

{pstd}Diagnostics of a fit and of an aggregation{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. cdid_diagnostics}{p_end}
{phang2}{cmd:. estat dynamic}{p_end}
{phang2}{cmd:. cdid_diagnostics, detail}{p_end}
{phang2}{cmd:. display r(N_with_two_outcomes)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_diagnostics} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(N_units)}}number of units{p_end}
{synopt:{cmd:r(N_treated)}}treated units{p_end}
{synopt:{cmd:r(N_never_treated)}}never-treated units{p_end}
{synopt:{cmd:r(N_unknown_cohort)}}units with unknown cohort{p_end}
{synopt:{cmd:r(N_with_rows)}}units with data rows{p_end}
{synopt:{cmd:r(N_frame_only)}}units supplied only through frame(){p_end}
{synopt:{cmd:r(N_with_outcome)}}units with at least one observed outcome{p_end}
{synopt:{cmd:r(N_with_two_outcomes)}}units with at least two observed outcomes{p_end}
{synopt:{cmd:r(N_cluster_ids)}}distinct cluster identifiers retained from the fit{p_end}
{synopt:{cmd:r(N_clust)}}clusters used for cell inference, missing when unclustered{p_end}
{synopt:{cmd:r(weight_sum)}}sum of unit weights{p_end}
{synopt:{cmd:r(weight_min)}}smallest unit weight{p_end}
{synopt:{cmd:r(weight_max)}}largest unit weight{p_end}
{synopt:{cmd:r(N_cells)}}number of cells{p_end}
{synopt:{cmd:r(N_post)}}post-treatment cells{p_end}
{synopt:{cmd:r(N_pre)}}pretreatment cells{p_end}
{synopt:{cmd:r(N_reference)}}reference cells{p_end}
{synopt:{cmd:r(N_available)}}available cells{p_end}
{synopt:{cmd:r(N_unavailable)}}unavailable cells{p_end}
{synopt:{cmd:r(N_with_se)}}cells with a standard error{p_end}
{synopt:{cmd:r(B_requested)}}number of multiplier draws requested{p_end}
{synopt:{cmd:r(wald_statistic)}}pretrend Wald statistic{p_end}
{synopt:{cmd:r(wald_df)}}its degrees of freedom{p_end}
{synopt:{cmd:r(wald_p)}}its p-value{p_end}
{synopt:{cmd:r(N_aggregates)}}aggregation bins, after estat{p_end}
{synopt:{cmd:r(N_aggregates_available)}}available bins, after estat{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(mode)}}chained or ordinary{p_end}
{synopt:{cmd:r(result_kind)}}cells or aggregation{p_end}
{synopt:{cmd:r(agg_type)}}aggregation type, after estat{p_end}
{synopt:{cmd:r(method)}}treatment adjustment{p_end}
{synopt:{cmd:r(control_group)}}comparison group{p_end}
{synopt:{cmd:r(base_period)}}base period{p_end}
{synopt:{cmd:r(pt_assumption)}}parallel trends assumption{p_end}
{synopt:{cmd:r(gmm_weighting)}}GMM weighting{p_end}
{synopt:{cmd:r(selection)}}assumption about missing outcomes{p_end}
{synopt:{cmd:r(wald_status)}}status of the pretrend Wald test{p_end}
{synopt:{cmd:r(inference_status)}}status of the inference{p_end}
{synopt:{cmd:r(band)}}intervals for the cells: pointwise, simultaneous, or none{p_end}
{synopt:{cmd:r(vce)}}standard errors for the cells: analytic, bootstrap, or none{p_end}
{synopt:{cmd:r(clustvar)}}cluster variable retained from the ordinary fit{p_end}
{synopt:{cmd:r(rng)}}source of multiplier draws, in chained mode{p_end}
{synopt:{cmd:r(inactive_options)}}inactive options in the chained specification{p_end}
{synopt:{cmd:r(wald_reason)}}cells used by the test or why it was unavailable{p_end}
{synopt:{cmd:r(overall_status)}}availability of the overall summary, after estat{p_end}
{synopt:{cmd:r(overall_reason)}}reason for an unavailable overall summary, after estat{p_end}
{synopt:{cmd:r(cells_matrix)}}note posted instead of {cmd:r(cells)} when the table exceeds c(max_matdim); use cdid_export{p_end}
{synopt:{cmd:r(aggregate_matrix)}}the same for {cmd:r(aggregate)}, after estat{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:r(cells)}}cells: cohort, date, role, availability, estimate, standard error, and bounds{p_end}
{synopt:{cmd:r(aggregate)}}aggregation bins, after estat{p_end}

{p2colreset}{...}

{pstd}
cdid_diagnostics returns every displayed quantity in r(); the lists above are the main results. A missing numeric quantity is accompanied by {cmd:r(name_status)}, which explains why. The matrices are returned only when they fit within c(max_matdim).



{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
