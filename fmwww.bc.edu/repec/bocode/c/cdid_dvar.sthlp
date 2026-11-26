{smcl}
{* *! version 1.0.0.1  17nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_nuisance" "help cdid_nuisance"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{viewerjumpto "Syntax" "cdid_dvar##syntax"}{...}
{viewerjumpto "Description" "cdid_dvar##description"}{...}
{viewerjumpto "Options" "cdid_dvar##options"}{...}
{viewerjumpto "Remarks" "cdid_dvar##remarks"}{...}
{viewerjumpto "Examples" "cdid_dvar##examples"}{...}
{viewerjumpto "Stored results" "cdid_dvar##results"}{...}
{viewerjumpto "References" "cdid_dvar##references"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{bf:cdid with dvar()} {hline 2}}Effects of a binary treatment that units enter and leave{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:cdid} {depvar} [{indepvars}] {ifin}{cmd:,}
{opt ivar(varname)} {opt time(varname)} {opt dvar(varname)} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opt ivar(varname)}}unit identifier{p_end}
{p2coldent :* {opt time(varname)}}numeric study date{p_end}
{p2coldent :* {opt dvar(varname)}}treatment status at each date, 0 or 1{p_end}
{synopt :{opt covars(varlist)}}covariates; alternative to {it:indepvars}{p_end}
{synopt :{opt method(string)}}{opt dr} (default), {opt ipw}, or {opt reg}{p_end}
{synopt :{opt switchers(string)}}{opt both} (default), {opt entry}, or {opt exit}{p_end}
{synopt :{opt switchtimes(numlist)}}dates of the requested transitions{p_end}
{synopt :{opt outcomepooling(string)}}{opt separate} (default), {opt pooled}, or blocks of cells{p_end}

{syntab:Missing outcomes}
{synopt :{opt selection(string)}}{opt none} (default) or {opt conditional_mtar}{p_end}
{synopt :{opt selmethod(string)}}{opt ipw} (default), {opt imputation}, or {opt dr}{p_end}
{synopt :{opt selmodel(string)}}{opt pair_logit} (default) or {opt independent_period_logit}{p_end}
{synopt :{opt selpooling(string)}}{opt separate} (default), {opt within_group}, or {opt pooled}{p_end}
{synopt :{opt imppooling(string)}}{opt separate} (default), {opt within_group}, or {opt pooled}{p_end}
{synopt :{opt impscale(string)}}{opt per_period} (default) or {opt per_change}{p_end}
{synopt :{opt selcovars(varlist)}}observation-model covariates; default: the outcome covariates{p_end}
{synopt :{opt selconstant}}intercept-only observation logits{p_end}
{synopt :{opt seluniverse(string)}}{opt F} (default), {opt B}, or {opt A}{p_end}
{synopt :{opt selrho(varname)}}known density ratio with {opt B} or {opt A}{p_end}
{synopt :{opt seljustification(string)}}stated justification, required with {opt B} or {opt A}{p_end}
{synopt :{opt missingref:erence(error)}}accepted; changes nothing{p_end}

{syntab:GMM}
{synopt :{opt gmmweighting(string)}}{opt optimal} (default), {opt two_step}, or {opt identity}{p_end}
{synopt :{opt gmmcovariance(string)}}{opt tikhonov} (default and only value){p_end}
{synopt :{opt condition(#)}}relative eigenvalue threshold; default {cmd:1e-10}{p_end}
{synopt :{opt ridge(#)}}relative Tikhonov multiplier; default {cmd:1e-4}{p_end}

{syntab:Inference}
{synopt :{opt cluster(varname)}}cluster variable; at least two clusters{p_end}
{synopt :{opt bstrap(#)}}{cmd:1} (default) multiplier bootstrap, {cmd:0} analytical{p_end}
{synopt :{opt cband(#)}}{cmd:1} (default) simultaneous bands over the cells, {cmd:0} pointwise{p_end}
{synopt :{opt biters(#)}}bootstrap draws; default {cmd:1000}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt noinffunc}}point estimates only{p_end}

{syntab:Other}
{synopt :{opt mode(chained)}}accepted; the only mode{p_end}
{synopt :{opt workspace(#)}}memory limit in bytes; default {cmd:1073741824}{p_end}
{synopt :{opt keepnuisance}}keep reports of the fitted models for {helpb cdid_nuisance}{p_end}
{synoptline}
{p 4 6 2}* {opt ivar()}, {opt time()}, and {opt dvar()} are required. Weights and {opt gvar()} are not allowed.{p_end}
{p 4 6 2}{it:indepvars}, {opt covars()}, and {opt selcovars()} may contain factor variables; see {help fvvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
With {opt dvar()} in place of {opt gvar()}, {helpb cdid} estimates the effects
of a binary treatment that units may enter, leave, and enter again, under a
static model: outcomes depend on current treatment status only, and past
treatment has no carryover. {it:varname} records each unit's status at every
date.

{pstd}
For a date {it:t} after the first and a prior status {it:d}, the switchers are
the units with status {it:d} at {it:t}-1 and 1-{it:d} at {it:t}, and the
stayers are the units with status {it:d} at both dates. Each cell compares the
mean outcome change of the switchers from {it:t}-1 to {it:t} with that of the
stayers. Entrants are compared with units that stay untreated, exiters with
units that stay treated, and the sign of the exit contrast is reversed, so
that every effect is reported on the same treated-minus-untreated scale. Here
{it:t}-1 denotes the study date preceding {it:t}, not necessarily the numeric
date minus one.
Identification also requires parallel trends and support for each entry or
exit comparison. The reported average weights the cell effects by their
numbers of switchers.

{pstd}
This design corresponds to {cmd:att_gt(dname = ...)} of
{browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}. It adapts the static binary specialization of
de Chaisemartin, D'Haultfoeuille, Pasquier, Sow, and Vazquez-Bare (2026) to
complete and incomplete panels.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt dvar(varname)} is the treatment status, 0 or 1, with no missing values:
one row for every unit at every date, including dates with missing outcomes.

{phang}
{opt method(dr|ipw|reg)}: {opt ipw} reweights the stayers by the odds of a
logit of switching on the covariates, fitted on the switchers and stayers of
the cell; {opt reg} removes from each change the prediction of a least-squares
regression of the stayers' changes on the covariates; {opt dr} (the default)
combines both. Covariates enter at {it:t}-1 and may vary over time.

{phang}
{opt switchers(both|entry|exit)} requests entries (0 to 1), exits (1 to 0), or
both.

{phang}
{opt switchtimes(numlist)} lists the dates {it:t} of the requested cells. By
default, the requested cells are those with at least one switcher in the
requested directions. A listed date without switchers is reported as an
unavailable cell, and the average is then not reported.

{phang}
{opt outcomepooling()}: with {opt separate} (the default), each cell has its
own stayer regression; with {opt pooled}, the regression has an intercept for
each requested cell and slopes common to all of them.
{cmd:outcomepooling(}{it:block} [{cmd:|} {it:block} ...]{cmd:)} partitions the
cells into blocks with common slopes; a {it:block} lists cells written
{cmd:entry:}{it:date} or {cmd:exit:}{it:date}, for example
{cmd:outcomepooling(entry:2003 entry:2004 | exit:2003 exit:2004)}. Every
requested cell must belong to exactly one block. In complete panels, a block
may also list cells that are not requested; their stayers then contribute only
to the fit of the slopes.

{dlgtab:Missing outcomes}

{phang}
{opt selection(conditional_mtar)} lets the probability that outcomes are
observed depend on the covariates at {it:t}-1 within each role.
{opt selmethod(ipw)} (the default) weights each unit observed at both dates of
a pair by the inverse of its fitted probability of being observed at both
dates, from {cmd:selmodel(pair_logit)} (the default) or the product of logits
for the two dates ({cmd:selmodel(independent_period_logit)});
{opt selmethod(imputation)} replaces the change of every unit of the role by
its prediction from a regression of the observed changes on the covariates;
{opt selmethod(dr)} adds the inverse-probability-weighted residuals of the
observed pairs. {opt imputation} and {opt dr} require
{cmd:selection(conditional_mtar)}.

{phang}
{opt selpooling()} and {opt imppooling()} set the slopes shared by the
observation logits and imputation regressions: {opt separate} (each role and
pair), {opt within_group} (each role of a transition), or {opt pooled} (all),
each with its own intercepts. {cmd:impscale(per_period)} multiplies the
covariates of a pair by its number of periods; {cmd:impscale(per_change)} does
not.

{phang}
{opt selcovars()} and {opt selconstant} cannot be combined.
{cmd:seluniverse(B)} and {cmd:seluniverse(A)} fit the pair logits on the units
with at least one or at least two observed outcomes; they require
{cmd:selection(conditional_mtar)}, {cmd:selmethod(ipw)},
{cmd:selmodel(pair_logit)}, and {opt seljustification()}.
{opt selrho(varname)} optionally supplies the known density ratio of the
covariates in the fitting units to those in the study population, within the
switcher and stayer groups; its values must be positive.

{phang}
{opt missingreference(error)} is accepted and changes nothing;
{cmd:missingreference(exclude)} is refused, because covariates are required at
{it:t}-1 for the units at risk of switching at {it:t}.

{dlgtab:GMM and inference}

{phang}
{opt gmmweighting()}, {opt gmmcovariance()}, {opt condition()}, and
{opt ridge()} apply when outcomes are missing and comparisons are chained; see
{helpb cdid}. {cmd:gmmweighting(within)} is not available.

{phang}
{opt cluster()}, {opt bstrap()}, {opt cband()}, {opt biters()}, {opt level()},
and {opt noinffunc} are as for {helpb cdid}. The analytical standard errors sum
the influence functions of the original units within clusters. Simultaneous
bands cover the requested cells. When a requested cell is unavailable or the
bootstrap draws are degenerate, pointwise intervals are reported instead;
{cmd:e(band_status)} records which case applies ({cmd:ok},
{cmd:unavailable_target_cell}, {cmd:unavailable_degenerate_family}, or
{cmd:not_requested}).

{phang}
{opt keepnuisance} keeps the fitted switcher logits, stayer regressions,
observation logits, and imputation regressions for {helpb cdid_nuisance}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Missing outcomes.} When outcomes are missing, the change of each role from
{it:t}-1 to {it:t} is chained through the dates at which its units are
observed: for each requested cell and role, every pair of dates at which some
units of the role are observed gives a mean change, and the levels of every
role are estimated jointly by GMM. Under {cmd:selection(none)}, the units
observed at a pair of dates are assumed to have the expected change of their
role. A cell is unavailable when the observed dates of its switchers or of its
stayers do not connect {it:t}-1 and {it:t}.

{pstd}
With {cmd:selmethod(ipw)} or {cmd:selmethod(dr)}, the observation logit needs
a finite solution. A cell with every outcome observed or every outcome missing
has no finite intercept. A selection covariate can also separate observed and
unobserved units and prevent a finite solution. For direct-pair logits,
the response indicates whether both outcomes are observed. For independent-date
logits, the response indicates whether the outcome at that date is observed.

{pstd}
{bf:Input.} {opt dvar()} needs a row for every unit at every date and a
treatment status in every row. Covariates must be nonmissing at {it:t}-1 for
the units at risk of switching at {it:t}; outcomes may be missing. Weights,
{opt saving()}, {opt crosspair}, {opt controlgroup()}, {opt ptassumption()},
{opt anticipation()}, {cmd:method(custom)}, and the other options of
{helpb cdid} that are not listed above are refused. Absorbing data supplied
through {opt dvar()} still request the static model.

{pstd}
{bf:After estimation.} {helpb cdid_export} saves {cmd:type(cells)} and
{cmd:type(aggregate)}, and {helpb cdid_nuisance} reports the fitted models
after {opt keepnuisance}. The switcher-weighted average is stored in
{cmd:e(att)} and {cmd:e(se_att)}; {cmd:estat} stops with a message that points
to them. {helpb cdid_plot}, {helpb cdid_diagnostics}, and {helpb cdid_chain}
are not available. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/switching.md":When treatment can stop and restart}.


{marker examples}{...}
{title:Examples}

{pstd}Setup: treatment status drawn at every date{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2027}{p_end}
{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. generate long id = _n}{p_end}
{phang2}{cmd:. generate double x = rnormal()}{p_end}
{phang2}{cmd:. expand 6}{p_end}
{phang2}{cmd:. bysort id: generate year = 2000 + _n}{p_end}
{phang2}{cmd:. generate byte treated = runiform() < invlogit(-1 + .5*x)}{p_end}
{phang2}{cmd:. generate double y = 0.3*(year - 2000) + 0.5*x + treated + rnormal()}{p_end}

{pstd}Entry and exit effects{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) dvar(treated)}{p_end}

{pstd}Entries only, with analytical standard errors{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) dvar(treated) switchers(entry) bstrap(0) cband(0)}{p_end}

{pstd}Outcomes missing more often when {cmd:x} is high, with the augmented correction{p_end}
{phang2}{cmd:. replace y = . if runiform() < invlogit(-2 + x)}{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) dvar(treated) selection(conditional_mtar) selmethod(dr) bstrap(0) cband(0) keepnuisance}{p_end}
{phang2}{cmd:. cdid_nuisance}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid} with {opt dvar()} stores the following in {cmd:e()}:

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of units{p_end}
{synopt:{cmd:e(T)}}number of dates{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters, with cluster(){p_end}
{synopt:{cmd:e(att)}}switcher-weighted average effect{p_end}
{synopt:{cmd:e(se_att)}}its reported standard error{p_end}
{synopt:{cmd:e(se_att_analytic)}}its analytical standard error{p_end}
{synopt:{cmd:e(se_att_bootstrap)}}its bootstrap standard error{p_end}
{synopt:{cmd:e(n_switchers)}}number of switchers in the requested cells{p_end}
{synopt:{cmd:e(N_missing)}}number of missing outcomes{p_end}
{synopt:{cmd:e(critical_value)}}critical value of the reported intervals or band{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(alpha)}}1 - {cmd:e(level)}/100{p_end}
{synopt:{cmd:e(biters)}}bootstrap draws requested (biters()){p_end}
{synopt:{cmd:e(draws)}}1 if bootstrap draws were used{p_end}

{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}cdid{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title of the output{p_end}
{synopt:{cmd:e(design)}}static{p_end}
{synopt:{cmd:e(mode)}}chained{p_end}
{synopt:{cmd:e(depvar)}}outcome{p_end}
{synopt:{cmd:e(ivar)}}unit identifier{p_end}
{synopt:{cmd:e(time)}}date variable{p_end}
{synopt:{cmd:e(dvar)}}treatment status variable{p_end}
{synopt:{cmd:e(covariates)}}covariates{p_end}
{synopt:{cmd:e(method)}}treatment adjustment{p_end}
{synopt:{cmd:e(switchers)}}both, entry, or exit{p_end}
{synopt:{cmd:e(switchtimes)}}dates of switchtimes(), when specified{p_end}
{synopt:{cmd:e(outcome_pooling)}}outcome-regression pooling{p_end}
{synopt:{cmd:e(gmm_weighting)}}GMM weighting, with missing outcomes or selection(){p_end}
{synopt:{cmd:e(selection)}}assumption about missing outcomes{p_end}
{synopt:{cmd:e(selection_est_method)}}correction for missing outcomes, when it applies{p_end}
{synopt:{cmd:e(selection_model)}}observation model, when it applies{p_end}
{synopt:{cmd:e(selection_pooling)}}observation-model pooling, when it applies{p_end}
{synopt:{cmd:e(selection_universe)}}units that fit the observation model, when it applies{p_end}
{synopt:{cmd:e(selection_rho)}}density-ratio variable, when specified{p_end}
{synopt:{cmd:e(selection_justification)}}text of seljustification(), when specified{p_end}
{synopt:{cmd:e(selection_covariates)}}observation-model covariates, when they apply{p_end}
{synopt:{cmd:e(imputation_pooling)}}imputation pooling, when it applies{p_end}
{synopt:{cmd:e(imputation_scale)}}imputation scaling, when it applies{p_end}
{synopt:{cmd:e(vce)}}analytic, bootstrap, or none{p_end}
{synopt:{cmd:e(vcetype)}}Bootstrap, with the multiplier bootstrap{p_end}
{synopt:{cmd:e(band)}}pointwise or simultaneous{p_end}
{synopt:{cmd:e(band_status)}}ok, not_requested, unavailable_target_cell, or unavailable_degenerate_family{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable, with cluster(){p_end}
{synopt:{cmd:e(nuisance)}}availability of the reports kept, with keepnuisance{p_end}
{synopt:{cmd:e(state_token)}}reference to the kept reports, with keepnuisance{p_end}
{synopt:{cmd:e(estat_cmd)}}cdid_estat{p_end}
{synopt:{cmd:e(properties)}}b V, or b with noinffunc{p_end}

{p2col 5 30 34 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimable cell effects, named direction:tdate (for example {cmd:_b[entry:t2003]}){p_end}
{synopt:{cmd:e(V)}}analytical covariance of {cmd:e(b)}, unless noinffunc{p_end}
{synopt:{cmd:e(cells)}}one row per requested cell; see the column definitions below{p_end}

{p2col 5 30 34 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the observations used{p_end}

{p2colreset}{...}

{pstd}
{cmd:e(b)} and {cmd:e(V)} are not posted when no requested cell is available. The columns of {cmd:e(cells)} are: time, the date t; tprev, the preceding study date; d, the treatment status before the switch (0 for entries, 1 for exits); sign, the sign applied to the switcher-stayer contrast (1 for entries, -1 for exits); available, 1 if the cell is estimated; switchers and stayers, the numbers of units; att, the cell effect; theta, the switcher-stayer contrast before the sign is applied; se, lower and upper, the reported standard error and interval limits; analytic_se and bootstrap_se; and status, 0 when the cell is available, 1 with no switchers, 2 with no stayers, 3 when the observed dates of the switchers do not connect the preceding date and t, and 4 when those of the stayers do not.


{marker references}{...}
{title:References}

{phang}
de Chaisemartin, C., X. D'Haultfoeuille, F. Pasquier, D. Sow, and
G. Vazquez-Bare. 2026. Difference-in-differences estimators for treatments
continuously distributed at every period. Working paper, arXiv:2201.06898v7.
{browse "https://arxiv.org/abs/2201.06898v7"}.


{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
