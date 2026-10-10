{smcl}
{* *! version 1.0.0  07oct2026}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thtarsel" "help thtarsel"}{...}
{vieweralsosee "thselect" "help thselect"}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{vieweralsosee "threshkit choose (model/test guide)" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thsubtar##syntax"}{...}
{viewerjumpto "Description" "thsubtar##description"}{...}
{viewerjumpto "Options" "thsubtar##options"}{...}
{viewerjumpto "The selection procedure" "thsubtar##maic"}{...}
{viewerjumpto "What the standard errors condition on" "thsubtar##se"}{...}
{viewerjumpto "thsubtar, thtar or thtarsel?" "thsubtar##versus"}{...}
{viewerjumpto "Post-estimation" "thsubtar##postest"}{...}
{viewerjumpto "Examples" "thsubtar##examples"}{...}
{viewerjumpto "Stored results" "thsubtar##results"}{...}
{viewerjumpto "References" "thsubtar##refs"}{...}
{viewerjumpto "Author" "thsubtar##author"}{...}

{title:Title}

{phang}
{bf:thsubtar} {hline 2} Subset SETAR with regime-specific autoregressive
orders, SETAR(2; {it:k1}, {it:k2}), selected by minimum AIC


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thsubtar} {it:depvar} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Orders}
{synopt:{opt maxp(#)}}largest order considered in {it:either} regime; default {cmd:maxp(4)}{p_end}
{synopt:{opt arl:ower(#)}}impose the lower-regime order instead of selecting it{p_end}
{synopt:{opt aru:pper(#)}}impose the upper-regime order instead of selecting it{p_end}

{syntab:Threshold and delay}
{synopt:{opt delay(numlist)}}candidate delays {it:d}; default {cmd:delay(1)}{p_end}
{synopt:{opt thr:eshold(#)}}impose the threshold instead of searching for it{p_end}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the candidate thresholds at {it:#} quantiles; default: all{p_end}
{synopt:{opt mino:bs(#)}}minimum observations per regime{p_end}

{syntab:Fit}
{synopt:{opt nocons:tant}}suppress the regime constants{p_end}
{synopt:{opt vce(ols|robust)}}per-regime OLS (default) or heteroskedasticity-robust{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt det:ail}}print the full delay and threshold search traces{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}The data must be {helpb tsset}, and the estimation sample must be
{bf:contiguous in time} -- see {help thsubtar##options:minobs()} below.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thsubtar} fits a two-regime self-exciting threshold autoregression in
which the two regimes have {bf:different autoregressive orders}:

{p 8 8 2}
{it:y_t} = {it:a0(1)} + {it:a1(1)} {it:y_t-1} + ... + {it:ak1(1)} {it:y_t-k1} + {it:e_t(1)}{space 4}if {it:y_t-d} <= {it:r}{break}
{it:y_t} = {it:a0(2)} + {it:a1(2)} {it:y_t-1} + ... + {it:ak2(2)} {it:y_t-k2} + {it:e_t(2)}{space 4}if {it:y_t-d} >  {it:r}

{pstd}
and selects {it:k1}, {it:k2}, {it:d} and {it:r} together by the minimum-AIC
procedure of {help thsubtar##refs:Tong and Lim (1980)}, section 8.

{pstd}
{bf:Why this is a different command and not an option.} {helpb thtar} carries
{bf:one} lag set in both regimes, and {helpb thtarsel} searches for {bf:one}
order common to both. That is often wrong in exactly the way that matters: a
series can be strongly autoregressive in one regime and nearly white in the
other -- which is the entire content of a band-of-inaction story -- and forcing
the same order on both spends degrees of freedom in the quiet regime to buy
nothing. Tong and Lim's own lynx and sunspot models are asymmetric, and that
asymmetry is a substantive finding about the series, not a tuning detail.

{pstd}
Algebraically this is a threshold regression with max({it:k1}, {it:k2}) lags in
which the coefficients on the surplus lags are constrained to zero in one
regime. It is not expressible through {helpb thregress}, whose {it:varlist}
switches in {it:every} regime, which is why the design is assembled directly
here.


{marker options}{...}
{title:Options}

{phang}
{opt maxp(#)} is the largest order considered in {it:either} regime, 1 to 12.
It also sets how many leading observations are reserved; see
{help thsubtar##maic:below}.

{phang}
{opt arlower(#)} and {opt arupper(#)} {bf:impose} an order instead of selecting
it, and may be used one at a time. {cmd:arlower(0)} is admissible and means a
constant with no dynamics in the lower regime, which is frequently what a quiet
regime wants. An imposed order enters the criterion that chooses the threshold,
so the threshold is selected {it:for the model you asked for} rather than
selected on one model and then reported with another.

{phang}
{opt delay(numlist)} gives the candidate delays. With several values the one
minimising the criterion is selected and reported, and {opt detail} shows the
whole delay trace. A delay larger than {opt maxp()} is refused: the transition
variable would then not be part of the state the model propagates, so the model
would not be self-exciting in the usual sense and none of the theory behind this
command would apply to it.

{phang}
{opt threshold(#)} fixes the threshold, so only the orders are selected. Useful
when theory or an earlier fit gives the threshold.

{phang}
{opt trim(#)}, {opt gridn(#)} and {opt minobs(#)} control the candidate
thresholds exactly as in {helpb thtar}. {opt minobs()} matters more here than
elsewhere: an order is selected {it:within} each regime, so a regime needs
enough observations to distinguish {it:k} from {it:k}+1, not merely enough to be
fitted at all.

{pmore}
{bf:The sample must be contiguous in time}, and {cmd:thsubtar} refuses if it is
not. The lags are taken by {it:position} inside the estimation sample, so an
internal gap -- a missing value, a hole in the calendar, an {cmd:if} that
removes a middle stretch -- would pair observations that are not one period
apart, and the model fitted would silently differ from the model reported. Use
{helpb tsfill} or restrict to a contiguous stretch.

{phang}
{opt vce(ols|robust)} selects the per-regime covariance. See
{help thsubtar##se:below} for what these standard errors do and do not account
for.


{marker maic}{...}
{title:The selection procedure}

{pstd}
Tong and Lim's section 8, equations (8.3) to (8.6). For a fixed delay {it:d} and
a fixed candidate threshold {it:t}:

{p 8 8 2}
AIC{it:_j}({it:k}) = {it:N_j} ln( RSS{it:_j}({it:k}) / {it:N_j} ) + 2({it:k} + 1){space 6}(8.3)

{pstd}
is minimised over 0 <= {it:k} <= {opt maxp()} {bf:separately in each regime},
where {it:N_j} is {bf:that regime's own} number of observations and the
2({it:k}+1) counts the {it:k} autoregressive coefficients plus the constant.
Then

{p 8 8 2}
AIC({it:t}) = AIC({it:k1}) + AIC({it:k2}){space 26}(8.4){break}
{it:r} = argmin over the candidates of AIC({it:t}){space 14}(8.5)

{pstd}
{bf:Equation (8.4) is what makes the search cheap, and the paper gives the
reason}: the two regimes' errors are independent, so their criteria add and the
two orders can be optimised one regime at a time. The cost is O({opt maxp()})
per regime rather than O({opt maxp()}{c 94}2) over pairs. Searching the
{it:k1} x {it:k2} grid would give the same answer at many times the cost;
searching a {it:common} order would give a different and wrong one.

{pstd}
Three details in (8.3) are easy to get wrong and are worth stating because they
change the answer:

{phang2}
1. The criterion uses {bf:each regime's own} {it:N_j}, not the pooled sample
size. Using {it:n} in both makes the penalty too weak against the fit in the
smaller regime -- and the smaller regime is exactly where an order is most
likely to be overstated.

{phang2}
2. {it:k} = 0 is admissible. Refusing it is what produces spurious dynamics in
a quiet regime.

{phang2}
3. The lags come from the {bf:actual past of the series}, including observations
that fall in the {it:other} regime. The regime label is decided by
{it:y_t-d}; it does not restrict where the lags may come from.

{pstd}
{bf:On equation (8.6).} Tong and Lim normalise AIC({it:r}) by
{it:n} - max{c 123}{it:d}, {it:L}{c 125} before comparing across delays,
because in their scheme each {it:d} uses its own maximal sample and the raw
criteria are then computed on different numbers of rows. {cmd:thsubtar} instead
reserves max({opt maxp()}, max {it:d}) leading observations {bf:once}, so every
delay, every order and every candidate threshold is scored on the {bf:same}
rows. Dividing by a common count cannot change an argmin, so the normalisation
is redundant here rather than omitted; the normalised value is reported as
{cmd:e(aic_n)} for comparison with published figures. The fixed sample is the
stronger device: it makes the criteria comparable by construction instead of by
correction. {cmd:e(reserved)} reports how many rows were held back.


{marker se}{...}
{title:What the standard errors condition on}

{pstd}
The two regimes are fitted on {bf:disjoint rows}, so the design is block
diagonal and so is the reported covariance. Each block carries {bf:its own}
residual variance: the regimes have independent errors, nothing in the model
ties their variances together, and equation (8.3) has already scored them
separately -- pooling the variance here after separating it there would be
incoherent. {cmd:e(sigma2_1)} and {cmd:e(sigma2_2)} report both, and
{cmd:estat orders} flags a large ratio.

{pstd}
{bf:These standard errors are conditional on the threshold and on the selected
orders.} {help thsubtar##refs:Chan (1993)} shows the threshold estimate
converges at rate {it:n}, faster than the root-{it:n} of the coefficients,
which is what makes conditioning on it legitimate to first order. Two things
follow, and both are limitations rather than details:

{phang2}
{bf:No interval for the threshold is offered.} The super-consistency argument
justifies treating {it:r} as known for the {it:coefficients}; it does not
produce a distribution for {it:r} itself, and the inverted-likelihood-ratio
machinery that does is built for a common-order model. Use {helpb thtar} when
the threshold is the quantity of interest.

{phang2}
{bf:No test of the selected orders is offered.} Tong and Lim select by AIC and
do not test, and the orders are chosen on the same data that located the
threshold, so any conventional reference distribution would be conditional on a
data-dependent choice. {cmd:estat trace} reports the criterion surface instead,
and says so when the surface is flat enough that the choice was not really
made.


{marker versus}{...}
{title:thsubtar, thtar or thtarsel?}

{synoptset 16}{...}
{p2col:{helpb thtar}}You know the order, or you want {bf:one} order in both regimes {bf:and} an interval for the threshold. The fullest inference, the least flexible dynamics.{p_end}
{p2col:{helpb thtarsel}}You want to choose {bf:one common} order, the delay, and the {bf:number of regimes}, with the whole trace. Use it first if you do not know how many regimes there are.{p_end}
{p2col:{bf:thsubtar}}You want the two regimes to have {bf:different} orders. Two regimes only, and no interval for the threshold.{p_end}
{p2col:{helpb thselect}}You want the number of thresholds by information criteria {bf:and} a sequential bootstrap test.{p_end}
{p2colreset}{...}

{pstd}
A reasonable sequence is {helpb thtarsel} to settle the number of regimes and a
working order, {cmd:thsubtar} to see whether the orders should differ, then
{helpb thtar} for the threshold interval if {cmd:estat compare} says the
asymmetry did not buy anything.


{marker postest}{...}
{title:Post-estimation}

{synoptset 22 tabbed}{...}
{synopt:{cmd:estat trace}}the AIC surface over the candidate thresholds, with {opt graph}; reports the range and warns when it is too flat to have decided anything{p_end}
{synopt:{cmd:estat orders}}what each regime's own criterion chose, with the variance ratio{p_end}
{synopt:{cmd:estat regimes}}the two fits side by side, with blanks where a lag is {it:not in} that regime's model{p_end}
{synopt:{cmd:estat compare}}refits with the common order max({it:k1}, {it:k2}) and reports what the asymmetry saved in AIC{p_end}
{synopt:{cmd:predict}}{opt xb}, {opt residuals}, {opt regime}{p_end}
{p2colreset}{...}

{pstd}
{cmd:predict} reads the block lengths from {cmd:e(k1)} and {cmd:e(k2)}: the two
regimes carry different numbers of lags, so the fitted value cannot be
assembled with the "{it:k} columns then {it:k} columns" walk that works after
the symmetric commands.


{marker examples}{...}
{title:Examples}

{pstd}Select everything on an annual series:{p_end}
{phang2}{cmd:. thsubtar y, maxp(6)}{p_end}

{pstd}Search the delay as well, and show the traces:{p_end}
{phang2}{cmd:. thsubtar y, maxp(6) delay(1 2 3) detail}{p_end}

{pstd}Was the asymmetry worth it?{p_end}
{phang2}{cmd:. estat compare}{p_end}

{pstd}The criterion surface, to see whether the threshold was really chosen:{p_end}
{phang2}{cmd:. estat trace, graph}{p_end}

{pstd}Impose a quiet lower regime and let the upper one be selected:{p_end}
{phang2}{cmd:. thsubtar y, maxp(6) arlower(0)}{p_end}

{pstd}Fix the threshold from theory and select only the orders:{p_end}
{phang2}{cmd:. thsubtar y, maxp(6) threshold(0)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:thsubtar} is {cmd:eclass}.{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations used, after the reserved rows{p_end}
{synopt:{cmd:e(k1)}, {cmd:e(k2)}}selected or imposed orders{p_end}
{synopt:{cmd:e(gamma)}}the threshold{p_end}
{synopt:{cmd:e(delay)}}the selected delay{p_end}
{synopt:{cmd:e(aic)}}the Tong-Lim criterion at the selected cell, eq (8.4){p_end}
{synopt:{cmd:e(aic_n)}}the same divided by {cmd:e(N)}, the eq (8.6) form{p_end}
{synopt:{cmd:e(reserved)}}leading rows held back for the lags and the delay{p_end}
{synopt:{cmd:e(N_regime1)}, {cmd:e(N_regime2)}}observations per regime{p_end}
{synopt:{cmd:e(ssr1)}, {cmd:e(ssr2)}, {cmd:e(ssr)}}residual sums of squares{p_end}
{synopt:{cmd:e(sigma2_1)}, {cmd:e(sigma2_2)}}per-regime innovation variances{p_end}
{synopt:{cmd:e(maxp)}}, {cmd:e(trim)}, {cmd:e(n_grid)}, {cmd:e(hascons)}, {cmd:e(level)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thsubtar}{p_end}
{synopt:{cmd:e(model)}}{cmd:setar(2; k1, k2)}{p_end}
{synopt:{cmd:e(threshold_var)}}{cmd:L}{it:d}{cmd:.}{it:depvar}{p_end}
{synopt:{cmd:e(vce)}}, {cmd:e(vcetype)}, {cmd:e(depvar)}, {cmd:e(timevar)}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients, in equations {cmd:lower} and {cmd:upper} of {bf:different lengths}{p_end}
{synopt:{cmd:e(trace)}}one row per candidate threshold: gamma, AIC, k1, k2, N1, N2{p_end}
{synopt:{cmd:e(dtrace)}}one row per delay: delay, AIC, AIC/n, gamma, k1, k2{p_end}


{marker refs}{...}
{title:References}

{phang}
Chan, K. S. 1993. Consistency and limiting distribution of the least squares
estimator of a threshold autoregressive model. {it:Annals of Statistics}
21: 520-533.
{browse "https://doi.org/10.1214/aos/1176349040":doi:10.1214/aos/1176349040}.

{phang}
Tong, H., and K. S. Lim. 1980. Threshold autoregression, limit cycles and
cyclical data. {it:Journal of the Royal Statistical Society B} 42: 245-292.
{browse "https://doi.org/10.1111/j.2517-6161.1980.tb01126.x":doi:10.1111/j.2517-6161.1980.tb01126.x}.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb thtar}, {helpb thtarsel}, {helpb thselect},
{helpb thnregimes}, {helpb threshkit}, {helpb threshkit_choose}
{p_end}
