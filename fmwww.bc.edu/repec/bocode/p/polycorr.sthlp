{smcl}
{* *! version 1.1.0  21oct2026}{...}
{vieweralsosee "polyindex" "help polyindex"}{...}
{vieweralsosee "[R] tetrachoric" "help tetrachoric"}{...}
{vieweralsosee "[R] correlate" "help correlate"}{...}
{vieweralsosee "[MV] factormat" "help factormat"}{...}
{vieweralsosee "[MV] pcamat" "help pcamat"}{...}
{viewerjumpto "Syntax" "polycorr##syntax"}{...}
{viewerjumpto "Description" "polycorr##description"}{...}
{viewerjumpto "Options" "polycorr##options"}{...}
{viewerjumpto "Remarks" "polycorr##remarks"}{...}
{viewerjumpto "Examples" "polycorr##examples"}{...}
{viewerjumpto "Stored results" "polycorr##results"}{...}
{viewerjumpto "Methods and formulas" "polycorr##methods"}{...}
{viewerjumpto "References" "polycorr##references"}{...}
{title:Title}

{phang}
{bf:polycorr} {hline 2} Polychoric, polyserial and Pearson correlations with a
joint covariance matrix, bivariate-normality diagnostics and positive-definite repair


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:polycorr}
{varlist}
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Variable types}
{synopt:{opt cat:max(#)}}variables with more than {it:#} distinct values are
continuous; default is {cmd:catmax(10)}{p_end}
{synopt:{opth ord:inal(varlist)}}treat these variables as ordinal regardless of {opt catmax()}{p_end}
{synopt:{opth cont:inuous(varlist)}}treat these variables as continuous{p_end}

{syntab:Sample}
{synopt:{opt pair:wise}}pairwise deletion; default is listwise (casewise) deletion{p_end}

{syntab:SE/Survey}
{synopt:{opt vce(vcetype)}}{it:vcetype} may be {opt r:obust} (default),
{opt cl:uster} {it:clustvar}, or {opt none}{p_end}
{synopt:{opt svy}}design-based (linearized) variance using the {helpb svyset} strata, PSUs and weights{p_end}
{synopt:{opt novce}}skip the variance computation (fast; point estimates only){p_end}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}

{syntab:Diagnostics}
{synopt:{opt adj:ust(method)}}multiple-testing adjustment of the normality tests:
{opt holm} (default), {opt bh}, {opt bonferroni} or {opt none}{p_end}
{synopt:{opt fitreps(#)}}parametric-bootstrap p-values for the G2 normality tests
using {it:#} replications; default is {cmd:fitreps(0)} (none){p_end}
{synopt:{opt seed(#)}}random-number seed for {opt fitreps()}{p_end}
{synopt:{opt pd:fix}}also return the nearest positive-definite correlation matrix{p_end}

{syntab:Reporting}
{synopt:{opt fit}}display the table of normality tests{p_end}
{synopt:{opt mat:rix}}display the correlation matrix{p_end}
{synopt:{opt notab:le}}suppress the table of correlations{p_end}
{synopt:{opt cifz}}display Fisher-z instead of Wald confidence intervals{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance on atanh(rho); default is {cmd:tolerance(1e-9)}{p_end}
{synoptline}
{p 4 6 2}
{cmd:fweight}s, {cmd:aweight}s, {cmd:pweight}s and {cmd:iweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2}
{cmd:mi estimate}, {cmd:svy bootstrap}, {cmd:svy brr}, {cmd:svy sdr} and
{cmd:svy jackknife} are allowed; see {helpb mi estimate} and {helpb svy}.{p_end}
{p 4 6 2}
{cmd:test}, {cmd:lincom}, {cmd:nlcom}, {cmd:testnl} and {cmd:estimates} work after {cmd:polycorr}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:polycorr} estimates the correlation between every pair of variables in
{varlist}. Each variable is classified as ordinal or continuous. For two ordinal
variables it estimates the polychoric correlation, for one ordinal and one
continuous variable the polyserial correlation, and for two continuous variables
the Pearson correlation. With two categories these become the tetrachoric and
biserial correlations.

{pstd}
Unlike earlier implementations, {cmd:polycorr} is an e-class estimation command.
{cmd:e(b)} holds all k(k-1)/2 correlations and {cmd:e(V)} their {it:joint}
asymptotic covariance matrix. The covariance matrix is obtained from the influence
functions of the two-step estimator, so it allows for the estimated thresholds,
means and standard deviations. It can be heteroskedasticity robust, cluster robust
or design based (Taylor linearization). It is the matrix needed to compare or test
correlations against each other, and to fit ordinal structural equation models by
weighted least squares.

{pstd}
For every polychoric pair with positive degrees of freedom, {cmd:polycorr} also
computes:

{phang2}o the Pearson (X2) and likelihood-ratio (G2) tests of the underlying bivariate normality;{p_end}
{phang2}o the pairwise RMSEA;{p_end}
{phang2}o optional parametric-bootstrap p-values;{p_end}
{phang2}o multiple-testing adjusted p-values;{p_end}
{phang2}o a global min-p (Bonferroni) test across all pairs.{p_end}

{pstd}
It checks whether the correlation matrix is positive definite and, on request,
returns the nearest positive-definite correlation matrix (Higham 2002).

{pstd}
{helpb polyindex} builds polychoric principal-component indices, such as asset
or wealth indices, from these results.


{marker options}{...}
{title:Options}

{dlgtab:Variable types}

{phang}
{opt catmax(#)} sets the largest number of distinct values an ordinal variable may
have; variables with more distinct values are treated as continuous. The default
is 10. This value was hard-coded in earlier software.

{phang}
{opth ordinal(varlist)} and {opth continuous(varlist)} override the {opt catmax()}
rule for the named variables. Ordinal variables need not be coded 1, 2, ...;
only the ordering of their distinct values is used.

{dlgtab:Sample}

{phang}
{opt pairwise} uses, for each pair, all observations with both variables nonmissing.
By default, observations with a missing value in any variable are excluded
(listwise deletion), so all correlations share one sample and one set of
thresholds. Under {opt pairwise}, {cmd:e(V)} still accounts for the overlap
between pair samples.

{dlgtab:SE/Survey}

{phang}
{opt vce(robust)}, the default, computes the sandwich (influence-function)
covariance matrix. Under simple random sampling and correct specification, this
estimates the same quantity as the conventional two-step asymptotic covariance.

{phang}
{opt vce(cluster clustvar)} allows for correlation within clusters.

{phang}
{opt svy} uses the first-stage strata, primary sampling units and sampling
weights set by {helpb svyset}. It computes the linearized (with-replacement)
variance and uses t critical values with #PSU - #strata degrees of freedom.
Finite population corrections and later stages are ignored. Strata with a single
PSU are not allowed. For replicate-weight designs, use the {cmd:svy brr:},
{cmd:svy jackknife:}, {cmd:svy bootstrap:} or {cmd:svy sdr:} prefix instead.

{phang}
{opt novce} and {cmd:vce(none)} compute the correlations only. This is useful
inside loops and is used by {helpb polyindex}.

{dlgtab:Diagnostics}

{phang}
{opt adjust(method)} sets the multiple-testing correction applied to the G2
p-values: {opt holm} (Holm 1979), {opt bh} (Benjamini and Hochberg 1995),
{opt bonferroni} or {opt none}.

{phang}
{opt fitreps(#)} adds a parametric-bootstrap p-value for each G2 test. Tables
are drawn from the fitted bivariate-normal cell probabilities, the model is
re-estimated, and the statistic is recomputed. This is advisable when tables
have many sparse cells. A 2x2 table has zero degrees of freedom and cannot be
tested from the pair alone.

{phang}
{opt cifz} displays confidence limits computed on the Fisher-z scale,
tanh(atanh(rho) +/- q se/(1-rho^2)). These stay inside (-1, 1) and are
stored in {cmd:e(ci_fz)} whether or not the option is specified.

{phang}
{opt pdfix} computes the nearest correlation matrix in the Frobenius norm by
the alternating-projections algorithm of Higham (2002). It then raises any
eigenvalue below 1e-6 to 1e-6 and rescales to unit diagonal. The result is
stored in {cmd:e(R_pd)}; {cmd:e(R)} and {cmd:e(b)} are not altered.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Estimator.} {cmd:polycorr} uses the two-step estimator (Olsson 1979;
Olsson, Drasgow, and Dorans 1982). In the first step, thresholds are estimated
from the marginal distribution of each ordinal variable, and the mean and
standard deviation from each continuous variable. In the second step, the
correlation is estimated by maximum likelihood with these held fixed. This is
the estimator used in weighted-least-squares SEM pipelines, because it gives one
set of thresholds per variable, shared by all pairs. Point estimates can differ
in the third decimal from estimators that re-estimate the thresholds jointly
with each correlation.

{pstd}
{bf:Relation to polychoric.} Compared with Kolenikov's {cmd:polychoric},
{cmd:polycorr}:

{phang2}o returns standard errors, tests and fit statistics for {it:all} pairs, not only the last one;{p_end}
{phang2}o returns their joint covariance matrix;{p_end}
{phang2}o accounts for weights in the Pearson standard errors;{p_end}
{phang2}o supports clusters, survey designs and {cmd:mi estimate};{p_end}
{phang2}o makes the category cutoff an option;{p_end}
{phang2}o rejects unknown options instead of passing them to {cmd:ml};{p_end}
{phang2}o names the X2 and G2 statistics consistently.{p_end}

{pstd}
{bf:Boundary estimates.} Empty rows or columns of a cross-tabulation can push
the estimate to |rho| = 1. Such pairs are marked with {cmd:*}, flagged in
{cmd:e(pairs)}, and their standard errors should not be used.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Polychoric and polyserial correlations with robust joint covariance{p_end}
{phang2}{cmd:. polycorr rep78 foreign mpg}{p_end}

{pstd}Normality tests and the correlation matrix{p_end}
{phang2}{cmd:. polycorr rep78 foreign mpg headroom, fit matrix}{p_end}

{pstd}Is the polyserial correlation of mpg with foreign equal to that of headroom with foreign?{p_end}
{phang2}{cmd:. polycorr foreign mpg headroom, ordinal(headroom)}{p_end}
{phang2}{cmd:. test [foreign]mpg = [foreign]headroom}{p_end}

{pstd}Cluster-robust standard errors{p_end}
{phang2}{cmd:. polycorr rep78 foreign mpg, vce(cluster turn)}{p_end}

{pstd}Survey data{p_end}
{phang2}{cmd:. webuse nhanes2f, clear}{p_end}
{phang2}{cmd:. svyset psuid [pweight=finalwgt], strata(stratid)}{p_end}
{phang2}{cmd:. polycorr health heartatk diabetes highbp, svy}{p_end}

{pstd}Multiple imputation{p_end}
{phang2}{cmd:. mi estimate: polycorr x1 x2 x3}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:polycorr} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (union of pair samples){p_end}
{synopt:{cmd:e(k_var)}}number of variables{p_end}
{synopt:{cmd:e(n_pairs)}}number of pairs{p_end}
{synopt:{cmd:e(catmax)}}value of {opt catmax()}{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(mineig)}}smallest eigenvalue of {cmd:e(R)}{p_end}
{synopt:{cmd:e(is_pd)}}1 if {cmd:e(R)} is positive definite{p_end}
{synopt:{cmd:e(n_fit)}}number of testable polychoric pairs{p_end}
{synopt:{cmd:e(p_global)}}global min-p (Bonferroni) test of bivariate normality{p_end}
{synopt:{cmd:e(n_reject)}}pairs rejected at 5% after adjustment{p_end}
{synopt:{cmd:e(n_bound)}}number of boundary estimates{p_end}
{synopt:{cmd:e(fitreps)}}bootstrap replications for the fit tests{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters ({cmd:vce(cluster)}){p_end}
{synopt:{cmd:e(N_strata)}, {cmd:e(N_psu)}, {cmd:e(df_r)}}strata, PSUs and design df ({opt svy}){p_end}
{synopt:{cmd:e(pd_iter)}, {cmd:e(pd_maxchg)}}iterations and largest change ({opt pdfix}){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:polycorr}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(varlist)}}variables{p_end}
{synopt:{cmd:e(types)}}{cmd:O} (ordinal) or {cmd:C} (continuous) for each variable{p_end}
{synopt:{cmd:e(deletion)}}{cmd:listwise} or {cmd:pairwise}{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcetype)}}variance type{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable{p_end}
{synopt:{cmd:e(strata)}, {cmd:e(psu)}}survey design variables{p_end}
{synopt:{cmd:e(adjust)}}multiple-testing method{p_end}
{synopt:{cmd:e(wtype)}, {cmd:e(wexp)}}weight type and expression{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}correlations; equation = first variable, column = second variable{p_end}
{synopt:{cmd:e(V)}}joint covariance matrix of {cmd:e(b)}{p_end}
{synopt:{cmd:e(R)}}k x k correlation matrix{p_end}
{synopt:{cmd:e(R_pd)}}nearest positive-definite correlation matrix ({opt pdfix}){p_end}
{synopt:{cmd:e(Se)}, {cmd:e(P)}}k x k standard errors and p-values for rho = 0{p_end}
{synopt:{cmd:e(N_pair)}}k x k observations used per pair{p_end}
{synopt:{cmd:e(pairs)}}per pair: var1, var2, type (1 polychoric, 2 polyserial, 3 Pearson), N, flag (1 boundary, 2 degenerate){p_end}
{synopt:{cmd:e(fit)}}per pair: X2, df, p_X2, G2, p_G2, p_adj, RMSEA, p_boot{p_end}
{synopt:{cmd:e(ci_fz)}}Fisher-z confidence limits{p_end}
{synopt:{cmd:e(tau)}}thresholds of ordinal variables (rows){p_end}
{synopt:{cmd:e(cats)}}category values of ordinal variables (rows){p_end}
{synopt:{cmd:e(mu)}, {cmd:e(sd)}}means and standard deviations of continuous variables{p_end}

{p2col 5 18 22 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
Let theta denote the first-step parameters: thresholds tau_c = invnormal(F_c),
where F_c is the weighted cumulative proportion, and the means and standard
deviations of continuous variables. For pair p, rho_p solves the weighted score
equation sum_i w_i s_ip(rho_p, theta) = 0. Its influence function is

{p 8 8 2}
IF_ip = -H_p^(-1) [ s_ip + G_p psi_i ]

{pstd}
where H_p is the derivative of the mean score with respect to rho, G_p its
derivative with respect to theta, and psi_i the influence function of theta.
For a threshold, psi_i = (1{y_i <= c} - F_c)/phi(tau_c). For a Pearson pair,
IF_i = z_xi z_yi - rho (z_xi^2 + z_yi^2)/2.

{pstd}
With u_ip = w_i IF_ip / W_p, the robust estimator is
V = n/(n-1) sum_i u_i u_i'. The cluster version sums u_i within clusters. The
survey version sums u_i within PSUs and takes centred cross-products within
strata.

{pstd}
The fit tests compare observed and fitted cell counts, with
df = KL - K - L for a K x L table. The pairwise
RMSEA = sqrt(max(0, (G2 - df)/(df (n-1)))).


{marker references}{...}
{title:References}

{phang}
Benjamini, Y., and Y. Hochberg. 1995. Controlling the false discovery rate.
{it:Journal of the Royal Statistical Society, Series B} 57: 289-300.

{phang}
Higham, N. J. 2002. Computing the nearest correlation matrix: A problem from
finance. {it:IMA Journal of Numerical Analysis} 22: 329-343.

{phang}
Holm, S. 1979. A simple sequentially rejective multiple test procedure.
{it:Scandinavian Journal of Statistics} 6: 65-70.

{phang}
Kolenikov, S., and G. Angeles. 2009. Socioeconomic status measurement with
discrete proxy variables: Is principal component analysis a reliable answer?
{it:Review of Income and Wealth} 55: 128-165.

{phang}
Olsson, U. 1979. Maximum likelihood estimation of the polychoric correlation
coefficient. {it:Psychometrika} 44: 443-460.

{phang}
Olsson, U., F. Drasgow, and N. J. Dorans. 1982. The polyserial correlation
coefficient. {it:Psychometrika} 47: 337-347.


{title:Author}

{pstd}
Yusuf Toyin Yusuf{break}
Department of Economics and Development Studies{break}
Kwara State University, Malete, Nigeria{break}
ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Companion packages: {helpb polysem} (ordinal CFA by DWLS), {helpb polytest}
(triplet and polyserial normality tests), {helpb polycopula} (copula
polychorics), {helpb polypml} (pairwise maximum likelihood), {helpb polyreg}
(index regressions with generated-regressor correction), if installed.{p_end}
{psee}
Help: {helpb polyindex}, {helpb tetrachoric}, {helpb correlate}, {helpb factormat}, {helpb pcamat}
{p_end}
