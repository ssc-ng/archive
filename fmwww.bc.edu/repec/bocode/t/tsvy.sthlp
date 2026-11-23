{smcl}
{* *! version 1.29  19nov2026}{...}
{vieweralsosee "tsvy (en espanol)" "help tsvy_es"}{...}
{viewerjumpto "Syntax" "tsvy##syntax"}{...}
{viewerjumpto "Description" "tsvy##description"}{...}
{viewerjumpto "Options" "tsvy##options"}{...}
{viewerjumpto "Remarks" "tsvy##remarks"}{...}
{viewerjumpto "Examples" "tsvy##examples"}{...}
{viewerjumpto "Frame layout" "tsvy##frame"}{...}
{viewerjumpto "References" "tsvy##references"}{...}
{viewerjumpto "Author" "tsvy##author"}{...}
{viewerjumpto "Also see" "tsvy##also_see"}{...}
{hline}
{title:Title}

{phang}
{bf:tsvy} {hline 2} Point-estimate table and Wald/Bonferroni/CLD test,
by level of aggregation and year, for complex survey data

{phang}
{it:Version {bf:1.29} (19nov2026)}{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsvy}
{ifin}{cmd:,}
{cmdab:varn:ame(}{it:varname}{cmd:)}
{cmdab:years:(}{it:numlist}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:options}]

{pstd}
where {it:statname} is one of {cmd:mean}, {cmd:total}, {cmd:proportion},
or {cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt varn:ame(varname)}}analysis variable; required. The
numerator, when {cmd:stat(ratio)}{p_end}
{synopt:{opt years(numlist)}}calendar years actually present in {cmd:ANIO_}
in the current data, in ascending order; required{p_end}
{synopt:{opt stat(statname)}}statistic to estimate and test: {cmd:mean},
{cmd:total}, {cmd:proportion}, or {cmd:ratio}; required{p_end}
{synopt:{opt nivel(varlist)}}variables defining the levels of aggregation
to loop over; default is {cmd:nivel(NACIONAL REGION NOMBREDD_)}{p_end}
{synopt:{opt cruce(varname)}}an extra crosscutting variable (for
example, sex, an age group, a land-use type -- anything the table needs
beyond {cmd:nivel()}); if given, every {cmd:nivel()} x {it:cruce} value
combination is estimated and tested separately{p_end}
{synopt:{opt subpop(exp)}}analysis universe, same role as {cmd:subpop()}
on the native {helpb svy} prefix -- see
{help tsvy##remarks_subpop:Remarks: subpop() vs if}. Recommended over
{cmd:[if]} whenever {cmd:cruce()} is also given{p_end}
{synopt:{opt l:evel(#)}}the value of {it:varname} to treat as success;
only matters for {cmd:stat(proportion)}; default is {cmd:level(1)}{p_end}
{synopt:{opt d:enominator(varname)}}denominator variable, so that
{cmd:stat(ratio)} estimates the ratio of {it:varname} to
{it:denominator}; required with {cmd:stat(ratio)}, ignored
otherwise{p_end}
{synopt:{opt expectcats(numlist)}}categories {it:varname} is expected to
take; {cmd:tsvy} stops before estimating anything if the observed
categories do not match exactly{p_end}

{syntab:Estimation}
{synopt:{opt a:lpha(#)}}significance level for confidence intervals and
the Wald/Bonferroni tests; default is {cmd:alpha(0.05)}{p_end}
{synopt:{opt boot(#)}}number of bootstrap replications for the omnibus
F-test; {cmd:boot(0)}, the default, uses the analytic (asymptotic)
computation instead of a bootstrap{p_end}
{synopt:{opt bseed(#)}}random-number seed for the bootstrap, when
{cmd:boot()>0}{p_end}

{syntab:Vs-a-reference (optional)}
{synopt:{opt refyear(#)}}calendar year (one of {cmd:years()}) to use as a
fixed baseline. Adds the {cmd:P_VS_REF}/{cmd:SIG_VS_REF} columns,
comparing EACH year against {cmd:refyear()} (Bonferroni over {it:k}-1
comparisons) -- a DIFFERENT question from {cmd:GRUPO} (all-pairs
CLD){p_end}

{syntab:MMD (optional, off by default)}
{synopt:{opt mmd}}[NOT design-based -- {cmd:mmd_2s} uses only an aweight, no strata/PSU; prefer {opt ksmmd}] also run {cmd:mmd_2s} (a Maximum Mean Discrepancy
two-sample test, {browse "https://ideas.repec.org/c/boc/bocode/s459820.html":ssc install mmd_2s}),
comparing the 2 years named in {cmd:mmdyears()} in each block, and
adding {cmd:P_MMD}/{cmd:EFFECT_MMD} to the accumulator frame. Off by
default: it runs {cmd:mmdboot()}*{cmd:mmdreps()} resamples PER block,
which can be noticeably slower than the rest of {cmd:tsvy} in a call
with many {cmd:nivel()}/{cmd:cruce()} blocks. Requires {cmd:mmdyears()}
and {cmd:mmdweight()}; not supported with {cmd:boot()>0}{p_end}
{synopt:{opt mmdyears(numlist)}}the exact 2 years, both from
{cmd:years()}, that {cmd:mmd} compares -- required if {cmd:mmd} is
given; {cmd:tsvy} stops with a message rather than guessing a pair.
Independent of {cmd:refyear()}: the two options answer different
questions ({cmd:refyear()} is the base year for
{cmd:P_VS_REF}/{cmd:SIG_VS_REF}, a contrast of the survey ESTIMATE
against {it:k}-1 years; {cmd:mmdyears()} is always exactly 2 years,
contrasted on the full unit-level DISTRIBUTION) and need not overlap --
{cmd:mmd} works with no {cmd:refyear()} at all{p_end}
{synopt:{opt mmdweight(varname)}}weight variable passed to {cmd:mmd_2s}
as {cmd:[aweight=}{it:varname}{cmd:]}; required if {cmd:mmd} is given.
{cmd:mmd_2s} is not an {helpb svy} command and does not inherit the
{helpb svyset} weight, so this is asked for explicitly, same as
{cmd:denominator()} for {cmd:stat(ratio)}{p_end}
{synopt:{opt mmdboot(#)}}{cmd:boot()} option passed to {cmd:mmd_2s};
default is {cmd:mmdboot(200)}{p_end}
{synopt:{opt mmdreps(#)}}{cmd:reps()} option passed to {cmd:mmd_2s};
default is {cmd:mmdreps(20)}{p_end}
{synopt:{opt mmdseed(#)}}{cmd:seed()} option passed to {cmd:mmd_2s};
default is {cmd:mmdseed(12345)}{p_end}

{syntab:KSMMD (optional, off by default; design-based)}
{synopt:{opt ksmmd}}run {helpb ksmmd} (Kiefer's k-sample KS statistic and a
k-sample MMD via random Fourier features) comparing the distribution of
{opt varname()} across the years of each block, {it:with the sampling design}:
the year label is permuted at the PSU level (each PSU travels whole, with the
weights of its units), within strata whenever strata mix years. The PSU, strata
and weight are read from {cmd:e()} after the block's {cmd:svy:} -- i.e. from
{helpb svyset}; there is no separate weight option. If no stratum of the block
mixes years (e.g. strata redefined every year), {cmd:tsvy} passes
{cmd:nostratperm} to {cmd:ksmmd} automatically. Adds
{cmd:P_KSMMD_KS}/{cmd:P_KSMMD_MMD} to the accumulator frame. Replaces
{cmd:mmd} when the design matters. Requires {cmd:ksmmd}
(v0.8 or later) and {cmd:boot(0)}. Limits inherited from {cmd:ksmmd}: first
sampling stage only, no fpc, and {opt subpop()} is applied as a plain
{cmd:if} (PSUs left with no observations are dropped){p_end}
{synopt:{opt ksmmdyears(numlist)}}years (from {cmd:years()}) to compare;
default is every year present in the block (k-sample, like {cmd:F_WALD}){p_end}
{synopt:{opt ksmmdreps(#)}}permutations; default {cmd:ksmmdreps(1000)},
minimum 99{p_end}
{synopt:{opt ksmmdseed(#)}}seed; default {cmd:ksmmdseed(12345)}{p_end}
{synopt:{opt ksmmdtype(string)}}{cmd:vspool} (default), {cmd:maxpairwise} or
{cmd:fuse}; see {helpb ksmmd}{p_end}
{synopt:{opt ksmmdfeat(#)}}number of random Fourier features; default
{cmd:ksmmdfeat(200)}{p_end}

{syntab:KWALLIS (optional, off by default)}
{synopt:{opt kwallis}}also run a design-based rank test (Lumley and
Scott, 2013, {it:Biometrika} 100(4):831-842 -- the method behind R's
{cmd:survey::svyranktest()}/{cmd:multiranktest()}) for each block,
adding {cmd:F_KW}/{cmd:P_KW}/{cmd:GRUPO_KW} to the accumulator frame.
Unlike {cmd:mmd}, it reuses the SAME weight already set by
{helpb svyset} (no separate weight option) and adds no real runtime
cost: it is one extra {cmd:svy: mean} call on a derived rank variable,
not a resampling procedure. Requires {cmd:stat(mean)} and not supported
with {cmd:boot()>0}. {bf:Important:} {cmd:F_KW}/{cmd:P_KW} test a
DIFFERENT null hypothesis than {cmd:F_WALD} -- see
{help tsvy##remarks_kwallis:Remarks: kwallis()} before treating them as
interchangeable{p_end}

{syntab:CLDMETODO (default auto since v1.29)}
{synopt:{opt cldmetodo(string)}}which multiplicity adjustment
{cmd:tsvy_core} uses to go from raw pairwise p-values to {cmd:GRUPO} (and
{cmd:GRUPO_KW}, if {cmd:kwallis} is on): {cmd:auto} (default since
v1.29: Bonferroni, and only in blocks with a significant omnibus F and a
single shared letter it escalates bonferroni -> holm -> fdr -> lsd until
the letters separate; the method used is stored in column
{cmd:CLD_METODO}), {cmd:bonferroni} (the previous default), {cmd:holm},
{cmd:fdr}, or {cmd:lsd}. Never changes
the omnibus F or the letter-assignment algorithm itself, only which pairs
count as "not significantly different". See
{help tsvy##remarks_cldmetodo:Remarks: cldmetodo()}{p_end}

{syntab:DFMODE (v1.28)}
{synopt:{opt dfmode(string)}}degrees of freedom used by {cmd:F_WALD}/{cmd:P_WALD},
{cmd:GRUPO} and {cmd:P_VS_REF} in each block: {cmd:subpop} (default; same {it:n-L}
as {cmd:svy, subpop(if block):}), {cmd:kg} (Korn and Graubard 1999, p. 209:
PSUs and strata with block observations only; same as {cmd:dofsubpop}) or
{cmd:full} (design df, behavior of v1.27 and earlier). Point estimates,
standard errors and CVs are unaffected. See
{help tsvy##remarks_dfmode:Remarks: dfmode()}{p_end}

{syntab:Output}
{synopt:{opt frame(name)}}accumulator frame; default is
{cmd:frame(ACUM_ALL)}{p_end}
{synopt:{opt threshold(#)}}CV(%) above which a row is flagged
{cmd:REF_ = "a/"}; default is {cmd:threshold(15)}{p_end}
{synopt:{opt replace}}drop and recreate the accumulator frame instead of
appending to it{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} must exist in the current data; a variable literally named
{cmd:ANIO_} must also exist (the variable {cmd:tsvy} passes internally
as {cmd:over()}). The dataset must already be {helpb svyset}.

{pstd}
{bf:Requires Stata 16.0 or later.} {cmd:tsvy} accumulates its output with
{helpb frame}s ({cmd:frame create}, {cmd:frame }{it:name}{cmd::}), a
feature introduced in Stata 16; it does not run on Stata 14 or 15.

{pstd}
{cmd:tsvy} always leaves exactly one row in {cmd:frame()} per
({cmd:nivel()}, [{cmd:cruce}]) combination seen anywhere in the data,
even when that combination has no usable observations (zero
observations, or too few years to estimate): such a block gets an empty
placeholder row (all columns missing except
{cmd:NIVEL}/{cmd:CATEGORIA}/{cmd:CRUCE}/{cmd:var}) instead of being skipped
outright. This makes the row count predictable for exporting to a fixed
contiguous range in a template after {cmd:reshape wide}, without
re-checking it each time. Applies to the joint path ({cmd:boot()==0})
only.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsvy} builds, in one pass, the table that a researcher working
with repeated cross-sections or panel waves of a complex survey usually
needs: point estimates broken down by level of aggregation (national,
regional, local, ...) and by year, {it:together with} a test of whether
each level's estimate actually changed from year to year. It loops over
every level of aggregation named in {cmd:nivel()}, running the same
omnibus-F/Bonferroni/CLD computation once per (level x
value x [{cmd:cruce} value]) combination, and accumulates one row per
year in a frame that is ready to {cmd:reshape wide} and export -- so the
point-estimate table and the F/Bonferroni/CLD test come from the very
same call, with no separate pass to keep aligned by hand.

{pstd}
{cmd:tsvy} is a companion to
{browse "https://github.com/atalaveracuya/tabsvy":tabsvy}/{cmd:tabsvyexport}
(a separate, general-purpose tool by the same author that follows the
same loop-and-accumulate design, but runs {cmd:svy: + parmby} at each
level instead -- point estimates only, no test across years). If you use
{cmd:tabsvy} and also need to know whether years are significantly
different from each other within each level, {cmd:tsvy} is the same
idea with a Wald/Bonferroni/CLD test added; if you have never used
{cmd:tabsvy}, {cmd:tsvy} stands on its own and needs nothing from
that repository.

{pstd}
{cmd:tsvy} does {it:not} modify or depend on the internal code of
{cmd:tabsvy.ado}. If it proves useful, folding it
into {cmd:tabsvy} itself is a natural next step, but that requires
write access to the {cmd:tabsvy} repository that this command does not
assume.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt varname(varname)} is the single analysis variable: not a
{it:varlist}. To tabulate several variables, call
{cmd:tsvy} once per variable, into the same {cmd:frame()} (see
{help tsvy##examples:Examples}).

{phang}
{opt years(numlist)} lists the real calendar years present in {cmd:ANIO_}
in the {it:current} data, in ascending chronological order -- not assumed
to run 1..k without gaps. {cmd:tsvy} reads the distinct codes actually
in {cmd:ANIO_} via {helpb levelsof} and maps them, by ascending position,
one-to-one onto {cmd:years()}; it stops with an error if the counts do not
match. This mirrors {cmd:tabsvy}'s own {cmd:years()} logic, so a base
missing a year entirely (say, no 2020 round for this
variable) is handled by simply listing the years that {it:are} present,
without decoding {cmd:ANIO_}'s value label.

{phang}
{opt stat(statname)} is the statistic to estimate and test: {cmd:mean},
{cmd:total}, {cmd:proportion}, or {cmd:ratio}.

{phang}
{opt nivel(varlist)} lists the variables whose distinct values define the
levels of aggregation to loop over -- for example, a constant
{cmd:NACIONAL} variable (see {help tsvy##remarks:Remarks}), a region
code, a department code. Default is {cmd:nivel(NACIONAL REGION NOMBREDD_)},
matching {cmd:tabsvy}'s own default and the convention it documents (a
{cmd:NACIONAL} variable equal to 1 for every observation, standing for
"no breakdown"). Every distinct value of every variable in {cmd:nivel()}
gets its own block of rows in the output.

{phang}
{opt cruce(varname)} adds a second crosscutting variable: instead of one
estimation per {cmd:nivel()} value, {cmd:tsvy} estimates once
per ({cmd:nivel()} value, {it:cruce} value) combination, and adds a
{cmd:CRUCE} column to the accumulator frame. It is not limited to any
particular kind of split -- sex, an age group, a land-use category, a
type of activity, whatever the table needs.

{phang}
{opt subpop(exp)} restricts the analysis universe (for example,
{cmd:subpop(elegible == 1 & sin_omision == 1)}), the same role
{cmd:[if]} already plays -- but implemented via the native {cmd:svy,
subpop(if {it:exp})} prefix option instead of an {cmd:[if]} filter, so
it never drops a primary sampling unit from the design's variance
calculation. The leading {cmd:if} is optional --
{cmd:subpop(}{it:exp}{cmd:)} and {cmd:subpop(if }{it:exp}{cmd:)} (the
form {cmd:svy}'s own {cmd:subpop()} requires) are accepted
identically. See {help tsvy##remarks_subpop:Remarks: subpop() vs if}
for why this matters whenever {cmd:cruce()} is also given, and for
what {cmd:tsvy} does to stop the specific mistake that motivated this
option. Not supported together with {cmd:boot()} > 0 (see Remarks).

{phang}
{opt level(#)} is the value of {it:varname} to treat as success, for
{cmd:stat(proportion)}. {opt denominator(varname)} is the denominator
variable for {cmd:stat(ratio)}, required with that statistic.
{opt alpha(#)} is the significance level for confidence intervals and
the Wald/Bonferroni tests.

{phang}
{opt expectcats(numlist)} declares, up front, which categories
{it:varname} should take (for example, {cmd:expectcats(1 2)} for a
dichotomous indicator). If the categories actually observed in the data do
not match exactly, {cmd:tsvy} stops before estimating anything, the
same fail-fast check {cmd:tabsvy} performs with its own
{cmd:expectcats()}.

{dlgtab:Estimation}

{phang}
{opt boot(#)} and {opt bseed(#)} control the bootstrap for the omnibus
F-test (see above). {cmd:boot()>0} requires a PSU {it:and} a stratum
declared in the current {helpb svyset}.

{dlgtab:Output}

{phang}
{opt frame(name)} names the accumulator frame. If it does not already
exist, it is created; existing rows are kept (and new ones appended)
unless {opt replace} is also given.

{phang}
{opt threshold(#)} is the coefficient-of-variation cutoff (in percent)
above which a row's {cmd:REF_} column is set to {cmd:"a/"}, a common flag
for an estimate too imprecise (high sampling variability) to report with
confidence.

{phang}
{opt replace} drops and recreates {cmd:frame()} instead of appending to
whatever it already holds. Use it on the first call of a sequence (see
{help tsvy##examples:Examples}); omit it on subsequent calls that
should accumulate into the same frame.


{marker remarks}{...}
{title:Remarks and examples}

{pstd}
Remarks are presented under the following headings:

{phang2}{help tsvy##remarks_nacional:The NACIONAL convention}{p_end}
{phang2}{help tsvy##remarks_subpop:subpop() vs if}{p_end}
{phang2}{help tsvy##remarks_limits:Differences from tabsvy, and current limitations}{p_end}
{phang2}{help tsvy##remarks_export:Exporting results}{p_end}

{marker remarks_nacional}{...}
{pstd}{bf:The NACIONAL convention}

{pstd}
{cmd:tsvy}'s default {cmd:nivel()} expects a variable literally named
{cmd:NACIONAL}, constant at 1 for every observation, exactly as
{cmd:tabsvy}'s own README documents ({cmd:gen NACIONAL = 1}). This is what
lets a single {cmd:nivel("NACIONAL REGION NOMBREDD_")} loop produce a
"national" block (one value, no real breakdown) alongside genuine
region/department breakdowns, using the same mechanism for both.

{marker remarks_subpop}{...}
{pstd}{bf:subpop() vs if}

{pstd}
Filtering the analysis universe with {cmd:[if]} and filtering it with
{cmd:subpop()} give the SAME point estimates -- but not always the same
standard error, and the direction of the difference matters. Restricting
with {cmd:[if]} {it:before} estimation can drop entire primary sampling
units (PSUs) from the design: if a stratum happens to have only one
remaining PSU after the filter, Stata's default {cmd:singleunit(missing)}
(or {cmd:singleunit(certainty)}, which silently assigns that stratum zero
variance instead of flagging it) means that stratum's real contribution
to the variance never gets counted. {cmd:subpop()} keeps the FULL design
(every sampled PSU and stratum) for the variance calculation, and only
excludes out-of-subpopulation categories from the final report -- see
West, Berglund & Heeringa (2008), the canonical reference for this exact
mechanism (cited in full below).

{pstd}
This is not a theoretical concern for this package: it is the bug that
motivated {cmd:subpop()} in the first place. A real production script had
{cmd:MUJER==1} inside {cmd:[if]} {it:together with} {cmd:cruce(MUJER)} --
which silently made {cmd:cruce()} a no-op, since {cmd:touse} (built from
{cmd:[if]}) had already excluded the other group before {cmd:cruce()}
ever got a chance to split by it. Measured on real production tabulations,
the resulting standard error for the minority group (Mujer, roughly 30%
of the weighted universe) was systematically ~6.7% smaller than the
correct value -- confirmed against a Stata-native Monte Carlo simulation
(1,000 replicate samples from a fixed stratified population) that
reproduces the exact mechanism: strata reduced to a single informing PSU
under {cmd:[if]} silently contribute zero variance.

{pstd}
{cmd:subpop()} closes this at the syntax level, not just by relying on
discipline: it is a place SEPARATE from {cmd:[if]} to state the universe,
and {cmd:tsvy} actively checks that neither the {cmd:cruce()} variable nor
any {cmd:nivel()} variable appears as a whole word inside the
{cmd:subpop()} expression -- exiting with an explanation of this exact
mechanism if it does, rather than letting the same mistake resurface
one option later.

{pstd}
Recommended pattern: use {cmd:subpop()} -- not {cmd:[if]} -- to define
who counts at all (for example, a valid-UA flag, a sex-not-omitted
flag), EVEN when that restriction is the same for every {cmd:cruce()}
group. See immediately below for why the two are not reliably
interchangeable, even in that "safe-looking" case. Use
{cmd:cruce()}/{cmd:over()} -- never {cmd:[if]} -- to separate the groups
being compared.

{pstd}
{bf:A universe-only {cmd:[if]} is not a safe shortcut for {cmd:subpop()}.}
When {cmd:[if]} restricts ONLY the universe (the same condition for
every {cmd:cruce()} group, never a value of the group being compared),
{cmd:[if]} and {cmd:subpop(if} {it:same condition}{cmd:)} give the SAME
point estimate, always -- confirmed to double-precision machine epsilon
in every replicate tested so far, including the simulation below. They
do NOT reliably give the same standard error: a universe-only
{cmd:[if]} is exposed to the exact PSU-dropping mechanism described
above, just without the {cmd:cruce()}-inside-{cmd:[if]} error that
motivated this option in the first place. If the restriction happens to
exclude every member of some PSU (or leaves a stratum with a single
surviving PSU), {cmd:[if]} drops that PSU from the design and its
variance contribution is lost; {cmd:subpop()} keeps it. This is rare at
low omission fractions and becomes real as the omitted share grows --
confirmed with a Monte Carlo simulation of 250 replicate
stratified-cluster samples at each of four levels of universe omission
(10%, 20%, 30%, 50% -- 1,000 replicates total): maximum difference in
the point estimate was exactly {cmd:0.0000000000} at all four levels;
maximum difference in the standard error was exactly {cmd:0.0000000000}
at 10%, 20%, and 30%, but {cmd:0.0018270000} at 50% -- roughly 4.5% of
that level's average standard error (0.040686), a real, structural
divergence rather than floating-point noise, appearing exactly where
the mechanism above predicts: at least one replicate's 50%-omission
pattern fully excluded a PSU. See this repository's
{cmd:ejemplo_if_vs_subpop_universo.do} and
{cmd:simulacion_stata_if_vs_subpop_universo.do}. Practical consequence:
use {cmd:subpop()} even for a universe-only restriction -- {cmd:[if]}
often, but not always, gives the same standard error, and there is no
way to tell from the output alone which case you are in.

{pstd}
{cmd:subpop()} is currently supported only when {cmd:boot()} is 0 (the
default, joint {cmd:over()} path -- the one used in production); {cmd:tsvy}
exits with an error if {cmd:subpop()} is combined with {cmd:boot()} > 0,
rather than silently ignoring it.

{marker remarks_mmd}{...}
{pstd}{bf:mmd() performance, and why it is off by default}

{pstd}
Unlike the rest of {cmd:tsvy}'s production path (one {cmd:svy:} call per
{cmd:nivel()} variable, computing every level and year together via
{cmd:over()}, no resampling), {cmd:mmd} runs a SEPARATE {cmd:mmd_2s} call
per ({cmd:nivel()}, {cmd:cruce()}) block, each doing
{cmd:mmdboot()}*{cmd:mmdreps()} resamples of the raw unit-level data. A
call with few blocks (say, {cmd:nivel(NACIONAL)} alone) barely notices;
one with many (for example {cmd:nivel(NOMBREDD_)} crossed with
{cmd:cruce(sexo)}, 24 departments x 2 = 48 blocks) can take
substantially longer than the same call without {cmd:mmd}. This is why
{cmd:mmd} defaults off and must be requested explicitly, and why
{cmd:mmdboot()}/{cmd:mmdreps()} are left adjustable rather than fixed:
lower them for a first pass over many blocks, raise them for a final run
over the few blocks that matter.

{pstd}
{cmd:mmd_2s} is not an {helpb svy} command: it does not use
{helpb svyset}'s design (strata/PSU) at all, so {cmd:subpop()} cannot be
passed to it as a native {cmd:svy, subpop()} prefix the way the rest of
{cmd:tsvy} does. When both {cmd:subpop()} and {cmd:mmd} are given,
{cmd:tsvy} applies the {cmd:subpop()} expression to {cmd:mmd_2s} as a
plain {cmd:[if]} restriction instead -- there is no PSU-loss concern to
avoid here, because {cmd:mmd_2s} was never using the survey design to
begin with. The 2 years compared are exactly the ones named in
{cmd:mmdyears()}, the SAME pair in every block -- {cmd:tsvy} does not
substitute a different year if one of the two is missing from a
particular block; if either year of {cmd:mmdyears()} has no data in that
block, or {cmd:mmd_2s} fails, {cmd:P_MMD}/{cmd:EFFECT_MMD} are simply
left missing for that one block, the same degrade-without-stopping
behavior {cmd:P_VS_REF} already has. See {help tsvy##options:mmdyears()}
for why it no longer defaults to {cmd:refyear()} vs. the last year.

{marker remarks_kwallis}{...}
{pstd}{bf:kwallis(): a different null hypothesis, not a better F_WALD}

{pstd}
{cmd:F_WALD} tests H0: mu_1=...=mu_k -- equality of the {it:k} estimated
survey MEANS. {cmd:kwallis}, even though it is design-based, still tests
the classical Kruskal-Wallis/Wilcoxon null: H0: F_1=...=F_k -- equality
of DISTRIBUTION (stochastic dominance/location), not of means. What
complex sampling changes is only HOW the statistic is computed (a
population rank instead of a sample rank, and design-based variance
instead of the classical distribution-free variance); it does not make
the two tests answer the same question. Do not read a significant
{cmd:F_WALD} with a non-significant {cmd:P_KW} (or vice versa) as a
contradiction -- they can legitimately disagree, because they are
testing different things. {cmd:kwallis} is also not a substitute for
{cmd:mmd}: {cmd:mmd_2s} is a genuinely omnibus test (via kernel mean
embedding, consistent against ANY distributional difference -- shape,
scale, location) but only 2-sample; {cmd:kwallis} is {it:k}-sample, like
{cmd:F_WALD}, but as a rank test has little or no power against a pure
scale/shape difference when the location is the same. The three tests
answer three different questions; none substitutes for the other two.

{pstd}
Method: for each block, the population rank of {opt varname()} is
estimated via the Hajek-weighted empirical CDF (with mid-ranks for
ties), using the SAME weight already set by {helpb svyset} -- pooling
ALL years being compared within that block, so the rank is relative to
the combined population of that block, not to a single year. That rank
is then treated as an ordinary variable for the rest of the pipeline:
{cmd:svy: mean} of the rank, {cmd:over()} the same block x year cells
{cmd:F_WALD} already uses, feeding the same omnibus F/Bonferroni/CLD
engine. This is not an ad-hoc weighting of the classical H statistic --
it is the construction Lumley and Scott (2013) prove is asymptotically
equivalent to using the true (unobserved) population rank, so no new
variance formula is needed: the standard design-based variance of a
domain mean already is the correct variance for this test.

{pstd}
Current scope: {cmd:stat(mean)} only, {cmd:boot()==0} only, no effect
size is reported (the ordinal eta-squared/epsilon-squared formulas used
for the classical, unweighted H statistic do not apply to this
Wald-on-ranks construction, so they are omitted rather than misapplied).
{bf:This option has not been run against real Stata} -- test it on a
small example and sanity-check {cmd:F_KW}/{cmd:P_KW}/{cmd:GRUPO_KW}
before relying on it with production data.

{marker remarks_dfmode}{...}
{pstd}{bf:dfmode(): degrees of freedom of the block}

{pstd}
{cmd:tsvy} estimates all blocks of a {cmd:nivel()} variable with one joint
{cmd:svy: ..., over()} and slices {cmd:e(b)}/{cmd:e(V)} by block. Up to v1.27
the test used the design df ({cmd:e(df_r)} of the joint run) for every block,
which can be orders of magnitude above the df of a small block (for example
15,149 versus 365 for one department). {cmd:svy, subpop(if block):} drops the
strata without block observations, and Korn and Graubard (1999, p. 209)
recommend counting only PSUs and strata with block observations. From v1.28
the default {cmd:dfmode(subpop)} reproduces the df of {cmd:svy, subpop():}, and
{cmd:dfmode(kg)} the Korn-Graubard df. Use {cmd:dfmode(full)} to reproduce older
output. Pairs whose adjusted p-value is close to {cmd:alpha} can change letter.{p_end}

{marker remarks_cldmetodo}{...}
{pstd}{bf:cldmetodo(): alternatives to Bonferroni for GRUPO/CLD}

{pstd}
By default {cmd:tsvy} adjusts each pairwise p-value with a straight
Bonferroni correction ({cmd:p_adj = min(p_raw*npares, 1)}) before deciding
which pairs share a {cmd:GRUPO} letter. {cmd:cldmetodo()} selects a
different adjustment for that one step; it never touches the omnibus
{cmd:F_WALD}/{cmd:F_KW} test or the maximal-subset letter algorithm
itself, both of which are unaffected by this option.

{phang2}o {cmd:auto} (default since v1.29): Bonferroni in every block
where it already separates letters; only when the omnibus F is
significant and Bonferroni leaves all years with the same letter does it
try holm, fdr and lsd, in that order, keeping the first one that
separates. {cmd:CLD_METODO} records each block's method and
{cmd:CLD_INCONS}=1 flags the blocks that do not separate even with
lsd.{p_end}
{phang2}o {cmd:bonferroni}: the default up to v1.28 -- use
{cmd:cldmetodo(bonferroni)} to reproduce earlier results.{p_end}
{phang2}o {cmd:holm}: Holm (1979), {it:Scandinavian Journal of
Statistics} 6(2):65-70 -- a sequential (step-down) procedure that
controls the same familywise error rate as Bonferroni under the same
assumptions, but is uniformly more powerful (it never rejects fewer pairs
than Bonferroni, and sometimes more). There is little reason to prefer
{cmd:bonferroni} over {cmd:holm} except to match results already
published with the plain Bonferroni correction.{p_end}
{phang2}o {cmd:fdr}: Benjamini and Hochberg (1995), {it:JRSS-B}
57(1):289-300 -- controls the {it:false discovery rate} (the expected
proportion of false rejections among the pairs declared different), not
the probability of any single false rejection in the whole family. This
is a different error criterion, not simply a more lenient Bonferroni: it
answers "of the pairs I call different, how many are likely wrong" rather
than "how likely is at least one mistake anywhere".{p_end}
{phang2}o {cmd:lsd}: Fisher's "protected" least significant difference
(Fisher 1935/1937, {it:The Design of Experiments}; the "protected" label
and its Monte Carlo evaluation are from Carmer and Swanson (1973),
{it:JASA} 68(341):66-74; defended explicitly in Saville (1990), {it:The
American Statistician} 44(2):174-180). Pairwise p-values are used
UNADJUSTED against {cmd:alpha()}, and only if the block's omnibus F was
already significant -- if it was not, no pair is declared different (that
omnibus-F gate is the "protection"). This is the option most likely to
show a differing letter when {cmd:F_WALD} (or {cmd:F_KW}) is
significant, but it does so by giving up familywise error control
entirely (it reverts to the per-comparison/comparisonwise error rate).
It is not "better" than {cmd:bonferroni}/{cmd:holm} -- it is a weaker
error guarantee traded for more power, and should be reported as
such.{p_end}

{marker remarks_limits}{...}
{pstd}{bf:Differences from tabsvy, and current limitations}

{phang2}o ({cmd:boot()==0} only) a {cmd:nivel()} x [{cmd:cruce}]
block with data in only ONE year still gets a row, with
{cmd:ESTIMA}/{cmd:ERROR_ST}/{cmd:LIM_INF}/{cmd:LIM_SUP}/{cmd:N_SIN_PON}/
{cmd:N_PONDERA}/{cmd:CV} filled in for that year -- only
{cmd:F_WALD}/{cmd:P_WALD}/{cmd:GRUPO}/{cmd:P_VS_REF}/{cmd:SIG_VS_REF} are
left missing for the whole block, since there is genuinely nothing to
test against with 1 year. This applies only to
the production path ({cmd:boot()==0}); with {cmd:boot()>0}, {cmd:tsvy}
estimates once per block via bootstrap, and that path still
requires at least 2 years of data to run at all -- a block with 1 year
is skipped there with a warning and contributes no rows, same as
always. {cmd:tabsvy} does not have this restriction either way, because
it does not need to compare years against each other.{p_end}
{phang2}o {cmd:tsvy} does not (yet) have {cmd:tabsvy}'s
{cmd:keepcat()}/{cmd:tipo()} options for looping over a thematic block of
several 0/1 indicator variables at once. If a table needs that pattern,
either keep using {cmd:tabsvy} for it, or call {cmd:tsvy} once per
indicator into the same {cmd:frame()} and tag the block yourself (see
{help tsvy##examples:Examples}).{p_end}
{phang2}o {cmd:tsvy} requires the variable it uses internally as
{cmd:over()} to be named exactly {cmd:ANIO_}; it is not configurable.{p_end}
{phang2}o when {cmd:boot()} is
0 (the default), {cmd:tsvy} runs a single joint
{cmd:svy: STAT ..., over(nivel_var [cruce_var] ANIO_)} per {cmd:nivel()}
variable -- the same command you would run by hand to get a reference
table -- instead of filtering to one {cmd:nivel()} (and, if given,
{cmd:cruce()}) value at a time and running {cmd:over(ANIO_)} inside that
filter. This matters whenever a filtered subset can drop entire strata
that happen to have zero observations of that particular value: filtering
first can make the standard error systematically smaller than
the joint-{cmd:over()} reference value (confirmed on real production
data, up to 35% smaller in small/rare {cmd:cruce()} categories), even
though the point estimate matches exactly either way.
{cmd:nivel()} and {cmd:cruce()} (when given) are grouped
{it:together} with {cmd:ANIO_} into a single {cmd:egen group()} variable
and cut from ONE joint {cmd:svy:} call by position, which
works because {cmd:egen group()} sorts ascending by {cmd:nivel()}
first, {cmd:cruce()} second, {cmd:ANIO_} third, so every
({cmd:nivel()}, {cmd:cruce()}) block stays a contiguous range of codes.
This mirrors the design of the companion tool
{cmd:parmby_tdiff.ado} (Talavera Cuya 2026): one {cmd:svy:} call with
every crosscutting variable in {cmd:over()}, sliced by position
afterward, never re-filtered and re-estimated per block -- {cmd:tsvy}
uses {cmd:egen group()} plus {cmd:summarize} rather than
{cmd:parmby_tdiff}'s fixed mod/ceil arithmetic specifically because
{cmd:egen group()} tolerates missing or sparse ({cmd:nivel()},
{cmd:cruce()}) combinations (a department with no observations of some
land-use category, say) without needing a perfectly rectangular cross --
{cmd:parmby_tdiff} instead documents this as a requirement (its
{it:e(b)} column count must divide evenly by the number of years). Only
{cmd:boot()>0} uses the filter-then-{cmd:over(ANIO_)} path,
because it reconstructs resampling replicates per block via bootstrap --
a different mechanism, implementing the identical F-test/Bonferroni/CLD
math and producing identical results either way.{p_end}

{marker remarks_export}{...}
{pstd}{bf:Exporting results}

{pstd}
The accumulator frame that {cmd:tsvy} builds (see
{help tsvy##frame:Frame layout} below) can be written to Excel or Word
with the companion command {helpb tsvyexport}, run afterward on the
same frame. See its own help for syntax and options.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
The script below (setup + examples 1-5) is confirmed running start to
finish without error in real Stata. The leading {cmd:.} before a
single-line command is the command prompt (standard Stata help
convention, not part of the command, and safe to copy as-is); the lines
inside the {cmd:foreach} block in example 3 are shown without it, because
a {cmd:.} left on every line of a multi-line {cmd:foreach}/{cmd:forvalues}
block -- including the body and the closing brace -- breaks Stata's
parsing of the block when pasted into a do-file. Comment lines (starting
with {cmd:*}) need no prompt either way; they are shown here exactly as
you would keep them in your own do-file.

{pstd}
Every example below is self-contained and runs on {cmd:auto.dta}, one of
Stata's built-in example datasets -- {cmd:sysuse auto} is enough, no
external data needed. {cmd:auto.dta} has no real
survey design, so the setup below is the minimal one that lets
{cmd:tsvy} run (each observation as its own PSU). {cmd:auto.dta} also has no
year variable, so {cmd:ANIO_} is fabricated purely to exercise the
over-time mechanics -- in real use, {cmd:ANIO_} and the {cmd:NACIONAL}
convention come from the same setup already used before calling
{cmd:tabsvy} (see its README).

{phang2}{cmd:* Setup}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}

{pstd}
{bf:Example 1: one call, several levels of aggregation.} {cmd:mean} of
{cmd:mpg}, three levels ({cmd:NACIONAL} and both values of {cmd:foreign}),
three years each -- point estimates plus the F/Bonferroni/CLD test across
years, all in one frame, one call:{p_end}
{phang2}{cmd:* Example 1: one call, several levels of aggregation}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL foreign) frame(F1) replace}{p_end}
{phang2}{cmd:. frame F1: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Example 2: {cmd:proportion}}, with {cmd:expectcats()} guarding the
coding of the analysis variable ({cmd:foreign} must take exactly 0/1, or
{cmd:tsvy} stops before estimating anything):{p_end}
{phang2}{cmd:* Example 2: proportion, with expectcats()}{p_end}
{phang2}{cmd:. tsvy, varname(foreign) stat(proportion) level(1) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) expectcats(0 1) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) frame(F2) replace}{p_end}
{phang2}{cmd:. frame F2: list NIVEL CATEGORIA ANIO ESTIMA CV REF_ F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Example 3: {cmd:total}}, several variables accumulated into the same
frame ({cmd:replace} only on the first call -- this is the pattern for
looping {cmd:tsvy} over many analysis variables, the way a real
pipeline loops it over many indicators). Note the {cmd:foreach} block
below has no leading {cmd:.} on any of its lines -- see the note at the
top of this section for why:{p_end}
{phang2}{cmd:* Example 3: total, several variables into the same frame}{p_end}
{phang2}{cmd:local variables mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy, varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        nivel(NACIONAL) frame(F3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:frame F3: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Example 4: a second crosscutting dimension} with {cmd:cruce()} --
here, a price-based split stands in for a real demographic split like
sex (or, in a production table, a real categorical like a land-use
type):{p_end}
{phang2}{cmd:* Example 4: a second crosscutting dimension with cruce()}{p_end}
{phang2}{cmd:. gen byte precio_alto = (price > 6000)}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(precio_alto) frame(F4) replace}{p_end}
{phang2}{cmd:. frame F4: list NIVEL CATEGORIA CRUCE ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA CRUCE)}{p_end}

{pstd}
{bf:Example 5: {cmd:ratio}} -- {opt denominator()} is required, and is a
separate option from {opt varname()} (the numerator), not a
{cmd:num/den} expression:{p_end}
{phang2}{cmd:* Example 5: ratio -- denominator() is a separate option}{p_end}
{phang2}{cmd:. tsvy, varname(trunk) stat(ratio) denominator(length) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) nivel(NACIONAL foreign) frame(F5) replace}{p_end}
{phang2}{cmd:. frame F5: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Example 6: restricting the universe with {cmd:[if]}.} {cmd:tsvy}
takes a leading {cmd:if} exactly like {cmd:svy:} does, applying it to
every estimation the loop makes internally -- it is
not limited to the {cmd:nivel()}/{cmd:cruce()} split. Use it whenever
the estimation should run over a subpopulation rather than the whole
dataset (for example, only the records that pass an eligibility or
quality-control condition upstream). Below, {cmd:rep78} is missing for 5
cars in {cmd:auto.dta}; restricting to {cmd:rep78 < .} drops them from
the universe before estimating, the same way a real pipeline restricts to
records that pass its own filter before calling {cmd:svy: total}:{p_end}
{phang2}{cmd:* Example 6: restricting the universe with [if]}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(weight) stat(total) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) nivel(NACIONAL foreign) frame(F6) replace}{p_end}
{phang2}{cmd:. frame F6: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:This {cmd:if} matters in every call of a loop, not just the first
one.} If your pipeline estimates several indicators, each one under its
own eligibility condition, put that condition on every {cmd:tsvy}
call inside the loop -- {cmd:replace} still belongs only on the first
call, but the {cmd:if} belongs on all of them:{p_end}
{phang2}{cmd:. foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy if elegible == 1 & control_calidad == 0, ///}{p_end}
{phang2}{cmd:        varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        nivel(NACIONAL) frame(F7) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}

{pstd}
The same pattern scales directly to a real complex-survey pipeline: keep
the {cmd:forvalues}/{cmd:foreach} loop from example 3, replace
{cmd:mpg weight length} with your own list of indicator variables, add
the {cmd:if} condition your data actually needs (as in example 6), and
replace {cmd:nivel(NACIONAL foreign)} with whatever aggregation-level
variables your data actually has (a national total plus however many
region/department-type variables apply).{p_end}

{pstd}
{bf:Example 7: {cmd:refyear()} -- comparing every year against ONE base
year.} {cmd:GRUPO} (used in every example above) answers "which years
differ from EACH OTHER" -- all pairs, Bonferroni over {it:k}(k-1)/2
comparisons. {cmd:refyear()} answers a narrower, DIFFERENT question --
"which years differ from THIS ONE base year" -- only {it:k}-1
comparisons, Bonferroni over {it:k}-1 (Dunn 1961) -- and adds
{cmd:P_VS_REF}/{cmd:SIG_VS_REF} to the frame alongside (not instead of)
{cmd:GRUPO}. The two can legitimately disagree on the same data because
they test different families of hypotheses. Below, 2023 is the base
year -- every other year gets a
{cmd:P_VS_REF} p-value against it, and 2023's own row stays missing (a
year is not tested against itself):{p_end}
{phang2}{cmd:* Example 7: refyear() -- vs a base year, not all pairs}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL foreign) refyear(2023) frame(F8) replace}{p_end}
{phang2}{cmd:. frame F8: list NIVEL CATEGORIA ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Example 8: {cmd:refyear()} together with {cmd:cruce()}.}
{cmd:refyear()} works the same with {cmd:cruce()} as without it: with
{cmd:boot()==0} (the default, and also the path
{cmd:cruce()} takes -- see {help tsvy##remarks_limits:Remarks}),
{cmd:tsvy} computes {cmd:P_VS_REF} inline from the same joint
{cmd:e(b)}/{cmd:e(V)} it already sliced for {cmd:GRUPO}/{cmd:F_WALD};
with {cmd:boot()>0} it is estimated once per block instead. Either
way, each ({cmd:nivel()}, {it:cruce}) block gets its own
{cmd:refyear()} baseline check and its own {cmd:P_VS_REF} column:{p_end}
{phang2}{cmd:* Example 8: refyear() + cruce() together}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(precio_alto) refyear(2023) frame(F9) replace}{p_end}
{phang2}{cmd:. frame F9: list NIVEL CATEGORIA CRUCE ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CATEGORIA CRUCE)}{p_end}

{pstd}
{bf:Example 9: {cmd:subpop()} instead of {cmd:[if]}, with
{cmd:cruce()}.} The universe restriction ({cmd:rep78 < .}, the same one
used in example 6) moves from {cmd:[if]} into {cmd:subpop()}; the
{cmd:cruce()} variable ({cmd:foreign}) is never repeated inside
{cmd:subpop()} -- see {help tsvy##remarks_subpop:Remarks} for why {cmd:tsvy}
actively checks for, and refuses, that exact combination.
{cmd:subpop()} accepts either the bare expression or the leading
{cmd:if} exactly as {cmd:svy}'s own {cmd:subpop()} does -- both lines
below are equivalent:{p_end}
{phang2}{cmd:* Example 9: subpop() with cruce()}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(rep78 < .) frame(F10) replace}{p_end}
{phang2}{cmd:. frame F10: list NIVEL CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(NIVEL CATEGORIA CRUCE)}{p_end}
{phang2}{cmd:* equivalent -- native "if" form, also accepted}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(if rep78 < .) frame(F10) replace}{p_end}

{pstd}
{bf:Example 10: a complete, runnable example with {cmd:sysuse
auto}.} No installed data needed -- anyone with Stata can run this end
to end. It builds a small complex-survey design on top of the built-in
{cmd:auto.dta}, uses a condition genuinely present in the data
({cmd:rep78} has 5 missing values, Stata's own repair-record variable)
as the universe restriction, and {cmd:foreign} (already in the data) as
the crosscutting domain -- nothing fabricated:{p_end}
{phang2}{cmd:* Example 10: subpop() with sysuse auto}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen double psu   = ceil(_n/4)}{p_end}
{phang2}{cmd:. gen double strat = ceil(psu/2)}{p_end}
{phang2}{cmd:. gen double wgt   = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], strata(strat) singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,3))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(!missing(rep78)) frame(F11) replace}{p_end}
{phang2}{cmd:. frame F11: list CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(CRUCE)}{p_end}

{pstd}
Cross-check against native {cmd:svy} for one cell (say, {cmd:foreign==1}
in the first synthetic year, coded {cmd:ANIO_==1}): restrict
{cmd:subpop()} to that exact cell too and drop {cmd:over()} entirely --
the two numbers should match:{p_end}
{phang2}{cmd:. svy, subpop(if !missing(rep78) & foreign==1 & ANIO_==1): mean mpg}{p_end}
{phang2}{cmd:. frame F11: list ESTIMA ERROR_ST if CRUCE==1 & ANIO==2021}{p_end}

{pstd}
{bf:Example 11: {cmd:sysuse nlsw88}, with a genuine missing-data
universe.} {cmd:nlsw88} (a well-known teaching dataset on women's wages)
has real missing values in {cmd:wage} for some respondents -- exactly
the kind of nonresponse {cmd:subpop()} is built for, with nothing
invented for the example. The domain being compared is {cmd:union}
membership:{p_end}
{phang2}{cmd:* Example 11: subpop() with sysuse nlsw88}{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. gen double psu   = ceil(_n/6)}{p_end}
{phang2}{cmd:. gen double strat = ceil(psu/2)}{p_end}
{phang2}{cmd:. gen double wgt   = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], strata(strat) singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,2))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(wage) stat(mean) years(2021 2022) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(union) subpop(!missing(wage)) frame(F12) replace}{p_end}
{phang2}{cmd:. frame F12: list CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(CRUCE)}{p_end}

{pstd}
Honest note on this particular dataset: wrapping the same
{cmd:!missing(wage)} condition in {cmd:[if]} instead of {cmd:subpop()}
would not visibly change the standard error here, because the
synthetic {cmd:psu}/{cmd:strat} design above does not correlate
missingness in {cmd:wage} with any one stratum in particular. The
mechanism matters -- and shows up as a real difference -- precisely
when the restriction (missing data, an eligibility flag, anything else)
concentrates inside specific strata, which is the scenario
{help tsvy##remarks_subpop:Remarks: subpop() vs if} documents and
measures in detail.{p_end}

{pstd}
{bf:Example 12: {cmd:mmd} --
a distributional test alongside {cmd:F_WALD}/{cmd:GRUPO}.} Requires
{browse "https://ideas.repec.org/c/boc/bocode/s459820.html":ssc install mmd_2s}
first. Read {help tsvy##remarks_mmd:Remarks: mmd() performance} before
turning this on over many {cmd:nivel()}/{cmd:cruce()} blocks. Note
{cmd:mmdyears()} is independent of {cmd:refyear()} -- this example
compares 2022 vs. 2023, while {cmd:refyear()} stays at 2021 for
{cmd:P_VS_REF}/{cmd:SIG_VS_REF}, a deliberately different pair to show
the two options don't need to agree:{p_end}
{phang2}{cmd:* Example 12: mmd, comparing an explicit pair of years}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen double psu = ceil(_n/3)}{p_end}
{phang2}{cmd:. gen double wgt = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,3))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) refyear(2021) mmd mmdyears(2022 2023) ///}{p_end}
{phang2}{cmd:    mmdweight(wgt) frame(F13) replace}{p_end}
{phang2}{cmd:. frame F13: list CATEGORIA ANIO ESTIMA F_WALD P_WALD P_MMD EFFECT_MMD}{p_end}


{marker frame}{...}
{title:Frame layout}

{pstd}
{cmd:tsvy} leaves the following variables in {cmd:frame()}, one row
per (level of {cmd:nivel()}, value, [{it:cruce} value], year):

{synoptset 16 tabbed}{...}
{synopt:{cmd:NIVEL}}the {cmd:nivel()} variable name for this row (with any
trailing {cmd:_} stripped, matching {cmd:tabsvy}'s convention -- e.g.
{cmd:NOMBREDD_} becomes {cmd:NOMBREDD}){p_end}
{synopt:{cmd:CATEGORIA}}the value of the {cmd:NIVEL} variable for this row{p_end}
{synopt:{cmd:CATEGORIA_LBL}}the value label text for {cmd:CATEGORIA}
(v1.21), e.g. {cmd:"Puno"} when the {cmd:nivel()} variable has a value
label attached; blank ({cmd:""}), never missing, when it does not --
check for a blank string to fall back to the numeric {cmd:CATEGORIA}{p_end}
{synopt:{cmd:CRUCE}}value of {cmd:cruce()}, if given{p_end}
{synopt:{cmd:CRUCE_LBL}}the value label text for {cmd:CRUCE} (v1.21),
same convention as {cmd:CATEGORIA_LBL}; only present when {cmd:cruce()}
is given{p_end}
{synopt:{cmd:var}}fixed at 1 (kept only for column-layout compatibility
with {cmd:tabsvy}'s own frame, where it identifies a category of a
categorical variable){p_end}
{synopt:{cmd:VARNAME}}the {opt varname()} analysis variable's
name as a string, the same on EVERY row this call leaves behind --
useful for telling apart, in a frame that accumulates several
{cmd:tsvy} calls (see {help tsvy##examples:Example 3}), which block of
rows came from which variable{p_end}
{synopt:{cmd:ANIO}}calendar year (mapped from {cmd:years()}){p_end}
{synopt:{cmd:ESTIMA}}point estimate{p_end}
{synopt:{cmd:ERROR_ST}}standard error{p_end}
{synopt:{cmd:CV}}coefficient of variation, percent{p_end}
{synopt:{cmd:LIM_INF LIM_SUP}}confidence limits{p_end}
{synopt:{cmd:N_SIN_PON N_PONDERA}}unweighted / weighted sample size{p_end}
{synopt:{cmd:REF_}}{cmd:"a/"} if {cmd:CV} exceeds {cmd:threshold()}{p_end}
{synopt:{cmd:F_WALD P_WALD}}omnibus Wald F-statistic and its analytic
p-value -- {it:constant across all years within the same block}, since the
test compares all years in that block at once. Missing when fewer than 2
years in the block have a defined, positive variance (a year with a
proportion of exactly 0 or 1 has none) -- with only 0 or 1 usable years
there is nothing left to test. As long as {it:at least 2} years are
usable, {cmd:F_WALD}/{cmd:P_WALD} are computed on that subset (the
degenerate years are dropped from the contrast, not the whole block).
This is independent of {cmd:ESTIMA}: a block with only 1 usable year
still gets {cmd:ESTIMA}/{cmd:ERROR_ST}/etc. for that year, with
{cmd:F_WALD}/{cmd:P_WALD}/{cmd:GRUPO} missing -- see
{help tsvy##remarks_limits:Remarks: differences from tabsvy}{p_end}
{synopt:{cmd:GRUPO}}the Compact Letter Display code for {it:this row's}
year within its block -- varies by year{p_end}
{synopt:{cmd:CLD_METODO}}(v1.29) adjustment method actually used for
{cmd:GRUPO} in this block (with {cmd:cldmetodo(auto)} it can vary across
blocks){p_end}
{synopt:{cmd:CLD_INCONS}}(v1.29) 1 if {cmd:P_WALD} < {cmd:alpha()} but
every year in the block shares a letter under {cmd:CLD_METODO}{p_end}
{synopt:{cmd:P_VS_REF}}Bonferroni-adjusted ({it:k}-1 comparisons) p-value
of {it:this row's} year against {cmd:refyear()}; missing if
{cmd:refyear()} was not specified, and always missing on
{cmd:refyear()}'s own row -- a DIFFERENT comparison family from
{cmd:GRUPO}{p_end}
{synopt:{cmd:SIG_VS_REF}}significance stars for {cmd:P_VS_REF}:
{cmd:"*"} p<0.10, {cmd:"**"} p<0.05, {cmd:"***"} p<0.01{p_end}
{synopt:{cmd:P_MMD}}(the 2 years compared are set by
{cmd:mmdyears()}) bootstrap p-value from {cmd:mmd_2s},
comparing the full distribution of {opt varname()} between the 2 years
named in {cmd:mmdyears()} -- {it:constant across all years within the
same block}, same pattern as {cmd:F_WALD}/{cmd:P_WALD}. Missing unless
{cmd:mmd} was specified, and missing for a block where the comparison
could not be run (see {help tsvy##remarks_mmd:Remarks: mmd() performance}){p_end}
{synopt:{cmd:EFFECT_MMD}}the matching effect-size statistic from
{cmd:mmd_2s} for that same two-year comparison; same missingness rules
as {cmd:P_MMD}{p_end}
{synopt:{cmd:P_KSMMD_KS}}permutation p-value of Kiefer's k-sample KS
statistic from {cmd:ksmmd}, design-based (PSU/strata permutation).
{it:Constant across all years within the same block}. Missing unless
{cmd:ksmmd} was specified, or if {cmd:ksmmd} failed for that block (lone PSU,
PSU mixing years, fewer than 2 years with data){p_end}
{synopt:{cmd:P_KSMMD_MMD}}same, for the k-sample MMD statistic
({cmd:ksmmdtype()}); same missingness rules{p_end}
{synopt:{cmd:F_KW}}omnibus F-statistic of the design-based rank test
(Lumley and Scott, 2013) across all years in the block -- {it:constant
across all years within the same block}, same pattern as
{cmd:F_WALD}/{cmd:P_WALD}. Missing unless {cmd:kwallis} was specified.
{bf:Tests a DIFFERENT null hypothesis than {cmd:F_WALD}} -- see
{help tsvy##remarks_kwallis:Remarks: kwallis()}{p_end}
{synopt:{cmd:P_KW}}p-value for {cmd:F_KW}{p_end}
{synopt:{cmd:GRUPO_KW}}the Compact Letter Display code from the rank
test for {it:this row's} year within its block -- varies by year, same
pattern as {cmd:GRUPO} but from a different test{p_end}
{p2colreset}{...}

{pstd}
Because {cmd:F_WALD}/{cmd:P_WALD}/{cmd:P_MMD}/{cmd:EFFECT_MMD}/
{cmd:F_KW}/{cmd:P_KW} are constant within a block and
{cmd:GRUPO}/{cmd:GRUPO_KW} vary by year, a subsequent {cmd:reshape wide}
should list {cmd:GRUPO}/{cmd:GRUPO_KW} among the variables being
reshaped (so they become {cmd:GRUPO2023}, {cmd:GRUPO2024}, ...) but leave
{cmd:F_WALD}/{cmd:P_WALD}/{cmd:P_MMD}/{cmd:EFFECT_MMD}/{cmd:F_KW}/
{cmd:P_KW} in {cmd:i()} instead, so they are carried along once per
block rather than needlessly repeated per year:

{phang2}{cmd:. reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV N_PONDERA N_SIN_PON GRUPO GRUPO_KW,}{p_end}
{phang2}{cmd:        i(NIVEL CATEGORIA var VARNAME F_WALD P_WALD P_MMD EFFECT_MMD P_KSMMD_KS P_KSMMD_MMD F_KW P_KW) j(ANIO)}{p_end}

{pstd}
This schema is otherwise compatible with the point-estimate half of
{cmd:tabsvyexport} ({cmd:ESTIMA}/{cmd:REF_} by year), since
{cmd:tabsvyexport} already discards every column it does not need before
its own reshape.


{marker references}{...}
{title:References}

{pstd}
Bonferroni, C.E. 1936. Teoria statistica delle classi e calcolo delle
probabilita. {it:Pubblicazioni del R Istituto Superiore di Scienze
Economiche e Commerciali di Firenze} 8: 3-62. The namesake of
{cmd:cldmetodo(bonferroni)} (default) -- no DOI, not indexed in any
major database; the actual citable source for the correction as used
here is Dunn (1961) below, which {cmd:refyear()}'s {it:k}-1
vs-baseline contrasts also use, applied to a smaller, DIFFERENT family
of comparisons.

{pstd}
Dunn, O.J. 1961. Multiple comparisons among means. {it:Journal of the
American Statistical Association} 56(293): 52-64.
doi:10.1080/01621459.1961.10482090

{pstd}
Fisher, R.A. 1935/1937. {it:The Design of Experiments}. Edinburgh: Oliver
and Boyd. Book, no DOI. Source of the least significant difference
underlying {cmd:cldmetodo(lsd)} (the two-step "test the pair only if the
omnibus F is significant" procedure is Fisher's own; the "protected"
label is not -- see Carmer and Swanson below).

{pstd}
Carmer, S.G., Swanson, M.R. 1973. An evaluation of ten pairwise multiple
comparison procedures by Monte Carlo methods. {it:Journal of the American
Statistical Association} 68(341): 66-74. doi:10.1080/01621459.1973.10481335
Source of the "protected" label and its empirical evaluation for
{cmd:cldmetodo(lsd)}.

{pstd}
Saville, D.J. 1990. Multiple comparison procedures: the practical
solution. {it:The American Statistician} 44(2): 174-180.
doi:10.1080/00031305.1990.10475712 Explicit defense of Fisher's protected
LSD, cited for {cmd:cldmetodo(lsd)}.

{pstd}
Holm, S. 1979. A simple sequentially rejective multiple test procedure.
{it:Scandinavian Journal of Statistics} 6(2): 65-70. doi:10.2307/4615733
Source of {cmd:cldmetodo(holm)}.

{pstd}
Benjamini, Y., Hochberg, Y. 1995. Controlling the false discovery rate: a
practical and powerful approach to multiple testing. {it:Journal of the
Royal Statistical Society, Series B} 57(1): 289-300.
doi:10.1111/j.2517-6161.1995.tb02031.x Source of {cmd:cldmetodo(fdr)}.

{pstd}
Miller, R.G. 1981. {it:Simultaneous Statistical Inference}, 2nd ed. New
York: Springer. doi:10.1007/978-1-4613-8122-8 General background on the
multiple-comparisons procedures compared above (book).

{pstd}
Piepho, H.P. 2004. An algorithm for a letter-based representation of
all-pairwise comparisons. {it:Journal of Computational and Graphical
Statistics} 13(2): 456-466. doi:10.1198/1061860043515 The letter-display
algorithm {cmd:GRUPO}/{cmd:GRUPO_KW} targets the same correct object as
(maximal homogeneous subsets of non-significantly-different categories),
even though {cmd:tsvy_core}'s own brute-force maximal-subset search is a
different, less efficient computation reaching the same result.

{pstd}
Lumley, T., Scott, A.J. 2013. Two-sample rank tests under complex
sampling. {it:Biometrika} 100(4): 831-842. doi:10.1093/biomet/ast027
Methodological basis for {cmd:kwallis()}.

{pstd}
West, B.T., Berglund, P.A., Heeringa, S.G. 2008. A closer examination of
subpopulation analysis of complex-sample survey data. {it:Stata Journal}
8(4): 520-531. doi:10.1177/1536867X0800800404 Canonical reference for
{help tsvy##remarks_subpop:why subpop() differs from if}, the mechanism
behind {cmd:subpop()}.


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI bears
no responsibility for it. Distributed under the GNU General Public License
v3 (https://www.gnu.org/licenses/gpl-3.0.txt).


{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb svy}, {helpb tsvyexport}
{p_end}

{psee}
En espanol: {helpb tsvy_es}
{p_end}
