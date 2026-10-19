{smcl}
{* *! version 1.0.0  12oct2026}{...}
{vieweralsosee "xtdyncce" "help xtdyncce"}{...}
{vieweralsosee "xtgcce" "help xtgcce"}{...}
{vieweralsosee "xtdyngcce methods" "help xtdyngcce_methods"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{viewerjumpto "Description" "xtdyngcce##description"}{...}
{viewerjumpto "Which command do I need?" "xtdyngcce##which"}{...}
{viewerjumpto "Commands" "xtdyngcce##commands"}{...}
{viewerjumpto "Quick start" "xtdyngcce##quick"}{...}
{viewerjumpto "Relation to other packages" "xtdyngcce##relation"}{...}
{viewerjumpto "References" "xtdyngcce##references"}{...}
{viewerjumpto "Author" "xtdyngcce##author"}{...}

{title:Title}

{phang}
{bf:xtdyngcce} {hline 2} Bootstrap and generalized inference for panel data
models with common correlated effects


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdyngcce} is a package of two estimation commands for panel data models
with unobserved common factors (interactive fixed effects). Both extend the
Common Correlated Effects (CCE) framework of
{help xtdyngcce##P2006:Pesaran (2006)}, in two different directions:

{p 6 10 2}
{bf:{helpb xtdyncce}} {hline 1} {it:dynamic, pooled.} Fits the CCEP estimator
with a lagged dependent variable and provides the recursive-design wild
bootstrap of {help xtdyngcce##JST2026:Juodis, Stauskas and Tromp (2026)},
together with three bias corrections for the Nickell bias (half-panel
jackknife, analytical, and fixed-T minimum distance).

{p 6 10 2}
{bf:{helpb xtgcce}} {hline 1} {it:static, heterogeneous.} Fits the Generalized
CCE mean-group estimator of {help xtdyngcce##LSB2026:Lu, Su and Ba (2026)},
which augments the regression with the time-series averages of the regressors
and remains consistent even when the CCE rank condition fails.

{pstd}
{helpb xtdyngcce_methods:help xtdyngcce methods} documents the derivations and
the step-by-step map from each block of code to the equation it implements.


{marker which}{...}
{title:Which command do I need?}

{pstd}
Answer three questions about your model.

{synoptset 34}{...}
{synopthdr:Question}
{synoptline}
{synopt:Is there a lagged dependent variable?}{p_end}
{p 8 12 2}yes {c -} {helpb xtdyncce}{break}
no {space 2}{c -} go on{p_end}
{synopt:Are the slopes the same across units?}{p_end}
{p 8 12 2}yes, pooled {space 4}{c -} {helpb xtdyncce} with {cmd:lags(0)}{break}
no, heterogeneous {c -} {helpb xtgcce}{p_end}
{synopt:Might the rank condition fail?}{p_end}
{p 8 12 2}yes {c -} {helpb xtgcce} (it is robust to this){break}
no {space 2}{c -} either; they agree asymptotically{p_end}
{synoptline}

{pstd}
{bf:The two commands are not substitutes.} They implement different
estimators under different assumptions:

{p2colset 8 30 32 2}{...}
{p2col :}{bf:xtdyncce}{space 8}{bf:xtgcce}{p_end}
{p2col :Slopes}pooled, homogeneous{space 4}heterogeneous, mean group{p_end}
{p2col :Dynamics}yes{space 20}no (excluded by the theory){p_end}
{p2col :Augmentation}zbar(t) and its lags{space 3}zbar(t) and xbar(i){p_end}
{p2col :Rank condition}assumed to hold{space 8}allowed to fail{p_end}
{p2col :Inference}wild bootstrap{space 9}leave-one-out jackknife{p_end}
{p2col :Asymptotics}N,T large, N/T -> kappa{space 0}N,T large{p_end}
{p2colreset}{...}

{pstd}
A {it:dynamic GCCE} estimator - heterogeneous slopes, a lagged dependent
variable {bf:and} robustness to rank failure - does not exist in either source
paper. Lu, Su and Ba name it explicitly as future research and call it "highly
challenging". This package therefore does not provide one.


{marker commands}{...}
{title:Commands}

{p2colset 5 22 24 2}{...}
{p2col :{helpb xtdyncce}}Dynamic CCE with recursive-design wild bootstrap{p_end}
{p2col :{helpb xtgcce}}Generalized CCE mean-group estimation{p_end}
{p2col :{helpb xtdyngcce_methods:xtdyngcce methods}}Derivations and the step-to-equation map{p_end}
{p2colreset}{...}


{marker quick}{...}
{title:Quick start}

{pstd}Declare the panel{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Dynamic model, the recommended procedure{p_end}
{phang2}{cmd:. xtdyncce y x, biasadj(hpj) vce(rdwb) reps(399) dreps(199) seed(1)}{p_end}

{pstd}Static heterogeneous model, with the CCE comparison{p_end}
{phang2}{cmd:. xtgcce y x, cce}{p_end}

{pstd}Run the shipped worked example with known true parameters{p_end}
{phang2}{cmd:. net get xtdyngcce}{p_end}
{phang2}{cmd:. do xtdyngcce_example.do}{p_end}


{marker relation}{...}
{title:Relation to other packages}

{pstd}
{cmd:xtdyngcce} is designed to sit beside, not replace,
{helpb xtdcce2} (Ditzen). Use {cmd:xtdcce2} for CCEP and CCEMG point
estimation, recursive mean adjustment, regularized CCE, the information
criteria for selecting averages, and the cross-section (pairs) bootstrap. Use
this package for what {cmd:xtdcce2} does not provide:

{p 6 8 2}
{bf:o} the recursive-design wild bootstrap. {cmd:xtdcce2}'s
{cmd:estat bootstrap, wild} rescales residuals by 1/(1-h) and resamples them;
it does {bf:not} regenerate y recursively and does {bf:not} re-estimate the
cross-section averages from the bootstrap data. Both are required by the
theory implemented here, so the two are different procedures.

{p 6 8 2}
{bf:o} the Moon-Weidner analytical correction and the De Vos-Everaert fixed-T
correction applied to CCEP.

{p 6 8 2}
{bf:o} the leave-one-out jackknife in which the cross-section averages are
{bf:also} recomputed without unit i. A general-purpose cluster jackknife such
as {cmd:summclust} deletes a cluster from the regression but leaves the
averages unchanged, which is a different estimator.

{p 6 8 2}
{bf:o} the iterated (double) bootstrap used for studentization.

{p 6 8 2}
{bf:o} the generalized CCE estimator; no Stata command adds the time-series
averages xbar(i) in a CCE context.

{pstd}
Useful companions: {helpb xtcd2} (CD test), {helpb xtcse2} (exponent of
cross-sectional dependence), {helpb xtnumfac} (number of factors),
{helpb xtspj} (split-panel jackknife for fixed-effect models, no factors),
{helpb regife} (principal-components interactive fixed effects).

{pstd}
{bf:Caution.} {cmd:xtdcce2}'s rank-condition classifier
({cmd:cr(..., rcclassifier)}) and its regularized CCE option
({cmd:cr(..., rcce)}) are {bf:static-only}. On a dynamic panel they print a
note, ignore themselves, and still return a zero return code. Do not rely on
the return code to tell you whether they ran.


{marker references}{...}
{title:References}

{marker JST2026}{...}
{phang}
Juodis, A., O. Stauskas, and S. Tromp. 2026. Bootstrap inference for dynamic
panel data models with common correlated effects. arXiv:2609.31442 [econ.EM].
{browse "https://arxiv.org/abs/2609.31442"}

{marker JR2026}{...}
{phang}
Juodis, A., and S. Reese. 2026. Five lessons for applied researchers from
twenty years of common correlated effects estimation.
{it:Journal of Econometrics} 253: 106120.
{browse "https://doi.org/10.1016/j.jeconom.2025.106120"}

{marker LSB2026}{...}
{phang}
Lu, X., L. Su, and Y. Ba. 2026. On generalized CCE estimation.
{it:Journal of Econometrics} 253: 106183.
{browse "https://doi.org/10.1016/j.jeconom.2026.106183"}

{marker P2006}{...}
{phang}
Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels
with a multifactor error structure. {it:Econometrica} 74(4): 967-1012.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00692.x"}

{pstd}
Full reference lists appear on the individual command pages and in
{helpb xtdyngcce_methods:help xtdyngcce methods}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
