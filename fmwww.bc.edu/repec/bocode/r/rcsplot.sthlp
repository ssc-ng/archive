{smcl}
{* *! version 1.0  04oct2026}{...}
{hline}
help for {hi:rcsplot}                                        {right:(Stata 16+)}
{hline}

{title:Title}

{phang}
{hi:rcsplot} -- Restricted cubic spline plot with matched model and plot ranges, optional histogram overlay, shaded confidence band with adjustable opacity, survey support, and outlier trimming

{title:Syntax}

{phang2}
{cmd:rcsplot} {it:command depvar xvar} [{it:covariates}] [{cmd:if}] [{cmd:in}] [{cmd:fw} {cmd:aw} {cmd:pw} {cmd:iw}] [{cmd:,} {it:options}]

{phang}
where {it:command} is one of {cmd:logistic}, {cmd:logit}, {cmd:poisson}, {cmd:stcox}, {cmd:regress}, or {cmd:linear}.

{title:Description}

{phang}
{cmd:rcsplot} fits a restricted cubic spline (RCS) model for a single exposure variable and plots the resulting dose-response curve with a confidence band. By default, the modeled data and the plotted x-range are identical: both are defined by the trim percentile window (1st to 99th percentile of the exposure). This ensures the plot shows exactly the data on which the model was fit, with no gap between the modeled sample and the plotted region.

{phang}
The curve is centered at {cmd:refval()} (the median by default), so the plotted value is exactly 1 (or 0 for linear models) at the reference point. The y-axis is automatically labeled according to the model type: {it:Odds ratio} for logistic, {it:Hazard ratio} for Cox, {it:Rate ratio} for Poisson, and {it:Beta coefficient} for linear.

{phang}
Two P-values are computed and printed in the report block below the plot: {it:P overall} (joint test that all spline terms are zero) and {it:P non-linear} (joint test that all non-linear terms are zero, i.e. a test of departure from linearity). By default, these P-values appear only in the report and not on the plot. Add the {cmd:pvaltext} option to also print them on the figure, or use {cmd:pvalues()} to place them at specific coordinates.

{phang}
The command supports the {cmd:svy} prefix. When {cmd:svyopts(, subpop(...))} is specified, the subpopulation restriction is honored throughout: trimming, knot placement, reference value, x-range, and model fit are all computed on the trimmed subpop. Spline knots are computed on the modeled sample and passed explicitly to {cmd:mkspline}, so the reference basis matches the model basis exactly and the OR is 1 at {cmd:refval()}.

{phang}
When {cmd:ciband} is used, the confidence band is drawn as a shaded area. The opacity of the shaded area can be controlled with {cmd:cibopacity()}, following the Stata convention where 100 means fully opaque and 0 means fully transparent.

{title:Options}

{phang}
{cmd:knots(#)} specifies the number of knots for the restricted cubic spline. Must be between 3 and 7. Default is {cmd:knots(3)}. Knot locations follow Harrell's percentile conventions: 3 knots: 10, 50, 90; 4 knots: 5, 35, 65, 95; 5 knots: 5, 27.5, 50, 72.5, 95; 6 knots: 5, 23, 41, 59, 77, 95; 7 knots: 2.5, 18.33, 34.17, 50, 65.83, 81.67, 97.5.

{phang}
{cmd:refval(#)} specifies the reference value of the exposure at which the curve is centered (i.e. where the OR/HR/beta equals 1 or 0). Default is the median of the exposure, computed on the modeled sample.

{phang}
{cmd:exp(yes|no)} specifies whether to exponentiate the y-axis. Default is {cmd:exp(yes)} for {cmd:logistic}, {cmd:logit}, {cmd:poisson}, and {cmd:stcox}, and {cmd:exp(no)} for {cmd:regress} and {cmd:linear}.

{phang}
{cmd:level(#)} specifies the confidence level, as a percentage, for the confidence intervals. Default is {cmd:level(95)}.

{phang}
{cmd:trim(lo hi)} drops observations with exposure below the {it:lo}-th percentile or above the {it:hi}-th percentile {it:before} fitting the model, and sets the plotted x-range to the same window. Default is {cmd:trim(1 99)}. Use {cmd:trim(none)} (or {cmd:trim(0 100)}) to fit and plot on the full data range. The report block shows the trim setting together with the resulting regression sample size (N).

{phang}
When {cmd:svy} is used with {cmd:svyopts(, subpop(...))}, the trim is applied {it:within} the subpopulation: rows are not dropped (which would break the survey design), but the subpop condition is augmented with the trim bounds and the model, knots, reference, and range are all computed on the trimmed subpop.

{phang}
{cmd:inrange(# #)} explicitly restricts the plotted x-axis to the range [{it:low}, {it:high}]. By default, the plotted x-range equals the trim percentile window, so the model and plot cover the same range. Use {cmd:inrange()} to override this, for example to plot a narrower region than the modeled data. The model is still fit on the trimmed data.

{phang}
{cmd:xtitle(string)} specifies the x-axis title. Default is the variable label of the exposure.

{phang}
{cmd:ytitle(string)} specifies the y-axis (left axis) title. Default depends on the model type (see Description).

{phang}
{cmd:title(string)} specifies the overall plot title.

{phang}
{cmd:notes(string)} adds a note beneath the plot. Enclose multi-word text in double quotes.

{phang}
{cmd:xlabel(...)} specifies the x-axis tick labels. Any valid {cmd:twoway} {cmd:xlabel()} syntax is accepted, for example {cmd:xlabel(50(25)150)} or {cmd:xlabel(, angle(45))}.

{phang}
{cmd:ylabel(...)} specifies the left y-axis tick labels. Any valid {cmd:twoway} {cmd:ylabel()} syntax is accepted, for example {cmd:ylabel(0.5 1 2, angle(0))}. Y-axis labels are formatted with one decimal place by default; override with a {cmd:format()} suboption.

{phang}
{cmd:xscale(...)} specifies the x-axis scale, for example {cmd:xscale(log)}. The {cmd:range()} suboption is added automatically.

{phang}
{cmd:yscale(...)} specifies the left y-axis scale and range. Common forms are {cmd:yscale(log)} for a log scale, {cmd:yscale(range(0.1 4.0))} to force a fixed visible range, and {cmd:yscale(log, range(0.5 2.0))} to combine a log scale with a fixed range.

{phang}
{cmd:pvaltext} displays the two P-values on the figure. By default, the P-values appear only in the report block; add {cmd:pvaltext} to print them on the plot as well. The text is placed automatically in the upper-middle region of the plot.

{phang}
{cmd:pvalues(# # # #)} explicitly specifies the (x, y) coordinates for the two P-value text labels. The order is {cmd:pvalues(x1 y1 x2 y2)}, where (x1, y1) is the position of {it:P overall} and (x2, y2) is the position of {it:P non-linear}. Supplying {cmd:pvalues()} automatically displays the text on the plot, overriding the default of no P-value text.

{phang}
{cmd:name(name)} specifies the name of the graph. Default is {cmd:name(rcsplot, replace)}.

{phang}
{cmd:saving(filename)} saves the graph to disk. Same syntax as {help graph save}.

{phang}
{cmd:lcolor(color)} specifies the color of the main curve. Default is {cmd:black}, or {cmd:eltblue} when {cmd:ciband} is used.

{phang}
{cmd:cicolor(color)} specifies the color of the confidence band lines. Default is {cmd:black}, or {cmd:eltblue} when {cmd:ciband} is used.

{phang}
{cmd:lwidth(style)} specifies the thickness of the main curve. Default is {cmd:lwidth(medthick)}.

{phang}
{cmd:cilwidth(style)} specifies the thickness of the confidence band lines. Default is {cmd:cilwidth(medthin)}.

{phang}
{cmd:histogram} requests a percentage histogram of the exposure on a secondary y-axis (right side). The histogram is restricted to the same range as the curve.

{phang}
{cmd:bins(#)} specifies the number of histogram bins. Default is {cmd:bins(15)}. The number of bins affects the height of the bars and therefore the scale of the secondary y-axis and the density of its tick labels. Fewer bins produce taller bars and a wider axis with sparser labels; more bins produce shorter bars and a denser axis.

{phang}
{cmd:histcolor(color)} specifies the fill color of the histogram bars. Default is {cmd:histcolor(white)} for the standard style and {cmd:histcolor(gs14)} for the Nature Medicine style.

{phang}
{cmd:histytitle(string)} specifies the title for the right y-axis (histogram axis). Default is {cmd:histytitle("Percent")}.

{phang}
{cmd:svy} fits the model under {cmd:svy:} using the current {help svyset} design. Confidence intervals and P-values are survey-adjusted. The histogram is not survey-weighted.

{phang}
{cmd:svyopts(suboptions)} passes suboptions to {cmd:svy}, for example {cmd:svyopts(, subpop(if sex==1))}. When a {cmd:subpop()} suboption is present, the subpop condition is extracted and combined with the trim bounds; the model, knots, reference, and range are all computed on the trimmed subpop.

{phang}
{cmd:ciband} draws the confidence band as a shaded area instead of dashed lines. Implies the Nature Medicine color palette: light blue shaded band with a medium blue effect line, gray histogram, and no grid lines.

{phang}
{cmd:cibcolor(color)} specifies the color of the shaded confidence band. Default is {cmd:cibcolor(ltbluishgray)}. Only used with {cmd:ciband}.

{phang}
{cmd:cibopacity(#)} specifies the opacity of the shaded confidence band as a percentage between 0 and 100, following the Stata convention: 100 is fully opaque (the band hides background elements) and 0 is fully transparent (the band is invisible). Default is 100. Intermediate values, such as {cmd:cibopacity(75)}, let background elements such as the histogram show through the band. Transparency is honored in on-screen graphs and preserved in PDF, SVG, and EMF exports; PNG and some older formats may drop the alpha channel.

{phang}
{cmd:nature} applies the Nature Medicine color palette to the plot {it:without} switching to the shaded band. Useful if you want the palette but keep dashed CI lines.

{phang}
{cmd:debug} prints detailed diagnostic information including the extracted subpop condition, augmented svyopts, trim bounds, knot list, reference value, resolved band color, and a direct check that the OR at the reference equals 1. Use for troubleshooting.

{phang}
{cmd:*} any other option accepted by {cmd:twoway} is passed through unchanged.

{title:Examples}

{phang}
Basic use: model and plot both default to the 1st-99th percentile window. By default, no P-value text appears on the plot; the P-values are printed in the report block below.

{phang2}
{cmd:. webuse nhanes2, clear}

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4)}

{phang}
Same model, but with P-value text shown on the figure:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) pvaltext}

{phang}
Custom reference value:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) refval(100)}

{phang}
Full data (no trimming):

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) trim(none)}

{phang}
Custom trim: 5th and 95th percentiles:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) trim(5 95)}

{phang}
User-supplied inrange() overrides the default range:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) inrange(50 150)}

{phang}
Fixed y-axis range of 0.1 to 4.0, with custom tick marks:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) yscale(range(0.1 4.0)) ylabel(0.1 0.25 0.5 1 2 4, angle(0))}

{phang}
Log scale combined with fixed range:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) yscale(log, range(0.5 2.0)) ylabel(0.5 1 2, angle(0))}

{phang}
With histogram on the secondary y-axis:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) histogram bins(20)}

{phang}
With Nature Medicine shaded CI band:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) ciband}

{phang}
Shaded band at 75% opacity, letting the histogram show through. Note: 100 is fully opaque, 0 is fully transparent, following the Stata convention.

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) histogram bins(20) ciband cibopacity(75)}

{phang}
Shaded band at 50% opacity:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) histogram ciband cibopacity(50)}

{phang}
Full Nature Medicine style with histogram, log y-axis, fixed range, and 75% opacity:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) histogram bins(20) ciband cibopacity(75) yscale(log, range(0.2 4.0)) ylabel(0.25 0.5 1 2 4, angle(0)) histytitle("Percent")}

{phang}
Subgroup analysis with an if clause:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi if age<50, knots(4) histogram ciband}

{phang}
Survey-weighted logistic regression:

{phang2}
{cmd:. svyset psu [pweight=finalwgt], strata(strata)}

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) svy ciband}

{phang}
Survey-weighted with domain (subpopulation) estimation:

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) svy svyopts(, subpop(if age<50)) ciband}

{phang}
Cox proportional hazards model:

{phang2}
{cmd:. stset time, failure(event)}

{phang2}
{cmd:. rcsplot stcox timevar age i.sex bmi, knots(4) ciband}

{phang}
Linear regression with shaded CI:

{phang2}
{cmd:. rcsplot regress bmi zinc age i.sex, knots(4) ciband}

{phang}
Save the graph and export to PDF (preserves transparency):

{phang2}
{cmd:. rcsplot logistic highbp zinc age i.sex bmi, knots(4) histogram ciband cibopacity(75) saving("myplot.gph", replace)}

{phang2}
{cmd:. graph export "myplot.pdf", replace}

{title:Stored results}

{phang}
{cmd:rcsplot} stores the following in {cmd:r()}:

{phang2}
{cmd:r(cmd)} - regression command used

{phang2}
{cmd:r(depvar)} - dependent variable

{phang2}
{cmd:r(xvar)} - exposure variable

{phang2}
{cmd:r(covars)} - covariates

{phang2}
{cmd:r(knotlist)} - knot locations used

{phang2}
{cmd:r(refval)} - reference value

{phang2}
{cmd:r(range_lo)} - lower bound of plotted range

{phang2}
{cmd:r(range_hi)} - upper bound of plotted range

{phang2}
{cmd:r(p_overall)} - P-value for overall association

{phang2}
{cmd:r(p_nonlin)} - P-value for non-linearity

{title:Methods and formulas}

{phang}
The restricted cubic spline basis is generated by {help mkspline} with the {cmd:cubic} option. For knots {it:t}{sub:1} < {it:t}{sub:2} < ... < {it:t}{sub:K}, the basis functions are defined by Harrell's parameterization. The knots are placed at percentiles of the exposure computed on the modeled sample (after any trimming and, when applicable, within the survey subpopulation). The knots are then passed explicitly to {cmd:mkspline} via the {cmd:knots()} suboption, so the spline basis used in the model matches the reference basis used for centering.

{phang}
The centered linear predictor difference from the reference is computed with {help predictnl}:

{phang2}
{it:df} = {it:b}{sub:1}({it:X}{sub:1} - {it:X}{sub:1,ref}) + {it:b}{sub:2}({it:X}{sub:2} - {it:X}{sub:2,ref}) + ...

{phang}
Confidence intervals use the delta method applied to the model's variance-covariance matrix. Under {cmd:svy}, the variance-covariance matrix is the survey-adjusted (linearized) VCE. When {cmd:exp(yes)} is specified, the linear predictor difference is exponentiated so the plotted value is the OR (or HR/RR) relative to the reference.

{phang}
The {it:P overall} test is a joint Wald test that all spline coefficients are zero:

{phang2}
{it:H}{sub:0}: {it:b}{sub:1} = {it:b}{sub:2} = ... = 0

{phang}
The {it:P non-linear} test is a joint Wald test that all non-linear coefficients are zero, i.e. a test of departure from linearity:

{phang2}
{it:H}{sub:0}: {it:b}{sub:2} = {it:b}{sub:3} = ... = 0

{phang}
Model fit statistics: the report block shows AIC and BIC alongside the regression sample size (N). AIC and BIC are computed from the model log-likelihood and the number of estimated parameters. Under {cmd:svy}, if {cmd:e(aic)} and {cmd:e(bic)} are not populated by Stata, they are derived from {cmd:e(ll)} and {cmd:e(k)}. AIC and BIC are only directly comparable between models fitted on the same sample; changing {cmd:trim()} changes the sample and invalidates the comparison.

{phang}
Trimming: by default, observations with exposure below the 1st or above the 99th percentile are dropped before fitting the model, and the plotted x-range is set to the same percentile window. The trimmed sample is used for knot placement, model fitting, P-values, and confidence intervals. This ensures the modeled sample and the plotted region are identical by default. The report block shows the trim setting together with the resulting regression sample size.

{phang}
Under {cmd:svy} with {cmd:svyopts(, subpop(...))}, trimming is applied {it:within} the subpopulation without dropping rows: the subpop condition is augmented with the trim bounds, and the model is fit on the trimmed subpop. This preserves the survey design while still excluding extreme exposure values.

{phang}
Shaded CI band opacity: the {cmd:cibopacity()} option sets the opacity of the shaded band as a percentage, where 100 is fully opaque and 0 is fully transparent. Internally, the user-facing opacity is converted to Stata's transparency convention (transparency = 100 - opacity) and the band color is expanded to an RGB triplet with an alpha channel. Named colors such as {cmd:ltbluishgray} are automatically resolved to their RGB equivalent. Transparency is preserved in PDF, SVG, and EMF exports.

{title:References}

{phang}
Harrell, F. E. 2015. {it:Regression Modeling Strategies}. 2nd ed. New York: Springer.

{phang}
Desquilbet, L., and F. Mariotti. 2010. Dose-response analyses using restricted cubic splines in Cox and logistic regression. {it:Stata Journal} 10(1): 112-138.

{phang}
Orsini, N., and S. Greenland. 2011. A procedure to tabulate and plot results after flexible modeling of a quantitative covariate. {it:Stata Journal} 11(1): 1-29.

{phang}
Marrie, R. A., N. Dawson, and A. Garland. 2009. Quantile regression and restricted cubic splines are useful for exploring relationships between continuous variables. {it:Journal of Clinical Epidemiology} 62(5): 511-517.

{title:Author}

{phang}
Professor Zumin Shi, Qatar University

{phang}
Email: {browse "mailto:zumin.shi@qu.edu.qa":zumin.shi@qu.edu.qa}

{title:Acknowledgments}

{phang}
The author thanks Professor Suhail Doi at Qatar University for his valuable feedback on the development of {cmd:rcsplot}, including suggestions that shaped the default reporting behaviour, the interpretation of opacity, and the formatting of numbers . 

{phang}
Deepseek was used in the development of {cmd:rcsplot}.

{title:Also see}

{phang}
{help mkspline}, {help predictnl}, {help logistic}, {help stcox}, {help poisson}, {help regress}, {help svy}, {help twoway}
