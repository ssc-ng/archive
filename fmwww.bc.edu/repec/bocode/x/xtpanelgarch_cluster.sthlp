{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##cluster"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch cluster} {hline 2} Bayesian clustering of many GARCH models (Bauwens and Rombouts 2007)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch cluster} {varname} {ifin} {cmd:,} {opt g:roups(#)} [{it:options}]

{synoptset 26}{...}
{synopthdr}
{synoptline}
{synopt:{opt g:roups(#)}}number of groups G (required){p_end}
{synopt:{opt alpha:prior(numlist)}}uniform supports of alpha_g: lo1 hi1 lo2 hi2 ...{p_end}
{synopt:{opt beta:prior(numlist)}}uniform supports of beta_g: lo1 hi1 lo2 hi2 ...{p_end}
{synopt:{opt dir:ichlet(#)}}Dirichlet parameter a0 for every group; default 2{p_end}
{synopt:{opt burn(#)}}burn-in iterations; default 500{p_end}
{synopt:{opt draw:s(#)}}retained draws; default 2000{p_end}
{synopt:{opt grid(#)}}griddy-Gibbs grid points; default 33{p_end}
{synopt:{opt marg:lik}}compute the log marginal likelihood (Chib 1995, eq. 28){p_end}
{synopt:{opt mlreps(#)}}reduced-run draws for the marginal likelihood; default 200{p_end}
{synopt:{opt demean}}subtract series means first (the model has zero mean){p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}


{title:Description}

{pstd}
The N series are draws from a finite mixture of G GARCH(1,1) models. Series in the same group share (alpha_g, beta_g):{p_end}
{p 8 8 2}y_jt ~ N(0, h_jt),  h_jt = (1 - alpha_g - beta_g) w_j + alpha_g y{c 94}2_j,t-1 + beta_g h_j,t-1,{p_end}
{pstd}
with w_j fixed at the sample variance (variance targeting, as in the paper). The sampler alternates three steps:
the group indicators (eq. 13), the group probabilities from a Dirichlet (eqs. 14-15), and each (alpha_g, beta_g)
by griddy-Gibbs (eqs. 16-17). Following the paper, the priors are uniforms on boxes truncated to alpha + beta < 1.
Their supports must be {bf:separated} across groups, through alpha or beta; this is what identifies the labels
(sec. 3.4). Choose G by comparing the log marginal likelihoods ({cmd:marglik}) across runs with different {cmd:groups()} (sec. 4).{p_end}

{pstd}
If no supports are given, the command separates the alpha supports at quantiles of series-by-series estimates.
Check the posterior densities for truncation at the support bounds, as the authors recommend, and widen the
supports if needed.{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)} posterior means and covariance of (eta, alpha, beta); {cmd:e(draws_eta)}, {cmd:e(draws_theta)} the
draws; {cmd:e(alloc)} N x G posterior allocation probabilities; {cmd:e(prior)}; {cmd:e(omega)} (targeted variances);
{cmd:e(lnml)} and {cmd:e(lnml_parts)} with {cmd:marglik}.{p_end}


{title:Example}

{phang2}{cmd:. xtpanelgarch cluster ret, groups(3) alphaprior(.001 .07 .07 .15 .15 .25) betaprior(.65 .97 .45 .75 .20 .60) marglik}{p_end}


{title:References}

{phang}Bauwens, L., and J. V. K. Rombouts. 2007. Bayesian clustering of many GARCH models. {it:Econometric Reviews} 26: 365-386.
{browse "https://doi.org/10.1080/07474930701220576":doi:10.1080/07474930701220576}{p_end}
{phang}Chib, S. 1995. Marginal likelihood from the Gibbs output. {it:Journal of the American Statistical Association} 90: 1313-1321.
{browse "https://doi.org/10.1080/01621459.1995.10476635":doi:10.1080/01621459.1995.10476635}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
