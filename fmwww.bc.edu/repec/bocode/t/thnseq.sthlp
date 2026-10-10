{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thnregimes" "help thnregimes"}{...}
{vieweralsosee "thselect" "help thselect"}{...}
{vieweralsosee "thtarsel" "help thtarsel"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thnseq##syntax"}{...}
{viewerjumpto "Description" "thnseq##description"}{...}
{viewerjumpto "Options" "thnseq##options"}{...}
{viewerjumpto "Why no bootstrap is needed" "thnseq##why"}{...}
{viewerjumpto "The shrinking level" "thnseq##level"}{...}
{viewerjumpto "Which of the three to use" "thnseq##which"}{...}
{viewerjumpto "Remarks" "thnseq##remarks"}{...}
{viewerjumpto "Stored results" "thnseq##results"}{...}
{viewerjumpto "Examples" "thnseq##examples"}{...}
{viewerjumpto "References" "thnseq##refs"}{...}
{viewerjumpto "Author" "thnseq##author"}{...}

{title:Title}

{phang}
{bf:thnseq} {hline 2} Number of regimes by the Strikholm-Teräsvirta
sequential procedure


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thnseq} {varname} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{p 8 15 2}
{cmd:thnseq} {varname} {ifin}{cmd:,} {opt xv:ars(varlist)}
{opt thresh:var(varname)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ar(numlist)}}autoregressive lags, for a self-exciting model{p_end}
{synopt :{opt xv:ars(varlist)}}regressors, for a threshold regression{p_end}
{synopt :{opt thresh:var(varname)}}threshold variable; default is
L{it:delay}.{it:y}{p_end}
{synopt :{opt delay(#)}}delay when {cmd:threshvar()} is not given; default
{cmd:delay(1)}{p_end}
{synopt :{opt noconstant}}suppress the regime constants{p_end}

{syntab:The sequence}
{synopt :{opt mmax(#)}}most thresholds to consider, 1 to 6; default
{cmd:mmax(3)}{p_end}
{synopt :{opt al:pha(#)}}significance level of the FIRST test; default
{cmd:alpha(0.05)}{p_end}
{synopt :{opt tau(#)}}level shrinkage per stage, in (0,1]; default
{cmd:tau(0.5)}{p_end}
{synopt :{opt ord:er(#)}}Taylor order 1, 3 or 4; default {cmd:order(3)}{p_end}

{syntab:Threshold estimation}
{synopt :{opt trim(#)}}quantile trimming; default {cmd:trim(0.15)}{p_end}
{synopt :{opt mino:bs(#)}}minimum observations per regime{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{title:Description}

{pstd}
{cmd:thnseq} determines how many thresholds a model needs, by the sequential
procedure of Strikholm and Teräsvirta (2006). It tests linearity; if that is
rejected it estimates one threshold and tests again, now treating that
threshold as known; and it continues until the first non-rejection. The
number of rejections is the number of thresholds.

{pstd}
Every test in the sequence is an ordinary Taylor-expansion linearity test
with a chi-squared limit. {bf:No bootstrap is used anywhere}, which is what
makes this much faster than {helpb thnregimes}, and the reason is worth
understanding before relying on it.


{marker why}{title:Why no bootstrap is needed}

{pstd}
Testing for an extra regime normally runs into the Davies problem: the new
threshold does not appear in the model under the null, so it is not
identified, the statistic is a supremum over a grid, and its distribution
has to be simulated. That is what {helpb thnregimes} does.

{pstd}
This procedure sidesteps it. Chan (1993) showed that threshold estimates are
{bf:super-consistent}: they converge at rate {it:T} rather than the root-{it:T}
of everything else. Strikholm and Teräsvirta add the part that makes a
{it:sequence} work {hline 2} the estimates stay super-consistent {bf:even
when fewer thresholds are fitted than the truth}.

{pstd}
So at each stage the thresholds already found can be treated as {bf:known}
constants. The current model is then just a linear model in regime-interacted
regressors, and "is there one more regime?" is an ordinary linearity test
against an additional smooth transition. Its asymptotic significance level is
the usual one.

{pstd}
The price is that this is an asymptotic argument resting on a rate. In short
samples the first threshold is not estimated nearly well enough to be treated
as known, and the sequence inherits that. On a few hundred observations,
check the answer against {helpb thnregimes}.


{marker level}{title:The shrinking level}

{pstd}
The first test uses {cmd:alpha()}. Each later test uses {cmd:tau()} times the
level of the one before, so with the defaults the sequence runs at 0.05,
0.025, 0.0125, and so on.

{pstd}
This is deliberate and it is not a tuning knob to be switched off. Each stage
is conditional on all the previous ones having rejected, so a fixed level
would let the overall error rate grow with the length of the sequence; and
the procedure is {bf:consistent} only because {cmd:alpha()} is meant to fall
with the sample size. Keeping a fixed 5% at every stage will go on finding
regimes in a long enough series.

{pstd}
{cmd:tau()} above 1 is refused, because it would make each later test
{it:easier} to pass and systematically over-state the number of regimes.


{marker which}{title:Which of the three to use}

{pstd}
The package answers "how many regimes?" three ways, and they are not
interchangeable.

{p2colset 6 22 24 2}{...}
{p2col :{helpb thnseq}}sequential linearity tests, no bootstrap. Fast. Rests
on super-consistency, so it wants a reasonably long series.{p_end}
{p2col :{helpb thnregimes}}the full F(j|i) triangle with a bootstrap. Slow,
and the most defensible in a short sample.{p_end}
{p2col :{helpb thselect}}information criteria, plus a sequential bootstrap
F(m+1|m). Use when you want a criterion rather than a test.{p_end}
{p2colreset}{...}

{pstd}
They can disagree. If they do, report that they did rather than quoting the
one you preferred, and prefer the bootstrap answer in a short sample.
{helpb thtarsel} handles the joint choice of order, delay and regime count
for a SETAR.


{marker remarks}{title:Remarks}

{pstd}
{bf:The sequence stops at the first non-rejection, by construction.} It does
not look past it. If the true model has a weak second threshold and a strong
third, this will stop at one.

{pstd}
{bf:Reaching} {cmd:mmax()} {bf:still rejecting is not an answer.} It means
the sequence never terminated, and the command says so. Raise {cmd:mmax()},
or treat the result as evidence that the threshold model is misspecified in
some other way {hline 2} neglected dynamics show up as spurious extra
regimes.

{pstd}
{bf:On} {cmd:order()}. The Taylor expansion runs over z, z-squared and
z-cubed at {cmd:order(3)}, the Luukkonen-Saikkonen-Teräsvirta default. The
quadratic block is present even though the raw expansion of a logistic
transition has vanishing square powers, because the auxiliary regression is
written in the identified parameters after recombination.
{cmd:order(4)} adds the quartic terms, which carry power against an
exponential-shaped transition; see {helpb thstrtype}.

{pstd}
{bf:The threshold estimates come from} {helpb thregress}, re-run at each
stage with one more threshold. Your own estimation results are saved and
restored, so running {cmd:thnseq} does not disturb whatever is in
{cmd:e()}.

{pstd}
{bf:The p-values shown are not corrected for the sequence.} Each is the
p-value of its own test. That is how the procedure is defined, and the
shrinking level is the mechanism that controls the sequence; do not read the
individual p-values as if each were a standalone finding.


{marker results}{title:Stored results}

{pstd}{cmd:thnseq} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(m)}}thresholds selected{p_end}
{synopt:{cmd:r(regimes)}}regimes selected, which is {cmd:r(m)}+1{p_end}
{synopt:{cmd:r(gamma1)}, {cmd:r(gamma2)}}the first two thresholds, when found{p_end}
{synopt:{cmd:r(stopped)}}1 if the sequence terminated on a non-rejection{p_end}
{synopt:{cmd:r(nfit)}}threshold models fitted along the way{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(alpha)}, {cmd:r(tau)}, {cmd:r(order)}, {cmd:r(mmax)}}as specified{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thnseq}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(thvar)}}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(gammas)}}the thresholds found{p_end}
{synopt:{cmd:r(F)}, {cmd:r(p)}}the test at each stage{p_end}
{synopt:{cmd:r(levels)}}the significance level used at each stage{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}A SETAR: how many regimes?{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. thnseq y, ar(1 2)}{p_end}

{pstd}Then fit what it chose{p_end}
{phang2}{cmd:. thregress y L.y L2.y, threshvar(L.y) nthresh(`r(m)')}{p_end}

{pstd}A threshold regression with an exogenous threshold variable{p_end}
{phang2}{cmd:. thnseq y, xvars(x1 x2) threshvar(z)}{p_end}

{pstd}A stricter sequence, and room for more regimes{p_end}
{phang2}{cmd:. thnseq y, ar(1) alpha(0.01) tau(0.5) mmax(5)}{p_end}

{pstd}The fourth-order expansion, for power against a symmetric transition{p_end}
{phang2}{cmd:. thnseq y, ar(1) order(4)}{p_end}

{pstd}Cross-checking against the bootstrap procedure, which is the right
thing to do in a short sample{p_end}
{phang2}{cmd:. thnseq y, ar(1)}{p_end}
{phang2}{cmd:. thnregimes y, ar(1) reps(499)}{p_end}


{marker refs}{title:References}

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics} 21:
520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based
inference in single and multiple threshold models. {it:Journal of
Econometrics} 110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}

{phang}
Luukkonen, R., P. Saikkonen, and T. Teräsvirta. 1988. Testing linearity
against smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.1093/biomet/75.3.491":doi:10.1093/biomet/75.3.491}

{phang}
Strikholm, B., and T. Teräsvirta. 2006. A sequential procedure for
determining the number of regimes in a threshold autoregressive model.
{it:Econometrics Journal} 9: 472-491.
{browse "https://doi.org/10.1111/j.1368-423X.2006.00194.x":doi:10.1111/j.1368-423X.2006.00194.x}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
