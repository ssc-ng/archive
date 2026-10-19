{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{viewerjumpto "Syntax" "tvtlr##syntax"}{...}
{viewerjumpto "Description" "tvtlr##description"}{...}
{viewerjumpto "The model is narrow, deliberately" "tvtlr##scope"}{...}
{viewerjumpto "Options" "tvtlr##options"}{...}
{viewerjumpto "How it works" "tvtlr##method"}{...}
{viewerjumpto "Reading the reported k and r" "tvtlr##argmax"}{...}
{viewerjumpto "Size in finite samples" "tvtlr##size"}{...}
{viewerjumpto "Examples" "tvtlr##examples"}{...}
{viewerjumpto "Stored results" "tvtlr##results"}{...}
{viewerjumpto "Validation" "tvtlr##validation"}{...}
{viewerjumpto "References" "tvtlr##references"}{...}
{viewerjumpto "Author" "tvtlr##author"}{...}
{title:Title}

{phang}
{bf:tvtlr} {hline 2} Test whether an AR model became a threshold AR model at
an unknown date


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtlr} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt meth:od(name)}}which test; only {cmd:berkes} is available in
this version{p_end}
{synopt :{opt dem:ean}}remove the mean before testing{p_end}
{synopt :{opt gridn(#)}}thin the threshold candidates{p_end}
{synopt :{opt level(#)}}90, 95 or 99; default {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}
The series must be contiguous in time. If the data are {helpb tsset} and
the sample has a gap, {cmd:tvtlr} refuses.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtlr} tests the null that a single AR(1) governs the whole sample,

{p 8 8 2}
H0:{space 3}{it:y_i} = {it:rho y_{c -(}i-1{c )-}} + {it:e_i}

{pstd}
against the alternative that at some unknown date {it:k*} a threshold term
switched on:

{p 8 8 2}
H1:{space 3}{it:y_i} = {it:phi1 y_{c -(}i-1{c )-}} + {it:e_i}
{space 8}for {it:i} {ul:<} {it:k*}{break}
{space 7}{it:y_i} = {it:phi1 y_{c -(}i-1{c )-}} + {it:phi2 y_{c -(}i-1{c )-}}
1[{it:y_{c -(}i-1{c )-}} {ul:<} {it:r}] + {it:e_i}{space 3}for {it:i} >
{it:k*}

{pstd}
{bf:Both the date and the threshold are absent under the null}, so this is
Davies' problem in two dimensions at once. The usual response is to trim
both searches and tabulate a critical value for each trimming choice. Berkes
et al. instead found a {bf:weighting} that makes the double supremum
converge with {bf:no trimming at all}, and whose limit depends on nothing:
not the error distribution, not {it:rho}, not the sample size, not any
tuning parameter.

{pstd}
The practical consequences are worth stating plainly. There is {bf:no
bootstrap} and {bf:nothing to tune} {hline 2} the test has no trimming
fraction, no bandwidth, no lag order and no grid to choose. It runs in a
fraction of a second and compares against three fixed numbers.


{marker scope}{...}
{title:The model is narrow, deliberately}

{pstd}
This is the paper's model, not a simplification made here, and
{cmd:tvtlr} refuses anything outside it rather than quietly fitting
something else:

{p 8 10 2}{bf:.} {bf:AR(1) only} {hline 2} one lag.{p_end}
{p 8 10 2}{bf:.} {bf:No intercept}, in either regime.{p_end}
{p 8 10 2}{bf:.} {bf:Delay fixed at 1} {hline 2} the threshold variable
{it:is} the regressor {it:y_{c -(}i-1{c )-}}.{p_end}
{p 8 10 2}{bf:.} {bf:A slope-only shift} {hline 2} the intercept does not
change, because there is none.{p_end}
{p 8 10 2}{bf:.} {bf:One extra regime}, appearing once, at one date.{p_end}

{pstd}
The no-intercept restriction is the one that bites in practice. The critical
values belong to that model. Applied to a series with a substantial mean,
the mean is absorbed into {it:rho}, pushing it toward 1. {cmd:tvtlr} warns
when the mean exceeds half the standard deviation and {bf:refuses} when it
exceeds twice it; {opt demean} removes the mean first and the output records
that it was used. Returns, growth rates and deviations need none of this.

{pstd}
{bf:If you need more than this, use} {cmd:method(zhuling)}. Zhu and Ling
(2012) extend the problem to an AR({it:p}) null {bf:with an intercept} and
a {bf:free delay}, and let the intercept shift as well as the slopes. It is
a genuinely different statistic, not a setting of this one:

{p2colset 8 26 28 2}{...}
{p2col :}{bf:berkes}{space 14}{bf:zhuling}{p_end}
{p2col :null}AR(1), no intercept{space 3}AR({it:p}) with intercept{p_end}
{p2col :delay}fixed at 1{space 11}free, {opt delay()}{p_end}
{p2col :what shifts}slopes only{space 10}intercept and slopes{p_end}
{p2col :weighting}weighted{space 13}unweighted{p_end}
{p2col :trimming}none needed{space 9}{bf:required}{p_end}
{p2col :critical values}three constants{space 5}depend on {it:p} and on
{opt trim()}{p_end}
{p2colreset}{...}

{pstd}
{bf:The trimming is not a convenience.} The paper shows that without
cutting the range of the break date and the threshold, the maximum of the
statistic {bf:diverges in probability}. Berkes et al. buy the untrimmed
range with a weight; Zhu and Ling buy it by trimming, and their critical
values are indexed by how much. {opt trim()} cannot be zero and the command
refuses it.


{marker options}{...}
{title:Options}

{phang}
{opt method(name)} selects the test: {cmd:berkes} (the default) or
{cmd:zhuling}. They are different statistics, not settings of one; see
above.

{pstd}
{bf:Options that apply only to} {cmd:method(zhuling)}:

{phang}
{opt lags(#)} is the order {it:p} of the AR null. Default 1.
{cmd:lags(0)} is the pure-intercept model, the {it:p} = 0 case of the
paper.

{phang}
{opt delay(#)} is the delay {it:d} in the threshold variable
{it:y_t-d}. Default 1.

{phang}
{opt trim(#)} is the paper's {it:pi_0}. The break date is searched over
the first 1-{it:pi_0} of the sample and the threshold over the
{it:pi_0} to 1-{it:pi_0} quantiles of {it:y}. The default is 0.10; the
paper uses 0.10 or 0.15 and says plainly that how to choose it optimally
remains unclear. It must lie in (0, 0.5].

{phang}
{opt simreps(#)} and {opt gridm(#)} control the simulation of the limiting
distribution: the number of draws (default 1000) and the resolution of the
two-parameter Wiener sheet (default 300). {opt seed(#)} makes the
simulation reproducible.

{pstd}
{bf:The critical values are simulated, not tabulated.} The paper's
Tables 1 and 2 give percentage points for a fixed list of {it:p} and
{it:pi_0}; this command instead simulates the paper's own limiting
distribution, so any {opt lags()} and any {opt trim()} can be used rather
than only the tabulated pairs, and a p-value is available as well as
critical values. The closed forms it needs are exact: the paper's
Phi1 and Phi2 integrate to -phi(x) and Phi(x) - x phi(x), so nothing is
approximated numerically.

{pstd}
{bf:One divergence, at} {it:p} {bf:= 2 only.} The simulation reproduces the
published percentage points at {it:p} = 0, 1, 3, 4 and 5 to within about
1%, and does not at {it:p} = 2, where it comes out roughly 9% low. The
paper's own {it:p} = 2 column is anomalous against its neighbours: at the
5% level with {it:pi_0} = 0.50 its entries rise 6.87, 10.19, 13.26, 14.03,
15.87, 17.52 for {it:p} = 0 to 5, so the step from {it:p} = 2 to 3 is only
0.77 where every other step adds between 1.6 and 3.3. Refining the grid
does not move it. Treat {cmd:lags(2)} results with that in mind; the
evidence is set out in
{bf:validation/tvthresh/tvtlr_equation_map.md}.

{phang}
{opt demean} subtracts the sample mean before testing. This {bf:changes the
test} {hline 2} it is no longer being applied to the series you passed
{hline 2} so it is an explicit choice and is reported in the output. Prefer
passing an already-centred series where you can.

{phang}
{opt gridn(#)} thins the threshold candidates to at most {it:#} points.
{bf:Leave it alone unless the series is very long.} The supremum over
{it:r} is exactly attained on the observed values, so the full candidate set
is not an approximation to anything {hline 2} thinning it can only lower the
statistic and make the test conservative. It exists because the search is
O({it:n}{c 94}2) and a series of tens of thousands of observations would
otherwise be slow.

{phang}
{opt level(#)} selects which tabulated value to decide at: 90, 95 or 99.
Only three quantiles exist, so any other level is reported at 5% with a
note, and {bf:no p-value is interpolated} {hline 2} {cmd:r(pbracket)} gives
the bracket the statistic falls in instead.


{marker method}{...}
{title:How it works}

{pstd}
With {it:Z} = sum of {it:y_{c -(}i-1{c )-}}{c 94}2 and
{it:S}({it:k,r}) = the same sum restricted to {it:i} > {it:k} and
{it:y_{c -(}i-1{c )-}} {ul:<} {it:r}, the statistic is

{p 8 8 2}
{it:Rbar} = ({it:n}/{it:Z}){c 94}3 {space 2}max over {it:k}{space 2}sup over
{it:r}{space 2}{it:R_n}({it:k,r})

{pstd}
where {it:R_n} multiplies the drop in the residual variance by the weight
{it:Z}({it:ZS} - {it:S}{c 94}2). That weight is the whole trick: it is what
makes the untrimmed supremum finite. The paper's equation (5) shows the
{it:unweighted} supremum diverges almost surely, so {bf:trimming this
statistic "to be safe" would invalidate the critical values}.

{pstd}
Written literally that is a regression at each of {it:n}{c 94}2 candidate
pairs. It is not computed that way. The two-regressor cross-product matrix
has the form [{it:Z S} ; {it:S S}], because the indicator squared is the
indicator, and carrying that through the algebra the determinant cancels
against the weight, leaving

{p 8 8 2}
{it:R_n}({it:k,r}) = ({it:ZV} - {it:SG}){c 94}2 / ({it:n}{c 94}3
{it:sigmahat}{c 94}2)

{pstd}
with {it:G} and {it:V} two more running sums. No inverse, no determinant and
no rank guard {hline 2} and the degenerate candidates fall out correctly:
where no observation lies below {it:r} after {it:k}, both sums are zero and
the statistic is exactly zero, as the paper says it should be.

{pstd}
The limit is the supremum over the unit square of
({it:su W}(1,1) - {it:W}({it:s,u})){c 94}2 with {it:W} a Brownian sheet.
Critical values: {bf:2.343} at 10%, {bf:2.758} at 5%, {bf:3.604} at 1%.


{marker argmax}{...}
{title:Reading the reported k and r}

{pstd}
{cmd:tvtlr} reports where the maximum was attained, because the paper
locates its own application's break dates that way. {bf:Read it with care.}

{pstd}
The maximised quantity is {bf:weighted}, and the weight rewards
configurations in which many observations fall below {it:r} after {it:k}
{hline 2} which favours {bf:small} {it:k}. On simulated series with a known
break at {it:n} = 300, the argmax tracked the true date only loosely and was
biased early:

{p2colset 10 32 34 2}{...}
{p2col :true break}located at{p_end}
{p2col :50}3{p_end}
{p2col :100}35{p_end}
{p2col :150}137{p_end}
{p2col :200}91{p_end}
{p2col :250}186{p_end}
{p2colreset}{...}

{pstd}
The paper gives no consistency result for it, and none is claimed here.
Treat {cmd:r(k)} as where the evidence peaked, not as a dated estimate, and
do not build a narrative on the date. If the date is the object of interest,
a procedure designed to estimate it is the right tool.


{marker size}{...}
{title:Size in finite samples}

{pstd}
The three critical values are {bf:asymptotic}, and in finite samples this
test is {bf:conservative}. Measured here on an AR(1) null, 500 replications
per cell:

{p2colset 8 26 28 2}{...}
{p2col :{it:n}}10%{space 8}5%{space 8}1%{p_end}
{p2col :100}0.04{space 7}0.01{space 7}0.00{p_end}
{p2col :200}0.06{space 7}0.02{space 7}0.00{p_end}
{p2col :400}0.07{space 7}0.03{space 7}0.00{p_end}
{p2col :{it:nominal}}0.10{space 7}0.05{space 7}0.01{p_end}
{p2colreset}{...}

{pstd}
The shortfall is large in short series and {bf:eases steadily as the sample
grows}, which is the signature of slow convergence rather than a mistake:
the finite-sample statistic is a supremum over about {it:n}{c 94}2 sample
points, while the limit is a supremum over a continuum, so the sample
version is systematically the smaller of the two and the gap closes with
{it:n}.

{pstd}
This agrees with the paper, whose own simulations report the "observed
significance level" {hline 2} the {it:non-rejection} rate, which should sit
at 1 - {it:alpha} = 0.95 {hline 2} as close to 0.95 at {it:n} = 400 and
{bf:slightly larger} at {it:n} = 200. Larger non-rejection means a smaller
rejection rate, i.e. conservative, in the same direction found here. The
paper reports no numeric size table, only power curves, so the figures above
were measured rather than matched.

{pstd}
{bf:What this means in practice.} Type I error is controlled, which is the
safe direction, but {bf:power is lower than the asymptotics suggest} and a
non-rejection in a short series is correspondingly weak evidence. Below
about 200 observations, treat a non-rejection as uninformative rather than
as support for a stable AR.


{marker examples}{...}
{title:Examples}

{pstd}A series that changes to a threshold AR partway through.{p_end}
{phang2}{cmd:. set seed 81001}{p_end}
{phang2}{cmd:. set obs 301}{p_end}
{phang2}{cmd:. generate int t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. generate double y = 0}{p_end}
{phang2}{cmd:. replace y = 0.5*y[_n-1] + rnormal() in 2/150}{p_end}
{phang2}{cmd:. replace y = 0.5*y[_n-1] - 0.9*y[_n-1]*(y[_n-1] <= 0) + rnormal() in 151/301}{p_end}
{phang2}{cmd:. tvtlr y}{p_end}

{pstd}A series with a mean: refused, then handled explicitly.{p_end}
{phang2}{cmd:. generate double ylevel = y + 20}{p_end}
{phang2}{cmd:. tvtlr ylevel}{p_end}
{phang2}{cmd:. tvtlr ylevel, demean}{p_end}

{pstd}Decide at 1%, and read the bracket rather than a p-value.{p_end}
{phang2}{cmd:. tvtlr y, level(99)}{p_end}
{phang2}{cmd:. display "`r(pbracket)'"}{p_end}

{pstd}On real data: test a return series for a change to threshold
dynamics.{p_end}
{phang2}{cmd:. generate double ret = D.lnprice}{p_end}
{phang2}{cmd:. tvtlr ret}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtlr} is {bf:r-class}. It fits nothing that survives the command, so
{cmd:e()} is untouched.

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}the Rbar statistic{p_end}
{synopt:{cmd:r(reject)}}1 if rejected at {cmd:r(level)}{p_end}
{synopt:{cmd:r(cv10)}, {cmd:r(cv05)}, {cmd:r(cv01)}}2.343, 2.758,
3.604{p_end}
{synopt:{cmd:r(k)}}where the maximum was attained {hline 2} see above{p_end}
{synopt:{cmd:r(r)}}the threshold at the maximum{p_end}
{synopt:{cmd:r(rho)}}the AR coefficient under the null{p_end}
{synopt:{cmd:r(sigma2)}}the residual variance under the null{p_end}
{synopt:{cmd:r(N)}}observations used, {it:n} = sample size minus one{p_end}
{synopt:{cmd:r(n_cand)}}threshold candidates searched{p_end}
{synopt:{cmd:r(demean)}}1 if {opt demean} was applied{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:tvtlr}{p_end}
{synopt:{cmd:r(method)}}{cmd:berkes}{p_end}
{synopt:{cmd:r(pbracket)}}the p-value bracket{p_end}

{pstd}
{bf:On} {cmd:r(N)}. The statistic sums over {it:i} = 1 to {it:n} with
regressor {it:y_{c -(}i-1{c )-}}, so the first observation serves as
{it:y_0} and {cmd:r(N)} is one less than the number of observations in the
sample. The normalisation ({it:n}/{it:Z}){c 94}3 makes that convention
matter, which is why it is stated.


{marker validation}{...}
{title:Validation}

{pstd}
The three critical values are reproduced by simulating the Brownian sheet
directly rather than shipped on trust. They come out low on a coarse grid
and rise monotonically as it is refined {hline 2} which is what a supremum
must do {hline 2} landing on the paper's values at a 200x200 mesh.

{pstd}
The closed form used internally is checked against a literal evaluation of
the paper's own expression, with two explicit least-squares fits and the
weight written out, at many ({it:k,r}) pairs; they agree to about
1e-14. That check exists because the closed form is derived algebra, and
derived algebra can be wrong.

{pstd}
The paper provides no numeric size or power table, so size was established
here by simulation and is reported in the equation map, including where it
differs from the paper's qualitative claim. The empirical replication
{hline 2} the paper's corn and soybean price series {hline 2} is
{bf:blocked}: the series are not on disk and the source URL in the paper
dates from 2008. That is recorded as an open item rather than quietly
dropped.

{pstd}
No reference code was published with the paper. See
{bf:validation/tvthresh/tvtlr_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Berkes, I., L. Horvath, S. Ling, and J. Schauer. 2011. Testing for
structural change of AR model to threshold AR model. {it:Journal of Time
Series Analysis} 32(5): 547-565.
{browse "https://doi.org/10.1111/j.1467-9892.2010.00714.x":doi:10.1111/j.1467-9892.2010.00714.x}

{phang}
Chan, K. S. 1990. Testing for threshold autoregression. {it:Annals of
Statistics} 18(4): 1886-1894.
{browse "https://doi.org/10.1214/aos/1176347886":doi:10.1214/aos/1176347886}

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present
only under the alternative. {it:Biometrika} 74(1): 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}

{phang}
Zhu, K., and S. Ling. 2012. Likelihood ratio tests for the structural change
of an AR(p) model to a Threshold AR(p) model. {it:Journal of Time Series
Analysis} 33(2): 223-232.
{browse "https://doi.org/10.1111/j.1467-9892.2011.00753.x":doi:10.1111/j.1467-9892.2011.00753.x}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb tvthomog},
{helpb tvtfourier}
{p_end}
