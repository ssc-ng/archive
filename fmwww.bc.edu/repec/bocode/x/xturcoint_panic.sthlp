{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_panic##syntax"}{...}
{viewerjumpto "Description" "xturcoint_panic##description"}{...}
{viewerjumpto "Options" "xturcoint_panic##options"}{...}
{viewerjumpto "Remarks" "xturcoint_panic##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_panic##results"}{...}
{viewerjumpto "Examples" "xturcoint_panic##examples"}{...}
{viewerjumpto "References" "xturcoint_panic##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {bf:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint panic} {hline 2} PANIC panel unit-root tests: Bai-Ng (2010), Westerlund-Larsson (2009), Reese-Westerlund (2016) PANICCA


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint panic} {varname} {ifin} [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:xturcoint panicca} {varname} ... {space 3}(shortcut for {cmd:method(panicca)})

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt meth:od(name)}}{bf:bn2010} (default), {bf:wl2009} or {bf:panicca}{p_end}
{synopt:{opt mod:el(constant|trend)}}deterministics; default {cmd:constant}{p_end}
{synopt:{opt km:ax(#)}}maximum number of factors (bn2010, wl2009); default {cmd:5}{p_end}
{synopt:{opt fc:rit(pcp|icp)}}Bai-Ng (2002) criterion PCp2 (default) or ICp2{p_end}
{synopt:{opt pm:ax(#)}}maximum ADF lag (wl2009); default {cmd:8}{p_end}
{synopt:{opt ic(aic|bic|tstat)}}ADF lag selection (wl2009); default {cmd:tstat}{p_end}
{synopt:{opt pap:er}}Bai-Ng (2010) formulas for Pa, Pb, PMSB instead of the GAUSS ones (bn2010, panicca){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
All three tests use the PANIC decomposition of Bai and Ng (2004): the first differences are decomposed into common
factors and idiosyncratic errors, the idiosyncratic errors are cumulated into e_it, and the unit-root hypothesis is
tested on e_it, which is free of cross-sectional dependence.

{phang}{bf:bn2010} Bai and Ng (2010): factors by principal components; the pooled bias-corrected statistics Pa, Pb
and the panel modified Sargan-Bhargava statistic PMSB.{p_end}
{phang}{bf:wl2009} Westerlund and Larsson (2009): the pooled ADF statistic Ze of the idiosyncratic components and its
bias-adjusted version Ze+ (correction for the estimation of the factors).{p_end}
{phang}{bf:panicca} Reese and Westerlund (2016): the factors are replaced by the cross-section average of the first
differences (PANIC on cross-section averages); Pa, Pb and PMSB as in Bai and Ng (2010).{p_end}

{pstd}
All statistics are N(0,1) under H0 (all idiosyncratic components have a unit root) and reject for large negative
values. This is a port of the GAUSS procedures {cmd:BNG_PANICnew}, {cmd:JWL_PANICadj} and {cmd:JWR_PANICCA}
(tspdlib 3.0.0, PD_PANIC.src). Results are identical to GAUSS.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker remarks}{...}
{title:Remarks}

{pstd}{bf:GAUSS formulas and paper formulas.} By default this command follows the GAUSS code, so its results are identical to GAUSS. Where the GAUSS code departs from the published formula, the formula of the paper is available with option {cmd:paper}. The differences are listed below.

{pstd}In the GAUSS routine {cmd:PaPbPMSB}:{p_end}
{phang2}(1) phi^4 is computed from the cross-section {it:average} of omega_i^2, phi^4 = (mean omega_i^2)^2, whereas
Bai and Ng (2010) define phi^4 as the average of omega_i^4;{p_end}
{phang2}(2) in the constant case Pb multiplies by omega^2/phi^4 without the square root of Bai and Ng (2010, p. 1092),
Pb = sqrt(N) T (rho+ - 1) sqrt[ tr(e_-1'e_-1)/(N T^2) * omega^2/phi^4 ].{p_end}

{pstd}Option {cmd:paper} applies both corrections (it affects Pa, Pb and PMSB of {cmd:bn2010} and {cmd:panicca};
{cmd:wl2009} is unchanged). The corrected formulas coincide with those in the Stata code of Reese and Westerlund
(2016). The Bartlett window of the long-run variances is the same in GAUSS and in the Reese-Westerlund code and is
used in both modes. The correction matters most for Pb in the constant case.

{pstd}{bf:Related commands.} The original Bai-Ng (2004) PANIC Fisher test is {helpb xtpanic} (package {cmd:xtflexur});
the PANIC stationarity test (Bai-Ng 2005 / Nazlioglu et al. 2021) is {helpb xtpstat}; PANIC with sharp breaks
(Bai and Carrion-i-Silvestre 2009) is {helpb xtpanicsb} (package {cmd:xtpdroot}).

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(Pa)}, {cmd:r(Pb)}, {cmd:r(PMSB)}}statistics (bn2010, panicca) with {cmd:r(p_Pa)}, {cmd:r(p_Pb)}, {cmd:r(p_PMSB)}{p_end}
{synopt:{cmd:r(Ze)}, {cmd:r(Ze_plus)}}statistics (wl2009) with {cmd:r(p_Ze)}, {cmd:r(p_Ze_plus)}{p_end}
{synopt:{cmd:r(nfactors)}}number of factors selected (bn2010, wl2009){p_end}
{synopt:{cmd:r(formulas)}}{cmd:gauss} (default) or {cmd:paper} (bn2010, panicca){p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}
{synopt:{cmd:r(adf)}}N x 2: ADF statistic and lags of each idiosyncratic component (wl2009){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xturcoint panic lnrxrate}{p_end}
{phang2}{cmd:. xturcoint panic lnrxrate, paper}{p_end}
{phang2}{cmd:. xturcoint panic lnrxrate, method(bn2010) model(trend) kmax(8) fcrit(icp)}{p_end}
{phang2}{cmd:. xturcoint panic lnrxrate, method(wl2009) pmax(4) ic(aic)}{p_end}
{phang2}{cmd:. xturcoint panicca lnrxrate}{p_end}

{marker references}{...}
{title:References}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration. {it:Econometrica} 72: 1127-1177.{p_end}
{phang}Bai, J., and S. Ng. 2010. Panel unit root tests with cross-section dependence: A further investigation.
{it:Econometric Theory} 26: 1088-1114. {browse "https://doi.org/10.1017/S0266466609990478":doi:10.1017/S0266466609990478}{p_end}
{phang}Westerlund, J., and R. Larsson. 2009. A note on the pooling of individual PANIC unit root tests.
{it:Econometric Theory} 25: 1851-1868. {browse "https://doi.org/10.1017/S0266466609990338":doi:10.1017/S0266466609990338}{p_end}
{phang}Reese, S., and J. Westerlund. 2016. PANICCA: PANIC on cross-section averages.
{it:Journal of Applied Econometrics} 31: 961-981. {browse "https://doi.org/10.1002/jae.2487":doi:10.1002/jae.2487}{p_end}
{phang}Bai, J., and S. Ng. 2002. Determining the number of factors in approximate factor models. {it:Econometrica} 70: 191-221.{p_end}

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
