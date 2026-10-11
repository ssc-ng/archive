{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "regress postestimation time series" "help regress_postestimation_time_series"}{...}
{viewerjumpto "Syntax" "mispauto_postestimation##syntax"}{...}
{viewerjumpto "Description" "mispauto_postestimation##desc"}{...}
{viewerjumpto "Supported estimators" "mispauto_postestimation##support"}{...}
{viewerjumpto "What is reused" "mispauto_postestimation##reuse"}{...}
{viewerjumpto "The e() guarantee" "mispauto_postestimation##guarantee"}{...}
{viewerjumpto "Relation to the built-ins" "mispauto_postestimation##builtins"}{...}
{viewerjumpto "Examples" "mispauto_postestimation##examples"}{...}

{title:Title}

{phang}
{bf:mispauto postestimation} {hline 2} Running mispauto on the model already in
memory


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto} {it:subcommand} {ifin} [{cmd:,} {it:options}]

{pstd}
That is, with the varlist omitted. The dependent variable and the regressors are
taken from the last estimation command.

{pstd}
{helpb mispauto_ghutton:mispauto ghutton} is the exception: it always needs an
explicit instrument list, because the instruments are what the procedure is
about and {cmd:e()} does not record which of them were excluded.


{marker desc}{...}
{title:Description}

{pstd}
Applied work normally fits the model first and asks the diagnostic questions
afterwards. Every subcommand except {cmd:ghutton} therefore accepts an empty
varlist and reads the model back from {cmd:e()}, so the usual sequence is

{phang2}{cmd:. regress consump wagepriv wagegovt}{p_end}
{phang2}{cmd:. mispauto godfrey}{p_end}

{pstd}
rather than retyping the specification. The two forms give identical results on
the same sample.


{marker support}{...}
{title:Supported estimators}

{pstd}
{cmd:mispauto} runs as postestimation after:

{p2colset 9 24 26 2}{...}
{p2col :{helpb regress}}the intended case, and the one the four papers assume{p_end}
{p2col :{helpb newey}}accepted; the diagnostics are recomputed from OLS
residuals, so the HAC covariance matrix of the fit is not used{p_end}
{p2col :{helpb prais}}accepted; note that the strategies are designed to decide
{it:whether} an AR(1) correction is appropriate, so running them after one has
already been applied answers a different question{p_end}
{p2col :{helpb ivregress}}accepted for the varlist only{p_end}
{p2colreset}{...}

{pstd}
Anything else exits with error 301 and a message naming the supported
estimators. This is deliberate rather than permissive: the four strategies are
derived for a linear regression with strictly exogenous regressors estimated by
least squares, and silently applying them to, say, a panel or a nonlinear fit
would produce numbers with no inferential standing.

{pstd}
{bf:Panel data are refused.} If the data are {helpb xtset} with a panel
variable, {cmd:mispauto} exits with error 459 and says so. All four strategies
are single-time-series procedures.


{marker reuse}{...}
{title:What is taken from e(), and what is not}

{p2colset 9 26 28 2}{...}
{p2col :{cmd:e(depvar)}}the dependent variable{p_end}
{p2col :{cmd:colnames e(b)}}the regressors, with {cmd:_cons} removed{p_end}
{p2col :{cmd:e(sample)}}the estimation sample. The diagnostics are restricted to
it, so {cmd:if} and {cmd:in} on the {cmd:mispauto} call can only narrow the
sample further, never widen it.{p_end}
{p2colreset}{...}

{pstd}
{bf:Nothing else is reused.} In particular the coefficient vector and covariance
matrix of the fit are ignored: every statistic is recomputed from a fresh OLS
fit on the marked sample. This matters after {cmd:newey} and {cmd:prais}, where
{cmd:e(b)} is not the OLS estimator.

{pstd}
Because the regressor list comes from {cmd:colnames e(b)}, time-series operators
are carried through as written, so {cmd:L.y} in the original {cmd:regress} call
reappears as {cmd:L.y}. That is what makes
{helpb mispauto_godfrey:mispauto godfrey, lagdep} able to find the lagged
dependent variable it needs.


{marker guarantee}{...}
{title:The e() guarantee}

{pstd}
{bf:Your estimation results survive the call.} Every subcommand fits models
internally, which would otherwise overwrite {cmd:e()}. Whatever was there before
is put back before the command returns, including on an error exit.

{pstd}
Two different mechanisms are used, for a reason worth recording.
{cmd:thursby}, {cmd:godfrey} and {cmd:knottnerus} refit with plain
{helpb regress} and restore afterwards. {cmd:ghutton} must call the built-in
{helpb hausman}, which uses the estimates-store system itself, so it protects
{cmd:e()} with {helpb estimates store} and {helpb estimates restore} rather than
with {cmd:_estimates hold}; the two cannot be combined.

{pstd}
Temporary variables are named with a {cmd:__mpa_} prefix and dropped on exit.
If a call is interrupted, {cmd:capture drop __mpa_*} clears any remainder.


{marker builtins}{...}
{title:Relation to the Stata built-ins}

{pstd}
{cmd:mispauto} calls Stata's own commands wherever one already computes the
right quantity, so results reconcile:

{p2colset 9 32 34 2}{...}
{p2col :{bf:Durbin's S-test}}is
{helpb regress postestimation time series##durbinalt:estat durbinalt} at
{cmd:lags(1)}, called directly{p_end}
{p2col :{bf:Sargan's J}}is
{helpb ivregress postestimation##overid:estat overid}, called directly{p_end}
{p2col :{bf:Hausman's statistic}}is {helpb hausman}, called directly{p_end}
{p2colreset}{...}

{pstd}
Three quantities are computed here because no built-in provides them:

{p2colset 9 32 34 2}{...}
{p2col :{bf:the exact DW p-value}}{cmd:estat dwatson} returns only
{cmd:r(dw)}{p_end}
{p2col :{bf:the truncation lag}}by the White{c 150}Domowitz procedure{p_end}
{p2col :{bf:Godfrey's equation (18)}}its auxiliary regression excludes the
regressors, unlike {cmd:estat bgodfrey} and {cmd:estat durbinalt}{p_end}
{p2colreset}{...}

{pstd}
{bf:Two places where mispauto and a built-in will legitimately differ.} First,
{cmd:estat ovtest} without {cmd:rhs} uses powers of the fitted values, whereas
{cmd:mispauto} defaults to powers of the regressors, which is Thursby's choice;
{cmd:resetvars(poy)} reproduces the built-in's set. Second, the robust Wald
statistic of Godfrey's equation (10) is asymptotic and carries no
{cmd:n/(n-k)} adjustment, while {cmd:regress, vce(robust)} applies one, so the
two differ by exactly that factor. Both points are documented in
{helpb mispauto_methods:mispauto methods}.


{marker examples}{...}
{title:Examples}

{pstd}The usual workflow{p_end}
{phang2}{cmd:. webuse klein, clear}{p_end}
{phang2}{cmd:. tsset yr}{p_end}
{phang2}{cmd:. regress consump wagepriv wagegovt}{p_end}
{phang2}{cmd:. mispauto knottnerus}{p_end}
{phang2}{cmd:. mispauto godfrey}{p_end}

{pstd}The estimation results are still there afterwards{p_end}
{phang2}{cmd:. regress}{p_end}

{pstd}Narrowing the sample{p_end}
{phang2}{cmd:. regress consump wagepriv wagegovt}{p_end}
{phang2}{cmd:. mispauto godfrey if yr >= 1925}{p_end}

{pstd}Looping over specifications and tabulating the verdicts{p_end}
{phang2}{cmd:. foreach spec in "wagepriv" "wagepriv wagegovt" "wagepriv wagegovt taxnetx" {c -(}}{p_end}
{phang2}{cmd:.         quietly regress consump `spec'}{p_end}
{phang2}{cmd:.         quietly mispauto godfrey, notable}{p_end}
{phang2}{cmd:.         display "`spec' -> `r(verdict)'"}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
