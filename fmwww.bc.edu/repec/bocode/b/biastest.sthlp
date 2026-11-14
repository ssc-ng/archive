{smcl}
{* *! version 1.0.0  13nov2026}{...}
{hline}
help for {cmd:biastest}{right:Hasraddin Guliyev}
{hline}

{title:Title}

{p 4 4 2}
{cmd:biastest} {hline 2} Hausman-type test of coefficient equality between two estimators


{title:Syntax}

{p 8 15 2}
{cmd:biastest} {depvar} {indepvars} {ifin}{cmd:,}
{cmd:m1(}{it:string}{cmd:)} {cmd:m2(}{it:string}{cmd:)}
[{cmd:m1ops(}{it:string}{cmd:)} {cmd:m2ops(}{it:string}{cmd:)}
{opt eff:icient(#)} {opt sigmaless} {opt sigmamore}
{opt boot:strap} {opt rep:s(#)} {opt seed(string)} {opt cl:uster(varname)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt m1}({it:string})}first estimation command (required){p_end}
{synopt:{opt m1ops}({it:string})}options passed to the first command{p_end}
{synopt:{opt m2}({it:string})}second estimation command (required){p_end}
{synopt:{opt m2ops}({it:string})}options passed to the second command{p_end}
{syntab:Hausman variance (default)}
{synopt:{opt eff:icient(#)}}model (1 or 2) that is efficient under H0; recommended{p_end}
{synopt:{opt sigmaless}}base both covariance matrices on the disturbance variance of the consistent estimator{p_end}
{synopt:{opt sigmamore}}base both covariance matrices on the disturbance variance of the efficient estimator{p_end}
{syntab:Bootstrap variance}
{synopt:{opt boot:strap}}estimate Var(b1 - b2) by the bootstrap; no efficiency assumption{p_end}
{synopt:{opt rep:s(#)}}number of bootstrap replications; default is {cmd:reps(200)}{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt cl:uster(varname)}}resample clusters; default is the panel variable for {cmd:xt} commands{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:biastest} fits two models of {depvar} on the same {indepvars} and the same
estimation sample, and tests whether their slope coefficients are equal.
Because both estimators use the same data, they are correlated, and

{p 8 8 2}Var(b1 - b2) = V1 + V2 - 2 Cov(b1, b2).

{pstd}
The covariance term cannot be ignored. {cmd:biastest} estimates Var(b1 - b2)
in one of two ways.

{phang}
1. {it:Hausman variance} (default). One estimator must be consistent under
both H0 and H1, and the other consistent and asymptotically efficient under
H0 and inconsistent under H1. Then Cov(b1, b2) = V_eff, so that
Var(b_cons - b_eff) = V_cons - V_eff (Hausman 1978). The standard application
is fixed effects (consistent) versus random effects (efficient under H0).

{phang}
2. {it:Bootstrap variance} (option {opt bootstrap}). Both models are refitted
on each bootstrap sample and Var(b1 - b2) is the covariance of b1* - b2*
across replications, as in the robust Hausman test of Kaiser (2014). No
efficiency assumption is needed, so this is the method to use with robust or
cluster-robust inference, and when neither estimator is efficient relative to
the other (two quantiles, OLS versus robust regression with non-normal errors).

{pstd}
Two tests are reported: an individual z test for each coefficient and a joint
chi-squared test of all compared coefficients. The individual tests are
correlated and not adjusted for multiple testing; the overall conclusion
should rest on the joint test.

{pstd}
The intercept is never compared. Coefficients are matched by name in the first
equation of each model; terms that are omitted or not estimated in one model
are excluded and listed.


{title:Options}

{dlgtab:Model}

{phang}
{opt m1}({it:string}) and {opt m2}({it:string}) name the estimation commands,
for example {cmd:regress}, {cmd:rreg}, {cmd:qreg} or {cmd:xtreg}. Each command
is run as {it:command depvar indepvars} {cmd:if} {it:sample}{cmd:,} {it:options}.

{phang}
{opt m1ops}({it:string}) and {opt m2ops}({it:string}) pass options to the two
commands, for example {cmd:m1ops(fe)} or {cmd:m2ops(q(.75))}. With the Hausman
variance, do not request robust, cluster-robust, bootstrap or jackknife
standard errors; use option {opt bootstrap} instead.

{dlgtab:Hausman variance}

{phang}
{opt efficient(#)} states which model, 1 or 2, is efficient under H0.
Theory always says which estimator is efficient, so specifying
{opt efficient()} is recommended, for example {cmd:efficient(2)} for
{cmd:m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re)}. If the declared efficient model
has the larger generalized variance (log-determinant of its covariance matrix)
in the sample, a warning is printed, because the data then contradict the
efficiency assumption.

{pmore}
If {opt efficient()} is omitted, the model whose covariance matrix for the
compared coefficients has the smaller log-determinant is treated as efficient.
This choice does not depend on the units of the regressors, and it is always
correct when V_cons - V_eff is positive semidefinite. When the contrast matrix
has negative eigenvalues, however, the choice is arbitrary and it determines
the sign of the chi-squared statistic. In that case the joint p-value is not
reported and a warning asks for {opt efficient()}. If either covariance matrix
is singular, {opt efficient()} must be specified.

{phang}
{opt sigmaless} and {opt sigmamore} make the two covariance matrices use one
common estimate of the disturbance standard deviation s, as in {help hausman}.
{opt sigmaless} rescales V_eff by (s_cons/s_eff)^2; {opt sigmamore} rescales
V_cons by (s_eff/s_cons)^2. As in {help hausman}, s is {cmd:e(sigma_e)} after
{cmd:xtreg, fe} or {cmd:xtreg, mle}, and {cmd:e(rmse)} otherwise (then
{cmd:e(sigma_e)}, then {cmd:e(sigma)}). The rescaling is meaningful only when
both covariance matrices are proportional to one disturbance variance, so the
options are applied only when both commands are {cmd:regress}, {cmd:xtreg} or
{cmd:areg}; otherwise they are ignored with a warning. The two options cannot
be combined.

{pmore}
A negative or non-positive-definite contrast arises when different
estimates of the disturbance variance enter V_cons and V_eff, even
asymptotically (Schreiber 2008). For {cmd:xtreg, fe} versus {cmd:xtreg, re}
on the same sample, a common s makes V_cons - V_eff positive semidefinite, so
either option is recommended for that comparison. {opt sigmaless} uses the
within estimate of the idiosyncratic variance for both models, which is the
form Le Gallo and Senegas (2023) recommend over the quasi-demeaned
random-effects covariance.

{dlgtab:Bootstrap variance}

{phang}
{opt bootstrap} estimates Var(b1 - b2) by the sample covariance of b1* - b2*
over the bootstrap replications. Both models are refitted with their options
on each bootstrap sample. Replications in which either model fails, or a
compared coefficient is omitted, are skipped and counted.
{opt efficient()}, {opt sigmaless} and {opt sigmamore} are not used.

{phang}
{opt reps(#)} sets the number of replications; the default is 200. Use more
(for example 1,000) for final results; the joint test needs a stable estimate
of a k x k covariance matrix.

{phang}
{opt seed(string)} sets the random-number seed, so results can be reproduced.

{phang}
{opt cluster(varname)} resamples whole clusters instead of observations. If
either command is an {cmd:xt} command and {opt cluster()} is not specified,
panels are resampled (the data must be {cmd:xtset}); duplicated panels are
given new panel identifiers in each replication. Resample at the level at
which the errors are allowed to be dependent.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which variance to use.} The Hausman variance V_cons - V_eff is valid only
when one estimator is fully efficient under H0 (Hausman 1978, Lemma 2.1).
Use option {opt bootstrap} instead in the following cases:

{p 8 12 2}- The models use robust, cluster-robust, bootstrap or jackknife
standard errors, so the efficiency assumption is not maintained.
{cmd:biastest} prints a warning. For fixed versus random effects, the
fully robust Mundlak (correlated random effects) test is an alternative
(Mundlak 1978; Wooldridge 2010, sec. 10.7.3), available after
{cmd:xtreg, re} as {cmd:estat mundlak} in recent versions of Stata.{p_end}
{p 8 12 2}- Neither estimator is efficient relative to the other, for example
two quantile regressions at different quantiles, or the between and the
within estimators (which are uncorrelated, so Var(d) = V_W + V_B). For two
quantiles, fitting both jointly with {help sqreg} and using {help test} is
equivalent.{p_end}
{p 8 12 2}- OLS versus robust regression when the errors are not normal. OLS
is efficient only under normal errors (Dehon, Gassner and Verardi 2009); with
non-normal errors, the usual reason for robust regression, neither estimator
is efficient. A valid Hausman-type test of MM against S estimates (Dehon,
Gassner and Verardi 2012) is reported by {cmd:robreg mm} (Jann, SSC).{p_end}

{pstd}
{bf:Do not use V1 + V2.} The formula SE(b1 - b2) = sqrt(SE1^2 + SE2^2)
(Paternoster et al. 1998) is for coefficients estimated on {it:independent}
samples. For two estimators on the same sample it ignores the covariance and
does not give a valid test. For nested linear models fitted to the same data,
see Clogg, Petkova and Haritou (1995).

{pstd}
{bf:Non-positive-definite contrast.} With the Hausman variance,
V_cons - V_eff may be singular or have negative eigenvalues. Individual
standard errors are reported as missing for coefficients with a nonpositive
diagonal element. The joint statistic uses a generalized inverse and
df = rank (Hausman and Taylor 1981), as {help hausman} does. The rank is
decided on a correlation scale, so it does not depend on the units of the
regressors. Check the contrast matrix even when the statistic is positive;
a non-positive-definite matrix can make a positive statistic misleading
(Schreiber 2008).

{pstd}
{bf:Interpretation.} Non-rejection is not evidence that the efficient
estimator is unbiased: the test can have low power. Choosing between models
with this test and then reporting inference from the chosen model
(pretesting) can severely distort the size of the second-stage tests;
Guggenberger (2010) shows this for fixed versus random effects and
recommends inference based on the fixed-effects estimator.

{pstd}
{bf:Direction of the difference.} The table reports Diff = b1 - b2 in the
order of {cmd:m1()} and {cmd:m2()}. The sign does not affect any statistic.


{title:Methods and formulas}

{pstd}
Let b_1 and b_2 be the estimates of the k compared slopes, d = b_1 - b_2, and
V_d the estimate of Var(d):

{p 8 8 2}Hausman: V_d = V_c - V_e (after any sigmaless/sigmamore rescaling),
where e indexes the efficient model and c the consistent one.{p_end}
{p 8 8 2}Bootstrap: V_d = (B-1)^(-1) sum_b (d*_b - dbar*)(d*_b - dbar*)',
where d*_b = b*_1b - b*_2b from replication b = 1, ..., B.{p_end}

{pstd}
For each coefficient j, z_j = d_j / sqrt(V_d[j,j]), with p-value
2*normal(-|z_j|), when V_d[j,j] > 0. Asymptotically z_j ~ N(0,1) under H0.

{pstd}
For the joint test let D = diag(S)^(1/2), where S is V_c for the Hausman
variance and V_d for the bootstrap variance, R = D^(-1) V_d D^(-1) and
s = D^(-1) d. With the eigen decomposition R = sum_i l_i x_i x_i', the
statistic is H = sum over |l_i| > 1e-10 of (s'x_i)^2 / l_i. When V_d is
positive definite, H = d' V_d^(-1) d. Under H0, H ~ chi2(r), where r is the
number of eigenvalues retained (the rank of V_d).


{title:Stored results}

{pstd}
{cmd:biastest} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used by both models{p_end}
{synopt:{cmd:e(N1)}, {cmd:e(N2)}}observations used by model 1 and model 2{p_end}
{synopt:{cmd:e(chi2)}}joint chi-squared statistic{p_end}
{synopt:{cmd:e(df)}}degrees of freedom of the joint test (rank of V_d){p_end}
{synopt:{cmd:e(p)}}p-value of the joint test{p_end}
{synopt:{cmd:e(posdef)}}1 if V_d is positive definite, 0 otherwise{p_end}
{synopt:{cmd:e(nneg)}}number of negative eigenvalues of V_d (correlation scale){p_end}
{synopt:{cmd:e(efficient)}}model treated as efficient under H0 (Hausman variance){p_end}
{synopt:{cmd:e(reps)}}successful bootstrap replications (option {cmd:bootstrap}){p_end}
{synopt:{cmd:e(N_fail)}}failed bootstrap replications (option {cmd:bootstrap}){p_end}
{synopt:{cmd:e(s2_1)}, {cmd:e(s2_2)}}disturbance s.d. of models 1 and 2, if stored by the command{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b_m1)}, {cmd:e(b_m2)}}full coefficient vectors of models 1 and 2{p_end}
{synopt:{cmd:e(V_m1)}, {cmd:e(V_m2)}}full covariance matrices of models 1 and 2, not rescaled{p_end}
{synopt:{cmd:e(diffs)}}b1 - b2 for the compared coefficients{p_end}
{synopt:{cmd:e(V_diff)}}V_d, the estimated variance of b1 - b2{p_end}
{synopt:{cmd:e(ses)}}standard errors of the differences{p_end}
{synopt:{cmd:e(z_stats)}}z statistics of the individual tests{p_end}
{synopt:{cmd:e(p_values)}}p-values of the individual tests{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:biastest}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Hausman} or {cmd:Bootstrap}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}independent variables requested{p_end}
{synopt:{cmd:e(common)}}coefficients compared{p_end}
{synopt:{cmd:e(excluded)}}coefficients not compared{p_end}
{synopt:{cmd:e(m1)}, {cmd:e(m2)}}estimation commands{p_end}
{synopt:{cmd:e(m1ops)}, {cmd:e(m2ops)}}their options{p_end}
{synopt:{cmd:e(cluster)}}resampling cluster variable (option {cmd:bootstrap}){p_end}
{synopt:{cmd:e(efficient_model)}}"Model 1" or "Model 2" (Hausman variance){p_end}
{synopt:{cmd:e(consistent_model)}}the other model (Hausman variance){p_end}
{synopt:{cmd:e(effcrit)}}how the efficient model was chosen{p_end}
{synopt:{cmd:e(sigmaless)}}"adjusted" if {cmd:sigmaless} was applied{p_end}
{synopt:{cmd:e(sigmamore)}}"adjusted" if {cmd:sigmamore} was applied{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}observations used by both models{p_end}


{title:Examples}

{phang}{bf:Example 1:} Fixed versus random effects, Hausman variance{p_end}
{cmd}{...}
{phang2}. webuse grunfeld, clear{p_end}
{phang2}. biastest invest mvalue kstock, m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re) efficient(2){p_end}
{phang2}. biastest invest mvalue kstock, m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re) efficient(2) sigmaless{p_end}
{txt}{...}

{phang}{bf:Example 2:} Fixed versus random effects, panel bootstrap (robust to heteroskedasticity and serial correlation){p_end}
{cmd}{...}
{phang2}. biastest invest mvalue kstock, m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re) bootstrap reps(1000) seed(12345){p_end}
{txt}{...}

{phang}{bf:Example 3:} Comparing two quantiles{p_end}
{cmd}{...}
{phang2}. webuse engel1857, clear{p_end}
{phang2}. biastest foodexp income, m1(qreg) m1ops(q(.25)) m2(qreg) m2ops(q(.75)) bootstrap reps(1000) seed(12345){p_end}
{phang2}. sqreg foodexp income, quantiles(.25 .75) reps(1000){p_end}
{phang2}. test [q25]income = [q75]income{p_end}
{txt}{...}

{phang}{bf:Example 4:} OLS versus robust regression{p_end}
{cmd}{...}
{phang2}. use https://stats.oarc.ucla.edu/stat/stata/dae/crime, clear{p_end}
{phang2}. biastest crime pctmetro pcths poverty, m1(regress) m2(rreg) m2ops(nolog) bootstrap reps(1000) seed(12345){p_end}
{txt}{...}
{pstd}
With the Hausman variance this comparison is valid only under normal errors
({cmd:efficient(1)}); see {help biastest##remarks:Remarks}.


{title:References}

{phang}
Bole, V., and P. Rebec. 2013. Bootstrapping the Hausman test in panel data
models. {it:Communications in Statistics - Simulation and Computation} 42: 650-670.

{phang}
Clogg, C. C., E. Petkova, and A. Haritou. 1995. Statistical methods for
comparing regression coefficients between models. {it:American Journal of Sociology} 100: 1261-1293.

{phang}
Dehon, C., M. Gassner, and V. Verardi. 2009. A Hausman-type test to detect the
presence of influential outliers in regression analysis. {it:Economics Letters} 105: 64-67.

{phang}
Dehon, C., M. Gassner, and V. Verardi. 2012. Extending the Hausman test to
check for the presence of outliers. In {it:Essays in Honor of Jerry Hausman},
Advances in Econometrics 29, 435-453. Bingley: Emerald.

{phang}
Guggenberger, P. 2010. The impact of a Hausman pretest on the size of a
hypothesis test: The panel data case. {it:Journal of Econometrics} 156: 337-343.

{phang}
Hausman, J. A. 1978. Specification tests in econometrics. {it:Econometrica} 46: 1251-1271.

{phang}
Hausman, J. A., and W. E. Taylor. 1981. A generalized specification test.
{it:Economics Letters} 8: 239-245.

{phang}
Kaiser, B. 2014. RHAUSMAN: Stata module to perform robust Hausman
specification test. Statistical Software Components S457909, Boston College.

{phang}
Le Gallo, J., and M.-A. Senegas. 2023. On the proper computation of the
Hausman test statistic in standard linear panel data models: Some
clarifications and new results. {it:Econometrics} 11(4): 25.

{phang}
Mundlak, Y. 1978. On the pooling of time series and cross section data.
{it:Econometrica} 46: 69-85.

{phang}
Paternoster, R., R. Brame, P. Mazerolle, and A. Piquero. 1998. Using the
correct statistical test for the equality of regression coefficients.
{it:Criminology} 36: 859-866.

{phang}
Schreiber, S. 2008. The Hausman test statistic can be negative even
asymptotically. {it:Jahrbuecher fuer Nationaloekonomie und Statistik} 228: 394-405.

{phang}
Wooldridge, J. M. 2010. {it:Econometric Analysis of Cross Section and Panel Data}. 2nd ed. Cambridge, MA: MIT Press.


{title:Author}

{pstd}
Hasraddin Guliyev{p_end}
{pstd}
Azerbaijan State University of Economics (UNEC){p_end}
{pstd}
hasradding@unec.edu.az{p_end}


{title:Also see}

{psee}
Manual: {help hausman}, {help suest}, {help regress}, {help rreg}, {help sqreg}, {help xtreg}, {help bsample}, {help test}{p_end}
