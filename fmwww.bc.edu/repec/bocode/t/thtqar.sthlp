{smcl}
{* *! version 1.0.0  03oct2026}{...}
{vieweralsosee "thqreg" "help thqreg"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{viewerjumpto "Syntax" "thtqar##syntax"}{...}
{viewerjumpto "Description" "thtqar##description"}{...}
{viewerjumpto "Options" "thtqar##options"}{...}
{viewerjumpto "What a quantile SETAR tells you that a SETAR does not" "thtqar##why"}{...}
{viewerjumpto "Reading it" "thtqar##reading"}{...}
{viewerjumpto "Examples" "thtqar##examples"}{...}
{viewerjumpto "Stored results" "thtqar##results"}{...}
{viewerjumpto "References" "thtqar##refs"}{...}
{title:Title}

{phang}
{bf:thtqar} {hline 2} Threshold quantile autoregression: a SETAR fitted at a
quantile instead of at the conditional mean


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtqar} {it:depvar} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{pstd}
The data must be {helpb tsset}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt ar(numlist)}}lags of {it:depvar} in the autoregression{p_end}
{synopt:{opt delay(#)}}delay {it:d} of the self-exciting threshold variable; default 1{p_end}
{synopt:{opth thv:ar(varname)}}use this threshold variable instead{p_end}
{synopt:{opt q:uantile(numlist)}}quantiles to fit; default {cmd:quantile(0.5)}{p_end}
{synopt:{opth inv:ariant(varlist)}}regressors whose coefficients do {it:not} switch{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points; default 50{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt test}}compute the sup/ave/exp-LR test of no threshold effect{p_end}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 0 (none){p_end}
{synopt:{opt boot(string)}}{opt resample} (default) or {opt wild}{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt vce(string)}}{opt robust} (default) or {opt iid}{p_end}
{synopt:{opt maxit(#)}}iterations of the quantile solver; default 25{p_end}
{synopt:{opt qtol(#)}}convergence tolerance of the solver; default 1e-10{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt ar()} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thtqar} fits

{p 8 8 2}
Q{sub:tau}({it:y_t} | {it:F_{t-1}}) = {bf:phi1}({it:tau})'{it:w_t}
1{c -(}{it:y_{t-d}} <= {it:gamma}{c )-} + {bf:phi2}({it:tau})'{it:w_t}
1{c -(}{it:y_{t-d}} > {it:gamma}{c )-}

{pstd}
with {it:w_t} the lags listed in {opt ar()}. It is a SETAR in which the regimes
describe a {it:quantile} of the conditional distribution rather than its mean.

{pstd}
{bf:It is a thin layer over {helpb thqreg}.} {cmd:thtqar} builds the
autoregression, picks the threshold variable, and hands the design to
{cmd:thqreg}; the search, the certified MM solver, the sup/ave/exp-LR test and
the reporting through official {helpb qreg} are all the same code. There is no
second implementation to keep in step, and everything in
{bf:{help thqreg:help thqreg}} about what the numbers mean -- and about what is
deliberately {it:not} provided, in particular that there is no confidence set
for {it:gamma} -- applies here unchanged.


{marker options}{...}
{title:Options}

{phang}
{opt ar(numlist)} lists the lags, and they need not be consecutive:
{cmd:ar(1 2 12)} is allowed.

{phang}
{opt delay(#)} sets the delay {it:d}, so the threshold variable is
{cmd:L}{it:d}{cmd:.}{it:depvar} and the model is {it:self-exciting}: the regime
is decided by where the series itself was {it:d} periods ago.

{phang}
{opth thvar(varname)} supplies an outside threshold variable instead, which
makes the model a TAR rather than a SETAR.

{pstd}
Every other option is passed straight through to {helpb thqreg}; see its help.


{marker why}{...}
{title:What a quantile SETAR tells you that a SETAR does not}

{pstd}
A mean SETAR ({helpb thtar}) asks whether the {it:average} dynamics differ
across regimes. A quantile SETAR asks whether the {it:shape} of the
conditional distribution does, and the two can give different answers.

{pstd}
{bf:The case worth knowing about.} Suppose a series mean-reverts at the same
average rate in both regimes, but in one regime the large negative shocks are
much more persistent than the large positive ones. A mean SETAR sees nothing:
the conditional means match. Fit the same model at {it:tau} = .1 and
{it:tau} = .9 and the persistence differs sharply between them. That asymmetry
in the tails is invisible to the mean and is exactly what this command is for.

{pstd}
{bf:And the reverse.} A threshold that shows up clearly at the median can
vanish in the tails, which says the regime structure governs typical behaviour
but not extremes. Either pattern is a result; neither is available from a
single mean regression.

{pstd}
With one regime this nests the quantile autoregression of Koenker and Xiao
(2006), so a {opt test} that does not reject is a statement that the quantile
autoregression suffices.


{marker reading}{...}
{title:Reading it}

{pstd}
{bf:Fit several quantiles at once and read {cmd:estat quantiles}.} The single
most informative output is the threshold as a function of {it:tau}:

{phang2}
{bf:gamma stable, coefficients changing} -- one regime boundary, different
dynamics along the distribution. The clean case.

{phang2}
{bf:gamma drifting monotonically with tau} -- often a sign that the real
transition is smooth rather than sharp. Compare {helpb thstar}.

{phang2}
{bf:gamma jumping about} -- usually weak identification. Check the gap column
of {cmd:estat profile}: if the winning grid point barely beats the runner-up at
that quantile, the threshold there is not pinned down and should not be
interpreted.

{pstd}
{bf:A searched delay invalidates the nominal p-value.} If you try several
{opt delay()} values and keep the best, the reported bootstrap p-value does not
account for that search. Choose the delay beforehand, or use
{helpb thnltest} -- whose arranged-autoregression test sweeps delays and
bootstraps the selected one -- to pick it, and say that you did.

{pstd}
{cmd:estat} and {cmd:predict} are {helpb thqreg}'s:
{cmd:estat profile}, {cmd:estat regimes}, {cmd:estat quantiles},
{cmd:estat table}; {cmd:predict} {opt xb}, {opt residuals}, {opt regime}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Is there anything nonlinear to model at all? Ask first{p_end}
{phang2}{cmd:. thnltest y, ar(1 2 3) reps(1000) seed(7)}{p_end}

{pstd}The median quantile SETAR{p_end}
{phang2}{cmd:. thtqar y, ar(1 2 3) delay(1)}{p_end}

{pstd}The tails against the centre -- the reason to use this command{p_end}
{phang2}{cmd:. thtqar y, ar(1 2 3) delay(1) quantile(0.1 0.25 0.5 0.75 0.9)}{p_end}
{phang2}{cmd:. estat quantiles, graph}{p_end}

{pstd}Is the threshold sharply identified at each quantile?{p_end}
{phang2}{cmd:. estat profile, graph}{p_end}

{pstd}With the test. Keep the grid and the replications modest to begin with{p_end}
{phang2}{cmd:. thtqar y, ar(1 2 3) delay(1) quantile(0.25 0.5 0.75) ///}{p_end}
{phang2}{cmd:      gridn(20) test reps(199) seed(3)}{p_end}

{pstd}Compare with the mean SETAR on the same series{p_end}
{phang2}{cmd:. thtar y, ar(1 2 3) delay(1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
Everything {helpb thqreg} stores, plus:

{synoptset 22 tabbed}{...}
{synopt:{cmd:e(cmd)}}{cmd:thtqar}{p_end}
{synopt:{cmd:e(model)}}{cmd:quantile SETAR} or {cmd:quantile TAR}{p_end}
{synopt:{cmd:e(arlags)}, {cmd:e(arnames)}}the lags, as numbers and as names{p_end}
{synopt:{cmd:e(lags)}, {cmd:e(delay)}}their count and the delay{p_end}
{synopt:{cmd:e(searched_delay)}}1 when the threshold variable is a lag of {it:depvar}{p_end}

{pstd}
The coefficient names are the real time-series expressions
({cmd:L1.}{it:depvar} and so on), not the temporary variables the
autoregression was built from.


{marker refs}{...}
{title:References}

{phang}
Caner, M. 2002. A note on least absolute deviation estimation of a threshold
model. {it:Econometric Theory} 18: 800-814.
{browse "https://doi.org/10.1017/s0266466602183113":doi:10.1017/s0266466602183113}

{phang}
Galvao, A. F., G. Montes-Rojas, and J. Olmo. 2011. Threshold quantile
autoregressive models. {it:Journal of Time Series Analysis} 32: 253-267.
{browse "https://doi.org/10.1111/j.1467-9892.2010.00696.x":doi:10.1111/j.1467-9892.2010.00696.x}

{phang}
Koenker, R., and Z. Xiao. 2006. Quantile autoregression.
{it:Journal of the American Statistical Association} 101: 980-990.
{browse "https://doi.org/10.1198/016214506000000672":doi:10.1198/016214506000000672}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb thqreg}, {helpb threshkit}, {helpb threshkit_choose},
{helpb thtar}, {helpb thstar}, {helpb thnltest}, {helpb qreg}
{p_end}
