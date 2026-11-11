{smcl}
{* *! version 1.0.0  09nov2026}{...}
{vieweralsosee "csdlp" "help csdlp"}{...}
{vieweralsosee "csdlp methods" "help csdlp_methods"}{...}
{vieweralsosee "csdlp_graph" "help csdlp_graph"}{...}
{viewerjumpto "csdlp_diff" "csdlp_postestimation##diff"}{...}
{viewerjumpto "csdlp_agg" "csdlp_postestimation##agg"}{...}
{viewerjumpto "Examples" "csdlp_postestimation##examples"}{...}
{title:Title}

{phang}
{bf:csdlp postestimation} {hline 2} Postestimation tools for {helpb csdlp}

{pstd}
The following commands are available after {cmd:csdlp}. They use the stored
B-spline knots, coefficients and HAC variances, and they leave {cmd:e()}
unchanged.

{p2colset 5 22 24 2}{...}
{p2col:{helpb csdlp_postestimation##diff:csdlp_diff}}differential responses g_h(z_a) - g_h(z_b) across horizons (paper Fig. 4){p_end}
{p2col:{helpb csdlp_postestimation##agg:csdlp_agg}}weighted aggregate responsiveness by period (paper Fig. 5){p_end}
{p2col:{helpb csdlp_graph}}IRF panels with uniform bands, Lemma 1 diagnostic, surface{p_end}
{p2col:{cmd:csdlp}}typed without arguments, redisplays the tables{p_end}


{marker diff}{...}
{title:csdlp_diff}

{p 8 16 2}
{cmd:csdlp_diff} {cmd:,} {opt at(# #)} [{opt val:ues} {opth h:orizons(numlist)}
{opt l:evel(#)} {opt level2(#)} {opt nogr:aph} {opt name(string)}
{opt sav:ing(filename)} {opt nolin:ear}]

{pstd}
{opt at(a b)} gives two percentiles of the state (default) or, with
{opt values}, two state values. For each horizon the command reports
d_h = g_h(z_a) - g_h(z_b) with variance
(phi(z_a)-phi(z_b))' V_h (phi(z_a)-phi(z_b)) and pointwise
confidence intervals, as in footnote 17 of the paper. It also reports the
linear-interaction counterpart beta_h (z_a - z_b). The graph plots both
across horizons with {opt level()} and {opt level2()} bands. Because the
contrast is a pointwise object, these intervals are pointwise.

{pstd}
Stored: {cmd:r(diff)} (columns {it:h d se lo hi lo2 hi2 p dlin selin llo lhi llo2 lhi2 plin}), {cmd:r(za)}, {cmd:r(zb)}.


{marker agg}{...}
{title:csdlp_agg}

{p 8 16 2}
{cmd:csdlp_agg} {it:weightvar} {ifin} [{cmd:,} {opt h:orizon(#)} {opt l:evel(#)}
{opt ci} {opt all:obs} {opt nogr:aph} {opt name(string)} {opt sav:ing(filename)}
{opt nolin:ear}]

{pstd}
Computes the aggregate responsiveness of Section 6.2,

{p 8 8 2}A_{c -(}t,h{c )-} = sum_i [K_{c -(}i,t-1{c )-} / sum_j K_{c -(}j,t-1{c )-}] g_h(Z_{c -(}i,t-1{c )-}),{p_end}

{pstd}
for every period, where {it:weightvar} is K_{c -(}i,t-1{c )-} (for example
{cmd:L.capital}). A_{c -(}t,h{c )-} is a linear functional a_t'b_h of the sieve
coefficients, so its standard error is sqrt(a_t'V_h a_t). The command reports
the time average (with s.e.), the standard deviation over time, and the
correlation between the sieve and the linear-interaction series; the paper
finds about -0.7. With absorbed sector-time effects, g_h is normalised, so
A_{c -(}t,h{c )-} is the {it:incremental} contribution of heterogeneity in the state, as in
the paper. By default the sample is {cmd:e(sample)}; {opt allobs} uses every
observation with non-missing state and weight. {opt ci} adds the
confidence band to the graph.

{pstd}
Stored: {cmd:r(agg)} (columns {it:t agg se lo hi agglin selin llo lhi}),
{cmd:r(mean)}, {cmd:r(se_mean)}, {cmd:r(mean_lin)}, {cmd:r(se_mean_lin)},
{cmd:r(sd)}, {cmd:r(sd_lin)}, {cmd:r(corr)}, {cmd:r(horizon)}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. csdlp lnk, shock(mp) state(L.d2d) horizons(0/16) cumulative absorb(sector#t) scale(-0.25) level(90)}{p_end}
{phang2}{cmd:. csdlp_diff, at(50 5)}{p_end}
{phang2}{cmd:. csdlp_diff, at(95 50)}{p_end}
{phang2}{cmd:. csdlp_agg L.capital, horizon(0)}{p_end}
{phang2}{cmd:. matrix list r(agg)}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane, {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com},
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
