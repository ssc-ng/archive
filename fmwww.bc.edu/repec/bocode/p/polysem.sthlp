{smcl}
{* *! version 1.0.0  21oct2026}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{vieweralsosee "[SEM] gsem" "help gsem"}{...}
{title:Title}

{phang}
{bf:polysem} {hline 2} Confirmatory factor analysis of ordinal indicators by
diagonally weighted least squares on polychoric correlations


{title:Syntax}

{p 8 17 2}
{cmd:polysem}
{cmd:(}{it:fname}{cmd::} {it:varlist}{cmd:)}
[{cmd:(}{it:fname}{cmd::} {it:varlist}{cmd:)} ...]
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt est:imator(dwls|uls|wls)}}weight matrix; default {cmd:dwls}{p_end}
{synopt:{opt orth:ogonal}}constrain factor correlations to zero{p_end}
{synopt:{opt vce(vcetype)}}{cmd:robust} (default) or {cmd:cluster} {it:clustvar}; passed to {helpb polycorr}{p_end}
{synopt:{opt svy}}design-based correlation covariance; see {helpb polycorr}{p_end}
{synopt:{opt pair:wise}, {opt cat:max(#)}, {opt ord:inal()}, {opt cont:inuous()}}passed to {helpb polycorr}{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt iter:ate(#)}}maximum Gauss-Newton iterations; default 500{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance on parameter change; default 1e-10{p_end}
{synoptline}
{p 4 6 2}
Weights are passed to {helpb polycorr}. A variable may appear in more than one
factor specification (cross-loading).{p_end}


{title:Description}

{pstd}
{cmd:polysem} fits the factor model R = Lambda Phi Lambda' + Theta to the
polychoric, polyserial and Pearson correlations of the indicators. Here Theta
is diagonal with Theta_ii = 1 - (Lambda Phi Lambda')_ii, because the latent
responses have unit variance. The command:

{phang2}1. runs {helpb polycorr} to obtain the vector of correlations r and its covariance matrix V;{p_end}
{phang2}2. minimizes (r - sigma(theta))' W (r - sigma(theta)) by Gauss-Newton with step halving.{p_end}

{pstd}
With {cmd:dwls}, W = diag(V)^(-1), as in the WLSMV estimator of Muthen,
du Toit and Spisic (1997). With {cmd:uls}, W = I. With {cmd:wls}, W = V^(-1).

{pstd}
Standard errors are robust (sandwich):

{p 8 8 2}
(D'WD)^(-1) D'W V W D (D'WD)^(-1)

{pstd}
where D is the Jacobian of sigma(theta). They inherit the robust, cluster or
survey form of V.

{pstd}
The residual statistic T = e'We is a weighted sum of chi-squared variables. It
is reported in two adjusted forms:

{phang2}o mean-adjusted (scaled), T df/tr(UV);{p_end}
{phang2}o mean- and variance-adjusted (scaled and shifted), a T + b, with a = sqrt(df/tr((UV)^2)) and b = df - a tr(UV).{p_end}

{pstd}
Here U = W - WD(D'WD)^(-1)D'W. The scaled-and-shifted form is the default
test. CFI and TLI use a baseline model with all correlations equal to zero.
RMSEA uses the adjusted statistic, and SRMR is computed from the correlation
residuals.

{pstd}
Loadings are on the standardized latent-response scale. Thresholds are left
unrestricted, so the model has no mean structure.


{title:Examples}

{phang2}{cmd:. webuse gsem_cfa, clear}{p_end}
{phang2}{cmd:. polysem (MathAb: q1-q8) (MathAtt: att1-att5)}{p_end}
{phang2}{cmd:. test [MathAb]q1 = [MathAb]q2}{p_end}
{phang2}{cmd:. polysem (MathAb: q1-q8) (MathAtt: att1-att5), vce(cluster school)}{p_end}
{phang2}{cmd:. matrix list e(resid)}{p_end}


{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_var)}, {cmd:e(k_factor)}}indicators and factors{p_end}
{synopt:{cmd:e(chi2)}, {cmd:e(df_m)}, {cmd:e(p)}}mean- and variance-adjusted test{p_end}
{synopt:{cmd:e(chi2_ms)}, {cmd:e(p_ms)}}mean-adjusted (scaled) test{p_end}
{synopt:{cmd:e(chi2_raw)}}unadjusted residual statistic e'We{p_end}
{synopt:{cmd:e(chi2_bs)}, {cmd:e(df_bs)}}adjusted baseline statistic{p_end}
{synopt:{cmd:e(cfi)}, {cmd:e(tli)}, {cmd:e(rmsea)}, {cmd:e(srmr)}}fit indices{p_end}
{synopt:{cmd:e(heywood)}}number of negative uniquenesses{p_end}
{synopt:{cmd:e(iter)}, {cmd:e(converged)}}iterations and convergence flag{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:polysem}{p_end}
{synopt:{cmd:e(factors)}, {cmd:e(ind}{it:#}{cmd:)}, {cmd:e(indicators)}}model specification{p_end}
{synopt:{cmd:e(estimator)}, {cmd:e(structure)}, {cmd:e(vce)}, {cmd:e(types)}}{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}loadings (equation = factor) and factor correlations (equation {cmd:corr}){p_end}
{synopt:{cmd:e(Lambda)}, {cmd:e(Phi)}, {cmd:e(Theta)}}loading matrix, factor correlations, uniquenesses{p_end}
{synopt:{cmd:e(resid)}}correlation residuals{p_end}


{title:References}

{phang}
Asparouhov, T., and B. Muthen. 2010. Simple second order chi-square correction.
Technical appendix, Mplus.

{phang}
Muthen, B., S. H. C. du Toit, and D. Spisic. 1997. Robust inference using weighted
least squares and quadratic estimating equations in latent variable modeling
with categorical and continuous outcomes. Unpublished manuscript.

{phang}
Satorra, A., and P. M. Bentler. 1994. Corrections to test statistics and
standard errors in covariance structure analysis. In {it:Latent Variables Analysis},
ed. A. von Eye and C. C. Clogg, 399-419. Thousand Oaks, CA: Sage.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polycorr}, {helpb gsem}, {helpb sem}
{p_end}
