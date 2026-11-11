{smcl}
{* *! version 1.2.2  09nov2026}{...}
{vieweralsosee "idxnl" "help idxnl"}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{bf:idxint} {hline 2}}Support-aware interaction analysis for two index covariates{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 14 2}
{cmd:idxint} {depvar} {it:x} {it:z} [{it:controls}] {ifin} [{cmd:,} {opt fe} {opth vce(vcetype)} {opt trim(#)}
{opt nb:ins(#)} {opt ng:rid(#)} {opt minc:ount(#)} {opt l:evel(#)} {opt cce} {opt two:way} {opt dk} {opt dkl:ag(#)} {opt gr:aph} {opt graphopt:s(string)} {opt notab:le}]

{title:Description}

{pstd}
{cmd:idxint} studies how the effect of index {it:x} varies with index {it:z}. It reports

{phang2}(A) the conventional linear interaction model y = a + b x + c z + d xz + controls;{p_end}
{phang2}(B) the same model with x^2 and z^2 added, which guards against product terms that merely
absorb own curvature when x and z are correlated (for bivariate normal indices with correlation r, a
pure x^2 effect b loads 2r/(1+r^2) b onto the product term);{p_end}
{phang2}(N) a nested Wald test of the linear-interaction assumption that adds moderator-bin indicators
and their products with x;{p_end}
{phang2}(C) binned effects of x within quantile bins of z.{p_end}

{pstd}
It then evaluates the conditional effect of x from (A) on a grid of z values and flags each grid point
as supported when (i) it lies inside [p({it:trim}), p(1-{it:trim})] of z, (ii) at least
{opt mincount()} observations lie within a Silverman-type bandwidth of it, and (iii) the local standard
deviation of x is at least one quarter of its overall standard deviation. Johnson-Neyman bounds are
reported with a note when they fall outside the supported range.

{title:Options}

{phang}{opt fe} uses {cmd:xtreg, fe}; {opt vce()} is passed to the estimator.{p_end}
{phang}{opt cce} (with {opt fe}) adds period averages of y, x, x^2, z, and the continuous controls interacted with panel indicators (common correlated effects); {opt twoway} uses two-way clustered standard errors; {opt dk} and {opt dklag(#)} use Driscoll-Kraay standard errors. All require {cmd:xtset} data; see {helpb idxspec}.{p_end}
{phang}{opt nbins(#)} number of moderator bins (2-5); default 3.{p_end}
{phang}{opt ngrid(#)} number of grid points; default 25.{p_end}
{phang}{opt mincount(#)} minimum local count; default max(20, 2% of N).{p_end}
{phang}{opt graph} plots the conditional effect, solid where supported and dashed where extrapolated.{p_end}

{title:Examples}

{phang2}{cmd:. idxint y gov2 gov1 w1 w2 i.year, vce(cluster id) graph}{p_end}

{title:Stored results}

{pstd}Scalars {cmd:r(N)}, {cmd:r(rho)}, {cmd:r(b_xz_A)}, {cmd:r(se_xz_A)}, {cmd:r(p_xz_A)}, {cmd:r(b_xz_B)},
{cmd:r(se_xz_B)}, {cmd:r(p_xz_B)}, {cmd:r(F_quad)}, {cmd:r(p_quad)}, {cmd:r(F_bin)}, {cmd:r(p_bin)},
{cmd:r(jn_lb)}, {cmd:r(jn_ub)}, {cmd:r(zsup_lo)}, {cmd:r(zsup_hi)}, {cmd:r(spur_factor)}; matrix {cmd:r(grid)}.{p_end}

{title:References}

{phang}Ganzach, Y. 1997. Misleading interaction and curvilinear terms. {it:Psychological Methods} 2: 235-247.{p_end}
{phang}Hainmueller, J., J. Mummolo, and Y. Xu. 2019. How much should we trust estimates from multiplicative interaction models? Simple tools to improve empirical practice. {it:Political Analysis} 27: 163-192.{p_end}
{phang}Simonsohn, U. 2024. Interacting with curves: How to validly test and probe interactions in the real (nonlinear) world. {it:Advances in Methods and Practices in Psychological Science} 7(1): 1-22.{p_end}

{title:Authors}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com{p_end}
{pstd}Francis Baidoo, Faculty of Business and Management Studies, Koforidua Technical University, Koforidua, Ghana{p_end}
