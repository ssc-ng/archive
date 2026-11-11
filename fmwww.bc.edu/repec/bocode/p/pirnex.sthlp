{smcl}
{* *! version 2.1.4 08nov2026}{...}
{title:PIRNEX — Pairwise Integral Regression and Neural Effects}

{p 4 4 2}Experimental panel-data pair-difference neural estimation and explanatory ML benchmarks. Research prototype; no established causal interpretation or validated neural-network Wald inference.{p_end}

{title:Syntax}
{p 8 8 2}{cmd:pirnex} {it:y x_cont1 x_cont2 x_binary}, {cmd:id(}{it:idvar}{cmd:)} {cmd:time(}{it:timevar}{cmd:)} [{cmd:folder(}{it:path}{cmd:)} {cmd:boots(}{it:#}{cmd:)} {cmd:epochs(}{it:#}{cmd:)} {cmd:seed(}{it:#}{cmd:)} {cmd:ml} {cmd:explain}]{p_end}
{p 8 8 2}{cmd:pirnex version}{p_end}
{p 8 8 2}{cmd:pirnex report, folder(}{it:path}{cmd:)}{p_end}

{title:Description}
{p 4 4 2}The current prototype requires exactly two continuous predictors followed by one 0/1 predictor. The variables and panel identifiers can be renamed. Observations are split by panel ID into training, validation and test sets. The neural potential is estimated on within-ID response differences with time effects. Low/high effects and conditional 0-to-1 binary contrasts are reported.{p_end}
{p 4 4 2}{cmd:ml} adds XGBoost and explainable boosting machine (EBM) predictive comparisons; {cmd:explain} additionally requests neural integrated gradients and XGBoost TreeSHAP / EBM native-term explanations. XGBoost and EBM are fitted on outcome levels and evaluated on within-ID pairs, so training targets differ from PIRNEX Neural.{p_end}

{title:Options}
{p 4 8 2}{cmd:id(varname)} required numeric individual panel identifier.{p_end}
{p 4 8 2}{cmd:time(varname)} required numeric integer-valued time identifier.{p_end}
{p 4 8 2}{cmd:folder(path)} working/output directory; defaults to a local {it:pirnex_run_v21} directory.{p_end}
{p 4 8 2}{cmd:boots(#)} exploratory cluster bootstrap draws; default 60.{p_end}
{p 4 8 2}{cmd:epochs(#)} maximum neural optimization epochs; default 150.{p_end}
{p 4 8 2}{cmd:seed(#)} seed for model partition and optimization; default 20261108.{p_end}
{p 4 8 2}{cmd:ml} request ML benchmarks; requires Python libraries listed in README.md.{p_end}
{p 4 8 2}{cmd:explain} request explainability; also enables ml.{p_end}

{title:Example}
{p 4 4 2}First change Stata's working directory to the folder containing pirnex.ado and its accompanying Python and Stata helper scripts. See README.md for installation and Python requirements.{p_end}
{phang}{cmd:. webuse nlswork, clear}{p_end}
{phang}{cmd:. pirnex ln_wage tenure hours union, id(idcode) time(year) folder("pirnex_run_v21") boots(0)}{p_end}

{title:Interpretation and limitations}
{p 4 4 2}Test pairwise R-squared is not a conventional level-regression R-squared. Wald chi-squared, z statistics and associated p-values are marked [EXP]: reference distributions have not been established for this neural estimator. Bootstrap confidence intervals are exploratory. The estimated effects and SHAP/IG attributions are not causal.{p_end}
{p 4 4 2}This is not an arbitrary-predictor-count estimator, an SSC release, nor a validated implementation of general nonlinear panel inference. Python dependencies must be accessible to the Python executable invoked by Stata. The prototype expects supporting scripts in the current working directory.{p_end}

{title:Authors and citation}
{p 4 4 2}Authors (in order): Dr. Zehra Yalnız; Prof. Dr. Figen Büyükakın; Sinan Bedir (doctoral student).{p_end}
{p 4 4 2}License: MIT License. Copyright information is in LICENSE.{p_end}
{p 4 4 2}PIRNEX is public experimental research software, not an SSC-accepted package. Cite the repository version or release tag and access date until a formal software publication exists.{p_end}
