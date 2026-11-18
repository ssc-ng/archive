{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_pretest" "help cdid_pretest"}{...}
{vieweralsosee "[M-2] struct" "help m2_struct"}{...}
{viewerjumpto "Author" "cdid_custom##author"}{...}
{viewerjumpto "Syntax" "cdid_custom##syntax"}{...}
{viewerjumpto "Description" "cdid_custom##description"}{...}
{viewerjumpto "The callback function" "cdid_custom##contract"}{...}
{viewerjumpto "Where callbacks are used" "cdid_custom##routes"}{...}
{viewerjumpto "Examples" "cdid_custom##examples"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:cdid_custom} {hline 2}}User-written treatment estimators for {cmd:cdid} and {cmd:cdid_pretest}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:cdid} {depvar} [{indepvars}] {ifin} [{cmd:iweight}]{cmd:,}
{opt ivar(varname)} {opt time(varname)} {opt gvar(varname)}
{cmd:method(custom)} {opt callback(name)} [{opt payload(name)} {it:other_options}]

{p 8 21 2}
{cmd:cdid_pretest} {depvar} [{indepvars}] {ifin} [{cmd:iweight}]{cmd:,}
{opt time(varname)} {opt gvar(varname)} [{opt ivar(varname)}]
{cmd:method(custom)} {opt callback(name)} [{opt payload(name)} {it:other_options}]


{marker description}{...}
{title:Description}

{pstd}
With {cmd:method(custom)}, {helpb cdid} and {helpb cdid_pretest} estimate each
two-group, two-period comparison with a Mata function that you write, instead
of the built-in inverse probability weighting, outcome regression, or doubly
robust estimators. The function returns the comparison's treatment effect and
its influence function; {cmd:cdid} then combines the comparisons and computes
standard errors as it does for the built-in estimators.

{pstd}
{opt callback(name)} names the function. {opt payload(name)} optionally names
an existing Mata object, of any type, that is passed to the function by
pointer; use it to pass settings or to collect information across calls. Both
must be Mata names; expressions are not evaluated. {opt callback()} and
{opt payload()} are allowed only with {cmd:method(custom)}.

{pstd}
The structures {cmd:cdid_callback_request} and {cmd:cdid_callback_result}
and the function {cmd:cdid_callback_result_make()} are part of the {cmd:cdid}
Mata library. In a new Stata session, type {cmd:mata: mata mlib index} before
defining a callback so that Mata finds them.


{marker contract}{...}
{title:The callback function}

{pstd}
A callback has the signature

{p 8 12 2}
{cmd:struct cdid_callback_result scalar} {it:name}{cmd:(struct cdid_callback_request scalar} {it:r}{cmd:, pointer() scalar} {it:payload}{cmd:)}

{pstd}
and ends with

{p 8 12 2}
{cmd:return(cdid_callback_result_make(}{it:att}{cmd:,} {it:psi}{cmd:,} {it:gradient}{cmd:))}

{pstd}
where {it:att} is the estimated effect (a real scalar), {it:psi} is its
influence function evaluated at each of the {it:m} observations passed in
{it:r} ({it:m} x 1), and {it:gradient} is the derivative described below or
{cmd:J(0,1,.)} when it is not needed. {it:payload} is {cmd:NULL} when
{opt payload()} is not specified. An error raised in the callback, for
example with {cmd:_error()}, stops chained estimation; in ordinary mode, the
cell is reported as unavailable ("the callback stopped with an error"), and in
the ordinary-mode {cmd:cdid_pretest}, the test is reported as unavailable.

{pstd}
The request {it:r} contains:

{p2colset 7 30 32 2}{...}
{p2col :{cmd:r.mode}}{cmd:"chained"} or {cmd:"ordinary"}{p_end}
{p2col :{cmd:r.route}}label of the type of comparison, for information: {cmd:"baseline_static"}, {cmd:"baseline_dated"} (covariates or weights that vary over time), {cmd:"conditional_mtar_static"}, or {cmd:"conditional_mtar_dated"} in chained mode; {cmd:"panel"}, {cmd:"unbalanced_panel"}, or {cmd:"RCS"} in ordinary mode. Branch on {cmd:r.mode} and {cmd:r.panel} instead{p_end}
{p2col :{cmd:r.panel}}{cmd:1} when outcomes are passed as pairs
({cmd:r.y0}, {cmd:r.y1}); {cmd:0} when they are passed as stacked
observations ({cmd:r.y}, {cmd:r.post}), as for repeated cross sections and
ordinary-mode unbalanced panels{p_end}
{p2col :{cmd:r.g}, {cmd:r.s}, {cmd:r.t}}cohort, earlier period, and later period of the comparison{p_end}
{p2col :{cmd:r.D}}{cmd:1} for units of cohort {cmd:r.g}, {cmd:0} for comparison units ({it:m} x 1){p_end}
{p2col :{cmd:r.y0}, {cmd:r.y1}}outcomes in the earlier and later periods (when {cmd:r.panel == 1}){p_end}
{p2col :{cmd:r.y}, {cmd:r.post}}outcome and later-period indicator (when {cmd:r.panel == 0}){p_end}
{p2col :{cmd:r.i_weights}}observation weights ({it:m} x 1){p_end}
{p2col :{cmd:r.covariates}}covariate matrix ({it:m} x {it:p}); covariates that vary over time are read at the dates described in {help cdid##remarks_reference:cdid}{p_end}
{p2col :{cmd:r.covariate_names}}its column names (1 x {it:p}){p_end}
{p2col :{cmd:r.inffunc}}{cmd:1} when {it:psi} is required; {cmd:0} for point estimates only (ordinary mode){p_end}
{p2col :{cmd:r.gradient_required}}{cmd:1} when {it:gradient} must be supplied (see below){p_end}
{p2col :{cmd:r.rows_F}, {cmd:r.rows_A}}positions of the passed observations among the units of the study population and of the estimation sample; {cmd:r.rows_A} is empty in ordinary mode{p_end}
{p2col :{cmd:r.call_index}}number of this call, starting at 1{p_end}
{p2colreset}{...}


{marker routes}{...}
{title:Where callbacks are used}

{phang}
{bf:Chained estimation without a missing-outcome correction}
({cmd:selection(none)}). {it:att} and {it:psi} must be finite. {it:gradient} is
optional; when omitted, {cmd:cdid} uses {it:psi}/{it:m}.

{phang}
{bf:Chained estimation with observation weighting}
({cmd:selection(conditional_mtar) selmethod(ipw)}). {it:gradient} is required:
an {it:m} x 1 vector giving the derivative of {it:att} with respect to each
observation's log weight, in the units of {it:att}. {cmd:selmethod(imputation)}
and {cmd:selmethod(dr)} do not support user-written estimators.

{phang}
{bf:Covariates missing at a reference date.} When
{cmd:missingreference(exclude)} restricts a cohort, the callback receives only
the units eligible for that cohort's comparisons, with weights computed on
those units.

{phang}
{bf:Not supported.} {cmd:method(custom)} is not available with
{opt crosspair}, {cmd:gmmweighting(within)}, {opt preset()}, or {opt dvar()}.

{phang}
{bf:Ordinary estimation} ({cmd:mode(ordinary)} or {cmd:rcs}). The callback
estimates each group-time effect directly from the two periods compared, for
balanced panels, unbalanced panels, and repeated cross sections. {it:gradient}
is ignored. The influence function is used as returned.

{phang}
{bf:Conditional pretrend test.} In ordinary mode, {helpb cdid_pretest} calls
the function for every pretreatment comparison, with the outcome replaced by
the indicator-transformed outcome used by the test. In chained mode the test
is not defined for user-written estimators and returns
{cmd:r(status)} = {cmd:"not_applicable"} without calling the function.

{phang}
{bf:After estimation.} {cmd:estat}, {helpb cdid_plot}, {helpb cdid_export},
{helpb cdid_load}, and {helpb cdid_pretest_load} use the stored results and
never call the function again; it need not exist after estimation.


{marker examples}{...}
{title:Examples}

{pstd}
Define a callback for panel comparisons: the weighted difference in mean
outcome changes between cohort and comparison units. The payload counts calls.

        {cmd:. mata: mata mlib index}
        {cmd:. mata:}
        {cmd:struct cdid_callback_result scalar my_att(}
        {cmd:    struct cdid_callback_request scalar r, pointer() scalar payload)}
        {cmd:{c -(}}
        {cmd:    real scalar m, mt, mc}
        {cmd:    real colvector dy, wt, wc, psi}
        {cmd:    if (payload != NULL) *payload = *payload + 1}
        {cmd:    if (r.panel != 1) _error(498)}
        {cmd:    m = rows(r.D)}
        {cmd:    dy = r.y1 - r.y0}
        {cmd:    wt = r.i_weights :* r.D}
        {cmd:    wc = r.i_weights :* (1 :- r.D)}
        {cmd:    if (sum(wt) <= 0 | sum(wc) <= 0) _error(459)}
        {cmd:    mt = sum(wt :* dy) / sum(wt)}
        {cmd:    mc = sum(wc :* dy) / sum(wc)}
        {cmd:    psi = m :* (wt :* (dy :- mt) / sum(wt) - wc :* (dy :- mc) / sum(wc))}
        {cmd:    return(cdid_callback_result_make(mt - mc, psi, psi / m))}
        {cmd:{c )-}}
        {cmd:my_calls = 0}
        {cmd:end}

{pstd}
Simulate a panel and use the callback:

        {cmd:. clear}
        {cmd:. set seed 20261116}
        {cmd:. set obs 600}
        {cmd:. generate id = _n}
        {cmd:. generate G = cond(runiform() < .4, 0, cond(runiform() < .5, 2004, 2006))}
        {cmd:. generate x = rnormal()}
        {cmd:. expand 8}
        {cmd:. bysort id: generate year = 2000 + _n}
        {cmd:. generate y = x + .2*(year - 2000) + (G > 0 & year >= G)*(1 + .25*(year - G)) + rnormal()}
        {cmd:. replace y = . if runiform() < .2}
        {cmd:. cdid y, ivar(id) time(year) gvar(G) method(custom) callback(my_att) payload(my_calls) bstrap(0) cband(0)}
        {cmd:. mata: my_calls}
        {cmd:. estat simple}

{pstd}
{cmd:net get cdid} copies {cmd:cdid_custom_estimators.do}, which defines this
callback and one for stacked observations, and runs them in chained mode,
ordinary mode, and {cmd:cdid_pretest}.


{marker author}{...}
{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
