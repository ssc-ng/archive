{smcl}
{* *! version 1.2.2  09nov2026}{...}
{vieweralsosee "idxnl" "help idxnl"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:idxdescribe} {hline 2}}Characterize index covariates before nonlinear or interactive modelling{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 18 2}
{cmd:idxdescribe} {varlist} {ifin} [{cmd:,} {opt bounds(lo hi)} {opth se(varlist)} {opt scale(interval|ordinal|ratio)} {opt trim(#)}]

{title:Description}

{pstd}
For each index, {cmd:idxdescribe} reports location, dispersion, skewness, the trimmed support
[p({it:trim}), p(1-{it:trim})], the number of distinct values, whether the index is signed, and a
provisional measurement scale. With {opt bounds()} it reports the share of observations within 5%
of each theoretical bound and the share of the theoretical range that is observed. If the data are
{cmd:xtset}, it decomposes the standard deviation into within and between components and reports the
within share of the variance. With {opt se()} (one standard-error variable per index, for example
the margins of error published with the Worldwide Governance Indicators) it reports total and within
reliability ratios under classical measurement error and the implied attenuation of a within
quadratic coefficient (reliability squared, under a normal approximation). Diagnostic flags point to
specification choices that depend on these properties.

{title:Options}

{phang}{opt bounds(lo hi)} theoretical lower and upper bounds of the index.{p_end}
{phang}{opt se(varlist)} standard errors of measurement, one variable per index.{p_end}
{phang}{opt scale()} declares the measurement scale; otherwise a heuristic classification is shown.{p_end}
{phang}{opt trim(#)} tail share for the supported interval; default 0.05.{p_end}

{title:Examples}

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. idxdescribe gov ict, bounds(-2.5 2.5)}{p_end}
{phang2}{cmd:. idxdescribe gov, bounds(-2.5 2.5) se(gov_se) scale(interval)}{p_end}

{title:Stored results}

{pstd}{cmd:r(table)}: one row per index with N, mean, sd, min, max, skew, p_lo, p50, p_hi, distinct,
floor, ceiling, sd_within, sd_between, within_share, rel_within.{p_end}

{title:Authors}

{pstd}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete, Nigeria; ytoyinyusuf@gmail.com{p_end}
{pstd}Francis Baidoo, Faculty of Business and Management Studies, Koforidua Technical University, Koforidua, Ghana{p_end}
