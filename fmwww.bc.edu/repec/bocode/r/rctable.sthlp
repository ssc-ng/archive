{smcl}
{* *! version 3.0.0  26sep2026}{...}
{viewerjumpto "Syntax" "rctable##syntax"}{...}
{viewerjumpto "Description" "rctable##description"}{...}
{viewerjumpto "Options" "rctable##options"}{...}
{viewerjumpto "Remarks" "rctable##remarks"}{...}
{viewerjumpto "Stored results" "rctable##results"}{...}
{viewerjumpto "Examples" "rctable##examples"}{...}
{viewerjumpto "Author" "rctable##author"}{...}
{title:Title}

{phang}
{bf:rctable} {hline 2} RCT results table (ITT or LATE) with multiple-testing
adjustments, exportable to Excel or LaTeX


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rctable} {it:{help varlist}} {cmd:using} {it:filename} {ifin}
{weight}{cmd:, }
{cmdab:treat:ment(}{it:varlist}{cmd:)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt treat:ment(varlist)}}treatment indicator(s); one variable per
treatment arm{p_end}

{syntab:Sample and controls}
{synopt:{opt cont:rol(varlist fv)}}controls included in every regression{p_end}
{synopt:{opt basec:ontrol(varlist)}}one baseline-control variable per
outcome, matched in the order of {it:varlist}{p_end}
{synopt:{opt clust:er(varlist)}}cluster variable(s) for {cmd:vce(cluster)}{p_end}

{syntab:Estimator}
{synopt:{opt est:imator(name)}}{cmd:itt} (default) or {cmd:late}{p_end}
{synopt:{opt treat:ed(varlist)}}endogenous "treated" variable, instrumented
by {cmd:treatment()}; implies {cmd:estimator(late)}{p_end}

{syntab:Inference display}
{synopt:{opt pvalue}}add a bracketed row with the raw p-value under each
coefficient{p_end}
{synopt:{opt qvalue(name)}}add a bracketed row with a multiple-testing
q-value; {it:name} is one of {cmd:bonferroni}, {cmd:sidak}, {cmd:holm},
{cmd:holland}, {cmd:hochberg}, {cmd:simes}, {cmd:yekutieli}, {cmd:bky}{p_end}
{synopt:{opt sd}}add a bracketed row with the standard deviation under each
mean{p_end}

{syntab:Output}
{synopt:{opt sheet(string)}}Excel worksheet name (and, optionally,
{cmd:export excel} suboptions) for {cmd:using}{p_end}
{synopt:{opt latex}}also (or instead of Excel, if {cmd:using} is omitted)
write a LaTeX table via {cmd:listtab}{p_end}
{synopt:{opt keep}}keep the generated table variables in the dataset in
memory instead of restoring the original data{p_end}
{synopt:{opt quiet}}suppress the estimation-command output and the "Outcome"
banners printed for each outcome{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
{it:fweight}s, {it:aweight}s, and {it:pweight}s are allowed; see
{help weight}. {cmd:by} is not allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:rctable} loops over each outcome in {it:varlist} and estimates either

{phang2}
{bf:ITT} ({cmd:estimator(itt)}, the default): {cmd:regress} {it:outcome} on
{cmd:treatment()}, {cmd:control()}, and the matching {cmd:basecontrol()}
variable, with robust (and, if {cmd:cluster()} is given, cluster-robust)
standard errors; or

{phang2}
{bf:LATE} ({cmd:estimator(late)}, or automatically when {cmd:treated()} is
specified): {cmd:ivregress 2sls} of {it:outcome} on {cmd:control()} and the
matching {cmd:basecontrol()} variable, instrumenting {cmd:treated()} with
{cmd:treatment()}.

{pstd}
For each outcome the program records the variable name and label, the
control-group and full-sample means (and, with {opt sd}, standard
deviations), the estimation sample size and number of clusters, and the
coefficient/standard error (with significance stars) for each treatment
arm (or for the instrumented {cmd:treated()} variable under LATE).
Optionally it adds a raw p-value row ({opt pvalue}) or a multiple-testing
q-value row ({opt qvalue()}). Two summary rows, "Observations" and
"Clusters", are appended at the bottom.

{pstd}
The table is written to {it:filename} via {cmd:export excel} when
{cmd:using} is specified, and/or to a LaTeX tabular via {cmd:listtab} when
{opt latex} is specified. By default the data in memory are preserved and
restored around the computation; {opt keep} instead leaves the table
variables (VAR, LAB, N_ind, N_clust, A, C, COEF1, COEF2, ...) appended to
the dataset in memory.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt treatment(varlist)} lists the treatment indicator(s), one per
treatment arm. With more than one treatment arm, {opt estimator(late)}
(and {opt treated()}) is not allowed.

{dlgtab:Sample and controls}

{phang}
{opt control(varlist fv)} lists control variables (factor-variable syntax
allowed) included, unchanged, in every outcome's regression.

{phang}
{opt basecontrol(varlist)} lists one control variable per outcome, matched
positionally to {it:varlist}: the first variable in {opt basecontrol()} is
added only to the regression for the first outcome in {it:varlist}, the
second to the second outcome, and so on. The number of variables in
{opt basecontrol()} must equal the number of outcomes in {it:varlist}, or
{cmd:rctable} exits with an error.

{phang}
{opt cluster(varlist)} specifies the cluster variable(s) for
{cmd:vce(cluster ...)}. If omitted, {cmd:regress ..., r} /
{cmd:ivregress 2sls ..., r} (heteroskedasticity-robust only) is used, and
the "Clusters" summary row is not produced.

{dlgtab:Estimator}

{phang}
{opt estimator(name)} is {cmd:itt} or {cmd:late}. Default is {cmd:itt}
unless {opt treated()} is specified, in which case {cmd:late} is used
automatically.

{phang}
{opt treated(varlist)} names the single endogenous "treated" variable to
be instrumented by {opt treatment()} under LATE. Specifying it implies
{opt estimator(late)}; specifying more than one variable, or combining it
with more than one {opt treatment()} arm, is not allowed.

{dlgtab:Inference display}

{phang}
{opt pvalue} adds, under each coefficient's standard-error row, a further
row showing the regression p-value in brackets, e.g. {cmd:[0.03]}. Cannot
be combined with {opt qvalue()}.

{phang}
{opt qvalue(name)} adds a bracketed multiple-testing-adjusted q-value row
instead of a raw p-value row. {it:name} selects the adjustment method and
must be one of {cmd:bonferroni}, {cmd:sidak}, {cmd:holm}, {cmd:holland},
{cmd:hochberg}, {cmd:simes}, {cmd:yekutieli}, or {cmd:bky} (Benjamini,
Krieger, and Yekutieli two-stage adaptive procedure). All methods other
than {cmd:bky} are computed via the user-written command {cmd:qqvalue}
(from SSC; installed automatically if not already present). Cannot be
combined with {opt pvalue}.

{phang}
{opt sd} adds a bracketed standard-deviation row under each control-group
and full-sample mean.

{dlgtab:Output}

{phang}
{opt sheet(string)} is passed to {cmd:export excel}'s {cmd:sheet()}
option and controls the destination worksheet in {it:filename}. It may
include additional {cmd:export excel} suboptions after a comma, e.g.
{cmd:sheet(results, sheetreplace)}; if {opt sheet()} is not specified,
{cmd:export excel} is called with {cmd:replace} instead, overwriting the
whole file. Only used when {cmd:using} is specified.

{phang}
{opt latex} additionally writes a LaTeX tabular (via {cmd:listtab}, from
SSC; installed automatically if not already present) with one column per
treatment arm.

{phang}
{opt keep} leaves the generated table variables (and any pre-existing
data) in memory rather than restoring the original dataset, and reorders
them to the end of the dataset. {cmd:rctable} refuses to run under
{opt keep} if the dataset already contains variables named {cmd:VAR},
{cmd:LAB}, {cmd:N_ind}, {cmd:N_clust}, {cmd:A}, {cmd:C}, or any
{cmd:COEF*} variable.

{phang}
{opt quiet} suppresses the underlying {cmd:regress}/{cmd:ivregress}
output and the per-outcome "Outcome ..." banner. (Note: despite the name,
this is the option that turns output {it:off}; there is no separate
"noisily" option.)


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Row layout.} Each outcome occupies 2 rows (coefficient / standard
error), or 3 rows if {opt pvalue} or {opt qvalue()} is specified (the
third row holds the bracketed p- or q-value). After the last outcome, one
"Observations" row and, if {opt cluster()} is specified, one "Clusters"
row are appended.

{pstd}
{ul:Control-group vs. full-sample statistics.} Column {cmd:C} reports the
mean (and, with {opt sd}, standard deviation) of the outcome among
observations for which every treatment-arm variable in {opt treatment()}
equals 0; column {cmd:A} reports the same statistic over the full
estimation sample.

{pstd}
{ul:Number formatting.} Coefficients, standard errors, and means/SDs are
formatted by the internal helper {cmd:_rctfmt}, which adapts the number of
decimal places to magnitude (3 decimals if |x|<10, 2 if <100, 1 if <1000,
0 otherwise) and rewrites "-0.000" as "0.000". Significance stars follow
the usual convention: *** p<=0.01, ** p<=0.05, * p<=0.10.

{pstd}
{ul:BKY q-values.} When {cmd:qvalue(bky)} is requested, {cmd:rctable}
implements the Benjamini-Krieger-Yekutieli two-stage sharpened
false-discovery-rate procedure directly (it does not call {cmd:qqvalue}),
searching over candidate FDR levels from 1 down to just above 0 in steps
of 0.001.

{pstd}
{ul:_rctfmt.} {cmd:_rctfmt} is an internal helper program (not intended to
be called directly by users).


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rctable} does not leave behind results of its own ({cmd:r()} or
{cmd:e()}); the last outcome's regression or {cmd:ivregress 2sls} results
remain in {cmd:e()} after the command completes.


{marker examples}{...}
{title:Examples}

{pstd}Basic ITT table, robust SEs, exported to Excel{p_end}
{phang2}{cmd:. rctable earnings hours using "results.xlsx", treatment(treat) sheet(itt)}{p_end}

{pstd}ITT with controls, a baseline control per outcome, and clustering{p_end}
{phang2}{cmd:. rctable earnings hours using "results.xlsx", treatment(treat) control(age i.region) basecontrol(earnings_bl hours_bl) cluster(hh_id) sheet(itt) sd}{p_end}

{pstd}LATE, instrumenting take-up with random assignment{p_end}
{phang2}{cmd:. rctable earnings using "results.xlsx", treatment(assigned) treated(participated) cluster(hh_id) sheet(late)}{p_end}

{pstd}Add raw p-values{p_end}
{phang2}{cmd:. rctable earnings hours using "results.xlsx", treatment(treat) cluster(hh_id) sheet(itt) pvalue}{p_end}

{pstd}Add Benjamini-Hochberg-style q-values instead{p_end}
{phang2}{cmd:. rctable earnings hours using "results.xlsx", treatment(treat) cluster(hh_id) sheet(itt) qvalue(hochberg)}{p_end}

{pstd}Keep the table in memory instead of restoring the original data{p_end}
{phang2}{cmd:. rctable earnings hours, treatment(treat) cluster(hh_id) keep}{p_end}

{pstd}Also produce a LaTeX table{p_end}
{phang2}{cmd:. rctable earnings hours using "results.xlsx", treatment(treat) cluster(hh_id) sheet(itt) latex}{p_end}


{marker References} {...}
{title:References}

{p 4 6 2}
Benjamini, Yoav and Krieger, Abba M and Yekutieli, Daniel (2006), Adaptive linear step-up procedures that control the false discovery rate, Biometrika, vol.93, n 3, pages 491--507,{p_end} 
{p 4 6 2}
Michael L. Anderson (2008), Multiple Inference and Gender Differences in the Effects of Early Intervention: A Reevaluation of the Abecedarian, Perry Preschool, and Early Training Projects},
Journal of the American Statistical Association, volume 103, number 484, pages 1481-1495. {p_end} 


{marker author}{...}
{title:Author}

Adrien Bouguen, 
abouguen@scu.edu
Santa Clara University,  
Economics department

{pstd}
This help file documents the user-written command {cmd:rctable}, version
3.0 (9/25/2026).
