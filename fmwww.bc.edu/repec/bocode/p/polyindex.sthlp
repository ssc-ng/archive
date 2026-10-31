{smcl}
{* *! version 1.1.0  21oct2026}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{vieweralsosee "[MV] pca" "help pca"}{...}
{vieweralsosee "[MV] mca" "help mca"}{...}
{vieweralsosee "[D] xtile" "help xtile"}{...}
{title:Title}

{phang}
{bf:polyindex} {hline 2} Polychoric principal-component or factor index with
bootstrap loading and household-level standard errors, ranking-stability
diagnostics and comparison indices


{title:Syntax}

{p 8 17 2}
{cmd:polyindex}
{varlist}
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt meth:od(pca|fa)}}principal components (default) or principal-axis factoring{p_end}
{synopt:{opt rot:ate(none|varimax)}}rotation for {cmd:method(fa)}; default {cmd:none}{p_end}
{synopt:{opt ncomp(#)}}number of components or factors to score and display; default 1{p_end}
{synopt:{opt pd:fix}}use the nearest positive-definite correlation matrix{p_end}
{synopt:{opt cat:max(#)}, {opth ord:inal(varlist)}, {opth cont:inuous(varlist)}}as in {helpb polycorr}{p_end}

{syntab:Scores}
{synopt:{opth gen:erate(stub)}}create score variables {it:stub}1, {it:stub}2, ...{p_end}
{synopt:{opt q:uantiles(#)}}number of quantile groups of the first score (e.g. 5 for quintiles){p_end}
{synopt:{opth qgen:erate(newvar)}}variable to hold the quantile groups{p_end}
{synopt:{opt replace}}replace existing variables{p_end}

{syntab:Bootstrap}
{synopt:{opt reps(#)}}bootstrap replications; default 0 (none){p_end}
{synopt:{opth cl:uster(varname)}}resample clusters (e.g. enumeration areas){p_end}
{synopt:{opth score:se(newvar)}}store each observation's bootstrap std. err. of score 1{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt nodots}}suppress replication dots{p_end}

{syntab:Comparison}
{synopt:{opt comp:are(mca pca)}}Spearman correlation of score 1 with an MCA index and/or a raw-variable PCA index{p_end}
{synoptline}
{p 4 6 2}
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed.{p_end}


{title:Description}

{pstd}
{cmd:polyindex} builds indices from the polychoric correlation matrix estimated
by {helpb polycorr}. This approach was proposed by Kolenikov and Angeles (2009)
for socioeconomic-status indices built from categorical asset and housing
indicators.

{pstd}
Each ordinal variable is scored by the conditional mean of its latent standard
normal variable within each category,
(phi(tau_{c-1}) - phi(tau_c)) / (Phi(tau_c) - Phi(tau_{c-1})).
Continuous variables are standardized.

{pstd}
With {cmd:method(pca)}, the scoring weights are the eigenvectors of R.
{cmd:method(fa)} uses iterated principal-axis factoring, starting from squared
multiple correlations. Optionally the loadings are rotated by Kaiser-normalized
varimax, and the regression-method scoring weights R^(-1) Lambda are applied.

{pstd}
With {opt reps()}, the whole procedure is bootstrapped, optionally by cluster.
Each replication re-estimates the correlations, thresholds and model, aligns the
bootstrap columns with the full-sample ones by order and sign, and re-scores the
original sample. The bootstrap reports:

{phang2}o standard errors of the column-1 loadings;{p_end}
{phang2}o the Spearman correlation between bootstrap and full-sample scores;{p_end}
{phang2}o the share of observations that change quantile group;{p_end}
{phang2}o with {opt scorese()}, each observation's bootstrap standard error of score 1.{p_end}

{pstd}
{opt compare(mca pca)} reports how closely score 1 ranks observations relative
to two alternatives: multiple correspondence analysis of the ordinal variables
({helpb mca}), and the Filmer-Pritchett principal-component index of the raw
variables ({helpb pca}).


{title:Remarks}

{pstd}
Eigenvectors and factors are signed so that their loadings sum to a positive
number. In replications where a category does not occur, that category keeps
its full-sample score.

{pstd}
The quantile groups used in the stability statistics are unweighted rank groups
of the estimation sample. The {opt qgenerate()} variable uses {helpb xtile} with
the specified weights. The comparison indices are unweighted.

{pstd}
Scores used as regressors are generated regressors. {helpb polyreg}, if
installed, gives bootstrap inference that accounts for this.


{title:Examples}

{phang2}{cmd:. polyindex water toilet floor roof electricity radio tv fridge, gen(wealth) q(5) qgen(wq) reps(200) seed(2026)}{p_end}
{phang2}{cmd:. polyindex water toilet floor roof electricity radio tv fridge [pw=wt], gen(w) cluster(ea) reps(500) scorese(w_se) compare(mca pca)}{p_end}
{phang2}{cmd:. polyindex water toilet floor roof electricity radio tv fridge, method(fa) ncomp(2) rotate(varimax) gen(f)}{p_end}


{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(k_var)}, {cmd:r(ncomp)}}observations, variables, components{p_end}
{synopt:{cmd:r(lambda}{it:#}{cmd:)}}eigenvalues of R{p_end}
{synopt:{cmd:r(reps)}}successful bootstrap replications{p_end}
{synopt:{cmd:r(spearman)}, {cmd:r(spearman_lo)}, {cmd:r(spearman_hi)}}mean and 2.5/97.5 percentiles of the Spearman correlation{p_end}
{synopt:{cmd:r(reclass)}, {cmd:r(reclass_lo)}, {cmd:r(reclass_hi)}}mean and percentiles of the share changing quantile group{p_end}
{synopt:{cmd:r(rho_mca)}, {cmd:r(rho_pca)}}absolute Spearman correlations with the comparison indices{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}, {cmd:r(types)}, {cmd:r(method)}, {cmd:r(rotate)}, {cmd:r(scores)}}{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(R)}}correlation matrix used{p_end}
{synopt:{cmd:r(eigenvalues)}}eigenvalues of R{p_end}
{synopt:{cmd:r(loadings)}}eigenvectors (pca) or factor loadings (fa){p_end}
{synopt:{cmd:r(weights)}}scoring weights{p_end}
{synopt:{cmd:r(uniqueness)}}uniquenesses (fa){p_end}
{synopt:{cmd:r(load_se)}}bootstrap SEs of column-1 loadings{p_end}
{synopt:{cmd:r(boot_load)}}bootstrap column-1 loadings (reps x k){p_end}
{synopt:{cmd:r(stability)}}per replication: Spearman correlation, share reclassified{p_end}

{pstd}
{cmd:polyindex} leaves the full-sample {helpb polycorr} results ({cmd:novce}) in {cmd:e()}.


{title:Reference}

{phang}
Kolenikov, S., and G. Angeles. 2009. Socioeconomic status measurement with
discrete proxy variables: Is principal component analysis a reliable answer?
{it:Review of Income and Wealth} 55: 128-165.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polycorr}, {helpb pca}, {helpb mca}, {helpb xtile}
{p_end}
