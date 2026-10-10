{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "threshkit choose (how many regimes?)" "help threshkit_choose"}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{viewerjumpto "Syntax" "thselect##syntax"}{...}
{viewerjumpto "Description" "thselect##description"}{...}
{viewerjumpto "Options" "thselect##options"}{...}
{viewerjumpto "Remarks" "thselect##remarks"}{...}
{viewerjumpto "Examples" "thselect##examples"}{...}
{viewerjumpto "Stored results" "thselect##results"}{...}
{viewerjumpto "References" "thselect##refs"}{...}
{title:Title}

{phang}
{bf:thselect} {hline 2} How many thresholds? Information criteria and a
sequential bootstrap test, side by side

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thselect} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth threshvar(varname)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth threshvar(varname)}}variable that splits the sample{p_end}
{synopt:{opt maxthresh(#)}}largest number of thresholds to consider; default 3{p_end}
{synopt:{opth inv:ariant(varlist)}}regressors whose coefficients never switch{p_end}
{synopt:{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt:{opt gridn(#)}}search {it:#} sample quantiles instead of all distinct values{p_end}
{synopt:{opt refine(#)}}refinement sweeps over the estimated thresholds; default 0{p_end}
{synopt:{opt minobs(#)}}minimum observations per regime{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt test}}also run the sequential bootstrap test F(m+1|m){p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(500)}{p_end}
{synopt:{opt boot(wild|normal)}}bootstrap DGP; default {cmd:boot(wild)}{p_end}
{synopt:{opt alpha(#)}}level for the sequential stopping rule; default 0.10{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:thselect} fits the model with {it:m} = 0, 1, …, {opt maxthresh()} thresholds,
prints the SSR and four information criteria for each, and names the {it:m} that
each criterion selects. With {opt test} it also runs the sequential bootstrap
test of {it:m} thresholds against {it:m}+1 and applies the usual stopping rule.

{pstd}
Official {helpb threshold}{cmd:, optthresh()} offers only the IC route.
{cmd:thselect} adds the test, reports all four criteria rather than one, and
prints the thresholds each model selected so you can see whether they are stable.

{marker options}{...}
{title:Options}

{phang}
{opt maxthresh(#)} caps the search. Each extra threshold costs degrees of freedom
and shrinks the smallest regime; with {opt trim(0.15)} the arithmetic limit is
about 1/trim − 1 regimes.

{phang}
{opt refine(#)} re-optimises each threshold conditional on the others, Bai (1997)
style, up to {it:#} sweeps. Sequential estimation is consistent (Gonzalo and
Pitarakis 2002) but not efficient; refinement can find a strictly better fit. It
costs time proportional to {it:#}.

{phang}
{opt test} runs F(m+1|m) = n(SSR_m − SSR_{m+1})/SSR_{m+1} with a bootstrap
p-value, for every m from 0 up.

{pmore}
{bf:Do not combine it with a coarse} {opt gridn()}. The bootstrap imposes the
null by generating from the {it:fitted} {it:m}-threshold model, so the
bootstrap data's threshold lies exactly on a grid point while the real one
does not; the observed fit pays a grid-misalignment penalty no bootstrap draw
pays, and the step {bf:over-rejects}, choosing too many regimes. Measured on
data with one true threshold, over the same fifteen data sets: 6 of 15
rejections at the 5% level with a 20-point grid against 2 of 15 on the full
grid. The first step, m = 0 against 1, is
unaffected, because under its null there is no estimated threshold to be
misaligned. The default full grid is the right choice here; see
{help thnregimes##gridsize:thnregimes} for the full account.

{phang}
{opt boot(wild|normal)} chooses the bootstrap DGP under the null of m thresholds.
{cmd:wild} (default) multiplies each fitted residual by its own N(0,1) draw, so
the p-value is {bf:heteroskedasticity-robust}. {cmd:normal} draws iid normal
errors with the fitted residual variance, which is Hansen's fixed-regressor
convention and reproduces the {helpb thtest} sup-F p-value.

{pstd}
{bf:This choice matters.} On the shipped growth data, F(1|0) = 19.11 with
p = 0.097 under {cmd:boot(normal)} and p = 0.163 under {cmd:boot(wild)}. The
statistic is the homoskedastic F either way; only the simulated null changes.
Report which you used.

{phang}
{opt alpha(#)} is the level of the stopping rule: stop at the first m whose
test against m+1 does not reject.

{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Information criteria are model selection, not inference.} They always return
a number; they never say "there is no threshold". AIC in particular over-selects
here, as it does elsewhere. BIC and the Gonzalo-Pitarakis criterion are the
conservative choices.

{pstd}
{bf:BIC-GP} is the criterion in the form used by Gonzalo and Pitarakis (2002) and
by official {cmd:optthresh()}: n·ln(SSR/n) + K·ln(n). The AIC/BIC/HQIC columns are
the usual likelihood forms, −2ℓ + penalty. They can disagree because they
penalise differently, not because one is wrong.

{pstd}
{bf:When the test and the criteria disagree,} the extra threshold is weakly
identified. The honest write-up is "two regimes, with some evidence of a third",
not whichever answer suits the argument.

{pstd}
{bf:Confidence intervals for the later thresholds} are reported by
{helpb thregress}{cmd:, nthresh(#)}, which inverts the likelihood ratio for each
threshold conditional on the others and can also report the conservative
modification (Donayre 2024; Donayre, Eo and Morley 2018). Do not reuse the
one-threshold critical value for a multi-threshold model.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use threshkit_dj}{p_end}

{pstd}Criteria only (fast){p_end}
{phang2}{cmd:. thselect diff gdp60 iony pgro sch, threshvar(q) maxthresh(3)}{p_end}

{pstd}With the sequential bootstrap test{p_end}
{phang2}{cmd:. set seed 20261001}{p_end}
{phang2}{cmd:. thselect diff gdp60 iony pgro sch, threshvar(q) maxthresh(3) test}{p_end}

{pstd}Match Hansen's fixed-regressor convention{p_end}
{phang2}{cmd:. thselect diff gdp60 iony pgro sch, threshvar(q) test boot(normal)}{p_end}

{pstd}Then estimate the chosen model{p_end}
{phang2}{cmd:. thregress diff gdp60 iony pgro sch, threshvar(q) nthresh(2) refine(10)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:thselect} is {it:rclass}. It stores{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(m_aic)}, {cmd:r(m_bic)}, {cmd:r(m_hqic)}, {cmd:r(m_bicgp)}}number of thresholds each criterion selects{p_end}
{synopt:{cmd:r(m_seq)}}number selected by the sequential test{p_end}
{synopt:{cmd:r(N)}, {cmd:r(n_grid)}, {cmd:r(alpha)}, {cmd:r(reps)}}sample and settings{p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}one row per m: m, SSR, AIC, BIC, HQIC, BIC-GP{p_end}
{synopt:{cmd:r(thresholds)}}row m holds the m estimated thresholds{p_end}
{synopt:{cmd:r(seqtest)}}F statistic, bootstrap p, MC s.e. for each m{p_end}
{p2colreset}{...}

{marker refs}{...}
{title:References}

{phang}
Bai, J. 1997. Estimating multiple breaks one at a time. {it:Econometric Theory}
13: 315-352.
{browse "https://doi.org/10.1017/S0266466600005831":doi:10.1017/S0266466600005831}.

{phang}
Donayre, L. 2024. Likelihood-ratio-based confidence intervals for multiple
threshold parameters. {it:SNDE} 29: 561-573.
{browse "https://doi.org/10.1515/snde-2023-0029":doi:10.1515/snde-2023-0029}.

{phang}
Gonzalo, J., and J.-Y. Pitarakis. 2002. Estimation and model selection based
inference in single and multiple threshold models. {it:Journal of Econometrics}
110: 319-352.
{browse "https://doi.org/10.1016/S0304-4076(02)00098-2":doi:10.1016/S0304-4076(02)00098-2}.

{phang}
Hansen, B. E. 1999. Testing for linearity. {it:Journal of Economic Surveys} 13:
551-576.
{browse "https://doi.org/10.1111/1467-6419.00098":doi:10.1111/1467-6419.00098}.

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
Help:  {helpb threshkit_choose:threshkit choose}, {helpb thregress}, {helpb thtest}
{p_end}
