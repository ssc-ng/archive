{smcl}
{* *! version 1.2.1  01oct2026}{...}
{vieweralsosee "duvm" "help duvm"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:duvmdiag} {hline 2}}Diagnostics of the unit-value model before estimating it{p_end}
{p2colreset}{...}

{p 4 4 2}{txt}Package {cmd:duvm}, version {res}1.2.1{txt} (01/10/2026) {c |} Stata {res}14.2{txt} or later {c |} first release {res}1.0.0{txt} (24/09/2026){p_end}


{title:Syntax}

{p 8 16 2}
{cmd:duvmdiag} {it:goods} {ifin} [{it:weight}]{cmd:,} {it:duvm_options} [{opt dec(#)}]

{pstd}
The syntax is that of {helpb duvm}; the variance options are ignored.


{title:Description}

{pstd}
{cmd:duvmdiag} runs the two stages of {helpb duvm} without the variance and
reports what will make the price elasticities fragile: goods reported by few
households or in few clusters, clusters too small for the measurement-error
correction, a correction that removes most of the between-cluster variance of
the unit value (little price signal left), negative quality elasticities,
expenditure elasticities near zero (unstable quality parameter), an
ill-conditioned or non-positive corrected moment matrix, and a symmetry
restriction that moves the second-stage coefficients a long way. The same
report is available after estimation with {cmd:estat diagnostics}.

{pstd}
It starts with the coding of the non-buyers (Table D0). A buyer is a household
whose budget share is positive; the table counts, good by good, the buyers, the
budget shares coded missing (read as 0, so that the household stays in the
model), the non-buyers that have a unit value in the data -- imputed, or coded 0
-- and the clusters that have a unit value but no buyer, whose price can only
come from outside the cluster. Each case is also reported as a warning, with
what {helpb duvm##options:nonbuyers()} does with it: imputed unit values bias
the quality elasticity toward zero, the more so the rarer the good.

{pstd}
With {helpb duvm##options:selection}, Table D3 reports how well the correction
of the unit values is identified, good by good: the share of buyers, the
McFadden pseudo-R2 of the probit of purchase, the households it predicts with
probability 0 or 1 (separation: the coefficients of the separating variables
drift, the Mills ratio does not), the variance inflation factor of the
quality elasticity due to the Mills ratio, 1/(1-rho^2) with rho the
within-cluster correlation of the Mills ratio and log expenditure given the
other regressors among the reporters, and the number of probit-only variables;
after estimation, also the coefficient of the Mills ratio and its z. A factor
above 10 means that the Mills ratio is almost collinear with log expenditure:
the quality elasticity then rests on the curvature of the probit, and the
linearized standard errors of the good understate its uncertainty; the warning
recommends leaving the good uncorrected with {opt selgoods()}, an exclusion
variable in {opt selvars()}, or at least {cmd:vce(bootstrap)}.


{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(N_warn)}}number of warnings{p_end}
{synopt:{cmd:r(cond_Sf)}}condition number of the corrected moment matrix{p_end}
{synopt:{cmd:r(mineig_Sf)}}its smallest eigenvalue{p_end}
{synopt:{cmd:r(sym_dist)}}||B_sym - B|| / ||B||{p_end}
{synopt:{cmd:r(sel_diag)}}Table D3 ({opt selection}): buyers, % buyers, pseudo-R2, perfectly predicted, variance inflation factor of the quality elasticity{p_end}


{title:Example}

{phang2}{cmd:. use mexico_2014_cereals, clear}{p_end}
{phang2}{cmd:. duvmdiag corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) cluster(psu) region(rururb) indcat(sex educ) indcon(age)}{p_end}
{p 8 8 2}{txt}({stata "duvm_examples 9":example 9: click to run in command window}){p_end}
{p 8 8 2}{txt}({stata "duvm_examples 9, do":open as a do-file}){p_end}

{pstd}With the diagnostic of the selection correction (Table D3){p_end}
{phang2}{cmd:. duvmdiag corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) cluster(psu) region(rururb) indcat(sex educ) indcon(age) selection}{p_end}
{p 8 8 2}{txt}({stata "duvm_examples 5":example 5: click to run in command window}){p_end}
{p 8 8 2}{txt}({stata "duvm_examples 5, db":click to run in dialog box}){p_end}
{p 8 8 2}{txt}({stata "duvm_examples 5, do":open as a do-file}){p_end}


{title:Author}

{pstd}Abdelkrim Araar, Universit{c e'} Laval / PEP, aabd@ecn.ulaval.ca{p_end}
