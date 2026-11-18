{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_chain" "help cdid_chain"}{...}
{vieweralsosee "cdid_diagnostics" "help cdid_diagnostics"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{vieweralsosee "cdid_load" "help cdid_load"}{...}
{vieweralsosee "cdid_nuisance" "help cdid_nuisance"}{...}
{vieweralsosee "cdid_plot" "help cdid_plot"}{...}
{viewerjumpto "Postestimation commands" "cdid_postestimation##description"}{...}
{viewerjumpto "estat" "cdid_postestimation##estat"}{...}
{viewerjumpto "Options for estat" "cdid_postestimation##options"}{...}
{viewerjumpto "Remarks" "cdid_postestimation##remarks"}{...}
{viewerjumpto "Examples" "cdid_postestimation##examples"}{...}
{viewerjumpto "Stored results" "cdid_postestimation##results"}{...}
{viewerjumpto "References" "cdid_postestimation##references"}{...}
{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{bf:cdid postestimation} {hline 2}}Postestimation tools for {cmd:cdid}{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following commands are available after {helpb cdid} with {opt gvar()}:

{synoptset 22}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb cdid_postestimation##estat:estat simple}}overall average of the post-treatment effects{p_end}
{synopt :{helpb cdid_postestimation##estat:estat group}}average effect by cohort{p_end}
{synopt :{helpb cdid_postestimation##estat:estat dynamic}}average effect by time since adoption (event study){p_end}
{synopt :{helpb cdid_postestimation##estat:estat calendar}}average effect by calendar date{p_end}
{synopt :{helpb cdid_chain}}comparisons and GMM weights behind each effect{p_end}
{synopt :{helpb cdid_nuisance}}fitted treatment, outcome, observation, and imputation models{p_end}
{synopt :{helpb cdid_diagnostics}}sample, model, and inference behind the results{p_end}
{synopt :{helpb cdid_plot}}graph of the effects or of an aggregation{p_end}
{synopt :{helpb cdid_export}}effects, aggregations, units, or influence functions as a dataset{p_end}
{synopt :{helpb cdid_load}}restore results saved with {opt saving()}{p_end}
{synopt :{helpb estimates}}store, restore, and replay results{p_end}
{synoptline}

{pstd}
These commands use the stored results and do not refit. After
{cmd:cdid} with {opt dvar()}, only {helpb cdid_export}, {helpb cdid_nuisance},
and {helpb estimates} apply; see {helpb cdid_dvar:cdid with dvar()}.
{helpb cdid_pretest}, the conditional pretrend test, is a separate estimation
command.


{marker estat}{...}
{title:Syntax for estat}

{p 8 14 2}
{cmd:estat} {c -(}{cmd:simple}{c |}{cmd:group}{c |}{cmd:dynamic}{c |}{cmd:calendar}{c )-}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Targets}
{synopt :{opt mine(#)}}earliest event time ({cmd:estat dynamic}){p_end}
{synopt :{opt maxe(#)}}latest event time or horizon ({cmd:dynamic}, {cmd:simple}, {cmd:group}){p_end}
{synopt :{opt balancee(#)}}keep cohorts observed for {it:#} periods after adoption ({cmd:dynamic}){p_end}
{synopt :{opt narm}}aggregate the available cells when some are unavailable{p_end}

{syntab:Inference}
{synopt :{opt bstrap(#)}}{cmd:1} multiplier bootstrap, {cmd:0} analytical; default: that of the fit{p_end}
{synopt :{opt cband(#)}}{cmd:1} simultaneous bands, {cmd:0} pointwise intervals; default: that of the fit{p_end}
{synopt :{opt biters(#)}}bootstrap draws; default: that of the fit{p_end}
{synopt :{opt l:evel(#)}}confidence level; default: that of the fit{p_end}
{synopt :{opt cluster(varname)}}the fit's cluster variable; {cmd:none} or {opt ivar()} after an ordinary fit{p_end}

{syntab:Computation and saving}
{synopt :{opt workspace(#)}}memory limit in bytes; default {cmd:1073741824}{p_end}
{synopt :{opt chunk(#)}}rows per processing block; default {cmd:1024}{p_end}
{synopt :{opt posting(string)}}{opt matrix} (default) or {opt state}{p_end}
{synopt :{opt saving(filename)}}save the aggregation for {helpb cdid_load}{p_end}
{synoptline}


{title:Description of estat}

{pstd}
{cmd:estat} aggregates the group-time effects of the current {cmd:cdid}
results, as R's {cmd:aggte()} does. {cmd:estat simple} averages the
post-treatment cells with weights proportional to cohort size;
{cmd:estat group} averages them by cohort, {cmd:estat dynamic} by time since
adoption, and {cmd:estat calendar} by calendar date. Each type also reports an
overall estimate. Cohort shares are computed over the study population.

{pstd}
{cmd:estat} replaces the results in {cmd:e()} with the aggregation. The
group-time results are kept, so another {cmd:estat} can follow, and typing
{cmd:cdid} replays the current aggregation. {helpb cdid_chain} reports the
comparisons of the fit from which the aggregation was computed in the same
session. {helpb cdid_nuisance} needs the fit to be the current result: store it
with {cmd:estimates store} before {cmd:estat} and restore it afterwards.


{marker options}{...}
{title:Options for estat}

{phang}
{opt mine(#)}, {opt maxe(#)}, and {opt balancee(#)} correspond to R's
{cmd:min_e}, {cmd:max_e}, and {cmd:balance_e}. With {cmd:estat dynamic},
{opt balancee(#)} keeps the cohorts observed for at least {it:#} periods after
treatment, and {opt mine()} and {opt maxe()} bound the event time {it:t} - {it:g}
in date units; a window without event times, or without nonnegative event
times, is refused. With {cmd:estat simple} and {cmd:estat group}, only
{opt maxe(#)} applies: it keeps the post-treatment cells whose horizon, counted
in positions of the sorted dates, is at most {it:#}. {cmd:estat calendar}
ignores all three, with a note.

{phang}
{opt narm} aggregates over the available cells when a cell needed by a target
is unavailable; the result then describes a restricted target, and the
excluded cells are recorded. Without it, such a target is reported as
unavailable.

{phang}
{opt bstrap(#)}, {opt cband(#)}, {opt biters(#)}, and {opt level(#)} set the
inference of the aggregation; by default, those of the fit are used.
Simultaneous bands cover the bins of one aggregation; the overall estimate has
a pointwise interval.

{phang}
{cmd:estat} inherits the clustering of the fit. After an ordinary-mode fit,
{cmd:cluster(none)} or the {opt ivar()} variable requests unit-level inference.
If an unavailable cluster variable is requested, {cmd:estat} warns and uses
unit-level inference for both analytical and multiplier-bootstrap standard
errors. Refit {cmd:cdid} with {opt cluster()} to use that variable. After a
chained fit, a request to change clustering stops with an error.

{phang}
{opt workspace(#)}, {opt chunk(#)}, {opt posting()}, and {opt saving()} are as
for {helpb cdid}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:estat} needs the influence functions of the fit; it is refused after
{opt noinffunc}. Bootstrap draws come from the current random-number stream;
use {helpb set seed} for reproducible results. After {cmd:cdid} with
{opt dvar()}, {cmd:estat} stops with a message pointing to {cmd:e(att)} and
{helpb cdid_export:cdid_export, type(aggregate)}. With
{cmd:missingreference(exclude)}, a cohort whose comparisons were restricted
enters with the mass of its eligible treated units.


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
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G)}{p_end}
{phang2}{cmd:. estimates store fit}{p_end}

{pstd}The four aggregations{p_end}
{phang2}{cmd:. estat simple}{p_end}
{phang2}{cmd:. estat group}{p_end}
{phang2}{cmd:. estat calendar}{p_end}
{phang2}{cmd:. estat dynamic, mine(-3) maxe(3)}{p_end}

{pstd}The comparisons behind the fit, after an aggregation{p_end}
{phang2}{cmd:. cdid_chain, cohort(2006)}{p_end}

{pstd}Restore the fit{p_end}
{phang2}{cmd:. estimates restore fit}{p_end}
{phang2}{cmd:. cdid}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:estat} replaces the results in {cmd:e()} with the aggregation. In chained mode, it adds:

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N_cells)}}number of group-time cells of the fit{p_end}
{synopt:{cmd:e(N_targets)}}number of aggregation bins{p_end}
{synopt:{cmd:e(N_posted)}}number of estimates in {cmd:e(b)}{p_end}
{synopt:{cmd:e(bstrap)}}bootstrap flag used{p_end}
{synopt:{cmd:e(cband)}}band flag used{p_end}
{synopt:{cmd:e(overall_att)}}overall estimate{p_end}
{synopt:{cmd:e(overall_se)}}its reported standard error{p_end}
{synopt:{cmd:e(overall_analytic_se)}}its analytical standard error{p_end}
{synopt:{cmd:e(overall_ci_low)}}lower limit of its pointwise interval{p_end}
{synopt:{cmd:e(overall_ci_high)}}upper limit of its pointwise interval{p_end}
{synopt:{cmd:e(overall_n_draws)}}bootstrap draws for the overall estimate{p_end}
{synopt:{cmd:e(overall_draws_used)}}1 if bootstrap draws were used for it{p_end}
{synopt:{cmd:e(n_draws)}}bootstrap draws for the bins{p_end}
{synopt:{cmd:e(draws_used)}}1 if bootstrap draws were used for the bins{p_end}
{synopt:{cmd:e(min_e)}}value of mine(){p_end}
{synopt:{cmd:e(max_e)}}value of maxe(){p_end}
{synopt:{cmd:e(balance_e)}}value of balancee(){p_end}
{synopt:{cmd:e(na_rm)}}1 with narm{p_end}

{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(title)}}title of the fit, followed by the aggregation type{p_end}
{synopt:{cmd:e(estat_cmdline)}}the estat command as typed{p_end}
{synopt:{cmd:e(agg_type)}}simple, group, dynamic, or calendar{p_end}
{synopt:{cmd:e(subcmd)}}the estat subcommand{p_end}
{synopt:{cmd:e(result_kind)}}aggregation{p_end}
{synopt:{cmd:e(overall_status)}}status of the overall estimate{p_end}
{synopt:{cmd:e(overall_reason)}}why it is unavailable, when it is{p_end}
{synopt:{cmd:e(overall_inference_status)}}status of its inference{p_end}
{synopt:{cmd:e(overall_inference_kind)}}type of its standard error{p_end}
{synopt:{cmd:e(band_family)}}type of band{p_end}
{synopt:{cmd:e(target_definition)}}definition of the aggregated targets{p_end}
{synopt:{cmd:e(weight_reduction)}}how unit weights were reduced{p_end}
{synopt:{cmd:e(weight_source)}}source of the weights{p_end}
{synopt:{cmd:e(selector_warning)}}note about mine(), maxe(), or balancee(), when any{p_end}

{p2colreset}{...}

{pstd}
In chained mode, estat also posts the results of cdid that describe the data, the inference and the posting ({cmd:e(N)}, {cmd:e(N_full)}, {cmd:e(clustered)}, {cmd:e(N_clust)}, {cmd:e(level)}, {cmd:e(alpha)}, {cmd:e(critical_value)}, e(wald_*), {cmd:e(vce)}, {cmd:e(band)}, {cmd:e(rng)}, {cmd:e(b)}, {cmd:e(V)}, {cmd:e(se)}, {cmd:e(ci)}, {cmd:e(coef_map)}, ...) and the settings macros of the fit, except {cmd:e(anticipation)}, {cmd:e(inactive_options)}, {cmd:e(missing_reference)}, {cmd:e(reference_status)}, and {cmd:e(nuisance)}; {cmd:e(cmdline)} and {cmd:e(sample)} are those of the fit. In ordinary mode, estat posts the results listed for ordinary fits in help cdid, except {cmd:e(inactive_options)}, {cmd:e(V_did)}, and {cmd:e(V_did_asymptotic)}, and adds {cmd:e(estat_cmdline)}; {cmd:e(N_targets)} and {cmd:e(N_posted)} count the bins and the overall estimate, which is the last element of {cmd:e(b)}. The overall-effect scalars, {cmd:e(agg_type)}, and {cmd:e(subcmd)} are posted in chained mode only.


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
