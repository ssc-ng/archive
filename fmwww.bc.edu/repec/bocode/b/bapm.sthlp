{smcl}
{* *! version 1.0 25 Oct 2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "bapm##syntax"}{...}
{viewerjumpto "Description" "bapm##description"}{...}
{viewerjumpto "Examples" "bapm##examples"}{...}
{title:Title}
{phang}
{bf:bapm} {hline 2} <Insert title>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:bapm}
varlist(min=3
max=6
numeric)
[{help if}]
[{cmd:,}
{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt g:raph}}  Generate a combined Bland-Altman plot. If {opt g:raph} or 
{opt n:ame} are set, a Bland-Altman plot matrix is generated.

{synopt:{opt n:ame(passthru)}} Specify the name of the combined Bland-Altman 
plot. If {opt g:raph} or {opt n:ame} are set, a Bland-Altman plot matrix is generated.

{synopt:{opt size(passthru)}}  Specify {help help textsizestyle: text size}.  Default is Huge.

{synopt:{opt f:ormatgraph(string)}}  Stata number format to use in graph (default is %4.1f)

{synopt:{opt T:ext(string)}}  String value for the first legend (default is 
variable 1 label/variable 1 name vs variable 1 label/variable 1 name)

{synopt:{opt s:catterstyle(string)}}  A {help twoway:twoway} scatter marker specification 
(default is jitter(3))

{synopt:{opt m:eanlinestyle(string)}}  A {help twoway:twoway} line specification for the mean 
line (default is lcolor(gs8) lpattern(solid))

{synopt:{opt loa:linestyle(string)}}  A {help twoway:twoway} line specification for the LOA 
lines (default is lcolor(gs8) lpattern(dash))

{synopt:{opt low:ess}}  Use a lowess curve instead of the mean of the differences

{synopt:{opt noCIM:ean}}  Do not add CI for the mean.

{synopt:{opt noCIL:oa}}  Do not add CI for the LOAs.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The command {cmd:bapm} is a wrapper doing a set of pairwise comparisons 
for the {help bap:Bland-Altman plot generator} on 3 to 6 variables.{p_end}


{marker examples}{...}
{title:Examples}


{phang}Get Bland-Altman dataset:{p_end}
{phang}{stata `". infile using "https://www-users.york.ac.uk/~mb55/datasets/pefr.dct", clear"'}{p_end}
{phang}{stata `". label data "PEFR (l/min) data""'}{p_end}
{phang}{stata `". label variable wright1 "Wright 1st"'}{p_end}
{phang}{stata `". label variable wright2 "Wright 2nd"'}{p_end}
{phang}{stata `". label variable mini1 "mini Wright 1st"'}{p_end}
{phang}{stata `". label variable mini2 "mini Wright 2nd"'}{p_end}

{phang}Get Bland-Altman pairwise comparisons in a matrix:{p_end}
{phang}{stata `". bapm wright1 wright2 mini1 mini2"'}{p_end}

{phang}Get Bland-Altman pairwise comparisons in a matrix and a Bland-Altman plot matrix (take some time):{p_end}
{phang}{stata `". bapm wright1 wright2 mini1 mini2, n(gl, replace)"'}{p_end}


{title:Stored results}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(bapm)}}  A matrix containing pairwise comparisons on the measurements: 
The mean measurements with 95% CI, the bias with 95% CI, the SEM, and the LOA limits{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}



