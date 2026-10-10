{smcl}
{* *! version 1.0.0  02oct2026}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{viewerjumpto "Syntax" "thmtar##syntax"}{...}
{viewerjumpto "Description" "thmtar##description"}{...}
{viewerjumpto "Options" "thmtar##options"}{...}
{viewerjumpto "TAR or M-TAR?" "thmtar##which"}{...}
{viewerjumpto "Remarks: the two nulls" "thmtar##nulls"}{...}
{viewerjumpto "Postestimation" "thmtar##postest"}{...}
{viewerjumpto "Examples" "thmtar##examples"}{...}
{viewerjumpto "Stored results" "thmtar##results"}{...}
{viewerjumpto "References" "thmtar##refs"}{...}
{title:Title}

{phang}
{bf:thmtar} {hline 2} Asymmetric unit-root and threshold-cointegration tests:
TAR and momentum-TAR adjustment

{marker syntax}{...}
{title:Syntax}

{pstd}Asymmetric unit root in one series{p_end}
{p 8 15 2}
{cmd:thmtar} {it:varname} {ifin} [{cmd:,} {it:options}]

{pstd}Threshold cointegration among several{p_end}
{p 8 15 2}
{cmd:thmtar} {it:depvar} {it:varlist} {ifin}{cmd:,} {opt coint} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(tar|mtar)}}which variable the indicator is built on; default {cmd:tar}{p_end}
{synopt:{opt lags(#)}}lagged differences to include; default 0{p_end}
{synopt:{opt thres:hold(#)}}fixed threshold; default 0{p_end}
{synopt:{opt cons:istent}}estimate the threshold by grid search (Chan 1993){p_end}
{synopt:{opt trim(#)}}trimming for the grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt coint}}two-step: Engle-Granger residual first{p_end}
{synopt:{opt band}}band model: three regimes, no adjustment inside the band{p_end}
{synopt:{opt bandt:ype(btar|eqtar)}}adjust to the band edge or to equilibrium; default {cmd:btar}{p_end}
{synopt:{opt bandl:imits(# #)}}fixed band bounds{p_end}
{synopt:{opt asym:metric}}search the two bounds separately (2-D grid){p_end}
{synopt:{opt gridn(#)}}grid points per side for the band search{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt vce(robust)}}heteroskedasticity-robust standard errors{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 1000{p_end}
{synopt:{opt boot(resample|wild)}}bootstrap errors; default {cmd:resample}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thmtar} fits the asymmetric adjustment model

{p 12 12 2}
Δ{it:z_t} = {it:I_t}·ρ{sub:1}{it:z_{t-1}} + (1−{it:I_t})·ρ{sub:2}{it:z_{t-1}}
+ Σ β{sub:i}Δ{it:z_{t-i}} + {it:e_t}

{pstd}
where {it:z} is either the series itself or, with {opt coint}, the residual from
a first-stage Engle-Granger regression, and the indicator is

{p2colset 8 26 28 2}{...}
{p2col:{bf:TAR}}{it:I_t} = 1{c -(}{it:z_{t-1}} ≥ τ{c )-} — asymmetry in the {it:level} of the gap{p_end}
{p2col:{bf:M-TAR}}{it:I_t} = 1{c -(}Δ{it:z_{t-1}} ≥ τ{c )-} — asymmetry in the {it:direction of movement}{p_end}
{p2colreset}{...}

{pstd}
and reports two tests: Φ for H0: ρ{sub:1} = ρ{sub:2} = 0 (no cointegration, or a
unit root with no adjustment in either direction), and an F test of
H0: ρ{sub:1} = ρ{sub:2} (symmetric adjustment).

{pstd}
Nothing in official Stata or on SSC does this for a single series or for
residual-based threshold cointegration.

{marker options}{...}
{title:Options}

{phang}
{opt model(tar|mtar)} chooses the indicator variable. See the next section.

{phang}
{opt lags(#)} adds lagged differences to absorb serial correlation, exactly as in
an augmented Dickey-Fuller regression. Residual autocorrelation invalidates the
test, so check it.

{phang}
{opt threshold(#)} fixes τ. Zero is the usual choice when {it:z} is a
cointegrating residual, because the long-run equilibrium is then zero by
construction. It is {bf:not} a neutral choice for a raw series.

{phang}
{opt consistent} estimates τ by searching the trimmed distinct values of the
indicator variable for the smallest SSR — Chan's (1993) consistent estimator. Use
it whenever the equilibrium level is not known a priori. Note that the published
Enders-Siklos critical values assume a {bf:known} threshold; this is one reason
{cmd:thmtar} simulates the p-value instead.

{phang}
{opt coint} runs the first-stage Engle-Granger regression of {it:depvar} on
{it:varlist} and applies everything above to its residual. This is the
Enders-Siklos (2001) threshold-cointegration test, and the Balke-Fomby (1997)
two-step setup.

{phang}
{opt boot(resample|wild)} selects the bootstrap errors: an iid resample of the
null residuals, or the same resample multiplied by N(0,1) draws, which is more
robust to heteroskedasticity.

{marker which}{...}
{title:TAR or M-TAR? Choose on the economics}

{pstd}
The two models answer different questions and {bf:they are not nested}.

{p2colset 6 20 22 2}{...}
{p2col:{bf:TAR}}Adjustment depends on {it:where} the gap is — positive gaps close at a different speed from negative ones. Natural when the deviation itself has an economic meaning: a markup, a spread, a real exchange rate above or below parity.{p_end}
{p2col:{bf:M-TAR}}Adjustment depends on {it:which way the gap is moving} — widening gaps are corrected differently from narrowing ones. Enders and Granger introduced this for interest rates, where momentum matters more than level.{p_end}
{p2colreset}{...}

{pstd}
Enders and Siklos (2001) suggest running both and selecting on an information
criterion when theory does not settle it. If you do that, {bf:say so}: it is a
specification search, and the reported p-value no longer has its nominal size.

{marker band}{...}
{title:The band model (Balke & Fomby 1997)}

{pstd}
With {opt band} the series has {bf:three} regimes and does {bf:not adjust at all}
inside the band:

{p 12 12 2}
Δ{it:z_t} = ρ{sub:u}·{it:w_u}·1{c -(}{it:z_{t-1}} > τ{sub:u}{c )-}
+ ρ{sub:l}·{it:w_l}·1{c -(}{it:z_{t-1}} < τ{sub:l}{c )-}
+ Σ β{sub:i}Δ{it:z_{t-i}} + {it:e_t}

{pstd}
This is the transaction-cost story: small deviations are not worth correcting, so
inside [τ{sub:l}, τ{sub:u}] the series is a random walk by construction, and
mean reversion only switches on once the gap is large enough to pay for the
adjustment. It is why a linear unit-root test can fail to reject on a series that
is globally mean reverting.

{pstd}
The two forms differ in {it:where the series is pulled back to}:

{p2colset 6 20 22 2}{...}
{p2col:{bf:btar}}{it:w_u} = {it:z_{t-1}} − τ{sub:u}, {it:w_l} = {it:z_{t-1}} − τ{sub:l}. Adjustment towards the nearer {bf:edge} of the band. The series comes to rest anywhere inside.{p_end}
{p2col:{bf:eqtar}}{it:w_u} = {it:w_l} = {it:z_{t-1}}. Adjustment towards {bf:equilibrium} (zero). The band only slows the return, it does not change the target.{p_end}
{p2colreset}{...}

{pstd}
{bf:The band is symmetric by default} (τ{sub:l} = −τ{sub:u}, a one-dimensional
search). {opt asymmetric} searches both bounds on a two-dimensional grid, which is
{it:G}² fits per bootstrap replication, so {opt gridn()} defaults to 30 there and
the bootstrap gets expensive quickly.

{pstd}
{bf:Centre the series first.} A band around zero is only meaningful for a series
whose equilibrium is zero — a cointegrating residual, a spread, a deviation from
parity. Applied to a raw level the lower regime is empty, the design is rank
deficient and the Wald statistics are not what they appear to be. {cmd:thmtar}
refuses that case with an error naming the regime counts rather than returning a
degenerate number.

{marker nulls}{...}
{title:Remarks: the two nulls are not interchangeable}

{pstd}
{bf:Φ: ρ{sub:1} = ρ{sub:2} = 0.} This is the test of interest for cointegration
or stationarity. Its null distribution is {bf:not} standard F: under the null the
series has a unit root, so the usual asymptotics fail. Enders and Siklos (2001)
tabulate critical values; {cmd:thmtar} simulates the p-value by generating random
walks from the null residuals and repeating the whole procedure, including the
threshold search when {opt consistent} is used. That covers the estimated-threshold
case, which the published tables do not.

{pstd}
{bf:ρ{sub:1} = ρ{sub:2}.} This is a conventional test, reported with a standard
χ²(1) p-value — {it:conditional} on rejecting the first null. Asymmetric
adjustment around a unit root is not a meaningful finding: if Φ does not reject,
the symmetry test describes the adjustment of a series that may not adjust at all.
Read them in order.

{pstd}
{bf:Half-lives.} With ρ̂{sub:j} the regime-specific adjustment speed, the half-life
is ln(0.5)/ln(1+ρ̂{sub:j}). Report both when adjustment is asymmetric; a single
average half-life hides exactly the finding.

{marker postest}{...}
{title:Postestimation}

{pstd}
{cmd:estat} subcommands:

{synoptset 22 tabbed}{...}
{synopt:{cmd:estat regimes}}the two adjustment coefficients side by side with
the symmetry test and the Phi test, and the regime counts{p_end}
{synopt:{cmd:estat halflife}}the half-life of a deviation in each regime{p_end}
{synopt:{cmd:estat profile}}the residual sum of squares over the threshold
grid; {opt graph} draws it{p_end}
{synopt:{cmd:estat bootdist}}the bootstrap null distribution of Phi;
{opt graph} draws it{p_end}
{synopt:{cmd:estat zplot}}the indicator variable over time with the threshold
(or the band) drawn{p_end}
{synopt:{cmd:estat table}}a publication summary{p_end}

{pstd}
{cmd:estat halflife} reports ln(.5)/ln(1+{it:rho}), the number of periods a
deviation takes to decay by half if the process stayed in that regime. Two
warnings go with it. It is a summary of {it:one} regime taken on its own, and a
process that switches regimes does not decay at either rate for long, so read
the two numbers as a comparison and not as a forecast. And if {it:rho} is zero
or positive in a regime there is no mean reversion there at all, which is
reported as such rather than as a very large number -- in a band model that is
the {it:expected} result inside the band, where there is no adjustment by
construction.

{pstd}
{cmd:estat profile} needs a threshold that was actually searched over, so it
requires {opt consistent} or {opt band}. A flat profile means a weakly
identified threshold: the adjustment coefficients are still consistent, but the
threshold itself should not then be given an economic interpretation.

{pstd}
{cmd:predict} supports:

{synoptset 22 tabbed}{...}
{synopt:{opt xb}}the linear prediction of D{it:z}{p_end}
{synopt:{opt residuals}}residuals{p_end}
{synopt:{opt regime}}1 or 2 for a two-regime model; 1 below / 2 inside / 3
above for a band model, with value labels{p_end}
{synopt:{opt ec}}{it:z} itself: the series, or the Engle-Granger residual under
{opt coint}{p_end}
{synopt:{opt ind:icator}}the variable the indicator function is applied to
(L.{it:z} for TAR, LD.{it:z} for M-TAR){p_end}

{pstd}
Note that the dependent variable is D{it:z}, so {opt xb} and {opt residuals}
refer to the {it:change} in {it:z}, not to its level. Under {opt coint} both
{cmd:predict} and {cmd:estat zplot} have to re-run the first-stage regression to
rebuild {it:z}; they do it inside {helpb _estimates} {cmd:hold ..., restore}, so
{cmd:e()} is intact afterwards and further postestimation commands still work.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Asymmetric unit root, TAR, threshold estimated{p_end}
{phang2}{cmd:. thmtar y, model(tar) lags(2) consistent}{p_end}

{pstd}Momentum version: does the series adjust differently when rising?{p_end}
{phang2}{cmd:. thmtar y, model(mtar) lags(2) threshold(0)}{p_end}

{pstd}Threshold cointegration between two series, M-TAR on the residual{p_end}
{phang2}{cmd:. thmtar y x, coint model(mtar) lags(1) consistent}{p_end}

{pstd}Band model on a cointegrating residual, band estimated{p_end}
{phang2}{cmd:. quietly regress y x}{p_end}
{phang2}{cmd:. predict double resid, residuals}{p_end}
{phang2}{cmd:. thmtar resid, band consistent bandtype(btar) lags(1)}{p_end}

{pstd}Adjustment to equilibrium rather than to the band edge, bounds fixed{p_end}
{phang2}{cmd:. thmtar resid, band bandlimits(-0.5 0.5) bandtype(eqtar) lags(1)}{p_end}

{pstd}Let the two bounds differ{p_end}
{phang2}{cmd:. thmtar resid, band consistent asymmetric gridn(40) lags(1)}{p_end}

{pstd}Heteroskedasticity-robust, wild bootstrap, reproducible{p_end}
{phang2}{cmd:. thmtar y x, coint vce(robust) boot(wild) reps(5000) seed(12345)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:thmtar} is {it:eclass}. It stores{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(phi)}, {cmd:e(p_phi)}}Φ statistic and its bootstrap p-value{p_end}
{synopt:{cmd:e(f_sym)}, {cmd:e(p_sym)}}symmetry statistic and its χ²(1) p-value{p_end}
{synopt:{cmd:e(tmax)}}max of the two t statistics{p_end}
{synopt:{cmd:e(tau)}}threshold used or estimated{p_end}
{synopt:{cmd:e(band)}}1 if a band model was fitted{p_end}
{synopt:{cmd:e(tau_lower)}, {cmd:e(tau_upper)}}band bounds{p_end}
{synopt:{cmd:e(N_inband)}}observations inside the band{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}observations above and below{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(lags)}, {cmd:e(trim)}, {cmd:e(boot_reps)}}fit and settings{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(model)}}{cmd:tar} or {cmd:mtar}{p_end}
{synopt:{cmd:e(stage1)}}what the model was applied to{p_end}
{synopt:{cmd:e(threshtype)}}fixed or consistent{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}ρ{sub:1}, ρ{sub:2}, lag coefficients, constant{p_end}
{synopt:{cmd:e(profile)}}SSR against the candidate thresholds{p_end}
{synopt:{cmd:e(bdist)}}bootstrap distribution of Φ{p_end}
{p2colreset}{...}

{marker valid}{...}
{title:Validation}

{pstd}
Once the threshold is fixed the model is an ordinary linear regression, so every
statistic is checked against Stata's own {helpb regress} and {helpb test} on a
hand-built design — an independent code path — and matches to 1e-9 or better, for
TAR, M-TAR, B-TAR and EQ-TAR alike. The consistent threshold and the estimated band
are checked to be the exact argmin of the stored profile, the symmetric band is
checked to be exactly symmetric, the asymmetric search is checked never to fit
worse, and the empty-regime refusal is checked to fire. See {bf:tests/reference/thmtar/certify_thmtar.do}.

{marker refs}{...}
{title:References}

{phang}
Balke, N. S., and T. B. Fomby. 1997. Threshold cointegration. {it:International
Economic Review} 38: 627-645.
{browse "https://doi.org/10.2307/2527284":doi:10.2307/2527284}.

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics} 21:
520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}.

{phang}
Enders, W., and C. W. J. Granger. 1998. Unit-root tests and asymmetric adjustment
with an example using the term structure of interest rates. {it:Journal of
Business & Economic Statistics} 16: 304-311.
{browse "https://doi.org/10.1080/07350015.1998.10524769":doi:10.1080/07350015.1998.10524769}.

{phang}
Enders, W., and P. L. Siklos. 2001. Cointegration and threshold adjustment.
{it:Journal of Business & Economic Statistics} 19: 166-176.
{browse "https://doi.org/10.1198/073500101316970395":doi:10.1198/073500101316970395}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thtar}, {helpb thregress},
{helpb thtest}
{p_end}
