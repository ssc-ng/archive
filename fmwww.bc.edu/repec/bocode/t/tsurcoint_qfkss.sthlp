{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_qfkss##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_qfkss##description"}{...}
{viewerjumpto "Options" "tsurcoint_qfkss##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_qfkss##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_qfkss##results"}{...}
{viewerjumpto "Examples" "tsurcoint_qfkss##examples"}{...}
{viewerjumpto "References" "tsurcoint_qfkss##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {bf:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint qfkss} {hline 2} Quantile Fourier KSS unit-root test (Bahmani-Oskooee, Chang, Niroomand and Ranjbar 2020)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint qfkss} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt tau(numlist)}}quantiles in (0,1); default {cmd:0.25 0.5 0.75}{p_end}
{synopt:{opt l:ags(#)}}number of lagged differences (fixed); default {cmd:8}{p_end}
{synopt:{opt fr:eq(#)}}Fourier frequency k (fixed, as in GAUSS); default {cmd:3}{p_end}
{synopt:{opt boot:strap(#)}}residual-bootstrap critical values for the first quantile in {cmd:tau()}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
As {helpb tsurcoint_qkss:tsurcoint qkss}, with sin(2 pi k t/T) and cos(2 pi k t/T) added to the quantile regression so that
smooth structural breaks are allowed. Port of GAUSS {cmd:QR_Fourier_KSS} and {cmd:QR_Fourier_KSS_bootstrap}
(tspdlib 3.0.0); the statistics are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Quantile regressions.} The quantile regressions are solved with the interior-point (Frisch-Newton) algorithm of the GAUSS routine {cmd:quantileFit} (tolerance 1e-4, at most 50 iterations), ported to Mata. This is what makes the results identical to GAUSS: an exact simplex solver such as {helpb qreg} returns slightly different coefficients and residual signs, which changes delta^2 and the critical values.

{pstd}{bf:Bootstrap quantiles.} GAUSS reports the 99th, 95th and 90th percentiles of the bootstrap distribution; the test is
left-tailed, so {cmd:tsurcoint} reports the 1st, 5th and 10th percentiles.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(rho)}}statistic and rho(tau) at the first quantile{p_end}
{synopt:{cmd:r(results)}}matrix: tau, rho(tau), delta^2, t_n(tau) for every quantile{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}bootstrap critical values (with {cmd:bootstrap()}){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint qfkss ln_inv, freq(1) lags(4)}{p_end}
{phang2}{cmd:. tsurcoint qfkss ln_inv, tau(0.5) freq(1) lags(4) bootstrap(199) seed(12)}{p_end}

{marker references}{...}
{title:References}

{phang}Bahmani-Oskooee, M., T. Chang, F. Niroomand, and O. Ranjbar. 2020. Fourier nonlinear quantile unit root test and PPP
in Africa. {it:Bulletin of Economic Research} 72: 451-481. {browse "https://doi.org/10.1111/boer.12228":doi:10.1111/boer.12228}{p_end}

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
