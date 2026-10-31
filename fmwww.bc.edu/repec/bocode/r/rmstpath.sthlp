{smcl}
{* *! rmstpath 0.1.3 16oct2026}{...}
{title:Title}

{p 4 4 2}{cmd:rmstpath} -- Unadjusted Kaplan-Meier RMST difference versus horizon, with pointwise confidence intervals (v0.1.3)

{title:Syntax}

{p 8 12 2}{cmd:rmstpath} {it:groupvar} {ifin}{cmd:,} {opt tau(numlist)}
[{opt primary(#)} {opt level(#)} {opt nograph} {opt cistyle(band|lines)}
{opt units(text)} {opt saving(filename[, replace])} {opt name(graphname)} {it:twoway_options}]

{title:Description}

{p 4 4 2}{cmd:rmstpath} computes two independent-group unadjusted Kaplan-Meier restricted mean survival times and their higher-coded minus lower-coded group difference. Results and normal Greenwood plug-in pointwise confidence limits are reported at the user-specified horizons in {cmd:tau()}.{p_end}

{p 4 4 2}For the graph, the estimated RMST difference is drawn at each observed pooled failure time, as well as at the requested horizons, zero, and a dense display grid. Its kinks thus occur at the event times rather than being joined only across the user-requested horizons. The confidence bounds are evaluated pointwise on the fine plotting grid, and the displayed area between points is a visual interpolation, {bf:not a simultaneous confidence band}.{p_end}

{p 4 4 2}Requires {cmd:stset} single-record right-censored data with entry at zero and exactly two numeric treatment groups. {bf:Weighted stset data are rejected}, not silently analyzed as unweighted. Survey and sampling weights, clustering, covariate adjustment, left truncation, multiple records, competing risks, and adjusted survival models are not implemented.{p_end}

{title:Options}

{phang}{opt tau(numlist)} is required. Supply two or more distinct positive horizons in the same units as survival time, e.g. {cmd:tau(6(6)36)}. Horizons beyond either arm's maximum observed follow-up are not allowed.{p_end}
{phang}{opt primary(#)} adds a reference line for a prespecified primary horizon that must appear in {cmd:tau()}. No multiplicity adjustment is implied.{p_end}
{phang}{opt level(#)} sets the pointwise confidence level. The default follows {cmd:set level} (typically 95). Valid confidence levels follow Stata {cmd:level(cilevel)} conventions (10 to 99.99).{p_end}
{phang}{opt nograph} prevents graph generation.{p_end}
{phang}{opt cistyle(band|lines)} selects a grayscale confidence band (default) or dashed CI limits.{p_end}
{phang}{opt units(text)} labels axes and the horizon note; it never rescales time. Defaults to {cmd:time units}.{p_end}
{phang}{opt saving(filename[, replace])} saves the {cmd:tau()} numerical table, not the denser plotting data, to a Stata dataset. The {cmd:replace} suboption is required to overwrite an existing file. For backward compatibility, the experimental 0.1.2 form {cmd:saving(filename) replace} still works, but it is not the recommended syntax.{p_end}
{phang}{opt name(graphname)} gives the generated graph a distinct Stata memory name without silently replacing an existing graph of that name. If omitted, the legacy graph name is {cmd:RMSTPath}, replaced on repeated calls.{p_end}
{phang}{it:twoway_options} are forwarded to {cmd:graph twoway}, for example {cmd:xlabel()}, {cmd:yscale()}, {cmd:xsize()}, {cmd:ysize()}, {cmd:title()}, {cmd:scheme()}, {cmd:graphregion()}, and {cmd:plotregion()}. User titles and axes/region styles override matching defaults. {cmd:name()} is handled separately as above. Graph-specific options do nothing with {cmd:nograph}.{p_end}

{title:Printed and returned results}

{p 4 4 2}Printed columns are horizon, each arm's RMST, difference, standard error, lower/upper pointwise confidence limits, and numbers at risk (Risk0/Risk1) immediately before the horizon. The table is also stored as {cmd:r(results)} with columns {cmd:tau rmst0 rmst1 diff se ll ul nrisk0 nrisk1}. Other returned values include {cmd:r(group0)}, {cmd:r(group1)}, {cmd:r(n0)}, {cmd:r(n1)}, {cmd:r(events0)}, {cmd:r(events1)}, {cmd:r(max_follow0)}, {cmd:r(max_follow1)}, {cmd:r(level)}, {cmd:r(k_tau)}, optionally {cmd:r(primary)} and {cmd:r(graph_name)}.{p_end}

{title:Examples}

{phang2}{cmd:. stset time, failure(event==1)}{p_end}
{phang2}{cmd:. rmstpath treatment, tau(6(6)36) primary(24) units(months)}{p_end}
{phang2}{cmd:. graph export "rmst_difference.pdf", name(RMSTPath) replace}{p_end}
{phang2}{cmd:. rmstpath treatment, tau(6(6)36) level(90) name(RMST90) xlabel(0(6)36)}{p_end}
{phang2}{cmd:. rmstpath treatment, tau(6(6)36) nograph saving("rmst_results.dta", replace)}{p_end}

{title:Statistical method}

{p 4 4 2}For each group, RMST at horizon tau is the integral of Kaplan-Meier survival from zero to tau. The plug-in variance is the sum over failure times earlier than tau of [integral from event time to tau of Kaplan-Meier survival]^2 times d/[Y(Y-d)]. The risk set includes censored observations tied with failures at that instant. Terminal complete failures contribute zero tail-area variance. The variance for the difference is the sum of independent group variances, with a normal critical value for its pointwise CI.{p_end}

{p 4 4 2}Pointwise intervals do {bf:not} provide simultaneous coverage over a range of horizons. A zero-event arm has zero estimated Greenwood variance; that is not evidence of precise inference. At-risk counts should inform interpretation of later-horizon estimates. The plotted CI limits are calculated at all pooled failure times and a fine horizon grid; any rendering between adjacent plotting points is a visual approximation to continuously varying confidence limits.{p_end}

{title:Relationship to existing commands}

{p 4 4 2}{cmd:strmst2} calculates arm-specific and contrast RMST at a single horizon and supports adjustment. {cmd:standsurv} already graphs standardized RMST contrasts across horizons using model-based survival. {cmd:rmstpath} is a lightweight standalone {bf:unadjusted} KM table and event-knot path workflow. It does not introduce a new RMST estimator or simultaneous confidence band.{p_end}

{title:Validation and release scope}

{p 4 4 2}The original RMST table engine was checked against 20 independent numerical references and against {cmd:strmst2} in 16 dataset-horizon combinations, agreeing to floating-point precision. Stata v0.1.3 subsequently passed its seven dedicated interface and safeguard tests, six release edge-case tests, and the earlier functional and graph smoke tests. The new graph calculations were independently cross-checked against the tabulation formula at 2,836 Python reference points. These tests do not establish finite-sample confidence coverage or simultaneous inference. Use at-risk counts to assess tail reliability. An isolated {cmd:net install}, {cmd:help rmstpath} lookup, and installed-command numerical smoke test all passed in Stata on 16 October 2026.{p_end}

{title:References}

{p 4 4 2}Cronin A, Tian L, Uno H. 2016. strmst2 and strmst2pw: New commands to compare survival curves using restricted mean survival time. {it:Stata Journal} 16: 702-716.{p_end}
{p 4 4 2}Klein JP, Moeschberger ML. 2003. {it:Survival Analysis: Techniques for Censored and Truncated Data}. 2nd ed. Springer.{p_end}

{title:Author}

{p 4 4 2}Christina Laternser.{p_end}
