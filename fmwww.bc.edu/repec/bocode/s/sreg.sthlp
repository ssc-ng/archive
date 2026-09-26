{smcl}
{* *! version 1.0.0 24sep2026}{...}
{title:Title}

{p 4 4 2}
{cmd:sreg} {hline 2} Stratified Randomized Experiments

{title:Installation}

{p 4 4 2}
Install the package from SSC:
{p_end}
{phang2}{cmd:. ssc install sreg, replace}{p_end}

{title:Syntax}

{p 8 12 2}
{cmd:sreg} {it:outcome} [{it:covariates}] {ifin},
{opt treatment(varname)} [{opt strata(varname)} {opt cluster(varname)}
{opt clustersize(varname)} {opt smallstrata} {opt k(#)} {opt nohc1}
{opt level(#)}]

{p 4 4 2}
Covariates may include factor variables and interactions. The outcome and
assignment/design variables must be numeric. Treatment indicators are coded 0, 1, 2, ...;
0 denotes the control. Strata are coded 1, 2, 3, .... Gaps are not allowed in these
codes in the estimation sample. Cluster IDs may be arbitrary integers.

{title:Description}

{p 4 4 2}
{cmd:sreg} estimates average treatment effects (ATEs) in stratified randomized
experiments. It supports matched pairs, k-tuple designs, large strata of
potentially unequal sizes, and designs that combine small and large strata.
Estimation accommodates multiple treatments, individual- and cluster-level
treatment assignment, and optimal linear covariate adjustment using baseline
characteristics. The package is implemented entirely in Stata and Mata.
Stata 14.2 or newer is required; no additional packages are required.

{p 4 4 2}
Supported procedures are large-strata, small-strata and mixed-design
estimators, under individual or cluster assignment, with multiple treatments,
optional linear covariate adjustment and the design-specific HC1 correction.
Inference uses the standard normal distribution. The output reports ATE
estimates, standard errors, z statistics, p-values and asymptotic confidence
intervals (95% by default).

{title:Arguments}

{phang}
{it:outcome} is the required numeric variable containing the observed outcome
for each observation. Write its variable name immediately after {cmd:sreg}.

{phang}
{it:covariates} is an optional list of numeric variables used for linear
covariate adjustment. Write their names after the outcome and before the
comma. Factor variables and interactions are supported. Omit this list to
estimate treatment effects without covariate adjustment. For cluster-level
assignment, individual-level covariates are averaged within clusters.

{p 4 4 2}
Pass variable names from the dataset currently in memory. For example:

{phang2}{cmd:. sreg gradesq34 pills_taken age_months, treatment(D) strata(class_level)}{p_end}

{p 4 4 2}
Here, {cmd:gradesq34} is the outcome, {cmd:pills_taken} and {cmd:age_months}
are covariates, {cmd:D} identifies treatment assignment, and
{cmd:class_level} identifies the randomization strata.
Without covariate adjustment, the command is:

{phang2}{cmd:. sreg gradesq34, treatment(D) strata(class_level)}{p_end}

{title:Options}

{phang}
{opt treatment(varname)} specifies randomized treatment assignment, not an
adjustment covariate. It is required.

{phang}
{opt strata(varname)} specifies randomization strata. If omitted, one stratum
is used. Every arm must be present in every stratum used by an estimator.

{phang}
{opt cluster(varname)} specifies the randomization unit. It changes the
estimator as well as its variance and is not a generic clustered standard
error option. Outcomes are averaged over available observations in a cluster;
covariates are replaced with cluster means. Treatment, stratum and represented
cluster size must be constant within cluster.

{phang}
{opt clustersize(varname)} specifies represented population sizes, one positive
integer value repeated within each cluster. These can differ from the number
sampled. If omitted, the number of complete observations per cluster is used,
with a warning. Cluster expanded outcomes equal size times mean outcome.

{phang}
{opt smallstrata} enables small/mixed design selection. Without this option,
the large-strata estimator is used. A common observed stratum size selects
the small-strata estimator. With varying sizes, at least 25% of strata must
share a qualifying size; that modal size defines the small component.
The default qualifying sizes are at most 3. Supply {opt k()} for larger tuples.
Ties select the smaller size. The remaining strata form the large component.

{phang}
{opt k(#)} specifies units per small stratum, or clusters per small stratum
under cluster assignment. In uniform designs it validates the observed size.
It does not itself enable {opt smallstrata}. Adjacent strata, in numeric
stratum order, are paired for small-strata variance estimation. An even
number of small strata is required. This ordering must correspond to the
design's intended pairing; row sorting does not define the pairs.

{phang}
{opt nohc1} disables the design-specific finite-sample correction. HC1 is
enabled by default. For large strata it scales the within-stratum variance
using assignment-unit counts and the number of treatment-by-stratum cells. For small strata it uses
B/[B-p-1], where B is the number of small strata and p the adjustment dimension;
the unadjusted individual small-strata estimator does not apply that factor.
The cluster small-strata estimator does apply it, including when p=0.

{phang}
{opt level(#)} sets the confidence percentage; the default is 95.
{cmd:sreg, level(90)} replays stored estimates with 90% intervals.

{title:Adjustment, missing data and diagnostics}

{p 4 4 2}
In large-strata estimation, covariate slopes are estimated separately for each
treatment-by-stratum cell. Lack of variation in any requested
covariate in a cell causes a warning and fallback to the unadjusted estimator.
Unidentified regressions produce an error. Small-strata adjustment regresses
within-stratum treatment-control outcome differences on covariate differences.
Mixed-design adjustment is applied to both components; an unidentified large
component is an error rather than a silent fallback.

{p 4 4 2}
Complete-case selection is applied to outcome, covariates and supplied design
variables after {cmd:if}/{cmd:in}. It can change observed stratum and cluster
sizes. Use {cmd:e(sample)} to inspect the selected sample. The dataset and
observation order are preserved. Negative or nonfinite variance estimates
and odd small-stratum counts are reported as errors rather than valid inference.

{title:Saved results}

{p 4 4 2}
{cmd:e(b)} contains {cmd:tau1}, {cmd:tau2}, and so on, one per active treatment. {cmd:e(V)} contains their full
covariance matrix. {cmd:lincom}, {cmd:test}, {cmd:estimates store} and
{cmd:estimates restore} are supported. Prediction and {cmd:margins} are not
implemented.

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(N)}}number of complete individual observations{p_end}
{synopt:{cmd:e(N_units)}}number of assignment units{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters, for cluster assignment{p_end}
{synopt:{cmd:e(N_strata)}}number of strata{p_end}
{synopt:{cmd:e(N_treatments)}}number of active treatment arms{p_end}
{synopt:{cmd:e(HC1)}}requested HC1 setting{p_end}
{synopt:{cmd:e(adjusted)}}whether adjustment was used{p_end}
{synopt:{cmd:e(smallstrata)}}requested small-strata setting{p_end}
{synopt:{cmd:e(k)}}detected small-stratum size{p_end}
{synopt:{cmd:e(beta)}}adjustment slopes when used{p_end}
{synopt:{cmd:e(design)}}large strata, small strata or mixed design{p_end}
{synopt:{cmd:e(warnings)}}diagnostic messages from estimation{p_end}
{synopt:{cmd:e(sample)}}estimation sample indicator{p_end}

{p 4 4 2}
Mixed fits additionally save {cmd:e(b_small)}, {cmd:e(V_small)},
{cmd:e(b_large)}, {cmd:e(V_large)}, {cmd:e(p_small)}, {cmd:e(N_small)} and
{cmd:e(N_large)}. The counts are assignment units, while {cmd:e(p_small)} is
the represented individual population share. {cmd:e(beta)} is the small
component's slopes for mixed fits. Component-share uncertainty is included
in the combined covariance.

{p 4 4 2}
Adjusted mixed fits also save {cmd:e(beta_small)} and {cmd:e(beta_large)}.
For large-component slopes, rows are ordered by stratum, then treatment arm
(control first). Columns follow {cmd:e(adjustment_terms)}.

{title:Examples}

{phang2}{cmd:. sreg earnings baseline age, treatment(assignment) strata(block)}{p_end}
{phang2}{cmd:. sreg earnings baseline, treatment(assignment) strata(block) cluster(village) clustersize(population)}{p_end}
{phang2}{cmd:. sreg earnings baseline, treatment(assignment) strata(pair) smallstrata}{p_end}
{phang2}{cmd:. sreg earnings, treatment(assignment) strata(block) smallstrata k(4)}{p_end}
{phang2}{cmd:. lincom tau2 - tau1}{p_end}
{phang2}{cmd:. sregplot, xtitle("ATE relative to control")}{p_end}


{title:Empirical illustration}

{p 4 4 2}
The included AEJapp data come from Chong et al. (2016), who studied iron
deficiency and educational attainment among school-age children in Peru.
The dataset contains 215 observations and 62 variables.
See {help sreg_aejapp} for the data description and source.

{p 4 4 2}
Download the example files from SSC. The following
commands copy the data to the current working folder and load them.
Save any data in memory before using {cmd:clear}.

{p 4 4 2}Download the example files from SSC:{p_end}
{phang2}{cmd:. ssc install sreg, all replace}{p_end}
{phang2}{cmd:. use sreg_aejapp.dta, clear}{p_end}
{phang2}{cmd:. describe gradesq34 treatment class_level pills_taken age_months}{p_end}
{phang2}{cmd:. generate byte D = cond(treatment == 3, 0, treatment)}{p_end}
{phang2}{cmd:. tabulate D class_level}{p_end}

{p 4 4 2}
The outcome is {cmd:gradesq34}, the treatment indicator is {cmd:D}, and
the stratum indicator is {cmd:class_level}. The original control code 3 is
recoded to 0. Estimate treatment effects without covariate adjustment:

{phang2}{cmd:. sreg gradesq34, treatment(D) strata(class_level)}{p_end}
{phang2}{cmd:. estimates store unadjusted}{p_end}

{p 4 4 2}
Expected estimates and standard errors, rounded to seven decimal places:

{p 8 8 2}{cmd:tau1   -.0511297   .2064541}{p_end}
{p 8 8 2}{cmd:tau2    .4090337   .2065146}{p_end}

{p 4 4 2}
Add covariates after the outcome and before the comma:

{phang2}{cmd:. sreg gradesq34 pills_taken age_months, treatment(D) strata(class_level)}{p_end}
{phang2}{cmd:. estimates store adjusted}{p_end}

{p 8 8 2}{cmd:tau1   -.0286159   .1816173}{p_end}
{p 8 8 2}{cmd:tau2    .3460869   .1857249}{p_end}

{p 4 4 2}
Extract the treatment-1 estimate and standard error, inspect the full
coefficient vector and covariance matrix, and plot the adjusted estimates:

{phang2}{cmd:. display _b[tau1]}{p_end}
{phang2}{cmd:. display _se[tau1]}{p_end}
{phang2}{cmd:. matrix list e(b)}{p_end}
{phang2}{cmd:. matrix list e(V)}{p_end}
{phang2}{cmd:. sregplot}{p_end}

{title:Example: small strata}

{phang2}{cmd:. set seed 2026}{p_end}
{phang2}{cmd:. sreg_rgen, n(300) individual tau(1.2 .8) smallstrata k(3) treatsizes(1 1 1) clear}{p_end}
{phang2}{cmd:. sreg Y x_1 x_2, treatment(D) strata(S) smallstrata}{p_end}

{title:Example: mixed small and large strata}

{phang2}{cmd:. sreg_rgen, n(120) individual tau(.5) mixedstrata nsmall(80) k(4) treatsizes(2 2) strata(4) clear}{p_end}
{phang2}{cmd:. sreg Y, treatment(D) strata(S) smallstrata k(4)}{p_end}

{title:Legacy syntax}

{p 4 4 2}
Existing {cmd:sreg, y(Y) d(D) s(S) x(X1 X2) g_id(G) ng(Ng) hc1(true)}
calls remain supported. Do not mix the two syntaxes. Legacy {cmd:ng()} without
{cmd:g_id()} is included in complete-case selection but otherwise ignored. Primary {cmd:clustersize()} requires {cmd:cluster()}.

{title:Authors}

{p 4 4 2}
Juri Trifonov jutrifonov@u.northwestern.edu

{p 4 4 2}
Yuehao Bai yuehao.bai@usc.edu

{p 4 4 2}
Azeem Shaikh amshaikh@uchicago.edu

{p 4 4 2}
Max Tabord-Meehan m.tabordmeehan@utoronto.ca

{title:References}

{p 4 4 2}
Bugni, F. A., Canay, I. A., and Shaikh, A. M. (2018). Inference Under Covariate-Adaptive Randomization. {it:Journal of the American Statistical Association}, 113(524), 1784–1796, doi:10.1080/01621459.2017.1375934.

{p 4 4 2}
Bugni, F., Canay, I., Shaikh, A., and Tabord-Meehan, M. (2024+). Inference for Cluster Randomized Experiments with Non-ignorable Cluster Sizes. {it:Forthcoming in the Journal of Political Economy: Microeconomics}, doi:10.48550/arXiv.2204.08356.

{p 4 4 2}
Jiang, L., Linton, O. B., Tang, H., and Zhang, Y. (2023+). Improving Estimation Efficiency via Regression-Adjustment in Covariate-Adaptive Randomizations with Imperfect Compliance. {it:Forthcoming in Review of Economics and Statistics}, doi:10.48550/arXiv.2204.08356.

{p 4 4 2}
Bai, Y., Jiang, L., Romano, J. P., Shaikh, A. M., and Zhang, Y. (2024). Covariate adjustment in experiments with matched pairs. {it:Journal of Econometrics}, 241(1), doi:10.1016/j.jeconom.2024.105740.

{p 4 4 2}
Bai, Y. (2022). Optimality of Matched-Pair Designs in Randomized Controlled Trials. {it:American Economic Review}, 112(12), doi:10.1257/aer.20201856.

{p 4 4 2}
Bai, Y., Romano, J. P., and Shaikh, A. M. (2022). Inference in Experiments With Matched Pairs. {it:Journal of the American Statistical Association}, 117(540), doi:10.1080/01621459.2021.1883437.

{p 4 4 2}
Liu, J. (2024). Inference for Two-stage Experiments under Covariate-Adaptive Randomization. doi:10.48550/arXiv.2301.09016.

{p 4 4 2}
Cytrynbaum, M. (2024). Covariate Adjustment in Stratified Experiments. {it:Quantitative Economics}, 15(4), 971–998, doi:10.3982/QE2475

{title:Project and software}

{p 4 4 2}
This is the Stata version of the R package sreg, implemented natively in
Stata and Mata. R is not required to use this package.

{p 4 4 2}
{browse "https://sreg-project.github.io":Project website}
{break}
{browse "https://github.com/jutrifonov/sreg-stata":Stata GitHub repository}
{break}
{browse "https://github.com/jutrifonov/sreg":R package}

{title:Also see}
{p 4 4 2}{help sregplot}, {help sreg_rgen}, {help lincom}, {help test}, {help estimates}{p_end}
