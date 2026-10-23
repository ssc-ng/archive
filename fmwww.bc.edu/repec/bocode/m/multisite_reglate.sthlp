{smcl}
{* *! version 2  2026-10-19}{...}
{viewerjumpto "Syntax" "multisite_regLATE##syntax"}{...}
{viewerjumpto "Description" "multisite_regLATE##description"}{...}
{viewerjumpto "Options" "multisite_regLATE##options"}{...}
{viewerjumpto "Stored results" "multisite_regLATE##results"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_regLATE} {hline 2} Estimates relationships between site-specific LATEs in multi-site randomized trials with imperfect compliance, see Section 3.3.4 of de Chaisemartin & Deeb (2026).
Two targets are available. With {cmd:outcomes()}, the command estimates the coefficients from the regression of a treatment arm's site-specific LATE on one outcome on its site-specific LATEs on other outcomes, with weights proportional to the arm's squared first stage.
With {cmd:cross()}, it estimates the covariance-variance ratio relating a second treatment arm's site-specific LATE on an outcome to the first arm's site-specific LATE on the same outcome.
Neither target requires estimating any site-specific LATE: both are functions of second moments of sites' ITT and first-stage effects, which are estimated without bias.
The command can also be applied to stratified RCTs with imperfect compliance. The command can also be used
outside of RCTs, when one has a binary instrument assigned as-good-as randomly within some sites or strata.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_regLATE outcome treatment instrument site} [if] [aweight] [{cmd:,}
{cmd:outcomes(}{it:varlist numeric}{cmd:)}
{cmd:cross(}{it:treatment2 instrument2}{cmd:)}
]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the outcome whose LATE is the dependent variable (outcome 1 in the paper's notation).
{p_end}

{p 4 8}
{cmd:treatment} is an indicator variable for whether a unit takes up the first treatment.
{p_end}

{p 4 8}
{cmd:instrument} is an indicator variable for whether a unit is assigned to the first treatment.
{p_end}

{p 4 8}
{cmd:site} is a numeric variable identifying each site/stratum.
{p_end}

{marker options}{...}
{title:Options}

{p 4 8}
{cmd:outcomes(}{it:varlist numeric}{cmd:)} estimates beta^d of Section 3.3.4: the coefficients from the regression of the LATE of the treatment on {cmd:outcome} on the LATEs of the same treatment on the outcomes in {it:varlist}, with weights proportional to sites' squared first stages (Proposition 4, point 1).
Units with {cmd:instrument} equal to zero form the control group; if the data contain units assigned to another treatment, restrict the sample with {cmd:if}. Sites with fewer than two assigned or two non-assigned units are dropped. One coefficient per variable in {it:varlist} is reported.
{p_end}

{p 4 8}
{cmd:cross(}{it:treatment2 instrument2}{cmd:)} estimates beta^12 of Section 3.3.4: the ratio of the covariance between the first and second treatments' site-specific LATEs on {cmd:outcome}, under weights proportional to the product of the two first stages, to the variance of the first treatment's LATE under weights proportional to its squared first stage (Proposition 4, point 2).
{it:treatment2} and {it:instrument2} are the take-up and assignment indicators of the second treatment; units with both instruments equal to zero form the control group. Sites with fewer than two units in any of the three arms are dropped. The command also reports the numerator and the denominator of the ratio.
{p_end}

{p 4 8}
Exactly one of the two options must be specified. Standard errors are based on the influence functions in Appendix A.4 of the paper.
{p_end}

{marker results}{...}
{title:Stored results}

{p 4 8}
{cmd:e(b)}, {cmd:e(V)}: the estimated coefficients and their estimated variance matrix, so that {cmd:ereturn display}, {cmd:test} and {cmd:lincom} can be used. {cmd:e(N)}, {cmd:e(Sites)}: number of units and sites used. {cmd:e(target)}: "beta_d" or "beta_12".
{p_end}
{p 4 8}
With {cmd:outcomes()}: {cmd:e(LATE_FS2_}{it:j}{cmd:)}: squared-first-stage-weighted average LATE on outcome {it:j} (1 is {cmd:outcome}, 2 onwards are the variables in {cmd:outcomes()}); {cmd:e(mean_FS2)}: corrected weighted average of sites' squared first stages; {cmd:e(predictors)}: the variables in {cmd:outcomes()}.
{p_end}
{p 4 8}
With {cmd:cross()}: {cmd:e(beta12)}, {cmd:e(se_beta12)}, {cmd:e(lb_CI_beta12)}, {cmd:e(ub_CI_beta12)}: the ratio, its standard error and 95% confidence interval; {cmd:e(cov12)}, {cmd:e(se_cov12)}: its numerator; {cmd:e(var1)}, {cmd:e(se_var1)}: its denominator; {cmd:e(LATE1_FS2)}: squared-first-stage-weighted average LATE of the first treatment.
{p_end}

{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:What are the data requirements and assumptions required to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment with at least two units per site in each arm used. The estimators require the exclusion restriction, monotonicity and a strictly positive first stage in every site, for each treatment; with {cmd:cross()}, assignment to one treatment must not change take-up of the other, which holds automatically with one-sided non-compliance. See Assumption 4 and Proposition 4 of the paper.
{p_end}

{p 4 8}
{it:Why is beta^12 not a regression coefficient?}
{p_end}

{p 4 4} Its numerator weights sites by the product of the two first stages and its denominator by the squared first stage of the first treatment. The corresponding weighted regression coefficient has the same sign and coincides with beta^12 when the two first stages are proportional across sites, but it cannot be written in terms of second moments of ITTs and first stages, so it is generally not estimable with few units per site.
{p_end}

{p 4 8}
{it:What weights w_s does the command use, and what does [aweight] do?}
{p_end}

{p 4 4} Sites are weighted by w_s=n_s/n, their share of the units; the targets then weight sites by w_s times squared or cross-products of first stages, as described above. [aweight] weights units when estimating each site's ITT and first-stage effects and their variances; it does not affect w_s.
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
