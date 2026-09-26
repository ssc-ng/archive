{smcl}
{* *! version 1.0.0  September, 2026}{...}
{hline}
{cmd:help twfedec}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:twfedec} {hline 2}}Two-way fixed effects coefficient as a weighted average of first-difference coefficients{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 11 2} {cmd:twfedec} {it:outcome} {it:treatment} [{it:covariates}] [{it:weight}] [{cmd:if} {it:exp}] [{cmd:in} {it:range}]
[{cmd:,} {bind:{cmdab:tinv:ariant(}{it:varlist}{cmd:)}}
{bind:{cmd:vce(}{it:vcetype}{cmd:)}}
{cmdab:gr:aph}
{bind:{cmdab:graphopt:ions(}{it:twoway_options}{cmd:)}}
{bind:{cmdab:for:mat(}{it:fmt}{cmd:)}]}{p_end}

{pstd}The data must be {helpb xtset} with a panel variable and a time variable.
{it:outcome} and {it:treatment} are numeric variables.
Factor variables and time-series operators are allowed in {it:covariates}; factor variables are allowed in {cmdab:tinv:ariant()}.{p_end}
{pstd}{cmd:aweight}s, {cmd:fweight}s, and {cmd:pweight}s are allowed if they are constant within each unit; see help {help weights}.{p_end}
{pstd}{cmd:twfedec} requires {cmd:reghdfe} (with {cmd:ftools} and {cmd:require}); install them with {cmd:ssc install require}, {cmd:ssc install ftools}, and {cmd:ssc install reghdfe}.{p_end}


{title:Description}

{pstd}{cmd:twfedec} implements the decomposition of Ishimaru (2026, Theorem 2.2).
In a balanced panel, the coefficient on a scalar treatment D in a two-way fixed effects (TWFE) regression of an outcome Y equals
a weighted average of the coefficients from k-period first-difference (FD) regressions, k = 1, ..., T-1, plus an adjustment term:{p_end}

{p 8 8 2}b_FE = sum_k w_k b_FD,k + A.{p_end}

{pstd}The k-period FD regression regresses Y(t+k) - Y(t) on D(t+k) - D(t) (and on the changes in the time-varying covariates W) over all pairs of periods k apart.
The weights w_k sum to one and reflect how much variation in k-period treatment changes remains after the time effects and covariates are accounted for.
The adjustment term A is zero without time-varying covariates; with them, it reflects how differently the TWFE and FD regressions account for covariate effects,
and a large A signals a violation of time homogeneity.
The command reports the TWFE coefficient, every FD coefficient with its weight, the weighted average, and A,
and optionally draws them as in Figure 1 of the paper.{p_end}

{pstd}The regressions include unit fixed effects (TWFE only) and period fixed effects.
Time-invariant covariates C, specified in {cmdab:tinv:ariant()}, enter with period-specific coefficients, i.e., as period x C terms;
{cmd:tinvariant(i.region)} gives period-by-region fixed effects.
In the FD regressions, the period is the start period t of each pair.{p_end}

{pstd}The identity is exact algebra, so the command also stores the discrepancy b_FE - (sum_k w_k b_FD,k + A) in {cmd:r(check)},
which is zero up to rounding error; a warning is displayed if it is not.
The identity requires a balanced panel with consecutive periods: after applying {cmd:if}, {cmd:in}, and dropping observations with missing values,
every unit must be observed in every period, and the time variable must have no gaps in units of the {helpb xtset} delta.
What one period means (a year, two years, a quarter) is set by the time variable and its delta; k counts periods.{p_end}

{pstd}With time-varying covariates, only the sum of the unnormalized weights is guaranteed to be positive; an individual weight can be negative.{p_end}


{title:Options}

{phang}{cmdab:tinv:ariant(}{it:varlist}{cmd:)} specifies the time-invariant covariates C, each of which receives a period-specific coefficient.
Factor variables, continuous variables, and interactions are allowed (e.g., {cmd:tinvariant(i.region c.x0 i.region#c.x0)}).
Every variable must be constant within each unit in the estimation sample.
Unit and period fixed effects are always included and must not be specified.{p_end}

{phang}{cmd:vce(}{it:vcetype}{cmd:)} specifies the standard errors of the TWFE and FD coefficients, as in {helpb reghdfe}.
The default is {cmd:vce(cluster} {it:panelvar}{cmd:)}.
The same {it:vcetype} is used in every regression.{p_end}

{phang}{cmdab:gr:aph} draws the FD coefficients with one-standard-error bars, the TWFE coefficient (dashed line), and the weights (bars, right axis).
With time-varying covariates, the weighted average of the FD coefficients is added as a solid line; it differs from the TWFE coefficient by A.{p_end}

{phang}{cmdab:graphopt:ions(}{it:twoway_options}{cmd:)} passes options to {helpb twoway}, such as {cmd:title()}, {cmd:xtitle()}, {cmd:name()}, or {cmd:saving()}; it implies {cmd:graph}.{p_end}

{phang}{cmdab:for:mat(}{it:fmt}{cmd:)} specifies the display format of the results; the default is {cmd:%10.6f}. See help {help format}.{p_end}


{title:Remarks}

{pstd}Weights: the identity holds with regression weights that are constant within each unit, with every sum over units weighted accordingly.
Zero or missing weights exclude the unit, as in any Stata estimator.{p_end}

{pstd}Standard errors: all regressions are estimated with {helpb reghdfe}, and the standard errors are those of {cmd:reghdfe}.
In the TWFE regression, the period-specific coefficients on C are parameterized so that the number of absorbed parameters counted equals their rank
(the period-invariant part of C_i'g_t is spanned by the unit effects); with the default clustering this reproduces {cmd:xtreg, fe} with period x C dummies.
The weights, the weighted average, and A are reported without standard errors.{p_end}


{marker s_examples}{title:Example}

{pstd}The example dataset {cmd:twfedec_example.dta} is the state-year panel of the paper (51 states including DC, 1979-2019):
log teen employment rate ({cmd:ln_emp_tn}), net job creation rate ({cmd:netjc_rate}), log minimum wage ({cmd:ln_mw}),
log per capita income ({cmd:ln_pci}), log teen population ({cmd:ln_pop}), and census region ({cmd:region}).
It is an ancillary file of the package: {cmd:ssc install twfedec, all} installs the package and copies the dataset to the current directory;
if {cmd:twfedec} is already installed, {cmd:net get twfedec, from("http://fmwww.bc.edu/repec/bocode/t")} copies the dataset only.{p_end}
{phang2}. {stata "ssc install twfedec, all"}{p_end}
{phang2}. {stata "use twfedec_example, clear"}{p_end}
{phang2}. {stata "xtset statefip year"}{p_end}

{pstd}Figure 1 of the paper: period-by-region fixed effects, no time-varying covariates{p_end}
{phang2}. {stata "twfedec ln_emp_tn ln_mw, tinvariant(i.region) graph"}{p_end}
{phang2}. {stata "twfedec netjc_rate ln_mw, tinvariant(i.region) graph"}{p_end}

{pstd}With time-varying covariates (Online Appendix Figure S1){p_end}
{phang2}. {stata "twfedec ln_emp_tn ln_mw ln_pci ln_pop, tinvariant(i.region) graph"}{p_end}

{pstd}Customize the figure{p_end}
{phang2}. {stata `"twfedec ln_emp_tn ln_mw, tinvariant(i.region) graphoptions(xtitle("Gap (Years)") name(fig1, replace))"'}{p_end}

{pstd}Heteroskedasticity-robust (not clustered) standard errors, weighting each state by its 1979 teen population (constant within state){p_end}
{phang2}. {stata "bysort statefip (year): gen double pop1979 = exp(ln_pop[1])"}{p_end}
{phang2}. {stata "twfedec ln_emp_tn ln_mw [aw=pop1979], tinvariant(i.region) vce(robust)"}{p_end}


{title:Stored results}

{pstd}{cmd:twfedec} stores the following in {cmd:r()}:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(b_fe)}}TWFE coefficient on the treatment{p_end}
{synopt:{cmd:r(se_fe)}}standard error of {cmd:r(b_fe)}{p_end}
{synopt:{cmd:r(b_wavg)}}weighted average of the FD coefficients, sum_k w_k b_FD,k{p_end}
{synopt:{cmd:r(adj)}}adjustment term A{p_end}
{synopt:{cmd:r(check)}}discrepancy b_FE - (sum_k w_k b_FD,k + A){p_end}
{synopt:{cmd:r(N)}}number of units{p_end}
{synopt:{cmd:r(T)}}number of periods{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}outcome{p_end}
{synopt:{cmd:r(treatment)}}treatment{p_end}
{synopt:{cmd:r(covariates)}}time-varying covariates{p_end}
{synopt:{cmd:r(tinvariant)}}time-invariant covariates{p_end}
{synopt:{cmd:r(vce)}}{it:vcetype} (and cluster variable){p_end}
{synopt:{cmd:r(wtype)}}weight type{p_end}
{synopt:{cmd:r(wexp)}}weight expression{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(fd)}}one row per horizon k = 1, ..., T-1; columns {cmd:b} (FD coefficient), {cmd:se} (its standard error), {cmd:weight} (w_k), and {cmd:nobs} (number of pairs, N(T-k)){p_end}

{pstd}If the FD coefficient at some k is not identified (the k-period treatment change is collinear with the period effects and covariate changes),
its {cmd:b} and {cmd:se} are missing and it is left out of the weighted average; without time-varying covariates its weight is then zero.{p_end}


{marker references}{...}
{title:Reference}

{phang}
Ishimaru, S., 2026. "What Do We Get from Two-Way Fixed Effects Regressions? Implications from Numerical Equivalence."
{it:The Econometrics Journal}.
(Also see {it:{browse "https://arxiv.org/abs/2103.12374":arXiv:2103.12374}}).{p_end}


{marker authors}{...}
{title:Author}

{pstd}Shoya Ishimaru{p_end}
{pstd}Hitotsubashi University{p_end}
{pstd}Tokyo, Japan{p_end}
{pstd}shoya.ishimaru@r.hit-u.ac.jp{p_end}


{marker also}{...}
{title:Also see}

{p 7 14 2}Help: {helpb reghdfe}, {helpb xtreg}, {helpb xtset}{p_end}
