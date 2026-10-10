{smcl}
{* *! version 1.0.0  05oct2026}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thmtar" "help thmtar"}{...}
{vieweralsosee "thsearch" "help thsearch"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thunitroot##syntax"}{...}
{viewerjumpto "Description" "thunitroot##description"}{...}
{viewerjumpto "Options" "thunitroot##options"}{...}
{viewerjumpto "The five statistics, and which to use" "thunitroot##stats"}{...}
{viewerjumpto "Why two bootstraps" "thunitroot##twoboot"}{...}
{viewerjumpto "The partial unit root" "thunitroot##partial"}{...}
{viewerjumpto "Choosing the delay" "thunitroot##delay"}{...}
{viewerjumpto "Relation to dfuller and to thtar" "thunitroot##versus"}{...}
{viewerjumpto "What is NOT provided" "thunitroot##limits"}{...}
{viewerjumpto "A note on Table III" "thunitroot##tableiii"}{...}
{viewerjumpto "Examples" "thunitroot##examples"}{...}
{viewerjumpto "Stored results" "thunitroot##results"}{...}
{viewerjumpto "References" "thunitroot##refs"}{...}
{title:Title}

{phang}
{bf:thunitroot} {hline 2} Threshold autoregression with a near unit root: the
Caner-Hansen (2001) joint threshold and unit-root battery


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thunitroot} {it:varname} {ifin} [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt lags(#)}}lagged differences in the ADF form; default {cmd:lags(1)}{p_end}
{synopt:{opt trend}}include a linear trend as well as the constant{p_end}
{synopt:{opt zt:ype(string)}}{opt long} (default), {opt lagdiff} or {opt laglevel}{p_end}
{synopt:{opt sw:itch(numlist)}}constrained model: which lags switch regime{p_end}

{syntab:Delay}
{synopt:{opt mmin(#)}}smallest delay to search; default {cmd:mmin(1)}{p_end}
{synopt:{opt mmax(#)}}largest delay to search; default = {opt mmin()}{p_end}
{synopt:{opt delay(#)}}report the estimates at this delay instead of the argmin{p_end}

{syntab:Search and inference}
{synopt:{opt trim(#)}}{cmd:0.15} (default), {cmd:0.10} or {cmd:0.05}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 1000, {cmd:reps(0)} skips{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt joint(numlist)}}jointly test whether these lags differ across regimes{p_end}

{syntab:Reporting}
{synopt:{opt reg:imevar(newvar)}}store the regime classification{p_end}
{synopt:{opt level(#)}}confidence level for the coefficient table{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} and the sample must be one unbroken stretch of
the time index.{p_end}
{p 4 6 2}
{cmd:thunitroot} is {helpb estcom:e-class}. {cmd:estat} subcommands:
{bf:regimes}, {bf:delay}, {bf:coefeq}, {bf:bootdist}, {bf:zplot},
{bf:regimeplot}, {bf:table}. {cmd:predict} supports {bf:xb},
{bf:residuals}, {bf:regime} and {bf:zvar}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thunitroot} fits the two-regime augmented Dickey-Fuller regression

{p 8 8 2}
{c 198}y{subscript:t} = {&theta}{subscript:1}' x{subscript:t-1}
1{c -(}Z{subscript:t-1} {c <} {&lambda}{c )-}
+ {&theta}{subscript:2}' x{subscript:t-1}
1{c -(}Z{subscript:t-1} {&ge} {&lambda}{c )-} + e{subscript:t}

{pstd}
with

{p 8 8 2}
x{subscript:t-1} = (y{subscript:t-1}, r{subscript:t}',
{c 198}y{subscript:t-1}, ..., {c 198}y{subscript:t-p})'{break}
{&theta}{subscript:i} = ({&rho}{subscript:i}, {&beta}{subscript:i}',
{&alpha}{subscript:i}')'{break}
r{subscript:t} = 1, or (1, t) with {opt trend}

{pstd}
and reports, at the same time, a test that there is no threshold
({&theta}{subscript:1} = {&theta}{subscript:2}) and four tests that there is a
unit root ({&rho}{subscript:1} = {&rho}{subscript:2} = 0).

{pstd}
The two questions cannot be separated, which is the point of the paper. A
linear {helpb dfuller} that fails to reject may be looking at a series that is
stationary in one regime and not the other; a threshold test that assumes
stationarity may reject because the series is a random walk. Caner and Hansen
derive the joint theory and show that the limit distribution of the threshold
statistic depends on whether {&rho} = 0, which is exactly the thing in
question. {cmd:thunitroot} therefore computes two bootstraps and reports both.

{pstd}
The threshold variable defaults to the {bf:long difference}
Z{subscript:t-1} = y{subscript:t-1} - y{subscript:t-1-m}. That choice is not
cosmetic: Z has to be stationary whether y is I(1) or I(0), because neither is
being assumed, and a long difference of an I(1) series is stationary while its
level is not.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} sets p, the number of lagged differences. It must be at least 1
because the regression is written in ADF form. The delay searched can never
exceed it; see {opt mmax()}.

{phang}
{opt trend} adds a linear trend to both regimes. Include it when the
alternative of interest is trend stationarity: without it the test has very
little power against a series that reverts to a trend rather than to a level.
It changes every critical value, and the correct set is selected
automatically.

{phang}
{opt ztype(long|lagdiff|laglevel)} selects

{p 12 16 2}
{opt long}     Z{subscript:t-1} = y{subscript:t-1} - y{subscript:t-1-m}{break}
{opt lagdiff}  Z{subscript:t-1} = {c 198}y{subscript:t-m}{break}
{opt laglevel} Z{subscript:t-1} = y{subscript:t-m}

{pmore}
{opt long} is the paper's default and the only one that is unambiguously
stationary under both hypotheses. {opt lagdiff} is also stationary under
I(1) but throws away the information in the longer horizon. {opt laglevel}
is {bf:not} stationary if y has a unit root, so the asymptotic theory in the
paper does not cover it; it is offered because it is what a conventional SETAR
uses, and the help says plainly that with it the critical values and the
bootstrap are no longer justified by Caner and Hansen's theorems. Use it for
comparison, not for inference.

{phang}
{opt switch(numlist)} fits the constrained model of the paper's Tables IX-X:
the intercept (and trend) and y{subscript:t-1} always switch regime, and only
the listed lagged differences switch as well. The rest are held common.
{cmd:switch(none)} lets nothing but the intercept and y{subscript:t-1} switch.
Without the option every coefficient switches, which is the unconstrained
model. Use {bf:estat coefeq} first to see which coefficients actually differ,
then constrain the ones that do not.

{dlgtab:Delay}

{phang}
{opt mmin(#)} and {opt mmax(#)} set the range of delays m searched. The
reported delay is the one minimising the residual sum of squares unless
{opt delay()} overrides it. {opt mmax()} cannot exceed {opt lags()}, because
Z reaches m periods behind the first regressor and a longer delay would
shorten the sample, so the models at different m would not be comparable.

{phang}
{opt delay(#)} reports the estimates at a chosen delay while still searching
{opt mmin()}-{opt mmax()} for the delay-selection table. This is what Caner
and Hansen do in their application: the SSR prefers m = 12, they report m = 9
because the fits are nearly identical and 9 is interpretable, and they print
the whole column so the reader can see it did not matter.

{dlgtab:Search and inference}

{phang}
{opt trim(#)} is restricted to {bf:0.15}, {bf:0.10} and {bf:0.05}, the three
regions Caner and Hansen tabulate. Any other value is refused rather than
accepted with the wrong critical values attached: the asymptotic bound and the
p-value functions exist only for these three, and a trim of, say, 0.12 would
leave them undefined. The bootstrap would still be valid, but reporting a
tabulated column beside it would not be.

{phang}
{opt reps(#)} sets the replications for {bf:both} bootstraps, so the cost is
two passes. The default 1000 gives a Monte Carlo standard error near 0.01 on a
p-value around 0.1. The published application uses 10,000; {cmd:reps(10000)}
reproduces it and takes a long time, exactly as the author's own program
warns. {cmd:reps(0)} skips the bootstrap entirely and then no p-value for W is
reported, because W has no tabulated distribution and inventing one would be
the error this command exists to avoid.

{phang}
{opt joint(numlist)} tests jointly whether the listed lagged differences
differ across regimes, with a bootstrap p-value. The lags must be switching
ones; asking whether a coefficient held common across regimes differs across
regimes is refused.

{dlgtab:Reporting}

{phang}
{opt regimevar(newvar)} stores 1 where Z {c <} {&lambda} and 2 elsewhere. It
is built from time-series operators, the same expression {bf:predict, regime}
uses, so it can be checked by hand.


{marker stats}{...}
{title:The five statistics, and which to use}

{pstd}
{bf:W} {hline 1} the threshold test, H0: {&theta}{subscript:1} =
{&theta}{subscript:2}. Reported with two bootstrap p-values; see below.
Rejecting says the two regimes differ somewhere, not that they differ in
{&rho}.

{pstd}
{bf:R1T} {hline 1} one-sided Wald of H0: {&rho}{subscript:1} =
{&rho}{subscript:2} = 0, equal to
{&Sigma}{subscript:i} t{subscript:i}{sup:2} 1{c -(}t{subscript:i} {c <} 0{c )-}.
This is the one to lead with. It has power only against the economically
interesting alternative, that both regimes are stationary, and it ignores a
positive t, which under the null is noise and under an explosive alternative is
not something you usually want to call evidence of stationarity.

{pstd}
{bf:R2T} {hline 1} two-sided Wald, t{subscript:1}{sup:2} +
t{subscript:2}{sup:2}. Use it when an explosive regime is a real possibility
(bubbles, hyperinflation); it has power in both directions and therefore less
power against stationarity than R1T.

{pstd}
{bf:-t1} and {bf:-t2} {hline 1} the one-sided t statistics for each regime
separately. These are what identify a partial unit root; see the next section
but one. Large positive values reject the unit root in that regime.

{pstd}
All four unit-root statistics are reported with a bootstrap p-value and with
the asymptotic p-value from the nuisance-free {bf:bound} of their Theorem 5.
The bound is valid when the threshold is not identified under the null and is
{bf:conservative} when it is: if the bound rejects, so does the exact
distribution. The bootstrap column is the sharper one and is what to report;
the asymptotic column is the one a referee can check against the printed
table.


{marker twoboot}{...}
{title:Why two bootstraps}

{pstd}
Theorem 4 gives the limit of W as a supremum of a unit-root term plus Hansen's
(1996) chi-square process. That limit is {bf:not} pivotal: it depends on
whether {&rho} = 0. So a single bootstrap cannot be right in both cases, and
which case holds is precisely what is unknown.

{pstd}
Caner and Hansen's answer, implemented literally here:

{p 8 8 2}
o the {bf:unrestricted} bootstrap simulates from the fitted linear AR using
{&rho}-hat. It is valid if y is stationary.{p_end}
{p 8 8 2}
o the {bf:unit-root-imposed} bootstrap sets {&rho} = 0 and simulates a random
walk with the same short-run dynamics. It is valid if y has a unit root.{p_end}
{p 8 8 2}
o Report the {bf:larger} of the two p-values. {cmd:e(p_W)} holds it.{p_end}

{pstd}
Which of the two is larger is {bf:not} fixed in advance and depends on the
series; when {&rho}-hat is close to zero the two DGPs are nearly identical and
the ordering is essentially noise at a few hundred replications. That is
precisely why the rule is stated as "take the larger" rather than "use the
unit-root one": taking the larger is conservative in the direction that
matters, since it does not let you claim a threshold that could be an artefact
of nonstationarity, whichever DGP happens to produce it.

{pstd}
In both bootstraps the errors are resampled i.i.d. from the linear model's
residuals and the recursion starts from the demeaned data, which makes the DGP
invariant to the level of the series, as it must be for the intercept to be a
nuisance parameter. There is {bf:no} wild or heteroskedastic variant: the
theory assumes i.i.d. errors throughout, and a robust version of this test does
not exist in the literature. See {it:What is NOT provided}.


{marker partial}{...}
{title:The partial unit root}

{pstd}
The finding only this battery can produce. Read {bf:-t1} and {bf:-t2}
together:

{p 8 8 2}
o both reject {&rarr} stationary in both regimes;{p_end}
{p 8 8 2}
o neither rejects {&rarr} no evidence against a unit root anywhere;{p_end}
{p 8 8 2}
o {bf:one rejects and the other does not} {&rarr} a {bf:partial unit root}.
The series is mean-reverting in one regime and a random walk in the other.{p_end}

{pstd}
A partial unit root is a stationary, ergodic process overall under mild
conditions, so it is not a contradiction. It is also invisible to a linear
ADF, which fits one {&rho} to both regimes and estimates something between
them. Caner and Hansen's own application finds it: US male unemployment
reverts strongly when it has been falling and behaves like a random walk when
it has been rising.

{pstd}
The command prints this reading explicitly, at the 5% bound, so it cannot be
missed. When the two statistics are on opposite sides of the critical value but
close to it, say so rather than declaring a partial unit root: the classification
is a comparison of two test statistics, each with its own sampling error.


{marker delay}{...}
{title:Choosing the delay}

{pstd}
The delay m is a parameter and selecting it is a search, so the p-value in the
row that wins does not know about the search. {cmd:thunitroot} prints the whole
column by delay, and {bf:estat delay} prints it with every statistic, for that
reason.

{pstd}
What to report: a conclusion that holds at every m in the range, or an
explicit statement that it holds only at the selected m. If the SSR is nearly
flat across m, choose the m that is interpretable and say the data were
indifferent, which is what Caner and Hansen do.

{pstd}
For a search over which {it:variable} drives the regime, rather than which lag,
see {helpb thsearch}, which corrects the p-value for the search itself.


{marker versus}{...}
{title:Relation to dfuller and to thtar}

{pstd}
{bf:Against} {helpb dfuller}{bf::} {cmd:thunitroot} prints the linear ADF
statistic as a benchmark on the same sample and design, so the two are directly
comparable. If the ADF does not reject and R1T does, the unit root was an
artefact of forcing a single regime. If both reject, the threshold adds nothing
to the unit-root conclusion but may still matter for the dynamics.

{pstd}
{bf:Against} {helpb thtar}{bf::} {cmd:thtar} fits a threshold autoregression in
{bf:levels} and assumes stationarity throughout; its confidence interval for
the threshold and its coefficient standard errors rely on that. Use
{cmd:thunitroot} first. If it rejects the unit root in both regimes, go on to
{cmd:thtar} for the richer post-estimation. If it does not, {cmd:thtar}'s
inference is not valid on that series and {cmd:thunitroot} is the right place
to stop.

{pstd}
{bf:Against} {helpb thmtar}{bf::} {cmd:thmtar} is for threshold adjustment in a
cointegrating residual, where the first stage has already removed the unit
root. Different question.


{marker limits}{...}
{title:What is NOT provided}

{pstd}
Stated so that nothing here is read as more than it is.

{phang}
o {bf:No heteroskedasticity-robust variant.} Assumption 1 of the paper requires
i.i.d. errors, and both the limit theory and the resampling bootstrap depend on
it. There is no robust version of these statistics in the literature, so none
is offered. If the residuals are visibly heteroskedastic, the p-values here are
not trustworthy and no option in this command repairs that. Check with
{bf:predict, residuals} and an ARCH test.

{phang}
o {bf:No confidence interval for} {&lambda}{bf:.} The threshold's limit
distribution under a near unit root is not the Chan/Hansen one, and a
likelihood-ratio inversion using those critical values would be wrong.
{bf:estat delay} shows how {&lambda} moves with m, which is the honest
sensitivity check.

{phang}
o {bf:No post-selection inference for the coefficients.} The reported standard
errors condition on the estimated {&lambda} and on the selected m. They are the
paper's own, and the paper is explicit that they condition.

{phang}
o {bf:Three regimes are not supported.} The theory is two-regime.

{phang}
o {bf:No bootstrap for the asymptotic column.} The asymptotic p-values are the
bound, by construction; they are not meant to agree with the bootstrap and
will usually be larger.

{phang}
o {bf:{opt ztype(laglevel)} is outside the theory}, as noted under
{it:Options}.


{marker tableiii}{...}
{title:A note on Table III}

{pstd}
Table III of the published paper prints the detrended critical values
identical to the demeaned ones. That cannot be right: adding a trend must move
the critical values of a unit-root statistic. The tabulation distributed with
the paper carries different detrended values (for R1T, 14.06 / 16.24 / 20.75
rather than 10.84 / 12.75 / 16.97), and those are the ones {cmd:thunitroot}
uses with {opt trend}. This is recorded here rather than left silent, because a
reader checking the command against the printed table would otherwise find a
discrepancy and have no way to know which side was wrong.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}The simplest usable call: 4 lags, delay 1, 299 replications{p_end}
{phang2}{cmd:. thunitroot y, lags(4) reps(299) seed(20261005)}{p_end}

{pstd}Search the delay from 1 to 4 and print the whole battery{p_end}
{phang2}{cmd:. thunitroot y, lags(4) mmin(1) mmax(4) reps(299) seed(20261005)}{p_end}
{phang2}{cmd:. estat delay}{p_end}

{pstd}Which coefficients actually differ across regimes?{p_end}
{phang2}{cmd:. estat coefeq}{p_end}

{pstd}Refit with only the level and the first lag switching{p_end}
{phang2}{cmd:. thunitroot y, lags(4) delay(1) mmin(1) mmax(4) switch(1) joint(2 3 4) reps(299) seed(20261005)}{p_end}

{pstd}See the two null distributions of W{p_end}
{phang2}{cmd:. estat bootdist, graph}{p_end}

{pstd}The regimes, and the series classified by regime{p_end}
{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat regimeplot}{p_end}
{phang2}{cmd:. estat zplot}{p_end}

{pstd}With a trend, for power against trend stationarity{p_end}
{phang2}{cmd:. thunitroot y, lags(4) trend reps(299) seed(20261005)}{p_end}

{pstd}Store the regimes and the residuals{p_end}
{phang2}{cmd:. thunitroot y, lags(4) reps(299) seed(1) regimevar(rg)}{p_end}
{phang2}{cmd:. predict double ehat if e(sample), residuals}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thunitroot} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations in the regression{p_end}
{synopt:{cmd:e(k_lags)}}lagged differences{p_end}
{synopt:{cmd:e(k_switch)}}coefficients that switch regime{p_end}
{synopt:{cmd:e(k_total)}}coefficients in all{p_end}
{synopt:{cmd:e(trend)}}1 if a trend was included{p_end}
{synopt:{cmd:e(trim)}}trimming fraction{p_end}
{synopt:{cmd:e(delay)}}delay the estimates are reported at{p_end}
{synopt:{cmd:e(delay_ssr)}}delay minimising the SSR{p_end}
{synopt:{cmd:e(lambda)}}estimated threshold{p_end}
{synopt:{cmd:e(N_regime1)}}, {cmd:e(N_regime2)}observations per regime{p_end}
{synopt:{cmd:e(n_grid)}}grid points searched{p_end}
{synopt:{cmd:e(ssr)}}, {cmd:e(ssr0)}threshold and linear sums of squares{p_end}
{synopt:{cmd:e(sigma2)}}, {cmd:e(sigma2_0)}the matching residual variances{p_end}
{synopt:{cmd:e(ll)}}Gaussian log-likelihood{p_end}
{synopt:{cmd:e(W)}}threshold Wald at the argmin-SSR delay{p_end}
{synopt:{cmd:e(W_m)}}threshold Wald at the reported delay{p_end}
{synopt:{cmd:e(p_W_unres)}}its p-value, {&rho} unrestricted{p_end}
{synopt:{cmd:e(p_W_ur)}}its p-value, unit root imposed{p_end}
{synopt:{cmd:e(p_W)}}the larger of the two: the one to report{p_end}
{synopt:{cmd:e(R1T)}}, {cmd:e(R2T)}, {cmd:e(t1)}, {cmd:e(t2)}unit-root statistics{p_end}
{synopt:{cmd:e(p_R1T)}}, ... bootstrap p-values, unit root imposed{p_end}
{synopt:{cmd:e(pa_R1T)}}, ... asymptotic-bound p-values{p_end}
{synopt:{cmd:e(adf)}}the linear ADF t statistic{p_end}
{synopt:{cmd:e(rho_lin)}}its {&rho}{p_end}
{synopt:{cmd:e(W_joint)}}, {cmd:e(p_W_joint)}the {opt joint()} Wald and its p{p_end}
{synopt:{cmd:e(reps)}}replications per bootstrap{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thunitroot}{p_end}
{synopt:{cmd:e(depvar)}}the series{p_end}
{synopt:{cmd:e(ztype)}}threshold-variable form{p_end}
{synopt:{cmd:e(model)}}{cmd:unconstrained} or {cmd:constrained}{p_end}
{synopt:{cmd:e(xnames)}}design column names{p_end}
{synopt:{cmd:e(swnames)}}, {cmd:e(nsnames)}switching and common names{p_end}
{synopt:{cmd:e(switchlags)}}, {cmd:e(jointlags)}what was asked for{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}, {cmd:e(V)}coefficients, {cmd:Regime1}, {cmd:Regime2},
then {cmd:Common}{p_end}
{synopt:{cmd:e(bydelay)}}delays x 10: {cmd:lambda ssr W R1T R2T t1 t2 ngrid n1 n2}{p_end}
{synopt:{cmd:e(pbydelay)}}delays x 9: the matching p-values{p_end}
{synopt:{cmd:e(cv)}}4 x 3 asymptotic 10/5/1% bounds{p_end}
{synopt:{cmd:e(b_linear)}}, {cmd:e(se_linear)}the linear ADF fit{p_end}
{synopt:{cmd:e(wald_coef)}}per-coefficient equality Walds{p_end}
{synopt:{cmd:e(p_wald_coef)}}their bootstrap p-values{p_end}
{synopt:{cmd:e(bdist_unres)}}, {cmd:e(bdist_ur)}the two bootstrap draws of W{p_end}


{marker refs}{...}
{title:References}

{phang}
Caner, M., and B. E. Hansen. 2001. Threshold autoregression with a unit root.
{it:Econometrica} 69: 1555-1596.
{browse "https://doi.org/10.1111/1468-0262.00257":doi:10.1111/1468-0262.00257}.

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 1997. Approximate asymptotic p values for structural-change
tests. {it:Journal of Business and Economic Statistics} 15: 60-67.
{browse "https://doi.org/10.1080/07350015.1997.10524687":doi:10.1080/07350015.1997.10524687}.

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics}
21: 520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}.

{phang}
Said, S. E., and D. A. Dickey. 1984. Testing for unit roots in
autoregressive-moving average models of unknown order. {it:Biometrika}
71: 599-607.
{browse "https://doi.org/10.1093/biomet/71.3.599":doi:10.1093/biomet/71.3.599}.


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
Online: {helpb thbandur} (the three-regime band alternative to this test),
{helpb thtar}, {helpb thmtar}, {helpb thsearch}, {helpb thnltest},
{helpb dfuller}, {helpb pperron}
{p_end}
