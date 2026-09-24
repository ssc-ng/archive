{smcl}
{* *! version 2.0 23sep2026}{...}

{title:Title}

{phang}
{bf:xtie2} {hline 2} Interactive Panel Data Estimation with automatic pairwise interactions

{title:Syntax}

{p 8 15 2}
{cmd:xtie2} {it:depvar indepvars} [{cmd:, robust}]

{title:Description}

{pstd}
{cmd:xtie2} estimates a fixed-effects panel model including all pairwise interactions among the explanatory variables.

{pstd}
The first variable is treated as the dependent variable.

{pstd}
The first two explanatory variables define the primary interaction used for marginal-effect analysis.

{pstd}
The command reports the interaction coefficient, its standard error, t statistic and p value.

{pstd}
It also calculates marginal effects and marginal-effect zero-crossing critical values.

{title:Options}

{phang}
{cmd:robust} requests robust standard errors in the fixed-effects model.

{title:Example}

{phang2}
{cmd:. xtset country_id year}

{phang2}
{cmd:. xtie2 unemployment energy_dependency energy_price_index inflation gdp_growth, robust}

{title:Stored results}

{pstd}
{cmd:xtie2} stores the following results in {cmd:e()}:

{synoptset 25 tabbed}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}independent variables{p_end}
{synopt:{cmd:e(beta_inter)}}primary interaction coefficient{p_end}
{synopt:{cmd:e(se_inter)}}standard error of primary interaction{p_end}
{synopt:{cmd:e(t_inter)}}t statistic of primary interaction{p_end}
{synopt:{cmd:e(p_inter)}}p value of primary interaction{p_end}
{synopt:{cmd:e(critical_x1)}}zero-crossing value for the marginal effect of the second variable{p_end}
{synopt:{cmd:e(critical_x2)}}zero-crossing value for the marginal effect of the first variable{p_end}

{title:Remarks}

{pstd}
The reported critical values are marginal-effect zero-crossing values.

{pstd}
They are not Hansen-type panel threshold estimates.

{title:Author}

{pstd}
Dr. Zehra Yalnız

{pstd}
Kocaeli University, Türkiye

{pstd}
Email: zehrayalnizz41@gmail.com

{pstd}
ORCID: 0000-0003-2633-2022

{title:Version}

{pstd}
Version 2.0, September 2026.
{pstd}
Version 2.0, September 2026.