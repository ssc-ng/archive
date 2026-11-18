{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_pretest_load" "help cdid_pretest_load"}{...}
{vieweralsosee "cdid_custom" "help cdid_custom"}{...}
{viewerjumpto "Syntax" "cdid_pretest##syntax"}{...}
{viewerjumpto "Description" "cdid_pretest##description"}{...}
{viewerjumpto "Options" "cdid_pretest##options"}{...}
{viewerjumpto "Remarks" "cdid_pretest##remarks"}{...}
{viewerjumpto "Examples" "cdid_pretest##examples"}{...}
{viewerjumpto "Stored results" "cdid_pretest##results"}{...}
{viewerjumpto "References" "cdid_pretest##references"}{...}
{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{cmd:cdid_pretest} {hline 2}}Conditional pretrend test for staggered difference-in-differences{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:cdid_pretest} {depvar} [{indepvars}] {ifin} [{cmd:iweight}]{cmd:,}
{opt time(varname)} {opt gvar(varname)} [{opt ivar(varname)} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt covars(varlist)}}covariates; alternative to {it:indepvars}{p_end}
{synopt :{opt nocons:tant}}omit the intercept{p_end}
{synopt :{opt method(string)}}{opt ipw} (default), {opt reg}, {opt dr}, or {opt custom}{p_end}
{synopt :{opt outcomepooling(string)}}{opt separate} (default) or {opt pooled}{p_end}
{synopt :{opt callback(name)}, {opt payload(name)}}user-written estimator; see {help cdid_custom}{p_end}
{synopt :{opt control:group(string)}}{opt nevertreated} (default) or {opt notyettreated}{p_end}
{synopt :{opt anticip:ation(#)}}periods of anticipation; default {cmd:0}{p_end}
{synopt :{opt base:period(string)}}{opt varying} (default) or {opt universal}{p_end}

{syntab:Mode}
{synopt :{opt mode(string)}}{opt chained} (default with panel data) or {opt ordinary}{p_end}
{synopt :{opt rcs}}repeated cross sections; implies {cmd:mode(ordinary)}{p_end}
{synopt :{opt panel(#)}}{cmd:1} (panel data) or {cmd:0} (repeated cross sections){p_end}
{synopt :{opt allowunbalanced(#)}}{cmd:1} or {cmd:0}; see below{p_end}

{syntab:Missing outcomes, study population, and weights}
{synopt :{opt selection()}, {opt selmethod()}, {opt selmodel()}}as for {helpb cdid}{p_end}
{synopt :{opt selpooling()}, {opt imppooling()}, {opt selcovars()}}as for {helpb cdid}{p_end}
{synopt :{opt selnocons:tant}, {opt selcons:tant}, {opt selzero}}as for {helpb cdid}{p_end}
{synopt :{opt seluniverse()}, {opt selrho()}, {opt seljustification()}}as for {helpb cdid}{p_end}
{synopt :{opt frame()}, {opt frameivar()}, {opt framegvar()}}as for {helpb cdid}{p_end}
{synopt :{opt framecovars()}, {opt frameselcovars()}}as for {helpb cdid}{p_end}
{synopt :{opt framewvar()}, {opt framecluster()}}as for {helpb cdid}{p_end}
{synopt :{opt wvar(varname)}, {opt fixweights(string)}}as for {helpb cdid}{p_end}

{syntab:Inference}
{synopt :{opt cluster(varname)}}cluster variable{p_end}
{synopt :{opt biters(#)}}multiplier-bootstrap draws; default {cmd:1000}{p_end}
{synopt :{opt l:evel(#)}}level of the reported critical value; default {cmd:level(95)}{p_end}
{synopt :{opt signs(matname)}}supply the bootstrap multipliers{p_end}
{synopt :{opt bstrap(#)}, {opt cband(#)}}accepted; do not change the test{p_end}
{synopt :{opt pl(#)}, {opt cores(#)}}only {cmd:pl(0) cores(1)}; the test runs serially{p_end}

{syntab:Results and computation}
{synopt :{opt posting(string)}}{opt matrix} (default) or {opt state}{p_end}
{synopt :{opt store(name)}}keep the complete results in a Mata object{p_end}
{synopt :{opt saving(filename)}}save the results for {helpb cdid_pretest_load}{p_end}
{synopt :{opt workspace(#)}, {opt chunk(#)}, {opt workcap(#)}}as for {helpb cdid}; chained mode only{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_pretest} tests conditional parallel trends before treatment with
the integrated-moments test of Callaway and Sant'Anna (2021). The null
hypothesis is that, conditional on the covariates, the mean outcome change of
each cohort and of its comparison units coincide in every pretreatment
comparison. The statistic is a Cramér-von Mises functional of these
differences evaluated at the covariate values of the sample; its critical
value and p-value come from a multiplier bootstrap. Failing to reject does not
establish parallel trends.

{pstd}
The test uses the chained or ordinary estimators of {helpb cdid} and is
distinct from the joint Wald test that {cmd:cdid} reports after a chained fit.
{cmd:cdid_pretest} displays the test and returns its results in {cmd:r()};
{cmd:e()} is left unchanged. It corresponds to the function
{cmd:conditional_did_pretest()} of
{browse "https://github.com/dvbn/cdid":R {cmd:cdid} 1.3.0.0}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{it:indepvars} or {opt covars()}, {opt noconstant}, {opt method()},
{opt outcomepooling()}, {opt callback()}, {opt payload()},
{opt controlgroup()}, {opt anticipation()}, and {opt baseperiod()} are as for
{helpb cdid}, except that the default treatment adjustment is
{cmd:method(ipw)}. In ordinary mode, {opt anticipation()} and
{opt baseperiod()} have no effect; see
{help cdid_pretest##remarks:Remarks}.

{dlgtab:Mode}

{phang}
{opt mode()} and {opt rcs} are as for {helpb cdid}. {cmd:panel(0)} also
requests repeated cross sections and ordinary mode. {opt allowunbalanced(#)}
specifies whether units observed at only some dates are kept: chained mode
keeps them and refuses {cmd:allowunbalanced(0)}; ordinary mode uses the units
observed at every date unless {cmd:allowunbalanced(1)} is specified.

{dlgtab:Missing outcomes, study population, and weights}

{phang}
In chained mode, the missing-outcome options, the study-population options
({opt frame()} and related options), and the weight options are as for
{helpb cdid}; see {help cdid_pretest##remarks:Remarks} for the supported
combinations.

{dlgtab:Inference}

{phang}
{opt cluster(varname)} clusters the bootstrap at a level at or above the unit.
In chained mode, the cluster variable may be the unit identifier or one
additional variable, with at least two clusters.

{phang}
{opt biters(#)} sets the number of bootstrap draws. {opt signs(matname)}
supplies a {it:B} x {it:C} matrix of multipliers equal to -1 or +1, where
{it:B} is the number of draws and {it:C} the number of clusters in order of
first appearance; no random numbers are then drawn. Otherwise, draws come from
the current random-number stream; use {helpb set seed} for reproducible
results.

{phang}
{opt pl(#)} and {opt cores(#)} correspond to R arguments that request parallel
computation. Only {cmd:pl(0) cores(1)} is accepted; {cmd:cdid_pretest} runs
serially.

{dlgtab:Results and computation}

{phang}
{opt posting(matrix|state)}. {opt matrix} (the default) returns the bootstrap
draws and the tested cells as matrices in {cmd:r()}. {opt state}, which
requires {opt store(name)}, keeps them only in the Mata object {it:name}, for
problems too large for Stata matrices. An existing Mata object is never
replaced.

{phang}
{opt saving(filename)} saves the results for {helpb cdid_pretest_load}. An
existing file is never replaced.

{phang}
{opt workspace(#)}, {opt chunk(#)}, and {opt workcap(#)} apply in chained mode
only; ordinary mode uses fixed internal settings.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Chained mode.} The test is available with {cmd:selection(none)} and with
{cmd:selection(conditional_mtar)} under {cmd:selmethod(ipw)},
{cmd:selmethod(imputation)}, or {cmd:selmethod(dr)}, for {cmd:method(ipw)},
{cmd:method(reg)}, and {cmd:method(dr)}. Imputation and the augmented
correction require {cmd:seluniverse(F)} without {opt selrho()}. The tested
family is the full set of pretreatment cells of the request; if any of them is
unavailable, the test is reported as unavailable ({cmd:r(status)} =
{cmd:"unavailable"}) with the reason in {cmd:r(reason)}. Covariates that vary
over time enter at the earlier date of each pretreatment comparison; a
required covariate missing at such a date stops the command with error 459,
whatever {opt missingreference()} would do in {helpb cdid}.

{pstd}
{bf:Ordinary mode.} The test follows the conditional pretest of the R package
{cmd:did} 2.5.1, on units observed at every date or on repeated cross
sections. Without covariates, the model contains an intercept only. As in R,
{opt anticipation()}, {opt baseperiod()}, {opt fixweights()}, the {opt frame*()}
options, the missing-outcome options ({opt selection()} and the {opt sel*()}
options), {opt imppooling()}, {opt outcomepooling()}, {opt workspace()},
{opt chunk()}, and {opt workcap()} have no effect in ordinary mode.
{cmd:r(inactive_options)} lists all of them, whether specified or omitted.
The note names the inactive options supplied in the command.
The ordinary test uses no anticipation, the base periods of R's
{cmd:did::conditional_did_pretest()}, and the weights as supplied.

{pstd}
{bf:User-written estimators.} In ordinary mode, the callback is evaluated for
every pretreatment comparison. In chained mode, the test is not defined for
user-written estimators and returns {cmd:r(status)} = {cmd:"not_applicable"}
without calling the function.


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

{pstd}Chained test with the default IPW adjustment{p_end}
{phang2}{cmd:. cdid_pretest y x, ivar(id) time(year) gvar(G) biters(199)}{p_end}
{phang2}{cmd:. display "p-value = " r(CvMpval)}{p_end}

{pstd}Ordinary-mode test with doubly robust adjustment on the units observed at every date{p_end}
{phang2}{cmd:. cdid_pretest y x, ivar(id) time(year) gvar(G) mode(ordinary) method(dr) biters(199)}{p_end}
{phang2}{cmd:. return list}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_pretest} stores the following in {cmd:r()}:

{synoptset 32 tabbed}{...}
{p2col 5 32 36 2: Scalars}{p_end}
{synopt:{cmd:r(CvM)}}Cramér-von Mises statistic{p_end}
{synopt:{cmd:r(CvMcval)}}bootstrap critical value at level(){p_end}
{synopt:{cmd:r(CvMpval)}}bootstrap p-value (share of draws strictly above {cmd:r(CvM)}){p_end}
{synopt:{cmd:r(N)}}number of units{p_end}
{synopt:{cmd:r(M)}}number of evaluation points (one per unit in chained mode){p_end}
{synopt:{cmd:r(K)}}number of pretreatment cells tested{p_end}
{synopt:{cmd:r(C)}}number of clusters{p_end}
{synopt:{cmd:r(B)}}number of bootstrap draws{p_end}
{synopt:{cmd:r(alpha)}}1 - level/100{p_end}
{synopt:{cmd:r(N_input)}}observations supplied{p_end}
{synopt:{cmd:r(N_requested)}}observations requested{p_end}
{synopt:{cmd:r(N_rows)}}rows used{p_end}
{synopt:{cmd:r(N_distinct)}}distinct units{p_end}
{synopt:{cmd:r(multipliers_used)}}1 if bootstrap multipliers were drawn or supplied{p_end}
{synopt:{cmd:r(bstrap_requested)}}value of bstrap(){p_end}
{synopt:{cmd:r(cband_requested)}}value of cband(){p_end}
{synopt:{cmd:r(n_callbacks)}}number of callback calls, with method(custom){p_end}
{synopt:{cmd:r(allowunbalanced_supplied)}}1 if allowunbalanced() was specified{p_end}
{synopt:{cmd:r(rcs_dr_corrected_if)}}1 when the ordinary doubly robust test with repeated cross-sections uses the corrected influence function{p_end}
{synopt:{cmd:r(formula_defaulted)}}1 when the ordinary test used the intercept-only model by default{p_end}
{synopt:{cmd:r(id_defaulted)}}1 when repeated cross-sections used observation identifiers by default{p_end}

{p2col 5 32 36 2: Macros}{p_end}
{synopt:{cmd:r(status)}}available, unavailable, or not_applicable{p_end}
{synopt:{cmd:r(reason)}}reason, when the test is not available{p_end}
{synopt:{cmd:r(mode)}}chained or ordinary{p_end}
{synopt:{cmd:r(method)}}treatment adjustment{p_end}
{synopt:{cmd:r(formula)}}covariates{p_end}
{synopt:{cmd:r(X_columns)}}columns of the treatment design{p_end}
{synopt:{cmd:r(Z_columns)}}columns of the evaluation grid{p_end}
{synopt:{cmd:r(outcome_pooling)}}outcome-regression pooling, when active{p_end}
{synopt:{cmd:r(clustervars)}}cluster variable, with cluster(){p_end}
{synopt:{cmd:r(callback)}}callback(), with method(custom){p_end}
{synopt:{cmd:r(payload)}}payload(), with method(custom){p_end}
{synopt:{cmd:r(allowunbalanced_requested)}}value of allowunbalanced(), when specified{p_end}
{synopt:{cmd:r(inactive_options)}}accepted options that have no effect in ordinary mode, specified or not{p_end}
{synopt:{cmd:r(posting)}}matrix or state{p_end}
{synopt:{cmd:r(state_token)}}name of the store() object, with store(){p_end}
{synopt:{cmd:r(rng)}}source of the multipliers, in words{p_end}
{synopt:{cmd:r(description)}}construction of the test, in words{p_end}
{synopt:{cmd:r(grid_rule)}}evaluation grid, in words{p_end}
{synopt:{cmd:r(influence_function)}}influence function used, in words{p_end}

{p2col 5 32 36 2: Matrices}{p_end}
{synopt:{cmd:r(CvMb)}}B x 1 bootstrap draws of the statistic{p_end}
{synopt:{cmd:r(family)}}tested pretreatment cells{p_end}
{synopt:{cmd:r(grid)}}evaluation grid: first_grid_row and multiplicity{p_end}

{p2colreset}{...}

{pstd}
When the test is unavailable or not applicable, the statistics are missing and {cmd:r(CvMb)} is not returned. cdid_pretest_load returns the same results, except {cmd:r(callback)}, {cmd:r(payload)}, {cmd:r(n_callbacks)}, and {cmd:r(inactive_options)}, and adds {cmd:r(state_file)}.


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
