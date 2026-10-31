{smcl}
{* *! version 1.0.0  25oct2026}{...}
{vieweralsosee "polyindex" "help polyindex"}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{title:Title}

{phang}
{bf:polyreg} {hline 2} Regression on a polychoric index with bootstrap inference
that accounts for the estimated index (generated-regressor correction)


{title:Syntax}

{p 8 17 2}
{cmd:polyreg}
{depvar}
[{indepvars}]
{ifin}
{weight}
{cmd:,}
{opth ind:ex(varlist)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opth ind:ex(varlist)}}indicators from which the index is built (e.g. assets){p_end}
{synopt:{opt mod:el(name)}}{cmd:regress} (default), {cmd:logit}, {cmd:probit} or {cmd:poisson}{p_end}
{synopt:{opt quant:iles(#)}}enter the index as {it:#} quantile-group dummies instead of linearly{p_end}
{synopt:{opt ncomp(#)}}number of index components entered linearly; default 1{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 199{p_end}
{synopt:{opth cl:uster(varname)}}resample clusters; also used for the naive standard errors{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt meth:od(pca|fa)}, {opt rot:ate()}, {opt pd:fix}}index model, as in {helpb polyindex}{p_end}
{synopt:{opt cat:max(#)}, {opt ord:inal()}, {opt cont:inuous()}}variable types, as in {helpb polycorr}{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt nodots}}suppress replication dots{p_end}
{synoptline}
{p 4 6 2}* {opt index()} is required. {indepvars} may contain factor variables.
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed.{p_end}


{title:Description}

{pstd}
Wealth or socioeconomic-status indices built by polychoric principal component
analysis are routinely used as regressors. The usual practice computes the index
once and then treats it as data. This ignores the sampling error in the index
weights (loadings and thresholds), so the reported standard errors are too small
(the generated-regressor problem; Pagan 1984; Murphy and Topel 1985).

{pstd}
{cmd:polyreg} builds the index with {helpb polyindex} and fits the outcome model.
It then bootstraps the {it:whole} procedure, optionally by cluster. In every
replication, the polychoric correlations, thresholds and eigenvectors are
re-estimated, the index is recomputed (and, with {opt quantiles()}, regrouped),
and the outcome model is re-fitted. The bootstrap covariance matrix of the
outcome-model coefficients is posted in {cmd:e(V)}. For the index terms, the
display compares bootstrap standard errors with the naive (robust or cluster)
standard errors and reports their ratio.

{pstd}
The index variables {cmd:__prx1}, {cmd:__prx2}, ... and, with
{opt quantiles()}, the group variable {cmd:__prxq} are left in the data for the
full sample. Existing variables with these names are replaced.


{title:Remarks}

{pstd}
Eigenvectors are signed so that their loadings sum to a positive number. The
index therefore has the same orientation in every replication, and bootstrap
coefficients are comparable.

{pstd}
With probability weights, observations are resampled and keep their weights.
For complex designs, resample primary sampling units with {opt cluster()}.

{pstd}
{bf:How to read the comparison.} In simulations (see the accompanying
article), the bootstrap is the safer choice when the index enters linearly and
rests on few or weak indicators: there, naive intervals undercover. When the
index enters through {opt quantiles()} dummies, naive standard errors were
accurate, and the bootstrap was conservative (4% to 21% too large), because
resampling moves the quantile cut points more than they move across
independent samples. Report both, and read a ratio near 1 as evidence that the
index's estimation error is negligible.

{pstd}
Percentile confidence intervals are stored in {cmd:e(ci_percentile)}. All
replicates are stored in {cmd:e(b_boot)}.


{title:Examples}

{phang2}{cmd:. polyreg enrolled age i.female, index(electricity radio tv fridge floor water toilet) reps(499) cluster(ea) seed(1)}{p_end}
{phang2}{cmd:. polyreg stunted age i.female [pw=wt], index(electricity radio tv fridge floor water toilet) quantiles(5) model(logit) cluster(ea)}{p_end}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(reps)}, {cmd:e(reps_ok)}, {cmd:e(N_clust)}, {cmd:e(ncomp)}, {cmd:e(quantiles)}}{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:polyreg}{p_end}
{synopt:{cmd:e(model)}, {cmd:e(index)}, {cmd:e(indexvars)}, {cmd:e(xvars)}, {cmd:e(depvar)}, {cmd:e(clustvar)}}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}full-sample coefficients; bootstrap covariance{p_end}
{synopt:{cmd:e(V_naive)}}covariance treating the index as data{p_end}
{synopt:{cmd:e(ci_percentile)}}bootstrap percentile intervals{p_end}
{synopt:{cmd:e(b_boot)}}bootstrap replicates{p_end}


{title:References}

{phang}
Murphy, K. M., and R. H. Topel. 1985. Estimation and inference in two-step
econometric models. {it:Journal of Business and Economic Statistics} 3: 370-379.

{phang}
Pagan, A. 1984. Econometric issues in the analysis of regressions with generated
regressors. {it:International Economic Review} 25: 221-247.

{phang}
Kolenikov, S., and G. Angeles. 2009. Socioeconomic status measurement with
discrete proxy variables: Is principal component analysis a reliable answer?
{it:Review of Income and Wealth} 55: 128-165.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polyindex}, {helpb polycorr}
{p_end}
