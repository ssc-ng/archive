{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid_pretest" "help cdid_pretest"}{...}
{vieweralsosee "cdid_load" "help cdid_load"}{...}
{viewerjumpto "Syntax" "cdid_pretest_load##syntax"}{...}
{viewerjumpto "Description" "cdid_pretest_load##description"}{...}
{viewerjumpto "Options" "cdid_pretest_load##options"}{...}
{viewerjumpto "Examples" "cdid_pretest_load##examples"}{...}
{viewerjumpto "Stored results" "cdid_pretest_load##results"}{...}
{title:Title}

{p2colset 5 26 28 2}{...}
{p2col :{cmd:cdid_pretest_load} {hline 2}}Load saved {cmd:cdid_pretest} results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 25 2}
{cmd:cdid_pretest_load} {cmd:using} {it:{help filename}}
[{cmd:,} {opt store(name)} {opt posting(string)} {opt workspace(#)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_pretest_load} restores results saved with the {opt saving()} option
of {helpb cdid_pretest} and returns them in {cmd:r()}, exactly as
{cmd:cdid_pretest} did, except the callback information {cmd:r(callback)},
{cmd:r(payload)}, and {cmd:r(n_callbacks)}. The data in memory, {cmd:e()}, and the random-number
state are unchanged. A file saved by {helpb cdid} or {cmd:estat} is refused;
load it with {helpb cdid_load}.


{marker options}{...}
{title:Options}

{phang}
{opt store(name)} also keeps the complete results in the Mata object
{it:name}. An existing Mata object is never replaced. {opt store()} is required
with {cmd:posting(state)}.

{phang}
{opt posting(matrix|state)}. {opt matrix} (the default) returns the bootstrap
draws and the tested cells as matrices in {cmd:r()}; loading fails with error
908 if they exceed {cmd:c(max_matdim)}. {opt state} keeps them only in the
{opt store()} object.

{phang}
{opt workspace(#)} limits the memory, in bytes, used to read the file; the
default is {cmd:1073741824} (1 GiB).


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20261116}{p_end}
{phang2}{cmd:. set obs 600}{p_end}
{phang2}{cmd:. generate id = _n}{p_end}
{phang2}{cmd:. generate G = cond(runiform() < .4, 0, cond(runiform() < .5, 2004, 2006))}{p_end}
{phang2}{cmd:. generate x = rnormal()}{p_end}
{phang2}{cmd:. expand 8}{p_end}
{phang2}{cmd:. bysort id: generate year = 2000 + _n}{p_end}
{phang2}{cmd:. generate y = x + .2*(year - 2000) + (G > 0 & year >= G)*(1 + .25*(year - G)) + rnormal()}{p_end}
{phang2}{cmd:. replace y = . if runiform() < .2}{p_end}

{pstd}Save a test and restore it{p_end}
{phang2}{cmd:. tempfile pt}{p_end}
{phang2}{cmd:. cdid_pretest y x, ivar(id) time(year) gvar(G) biters(199) saving(`pt')}{p_end}
{phang2}{cmd:. cdid_pretest_load using `pt'}{p_end}
{phang2}{cmd:. display r(CvMpval)}{p_end}
{phang2}{cmd:. cdid_pretest_load using `pt', store(pt_results) posting(state)}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_pretest_load} returns the results of {helpb cdid_pretest##results:cdid_pretest}, except {cmd:r(callback)}, {cmd:r(payload)}, {cmd:r(n_callbacks)}, and {cmd:r(inactive_options)}, and adds {cmd:r(state_file)}, the file loaded, and, with {cmd:store()}, {cmd:r(state_token)}, the name of the stored object.



{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
