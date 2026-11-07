{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch pretest" "help xtpanelgarch_pretest"}{...}
{vieweralsosee "xtpanelgarch cg" "help xtpanelgarch_cg"}{...}
{vieweralsosee "xtpanelgarch vt" "help xtpanelgarch_vt"}{...}
{vieweralsosee "xtpanelgarch cl" "help xtpanelgarch_cl"}{...}
{vieweralsosee "xtpanelgarch armagarch" "help xtpanelgarch_armagarch"}{...}
{vieweralsosee "xtpanelgarch qgarch" "help xtpanelgarch_qgarch"}{...}
{vieweralsosee "xtpanelgarch hgarch" "help xtpanelgarch_hgarch"}{...}
{vieweralsosee "xtpanelgarch cluster" "help xtpanelgarch_cluster"}{...}
{vieweralsosee "xtpanelgarch msgarch" "help xtpanelgarch_msgarch"}{...}
{vieweralsosee "xtpanelgarch postestimation" "help xtpanelgarch_postestimation"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] arch" "help arch"}{...}
{vieweralsosee "[TS] mgarch" "help mgarch"}{...}
{viewerjumpto "Syntax" "xtpanelgarch##syntax"}{...}
{viewerjumpto "Description" "xtpanelgarch##description"}{...}
{viewerjumpto "Which subcommand?" "xtpanelgarch##which"}{...}
{viewerjumpto "Examples" "xtpanelgarch##examples"}{...}
{viewerjumpto "References" "xtpanelgarch##references"}{...}
{viewerjumpto "Author" "xtpanelgarch##author"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch} {hline 2} Panel GARCH models: estimation, pre-testing and diagnostics


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch} {it:subcommand} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 16}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb xtpanelgarch_pretest:pretest}}identification strategy of Cermeño and Grier (2001, 2006){p_end}
{synopt:{helpb xtpanelgarch_cg:cg}}panel GARCH / DPD-CCV by maximum likelihood (Cermeño and Grier 2001, 2006; Cermeño and Sanin 2015; Lee 2010){p_end}
{synopt:{helpb xtpanelgarch_vt:vt}}feasible panel GARCH, three-step variance targeting (Asai 2023){p_end}
{synopt:{helpb xtpanelgarch_cl:cl}}composite-likelihood GARCH panel with nuisance intercepts (Pakel, Shephard and Sheppard 2011){p_end}
{synopt:{helpb xtpanelgarch_armagarch:armagarch}}panel ARMA-GARCH for large N and T with jackknife bias correction (Su and Zhu 2024){p_end}
{synopt:{helpb xtpanelgarch_qgarch:qgarch}}panel quantile GARCH with homogeneity pursuit (Zhu, Li, Zhang and Li 2026){p_end}
{synopt:{helpb xtpanelgarch_hgarch:hgarch}}hierarchical GARCH with characteristics and random effects (Brownlees 2019){p_end}
{synopt:{helpb xtpanelgarch_cluster:cluster}}Bayesian clustering of many GARCH models (Bauwens and Rombouts 2007){p_end}
{synopt:{helpb xtpanelgarch_msgarch:msgarch}}Bayesian nonparametric panel Markov-switching GARCH (Casarin, Costantini and Osuntuyi 2024){p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb xtset} with a panel and a time variable. Time-series operators are allowed in all varlists.
Postestimation tools are described in {helpb xtpanelgarch_postestimation}; the equation-by-equation derivations
and the step-to-equation maps are in {helpb xtpanelgarch_methods}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpanelgarch} brings conditional heteroskedasticity into panel data. Each subcommand implements one
estimator from the panel-GARCH literature exactly as written in its source paper and reports tables in the
format used by those papers: a mean block, a variance block, a covariance block, and a
"volatility dynamics" block (persistence, half-life, positive-definiteness checks).

{pstd}
The common thread is a dynamic panel regression

{p 8 8 2}
y_it = mu_i + phi y_i,t-1 + x_it'beta + u_it

{pstd}
whose disturbances have a time-varying conditional variance, with dynamics shared by all units
({it:panel homogeneity}). Unit-specific intercepts in the mean and in the variance are allowed.


{marker which}{...}
{title:Which subcommand?}

{p2colset 5 30 32 2}{...}
{p2col:Situation}Use{p_end}
{p2line}
{p2col:Small N, large T, want covariances}{cmd:cg, cov(common|pair|ccc)} or {cmd:vt}{p_end}
{p2col:Independent units, any N}{cmd:cg, cov(none)} (Models A-D) or {cmd:cl}{p_end}
{p2col:Positive definiteness must hold}{cmd:vt} (Asai's feasible form); check {cmd:cg} with {cmd:estat pd}{p_end}
{p2col:Many units, zero-mean returns}{cmd:cl} (fast, sqrt(T) inference){p_end}
{p2col:Large N and T, ARMA mean, unit effects}{cmd:armagarch} (sqrt(NT), jackknife){p_end}
{p2col:Value-at-risk, clusters of assets}{cmd:qgarch} (quantile-specific groups){p_end}
{p2col:Explain GARCH heterogeneity by firm characteristics}{cmd:hgarch}{p_end}
{p2col:Unknown groups of volatility dynamics, Bayesian}{cmd:cluster} (finite mixture), {cmd:msgarch} (regimes + clusters){p_end}
{p2col:Test the Friedman-Ball / Cukierman-Meltzer channels}{cmd:cg, archm het(L.y)}{p_end}
{p2col:Regime effects in volatility}{cmd:cg, het(}{it:regime dummies}{cmd:)} (Cermeño-Sanin 2015){p_end}
{p2line}


{marker examples}{...}
{title:Examples}

{pstd}Grunfeld investment data (Cermeño and Grier 2001, sec. 7.1){p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. keep if inlist(company, 1, 2, 3, 4, 8)}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtpanelgarch pretest invest mvalue kstock}{p_end}
{phang2}{cmd:. xtpanelgarch cg invest mvalue kstock, arch(1) model(D)}{p_end}
{phang2}{cmd:. estat diagnostics}{p_end}

{pstd}Dynamic panel with GARCH(1,1) variances and covariances (Cermeño and Grier 2006, Model 3){p_end}
{phang2}{cmd:. xtpanelgarch cg infl L(1/12).infl, arch(1) garch(1) varfe cov(pair)}{p_end}
{phang2}{cmd:. estat pd}{p_end}
{phang2}{cmd:. estat correlation}{p_end}

{pstd}Feasible panel GARCH by variance targeting (Asai 2023){p_end}
{phang2}{cmd:. xtpanelgarch vt infl L.infl covid}{p_end}
{phang2}{cmd:. xtpanelgarch vt infl L.infl covid, ccp}{p_end}

{pstd}Composite likelihood for a wide panel of returns (Pakel et al. 2011){p_end}
{phang2}{cmd:. xtpanelgarch cl ret, demean macgyver}{p_end}

{pstd}A complete worked example is in {cmd:xtpanelgarch_example.do} ({cmd:net get xtpanelgarch}).{p_end}


{marker references}{...}
{title:References}

{phang}Asai, M. 2023. Feasible panel GARCH models: Variance-targeting estimation and empirical application.
{it:Econometrics and Statistics} 25: 23-38. {browse "https://doi.org/10.1016/j.ecosta.2022.01.004":doi:10.1016/j.ecosta.2022.01.004}{p_end}
{phang}Bollerslev, T. 1986. Generalized autoregressive conditional heteroskedasticity. {it:Journal of Econometrics} 31: 307-327.
{browse "https://doi.org/10.1016/0304-4076(86)90063-1":doi:10.1016/0304-4076(86)90063-1}{p_end}
{phang}Bollerslev, T., and J. M. Wooldridge. 1992. Quasi-maximum likelihood estimation and inference in dynamic models with time-varying covariances.
{it:Econometric Reviews} 11: 143-172. {browse "https://doi.org/10.1080/07474939208800229":doi:10.1080/07474939208800229}{p_end}
{phang}Cermeño, R., and K. B. Grier. 2001. Modeling GARCH processes in panel data: Theory, simulations and examples. Working paper, CIDE and University of Oklahoma.{p_end}
{phang}Cermeño, R., and K. B. Grier. 2006. Conditional heteroskedasticity and cross-sectional dependence in panel data: An empirical study of inflation uncertainty in the G7 countries.
In {it:Panel Data Econometrics}, ed. B. H. Baltagi, 259-277. Amsterdam: Elsevier.
{browse "https://doi.org/10.1016/S0573-8555(06)74010-X":doi:10.1016/S0573-8555(06)74010-X}{p_end}
{phang}Cermeño, R., and M. E. Sanin. 2015. Are flexible exchange rate regimes more volatile? Panel GARCH evidence for the G7 and Latin America.
{it:Review of Development Economics} 19: 297-308. {browse "https://doi.org/10.1111/rode.12143":doi:10.1111/rode.12143}{p_end}
{phang}Engle, R. F. 1982. Autoregressive conditional heteroscedasticity with estimates of the variance of United Kingdom inflation. {it:Econometrica} 50: 987-1007.
{browse "https://doi.org/10.2307/1912773":doi:10.2307/1912773}{p_end}
{phang}Glosten, L. R., R. Jagannathan, and D. E. Runkle. 1993. On the relation between the expected value and the volatility of the nominal excess return on stocks.
{it:Journal of Finance} 48: 1779-1801. {browse "https://doi.org/10.1111/j.1540-6261.1993.tb05128.x":doi:10.1111/j.1540-6261.1993.tb05128.x}{p_end}
{phang}Lee, J. 2010. The link between output growth and volatility: Evidence from a GARCH model with panel data. {it:Economics Letters} 106: 143-145.
{browse "https://doi.org/10.1016/j.econlet.2009.11.008":doi:10.1016/j.econlet.2009.11.008}{p_end}
{phang}Su, B., and K. Zhu. 2024. Inference for the panel ARMA-GARCH model when both N and T are large. {browse "https://arxiv.org/abs/2404.18377":arXiv:2404.18377}.{p_end}
{phang}Zhu, Q., W. Li, W. Zhang, and G. Li. 2026. Panel quantile GARCH models under homogeneity. {it:Journal of Business and Economic Statistics} 44: 270-281.
{browse "https://doi.org/10.1080/07350015.2025.2526418":doi:10.1080/07350015.2025.2526418}{p_end}
{phang}Bauwens, L., and J. V. K. Rombouts. 2007. Bayesian clustering of many GARCH models. {it:Econometric Reviews} 26: 365-386.
{browse "https://doi.org/10.1080/07474930701220576":doi:10.1080/07474930701220576}{p_end}
{phang}Brownlees, C. 2019. Hierarchical GARCH. {it:Journal of Empirical Finance} 51: 17-27.
{browse "https://doi.org/10.1016/j.jempfin.2019.01.009":doi:10.1016/j.jempfin.2019.01.009}{p_end}
{phang}Casarin, R., M. Costantini, and A. Osuntuyi. 2024. Bayesian nonparametric panel Markov-switching GARCH models.
{it:Journal of Business and Economic Statistics} 42: 135-146. {browse "https://doi.org/10.1080/07350015.2023.2166049":doi:10.1080/07350015.2023.2166049}{p_end}
{phang}Pakel, C., N. Shephard, and K. Sheppard. 2011. Nuisance parameters, composite likelihoods and a panel of GARCH models. {it:Statistica Sinica} 21: 307-329.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
