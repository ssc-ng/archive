{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "tsurcoint fkss" "help tsurcoint_fkss"}{...}
{vieweralsosee "tsurcoint wkss" "help tsurcoint_wkss"}{...}
{vieweralsosee "tsurcoint fwkss" "help tsurcoint_fwkss"}{...}
{vieweralsosee "tsurcoint fwadf" "help tsurcoint_fwadf"}{...}
{vieweralsosee "tsurcoint qkss" "help tsurcoint_qkss"}{...}
{vieweralsosee "tsurcoint qfkss" "help tsurcoint_qfkss"}{...}
{vieweralsosee "tsurcoint qks" "help tsurcoint_qks"}{...}
{vieweralsosee "tsurcoint glsbreak" "help tsurcoint_glsbreak"}{...}
{vieweralsosee "tsurcoint shin" "help tsurcoint_shin"}{...}
{vieweralsosee "tsurcoint cissanso" "help tsurcoint_cissanso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xturcoint (panel tests)" "help xturcoint"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "tsurcoint##syntax"}{...}
{viewerjumpto "Description" "tsurcoint##description"}{...}
{viewerjumpto "GAUSS map" "tsurcoint##gauss"}{...}
{viewerjumpto "GAUSS vs paper formulas" "tsurcoint##formulas"}{...}
{viewerjumpto "Validation" "tsurcoint##validation"}{...}
{viewerjumpto "Examples" "tsurcoint##examples"}{...}
{viewerjumpto "Author" "tsurcoint##author"}{...}
{p 4 4 2}{bf:tsurcoint} {c |} {bf:overview} {c |} {help tsurcoint_fkss:fkss} {c |} {help tsurcoint_wkss:wkss} {c |} {help tsurcoint_fwkss:fwkss} {c |} {help tsurcoint_fwadf:fwadf} {c |} {help tsurcoint_qkss:qkss} {c |} {help tsurcoint_qfkss:qfkss} {c |} {help tsurcoint_qks:qks} {c |} {help tsurcoint_glsbreak:glsbreak} {c |} {help tsurcoint_shin:shin} {c |} {help tsurcoint_cissanso:cissanso} {c |} {help tsurcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:tsurcoint} {hline 2} Time-series unit-root and cointegration tests ported from the GAUSS libraries {it:tspdlib} and
{it:carrionlib}, with results identical to GAUSS


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsurcoint} {it:subcommand} {it:varlist} {ifin} [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:tsurcoint} {space 3}(without arguments: lists all tests with clickable links)

{synoptset 20}{...}
{p2coldent:{it:subcommand}}test (click for the full help page){p_end}
{synoptline}
{syntab:Nonlinear and smooth-break unit root}
{synopt:{helpb tsurcoint_fkss:fkss}}Fourier KSS / Fourier ADF (Christopoulos and Leon-Ledesma 2010){p_end}
{synopt:{helpb tsurcoint_wkss:wkss}}wavelet KSS (Aydin 2020){p_end}
{synopt:{helpb tsurcoint_fwkss:fwkss}}Fourier wavelet KSS (Aydin 2020){p_end}
{synopt:{helpb tsurcoint_fwadf:fwadf}}Fourier wavelet ADF (Aydin and Pata 2020){p_end}
{syntab:Quantile unit root}
{synopt:{helpb tsurcoint_qkss:qkss}}quantile KSS (Li and Park 2018){p_end}
{synopt:{helpb tsurcoint_qfkss:qfkss}}quantile Fourier KSS (Bahmani-Oskooee, Chang, Niroomand and Ranjbar 2020){p_end}
{synopt:{helpb tsurcoint_qks:qks}}quantile Kolmogorov-Smirnov tests for the QADF, QR Fourier ADF, QR KSS and QR Fourier KSS statistics{p_end}
{syntab:Structural-break unit root}
{synopt:{helpb tsurcoint_glsbreak:glsbreak}}ADF-GLS, PT, MZa, MZt, MSB, MPT with 1 or 2 breaks (Perron-Rodriguez 2003; Carrion-i-Silvestre, Kim and Perron 2009){p_end}
{syntab:Cointegration (H0: cointegration)}
{synopt:{helpb tsurcoint_shin:shin}}Shin (1994), OLS and DOLS{p_end}
{synopt:{helpb tsurcoint_cissanso:cissanso}}Carrion-i-Silvestre and Sanso (2006), one structural break{p_end}
{synoptline}
{p 4 6 2}Alias: {cmd:fadf} = {cmd:fkss, adf}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsurcoint} collects, under one command, the time-series tests of the GAUSS libraries {it:tspdlib} 3.0.0 (Saban
Nazlioglu) and {it:carrionlib} 1.0.2 (Josep Lluis Carrion-i-Silvestre) that were {it:not yet available in Stata}, plus the
GLS break models that were only partly available. Every subcommand is a line-by-line port of the GAUSS procedure, written in
Mata, including the GAUSS interior-point quantile-regression solver, and reproduces the GAUSS results to 10 decimals. The
other tests of these libraries already existed in Stata and are not duplicated; they are listed in the
{help tsurcoint##gauss:GAUSS map}. The panel tests of the same libraries are in {helpb xturcoint}.


{marker gauss}{...}
{title:GAUSS map: every time-series test of tspdlib and carrionlib and its Stata command}

{pstd}
Commands marked {bf:(new)} are in {cmd:tsurcoint}; the others already existed and are not duplicated. Click a command to
open its help (if installed) or the install link.

{p2colset 4 34 36 2}{...}
{p2col:{bf:GAUSS procedure}}{bf:Stata command}{p_end}
{p2line}
{p2col:{it:Unit root, no break}}{p_end}
{p2col:ADF}{helpb dfuller} (official){p_end}
{p2col:PP}{helpb pperron} (official){p_end}
{p2col:LMkpss (KPSS)}{helpb kpss} [{stata ssc install kpss:kpss}]{p_end}
{p2col:DFGLS, ERS PT}{helpb dfgls} (official), {helpb ersur} [{stata ssc install ersur:ersur}]{p_end}
{p2col:MGLS (Ng-Perron MZa, MZt, MSB, MPT)}{helpb ckptest} {cmd:model(const|trend)} [{stata ssc install ckptest:ckptest}]{p_end}
{p2col:LM (Schmidt-Phillips 1992)}{helpb lsmlm} [{stata ssc install lsmlm:lsmlm}]{p_end}
{p2col:KSS (Kapetanios-Shin-Snell 2003)}{helpb kssur} [{stata ssc install kssur:kssur}]{p_end}
{p2col:{it:Unit root with sharp breaks}}{p_end}
{p2col:ADF_1break (Zivot-Andrews 1992)}{helpb zandrews} [{stata ssc install zandrews:zandrews}]{p_end}
{p2col:ADF_2breaks (Narayan-Popp 2010)}{helpb narayanp} [{stata ssc install narayanp:narayanp}], {helpb tsadvroot} {cmd:npadf}{p_end}
{p2col:LM_1break, LM_2breaks (Lee-Strazicich)}{helpb lsmlm} [{stata ssc install lsmlm:lsmlm}], {helpb leestra} [{stata ssc install leestra:leestra}]{p_end}
{p2col:KPSS_1break, KPSS_2breaks}{helpb kpssbr} [{stata ssc install kpssbr:kpssbr}]{p_end}
{p2col:gls_1break, GLS_2breaks}{helpb tsurcoint_glsbreak:tsurcoint glsbreak} {bf:(new)}{p_end}
{p2col:sbur_gls / msbur (CKP 2009, up to 5 breaks)}{helpb ckptest} [{stata ssc install ckptest:ckptest}], {helpb tsadvroot} {cmd:cisur} [{stata ssc install tsadvroot:tsadvroot}]{p_end}
{p2col:RALS_ADF, RALS_LM, RALSLM_breaks}{helpb ralsadf}, {helpb ralslm}, {helpb ralslmb} [{stata ssc install rals:rals}]{p_end}
{p2col:{it:Unit root with smooth (Fourier) breaks}}{p_end}
{p2col:Fourier_ADF, Fourier_LM, Fourier_GLS, Fourier_KPSS}{helpb fourierdf}, {helpb fourierlm}, {helpb fouriergls}, {helpb fourierkpss} [{stata ssc install fourierur:fourierur}]{p_end}
{p2col:Fourier_KSS}{helpb tsurcoint_fkss:tsurcoint fkss} {bf:(new)}{p_end}
{p2col:WKSS, Fourier_WKSS, fourier_wadf}{helpb tsurcoint_wkss:wkss}, {helpb tsurcoint_fwkss:fwkss}, {helpb tsurcoint_fwadf:fwadf} {bf:(new)}{p_end}
{p2col:{it:Quantile unit root}}{p_end}
{p2col:QRADF (Koenker-Xiao 2004)}{helpb qadf}, {helpb qadf_process} [{stata ssc install qadf:qadf}]{p_end}
{p2col:QR_Fourier_ADF (Li-Zheng 2018)}{helpb tsadvroot} {cmd:fqadf} [{stata ssc install tsadvroot:tsadvroot}]{p_end}
{p2col:QR_KSS, QR_Fourier_KSS, qks_tests}{helpb tsurcoint_qkss:qkss}, {helpb tsurcoint_qfkss:qfkss}, {helpb tsurcoint_qks:qks} {bf:(new)}{p_end}
{p2col:{it:Variance breaks}}{p_end}
{p2col:sbvar_icss / icss (Inclan-Tiao; Sanso et al.)}{helpb icss} [{stata ssc install flexur:flexur}]{p_end}
{p2col:{it:Cointegration}}{p_end}
{p2col:coint_egranger (Engle-Granger)}{helpb egranger} [{stata ssc install egranger:egranger}]{p_end}
{p2col:coint_pouliaris (Phillips-Ouliaris)}{helpb pocoint} [{stata ssc install pocoint:pocoint}]{p_end}
{p2col:coint_ghansen (Gregory-Hansen)}{helpb ghansen} [{stata ssc install ghansen:ghansen}]{p_end}
{p2col:coint_hatemiJ (Hatemi-J two breaks)}{helpb hatemicoint} [{stata ssc install hatemicoint:hatemicoint}]{p_end}
{p2col:coint_maki (Maki multiple breaks)}{helpb maki} [{stata ssc install maki:maki}], {helpb makicoint} [{stata ssc install makicoint:makicoint}]{p_end}
{p2col:coint_tsongetal (Tsong et al. Fourier)}{helpb fcoint} [{stata ssc install fcoint:fcoint}]{p_end}
{p2col:coint_shin (Shin 1994)}{helpb tsurcoint_shin:tsurcoint shin} {bf:(new)}{p_end}
{p2col:coint_cissanso, coinkpss (CiS-Sanso 2006)}{helpb tsurcoint_cissanso:tsurcoint cissanso} {bf:(new)}{p_end}
{p2col:{it:Causality}}{p_end}
{p2col:granger (Granger, Toda-Yamamoto, Fourier Granger/TY, single and cumulative)}{helpb caustests} [{stata ssc install caustests:caustests}], {helpb vargranger} (official){p_end}
{p2col:asymCause (Hatemi-J 2012 asymmetric)}{helpb asycaus} [{stata ssc install asycaus:asycaus}]{p_end}
{p2line}
{p2colreset}{...}

{pstd}{bf:Not ported.} {cmd:coinkpss_factor} (carrionlib) needs externally estimated common factors; {cmd:rsperron} and
{cmd:code09} are helper routines (Perron 1989 response surfaces, MSB p-values) used by other procedures.


{marker formulas}{...}
{title:GAUSS formulas and paper formulas}

{pstd}
{cmd:tsurcoint} follows the GAUSS code by default, so that its results are identical to GAUSS. Where the GAUSS code departs
from the published formula, the paper's formula is available with option {cmd:paper}:

{p2colset 6 22 24 2}{...}
{p2col:{bf:subcommand}}{bf:GAUSS (default)  versus  paper (option {cmd:paper})}{p_end}
{p2line}
{p2col:{helpb tsurcoint_glsbreak:glsbreak}}s2_AR = s2_ek/(1 - b1 - b2), lag of the last candidate date versus Ng-Perron s2_AR = s2_ek/(1 - sum of lag coefficients)^2 at the selected date{p_end}
{p2col:{helpb tsurcoint_shin:shin}, {helpb tsurcoint_cissanso:cissanso}}DOLS statistic divided by the full T^2 versus by the DOLS sample size{p_end}
{p2col:{helpb tsurcoint_fwadf:fwadf}}AIC/BIC penalty uses the Fourier frequency versus the number of regressors{p_end}
{p2line}
{p2colreset}{...}

{pstd}
Two exceptions where the default follows the paper because the GAUSS result is not usable:{p_end}
{phang2}{helpb tsurcoint_wkss:wkss}: GAUSS runs the KSS regression on the series without the wavelet transform (its value equals
the ordinary KSS test) and fails for the trend model; option {cmd:gauss} reproduces GAUSS.{p_end}
{phang2}bootstrap critical values of {helpb tsurcoint_fkss:fkss} and {helpb tsurcoint_qfkss:qfkss}: GAUSS reports the 99th, 95th
and 90th percentiles of a left-tailed statistic; {cmd:tsurcoint} reports the 1st, 5th and 10th.{p_end}


{marker validation}{...}
{title:Validation against GAUSS}

{pstd}
Every subcommand was run on the example data of tspdlib ({it:ts_examples.csv}, {it:ts_coint.csv}) and compared with GAUSS
26.1 for several option combinations: all statistics, critical values, selected lags, Fourier frequencies and break dates
agree to 10 decimals. The quantile tests reach this agreement because the GAUSS interior-point solver of {cmd:quantileFit} is
reproduced; an exact simplex solver ({helpb qreg}) gives differences of up to 1e-3 in the statistics and larger
differences in the critical values.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. tsurcoint}{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsurcoint fkss ln_inv, simulate(5000) seed(1)}{p_end}
{phang2}{cmd:. tsurcoint qkss ln_inv, tau(0.1(0.2)0.9) lags(4)}{p_end}
{phang2}{cmd:. tsurcoint qks ln_inv, testtype(kss) lags(2)}{p_end}
{phang2}{cmd:. tsurcoint glsbreak ln_inv, model(both)}{p_end}
{phang2}{cmd:. tsurcoint shin ln_consump ln_inc, lrv(spcqs)}{p_end}
{phang2}{cmd:. tsurcoint cissanso ln_consump ln_inc, model(an) lrv(bartlett)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
The GAUSS libraries are by Saban Nazlioglu (tspdlib) and Josep Lluis Carrion-i-Silvestre (carrionlib), distributed by Aptech
Systems for non-commercial use. Please cite the original papers listed on each help page.
{p_end}
