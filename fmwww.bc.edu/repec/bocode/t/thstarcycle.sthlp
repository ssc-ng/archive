{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "thstar" "help thstar"}{...}
{vieweralsosee "thsearch" "help thsearch"}{...}
{vieweralsosee "thnltest" "help thnltest"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thstarcycle##syntax"}{...}
{viewerjumpto "Description" "thstarcycle##description"}{...}
{viewerjumpto "Options" "thstarcycle##options"}{...}
{viewerjumpto "The seven steps, and why the order matters" "thstarcycle##steps"}{...}
{viewerjumpto "When the cycle stops at step 3" "thstarcycle##stop"}{...}
{viewerjumpto "LSTAR or ESTAR" "thstarcycle##family"}{...}
{viewerjumpto "What the p-values do and do not mean" "thstarcycle##pvalues"}{...}
{viewerjumpto "What is NOT provided" "thstarcycle##limits"}{...}
{viewerjumpto "Examples" "thstarcycle##examples"}{...}
{viewerjumpto "Stored results" "thstarcycle##results"}{...}
{viewerjumpto "References" "thstarcycle##refs"}{...}
{title:Title}

{phang}
{bf:thstarcycle} {hline 2} Terasvirta's specification cycle for a smooth
transition autoregression, run end to end


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thstarcycle} {it:varname} {ifin} [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt maxar(#)}}largest AR order considered; default {cmd:maxar(6)}{p_end}
{synopt:{opt aric(string)}}{opt aic} (default), {opt bic} or {opt hqic}{p_end}
{synopt:{opt delay(numlist)}}delays to try as the transition variable; default {cmd:1/maxar}{p_end}
{synopt:{opth cand:idates(varlist)}}further candidate transition variables{p_end}
{synopt:{opt alpha(#)}}significance level for every decision; default 0.05{p_end}
{synopt:{opt ord:er(#)}}order of the Taylor expansion, 1 to 3; default 3{p_end}
{synopt:{opt type(string)}}override the family the cycle selects{p_end}
{synopt:{opt ng:amma(#)}}, {opt nc(#)}starting-value grid passed to {helpb thstar}{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt nofit}}stop after step 4 and print the command to run{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset}. {cmd:thstarcycle} is {helpb return:rclass}, and
unless {opt nofit} is given it {bf:leaves the fitted} {helpb thstar}
{bf:estimates in} {cmd:e()}, so {cmd:estat}, {cmd:predict} and
{helpb thforecast} all work afterwards.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thstarcycle} runs Terasvirta's (1994) seven-step specification procedure
for a smooth transition autoregression: choose the AR order, test linearity,
choose the transition variable, choose between the logistic and exponential
families, estimate, evaluate, and report.

{pstd}
Each step already exists in THRESHKIT as a separate command. What this one adds
is that it runs them {bf:in the right order}, stops where the procedure says to
stop, and prints the whole trail rather than only the winner — including the
exact {helpb thstar} command it ran, so that the result can be reproduced one
command at a time.

{pstd}
The report is deliberately long. A specification cycle is a sequence of
decisions, and a reader who cannot see the decisions cannot judge the model.


{marker options}{...}
{title:Options}

{phang}
{opt maxar(#)} is the largest AR order considered. It also fixes the estimation
sample: every information criterion in step 1 is computed on the observations
available at {opt maxar()}, because a criterion computed on a sample that grows
as p falls is not comparable across p — and comparing it anyway reliably
selects the smallest p. Raising {opt maxar()} therefore shortens the sample for
every row of the table, which is the honest trade-off.

{phang}
{opt aric(aic|bic|hqic)} is the criterion that picks the AR order. AIC
over-selects and BIC under-selects in small samples; in this setting
over-selecting is the safer error, because a p that is too {it:small} pushes
omitted dynamics into step 2 and manufactures nonlinearity. If AIC and BIC
disagree, run the cycle at both and report whether the conclusion changed.

{phang}
{opt delay(numlist)} lists the delays d for which y{subscript:t-d} is tried as
the transition variable. The default is every delay up to {opt maxar()}. A
delay cannot exceed {opt maxar()}: the transition variable must not reach
further back than the longest lag the model considers, or the sample would
differ between the test and the model.

{phang}
{opth candidates(varlist)} adds further candidate transition variables — an
exogenous series, a lag of one, a spread. They are tested on exactly the same
footing as the delays, and they appear in the same table.

{phang}
{opt alpha(#)} is the level at which every decision is taken: whether
linearity is rejected in step 3, and which family the H04/H03/H02 sequence
indicates in step 4. It is one option because the decisions are one procedure.

{phang}
{opt order(#)} is the order of the Taylor expansion in the linearity test.
3 is Terasvirta's and the default. Degrees of freedom are the {bf:rank
increase}, not a column count: a self-exciting candidate is itself a
regressor, so the interaction block is rank deficient, and counting columns
would understate every p-value in step 2.

{phang}
{opt type(string)} overrides the family selected in step 4 — use it to fit the
other family when the two selection rules disagree, which the report flags.

{phang}
{opt ngamma(#)} and {opt nc(#)} size the starting-value grid handed to
{helpb thstar}. The concentrated NLS problem is not globally concave, so the
grid matters; enlarge it if {cmd:e(converged)} is 0.

{phang}
{opt nofit} stops after step 4 and prints the {helpb thstar} command the cycle
would have run. Use it when the selection is what you want and the estimation
is expensive, or when you want to modify the command before running it.


{marker steps}{...}
{title:The seven steps, and why the order matters}

{pstd}
{bf:Step 1 — the AR order, on a LINEAR model.} This has to come first. If p is
too small, the omitted dynamics do not disappear: they show up as apparent
nonlinearity, and the linearity test in step 2 rejects for a reason that has
nothing to do with regimes. This is the commonest way to "find" a smooth
transition that is not there, and it is why Terasvirta puts the order first
rather than selecting p and the transition jointly.

{pstd}
{bf:Step 2 — linearity, for every candidate.} The order-3 Taylor LM of
Luukkonen, Saikkonen and Terasvirta (1988). The STAR model's transition
parameters are not identified under the null of linearity, so a Wald or LR test
of them has no standard distribution; expanding the transition function in a
Taylor series around {&gamma} = 0 replaces the unidentified parameters with
polynomial terms whose exclusion {it:is} testable. That is the trick the whole
cycle rests on.

{pstd}
{bf:Step 3 — the transition variable}, chosen by the smallest linearity
p-value (Lundbergh, Terasvirta and van Dijk 2003). If no candidate rejects, the
cycle stops; see the next section.

{pstd}
{bf:Step 4 — the family.} The H04/H03/H02 sequence; see {it:LSTAR or ESTAR}.

{pstd}
{bf:Step 5 — estimation.} Concentrated nonlinear least squares over a
starting-value grid, which is {helpb thstar}. The command the cycle runs is
printed so you can type it yourself.

{pstd}
{bf:Step 6 — evaluation.} The Eitrheim-Terasvirta (1996) tests: no
{it:remaining} nonlinearity, no serial correlation, parameter constancy. These
are LM tests added to the model's {bf:gradient}, which is what makes them tests
of the fitted STAR rather than of a linear model. Failing the
remaining-nonlinearity test means a second transition or a different
transition variable, not a bigger {&gamma}.

{pstd}
{bf:Step 7 — the report.} One table, with the conditional p-values labelled as
such.


{marker stop}{...}
{title:When the cycle stops at step 3}

{pstd}
If no candidate rejects linearity at {opt alpha()}, {cmd:thstarcycle} stops and
says so, and it does not estimate anything. That is the procedure working, not
failing.

{pstd}
The reason it stops rather than fitting anyway: under linearity the transition
parameters {&gamma} and c are {bf:not identified}. A fitted STAR will still
report numbers for them, with standard errors, and the fit will look better
than the linear one simply because it has more parameters. None of it means
anything. The honest output is a linear AR.

{pstd}
What to do next, in order:

{p 8 8 2}
1. {helpb thnltest} — a second opinion from tests built on a different
principle (Keenan, Tsay's arranged autoregression, CUSUM). The Taylor LM can
miss nonlinearity it is not expanded around.{p_end}
{p 8 8 2}
2. {helpb thsearch} — if a {bf:sharp} threshold is plausible. The Taylor LM has
little power against a discontinuity, so "no smooth transition" is not "no
threshold".{p_end}
{p 8 8 2}
3. Re-run at a different {opt maxar()}. If p was over-selected the
nonlinearity may have been absorbed into the lags.{p_end}


{marker family}{...}
{title:LSTAR or ESTAR}

{pstd}
Terasvirta's sequential rule, applied to the chosen candidate:

{p 8 8 2}
reject H04 {&rarr} {bf:LSTAR}{break}
accept H04, reject H03 {&rarr} {bf:ESTAR}{break}
accept H04 and H03, reject H02 {&rarr} {bf:LSTAR}

{pstd}
The reasoning: the exponential transition is {bf:symmetric} about c, so its
Taylor expansion leaves no odd-order term. A significant third-order term is
therefore evidence for the asymmetric logistic function. Economically the
distinction is real: an LSTAR says the dynamics differ between high and low
states, an ESTAR says they differ between the middle and {it:both} extremes.

{pstd}
The report also prints the {bf:minimum-p-value} variant of the rule, and
flags it when the two disagree. That disagreement is a genuine ambiguity in
the data, not a defect: fit both families, compare them on the step-6
evaluation tests and on the shape of the fitted transition
({bf:estat transition}), and report both. Choosing silently on whichever rule
favoured your preferred answer is the thing to avoid.


{marker pvalues}{...}
{title:What the p-values do and do not mean}

{pstd}
Read this before quoting any number from the report.

{pstd}
{bf:Step 2's p-values are a comparison across candidates}, and the smallest of
them is a minimum over the candidate set. It is {bf:not} a valid test of
linearity at the chosen candidate, for exactly the reason {helpb thsearch}
exists: maximising a statistic over a set and then reading off that
statistic's own marginal p-value is anti-conservative. If you need a valid
p-value for "is there any nonlinearity at all", use {helpb thsearch}, whose
bootstrap repeats the search.

{pstd}
{bf:Steps 4 and 6 condition on steps 1 and 3.} The family tests and the
evaluation tests treat the AR order and the transition variable as given, and
they do not account for the fact that both were chosen from the data.

{pstd}
{bf:The cycle is a specification procedure, not a simultaneous test.} That is
how Terasvirta presents it, and it is a perfectly respectable way to build a
model — provided the trail is reported. This command reports the trail. What
it cannot do is turn a sequence of conditional decisions into one
unconditional p-value, and nothing in the literature does.


{marker limits}{...}
{title:What is NOT provided}

{phang}
o {bf:No joint selection.} The AR order, the transition variable and the
family are selected sequentially, not jointly, because that is the procedure.
A joint information criterion over (p, s, family) is not implemented.

{phang}
o {bf:No search-corrected p-value.} See the previous section;
{helpb thsearch} has one.

{phang}
o {bf:No multiple transitions.} The cycle selects one transition function. If
step 6 rejects the no-remaining-nonlinearity test, a second transition may be
needed and must be specified by hand.

{phang}
o {bf:No time-varying STAR.} The Lundbergh-Terasvirta-van Dijk time-varying
variant is not fitted; only their transition-variable rule is used.

{phang}
o {bf:Only the self-exciting and named candidates you supply.} The command
does not go looking for transition variables you did not list.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use threshkit_ur}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}The whole cycle, with defaults{p_end}
{phang2}{cmd:. thstarcycle dy}{p_end}

{pstd}Then carry on from the fit the cycle left in {cmd:e()}{p_end}
{phang2}{cmd:. estat transition}{p_end}
{phang2}{cmd:. thforecast, horizon(12) seed(1)}{p_end}

{pstd}A shorter AR search, BIC, and only the first three delays{p_end}
{phang2}{cmd:. thstarcycle dy, maxar(4) aric(bic) delay(1 2 3)}{p_end}

{pstd}Add an exogenous candidate transition variable{p_end}
{phang2}{cmd:. thstarcycle dy, maxar(4) candidates(L.q L2.q)}{p_end}

{pstd}Select but do not estimate, then run the printed command yourself{p_end}
{phang2}{cmd:. thstarcycle dy, maxar(4) nofit}{p_end}

{pstd}Force the other family when the two rules disagree{p_end}
{phang2}{cmd:. thstarcycle dy, maxar(4) type(estar)}{p_end}

{pstd}A stricter level throughout{p_end}
{phang2}{cmd:. thstarcycle dy, maxar(4) alpha(0.01)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thstarcycle} stores the following in {cmd:r()}, and leaves the fitted
{helpb thstar} results in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations on the common sample{p_end}
{synopt:{cmd:r(p)}}selected AR order{p_end}
{synopt:{cmd:r(n_cand)}}candidates tested{p_end}
{synopt:{cmd:r(cand)}}index of the selected candidate{p_end}
{synopt:{cmd:r(delay)}}its delay, if it is a lag of {it:varname}{p_end}
{synopt:{cmd:r(p_lin)}}its linearity p-value{p_end}
{synopt:{cmd:r(rejected)}}1 if linearity was rejected at {opt alpha()}{p_end}
{synopt:{cmd:r(family)}}1 LSTAR, 2 ESTAR, 0 none indicated{p_end}
{synopt:{cmd:r(family_minp)}}the same by the minimum-p-value rule{p_end}
{synopt:{cmd:r(alpha)}}the level used{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:thstarcycle}{p_end}
{synopt:{cmd:r(candvar)}}name of the selected transition variable{p_end}
{synopt:{cmd:r(candidates)}}all candidate names, in table order{p_end}
{synopt:{cmd:r(familyname)}}{cmd:LSTAR}, {cmd:ESTAR} or {cmd:none indicated}{p_end}
{synopt:{cmd:r(aric)}}the criterion used for the AR order{p_end}
{synopt:{cmd:r(fitcmd)}}the {cmd:thstar} command that was run{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(arsel)}}maxar x 7: {cmd:p ssr ll aic bic hqic k}{p_end}
{synopt:{cmd:r(lintest)}}candidates x 12: {cmd:LM3}, {cmd:H04}, {cmd:H03},
{cmd:H02}, each as (F, df, p){p_end}


{marker refs}{...}
{title:References}

{phang}
Terasvirta, T. 1994. Specification, estimation, and evaluation of smooth
transition autoregressive models. {it:Journal of the American Statistical
Association} 89: 208-218.
{browse "https://doi.org/10.1080/01621459.1994.10476462":doi:10.1080/01621459.1994.10476462}.

{phang}
Luukkonen, R., P. Saikkonen, and T. Terasvirta. 1988. Testing linearity
against smooth transition autoregressive models. {it:Biometrika} 75: 491-499.
{browse "https://doi.org/10.1093/biomet/75.3.491":doi:10.1093/biomet/75.3.491}.

{phang}
Eitrheim, O., and T. Terasvirta. 1996. Testing the adequacy of smooth
transition autoregressive models. {it:Journal of Econometrics} 74: 59-75.
{browse "https://doi.org/10.1016/0304-4076(95)01751-8":doi:10.1016/0304-4076(95)01751-8}.

{phang}
Lundbergh, S., T. Terasvirta, and D. van Dijk. 2003. Time-varying smooth
transition autoregressive models. {it:Journal of Business and Economic
Statistics} 21: 104-121.
{browse "https://doi.org/10.1198/073500102288618810":doi:10.1198/073500102288618810}.

{phang}
van Dijk, D., T. Terasvirta, and P. H. Franses. 2002. Smooth transition
autoregressive models - a survey of recent developments.
{it:Econometric Reviews} 21: 1-47.
{browse "https://doi.org/10.1081/ETC-120008723":doi:10.1081/ETC-120008723}.


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
Online: {helpb thstar}, {helpb thsearch}, {helpb thnltest},
{helpb thforecast}, {helpb thtar}
{p_end}
