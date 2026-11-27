{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "xtqqr" "help xtqqr"}{...}
{vieweralsosee "xtqqkrls" "help xtqqkrls"}{...}
{vieweralsosee "xtqqr methods" "help xtqqr_methods"}{...}
{viewerjumpto "Syntax" "xtqqplot##syntax"}{...}
{viewerjumpto "Description" "xtqqplot##description"}{...}
{viewerjumpto "Options" "xtqqplot##options"}{...}
{viewerjumpto "Examples" "xtqqplot##examples"}{...}
{viewerjumpto "Author" "xtqqplot##author"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:xtqqplot} {hline 2}}Graphs after xtqqr and xtqqkrls{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtqqplot} [{cmd:,} {it:type} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr:type}
{synoptline}
{synopt:{opt heat:map}}tile heatmap of the surface (default){p_end}
{synopt:{opt cont:our}}smoothed contour map (thin-plate spline){p_end}
{synopt:{opt slic:es}}effect curves with confidence bands for selected theta (or tau){p_end}
{synopt:{opt val:idate}}panel QR slope with its band vs the theta-averaged QQ slope (after {cmd:xtqqr, validate}){p_end}
{synopt:{opt ame}}KRLS average effect by theta-regime with confidence intervals (after {cmd:xtqqkrls}){p_end}
{synoptline}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt v:alue(name)}}surface to map: {cmd:coef} (default), {cmd:p}, {cmd:t}, {cmd:se} or {cmd:r2}{p_end}
{synopt:{opt color:map(name)}}{cmd:parula} (MATLAB, default), {cmd:bwr} (blue-white-red, centred at 0) or {cmd:jet}{p_end}
{synopt:{opt nb:ins(#)}}number of colour classes in the heatmap; default {cmd:16}{p_end}
{synopt:{opt values}}print the value and stars in each cell{p_end}
{synopt:{opt comb:ine}}heatmap of the coefficients and of the p-values side by side{p_end}
{synopt:{opt lev:els(#)}}colour levels of the contour map; default {cmd:24}{p_end}
{synopt:{opt sig:mark}}mark cells with p < {opt alpha()} on the contour map{p_end}
{synopt:{opt al:pha(#)}}significance level for bands and marks; default {cmd:0.05}{p_end}
{synopt:{opt at(numlist)}}theta (or tau) values of the slices; default {cmd:0.1 0.5 0.9}{p_end}
{synopt:{opt over(theta|tau)}}slices at fixed theta (default) or at fixed tau{p_end}
{synopt:{opt ti:tle(string)}}graph title{p_end}
{synopt:{opt sub:title(string)}}subtitle (added to the note of a single heatmap){p_end}
{synopt:{opt name(name)}}graph name{p_end}
{synopt:{opt sav:ing(filename[, options])}}export the graph; PNG/TIF/JPG default to 2200 pixels wide{p_end}
{synopt:{opt sch:eme(name)}}graph scheme for contour, slices, validate and ame{p_end}
{synopt:{opt nodraw}}do not display the graph{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqqplot} draws the results left in {cmd:e()} by {helpb xtqqr} or
{helpb xtqqkrls}.

{pstd}
The default heatmap draws one exact tile per (tau, theta) pair, with
quantiles of the dependent variable (tau) on the horizontal axis,
quantiles of the QQ regressor (theta) on the vertical axis, white cell
borders, a colour bar and the significance stars (*** p<0.01, ** p<0.05,
* p<0.10) printed inside the tiles. Cells that were not estimated stay
white. The default colour map is MATLAB's Parula.


{marker options}{...}
{title:Options}

{phang}
{opt value(name)} chooses what to map. {cmd:p} maps the p-values on
[0, 1]; {cmd:r2} the kernel-weighted pseudo R-squared ({cmd:xtqqr} only).

{phang}
{opt colormap(bwr)} is centred at zero (symmetric scale), which shows the
sign of the effect at a glance. {cmd:parula} and {cmd:jet} span the
observed range.

{phang}
{opt values} prints the value of each cell with its stars; best on grids
up to about 11 x 11.

{phang}
{opt combine} puts the coefficient heatmap and the p-value heatmap side by
side in one figure.

{phang}
{opt slices} draws b(tau, theta) against tau for the theta values in
{opt at()} (nearest grid points), with pointwise
(1-{opt alpha()}) confidence bands. {cmd:over(tau)} draws them against
theta for fixed tau instead.

{phang}
{opt saving()} accepts any {helpb graph export} file name and options,
for example {cmd:saving("fig3.png", replace)}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xtqqr y x z, validate}{p_end}
{phang2}{cmd:. xtqqplot}{p_end}
{phang2}{cmd:. xtqqplot, heatmap colormap(bwr)}{p_end}
{phang2}{cmd:. xtqqplot, heatmap combine saving("qq_y_x.png", replace)}{p_end}
{phang2}{cmd:. xtqqplot, heatmap value(p)}{p_end}
{phang2}{cmd:. xtqqplot, contour sigmark}{p_end}
{phang2}{cmd:. xtqqplot, slices at(0.1 0.5 0.9)}{p_end}
{phang2}{cmd:. xtqqplot, slices over(tau) at(0.1 0.9)}{p_end}
{phang2}{cmd:. xtqqplot, validate}{p_end}
{phang2}{cmd:. xtqqkrls y x, seed(1)}{p_end}
{phang2}{cmd:. xtqqplot, ame}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
