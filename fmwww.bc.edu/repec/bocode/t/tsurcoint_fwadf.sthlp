{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_fwadf##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_fwadf##description"}{...}
{viewerjumpto "Options" "tsurcoint_fwadf##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_fwadf##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_fwadf##results"}{...}
{viewerjumpto "Examples" "tsurcoint_fwadf##examples"}{...}
{viewerjumpto "References" "tsurcoint_fwadf##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {bf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint fwadf} {hline 2} Fourier wavelet ADF unit-root test (Aydin and Pata 2020)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint fwadf} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection; default {cmd:tstat} (general-to-specific, |t| > 1.645){p_end}
{synopt:{opt fm:ax(#)}}maximum Fourier frequency (1-5); default {cmd:5}{p_end}
{synopt:{opt pap:er}}AIC/BIC penalize the number of regressors (see Remarks){p_end}
{synopt:{opt sim:ulate(#)}}Monte Carlo critical values with # replications{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:simulate()} / {cmd:bootstrap()}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The Haar wavelet transform of the series is tested with the Fourier ADF regression
dy_t = rho y_{t-1} + c [+ b t] + gamma sin(2 pi k t/T) + lagged dy_t, searching k = 1..fmax by minimum SSR. As in the GAUSS
code, only the sine term enters in the wavelet version. Port of GAUSS {cmd:fourier_wadf} (tspdlib 3.0.0, calling
{cmd:Fourier_ADF} with the wavelet switch); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the paper's formula is available with option {cmd:paper}.

{pstd}In the GAUSS helper {cmd:_runFourierOLS} the AIC and BIC are computed as (2k - 2LL)/n and (k ln n - 2LL)/n with k equal
to the {it:Fourier frequency}, not to the number of regressors, so within a frequency the criteria do not penalize
additional lags and select the largest lag. Option {cmd:paper} uses the number of regressors. The t-sig rule
({cmd:ic(tstat)}, the default) is not affected.

{pstd}{bf:Critical values.} GAUSS does not report critical values for this test. Option {cmd:simulate(#)} computes them by Monte Carlo with the design of the GAUSS routine {cmd:_get_cv_Fourier_KSS}: a driftless random walk of the same length, the selected Fourier frequency held fixed, and no augmentation lags. They are random, so set {cmd:seed()} for reproducibility and use at least 5,000 replications for publication.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(lags)}, {cmd:r(freq)}}statistic, lags and frequency{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}Monte Carlo critical values (with {cmd:simulate()}){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint fwadf ln_inv, simulate(5000) seed(1)}{p_end}
{phang2}{cmd:. tsurcoint fwadf ln_inv, model(trend) ic(aic) paper}{p_end}

{marker references}{...}
{title:References}

{phang}Aydin, M., and U. K. Pata. 2020. Are shocks to disaggregated renewable energy consumption permanent or temporary for
the USA? Wavelet based unit root test with smooth structural shifts. {it:Energy} 207: 118245.
{browse "https://doi.org/10.1016/j.energy.2020.118245":doi:10.1016/j.energy.2020.118245}{p_end}
{phang}Enders, W., and J. Lee. 2012. The flexible Fourier form and Dickey-Fuller type unit root tests.
{it:Economics Letters} 117: 196-199.{p_end}

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
