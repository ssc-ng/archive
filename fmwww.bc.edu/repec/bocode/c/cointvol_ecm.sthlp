{smcl}
{* *! version 0.2.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol resid" "help cointvol_resid"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{viewerjumpto "Syntax" "cointvol_ecm##syntax"}{...}
{viewerjumpto "Description" "cointvol_ecm##description"}{...}
{viewerjumpto "Options" "cointvol_ecm##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_ecm##methods"}{...}
{viewerjumpto "Remarks" "cointvol_ecm##remarks"}{...}
{viewerjumpto "Examples" "cointvol_ecm##examples"}{...}
{viewerjumpto "Stored results" "cointvol_ecm##results"}{...}
{viewerjumpto "References" "cointvol_ecm##references"}{...}
{viewerjumpto "Author" "cointvol_ecm##author"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:cointvol ecm} {hline 2}}Error-correction (ECM) t-tests of no cointegration with
published critical values and a wild bootstrap robust to GARCH errors{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:cointvol ecm} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt beta(#|estimate)}}known cointegrating coefficient (KED test; default
{cmd:beta(1)}) or {cmd:estimate} (BDM / Ericsson-MacKinnon test){p_end}
{synopt:{opt tr:end(string)}}{cmd:none}, {cmd:constant}, {cmd:trend} or {cmd:qtrend};
default {cmd:none} with a known beta, {cmd:constant} with {cmd:beta(estimate)}{p_end}
{synopt:{opt cons:tant}, {opt nocons:tant}}synonyms for {cmd:trend(constant)} and
{cmd:trend(none)}{p_end}
{synopt:{opt lag:s(#)}}lagged differences of y and x in the ECM; default 0{p_end}

{syntab:Critical values}
{synopt:{opt cv(name)}}reference distribution: {cmd:em} (default), {cmd:bdm}, {cmd:sim},
{cmd:ked} or {cmd:normal}{p_end}
{synopt:{opt simr:eps(#)}}replications of the simulated null distributions; default 10000;
0 skips them{p_end}

{syntab:Bootstrap}
{synopt:{opt boot:strap(wild|none)}}wild bootstrap; default {cmd:wild}{p_end}
{synopt:{opt r:eps(#)}}bootstrap replications; default 199{p_end}
{synopt:{opt mult:iplier(name)}}{cmd:mammen} (default), {cmd:rademacher} or {cmd:gauss}{p_end}
{synopt:{opt bsr:esid(name)}}{cmd:unrestricted} (default) or {cmd:restricted} estimates in the
bootstrap DGP{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}decision level; default {cmd:level(95)}{p_end}
{synopt:{opt nodots}}suppress replication dots{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} (not as a panel) with no gaps. A known beta needs exactly one
{it:indepvar}; {cmd:beta(estimate)} allows up to 11.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol ecm} tests the null of no cointegration by the t-ratio on the lagged level
of {it:depvar} in a single-equation conditional error-correction model, assuming that the
regressors are weakly exogenous. Two versions are available:

{p 8 12 2}1. {bf:known beta} (Kremers, Ericsson and Dolado 1992, KED): the equilibrium error
y - beta x is imposed. The null distribution depends on a signal-to-noise ratio q: it is the
Dickey-Fuller distribution when q = 0 and N(0,1) as q grows.{p_end}
{p 8 12 2}2. {bf:estimated coefficients} ({cmd:beta(estimate)}; Banerjee, Dolado and Mestre
1998, BDM; Ericsson and MacKinnon 2002, E&M): y(t-1) and x(t-1) enter unrestrictedly. The
statistic kappa_d(k) has a nuisance-parameter-free limit that depends on the number of
variables k = m+1 and the deterministic terms d.{p_end}

{pstd}
The default reference distribution is the finite-sample response surface of Ericsson and
MacKinnon (2002), which supersedes the BDM table; the BDM values are also reported. Following
Mantalos (c. 2001) a wild bootstrap that imposes the null is computed by default; it keeps
the size under GARCH(1,1) errors and is the headline inference when it is computed. An
ARCH-LM(1) test on the ECM residuals is reported.

{pstd}
When the common-factor restriction fails, ECM tests are more powerful than the residual
Dickey-Fuller test (KED 1992; BDM 1998). If weak exogeneity is doubtful, use
{helpb cointvol_rank:cointvol rank}.


{marker options}{...}
{title:Options}

{phang}
{opt beta(#|estimate)}: a number gives the known cointegrating coefficient, so the
equilibrium error is y - beta x (default 1, Mantalos's design; KED eq. 4). {cmd:estimate}
selects the unrestricted ECM of BDM eq. (1') and E&M eqs (16), (24).

{phang}
{opt trend(string)} sets the unrestricted deterministic terms of the ECM: {cmd:none}
(E&M nc), {cmd:constant} (c), {cmd:trend} (ct) or {cmd:qtrend} (constant, trend and trend
squared; ctt). The defaults are {cmd:none} with a known beta (Mantalos eq. 3) and
{cmd:constant} with {cmd:beta(estimate)} (BDM Table I A; E&M Table 3). {opt constant} and
{opt noconstant} are accepted for compatibility.

{phang}
{opt lags(#)} adds Dy(t-j) and Dx(t-j), j = 1..#, to the ECM (E&M eq. 24 with lag order
#+1). The E&M response surfaces were simulated without lags; following E&M sec. 5 the
adjusted sample size is then T - h, with h the total number of regressors.

{phang}
{opt cv(name)} chooses the reference distribution used for the decision when
{cmd:bootstrap(none)} is specified (with the bootstrap, all rows are reported and the
bootstrap decides): {cmd:em} the E&M response surface (known beta: E&M k = 1, the q = 0,
Dickey-Fuller bound); {cmd:bdm} the BDM Table I values ({cmd:beta(estimate)} with
{cmd:constant} or {cmd:trend} and at most 5 regressors); {cmd:sim} the simulated null
distribution; {cmd:ked} the KED distribution simulated at q = q^ (known beta only);
{cmd:normal} N(0,1).

{phang}
{opt simreps(#)} is the number of replications of the simulated null distributions ({cmd:sim}
row and, with a known beta, the {cmd:ked} row); 0 skips them; the minimum positive value
is 100.

{phang}
{opt bootstrap(wild|none)} requests the wild bootstrap (default) or skips it.

{phang}
{opt reps(#)} is the number of bootstrap replications; the default is 199, as in Mantalos,
and the minimum is 19.

{phang}
{opt multiplier(name)}: {cmd:mammen} (default) is the two-point distribution with
E u* = 0, E u*{c 94}2 = 1 and E u*{c 94}3 = 1 (Mantalos eq. 5; Mammen 1993).
{cmd:rademacher} and {cmd:gauss} are extensions.

{phang}
{opt bsresid(name)}: {cmd:unrestricted} (default) takes the short-run coefficients and
residuals of the bootstrap DGP from the estimated ECM with the level coefficients set to zero;
{cmd:restricted} re-estimates the ECM without the levels (b = 0 imposed).

{phang}
{opt seed(#)}, {opt level(#)} and {opt nodots} are as usual. Decisions from the BDM table
are available for {cmd:level(90)}, {cmd:level(95)} and {cmd:level(99)} only.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Known beta} (KED 1992 eqs 1-3; Mantalos eqs 1-3):

{p 8 8 2}Dy(t) = a Dx(t) + b (y(t-1) - beta x(t-1)) + d(t)'c + sum_(j=1..p) (phi_j Dy(t-j) +
psi_j Dx(t-j)) + e(t),{p_end}

{pstd}
t = p+2,...,T, estimated by OLS with n observations; t_ECM = b^/se(b^) with
s{c 94}2 = SSR/(n-h). H0: b = 0; H1: b < 0. KED (eqs 14-18) show that
t_ECM => [intB_u dB_e - q{c 94}-1 intB_e dB_e] / [intB_u{c 94}2 - 2q{c 94}-1 intB_u B_e +
q{c 94}-2 intB_e{c 94}2]{c 94}(1/2), with the signal-to-noise ratio

{p 8 8 2}q = -(a - beta) s,   s = sigma_u / sigma_e  (KED eq. 16),{p_end}

{pstd}
the Dickey-Fuller distribution when q = 0 and N(0,1) + O(1/q) for large q. The command
reports q^ = (beta - a^) sd(Dx)/s_e.

{pstd}
{bf:Estimated coefficients} (BDM eq. 1', eq. 3'; E&M eqs 16, 24):

{p 8 8 2}Dy(t) = g0'Dx(t) + rho y(t-1) + theta'x(t-1) + d(t)'c + lags + e(t),{p_end}

{pstd}
kappa_d(k) = rho^/se(rho^), H0: rho = 0 (no cointegration; theta = 0 follows), k = m+1
variables. Its limit (E&M eq. 19) depends only on k and d.

{pstd}
{bf:Ericsson-MacKinnon response surfaces} (E&M eq. 26, Tables 2-5; {cmd:cv(em)}). For the
1%, 5% and 10% levels,

{p 8 8 2}c(p) = theta_inf + theta_1/Ta + theta_2/Ta{c 94}2 + theta_3/Ta{c 94}3,   Ta = T - h,{p_end}

{pstd}
where T is the number of observations in the ECM regression and h the number of regressors
including deterministic terms (E&M sec. 5; without lags h = 2k - 1 + d). All 144
response surfaces (k = 1..12; nc, c, ct, ctt) are embedded. With a known beta the row k = 1
(Dickey-Fuller) is used: it is the q = 0 bound of KED, the most conservative case. The E&M
design covers 20 <= T <= 1000. {bf:p-value} (extended implementation): E&M compute p-values
with a program that is not printed in the paper. The command interpolates
Phi{c 94}-1(p) through the three finite-sample quantiles with a quadratic (probit)
curve, extrapolated linearly where the quadratic is not increasing. It reproduces the E&M
Tables 6-7 p-values to within 0.02 (see the test file).

{pstd}
{bf:BDM Table I} ({cmd:cv(bdm)}): 1%, 5% and 10% values for 1-5 regressors, constant or
constant and trend, T = 25, 50, 100, 500 and infinity; for other T the command interpolates
linearly in 1/T (T < 25: the T = 25 row). E&M (sec. 4.3) show that their surfaces encompass
BDM: every BDM value lies within 0.2 of the E&M value (largest deviation 0.194, c(6),
T = 500, 5%), which the test file verifies.

{pstd}
{bf:Simulated null distributions} ({cmd:cv(sim)}, {cmd:cv(ked)}): the same regression
(deterministics and lags included) on simulated data of length T. Known beta: y = beta x + w
with x and w independent Gaussian random walks (q = 0); KED plug-in: Dy = (beta - q^)Dx + e,
Dx and e iid N(0,1) (q = q^). Estimated coefficients: E&M DGP (23), k independent Gaussian
random walks. p = (#{c -(}t* <= t{c )-} + 1)/(R + 1).

{pstd}
{bf:Wild bootstrap} (Mantalos eqs 4-5; generalised to deterministics and lags):

{p 8 12 2}1. Estimate the ECM. Set the level coefficients (b, or rho and theta) to zero and
keep the other coefficients and the residuals e^ ({cmd:bsresid(restricted)}: re-estimate
without the levels).{p_end}
{p 8 12 2}2. For r = 1,...,B draw iid u*(t) and generate Dy*(t) = fitted short-run part +
sum phi_j Dy*(t-j) + e^(t)u*(t) recursively (observed values as initial conditions); this
imposes H0.{p_end}
{p 8 12 2}3. Cumulate y*(t) from y(1), keep x fixed, re-estimate the ECM and obtain t*_r.{p_end}
{p 8 12 2}4. p = B{c 94}-1 #{c -(}t*_r <= t{c )-}.{p_end}

{pstd}
{bf:Correction of the tail.} Mantalos writes the bootstrap p-value as P*(T* >= T_s). The ECM
test rejects for {it:negative} values, so the consistent p-value is P*(t* <= t).

{pstd}
{bf:ARCH-LM(1)} (Engle 1982; Mantalos sec. 3): n' R{c 94}2 from the regression of
e^(t){c 94}2 on (1, e^(t-1){c 94}2), n' = n-1, against chi2(1).

{pstd}
{bf:Step -> source map.}{break}
known-beta ECM and t-ratio: KED (1992) eqs (1), (3), (14); Mantalos eqs (1), (3){break}
signal-to-noise q and limits: KED (1992) eqs (13), (15)-(18){break}
estimated-coefficient ECM: BDM (1998) eqs (1'), (3'); E&M (2002) eqs (16), (19), (24){break}
response surfaces and Ta = T - h: E&M (2002) eq (26), Tables 2-5, sec. 5{break}
BDM critical values: BDM (1998) Table I{break}
bootstrap DGP under H0 and multiplier: Mantalos eqs (4)-(5); Mammen (1993){break}
left-tail p-value: correction of Mantalos; ARCH-LM: Mantalos sec. 3


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which version?} If theory fixes the cointegrating vector (a spread, a basis, purchasing
power parity), the known-beta KED test is more powerful (Zivot 2000), but its null
distribution depends on q, so the E&M k = 1 row is only a conservative bound and the
bootstrap (or the KED plug-in row) should be used. If the vector is unknown, use
{cmd:beta(estimate)}: its critical values are tabulated exactly by E&M.

{pstd}
{bf:GARCH.} The E&M and BDM values assume homoskedastic errors. Mantalos's Monte Carlo
evidence shows the asymptotic ECM test over-rejecting at T = 100 with persistent GARCH
(about 0.07 at 5% for (ARCH, GARCH) = (0.09, 0.90)); the wild bootstrap is correctly sized.
An ARCH-LM test with a large p-value does not rule out GARCH.

{pstd}
{bf:Labels.} Original: the KED t_ECM; the BDM/E&M kappa_d(k); the E&M response surfaces;
the BDM table; the Mammen wild bootstrap with H0 imposed; ARCH-LM(1). Correction: left-tail
bootstrap p-value. Extended implementation: the E&M p-value approximation, the 1/T
interpolation of the BDM table, {cmd:bsresid(restricted)}, lags and deterministics in the
bootstrap, the Rademacher and Gaussian multipliers, the simulated q = 0 and KED plug-in
distributions.

{pstd}
{bf:Source notes.} (i) KED is cited as the published OBES (1992) article; the working-paper
version (Federal Reserve Board IFDP 431, June 1992) was used to verify eqs (3), (14)-(18);
q = -(a - 1)s there refers to the cointegrating vector (1, -1), i.e. q = -(a - beta)s in
general. (ii) BDM print their critical values without the minus sign; the signs are
restored. BDM's k is the number of regressors (E&M k - 1). (iii) The E&M Table 2 row k = 1,
1% is mis-aligned in the text layer of the PDF (theta_2 = -3.6); the page image was used.
(iv) Mantalos (c. 2001) is an unrefereed working paper with notation inconsistencies (its
GARCH equation attaches the ARCH symbol to h(t-1)).


{marker examples}{...}
{title:Examples}

{pstd}Setup: Mantalos design, q = 0 (a = 1), plus a second regressor{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 120}{p_end}
{phang2}{cmd:. set seed 2001}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen e1 = rnormal()/4}{p_end}
{phang2}{cmd:. gen e2 = rnormal()}{p_end}
{phang2}{cmd:. gen x = sum(e2)}{p_end}
{phang2}{cmd:. gen y = sum(e2 + e1)}{p_end}
{phang2}{cmd:. gen z = sum(rnormal())}{p_end}

{pstd}Known beta (KED): bootstrap, E&M k = 1 bound, KED plug-in{p_end}
{phang2}{cmd:. cointvol ecm y x, seed(1)}{p_end}

{pstd}Estimated coefficients with a constant: E&M c(3) and BDM{p_end}
{phang2}{cmd:. cointvol ecm y x z, beta(estimate) seed(1)}{p_end}

{pstd}Trend and one lag, BDM reference without bootstrap{p_end}
{phang2}{cmd:. cointvol ecm y x z, beta(estimate) trend(trend) lags(1) cv(bdm) bootstrap(none)}{p_end}

{pstd}Rademacher multiplier, restricted bootstrap residuals, more replications{p_end}
{phang2}{cmd:. cointvol ecm y x, multiplier(rademacher) bsresid(restricted) reps(999) seed(1)}{p_end}

{pstd}Replication: E&M worked example (k = 4, constant, T = 47): 5% value -3.84{p_end}
{phang2}{cmd:. mata: cve_emcv(4, 1, 47 - 7 - 1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol ecm} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations in the ECM regression{p_end}
{synopt:{cmd:r(h)}, {cmd:r(Ta)}}number of regressors and adjusted sample size T - h{p_end}
{synopt:{cmd:r(k)}}E&M k (1 with a known beta, m+1 otherwise){p_end}
{synopt:{cmd:r(lags)}}lags{p_end}
{synopt:{cmd:r(beta)}}known cointegrating coefficient{p_end}
{synopt:{cmd:r(t)}}t_ECM or kappa_d(k){p_end}
{synopt:{cmd:r(b)}, {cmd:r(se_b)}}tested coefficient and standard error{p_end}
{synopt:{cmd:r(a)}, {cmd:r(se_a)}}coefficient on Dx (known beta){p_end}
{synopt:{cmd:r(c)}, {cmd:r(se_c)}}intercept (known beta, with a constant){p_end}
{synopt:{cmd:r(sigma2)}}residual variance{p_end}
{synopt:{cmd:r(q)}}estimated signal-to-noise ratio q^ (known beta){p_end}
{synopt:{cmd:r(archlm)}, {cmd:r(p_archlm)}}ARCH-LM(1) statistic and p-value{p_end}
{synopt:{cmd:r(p_boot)}}wild-bootstrap p-value{p_end}
{synopt:{cmd:r(p_df)}}p-value from the simulated null distribution{p_end}
{synopt:{cmd:r(p_em)}}approximate E&M p-value{p_end}
{synopt:{cmd:r(p_ked)}}KED plug-in p-value{p_end}
{synopt:{cmd:r(p_norm)}}N(0,1) p-value{p_end}
{synopt:{cmd:r(cv01_em)}, {cmd:r(cv05_em)}, {cmd:r(cv10_em)}}E&M critical values{p_end}
{synopt:{cmd:r(cv05_bdm)}, {cmd:r(cv05_boot)}, {cmd:r(cv05_df)}}5% critical values{p_end}
{synopt:{cmd:r(reject)}}1 if H0 is rejected by the main inference{p_end}
{synopt:{cmd:r(reject_cv)}}1 if H0 is rejected by the {opt cv()} reference{p_end}
{synopt:{cmd:r(reps)}, {cmd:r(simreps)}, {cmd:r(level)}}settings{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol ecm}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(indepvars)}}variables ({cmd:r(indepvar)} also){p_end}
{synopt:{cmd:r(betatype)}}{cmd:known} or {cmd:estimated}{p_end}
{synopt:{cmd:r(trend)}, {cmd:r(constant)}, {cmd:r(cv)}}settings{p_end}
{synopt:{cmd:r(bootstrap)}, {cmd:r(multiplier)}, {cmd:r(bsresid)}, {cmd:r(seed)}}settings{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}rows {cmd:bootstrap sim normal em bdm kedq}; columns
{cmd:cv01 cv05 cv10 p reject}{p_end}
{synopt:{cmd:r(coef)}}ECM coefficients (row 1) and standard errors (row 2), in the order
Dx, level terms, deterministics, lags{p_end}
{synopt:{cmd:r(boot)}}B x 1 bootstrap statistics t*{p_end}


{marker references}{...}
{title:References}

{phang}
Banerjee, A., J. J. Dolado, and R. Mestre. 1998. Error-correction mechanism tests for
cointegration in a single-equation framework. {it:Journal of Time Series Analysis} 19:
267-283. doi:10.1111/1467-9892.00091.

{phang}
Engle, R. F. 1982. Autoregressive conditional heteroscedasticity with estimates of the
variance of United Kingdom inflation. {it:Econometrica} 50: 987-1007. doi:10.2307/1912773.

{phang}
Ericsson, N. R., and J. G. MacKinnon. 2002. Distributions of error correction tests for
cointegration. {it:Econometrics Journal} 5: 285-318. doi:10.1111/1368-423X.00085.

{phang}
Kremers, J. J. M., N. R. Ericsson, and J. J. Dolado. 1992. The power of cointegration
tests. {it:Oxford Bulletin of Economics and Statistics} 54: 325-348.
doi:10.1111/j.1468-0084.1992.tb00005.x. (Working-paper version: International Finance
Discussion Paper 431, Board of Governors of the Federal Reserve System, June 1992.)

{phang}
Mammen, E. 1993. Bootstrap and wild bootstrap for high dimensional linear models.
{it:Annals of Statistics} 21: 255-285. doi:10.1214/aos/1176349025.

{phang}
Mantalos, P. c. 2001. ECM-cointegration test with GARCH(1,1) errors. Working paper,
Department of Science and Health, Blekinge Institute of Technology, Sweden. Unpublished;
no DOI.

{phang}
Zivot, E. 2000. The power of single equation tests for cointegration when the cointegrating
vector is prespecified. {it:Econometric Theory} 16: 407-439. doi:10.1017/S0266466600163054.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the original method papers above together with the {cmd:cointvol} package.

{title:Also see}

{psee}
{helpb cointvol}, {helpb cointvol_resid:cointvol resid}, {helpb cointvol_rank:cointvol rank}
{p_end}
