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
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_shin##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_shin##description"}{...}
{viewerjumpto "Options" "tsurcoint_shin##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_shin##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_shin##results"}{...}
{viewerjumpto "Examples" "tsurcoint_shin##examples"}{...}
{viewerjumpto "References" "tsurcoint_shin##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {bf:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint shin} {hline 2} Shin (1994) test of the null of cointegration


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint shin} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(none|constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt lrv(name)}}long-run variance: {cmd:iid} (default, as in GAUSS), {cmd:bartlett}, {cmd:qs}, {cmd:spcbartlett}, {cmd:spcqs}, {cmd:kurbartlett}, {cmd:kurqs}{p_end}
{synopt:{opt bw:idth(#)}}bandwidth for {cmd:bartlett}/{cmd:qs}; default round(4(T/100)^(2/9)){p_end}
{synopt:{opt lead:s(#)}}DOLS leads and lags; default int(4(T/100)^(2/9)){p_end}
{synopt:{opt pap:er}}normalise the DOLS statistic by the DOLS sample size (see Remarks){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The cointegrating regression is estimated by OLS and by DOLS with q leads and lags of the differenced regressors; for each
set of residuals C = T^-2 sum_t S_t^2 / omega^2, with S_t the partial sums and omega^2 a long-run variance. H0:
cointegration; large values reject. Critical values of Shin (1994) for k = 1..5. Port of GAUSS {cmd:coint_shin}
(tspdlib 3.0.0); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the paper's formula is available with option {cmd:paper}.

{pstd}(1) GAUSS divides both the OLS and the DOLS statistic by the full T^2, although the DOLS residuals cover only T - 2q - 1 observations. Option {cmd:paper} uses the DOLS sample size for the DOLS statistic; the OLS statistic is unchanged.

{pstd}{bf:Long-run variance.} {cmd:spcbartlett} and {cmd:spcqs} are the AR-prewhitened estimators of Sul, Phillips and Choi (2005) (AR order by BIC up to 8); {cmd:kurbartlett} and {cmd:kurqs} use the Andrews (1991) bandwidth with the Kurozumi (2002) cap at an AR(1) coefficient of 0.7. The GAUSS default is {cmd:iid}, which ignores serial correlation; for applied work a kernel or SPC estimator is advisable.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat_ols)}, {cmd:r(stat_dols)}}statistics{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}Shin (1994) critical values{p_end}
{synopt:{cmd:r(T)}, {cmd:r(k)}, {cmd:r(leads)}, {cmd:r(bwidth)}}settings{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint shin ln_consump ln_inc}{p_end}
{phang2}{cmd:. tsurcoint shin ln_consump ln_inc ln_inv, lrv(spcqs)}{p_end}
{phang2}{cmd:. tsurcoint shin ln_consump ln_inc, model(trend) lrv(bartlett) paper}{p_end}

{marker references}{...}
{title:References}

{phang}Shin, Y. 1994. A residual-based test of the null of cointegration against the alternative of no cointegration.
{it:Econometric Theory} 10: 91-115. {browse "https://doi.org/10.1017/S0266466600008240":doi:10.1017/S0266466600008240}{p_end}
{phang}Sul, D., P. C. B. Phillips, and C.-Y. Choi. 2005. Prewhitening bias in HAC estimation.
{it:Oxford Bulletin of Economics and Statistics} 67: 517-546.{p_end}
{phang}Kurozumi, E. 2002. Testing for stationarity with a break. {it:Journal of Econometrics} 108: 63-99.{p_end}

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
