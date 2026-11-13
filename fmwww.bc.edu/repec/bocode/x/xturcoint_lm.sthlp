{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_lm##syntax"}{...}
{viewerjumpto "Description" "xturcoint_lm##description"}{...}
{viewerjumpto "Options" "xturcoint_lm##options"}{...}
{viewerjumpto "Remarks" "xturcoint_lm##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_lm##results"}{...}
{viewerjumpto "Examples" "xturcoint_lm##examples"}{...}
{viewerjumpto "References" "xturcoint_lm##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {bf:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint lm} {hline 2} Panel LM unit-root tests with level shifts (Im-Lee-Tieslau 2005) or level and trend shifts (Lee-Tieslau 2019)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint lm} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(level|trend)}}{bf:level}: Im-Lee-Tieslau (2005) level shifts (default); {bf:trend}: Lee-Tieslau (2019) level and trend shifts{p_end}
{synopt:{opt nb:reak(#)}}number of endogenous breaks per unit: 0 (default), 1 or 2{p_end}
{synopt:{opt pm:ax(#)}}maximum number of lagged differences; default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}lag selection: AIC, BIC/SIC or general-to-specific t-test at 10% (default {cmd:tstat}){p_end}
{synopt:{opt trim(#)}}trimming fraction for the break search; default {cmd:0.10}{p_end}
{synopt:{opt pap:er}}use the formula of the paper instead of the GAUSS convention (see Remarks){p_end}
{synopt:{opt notab:le}}suppress the unit-specific table{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xturcoint lm} computes, for every unit, the minimum Lagrange-multiplier (LM) unit-root statistic of
Schmidt and Phillips (1992) / Lee and Strazicich (2003) with 0, 1 or 2 breaks at unknown dates, and pools them
into the standardized panel LM statistic

{p 8 8 2}Z = sqrt(N) [ mean(LM_i) - E(LM) ] / sqrt(V(LM)),

{pstd}
which is N(0,1) under H0 (all panels have a unit root) and rejects for large negative values. With
{cmd:model(level)} the breaks are level shifts and the moments E and V are the Im, Lee and Tieslau (2005)
no-break moments (the LM statistic is invariant to level shifts). With {cmd:model(trend)} the breaks shift the level
and the slope; the series is transformed as in Lee and Tieslau (2019) so that the statistic no longer depends
on the break fractions, and the moments come from their tables. E and V depend on T and on each unit's
selected lag (capped at 8).

{pstd}
This is a port of the GAUSS procedure {cmd:PDLM} (tspdlib 3.0.0, files PD_ILTlevel.src and PD_LTtrend.src,
which call {cmd:LM}, {cmd:LM_1break} and {cmd:LM_2breaks}). Results are numerically identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker options}{...}
{title:Options}

{phang}{opt model()} selects the break type; {cmd:level} (or {cmd:ilt}) and {cmd:trend} (or {cmd:lt}).
With {cmd:nbreak(0)} both models give the same Schmidt-Phillips panel LM test.

{phang}{opt nbreak(#)} 1 or 2 searches every admissible break date (two dates at least 2 periods apart for
{cmd:level}, 3 for {cmd:trend}) inside [trim*T, (1-trim)*T] and keeps the minimum LM statistic.

{phang}{opt pmax(#)} and {opt ic()} control the augmentation; {cmd:tstat} starts at {cmd:pmax} and drops the last
lag while |t| < 1.645.

{phang}{opt trim(#)}; as in GAUSS, the first admissible date is moved to pmax+3 if trim*T < pmax+2.

{phang}{cmd:paper} for {cmd:model(trend)} with breaks, uses for every unit the lag selected at its minimizing break
date (Lee and Tieslau 2019) instead of the GAUSS convention (lag of the last candidate date). It has no effect on
{cmd:model(level)} or {cmd:nbreak(0)}.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the formula of the paper is available with option {cmd:paper}. The differences are listed below.

{pstd}(1) {bf:Lag of the trend-break test.} For {cmd:model(trend)} GAUSS reports, and uses in the moments, the lag
selected at the {it:last} candidate break date rather than at the minimizing date. {cmd:xturcoint lm} does the same by
default; option {cmd:paper} uses the lag at the minimizing date, as in Lee and Tieslau (2019).
{p_end}

{pstd}Other GAUSS conventions (kept in both modes):
(2) The moment tables are indexed by T exactly as in GAUSS; the gaps of the GAUSS index (T = 10 and T = 53, 54,
where GAUSS stops with an error) are mapped to the nearest tabulated T.
(3) With {cmd:pmax(0)} GAUSS returns lag -1 for the break models (and then fails in the moments); the lag is
reported as 0 here. The trend-break test requires {cmd:pmax()} >= 1, as in GAUSS.

{pstd}{bf:Related commands.} The Lee-Tieslau two-break trend test is also part of {helpb xtbreaklm}
({cmd:type(sharp)}, package {cmd:xtpdroot}); {cmd:xturcoint lm} additionally covers the level-shift (ILT) test and the
one-break trend test.

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(PDLM)}}panel LM statistic{p_end}
{synopt:{cmd:r(p)}}left-tailed p-value{p_end}
{synopt:{cmd:r(mean)}, {cmd:r(var)}}moments E(LM), V(LM) used{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}
{synopt:{cmd:r(nbreak)}, {cmd:r(pmax)}, {cmd:r(trim)}}settings{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}, {cmd:r(ic)}, {cmd:r(varname)}}settings{p_end}
{synopt:{cmd:r(formulas)}}{cmd:gauss} (default) or {cmd:paper}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(individual)}}N x (2+nbreak): LM_i, lags, break date(s) in time units{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. keep if id<=20}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate, model(level) nbreak(1)}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate, model(trend) nbreak(1) pmax(4) ic(bic)}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate, model(trend) nbreak(1) pmax(4) ic(bic) paper}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate, model(level) nbreak(2) pmax(2)}{p_end}
{phang2}{cmd:. matrix list r(individual)}{p_end}

{marker references}{...}
{title:References}

{phang}Im, K. S., J. Lee, and M. Tieslau. 2005. Panel LM unit-root tests with level shifts.
{it:Oxford Bulletin of Economics and Statistics} 67: 393-419. {browse "https://doi.org/10.1111/j.1468-0084.2005.00125.x":doi:10.1111/j.1468-0084.2005.00125.x}{p_end}
{phang}Lee, J., and M. Tieslau. 2019. Panel LM unit root tests with level and trend shifts.
{it:Economic Modelling} 80: 1-10. {browse "https://doi.org/10.1016/j.econmod.2018.07.025":doi:10.1016/j.econmod.2018.07.025}{p_end}
{phang}Lee, J., and M. C. Strazicich. 2003. Minimum Lagrange multiplier unit root test with two structural breaks.
{it:Review of Economics and Statistics} 85: 1082-1089.{p_end}
{phang}Schmidt, P., and P. C. B. Phillips. 1992. LM tests for a unit root in the presence of deterministic trends.
{it:Oxford Bulletin of Economics and Statistics} 54: 257-287.{p_end}
{phang}Nazlioglu, S. GAUSS tspdlib: Time Series and Panel Data Methods library, version 3.0.0, Aptech Systems.{p_end}

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
