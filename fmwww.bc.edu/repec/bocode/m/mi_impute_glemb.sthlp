{smcl}
{* *! version 0.1.3 23sep2026}{...}
{vieweralsosee "[MI] mi impute" "help mi_impute"}{...}
{vieweralsosee "glemb" "help glemb"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:mi impute glemb}}General location EMB imputation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 19 2}
{cmd:mi} {cmd:impute} {cmd:glemb} {it:ivars}
[{cmd:=} {it:xvars}] {ifin}{cmd:,}
{cmd:noms(}{it:varlist}{cmd:)}
[{cmd:add(}{it:#}{cmd:)}
 {cmd:replace}
 {cmd:rseed(}{it:#}{cmd:)}
 {cmd:catinteract(}{it:#}{cmd:)}
 {cmd:catprior(}{it:#}{cmd:)}
 {cmd:maxits(}{it:#}{cmd:)}
 {cmd:meanmodel(}{it:main|saturated}{cmd:)}
 {cmd:profile}]

{pstd}
Before using {cmd:mi impute glemb}, declare the data with {cmd:mi set} and
register variables to be imputed with {cmd:mi register imputed}.

{title:Description}

{pstd}
{cmd:mi impute glemb} imputes mixed categorical and continuous variables using
the general location model and the EMB algorithm.  It is a multivariate
imputation method: variables on the left side are modeled jointly with any
complete predictors on the right side.

{pstd}
Stata manages the {cmd:mi} storage style, {cmd:add()}, {cmd:replace}, and
{cmd:rseed()}.  The command works with Stata's standard in-memory {cmd:mi}
styles, including {cmd:wide}, {cmd:mlong}, and {cmd:flong}.

{title:Variable placement}

{pstd}
Variables in {it:ivars} must already be registered as {cmd:imputed}.  Any
variable with missing values that should be jointly imputed by {cmd:glemb}
must be placed on the left side.

{pstd}
Variables after the equals sign are complete predictors.  They may be
included in the imputation model, but they are not imputed by this call.
Right-hand-side predictors must be complete in the imputation sample.

{pstd}
Extended missing values ({cmd:.a}-{cmd:.z}) in imputation variables are left
unchanged and are not imputed.  {cmd:mi impute glemb} prints a note when such
values are present.  If all missing values in the imputation variables are
extended missing values, no imputations are added.

{pstd}
Categorical variables with missing values should be listed in {cmd:noms()}.
Complete categorical predictors may also be included in {cmd:noms()}, but this
is optional.  Variables in the model that are not listed in {cmd:noms()} are
treated as continuous.

{title:Options}

{phang}
{cmd:noms(}{it:varlist}{cmd:)} specifies the categorical variables in the
imputation model.  This option is required.

{phang}
{cmd:catinteract(}{it:#}{cmd:)} specifies the maximum order of categorical
interactions in the log-linear model for categorical cell probabilities.  It
must be 2 or 3.  The default is {cmd:catinteract(2)}.

{phang}
{cmd:catprior(}{it:#}{cmd:)} specifies the categorical pseudocount.  If omitted,
the default is {cmd:1 / n_cells}.  Specifying {cmd:catprior(0)} is allowed only
when all possible categorical cells are observed in the imputation sample.

{phang}
{cmd:meanmodel(main)} specifies that the conditional mean model for the
continuous variables includes an intercept and main effects of the categorical
variables.  This is the default.

{phang}
{cmd:meanmodel(saturated)} specifies a separate continuous mean vector for each
categorical cell.  This can be useful for comparisons but may be less stable
and slower with sparse categorical tables.

{phang}
{cmd:maxits(}{it:#}{cmd:)} specifies the maximum number of ECM iterations.
The default is {cmd:maxits(1000)}.

{phang}
{cmd:profile} reports mean timing and E-step row-count diagnostics after
{cmd:mi impute} finishes.

{title:Practical guidance}

{phang}
Place all variables with missing values that should be imputed on the left
side of {cmd:mi impute glemb}.

{phang}
Use the right side only for complete predictors.

{phang}
Include categorical variables with missing values in {cmd:noms()}.  Complete
categorical predictors can optionally be included in {cmd:noms()}, but it is
not essential.

{phang}
Avoid specifying many categorical variables with many levels.  {cmd:glemb}
forms a multiway categorical table and will stop if the table is too large.
Consider combining sparse categories or reducing the number of variables in
{cmd:noms()}.

{phang}
Continuous variables must have at least one observed value and must have
nonzero observed variance.

{phang}
Extended missing values ({cmd:.a}-{cmd:.z}) are treated as hard missing values:
they are left unchanged and are not imputed.  Convert them to ordinary missing
values ({cmd:.}) before imputation if you want {cmd:glemb} to impute them.

{phang}
Imputed continuous values are draws from the fitted multivariate normal model
and can fall outside the observed range.

{title:Examples}

{pstd}
Basic workflow:

{phang2}
{cmd:. mi set wide}

{phang2}
{cmd:. mi register imputed self pov race momwork}

{phang2}
{cmd:. mi register regular anti childage divorce gender momage}

{phang2}
{cmd:. mi impute glemb self pov race momwork = anti childage divorce gender momage, noms(pov race momwork divorce) add(25) rseed(123)}

{phang2}
{cmd:. mi estimate: regress anti self pov i.race childage divorce gender momage momwork}

{pstd}
Using a saturated continuous mean model:

{phang2}
{cmd:. mi impute glemb self pov race momwork = anti childage divorce gender momage, noms(pov race momwork divorce) meanmodel(saturated) add(25) rseed(123)}

{pstd}
Profiling a run:

{phang2}
{cmd:. mi impute glemb self pov race momwork = anti childage divorce gender momage, noms(pov race momwork divorce) add(25) rseed(123) profile}

{title:Stored results}

{pstd}
{cmd:mi impute} stores its usual results.  When {cmd:profile} is specified,
{cmd:glemb} also prints timing diagnostics after the imputation run.

{title:Author}

{pstd}
Paul D. Allison{break}
Statistical Horizons{break}
{browse "mailto:allison@statisticalhorizons.com":allison@statisticalhorizons.com}

{title:Suggested citation}

{pstd}
Allison, P. D. 2026. {it:GLEMB: Stata module for multiple imputation under
the general location model using EMB}. Version 0.1.3.
{browse "https://github.com/pauldallison/glemb-stata"}.

{title:References}

{phang}
Little, R. J. A., and M. D. Schluchter. 1985. Maximum likelihood estimation
for mixed continuous and categorical data with missing values.
{it:Biometrika} 72: 497-512.

{phang}
Olkin, I., and R. F. Tate. 1961. Multivariate correlation models with mixed
discrete and continuous variables. {it:Annals of Mathematical Statistics}
32: 448-465.

{phang}
Rubin, D. B. 1987. {it:Multiple Imputation for Nonresponse in Surveys}.
New York: Wiley.

{title:License}

{pstd}
This software is distributed under the GNU General Public License version 3.

{title:Also see}

{psee}
{helpb glemb}; {helpb mi impute}; {helpb mi estimate}
