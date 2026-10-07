{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag im" "help jointdiag_im"}{...}
{vieweralsosee "jointdiag bc" "help jointdiag_bc"}{...}
{vieweralsosee "jointdiag all" "help jointdiag_all"}{...}
{vieweralsosee "estat hettest" "help regress postestimation##hettest"}{...}
{viewerjumpto "Syntax" "jointdiag_lm##syntax"}{...}
{viewerjumpto "Description" "jointdiag_lm##description"}{...}
{viewerjumpto "Options" "jointdiag_lm##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_lm##interpret"}{...}
{viewerjumpto "Remarks" "jointdiag_lm##remarks"}{...}
{viewerjumpto "Examples" "jointdiag_lm##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_lm##results"}{...}
{viewerjumpto "References" "jointdiag_lm##refs"}{...}

{title:Title}

{phang}
{bf:jointdiag lm} {hline 2} Four-directional LM test: normality,
heteroskedasticity, serial independence and functional form


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:lm} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}order {it:p} of the serial-correlation alternative;
default {cmd:lags(1)}{p_end}
{synopt:{opt het(varlist)}}the {it:z} variables of the variance function{p_end}
{synopt:{opt rhs}}use all regressors as {it:z}{p_end}
{synopt:{opt func(varlist)}}user-chosen {it:W} for the functional-form block{p_end}
{synopt:{opt reset(#)}}highest power for the default {it:W}; default
{cmd:reset(4)}{p_end}
{synopt:{opt ts:powers}}use powers of each regressor (Thursby{c 150}Schmidt)
rather than of the fitted values{p_end}

{syntab:Variants}
{synopt:{opt stud:entize}}Koenker (1981) studentised LM_H{p_end}
{synopt:{opt df:adj}}use {it:n-k} instead of {it:n} in the moments of LM_N{p_end}
{synopt:{opt fullbg}}LM_I from the full Breusch{c 150}Godfrey regression{p_end}

{syntab:Multiple comparison}
{synopt:{opt mcp}}run the Bera{c 150}Jarque multiple-comparison procedure{p_end}
{synopt:{opt sim(#)}}simulate finite-sample critical values from {it:#} draws{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:sim()}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}contribution plot{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:jointdiag lm} computes the four one-directional Lagrange-multiplier
statistics of Bera and Jarque (1982) and every one of the fifteen combinations
they generate:

{p 8 8 2}
LM_NHIF = LM_N + LM_H + LM_I + LM_F

{pstd}
The additivity is exact, not an approximation: it follows from the block
diagonality of the concentrated information matrix (see
{helpb jointdiag_methods##additivity:the additivity theorem}).  So the degrees
of freedom add too, and every joint test in the table is literally the sum of
the rows above it.

{pstd}
With {opt mcp} the command also runs their multiple-comparison procedure, which
keeps the overall level under control while still telling you {it:which}
direction failed {c 150} something a single joint statistic cannot do.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets the order {it:p} of the autoregressive alternative for
LM_I.  The degrees of freedom of that block are {it:p}.

{phang}
{opt het(varlist)} names the variables {it:z} entering the variance function
{it:Var}({it:u_t}) = {it:sigma}{c 94}2 + {it:z_t'}{&alpha}.  The default is the
fitted values, which is Cook and Weisberg's choice and matches
{helpb estat hettest}.  {opt rhs} uses all the regressors, matching
{cmd:estat hettest, rhs}.  Bera and Jarque's footnote 2 notes that when you
have no prior information about the form of the heteroskedasticity you may
prefer the fully non-constructive White test instead.

{phang}
{opt func(varlist)} supplies the added variables {it:W} for the functional-form
block directly {c 150} use this when you have a specific omitted variable in
mind.  Otherwise {it:W} is powers 2 to {opt reset()} of the fitted values
(Ramsey's RESET) or, with {opt tspowers}, powers of each regressor, which is
the set Ghali and Snow (1987) use.

{phang}
{opt studentize} replaces the Gaussian scale factor in LM_H by the empirical
fourth moment of the residuals (Koenker 1981).  Use it whenever the residuals
are visibly non-normal; it is exactly the "factor 2" correction that Godfrey
and Wickens (1982) and Bera, McAleer and Pesaran (1989) insist on.

{phang}
{opt fullbg} computes LM_I from the Breusch{c 150}Godfrey auxiliary regression
of the residual on the regressors {it:and} its own lags, rather than from the
simple {it:n r'r} form.  {bf:Use it when the model contains lagged dependent
variables}, where the simple form is not valid.

{phang}
{opt mcp} performs the procedure of Bera and Jarque (1982, sec. 5).  Each
direction is tested at level {it:alpha}/4, so the Bonferroni bound on the
overall level is {it:alpha}; the exact level under asymptotic independence is
also printed.  {opt sim(#)} replaces the chi-squared critical values by
empirical quantiles from {it:#} Gaussian replications on the same design
matrix {c 150} worth doing when {it:n} is small, since these statistics are
only asymptotically chi-squared.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:The one-directional block.}  Read these first, but do not stop there.  Each
is valid {it:only if the other three assumptions hold}; that is the whole point
of the paper.  A large LM_I with a large LM_F is ambiguous.

{pstd}
{bf:The two- and three-directional blocks.}  These are the statistics to quote
when you have prior reason to believe only certain directions are at risk.  In
cross-sectional work the natural one is LM_NHF; with clean time-series data
LM_HIF.

{pstd}
{bf:LM_NHIF.}  The omnibus statistic.  Rejecting it says "something is wrong"
and nothing more.

{pstd}
{bf:The skewness and kurtosis line.}  Reported because LM_N is driven entirely
by them, and because the direction of the departure matters for what you do
next: heavy tails alone point to robust standard errors, strong skewness to a
transformation.

{pstd}
{bf:The MCP block.}  "REJECT" in a row means adjust the model in that
direction.  The count of rejected directions is in {cmd:r(nrej)}.  Bera and
Jarque found the procedure identifies N, H and I efficiently but can
over-adjust {c 150} with lognormal errors LM_H flagged heteroskedasticity in
51 of 100 replications when none was present {c 150} and that it identifies the
F direction less reliably when strong heteroskedasticity is also present.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Overtesting is cheap; undertesting is dangerous.}  Bera and Jarque's
Monte Carlo puts numbers on it.  Applying the four-directional test when only
one direction is violated costs about 0.04 of power.  Applying a
one-directional test when four directions are violated costs 0.42: the power of
the correctly specified LM_NHIF is 0.898 against a four-way departure, while
LM_N alone manages 0.474.

{pstd}
{bf:What to do after a rejection.}  The order matters.  Check the functional
form before the error structure, because a wrong functional form reads as
autocorrelation {c 150} see {helpb jointdiag_bc:jointdiag bc} and
Savin and White (1978).  Then check whether an apparent ARCH or autocorrelation
signal survives conditioning on the other, with
{helpb jointdiag_arch:jointdiag arch}.

{pstd}
{bf:Relation to Stata's built-ins.}  LM_H reproduces {helpb estat hettest}
exactly, {cmd:studentize} reproduces {cmd:estat hettest, iid}, {cmd:rhs}
reproduces {cmd:estat hettest, rhs}, and {cmd:fullbg} reproduces
{helpb estat bgodfrey}.  LM_N is the Jarque{c 150}Bera statistic, which is
{it:not} what {helpb sktest} reports ({cmd:sktest} gives the Royston-adjusted
D'Agostino test).


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}All fifteen statistics, from the model in memory{p_end}
{phang2}{cmd:. jointdiag lm}{p_end}

{pstd}Second-order serial alternative, regressors as the variance variables{p_end}
{phang2}{cmd:. jointdiag lm, lags(2) rhs}{p_end}

{pstd}Robust to non-normal errors, with the multiple-comparison procedure{p_end}
{phang2}{cmd:. jointdiag lm, studentize mcp}{p_end}

{pstd}Finite-sample critical values and the contribution plot{p_end}
{phang2}{cmd:. jointdiag lm, mcp sim(2000) seed(20261006) graph}{p_end}

{pstd}Cross-check against the built-ins{p_end}
{phang2}{cmd:. jointdiag lm, studentize notable}{p_end}
{phang2}{cmd:. display r(lm_H)}{p_end}
{phang2}{cmd:. estat hettest, iid}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:jointdiag lm} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(lm_}{it:s}{cmd:)}}statistic, for {it:s} in N, H, I, F, NH, NI,
NF, HI, HF, IF, NHI, NHF, NIF, HIF, NHIF{p_end}
{synopt:{cmd:r(df_}{it:s}{cmd:)}}degrees of freedom{p_end}
{synopt:{cmd:r(p_}{it:s}{cmd:)}}p-value{p_end}
{synopt:{cmd:r(skewness)}}residual skewness{p_end}
{synopt:{cmd:r(kurtosis)}}residual kurtosis{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(nrej)}}directions rejected, with {cmd:mcp}{p_end}
{synopt:{cmd:r(c}{it:X}{cmd:)}}MCP critical value for direction {it:X}{p_end}
{synopt:{cmd:r(alpha_marginal)}}marginal level per direction{p_end}
{synopt:{cmd:r(alpha_overall)}}exact overall level under independence{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:jointdiag lm}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}regressors{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}15 {&times} 3 matrix of statistic, df and p-value{p_end}


{marker refs}{...}
{title:References}

{phang}Bera, A. K., and C. M. Jarque. 1982. {it:J. Econometrics} 20: 59{c 150}82.
{browse "https://doi.org/10.1016/0304-4076(82)90103-8"}{p_end}
{phang}Jarque, C. M., and A. K. Bera. 1980. {it:Economics Letters} 6: 255{c 150}259.
{browse "https://doi.org/10.1016/0165-1765(80)90024-5"}{p_end}
{phang}Higgins, M. L., and A. K. Bera. 1988. {it:Econometric Reviews} 7: 171{c 150}181.
{browse "https://doi.org/10.1080/07474938808800151"}{p_end}
{phang}Koenker, R. 1981. {it:J. Econometrics} 17: 107{c 150}112.
{browse "https://doi.org/10.1016/0304-4076(81)90062-2"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
