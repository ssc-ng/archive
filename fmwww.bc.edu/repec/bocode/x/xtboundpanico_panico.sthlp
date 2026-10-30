{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "xtboundpanico" "help xtboundpanico"}{...}
{vieweralsosee "xtboundpanico methods" "help xtboundpanico_methods"}{...}
{vieweralsosee "xtboundpanico bounds" "help xtboundpanico_bounds"}{...}
{vieweralsosee "xtboundpanico nfactors" "help xtboundpanico_nfactors"}{...}
{viewerjumpto "Syntax" "xtboundpanico_panico##syntax"}{...}
{viewerjumpto "Description" "xtboundpanico_panico##description"}{...}
{viewerjumpto "Options" "xtboundpanico_panico##options"}{...}
{viewerjumpto "Interpreting the output" "xtboundpanico_panico##interpret"}{...}
{viewerjumpto "Remarks" "xtboundpanico_panico##remarks"}{...}
{viewerjumpto "Examples" "xtboundpanico_panico##examples"}{...}
{viewerjumpto "Stored results" "xtboundpanico_panico##results"}{...}
{viewerjumpto "Author" "xtboundpanico_panico##author"}{...}

{title:Title}

{phang}
{bf:xtboundpanico panico} and {bf:panicca} {hline 2} PANIC analysis of
cointegration in panels with common factors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtboundpanico} {cmdab:panico:} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{p 8 17 2}
{cmd:xtboundpanico} {cmdab:panicca:} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(#)}}deterministics: 0 none, 1 constant (default), 2 constant
and trend{p_end}

{syntab:Number of factors}
{synopt:{opt fac:tors(#)}}impose this many factors instead of estimating{p_end}
{synopt:{opt rmax(#)}}maximum considered; default 5 ({cmd:panico}) or
{it:1+k} ({cmd:panicca}){p_end}
{synopt:{opt nfac:tors(crit)}}criterion used; see below{p_end}

{syntab:Lag order}
{synopt:{opt maxl:ags(#)}}maximum ADF lags; default floor(4 (T/100)^(1/4)){p_end}
{synopt:{opt lags(#)}}impose this many instead of selecting{p_end}
{synopt:{opt lagc:rit(crit)}}{cmd:bic} (default), {cmd:aic}, {cmd:maic}, {cmd:mbic}{p_end}

{syntab:Long-run variance}
{synopt:{opt nwb:w(#)}}Bartlett bandwidth; default is Ng's data-dependent rule{p_end}

{syntab:Reporting}
{synopt:{opt lev:el(#)}}level for the printed verdicts; default 95{p_end}
{synopt:{opt savec:omp(stub)}}save uhat* and Fhat as variables{p_end}
{synopt:{opt graph}}plot the factors and the per-unit ADF statistics{p_end}
{synopt:{opt name(name)}}name for the graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtboundpanico panico} implements Section 4 of Banerjee and
Carrion-i-Silvestre (2026): PANICO, the extension of the PANIC methodology of
Bai and Ng (2004, 2010) from panel unit roots to panel cointegration.

{pstd}
Starting from the pooled CCE estimate of the homogeneous long-run slope vector,
the error-correction term yhat_it is differenced, projected on the deterministic
component, and defactored. The idiosyncratic residuals and the factors are
recumulated into uhat*_it and Fhat_t. Six statistics then test whether uhat*_it
has a unit root - which, by Theorem 2 of the paper, is the null of a panel
spurious relationship - and the ADF or MQ statistics determine how many of the
common factors carry a stochastic trend.

{pstd}
The decisive property is {bf:invariance}: because theta is pooled and
consistently estimated under the null, the limiting distributions are identical
to those of PANIC for panel unit roots. PANICO also does {bf:not} require the
rank condition (Assumption G) that the bounds branch needs.

{pstd}
{cmd:panicca} differs in one step only: the factors are the differenced,
demeaned cross-section averages of the observables rather than principal
components, following Reese and Westerlund (2016). Everything downstream is
identical.

{pstd}
Unlike the bounds test, PANICO has {bf:no inconclusive region}. The price is
that the number of factors must be estimated.


{marker options}{...}
{title:Options}

{phang}
{opt factors(#)} imposes the number of factors and skips selection. With
{cmd:panicca} it cannot exceed {it:1+k}, since only {it:1+k} cross-section
averages exist.

{phang}
{opt rmax(#)} bounds the search. The default is 5 for {cmd:panico} - the paper's
choice - and {it:1+k} for {cmd:panicca}. {cmd:rmax} also enters PCp, AIC3 and
BIC3 through sigmahat^2 = V(rmax), so it is not a neutral upper limit.

{phang}
{opt nfactors(crit)} selects the criterion. For {cmd:panico}: {cmd:icp1} (the
panel BIC, the default), {cmd:icp2}, {cmd:icp3}, {cmd:pcp1}, {cmd:pcp2},
{cmd:pcp3}, {cmd:aic3}, {cmd:bic3} (Bai and Ng 2002), {cmd:er}, {cmd:gr}
(Ahn and Horenstein 2013) or {cmd:ed} (Onatski 2010). For {cmd:panicca} the
default is {cmd:rw}, the Reese-Westerlund criterion; {cmd:icp1}-{cmd:icp3},
{cmd:bic3}, {cmd:er}, {cmd:gr} and {cmd:ed} are also accepted.
Run {helpb xtboundpanico_nfactors:xtboundpanico nfactors} first to see them all.

{phang}
{opt maxlags(#)}, {opt lags(#)}, {opt lagcrit(crit)} govern the per-unit ADF
regression of eq. (22), which has {bf:no deterministic terms} - the deterministic
component has already been removed in differences. Here the number of lags may
be zero.

{phang}
{opt nwbw(#)} fixes the Bartlett truncation used for the long-run variances
behind Pa, Pb, PMSB and MQc. The default is the Andrews AR(1) plug-in rule used
in the PANIC code, ceil(1.1447 (alphahat T)^(1/3)). {cmd:nwbw(0)} switches off
the autocovariance correction entirely.

{phang}
{opt savecomp(stub)} creates {it:stub}{cmd:_u} with uhat*_it and
{it:stub}{cmd:_f1}, {it:stub}{cmd:_f2}, ... with the estimated factors (constant
across units, since the factors are common). Useful for plotting the common
component or feeding it into another model.

{phang}
{opt graph} combines two panels: the estimated factors over time, and the
per-unit ADF statistics against the 5% critical value {bf:for the case in use}
- about -1.94 in case c and -2.62 in case tau, since the two limits differ.
The two panels are also kept separately, undrawn, as {it:name}{cmd:_f} and
{it:name}{cmd:_u}, so either can be shown or exported on its own:

{phang2}{cmd:. xtboundpanico panico y x, model(2) graph name(fig)}{p_end}
{phang2}{cmd:. graph display fig_f}{p_end}
{phang2}{cmd:. graph export factors.png, replace}{p_end}

{pstd}
{space 4}The data in memory are untouched by the plotting.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Case c vs case tau.} Models 0 and 1 are "case c", Model 2 is "case tau".
This matters: in case tau the per-unit ADF statistic does {bf:not} have a
Dickey-Fuller distribution. Bai and Ng (2004) Theorem 3.1 shows it converges to
-(1/2)(int V^2)^(-1/2) with V a Brownian bridge, so its 5% point is about -2.62
rather than -1.95. The command uses the right distribution for each case; the
figure's reference line is the case-c value and is labelled as such.

{pstd}
{bf:Group-type P, Pm, Z.} These pool the per-unit ADF statistics and tolerate
heterogeneous short-run dynamics. P is chi2(2N) read in the upper tail; Pm in
the upper tail of the standard normal; Z in the lower tail. They over-reject
mildly in small T because asymptotic moments and p-values are used - the paper
documents this in Section 5.2.

{pstd}
{bf:Pooled-type Pa, Pb, PMSB.} These impose a common autoregressive parameter
and are read in the lower tail of the standard normal. Pa over-rejects for small
N; Pb is close to nominal regardless of T and N; PMSB is conservative in finite
samples and attains the nominal size as T grows. {bf:Pb and PMSB are the ones to
lean on}, and PMSB has the attraction of not requiring rho to be estimated at
all.

{pstd}
{bf:Common component.} With one factor, the ADF on Fhat decides I(0) against
I(1) using ordinary Dickey-Fuller critical values (with an intercept in case c,
with an intercept and a trend in case tau). With several factors, MQc and MQf
are applied sequentially from m = min(r, 6) downwards; the last row of each
table is the estimated number of I(1) factors r_1. MQc removes serial
correlation nonparametrically, MQf by filtering with an estimated VAR; they can
disagree, and the paper reports both.

{pstd}
{bf:Putting it together.} The idiosyncratic block answers "is there
cointegration?". The common block answers "what kind of cross-section dependence
is there?". A rejection in the idiosyncratic block with an I(1) factor is the
classic finding: the series are I(1) and driven by a common stochastic trend,
but a stationary long-run relationship exists once that trend is accounted for.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Cross-sectional independence.} Theorem 2 strengthens Assumption C(ii) to
E(e_it e_jt') = 0 for i != j. Every pooled PANIC test needs this, as do Pesaran
(2007) and Gengenbach, Urbain and Westerlund (2016). The common factors are
supposed to absorb the pervasive dependence; what is assumed away is residual
dependence in the idiosyncratic innovations. If you suspect strong remaining
dependence, the group-type statistics are the more forgiving of the six.

{pstd}
{bf:panico or panicca?} The paper finds the conclusions "almost identical". PC
factors need no rank condition and can exceed {it:1+k}; CA factors are simpler,
need no estimation of the factor space, and are less prone to the small-sample
distortions of principal components documented by Westerlund and Urbain. Running
both, as {cmd:xtboundpanico all} does, is cheap and is what the paper does.

{pstd}
{bf:Choosing r matters.} In the paper's own applications every Bai-Ng criterion
selected rmax while ED and the eigenvalue ratios selected 1, and the qualitative
conclusions held either way - but check that for your data rather than assuming
it. The Reese-Westerlund criterion is a multivariate ICp3 and can over-estimate.

{pstd}
{bf:Minimum T.} The ADF regressions need about maxlags + 6 periods; the command
errors out with the arithmetic shown.

{pstd}
{bf:MQ coverage.} Bai and Ng's Table I covers at most 6 factors, so the
sequential procedure starts at min(r, 6).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Default: PC factors, panel BIC, rmax 5{p_end}
{phang2}{cmd:. xtboundpanico panico invest mvalue kstock, model(1)}{p_end}

{pstd}Trend case, factor number from BIC3, with a figure{p_end}
{phang2}{cmd:. xtboundpanico panico invest mvalue kstock, model(2) nfactors(bic3) graph}{p_end}

{pstd}Impose two factors and keep the components{p_end}
{phang2}{cmd:. xtboundpanico panico invest mvalue kstock, model(2) factors(2) savecomp(pc)}{p_end}
{phang2}{cmd:. line pc_f1 pc_f2 year if company==1}{p_end}

{pstd}The cross-section-average variant{p_end}
{phang2}{cmd:. xtboundpanico panicca invest mvalue kstock, model(2)}{p_end}

{pstd}Switch off the autocovariance correction{p_end}
{phang2}{cmd:. xtboundpanico panico invest mvalue kstock, model(2) nwbw(0)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtboundpanico panico} and {cmd:panicca} store the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(P)}}, {cmd:r(P_p)}{space 4}group-type P and its p-value{p_end}
{synopt:{cmd:r(Pm)}}, {cmd:r(Pm_p)}{space 2}group-type Pm{p_end}
{synopt:{cmd:r(Z)}}, {cmd:r(Z_p)}{space 4}group-type Z{p_end}
{synopt:{cmd:r(Pa)}}, {cmd:r(Pa_p)}{space 2}pooled Pa{p_end}
{synopt:{cmd:r(Pb)}}, {cmd:r(Pb_p)}{space 2}pooled Pb{p_end}
{synopt:{cmd:r(PMSB)}}, {cmd:r(PMSB_p)}{space 0}pooled PMSB{p_end}
{synopt:{cmd:r(adf_F)}}, {cmd:r(adf_F_p)}{space 0}ADF on Fhat, if r = 1{p_end}
{synopt:{cmd:r(r1)}}estimated number of I(1) factors, if r = 1{p_end}
{synopt:{cmd:r(r1_mqc)}}, {cmd:r(r1_mqf)}{space 0}same from MQc / MQf, if r > 1{p_end}
{synopt:{cmd:r(r)}}number of factors used{p_end}
{synopt:{cmd:r(rmax)}}maximum considered{p_end}
{synopt:{cmd:r(N)}}, {cmd:r(T)}, {cmd:r(k)}, {cmd:r(model)}, {cmd:r(level)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtboundpanico}{p_end}
{synopt:{cmd:r(subcmd)}}{cmd:panico} or {cmd:panicca}{p_end}
{synopt:{cmd:r(nfactors)}}criterion used for r{p_end}
{synopt:{cmd:r(dcase)}}{cmd:c} or {cmd:tau}{p_end}
{synopt:{cmd:r(lagcrit)}}lag criterion{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(indepvars)}, {cmd:r(panelvar)}, {cmd:r(timevar)}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(b_cce)}}pooled CCE coefficients{p_end}
{synopt:{cmd:r(V_cce)}}their HPY variance{p_end}
{synopt:{cmd:r(adf_i)}}per-unit ADF statistics, N x 1{p_end}
{synopt:{cmd:r(p_i)}}their p-values, N x 1{p_end}
{synopt:{cmd:r(lags_i)}}selected ADF lags per unit{p_end}
{synopt:{cmd:r(Fhat)}}estimated factors, T x r{p_end}
{synopt:{cmd:r(ic)}}factor-number criteria table{p_end}
{synopt:{cmd:r(mqc)}}, {cmd:r(mqf)}{space 2}MQ tables (m, statistic, 5% c.v.,
reject), if r > 1{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane
