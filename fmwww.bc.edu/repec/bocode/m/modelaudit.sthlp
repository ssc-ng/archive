{smcl}
{* *! version 0.1.4 29sep2026}{...}
{vieweralsosee "[R] estimates" "help estimates"}{...}
{vieweralsosee "[R] estimates stats" "help estimates stats"}{...}

{title:Title}

{phang}
{bf:modelaudit} {hline 2} Audit stored estimation models for sample changes, focal-estimate movement,
model complexity, and information criteria


{title:Syntax}

{p 8 17 2}
{cmd:modelaudit} {it:namelist}{cmd:,} {opt focal(coefname)}
[{opt base(#)} {opt previous} {opt samples} {opt eform} {opt coef} {opt level(#)}]


{title:Description}

{pstd}
{cmd:modelaudit} compares two or more stored estimation results.  It is designed as a
diagnostic and workflow tool, not as an automated model-selection command.

{pstd}
Version 0.1 reports:

{phang2}the estimation N for each stored model;{p_end}
{phang2}events and non-events for common binary-outcome estimators;{p_end}
{phang2}VCE rank from {cmd:e(rank)}, i.e. the rank of {cmd:e(V)};{p_end}
{phang2}the number of columns in {cmd:e(b)};{p_end}
{phang2}model degrees of freedom from {cmd:e(df_m)} when available;{p_end}
{phang2}descriptive events per model degree of freedom (E/df) for selected fixed-effect binary models;{p_end}
{phang2}the focal coefficient, confidence interval, and change in the raw coefficient;{p_end}
{phang2}AIC and BIC when official {cmd:estimates stats} supplies them;{p_end}
{phang2}cluster count when the estimator stores {cmd:e(N_clust)}; and{p_end}
{phang2}exact estimation-sample equality and optional pairwise sample overlap.{p_end}

{pstd}
The command requires models stored in memory, for example with {cmd:estimates store}.
Sample-comparison diagnostics additionally require a valid {cmd:e(sample)} for each model.


{title:Options}

{phang}
{opt focal(coefname)} is required.  Supply the coefficient name as Stata understands it in
{cmd:_b[]}.  Examples include {cmd:focal(exposure)} and {cmd:focal(1.exposure)}.
For multi-equation models, an equation-qualified coefficient may be required.

{phang}
{opt base(#)} specifies the model used as the comparator for coefficient change and sample
equality.  The default is the first model.

{phang}
{opt previous} compares each model with the immediately preceding model instead of a single
base model.  The first model then has no comparator.

{phang}
{opt samples} displays the complete pairwise matrix of estimation-sample overlap counts.

{phang}
{opt eform} forces exponentiation of the focal coefficient and its confidence limits.

{phang}
{opt coef} forces display on the raw coefficient scale.

{phang}
{opt level(#)} specifies the confidence level.  The default is the current Stata default
confidence level.


{title:Automatic focal-estimate scale}

{pstd}
Unless {opt eform} or {opt coef} is specified, version 0.1 uses the following display scales:

{phang2}{cmd:logit}, {cmd:logistic}, {cmd:clogit}, {cmd:xtlogit}, {cmd:melogit},
{cmd:meqrlogit}, and {cmd:firthlogit}: odds ratio (OR);{p_end}
{phang2}{cmd:stcox}: hazard ratio (HR), detected using Stata's stored {cmd:e(cmd2)} / {cmd:e(cmd)} results;{p_end}
{phang2}{cmd:poisson}, {cmd:xtpoisson}, {cmd:mepoisson}, {cmd:nbreg}, {cmd:xtnbreg},
and {cmd:menbreg}: incidence-rate ratio (IRR);{p_end}
{phang2}equation-qualified {cmd:mlogit} coefficients: relative-risk ratio (RRR);{p_end}
{phang2}other estimators: raw coefficient (b).{p_end}


{title:Important interpretation details}

{pstd}
{cmd:Delta b %} is calculated on the raw coefficient (linear-predictor) scale:
100*(b_i-b_ref)/b_ref.  This remains true when the displayed estimate is exponentiated.
If the reference coefficient equals zero, percent change is undefined.  Version 0.1.3
also suppresses {cmd:Delta b %} when the compared models use different dependent variables
or different estimation commands; {cmd:logit} and {cmd:logistic} are treated as aliases.

{pstd}
{cmd:Same samp.} in the displayed output means that {cmd:e(sample)} is exactly identical between
the two compared models.  It does not merely mean the two models have the same numerical N.
The base model is displayed as {cmd:REF}; in sequential mode the first model has no comparator.

{pstd}
AIC and BIC are obtained from official {cmd:estimates stats}.  If estimation samples differ,
{cmd:modelaudit} warns that cross-model information-criterion comparisons may reflect both
specification changes and changes in the observations being analyzed.

{pstd}
E/df is intentionally descriptive.  When shown, its denominator is {cmd:e(df_m)}.
{cmd:e(rank)} is reported separately as the rank of {cmd:e(V)}, and the number of
coefficient-vector columns is reported separately from {cmd:colsof(e(b))}.  These
quantities are not substituted for one another.  {cmd:modelaudit} does not treat a
particular events-per-parameter threshold as a validity criterion.


{title:Examples}

{phang2}{cmd:. logit y x}{p_end}
{phang2}{cmd:. estimates store m1}{p_end}
{phang2}{cmd:. logit y x age sex}{p_end}
{phang2}{cmd:. estimates store m2}{p_end}
{phang2}{cmd:. logit y x age sex i.payer}{p_end}
{phang2}{cmd:. estimates store m3}{p_end}
{phang2}{cmd:. modelaudit m1 m2 m3, focal(x)}{p_end}
{phang2}{cmd:. modelaudit m1 m2 m3, focal(x) previous samples}{p_end}


{title:Stored results}

{pstd}
{cmd:modelaudit} is an r-class command and stores:

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(summary)}}numeric model-audit matrix; rows correspond to models{p_end}
{synopt:{cmd:r(overlap)}}pairwise estimation-sample overlap counts{p_end}
{synopt:{cmd:r(models)}}model names{p_end}
{synopt:{cmd:r(focal)}}requested focal coefficient{p_end}
{synopt:{cmd:r(scales)}}display scale used for each focal estimate{p_end}
{synopt:{cmd:r(base)}}base-model index{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(nmodels)}}number of models{p_end}
{synopt:{cmd:r(sample_changes)}}1 if a requested sample comparison changed, 0 otherwise{p_end}
{synopt:{cmd:r(sample_missing)}}1 if e(sample) was unavailable for any model{p_end}
{synopt:{cmd:r(focal_missing)}}1 if the focal coefficient was unavailable for any model{p_end}
{synopt:{cmd:r(delta_suppressed)}}1 if any Delta b comparison was suppressed as noncomparable{p_end}

{pstd}
Columns of {cmd:r(summary)} are, in order: {cmd:N}, {cmd:events}, {cmd:nonevents},
{cmd:vcerank}, {cmd:modeldf}, {cmd:ep}, {cmd:b}, {cmd:estimate}, {cmd:lb}, {cmd:ub},
{cmd:pctchg}, {cmd:ll}, {cmd:aic}, {cmd:bic}, {cmd:clusters}, {cmd:sampleok},
{cmd:samecomp}, and {cmd:bcols}.  {cmd:vcerank} is {cmd:e(rank)}; {cmd:bcols} is
{cmd:colsof(e(b))}.


{title:Validation and scope}

{pstd}
The public validation suite distributed with version 0.1.4 exercises linear regression,
binary logistic regression, Poisson regression, Cox regression, factor-variable focal
coefficients, clustered standard errors, changing and unavailable estimation samples,
alternate/sequential comparators, noncomparable model pairs, and a collinearity case
in which {cmd:e(rank)} differs from {cmd:colsof(e(b))}.

{pstd}
The automatic scale-recognition rules listed above are conveniences based on stored
estimation-command metadata.  Estimator-specific behavior outside the publicly exercised
core should be checked against the estimator's own stored results.


{title:Author}

{pstd}
Christina Laternser, PhD


{title:Version}

{pstd}
Version 0.1.4.  Minimum Stata version: 14.2.

{pstd}
The first release is deliberately limited to model auditing.  It does not choose a model,
apply significance rules, or label a specification as good or bad.
