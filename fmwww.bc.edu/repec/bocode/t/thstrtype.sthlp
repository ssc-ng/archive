{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thstar" "help thstar"}{...}
{vieweralsosee "thnltest" "help thnltest"}{...}
{vieweralsosee "thstr" "help thstr"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thstrtype##syntax"}{...}
{viewerjumpto "Description" "thstrtype##description"}{...}
{viewerjumpto "Options" "thstrtype##options"}{...}
{viewerjumpto "How the rule works" "thstrtype##rule"}{...}
{viewerjumpto "Why not Terasvirta's sequence" "thstrtype##tp"}{...}
{viewerjumpto "Remarks" "thstrtype##remarks"}{...}
{viewerjumpto "Stored results" "thstrtype##results"}{...}
{viewerjumpto "Examples" "thstrtype##examples"}{...}
{viewerjumpto "References" "thstrtype##refs"}{...}
{viewerjumpto "Author" "thstrtype##author"}{...}

{title:Title}

{phang}
{bf:thstrtype} {hline 2} Choose between a logistic and an exponential smooth
transition


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thstrtype} {varname} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ar(numlist)}}autoregressive lags; required{p_end}
{synopt :{opt thv:ar(varname)}}transition variable; default is
L{it:delay}.{it:y}{p_end}
{synopt :{opt delay(#)}}delay when {cmd:thvar()} is not given; default
{cmd:delay(1)}{p_end}
{synopt :{opt xv:ars(varlist)}}extra exogenous regressors{p_end}
{synopt :{opt noconstant}}suppress the constant{p_end}

{syntab:Auxiliary regression}
{synopt :{opt ord:er(#)}}Taylor order, 3 or 4; default {cmd:order(4)}{p_end}
{synopt :{opt pars:imonious}}interact only the first power, as in NL3A/NL4A{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be {helpb tsset}.


{marker description}{title:Description}

{pstd}
{helpb thstar} asks you to pick {cmd:type(lstar)} or {cmd:type(estar)}, and
the choice is not cosmetic. A {bf:logistic} transition is {it:monotone} in
the transition variable: the dynamics differ between low and high values. An
{bf:exponential} transition is {it:symmetric} about its centre: the dynamics
differ between small and large deviations, in either direction. Those are
different stories about the data, and fitting both and keeping the better
likelihood is model selection by eye, not a procedure.

{pstd}
{cmd:thstrtype} applies the Escribano-Jorda (1999) selection rule. It also
reports the fourth-order linearity test the same auxiliary regression
provides, and, for comparison, the earlier Teräsvirta (1994) sequence.

{pstd}
Everything here is ordinary least squares and Stata's own {helpb test}
command on an auxiliary regression. There is no hand-rolled arithmetic,
because the entire procedure {it:is} a set of nested F tests.


{marker options}{title:Options}

{phang}
{opt ar(numlist)} gives the autoregressive lags of the linear part. They need
not be consecutive.

{phang}
{opt thvar(varname)} sets the transition variable explicitly, for a
smooth-transition regression rather than a smooth-transition
autoregression. Without it the transition variable is L{it:delay}.{it:y},
which is the usual STAR case.

{phang}
{opt order(#)} sets the Taylor order of the approximation to the transition
function. {cmd:order(4)} is the default and the paper's recommendation: the
fourth-order terms are exactly what gives the linearity test power against an
{it:exponential} transition, which a third-order expansion can miss.
{cmd:order(3)} reproduces the older Luukkonen-Saikkonen-Teräsvirta form.

{phang}
{opt parsimonious} uses the augmented first-order auxiliary regression
(NL3A/NL4A): the first power of the transition variable is interacted with
every regressor, but the higher powers enter on their own. With {it:p} lags
this needs {it:p}+3 terms instead of 4{it:p}+4. Every extra term costs the
test power, so this matters when {it:p} is large or the sample is short.
Teräsvirta's sequence is not reported in this form, because its three blocks
are not separately defined there.


{marker rule}{title:How the rule works}

{pstd}
Replace the transition function by a Taylor expansion and the auxiliary
regression becomes

{p 8 8 2}
y(t) = b0'x(t) + b1'x(t)z + b2'x(t)z^2 + b3'x(t)z^3 + b4'x(t)z^4 + u(t)

{pstd}
where x(t) holds the linear regressors and z is the transition variable. The
useful fact is which blocks vanish:

{p 8 11 2}
{bf:If the transition is LOGISTIC} and centred at zero, the {bf:even} blocks
b2 and b4 are exactly zero.{p_end}
{p 8 11 2}
{bf:If the transition is EXPONENTIAL} and centred at zero, the {bf:odd}
blocks b1 and b3 are exactly zero.{p_end}

{pstd}
So the rule tests both and compares the strength of the two rejections:

{p 8 11 2}1. F for H0E: b2 = b4 = 0 (the even powers){p_end}
{p 8 11 2}2. F for H0L: b1 = b3 = 0 (the odd powers){p_end}
{p 8 11 2}3. The smaller p-value wins. Smaller for H0L means the odd terms
are the ones carrying signal, which points to {bf:LSTAR}; smaller for H0E
points to {bf:ESTAR}.{p_end}

{pstd}
The two hypotheses are tested {bf:without conditioning on each other}, and
that is the point of the procedure rather than an incidental detail. See
below.

{pstd}
There is a bonus reading. Rejecting one hypothesis while failing to reject
the other also suggests the transition centre is near zero, which is useful
as a starting value when you go on to fit the model.


{marker tp}{title:Why not Teräsvirta's sequence}

{pstd}
Teräsvirta's (1994) rule tests three {it:nested} hypotheses in order {hline 2}
the cubic terms, then the quadratic terms given the cubic are zero, then the
linear terms given both are zero {hline 2} and selects on which p-value is
smallest. {cmd:thstrtype} reports it, because a great deal of applied work
used it and readers look for it.

{pstd}
Escribano and Jorda identify two problems with it, both of which bite when
the transition centre {bf:c is not zero}. First, expanding a logistic term
around a non-zero centre produces non-zero {it:quadratic} terms, so the
quadratic block stops being the exponential signature it is supposed to be.
Second, the conditioning restrictions in the sequence are then simply false,
and once a test conditions on a false restriction, the {it:order} of the
p-values {hline 2} which is the whole rule {hline 2} no longer means what it
is meant to mean.

{pstd}
When the two rules disagree, {cmd:thstrtype} says so explicitly. Prefer the
Escribano-Jorda answer, and report in the paper that the two disagreed rather
than quoting only the one you liked.


{marker remarks}{title:Remarks}

{pstd}
{bf:This is a selection rule, not a test of one type against the other.} The
two shapes are not nested, there is no null hypothesis "the transition is
logistic", and the command always returns one of the two answers. When the
two p-values are close, the lean is weak; fit both and compare. Treating a
narrow margin as a finding is the main way this procedure gets misused.

{pstd}
{bf:It is conditional on a prior rejection of linearity.} If the linearity
test does not reject, the rule is choosing between two nonlinear models when
the data support neither, and the command says so in the output. Do not
report a selected type from a series whose linearity was not rejected.

{pstd}
{bf:Powers of the transition variable get large.} z^4 on a series with a
spread of 10 reaches 10,000, and the auxiliary regression can become
ill-conditioned. The command counts any term Stata drops for collinearity and
warns, because a dropped term changes the degrees of freedom of every test
above it. If you see that warning, use {cmd:parsimonious} or fewer lags.

{pstd}
{bf:The delay is assumed known}, as in the paper. Running the command over
several delays and keeping the most significant is a search that none of the
p-values shown corrects for.

{pstd}
{bf:Relationship to} {helpb thnltest}: that command tests linearity against a
range of nonlinear alternatives and is where to start. {cmd:thstrtype} is for
the next question {hline 2} given that linearity is rejected and a smooth
transition is wanted, which shape.


{marker results}{title:Stored results}

{pstd}{cmd:thstrtype} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(F_lin)}, {cmd:r(p_lin)}, {cmd:r(df_lin)}}the linearity test{p_end}
{synopt:{cmd:r(F_even)}, {cmd:r(p_even)}, {cmd:r(df_even)}}H0E, the even powers{p_end}
{synopt:{cmd:r(F_odd)}, {cmd:r(p_odd)}, {cmd:r(df_odd)}}H0L, the odd powers{p_end}
{synopt:{cmd:r(F1)}, {cmd:r(F2)}, {cmd:r(F3)}}Teräsvirta's sequence{p_end}
{synopt:{cmd:r(p1)}, {cmd:r(p2)}, {cmd:r(p3)}}its p-values{p_end}
{synopt:{cmd:r(df_r)}}residual degrees of freedom of the auxiliary regression{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(order)}, {cmd:r(delay)}}as specified{p_end}
{synopt:{cmd:r(dropped)}}auxiliary terms dropped for collinearity{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:LSTAR} or {cmd:ESTAR}, the selection{p_end}
{synopt:{cmd:r(startype)}}{cmd:lstar} or {cmd:estar}, ready for {helpb thstar}{p_end}
{synopt:{cmd:r(type_tp)}}Teräsvirta's selection, when reported{p_end}
{synopt:{cmd:r(thvar)}}the transition variable used{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(depvar)}}{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}The usual case: an AR(1) with the first lag as the transition{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. thstrtype y, ar(1)}{p_end}
{phang2}{cmd:. thstar y, ar(1) type(`r(startype)')}{p_end}

{pstd}More lags, and the parsimonious auxiliary regression{p_end}
{phang2}{cmd:. thstrtype y, ar(1 2 3) parsimonious}{p_end}

{pstd}The older third-order form, to compare{p_end}
{phang2}{cmd:. thstrtype y, ar(1) order(3)}{p_end}

{pstd}An exogenous transition variable, for a smooth-transition regression{p_end}
{phang2}{cmd:. thstrtype y, ar(1 2) thvar(spread) xvars(x1 x2)}{p_end}

{pstd}Checking several delays {hline 2} remembering that choosing the most
significant is a search the p-values do not correct for{p_end}
{phang2}{cmd:. forvalues d = 1/4 {c -(}}{p_end}
{phang2}{cmd:.     quietly thstrtype y, ar(1) delay(`d')}{p_end}
{phang2}{cmd:.     display "d = `d'  linearity p = " r(p_lin) "  type = " "`r(type)'"}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker refs}{title:References}

{phang}
Escribano, A., and O. Jordá. 1999. Improved testing and specification of
smooth transition regression models. In {it:Nonlinear Time Series Analysis of
Economic and Financial Data}, ed. P. Rothman, 289-319. Boston: Springer.
{browse "https://doi.org/10.1007/978-1-4615-5129-4_14":doi:10.1007/978-1-4615-5129-4_14}

{phang}
Luukkonen, R., P. Saikkonen, and T. Teräsvirta. 1988. Testing linearity
against smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.1093/biomet/75.3.491":doi:10.1093/biomet/75.3.491}

{phang}
Teräsvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.2307/2291217":doi:10.2307/2291217}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
