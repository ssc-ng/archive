{smcl}
{* *! xtxai help revision 06nov2026}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}

{title:Title}

{pstd}
{bf:xtxai} {hline 2} Explainability tools for Stata
estimation and machine-learning models.

{title:Syntax}

{pstd}
Linear PSSA after {cmd:regress} or {cmd:xtreg, fe/re}:

{phang2}
{cmd:xtxai, model(pssa) explain(linear)}
{cmd:vars(}{it:varlist}{cmd:)}
{cmd:id(}{it:panelvar}{cmd:)}
{cmd:background(pooled|unit|factor)}
[{cmd:factor(}{it:varname}{cmd:)}
{cmd:prefix(}{it:name}{cmd:)} {cmd:replace}]

{pstd}
Fitted machine-learning model and reference-game Shapley:

{phang2}
{cmd:xtxai} {it:depvar indepvars}{cmd:,}
{cmd:model(xgboost|ebm) explain(pssa)}
{cmd:holdout(}{it:time}{cmd:)}
{cmd:id(}{it:panelvar}{cmd:)}
{cmd:background(pooled|unit)}
[{cmd:prefix(}{it:name}{cmd:)} {cmd:replace}]

{pstd}
Plain machine-learning estimation:

{phang2}
{cmd:xtxai} {it:depvar indepvars}{cmd:,}
{cmd:model(xgboost|ebm|randomforest)}
{cmd:holdout(}{it:time}{cmd:)}

{pstd}
Previously estimated-model adapters:

{phang2}
{cmd:xtxai, model(fe|re)}

{phang2}
{cmd:xtxai, model(xtscc) explain(within|linear) replace}

{phang2}
{cmd:xtxai, model(mg) explain(full) replace}

{phang2}
{cmd:xtxai, model(amg) explain(full) replace}

{phang2}
{cmd:xtxai, model(pmg) explain(dynamic)}
[{cmd:prefix(}{it:name}{cmd:)} {cmd:replace}]

{phang2}
{cmd:xtxai, model(csardl) explain(partial)}
{cmd:id(}{it:panelvar}{cmd:)}
[{cmd:prefix(}{it:name}{cmd:)} {cmd:replace}]

{title:Description}

{pstd}
{cmd:xtxai} provides estimator-specific tools for
explaining predictions and linear-index contributions
in econometric and machine-learning models.

{pstd}
The command connects traditional econometric analysis
with explainable artificial intelligence methods.

{pstd}
Supported explanation mechanisms differ across models.
All explanations are observational and do not establish
causal relationships.

{pstd}
Some model adapters remain development-stage features.
Their availability depends on the installed ado version.

{title:Linear PSSA}

{pstd}
The {cmd:model(pssa) explain(linear)} mode computes
interventional Shapley contributions for a fixed
linear prediction index.

{pstd}
Contributions are evaluated relative to an explicitly
selected reference distribution.

{phang}
{cmd:background(pooled)} uses the overall sample mean.

{phang}
{cmd:background(unit)} uses panel-specific means.

{phang}
{cmd:background(factor)} uses an observed factor
and an in-sample projection.

{pstd}
The factor reference does not identify an unobserved
latent common factor.

{pstd}
For fixed-effects models, linear-index explanations
exclude the fitted unit-specific effects.

{title:Machine-learning explanations}

{pstd}
For XGBoost and Explainable Boosting Machine models,
{cmd:explain(pssa)} evaluates an empirical
interventional reference game.

{pstd}
The background distribution is constructed using
training observations only.

{pstd}
The current reference-game implementation supports
a maximum of five explanatory variables.

{pstd}
Available reference schemes are pooled and
panel-unit-specific backgrounds.

{pstd}
These explanations differ from conventional
XGBoost Tree SHAP values and EBM term decompositions.

{title:Options}

{phang}
{cmd:model()} selects the estimator-specific adapter.

{phang}
{cmd:explain()} selects the explanation mechanism.

{phang}
{cmd:vars()} specifies explanatory variables
for linear PSSA decomposition.

{phang}
{cmd:id()} identifies the panel variable.

{phang}
{cmd:background()} selects the reference distribution.

{phang}
{cmd:factor()} specifies an observed factor variable
for linear PSSA factor-based references.

{phang}
{cmd:holdout()} specifies the time threshold
used for machine-learning evaluation.

{phang}
{cmd:prefix()} specifies the prefix of generated
output variables.

{phang}
{cmd:replace} allows existing output variables
to be overwritten.

{title:Examples}

{pstd}
Example 1: Linear PSSA with the Grunfeld dataset.

{phang2}{cmd:. webuse grunfeld, clear}

{phang2}{cmd:. xtset company year}

{phang2}{cmd:. regress invest mvalue kstock}

{phang2}
{cmd:. xtxai, model(pssa) explain(linear)}
{cmd:vars(mvalue kstock) id(company)}
{cmd:background(unit) prefix(pu) replace}

{pstd}
Example 2: XGBoost reference-game explanation.

{phang2}
{cmd:. xtxai invest mvalue kstock, model(xgboost)}
{cmd:explain(pssa) holdout(1950) id(company)}
{cmd:background(pooled) prefix(xp) replace}

{pstd}
Example 3: EBM reference-game explanation.

{phang2}
{cmd:. xtxai invest mvalue kstock, model(ebm)}
{cmd:explain(pssa) holdout(1950) id(company)}
{cmd:background(unit) prefix(xe) replace}

{title:PMG dynamic decomposition}

{pstd}
The {cmd:model(pmg) explain(dynamic)} adapter
reads short-run terms from the stored coefficient
names of a previously estimated {cmd:xtpmg} model.

{pstd}
Panel identifiers are matched with stored
unit-specific coefficient rows.

{pstd}
The estimator's error-correction term is
reconstructed using named long-run coefficients.

{pstd}
Unsupported normalizations and ambiguous panel
mappings are rejected rather than inferred.

{pstd}
Reported StataNow 19 verification includes:

{phang}
ARDL(1,1,1)

{phang}
ARDL(2,1,1)

{phang}
ARDL(2,2,1)

{phang}
ARDL(3,2,1,2)

{phang}
Unbalanced ARDL(2,2,1,1)

{pstd}
These tests do not guarantee compatibility with
every lag order, normalization convention,
or {cmd:xtpmg} implementation.

{pstd}
ECM term products are not Shapley values.

{title:CS-ARDL limited scope}

{pstd}
The {cmd:model(csardl) explain(partial)} adapter
provides a guarded five-term observed dynamic index
for the tested two-regressor configuration.

{pstd}
It does not reconstruct the complete fitted value.

{pstd}
Cross-sectional averages, partialled-out components,
heterogeneous constants, and latent common factors
are not attributed by this adapter.

{pstd}
Panel identifiers outside the numerical sequence
1 through G are rejected.

{title:Stored results}

{pstd}
PSSA modes return the following results in {cmd:r()}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(N)}}Number of observations{p_end}
{synopt:{cmd:r(maxgap)}}Maximum reconstruction gap{p_end}

{pstd}
Other adapters provide model-specific stored results.

{pstd}
Use {cmd:return list} after execution to inspect
the available returned results.

{title:Requirements}

{pstd}
The supplied development tests used StataNow 19.

{pstd}
The Python bridge and associated test scripts
require Stata 17 or later.

{pstd}
Machine-learning execution requires a working
Stata Python environment with the relevant packages:

{phang}
numpy, pandas, xgboost, scikit-learn, shap,
and interpret.

{pstd}
Additional econometric commands must be installed
separately when their adapters are used.

{phang}
These include {cmd:xtpmg}, {cmd:xtdcce2},
{cmd:xtmg}, and {cmd:xtscc}.

{title:Limitations}

{pstd}
This documentation describes development-stage
capabilities of the XTXAI framework.

{pstd}
Panel-aware Shapley methodological novelty,
out-of-sample robustness, complete coverage
of econometric model families, and end-to-end
reproducibility remain subject to further validation.

{pstd}
Users should verify feature availability against
the specific installed ado version.

{title:Author}

{pstd}
Dr. Zehra Yalnız

{pstd}
XTXAI is listed in the SSC archive.

{pstd}
This help file describes a development candidate.

{pstd}
Not all documented features are necessarily
available in the SSC-distributed version.
