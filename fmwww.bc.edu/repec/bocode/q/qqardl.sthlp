{smcl}
{* *! version 1.1.0  25nov2026}{...}
{vieweralsosee "qqardl methods" "help qqardl_methods"}{...}
{vieweralsosee "ardl (if installed)" "help ardl"}{...}
{vieweralsosee "qardl (if installed)" "help qardl"}{...}
{vieweralsosee "qqr (if installed)" "help qqr"}{...}
{viewerjumpto "Syntax" "qqardl##syntax"}{...}
{viewerjumpto "Description" "qqardl##description"}{...}
{viewerjumpto "Options" "qqardl##options"}{...}
{viewerjumpto "Interpreting the output" "qqardl##output"}{...}
{viewerjumpto "Remarks" "qqardl##remarks"}{...}
{viewerjumpto "Examples" "qqardl##examples"}{...}
{viewerjumpto "Stored results" "qqardl##results"}{...}
{viewerjumpto "References" "qqardl##references"}{...}
{viewerjumpto "Version history" "qqardl##history"}{...}
{viewerjumpto "Author" "qqardl##author"}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{bf:qqardl} {hline 2}}Quantile-on-Quantile ARDL (QQARDL) bounds test,
long-run, short-run and error-correction coefficients{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:qqardl} {depvar} {it:indepvar} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tau(numlist)}}quantile levels of {depvar}; default
{cmd:0.05 0.1 0.2 ... 0.9 0.95} (11 levels){p_end}
{synopt:{opt theta(numlist)}}quantile levels of {it:indepvar}; default as {opt tau()}{p_end}
{synopt:{opt lag:s(p q)}}order of the error-correction form, Eq. (4); default {cmd:lags(1 1)}{p_end}
{synopt:{opt bt:est(eq1|ecm)}}bounds-test regression: Eq. (1) of Destek et al. (default) or Eq. (4){p_end}
{synopt:{opt btl:ags(a b)}}lagged differences of y and x in Eq. (1); default {cmd:btlags(1 1)}{p_end}
{synopt:{opt lrt:ype(multiplier|beta)}}long run as -b1/d0 (default) or as the coefficient b1 of Eq. (4){p_end}
{synopt:{opt lrall}}report the long run for all pairs, not only cointegrated ones{p_end}
{synopt:{opt vce(ols|robust)}}standard errors of the coefficients; default {cmd:ols}{p_end}
{synopt:{opt noboundspval}}use the asymptotic PSS bounds instead of
Kripfganz-Schneider p-values{p_end}

{syntab:Output}
{synopt:{opt notab:le}}suppress the four result grids{p_end}
{synopt:{opt nogr:aph}}suppress the heatmaps{p_end}
{synopt:{opt col:ormap(name)}}{cmd:parula} (default), {cmd:bwr} (blue-white-red centred at 0, as in
Destek et al. 2025), {cmd:jet}, {cmd:viridis} or {cmd:redblue}{p_end}
{synopt:{opt val:ues}}print coefficient values in the heatmap cells{p_end}
{synopt:{opt graphn:ame(name)}}stub of the graph names; default {cmd:qqardl}{p_end}
{synopt:{opt gen:qser(stub)}}store the quantile series as {it:stub}{cmd:_y}{it:##} and {it:stub}{cmd:_x}{it:##}{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the grid of results (one row per quantile pair){p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (not {helpb xtset}) and the estimation sample
must be a contiguous span without gaps.  Time-series operators are allowed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:qqardl} implements the Quantile-on-Quantile Autoregressive Distributed Lag
(QQARDL) approach introduced by Destek, Radulescu, Ozkan and Balsalobre-Lorente
(2025) and applied by Balci and Dogan (2026).  Following Jordan and Philips (2018)
the lags are fixed at one.  For every quantile {it:tau} of {depvar} and every
quantile {it:theta} of {it:indepvar} it

{p 8 12 2}1. builds the {it:quantile series} (QSER) of Li (2022) of {depvar} at
{it:tau} and of {it:indepvar} at {it:theta};{p_end}
{p 8 12 2}2. runs the bounds-test regression of Destek et al. (2025, Eq. 1)

{p 12 12 2}
D.y{c 94}tau = c + w1 LD.y{c 94}tau + w2 LD.x{c 94}theta + g1 L.y{c 94}tau + g2 L.x{c 94}theta + e

{p 12 12 2}
and the Pesaran, Shin and Smith (2001) F test of H0: g1 = g2 = 0 (Eqs. 2-3), with
finite-sample p-values of Kripfganz and Schneider (2020); a pair is cointegrated
when p < 0.10, i.e. F exceeds the 10% I(1) critical value;{p_end}
{p 8 12 2}3. estimates the error-correction form (Eq. 4)

{p 12 12 2}
D.y{c 94}tau = a0 + d0 L.y{c 94}tau + d1 D.x{c 94}theta + b1 L.x{c 94}theta + e

{p 12 12 2}
and reports the error-correction term d0 and the short-run coefficient d1 for all
pairs, and the long-run coefficient only for the cointegrated pairs (as in
Destek et al. 2025, p. 4).  Both regressions are estimated by ordinary least
squares on the two quantile series.{p_end}

{pstd}
The results are displayed as four {it:theta} x {it:tau} grids with significance
stars and drawn as heatmaps in the layout of Balci and Dogan (2026, Figs. 3-6):
quantiles of {depvar} on the horizontal axis, quantiles of {it:indepvar} on the
vertical axis.

{pstd}
The quantile series is computed by a Mata port of the R package {bf:qfa}
({cmd:qdft()} followed by {cmd:qdft2qser()}): trigonometric quantile regressions
at every Fourier frequency, solved with a Frisch-Newton interior-point algorithm,
followed by the inverse Fourier transform.  See {help qqardl_methods} for the
step-by-step derivation and the validation.


{marker options}{...}
{title:Options}

{phang}
{opt tau(numlist)} and {opt theta(numlist)} set the quantile grids.  The default
grid is the one of Balci and Dogan (2026, Eq. 6).

{phang}
{opt btest(eq1)} (default) uses Eq. (1) of Destek et al. (2025) for the bounds test;
{opt btest(ecm)} uses the error-correction form of Eq. (4) instead.  {opt btlags(a b)}
sets the number of lagged differences of y and x in Eq. (1).

{phang}
{opt lrtype(multiplier)} (default) reports the long-run multiplier -b1/d0 with a
delta-method standard error, the elasticity interpreted in both papers;
{opt lrtype(beta)} reports the level coefficient b1 of Eq. (4), which Destek et al.
(2025) label "the long-run coefficient".  {opt lrall} shows the long run for every
pair instead of the cointegrated pairs only.

{phang}
{opt lags(p q)} sets the order of the error-correction form.  {cmd:lags(1 1)} is Eq. (4).  With {it:p}>1
the regression adds {it:p}-1 lagged differences of the dependent quantile series;
with {it:q}>1 it adds lagged differences of the regressor series.  Balci and Dogan
use {cmd:lags(1 2)}, {cmd:lags(2 1)} and {cmd:lags(2 2)} as robustness checks.

{phang}
{opt vce(robust)} uses heteroskedasticity-robust (HC1) standard errors for the
coefficients and the long-run effect.  The bounds F test always uses the
classical variance, as in Pesaran, Shin and Smith (2001).

{phang}
{opt noboundspval}: by default the bounds-test p-values come from
{cmd:ardlbounds} (Kripfganz and Schneider 2020, finite sample, case III, upper
I(1) bound).  If {cmd:ardlbounds} is not installed, or with this option, stars
are assigned from the asymptotic PSS case III I(1) critical values
(4.78, 5.73, 7.84 for k = 1).

{phang}
{opt genqser(stub)} stores the quantile series as new variables, e.g.
{cmd:qs_y05}, {cmd:qs_y50}, {cmd:qs_x95}.

{phang}
{opt saving(filename[, replace])} saves a dataset with variables {cmd:tau},
{cmd:theta}, {cmd:F}, {cmd:F_p}, {cmd:t_bdm}, {cmd:t_p}, {cmd:ect}, {cmd:ect_se},
{cmd:ect_p}, {cmd:lr}, {cmd:lr_se}, {cmd:lr_p}, {cmd:sr}, {cmd:sr_se},
{cmd:sr_p} and {cmd:r2}.


{marker output}{...}
{title:Interpreting the output}

{pstd}
Each grid has the quantiles of {it:indepvar} ({it:theta}) in rows, highest first,
and the quantiles of {depvar} ({it:tau}) in columns.

{phang2}{bf:Bounds test F-statistic}: a star means H0 of no cointegration is
rejected using the upper, I(1), bound (p < 0.10 defines a cointegrated pair); i.e. cointegration between the {it:tau}
quantile series of {depvar} and the {it:theta} quantile series of {it:indepvar}.{p_end}
{phang2}{bf:Long-run coefficient} (cointegrated pairs only, '.' elsewhere): the equilibrium effect of {it:indepvar} on
{depvar} at that pair of quantiles.  With variables in logs it is an elasticity.{p_end}
{phang2}{bf:Short-run coefficient}: the impact effect of a change in
{it:indepvar}.{p_end}
{phang2}{bf:Error-correction term}: the speed of adjustment; a significant negative
value (between -1 and 0) confirms convergence to the long-run relationship.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Integration order.} As in any ARDL bounds test, {depvar} should be I(1) and
{it:indepvar} I(0) or I(1), never I(2).  Balci and Dogan use the quantile ADF test
({cmd:qadf}) for this pre-test.

{pstd}
{bf:Sample size.} The quantile series needs about (n/2) x (number of quantiles)
quantile regressions per variable; with n = 437 monthly observations and the
default grid this takes well under a minute.

{pstd}
{bf:Comparison with R.} For an odd sample size the quantile series equals that of
R {bf:qfa::qser()} to about 1e-6.  When n is composite, some trigonometric quantile
regressions have non-unique solutions (all equally optimal); R's simplex picks an
arbitrary vertex while {cmd:qqardl} returns the centre of the solution set, so the
series can differ by an amount within the non-uniqueness interval.  See
{help qqardl_methods##nonunique:qqardl methods}.

{pstd}
{bf:Two regressions.} Following Destek et al. (2025), cointegration is tested with
Eq. (1), which contains lagged differences, while the reported coefficients come from
the error-correction form, Eq. (4).  {cmd:btest(ecm)} tests within Eq. (4).

{pstd}
{bf:What the method does not provide.} The bounds-test p-values treat the quantile
series as observed data; they do not account for the estimation of the series.


{marker examples}{...}
{title:Examples}

{pstd}Simulated cointegrated monthly data{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 2026}{p_end}
{phang2}{cmd:. set obs 241}{p_end}
{phang2}{cmd:. gen t = tm(2005m1) + _n - 1}{p_end}
{phang2}{cmd:. format t %tm}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen x = 0}{p_end}
{phang2}{cmd:. replace x = L.x + 0.02 + rnormal(0, 0.1) in 2/l}{p_end}
{phang2}{cmd:. gen y = 1}{p_end}
{phang2}{cmd:. replace y = L.y + 0.5 - 0.3*(L.y - L.x) + 0.4*D.x + rnormal(0, 0.1) in 2/l}{p_end}

{pstd}QQARDL(1,1) on the default 11 x 11 grid{p_end}
{phang2}{cmd:. qqardl y x}{p_end}

{pstd}Robustness: ARDL(2,2), robust standard errors, a coarser grid, values in the cells{p_end}
{phang2}{cmd:. qqardl y x, lags(2 2) vce(robust) tau(0.1(0.2)0.9) values}{p_end}

{pstd}Figures in the colours of Destek et al. (2025); long run as the coefficient b1{p_end}
{phang2}{cmd:. qqardl y x, colormap(bwr) lrtype(beta)}{p_end}

{pstd}Keep the quantile series and save the grid{p_end}
{phang2}{cmd:. qqardl y x, genqser(qs) saving(qq_results, replace) nograph}{p_end}
{phang2}{cmd:. matrix list r(lr)}{p_end}

{pstd}A complete worked example is in {cmd:qqardl_example.do} ({stata "net get qqardl":net get qqardl}).{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:qqardl} stores the following in {cmd:r()}:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations in the error-correction regression, Eq. (4){p_end}
{synopt:{cmd:r(N_bt)}}observations in the bounds-test regression, Eq. (1){p_end}
{synopt:{cmd:r(p)}, {cmd:r(q)}}ARDL order{p_end}
{synopt:{cmd:r(df_r)}}residual degrees of freedom{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:qqardl}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvar)}}variables{p_end}
{synopt:{cmd:r(tau)}, {cmd:r(theta)}}quantile grids{p_end}
{synopt:{cmd:r(vce)}}{cmd:ols} or {cmd:robust}{p_end}
{synopt:{cmd:r(pvsource)}}source of the bounds-test p-values{p_end}
{synopt:{cmd:r(btest)}, {cmd:r(lrtype)}}bounds-test equation and long-run definition{p_end}

{p2col 5 16 20 2: Matrices (rows theta, columns tau)}{p_end}
{synopt:{cmd:r(F)}, {cmd:r(F_p)}}bounds F statistic and I(1) p-value{p_end}
{synopt:{cmd:r(coint)}}1 if the pair is cointegrated (p < 0.10){p_end}
{synopt:{cmd:r(t_bdm)}, {cmd:r(t_p)}}t statistic on a1 and I(1) p-value{p_end}
{synopt:{cmd:r(ect)}, {cmd:r(ect_se)}, {cmd:r(ect_p)}}error-correction term{p_end}
{synopt:{cmd:r(lr)}, {cmd:r(lr_se)}, {cmd:r(lr_p)}}long-run coefficient (all pairs; mask with {cmd:r(coint)}){p_end}
{synopt:{cmd:r(sr)}, {cmd:r(sr_se)}, {cmd:r(sr_p)}}short-run coefficient{p_end}
{synopt:{cmd:r(r2)}}R-squared{p_end}
{synopt:{cmd:r(qser_y)}, {cmd:r(qser_x)}}quantile series (n x number of quantiles){p_end}


{marker references}{...}
{title:References}

{phang}
Balci, N. and M. Dogan. 2026. Financial development and the U.S. renewable energy
transition: A quantile-on-quantile ARDL analysis across geothermal, solar, wind,
and biomass consumption. {it:Energy Sources, Part B} 21(1): 2726983.
doi:10.1080/15567249.2026.2726983.

{phang}
Destek, M. A., M. Radulescu, O. Ozkan and D. Balsalobre-Lorente. 2025. The hidden
cost of renewable energy: A quantile view for environmental management on critical
metals. {it:Journal of Environmental Management} 389: 126089.
doi:10.1016/j.jenvman.2025.126089.

{phang}
Jordan, S. and A. Q. Philips. 2018. Cointegration testing and dynamic simulations
of autoregressive distributed lag models. {it:Stata Journal} 18(4): 902-923.
doi:10.1177/1536867X1801800409.

{phang}
Kripfganz, S. and D. C. Schneider. 2020. Response surface regressions for critical
value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics} 82(6): 1456-1481.
doi:10.1111/obes.12377.

{phang}
Li, T.-H. 2022. Quantile Fourier transform, quantile series, and nonparametric
estimation of quantile spectra. arXiv:2211.05844. doi:10.48550/arXiv.2211.05844.
Published 2025 in {it:Communications in Statistics - Simulation and Computation} 55: 1-22.

{phang}
Pesaran, M. H., Y. Shin and R. J. Smith. 2001. Bounds testing approaches to the
analysis of level relationships. {it:Journal of Applied Econometrics} 16(3):
289-326. doi:10.1002/jae.616.


{marker history}{...}
{title:Version history}

{phang}1.1.0 (25nov2026): bounds test from Eq. (1) of Destek et al. (2025)
({opt btest()}, {opt btlags()}); cointegration decision p < 0.10 and {cmd:r(coint)};
long run for cointegrated pairs only ({opt lrall}, {opt lrtype()});
{cmd:colormap(bwr)}; QSER reference Li (2022).{p_end}
{phang}1.0.0 (25nov2026): first release.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
