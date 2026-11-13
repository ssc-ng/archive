{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_cusum##syntax"}{...}
{viewerjumpto "Description" "xturcoint_cusum##description"}{...}
{viewerjumpto "Options" "xturcoint_cusum##options"}{...}
{viewerjumpto "Remarks" "xturcoint_cusum##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_cusum##results"}{...}
{viewerjumpto "Examples" "xturcoint_cusum##examples"}{...}
{viewerjumpto "References" "xturcoint_cusum##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {bf:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint cusum} {hline 2} Westerlund (2005) panel CUSUM test of the null of cointegration


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint cusum} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(none|constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt est:imator(dols|fmols)}}estimator of the cointegrating vector; default {cmd:dols}{p_end}
{synopt:{opt l:ags(#)}}DOLS leads/lags p; default {cmd:2}{p_end}
{synopt:{opt bw:idth(#)}}Bartlett bandwidth for FMOLS and the CUSUM long-run variance; default int(T^(1/3)){p_end}
{synopt:{opt notab:le}}suppress the unit-specific table{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
For each unit the cointegrating regression is estimated by DOLS or FMOLS and the CUSUM statistic

{p 8 8 2}CUSUM_i = max_t |S_it| / sqrt(T s_i^2), S_it = partial sums of the residuals, s_i^2 = Bartlett long-run variance,

{pstd}
is computed. The panel statistic Z = sqrt(N)(mean CUSUM_i - mu)/sqrt(var) is N(0,1) under H0 (all panels are
cointegrated) and rejects for large positive values (right tail). mu and var are Westerlund's simulated moments
(k = 1,...,5 regressors). This is a port of the GAUSS procedure {cmd:cusum_panel} (westerlundlib, cusum_west.src);
results are identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker remarks}{...}
{title:Remarks}

{pstd}The GAUSS procedure reads the number of regressors and the bandwidth from {it:global} symbols; here they are taken
from the varlist and {cmd:bwidth()}. The DOLS lead/lag window is the one coded by Westerlund in {cmd:dols}. When the
lead/lag matrix is rank-deficient (many regressors, short T) the projection uses a generalized inverse, which is
unique; GAUSS {cmd:inv()} returns numerically arbitrary values in that case.

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(Z)}, {cmd:r(p)}}panel statistic and right-tailed p-value{p_end}
{synopt:{cmd:r(mu)}, {cmd:r(var)}}moments used{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}, {cmd:r(k)}, {cmd:r(lags)}, {cmd:r(bwidth)}}settings{p_end}
{synopt:{cmd:r(cusum)}}N x 1 unit-specific CUSUM statistics{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse xtcoint, clear}{p_end}
{phang2}{cmd:. xturcoint cusum productivity rddomestic rdforeign}{p_end}
{phang2}{cmd:. xturcoint cusum productivity rddomestic rdforeign, estimator(fmols) model(trend)}{p_end}

{marker references}{...}
{title:References}

{phang}Westerlund, J. 2005. A panel CUSUM test of the null of cointegration.
{it:Oxford Bulletin of Economics and Statistics} 67: 231-262. {browse "https://doi.org/10.1111/j.1468-0084.2004.00118.x":doi:10.1111/j.1468-0084.2004.00118.x}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
{help xturcoint:xturcoint} (overview, list of all tests, map of the GAUSS libraries){break}
Unit root: {help xturcoint_lm:xturcoint lm}, {help xturcoint_fixedt:xturcoint fixedt}, {help xturcoint_mp:xturcoint mp}, {help xturcoint_panic:xturcoint panic}{break}
Pre-test: {help xturcoint_cd:xturcoint cd}{break}
Cointegration: {help xturcoint_cusum:xturcoint cusum}, {help xturcoint_adfmin:xturcoint adfmin}
{p_end}
