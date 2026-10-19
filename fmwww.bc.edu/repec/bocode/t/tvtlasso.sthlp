{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "[R] lasso" "help lasso"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtcovdep" "help tvtcovdep"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{vieweralsosee "tvtexport" "help tvtexport"}{...}
{viewerjumpto "Syntax" "tvtlasso##syntax"}{...}
{viewerjumpto "Description" "tvtlasso##description"}{...}
{viewerjumpto "When to use this and not tvtfourier" "tvtlasso##versus"}{...}
{viewerjumpto "Options" "tvtlasso##options"}{...}
{viewerjumpto "Which estimator is reported" "tvtlasso##which"}{...}
{viewerjumpto "The penalty lambda" "tvtlasso##lambda"}{...}
{viewerjumpto "How long this takes" "tvtlasso##speed"}{...}
{viewerjumpto "Why there are no standard errors" "tvtlasso##nose"}{...}
{viewerjumpto "Examples" "tvtlasso##examples"}{...}
{viewerjumpto "Stored results" "tvtlasso##results"}{...}
{viewerjumpto "Validation" "tvtlasso##validation"}{...}
{viewerjumpto "References" "tvtlasso##references"}{...}
{viewerjumpto "Author" "tvtlasso##author"}{...}
{title:Title}

{phang}
{bf:tvtlasso} {hline 2} High-dimensional threshold regression with a Fourier
time-varying threshold, by weighted LASSO


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtlasso} {depvar} {it:indepvars} {ifin}{cmd:,}
{opth thr:eshvar(varname)} [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:The model}
{synopt :{opth thr:eshvar(varname)}}required: the threshold variable
{it:q_t}{p_end}
{synopt :{opt nofour:ier}}constant threshold: set {it:gamma_1} =
{it:gamma_2} = 0{p_end}
{synopt :{opt nocons:tant}}no intercept in either regime{p_end}

{syntab:The penalty}
{synopt :{opt lambda(#)}}the l1 penalty; the default is chosen by BIC over
a path{p_end}
{synopt :{opt npath(#)}}points on the lambda path; default 100{p_end}
{synopt :{opt lr:atio(#)}}smallest lambda as a fraction of the largest;
default 0.001{p_end}
{synopt :{opt nothresh:olded}}report the weighted LASSO and skip the
thresholded one{p_end}
{synopt :{opt cgr:id(lo hi step)}}grid for {it:C} in {it:H = C lambda};
default {cmd:0.1 5 0.1}, the paper's{p_end}

{syntab:The threshold search}
{synopt :{opt trim(#)}}the grid runs from the {it:trim} to the
1-{it:trim} quantile of {it:q}; default 0.15, the paper's{p_end}
{synopt :{opt gstep(#)}}step of the threshold grid; default 0.1, the
paper's{p_end}
{synopt :{opt kgr:id(numlist)}}frequencies to search; default
{cmd:1 2 3 4 5}, the paper's{p_end}
{synopt :{opt it:erate(#)}}alternations between lambda and the threshold
search; default 2{p_end}

{syntab:The solver}
{synopt :{opt maxi:ter(#)}}coordinate descent iteration cap; default
10000{p_end}
{synopt :{opt tol:erance(#)}}convergence tolerance; default 1e-7{p_end}
{synopt :{opt l:evel(#)}}accepted and has no effect; see
{it:Why there are no standard errors}{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{it:indepvars} may contain factor variables; see {help fvvarlist}. There may
be more of them than there are observations.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtlasso} fits

{p 8 8 2}
{it:y_t} = {it:b1}'{it:x_t} + {it:e_t} if {it:q_t} <= {it:gamma_t},
{it:b2}'{it:x_t} + {it:e_t} otherwise{break}
{it:gamma_t} = {it:gamma_0} + {it:gamma_1} sin(2*pi*{it:k}*t/T) +
{it:gamma_2} cos(2*pi*{it:k}*t/T)

{pstd}
where {it:x_t} may have {bf:more elements than there are observations} and
only a few of them matter. It implements Yang (2024), which penalises the
coefficients by a weighted l1 norm and so does three things at once:

{phang2}
{bf:1.} estimates the regression coefficients consistently;{p_end}
{phang2}
{bf:2.} {bf:selects} which covariates belong in the model;{p_end}
{phang2}
{bf:3.} {bf:decides whether there is a threshold effect at all} --
whether the model is a threshold model or just a linear one.{p_end}

{pstd}
The third is worth spelling out. Writing {it:delta} = {it:b1} - {it:b2} for
the regime shift, the question "is this a threshold model" is the question
"is {it:delta} zero". The LASSO answers it by selection: if no shift term
survives, the evidence is for a linear model. The paper's Theorem 6 is the
consistency result behind that, and the output says which way it came out.
{bf:No pretest is needed, and that is the point} -- in a classical
low-dimensional threshold model the estimation procedure differs according
to whether a threshold exists, and here it does not.


{marker versus}{...}
{title:When to use this and not tvtfourier}

{pstd}
{helpb tvtfourier} is the same threshold function on a specification you
have already fixed, by least squares, with bootstrap tests and intervals.
{cmd:tvtlasso} is its {bf:high-dimensional} counterpart: it chooses the
specification and gives no intervals.

{pstd}
So:

{phang2}
{bf:few candidate regressors, specification settled} {hline 1}
{helpb tvtfourier}. It tests the threshold and gives you inference.{p_end}
{phang2}
{bf:many candidate regressors, perhaps more than observations}
{hline 1} {cmd:tvtlasso}. Then refit what it retains with
{helpb tvtfourier} on {bf:independent} data if you need inference.{p_end}

{pstd}
The other selection command in the library, {helpb tvtcovdep}, also chooses
a specification, but its threshold moves with {bf:observed covariates}
rather than with {bf:time}. Choose between them on what you think moves the
threshold, not on the dimension: see {helpb tvthresh_choose}.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is required and names the threshold variable
{it:q_t}. It may not also appear in {it:indepvars}.

{phang}
{opt nofourier} sets {it:gamma_1} = {it:gamma_2} = 0, which gives the
{bf:constant-threshold} high-dimensional estimator of
Lee, Seo and Shin (2016) and of Callot et al. (2017).
It is here for two reasons: it is what you want
if the threshold really is constant, and it is the comparison the paper's
own second experiment makes. Running both is the cheapest way to see
whether the time variation is doing any work.

{phang}
{opt lambda(#)} fixes the penalty. The default selects it by BIC over a
path; see {it:The penalty lambda}.

{phang}
{opt nothresholded} reports the weighted LASSO of equation (6) instead of
the thresholded LASSO of equation (16). See {it:Which estimator is
reported}.

{phang}
{opt cgrid(lo hi step)} is the grid searched for {it:C} in the hard
threshold {it:H} = {it:C} * {it:lambda}. The default {cmd:0.1 5 0.1} is the
paper's. It must ascend.

{phang}
{opt trim(#)} and {opt gstep(#)} define the threshold grid: from the
{it:trim} quantile of {it:q} to the 1-{it:trim} quantile, in steps of
{it:gstep}, for each of {it:gamma_0}, {it:gamma_1} and {it:gamma_2}. The
defaults 0.15 and 0.1 are the paper's. {opt gstep()} is the single biggest
lever on run time, because the grid is three-dimensional: doubling it is
roughly an eightfold saving.

{phang}
{opt kgrid(numlist)} is the set of frequencies searched. The default
{cmd:1 2 3 4 5} follows Becker, Enders and Lee (2006) and is the paper's.
Fixing it at one value divides the work by five, and is reasonable when you
have a prior about the period of the variation.

{phang}
{opt iterate(#)} is how many times {it:lambda} and the threshold search
alternate. Equation (7) minimises over the threshold at a {bf:fixed}
{it:lambda}, so one has to be chosen before the search can start; the
default 2 means "choose lambda at a pilot split, search, choose lambda
again at the split found, search again". {cmd:iterate(1)} halves the run
time at some cost in the quality of {it:lambda}.


{marker which}{...}
{title:Which estimator is reported}

{pstd}
Two are computed and both are returned.

{phang}
{bf:The weighted LASSO}, equation (6), in {cmd:e(b_wl)}. It shrinks but
rarely sets coefficients exactly to zero, so it tends to retain all the
relevant variables and a good many irrelevant ones.

{phang}
{bf:The thresholded LASSO}, equation (16), in {cmd:e(b)} and reported in
the output. It takes the weighted LASSO and zeroes every coefficient
smaller in absolute value than {it:H} = {it:C} * {it:lambda}, with {it:C}
chosen by BIC. This is the one that selects well, and it is the paper's
recommendation.

{pstd}
{bf:Equation (16) does not refit the survivors}, and this command does not
either. That is visible in the paper's own Table 1, where the thresholded
estimator's mean square prediction error is {it:worse} than the weighted
LASSO's in several cells -- refitting could only lower the sum of squares,
so those rows are only possible without one. If you want a refit, take
{cmd:e(selected)} and run {helpb tvtfourier} or {helpb regress} on the
retained terms yourself, and understand that you are then no longer
computing the paper's estimator.


{marker lambda}{...}
{title:The penalty lambda}

{pstd}
{bf:The paper's theoretical formula is not a usable recipe.} It sets
{it:lambda} = {it:A} {it:sigma} {it:m}^(1/{it:d})
{{log(3{it:m})/T}}^(1/2) for "a constant {it:A} > 0", and its simulation
section specifies none of {it:A}, {it:sigma} or {it:d} -- {it:d} is only
the order of a moment that a bound in the proof needs finite, and
{it:m}^(1/{it:d}) tends to 1 as {it:d} grows. There is no number in it.

{pstd}
What the paper actually ran was {bf:glmnet}, and its text endorses the BIC
for the regularisation parameters, citing Zou, Hastie and Tibshirani (2007)
for the degrees of freedom and Wang, Li and Leng (2009) for selection
consistency. So the default here selects {it:lambda} by {bf:BIC} over a
geometric path of {opt npath()} points running from the smallest value that
zeroes every coefficient down to {opt lratio()} times it, with

{p 8 12 2}
BIC = T log(SSR/T) + log(T) * (number of nonzero coefficients).

{pstd}
{cmd:e(lambda_auto)} records whether {it:lambda} was computed or given, and
{cmd:e(lambda_pilot)} the value at the pilot split before any alternation.

{pstd}
To use AIC instead, which keeps more terms and is not selection
consistent, pass it explicitly after inspecting the path.


{marker speed}{...}
{title:How long this takes}

{pstd}
{bf:Minutes, not seconds, and that is inherent.} The threshold search is
three-dimensional -- {it:gamma_0}, {it:gamma_1}, {it:gamma_2} -- times the
frequencies, and every grid point needs its own LASSO fit. At the paper's
own defaults with {it:T} = 200 and {it:m} = 50 that is tens of thousands of
fits. For orientation, the paper reports {bf:97 to 300 seconds per
replication} for its own R implementation, and this command is in the same
range.

{pstd}
In descending order of effect, the levers are:

{phang2}
{opt gstep()} {hline 1} the grid is cubic in it, so {cmd:gstep(0.2)} is
about eight times faster than {cmd:gstep(0.1)};{p_end}
{phang2}
{opt kgrid()} {hline 1} one frequency instead of five is five times
faster;{p_end}
{phang2}
{opt iterate(1)} {hline 1} halves it;{p_end}
{phang2}
{opt nofourier} {hline 1} collapses the search to one dimension and is
nearly instant.{p_end}

{pstd}
{cmd:e(n_visited)} reports how many LASSO fits were actually done and
{cmd:e(n_skipped)} how many grid points were recognised as giving a split
already seen. A sensible way to work is to explore with a coarse
{opt gstep()} and one frequency, then run the defaults once for the
reported result.


{marker nose}{...}
{title:Why there are no standard errors}

{pstd}
{bf:None are reported, and that is deliberate.} Any would be conditional on
the selection while ignoring that the selection happened. The paper derives
non-asymptotic oracle inequalities, sup-norm bounds and selection
consistency -- not a post-selection distribution -- and neither does this
command. {cmd:e(V)} is posted as zeros only because {cmd:ereturn post}
requires a matrix; it is not an estimate of anything.

{pstd}
{opt level()} is accepted so the command composes with the rest of the
library, and has no effect.

{pstd}
For inference on what was retained, refit with {helpb tvtfourier} on data
that did not choose it.


{marker examples}{...}
{title:Examples}

{pstd}
Fifty candidate regressors, two hundred observations, and a threshold that
moves with a one-cycle Fourier term:{p_end}

{phang2}{cmd:. set seed 81001}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. generate int t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. forvalues j = 1/50 {c -(}}{p_end}
{phang2}{cmd:.     quietly generate double x`j' = rnormal(0, 0.5)}{p_end}
{phang2}{cmd:.     quietly replace x`j' = 0.5*x`j'[_n-1] + rnormal(0, 0.5) in 2/l}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. generate double q = rnormal()}{p_end}
{phang2}{cmd:. quietly replace q = 0.5*q[_n-1] + rnormal() in 2/l}{p_end}
{phang2}{cmd:. generate double gam = 0.5 + 0.5*sin(2*_pi*t/200) + 0.5*cos(2*_pi*t/200)}{p_end}
{phang2}{cmd:. generate double y = x1 + x2 + (x1 + x2)*(q <= gam) + rnormal(0, 0.5)}{p_end}

{pstd}
Explore first, with a coarse grid and one frequency:{p_end}
{phang2}{cmd:. tvtlasso y x1-x50, threshvar(q) gstep(0.3) kgrid(1) iterate(1)}{p_end}

{pstd}
Then the paper's own settings for the reported result:{p_end}
{phang2}{cmd:. tvtlasso y x1-x50, threshvar(q)}{p_end}

{pstd}
Is the time variation doing any work? Compare against the
constant-threshold LASSO on the same data:{p_end}
{phang2}{cmd:. tvtlasso y x1-x50, threshvar(q) nofourier}{p_end}
{phang2}{cmd:. display e(mse)}{p_end}

{pstd}
What was retained, and was there a threshold effect at all:{p_end}
{phang2}{cmd:. matrix list e(selected)}{p_end}
{phang2}{cmd:. display "shift terms retained: " e(k_shift)}{p_end}

{pstd}
The weighted LASSO alongside the thresholded one:{p_end}
{phang2}{cmd:. matrix list e(b_wl)}{p_end}
{phang2}{cmd:. display e(df_wl) " vs " e(df_th)}{p_end}

{pstd}
The fitted threshold against the data:{p_end}
{phang2}{cmd:. matrix p = e(path)}{p_end}
{phang2}{cmd:. svmat double p, name(gamhat)}{p_end}
{phang2}{cmd:. twoway line gamhat1 t || scatter q t, msize(tiny)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtlasso} is {cmd:eclass} and stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(m)}}number of candidate regressors{p_end}
{synopt:{cmd:e(gamma0)}}the threshold intercept{p_end}
{synopt:{cmd:e(gamma1)}}the sine amplitude{p_end}
{synopt:{cmd:e(gamma2)}}the cosine amplitude{p_end}
{synopt:{cmd:e(k)}}the selected frequency{p_end}
{synopt:{cmd:e(lambda)}}the penalty used{p_end}
{synopt:{cmd:e(lambda_pilot)}}its value at the pilot split{p_end}
{synopt:{cmd:e(lambda_auto)}}1 if chosen by BIC{p_end}
{synopt:{cmd:e(H)}}the hard threshold {it:C}*{it:lambda}{p_end}
{synopt:{cmd:e(C)}}{it:C}, chosen by BIC{p_end}
{synopt:{cmd:e(crit)}}the penalised criterion attained{p_end}
{synopt:{cmd:e(ssr)}}SSR/T at the weighted LASSO{p_end}
{synopt:{cmd:e(mse)}}SSR/T at the reported estimator{p_end}
{synopt:{cmd:e(df_wl)}}terms retained by the weighted LASSO{p_end}
{synopt:{cmd:e(df_th)}}terms retained by the thresholded LASSO{p_end}
{synopt:{cmd:e(k_shift)}}shift terms retained: zero means no threshold
effect{p_end}
{synopt:{cmd:e(N_lower)}}observations with {it:q_t} <= {it:gamma_t}{p_end}
{synopt:{cmd:e(N_upper)}}observations above{p_end}
{synopt:{cmd:e(n_visited)}}LASSO fits performed{p_end}
{synopt:{cmd:e(n_skipped)}}grid points recognised as duplicate splits{p_end}
{synopt:{cmd:e(minreg)}}minimum regime size imposed{p_end}
{synopt:{cmd:e(trim)}}the trimming fraction{p_end}
{synopt:{cmd:e(gstep)}}the grid step{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtlasso}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}the candidate regressors{p_end}
{synopt:{cmd:e(threshvar)}}the threshold variable{p_end}
{synopt:{cmd:e(kgrid)}}the frequencies searched{p_end}
{synopt:{cmd:e(estimator)}}which estimator {cmd:e(b)} holds{p_end}
{synopt:{cmd:e(fourier)}}{cmd:Fourier} or {cmd:constant}{p_end}
{synopt:{cmd:e(title)}}title in the output{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}the thresholded LASSO, in equations {cmd:level:} and
{cmd:shift:}{p_end}
{synopt:{cmd:e(V)}}zeros; see {it:Why there are no standard errors}{p_end}
{synopt:{cmd:e(b_wl)}}the weighted LASSO{p_end}
{synopt:{cmd:e(selected)}}0/1 indicators matching {cmd:e(b)}{p_end}
{synopt:{cmd:e(selected_wl)}}0/1 indicators matching {cmd:e(b_wl)}{p_end}
{synopt:{cmd:e(path)}}the fitted threshold, one row per observation{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker validation}{...}
{title:Validation}

{pstd}
No code ships with the paper: its supplement contains only EPS images of
its own tables, and its simulations were run in R with glmnet. The
implementation here is clean-room from the published equations.

{pstd}
{bf:The solver is pinned exactly, without reference to the paper.} A LASSO
solution is characterised completely by two properties, and both are
checked to machine precision: at {it:lambda} = 0 it must be ordinary least
squares (agrees to 5e-11 in the coefficients and 1e-16 in the sum of
squares), and at {it:lambda} > 0 it must satisfy the Karush-Kuhn-Tucker
conditions (violations of 1e-13 or less on the retained coefficients, and
{bf:exactly zero} on the excluded ones, which is what shows the active-set
cycling never stops short of the true optimum).

{pstd}
{bf:Two things the paper's simulation section never states had to be
recovered from its own tables}, and both are recorded in full in
{bf:validation/tvthresh/tvtlasso_equation_map.md}:

{phang2}
{bf:1.} The distribution of {it:q}. The paper says only that "{it:q_t} is
generated as {it:x_it}", which does not carry the innovation variance
across. Its {bf:Regime1} column -- the share of observations below the true
threshold, which involves no estimator at all -- is 0.649 to 0.655
throughout, and that is matched only by an AR(1) with {bf:N(0,1)}
innovations (0.6537). The stated N(0, 0.5^2) governs the covariates.
Reading it as applying to {it:q} gives 0.734 and makes the regimes
materially more unbalanced than anything the paper reports.{p_end}

{phang2}
{bf:2.} The error variance. Table 1's MSE column settles it: in the
cleanest cell the threshold is recovered exactly, classification accuracy
is 1.000 and no true term is dropped, and MSE there is 0.259, so
{bf:sigma = 0.5}.{p_end}

{pstd}
On one draw at the paper's exact design -- {it:m} = 50, {it:T} = 200,
{it:a} = 1, {cmd:gstep(0.1)} -- the command recovers
{it:gamma} = (0.477, 0.577, 0.577) against a truth of (0.5, 0.5, 0.5),
every one within a single grid step; selects the true support
{bf:exactly}, with no zero coefficient retained and no nonzero one
dropped; keeps all five shift terms; and reaches a classification accuracy
of {bf:0.9950} against the paper's 0.994 for that cell.

{pstd}
The suite is {bf:tests/reference/tvtlasso/certify_tvtlasso.do}. Its
replicated sections use a reduced design -- fewer replications, a coarser
grid, {it:m} = 20 -- because the paper's budget of 1000 replications at
97-300 seconds each is tens of hours per cell; the suite says so where it
matters and checks the paper's qualitative claims there rather than its
exact figures.


{marker references}{...}
{title:References}

{phang}
Yang, L. 2024. High dimensional threshold model with a time-varying
threshold based on Fourier approximation. {it:Studies in Nonlinear
Dynamics & Econometrics} 28(1): 83-117.
{browse "https://doi.org/10.1515/snde-2021-0047":doi:10.1515/snde-2021-0047}

{phang}
Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series
Analysis} 27(3): 381-409.
{browse "https://doi.org/10.1111/j.1467-9892.2006.00478.x":doi:10.1111/j.1467-9892.2006.00478.x}

{phang}
Callot, L., M. Caner, A. B. Kock, and J. A. Riquelme. 2017. Sharp
threshold detection based on sup-norm error rates in high-dimensional
models. {it:Journal of Business & Economic Statistics} 35(2): 250-264.
{browse "https://doi.org/10.1080/07350015.2015.1052461":doi:10.1080/07350015.2015.1052461}

{phang}
Lee, S., M. H. Seo, and Y. Shin. 2016. The lasso for high dimensional
regression with a possible change point. {it:Journal of the Royal
Statistical Society, Series B} 78(1): 193-210.
{browse "https://doi.org/10.1111/rssb.12108":doi:10.1111/rssb.12108}

{phang}
Wang, H., B. Li, and C. Leng. 2009. Shrinkage tuning parameter selection
with a diverging number of parameters. {it:Journal of the Royal
Statistical Society, Series B} 71(3): 671-683.
{browse "https://doi.org/10.1111/j.1467-9868.2008.00693.x":doi:10.1111/j.1467-9868.2008.00693.x}

{phang}
Yang, L., C. Lee, and I.-P. Chen. 2021. Threshold model with a time-varying
threshold based on Fourier approximation. {it:Journal of Time Series
Analysis} 42(4): 406-430.
{browse "https://doi.org/10.1111/jtsa.12574":doi:10.1111/jtsa.12574}

{phang}
Zou, H., T. Hastie, and R. Tibshirani. 2007. On the degrees of freedom of
the lasso. {it:The Annals of Statistics} 35(5): 2173-2192.
{browse "https://doi.org/10.1214/009053607000000127":doi:10.1214/009053607000000127}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
