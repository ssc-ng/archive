{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat methods" "help indsat_methods"}{...}
{title:Title}

{phang}
{bf:indsat gauge} {hline 2} Null-theory calculator for indicator saturation


{title:Syntax}

{p 8 15 2}
{cmd:indsat gauge} {cmd:,} {opt t(#)} [{opt tp:vals(numlist)} {opt m(#)}]


{title:Description}

{pstd}
For a sample size {opt t()} and a list of target sizes (default 0.05, 0.025, 0.01, 1/T, 0.005, 0.001),
{cmd:indsat gauge} reports the two-sided cut-off {it:c}; the expected number of falsely retained impulses alpha*T
(Hendry, Johansen & Santos 2008); its standard deviation and that of the gauge, from the normal theory of
Johansen & Nielsen (2016) for the {opt m()}-step estimator; Poisson probabilities of zero and of three or more
false impulses; the sigma consistency factor xi; and the efficiency of the regression coefficients, 1/eta_m^2
(Johansen & Nielsen 2009, 2016). Use it to choose {opt tpval()} before running {helpb indsat} and to justify
that choice in a paper.{p_end}


{title:Examples}

{phang2}{cmd:. indsat gauge, t(200)}{p_end}
{phang2}{cmd:. indsat gauge, t(100) tpvals(0.05 0.01 0.001) m(3)}{p_end}


{title:Stored results}

{pstd}{cmd:r(gauge)}: alpha, c, expected, sd_count, p0, p3plus, sd_gauge, xi, eta, eff.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}merwanroudane920@gmail.com{break}{browse "https://github.com/merwanroudane":github.com/merwanroudane}
