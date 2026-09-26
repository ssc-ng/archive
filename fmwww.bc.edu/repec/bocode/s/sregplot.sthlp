{smcl}
{* *! version 1.0.0 24sep2026}{...}
{title:sregplot — Plot treatment effects and confidence intervals}

{p 8 12 2}
{cmd:sregplot} [{cmd:,} {opt level(#)}
{opt treatmentlabels("label 1" "label 2" ...)}
{opt title(string)} {opt xtitle(string)} {opt ytitle(string)}
{opt cicolor(colorstyle)} {opt msymbol(symbolstyle)} {opt msize(sizestyle)}
{opt mcolor(colorstyle)} {opt mfcolor(colorstyle)} {opt mlwidth(linewidthstyle)}
{opt labcolor(colorstyle)} {opt labsize(sizestyle)} {opt bgcolor(colorstyle)}
{opt nogrid} {opt nozeroline} {opt name(name, replace)}
{opt saving(filename, replace)}]

{p 4 4 2}
Run after {help sreg}, including restored estimates. Draws a horizontal
confidence interval and point estimate for each treatment, annotated with
the estimate and standard error. Intervals are calculated from {cmd:e(b)} and
{cmd:e(V)} using the selected level (default 95). Data and estimation results
are preserved. Labels must be quoted separately and match the number of arms.

{p 4 4 2}
Customize the graph using Stata color, symbol and size styles.
{opt cicolor()} specifies the confidence-interval color.
{opt nozeroline} suppresses the dashed vertical line at zero.

{phang2}{cmd:. sregplot, treatmentlabels("Program A" "Program B") level(90)}{p_end}
{phang2}{cmd:. graph export effects.svg, replace}{p_end}
{phang2}{cmd:. sregplot, cicolor(navy) msymbol(O) nogrid saving(effects.gph, replace)}{p_end}

{p 4 4 2}See {help sreg}, {help graph export}, {help colorstyle}.{p_end}

{title:Project and software}

{p 4 4 2}
This is the Stata version of the R package sreg, implemented natively in
Stata and Mata. R is not required to use this package.

{p 4 4 2}
{browse "https://sreg-project.github.io":Project website}
{break}
{browse "https://github.com/jutrifonov/sreg-stata":Stata GitHub repository}
{break}
{browse "https://github.com/jutrifonov/sreg":R package}
