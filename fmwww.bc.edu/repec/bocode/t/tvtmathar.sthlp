{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{viewerjumpto "Syntax" "tvtmathar##syntax"}{...}
{viewerjumpto "Description" "tvtmathar##description"}{...}
{viewerjumpto "Why this one needs no bootstrap" "tvtmathar##observed"}{...}
{viewerjumpto "Options" "tvtmathar##options"}{...}
{viewerjumpto "The model space" "tvtmathar##models"}{...}
{viewerjumpto "What the paper does not prove" "tvtmathar##theory"}{...}
{viewerjumpto "Examples" "tvtmathar##examples"}{...}
{viewerjumpto "Stored results" "tvtmathar##results"}{...}
{viewerjumpto "Validation" "tvtmathar##validation"}{...}
{viewerjumpto "References" "tvtmathar##references"}{...}
{viewerjumpto "Author" "tvtmathar##author"}{...}
{title:Title}

{phang}
{bf:tvtmathar} {hline 2} Moving average threshold heterogeneous
autoregression


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtmathar} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt freq(numlist)}}averaging horizons; default
{cmd:freq(1 5 20)}{p_end}
{synopt :{opt lags:mu(#)}}window for the threshold; default
{it:floor}(sqrt({it:n})){p_end}
{synopt :{opt crit:erion(aic|bic)}}model selection criterion; default
{cmd:aic}{p_end}
{synopt :{opt model(#)}}fit this model instead of selecting one{p_end}
{synopt :{opt norob:ust}}non-robust covariance{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
A heterogeneous autoregression (HAR) explains a series by its own averages
over several horizons {hline 2} for daily financial data, typically the
previous day, week and month. {cmd:tvtmathar} adds a threshold effect at
each horizon, where the threshold is itself a {bf:moving average of that
horizon's own average}:

{p 8 8 2}
{it:y_t} = {it:b0} + SUM_k {c -(} {it:b_k} {it:y^(k)}_{c -(}t-1{c )-} +
{it:psi_k} 1[{it:y^(k)}_{c -(}t-1{c )-} {ul:>} {it:mu^(k)}_{c -(}t-1{c )-}]
{it:y^(k)}_{c -(}t-1{c )-} {c )-} + {it:u_t}

{pstd}
with {it:y^(k)_t} the average of the last {it:m_k} observations and
{it:mu^(k)_t} the average of {it:y^(k)} over the last {opt lagsmu()}
periods. So the model asks: {it:does the series behave differently when its
weekly average is above its recent typical weekly average?}

{pstd}
{bf:Use it when} the natural story is about horizons {hline 2} realised
volatility, trading activity, macro series with monthly/quarterly/annual
structure {hline 2} and the threshold you have in mind is "above or below
the recent norm at that horizon".


{marker observed}{...}
{title:Why this one needs no bootstrap}

{pstd}
{bf:The threshold is fully observed.} It is a moving average of a quantity
already computed from the data, so there is no unknown threshold parameter
anywhere in the model. Everything follows from that single fact:

{p 8 10 2}{bf:.} the model is a {bf:linear regression} in the coefficients,
estimable by ordinary least squares;{p_end}
{p 8 10 2}{bf:.} there is {bf:no grid search} and nothing to profile;{p_end}
{p 8 10 2}{bf:.} under the null of no threshold effect {bf:nothing becomes
unidentified}, so {bf:Davies' problem does not arise} and the test is an
ordinary Wald test {hline 2} no bootstrap, no simulated critical
values;{p_end}
{p 8 10 2}{bf:.} it is by a wide margin the {bf:fastest} command in this
library.{p_end}

{pstd}
{bf:The price.} Because the threshold is an {it:average}, this model can
only ever ask "is the series above its recent norm?". It {bf:cannot} express
"is the series unusual?" {hline 2} a threshold at an extreme rather than a
central level. {helpb tvtcotar} exists to relax exactly that, using a
rolling {it:quantile} instead of a rolling mean, and it pays for the
flexibility with a grid search, a Davies problem and a bootstrap. If you
want the threshold to sit anywhere other than the middle, this is not the
command.


{marker options}{...}
{title:Options}

{phang}
{opt freq(numlist)} lists the averaging horizons {it:m_k}. The default
{cmd:freq(1 5 20)} is day, week and month for daily data; use
{cmd:freq(1 3 12)} for month, quarter and year with monthly data. The first
horizon is normally 1 (the series itself). Between two and six horizons are
allowed, since the command fits all 2^K models.

{phang}
{opt lagsmu(#)} is the window over which each threshold is averaged. The
default is the paper's rule of thumb, {it:floor}(sqrt({it:n})). The
trade-off it manages is stated in the paper: a short window makes the
threshold volatile, a long one lets the average and its threshold drift
apart so the indicator stops switching.

{phang}
{opt criterion(aic|bic)} chooses between the two information criteria, both
in their per-observation form, {it:log}(SSR/{it:n}) plus the penalty.

{phang}
{opt model(#)} fits a specific model rather than selecting one {hline 2}
useful for reporting the full specification alongside the selected one, or
for checking how much the selection mattered.

{phang}
{opt norobust} uses the classical covariance. Robust is the default.


{marker models}{...}
{title:The model space}

{pstd}
With {it:K} horizons each can either carry a threshold term or not, giving
2^{it:K} models. They are numbered by how many threshold terms they have,
then in horizon order, so for {cmd:freq(1 5 20)}:

{p2colset 8 20 22 2}{...}
{p2col :model 1}no threshold terms {hline 2} plain HAR{p_end}
{p2col :models 2-4}one threshold term, at the first, second, third
horizon{p_end}
{p2col :models 5-7}two threshold terms{p_end}
{p2col :model 8}all three {hline 2} the full MAT-HAR{p_end}
{p2colreset}{...}

{pstd}
Every model is fitted and scored; {cmd:e(models)} holds the SSR, AIC, BIC,
Wald statistic and p-value for all of them, so the selection can be
inspected rather than taken on trust. If the criterion picks model 1, plain
HAR was preferred and there is no threshold effect to report.


{marker theory}{...}
{title:What the paper does not prove}

{pstd}
{bf:There is no asymptotic theory for these estimators.} The paper says so
in a footnote: deriving the asymptotic properties of the least-squares
estimators of MAT-HAR is beyond its scope, and they are studied only by
simulation. The Wald test is accordingly treated as asymptotically
chi-squared {bf:without proof}.

{pstd}
That is reported here rather than buried, because it affects how a result
should be read. A decisive p-value is probably telling you something; a
borderline one rests on a limit that has not been established. The
simulation evidence in the paper is the support for it, not a theorem.

{pstd}
Note also that the document on disk is the longer SSRN working paper, while
the published article in the {it:Journal of Forecasting} is about half its
length. Tables may differ between the two.


{marker examples}{...}
{title:Examples}

{pstd}Daily data: day, week, month.{p_end}
{phang2}{cmd:. tvtmathar rv, freq(1 5 20)}{p_end}

{pstd}Monthly data: month, quarter, year.{p_end}
{phang2}{cmd:. tvtmathar y, freq(1 3 12)}{p_end}

{pstd}Select by BIC instead, which penalises the extra threshold terms more
heavily.{p_end}
{phang2}{cmd:. tvtmathar y, freq(1 3 12) criterion(bic)}{p_end}

{pstd}Report the full model regardless of what the criterion picked, and
compare.{p_end}
{phang2}{cmd:. tvtmathar y, freq(1 3 12)}{p_end}
{phang2}{cmd:. estimates store selected}{p_end}
{phang2}{cmd:. tvtmathar y, freq(1 3 12) model(8)}{p_end}
{phang2}{cmd:. estimates store full}{p_end}

{pstd}Look at the whole model space before believing the selection.{p_end}
{phang2}{cmd:. matrix list e(models)}{p_end}

{pstd}A longer threshold window.{p_end}
{phang2}{cmd:. tvtmathar y, freq(1 5 20) lagsmu(60)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtmathar} is {bf:e-class}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations in the sample{p_end}
{synopt:{cmd:e(N_eff)}}observations used, after the longest average{p_end}
{synopt:{cmd:e(model)}}the selected model number{p_end}
{synopt:{cmd:e(n_models)}}2^{it:K}{p_end}
{synopt:{cmd:e(n_thresh)}}threshold terms in the selected model{p_end}
{synopt:{cmd:e(lagsmu)}}threshold averaging window used{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(ssr)}}fit of the selected
model{p_end}
{synopt:{cmd:e(wald)}, {cmd:e(p_wald)}}no-threshold-effect test{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtmathar}{p_end}
{synopt:{cmd:e(freq)}}the horizons used{p_end}
{synopt:{cmd:e(criterion)}}{cmd:aic} or {cmd:bic}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients: constant, one per horizon, then
the threshold terms{p_end}
{synopt:{cmd:e(models)}}every model: number, parameters, SSR, AIC, BIC,
threshold count, Wald, p{p_end}


{marker validation}{...}
{title:Validation}

{pstd}
The authors ship their MATLAB, so this implementation is checked against it
directly. Validation is in two layers, because the authors' own generator
leaves the first few horizon-averages at zero as an initialisation artifact
and their estimator then uses those zeros {hline 2} harmless inside their
simulation, but wrong on real data, so this command computes the averages
properly and starts the sample after the longest horizon.

{p 8 10 2}{bf:.} {bf:The construction}: given the same series, the horizon
averages and the thresholds computed here match theirs to {bf:7e-16}
wherever both are well defined.{p_end}
{p 8 10 2}{bf:.} {bf:The regression}: given their own averages and
thresholds read straight from MATLAB, the coefficients, AIC and BIC match
for {bf:all eight models}, and the same model is selected.{p_end}

{pstd}
Together these pin the command without inheriting the artifact. See
{bf:validation/tvthresh/tvtmathar_equation_map.md}, which also records the
exact criterion formulas and how they were verified.

{pstd}
No line of the authors' code is used; the archive carries no licence, so it
is treated as all-rights-reserved and was read and run only.


{marker references}{...}
{title:References}

{phang}
Motegi, K., X. Cai, S. Hamori, and H. Xu. 2020. Moving average threshold
heterogeneous autoregressive (MAT-HAR) models. {it:Journal of Forecasting}
39(7): 1035-1042.
{browse "https://doi.org/10.1002/for.2671":doi:10.1002/for.2671}

{phang}
Corsi, F. 2009. A simple approximate long-memory model of realized
volatility. {it:Journal of Financial Econometrics} 7(2): 174-196.
{browse "https://doi.org/10.1093/jjfinec/nbp001":doi:10.1093/jjfinec/nbp001}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb tvtcotar},
{helpb tvtfourier}
{p_end}
