{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "mispauto thursby" "help mispauto_thursby"}{...}
{vieweralsosee "mispauto knottnerus" "help mispauto_knottnerus"}{...}
{viewerjumpto "Syntax" "mispauto_godfrey##syntax"}{...}
{viewerjumpto "Description" "mispauto_godfrey##desc"}{...}
{viewerjumpto "Options" "mispauto_godfrey##options"}{...}
{viewerjumpto "The sequence" "mispauto_godfrey##seq"}{...}
{viewerjumpto "Interpreting the output" "mispauto_godfrey##interp"}{...}
{viewerjumpto "Remarks" "mispauto_godfrey##remarks"}{...}
{viewerjumpto "Examples" "mispauto_godfrey##examples"}{...}
{viewerjumpto "Stored results" "mispauto_godfrey##results"}{...}

{title:Title}

{phang}
{bf:mispauto godfrey} {hline 2} Godfrey's (1987) ordered sequence of hypotheses


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto godfrey} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt lev:el(#)}}overall nominal level in percent; default {cmd:level(5)}{p_end}
{synopt :{opt lev:els(# # #)}}levels for (b), (c) and (d) separately, in
percent{p_end}

{syntab:Testing (b): misspecification}
{synopt :{opt trunc:ate(spec)}}truncation lag: {cmd:auto}, {cmd:seasonal}, or an
integer; default {cmd:auto}{p_end}
{synopt :{opt wdr:ule(rule)}}with {cmd:auto}: {cmd:last} or {cmd:first}
significant lag; default {cmd:last}{p_end}
{synopt :{opt ker:nel(k)}}{cmd:truncated} or {cmd:bartlett}; default
{cmd:truncated}{p_end}
{synopt :{opt resetv:ars(set)}}{cmd:pox}, {cmd:poy}, {cmd:ts} or {cmd:pc};
default {cmd:pox}{p_end}
{synopt :{opt resetp:owers(numlist)}}powers to use; default {cmd:2 3 4}{p_end}

{syntab:Testing (c) and (d): the error model}
{synopt :{opt q(#)}}order of the AR(p+q) alternative; default is one less than
the detected period{p_end}
{synopt :{opt p(#)}}order of the AR(p) null; default {cmd:p(1)}{p_end}
{synopt :{opt dte:st(m)}}test of (d): {cmd:t} or {cmd:dw}; default {cmd:t}{p_end}

{syntab:Lagged dependent variables}
{synopt :{opt lagd:ep}}use Godfrey's section IV likelihood-ratio route{p_end}

{syntab:Reporting}
{synopt :{opt g:raph}}draw the annotated residual correlogram{p_end}
{synopt :{opt n:ame(string)}}name for the graph{p_end}
{synopt :{opt notable}}suppress display{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{pstd}
{cmd:mispauto godfrey} implements the strategy Godfrey (1987) proposed as a
replacement for Thursby's. Four hypotheses are ordered from the least to the
most restrictive:

{p2colset 9 16 18 2}{...}
{p2col :{bf:(a)}}the regression function is misspecified and the errors are
ARMA of unknown order{p_end}
{p2col :{bf:(b)}}the regression function is correct and the errors are ARMA of
unknown order{p_end}
{p2col :{bf:(c)}}the regression function is correct and the errors are AR(1){p_end}
{p2col :{bf:(d)}}the regression function is correct and the errors are
independent{p_end}
{p2colreset}{...}

{pstd}
Testing proceeds along the sequence and stops at the first rejection; the last
hypothesis not rejected is adopted. The overall level is therefore at most the
sum of the three component levels, which is why the default allocation is
Bonferroni rather than Thursby's product rule.

{pstd}
The decisive feature is the first test. It checks for misspecification using an
{it:autocorrelation-consistent} covariance matrix, so a rejection cannot be
blamed on serial correlation. Thursby's RESET has no such protection, and
Porter and Kashyap (1984) showed what that costs: see the Remarks in
{helpb mispauto}.


{marker options}{...}
{title:Options}

{phang}
{opt levels(# # #)} overrides the Bonferroni split and sets the levels of the
three tests directly, in percent. The sum is reported as the overall level.

{phang}
{opt truncate(spec)} sets the truncation lag {cmd:j} in Godfrey's
{cmd:Sigma_j}. {cmd:auto}, the default, implements the selection procedure of
White and Domowitz (1984, section 4) that Godfrey refers to but does not
reproduce: for each lag an auxiliary regression of {cmd:e(t)e(t-tau)} on the
distinct elements of {cmd:x(t)x(t-tau)'} yields a chi-squared statistic, and
lags are admitted using Bonferroni-adjusted levels, subject to their growth
condition {cmd:j = o(T^(1/3))}. The joint statistic over all candidate lags is
reported alongside. {cmd:seasonal} uses the period from {helpb tsset}, which is
Godfrey's only published guidance. An integer sets it directly.

{phang}
{opt wdrule(rule)} decides, among the lags found significant, which one sets
{cmd:j}. {cmd:last}, the default, takes the largest significant lag.
{cmd:first} stops at the lag before the first insignificant one, which is the
stricter reading of White and Domowitz. {bf:The default is not the stricter
reading on purpose:} a pure seasonal error has an insignificant first lag and a
large seasonal lag, so a first-stop rule returns {cmd:j = 0} and discards the
autocorrelation entirely -- exactly the case this package exists to diagnose.

{phang}
{opt kernel(k)} weights {cmd:Sigma_j}. {cmd:truncated}, the default, is the
uniform weighting Godfrey's equation (10) literally specifies. It is not
guaranteed positive semi-definite; when it is not, the command uses a spectral
generalized inverse that keeps the positive eigenvalues, reports the rank
actually used as the degrees of freedom, and prints a warning. It never
switches kernel silently. {cmd:bartlett} routes the computation through
{helpb newey} and is positive semi-definite by construction.

{phang}
{opt q(#)} is the order of the AR(1+q) alternative in the test of (c). Godfrey
suggests 3 for quarterly and 11 or 12 for monthly data "otherwise the test will
lack power in the presence of pure seasonal autocorrelation". The default is
one less than the period detected from {helpb tsset}, so quarterly data give
{cmd:q(3)} and monthly data {cmd:q(11)} automatically.

{phang}
{opt p(#)} generalises the null to AR(p). The F test then applies to the last
{cmd:q} coefficients and is appropriate against both AR(p+q) and ARMA(p,q).

{phang}
{opt lagdep} switches to the route of Godfrey's section IV, for models that
contain a lagged dependent variable. The White and Domowitz results do not
apply there, so an AR(1+q) error model is imposed, (b) and (c) are tested by
likelihood ratio using {helpb arima} and {helpb lrtest}, and (d) is tested by
Durbin's h. The command requires {cmd:L.}{it:depvar} to be among the regressors
and refuses with a message otherwise, because Durbin's h needs the variance of
that coefficient specifically.


{marker seq}{...}
{title:The sequence, and what to do at each exit}

{p2colset 9 26 28 2}{...}
{p2col :{bf:(b) rejected}}adopt {bf:(a)}. The regression function is wrong even
after allowing for arbitrary autocorrelation. Respecify. Do not instrument, do
not AR-correct.{p_end}
{p2col :{bf:(c) rejected}}adopt {bf:(b)}. The function is fine but the errors
are not AR(1). Either model the error process with {helpb arima}, or keep OLS
with an autocorrelation-consistent covariance matrix ({helpb newey}). Godfrey
recommends Amemiya's (1973) generalised least squares with an estimated
autocovariance matrix, which is asymptotically optimal for quite general error
processes.{p_end}
{p2col :{bf:(d) rejected}}adopt {bf:(c)}. AR(1) errors. Use {helpb prais},
or {cmd:prais, corc}, or Hildreth{c 150}Lu.{p_end}
{p2col :{bf:nothing rejected}}adopt {bf:(d)}. Report OLS.{p_end}
{p2colreset}{...}


{marker interp}{...}
{title:Interpreting the output}

{pstd}
The header reports the truncation lag actually used and how it was chosen, the
values of {cmd:q} and {cmd:p}, the kernel, and the detected periodicity. Check
these first: a {cmd:j} of zero on data you believe to be autocorrelated means
the White{c 150}Domowitz procedure found no significant autocovariance, and the
first test is then only heteroskedasticity-robust.

{pstd}
The {cmd:White-Domowitz joint test} line is the sum of the individual lag
statistics across all candidate lags, which is valid because they are
asymptotically independent. A large joint statistic with a small selected
{cmd:j} is a signal to inspect the correlogram.

{pstd}
If the warning about positive definiteness appears, the degrees of freedom in
the (b) row are the rank actually used, not the number of test variables. Rerun
with {cmd:kernel(bartlett)} and see whether the conclusion survives.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Do not set}{space 1}{opt truncate()}{space 1}{bf:generously.} Wald tests
based on a heteroskedasticity- or autocorrelation-consistent covariance matrix
over-reject in finite samples, and the distortion grows with the number of
lags. In a Monte Carlo on a correctly specified model with independent errors at
T = 200, forcing {cmd:j = 6} produced rejection rates near 33% for the
truncated kernel and 24% for the Bartlett kernel computed by Stata's own
{helpb newey}, against a nominal 5%, while the plain OLS F test held its size.
Two kernels failing together, one of them StataCorp's code, places the problem
in the statistic rather than in any implementation. This is the reason the
truncation lag is selected from the data by default.

{pstd}
{bf:Godfrey reports no size or power evidence for this sequence.} His paper is
analytical. The claims made for it here are the ones he makes: that it is not
subject to Knottnerus's criticisms, and that its first stage is robust to
autocorrelation in a way Thursby's is not.

{pstd}
{bf:The auxiliary regression of equation (18) excludes the regressors on
purpose.} Breusch{c 150}Godfrey and {cmd:estat durbinalt} include them; Godfrey's
derivation, which fixes {cmd:beta} at the OLS estimate, does not. This is the
one place where {cmd:mispauto} deliberately computes something different from
the familiar Stata built-ins. See {helpb mispauto_methods:mispauto methods}.

{pstd}
{bf:This strategy assumes strictly exogenous regressors}, as Godfrey states in
his abstract. With a lagged dependent variable use {opt lagdep}; with an
endogenous regressor the question is a different one and belongs to
{helpb mispauto_ghutton:mispauto ghutton}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mispauto godfrey y x1 x2}{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2, graph}{p_end}

{pstd}Quarterly data: q defaults to 3{p_end}
{phang2}{cmd:. tsset qtr, quarterly}{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2}{p_end}

{pstd}Check the kernel choice does not drive the conclusion{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2, kernel(bartlett)}{p_end}

{pstd}Fix the truncation lag and the alternative order{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2, truncate(4) q(8)}{p_end}

{pstd}Spend the level unevenly{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2, levels(2.5 1.25 1.25)}{p_end}

{pstd}With a lagged dependent variable{p_end}
{phang2}{cmd:. mispauto godfrey y L.y x1, lagdep}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}, {cmd:r(k)}, {cmd:r(level)} sample and level{p_end}
{synopt:{cmd:r(alpha_overall)}}sum of the three component levels{p_end}
{synopt:{cmd:r(truncate)}}truncation lag used{p_end}
{synopt:{cmd:r(wd_maxlag)}}largest candidate lag considered{p_end}
{synopt:{cmd:r(wd_joint)}}, {cmd:r(wd_p)} the White{c 150}Domowitz joint
test{p_end}
{synopt:{cmd:r(q)}}, {cmd:r(p)} orders used{p_end}
{synopt:{cmd:r(stat_b)}}, {cmd:r(df_b)}, {cmd:r(p_b)}, {cmd:r(sig_b)} test of
(b){p_end}
{synopt:{cmd:r(rank_b)}}rank used for (b); differs from {cmd:r(df_b)} only when
{cmd:Sigma_j} was not positive definite{p_end}
{synopt:{cmd:r(nonpd)}}1 if the generalized inverse was needed{p_end}
{synopt:{cmd:r(stat_c)}}, {cmd:r(df_c)}, {cmd:r(p_c)}, {cmd:r(sig_c)} test of
(c){p_end}
{synopt:{cmd:r(stat_d)}}, {cmd:r(p_d)}, {cmd:r(sig_d)} test of (d){p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:MS+ARMA}, {cmd:NAR}, {cmd:AR(1)} or {cmd:NP}{p_end}
{synopt:{cmd:r(hypothesis)}}the hypothesis adopted: {cmd:(a)} to {cmd:(d)}{p_end}
{synopt:{cmd:r(kernel)}}, {cmd:r(trunctype)}, {cmd:r(period)} settings used{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
