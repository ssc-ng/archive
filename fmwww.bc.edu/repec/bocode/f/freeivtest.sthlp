{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "freeiv" "help freeiv"}{...}
{vieweralsosee "freeivmenu" "help freeivmenu"}{...}
{vieweralsosee "freeivdiag" "help freeivdiag"}{...}
{title:Title}

{phang}
{bf:freeivtest} {hline 2} Endogeneity, agreement between routes, and an
outside estimate against the identified set


{title:Syntax}

{p 8 17 2}
{cmd:freeivtest} [{cmd:, gamma(}{it:#}{cmd:)} {cmd:segamma(}{it:#}{cmd:)}]

{pstd}after {helpb freeiv}.


{title:Description}

{pstd}
After the one-endogenous model, three blocks, in the order they should be
read.  After the two-indicator model, the three tests that model carries (see
the last section).  Under {cmd:vce(svy)} the covariance is the design's, the z
become t on the design degrees of freedom d, and the Wald of block 1 becomes
the adjusted F = (d - 1) W/(2d) on (2, d - 1) degrees of freedom, as
{cmd:svy} reports it.


{title:1.  Is there any endogeneity at all}

{pstd}
Under theta = 0 the confounder is absent, so eps2 = V2 and the OLS residual
r = xi - gamma-tilde eps2 equals V1, which is {it:independent} of eps2 -- not
merely uncorrelated, which is true by construction.  Independence is
refutable, and two third-order cross-moments must then vanish:

{p 8 8 2}E[r eps2^2] = m12 - gt m03{p_end}
{p 8 8 2}E[r^2 eps2] = m21 - 2 gt m12 + gt^2 m03{p_end}

{pstd}
The Wald statistic on the pair is chi2 with 2 df.
{bf:It never estimates gamma}, so it keeps its power exactly where the qme loses its own: on
{cmd:freeiv_sim2} the discriminant is negative and the qme has no real root,
yet the test rejects at p = 0.0004.  In simulation it holds its size (0.060 at
n = 526, 0.047 at n = 5000, for a nominal 5%).

{pstd}
Both moments vanish identically when m03 = 0, that is when U and V2 are both
symmetric.  There the test has no power {it:by construction}, and the case is
visible beforehand as a z of m03 near zero in {helpb freeivmenu}.  Read that
first.  Detecting a confounder needs only m03 != 0, from U or from V2;
measuring g needs more, so detection can succeed where estimation fails.

{pstd}
The test maintains the linear one-factor specification, so a rejection is
evidence of theta > 0 {it:or} of a departure from that structure.


{title:2.  Do the routes agree}

{pstd}
Every closed form is a smooth function of the same moment vector, so one
covariance matrix serves them all and the difference of any two has variance
(g_a - g_b)' V (g_a - g_b)/n.  Each pair tests the assumption that separates
the two routes:

{p2colset 8 24 26 2}{...}
{p2col:{bf:qme - ols}}theta = 0, no confounding{p_end}
{p2col:{bf:qme - hme}}B = 0, symmetry of V2{p_end}
{p2colreset}{...}

{pstd}
The qme is the reference because its assumptions are the weakest; when the
discriminant is negative the vertex takes its place, and its pairs are then
read as rough.  A large |z| rejects the assumption that separates the pair; a
small one is mutual corroboration between two routes with different
assumptions.

{pstd}
{cmd:qme - ols} is {it:not} the right endogeneity test: it needs the qme to
exist and inherits its 1/sqrt(D) imprecision.  On Wooldridge's wage1, lwage on
educ with exper, it gives p = 0.36 while block 1 gives p = 0.0002 on the same
data.


{title:3.  An outside estimate against the identified set}

{pstd}
{cmd:gamma(}{it:#}{cmd:)} takes an estimate produced by any other method --
LSZ, Lewbel (2012), a published paper, a genuine instrument -- and asks whether
the scale-consistent model can produce it at all.  Outside the interval it
cannot, without a negative variance; {helpb freeivdiag} says which one.  The
distance to the nearer end is divided by that end's standard error, and
{cmd:segamma(}{it:#}{cmd:)} adds the outside estimate's own, treating the two as
independent, which they are not.  A point outside the interval need not be
significantly outside: read the z.


{title:After the two-indicator model}

{pstd}
{cmd:freeivtest} gathers the three tests of model B in one table, with their
p-values: scale consistency (a1 against g2 a2 + g3 a3), the one-factor test
(R1 - R3, which needs symmetric V2 and V3 as well, and has little power when
the two third-order cross-moments are not both measured), and the J of the
sixteen-moment GMM on 4 degrees of freedom.  {cmd:gamma()} and
{cmd:segamma()} do not apply there.


{title:What is NOT tested here}

{pstd}
No pair of block 2 tests scale consistency: the map from gamma to the
nuisances is derived from a1 = g a2, so every statistic presupposes it.  At
second order it is untestable outright, the interval being exactly the
positivity region.

{pstd}
It {it:is} tested at fourth order, by the over-identifying J of
{cmd:method(gmm)} and {cmd:method(pgmm)} -- but only away from a knife edge.
The Jacobian of the model with a1 free has determinant

{p 8 8 2}-(gamma - tau)^5 (B kurt_U - A kurt_V2){p_end}

{pstd}
so the restriction binds except where that second factor vanishes, and a
{it:normal V2} sits exactly there, since it makes B and kurt_V2 both zero.
Read {cmd:e(idfac)} before the J.  In simulation, against a violation by a
factor two at n = 4000, the rejection rate at 5% is 0.065 with V2 normal,
0.435 with V2 symmetric but leptokurtic, and 1.000 with V2 skewed.

{pstd}
It is tested {it:directly}, without any fourth moment, by a second indicator:
in model B a1 is free and identified, and the test above compares it with
g2 a2 + g3 a3.


{title:Examples}

{pstd}These run on data that ship with Stata{p_end}
{phang2}{stata "sysuse nlsw88, clear":. sysuse nlsw88, clear}{p_end}
{phang2}{stata "generate lwage = ln(wage)":. generate lwage = ln(wage)}{p_end}
{phang2}{stata "freeiv lwage grade age i.race (tenure)":. freeiv lwage grade age i.race (tenure)}{p_end}
{phang2}{stata "freeivtest":. freeivtest}{p_end}

{pstd}Against an estimate obtained elsewhere, with its own standard error{p_end}
{phang2}{stata "freeivtest, gamma(0.03) segamma(0.01)":. freeivtest, gamma(0.03) segamma(0.01)}{p_end}

{pstd}After the two-indicator model (after {cmd:net get freeiv}){p_end}
{phang2}{stata "use freeiv_proxy, clear":. use freeiv_proxy, clear}{p_end}
{phang2}{stata "freeiv y1 x (y2 y3)":. freeiv y1 x (y2 y3)}{p_end}
{phang2}{stata "freeivtest":. freeivtest}{p_end}


{title:Stored results}

{pstd}
{cmd:freeivtest} is {cmd:rclass}.  After model A it returns {cmd:r(W_endo)},
{cmd:r(F_endo)} (under {cmd:vce(svy)}), {cmd:r(p_endo)}, {cmd:r(g1)},
{cmd:r(g2)}, the pairwise {cmd:r(z_ols)} and {cmd:r(z_hme)}, the reference
{cmd:r(ref)} ({cmd:qme} or {cmd:vertex}), and {cmd:r(out_z)}, {cmd:r(out_d)}
when {cmd:gamma()} is given.  After model B it returns {cmd:r(z_sc)},
{cmd:r(p_sc)}, {cmd:r(z_of)}, {cmd:r(p_of)}, {cmd:r(J)} and {cmd:r(p_J)}.


{title:Author}

{pstd}
Abdelkrim Araar, Universite Laval and PEP{break}
{browse "mailto:aabd@ecn.ulaval.ca":aabd@ecn.ulaval.ca}


{title:Also see}

{psee}
Online: {helpb freeiv}, {helpb freeivmenu}, {helpb freeivdiag},
{helpb freeivreport}
{p_end}
