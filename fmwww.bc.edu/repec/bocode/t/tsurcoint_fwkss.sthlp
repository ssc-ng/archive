{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_fwkss##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_fwkss##description"}{...}
{viewerjumpto "Options" "tsurcoint_fwkss##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_fwkss##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_fwkss##results"}{...}
{viewerjumpto "Examples" "tsurcoint_fwkss##examples"}{...}
{viewerjumpto "References" "tsurcoint_fwkss##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {bf:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint fwkss} {hline 2} Fourier wavelet KSS unit-root test (Aydin 2020)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint fwkss} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection; default {cmd:tstat} (general-to-specific, |t| > 1.645){p_end}
{synopt:{opt fm:ax(#)}}maximum Fourier frequency (1-5); default {cmd:5}{p_end}
{synopt:{opt sim:ulate(#)}}Monte Carlo critical values with # replications{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:simulate()} / {cmd:bootstrap()}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The Haar wavelet transform (T/2 scaling coefficients) of the series is computed first; the Fourier KSS test of
{helpb tsurcoint_fkss:tsurcoint fkss} is then applied to the wavelet coefficients. It combines smooth breaks (Fourier
terms), nonlinear adjustment (ESTAR) and the noise reduction of the wavelet filter. Port of GAUSS {cmd:Fourier_WKSS}
(tspdlib 3.0.0); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Critical values.} GAUSS does not report critical values for this test. Option {cmd:simulate(#)} computes them by Monte Carlo with the design of the GAUSS routine {cmd:_get_cv_Fourier_KSS}: a driftless random walk of the same length, the selected Fourier frequency held fixed, and no augmentation lags. They are random, so set {cmd:seed()} for reproducibility and use at least 5,000 replications for publication.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(lags)}, {cmd:r(freq)}}statistic, lags and frequency{p_end}
{synopt:{cmd:r(F_fourier)}, {cmd:r(p_F_fourier)}}F test of the Fourier terms on the wavelet coefficients{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}Monte Carlo critical values (with {cmd:simulate()}){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint fwkss ln_inv, simulate(5000) seed(1)}{p_end}
{phang2}{cmd:. tsurcoint fwkss ln_inv, model(trend) pmax(4) fmax(3) ic(bic)}{p_end}

{marker references}{...}
{title:References}

{phang}Aydin, M. 2020. A new nonlinear wavelet-based unit root test with structural breaks. MPRA Paper 104291.{p_end}
{phang}Christopoulos, D. K., and M. A. Leon-Ledesma. 2010. {it:Journal of International Money and Finance} 29: 1076-1093.{p_end}

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
