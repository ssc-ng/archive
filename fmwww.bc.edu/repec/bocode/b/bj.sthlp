{smcl}
{* *! version 1.0.0  23nov2026}{...}
{vieweralsosee "[TS] corrgram" "help corrgram"}{...}
{vieweralsosee "[TS] tsline" "help tsline"}{...}
{vieweralsosee "[G-2] graph combine" "help graph combine"}{...}
{vieweralsosee "[TS] arima" "help arima"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] arimasoc" "help arimasoc"}{...}
{viewerjumpto "Syntax" "bj##syntax"}{...}
{viewerjumpto "Description" "bj##description"}{...}
{viewerjumpto "Options" "bj##options"}{...}
{viewerjumpto "Remarks" "bj##remarks"}{...}
{viewerjumpto "Examples" "bj##examples"}{...}
{viewerjumpto "References" "bj##references"}{...}
{viewerjumpto "Author" "bj##author"}{...}
{title:Title}

{p2colset 5 11 13 2}{...}
{p2col:{cmd:bj} {hline 2}}Box{c -}Jenkins strategy: identification, and
estimation, diagnostic checking and forecast, each in one figure{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:bj} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt id}}examine only the identification stage (output {cmd:bj_id}){p_end}
{synopt:{opt arima(spec)}}full {helpb arima} specification of the model to
estimate, for example {cmd:arima(arima(1,1,0))}{p_end}
{synopt:{opt ord:er(p q)}}ARMA({it:p},{it:q}) model to estimate; shortcut
for {cmd:arima(arima(}{it:p}{cmd:,0,}{it:q}{cmd:))}; default is the model
selected by BIC{p_end}
{synopt:{opt hor:izon(#)}}number of forecast periods; default is 5% of the
observations{p_end}
{synopt:{opt lag:s(#)}}number of lags in the ACF and PACF; default as in
{helpb corrgram}{p_end}
{synopt:{opt lev:el(#)}}confidence level for the bands; default is
{cmd:level(95)}{p_end}

{syntab:Combined graph}
{synopt:{opt ti:tle(tinfo)}}overall title; default is
{cmd:"Box - Jenkins modelling strategy"}{p_end}
{synopt:{opt sub:title(tinfo)}}subtitle of the identification output;
default is two lines, {cmd:Identification} and the {it:variable label}{p_end}
{synopt:{opt estsub:title(tinfo)}}subtitle of the estimation output;
default is two lines, {cmd:Estimation, diagnosis and forecast} and the
{it:variable label}{p_end}
{synopt:{opt nolab:el}}use the variable name instead of its label in the
default subtitle{p_end}
{synopt:{opt noinfo}}suppress both information panels below the graphs{p_end}
{synopt:{opt notest:s}}suppress the unit root and ARMA selection panel; keep
the data description{p_end}
{synopt:{opt info:text("line" ["line" ...])}}add lines of text to the
information panel, such as a description of the data{p_end}
{synopt:{opt dfl:ags(#)}}lagged differences in the Dickey{c -}Fuller tests;
default is {cmd:dflags(0)}{p_end}
{synopt:{opt soc:opts(options)}}options passed to {helpb arimasoc}; the
maximum AR and MA orders depend on the frequency of the data{p_end}
{synopt:{opt exp:ort(filename[, replace])}}export the figures to
{it:filename} and {it:filename}{cmd:_est}; PDF if no extension is
given{p_end}
{synopt:{opt note(tinfo)}}overall note{p_end}
{synopt:{opt cap:tion(tinfo)}}overall caption{p_end}
{synopt:{opt name(name[, replace])}}name of the combined graph; default is
{cmd:bj_id, replace}{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the combined graph to disk{p_end}
{synopt:{opt combopt:s(options)}}other options passed to
{helpb graph combine}{p_end}

{syntab:Individual graphs}
{synopt:{opt tsopt:s(options)}}options passed to {helpb tsline}{p_end}
{synopt:{opt acopt:s(options)}}options passed to {helpb ac}{p_end}
{synopt:{opt pacopt:s(options)}}options passed to {helpb pac}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {helpb tsset} your data before using {cmd:bj}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see
{help tsvarlist}. For example, {cmd:bj D.y} analyzes the first difference of
{cmd:y}.{p_end}
{p 4 6 2}
The identification figure analyzes {it:depvar} only; {it:indepvars} enter the
model estimated in the estimation figure.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bj} gathers in two publication-ready figures the steps of the
Box{c -}Jenkins methodology: identification, and estimation, diagnostic
checking and forecast. It is intended mainly for teaching and consulting.

{pstd}
{cmd:bj} requires Stata 18 or later, because the ARMA selection in the
identification figure uses {helpb arimasoc}.

{pstd}
{cmd:bj} produces two figures, with the same title:

{p2colset 8 20 22 2}{...}
{p2col:{cmd:bj_id}}{it:Identification}: time plot of the series, ACF and
PACF, description of the data, Dickey{c -}Fuller tests and ARMA selection
with {helpb arimasoc}. Letter proportion (8.5 x 11).{p_end}
{p2col:{cmd:bj_est}}{it:Estimation}: an ARMA({it:p},{it:q}) model, or the
model given in {opt arima()}, estimated with {helpb arima}. Top row: observed and fitted values (65% of the width)
and the forecast (35%). Middle row: residuals over time (65%) and their
histogram with a normal density (35%). Bottom row: table of residual
diagnostics (65%) and normal Q-Q plot of the residuals (35%). Letter
proportion (8.5 x 11).{p_end}
{p2colreset}{...}

{pstd}
Option {opt id} restricts {cmd:bj} to the identification figure.

{pstd}
{cmd:bj} is a wrapper: it calls official Stata commands and joins their
output with {helpb graph combine}. The identification figure uses
{helpb tsline}, {helpb ac}, {helpb pac}, {helpb summarize}, {helpb dfuller}
and {helpb arimasoc}; the estimation figure uses {helpb arima},
{cmd:predict} (see {helpb arima postestimation}), {helpb tsappend},
{helpb wntestq}, {helpb histogram} and {helpb qnorm}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt id} examines only the identification stage of the Box{c -}Jenkins
methodology: {cmd:bj} produces {cmd:bj_id} and skips the estimation figure
{cmd:bj_est}.

{phang}
{opt arima(spec)} gives the full specification of the model estimated in
{cmd:bj_est}, as if you had a good prior guess of the model. {it:spec} is
passed as is to {cmd:arima} {it:depvar} [{it:indepvars}]{cmd:,} {it:spec};
any {helpb arima} option is allowed: {cmd:ar()}, {cmd:ma()},
{cmd:arima(}{it:p}{cmd:,}{it:d}{cmd:,}{it:q}{cmd:)},
{cmd:sarima(}{it:P}{cmd:,}{it:D}{cmd:,}{it:Q}{cmd:,}{it:s}{cmd:)},
{cmd:mar()}, {cmd:mma()}, {cmd:noconstant}, and so on. For example,
{cmd:arima(ar(1) ma(1))}, {cmd:arima(arima(1,1,0))} or
{cmd:arima(ar(1) sarima(1,0,0,7))}. Do not combine it with {opt order()}.
{p_end}
{pmore}
If the model is differenced, with {it:d} > 0 in {cmd:arima()} or {it:D} > 0
in {cmd:sarima()}, the fitted values and the forecast are in levels of
{it:depvar} ({cmd:predict, y}), and the forecast panel has no band:
{cmd:predict, mse} refers to the differenced series only. The residuals are
those of the differenced model.
{p_end}
{pmore}
With {it:indepvars}, the forecast needs their values after the sample. If
you have them, add the forecast periods with {helpb tsappend} and fill in
the values of {it:indepvars} before running {cmd:bj}; {cmd:bj} uses them.
Missing values after the sample are held at the last value of each
variable in the estimation sample, and the note says so. This is a strong
assumption: the forecast is conditional on {it:indepvars} staying at their
last value, and the band does not include their uncertainty.
{p_end}

{phang}
{opt order(p q)} sets the ARMA({it:p},{it:q}) model estimated in
{cmd:bj_est}; it is a shortcut for {cmd:arima(arima(}{it:p}{cmd:,0,}{it:q}{cmd:))}.
By default, {cmd:bj} uses the model selected by the BIC in
{helpb arimasoc}. Differencing can be done with time-series operators, as
in {cmd:bj D.y, order(}{it:p q}{cmd:)}, whose fitted values and forecast are
those of {cmd:D.y}, or with {opt arima()}, as in
{cmd:bj y, arima(arima(}{it:p}{cmd:,1,}{it:q}{cmd:))}, whose fitted values and
forecast are in levels of {cmd:y}.

{phang}
{opt horizon(#)} sets the number of periods {it:h} forecast in
{cmd:bj_est}. By default, {it:h} is 5% of the observations, rounded up. The
forecast panel shows the last {it:h} observed periods and the {it:h}
forecast periods.

{phang}
{opt lags(#)} specifies the number of lags shown in both the ACF and the
PACF.

{phang}
{opt level(#)}; see {helpb level:[R] level}. Applies to both the ACF and the
PACF bands.

{dlgtab:Combined graph}

{phang}
{opt title()}, {opt subtitle()}, {opt note()} and {opt caption()} apply to the
combined figure; see {manhelpi title_options G-3}. The default title is
{cmd:"Box - Jenkins modelling strategy"}, in both figures. The default
subtitle has two lines: the stage ({cmd:Identification} or
{cmd:Estimation, diagnosis and forecast}) and, below it, the variable label. When {it:varname}
contains time-series operators, the expression is appended, for example
{it:label} {cmd:(D.gnp96)}. If the variable has no label, the
variable name is used. {opt subtitle()} changes the subtitle of
{cmd:bj_id} and {opt estsubtitle()} that of {cmd:bj_est}; each one leaves
the other figure with its default subtitle. To give your own subtitle in two
lines, type {cmd:subtitle("}{it:line 1}{cmd:" "}{it:line 2}{cmd:")}, and
likewise for {opt estsubtitle()}.

{phang}
{opt nolabel} uses the variable name, with its time-series operators, in the
default subtitle instead of the variable label.

{phang}
{opt noinfo} suppresses the information row. By default, {cmd:bj} adds a
row below the ACF and PACF with two boxed panels of the same width as those
graphs. The panel below the ACF, titled {it:Data description}, is a
two-column table that reports the start date, end date and frequency of the
series, as declared with {helpb tsset}, and the number of observations,
mean, standard deviation, minimum and maximum of the series. The values
refer to the sample actually used, after {cmd:if}, {cmd:in} and
the missing values created by time-series operators; with {cmd:bj D.y}, the
statistics are those of {cmd:D.y}. Statistics are shown with the display
format of the variable; see {helpb format}.

{phang}
{opt notests} suppresses the panel {it:Unit root and ARMA selection}: the
Dickey{c -}Fuller tests and {helpb arimasoc} are not run, which makes
{cmd:bj} much faster. The {it:Data description} panel is still shown, below
the ACF, and the cell below the PACF is left empty. It has no effect if
{opt noinfo} is specified.

{phang}
{opt infotext("line" ["line" ...])} adds lines of text below the
{it:Data description} panel. Each line must be enclosed in double quotes. A typical use is
a short description of the data: source, units, definitions. It has no
effect if {opt noinfo} is specified.

{phang}
{opt export(filename[, replace])} exports the figures with
{helpb graph export}: {cmd:bj_id} to {it:filename} and {cmd:bj_est} to
{it:filename}{cmd:_est}. If {it:filename} has no extension, {cmd:.pdf} is
added, so the figures are exported to PDF; for example,
{cmd:export(bj, replace)} creates {cmd:bj.pdf} and {cmd:bj_est.pdf}. Other formats are chosen by the extension,
for example {cmd:export(figure.png, replace)}. Enclose {it:filename} in
double quotes if it contains spaces. Use {cmd:replace} to overwrite an
existing file.

{phang}
{opt name()} and {opt saving()}; see {manhelpi name_option G-3} and
{manhelpi saving_option G-3}.

{phang}
{opt combopts(options)} passes any other option to the final
{cmd:graph combine}. By default the figure has the proportion of a letter
page, {cmd:xsize(8.5) ysize(11)} ({cmd:xsize(8.5) ysize(7.33)} with
{opt noinfo}), with three rows of equal height: the time plot of the
series, the ACF and PACF, and the information panels. To change the size, use, for example,
{cmd:combopts(xsize(5) ysize(6))}. The size also sets the dimensions of the
file created by {opt export()}: by default, a letter-size PDF. Text is scaled with {cmd:iscale(0.5)}; use,
for example, {cmd:combopts(iscale(0.8))} for larger text.

{dlgtab:Individual graphs}

{phang}
{opt tsopts(options)}, {opt acopts(options)} and {opt pacopts(options)} pass
options to each of the three graphs. Any option accepted by the corresponding
command is allowed, such as {cmd:title()}, {cmd:ytitle()}, {cmd:xlabel()} or
{cmd:note()}. Do not specify {cmd:lags()} or {cmd:level()} here; use the main
options instead. By default the ACF is titled {cmd:AC}, the PACF is titled
{cmd:PAC}, and neither has a y-axis title. The series, the ACF and the PACF
are drawn in {cmd:navy}, with very small markers in the ACF and PACF. For example,
{cmd:acopts(title("Autocorrelation") ytitle("r(k)"))} replaces the title
defaults, and {cmd:tsopts(lcolor(maroon))} or
{cmd:acopts(lcolor(maroon) mcolor(maroon) msize(medium))} replace the colors
and marker size.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:ac} and {cmd:pac} require a sample without gaps. If {cmd:if} or
{cmd:in} produce gaps in the time variable, {cmd:bj} stops with the error
message of {cmd:ac}.

{pstd}
The panel below the PACF, titled {it:Unit root and ARMA selection}, reports:

{p2colset 8 24 26 2}{...}
{p2col:{bf:DF none}}{helpb dfuller} with {cmd:noconstant}: no constant, no
trend{p_end}
{p2col:{bf:DF constant}}{helpb dfuller}: constant{p_end}
{p2col:{bf:DF trend}}{helpb dfuller} with {cmd:trend}: constant and linear
trend{p_end}
{p2col:{bf:DF lags}}number of lagged differences, set with
{opt dflags()}{p_end}
{p2col:{bf:ARMA search}}maximum AR and MA orders searched by
{helpb arimasoc}{p_end}
{p2col:{bf:AIC, BIC, HQIC}}ARMA({it:p},{it:q}) model selected by each
criterion and the value of the criterion{p_end}
{p2colreset}{...}

{pstd}
By default, the maximum AR and MA orders searched by {helpb arimasoc}
depend on the frequency declared with {helpb tsset}. The rule is 0.5 times
the seasonal period {it:s} of the data, rounded up, with a cap of 8 for
weekly data:

{p2colset 8 24 40 2}{...}
{p2col:{bf:Frequency}}{bf:{it:s}}{space 14}{bf:Max AR and MA order}{space 3}{bf:Models}{p_end}
{p2line}
{p2col:daily}7{space 16}4{space 21}25{p_end}
{p2col:weekly}52{space 15}8 (rule: 26, capped){space 3}81{p_end}
{p2col:monthly}12{space 15}6{space 21}49{p_end}
{p2col:quarterly}4{space 16}2{space 21}9{p_end}
{p2col:halfyearly}2{space 16}1{space 21}4{p_end}
{p2col:yearly}1{space 16}1{space 21}4{p_end}
{p2col:other}{space 17}2 ({helpb arimasoc} default){space 1}9{p_end}
{p2line}
{p2colreset}{...}

{pstd}
{helpb arimasoc} fits every ARMA({it:p},{it:q}) model with {it:p} and {it:q}
from 0 to the maximum, that is, (max + 1)^2 models. Daily data use the
calendar week ({it:s} = 7); with business days ({it:s} = 5) the rule gives
3, so specify {cmd:socopts(maxar(3) maxma(3))}. Weekly data use the annual
cycle ({it:s} = 52); the rule gives 26, that is, 729 models, which is too
slow and prone to convergence problems, so the order is capped at 8 (81
models). A {cmd:maxar()} or {cmd:maxma()} given in {opt socopts()} replaces
the default; for example, {cmd:socopts(maxar(4) maxma(4))} gives a faster
search.

{pstd}
For each Dickey{c -}Fuller specification, the panel shows the Z(t)
statistic and, in parentheses, the 5% critical value. The null hypothesis is
a unit root; it is rejected at 5% when Z(t) is smaller than the critical
value. All results refer to the series as analyzed: with {cmd:bj D.y}, the
tests and the ARMA selection apply to {cmd:D.y}. If a test or the model
selection cannot be computed, {cmd:n/a} is shown. {helpb arimasoc} requires
Stata 18 or later.

{pstd}
{bf:Estimation figure.} The model is estimated with
{cmd:arima} {it:depvar} [{it:indepvars}]{cmd:, arima(}{it:p}{cmd:,0,}{it:q}{cmd:)},
or with the specification given in {opt arima()}, on the estimation sample
(the observations with no missing values in {it:depvar} and
{it:indepvars}). The forecast horizon {it:h} is set with {opt horizon(#)}
or, by default, is 5% of the observations,
rounded up. {cmd:bj} adds {it:h} periods with {helpb tsappend} and computes a
dynamic forecast ({cmd:predict, dynamic()}) from the first period after the
sample: each forecast uses the previous forecasts, not observed values. The
forecast panel shows the last {it:h} observed periods, the forecast and its
{opt level()}% band, from {cmd:predict, mse} (no band for differenced
models in {opt arima()}). With {it:indepvars}, the values after the sample
given by the user are used, and the missing ones are held at the last value
in the sample. The data in memory are not
changed: {cmd:bj} works on a preserved copy.

{pstd}
{bf:Residual diagnostics.} The table below the residuals reports:

{p2colset 8 30 32 2}{...}
{p2col:{bf:Mean, Std. dev.}}of the residuals{p_end}
{p2col:{bf:Ljung-Box Q(}{it:L}{bf:)}}{helpb wntestq} on the residuals, with
the 5% critical value and the p-value; H0: white noise{p_end}
{p2col:{bf:McLeod-Li Q(}{it:L}{bf:)}}{helpb wntestq} on the squared
residuals, with the 5% critical value and the p-value; H0: no ARCH
effects{p_end}
{p2col:{bf:Skewness, Kurtosis}}of the residuals; 0 and 3 under
normality{p_end}
{p2col:{bf:Jarque-Bera}}normality test, with the 5% critical value and the
p-value; H0: normality{p_end}
{p2colreset}{...}

{pstd}
The critical value is the 95th percentile of the chi-squared distribution
with {it:L} degrees of freedom, {cmd:invchi2tail(}{it:L}{cmd:, 0.05)}; H0 is
rejected at 5% when Q is larger than the critical value, or, equivalently,
when the p-value is smaller than 0.05.

{pstd}
The Jarque{c -}Bera statistic is computed from the skewness {it:S} and the
kurtosis {it:K} of the residuals, JB = {it:N}/6 [{it:S}^2 + ({it:K} {c -} 3)^2/4],
and follows a chi-squared distribution with 2 degrees of freedom under H0;
the 5% critical value is {cmd:invchi2tail(2, 0.05)} = 5.99.

{pstd}
The number of lags {it:L} is twice the seasonal period: daily 14, weekly
104, monthly 24, quarterly 8, halfyearly 4; yearly 5; other units 10; at
most {it:N}/4. The degrees of freedom of the Q tests are not adjusted for
the {it:p}+{it:q} estimated parameters. The McLeod-Li test is used instead
of {cmd:estat archlm}, which is not available after {helpb arima}.

{pstd}
{bf:Frames.} The tables in the information panels have a navy frame. Stata
graphs do not support rounded corners, so the frames are rectangular.

{pstd}
The series, the ACF and the PACF are shown with the same relative text size:
the intermediate combinations use {cmd:iscale(1)}, so only the final
{helpb graph combine} scales the text. To change the overall text size, use
{cmd:combopts(iscale(}{it:#}{cmd:))}; the default is {cmd:iscale(0.5)}.

{pstd}
Double quotes ({cmd:"}) inside a variable label are replaced by single quotes
({cmd:'}) in the default subtitle.

{pstd}
Stata computes the PACF from a sequence of regressions; therefore the first
partial autocorrelation need not equal the first autocorrelation. See
{it:Methods and formulas} in {manlink TS corrgram}.


{marker examples}{...}
{title:Examples}

{pstd}
The examples use two datasets shipped with Stata, loaded with
{helpb sysuse}: {cmd:tsline2}, a stationary series of daily calories in
2002, and {cmd:gnp96}, the quarterly real GNP, a non-stationary series.

{pstd}{bf:Stationary series: tsline2}{p_end}

{pstd}Setup{p_end}
{phang2}{stata "sysuse tsline2, clear":. sysuse tsline2, clear}{p_end}
{phang2}{stata "tsset day":. tsset day}{p_end}

{pstd}Identification and estimation, with the model selected by BIC{p_end}
{phang2}{stata "bj calories":. bj calories}{p_end}

{pstd}Identification stage only; export the output bj_id to bj_id.pdf{p_end}
{phang2}{stata "bj calories, id export(bj_id, replace)":. bj calories, id export(bj_id, replace)}{p_end}

{pstd}Both figures to PDF: bj.pdf and bj_est.pdf{p_end}
{phang2}{stata "bj calories, export(bj, replace)":. bj calories, export(bj, replace)}{p_end}

{pstd}Estimation of an ARMA(1,1){p_end}
{phang2}{stata "bj calories, order(1 1)":. bj calories, order(1 1)}{p_end}

{pstd}Forecast of 30 days instead of the default (5% of 365 = 19 days){p_end}
{phang2}{stata "bj calories, horizon(30)":. bj calories, horizon(30)}{p_end}

{pstd}Full arima specification: ARMA(1,1) with a weekly seasonal AR term{p_end}
{phang2}{stata "bj calories, arima(ar(1) ma(1) sarima(1,0,0,7))":. bj calories, arima(ar(1) ma(1) sarima(1,0,0,7))}{p_end}

{pstd}Independent variable: held at its last value in the forecast{p_end}
{phang2}{stata "bj calories ucalories, arima(ar(1))":. bj calories ucalories, arima(ar(1))}{p_end}

{pstd}Independent variable with values for 7 days after the sample{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. tsappend, add(7)}{p_end}
{phang2}{cmd:. replace ucalories = L7.ucalories if missing(ucalories)}{p_end}
{phang2}{cmd:. bj calories ucalories, arima(ar(1)) horizon(7)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}28 lags in the ACF and PACF, 90% bands{p_end}
{phang2}{stata "bj calories, lags(28) level(90)":. bj calories, lags(28) level(90)}{p_end}

{pstd}Your own subtitles in both figures{p_end}
{phang2}{stata `"bj calories, subtitle("Identification" "Daily calories, 2002") estsubtitle("Estimation" "Daily calories, 2002")"':. bj calories, subtitle("Identification" "Daily calories, 2002") estsubtitle("Estimation" "Daily calories, 2002")}{p_end}

{pstd}Variable name instead of label in the subtitle{p_end}
{phang2}{stata "bj calories, nolabel":. bj calories, nolabel}{p_end}

{pstd}Without the information panels{p_end}
{phang2}{stata "bj calories, noinfo":. bj calories, noinfo}{p_end}

{pstd}Data description only, without unit root tests and ARMA selection (faster){p_end}
{phang2}{stata "bj calories, notests":. bj calories, notests}{p_end}

{pstd}Additional description of the data in the information panel{p_end}
{phang2}{stata `"bj calories, infotext("Unit: calories per day" "Source: Stata example data")"':. bj calories, infotext("Unit: calories per day" "Source: Stata example data")}{p_end}

{pstd}Statistics with thousands separators: change the display format first{p_end}
{phang2}{cmd:. format calories %12.0fc}{p_end}
{phang2}{cmd:. bj calories}{p_end}

{pstd}ARMA search: default for daily data, max AR and MA order 4 (25 models){p_end}
{phang2}{stata "bj calories":. bj calories}{p_end}

{pstd}ARMA search: faster, max AR and MA order 2 (9 models){p_end}
{phang2}{stata "bj calories, socopts(maxar(2) maxma(2))":. bj calories, socopts(maxar(2) maxma(2))}{p_end}

{pstd}ARMA search: deep AR, shallow MA, max AR 6 and MA 2 (21 models){p_end}
{phang2}{stata "bj calories, socopts(maxar(6) maxma(2))":. bj calories, socopts(maxar(6) maxma(2))}{p_end}

{pstd}Dickey{c -}Fuller tests with 7 lagged differences{p_end}
{phang2}{stata "bj calories, dflags(7)":. bj calories, dflags(7)}{p_end}

{pstd}Customizing the individual graphs{p_end}
{phang2}{cmd:. bj calories, tsopts(title("Series")) acopts(title("ACF")) pacopts(title("PACF")) note("Source: Stata example data")}{p_end}

{pstd}{bf:Non-stationary series: gnp96}{p_end}

{pstd}Setup{p_end}
{phang2}{stata "sysuse gnp96, clear":. sysuse gnp96, clear}{p_end}
{phang2}{stata "tsset date":. tsset date}{p_end}

{pstd}Levels: the ACF decays slowly and the Dickey{c -}Fuller tests do not
reject the unit root{p_end}
{phang2}{stata "bj gnp96":. bj gnp96}{p_end}

{pstd}First difference: the series becomes stationary{p_end}
{phang2}{stata "bj D.gnp96":. bj D.gnp96}{p_end}

{pstd}ARIMA(1,1,0): first difference and order(1 0){p_end}
{phang2}{stata "bj D.gnp96, order(1 0)":. bj D.gnp96, order(1 0)}{p_end}

{pstd}Forecast of 8 quarters (two years){p_end}
{phang2}{stata "bj D.gnp96, order(1 0) horizon(8)":. bj D.gnp96, order(1 0) horizon(8)}{p_end}

{pstd}ARIMA(1,1,0) in levels: fitted values and forecast of gnp96, not of
its difference{p_end}
{phang2}{stata "bj gnp96, arima(arima(1,1,0)) horizon(8)":. bj gnp96, arima(arima(1,1,0)) horizon(8)}{p_end}


{marker references}{...}
{title:References}

{pstd}{bf:Box{c -}Jenkins methodology}{p_end}

{phang}
Box, G. E. P., and G. M. Jenkins. 1970.
{it:Time Series Analysis: Forecasting and Control}. San Francisco:
Holden-Day.

{phang}
Box, G. E. P., G. M. Jenkins, G. C. Reinsel, and G. M. Ljung. 2015.
{it:Time Series Analysis: Forecasting and Control}. 5th ed. Hoboken, NJ:
Wiley.

{phang}
Hamilton, J. D. 1994. {it:Time Series Analysis}. Princeton, NJ: Princeton
University Press.

{pstd}{bf:Identification: confidence bands of the ACF and PACF}{p_end}

{phang}
Bartlett, M. S. 1946. On the theoretical specification and sampling
properties of autocorrelated time-series. {it:Supplement to the Journal of
the Royal Statistical Society} 8: 27{c -}41.
{browse "https://doi.org/10.2307/2983611"}.

{phang}
Quenouille, M. H. 1949. Approximate tests of correlation in time-series.
{it:Journal of the Royal Statistical Society, Series B} 11: 68{c -}84.
{browse "https://doi.org/10.1111/j.2517-6161.1949.tb00023.x"}.

{pstd}{bf:Identification: unit root tests}{p_end}

{phang}
Dickey, D. A., and W. A. Fuller. 1979. Distribution of the estimators for
autoregressive time series with a unit root. {it:Journal of the American
Statistical Association} 74: 427{c -}431.
{browse "https://doi.org/10.1080/01621459.1979.10482531"}.

{phang}
Dickey, D. A., and W. A. Fuller. 1981. Likelihood ratio statistics for
autoregressive time series with a unit root. {it:Econometrica} 49:
1057{c -}1072. {browse "https://doi.org/10.2307/1912517"}.

{phang}
Fuller, W. A. 1996. {it:Introduction to Statistical Time Series}. 2nd ed.
New York: Wiley.

{phang}
MacKinnon, J. G. 1994. Approximate asymptotic distribution functions for
unit-root and cointegration tests. {it:Journal of Business and Economic
Statistics} 12: 167{c -}176.
{browse "https://doi.org/10.1080/07350015.1994.10510005"}.

{phang}
Said, S. E., and D. A. Dickey. 1984. Testing for unit roots in
autoregressive-moving average models of unknown order. {it:Biometrika} 71:
599{c -}607. {browse "https://doi.org/10.1093/biomet/71.3.599"}.

{pstd}{bf:Identification: ARMA order selection}{p_end}

{phang}
Akaike, H. 1974. A new look at the statistical model identification.
{it:IEEE Transactions on Automatic Control} 19: 716{c -}723.
{browse "https://doi.org/10.1109/TAC.1974.1100705"}.

{phang}
Hannan, E. J., and B. G. Quinn. 1979. The determination of the order of an
autoregression. {it:Journal of the Royal Statistical Society, Series B} 41:
190{c -}195. {browse "https://doi.org/10.1111/j.2517-6161.1979.tb01072.x"}.

{phang}
Schwarz, G. 1978. Estimating the dimension of a model. {it:Annals of
Statistics} 6: 461{c -}464.
{browse "https://doi.org/10.1214/aos/1176344136"}.

{pstd}{bf:Diagnosis: residual tests and Q-Q plot}{p_end}

{phang}
Box, G. E. P., and D. A. Pierce. 1970. Distribution of residual
autocorrelations in autoregressive-integrated moving average time series
models. {it:Journal of the American Statistical Association} 65:
1509{c -}1526. {browse "https://doi.org/10.1080/01621459.1970.10481180"}.

{phang}
Jarque, C. M., and A. K. Bera. 1980. Efficient tests for normality,
homoscedasticity and serial independence of regression residuals.
{it:Economics Letters} 6: 255{c -}259.
{browse "https://doi.org/10.1016/0165-1765(80)90024-5"}.

{phang}
Jarque, C. M., and A. K. Bera. 1987. A test for normality of observations
and regression residuals. {it:International Statistical Review} 55:
163{c -}172. {browse "https://doi.org/10.2307/1403192"}.

{phang}
Ljung, G. M., and G. E. P. Box. 1978. On a measure of lack of fit in time
series models. {it:Biometrika} 65: 297{c -}303.
{browse "https://doi.org/10.1093/biomet/65.2.297"}.

{phang}
McLeod, A. I., and W. K. Li. 1983. Diagnostic checking ARMA time series
models using squared-residual autocorrelations. {it:Journal of Time Series
Analysis} 4: 269{c -}273.
{browse "https://doi.org/10.1111/j.1467-9892.1983.tb00373.x"}.

{phang}
Wilk, M. B., and R. Gnanadesikan. 1968. Probability plotting methods for
the analysis of data. {it:Biometrika} 55: 1{c -}17.
{browse "https://doi.org/10.1093/biomet/55.1.1"}.

{phang}
Wilson, E. B., and M. M. Hilferty. 1931. The distribution of chi-square.
{it:Proceedings of the National Academy of Sciences} 17: 684{c -}688.
{browse "https://doi.org/10.1073/pnas.17.12.684"}.

{pstd}{bf:Software}{p_end}

{phang}
StataCorp. 2023. {it:Stata 18 Time-Series Reference Manual}. College
Station, TX: Stata Press.


{marker author}{...}
{title:Author}

{pstd}
Rodrigo Taborda, Universidad de los Andes{break}
{browse "mailto:r.taborda@uniandes.edu.co":r.taborda@uniandes.edu.co}


{title:Also see}

{psee}
Online: {manhelp corrgram TS}, {manhelp tsline TS}, {manhelp graph_combine G-2:graph combine},
{manhelp arima TS}, {manhelp dfuller TS}, {manhelp arimasoc TS},
{manhelp tsappend TS}, {manhelp wntestq TS},
{manhelp qnorm R}
{p_end}
