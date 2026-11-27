{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "xtqqkrls" "help xtqqkrls"}{...}
{vieweralsosee "xtqqplot" "help xtqqplot"}{...}
{vieweralsosee "xtqqr methods" "help xtqqr_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "xtqqr##syntax"}{...}
{viewerjumpto "Description" "xtqqr##description"}{...}
{viewerjumpto "The family of panel QQ estimators" "xtqqr##family"}{...}
{viewerjumpto "Options" "xtqqr##options"}{...}
{viewerjumpto "Interpreting the output" "xtqqr##output"}{...}
{viewerjumpto "Remarks" "xtqqr##remarks"}{...}
{viewerjumpto "Examples" "xtqqr##examples"}{...}
{viewerjumpto "Stored results" "xtqqr##results"}{...}
{viewerjumpto "References" "xtqqr##references"}{...}
{viewerjumpto "Author" "xtqqr##author"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{bf:xtqqr} {hline 2}}Panel quantile-on-quantile regression{p_end}
{p2colreset}{...}

{pstd}
The {bf:xtqqr} package contains

{p2colset 9 24 26 2}{...}
{p2col:{helpb xtqqr}}panel quantile-on-quantile regression (QQR), kernel and quantile-group forms{p_end}
{p2col:{helpb xtqqkrls}}panel quantile-on-quantile kernel regularized least squares (PQQKRLS){p_end}
{p2col:{helpb xtqqplot}}heatmaps, contour maps, slices and validation plots{p_end}
{p2col:{help xtqqr_methods:xtqqr methods}}equations, the step-to-equation map and the assumptions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtqqr} {depvar} {it:qqvar} [{it:controls}] {ifin}
[{cmd:,} {it:options}]

{pstd}
{it:qqvar} is the regressor whose quantiles index the surface (the
{it:theta} dimension). {it:controls} enter linearly with coefficients
that may vary with {it:tau}. Time-series operators are allowed
({cmd:L.x}, {cmd:D.x}).

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Quantile grid}
{synopt:{opt tau(numlist)}}quantiles of {depvar}; default {cmd:0.05(0.05)0.95}{p_end}
{synopt:{opt theta(numlist)}}quantiles of {it:qqvar}; default {cmd:0.05(0.05)0.95}{p_end}

{syntab:Estimator}
{synopt:{opt met:hod(kernel|groups)}}{cmd:kernel}: local-linear QQ of Sim and Zhou (2015), the default; {cmd:groups}: quantile-group dummies (Clance et al.){p_end}
{synopt:{opt bw(#)}}bandwidth {it:h} on the probability scale; default {cmd:0.05} (Sim and Zhou 2015){p_end}
{synopt:{opt ker:nel(name)}}{cmd:gaussian} (default), {cmd:epanechnikov} or {cmd:uniform}{p_end}
{synopt:{opt group:s(#)}}number of quantile groups of {it:qqvar} for {cmd:method(groups)}; default {cmd:4}{p_end}
{synopt:{opt xref(pooled|unit)}}quantiles and ranks of {it:qqvar} from the pooled sample (default) or within each unit{p_end}

{syntab:Panel effects}
{synopt:{opt fe(canay|dummy|none)}}remove unit effects by Canay (2011) two-step (default), by unit dummies, or pool (no effects){p_end}
{synopt:{opt time:fe}}add time (period) effects{p_end}

{syntab:Inference}
{synopt:{opt vce(vcetype)}}{cmd:cluster} (default, by panel unit), {cmd:robust}, {cmd:iid} or {cmd:bootstrap}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:100}{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synopt:{opt l:evel(#)}}confidence level stored in {cmd:e(level)}, used by {helpb xtqqplot}{p_end}

{syntab:Reporting}
{synopt:{opt val:idate}}compare the theta-averaged QQ slopes with the panel quantile regression slope{p_end}
{synopt:{opt notab:le}}suppress the coefficient table{p_end}
{synopt:{opt block(#)}}number of theta columns per table block; default {cmd:8}{p_end}
{synopt:{opt gr:aph}}draw the heatmap after estimation{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the surface in long format (tau, theta, coef, se, t, p, r2){p_end}
{synopt:{opt nodots}}suppress the progress dots{p_end}
{synoptline}
{pstd}
The data must be {helpb xtset}. Unbalanced panels are allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqqr} estimates how the {it:theta}-quantile of a regressor {it:x}
affects the {it:tau}-quantile of an outcome {it:y} in panel data. It
implements the quantile-on-quantile (QQ) approach of Sim and Zhou (2015)
for country-year (or firm-year) observations, and the panel variants used
in the applied literature that the package was built from.

{pstd}
For every pair ({it:tau}, {it:theta}) the command fits the local-linear,
kernel-weighted quantile regression of Sim and Zhou (2015):

{p 8 8 2}
min over (b0, b1, g) of
Sum_it rho_tau( y~_it - b0 - b1 (x_it - x^theta) - z_it'g ) K( (F_n(x_it) - theta) / h )

{pstd}
where rho_tau is the check function, x^theta is the theta-quantile of
{it:x}, F_n is the empirical distribution of {it:x}, K is a kernel with
bandwidth {it:h}, z are the controls and y~ is {it:y} purged of unit
effects. The slope {bf:b1(tau, theta)} is the effect of {it:x} on the
tau-quantile of {it:y} when {it:x} is at its theta-quantile. Each
quantile regression is solved exactly by {helpb qreg} with importance
weights.


{marker family}{...}
{title:The family of panel QQ estimators}

{p2colset 5 34 36 2}{...}
{p2col:{it:Paper}}{it:How to reproduce it}{p_end}
{p2line}
{p2col:Sim and Zhou (2015)}{cmd:xtqqr y x, fe(none)} on a single series (one panel unit), {cmd:bw(0.05)}{p_end}
{p2col:Wu et al. (2021), pooled QQ}{cmd:xtqqr y x, fe(none)}{p_end}
{p2col:Hassan, Iqbal and Arshed (2021)}{cmd:xtqqr y x, fe(none) validate} (panel QR + QQR){p_end}
{p2col:Atsalakis, Bouri and Pasiouras (2021)}{cmd:xtqqr y x controls, xref(unit) timefe} (country-specific D_i^theta){p_end}
{p2col:Clance, Gozgor, Gupta and Lau}{cmd:xtqqr y L.x, method(groups) groups(4) timefe}{p_end}
{p2col:Adebayo, Ozkan and Eweade (2024)}{helpb xtqqkrls} (QQKRLS){p_end}
{p2col:Sonail et al. (2026), PQQKRLS}{helpb xtqqkrls}{cmd: y x controls}{p_end}
{p2line}
{p2colreset}{...}

{pstd}
Atsalakis et al. (2021) estimate their QQ mixed model with the linear
quantile mixed model of Geraci and Bottai (2014). {cmd:xtqqr} reproduces
their centring of the disaster index at the country-specific quantile
({opt xref(unit)}) but handles the unit effects by Canay (2011) or by
dummies rather than with a random-effects likelihood; see
{help xtqqr_methods:xtqqr methods}.


{marker options}{...}
{title:Options}

{dlgtab:Quantile grid}

{phang}
{opt tau(numlist)} gives the quantiles of {depvar}, strictly between 0
and 1. The default 0.05(0.05)0.95 gives 19 levels.

{phang}
{opt theta(numlist)} gives the quantiles of {it:qqvar}. With the default
grids the command fits 19 x 19 = 361 quantile regressions.

{dlgtab:Estimator}

{phang}
{opt method(kernel)}, the default, is the Sim and Zhou (2015) estimator
above. {opt method(groups)} replaces the local-linear term by indicators
of the {opt groups()} quantile groups of {it:qqvar} (group 1 is the base)
and reports, for each tau, the effect of being in group g rather than in
the lowest group, as in the panel QQ tables of Clance et al.

{phang}
{opt bw(#)} is the bandwidth on the probability (rank) scale, because
the kernel acts on F_n(x) - theta. Sim and Zhou (2015) use h = 0.05.
Larger values average over more observations: smaller variance, larger
smoothing bias where the effect changes quickly with x (in our
simulations, h = 0.15 cut the standard error by a factor of five but
lowered the coverage of 95% intervals to 82% near a kink). Use 0.10 to
0.20 only when cells are too noisy, and report the bandwidth.

{phang}
{opt kernel(name)} selects the kernel K: {cmd:gaussian} (Sim and Zhou
2015), {cmd:epanechnikov} or {cmd:uniform}. Compact kernels set the
weight of observations outside the band to zero.

{phang}
{opt groups(#)} sets the number of quantile groups for
{cmd:method(groups)}; 4 gives quartiles.

{phang}
{opt xref(pooled|unit)}. With {cmd:pooled} (default) x^theta and F_n are
computed from all observations, so theta refers to the position of an
observation in the cross-country distribution. With {cmd:unit} they are
computed within each panel unit (x^theta_i and F_n,i), so theta refers to
the unit's own history: "a large shock for that country". This is the
centring D_it - D_i^theta of Atsalakis et al. (2021).

{dlgtab:Panel effects}

{phang}
{opt fe(canay)}, the default, applies the two-step transformation of
Canay (2011): a_i is estimated from the within (mean) regression of y on
x, the controls (and time dummies), and y~ = y - a_i is used in every QQ
fit. This treats the unit effect as a location shift, which is the
assumption under which Canay's estimator is consistent.

{phang}
{opt fe(dummy)} includes N-1 unit dummies in every local quantile
regression (Koenker 2004 without shrinkage). It allows the unit effect
to differ across tau but needs a long panel (large T) and many
observations inside each kernel window.

{phang}
{opt fe(none)} pools all observations (the pooled QQ of Wu et al. 2021).

{phang}
{opt timefe} adds period dummies to the first step and to every local
quantile regression.

{dlgtab:Inference}

{phang}
{opt vce(cluster)}, the default, uses the Powell (1991) kernel sandwich
for the weighted quantile regression, with the score summed within panel
units (Parente and Santos Silva 2016). It is robust to heteroskedasticity
and to arbitrary serial correlation within a unit.
{opt vce(robust)} treats observations as independent; {opt vce(iid)}
assumes a common error density.

{phang}
{opt vce(bootstrap)} resamples whole panel units with replacement and
repeats the {it:entire} procedure in each replication: the fixed-effect
step, the ranks F_n, the quantiles x^theta and every cell. Standard errors
are the standard deviations of the replicated slopes.

{phang}
{opt reps(#)} and {opt seed(#)} control the bootstrap.

{dlgtab:Reporting}

{phang}
{opt validate} also fits the panel quantile regression of y~ on x (and the
controls) for each tau and compares its slope b(tau) with the average of
the QQ slopes over theta. Sim and Zhou (2015) and Wu et al. (2021) use
this comparison to check that the QQ surface is a decomposition of the
standard quantile regression effect.

{phang}
{opt saving(filename[, replace])} stores the full surface in long format,
one row per (tau, theta) pair, for use in other software (for example a
3-D surface in MATLAB or R).


{marker output}{...}
{title:Interpreting the output}

{phang}
{bf:Header.} Sample size, number of panel units, the treatment of unit
and time effects, the kernel, the bandwidth, the reference distribution
of {it:qqvar} and the variance estimator.

{phang}
{bf:QQ slope estimates.} Rows are tau (quantiles of {depvar}), columns are
theta (quantiles of {it:qqvar}). Each cell is b1(tau, theta) with stars
for p<0.10 (*), p<0.05 (**) and p<0.01 (***). Read a row to see how the
effect at a given state of {it:y} (for example low growth, tau = 0.10)
changes with the size of {it:x}; read a column to see how a given size of
{it:x} affects different parts of the distribution of {it:y}.

{phang}
{bf:Summary of the estimated surface.} Mean, median, range and dispersion
of the cells, and how many are significant. A large dispersion relative
to the typical standard error is the QQ evidence of heterogeneity.

{phang}
{bf:Validation} (with {opt validate}). The panel quantile regression slope
b(tau) with its standard error, next to the average of b1(tau, theta)
over theta. Similar profiles across tau (a high correlation) indicate that
the QQ estimates decompose the conventional quantile effect.

{phang}
A warning is printed when the smallest kernel-weighted effective sample
(Kish) is below ten times the number of parameters of a local fit.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:Sample size.} Each cell uses roughly a share 2.5h of the observations
(about 12% with h = 0.05). With N x T = 1,000 that is around 120
observations per local fit. Keep the number of controls small, or widen
{opt bw()}.

{pstd}
{bf:Which fixed effects?} Use {cmd:fe(canay)} when T is moderate and the
unit effects are plausibly pure location shifts; {cmd:fe(dummy)} when T is
large (30+); {cmd:fe(none)} to reproduce pooled QQ studies, or when the
cross-unit variation is the object of interest.

{pstd}
{bf:Pooled versus unit quantiles.} {cmd:xref(pooled)} asks "what happens
when x is high relative to all countries"; {cmd:xref(unit)} asks "what
happens when x is high for that country". They answer different questions.

{pstd}
{bf:Inference.} The cluster sandwich is fast and is the default. The block
bootstrap is slower (reps x cells quantile regressions) but takes the
estimated first step and ranks into account. A Monte Carlo coverage check
is reported in {help xtqqr_methods:xtqqr methods}: with h = 0.05 the clustered
95% intervals covered the truth in 94.5% of 200 simulated panels.

{pstd}
{bf:Speed.} The default 19 x 19 grid (361 quantile regressions) on 1,500
observations takes about 25 seconds with the cluster sandwich. Use a 9 x 9 grid ({cmd:tau(0.1(0.1)0.9) theta(0.1(0.1)0.9)})
to explore.


{marker examples}{...}
{title:Examples}

{pstd}Simulated panel: 60 countries, 25 years{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2026}{p_end}
{phang2}{cmd:. set obs 60}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. gen a = rnormal()}{p_end}
{phang2}{cmd:. expand 25}{p_end}
{phang2}{cmd:. bysort id: gen year = 1995 + _n}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. gen x = 0.7*a + rnormal()}{p_end}
{phang2}{cmd:. gen z = rnormal()}{p_end}
{phang2}{cmd:. gen y = a + 0.5*x + 0.5*x*(x>0) + 0.3*z + (1 + 0.3*x*(x>0))*rnormal()}{p_end}

{pstd}Panel QQ with Canay fixed effects and the validation table{p_end}
{phang2}{cmd:. xtqqr y x z, validate}{p_end}
{phang2}{cmd:. xtqqplot, heatmap}{p_end}
{phang2}{cmd:. xtqqplot, heatmap combine}{p_end}
{phang2}{cmd:. xtqqplot, validate}{p_end}

{pstd}A coarser grid, values printed in the cells{p_end}
{phang2}{cmd:. xtqqr y x z, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9)}{p_end}
{phang2}{cmd:. xtqqplot, heatmap values}{p_end}

{pstd}Country-specific quantiles and time effects (Atsalakis et al. 2021){p_end}
{phang2}{cmd:. xtqqr y x z, xref(unit) timefe bw(0.10)}{p_end}

{pstd}Pooled QQ (Wu et al. 2021){p_end}
{phang2}{cmd:. xtqqr y x, fe(none)}{p_end}

{pstd}Quantile-group panel QQ with a lagged regressor (Clance et al.){p_end}
{phang2}{cmd:. xtqqr y L.x, method(groups) groups(4) timefe}{p_end}

{pstd}Panel block bootstrap{p_end}
{phang2}{cmd:. xtqqr y x z, tau(0.1(0.2)0.9) theta(0.1(0.2)0.9) vce(bootstrap) reps(200) seed(1)}{p_end}

{pstd}A complete worked script ships with the package: {cmd:net get xtqqr}, then {cmd:do xtqqr_example.do}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtqqr} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panel units{p_end}
{synopt:{cmd:e(bw)}}bandwidth{p_end}
{synopt:{cmd:e(n_tau)}}number of tau levels{p_end}
{synopt:{cmd:e(n_theta)}}number of theta levels (groups - 1 with {cmd:method(groups)}){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(groups)}}number of quantile groups ({cmd:method(groups)}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtqqr}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(qqvar)}}QQ regressor{p_end}
{synopt:{cmd:e(controls)}}control variables{p_end}
{synopt:{cmd:e(ivar)}, {cmd:e(tvar)}}panel and time variables{p_end}
{synopt:{cmd:e(fe)}, {cmd:e(timefe)}}treatment of unit and time effects{p_end}
{synopt:{cmd:e(xref)}}{cmd:pooled} or {cmd:unit}{p_end}
{synopt:{cmd:e(method)}}{cmd:kernel} or {cmd:groups}{p_end}
{synopt:{cmd:e(kernel)}}kernel{p_end}
{synopt:{cmd:e(vce)}}variance estimator{p_end}
{synopt:{cmd:e(taulist)}, {cmd:e(thetalist)}}the grids{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(coef)}}tau x theta matrix of slopes b1(tau, theta){p_end}
{synopt:{cmd:e(se)}}standard errors{p_end}
{synopt:{cmd:e(t)}}z statistics{p_end}
{synopt:{cmd:e(p)}}p-values (normal approximation){p_end}
{synopt:{cmd:e(r2)}}kernel-weighted pseudo R-squared of each local fit{p_end}
{synopt:{cmd:e(nobs)}}effective (Kish) sample size per theta; observations per group with {cmd:method(groups)}{p_end}
{synopt:{cmd:e(tau)}, {cmd:e(theta)}}the grids as column vectors{p_end}
{synopt:{cmd:e(qrcomp)}}with {opt validate}: b_QR, se_QR, p_QR, QQ average, its sd over theta, difference{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Atsalakis, G. S., E. Bouri, and F. Pasiouras. 2021. Natural disasters and
economic growth: a quantile on quantile approach. {it:Annals of Operations Research}.
{browse "https://doi.org/10.1007/s10479-020-03535-6":doi:10.1007/s10479-020-03535-6}

{phang}
Canay, I. A. 2011. A simple approach to quantile regression for panel data.
{it:Econometrics Journal} 14: 368-386.
{browse "https://doi.org/10.1111/j.1368-423X.2011.00349.x":doi:10.1111/j.1368-423X.2011.00349.x}

{phang}
Clance, M., G. Gozgor, R. Gupta, and C. K. M. Lau. The relationship between
economic uncertainty and corporate tax rates. Working paper, University of
Pretoria.

{phang}
Geraci, M., and M. Bottai. 2014. Linear quantile mixed models.
{it:Statistics and Computing} 24: 461-479.

{phang}
Hassan, M. S., M. Iqbal, and N. Arshed. 2021. Distribution-based effects of
disaggregated GDP and environmental quality: a case of quantile on quantile
estimates. {it:Environmental Science and Pollution Research}.

{phang}
Koenker, R. 2004. Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74-89.
{browse "https://doi.org/10.1016/j.jmva.2004.05.006":doi:10.1016/j.jmva.2004.05.006}

{phang}
Parente, P. M. D. C., and J. M. C. Santos Silva. 2016. Quantile regression
with clustered data. {it:Journal of Econometric Methods} 5: 1-15.
{browse "https://doi.org/10.1515/jem-2014-0011":doi:10.1515/jem-2014-0011}

{phang}
Powell, J. L. 1991. Estimation of monotonic regression models under quantile
restrictions. In {it:Nonparametric and Semiparametric Methods in Econometrics},
ed. W. Barnett, J. Powell, and G. Tauchen, 357-384. Cambridge University Press.

{phang}
Sim, N., and H. Zhou. 2015. Oil prices, US stock return, and the dependence
between their quantiles. {it:Journal of Banking and Finance} 55: 1-12.
{browse "https://doi.org/10.1016/j.jbankfin.2015.01.013":doi:10.1016/j.jbankfin.2015.01.013}

{phang}
Wu, C.-F., T. Chang, C.-M. Wang, T.-P. Wu, M.-C. Lin, and S.-C. Huang. 2021.
Measuring the impact of health on economic growth using pooling data in
regions of Asia: evidence from a quantile-on-quantile analysis.
{it:Frontiers in Public Health} 9: 689610.
{browse "https://doi.org/10.3389/fpubh.2021.689610":doi:10.3389/fpubh.2021.689610}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the package and the original papers when using {cmd:xtqqr}.
{p_end}
