{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag arch" "help jointdiag_arch"}{...}
{vieweralsosee "estat imtest" "help regress postestimation##imtest"}{...}
{viewerjumpto "Syntax" "jointdiag_im##syntax"}{...}
{viewerjumpto "Description" "jointdiag_im##description"}{...}
{viewerjumpto "Options" "jointdiag_im##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_im##interpret"}{...}
{viewerjumpto "Remarks" "jointdiag_im##remarks"}{...}
{viewerjumpto "Examples" "jointdiag_im##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_im##results"}{...}

{title:Title}

{phang}
{bf:jointdiag im} {hline 2} Information-matrix test and its decomposition,
with AR({it:p}) errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:im} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ar(#)}}order of the AR errors in the {it:null} model;
default {cmd:ar(0)}{p_end}
{synopt:{opt archl:ags(#)}}order of the conditional-variance block tested;
default = max({cmd:ar()}, 1){p_end}
{synopt:{opt aarch}}test augmented ARCH (include cross-products of lagged
residuals){p_end}
{synopt:{opt hall}}force the pure Hall (1987) three-component decomposition{p_end}
{synopt:{opt bp}}un-studentised blocks (Hall's exact {&Delta}1 and {&Delta}3){p_end}
{synopt:{opt comp:are}}print {helpb estat imtest} side by side{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt gr:aph}}component plot{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
White's (1982) information-matrix test asks whether the information-matrix
equality holds.  Hall (1987) showed that in the normal linear model it splits
asymptotically into three {it:independent} pieces {c 150} heteroskedasticity,
skewness and kurtosis {c 150} and, crucially, that {bf:none of them has any
power against serial correlation}: the test's power there equals its size.

{pstd}
Bera and Lee (1993) answered the question Hall left open.  Starting from a
linear model with AR({it:p}) errors they found the covariance matrix of the
indicator vector {it:stays} block diagonal, giving six additive components, and
that one of the new ones {c 150} {bf:T2} {c 150} {bf:is exactly Engle's LM test
for ARCH}.  With Chesher's (1984) reading of the IM test as a test for
parameter variation, that identity says: {bf:ARCH is random variation in the
autoregressive coefficients}.

{pstd}
With {cmd:ar(0)} you get Hall's three components; with {cmd:ar(}{it:p}{cmd:)}
you get Bera and Lee's six.


{marker options}{...}
{title:Options}

{phang}
{opt ar(#)} sets the order of the autoregressive errors {it:in the null model}.
With {cmd:ar(0)} the null is the ordinary normal linear model and the residuals
come from {helpb regress}; with {cmd:ar(}{it:p}{cmd:)} they come from
{helpb arima} (or {helpb prais} when {it:p} = 1).

{phang}
{opt archlags(#)} is the order of the conditional-variance block, separately
from {cmd:ar()}.  Setting {cmd:ar(0) archlags(}{it:q}{cmd:)} makes T2 identical
to {cmd:estat archlm, lags(}{it:q}{cmd:)} {c 150} this is the numerical
statement of Bera and Lee's eq. (7) and is verified in the example do-file.

{phang}
{opt aarch} includes the cross-products {it:e_{t-i} e_{t-j}}, giving the
augmented ARCH alternative of Bera, Higgins and Lee (1992).  Unlike ARCH,
AARCH is not symmetric in the signs of the lagged errors, so it picks up the
leverage effect.

{phang}
{opt bp} turns off the studentisation of the heteroskedasticity and kurtosis
blocks.  The default (studentised) heteroskedasticity block equals White's
direct test and matches {helpb estat imtest}; {cmd:bp} gives the
Breusch{c 150}Pagan form Hall writes as {&Delta}1.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:With} {cmd:ar(0)}.  Three rows.  T1n is heteroskedasticity, T2n skewness,
T3n kurtosis.  The note under the table is the warning worth remembering: a
clean IM test says nothing about serial correlation.  If you care about that,
re-run with {cmd:ar(}{it:p}{cmd:)} or use {helpb jointdiag_lm:jointdiag lm}.

{pstd}
{bf:With} {cmd:ar(}{it:p}{cmd:)}.  Six rows.  T1 is {it:static} heteroskedasticity
(the variance depends on the regressors), T2 is {it:conditional}
heteroskedasticity (ARCH; the variance depends on past errors).  The two are
different problems with different remedies, and the line below the table
reports their sum.  T5 and T6 are the analogous split of the {it:third} moment
{c 150} Bera and Lee's "heteroclicity".  T4 picks up heteroskedasticity caused
by the interaction between the regressors and the disturbances.

{pstd}
{bf:With} {cmd:compare}.  The heteroskedasticity blocks agree to the last digit.
The skewness and kurtosis blocks do {it:not}, and this is deliberate: Stata's
{helpb estat imtest} reports the Cameron{c 150}Trivedi (1990) OPG forms,
{cmd:jointdiag} reports Hall's {&Delta}2 and {&Delta}3 as written in the paper.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Why the AR extension matters.}  Hall (1987, p. 262) wrote that with
first-order autoregressive errors "the indicator vector no longer has a block
diagonal covariance matrix due to the inclusion of the autoregressive
coefficient in the parameter vector".  Bera and Lee showed it does.  That is
the difference between a test that decomposes into interpretable pieces and one
that does not.

{pstd}
{bf:A practical by-product.}  Because T1 conditions on the AR structure, it
gives you a {it:heteroskedasticity test that is valid in the presence of
autocorrelation} {c 150} something the ordinary White or Breusch{c 150}Pagan
test is not (Epps and Epps 1977).  Operationally: regress the squared residual
on the squares and cross-products of the {it:quasi-differenced} regressors,
not the raw ones.

{pstd}
{bf:Limitation.}  Lagged dependent variables among the regressors are not
supported in the {cmd:ar()} branch; with them the block diagonality that makes
the six components additive can fail.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}Hall's three components, with the built-in alongside{p_end}
{phang2}{cmd:. jointdiag im, hall compare}{p_end}

{pstd}The Bera{c 150}Lee six, AR(1) null and ARCH(2) alternative{p_end}
{phang2}{cmd:. jointdiag im, ar(1) archlags(2) graph}{p_end}

{pstd}Augmented ARCH{p_end}
{phang2}{cmd:. jointdiag im, ar(1) archlags(2) aarch}{p_end}

{pstd}Verify T2 == Engle's test{p_end}
{phang2}{cmd:. jointdiag im, ar(0) archlags(3) notable}{p_end}
{phang2}{cmd:. display r(T2)}{p_end}
{phang2}{cmd:. estat archlm, lags(3)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(T1)} ... {cmd:r(T6)}}the six component statistics{p_end}
{synopt:{cmd:r(df1)} ... {cmd:r(df6)}}their degrees of freedom{p_end}
{synopt:{cmd:r(p1)} ... {cmd:r(p6)}}their p-values{p_end}
{synopt:{cmd:r(T)}, {cmd:r(df)}, {cmd:r(p)}}the total{p_end}
{synopt:{cmd:r(ct_h)}, {cmd:r(ct_s)}, {cmd:r(ct_k)}}{cmd:estat imtest} values,
with {cmd:compare}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(ar)}}observations, AR order{p_end}


{title:References}

{phang}Hall, A. 1987. {it:Rev. Econ. Studies} 54: 257{c 150}263.
{browse "https://doi.org/10.2307/2297515"}{p_end}
{phang}Bera, A. K., and S. Lee. 1993. {it:Rev. Econ. Studies} 60: 229{c 150}240.
{browse "https://doi.org/10.2307/2297820"}{p_end}
{phang}White, H. 1982. {it:Econometrica} 50: 1{c 150}25.
{browse "https://doi.org/10.2307/1912526"}{p_end}
{phang}Chesher, A. 1984. {it:Econometrica} 52: 865{c 150}872.
{browse "https://doi.org/10.2307/1911188"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
