{smcl}
{* 03nov2026}{...}
{hi:help corrheat}{right:version 0.1.2}
{hline}

{title:Title}

{pstd}{hi:corrheat} {hline 2} Correlation heat plot with r and p labels and an in-plot color bar


{title:Syntax}

{p 8 15 2}
    {cmd:corrheat} {varlist} {ifin}
    [{cmd:,} {it:options} {it:{help twoway_options}}]

{synoptset 26}{...}
{synopthdr:options}
{synoptline}
{syntab:Color scale}
{synopt :{opt cut:s(numlist)}}color-bin edges; default runs from the most negative r up to 1{p_end}
{synopt :{opt st:ep(#)}}bin width for the automatic cuts; default {cmd:.05}{p_end}
{synopt :{opt col:ors(colorlist)}}palette from low to high; default {cmd:White Ivory "118 223 253" "0 129 168"}{p_end}

{syntab:Cell labels}
{synopt :{opt whitea:bove(#)}}white text where rounded r is at or above {it:#}; default {cmd:.8}{p_end}
{synopt :{opt whiteb:elow(#)}}white text where rounded r is at or below {it:#}; default {cmd:-2} (never){p_end}
{synopt :{opt rs:ize(size)}}size of r labels, including the diagonal; default {cmd:*1.3}{p_end}
{synopt :{opt ps:ize(size)}}size of p labels; default {cmd:*.9}{p_end}
{synopt :{opt nop:values}}show r only{p_end}
{synopt :{opt lead:zero}}keep leading zeros (0.28, 0.020); default drops them{p_end}

{syntab:Correlations}
{synopt :{opt list:wise}}listwise deletion in {helpb pwcorr}; default is pairwise{p_end}

{syntab:Color bar}
{synopt :{opt nobar}}omit the color bar{p_end}
{synopt :{cmd:{ul:bar}pos(}{it:x0 x1 ytop ybot}{cmd:)}}bar position in plot coordinates{p_end}
{synopt :{opt tick:s(numlist)}}values that get a tick on the bar; default {cmd:-1(.25)1}{p_end}
{synopt :{opt tlab:size(size)}}size of the bar's tick labels; default {cmd:small}{p_end}

{syntab:Graph}
{synopt :{it:{help twoway_options}}}any other options, such as {cmd:xtitle()}, {cmd:title()},
    {cmd:xsize()}, {cmd:ysize()}, {cmd:name()}, or {cmd:saving()}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:corrheat} draws a lower-triangle correlation heat plot of the variables in
{it:varlist}. Each cell shows the correlation r with its p value underneath, and
a gradient color bar is drawn inside the empty upper-right triangle.

{pstd}
Correlations and p values come from {helpb pwcorr}. The plot is drawn with
{helpb heatplot} (Jann 2019). The color bar is built from the colors and bin
edges that {cmd:heatplot} itself uses for the cells, so the legend always
matches the plot.

{pstd}
{cmd:corrheat} works on a preserved copy of the data; your dataset is not changed.

{pstd}
{cmd:corrheat} requires Stata 16 or newer and the SSC packages {cmd:heatplot},
{cmd:palettes}, and {cmd:colrspace}:

        . {stata ssc install heatplot, replace}
        . {stata ssc install palettes, replace}
        . {stata ssc install colrspace, replace}


{title:Options}

{dlgtab:Color scale}

{phang}
{opt cuts(numlist)} sets the edges of the color bins, for example
{cmd:cuts(-0.1(0.05)1)}. The color bar spans exactly this range. If omitted,
the cuts run from the most negative correlation, rounded down to a multiple of
{cmd:step()}, up to 1. The cuts used are displayed in the Results window. If a
correlation falls below the lowest cut, {cmd:heatplot} adds one extra bin from
that value up to the lowest cut.

{phang}
{opt step(#)} sets the bin width used when {cmd:cuts()} is omitted. The default
is {cmd:step(.05)}.

{phang}
{opt colors(colorlist)} sets the palette, from the lowest to the highest bin.
Any palette or color list accepted by {helpb colorpalette} is allowed; colors
are interpolated across the bins. The default is
{cmd:colors(White Ivory "118 223 253" "0 129 168")}.

{dlgtab:Cell labels}

{phang}
{opt whiteabove(#)} prints the labels of cells whose r, rounded to two
decimals, is at or above {it:#} in white instead of black. The default is
{cmd:whiteabove(.8)}. Rounding means two cells that display the same value
always get the same text color. Diagonal labels are always white.

{phang}
{opt whitebelow(#)} does the same for cells at or below {it:#}. Use it with a
diverging palette, where strongly negative cells are also dark. The default,
{cmd:whitebelow(-2)}, never applies.

{phang}
{opt rsize(size)} and {opt psize(size)} set the sizes of the r and p labels;
see {it:{help textsizestyle}}. {cmd:rsize()} also sets the size of the 1s on the
diagonal. Defaults are {cmd:rsize(*1.3)} and {cmd:psize(*.9)}.

{phang}
{opt nopvalues} suppresses the p labels and shows r only.

{phang}
{opt leadzero} keeps leading zeros in the r, p, and color-bar labels (0.28,
0.020, <0.001). By default they are dropped, following APA style for
statistics that cannot exceed 1 (.28, .020, <.001).

{dlgtab:Correlations}

{phang}
{opt listwise} passes {cmd:listwise} to {helpb pwcorr}, so all correlations use
the same observations. The default is pairwise deletion.

{dlgtab:Color bar}

{phang}
{opt nobar} omits the color bar.

{phang}
{cmd:barpos(}{it:x0 x1 ytop ybot}{cmd:)} places the bar in plot coordinates: left edge,
right edge, top, and bottom. Matrix row {it:i} sits at y = {it:i} (row 1 on top)
and column {it:j} at x = {it:j}; each cell is 1 unit square. The default for
{it:k} variables is {cmd:barpos(}{it:k}-1.25 {it:k}-.95 .6 .6+.45{it:k}{cmd:)}.

{phang}
{opt ticks(numlist)} sets the values that get a tick and label on the bar.
Values outside the bar's range are skipped, so the default,
{cmd:ticks(-1(.25)1)}, suits any scale.

{phang}
{opt tlabsize(size)} sets the size of the bar's tick labels. The default is
{cmd:tlabsize(small)}.

{dlgtab:Graph}

{phang}
{it:twoway_options} are any other options; they are passed to the graph. See
{it:{help twoway_options}}.


{title:Remarks}

{pstd}
{ul:One scale per paper.} Automatic cuts fit each figure to its own data, so
the same shade can mean different r values in different figures. Note the cuts
displayed for each figure and give the widest range to all of them with
{cmd:cuts()}.

{pstd}
{ul:Layout.} The first variable listed is the top row and
column 1. Row labels are the variable labels, so label your
variables first. The x axis is numbered 1 to {it:k}-1, because the last column
holds only the diagonal.

{pstd}
{ul:Limits.} The default bar position assumes at least 5 variables. With 4 or
fewer, the empty triangle is too small; specify {cmd:nobar} or adjust
{cmd:barpos()}. The layout assumes a lower triangle with the diagonal drawn, so
do not pass {cmd:heatplot}'s {cmd:nodiagonal} or {cmd:upper} options.

{pstd}
{ul:Shading.} Two cells that display the same r can differ by one shade when
their unrounded values sit on either side of a bin edge (for example, .7996 and
.8004). The shading reflects the unrounded values.


{title:Examples}

{pstd}
Basic use with Stata's auto data:

        . {stata sysuse auto, clear}
        . {stata corrheat price mpg headroom trunk weight length turn displacement}

{pstd}
Correlations only, no p values:

{p 8 12 2}
        . {stata corrheat price mpg headroom trunk weight length turn displacement, nopvalues}

{pstd}
Diverging gold-to-teal palette centered on zero:

{p 8 12 2}
        . {stata corrheat price mpg headroom trunk weight length turn displacement, cuts(-1(.05)1) colors(#b8860b #f7f7f7 #0f7395) whitebelow(-.8)}

{pstd}
A publication figure with a fixed scale and size, then exported:

        . corrheat v1 v2 v3 v4 v5 v6 v7 v8 v9, cuts(-0.1(0.05)1)  ///
              xtitle("Profiles", size(medium)) xsize(6.5) ysize(4.5)
        . graph export "corr_fig1.png", width(3000) replace


{title:References}

{phang}
Jann, B. (2019). heatplot: Stata module to create heat plots and hexagon plots.
Available from {browse "http://ideas.repec.org/c/boc/bocode/s458598.html"}.


{title:Author}

{pstd}
Shane Littrell, Cornell University (shane.littrell27@gmail.com)

{pstd}
Website: {browse "http://www.shanelittrell.com"}.


{title:Also see}

{psee}
Online: help for {helpb heatplot}, {helpb colorpalette}, {helpb pwcorr}
