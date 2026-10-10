{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thtvar" "help thtvar"}{...}
{vieweralsosee "thsearch" "help thsearch"}{...}
{vieweralsosee "varsoc" "help varsoc"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thtvarsel##syntax"}{...}
{viewerjumpto "Description" "thtvarsel##description"}{...}
{viewerjumpto "Options" "thtvarsel##options"}{...}
{viewerjumpto "Why all three at once" "thtvarsel##joint"}{...}
{viewerjumpto "Why one fixed sample" "thtvarsel##sample"}{...}
{viewerjumpto "Reading the two tables" "thtvarsel##reading"}{...}
{viewerjumpto "Which criterion" "thtvarsel##which"}{...}
{viewerjumpto "What is NOT provided" "thtvarsel##limits"}{...}
{viewerjumpto "Examples" "thtvarsel##examples"}{...}
{viewerjumpto "Stored results" "thtvarsel##results"}{...}
{viewerjumpto "References" "thtvarsel##refs"}{...}
{title:Title}

{phang}
{bf:thtvarsel} {hline 2} Joint selection of the lag order, the delay and the
threshold for a threshold VAR


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtvarsel} {it:depvarlist} {ifin} [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ps:earch(numlist)}}lag orders to try; default {cmd:psearch(1/4)}{p_end}
{synopt:{opt ds:earch(numlist)}}delays to try; default every delay up to the largest lag{p_end}
{synopt:{opth thv:ar(varname)}}fix the threshold variable instead of searching delays{p_end}
{synopt:{opt ic(string)}}{opt bic} (default), {opt aic}, {opt hqic} or {opt lndet}{p_end}
{synopt:{opt trim(#)}}trimming of each threshold grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap each threshold grid at # points{p_end}
{synopt:{opt minobs(#)}}minimum observations per regime{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt fit}}fit {helpb thtvar} at the selected cell{p_end}
{synopt:{opt graph}}plot the criterion over the (p, d) grid{p_end}
{synopt:{opt saving(filename)}}export that graph{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} and at least two equations are required.
{cmd:thtvarsel} is {helpb return:rclass}; with {opt fit} it also leaves the
{helpb thtvar} estimates in {cmd:e()}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thtvarsel} chooses the three discrete things a threshold VAR needs — the
lag order p, the delay d of the threshold variable, and the threshold
{&gamma} itself — by minimising one information criterion over the whole
(p, d) grid, with {&gamma} profiled out inside each cell.

{pstd}
It also fits the {bf:linear} VAR at every lag order on the same sample and
prints it beside the threshold table, because the first question is not which
threshold model but whether a threshold model is wanted at all.

{pstd}
Official {helpb varsoc} selects a linear VAR's lag order and knows nothing
about regimes. {helpb thtvar} estimates a TVAR at a lag order and delay you
supply. This command fills the gap between them.


{marker options}{...}
{title:Options}

{phang}
{opt psearch(numlist)} lists the lag orders. The largest of them fixes the
estimation sample for {bf:every} cell; see {it:Why one fixed sample}. Twelve
is the hard ceiling, because beyond it the fixed sample is short enough that
the whole table is about the sample rather than about the model.

{phang}
{opt dsearch(numlist)} lists the delays d for which the first variable's lag
y{subscript:1,t-d} is used as the threshold variable — the same convention
{helpb thtvar}{cmd:, delay()} uses. A delay may not exceed the largest lag
order: the threshold variable must not reach further back than the model's own
lags, or the sample would be set by the delay rather than by the model.

{phang}
{opth thvar(varname)} fixes the threshold variable instead. The table then has
one row per lag order and the delay column reads 0. It cannot be combined with
{opt dsearch()}: you have either fixed the timing or asked to search it.

{phang}
{opt ic(bic|aic|hqic|lndet)} is the criterion. {opt lndet} is ln|{&Sigma}|
with {bf:no penalty}, which always prefers the largest model and is there as
a diagnostic, not as a selection rule — if ln|{&Sigma}| is nearly flat across
the grid, nothing is pinned down and the penalised criteria are choosing on
the penalty alone.

{phang}
{opt trim(#)}, {opt gridn(#)} and {opt minobs(#)} control the {&gamma} grid
inside each cell, exactly as in {helpb thtvar}. {opt gridn()} is the option
that controls the running time: the grid is searched once per cell.

{phang}
{opt fit} runs {helpb thtvar} at the selected cell and leaves the estimates in
{cmd:e()}, so {cmd:estat} and {cmd:predict} work afterwards. The command it
runs is printed and returned in {cmd:r(fitcmd)}.

{phang}
{opt graph} plots the criterion against p, one line per delay. A flat surface
is the thing to look for; see {it:Reading the two tables}.


{marker joint}{...}
{title:Why all three at once}

{pstd}
The three choices interact, and selecting them one at a time can land on a
cell that is not the minimiser over any of them.

{pstd}
{bf:A delay that is too long} makes the regime variable nearly uninformative
about the current state. The ln|{&Sigma}| profile over {&gamma} then flattens,
any threshold looks as good as any other, and the cell's criterion looks
respectable because the model has degenerated into something close to a linear
VAR with extra parameters.

{pstd}
{bf:A lag order that is too short} leaves dynamics unmodelled, and the regime
split absorbs them. A threshold then looks necessary when what is missing is a
lag. This is the multivariate version of the error Terasvirta's cycle guards
against by selecting the AR order first, and it is why the linear VAR table is
printed beside the threshold one.

{pstd}
Tsay's (1998) selection is an information criterion minimised over the lag
order, the delay {it:and} the threshold. That is what this command does.


{marker sample}{...}
{title:Why one fixed sample}

{pstd}
Every cell is computed on the observations available at the {bf:largest} lag
order in {opt psearch()}. This is not a convenience: a criterion computed on a
sample that grows as p falls is not comparable across p, and comparing it
anyway reliably selects the smallest p, because dropping a lag adds
observations and almost always lowers n·ln|{&Sigma}| by more than the penalty
it saves.

{pstd}
The consequence to be aware of: raising {opt psearch()} shortens the sample
for {bf:every} row, including the small ones. If the conclusion changes when
you extend the range, that is informative and should be reported — it means
the choice is being driven by the sample rather than by the data's dynamics.

{pstd}
The linear VAR rows use the same fixed sample, so the comparison at the bottom
of the output is a comparison of two models on identical data.


{marker reading}{...}
{title:Reading the two tables}

{pstd}
{bf:1. Start at the bottom.} The difference between the best linear criterion
and the best threshold criterion answers the only question that matters first.
If it is negative the linear VAR wins, and reporting a TVAR means overruling
the criterion — which is allowed, but has to be said out loud and justified on
other grounds.

{pstd}
{bf:2. Look at the spread of the criterion across cells.} If the whole grid is
within a point or two, the specification is not pinned down. Report the range,
pick the cell that is interpretable, and say the data were indifferent. The
{opt graph} option is the quickest way to see this: nearly parallel flat lines
mean the delay does not matter and p is being chosen on the penalty.

{pstd}
{bf:3. Check the split column.} A cell whose regimes are, say, 12 and 400
observations is not two regimes; it is one regime and a handful of outliers.
The criterion will happily choose it if those twelve points are unusual
enough. Look at the split before believing the cell.

{pstd}
{bf:4. Check ln|{&Sigma}| against the penalised criterion.} ln|{&Sigma}| must
fall as p rises — it has no penalty — so if {opt ic(lndet)} prefers a smaller p
than BIC, something is wrong with the sample or the grid. The certification
suite checks exactly that ordering.

{pstd}
{bf:5. Nothing here is a test.} Minimising a criterion over the grid is model
selection. For a p-value refit with {helpb thtvar}{cmd:, test} at the selected
cell, and read the warning it prints — the specification was chosen from the
same data.


{marker which}{...}
{title:Which criterion}

{pstd}
{bf:BIC} is the default. It penalises hardest, and in this setting
over-fitting is the expensive error: an extra lag or a spurious regime split
costs 2·k{subscript:w}·k parameters at once in a two-regime system, and the
resulting model forecasts badly while fitting well.

{pstd}
{bf:AIC} over-selects, systematically and in a way that does not vanish with
the sample. It is the right choice if the purpose is forecasting and you intend
to keep the richer dynamics.

{pstd}
{bf:HQIC} sits between them and is consistent, unlike AIC.

{pstd}
{bf:Run at least two and report whether the choice changed.} They disagree by
construction, and a selection that survives both is worth much more than one
that depends on which criterion was typed.


{marker limits}{...}
{title:What is NOT provided}

{phang}
o {bf:No test.} This is selection. {helpb thtvar}{cmd:, test} has the
sup/ave/exp-LR test with a fixed-regressor bootstrap, and its p-value does not
account for the search done here.

{phang}
o {bf:No search-corrected p-value.} The univariate analogue,
{helpb thsearch}, has one; the multivariate version — a bootstrap that
repeats the whole (p, d, {&gamma}) search in every replication — is not
implemented, and would be expensive.

{phang}
o {bf:One threshold.} The grid is over (p, d, {&gamma}) for a two-regime
model. For more regimes use {helpb thtvar}{cmd:, nthresh()}, whose own
{cmd:e(select)} table covers the number of thresholds at a fixed (p, d).

{phang}
o {bf:The same lag order in both regimes.} A TVAR with different lag orders
per regime is not fitted by {helpb thtvar} and so is not searched here.

{phang}
o {bf:No cointegration.} For a threshold VECM see {helpb thtvecm}; the
selection problem there is different because the cointegrating vector has to
be estimated first.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_rates}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}The default grid, by BIC{p_end}
{phang2}{cmd:. thtvarsel g3month g3year}{p_end}

{pstd}A specific grid, with the surface plotted{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) dsearch(1/3) graph}{p_end}

{pstd}Both criteria, to see whether the choice survives{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) dsearch(1/3) ic(bic)}{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) dsearch(1/3) ic(aic)}{p_end}

{pstd}Is anything pinned down at all? Look at ln|Sigma| with no penalty{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) dsearch(1/3) ic(lndet)}{p_end}

{pstd}A fixed exogenous threshold variable: only the lag order is searched{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) thvar(L.sspread)}{p_end}

{pstd}Select, fit, and carry on{p_end}
{phang2}{cmd:. thtvarsel g3month g3year, psearch(1/4) dsearch(1/3) fit}{p_end}
{phang2}{cmd:. estat regimes}{p_end}
{phang2}{cmd:. estat girf, horizon(12) reps(500) compare seed(1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thtvarsel} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations on the fixed sample{p_end}
{synopt:{cmd:r(p)}}, {cmd:r(delay)}, {cmd:r(gamma)}the selected cell{p_end}
{synopt:{cmd:r(crit)}}its criterion value{p_end}
{synopt:{cmd:r(crit_linear)}}the best linear criterion{p_end}
{synopt:{cmd:r(p_linear)}}the lag order attaining it{p_end}
{synopt:{cmd:r(gain)}}linear minus threshold: positive favours the threshold{p_end}
{synopt:{cmd:r(n_cells)}}cells searched{p_end}
{synopt:{cmd:r(trim)}}trimming used{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thtvarsel}{p_end}
{synopt:{cmd:r(ic)}}criterion used{p_end}
{synopt:{cmd:r(yvars)}}equations{p_end}
{synopt:{cmd:r(plist)}}, {cmd:r(dlist)}what was searched{p_end}
{synopt:{cmd:r(fitcmd)}}the {cmd:thtvar} command run under {opt fit}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(grid)}}cells x 10: {cmd:p d gamma lndet ll aic bic hqic ngrid n1}{p_end}
{synopt:{cmd:r(linear)}}lag orders x 6: {cmd:p lndet ll aic bic hqic}{p_end}


{marker refs}{...}
{title:References}

{phang}
Tsay, R. S. 1998. Testing and modeling multivariate threshold models.
{it:Journal of the American Statistical Association} 93: 1188-1202.
{browse "https://doi.org/10.1080/01621459.1998.10473779":doi:10.1080/01621459.1998.10473779}.

{phang}
Hubrich, K., and T. Terasvirta. 2013. Thresholds and smooth transitions in
vector autoregressive models. {it:Advances in Econometrics} 32: 273-326.
{browse "https://doi.org/10.1108/S0731-9053(2013)0000031008":doi:10.1108/S0731-9053(2013)0000031008}.

{phang}
Hansen, B. E. 1999. Testing for linearity. {it:Journal of Economic Surveys}
13: 551-576.
{browse "https://doi.org/10.1111/1467-6419.00098":doi:10.1111/1467-6419.00098}.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com
{p_end}


{title:Also see}

{psee}
Manual: {helpb threshkit}, {helpb threshkit_choose}

{psee}
Online: {helpb thtvar}, {helpb thstvar}, {helpb thtvecm},
{helpb thsearch}, {helpb varsoc}
{p_end}
