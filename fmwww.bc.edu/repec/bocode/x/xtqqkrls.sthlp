{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "xtqqr" "help xtqqr"}{...}
{vieweralsosee "xtqqplot" "help xtqqplot"}{...}
{vieweralsosee "xtqqr methods" "help xtqqr_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "krls (SSC)" "help krls"}{...}
{viewerjumpto "Syntax" "xtqqkrls##syntax"}{...}
{viewerjumpto "Description" "xtqqkrls##description"}{...}
{viewerjumpto "Options" "xtqqkrls##options"}{...}
{viewerjumpto "Interpreting the output" "xtqqkrls##output"}{...}
{viewerjumpto "Remarks" "xtqqkrls##remarks"}{...}
{viewerjumpto "Examples" "xtqqkrls##examples"}{...}
{viewerjumpto "Stored results" "xtqqkrls##results"}{...}
{viewerjumpto "References" "xtqqkrls##references"}{...}
{viewerjumpto "Author" "xtqqkrls##author"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:xtqqkrls} {hline 2}}Panel quantile-on-quantile kernel regularized least squares (PQQKRLS){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtqqkrls} {depvar} {it:qqvar} [{it:othervars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Quantile grid}
{synopt:{opt tau(numlist)}}quantiles of the distribution of pointwise effects; default {cmd:0.05(0.05)0.95}{p_end}
{synopt:{opt theta(numlist)}}quantiles of {it:qqvar}; default {cmd:0.05(0.05)0.95}{p_end}

{syntab:theta-regimes}
{synopt:{opt sub:set(lower|band)}}{cmd:lower}: x <= Q_theta(x) (default); {cmd:band}: |F_n(x) - theta| <= {opt bw()}{p_end}
{synopt:{opt bw(#)}}half-width of the band on the probability scale; default {cmd:0.10}{p_end}
{synopt:{opt xref(pooled|unit)}}quantiles of {it:qqvar} from the pooled sample (default) or within each unit{p_end}
{synopt:{opt min:obs(#)}}smallest regime that is estimated; default {cmd:20}{p_end}

{syntab:Panel effects}
{synopt:{opt fe(none|within)}}{cmd:none}: pooled country-year data (default, as in the papers); {cmd:within}: unit demeaning{p_end}
{synopt:{opt time:fe}}also remove period means{p_end}

{syntab:KRLS}
{synopt:{opt l:ambda(#)}}regularization parameter; default: leave-one-out choice of {cmd:krls}{p_end}
{synopt:{opt s:igma(#)}}kernel bandwidth; default: number of KRLS inputs (Hainmueller and Hazlett 2014){p_end}

{syntab:Inference}
{synopt:{opt boot(fast|refit|none)}}unit-block bootstrap of the cell estimates; default {cmd:fast}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:200}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt notab:le}}suppress the tables{p_end}
{synopt:{opt block(#)}}theta columns per table block; default {cmd:8}{p_end}
{synopt:{opt gr:aph}}draw the heatmap after estimation{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the surface in long format{p_end}
{synopt:{opt nodots}}suppress the progress dots{p_end}
{synoptline}
{pstd}
The data must be {helpb xtset}. {cmd:xtqqkrls} calls {cmd:krls}
(Hainmueller and Hazlett), which must be installed:
{stata ssc install krls}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqqkrls} implements the quantile-on-quantile KRLS (QQKRLS) of
Adebayo, Ozkan and Eweade (2024) for panel data (PQQKRLS, Sonail et al.
2026). Kernel regularized least squares (Hainmueller and Hazlett 2014)
learns the conditional mean function y = f(x, othervars) without a
functional-form assumption and delivers a {it:pointwise} marginal effect
of {it:qqvar} at every observation:

{p 8 8 2}
dy/dx_k = -(2/sigma) Sum_i c_i exp(-||x_i - x_k||^2 / sigma) (x_i - x_k)

{pstd}
QQKRLS adds the quantile-on-quantile dimension. For each theta, KRLS is fit
on the theta-regime of {it:qqvar}; the tau-quantile of the pointwise
effects in that regime is reported as {bf:beta(tau, theta)}. In the panel
version the observations are country-years, and the pointwise effects of
all units in the regime form the distribution whose quantiles are taken.

{pstd}
For each regime the command also reports the KRLS {it:average} pointwise
effect with its analytic standard error, the summary measure of
Hainmueller and Hazlett (2014).


{marker options}{...}
{title:Options}

{phang}
{opt tau(numlist)} gives the quantiles of the distribution of the
pointwise marginal effects inside each regime (the tau dimension of the
QQKRLS heatmaps).

{phang}
{opt theta(numlist)} gives the quantiles of {it:qqvar} that define the
regimes.

{phang}
{opt subset(lower)}, the default, defines the theta-regime as all
observations with x <= Q_theta(x). This is the construction of the
reference QQKRLS implementations. Regimes are nested: theta = 0.95 uses
95% of the sample.
{opt subset(band)} uses the observations whose rank lies within
{opt bw()} of theta: a local window, closer to the kernel logic of Sim
and Zhou (2015), with non-nested regimes.

{phang}
{opt xref(unit)} computes the quantiles (or ranks) of {it:qqvar} within
each panel unit.

{phang}
{opt fe(within)} removes unit means from {depvar}, {it:qqvar} and
{it:othervars} before KRLS. The regimes are still defined on the original
level of {it:qqvar}. Use it when the unit effects may be correlated with
{it:qqvar}: KRLS on pooled levels then attributes cross-country level
differences to {it:qqvar}. {opt timefe} removes period means (two-way
demeaning by alternating projections when combined with {opt fe(within)}).

{phang}
{opt lambda(#)} and {opt sigma(#)} are passed to {cmd:krls}. By default
sigma equals the number of inputs and lambda minimizes the leave-one-out
error, as in Hainmueller and Hazlett (2014).

{phang}
{opt boot(fast)}, the default, resamples panel units with replacement
within each regime and recomputes the tau-quantiles of their pointwise
effects (the KRLS fit is held fixed). {opt boot(refit)} re-estimates KRLS
on each resample with lambda and sigma fixed at the full-sample values,
which also reflects estimation error in the effects (slow: reps x theta
KRLS fits). {opt boot(none)} reports point estimates only.

{phang}
{opt minobs(#)} skips regimes with fewer observations; those cells are
missing (white in the heatmap).


{marker output}{...}
{title:Interpreting the output}

{phang}
{bf:QQKRLS effects.} Rows are tau, columns theta. A cell is the
tau-quantile of the pointwise effects of {it:qqvar} among the observations
of the theta-regime. A row near tau = 0.5 is the typical effect; the
spread between tau = 0.1 and 0.9 within a column measures how
heterogeneous the effect is at that level of {it:qqvar}.

{phang}
{bf:Average pointwise marginal effect by theta-regime.} The KRLS average
effect, its analytic standard error and p-value, the selected lambda, the
in-sample R-squared and the size of the regime. A changing average
effect across theta is evidence of nonlinearity in {it:qqvar}.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:What tau means here.} In {cmd:xtqqr}, tau is a quantile of the
outcome. In QQKRLS, following Adebayo et al. (2024), tau indexes the
distribution of KRLS pointwise effects; KRLS models the conditional mean.
Interpret the heatmap accordingly.

{pstd}
{bf:Computation.} KRLS builds an n x n kernel matrix for each regime; with
nested regimes the largest has about 0.95 N observations. Up to N = 2,000
a 19-level theta grid runs in minutes; beyond 5,000 the command warns.

{pstd}
{bf:Fixed effects.} In simulations where unit effects are correlated with
{it:qqvar}, the pooled fit attributes level differences to {it:qqvar} and
overstates its effect; {opt fe(within)} recovers the true slope.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xtqqkrls y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) seed(1)}{p_end}
{phang2}{cmd:. xtqqplot, heatmap}{p_end}
{phang2}{cmd:. xtqqplot, ame}{p_end}

{phang2}{cmd:. xtqqkrls y x z, fe(within) subset(band) bw(0.15) seed(1)}{p_end}
{phang2}{cmd:. xtqqkrls y x z, fe(within) boot(refit) reps(50) theta(0.2(0.2)0.8) seed(1)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(N_g)}}observations and panel units{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(n_tau)}, {cmd:e(n_theta)}}grid sizes{p_end}
{synopt:{cmd:e(bw)}, {cmd:e(minobs)}}band half-width and minimum regime size{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtqqkrls}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(qqvar)}, {cmd:e(controls)}}variables{p_end}
{synopt:{cmd:e(fe)}, {cmd:e(timefe)}, {cmd:e(xref)}, {cmd:e(subset)}, {cmd:e(boot)}}options used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(coef)}}tau x theta matrix beta(tau, theta){p_end}
{synopt:{cmd:e(se)}, {cmd:e(t)}, {cmd:e(p)}}bootstrap s.e., z statistics, p-values{p_end}
{synopt:{cmd:e(ame)}}theta x 7: average effect, s.e., p, lambda, sigma, R2, regime size{p_end}
{synopt:{cmd:e(tau)}, {cmd:e(theta)}}the grids{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Adebayo, T. S., O. Ozkan, and B. S. Eweade. 2024. Do energy efficiency R&D
investments and information and communication technologies promote
environmental sustainability in Sweden? A quantile-on-quantile KRLS
investigation. {it:Journal of Cleaner Production} 440: 140832.
{browse "https://doi.org/10.1016/j.jclepro.2024.140832":doi:10.1016/j.jclepro.2024.140832}

{phang}
Adebayo, T. S., M. S. Meo, B. S. Eweade, and O. Ozkan. 2024. Analyzing the
effects of solar energy innovations, digitalization, and economic
globalization on environmental quality in the United States.
{it:Clean Technologies and Environmental Policy} 26: 4157-4176.
{browse "https://doi.org/10.1007/s10098-024-02831-0":doi:10.1007/s10098-024-02831-0}

{phang}
Hainmueller, J., and C. Hazlett. 2014. Kernel regularized least squares:
reducing misspecification bias with a flexible and interpretable machine
learning approach. {it:Political Analysis} 22: 143-168.
{browse "https://doi.org/10.1093/pan/mpt019":doi:10.1093/pan/mpt019}

{phang}
Li, G., Y. Li, and C.-L. Tsai. 2015. Quantile correlations and quantile
autoregressive modeling. {it:Journal of the American Statistical Association}
110: 246-261.
{browse "https://doi.org/10.1080/01621459.2014.892007":doi:10.1080/01621459.2014.892007}

{phang}
Sim, N., and H. Zhou. 2015. Oil prices, US stock return, and the dependence
between their quantiles. {it:Journal of Banking and Finance} 55: 1-12.
{browse "https://doi.org/10.1016/j.jbankfin.2015.01.013":doi:10.1016/j.jbankfin.2015.01.013}

{phang}
Sonail, M., D. Xu, Z. Hassan, F. Fazal, and M. A. Sadat. 2026. Artificial
intelligence, tourism development, and ecological footprint in advanced
economies: evidence from MMQR and PQQKRLS approaches. {it:Economies} 14: 338.
{browse "https://doi.org/10.3390/economies14080338":doi:10.3390/economies14080338}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
