{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{vieweralsosee "tvtlr" "help tvtlr"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvtboundary" "help tvtboundary"}{...}
{vieweralsosee "tvtexport" "help tvtexport"}{...}
{viewerjumpto "Syntax" "tvtsel##syntax"}{...}
{viewerjumpto "Description" "tvtsel##description"}{...}
{viewerjumpto "What it runs, and in what order" "tvtsel##steps"}{...}
{viewerjumpto "Options" "tvtsel##options"}{...}
{viewerjumpto "How to read the recommendation" "tvtsel##reading"}{...}
{viewerjumpto "What it cannot do" "tvtsel##limits"}{...}
{viewerjumpto "Examples" "tvtsel##examples"}{...}
{viewerjumpto "Stored results" "tvtsel##results"}{...}
{viewerjumpto "References" "tvtsel##references"}{...}
{viewerjumpto "Author" "tvtsel##author"}{...}
{title:Title}

{phang}
{bf:tvtsel} {hline 2} Which TVTHRESH specification does this dataset call
for?


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtsel} {depvar} [{it:indepvars}] {ifin}{cmd:,}
{opth thr:eshvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth thr:eshvar(varname)}}required: the threshold variable
{it:q_t}{p_end}
{synopt :{opth z:vars(varlist)}}candidate variables that might move the
threshold{p_end}
{synopt :{opt reps(#)}}bootstrap replications for the F1 and F2 tests;
default 0, which skips them{p_end}
{synopt :{opt trim(#)}}trimming passed to the tests it runs; default
0.15{p_end}
{synopt :{opt ngrid(#)}}threshold grid passed to {helpb tvtfourier};
default 9, deliberately coarse{p_end}
{synopt :{opt simreps(#)}}simulation draws for {helpb tvtboundary}'s score
test; default 200{p_end}
{synopt :{opt quick}}skip every step that needs a bootstrap{p_end}
{synopt :{opt nodet:ail}}omit the footer saying which command produced
each number{p_end}
{synopt :{opt nocons:tant}}passed through to the tests{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{it:indepvars} is optional. With none, the series is treated as univariate
and {helpb tvtlr} becomes available.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtsel} runs this library's own diagnostics on your data, in order,
and reports a ranked list of the specifications they point to, with the
evidence attached to each line.

{pstd}
{bf:It implements no estimator and replicates no paper.} Every number it
reports is produced by one of the library's own commands and it says which.
It fits nothing itself, and it leaves your own {cmd:e()} exactly as it found
it.

{pstd}
The companion is {helpb tvthresh_choose}, which is the same decision
problem set out in prose, with the reasoning you cannot get from a test.
Read that too; this command is a starting point, not a verdict.


{marker steps}{...}
{title:What it runs, and in what order}

{phang}
{bf:0. The shape of the data}, free, no estimation. The number of
observations; the number of regressors, flagging the high-dimensional case
when 2{it:p} reaches half the sample; whether {it:depvar} is a non-negative
integer count; and the threshold variable's own AR(1) coefficient, which
separates the cointegrating case from the stationary one.

{phang}
{bf:1. Is the threshold constant?} {helpb tvthomog}. This is the question
the library turns on and the reason {helpb tvthomog} was built first. It is
always run: its critical values are simulated, so it needs no bootstrap.

{phang}
{bf:2. Is there a threshold effect at all?} For a univariate series,
{helpb tvtlr}, whose limit is pivotal and distribution-free, so it is
nearly free and always run. With regressors the question needs
{helpb tvtfourier}'s F1, which needs a bootstrap, so it runs only when you
give {opt reps()}.

{phang}
{bf:3. Does the threshold move with TIME?} {helpb tvtfourier}'s F2, under
{opt reps()}.

{phang}
{bf:4. Does it move with the variables you nominated?}
{helpb tvtboundary}'s score test, when {opth zvars(varlist)} is given.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is required. It may not also appear in
{it:indepvars} or in {opt zvars()}.

{phang}
{opth zvars(varlist)} nominates the variables you think might move the
threshold. Without it, step 4 cannot run and the covariate-driven family
cannot be ranked {hline 2} the command will say so rather than quietly
leaving it out.

{phang}
{opt reps(#)} turns on the bootstrap tests. The default of 0 keeps the
command fast but means F1 and F2 are not computed, and the output says so.
{bf:Use at least 399 for a result you would report.}

{phang}
{opt ngrid(#)} defaults to 9 rather than {helpb tvtfourier}'s own 15. That
is deliberate: here the threshold estimate is a means to a test, not the
answer, and the bootstrap re-runs the search on every replication. Raise it
if you intend to read the threshold path.

{phang}
{opt quick} skips every bootstrap step whatever {opt reps()} says. Useful
for a first look at a large dataset.


{marker reading}{...}
{title:How to read the recommendation}

{pstd}
Three warnings are printed with every run, and they are not boilerplate.

{phang}
{bf:A non-rejection is not evidence of a constant threshold.} The power of
these tests against a {it:step} change is low. From {helpb tvtfourier}'s own
source paper, the power to detect a non-constant threshold at
{it:T} = 100 is about 0.21 when the change is a single abrupt shift, and
still only 0.57 at {it:T} = 500. If the mechanism you have in mind is a
dated event, a non-rejection here tells you very little.

{phang}
{bf:A rejection does not tell you which family.} The three ways a threshold
can move {hline 2} with time, with its own past, with other variables
{hline 2} are not nested. A test built for one rejects when a different one
is true. When two or more reject, the command says so explicitly and tells
you the numbering is not a ranking between them, because it is not.

{phang}
{bf:The diagnostics can disagree, and that is reported rather than
resolved.} {helpb tvthomog} not rejecting while F2 or the score test does is
a common and informative pattern: the tests have different alternatives and
different power. The command prints a note and asks you to treat the
evidence as mixed, rather than silently picking whichever answer came last.

{pstd}
In testing, a Fourier-moving threshold at {it:T} = 200 gave
{helpb tvthomog} a CT of 0.41 against a 95% critical value of 0.75
{hline 2} no rejection {hline 2} while F2 on the same data was 504 with a
bootstrap p-value of 0.000. That is exactly the pattern the note is for,
and it is why {opt reps()} is worth paying for.


{marker limits}{...}
{title:What it cannot do}

{phang}
{bf:It cannot rank a family you gave it no way to test.} Without
{opt zvars()} the covariate-driven family is untested; the threshold
variable's own past ({helpb tvtcotar}, {helpb tvtcotrk}) has no test here at
all and is suggested in prose only.

{phang}
{bf:It cannot test the two unimplemented families.} A count dependent
variable points at {cmd:tvtinar} and a latent threshold at
{cmd:tvtlatent}; both are recommended when the data suggests them and both
are reported as not yet implemented.

{phang}
{bf:It gives no p-value for the constant-threshold test.}
{helpb tvthomog} and {helpb tvtlr} both have nonstandard limits and report
simulated critical values, so {cmd:tvtsel} reports the statistic against
the critical value, not a p-value.

{phang}
{bf:It is not a substitute for looking at the data.} Plot the threshold
variable and the fitted path with {helpb tvtplot} before you commit.


{marker examples}{...}
{title:Examples}

{pstd}A first look, no bootstrap, a few seconds{p_end}
{phang2}{cmd:. tvtsel y x1 x2, threshvar(q)}{p_end}

{pstd}The version you would report, with the bootstrap tests{p_end}
{phang2}{cmd:. tvtsel y x1 x2, threshvar(q) reps(399)}{p_end}

{pstd}Nominating the variables you think move the threshold{p_end}
{phang2}{cmd:. tvtsel y x1 x2, threshvar(q) zvars(z1 z2) reps(399)}{p_end}

{pstd}A univariate series, where {helpb tvtlr} is available{p_end}
{phang2}{cmd:. tvtsel y, threshvar(L.y) reps(399)}{p_end}

{pstd}Acting on what it returns{p_end}
{phang2}{cmd:. quietly tvtsel y x1 x2, threshvar(q) reps(399)}{p_end}
{phang2}{cmd:. display "`r(primary)'"}{p_end}
{phang2}{cmd:. if r(CT_reject) | r(p_F2) < 0.05 tvtfourier y x1 x2, threshvar(q) reps(399)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtsel} is {cmd:rclass} and stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(p)}}number of regressors besides the threshold{p_end}
{synopt:{cmd:r(nz)}}number of nominated threshold movers{p_end}
{synopt:{cmd:r(iscount)}}1 if {it:depvar} is a non-negative integer{p_end}
{synopt:{cmd:r(hidim)}}1 if 2{it:p} reaches half the sample{p_end}
{synopt:{cmd:r(rho)}}the threshold variable's AR(1) coefficient{p_end}
{synopt:{cmd:r(i1)}}1 if that coefficient is near one{p_end}
{synopt:{cmd:r(CT)}}{helpb tvthomog}'s statistic{p_end}
{synopt:{cmd:r(CT_cv)}}its critical value{p_end}
{synopt:{cmd:r(CT_reject)}}1 if a constant threshold is rejected{p_end}
{synopt:{cmd:r(Z)}}{helpb tvtlr}'s statistic, univariate case{p_end}
{synopt:{cmd:r(Z_reject)}}1 if a threshold effect is found{p_end}
{synopt:{cmd:r(F1)}}, {cmd:r(p_F1)}, {cmd:r(F2)}, {cmd:r(p_F2)}{p_end}
{synopt:{cmd:r(score)}}, {cmd:r(score_reject)}{p_end}
{synopt:{cmd:r(n_rec)}}lines in the recommendation{p_end}
{synopt:{cmd:r(n_family)}}how many families' tests rejected{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:tvtsel}{p_end}
{synopt:{cmd:r(primary)}}the top recommendation{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(indepvars)}, {cmd:r(threshvar)},
{cmd:r(zvars)}{p_end}
{p2colreset}{...}

{pstd}
Anything that was not computed comes back as missing, not as zero.


{marker references}{...}
{title:References}

{pstd}
{cmd:tvtsel} implements nothing of its own. The commands it runs cite their
own sources: {helpb tvthomog}, {helpb tvtlr}, {helpb tvtfourier} and
{helpb tvtboundary}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
