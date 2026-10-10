{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thforecast" "help thforecast"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thsim##syntax"}{...}
{viewerjumpto "Description" "thsim##description"}{...}
{viewerjumpto "Specifying the model" "thsim##spec"}{...}
{viewerjumpto "Why burn-in is not a detail" "thsim##burn"}{...}
{viewerjumpto "Options" "thsim##options"}{...}
{viewerjumpto "Using it for size and power" "thsim##power"}{...}
{viewerjumpto "What is NOT provided" "thsim##limits"}{...}
{viewerjumpto "Examples" "thsim##examples"}{...}
{viewerjumpto "Stored results" "thsim##results"}{...}
{viewerjumpto "References" "thsim##refs"}{...}
{title:Title}

{phang}
{bf:thsim} {hline 2} Simulate data from a threshold model you specify


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thsim} [{it:newvarstub}] {cmd:,} {opt mod:el(string)} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt mod:el(string)}}{opt tr}, {opt kink}, {opt setar}, {opt star} or {opt tvar}{p_end}
{synopt:{opt n(#)}}observations to keep; default 500{p_end}
{synopt:{opt b:urn(#)}}observations to discard first; default 500{p_end}
{synopt:{opt c:oef(string)}}coefficients, regimes or equations separated by {bf:|}{p_end}
{synopt:{opt coef2(string)}}the second regime, for {opt model(tvar)}{p_end}
{synopt:{opt th:resholds(numlist)}}the threshold(s){p_end}
{synopt:{opt ar(numlist)}}which lags enter; default {cmd:ar(1)}{p_end}
{synopt:{opt del:ay(#)}}the regime depends on y(t-#); default 1{p_end}
{synopt:{opt sl:ope(numlist)}}two slopes, for {opt model(tr)} and {opt model(kink)}{p_end}
{synopt:{opt nocons:tant}}no constant in the design{p_end}

{syntab:Smooth transition}
{synopt:{opt g:amma(#)}}transition speed; default 5{p_end}
{synopt:{opt c(#)}}, {opt c2(#)}location parameter(s){p_end}
{synopt:{opt ty:pe(string)}}{opt lstar1} (default), {opt estar} or {opt lstar2}{p_end}

{syntab:Errors}
{synopt:{opt sig:ma(#)}}error standard deviation; default 1{p_end}
{synopt:{opt e:rrors(string)}}{opt normal} (default), {opt t} or {opt resample}{p_end}
{synopt:{opt df(#)}}degrees of freedom for {opt errors(t)}; default 5{p_end}
{synopt:{opth res:iduals(varname)}}source for {opt errors(resample)}{p_end}
{synopt:{opt smat(matname)}}innovation covariance for {opt model(tvar)}{p_end}

{syntab:Shape and output}
{synopt:{opt lag:s(#)}}VAR lag order, for {opt model(tvar)}; default 1{p_end}
{synopt:{opt k(#)}}number of equations, for {opt model(tvar)}; default 2{p_end}
{synopt:{opt tv:ar(name)}}name for the time variable; default {bf:t}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt clear}}clear the data first{p_end}
{synopt:{opt replace}}overwrite existing variables{p_end}
{synoptline}
{p 4 6 2}* {opt model()} is required.{p_end}
{p 4 6 2}
The recursive models ({opt setar}, {opt star}, {opt tvar}) leave the data
{helpb tsset}. {cmd:thsim} is {helpb return:rclass}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thsim} generates data from a threshold model whose parameters {it:you}
write down. It is the companion to {helpb thforecast}, which simulates forward
from a {bf:fitted} model: the recursions are the same arithmetic, and the
difference is where the parameters come from.

{pstd}
What it is for:

{p 8 8 2}
o {bf:size and power studies}. Generate under the null, run a test, count
rejections; then generate under an alternative and count again. Every test in
THRESHKIT was checked this way, and the power checks are in the certification
suites.{p_end}
{p 8 8 2}
o {bf:checking that a command recovers what it should}. Simulate with a known
threshold and delay, fit, and see whether the estimate lands on it. If it does
not on 500 clean observations, it will not on your data.{p_end}
{p 8 8 2}
o {bf:teaching and examples}. A simulated SETAR with slopes +0.8 and -0.8
makes the point of the whole package in one picture.{p_end}

{pstd}
The parameterisations match the commands exactly, so a simulated series can be
handed straight to {helpb thtar}, {helpb thstar} or {helpb thtvar} and the
numbers are comparable without translation.


{marker spec}{...}
{title:Specifying the model}

{pstd}
{bf:model(tr)} — cross-sectional threshold regression. {opt slope(b1 b2)} gives
the slope on x below and above the threshold, and {opt thresholds(g)} the
threshold in q (default 0). x and q are independent standard normals, which is
the {it:easy} case: a q correlated with x makes the threshold harder to find
and is the realistic one. Creates {bf:x}, {bf:q} and the outcome.

{pstd}
{bf:model(kink)} — the continuous version. {opt slope(b1 b2)} gives the slope
below the kink and the {bf:change} in slope above it, so the fitted function is
continuous at the kink by construction. A jump model fitted to this will find a
spurious gap, which is worth seeing once.

{pstd}
{bf:model(setar)} — self-exciting threshold autoregression. {opt coef()} holds
one row per regime separated by {bf:|}: the coefficients on {opt ar()} in
order, then the constant unless {opt noconstant}.
{opt thresholds()} needs one fewer value than there are rows, and {opt delay()}
says which lag decides the regime.

{p 8 8 2}
{cmd:thsim y, model(setar) ar(1) coef(0.8 0 | -0.5 0) thresholds(0)}

{pstd}
{bf:model(star)} — smooth transition. {opt coef()} takes exactly {bf:two} rows:
the {bf:linear} block and the {bf:transition} block, so the upper regime is
their {it:sum}. That is the same parameterisation {helpb thstar} reports, which
is what makes a simulated series directly usable as a reference for it.
{opt gamma()} is the transition speed, {opt c()} the location.

{p 8 8 2}
{cmd:thsim y, model(star) ar(1) coef(0.8 0 | -1.5 0) gamma(4) c(0)}

{pstd}
{bf:model(tvar)} — two-regime threshold VAR. {opt coef()} and {opt coef2()}
hold one regime each, equation by equation separated by {bf:|}, with the
{bf:constant first} and then the lags — the layout {helpb thtvar}'s
{cmd:e(B1)} uses. {opt k()} is the number of equations, {opt lags()} the lag
order, and the regime is decided by the {it:first} variable's lag
{opt delay()}. {opt smat()} gives the innovation covariance.

{p 8 8 2}
{cmd:thsim y, model(tvar) k(2) lags(1) delay(1)}{break}
{p 12 12 2}
{cmd:coef(0 0.7 0.2 | 0 0.3 0.4) coef2(0 -0.6 0.2 | 0 0.3 0.4)}


{marker burn}{...}
{title:Why burn-in is not a detail}

{pstd}
A threshold recursion started from zero spends its first observations in
whichever regime {it:contains} zero. The regime mix of a short series simulated
without burn-in therefore reflects the starting value rather than the model's
stationary law — and a size study built on it reports the size of a
{bf:different model}.

{pstd}
The default discards 500 observations. {cmd:burn(0)} is allowed and prints a
warning, because it is occasionally what you want (reproducing someone else's
code that omitted it, for instance).

{pstd}
How much is enough depends on the persistence: a near-unit-root regime mixes
slowly, so 500 may not be enough at 0.98 and is plenty at 0.5. The cheap check
is to simulate twice with different burn-in and compare the share of
observations in each regime; if it moves, raise it.


{marker options}{...}
{title:Options}

{phang}
{opt errors(normal|t|resample)} sets the innovation distribution.
{opt errors(t)} with {opt df()} gives fat tails, rescaled so the standard
deviation is still {opt sigma()} — otherwise changing {opt df()} would change
two things at once. {opt errors(resample)} draws with replacement from
{opth residuals(varname)}, {bf:centred} first, which is how you simulate with
the error distribution of real data: fit a model to your series, predict the
residuals, and feed them back.

{phang}
{opt smat(matname)} is the {it:k} x {it:k} innovation covariance for
{opt model(tvar)}; without it the innovations are independent with standard
deviation {opt sigma()}. Supply one when the point of the exercise is the
Cholesky ordering or the orthogonalised responses.

{phang}
{opt seed(string)} sets the seed. A simulation study without one is not
reproducible, and a reported size or power without a seed cannot be checked.


{marker power}{...}
{title:Using it for size and power}

{pstd}
The pattern, with the number of rejections accumulated in a scalar:

{p 8 8 2}
{cmd:. local R = 0}{break}
{cmd:. forvalues i = 1/1000 {c -(}}{break}
{cmd:.     quietly thsim y, model(setar) ar(1) coef(0.5 0 | 0.5 0) ///}{break}
{cmd:.         thresholds(0) n(200) seed(`=20000+`i'') clear}{break}
{cmd:.     quietly thtar y, ar(1) delay(1) test reps(199)}{break}
{cmd:.     if e(p) < 0.05 local ++R}{break}
{cmd:. {c )-}}{break}
{cmd:. display "size = " `R'/1000}

{pstd}
Note that the two regimes share the same coefficients there, so the data are
{it:linear} and the rejection rate estimates the {bf:size}. Change one regime
and the same loop estimates {bf:power}.

{pstd}
Two things that go wrong in practice. First, {bf:use a different seed in every
replication} — the example derives it from the loop index. Reusing one seed
gives a thousand copies of one draw and a size of 0 or 1. Second, {bf:the
bootstrap inside the test needs its own replications}; with {cmd:reps(199)} and
1000 outer draws that is 199,000 fits, so start with 100 outer draws to check
the loop before leaving it to run.


{marker limits}{...}
{title:What is NOT provided}

{phang}
o {bf:No TARMA, no threshold GARCH, no three-regime VAR.} The models are the
ones THRESHKIT fits.

{phang}
o {bf:No exogenous threshold variable in the recursive models.} The regime is
decided by a lag of the simulated series, because an exogenous threshold
variable would have to be simulated too and that is a second model.

{phang}
o {bf:No trend or seasonal terms}, and no exogenous regressors in the
recursive models.

{phang}
o {bf:No panel.} Out of scope for THRESHKIT by design.

{phang}
o {bf:Regime 1 in} {opt model(setar)} {bf:is} y(t-d) {ul:<} {&gamma}, weakly,
matching {helpb thregress}. {helpb thunitroot} uses the strict inequality,
which is its paper's convention; if you are simulating a reference for that
command the observation exactly at the threshold is classified differently,
and with continuous errors that has probability zero.


{marker examples}{...}
{title:Examples}

{pstd}A two-regime SETAR with a sign flip, fitted back{p_end}
{phang2}{cmd:. thsim y, model(setar) ar(1) coef(0.8 0 | -0.8 0) thresholds(0) n(500) seed(1) clear}{p_end}
{phang2}{cmd:. thtar y, ar(1) delay(1) test reps(299)}{p_end}

{pstd}A LINEAR series from the same machinery, for size{p_end}
{phang2}{cmd:. thsim y, model(setar) ar(1) coef(0.5 0 | 0.5 0) thresholds(0) n(500) seed(1) clear}{p_end}
{phang2}{cmd:. thtar y, ar(1) delay(1) test reps(299)}{p_end}

{pstd}A smooth transition, fitted with the cycle{p_end}
{phang2}{cmd:. thsim y, model(star) ar(1 2) coef(0.8 0.1 0 | -1.5 0 0) gamma(4) c(0) n(600) seed(2) clear}{p_end}
{phang2}{cmd:. thstarcycle y, maxar(4)}{p_end}

{pstd}Fat-tailed errors, to see what they do to a test{p_end}
{phang2}{cmd:. thsim y, model(setar) ar(1) coef(0.8 0 | -0.8 0) thresholds(0) errors(t) df(3) n(500) seed(3) clear}{p_end}

{pstd}Errors resampled from real data{p_end}
{phang2}{cmd:. use threshkit_ur, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. quietly thtar dy, ar(1 2) delay(1)}{p_end}
{phang2}{cmd:. predict double eh if e(sample), residuals}{p_end}
{phang2}{cmd:. thsim y, model(setar) ar(1) coef(0.8 0 | -0.8 0) thresholds(0) errors(resample) residuals(eh) n(400) seed(4)}{p_end}

{pstd}A threshold VAR, fitted back{p_end}
{phang2}{cmd:. thsim y, model(tvar) k(2) lags(1) delay(1) thresholds(0) ///}{p_end}
{phang2}{cmd:.     coef(0 0.7 0.2 | 0 0.3 0.4) coef2(0 -0.6 0.2 | 0 0.3 0.4) n(600) seed(5) clear}{p_end}
{phang2}{cmd:. thtvarsel y1 y2, psearch(1 2 3) dsearch(1 2)}{p_end}

{pstd}A cross-sectional threshold regression and its continuous cousin{p_end}
{phang2}{cmd:. thsim y, model(tr) slope(1 -1) n(400) seed(6) clear}{p_end}
{phang2}{cmd:. thregress y x, threshvar(q) test reps(299)}{p_end}
{phang2}{cmd:. thsim y, model(kink) slope(1 -2) n(400) seed(7) clear}{p_end}
{phang2}{cmd:. thkink y, kinkvar(x)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations kept{p_end}
{synopt:{cmd:r(burn)}}observations discarded{p_end}
{synopt:{cmd:r(delay)}}the delay used{p_end}
{synopt:{cmd:r(threshold)}}the threshold, for the cross-sectional designs{p_end}
{synopt:{cmd:r(k)}}, {cmd:r(lags)}for {opt model(tvar)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thsim}{p_end}
{synopt:{cmd:r(model)}}the model simulated{p_end}
{synopt:{cmd:r(errors)}}the error distribution{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(depvars)}the variable(s) created{p_end}


{marker refs}{...}
{title:References}

{phang}
Tong, H. 1990. {it:Non-linear Time Series: A Dynamical System Approach}.
Oxford: Oxford University Press.

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}.

{phang}
Tsay, R. S. 1998. Testing and modeling multivariate threshold models.
{it:Journal of the American Statistical Association} 93: 1188-1202.
{browse "https://doi.org/10.1080/01621459.1998.10473779":doi:10.1080/01621459.1998.10473779}.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com
{p_end}


{title:Also see}

{psee}
Manual: {helpb threshkit}, {helpb threshkit_choose}

{psee}
Online: {helpb thforecast}, {helpb thtar}, {helpb thstar},
{helpb thtvar}, {helpb thregress}, {helpb thkink}
{p_end}
