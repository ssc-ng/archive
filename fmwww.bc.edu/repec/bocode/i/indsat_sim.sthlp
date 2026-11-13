{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat gauge" "help indsat_gauge"}{...}
{title:Title}

{phang}
{bf:indsat sim} {hline 2} Monte Carlo gauge and potency of indicator saturation


{title:Syntax}

{p 8 15 2}
{cmd:indsat sim} [{cmd:,} {opt t(#)} {opt rep:s(#)} {opt siz:es(numlist)} {opt break:date(#)} {opt out:lier(#)} {opt outd:ate(#)}
{opt rho(#)} {opt tp:val(#)} {opt win:dow(#)} {opt sat:uration(string)} {opt seed(#)} {it:isat_options}]


{title:Description}

{pstd}
Simulates {it:y_t = rho y_(t-1) + lambda 1(t >= tau) + delta 1(t = tau_o) + e_t}, {it:e_t ~ IN(0,1)}, with
{it:tau} = {opt breakdate()} x T, and runs {cmd:indsat} with the indicator sets in {opt saturation()} (default {cmd:sis})
for each break size in {opt sizes()} (default 0,...,5), as in the Monte Carlo designs of Castle, Doornik, Hendry &
Pretis (2015) and Kurle (2025). Reported: the {it:gauge} (retention rate of irrelevant indicators), the
{it:potency} (share of replications detecting the shift within +/-{opt window()} periods), the mean number
retained, and the mean, bias and RMSE of the estimated shift. Use it to calibrate {opt tpval()} for your sample
size or to reproduce the tables of the papers.{p_end}


{title:Examples}

{phang2}{cmd:. indsat sim, t(100) reps(500) sizes(0 1 2 3 4 5) tpval(0.01) seed(1)}{p_end}
{phang2}{cmd:. indsat sim, t(100) reps(500) saturation(iis sis) outlier(5) tpval(0.01) seed(1)}{p_end}
{phang2}{cmd:. indsat sim, t(100) reps(300) rho(0.5) tpval(0.01) seed(1)}{p_end}


{title:Stored results}

{pstd}{cmd:r(sim)}: lambda, reps, gauge, potency, retained, shift, bias, rmse.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}merwanroudane920@gmail.com{break}{browse "https://github.com/merwanroudane":github.com/merwanroudane}
