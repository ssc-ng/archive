{smcl}
{* *! version 1.0.0  09nov2026}{...}
{vieweralsosee "csdlp" "help csdlp"}{...}
{vieweralsosee "csdlp postestimation" "help csdlp_postestimation"}{...}
{vieweralsosee "csdlp methods" "help csdlp_methods"}{...}
{title:Title}

{phang}
{bf:csdlp_graph} {hline 2} Graphs after {helpb csdlp}


{title:Syntax}

{p 8 16 2}
{cmd:csdlp_graph} [{cmd:,} {opth h:orizons(numlist)} {opt nolin:ear}
{opt point:wise} {opt lem:ma} {opt surf:ace} {opt nocomb:ine} {opt cols(#)}
{opt xt:itle(string)} {opt yt:itle(string)} {opt name(string)}
{opt sav:ing(filename)}]


{title:Description}

{pstd}
Default: one panel per horizon, in the style of Figure 3 of David, Giacomini,
Jiao and Wang (2026). Each panel shows the sieve IRF g_h(z), the
{cmd:e(level)}% and {cmd:e(level2)}% studentized uniform bands, and the
linear-interaction LP as a dashed line. If more than four horizons were
estimated, four evenly spaced ones are shown unless {opt horizons()} is given.
Panels are combined with {cmd:grc1leg2} or {cmd:grc1leg} if installed, and
with {cmd:graph combine} otherwise.

{phang}
{opt pointwise} adds the pointwise interval (eq. 18) as dotted lines.

{phang}
{opt lemma} draws, for the first selected horizon, the local slope g_h'(z) and
the Lemma 1 weight omega_h(z). The linear-interaction slope equals
integral omega_h(z) g_h'(z) dz (Proposition 2), so the plot shows which slopes
the linear coefficient averages.

{phang}
{opt surface} draws a contour plot of g_h(z) over (z, h) with a Parula-type
colour scale (requires two or more horizons).

{phang}
{opt saving(file)} exports PNG files: {it:file}{cmd:.png}, {it:file}{cmd:_lemma.png}
or {it:file}{cmd:_surface.png}.


{title:Examples}

{phang2}{cmd:. csdlp_graph, horizons(0 4 8 12)}{p_end}
{phang2}{cmd:. csdlp_graph, horizons(4) pointwise}{p_end}
{phang2}{cmd:. csdlp_graph, lemma}{p_end}
{phang2}{cmd:. csdlp_graph, surface saving(irf)}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane, {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com},
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
