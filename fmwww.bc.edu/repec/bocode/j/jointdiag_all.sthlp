{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag arch" "help jointdiag_arch"}{...}
{vieweralsosee "jointdiag bc" "help jointdiag_bc"}{...}
{viewerjumpto "Syntax" "jointdiag_all##syntax"}{...}
{viewerjumpto "Description" "jointdiag_all##description"}{...}
{viewerjumpto "Options" "jointdiag_all##options"}{...}
{viewerjumpto "Reading the verdict" "jointdiag_all##verdict"}{...}
{viewerjumpto "A suggested workflow" "jointdiag_all##workflow"}{...}
{viewerjumpto "Examples" "jointdiag_all##examples"}{...}

{title:Title}

{phang}
{bf:jointdiag all} {hline 2} The full joint-diagnostic dashboard, with a verdict


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} [{cmd:all}] [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
{cmd:all} is the default subcommand, so {cmd:jointdiag} on its own runs it.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:ags(#)}}AR order throughout; default {cmd:lags(1)}{p_end}
{synopt:{opt archl:ags(#)}}ARCH order throughout; default {cmd:archlags(1)}{p_end}
{synopt:{opt het(varlist)}}the {it:z} variables of the variance function{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}combined three-panel dashboard figure{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:jointdiag all} runs the fast subcommands in one pass, prints every
statistic in a single table, and then writes a short verdict in words.  It is
the right place to start; the verdict tells you which specialised page to open
next.

{pstd}
Seventeen statistics are reported, grouped as:

{p 4 7 2}
{bf:*}  the four Bera{c 150}Jarque directions and their four-way sum;
{p 4 7 2}
{bf:*}  Hall's three information-matrix components plus Bera and Lee's
conditional-heteroskedasticity component;
{p 4 7 2}
{bf:*}  ARCH and autocorrelation, naive and conditioned on each other;
{p 4 7 2}
{bf:*}  bilinearity, the ARCH-plus-bilinear joint test, and Tsai's score test.

{pstd}
The two heavy subcommands, {helpb jointdiag_spec:spec} (bootstrap) and
{helpb jointdiag_bc:bc} (grid maximisation), are {it:not} included; run them
separately when the verdict points that way.


{marker verdict}{...}
{title:Reading the verdict}

{pstd}
The verdict block turns the table into instructions.  Each line that appears
corresponds to a pattern in the numbers:

{p 4 7 2}
{bf:"non-normal residuals"} {c 174} LM_N rejects.  In small samples your t and
F statistics are unreliable; consider a transformation ({helpb jointdiag_bc:bc})
or robust standard errors.

{p 4 7 2}
{bf:"heteroskedasticity"} {c 174} LM_H rejects.  {cmd:regress, robust} or an
explicit variance model.

{p 4 7 2}
{bf:"serial correlation, BUT check the functional form first"} {c 174} LM_I
rejects.  This is the Savin{c 150}White warning: do not reach for
{helpb prais} until {helpb jointdiag_bc:jointdiag bc} has ruled out a
misspecified functional form.

{p 4 7 2}
{bf:"the ARCH signal DISAPPEARS once autocorrelation is allowed"} {c 174} it was
autocorrelation all along.  Model the mean.

{p 4 7 2}
{bf:"the autocorrelation signal DISAPPEARS once ARCH is allowed"} {c 174} the
reverse.  Standard AR tests are invalid under ARCH (Diebold 1986).

{p 4 7 2}
{bf:"ARCH and autocorrelation are BOTH present"} {c 174} fit them jointly with
{helpb arch} and {bf:check the stationarity condition}
{it:w}({&phi}){&Sigma}{&gamma} < 1 reported by
{helpb jointdiag_arch:jointdiag arch}.

{pstd}
If nothing rejects, the block reminds you that four one-directional tests at
level {it:a} have an overall level near 4{it:a}, and points you at
{cmd:jointdiag lm, mcp} for the controlled version.  {cmd:r(nflags)} counts the
lines printed.


{marker workflow}{...}
{title:A suggested workflow}

{p 4 7 2}
{bf:1.}  {cmd:regress} your model, then {cmd:jointdiag all}.

{p 4 7 2}
{bf:2.}  If the functional form or serial correlation is flagged, run
{cmd:jointdiag bc} {it:y} {it:x}{cmd:, rho} and compare {it:C}(.) with
{it:G}(.) before changing anything.

{p 4 7 2}
{bf:3.}  If ARCH is flagged, run {cmd:jointdiag arch} and read Panel B, not
Panel A.

{p 4 7 2}
{bf:4.}  Re-specify the model and fit it, e.g. with {helpb arch}.

{p 4 7 2}
{bf:5.}  Check the new model in {it:both} conditional moments with
{cmd:jointdiag port} and, for a definitive omnibus answer,
{cmd:jointdiag spec}.

{p 4 7 2}
{bf:6.}  Iterate until step 5 is clean.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}
{phang2}{cmd:. jointdiag all}{p_end}

{pstd}Richer alternatives and the combined figure{p_end}
{phang2}{cmd:. jointdiag all, lags(2) archlags(2) graph}{p_end}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(lm_NHIF)}, {cmd:r(p_NHIF)}}the four-directional statistic{p_end}
{synopt:{cmd:r(nflags)}}number of verdict lines printed{p_end}
{synopt:{cmd:r(N)}}observations{p_end}

{pstd}
For the individual statistics, call the subcommands directly; each returns a
full set of {cmd:r()} results.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
