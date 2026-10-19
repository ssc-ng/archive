{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{viewerjumpto "Syntax" "tvtlatent##syntax"}{...}
{viewerjumpto "Description" "tvtlatent##description"}{...}
{viewerjumpto "What makes this one different" "tvtlatent##different"}{...}
{viewerjumpto "Options" "tvtlatent##options"}{...}
{viewerjumpto "Reading the output" "tvtlatent##reading"}{...}
{viewerjumpto "Sample size, and how far to trust phi" "tvtlatent##chain"}{...}
{viewerjumpto "What is validated" "tvtlatent##validation"}{...}
{viewerjumpto "Examples" "tvtlatent##examples"}{...}
{viewerjumpto "Stored results" "tvtlatent##results"}{...}
{viewerjumpto "References" "tvtlatent##references"}{...}
{viewerjumpto "Author" "tvtlatent##author"}{...}
{title:Title}

{phang}
{bf:tvtlatent} {hline 2} Threshold model whose threshold is a latent
AR(1) process


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtlatent} {depvar} [{it:indepvars}] {ifin}{cmd:,}
{opth thr:eshvar(varname)} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opth threshvar(varname)}}the threshold variable {it:z}{p_end}

{syntab:The chain}
{synopt :{opt mcmcr:eps(#)}}total sweeps; default 20000{p_end}
{synopt :{opt burn:in(#)}}sweeps discarded; default 10000{p_end}
{synopt :{opt thin(#)}}keep every {it:#}th draw; default 1{p_end}
{synopt :{opt seed(#)}}make the chain reproducible{p_end}
{synopt :{opt trim(#)}}trimming for the starting fit; default 0.1{p_end}

{syntab:Priors}
{synopt :{opt au(#)}, {opt bu(#)}}inverse gamma for {it:sigma2_u};
default 2, 2{p_end}
{synopt :{opt ae(#)}, {opt be(#)}}inverse gamma for the two regime
variances; default 2, 2{p_end}
{synopt :{opt phia(#)}, {opt phib(#)}}scaled beta on (-1,1) for {it:phi};
default 1, 1, which is uniform{p_end}
{synopt :{opt mum:ean(#)}, {opt muv:ar(#)}}normal for {it:mu}; default 0,
1000{p_end}

{syntab:Other}
{synopt :{opt noconstant}}suppress the constant{p_end}
{synopt :{opt l:evel(#)}}credibility level for the HPD intervals{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The data must be {helpb tsset} and the estimation sample must have {bf:no
gaps}. See {it:What makes this one different}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtlatent} fits

{p 8 8 2}
{it:y_t} = {it:x_t}'{it:b1} 1{c -(}{it:z_t} <= {it:g_t}{c )-} +
{it:x_t}'{it:b2} 1{c -(}{it:z_t} > {it:g_t}{c )-} + {it:e_t}

{pstd}
in which the threshold is {bf:not observed and not a function of anything
observed}. It is a latent state with an autoregression of its own:

{p 8 8 2}
{it:g_t} = {it:mu} + {it:phi}({it:g_t-1} - {it:mu}) + {it:u_t},{space 3}
{it:u_t} ~ N(0, {it:sigma2_u})

{pstd}
The two regimes have their own innovation variances. Estimation is by
MCMC: the path is drawn one point at a time by Metropolis and everything
else in closed form.


{marker different}{...}
{title:What makes this one different}

{pstd}
Every other estimator in this library makes the threshold a function of
something you can see {hline 2} of {bf:time}
({helpb tvtfourier}, {helpb tvtlasso}), of the threshold variable's own
{bf:past} ({helpb tvtcotar}, {helpb tvtcotrk}), or of {bf:other
variables} ({helpb tvtcoint}, {helpb tvtboundary}, {helpb tvtindex},
{helpb tvtstar}, {helpb tvtcovdep}).

{pstd}
Here it is a function of nothing observed at all. Three things follow,
and they are the reason this command behaves unlike its siblings.

{phang}
{bf:1. The whole path is a parameter.} There is no profile likelihood to
maximise over a grid of candidate thresholds, so none of the
search-and-bootstrap machinery the rest of the library uses applies. What
comes back is a posterior, not a point estimate with a confidence
interval.

{phang}
{bf:2. The data must be {helpb tsset} and gap-free.} The state evolves in
time, so a gap is not simply a missing row: the threshold goes on moving
across it. Treating the stretches either side as contiguous would misdate
every threshold after the gap, so {cmd:tvtlatent} refuses rather than
guessing. Restrict to an unbroken stretch with {cmd:if}.

{phang}
{bf:3. It will always fit something.} A latent path has enough freedom to
track noise. {bf:That is the risk this command carries and the previous
point is how you manage it:} read {cmd:sigma2_u} and {cmd:phi}, and look
at the path with {helpb tvtplot}, before you read the slopes.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is required and may not also be a regressor.

{phang}
{opt mcmcreps()}, {opt burnin()}, {opt thin()} control the chain. The
defaults are the source's own. See {it:Sample size, and how far to trust
phi}.

{phang}
{opt trim()} applies only to the {bf:constant}-threshold least squares fit
that starts the chain and supplies the empirical priors for the two slope
vectors. It does not restrict the latent path.

{phang}
The prior options carry the source's values. {opt phia(1) phib(1)} is a
uniform prior on (-1,1) for {it:phi}; raising {opt phia()} pushes mass
toward +1 if you have a reason to expect a persistent threshold.


{marker reading}{...}
{title:Reading the output}

{pstd}
{bf:Read the threshold block before the slope block.} The two slopes are
only meaningful if there is a threshold worth speaking of.

{phang}
{bf:{cmd:sigma2_u} near 0} means the threshold barely moves. A
constant-threshold model would do, and
{helpb tvthomog} is the test that says so properly.

{phang}
{bf:{cmd:phi} near 1} means the threshold wanders rather than reverting to
{cmd:mu}; near 0 it is close to white noise around {cmd:mu}, which is
usually a sign that the data are not telling you much about the path.

{phang}
{bf:{cmd:mu} is weakly identified} in short samples and its HPD interval is
often very wide. That is a property of the model, not a failure of the
fit.

{phang}
{bf:The slopes attenuate.} Because regimes are classified by an estimated
latent path rather than observed, some observations land in the wrong
regime, and that pulls the two slope vectors {bf:toward each other}. The
gap between regimes is therefore a {bf:lower bound} on the true gap. See
{it:Sample size}.

{pstd}
Intervals are {bf:highest posterior density} intervals {hline 2} the
shortest interval holding the stated mass {hline 2} not central percentile
intervals. For a skewed posterior, and a threshold's usually is, they are
not the same, and the HPD is what the source reports.


{marker chain}{...}
{title:Sample size, and how far to trust phi}

{pstd}
{bf:At around 200 observations {cmd:phi} is badly biased toward 0 and
{cmd:sigma2_u} is biased up, and no amount of extra sampling fixes it.}
This is the single most important thing to know before reading the
threshold block.

{pstd}
Measured on the source's own design ({it:phi} = 0.9, {it:sigma2_u} = 0.5),
five replications each, chain fixed at the default 20000/10000:

{p2colset 9 20 24 2}{...}
{p2col :{bf:n}}{bf:phi}{space 8}{bf:sigma2_u}{space 4}{bf:corr with the true path}{p_end}
{p2col :200}0.477{space 8}0.859{space 10}0.595{p_end}
{p2col :500}0.857{space 8}0.536{space 10}0.756{p_end}
{p2col :1000}0.913{space 8}0.381{space 10}0.733{p_end}
{p2col :{it:truth}}{it:0.900}{space 8}{it:0.500}{p_end}
{p2colreset}{...}

{pstd}
Both converge on the truth as {it:n} grows. That is what tells you the
cause is {bf:finite-sample identification and not the sampler}: the path
is updated one point at a time, so if slow mixing were to blame, a
{it:longer} series would make matters worse, not better. It makes them
dramatically better.

{pstd}
{bf:So treat {cmd:phi} and {cmd:sigma2_u} as informative only from about
500 observations.} Below that the fitted path is still worth looking at
{hline 2} it already correlates about 0.6 with the truth at {it:n} = 200
{hline 2} but the two parameters describing how the threshold moves are
not to be reported as estimates of anything.

{pstd}
{bf:Chain length matters too, just much less.} At {it:n} = 200, cutting
the default 20000 sweeps to 4000 moved average {cmd:phi} from 0.71 to
0.64, with two replications of ten landing below 0.3. The defaults are
the source's own and are a floor, not a comfortable margin. If
{cmd:phi} comes back low, run it again with a different {opt seed()}
before believing it; if the two chains disagree, lengthen them.

{pstd}
{bf:The slopes attenuate, at every {it:n} measured.} Regimes are
classified by an estimated path, so some observations land on the wrong
side and the two slope vectors are pulled toward each other. In the study
above the fitted gap stayed below the true gap of 1.5 at all three sample
sizes. Read the gap between regimes as a {bf:lower bound}.

{marker validation}{...}
{title:What is validated}

{pstd}
{bf:Locked exactly against the authors' own MATLAB}: the
constant-threshold starting fit and its grid, the regime least squares at
a fixed threshold and at a fixed path, the moments of all six posterior
conditionals at a fixed state, the Metropolis proposal moments at the
first, an interior and the last observation, one acceptance ratio at a
proposal that flips the regime, and the particle-filter weights and
log-likelihood. All agree to machine precision.

{pstd}
{bf:Not locked, and cannot be}: the chains themselves. Stata and MATLAB
have different random number streams, so no sequence of draws will ever
agree. That is a property of the method, which is why the lock targets
every deterministic piece the sampler is built from instead.

{pstd}
{bf:Two defects in the source's {cmd:phi} step are corrected here}, and
both are stated in full in
{bf:validation/tvthresh/tvtlatent_equation_map.md}: its regression
denominator drops one term, and its acceptance ratio omits part of the
density of the first observation. Both are of order 1/{it:n} and neither
is visible in a trace plot. This command uses the conditional derived from
the model.

{pstd}
{bf:Validated by recovery} on the source's own designs rather than by
matching its tables, at three sample sizes. What that study found about
{cmd:phi} and {cmd:sigma2_u} is in {it:Sample size} above, and it is a
property of the model at small {it:n}, not a defect of this code.


{marker examples}{...}
{title:Examples}

{pstd}A mean shift whose threshold drifts {hline 2} the source's own
Case 1{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tvtlatent y, threshvar(z)}{p_end}

{pstd}Look at the path before reading the slopes{p_end}
{phang2}{cmd:. tvtplot}{p_end}

{pstd}With regressors, and reproducible{p_end}
{phang2}{cmd:. tvtlatent y x1 x2, threshvar(z) seed(20261014)}{p_end}

{pstd}A longer chain, which is what to do when {cmd:phi} comes back low{p_end}
{phang2}{cmd:. tvtlatent y x1 x2, threshvar(z) mcmcreps(60000) burnin(30000) thin(5)}{p_end}

{pstd}Check the answer is not an artefact of one chain{p_end}
{phang2}{cmd:. quietly tvtlatent y, threshvar(z) seed(1)}{p_end}
{phang2}{cmd:. display _b[thr:phi]}{p_end}
{phang2}{cmd:. quietly tvtlatent y, threshvar(z) seed(2)}{p_end}
{phang2}{cmd:. display _b[thr:phi]}{p_end}

{pstd}Ask first whether a constant threshold would do{p_end}
{phang2}{cmd:. tvthomog y x1 x2, threshvar(z)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtlatent} is {cmd:eclass} and stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(kept)}}draws retained{p_end}
{synopt:{cmd:e(mcmcreps)}}, {cmd:e(burnin)}, {cmd:e(thin)}{p_end}
{synopt:{cmd:e(gamma_ct)}}the constant-threshold starting value{p_end}
{synopt:{cmd:e(n_grid)}}candidates searched for it{p_end}
{synopt:{cmd:e(acc_path)}}acceptance rate for the path{p_end}
{synopt:{cmd:e(acc_phi)}}acceptance rate for {it:phi}{p_end}
{synopt:{cmd:e(trim)}}, {cmd:e(level)}, {cmd:e(k_regr)}{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtlatent}{p_end}
{synopt:{cmd:e(depvar)}}, {cmd:e(indepvars)}, {cmd:e(threshvar)},
{cmd:e(timevar)}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}posterior means{p_end}
{synopt:{cmd:e(V)}}posterior variance matrix{p_end}
{synopt:{cmd:e(path)}}one row per observation: posterior mean of the
threshold, then the HPD band. {helpb tvtplot} reads it{p_end}
{synopt:{cmd:e(hpd_lo)}, {cmd:e(hpd_hi)}}HPD interval per parameter{p_end}
{synopt:{cmd:e(draws)}}the retained draws, one row each{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Zhu, Y., H. Chen, and M. Lin. 2018. Threshold models with time-varying
threshold values and their application in estimating regime-sensitive
Taylor rules. {it:Studies in Nonlinear Dynamics & Econometrics} 23(5):
article 20170114.
{browse "https://doi.org/10.1515/snde-2017-0114":doi:10.1515/snde-2017-0114}

{phang}
Zhu, Y., and H. Chen. 2017. The asymmetry of U.S. monetary policy:
Evidence from a threshold Taylor rule with time-varying threshold values.
{it:Physica A} 473: 522-535.
{browse "https://doi.org/10.1016/j.physa.2017.01.023":doi:10.1016/j.physa.2017.01.023}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
