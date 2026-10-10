{smcl}
{* *! version 1.0.0  07oct2026}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thkink" "help thkink"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thsubci##syntax"}{...}
{viewerjumpto "Description" "thsubci##description"}{...}
{viewerjumpto "Options" "thsubci##options"}{...}
{viewerjumpto "Why the rate is the whole problem" "thsubci##rate"}{...}
{viewerjumpto "The block size" "thsubci##block"}{...}
{viewerjumpto "Which interval to use" "thsubci##which"}{...}
{viewerjumpto "Remarks" "thsubci##remarks"}{...}
{viewerjumpto "Stored results" "thsubci##results"}{...}
{viewerjumpto "Examples" "thsubci##examples"}{...}
{viewerjumpto "References" "thsubci##refs"}{...}
{viewerjumpto "Author" "thsubci##author"}{...}

{title:Title}

{phang}
{bf:thsubci} {hline 2} Subsampling confidence interval for a SETAR threshold


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thsubci} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ar(#)}}autoregressive order; default {cmd:ar(1)}{p_end}
{synopt :{opt delay(#)}}delay of the threshold variable; default
{cmd:delay(1)}{p_end}
{synopt :{opt trim(#)}}quantile trimming of the threshold grid; default
{cmd:trim(0.15)}{p_end}
{synopt :{opt mino:bs(#)}}minimum observations per regime{p_end}

{syntab:Subsampling}
{synopt :{opt rate(type)}}{cmd:estimate} (default), {cmd:continuous} or
{cmd:discontinuous}{p_end}
{synopt :{opt bl:ock(#)}}block size {it:b}; default is about n raised to 0.6{p_end}
{synopt :{opt maxb:lk(#)}}most blocks to evaluate per block size; default
{cmd:maxblk(150)}{p_end}
{synopt :{opt gv:als(numlist)}}exponents for the rate-fit block sizes;
default {cmd:0.5 0.6 0.7 0.8}{p_end}
{synopt :{opt tv:als(numlist)}}quantile levels for the rate fit; default
{cmd:0.6 0.7 0.8 0.9}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be {helpb tsset} and the sample must be a single contiguous
span.


{marker description}{title:Description}

{pstd}
{cmd:thsubci} builds a confidence interval for the threshold of a SETAR model
by subsampling, following Gonzalo and Wolf (2005). It fits the threshold on
every overlapping block of the series, measures how fast those subsample
estimates concentrate on the full-sample estimate, and converts that into an
interval.

{pstd}
The method's value is that it works {bf:without knowing the limiting
distribution} of the threshold estimator, and without knowing which of two
very different cases you are in.


{marker rate}{title:Why the rate is the whole problem}

{pstd}
The asymptotics of a SETAR threshold estimator depend on whether the model is
continuous:

{p2colset 6 24 26 2}{...}
{p2col :{bf:Discontinuous}}a jump at the threshold. n(rhat - r) converges to
the argmin of a compound Poisson process. The limit is non-standard, and
nobody knows how to estimate it consistently. {bf:Rate n.}{p_end}
{p2col :{bf:Continuous}}a kink, no jump. The limit is {bf:normal} and ordinary
inference works. {bf:Rate n to the power 1/2.}{p_end}
{p2colreset}{...}

{pstd}
So the two rates differ by a factor of n to the power one half, and which case
holds is exactly what is usually in doubt. An interval built on the wrong rate
is not slightly wrong: it is wrong by a factor that {bf:grows with the sample
size}.

{pstd}
Subsampling needs neither limiting distribution. Writing the rate as n to the
power beta, with beta either 1/2 or 1, the method estimates beta from the data
and remains asymptotically valid (the paper's Theorem 3.3) as long as that
estimate converges faster than 1/log n.

{pstd}
{bf:How beta is estimated.} Since the unscaled quantity |rhat(b) - rhat(n)|
shrinks at the same rate, its quantiles shrink at that rate too. The command
computes those quantiles at several block sizes and regresses the mean log
quantile on the log block size; the slope is minus beta. In short, the rate is
read off {bf:the speed at which subsample estimates concentrate as the block
grows}, which requires no knowledge of which case holds.

{pstd}
{bf:beta is reported, and clamped.} The theory admits only 1/2 and 1. An
estimate far outside a generous bracket around that range is a failure of the
estimator on your sample, not a refinement of the theory, and using it would
give an interval wrong by a power of n. The command prints the raw estimate,
and says so whenever it had to clamp.

{pstd}
{bf:Reading beta.} A value near 1 leans towards a jump, near 1/2 towards a
kink. It is a diagnostic, not a test; for a proper test of continuity see
{helpb thkink} and its {cmd:estat continuity}.


{marker block}{title:The block size}

{pstd}
Subsampling needs {it:b} to grow with {it:n} but more slowly. The default is
about n to the power 0.6, which satisfies that and leaves enough blocks to
pin down a quantile.

{pstd}
The interval is sensitive to this choice in finite samples, and that is an
acknowledged weakness of subsampling rather than a flaw in the
implementation. Try two or three block sizes. If the interval moves a great
deal, say so in the paper rather than reporting the one you preferred.

{pstd}
{cmd:maxblk()} caps how many blocks are actually evaluated at each block
size, by thinning the starting points evenly. Every overlapping block would
be thousands of SETAR fits per block size. Thinning changes the Monte Carlo
error of the subsampling distribution, not what it estimates, and the same
rule is applied at every block size so the rate regression is not distorted.
Raise it if the interval looks unstable.


{marker which}{title:Which interval to use}

{pstd}
The package offers three routes to a threshold interval, and they are not
interchangeable.

{p2colset 6 26 28 2}{...}
{p2col :{cmd:thregress, ci(lr)}}inverts the likelihood ratio. Standard,
fast, and can return a {it:disconnected} set, which is informative.{p_end}
{p2col :{cmd:estat gridboot}}inverts a test whose null fixes the threshold
(Hidalgo-Lee-Seo). Valid under both the jump and the kink, and needs no
rate.{p_end}
{p2col :{cmd:thsubci}}subsampling with an estimated rate. Needs no limiting
distribution at all, and gives you beta as a by-product.{p_end}
{p2colreset}{...}

{pstd}
They answer the same question by genuinely different routes and can disagree.
When they do, report that they did.

{pstd}
What is {it:not} valid: the nonparametric, wild and residual bootstraps.
{helpb thregress} refuses those outright for a threshold interval, on Yu's
(2014) result.


{marker remarks}{title:Remarks}

{pstd}
{bf:The interval is symmetric by construction.} The true limiting
distribution is not symmetric in the jump case, so read the output as a valid
interval and not as a picture of the sampling density.

{pstd}
{bf:On a continuous model the threshold is weakly identified,} and this shows
up honestly as a very wide interval. The sum-of-squares profile is nearly flat
near a kink, so subsample estimates scatter, beta comes out low and the
interval widens. That is the method being truthful about a hard problem: the
point estimate is what is poor, and no interval procedure can repair it. If
you believe the model is continuous, {helpb thkink} estimates it under that
restriction, which is far better than estimating it unrestricted and widening
the interval afterwards.

{pstd}
{bf:Subsampling under-covers in finite samples.} That is documented in the
paper's own simulations. Treat a short-sample interval as indicative, and
cross-check it against {cmd:estat gridboot}.

{pstd}
{bf:The series must be contiguous}, because the method cuts it into blocks of
consecutive observations and a gap would put observations from either side of
it into one block.

{pstd}
{bf:Cost.} The threshold is refitted on every retained block at every block
size. The engine profiles each block in a single ascending pass rather than
one regression per grid point, which is what makes this affordable at all,
but it is still the most expensive command in the package. Start with the
defaults.


{marker results}{title:Stored results}

{pstd}{cmd:thsubci} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(gamma)}}the full-sample threshold estimate{p_end}
{synopt:{cmd:r(lb)}, {cmd:r(ub)}}the interval{p_end}
{synopt:{cmd:r(hw)}}its half-width{p_end}
{synopt:{cmd:r(beta)}}the estimated rate exponent, before clamping{p_end}
{synopt:{cmd:r(beta_used)}}the exponent actually used{p_end}
{synopt:{cmd:r(block)}}block size{p_end}
{synopt:{cmd:r(nblocks)}}blocks evaluated for the interval{p_end}
{synopt:{cmd:r(nrate)}}block sizes used in the rate fit{p_end}
{synopt:{cmd:r(N)}}length of the series (the n in n to the power beta){p_end}
{synopt:{cmd:r(level)}, {cmd:r(ar)}, {cmd:r(delay)}}as specified{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(rate)}}{cmd:estimate}, {cmd:continuous} or {cmd:discontinuous}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(depvar)}}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(rateinfo)}}one row per block size used in the rate fit: the
block size, the number of blocks and the mean log quantile{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}The usual case: let the rate be estimated{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. thsubci y, ar(1) delay(1)}{p_end}

{pstd}When you are confident the model has a jump{p_end}
{phang2}{cmd:. thsubci y, ar(1) rate(discontinuous)}{p_end}

{pstd}Checking sensitivity to the block size, which you should do{p_end}
{phang2}{cmd:. foreach b of numlist 50 70 90 110 {c -(}}{p_end}
{phang2}{cmd:.     quietly thsubci y, ar(1) block(`b')}{p_end}
{phang2}{cmd:.     display "b = `b'  [" r(lb) ", " r(ub) "]  beta = " r(beta)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}Against the other two routes on the same data{p_end}
{phang2}{cmd:. thregress y L.y, threshvar(L.y) ci(lr)}{p_end}
{phang2}{cmd:. estat gridboot}{p_end}
{phang2}{cmd:. thsubci y, ar(1)}{p_end}

{pstd}Inspecting the rate fit itself{p_end}
{phang2}{cmd:. thsubci y, ar(1)}{p_end}
{phang2}{cmd:. matrix list r(rateinfo)}{p_end}


{marker refs}{title:References}

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics} 21:
520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}

{phang}
Chan, K. S., and R. S. Tsay. 1998. Limiting properties of the least squares
estimator of a continuous threshold autoregressive model. {it:Biometrika} 85:
413-426.
{browse "https://doi.org/10.1093/biomet/85.2.413":doi:10.1093/biomet/85.2.413}

{phang}
Gonzalo, J., and M. Wolf. 2005. Subsampling inference in threshold
autoregressive models. {it:Journal of Econometrics} 127: 201-224.
{browse "https://doi.org/10.1016/j.jeconom.2004.08.004":doi:10.1016/j.jeconom.2004.08.004}

{phang}
Politis, D. N., J. P. Romano, and M. Wolf. 1999. {it:Subsampling}. New York:
Springer.

{phang}
Yu, P. 2014. The bootstrap in threshold regression. {it:Econometric Theory}
30: 676-714.
{browse "https://doi.org/10.1017/S0266466614000012":doi:10.1017/S0266466614000012}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
