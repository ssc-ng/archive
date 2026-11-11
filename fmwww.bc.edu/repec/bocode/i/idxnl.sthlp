{smcl}
{* *! version 1.2.2  09nov2026}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{bf:idxnl} {hline 2}}Nonlinear and interactive modelling with index covariates{p_end}
{p2colreset}{...}

{title:Commands}

{p2colset 5 20 22 2}{...}
{p2col:{helpb idxdescribe}}characterize scale, support, bounds, within variation, and reliability{p_end}
{p2col:{helpb idxspec}}compare linear, quadratic, cubic, spline, and kink specifications and evaluate turning-point claims on the supported interval; options for common correlated effects, two-way clustered and Driscoll-Kraay errors, instrumental variables, SIMEX measurement-error correction, and percentile-rank (ordinal) analysis{p_end}
{p2col:{helpb idxtp}}turning-point inference (delta and Fieller) and support-restricted U-shape test after any estimation{p_end}
{p2col:{helpb idxint}}support-aware and curvature-robust analysis of interactions between indices{p_end}
{p2colreset}{...}

{title:Workflow}

{pstd}
1. Characterize each index ({cmd:idxdescribe}): scale, sign and arbitrary origin, bounds and mass points,
within-unit variation, and reliability.{p_end}
{pstd}
2. Restrict attention to specifications whose implications do not depend on arbitrary features of the
index coding (affine-invariant bases for interval-scale indices; rank-based statements for ordinal
indices).{p_end}
{pstd}
3. Compare specifications ({cmd:idxspec}) and accept a turning point only when the support-restricted
U-test, the Fieller interval, and the two-lines check agree.{p_end}
{pstd}
4. For interactions ({cmd:idxint}), check robustness to own curvature, test the linearity of the
interaction, and report conditional effects only where the moderator is supported.{p_end}

{title:Installation}

{phang2}{cmd:. net install idxnl, from(}{it:path}{cmd:)}{p_end}
{phang2}{cmd:. net get idxnl, from(}{it:path}{cmd:)}{space 4}(ancillary example data and do-files){p_end}

{title:Authors}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com{p_end}
{pstd}Francis Baidoo, Faculty of Business and Management Studies, Koforidua Technical University, Koforidua, Ghana{p_end}
