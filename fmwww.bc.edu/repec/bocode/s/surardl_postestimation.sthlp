{smcl}
{* *! version 1.0.1  10oct2026}{...}
{vieweralsosee "surardl" "help surardl"}{...}
{vieweralsosee "surardl methods" "help surardl_methods"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Postestimation commands" "surardl_postestimation##commands"}{...}
{viewerjumpto "predict" "surardl_postestimation##predict"}{...}
{viewerjumpto "estat bounds" "surardl_postestimation##bounds"}{...}
{viewerjumpto "estat longrun" "surardl_postestimation##longrun"}{...}
{viewerjumpto "estat shortrun" "surardl_postestimation##shortrun"}{...}
{viewerjumpto "estat ecequal" "surardl_postestimation##ecequal"}{...}
{viewerjumpto "estat lrequal" "surardl_postestimation##lrequal"}{...}
{viewerjumpto "estat poolability" "surardl_postestimation##pool"}{...}
{viewerjumpto "estat sigma" "surardl_postestimation##sigma"}{...}
{viewerjumpto "estat serial" "surardl_postestimation##serial"}{...}
{viewerjumpto "estat efficiency" "surardl_postestimation##eff"}{...}
{viewerjumpto "estat graph" "surardl_postestimation##graph"}{...}
{viewerjumpto "Examples" "surardl_postestimation##examples"}{...}
{viewerjumpto "Author" "surardl_postestimation##author"}{...}

{title:Title}

{phang}
{bf:surardl postestimation} {hline 2} Postestimation tools for {helpb surardl}


{marker commands}{...}
{title:Postestimation commands}

{pstd}
The following are available after {cmd:surardl}:

{synoptset 30 tabbed}{...}
{synopthdr:Command}
{synoptline}
{synopt :{helpb surardl_postestimation##bounds:estat bounds}}bounds test, with resampled critical values{p_end}
{synopt :{helpb surardl_postestimation##longrun:estat longrun}}long-run coefficients, Fieller sets, bootstrap intervals{p_end}
{synopt :{helpb surardl_postestimation##shortrun:estat shortrun}}short-run and deterministic coefficients{p_end}
{synopt :{helpb surardl_postestimation##ecequal:estat ecequal}}equality of the speeds of adjustment{p_end}
{synopt :{helpb surardl_postestimation##lrequal:estat lrequal}}equality of the long-run coefficients{p_end}
{synopt :{helpb surardl_postestimation##pool:estat poolability}}poolability across equations{p_end}
{synopt :{helpb surardl_postestimation##sigma:estat sigma}}Sigma-hat, correlations and dependence tests{p_end}
{synopt :{helpb surardl_postestimation##serial:estat serial}}Breusch-Godfrey test on the SUR residuals{p_end}
{synopt :{helpb surardl_postestimation##eff:estat efficiency}}efficiency gain over OLS{p_end}
{synopt :{helpb surardl_postestimation##graph:estat graph}}the figure set{p_end}
{synopt :{opt estat summary}}per-equation fit summary{p_end}
{synopt :{helpb surardl_postestimation##predict:predict}}residuals, fitted values, error-correction term{p_end}
{synoptline}

{pstd}
Because {cmd:e(b)} and {cmd:e(V)} are posted in the standard way, with
coefficients named {cmd:[}{it:eqname}{cmd:]L.}{it:varname}, the official
commands {helpb test}, {helpb testnl}, {helpb lincom}, {helpb nlcom},
{helpb estimates store} and {helpb estimates table} all work and all use the
full SUR covariance, including its cross-equation blocks.

{pstd}
Every {cmd:estat} subcommand rebuilds the design from the level series stored
in {cmd:e(lv)}, so results do not depend on what has happened to the data in
memory since estimation.


{marker predict}{...}
{title:Syntax for predict}

{p 8 15 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt :{opt r:esiduals}}SUR residuals; the default{p_end}
{synopt :{opt olsr:esiduals}}equation-by-equation OLS residuals{p_end}
{synopt :{opt xb}}fitted values of D.{it:depvar}{p_end}
{synopt :{opt ec}}error-correction term y(t-1) - sum_k theta(k) x(k,t-1){p_end}
{synoptline}

{pstd}
The error-correction term uses the estimated long-run coefficients, so
lambda times this variable is the equilibrium-correction component of
D.{it:depvar}.


{marker bounds}{...}
{title:estat bounds}

{p 8 15 2}
{cmd:estat bounds} [{cmd:,} {opt boot:strap(#)} {opt seed(#)}
{opt boott:arget(string)} {opt bootd:gp(string)} {opt bootl:ags(#)}
{opt sim:ulate(#)} {opt simr:ho(#)}]

{pstd}
With no options, redisplays the bounds table. With {opt bootstrap()} or
{opt simulate()} the model is refitted with that resampling requested, which
replaces the stored results; this is noted on screen.

{pstd}
See {helpb surardl_methods##boot:help surardl methods} for the bootstrap
design and {helpb surardl_methods##cv:critical values} for what each tabulation
is and is not valid for.


{marker longrun}{...}
{title:estat longrun}

{p 8 15 2}
{cmd:estat longrun} [{cmd:,} {opt l:evel(#)} {opt fie:ller}
{opt boot:strap(#)} {opt seed(#)}]

{pstd}
Reports theta = -beta/lambda with delta-method standard errors, z statistics,
p-values and confidence intervals.

{phang}
{opt fieller} adds the Fieller (1954) confidence set, which inverts
H0: beta + theta lambda = 0 and so never divides by lambda-hat. The set is
reported as a bounded interval, an unbounded complement, the whole line or the
empty set. An unbounded set is the honest signal that lambda is too weakly
identified to pin the ratio down.

{phang}
{opt bootstrap(#)} adds percentile and bias-corrected percentile intervals
from a residual bootstrap under the alternative, preserving the cross-equation
covariance.

{pstd}
Simulation 5 of the paper finds the delta-method interval under-covers badly,
and worse as {it:T} grows. Prefer the Fieller set or the bootstrap interval
when the decision matters.


{marker shortrun}{...}
{title:estat shortrun}

{p 8 15 2}
{cmd:estat shortrun} [{cmd:,} {opt l:evel(#)}]

{pstd}
The short-run block of each equation: lagged differences of the dependent
variable, current and lagged differences of the regressors (the impact
elasticities of equation 13c), and the deterministic terms.


{marker ecequal}{...}
{title:estat ecequal}

{p 8 15 2}
{cmd:estat ecequal} [{cmd:,} {opt mt:est(string)}]

{pstd}
Tests H0: lambda(i) = lambda(j) for every pair, and the joint hypothesis that
all speeds of adjustment are equal. This is the test behind the two-cluster
finding in section 5 of the paper: order the units by lambda-hat and the
pairwise results show which units adjust at a common speed.

{phang}
{opt mtest(string)} is the family-wise correction over the {it:N}({it:N}-1)/2
pairwise tests: {cmd:holm} (default), {cmd:bonferroni}, {cmd:sidak} or
{cmd:none}. Simulation 4 reports a maximum pairwise rejection rate of 53% at
{it:N} = 5, {it:T} = 50 without a correction, so {cmd:none} is rarely wise.

{pstd}
Stored in {cmd:r()}: {cmd:r(pairs)}, {cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p)}.


{marker lrequal}{...}
{title:estat lrequal}

{p 8 15 2}
{cmd:estat lrequal} [{varlist}] [{cmd:,} {opt mt:est(string)}]

{pstd}
Tests H0: theta(k,i) = theta(k,j) for every pair of units, and the joint
hypothesis that the long-run coefficient on each named regressor is common,
by the multivariate delta method of equations (92)-(93). With no {varlist}
every regressor is tested.

{pstd}
These tests use the cross-equation covariance blocks that
equation-by-equation estimation sets to zero, and are the capability the paper
describes as unavailable to single-equation methods.


{marker pool}{...}
{title:estat poolability}

{p 8 15 2}
{cmd:estat poolability} [{cmd:,} {opt lam:bda} {opt short:run} {opt all}]

{pstd}
Tests whether a block of coefficients is common across all equations: the
long-run level coefficients beta by default, the speeds of adjustment with
{opt lambda}, the short-run coefficients with {opt shortrun}, or lambda and
beta jointly with {opt all}.

{pstd}
Simulation 4 finds this test over-rejects when {it:N} is large and {it:T}
small, reaching 21% at {it:N} = 5, {it:T} = 50 against a nominal 5%. Treat it
cautiously below {it:T} = 200 for {it:N} = 5, or below {it:T} = 100 for
{it:N} <= 3.


{marker sigma}{...}
{title:estat sigma}

{p 8 15 2}
{cmd:estat sigma}

{pstd}
Prints Sigma-hat and the cross-equation correlation matrix, then the
Breusch-Pagan LM test of a diagonal Sigma (equations 96-99), the Pesaran CD
statistic (equation 100), the mean absolute off-diagonal correlation,
{it:T}/{it:N}, the conditioning of Sigma-hat and whether it is positive
definite.

{pstd}
The LM test is the one that matters: by Proposition 1 the SUR estimator
coincides with OLS when Sigma is diagonal, so a non-rejection says system
estimation has nothing to add. The CD test has limited power at small {it:N}
and is a robustness check only.


{marker serial}{...}
{title:estat serial}

{p 8 15 2}
{cmd:estat serial} [{cmd:,} {opt lags(#)}]

{pstd}
Breusch-Godfrey LM test for serial correlation in each equation's SUR
residuals, up to order {opt lags()}.

{pstd}
This checks Assumption 1(iii). It is load-bearing: the contemporaneous Sigma is
the correct GLS weight only because the ARDL lag structure has already absorbed
the serial correlation (Remark 4). If the test rejects, raise {opt lags()} in
{cmd:surardl} until it does not.


{marker eff}{...}
{title:estat efficiency}

{p 8 15 2}
{cmd:estat efficiency}

{pstd}
Reports 1 - SE(SUR)/SE(OLS) for each level coefficient, equation (95).
Proposition 2 guarantees a non-negative asymptotic gain whenever Sigma is
non-diagonal and the regressors differ across equations; negative finite-sample
entries simply reflect sampling error in Sigma-hat.


{marker graph}{...}
{title:estat graph}

{p 8 15 2}
{cmd:estat graph} [{cmd:,} {opt lam:bda} {opt bou:nds} {opt long:run}
{opt sig:ma} {opt eff:iciency} {opt boot:dist} {opt all}
{opt n:ame(string)} {opt sav:ing(string)} {opt var:iable(varname)}
{opt sch:eme(string)}]

{pstd}
Draws the figure set. With no options all five standard figures are produced.

{p2colset 8 24 26 2}{...}
{p2col :{opt lambda}}speeds of adjustment with confidence intervals, sorted, so
the adjustment-speed clusters are visible{p_end}
{p2col :{opt bounds}}bounds F statistics against the PSS critical bands{p_end}
{p2col :{opt longrun}}forest plot of the long-run coefficients on one
regressor, chosen with {opt variable()}{p_end}
{p2col :{opt sigma}}cross-equation correlation heatmap{p_end}
{p2col :{opt efficiency}}efficiency gain on lambda, by equation{p_end}
{p2col :{opt bootdist}}bootstrap null distribution with the observed statistic
and the bootstrap critical value; needs {opt bootstrap()} at estimation{p_end}
{p2colreset}{...}

{phang}
{opt name(string)} prefixes the graph names, so several models can be compared
side by side. {opt saving(string)} exports each figure as
{it:string}_{it:figure}{cmd:.png}. Only official {helpb twoway} commands are
used, so no community-contributed graphics package is required.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use surardl_asean6}{p_end}
{phang2}{cmd:. generate double lrec = ln(rec)}{p_end}
{phang2}{cmd:. generate double lgdp = ln(gdp)}{p_end}
{phang2}{cmd:. generate double lfdi = ln(fdi + 4)}{p_end}
{phang2}{cmd:. generate double lto  = ln(to)}{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. surardl lrec lgdp lfdi lto, bootstrap(999)}{p_end}

{pstd}Is system estimation warranted at all?{p_end}
{phang2}{cmd:. estat sigma}{p_end}

{pstd}Are the lag orders long enough for Assumption 1(iii)?{p_end}
{phang2}{cmd:. estat serial, lags(2)}{p_end}

{pstd}Long-run elasticities with an interval that survives a weak lambda{p_end}
{phang2}{cmd:. estat longrun, fieller}{p_end}
{phang2}{cmd:. estat longrun, bootstrap(999)}{p_end}

{pstd}Which countries adjust at the same speed?{p_end}
{phang2}{cmd:. estat ecequal, mtest(holm)}{p_end}
{phang2}{cmd:. estat graph, lambda}{p_end}

{pstd}Is the growth elasticity common across the panel?{p_end}
{phang2}{cmd:. estat lrequal lgdp}{p_end}
{phang2}{cmd:. estat poolability}{p_end}

{pstd}A restriction of your own, using the full SUR covariance{p_end}
{phang2}{cmd:. test [Indonesia]L.lrec = [Malaysia]L.lrec}{p_end}
{phang2}{cmd:. testnl -_b[Thailand:L.lgdp]/_b[Thailand:L.lrec] = }{cmd:-_b[Vietnam:L.lgdp]/_b[Vietnam:L.lrec]}{p_end}

{pstd}Residual diagnostics of your own{p_end}
{phang2}{cmd:. predict double uhat, residuals}{p_end}
{phang2}{cmd:. predict double ecm, ec}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
