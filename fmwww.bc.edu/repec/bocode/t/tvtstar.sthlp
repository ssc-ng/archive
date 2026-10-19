{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtstar##syntax"}{...}
{viewerjumpto "Description" "tvtstar##description"}{...}
{viewerjumpto "What makes it a C-STAR" "tvtstar##cstar"}{...}
{viewerjumpto "Options" "tvtstar##options"}{...}
{viewerjumpto "The two tests" "tvtstar##tests"}{...}
{viewerjumpto "Things to check in the output" "tvtstar##checks"}{...}
{viewerjumpto "Examples" "tvtstar##examples"}{...}
{viewerjumpto "Stored results" "tvtstar##results"}{...}
{viewerjumpto "Validation" "tvtstar##validation"}{...}
{viewerjumpto "References" "tvtstar##references"}{...}
{viewerjumpto "Author" "tvtstar##author"}{...}
{title:Title}

{phang}
{bf:tvtstar} {hline 2} Smooth transition with a state-dependent threshold
(SDC-STAR)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtstar} {depvar} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lags(#)}}autoregressive order in each regime; default
{cmd:lags(1)}{p_end}
{synopt :{opth x:vars(varlist)}}the state variables the threshold depends
on, entered {bf:lagged one period}. Omit for a constant threshold{p_end}
{synopt :{opth exog(varlist)}}extra regressors in BOTH regimes, which
makes it the SDC-STARX{p_end}
{synopt :{opt gauss:ian}}Gaussian errors instead of the Student-t{p_end}
{synopt :{opt start:s(#)}}starting values tried, 1 to 6; default
{cmd:starts(6)}{p_end}
{synopt :{opt max:iter(#)}}iterations per start; default
{cmd:maxiter(300)}{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtstar} fits the state-dependent contemporaneous-threshold STAR of
{browse "https://doi.org/10.1111/j.1468-0084.2012.00719.x":Dueker, Psaradakis, Sola and Spagnolo}:
two latent autoregressions,

{p 8 8 2}
{it:y_it} = {it:mu_i} + {it:phi_i'y_{t-1}} + {it:sigma_i u_it},
{space 4}{it:i} = 1, 2

{pstd}
mixed by a weight that is itself a probability the model implies, with a
threshold that moves with observed state variables,

{p 8 8 2}
{it:threshold_{t-1}} = {it:gamma} + {it:beta'x_{t-1}}.

{pstd}
The motivation is the one that runs through this library: an interest rate
may be high or low "not in absolute terms but relative to" inflation and
output growth. What is different here is that the transition is
{bf:smooth} rather than a sharp split {hline 2} the data are not assigned
to a regime, they are weighted between two.

{pstd}
Estimation is by conditional maximum likelihood. {bf:The errors are
standardised Student-t by default, not Gaussian}, which is the paper's own
choice and gives the model room for outliers; the degrees of freedom are
estimated. {opt gaussian} imposes the Gaussian case.


{marker cstar}{...}
{title:What makes it a C-STAR, and why that costs time}

{pstd}
In the standard logistic smooth-transition model of Terasvirta (1994)
the transition function is bolted on: its slope and location are free
parameters with no connection to the regime equations.
Here the weight on regime 1 {bf:is} a probability the model implies,

{p 8 8 2}
{it:G} = P({it:y_1t} < threshold) / [ P({it:y_1t} < threshold) +
P({it:y_2t} >= threshold) ]

{pstd}
so it depends on {bf:every parameter}: both intercepts, both lag vectors,
both scales, the threshold and its state coefficients. Nothing about the
transition is free.

{pstd}
Two consequences follow, and both are practical:

{phang2}
{bf:the likelihood cannot be concentrated.} There is no profiling step and
no grid; everything is estimated jointly, which makes this the slowest
estimator in the library.

{phang2}
{bf:the likelihood is multi-modal}, so the command maximises from several
starting values and keeps the best, as the paper does. {cmd:e(n_conv)}
reports how many converged cleanly. If that is 1 of 6, treat the answer as
provisional and raise {opt starts()}.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} is the AR order {bf:in each regime}. Every lag is estimated
twice and also enters the transition function, so the parameter count grows
quickly; the command refuses more than 12.

{phang}
{opth xvars(varlist)} gives the state variables. They enter {bf:lagged one
period}, which is eq (5). {bf:Omit it and the threshold is constant}, which
is an ordinary C-STAR and is also the null of the main test.

{phang}
{opth exog(varlist)} puts extra regressors in both regime equations. The
paper calls the result SDC-STARX and notes it "nests all other C-STAR and
SDC-STAR specifications as special cases".

{phang}
{opt gaussian} replaces the standardised Student-t with the normal. It is a
{bf:restriction}, so it cannot fit better, and the output labels it.

{phang}
{opt starts(#)} and {opt maxiter(#)} control the optimisation; see above.


{marker tests}{...}
{title:The two tests}

{pstd}
{bf:Is the threshold state dependent?} {it:H0}: {it:beta} = 0. This is the
paper's headline question and {bf:it is a regular test}: under the null the
threshold intercept is still identified and every other parameter still
means what it meant, so there is no Davies problem and the likelihood ratio
has its ordinary chi-squared({it:k}) distribution. That is unusual in this
library and it is why this test gets a p-value.

{pstd}
{bf:Is the series nonlinear at all?} AR({it:p}) against SDC-STAR({it:p}).
{bf:This one is NOT regular and gets no p-value.} Under linearity the
transition parameters are unidentified, so the statistic does not have a
chi-squared distribution however much the models nest. The paper handles it
with Hansen's (1992) method, which is {bf:not implemented here}; the
statistic is printed as a descriptive number and the output says so.

{pstd}
{bf:Read them in that order is not right here.} Unlike the F1/F2 pairs
elsewhere in this library, the regular test is the second question, not the
first. If you need a defensible linearity test, use
{helpb tvthomog} or {helpb tvtfourier}, which supply one.


{marker checks}{...}
{title:Things to check in the output}

{phang}
{bf:Does G actually move?} The header prints its minimum, mean and maximum.
If the range is tiny the transition is close to degenerate, the two regimes
are nearly indistinguishable, and the split is not identified by the data.
The command warns when the range is below 0.05.

{phang}
{bf:Did a regime's degrees of freedom land on the floor?} The Student-t is
floored at 2.05 (the paper requires only {it:nu} > 2, but at {it:nu} = 2 the
standardisation degenerates). A component sitting on the floor is swallowing
a few outliers rather than fitting anyone's tails, and the split should not
be read as two economic regimes. The command says so, and the remedy is to
compare against {opt gaussian}.

{phang}
{bf:Were standard errors available?} They come from a numerical Hessian at
the optimum. If that is not negative definite the command reports {bf:no}
standard errors rather than inventing them, and says why.

{phang}
{bf:How many starts converged?} See {cmd:e(n_conv)}.


{marker examples}{...}
{title:Examples}

{pstd}An interest rate whose threshold moves with inflation and output
growth{p_end}
{phang2}{cmd:. tvtstar rate, lags(2) xvars(inflation outputgrowth)}{p_end}

{pstd}Is the threshold state dependent at all? The test is in the
output{p_end}
{phang2}{cmd:. display e(lr_const) "  p = " e(p_lr_const)}{p_end}

{pstd}The constant-threshold C-STAR, for comparison{p_end}
{phang2}{cmd:. tvtstar rate, lags(2)}{p_end}

{pstd}Gaussian errors, when the t collapses to its floor{p_end}
{phang2}{cmd:. tvtstar rate, lags(2) xvars(inflation) gaussian}{p_end}

{pstd}The STARX version, with exogenous regressors in both regimes{p_end}
{phang2}{cmd:. tvtstar rate, lags(1) xvars(inflation) exog(spread)}{p_end}

{pstd}Plot the fitted threshold against the series{p_end}
{phang2}{cmd:. tvtstar rate, lags(2) xvars(inflation)}{p_end}
{phang2}{cmd:. tvtplot}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tvtstar} is {cmd:e}-class. It stores

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}usable observations, after the lags{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}of the constant-threshold model{p_end}
{synopt:{cmd:e(ll_lin)}}of the linear AR{p_end}
{synopt:{cmd:e(lr_const)}, {cmd:e(p_lr_const)}}the regular test{p_end}
{synopt:{cmd:e(lr_lin)}}the linearity statistic, with no p-value{p_end}
{synopt:{cmd:e(gamma0)}}threshold intercept{p_end}
{synopt:{cmd:e(sigma1)}, {cmd:e(sigma2)}}regime scales{p_end}
{synopt:{cmd:e(df1)}, {cmd:e(df2)}}estimated degrees of freedom{p_end}
{synopt:{cmd:e(df_floor)}}1 if a regime sits on the floor{p_end}
{synopt:{cmd:e(G_min)}, {cmd:e(G_mean)}, {cmd:e(G_max)}}the weight's
range{p_end}
{synopt:{cmd:e(n_conv)}, {cmd:e(n_start)}}starts that converged, and
tried{p_end}
{synopt:{cmd:e(novce)}}1 if no standard errors were available{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtstar}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(statevars)}}the threshold's state variables{p_end}
{synopt:{cmd:e(exogvars)}}extra regressors in both regimes{p_end}
{synopt:{cmd:e(errdist)}}the error distribution used{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}in three equations, {cmd:regime1},
{cmd:regime2} and {cmd:threshold}{p_end}
{synopt:{cmd:e(path)}}the fitted threshold, observation by
observation{p_end}
{synopt:{cmd:e(weight)}}the fitted weight on regime 1{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
No code ships with this paper, and its Table 1 reports {it:biases} and
{it:ratios} of sampling SD to estimated SE rather than levels, so there is
no number to lock against. What is checked exactly is the two building
blocks, and then recovery by simulation:

{phang2}
{bf:the standardised Student-t} is a density with variance one at {it:nu} =
3, 12, 21 and 30 and in the Gaussian limit, with F(0) = 1/2;

{phang2}
{bf:the mixing function} lies in [0,1], increases with the threshold, and
collapses to {it:F1} exactly when the two regimes are identical;

{phang2}
{bf:recovery} of a known SDC-STAR(1) at T = 700, simulating from the
model's own mixture: intercepts −1.01 and 1.47 (true −1 and 1.5), AR terms
0.500 and 0.261 (0.5 and 0.3), threshold 0.375 + 1.158{it:x} (true 0.5 +
1.2{it:x});

{phang2}
{bf:the likelihood ordering} SDC-STAR >= constant threshold >= linear AR,
which is nesting and so cannot fail unless the optimiser did;

{phang2}
{bf:the regular test discriminates} and is not oversized on null data.

{pstd}
The suite is {cmd:tests/reference/tvtstar/certify_tvtstar.do} and the
equation map is {cmd:validation/tvthresh/tvtstar_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Dueker, M. J., M. Sola, and F. Spagnolo. 2007. Contemporaneous threshold
autoregressive models: estimation, testing and forecasting.
{it:Journal of Econometrics} 141: 517-547.

{phang}
Dueker, M. J., Z. Psaradakis, M. Sola, and F. Spagnolo. 2013.
State-dependent threshold smooth transition autoregressive models.
{it:Oxford Bulletin of Economics and Statistics} 75(5): 736-759.
{browse "https://doi.org/10.1111/j.1468-0084.2012.00719.x":doi:10.1111/j.1468-0084.2012.00719.x}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
