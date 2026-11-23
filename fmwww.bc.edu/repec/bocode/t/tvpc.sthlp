{smcl}
{* *! version 1.0.0  21nov2026}{...}
{vieweralsosee "tvpc methods" "help tvpc_methods"}{...}
{vieweralsosee "tvpcmci" "help tvpcmci"}{...}
{vieweralsosee "tvpcsens" "help tvpcsens"}{...}
{vieweralsosee "tvpcgraph" "help tvpcgraph"}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{viewerjumpto "Syntax" "tvpc##syntax"}{...}
{viewerjumpto "Description" "tvpc##description"}{...}
{viewerjumpto "Options" "tvpc##options"}{...}
{viewerjumpto "Interpreting the output" "tvpc##output"}{...}
{viewerjumpto "Remarks" "tvpc##remarks"}{...}
{viewerjumpto "Examples" "tvpc##examples"}{...}
{viewerjumpto "Stored results" "tvpc##results"}{...}
{viewerjumpto "References" "tvpc##references"}{...}
{viewerjumpto "Author" "tvpc##author"}{...}
{title:Title}

{p2colset 5 13 15 2}{...}
{p2col:{bf:tvpc} {hline 2}}Time-variant Peter-Clark (TV-PC) causal discovery for
multivariate time series{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:tvpc} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}number of lag steps {it:m}; default {cmd:lags(4)}{p_end}
{synopt:{opt lags:tep(#)}}periods per lag step; default {cmd:lagstep(1)}
({cmd:lagstep(3)} = quarterly steps on monthly data, as in the paper){p_end}
{synopt:{opt a:lpha(#)}}significance level of the Fisher z tests; default {cmd:alpha(0.05)}{p_end}
{synopt:{opt var:iant(string)}}{cmd:original} (default, as in the paper) or {cmd:stable} PC{p_end}
{synopt:{opt maxd:epth(#)}}largest conditioning-set size; default unlimited{p_end}
{synopt:{opt nocon:temp}}forbid contemporaneous edges between variables at {it:t}{p_end}
{synopt:{opt nostand:ardize}}skip the standardisation of Eq. (2.2){p_end}

{syntab:Extensions}
{synopt:{opt truth(matname)}}score the graph against a known causal structure{p_end}
{synopt:{opt str:ength}}OLS strength of each causal link (standardised){p_end}
{synopt:{opt rep:s(#)}}moving-block bootstrap replications for edge stability{p_end}
{synopt:{opt block:len(#)}}bootstrap block length; default {it:u}^(1/3){p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}

{syntab:Reporting}
{synopt:{opt notab:le}}suppress all tables{p_end}
{synopt:{opt noedge:s}}suppress Table A (list of links){p_end}
{synopt:{opt nolag:map}}suppress Table B (lag-link matrix){p_end}
{synopt:{opt nosum:mary}}suppress Table C (variable summary){p_end}
{synopt:{opt nolo:g}}suppress the progress log of the skeleton search{p_end}
{synopt:{opt gr:aph(graphopts)}}draw graphs; {it:graphopts} are those of {helpb tvpcgraph},
e.g. {cmd:graph(grid map(cpi))}{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (single time series). {it:varlist} needs at least two
variables. Gaps in the time variable produce missing lags and those rows are dropped.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvpc} implements the time-variant Peter-Clark (TV-PC) algorithm of
Aung, Zhu, Lee, Guo and Li (2026). Each of the {it:n} variables is expanded into
{it:m}+1 nodes {it:X(i,t), X(i,t-1), ..., X(i,t-m)}, and the graph is learnt over
these {it:n}({it:m}+1) nodes. The procedure is the following.

{phang2}1. Standardise every series (Eq. 2.2).{p_end}
{phang2}2. Add the lagged nodes, where lag {it:k} is {it:k} x {cmd:lagstep()} periods
(Fig. 1).{p_end}
{phang2}3. Impose the edge restrictions of Sec. 2.1.1: no self-loops, no edges
between lagged nodes, and no edges from time {it:t} to the past.{p_end}
{phang2}4. Run the PC algorithm. The skeleton is pruned with Fisher's z
conditional-independence tests (Eq. 2.1), removing an edge when p {ul:>} alpha.
Edges are then oriented using the temporal knowledge, v-structures and Meek's
rules R1-R4, and the result is returned as a PDAG (Sec. 2.1.2-2.1.4).{p_end}

{pstd}
The skeleton search, the order in which conditioning sets are enumerated, the
separating sets and the orientation rules reproduce the {it:gCastle} PC
implementation that the authors used, step for step. The estimated graph is
therefore identical to gCastle's. On the TimeGraph A1 benchmark, {cmd:tvpc}
reproduces the TV-PC column of Table 1 of the paper; see {help tvpc_methods}.

{pstd}
The companion commands are:{p_end}
{p2colset 9 22 24 2}{...}
{p2col:{helpb tvpcgraph}}causal maps, time-lag grid, network, heat map{p_end}
{p2col:{helpb tvpcsens}}sensitivity to lags and alpha (Sec. 4.4, Fig. 12, Table 1){p_end}
{p2col:{helpb tvpcmci}}PCMCI benchmark of Sec. 5{p_end}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets the number of lag steps {it:m}. The paper uses {it:m} = 4 and
checks {it:m} = 3 and 5 in Sec. 4.4. The number of conditional-independence tests
grows quickly with {it:n}({it:m}+1).

{phang}
{opt lagstep(#)} sets the number of periods in one lag step. With monthly data and
{cmd:lagstep(3)}, the nodes are {it:t}-3, {it:t}-6, {it:t}-9 and {it:t}-12 months,
which is the quarterly design of the paper. Tables and graphs label lags in steps
({it:t-k}). The matrix row names give the lag in periods ({cmd:L6.cpi}).

{phang}
{opt alpha(#)} is the significance level of the Fisher z tests. Smaller values
give sparser graphs. Table 1 of the paper uses 0.0005 to 0.05.

{phang}
{opt variant(original|stable)}: {cmd:original} updates the adjacency sets while
testing, as gCastle's default PC does and as the paper did. {cmd:stable} is the
order-independent PC-stable of Colombo and Maathuis (2014).

{phang}
{opt maxdepth(#)} caps the size of the conditioning sets |S|. The default
(-1) leaves it unlimited, as in the paper.

{phang}
{opt nocontemp} also forbids edges between the variables at time {it:t}, so that
only lagged causal links remain. This option is an extension; the paper allows
contemporaneous edges.

{phang}
{opt nostandardize} keeps the original units. Fisher's z test depends only on
correlations, so the graph does not change. Only the {opt strength} coefficients
change.

{phang}
{opt truth(matname)} supplies a known causal structure as a {it:K} x 3 matrix
with one row per true link: {it:(cause effect lag)}. {it:cause} and {it:effect} are
the positions of the variables in {it:varlist}, and {it:lag} is in steps
(0 = contemporaneous). Precision, recall, F1, skeleton F1 and the structural Hamming
distance (SHD) are reported, using the gCastle {it:MetricsDAG} conventions of
Table 1.

{phang}
{opt strength} addresses the limitation stated in the paper's conclusion (the
strength of the causal links is not known). Each standardised {it:X(j,t)} is
regressed by OLS on its directed parents in the PDAG, and the coefficients, t
statistics and R-squared are reported. These p-values are computed after model
selection and are only descriptive.

{phang}
{opt reps(#)}, {opt blocklen(#)} and {opt seed(#)} rerun TV-PC on {it:#}
moving-block bootstrap resamples of the rows of the lagged data matrix. The rows
already contain the lags, so the block bootstrap keeps the temporal dependence. The
share of replications that reproduce each link is reported as {it:Stab%} and
stored in {cmd:e(Fdir)} and {cmd:e(Fadj)}. This option is an extension.

{phang}
{opt graph(graphopts)} calls {helpb tvpcgraph} after estimation, e.g.
{cmd:graph(grid network map(cpi hpi))}.


{marker output}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.} Gives the number of usable observations {it:u} (after lags are
formed), {it:n}, {it:m}, the lag step, the number of nodes {it:n}({it:m}+1), the
number of node pairs removed a priori by the restrictions, the number of CI tests
run and the largest conditioning-set size reached.

{pstd}
{bf:Table A (links).} Lists every edge of the PDAG, grouped by the effect variable
at time {it:t}. {cmd:-->} marks a directed edge and {cmd:---} an undirected
contemporaneous edge that the data cannot orient. {it:r(marg)} is the marginal
correlation. {it:|r|min} is the weakest partial correlation over all the
conditioning sets tested. {it:p max} is the largest Fisher z p-value over those
tests; it is below alpha because the edge survived. {it:Stab%} is shown only with
{opt reps()}.

{pstd}
{bf:Table B (lag-link matrix).} This is the tabular summary of the paper's causal
relationship maps (Figs. 3-11). Rows are causes and columns are effects at {it:t}.
A cell such as {cmd:234} means that cause({it:t}-2), cause({it:t}-3) and
cause({it:t}-4) drive effect({it:t}). {cmd:0} denotes a directed contemporaneous
link and {cmd:u} an undirected one. Diagonal cells show autoregressive memory.

{pstd}
{bf:Table C (summary).} Reports in-links and out-links, the number of distinct
driver and driven variables, and the number of own lags for each variable. A
variable with many in-links, such as unemployment or house prices in the paper, is
"impacted by many indicators".

{pstd}
{bf:Table D (accuracy)} appears with {opt truth()}. {bf:Table E (strength)}
appears with {opt strength}.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{it:Assumptions.} TV-PC assumes causal sufficiency (no hidden common causes),
faithfulness, linear-Gaussian dependence (because of the Fisher z test) and a
stable causal structure over the sample. The series should be stationary or
transformed to stationarity. With trending series in levels, spurious correlations
produce spurious links.

{pstd}
{it:Sample size.} Each test uses u - |S| - 3 degrees of freedom. With 240 monthly
observations and 55 nodes, as in the paper, keep {it:m} {ul:<} 5 or use
{opt maxdepth()}.

{pstd}
{it:Computing time.} The number of CI tests depends on how dense the graph stays
while it is pruned. Highly persistent series (near unit roots) correlate every
lag with every other node. The skeleton then stays dense and the number of
conditioning sets explodes combinatorially. The progress log shows the size |S|
reached. If a run is slow, difference or detrend the series, lower {opt alpha()},
or cap {opt maxdepth()} (for example {cmd:maxdepth(3)}).

{pstd}
{it:Lags beyond the window.} A true link whose lag exceeds {it:m} cannot be found,
and its effect can be absorbed by shorter lags. Check robustness with
{helpb tvpcsens}.

{pstd}
{it:Directions.} Lagged edges are always oriented forward in time. Contemporaneous
edges are oriented only through v-structures and Meek's rules, so some may stay
undirected (Sec. 2.1.4).

{pstd}
{it:Reproducibility.} The original variant depends on the order of the variables
in {it:varlist}, exactly as gCastle does. Use {cmd:variant(stable)} for an
order-independent skeleton.


{marker examples}{...}
{title:Examples}

{pstd}Setup (benchmark with known truth){p_end}
{phang2}{cmd:. use tvpc_a1, clear}{p_end}
{phang2}{cmd:. local tr : char _dta[tvpc_truth]}{p_end}
{phang2}{cmd:. matrix T = (`tr')}{p_end}

{pstd}TV-PC with four lags, as in Table 1 of the paper{p_end}
{phang2}{cmd:. tvpc X1-X8, lags(4) alpha(0.0005) truth(T)}{p_end}

{pstd}Paper-style application: monthly data, four quarterly lags{p_end}
{phang2}{cmd:. use tvpc_macro, clear}{p_end}
{phang2}{cmd:. tvpc cpi-hpi, lags(4) lagstep(3) alpha(0.05) strength}{p_end}
{phang2}{cmd:. tvpcgraph, map(cpi) }{p_end}
{phang2}{cmd:. tvpcgraph, all}{p_end}

{pstd}Edge stability{p_end}
{phang2}{cmd:. tvpc cpi-hpi, lags(4) lagstep(3) reps(200) seed(1)}{p_end}

{pstd}A full worked script is in {cmd:tvpc_example.do} ({cmd:net get tvpc}).{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tvpc} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}usable observations {it:u}{p_end}
{synopt:{cmd:e(n_vars)}}number of variables {it:n}{p_end}
{synopt:{cmd:e(lags)}}lag steps {it:m}{p_end}
{synopt:{cmd:e(lagstep)}}periods per lag step{p_end}
{synopt:{cmd:e(alpha)}}significance level{p_end}
{synopt:{cmd:e(nodes)}}{it:n}({it:m}+1){p_end}
{synopt:{cmd:e(ntests)}}CI tests run{p_end}
{synopt:{cmd:e(depth)}}largest |S| tested{p_end}
{synopt:{cmd:e(n_edges)}}edges in the PDAG{p_end}
{synopt:{cmd:e(n_lagged)}}lagged directed edges{p_end}
{synopt:{cmd:e(n_cdir)}}contemporaneous directed edges{p_end}
{synopt:{cmd:e(n_cund)}}contemporaneous undirected edges{p_end}
{synopt:{cmd:e(n_forbid)}}node pairs removed a priori{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(F1)}, {cmd:e(precision)}, {cmd:e(recall)}, {cmd:e(shd)}, {cmd:e(F1_skel)}, {cmd:e(TP)}, {cmd:e(nnz)}, {cmd:e(n_true)}, {cmd:e(reversed)}}with {opt truth()}{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvpc}{p_end}
{synopt:{cmd:e(varlist)}}variables{p_end}
{synopt:{cmd:e(nodenames)}}node names ({cmd:cpi L3.cpi ...}){p_end}
{synopt:{cmd:e(variant)}}PC variant{p_end}
{synopt:{cmd:e(citest)}}{cmd:fisherz}{p_end}
{synopt:{cmd:e(contemp)}}{cmd:yes} or {cmd:no}{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(G)}}PDAG over nodes: G[a,b]=1, G[b,a]=0 means a{c 45}{c 62}b; both 1 = undirected{p_end}
{synopt:{cmd:e(Skel)}}undirected skeleton{p_end}
{synopt:{cmd:e(Pmax)}}largest p-value per node pair over all tests{p_end}
{synopt:{cmd:e(Psep)}}p-value at which the pair was separated{p_end}
{synopt:{cmd:e(Rmarg)}}correlation matrix of the nodes{p_end}
{synopt:{cmd:e(Rmin)}}smallest |partial r| per pair{p_end}
{synopt:{cmd:e(links)}}one row per link: effect cause lag period type r_marg r_min p_max stab
(type 1 lagged, 2 contemporaneous directed, 3 undirected){p_end}
{synopt:{cmd:e(lagmap)}}{it:n} x {it:n} number of links cause (row) {c 45}{c 62} effect (column){p_end}
{synopt:{cmd:e(degree)}}in_links out_links drivers driven own_lags{p_end}
{synopt:{cmd:e(strength)}}with {opt strength}{p_end}
{synopt:{cmd:e(Fdir)}, {cmd:e(Fadj)}}with {opt reps()}: bootstrap frequencies{p_end}
{synopt:{cmd:e(truth)}}with {opt truth()}{p_end}

{p2col 5 18 22 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Aung, H. W., Z. Zhu, G. Lee, Y. Guo and J. Li. 2026. Uncover temporal causal
interrelationships between key economic indicators through Peter-Clark algorithm.
{it:Computational Economics}. {browse "https://doi.org/10.1007/s10614-026-11411-x":doi:10.1007/s10614-026-11411-x}.

{phang}
Spirtes, P. and C. Glymour. 1991. An algorithm for fast recovery of sparse causal
graphs. {it:Social Science Computer Review} 9: 62-72.
{browse "https://doi.org/10.1177/089443939100900106":doi:10.1177/089443939100900106}.

{phang}
Colombo, D. and M. H. Maathuis. 2014. Order-independent constraint-based causal
structure learning. {it:Journal of Machine Learning Research} 15: 3741-3782.

{phang}
Meek, C. 1995. Causal inference and causal explanation with background knowledge.
{it:Proceedings of the 11th Conference on Uncertainty in Artificial Intelligence}, 403-410.

{phang}
Zhang, K., S. Zhu, M. Kalander, I. Ng, J. Ye, Z. Chen and L. Pan. 2021. gCastle: A
Python toolbox for causal discovery. {browse "https://arxiv.org/abs/2111.15155":arXiv:2111.15155}.

{phang}
Ferdous, M. H., E. Hossain and M. O. Gani. 2025. TimeGraph: Synthetic benchmark
datasets for robust time-series causal discovery. {it:Proceedings of KDD 2025},
5425-5435. {browse "https://doi.org/10.1145/3711896.3737439":doi:10.1145/3711896.3737439}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
