{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint mp" "help xturcoint_mp"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint##syntax"}{...}
{viewerjumpto "Description" "xturcoint##description"}{...}
{viewerjumpto "Which test to use" "xturcoint##guide"}{...}
{viewerjumpto "GAUSS map" "xturcoint##gauss"}{...}
{viewerjumpto "Validation" "xturcoint##validation"}{...}
{viewerjumpto "GAUSS vs paper formulas" "xturcoint##formulas"}{...}
{viewerjumpto "Examples" "xturcoint##examples"}{...}
{viewerjumpto "Author" "xturcoint##author"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {bf:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {help xturcoint_mp:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint} {hline 2} Panel unit-root, cross-sectional dependence and panel cointegration tests ported from the
GAUSS libraries {it:tspdlib}, {it:carrionlib} and {it:westerlundlib}, with results identical to GAUSS


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint} {it:subcommand} {it:varlist} {ifin} [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:xturcoint} {space 3}(without arguments: lists all tests with clickable links)

{synoptset 20}{...}
{p2coldent:{it:subcommand}}test (click for the full help page){p_end}
{synoptline}
{syntab:Panel unit root / stationarity}
{synopt:{helpb xturcoint_lm:lm}}Im-Lee-Tieslau (2005) panel LM with level shifts; Lee-Tieslau (2019) with level and trend shifts; 0, 1 or 2 breaks{p_end}
{synopt:{helpb xturcoint_fixedt:fixedt}}Hadri-Larsson (2005) stationarity and Carrion-i-Silvestre-Hadri (2010) unit-root tests for fixed T{p_end}
{synopt:{helpb xturcoint_mp:mp}}Moon-Perron (2004) t*_a and t*_b with dynamic common factors{p_end}
{synopt:{helpb xturcoint_panic:panic}}Bai-Ng (2010) Pa, Pb, PMSB; Westerlund-Larsson (2009) Ze, Ze+; Reese-Westerlund (2016) PANICCA{p_end}
{syntab:Cross-sectional dependence (pre-test)}
{synopt:{helpb xturcoint_cd:cd}}Breusch-Pagan (1980) LM, Pesaran-Ullah-Yamagata (2008) LMadj, Pesaran (2004, 2021) CDlm and CD, Baltagi-Feng-Kao (2012) CDlm+{p_end}
{syntab:Panel cointegration}
{synopt:{helpb xturcoint_cusum:cusum}}Westerlund (2005) panel CUSUM test, H0: cointegration{p_end}
{synopt:{helpb xturcoint_adfmin:adfmin}}Westerlund (2006) panel Z and ADF tests with a level break, H0: no cointegration{p_end}
{synoptline}
{p 4 6 2}Aliases: {cmd:panicca} = {cmd:panic, method(panicca)}; {cmd:csd} = {cmd:cd}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xturcoint} collects, under one command, the panel unit-root and panel cointegration tests of the GAUSS
libraries {it:tspdlib} 3.0.0 (Saban Nazlioglu), {it:carrionlib} 1.0.2 (Josep Lluis Carrion-i-Silvestre) and
{it:westerlundlib} (Joakim Westerlund) that were {it:not yet available in Stata}. Every subcommand is a line-by-line port
of the corresponding GAUSS procedure, written in Mata, and reproduces the GAUSS results to at least 8 decimals
(see {help xturcoint##validation:Validation}). The tests of these libraries that already existed in Stata were not
duplicated; they are listed, with links, in the {help xturcoint##gauss:GAUSS map} below.

{pstd}
All subcommands read the panel structure from {helpb xtset}, require a balanced panel, return everything in {cmd:r()}
and print journal-style tables with significance stars.


{marker guide}{...}
{title:Which test to use}

{phang}1. Test for cross-sectional dependence first: {helpb xturcoint_cd:xturcoint cd}.{p_end}
{phang}2. Without cross-sectional dependence: first-generation tests ({helpb xtunitroot}) or, for short panels, {helpb xturcoint_fixedt:xturcoint fixedt};
with structural breaks, {helpb xturcoint_lm:xturcoint lm}.{p_end}
{phang}3. With cross-sectional dependence (common factors): {helpb xturcoint_panic:xturcoint panic} or {helpb xturcoint_mp:xturcoint mp}.{p_end}
{phang}4. Cointegration: {helpb xturcoint_cusum:xturcoint cusum} (null of cointegration) and {helpb xturcoint_adfmin:xturcoint adfmin}
(null of no cointegration, level break). Use both for a confirmatory analysis.{p_end}


{marker gauss}{...}
{title:GAUSS map: every panel test of the three GAUSS libraries and its Stata command}

{pstd}
The table lists every panel unit-root, stationarity, cross-sectional dependence, causality and cointegration
procedure of the three GAUSS libraries and where to find it in Stata. Commands marked {bf:(new)} are in {cmd:xturcoint};
the others already existed and are not duplicated. Click a command to open its help (if it is installed) or the
install link.

{p2colset 4 32 34 2}{...}
{p2col:{bf:GAUSS procedure (library)}}{bf:Stata command}{p_end}
{p2line}
{p2col:{it:Panel unit root / stationarity}}{p_end}
{p2col:PDLM, PDLMlevel, PDLMtrend (tspdlib)}{helpb xturcoint_lm:xturcoint lm} {bf:(new)}; the two-break trend case also in {helpb xtbreaklm} [{stata ssc install xtpdroot:xtpdroot}]{p_end}
{p2col:fixed_T_panel (tspdlib)}{helpb xturcoint_fixedt:xturcoint fixedt} {bf:(new)}{p_end}
{p2col:pu_mp04 (carrionlib)}{helpb xturcoint_mp:xturcoint mp} {bf:(new)}{p_end}
{p2col:BNG_PANICnew, JWL_PANICadj, JWR_PANICCA (tspdlib)}{helpb xturcoint_panic:xturcoint panic} {bf:(new)}{p_end}
{p2col:BNG_PANIC, Bai-Ng 2004 (tspdlib)}{helpb xtpanic} [{stata ssc install xtflexur:xtflexur}]{p_end}
{p2col:cips, cadf, Pesaran 2007 (tspdlib)}{helpb xtcips} [{stata ssc install xtcips:xtcips}], {helpb pescadf} [{stata ssc install pescadf:pescadf}]; Westerlund-Hosseinkouchack 2016 version: {helpb xtcipsm} [{stata ssc install xtpdlib:xtpdlib}]{p_end}
{p2col:pd_kpss, pankpss, Carrion et al. 2005 (tspdlib, carrionlib)}{helpb xtpkpss} [{stata ssc install xtpunitcoint:xtpunitcoint}]{p_end}
{p2col:PDfzk, Nazlioglu-Karul 2017 (tspdlib)}{helpb xtfpss} [{stata ssc install xtpdlib:xtpdlib}]{p_end}
{p2col:pd_stationary, Hadri 2000, Yin-Wu 2001, Nazlioglu et al. 2021 (tspdlib)}{helpb xtpstat} [{stata ssc install xtpdroot:xtpdroot}]; Hadri also {helpb xtunitroot} {cmd:hadri}{p_end}
{p2col:panelbreak, Bai-Carrion-i-Silvestre 2009 PANIC with breaks (carrionlib)}{helpb xtpanicsb} [{stata ssc install xtpdroot:xtpdroot}]{p_end}
{p2col:{it:Cross-sectional dependence}}{p_end}
{p2col:pd_getCDError (tspdlib)}{helpb xturcoint_cd:xturcoint cd} {bf:(new)}; related: {helpb xtcd2} [{stata ssc install xtcd2:xtcd2}], {helpb xtcsd} [{stata ssc install xtcsd:xtcsd}], {helpb xttest2}{p_end}
{p2col:{it:Panel causality}}{p_end}
{p2col:Panel_Fisher, Emirmahmutoglu-Kose 2011 (tspdlib)}{helpb xtpgc} [{stata ssc install xtpdlib:xtpdlib}]{p_end}
{p2col:Panel_SURwald, Konya 2006 (tspdlib)}{helpb xtpgc} [{stata ssc install xtpdlib:xtpdlib}]{p_end}
{p2col:Panel_Zhnc, Dumitrescu-Hurlin 2012 (tspdlib)}{helpb xtgcause} [{stata ssc install xtgcause:xtgcause}]{p_end}
{p2col:{it:Panel cointegration}}{p_end}
{p2col:cusum_panel, Westerlund 2005 (westerlundlib)}{helpb xturcoint_cusum:xturcoint cusum} {bf:(new)}{p_end}
{p2col:adfmin_west, Westerlund 2006 (westerlundlib)}{helpb xturcoint_adfmin:xturcoint adfmin} {bf:(new)}{p_end}
{p2col:brei_panel, Westerlund 2005 variance ratio (westerlundlib)}{helpb xtcointtest} {cmd:westerlund} (official Stata; verified identical to GAUSS){p_end}
{p2col:ecm_panel, Westerlund 2007 ECM tests (westerlundlib)}{helpb xtwest} [{stata ssc install xtwest:xtwest}]{p_end}
{p2col:boot_panel, Westerlund-Edgerton 2007 bootstrap LM (westerlundlib)}{helpb xtpcointegboot} [{stata ssc install xtpunitcoint:xtpunitcoint}]{p_end}
{p2col:gdh_panel, Westerlund 2008 Durbin-Hausman (westerlundlib)}{helpb xtdhcoint} [{stata ssc install xtdhcoint:xtdhcoint}]{p_end}
{p2col:lmbreak_panel, Westerlund 2006 LM with multiple breaks (westerlundlib)}{helpb xtlmbreak} [{stata ssc install xtlmbreak:xtlmbreak}]{p_end}
{p2col:ilt_br/ilt_fact, pd_coint_wedgerton, Westerlund-Edgerton 2008 (westerlundlib, tspdlib)}{helpb xtpcointegwe} [{stata ssc install xtpunitcoint:xtpunitcoint}]{p_end}
{p2col:factcoint, ped_t7, Banerjee-Carrion-i-Silvestre 2015 (carrionlib)}{helpb xtbreakcoint} [{stata ssc install xtbreakcoint:xtbreakcoint}]{p_end}
{p2col:CADFcoin_multiple, Banerjee-Carrion-i-Silvestre (carrionlib)}{helpb xtcadfcoint} [{stata ssc install xtcadfcoint:xtcadfcoint}]{p_end}
{p2col:ped_t7 without breaks, Pedroni 1999 (carrionlib)}{helpb xtcointtest} {cmd:pedroni} (official), {helpb xtpedroni} [{stata ssc install xtpedroni:xtpedroni}]{p_end}
{p2line}
{p2colreset}{...}

{pstd}{bf:Not ported.} {cmd:lm_break}/{cmd:ilt_lmcoint} (westerlundlib lmcoint.src, Westerlund-Edgerton 2007, a
single-equation test) does not run in GAUSS as distributed: {cmd:campbell()} builds a regressor matrix whose blocks have
different numbers of rows (GAUSS error G0047), and the file is not listed in the library's package.json. {cmd:ll.src}
(Westerlund 2005, panel DOLS/DSUR) and {cmd:baikao.src} (Westerlund 2007, bias-adjusted estimation under cross-sectional
dependence) are estimators, not tests.


{marker validation}{...}
{title:Validation against GAUSS}

{pstd}
Every subcommand was run on the example data sets shipped with the GAUSS libraries ({it:pd_full.csv} of tspdlib,
{it:gdp.dat} of carrionlib, {it:panelcoint.dat} of westerlundlib) and compared with GAUSS 26.1: 71 statistics across all
options agree to 8-10 decimals (break dates and selected lags agree exactly). Where a GAUSS procedure depends on
global symbols (Westerlund's {cmd:cusum_panel}, Nazlioglu's {cmd:fixed_T_panel}), the values are passed explicitly.


{marker formulas}{...}
{title:GAUSS formulas and paper formulas}

{pstd}
{cmd:xturcoint} follows the GAUSS code by default, so that its results are identical to GAUSS. In the few places where
the GAUSS code departs from the formula published in the paper, the paper's formula is available with option
{cmd:paper}:

{p2colset 6 22 24 2}{...}
{p2col:{bf:subcommand}}{bf:GAUSS (default)  versus  paper (option {cmd:paper})}{p_end}
{p2line}
{p2col:{helpb xturcoint_cd:cd}}CD scaled by T (GAUSS) versus sqrt(T) (Pesaran 2004, 2021); the paper value equals {helpb xtcd2}{p_end}
{p2col:{helpb xturcoint_panic:panic}}phi^4 = (mean omega_i^2)^2 and Pb without square root (GAUSS) versus phi^4 = mean omega_i^4 and Pb as in Bai and Ng (2010); bn2010 and panicca{p_end}
{p2col:{helpb xturcoint_lm:lm}}trend-break model: lag of the last candidate break (GAUSS) versus lag at the minimizing break (Lee and Tieslau 2019){p_end}
{p2col:{helpb xturcoint_adfmin:adfmin}}exception: the default uses all regressors (paper), because GAUSS uses only the first one; option {cmd:gaussfirstx} reproduces GAUSS{p_end}
{p2line}
{p2colreset}{...}

{pstd}
The other subcommands ({helpb xturcoint_fixedt:fixedt}, {helpb xturcoint_mp:mp}, {helpb xturcoint_cusum:cusum}) agree with
their papers and have no {cmd:paper} option. The corrected Bai-Ng (2010) formulas were checked against the Stata code of
Reese and Westerlund (2016).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xturcoint}{p_end}
{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xturcoint cd lnrxrate}{p_end}
{phang2}{cmd:. xturcoint panic lnrxrate, method(bn2010)}{p_end}
{phang2}{cmd:. xturcoint mp lnrxrate, factors(1)}{p_end}
{phang2}{cmd:. xturcoint lm lnrxrate, nbreak(1)}{p_end}
{phang2}{cmd:. webuse xtcoint, clear}{p_end}
{phang2}{cmd:. xturcoint cusum productivity rddomestic rdforeign}{p_end}
{phang2}{cmd:. xturcoint adfmin productivity rddomestic}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
The GAUSS libraries are by Saban Nazlioglu (tspdlib), Josep Lluis Carrion-i-Silvestre (carrionlib) and Joakim Westerlund
(westerlundlib), distributed by Aptech Systems for non-commercial use. Please cite the original papers listed on each help page.
{p_end}
