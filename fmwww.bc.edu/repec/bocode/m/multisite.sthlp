{smcl}
{* *! version 2  2026-10-19}{...}
{viewerjumpto "Syntax" "multisite##syntax"}{...}
{viewerjumpto "Description" "multisite##description"}{...}

{title:Title}

{p 4 8}
{cmd:multisite} {hline 2} Library of commands to estimate treatment-effect heterogeneity across sites in
multi-site randomized experiments with few units per site.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite}
{p_end}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:multisite} wraps in four commands to estimate treatment-effect heterogeneity across sites in multi-site RCTs, and more generally in stratified RCTs. The four commands wrapped by {cmd:multisite} respectively estimate the variance of ITTs across sites, the variance of LATEs across sites, the regressions of ITTs on explanatory variables, and relationships between site-level LATEs across outcomes and treatment arms.

{p 4 8}One just needs to install {cmd:multisite} and execute it once to install those four commands.

{p 4 8}
{cmd:multisite_varITT} computes the estimated variance of ITTs across sites in multi-site randomized trials.

{p 12 12}
{help multisite_varITT}. 
{p_end}

{p 4 8}
{cmd:multisite_varLATE} computes the estimated variance of LATEs across sites in multi-site randomized trials.

{p 12 12}
{help multisite_varLATE}. 
{p_end}

{p 4 8}
{cmd:multisite_regITT} computes the coefficients from a regression of site-level ITTs on site-level characteristics in multi-site randomized trials.

{p 12 12}
{help multisite_regITT}. 
{p_end}

{p 4 8}
{cmd:multisite_regLATE} estimates the coefficients from a regression of a treatment's site-level LATE on one outcome on its site-level LATEs on other outcomes, and the covariance-variance ratio relating two treatments' site-level LATEs on the same outcome, in multi-site randomized trials.

{p 12 12}
{help multisite_regLATE}. 
{p_end}

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
