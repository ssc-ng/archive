{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "dvar methods" "help dvar_methods"}{...}
{vieweralsosee "var" "help var"}{...}
{vieweralsosee "logit" "help logit"}{...}
{viewerjumpto "Syntax" "dvar##syntax"}{...}
{viewerjumpto "Description" "dvar##description"}{...}
{viewerjumpto "dvar fit" "dvar##fit"}{...}
{viewerjumpto "dvar joint" "dvar##joint"}{...}
{viewerjumpto "dvar irf" "dvar##irf"}{...}
{viewerjumpto "dvar forecast" "dvar##forecast"}{...}
{viewerjumpto "dvar kernel" "dvar##kernel"}{...}
{viewerjumpto "dvar palette" "dvar##palette"}{...}
{viewerjumpto "Interpreting the output" "dvar##output"}{...}
{viewerjumpto "Remarks" "dvar##remarks"}{...}
{viewerjumpto "Examples" "dvar##examples"}{...}
{viewerjumpto "Stored results" "dvar##results"}{...}
{viewerjumpto "References" "dvar##references"}{...}
{viewerjumpto "Author" "dvar##author"}{...}
{title:Title}

{phang}
{bf:dvar} {hline 2} Distributional vector autoregression, multimodal joint
predictive distributions and distributional impulse responses


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:dvar fit} {varlist} {ifin} [{cmd:,} {it:{help dvar##fitopts:fit_options}}]

{p 8 16 2}
{cmd:dvar joint} {varlist} {ifin}{cmd:,} {opt at(date)} [{it:{help dvar##jointopts:joint_options}}]

{p 8 16 2}
{cmd:dvar irf} {varlist} {ifin}{cmd:,} {opt at(date)} {opth sh:ock(varname)}
{opt cf(spec)} [{it:{help dvar##irfopts:irf_options}}]

{p 8 16 2}
{cmd:dvar forecast} {varlist} {ifin}{cmd:,} {opt start(date)} [{it:{help dvar##fcopts:forecast_options}}]

{p 8 16 2}
{cmd:dvar kernel} {varlist} {ifin}{cmd:,} {opt at(date)} [{it:{help dvar##kernelopts:kernel_options}}]

{p 8 16 2}
{cmd:dvar palette} [{it:name}] [{cmd:,} {opt n(#)} {opt nograph}]

{pstd}
The data must be {helpb tsset} (one time series, no panel). The order of
{varlist} is the order of the distribution factorisation, i.e. the recursive
(triangular) identification scheme: the first variable is conditioned only on
the lags, the second on the lags and the first, and so on.
{it:date} is written in the display format of the time variable, e.g.
{cmd:at(2008q4)}, or as a number.

{p 4 4 2}
Common estimation options (all subcommands except {cmd:kernel} and {cmd:palette}):

{synoptset 22 tabbed}{...}
{synopthdr:common options}
{synoptline}
{synopt:{opt l:ags(#)}}number of lags in Z_t; default depends on the subcommand{p_end}
{synopt:{opt grid(#)}}number of thresholds per variable; default {cmd:99} (the 1st,...,99th empirical percentiles){p_end}
{synopt:{opt lam:bda(#)}}elastic-net penalty; default {cmd:0.0005} as in the replication code; {cmd:0} = maximum likelihood, eq. (6){p_end}
{synopt:{opt alp:ha(#)}}elastic-net mixing weight (1 = lasso, 0 = ridge); default {cmd:0.2}{p_end}
{synopt:{opt link(logit|probit)}}link function Lambda in eq. (2); default {cmd:logit}{p_end}
{synopt:{opt draw:s(#)}}Monte Carlo draws from the predictive distribution{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt nogr:aph}}suppress graphs{p_end}
{synopt:{opt notab:le}}suppress the results table{p_end}
{synopt:{opt name(stub)}}stub for graph names{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dvar} implements the {bf:distributional vector autoregression} (DVAR) of
Wang, Oka and Zhu (2025). The joint distribution of a vector Y_t conditional on
its past Z_t is factorised into a chain of univariate conditional distributions,

{p 12 12 2}
F(Y_t | Z_t) = rho( F(Y_1t | X_1t), ..., F(Y_Jt | X_Jt) ),
X_1t = (1, Z_t), X_jt = (1, Z_t, Y_1t, ..., Y_j-1,t),

{pstd}
and each univariate conditional distribution is estimated by
{bf:distribution regression} (DR): for every threshold y on a grid, a binary
logit (or probit) of 1{Y_jt <= y} on X_jt,

{p 12 12 2}
F(y_j | x_j) = Lambda( x_j' theta_j(y_j) ).

{pstd}
The fitted conditional CDFs are monotonised by rearrangement (Chernozhukov,
Fernandez-Val and Galichon 2009). Joint draws are generated sequentially
(Algorithm 1 of the paper). Multi-step distributions use local projections:
Y_t+h is regressed directly on (Y_t, Z_t).

{pstd}
The package also implements the nonparametric {bf:kernel} estimator of the
conditional joint distribution of Adrian, Boyarchenko and Giannone (2021).
That paper documents multimodality in the joint distribution of US GDP growth
and financial conditions, and the DVAR paper benchmarks against it.

{pstd}
All heat maps and contour plots use the MATLAB {bf:Parula} colour map by
default (64 stops, the same palette as the author's QQR packages); {cmd:jet},
{cmd:turbo}, {cmd:bluered}, {cmd:sinha}, {cmd:viridis} and {cmd:gray} are
available through {opt colorscale()}.

{pstd}
The equation-by-equation derivation and the map from every step of the code
to the paper are in {help dvar_methods:help dvar_methods}.


{marker fit}{...}
{title:dvar fit}

{pstd}
Estimates the DR system at horizon {opt horizon()} and reports the
coefficient processes theta_j(y) at the thresholds Q_tau(Y_j), with sandwich
standard errors H^-1 Sigma H^-1 (Theorem 1), where Sigma is a Bartlett
long-run covariance of the scores. It also reports the average McFadden
pseudo-R2 and a Kolmogorov-Smirnov test on the in-sample Rosenblatt PITs of
each factorised conditional.

{marker fitopts}{...}
{synoptset 22 tabbed}{...}
{synopthdr:fit_options}
{synoptline}
{synopt:{opt l:ags(#)}}lags in Z_t; default {cmd:3}{p_end}
{synopt:{opt h:orizon(#)}}direct horizon of the regression; default {cmd:1}{p_end}
{synopt:{opth tau:s(numlist)}}quantile levels of the thresholds shown in the table; default {cmd:.1 .25 .5 .75 .9}{p_end}
{synopt:{opt hac(#)}}Bartlett lags for Sigma; default floor(4(T/100)^(2/9)); {cmd:0} = White{p_end}
{synopt:{opt l:evel(#)}}confidence level of the coefficient bands{p_end}
{synopt:{opt ins:ample}}one-step predictive quantiles, means and pairwise correlations for every period (Figure 3 of the paper){p_end}
{synopt:{opt gen:erate(stub)}}save the in-sample statistics as variables {it:stub}{cmd:_mean_}{it:var}, {it:stub}{cmd:_q05_}{it:var}, ..., {it:stub}{cmd:_corr_1_2}; implies {opt insample}{p_end}
{synopt:{opt plot:range(# #)}}range of threshold levels drawn in the coefficient plots; default {cmd:.05 .95}{p_end}
{synoptline}


{marker joint}{...}
{title:dvar joint}

{pstd}
Joint predictive distribution of a pair of outcomes for h = 1, ..., H periods
after the information date {opt at()} (Figure 4 of the paper). Each horizon
has its own local-projection DR system. The draws are smoothed with a
bivariate Gaussian kernel and drawn as filled Parula contours. The table
reports moments, the correlation and the number of modes of each joint
density.

{marker jointopts}{...}
{synoptset 22 tabbed}{...}
{synopthdr:joint_options}
{synoptline}
{synopt:{opt at(date)}}last period of the information set (required){p_end}
{synopt:{opth hor:izons(numlist)}}horizons; default {cmd:1 2 3 4}{p_end}
{synopt:{opt l:ags(#)}}lags; default {cmd:3}{p_end}
{synopt:{opth pair(varlist)}}the two variables to plot; default the first two{p_end}
{synopt:{opt real:time}}estimate each horizon only on data available at {opt at()}{p_end}
{synopt:{opt bw(# #)}}kernel bandwidths; default MATLAB {cmd:ksdensity} rule; the paper uses {cmd:bw(0.25 0.8)}{p_end}
{synopt:{opt ng:rid(#)}}grid points per axis; default {cmd:60}{p_end}
{synopt:{opt lev:els(#)}}contour levels; default {cmd:15}{p_end}
{synopt:{opt col:orscale(name)}}{cmd:parula} (default), {cmd:jet}, {cmd:turbo}, {cmd:bluered}, {cmd:sinha}, {cmd:viridis}, {cmd:gray}{p_end}
{synopt:{opt heat:map}}heat map instead of filled contours{p_end}
{synopt:{opt xr:ange(# #)} {opt yr:ange(# #)}}plot window{p_end}
{synopt:{opt mode:frac(#)}}a local maximum counts as a mode if it exceeds # x the peak; default {cmd:0.05}{p_end}
{synopt:{opt draw:s(#)}}default {cmd:20000}{p_end}
{synoptline}


{marker irf}{...}
{title:dvar irf}

{pstd}
Distributional impulse response functions, Definition 1 of the paper:
DIR_jh = F*(Y_j,t+h | Z_t) - F(Y_j,t+h | Z_t). At the shock date {opt at()}
the marginal of {opt shock()} in the joint distribution F(Y_t | Z_t) is
replaced by the counterfactual distribution G of {opt cf()}. Variables ordered
{it:before} the shocked variable keep their draws; variables ordered
{it:after} it are re-drawn conditionally on the new values. The baseline and
counterfactual draws are then propagated through the local projections
F(Y_t+h | Y_t, Z_t), h = 1, ..., H. The tables report the quantile IRF (QIRF)
and the moment IRF (MIRF) in the layout of Tables 1-2 of the paper.

{marker irfopts}{...}
{synoptset 26 tabbed}{...}
{synopthdr:irf_options}
{synoptline}
{synopt:{opt at(date)}}shock date, h = 0 (required){p_end}
{synopt:{opth sh:ock(varname)}}variable whose distribution is perturbed (required){p_end}
{synopt:{opt cf(spec)}}counterfactual G (required), see below{p_end}
{synopt:{opt hor:izon(#)}}H; default {cmd:4}{p_end}
{synopt:{opt inl:ags(#)}}lags of the h = 0 model F(Y_t|Z_t); default {cmd:3}{p_end}
{synopt:{opt l:ags(#)}}lags of the local projections, including Y_t; default {cmd:4}{p_end}
{synopt:{opt lpe:nd(date)}}last outcome date used by the local projections (the replication code uses {cmd:2019q4}){p_end}
{synopt:{opth qu:antiles(numlist)}}default {cmd:.05 .25 .5 .75 .95}{p_end}
{synopt:{opt rep:s(#)}}moving-block bootstrap replications (Appendix B.5); default {cmd:0}{p_end}
{synopt:{opt bl:ocklength(#)}}block length; default {cmd:8}{p_end}
{synopt:{opt joint}}also draw baseline and counterfactual joint contours{p_end}
{synopt:{opt draw:s(#)}}default {cmd:20000}{p_end}
{synoptline}

{pstd}
{it:spec} of {opt cf()}:

{p2colset 9 34 36 2}{...}
{p2col:{cmd:normal} {it:m s}}N(m, s^2){p_end}
{p2col:{cmd:tnormal} {it:m s a b}}N(m, s^2) truncated to (a, b) (paper, Sec. 4.4.1: {cmd:tnormal 0 0.2 -1.5 2}){p_end}
{p2col:{cmd:gamma} {it:k theta}}Gamma(shape k, scale theta){p_end}
{p2col:{cmd:tgamma} {it:k theta a b}}truncated gamma (paper, Sec. 4.4.2: {cmd:tgamma 0.6 6 0 11}){p_end}
{p2col:{cmd:uniform} {it:a b}}U(a, b){p_end}
{p2col:{cmd:point} {it:v}}point mass at v: the classical one-time impulse{p_end}
{p2col:{cmd:shift} {it:d}}baseline draws + d (location shock){p_end}
{p2col:{cmd:scale} {it:c}}baseline mean + c x (draw - mean) (uncertainty shock){p_end}
{p2colreset}{...}


{marker forecast}{...}
{title:dvar forecast}

{pstd}
Out-of-sample evaluation of the h-step DVAR predictive distributions over an
expanding window (Section 4.2). For every origin from {opt start()} to T-h, the
DR systems are re-estimated on the data available at the origin. The table
reports the RMSE of the predictive mean, the CRPS, the log predictive score,
quantile scores, and the Rossi and Sekhposyan (2019) uniformity test of the
PITs.

{marker fcopts}{...}
{synoptset 22 tabbed}{...}
{synopthdr:forecast_options}
{synoptline}
{synopt:{opt start(date)}}first forecast origin (required){p_end}
{synopt:{opt h:orizon(#)}}forecast horizon; default {cmd:1}{p_end}
{synopt:{opt l:ags(#)}}default {cmd:3}{p_end}
{synopt:{opth tau:s(numlist)}}quantile-score levels; default {cmd:.05 .1 .5 .9 .95}{p_end}
{synopt:{opt full:sample}}estimate once on the full sample, as the replication code does (not a true out-of-sample exercise){p_end}
{synopt:{opt nojoint}}skip the joint draws (faster); means and log scores then use the marginal DR{p_end}
{synopt:{opt gen:erate(stub)}}save PITs, quantiles, means, CRPS, log and quantile scores as variables{p_end}
{synopt:{opt draw:s(#)}}default {cmd:2000}{p_end}
{synoptline}


{marker kernel}{...}
{title:dvar kernel}

{pstd}
The Adrian, Boyarchenko and Giannone (2021) estimator, eq. (1):

{p 12 12 2}
p(y | x) = sum_t K_wy(y - y_t) K_wx(x - x_t) / sum_t K_wx(x - x_t),

{pstd}
with Gaussian product kernels and bandwidths w = c x sd. Multi-step
distributions come from Monte Carlo paths (their Algorithm 1). The paper
discretises the state space; {cmd:dvar kernel} samples exactly from the kernel
mixture instead, which is the limit of that grid. With {opt shock()} and
{opt cf()}, density impulse responses (their Algorithm 3) are computed with the
same perturbation logic as {cmd:dvar irf}.

{marker kernelopts}{...}
{synoptset 22 tabbed}{...}
{synopthdr:kernel_options}
{synoptline}
{synopt:{opt at(date)}}date t of the h = 0 distribution p(y_t | y_t-1, ...){p_end}
{synopt:{opt l:ags(#)}}lags in x; default {cmd:1} (as in the paper){p_end}
{synopt:{opt c(#)}}bandwidth constant; default {cmd:0.5}{p_end}
{synopt:{opth cv:grid(numlist)}}choose c by the out-of-sample one-step log predictive score (their Figure 2){p_end}
{synopt:{opt cvs:tart(date)}}first origin of the score; default one third of the sample{p_end}
{synopt:{opt hor:izon(#)}}default {cmd:4}{p_end}
{synopt:{opth sh:ock(varname)} {opt cf(spec)}}optional density impulse response{p_end}
{synopt:{opt draw:s(#)}}default {cmd:10000}{p_end}
{synoptline}


{marker palette}{...}
{title:dvar palette}

{pstd}
Displays and returns ({cmd:r(colors)}) the QQR colour maps interpolated to
{opt n(#)} colours, ready for {cmd:ccolors()} in {helpb twoway contour}:
{cmd:parula} (MATLAB R2014b, 64 stops), {cmd:jet}, {cmd:turbo}, {cmd:bluered},
{cmd:sinha}, {cmd:viridis}, {cmd:gray}.


{marker output}{...}
{title:Interpreting the output}

{pstd}
{bf:dvar fit.} Each equation block shows theta_j(y) at y = Q_tau(Y_j). A
{it:positive} coefficient raises Pr(Y_j <= y), i.e. it shifts probability
mass {it:below} y. Coefficients that change sign or size across tau are the
distributional heterogeneity a mean VAR cannot capture: for example, lagged
financial stress may matter mainly for the lower tail of GDP growth. Standard
errors are pointwise in y. Because of the rearrangement, the reported CDF is
monotone even when individual theta's cross. KS(PIT) > 1.34 signals a
mis-calibrated conditional distribution (5% level).

{pstd}
{bf:dvar joint.} {it:modes} > 1 means the joint predictive density has several
local peaks (e.g. a "good" and a "bad" regime, as in late 2008). In the paper
multimodality appears only under tight financial conditions and resolves
within a few quarters.

{pstd}
{bf:dvar irf.} {it:Base} rows describe the baseline distribution F; {it:Diff}
rows are QIRF_j,h(tau) = Q*(tau) - Q(tau) and MIRF = moment(F*) - moment(F).
With {opt reps()}, a star marks horizons whose bootstrap interval excludes 0.
The DIRF graph plots F*(y) - F(y): negative values mean the counterfactual
moved probability mass {it:above} y.

{pstd}
{bf:dvar forecast.} Lower RMSE, CRPS, LogS and QS are better. "pass" means the
PIT ECDF stays inside the 95% Rossi-Sekhposyan band, i.e. the predictive
distribution is not rejected as mis-calibrated.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:Sample size.} Every threshold regression has 1 + J x lags (+ j - 1)
coefficients. With quarterly macro data (T ~ 200) keep J x lags <= 12. The
small default elastic-net penalty stabilises the extreme thresholds, where
1{Y <= y} is almost always 0 or 1.

{pstd}
{bf:Ordering.} As in a Cholesky SVAR, the ordering matters for the
counterfactual at h = 0 only through the variables ordered after the shocked
one. The paper (Appendix B.2) finds the forecast distributions insensitive to
the ordering.

{pstd}
{bf:Draws.} QIRFs at the 5% and 95% quantiles need many draws: use at least
20,000. Baseline and counterfactual share the same uniforms (common random
numbers), so their difference has little simulation noise.

{pstd}
{bf:Bootstrap.} {opt reps()} re-estimates every DR system on moving-block
resamples of the regression rows. With J = 3, H = 4 and 99 thresholds, one
replication fits about 1,500 logits; {cmd:reps(199)} with {cmd:draws(5000)}
takes several minutes.

{pstd}
{bf:Replication code.} The MATLAB code (i) draws by the nearest-CDF rule, (ii)
estimates the "out-of-sample" models on the full sample, and (iii) maps a
uniform above F(y_99) to the {it:lowest} threshold in its counterfactual step.
{cmd:dvar} uses the generalised inverse of the rearranged CDF (Algorithm 1),
true expanding windows ({opt fullsample} reproduces (ii)), and maps such a
uniform to the highest threshold. See {help dvar_methods}.


{marker examples}{...}
{title:Examples}

{pstd}Setup (US data used by Wang, Oka and Zhu 2025){p_end}
{phang2}{cmd:. use dvar_us, clear}{p_end}
{phang2}{cmd:. tsset q}{p_end}

{pstd}DR system with 3 lags, coefficient processes and in-sample correlation{p_end}
{phang2}{cmd:. dvar fit nfci gdp rate, lags(3) insample seed(1)}{p_end}

{pstd}Joint distribution of NFCI and GDP after 2008q4 (multimodality){p_end}
{phang2}{cmd:. dvar joint nfci gdp rate, at(2008q4) horizons(1/4) bw(0.25 0.8) seed(1)}{p_end}

{pstd}Counterfactual monetary easing in 2008q4: rate ~ N(-1, 0.3^2){p_end}
{phang2}{cmd:. dvar irf nfci gdp rate, at(2008q4) shock(rate) cf(normal -1 0.3) lpend(2019q4) seed(1)}{p_end}

{pstd}Limit financial tightening in 2008q4 (paper, Sec. 4.4.1), with bootstrap bands{p_end}
{phang2}{cmd:. dvar irf nfci gdp, at(2008q4) shock(nfci) cf(tnormal 0 0.2 -1.5 2) reps(199) draws(5000) seed(1)}{p_end}

{pstd}Out-of-sample PITs and scores, one quarter ahead{p_end}
{phang2}{cmd:. dvar forecast nfci gdp, start(2000q1) horizon(1) seed(1)}{p_end}

{pstd}Adrian-Boyarchenko-Giannone kernel model, bandwidth by log score{p_end}
{phang2}{cmd:. dvar kernel nfci gdp, at(2008q4) cvgrid(0.3(0.1)0.9) seed(1)}{p_end}

{pstd}Colour maps{p_end}
{phang2}{cmd:. dvar palette parula, n(64)}{p_end}
{phang2}{cmd:. dvar joint nfci gdp, at(2008q4) colorscale(turbo) heatmap}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:dvar fit} stores in {cmd:e()}:{p_end}
{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}rows of the regression sample{p_end}
{synopt:{cmd:e(J)}}number of outcomes{p_end}
{synopt:{cmd:e(lags)}, {cmd:e(horizon)}, {cmd:e(grid)}}specification{p_end}
{synopt:{cmd:e(lambda)}, {cmd:e(alpha)}, {cmd:e(hac)}}penalty and HAC lags{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:dvar}{p_end}
{synopt:{cmd:e(depvars)}, {cmd:e(link)}, {cmd:e(taus)}, {cmd:e(timevar)}}{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(theta}{it:j}{cmd:)}}d_j x K coefficient process of equation j{p_end}
{synopt:{cmd:e(se}{it:j}{cmd:)}}its sandwich standard errors{p_end}
{synopt:{cmd:e(tab_b}{it:j}{cmd:)}, {cmd:e(tab_se}{it:j}{cmd:)}}the tabulated columns{p_end}
{synopt:{cmd:e(thresholds)}}K x J threshold grid{p_end}
{synopt:{cmd:e(fitstats)}}pseudo-R2, KS(PIT) and d_j by equation{p_end}
{synopt:{cmd:e(pit)}}in-sample Rosenblatt PITs{p_end}
{synopt:{cmd:e(insample)}}with {opt insample}: time, mean and 5 quantiles per variable, pairwise correlations{p_end}

{pstd}{cmd:dvar joint} stores {cmd:r(stats)} (one row per horizon) and
{cmd:r(density}{it:i}{cmd:)} (x, y, density grid).{p_end}

{pstd}{cmd:dvar irf} stores, for each variable {it:v}: {cmd:r(irf_}{it:v}{cmd:)}
(Base/Diff table), {cmd:r(dirf_}{it:v}{cmd:)} (threshold, then F*-F, lower and
upper band for each h), {cmd:r(dens_}{it:v}{cmd:)} and, with {opt reps()},
{cmd:r(lo_}{it:v}{cmd:)} and {cmd:r(hi_}{it:v}{cmd:)}.{p_end}

{pstd}{cmd:dvar forecast} stores {cmd:r(summary)} and {cmd:r(forecasts)};
{cmd:dvar kernel} stores {cmd:r(stats)}, {cmd:r(c)}, {cmd:r(cv)} and, with
{opt shock()}, {cmd:r(irf_}{it:v}{cmd:)}.{p_end}


{marker references}{...}
{title:References}

{phang}
Wang, Y., T. Oka, and D. Zhu. 2025. Distributional vector autoregression:
eliciting macro and financial dependence. {it:Journal of Applied Econometrics}.
Replication data: {browse "https://doi.org/10.15456/jae.2025344.0549161755"}.
Working paper: arXiv:2303.04994.

{phang}
Adrian, T., N. Boyarchenko, and D. Giannone. 2021. Multimodality in
macrofinancial dynamics. {it:International Economic Review} 62(2): 861-886.
{browse "https://doi.org/10.1111/iere.12501"}.

{phang}
Adrian, T., N. Boyarchenko, and D. Giannone. 2019. Vulnerable growth.
{it:American Economic Review} 109(4): 1263-1289.

{phang}
Chernozhukov, V., I. Fernandez-Val, and A. Galichon. 2009. Improving point and
interval estimators of monotone functions by rearrangement. {it:Biometrika}
96(3): 559-575.

{phang}
Chernozhukov, V., I. Fernandez-Val, and B. Melly. 2013. Inference on
counterfactual distributions. {it:Econometrica} 81(6): 2205-2268.

{phang}
Foresi, S., and F. Peracchi. 1995. The conditional distribution of excess
returns: an empirical analysis. {it:Journal of the American Statistical
Association} 90(430): 451-466.

{phang}
Jorda, O. 2005. Estimation and inference of impulse responses by local
projections. {it:American Economic Review} 95(1): 161-182.

{phang}
Kunsch, H. R. 1989. The jackknife and the bootstrap for general stationary
observations. {it:Annals of Statistics} 17(3): 1217-1241.

{phang}
Rossi, B., and T. Sekhposyan. 2019. Alternative tests for correct
specification of conditional predictive densities. {it:Journal of
Econometrics} 208(2): 638-657.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":https://github.com/merwanroudane}

{pstd}
Please cite Wang, Oka and Zhu (2025) and, for {cmd:dvar kernel}, Adrian,
Boyarchenko and Giannone (2021) when using this package.
{p_end}
