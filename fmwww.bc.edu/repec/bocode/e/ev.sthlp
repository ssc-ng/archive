{smcl}
{* *! version 0.2.2  05nov2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "ev##syntax"}{...}
{viewerjumpto "Description" "ev##description"}{...}
{viewerjumpto "Options" "ev##options"}{...}
{viewerjumpto "Functions" "ev##functions"}{...}
{viewerjumpto "Examples" "ev##examples"}{...}
{viewerjumpto "Example do-file" "ev##dofile"}{...}
{viewerjumpto "Errors" "ev##errors"}{...}
{viewerjumpto "Citation" "ev##citation"}{...}
{viewerjumpto "Authors" "ev##authors"}{...}
{title:Title}

{phang}
{bf:ev} {hline 2} EViews-style expressions in Stata estimation commands


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:ev} [{cmd:,} {it:ev_options}] {cmd::} {it:estimation_command} {it:varlist_with_expressions} [{it:weight}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,} {it:command_options}]

{synoptset 22 tabbed}{...}
{synopthdr:ev_options}
{synoptline}
{synopt:{opt freq(#)}}periods per year; needed for {cmd:@pcha} and {cmd:@pchy} when the time variable is a plain integer{p_end}
{synopt:{opt keep}}keep the generated variables, named {cmd:_ev_*}{p_end}
{synopt:{opt panel(varname)}}panel variable to use for this command only{p_end}
{synopt:{opt time(varname)}}time variable to use for this command only{p_end}
{synopt:{opt delta(#)}}time delta to use for this command only{p_end}
{synopt:{opt any}}allow an estimation command that is not on the supported list{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be declared with {helpb xtset} or {helpb tsset}, or you must use {opt panel()} and {opt time()}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:ev} lets you write transformed variables directly in the variable list of an
estimation command, in the style of EViews, for example {cmd:ln(x)}, {cmd:d(x)},
{cmd:x(-1)} or {cmd:@pch(x)}. It creates temporary variables, runs the command,
and removes them, so the dataset is unchanged after the command finishes
(unless you specify {opt keep}).

{pstd}
Supported estimation commands: {helpb regress} (and its abbreviation {cmd:reg}),
{helpb xtreg}, {helpb areg}, {helpb poisson}, {helpb nbreg}, {helpb logit}, {helpb probit},
{helpb ologit}, {helpb oprobit}, {helpb tobit}, {helpb qreg}, {helpb rreg}, {helpb newey},
{helpb glm}, {helpb xtpoisson}, {helpb xtlogit}, {helpb xtprobit}, {helpb xtnbreg},
{helpb mixed}, {helpb xtmixed}, {cmd:reghdfe} and {cmd:ppmlhdfe}.
Other commands stop with error 199 unless you specify {opt any}.

{pstd}
Stored results and {cmd:e(sample)} are preserved, so {helpb predict} and
postestimation commands work afterwards. Factor-variable notation such as
{cmd:i.country} passes through unchanged. Weights, {cmd:if}, {cmd:in} and
options such as {cmd:vce()} and {cmd:absorb()} are passed to the estimation command.

{pstd}
If the data are declared with a time delta other than 1, {cmd:ev} inherits it for
the command and restores the original setting afterwards.


{marker options}{...}
{title:Options}

{phang}
{opt freq(#)} sets the number of periods per year (1 annual, 4 quarterly, 12 monthly).
Required for {cmd:@pcha} and {cmd:@pchy} when the time variable is a plain integer
(such as year); without it, the command stops with error 198.
For Stata date formats such as {cmd:%tq}, the frequency is taken from the format.

{phang}
{opt keep} keeps the generated variables in the data, named with the prefix
{cmd:_ev_}. Use it when you want to {cmd:predict} from the model or when
coefficient labels should show readable names (for {cmd:mixed}, without
{opt keep} the labels can show internal temporary names). Drop them with
{cmd:drop _ev_*}.

{phang}
{opt panel(varname)} and {opt time(varname)} declare the structure for this one
command, for data that are not {cmd:xtset} or {cmd:tsset}. The previous
(undeclared) state is restored afterwards.

{phang}
{opt delta(#)} sets the time delta for this one command.

{phang}
{opt any} allows an estimation command that is not on the supported list.
Results for such commands are not tested.


{marker functions}{...}
{title:Functions}

{synoptset 24}{...}
{synopt:{it:expression}}meaning{p_end}
{synoptline}
{synopt:{cmd:ln(x)}}natural logarithm{p_end}
{synopt:{cmd:x^2}}power{p_end}
{synopt:{cmd:x/y}, {cmd:x-y}}ratio, difference; a hyphen is always subtraction, never a variable range{p_end}
{synopt:{cmd:x(-1)}}one-period lag{p_end}
{synopt:{cmd:x(-1 to -3)}}lags 1 to 3, as separate regressors{p_end}
{synopt:{cmd:x(1)}}one-period lead{p_end}
{synopt:{cmd:d(x)}}first difference{p_end}
{synopt:{cmd:d(x,n)}}n-th difference{p_end}
{synopt:{cmd:d(x,n,s)}}n-th difference and one seasonal difference of order s{p_end}
{synopt:{cmd:dlog(x)}}first difference of the log{p_end}
{synopt:{cmd:d(ln(x))}}functions may be nested{p_end}
{synopt:{cmd:@pch(x)}}percent change over the previous period{p_end}
{synopt:{cmd:@pcha(x)}}percent change at an annual rate (needs the frequency){p_end}
{synopt:{cmd:@pchy(x)}}percent change over the same period a year ago (needs the frequency){p_end}
{synopt:{cmd:@movav(x,n)}}moving average of n periods{p_end}
{synopt:{cmd:@trend}, {cmd:@trend(base)}}linear time trend, optionally with base period{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
In panel data, lags, leads and differences are computed within each panel.
An unknown function name stops with error 198.


{marker examples}{...}
{title:Examples}

{pstd}Setup (declare the data first):{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Log, power and lag transformations:{p_end}
{phang2}{cmd:. ev: regress invest ln(mvalue) ln(kstock)}{p_end}
{phang2}{cmd:. ev: regress invest mvalue kstock^2}{p_end}
{phang2}{cmd:. ev: regress invest mvalue(-1 to -3) kstock}{p_end}

{pstd}Differences and growth rates:{p_end}
{phang2}{cmd:. ev: regress invest d(mvalue) dlog(kstock)}{p_end}
{phang2}{cmd:. ev: regress invest d(ln(mvalue)) kstock}{p_end}
{phang2}{cmd:. ev: regress invest d(mvalue,1,2)}{p_end}
{phang2}{cmd:. ev: regress invest @pch(mvalue) kstock}{p_end}
{phang2}{cmd:. ev, freq(1): regress invest @pcha(mvalue)}{p_end}

{pstd}Moving average and trend:{p_end}
{phang2}{cmd:. ev: regress invest @movav(mvalue,3) kstock}{p_end}
{phang2}{cmd:. ev: regress invest @trend ln(mvalue)}{p_end}

{pstd}Other estimators, weights, {cmd:if} and options:{p_end}
{phang2}{cmd:. ev: xtreg invest ln(mvalue) d(kstock), fe vce(cluster company)}{p_end}
{phang2}{cmd:. ev: areg invest ln(mvalue) kstock^2, absorb(company)}{p_end}
{phang2}{cmd:. ev: regress invest ln(mvalue) i.company}{p_end}
{phang2}{cmd:. ev: poisson patents ln(mvalue) kstock}{p_end}
{phang2}{cmd:. ev: regress invest ln(mvalue) d(kstock) [aw = kstock] if year > 1940, vce(robust)}{p_end}

{pstd}Keep the generated variables and predict:{p_end}
{phang2}{cmd:. ev, keep: regress invest ln(mvalue) d(kstock)}{p_end}
{phang2}{cmd:. predict double yhat}{p_end}
{phang2}{cmd:. drop yhat _ev_*}{p_end}

{pstd}Data without a declared structure:{p_end}
{phang2}{cmd:. xtset, clear}{p_end}
{phang2}{cmd:. ev, panel(company) time(year): regress invest d(mvalue) ln(kstock)}{p_end}


{marker dofile}{...}
{title:Example do-file}

{pstd}
The package includes {cmd:ev_examples.do}, which builds a small hypothetical
panel (10 companies, 1935-1954) and a quarterly series, then runs the
examples above on that simulated data. No outside dataset or internet
connection is needed. The data are for illustration only and do not
represent real observations.

{pstd}
To locate and run the file, type:

{phang2}{cmd:. findfile ev_examples.do}{p_end}
{phang2}{cmd:. do "`r(fn)'"}{p_end}

{pstd}
The do-file clears the data in memory, so save your work first. It sets the
seed to 20261105, so every run gives the same results.


{marker errors}{...}
{title:Errors}

{synoptset 10}{...}
{synopt:{bf:459}}the data are not declared with {cmd:xtset}/{cmd:tsset} and no {opt panel()}/{opt time()} was given{p_end}
{synopt:{bf:198}}unknown function name, or {cmd:@pcha}/{cmd:@pchy} used without {opt freq()} on a plain-integer time variable{p_end}
{synopt:{bf:199}}the estimation command is not on the supported list and {opt any} was not specified{p_end}
{p2colreset}{...}


{marker citation}{...}
{title:Citation}

{pstd}
If you use {cmd:ev} in your research, please cite it as:

{phang}
Yeung, M., and Tao, A. 2026. ev: Stata module for EViews-style expressions in
estimation commands.
{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Matthew Yeung and Aaron Tao{break}
School of Open Learning, Hong Kong Metropolitan University{break}
{browse "mailto:myeung@hkmu.edu.hk":myeung@hkmu.edu.hk}
{p_end}
