{smcl}
{* *! version 3.4 12 OCTOBER 2026 Soo Jeong Lee and Jeffrey M. Wooldridge *}
{viewerjumpto "Syntax" "lwdid##syntax"}{...}
{viewerjumpto "Options" "lwdid##options"}{...}
{viewerjumpto "Saved results" "lwdid##results"}{...}
{viewerjumpto "Description" "lwdid##description"}{...}
{viewerjumpto "Examples" "lwdid##examples"}{...}
{viewerjumpto "Citation" "lwdid##citation"}{...}
{viewerjumpto "Authors" "lwdid##author"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:lwdid} {hline 2}}Transformation-based rolling DID estimator (Lee & Wooldridge, 2026a, 2026b){p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:lwdid} {it:varlist} [{it:if}] [{it:in}],
{cmd:ivar(}{it:varname}{cmd:)}
{cmd:tvar(}{it:varname}{cmd:)}
{cmd:gvar(}{it:varname}{cmd:)}
{cmd:rolling(}{it:type}{cmd:)}
[{it:options}]

{marker argsopts}{...}
{title:Arguments and Options}

{synoptset 28 tabbed}{...}
{synopthdr:Options}
{synoptline}

{syntab:Main variables}
{synopt:{it:varlist}}Outcome variable followed by optional covariates (x-variables).{p_end}

{syntab:Required options}
{synopt:{opt ivar(varname)}}Panel identifier (numeric or string).{p_end}

{synopt:{opt tvar(varname)}}Time variable, supplied as a single numeric time index. {p_end}

{synopt:{opt gvar(varname)}}Treatment cohort variable indicating the first-treated period for each unit. {cmd:gvar()} should be constant across all observations within each treated unit. Never-treated units should be coded as 0 or missing. {cmd:gvar()} must be measured on the same scale as {cmd:tvar()}.{p_end}

{synopt:{opt rolling(type)}}Unit-specific outcome transformation for {it:yvar}:{break}
{space 2}{bf:demean}   removes the pre-treatment mean{break} 
{space 2}{bf:detrend}  removes the pre-treatment linear trend{break} 
{space 2}{bf:demeanq}  removes the pre-treatment mean and quarterly seasonal effects{break} 
{space 2}{bf:detrendq} removes the pre-treatment linear trend and quarterly seasonal effects{break} 
{space 2}{bf:demeanm}  removes the pre-treatment mean and monthly seasonal effects{break} 
{space 2}{bf:detrendm} removes the pre-treatment linear trend and monthly seasonal effects{p_end}

{syntab:Required (depends on implementation)}
{synopt:{opt method(ra|ipw|ipwra)}}{it:Large-N only.} Specifies the large-N estimation method:{break}
{cmd:ra} for regression adjustment {break}
{cmd:ipw} for inverse probability weighting {break}
{cmd:ipwra} for doubly robust IPW-RA. {break}
Required unless {cmd:small} is specified; {cmd:ipw} and {cmd:ipwra} require covariates.{p_end}

{synopt:{opt small}}{it:Small-N only.} Specifies the small-sample implementation for settings with few treated units, few control units, or both. Covariates are allowed only with a single treated cohort and require N_treated > K+1 and N_control > K+1 (K = number of covariates).{p_end}

{syntab:Optional options}

{synopt:{opt pre(#)}}{it:Large-N only.} Specifies the number of pre-treatment periods used to construct the outcome transformation.{break}
By default, all available pre-treatment periods are used.{break}
For example, {cmd:pre(1)} uses only the last pre-treatment period, while
{cmd:pre(3)} uses the last three pre-treatment periods.{p_end}

{synopt:{opt never}}{it:Large-N only.} Uses only never-treated units as controls; by default, {cmd:lwdid} uses both never-treated and not-yet-treated units.{p_end}

{synopt:{opt attgt}}{it:Large-N only.} Reports post-treatment ATT(g,t) estimates by cohort and calendar time, with standard errors and confidence intervals. For {cmd:ipw} and {cmd:ipwra}, standard errors are influence-function based and account for estimation of the propensity score; for {cmd:ra}, they are regression based (robust or clustered).{p_end}

{synopt:{opt cluster(varname)}}{it:Large-N only.} Specifies the clustering level for ATT(g,t) standard errors and multiplier-bootstrap inference. By default, clustering is at the unit level.{p_end}

{synopt:{opt ydot}}{it:Large-N only.}  Saves the cohort-specific residualized outcome variables used to construct the ATT(g,t) estimates. By default, these variables are not saved to avoid conflicts with existing user variables.{p_end}

{synopt:{opt save(filename)}}Save estimation results as a .dta file.{p_end}

{synopt:{opt graph}}Displays graphical results.{break}
Large-N: plots weighted ATT estimates by relative time with pointwise confidence intervals by default. {break}
Small-N: plots treated and control means of residualized outcomes over time.{p_end}

{synopt:{opt cb}}{it:Large-N only.} Uses simultaneous confidence bands over all estimated event times (pre- and post-treatment) in both the event-study table and graph, rather than the default pointwise confidence intervals.{p_end}

{synopt:{opt gopts(string)}}Additional {cmd:twoway} graph options (only with {cmd:graph}).{p_end}

{synopt:{opt gid(id)}}Select treated unit to plot (default: treated-group average).{p_end}

{synopt:{opt vce(vartype)}}{it:Small-N only.} Variance estimator for regression (e.g., {bf:robust}, {bf:hc3}).{p_end}

{synopt:{opt reps(#)}}{it:Large-N only.} Number of bootstrap replications for large-N inference (default = 999).{p_end}

{synopt:{opt seed(#)}}{it:Large-N only.} Random-number seed for the bootstrap, for reproducible standard errors and confidence bands.{p_end}

{synopt:{opt level(#)}}Confidence level, in percent (default = 95).{p_end}

{synopt:{opt ri}}{it:Small-N only.} Perform randomization inference (RI).{p_end}

{synopt:{opt rireps(#)}}{it:Small-N only.} Number of RI repetitions (default = 999).{p_end}

{synopt:{opt riseed(#)}}{it:Small-N only.} Seed for RI reproducibility (default: randomly drawn).{p_end}

{synoptline}

{marker results}{...}
{title:Saved results}

{pstd}
Large-N mode saves the following in {cmd:e()}; type {cmd: ereturn list} to display them:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(att)}}post-treatment average ATT ({cmd:Post_avg}){p_end}
{synopt:{cmd:e(se_att)}}standard error of {cmd:e(att)}{p_end}
{synopt:{cmd:e(N_attgt)}}number of estimated ATT(g,t) cells{p_end}
{synopt:{cmd:e(N_dropped)}}number of excluded ATT(g,t) cells{p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(cb_crit)}}critical value for simultaneous confidence bands{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lwdid}{p_end}
{synopt:{cmd:e(depvar)}}outcome variable{p_end}
{synopt:{cmd:e(controls)}}covariates, as specified{p_end}
{synopt:{cmd:e(method)}}{cmd:ra}, {cmd:ipw}, or {cmd:ipwra}{p_end}
{synopt:{cmd:e(rolling)}}transformation type{p_end}
{synopt:{cmd:e(ci_display)}}{cmd:pointwise} or {cmd:simultaneous}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}{cmd:Pre_avg}, {cmd:Post_avg}, and event-study WATT(r), named {cmd:Rm}{it:#} (r < 0) and {cmd:Rp}{it:#} (r >= 0){p_end}
{synopt:{cmd:e(V)}}bootstrap variance-covariance matrix of {cmd:e(b)}{p_end}
{synopt:{cmd:e(WATT)}}event-study results: {cmd:ryear watt se}{p_end}
{synopt:{cmd:e(ATTgt)}}cell-level results, including pre-treatment cells: {cmd:cohort time ryear att se Ngt}{p_end}
{synopt:{cmd:e(ATTgt_dropped)}}excluded cells, if any: {cmd:cohort time ryear reason}{p_end}
{synopt:{cmd:e(N_cohorts_used)}}number of cohorts contributing to each WATT(r){p_end}

{pstd}
Reason codes in {cmd:e(ATTgt_dropped)}: 1 = insufficient treated or control
observations; 2 = propensity model failed or did not converge; 3 = outcome
regression failed; 4 = treatment not identified; 5 = outcome influence
function singular; 6 = propensity influence function singular.

{pstd}
Cell-level ATT(g,t) estimates are not in {cmd:e(b)}; use {cmd:e(ATTgt)}.
Coefficient names can be listed with {cmd:ereturn display, coeflegend}, e.g.:

{space 4}{cmd:. scalar avg_att = _b[Post_avg]}
{space 4}{cmd:. scalar avg_se  = _se[Post_avg]}
{space 4}{cmd:. scalar att_m2  = _b[Rm2]}
{space 4}{cmd:. scalar att1    = _b[Rp1]}

{pstd}
Small-N mode saves {cmd:e(att)}, {cmd:e(se_att)}, {cmd:e(b)}, and {cmd:e(V)}.
With common timing, it also saves period-specific estimates in {cmd:e(ATTt)}
and {cmd:e(SEt)}, and the RI p-value in {cmd:e(p_ri)} when {cmd:ri} is specified.


{marker description}{...}
{title:Description}

{pstd}
{cmd:lwdid} implements the transformation-based rolling Difference-in-Differences estimators 
developed in Lee and Wooldridge (2026a, 2026b). 
The command provides a unified implementation for panel data settings with either 
a {it:large-N} or a {it:small-N} cross-sectional dimension, allowing treatment effects
to be estimated under both the staggered treatment adoption and the common timing case. 

{pstd}
The central idea is to transform outcome variables within each unit to remove
pre-treatment means, trends, or seasonal components. This within-unit transformation
converts panel data into a series of cross-sectional datasets where the residualized outcomes serve as the dependent variable.
Treatment effects are then estimated via simple cross-sectional regressions in each
period, enabling both overall and period-specific ATT estimation.

{pstd}
By default, {cmd:lwdid} uses the large-N procedure of Lee and Wooldridge (2026a),
which is designed for panels with a large cross-sectional dimension and allows for
heterogeneous treatment effects and unit-specific heterogeneous linear trends.

{pstd}
When the cross-sectional dimension is small ({it:small-N}), conventional
large-N inference may be unreliable. In such settings, specifying
the {cmd:small} option invokes the exact small-sample inference procedures
developed in Lee and Wooldridge (2026b). 

{pstd}
In the large-N procedure, ATT(g,t) is estimated separately for each cohort and
calendar time and then aggregated, with cohort-size weights, into event-study
effects WATT(r) and pre- and post-treatment averages. Inference uses a
multiplier (wild) bootstrap of the influence functions, clustered at the unit
level by default. If some ATT(g,t) cannot be estimated (for example, because of
too few treated or control units or a failed propensity-score model), those
cells are excluded from the aggregation and a warning lists up to five of them;
the complete list is stored in {cmd:e(ATTgt_dropped)}.

{pstd}
Based on the treatment cohort variable specified in {cmd:gvar()}, {cmd:lwdid}
automatically detects whether the design involves a single treatment cohort
(common timing) or multiple cohorts (staggered adoption) and applies the
appropriate estimation procedure. 

{pstd}
Details of the implementation are given in Hur, Lee and Wooldridge (2026c); 
see also the {browse "https://github.com/Soo-econ/lwdid":lwdid GitHub repository}
for additional examples and documentation.


{marker examples}{...}
{title:Examples}

{bf:Example 1:} Large-N estimation (RA, demean transformation)

{space 4}{cmd:. lwdid y, ivar(id) tvar(year) gvar(first_treat) rolling(demean) method(ra) graph}


{bf:Example 2:} Large-N estimation (IPWRA, detrend transformation)

{space 4}{cmd:. lwdid y x1 x2, ivar(id) tvar(year) gvar(first_treat) rolling(detrend) method(ipwra) save(myresult) graph gopts(ytitle("Residualized average outcome") xtitle("Year") title("The Effects of Walmart Opening"))}

{pstd}
This example estimates treatment effects using the IPWRA estimator with the
detrend transformation. The option save(myresult) saves the estimates to
myresult.dta. The gopts() option customizes the graph.


{bf:Example 3:} Small-N estimation (Quarterly data with detrending and seasonal adjustment)

{space 4}{cmd:. gen qdate = yq(year, quarter)}
{space 4}{cmd:. format qdate %tq}
{space 4}{cmd:. gen gq = yq(first_year, first_quarter)}
{space 4}{cmd:. format gq %tq}
{space 4}{cmd:. lwdid y, small ivar(id) tvar(qdate) gvar(gq) rolling(detrendq) graph}

{pstd}
With the {cmd:small} option, {cmd:lwdid} implements the small-N inference
procedure. Here the example uses quarterly data with the {cmd:detrendq}
transformation. For quarterly seasonal adjustment, {cmd:tvar()} should be
a single Stata quarterly date variable created by {cmd:yq()}, and {cmd:gvar()}
should be on the same scale.

{bf:Example 4:} Small-N estimation (Monthly data with detrending and seasonal adjustment)

{space 4}{cmd:. gen mdate = ym(year, month)}
{space 4}{cmd:. format mdate %tm}
{space 4}{cmd:. gen gm = ym(first_year, first_month)}
{space 4}{cmd:. format gm %tm}
{space 4}{cmd:. lwdid y, small ivar(id) tvar(mdate) gvar(gm) rolling(detrendm) graph}

{pstd}
This example uses monthly data with the {cmd:detrendm} transformation. For
monthly seasonal adjustment, {cmd:tvar()} should be a single Stata monthly
date variable created by {cmd:ym()}, and {cmd:gvar()} should be on the same
scale.


{marker citation}{...}
{title:Citation}

{pstd}
Lee, S. J., and Wooldridge, J. M. (2026a), 
"A Simple Transformation Approach to Difference-in-Differences Estimation for Panel Data," 
forthcoming at {browse "https://doi.org/10.1080/07350015.2026.2683047":{it:Journal of Business & Economic Statistics}}.

{pstd}
Lee, S. J., and Wooldridge, J. M. (2026b), 
"Simple Approaches to Inference with Difference-in-Differences Estimators with Small Cross-Sectional Sample Sizes,"  
Working Paper, Available at {browse "https://dx.doi.org/10.2139/ssrn.5325686":SSRN 5325686}

{pstd}
Hur, E. K., Lee, S. J., and Wooldridge, J. M. (2026c), 
"Rolling Difference-in-Differences Estimation for Small and Large Panels,"  
Working Paper, Available at {browse "https://dx.doi.org/10.2139/ssrn.6502558":SSRN 6502558}



{marker author}{...}
{title:Authors}

    Soo Jeong Lee
    Southern Illinois University Carbondale
    {browse "mailto:soojeong.lee@siu.edu":soojeong.lee@siu.edu}

    Jeffrey M. Wooldridge
    Michigan State University
    {browse "mailto:wooldri1@msu.edu":wooldri1@msu.edu}











