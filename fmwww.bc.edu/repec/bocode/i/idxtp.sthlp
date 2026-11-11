{smcl}
{* *! version 1.2.2  09nov2026}{...}
{vieweralsosee "idxnl" "help idxnl"}{...}
{vieweralsosee "idxspec" "help idxspec"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{bf:idxtp} {hline 2}}Turning-point inference and support-restricted U-shape test after estimation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 14 2}
{cmd:idxtp} {it:varname} [{cmd:,} {opt sq(name)} {opt min(#)} {opt max(#)} {opt trim(#)} {opt l:evel(#)} {opt nodis:play}]

{title:Description}

{pstd}
{cmd:idxtp} is used after an estimation command whose model contains {it:varname} and its square.
The squared term may be a generated variable named in {opt sq()} or the factor-variable term
{cmd:c.}{it:varname}{cmd:#c.}{it:varname} (the default). {cmd:idxtp} reports the turning point
-b1/(2 b2), its delta-method interval, the Fieller interval (bounded, union of two half-lines, or
unbounded), its percentile position in the estimation sample, and the Lind-Mehlum test evaluated
at the bounds of the supported interval S = [p({it:trim}), p(1-{it:trim})]. The test on the full
observed range is reported for comparison. Student-t critical values with e(df_r) degrees of freedom
are used when available.

{title:Options}

{phang}{opt sq(name)} names the squared term in {cmd:e(b)}.{p_end}
{phang}{opt min(#)} and {opt max(#)} set S directly and override {opt trim()}.{p_end}
{phang}{opt trim(#)} tail share removed from each side; default 0.05. {cmd:trim(0)} uses [min, max].{p_end}
{phang}{opt level(#)} confidence level for the intervals.{p_end}

{title:Examples}

{phang2}{cmd:. regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)}{p_end}
{phang2}{cmd:. idxtp gov}{p_end}
{phang2}{cmd:. generate gov2 = gov^2}{p_end}
{phang2}{cmd:. xtreg y gov gov2 w1 w2 i.year, fe vce(cluster id)}{p_end}
{phang2}{cmd:. idxtp gov, sq(gov2) trim(0.10)}{p_end}

{title:Stored results}

{pstd}Scalars {cmd:r(tp)}, {cmd:r(se_tp)}, {cmd:r(tp_pct)}, {cmd:r(delta_lb)}, {cmd:r(delta_ub)},
{cmd:r(fieller_lb)}, {cmd:r(fieller_ub)}, {cmd:r(lm_t)}, {cmd:r(lm_p)}, {cmd:r(lmfull_t)}, {cmd:r(lmfull_p)},
{cmd:r(slope_lo)}, {cmd:r(slope_hi)}, {cmd:r(t_lo)}, {cmd:r(t_hi)}, {cmd:r(lo)}, {cmd:r(hi)},
{cmd:r(inside)}, {cmd:r(fieller_inside)}; macros {cmd:r(shape)} and {cmd:r(fieller_type)}.{p_end}

{title:References}

{phang}Hirschberg, J., and J. Lye. 2010. A geometric comparison of the delta and Fieller confidence intervals. {it:American Statistician} 64: 234-241.{p_end}
{phang}Lind, J. T., and H. Mehlum. 2010. With or without U? The appropriate test for a U-shaped relationship. {it:Oxford Bulletin of Economics and Statistics} 72: 109-118.{p_end}

{title:Authors}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com{p_end}
{pstd}Francis Baidoo, Faculty of Business and Management Studies, Koforidua Technical University, Koforidua, Ghana{p_end}
