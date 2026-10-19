{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtlr" "help tvtlr"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{vieweralsosee "tvtsel" "help tvtsel"}{...}
{viewerjumpto "Syntax" "tvtpredreg##syntax"}{...}
{viewerjumpto "Description" "tvtpredreg##description"}{...}
{viewerjumpto "Which statistic, and why you must choose" "tvtpredreg##which"}{...}
{viewerjumpto "Options" "tvtpredreg##options"}{...}
{viewerjumpto "The four tuning parameters" "tvtpredreg##tuning"}{...}
{viewerjumpto "What is validated and what is not" "tvtpredreg##validation"}{...}
{viewerjumpto "Examples" "tvtpredreg##examples"}{...}
{viewerjumpto "Stored results" "tvtpredreg##results"}{...}
{viewerjumpto "References" "tvtpredreg##references"}{...}
{viewerjumpto "Author" "tvtpredreg##author"}{...}
{title:Title}

{phang}
{bf:tvtpredreg} {hline 2} Does a predictive regression change into a
threshold predictive regression?


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtpredreg} {depvar} {it:predictors} {ifin}{cmd:,}
{opth thr:eshvar(varname)} {opt meth:od(glr|gf)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opth threshvar(varname)}}the threshold variable; it enters
{bf:lagged}, as {it:q_t-1}{p_end}
{synopt :{opt method(glr|gf)}}{bf:no default} {hline 2} see
{it:Which statistic}{p_end}

{syntab:The four tuning parameters}
{synopt :{opt pi1(#)}}break-date trimming, {it:k1} = {it:floor(n*pi1)};
default 0.85{p_end}
{synopt :{opt lambda1(#)}}lower threshold quantile; default 0.15{p_end}
{synopt :{opt lambda2(#)}}upper threshold quantile; default 0.85{p_end}
{synopt :{opt bootr:eps(#)}}bootstrap draws; default 499{p_end}

{syntab:Other}
{synopt :{opt seed(#)}}make the bootstrap reproducible{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:depvar} is regressed on the {bf:lagged} predictors, so the model is
{it:y_t} on {it:x_t-1}: supply the predictors in levels and the command
lags them.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtpredreg} tests a predictive regression

{p 8 8 2}
{it:y_t} = {it:psi_0} + {it:psi_1}{it:x_t-1} + {it:u_t}

{pstd}
against the alternative that at some unknown date {it:k} it becomes a
{bf:threshold} predictive regression,

{p 8 8 2}
{it:y_t} = {it:psi_0} + {it:psi_1}{it:x_t-1} +
({it:phi_0} + {it:phi_1}{it:x_t-1}) 1{c -(}{it:q_t-1} <= {it:r}{c )-} +
{it:u_t},{space 4}{it:t} > {it:k}

{pstd}
Both the break date {it:k} and the threshold {it:r} are {bf:absent under
the null}, which is what makes the problem hard: the statistic is a double
supremum and its limiting distribution is not standard.

{pstd}
Two special cases of the same null sit in the literature already. With
{it:r} = infinity it is a test of parameter change in a predictive
regression; with {it:k} = 0 it is a test of a threshold. This command tests
both at once.


{marker which}{...}
{title:Which statistic, and why you must choose}

{pstd}
{bf:{opt method()} has no default, deliberately.}

{phang}
{opt method(glr)} {hline 2} a generalised likelihood ratio, for a
{bf:stationary} predictor.

{phang}
{opt method(gf)} {hline 2} a generalised F, for a {bf:unit-root}
predictor. Its critical values come from Hansen's (2000) {bf:fixed
regressor} bootstrap, because, as the paper puts it, standard bootstrap
techniques fail in the context of non-stationary autoregressive models.

{pstd}
The two {it:statistics} barely differ {hline 2} they are computed from the
same pair of residual sums and the paper shows they are asymptotically
equivalent when the predictor is stationary. {bf:The two bootstraps do
differ}, and using the wrong one invalidates the inference. That is a
judgement about your data, not a default this command can make for you, so
you must state it and be able to defend it. Test the predictor for a unit
root first.

{pstd}
Whichever you choose, the other statistic is printed for comparison. {bf:It
must not be compared with the critical values shown} {hline 2} those belong
to the method you asked for.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is required. It enters lagged: the indicator is
1{c -(}{it:q_t-1} <= {it:r}{c )-}. It may not also be a predictor.

{phang}
{opt seed(#)} fixes the bootstrap draws. Without it two runs on the same
data give slightly different p-values, as any bootstrap does.

{phang}
The four tuning options have their own section below. Read it.


{marker tuning}{...}
{title:The four tuning parameters}

{pstd}
{bf:The paper on which this is based never states them.} The PDF available
here is the December 2020 preprint, and in it

{p2colset 8 24 26 2}{...}
{p2col :{opt pi1()}}appears only as "0 < {it:pi1} < 1"{p_end}
{p2col :{opt lambda1()}}appears only as {it:lambda1} = F({it:r1}) with
"-infinity < {it:r1}"{p_end}
{p2col :{opt lambda2()}}likewise, with "{it:r1} < {it:r2} < infinity"{p_end}
{p2col :{opt bootreps()}}is never given a value at all{p_end}
{p2colreset}{...}

{pstd}
Those symbols occur more than eighteen times across the paper {hline 2} in
the statistic, in Theorem 1, in every bootstrap statistic and every
corollary {hline 2} and not once with a number. The "5000 replications" in
its simulation section is the {bf:Monte Carlo} count, not the bootstrap
count.

{pstd}
{bf:So the defaults here are conventional choices, not the paper's}, and
the command prints them on every run so they end up in your log. Report
them alongside your results. If you need to match the paper's own tables,
consult the published {it:JBES} version (41(1):228-240), which may fix
them.

{pstd}
{bf:Why this matters more here than for other tests in this library.}
Section 3 of the paper says the limiting distribution "depends on the DGP
and cannot be tabulated". There is therefore no published critical-value
table to check against, unlike {helpb tvtlr}, whose source tabulates
percentage points {it:indexed by} the trimming. Here the tuning and the
critical values cannot be separated.


{marker validation}{...}
{title:What is validated and what is not}

{pstd}
{bf:Validated: the bootstrap is calibrated.} A correctly built bootstrap
test reproduces the statistic's own null distribution at {it:any}
admissible trimming, so this check needs none of the four unknowns. Data
are generated from the paper's own null design; the statistic's null
quantiles are measured directly over 400 draws, and the bootstrap's
critical values are compared with them. Across four designs the bootstrap
now reproduces them to within about 5%, with no systematic direction.

{pstd}
{bf:That check found and fixed a real defect.} The trimming had been
applied to regime {bf:membership} and not only to the candidate
thresholds, so observations below the lower bound were dropped out of the
regime instead of merely being excluded as threshold candidates. That left
the regime nearly empty at {it:r} just above the bound, where the
statistic turns on one or two residuals -- which the sample realises once
but the bootstrap redraws on every replication. The bootstrap's critical
values came out 8 to 31 percent too high. A rejection-rate study could not
have resolved an error that size at any affordable replication count; the
direct comparison did, at a fraction of the cost.

{pstd}
{bf:Not validated: the paper's table entries.} They were produced at the
unstated tuning, so a mismatch could not be attributed. Reproducing them
needs the published version.

{pstd}
The full record, including one declared departure over which residuals the
bootstrap multiplies, is in
{bf:validation/tvthresh/tvtpredreg_equation_map.md}.


{marker examples}{...}
{title:Examples}

{pstd}Stationary predictor {hline 2} check that first, then use {cmd:glr}{p_end}
{phang2}{cmd:. dfuller x, lags(1)}{p_end}
{phang2}{cmd:. tvtpredreg y x, threshvar(q) method(glr)}{p_end}

{pstd}Highly persistent or unit-root predictor {hline 2} use {cmd:gf}{p_end}
{phang2}{cmd:. tvtpredreg y x, threshvar(q) method(gf)}{p_end}

{pstd}Reproducible, and with the tuning stated explicitly{p_end}
{phang2}{cmd:. tvtpredreg y x, threshvar(q) method(glr) ///}{p_end}
{phang2}{cmd:      pi1(0.85) lambda1(0.15) lambda2(0.85) bootreps(999) seed(20261014)}{p_end}

{pstd}Faster while exploring{p_end}
{phang2}{cmd:. tvtpredreg y x, threshvar(q) method(glr) pi1(0.5) bootreps(199)}{p_end}

{pstd}Acting on the result{p_end}
{phang2}{cmd:. quietly tvtpredreg y x, threshvar(q) method(glr)}{p_end}
{phang2}{cmd:. display "p = " r(p) "   break at " r(k) "   threshold " r(r)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtpredreg} is {cmd:rclass} and stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}the statistic for the method chosen{p_end}
{synopt:{cmd:r(glr)}}the GLR statistic{p_end}
{synopt:{cmd:r(gf)}}the GF statistic{p_end}
{synopt:{cmd:r(p)}}bootstrap p-value{p_end}
{synopt:{cmd:r(reject)}}1 if the null is rejected at {opt level()}{p_end}
{synopt:{cmd:r(cv)}}, {cmd:r(cv10)}, {cmd:r(cv05)}, {cmd:r(cv01)}{p_end}
{synopt:{cmd:r(k)}}break date attaining the supremum{p_end}
{synopt:{cmd:r(r)}}threshold attaining the supremum{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(n_split)}}splits searched{p_end}
{synopt:{cmd:r(pi1)}}, {cmd:r(lambda1)}, {cmd:r(lambda2)},
{cmd:r(bootreps)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:tvtpredreg}{p_end}
{synopt:{cmd:r(method)}}{cmd:glr} or {cmd:gf}{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(predictors)}, {cmd:r(threshvar)}{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Zhu, F., M. Liu, S. Ling, and Z. Cai. 2023. Testing for structural change
of a predictive regression model to a threshold predictive regression
model. {it:Journal of Business & Economic Statistics} 41(1): 228-240.
{browse "https://doi.org/10.1080/07350015.2021.2008406":doi:10.1080/07350015.2021.2008406}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
