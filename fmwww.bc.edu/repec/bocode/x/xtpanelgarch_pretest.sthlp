{smcl}
{* *! version 1.0.0  06nov2026}{...}
{vieweralsosee "xtpanelgarch" "help xtpanelgarch"}{...}
{vieweralsosee "xtpanelgarch cg" "help xtpanelgarch_cg"}{...}
{vieweralsosee "xtpanelgarch methods" "help xtpanelgarch_methods##pretest"}{...}
{title:Title}

{phang}
{bf:xtpanelgarch pretest} {hline 2} Identification strategy for panel GARCH models (Cermeño and Grier 2001, 2006)


{title:Syntax}

{p 8 16 2}
{cmd:xtpanelgarch pretest} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt hacl:ags(#)}}Newey-West lag for the HAC Wald test; default floor(4(T/100){c 94}(2/9)){p_end}
{synopt:{opt l:ags(#)}}lags for the PACF and LM-ARCH tables; default 10{p_end}
{synopt:{opt arfe(#)}}AR order of the u{c 94}2 regression used to test unit effects in the variance; default 1{p_end}
{synopt:{opt cpl:ags(#)}}AR order for the cross-product regression; default 1{p_end}
{synopt:{opt sig:level(#)}}significance level used for the recommendation; default 0.05{p_end}
{synopt:{opt noxs}}skip the cross-sectional tests{p_end}
{synoptline}


{title:Description}

{pstd}
The command follows CG (2001, sec. 5) and CG (2006, sec. 10.3). It reports:{p_end}
{phang2}[1] a HAC Wald test of equal intercepts in the LSDV mean regression, chi2(N-1). Its result
decides whether the LSDV or the OLS residuals feed steps 2-5;{p_end}
{phang2}[2] partial autocorrelations of the squared residuals (as in CG 2001 Tables 1 and 3), with t-ratios
and one-sided p-values, plus the Engle (1982) LM-ARCH(j) statistic for j = 1..{cmd:lags()};{p_end}
{phang2}[3] individual effects in the variance: an F and a chi2 test of unit intercepts in the AR({cmd:arfe()})
regression of u{c 94}2, and the LR test of groupwise heteroskedasticity;{p_end}
{phang2}[4] cross-sectional correlation: the LR test that Sigma is diagonal, Breusch-Pagan LM, and Pesaran CD;{p_end}
{phang2}[5] a pooled AR regression of the cross products u_it u_jt and a test of pair-specific intercepts.{p_end}
{pstd}
It ends with a suggested {cmd:model()}, variance order and {cmd:cov()} for {helpb xtpanelgarch_cg}. Like CG
(2006, p. 266), treat the suggestion as a starting point: CG's own strategy picked their Model 2,
but Model 3 fit better.{p_end}


{title:Stored results}

{pstd}Scalars {cmd:r(wald_mu)}, {cmd:r(wald_mu_p)}, {cmd:r(F_varfe)}, {cmd:r(p_varfe)}, {cmd:r(lr_grouphet)},
{cmd:r(lr_xcorr)}, {cmd:r(lm_bp)}, {cmd:r(cd)} (with p-values) and {cmd:r(n_sig_pac)}; macros {cmd:r(suggest_model)},
{cmd:r(suggest_var)}, {cmd:r(suggest_cov)}; matrices {cmd:r(pac)}, {cmd:r(lmarch)}, {cmd:r(crossprod_ar)}.{p_end}


{title:Example}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. keep if inlist(company, 1, 2, 3, 4, 8)}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtpanelgarch pretest invest mvalue kstock, haclags(2)}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
