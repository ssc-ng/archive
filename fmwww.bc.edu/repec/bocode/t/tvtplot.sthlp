{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtsim" "help tvtsim"}{...}
{vieweralsosee "[G-2] graph twoway" "help twoway"}{...}
{viewerjumpto "Syntax" "tvtplot##syntax"}{...}
{viewerjumpto "Description" "tvtplot##description"}{...}
{viewerjumpto "What to look for" "tvtplot##reading"}{...}
{viewerjumpto "Options" "tvtplot##options"}{...}
{viewerjumpto "Examples" "tvtplot##examples"}{...}
{viewerjumpto "Author" "tvtplot##author"}{...}
{title:Title}

{phang}
{bf:tvtplot} {hline 2} Plot a fitted time-varying threshold


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtplot} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth true:var(varname)}}overlay a known true threshold path{p_end}
{synopt :{opt nosc:atter}}omit the threshold variable's points{p_end}
{synopt :{opt nore:gime}}do not highlight the lower-regime points{p_end}
{synopt :{opt nole:gend}}suppress the legend{p_end}
{synopt :{opt ti:tle(string)}}, {opt sub:title(string)},
{opt yt:itle(string)}, {opt xt:itle(string)}{p_end}
{synopt :{opt ms:ize(size)}}, {opt lw:idth(width)},
{opt sch:eme(name)}{p_end}
{synopt :{opt name(name)}}, {opt sav:ing(filename)}{p_end}
{synopt :{it:twoway_options}}anything {helpb twoway} accepts{p_end}
{synoptline}
{p 4 6 2}
{cmd:tvtplot} runs after a TVTHRESH {bf:estimator} that leaves
{cmd:e(path)}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtplot} draws the fitted threshold path over time, against the
threshold variable it splits, with the observations assigned to the lower
regime highlighted.

{pstd}
{bf:Why the picture is worth drawing.} A time-varying threshold model
asserts that the boundary between regimes moved. That assertion is far
easier to judge by eye than from three Fourier coefficients. The plot shows
at once whether the fitted path tracks a real feature of the data or wanders
through an undifferentiated cloud of points, and whether both regimes stay
populated across the sample or one of them empties out at the ends. A table
of coefficients hides both, and both bear directly on whether the estimates
mean anything.

{pstd}
It runs after an {bf:estimator}. A test such as {helpb tvthomog} does not
fit a path at all {hline 2} it reports whether the threshold is constant
without estimating how it moves {hline 2} so there is nothing for it to
draw, and {cmd:tvtplot} says so rather than inventing a line.


{marker reading}{...}
{title:What to look for}

{phang}
{bf:Does either regime empty out?} If the fitted path runs above almost
every point for a stretch of the sample, the upper regime is nearly empty
there and the coefficients are being identified by a handful of
observations. The fit may still be the least-squares optimum and still be
untrustworthy. This is the single most useful thing the plot reveals.

{phang}
{bf:Does the path move for a reason?} A path that swings across the whole
range of the threshold variable while the points show no corresponding
structure is fitting noise. Compare the SSRs {hline 2}
{cmd:e(ssr_const)} against {cmd:e(ssr)} {hline 2} and read the constancy
test before believing a dramatic-looking path.

{phang}
{bf:Does the shape match the mechanism you have in mind?} A Fourier path is
smooth and cyclical by construction. If the story is a policy change on a
date, a smooth cycle fitted through it is an approximation to a step, and
not a good one. See {helpb tvthresh_choose}.

{phang}
{bf:Is the movement large relative to the spread of} {it:q}{bf:?} A
threshold that moves by a tenth of the interquartile range of the threshold
variable is reclassifying very few observations, whatever its coefficients'
p-values say.


{marker options}{...}
{title:Options}

{phang}
{opth truevar(varname)} overlays a known true path as a dashed line. Used
with {helpb tvtsim}, which leaves the true path in the data as
{cmd:gamma}, this turns the plot into a direct check of how well the
estimator recovered what generated the data.

{phang}
{opt noscatter} omits the threshold variable's own observations, and
{opt noregime} omits the highlighting of the lower-regime points. Both are
there for the case where the sample is large enough that the points obscure
the line rather than informing it; with more than a few thousand
observations, {opt noregime} usually reads better.

{phang}
{opt title()}, {opt subtitle()}, {opt ytitle()}, {opt xtitle()},
{opt msize()}, {opt lwidth()}, {opt scheme()}, {opt name()} and
{opt saving()} behave as elsewhere in Stata. The defaults are chosen to read
on a printed page: the data in light grey so they do not compete with the
fitted line, which is what the reader is being asked to look at.

{phang}
Any other {helpb twoway} option is passed through, so the result can be
restyled to a journal's requirements without rebuilding the graph by hand.

{pstd}
The horizontal axis is the {helpb tsset} time variable when the data are
{cmd:tsset}, and the observation number otherwise.


{marker examples}{...}
{title:Examples}

{pstd}Fit and plot.{p_end}
{phang2}{cmd:. tvtsim, model(fourier) n(200) seed(71010) clear}{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}
{phang2}{cmd:. tvtplot}{p_end}

{pstd}With the true path overlaid, which is how to check an estimator on
simulated data.{p_end}
{phang2}{cmd:. tvtplot, truevar(gamma)}{p_end}

{pstd}A cleaner version for publication, with the points dropped and the
line emphasised.{p_end}
{phang2}{cmd:. tvtplot, noregime msize(tiny) lwidth(thick) title("Estimated threshold")}{p_end}

{pstd}Fitted against a design the Fourier form handles badly {hline 2} the
plot makes the mismatch obvious in a way the coefficients do not.{p_end}
{phang2}{cmd:. tvtsim, model(shift1) n(500) seed(7) clear}{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}
{phang2}{cmd:. tvtplot, truevar(gamma)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvtfourier}, {helpb tvtsim},
{helpb tvthresh_choose}
{p_end}
