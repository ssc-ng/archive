{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##cl"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch cl} {hline 2} Composite-likelihood GARCH panel (Pakel, Shephard and Sheppard 2011)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch cl} {varname} {ifin} [{cmd:,} {opt demean} {opt dist:ribution(normal|t)} {opt hacl:ags(#)} {opt mac:gyver} {opt nocorr:ection} {opt l:evel(#)} {opt notable}]


{title:Description}

{pstd}
Each series i has a GARCH(1,1) variance with a common persistence (a, b) and its own level gamma_i:{p_end}
{p 8 8 2}sigma2_it = gamma_i (1 - a - b) + a y{c 94}2_i,t-1 + b sigma2_i,t-1.{p_end}
{pstd}
The nuisance parameters gamma_i are estimated by the method of moments, gamma_i = mean of y{c 94}2_it. Then
(a, b) maximise the composite likelihood, the average of the N univariate log likelihoods. This ignores the
cross-sectional dependence in the likelihood, but the standard errors account for it. They are the sqrt(T)
sandwich J{c 94}-1 I~ J{c 94}-1 of eq. (2.10): I~ is the Newey-West long-run variance of the cross-sectional
average score, corrected for the estimation of gamma_i.{p_end}

{phang}{opt demean} subtracts unit means first. The paper assumes zero-mean returns.{p_end}
{phang}{opt nocorrection} drops the nuisance correction from I~ and keeps the HAC.{p_end}
{phang}{opt macgyver} also reports Engle's (2009) MacGyver estimator: the median of per-series QMLEs
with gamma_i fixed. Per-series estimates are in {cmd:e(macgyver)}.{p_end}


{title:Remarks}

{pstd}
In Pakel et al.'s simulations CL works well once T >= 500, and the incidental-parameter bias from estimating
gamma_i is visible for T <= 250 (sec. 3.3). The command prints a note below T = 500.{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)}, {cmd:e(V_nocorr)}, {cmd:e(gamma)} (1 x N nuisance estimates), {cmd:e(sigma2)},
{cmd:e(cl)} (composite log likelihood, eq. 2.5), {cmd:e(haclags)}, and {cmd:e(macgyver)} when requested.{p_end}


{title:Reference}

{phang}Pakel, C., N. Shephard, and K. Sheppard. 2011. Nuisance parameters, composite likelihoods and a panel of GARCH models.
{it:Statistica Sinica} 21: 307-329.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
