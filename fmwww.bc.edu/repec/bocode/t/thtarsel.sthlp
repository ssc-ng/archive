{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thselect" "help thselect"}{...}
{vieweralsosee "thsearch" "help thsearch"}{...}
{vieweralsosee "thnregimes" "help thnregimes"}{...}
{vieweralsosee "thtvarsel" "help thtvarsel"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thtarsel##syntax"}{...}
{viewerjumpto "Description" "thtarsel##description"}{...}
{viewerjumpto "Options" "thtarsel##options"}{...}
{viewerjumpto "The one thing that makes this hard" "thtarsel##fixed"}{...}
{viewerjumpto "What a criterion cannot tell you" "thtarsel##limits"}{...}
{viewerjumpto "Reading the output" "thtarsel##reading"}{...}
{viewerjumpto "Examples" "thtarsel##examples"}{...}
{viewerjumpto "Stored results" "thtarsel##results"}{...}
{viewerjumpto "References" "thtarsel##refs"}{...}

{title:Title}

{phang}
{bf:thtarsel} {hline 2} Joint selection of the autoregressive order, the
delay and the number of regimes for a SETAR, with the whole search trace


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thtarsel} {it:depvar} {ifin} [{cmd:,} {it:options}]

{pstd}
The data must be {helpb tsset}.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt maxp(#)}}largest autoregressive order; default 4{p_end}
{synopt:{opt maxd:elay(#)}}largest delay; default {opt maxp()}{p_end}
{synopt:{opt maxr:egimes(#)}}largest number of regimes, 2 to 4; default 2{p_end}
{synopt:{opt lin:ear}}also fit the linear model, as a benchmark in the same table{p_end}
{synopt:{opt trim(#)}}trimming of the threshold grid; default 0.15{p_end}
{synopt:{opt gridn(#)}}cap the number of grid points{p_end}
{synopt:{opt minobs(#)}}minimum observations in a regime{p_end}
{synopt:{opt nocons:tant}}no constant{p_end}
{synopt:{opt det:ail}}print every cell, not only the winners{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thtarsel} chooses the autoregressive order {it:p}, the delay {it:d} and
the number of regimes {it:m} for a self-exciting threshold autoregression
{bf:together}, by an information criterion, and reports the {bf:whole search
trace} rather than only its own answer.

{pstd}
Choosing them one at a time is the usual practice and it is not safe. The
best order depends on how many regimes you allow, because a second regime
can absorb dynamics that a longer lag would otherwise have to carry; and the
best delay depends on both. Fixing {it:p} first, then searching {it:d}, then
testing for a second regime, answers three questions in an order that
changes the answers.

{pstd}
{cmd:thtvarsel} does the same thing for a threshold VAR. This is the
univariate case.


{marker options}{...}
{title:Options}

{phang}
{opt maxp(#)} and {opt maxdelay(#)} bound the search. The delay cannot
exceed the order: a delay larger than the largest autoregressive lag means
the transition variable is not part of the state the model propagates, so
the model is not self-exciting in the usual sense and nothing here would
apply to it. Cells with {it:d} > {it:p} are skipped rather than silently
ranked.

{phang}
{opt linear} adds the linear autoregression to the same table, as {it:m} = 1
regime. {bf:Include it.} Without a linear benchmark the table can only tell
you which threshold model is least bad, and a criterion will always name a
winner — including on linear data. With it, you can see whether any
threshold model beats no threshold model at all.

{phang}
The linear cells are fitted {bf:once} per order, not once per delay, because
the delay does not enter a model with no transition variable. Their delay is
reported as 0. Fitting them once per delay would enter the same model
several times under different labels, which would also put exact ties into
the table and make the reported margin zero.

{phang}
{opt detail} prints every cell with its criteria, and marks which cell each
criterion chose. Use it. See {it:Reading the output}.


{marker fixed}{...}
{title:The one thing that makes this hard, and it is not the search}

{pstd}
An information criterion compares models by fit penalised for size. It is
only a comparison {bf:if every model is fitted to the same observations}.

{pstd}
An autoregression of order {it:p} loses its first {it:p} observations. So a
naive sweep over {it:p} compares a model fitted to {it:n}-1 observations with
one fitted to {it:n}-4 — and because a sum of squared residuals over fewer
observations is smaller almost mechanically, {bf:the smallest order wins by
arithmetic rather than by evidence}. The delay does the same damage, costing
{it:d} observations.

{pstd}
So {cmd:thtarsel} reserves max({opt maxp()}, {opt maxdelay()}) leading
observations {bf:once}, and every cell in the grid is fitted to exactly the
same rows. The number of observations each cell used is printed, and it is
one number, not a column.

{pstd}
This is the single most common way a selection table is made meaningless,
and it is invisible in the output of a procedure that gets it wrong: the
table looks fine and the answer is an artefact.


{marker limits}{...}
{title:What a criterion cannot tell you}

{pstd}
{bf:Whether a threshold exists.} A criterion ranks models; it does not test
anything. Give it linear data and it will still name a winner, and if you
have not included {opt linear} that winner will have a threshold in it. For
the existence question use {helpb thtest} (or {cmd:thtar, test}), which
bootstraps the sup statistic over the whole grid, or {helpb thnregimes},
which tests regime counts against each other.

{pstd}
{bf:Whether the choice was close.} The output reports the {bf:margin} by
which the winner beat the runner-up on BIC, and the range over the whole
grid. A margin under about 2 is not a choice, it is a tie, and the command
says so when it sees one. Report the table in that case, not the winner, and
check that your conclusions survive the runner-up.

{pstd}
{bf:Which criterion to believe.} AIC, BIC and HQIC are all reported because
they disagree in a predictable direction: AIC's penalty does not grow with
the sample, so it over-fits — it will often take a longer lag or an extra
regime that BIC rejects. If they agree, the choice is robust. If they do
not, say which you used and why, and prefer BIC for a parsimonious
description and AIC if the model is for forecasting.

{pstd}
The threshold count is penalised honestly: {it:k} counts {bf:every}
estimated parameter including the thresholds themselves. An implementation
that counted only coefficients would make extra regimes look cheaper than
they are.


{marker reading}{...}
{title:Reading the output}

{pstd}
With {opt detail} each row is one (p, delay, m) cell, and the last column
marks {bf:A} for AIC's choice, {bf:B} for BIC's and {bf:H} for HQIC's.

{pstd}
Three things to look at before the winner:

{phang2}
1. {bf:Is the surface flat?} Compare the BIC range over the grid with the
margin over the runner-up. A wide range and a wide margin means the
criterion really discriminated. A wide range and a narrow margin means
several quite different models fit about equally well.

{phang2}
2. {bf:Do the criteria agree?} If AIC picks a much larger model than BIC,
the extra parameters are buying fit that does not survive a sample-size
penalty.

{phang2}
3. {bf:Did the linear benchmark lose by much?} If you included
{opt linear} and the threshold model wins by less than about 2, the data are
not telling you there is a threshold.


{marker examples}{...}
{title:Examples}

{pstd}Select everything at once, with the linear benchmark and the full
trace{p_end}

{phang2}{cmd:. thtarsel y, maxp(4) maxregimes(2) linear detail}{p_end}

{pstd}Then fit what it chose{p_end}

{phang2}{cmd:. thtar y, ar(1/`=r(p_bic)') delay(`=r(d_bic)')}{p_end}

{pstd}And {it:test} what the criterion only ranked{p_end}

{phang2}{cmd:. thtar y, ar(1/`=r(p_bic)') delay(`=r(d_bic)') test reps(999)}{p_end}

{pstd}Allow three regimes, and a delay shorter than the order{p_end}

{phang2}{cmd:. thtarsel y, maxp(3) maxdelay(2) maxregimes(3) linear detail}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(N)}}observations used by {it:every} cell{p_end}
{synopt:{cmd:r(reserved)}}leading observations reserved to make that possible{p_end}
{synopt:{cmd:r(n_cells)}}cells searched{p_end}
{synopt:{cmd:r(p_aic)}, {cmd:r(d_aic)}, {cmd:r(m_aic)}}AIC's choice{p_end}
{synopt:{cmd:r(p_bic)}, {cmd:r(d_bic)}, {cmd:r(m_bic)}}BIC's choice{p_end}
{synopt:{cmd:r(p_hqic)}, {cmd:r(d_hqic)}, {cmd:r(m_hqic)}}HQIC's choice{p_end}
{synopt:{cmd:r(bic_margin)}}by how much BIC's winner beat the runner-up{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:r(depvar)}}the series{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thtarsel}{p_end}

{pstd}Matrices{p_end}
{synopt:{cmd:r(table)}}one row per cell: p, delay, m, ssr, ln sigma2, k, aic, bic, hqic{p_end}

{pstd}
Note that {cmd:r(m_*)} is the number of {bf:regimes}, not the number of
thresholds — so a two-regime model reports 2, and the linear benchmark
reports 1.


{marker refs}{...}
{title:References}

{phang}
Tsay, R. S. 1989. Testing and modeling threshold autoregressive processes.
{it:Journal of the American Statistical Association} 84: 231-240.
{browse "https://doi.org/10.1080/01621459.1989.10478760":doi:10.1080/01621459.1989.10478760}

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based
inference in single and multiple threshold models.
{it:Journal of Econometrics} 110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}

{phang}
Tong, H. 1990. {it:Non-linear Time Series: A Dynamical System Approach}.
Oxford: Oxford University Press.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com


{title:Also see}

{psee}
Fit what it chooses: {helpb thtar}{break}
Let the regimes have DIFFERENT orders: {helpb thsubtar}{break}
Test what it only ranks: {helpb thtest}, {helpb thnregimes}{break}
Choose the threshold VARIABLE: {helpb thsearch}{break}
Thresholds only, design fixed: {helpb thselect}{break}
The multivariate case: {helpb thtvarsel}{break}
Which command at all: {helpb threshkit_choose}
{p_end}
