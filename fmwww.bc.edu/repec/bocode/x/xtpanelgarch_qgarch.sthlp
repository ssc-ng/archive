{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch postestimation" "help xtpanelgarch_postestimation"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##qgarch"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch qgarch} {hline 2} Panel quantile GARCH models under homogeneity (Zhu, Li, Zhang and Li 2026)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch qgarch} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opt q:uantile(#)}}quantile level tau; default 0.05{p_end}
{synopt:{opt gr:oup(list)}}coefficients to group: any of {cmd:omega alpha beta}, or {cmd:none}; default all three{p_end}
{synopt:{opt deltam:ax(#)}}upper end of the threshold grid; default 2 (paper: [0, 2]){p_end}
{synopt:{opt ncand:idates(#)}}candidates per grid refinement; default 6 (authors' code){p_end}
{synopt:{opt tol:erance(#)}}BIC convergence tolerance of the grid search; default 1e-4{p_end}
{synopt:{opt bw:idth(hs|b)}}Hall-Sheather (default) or Bofinger bandwidth for the density{p_end}
{synopt:{opth fac:tors(varlist)}}observed common factors f_t: the factor QGARCH of eq. (10){p_end}
{synopt:{opt nolog}}suppress progress messages{p_end}
{synoptline}


{title:Description}

{pstd}
For each unit, the tau-th conditional quantile of a return y_it is{p_end}
{p 8 8 2}Q_tau(y_it | F_t-1) = w_i(tau) + a_i(tau) sum_{j>=1} b_i(tau){c 94}(j-1) |y_i,t-j|,{p_end}
{pstd}
the quantile GARCH of Zhu, Tan, Zheng and Li (2023). Here w, a and b drive the amplitude, fluctuation and
persistence of volatility. Each coefficient may cluster across units, and each has its own unknown partition
(eq. 4). The command implements the three-stage procedure.{p_end}
{phang2}Stage I: self-weighted quantile regression for each unit (eq. 5), with the He-Yi weights of eq. (9).
Starting values come from a GARCH(1,1) fitted to sqrt|y| sgn(y), plus a 9{c 94}3 grid, as in the authors' code.{p_end}
{phang2}Stage II: sort the initial estimates and run binary segmentation with the CUSUM statistic (6). The threshold
is chosen by BIC3 = weighted loss + g ln N, through the authors' adaptive grid on [0, {cmd:deltamax()}].{p_end}
{phang2}Stage III: pooled self-weighted quantile regression under the detected groups (eq. 7). By Theorem 3.1 it
equals the oracle estimator with probability approaching one and converges at rate sqrt(NT).{p_end}

{pstd}
Standard errors use the sandwich Omega1{c 94}-1 Omega0 Omega1{c 94}-1 / NT. The conditional density is estimated
by the difference quotient 2l / (Q_tau+l - Q_tau-l), with both quantiles refitted under the same groups
(supplement, eq. S.51).{p_end}


{title:Remarks}

{pstd}
Only a fractional moment of y is required, so the method suits heavy-tailed returns. For a lower-tail VaR
(tau < 0.5), the w and a estimates are negative. Theorem 3.1 assumes N/T -> 0 and cross-sectional
uncorrelatedness of the quantile scores (Assumption 1(ii)). The bandwidth's sample size n is not stated in
the paper; the command uses n = NT, the size of the pooled regression. With {opt factors()} the model becomes the factor QGARCH of
eq. (10), Q_tau = w_i + a_i sum b_i{c 94}(j-1)|y_i,t-j| + lambda_i'f_t. The loadings get their own homogeneity structure (eq. 11)
and their own BIC3 threshold, and they are named {cmd:lambda_}{it:var}{cmd::g#}. Loadings start from OLS of y_i on f_t, as in the
authors' code. Factors must be common across panels. The authors' code adds lambda'f_1 outside the check function at t = 1; the
command follows eq. (10) and keeps it inside. Use {cmd:group(omega alpha beta)} to leave the loadings ungrouped. Run the command once per quantile level; groups may change with tau (paper sec. 6).{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)} (group coefficients omega:g#, alpha:g#, beta:g#), {cmd:e(groups)} (N x 3 group labels),
{cmd:e(phi_initial)} (Stage I), {cmd:e(phi)} (unit coefficients after Stage III), {cmd:e(delta)} (selected thresholds),
{cmd:e(qtau)} (T x N fitted quantiles, the in-sample VaR), {cmd:e(weights)}; scalars {cmd:e(quantile)}, {cmd:e(loss)},
{cmd:e(hit)} (in-sample hit rate), {cmd:e(bandwidth)}, {cmd:e(g_omega)}, {cmd:e(g_alpha)}, {cmd:e(g_beta)}.{p_end}


{title:Example}

{phang2}{cmd:. xtpanelgarch qgarch ret, quantile(0.025)}{p_end}
{phang2}{cmd:. predict double var25, quantile}{p_end}


{title:References}

{phang}Zhu, Q., W. Li, W. Zhang, and G. Li. 2026. Panel quantile GARCH models under homogeneity.
{it:Journal of Business and Economic Statistics} 44: 270-281.
{browse "https://doi.org/10.1080/07350015.2025.2526418":doi:10.1080/07350015.2025.2526418}{p_end}
{phang}Zhu, Q., S. Tan, Y. Zheng, and G. Li. 2023. Quantile autoregressive conditional heteroscedasticity.
{it:Journal of the Royal Statistical Society, Series B} 85: 1099-1127.
{browse "https://doi.org/10.1093/jrsssb/qkad068":doi:10.1093/jrsssb/qkad068}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
