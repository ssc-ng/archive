{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thunitroot" "help thunitroot"}{...}
{vieweralsosee "thmtar" "help thmtar"}{...}
{vieweralsosee "thtvecm" "help thtvecm"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "thbandur##syntax"}{...}
{viewerjumpto "Description" "thbandur##description"}{...}
{viewerjumpto "Options" "thbandur##options"}{...}
{viewerjumpto "Why the critical values are fixed" "thbandur##fixed"}{...}
{viewerjumpto "The grid is not the usual grid" "thbandur##grid"}{...}
{viewerjumpto "Choosing between this and thunitroot" "thbandur##which"}{...}
{viewerjumpto "Remarks" "thbandur##remarks"}{...}
{viewerjumpto "Stored results" "thbandur##results"}{...}
{viewerjumpto "Examples" "thbandur##examples"}{...}
{viewerjumpto "References" "thbandur##refs"}{...}
{viewerjumpto "Author" "thbandur##author"}{...}

{title:Title}

{phang}
{bf:thbandur} {hline 2} Unit-root tests against a globally stationary
three-regime SETAR


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:thbandur} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Deterministic terms}
{synopt :{opt case(#)}}1 zero mean, 2 non-zero mean, 3 mean and trend;
default {cmd:case(2)}{p_end}
{synopt :{opt const:ant}}shorthand for {cmd:case(2)}{p_end}
{synopt :{opt trend}}shorthand for {cmd:case(3)}{p_end}

{syntab:Model}
{synopt :{opt lags(#)}}augmentation lags of D.{it:y}; default {cmd:lags(0)}{p_end}

{syntab:Threshold grid}
{synopt :{opt c:par(#)}}grid-width constant in the rule below; default {cmd:cpar(3)}{p_end}
{synopt :{opt d:elta(#)}}grid-shrinkage exponent, at least 0.5;
default {cmd:delta(0.5)}{p_end}
{synopt :{opt gridn(#)}}grid points per threshold, 2 to 200; default
{cmd:gridn(20)}{p_end}
{synopt :{opt mino:bs(#)}}minimum observations in each outer regime{p_end}
{synopt :{opt ming:ap(#)}}minimum width of the corridor{p_end}

{syntab:Inference}
{synopt :{opt reps(#)}}bootstrap replications; default {cmd:reps(0)}, meaning
the tabulated asymptotic values only{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be {helpb tsset} and the sample must be a single contiguous
span.


{marker description}{title:Description}

{pstd}
{cmd:thbandur} tests the null of a unit root against the alternative of a
{bf:globally stationary three-regime SETAR} {hline 2} a series that behaves
like a random walk while it sits inside a corridor, and reverts once it
leaves. That is the transaction-cost story: nothing pulls the series back
while the deviation is too small to be worth acting on, and something does
once it is large enough.

{pstd}
The underlying model is

{p 8 8 2}
y(t) = phi1 y(t-1) + u(t){space 8}if y(t-1) <= r1{break}
y(t) = phi0 y(t-1) + u(t){space 8}if r1 < y(t-1) <= r2{break}
y(t) = phi2 y(t-1) + u(t){space 8}if y(t-1) > r2

{pstd}
with a unit root in the middle and |phi1|, |phi2| < 1 outside. Writing
beta = phi - 1 and {bf:imposing beta0 = 0} {hline 2} a pure random walk in
the corridor, which is the theoretically motivated restriction and what
separates this test from the Bec-Ben Salem-Carrasco and Bec-Guay-Guerre
procedures {hline 2} the estimating equation is

{p 8 8 2}
D.y(t) = beta1 y(t-1) 1{c -(}y(t-1) <= r1{c )-}
{space 1}+ beta2 y(t-1) 1{c -(}y(t-1) > r2{c )-}
{space 1}+ SUM gamma(j) D.y(t-j) + e(t)

{pstd}
and the hypotheses are

{p 8 8 2}
H0: beta1 = beta2 = 0{space 6}(a unit root everywhere){break}
H1: beta1 < 0, beta2 < 0{space 2}(globally stationary three-regime SETAR)

{pstd}
Three statistics are reported, as in the paper: the supremum, the average
and the exponential average of the Wald statistic over the threshold grid.


{marker fixed}{title:Why the critical values are fixed}

{pstd}
Usually a statistic maximised over an unidentified nuisance parameter has a
null distribution that depends on the grid, which is why the rest of this
package bootstraps. Here it does not, and the reason is worth knowing.

{pstd}
Theorems 1 to 3 of the paper show that the asymptotic null distribution of
the Wald statistic {bf:does not depend on (r1, r2)} at all, and equals the
distribution at r1 = r2 = 0. A unit-root process spends a vanishing fraction
of its time {hline 2} of order T raised to the power -1/2 {hline 2} inside a
corridor of fixed width, so in the limit the corridor simply does not
matter. The supremum and the average therefore share the {it:same} limit, and
the exponential average has the limit of exp of half that.

{pstd}
That is why one table of critical values serves, why the sup and average
columns in the output are identical, and why no bootstrap is required for
validity. The values come from Table 1 of the paper and were tabulated from
random walks of 5,000 observations over 50,000 replications.

{pstd}
{bf:They are asymptotic values from a very long series.} Unit-root tests are
size-distorted in short samples, so on a few hundred observations
{cmd:reps()} is worth running as a check. The bootstrap imposes the null by
construction, cumulating resampled differences into a random walk, and
re-detrends, rebuilds the grid and re-searches every pair on each
replication.


{marker grid}{title:The grid is not the usual quantile grid}

{pstd}
This matters and is easy to get wrong. Under the conventional
quantile-trimming rule used elsewhere in this package, the thresholds would
{bf:diverge} under the null, and then Theorems 1 to 3 do not apply.
Assumption 3 of the paper instead requires a corridor of {bf:finite width
under both hypotheses}, delivered by searching the quantile band

{p 8 8 2}
pibar - c / T^delta{space 4}to{space 4}pibar + c / T^delta

{pstd}
where pibar is the sample quantile at zero. The band {it:shrinks} as T grows,
which is exactly what keeps the corridor finite. With the defaults
{cmd:cpar(3)} and {cmd:delta(0.5)}, a sample of 100 gives a band covering about
60% of the data, which is the illustration the paper gives. {cmd:cpar()} is the
{it:c} of the rule above and may be abbreviated to {cmd:c()}.

{pstd}
{cmd:delta()} below 0.5 is {bf:refused}. It is not a tuning knob: a smaller
exponent lets the thresholds diverge, Theorems 1 to 3 fail, and every
critical value printed becomes wrong while the output continues to look
entirely reasonable.


{marker which}{title:Choosing between this and thunitroot}

{pstd}
{helpb thunitroot} implements Caner and Hansen (2001). Both test a unit root
in a threshold model, and they are not interchangeable.

{p2colset 6 26 28 2}{...}
{p2col :{it:}}{it:thunitroot}{space 10}{it:thbandur}{p_end}
{p2col :regimes}two{space 17}three{p_end}
{p2col :transition variable}a lagged DIFFERENCE{space 1}the lagged LEVEL{p_end}
{p2col :corridor}none{space 16}random walk, imposed{p_end}
{p2col :inference}bootstrap{space 11}tabulated, bootstrap optional{p_end}
{p2colreset}{...}

{pstd}
Caner and Hansen use a lagged difference because it is stationary under the
null; that rules out the lagged level, which is precisely the variable a
band-of-inaction story needs. {cmd:thbandur} makes the opposite choice and
pays for it with a different asymptotic argument. If your alternative is a
band of inaction around a long-run relationship {hline 2} purchasing power
parity, a price spread, an interest-rate differential {hline 2} this is the
test aimed at it. If you want a general two-regime threshold with a unit
root and no particular corridor story, use {helpb thunitroot}.


{marker remarks}{title:Remarks}

{pstd}
{bf:A rejection does not establish the band.} It says the series is not a
unit root everywhere. The thresholds printed are where the statistic peaked
and carry {bf:no confidence set}; the asymptotic theory that makes the
critical values threshold-free is the same theory that says the thresholds
are not identified under the null. To estimate the band itself, fit it with
{helpb thmtar} (using {cmd:band}) or {helpb thtvecm} with {cmd:nthresh(2)}.

{pstd}
{bf:Which statistic to quote.} The paper reports all three and so does this
command. The supremum is the most familiar; the average and exponential
average are the Andrews-Ploberger style alternatives, which trade some power
against a sharply located alternative for power spread over the grid. Decide
before you look, and report all three if you looked at all three.

{pstd}
{bf:The delay is fixed at one.} The paper follows the literature in using
y(t-1) as the transition variable, and the asymptotics are derived for it.
This command does not offer a delay option, because a longer delay is not
covered by the theorems that make the tabulated values valid.

{pstd}
{bf:Serial correlation} is handled by {cmd:lags()}, which adds lagged
differences as in the paper's equation (23). The paper notes that the true
augmentation may enter non-linearly, in which case linear terms are a
first-order approximation.


{marker results}{title:Stored results}

{pstd}{cmd:thbandur} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(wsup)}, {cmd:r(wavg)}, {cmd:r(wexp)}}the three statistics{p_end}
{synopt:{cmd:r(p_sup)}, {cmd:r(p_avg)}, {cmd:r(p_exp)}}bootstrap p-values,
missing without {cmd:reps()}{p_end}
{synopt:{cmd:r(r1)}, {cmd:r(r2)}}thresholds at the supremum{p_end}
{synopt:{cmd:r(cv90)}, {cmd:r(cv95)}, {cmd:r(cv99)}}Table 1 values for sup and
average Wald{p_end}
{synopt:{cmd:r(cve90)}, {cmd:r(cve95)}, {cmd:r(cve99)}}Table 1 values for
exponential Wald{p_end}
{synopt:{cmd:r(N)}}observations used in the regression{p_end}
{synopt:{cmd:r(case)}, {cmd:r(lags)}}deterministic case and augmentation{p_end}
{synopt:{cmd:r(ngrid)}, {cmd:r(npairs)}}grid points and admissible pairs{p_end}
{synopt:{cmd:r(plo)}, {cmd:r(phi)}}the quantile band searched{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thbandur}{p_end}
{synopt:{cmd:r(depvar)}}the series tested{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(stat)}}the three statistics{p_end}
{synopt:{cmd:r(cvsup)}, {cmd:r(cvexp)}}the critical-value rows{p_end}
{synopt:{cmd:r(grid)}}the threshold grid searched{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}A de-meaned series, no augmentation{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. thbandur y, constant}{p_end}

{pstd}With a linear trend and two augmentation lags{p_end}
{phang2}{cmd:. thbandur y, trend lags(2)}{p_end}

{pstd}With a bootstrap check, which is worth doing in a short sample{p_end}
{phang2}{cmd:. thbandur y, constant lags(1) reps(999) seed(42)}{p_end}

{pstd}A wider threshold band and a finer grid{p_end}
{phang2}{cmd:. thbandur y, constant c(4) gridn(40)}{p_end}

{pstd}Compared against the linear test on the same series{p_end}
{phang2}{cmd:. dfuller y, lags(1)}{p_end}
{phang2}{cmd:. thbandur y, constant lags(1)}{p_end}

{pstd}After rejecting, estimate the band itself{p_end}
{phang2}{cmd:. thmtar y, band}{p_end}


{marker refs}{title:References}

{phang}
Balke, N. S., and T. B. Fomby. 1997. Threshold cointegration.
{it:International Economic Review} 38: 627-645.
{browse "https://doi.org/10.2307/2527284":doi:10.2307/2527284}

{phang}
Caner, M., and B. E. Hansen. 2001. Threshold autoregression with a unit root.
{it:Econometrica} 69: 1555-1596.
{browse "https://doi.org/10.1111/1468-0262.00257":doi:10.1111/1468-0262.00257}

{phang}
Enders, W., and C. W. J. Granger. 1998. Unit-root tests and asymmetric
adjustment with an example using the term structure of interest rates.
{it:Journal of Business and Economic Statistics} 16: 304-311.
{browse "https://doi.org/10.1080/07350015.1998.10524769":doi:10.1080/07350015.1998.10524769}

{phang}
Kapetanios, G., and Y. Shin. 2006. Unit root tests in three-regime SETAR
models. {it:Econometrics Journal} 9: 252-278.
{browse "https://doi.org/10.1111/j.1368-423X.2006.00184.x":doi:10.1111/j.1368-423X.2006.00184.x}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
