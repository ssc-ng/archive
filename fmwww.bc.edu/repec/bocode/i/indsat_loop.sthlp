{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat gauge" "help indsat_gauge"}{...}
{title:Title}

{phang}
{bf:indsat loop} {hline 2} Impulse indicator saturation over a grid of target sizes and the Jiao-Pretis outlier scaling tests


{title:Syntax}

{p 8 15 2}
{cmd:indsat loop} {depvar} [{indepvars}] {ifin} [{cmd:,} {opt nums(numlist)} | {opt tpvals(numlist)} {opt nsim(#)} {opt seed(#)} {opt gr:aph} {opt name()} {it:isat_options}]


{title:Description}

{pstd}
Runs {cmd:indsat ..., iis} for every target size in the grid ({opt nums()} = expected numbers of false outliers,
tpval = num/T, default 20,...,1; or {opt tpvals()} directly) and reports the number of retained impulses, the
empirical gauge and the outlier proportion test at each size. Two joint tests of the null of no outliers follow
(port of {it:gets::isat loop} and {it:gets::outlierscaletest}): the {it:scaling sum test} (normal) and the
{it:scaling sup test} (p-value simulated with {opt nsim()} draws from the Gaussian limit). Under the null the
retained counts track alpha*T at every size; counts well above it signal outliers or a misspecified model.
{opt graph} plots retained counts against the expected count with a 95% Poisson band. Results match R
{it:gets} exactly.{p_end}


{title:Example}

{phang2}{cmd:. use indsat_nile, clear}{p_end}
{phang2}{cmd:. indsat loop flow, nums(10(-1)1) seed(1) graph}{p_end}


{title:Stored results}

{pstd}{cmd:r(grid)} (tpval, expected, retained, gauge, z, p), {cmd:r(sum)}, {cmd:r(p_sum)}, {cmd:r(sup)}, {cmd:r(p_sup)}, {cmd:r(N)}.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}merwanroudane920@gmail.com{break}{browse "https://github.com/merwanroudane":github.com/merwanroudane}
