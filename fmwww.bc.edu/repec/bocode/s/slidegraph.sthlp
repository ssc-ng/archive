{smcl}
{* *! version 1.3.0  06nov2026}{...}
{viewerjumpto "Syntax" "slidegraph##syntax"}{...}
{viewerjumpto "Description" "slidegraph##description"}{...}
{viewerjumpto "Options" "slidegraph##options"}{...}
{viewerjumpto "Remarks" "slidegraph##remarks"}{...}
{viewerjumpto "Examples" "slidegraph##examples"}{...}
{viewerjumpto "Stored results" "slidegraph##results"}{...}
{viewerjumpto "Installation" "slidegraph##installation"}{...}
{viewerjumpto "Author" "slidegraph##author"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{bf:slidegraph} {hline 2}}Automated stepped and layered graphs for presentation slides{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}
1. Configure slide layers with explicit patterns:

{p 8 16 2}
{cmd:slidegraph set}{cmd:,} {cmdab:pat:terns(}{it:color1 pat1 color2 pat2 ...}{cmd:)}
[{cmd:off(}{it:#}{cmd:)} {cmd:dim(}{it:#}{cmd:)}]

{p 4 8 2}
2. Configure slide layers with preset shorthands:

{p 8 16 2}
{cmd:slidegraph set}{cmd:,} {cmdab:col:ors(}{it:color1 color2 ...}{cmd:)}
{cmdab:cum:ulative}|{cmdab:spot:light} [{cmd:off(}{it:#}{cmd:)} {cmd:dim(}{it:#}{cmd:)}]

{p 4 8 2}
3. Execute multi-frame build:

{p 8 16 2}
{cmd:slidegraph} [{cmd:,} {cmd:stub(}{it:name}{cmd:)} {cmd:saving(}{it:filename}{cmd:)}
{cmd:full}] {cmd::} {it:graph_command}

{p 4 8 2}
4. Export LaTeX Beamer overlay code:

{p 8 16 2}
{cmd:slidegraph export} [{it:using filename.tex}] [{cmd:,} {cmd:path(}{it:string}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)} {cmd:options(}{it:string}{cmd:)} {cmd:replace}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main (slidegraph)}
{synopt :{opt stub(name)}}graph name prefix in memory; default is {cmd:sg}{p_end}
{synopt :{opt saving(filename)}}save or export individual frames using automatic extension detection (e.g., {cmd:.pdf}, {cmd:.png}, {cmd:.gph}){p_end}
{synopt :{opt full}}also create an unsuffixed full figure (all series visible at 100%) in memory and on disk{p_end}

{syntab:Configuration (slidegraph set)}
{synopt :{opt pat:terns(string)}}space-delimited list of {it:color_token pattern} pairs (patterns can use {cmd:0}=off, {cmd:1}=dim, {cmd:2}=focus){p_end}
{synopt :{opt col:ors(string)}}space-delimited list of series color tokens to be sequenced by preset{p_end}
{synopt :{opt cum:ulative}}preset for progressive revelation (frame 1 shows series 1; frame 2 shows 1 & 2; etc. with previous series staying visible){p_end}
{synopt :{opt spot:light}}preset for narrative focus (active series at 100%, previous series dimmed to {opt dim()}, future series off){p_end}
{synopt :{opt off(#)}}opacity percentage integer for hidden series (0-100); default is {cmd:0} ({cmd:%0}){p_end}
{synopt :{opt dim(#)}}opacity percentage integer for dimmed/background series (0-100); default is {cmd:20} ({cmd:%20}){p_end}

{syntab:Export (slidegraph export)}
{synopt :{it:using filename.tex}}target {cmd:.tex} file path; default is {it:saving_stem.tex}{p_end}
{synopt :{opt path(string)}}custom relative/absolute image directory to prepend in LaTeX {cmd:\includegraphics} commands{p_end}
{synopt :{opt saving(filename)}}override saved image filename stem and extension{p_end}
{synopt :{opt options(string)}}options passed inside {cmd:\includegraphics[...]}; default is {cmd:width=\linewidth}{p_end}
{synopt :{opt replace}}overwrite existing {cmd:.tex} file{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:slidegraph} automates the creation of layered, stepped sequence graphs for presentation slides
(such as LaTeX Beamer or PowerPoint builds).

{pstd}
In traditional slide builds, omitting data series from early frames causes Stata to recalculate axis
ranges, change legend bounding boxes, and shift margins across frames. {cmd:slidegraph} solves this
problem by plotting all series in every single frame and modulating visibility using Stata's native opacity
modifiers (e.g., turning {cmd:navy} into {cmd:navy%0} when hidden, or {cmd:navy%20} when dimmed).
As a result, axes, ticks, labels, and legends remain 100% stationary throughout the build sequence.

{pstd}
{cmd:slidegraph} supports 3-state narrative storytelling:
{break}
- {cmd:2}: Focus / full opacity (series under active discussion).
{break}
- {cmd:1}: Dimmed ghost context ({opt dim(#)}, series already introduced but de-emphasized).
{break}
- {cmd:0}: Off / hidden ({opt off(#)}, series not yet introduced).
{break}
When patterns contain only {cmd:0} and {cmd:1} (and no {cmd:2}), {cmd:1} defaults to full opacity and {cmd:0} to off, preserving full backwards compatibility.

{pstd}
All graph options (e.g., {cmd:title()}, {cmd:legend()}, {cmd:aspect()}) are specified
directly within the {it:graph_command} after the colon. While {cmd:twoway} is the most common use case,
{cmd:slidegraph} works equally well with any Stata graph command that supports series colors, such as
{cmd:graph bar}, {cmd:graph hbar}, {cmd:graph dot}, and {cmd:graph box}.


{marker options}{...}
{title:Options}

{phang}
{opt stub(name)} sets the memory name prefix for the generated graphs ({it:stub_1}, {it:stub_2}, ..., {it:stub_N}).
The default is {cmd:sg} ({cmd:sg_1}, {cmd:sg_2}, ...).
{it:Note:} Avoid specifying {cmd:name()} inside the {it:graph_command}, as {cmd:slidegraph} injects its own
frame names based on {opt stub()}. If a {cmd:name()} option is detected in the graph command, a warning is displayed.

{phang}
{opt saving(filename)} automatically saves or exports each rendered slide with the frame index inserted before the file extension
({it:filename_1.ext}, {it:filename_2.ext}, ..., {it:filename_N.ext}).
The action is determined automatically by inspecting the file postfix:
{break}
- {cmd:.pdf}, {cmd:.png}, {cmd:.svg}, {cmd:.eps}, {cmd:.tif}: automatically calls {cmd:graph export}.
{break}
- {cmd:.gph} (or omitting an extension): automatically calls {cmd:graph save}.

{phang}
{opt full} instructs {cmd:slidegraph} to also render an unsuffixed full figure ({it:stub} in memory and {it:filename.ext} on disk)
where all series are plotted at 100% opacity without modification. This allows generating both paper figures and slide animation frames
from a single graph command.

{phang}
{opt patterns(string)} specifies explicit series visibility sequences using paired color tokens and ternary/binary strings.
Both named color styles (e.g., {cmd:navy}, {cmd:cranberry}) and custom RGB values (e.g., {cmd:"255 0 0"}) are supported.
RGB color triples must be enclosed in quotes (e.g., {cmd:patterns("255 0 0" 21 "0 128 255" 02)}).
When an RGB color is detected, {cmd:slidegraph} automatically places the opacity modifier inside the quotes (e.g., {cmd:"255 0 0 %0"}),
as required by Stata's syntax, and issues a warning that RGB formatting may be sensitive to spacing.

{phang}
{opt colors(string)} specifies a list of color tokens to sequence using a preset shorthand ({opt cumulative} or {opt spotlight}).

{phang}
{opt cumulative} generates progressive revelation patterns where each series appears in turn and remains on at 100% opacity for all subsequent frames.

{phang}
{opt spotlight} generates narrative focus patterns where each series is highlighted at 100% opacity during its active frame,
previous series are kept visible but dimmed to {opt dim(#)}, and subsequent series remain off at {opt off(#)}.

{phang}
{opt off(#)} specifies the opacity percentage integer applied when a bit is {cmd:0}. The value must be an integer between 0 and 100.
The default is {cmd:0} (which becomes {cmd:%0}, fully transparent).

{phang}
{opt dim(#)} specifies the opacity percentage integer applied when a bit is {cmd:1} in 3-state patterns. The value must be an integer between 0 and 100.
The default is {cmd:20} (which becomes {cmd:%20}, dimmed ghost context).

{phang}
{opt path(string)} in {cmd:slidegraph export} specifies a custom relative or absolute directory path to prepend in LaTeX {cmd:\includegraphics} commands.
{cmd:slidegraph} strips out any local directory components from the saved image filename and substitutes this path, solving relative path mismatches
between Stata working directories and LaTeX presentation source files.


{marker remarks}{...}
{title:Remarks: Design philosophy and limitations}

{pstd}
{bf:Why color-based substitution?}
{break}
Stata's graphing ecosystem spans a wide variety of built-in commands ({cmd:twoway},
{cmd:graph bar}, {cmd:graph box}, {cmd:graph dot}, {cmd:histogram}) and
community-contributed packages ({cmd:coefplot}, {cmd:marginsplot}, {cmd:binscatter},
etc.), each with its own syntax for defining series and plot elements.
Attempting to parse plot structures directly would either restrict {cmd:slidegraph}
to basic {cmd:twoway} commands or make it fragile when used with wrapper packages.

{pstd}
Despite their syntactic differences, nearly all Stata graph commands share a
common denominator: they accept standard Stata color specifications.
By keying frame visibility to color tokens rather than plot syntax,
{cmd:slidegraph} remains completely command-agnostic{hline 2}any element whose
color you can specify can be sequenced across slides.

{pstd}
{bf:Limitation and workarounds: Multiple layers with the same color}
{break}
Because {cmd:slidegraph} identifies layers by their color token, two plot elements
that use the exact same color string cannot be toggled independently:

{phang2}{cmd:. twoway (scatter y1 x1, mcolor(navy)) (scatter y2 x2, mcolor(navy))}{p_end}

{pstd}
If you need two series to appear in the {bf:same visual color} on different frames,
you have two simple workarounds:

{phang}
1. {bf:Use visually identical color aliases:} Stata treats unit intensity multipliers
and equivalent RGB triplets as identical on screen, while {cmd:slidegraph} treats
them as distinct tokens:
{break}
- Layer 1: {cmd:mcolor(navy)}
{break}
- Layer 2: {cmd:mcolor(navy*1)} (or {cmd:mcolor(navy*1.0)})
{break}
- Layer 3: {cmd:mcolor("26 71 111")} (the RGB equivalent of {cmd:navy})
{break}
For example: {cmd:slidegraph set, colors(navy navy*1) cumulative}

{phang}
2. {bf:Copy and tweak the generated commands:} {cmd:slidegraph} prints the exact
expanded command for every frame to the Stata Results window. In complex cases,
you can assign temporary distinct colors to generate the sequence, then copy the
echoed commands from the Results window and adjust the colors manually.


{marker examples}{...}
{title:Examples}

{pstd}Load example data:{p_end}
{phang2}{cmd:. }{stata "sysuse auto, clear"}{p_end}

{pstd}1. Two-frame build with shorthand cumulative preset:{p_end}
{phang2}{cmd:. }{stata "slidegraph set, colors(navy cranberry) cumulative"}{p_end}
{phang2}{cmd:. }{stata `"slidegraph : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)), title("Price vs MPG by Foreign Status")"'}{p_end}
{phang2}{cmd:. }{stata "graph dir sg*"}{p_end}
{phang2}{cmd:. }{stata "graph display sg_1"}{p_end}
{phang2}{cmd:. }{stata "graph display sg_2"}{p_end}

{pstd}2. Three-frame build with spotlight focus and ghost dimming:{p_end}
{phang2}{cmd:. }{stata "slidegraph set, colors(navy cranberry midblue) spotlight dim(25)"}{p_end}
{phang2}{cmd:. }{stata `"slidegraph, stub(spot) : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)) (lfit price mpg, lcolor(midblue))"'}{p_end}
{phang2}{cmd:. }{stata "graph display spot_1"}{p_end}
{phang2}{cmd:. }{stata "graph display spot_2"}{p_end}
{phang2}{cmd:. }{stata "graph display spot_3"}{p_end}

{pstd}3. Combined slide sequence + standalone paper figure + LaTeX export:{p_end}
{phang2}{cmd:. }{stata "slidegraph set, colors(navy cranberry midblue) cumulative"}{p_end}
{phang2}{cmd:. }{stata `"slidegraph, stub(fig1) saving(fig1.pdf) full : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)) (lfit price mpg, lcolor(midblue))"'}{p_end}
{phang2}{cmd:. }{stata `"slidegraph export using "fig1_slides.tex", path("figures/slides") replace"'}{p_end}
{phang2}{cmd:. }{stata `"type "fig1_slides.tex""'}{p_end}

{pstd}In your LaTeX Beamer presentation, simply insert:{p_end}
{phang2}{cmd:\input{c -(}fig1_slides.tex{c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:slidegraph set} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total number of frames{p_end}
{synopt:{cmd:r(npairs)}}number of color/pattern pairs{p_end}
{synopt:{cmd:r(any_rgb)}}1 if custom RGB colors detected, 0 otherwise{p_end}
{synopt:{cmd:r(has_2)}}1 if 3-state patterns active, 0 otherwise{p_end}
{synopt:{cmd:r(off_val)}}off opacity percentage integer{p_end}
{synopt:{cmd:r(dim_val)}}dim opacity percentage integer{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(patterns)}}raw patterns string{p_end}
{synopt:{cmd:r(off)}}off modifier (e.g. {cmd:%0}){p_end}
{synopt:{cmd:r(dim)}}dim modifier (e.g. {cmd:%20}){p_end}

{pstd}
{cmd:slidegraph} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total number of frames{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(stub)}}memory graph name prefix{p_end}
{synopt:{cmd:r(cmd_#)}}expanded command executed for frame {it:#} ({cmd:r(cmd_1)}, {cmd:r(cmd_2)}, ...){p_end}
{synopt:{cmd:r(cmd_full)}}full figure command with all series at 100% (if {opt full} specified){p_end}
{synopt:{cmd:r(full)}}{cmd:1} if {opt full} specified{p_end}
{synopt:{cmd:r(saving)}}specified target saving filename{p_end}
{synopt:{cmd:r(save_stem)}}target saving filename without extension{p_end}
{synopt:{cmd:r(save_ext)}}target saving file extension{p_end}
{synopt:{cmd:r(off)}}off modifier (e.g. {cmd:%0}){p_end}
{synopt:{cmd:r(dim)}}dim modifier (e.g. {cmd:%20}){p_end}

{pstd}
{cmd:slidegraph export} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total number of overlay frames{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(file)}}path to generated {cmd:.tex} file{p_end}
{synopt:{cmd:r(path)}}custom LaTeX image path prefix{p_end}
{synopt:{cmd:r(options)}}options passed to {cmd:\includegraphics}{p_end}
{p2colreset}{...}


{marker installation}{...}
{title:Installation}

{pstd}
Install from the SSC archive (recommended once available):{p_end}
{phang2}{cmd:. }{stata "ssc install slidegraph, replace"}{p_end}

{pstd}
To retrieve the demonstration do-file ({cmd:slidegraph_demo.do}):{p_end}
{phang2}{cmd:. }{stata "net get slidegraph"}{p_end}

{pstd}
Or install the latest development version directly from GitHub:{p_end}
{phang2}{cmd:. }{stata `"net install slidegraph, from("https://aarondwolf.github.io/slidegraph") replace"'}{p_end}


{marker author}{...}
{title:Author & Support}

{pstd}
Aaron Wolf, Northwestern University{break}
Email: {browse "mailto:aaron.wolf@u.northwestern.edu":aaron.wolf@u.northwestern.edu}{break}
Project: {browse "https://github.com/aarondwolf/slidegraph":https://github.com/aarondwolf/slidegraph}{break}
Issues & bug reports: {browse "https://github.com/aarondwolf/slidegraph/issues":https://github.com/aarondwolf/slidegraph/issues}{break}
Please visit the GitHub repository to check for updates or report issues.{p_end}
