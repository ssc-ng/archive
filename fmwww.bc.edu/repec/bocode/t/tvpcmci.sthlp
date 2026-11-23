{smcl}
{* *! version 1.0.0  21nov2026}{...}
{vieweralsosee "tvpc" "help tvpc"}{...}
{vieweralsosee "tvpc methods" "help tvpc_methods"}{...}
{vieweralsosee "tvpcsens" "help tvpcsens"}{...}
{vieweralsosee "tvpcgraph" "help tvpcgraph"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{bf:tvpcmci} {hline 2}}PCMCI causal discovery with partial-correlation tests
(benchmark of Aung et al. 2026, Sec. 5){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:tvpcmci} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt taumax(#)}}maximum lag (in steps); default 4{p_end}
{synopt:{opt taumin(#)}}minimum lag; 0 (default) also tests contemporaneous links{p_end}
{synopt:{opt lags:tep(#)}}periods per lag step; default 1{p_end}
{synopt:{opt a:lpha(#)}}MCI significance level; default 0.05{p_end}
{synopt:{opt pca:lpha(#)}}PC1 significance level; default 0.2 (tigramite default){p_end}
{synopt:{opt maxc:onds(#)}}largest PC1 condition dimension; default unlimited{p_end}
{synopt:{opt truth(matname)}}score against a known structure (see {helpb tvpc}){p_end}
{synopt:{opt notab:le} {opt noedge:s} {opt nolag:map} {opt nosum:mary}}reporting{p_end}
{synopt:{opt gr:aph(graphopts)}}graphs via {helpb tvpcgraph}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:tvpcmci} implements PCMCI (Runge et al. 2019), the benchmark against which Aung
et al. (2026) compare TV-PC in Table 1. It reproduces {cmd:tigramite}'s
{cmd:run_pcmci()} with the {cmd:ParCorr} test. The algorithm has two stages.

{phang2}{it:PC1.} For every X_j(t), the lagged candidates X_i(t-tau),
tau = max(1, taumin) to taumax, are pruned by conditioning on the strongest current
parents. One condition set is used per dimension. Parents are re-sorted by their
smallest |partial r|, and a candidate is dropped when p > pcalpha.{p_end}
{phang2}{it:MCI.} Each link is tested as X_i(t-tau) {c 124}{c 124} X_j(t) |
P(X_j(t)) \ X_i(t-tau), P(X_i(t-tau)), where the parents of X_i are shifted by tau.
A link exists if p {ul:<} alpha. A contemporaneous pair significant in both directions
is undirected; one significant in only one direction is directed.{p_end}

{pstd}
ParCorr standardises the data within each test, takes the OLS residuals on Z,
computes their Pearson r, and forms t = r sqrt(df/(1-r{c 94}2)) with
df = T' - 2 - |Z| and a two-sided p-value. All tests use the same
T' = T - 2 taumax rows. The p-values agree with tigramite to within 1e-7 (see
{help tvpc_methods##validation:validation}).

{pstd}
Results are stored on the same node layout as {cmd:tvpc}, so {helpb tvpcgraph} and
{opt truth()} work identically.


{title:Examples}

{phang2}{cmd:. use tvpc_a1, clear}{p_end}
{phang2}{cmd:. local tr : char _dta[tvpc_truth]}{p_end}
{phang2}{cmd:. matrix T = (`tr')}{p_end}
{phang2}{cmd:. tvpcmci X1-X8, taumax(4) alpha(0.001) truth(T)}{p_end}
{phang2}{cmd:. tvpcgraph, grid}{p_end}


{title:Stored results}

{pstd}
The scalars and macros are the same as for {helpb tvpc}, plus {cmd:e(pc_alpha)},
{cmd:e(tau_min)} and {cmd:e(n_parents)}. The matrices are {cmd:e(G)},
{cmd:e(links)}, {cmd:e(lagmap)} and {cmd:e(degree)}, together with:{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:e(pvalue)}}MCI p-values, rows = cause node (i, tau), columns = effect j{p_end}
{synopt:{cmd:e(val)}}MCI partial correlations, same layout{p_end}
{synopt:{cmd:e(parents)}}PC1 parents: effect cause lag{p_end}


{title:References}

{phang}
Runge, J., P. Nowack, M. Kretschmer, S. Flaxman and D. Sejdinovic. 2019. Detecting
and quantifying causal associations in large nonlinear time series datasets.
{it:Science Advances} 5: eaau4996.
{browse "https://doi.org/10.1126/sciadv.aau4996":doi:10.1126/sciadv.aau4996}.

{phang}
Aung, H. W., Z. Zhu, G. Lee, Y. Guo and J. Li. 2026. {it:Computational Economics}.
{browse "https://doi.org/10.1007/s10614-026-11411-x":doi:10.1007/s10614-026-11411-x}.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
