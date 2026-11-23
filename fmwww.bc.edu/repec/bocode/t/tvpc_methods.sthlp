{smcl}
{* *! version 1.0.0  21nov2026}{...}
{vieweralsosee "tvpc" "help tvpc"}{...}
{vieweralsosee "tvpcmci" "help tvpcmci"}{...}
{vieweralsosee "tvpcsens" "help tvpcsens"}{...}
{vieweralsosee "tvpcgraph" "help tvpcgraph"}{...}
{viewerjumpto "Node graph" "tvpc_methods##nodes"}{...}
{viewerjumpto "Restrictions" "tvpc_methods##restrict"}{...}
{viewerjumpto "Skeleton" "tvpc_methods##skeleton"}{...}
{viewerjumpto "Fisher z" "tvpc_methods##fisher"}{...}
{viewerjumpto "Orientation" "tvpc_methods##orient"}{...}
{viewerjumpto "Step map" "tvpc_methods##map"}{...}
{viewerjumpto "Validation" "tvpc_methods##validation"}{...}
{viewerjumpto "Extensions" "tvpc_methods##ext"}{...}
{title:Title}

{p 4 4 2}
{bf:tvpc methods} {hline 2} Derivation, step-by-step correspondence with Aung et
al. (2026) and validation of {helpb tvpc}


{marker nodes}{...}
{title:1. Standardisation and the time-lagged node graph (Sec. 2.1.1, 2.3, Fig. 1)}

{pstd}
Every series is standardised, {it:x''} = ({it:x} - mu)/sigma (Eq. 2.2). sigma is the
population standard deviation, as in a standard scaler. With {it:n} variables and
{it:m} lag steps of {it:s} periods, the node set is

{p 8 8 2}
V = {c -(} X(1,t), X(1,t-s), ..., X(1,t-ms), ..., X(n,t), ..., X(n,t-ms) {c )-}

{pstd}
so that |V| = {it:n}({it:m}+1). The nodes are ordered variable by variable, lag
within variable, exactly as written in the paper. The order matters for the
original PC variant. The data matrix has {it:u} = T - {it:ms} complete rows.


{marker restrict}{...}
{title:2. Edge restrictions (Sec. 2.1.1)}

{pstd}
The initial graph G0 is complete and undirected, except that:{p_end}
{phang2}(a) there are no self-loops;{p_end}
{phang2}(b) there are no edges between two lagged nodes X(i,t-k) and X(j,t-l), k,l {ul:>} 1,
including two lags of the same variable;{p_end}
{phang2}(c) edges X(i,t) {c 45}{c 62} X(j,t-k) are forbidden, so any edge between a
current node and a lagged node must point forward in time.{p_end}

{pstd}
Restrictions (b) and (c) are passed to PC as background knowledge in the form of
gCastle's {it:PrioriKnowledge}. A pair forbidden in both directions is removed
before any test, and a pair forbidden in one direction is oriented at the start of
the orientation stage. Edges remain possible from lag to current and between
current nodes. With {opt nocontemp}, current-current pairs are also forbidden.


{marker skeleton}{...}
{title:3. Skeleton by conditional-independence testing (Sec. 2.1.2)}

{pstd}
For d = 0, 1, 2, ... and for every adjacent pair (i, j) with i < j in node order,
PC tests

{p 8 8 2}
H0: X_i {c 124}{c 124} X_j | S,   S {c 162} adj(i) \ {c -(}j{c )-},  |S| = d

{pstd}
and deletes the edge as soon as one test gives p {ul:>} alpha. S is then stored as
the separating set. The loop continues while some pair still has
|adj(i)\{c -(}j{c )-}| {ul:>} d. The paper writes S {c 162} V \ {c -(}X_i, X_j{c )-} with
|S| from 0 to n-2. Its implementation, gCastle, restricts S to the current
adjacency of {it:i}, which is the standard PC device; {cmd:tvpc} follows the
implementation.

{pstd}
{it:Enumeration order.} gCastle draws the candidate sets with
{cmd:itertools.combinations} over a Python {cmd:set} of node indices. The iteration
order of that set is the order of the slots in CPython's hash table (open
addressing with 9 linear probes and perturbation, table resized at 3/5 load).
{cmd:tvpc} emulates this table exactly in Mata. As a result, the same first
separating set is found and the separating sets and orientations coincide with
gCastle's. In {cmd:original} the adjacencies are updated during each depth; in
{cmd:stable} they are frozen at the start of each depth.


{marker fisher}{...}
{title:4. Fisher's z test (Sec. 2.2, Eq. 2.1)}

{pstd}
The partial correlation is r = -P[1,2]/sqrt(|P[1,1] P[2,2]|), where P is the
inverse of the correlation matrix of (X_i, X_j, S). A pseudo-inverse is used if
that matrix is singular, and r is clipped to [-0.99999, 0.99999]. The test
statistic and p-value are

{p 8 8 2}
Z = sqrt(u - |S| - 3) x 0.5 x ln{c -(}(1 + r)/(1 - r){c )-},
p = 2{c -(}1 - Phi(|Z|){c )-}

{pstd}
and the edge is removed if p {ul:>} alpha (Eq. in Sec. 2.1.2).


{marker orient}{...}
{title:5. Orientation and the PDAG (Sec. 2.1.3-2.1.4)}

{phang2}(i) {it:Background knowledge:} edges of forbidden direction are removed, so
lag-to-current edges become directed.{p_end}
{phang2}(ii) {it:V-structures:} for every separated pair (i,j), taken in the order
they were removed, and every common neighbour k not in S(i,j), the undirected
edges i{c 45}k and j{c 45}k are oriented i{c 45}{c 62}k{c 60}{c 45}j. Edges
already oriented are left unchanged.{p_end}
{phang2}(iii) {it:Meek's rules} are iterated to a fixed point: R1 (no new
v-structure), R2 (acyclicity), R3 and R4. The paper's displayed rules are R1 and
R2.{p_end}

{pstd}
The result is a partially directed acyclic graph, stored in {cmd:e(G)}. Undirected
edges are those the data cannot orient (Sec. 2.1.4).


{marker map}{...}
{title:6. Step {c 45}{c 62} code map}

{p2colset 5 42 44 2}{...}
{p2col:{bf:Paper}}{bf:tvpc.ado}{p_end}
{p2line}
{p2col:Eq. (2.2) standardisation}Step 1, ado ({cmd:sdp} = population sd){p_end}
{p2col:Fig. 1 step 2, node set V1}Step 2, {cmd:L}{it:ks}{cmd:.}var nodes{p_end}
{p2col:Sec. 2.1.1 restrictions}{cmd:_tvpc_forbid()}{p_end}
{p2col:Sec. 2.1.2 CI testing loop}{cmd:_tvpc_skeleton()}, {cmd:_tvpc_loop()}{p_end}
{p2col:gCastle set ordering}{cmd:_tvpc_ps_fromiter()}, {cmd:_tvpc_ps_minus()}{p_end}
{p2col:Eq. (2.1) Fisher z}{cmd:_tvpc_fz()}{p_end}
{p2col:Sec. 2.1.3 colliders + rules}{cmd:_tvpc_orient()}{p_end}
{p2col:Sec. 2.1.4 PDAG}{cmd:e(G)}, {cmd:e(links)}{p_end}
{p2col:Figs. 3-11 maps}{helpb tvpcgraph} {cmd:map()}, Table B{p_end}
{p2col:Fig. 2 network}{helpb tvpcgraph} {cmd:network}{p_end}
{p2col:Sec. 4.4, Fig. 12 lag sensitivity}{helpb tvpcsens}{p_end}
{p2col:Sec. 5, Table 1 vs PCMCI}{helpb tvpcmci}, {helpb tvpcsens} {cmd:pcmci}{p_end}
{p2colreset}{...}


{marker validation}{...}
{title:7. Validation}

{pstd}
{it:Against gCastle.} On the TimeGraph A1 data (Gaussian, 8 variables, lag 4,
n = 5000, shipped as {cmd:tvpc_a1.dta}), the 40 x 40 PDAG of {cmd:tvpc} is identical
entry by entry to gCastle's at alpha = 0.0005, 0.001, 0.005, 0.01 and 0.05. On 24
simulated paper-size problems (11 variables, 55 nodes, {cmd:lagstep(3)}, both
variants, alpha = 0.01, 0.05 and 0.2, conditioning sets up to |S| = 12), all 24
graphs are identical.

{pstd}
{it:Table 1 of the paper.} With the gCastle MetricsDAG F1, {cmd:tvpc} gives 0.6957,
0.6957, 0.6667, 0.6400 and 0.4138 at the five p-values. The paper reports 0.6957,
0.6957, 0.6667, 0.6400 and 0.5517. The first four values match exactly. At
p = 0.05 gCastle itself returns 0.4138 on this dataset, so the printed 0.5517 cannot
be reproduced with the published data and code.

{pstd}
{it:PCMCI.} The p-values of {helpb tvpcmci} agree with tigramite 5.2 (ParCorr) to
within 1e-7. Its F1 scores are 0.6923 (p = 0.0005, 0.001, 0.005), matching the
paper, and 0.6923 and 0.5294 at p = 0.01 and 0.05, where the paper reports 0.6207
and 0.5455. The likely cause is a different tigramite version or different pc_alpha
settings, which the paper does not report.


{marker ext}{...}
{title:8. Extensions beyond the paper}

{phang2}{opt strength}: the linear structural-equation coefficient of each directed
link, estimated by OLS on the PDAG parents. This responds to the limitation stated
in Sec. 6 of the paper.{p_end}
{phang2}{opt reps()}: moving-block bootstrap stability of each link.{p_end}
{phang2}{opt truth()}: F1, precision, recall, SHD and skeleton F1.{p_end}
{phang2}{opt nocontemp}, {opt maxdepth()}, {cmd:variant(stable)}.{p_end}

{pstd}
The paper does not provide standard errors or tests for the presence of a link
beyond the PC decision rule. The strength and bootstrap outputs are descriptive
diagnostics, not formal inference.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
