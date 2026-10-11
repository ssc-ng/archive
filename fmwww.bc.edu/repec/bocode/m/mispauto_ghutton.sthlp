{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "ivregress postestimation" "help ivregress_postestimation"}{...}
{vieweralsosee "hausman" "help hausman"}{...}
{viewerjumpto "Syntax" "mispauto_ghutton##syntax"}{...}
{viewerjumpto "Description" "mispauto_ghutton##desc"}{...}
{viewerjumpto "Options" "mispauto_ghutton##options"}{...}
{viewerjumpto "The two stages" "mispauto_ghutton##stages"}{...}
{viewerjumpto "Interpreting the output" "mispauto_ghutton##interp"}{...}
{viewerjumpto "Remarks" "mispauto_ghutton##remarks"}{...}
{viewerjumpto "Examples" "mispauto_ghutton##examples"}{...}
{viewerjumpto "Stored results" "mispauto_ghutton##results"}{...}

{title:Title}

{phang}
{bf:mispauto ghutton} {hline 2} Godfrey and Hutton's (1994) two-stage procedure
for errors in variables and simultaneity


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto ghutton} {it:depvar} [{it:varlist1}]
{cmd:(}{it:varlist2} {cmd:=} {it:varlist_iv}{cmd:)} {ifin}
[{cmd:,} {it:options}]

{pstd}
{it:varlist1} holds the exogenous regressors, {it:varlist2} the regressors
suspected of being measured with error or jointly determined, and
{it:varlist_iv} the excluded instruments. The syntax is that of
{helpb ivregress}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lev:el(#)}}overall nominal level in percent; default
{cmd:level(5)}, split evenly between the stages{p_end}
{synopt :{opt pj(#)}}level for stage 1 alone, percent{p_end}
{synopt :{opt ph(#)}}level for stage 2 alone, percent{p_end}
{synopt :{opt haus:man(m)}}{cmd:contrast} or {cmd:augmented}; default
{cmd:contrast}{p_end}
{synopt :{opt notable}}suppress display{p_end}
{synoptline}

{pstd}
The equation must be {bf:overidentified}: the procedure needs at least one more
instrument than endogenous regressor, because stage 1 is identically zero
otherwise.


{marker desc}{...}
{title:Description}

{pstd}
A significant Hausman statistic is routinely read as evidence of simultaneity or
measurement error, and taken as a licence to present instrumental-variable
estimates. Godfrey and Hutton point out that this does not follow. Hausman's
test, like most tests aimed at a particular alternative, is sensitive to many
others; they show it has asymptotic local power against a broad class of
departures, and for most of those, re-estimating by IV "will not produce useful
results".

{pstd}
Their remedy is a nested pair of nulls, tested general to specific:

{p2colset 9 20 22 2}{...}
{p2col :{bf:Stage 1}}is errors in variables or simultaneity the {it:only}
misspecification{c 63} Equivalently: is the structural equation correctly
specified and are the instruments valid{c 63} Tested by the Sargan statistic
{cmd:J = n R2u}, with {cmd:Omega} left unrestricted.{p_end}
{p2col :{bf:Stage 2}}given that, is there any simultaneity or measurement error
at all{c 63} Tested by Hausman's statistic with {cmd:Omega = 0}.{p_end}
{p2colreset}{...}

{pstd}
They prove the two statistics are asymptotically independent under the stage-2
null, so the overall level is {cmd:1 - (1 - pJ)(1 - pH)}.


{marker options}{...}
{title:Options}

{phang}
{opt level(#)} splits evenly between the stages, so {cmd:level(5)} gives each
2.5%. The realised overall level is printed.

{phang}
{opt pj(#)} and {opt ph(#)} set the two levels directly and override
{opt level()}. Use them when the stages matter unequally: a cautious analyst
spends more on stage 1, since a wrong decision there is the expensive one.

{phang}
{opt hausman(m)} chooses the form of the stage-2 statistic.
{cmd:contrast}, the default, is their equation (10), the estimator contrast; it
is computed by Stata's own {helpb hausman} on stored OLS and IV fits.
{cmd:augmented} is their equation (11), the variable-addition form, computed by
{helpb ivregress postestimation##endogenous:estat endogenous}. They are
asymptotically equivalent. The built-in is called rather than reimplemented
because the generalized inverse used when the variance difference is not
positive definite is pivot-order dependent, and Stata's degrees-of-freedom
convention would not otherwise be reproduced.


{marker stages}{...}
{title:The two stages and what to do at each exit}

{p2colset 9 28 30 2}{...}
{p2col :{bf:Stage 1 rejects}}diagnosis {bf:RESPEC}. Stage 2 is not reached and
{bf:IV estimates should not be presented}. A significant {cmd:J} means the
overidentifying restrictions fail, so instrumenting does not repair the
equation. Reconsider the specification of the structural equation {it:and} the
validity of the excluded instruments; the test cannot tell you which is at
fault.{p_end}
{p2col :{bf:Stage 1 accepts, stage 2 rejects}}diagnosis {bf:EV/S}. The EV/S
formulation is adequate and {cmd:Omega} is not zero. {bf:Present the IV
estimates.}{p_end}
{p2col :{bf:Both accept}}diagnosis {bf:OLS}. No simultaneity and no measurement
error. {bf:Present the OLS estimates}, which are consistent and efficient
relative to IV here.{p_end}
{p2colreset}{...}


{marker interp}{...}
{title:Interpreting the output}

{pstd}
The header reports {cmd:k}, the number of instruments {cmd:p}, and the number
of overidentifying restrictions {cmd:p - k}, which is the degrees of freedom of
stage 1. With only one overidentifying restriction the stage-1 test is weak;
treat an acceptance there as uninformative rather than as support.

{pstd}
When stage 1 rejects, the stage-2 row prints {cmd:not reached} rather than a
number. This is deliberate: their section 2 explains that computing the Hausman
statistic anyway and reporting it alongside would invite exactly the inference
the procedure exists to prevent.

{pstd}
{bf:The command restores your previous estimation results.} It fits OLS and
2SLS internally and stores them under temporary names; whatever was in
{cmd:e()} before the call is put back afterwards.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:This answers a different question from the other three subcommands.} They
ask what a significant Durbin{c 150}Watson statistic means; this one asks what
a significant Hausman statistic means. Running both is sensible when a
time-series equation has an endogenous regressor: a failure of stage 1 and a
rejection by {helpb mispauto_godfrey:mispauto godfrey} point at the same thing
from two directions.

{pstd}
{bf:The asymptotic independence of the two statistics is proved only under the
stage-2 null.} The overall level {cmd:1 - (1 - pJ)(1 - pH)} is therefore exact
only when {cmd:Omega = 0}. Under the stage-1 null with {cmd:Omega} non-zero it
is not established, and the paper does not claim it is.

{pstd}
{bf:Why not simply test everything at once{c 63}} Their section 2 answers this.
Under the stage-1 null with {cmd:Omega} non-zero, OLS estimation of the fully
augmented equation yields inconsistent estimators, and the restrictions would be
rejected with probability tending to one as the sample grows. An IV test of the
same restrictions has an asymptotic rejection probability equal to the chosen
level. The general-to-specific ordering is what makes the first stage
informative.

{pstd}
{bf:The statistic Stata reports as Sargan's is theirs exactly.}
{cmd:estat overid} after {cmd:ivregress 2sls} computes
{cmd:N*(1 - rss/eqnrss)}, which is {cmd:n} times the uncentred R-squared from
regressing the IV residual on the full instrument list -- their equation (13).
The equivalence is set out in {helpb mispauto_methods:mispauto methods}.

{pstd}
{bf:Their own example.} In their section 3 they revisit an Australian wine
supply equation from Maddala (1992) for which the Hausman statistic is
significant at the 1% level with either of two instruments, and Maddala
concludes the price is endogenous. Using both instruments together they obtain
{cmd:J = 6.73}, significant at the 1% level on one degree of freedom, and
conclude that "there is no real point in proceeding to the second stage" and
that the specification of the supply function should be reconsidered instead.
That dataset is not distributed with this package.


{marker examples}{...}
{title:Examples}

{pstd}One endogenous regressor, two instruments{p_end}
{phang2}{cmd:. mispauto ghutton y x1 (x2 = z1 z2)}{p_end}

{pstd}Spend the level unevenly, favouring stage 1{p_end}
{phang2}{cmd:. mispauto ghutton y x1 (x2 = z1 z2), pj(4) ph(1)}{p_end}

{pstd}The variable-addition form of the Hausman test{p_end}
{phang2}{cmd:. mispauto ghutton y x1 (x2 = z1 z2), hausman(augmented)}{p_end}

{pstd}Act on the verdict in a do-file{p_end}
{phang2}{cmd:. mispauto ghutton y x1 (x2 = z1 z2), notable}{p_end}
{phang2}{cmd:. if "`r(verdict)'" == "EV/S" ivregress 2sls y x1 (x2 = z1 z2)}{p_end}
{phang2}{cmd:. else if "`r(verdict)'" == "OLS" regress y x1 x2}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of coefficients{p_end}
{synopt:{cmd:r(p_inst)}}number of instruments{p_end}
{synopt:{cmd:r(n_overid)}}overidentifying restrictions, {cmd:p - k}{p_end}
{synopt:{cmd:r(level)}}, {cmd:r(alpha_overall)} nominal and realised levels{p_end}
{synopt:{cmd:r(J)}}, {cmd:r(df_J)}, {cmd:r(p_J)}, {cmd:r(sig_J)} stage 1{p_end}
{synopt:{cmd:r(H)}}, {cmd:r(df_H)}, {cmd:r(p_H)}, {cmd:r(sig_H)} stage 2,
missing if not reached{p_end}
{synopt:{cmd:r(stage2)}}1 if stage 2 was reached{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:RESPEC}, {cmd:EV/S} or {cmd:OLS}{p_end}
{synopt:{cmd:r(endog)}}, {cmd:r(exog)}, {cmd:r(inst)} the variable lists{p_end}
{synopt:{cmd:r(hausman)}}form of the stage-2 statistic used{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
