{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_cissanso##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_cissanso##description"}{...}
{viewerjumpto "Options" "tsurcoint_cissanso##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_cissanso##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_cissanso##results"}{...}
{viewerjumpto "Examples" "tsurcoint_cissanso##examples"}{...}
{viewerjumpto "References" "tsurcoint_cissanso##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {bf:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint cissanso} {hline 2} Carrion-i-Silvestre and Sanso (2006) test of the null of cointegration with a structural break


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint cissanso} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(name)}}{cmd:an} level shift (default), {cmd:a} level shift with trend, {cmd:d} regime shift, {cmd:e} regime and trend shift{p_end}
{synopt:{opt trim(#)}}trimming of the break search; default {cmd:0.10}{p_end}
{synopt:{opt lrv(name)}}long-run variance: {cmd:iid} (default, as in GAUSS), {cmd:bartlett}, {cmd:qs}, {cmd:spcbartlett}, {cmd:spcqs}, {cmd:kurbartlett}, {cmd:kurqs}{p_end}
{synopt:{opt bw:idth(#)}}bandwidth for {cmd:bartlett}/{cmd:qs}; default round(4(T/100)^(2/9)){p_end}
{synopt:{opt lead:s(#)}}DOLS leads and lags; default int(4(T/100)^(2/9)){p_end}
{synopt:{opt pap:er}}normalise the DOLS statistic by the DOLS sample size (see Remarks){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The KPSS-type statistic of Shin (1994) is computed from the OLS and the DOLS residuals of a cointegrating regression with a
dummy for a structural break at an unknown date; the break is the date that minimizes the SSR, separately for OLS and DOLS.
H0: cointegration with a break; large values reject. Critical values of Carrion-i-Silvestre and Sanso (2006), k = 1..4,
at the DOLS break fraction (used for both statistics, as in GAUSS). Port of GAUSS {cmd:coint_cissanso} (tspdlib 3.0.0;
same test as {cmd:coi_end} in carrionlib); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the paper's formula is available with option {cmd:paper}.

{pstd}(1) GAUSS divides both the OLS and the DOLS statistic by the full T^2, although the DOLS residuals cover only T - 2q - 1 observations. Option {cmd:paper} uses the DOLS sample size for the DOLS statistic; the OLS statistic is unchanged.

{pstd}(2) In the GAUSS table for model An with k = 4 the 1% critical value at lambda = 0.5 is 0.350, while the rest of the row runs
from 0.1754 down to 0.1365; it is probably 0.1350. It is reproduced as in GAUSS.

{pstd}{bf:Long-run variance.} {cmd:spcbartlett} and {cmd:spcqs} are the AR-prewhitened estimators of Sul, Phillips and Choi (2005) (AR order by BIC up to 8); {cmd:kurbartlett} and {cmd:kurqs} use the Andrews (1991) bandwidth with the Kurozumi (2002) cap at an AR(1) coefficient of 0.7. The GAUSS default is {cmd:iid}, which ignores serial correlation; for applied work a kernel or SPC estimator is advisable.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat_ols)}, {cmd:r(stat_dols)}}statistics{p_end}
{synopt:{cmd:r(break_ols)}, {cmd:r(break_dols)}, {cmd:r(lambda_ols)}, {cmd:r(lambda_dols)}}break dates and fractions{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}critical values{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint cissanso ln_consump ln_inc}{p_end}
{phang2}{cmd:. tsurcoint cissanso ln_consump ln_inc, model(e) lrv(bartlett) trim(0.15)}{p_end}

{marker references}{...}
{title:References}

{phang}Carrion-i-Silvestre, J. L., and A. Sanso. 2006. Testing the null of cointegration with structural breaks.
{it:Oxford Bulletin of Economics and Statistics} 68: 623-646. {browse "https://doi.org/10.1111/j.1468-0084.2006.00180.x":doi:10.1111/j.1468-0084.2006.00180.x}{p_end}
{phang}Carrion-i-Silvestre, J. L., and A. Sanso. 2006. A guide to the computation of stationarity tests.
{it:Empirical Economics} 31: 433-448.{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
{help tsurcoint:tsurcoint} (overview, list of all tests, map of the GAUSS libraries){break}
Nonlinear / Fourier / wavelet: {help tsurcoint_fkss:fkss}, {help tsurcoint_wkss:wkss}, {help tsurcoint_fwkss:fwkss}, {help tsurcoint_fwadf:fwadf}{break}
Quantile: {help tsurcoint_qkss:qkss}, {help tsurcoint_qfkss:qfkss}, {help tsurcoint_qks:qks}{break}
Breaks: {help tsurcoint_glsbreak:glsbreak}{break}
Cointegration: {help tsurcoint_shin:shin}, {help tsurcoint_cissanso:cissanso}{break}
Panel data: {help xturcoint:xturcoint}
{p_end}
