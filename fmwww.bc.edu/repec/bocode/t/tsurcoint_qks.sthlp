{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_qks##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_qks##description"}{...}
{viewerjumpto "Options" "tsurcoint_qks##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_qks##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_qks##results"}{...}
{viewerjumpto "Examples" "tsurcoint_qks##examples"}{...}
{viewerjumpto "References" "tsurcoint_qks##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {bf:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint qks} {hline 2} Quantile Kolmogorov-Smirnov unit-root tests (four variants)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint qks} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt test:type(name)}}{cmd:adf} (Koenker-Xiao 2004), {cmd:fadf} (Li-Zheng 2018), {cmd:kss} (Li-Park 2018, default), {cmd:fkss} (Bahmani-Oskooee et al. 2020){p_end}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt l:ags(#)}}lagged differences (maximum for {cmd:adf}, fixed otherwise); default {cmd:8}{p_end}
{synopt:{opt fr:eq(#)}}Fourier frequency for {cmd:fadf}/{cmd:fkss}; default {cmd:3}{p_end}
{synopt:{opt boot:strap(#)}}residual-bootstrap critical values (GAUSS {cmd:QKS_bootstrap}){p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
QKS = max_tau |t_n(tau)| over tau = 0.10, 0.11, ..., 0.69, the grid produced by the GAUSS loop {cmd:for quantil(0.1, 0.7, 0.01)}.
The quantile statistic t_n(tau) is that of the chosen test. H0: unit root at every quantile; the test is right-tailed.
Port of GAUSS {cmd:qks_tests} and {cmd:QKS_bootstrap} (tspdlib 3.0.0); QKS and the maximizing quantile are identical to GAUSS.
For {cmd:testtype(adf)} the lag is chosen first by the ADF t-sig rule with a constant, as in GAUSS {cmd:quantileADF}.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Quantile regressions.} The quantile regressions are solved with the interior-point (Frisch-Newton) algorithm of the GAUSS routine {cmd:quantileFit} (tolerance 1e-4, at most 50 iterations), ported to Mata. This is what makes the results identical to GAUSS: an exact simplex solver such as {helpb qreg} returns slightly different coefficients and residual signs, which changes delta^2 and the critical values.

{pstd}The bootstrap re-estimates the 180 quantile regressions on every replication; 200-500 replications take a few
minutes. The QKS test for the QADF statistic over a user-chosen grid is also available in {helpb qadf_process}
(package {cmd:qadf}).

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(qks)}, {cmd:r(tau_star)}}QKS statistic and maximizing quantile{p_end}
{synopt:{cmd:r(process)}}matrix: tau, rho(tau), delta^2, t_n(tau) for the 60 quantiles{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}bootstrap critical values (with {cmd:bootstrap()}){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint qks ln_inv, testtype(kss) lags(2)}{p_end}
{phang2}{cmd:. tsurcoint qks ln_inv, testtype(fkss) freq(1) lags(2) model(trend)}{p_end}
{phang2}{cmd:. tsurcoint qks ln_inv, testtype(adf) lags(4) bootstrap(199) seed(1)}{p_end}

{marker references}{...}
{title:References}

{phang}Koenker, R., and Z. Xiao. 2004. {it:Journal of the American Statistical Association} 99: 775-787.
{browse "https://doi.org/10.1198/016214504000001114":doi:10.1198/016214504000001114}{p_end}
{phang}Li, H., and C. Zheng. 2018. Unit root quantile autoregression testing with smooth structural changes.
{it:Finance Research Letters} 25: 83-89.{p_end}
{phang}Li, H., and S. Y. Park. 2018. {it:Econometric Reviews} 37: 867-892.{p_end}
{phang}Bahmani-Oskooee, M., T. Chang, F. Niroomand, and O. Ranjbar. 2020. {it:Bulletin of Economic Research} 72: 451-481.{p_end}

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
