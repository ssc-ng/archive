{smcl}
{* *! version 1.0.0  05oct2026}{...}
{vieweralsosee "thselect" "help thselect"}{...}
{vieweralsosee "thtar" "help thtar"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "thtest" "help thtest"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thsearch##syntax"}{...}
{viewerjumpto "Description" "thsearch##description"}{...}
{viewerjumpto "Options" "thsearch##options"}{...}
{viewerjumpto "Why the ordinary p-value is wrong here" "thsearch##why"}{...}
{viewerjumpto "Which criterion should decide?" "thsearch##criteria"}{...}
{viewerjumpto "Reading the output" "thsearch##reading"}{...}
{viewerjumpto "What is NOT provided" "thsearch##limits"}{...}
{viewerjumpto "Examples" "thsearch##examples"}{...}
{viewerjumpto "Stored results" "thsearch##results"}{...}
{viewerjumpto "References" "thsearch##refs"}{...}
{title:Title}

{phang}
{bf:thsearch} {hline 2} Which threshold variable, and which delay? A search
over candidate threshold variables whose p-value is corrected for the search


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thsearch} {it:depvar} [{it:indepvars}] {ifin}{cmd:,}
[{opth cand:idates(varlist)} {opt delay(numlist)} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Candidate set}
{synopt:{opth cand:idates(varlist)}}named candidate threshold variables{p_end}
{synopt:{opt delay(numlist)}}also try {it:L#.depvar} for each # in the list{p_end}
{synopt:{opth dv:ar(varname)}}lag this variable instead of {it:depvar}{p_end}

{syntab:Search}
{synopt:{opt trim(#)}}trimming of each candidate's grid; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}cap the grid at # quantiles of the candidate{p_end}
{synopt:{opt minobs(#)}}minimum observations on each side of the threshold{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}

{syntab:Test}
{synopt:{opt stat(string)}}{opt sup} (default), {opt ave} or {opt exp}{p_end}
{synopt:{opt vce(string)}}{opt robust} for the heteroskedastic LM, {opt ols} for the F{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 500, {cmd:reps(0)} skips it{p_end}
{synopt:{opt seed(string)}}set the random-number seed{p_end}
{synopt:{opt ord:er(#)}}order of the Taylor linearity test, 0 to 3; default 3{p_end}
{synopt:{opt crit:erion(string)}}{opt ssr} (default), {opt lmp} or {opt stat}{p_end}

{syntab:Reporting}
{synopt:{opt graph}}plot the minimised SSR across candidates{p_end}
{synopt:{opt saving(filename)}}export that graph{p_end}
{synoptline}
{p 4 6 2}
At least one of {opt candidates()} and {opt delay()} is required.{p_end}
{p 4 6 2}
{cmd:thsearch} is {helpb return:rclass}. It estimates nothing: it chooses the
threshold variable, and then you fit the model with {helpb thtar} or
{helpb thregress}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thsearch} answers the question that comes before every threshold model
and is almost never reported: {it:which variable does the regime depend on,
and at which lag?}

{pstd}
It fits, for each candidate {it:q} in turn, the two-regime model

{p 8 8 2}
y{subscript:i} = x{subscript:i}'{bf:b}{subscript:1} 1{c -(}q{subscript:i} {ul:<} {it:g}{c )-}
+ x{subscript:i}'{bf:b}{subscript:2} 1{c -(}q{subscript:i} > {it:g}{c )-} + e{subscript:i}

{pstd}
over a trimmed grid of thresholds {it:g}, and reports for each candidate

{p 8 8 2}
o the minimised sum of squared residuals and the {it:g} that attains it;{p_end}
{p 8 8 2}
o the sup-, ave- or exp-F (or the heteroskedasticity-robust LM) of no
threshold effect in that candidate;{p_end}
{p 8 8 2}
o the order-3 Taylor LM test of linearity against a {it:smooth} transition
in that candidate, which is the statistic the STAR literature uses to pick a
transition variable.{p_end}

{pstd}
It then reports {bf:one further p-value, corrected for the search}, described
next. That correction is the reason this command exists.

{pstd}
Every regressor is regime-varying here, with no invariant block. That is not
a limitation; it is what makes the p-value exact. The observed statistic and
every bootstrap draw are then computed from the identical design, so there is
no convention to be matched up by hand between the two. Fit the model with an
invariant block, using {helpb thregress}{cmd:, invariant()}, once the
threshold variable has been chosen.


{marker options}{...}
{title:Options}

{dlgtab:Candidate set}

{phang}
{opth candidates(varlist)} lists named candidate threshold variables. They
may be time-series operated ({cmd:L.x}, {cmd:D.y}) and may include factor
variables.

{phang}
{opt delay(numlist)} adds {cmd:L1.}{it:depvar}, {cmd:L2.}{it:depvar}, ... for
each integer in the list. This is the SETAR delay {it:d} of Tsay (1989): the
regime of y{subscript:t} is decided by its own past value
y{subscript:t-d}, and {it:d} is a parameter like any other. The data must be
{helpb tsset}.

{phang}
{opth dvar(varname)} lags that variable instead of {it:depvar}, for a TAR
whose threshold variable is the lag of some other series.

{pstd}
{opt candidates()} and {opt delay()} may be combined; the two sets are
searched jointly and the correction covers all of them together.

{dlgtab:Search}

{phang}
{opt trim(#)} drops the extreme # and 1-# quantiles of each candidate from
its grid, so every regime keeps a usable share of the sample. The default
{cmd:trim(0.15)} is Hansen's. Each candidate gets its own grid, because each
has its own distribution.

{phang}
{opt gridn(#)} replaces the distinct values of the candidate by # of its
sample quantiles. Use it when candidates are continuous and n is large; it
speeds every bootstrap replication by the same factor.

{phang}
{opt minobs(#)} forces at least # observations on each side, on top of the
trimming. The binding constraint is always the larger of the two.

{dlgtab:Test}

{phang}
{opt stat(sup|ave|exp)} selects the functional of the pointwise statistic.
{opt sup} is Davies' and Hansen's; {opt ave} and {opt exp} are Andrews and
Ploberger's, which have more power against a small threshold effect and less
against a large one. The choice must be made before looking at the data: it
changes the p-value.

{phang}
{opt vce(robust)} uses the heteroskedasticity-robust LM statistic and a wild
bootstrap in which each observation keeps its own residual scale.
{opt vce(ols)} (the default) uses the homoskedastic F and i.i.d. normal
draws, Hansen's fixed-regressor convention. With real heteroskedasticity the
homoskedastic F rejects far too often, and "a threshold" is then just
changing variance; prefer {opt vce(robust)} unless you have checked.

{phang}
{opt reps(#)} sets the number of bootstrap replications. The default 500
gives a Monte Carlo standard error of about 0.01 on a p-value near 0.1, which
is reported. {cmd:reps(0)} skips the bootstrap and leaves the table as a
ranking with no test; see the warning the command prints.

{phang}
{opt order(#)} is the order of the Taylor expansion in the linearity test:
3 (the default) is Terasvirta's recommendation, 1 the plain LM against a
single-term transition. {cmd:order(0)} skips that test. Degrees of freedom
are {bf:rank-based}: when the candidate is itself a regressor, as it is for
every {opt delay()} candidate, the auxiliary block is rank-deficient and
counting columns would understate the p-value.

{phang}
{opt criterion(ssr|lmp|stat)} records in {cmd:r(criterion)} which rule you
intend to use. All three columns are always printed; this option changes
nothing but the label, by design, because the command should not hide which
criterion produced the answer.

{dlgtab:Reporting}

{phang}
{opt graph} plots the minimised SSR against the candidate. A visibly flat
profile means no candidate is preferred and the search has not identified a
threshold variable, whatever the argmin says.


{marker why}{...}
{title:Why the ordinary p-value is wrong here}

{pstd}
Suppose you try eight candidate threshold variables, keep the one with the
largest sup-F, and report that sup-F's usual bootstrap p-value. Under the
null of no threshold in any candidate, you have taken the maximum of eight
random variables and compared it to the distribution of {it:one} of them. The
p-value is too small, and badly so: with eight roughly independent candidates
a nominal 5% test rejects about a third of the time.

{pstd}
Hansen (1996) defines the statistic for exactly this situation. His equation
(7) takes the supremum over the threshold value {it:and} over an index set D
of candidate threshold variables, and the bootstrap that delivers its
critical values redraws the data and then {bf:repeats the whole search}. That
is what {cmd:thsearch} computes and reports as the search-corrected p-value.

{pstd}
The per-candidate "boot p" column is each candidate's own marginal p-value,
computed from the same draws. It is the right number only for a candidate
fixed a priori, on theoretical grounds, before seeing the data. If you picked
the candidate from this table, that column is not a valid test and the
search-corrected p-value is.

{pstd}
The same logic is why {helpb thtar} prints a warning when {opt delay()} holds
more than one value: a delay chosen by minimising the SSR makes the threshold
test that follows it conditional on a data-dependent choice. Run
{cmd:thsearch} first to get a valid p-value, then fix the delay in
{cmd:thtar} with {cmd:delay(}{it:the chosen d}{cmd:)}.


{marker criteria}{...}
{title:Which criterion should decide?}

{pstd}
{bf:Minimum SSR} is the least-squares answer and the one {helpb thtar} and
{helpb thregress} will reproduce. It is the right criterion when the
transition really is abrupt, and it is consistent for the threshold variable
under the conditions in Hansen (1999).

{pstd}
{bf:Smallest linearity p-value} is the Lundbergh, Terasvirta and van Dijk
(2003) rule, carried over from Terasvirta's (1994) STAR modelling cycle. Use
it when the transition is intended to be {bf:smooth} -- that is, when the
model you will fit is {helpb thstar} or {helpb thstvar}, not {helpb thtar}.
A smooth transition spreads the regime change over many observations, and the
sharp-threshold SSR can then prefer the wrong variable.

{pstd}
{bf:Largest sup-F / sup-LM} is not recommended as a selection rule on its
own. It is the statistic being tested, so selecting on it and then testing it
is the circularity the correction above exists to handle; the column is
printed so that you can see what the search-corrected p-value refers to.

{pstd}
{bf:When they disagree}, say so in the paper. Disagreement between the SSR
and the linearity p-value is informative: it usually means either that the
transition is smooth (so the SSR is the wrong criterion) or that no candidate
is well identified (so neither is). Fit both and report both.


{marker reading}{...}
{title:Reading the output}

{pstd}
Three things to look at, in this order.

{phang}
1. {bf:The search-corrected p-value.} If it is not small, stop. No threshold
variable has been identified and no amount of ranking in the table changes
that. Report the corrected p-value, the candidate set, and the number of
replications.

{phang}
2. {bf:The spread of the SSR column.} A gap of a fraction of a percent
between the best and the second-best candidate means the data do not
distinguish them. Report both, or report the one theory prefers and say the
data were indifferent.

{phang}
3. {bf:Agreement between the criteria.} If argmin SSR and argmin linearity
p-value name the same candidate, the choice is robust to whether the
transition is abrupt or smooth. If they do not, the choice is not.


{marker limits}{...}
{title:What is NOT provided}

{pstd}
Stated so that nothing here is read as more than it is.

{phang}
o {bf:No estimates.} {cmd:thsearch} is a selection tool. Coefficients,
standard errors and the confidence interval for the threshold come from
{helpb thtar} or {helpb thregress} afterwards.

{phang}
o {bf:No invariant block}, deliberately: see {it:Description}.

{phang}
o {bf:One threshold only.} The search is over the threshold {it:variable},
with a single split. For how many thresholds a chosen variable supports, use
{helpb thselect}; for a joint search over the variable and the number of
thresholds, run {cmd:thsearch} first and {cmd:thselect} on the winner, and
note that the second step is then conditional on the first.

{phang}
o {bf:No post-selection inference for the slopes.} The search-corrected
p-value is for the threshold test. The coefficient standard errors reported
by the command you fit afterwards condition on the selected threshold
variable and do not account for the selection. No procedure in the threshold
literature currently does; the honest reporting is to say that the variable
was selected and from which set.

{phang}
o {bf:No multivariate search.} For a TVAR the analogous search is over the
delay and the regime lag order; see {helpb thtvar} and {helpb thselect}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Which lag of the dependent variable splits the sample?{p_end}
{phang2}{cmd:. thsearch dln_inv L.dln_inv L.dln_inc, delay(1/4) reps(499) seed(20261005)}{p_end}

{pstd}Named candidates instead, heteroskedasticity-robust{p_end}
{phang2}{cmd:. thsearch dln_inv L.dln_inv, candidates(L.dln_inc L.dln_consump) vce(robust) reps(499)}{p_end}

{pstd}Both sets at once, with the graph{p_end}
{phang2}{cmd:. thsearch dln_inv L.dln_inv, delay(1/3) candidates(L.dln_inc) reps(499) graph}{p_end}

{pstd}The ranking only, no test (and the command says so){p_end}
{phang2}{cmd:. thsearch dln_inv L.dln_inv, delay(1/6) reps(0)}{p_end}

{pstd}Then fit the model at the chosen delay{p_end}
{phang2}{cmd:. thsearch dln_inv L.dln_inv, delay(1/4) reps(499) seed(20261005)}{p_end}
{phang2}{cmd:. local d = substr("`r(bestvar)'", 2, 1)}{p_end}
{phang2}{cmd:. thtar dln_inv, ar(1) delay(`d') test reps(499)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thsearch} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(n_cand)}}number of candidates searched{p_end}
{synopt:{cmd:r(ssr0)}}sum of squared residuals of the linear model{p_end}
{synopt:{cmd:r(stat_max)}}the maximum of the statistic over all candidates{p_end}
{synopt:{cmd:r(p)}}search-corrected bootstrap p-value{p_end}
{synopt:{cmd:r(p_mcse)}}its Monte Carlo standard error{p_end}
{synopt:{cmd:r(reps)}}replications{p_end}
{synopt:{cmd:r(best)}}index of the argmin-SSR candidate{p_end}
{synopt:{cmd:r(gamma)}}threshold at that candidate's SSR minimum{p_end}
{synopt:{cmd:r(best_lm)}}index of the smallest-linearity-p candidate{p_end}
{synopt:{cmd:r(best_stat)}}index of the argmax-statistic candidate{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thsearch}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}regressors{p_end}
{synopt:{cmd:r(candidates)}}the candidate names, in table order{p_end}
{synopt:{cmd:r(bestvar)}}name of the argmin-SSR candidate{p_end}
{synopt:{cmd:r(bestvar_lm)}}name of the smallest-linearity-p candidate{p_end}
{synopt:{cmd:r(bestvar_stat)}}name of the argmax-statistic candidate{p_end}
{synopt:{cmd:r(statistic)}}which statistic was bootstrapped{p_end}
{synopt:{cmd:r(criterion)}}the criterion you declared{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}candidates x 15; columns {cmd:ssr gamma_ssr supF aveF
expF gamma_F supLM aveLM expLM gamma_LM ngrid nskip LM3 df_LM3 p_LM3}{p_end}
{synopt:{cmd:r(pmarg)}}each candidate's marginal bootstrap p-value{p_end}
{synopt:{cmd:r(bootdist)}}the {cmd:reps} draws of the searched maximum{p_end}


{marker refs}{...}
{title:References}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64: 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}.

{phang}
Hansen, B. E. 1999. Testing for linearity. {it:Journal of Economic Surveys}
13: 551-576.
{browse "https://doi.org/10.1111/1467-6419.00098":doi:10.1111/1467-6419.00098}.

{phang}
Lundbergh, S., T. Terasvirta, and D. van Dijk. 2003. Time-varying smooth
transition autoregressive models. {it:Journal of Business and Economic
Statistics} 21: 104-121.
{browse "https://doi.org/10.1198/073500102288618810":doi:10.1198/073500102288618810}.

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
Tsay, R. S. 1989. Testing and modeling threshold autoregressive processes.
{it:Journal of the American Statistical Association} 84: 231-240.
{browse "https://doi.org/10.1080/01621459.1989.10478760":doi:10.1080/01621459.1989.10478760}.


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
Online: {helpb thselect}, {helpb thtar}, {helpb thregress}, {helpb thtest},
{helpb thstar}, {helpb thnltest}
{p_end}
