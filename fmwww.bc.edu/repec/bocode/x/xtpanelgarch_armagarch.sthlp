{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch postestimation" "help xtpanelgarch_postestimation"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##armagarch"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch armagarch} {hline 2} Panel ARMA-GARCH model for large N and T (Su and Zhu 2024)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch armagarch} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 22}{...}
{synopthdr}
{synoptline}
{synopt:{opt ar(#)}}AR order P; default 1{p_end}
{synopt:{opt ma(#)}}MA order Q; default 1{p_end}
{synopt:{opt arch(#)}}ARCH order L; default 1{p_end}
{synopt:{opt garch(#)}}GARCH order K; default 1{p_end}
{synopt:{opt bias(none|jackknife)}}half-panel jackknife bias correction; default {cmd:none}{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt notable}}suppress the coefficient table{p_end}
{synoptline}
{p 4 6 2}Do not include lags of {it:depvar} in {it:indepvars}; the AR part is set by {cmd:ar()}.{p_end}


{title:Description}

{pstd}
The model is{p_end}
{p 8 8 2}y_it = mu_i + x_it'beta + sum_p phi_p y_i,t-p + sum_q psi_q u_i,t-q + u_it,{p_end}
{p 8 8 2}u_it = sqrt(h_it) e_it,  h_it = w_i (1 - sum tau_l - sum nu_k) + sum tau_l u{c 94}2_i,t-l + sum nu_k h_i,t-k.{p_end}
{pstd}
The ARMA and GARCH parameters are common to all units. Each unit has its own mean effect mu_i and
variance level w_i = E(u{c 94}2_it). Estimation has two steps. Step 1 is least squares with the fixed
effects concentrated out (eq. 2.4-2.5). Step 2 takes w_i-hat = mean of the squared step-1 residuals
and maximises the variance-targeting Gaussian quasi likelihood over (tau, nu) (eq. 2.9). All
common parameters converge at rate sqrt(NT). When N and T grow at the same rate, they carry
asymptotic biases of order 1/T (Theorems 4.1 and 4.4).{p_end}

{pstd}
{opt bias(jackknife)} applies the half-panel jackknife of Dhaene and Jochmans (2015), as in eq. (4.4)
for lambda = (beta, phi, psi) and eq. (4.11) for zeta = (tau, nu). zeta uses residuals at the corrected lambda,
and w_i is re-estimated in each half (the authors' code). Corrected and uncorrected estimators share the same
asymptotic variance (Theorems 4.3 and 4.6). The uncorrected estimates stay in {cmd:e(b_nobias)}.{p_end}


{title:Inference}

{pstd}
Var(lambda-hat) is the sandwich on the concentrated residuals, which is Theorem 4.1's Sigma1 under
martingale-difference errors. Var(zeta-hat) is Gamma2{c 94}-1 Omega2 Gamma2{c 94}-1 / NT. Omega2 includes the
estimation effects of w_i-hat and lambda-hat (Theorem 4.4). The paper's explicit formulas sit in an
unpublished supplement, so all derivatives are numerical. For the unit effects:
se(mu_i) = sqrt(w_i / l'Sigma_psi{c 94}-1 l) (Theorem 4.2); se(w_i) and se(varpi_i) follow Theorem 4.5 with the
pooled kurtosis of the standardised residuals.{p_end}


{title:Remarks}

{pstd}
On the paper's DGP (5.1) with N = 50 and T = 200, the sandwich standard errors match the paper's Monte
Carlo standard deviations: 0.014 / 0.005 / 0.013 / 0.013 / 0.048 for beta, phi, psi, tau, nu, against the
paper's 0.015 / 0.005 / 0.013 / 0.014 / 0.044. The authors suggest T >= 100 for reliable GARCH inference.
Presample values: y and u are zero in step 1 (eq. 2.2), and u{c 94}2 = h = w_i-hat in step 2
(the authors' code sets h_i1 = w_i-hat; the paper's text uses a constant c_h).{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)} (block diagonal in lambda and zeta), {cmd:e(b_nobias)}, {cmd:e(mu)}, {cmd:e(omega)} and
{cmd:e(varpi)} (N x 2: estimate, s.e.), {cmd:e(sigma2)}, {cmd:e(resid)}, and {cmd:e(halves)} with the
jackknife. Scalars {cmd:e(ll)}, {cmd:e(Q_ls)}, {cmd:e(kappa)}.{p_end}


{title:Example}

{phang2}{cmd:. xtpanelgarch armagarch ppi L.cpie L.ipm, ar(1) ma(1) arch(1) garch(1) bias(jackknife)}{p_end}
{phang2}{cmd:. estat effects}{p_end}


{title:Reference}

{phang}Su, B., and K. Zhu. 2024. Inference for the panel ARMA-GARCH model when both N and T are large.
{browse "https://arxiv.org/abs/2404.18377":arXiv:2404.18377}.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
