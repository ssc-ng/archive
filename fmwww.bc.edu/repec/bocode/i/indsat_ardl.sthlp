{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat types" "help indsat_types"}{...}
{vieweralsosee "ardl (if installed)" "help ardl"}{...}
{title:Title}

{phang}
{bf:indsat ardl} {hline 2} ARDL / error-correction model with indicator saturation and the bounds test


{title:Syntax}

{p 8 15 2}
{cmd:indsat ardl} {depvar} {indepvars} {ifin} {cmd:,} {it:saturation} [{opt lags(numlist)} {opt maxl:ags(#)} {opt aic} {opt ec} {opt ec1}
{opt nobounds} {opt nogr:aph} {opt nocomp:are} {opt exog(varlist)} {opt pre:fix(stub)} {opt tr:endvar(varname)} {opt nocons:tant} {it:isat_options}]


{title:Description}

{pstd}
{cmd:indsat ardl} detects outliers and breaks in an autoregressive distributed-lag (ARDL) model and then tests for
a long-run (level) relationship with the Pesaran, Shin & Smith (2001) bounds test, using the Kripfganz &
Schneider (2020) critical values of the {cmd:ardl} package. Unmodelled outliers and level shifts bias ARDL
long-run coefficients and the bounds test; saturating the ARDL regression first and adding the retained
indicators as unrestricted deterministic terms gives robust long-run estimates.{p_end}

{pstd}
Steps: (1) lag orders from {opt lags()} or selected by {cmd:ardl} (BIC, or {opt aic}) without indicators;
(2) {helpb indsat} on the ARDL regression in levels with every ARDL term fixed and the chosen indicator sets
({cmd:iis}, {cmd:sis}, {cmd:super}, {cmd:mis()}, ...); the retained indicators are saved as variables
{it:stub}{it:name} (default {cmd:_I}); (3) {cmd:ardl} with {cmd:exog()} = retained indicators, in error-correction
form ({opt ec}, default) followed by {cmd:estat ectest}.{p_end}

{pstd}
Graphs and comparisons are produced automatically: the dashboard {cmd:indsat_dash} of the saturated ARDL
regression (fit with break dates, residuals, intercept path, timeline of indicators) and the table and graph
{cmd:indsat_compare} of the long-run coefficients and the speed of adjustment estimated {it:without} and
{it:with} the retained indicators. {opt nograph} and {opt nocompare} suppress them. {opt exog()} adds exogenous
regressors (kept fixed, as in {cmd:ardl}).{p_end}

{pstd}
{bf:After your own ardl.} Typing {cmd:indsat ,} {it:saturation} right after {cmd:ardl} reads the lag orders,
{cmd:exog()}, constant and sample from {cmd:e()} and runs all of the above (see {help indsat##post:post-estimation mode}).{p_end}

{pstd}
Requires {cmd:ardl} ({stata ssc install ardl:ssc install ardl}). {opt lags()} gives p for {depvar} followed by one q per regressor.


{title:Remarks}

{pstd}
Step indicators enter the EC model unrestricted (case 3 of PSS): a step of size gamma shifts the equilibrium
mean by gamma/(-alpha), where alpha is the speed of adjustment. Use {cmd:mis()} to allow a break in a slope.
Keep {opt tpval()} small (1/T or less) because the bounds-test critical values do not account for selection,
and report results with and without saturation.


{title:Examples}

{phang2}{cmd:. use indsat_dhsy, clear}{p_end}
{phang2}{cmd:. indsat ardl c y D4p, lags(5 5 1) super tpval(0.01)}{p_end}
{phang2}{cmd:. indsat ardl c y D4p, maxlags(5) iis tpval(0.025) aic}{p_end}
{phang2}{cmd:. ardl c y D4p, lags(2 2 1)}{p_end}
{phang2}{cmd:. indsat, sis tpval(0.01)}{space 16}// saturate the ARDL in memory{p_end}


{title:Stored results}

{pstd}The {cmd:ardl} results plus {cmd:e(indsat_retained)}, {cmd:e(indsat_indicators)}, {cmd:e(indsat_nret)} and {cmd:e(indsat_lags)}.{p_end}


{title:References}

{phang}Davidson, J.E.H., D.F. Hendry, F. Srba and S. Yeo (1978). Econometric modelling of the aggregate time-series relationship between consumers' expenditure and income in the United Kingdom. {it:Economic Journal} 88: 661-692.{p_end}
{phang}Kripfganz, S. and D.C. Schneider (2020). Response surface regressions for critical value bounds and approximate p-values in equilibrium correction models. {it:Oxford Bulletin of Economics and Statistics} 82: 1456-1481.{p_end}
{phang}Pesaran, M.H., Y. Shin and R.J. Smith (2001). Bounds testing approaches to the analysis of level relationships. {it:Journal of Applied Econometrics} 16: 289-326.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}merwanroudane920@gmail.com{break}{browse "https://github.com/merwanroudane":github.com/merwanroudane}
