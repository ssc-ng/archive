{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_cd##syntax"}{...}
{viewerjumpto "Description" "xturcoint_cd##description"}{...}
{viewerjumpto "Options" "xturcoint_cd##options"}{...}
{viewerjumpto "Remarks" "xturcoint_cd##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_cd##results"}{...}
{viewerjumpto "Examples" "xturcoint_cd##examples"}{...}
{viewerjumpto "References" "xturcoint_cd##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {bf:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint cd} {hline 2} Error cross-sectional dependence tests (BP 1980, PUY 2008, Pesaran 2004/2021, BFK 2012)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint cd} {depvar} [{indepvars}] {ifin} [{cmd:,} {opt nocons:tant} {opt tre:nd} {opt pap:er}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:xturcoint cd} regresses y_i on the regressors unit by unit, computes the pairwise correlations rho_ij of the
residuals and reports five tests of H0: no cross-sectional dependence:

{p2colset 8 30 32 2}{...}
{p2col:{bf:LM}}Breusch and Pagan (1980), T sum rho_ij^2 ~ chi2(N(N-1)/2) (T large, N small){p_end}
{p2col:{bf:LMadj}}Pesaran, Ullah and Yamagata (2008) bias-adjusted LM with the exact mean and variance of (T-k)rho_ij^2{p_end}
{p2col:{bf:CDlm}}Pesaran (2004, 2021) scaled LM{p_end}
{p2col:{bf:CDlm+}}Baltagi, Feng and Kao (2012) bias-corrected scaled LM, CDlm - N/(2(T-1)){p_end}
{p2col:{bf:CD}}Pesaran (2004, 2021) CD test based on the average correlation{p_end}
{p2colreset}{...}

{pstd}
The last four are N(0,1) with two-sided p-values. Use the result to choose between first-generation and
second-generation (factor-robust) panel unit-root tests such as {helpb xturcoint_panic:xturcoint panic} or
{helpb xturcoint_mp:xturcoint mp}. This is a port of the GAUSS procedure {cmd:pd_getCDError} (tspdlib 3.0.0,
PD_cdtests.src); results are identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker options}{...}
{title:Options}

{phang}{opt noconstant} omits the constant from the unit regressions (GAUSS uses exactly the regressor matrix it is
given; by default {cmd:xturcoint} adds a constant). With no {it:indepvars} the residuals are deviations from the unit means.

{phang}{opt trend} adds a linear trend to every unit regression.

{phang}{cmd:paper} reports the CD statistic with the formula of Pesaran (2004, 2021), scaled by sqrt(T), instead of the
GAUSS formula; see Remarks. The other four statistics are the same in both modes.

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the formula of the paper is available with option {cmd:paper}. The differences are listed below.

{pstd}{bf:The CD statistic.} GAUSS tspdlib accumulates T*rho_ij instead of sqrt(T)*rho_ij, so the GAUSS CD equals
sqrt(T) times the CD statistic of Pesaran (2004, 2021):{p_end}
{p 8 8 2}GAUSS: CD = sqrt(2/(N(N-1))) sum_{c 60}i<j{c 62} T rho_ij{space 6}paper: CD = sqrt(2T/(N(N-1))) sum_{c 60}i<j{c 62} rho_ij{p_end}
{pstd}By default {cmd:xturcoint cd} reports the GAUSS value and prints the paper value below the table; option
{cmd:paper} puts the paper value in the table. The paper value coincides with the CD of {helpb xtcd2} computed on the
same residuals. Because the GAUSS value is inflated by sqrt(T), the two can lead to different conclusions; for
inference report the paper value. LM, LMadj, CDlm and CDlm+ are not affected.

{pstd}{bf:Related commands.} {helpb xtcd2} (Pesaran CD, Juodis-Reese CDw, Pesaran-Xie CD*), {helpb xtcsd} (Pesaran,
Frees and Friedman tests after {cmd:xtreg}) and {helpb xttest2} (Breusch-Pagan LM).

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(LM)}, {cmd:r(p_LM)}, {cmd:r(df_LM)}}Breusch-Pagan LM{p_end}
{synopt:{cmd:r(LMadj)}, {cmd:r(p_LMadj)}}Pesaran-Ullah-Yamagata{p_end}
{synopt:{cmd:r(CDlm)}, {cmd:r(p_CDlm)}}Pesaran scaled LM{p_end}
{synopt:{cmd:r(CDlmadj)}, {cmd:r(p_CDlmadj)}}Baltagi-Feng-Kao{p_end}
{synopt:{cmd:r(CD)}, {cmd:r(p_CD)}}CD as reported in the table{p_end}
{synopt:{cmd:r(CD_paper)}}CD with sqrt(T) scaling (Pesaran 2021){p_end}
{synopt:{cmd:r(rbar)}, {cmd:r(arbar)}}average correlation and average absolute correlation{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}, {cmd:r(k)}}dimensions; k counts the constant/trend{p_end}
{synopt:{cmd:r(formulas)}}{cmd:gauss} (default) or {cmd:paper}{p_end}
{synopt:{cmd:r(rho)}}N x N residual correlation matrix{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xturcoint cd invest mvalue kstock}{p_end}
{phang2}{cmd:. xturcoint cd invest mvalue kstock, paper}{p_end}
{phang2}{cmd:. xturcoint cd invest}{p_end}

{marker references}{...}
{title:References}

{phang}Breusch, T. S., and A. R. Pagan. 1980. The Lagrange multiplier test and its applications to model specification in econometrics.
{it:Review of Economic Studies} 47: 239-253.{p_end}
{phang}Pesaran, M. H., A. Ullah, and T. Yamagata. 2008. A bias-adjusted LM test of error cross-section independence.
{it:Econometrics Journal} 11: 105-127. {browse "https://doi.org/10.1111/j.1368-423X.2007.00227.x":doi:10.1111/j.1368-423X.2007.00227.x}{p_end}
{phang}Pesaran, M. H. 2021. General diagnostic tests for cross-sectional dependence in panels.
{it:Empirical Economics} 60: 13-50. {browse "https://doi.org/10.1007/s00181-020-01875-7":doi:10.1007/s00181-020-01875-7}{p_end}
{phang}Baltagi, B. H., Q. Feng, and C. Kao. 2012. A Lagrange multiplier test for cross-sectional dependence in a fixed effects panel data model.
{it:Journal of Econometrics} 170: 164-177. {browse "https://doi.org/10.1016/j.jeconom.2012.04.004":doi:10.1016/j.jeconom.2012.04.004}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
{help xturcoint:xturcoint} (overview, list of all tests, map of the GAUSS libraries){break}
Unit root: {help xturcoint_lm:xturcoint lm}, {help xturcoint_fixedt:xturcoint fixedt}, {help xturcoint_mp:xturcoint mp}, {help xturcoint_panic:xturcoint panic}{break}
Pre-test: {help xturcoint_cd:xturcoint cd}{break}
Cointegration: {help xturcoint_cusum:xturcoint cusum}, {help xturcoint_adfmin:xturcoint adfmin}
{p_end}
