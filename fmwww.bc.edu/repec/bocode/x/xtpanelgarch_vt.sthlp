{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch cg" "help xtpanelgarch_cg"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##vt"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch vt} {hline 2} Feasible panel GARCH by three-step variance targeting (Asai 2023)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch vt} {depvar} {indepvars} {ifin} [{cmd:,} {opt ccp} {opt qml} {opt vce(robust|model)} {opt l:evel(#)} {opt notable}]


{title:Description}

{pstd}
The mean is y_it = alpha_i + z_it'theta + u_it, where z_it usually contains {cmd:L.}{it:depvar}. The conditional
covariance matrix follows Asai's feasible specification{p_end}
{p 8 8 2}H_t = (1 - gamma - phi) Sigma + gamma u_t-1 u_t-1' + phi H_t-1,{p_end}
{pstd}
which is positive definite at every t and stationary when gamma + phi < 1. Estimation proceeds in three steps:
fixed effects for (theta, alpha); the sample covariance of the residuals for Sigma; quasi-maximum likelihood
in (gamma, phi) only. Only two parameters are optimised, so {cmd:vt} scales to N where full ML
({helpb xtpanelgarch_cg:cg}, with k + 3 + N(N+3)/2 parameters) is impractical.{p_end}

{pstd}
{opt ccp} switches to the constant-correlation panel GARCH of eq. (27): h_ii,t follows the VT recursion and
h_ij,t = r_ij sqrt(h_ii,t h_jj,t), with r_ij taken from Sigma-hat.{p_end}

{pstd}
{opt vce(robust)} (default) uses Asai's misspecification-robust Omega_m (eq. 25) for theta and alpha.
{opt vce(model)} uses the model-based estimator (eq. 26), which is efficient under correct specification.
The (gamma, phi) block always uses Proposition 4. That sandwich accounts for the estimation of Sigma
in step 2.{p_end}


{pstd}
{opt qml} refines the VT estimates by full quasi-maximum likelihood of eq. (22) over (theta, alpha, Sigma, gamma, phi), started
at the VT solution, as in Asai's Table 5. Sigma is parameterised by its Cholesky factor so that it stays positive definite. The
reported variance is the Bollerslev-Wooldridge sandwich, and {cmd:e(Sigma)} holds the QML estimate of Sigma. QML is more efficient
than VT (Remark 3.3); VT is much faster for large N.{p_end}


{title:Remarks}

{pstd}
The asymptotics take n fixed and T to infinity. Asai's simulations show that a larger N shrinks the variance of
(gamma, phi) without improving the rate (Tables 1-2). Sigma-hat is N x N, so T must be well above N.
Use {cmd:estat pd} and {cmd:predict, correlation(i j)} to inspect the fitted covariance path.{p_end}


{title:Stored results}

{pstd}As for {helpb xtpanelgarch_cg##results:cg}, plus {cmd:e(Sigma)} (Sigma-hat) and {cmd:e(V_model1)} (the eq. 26 variance of the mean block).{p_end}


{title:Example}

{phang2}{cmd:. xtpanelgarch vt infl L.infl covid}{p_end}
{phang2}{cmd:. xtpanelgarch vt infl L.infl covid, ccp}{p_end}


{title:Reference}

{phang}Asai, M. 2023. Feasible panel GARCH models: Variance-targeting estimation and empirical application.
{it:Econometrics and Statistics} 25: 23-38. {browse "https://doi.org/10.1016/j.ecosta.2022.01.004":doi:10.1016/j.ecosta.2022.01.004}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
