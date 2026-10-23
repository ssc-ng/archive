{smcl}
{* *! version 3  2026-10-19}{...}
{viewerjumpto "Syntax" "multisite_varLATE##syntax"}{...}
{viewerjumpto "Description" "multisite_varLATE##description"}{...}
{viewerjumpto "Stored results" "multisite_varLATE##results"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_varLATE} {hline 2} Estimates and conducts inference on the variance of LATEs across sites in multi-site randomized trials with imperfect compliance, see Section 3.3.2 of de Chaisemartin & Deeb (2026).
The command reports the overall LATE (sites weighted in proportion to their number of compliers), a lower bound for the variance of site-specific LATEs under those complier weights, the average of site-specific LATEs under weights proportional to sites' squared first stages,
the variance of site-specific LATEs under the same squared-first-stage weights, and the ratio of the standard deviation of LATEs to the average LATE under those weights.
The command can also be used to estimate the variance of LATEs across strata in stratified RCTs with imperfect compliance. The command can also be used
outside of RCTs, when one has a binary instrument assigned as-good-as randomly within some sites or strata.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_varLATE outcome treatment instrument site} [if] [aweight]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the dependent variable of interest.
{p_end}

{p 4 8}
{cmd:treatment} is an indicator variable for whether a unit is treated
{p_end}

{p 4 8}
{cmd:instrument} is an indicator variable for whether a unit is assigned to treatment
{p_end}

{p 4 8}
{cmd:site} is a numeric variable identifying each site/stratum.
{p_end}

{p 4 8}
The output table has five rows. Row 1 is the overall LATE, the ratio of the weighted average ITT effect to the weighted average first stage, which weights site-specific LATEs in proportion to sites' shares of compliers.
Row 2 is a lower bound for the variance of site-specific LATEs under the same complier weights (Equation (17) in Proposition 2 of the paper). This variance is not identified from moments of sites' ITT and first-stage effects, but the bound is; the bound is zero if and only if LATEs are constant across sites, so it can be used to test that hypothesis.
Row 3 is the average of site-specific LATEs under weights proportional to sites' squared first stages (LATE_FS2). Row 4 is the variance of site-specific LATEs under the same squared-first-stage weights,
estimated from corrected moments of sites' ITT and first-stage effects without estimating any site-specific LATE (Equation (16) in Proposition 2 of the paper). Row 5 is the square root of Row 4 divided by Row 3.
Standard errors are based on the influence functions in Theorem 4 and Appendix A.2 of de Chaisemartin & Deeb (2026).
{p_end}

{marker results}{...}
{title:Stored results}

{p 4 8}
{cmd:e(LATE_hat)}, {cmd:e(se_late_hat)}, {cmd:e(lb_CI_late)}, {cmd:e(ub_CI_late)}: overall LATE, its standard error and 95% confidence interval.
{p_end}
{p 4 8}
{cmd:e(var_LATE_lb)}, {cmd:e(se_var_late_lb)}, {cmd:e(lb_CI_var_late_lb)}, {cmd:e(ub_CI_var_late_lb)}: lower bound for the variance of site-specific LATEs under complier weights, its standard error and 95% confidence interval. Missing if the corrected mean of squared first stages is not below the mean first stage, in which case the bound is not defined.
{p_end}
{p 4 8}
{cmd:e(LATE_FS2_hat)}, {cmd:e(se_late_FS2_hat)}, {cmd:e(lb_CI_late_FS2)}, {cmd:e(ub_CI_late_FS2)}: average of site-specific LATEs under squared-first-stage weights, its standard error and 95% confidence interval.
{p_end}
{p 4 8}
{cmd:e(var_LATE)}, {cmd:e(se_var_late)}, {cmd:e(lb_CI_var_late)}, {cmd:e(ub_CI_var_late)}: variance of site-specific LATEs under squared-first-stage weights, its standard error and 95% confidence interval.
{p_end}
{p 4 8}
{cmd:e(ratio_sd_late)}: square root of {cmd:e(var_LATE)} divided by {cmd:e(LATE_FS2_hat)}. {cmd:e(mean_FS)}: weighted average first stage. {cmd:e(mean_FS2)}: corrected weighted average of sites' squared first stages. {cmd:e(N)}, {cmd:e(Sites)}: number of units and sites used.
{p_end}

{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:What are the data requirements and assumptions required to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment, with at least two units assigned to treatment and control per site (stratum). As such, the command automatically drops any sites (strata) not satisfying this requirement.
The estimators also require the usual exclusion restriction and monotonicity conditions, and that every site has a strictly positive first stage; see Assumption 4 in {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4615304":Estimating treatment-effect heterogeneity across sites, in multi-site randomized experiments with few units per site}.
{p_end}

{p 4 8}
{it:Why are LATEs weighted by squared first stages, and why is the complier-weighted variance only bounded?}
{p_end}

{p 4 4} With few units per site, site-specific LATEs cannot be estimated without bias, so a corrected variance estimator cannot be applied to them directly. Weighting by squared first stages makes the variance of LATEs a ratio of moments of sites' ITT and first-stage effects, which can be estimated without bias.
The complier-weighted variance involves the ratio of squared ITT effects to first stages, which is not identified from such moments; the Cauchy-Schwarz inequality gives the lower bound in Row 2, which uses only identified moments. See Section 3.3.2 of the paper.
{p_end}

{p 4 8}
{it:The results in the paper allow for weights w_s, what w_s does the command use?}
{p_end}

{p 4 4} The command uses w_s=n_s/n, the proportion that site s accounts for in the population. Then, site-specific LATEs are weighted by w_s times the site's first stage in Rows 1 and 2, and by w_s times the site's squared first stage in Rows 3 to 5.
{p_end}

{p 4 8}
{it:What does [aweight] do then?}
{p_end}

{p 4 4}
[aweight] allows to use weights to estimate the ITT and FS effects in each site, and the variance of those effects. [aweight] does not affect w_s.
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
