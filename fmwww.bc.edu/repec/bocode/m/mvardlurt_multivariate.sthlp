{smcl}
{* *! version 1.1.2  03oct2026}{...}
{hline}
help for {hi:mvardlurt_multivariate}{right:Yusuf Toyin Yusuf (2026)}
{hline}

{title:Title}

{p 4 8 2}
{bf:mvardlurt_multivariate} {hline 2} Multivariate ARDL unit root test with two or more covariates
(Sam, McNown, Goh and Goh, 2024), with residual-bootstrap critical values


{title:Syntax}

{p 8 16 2}
{cmd:mvardlurt_multivariate} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
{it:indepvars} are the covariates (one or more). The data must be {helpb tsset}
with no gaps in the estimation sample.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt c:ase(#)}}{cmd:1} none, {cmd:3} intercept (default), {cmd:5} intercept + trend{p_end}
{synopt:{opt maxl:ag(#)}}largest lag searched, 0-12; default {cmd:4}{p_end}
{synopt:{opt ic(string)}}{cmd:aic} (default) or {cmd:bic}{p_end}
{synopt:{opt fixl:ag(numlist)}}fixed lags {it:p q} (common q) or {it:p q1 ... qk}; skips the search{p_end}
{synopt:{opt cont:emp}}also include contemporaneous {bf:D.}{it:x}{p_end}

{syntab:Inference}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:1000}, minimum 100{p_end}
{synopt:{opt seed(#)}}random-number seed; default {cmd:12345}{p_end}
{synopt:{opt l:evel(#)}}decision level for the four-case table; default {cmd:95}{p_end}
{synopt:{opt nob:oot}}no bootstrap: statistics only, no critical values or decision{p_end}

{syntab:Reporting}
{synopt:{opt star}}show significance stars (default){p_end}
{synopt:{opt nos:tar}}suppress stars{p_end}
{synopt:{opt not:able}}suppress the information-criterion table{p_end}
{synopt:{opt nod:isplay}}suppress all tables{p_end}
{synopt:{opt di:ag}}residual diagnostic tests{p_end}
{synopt:{opt nog:raph}}suppress graphs{p_end}
{synopt:{opt savepath(filename)}}export headline results to Excel{p_end}
{synoptline}


{title:Description}

{p 4 4 2}
The test estimates the ARDL (conditional error-correction) regression

{p 8 8 2}
D.y = c1 + c2 t + b1 L.y + b2' L.x + sum_i phi_i L{it:i}D.y + sum_j Phi_j' L{it:j}D.x [+ w' D.x] + u

{p 4 4 2}
where {it:x} holds all covariates. Two statistics are bootstrapped:

{p 8 12 2}- the {bf:t-test} on L.y, H0: b1 = 0 (lower tail){p_end}
{p 8 12 2}- the {bf:F-test} on all lagged covariate levels, H0: b2 = 0 (upper tail){p_end}

{p 4 4 2}
Decision rule (paper, section 3.2):

{p 8 8 2}
{bf:Case I}: neither rejects; nonstationary, no cointegration.{break}
{bf:Case II}: t rejects, F does not; y is stationary I(0).{break}
{bf:Case III}: t does not reject, F rejects; degenerate lagged y, possibly I(2).{break}
{bf:Case IV}: both reject; cointegration (y is I(1) if the covariates are I(1)).

{p 4 4 2}
The joint F-test is valid when the system has at most one cointegrating relation
(no feedback from {it:y} to the covariates).


{title:Bootstrap}

{p 4 4 2}
For the t-test the model is re-estimated with b1 = 0 imposed, for the F-test with
b2 = 0 imposed. Residuals are centred, rescaled and resampled; y* is rebuilt
recursively (covariates held at their observed values); the full ARDL is
re-estimated and the statistic stored. The 10%, 5%, 2.5%, 1% and decision-level
quantiles are reported. Bootstrap p-values are (1 + #extreme draws)/(B + 1).

{p 4 4 2}
{bf:Lag search.} All (p, q), p, q = 0..{cmd:maxlag}, are compared on one common sample,
the same q being used for every covariate. The final model is re-estimated on the
longest sample. Use {cmd:fixlag()} for covariate-specific lags. With many covariates
keep {cmd:maxlag()} small.


{title:Stars}

{p 4 4 2}
Compared with the bootstrap critical values: {bf:***} 1%, {bf:**} 2.5%, {bf:*} 5%, {bf:+} 10%.


{title:Postestimation}

{p 4 8 2}{cmd:mvardlurt_multivariate_diag} - Breusch-Godfrey(1), RESET, Breusch-Pagan (Koenker), ARCH(1), Jarque-Bera; matrix in {cmd:r(diag)}.{p_end}
{p 4 8 2}{cmd:mvardlurt_multivariate_graph} [{cmd:, scheme(}{it:name}{cmd:) nocombine}] - levels, bootstrap distributions, residual plots, CUSUM; combined panel {cmd:mvu_panel}.{p_end}
{p 4 8 2}{cmd:predict} {it:newvar} [{cmd:, xb residuals}] - fitted values / residuals of the D.y equation.{p_end}
{p 4 8 2}{cmd:_mvardlurt_multivariate_display} - redisplay the tables.{p_end}

{p 4 4 2}
Diagnostics, graphs and {cmd:predict} use objects kept in Mata and stop working after
{cmd:mata clear}; re-run the command to restore them.


{title:Stored results}

{p 4 4 2}{cmd:e(b)}, {cmd:e(V)}, {cmd:e(sample)} belong to the final ARDL regression of D.{it:y}.

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(T)}}observations in the regression / before lags{p_end}
{synopt:{cmd:e(tstat)}, {cmd:e(fstat)}}observed t and F statistics{p_end}
{synopt:{cmd:e(p_t)}, {cmd:e(p_f)}}bootstrap p-values{p_end}
{synopt:{cmd:e(B_t)}, {cmd:e(B_f)}}valid bootstrap draws{p_end}
{synopt:{cmd:e(opt_p)}}lags of D.y{p_end}
{synopt:{cmd:e(k)}, {cmd:e(case)}, {cmd:e(reps)}, {cmd:e(maxlag)}}settings{p_end}
{synopt:{cmd:e(level)}, {cmd:e(alpha)}}decision level and size{p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_a)}, {cmd:e(rss)}, {cmd:e(rmse)}, {cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(df_r)}}fit{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}, {cmd:e(cmdline)}, {cmd:e(depvar)}, {cmd:e(indepvars)}}{p_end}
{synopt:{cmd:e(opt_q)}}lags of D.x_i, one per covariate{p_end}
{synopt:{cmd:e(casename)}, {cmd:e(ic)}, {cmd:e(t_start)}, {cmd:e(t_end)}}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(cv)}}2 x 5 critical values (rows t, F; columns 10%, 5%, 2.5%, 1%, decision level){p_end}
{synopt:{cmd:e(ic_table)}}information criteria over (p, q) when lags were searched{p_end}


{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. mvardlurt_multivariate ln_inv ln_inc ln_consump, maxlag(4) reps(999)}{p_end}
{phang2}{cmd:. mvardlurt_multivariate ln_inv ln_inc ln_consump, case(5) fixlag(2 1) seed(7) nograph}{p_end}
{phang2}{cmd:. mvardlurt_multivariate_diag}{p_end}
{phang2}{cmd:. predict double ehat, residuals}{p_end}

{p 4 4 2}More, including a simulated system with three covariates, in {cmd:mvardlurt_multivariate_example.do}.


{title:References}

{p 4 8 2}Sam, C. Y., McNown, R., Goh, S. K. and Goh, K. L. (2024). A multivariate autoregressive distributed lag unit root test. {it:Studies in Economics and Econometrics}.{p_end}
{p 4 8 2}McNown, R., Sam, C. Y. and Goh, S. K. (2018). Bootstrapping the autoregressive distributed lag test for cointegration. {it:Applied Economics} 50(13): 1509-1521.{p_end}
{p 4 8 2}Pesaran, M. H., Shin, Y. and Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. {it:Journal of Applied Econometrics} 16(3): 289-326.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Kwara State University, Nigeria. yusuf.yusuf@kwasu.edu.ng{p_end}
{p 4 4 2}Output layout and star convention follow Roudane's {cmd:mvardlurt} (2026), which handles a single covariate.{p_end}
