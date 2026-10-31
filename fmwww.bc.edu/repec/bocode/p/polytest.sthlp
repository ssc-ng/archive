{smcl}
{* *! version 1.0.0  21oct2026}{...}
{vieweralsosee "polycorr" "help polycorr"}{...}
{title:Title}

{phang}
{bf:polytest} {hline 2} Tests of the latent-normality assumption behind
tetrachoric, polychoric and polyserial correlations


{title:Syntax}

{p 8 17 2}
{cmd:polytest}
{varlist}
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt trip:lets}}triplet tests for all triplets of ordinal variables{p_end}
{synopt:{opt poly:serial}}binned tests for all (continuous, ordinal) pairs{p_end}
{synopt:{opt reps(#)}}parametric-bootstrap replications; default 199; 0 for asymptotic p-values only{p_end}
{synopt:{opt bins(#)}}number of quantile bins of the continuous variable; default 5{p_end}
{synopt:{opt adj:ust(method)}}{opt holm} (default), {opt bh}, {opt bonferroni} or {opt none}{p_end}
{synopt:{opt maxt:riplets(#)}}refuse to run more than {it:#} triplets; default 500{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt cat:max(#)}, {opt ord:inal()}, {opt cont:inuous()}}variable types, as in {helpb polycorr}{p_end}
{synoptline}
{p 4 6 2}
If neither {opt triplets} nor {opt polyserial} is specified, both are run.
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed.{p_end}


{title:Description}

{pstd}
The pairwise goodness-of-fit tests reported by {helpb polycorr} cannot test
normality for a 2x2 table. Such a table has three free cell probabilities and
three parameters (two thresholds and the tetrachoric correlation), so it fits
exactly. {cmd:polytest} adds two tests that cover this case and polyserial pairs.

{pstd}
{bf:Triplet test.} For three ordinal variables with K, L and M categories, the
three-way table has KLM - 1 free cells. The trivariate-normal model, fitted by
the usual two-step estimator (marginal thresholds and the three pairwise
polychoric correlations), has K + L + M - 3 + 3 parameters. This leaves

{p 8 8 2}
df = KLM - K - L - M - 1

{pstd}
degrees of freedom, which equals 1 for three binary variables. The fitted cell
probabilities are trivariate normal rectangle probabilities, computed by
48-point Gauss-Legendre integration of binormal(). The Pearson (X2) and
likelihood-ratio (G2) statistics are reported. Because the parameters come from
pairwise two-step estimation rather than trivariate ML, the chi-squared
reference distribution is approximate. The parametric bootstrap p-value is
therefore the default: tables are drawn from the fitted probabilities and the
estimation is repeated for each draw.

{pstd}
{bf:Polyserial test.} Under the polyserial model, y given the standardized
continuous variable z is ordered probit with index rho z/sqrt(1-rho^2) and
thresholds tau/sqrt(1-rho^2). The test splits x into {opt bins()} quantile
bins and compares observed and expected counts of each category of y within
each bin. The approximate degrees of freedom are B(L-1) - L. The bootstrap
p-value simulates y given x from the fitted model. The marginal normality of x,
also assumed by the polyserial model, is tested by the Jarque-Bera statistic.

{pstd}
p-values (bootstrap if {opt reps()}>0, otherwise G2 or X2) are adjusted for
multiplicity. A global min-p (Bonferroni) test is reported for each family.


{title:Examples}

{phang2}{cmd:. webuse nhanes2f, clear}{p_end}
{phang2}{cmd:. polytest heartatk diabetes highbp health, triplets seed(1)}{p_end}
{phang2}{cmd:. polytest weight health highbp, polyserial bins(8) seed(1)}{p_end}


{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(p_global_trip)}, {cmd:r(n_reject_trip)}}global test and rejections, triplets{p_end}
{synopt:{cmd:r(p_global_ps)}, {cmd:r(n_reject_ps)}}global test and rejections, polyserial pairs{p_end}
{synopt:{cmd:r(N)}, {cmd:r(reps)}, {cmd:r(bins)}}{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(triplets)}}v1 v2 v3 df X2 p_X2 G2 p_G2 p_boot p_adj flag (variable positions in varlist){p_end}
{synopt:{cmd:r(polyserial)}}x y rho df X2 p_X2 p_boot p_adj JB p_JB{p_end}


{title:References}

{phang}
Foldnes, N., and S. Gronneberg. 2020. Pernicious polychorics: The impact and
detection of underlying non-normality. {it:Structural Equation Modeling} 27: 525-543.

{phang}
Jarque, C. M., and A. K. Bera. 1987. A test for normality of observations and
regression residuals. {it:International Statistical Review} 55: 163-172.


{title:Author}

{pstd}
Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com


{title:Also see}

{psee}
Help: {helpb polycorr}, {helpb polycopula} (if installed)
{p_end}
