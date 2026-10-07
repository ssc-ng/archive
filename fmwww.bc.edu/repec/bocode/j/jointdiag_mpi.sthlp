{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "estat dwatson" "help regress postestimation ts"}{...}
{viewerjumpto "Syntax" "jointdiag_mpi##syntax"}{...}
{viewerjumpto "Description" "jointdiag_mpi##description"}{...}
{viewerjumpto "Options" "jointdiag_mpi##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_mpi##interpret"}{...}
{viewerjumpto "Remarks" "jointdiag_mpi##remarks"}{...}
{viewerjumpto "Examples" "jointdiag_mpi##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_mpi##results"}{...}

{title:Title}

{phang}
{bf:jointdiag mpi} {hline 2} One-sided most-powerful-invariant joint test for
AR(1) disturbances and heteroskedasticity


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:mpi} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt z(varname)}}the {it:z_t} of Var({it:e_t}) = {it:sigma}{c 94}2
{it:z_t}; must be positive{p_end}
{synopt:{opt rho1(#)}}point of maximum power; default {cmd:rho1(0.5)}{p_end}
{synopt:{opt neg:ative}}test against {it:negative} autocorrelation{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
King and Evans (1984) objected to the Bera{c 150}Jarque joint LM test on three
grounds, and built an alternative that answers all of them.

{p 4 7 2}
{bf:1.}  The LM test is {bf:two-sided}, but most econometric testing problems
are one-sided: economic theory usually tells you the sign.  In time series you
almost always expect {it:positive} autocorrelation.  Their Table 1 measures the
cost of ignoring that: at {it:n} = 20 the one-sided test has power 0.134, 0.228,
0.320, 0.403 and 0.475 where the two-sided LM test manages 0.082, 0.143, 0.211,
0.278 and 0.341.  Roughly a third of the available power is thrown away.

{p 4 7 2}
{bf:2.}  The LM test has {bf:no optimal small-sample property}.  Theirs is most
powerful invariant in a neighbourhood of a chosen point {it:rho1}.

{p 4 7 2}
{bf:3.}  The LM test needs {bf:Monte Carlo critical values}.  The exact null
distribution of theirs is a ratio of quadratic forms, so the critical value can
be computed numerically.

{pstd}
The statistic is {it:r}({it:rho1}), the ratio of the GLS to the OLS sum of
squared residuals, and {bf:small values reject}.


{marker options}{...}
{title:Options}

{phang}
{opt z(varname)} gives the known shape of the heteroskedasticity,
Var({it:e_t}) = {it:sigma}{c 94}2 {it:z_t}.  Leaving it out tests a pure AR(1)
alternative.

{phang}
{opt rho1(#)} is the point at which the test is most powerful.  The authors
recommend 0.5 against positive and -0.5 against negative autocorrelation,
chosen from experience with similar problems, and stress that it must be picked
{bf:without looking at} {it:y}.

{phang}
{opt negative} flips the sign of {cmd:rho1()} for the negative-autocorrelation
alternative.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Reject when the statistic falls BELOW the critical value.}  This is the
opposite of the usual convention and follows from the construction: under the
alternative the GLS transformation removes more variance, so the ratio shrinks.

{pstd}
{bf:The moment block} reports E[{it:r}] and sd[{it:r}] under the null, from
Henshaw (1966).  Use them as a sanity check: the statistic should lie within a
few standard deviations of the mean when the null is true.

{pstd}
{bf:The p-value is exact}, not asymptotic.  It comes from Imhof's (1961)
numerical inversion of the characteristic function of the quadratic form,
computed in logarithms so that it does not overflow in large samples.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The honest limitation.}  The test assumes the variances of the error term
in the autoregressive process are known up to a scalar.  The authors
acknowledge this (their sec. 3) and suggest the practical route: choose a
parametric form for {it:z_t}, set its unknown parameters to "reasonable"
non-zero values without reference to {it:y}, and run the test with the
resulting {it:z}.  That is what {opt z()} is for.

{pstd}
{bf:When to prefer it over} {helpb jointdiag_lm:jointdiag lm}.  When you have a
clear sign prior and a small sample, which is the case this test was built for.
When you have no sign prior, or many directions to check at once, use the LM
family instead.

{pstd}
{bf:Numerical note.}  The paper used the FQUAD subroutine of Koerts and
Abrahamse (1969) and offered beta approximations as a fallback.  Imhof's
inversion is used here instead; it is exact to the integration tolerance and
needs no approximation.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}Against positive autocorrelation{p_end}
{phang2}{cmd:. jointdiag mpi, rho1(0.5)}{p_end}

{pstd}Jointly with a known heteroskedasticity shape{p_end}
{phang2}{cmd:. jointdiag mpi, z(dln_inc) rho1(0.5)}{p_end}

{pstd}Against negative autocorrelation{p_end}
{phang2}{cmd:. jointdiag mpi, negative}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(r)}}the test statistic{p_end}
{synopt:{cmd:r(crit)}}exact critical value (reject below it){p_end}
{synopt:{cmd:r(p)}}exact p-value{p_end}
{synopt:{cmd:r(rho1)}}the point of maximum power used{p_end}
{synopt:{cmd:r(Er)}, {cmd:r(Vr)}}null mean and variance{p_end}
{synopt:{cmd:r(N)}}observations{p_end}


{title:References}

{phang}King, M. L., and M. A. Evans. 1984. {it:Economics Letters} 16: 297{c 150}302.
{browse "https://doi.org/10.1016/0165-1765(84)90179-4"}{p_end}
{phang}King, M. L. 1980. {it:Annals of Statistics} 8: 1265{c 150}1271.{p_end}
{phang}Imhof, J. P. 1961. {it:Biometrika} 48: 419{c 150}426.{p_end}
{phang}Henshaw, R. C. 1966. {it:Econometrica} 34: 646{c 150}660.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
