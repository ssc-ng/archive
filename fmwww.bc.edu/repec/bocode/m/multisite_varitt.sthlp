{smcl}
{* *! version 1.1  2026-10-19}{...}
{viewerjumpto "Syntax" "multisite_varITT##syntax"}{...}
{viewerjumpto "Description" "multisite_varITT##description"}{...}
{viewerjumpto "Stored results" "multisite_varITT##results"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_varITT} {hline 2} Estimates and conducts inference on the variance of ITTs across sites in multi-site randomized trials, 
and provides the ratio of the standard deviation of ITTs across sites to the average ITT, see Section 3.1 of de Chaisemartin & Deeb (2026) and the application in Section 4.2. The variance is estimated from corrected moments of sites' ITT estimators (Proposition 1); standard errors use the influence function of Theorem 1.
The command can also be used to estimate the variance of ITT effects across strata in stratified RCTs.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_varITT outcome instrument site} [if] [aweight]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the dependent variable of interest.
{p_end}

{p 4 8}
{cmd:instrument} is an indicator variable for whether a unit is assigned to treatment
{p_end}

{p 4 8}
{cmd:site} is a numeric variable identifying each site/stratum.
{p_end}

{marker results}{...}
{title:Stored results}

{p 4 8}
{cmd:e(itt_hat)}, {cmd:e(se_itt_hat)}, {cmd:e(lb_CI_itt)}, {cmd:e(ub_CI_itt)}: weighted average ITT, its standard error and 95% confidence interval.
{p_end}
{p 4 8}
{cmd:e(var_itt)}, {cmd:e(se_varitt)}, {cmd:e(lb_CI_var_itt)}, {cmd:e(ub_CI_var_itt)}: variance of ITTs across sites, its standard error and 95% confidence interval. {cmd:e(N)}, {cmd:e(Sites)}: number of units and sites used.
{p_end}

{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:What are the data requirements to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment, with at least two units assigned to treatment and control per site (stratum). As such, the command automatically drops any sites (strata) not satisfying this requirement.
{p_end}

{p 4 8}
{it:The results in the paper allow for weights w_s, what w_s does the command use?}
{p_end}

{p 4 4} The command automatically weights each site by its sample size: w_s=n_s/n
{p_end}

{p 4 8}
{it:What does [aweight] do then?}
{p_end}

{p 4 4}
[aweight] allows to use weights to estimate the ITT effects in each site, and the variance of those effects. [aweight] does not affect w_s. 
{p_end}

{marker references}{...}
{title:References}

{p 4 8}de Chaisemartin, C and Deeb, A (2026).
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4615304":Estimating treatment-effect heterogeneity across sites, in multi-site randomized experiments with few units per site}.{p_end}



{title:Authors}

{p 4 8}Clément de Chaisemartin, Sciences Po.{p_end}
{p 4 8}Antoine Deeb, World Bank.{p_end}
{p 4 8}Bingxue Li, Sciences Po.{p_end}

{title:Contact}
{browse "mailto:adeeb1@worldbank.org":adeeb1@worldbank.org}
{browse "mailto:chaisemartin.packages@gmail.com":chaisemartin.packages@gmail.com}
