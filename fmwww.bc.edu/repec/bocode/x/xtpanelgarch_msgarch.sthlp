{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##msgarch"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch msgarch} {hline 2} Bayesian nonparametric panel Markov-switching GARCH (Casarin, Costantini and Osuntuyi 2024)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch msgarch} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 22}{...}
{synopthdr}
{synoptline}
{synopt:{opt stat:es(#)}}number of regimes K; default 2{p_end}
{synopt:{opt burn(#)}}burn-in iterations; default 1000{p_end}
{synopt:{opt draw:s(#)}}retained draws; default 2000{p_end}
{synopt:{opt thin(#)}}thinning; default 1{p_end}
{synopt:{opt nu(#)}}Pitman-Yor discount nu; default 0 (Dirichlet process){p_end}
{synopt:{opt psi(#)}}Pitman-Yor concentration psi; default 10 (paper, sec. 4.2){p_end}
{synopt:{opt phi(#)}}precision of the transition-row prior; default 10{p_end}
{synopt:{opt musd(#)}}first-stage scale s of mu_ik; default 0.25 sd(y){p_end}
{synopt:{opt r(#)}}first-stage beta precision r; default 100{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}


{title:Description}

{pstd}
Every series has its own hidden K-state Markov chain s_it, which drives a switching mean and switching GARCH parameters:{p_end}
{p 8 8 2}y_it = mu_i(s_it) + sigma_it e_it,  sigma{c 94}2_it = gamma_i(s_it) + alpha_i(s_it) u{c 94}2_i,t-1 + beta_i(s_it) sigma{c 94}2_i,t-1.{p_end}
{pstd}
The series-specific parameters are shrunk toward cluster atoms (first stage, eqs. 8-9). Within each regime, a
Pitman-Yor process prior clusters the atoms across series (eqs. 10-16). The posterior is sampled with the six
Gibbs/MH steps of section 3 and Appendix A:{p_end}
{phang2}1. slice and stick-breaking variables;{p_end}
{phang2}2. the transition probabilities (plus an MH step for r_k);{p_end}
{phang2}3. the cluster atoms;{p_end}
{phang2}4. the series parameters: MH with a normal-mixture proposal for the means, and the Nakatsuma-Ardia
linearised proposal for the GARCH parameters;{p_end}
{phang2}5. the regime paths: MH whose proposal is forward-filtering backward-sampling (FFBS) on the
Klaassen-collapsed MS-GARCH;{p_end}
{phang2}6. the cluster allocations.{p_end}
{pstd}
The regimes are identified by mu_i1 > mu_i2 > ... (sec. 4.2).{p_end}


{title:Remarks}

{pstd}
Two steps implement the exact full conditionals where the paper's formulas are approximations. First, the atom
updates for gamma*, alpha*, beta* use griddy-Gibbs on the exact beta full conditional, because the inverse-cdf form
of eqs. (36)-(37) drops the Beta normalising constants. Second, the mixture proposals of step 4 are not symmetric,
so their full Hastings ratio is used. During burn-in only, the GARCH-block proposal is rescaled adaptively per series toward a 25% acceptance rate, so the
kept chain is a valid MCMC. Check convergence with several seeds and inspect {cmd:e(acceptance)}. On the paper's design
(N = 30, T = 300) the regime means are recovered closely (correlation with the truth 0.99 and 0.92). The GARCH parameters
of each series are weakly identified at this T, with a trade-off between gamma and beta. Use longer chains for them. The
estimated number of clusters per regime is reported as its posterior mode (MAP), as in the paper's Figures 3 and 5.{p_end}


{title:Stored results}

{pstd}{cmd:e(b)}, {cmd:e(V)} posterior mean and covariance of the cross-sectional averages of (mu, gamma, alpha, beta) by regime;
{cmd:e(post)} N x 4K posterior means per series; {cmd:e(P)} N x K{c 94}2 transition matrices (row-major);
{cmd:e(sprob)} T x (N K) smoothed regime probabilities; {cmd:e(nclusters)} draws of the number of clusters by regime;
{cmd:e(cocluster)} (N K) x N co-clustering probabilities (eq. 28); {cmd:e(acceptance)}.{p_end}


{title:References}

{phang}Casarin, R., M. Costantini, and A. Osuntuyi. 2024. Bayesian nonparametric panel Markov-switching GARCH models.
{it:Journal of Business and Economic Statistics} 42: 135-146.
{browse "https://doi.org/10.1080/07350015.2023.2166049":doi:10.1080/07350015.2023.2166049}{p_end}
{phang}Billio, M., R. Casarin, and A. Osuntuyi. 2016. Efficient Gibbs sampling for Markov switching GARCH models.
{it:Computational Statistics and Data Analysis} 100: 37-57.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
