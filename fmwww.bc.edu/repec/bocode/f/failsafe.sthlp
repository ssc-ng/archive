{smcl}
{* *! version 0.1.6 18sep2026}{...}
{vieweralsosee "[R] estimates" "help estimates"}{...}
{vieweralsosee "[R] logit" "help logit"}{...}
{vieweralsosee "[ST] stcox" "help stcox"}{...}
{vieweralsosee "[ST] stcrreg" "help stcrreg"}{...}

{title:Title}

{phang}
{bf:failsafe} {hline 2} Postestimation statistical diagnostic linter for fitted Stata models

{title:Syntax}

{p 8 17 2}
{cmd:failsafe}
[{cmd:,}
{opt mincell(#)}
{opt minclusters(#)}
{opt cells}]

{title:Description}

{pstd}
{cmd:failsafe} is a read-only postestimation command that inspects the active
estimation results and reports model characteristics and statistical signals
that may warrant review.  It does not refit the model, change the
specification, select a model, or declare a fitted model statistically or
substantively valid or invalid.

{pstd}
Core checks are available after any estimation command that posts {cmd:e(b)}.
Additional estimator-specific checks are used when the fitted command exposes
the required metadata.

{pstd}
For supported binary-response estimators, {cmd:failsafe} reports estimation
sample size, event and non-event counts, model degrees of freedom, and a
descriptive events-per-model-df ratio.  It can inspect observed levels of
numeric factor variables and observed two-way categorical interaction cells.

{pstd}
For {cmd:stcox}, {cmd:failsafe} uses Stata's stored failure and subject counts.
For {cmd:stcrreg}, it additionally reports competing events and censored
subjects.  Survival models are not reduced to a binary event/non-event count.

{title:Supported estimator-specific checks}

{p 8 12 2}
Binary-response event counting and factor-cell checks are implemented for
{cmd:logit}, {cmd:logistic}, {cmd:probit}, {cmd:cloglog}, {cmd:clogit},
{cmd:xtlogit}, {cmd:melogit}, and {cmd:meqrlogit}.  The command also recognizes
{cmd:firthlogit} when installed, but that community-contributed estimator is
not part of the public validation suite.

{p 8 12 2}
Survival metadata checks are implemented for {cmd:stcox} and {cmd:stcrreg}.

{p 8 12 2}
Other e-class estimators can still receive the generic metadata, omission,
convergence, and variance-covariance checks when the corresponding stored
results are available.

{title:Options}

{phang}
{opt mincell(#)} requests a user-defined minimum total count for each observed
factor level and each observed two-way categorical interaction cell.
There is no default sparse-cell threshold.  For main effects, the quantity
being compared with {it:#} is the total number of observations in that factor
level, not the event count alone.

{phang}
{opt minclusters(#)} requests a user-defined minimum number of clusters.
The signal is evaluated only when the fitted estimator reports {cmd:e(N_clust)}.
There is no built-in "few clusters" cutoff.

{phang}
{opt cells} displays factor-level and, when applicable, observed two-way
categorical interaction outcome-cell tables for supported binary-response
models.

{title:Signals}

{p2colset 9 18 20 2}{...}
{p2col:{bf:Code}}{bf:Meaning}{p_end}
{p2line}
{p2col:{cmd:FS001}}estimation reports nonconvergence{p_end}
{p2col:{cmd:FS002}}one or more coefficients were explicitly omitted{p_end}
{p2col:{cmd:FS003}}estimator reports completely determined outcomes / perfect-prediction structure{p_end}
{p2col:{cmd:FS101}}an observed main-effect factor level has zero events or zero non-events in final {cmd:e(sample)}{p_end}
{p2col:{cmd:FS102}}a main-effect factor level is below user-specified {cmd:mincell()}{p_end}
{p2col:{cmd:FS103}}an observed two-way categorical interaction cell has zero events or zero non-events in final {cmd:e(sample)}{p_end}
{p2col:{cmd:FS104}}an observed two-way categorical interaction cell is below user-specified {cmd:mincell()}{p_end}
{p2col:{cmd:FS201}}an estimated parameter has a missing or nonpositive variance on the diagonal of {cmd:e(V)}{p_end}
{p2col:{cmd:FS202}}reported cluster count is below user-specified {cmd:minclusters()}{p_end}
{p2col:{cmd:FS901}}{cmd:e(sample)} is unavailable, limiting sample-based checks{p_end}
{p2line}

{pstd}
{cmd:FS101} and {cmd:FS103} describe cell structure in the final estimation
sample.  They are not presented as complete separation tests.  When the
estimator itself reports completely determined outcomes, {cmd:FS003} uses
that estimator-native metadata.

{title:Interpretation notes}

{pstd}
{cmd:e(rank)} is treated as the rank of {cmd:e(V)} and is reported as
{it:VCE rank}.  It is not treated as the number of coefficient columns.
{cmd:failsafe} separately reports {cmd:colsof(e(b))}.

{pstd}
The displayed events-per-model-df or failures-per-model-df quantity is
descriptive.  {cmd:failsafe} applies no rule-of-thumb adequacy threshold to
that ratio.

{pstd}
Factor-cell inspection currently supports numeric factor variables and
observed two-way categorical interactions.  Higher-order categorical
interaction coefficients may be detected, but their joint cells are not
parsed in version 0.1.6.  Continuous components of interactions are not
treated as categorical cells.

{title:Examples}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. logit foreign mpg weight}{p_end}
{phang2}{cmd:. failsafe}{p_end}

{phang2}{cmd:. logit foreign mpg i.rep78}{p_end}
{phang2}{cmd:. failsafe, cells mincell(5)}{p_end}

{phang2}{cmd:. logit y x, vce(cluster hospital)}{p_end}
{phang2}{cmd:. failsafe, minclusters(30)}{p_end}

{phang2}{cmd:. stcox x z}{p_end}
{phang2}{cmd:. failsafe}{p_end}

{phang2}{cmd:. stcrreg x z, compete(status==2)}{p_end}
{phang2}{cmd:. failsafe}{p_end}

{title:Stored results}

{pstd}
{cmd:failsafe} stores the following in {cmd:r()} when available.

{synoptset 27 tabbed}{...}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:r(N)}}estimation sample size reported by the estimator{p_end}
{synopt:{cmd:r(coef_columns)}}number of columns in {cmd:e(b)}{p_end}
{synopt:{cmd:r(vce_rank)}}rank of {cmd:e(V)}, from {cmd:e(rank)}{p_end}
{synopt:{cmd:r(rank)}}compatibility alias for {cmd:r(vce_rank)}{p_end}
{synopt:{cmd:r(modeldf)}}model degrees of freedom, from {cmd:e(df_m)}{p_end}
{synopt:{cmd:r(events)}}binary-response event count{p_end}
{synopt:{cmd:r(nonevents)}}binary-response non-event count{p_end}
{synopt:{cmd:r(failures)}}survival failures{p_end}
{synopt:{cmd:r(competing)}}competing events for {cmd:stcrreg}{p_end}
{synopt:{cmd:r(censored)}}censored subjects for {cmd:stcrreg}{p_end}
{synopt:{cmd:r(subjects)}}subjects for supported survival estimators{p_end}
{synopt:{cmd:r(epdf)}}events/model-df or failures/model-df, descriptive only{p_end}
{synopt:{cmd:r(clusters)}}reported cluster count{p_end}
{synopt:{cmd:r(converged)}}reported convergence indicator{p_end}
{synopt:{cmd:r(cds)}}completely determined successes, when posted{p_end}
{synopt:{cmd:r(cdf)}}completely determined failures, when posted{p_end}
{synopt:{cmd:r(determined_total)}}sum of completely determined successes and failures{p_end}
{synopt:{cmd:r(perfect_available)}}1 when relevant estimator metadata is available{p_end}
{synopt:{cmd:r(omitted)}}number of explicitly omitted terms detected{p_end}
{synopt:{cmd:r(sample_available)}}1 when a nonempty {cmd:e(sample)} can be reconstructed{p_end}
{synopt:{cmd:r(nfactorvars)}}number of discovered factor variables{p_end}
{synopt:{cmd:r(ninteractionsets)}}number of distinct two-way categorical interaction sets{p_end}
{synopt:{cmd:r(interaction_coef_terms)}}number of expanded interaction coefficient terms detected{p_end}
{synopt:{cmd:r(higher_interactions)}}higher-order categorical interaction coefficient terms detected but deferred{p_end}
{synopt:{cmd:r(factor_cell_rows)}}rows in {cmd:r(factor_cells)}{p_end}
{synopt:{cmd:r(interaction_cell_rows)}}rows in {cmd:r(interaction_cells)}{p_end}
{synopt:{cmd:r(zero_factor_cells)}}factor levels with zero events or zero non-events{p_end}
{synopt:{cmd:r(sparse_factor_levels)}}factor levels below {cmd:mincell()}{p_end}
{synopt:{cmd:r(zero_interaction_cells)}}observed interaction cells with zero events or zero non-events{p_end}
{synopt:{cmd:r(sparse_interaction_cells)}}observed interaction cells below {cmd:mincell()}{p_end}
{synopt:{cmd:r(vce_available)}}1 when a conformable {cmd:e(V)} was available{p_end}
{synopt:{cmd:r(se_problem_count)}}parameters with missing or nonpositive diagonal variance{p_end}
{synopt:{cmd:r(mincell)}}requested {cmd:mincell()} value{p_end}
{synopt:{cmd:r(minclusters)}}requested {cmd:minclusters()} value{p_end}
{synopt:{cmd:r(nsignals)}}number of signal codes emitted{p_end}
{synoptline}

{synoptset 27 tabbed}{...}
{synopthdr:Macros}
{synoptline}
{synopt:{cmd:r(cmd)}}stored estimator command name{p_end}
{synopt:{cmd:r(cmd2)}}secondary/front-end estimator command name, when posted{p_end}
{synopt:{cmd:r(depvar)}}dependent variable reported by estimator{p_end}
{synopt:{cmd:r(vce)}}VCE type from {cmd:e(vce)}{p_end}
{synopt:{cmd:r(vcetype)}}VCE label from {cmd:e(vcetype)}{p_end}
{synopt:{cmd:r(omitted_terms)}}explicitly omitted terms detected{p_end}
{synopt:{cmd:r(factor_vars)}}discovered factor variables{p_end}
{synopt:{cmd:r(interaction_sets)}}discovered two-way categorical interaction sets{p_end}
{synopt:{cmd:r(se_problem_terms)}}parameters with missing/nonpositive variance{p_end}
{synopt:{cmd:r(signal_codes)}}space-separated FailSafe signal codes{p_end}
{synoptline}

{synoptset 27 tabbed}{...}
{synopthdr:Matrices}
{synoptline}
{synopt:{cmd:r(factor_cells)}}factor-level counts when available{p_end}
{synopt:{cmd:r(interaction_cells)}}two-way interaction-cell counts when available{p_end}
{synoptline}

{title:Version and validation}

{pstd}
Version 0.1.6.  The program declares {cmd:version 14.2}.  The release
candidate's public regression suite contains 22 tests covering core metadata,
omitted terms, factor levels and interactions, perfect prediction, VCE
integrity, user-specified thresholds, Cox and Fine-Gray survival metadata,
and compatibility across the built-in binary estimators listed above.

{pstd}
The public suite was run successfully in StataNow under {cmd:version 14.2}
compatibility semantics.  This does not by itself constitute testing on a
separate Stata 14.2 executable.

{title:Author}

{pstd}
Christina Laternser, PhD

{pstd}
{browse "mailto:claternser@luriechildrens.org":claternser@luriechildrens.org}
