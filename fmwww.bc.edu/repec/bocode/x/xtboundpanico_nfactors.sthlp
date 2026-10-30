{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "xtboundpanico" "help xtboundpanico"}{...}
{vieweralsosee "xtboundpanico methods" "help xtboundpanico_methods"}{...}
{vieweralsosee "xtboundpanico bounds" "help xtboundpanico_bounds"}{...}
{vieweralsosee "xtboundpanico panico" "help xtboundpanico_panico"}{...}
{viewerjumpto "Syntax" "xtboundpanico_nfactors##syntax"}{...}
{viewerjumpto "Description" "xtboundpanico_nfactors##description"}{...}
{viewerjumpto "Options" "xtboundpanico_nfactors##options"}{...}
{viewerjumpto "Criteria" "xtboundpanico_nfactors##criteria"}{...}
{viewerjumpto "Interpreting the output" "xtboundpanico_nfactors##interpret"}{...}
{viewerjumpto "Examples" "xtboundpanico_nfactors##examples"}{...}
{viewerjumpto "Stored results" "xtboundpanico_nfactors##results"}{...}
{viewerjumpto "Author" "xtboundpanico_nfactors##author"}{...}

{title:Title}

{phang}
{bf:xtboundpanico nfactors} {hline 2} number of common factors, eleven
estimators side by side


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtboundpanico} {cmdab:nf:actors} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(#)}}deterministics: 0 none, 1 constant (default), 2 constant
and trend{p_end}
{synopt:{opt meth:od(method)}}{cmd:pc} (default) or {cmd:ca}{p_end}
{synopt:{opt rmax(#)}}maximum considered; default 5 ({cmd:pc}) or {it:1+k} ({cmd:ca}){p_end}
{synopt:{opt graph}}plot the criterion profiles{p_end}
{synopt:{opt name(name)}}name for the graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtboundpanico nfactors} reports every implemented estimator of the number
of common factors on the same data, so you can see whether they agree before
committing to one.

{pstd}
This matters more than it looks. The paper's own empirical sections (Section
6.1) report that every Bai-Ng (2002) criterion selected the maximum allowed
number of factors while Onatski's (2010) and Ahn-Horenstein's (2013) estimators
selected one - and the reported results are those for r = 1. A single criterion
run in isolation can therefore be badly misleading.

{pstd}
Candidates are taken from the {bf:differenced and projected} series D.yhat^d, as
the PANIC methodology prescribes, not from the levels. With {cmd:method(pc)}
they are the principal components of that matrix; with {cmd:method(ca)} they are
the differenced, demeaned cross-section averages of the observables, and the
Reese-Westerlund (2016) criterion is reported instead.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} must match the model you will use for testing: it determines
whether the differences are demeaned (Model 2) or not (Models 0 and 1), and that
changes the factor estimates.

{phang}
{opt method(pc)} reports the eleven estimators listed below.
{opt method(ca)} reports the Reese-Westerlund criterion over
s = 0, 1, ..., 1+k cross-section averages.

{phang}
{opt rmax(#)} is the upper bound. It is not neutral: PCp, AIC3 and BIC3 scale
their penalties by sigmahat^2 = V(rmax), so changing rmax moves those three.
ICp1-ICp3, ER, GR and ED do not depend on rmax except through the search range.

{phang}
{opt graph} plots ICp1, ICp2 and ICp3 against k (or IC(s) against s for
{cmd:method(ca)}).


{marker criteria}{...}
{title:The criteria}

{pstd}
Let V(k) be the average residual variance after fitting k factors, C2 =
min(N, T), and mutilde_1 >= mutilde_2 >= ... the eigenvalues of XX'/(TN).

{synoptset 16 tabbed}{...}
{synopt:{bf:ICp1}}ln V(k) + k ((N+T)/(NT)) ln(NT/(N+T)) {space 2}- the panel BIC;
the paper's default{p_end}
{synopt:{bf:ICp2}}ln V(k) + k ((N+T)/(NT)) ln C2{p_end}
{synopt:{bf:ICp3}}ln V(k) + k (ln C2)/C2 {space 6}- less robust when N or T is
small{p_end}
{synopt:{bf:PCp1-3}}as ICp1-3 but with V(k) in levels, penalty scaled by
V(rmax){p_end}
{synopt:{bf:AIC3}}V(k) + k sigmahat^2 2(N+T-k)/(NT) {space 2}- fails Bai and
Ng's condition (ii); over-selects{p_end}
{synopt:{bf:BIC3}}V(k) + k sigmahat^2 (N+T-k) ln(NT)/(NT) {space 1}- the paper's
fallback when N or T is small{p_end}
{synopt:{bf:ER}}mutilde_k / mutilde_{k+1} {space 10}- {bf:maximised}{p_end}
{synopt:{bf:GR}}ln(V(k-1)/V(k)) / ln(V(k)/V(k+1)) {space 1}- {bf:maximised}{p_end}
{synopt:{bf:ED}}Onatski's iterated edge-distribution rule{p_end}
{synopt:{bf:RW}}ln det[Sigmahat_v(s)] + s (m+1) N^-1 ln N {space 1}-
{cmd:method(ca)} only{p_end}

{pstd}
ER and GR include the Ahn-Horenstein mock eigenvalue
mutilde_0 = V(0)/ln(min(N,T)), so rhat = 0 is an admissible answer for them.
Full formulas and the ED algorithm are in
{helpb xtboundpanico_methods:help xtboundpanico methods}.

{pstd}
{bf:Not implemented.} Bai and Ng's AIC1, BIC1, AIC2 and BIC2 are omitted: the
paper does not use them and Bai and Ng show they fail the consistency conditions
for some (N, T) configurations.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
Three blocks are printed: the ICp and PCp profiles over k, the AIC3/BIC3/ER/GR
profiles with the raw eigenvalues, and a summary table of the selected rhat per
criterion.

{pstd}
{bf:Read the profile, not just the argmin.} A criterion that is nearly flat
between k = 1 and k = 3 is telling you that it cannot distinguish them. The
eigenvalue column is the most direct evidence: a clear gap between mutilde_r and
mutilde_{r+1} is what every one of these estimators is trying to detect, and ER
makes that gap explicit as a ratio.

{pstd}
{bf:When they disagree.} Follow the paper: prefer BIC3 and the ratio-based
estimators (ER, GR, ED) when N or T is small, and check that your testing
conclusions survive both the small and the large rhat. Over-specifying r leaves
the I(1) bound of the bounds test almost unaffected but makes the I(0) bound
over-reject; in PANICO it mostly costs power.

{pstd}
{bf:AIC3 selecting rmax is expected}, not a bug - it fails Bai and Ng's second
consistency condition. If AIC3 is your only outlier, ignore it.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}All eleven estimators, trend case{p_end}
{phang2}{cmd:. xtboundpanico nfactors invest mvalue kstock, model(2) rmax(4)}{p_end}

{pstd}With the criterion profiles plotted{p_end}
{phang2}{cmd:. xtboundpanico nfactors invest mvalue kstock, model(2) rmax(4) graph}{p_end}

{pstd}The cross-section-average criterion{p_end}
{phang2}{cmd:. xtboundpanico nfactors invest mvalue kstock, model(2) method(ca)}{p_end}

{pstd}Feed the answer straight into the test{p_end}
{phang2}{cmd:. xtboundpanico nfactors invest mvalue kstock, model(2)}{p_end}
{phang2}{cmd:. local r = r(r_bic3)}{p_end}
{phang2}{cmd:. xtboundpanico panico invest mvalue kstock, model(2) factors(`r')}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtboundpanico nfactors} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(r_icp1)}}, {cmd:r(r_icp2)}, {cmd:r(r_icp3)}{p_end}
{synopt:{cmd:r(r_pcp1)}}, {cmd:r(r_pcp2)}, {cmd:r(r_pcp3)}{p_end}
{synopt:{cmd:r(r_aic3)}}, {cmd:r(r_bic3)}{p_end}
{synopt:{cmd:r(r_er)}}, {cmd:r(r_gr)}, {cmd:r(r_ed)}{p_end}
{synopt:{cmd:r(r_rw)}}{cmd:method(ca)} only{p_end}
{synopt:{cmd:r(N)}}, {cmd:r(T)}, {cmd:r(k)}, {cmd:r(rmax)}, {cmd:r(model)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtboundpanico}{p_end}
{synopt:{cmd:r(subcmd)}}{cmd:nfactors}{p_end}
{synopt:{cmd:r(method)}}{cmd:pc} or {cmd:ca}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(ic)}}criterion table. With {cmd:method(pc)}, (rmax+1) x 12:
k, ICp1-3, PCp1-3, AIC3, BIC3, ER, GR, eigenvalue. With {cmd:method(ca)},
(rmax+1) x 3: s, IC(s), ln Sigmahat_v(s){p_end}
{synopt:{cmd:r(rhats)}}1 x 11 of the selected rhat in the order ICp1, ICp2,
ICp3, PCp1, PCp2, PCp3, AIC3, BIC3, ER, GR, ED (1 x 1 with {cmd:method(ca)}){p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane
