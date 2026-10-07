{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag all" "help jointdiag_all"}{...}
{viewerjumpto "Description" "jointdiag_postestimation##description"}{...}
{viewerjumpto "Supported estimators" "jointdiag_postestimation##support"}{...}
{viewerjumpto "What is reused from e()" "jointdiag_postestimation##reuse"}{...}
{viewerjumpto "The e() guarantee" "jointdiag_postestimation##guarantee"}{...}
{viewerjumpto "Examples" "jointdiag_postestimation##examples"}{...}

{title:Title}

{phang}
{bf:jointdiag postestimation} {hline 2} Using jointdiag after an estimation
command


{marker description}{...}
{title:Description}

{pstd}
Every {cmd:jointdiag} subcommand can be run in two ways.

{pstd}
{bf:Standalone}, naming the model explicitly:

{phang2}{cmd:. jointdiag lm y x1 x2, lags(2)}{p_end}

{pstd}
{bf:Postestimation}, reading the model from the results in memory:

{phang2}{cmd:. regress y x1 x2}{p_end}
{phang2}{cmd:. jointdiag lm, lags(2)}{p_end}

{pstd}
The two forms give identical answers on the same sample.  The postestimation
form is the one to use in practice, because it inherits {cmd:e(sample)} and so
automatically respects whatever {cmd:if}, {cmd:in} and missing-value
exclusions produced the fit.

{pstd}
Two subcommands are {it:only} postestimation, because they need a fitted
conditional-variance model: {helpb jointdiag_port:port} and
{helpb jointdiag_spec:spec}.  One is only standalone, because it needs the
dependent variable untransformed: {helpb jointdiag_bc:bc}.


{marker support}{...}
{title:Supported estimators}

{synoptset 26 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb jointdiag_lm:lm}}any single-equation fit with
{cmd:e(depvar)} and {cmd:e(b)}; refits internally with {helpb regress}{p_end}
{synopt:{helpb jointdiag_im:im}}same{p_end}
{synopt:{helpb jointdiag_arch:arch}}same{p_end}
{synopt:{helpb jointdiag_bilinear:bilinear}}same{p_end}
{synopt:{helpb jointdiag_score:score}}same{p_end}
{synopt:{helpb jointdiag_mpi:mpi}}same{p_end}
{synopt:{helpb jointdiag_nonnest:nonnest}}standalone only (it needs two model
specifications){p_end}
{synopt:{helpb jointdiag_port:port}}{helpb arch}, {helpb arima}, or any
command supporting {cmd:predict, residuals}; a conditional variance is taken
from {cmd:predict, variance} when available{p_end}
{synopt:{helpb jointdiag_spec:spec}}{helpb regress} and {helpb arch} only{p_end}
{synopt:{helpb jointdiag_bc:bc}}standalone only{p_end}
{synoptline}

{pstd}
If a subcommand cannot work with the estimator in memory it says so and stops
with return code 301 or 322 rather than producing a wrong number.


{marker reuse}{...}
{title:What is reused from e()}

{p 4 7 2}
{bf:*}  {cmd:e(depvar)} becomes the dependent variable.
{p 4 7 2}
{bf:*}  The regressor names come from {cmd:colnames e(b)} with {cmd:_cons}
removed; equation prefixes left by {helpb arch} and {helpb arima} are stripped
and only names that resolve to real variables are kept.
{p 4 7 2}
{bf:*}  {cmd:e(sample)} is intersected with the subcommand's own {cmd:touse},
so the diagnostic is computed on exactly the estimation sample.
{p 4 7 2}
{bf:*}  {cmd:e(cmdline)} is used by {helpb jointdiag_spec:spec} to refit the
model inside the bootstrap.

{pstd}
The time variable comes from {helpb tsset}, not from {cmd:e()}, so the data
must still be {cmd:tsset} when you call the diagnostic.


{marker guarantee}{...}
{title:The e() guarantee}

{pstd}
Every subcommand fits auxiliary models internally {c 150} that is how LM tests
work.  Those fits would ordinarily destroy your estimation results.  They do
not: each subcommand brackets its work with

{phang2}{cmd:tempname _h}{p_end}
{phang2}{cmd:capture _estimates hold `_h', restore nullok}{p_end}

{pstd}
so {cmd:e()} is restored on exit, including when the command stops with an
error.  After any {cmd:jointdiag} call you can carry straight on with
{cmd:predict}, {cmd:test}, {cmd:margins} or another {cmd:estat} as if nothing
had happened.

{pstd}
The one thing to be aware of: {cmd:r()} {it:is} overwritten, as it is by any
{cmd:rclass} command.  Store what you need before the next call.


{marker examples}{...}
{title:Examples}

{pstd}Diagnostics do not disturb the fit{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}
{phang2}{cmd:. jointdiag all}{p_end}
{phang2}{cmd:. test dln_inc = dln_consump}{p_end}
{phang2}{cmd:. predict double resid, residuals}{p_end}

{pstd}Harvesting results into a table{p_end}
{phang2}{cmd:. regress dln_inv dln_inc}{p_end}
{phang2}{cmd:. jointdiag lm, notable}{p_end}
{phang2}{cmd:. matrix T = r(table)}{p_end}
{phang2}{cmd:. matrix list T}{p_end}

{pstd}Looping over lag orders{p_end}
{phang2}{cmd:. forvalues p = 1/6 {c -(}}{p_end}
{phang2}{cmd:.     quietly jointdiag lm, lags(`p') notable}{p_end}
{phang2}{cmd:.     display "p = `p'  LM_I = " %8.3f r(lm_I) "  p = " %6.4f r(p_I)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}After a conditional-variance model{p_end}
{phang2}{cmd:. arch dln_inv dln_inc, ar(1) arch(1) garch(1)}{p_end}
{phang2}{cmd:. jointdiag port, lags(12)}{p_end}
{phang2}{cmd:. jointdiag spec, reps(299) seed(42)}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
