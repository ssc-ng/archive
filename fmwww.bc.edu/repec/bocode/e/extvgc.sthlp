{smcl}
{* *! version 1.0.0  25nov2026}{...}
{vieweralsosee "extvgc methods" "help extvgc_methods"}{...}
{vieweralsosee "asycaus (if installed)" "help asycaus"}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{viewerjumpto "Syntax" "extvgc##syntax"}{...}
{viewerjumpto "Description" "extvgc##description"}{...}
{viewerjumpto "Options" "extvgc##options"}{...}
{viewerjumpto "Interpreting the output" "extvgc##output"}{...}
{viewerjumpto "Remarks" "extvgc##remarks"}{...}
{viewerjumpto "Examples" "extvgc##examples"}{...}
{viewerjumpto "Stored results" "extvgc##results"}{...}
{viewerjumpto "References" "extvgc##references"}{...}
{viewerjumpto "Author" "extvgc##author"}{...}
{title:Title}

{phang}
{bf:extvgc} {hline 2} Extreme time-varying Granger-causality test (EX-TVGC) of
Hong, Guo & Zhao (2025)

{pstd}
Methods page (equations, step-by-step map to the paper): {help extvgc_methods:help extvgc methods}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:extvgc} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{pstd}
H0: {it:causvar} (shock) does not Granger-cause {it:depvar} (shock).
The data must be {helpb tsset} (single time series, no gaps).

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Shocks (Eqs. 1-7)}
{synopt:{opt th:eta(#)}}quantile level theta1 in (0, 0.5); theta2 = 1 - theta1; default {cmd:0.1}{p_end}
{synopt:{opt thr:eshold(type)}}{cmd:common} (default, Eq. 2), {cmd:own} (variable-specific) or {cmd:zero} (all positive vs all negative changes){p_end}
{synopt:{opt diff:erenced}}the variables already are the shocks (e.g. log returns); default: levels, shocks = first differences{p_end}
{synopt:{opt nocum:ulate}}do not cumulate the components (stationary use){p_end}
{synopt:{opt cause:shocks(list)}}shocks of {it:causvar}: {cmd:pos} {cmd:neg} {cmd:nor}; default all three{p_end}
{synopt:{opt dep:shocks(list)}}shocks of {it:depvar}: {cmd:pos} {cmd:neg} {cmd:nor}; default all three{p_end}
{synopt:{opt nooverall}}skip the test on the undecomposed series (Fig. 2 of the paper){p_end}

{syntab:LA-VAR and lag order (Eqs. 8-13)}
{synopt:{opt d(#)}}extra (augmentation) lags, Toda-Yamamoto; default {cmd:1}{p_end}
{synopt:{opt notr:end}}omit the linear trend of Eqs. (8)-(9){p_end}
{synopt:{opt l:ags(#)}}fix the lag order p (otherwise selected){p_end}
{synopt:{opt maxl:ag(#)}}largest lag for selection; default {cmd:8}{p_end}
{synopt:{opt ic(name)}}{cmd:hjc} (default, Eq. 12), {cmd:aic}, {cmd:sbc}, {cmd:hqc}{p_end}
{synopt:{opt lagm:ode(mode)}}{cmd:common} (default: chosen on the overall system, used for all pairs) or {cmd:pair}{p_end}

{syntab:Time variation (Eq. 19)}
{synopt:{opt alg:orithm(name)}}{cmd:recursive} (default, recursive evolving), {cmd:forward} or {cmd:rolling}{p_end}
{synopt:{opt win:dow(#)}}minimum window (obs); default floor(T(0.01 + 1.8/sqrt(T))); paper: 72{p_end}

{syntab:Bootstrap (Eqs. 20-22)}
{synopt:{opt rep:s(#)}}bootstrap replications; default {cmd:499}; {cmd:0} = no critical values{p_end}
{synopt:{opt cont:rol(#)}}control window (obs) for the max-SEW critical value; default {cmd:12} (one year of monthly data){p_end}
{synopt:{opt res:ample(type)}}{cmd:indep} (default, residuals redrawn per equation) or {cmd:joint} (rows){p_end}
{synopt:{opt seed(#)}}random-number seed; default {cmd:12345}{p_end}
{synopt:{opt l:evel(#)}}90, 95 (default) or 99: critical value used for decisions, episodes and shading{p_end}

{syntab:Reporting}
{synopt:{opt mind:ur(#)}}minimum length (obs) of a reported causality episode; default {cmd:1}{p_end}
{synopt:{opt noepis:odes}}do not list the episodes{p_end}
{synopt:{opt desc:riptive}}Table 1 of the paper: descriptive statistics, JB, ADF, KPSS of the shocks{p_end}
{synopt:{opt diag:nostics}}Tables 2 and 3: multivariate normality and ARCH per pair, lag order by four criteria{p_end}
{synopt:{opt gen:erate(stub)}}save the SEW_t sequences as {it:stub}{cmd:_}{it:pair} variables{p_end}
{synopt:{opt nogr:aph}}no graphs{p_end}
{synopt:{opt sav:ing(filename)}}save the pair-panel graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:extvgc} implements the extreme time-varying Granger-causality test of
Hong, Guo & Zhao (2025). It combines the extreme Granger-causality idea of
Wang, Ma, Niu & He (2020) with the lag-augmented VAR and the recursive
evolving window algorithm of Shi, Phillips & Hurn (2018) and
Shi, Hurn & Phillips (2020):

{p 8 12 2}1. The shock of each variable is split with common quantile
thresholds into {bf:extreme positive} (e > q, the top 10% by default),
{bf:extreme negative} (e < q_v, the bottom 10%) and {bf:normal} shocks
(Eqs. 2-5), and each part is cumulated (Eq. 6).{p_end}
{p 8 12 2}2. For every pair (shock of {it:causvar}, shock of {it:depvar}) a
LA-VAR(p + d) with constant and trend is fitted (Eqs. 8-13), p chosen by the
Hatemi-J (2003) criterion.{p_end}
{p 8 12 2}3. The Wald statistic (Eq. 18) is computed on every subsample;
the recursive evolving statistic SEW_t is its supremum over all start points
for each end date t (Eq. 19).{p_end}
{p 8 12 2}4. Critical values come from a residual bootstrap of the restricted
VAR: the 90/95/99% quantile of the maximum SEW over a control window
(Eqs. 20-22). H0 is rejected at date t when SEW_t exceeds the critical value.{p_end}

{pstd}
With the defaults the command reproduces the layout of the paper: the overall
test (Fig. 2) and the nine pairs Ext+/Ext-/Normal x Ext+/Ext-/Normal (Fig. 3),
with tables of the maximum statistics, the critical values and the dated
causality episodes. {opt threshold(zero)} gives the classical
Hatemi-J (2012) positive/negative split in the same time-varying framework
(the AS-TVGC of Hong et al. 2022).


{marker options}{...}
{title:Options}

{phang}
{opt theta(#)} is theta1 of Eq. (2); theta2 = 1 - theta1. With the default 0.1
an extreme positive shock lies above the 90th percentile and an extreme
negative shock below the 10th percentile (Wang et al. 2020, Sec. 4.1). The
paper's robustness checks use 0.08, 0.12 and 0.20.

{phang}
{opt threshold(common)} uses the common thresholds of Eq. (2):
q = max of the two variables' upper quantiles, q_v = min of their lower
quantiles. {opt threshold(own)} uses each variable's own quantiles, which is
preferable when the two shocks have very different scales.
{opt threshold(zero)} sets q = q_v = 0, so every positive (negative) change is
a positive (negative) shock and the normal component is empty; only
{cmd:pos} and {cmd:neg} pairs are then run.

{phang}
{opt differenced} declares that {it:depvar} and {it:causvar} already are the
shocks e (for example log returns, as in the paper's data step). Without it
the variables are taken as (log) levels and e = first difference.
Both give identical statistics for the same data.

{phang}
{opt lags(#)}, {opt maxlag(#)}, {opt ic()}, {opt lagmode()}: the paper selects
one lag order by HJC for the system (Table 3); this is the default
({cmd:lagmode(common)}, on the undecomposed series). {cmd:lagmode(pair)}
selects p separately for each pair.

{phang}
{opt algorithm()}: {cmd:recursive} = recursive evolving (sup over all start
points; the paper's choice), {cmd:forward} = expanding window from the first
observation, {cmd:rolling} = fixed window of length {opt window()}.

{phang}
{opt control(#)} is the control window of Eq. (22): the bootstrap critical value
is the quantile of the maximum SEW over {it:#} consecutive dates, which
controls the false detection rate over that period. The paper uses one year
(12 months) and five years (60) as robustness.


{marker output}{...}
{title:Interpreting the output}

{phang}{bf:Header} {hline 2} the thresholds actually used (q and q_v), the lag
order rule, the algorithm, the minimum window and the bootstrap design.{p_end}

{phang}{bf:Main table} {hline 2} one row per pair, written
{it:shock of causvar} => {it:shock of depvar} (Ext+ extreme positive, Ext-
extreme negative, Normal). {bf:p} lag order; {bf:max SEW} largest SEW_t over
the sample and the date {bf:at} which it occurs; {bf:CV 90/95/99%} bootstrap
critical values; {bf:#rej} number of dates with SEW_t above the
{opt level()} critical value. Stars mark the max SEW above the 90/95/99% CV.{p_end}

{phang}{bf:Causality episodes} {hline 2} the dated periods in which H0 is
rejected (consecutive dates above the critical value), as in the dating of
Section 3.3 of the paper (e.g. "from July 2007 to November 2008").{p_end}

{phang}{bf:Graphs} {hline 2} {cmd:extvgc_shocks}: the shocks of both variables
with the thresholds (extreme positive, extreme negative, normal);
{cmd:extvgc_overall}: SEW_t of the undecomposed test (Fig. 2);
{cmd:extvgc_pairs}: the panel of all pairs (Fig. 3), dashed line = critical
value, shaded = H0 rejected.{p_end}


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:Sample size.} Monthly data of 300+ observations as in the paper are
comfortable. The minimum window must exceed the number of LA-VAR regressors
plus two; extreme components carry about theta*T jumps each, so short
windows contain few extreme events.

{pstd}
{bf:Sparse extreme components (caution).} An extreme component is a step
function that changes only about 10% of the time. In a short subsample it may
jump only a few times, and the LA-VAR then fits it almost perfectly, which can
produce very large Wald values. Because the recursive evolving statistic takes
the supremum over hundreds of start points while the bootstrap critical value
of Eq. (22) is computed on the first {it:window}+{it:control}-1 observations,
rejections in pairs of extreme components should be read with care. In
simulations with independent series extvgc reproduces this behaviour of the
procedure. Useful checks: a longer {opt window()}, a larger
{opt control()}, {opt threshold(own)}, comparing with {opt algorithm(rolling)},
and requiring persistence with {opt mindur()}.

{pstd}
{bf:Persistence after a break.} With the recursive evolving algorithm, a
causal episode can remain significant after it ends, because windows that
start inside the episode still enter the supremum. The date of the first
rejection (origination) is the most reliable piece of information.

{pstd}
{bf:Computation.} All subsample regressions use running cross-products, so the
cost is small; the bootstrap dominates (about 0.03 s per replication and pair
for T = 360). 499 replications for ten pairs take two to three minutes.

{pstd}
{bf:Numerical form.} The LA-VAR is estimated in an equivalent parameterisation
(differences of the dependent variable, one lagged level and lagged
differences); the Wald statistic is identical to the one from the levels
form and equals {cmd:regress} + {cmd:test} with Sigma = e'e/T
(see {help extvgc_methods}).


{marker examples}{...}
{title:Examples}

{pstd}Simulated data (the full self-test is {cmd:extvgc_example.do}, {cmd:net get extvgc}){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 360}{p_end}
{phang2}{cmd:. gen t = ym(1990,1) + _n - 1}{p_end}
{phang2}{cmd:. format t %tm}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen x = sum(rnormal()*0.05)}{p_end}
{phang2}{cmd:. gen y = sum(rnormal()*0.05)}{p_end}

{pstd}The paper's set-up: theta = 0.1, d = 1, window 72, one-year control, 499 replications{p_end}
{phang2}{cmd:. extvgc y x, theta(0.1) d(1) window(72) control(12) reps(499)}{p_end}

{pstd}With Tables 1-3 of the paper and the SEW_t series saved{p_end}
{phang2}{cmd:. extvgc y x, window(72) descriptive diagnostics generate(sew)}{p_end}

{pstd}Data already in log returns (the shocks), as in the paper's data step{p_end}
{phang2}{cmd:. extvgc oilret gprret, differenced window(72)}{p_end}

{pstd}Only extreme positive shocks of the cause, robustness with theta = 0.08 and a five-year control window{p_end}
{phang2}{cmd:. extvgc y x, causeshocks(pos) theta(0.08) window(72) control(60)}{p_end}

{pstd}Classical positive / negative split (AS-TVGC, Hong et al. 2022){p_end}
{phang2}{cmd:. extvgc y x, threshold(zero) window(72)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:extvgc} stores the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(theta)}}theta1{p_end}
{synopt:{cmd:r(window)}}minimum window{p_end}
{synopt:{cmd:r(control)}}control window{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(d)}}augmentation lags{p_end}
{synopt:{cmd:r(level)}}decision level{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:extvgc}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(causvar)}}variables{p_end}
{synopt:{cmd:r(pairs)}}pair codes: {cmd:all} = overall; otherwise cause then dep shock, {cmd:p} extreme positive, {cmd:n} extreme negative, {cmd:z} normal (e.g. {cmd:pn} = Ext+ => Ext-){p_end}
{synopt:{cmd:r(algorithm)}, {cmd:r(threshold)}}options used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}one row per pair: p, window, max SEW, row of the max, CV 90, CV 95, CV 99, number of statistics, number of rejecting dates{p_end}
{synopt:{cmd:r(sew)}}T x pairs: SEW_t by observation (missing before the first full window){p_end}
{synopt:{cmd:r(thresholds)}}2 x 2: upper (q) and lower (q_v) threshold for each variable{p_end}
{synopt:{cmd:r(lagorder)}}lag order chosen by AIC, SBC, HQC, HJC on the overall system{p_end}
{synopt:{cmd:r(episodes)}}pair, start, end (time values), length, peak SEW of each episode{p_end}


{marker references}{...}
{title:References}

{phang}
Hong, Y., Guo, X. and Zhao, C. 2025. New paths of the time-varying
Granger-causality test under extreme shocks: An analysis of geopolitical risk
and crude oil markets. {it:Research in International Business and Finance}
77: 102994.

{phang}
Wang, L., Ma, F., Niu, T. and He, C. 2020. Crude oil and BRICS stock markets
under extreme shocks: New evidence. {it:Economic Modelling} 86: 54-68.

{phang}
Shi, S., Phillips, P. C. B. and Hurn, S. 2018. Change detection and the causal
impact of the yield curve. {it:Journal of Time Series Analysis} 39: 966-987.

{phang}
Shi, S., Hurn, S. and Phillips, P. C. B. 2020. Causal change detection in
possibly integrated systems: Revisiting the money-income relationship.
{it:Journal of Financial Econometrics} 18: 158-180.

{phang}
Hatemi-J, A. 2003. A new method to choose optimal lag order in stable and
unstable VAR models. {it:Applied Economics Letters} 10: 135-137.

{phang}
Hatemi-J, A. 2012. Asymmetric causality tests with an application.
{it:Empirical Economics} 43: 447-456.

{phang}
Hong, Y., Wang, L., Ye, X. and Zhang, Y. 2022. Dynamic asymmetric impact of
equity market uncertainty on energy markets: A time-varying causality analysis.
{it:Renewable Energy}.

{phang}
Toda, H. Y. and Yamamoto, T. 1995. Statistical inference in vector
autoregressions with possibly integrated processes.
{it:Journal of Econometrics} 66: 225-250.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
