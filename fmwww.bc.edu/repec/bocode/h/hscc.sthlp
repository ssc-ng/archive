{smcl}
{* *! hscc 1.0.2 28sep2026}{...}

{title:Title}

{phang}
{bf:hscc} {hline 2} Heterogeneous-Slope SCC estimator with joint partial pooling,
optional common time fixed effects, and HC3-adjusted Driscoll-Kraay inference


{title:Syntax}

{p 8 17 2}
{cmd:hscc} {depvar} {indepvars} {ifin}
[{cmd:,} {opt lag(#)} {opt timefe}]


{title:Description}

{pstd}
{cmd:hscc} estimates a heterogeneous-slope panel model in which unit-specific
slopes are decomposed into a central slope, systematic heterogeneity related to
unit-level regressor means, and residual unit-specific slope deviations.

{pstd}
The residual slope deviations are jointly estimated under a quadratic penalty
derived from the estimated residual slope covariance matrix. The final
covariance matrix uses HC3-adjusted observation scores aggregated across units
by time and a Bartlett Driscoll-Kraay HAC estimator.

{pstd}
Version 1.0.2 adds the optional {cmd:timefe} specification. When requested,
common time effects are partialled out from the complete joint HSCC design.
These time effects are treated as common nuisance components and are kept
outside the heterogeneous-slope and penalty blocks. Recovered centered common
time effects are displayed and stored in {cmd:e(timefe_b)}.

{pstd}
The data must be {cmd:xtset} before estimation. Version 1.0.2 requires a
strongly balanced estimation sample.


{title:Model}

{pstd}
The slope structure is

{p 8 8 2}
beta_i = beta + Gamma z_i + eta_i,

{pstd}
where beta is the central/average slope vector, z_i contains centered unit
means of the regressors, and eta_i is residual slope heterogeneity subject to

{p 8 8 2}
sum_i eta_i = 0.

{pstd}
The joint estimator minimizes the within-transformed residual sum of squares
plus a quadratic penalty on eta_i.

{pstd}
With {cmd:timefe}, the empirical specification additionally controls for
common additive time effects,

{p 8 8 2}
y_it = alpha_i + lambda_t + x_it'beta_i + u_it,

{pstd}
where lambda_t denotes the common time effect. The time effects are partialled
out using an FWL-equivalent transformation and are not treated as heterogeneous
slope parameters. Reported time effects use a centered mean-zero normalization.


{title:Options}

{phang}
{opt lag(#)} sets the maximum Bartlett HAC lag. If omitted, {cmd:hscc} uses

{p 12 12 2}
floor(4*(T/100)^(2/9))

{pstd}
with a minimum of 1.

{phang}
{opt timefe} adds common time fixed effects by partialling them out from the
complete joint HSCC design. Time effects are treated as common nuisance
components and are kept outside the heterogeneous-slope and penalty blocks.
Recovered centered common time effects are stored in {cmd:e(timefe_b)}.


{title:Examples}

{phang2}{cmd:. xtset i time}

{phang2}{cmd:. hscc GGI lnREC lnT GPATDE FD}

{phang2}{cmd:. hscc GGI lnREC lnT GPATDE FD, lag(2)}

{phang2}{cmd:. hscc GGI lnREC lnT GPATDE FD, timefe}

{phang2}{cmd:. hscc GGI lnREC lnT GPATDE FD, timefe lag(2)}


{title:Stored results}

{pstd}
{cmd:hscc} stores the following in {cmd:e()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:e(b)}}HSCC central slope estimates{p_end}
{synopt:{cmd:e(V)}}HC3 Driscoll-Kraay covariance matrix{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panel units{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(lag)}}DK/HAC lag{p_end}
{synopt:{cmd:e(df_r)}}T-1 degrees of freedom used for inference{p_end}
{synopt:{cmd:e(heterogeneity_trace)}}trace of the estimated residual slope covariance{p_end}
{synopt:{cmd:e(r2_w)}}descriptive HSCC within R-squared{p_end}
{synopt:{cmd:e(mg_b)}}conventional mean-group point-estimate benchmark{p_end}
{synopt:{cmd:e(timefe)}}nonempty when common time fixed effects are requested{p_end}
{synopt:{cmd:e(timefe_b)}}recovered centered common time effects when {cmd:timefe} is used{p_end}
{synopt:{cmd:e(timefe_normalization)}}normalization used for recovered time effects{p_end}


{title:Remarks}

{pstd}
The methodological contribution of HSCC is in the point-estimation layer.
Driscoll-Kraay / SCC is retained as the inference framework.

{pstd}
The version 1.0.2 covariance is a first-order HC3-DK approximation. Monte Carlo
validation for the motivating N=31, T=20 design indicated mild small-T
undercoverage. Results close to conventional significance thresholds should
therefore be interpreted with appropriate caution.

{pstd}
The {cmd:timefe} option is an extension of the empirical specification rather
than a separate estimator.

{pstd}
The estimator is not tuned to preserve statistical significance.


{title:Version}

{pstd}
HSCC 1.0.2, 28 September 2026.
