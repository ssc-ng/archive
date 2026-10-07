{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag bilinear" "help jointdiag_bilinear"}{...}
{viewerjumpto "Syntax" "jointdiag_score##syntax"}{...}
{viewerjumpto "Description" "jointdiag_score##description"}{...}
{viewerjumpto "Options" "jointdiag_score##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_score##interpret"}{...}
{viewerjumpto "Remarks" "jointdiag_score##remarks"}{...}
{viewerjumpto "Examples" "jointdiag_score##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_score##results"}{...}

{title:Title}

{phang}
{bf:jointdiag score} {hline 2} Score tests for autocorrelation,
heteroskedasticity and bilinearity in the errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:score} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt het(varlist)}}the {it:z} of the variance function; default the
fitted values{p_end}
{synopt:{opt ar(#)}}AR order {it:p}; default {cmd:ar(1)}{p_end}
{synopt:{opt bil:inear}}add the Liu{c 150}Wei{c 150}Wang bilinear tests{p_end}
{synopt:{opt log}}treat the variance function as exp({it:z'}{&lambda}){p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt gr:aph}}component plot{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
Tsai (1986) derived a score test for simultaneous independence and
homoskedasticity in the first-order autoregressive model with non-constant
variance.  It splits exactly:

{p 8 8 2}
{it:S} = {it:S1} + {it:S2}

{pstd}
with {it:S1} testing {&rho} = 0 given homoskedasticity and {it:S2} testing the
variance given independence.  Each half is separately usable, and each is
robust to the other under local departures.

{pstd}
Liu, Wei and Wang (2003) extended this to {it:nonlinear} regression with
diagonal bilinear DBL({it:p},0,1) errors,

{p 8 8 2}
{it:u_t} = {&Sigma}_i {&phi}_i {it:u_{t-i}} + {&psi} {it:u_{t-1} e_{t-1}} + {it:e_t}

{pstd}
giving four score tests: bilinearity alone, correlation and bilinearity
together, homogeneity of variance, and all of them jointly.


{marker options}{...}
{title:Options}

{phang}
{opt het(varlist)} names the variables entering the variance function.  The
default is the fitted values, which is Cook and Weisberg's (1983) choice and
the one Tsai works with.

{phang}
{opt ar(#)} sets the autoregressive order.  Tsai's paper is written for
{it:p} = 1; Liu, Wei and Wang generalise it.

{phang}
{opt bilinear} adds the DBL tests.  The bilinear term {it:u_{t-1} e_{t-1}} is
the simplest way to let the errors be nonlinear without leaving the score-test
framework.

{phang}
{opt log} is for a multiplicative variance function {it:w} = exp({it:z'}{&lambda}),
in which case the derivative matrix is {it:z} itself.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:S1 and S2 are independent.}  Read them as two separate verdicts, then the
sum as the joint one.  A large {it:S} with both halves moderate means the
evidence is spread across both problems.

{pstd}
{bf:The reported first-order residual correlation} is the {it:rho} of Tsai's
eq. (2-5); it is the quantity {it:S1} squares, so it gives you the direction as
well as the strength.

{pstd}
{bf:SCa, SCb, SCd} are the Liu{c 150}Wei{c 150}Wang statistics.  SCa isolates
the bilinear term; SCb tests autocorrelation and bilinearity together; SCd adds
the variance.  If SCa rejects while S1 does not, the dependence in the errors is
nonlinear rather than linear, and the remedy is a bilinear or ARCH
specification, not an AR one.  Compare with
{helpb jointdiag_bilinear:jointdiag bilinear}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:This is a local test and its power is not monotone.}  Liu, Wei and Wang
(2003, sec. 4) document it carefully: power rises as the bilinear parameter
moves away from zero, peaks, and then {it:falls} again.  In their simulations
the turning point is near |{&psi}| = 0.5 and by |{&psi}| = 0.8 the power is back
down.  Their Figure 1 mirrors what Guegan and Pham (1992) found for pure
bilinear series.  So a non-rejection is {bf:not} evidence that the bilinear
term is small; it may be evidence that it is large.  Inspect the fitted
bilinear coefficient as well.

{pstd}
{bf:Tsai's geometric reading.}  Section 3 of his paper connects the statistic
to Cook's local-influence analysis: {it:S} is large exactly when the normal
curvature of the influence graph is large, or when the GLS coefficient
estimates are sensitive to perturbing the error structure.  A rejection
therefore also warns that your coefficient estimates are fragile.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}Tsai's two components{p_end}
{phang2}{cmd:. jointdiag score, ar(1)}{p_end}

{pstd}With the bilinear extension and a named variance variable{p_end}
{phang2}{cmd:. jointdiag score, ar(2) het(dln_inc) bilinear graph}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(S1)}, {cmd:r(df1)}, {cmd:r(p1)}}autocorrelation component{p_end}
{synopt:{cmd:r(S2)}, {cmd:r(df2)}, {cmd:r(p2)}}variance component{p_end}
{synopt:{cmd:r(S)}, {cmd:r(df)}, {cmd:r(p)}}the sum{p_end}
{synopt:{cmd:r(SCa)}, {cmd:r(p_SCa)}}bilinearity{p_end}
{synopt:{cmd:r(SCb)}, {cmd:r(p_SCb)}}correlation and bilinearity{p_end}
{synopt:{cmd:r(SCd)}, {cmd:r(p_SCd)}}variance and correlation{p_end}
{synopt:{cmd:r(rho)}}first-order residual correlation{p_end}
{synopt:{cmd:r(N)}}observations{p_end}


{title:References}

{phang}Tsai, C.-L. 1986. {it:Biometrika} 73: 455{c 150}460.
{browse "https://doi.org/10.2307/2336222"}{p_end}
{phang}Liu, Y.-A., B.-C. Wei, and H.-B. Wang. 2003.
{it:Comm. Statist. Theory Meth.} 32: 2441{c 150}2463.
{browse "https://doi.org/10.1081/sta-120025387"}{p_end}
{phang}Cook, R. D., and S. Weisberg. 1983. {it:Biometrika} 70: 1{c 150}10.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
