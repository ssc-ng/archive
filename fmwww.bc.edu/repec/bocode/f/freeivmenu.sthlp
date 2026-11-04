{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "freeiv" "help freeiv"}{...}
{vieweralsosee "freeivdiag" "help freeivdiag"}{...}
{vieweralsosee "freeivtest" "help freeivtest"}{...}
{title:Title}

{phang}
{bf:freeivmenu} {hline 2} What these data can identify, before any estimation


{title:Syntax}

{p 8 17 2}
{cmd:freeivmenu} {depvar} [{indepvars}] {cmd:(}{it:endogvar}{cmd:)}
{ifin} {weight}
[{cmd:, bw(}{it:#}{cmd:)}]

{p 8 17 2}
{cmd:freeivmenu} {depvar} [{indepvars}] {cmd:(}{it:endogvar1} {it:endogvar2}{cmd:)}
{ifin} {weight}
[{cmd:, bw(}{it:#}{cmd:)}]

{p 4 6 2}{it:pweight}s and {it:aweight}s are allowed; {it:indepvars} may
contain factor variables.{p_end}


{title:Description}

{pstd}
{cmd:freeivmenu} is run {it:before} {helpb freeiv}, in the spirit of reading a
first-stage F before an instrumental-variables regression.  It prints one line
per family of identifying strategies, with the signal that family needs, the
value of that signal in these data, and a verdict.

{pstd}
The first line is always true: the interval exists under the model alone.  The
others say whether the assumption that would deliver a {it:point} is carried
by the data.  A weak signal does not make an estimator wrong; it makes it
imprecise, and sometimes it makes it silent.

{pstd}
What each line reports:

{p2colset 5 26 28 2}{...}
{p2col:{bf:bounds}}the width of [gamma-tilde/2, gamma-tilde].  Always
available.{p_end}
{p2col:{bf:third order}}the skewness of the first-stage residual and the z of
m03, on which the third-order routes -- qme, hme, lsz -- live entirely.  Then
the z of the discriminant D = g^2 (2A - B)^2, which the model cannot make
negative: far below zero (z <= -2) the verdict is {bf:REFUTES}.  Then either
the implied standard error of the qme or, when neither root lies inside the
interval, the line {bf:roots inside the bounds 0 NONE}: the qme's value is then
not admissible, however precise.  Last, A = a2^3 E[U^3] and mu = A/(A+B), read
at the qme or, when D < 0, at the vertex, where mu is 1/3 by
construction.{p_end}
{p2col:{bf:symmetry of V2}}B = E[V2^3], which the {cmd:hme} sets to 0.  When D
< 0 it is read at the vertex, where B = 2A: a negative discriminant then itself
says that V2 is skewed.{p_end}
{p2col:{bf:heteroskedasticity}}the F of eps2^2 on X, which is what
{cmd:lewbel12} needs.  When it is absent, that route returns noise -- and
{cmd:ivreg2h} says the same thing in its own language, through a small
Cragg-Donald F.{p_end}
{p2col:{bf:local slope profile}}the kernel-weighted slope of xi on eps2 at
seven percentiles of eps2 -- the local-linear estimate of the derivative of
E[xi | eps2].  In the one-factor model that derivative is
gamma + alpha1 m'(s) with m(s) = E[U | eps2 = s].  If the confounder is
Gaussian-like, m is linear and the profile is {it:flat} at gamma-tilde: the
third-order routes will find little.  If it is skewed, m is curved and the
profile moves -- but a non-linear outcome equation curves it too, so a
curved profile says which of the two is in play only together with the other
lines.  Two readings are exact in the limit.  When m is increasing
(log-concave densities suffice) the {it:minimum} of the profile is an upper
bound on gamma tighter than gamma-tilde, with no assumption on the law;
"tightens" is printed when the minimum sits at p5 or p10 and beats
gamma-tilde by more than 1.96 standard errors.  The minimum belongs in a tail:
on the side of eps2 that V2 dominates the slope tends to gamma, on the side U
dominates to gamma + alpha1/alpha2, and an increasing m keeps it above gamma in
between.  An interior minimum is reported as "interior min": the profile does
not have that shape, no bound is read from it, and a non-linear outcome
equation is the first thing to suspect.  And the ratio of the two tail slopes
tends to 1 + alpha1/(gamma alpha2), which is 2 under scale consistency; it is
informative only when one tail of eps2 is dominated by U and the other by V2,
as with a bounded or strongly skewed confounder, and it converges slowly.  The
bandwidth is h = 2 * 1.06 * sd(eps2) * N^(-1/5) unless {opt bw()} is
given.{p_end}
{p2col:{bf:two indicators}}a reminder that a second indicator of the same
confounder, if one exists, opens model B and with it the only direct test of
scale consistency.  Model B is selected by the syntax alone -- two variables
inside the parentheses.{p_end}
{p2colreset}{...}

{pstd}
{bf:With two indicators.}  Two variables in the parentheses give the menu of
the two-indicator model, which says before estimation whether Theorem 1 of
Araar (2026d) has anything to work with:

{p2colset 5 26 28 2}{...}
{p2col:{bf:relevance of the pair}}the t of the residual correlation of the two
indicators, against the application rule t >= 10 below which the closed form
disperses steeply, and alpha2 alpha3 = E[eps2 eps3] with its z.{p_end}
{p2col:{bf:third order}}the two cross-moments E[eps2^2 eps3] and
E[eps2 eps3^2] with their z, and whether they share a sign -- guard (i) of
Proposition 1, which fires when the regressor affects the indicator or a
second factor is present.{p_end}
{p2col:{bf:loadings}}alpha2/alpha3 from the ratio of the two cross-moments,
guard (ii) on its coherence with the covariance, the implied loadings, and the
implied idiosyncratic variances, guard (iii).  A guard that fires here fires in
{helpb freeiv}.{p_end}
{p2col:{bf:confounder}}the implied skewness of U, which sets the precision
regime mapped in Araar (2026d) -- {it:low} (below 0.5): the causal coefficient
is recovered but the free direct effect a1 is not; {it:moderate}; {it:full}
(above 1.5): all parameters are precise and scale consistency becomes
testable.{p_end}
{p2col:{bf:one factor}}the three estimates R1, R2, R3 of alpha2/alpha3 and
|R3/R1 - 1|; read only when both third-order z exceed 2, since R2 and R3 are
noise otherwise.{p_end}
{p2col:{bf:local slope profile}}of xi on each indicator, as above; "rising" or
"interior min" says whether the minimum sits in a tail, as the linear
one-factor model implies, or inside.{p_end}
{p2colreset}{...}

{pstd}
{bf:Read the z of m03 first.}  Detecting endogeneity and measuring it need
different signals: measuring g needs a third-order signal that the
quadratic can use (D > 0), while detecting a confounder at all needs only
m03 != 0, from U or from V2 (see {helpb freeivtest}).  When U and V2 are both
symmetric the third-order block is empty and neither is possible; that case is
visible here and nowhere else.

{pstd}
With {it:pweight}s the z of the discriminant uses the sandwich form of
{helpb freeiv}.  The menu takes no survey design; under {cmd:svyset} data, give
it the sampling weight.


{title:Options}

{phang}
{opt bw(#)} sets the kernel bandwidth of the local slope profile, in the units
of eps2; the default is 2 * 1.06 * sd(eps2) * N^(-1/5).  A larger bandwidth
gives a smoother, more precise and more biased profile.


{title:Examples}

{pstd}These run on data that ship with Stata{p_end}
{phang2}{stata "sysuse nlsw88, clear":. sysuse nlsw88, clear}{p_end}
{phang2}{stata "generate lwage = ln(wage)":. generate lwage = ln(wage)}{p_end}

{pstd}A strong third-order signal (z of D 5.7) that refutes the model: neither
root lies inside the interval, and the line {bf:roots inside the bounds} says
so before any estimate is read{p_end}
{phang2}{stata "freeivmenu lwage grade age i.race (tenure)":. freeivmenu lwage grade age i.race (tenure)}{p_end}
{phang2}{stata "freeiv lwage grade age i.race (tenure), method(all)":. freeiv lwage grade age i.race (tenure), method(all)}{p_end}

{pstd}No third-order signal at all (z of m03 0.65): the discriminant is
negative within its noise, the qme falls back on the vertex and lands outside
the interval{p_end}
{phang2}{stata "freeivmenu lwage ttl_exp (grade)":. freeivmenu lwage ttl_exp (grade)}{p_end}
{phang2}{stata "freeiv lwage ttl_exp (grade), method(all)":. freeiv lwage ttl_exp (grade), method(all)}{p_end}

{pstd}And a design that carries the model (after {cmd:net get freeiv}){p_end}
{phang2}{stata "use freeiv_sim1, clear":. use freeiv_sim1, clear}{p_end}
{phang2}{stata "freeivmenu y1 x (y2)":. freeivmenu y1 x (y2)}{p_end}


{title:Stored results}

{pstd}
{cmd:freeivmenu} is {cmd:rclass}.  Every displayed statistic is returned,
including {cmd:r(z_m03)}, {cmd:r(F_lewbel)}, {cmd:r(p_lewbel)},
{cmd:r(lo)}, {cmd:r(hi)}, {cmd:r(disc)}, {cmd:r(disc_z)}, {cmd:r(nroots)},
{cmd:r(at_vertex)}, {cmd:r(A)}, {cmd:r(B)}, {cmd:r(mu)}, {cmd:r(cshare)}, and
the matrix {cmd:r(moments)}.  The local slope profile is returned as the 7 x 3
matrix {cmd:r(profile)} (evaluation point, slope, standard error, rows p5 to
p95), with {cmd:r(prof_h)}, {cmd:r(prof_min)}, {cmd:r(prof_minse)},
{cmd:r(prof_ratio)} and {cmd:r(prof_z)}.  With two indicators the returned set
is that of the two-indicator engine ({cmd:r(t_rho)}, {cmd:r(m23)},
{cmd:r(m223)}, {cmd:r(m233)}, {cmd:r(guard)}, {cmd:r(R1)}, {cmd:r(R2)},
{cmd:r(R3)}, {cmd:r(disc_R)}, {cmd:r(a2)}, {cmd:r(a3)}, {cmd:r(mu3)},
{cmd:r(s2)}, {cmd:r(s3)}, ...), the z statistics {cmd:r(z_m23)},
{cmd:r(z_m223)}, {cmd:r(z_m233)}, and the two profiles {cmd:r(profile2)},
{cmd:r(profile3)} with their {cmd:r(prof2_*)} and {cmd:r(prof3_*)} scalars.


{title:Reference}

{phang}
Araar, A. 2026d.  Two indicators of one latent confounder: Closed-form
identification of the triangular model with a free proxy effect.  Zenodo,
doi:10.5281/zenodo.22207331.


{title:Author}

{pstd}
Abdelkrim Araar, Universite Laval and PEP{break}
{browse "mailto:aabd@ecn.ulaval.ca":aabd@ecn.ulaval.ca}


{title:Also see}

{psee}
Online: {helpb freeiv}, {helpb freeivdiag}, {helpb freeivtest},
{helpb freeivreport}
{p_end}
