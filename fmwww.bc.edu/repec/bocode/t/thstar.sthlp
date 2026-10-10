{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{viewerjumpto "Syntax" "thstar##syntax"}{...}
{viewerjumpto "Description" "thstar##description"}{...}
{viewerjumpto "Options" "thstar##options"}{...}
{viewerjumpto "The modelling cycle" "thstar##cycle"}{...}
{viewerjumpto "Remarks: gamma is weakly identified" "thstar##gamma"}{...}
{viewerjumpto "Postestimation" "thstar##postest"}{...}
{viewerjumpto "Examples" "thstar##examples"}{...}
{viewerjumpto "Stored results" "thstar##results"}{...}
{viewerjumpto "References" "thstar##refs"}{...}
{title:Title}

{phang}
{bf:thstar} {hline 2} Smooth transition autoregression: LSTAR, ESTAR and
second-order LSTAR

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thstar} {depvar} {ifin}{cmd:,} {opt ar(numlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt ar(numlist)}}lags of {it:depvar} to include{p_end}
{synopt:{opt ty:pe(string)}}{opt lstar1} (default), {opt estar}, {opt lstar2}{p_end}
{synopt:{opt delay(#)}}delay for the self-exciting transition variable; default 1{p_end}
{synopt:{opth thv:ar(varname)}}use this transition variable instead{p_end}
{synopt:{opt trim(#)}}trimming for the location grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt ngamma(#)}}grid points for the smoothness; default 20{p_end}
{synopt:{opt nc(#)}}grid points for the location; default 40{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt vce(robust)}}heteroskedasticity-robust standard errors{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt ar()} is required. The data must be {helpb tsset}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thstar} fits the smooth transition autoregression

{p 12 12 2}
{it:y_t} = {it:x_t}'φ{sub:1}(1 − {it:G}({it:z_t})) + {it:x_t}'φ{sub:2}{it:G}({it:z_t}) + {it:e_t}

{pstd}
where {it:x_t} holds the lags in {opt ar()} and the constant, and {it:G} is a
transition function running from 0 to 1. The regime changes {bf:gradually} with
{it:z}: a sharp threshold is the limiting case as the smoothness parameter grows.

{pstd}
The three transition functions, with γ scaled by the standard deviation of
{it:z} so that it does not depend on the units of {it:z}
(Teräsvirta 1994, p.209):

{p2colset 8 22 24 2}{...}
{p2col:{bf:lstar1}}{it:G} = 1/(1 + exp(−γ({it:z} − {it:c})/σ{sub:z})). Monotone: one regime below {it:c}, another above.{p_end}
{p2col:{bf:estar}}{it:G} = 1 − exp(−γ({it:z} − {it:c})²/σ{sub:z}²). Symmetric: the middle differs from both tails. The usual choice for real exchange rates and for mean reversion that is stronger far from equilibrium.{p_end}
{p2col:{bf:lstar2}}{it:G} = 1/(1 + exp(−γ({it:z} − {it:c}{sub:1})({it:z} − {it:c}{sub:2})/σ{sub:z}²)). Two locations: like ESTAR but the outer regimes may differ from each other.{p_end}
{p2colreset}{...}

{pstd}
Estimation is nonlinear least squares with the linear parameters φ concentrated
out, so only (γ, {it:c}) are searched: a grid first, then Nelder-Mead. The
reported standard errors come from the NLS sandwich over {bf:all} parameters,
including γ and {it:c}, so they already account for having estimated the
transition.

{pstd}
The output also reports the Luukkonen-Saikkonen-Teräsvirta (1988) linearity test
and the Teräsvirta (1994) specification sequence, which is how you decide
{it:whether} a STAR is warranted and {it:which} one.

{marker options}{...}
{title:Options}

{phang}
{opt ar(numlist)} lists the lags. {cmd:ar(1 2 3)} is an AR(3); {cmd:ar(1 12)} a
subset autoregression.

{phang}
{opt delay(#)} sets the self-exciting transition variable to {it:y_{t−#}}.
{opth thvar(varname)} replaces it with any other observed series.

{phang}
{opt ngamma(#)} and {opt nc(#)} control the starting-value grid. The likelihood
is famously flat in γ, so the grid is not a convenience: a bad start gives a bad
answer. Raise them if convergence fails or the answer looks implausible.

{phang}
{opt trim(#)} keeps the candidate locations away from the tails of {it:z}, so
that both regimes contain data.

{marker cycle}{...}
{title:The modelling cycle: do this in order}

{pstd}
Teräsvirta's procedure is a sequence, and the order matters.

{phang2}
{bf:1. Specify the linear model first.} Choose {opt ar()} so the residuals are
not autocorrelated. Omitted dynamics look exactly like regime switching, and
fitting a STAR to an underspecified AR will "find" nonlinearity that is not there.

{phang2}
{bf:2. Test linearity.} The {bf:LM3} test in the output regresses the linear
residuals on {it:x}, {it:x·z}, {it:x·z}², {it:x·z}³. If it does not reject, stop:
there is no evidence for a STAR.

{phang2}
{bf:3. Choose the transition function.} The sequence H04, H03, H02 is reported.
Teräsvirta's rule: if {bf:H03} has the smallest p-value choose {bf:ESTAR},
otherwise choose {bf:LSTAR}. {cmd:thstar} prints which model the sequence points
to and which one you actually fitted, so a mismatch is visible.

{phang2}
{bf:4. Estimate}, and then {bf:5. check the fit} with the three
Eitrheim-Teräsvirta tests: {cmd:estat misspec}. Read the serial-correlation test
first — if it rejects, go back to step 1.

{pstd}
{bf:A caution about degrees of freedom.} When the transition variable is itself
one of the regressors — the self-exciting case {it:z} = {it:y_{t−1}} — the
interaction block is rank deficient. {cmd:thstar} counts the restrictions as the
{bf:rank increase}, not the number of columns, so its p-values differ from a
naive implementation. On the shipped data the correct df is 9, not 12.

{marker gamma}{...}
{title:Remarks: expect γ to be weakly identified}

{pstd}
The smoothness parameter is almost always imprecisely estimated, and a large
standard error on γ is {bf:normal, not a bug}. The reason is structural: once the
transition is reasonably sharp, moving γ from 50 to 500 changes the fitted values
almost not at all, so the data cannot distinguish them. On the shipped
unemployment data γ̂ ≈ 110 with a standard error of several hundred.

{pstd}
What follows from that:

{phang2}
o {bf:Do not report a t test on γ.} It is not informative, and a "non-significant"
γ does not mean there is no transition.

{phang2}
o {bf:Do test linearity properly}, with LM3 — that is the hypothesis you care
about, and it is tested without estimating γ at all.

{phang2}
o {bf:A very large γ̂ means you have a threshold}, not a smooth transition.
Compare with {helpb thtar} or {helpb thregress}: those have a complete inference
theory for that case, and this one does not.

{phang2}
o {bf:The location {it:c} is usually estimated well}, often much better than γ.
It is the economically interesting parameter, and the one to report.

{marker postest}{...}
{title:Postestimation}

{p2colset 6 24 26 2}{...}
{p2col:{cmd:estat misspec}}all three Eitrheim-Teräsvirta tests at once{p_end}
{p2col:{cmd:estat nonlinear}}no remaining nonlinearity (is one transition enough?){p_end}
{p2col:{cmd:estat serial}}no remaining serial correlation ({cmd:lags(#)}){p_end}
{p2col:{cmd:estat constancy}}parameter constancy against a smooth trend{p_end}
{p2col:{cmd:estat linearity}}the Taylor linearity tests in BOTH forms -- the homoskedastic F and the heteroskedasticity-robust LM -- side by side{p_end}
{p2col:{cmd:estat transition}}plot the fitted transition function against {it:z}{p_end}
{p2col:{cmd:estat regimeplot}}observed and fitted against {it:z}{p_end}
{p2col:{cmd:estat skeleton}}the deterministic skeleton: stability, limit cycles, half-lives ({cmd:estat skel} is a synonym){p_end}
{p2col:{cmd:estat archlm}}Engle's ARCH LM test on the squared residuals{p_end}
{p2col:{cmd:estat mcleodli}}McLeod-Li portmanteau on the squared residuals{p_end}
{p2col:{cmd:estat normality}}Jarque-Bera, with skewness and kurtosis components{p_end}
{p2col:{cmd:estat diag}}{cmd:archlm}, {cmd:mcleodli} and {cmd:normality} in one table{p_end}
{p2col:{cmd:predict}}{cmd:xb}, {cmd:residuals}, {cmd:transition} (the fitted {it:G}){p_end}
{p2colreset}{...}

{pstd}
All three tests are F tests of an added block in a regression of the STAR
residuals on the {bf:gradient} of the fitted model, which is the orthogonality the
estimates impose.

{pstd}
{bf:The variance and distribution diagnostics} are separate from the three above.
{cmd:estat diag} collects {cmd:archlm}, {cmd:mcleodli} and {cmd:normality} -- it
does {bf:not} include {cmd:estat serial}, which belongs to the
Eitrheim-Teräsvirta family and is reported by {cmd:estat misspec}. The division
is deliberate: the ET tests ask whether the {it:conditional mean} is adequate,
these ask about the {it:errors} given that mean. {cmd:estat archlm} and
{cmd:estat mcleodli} both look for structure in the squared residuals, the first
as a regression, the second as a portmanteau, and they can disagree -- the
portmanteau has power against patterns spread over many lags that a short ARCH
regression misses. {opt lags(#)} sets the order; the default is 4.

{pstd}
{bf:estat skeleton} sets the errors to zero and iterates the fitted model. It
reports whether the deterministic path converges to a {bf:fixed point} or settles
into a {bf:limit cycle}, and the half-life of a shock measured from each limiting
regime. A smooth-transition model can be globally stable while one of its
limiting regimes is locally explosive, so a modulus at or above 1 for a single
regime is not by itself a sign of a broken fit. The skeleton is {bf:not a
forecast}: Clements and Smith (1997) show the deterministic path differs from
E[{it:y_t+h}] for a nonlinear model and that the gap does not shrink with the
sample. Use {helpb thforecast} for forecasts.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Fit, and read the linearity sequence in the output{p_end}
{phang2}{cmd:. thstar dy, ar(1 2 3) type(lstar1) delay(1)}{p_end}

{pstd}The sequence points to ESTAR on these data, so fit that instead{p_end}
{phang2}{cmd:. thstar dy, ar(1 2 3) type(estar) delay(1)}{p_end}

{pstd}Check the fit before believing it{p_end}
{phang2}{cmd:. estat misspec, lags(4)}{p_end}

{pstd}See the transition: steep means a threshold, flat means weak identification{p_end}
{phang2}{cmd:. estat transition}{p_end}

{pstd}An exogenous transition variable{p_end}
{phang2}{cmd:. thstar dy, ar(1 2) thvar(q)}{p_end}

{pstd}Is a sharp threshold the better description?{p_end}
{phang2}{cmd:. thtar dy, ar(1 2 3) delay(1) test}{p_end}

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(gamma)}, {cmd:e(c)}, {cmd:e(c2)}}transition parameters{p_end}
{synopt:{cmd:e(sd_z)}}standard deviation of {it:z}, the scaling of γ{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(ssr0)}}SSR of the STAR and of the linear model{p_end}
{synopt:{cmd:e(converged)}}1 if the optimiser converged{p_end}
{synopt:{cmd:e(typenum)}}1 lstar1, 2 estar, 3 lstar2{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}equations {cmd:Linear}, {cmd:Transition}, {cmd:Transition_parms}{p_end}
{synopt:{cmd:e(lmtest)}}rows LM3, H04, H03, H02; columns F, df, p{p_end}
{p2colreset}{...}

{pstd}
The {cmd:Linear} block is the regime at {it:G} = 0. The {cmd:Transition} block is
the {bf:change} added as {it:G} goes to 1, so the upper regime is the sum —
{helpb lincom} it.

{marker valid}{...}
{title:Validation}

{pstd}
The linearity and misspecification tests are checked against Stata's own
{helpb regress} and {helpb test} on hand-built auxiliary regressions — an
independent code path — and agree to 1e-9 including the rank-corrected degrees of
freedom. The fit is checked against identities it must satisfy: the smooth fit
never worse than linear, {it:G} inside [0,1], residuals with mean zero summing to
{cmd:e(ssr)}, γ positive and {it:c} inside the range of {it:z}. On the
Durlauf-Johnson data the smooth transition locates the change at 781.7, inside
the [594, 1794] confidence set that {helpb thregress} gives for the jump
threshold — two model classes and two engines agreeing on the break point. See
{bf:tests/reference/thstar/certify_thstar.do}.

{marker robustlm}{...}
{title:Linearity when the variance moves too}

{pstd}
The Taylor linearity test of Luukkonen, Saikkonen and Teräsvirta is an
{it:F} test, and the {it:F} form assumes the errors are homoskedastic under
the null. When they are not, the damage is {bf:specific, not generic}:
neglected conditional heteroskedasticity makes the linearity test
{bf:reject a linear series}.

{pstd}
That matters here more than almost anywhere else, because the series this
command is used on — exchange rates, interest-rate spreads, output growth —
are exactly the series that have volatility clustering. A rejection by the
{it:F} form alone can be a GARCH effect wearing a transition's clothes, and
fitting a smooth transition to it would be {bf:modelling the variance with
the mean}.

{pstd}
So {cmd:thstar} computes the same four hypotheses a second time in the
heteroskedasticity-robust LM form of van Dijk, Teräsvirta and Franses
(2002), and stores them in {cmd:e(lmtest_robust)}. It is Wooldridge's
construction: project the restricted regressors out of the auxiliary block,
multiply by the restricted residuals, regress a vector of ones on the
result, and take {it:n} minus the residual sum of squares. No assumption
about the error variance enters anywhere.

{pstd}
{cmd:estat linearity} prints the two side by side, which is the point. Read
them together:

{p 8 12 2}
{bf:Both reject} — the nonlinearity is in the mean and does not rest on the
homoskedasticity assumption. Proceed.

{p 8 12 2}
{bf:Only the F form rejects} — this is what neglected heteroskedasticity
looks like. Run {cmd:estat archlm}; if there is ARCH, model it before
fitting a transition. The command says so when it sees this pattern.

{p 8 12 2}
{bf:Only the robust form rejects} — the {it:F} form is the less reliable of
the two, since it is the one carrying an assumption. Treat the robust
result as the finding.

{pstd}
Both forms take their degrees of freedom from the {bf:rank increase} of the
auxiliary block, not from its column count. In the self-exciting case the
transition variable {it:is} one of the regressors, so the interaction block
is rank deficient; counting columns would inflate the degrees of freedom
and make the test conservative in a way that reads as evidence of
linearity. The two forms therefore always report the same degrees of
freedom, and {cmd:estat linearity} says so if they ever do not.


{marker ugirf}{...}
{title:estat girf: the response to a shock, when there is no single response}

{pstd}
In a linear model the response to a shock is a property of the model alone:
invert the lag polynomial and you are done. In a threshold model it is not.
The response depends on

{p 8 12 2}
the {bf:history} the shock arrives into, because that decides which regime
the system is in and how close it is to switching;

{p 8 12 2}
the {bf:sign} of the shock, because a shock that pushes the system across
the threshold does something a shock of the same size the other way does
not;

{p 8 12 2}
the {bf:size} of the shock, for the same reason — {bf:responses do not
scale}. The answer to a two-sigma shock is not twice the answer to a
one-sigma shock.

{pstd}
So {cmd:estat girf} computes the generalised impulse response of Koop,
Pesaran and Potter (1996),

{p 8 8 2}
GIRF({it:h}, {it:delta}, {it:omega}) = E[{it:y_t+h} | {it:e_t} = {it:delta}, {it:omega}] {c -} E[{it:y_t+h} | {it:omega}]

{pstd}
by simulation. Both expectations are simulated and the two paths share the
{bf:same future shocks}, so their difference isolates the effect of
{it:delta} rather than Monte Carlo noise.

{pstd}
Four responses are printed together, and {bf:the comparison is the point}:
to +{it:delta}, to {c -}{it:delta}, and conditional on the shock arriving
in each regime. In a linear model the first two would be exact mirror
images and the last two identical. {bf:Where they are not, that difference
is the nonlinearity} — and it is the only part of the table a linear model
could not have produced. A GIRF whose four columns agree is telling you the
threshold is not doing any work.

{pstd}
Two requirements, both refused with a reason rather than worked around. The
model must be {bf:self-exciting}: the transition variable has to be a lag of
the dependent variable, so the simulation can compute it forward. With an
exogenous threshold variable the future path is unknown, and freezing it
would answer a different question. And the delay must be one of the
autoregressive lags, or the transition variable is not part of the state the
model propagates.

{synoptset 20 tabbed}{...}
{synopthdr:girf option}
{synoptline}
{synopt:{opt size(#)}}shock size in the units of {it:y}; default 1. The
residual standard deviation is printed beside it for scale{p_end}
{synopt:{opt h:orizon(#)}}horizons; default 12{p_end}
{synopt:{opt reps(#)}}simulated paths per history; default 200{p_end}
{synopt:{opt hist:ories(#)}}histories averaged over; default 150, taken
evenly spaced through the sample so the answer does not move with the
seed for a reason unrelated to the model{p_end}
{synopt:{opt boot(string)}}{opt resample} (default) draws shocks from the
residuals; {opt normal} draws them from a fitted normal. Resampling is the
default because a threshold model's residuals are routinely skewed, and the
response to a large shock is exactly where that matters{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt gr:aph}}plot all four responses{p_end}
{synopt:{opt sav:ing()}}save that graph{p_end}
{synoptline}


{marker refs}{...}
{title:References}

{phang}
Koop, G., M. H. Pesaran, and S. M. Potter. 1996. Impulse response analysis
in nonlinear multivariate models.
{it:Journal of Econometrics} 74: 119-147.
{browse "https://doi.org/10.1016/0304-4076(95)01753-4":doi:10.1016/0304-4076(95)01753-4}

{phang}
van Dijk, D., T. Teräsvirta, and P. H. Franses. 2002. Smooth transition
autoregressive models — a survey of recent developments.
{it:Econometric Reviews} 21: 1-47.
{browse "https://doi.org/10.1081/ETC-120008723":doi:10.1081/ETC-120008723}

{phang}
Clements, M. P., and J. Smith. 1997. The performance of alternative
forecasting methods for SETAR models. {it:International Journal of
Forecasting} 13: 463-475.
{browse "https://doi.org/10.1016/S0169-2070(97)00017-4":doi:10.1016/S0169-2070(97)00017-4}.

{phang}
Eitrheim, Ø., and T. Teräsvirta. 1996. Testing the adequacy of smooth transition
autoregressive models. {it:Journal of Econometrics} 74: 59-75.
{browse "https://doi.org/10.1016/0304-4076(95)01751-8":doi:10.1016/0304-4076(95)01751-8}.

{phang}
Granger, C. W. J., and T. Teräsvirta. 1993. {it:Modelling Nonlinear Economic
Relationships}. Oxford University Press.

{phang}
Luukkonen, R., P. Saikkonen, and T. Teräsvirta. 1988. Testing linearity against
smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.2307/2336599":doi:10.2307/2336599}.

{phang}
Teräsvirta, T. 1994. Specification, estimation and evaluation of smooth
transition autoregressive models. {it:JASA} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
van Dijk, D., T. Teräsvirta, and P. H. Franses. 2002. Smooth transition
autoregressive models — a survey of recent developments. {it:Econometric Reviews}
21: 1-47.
{browse "https://doi.org/10.1081/ETC-120008723":doi:10.1081/ETC-120008723}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thstarcycle} (the
specification cycle for this model), {helpb thstrtype} (logistic or
exponential?), {helpb thstr}, {helpb thtar}, {helpb thregress}, {helpb thtest},
{helpb thsim}, {helpb thexport}
{p_end}
