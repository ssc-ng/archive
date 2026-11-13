{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_qkss##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_qkss##description"}{...}
{viewerjumpto "Options" "tsurcoint_qkss##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_qkss##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_qkss##results"}{...}
{viewerjumpto "Examples" "tsurcoint_qkss##examples"}{...}
{viewerjumpto "References" "tsurcoint_qkss##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {bf:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint qkss} {hline 2} Quantile KSS unit-root test (Li and Park 2018)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint qkss} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt tau(numlist)}}quantiles in (0,1); default {cmd:0.25 0.5 0.75}{p_end}
{synopt:{opt l:ags(#)}}number of lagged differences (fixed, as in GAUSS); default {cmd:8}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
For each quantile tau, dy_t is regressed by quantile regression on (1, y^3_{t-1}, lagged dy_t [, t]); the statistic
t_n(tau) = f(tau)/sqrt(tau(1-tau)) {c 183} sqrt(Y'P_X Y) {c 183} rho(tau) uses the sparsity f(tau) estimated from the
quantile regressions at tau +- h (Hall-Sheather bandwidth, then Bofinger). H0: unit root at quantile tau.
Critical values are those of Li and Park (2018), interpolated in the nuisance parameter delta^2. Port of GAUSS
{cmd:QR_KSS} (tspdlib 3.0.0); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Quantile regressions.} The quantile regressions are solved with the interior-point (Frisch-Newton) algorithm of the GAUSS routine {cmd:quantileFit} (tolerance 1e-4, at most 50 iterations), ported to Mata. This is what makes the results identical to GAUSS: an exact simplex solver such as {helpb qreg} returns slightly different coefficients and residual signs, which changes delta^2 and the critical values.

{pstd}The global quantile Kolmogorov-Smirnov test over many quantiles is {helpb tsurcoint_qks:tsurcoint qks}.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(rho)}}statistic and rho(tau) at the first quantile{p_end}
{synopt:{cmd:r(results)}}matrix: tau, rho(tau), delta^2, t_n(tau), cv 1%, 5%, 10% for every quantile{p_end}
{synopt:{cmd:r(T)}, {cmd:r(lags)}}settings{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint qkss ln_inv}{p_end}
{phang2}{cmd:. tsurcoint qkss ln_inv, tau(0.1(0.1)0.9) lags(4) model(trend)}{p_end}

{marker references}{...}
{title:References}

{phang}Li, H., and S. Y. Park. 2018. Testing for a unit root in a nonlinear quantile autoregression framework.
{it:Econometric Reviews} 37: 867-892. {browse "https://doi.org/10.1080/07474938.2016.1222225":doi:10.1080/07474938.2016.1222225}{p_end}
{phang}Koenker, R., and Z. Xiao. 2004. Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99: 775-787.{p_end}

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
