{smcl}
{* *! version 1.0.0  25oct2026}{...}
{viewerjumpto "Syntax" "xtcollin##syntax"}{...}
{viewerjumpto "Description" "xtcollin##description"}{...}
{viewerjumpto "Options" "xtcollin##options"}{...}
{viewerjumpto "Remarks" "xtcollin##remarks"}{...}
{viewerjumpto "Stored results" "xtcollin##results"}{...}
{viewerjumpto "Examples" "xtcollin##examples"}{...}
{viewerjumpto "References" "xtcollin##references"}{...}
{title:Title}

{p 4 8 2}
{bf:xtcollin} {hline 2} Collinearity diagnostics for the design an estimator actually uses:
pooled, within, two-way, first-difference, random-effects, between, CCE, and unit by unit


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}After an estimation command ({helpb xtreg}, {helpb regress}, {helpb areg}, {cmd:xtdcce2}, ...)

{p 8 16 2}
{cmd:xtcollin} [{cmd:,} {it:options}]

{p 4 8 2}For a list of regressors

{p 8 16 2}
{cmd:xtcollin} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt tr:ansform(name)}}{cmd:none}, {cmd:within}, {cmd:twoway}, {cmd:fd}, {cmd:quasi}, {cmd:between} or
{cmd:cce}; default from the last estimation, else {cmd:within} for panel data{p_end}
{synopt:{opt th:eta(#)}}quasi-demeaning factor for {cmd:transform(quasi)}; taken from {cmd:xtreg, re} by
default{p_end}
{synopt:{opt cce:vars(varlist)}}variables whose cross-section averages are partialled out with
{cmd:transform(cce)}; default the dependent variable and the regressors{p_end}
{synopt:{opt unit:s}}unit-by-unit VIFs and condition numbers{p_end}
{synopt:{opt vdp}}variance-decomposition proportions{p_end}
{synopt:{opt noc:onstant}}no intercept in the untransformed design{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
{it:indepvars} may contain factor variables and time-series operators.


{marker description}{...}
{title:Description}

{p 4 4 2}
Variance inflation factors (VIFs) and condition numbers computed on the raw data, as by
{cmd:estat vif} after {cmd:regress}, describe the design of a pooled regression. A panel
estimator uses a transformed design: fixed effects remove unit means, the two-way model also
period means, first differences remove levels, random effects remove a fraction theta of the unit
means, and CCE removes the cross-section averages unit by unit. Mean-group and CCE estimators run
one regression per unit, whose designs can be far more collinear than the pooled one. The raw
diagnostics can therefore miss collinearity that inflates the variances of the estimates, or
flag collinearity that the transformation removes.

{p 4 4 2}
{cmd:xtcollin} reports, for the transformed design: VIFs, the condition number and condition
indices with the variance-decomposition proportions of Belsley, Kuh and Welsch (1980); for panel
data, the share of each regressor's variance that is within units, which shows regressors that are
nearly constant over time and so are identified by little variation under fixed effects; and,
with {opt units}, the VIFs and condition numbers of every unit regression, summarized by their
median, maximum and the share of units above the usual thresholds.


{marker options}{...}
{title:Options}

{phang}{opt transform(name)} chooses the transformation. After {cmd:xtreg, fe} it is {cmd:within},
after {cmd:xtreg, re} {cmd:quasi}, after {cmd:xtreg, be} {cmd:between}, after {cmd:xtdcce2} or
{cmd:xtutest} {cmd:cce}, after {cmd:areg} and {cmd:reghdfe} {cmd:within}.
{cmd:twoway} removes unit and period means (alternating projections, valid for unbalanced
panels).

{phang}{opt theta(#)} sets theta for {cmd:transform(quasi)}; after {cmd:xtreg, re} the stored value is
used (its median when it varies across units).

{phang}{opt ccevars(varlist)} sets the variables whose period averages are partialled out.

{phang}{opt units} adds the unit-by-unit diagnostics: with {cmd:transform(cce)} the averages are
partialled out of each unit's regressors; otherwise each unit's regressors with an intercept, the
design of the mean-group estimator. Use {cmd:matrix list r(units)} for the values.

{phang}{opt vdp} lists the variance-decomposition proportions.

{phang}{opt noconstant} omits the intercept from the untransformed design.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
Rules of thumb: a VIF above 10, or a condition index above 30 with two or more
variance-decomposition proportions above 0.5 in its row, signals collinearity that can harm
estimation (Belsley, Kuh and Welsch 1980). They are conventions, not tests. Collinearity matters
through the standard errors it produces, which should be read together with these diagnostics.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:xtcollin} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(N_tr)}}rows of the transformed design{p_end}
{synopt:{cmd:r(cn_raw)}, {cmd:r(cn_tr)}}condition numbers of the raw and transformed designs{p_end}
{synopt:{cmd:r(theta)}}theta (quasi){p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(transform)}}transformation{p_end}
{synopt:{cmd:r(varlist)}}regressors{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(vif)}}VIFs of the raw and transformed designs{p_end}
{synopt:{cmd:r(ci)}}condition indices{p_end}
{synopt:{cmd:r(vdp)}}variance-decomposition proportions{p_end}
{synopt:{cmd:r(within_share)}}within-unit share of each regressor's variance{p_end}
{synopt:{cmd:r(units)}}unit id, condition number, VIFs (with {opt units}){p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use xtcsddiag_apec, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. generate lnEF = ln(EF)}{p_end}
{phang2}{cmd:. generate NET2 = NET^2}{p_end}
{phang2}{cmd:. xtreg lnEF NET NET2 GLB, fe}{p_end}
{phang2}{cmd:. xtcollin, vdp}{p_end}
{phang2}{cmd:. xtcollin NET NET2 GLB, transform(twoway)}{p_end}
{phang2}{cmd:. xtcollin NET NET2 GLB, transform(cce) ccevars(lnEF NET NET2 GLB) units}{p_end}
{phang2}{cmd:. xtcollin NET NET2 GLB, transform(none) units}{p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Belsley, D. A., E. Kuh, and R. E. Welsch. 1980.
{it:Regression Diagnostics: Identifying Influential Data and Sources of Collinearity}. New York: Wiley.{p_end}
{p 4 8 2}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error
structure. {it:Econometrica} 74: 967-1012.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb xtcsddiag}, {helpb xtcdmax} (same package), {helpb estat vif}{p_end}
