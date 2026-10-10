{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "freeiv" "help freeiv"}{...}
{vieweralsosee "freeivmenu" "help freeivmenu"}{...}
{vieweralsosee "freeivtest" "help freeivtest"}{...}
{title:Title}

{phang}
{bf:freeivdiag} {hline 2} What a value of gamma implies about the model


{title:Syntax}

{p 8 17 2}
{cmd:freeivdiag} [{cmd:, gamma(}{it:#}{cmd:)}]

{pstd}after {helpb freeiv} with one endogenous regressor.


{title:Description}

{pstd}
The second-order system pins theta = a2^2 Var(U), Var(V1) and Var(V2) as
functions of gamma {it:alone}:

{p 8 8 2}theta = m02 (gamma-tilde - gamma)/gamma{p_end}
{p 8 8 2}Var(V2) = m02 - theta{p_end}
{p 8 8 2}Var(V1) = m20 - gamma^2 m02 - 3 gamma^2 theta{p_end}

{pstd}
The diagnostic is therefore {it:method free}.  Hand it the estimate from the
qme, the hme, the GMM, Lewbel (2012), LSZ or a published paper, and it says
what that number implies about the unobservables.  With no option it uses
{cmd:e(gamma)}; {cmd:gamma(}{it:#}{cmd:)} evaluates any outside value.

{pstd}
{bf:The interval IS the positivity region.}  With c = theta/m02, the
confounder's share of the first-stage residual variance,

{p 8 8 2}gamma-tilde - gamma = gamma c{space 13}so theta >= 0 iff gamma <= gamma-tilde{p_end}
{p 8 8 2}gamma - gamma-tilde/2 = gamma (1 - c)/2{space 2}so Var(V2) >= 0 iff gamma >= gamma-tilde/2{p_end}

{pstd}
that is, gamma-tilde = gamma (1 + c) with c in [0, 1].  An estimate outside the
interval therefore implies a negative variance, mechanically -- c then leaves
[0, 1] -- and the command says so.  That is the head-on comparison between a
route that imposes scale consistency and one that does not.


{title:What it prints}

{p2colset 5 24 26 2}{...}
{p2col:{bf:position}}where gamma sits in the interval, or a warning that it is
outside.{p_end}
{p2col:{bf:nuisances}}theta, Var(V2), Var(V1), flagged when negative, and c,
flagged when outside [0, 1].{p_end}
{p2col:{bf:third moment}}A = a2^3 E[U^3] and B = E[V2^3], recovered from
A = m12/gamma - m03 and B = 2 m03 - m12/gamma, and mu = A/(A+B).  B = 0 is the
hme's assumption; mu near 1/3 (B = 2A) is where the qme degenerates.{p_end}
{p2col:{bf:kurtosis}}the identified kurtosis of the confounder, when theta is
positive.  Outside 3 to 10 is a warning about the one-factor structure.{p_end}
{p2colreset}{...}

{pstd}
At the exact ends of the interval theta or Var(V2) is zero up to machine
rounding; a relative tolerance prevents a spurious NEGATIVE flag there.


{title:Examples}

{pstd}These run on data that ship with Stata{p_end}
{phang2}{stata "sysuse nlsw88, clear":. sysuse nlsw88, clear}{p_end}
{phang2}{stata "generate lwage = ln(wage)":. generate lwage = ln(wage)}{p_end}
{phang2}{stata "freeiv lwage grade age i.race (tenure)":. freeiv lwage grade age i.race (tenure)}{p_end}
{phang2}{stata "freeivdiag":. freeivdiag}{p_end}

{pstd}What an estimate obtained elsewhere would imply{p_end}
{phang2}{stata "freeivdiag, gamma(0.03)":. freeivdiag, gamma(0.03)}{p_end}

{pstd}What the ends of the interval imply{p_end}
{phang2}{stata "freeivdiag, gamma(`=e(lo)')":. freeivdiag, gamma(`=e(lo)')}{p_end}
{phang2}{stata "freeivdiag, gamma(`=e(hi)')":. freeivdiag, gamma(`=e(hi)')}{p_end}


{title:Stored results}

{pstd}
{cmd:freeivdiag} is {cmd:rclass} and returns {cmd:r(gamma)}, {cmd:r(theta)},
{cmd:r(sV1)}, {cmd:r(sV2)}, {cmd:r(cshare)}, {cmd:r(A)}, {cmd:r(B)},
{cmd:r(mu)}, {cmd:r(kurtU)}, {cmd:r(lo)}, {cmd:r(hi)}, {cmd:r(inbounds)} and
{cmd:r(source)}.


{title:Author}

{pstd}
Abdelkrim Araar, Universite Laval and PEP{break}
{browse "mailto:aabd@ecn.ulaval.ca":aabd@ecn.ulaval.ca}


{title:Also see}

{psee}
Online: {helpb freeiv}, {helpb freeivmenu}, {helpb freeivtest}
{p_end}
