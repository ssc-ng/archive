{smcl}
{* *! version 1.0.0  21nov2026}{...}
{vieweralsosee "tvpc" "help tvpc"}{...}
{vieweralsosee "tvpcmci" "help tvpcmci"}{...}
{vieweralsosee "tvpcgraph" "help tvpcgraph"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:tvpcsens} {hline 2}}Sensitivity of TV-PC graphs to the lag length and to
alpha; TV-PC vs PCMCI comparison{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:tvpcsens} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lags:list(numlist)}}lag lengths {it:m} to try; default 4{p_end}
{synopt:{opt alpha:s(numlist)}}alpha values to try; default 0.05{p_end}
{synopt:{opt lagst:ep(#)}}periods per lag step{p_end}
{synopt:{opt var:iant(string)}} {opt nocon:temp}: as in {helpb tvpc}{p_end}
{synopt:{opt targ:et(varname)}}report drivers of {it:target}({it:t}) for each {it:m} (Fig. 12){p_end}
{synopt:{opt truth(matname)}}add precision, recall and F1{p_end}
{synopt:{opt pcmci}}also run {helpb tvpcmci} (Table 1 comparison){p_end}
{synopt:{opt pca:lpha(#)}}PC1 level for {opt pcmci}; default 0.2{p_end}
{synopt:{opt gr:aph}}plot F1 (or edges) against alpha{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:tvpcsens} reruns {helpb tvpc} on a grid of lag lengths and alpha values. It
reproduces two exercises of Aung et al. (2026): the lag sensitivity of Sec. 4.4 and
Fig. 12 ({it:m} = 3, 4, 5 quarterly steps), and the TV-PC versus PCMCI F1 comparison
of Table 1.

{pstd}
For every run it reports the edge counts and the Jaccard similarity with the first
run, in two forms. {it:J(var)} compares cause{c 45}{c 62}effect variable pairs.
{it:J(lag)} compares links including their lag, restricted to lags no greater than
the smallest {it:m}. With {opt truth()} it also reports F1. True links beyond a
given {it:m} are ignored for that run.

{pstd}
Your {cmd:e()} results are preserved.


{title:Examples}

{pstd}Table 1 of the paper{p_end}
{phang2}{cmd:. use tvpc_a1, clear}{p_end}
{phang2}{cmd:. local tr : char _dta[tvpc_truth]}{p_end}
{phang2}{cmd:. matrix T = (`tr')}{p_end}
{phang2}{cmd:. tvpcsens X1-X8, lagslist(4) alphas(0.0005 0.001 0.005 0.01 0.05) truth(T) pcmci graph}{p_end}

{pstd}Fig. 12: CPI maps with 3, 4 and 5 quarterly lags{p_end}
{phang2}{cmd:. use tvpc_macro, clear}{p_end}
{phang2}{cmd:. tvpcsens cpi-hpi, lagslist(3 4 5) alphas(0.05) lagstep(3) target(cpi)}{p_end}


{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(table)}}m alpha N edges lagged cdir cund ntests jac_var jac_lag
precision recall F1 [pcmci_edges pcmci_F1]{p_end}
{synopt:{cmd:r(lagslist)}, {cmd:r(alphas)}}grids used{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
