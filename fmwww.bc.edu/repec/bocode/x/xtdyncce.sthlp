{smcl}
{* *! version 1.0.0  12oct2026}{...}
{vieweralsosee "xtdyngcce" "help xtdyngcce"}{...}
{vieweralsosee "xtgcce" "help xtgcce"}{...}
{vieweralsosee "xtdyngcce methods" "help xtdyngcce_methods"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{viewerjumpto "Syntax" "xtdyncce##syntax"}{...}
{viewerjumpto "Description" "xtdyncce##description"}{...}
{viewerjumpto "Options" "xtdyncce##options"}{...}
{viewerjumpto "How to write the command" "xtdyncce##howto"}{...}
{viewerjumpto "Interpreting the output" "xtdyncce##interpret"}{...}
{viewerjumpto "Remarks and practical guidance" "xtdyncce##remarks"}{...}
{viewerjumpto "Examples" "xtdyncce##examples"}{...}
{viewerjumpto "Stored results" "xtdyncce##results"}{...}
{viewerjumpto "References" "xtdyncce##references"}{...}
{viewerjumpto "Author" "xtdyncce##author"}{...}

{title:Title}

{phang}
{bf:xtdyncce} {hline 2} Dynamic Common Correlated Effects estimation with
recursive-design wild bootstrap inference


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtdyncce} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt lag:s(#)}}autoregressive order: {cmd:1} (default) or {cmd:0}{p_end}
{synopt :{opt crl:ags(#)}}lags of the cross-section averages; default {cmd:1}{p_end}
{synopt :{opt nocons:tant}}omit the constant from the augmentation{p_end}

{syntab:Bias correction}
{synopt :{opt bias:adj(method)}}{cmd:none} (default), {cmd:hpj}, {cmd:an} or {cmd:dvs}{p_end}
{synopt :{opt anbw(#)}}truncation bandwidth for {cmd:biasadj(an)}; default {cmd:1}{p_end}
{synopt :{opt dvsi:terate(#)}}maximum iterations for {cmd:biasadj(dvs)}; default {cmd:200}{p_end}
{synopt :{opt dvst:ol(#)}}convergence tolerance for {cmd:biasadj(dvs)}; default {cmd:1e-10}{p_end}

{syntab:Inference}
{synopt :{opt vce(type)}}{cmd:ccm} (default), {cmd:jackknife} or {cmd:rdwb}{p_end}
{synopt :{opt r:eps(#)}}first-round bootstrap draws B; default {cmd:399}{p_end}
{synopt :{opt dr:eps(#)}}second-round draws D for studentization; default {cmd:199}{p_end}
{synopt :{opt wei:ghts(type)}}{cmd:rademacher} (default), {cmd:mammen} or {cmd:normal}{p_end}
{synopt :{opt soph:isticated}}restricted factors of eq. (4.8) instead of the naive ones{p_end}
{synopt :{opt nostu:dentize}}turn off the iterated bootstrap (AR(1) only){p_end}
{synopt :{opt med:ianbc}}median-bias-correct the point estimates{p_end}
{synopt :{opt nomed:ianbc}}do not median-bias-correct{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt :{opt gr:aph}}coefficient plot and bootstrap density{p_end}
{synopt :{opt name(string)}}stub for the graph names{p_end}
{synopt :{opt tr:ace}}show bootstrap / jackknife progress{p_end}
{synopt :{opt notab:le}}suppress the output table{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
A panel must be declared with {helpb xtset} beforehand. The estimation sample
must be balanced and free of gaps; see {help xtdyncce##remarks:Remarks}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdyncce} fits the dynamic panel data model with unobserved common
factors

{p 8 8 2}
y(i,t) = a*y(i,t-1) + b'x(i,t) + g(i)'f(t) + e(i,t)

{pstd}
by the pooled Common Correlated Effects (CCEP) estimator of
{help xtdyncce##P2006:Pesaran (2006)}, and provides the
{it:recursive-design wild bootstrap} (RD-WB) inference of
{help xtdyncce##JST2026:Juodis, Stauskas and Tromp (2026)}.

{pstd}
The unobserved factors f(t) are approximated by cross-section averages of the
dependent variable, the regressors, and their lags, together with a constant.
Because the model is dynamic, CCEP inherits the {it:Nickell bias} of order 1/T
and, in addition, a factor-approximation bias of order 1/N. {cmd:xtdyncce}
offers the three bias corrections benchmarked in the source paper
({cmd:hpj}, {cmd:an}, {cmd:dvs}) and three ways to build standard errors and
confidence intervals.

{pstd}
{bf:What makes the RD-WB different.} In each bootstrap replication the
dependent variable is {it:regenerated recursively} from the fitted dynamics,
and the cross-section averages are {it:re-estimated from the bootstrap data}.
Both steps are essential: a residual wild bootstrap that resamples residuals
while holding y and the averages fixed is a different estimator with different
properties. The additional regressors x(i,t) are deliberately held fixed across
replications, exactly as in the source paper.

{pstd}
For {bf:static, heterogeneous-slope} panels, and in particular when the CCE
rank condition may fail, see {helpb xtgcce} instead.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} sets the autoregressive order. {cmd:lags(1)}, the default,
includes L.{depvar} as a regressor. {cmd:lags(0)} fits the static CCEP model;
the bias corrections then have nothing to remove and a note is printed.
For AR(p) with p > 1, include the extra lags yourself in {indepvars}, e.g.
{cmd:xtdyncce y L2.y x}.

{phang}
{opt crlags(#)} sets how many lags of the cross-section averages enter the
augmentation. The default {cmd:crlags(1)} reproduces
{cmd:F = [ybar, ybar(-1), xbar, xbar(-1)]}, which is the augmentation used
throughout {help xtdyncce##JST2026:Juodis, Stauskas and Tromp (2026)} and
aligns the treatment of y and x. Values above 1 are allowed but take you
outside the asymptotics the paper proves; see
{help xtdyncce##remarks:Remarks}.

{phang}
{opt noconstant} drops the constant from the augmentation. The source paper
always keeps it ("for all estimators considered, the vector of ones is always
included among the columns of F"), so use this only deliberately.

{dlgtab:Bias correction}

{phang}
{opt biasadj(method)} selects the correction applied to the point estimates:

{p 12 16 2}
{cmd:none} {space 2}no correction; the raw CCEP estimator (the default).

{p 12 16 2}
{cmd:hpj} {space 3}the half-panel jackknife of
{help xtdyncce##DJ2015:Dhaene and Jochmans (2015)}:
{cmd:2*dhat - (dhat1 + dhat2)/2}, where dhat1 and dhat2 are CCEP on the two
half-panels {bf:with the cross-section averages recomputed inside each half}.
That recomputation is what makes the correction valid here.

{p 12 16 2}
{cmd:an} {space 4}the analytical correction of
{help xtdyncce##MW2017:Moon and Weidner (2017)}, Definition 1 and
Corollary 4.5: the weak-exogeneity bias term B1 is estimated with a truncation
kernel of bandwidth {opt anbw()} and removed.

{p 12 16 2}
{cmd:dvs} {space 3}the fixed-T minimum-distance correction of
{help xtdyncce##DVE2021:De Vos and Everaert (2021)}, equations (18)-(21),
solved as a fixed point. This is the only correction that is consistent for
{it:fixed} T, and it is the best performer in the source paper's Monte Carlo.

{phang}
{opt anbw(#)} is the truncation bandwidth M for {cmd:biasadj(an)}. The inner
sum runs over 1 <= s-t <= M. The default {cmd:anbw(1)} follows the
recommendation in {help xtdyncce##HK2011:Hahn and Kuersteiner (2011)} that
"a natural choice for m would be 1 in practice". Larger M removes more of the
bias but adds noise.

{phang}
{opt dvsiterate(#)} and {opt dvstol(#)} control the DVS fixed point. A warning
is printed if it has not converged.

{dlgtab:Inference}

{phang}
{opt vce(type)} selects how standard errors and confidence intervals are
built:

{p 12 16 2}
{cmd:ccm} {space 4}the clustered sandwich of
{help xtdyncce##A1987:Arellano (1987)} (the "CCM" of the source paper). Fast,
and sufficient for the pure AR(1) model. {bf:It is not sufficient when
regressors are present}: it captures only the innovation variance and misses
the variance coming from factor approximation. Default.

{p 12 16 2}
{cmd:jackknife} {space 1}the leave-one-out jackknife of equation (4.4), in
which the cross-section averages are {bf:also} recomputed without unit i. This
does capture the factor-approximation variance.

{p 12 16 2}
{cmd:rdwb} {space 3}the recursive-design wild bootstrap. When regressors are
present it runs the {it:iterated} (double) bootstrap of equation (4.6) and
reports a studentized interval scaled by the leave-one-out jackknife standard
error, which is what the source paper requires for the ARX(1) case. For the
pure AR(1) model it uses an equal-tailed reverse-percentile interval with a
median-bias-corrected point estimate, per Remark 6.

{phang}
{opt reps(#)} is the number of first-round bootstrap draws B. The source paper
uses B = 399 for a single bootstrap and B = D = 199 for the double bootstrap.
Minimum 99.

{phang}
{opt dreps(#)} is the number of second-round draws D used to obtain the
bootstrap-world standard error inside each first-round draw. Total cost is
B x D CCEP fits, so this is the expensive option; see
{help xtdyncce##remarks:Remarks} for timings.

{phang}
{opt weights(type)} sets the wild weights. {cmd:rademacher} (default) is what
the source paper actually runs. {cmd:mammen} and {cmd:normal} are offered as
robustness checks.

{phang}
{opt sophisticated} builds the bootstrap factor proxies from the restricted
form of equation (4.8), {cmd:fddot(t) = zbar(t) - Ahat'zbar(t-1)}, with Ahat
estimated by CCEP on the multi-equation VAR(1) as the paper requires. Without
this option the "naive" proxies are used, which is what the paper's empirical
application reports.

{phang}
{opt nostudentize} turns off the iterated bootstrap and falls back to an
equal-tailed reverse-percentile interval. It is much faster, and is the right
choice for the pure AR(1) model (Remark 6 of the source paper). {bf:Do not use
it when regressors are present}: on the source paper's own empirical design the
studentized interval covers 0.950 while the reverse-percentile interval covers
only 0.720.

{phang}
{opt medianbc} / {opt nomedianbc} control the median bias correction of
{help xtdyncce##HJ2024:Higgins and Jochmans (2024)}, in which the point
estimate is replaced by {cmd:2*dhat - median(bootstrap draws)}. It is {bf:on
by default} with {cmd:vce(rdwb)}, matching the source paper, and unavailable
otherwise.

{phang}
{opt seed(#)} fixes the random-number seed. Always set it for results you
intend to report.

{dlgtab:Reporting}

{phang}
{opt graph} draws a coefficient plot with confidence intervals and, when a
bootstrap was run, the bootstrap density of the first coefficient.
{opt name(string)} sets the graph-name stub (graphs are named
{it:stub}{cmd:_coef} and {it:stub}{cmd:_boot}).

{phang}
{opt trace} reports progress every 100 bootstrap draws (every 20 for the
iterated bootstrap) and every 50 jackknife units. Useful on large panels.


{marker howto}{...}
{title:How to write the command}

{pstd}
{bf:Step 1 - declare the panel.}

{phang2}{cmd:. xtset country year}{p_end}

{pstd}
{bf:Step 2 - start simple.} Fit the uncorrected estimator to see the raw
numbers and confirm the sample is what you expect.

{phang2}{cmd:. xtdyncce gdp temp}{p_end}

{pstd}
Read off {it:Number of panels}, {it:Time periods} and whether any panel was
dropped for unbalancedness. Nothing else is trustworthy until those are right.

{pstd}
{bf:Step 3 - decide whether you have a Nickell-bias problem.} If
{cmd:lags(1)} is in force and T is small relative to N, the autoregressive
coefficient is biased downward. Compare the corrections:

{phang2}{cmd:. xtdyncce gdp temp, biasadj(hpj)}{p_end}
{phang2}{cmd:. xtdyncce gdp temp, biasadj(an)}{p_end}
{phang2}{cmd:. xtdyncce gdp temp, biasadj(dvs)}{p_end}

{pstd}
If the three move the AR coefficient in the same direction and by a similar
amount, you are in a well-behaved design. If {cmd:hpj} is wildly different from
the other two, your T is probably too short for the half-panel split.

{pstd}
{bf:Step 4 - choose inference deliberately.} With regressors in the model the
default {cmd:vce(ccm)} understates uncertainty. Move to:

{phang2}{cmd:. xtdyncce gdp temp, biasadj(hpj) vce(rdwb) reps(399) seed(1)}{p_end}

{pstd}
This is the validated procedure: bias-corrected point estimate,
recursive-design bootstrap, reverse-percentile interval, median bias
correction.

{pstd}
{bf:Step 5 - report.} Add {cmd:graph} for the figures and read
{cmd:ereturn list} for everything you may want to table.

{pstd}
{bf:A note on writing the varlist.} The lag of the dependent variable is added
{it:automatically} by {cmd:lags(1)} - do {bf:not} type {cmd:L.y} yourself in
{indepvars}, or it will enter twice. Time-series operators are allowed in
{indepvars} for everything else, e.g.

{phang2}{cmd:. xtdyncce gdp temp L.temp}{p_end}


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.}
{it:Estimator} names the point estimator, including the bias correction
({cmd:CCEP}, {cmd:CCEP-HPJ}, {cmd:CCEP-AN}, {cmd:CCEP-DVS}).
{it:Inference} names the variance and interval method.
{it:Number of panels} is N {it:after} any unbalanced panels were dropped.

{pstd}
{bf:Coefficient table.} {cmd:L.}{it:depvar} is the persistence parameter a.
The remaining rows are the pooled slopes b. {it:Std. err.} is the square root
of the reported variance; with {cmd:vce(rdwb)} and studentization this is the
{bf:jackknife} standard error, because that is the real-world scale the
studentized interval is multiplied by. The confidence interval is {bf:not}
always symmetric around the coefficient: reverse-percentile and studentized
bootstrap intervals are asymmetric by construction, and that asymmetry is
where the bias information lives.

{pstd}
{bf:Implied long-run effects.} For each regressor, LR = b / (1 - a): the
cumulative effect of a permanent unit change. {it:share} is b/LR, the fraction
of the long-run effect that arrives immediately. {it:half-life} is
ln(0.5)/ln(a), the number of periods for half of a shock to dissipate. These
are reported only when the AR coefficient is inside the unit circle.

{pstd}
{bf:Footer.} The number of cross-section average columns is the dimension of
the augmentation; if it approaches T, the estimator is close to exhausting the
time-series degrees of freedom, which is itself a source of bias
(De Vos and Everaert 2021, section 3).


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:Which combination should I report?} A bias-corrected CCEP paired with the
recursive-design bootstrap:

{phang2}{cmd:xtdyncce y x, biasadj(hpj) vce(rdwb)}{p_end}

{pstd}
{bf:Measured coverage} of the 95% interval for the autoregressive coefficient,
N = 50, T = 25, 100 replications, seed varied each time (true alpha = 0.6):

{p2colset 8 38 40 2}{...}
{p2col :{bf:procedure}}{bf:coverage}{p_end}
{p2col :{cmd:vce(ccm)}, no correction}0.32{p_end}
{p2col :{cmd:vce(ccm) biasadj(hpj)}}0.50{p_end}
{p2col :{cmd:vce(ccm) biasadj(dvs)}}0.70{p_end}
{p2col :{cmd:vce(rdwb) nostudentize}}0.86{p_end}
{p2col :{cmd:vce(rdwb) biasadj(hpj) nostudentize}}0.86{p_end}
{p2colreset}{...}

{pstd}
And on the source paper's {bf:own empirical design} (N = 100, T = 20,
alpha0 = 0.2, strictly exogenous regressor, 100 replications), where JST
publish the number to hit:

{p2colset 8 44 46 2}{...}
{p2col :{bf:procedure}}{bf:coverage}{p_end}
{p2col :{cmd:vce(ccm)}, no correction}0.060{p_end}
{p2col :{cmd:vce(rdwb) nostudentize}}0.720{p_end}
{p2col :{cmd:vce(rdwb) biasadj(dvs) nostudentize}}0.910{p_end}
{p2col :{cmd:vce(rdwb)} (studentized, the default)}{bf:0.950}{p_end}
{p2col :{it:JST Table A.11, CCEP(RDn)}}{it:0.936}{p_end}
{p2colreset}{...}

{pstd}
The collapse of the clustered interval to 0.060 reproduces the finding the
source paper is built on (they report 0.082), and the default studentized
interval reproduces their 0.936 at 0.950. The lesson is that at short T the
studentization is not optional decoration: it is what delivers the nominal
level.

{pstd}
{cmd:biasadj(dvs)} is the better choice when T is genuinely small (say T < 25)
and the regressors are strictly exogenous, which is the case
De Vos and Everaert designed it for. {cmd:biasadj(an)} is the natural choice
when T is moderate and you want an analytical rather than a resampling
correction.

{pstd}
{bf:Sample-size regime.} The theory in the source paper is a joint
large-N, large-T asymptotic with N/T -> kappa in (0, infinity). In practice
this means neither dimension should dwarf the other by an order of magnitude.
For T below about 20, prefer {cmd:biasadj(dvs)}, which is the only correction
derived for fixed T.

{pstd}
{bf:Rank condition.} The results assume the rank condition holds exactly,
rk(Gamma) = R = K. The paper explicitly leaves the deficient case
R <= K to future research. {cmd:xtdyncce} does {bf:not} test the rank
condition and will not warn you if it fails. Check it before estimating - see
{helpb xtgcce} for an estimator that is robust to its failure, and
{help xtdyncce##DVES2024:De Vos, Everaert and Sarafidis (2024)} for a test.
Note that {cmd:xtdcce2}'s rank-condition classifier and its regularized CCE
option are {bf:static-only} and silently ignore themselves on a dynamic panel.

{pstd}
{bf:Unbalanced panels and gaps.} Neither the cross-section averages nor the
leave-one-out jackknife is defined without a common time grid. Panels with a
shorter span are dropped and the count is reported; gaps inside a panel are an
error. This is a deliberate, documented restriction: neither source paper
provides theory for unbalanced CCE.

{pstd}
{bf:Timing.} The bootstrap engine is pure Mata. On a balanced panel with
N = 100 and T = 50 a first-round draw costs roughly 0.002 seconds, so
{cmd:reps(399)} takes under a second. The experimental {cmd:studentize} option
costs B x D fits and is of the order of minutes. Use {cmd:trace} on large
problems.

{pstd}
{bf:Every bootstrap draw carries the same bias correction.} When
{cmd:biasadj()} is combined with {cmd:vce(rdwb)}, each replication is
bias-corrected by the same method before the studentized statistic is formed.
This follows appendix A.1.2 of the source paper. Skipping it leaves the
statistic centred away from zero and the interval misses.

{pstd}
{bf:What this command does not do.} It does not test the rank condition,
does not select the number of factors, does not handle weak factors, and does
not provide a specification test against the principal-components estimator.
These are documented limitations of the underlying theory, not omissions.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Uncorrected CCEP with clustered standard errors{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock}{p_end}

{pstd}Half-panel jackknife bias correction{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock, biasadj(hpj)}{p_end}

{pstd}Leave-one-out jackknife standard errors{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock, vce(jackknife)}{p_end}

{pstd}The recommended procedure: bias correction + recursive-design bootstrap{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock, biasadj(hpj) vce(rdwb) reps(399) seed(1)}{p_end}

{pstd}More bootstrap draws{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock, vce(rdwb) reps(999) seed(1)}{p_end}

{pstd}Pure AR(1) with the sophisticated restricted factors{p_end}
{phang2}{cmd:. xtdyncce invest, vce(rdwb) sophisticated seed(1)}{p_end}

{pstd}Two lags of the cross-section averages, with graphs{p_end}
{phang2}{cmd:. xtdyncce invest mvalue kstock, crlags(2) vce(rdwb) graph name(fig1)}{p_end}

{pstd}A full worked example on simulated data with known truth is shipped with
the package:{p_end}
{phang2}{cmd:. net get xtdyngcce}{p_end}
{phang2}{cmd:. do xtdyngcce_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtdyncce} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels used{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(k_w)}}number of estimated coefficients{p_end}
{synopt:{cmd:e(lags)}}autoregressive order{p_end}
{synopt:{cmd:e(crlags)}}lags of the cross-section averages{p_end}
{synopt:{cmd:e(n_csa)}}number of augmentation columns{p_end}
{synopt:{cmd:e(reps)}}first-round bootstrap draws{p_end}
{synopt:{cmd:e(dreps)}}second-round draws{p_end}
{synopt:{cmd:e(studentized)}}1 if the experimental studentized interval was used{p_end}
{synopt:{cmd:e(sophisticated)}}1 if restricted factors were used{p_end}
{synopt:{cmd:e(medianbc)}}1 if the point estimates were median-bias-corrected{p_end}
{synopt:{cmd:e(N_drop)}}panels dropped for unbalancedness{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdyncce}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(indeps)}}names of the regressors{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(biasadj)}}bias-correction method{p_end}
{synopt:{cmd:e(vcetype)}}variance method{p_end}
{synopt:{cmd:e(weights)}}wild-weight distribution{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(ci_lo)}}lower confidence limits{p_end}
{synopt:{cmd:e(ci_hi)}}upper confidence limits{p_end}
{synopt:{cmd:e(bdraws)}}B x k matrix of bootstrap draws (with {cmd:vce(rdwb)}){p_end}
{synopt:{cmd:e(bjack)}}N x k matrix of leave-one-out estimates (with {cmd:vce(jackknife)}){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker A1987}{...}
{phang}
Arellano, M. 1987. Computing robust standard errors for within-groups
estimators. {it:Oxford Bulletin of Economics and Statistics} 49(4): 431-434.

{marker DVE2021}{...}
{phang}
De Vos, I., and G. Everaert. 2021. Bias-corrected common correlated effects
pooled estimation in dynamic panels. {it:Journal of Business & Economic
Statistics} 39(1): 294-306. {browse "https://doi.org/10.1080/07350015.2019.1654879"}

{marker DVES2024}{...}
{phang}
De Vos, I., G. Everaert, and V. Sarafidis. 2024. A method to evaluate the rank
condition for CCE estimators. {it:Econometric Reviews} 43(2-4): 123-155.
{browse "https://doi.org/10.1080/07474938.2023.2292383"}

{marker DJ2015}{...}
{phang}
Dhaene, G., and K. Jochmans. 2015. Split-panel jackknife estimation of
fixed-effect models. {it:Review of Economic Studies} 82(3): 991-1030.
{browse "https://doi.org/10.1093/restud/rdv007"}

{marker GK2015}{...}
{phang}
Goncalves, S., and M. Kaffo. 2015. Bootstrap inference for linear dynamic
panel data models with individual fixed effects. {it:Journal of Econometrics}
186(2): 407-426. {browse "https://doi.org/10.1016/j.jeconom.2015.02.017"}

{marker HK2011}{...}
{phang}
Hahn, J., and G. Kuersteiner. 2011. Bias reduction for dynamic nonlinear panel
models with fixed effects. {it:Econometric Theory} 27(6): 1152-1191.
{browse "https://doi.org/10.1017/S0266466611000028"}

{marker Han2026}{...}
{phang}
Hansen, B. E. 2026. Jackknife standard errors for clustered regression.
{it:Review of Economic Studies}, forthcoming.
{browse "https://doi.org/10.1093/restud/rdag050"}

{marker HJ2024}{...}
{phang}
Higgins, A., and K. Jochmans. 2024. Bootstrap inference for fixed-effect
models. {it:Econometrica} 92(2): 411-427.
{browse "https://doi.org/10.3982/ECTA20712"}

{marker JKW2021}{...}
{phang}
Juodis, A., H. Karabiyik, and J. Westerlund. 2021. On the robustness of the
pooled CCE estimator. {it:Journal of Econometrics} 220(2): 325-348.
{browse "https://doi.org/10.1016/j.jeconom.2020.06.002"}

{marker JST2026}{...}
{phang}
Juodis, A., O. Stauskas, and S. Tromp. 2026. Bootstrap inference for dynamic
panel data models with common correlated effects. arXiv:2609.31442 [econ.EM].
{browse "https://arxiv.org/abs/2609.31442"}

{marker MW2017}{...}
{phang}
Moon, H. R., and M. Weidner. 2017. Dynamic linear panel regression models with
interactive fixed effects. {it:Econometric Theory} 33(1): 158-195.
{browse "https://doi.org/10.1017/S0266466615000328"}

{marker P2006}{...}
{phang}
Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels
with a multifactor error structure. {it:Econometrica} 74(4): 967-1012.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00692.x"}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See also: {helpb xtgcce}, {helpb xtdyngcce}, {helpb xtdyngcce_methods},
{helpb xtdcce2}, {helpb xtcd2}, {helpb xtcse2}.
