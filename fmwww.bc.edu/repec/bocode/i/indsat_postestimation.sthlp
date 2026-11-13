{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat types" "help indsat_types"}{...}
{vieweralsosee "indsat methods" "help indsat_methods"}{...}
{viewerjumpto "Syntax" "indsat_postestimation##syntax"}{...}
{viewerjumpto "Subcommands" "indsat_postestimation##sub"}{...}
{viewerjumpto "predict" "indsat_postestimation##predict"}{...}
{viewerjumpto "Examples" "indsat_postestimation##examples"}{...}
{title:Title}

{phang}
{bf:indsat postestimation} {hline 2} Postestimation tools for indsat


{marker syntax}{...}
{title:Two kinds of postestimation}

{pstd}
(1) {it:Saturating your own model}: after {cmd:regress}, {cmd:newey} or {cmd:ardl}, type {cmd:indsat ,} {it:saturation}
(see {help indsat##post:post-estimation mode}). (2) {it:Analysing the saturated model}: after {cmd:indsat}, the
subcommands below.{p_end}


{title:Syntax}

{p2colset 5 34 36 2}{...}
{p2col:{cmd:estat dates} [{cmd:,} {opt comp:act}]}table of retained indicators and implied regimes{p_end}
{p2col:{cmd:estat path} [{cmd:,} {opt gen:erate(name)} {opt lr} {opt l:evel(#)}]}intercept (deterministic) coefficient path{p_end}
{p2col:{cmd:estat plot} [{cmd:,} {opt name()} {opt saving(file)} {opt nocomb:ine} {opt ti:tle()}]}four-panel dashboard{p_end}
{p2col:{cmd:estat test} [{cmd:,} {opt hn:ull(#)} {opt cip:val(#)} {opt bias:corr} {opt lr} {opt gr:aph}]}test of the path against a value (Pretis isattest){p_end}
{p2col:{cmd:estat outlier} [{cmd:,} {opt alt:ernative(two.sided|less|greater)}]}Jiao-Pretis proportion and count tests{p_end}
{p2col:{cmd:estat distort} [{cmd:,} {opt boot(#)} {opt seed(#)}]}Jiao-Pretis-Schwarz distortion test{p_end}
{p2col:{cmd:estat biascorr}}1- and 2-step bias-corrected indicator coefficients{p_end}
{p2col:{cmd:estat bias} [{cmd:,} {opt con:stant}]}F-test of retained indicators (+ constant: forecast bias){p_end}
{p2col:{cmd:estat forecast} [{cmd:,} {opt h(#)} {opt gen:erate(stub)} {opt int:ercept} {opt gr:aph}]}forecasts with persistent shifts{p_end}
{p2col:{cmd:estat diag} [{cmd:,} {opt lag:s(#)} {opt arch:lags(#)}]}misspecification tests{p_end}
{p2colreset}{...}

{p 8 16 2}
{cmd:predict} {newvar} [{it:if}] [{it:in}] [{cmd:,} {opt xb} | {opt r:esiduals} | {opt rst:andard} | {opt path} | {opt pathse}]


{marker sub}{...}
{title:Subcommands}

{phang}
{cmd:estat dates} lists every retained indicator with its type, date, coefficient, standard error, t and p
and, when steps are present, a regime table: the level of the intercept in each regime with its exact
standard error. {opt compact} omits the regime table.

{phang}
{cmd:estat path} computes the path {it:mu_t} of the constant plus all retained impulse/step/trend/designed
indicators with exact standard errors and {it:level}% band ({cmd:r(path)}: time, path, se, lower, upper),
the MIS coefficient paths ({cmd:r(mispath)}) and, with {opt lr} and AR terms, the long-run path.

{phang}
{cmd:estat plot} draws (a) actual and fitted values with break dates, (b) scaled residuals with the
selection cut-offs and spikes where |residual| exceeds them, (c) the intercept path and its band,
(d) the MIS coefficient paths or, without MIS, a timeline of retained indicators (size and sign).

{phang}
{cmd:estat test} is Pretis' {it:isattest}: it reports episodes in which the {opt cipval()} band of the path
lies wholly above or below {opt hnull()} (e.g. climate-model bias, forecast bias over time, target
deviations). {opt biascorr} uses the 2-step bias-corrected path (models without covariates).

{phang}
{cmd:estat outlier} tests H0: no outliers, using the number of retained impulses (normal theory of
Johansen & Nielsen 2016 and an exact Poisson test).

{phang}
{cmd:estat distort} tests whether IIS changes the regression coefficients relative to OLS; {opt boot(#)}
adds the clean-sample bootstrap p-value and quantiles.

{phang}
{cmd:estat biascorr} corrects the post-selection bias of retained coefficients.

{phang}
{cmd:estat bias} F-tests the retained indicators jointly (constancy); with {opt constant} also the
constant, which is Ericsson & Reisman's forecast-bias test when {depvar} is a forecast error and the model has
no regressors.

{phang}
{cmd:estat forecast} produces {opt h()}-step forecasts in which impulses end, steps persist, broken trends
extrapolate and AR terms iterate; bands use the error variance and psi-weights. {opt intercept} adds the last
in-sample residual (an intercept correction, Castle, Doornik & Hendry 2026). Future regressor values must be in
the data ({cmd:tsappend} is applied automatically for models without regressors).

{phang}
{cmd:estat diag} reports Breusch-Godfrey, ARCH, Jarque-Bera, Doornik-Hansen, White and RESET tests.


{marker predict}{...}
{title:predict}

{phang}{opt xb} fitted values (default); {opt residuals}; {opt rstandard} residuals/sigma; {opt path} and {opt pathse}
the intercept path and its standard error.{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use indsat_nile, clear}{p_end}
{phang2}{cmd:. indsat flow, super tpval(0.01)}{p_end}
{phang2}{cmd:. estat dates}{p_end}
{phang2}{cmd:. estat plot, saving(nile.png)}{p_end}
{phang2}{cmd:. estat test, hnull(1000) graph}{p_end}
{phang2}{cmd:. estat biascorr}{p_end}
{phang2}{cmd:. estat forecast, h(10) graph}{p_end}
{phang2}{cmd:. predict mu, path}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
