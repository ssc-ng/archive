{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol select" "help cointvol_select"}{...}
{vieweralsosee "cointvol adaptive" "help cointvol_adaptive"}{...}
{vieweralsosee "cointvol restrict" "help cointvol_restrict"}{...}
{vieweralsosee "cointvol vecmgarch" "help cointvol_vecmgarch"}{...}
{vieweralsosee "cointvol garchrank" "help cointvol_garchrank"}{...}
{vieweralsosee "cointvol resid" "help cointvol_resid"}{...}
{vieweralsosee "cointvol ecm" "help cointvol_ecm"}{...}
{vieweralsosee "cointvol nullcoint" "help cointvol_nullcoint"}{...}
{vieweralsosee "cointvol stoch" "help cointvol_stoch"}{...}
{vieweralsosee "cointvol hetcoint" "help cointvol_hetcoint"}{...}
{vieweralsosee "cointvol diag" "help cointvol_diag"}{...}
{vieweralsosee "cointvol simulate" "help cointvol_simulate"}{...}
{vieweralsosee "cointvol table" "help cointvol_table"}{...}
{vieweralsosee "cointvol graph" "help cointvol_graph"}{...}
{viewerjumpto "Description" "cointvol##description"}{...}
{viewerjumpto "Method-selection guide" "cointvol##guide"}{...}
{viewerjumpto "Workflow" "cointvol##workflow"}{...}
{viewerjumpto "Citation" "cointvol##citation"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:cointvol} {hline 2}}Cointegration under volatility and heteroskedasticity{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:cointvol} {it:subcommand} ... [{cmd:,} {it:options}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol} collects in one package the econometric methods for
cointegration when the innovations are conditionally heteroskedastic
(ARCH/GARCH), have nonstationary volatility (variance breaks, trending or
stochastic volatility), or are heteroskedastic in other ways. The methods are
implemented from the original papers. Each help file maps every computational
step to the equation of its source and labels each option "Original" or
"Extended implementation".

{pstd}
The package is organised around the questions an applied researcher asks.

{p2colset 5 30 32 2}{...}
{p2col:{bf:Question}}{bf:Subcommand}{p_end}
{p2line}
{p2col:How many cointegrating relations?}{helpb cointvol_rank:rank} (Johansen with
wild/i.i.d. bootstrap), {helpb cointvol_adaptive:adaptive} (adaptive LR),
{helpb cointvol_garchrank:garchrank} (rank tests under GARCH errors){p_end}
{p2col:Which lag order and rank?}{helpb cointvol_select:select} (standard and
adaptive information criteria){p_end}
{p2col:Restrictions on alpha, beta?}{helpb cointvol_restrict:restrict} (PLR,
sandwich Wald, wild bootstrap, Bartlett){p_end}
{p2col:Joint VECM + volatility model?}{helpb cointvol_vecmgarch:vecmgarch}
(BEKK, GARCH-X, CCC, ECCC, ARCH, triangular GARCH){p_end}
{p2col:Single-equation tests of no cointegration?}{helpb cointvol_resid:resid}
(EG, FKM, Lee-Tse, TAR/MTAR, KSS, break tests), {helpb cointvol_ecm:ecm}
(ECM t test, wild bootstrap){p_end}
{p2col:Test the null of cointegration?}{helpb cointvol_nullcoint:nullcoint}
(KPSS/Shin, DNLS, fixed-regressor wild bootstrap){p_end}
{p2col:Stochastic / heteroskedastic cointegration?}{helpb cointvol_stoch:stoch},
{helpb cointvol_hetcoint:hetcoint}{p_end}
{p2col:Diagnostics on a VECM?}{helpb cointvol_diag:diag} (ARCH-LM, multivariate
ARCH, autocorrelation LM with HCCME, variance profile, roots){p_end}
{p2col:Monte Carlo designs of the literature?}{helpb cointvol_simulate:simulate}{p_end}
{p2col:Tables and graphs for a paper?}{helpb cointvol_table:table} (LaTeX, HTML,
Excel, Word, CSV), {helpb cointvol_graph:graph} (bootstrap distributions, IC
surface, ECT, volatility, correlations, variance profiles){p_end}
{p2line}
{p2colreset}{...}


{marker guide}{...}
{title:Method-selection guide}

{pstd}
{bf:Case A. No evidence of volatility problems.} If {cmd:cointvol diag} finds
no ARCH effects and flat variance profiles, the standard Johansen procedure is
adequate ({helpb vecrank}, or {cmd:cointvol rank, method(asy)}). The bootstrap
versions remain valid and cost only computing time.

{pstd}
{bf:Case B. Conditional heteroskedasticity (ARCH/GARCH).} The Johansen limits
are unchanged, but finite-sample size can be poor (Lee and Tse 1996;
Cavaliere, Rahbek and Taylor 2010b). Use {cmd:cointvol rank, method(wild)}; the
i.i.d. bootstrap is also valid here. {cmd:cointvol garchrank} uses the GARCH
structure itself to gain power (Sin, Mi and Ling 2024).

{pstd}
{bf:Case C. Joint estimation of the long run and the volatility.} Use
{cmd:cointvol vecmgarch}; it estimates the cointegrating vectors efficiently
(Li, Ling and Wong 2001; Seo 2007) and lets the disequilibrium enter the
variance (GARCH-X, Lee 1994). Inference on beta should use the robust
covariance ({cmd:vce(robust)}).

{pstd}
{bf:Case D. Nonstationary (unconditional) volatility: breaks, trends.} The
Johansen limits change and the standard tests over-reject (Cavaliere, Rahbek
and Taylor 2010a). Use {cmd:cointvol rank, method(wild)} or the more powerful
adaptive test {cmd:cointvol adaptive} (Boswijk and Zu 2022); choose lags and
rank with {cmd:cointvol select, adaptive}. Do not use the i.i.d. bootstrap.
Test restrictions on alpha and beta with {cmd:cointvol restrict, method(wild)}.

{pstd}
{bf:Case E. Stochastic or heteroskedastic cointegration.} When the variance of
the equilibrium error itself grows over time, ordinary cointegration tools do
not apply. Use {cmd:cointvol stoch} (Harris, McCabe and Leybourne 2002; McCabe,
Leybourne and Harris 2006) or {cmd:cointvol hetcoint} (Hansen 1992).

{pstd}
{bf:Case F. Nonlinear adjustment or a nonlinear long-run relation.} Threshold
or smooth-transition adjustment: {cmd:cointvol resid, test(tar mtar kss)};
breaks in the relation: {cmd:test(gh hj)}; a nonlinear cointegrating function
under the null of cointegration: {cmd:cointvol nullcoint, model()} with the
DNLS estimator (Choi and Saikkonen 2010; Hanck and Massing 2025). These tests
over-reject under GARCH and variance breaks (Maki 2013), so prefer their
bootstrap versions.

{pstd}
{bf:Case G. Small sample with strongly persistent GARCH.} Asymptotic critical
values are unreliable near integrated GARCH (Franses, Kofman and Moser 1994;
Kurita 2013). Use bootstrap p-values throughout, and the Bartlett correction
for tests on beta ({cmd:cointvol restrict, bartlett}).

{pstd}
{bf:Two-step spread GARCH.} Fitting a univariate GARCH to an estimated
error-correction term ({cmd:cointvol diag, spreadgarch}) is shown only for
comparison; it ignores estimation error in beta and is less efficient than the
joint estimators of Case C.

{pstd}
{cmd:cointvol about} displays the version and citation information.

{pstd}
Subcommands may be abbreviated to their underlined minimum:
{cmd:{ul:ra}nk}, {cmd:{ul:sel}ect}, {cmd:{ul:adapt}ive}, {cmd:{ul:rest}rict},
{cmd:{ul:vecm}garch}, {cmd:{ul:garchr}ank}, {cmd:{ul:resi}d}, {cmd:{ul:ecm}},
{cmd:{ul:null}coint}, {cmd:{ul:stoch}}, {cmd:{ul:het}coint}, {cmd:{ul:diag}},
{cmd:{ul:sim}ulate}.


{marker workflow}{...}
{title:A suggested workflow}

{phang2}1. {cmd:cointvol diag} on a VAR in levels: are the residuals
heteroskedastic, and is the variance profile far from the 45-degree line
(nonstationary volatility)?{p_end}
{phang2}2. {cmd:cointvol select}: choose the lag order and the rank; use the
adaptive criteria if the volatility is time-varying.{p_end}
{phang2}3. {cmd:cointvol rank, method(wild)} (and {cmd:cointvol adaptive}):
bootstrap rank tests robust to the volatility pattern.{p_end}
{phang2}4. {cmd:cointvol restrict}: tests on beta (e.g. a unit spread) and on
alpha (weak exogeneity) with the wild bootstrap or sandwich Wald test.{p_end}
{phang2}5. {cmd:cointvol vecmgarch}: joint efficient estimation of the
cointegrated system and its conditional covariance.{p_end}


{title:Technical notes}

{pstd}
The package needs Stata 14 or newer. The computations are written in Mata.
Every bootstrap and simulation is reproducible through the {cmd:seed()}
option. The certification scripts are in the {cmd:tests/} folder of the
distribution.


{marker citation}{...}
{title:Citation}

{pstd}
Please cite the original papers of the methods you use (see each subcommand's
References) and the package:

{phang}
Roudane, M. 2026. cointvol: Stata module for cointegration under volatility and
heteroskedasticity. Version 0.1.0.
{browse "https://github.com/merwanroudane":github.com/merwanroudane}.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
