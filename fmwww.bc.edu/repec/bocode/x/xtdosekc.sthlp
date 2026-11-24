{smcl}
{* *! version 1.0.0  23nov2026}{...}
{vieweralsosee "xtdosekc methods" "help xtdosekc_methods"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{vieweralsosee "[TS] sspace" "help sspace"}{...}
{viewerjumpto "Syntax" "xtdosekc##syntax"}{...}
{viewerjumpto "Description" "xtdosekc##description"}{...}
{viewerjumpto "Models" "xtdosekc##models"}{...}
{viewerjumpto "Options" "xtdosekc##options"}{...}
{viewerjumpto "Subcommands" "xtdosekc##subcommands"}{...}
{viewerjumpto "Graphs" "xtdosekc##graphs"}{...}
{viewerjumpto "Interpreting the output" "xtdosekc##output"}{...}
{viewerjumpto "Remarks" "xtdosekc##remarks"}{...}
{viewerjumpto "Examples" "xtdosekc##examples"}{...}
{viewerjumpto "Stored results" "xtdosekc##results"}{...}
{viewerjumpto "References" "xtdosekc##references"}{...}
{viewerjumpto "Author" "xtdosekc##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:xtdosekc} {hline 2}}Dynamic nonlinear panel Environmental Kuznets Curve:
difference-of-sigmoids (DoS) curve with country stochastic trends{p_end}
{p2colreset}{...}

{pstd}
Implements Amoroso, Garcia-Martos and Koopman (2026), {it:A dynamic nonlinear panel
decomposition model for the global Environmental Kuznets Curve}, {it:The Econometrics
Journal}. The equation-by-equation derivation is in {help xtdosekc_methods:help xtdosekc methods}.


{marker syntax}{...}
{title:Syntax}

{pstd}Estimation

{p 8 17 2}
{cmd:xtdosekc} {it:depvar} {it:incomevar} {ifin} [{cmd:,} {it:options}]

{pstd}Replay

{p 8 17 2}
{cmd:xtdosekc} [{cmd:,} {opt nodiag}]

{pstd}Subcommands

{p 8 17 2}
{cmd:xtdosekc sens} {it:depvar} {it:incomevar} {ifin} [{cmd:,} {opt lsnrg:rid(numlist)} {opt lekcg:rid(numlist)} {it:estimation_options}]

{p 8 17 2}
{cmd:xtdosekc compare} {it:depvar} {it:incomevar} {ifin} [{cmd:,} {opt fef:rom(matname)} {opt trendf:rom(matname)} {opt sh:ift(varname)} {it:estimation_options}]

{p 8 17 2}
{cmd:xtdosekc integ} {varlist} {ifin} [{cmd:,} {opt l:ags(#)} {opt dl:ags(#)} {opt pl:ags(#)} {opt nopanel} {opt idl:abel(varname)}]

{p 8 17 2}
{cmd:xtdosekc illustrate} [{cmd:,} {opt c1(#)} {opt s1(#)} {opt c2(#)} {opt s2(#)} {opt gam:ma(#)} {opt range(# #)} {opt gname(name)} {opt gexp:ort(ext)}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(name)}}{opt dynamic} (default), {opt static}, {opt trend} or {opt country}; see {help xtdosekc##models:Models}{p_end}
{synopt:{opt sh:ift(varname)}}unit-level indicator; units with {it:varname}!=0 get their own green-transition location {it:c2} (the paper's "Regional" model){p_end}
{synopt:{opt init(numlist)}}dynamic starting values: gamma c1 c2 [shift] s1 s2 sigma_eps sigma_eta; default 3.7 1.1 4.5 [-0.5] 1 4.5 0.03 0.02 (the paper's){p_end}
{synopt:{opt clb(#)}}lower bound of c1 and c2; default min(x) of the estimation sample{p_end}
{synopt:{opt from(matname)}}static starting values: 1 x (N+5) for {opt static}, 1 x (2N+5) for {opt trend}, N x 6 for {opt country} (R parameterisation, see Remarks){p_end}

{syntab:Penalties, eq. (3.10)-(3.11)}
{synopt:{opt lsnr(#)}}weight lambda_snr of the signal-to-noise penalty; default {cmd:1e6}{p_end}
{synopt:{opt lekc(#)}}weight lambda_ekc of the amplitude penalty; default {cmd:1e6}{p_end}
{synopt:{opt snr:atio(#)}}ceiling on sigma_eta/sigma_eps in P_snr; default {cmd:0.5}{p_end}
{synopt:{opt gammap:en(#)}}floor on gamma in P_ekc; default {cmd:1}{p_end}

{syntab:Box constraints (L-BFGS-B)}
{synopt:{opt gammalb(#)}}lower bound of gamma; default {cmd:1}{p_end}
{synopt:{opt smin(#)} {opt smax(#)}}bounds of s1, s2; default {cmd:1e-3} and {cmd:5}{p_end}
{synopt:{opt shb:ound(#)}}bound |shift| <= #; default {cmd:2}{p_end}
{synopt:{opt lsmin(#)} {opt lsemax(#)} {opt lsnmax(#)}}bounds of ln sigma; defaults {cmd:-10}, {cmd:-0.7}, {cmd:-2.5}{p_end}

{syntab:Optimiser}
{synopt:{opt factr(#)}}L-BFGS-B relative-reduction tolerance factor; default {cmd:1e7} (R {cmd:optim}){p_end}
{synopt:{opt maxi:ter(#)}}maximum iterations; default 2000 (dynamic, country) or 10000 (static, trend){p_end}
{synopt:{opt ndeps(#)}}finite-difference step of the numerical gradient; default {cmd:1e-3} (R {cmd:optim}){p_end}
{synopt:{opt lmm(#)}}number of L-BFGS memory pairs; default {cmd:5}{p_end}
{synopt:{opt trace}}print the objective at every iteration{p_end}

{syntab:State-space bootstrap (Section 3.4)}
{synopt:{opt reps(#)}}number of kept bootstrap draws; default {cmd:0} (none); the paper uses {cmd:reps(500)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt gmax:boot(#)}}discard draws with gamma > #; default {cmd:15}{p_end}
{synopt:{opt shmin:boot(#)}}discard draws with shift < # (regional model); default {cmd:-1.5}{p_end}
{synopt:{opt maxt:ries(#)}}maximum number of attempted draws; default 10 x {opt reps()}{p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}
{synopt:{opt l:evel(#)}}level of the percentile intervals; default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt idl:abel(varname)}}string (or labelled) variable used to label units (e.g. ISO3 codes){p_end}
{synopt:{opt gr:oup(varname)}}unit-level 0/1 variable for line patterns and marker shapes (e.g. advanced vs emerging){p_end}
{synopt:{opt exp:scale(#)}}also report exp(x*) x #, the turning point in levels (e.g. 1000 when x = ln(GDP/1000)){p_end}
{synopt:{opt dfm(#)}}number of dynamic factors extracted from the trends; default {cmd:2}{p_end}
{synopt:{opt nodiag}}suppress the residual-diagnostics table (Table 3){p_end}
{synopt:{opt notab:le}}suppress all output tables{p_end}
{synopt:{opt gen:erate(stub)}}save components {it:stub}{cmd:_mu}, {cmd:_curve}, {cmd:_tau}, {cmd:_taulo}, {cmd:_tauhi}, {cmd:_fit}, {cmd:_sfit}, {cmd:_res}, {cmd:_struct}{p_end}
{synopt:{opt replace}}overwrite existing {opt generate()} variables{p_end}
{synopt:{opt tex(filename)}}write the main table and the diagnostics table in the paper's LaTeX layout{p_end}

{syntab:Graphs}
{synopt:{opt gr:aph(list)}}any of {opt data fit curve trends decomp diag dfm boot}, or {opt all}{p_end}
{synopt:{opt gname(stub)}}graph names {it:stub}{cmd:_}{it:type}; default {cmd:xtdosekc}{p_end}
{synopt:{opt gexp:ort(ext)}}export every graph as {it:stub}{cmd:_}{it:type}.{it:ext} (png, pdf, eps, svg){p_end}
{synopt:{opt col:ors(list)}}quoted list of colours cycled over units; default reproduces the paper's palette{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb xtset} and form a balanced panel without gaps.{p_end}


{marker description}{...}
{title:Description}

{pstd}
The Environmental Kuznets Curve (EKC) relates pollution {it:y} (here log CO2 per
capita) to income {it:x} (log GDP per capita). Instead of a quadratic in {it:x},
{cmd:xtdosekc} uses a bounded {bf:difference-of-sigmoids (DoS)}:

{p 8 8 2}
y_it = mu_i + tau_it + gamma [ sigma(x_it; c1, s1) - sigma(x_it; c2, s2) ] + eps_it,{break}
sigma(x; c, s) = 1 / (1 + exp(-s (x - c))),

{pstd}
where the first logistic is the {it:economic-growth} effect (activated at income
c1), the second the {it:green-transition} effect (activated at c2 > c1), and
tau_it is a country random walk ({it:stochastic trend}) that absorbs energy-mix,
technology and policy shifts. Because the DoS is bounded it is immune to the
"powers of integrated regressors" problem of Wagner (2015), and the stochastic
trends remove the spurious-regression residuals of static EKC panels.

{pstd}
Estimation follows the paper exactly: the fixed effects are concentrated out by
sample means, the trends are handled by an exact-diffuse Kalman filter, and the
penalised profile likelihood is maximised with {bf:L-BFGS-B} (a Mata port of the
algorithm used by R's {cmd:optim}, including its finite-difference gradient), so
that results match the authors' replication code. Standard errors, intervals and
contrasts come from the Stoffer-Wall state-space bootstrap. The command also
produces every table and figure of the paper and its Online Appendix.


{marker models}{...}
{title:Models}

{phang}
{opt model(dynamic)} {hline 2} the paper's model (Section 4.4, Table 2): DoS +
fixed effects + stochastic trends. Add {opt shift(varname)} for the {it:Regional}
model with a separate c2 for one group (Europe in the paper). Restrict the sample
with {cmd:if} for the split-sample E7 / G7 columns.

{phang}
{opt model(static)} {hline 2} pooled DoS with fixed effects by nonlinear least
squares (Section 4.3, Figures 4-5).

{phang}
{opt model(trend)} {hline 2} static model with country linear trends mu_i + delta_i t
(Online Appendix S2.1).

{phang}
{opt model(country)} {hline 2} single-equation DoS fitted country by country
(Section 4.2, Table 1, Figure 3).


{marker options}{...}
{title:Options}

{phang}
{opt shift(varname)} must be constant within each unit and select some, but not
all, units. The shifted location is c2(shift) = c2 + delta with |delta| <= {opt shbound()};
the table reports c2(shift), the contrast c2 - c2(shift) and both turning points.

{phang}
{opt reps(#)} runs the Stoffer and Wall (1991) bootstrap of Section 3.4: the
one-step-ahead prediction errors are whitened by the inverse symmetric square root
of their N x N covariance, resampled element-wise, recoloured, pushed through the
innovations form of the filter, the DoS curve and fixed effects are added back,
and the model is re-estimated with identical settings. Draws that fail to converge
or are degenerate ({opt gmaxboot()}, {opt shminboot()}) are discarded and replaced,
exactly as in the replication code. It requires N < T - 1.

{phang}
{opt lsnr()}, {opt lekc()} set the penalties of eq. (3.11). With the default box
gamma >= 1 the amplitude penalty is inactive; the signal-to-noise penalty binds in
the paper's data. Use {cmd:xtdosekc sens} for the Online-Appendix sensitivity grid.


{marker subcommands}{...}
{title:Subcommands}

{phang}
{cmd:xtdosekc sens} re-estimates the dynamic model over a grid of penalty weights:
Table S1 varies lambda_snr (default grid 0 1e2 1e4 1e6 1e8 1e10) at lambda_ekc =
{opt lekc()}, Table S2 varies lambda_ekc (default 0 1e3 1e6) at lambda_snr = {opt lsnr()}.
It reports gamma, c1, c2, c2(shift), ln sigma^2, the q-ratio and the unpenalised
and penalised log-likelihoods. Returns {cmd:r(snr)} and {cmd:r(ekc)}.

{phang}
{cmd:xtdosekc compare} fits the three treatments of the country baseline (fixed
effects, + linear trends, + stochastic trends) and reports Tables S3-S5: DoS
parameters and log-likelihoods, the LR test of the linear trends, RMSE, mean
ACF(1), ADF rejections, Ljung-Box non-rejections and the trend slopes.

{phang}
{cmd:xtdosekc integ} reports Tables S6-S7: per-unit ADF tests in levels (constant +
trend) and differences (constant), an Engle-Granger residual test when two variables
are given (first on second, MacKinnon 2010 5% critical value), and panel Pesaran (2004)
CD, Levin-Lin-Chu and Im-Pesaran-Shin tests.

{phang}
{cmd:xtdosekc illustrate} draws Figure 1 (sigma1, sigma2 and the DoS with its
turning point) and returns {cmd:r(xstar)}; the defaults reproduce x* = 6.01.


{marker graphs}{...}
{title:Graphs}

{p2colset 8 20 22 2}{...}
{p2col:{opt data}}Figure 2: y and x over time by unit{p_end}
{p2col:{opt fit}}Figures 3-4: observations and fitted mu_i + DoS(x) by unit{p_end}
{p2col:{opt curve}}Figures 6-7: structural points y - mu_i - tau_it, DoS curve(s) and turning point(s){p_end}
{p2col:{opt trends}}Figure 8: smoothed tau_it with pointwise {opt level()} bands{p_end}
{p2col:{opt diag}}Figure 5: ACF(1), Ljung-Box, ADF and Shapiro-Wilk by unit{p_end}
{p2col:{opt dfm}}Figure 9: loadings of the dynamic factors of the trends (bar chart){p_end}
{p2col:{opt decomp}}new: observed y, mu_i + DoS and mu_i + DoS + tau_it over time{p_end}
{p2col:{opt boot}}new: bootstrap distributions of the key parameters and contrasts{p_end}
{p2colreset}{...}


{marker output}{...}
{title:Interpreting the output}

{phang}{bf:gamma} {hline 2} amplitude of the EKC (log points of emissions between the
two plateaus).{p_end}
{phang}{bf:c1, s1} {hline 2} income at which emissions start rising, and how fast.{p_end}
{phang}{bf:c2, s2} {hline 2} income at which the green transition starts, and how fast.
c2(shift) is the same for the {opt shift()} group.{p_end}
{phang}{bf:sigma_eps, sigma_eta, q} {hline 2} observation noise, trend noise and their
ratio; q is held below {opt snratio()} by the penalty so that the trend cannot absorb
the EKC.{p_end}
{phang}{bf:c2 - c1} {hline 2} the "grow first, clean later" gap; a positive gap with a
small bootstrap p supports an EKC.{p_end}
{phang}{bf:x*} {hline 2} income at which emissions peak; "--" means the maximum is at the
edge of the observed income range (no interior turning point, as for the E7 panel).
{opt expscale()} converts it to levels.{p_end}
{phang}{bf:Boot. p} {hline 2} two-sided bootstrap p-value of a contrast against zero
("<" when every draw has the same sign).{p_end}
{phang}{bf:Log-likelihood} {hline 2} the penalised value is the one reported in the
paper; the unpenalised value and the penalty are also shown.{p_end}
{phang}{bf:Diagnostics table} {hline 2} mu_i and residual tests by unit (Table 3). The
ADF p-value follows R's {cmd:tseries::adf.test(k = 1)} and is bounded in [0.01, 0.10];
** marks rejection of a unit root at 5%.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Compatibility with the replication code.} The likelihood is the exact-diffuse
one computed by R's KFAS (first observation of each country is the diffuse step), and
the optimiser is a line-by-line port of L-BFGS-B as called by R's {cmd:optim}. On the
paper's data the Global model reproduces the published estimates to 1e-11 and the
penalised log-likelihood 984.83. The Regional model needs about 80 iterations on a
flat surface, so rounding differences of order 1e-13 accumulate; results agree with
Table 2 and Table 3 to the reported decimals (gamma within 0.002). The bootstrap uses
Stata's random-number generator, so SEs differ from the paper by Monte Carlo error only.

{pstd}
{bf:Split samples.} The replication code fits the E7 and G7 panels with the full-sample
min(x) as lower bound of c1 and c2 and without an iteration control, i.e. R's default
of 100 iterations; the E7 fit stops at that limit. {opt clb()} and {opt maxiter(100)}
reproduce Table 2 (E7: gamma 9.11, LL 459.41; G7: gamma 6.09, LL 516.43). Running to
convergence gives higher likelihoods on these weakly identified subsamples, which is the
paper's reason for not reporting their standard errors.

{pstd}
{bf:Identification.} Single-country (Table 1) and static pooled fits are weakly
identified: the SSR surface is a flat ridge and different, equally valid optimisers
stop at different points (R itself moves from c1 = 2.75 to 2.56 under a 1e-12
perturbation of the start). This is the paper's motivation for pooling and for the
dynamic model. Use {opt from()} with the authors' starting values to reproduce Table 1
(see {cmd:xtdosekc_example.do}).

{pstd}
{bf:Parameterisation of from().} Static models use R's parameterisation
c2 = c1 + c2gap + 0.001 with c2gap >= 1e-6. For {opt country} the matrix has one row
per unit: mu gamma c1 c2gap s1 s2. For {opt static}: mu_1..mu_N gamma c1 c2gap s1 s2.
For {opt trend}: mu_1..mu_N delta_1..delta_N gamma c1 c2gap s1 s2.

{pstd}
{bf:Bootstrap of the variances.} In re-estimation the signal-to-noise penalty binds,
so the bootstrap distribution of sigma_eta and q is shifted below the estimate (the
same happens in the authors' draws). Following the paper, inference should be based on
the DoS parameters, the contrasts and the turning points.

{pstd}
{bf:Sample size.} Use T >= 10 per unit; the bootstrap needs N < T - 1. All units must
share the same consecutive periods.


{marker examples}{...}
{title:Examples}

{pstd}Setup (the paper's data are shipped as an ancillary file; {cmd:net get xtdosekc}){p_end}
{phang2}{cmd:. use xtdosekc_g20, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Global dynamic model (Table 2, column Global){p_end}
{phang2}{cmd:. xtdosekc ln_co2 ln_gdp, idlabel(country) expscale(1000)}{p_end}

{pstd}Regional model with bootstrap SEs, all figures and LaTeX tables (Tables 2-3, Figures 7-9){p_end}
{phang2}{cmd:. xtdosekc ln_co2 ln_gdp, shift(europe) reps(500) seed(20260226) idlabel(iso3) group(advanced) graph(all) tex(table2.tex)}{p_end}

{pstd}Split samples (Table 2, columns E7 and G7, with the replication code's settings: full-sample bound on c1, c2 and R's default 100 iterations){p_end}
{phang2}{cmd:. xtdosekc ln_co2 ln_gdp if advanced == 0, clb(0.3898978) maxiter(100) idlabel(country) nodiag}{p_end}
{phang2}{cmd:. xtdosekc ln_co2 ln_gdp if advanced == 1, clb(0.3898978) maxiter(100) idlabel(country) nodiag}{p_end}

{pstd}Static models (Section 4.3, Figures 4-5){p_end}
{phang2}{cmd:. xtdosekc ln_co2 ln_gdp, model(static) idlabel(iso3) group(advanced) graph(fit curve diag)}{p_end}

{pstd}Online Appendix{p_end}
{phang2}{cmd:. xtdosekc sens ln_co2 ln_gdp, shift(europe)}{p_end}
{phang2}{cmd:. xtdosekc compare ln_co2 ln_gdp, idlabel(iso3)}{p_end}
{phang2}{cmd:. xtdosekc integ ln_co2 ln_gdp, idlabel(iso3)}{p_end}
{phang2}{cmd:. xtdosekc illustrate}{p_end}

{pstd}The full replication of the paper is in {cmd:xtdosekc_example.do}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtdosekc} stores the following in {cmd:e()} (dynamic model; static models store the subset that applies):

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(N_g)}, {cmd:e(T)}}observations, units, periods{p_end}
{synopt:{cmd:e(ll)}}penalised log-likelihood (static: Gaussian log-likelihood){p_end}
{synopt:{cmd:e(ll_unpen)}, {cmd:e(penalty)}}unpenalised log-likelihood and penalty{p_end}
{synopt:{cmd:e(ssr)}}residual sum of squares{p_end}
{synopt:{cmd:e(converged)}, {cmd:e(fail)}, {cmd:e(iterations)}, {cmd:e(nfg)}}optimiser status (fail: 0 ok, 1 maxiter, 52 abnormal){p_end}
{synopt:{cmd:e(reps)}, {cmd:e(kept)}, {cmd:e(ndisc)}, {cmd:e(discard_rate)}}bootstrap counts{p_end}
{synopt:{cmd:e(xmin)}, {cmd:e(xmax)}}income range used for the turning point{p_end}
{synopt:{cmd:e(lsnr)}, {cmd:e(lekc)}, {cmd:e(snratio)}, {cmd:e(gammapen)}, {cmd:e(level)}}settings{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}, {cmd:e(cmdline)}, {cmd:e(model)}, {cmd:e(depvar)}, {cmd:e(indepvar)}, {cmd:e(shift)}, {cmd:e(ivar)}, {cmd:e(tvar)}, {cmd:e(units)}, {cmd:e(optimizer)}}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}natural parameters and bootstrap covariance{p_end}
{synopt:{cmd:e(table)}}rows: parameters, q-ratio, contrasts, turning points, interior flags; columns: est se lo hi pr_le0{p_end}
{synopt:{cmd:e(mu)}, {cmd:e(tau)}, {cmd:e(vtau)}}fixed effects, smoothed trends (T x N) and their variances{p_end}
{synopt:{cmd:e(diag)}}per unit: mu_i, ACF(1), Ljung-Box Q and p, ADF stat and p, Shapiro-Wilk W and p{p_end}
{synopt:{cmd:e(draws)}, {cmd:e(boot)}}raw bootstrap draws and the derived quantities per draw{p_end}
{synopt:{cmd:e(loadings)}, {cmd:e(factors)}, {cmd:e(eigen)}}dynamic factor model of the trends{p_end}
{synopt:{cmd:e(raw)}, {cmd:e(grid)}}optimiser vector and the curve on a 300-point income grid{p_end}
{synopt:{cmd:e(country)}, {cmd:e(delta)}}country-model estimates; trend slopes ({opt model(trend)}){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}Amoroso, C., C. Garcia-Martos and S. J. Koopman. 2026. A dynamic nonlinear panel
decomposition model for the global Environmental Kuznets Curve. {it:The Econometrics Journal}, utag037.
{browse "https://doi.org/10.1093/ectj/utag037":doi:10.1093/ectj/utag037}.{p_end}
{phang}Byrd, R. H., P. Lu, J. Nocedal and C. Zhu. 1995. A limited memory algorithm for bound
constrained optimization. {it:SIAM Journal on Scientific Computing} 16: 1190-1208.{p_end}
{phang}Durbin, J. and S. J. Koopman. 2012. {it:Time Series Analysis by State Space Methods}. 2nd ed. Oxford University Press.{p_end}
{phang}Pena, D. and G. E. P. Box. 1987. Identifying a simplifying structure in time series.
{it:Journal of the American Statistical Association} 82: 836-843.{p_end}
{phang}Stoffer, D. S. and K. D. Wall. 1991. Bootstrapping state-space models: Gaussian maximum
likelihood estimation and the Kalman filter. {it:Journal of the American Statistical Association} 86: 1024-1033.{p_end}
{phang}Wagner, M. 2015. The Environmental Kuznets Curve, cointegration and nonlinearity.
{it:Journal of Applied Econometrics} 30: 948-967.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Please cite the original article when using this command.{p_end}
