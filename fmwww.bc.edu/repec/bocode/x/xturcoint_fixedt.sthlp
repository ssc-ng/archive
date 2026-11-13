{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_fixedt##syntax"}{...}
{viewerjumpto "Description" "xturcoint_fixedt##description"}{...}
{viewerjumpto "Options" "xturcoint_fixedt##options"}{...}
{viewerjumpto "Remarks" "xturcoint_fixedt##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_fixedt##results"}{...}
{viewerjumpto "Examples" "xturcoint_fixedt##examples"}{...}
{viewerjumpto "References" "xturcoint_fixedt##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {bf:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint fixedt} {hline 2} Fixed-T panel stationarity (Hadri-Larsson 2005) and unit-root (Carrion-i-Silvestre-Hadri 2010) LM tests


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint fixedt} {varname} {ifin} [{cmd:,} {opt mod:el(constant|trend)} {opt notab:le}]

{marker description}{...}
{title:Description}

{pstd}
For each unit the OLS residuals e_i of y_i on (1) or (1, t) give two LM statistics:

{p 8 8 2}LM(HL)_i = sum_t S_t^2 / (T e_i'e_i), S_t = partial sums of e_i (KPSS-type, H0: stationarity),{p_end}
{p 8 8 2}LM(CH)_i = sum_t S(de)_t^2 / (T de_i'de_i), de = first differences of e_i (Bhargava-type, H0: unit root).{p_end}

{pstd}
Both are standardized with their {it:exact} finite-T means and variances, so the panel statistics

{p 8 8 2}Z_HL = sqrt(N)(mean LM(HL)_i - mu1)/sd1 ~ N(0,1) (right tail) and Z_CH = sqrt(N)(mean LM(CH)_i - mu2)/sd2 ~ N(0,1) (left tail)

{pstd}
are valid for fixed T and N -> infinity (micro panels, short macro panels). This is a port of the GAUSS
procedure {cmd:fixed_T_panel} (tspdlib 3.0.0, PD_fixedT.src); results are identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker options}{...}
{title:Options}

{phang}{opt model(constant|trend)} deterministic component (default {cmd:constant}).

{phang}{opt notable} suppresses the unit-specific statistics.

{marker remarks}{...}
{title:Remarks}

{pstd}The GAUSS procedure reads T from a {it:global} symbol rather than from the data; {cmd:xturcoint fixedt} always uses
the number of periods of the estimation sample (identical to GAUSS when the global equals rows(y)).
The two tests have opposite nulls: use them together as a confirmatory analysis.

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(Z_HL)}, {cmd:r(p_HL)}}Hadri-Larsson statistic and right-tailed p-value{p_end}
{synopt:{cmd:r(Z_CH)}, {cmd:r(p_CH)}}Carrion-i-Silvestre-Hadri statistic and left-tailed p-value{p_end}
{synopt:{cmd:r(mu_HL)}, {cmd:r(var_HL)}, {cmd:r(mu_CH)}, {cmd:r(var_CH)}}exact moments{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}
{synopt:{cmd:r(individual)}}N x 6: LM, Z, p for each test{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. keep if id<=30 & year>=1990}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xturcoint fixedt lnrxrate}{p_end}
{phang2}{cmd:. xturcoint fixedt lnrxrate, model(trend)}{p_end}

{marker references}{...}
{title:References}

{phang}Hadri, K., and R. Larsson. 2005. Testing for stationarity in heterogeneous panel data where the time dimension is finite.
{it:Econometrics Journal} 8: 55-69. {browse "https://doi.org/10.1111/j.1368-423X.2005.00151.x":doi:10.1111/j.1368-423X.2005.00151.x}{p_end}
{phang}Carrion-i-Silvestre, J. L., and K. Hadri. 2010. Panel data unit root test with fixed time dimension.
{it:Bulletin of Economic Research} 62: 269-277. {browse "https://doi.org/10.1111/j.1467-8586.2009.00336.x":doi:10.1111/j.1467-8586.2009.00336.x}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
{help xturcoint:xturcoint} (overview, list of all tests, map of the GAUSS libraries){break}
Unit root: {help xturcoint_lm:xturcoint lm}, {help xturcoint_fixedt:xturcoint fixedt}, {help xturcoint_mp:xturcoint mp}, {help xturcoint_panic:xturcoint panic}{break}
Pre-test: {help xturcoint_cd:xturcoint cd}{break}
Cointegration: {help xturcoint_cusum:xturcoint cusum}, {help xturcoint_adfmin:xturcoint adfmin}
{p_end}
