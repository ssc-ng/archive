{smcl}
{* *! version 2.3.0 29sep2026}{...}
{title:Title}
{p 4 4}{cmd:xtie2} — Fixed-effects panel interactions, conditional effects, and Johnson–Neyman regions{p_end}

{title:Syntax}
{p 8 12 2}{cmd:xtie2} {it:depvar indepvars} {ifin} [{cmd:,} {opt robust} {opt level(#)} {opt pair(var1 var2)}]{p_end}

{title:Description}
{pstd}{cmd:xtie2} fits {cmd:xtreg, fe} with all pairwise interactions among the explanatory variables. By default the first two explanatory variables are the focal pair. {cmd:pair()} selects any two explanatory variables and internally places them first; the fitted model is unchanged by this ordering. All explanatory variables are treated as continuous. For the focal conditional effects, the remaining explanatory variables enter through their interactions with the focal variables and are held at their estimation-sample means. Declare the panel with {cmd:xtset} first. This command does not estimate Hansen-type panel thresholds.{p_end}
{pstd}For a model with x1, x2 and additional variables zk, the effect of x1 at x2=v, holding each zk at its estimation-sample mean, is b1 + b12*v + sum_k b1k*mean(zk). The effect of x2 is analogous. Standard errors use the full covariance matrix of these coefficients. No causal interpretation is implied by the command.{p_end}

{title:Options}
{phang}{opt robust} uses {cmd:xtreg, fe vce(robust)}, which clusters by panel.{p_end}
{phang}{opt level(#)} gives the confidence level for Johnson–Neyman regions; default 95.{p_end}
{phang}{opt pair(var1 var2)} chooses the two focal explanatory variables for conditional effects. Both must appear in the explanatory varlist and be different. The default is the first two explanatory variables, preserving earlier command usage.{p_end}

{title:Results and limits}
{pstd}The command displays the primary interaction coefficient, conditional marginal effects at the focal moderator's minimum, mean, median and maximum, analytic zero crossings, and Johnson–Neyman boundaries where the absolute t statistic equals its critical value. A zero crossing need not be a statistically significant boundary; a boundary may fall outside the observed range. Degenerate cases have no unique pair of JN boundaries. Variables must be continuous; categorical variables and factor notation are not accepted in the input varlist.{p_end}
{pstd}The command creates {cmd:me_x1}, {cmd:me_x2}, and, when the primary interaction is nonzero, {cmd:regime_x2} for estimation-sample observations. It stops if those names already exist and never overwrites them. The regime variable merely classifies observations around the zero crossing; it is not an estimated threshold regime. Generated names must fit Stata's variable-name length limit.{p_end}

{title:Stored results}
{pstd}The underlying {cmd:xtreg} {cmd:e(b)}, {cmd:e(V)}, and {cmd:e(sample)} are retained, together with {cmd:e(depvar)}, {cmd:e(indepvars)}, {cmd:e(primary_interaction)}, {cmd:e(beta_inter)}, {cmd:e(se_inter)}, {cmd:e(t_inter)}, {cmd:e(p_inter)}, and {cmd:e(level)}. Existing {cmd:e(critical_x1)} and {cmd:e(critical_x2)} are retained when defined. Aliases {cmd:e(zero_cross_x1)} and {cmd:e(zero_cross_x2)} are added. When two JN boundaries exist, {cmd:e(JN_x1_low)}, {cmd:e(JN_x1_high)}, {cmd:e(JN_x2_low)}, and {cmd:e(JN_x2_high)} are returned. Values are absent when undefined.{p_end}

{title:Example}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtie2 unemployment inflation energy_dependency gdp_growth, robust level(95)}{p_end}
{phang2}{cmd:. xtie2 unemployment inflation energy_dependency gdp_growth, pair(energy_dependency gdp_growth) robust}{p_end}

{title:Authors}
{pstd}Dr. Zehra Yalnız and Prof. Dr. Figen Büyükakın, Kocaeli University, Türkiye.{p_end}
