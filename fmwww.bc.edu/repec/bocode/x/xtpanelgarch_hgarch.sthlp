{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##hgarch"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch hgarch} {hline 2} Hierarchical GARCH (Brownlees 2019)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch hgarch} {varname} {ifin} {cmd:,} {opth char:acteristics(varlist)} [{it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opth char:acteristics(varlist)}}time-invariant series characteristics x_i (required){p_end}
{synopt:{opth fac:tor(varname)}}common factor rF_t (for example the market return){p_end}
{synopt:{opt draw:s(#)}}simulation draws S; default 100 (as in the paper){p_end}
{synopt:{opt seed(#)}}seed for the common draws; default 12345{p_end}
{synopt:{opt fixp:i(#)}}fix the persistence pi_i at # (the paper's simulation uses 0.99){p_end}
{synopt:{opt vce(oim|opg|robust)}}variance of the hyper-parameters; default {cmd:oim}{p_end}
{synoptline}


{title:Description}

{pstd}
Each series follows a factor GARCH(1,1) written in Brownlees' parameterisation{p_end}
{p 8 8 2}r_it = b_i rF_t + e_it,  h_it = (1 - pi_i) h_i + pi_i [lambda_i e{c 94}2_i,t-1 + (1 - lambda_i) h_i,t-1].{p_end}
{pstd}
Here h_i is the unconditional idiosyncratic variance, lambda_i the "roughness" a/(a+b), and pi_i = a + b the persistence.
At level II the coefficients depend on the characteristics through link functions, plus Gaussian random effects:
b_i = d_b'x_i + u, ln h_i = d_h'x_i + u, Phi{c 94}-1(lambda_i) = d_l'x_i + u, Phi{c 94}-1(pi_i) = d_p'x_i + u.
The hyper-parameters (d, tau) are estimated by simulated maximum likelihood of the marginal likelihood (7).
The same S draws are used for every series, and the stable log-sum-exp form (9) is applied. The series
coefficients are then estimated by their conditional expectations given the data (eqs. 10-12). These shrink each
series toward the value its characteristics imply, more strongly when tau is small.{p_end}

{pstd}
Starting values come from the paper's naive estimator: series-by-series ML, then OLS of the level-II equations.
The naive estimates are returned in {cmd:e(naive)} for comparison.{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)} (delta and ln tau); {cmd:e(coef)} N x 8: E(b_i), sd, E(h_i), sd, E(lambda_i), sd, E(pi_i), sd;
{cmd:e(naive)}; {cmd:e(ess)} (effective number of draws per series); {cmd:e(ll)} (simulated log likelihood).{p_end}


{title:Remarks}

{pstd}
The paper does not state the presample value; h_i0 = e{c 94}2_i0 = h_i is used. The hyper-parameter vector does not grow
with N, so large cross-sections are feasible. Increase {cmd:draws()} when {cmd:e(ess)} is small.{p_end}


{title:Reference}

{phang}Brownlees, C. 2019. Hierarchical GARCH. {it:Journal of Empirical Finance} 51: 17-27.
{browse "https://doi.org/10.1016/j.jempfin.2019.01.009":doi:10.1016/j.jempfin.2019.01.009}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
