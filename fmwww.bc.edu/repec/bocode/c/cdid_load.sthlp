{smcl}
{* *! version 1.0.0.0  16nov2026}{...}
{vieweralsosee "cdid" "help cdid"}{...}
{vieweralsosee "cdid_pretest_load" "help cdid_pretest_load"}{...}
{viewerjumpto "Syntax" "cdid_load##syntax"}{...}
{viewerjumpto "Description" "cdid_load##description"}{...}
{viewerjumpto "Options" "cdid_load##options"}{...}
{viewerjumpto "Examples" "cdid_load##examples"}{...}
{viewerjumpto "Stored results" "cdid_load##results"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:cdid_load} {hline 2}}Load saved {cmd:cdid} results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cdid_load} {cmd:using} {it:{help filename}} [{cmd:,} {opt posting(string)} {opt workspace(#)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:cdid_load} restores results saved with the {opt saving()} option of
{helpb cdid} or of {cmd:estat}, in chained or ordinary mode, and posts them in
{cmd:e()}. The data used for estimation are not needed: after loading, you can
replay the results by typing {cmd:cdid}, aggregate them with {cmd:estat} (if
the influence functions were saved), and use {helpb cdid_plot},
{helpb cdid_export}, and {helpb cdid_diagnostics}.

{pstd}
Loading reproduces the saved estimates, standard errors, and intervals
exactly; nothing is re-estimated and no random numbers are drawn. The data in
memory, {cmd:r()}, and the random-number state are unchanged. The numerical
results and the settings of the fit are restored. {cmd:e(cmdline)} holds the
original {cmd:cdid} command, including after loading an aggregation.
If the file lacks the original command line, {cmd:e(cmdline)} holds the
{cmd:cdid_load} command. {cmd:e(state_file)} names the file.
{cmd:e(sample)} is not set, and {cmd:e(missing_reference)} and
{cmd:e(reference_status)} are set only when the saved fit restricted some
comparisons under {cmd:missingreference(exclude)}. Reports kept with {opt keepnuisance} are restored with the results,
and so is the information used by {helpb cdid_chain} when the file was saved
by {cmd:cdid}; files saved by {cmd:estat} do not contain it. Results of
{cmd:cdid} with {opt dvar()} cannot be saved.


{marker options}{...}
{title:Options}

{phang}
{opt posting(matrix|state)}. {opt matrix} (the default) posts the estimates in
{cmd:e(b)} and their covariance in {cmd:e(V)}; loading fails with error 908 if
there are more estimates than {cmd:c(max_matdim)} allows. {opt state} loads the
complete results without posting {cmd:e(b)} and {cmd:e(V)}.

{phang}
{opt workspace(#)} limits the memory, in bytes, used to read the file; the
default is {cmd:1073741824} (1 GiB). A larger file is refused with error 908.


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

{pstd}Save a fit and an aggregation, then restore them without the data{p_end}
{phang2}{cmd:. tempfile fit dyn}{p_end}
{phang2}{cmd:. cdid y x, ivar(id) time(year) gvar(G) bstrap(0) cband(0) saving(`fit')}{p_end}
{phang2}{cmd:. estat dynamic, saving(`dyn')}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. cdid_load using `fit'}{p_end}
{phang2}{cmd:. estat group}{p_end}
{phang2}{cmd:. cdid_load using `dyn'}{p_end}
{phang2}{cmd:. cdid_plot}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cdid_load} posts the results listed in {helpb cdid##results:cdid} and {helpb cdid_postestimation##results:cdid postestimation} as they were saved. It restores the numerical results and the settings of the fit. {cmd:e(cmdline)} holds the original cdid command for a saved fit or aggregation, or the cdid_load command if the file lacks the original command line. {cmd:e(state_file)} names the file. {cmd:e(sample)} is unset, and {cmd:e(missing_reference)} and {cmd:e(reference_status)} are set only when the saved fit restricted some comparisons under missingreference(exclude).



{title:Author}

{pstd}
David Benatia, HEC Montréal{break}
david.benatia@hec.ca
