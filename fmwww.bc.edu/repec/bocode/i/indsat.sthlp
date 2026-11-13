{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat types (when to use each)" "help indsat_types"}{...}
{vieweralsosee "indsat methods" "help indsat_methods"}{...}
{vieweralsosee "indsat postestimation" "help indsat_postestimation"}{...}
{vieweralsosee "indsat ardl" "help indsat_ardl"}{...}
{vieweralsosee "indsat loop" "help indsat_loop"}{...}
{vieweralsosee "indsat gauge" "help indsat_gauge"}{...}
{vieweralsosee "indsat sim" "help indsat_sim"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtgets (panel)" "help xtgets"}{...}
{viewerjumpto "Syntax" "isat##syntax"}{...}
{viewerjumpto "Description" "isat##description"}{...}
{viewerjumpto "Options" "isat##options"}{...}
{viewerjumpto "Interpreting the output" "isat##output"}{...}
{viewerjumpto "Remarks" "isat##remarks"}{...}
{viewerjumpto "Examples" "isat##examples"}{...}
{viewerjumpto "Stored results" "isat##results"}{...}
{viewerjumpto "References" "isat##references"}{...}
{viewerjumpto "Author" "isat##author"}{...}
{title:Title}

{phang}
{bf:indsat} {hline 2} Indicator saturation library: outlier and structural-break detection by
general-to-specific selection (IIS, SIS, TIS, QIS, CIS, DIS, PIS, MIS, designed and user indicators),
with ARDL bounds testing, gauge theory, Monte Carlo and journal-style tables and graphs


{marker commands}{...}
{title:The indsat library: one command, all tools}

{p2colset 5 34 36 2}{...}
{p2col:{it:Command}}{it:Purpose}{p_end}
{p2line}
{p2col:{helpb indsat##syntax:indsat} {it:y x}{cmd:,} {it:saturation}}estimate a saturated regression (this page){p_end}
{p2col:{helpb indsat##post:indsat}{cmd:,} {it:saturation}}{bf:after your own regress, newey or ardl}: saturate the model in memory{p_end}
{p2col:{helpb indsat_ardl:indsat ardl}}ARDL / error-correction model with saturation and the PSS bounds test{p_end}
{p2col:{helpb indsat_loop:indsat loop}}re-estimate over a grid of target sizes; Jiao-Pretis scaling tests{p_end}
{p2col:{helpb indsat_gauge:indsat gauge}}null theory: cut-offs, expected false indicators, efficiency{p_end}
{p2col:{helpb indsat_sim:indsat sim}}Monte Carlo gauge and potency{p_end}
{p2col:{helpb indsat_postestimation:indsat dates}}retained indicators and regime table{p_end}
{p2col:{helpb indsat_postestimation:indsat path}}intercept / coefficient paths with exact bands{p_end}
{p2col:{helpb indsat_postestimation:indsat plot}}four-panel journal dashboard{p_end}
{p2col:{helpb indsat_postestimation:indsat test}}periods in which the path differs from a value{p_end}
{p2col:{helpb indsat_postestimation:indsat outlier}}Jiao-Pretis outlier proportion and count tests{p_end}
{p2col:{helpb indsat_postestimation:indsat distort}}Jiao-Pretis-Schwarz distortion test (+ bootstrap){p_end}
{p2col:{helpb indsat_postestimation:indsat biascorr}}post-selection bias correction{p_end}
{p2col:{helpb indsat_postestimation:indsat bias}}constancy / forecast-bias F-test{p_end}
{p2col:{helpb indsat_postestimation:indsat forecast}}forecasts with persistent shifts{p_end}
{p2col:{helpb indsat_postestimation:indsat diag}}misspecification tests{p_end}
{p2col:{helpb indsat_types:indsat types}}{bf:guide: which indicator type to use, and when}{p_end}
{p2col:{helpb indsat_methods:indsat methods}}formulas, algorithms, step-to-paper map{p_end}
{p2line}
{p2colreset}{...}
{pstd}
Typing {cmd:indsat} alone shows this menu (or replays the last estimates). Postestimation subcommands are
also available as {cmd:estat} {it:subcommand}. If a variable has the same name as a subcommand, estimate with
{cmd:indsat estimate} {it:y x}{cmd:, ...}.


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:indsat} [{cmd:estimate}] {depvar} [{indepvars}] {ifin}
{cmd:,} {it:saturation} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr:saturation}
{synoptline}
{syntab:Indicator sets (combine freely; see {help indsat_types:when to use each})}
{synopt:{opt iis}}impulse indicators 1(t=j){p_end}
{synopt:{opt sis}}step indicators 1(t>=j) (or 1(t<=j), {opt sisform(down)}){p_end}
{synopt:{opt tis}}broken linear trends (t-j+1)1(t>=j){p_end}
{synopt:{opt qis}, {opt cis}}broken quadratic and cubic trends{p_end}
{synopt:{opt dis}}differenced (zero-sum) impulses I(t=j) - I(t=j-1){p_end}
{synopt:{opt pis(#)}}pairwise impulses I(t=i) + I(t=i+#){p_end}
{synopt:{opth mis(varlist)}}multiplicative indicators x_t 1(t>=j): coefficient breaks{p_end}
{synopt:{opt bis(shape)}}designed break functions: {cmd:volcanic}, {cmd:tc}, {cmd:ramp} or {cmd:, shape(}{it:numlist}{cmd:)}{p_end}
{synopt:{opth uis(varlist)}}user-specified candidate indicators/variables{p_end}
{synopt:{opt super}}super saturation = {opt iis sis}{p_end}
{synopt:{opt ultra}}ultra saturation = {opt iis sis tis}{p_end}
{synopt:{opt select}}also select over the regressors (keep only {opt fixed()} and the constant){p_end}

{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opth ar(numlist)}}add lags of {depvar} as regressors (kept in the model){p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opth fixed(varlist)}}regressors never removed when {opt select} is used{p_end}
{synopt:{opt sisform(up|down)}}step convention: {cmd:up} (gets, default) or {cmd:down} (Autometrics){p_end}
{synopt:{opt common}}impose common break dates on SIS and all MIS coefficients{p_end}

{syntab:Selection}
{synopt:{opt tp:val(#)}}target size (significance level of selection); default {cmd:0.001}{p_end}
{synopt:{opt alg:orithm(name)}}{cmd:gets} (default), {cmd:split} (split-half) or {cmd:mstep} (m-step Huber-skip){p_end}
{synopt:{opt ms:teps(#)}}number of iterations for {cmd:algorithm(mstep)}; default 1{p_end}
{synopt:{opt rat:io(#)}}ratio threshold for the number of blocks; default 0.8{p_end}
{synopt:{opt maxb:lock(#)}}maximum block size; default 30 (15 for QIS, 8 for CIS){p_end}
{synopt:{opt block:s(#)}}fix the number of blocks{p_end}
{synopt:{opt maxp:aths(#)}}maximum number of search paths per GETS; default all{p_end}
{synopt:{opt ic(name)}}terminal-model criterion: {cmd:sc} (default), {cmd:aic}, {cmd:aicc}, {cmd:hq}{p_end}
{synopt:{opt noadd:block}}do not run the additional block search when too many indicators survive{p_end}
{synopt:{opt arlb(lag p)}}diagnostic guard: Ljung-Box AR test must not reject at {it:p}{p_end}
{synopt:{opt archlb(lag p)}}diagnostic guard: Ljung-Box ARCH test{p_end}
{synopt:{opt jb(p)}}diagnostic guard: Jarque-Bera normality{p_end}
{synopt:{opt tol(#)}}collinearity tolerance; default 1e-7{p_end}

{syntab:Inference and reporting}
{synopt:{opt vce(type)}}{cmd:ols} (default), {cmd:robust} (White HC0) or {cmd:nw} (Newey-West){p_end}
{synopt:{opt varcor:r}}Johansen-Nielsen consistency/efficiency correction of the covariance (IIS){p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt gen:erate(stub)}}save the retained indicators as variables {it:stub}{it:name}{p_end}
{synopt:{opt gr:aph}}draw the four-panel dashboard ({cmd:estat plot}){p_end}
{synopt:{opt nodates}}suppress the table of detected breaks{p_end}
{synopt:{opt notable}}suppress the coefficient table{p_end}
{synopt:{opt noheader}}suppress the header{p_end}
{synopt:{opt nooutliertests}}suppress the Jiao-Pretis tests (IIS-only models){p_end}
{synoptline}
{p 4 6 2}
Time-series operators are allowed; data must be {cmd:tsset} for {opt ar()}, operators and dated output
(otherwise observation order is used). The estimation sample must be contiguous.{p_end}
{p 4 6 2}
See {help indsat_postestimation} for {cmd:estat} and {cmd:predict}.{p_end}


{marker post}{...}
{title:Post-estimation mode: saturate the model you have just estimated}

{p 8 15 2}
{it:estimation command} ...{p_end}
{p 8 15 2}
{cmd:indsat ,} {it:saturation} [{it:options}] [{opt nocomp:are} {opt nogr:aph}]

{pstd}
After {helpb regress}, {helpb newey} or {cmd:ardl} (Kripfganz & Schneider), typing {cmd:indsat} with options only
reads the dependent variable, the regressors (including lags, time-series operators and factor variables),
the constant and the estimation sample from {cmd:e()} and re-estimates the {it:same} model with the requested
indicator sets. The researcher therefore keeps the usual workflow and adds, in one line, the detection of
outliers, location shifts, trend breaks and coefficient breaks:{p_end}
{phang2}{cmd:. regress y x1 x2}{p_end}
{phang2}{cmd:. indsat, super tpval(0.01)}{space 14}// outliers + level shifts{p_end}
{phang2}{cmd:. indsat, sis mis(x1) common}{space 11}// level and slope breaks at common dates{p_end}
{phang2}{cmd:. indsat plot}{p_end}

{pstd}
{bf:Output.} Tables {it:and} graphs are produced automatically:{p_end}
{phang2}- the saturated model (coefficients, retained indicators, diagnostics, Jiao-Pretis tests) and the table of
detected outliers and breaks with the implied regimes;{p_end}
{phang2}- graph {cmd:indsat_dash}: (a) actual and fitted values with break dates, (b) scaled residuals with the
selection cut-offs, (c) the intercept path with its band, (d) the MIS coefficient paths or a timeline of the retained
indicators;{p_end}
{phang2}- a table and graph {cmd:indsat_compare} of the original versus the saturation-robust estimates (coefficient,
95% interval, change in %); large changes show that outliers or breaks distorted the original model.{p_end}
{pstd}
{opt nograph} suppresses the graphs and {opt nocompare} the comparison. After {cmd:ardl}, the lag orders, constant, {cmd:exog()} variables and the
level/EC form are taken from {cmd:e()} and {helpb indsat_ardl:indsat ardl} is run: saturation of the ARDL
regression (with its dashboard), re-estimation of the error-correction model with the retained indicators, the
comparison of the long-run coefficients and the speed of adjustment without and with indicators (table and graph),
and the Pesaran-Shin-Smith bounds test.
All postestimation subcommands ({cmd:indsat dates}, {cmd:plot}, {cmd:test}, ...) then apply.
Weighted estimation is not supported. The selection uses OLS t-tests (see remark 4); use {opt vce()} to change it.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:indsat} implements indicator saturation (Hendry 1999; Hendry, Johansen & Santos 2008;
Johansen & Nielsen 2009; Castle, Doornik, Hendry & Pretis 2015; Pretis, Reade & Sucarrat 2018).
The regression is saturated with a full set of candidate indicators, more than there are
observations, and a general-to-specific multi-path search, carried out on blocks of
indicators, retains only those that are significant at the target size {opt tpval()}.
The regressors of the model are kept throughout. The retained indicators date and
quantify outliers, location shifts, trend breaks and coefficient breaks, and the final
model is a regression that is robust to them.

{pstd}
The default algorithm is a faithful port of {it:gets::isat} (R package {it:gets}): with the same data and
options it returns the same retained indicators and coefficients to numerical precision (validated
for IIS, SIS, TIS, AR terms, all covariance types, all information criteria and the additional block search).
The split-half and m-step algorithms of the asymptotic theory (Johansen & Nielsen 2009, 2016;
Nielsen & Qian 2025) are also available.

{pstd}
Companion commands: {helpb indsat_ardl:indsat ardl} (ARDL / error-correction models with saturation and the
Pesaran-Shin-Smith bounds test), {helpb indsat_loop:indsat loop} (results over a grid of target sizes and the
Jiao-Pretis scaling tests), {helpb indsat_gauge:indsat gauge} (null distribution of the number of false
indicators, cut-offs, efficiency) and {helpb indsat_sim:indsat sim} (Monte Carlo gauge and potency).
For panels use {helpb xtgets}.


{marker options}{...}
{title:Options}

{dlgtab:Indicator sets}

{phang}
{opt iis}, {opt sis}, {opt tis}, {opt qis}, {opt cis}, {opt dis}, {opt pis(#)}, {opt mis(varlist)},
{opt bis()}, {opt uis(varlist)}, {opt super}, {opt ultra}: see {help indsat_types} for the definitions and
for the situations in which each one is appropriate. Each set is searched in blocks separately; the
survivors of all sets are then searched jointly. {opt mis()} variables must be regressors (lags allowed:
{cmd:mis(L.y)} with {cmd:ar(1)}). Retained indicators are named {it:type}{it:date}, e.g. {cmd:sis1899},
{cmd:iis1990q3}, {cmd:misx_2008m9}.

{phang}
{opt bis(volcanic [, gamma(#) length(#)])} uses eq. (31) of Pretis et al. (2016) with response time 1,
default gamma = 0.5 and L = 3, normalised to a peak of 1. {opt bis(tc [, delta(#) length(#)])} uses
delta^k (default delta 0.7). {opt bis(ramp [, length(#)])} a linear ramp. {opt bis(, shape(numlist))}
any profile.

{phang}
{opt select} turns {cmd:indsat} into a joint selection over indicators and regressors (as Autometrics):
in the final search only the constant and {opt fixed()} variables are kept. With no indicator set,
{cmd:indsat} {it:y x1-x50}{cmd:, select} is a plain multi-path GETS.

{phang}
{opt common} (with {opt sis} and/or {opt mis()}) forces breaks to occur at the same dates for the intercept
and all MIS coefficients: the union of dates retained separately is the candidate set; dates closer than
the number of parameters per date are merged; date blocks are eliminated backwards by Wald F-tests at
{opt tpval()}.

{dlgtab:Selection}

{phang}
{opt tpval(#)} is the significance level of every t-test in the search, i.e. the target gauge: under the
null about {it:#} times the number of candidates are retained by chance. 1/T is a common choice. See {helpb indsat_gauge:indsat gauge}.

{phang}
{opt algorithm(gets)}: the number of blocks per set is ceil(max(2, m/(ratio*m-k), m/min(ratio*T, maxblock)))
for m candidates and k regressors; each block is reduced by multi-path GETS with the regressors fixed; the
terminal model with the lowest {opt ic()} is chosen; block survivors are reduced again; finally all sets
are combined. {opt algorithm(split)}: split-half IIS/SIS. {opt algorithm(mstep)}: m-step robustified
least squares; the reported sigma is consistency corrected.

{dlgtab:Inference}

{phang}
{opt vce()} is used both in the search and in the final model, exactly as in {it:gets}. {opt nw} uses
Bartlett weights with round(T^(1/4)) lags.

{phang}
{opt varcorr} multiplies the covariance by xi^2 and the block of regressors by eta^2 (Johansen & Nielsen
2009; {it:gets::isatvarcorrect}); valid for IIS under the null.


{marker output}{...}
{title:Interpreting the output}

{phang}{bf:Header.} {it:Candidate ind.} is the number of indicators searched (about T per set);
{it:Expected false} = tpval x candidates, the number retained by chance if there were no breaks;
{it:Estimations} counts the regressions run in the search.{p_end}
{phang}{bf:Coefficient table.} Regressors first, then retained indicators. An impulse coefficient is the
outlier size; a step coefficient is the shift that starts at its date ({opt sisform(up)}); a broken-trend
coefficient is the change in slope; an MIS coefficient is the change in the slope of {it:x}. Stars: * 10%,
** 5%, *** 1%. Retained indicators may have p-values slightly above {opt tpval()} because the terminal
model is chosen by an information criterion (as in {it:gets}).{p_end}
{phang}{bf:Diagnostics.} Ljung-Box tests of residual autocorrelation and ARCH and the Jarque-Bera test
(as printed by {it:gets}); more in {cmd:estat diag}. For IIS-only models, the Jiao-Pretis outlier
proportion and Poisson count tests (H0: no outliers, i.e. retained impulses are false detections) and
the Jiao-Pretis-Schwarz distortion test (H0: removing outliers does not change the regression
coefficients).{p_end}
{phang}{bf:Detected outliers and breaks.} One line per indicator with type, date and t-test, followed by the
regime table (level of the intercept in each regime defined by the steps).{p_end}


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
1. {it:Sample size.} With T observations and k regressors, blocks must satisfy k + block < T; for T < 40 use
{opt maxblock(10)} or smaller. QIS/CIS need small blocks (defaults 15 and 8).{p_end}
{pstd}
2. {it:Dynamics.} Put lags in the model ({opt ar()}) before saturating: unmodelled autocorrelation inflates
the number of retained indicators. Check {cmd:estat diag}.{p_end}
{pstd}
3. {it:Target size.} Smaller is safer for SIS/TIS (Nielsen & Qian 2025); confirm robustness with {helpb indsat_loop:indsat loop}.{p_end}
{pstd}
4. {it:Covariance during selection.} {opt vce()} is used inside the search, as in {it:gets}. With many candidate
indicators, {opt vce(robust)} and especially {opt vce(nw)} understate standard errors and retain far too many
indicators; select with the default {opt vce(ols)} and examine robustness of the final model afterwards.{p_end}
{pstd}
5. {it:Post-selection bias.} Retained coefficients are biased away from zero near the cut-off; see
{cmd:estat biascorr}.{p_end}
{pstd}
6. {it:Comparison with other software.} The default search equals R {it:gets} 0.40. Autometrics (PcGive/OxMetrics)
uses a different tree search and diagnostic backtesting, so results can differ in borderline cases.
{cmd:estat path}/{cmd:estat test} compute the exact variance a_t'Va_t of the coefficient path; {it:gets::isatvar}
uses a cumulative-block approximation that, after a retained impulse, also adds that impulse's variance
(so its bands are wider). See {help indsat_methods}.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}After your own regression (post-estimation mode){p_end}
{phang2}{cmd:. use indsat_seatbelts, clear}{p_end}
{phang2}{cmd:. regress ldriverskilled lkms lpetrol i.month}{p_end}
{phang2}{cmd:. indsat, sis tpval(0.005)}{p_end}
{phang2}{cmd:. use indsat_dhsy, clear}{p_end}
{phang2}{cmd:. ardl c y D4p, lags(5 5 1) ec}{p_end}
{phang2}{cmd:. indsat, super tpval(0.01)}{p_end}

{pstd}Nile river flow: the 1898 Aswan dam shift (Cobb 1978){p_end}
{phang2}{cmd:. use indsat_nile, clear}{p_end}
{phang2}{cmd:. indsat flow, iis sis tpval(0.01)}{p_end}
{phang2}{cmd:. estat plot}{p_end}
{phang2}{cmd:. estat test, hnull(1000) biascorr graph}{p_end}

{pstd}UK seat-belt law (Harvey & Durbin 1986), dynamic model with super saturation{p_end}
{phang2}{cmd:. use indsat_seatbelts, clear}{p_end}
{phang2}{cmd:. indsat ldriverskilled lkms lpetrol, ar(1 12) super tpval(0.005)}{p_end}
{phang2}{cmd:. estat dates}{p_end}
{phang2}{cmd:. estat diag}{p_end}
{phang2}{cmd:. estat forecast, h(12) graph}{p_end}

{pstd}Coefficient breaks with common dates (MIS){p_end}
{phang2}{cmd:. indsat ldriverskilled lkms lpetrol, ar(1) sis mis(lpetrol) common tpval(0.005)}{p_end}

{pstd}Outliers, robust regression and the Jiao-Pretis tests{p_end}
{phang2}{cmd:. indsat ldriverskilled lkms lpetrol, ar(1 12) iis tpval(0.01)}{p_end}
{phang2}{cmd:. estat outlier}{p_end}
{phang2}{cmd:. estat distort, boot(199) seed(1)}{p_end}
{phang2}{cmd:. indsat loop ldriverskilled lkms lpetrol, ar(1 12) graph}{p_end}

{pstd}Theory benchmarks{p_end}
{phang2}{cmd:. indsat flow, iis algorithm(split) tpval(0.01)}{p_end}
{phang2}{cmd:. indsat flow, iis algorithm(mstep) msteps(5) tpval(0.01)}{p_end}

{pstd}A full worked script is installed with the package: {cmd:net get indsat} then {cmd:do indsat_example.do}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:indsat} stores the following in {cmd:e()}:{p_end}
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(nret)}}retained indicators; {cmd:e(niis)}, {cmd:e(nsis)}, {cmd:e(ntis)}, {cmd:e(nmis)}, {cmd:e(nbis)}, {cmd:e(nuis)}, {cmd:e(nqis)}, {cmd:e(ncis)}, {cmd:e(ndis)}, {cmd:e(npis)} by type{p_end}
{synopt:{cmd:e(ncand)}}candidate indicators{p_end}
{synopt:{cmd:e(tpval)}}target size; {cmd:e(crit)} normal cut-off{p_end}
{synopt:{cmd:e(gauge_exp)}}expected number of false indicators; {cmd:e(gauge)} retained/candidates{p_end}
{synopt:{cmd:e(sigma)}}standard error of regression; {cmd:e(sigma_cor)} consistency-corrected sigma{p_end}
{synopt:{cmd:e(rss)}, {cmd:e(tss)}, {cmd:e(ll)}, {cmd:e(r2)}, {cmd:e(r2_a)}, {cmd:e(icval)}}fit{p_end}
{synopt:{cmd:e(nest)}}number of estimations in the search{p_end}
{synopt:{cmd:e(xi)}, {cmd:e(eta)}}Johansen-Nielsen consistency and efficiency factors{p_end}
{synopt:{cmd:e(lb_ar)}, {cmd:e(lb_ar_p)}, {cmd:e(lb_arch)}, {cmd:e(lb_arch_p)}, {cmd:e(jb)}, {cmd:e(jb_p)}}diagnostics{p_end}
{synopt:{cmd:e(op_z)}, {cmd:e(op_p)}, {cmd:e(op_count)}, {cmd:e(op_count_p)}}Jiao-Pretis tests (IIS only){p_end}
{synopt:{cmd:e(dist_chi2)}, {cmd:e(dist_df)}, {cmd:e(dist_p)}}distortion test (IIS only){p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:indsat}{p_end}
{synopt:{cmd:e(retained)}}names of the retained indicators{p_end}
{synopt:{cmd:e(postof)}}original command, in post-estimation mode{p_end}
{synopt:{cmd:e(saturation)}}indicator sets searched{p_end}
{synopt:{cmd:e(xvars)}, {cmd:e(xret)}}regressors specified / retained{p_end}
{synopt:{cmd:e(algorithm)}, {cmd:e(vce)}, {cmd:e(ic)}, {cmd:e(sisform)}, {cmd:e(bis)}}settings{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and covariance of the final model{p_end}
{synopt:{cmd:e(breaks)}}one row per retained indicator: type, obs, time, coef, se, t, p (type codes 1 IIS,
2 SIS, 3 TIS, 4 MIS, 5 UIS, 6 BIS, 7 QIS, 8 CIS, 9 DIS, 10 PIS){p_end}
{synopt:{cmd:e(X)}}final design matrix; {cmd:e(tvals)} time values; {cmd:e(resid)} actual, fitted, residual{p_end}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}Castle, J.L., J.A. Doornik and D.F. Hendry (2020). Robust discovery of regression models. {it:Econometrics and Statistics} (Oxford working paper 2020-W04).{p_end}
{phang}Castle, J.L., J.A. Doornik and D.F. Hendry (2026). A novel approach to forecasting after large forecast errors. {it:Journal of Forecasting} 45: 837-849. doi:10.1002/for.70062.{p_end}
{phang}Castle, J.L., J.A. Doornik, D.F. Hendry and F. Pretis (2015). Detecting location shifts during model selection by step-indicator saturation. {it:Econometrics} 3: 240-264. doi:10.3390/econometrics3020240.{p_end}
{phang}Doornik, J.A., D.F. Hendry and F. Pretis (2013). Step-indicator saturation. Oxford Economics Discussion Paper 658.{p_end}
{phang}Ericsson, N.R. and E.L. Reisman (2012). Evaluating a global vector autoregression for forecasting. Research Program on Forecasting Working Paper 2012-006, George Washington University.{p_end}
{phang}Ericsson, N.R., M.H.I. Dore and H. Butt (2022). Detecting and quantifying structural breaks in climate. {it:Econometrics} 10: 33. doi:10.3390/econometrics10040033.{p_end}
{phang}Hendry, D.F., S. Johansen and C. Santos (2008). Automatic selection of indicators in a fully saturated regression. {it:Computational Statistics} 23: 317-335. doi:10.1007/s00180-007-0054-z.{p_end}
{phang}Johansen, S. and B. Nielsen (2009). An analysis of the indicator saturation estimator as a robust regression estimator. In J.L. Castle and N. Shephard (eds), {it:The Methodology and Practice of Econometrics}, Oxford University Press.{p_end}
{phang}Johansen, S. and B. Nielsen (2013). Outlier detection in regression using an iterated one-step approximation to the Huber-skip estimator. {it:Econometrics} 1: 53-70. doi:10.3390/econometrics1010053.{p_end}
{phang}Johansen, S. and B. Nielsen (2016). Asymptotic theory of outlier detection algorithms for linear time series regression models. {it:Scandinavian Journal of Statistics} 43: 321-348. doi:10.1111/sjos.12174.{p_end}
{phang}Kitov, O.I. and M.N. Tabor (2015). Detecting structural changes in linear models: a variable selection approach using multiplicative indicator saturation. University of Oxford.{p_end}
{phang}Kurle, J.K. (2025). A Monte Carlo study of super saturation for detecting outliers and location shifts. SSRN 5583830.{p_end}
{phang}Marczak, M. and T. Proietti (2016). Outlier detection in structural time series models: the indicator saturation approach. {it:International Journal of Forecasting} 32: 180-202.{p_end}
{phang}Nielsen, B. and M. Qian (2025). Asymptotic properties of the gauge and power of step-indicator saturation. University of Oxford.{p_end}
{phang}Pretis, F., J.J. Reade and G. Sucarrat (2018). Automated general-to-specific (GETS) regression modeling and indicator saturation for outliers and structural breaks. {it:Journal of Statistical Software} 86(3).{p_end}
{phang}Pretis, F., L. Schneider, J.E. Smerdon and D.F. Hendry (2016). Detecting volcanic eruptions in temperature reconstructions by designed break-indicator saturation. {it:Journal of Economic Surveys} 30: 403-429.{p_end}
{phang}Stillwagon, J.R. (2025). Tracking shifts in U.S. monetary policy: comparing multiplicative indicator saturation with three alternatives. SSRN 6806799.{p_end}
{phang}Sucarrat, G. (2021). User-specified general-to-specific and indicator saturation methods. {it:The R Journal} 12(2): 251-265.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
