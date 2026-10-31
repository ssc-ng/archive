{smcl}
{* *! version 1.1.0  25oct2026}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{vieweralsosee "polytest" "help polytest"}{...}
{title:Title}

{phang}
{bf:polycopula} {hline 2} Copula-based association for ordinal variables:
Gaussian (polychoric), Frank, Clayton and Gumbel


{title:Syntax}

{p 8 17 2}
{cmd:polycopula}
{varlist}
{ifin}
{weight}
[{cmd:,} {opt cop:ulas(list)} {opt rob:ust} {opt cut:off(#)} {opt cat:max(#)} {opth ord:inal(varlist)} {opt l:evel(#)}]

{p 4 6 2}
{it:list} is any of {cmd:gaussian frank clayton gumbel} (default: all four;
{cmd:gaussian} is always included). {cmd:fweight}s, {cmd:aweight}s and
{cmd:pweight}s are allowed.{p_end}


{title:Description}

{pstd}
The polychoric correlation is the parameter of a Gaussian copula linking the
latent variables behind two ordinal variables. When {helpb polytest} or the
{helpb polycorr} fit tests reject latent normality, the polychoric correlation
can misstate the strength of association.

{pstd}
{cmd:polycopula} fits, for every pair, the same two-step model with the
Gaussian copula replaced by:

{phang2}o Frank: symmetric, no tail dependence;{p_end}
{phang2}o Clayton: lower-tail dependence;{p_end}
{phang2}o Gumbel: upper-tail dependence.{p_end}

{pstd}
Clayton and Gumbel are rotated by 90 degrees when the dependence is negative.

{pstd}
The cell probabilities are rectangle probabilities of the copula, evaluated at
the marginal cumulative proportions. The copula parameter is estimated by
maximum likelihood with the margins held fixed (inference functions for
margins; Joe 2005).

{pstd}
For each copula, {cmd:polycopula} reports:

{phang2}o the parameter;{p_end}
{phang2}o Kendall's tau, which is comparable across families;{p_end}
{phang2}o the normal-equivalent correlation rho* = sin(pi tau/2);{p_end}
{phang2}o robust standard errors for the parameter and for tau, from the
two-step influence function, which accounts for the estimated margins;{p_end}
{phang2}o the log likelihood, AIC and BIC;{p_end}
{phang2}o the G2 goodness-of-fit statistic with KL-K-L df;{p_end}
{phang2}o a Vuong (1989) z statistic comparing each copula with the Gaussian.{p_end}


{title:Robust polychoric correlation}

{pstd}
Option {opt robust} adds, for every pair, the robust polychoric correlation of
Welz, Mair, and Alfons (2025). It is designed for data contaminated by careless
or inattentive responding, which a copula cannot repair. Thresholds and rho are
estimated jointly by minimizing

{p 8 8 2}
sum over cells of phi(f/p(theta) - 1) p(theta),

{pstd}
where f is the observed cell proportion, p(theta) the polychoric cell
probability, and phi(z) = (z+1)ln(z+1) for z <= c and is linear above c.
Equivalently, the estimating equations are those of maximum likelihood, with
each cell's Pearson ratio f/p capped at 1 + c. Cells that are far more
frequent than the model predicts are downweighted.

{pstd}
{opt cutoff(#)} sets c; the default is 0.6, as recommended by the authors.
Smaller values are more robust; c = infinity gives maximum likelihood with
thresholds and rho estimated jointly. Standard errors come from the influence
function of the estimating equation, which accounts for the estimated
thresholds. Under correct specification, they agree with the maximum
likelihood standard errors. The table reports the two-step ML estimate, the
robust estimate, its standard error, the number of downweighted cells, and a
convergence flag. They are also returned in {cmd:r(robust)}.

{pstd}
{bf:Caution.} The robust estimator is designed for a {it:small} fraction of
contaminated responses. If many cells are downweighted (say, more than a few of
the K x L cells), and the robust and ML estimates differ widely, the polychoric
model itself probably fits poorly. In that case, the robust estimate describes
only the part of the table that the Gaussian model can fit, and the copula
comparisons above (or {helpb polytest}) are the more informative diagnostics.


{title:Examples}

{phang2}{cmd:. webuse gsem_cfa, clear}{p_end}
{phang2}{cmd:. polycopula att1 att2 att3}{p_end}
{phang2}{cmd:. polycopula q1 q2 att1, copulas(clayton gumbel)}{p_end}
{phang2}{cmd:. matrix list r(table)}{p_end}
{phang2}{cmd:. polycopula q1 q2 q3, copulas(gaussian) robust}{p_end}


{title:Stored results}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}one row per pair and copula: pair, family, rotated, theta, se, tau, se_tau, rho_star, ll, aic, bic, G2, df, p_G2, vuong, p_vuong{p_end}
{synopt:{cmd:r(robust)}}with {opt robust}: pair, rho_ml, rho_robust, se_robust, cells_down, converged{p_end}
{p2col 5 16 20 2: Scalars and macros}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(copulas)}, {cmd:r(varlist)}}{p_end}


{title:References}

{phang}
Joe, H. 2005. Asymptotic efficiency of the two-stage estimation method for
copula-based models. {it:Journal of Multivariate Analysis} 94: 401-419.

{phang}
Nelsen, R. B. 2006. {it:An Introduction to Copulas}. 2nd ed. New York: Springer.

{phang}
Welz, M., P. Mair, and A. Alfons. 2025. Robust estimation of polychoric
correlation. {it:Psychometrika}, published online.

{phang}
Vuong, Q. H. 1989. Likelihood ratio tests for model selection and non-nested
hypotheses. {it:Econometrica} 57: 307-333.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polycorr}, {helpb polytest} (if installed)
{p_end}
