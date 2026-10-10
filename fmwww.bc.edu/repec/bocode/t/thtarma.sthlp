{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{vieweralsosee "thunitroot" "help thunitroot"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thtarma##syntax"}{...}
{viewerjumpto "Description" "thtarma##description"}{...}
{viewerjumpto "Options" "thtarma##options"}{...}
{viewerjumpto "The two statistics" "thtarma##stats"}{...}
{viewerjumpto "The p-value" "thtarma##pvalue"}{...}
{viewerjumpto "Remarks" "thtarma##remarks"}{...}
{viewerjumpto "Validation" "thtarma##validation"}{...}
{viewerjumpto "Stored results" "thtarma##results"}{...}
{viewerjumpto "Examples" "thtarma##examples"}{...}
{viewerjumpto "References" "thtarma##refs"}{...}
{viewerjumpto "Author" "thtarma##author"}{...}

{title:Title}

{phang}
{bf:thtarma} {hline 2} Supremum LM test for a threshold in an ARMA model


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thtarma} {varname} {ifin}{cmd:,} {opt ar(#)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ar(#)}}autoregressive order {it:p}, 1 to 12; required{p_end}
{synopt :{opt ma(#)}}moving-average order {it:q}, 0 to 6; default {cmd:ma(1)}{p_end}
{synopt :{opt delay(#)}}delay {it:d} of the threshold variable; default {cmd:delay(1)}{p_end}
{synopt :{opt star}}test a threshold in the AR {bf:and} MA parameters
(the sLM* statistic){p_end}

{syntab:Threshold grid}
{synopt :{opt trim(#)}}search between the {it:#} and 1-{it:#} quantiles;
default {cmd:trim(0.25)}{p_end}
{synopt :{opt gridn(#)}}cap the grid at {it:#} points; default
{cmd:gridn(100)}, and {cmd:gridn(0)} uses every distinct value{p_end}

{syntab:Inference}
{synopt :{opt reps(#)}}recursive bootstrap replications; default {cmd:reps(499)}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synopt :{opt asymp:totic}}skip the bootstrap {bf:(read the warning below)}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be {helpb tsset} and the estimation sample must be a single
contiguous span. {cmd:thtarma} is a single-series command; panel data are
outside the scope of this package.


{marker description}{title:Description}

{pstd}
{cmd:thtarma} tests whether a threshold ARMA model fits significantly better
than a plain ARMA model of the same orders. The alternative is

{p 8 8 2}
X(t) = phi10 + SUM phi1k X(t-k) + e(t) - SUM theta1s e(t-s){break}
{space 7}+ ( Psi10 + SUM Psi1k X(t-k) - SUM Psi2s e(t-s) ) I( X(t-d) <= r )

{pstd}
and the null is {bf:Psi = 0}, which leaves an ARMA(p,q). The threshold {it:r}
is unknown, and under the null it does not appear in the model at all.

{pstd}
{bf:Why this needs its own command rather than another option on}
{helpb thtest}{bf:.} Every other linearity test in this package profiles out
a linear regression at each candidate threshold: the residual at a given
threshold is a closed-form function of the data, so a grid search is a sweep
of least-squares fits. An ARMA residual is not. It is defined by the
recursion

{p 8 8 2}
e(t) = X(t) - phi0 - SUM phi_k X(t-k) + SUM theta_s e(t-s),

{pstd}
so e(t) depends on every earlier residual and hence on the whole history.
Nothing can be profiled out in closed form, and the derivative of e(t) with
respect to any parameter is itself a recursion. That is the reason for a
separate engine.


{marker options}{title:Options}

{phang}
{opt ar(#)} and {opt ma(#)} set the orders of the null ARMA. They are assumed
{bf:known}, as in the paper. Choosing them by an information criterion first
and then testing is common practice, and the paper's own simulations report
that the test's behaviour is not much affected by it, but the uncertainty in
that choice is not carried into the p-value by this command or by any other.

{phang}
{opt delay(#)} sets which lag of the series is the threshold variable. It is
also assumed known. If you do not know it, run the command over a few
candidate delays and remember that choosing the most significant one is
itself a search that the p-values shown do not correct for.

{phang}
{opt star} switches from sLM to sLM*. See {it:{help thtarma##stats:The two
statistics}}.

{phang}
{opt trim(#)} sets the quantile range the threshold is searched over.
{cmd:trim(0.25)} is the default because it is the range the paper's tabulated
critical values were computed for; any other value silently invalidates
those, so the command stops reporting them.

{phang}
{opt gridn(#)} caps the number of candidate thresholds. The bootstrap
re-searches the grid on {it:every} replication, so an uncapped grid
multiplies the work by {cmd:reps()}. The cap is applied identically to the
observed statistic and to every bootstrap draw, which is what matters: the
bootstrap must reproduce the procedure that produced the observed number,
cap included.

{phang}
{opt asymptotic} skips the bootstrap and reports only the tabulated
asymptotic verdict. {bf:This is not the recommended mode.} The asymptotic
test is known to be oversized at small and moderate sample sizes, so it
rejects a linear ARMA more often than its nominal level. Use it to inspect
the statistic quickly, not to support a published rejection.


{marker stats}{title:The two statistics}

{pstd}
{bf:sLM} (the default) tests a threshold in the {bf:AR parameters only}: the
moving-average coefficients are held equal across regimes, and Psi has p+1
elements.

{pstd}
{bf:sLM*} ({cmd:star}) tests a threshold in the {bf:AR and the MA
parameters}: Psi has p+q+1 elements.

{pstd}
On the same data sLM* is computed from a strictly larger parameter set, so
it will come out larger. That does not make it the better test. It has more
degrees of freedom and a correspondingly higher critical value, so it is
{it:less} powerful when the threshold is in fact confined to the AR part.
Choose by what you want to test, not by which number is bigger.


{marker pvalue}{title:The p-value}

{pstd}
Under the null the threshold {it:r} is {bf:unidentified} {hline 2} it appears
nowhere in an ARMA model {hline 2} so the usual chi-squared theory does not
apply, and a nominal p-value would be wrong. The statistic is computed over a
grid of candidate thresholds and the supremum is taken, the same device used
by {helpb thtest} and described by Davies (1987) and Hansen (1996).

{pstd}
{bf:The recursive bootstrap is the default and is the figure to report.}
Giannerini, Goracci and Rahbek establish its validity for this statistic and
show that the asymptotic test is oversized at small and moderate {it:n}. Each
replication

{p 8 11 2}1. generates a pseudo-series {bf:recursively} from the fitted
{it:linear} ARMA, using residuals resampled from the null fit, so the null is
imposed by construction;{p_end}
{p 8 11 2}2. {bf:re-estimates} the ARMA on that pseudo-series; and{p_end}
{p 8 11 2}3. {bf:re-searches the whole threshold grid}.{p_end}

{pstd}
Steps 2 and 3 are the ones that are easy to skip and fatal to skip. The
observed statistic is a supremum taken after a fit; a bootstrap that held
either the fit or the winning threshold fixed would be the distribution of a
statistic nobody computed, and would over-reject.

{pstd}
The p-value uses the (count+1)/(reps+1) convention, so it is never exactly
zero: the observed statistic is itself one admissible draw under the null.

{pstd}
{bf:The tabulated critical values} from Table 1 of the paper are also shown,
for p = 1 to 4 and q = 1 to 2, and {bf:only} when {cmd:trim(0.25)} is in
effect, because that is the range they were simulated under. Outside those
cases the command prints no critical value rather than interpolating one the
paper never published.

{pstd}
{bf:A note on the published tables.} The R package {cmd:tseriesTARMA}, by two
of the paper's authors, prints slightly different critical values and indexes
them by {it:degrees of freedom} rather than by (p, q) {hline 2} for instance
9.09, 10.78 and 14.61 where the paper's Table 1 gives 9.61, 11.37 and 15.19.
{cmd:thtarma} quotes the paper's own table, because the paper is the
authority for this implementation and its table is indexed the way this
command is parameterised. The discrepancy is stated here rather than
reconciled silently.


{marker remarks}{title:Remarks}

{pstd}
{bf:The null ARMA is fitted by conditional Gaussian maximum likelihood}, with
the pre-sample errors set to zero, which is the likelihood the paper
specifies. This is {it:not} what {helpb arima} does by default: {cmd:arima}
uses exact maximum likelihood through the Kalman filter. The two are
asymptotically equivalent and will differ in finite samples, so do not expect
{cmd:r(b)} to reproduce {cmd:arima}'s coefficients exactly. They should imply
the same unconditional mean, and on a long series they do.

{pstd}
{bf:Invertibility matters here more than usual.} Assumption A1 of the paper
requires the MA polynomial to have all roots outside the unit circle. Every
derivative in the test is a recursion driven by that polynomial, so a nearly
non-invertible MA makes all of them nearly explosive and the statistic
unreliable. The command reports the largest inverse root modulus and warns
above 0.95.

{pstd}
{bf:The sample must be contiguous.} An ARMA residual is defined by a
recursion over consecutive periods. A gap in the time variable would make
every residual after it meaningless, so the command refuses rather than
producing a number.

{pstd}
{bf:What a rejection means.} It means a threshold ARMA fits better than a
linear ARMA at the stated orders and delay. It does not identify the
threshold: the reported value is where the statistic peaked, and this command
provides no confidence set for it. It also does not validate the orders. A
rejection is evidence of nonlinearity of this particular shape, not proof
that this is the right model.


{marker validation}{title:Validation}

{pstd}
The implementation was checked against {cmd:tseriesTARMA} 0.5-2, the R
package written by two of the paper's own authors, run as an independent
oracle on an identical 400-observation series. That package is distributed
under the GPL; none of its source was copied, and the Mata engine was written
from the paper's equations. On that series:

{p2colset 8 38 40 2}{...}
{p2col :{it:quantity}}{it:tseriesTARMA}{space 6}{it:THRESHKIT}{p_end}
{p2col :null ARMA sigma-squared}1.001286{space 8}1.0012861{p_end}
{p2col :maximising threshold}3.008297{space 8}3.0082969{p_end}
{p2col :sLM}4.025750{space 8}4.0299351{p_end}
{p2col :sLM*}4.587758{space 8}4.5909742{p_end}
{p2colreset}{...}

{pstd}
The residual variance and the maximising threshold agree to seven digits and
exactly, which means the conditional ARMA fit, the derivative recursions and
the grid search all match an independent implementation. The remaining
difference of about one part in a thousand sits in the assembly of the
concentrated information matrix; it is recorded in
{cmd:validation/thtarma/reference_lock.yml} rather than tuned away.


{marker results}{title:Stored results}

{pstd}{cmd:thtarma} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}the sLM or sLM* statistic{p_end}
{synopt:{cmd:r(p)}}bootstrap p-value; missing under {cmd:asymptotic}{p_end}
{synopt:{cmd:r(gamma)}}threshold at which the statistic peaked{p_end}
{synopt:{cmd:r(sigma2)}}residual variance of the null ARMA{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(ar)}, {cmd:r(ma)}, {cmd:r(delay)}}the orders and the delay{p_end}
{synopt:{cmd:r(trim)}}the quantile trimming used{p_end}
{synopt:{cmd:r(ngrid)}, {cmd:r(npoints)}}grid points offered and usable{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications actually used{p_end}
{synopt:{cmd:r(converged)}}1 if the null ARMA converged{p_end}
{synopt:{cmd:r(marad)}}largest inverse MA root modulus{p_end}
{synopt:{cmd:r(cv90)} ... {cmd:r(cv999)}}tabulated critical values, when they apply{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thtarma}{p_end}
{synopt:{cmd:r(statname)}}{cmd:sLM} or {cmd:sLM*}{p_end}
{synopt:{cmd:r(depvar)}}the series tested{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}null ARMA coefficients: intercept, AR, MA{p_end}
{synopt:{cmd:r(grid)}}the candidate thresholds searched{p_end}
{synopt:{cmd:r(bootdist)}}the bootstrap statistics{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}A threshold in the AR part of an ARMA(1,1), with the bootstrap{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. thtarma y, ar(1) ma(1) delay(1) reps(499) seed(42)}{p_end}

{pstd}A threshold in the AR and MA parts{p_end}
{phang2}{cmd:. thtarma y, ar(1) ma(1) delay(1) star reps(499) seed(42)}{p_end}

{pstd}A quick look at the statistic, without waiting for the bootstrap{p_end}
{phang2}{cmd:. thtarma y, ar(2) ma(1) delay(1) asymptotic}{p_end}

{pstd}Several delays. Remember that picking the smallest p-value from this
sweep is a search the individual p-values do not correct for{p_end}
{phang2}{cmd:. forvalues d = 1/3 {c -(}}{p_end}
{phang2}{cmd:.     quietly thtarma y, ar(1) ma(1) delay(`d') reps(299) seed(7)}{p_end}
{phang2}{cmd:.     display "d = `d'  stat = " r(stat) "  p = " r(p)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}Exporting the bootstrap distribution to look at it{p_end}
{phang2}{cmd:. thtarma y, ar(1) ma(1) reps(999) seed(1)}{p_end}
{phang2}{cmd:. matrix B = r(bootdist)}{p_end}
{phang2}{cmd:. svmat double B, name(bstat)}{p_end}
{phang2}{cmd:. histogram bstat1, xline(`=r(stat)')}{p_end}


{marker refs}{title:References}

{phang}
Chan, K. S., and G. Goracci. 2019. On the ergodicity of first-order threshold
autoregressive moving-average processes. {it:Journal of Time Series Analysis}
40: 256-264. {browse "https://doi.org/10.1111/jtsa.12440":doi:10.1111/jtsa.12440}

{phang}
Davies, R. B. 1987. Hypothesis testing when a nuisance parameter is present
only under the alternative. {it:Biometrika} 74: 33-43.
{browse "https://doi.org/10.1093/biomet/74.1.33":doi:10.1093/biomet/74.1.33}

{phang}
Giannerini, S., G. Goracci, and A. Rahbek. 2022. The validity of bootstrap
testing in the threshold framework. {it:arXiv} 2201.00028.
{browse "https://arxiv.org/abs/2201.00028":arXiv:2201.00028}

{phang}
Goracci, G., S. Giannerini, K. S. Chan, and H. Tong. 2023. Testing for
threshold effects in the TARMA framework. {it:Statistica Sinica} 33:
1879-1901.
{browse "https://doi.org/10.5705/ss.202021.0120":doi:10.5705/ss.202021.0120}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
