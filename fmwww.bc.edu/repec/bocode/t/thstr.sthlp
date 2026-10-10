{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "thstar (the time-series sibling)" "help thstar"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thstr##syntax"}{...}
{viewerjumpto "Description" "thstr##description"}{...}
{viewerjumpto "Options" "thstr##options"}{...}
{viewerjumpto "Smooth or sharp?" "thstr##which"}{...}
{viewerjumpto "Examples" "thstr##examples"}{...}
{viewerjumpto "Stored results" "thstr##results"}{...}
{viewerjumpto "References" "thstr##refs"}{...}
{title:Title}

{phang}
{bf:thstr} {hline 2} Cross-sectional smooth transition regression

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thstr} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth thvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth thv:ar(varname)}}transition variable{p_end}
{synopt:{opt ty:pe(string)}}{opt lstar1} (default), {opt estar}, {opt lstar2}{p_end}
{synopt:{opt trim(#)}}trimming for the location grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt ngamma(#)}}grid points for the smoothness; default 20{p_end}
{synopt:{opt nc(#)}}grid points for the location; default 40{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt vce(robust)}}heteroskedasticity-robust standard errors{p_end}
{synopt:{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}* {opt thvar()} is required. No {helpb tsset} is needed.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thstr} fits

{p 12 12 2}
{it:y_i} = {it:x_i}'φ{sub:1}(1 − {it:G}({it:z_i})) + {it:x_i}'φ{sub:2}{it:G}({it:z_i}) + {it:e_i}

{pstd}
where the coefficients change {bf:gradually} with the transition variable
{it:z} instead of jumping at a threshold. It is the cross-sectional sibling of
{helpb thstar}: the same engine, the same transition functions, the same
linearity tests, without the autoregressive structure and without needing a time
index.

{pstd}
Nothing in official Stata fits this. The usual workaround is a hand-written
{helpb nl} function, which has no starting-value search, no linearity test, and
no standard errors for the transition parameters.

{pstd}
For the transition functions, the estimation method, the modelling cycle and the
warning about γ being weakly identified, see {helpb thstar} — all of it applies
here unchanged. Only the data structure differs.

{marker options}{...}
{title:Options}

{phang}
{opth thvar(varname)} is the variable along which the coefficients change. It
should be continuously distributed.

{phang}
{opt type()}, {opt trim()}, {opt ngamma()}, {opt nc()}, {opt vce()} behave exactly
as in {helpb thstar}.

{marker which}{...}
{title:Smooth or sharp? Let the data and the theory both speak}

{pstd}
{cmd:thstr} and {helpb thregress} describe the same phenomenon differently: one
says the coefficients slide, the other that they jump. Three things help decide.

{phang2}
{bf:1. The economics.} A policy cut-off, an eligibility rule or a tax bracket
jumps. Aggregation over heterogeneous units, gradual learning or adjustment costs
slide. If individual units switch sharply at different points, the aggregate is
smooth even though no unit is.

{phang2}
{bf:2. The estimated smoothness.} A very large γ̂ {it:is} a threshold, and
{helpb thregress} has the better inference theory for that case. A moderate γ̂
with a tight location is genuine smoothness.

{phang2}
{bf:3. The fit.} The two models are not nested, but their SSRs are comparable.
On the shipped growth data they are nearly identical (8.046 smooth, 8.025 jump)
and the smooth location, 781.7, sits inside the jump model's confidence set
[594, 1794]. When that happens, say so: the break point is robust to the model
class, which is a stronger result than either model alone.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use threshkit_dj}{p_end}

{pstd}Does the growth relation change gradually with 1960 income?{p_end}
{phang2}{cmd:. thstr diff gdp60 iony pgro sch, thvar(q) vce(robust)}{p_end}

{pstd}Exponential transition: the middle differs from both tails{p_end}
{phang2}{cmd:. thstr diff gdp60 iony pgro sch, thvar(q) type(estar)}{p_end}

{pstd}Look at the fitted transition and the implied regimes{p_end}
{phang2}{cmd:. estat transition}{p_end}
{phang2}{cmd:. estat regimeplot}{p_end}

{pstd}Check the specification{p_end}
{phang2}{cmd:. estat misspec}{p_end}

{pstd}Compare with the sharp-threshold description of the same data{p_end}
{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q) test}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thstr} is {it:eclass} and stores the same results as {helpb thstar}, with
{cmd:e(cmd)} equal to {cmd:thstr} and {cmd:e(indepvars)} in place of
{cmd:e(arlags)}. The same {cmd:estat} suite and {cmd:predict} apply.


{marker endog}{...}
{title:What is not provided: endogenous regressors}

{pstd}
{cmd:thstr} fits by {bf:concentrated nonlinear least squares}, which assumes the
regressors are {bf:exogenous}. If a regressor is endogenous, or the transition
variable is, the estimates here are not consistent and nothing in the output
will say so -- the fit will look entirely ordinary.

{pstd}
There is no smooth-transition counterpart in this package.
{help thstr##refs:Areosa, McAleer, and Medeiros (2011)} give a moment-based
(GMM) estimator for exactly this case, and it is not implemented here. What the
package does offer is the {bf:sharp}-threshold analogues: {helpb thivreg} for
endogenous {it:regressors} with an exogenous threshold, and {helpb thendog} for
an endogenous {it:threshold variable} -- though read that command's warning
about the consistency of its threshold estimate before relying on it. If
endogeneity is the problem and a sharp split is defensible, those are the
honest route; if the transition really is smooth, this is a known gap rather
than something to work around.

{marker refs}{...}
{title:References}

{phang}
Granger, C. W. J., and T. Teräsvirta. 1993. {it:Modelling Nonlinear Economic
Relationships}. Oxford University Press.

{phang}
Luukkonen, R., P. Saikkonen, and T. Teräsvirta. 1988. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.2307/2336599":doi:10.2307/2336599}.

{phang}
Teräsvirta, T. 1994. {it:JASA} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
Areosa, W. D., M. McAleer, and M. C. Medeiros. 2011. Moment-based estimation of
smooth transition regression models with endogenous variables. {it:Journal of
Econometrics} 165: 100-111.
{browse "https://doi.org/10.1016/j.jeconom.2011.05.009":doi:10.1016/j.jeconom.2011.05.009}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb thstar}, {helpb threshkit_choose:threshkit choose}, {helpb thregress},
{helpb thkink}
{p_end}
