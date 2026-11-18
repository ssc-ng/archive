{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid postestimation" "help cdid_postestimation"}{...}
{vieweralsosee "cdid_diagnostics" "help cdid_diagnostics"}{...}
{viewerjumpto "Syntax" "cdid_nuisance##syntax"}{...}
{viewerjumpto "Description" "cdid_nuisance##description"}{...}
{viewerjumpto "Option" "cdid_nuisance##options"}{...}
{viewerjumpto "Remarks" "cdid_nuisance##remarks"}{...}
{viewerjumpto "Examples" "cdid_nuisance##examples"}{...}
{viewerjumpto "Stored results" "cdid_nuisance##results"}{...}
{viewerjumpto "References" "cdid_nuisance##references"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:cdid_nuisance} {hline 2}}Report the treatment, outcome, observation, and imputation models fitted by {cmd:cdid}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 22 2}
{cmd:cdid_nuisance} [{it:component}] [{cmd:,} {opt block(id)}]

{p 8 8 2}
{it:component} is {opt selection}, {opt outcome}, {opt treatment}, or
{opt imputation}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_nuisance} reports the models that {helpb cdid} fitted to adjust the
effects: the observation logits of the correction for missing outcomes
({it:selection}), the regressions of the controls' outcome changes
({it:outcome}), the treatment propensity logits ({it:treatment}), and the
regressions that impute outcome changes ({it:imputation}). The reports
describe the fits that produced the estimates; nothing is refitted. It
corresponds to {cmd:nuisance_models()} of
{browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}.

{pstd}
A chained fit keeps reports when {cmd:cdid} is run with {opt keepnuisance}.
After an ordinary-mode fit or aggregation, {cmd:cdid_nuisance} returns
{cmd:r(status)} = {cmd:"unavailable"} and explains why in {cmd:r(reason)}.
Which components are reported depends on the specification. In chained fits
with same-pair comparisons, the observation logits are reported with
{cmd:selection(conditional_mtar)}, and the outcome, treatment, and imputation
models with {cmd:selmethod(dr)}; with {cmd:selection(none)} or
{cmd:selmethod(ipw)}, the outcome and treatment models of {opt method()} are
not reported.
Typed without a component, {cmd:cdid_nuisance} lists the fitted blocks of
every component and the status of each component. With a component, it
displays the equation and coefficient table of every block of that component;
{opt block()} selects one block. A component that the specification does not
use, or that is not reported for it, has a status and a reason instead of a
table.


{marker options}{...}
{title:Option}

{phang}
{opt block(id)} selects one block by its identifier ({cmd:S1}, {cmd:O2},
{cmd:T1}, {cmd:I3}, ...; after {cmd:preset(cohort_time_fe)},
{cmd:selection_1}, {cmd:calendar}, {cmd:treatment_1}, {cmd:imputation_1},
{cmd:roster}, ...), by its number within the component, or by its label.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Blocks.} A block is one fitted model. Observation logits have one block
per cohort and pair of dates ({cmd:selmodel(pair_logit)}) or per cohort and
date ({cmd:selmodel(independent_period_logit)}) with
{cmd:selpooling(separate)}; one block per cohort with {opt within_cohort}; and
a single block with {opt across_cohorts}, each with an intercept for every
cell. Outcome regressions have one block per pair of dates and control set
with {cmd:outcomepooling(separate)}, or a single block with common slopes with
{cmd:outcomepooling(pooled)}. Treatment logits have one block per target
cohort and control set. Imputation regressions follow {opt imppooling()}.

{pstd}
{bf:Cross-pair comparisons.} After {opt crosspair}, outcome blocks are
labeled by control cohort and pair, treatment blocks by target cohort and
control set, and imputation blocks by pooling group. After cross-pair fits
with covariates or weights that vary over time and an imputation or augmented
correction, the outcome, treatment, and imputation components are reported as
unavailable, as in R.

{pstd}
{bf:Binary treatment with entry and exit.} After {cmd:cdid} with {opt dvar()},
the treatment component has one switcher logit per cell, fitted on the
switchers and stayers; the outcome component has the stayer regressions; with
{cmd:selection(conditional_mtar)}, the selection and imputation components
follow {opt selpooling()} and {opt imppooling()}.

{pstd}
{bf:Cohort-by-date preset.} After {cmd:preset(cohort_time_fe)}, the outcome
component has one block, {cmd:calendar}, with the date and cohort-by-date
levels on the intercept and on the covariates, centered at their means in the
study population and divided by their largest absolute deviation; the lowest
level of each connected set is fixed at zero and has no standard error. The
treatment component has one logit of cohort membership per treated and donor
cohort. With {cmd:seluniverse(A)} or {cmd:seluniverse(B)}, the selection
component lists the selection blocks and then a {cmd:Roster probabilities}
table, returned in {cmd:r(roster)}; {cmd:block(roster)} returns it in
{cmd:r(table)}. Imputation slopes that are exact aliases on the prediction
rows are dropped, and the block lists the slopes kept.

{pstd}
{bf:Standard errors.} The standard errors of the coefficients come from the
influence function of each coefficient, the same influence functions that
enter the standard errors of the effects. Each unit of the study population
contributes one score; the variance is the centered sum of squared scores
divided by N^2, without a small-sample adjustment. With {opt cluster()}, the
scores are summed within clusters first. Coefficient standard errors can be
missing with {opt noinffunc} and with weightings other than {opt optimal}.

{pstd}
{bf:Lifetime.} The reports belong to the results that produced them: they are
available after {cmd:estimates restore}, written by {opt saving()} and
restored by {helpb cdid_load}. They are not reported while an {cmd:estat}
aggregation is the current result.


{marker examples}{...}
{title:Examples}

{pstd}Setup: outcomes missing more often when {cmd:z} is high{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20261116}{p_end}
{phang2}{cmd:. set obs 600}{p_end}
{phang2}{cmd:. generate id = _n}{p_end}
{phang2}{cmd:. generate G = cond(runiform() < .4, 0, cond(runiform() < .5, 2004, 2006))}{p_end}
{phang2}{cmd:. generate x = rnormal()}{p_end}
{phang2}{cmd:. generate z = rnormal()}{p_end}
{phang2}{cmd:. expand 8}{p_end}
{phang2}{cmd:. bysort id: generate year = 2000 + _n}{p_end}
{phang2}{cmd:. generate y = x + .2*(year - 2000) + (G > 0 & year >= G)*(1 + .25*(year - G)) + rnormal()}{p_end}
{phang2}{cmd:. replace y = . if runiform() < invlogit(-1.5 + z)}{p_end}

{pstd}Observation weighting with pooled slopes within cohort{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) selection(conditional_mtar) selcovars(x z) selpooling(within_cohort) bstrap(0) cband(0) keepnuisance}{p_end}
{phang2}{cmd:. cdid_nuisance}{p_end}
{phang2}{cmd:. cdid_nuisance selection, block(S1)}{p_end}
{phang2}{cmd:. matrix list r(table)}{p_end}

{pstd}All four components with the augmented correction{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) selection(conditional_mtar) selcovars(x z) selmethod(dr) selpooling(within_cohort) imppooling(within_cohort) bstrap(0) cband(0) keepnuisance}{p_end}
{phang2}{cmd:. cdid_nuisance treatment}{p_end}
{phang2}{cmd:. cdid_nuisance outcome, block(O1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_nuisance} stores the following in {cmd:r()}; the block results refer to the selected block:

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of units{p_end}
{synopt:{cmd:r(n_blocks)}}number of blocks{p_end}
{synopt:{cmd:r(n_units)}}units in the selected block{p_end}
{synopt:{cmd:r(n_fitting_rows)}}fitting rows of the selected block{p_end}
{synopt:{cmd:r(n_comparisons)}}comparisons that use the selected block{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(component)}}component displayed{p_end}
{synopt:{cmd:r(status)}}available, not_applicable, not_captured, or unavailable{p_end}
{synopt:{cmd:r(reason)}}why a component is not available{p_end}
{synopt:{cmd:r(status_component)}}status of each component, for example {cmd:r(status_selection)}{p_end}
{synopt:{cmd:r(method)}}treatment adjustment{p_end}
{synopt:{cmd:r(selmethod)}}correction for missing outcomes{p_end}
{synopt:{cmd:r(block)}}identifier of the selected block{p_end}
{synopt:{cmd:r(label)}}label of the selected block{p_end}
{synopt:{cmd:r(equation)}}equation of the selected block{p_end}
{synopt:{cmd:r(terms)}}labels of the coefficients of the selected block{p_end}
{synopt:{cmd:r(kept_slopes)}}slopes kept, after the preset{p_end}
{synopt:{cmd:r(aliased_slopes)}}slopes dropped as exact aliases, after the preset{p_end}
{synopt:{cmd:r(roster_terms)}}labels of {cmd:r(roster)}{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:r(blocks)}}one row per block: parameters, fitting rows, units or weights, comparisons, and related counts{p_end}
{synopt:{cmd:r(table)}}coefficients of the selected block, with standard errors, z statistics, p-values, and 95% confidence limits{p_end}
{synopt:{cmd:r(roster)}}roster probabilities, after the preset with seluniverse(A) or seluniverse(B){p_end}

{p2colreset}{...}

{pstd}
{cmd:r(N)} and {cmd:r(n_blocks)} are returned with the block summary of a
component; {cmd:r(n_units)}, {cmd:r(n_fitting_rows)}, {cmd:r(n_comparisons)},
and the other block results are returned when one block is displayed. A
component without a report returns only its status and reason.


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
