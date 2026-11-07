{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch cg" "help xtpanelgarch_cg"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch postestimation} {hline 2} Postestimation tools for xtpanelgarch


{title:Commands}

{synoptset 22}{...}
{synopt:{cmd:predict}}conditional variances, standard deviations, residuals, covariances, correlations{p_end}
{synopt:{cmd:estat diagnostics}}Ljung-Box Q of z and z{c 94}2 and LM-ARCH, by panel and pooled{p_end}
{synopt:{cmd:estat pd}}positive definiteness of Omega_t; Asai (2023) Propositions 1-2{p_end}
{synopt:{cmd:estat volatility}}small-multiple plot of conditional variances (or {opt sd}) by panel{p_end}
{synopt:{cmd:estat correlation}}implied conditional correlations (covariance models){p_end}
{synopt:{cmd:estat effects}}unit effects mu_i and w_i with CIs (after {cmd:armagarch}; Su and Zhu 2024, Fig. 1){p_end}
{synopt:{cmd:estat backtest}}VaR backtests after {cmd:qgarch}: Kupiec, Christoffersen and DQ (Engle-Manganelli 2004){p_end}
{synopt:{cmd:estat forecast}}h-step conditional variance forecasts after {cmd:cg}, {cmd:vt}, {cmd:cl} and {cmd:armagarch}{p_end}
{synopt:{cmd:estat ic}}AIC and BIC{p_end}
{synopt:{helpb lrtest}}likelihood-ratio tests between nested models (e.g. CG models A-D, 1-3){p_end}


{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {newvar} {ifin} [{cmd:,} {opt v:ariance} | {opt sd} | {opt r:esiduals} | {opt std:residuals} |
{opt cov:ariance(i j)} | {opt corr:elation(i j)} | {opt quant:ile}]

{pstd}
{opt quantile} (the default after {cmd:qgarch}) returns the fitted conditional tau-quantile, the in-sample value-at-risk.
{it:i} and {it:j} are values of the panel variable. {opt covariance()} and {opt correlation()} return the
period-t value on every observation of that period.{p_end}


{title:Syntax for estat}

{p 8 16 2}{cmd:estat diagnostics} [{cmd:,} {opt l:ags(#)}]{p_end}
{p 8 16 2}{cmd:estat pd}{p_end}
{p 8 16 2}{cmd:estat backtest}{p_end}
{p 8 16 2}{cmd:estat forecast} [{cmd:,} {opt h:orizon(#)} {opt gr:aph} {opt name(string)}]{p_end}
{p 8 16 2}{cmd:estat volatility} [{cmd:,} {opt sd} {opt name(string)} {opt nodraw}]{p_end}
{p 8 16 2}{cmd:estat correlation} [{cmd:,} {opt name(string)} {opt nodraw}]{p_end}


{title:Remarks}

{pstd}
CG (2001, sec. 5.3) and CG (2006, p. 266) ask that the squared normalised residuals show no remaining
autocorrelation. {cmd:estat diagnostics} reports, for every panel and pooled, Q(z), Q(z{c 94}2) and the
LM-ARCH statistic on z_it = u_it / sigma_it. The pooled statistic is the sum of the unit statistics,
chi2(N x lags) under independence.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
