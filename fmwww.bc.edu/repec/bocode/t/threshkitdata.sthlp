{smcl}
{* *! version 1.0.0  07oct2026}{...}
{vieweralsosee "threshkit" "help threshkit"}{...}
{viewerjumpto "Syntax" "threshkitdata##syntax"}{...}
{viewerjumpto "Description" "threshkitdata##description"}{...}
{viewerjumpto "Why this is a separate package" "threshkitdata##why"}{...}
{viewerjumpto "The datasets" "threshkitdata##sets"}{...}
{viewerjumpto "Examples" "threshkitdata##examples"}{...}
{viewerjumpto "Author" "threshkitdata##author"}{...}

{title:Title}

{phang}
{bf:threshkitdata} {hline 2} Example datasets and the guided tour for THRESHKIT


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:threshkitdata} [{cmd:,} {opt get}]

{synoptset 16 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt get}}fetch the files into the current directory{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:threshkitdata} reports which of the THRESHKIT example files are in the
current directory, and with {opt get} fetches them. It is a convenience
wrapper around {helpb net get}; the files themselves are what matter.

{pstd}
This package carries four datasets and one guided tour. It is of no use on its
own -- install {helpb threshkit} as well.


{marker why}{...}
{title:Why this is a separate package}

{pstd}
A Stata {cmd:.pkg} file can list at most {bf:100} files, and THRESHKIT's
commands, help pages and compiled Mata library come to exactly 100. The
datasets and the tour therefore could not be listed in the same package, so
they are published here instead. Nothing is missing from {helpb threshkit} as
a result: every command and every help page is in that package and works
without these files. They are needed only to {it:run the examples} in the help
and the tour.

{pstd}
These are {bf:ancillary} files. {cmd:ssc install} never places ancillary files
in the adopath -- that is true of every package that ships data, not something
particular to this one -- so they are fetched into the current directory
instead:

{phang2}{cmd:. ssc install threshkitdata}{p_end}
{phang2}{cmd:. threshkitdata, get}{p_end}

{pstd}
or equivalently {cmd:net get threshkitdata}.


{marker sets}{...}
{title:The datasets}

{synoptset 22 tabbed}{...}
{synopt:{cmd:threshkit_dj.dta}}Durlauf-Johnson cross-country growth, as used by
Hansen (2000). The cross-sectional workhorse: {it:q} is 1960 per-capita GDP{p_end}
{synopt:{cmd:threshkit_kink.dta}}Reinhart-Rogoff US debt and growth, as used by
Hansen (2017) for the regression kink{p_end}
{synopt:{cmd:threshkit_ur.dta}}US unemployment 1959m1-1996m7, as used by Hansen
(1997) for the TAR application{p_end}
{synopt:{cmd:threshkit_rates.dta}}US interest rates 1959m1-1993m2, as used by
Tsay (1998) and by Hansen and Seo (2002) for the multivariate models{p_end}
{synopt:{cmd:threshkit_example.do}}a guided tour over all four, in the order
the questions actually arise{p_end}
{p2colreset}{...}

{pstd}
Each is stored from the {bf:original author's text file} rather than imported
through another language: a CSV round trip through R costs eight significant
digits, which is enough to break a numerical comparison against a published
table.


{marker examples}{...}
{title:Examples}

{pstd}Which files are here?{p_end}
{phang2}{cmd:. threshkitdata}{p_end}

{pstd}Fetch them, then take the tour{p_end}
{phang2}{cmd:. threshkitdata, get}{p_end}
{phang2}{cmd:. do threshkit_example.do}{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help: {helpb threshkit}
{p_end}
