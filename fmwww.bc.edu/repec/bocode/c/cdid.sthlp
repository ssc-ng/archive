{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid postestimation" "help cdid_postestimation"}{...}
{vieweralsosee "cdid with dvar()" "help cdid_dvar"}{...}
{vieweralsosee "cdid_custom" "help cdid_custom"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "cdid_pretest" "help cdid_pretest"}{...}
{vieweralsosee "cdid_chain" "help cdid_chain"}{...}
{vieweralsosee "cdid_nuisance" "help cdid_nuisance"}{...}
{vieweralsosee "cdid_diagnostics" "help cdid_diagnostics"}{...}
{vieweralsosee "cdid_plot" "help cdid_plot"}{...}
{vieweralsosee "cdid_export" "help cdid_export"}{...}
{vieweralsosee "cdid_load" "help cdid_load"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[CAUSAL] hdidregress" "help hdidregress"}{...}
{viewerjumpto "Syntax" "cdid##syntax"}{...}
{viewerjumpto "Description" "cdid##description"}{...}
{viewerjumpto "Options" "cdid##options"}{...}
{viewerjumpto "Remarks" "cdid##remarks"}{...}
{viewerjumpto "Examples" "cdid##examples"}{...}
{viewerjumpto "Stored results" "cdid##results"}{...}
{viewerjumpto "References" "cdid##references"}{...}
{viewerjumpto "Author" "cdid##author"}{...}
{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{cmd:cdid} {hline 2}}Chained difference-in-differences for staggered adoption in complete and incomplete panels{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Staggered adoption: cohorts defined by the first treatment date

{p 8 13 2}
{cmd:cdid} {depvar} [{indepvars}] {ifin} [{it:{help cdid##weight:iweight}}]{cmd:,}
{opt ivar(varname)} {opt time(varname)} {opt gvar(varname)} [{it:options}]

{pstd}
Binary treatment that units may enter and leave; see {helpb cdid_dvar:cdid with dvar()}

{p 8 13 2}
{cmd:cdid} {depvar} [{indepvars}] {ifin}{cmd:,}
{opt ivar(varname)} {opt time(varname)} {opt dvar(varname)} [{it:dvar_options}]

{pstd}
Replay the current results

{p 8 13 2}
{cmd:cdid}

{pstd}
Aggregate, test, inspect, plot, export, or save the results: see
{helpb cdid_postestimation:cdid postestimation}.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opt ivar(varname)}}unit identifier{p_end}
{p2coldent :* {opt time(varname)}}numeric study date{p_end}
{p2coldent :* {opt gvar(varname)}}first treatment date; {cmd:0} for never-treated units{p_end}
{synopt :{opt covars(varlist)}}covariates; alternative to {it:indepvars}{p_end}
{synopt :{opt nocons:tant}}omit the intercept from the treatment and outcome models{p_end}
{synopt :{opt method(string)}}treatment adjustment: {opt dr} (default), {opt ipw}, {opt reg}, or {opt custom}{p_end}
{synopt :{opt outcomepooling(string)}}{opt separate} (default) or {opt pooled} outcome regressions{p_end}
{synopt :{opt callback(name)}}Mata function for {cmd:method(custom)}{p_end}
{synopt :{opt payload(name)}}Mata object passed to the callback{p_end}
{synopt :{opt missingref:erence(string)}}covariate missing at a reference date: {opt exclude} (default) or {opt error}{p_end}

{syntab:Comparisons and parallel trends}
{synopt :{opt control:group(string)}}{opt nevertreated} (default) or {opt notyettreated}{p_end}
{synopt :{opt anticip:ation(#)}}periods of anticipation; default {cmd:0}{p_end}
{synopt :{opt base:period(string)}}reporting of pretreatment cells: {opt varying} (default) or {opt universal}{p_end}
{synopt :{opt ptassumption(string)}}{opt post} (default), {opt ctrl}, or {opt all}{p_end}
{synopt :{opt ptstart(#)}}first date of the {opt all} or {opt ctrl} restrictions{p_end}
{synopt :{opt targetcohorts(numlist)}}estimate effects for these treated cohorts only{p_end}
{synopt :{opt targets(matname)}}target cohorts given as a one-column matrix{p_end}
{synopt :{opt cross:pair}}link separate within-unit changes of target and control cohorts{p_end}
{synopt :{opt preset(cohort_time_fe)}}linear cohort-by-date fixed-effects specification{p_end}

{syntab:Missing outcomes}
{synopt :{opt selection(string)}}{opt none} (default) or {opt conditional_mtar}{p_end}
{synopt :{opt selmethod(string)}}{opt ipw} (default), {opt imputation}, or {opt dr}{p_end}
{synopt :{opt selmodel(string)}}{opt pair_logit} (default) or {opt independent_period_logit}{p_end}
{synopt :{opt selpooling(string)}}{opt separate} (default), {opt within_cohort}, or {opt across_cohorts}{p_end}
{synopt :{opt imppooling(string)}}{opt separate} (default), {opt within_cohort}, or {opt across_cohorts}{p_end}
{synopt :{opt selcovars(varlist)}}observation-model covariates; default: the outcome covariates{p_end}
{synopt :{opt selnocons:tant}}omit the intercept from the observation logits{p_end}
{synopt :{opt selcons:tant}}intercept-only observation logits{p_end}
{synopt :{opt selzero}}observation logits with no parameters{p_end}
{synopt :{opt seluniverse(string)}}units that fit the observation model: {opt F} (default), {opt B}, or {opt A}{p_end}
{synopt :{opt selrho(varname)}}known density ratio for {opt B} or {opt A}{p_end}
{synopt :{opt seljustification(string)}}stated justification, required with {opt B} or {opt A}{p_end}

{syntab:Study population and weights}
{synopt :{opt frame(name)}}frame with one row per unit of the study population{p_end}
{synopt :{opt frameivar(name)}}unit identifier in {opt frame()}; default: the {opt ivar()} name{p_end}
{synopt :{opt framegvar(name)}}first treatment date in {opt frame()}{p_end}
{synopt :{opt framecovars(varlist)}}covariates in {opt frame()}{p_end}
{synopt :{opt frameselcovars(varlist)}}observation-model covariates in {opt frame()}{p_end}
{synopt :{opt framewvar(name)}}sampling weights in {opt frame()}{p_end}
{synopt :{opt framecluster(name)}}cluster variable in {opt frame()}{p_end}
{synopt :{opt wvar(varname)}}sampling weights; alternative to {cmd:iweight}s{p_end}
{synopt :{opt fixweights(string)}}{opt first_period} or {opt base_period} when weights vary within units{p_end}

{syntab:GMM}
{synopt :{opt gmmweighting(string)}}{opt optimal} (default), {opt two_step}, {opt within}, or {opt identity}{p_end}
{synopt :{opt gmmcovariance(string)}}{opt tikhonov} (default and only value){p_end}
{synopt :{opt condition(#)}}relative eigenvalue threshold; default {cmd:1e-10}{p_end}
{synopt :{opt ridge(#)}}relative Tikhonov multiplier; default {cmd:1e-4}{p_end}

{syntab:Inference}
{synopt :{opt cluster(varname)}}cluster variable; units nested in clusters{p_end}
{synopt :{opt bstrap(#)}}{cmd:1} (default) multiplier bootstrap, {cmd:0} analytical standard errors{p_end}
{synopt :{opt cband(#)}}{cmd:1} (default) simultaneous bands, {cmd:0} pointwise intervals{p_end}
{synopt :{opt biters(#)}}bootstrap draws; default {cmd:1000}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt noinffunc}}point estimates only{p_end}

{syntab:Mode}
{synopt :{opt mode(string)}}{opt chained} (default with panel data) or {opt ordinary}{p_end}
{synopt :{opt rcs}}repeated cross sections; implies {cmd:mode(ordinary)}{p_end}
{synopt :{opt panel(string)}}{opt true} or {cmd:1}; redundant in chained mode{p_end}
{synopt :{opt allowunbalanced}[{cmd:(}{it:string}{cmd:)}]}keep units not observed at every date in ordinary mode{p_end}

{syntab:Computation}
{synopt :{opt workspace(#)}}memory limit in bytes; default {cmd:1073741824}{p_end}
{synopt :{opt chunk(#)}}rows per processing block; default automatic (1024 in ordinary mode){p_end}
{synopt :{opt workcap(#)}}limit on counted operations; default none{p_end}

{syntab:Reporting and saving}
{synopt :{opt posting(string)}}{opt matrix} (default) or {opt state}{p_end}
{synopt :{opt saving(filename)}}save the complete results for {helpb cdid_load}{p_end}
{synopt :{opt keepnuisance}}keep reports of the fitted models for {helpb cdid_nuisance}{p_end}
{synoptline}
{p 4 6 2}* {opt time()} and {opt gvar()} are required. {opt ivar()} is required in chained mode and may be omitted with {opt rcs}.{p_end}
{marker weight}{...}
{p 4 6 2}{cmd:iweight}s are allowed and are equivalent to {opt wvar()}; specify one or the other. See {help weight}.{p_end}
{p 4 6 2}{it:indepvars}, {opt covars()}, and {opt selcovars()} may contain factor variables; see {help fvvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid} estimates group-time average treatment effects on the treated,
ATT({it:g},{it:t}): the average effect at date {it:t} on the units first treated
at date {it:g}, in designs where units adopt the treatment at different dates
and remain treated. It implements the chained difference-in-differences
estimator of Bellégo, Benatia, and Dortet-Bernadet (2025) within the framework
of Callaway and Sant'Anna (2021).

{pstd}
In chained mode, the default, each unit contributes the changes of its outcome
between the dates at which it is observed, so the panel need not be complete.
These comparisons are combined by the generalized method of moments (GMM). The
targets remain the effects on the cohorts of the study population, including
units whose outcomes are missing at some dates (except that, under the default
{cmd:missingreference(exclude)}, a cohort whose treated units lack a required
reference covariate is estimated for its eligible treated units); the assumptions concern the
missing changes rather than the missing levels. An effect that the observed
comparisons cannot recover is reported as unavailable, with a reason, and is
never set to zero.

{pstd}
The treatment adjustment ({opt method()}) and the adjustment for missing
outcomes ({opt selection()} and {opt selmethod()}) are chosen separately.
Ordinary mode ({cmd:mode(ordinary)} or {opt rcs}) estimates the effects of
Callaway and Sant'Anna (2021) on units observed at every date or on repeated
cross sections. A binary treatment that units can enter and leave is estimated
with {opt dvar()}; see {helpb cdid_dvar:cdid with dvar()}.

{pstd}
{cmd:cdid} corresponds to the function {cmd:att_gt()} of {browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}; see
{help cdid##remarks_r:Correspondence with R}.


{marker options}{...}
{title:Options}

{pstd}
Options are grouped as in the syntax table. Unless stated otherwise, they apply
to chained mode; {help cdid##opt_mode:Mode} lists the options that ordinary
mode accepts.

{marker opt_model}{...}
{dlgtab:Model}

{phang}
{opt ivar(varname)} identifies units. It may be numeric or string in chained
mode; ordinary mode requires a numeric identifier, except with {opt rcs}, where
{opt ivar()} may be omitted. Each unit appears at most
once per date.

{phang}
{opt time(varname)} is the numeric study date. Dates need not be consecutive
integers. Anticipation, reference dates, and the event time of
{cmd:estat dynamic} use the date values; the pooled models and the {opt maxe()}
horizon of {cmd:estat simple} and {cmd:estat group} count steps in positions of
the sorted study dates.

{phang}
{opt gvar(varname)} is the date at which a unit is first treated, constant
within unit, nonnegative, and nonmissing. Code never-treated units {cmd:0}.

{phang}
{it:indepvars} or {opt covars(varlist)} specify the covariates of the treatment
and outcome models; specify one or the other. Factor-variable notation
({cmd:i.}, {cmd:ib}{it:#}{cmd:.}, {cmd:#}, {cmd:##}) is accepted; base and
omitted levels are dropped, and the remaining indicator columns correspond to
R's {cmd:factor()} treatment contrasts with the same base. A factor interacted
with a continuous covariate without the factor's main effect, {cmd:i.cf#c.x} (or
{cmd:ibn.cf#c.x}), has one slope per level, as R's {cmd:factor(cf):x};
{cmd:c.x i.cf#c.x} corresponds to R's {cmd:x + factor(cf):x}. Covariates may be
constant within units or vary over time; see
{help cdid##remarks_reference:Covariates that vary over time}.

{phang}
{opt noconstant} omits the intercept from the treatment and outcome designs,
including with {opt crosspair}.

{phang}
{opt method(string)} selects the treatment adjustment: {opt dr}, doubly robust
(the default); {opt ipw}, inverse probability weighting; {opt reg}, regression
of the controls' outcome changes; or {opt custom}, a Mata function named in
{opt callback()} ({help cdid_custom}).

{phang}
{opt outcomepooling(separate|pooled)} applies to {cmd:method(reg)} and
{cmd:method(dr)}. {opt separate} (the default) fits one regression of the
controls' outcome changes for each distinct comparison; {opt pooled} shares
slopes, scaled by the length of each comparison, across comparisons, with local
intercepts.

{phang}
{opt callback(name)} and {opt payload(name)} name the Mata function and the
optional Mata object used by {cmd:method(custom)}; see {help cdid_custom}.

{phang}
{opt missingreference(exclude|error)} sets what happens when a covariate that
varies over time is missing at the date where a cohort's comparisons read it.
Weights are not covered: with {opt fixweights()}, every unit used needs a
positive weight at its anchor date, whatever {opt missingreference()} says. {opt exclude} (the default) warns and excludes the
affected units from that cohort's comparisons only; {opt error} stops with
error 459 and lists up to five missing values. When no required value is
missing, both give the same results. The option is not available as
{opt exclude} with {opt preset()} or {opt dvar()} and is ignored in ordinary
mode. See {help cdid##remarks_reference:Covariates that vary over time}.

{marker opt_comparisons}{...}
{dlgtab:Comparisons and parallel trends}

{phang}
{opt controlgroup(nevertreated|notyettreated)} selects the comparison units:
never-treated units (the default), or never-treated units together with the
units not yet treated at the dates compared.

{phang}
{opt anticipation(#)} allows treatment to affect outcomes {it:#} periods before
adoption. The reference date of cohort {it:g} is the latest study date {it:d}
with {it:d} + {it:#} < {it:g}.

{phang}
{opt baseperiod(varying|universal)} sets how pretreatment cells are reported:
{opt varying} compares each pretreatment date with the preceding study date;
{opt universal} compares each with the cohort's reference date. It changes
the reporting, not the assumption.

{phang}
{opt ptassumption(post|ctrl|all)} sets the parallel trends assumption.
{opt post} (the default) assumes parallel trends from each cohort's reference
date onward. {opt ctrl} adds common untreated trends among the clean control
cohorts from {opt ptstart()} (by default from the first date); the target
cohort's own pretreatment trend stays unrestricted. {opt all} adds parallel
trends of the target and its controls from {opt ptstart()} up to the reference
date, so that earlier dates can serve as baselines; {opt ptstart()} is then
required. Valid added restrictions can make more effects available or improve
precision; neither gain is guaranteed, and false restrictions bias the
estimates.

{phang}
{opt ptstart(#)} is a study date. It is required with {cmd:ptassumption(all)},
optional with {cmd:ptassumption(ctrl)}, and not allowed with
{cmd:ptassumption(post)}.

{phang}
{opt targetcohorts(numlist)} or {opt targets(matname)} restrict the target
cohorts; specify one or the other. By default, every treated cohort whose
treatment date is on or before the last study date is a target; the effects of
a cohort {it:g} with no study date {it:d} such that {it:d} + anticipation <
{it:g} are reported as unavailable.

{phang}
{opt crosspair} estimates each ATT({it:g},{it:t}) from separate within-unit
changes of the target cohort and of each clean control cohort, linked through
calendar dates by GMM, rather than from comparisons on date pairs observed in
both. It can identify effects without a shared observed date pair when the
linked comparisons identify the requested contrast. See {help cdid##remarks_crosspair:Cross-pair comparisons}.

{phang}
{opt preset(cohort_time_fe)} requests the linear cohort-by-date fixed-effects
specification; see {help cdid##remarks_preset:Cohort-by-date preset}.

{marker opt_selection}{...}
{dlgtab:Missing outcomes}

{phang}
{opt selection(none|conditional_mtar)} states the assumption about missing
outcomes. {opt none} (the default) fits no observation model and requires the
units observed at both dates of a comparison to be representative of their
cohort's mean change over that pair. {opt conditional_mtar} allows observation
to depend on covariates and adjusts for it; {opt corollary1} is a synonym.

{phang}
{opt selmethod(ipw|imputation|dr)} chooses the adjustment under
{cmd:selection(conditional_mtar)}: observation weighting ({opt ipw}, the
default), which weights each observed change by the inverse of its fitted
probability of being observed at both dates; change imputation
({opt imputation}), which predicts the changes with regressions fitted to the
observed changes; or the augmented correction ({opt dr}), which combines the
two. All three work with {cmd:method(ipw)}, {cmd:method(reg)}, and
{cmd:method(dr)}. {cmd:method(custom)} supports {cmd:selmethod(ipw)} only.

{phang}
{opt selmodel(pair_logit|independent_period_logit)} specifies the observation
model: a logit for observing both dates of a pair (the default), or the product
of logits for each date, which assumes conditionally independent observation
at the two dates.

{phang}
{opt selpooling()} and {opt imppooling()} set whether the slopes of the
observation logits and of the imputation regressions are separate for each
cell ({opt separate}, the default), shared within cohort
({opt within_cohort}), or shared across cohorts ({opt across_cohorts}). Each
cell keeps its own intercept.

{phang}
{opt selcovars(varlist)} gives the observation model its own covariates; by
default they are the outcome covariates. {opt selnoconstant} omits the
intercept; {opt selconstant} fits intercepts only and cannot be combined with
{opt selcovars()}, {opt frameselcovars()}, {opt selnoconstant}, or
{opt selzero}; {opt selzero} uses no observation design.

{phang}
{opt seluniverse(F|B|A)} sets the units that fit the observation model: the
study population ({opt F}, the default), the units with at least one observed
outcome ({opt B}), or with at least two ({opt A}). {opt B} and {opt A} require
{cmd:selmethod(ipw)}, {cmd:selmodel(pair_logit)}, and
{opt seljustification()}; {opt selrho(varname)} supplies the known density
ratio of the covariates in the fitting units to those in the study population,
within each cohort; its values must be positive. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/sampling-information.md":Sampling information}.

{marker opt_population}{...}
{dlgtab:Study population and weights}

{phang}
{opt frame(name)} names a frame with one row per unit of the study population,
including units with one or no observed outcome. Without it, the units in the
data form the study population. {opt frameivar()} defaults to the
{opt ivar()} name. {opt framegvar()}, {opt framecovars()},
{opt frameselcovars()}, {opt framewvar()}, and {opt framecluster()} are not
inherited from same-named frame variables: name them to read cohorts,
covariates, weights, or clusters from the frame.

{phang}
{opt wvar(varname)} or {cmd:iweight}s specify positive sampling weights,
constant within unit unless {opt fixweights()} is given.
{opt fixweights(first_period)} uses each unit's weight at the first study date,
where it must be observed; {opt fixweights(base_period)} uses its weight at
each target cohort's reference date. Weights are not allowed with
{opt preset()}.

{marker opt_gmm}{...}
{dlgtab:GMM}

{phang}
{opt gmmweighting(optimal|two_step|within|identity)} selects the weighting
matrix that combines the comparisons: the inverse of their estimated covariance
({opt optimal}, the default; {opt two_step} is a synonym), the inverse of the
analytical covariance of within-unit changes under uncorrelated level shocks
({opt within}), or the identity matrix. {opt within} is available with or
without {opt selection()} and with every {opt selmethod()}, but not with
{cmd:method(custom)}; with {opt selection()}, {cmd:outcomepooling(pooled)}, or
covariates that vary over time it requires a constant in the covariate design.
Inference always uses the estimated influence functions.

{phang}
{opt gmmcovariance(tikhonov)}, {opt condition(#)}, and {opt ridge(#)} control
the regularization of the estimated moment covariance when its relative
smallest eigenvalue falls below {opt condition()}. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/gmm.md":GMM weighting}.

{marker opt_inference}{...}
{dlgtab:Inference}

{phang}
{opt cluster(varname)} clusters at a level at or above the unit; each unit
belongs to one cluster. Clustering does not change point estimates.

{phang}
{opt bstrap(#)}, {opt cband(#)}, and {opt biters(#)} control the multiplier
bootstrap. With {cmd:bstrap(1)}, the default, standard errors come from
{opt biters()} draws and, with {cmd:cband(1)}, the bands hold simultaneously
over the reported effects. With {cmd:bstrap(0)}, standard errors are analytical
and intervals pointwise. Use {helpb set seed} for reproducible draws.

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.

{phang}
{opt noinffunc} computes point estimates only. No standard errors are
reported, and {cmd:estat} aggregations, which need the influence functions,
are refused.

{marker opt_mode}{...}
{dlgtab:Mode}

{phang}
{opt mode(chained|ordinary)} selects the estimator. Ordinary mode uses the
{cmd:csdid} 2.0.2 package (Callaway, Rios-Avila, and Sant'Anna), installed
separately. For panel data it requires a numeric {opt ivar()}. It takes
covariates from the varlist and refuses {opt covars()}, {opt noconstant},
{opt panel()}, {opt frame()}, and its associated options. See
{help cdid##remarks_ordinary:Ordinary mode}.

{phang}
{opt rcs} requests repeated cross sections and implies ordinary mode;
{cmd:mode(chained)} with {opt rcs} is refused.

{phang}
{opt panel(true)} or {cmd:panel(1)} is accepted in chained mode and changes
nothing.

{phang}
{opt allowunbalanced}, alone or as {cmd:allowunbalanced(true)}, keeps, in
ordinary mode, the units not observed at every date; these data are then
analyzed with repeated cross-section estimators. In chained mode, units with
gaps are always used, and {cmd:allowunbalanced(false)} is refused. In ordinary
mode, {opt fixweights()} also accepts {opt varying}.

{marker opt_computation}{...}
{dlgtab:Computation}

{phang}
{opt workspace(#)}, {opt chunk(#)}, and {opt workcap(#)} limit memory and
computation; a fit that would exceed a limit is refused rather than
truncated.

{marker opt_reporting}{...}
{dlgtab:Reporting and saving}

{phang}
{opt posting(matrix|state)}. {opt matrix} (the default) posts the available
estimates in {cmd:e(b)} and their covariance in {cmd:e(V)}. {opt state} keeps
the complete results for {cmd:estat}, {helpb cdid_export}, and
{helpb cdid_plot} without posting {cmd:e(b)}, for problems too large for Stata
matrices.

{phang}
{opt saving(filename)} saves the complete results for {helpb cdid_load}. An
existing file is never replaced.

{phang}
In chained mode, {opt keepnuisance} keeps reports of the fitted treatment,
outcome, observation, and imputation models for {helpb cdid_nuisance}. The models are
fitted in any case; the option keeps their reports and adds one pass over the
units to compute the standard errors of their coefficients. Estimates and
inference are unchanged.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

{phang2}{help cdid##remarks_cohort:Cohorts, reference dates, and unavailable effects}{p_end}
{phang2}{help cdid##remarks_reference:Covariates that vary over time}{p_end}
{phang2}{help cdid##remarks_missing:Missing outcomes}{p_end}
{phang2}{help cdid##remarks_crosspair:Cross-pair comparisons}{p_end}
{phang2}{help cdid##remarks_within:Within-unit weighting}{p_end}
{phang2}{help cdid##remarks_preset:Cohort-by-date preset}{p_end}
{phang2}{help cdid##remarks_dvar:Binary treatment with entry and exit}{p_end}
{phang2}{help cdid##remarks_ordinary:Ordinary mode}{p_end}
{phang2}{help cdid##remarks_custom:User-written estimators}{p_end}
{phang2}{help cdid##remarks_r:Correspondence with R}{p_end}

{pstd}
The user guide, {browse "https://github.com/dvbn/cdid-stata/blob/main/docs/README.md"},
states the assumptions behind each choice and works through examples.

{marker remarks_cohort}{...}
{title:Cohorts, reference dates, and unavailable effects}

{pstd}
A cohort is the set of units first treated at the same date. The output
reports post-treatment cells ({cmd:post})
and pretreatment cells ({cmd:pre}), which describe the trends of the cohort
and its controls before treatment. The footer reports a joint Wald test that the
pretreatment cells are zero, when their covariance allows it. Failing to
reject does not establish parallel trends.

{pstd}
A cell that the observed comparisons cannot identify, for example because no
comparison unit is observed at the dates involved, is reported as unavailable
with a reason; {helpb cdid_export:cdid_export, type(cells)} lists the reasons,
and {helpb cdid_chain} shows how each available cell is identified. An
aggregate that needs an unavailable cell is unavailable unless {cmd:estat}
is given {opt narm}.

{marker remarks_reference}{...}
{title:Covariates that vary over time}

{pstd}
A covariate that varies within units is read at each target cohort's reference
date for the post-treatment comparisons, and at the earlier date of each
pretrend comparison. A unit can contribute its change from date 3 to date 4
even if its outcome at date 2 is missing: if a comparison reads its date-2
covariate and that value is known, supply it on the date-2 row with a missing
outcome. Covariates are never carried forward, imputed, or read from another
date.

{pstd}
If the value is unknown, {cmd:missingreference(exclude)}, the default, warns and
excludes the unit from that cohort's comparisons only, as treated or comparison
unit. The unit still contributes to other cohorts whose reference covariates it
has, it keeps its row in the influence functions, and the number of units is
unchanged. If treated units are excluded, the cohort's effects describe its
remaining treated units, and a note after the table gives their number;
{cmd:estat} then weights that cohort by its eligible treated units.
{cmd:e(reference_eligibility)} records the counts. A pretrend comparison whose
own earlier-date covariate is missing is reported as unavailable, and the joint
pretrend Wald test is then not computed. {cmd:missingreference(error)} stops
with error 459 and lists the missing values. {helpb cdid_pretest} always stops
in this case.

{pstd}
Time-invariant covariates must be complete for the units used in estimation.
See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/help/prepare-data.md":Prepare your panel and unit table}.

{marker remarks_missing}{...}
{title:Missing outcomes}

{pstd}
Treatment {opt method(dr)} with {cmd:selmethod(dr)} is doubly robust in both
layers: for the treatment, either the propensity model or the outcome
regression may be misspecified; for the missing outcomes, either the
observation model or the imputation model, provided the other model of each
layer and the remaining assumptions are correct. The augmented correction does
not give {cmd:method(ipw)} or {cmd:method(reg)} the treatment-layer guarantee.
Fitted observation probabilities are bounded below by 1e-6 and treatment
propensities above by 1 - 1e-6. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/missing-outcomes.md":Handling missing outcomes}.

{marker remarks_crosspair}{...}
{title:Cross-pair comparisons}

{pstd}
With {opt crosspair}, each comparison is the mean change of one cohort between
two dates, of the target cohort or of a clean control cohort (the never-treated
cohort, or with {cmd:controlgroup(notyettreated)} the cohorts not yet treated at
the later date). GMM links these changes through calendar dates where the trend
assumption applies, so a cohort observed at dates 2 and 4 can be compared with
controls observed at dates 2 and 3 and at dates 3 and 4. Every comparison of
target cohort {it:g} reads covariates at {it:g}'s reference date. All treatment
methods except {opt custom}, every {opt selmethod()}, {opt noconstant},
factor-variable covariates, and covariates or weights that vary over time are
supported; {cmd:selmethod(imputation)} and {cmd:selmethod(dr)} require
{cmd:seluniverse(F)}. {opt crosspair} is not available in ordinary mode or with
{opt preset()}. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/cross-pair.md":Cross-pair chaining}.

{marker remarks_within}{...}
{title:Within-unit weighting}

{pstd}
{cmd:gmmweighting(within)} uses a working weighting matrix, block diagonal by
target cohort, built from the covariance of within-unit changes under
uncorrelated level shocks of equal variance. The weighting matrix does not
depend on the outcomes; it affects efficiency, not consistency, and the
reported standard errors do not assume it. With {opt crosspair}, {cmd:ptassumption(ctrl)},
{cmd:baseperiod(universal)}, not-yet-treated controls, no covariates, and
nested observation windows within each cohort, the point estimates equal the
coefficients of stacked target-cohort regressions with unit fixed effects; see
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/cross-pair.md":Cross-pair chaining}.

{marker remarks_preset}{...}
{title:Cohort-by-date preset}

{pstd}
{cmd:preset(cohort_time_fe)} with {cmd:method(reg)} fits the linear regression
of the outcome on unit fixed effects, date fixed effects, and a separate effect
for each treated cohort and date, on the observed rows, by least squares within
units. With {cmd:controlgroup(nevertreated)}, every date of a treated cohort
except its reference date has its own effect; with
{cmd:controlgroup(notyettreated) ptassumption(all)} and {opt ptstart()} at the
first study date, untreated dates share the common date effects and only
post-treatment cells are reported. Time-invariant covariates enter with
date-specific slopes and cohort-by-date deviations, and each effect is
evaluated at the covariate mean of its cohort in the study population.
{cmd:method(ipw)} and {cmd:method(dr)} combine cohort-standardized changes by
GMM. {cmd:selection(conditional_mtar)} with every {opt selmethod()} applies.

{pstd}
The preset requires {cmd:baseperiod(universal)}, {cmd:anticipation(0)}, no
weights, positive consecutive integer study dates, a never-treated cohort,
treated cohorts that adopt after the first date, and covariates that are
constant within units and nonmissing for every unit. With {cmd:method(reg)},
{cmd:gmmweighting()} may be omitted or set to {opt within}; with
{cmd:method(ipw)} or {cmd:method(dr)}, it can be {opt optimal}, {opt two_step},
or {opt identity}, not {opt within}. Standard errors use
the unit score sandwich without a degrees-of-freedom adjustment.
{helpb cdid_chain} is not available after the preset. See
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/methods/cohort-time-fe.md":Cohort-by-date fixed effects}.

{marker remarks_dvar}{...}
{title:Binary treatment with entry and exit}

{pstd}
With {opt dvar()} in place of {opt gvar()}, {cmd:cdid} estimates the immediate
effects of entering and leaving a binary treatment under a static model in
which past treatment has no effect beyond current status. Supplying both is an
error. See {helpb cdid_dvar:cdid with dvar()}.

{marker remarks_ordinary}{...}
{title:Ordinary mode}

{pstd}
Ordinary mode estimates the effects of Callaway and Sant'Anna (2021) with the
{cmd:csdid} 2.0.2 package on the units observed at every date (a note reports
how many units are dropped), on all units with {opt allowunbalanced}, or on
repeated cross sections with {opt rcs}. A balanced panel alone does not make
chained and ordinary estimates equal; see
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/from-did.md":Moving from did and csdid}.
The ordinary fit lists all accepted inactive options in
{cmd:e(inactive_options)}, whether specified or omitted. These include
{opt selection()}, the {opt sel*()} options, and {opt keepnuisance}. The note
names the inactive options supplied in the command. Nuisance-model reports
are unavailable in ordinary mode.

{marker remarks_custom}{...}
{title:User-written estimators}

{pstd}
{cmd:method(custom)} replaces the built-in treatment adjustment of each
comparison by a Mata function; see {help cdid_custom}. It is not available with
{opt crosspair}, {cmd:gmmweighting(within)}, or
{cmd:selmethod(imputation|dr)}.

{marker remarks_r}{...}
{title:Correspondence with R}

{pstd}
{cmd:cdid} 1.0.0.0 for Stata implements the estimators, options, and defaults
of {browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}, except the R arguments that control computation or
printing ({cmd:faster_mode}, {cmd:print_details}, {cmd:pl}, {cmd:cores},
{cmd:control$workers}), which have no Stata counterpart and do not change the
estimator. Estimates and standard errors were compared with R on a range of
configurations and agree there up to numerical precision; agreement is not
established beyond them, and multiplier-bootstrap draws come from Stata's
random-number generator and differ from R's. The mapping between
R arguments and Stata options is in
{browse "https://github.com/dvbn/cdid-stata/blob/main/docs/from-r-cdid.md":Moving from R cdid}.


{marker examples}{...}
{title:Examples}

{pstd}Setup: a staggered panel with outcomes missing at random dates{p_end}
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

{pstd}Group-time effects with the defaults: doubly robust adjustment, never-treated controls, multiplier bootstrap{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G)}{p_end}

{pstd}Event study{p_end}
{phang2}{cmd:. estat dynamic}{p_end}
{phang2}{cmd:. cdid_plot}{p_end}

{pstd}Regression adjustment, not-yet-treated controls, analytical standard errors{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) method(reg) controlgroup(notyettreated) bstrap(0) cband(0)}{p_end}

{pstd}Augmented correction for outcomes missing conditionally on {cmd:x}{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) selection(conditional_mtar) selmethod(dr) bstrap(0) cband(0)}{p_end}

{pstd}Cross-pair comparisons with control parallel trends and within-unit weighting{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) crosspair controlgroup(notyettreated) ptassumption(ctrl) gmmweighting(within) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. cdid_chain, cohort(2004) time(2005)}{p_end}

{pstd}Cohort-by-date fixed effects{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) preset(cohort_time_fe) method(reg) baseperiod(universal) bstrap(0) cband(0)}{p_end}

{pstd}Ordinary estimation on the units observed at every date{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) mode(ordinary) bstrap(0) cband(0)}{p_end}

{pstd}A covariate missing at a cohort's reference date{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20261116}{p_end}
{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. generate id = _n}{p_end}
{phang2}{cmd:. generate G = cond(mod(id, 3) == 0, 3, cond(mod(id, 3) == 1, 4, 0))}{p_end}
{phang2}{cmd:. expand 4}{p_end}
{phang2}{cmd:. bysort id: generate year = _n}{p_end}
{phang2}{cmd:. generate x = rnormal() + 0.2 * year}{p_end}
{phang2}{cmd:. generate y = 0.5 * x + 0.3 * year + (G > 0 & year >= G) + rnormal()}{p_end}
{phang2}{cmd:. replace x = . if id == 6 & year == 2}{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) bstrap(0) cband(0)}{p_end}
{phang2}{cmd:. matrix list e(reference_eligibility)}{p_end}
{phang2}{cmd:. capture noisily cdid y x, ivar(id) time(year) gvar(G) missingreference(error)}{p_end}

{pstd}
{cmd:net get cdid} copies {cmd:cdid_hands_on.do}, a longer guided example, and
{cmd:cdid_custom_estimators.do} to the current directory.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid} with {opt gvar()} in chained mode stores the following in {cmd:e()}. Results marked by a condition are posted only when it holds; {cmd:ereturn list} shows the results of a given fit. For {opt dvar()}, see {helpb cdid_dvar##results:cdid with dvar()}; for {cmd:estat}, see {helpb cdid_postestimation##results:cdid postestimation}.

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of units in the study population{p_end}
{synopt:{cmd:e(N_full)}}number of units in the study population, the scale of {cmd:e(V_asymptotic)}{p_end}
{synopt:{cmd:e(N_cells)}}number of group-time cells of the fit{p_end}
{synopt:{cmd:e(N_targets)}}number of rows of the results table, including unavailable and reference cells{p_end}
{synopt:{cmd:e(N_posted)}}number of estimates in {cmd:e(b)}{p_end}
{synopt:{cmd:e(clustered)}}1 if cluster() was specified{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters, with cluster(){p_end}
{synopt:{cmd:e(point_only)}}1 if only point estimates were computed (noinffunc){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(alpha)}}1 - {cmd:e(level)}/100{p_end}
{synopt:{cmd:e(B_requested)}}bootstrap draws requested{p_end}
{synopt:{cmd:e(bstrap_requested)}}value of bstrap(){p_end}
{synopt:{cmd:e(cband_requested)}}value of cband(){p_end}
{synopt:{cmd:e(critical_value)}}critical value of the reported intervals or bands{p_end}
{synopt:{cmd:e(normal_critical_value)}}normal critical value at {cmd:e(level)}{p_end}
{synopt:{cmd:e(wald_statistic)}}pretrend Wald statistic{p_end}
{synopt:{cmd:e(wald_df)}}its degrees of freedom{p_end}
{synopt:{cmd:e(wald_p)}}its p-value{p_end}
{synopt:{cmd:e(wald_N_clust)}}clusters used by the Wald test, with cluster(){p_end}
{synopt:{cmd:e(anticipation)}}periods of anticipation{p_end}

{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}cdid{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title of the output{p_end}
{synopt:{cmd:e(mode)}}chained{p_end}
{synopt:{cmd:e(depvar)}}name of the outcome{p_end}
{synopt:{cmd:e(ivar)}}unit identifier{p_end}
{synopt:{cmd:e(time)}}date variable{p_end}
{synopt:{cmd:e(gvar)}}cohort variable{p_end}
{synopt:{cmd:e(covariates)}}covariates, as typed{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable, with cluster(){p_end}
{synopt:{cmd:e(method)}}treatment adjustment{p_end}
{synopt:{cmd:e(control_group)}}comparison group{p_end}
{synopt:{cmd:e(base_period)}}base period{p_end}
{synopt:{cmd:e(pt_assumption)}}parallel trends assumption{p_end}
{synopt:{cmd:e(gmm_weighting)}}GMM weighting{p_end}
{synopt:{cmd:e(gmm_covariance)}}covariance regularization{p_end}
{synopt:{cmd:e(outcome_pooling)}}outcome-regression pooling{p_end}
{synopt:{cmd:e(imputation_pooling)}}imputation pooling, when active{p_end}
{synopt:{cmd:e(selection)}}assumption about missing outcomes, as specified{p_end}
{synopt:{cmd:e(selection_canonical)}}the same, in canonical form{p_end}
{synopt:{cmd:e(selection_est_method)}}correction for missing outcomes{p_end}
{synopt:{cmd:e(selection_model)}}observation model{p_end}
{synopt:{cmd:e(selection_pooling)}}observation-model pooling{p_end}
{synopt:{cmd:e(selection_universe)}}units that fit the observation model{p_end}
{synopt:{cmd:e(selection_justification)}}text of seljustification(), when specified{p_end}
{synopt:{cmd:e(cross_pair)}}crosspair, when specified{p_end}
{synopt:{cmd:e(preset)}}cohort_time_fe, when specified{p_end}
{synopt:{cmd:e(missing_reference)}}exclude or error (not with the preset){p_end}
{synopt:{cmd:e(reference_status)}}restricted, auxiliary_unavailable, or unrestricted (not with the preset){p_end}
{synopt:{cmd:e(reference_restricted)}}cohorts whose comparisons were restricted, when any{p_end}
{synopt:{cmd:e(reference_variables)}}covariates whose reference values were checked, when comparisons were restricted{p_end}
{synopt:{cmd:e(inactive_options)}}options that have no effect under this specification, specified or not{p_end}
{synopt:{cmd:e(callback)}}callback(), with method(custom){p_end}
{synopt:{cmd:e(payload)}}payload(), with method(custom){p_end}
{synopt:{cmd:e(wtype)}}weight type, with weights{p_end}
{synopt:{cmd:e(wexp)}}weight expression, with weights{p_end}
{synopt:{cmd:e(nuisance)}}availability of the reports kept, with keepnuisance{p_end}
{synopt:{cmd:e(vce)}}analytic, bootstrap, or none{p_end}
{synopt:{cmd:e(vcetype)}}Bootstrap, with the multiplier bootstrap{p_end}
{synopt:{cmd:e(band)}}pointwise, simultaneous, or none{p_end}
{synopt:{cmd:e(inference_rule)}}how bstrap() and cband() were applied, in words{p_end}
{synopt:{cmd:e(rng)}}source of the bootstrap multipliers, in words{p_end}
{synopt:{cmd:e(result_kind)}}cells{p_end}
{synopt:{cmd:e(result_status)}}status of the results{p_end}
{synopt:{cmd:e(inference_status)}}status of the inference{p_end}
{synopt:{cmd:e(wald_status)}}status of the pretrend Wald test{p_end}
{synopt:{cmd:e(wald_reason)}}why the Wald test was not computed, when it was not{p_end}
{synopt:{cmd:e(warning)}}warnings, when any{p_end}
{synopt:{cmd:e(posting_mode)}}matrix or state{p_end}
{synopt:{cmd:e(posting_reason)}}description of what {cmd:e(b)} holds{p_end}
{synopt:{cmd:e(coefficient_map)}}description of {cmd:e(coef_map)}{p_end}
{synopt:{cmd:e(covariance_scale)}}description of {cmd:e(V)} and {cmd:e(V_asymptotic)}{p_end}
{synopt:{cmd:e(se_scale)}}description of {cmd:e(se)}{p_end}
{synopt:{cmd:e(sample_scope)}}description of {cmd:e(sample)}{p_end}
{synopt:{cmd:e(state_token)}}reference to the stored results used by estat and the postestimation commands{p_end}
{synopt:{cmd:e(state_file)}}file written by saving(), when specified{p_end}
{synopt:{cmd:e(estat_cmd)}}cdid_estat{p_end}
{synopt:{cmd:e(properties)}}b V, or b with noinffunc{p_end}

{p2col 5 30 34 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}available estimates{p_end}
{synopt:{cmd:e(V)}}analytical covariance of {cmd:e(b)}{p_end}
{synopt:{cmd:e(V_asymptotic)}}{cmd:e(N_full)} times {cmd:e(V)}{p_end}
{synopt:{cmd:e(se)}}reported standard errors{p_end}
{synopt:{cmd:e(analytic_se)}}analytical standard errors{p_end}
{synopt:{cmd:e(ci)}}reported intervals or bands (2 x k){p_end}
{synopt:{cmd:e(ci_pointwise)}}pointwise intervals (2 x k){p_end}
{synopt:{cmd:e(coef_map)}}cell of each estimate in {cmd:e(b)}{p_end}
{synopt:{cmd:e(reference_eligibility)}}eligible and excluded units by target cohort, when comparisons were restricted{p_end}
{synopt:{cmd:e(reference_contexts)}}excluded units by reference date, when comparisons were restricted{p_end}
{synopt:{cmd:e(reference_aux_unavailable)}}unavailable pretrend comparisons, when any{p_end}

{p2col 5 30 34 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the input rows of the units in the study population, including rows with a missing outcome; units excluded from the comparisons of a cohort, for example under missingreference(exclude), remain marked{p_end}

{p2colreset}{...}

{pstd}
With noinffunc, {cmd:e(V)} and {cmd:e(V_asymptotic)} are not posted and {cmd:e(point_only)} is 1. With posting(matrix) and at least one available cell, {cmd:e(se)}, {cmd:e(analytic_se)}, {cmd:e(ci)}, and {cmd:e(ci_pointwise)} have missing entries and {cmd:e(properties)} is b; with posting(state), no matrix is posted and {cmd:e(properties)} is empty.

{pstd}
In ordinary mode, cdid stores the following in {cmd:e()}; the chained-mode settings macros are not posted.

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of units used{p_end}
{synopt:{cmd:e(N_full)}}the same, the scale of {cmd:e(V_asymptotic)}{p_end}
{synopt:{cmd:e(N_cells)}}number of group-time cells{p_end}
{synopt:{cmd:e(N_targets)}}number of rows of the results table{p_end}
{synopt:{cmd:e(N_posted)}}number of estimates in {cmd:e(b)}{p_end}
{synopt:{cmd:e(clustered)}}1 when the reported inference uses clusters{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters, when clustered{p_end}
{synopt:{cmd:e(point_only)}}1 if only point estimates were computed{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(alpha)}}1 - {cmd:e(level)}/100{p_end}
{synopt:{cmd:e(B_requested)}}bootstrap draws requested{p_end}
{synopt:{cmd:e(bstrap)}}value of bstrap(){p_end}
{synopt:{cmd:e(cband)}}value of cband(){p_end}
{synopt:{cmd:e(critical_value)}}critical value of the reported intervals or bands{p_end}
{synopt:{cmd:e(normal_critical_value)}}normal critical value at {cmd:e(level)}{p_end}
{synopt:{cmd:e(wald_statistic)}}pretrend Wald statistic{p_end}
{synopt:{cmd:e(wald_df)}}its degrees of freedom{p_end}
{synopt:{cmd:e(wald_p)}}its p-value{p_end}
{synopt:{cmd:e(wald_p_unrounded)}}its p-value before rounding{p_end}

{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}cdid{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title of the output{p_end}
{synopt:{cmd:e(mode)}}ordinary{p_end}
{synopt:{cmd:e(depvar)}}name of the outcome{p_end}
{synopt:{cmd:e(ivar)}}unit identifier{p_end}
{synopt:{cmd:e(time)}}date variable{p_end}
{synopt:{cmd:e(gvar)}}cohort variable{p_end}
{synopt:{cmd:e(covariates)}}covariates, as typed{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable used for inference, when clustered{p_end}
{synopt:{cmd:e(method)}}treatment adjustment{p_end}
{synopt:{cmd:e(inactive_options)}}accepted options that have no effect in ordinary mode, specified or not{p_end}
{synopt:{cmd:e(callback)}}callback(), with method(custom){p_end}
{synopt:{cmd:e(payload)}}payload(), with method(custom){p_end}
{synopt:{cmd:e(vce)}}analytic, bootstrap, or none{p_end}
{synopt:{cmd:e(vcetype)}}Bootstrap, with the multiplier bootstrap{p_end}
{synopt:{cmd:e(band)}}pointwise, simultaneous, or none{p_end}
{synopt:{cmd:e(inference_rule)}}how bstrap() and cband() were applied, in words{p_end}
{synopt:{cmd:e(result_kind)}}ordinary_cells (ordinary_simple, ... after estat){p_end}
{synopt:{cmd:e(wald_status)}}status of the pretrend Wald test{p_end}
{synopt:{cmd:e(wald_reason)}}cells used by the Wald test, or why it was not computed{p_end}
{synopt:{cmd:e(conditional_test_status)}}status of the conditional pretest in this result{p_end}
{synopt:{cmd:e(warning)}}warnings, when any{p_end}
{synopt:{cmd:e(posting_mode)}}matrix or state{p_end}
{synopt:{cmd:e(covariance_scale)}}description of {cmd:e(V)}, {cmd:e(V_asymptotic)}, and {cmd:e(V_did)}{p_end}
{synopt:{cmd:e(se_scale)}}description of {cmd:e(se)}{p_end}
{synopt:{cmd:e(sample_scope)}}description of {cmd:e(sample)}{p_end}
{synopt:{cmd:e(state_token)}}reference to the stored results used by estat{p_end}
{synopt:{cmd:e(estat_cmd)}}cdid_estat{p_end}
{synopt:{cmd:e(properties)}}b V{p_end}

{p2col 5 30 34 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}available estimates{p_end}
{synopt:{cmd:e(V)}}covariance of {cmd:e(b)}{p_end}
{synopt:{cmd:e(V_asymptotic)}}{cmd:e(N_full)} times {cmd:e(V)}{p_end}
{synopt:{cmd:e(V_did)}}covariance R's att_gt() reports as V_analytical, divided by {cmd:e(N_full)}{p_end}
{synopt:{cmd:e(V_did_asymptotic)}}covariance R's att_gt() reports as V_analytical{p_end}
{synopt:{cmd:e(se)}}reported standard errors{p_end}
{synopt:{cmd:e(analytic_se)}}analytical standard errors{p_end}
{synopt:{cmd:e(ci)}}reported intervals or bands (2 x k){p_end}
{synopt:{cmd:e(ci_pointwise)}}pointwise intervals (2 x k){p_end}
{synopt:{cmd:e(coef_map)}}cell of each estimate in {cmd:e(b)}{p_end}

{p2col 5 30 34 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the observations used{p_end}

{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Bellégo, C., D. Benatia, and V. Dortet-Bernadet. 2025. The chained
difference-in-differences. {it:Journal of Econometrics} 248: 105783.
{browse "https://doi.org/10.1016/j.jeconom.2024.105783"}.

{phang}
Callaway, B., and P. H. C. Sant'Anna. 2021. Difference-in-differences with
multiple time periods. {it:Journal of Econometrics} 225: 200-230.
{browse "https://doi.org/10.1016/j.jeconom.2020.12.001"}.


{marker author}{...}
{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
