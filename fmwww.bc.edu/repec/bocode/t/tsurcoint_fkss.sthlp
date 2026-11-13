{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint" "help tsurcoint"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
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
{viewerjumpto "Syntax" "tsurcoint_fkss##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_fkss##description"}{...}
{viewerjumpto "Options" "tsurcoint_fkss##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_fkss##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_fkss##results"}{...}
{viewerjumpto "Examples" "tsurcoint_fkss##examples"}{...}
{viewerjumpto "References" "tsurcoint_fkss##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {bf:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint fkss} {hline 2} Fourier KSS (and Fourier ADF) unit-root test of Christopoulos and Leon-Ledesma (2010)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint fkss} {varname} {ifin} [{cmd:,} {it:options}]{p_end}
{p 8 17 2}{cmd:tsurcoint fadf} {varname} ... {space 3}(shortcut for {cmd:fkss, adf}){p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection; default {cmd:tstat} (general-to-specific, |t| > 1.645){p_end}
{synopt:{opt fm:ax(#)}}maximum Fourier frequency (1-5); default {cmd:5}{p_end}
{synopt:{opt adf}}Fourier ADF on the Fourier residuals instead of the KSS regression{p_end}
{synopt:{opt sim:ulate(#)}}Monte Carlo critical values with # replications{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:simulate()} / {cmd:bootstrap()}{p_end}
{synopt:{opt boot:strap(#)}}residual-bootstrap critical values (GAUSS {cmd:Fourier_KSS_bootstrap}){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The series is regressed on a constant [and trend] and one pair of Fourier terms sin(2 pi k t/T), cos(2 pi k t/T), with
the frequency k* in 1..fmax chosen by minimum SSR. The residuals v_t are tested with the KSS regression
dv_t = delta v^3_{t-1} + lagged dv_t (or, with {cmd:adf}, with v_{t-1} in place of v^3_{t-1}). H0: unit root;
H1: globally stationary ESTAR with smooth breaks. The command also reports the F test for the Fourier terms.
Port of GAUSS {cmd:Fourier_KSS} and {cmd:Fourier_KSS_bootstrap} (tspdlib 3.0.0); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker options}{...}
{title:Options}

{phang}{opt bootstrap(#)} rebuilds random walks from the centred AR(1) residuals of the Fourier-detrended differences and
recomputes the whole statistic (including the choice of k* and of the lags) on every replication.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Critical values.} GAUSS does not report critical values for this test. Option {cmd:simulate(#)} computes them by Monte Carlo with the design of the GAUSS routine {cmd:_get_cv_Fourier_KSS}: a driftless random walk of the same length, the selected Fourier frequency held fixed, and no augmentation lags. They are random, so set {cmd:seed()} for reproducibility and use at least 5,000 replications for publication.

{pstd}{bf:Bootstrap quantiles.} The GAUSS routine sorts the bootstrap statistics in ascending order and reports the
99th, 95th and 90th percentiles; because the test is left-tailed, {cmd:tsurcoint} reports the 1st, 5th and 10th percentiles
(the bootstrap is random, so its values can never be identical to GAUSS anyway).

{pstd}{bf:Related commands.} The Fourier ADF of Enders and Lee (2012) is {helpb fourierdf} and the RALS Fourier KSS is
{helpb ralsfkss}; the plain KSS test is {helpb kssur}.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(stat)}, {cmd:r(lags)}, {cmd:r(freq)}}statistic, lags and Fourier frequency k*{p_end}
{synopt:{cmd:r(F_fourier)}, {cmd:r(p_F_fourier)}}F test of the Fourier terms (standard F p-value){p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}critical values (with {cmd:simulate()} or {cmd:bootstrap()}){p_end}
{synopt:{cmd:r(T)}, {cmd:r(pmax)}}settings{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint fkss ln_inv}{p_end}
{phang2}{cmd:. tsurcoint fkss ln_inv, model(trend) simulate(5000) seed(123)}{p_end}
{phang2}{cmd:. tsurcoint fkss ln_inv, bootstrap(499) seed(123)}{p_end}
{phang2}{cmd:. tsurcoint fadf ln_inv, pmax(4) ic(aic)}{p_end}

{marker references}{...}
{title:References}

{phang}Christopoulos, D. K., and M. A. Leon-Ledesma. 2010. Smooth breaks and non-linear mean reversion: Post-Bretton Woods
real exchange rates. {it:Journal of International Money and Finance} 29: 1076-1093.
{browse "https://doi.org/10.1016/j.jimonfin.2010.02.003":doi:10.1016/j.jimonfin.2010.02.003}{p_end}
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
