{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "xtboundpanico" "help xtboundpanico"}{...}
{vieweralsosee "xtboundpanico methods" "help xtboundpanico_methods"}{...}
{vieweralsosee "xtboundpanico panico" "help xtboundpanico_panico"}{...}
{vieweralsosee "xtboundpanico nfactors" "help xtboundpanico_nfactors"}{...}
{viewerjumpto "Syntax" "xtboundpanico_bounds##syntax"}{...}
{viewerjumpto "Description" "xtboundpanico_bounds##description"}{...}
{viewerjumpto "Options" "xtboundpanico_bounds##options"}{...}
{viewerjumpto "Interpreting the output" "xtboundpanico_bounds##interpret"}{...}
{viewerjumpto "Remarks" "xtboundpanico_bounds##remarks"}{...}
{viewerjumpto "Examples" "xtboundpanico_bounds##examples"}{...}
{viewerjumpto "Stored results" "xtboundpanico_bounds##results"}{...}
{viewerjumpto "Author" "xtboundpanico_bounds##author"}{...}

{title:Title}

{phang}
{bf:xtboundpanico bounds} {hline 2} panel cointegration bounds test with common
factors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtboundpanico} {cmdab:bou:nds} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(#)}}deterministics: 0 none, 1 constant (default), 2 constant
and trend{p_end}
{synopt:{opt fac:tors(#)}}number of factor proxies r; default {it:1+k}{p_end}

{syntab:Lag order}
{synopt:{opt maxl:ags(#)}}maximum VAR order; default floor(4 (T/100)^(1/4)){p_end}
{synopt:{opt lags(#)}}impose this order instead of selecting{p_end}
{synopt:{opt lagc:rit(crit)}}{cmd:bic} (default), {cmd:aic}, {cmd:maic}, {cmd:mbic}{p_end}

{syntab:Inference}
{synopt:{opt cvm:ethod(method)}}{cmd:surface} (default) or {cmd:asymptotic}{p_end}
{synopt:{opt lev:el(#)}}level for the printed verdict; default 95{p_end}
{synopt:{opt dff:ull}}use full T in the error variance{p_end}
{synopt:{opt dfp:aper}}use full T and the paper's literal m_i{p_end}

{syntab:Reporting}
{synopt:{opt noc:ips}}suppress the CIPS comparator (roughly halves run time){p_end}
{synopt:{opt graph}}plot the individual t-ratios against both bounds{p_end}
{synopt:{opt name(name)}}name for the graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtboundpanico bounds} implements Section 3 of Banerjee and
Carrion-i-Silvestre (2026). It estimates the homogeneous long-run slope vector
by the pooled CCE estimator of Pesaran (2006), forms the error-correction term
yhat_it = thetahat' Y_it, fits the conditional error-correction model of
eq. (15) unit by unit, and averages the t-ratios of the speed-of-adjustment
coefficient into

{p 8 8 2}tybar = N^-1 sum_i t_rho_yi.{p_end}

{pstd}
Because the pooled CCE estimator is consistent {bf:under the null} of a spurious
relationship, the observable regressors drop out of the limiting distribution,
which then depends only on 1 + r_1 stochastic trends. Since r_1 is unknown, the
statistic is referred to {bf:two} critical values - one for r = r_0 (every
factor I(0)) and one for r = r_1 (every factor I(1)). Outside that interval the
verdict is robust to the number and order of integration of the factors; inside
it, inference is inconclusive.

{pstd}
The CIPS statistic of Banerjee and Carrion-i-Silvestre (2017), computed from the
CADF regression of eq. (18), is printed for comparison.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} chooses the deterministic component. Because the test focuses on
rho_yi alone, the paper's Cases 2 and 3 are equivalent and collapse into
{cmd:model(1)}, and Cases 4 and 5 into {cmd:model(2)}.

{phang}
{opt factors(#)} is the number of cross-section averages used as factor proxies,
entering z_i,t-1 in the order (ybar, xbar_1, ..., xbar_{it:r}-1). Assumption G
caps it at {it:1+k}; asking for more is an error. The default {it:1+k} is the
rank condition met with equality, which is what the paper's empirical
applications use. Over-specifying r leaves the I(1) bound almost unaffected but
makes the I(0) bound over-reject more in small T.

{phang}
{opt maxlags(#)}, {opt lags(#)} and {opt lagcrit(crit)} govern the VAR order
p_i, which is selected per unit. p_i is the order of the underlying VAR, so the
error-correction model carries p_i - 1 lagged differences. {cmd:bic} is the
paper's choice; {cmd:aic} over-selects badly here and is offered only for
completeness.

{phang}
{opt cvmethod(surface)} evaluates the response surfaces of Table C.2 at your
(r, k, T, N) and reports critical values at the 1, 2.5, 5 and 10% levels. This
is what the paper's own simulations use. A warning is printed when (r, k, T, N)
lies outside the box the surfaces were fitted on.
{opt cvmethod(asymptotic)} instead reads Table C.1, which has the 5% level only,
interpolated linearly in N over {c -(}20, 40, 60{c )-}.

{phang}
{opt dffull} and {opt dfpaper} switch the degrees of freedom used for the error
variance in eq. (17) to the two literal readings of the printed formula. Both
over-reject substantially in small T; see
{helpb xtboundpanico_methods:help xtboundpanico methods}. They exist so the
printed equation can be reproduced on demand, not because they are recommended.

{phang}
{opt nocips} skips the CADF regressions behind the CIPS comparator. Useful
inside simulation loops.

{phang}
{opt graph} plots each unit's t_rho_yi against the unit index, with the two
polar critical values as dashed lines and tybar as a solid line - so you can see
at a glance whether rejection is driven by a few units or is general.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.} Units actually used (degenerate units are dropped and reported),
periods, number of regressors k, number of factor proxies r, and the maximum
VAR order searched.

{pstd}
{bf:Pooled CCE long-run coefficients.} thetahat_x with Holly, Pesaran and
Yamagata (2010) standard errors. The z and p-value test theta_j = 0; to test a
theory restriction such as theta = 1, use {cmd:r(b_cce)} and {cmd:r(V_cce)}:

{phang2}{cmd:. xtboundpanico bounds s f, model(2)}{p_end}
{phang2}{cmd:. matrix b = r(b_cce)}{p_end}
{phang2}{cmd:. matrix V = r(V_cce)}{p_end}
{phang2}{cmd:. di (b[1,1]-1)/sqrt(V[1,1])}{p_end}

{pstd}
which is exactly the Fisher-effect / forward-rate-unbiasedness style of test the
paper runs in Section 6.

{pstd}
{bf:tybar} and the two bounds. The upper bound (all factors I(1)) is the more
negative one. With {cmd:level(95)} the decision rule printed is

{p 8 12 2}{it:tybar} < upper bound{col 42}COINTEGRATION{p_end}
{p 8 12 2}{it:tybar} > lower bound{col 42}NO COINTEGRATION (spurious){p_end}
{p 8 12 2}in between{col 42}INCONCLUSIVE{p_end}

{pstd}
All four levels are printed so you can see how wide the ambiguity region is at
each. A wide region at the level you care about is itself informative: it says
the data cannot tell you about cointegration without telling you about the
factors first.

{pstd}
{bf:CIPS.} The comparator. It is usually close to tybar - that is the point of
the comparison in the paper - but it assumes the factors are I(1) under the
null, so it is not robust in the way the bounds are.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Minimum T.} Equation (15) in its Case-5 form needs roughly
p_max + 2 + r + (1+k)(p_max-1) + r p_max + k + 2 periods. The command computes
that and errors out with the arithmetic shown rather than failing on a singular
matrix.

{pstd}
{bf:Weak exogeneity} of {it:indepvars} is maintained throughout (eq. 6). If your
regressors are not weakly exogenous the conditional error-correction
representation is not valid and neither is this test.

{pstd}
{bf:What to do with an inconclusive result.} Run
{helpb xtboundpanico_panico:xtboundpanico panico}. That is what it is for: it
estimates the factors and their order of integration, so the ambiguity region
disappears. The paper finds PANICO more powerful than the bounds test for
T >= 100.

{pstd}
{bf:Speed.} Each unit is fitted p_max times for the lag search, plus p_max more
for the CADF comparator. {opt nocips} and {opt lags()} both cut that down.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Constant, rank condition with equality{p_end}
{phang2}{cmd:. xtboundpanico bounds invest mvalue kstock, model(1)}{p_end}

{pstd}Trend, one factor only, with a figure{p_end}
{phang2}{cmd:. xtboundpanico bounds invest mvalue kstock, model(2) factors(1) graph}{p_end}

{pstd}Asymptotic critical values as a cross-check{p_end}
{phang2}{cmd:. xtboundpanico bounds invest mvalue kstock, model(2) cvmethod(asymptotic)}{p_end}

{pstd}Reproduce the paper's printed equation (17) literally{p_end}
{phang2}{cmd:. xtboundpanico bounds invest mvalue kstock, model(2) dfpaper}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtboundpanico bounds} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(tybar)}}the panel bounds statistic{p_end}
{synopt:{cmd:r(cv_i0)}}lower bound (all factors I(0)) at {cmd:level()}{p_end}
{synopt:{cmd:r(cv_i1)}}upper bound (all factors I(1)) at {cmd:level()}{p_end}
{synopt:{cmd:r(cips)}}CIPS comparator (unless {opt nocips}){p_end}
{synopt:{cmd:r(N)}}units used{p_end}
{synopt:{cmd:r(N_full)}}units in the estimation sample{p_end}
{synopt:{cmd:r(T)}}periods{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(r)}}number of factor proxies{p_end}
{synopt:{cmd:r(model)}}deterministic specification{p_end}
{synopt:{cmd:r(maxlags)}}maximum VAR order searched{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtboundpanico}{p_end}
{synopt:{cmd:r(subcmd)}}{cmd:bounds}{p_end}
{synopt:{cmd:r(decision)}}{cmd:COINTEGRATION}, {cmd:NO COINTEGRATION (spurious)}
or {cmd:INCONCLUSIVE}{p_end}
{synopt:{cmd:r(cvmethod)}}{cmd:surface} or {cmd:asymptotic}{p_end}
{synopt:{cmd:r(lagcrit)}}lag criterion{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(indepvars)}, {cmd:r(panelvar)}, {cmd:r(timevar)}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(b_cce)}}pooled CCE coefficients, {it:k} x 1{p_end}
{synopt:{cmd:r(V_cce)}}their HPY variance, {it:k} x {it:k}{p_end}
{synopt:{cmd:r(t_i)}}individual t_rho_yi, one row per retained unit{p_end}
{synopt:{cmd:r(lags_i)}}selected p_i per retained unit{p_end}
{synopt:{cmd:r(cv)}}4 x 2 critical values, rows 1/2.5/5/10%, columns I(0)/I(1){p_end}
{synopt:{cmd:r(t_cips)}}individual CADF t-ratios (unless {opt nocips}){p_end}
{synopt:{cmd:r(dropped)}}positions of dropped units, if any{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane
