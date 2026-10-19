{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "xtpqgmm" "help xtpqgmm"}{...}
{vieweralsosee "xtpqgmm_methods" "help xtpqgmm_methods"}{...}
{vieweralsosee "twoway rarea" "help twoway rarea"}{...}
{vieweralsosee "graph combine" "help graph combine"}{...}
{viewerjumpto "Syntax" "xtpqgmmplot##syntax"}{...}
{viewerjumpto "Description" "xtpqgmmplot##description"}{...}
{viewerjumpto "What the band is, and is not" "xtpqgmmplot##bands"}{...}
{viewerjumpto "Options" "xtpqgmmplot##options"}{...}
{viewerjumpto "Examples" "xtpqgmmplot##examples"}{...}
{viewerjumpto "Stored results" "xtpqgmmplot##results"}{...}
{viewerjumpto "Author" "xtpqgmmplot##author"}{...}

{p2colset 1 18 20 2}{...}
{p2col:{bf:xtpqgmmplot} {hline 2}}Coefficient path {it:beta}-hat({it:tau}) with
pointwise bands, for {helpb xtpqgmm}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpqgmmplot} {depvar} [{it:exogvars}]
{cmd:(}{it:endogvars} {cmd:=} {it:instruments}{cmd:)}
{ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Path}
{synopt:{opt q:uantile(numlist)}}quantiles to fit; default is
{cmd:10 20 30 40 50 60 70 80 90}{p_end}
{synopt:{opt v:ars(varlist)}}plot only these coefficients; default is all of
them{p_end}
{synopt:{opt l:evel(#)}}confidence level for the {bf:pointwise} band; default
is {cmd:level(95)}{p_end}
{synopt:{opt noci}}draw the path alone, with no band{p_end}

{syntab:Look}
{synopt:{opt gformat(%fmt)}}numeric format for the y axis; default
{cmd:%5.0g}{p_end}
{synopt:{opt noyz:ero}}suppress the horizontal reference line at zero{p_end}
{synopt:{opt plot:opts(line_options)}}options for the path line{p_end}
{synopt:{opt cio:pts(area_options)}}options for the band{p_end}
{synopt:{opt comb:opts(graph_combine_options)}}options for the combined
graph{p_end}
{synopt:{opt ti:tle(string)}}title of the combined graph{p_end}
{synopt:{opt sub:title(string)}}subtitle of the combined graph{p_end}

{syntab:Output}
{synopt:{opt n:ame(stub)}}name of the combined graph, and the stub for the
individual ones; default {cmd:name(xtpqgmm)}{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the graph to disk{p_end}
{synopt:{opt nocomb:ine}}draw one graph per coefficient instead of combining
them{p_end}
{synopt:{opt keepg:raphs}}keep the individual graphs in memory after
combining{p_end}
{synopt:{opt nodots}}suppress the progress dots{p_end}

{syntab:Passed to {helpb xtpqgmm}}
{synopt:{opt id(varname)}}panel identifier, if the data are not {helpb xtset}{p_end}
{synopt:{opt b:andwidth(#)}}bandwidth {it:h}{p_end}
{synopt:{opt lag:s(#)}}Bartlett truncation lag{p_end}
{synopt:{opt mm}}SP-MM, equation (9){p_end}
{synopt:{opt one:step}}one-step SP-GMM, equation (10){p_end}
{synopt:{opt nonmfallback}}switch off the Nelder-Mead safeguard{p_end}
{synopt:{opt smoothw:eight}}build the two-step weight from the smoothed
score{p_end}
{synopt:{opt mint(#)}}minimum usable {it:T} per unit; default {cmd:mint(5)}{p_end}
{synopt:{opt warnt(#)}}threshold for the short-panel note; default
{cmd:warnt(20)}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
The model is written exactly as for {helpb xtpqgmm}, and exactly as for
{helpb ivregress}: at least one endogenous regressor inside parentheses with
its instruments after the equals sign. The data must be {helpb xtset}, or
{opt id()} given.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqgmmplot} fits {helpb xtpqgmm} once at each quantile in
{opt quantile()} and plots the resulting coefficient path
{it:beta}-hat({it:tau}) against {it:tau}, with a pointwise confidence band
around it. With several regressors it draws one panel per regressor and
combines them.

{pstd}
Each quantile is a separate {cmd:xtpqgmm} call. That is deliberate: if one
{it:tau} fails to converge, the path survives, the failure is reported by
name, and {cmd:r(n_fail)} counts it. A straight segment in the line is then
interpolation across the missing quantile, not an estimate -- the command
warns about this when it happens.

{pstd}
The numbers behind the picture come back in {cmd:r(path)}, so the graph can
be redrawn by hand or turned into a table without refitting anything.


{marker bands}{...}
{title:What the band is, and is not}

{pstd}
{bf:The band is pointwise.} At each plotted {it:tau}, taken on its own, it
covers the true {it:beta}({it:tau}) with probability {opt level()}. That is
what Theorem 4.1 of Galvao, Hounyo and Lin (2026) delivers, and nothing more.

{pstd}
{bf:The band is not a confidence band for the path.} The paper proves no
weak convergence of {it:beta}-hat({c -}) as a process in {it:tau}, so there is
no uniform band to draw and this command does not pretend otherwise. In
particular:

{phang2}
o the probability that the whole estimated path stays inside the band is
{it:below} {opt level()}, and falls as more quantiles are plotted;

{phang2}
o "the path leaves the band around {it:tau} = 0.8" is {bf:not} a test of
anything;

{phang2}
o the quantiles are fitted separately and {cmd:e(V)} is block diagonal with
{bf:exactly zero} off-diagonal blocks, so {helpb test} across quantiles will
produce a number that is not valid.

{pstd}
A Bonferroni correction across the plotted grid is defensible and is
{it:not} applied for you: ask for
{cmd:level(}100 {c -} 5/{it:k}{cmd:)} with {it:k} quantiles if you want it.
See {help xtpqgmm_methods##uniform:[methods] Uniform inference} for what a
genuine uniform band would require.


{marker options}{...}
{title:Options}

{dlgtab:Path}

{phang}
{opt quantile(numlist)} lists the quantiles to fit, either as percentages
({cmd:10 25 50}) or as proportions ({cmd:.1 .25 .5}), exactly as
{helpb xtpqgmm} accepts them. At least two are required; a single quantile is
a table, not a path. The default grid is the nine deciles from 10 to 90.
Quantiles in the extreme tails need {it:T} to be large and will often fail to
converge on short panels -- that is information, not a bug.

{phang}
{opt vars(varlist)} restricts the plot to the named coefficients. Useful when
the model has several exogenous controls and only the endogenous regressor is
of interest. The names must match the coefficient names exactly as
{cmd:xtpqgmm} reports them, including any time-series operator
({cmd:L.yd}, not {cmd:yd}).

{phang}
{opt level(#)} sets the pointwise confidence level. See
{help xtpqgmmplot##bands:above} before reading the band as a statement about
the whole path.

{phang}
{opt noci} draws the path alone. Honest, and sometimes the right choice when
several panels are combined and the bands overlap into mush.

{dlgtab:Look}

{phang}
{opt gformat(%fmt)} is the numeric format for the y-axis labels, for example
{cmd:gformat(%4.2f)}. It must begin with a percent sign.

{phang}
{opt noyzero} removes the dashed horizontal line at zero. The line is drawn by
default because "is this coefficient different from zero, and where" is the
first question anyone asks of a quantile path.

{phang}
{opt plotopts()}, {opt ciopts()} and {opt combopts()} are passed straight
through to the line, the {helpb twoway rarea:rarea} band and
{helpb graph combine} respectively. The command sets no {helpb scheme}, so the
graph inherits the user's own -- it is readable under both {cmd:s2color}
(the Stata 17 default) and {cmd:stcolor} (18 and later).

{dlgtab:Output}

{phang}
{opt name(stub)} names the combined graph {it:stub} and the individual panels
{it:stub}{cmd:_1}, {it:stub}{cmd:_2}, ... in the order of {cmd:r(varlist)}.
With a single coefficient there is nothing to combine and the one graph is
named {it:stub}.

{phang}
{opt saving(filename[, replace])} saves the graph. When several graphs are
produced -- that is, under {opt nocombine} with more than one coefficient --
they are saved as {it:filename}{cmd:_1}, {it:filename}{cmd:_2}, and so on.

{phang}
{opt nocombine} leaves the panels as separate graphs and displays each.

{phang}
{opt keepgraphs} keeps the individual panels in memory after combining them.
Without it they are dropped, since {helpb graph combine} has already copied
what it needs and the leftovers only clutter {helpb graph dir}.

{phang}
{opt nodots} suppresses the one dot per fitted quantile, and the {cmd:x} that
marks a quantile that failed.

{dlgtab:Passed to xtpqgmm}

{phang}
These are handed to every {cmd:xtpqgmm} call unchanged; see
{helpb xtpqgmm##options:[xtpqgmm] Options} for what they do. Note that
{opt bandwidth()} fixes {it:h} at the {it:same} value for every quantile,
which is usually {bf:not} what you want: the default plug-in rule is
{it:tau}-specific and adapts across the grid. Fix it only to make two paths
comparable on purpose.

{phang}
The short-panel and {it:n}/{it:T} notes are suppressed inside the loop -- they
would otherwise print once per quantile. Run {helpb xtpqgmm} at a single
quantile to see them.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}The default decile path, one endogenous regressor{p_end}
{phang2}{cmd:. xtpqgmmplot ln_wage age (tenure = union south)}{p_end}

{pstd}A denser grid, 90% bands, fixed y format{p_end}
{phang2}{cmd:. xtpqgmmplot ln_wage age (tenure = union south),}
{cmd:quantile(10(5)90) level(90) gformat(%4.2f)}{p_end}

{pstd}Only the endogenous coefficient, saved to disk{p_end}
{phang2}{cmd:. xtpqgmmplot ln_wage age (tenure = union south),}
{cmd:vars(tenure) saving(tenure_path, replace)}{p_end}

{pstd}Separate graphs, kept, with a Bonferroni level over nine quantiles{p_end}
{phang2}{cmd:. xtpqgmmplot ln_wage age (tenure = union south),}
{cmd:quantile(10(10)90) level(99.44) nocombine}{p_end}

{pstd}The dynamic panel of the paper{p_end}
{phang2}{cmd:. xtpqgmmplot yd (L.yd = L2.yd L3.yd), quantile(25 50 75)}{p_end}

{pstd}Redraw the path by hand from the returned numbers{p_end}
{phang2}{cmd:. xtpqgmmplot ln_wage (tenure = union south), nodots}{p_end}
{phang2}{cmd:. matrix P = r(path)}{p_end}
{phang2}{cmd:. matrix list P}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqgmmplot} is {helpb return:rclass} and stores

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n_q)}}number of quantiles requested{p_end}
{synopt:{cmd:r(n_fail)}}number that failed to converge{p_end}
{synopt:{cmd:r(level)}}pointwise confidence level{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(graph)}}name(s) of the graph(s) left in memory{p_end}
{synopt:{cmd:r(varlist)}}coefficients plotted, in panel order{p_end}
{synopt:{cmd:r(quantiles)}}quantiles requested{p_end}
{synopt:{cmd:r(failed)}}quantiles that failed, if any{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(path)}}the plotted numbers: one row per (coefficient,
quantile), columns {cmd:tau}, {cmd:b}, {cmd:se}, {cmd:lo}, {cmd:hi}. Row
equations are the coefficient names and row names are {cmd:q10},
{cmd:q25}, ... {p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Companion to {helpb xtpqgmm}. Method: Galvao, A. F., U. Hounyo, and J. Lin.
2026. GMM for panel data quantile regression. arXiv:2610.12824 [econ.EM].
{browse "https://doi.org/10.48550/arXiv.2610.12824":doi:10.48550/arXiv.2610.12824}
