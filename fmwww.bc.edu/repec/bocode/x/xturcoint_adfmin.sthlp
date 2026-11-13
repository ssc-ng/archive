{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_adfmin##syntax"}{...}
{viewerjumpto "Description" "xturcoint_adfmin##description"}{...}
{viewerjumpto "Options" "xturcoint_adfmin##options"}{...}
{viewerjumpto "Remarks" "xturcoint_adfmin##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_adfmin##results"}{...}
{viewerjumpto "Examples" "xturcoint_adfmin##examples"}{...}
{viewerjumpto "References" "xturcoint_adfmin##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {bf:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint adfmin} {hline 2} Westerlund (2006) panel cointegration tests allowing for a level break


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint adfmin} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}level break in the constant (default) or with a trend{p_end}
{synopt:{opt l:ags(#)}}p: Bartlett bandwidth of the Z tests and p-1 lagged differences of the ADF tests; default {cmd:1}{p_end}
{synopt:{opt trim(#)}}trimming of the break search; default {cmd:0.10}{p_end}
{synopt:{opt gauss:firstx}}use only the first regressor in the residual regression, as the GAUSS code does{p_end}
{synopt:{opt notab:le}}suppress the break-date table{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
For each unit and each candidate break date Tb in [trim*T, (1-trim)*T] the residuals of y on
(1, DU(Tb), [t], x) are tested for a unit root with the semiparametric Phillips Z_tau and Z_rho tests and with the
parametric ADF_tau and ADF_rho tests; each unit keeps the minimum over Tb (a Gregory-Hansen-type search). The panel
statistics are the standardized averages of the unit minima, N(0,1) under H0 (no cointegration), left-tailed.
This is a port of the GAUSS procedure {cmd:adfmin_west} (westerlundlib, adfmin.src); results are identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS convention.} The GAUSS code uses only the first regressor of every unit in the residual regression,
although the moments are taken for k regressors. With one regressor this is irrelevant. With k > 1
{cmd:xturcoint adfmin} uses all regressors (the model of the paper); option {cmd:gaussfirstx} reproduces the GAUSS
behaviour exactly. At most 5 regressors are allowed (moment table).

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(Z_tau)}, {cmd:r(Z_rho)}, {cmd:r(ADF_tau)}, {cmd:r(ADF_rho)}}panel statistics{p_end}
{synopt:{cmd:r(p_Z_tau)}, ... , {cmd:r(p_ADF_rho)}}left-tailed p-values{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}, {cmd:r(k)}, {cmd:r(lags)}, {cmd:r(trim)}}settings{p_end}
{synopt:{cmd:r(stat)}, {cmd:r(pvalue)}}1 x 4 matrices{p_end}
{synopt:{cmd:r(breakobs)}, {cmd:r(breakdate)}}N x 4 break observation index and break date (time units){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse xtcoint, clear}{p_end}
{phang2}{cmd:. xturcoint adfmin productivity rddomestic}{p_end}
{phang2}{cmd:. xturcoint adfmin productivity rddomestic rdforeign, model(trend) lags(2) trim(0.15)}{p_end}

{marker references}{...}
{title:References}

{phang}Westerlund, J. 2006. Testing for panel cointegration with a level break.
{it:Economics Letters} 91: 27-33. {browse "https://doi.org/10.1016/j.econlet.2005.10.007":doi:10.1016/j.econlet.2005.10.007}{p_end}

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
