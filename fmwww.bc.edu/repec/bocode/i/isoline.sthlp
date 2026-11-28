{smcl}
{* 06Nov2026}{...}
{hi:help isoline}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-graphfunctions":graphfunctions (GitHub)}}

{hline}
{it:(back to {stata help graphfunctions})}

{title:isoline}: {it:Generate contour line segments and filled depth-band polygons.}

{pstd}
{cmd:isoline} converts numeric {it:x y z} observations into coordinates for
{help twoway} graphs. It requires Stata 15 or newer and no additional packages.
It generates coordinates only; colors and other styling are set in the graph command.

{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:isoline} {it:x y z} {ifin}
[{cmd:,} {opt method(string)} {opt power(#)} {opt levels(numlist)}
{opt n(#)} {opt smooth(#)} {opt fill} {opt replace}
{opt genx(name)} {opt geny(name)} {opt genz(name)}
{opt genid(name)} {opt genorder(name)}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt method(string)}}{cmd:idw} (default) or {cmd:nearest}.{p_end}
{synopt:{opt pow:er(#)}}Positive IDW distance power; default {cmd:2}. Only allowed with {cmd:method(idw)}.{p_end}
{synopt:{opt levels(numlist)}}Contour depths, or band boundaries with {cmd:fill}. Default: five equally spaced depths inside the sampled z range.{p_end}
{synopt:{opt n(#)}}Grid points along each axis; integer at least 2. Default {cmd:50}, giving a 50 by 50 grid.{p_end}
{synopt:{opt smo:oth(#)}}Gaussian smoothing bandwidth from 0 to 1. Default {cmd:0} (no smoothing).{p_end}
{synopt:{opt fill}}Generate closed band polygons instead of line segments.{p_end}
{synopt:{opt replace}}Overwrite output variables, but never the three input variables.{p_end}
{synopt:{opt genx(name)}}Output x coordinate; default {cmd:_x}.{p_end}
{synopt:{opt geny(name)}}Output y coordinate; default {cmd:_y}.{p_end}
{synopt:{opt genz(name)}}Output depth or band number; default {cmd:_z}.{p_end}
{synopt:{opt genid(name)}}Output segment or polygon ID; default {cmd:_id}.{p_end}
{synopt:{opt genorder(name)}}Point order within each segment or polygon; default {cmd:_order}.{p_end}
{synoptline}
{p2colreset}{...}

{title:Interpolation and smoothing}

{pstd}
The command evaluates the surface on a regular grid covering the selected
sample's bounding rectangle, including areas outside its convex hull.
Those areas are extrapolated. Distances use the original x/y units, so the
coordinates should be in comparable units. At least three complete observations
are required; x, y, and z must each vary, and sampled x/y pairs must be unique.
Observations with missing x, y, or z are excluded.

{pstd}
{cmd:method(idw)} uses all sampled points with weights proportional to
distance raised to minus {cmd:power()}. Higher powers emphasize nearby points.
At a grid node coinciding with an observation, the observed z is used.
{cmd:method(nearest)} assigns the nearest sampled z to each grid node.
Equidistant ties use the smallest x, then the smallest y, independent of input order.

{pstd}
Both methods then extract contours by linear interpolation on two triangles
per grid cell. Nearest-neighbor contours therefore approximate, rather than
exactly trace, Voronoi boundaries. Increasing {cmd:n()} refines this approximation;
it does not itself control smoothing. Runtime grows with sample size and grid size.

{pstd}
{cmd:smooth()} applies Gaussian averaging to the grid before extracting
lines or polygons. The kernel standard deviation is {cmd:smooth()} times the
longer side of the sampled bounding rectangle. For example, {cmd:smooth(.05)}
uses 5% of that span. Weights are renormalized at rectangle edges, without
zero padding. Smoothing keeps values within the unsmoothed grid's range but
does not preserve exact interpolation at observations.

{pstd}
Try {cmd:.02} for light smoothing, {cmd:.05} for moderate smoothing, or
{cmd:.10} for stronger smoothing. Values near {cmd:1} strongly flatten the
surface and may eliminate requested contour levels. Use enough grid points to
resolve the chosen bandwidth. Use identical {cmd:method()}, {cmd:power()},
{cmd:levels()}, {cmd:n()}, and {cmd:smooth()} settings for matching lines and fills.

{title:Output and plotting}

{pstd}
The five output variables are double precision. Input observations and their
order are retained. Output coordinates begin in observation 1; rows are added
only when needed, with missing values for the original variables in those new rows.
Unused output rows are missing. Output names must be distinct and different from
the input names.

{pstd}
Without {cmd:fill}, each {cmd:_id} identifies a two-point segment.
{cmd:_z} contains its contour depth and {cmd:_order} is 1 or 2.
A row with all five output variables missing separates successive segments.
These are not joined contour paths. Plot with
{cmd:line _y _x, cmissing(n)} and do not sort by x.

{pstd}
With {cmd:fill}, each {cmd:_id} identifies a closed polygon clipped from a
grid triangle. Its last coordinate repeats its first; a missing separator follows.
{cmd:_z} contains a band number, not a depth. For K sorted, unique levels,
bands are numbered 1 through K+1: below the first level, between successive levels,
and at or above the last level. Shared boundaries appear in both adjacent
polygons but have zero area; constant triangles on a cut belong to the upper band.
Some bands may be empty.

{pstd}
Plot polygons with {cmd:area _y _x, nodropbase cmissing(n)}, without {cmd:sort}.
When filtering by depth or band, retain separator rows with
{cmd:| missing(_z)} to avoid connecting unrelated pieces.
Use one graph layer per depth/band to choose {cmd:lcolor()} and {cmd:fcolor()}.
Triangle seams may be visible in raster exports; opaque matching polygon edges
help reduce them.

{title:Examples}

{pstd}Load the sandstone sample:{p_end}
{cmd}
    use https://www.stata-press.com/data/r19/sandstone, clear
    rename easting x
    rename northing y
    rename depth z
{txt}
{pstd}Generate and plot contour lines:{p_end}
{cmd}
    isoline x y z, n(60) smooth(.05)
    twoway line _y _x, cmissing(n) lcolor(navy)

    isoline x y z, method(nearest) n(60) smooth(.02) replace
    twoway line _y _x, cmissing(n) lcolor(teal)
{txt}
{pstd}Choose three depth boundaries and generate matching lines and fills:{p_end}
{cmd}
    isoline x y z, levels(7700 7800 7900) n(60) smooth(.05) replace
    isoline x y z, levels(7700 7800 7900) n(60) smooth(.05) fill ///
        genx(fx) geny(fy) genz(band) genid(fid) genorder(forder)

    local colors "ltblue teal orange cranberry"
    local areas
    forvalues k = 1/4 {
        local color : word `k' of `colors'
        local areas `areas' (area fy fx if band == `k' | missing(band), ///
            nodropbase cmissing(n) fcolor(`color') fintensity(100) ///
            lcolor(`color') lwidth(vthin))
    }
    twoway `areas' ///
        (line _y _x if _z == 7700 | missing(_z), cmissing(n) lcolor(navy)) ///
        (line _y _x if _z == 7800 | missing(_z), cmissing(n) lcolor(brown)) ///
        (line _y _x if _z == 7900 | missing(_z), cmissing(n) lcolor(maroon)), ///
        legend(order(1 "< 7700" 2 "7700 to 7800" ///
            3 "7800 to 7900" 4 ">= 7900"))
{txt}

{title:Stored results}

{pstd}{cmd:isoline} stores the following in {cmd:r()}:{p_end}
{synoptset 22}{...}
{synopt:{cmd:r(N)}}Number of complete sampled observations.{p_end}
{synopt:{cmd:r(N_segments)}}Number of line segments; line mode only.{p_end}
{synopt:{cmd:r(N_polygons)}}Number of polygons; fill mode only.{p_end}
{synopt:{cmd:r(N_bands)}}Number of possible bands, including empty ones; fill mode only.{p_end}
{synopt:{cmd:r(n)}}Grid points per axis.{p_end}
{synopt:{cmd:r(smooth)}}Gaussian bandwidth fraction.{p_end}
{synopt:{cmd:r(power)}}IDW distance power; IDW only.{p_end}
{synopt:{cmd:r(levels)}}Sorted, unique contour depths or band boundaries.{p_end}
{synopt:{cmd:r(method)}}{cmd:idw} or {cmd:nearest}.{p_end}
{synopt:{cmd:r(smoothing)}}{cmd:none} or {cmd:gaussian}.{p_end}
{synopt:{cmd:r(geometry)}}{cmd:line} or {cmd:fill}.{p_end}
{p2colreset}{...}

{pstd}
If no geometry can be generated, the command reports an error without replacing
existing outputs. Check levels, grid resolution, and smoothing.

{title:Package details}

Version      : {bf:isoline} v1.1 in {stata help graphfunctions:graphfunctions}
This release : 06 Nov 2026
First release: 06 Nov 2026
Repository   : {browse "https://github.com/asjadnaqvi/stata-graphfunctions":GitHub}
License      : {browse "https://opensource.org/licenses/MIT":MIT}
Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}

{title:Feedback}

{pstd}
Please report bugs and feature requests on
{browse "https://github.com/asjadnaqvi/stata-graphfunctions/issues":GitHub}.

{title:Also see}

{psee}{helpb graphfunctions}, {helpb catspline}, {helpb twoway_contour},
{helpb twoway_contourline}.
