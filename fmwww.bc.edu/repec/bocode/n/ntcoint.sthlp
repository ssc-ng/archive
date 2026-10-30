{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "ntcoint methods" "help ntcoint_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "vecrank" "help vecrank"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "egranger (if installed)" "help egranger"}{...}
{viewerjumpto "Syntax" "ntcoint##syntax"}{...}
{viewerjumpto "Description" "ntcoint##description"}{...}
{viewerjumpto "Options" "ntcoint##options"}{...}
{viewerjumpto "Interpreting the output" "ntcoint##output"}{...}
{viewerjumpto "Remarks and practical guidance" "ntcoint##remarks"}{...}
{viewerjumpto "Examples" "ntcoint##examples"}{...}
{viewerjumpto "Stored results" "ntcoint##results"}{...}
{viewerjumpto "References" "ntcoint##refs"}{...}
{viewerjumpto "Author" "ntcoint##author"}{...}

{title:Title}

{phang}
{bf:ntcoint} {hline 2} Test of {it:nontrivial} cointegration via the squared-correlations
ratio of Hualde and Olmo (2026)


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:ntcoint} {varlist} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt tr:end}}include a constant {it:and} a linear time trend in the
deterministic component; the default is a constant only{p_end}

{syntab:Long-run covariance}
{synopt :{opt kern:el(kname)}}{opt parzen} (the default), {opt hanning} or
{opt bartlett}{p_end}
{synopt :{opt lamb:da(#1 #2)}}the two bandwidth exponents, {it:#1} {ul:>} {it:#2},
both {ul:<} 1/3; default {cmd:lambda(.2 .1666667)}{p_end}
{synopt :{opt c:parm(#)}}the constant {it:C} in K = {it:C}*T^lambda; default
{cmd:cparm(1)}{p_end}

{syntab:Inference}
{synopt :{opt l:evel(#)}}significance level: 90, 95 (the default) or 99{p_end}
{synopt :{opt cvt:able(which)}}{opt exact} (the default) or {opt authors}; see
{help ntcoint##cvtable:below}{p_end}
{synopt :{opt reps(#)}}bootstrap replications; default {cmd:reps(500)}{p_end}
{synopt :{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synopt :{opt btype(#)}}bootstrap algorithm, {cmd:1} (the paper's, the default)
or {cmd:2}{p_end}
{synopt :{opt noboot:strap}}skip the bootstrap{p_end}

{syntab:Reporting}
{synopt :{opt pl:ot(namelist)}}one or more of {opt series}, {opt cv}, {opt boot},
{opt bandwidth}, {opt pairs}, or {opt all}{p_end}
{synopt :{opt name(stub)}}prefix for the graph names; default {cmd:ntcoint}{p_end}
{synopt :{opt gr:aph}}synonym for {cmd:plot(series)}{p_end}
{synopt :{opt graphopts(string)}}options passed through to each graph{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The data must be {helpb tsset} and free of gaps over the estimation
window. With more than two variables {cmd:ntcoint} runs every pair.{p_end}


{marker description}{title:Description}

{pstd}
{cmd:ntcoint} tests

{p 8 8 2}{bf:H0}: absence of nontrivial cointegration{p_end}
{p 8 8 2}{bf:H1}: nontrivial cointegration{p_end}

{pstd}
in a bivariate system, using the squared-correlations ratio (SCR) statistic of
Hualde and Olmo (2026).

{pstd}
The point is a distinction standard methods blur. Two series can be formally
cointegrated for an uninteresting reason: one of them is stationary, so a
standard unit vector such as (1,0)' lies in the cointegrating space. That is
{it:trivial} cointegration (TC), and it carries no long-run equilibrium
content {hline 2} two {it:independent} processes, one I(0) and one I(1), are
"cointegrated" in this sense. Only {it:nontrivial} cointegration (NTC), where
the cointegrating vector has no zero entry, reproduces the long-run equilibrium
idea of Engle and Granger (1987). Under H0 {cmd:ntcoint} collects the three
uninteresting states {hline 2} no cointegration (NC), trivial cointegration (TC)
and full cointegration (FC, both series stationary) {hline 2} and tests them
against NTC directly.

{pstd}
The statistic is the ratio of two squared-correlation complements,

{p 8 8 2}SCR = (1 - rhat^2) / (1 - rhohat^2),{p_end}

{pstd}
where {it:rhat} is the ordinary sample correlation of the (de)trended
observables and {it:rhohat} is a nonparametric estimate of the long-run
correlation of their first differences, built from kernel long-run variances at
{it:two} bandwidths. H0 is rejected for {bf:small} values of SCR. Two features
matter in practice: the test is fully nonparametric, so no short-run dynamics
need be specified, and it is {bf:invariant to the ordering of the two
variables}, unlike residual-based tests, where the choice of dependent variable
can flip the answer {hline 2} a serious problem precisely under TC.

{pstd}
Three critical values are reported: {it:conservative} (valid for every value of
the nuisance parameter), {it:plug-in} (evaluated at the estimated long-run
correlation) and a {it:bootstrap} p-value.

{pstd}
For the derivation, the step-by-step map from code to equations, and the
evidence behind the {opt cvtable()} option, see {bf:{help ntcoint_methods:help ntcoint methods}}.


{marker options}{title:Options}

{dlgtab:Model}

{phang}
{opt trend} removes a constant and a linear time trend from each series by
ordinary least squares before forming the correlation, and demeans the first
differences before the kernel estimates. This is the specification of Section 2
of the online appendix. Without it, only a constant is removed (Section 3 of the
paper). The two cases have {it:different} limiting distributions and therefore
different critical values; {cmd:ntcoint} switches tables automatically.

{dlgtab:Long-run covariance}

{phang}
{opt kernel(kname)} selects the kernel for the long-run covariance matrix.
{opt parzen} is the default and is the only choice for which the paper's
Theorem 2 is established: it satisfies the kernel condition inherited from
Kheifets and Phillips (2023), it keeps the estimate positive semi-definite, and
it guarantees SCR {ul:>} 0 in finite samples. {opt hanning} (Tukey-Hanning) also
satisfies the kernel condition but does {it:not} guarantee a nonnegative
statistic; {opt bartlett} (Newey-West) is offered only for comparison. Both
print a warning.

{phang}
{opt lambda(#1 #2)} sets the two bandwidth exponents in K_i = C*T^lambda_i. The
theory requires 0 < lambda2 < lambda1 < 1/3. The default (1/5, 1/6) is the pair
the paper adopts after its own sensitivity analysis; it reports (1/4, 1/5) and
(1/6, 1/7) as alternatives. The slow/fast pair is what makes the test correctly
sized under full cointegration; if the two implied bandwidths round to the same
integer, {cmd:ntcoint} warns, because the construction has then collapsed to the
single-bandwidth estimator.

{phang}
{opt cparm(#)} is the constant C. Following Kheifets and Phillips (2023) the
paper fixes C = 1, and there is rarely a reason to change it.

{dlgtab:Inference}

{phang}
{opt level(#)} is the significance level in the usual Stata sense:
{cmd:level(95)} tests at 5%. Only 90, 95 and 99 are accepted, because the
limiting distribution is tabulated at those three levels.

{phang}{marker cvtable}
{opt cvtable(which)} chooses the source of the asymptotic critical values.

{p 12 14 2}
{opt exact} (the default) uses tables generated for this package by direct
simulation of the limiting functional in equation (14) of the paper, with
200,000 replications.{p_end}
{p 12 14 2}
{opt authors} uses the {it:thr_asy} tables shipped with the article's
replication package. These are {bf:3 to 29 percent smaller} than the values
implied by equation (14), and they are visibly asymmetric in the sign of the
long-run correlation although Remark 1.1 of the paper proves the distribution
depends on its absolute value only. Because H0 is rejected for small SCR,
smaller critical values mean a {it:more conservative}, undersized test. Use this
option to reproduce the numbers printed in the article; use the default to
follow the article's equations. The evidence is laid out in
{bf:{help ntcoint_methods:help ntcoint methods}}.{p_end}

{phang}
{opt reps(#)}, {opt seed(#)} control the bootstrap. The paper uses 500
replications. Always set {opt seed()} for reproducible results.

{phang}
{opt btype(#)} selects the bootstrap algorithm. {cmd:btype(1)}, the default,
recomputes the {it:whole} statistic {hline 2} including both kernel estimates
{hline 2} on every bootstrap sample; this is Steps 1-5 of Section 3 of the
online appendix. {cmd:btype(2)} reuses the denominator computed from the
observed data, which is faster but is {bf:not} the published procedure and is
not covered by Theorem S3. Prefer the default.

{phang}
{opt nobootstrap} skips the bootstrap. Useful when scanning many pairs; the
conservative and plug-in tests are still reported.

{dlgtab:Reporting}

{phang}
{opt plot(namelist)} draws one or more diagnostic graphs. {opt all} draws every
applicable one. Each is named {it:stub}{cmd:_}{it:kind}, so they can be
{helpb graph combine:combined}.

{p 12 14 2}
{opt series} {hline 2} the two series over the estimation window, in the style
of Figure 1 of the paper, with the statistic and its critical value in the
subtitle.{p_end}
{p 12 14 2}
{opt cv} {hline 2} {bf:the key diagnostic.} The critical-value curve A(rho)
across the whole range of the nuisance parameter, with the rejection region
shaded, a horizontal line at the observed SCR, and a marker at the estimated
long-run correlation rho-hat. The test rejects exactly when the horizontal line
lies inside the shaded region, so the plot shows at a glance both the decision
and how close it was. It also shows why the conservative value, the lowest point
of the curve at |rho| = 1, is the safe choice whatever rho turns out to be. With
{opt trend} the curve is A{c 94}tr(rho) and sits roughly twice as high.{p_end}
{p 12 14 2}
{opt boot} {hline 2} the bootstrap null distribution with the rejection region
coloured and the observed statistic marked, so the p-value is visible as an
area. The display is truncated at the 90th percentile of the draws, because the
null distribution has a long right tail that would otherwise squash the decision
region against the axis; the note reports how many draws lie beyond. Requires
the bootstrap, so it cannot be combined with {opt nobootstrap}.{p_end}
{p 12 14 2}
{opt bandwidth} {hline 2} SCR and both critical values at the three bandwidth
pairs the paper examines, (1/4,1/5), (1/5,1/6) and (1/6,1/7), with the realized
integer bandwidths on the axis. If the decision flips across the three, the
evidence is bandwidth-dependent and should be reported as such.{p_end}
{p 12 14 2}
{opt pairs} {hline 2} a map of the pairwise decisions over the whole varlist,
shaded by how many of the three SCR tests reject. This is the visual counterpart
of Table 3 of the paper, and it needs at least three variables. It uses
{helpb heatplot} (SSC) when installed and falls back to a base {helpb twoway}
grid otherwise.{p_end}

{phang}
{opt name(stub)} sets the graph-name prefix, so that repeated calls do not
overwrite each other. The default is {cmd:ntcoint}.

{phang}
{opt graph} is kept as a synonym for {cmd:plot(series)}.

{phang}
{opt graphopts(string)} is passed through to each graph drawn.

{pstd}
The single-pair plots ({opt series}, {opt cv}, {opt boot}, {opt bandwidth})
describe one pair, so with more than two variables only {opt pairs} is drawn and
a note says so.


{marker output}{title:Interpreting the output}

{pstd}
Each row is one pair. Reading the columns:

{p2colset 5 20 22 2}{...}
{p2col :{bf:r}}the sample correlation between the two (de)trended series,
equation (11). Under NTC it tends to +1 or -1; under TC it tends to 0; under NC
it has a nondegenerate limiting distribution (Phillips 1986); under FC it tends
to the population correlation.{p_end}
{p2col :{bf:rho}}the estimated long-run correlation between the innovations,
from equations (18)-(19). It converges more slowly than {bf:r}, so under NTC it
is usually visibly below one even in large samples. This is expected, not a
symptom of anything.{p_end}
{p2col :{bf:SCR}}the test statistic. {bf:Small is evidence against H0.} Under
NTC it is O_p(T^(2*lambda1 - 1)) and collapses to zero; under TC and FC it
diverges to +infinity; under NC it converges to the distribution A(rho).{p_end}
{p2col :{bf:cv cons}}the conservative critical value, the infimum of the
critical value over the nuisance parameter, attained at |rho| = 1. Using it
guarantees correct asymptotic size whatever the true rho, at the cost of
power.{p_end}
{p2col :{bf:cv plug}}the plug-in critical value, the quantile of A(rhohat) read
at the estimated long-run correlation. It is never smaller than {bf:cv cons} and
is the more powerful of the two.{p_end}
{p2col :{bf:boot p}}the bootstrap p-value. Reject when it is at or below the
chosen significance level.{p_end}
{p2col :{bf:cons,plug,bt}}three 0/1 decisions in the order conservative,
plug-in, bootstrap: 1 means H0 was rejected, i.e. {bf:evidence of nontrivial
cointegration}. This is the format of Table 3 of the paper.{p_end}
{p2colreset}{...}

{pstd}
Because {bf:cv cons} {ul:<} {bf:cv plug} always, a conservative rejection
implies a plug-in rejection. A row reading {cmd:1,1,1} is unambiguous evidence
of NTC; {cmd:0,1,1} is evidence that rests on the sharper critical value;
{cmd:0,0,0} means the pair is not distinguishable from "no long-run equilibrium
relationship", which includes the possibility that the two series {it:are}
cointegrated, but trivially.


{marker remarks}{title:Remarks and practical guidance}

{dlgtab:Sample size}

{pstd}
The method is asymptotic and the nonparametric long-run correlation converges
slowly. The simulation evidence in the online appendix shows the plug-in and
bootstrap versions are oversized at T = 50 (rejection frequencies around 0.17 to
0.22 against a nominal 0.10) and that the distortion disappears by about
T = 200-500. {cmd:ntcoint} refuses samples below T = 20 and warns below T = 100.
Treat anything under T = 200 as indicative. The conservative version is
undersized by construction and is the safe choice in short samples.

{dlgtab:Which version to report}

{pstd}
The paper's own conclusion is that the {bf:bootstrap} version gives the best
balance of size and power across its seven designs, with the plug-in close
behind and the conservative version safest but least powerful. Reporting all
three, as the default output does, is the honest presentation.

{dlgtab:Choosing the deterministic specification}

{pstd}
Use {opt trend} only when a linear trend is genuinely plausible. The two cases
have different limiting distributions, and the trend-case critical values are
roughly twice the constant-case ones, so the choice materially changes the
answer. The paper's own application argues the euro-area yield series show no
linear trend and uses the constant-only specification.

{dlgtab:What the test does not do}

{pstd}
It is bivariate. The paper treats a multivariate extension and the notion of a
nontrivial cointegrating {it:rank} as future work, so {cmd:ntcoint} runs pairs
and nothing more. Absence of pairwise NTC does {bf:not} rule out a
higher-dimensional cointegrating relationship.

{pstd}
It returns no confidence interval for the cointegrating coefficient or for rho,
and no estimate of the cointegrating vector; the paper provides none.

{pstd}
There is one acknowledged blind spot. Under full cointegration with a
population correlation of exactly one, the statistic cannot separate FC from
NTC. Remark 1.3 of the paper argues this case has little empirical relevance for
economic time series and notes that Johansen's procedure and residual-based
methods cannot handle it either.

{dlgtab:Bandwidth sensitivity}

{pstd}
Report results for more than one {opt lambda()} pair if the decision is close.
The paper examines (1/4,1/5), (1/5,1/6) and (1/6,1/7) and finds the middle pair
balances size and power best, which is why it is the default. The authors
deliberately decline the automatic bandwidth rules of Andrews (1991) and Newey
and West (1994), which target the mean squared error of a long-run variance
rather than the behaviour of this ratio.


{marker examples}{title:Examples}

{pstd}
The example dataset and do-files ship as {it:ancillary} files, so they are not
placed on the adopath. Fetch them into your working directory once with{p_end}
{phang2}{cmd:. net get ntcoint}{p_end}

{pstd}Setup: euro-area AAA government bond yields, daily, 2004-2025{p_end}
{phang2}{cmd:. use ntcoint_ecbyields}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}A single pair, all three versions of the test{p_end}
{phang2}{cmd:. ntcoint y10y y30y, level(90) reps(500) seed(20261027)}{p_end}

{pstd}Every pair of the yield curve, as in Table 3 of the paper{p_end}
{phang2}{cmd:. ntcoint y3m y1y y2y y5y y7y y10y y30y, level(90) reps(500) seed(20261027)}{p_end}

{pstd}Reproduce the article's printed decisions, using its own critical values{p_end}
{phang2}{cmd:. ntcoint y3m y1y y2y y5y y7y y10y y30y, cvtable(authors) level(90)}{p_end}

{pstd}Allow a linear trend, and skip the bootstrap for speed{p_end}
{phang2}{cmd:. ntcoint y2y y10y, trend nobootstrap}{p_end}

{pstd}Bandwidth sensitivity{p_end}
{phang2}{cmd:. ntcoint y10y y30y, lambda(.25 .2)       nobootstrap}{p_end}
{phang2}{cmd:. ntcoint y10y y30y, lambda(.2 .1666667)  nobootstrap}{p_end}
{phang2}{cmd:. ntcoint y10y y30y, lambda(.1666667 .1428571) nobootstrap}{p_end}

{pstd}Diagnostic graphs: where the decision comes from, and how robust it is{p_end}
{phang2}{cmd:. ntcoint y10y y30y, plot(cv)}{p_end}
{phang2}{cmd:. ntcoint y10y y30y, reps(500) seed(1) plot(boot)}{p_end}
{phang2}{cmd:. ntcoint y10y y30y, plot(bandwidth) nobootstrap}{p_end}

{pstd}Everything at once, then combined into one figure{p_end}
{phang2}{cmd:. ntcoint y10y y30y, reps(500) seed(1) plot(all) name(fig)}{p_end}
{phang2}{cmd:. graph combine fig_series fig_cv fig_boot fig_bw, cols(2)}{p_end}

{pstd}The pairwise map of the whole yield curve (the visual Table 3){p_end}
{phang2}{cmd:. ntcoint y3m y1y y2y y5y y7y y10y y30y, level(90) plot(pairs)}{p_end}
{phang2}{cmd:. matrix list r(decmap)}{p_end}

{pstd}Redrawing the critical-value curve by hand from the stored matrix{p_end}
{phang2}{cmd:. ntcoint y10y y30y, nobootstrap}{p_end}
{phang2}{cmd:. matrix C = r(cvcurve)}{p_end}
{phang2}{cmd:. local s = r(scr)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double C, name(c)}{p_end}
{phang2}{cmd:. twoway line c2 c1, yline(`s')}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}A full self-test, including a known-truth Monte Carlo on the paper's DGP1{p_end}
{phang2}{cmd:. do ntcoint_example.do}{p_end}


{marker results}{title:Stored results}

{pstd}{cmd:ntcoint} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(npairs)}}number of pairs tested{p_end}
{synopt:{cmd:r(level)}}significance level used{p_end}
{synopt:{cmd:r(lambda1)}}slow bandwidth exponent{p_end}
{synopt:{cmd:r(lambda2)}}fast bandwidth exponent{p_end}

{pstd}and, when exactly one pair was tested,{p_end}
{synopt:{cmd:r(T)}}number of observations{p_end}
{synopt:{cmd:r(r)}}sample correlation{p_end}
{synopt:{cmd:r(rho)}}estimated long-run correlation{p_end}
{synopt:{cmd:r(scr)}}the SCR statistic{p_end}
{synopt:{cmd:r(cv_cons)}}conservative critical value{p_end}
{synopt:{cmd:r(cv_plug)}}plug-in critical value{p_end}
{synopt:{cmd:r(p_boot)}}bootstrap p-value{p_end}
{synopt:{cmd:r(rej_cons)}}1 if the conservative test rejects{p_end}
{synopt:{cmd:r(rej_plug)}}1 if the plug-in test rejects{p_end}
{synopt:{cmd:r(rej_boot)}}1 if the bootstrap test rejects{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:ntcoint}{p_end}
{synopt:{cmd:r(kernel)}}kernel used{p_end}
{synopt:{cmd:r(cvtable)}}{cmd:exact} or {cmd:authors}{p_end}
{synopt:{cmd:r(deterministic)}}{cmd:constant} or {cmd:trend}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}one row per pair, columns {cmd:r}, {cmd:rho},
{cmd:scr}, {cmd:cv_cons}, {cmd:cv_plug}, {cmd:p_boot}, {cmd:rej_cons},
{cmd:rej_plug}, {cmd:rej_boot}, {cmd:T}{p_end}
{synopt:{cmd:r(cvcurve)}}single pair only: the whole critical-value curve,
2001 x 2, columns {cmd:rho} and {cmd:cv}, so the {opt plot(cv)} picture can be
redrawn by hand{p_end}
{synopt:{cmd:r(bwscan)}}after {opt plot(bandwidth)}: 3 x 7, columns
{cmd:lambda1}, {cmd:lambda2}, {cmd:K1}, {cmd:K2}, {cmd:scr}, {cmd:cv_cons},
{cmd:cv_plug}{p_end}
{synopt:{cmd:r(decmap)}}after {opt plot(pairs)}: the symmetric
{it:k} x {it:k} matrix of how many SCR tests reject for each pair{p_end}
{p2colreset}{...}


{marker refs}{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica} 59: 817-858.

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Co-integration and error correction:
Representation, estimation, and testing. {it:Econometrica} 55: 251-276.

{phang}
Gomez-Biscarri, J., and J. Hualde. 2015. Regression-based analysis of
cointegration systems. {it:Journal of Econometrics} 186: 32-50.

{phang}
Hualde, J., and J. Olmo. 2026. Testing for nontrivial cointegration.
{it:Journal of Business & Economic Statistics}.
{browse "https://doi.org/10.1080/07350015.2026.2638497":doi:10.1080/07350015.2026.2638497}.

{phang}
Johansen, S. 1995. {it:Likelihood-Based Inference in Cointegrated Vector
Autoregressive Models}. Oxford: Oxford University Press.

{phang}
Kheifets, I. L., and P. C. B. Phillips. 2023. Fully modified least squares
cointegrating parameter estimation in multicointegrated systems.
{it:Journal of Econometrics} 232: 300-319.

{phang}
Newey, W. K., and K. D. West. 1994. Automatic lag selection in covariance
matrix estimation. {it:Review of Economic Studies} 61: 631-653.

{phang}
Phillips, P. C. B. 1986. Understanding spurious regressions in econometrics.
{it:Journal of Econometrics} 33: 311-340.


{marker author}{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite Hualde and Olmo (2026) for the method and this package for the
implementation.
