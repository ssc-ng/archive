{smcl}
{* *! version 1.0.0  25oct2026}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{vieweralsosee "[MI] mi estimate" "help mi estimate"}{...}
{viewerjumpto "Syntax" "polypml##syntax"}{...}
{viewerjumpto "Description" "polypml##description"}{...}
{viewerjumpto "Options" "polypml##options"}{...}
{viewerjumpto "Remarks" "polypml##remarks"}{...}
{viewerjumpto "Examples" "polypml##examples"}{...}
{viewerjumpto "Stored results" "polypml##results"}{...}
{viewerjumpto "References" "polypml##references"}{...}
{title:Title}

{phang}
{bf:polypml} {hline 2} Joint estimation of polychoric correlations and thresholds
with missing data: pairwise maximum likelihood or full-information maximum likelihood


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:polypml}
{varlist}
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt meth:od(pml|fiml)}}pairwise ML (default) or full-information ML{p_end}
{synopt:{opt vce(vcetype)}}{opt r:obust} (default) or {opt cl:uster} {it:clustvar}{p_end}
{synopt:{opt draw:s(#)}}Halton draws for the GHK simulator ({cmd:fiml}); default 200{p_end}
{synopt:{opt cat:max(#)}}largest number of categories accepted; default 10{p_end}
{synopt:{opth ord:inal(varlist)}}treat these variables as ordinal regardless of {opt catmax()}{p_end}
{synopt:{opt thr:esholds}}also display the thresholds{p_end}
{synopt:{opt l:evel(#)}}confidence level; default 95{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default 300{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance (pml); default 1e-8{p_end}
{synoptline}
{p 4 6 2}
All variables must be ordinal. {cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed.
{cmd:test}, {cmd:lincom}, {cmd:nlcom} and {cmd:estimates} work after {cmd:polypml}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{helpb polycorr} estimates each correlation by the two-step method. Thresholds
come from the margins and each correlation from its own pair, using listwise or
pairwise deletion. {cmd:polypml} instead estimates {it:all} thresholds and
correlations {it:jointly}, using every observed value.

{phang}
{cmd:method(pml)}, the default, maximizes the pairwise (composite) likelihood
(Katsikatsou et al. 2012). This is the sum, over all pairs of variables, of the
bivariate log likelihoods of the observations that have both variables observed.
Each threshold is shared by every pair that contains its variable. Estimation is
by Fisher scoring with analytic scores, started from the two-step values. The
covariance matrix is the Godambe (sandwich) matrix H^(-1) J H^(-1). Here H is
the sum of the pairwise information matrices, and J is the outer product of the
observation-level score contributions, summed across pairs, so that correlation
between pairs sharing an observation is taken into account. Pairwise ML is
consistent when data are missing completely at random (MCAR).

{phang}
{cmd:method(fiml)} maximizes the full-information likelihood of the latent
multivariate normal model. Each observation contributes the probability of its
observed categories, which is a rectangle probability of the multivariate normal
distribution of its observed variables. The probabilities are exact for one or
two observed variables (normal() and binormal()). For three or more they are
simulated by the GHK algorithm with Halton draws, which are held fixed across
iterations so that the simulated likelihood is smooth. The correlation matrix is
parametrized through canonical partial correlations, so it is positive definite
at every iteration. Observations are grouped into response patterns, and the
optimizer is {helpb mf_optimize:optimize()} (BFGS). FIML is consistent when data
are missing at random (MAR), that is, when missingness depends on observed
values of the variables. Standard errors are sandwich (robust or cluster)
standard errors in the natural parametrization.


{marker options}{...}
{title:Options}

{phang}
{opt method(pml|fiml)} chooses the estimator. FIML is slower; its run time grows
with the number of distinct response patterns, with {opt draws()}, and with the
square of the number of parameters. FIML starts from the PML estimates and is
maximized by Fisher scoring, with an iteration log; the Hessian for the
standard errors is then computed by second differences, which is announced by
"(computing standard errors)". With five 5-category variables, about 1,000
response patterns and 200 draws, expect a run time of one to a few minutes.

{phang}
{opt vce(cluster clustvar)} sums score contributions within clusters.

{phang}
{opt draws(#)} sets the number of Halton draws per dimension used by GHK. 200
draws are adequate for most applications; check stability by re-estimating with
500.

{phang}
{opt thresholds} displays the threshold estimates. They are always stored in
{cmd:e(b)} with equation names {cmd:cut_1}, {cmd:cut_2}, ... (one per variable,
in varlist order) and in {cmd:e(tau)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which estimator?} With complete data, pairwise ML and the two-step estimator
of {helpb polycorr} are both consistent and usually agree to two decimals.
Pairwise ML is somewhat more efficient for the thresholds because it uses the
dependence between variables.

{pstd}
With missing data, the choice depends on the missingness mechanism. Listwise or
available-case two-step estimates and pairwise ML assume MCAR. When missingness
depends on other observed variables (MAR), use {cmd:method(fiml)}, or multiple
imputation followed by {cmd:mi estimate: polycorr}.

{pstd}
{bf:Continuous variables.} {cmd:polypml} handles ordinal variables only.
Continuous variables can be discretized into deciles, or analysed with
{helpb polycorr} after multiple imputation.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse nhanes2f, clear}{p_end}
{phang2}{cmd:. polypml health heartatk diabetes highbp, thresholds}{p_end}
{phang2}{cmd:. polypml health heartatk diabetes highbp, method(fiml) draws(300)}{p_end}
{phang2}{cmd:. polypml health heartatk diabetes highbp [pw=finalwgt], vce(cluster psuid)}{p_end}
{phang2}{cmd:. test [health]heartatk = [health]diabetes}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations used{p_end}
{synopt:{cmd:e(k_var)}, {cmd:e(n_pairs)}}variables and pairs{p_end}
{synopt:{cmd:e(ll)}}log pairwise likelihood (pml) or simulated log likelihood (fiml){p_end}
{synopt:{cmd:e(converged)}, {cmd:e(iter)}}convergence flag and iterations{p_end}
{synopt:{cmd:e(mineig)}}smallest eigenvalue of {cmd:e(R)}{p_end}
{synopt:{cmd:e(draws)}, {cmd:e(n_patterns)}}draws and response patterns (fiml){p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:polypml}{p_end}
{synopt:{cmd:e(method)}}{cmd:pml} or {cmd:fiml}{p_end}
{synopt:{cmd:e(varlist)}, {cmd:e(vce)}, {cmd:e(clustvar)}, {cmd:e(wtype)}, {cmd:e(wexp)}}{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}correlations (equation = first variable) then thresholds; sandwich covariance{p_end}
{synopt:{cmd:e(R)}}correlation matrix{p_end}
{synopt:{cmd:e(tau)}, {cmd:e(cats)}}thresholds and category values (rows = variables){p_end}


{marker references}{...}
{title:References}

{phang}
Genz, A. 1992. Numerical computation of multivariate normal probabilities.
{it:Journal of Computational and Graphical Statistics} 1: 141-149.

{phang}
Katsikatsou, M., I. Moustaki, F. Yang-Wallentin, and K. G. J{c o:}reskog. 2012.
Pairwise likelihood estimation for factor analysis models with ordinal data.
{it:Computational Statistics and Data Analysis} 56: 4243-4258.

{phang}
Lewandowski, D., D. Kurowicka, and H. Joe. 2009. Generating random correlation
matrices based on vines and extended onion method. {it:Journal of Multivariate
Analysis} 100: 1989-2001.

{phang}
Varin, C., N. Reid, and D. Firth. 2011. An overview of composite likelihood
methods. {it:Statistica Sinica} 21: 5-42.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polycorr}, {helpb mi estimate}
{p_end}
