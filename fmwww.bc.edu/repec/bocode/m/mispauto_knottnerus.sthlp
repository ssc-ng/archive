{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto" "help mispauto"}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "mispauto thursby" "help mispauto_thursby"}{...}
{vieweralsosee "mispauto godfrey" "help mispauto_godfrey"}{...}
{viewerjumpto "Syntax" "mispauto_knottnerus##syntax"}{...}
{viewerjumpto "Description" "mispauto_knottnerus##desc"}{...}
{viewerjumpto "The three blind spots" "mispauto_knottnerus##blind"}{...}
{viewerjumpto "Options" "mispauto_knottnerus##options"}{...}
{viewerjumpto "Interpreting the output" "mispauto_knottnerus##interp"}{...}
{viewerjumpto "Examples" "mispauto_knottnerus##examples"}{...}
{viewerjumpto "Stored results" "mispauto_knottnerus##results"}{...}

{title:Title}

{phang}
{bf:mispauto knottnerus} {hline 2} Knottnerus's (1985) diagnostics: when the
other strategies go blind


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto knottnerus} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lag:s(#)}}autocorrelations to compute; default is twice the
detected period, minimum 4{p_end}
{synopt :{opt lev:el(#)}}level for the seasonal test, percent; default
{cmd:level(5)}{p_end}
{synopt :{opt g:raph}}correlogram with seasonal lags highlighted{p_end}
{synopt :{opt n:ame(string)}}name for the graph{p_end}
{synopt :{opt notable}}suppress display; warnings are still counted in
{cmd:r(n_warnings)}{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{pstd}
This subcommand is not a test strategy. It computes the quantities Knottnerus
(1985) used to prove that Thursby's procedure fails in identifiable cases, and
reports whether your series falls into any of them. It costs almost nothing to
run and it is the difference between a diagnosis you can defend and one you
cannot.

{pstd}
{bf:Run it on every equation before reporting a}
{helpb mispauto_thursby:thursby}{bf: or}
{helpb mispauto_godfrey:godfrey}{bf: diagnosis.} {cmd:mispauto all} does so
automatically and counts the warnings in its comparison table.


{marker blind}{...}
{title:The three blind spots}

{pstd}
{bf:1. The first-order autocorrelation is zero.} Knottnerus's section II and
footnote 1. If the disturbances follow any process with
{cmd:E(e(t) e(t-1)) = 0}, then the Durbin{c 150}Watson statistic converges to 2
and Durbin's S-test is insignificant, so {bf:Thursby's strategy returns NP no
matter how strongly the errors are autocorrelated}. He names pure seasonal
autocorrelation as the leading case, which "may occur especially in monthly and
quarterly data". The simplest example is {cmd:e(t) = rho e(t-4) + v(t)}: every
odd autocorrelation is zero and the strategy sees nothing.

{pstd}
{bf:2. The second-order autocorrelation equals the square of the first.}
Knottnerus's section IV, from his equation (15). If {cmd:g2 = g1^2} with
{cmd:g1} non-zero, Durbin's S-test is insignificant while
Durbin{c 150}Watson is significant, so {bf:genuinely non-AR(1) errors are
reported as AR(1)}. The condition holds exactly for a true AR(1), which is why
it is diagnostic: the closer your residuals come to it, the less the strategy
can tell AR(1) from something else.

{pstd}
{bf:3. The nonlinear restrictions carry no information.} Knottnerus's equation
(12) proves that {cmd:plim(b3*b1 + b2) = 0} for {it:any} stationary error
process. The restrictions the likelihood-ratio stage of Thursby's LRS procedure
tests are therefore satisfied whatever the errors do, and that stage has
asymptotic power equal to its nominal size. Thursby's (1985) reply accepts the
result. When the reported z-ratio is small, as it usually is, the LR stage is
uninformative on your data and {opt slrs} is the better specification.

{pstd}
Knottnerus also shows, through his equation (8)
{cmd:R = -rho1*rho2/(1-rho2)}, that the power of the strategy against AR(2)
errors is {it:non-monotonic} in the second-order parameter, so Thursby's
conclusion that detection improves as the second-order parameter grows relative
to the first is a feature of his coarse grid of three parameter pairs rather
than a general property. The command reports {cmd:R} and the implied
autocorrelations so this can be checked directly.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets how many residual autocorrelations are computed and shown in
the graph. The default is twice the period detected from {helpb tsset}, with a
floor of 4, capped so that enough residual degrees of freedom remain.

{phang}
{opt level(#)} is the level at which the seasonal F test is judged when the
warning is issued. It does not affect anything else: the other three warnings
use a two-standard-error band.

{phang}
{opt graph} draws the correlogram with Bartlett bands at
{cmd:+/- 1.96/sqrt(T)} and the seasonal lags drawn in a contrasting colour, so
blind spot 1 is visible at a glance: a flat correlogram with one tall bar at the
seasonal lag.


{marker interp}{...}
{title:Interpreting the output}

{pstd}
The table has three blocks.

{pstd}
{bf:The first block} reports the residual autocorrelations and the two
quantities from equation (15). The yardstick printed beneath,
{cmd:1/sqrt(T)}, is the Bartlett standard error; the warnings use twice it. Read
{cmd:gamma(1)} first: if it is inside the band, blind spot 1 applies and
nothing Thursby's procedure says about autocorrelation can be trusted.

{pstd}
{bf:The second block} fits an AR(2) to the residuals and reports Knottnerus's
{cmd:R}, together with the autocorrelations the fitted AR(2) implies. Comparing
these with the directly estimated {cmd:gamma(1)} and {cmd:gamma(2)} in the first
block is a quick check on whether an AR(2) describes the residuals at all: large
discrepancies point to a moving-average or seasonal component.

{pstd}
{bf:The third block} is equation (12). {cmd:b3*b1 + b2} has a probability limit
of zero under any stationary error process, so a z-ratio inside
{cmd:+/- 1.96} is the expected result, not a finding. It is reported because
Thursby's LR stage tests exactly this quantity, and seeing it near zero is what
justifies ignoring that stage.

{pstd}
{bf:The warnings block} then states, in words, which strategies are unreliable
on this series and what to do instead. If no warning is raised the block says
so explicitly rather than printing nothing.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mispauto knottnerus y x1 x2}{p_end}
{phang2}{cmd:. mispauto knottnerus y x1 x2, graph}{p_end}

{pstd}Monthly data: look out to two years{p_end}
{phang2}{cmd:. tsset mdate, monthly}{p_end}
{phang2}{cmd:. mispauto knottnerus y x1 x2, lags(24) graph}{p_end}

{pstd}The decision this subcommand exists to support{p_end}
{phang2}{cmd:. mispauto knottnerus y x1 x2, notable}{p_end}
{phang2}{cmd:. if r(n_warnings) > 0 display "Thursby's strategy is unsafe here"}{p_end}

{pstd}Recover the correlogram as a matrix{p_end}
{phang2}{cmd:. mispauto knottnerus y x1 x2, notable}{p_end}
{phang2}{cmd:. matrix list r(ac)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}, {cmd:r(k)}, {cmd:r(lags)} sample and lag count{p_end}
{synopt:{cmd:r(periodicity)}}period detected from {helpb tsset}{p_end}
{synopt:{cmd:r(gamma1)}}, {cmd:r(gamma2)} residual autocorrelations{p_end}
{synopt:{cmd:r(g2_g1sq)}}{cmd:gamma2 - gamma1^2}, from eq.(15){p_end}
{synopt:{cmd:r(blind)}}{cmd:gamma1*(gamma2 - gamma1^2)}, eq.(15){p_end}
{synopt:{cmd:r(se_gamma)}}{cmd:1/sqrt(T)}, the Bartlett yardstick{p_end}
{synopt:{cmd:r(rho1)}}, {cmd:r(rho2)} AR(2) fit of the residuals{p_end}
{synopt:{cmd:r(R)}}Knottnerus's {cmd:R}, eq.(8){p_end}
{synopt:{cmd:r(gamma1_implied)}}, {cmd:r(gamma2_implied)} from his footnote 2{p_end}
{synopt:{cmd:r(nlr)}}, {cmd:r(nlr_se)}, {cmd:r(nlr_z)} {cmd:b3*b1+b2} and its
z-ratio, eq.(12){p_end}
{synopt:{cmd:r(F_seas)}}, {cmd:r(df_seas)}, {cmd:r(p_seas)} seasonal test{p_end}
{synopt:{cmd:r(n_warnings)}}number of blind spots detected{p_end}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:r(ac)}}lag, autocorrelation, Bartlett standard error, z{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
