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
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{viewerjumpto "Syntax" "tsurcoint_glsbreak##syntax"}{...}
{viewerjumpto "Description" "tsurcoint_glsbreak##description"}{...}
{viewerjumpto "Options" "tsurcoint_glsbreak##options"}{...}
{viewerjumpto "Remarks" "tsurcoint_glsbreak##remarks"}{...}
{viewerjumpto "Stored results" "tsurcoint_glsbreak##results"}{...}
{viewerjumpto "Examples" "tsurcoint_glsbreak##examples"}{...}
{viewerjumpto "References" "tsurcoint_glsbreak##references"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {help tsurcoint:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {bf:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint glsbreak} {hline 2} GLS unit-root tests with one or two structural breaks (Perron-Rodriguez 2003; Carrion-i-Silvestre, Kim and Perron 2009)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:tsurcoint glsbreak} {varname} {ifin} [{cmd:,} {it:options}]{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(level|trend|both)}}break in the level, in the trend slope, or in both (default){p_end}
{synopt:{opt br:eaks(#)}}1 (default) or 2 breaks{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection; default {cmd:tstat} (general-to-specific, |t| > 1.645){p_end}
{synopt:{opt pap:er}}Ng-Perron (2001) autoregressive spectral variance (see Remarks){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
For every candidate break date (or pair of dates) the series is GLS-detrended with the non-centrality parameter c-bar
(-13.5 for level shifts; the Carrion-i-Silvestre, Kim and Perron (2009) response surface otherwise); the break is the date
that minimizes the SSR of the GLS-detrending regression. Six tests are computed at that date: ADF-GLS, the feasible
point-optimal PT, and the modified tests MZa, MZt, MSB and MPT of Ng and Perron (2001). All reject for small values.
Port of GAUSS {cmd:gls_1break} and {cmd:GLS_2breaks} (tspdlib 3.0.0); results are identical to GAUSS.

{pstd}
The data must be {helpb tsset} as a single time series (not a panel); the estimation sample must be contiguous.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the paper's formula is available with option {cmd:paper}.

{pstd}(1) In the GAUSS routine {cmd:_get_s2ar} the expression {cmd:sumc(b[2:cols(b)])} is applied to a column vector, so it sums
b[2] and b[1] (the coefficient of e_{t-1} and the first lagged difference); the denominator is not squared, and one lag is
used when no lag is selected. Ng and Perron (2001) define s2_AR = s2_ek/(1 - sum of the lag coefficients)^2. Option
{cmd:paper} uses this definition.{p_end}
{pstd}(2) GAUSS reports the lag and s2_AR of the {it:last} candidate break date; with {cmd:paper} they are those of the selected
date. The ADF-GLS statistic is the same in both modes.{p_end}
{pstd}(3) For two breaks that fall in the same decile the GAUSS critical-value table has no entry (it returns zeros);
these are shown as n.a.{p_end}

{pstd}{bf:Related commands.} {helpb ckptest} and {helpb tsadvroot} {cmd:cisur} implement Carrion-i-Silvestre, Kim and Perron (2009)
with up to five breaks in level and slope (GAUSS {cmd:msbur}/{cmd:sbur_gls}); {cmd:tsurcoint glsbreak} adds the level-shift and
trend-shift models with one and two breaks.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(ADF_GLS)}, {cmd:r(PT)}, {cmd:r(MZa)}, {cmd:r(MZt)}, {cmd:r(MSB)}, {cmd:r(MPT)}}statistics{p_end}
{synopt:{cmd:r(break1)}, {cmd:r(break2)}, {cmd:r(lambda1)}, {cmd:r(lambda2)}}break dates and fractions{p_end}
{synopt:{cmd:r(lags)}, {cmd:r(s2ar)}, {cmd:r(cbar)}}lag, s2_AR and c-bar{p_end}
{synopt:{cmd:r(stats)}, {cmd:r(cv)}}1 x 6 statistics and 6 x 3 critical values{p_end}
{synopt:{cmd:r(formulas)}}{cmd:gauss} or {cmd:paper}{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint glsbreak ln_inv}{p_end}
{phang2}{cmd:. tsurcoint glsbreak ln_inv, model(level)}{p_end}
{phang2}{cmd:. tsurcoint glsbreak ln_inv, model(trend) breaks(2) pmax(4)}{p_end}
{phang2}{cmd:. tsurcoint glsbreak ln_inv, paper}{p_end}

{marker references}{...}
{title:References}

{phang}Perron, P., and G. Rodriguez. 2003. GLS detrending, efficient unit root tests and structural change.
{it:Journal of Econometrics} 115: 1-27. {browse "https://doi.org/10.1016/S0304-4076(03)00090-3":doi:10.1016/S0304-4076(03)00090-3}{p_end}
{phang}Carrion-i-Silvestre, J. L., D. Kim, and P. Perron. 2009. GLS-based unit root tests with multiple structural breaks under
both the null and the alternative hypotheses. {it:Econometric Theory} 25: 1754-1792.{p_end}
{phang}Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit root tests with good size and power.
{it:Econometrica} 69: 1519-1554.{p_end}

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
