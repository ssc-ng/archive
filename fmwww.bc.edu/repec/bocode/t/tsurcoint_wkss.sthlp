{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_wkss##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_wkss##description"}{...}
{viewerjumpto "Options" "tsurcoint_wkss##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_wkss##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_wkss##results"}{...}
{viewerjumpto "Examples" "tsurcoint_wkss##examples"}{...}
{viewerjumpto "References" "tsurcoint_wkss##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {bf:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint wkss} {hline 2} Wavelet KSS unit-root test (Aydin 2020)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint wkss} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(none|constant|trend)}}deterministics removed first; default {cmd:constant}{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection; default {cmd:tstat} (general-to-specific, |t| > 1.645){p_end}
{synopt:{opt gauss}}reproduce the GAUSS routine {cmd:WKSS} exactly (see Remarks){p_end}
{synopt:{opt sim:ulate(#)}}Monte Carlo critical values with # replications{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:simulate()} / {cmd:bootstrap()}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The series is demeaned or detrended, transformed by the Haar wavelet into its T/2 scaling coefficients, and the KSS
regression dv_t = delta v^3_{t-1} + lagged dv_t is run on the wavelet coefficients. H0: unit root; H1: nonlinear
(ESTAR) stationarity. Port of GAUSS {cmd:WKSS} (tspdlib 3.0.0).

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS and paper.} The GAUSS routine {cmd:WKSS} computes the wavelet transform but then runs the KSS regression on
the untransformed series, so its result is identical to the ordinary KSS test (and to {helpb kssur}); with
{cmd:model(trend)} it stops with an error (an uninitialized variable). Because the GAUSS result is not a wavelet test,
{cmd:tsurcoint wkss} applies the wavelet transform by default, as described by Aydin (2020); option {cmd:gauss} reproduces
the GAUSS value exactly. This is the only subcommand whose default departs from GAUSS, together with
{helpb tsurcoint_fkss:the bootstrap quantiles}.

{pstd}{bf:Critical values.} GAUSS does not report critical values for this test. Option {cmd:simulate(#)} computes them by Monte Carlo with the design of the GAUSS routine {cmd:_get_cv_Fourier_KSS}: a driftless random walk of the same length, the selected Fourier frequency held fixed, and no augmentation lags. They are random, so set {cmd:seed()} for reproducibility and use at least 5,000 replications for publication.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(lags)}}statistic and selected lags{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}Monte Carlo critical values (with {cmd:simulate()}){p_end}
{synopt:{cmd:r(T)}, {cmd:r(Tw)}}observations and wavelet coefficients{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint wkss ln_inv, simulate(5000) seed(1)}{p_end}
{phang2}{cmd:. tsurcoint wkss ln_inv, model(trend) simulate(5000) seed(1)}{p_end}
{phang2}{cmd:. tsurcoint wkss ln_inv, gauss}{p_end}

{marker references}{...}
{title:References}

{phang}Aydin, M. 2020. A new nonlinear wavelet-based unit root test with structural breaks. MPRA Paper 104291.{p_end}
{phang}Kapetanios, G., Y. Shin, and A. Snell. 2003. Testing for a unit root in the nonlinear STAR framework.
{it:Journal of Econometrics} 112: 359-379.{p_end}

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
