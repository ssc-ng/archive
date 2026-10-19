{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{vieweralsosee "tvtsel" "help tvtsel"}{...}
{vieweralsosee "tvtplot" "help tvtplot"}{...}
{viewerjumpto "Syntax" "tvtinar##syntax"}{...}
{viewerjumpto "Description" "tvtinar##description"}{...}
{viewerjumpto "The model" "tvtinar##model"}{...}
{viewerjumpto "Options" "tvtinar##options"}{...}
{viewerjumpto "Which estimator" "tvtinar##which"}{...}
{viewerjumpto "Choosing the memory and the percentile" "tvtinar##tuning"}{...}
{viewerjumpto "What is validated" "tvtinar##validation"}{...}
{viewerjumpto "Examples" "tvtinar##examples"}{...}
{viewerjumpto "Stored results" "tvtinar##results"}{...}
{viewerjumpto "References" "tvtinar##references"}{...}
{viewerjumpto "Author" "tvtinar##author"}{...}
{title:Title}

{phang}
{bf:tvtinar} {hline 2} Threshold model for COUNTS with an empirical
quantile threshold (EQTINAR)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtinar} {depvar} {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:The threshold}
{synopt :{opt mem:ory(#)}}size of the local memory {it:m}; default 6{p_end}
{synopt :{opt pct(#)}}the percentile {it:c} in (0,1]; {bf:omit it to have
it chosen}{p_end}
{synopt :{opt minr:eg(#)}}smallest admissible regime share; default
0.15{p_end}

{syntab:The estimator}
{synopt :{opt meth:od(cls|cml)}}conditional least squares or conditional
maximum likelihood; default {cmd:cls}{p_end}
{synopt :{opt innov:ation(poisson|geometric)}}innovation law, used by
{cmd:cml}; default {cmd:poisson}{p_end}
{synopt :{opt l:evel(#)}}confidence level{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:depvar} must be a {bf:non-negative integer count} and the data must
be {helpb tsset} with no gaps in the estimation sample.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtinar} fits the EQTINAR(1) model of Jia, Zhu, Wang and Li (2026):
an integer-valued autoregression in which the regime is decided by
comparing the previous count with an {bf:empirical quantile of the counts
just before it}.

{pstd}
{bf:This is the only command in TVTHRESH for count data.} Everything else
in the library is Gaussian, and a Gaussian threshold model fitted to
counts is the wrong family however the threshold behaves. That is why
{helpb tvtsel} sends an integer-valued dependent variable here before it
looks at anything else.


{marker model}{...}
{title:The model}

{p 8 8 2}
{it:X_t} = ({it:a1} o {it:X_t-1}) {it:I_t,1} +
({it:a2} o {it:X_t-1}) {it:I_t,2} + {it:Z_t}

{pstd}
where {bf:o} is {bf:binomial thinning}: {it:a} o {it:X} is the number of
successes in {it:X} independent Bernoulli({it:a}) trials. That is what
keeps the process integer-valued, rather than discretising a continuous
model, and it is why {it:a1} and {it:a2} are {bf:probabilities and not
regression slopes}. Each is the chance that any one of last period's
counts survives into this one.

{pstd}
The regime is

{p 8 8 2}
{it:I_t,1} = 1{c -(}{it:X_t-1} <= {it:mu_t-2}({it:c}){c )-}

{pstd}
and {it:mu_t-2}({it:c}) is the ({it:c}*{it:m})-th smallest value of the
{bf:local memory} {it:X_t-m-1}, ..., {it:X_t-2}.

{pstd}
{bf:Note where the memory ends.} It stops at {it:t-2}, so the value being
classified, {it:X_t-1}, is {bf:not itself inside the window it is
compared against}. Were it included, every observation would be judged
against a quantile it helped set.

{pstd}
{bf:The first {it:m}+1 observations are spent} building the first memory,
so an estimation sample of {it:n} leaves {it:n}-{it:m}-1 usable.


{marker options}{...}
{title:Options}

{phang}
{opt memory(#)} is {it:m}, how far back the threshold looks. Small {it:m}
tracks short-term noise; large {it:m} drifts toward a fixed quantile of
the whole sample and gives up the point of the method.

{phang}
{opt pct(#)} is {it:c}. {bf:Leave it out and it is chosen for you} by
minimum sum of squared errors over the admissible candidates. See
{it:Choosing the memory and the percentile}.

{phang}
{opt minreg(#)} is the floor on each regime's share of the sample when
{it:c} is searched. The source uses 0.15.

{phang}
{opt method()} and {opt innovation()}: see {it:Which estimator}.


{marker which}{...}
{title:Which estimator}

{phang}
{bf:{cmd:method(cls)}} {hline 2} conditional least squares, the default.
The conditional mean is linear in ({it:a1}, {it:a2}, {it:lambda}), so
this is a closed-form least squares solve: fast, and it cannot fail to
converge.

{phang}
{bf:{cmd:method(cml)}} {hline 2} conditional maximum likelihood. More
precise, and {bf:bounded by construction}, but it needs the innovation
law to be named and it has to be optimised numerically.

{pstd}
{bf:There is a real catch with {cmd:cls} on short series.} Nothing in a
closed-form solve holds {it:a1} and {it:a2} inside (0,1). In this
library's replication of the source's own Scenario A at {it:n} = 50,
{bf:20.7 per cent of {it:a1} estimates came out outside (0,1)} {hline 2}
against 0.2 per cent for {it:a2}. An estimate outside (0,1) is not a
probability and cannot be interpreted as one. The command says so when it
happens; if it does, use {cmd:method(cml)} or fit a longer series.

{pstd}
Under {cmd:innovation(poisson)} the variance is tied to the mean,
{it:sigma2_z} = {it:lambda}, so {bf:there are three free parameters, not
four}, and the two rows carry the same information. Under
{cmd:innovation(geometric)}, {it:sigma2_z} = {it:lambda}(1+{it:lambda}),
which allows overdispersion and is still not free. Only {cmd:cls}
estimates the variance separately, which is why it alone can report a
{it:sigma2_z} that disagrees with {it:lambda}.


{marker tuning}{...}
{title:Choosing the memory and the percentile}

{pstd}
{bf:{it:m} is yours to set; {it:c} is chosen from the data.} That split
is the source's, and it is deliberate: {it:m} says what "recent" means
for your series, which is a question about the subject matter, while
{it:c} is a nuisance parameter.

{pstd}
When {opt pct()} is omitted the candidates are {it:c} = 1/{it:m}, ...,
restricted to those leaving both regimes above {opt minreg()}, and the
one minimising the sum of squared errors is kept.

{pstd}
{bf:The standard errors then condition on the chosen {it:c}} and do not
account for the search having happened. The source does the same. If that
matters for your application, set {opt pct()} from theory and report that
you did.


{marker validation}{...}
{title:What is validated}

{pstd}
Against the source's {bf:Table 1} {hline 2} Scenario A of Model I,
({it:a1}, {it:a2}, {it:lambda}) = (0.3, 0.6, 1) with Poisson
innovations, {it:c} = 0.5 and {it:m} = 6 {hline 2} which is an exact
published numerical target.

{pstd}
{bf:At {it:n} = 200 and 500 both estimators reproduce it closely.} At
{it:n} = 500, CLS gives 0.2870 / 0.5890 / 1.0204 against the published
0.2866 / 0.5938 / 1.0153, with standard deviations and mean squared
errors agreeing to the third decimal; CML gives 0.2968 / 0.5965 / 1.0038
against 0.2940 / 0.5990 / 1.0034.

{pstd}
{bf:CML also reproduces the {it:n} = 50 row}; CLS does not, and the
out-of-range finding above is exactly where the difference sits. The full
comparison is in
{bf:validation/tvthresh/tvtinar_equation_map.md}.


{marker examples}{...}
{title:Examples}

{pstd}Let the percentile be chosen, with a six-period memory{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tvtinar cases}{p_end}

{pstd}The source's own setting, stated rather than searched{p_end}
{phang2}{cmd:. tvtinar cases, memory(6) pct(0.5)}{p_end}

{pstd}Maximum likelihood, and overdispersed innovations{p_end}
{phang2}{cmd:. tvtinar cases, method(cml)}{p_end}
{phang2}{cmd:. tvtinar cases, method(cml) innovation(geometric)}{p_end}

{pstd}A longer memory, for a series whose "recent normal" moves slowly{p_end}
{phang2}{cmd:. tvtinar cases, memory(20)}{p_end}

{pstd}Look at the threshold path{p_end}
{phang2}{cmd:. quietly tvtinar cases}{p_end}
{phang2}{cmd:. matrix list e(path)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtinar} is {cmd:eclass} and stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}usable observations, {it:n}-{it:m}-1{p_end}
{synopt:{cmd:e(memory)}}{it:m}{p_end}
{synopt:{cmd:e(pct)}}the percentile {it:c} used{p_end}
{synopt:{cmd:e(k_order)}}its rank within the memory{p_end}
{synopt:{cmd:e(sigma2_z)}}innovation variance{p_end}
{synopt:{cmd:e(share1)}}share in the lower regime{p_end}
{synopt:{cmd:e(n_cand)}}candidates the search considered{p_end}
{synopt:{cmd:e(inrange)}}1 if both thinning parameters are inside
(0,1){p_end}
{synopt:{cmd:e(ll)}}log likelihood, {cmd:cml} only{p_end}
{synopt:{cmd:e(minreg)}}, {cmd:e(level)}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tvtinar}{p_end}
{synopt:{cmd:e(method)}}, {cmd:e(innovation)}, {cmd:e(searched)}{p_end}
{synopt:{cmd:e(depvar)}}, {cmd:e(timevar)}, {cmd:e(threshvar)}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}{it:a1}, {it:a2}, {it:lambda}, {it:sigma2_z}{p_end}
{synopt:{cmd:e(V)}}variance matrix{p_end}
{synopt:{cmd:e(path)}}the fitted threshold at each usable {it:t}{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Jia, Y., F. Zhu, T. Wang, and Q. Li. 2026. A new time-varying-threshold
integer-valued autoregressive model. {it:Communications in Nonlinear
Science and Numerical Simulation} 163: 110445.
{browse "https://doi.org/10.1016/j.cnsns.2026.110445":doi:10.1016/j.cnsns.2026.110445}

{phang}
Motegi, K., J. W. Dennis, and S. Hamori. 2024. Conditional Threshold
Autoregression. SSRN Working Paper 3960058 {hline 2} the continuous-valued
model this one adapts to counts; see {helpb tvtcotar}.
{browse "https://doi.org/10.2139/ssrn.3960058":doi:10.2139/ssrn.3960058}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
