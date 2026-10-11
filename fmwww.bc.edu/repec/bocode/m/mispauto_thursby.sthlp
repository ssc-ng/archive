{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "mispauto godfrey" "help mispauto_godfrey"}{...}
{vieweralsosee "mispauto knottnerus" "help mispauto_knottnerus"}{...}
{viewerjumpto "Syntax" "mispauto_thursby##syntax"}{...}
{viewerjumpto "Description" "mispauto_thursby##desc"}{...}
{viewerjumpto "Options" "mispauto_thursby##options"}{...}
{viewerjumpto "The decision rule" "mispauto_thursby##rule"}{...}
{viewerjumpto "Interpreting the output" "mispauto_thursby##interp"}{...}
{viewerjumpto "Remarks" "mispauto_thursby##remarks"}{...}
{viewerjumpto "Examples" "mispauto_thursby##examples"}{...}
{viewerjumpto "Stored results" "mispauto_thursby##results"}{...}

{title:Title}

{phang}
{bf:mispauto thursby} {hline 2} Thursby's (1981) three-procedure test strategy


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto thursby} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt lev:el(#)}}overall nominal level in percent; default {cmd:level(5)}{p_end}
{synopt :{opt slrs}}run only the S-test in LRS, dropping the LR stage{p_end}

{syntab:RESET}
{synopt :{opt resetv:ars(set)}}{cmd:pox}, {cmd:poy}, {cmd:ts} or {cmd:pc};
default {cmd:pox}{p_end}
{synopt :{opt resetp:owers(numlist)}}powers to use; default {cmd:2 3 4}{p_end}
{synopt :{opt resetmod}}apply Porter and Kashyap's (1984) autocorrelation
correction to RESET{p_end}

{syntab:Durbin-Watson}
{synopt :{opt dws:ide(side)}}{cmd:lower}, {cmd:upper} or {cmd:two}; default
{cmd:lower}{p_end}
{synopt :{opt dwp(method)}}{cmd:imhof} for the exact p-value or {cmd:normal};
default {cmd:imhof}{p_end}
{synopt :{opt maxt:dw(#)}}largest T for which the exact p-value is computed;
default {cmd:1000}{p_end}

{syntab:LRS}
{synopt :{opt rte:method(m)}}restricted fit: {cmd:durbin}, {cmd:corc} or
{cmd:prais}; default {cmd:durbin}{p_end}
{synopt :{opt nomiss0}}drop, rather than zero-fill, leading missing lagged
residuals{p_end}

{syntab:Reporting}
{synopt :{opt g:raph}}draw the annotated residual correlogram{p_end}
{synopt :{opt n:ame(string)}}name for the graph{p_end}
{synopt :{opt notable}}suppress display; still return everything in {cmd:r()}{p_end}
{synoptline}

{pstd}
The data must be {helpb tsset}. With no varlist the model is read from the last
{helpb regress}.


{marker desc}{...}
{title:Description}

{pstd}
{cmd:mispauto thursby} runs the three procedures of Thursby (1981) and resolves
them into one of four diagnoses by his eight-cell rule.

{p2colset 9 20 22 2}{...}
{p2col :{bf:D}}the Durbin{c 150}Watson test on the original regression. A
significant value means nonrandom disturbances {it:or} misspecification.{p_end}
{p2col :{bf:R}}RESET. A significant value means misspecification.{p_end}
{p2col :{bf:L}}the LRS procedure: Durbin's S-test applied to the unrestricted
transformed equation, followed, if that is insignificant, by a likelihood-ratio
test of the nonlinear restrictions an AR(1) process imposes. A significant value
from either means misspecification {it:or} non-AR(1) autocorrelation.{p_end}
{p2colreset}{...}

{pstd}
Because three tests are run, each is applied at a stricter level than the
headline figure, by Thursby's equations (8) and (6). The realised levels are
printed in the header. See {helpb mispauto_methods:mispauto methods} for the
derivation of every step.


{marker options}{...}
{title:Options}

{phang}
{opt level(#)} is the level of the {it:strategy}, not of each test. With
{cmd:level(5)} each of the three procedures runs at
{cmd:1 - 0.95^(1/3) = 1.6952%} and each of the two LRS tests at
{cmd:1 - sqrt(1 - 0.016952) = 0.8512%}.

{phang}
{opt slrs} drops the likelihood-ratio stage and runs the S-test at the full
procedure level. Knottnerus proved the LR stage has asymptotic power equal to
its size whatever the error process, and Thursby's reply concedes the point
while reporting, from an unpublished 1983 mimeo, that dropping it costs about
two percentage points of power in most of his designs. That claim cannot be
verified from published sources and is attributed, not asserted.

{phang}
{opt resetmod} replaces the plain RESET with the modification Porter and
Kashyap (1984) propose in their section 3 and evaluate in their Table 3: the
autocorrelation parameter is estimated in both the maintained and the augmented
model by one-step Cochrane{c 150}Orcutt and the test is applied to the
quasi-differenced models. Their Table 3 shows this restores correct size in
every cell where the plain test fails. Use it whenever the Durbin{c 150}Watson
row rejects and the regressors are themselves persistent.

{phang}
{opt dwside(side)} chooses the tail. {cmd:lower} tests against positive
autocorrelation, which is what Thursby's designs assume and what the classical
{cmd:dL}/{cmd:dU} tables are built for. Use {cmd:two} when misspecification,
rather than AR(1), is the alternative you really have in mind.

{phang}
{opt dwp(method)} selects the p-value. {cmd:imhof} inverts the characteristic
function exactly, following Imhof (1961); it needs a T by T eigendecomposition
and is therefore capped by {opt maxtdw()}. {cmd:normal} uses the large-sample
result that {cmd:(1 - d/2)} is approximately normal with variance {cmd:1/T}.

{phang}
{opt rtemethod(m)} chooses how the restricted equation is fitted.
{cmd:durbin}, the default, applies the transform Thursby writes out in step 3
of his section II.B. Thursby reports that Cochrane{c 150}Orcutt and Durbin's
procedure made almost no difference in his experiments.


{marker rule}{...}
{title:The decision rule}

{pstd}
With D, R, L for insignificant and D', R', L' for significant, Thursby's table
on page 118 maps all eight outcomes:

{p 12 20 2}
{cmd:D  R  L   ->  NP}{break}
{cmd:D' R  L   ->  AR(1)}{break}
{cmd:D  R  L'  ->  NAR}{break}
{cmd:D' R  L'  ->  NAR}{break}
{cmd:D  R' L   ->  MS}{break}
{cmd:D  R' L'  ->  MS}{break}
{cmd:D' R' L   ->  MS}{break}
{cmd:D' R' L'  ->  MS}

{pstd}
Equivalently: a significant RESET always means {bf:MS}; otherwise a significant
LRS means {bf:NAR}; otherwise a significant Durbin{c 150}Watson means
{bf:AR(1)}; otherwise {bf:NP}. The pattern realised is printed and returned in
{cmd:r(pattern)}.


{marker interp}{...}
{title:Interpreting the output}

{pstd}
Read the {bf:Outcome} column, not the stars: the stars mark the conventional
10/5/1 per cent levels while the outcome column applies the adjusted level in
the header. A p-value of 0.03 earns two stars and still accepts.

{pstd}
The {cmd:rho-hat from the UTE} figure at the foot is {cmd:b(2k+1)} from
equation (2), the implied first-order autoregressive parameter. If the diagnosis
is {bf:AR(1)} this is the value a Cochrane{c 150}Orcutt correction will be
working with; a value near one is a warning that the real problem may be
nonstationarity rather than autocorrelation.

{pstd}
Two cautions print automatically. One appears when the LR stage rejects,
restating the Knottnerus result. The other appears whenever RESET rejects,
because of the Porter and Kashyap evidence. Neither is boilerplate; act on
them.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:This procedure has documented failure modes and the command does not hide
them.} Run {helpb mispauto_knottnerus:mispauto knottnerus} on the same equation
before you report a Thursby diagnosis. In particular:

{phang2}
{bf:1.} If the first-order residual autocorrelation is near zero but the errors
are seasonally dependent, this procedure returns {bf:NP}. It cannot do otherwise.

{phang2}
{bf:2.} If the second-order autocorrelation is close to the square of the
first, genuinely non-AR(1) errors are returned as {bf:AR(1)}.

{phang2}
{bf:3.} An omitted regressor orthogonal to everything in the model is invisible
to RESET, and the procedure tends to return {bf:AR(1)} instead of {bf:MS}
because the omitted series behaves like an autocorrelated disturbance. Thursby
reports exactly this for his own models 13 and 14.

{pstd}
{bf:Thursby's own application.} In his section V he applies RESET and LRS to the
regression in which Durbin and Watson (1951) found a significant
Durbin{c 150}Watson statistic, and finds {it:both} significant at the 1% level,
concluding that the correct response is to respecify rather than to correct for
AR(1). That dataset is not distributed with this package.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mispauto thursby y x1 x2}{p_end}
{phang2}{cmd:. mispauto thursby y x1 x2, level(10) graph}{p_end}
{phang2}{cmd:. mispauto thursby y x1 x2, slrs}{p_end}
{phang2}{cmd:. mispauto thursby y x1 x2, resetmod dwside(two)}{p_end}
{phang2}{cmd:. mispauto thursby y x1 x2, resetvars(poy) resetpowers(2 3)}{p_end}

{pstd}After {helpb regress}{p_end}
{phang2}{cmd:. regress y x1 x2}{p_end}
{phang2}{cmd:. mispauto thursby}{p_end}

{pstd}Collecting the verdict for a table{p_end}
{phang2}{cmd:. mispauto thursby y x1 x2, notable}{p_end}
{phang2}{cmd:. display "`r(verdict)' from pattern `r(pattern)'"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:mispauto thursby} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(level)}}nominal overall level, percent{p_end}
{synopt:{cmd:r(alpha_each)}}adjusted level for each procedure, eq.(8){p_end}
{synopt:{cmd:r(alpha_lrs)}}adjusted level within LRS, eq.(6){p_end}
{synopt:{cmd:r(dw)}}Durbin{c 150}Watson statistic{p_end}
{synopt:{cmd:r(p_dw)}}its p-value{p_end}
{synopt:{cmd:r(sig_dw)}}1 if D rejects{p_end}
{synopt:{cmd:r(F_reset)}}RESET F statistic{p_end}
{synopt:{cmd:r(df_reset)}}, {cmd:r(df_r_reset)} its degrees of freedom{p_end}
{synopt:{cmd:r(p_reset)}}its p-value{p_end}
{synopt:{cmd:r(sig_reset)}}1 if R rejects{p_end}
{synopt:{cmd:r(F_s)}}, {cmd:r(p_s)}, {cmd:r(sig_s)} Durbin's S-test{p_end}
{synopt:{cmd:r(lr)}}, {cmd:r(df_lr)}, {cmd:r(p_lr)}, {cmd:r(sig_lr)} the LR of
eq.(4){p_end}
{synopt:{cmd:r(sig_lrs)}}1 if the LRS procedure rejects{p_end}
{synopt:{cmd:r(rho)}}{cmd:b(2k+1)} from the UTE{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:NP}, {cmd:AR(1)}, {cmd:NAR} or {cmd:MS}{p_end}
{synopt:{cmd:r(pattern)}}the realised eight-cell pattern, e.g. {cmd:D' R L'}{p_end}
{synopt:{cmd:r(resetvars)}}, {cmd:r(resetpowers)} the test variables used{p_end}
{synopt:{cmd:r(dwmethod)}}how the Durbin{c 150}Watson p-value was obtained{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
