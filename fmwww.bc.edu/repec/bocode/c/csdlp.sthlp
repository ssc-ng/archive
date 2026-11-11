{smcl}
{* *! version 1.0.0  09nov2026}{...}
{vieweralsosee "csdlp methods" "help csdlp_methods"}{...}
{vieweralsosee "csdlp postestimation" "help csdlp_postestimation"}{...}
{vieweralsosee "csdlp_graph" "help csdlp_graph"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "csdlp##syntax"}{...}
{viewerjumpto "Description" "csdlp##description"}{...}
{viewerjumpto "Options" "csdlp##options"}{...}
{viewerjumpto "Interpreting the output" "csdlp##output"}{...}
{viewerjumpto "Remarks" "csdlp##remarks"}{...}
{viewerjumpto "Examples" "csdlp##examples"}{...}
{viewerjumpto "Stored results" "csdlp##results"}{...}
{viewerjumpto "References" "csdlp##references"}{...}
{viewerjumpto "Author" "csdlp##author"}{...}
{title:Title}

{phang}
{bf:csdlp} {hline 2} Causal state-dependent local projections: sieve
estimation with pointwise and state-uniform inference for micro-macro panels
and time series


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:csdlp} {depvar} {ifin}{cmd:,}
{opt sh:ock(varname)} {opt st:ate(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model (eq. 3 and 27 of the paper)}
{p2coldent:* {opt sh:ock(varname)}}aggregate shock {it:X_t}; time-series operators allowed{p_end}
{p2coldent:* {opt st:ate(varname)}}predetermined state {it:Z_{c -(}i,t-1{c )-}}, e.g. {cmd:state(L.d2d)}{p_end}
{synopt:{opth h:orizons(numlist)}}LP horizons, e.g. {cmd:horizons(0/12)}; default {cmd:0}{p_end}
{synopt:{opth cont:rols(varlist)}}predetermined controls {it:W_{c -(}i,t-1{c )-}}; ts- and factor-variable operators allowed{p_end}
{synopt:{opt ab:sorb(list)}}fixed effects to absorb; each element a variable or an interaction {cmd:a#b} (e.g. {cmd:absorb(sector#t firm)}){p_end}
{synopt:{opt cum:ulative}}outcome {it:y_{c -(}t+h{c )-} - y_{c -(}t-1{c )-}} (cumulative response, as in Ottonello-Winberry){p_end}
{synopt:{opt nocons:tant}}omit the constant from {it:W} (exactly eq. 3 / the paper's simulations){p_end}
{synopt:{opt inter:mediate}}add intermediate shocks {it:X_{c -(}t+j{c )-}*phi(Z)}, j=1..h, as controls (Table 3){p_end}
{synopt:{opt norm:alize(auto|on|off)}}normalise {it:g_h} to zero sample mean when FE absorb {it:X_t}; default {cmd:auto}{p_end}

{syntab:Sieve (Algorithm 1)}
{synopt:{opt sel:ect(aic|bic|gcv|lasso)}}sieve-dimension selector; default {cmd:aic} (eq. 10-11){p_end}
{synopt:{opt nb:asis(#)}}fix the number of B-spline functions {it:J} (oracle; overrides {cmd:select()}){p_end}
{synopt:{opt jmin(#)}, {opt jmax(#)}}candidate set {it:J} = {jmin,...,jmax}; default 4 and 20{p_end}
{synopt:{opt jlas:so(#)}}maximal dimension for {cmd:select(lasso)}; default 50{p_end}

{syntab:Inference (eq. 13-21)}
{synopt:{opt vce(vcetype)}}{cmd:nw} (default; Newey-West, L=floor(4((T-h)/100)^(2/9))), {cmd:nw} {it:#}, {cmd:hlag} (L=h), or {cmd:cluster} (by time){p_end}
{synopt:{opt l:evel(#)}}outer band / CI level; default {cmd:95}{p_end}
{synopt:{opt level2(#)}}inner uniform band level; default {cmd:68}; {cmd:0} suppresses{p_end}
{synopt:{opt reps(#)}}Gaussian draws for the sup-t critical value; default {cmd:2000}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Grid, reporting and graphs}
{synopt:{opt grid(#)}}number of grid points for {it:z}; default 200{p_end}
{synopt:{opt range(# #)}}grid between these percentiles of the state; default {cmd:5 95}{p_end}
{synopt:{opt zrange(# #)}}grid between these values of the state (overrides {cmd:range()}){p_end}
{synopt:{opt sc:ale(#)}}report responses to a shock of size delta (e.g. {cmd:scale(-0.25)} for a 25bp cut){p_end}
{synopt:{opth qu:antiles(numlist)}}state percentiles in Table 2; default {cmd:5 25 50 75 95}{p_end}
{synopt:{opt notab:le}}suppress the tables{p_end}
{synopt:{opt nogr:aph}}suppress the IRF graph{p_end}
{synopt:{opth gh:orizons(numlist)}}horizons shown in the graph{p_end}
{synopt:{opt nolin:ear}}do not overlay the linear-interaction LP in the graph{p_end}
{synopt:{opt name(string)}}graph name stub; default {cmd:csdlp}{p_end}
{synopt:{opt sav:ing(filename)}}export the graph as {it:filename}{cmd:.png}{p_end}
{synoptline}
{p 4 6 2}* required. The data must be {helpb xtset} (panel) or {helpb tsset} (one time series).{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:csdlp} implements the causal state-dependent local projections of
{help csdlp##DGJW2026:David, Giacomini, Jiao and Wang (2026)}. For each horizon h
it estimates

{p 8 8 2}
{it:Y_{c -(}i,t+h{c )-} = g_h(Z_{c -(}i,t-1{c )-}) X_t + W'_{c -(}i,t-1{c )-} gamma_h + u_{c -(}i,t+h{c )-}}

{pstd}
where {it:g_h(.)} is an unknown function of a predetermined micro state. Under
causal shock exogeneity (Assumption 1), a predetermined state (Assumption 2)
and the conditional-mean condition that the outcome is linear in the shock
with a state-dependent coefficient (Assumption 3), {it:g_h(z)} {bf:is} the
total causal impulse response per unit shock for units with state {it:z}. The
state may be endogenous (it may depend on past shocks).

{pstd}
The paper shows that the standard linear-interaction LP,
{it:(alpha_h + beta_h Z) X_t}, does not recover {it:g_h} unless {it:g_h} is
exactly linear: {it:beta_h} is a weighted average of the local {bf:slopes}
{it:g_h'(z)}, not of response levels (Proposition 2, Lemma 1). {cmd:csdlp}
therefore estimates {it:g_h} nonparametrically with a cubic B-spline sieve,
selects the sieve dimension by AIC (or BIC, GCV, LASSO), and reports:

{p 8 12 2}1. the sieve IRF {it:g_h(z)} with pointwise confidence intervals (eq. 18);{p_end}
{p 8 12 2}2. {bf:studentized} state-uniform confidence bands (eq. 19-21), valid when
the convergence rate differs across the state space (root-NT where
idiosyncratic noise dominates, root-T where aggregate noise survives
cross-sectional averaging);{p_end}
{p 8 12 2}3. the linear-interaction benchmark (eq. 2b), its Lemma 1 decomposition, and
the weights {it:omega_h(z)};{p_end}
{p 8 12 2}4. auxiliary tests of linearity and of state dependence.{p_end}

{pstd}
Inference uses HAC on the cross-sectionally aggregated score
{it:s_t = N^(-1/2) sum_i P~_{c -(}i,t{c )-} u_{c -(}i,t+h{c )-}} (eq. 14-16), which is robust to the
strong common dependence created by the aggregate shock and to the MA(h)
dependence of overlapping LP horizons. With N=1 it reduces to a time-series
sieve LP.

{pstd}
Postestimation: {helpb csdlp_postestimation:csdlp_diff} (differential responses
across states, paper Fig. 4), {helpb csdlp_postestimation:csdlp_agg}
(capital-weighted aggregate responsiveness, Fig. 5) and {helpb csdlp_graph}
(IRF panels, Lemma 1 diagnostic, response surface). The derivation and the
step-to-equation map are in {help csdlp_methods}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt shock(varname)} is the aggregate shock {it:X_t}. It should be (close to)
a martingale difference with respect to the pre-shock information set
(Assumption 1(ii)). If you residualise the shock or use the fitted value of a
first stage, pass that series. The paper's theory treats the shock as observed
and does not account for first-stage uncertainty. A note is printed if the
variable varies across units within a period.

{phang}
{opt state(varname)} is the state {it:Z_{c -(}i,t-1{c )-}}. Pass it with the lag
operator, for example {cmd:state(L.d2d)}, so that it is predetermined. Any
predetermined state gives a well-defined subpopulation causal response
(Proposition 1), even if it is not the "true" state.

{phang}
{opt horizons(numlist)} lists the horizons; each horizon is a separate
regression on its own sample (the last h periods are lost).

{phang}
{opt controls(varlist)} are the controls {it:W}. They may be included for
efficiency without affecting identification. Typical: lagged outcomes
({cmd:L.y}), the state itself, firm characteristics, {cmd:i.fquarter}.

{phang}
{opt absorb(list)} absorbs fixed effects by an exact within transformation
(alternating projections for several dimensions). {cmd:absorb(sector#t)}
reproduces the sector-time(-horizon) effects of the paper's application. When
the FE absorb {it:X_t} itself (any FE nested in time), the constant component
of {it:g_h} is not identified. {cmd:csdlp} then normalises both the sieve and
the linear function to zero sample mean over the estimation sample (see
{opt normalize()}), and the response is a {it:differential} response relative
to the common component.

{phang}
{opt cumulative} uses {it:y_{c -(}t+h{c )-} - y_{c -(}t-1{c )-}}, as in equation (27). For a
log capital stock this is cumulative net investment.

{phang}
{opt noconstant} drops the intercept that {cmd:csdlp} otherwise adds to {it:W}
when no FE are absorbed. Equation (3) and the paper's Monte Carlo design have no
intercept. Because E[X_t]=0, the intercept never affects identification.

{phang}
{opt intermediate} adds {it:X_{c -(}t+j{c )-} phi_J(Z_{c -(}i,t-1{c )-})}, j=1..h, as controls. This does
not change identification, but it removes the common component of the LP error
driven by future aggregate shocks, which makes larger N much more effective
(Table 3: bands at h=4 shrink by an order of magnitude). It raises the
dimension to J(h+1), so use it with moderate h and J.

{dlgtab:Sieve}

{phang}
{opt select()} chooses J. {cmd:aic} (default, eq. 10) uses
{it:N(T-h) log(SSR/N(T-h)) + 2 K_J}, {cmd:bic} uses the {it:log(n)} penalty,
and {cmd:gcv} minimises {it:(SSR/n)/(1-K_J/n)^2}. {cmd:lasso} fits a
cross-validated lasso with J_max={opt jlasso()} B-spline interactions,
leaving W unpenalised, and sets J to the number of non-zero sieve terms
(at least 4); it requires Stata 16. J=4 is a global cubic polynomial;
each extra function adds an interior knot at an empirical quantile.

{phang}
{opt nbasis(#)} fixes J ("oracle" in the paper's tables). Data-driven selection
costs some finite-sample coverage relative to the oracle (Tables 3-4).

{dlgtab:Inference}

{phang}
{opt vce(nw)} (default) is the paper's HAC estimator with Bartlett weights
and {it:L_h} = floor(4((T-h)/100)^(2/9)), where T-h is the number of time
periods in the horizon-h sample. {cmd:vce(nw} {it:#}{cmd:)} fixes L.
{cmd:vce(hlag)} uses L=h, the paper's robustness check (footnote 8).
{cmd:vce(cluster)} sets L=0, i.e. clustering by time period, the recipe of
{help csdlp##AS2026:Almuzara and Sancibrian (2026)}. That recipe is valid when
lags of the outcome and the shock are controlled for.

{phang}
{opt level(#)} and {opt level2(#)} set the outer and inner bands. The paper's
application uses 90 and 68; its simulations use 95.

{phang}
{opt reps(#)} is the number B of Gaussian draws {it:xi ~ N(0, I_J)} used to
simulate the studentized supremum (eq. 19-20). The paper uses B=2000.

{dlgtab:Grid and reporting}

{phang}
{opt range(p1 p2)} places the {opt grid()} points between the p1-th and p2-th
percentiles of the state. The paper evaluates coverage over the 5th-95th
percentiles; uniform inference is harder in sparse boundary regions (its
footnote 10). {opt zrange(a b)} uses state values instead. Grid points outside
a horizon's support are set to missing.

{phang}
{opt scale(#)} multiplies all responses and standard errors by delta, so that
{it:IRF_h(z;delta) = g_h(z) delta}. For a shock measured in percentage points,
{cmd:scale(-0.25)} reports the response to a 25 basis-point cut.


{marker output}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.} Observations and units in the h=0 sample, number of time periods,
the sieve and selector, the VCE, the number of Gaussian draws, and notes on
normalisation or intermediate shocks.

{pstd}
{bf:Table 1} (one row per horizon):

{p2colset 8 26 28 2}{...}
{p2col:{it:Obs}}observations in the horizon-h regression{p_end}
{p2col:{it:J}}selected number of B-spline functions{p_end}
{p2col:{it:Lags}}HAC truncation lag L_h{p_end}
{p2col:{it:Linear SD-LP slope}}beta_h of the standard LP (2b) with its HAC s.e.
and stars. This is the number the applied literature reports.{p_end}
{p2col:{it:Proj. (Lem. 1)}}sample analogue of Lemma 1,
E[X^2(Z-mu)g(Z)]/E[X^2(Z-mu)^2], computed from the sieve fit. When it is close
to the slope, the linear coefficient is the omega-weighted average of the
{it:slopes} g_h'(z) (Prop. 2), not a statement about response levels.{p_end}
{p2col:{it:Linearity chi2, p}}HAC-Wald test of H0: g_h is linear in z. In
B-spline coordinates a function is linear iff its coefficients lie in the span
of (1, Greville abscissae); df = J-2.{p_end}
{p2col:{it:No-SD p}}HAC-Wald test of H0: g_h is constant in z (no state
dependence); df = J-1.{p_end}
{p2col:{it:sup-t c}}studentized uniform critical value c_{h,1-alpha} (eq. 20);
compare with 1.96 for the pointwise interval.{p_end}
{p2col:{it:sup-t p(g=0)}}p-value of the sup-t test of H0: g_h(z)=0 for all grid
z (the uniform band inverted). After normalisation it tests "no differential
response".{p_end}

{pstd}
The two Wald tests are {bf:auxiliary}: they are computed conditional on the
selected J and are not covered by the paper's theory. Read them as diagnostics.

{pstd}
{bf:Table 2} evaluates the sieve IRF and the linear IRF at the state percentiles
in {opt quantiles()}, with pointwise standard errors. Typical pattern: the two
agree near the centre of the distribution and diverge in the tails, or have
opposite signs where g_h is hump-shaped (the paper's Fig. 3).

{pstd}
{bf:Graph.} One panel per horizon: the sieve IRF (solid) with the
{opt level()}% and {opt level2()}% studentized uniform bands, and the
linear-interaction IRF (dashed). The bands widen where the state-specific
standard error is large. Because they are uniform, they can be used to judge
shape (monotone vs. hump-shaped) over the whole support.


{marker remarks}{...}
{title:Remarks / practical guidance}

{pstd}
{bf:When is g_h causal?} Figure 1 of the paper: (i) the shock is causally
exogenous; (ii) the DGP is linear in the shock; (iii) propagation is stable
(the shock does not change persistence). Micro-macro environments with
heterogeneous exposure and time-invariant propagation, including
first-order perturbation solutions of HA/HANK models and panel VARs with
state-dependent loadings, satisfy (ii)-(iii). Regime switching, ZLB,
sign asymmetries, and shocks that alter persistence violate them (the GHKP
critique). Then neither linear nor sieve state-dependent LPs recover the
finite-shock IRF.

{pstd}
{bf:Sample size.} N and T play different roles: cross-sectional averaging
removes idiosyncratic noise, but aggregate components of the LP error shrink
only with T. Expect undercoverage of uniform bands for short panels (T=40:
coverage about 0.73 at nominal 0.95), improving with T (T=200: about 0.88).

{pstd}
{bf:Choice of J.} AIC and GCV behave almost identically; LASSO yields wider,
slightly more conservative bands. Inspect {cmd:e(ic_h}{it:#}{cmd:)} for the
whole criterion profile.

{pstd}
{bf:Multivariate states} (Remark 3) require tensor-product bases and are not
implemented. Use a low-dimensional summary of the state.

{pstd}
{bf:Speed.} Each horizon fits jmax-jmin+1 regressions for the AIC search plus
the final fit. For very large panels, narrow {opt jmax()} or use
{opt nbasis()}.


{marker examples}{...}
{title:Examples}

{pstd}Real data shipped with the package: 50 US states, monthly activity and
Jarocinski-Karadi monetary policy shocks ({cmd:net get csdlp} copies
{cmd:csdlp_states.dta}, {cmd:csdlp_realdata.do} and the build script
{cmd:csdlp_states_build.do} to the working directory){p_end}
{phang2}{cmd:. net get csdlp}{p_end}
{phang2}{cmd:. use csdlp_states, clear}{p_end}
{phang2}{cmd:. notes}{p_end}
{phang2}{cmd:. csdlp y if pre, shock(mp_median) state(L.zw) horizons(0/24) cumulative absorb(mdate sid) controls(L.dy L2.dy L3.dy L.zw) scale(0.25) level(90) level2(68) seed(1)}{p_end}
{phang2}{cmd:. csdlp_diff, at(50 5) level(90)}{p_end}
{phang2}{cmd:. csdlp_graph, lemma horizons(12)}{p_end}

{pstd}Paper's Monte Carlo design (see {cmd:csdlp_example.do}){p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. csdlp y, shock(x) state(L.z) controls(L.y) horizons(0 4 8 12) noconstant seed(1)}{p_end}

{pstd}Ottonello-Winberry-type firm panel: cumulative investment, sector-time FE, 25bp cut, 90/68 bands{p_end}
{phang2}{cmd:. egen st = group(sector t)}{p_end}
{phang2}{cmd:. csdlp lnk, shock(mp) state(L.d2d) horizons(0/12) cumulative absorb(st) controls(L.d2d L.D.lnk L.size L.salesg L.liq i.fq c.L.d2d#c.L.gdpg) scale(-0.25) level(90) level2(68) seed(42)}{p_end}

{pstd}Differential responses and aggregate responsiveness{p_end}
{phang2}{cmd:. csdlp_diff, at(50 5)}{p_end}
{phang2}{cmd:. csdlp_diff, at(95 50)}{p_end}
{phang2}{cmd:. csdlp_agg L.capital, horizon(0)}{p_end}

{pstd}Graphs{p_end}
{phang2}{cmd:. csdlp_graph, horizons(0 4 8 12)}{p_end}
{phang2}{cmd:. csdlp_graph, lemma}{p_end}
{phang2}{cmd:. csdlp_graph, surface}{p_end}

{pstd}Alternative selectors and VCEs{p_end}
{phang2}{cmd:. csdlp y, shock(x) state(L.z) controls(L.y) horizons(0/8) select(gcv) vce(hlag)}{p_end}
{phang2}{cmd:. csdlp y, shock(x) state(L.z) controls(L.y) horizons(0/4) nbasis(4) vce(cluster) intermediate}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:csdlp} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations at the first horizon{p_end}
{synopt:{cmd:e(N_g)}}number of units{p_end}
{synopt:{cmd:e(T)}}number of time periods at the first horizon{p_end}
{synopt:{cmd:e(n_h)}}number of horizons{p_end}
{synopt:{cmd:e(level)}, {cmd:e(level2)}}band levels{p_end}
{synopt:{cmd:e(reps)}}Gaussian draws{p_end}
{synopt:{cmd:e(scale)}}shock size delta{p_end}
{synopt:{cmd:e(jmin)}, {cmd:e(jmax)}}candidate range for J{p_end}
{synopt:{cmd:e(normalized)}}1 if g_h was normalised to zero mean{p_end}
{synopt:{cmd:e(zbar_h}{it:#}{cmd:)}}sample mean of the state at horizon #{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:csdlp}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(shock)}, {cmd:e(state)}}variables{p_end}
{synopt:{cmd:e(controls)}, {cmd:e(absorb)}}controls and absorbed FE{p_end}
{synopt:{cmd:e(horizons)}}horizons{p_end}
{synopt:{cmd:e(select)}, {cmd:e(vce)}}selector and VCE type{p_end}
{synopt:{cmd:e(ivar)}, {cmd:e(tvar)}}panel and time variables{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(irf)}}grid results, one block per horizon; columns {it:h z g se pw_lo pw_hi u_lo u_hi u2_lo u2_hi glin selin lpw_lo lpw_hi lu_lo lu_hi gprime omega}{p_end}
{synopt:{cmd:e(summary)}}one row per horizon (Table 1); columns {it:h obs N T J lags crit crit2 b_lin se_lin p_lin b_proj W_nonlin df_nonlin p_nonlin W_nosd df_nosd p_nosd supt p_supt aic normalized}{p_end}
{synopt:{cmd:e(quant)}}Table 2; columns {it:h pctile z g se p glin selin plin}{p_end}
{synopt:{cmd:e(J)}}selected J by horizon{p_end}
{synopt:{cmd:e(b_h}{it:#}{cmd:)}, {cmd:e(V_h}{it:#}{cmd:)}}sieve coefficients and HAC variance (eq. 16){p_end}
{synopt:{cmd:e(kn_h}{it:#}{cmd:)}}full cubic knot vector{p_end}
{synopt:{cmd:e(cen_h}{it:#}{cmd:)}}basis centring constants (normalised case){p_end}
{synopt:{cmd:e(bl_h}{it:#}{cmd:)}, {cmd:e(Vl_h}{it:#}{cmd:)}}linear-interaction coefficients and variance{p_end}
{synopt:{cmd:e(ic_h}{it:#}{cmd:)}}criterion profile: {it:J_requested J_effective AIC BIC GCV K}{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample of the first horizon{p_end}

{pstd}
Columns u_lo/u_hi hold the {opt level()} uniform band, u2_lo/u2_hi the
{opt level2()} band, and pw_lo/pw_hi the pointwise interval. The "l" columns
hold the same objects for the linear-interaction LP. gprime is g_h'(z) and
omega is the Lemma 1 weight omega_h(z).


{marker references}{...}
{title:References}

{phang}
Jarocinski, M., and P. Karadi. 2020. Deconstructing monetary policy surprises:
The role of information shocks. {it:American Economic Journal: Macroeconomics}
12(2): 1-43. {browse "https://doi.org/10.1257/mac.20180090":doi:10.1257/mac.20180090}.
(Source of the shocks in {cmd:csdlp_states.dta}; state activity data from the
Federal Reserve Bank of Philadelphia, State Coincident Indexes.)

{marker DGJW2026}{...}
{phang}
David, J. M., R. Giacomini, X. Jiao, and W. Wang. 2026. Causal state-dependent
local projections. Federal Reserve Bank of Chicago Working Paper 2026-18.
{browse "https://doi.org/10.21033/wp-2026-18":doi:10.21033/wp-2026-18}.

{marker AS2026}{...}
{phang}
Almuzara, M., and V. Sancibrian. 2026. Micro responses to macro shocks. Federal
Reserve Bank of New York Staff Report 1090.
{browse "https://doi.org/10.59576/sr.1090":doi:10.59576/sr.1090}.

{phang}
Chernozhukov, V., D. Chetverikov, and K. Kato. 2014. Gaussian approximation of
suprema of empirical processes. {it:Annals of Statistics} 42: 1564-1597.
{browse "https://doi.org/10.1214/14-AOS1230":doi:10.1214/14-AOS1230}.

{phang}
Goncalves, S., A. M. Herrera, L. Kilian, and E. Pesavento. 2024. State-dependent
local projections. {it:Journal of Econometrics} 244: 105702.
{browse "https://doi.org/10.1016/j.jeconom.2024.105702":doi:10.1016/j.jeconom.2024.105702}.

{phang}
Goncalves, S., A. M. Herrera, L. Kilian, and E. Pesavento. 2024. Nonparametric
local projections. Federal Reserve Bank of Dallas Working Paper 2414.
{browse "https://doi.org/10.24149/wp2414":doi:10.24149/wp2414}.

{phang}
Kolesar, M., and M. Plagborg-Moller. 2024. Dynamic causal effects in a nonlinear
world: the good, the bad, and the ugly. arXiv:2411.10415.

{phang}
Montiel Olea, J. L., and M. Plagborg-Moller. 2021. Local projection inference is
simpler and more robust than you think. {it:Econometrica} 89: 1789-1823.
{browse "https://doi.org/10.3982/ECTA18756":doi:10.3982/ECTA18756}.

{phang}
Ottonello, P., and T. Winberry. 2020. Financial heterogeneity and the investment
channel of monetary policy. {it:Econometrica} 88: 2473-2502.
{browse "https://doi.org/10.3982/ECTA15949":doi:10.3982/ECTA15949}.

{phang}
Winkler, V. 2026. When and why state-dependent local projections work.
arXiv:2601.01622.

{phang}
Zhang, D., and W. B. Wu. 2017. Gaussian approximation for high dimensional time
series. {it:Annals of Statistics} 45: 1895-1919.
{browse "https://doi.org/10.1214/16-AOS1512":doi:10.1214/16-AOS1512}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original paper (David, Giacomini, Jiao and Wang 2026) when
using this command.
