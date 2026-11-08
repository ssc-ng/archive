{smcl}
{* *! version 1.0.0  05Nov2026}{...}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:mmwsmed} {hline 2}}Causal mediation analysis using ratio-of-mediator-probability weighting with parametric or nonparametric weights{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
One mediator

{p 8 16 2}
{cmd:mmwsmed}
{cmd:(}{it:ovar} [{it:omvarlist}] [{cmd:,} {it:omodel}]{cmd:)}
{cmd:(}{it:mvar} [{it:mmvarlist}] [{cmd:,} {it:mmodel}]{cmd:)}
{cmd:(}{it:tvar} [{it:tmvarlist}] [{cmd:,} {it:topts}]{cmd:)}
{ifin} [{it:{help weight:pweight}}]
[{cmd:,} {it:stat} {it:options}]

{pstd}
Two mediators

{p 8 16 2}
{cmd:mmwsmed}
{cmd:(}{it:ovar} [{it:omvarlist}] [{cmd:,} {it:omodel}]{cmd:)}
{cmd:(}{it:mvar1} [{it:mmvarlist1}] [{cmd:,} {it:mmodel}]{cmd:)}
{cmd:(}{it:mvar2} [{it:mmvarlist2}] [{cmd:,} {it:mmodel}]{cmd:)}
{cmd:(}{it:tvar} [{it:tmvarlist}] [{cmd:,} {it:topts}]{cmd:)}
{ifin} [{it:{help weight:pweight}}]
[{cmd:,} {opt par:allel}|{opt seq:uential} {it:stat} {it:options}]

{phang}
{it:ovar} is the outcome and may be continuous, binary, or a count; {it:omvarlist} are pretreatment covariates added to
the outcome model for precision.{p_end}
{phang}
{it:mvar} is the mediator; {it:mmvarlist} are the pretreatment covariates of the mediator model, which should include all
confounders of the mediator-outcome relationship. With two mediators, {it:mvar1} is listed first; in a sequential design,
{it:mvar1} precedes and may affect {it:mvar2}.{p_end}
{phang}
{it:tvar} is the treatment: binary, multivalued categorical, or ordinal (nonnegative integers, at most 10 levels), or
continuous with {cmd:continuous()}. {it:tmvarlist}, if specified,
are the covariates of a treatment-selection model used to weight for nonrandom treatment assignment; omit it when the
treatment is randomized.{p_end}
{phang}
{it:omvarlist}, {it:mmvarlist}, and {it:tmvarlist} may contain factor variables; see {help fvvarlist}.{p_end}

{synoptset 28 tabbed}{...}
{marker mmodel}{...}
{synopthdr:mmodel}
{synoptline}
{synopt :{opt linear}}normal linear model for a continuous mediator; {cmd:the default}{p_end}
{synopt :{opt logit}}logistic model for a 0/1 mediator{p_end}
{synopt :{opt probit}}probit model for a 0/1 mediator{p_end}
{synopt :{opt ologit}}ordered logit model for an ordinal mediator{p_end}
{synopt :{opt mlogit}}multinomial logit model for a categorical mediator{p_end}
{synopt :{opt poisson}}Poisson model for a count mediator{p_end}
{synoptline}

{marker omodel}{...}
{synopthdr:omodel}
{synoptline}
{synopt :{opt linear}}linear model; {cmd:the default}{p_end}
{synopt :{opt logit}}logistic model for a binary (or fractional) outcome{p_end}
{synopt :{opt probit}}probit model for a binary (or fractional) outcome{p_end}
{synopt :{opt poisson}}Poisson model for a count (or nonnegative) outcome{p_end}
{synoptline}

{marker topts}{...}
{synopthdr:topts}
{synoptline}
{syntab:Treatment model, binary {it:tvar}}
{synopt :{opt log:it}}logistic regression; {cmd:the default}{p_end}
{synopt :{opt pr:obit}}probit regression{p_end}
{synopt :{opth het:probit(varlist)}}heteroskedastic probit regression; {it:varlist} models the variance{p_end}
{syntab:Treatment model, multivalued {it:tvar}}
{synopt :{opt mlog:it}}multinomial logistic regression for unordered treatment categories; the default{p_end}
{synopt :{opt olog:it}}ordered logistic regression for an ordinal treatment{p_end}
{synopt :{opt opr:obit}}ordered probit regression for an ordinal treatment{p_end}
{syntab:Continuous treatment}
{synopt :{opth cont:inuous(numlist)}}continuous treatment; evaluate effects at these values, the first being the control value{p_end}
{synopt :{opt bw:idth(#)}}kernel bandwidth; default is sd({it:tvar}) x 2.34/N^(1/4){p_end}
{synopt :{opt trim(#)}}drop units whose normalized weight exceeds {it:#} in any potential-outcome mean; default is {cmd:trim(0.1)}{p_end}
{synopt :{opt logn:ormal}}fit the generalized propensity score models to ln({it:tvar}){p_end}
{syntab:Treatment-selection weights}
{synopt :{opt tm:ethod(iptw|mmws)}}treatment-selection weights; {opt iptw} (the default) or marginal mean weighting through stratification{p_end}
{synopt :{opt tstr:ata(#)}}number of propensity-score strata for {cmd:tmethod(mmws)}; default is {cmd:tstrata(5)}{p_end}
{synoptline}

{marker stat}{...}
{synopthdr:stat}
{synoptline}
{synopt :{opt nie}}natural indirect effect(s){p_end}
{synopt :{opt nde}}natural direct effect{p_end}
{synopt :{opt te}}total effect{p_end}
{synopt :{opt pnie}}pure natural indirect effect(s){p_end}
{synopt :{opt tnde}}total natural direct effect (one mediator){p_end}
{synopt :{opt int}}treatment-by-mediator (and mediator-by-mediator) interaction effects{p_end}
{synopt :{opt pom:eans}}potential-outcome means{p_end}
{synopt :{opt all}}all effects and potential-outcome means{p_end}
{synoptline}
{p 4 6 2}
With one mediator, the default is {cmd:nie nde te}; with two mediators, the default is all effects.

{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt :{opt par:allel}}two mediators on parallel pathways; the default with two mediators{p_end}
{synopt :{opt seq:uential}}two mediators in sequence, {it:mvar1} before {it:mvar2}{p_end}
{synopt :{opt con:trol(#|label)}}level of {it:tvar} that is the control; default is the first level{p_end}
{synopt :{opt het:eroskedastic}[{cmd:(}{varlist}{cmd:)}]}with a {opt linear} mediator model, model the log of the mediator variance as a linear function of the covariates or of {it:varlist}{p_end}

{syntab:Weighting}
{synopt :{opt mw:eight(ratio|odds)}}ratio-of-mediator-probability weights (the default) or treatment odds-ratio weights{p_end}
{synopt :{opth ot:erms(varlist)}}additional terms for the treatment-given-mediator model with {cmd:mweight(odds)}{p_end}
{synopt :{opt nonp:arametric}}MMWS-based (stratified) RMPW; one categorical mediator{p_end}
{synopt :{opt str:ata(# #)}}strata on the mediator propensity score under treatment, then under control; default is {cmd:strata(3 3)}{p_end}
{synopt :{opt nmin(#)}}minimum observations of each mediator level per treatment group in a stratum; default is {cmd:nmin(1)}{p_end}
{synopt :{opt com:mon}}restrict the analysis to the region of common support{p_end}
{synopt :{opt cal:iper(#)}}widen the common-support range by {it:#} standard deviations; default is {cmd:caliper(0.2)}{p_end}

{syntab:Moderated mediation}
{synopt :{opth mod:erator(varname)}}estimate the decomposition within each level of a pretreatment moderator and test differences{p_end}

{syntab:SE/Robust}
{synopt :{opt vce(vcetype)}}{opt r:obust} (the default), {opt cl:uster} {it:clustvar}, or {opt boot:strap} [{cmd:,} {it:{help bootstrap:bootstrap_options}}]{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt diag:nostics}}display the controlled-effects regression, covariate balance, mediator distribution check, and weight diagnostics{p_end}
{synopt :{opt aeq:uations}}display the mediator and treatment models{p_end}
{synopt :{opt leg:end}}display the legend defining the effects below the table{p_end}
{synopt :{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt :{opt gen:erate(stub)}}save mediator probabilities, treatment weights, strata, and the sample indicator{p_end}
{synopt :{opt repl:ace}}replace variables previously created with {cmd:generate()}{p_end}
{synoptline}
{p 4 6 2}
{cmd:pweight}s are allowed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mmwsmed} decomposes the total effect of a treatment on an outcome into natural direct and indirect effects using
ratio-of-mediator-probability weighting (RMPW; Hong 2010; Hong, Deutsch, and Hill 2015; Hong 2015, chapters 11 to 13).
RMPW allows the effect of the mediator on the outcome to differ by treatment (a treatment-by-mediator interaction), makes no
assumption about the distribution of the outcome, and requires no model for the outcome. The estimators, the extensions implemented here, and their finite-sample performance are
described in Linden (2026). The syntax follows that of {helpb mediate}.



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt parallel} specifies two mediators that are conditionally independent of each other given treatment and the covariates
(Hong 2015, sec. 13.2). This is the default with two mediators.

{phang}
{opt sequential} specifies that {it:mvar1} precedes and may affect {it:mvar2} (Hong 2015, sec. 13.3). The model for {it:mvar2}
is fitted separately within each level of {it:mvar1} when the {it:mvar1} model is categorical, or includes {it:mvar1} as a
covariate otherwise. See {it:Remarks} for the counterfactual means identified by these weights.

{phang}
{opt control(#|label)} specifies the level of {it:tvar} that is the control. Every other level is compared with it.

{phang}
{opt heteroskedastic}[{cmd:(}{varlist}{cmd:)}], with a {opt linear} mediator model, lets the variance of the mediator depend on
covariates, as in Hong (2015, sec. 12.1.2). Within each treatment level, the mediator is normal with mean x'b and variance
exp(z'g), where z is the mediator covariates or, if specified, {it:varlist} (plus a constant); the mean and variance equations
are fitted jointly by maximum likelihood, as by {helpb hetregress} (Linden 2026). Hong's construction, E[M^2|X] - E[M|X]^2 from two linear
regressions, is not used because it can produce negative variances. By default, each treatment level has its own constant
variance. The option has no effect with {cmd:mweight(odds)}, which uses no mediator density.

{pmore}
When the mediator variance differs between treatment levels, the constant-variance model gives biased estimates, and
{cmd:heteroskedastic} removes the bias. When the difference is large, however, the ratio of the two mediator densities, and hence
the weight, is unbounded for some units: where the variance under one level is less than half that under the other, the weights
have infinite variance. Estimates then rest on a few observations, their sampling variability shrinks little as the sample
grows, and neither the robust nor the bootstrap standard errors are reliable. The same happens when the treatment shifts the
mediator by much relative to its residual standard deviation. Low Kish effective sample sizes in the weight diagnostics (see
{cmd:diagnostics}; a note is displayed when a copy's effective sample size falls below 5% of its observations or one observation
carries more than 10% of a copy's weight) are the warning sign (Linden 2026).

{dlgtab:Weighting}

{phang}
{opt mweight(ratio|odds)} specifies how the mediator weights are computed. With {opt odds}, the weight for a unit at level
{it:a} shifted to the mediator distribution of level {it:b} is

{p 12 12 2}
[pr(T=b|M,C)/pr(T=a|M,C)] x [pr(T=a|C)/pr(T=b|C)],

{pmore}
where both probabilities come from logit (binary treatment) or multinomial logit models of the treatment, and C is the
mediator's covariate list (plus {it:mvar1} for {it:mvar2} in a sequential design). A categorical mediator enters the treatment
model as indicators and other mediators enter linearly; use {cmd:oterms()} to add nonlinear or interaction terms. The mediator
model in the mediator equation then determines only whether the mediator is treated as categorical. {cmd:mweight(odds)} suits
count or skewed mediators for which a normal or Poisson model is implausible; Linden (2026) illustrates this with the number
of quarters employed in the NEWWS Riverside data.

{phang}
{opth oterms(varlist)} adds terms to the treatment models used by {cmd:mweight(odds)}, e.g., {cmd:oterms(c.m#c.m c.m#c.x1)}.
A term involving a mediator enters the model of the treatment given that mediator (with a sequential design, terms in
{it:mvar1} also enter the second model as covariates, and terms involving both mediators enter the second model); a term
involving no mediator enters every treatment model, with and without the mediator. A term involving both mediators is not
allowed with a parallel design. The odds-ratio weights are correct only if these models are.

{phang}
{opt nonparametric} computes the RMPW from stratum-specific proportions rather than model-based probabilities. It requires one
mediator with a {opt logit}, {opt probit}, or {opt ologit} model: the method stratifies on a single linear predictor of the
mediator model under each treatment level, and estimates pr(M={it:m}) by proportions within strata, which a continuous mediator
does not allow and which would leave strata too thin with two mediators. With a multivalued treatment, units excluded from
the strata of any contrast are excluded from the analysis.

{phang}
{opt strata(# #)} sets the number of strata on the linear predictor under treatment and, within each, under control. Hong (2015)
used 3 x 3 and 4 x 4 strata.

{phang}
{opt nmin(#)} sets the minimum number of observations of every mediator level, within each treatment group, that a stratum must
contain; observations in strata that fail are excluded and reported.

{phang}
{opt common} identifies the region of common support (Hong 2015, Step 3). For each linear predictor of each mediator (or odds)
model, the range observed in every treatment-by-mediator cell (every treatment group, for a linear or Poisson mediator) is widened
by {opt caliper()} standard deviations at each end, and units outside the overlap of all cells are excluded. With
{cmd:mweight(odds)}, the treatment model that includes the mediator shifts with the mediator by construction, so its overlap is
taken across treatment groups within each mediator level (across treatment groups, for a linear or Poisson mediator); the
treatment model without the mediator follows the rule above. Common support is established before the strata are formed.

{phang}
{opt caliper(#)} sets the widening of the common-support range; the default, 0.2, follows Austin (2011) as used by Hong (2015).

{dlgtab:Treatment equation}

{phang}
Covariates in the treatment equation request adjustment for treatment selection in quasi-experimental data, or for nonrandom
attrition in a randomized study (Hong 2015, sec. 12.2.1). A treatment model is fitted, and the resulting treatment weight
multiplies the mediator-model weights and the RMPW.

{pmore}
The treatment model is {opt logit} (the default), {opt probit}, or {opth hetprobit(varlist)} for a binary treatment, and
{opt mlogit} (the default), {opt ologit}, or {opt oprobit} for a treatment with more than two levels. {opt mlogit} treats the
levels as unordered categories (e.g., three different programs). {opt ologit} and {opt oprobit} are for an {it:ordinal}
treatment, whose levels are ordered (e.g., doses or intensities), and impose the proportional-odds or ordered-probit structure;
do not use them for unordered categories. The levels are ordered by their numeric values, whatever level is the control. With
{opth hetprobit(varlist)}, {it:varlist} enters the model for the log of the standard deviation; when the treatment depends
little on the covariates, the heteroskedastic-probit likelihood can be flat or have several maxima, so use {cmd:hetprobit()}
only when the variance covariates are expected to matter. In simulations under strong heteroskedasticity, a correctly specified
heteroskedastic probit model produced more variable weights and poorer performance than a simpler logit model (Linden 2026). 
The same treatment model is
used for the treatment models of {cmd:mweight(odds)}, so the treatment equation may specify a model without covariates, e.g.,
{cmd:(}{it:tvar}{cmd:, probit)}. With any model, the weights depend only on the predicted probability of each treatment level:
IPTW uses pr(T=z)/pr(T=z|X), MMWS stratifies on the predicted probabilities, and the odds-ratio mediator factor is the ratio of
the treatment odds (level t vs. the control level) with and without the mediator. The two-step standard errors account for
estimation of every treatment model.
{cmd:tmethod(iptw)} (the default) uses stabilized weights pr(T=z)/pr(T=z|X). {cmd:tmethod(mmws)} uses marginal mean weighting
through stratification (Hong 2012; Linden 2014) with {cmd:tstrata()} strata, reproducing the ATE weights of {helpb mmws}. With a
binary treatment, the strata are formed on the propensity score. With {cmd:mlogit}, each treatment level is weighted on its own set
of strata on pr(T=z) ({cmd:mmws, nominal}). With {cmd:ologit} or {cmd:oprobit}, the model implies a single balancing score, so
one set of strata is formed on pr(T = lowest level), and strata that do not contain every treatment level are excluded (Hong 2015,
sec. 5.3.2.2; {cmd:mmws, ordinal}). With {cmd:pweight}s, the strata are weighted quantiles and the stratum counts are weighted.

{dlgtab:Continuous treatment}

{phang}
{opth continuous(numlist)} specifies a continuous treatment and the treatment values at which effects are evaluated; the first
value is the control value d0 and each other value dt is compared with it, as in {helpb mediate}. RMPW requires units observed
at each treatment level, so with a continuous treatment {cmd:mmwsmed} instead uses generalized propensity score (GPS) weighting
with kernel smoothing (Hsu, Huber, Lee, and Lettry 2020). Two normal linear models for the treatment are fitted, f1(d|X) given
the covariates and f2(d|M,X) given the mediator and covariates, where X is the union of {it:tmvarlist} and {it:mmvarlist}
(the mediator enters as {cmd:i.}{it:mvar} with an {opt ologit} or {opt mlogit} mediator model; no mediator model is fitted
otherwise). With K_d(T) an Epanechnikov kernel in (T - d)/h,

{p2colset 9 32 34 2}{...}
{p2col:E[Y(dt,M(dt))]}weight K_dt(T)/f1(dt|X){p_end}
{p2col:E[Y(dt,M(d0))]}weight K_dt(T) f2(d0|M,X)/[f2(dt|M,X) f1(d0|X)]{p_end}
{p2col:E[Y(d0,M(d0))]}weight K_d0(T)/f1(d0|X){p_end}
{p2col:E[Y(d0,M(dt))]}weight K_d0(T) f2(dt|M,X)/[f2(d0|M,X) f1(dt|X)]{p_end}
{p2colreset}{...}

{pmore}
Each potential-outcome mean is a normalized weighted mean, and the effects (NIE, NDE, TE, PNIE, TNDE, INT) are defined as for a
discrete treatment, with t and c replaced by dt and d0. The mediator's distribution enters only through the GPS given the
mediator, as with {cmd:mweight(odds)}, so the mediator may be continuous, binary, or categorical. Units whose normalized weight
exceeds {opt trim()} in any mean are dropped from all means ({cmd:e(N_trim)}). The bandwidth h defaults to sd(T) x 2.34/N^(1/4)
and is held fixed across bootstrap samples. Kernel smoothing introduces a bias of order h^2 at each evaluation value, and the
estimator converges more slowly than with a discrete treatment; evaluation values should lie where the treatment has ample
support. Linden (2026) compares the default bandwidth with half of it. Standard errors are bootstrapped ({cmd:vce(bootstrap)}, 
default 500 replications; {cmd:vce(cluster} {it:clustvar}{cmd:)}
resamples clusters). Outcome covariates, two mediators, {cmd:moderator()}, {cmd:nonparametric}, {cmd:mweight()},
{cmd:common}, {cmd:control()}, and a treatment model are not allowed with {cmd:continuous()}.

{dlgtab:Moderated mediation}

{phang}
{opth moderator(varname)} specifies a pretreatment moderator taking nonnegative integer values (Hong 2015, sec. 13.1). All
models, common support, strata, and weights are estimated separately within each level, and the outcome model includes
level-specific copy indicators and covariate coefficients. Each effect is reported within each level ({cmd:r1vs0.}{it:tvar}{cmd:#}{it:g}{cmd:.}{it:moderator})
and as a difference from the first level g0, in equations named {it:effect}{cmd:_diff} (e.g., {cmd:NIE_diff:r1vs0.}{it:tvar}{cmd:#}{it:g}{cmd:.}{it:moderator}
= effect at level g minus effect at level g0). The {cmd:by:} prefix may be
used instead to run fully separate analyses.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the standard errors.

{phang2}
{cmd:vce(robust)}, the default, computes robust (sandwich) standard errors that account for the fact that the weights are
estimated. RMPW is a multistep estimator: the mediator models (or, with {cmd:mweight(odds)}, the treatment models given the
mediator), the treatment-selection model and marginal treatment shares (with treatment covariates and IPTW), and the weighted
outcome model are each fitted in turn, and the weights carry the sampling error of the earlier steps into the potential-outcome
means. {cmd:mmwsmed} stacks the estimating equations of all steps and computes the M-estimation sandwich variance (Linden 2026), so the
standard errors reflect the uncertainty in every model that produces the weights. Because each individual appears in several
counterfactual copies of the stacked data, the estimating-function contributions are summed within individuals (one cluster per
individual). For a binary mediator and treatment without {it:omvarlist}, these are the generalized method of moments standard
errors of Bein et al. (2018). The adjustment covers every mediator model ({opt logit}, {opt probit}, {opt ologit},
{opt mlogit}, {opt linear} with or without {cmd:heteroskedastic}, {opt poisson}), ratio and odds weights, binary and
multivalued treatments, IPTW, moderators, and every outcome model; common-support exclusions are treated as fixed.

{pmore2}
Treating the weights as known instead, can misstate the standard errors in either direction:
in simulations (Linden 2026) it overstated the standard error of the natural direct effect and understated that of the natural indirect
effect. The adjusted standard errors were close to the empirical standard deviation of the estimates throughout.

{pmore2}
With a {opt linear} mediator model (with or without {cmd:heteroskedastic}) combined with treatment-selection weights, the robust
standard errors can be noticeably too small in samples of moderate size (in the simulations of Linden [2026] with 800 observations, by 10%-20%),
because the density-ratio weights are variable; {cmd:vce(bootstrap)} gave standard errors close to the empirical standard
deviation and is recommended in that case.

{pmore2}
With {cmd:nonparametric} or {cmd:tmethod(mmws)}, the weights are step functions of estimated propensity scores, so there is no
derivative to propagate; the robust standard errors then treat the weights as known (a note says so), and
{cmd:vce(bootstrap)} is recommended (Linden 2026).

{phang2}
{cmd:vce(cluster} {it:clustvar}{cmd:)} computes the same standard errors, summing the contributions within the clusters
defined by {it:clustvar} instead of within individuals. Individuals must be nested within clusters (for example, students
within schools).

{phang2}
{cmd:vce(bootstrap} [{cmd:,} {it:bootstrap_options}]{cmd:)} reruns the entire procedure, including all models, common support,
and strata, in each replication and is available in every case. With {cmd:pweight}s, each resampled observation keeps its
sampling weight; this does not reflect a complex survey design, for which replicate weights (see {helpb svy bootstrap}) are
needed. {helpb estat bootstrap} is available after running {cmd:mmwsmed} with the {cmd:vce(bootstrap}} option.

{dlgtab:Reporting}

{phang}
{opt diagnostics} displays, after the table of effects, up to four additional tables (by default only the table of effects is
shown). It may also be specified on replay ({cmd:mmwsmed, diagnostics}).

{p 8 12 2}1. {it:Controlled treatment-by-mediator effects}: the regression of the outcome on the treatment, the mediator(s),
the treatment-by-mediator interactions, and {it:omvarlist}, weighted by the product of the balance weights of table 2, which
estimates the controlled direct effects (Hong 2015, Step 5). Linear and Poisson mediators are centered at their means, so the
treatment coefficients are controlled direct effects at the mean of the mediator.{p_end}
{p 8 12 2}2. {it:Covariate balance}: for each mediator and each covariate of its model, the p-value of a joint F test of the
treatment, mediator, and treatment-by-mediator coefficients (the mediator enters as indicators if categorical, linearly
otherwise), without weights and with weights for mediator value selection (Step 4). These weights are, within each treatment
group, the stabilized inverse probability (categorical mediator) or density (linear or Poisson mediator) of the observed
mediator value given the covariates, pr(M=m|T)/pr(M=m|T,X), or the MMWS stratum proportions with {cmd:nonparametric} and a
binary treatment. With {cmd:mweight(odds)}, the mediator models of the mediator equations are fitted for this table only.
In a sequential design, the second mediator's model also conditions on the first.{p_end}
{p 8 12 2}3. {it:Mediator distribution check}: for each copy whose weights change a mediator's distribution, the weighted
proportion at each level (categorical mediator) or the weighted mean (linear or Poisson mediator), next to the same quantity
in the treatment group whose distribution the copy targets. Close agreement indicates that the weights reproduce the
counterfactual mediator distribution; large gaps signal a misspecified mediator model or limited overlap. Hong (2015,
p. 290) reports this comparison after computing the RMPW (Step 6) for the NEWWS Riverside data.{p_end}
{p 8 12 2}4. {it:Weight diagnostics}: for each copy, the number of observations, the largest weight relative to the mean, the
largest weight's share of the total, and Kish's effective sample size (see Linden 2026 for their use as warning indicators).{p_end}

{phang}
All tables label the levels of the treatment, moderator, and categorical mediators with their value labels when these are
defined (otherwise with the values), and their widths are fitted to the variable names and labels.

{phang}
{opt aequations} displays the mediator and treatment models.

{phang}
{opt legend} displays, below the table, the definitions of the reported effects and potential-outcome means and a note on the
standard errors. It may also be specified on replay.

{phang}
{opt coeflegend} displays the legend of the coefficients, such as {cmd:_b[NIE:r1vs0.}{it:tvar}{cmd:]}, instead of the
statistics, for use with {helpb lincom}, {helpb test}, and {helpb nlcom}. It may also be specified on replay.

{phang}
{opt generate(stub)} saves {it:stub}{cmd:_f}{it:k}{cmd:_}{it:z} (the probability or density of the observed value of mediator
{it:k} under treatment level {it:z}, or the odds-based factor with {cmd:mweight(odds)}), {it:stub}{cmd:_tw} (treatment weight),
{it:stub}{cmd:_strata} (cross-strata), and {it:stub}{cmd:_sample} (analytic sample).



{marker examples}{...}
{title:Examples}

{pstd}All examples use the NEWWS Riverside data (Hong, Deutsch, and Hill 2015; Hong 2015, ch. 11; Linden 2026). 
Welfare applicants were randomly assigned to a labor force attachment program ({cmd:treat} = 1) or a
control condition ({cmd:treat} = 0); the outcome {cmd:trunc_dep12sm2} is maternal depressive symptoms two years after
randomization, and the mediator is employment during those two years, coded as a binary indicator ({cmd:emp}), three
categories ({cmd:emp_cat}), or the number of quarters employed, 0 to 8 ({cmd:emp_cont}). Because treatment was randomized,
no treatment-selection model is specified.{p_end}

{pstd}Setup{p_end}
{phang2}{cmd:. use Riverside.dta, clear}{p_end}

{pstd}{ul:Binary mediator}{p_end}

{pstd}Parametric RMPW with a logit mediator model and outcome-model covariates for precision; all effects and potential-outcome means, the diagnostic tables, the mediator models, and the legend{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all diagnostics aequations legend}{p_end}

{pstd}Replay the results with the coefficient legend, then test whether the natural treatment-by-mediator interaction is zero{p_end}
{phang2}{cmd:. mmwsmed, coeflegend}{p_end}
{phang2}{cmd:. test _b[INT:r1vs0.treat] = 0}{p_end}

{pstd}Restrict the analysis to the region of common support of the mediator propensity scores{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all common diagnostics}{p_end}

{pstd}Bootstrap standard errors, then percentile and bias-corrected confidence intervals{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all vce(bootstrap, reps(1000) seed(1234))}{p_end}
{phang2}{cmd:. estat bootstrap, normal percentile bc}{p_end}

{pstd}Nonparametric (stratification-based) RMPW with the default 3 x 3 strata; the two-step standard errors treat these weights as known, so bootstrap standard errors are obtained as well{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all nonpar diagnostics}{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all nonpar vce(bootstrap, reps(1000) seed(1234))}{p_end}

{pstd}Nonparametric RMPW with 4 x 4 strata within the region of common support{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all nonpar strata(4 4) common}{p_end}

{pstd}{ul:Three-category mediator}{p_end}

{pstd}Multinomial logit and ordered logit mediator models; bootstrap standard errors with the ordered logit model{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp_cat emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, mlogit) (treat), all diagnostics}{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp_cat emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, ologit) (treat), all diagnostics}{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp_cat emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, ologit) (treat), all vce(bootstrap, reps(1000) seed(1234))}{p_end}

{pstd}{ul:Number of quarters employed}{p_end}

{pstd}The number of quarters employed is bounded and has many zeros, so neither a normal nor a Poisson mediator model is
plausible. Odds-ratio weights replace the mediator model with models for treatment given the mediator and covariates; two-step
and bootstrap standard errors{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp_cont emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (treat), all mweight(odds) diagnostics}{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2 emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (emp_cont emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic) (treat), all mweight(odds) vce(bootstrap, reps(1000) seed(1234))}{p_end}

{pstd}{ul:Other analyses}{p_end}

{pstd}Moderated mediation by educational attainment (no high school diploma), with bootstrap standard errors{p_end}
{phang2}{cmd:. mmwsmed (trunc_dep12sm2) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all common moderator(nohsdip) vce(bootstrap, reps(500) seed(1234))}{p_end}

{pstd}Binary outcome (high depressive symptoms) with a logit outcome model{p_end}
{phang2}{cmd:. generate byte dep16 = trunc_dep12sm2 >= 16}{p_end}
{phang2}{cmd:. mmwsmed (dep16 pqtrunc50 hispanic, logit) (emp emp_prior pqtrunc30 pqtrunc49 pqtrunc50-pqtrunc53 hispanic, logit) (treat), all}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mmwsmed} stores the following in {cmd:e()}:

{synoptset 26 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations in the analytic sample{p_end}
{synopt:{cmd:e(N_control)}, {cmd:e(N_treat)}}control and other-level observations{p_end}
{synopt:{cmd:e(N_excl)}}observations excluded (all reasons){p_end}
{synopt:{cmd:e(N_excl_support)}}excluded for lack of common support{p_end}
{synopt:{cmd:e(N_excl_strata)}}excluded in strata failing {cmd:nmin()}{p_end}
{synopt:{cmd:e(N_excl_tw)}}excluded by the treatment-weighting step{p_end}
{synopt:{cmd:e(N_excl_miss)}}excluded because a weight could not be computed{p_end}
{synopt:{cmd:e(N_stack)}}observations in the stacked (duplicated) data{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(k_levels)}}number of treatment levels{p_end}
{synopt:{cmd:e(k_copies)}}number of counterfactual copies{p_end}
{synopt:{cmd:e(caliper)}}caliper, if {cmd:common} was specified{p_end}
{synopt:{cmd:e(N_trim)}}units trimmed (continuous treatment){p_end}
{synopt:{cmd:e(bwidth)}}kernel bandwidth (continuous treatment){p_end}
{synopt:{cmd:e(trim)}}trimming cutoff (continuous treatment){p_end}
{synopt:{cmd:e(N_reps)}}successful bootstrap replications ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(N_misreps)}}failed bootstrap replications ({cmd:vce(bootstrap)}){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mmwsmed}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}outcome{p_end}
{synopt:{cmd:e(mvar)}, {cmd:e(mvar1)}, {cmd:e(mvar2)}}mediator(s){p_end}
{synopt:{cmd:e(omodel)}}outcome model{p_end}
{synopt:{cmd:e(mmodel)}, {cmd:e(mmodel1)}, {cmd:e(mmodel2)}}mediator model(s){p_end}
{synopt:{cmd:e(tvar)}}treatment{p_end}
{synopt:{cmd:e(tlevels)}}levels of the treatment{p_end}
{synopt:{cmd:e(tvartype)}}{cmd:binary} or {cmd:multivalued}{p_end}
{synopt:{cmd:e(control)}}control level{p_end}
{synopt:{cmd:e(med_type)}}{cmd:single}, {cmd:parallel}, or {cmd:sequential}{p_end}
{synopt:{cmd:e(mweight)}}{cmd:ratio} or {cmd:odds}{p_end}
{synopt:{cmd:e(method)}}{cmd:parametric} or {cmd:nonparametric}{p_end}
{synopt:{cmd:e(strata)}}numbers of strata{p_end}
{synopt:{cmd:e(mcov1)}, {cmd:e(mcov2)}, {cmd:e(indepvars)}, {cmd:e(tcov)}}covariate lists{p_end}
{synopt:{cmd:e(tmethod)}}treatment-weighting method{p_end}
{synopt:{cmd:e(tmodel)}}treatment model{p_end}
{synopt:{cmd:e(thet)}}variance varlist of {cmd:hetprobit()}{p_end}
{synopt:{cmd:e(heteroskedastic)}}{cmd:heteroskedastic}, if specified{p_end}
{synopt:{cmd:e(hetvars)}}variance varlist of {cmd:heteroskedastic()}{p_end}
{synopt:{cmd:e(moderator)}, {cmd:e(mlevels)}}moderator and its levels{p_end}
{synopt:{cmd:e(stats)}, {cmd:e(copies)}}reported effects and counterfactual copies{p_end}
{synopt:{cmd:e(vce)}}{cmd:robust}, {cmd:cluster}, or {cmd:bootstrap}{p_end}
{synopt:{cmd:e(vceweights)}}{cmd:estimated} (std. err. account for estimation of the weights) or {cmd:known}{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt:{cmd:e(prefix)}}{cmd:bootstrap} ({cmd:vce(bootstrap)}){p_end}
{synopt:{cmd:e(bs_engine)}}{cmd:mata} or {cmd:prefix}: how the bootstrap replications were computed{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}potential-outcome means and effects{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of {cmd:e(b)}{p_end}
{synopt:{cmd:e(mcheck)}}mediator distribution check{p_end}
{synopt:{cmd:e(wdiag)}}weight diagnostics{p_end}
{synopt:{cmd:e(balance)}}balance p-values (with {cmd:diagnostics}){p_end}
{synopt:{cmd:e(ctl_b)}}controlled-effects regression coefficients (with {cmd:diagnostics}){p_end}
{synopt:{cmd:e(ctl_V)}}controlled-effects regression variance (with {cmd:diagnostics}){p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the analytic sample{p_end}


{marker references}{...}
{title:References}

{phang}
Austin, P. C. 2011. Optimal caliper widths for propensity-score matching when estimating differences in means and differences
in proportions in observational studies. {it:Pharmaceutical Statistics} 10: 150-161.

{phang}
Bein, E., J. Deutsch, G. Hong, K. E. Porter, X. Qin, and C. Yang. 2018. Two-step estimation in ratio-of-mediator-probability
weighted causal mediation analysis. {it:Statistics in Medicine} 37: 1304-1324.

{phang}
Hong, G. 2010. Ratio of mediator probability weighting for estimating natural direct and indirect effects.
{it:JSM Proceedings, Biometrics Section}, 2401-2415. Alexandria, VA: American Statistical Association.

{phang}
Hong, G. 2012. Marginal mean weighting through stratification: a generalized method for evaluating multivalued and multiple
treatments with nonexperimental data. {it:Psychological Methods} 17: 44-60.

{phang}
Hong, G. 2015. {it:Causality in a Social World: Moderation, Mediation and Spill-over}. Chichester, UK: Wiley.

{phang}
Hong, G., J. Deutsch, and H. D. Hill. 2015. Ratio-of-mediator-probability weighting for causal mediation analysis in the presence
of treatment-by-mediator interaction. {it:Journal of Educational and Behavioral Statistics} 40: 307-340.

{phang}
Hsu, Y.-C., M. Huber, Y.-Y. Lee, and L. Lettry. 2020. Direct and indirect effects of continuous treatments based on
generalized propensity score weighting. {it:Journal of Applied Econometrics} 35: 814-840.

{phang}
Huber, M. 2014. Identifying causal mechanisms (primarily) based on inverse probability weighting.
{it:Journal of Applied Econometrics} 29: 920-943.

{phang}
Linden, A. 2014. Combining propensity score-based stratification and weighting to improve causal inference in the evaluation of
health care interventions. {it:Journal of Evaluation in Clinical Practice} 20: 1065-1071.

{phang}
Linden, A. 2026. Ratio-of-mediator-probability weighting for causal mediation analysis: 
estimation, extensions, and practical guidance. Preprint {it:arXiv}.

{phang}
Tchetgen Tchetgen, E. J. 2013. Inverse odds ratio-weighted estimation for causal mediation analysis.
{it:Statistics in Medicine} 32: 4567-4580.


{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{marker citation}{title:Citation of {cmd:mmwsmed}}

{p 4 8 2}{cmd:mmwsmed} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. 
MMWSMED: Stata module for conducting causal mediation analysis using ratio-of-mediator-probability weighting with parametric or nonparametric weights. 
Statistical Software Components SXXXXXX, Boston College Department of Economics{p_end}



{title:Also see}

{p 4 8 2}Online: {helpb mediate}, {helpb mmws} (if installed), {helpb pstrata} (if installed), {helpb rwrmed} (if installed){p_end}
