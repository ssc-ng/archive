{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "threshkit choose (jump or kink?)" "help threshkit_choose"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{viewerjumpto "Syntax" "thkink##syntax"}{...}
{viewerjumpto "Description" "thkink##description"}{...}
{viewerjumpto "Options" "thkink##options"}{...}
{viewerjumpto "Remarks: why the limit is normal" "thkink##normal"}{...}
{viewerjumpto "Kink or jump?" "thkink##which"}{...}
{viewerjumpto "Postestimation" "thkink##postest"}{...}
{viewerjumpto "Examples" "thkink##examples"}{...}
{viewerjumpto "Stored results" "thkink##results"}{...}
{viewerjumpto "References" "thkink##refs"}{...}
{title:Title}

{phang}
{bf:thkink} {hline 2} Regression kink with an unknown threshold: a continuous
regression function whose slope changes at an estimated point

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thkink} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth kinkvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth kinkvar(varname)}}variable in which the slope kinks{p_end}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt grange(# #)}}search only this range of kink points{p_end}
{synopt:{opt gstep(#)}}use a regular grid of this step instead of the observed values{p_end}
{synopt:{opt minobs(#)}}minimum observations on each side{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt test}}test H0: no kink (linear in {opt kinkvar()}){p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}* {opt kinkvar()} is required. {it:indepvars} enter linearly and do not switch.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thkink} fits the regression kink model of Hansen (2017):

{p 12 12 2}
{it:y_i} = {it:b1}({it:x_i} − {it:g})⁻ + {it:b2}({it:x_i} − {it:g})⁺ + {it:z_i}'θ + {it:e_i}

{pstd}
where ({it:u})⁻ = {it:u}·1{c -(}{it:u}<0{c )-} and ({it:u})⁺ = {it:u}·1{c -(}{it:u}>0{c )-}, {it:x}
is {opt kinkvar()} and {it:z} is {it:indepvars}. The fitted function is
{bf:continuous} at {it:g}: the level does not jump, only the slope in {it:x}
changes, from {it:b1} below to {it:b2} above.

{pstd}
This is a different model from {helpb thregress}, not a variant of it. Hansen
(2000) Assumption 1.7 explicitly {bf:excludes} the continuous case, so fitting a
jump model to kinked data gives an inconsistent threshold estimate, and the
reverse wastes information. {helpb threshkit_choose:help threshkit choose}
Step 2 is the decision rule.

{marker options}{...}
{title:Options}

{phang}
{opth kinkvar(varname)} is the variable whose slope changes. Everything in
{it:indepvars} enters linearly with a single coefficient.

{phang}
{opt grange(# #)} and {opt gstep(#)} define a regular search grid, which is how
Hansen's own application searches (debt/GDP from 10 to 70 in steps of 0.1). Without
them the grid is the distinct observed values of {opt kinkvar()} inside the
trimmed range, as in {helpb thregress}. Use the regular grid when the kink point
has a natural scale and you want a reproducible, data-independent grid.

{phang}
{opt test} tests H0: the model is linear in {opt kinkvar()}, using the sup-Wald
statistic over the grid and a Gaussian multiplier bootstrap. As in
{helpb thtest}, the kink point is unidentified under this null, so the p-value
must be simulated.

{marker normal}{...}
{title:Remarks: why the confidence interval here is an ordinary Wald interval}

{pstd}
In the discontinuous model of {helpb thregress} the threshold converges at rate
{it:n} to a non-standard limit, which is why that command inverts a likelihood
ratio instead of using a standard error. {bf:The kink model is different.}
Hansen (2017) shows that when the regression function is continuous, the kink
point is sqrt({it:n})-consistent and {bf:asymptotically normal}, jointly with the
slope coefficients.

{pstd}
So {cmd:thkink} reports {it:g} as an ordinary coefficient, with a standard error,
a z statistic and a symmetric confidence interval. That standard error is not the
naive one: the design is augmented with the derivative of the fitted function with
respect to {it:g}, and the cross-product is corrected, so the reported precision
of the slopes already accounts for {it:g} having been estimated. Nothing further
is needed — there is no two-step interval to compute, unlike
{cmd:thregress}.

{pstd}
Practical consequence: you can {helpb test} and {helpb lincom} the kink point
together with the slopes, and {cmd:lincom kink_above - kink_below} is the correct
test of "the slope does not change at the kink" {it:given} that a kink exists.
{cmd:estat slopetest} does exactly that.

{marker which}{...}
{title:Kink or jump? A short decision rule}

{p2colset 6 24 26 2}{...}
{p2col:{bf:Use thkink when}}theory says the relationship bends: a capacity constraint, diminishing returns above a level, a marginal rate that changes.{p_end}
{p2col:{bf:Use thregress when}}theory says something switches on: an eligibility cut-off, a tax bracket, a policy trigger. The level itself moves.{p_end}
{p2col:{bf:If unsure}}fit both. {cmd:estat continuity} after {cmd:thkink} reports the two SSRs. The jump model nests the kink, so its SSR is always smaller; a {it:large} gap is evidence against continuity, a small one says the kink restriction is nearly free and is worth keeping, because it buys a sqrt(n) rate and a normal limit.{p_end}
{p2colreset}{...}

{pstd}
A formal continuity test (Hidalgo, Lee, Lee and Seo) is scheduled for the next
release; the paper is in the project folder.

{marker postest}{...}
{title:Postestimation}

{p2colset 6 22 24 2}{...}
{p2col:{cmd:estat kinkplot}}data with the fitted kinked function and the kink point marked{p_end}
{p2col:{cmd:estat lrplot}}the Wald profile over candidate kink points (Hansen 2017, Figure 3){p_end}
{p2col:{cmd:estat slopetest}}test that the slope does not change{p_end}
{p2col:{cmd:estat continuity}}compare the kink fit with the jump fit{p_end}
{p2col:{cmd:estat pscore}}score test for the EXISTENCE of a breakpoint, with a
conventional reference distribution and no bootstrap{p_end}
{p2col:{cmd:estat serial}}no residual autocorrelation, against the kink design{p_end}
{p2col:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{p2col:{cmd:estat mcleodli}}McLeod-Li portmanteau on the squared residuals{p_end}
{p2col:{cmd:estat normality}}Jarque-Bera, with skewness and kurtosis components{p_end}
{p2col:{cmd:estat diag}}all four of the above in one table{p_end}
{p2col:{cmd:predict}}{cmd:xb}, {cmd:residuals}, {cmd:regime} (side of the kink){p_end}
{p2colreset}{...}

{pstd}
{cmd:estat kinkplot} and {cmd:estat regimeplot} are the same command, as are
{cmd:estat lrplot} and {cmd:estat profileplot}; both pairs are accepted so that
the name used after {helpb thregress} also works here.

{pstd}
{bf:The residual diagnostics} test the fitted residuals against the
{bf:gradient of the kink model}, not against {it:x} alone. For

{p 8 8 2}
{it:y} = {it:b1}({it:q}-{it:g}){bf:_} + {it:b2}({it:q}-{it:g}){bf:+} + {it:x}'{it:d} + {it:e}

{pstd}
that gradient is [ ({it:q}-{it:g}){bf:_} , ({it:q}-{it:g}){bf:+} , {it:x} ,
-{it:b1}1{c 123}{it:q}<={it:g}{c 125} - {it:b2}1{c 123}{it:q}>{it:g}{c 125} ],
and the {bf:last column is the derivative with respect to the kink point}.
Including it is the whole point: leave it out and the test silently conditions
on {it:g} being {bf:known}, which it is not, so a rejection could be nothing but
the estimation of {it:g} itself. {opt lags(#)} sets the order of the
serial-correlation and ARCH tests; the default is 4.

{pstd}
These matter for the kink model in particular, because a {it:jump} fitted as a
kink leaves a systematic pattern in the residuals around the breakpoint.
{cmd:estat continuity} is the direct test of that and these are the indirect
check. {cmd:estat normality} is worth reading before quoting the kink point's
standard error: the root-{it:n} normal limit for {it:psi} is what makes that
standard error meaningful in the first place.

{marker pscore}{...}
{title:Testing whether there is a breakpoint at all}

{pstd}
{cmd:estat pscore} tests the null of {bf:no breakpoint}, and it reaches that
question by a route unlike anything else in this package.

{pstd}
Every other threshold test here meets the same obstacle: the breakpoint does
not exist under the null, so the statistic is computed over a grid of
candidates and the {bf:supremum} is taken {hline 2} and the limit of that
supremum is not standard, which is why it needs a bootstrap or Davies' bound.

{pstd}
Muggeo (2016) {bf:averages} over the unidentified parameter instead of
maximising over it. The term that is undefined under the null is replaced by

{p 8 8 2}
phibar(i) = (1/K) SUM over k of phi(x(i), psi(k))

{pstd}
for K fixed values of psi spanning the admissible range. The averaged term no
longer depends on psi at all, so an ordinary score test can be formed, and it
has a {bf:conventional reference distribution}: no grid search, no bootstrap,
no tabulated bound.

{pstd}
The justification is not informal. It comes from de Finetti's extended
definition of a conditional quantity, under which E(X | B) stands in for X
when the conditioning event B is false; here B is the event that the
breakpoint coefficient is non-zero. The construction has a Bayesian flavour
{hline 2} equally spaced psi(k) amount to a uniform prior on psi, which the
paper argues is the reasonable choice under the null {hline 2} while involving
no prior-to-posterior step and no prior on anything else.

{pstd}
{bf:Two forms, and the default is the safer one.} Without options the test
includes {it:both} a jump term 1(x > psi) and a kink term (x - psi)+ and
refers the statistic to chi-squared with 2 degrees of freedom. With
{cmd:oneterm} only the kink term enters and the reference is a t. Use the
two-term form unless you are certain the function is continuous: it tests
both departures, which is what you want when continuity is itself in doubt.

{pstd}
{bf:Which sigma.} The paper shows the null and alternative variance estimates
are both consistent, so either gives the right size, but the null one
{bf:loses power}. The default therefore uses the fitted model's estimate;
{cmd:sigma0} switches to the null one for comparison.

{pstd}
{bf:On K.} The paper reports that the number and placement of the averaging
points are negligible in practice, and its simulations confirm it. The
default {cmd:k(20)} is ample; {cmd:trim()} keeps the extreme order statistics
out, where (x - psi)+ is nearly constant and contributes almost nothing.

{pstd}
{bf:Not Conniffe's (2001) pseudo-score}, despite the similar name. That statistic
plugs the unconstrained estimate psi-hat into the null residuals; but under
the null psi does not exist, so psi-hat has an unknown distribution and so
does the statistic {hline 2} and the paper notes this does not vanish
asymptotically. Averaging avoids estimating the nuisance at all.

{pstd}
Being an entirely different construction, it can disagree with
{helpb thtest}'s bootstrap or with {cmd:thtest, davies}. When it does, report
that it did.


{marker examples}{...}
{title:Examples}

{pstd}The shipped data are Reinhart-Rogoff US debt and growth, as used by
Hansen (2017): does the debt/GDP ratio bend the growth relationship?{p_end}

{phang2}{cmd:. use threshkit_kink}{p_end}

{pstd}Reproduce the published application exactly (kink at 43.8){p_end}
{phang2}{cmd:. set seed 20261001}{p_end}
{phang2}{cmd:. thkink gdp gdp1, kinkvar(debt1) grange(10 70) gstep(0.1) test}{p_end}

{pstd}Look at the fit and the criterion{p_end}
{phang2}{cmd:. estat kinkplot}{p_end}
{phang2}{cmd:. estat lrplot}{p_end}

{pstd}Does the slope actually change?{p_end}
{phang2}{cmd:. estat slopetest}{p_end}

{pstd}Is there a breakpoint at all? No bootstrap needed{p_end}
{phang2}{cmd:. estat pscore}{p_end}

{pstd}The kink-only form, when continuity is not in doubt{p_end}
{phang2}{cmd:. estat pscore, oneterm}{p_end}

{pstd}Is continuity defensible?{p_end}
{phang2}{cmd:. estat continuity}{p_end}

{pstd}Default grid (observed values, 15% trimming){p_end}
{phang2}{cmd:. thkink gdp gdp1, kinkvar(debt1) test}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:thkink} is {it:eclass}. It stores{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(gamma)}, {cmd:e(se_gamma)}}kink point and its standard error{p_end}
{synopt:{cmd:e(gamma_lo)}, {cmd:e(gamma_hi)}}Wald confidence interval for the kink point{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(ssr0)}}SSR of the kink model and of the linear model{p_end}
{synopt:{cmd:e(wald)}, {cmd:e(p)}, {cmd:e(crit)}}no-kink test, bootstrap p-value, critical value{p_end}
{synopt:{cmd:e(N_below)}, {cmd:e(N_above)}}observations on each side{p_end}
{synopt:{cmd:e(n_grid)}, {cmd:e(trim)}, {cmd:e(level)}}settings in force{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients {cmd:kink_below}, {cmd:kink_above}, {it:indepvars}, {cmd:_cons}, {cmd:gamma}{p_end}
{synopt:{cmd:e(profile)}}grid by 3: gamma, SSR, Wald{p_end}
{p2colreset}{...}

{marker valid}{...}
{title:Validation}

{pstd}
Checked against Hansen's own R code ({bf:cthresh/growth.r}) on his own data:
kink point 43.8, SSR 3738.2731680237, linear SSR 3835.3025371254, sup-Wald
5.65833515, and every coefficient and standard error including se({it:g}) =
12.0553205631, all agreeing to at least ten significant digits. See
{bf:tests/reference/thkink/certify_thkink.do}.

{marker refs}{...}
{title:References}

{phang}
Chan, K. S., and R. S. Tsay. 1998. Limiting properties of the least squares
estimator of a continuous threshold autoregressive model. {it:Biometrika} 85:
413-426.
{browse "https://doi.org/10.1093/biomet/85.2.413":doi:10.1093/biomet/85.2.413}.

{phang}
Hansen, B. E. 2017. Regression kink with an unknown threshold. {it:Journal of
Business & Economic Statistics} 35: 228-240.
{browse "https://doi.org/10.1080/07350015.2015.1073595":doi:10.1080/07350015.2015.1073595}.

{phang}
Hidalgo, J., J. Lee, and M. H. Seo. 2019. Robust inference for threshold
regression models. {it:Journal of Econometrics} 210: 291-309.
{browse "https://doi.org/10.1016/j.jeconom.2019.01.008":doi:10.1016/j.jeconom.2019.01.008}.

{phang}
Conniffe, D. 2001. Score tests when a nuisance parameter is unidentified
under the null hypothesis. {it:Journal of Statistical Planning and Inference}
97: 67-83.
{browse "https://doi.org/10.1016/S0378-3758(00)00346-3":doi:10.1016/S0378-3758(00)00346-3}.

{phang}
Muggeo, V. M. R. 2016. Testing with a nuisance parameter present only under
the alternative: a score-based approach with application to segmented
modelling. {it:Journal of Statistical Computation and Simulation} 86:
3059-3067.
{browse "https://doi.org/10.1080/00949655.2016.1149855":doi:10.1080/00949655.2016.1149855}.

{phang}
Reinhart, C. M., and K. S. Rogoff. 2010. Growth in a time of debt.
{it:American Economic Review} 100: 573-578.
{browse "https://doi.org/10.1257/aer.100.2.573":doi:10.1257/aer.100.2.573}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thregress}, {helpb thtest}, {helpb thselect}
{p_end}
