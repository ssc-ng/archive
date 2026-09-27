{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol table" "help cointvol_table"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol vecmgarch" "help cointvol_vecmgarch"}{...}
{viewerjumpto "Syntax" "cointvol_graph##syntax"}{...}
{viewerjumpto "Description" "cointvol_graph##description"}{...}
{viewerjumpto "Examples" "cointvol_graph##examples"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:cointvol graph} {hline 2}}Publication graphs from cointvol results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cointvol graph} {cmd:bootdist} [{cmd:,} {opt stat:istic(trace|maxeig|lr|wald)} {it:common}]

{p 8 16 2}
{cmd:cointvol graph} {cmd:ic} [{cmd:,} {opt ic(bic|hqc|aic)} {it:common}]

{p 8 16 2}
{cmd:cointvol graph} {c -(}{cmd:ect}|{cmd:volatility}|{cmd:correlation}{c )-} [{cmd:,} {it:common}]

{p 8 16 2}
{cmd:cointvol graph} {cmd:varprofile} {varlist} {ifin}{cmd:,} {opt l:ags(#)} [{opt tr:end()} {opt rank(#)} {it:common}]

{p 4 4 2}
{it:common} options: {opt name(name)} graph name; {opt saving(filename)} export
(.png, .pdf, .svg, .eps); {opt mono} black-and-white print version.


{marker description}{...}
{title:Description}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:bootdist}}bootstrap distribution of each rank statistic with the
observed statistic and its bootstrap p-value (run right after
{helpb cointvol_rank:cointvol rank} with a bootstrap method), or of the PLR /
Wald statistic after {helpb cointvol_restrict:cointvol restrict}{p_end}
{p2col:{cmd:ic}}information criterion by lag order for each rank (after
{helpb cointvol_select:cointvol select}); the minimum gives the joint (k, r)
choice of Cavaliere et al. (2018){p_end}
{p2col:{cmd:ect}}estimated error-correction terms (after
{helpb cointvol_vecmgarch:cointvol vecmgarch} or {cmd:cointvol restrict}){p_end}
{p2col:{cmd:volatility}}conditional standard deviations (after {cmd:cointvol vecmgarch}){p_end}
{p2col:{cmd:correlation}}conditional correlations (after {cmd:cointvol vecmgarch}){p_end}
{p2col:{cmd:varprofile}}variance profiles of VECM residuals against the
45-degree line (Cavaliere, Rahbek and Taylor 2010); a profile far from the line
signals nonstationary volatility{p_end}
{p2colreset}{...}

{pstd}
Graphs use a white background and a soft palette; {opt mono} gives a
grey-scale version for print.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse balance2, clear}{p_end}
{phang2}{cmd:. cointvol rank y i c, lags(2) trend(rconstant) method(wild) reps(999) seed(1)}{p_end}
{phang2}{cmd:. cointvol graph bootdist, saving(bootdist.png)}{p_end}
{phang2}{cmd:. cointvol select y i c, maxlag(4) trend(rconstant)}{p_end}
{phang2}{cmd:. cointvol graph ic}{p_end}
{phang2}{cmd:. cointvol graph varprofile y i c, lags(2) rank(1)}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
