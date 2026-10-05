{smcl}
{* *! version 1.0.0  01oct2026}{...}
{vieweralsosee "regress" "help regress"}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "aardl" "help aardl"}{...}
{vieweralsosee "fbardl" "help fbardl"}{...}
{vieweralsosee "fbnardl" "help fbnardl"}{...}
{vieweralsosee "mtnardl" "help mtnardl"}{...}
{vieweralsosee "estat" "help estat"}{...}
{viewerjumpto "Syntax" "bootdiag##syntax"}{...}
{viewerjumpto "Description" "bootdiag##description"}{...}
{viewerjumpto "Quick start" "bootdiag##quickstart"}{...}
{viewerjumpto "Why bootstrap" "bootdiag##why"}{...}
{viewerjumpto "Choosing a test" "bootdiag##choosing"}{...}
{viewerjumpto "Options" "bootdiag##options"}{...}
{viewerjumpto "The tests in detail" "bootdiag##tests"}{...}
{viewerjumpto "Bootstrap DGPs" "bootdiag##dgps"}{...}
{viewerjumpto "Choosing a DGP" "bootdiag##choosedgp"}{...}
{viewerjumpto "How many replications" "bootdiag##reps"}{...}
{viewerjumpto "The joint NHI test" "bootdiag##nhi"}{...}
{viewerjumpto "Fast double bootstrap" "bootdiag##fdb"}{...}
{viewerjumpto "Graphs" "bootdiag##graphs"}{...}
{viewerjumpto "Reading the output" "bootdiag##reading"}{...}
{viewerjumpto "Supported commands" "bootdiag##support"}{...}
{viewerjumpto "How the model is recovered" "bootdiag##recovery"}{...}
{viewerjumpto "The ARDL family" "bootdiag##ardlfamily"}{...}
{viewerjumpto "Worked examples" "bootdiag##examples"}{...}
{viewerjumpto "Reporting results" "bootdiag##reporting"}{...}
{viewerjumpto "Troubleshooting" "bootdiag##trouble"}{...}
{viewerjumpto "Stored results" "bootdiag##results"}{...}
{viewerjumpto "References" "bootdiag##references"}{...}
{viewerjumpto "Author" "bootdiag##author"}{...}
{title:Title}

{phang}
{bf:bootdiag} {hline 2} Bootstrap and Monte Carlo post-estimation diagnostic
tests for time-series regression and the ARDL family


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bootdiag} {it:subcommand} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt serial}}serial correlation{p_end}
{synopt:{opt het}}heteroskedasticity{p_end}
{synopt:{opt norm}}normality of the disturbances{p_end}
{synopt:{opt stab}}parameter stability{p_end}
{synopt:{opt spec}}functional form{p_end}
{synopt:{opt all}}the complete battery (the default){p_end}
{synopt:{opt nhi}}joint Jarque-Bera NHI test and all six sub-tests{p_end}
{synopt:{opt fdb}}fast double bootstrap, or pretest choice of B{p_end}
{synoptline}

{synopthdr:options}
{synoptline}
{syntab:Bootstrap design}
{synopt:{opt r:eps(#)}}replications; default {cmd:reps(999)}{p_end}
{synopt:{opt dgp(type)}}bootstrap DGP; default {cmd:dgp(wild)}{p_end}
{synopt:{opt w:eight(dist)}}auxiliary distribution; default {cmd:weight(rademacher)}{p_end}
{synopt:{opt ft:rans(form)}}residual transformation; default {cmd:ftrans(hc3)}{p_end}
{synopt:{opt bl:ock(#)}}block length; default data-driven{p_end}
{synopt:{opt cont:inuous}}Racine-MacKinnon continuous p-value{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}

{syntab:Test tuning}
{synopt:{opt lag:s(numlist)}}lags for Breusch-Godfrey; default {cmd:lags(1 2 4)}{p_end}
{synopt:{opt arch:lags(#)}}lags for ARCH LM; default {cmd:archlags(2)}{p_end}
{synopt:{opt trim(#)}}trimming for supF/aveF/expF; default {cmd:trim(0.15)}{p_end}
{synopt:{opt resetp:ow(#)}}highest power in RESET; default {cmd:resetpow(4)}{p_end}
{synopt:{opt nhil:ags(#)}}lags in the NHI independence component; default {cmd:nhilags(1)}{p_end}
{synopt:{opt fdbt:est(name)}}which test the FDB applies to; default {cmd:koenker}{p_end}

{syntab:Pretest choice of B}
{synopt:{opt pret:est}}choose B by pretesting instead of fixing it{p_end}
{synopt:{opt prea:lpha(#)}}level of interest; default {cmd:prealpha(0.05)}{p_end}
{synopt:{opt preb:eta(#)}}pretest level; default {cmd:prebeta(0.01)}{p_end}
{synopt:{opt premin(#)}}starting B; default {cmd:premin(99)}{p_end}
{synopt:{opt premax(#)}}maximum B; default {cmd:premax(12799)}{p_end}

{syntab:Model specification}
{synopt:{opt yl:ev(varname)}}dependent variable in levels{p_end}
{synopt:{opt xl:ev(varlist)}}long-run regressors in levels{p_end}
{synopt:{opt p(#)}}autoregressive order in levels{p_end}
{synopt:{opt q(numlist)}}lag order of each regressor{p_end}
{synopt:{opt case(#)}}PSS deterministic case, 1-5{p_end}
{synopt:{opt tol:erance(#)}}tolerance of the reconstruction check; default {cmd:1e-4}{p_end}
{synopt:{opt nover:ify}}skip the reconstruction check{p_end}

{syntab:Output}
{synopt:{opt notab:le}}suppress the table{p_end}
{synopt:{opt noasy:mptotic}}suppress the bootstrap-vs-asymptotic panel{p_end}
{synopt:{opt gr:aph}}produce the diagnostic graphs{p_end}
{synopt:{opt gna:me(name)}}stub for graph names{p_end}
{synopt:{opt sav:ing(filename)}}export the combined panel{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bootdiag} replaces the asymptotic p-values of the standard regression
diagnostics with bootstrap and Monte Carlo p-values. It runs after
{helpb regress}, {helpb newey}, {helpb ardl}, {cmd:aardl}, {cmd:fbardl},
{cmd:fbnardl} and {cmd:mtnardl}.

{pstd}
The test statistic is computed from the residuals and the design matrix of the
fitted equation, exactly as the source papers define it. Only the {it:null
distribution} changes: it is obtained by simulation rather than from a
chi-squared or F table.

{pstd}
{cmd:bootdiag} recovers the estimated equation from {cmd:e()} and
{bf:verifies} the reconstruction against the residual sum of squares the
fitting command reported. If the two disagree it stops with an error rather
than reporting a number that does not correspond to the model you estimated.


{marker quickstart}{...}
{title:Quick start}

{pstd}The whole battery after a dynamic regression{p_end}
{phang2}{cmd:. regress y L.y x z}{p_end}
{phang2}{cmd:. bootdiag all}{p_end}

{pstd}One family, more replications{p_end}
{phang2}{cmd:. bootdiag serial, reps(1999)}{p_end}

{pstd}With all ten graphs{p_end}
{phang2}{cmd:. bootdiag all, graph}{p_end}

{pstd}After an ARDL error-correction model{p_end}
{phang2}{cmd:. ardl y x z, maxlags(4) ec}{p_end}
{phang2}{cmd:. bootdiag all, graph}{p_end}


{marker why}{...}
{title:Why bootstrap these tests}

{pstd}
The asymptotic versions of these tests can be badly size-distorted in exactly
the samples applied time-series work uses. The table below is a Monte Carlo
experiment on an AR(1)-X process {it:under the null}, 300 replications,
nominal 5%. A correct test should reject 5% of the time.

{p 8 8 2}{txt}
{space 4}{hline 58}{break}
{space 4}test{space 20}n=60 rho=.5{space 2}n=60 rho=.9{space 2}n=150 rho=.9{break}
{space 4}{hline 58}{break}
{space 4}Koenker, asymptotic{space 7}0.113{space 8}0.197{space 9}0.163{break}
{space 4}Koenker, bootstrap{space 8}0.020{space 8}0.060{space 9}0.030{break}
{space 4}Jarque-Bera, asymptotic{space 3}0.040{space 8}0.027{space 9}0.027{break}
{space 4}Jarque-Bera, bootstrap{space 4}0.033{space 8}0.037{space 9}0.050{break}
{space 4}supF, bootstrap{space 11}0.057{space 8}0.050{space 9}0.057{break}
{space 4}{hline 58}
{p_end}

{pstd}
Three things to take from it.

{phang}
{bf:1.} The asymptotic heteroskedasticity test rejects a true null three to
four times too often, and gets worse as persistence rises. A researcher using
it would "find" heteroskedasticity in one sample in five when there is none.
This is the distortion documented by
{help bootdiag##CZ99:Cribari-Neto and Zarkos (1999)} and
{help bootdiag##DKBG04:Dufour et al. (2004)}.

{phang}
{bf:2.} The asymptotic Jarque-Bera test errs the other way: it is
{it:under}-sized, so it misses real non-normality. This is the finding of
{help bootdiag##KD00:Kilian and Demiroglu (2000)}.

{phang}
{bf:3.} The bootstrap versions sit on the nominal level in every cell,
including at rho = 0.9 where the asymptotic tests are worst.

{pstd}
A size-distorted test is not a conservative test. Over-rejection means
reporting problems that are not there; under-rejection means missing problems
that are. Neither is safe.


{marker choosing}{...}
{title:Choosing a test}

{pstd}
A short guide to which subcommand answers which question.

{p2colset 6 30 32 2}{...}
{p2col:{bf:Question}}{bf:Use}{p_end}
{p2line}
{p2col:Are the errors autocorrelated?}{cmd:bootdiag serial}{p_end}
{p2col:... and possibly heteroskedastic too?}{cmd:serial} and read LM_HR{p_end}
{p2col:Is the error variance constant?}{cmd:bootdiag het}{p_end}
{p2col:Is there ARCH?}{cmd:het}, read the ARCH LM row{p_end}
{p2col:Are the errors normal?}{cmd:bootdiag norm}{p_end}
{p2col:Are the coefficients stable?}{cmd:bootdiag stab}{p_end}
{p2col:Where is the break?}{cmd:stab, graph}, read {cmd:_chow}{p_end}
{p2col:Is the functional form right?}{cmd:bootdiag spec}{p_end}
{p2col:Is the model adequate overall?}{cmd:bootdiag nhi}{p_end}
{p2col:I want the most accurate p-value}{cmd:bootdiag fdb}{p_end}
{p2col:Replications are expensive}{cmd:fdb, pretest} or {cmd:continuous}{p_end}
{p2colreset}{...}

{pstd}
{bf:Within the serial correlation family}, three forms of Breusch-Godfrey are
reported for each lag order. Which to read:

{phang}
{bf:LM} is the familiar nR-squared form. Use it when you are confident the
errors are homoskedastic.

{phang}
{bf:LM_HR} is the heteroskedasticity-robust form. Use it when they might not
be. {help bootdiag##GT05:Godfrey and Tremayne (2005)} show that the plain LM
test is oversized under conditional heteroskedasticity, sometimes badly.

{phang}
{bf:MLM_HR} is their modification, which drops two asymptotically negligible
terms and so uses a less variable covariance estimate. It is their
recommendation, and usually the one to quote.

{pstd}
{bf:Within the heteroskedasticity family}, Breusch-Pagan assumes normal errors
and Koenker does not; Koenker is the safer default. White's test is an omnibus
test of the whole specification, not of heteroskedasticity alone, so a
rejection there does not by itself mean the variance is non-constant.
{help bootdiag##DKBG04:Dufour et al. (2004)} find Szroeter- and Hartley-type
tests the most powerful, and both are included.

{pstd}
{bf:Within the stability family}, CUSUM is sensitive to {it:permanent} shifts
in the coefficients, CUSUM of squares to {it:transitory} ones and to variance
breaks; {help bootdiag##DK96:Dufour and Kiviet (1996)} document the contrast.
supF is the formal test for a single break at an unknown date; aveF and expF
are the Andrews-Ploberger alternatives, which can have more power against
small breaks spread over the sample.


{marker options}{...}
{title:Options}

{dlgtab:Bootstrap design}

{phang}
{opt reps(#)} sets the number of bootstrap replications. See
{help bootdiag##reps:How many replications} below.

{phang}
{opt dgp(type)} selects the bootstrap data generating process. See
{help bootdiag##dgps:Bootstrap DGPs} and {help bootdiag##choosedgp:Choosing a DGP}.

{phang}
{opt weight(dist)} selects the auxiliary distribution for the wild bootstrap:
{cmd:rademacher} (default), {cmd:mammen} or {cmd:normal}.

{pmore}
The Rademacher distribution puts mass 1/2 on +1 and on -1. Mammen's two-point
distribution adds a skewness correction, E(v^3) = 1.
{help bootdiag##DF08:Davidson and Flachaire (2008)} show by Edgeworth expansion
and by simulation that Rademacher gives smaller errors in rejection
probability in essentially every case they examine, {it:even when the errors
are skewed}, and that it is insensitive to high-leverage observations. Use
Rademacher unless you have a specific reason not to.

{phang}
{opt ftrans(form)} sets the transformation f(u) applied to the residuals before
they are multiplied by the auxiliary weights: {cmd:none}, {cmd:hc1},
{cmd:hc2}, or {cmd:hc3} (default). These correspond to the HCCME forms of
MacKinnon and White (1985): f(u) = u, sqrt(n/(n-k))u, u/sqrt(1-h), u/(1-h).
HC3 is the most aggressive leverage correction and is normally best.

{phang}
{opt continuous} computes the p-value as (N+U)/(B+1) with U uniform on [0,1],
following {help bootdiag##RM07:Racine and MacKinnon (2007)}. This is exactly
uniform under the null for {it:any} finite B, removing the requirement that
alpha*(B+1) be an integer. Useful when replications are expensive.

{phang}
{opt seed(#)} sets the random-number seed. Always set it in work you intend to
report, so the p-values are reproducible.

{dlgtab:Model specification}

{phang}
{opt ylev()}, {opt xlev()}, {opt p()}, {opt q()} and {opt case()} let you state
the model explicitly instead of having it read from {cmd:e()}. Use them for an
equation {cmd:bootdiag} cannot recover, or to test a model you have built by
hand. {opt p()} is the autoregressive order {it:in levels} and {opt q()} gives
one lag order per variable in {opt xlev()}, also in levels.

{phang}
{opt tolerance(#)} and {opt noverify} control the reconstruction check. The
default tolerance of 1e-4 is a relative difference in the residual sum of
squares; a correct reconstruction normally agrees to machine precision.
{opt noverify} skips the check and is not recommended.


{marker tests}{...}
{title:The tests in detail}

{pstd}{bf:Serial correlation} {hline 2} {cmd:bootdiag serial}{p_end}

{p2colset 6 28 30 2}{...}
{p2col:{bf:Breusch-Godfrey LM}}Auxiliary regression of the residuals on the
original regressors and Q lagged residuals, with missing lags set to zero;
statistic is nR-squared, asymptotically chi2(Q).{p_end}
{p2col:{bf:BG robust LM_HR}}u'E{E'M(W)Omega M(W)E}^-1 E'u with Omega =
diag(u_t^2) from the restricted fit. Godfrey and Tremayne (2005) eq.(4).{p_end}
{p2col:{bf:BG modified MLM_HR}}u'E(Etil'Etil)^-1 E'u, their eq.(6), dropping
E'P(W2)E and E'P(W2)Omega P(W2)E, both o_p(T).{p_end}
{p2col:{bf:Durbin-Watson d}}sum(u_t - u_{t-1})^2 / sum u_t^2. Reported with an
{it:equal-tail} bootstrap p-value, which removes the inconclusive region
entirely.{p_end}
{p2col:{bf:First-order rho-hat}}The autocorrelation coefficient bootstrapped
directly, as Jeong and Chung (2001) recommend; symmetric two-tailed p-value.{p_end}
{p2colreset}{...}

{pstd}{bf:Heteroskedasticity} {hline 2} {cmd:bootdiag het}{p_end}

{p2colset 6 28 30 2}{...}
{p2col:{bf:Breusch-Pagan LM}}One half the explained sum of squares from
regressing u_t^2/sigtil^2 on the regressors, sigtil^2 = sum u_t^2 / n.{p_end}
{p2col:{bf:Koenker studentised}}nR-squared from u^2 on the regressors. Does
not assume normal errors; the safer default.{p_end}
{p2col:{bf:White general}}nR-squared on levels, squares and cross-products.
A joint test of first- {it:and} second-moment specification.{p_end}
{p2col:{bf:Engle ARCH LM}}nR-squared from u^2 on its own q lags.{p_end}
{p2col:{bf:Szroeter SKH}}sum 2(1-cos(pi t/(T+1)))u_(t)^2 / sum u_(t)^2.
Dufour et al. (2004) eq.(30).{p_end}
{p2col:{bf:Harrison-McCabe}}Ratio of the first half of the squared residuals
to the total. Rejects for {it:small} values, so a lower-tail p-value is used.{p_end}
{p2colreset}{...}

{pstd}{bf:Normality} {hline 2} {cmd:bootdiag norm}{p_end}

{p2colset 6 28 30 2}{...}
{p2col:{bf:Jarque-Bera}}T[b1/6 + (b2-3)^2/24].{p_end}
{p2col:{bf:Lobato-Velasco}}The same moments but studentised by sums of powers
of the sample autocovariances, so it is valid under weak dependence without a
kernel or a truncation lag.{p_end}
{p2col:{bf:Anderson-Darling}}EDF distance from the fitted normal, weighted
towards the tails.{p_end}
{p2colreset}{...}

{pstd}{bf:Parameter stability} {hline 2} {cmd:bootdiag stab}{p_end}

{p2colset 6 28 30 2}{...}
{p2col:{bf:CUSUM}}max |W(r)| / [sqrt(T-K-1) + 2(r-K-1)/sqrt(T-K-1)] on
recursive residuals, with sigma estimated about the mean of those residuals
(Harvey's correction, which raises power under a shift).{p_end}
{p2col:{bf:CUSUM of squares}}max |S_r - r/m|.{p_end}
{p2col:{bf:supF}}max over candidate break dates of the Chow F statistic,
trimmed at {opt trim()}.{p_end}
{p2col:{bf:aveF / expF}}The Andrews-Ploberger average and exponential
versions.{p_end}
{p2colreset}{...}

{pmore}
Note that CUSUM has {it:no} power against shifts orthogonal to the mean
regressor: Kraemer, Ploberger and Alt (1988) Theorem 2. If CUSUM is quiet but
supF is not, that is the likely reason, and supF should be believed.

{pstd}{bf:Functional form} {hline 2} {cmd:bootdiag spec}{p_end}

{p2colset 6 28 30 2}{...}
{p2col:{bf:Ramsey RESET}}F test on powers 2..{opt resetpow()} of the fitted
values added to the regression.{p_end}
{p2col:{bf:Cramer-von Mises}}(1/n^2) sum_l [sum_i u_i 1(X_i <= X_l)]^2 on the
marked empirical process.{p_end}
{p2col:{bf:Kolmogorov-Smirnov}}The sup-norm version of the same process.{p_end}
{p2colreset}{...}

{pmore}
The last two are {it:consistent} specification tests: they have power against
any departure from the conditional-mean restriction, not only against the
polynomial alternatives RESET looks at.
{help bootdiag##Stu98:Stute et al. (1998)} prove the wild bootstrap is the
right way to get their critical values, and that the pairs bootstrap is
{it:inconsistent} here.


{marker dgps}{...}
{title:Bootstrap DGPs}

{p2colset 6 22 24 2}{...}
{p2col:{cmd:wild}}Recursive wild bootstrap (default). y* is regenerated
recursively and the errors are f(u)*v.{p_end}
{p2col:{cmd:residual}}Recursive residual bootstrap: iid resampling of
rescaled, recentred residuals.{p_end}
{p2col:{cmd:fixed}}Fixed-regressor wild bootstrap. For comparison only.{p_end}
{p2col:{cmd:sieve}}AR sieve with the order chosen by AIC.{p_end}
{p2col:{cmd:block}}Moving block bootstrap.{p_end}
{p2col:{cmd:stationary}}Stationary bootstrap, geometric block lengths.{p_end}
{p2col:{cmd:blockwild}}Block wild bootstrap, one weight per block.{p_end}
{p2col:{cmd:normal}}Parametric Gaussian.{p_end}
{p2colreset}{...}

{pstd}
{bf:Why the default is recursive.} In a model with a lagged dependent variable,
holding y fixed and perturbing only the error term is incoherent: the
regenerated y* no longer matches the y_{t-1} used as a regressor.
{help bootdiag##Mac07:MacKinnon (2007, section 7)} finds that for the supF test
in an AR(1) model the recursive residual bootstrap works well at every value of
the autoregressive parameter, while the fixed-regressor bootstrap performs
about as badly as the asymptotic test.
{help bootdiag##OW05:O'Reilly and Whelan (2005)} reach the same conclusion and
add that the wild version is needed once the error variance is not constant.
{cmd:dgp(fixed)} is provided so you can see this for yourself.


{marker choosedgp}{...}
{title:Choosing a DGP}

{p2colset 6 34 36 2}{...}
{p2col:{bf:What you believe about the errors}}{bf:Use}{p_end}
{p2line}
{p2col:iid}{cmd:dgp(residual)}{p_end}
{p2col:heteroskedastic, unknown form}{cmd:dgp(wild)} {it:(default)}{p_end}
{p2col:serially correlated, homoskedastic}{cmd:dgp(sieve)}{p_end}
{p2col:dependence of unknown form}{cmd:dgp(stationary)}{p_end}
{p2col:testing a mean or variance break}{cmd:dgp(blockwild)}{p_end}
{p2col:normal, and you want an exact test}{cmd:dgp(normal)}{p_end}
{p2colreset}{...}

{pstd}
{bf:A caution about dgp(sieve).} The AR sieve assumes the innovations are
homoskedastic, so it rules out ARCH and GARCH. Do not use it if the ARCH LM
test rejects.

{pstd}
{bf:A caution about the wild bootstrap and squared residuals.} A Rademacher
draw sets u* = +/- u, so |u*| = |u| exactly. Any statistic that depends only on
{it:squared} residuals is then nearly constant across bootstrap samples. This
does not affect the p-values reported in the table, but it does mean the CUSUM
of squares {it:band} would collapse, so {cmd:bootdiag} draws the stability
bands with the residual bootstrap and says so on the graph.

{pstd}
{bf:When it is exact.} {help bootdiag##DKBG04:Dufour et al. (2004)} prove that
every statistic satisfying S(cy + Xd, X) = S(y, X) for c > 0 is pivotal given
X. All the heteroskedasticity statistics above qualify. With {cmd:dgp(normal)},
or any fully specified error distribution, and alpha*(B+1) an integer, the
Monte Carlo test is then {it:exact in finite samples} - not approximate.


{marker reps}{...}
{title:How many replications}

{pstd}
{help bootdiag##DM00:Davidson and MacKinnon (2000)} show the power loss from a
finite B is roughly proportional to 1/(B+1). Their guidance:

{p2colset 8 26 28 2}{...}
{p2col:{bf:Level}}{bf:Minimum B}{p_end}
{p2col:5%}399{p_end}
{p2col:1%}1499{p_end}
{p2colreset}{...}

{pstd}
The default of 999 satisfies the requirement that alpha*(B+1) be an integer at
both 5% and 1%, and is adequate for most work. Use 1999 or 4999 for results you
intend to publish, and set {opt seed()}.

{pstd}
Two ways to spend fewer replications without losing exactness:

{phang}
{opt continuous} gives a p-value that is exactly uniform under the null for any
B, so alpha*(B+1) need not be an integer
({help bootdiag##RM07:Racine and MacKinnon 2007}).

{phang}
{cmd:fdb, pretest} raises B as 2B+1 only while the p-value is still ambiguous
relative to {opt prealpha()}, so B stays small when the answer is clear-cut and
grows only when power demands it
({help bootdiag##DM00:Davidson and MacKinnon 2000}, section 3).

{phang2}{cmd:. bootdiag fdb, pretest fdbtest(koenker)}{p_end}


{marker nhi}{...}
{title:The joint NHI test}

{pstd}
{cmd:bootdiag nhi} reports the test of
{help bootdiag##JB80:Jarque and Bera (1980)}, which is not the familiar
skewness-kurtosis statistic but the {it:joint} test of normality,
homoskedasticity and serial independence:

{p 8 8 2}
LM_NHI = LM_N + LM_H + LM_I{break}
{space 2}LM_N = T[b1/6 + (b2-3){superscript:2}/24]{space 6}(normality){break}
{space 2}LM_H = (1/2) f'Z(Z'MZ){superscript:-1}Z'f{space 6}(Breusch-Pagan){break}
{space 2}LM_I = T r'r{space 6}(Breusch)

{pstd}
with f_t = u_t{superscript:2}/mu2 - 1 and r_j the residual autocorrelations.

{pstd}
Because the decomposition is additive, the joint test, the three
one-directional tests and the three two-directional combinations all come from
a single bootstrap loop and are mutually consistent. The reported statistics
satisfy LM_N + LM_H + LM_I = LM_NHI exactly, which is a useful check:

{phang2}{cmd:. bootdiag nhi, reps(999)}{p_end}
{phang2}{cmd:. matrix R = r(results)}{p_end}
{phang2}{cmd:. di R[2,1] + R[3,1] + R[4,1] - R[1,1]}{space 4}// should be 0{p_end}

{pstd}
This is more informative than running the three tests separately. A model can
pass each one-directional test and still fail the joint test, because the joint
test accumulates evidence across all three directions.


{marker fdb}{...}
{title:Fast double bootstrap}

{pstd}
A single bootstrap test still has an error in rejection probability. A double
bootstrap reduces it, but needs B(B+1) statistics. The fast double bootstrap of
{help bootdiag##DM07:Davidson and MacKinnon (2007)} draws one second-level
sample per first-level sample and so needs only 2B+1:

{p 8 8 2}
p_F = (1/B) sum 1[tau*_j > Qhat*_B(1 - phat)]

{pstd}
where Qhat*_B is the (1 - phat) quantile of the second-level statistics.
{cmd:bootdiag fdb} reports the single-bootstrap p-value alongside the FDB
p-value, so the size of the refinement is visible.

{pstd}
The FDB requires the statistic to be asymptotically independent of the
bootstrap DGP. That holds for the residual and wild bootstraps when the
parameters are estimated under the null, which is what {cmd:bootdiag} does.

{phang2}{cmd:. bootdiag fdb, fdbtest(koenker) reps(999)}{p_end}

{pstd}
{opt fdbtest()} accepts {cmd:bg}, {cmd:bp}, {cmd:koenker}, {cmd:white},
{cmd:arch}, {cmd:jb}, {cmd:reset} and {cmd:supf}.


{marker graphs}{...}
{title:Graphs}

{pstd}
{opt graph} produces up to ten figures, named {it:stub}{cmd:_}{it:kind} where
the stub is set by {opt gname()}:

{p2colset 8 24 26 2}{...}
{p2col:{cmd:_null}}bootstrap null density, observed value, 5% critical value{p_end}
{p2col:{cmd:_pdisc}}P-value discrepancy plot{p_end}
{p2col:{cmd:_hist}}residual histogram against the fitted normal{p_end}
{p2col:{cmd:_qq}}normal quantile plot{p_end}
{p2col:{cmd:_het}}squared residuals against fitted values, with lowess{p_end}
{p2col:{cmd:_cusum}}CUSUM with bootstrap bands{p_end}
{p2col:{cmd:_cusumsq}}CUSUM of squares with bootstrap bands{p_end}
{p2col:{cmd:_chow}}Chow F sequence with the bootstrap supF critical value{p_end}
{p2col:{cmd:_acf}}residual correlogram with bootstrap bands{p_end}
{p2col:{cmd:_panel}}all of the above combined{p_end}
{p2colreset}{...}

{pstd}
Three of these have no standard Stata equivalent.

{phang}
{bf:CUSUM bands.} Brown, Durbin and Evans (1975) draw straight asymptotic
boundaries. {help bootdiag##KPA88:Kraemer, Ploberger and Alt (1988)} show these
are unreliable once a lagged dependent variable is present, because the
recursive residuals are then neither normal nor independent. {cmd:bootdiag}
draws the pointwise quantiles of the bootstrap CUSUM paths under the null
instead, so the band inherits whatever finite-sample behaviour the model
actually has.

{phang}
{bf:Correlogram bands.} The usual plus-or-minus 2/sqrt(n) lines assume the
series is iid. Residuals from a fitted dynamic model are not: their low-order
autocorrelations are shrunk towards zero by the estimation itself. The
bootstrap bands reproduce that shrinkage and are typically {it:narrower} than
the nominal lines at short lags, which makes the test more, not less,
sensitive.

{phang}
{bf:P-value discrepancy plot.} In the style of Davidson and MacKinnon (1998),
this plots actual minus nominal rejection frequency across all levels from 1%
to 40%, using the bootstrap null as the truth. A curve above zero means the
asymptotic test over-rejects at that level. It shows the whole size distortion,
not just its value at 5%.


{marker reading}{...}
{title:Reading the output}

{pstd}
The header reports where the equation came from and whether the reconstruction
was verified:

{p 8 8 2}{txt}
{space 2}Fitted by{space 20}: ardl  (model read from ardl e(regressors)){break}
{space 2}Model reconstruction{space 9}: verified on RSS (rel. diff 0.0e+00){break}
{space 2}ARDL order{space 19}: p = 2, q = (0 0)   PSS case 3{break}
{space 2}Observations / parameters{space 4}: 147 / 5{break}
{space 2}Bootstrap DGP{space 16}: recursive wild{break}
{space 30}weights = rademacher, f(u) = hc3
{p_end}

{pstd}
A relative difference of order 1e-16 means the reconstruction is exact. If it
ever fails, {cmd:bootdiag} stops; it does not report numbers for a model you
did not estimate.

{pstd}
In the table, {bf:Boot p} is the Monte Carlo p-value (N*Ghat+1)/(N+1) of
Dufour et al. (2004), {bf:5% c.v.} is the empirical 95th percentile of the
bootstrap null, and {bf:H0} summarises the decision. Stars follow the usual
convention.

{pstd}
The {bf:Bootstrap vs asymptotic} panel at the foot is the one to look at when
deciding whether the bootstrap mattered. A {it:positive} difference means the
asymptotic test over-rejects relative to the bootstrap; a large positive
difference means a result you would have reported as significant is not.


{marker support}{...}
{title:Supported commands}

{p2colset 6 20 22 2}{...}
{p2col:{helpb regress}}design read from the column names of e(b){p_end}
{p2col:{helpb newey}}same{p_end}
{p2col:{helpb ardl}}design read from e(regressors){p_end}
{p2col:{cmd:aardl}}design read from e(ecmvars){p_end}
{p2col:{cmd:fbardl}}1.3.1 and later: design read from e(bdvars){p_end}
{p2col:{cmd:fbnardl}}2.0.1 and later: design read from e(bdvars){p_end}
{p2col:{cmd:mtnardl}}1.0.1 and later: design read from e(bdvars){p_end}
{p2colreset}{...}


{marker recovery}{...}
{title:How the model is recovered}

{pstd}
This section matters if you want to know exactly what is being tested.

{pstd}
{cmd:bootdiag} does {it:not} trust {cmd:e(p)} or {cmd:e(q_*)}, because the
commands label their lag orders differently. {cmd:aardl}, for instance, reports
"ARDL(1,0,0)" for a model whose {cmd:e(ecmvars)} is
{cmd:L.y L.x L.z L1.D.y D.x D.z}, which in levels is an ARDL(2,1,1).

{pstd}
Instead it parses the regressor list itself and reads off the implied maximum
lag of every base variable:

{p2colset 8 26 28 2}{...}
{p2col:{bf:Term}}{bf:implied lag}{p_end}
{p2col:{cmd:x}}0{p_end}
{p2col:{cmd:L.x}, {cmd:L1.x}}1{p_end}
{p2col:{cmd:L#.x}}#{p_end}
{p2col:{cmd:D.x}}1{p_end}
{p2col:{cmd:LD.x}, {cmd:L1D.x}}2{p_end}
{p2col:{cmd:L#D.x}}# + 1{p_end}
{p2col:{cmd:L(a/b).x}}b{p_end}
{p2col:{cmd:L(a/b)D.x}}b + 1{p_end}
{p2colreset}{...}

{pstd}
Terms that are not functions of a model variable - a constant, a trend, Fourier
terms, dummies - are treated as deterministic and held fixed in the bootstrap.

{pstd}
From the recovered levels order the conditional ECM is rebuilt as an exact
reparameterisation, so the residuals, and hence the residual sum of squares,
are identical to the levels form. That is the invariant the verification
checks. One subtlety is handled explicitly: when q_i = 0 the level term is
dated t rather than t-1 and there is no difference term, because b_0*x_t cannot
be split into x_{t-1} and D.x_t without imposing that the two coefficients be
equal. This is why {cmd:ardl}'s EC output shows x at time t when q = 0.

{pstd}
The estimation sample is forced to match {cmd:e(N)}. The ARDL commands fix
their sample at maxlag+1 so that every candidate model in the lag search is
compared on a common sample; the selected p is usually smaller, so a naive
start would use extra observations and the fit would not reproduce.


{marker ardlfamily}{...}
{title:The ARDL family}

{pstd}
Older versions of {cmd:fbardl}, {cmd:fbnardl} and {cmd:mtnardl} wrapped their
estimation in {helpb preserve}/{helpb restore} and called {cmd:ereturn post}
without a coefficient vector. The variables they constructed - Fourier terms,
asymmetric partial sums, threshold regimes - were dropped before the command
returned, so nothing was left for a post-estimation command to read.

{pstd}
{cmd:fbardl} 1.3.1, {cmd:fbnardl} 2.0.1 and {cmd:mtnardl} 1.0.1 fix this. They
post the coefficient vector, record the regressor list in {cmd:e(bdvars)} and
the dependent variable in {cmd:e(bddepvar)}, and rebuild the constructed
columns after the restore. {cmd:bootdiag} then works after them directly:

{phang2}{cmd:. fbnardl y x z, decompose(x) maxlag(4)}{p_end}
{phang2}{cmd:. bootdiag all, reps(999) graph}{p_end}

{pstd}
With an older version, or for any equation {cmd:bootdiag} did not fit, build
the regressors yourself and state the model:

{phang2}{cmd:. qui gen double dx   = D.x}{p_end}
{phang2}{cmd:. qui gen double xpos = sum(cond(dx>0, dx, 0))}{p_end}
{phang2}{cmd:. qui gen double xneg = sum(cond(dx<0, dx, 0))}{p_end}
{phang2}{cmd:. bootdiag all, ylev(y) xlev(xpos xneg z) p(1) q(1 1 0)}{p_end}


{marker examples}{...}
{title:Worked examples}

{pstd}{bf:1. The basic workflow}{p_end}
{phang2}{cmd:. regress y L.y x z}{p_end}
{phang2}{cmd:. estat bgodfrey, lags(1 2 4)}{space 4}// the asymptotic answer{p_end}
{phang2}{cmd:. estat hettest, rhs iid}{p_end}
{phang2}{cmd:. bootdiag all, reps(999) seed(1)}{space 4}// the bootstrap answer{p_end}

{pstd}{bf:2. Serial correlation under suspected heteroskedasticity}{p_end}
{phang2}{cmd:. bootdiag serial, reps(1999) lags(1 2 4 8)}{p_end}
{pmore}Read the MLM_HR rows: they are robust and have the least variable
covariance estimate.{p_end}

{pstd}{bf:3. Seeing whether the bootstrap mattered}{p_end}
{phang2}{cmd:. bootdiag het, reps(999)}{p_end}
{pmore}Look at the "Bootstrap vs asymptotic" panel. A large positive difference
means the asymptotic test was over-rejecting.{p_end}

{pstd}{bf:4. Comparing DGPs, including the one that fails}{p_end}
{phang2}{cmd:. bootdiag het, dgp(wild) notable}{p_end}
{phang2}{cmd:. bootdiag het, dgp(residual) notable}{p_end}
{phang2}{cmd:. bootdiag het, dgp(fixed) notable}{space 4}// expected to be unreliable{p_end}

{pstd}{bf:5. Normality with the AR sieve}{p_end}
{phang2}{cmd:. bootdiag norm, reps(999) dgp(sieve)}{p_end}
{pmore}Psaradakis and Vavra (2020) fit an AR sieve to the residuals and draw
the innovations from N(0,1), which imposes the null and is what gives the test
its power.{p_end}

{pstd}{bf:6. Stability, with the break located}{p_end}
{phang2}{cmd:. bootdiag stab, reps(999) trim(0.15) graph}{p_end}
{pmore}The {cmd:_chow} graph shows the whole Chow F sequence with the bootstrap
supF critical value, so you can see both whether there is a break and where.{p_end}

{pstd}{bf:7. The most accurate p-value available}{p_end}
{phang2}{cmd:. bootdiag fdb, fdbtest(koenker) reps(999)}{p_end}

{pstd}{bf:8. A model bootdiag did not fit}{p_end}
{phang2}{cmd:. bootdiag all, ylev(y) xlev(x z) p(2) q(1 0) case(3)}{p_end}

{pstd}
A full annotated script ships with the package as
{bf:bootdiag_example.do}.


{marker reporting}{...}
{title:Reporting results}

{pstd}
For a paper, state: the bootstrap DGP, the auxiliary distribution, the residual
transformation, the number of replications, and the seed. For example:

{pmore}
"Diagnostic p-values are recursive wild bootstrap Monte Carlo p-values with
Rademacher weights and the HC3 residual transformation, 1999 replications
(Davidson and Flachaire 2008; MacKinnon 2007)."

{pstd}
This matters. As MacKinnon (2006) puts it, saying only that something is a
"bootstrap p-value" gives the reader grossly insufficient information, because
the answer depends on which of many bootstrap DGPs was used.

{pstd}
The results matrix is in {cmd:r(results)} and can be written out with
{helpb esttab} or {helpb putexcel}.


{marker trouble}{...}
{title:Troubleshooting}

{pstd}
{bf:"could not reproduce the fitted model from e()"} {hline 2} the equation
{cmd:bootdiag} rebuilt does not match the one you estimated. Usually the
fitting command used something {cmd:bootdiag} cannot see: an extra exogenous
regressor, a different deterministic case, or a transformed variable. State the
model explicitly with {opt ylev()}, {opt xlev()}, {opt p()} and {opt q()}.

{pstd}
{bf:"does not leave its estimated equation behind"} {hline 2} you are running
an older {cmd:fbardl}, {cmd:fbnardl} or {cmd:mtnardl}. Update it, or state the
model explicitly. See {help bootdiag##ardlfamily:The ARDL family}.

{pstd}
{bf:A statistic is reported as missing} {hline 2} the sample is too short for
that test. Szroeter and Harrison-McCabe need a reasonable number of
observations; supF needs more than 2k observations in each regime after
trimming.

{pstd}
{bf:The run is slow} {hline 2} {cmd:bootdiag all} with supF is the expensive
case, because every replication re-estimates the model at every candidate break
point. Use a single family, raise {opt trim()}, or use {opt continuous} with a
smaller {opt reps()}.

{pstd}
{bf:The CUSUM band looks too narrow} {hline 2} this is expected and correct if
you forced {cmd:dgp(wild)} for the graph; see the note under
{help bootdiag##choosedgp:Choosing a DGP}.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:bootdiag} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(reps)}}replications used{p_end}
{synopt:{cmd:r(N)}}observations in the rebuilt equation{p_end}
{synopt:{cmd:r(k)}}parameters in the rebuilt equation{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(dgp)}}bootstrap DGP used{p_end}
{synopt:{cmd:r(weight)}}auxiliary distribution{p_end}
{synopt:{cmd:r(ftrans)}}residual transformation{p_end}
{synopt:{cmd:r(cmd)}}the command bootdiag ran after{p_end}
{synopt:{cmd:r(source)}}where the equation was read from{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}one row per test; columns {cmd:statistic},
{cmd:p_boot}, {cmd:cv5}, {cmd:cv10}, {cmd:cv1}, {cmd:p_asym}{p_end}

{pstd}
After {cmd:fdb} the columns are {cmd:statistic}, {cmd:p_single},
{cmd:q_second}, {cmd:p_fdb}; with {opt pretest} they are {cmd:statistic},
{cmd:p_boot}, {cmd:B_used}.


{marker references}{...}
{title:References}

{marker BP79}{...}
{phang}Breusch, T. S., and A. R. Pagan. 1979. A simple test for
heteroscedasticity and random coefficient variation.
{it:Econometrica} 47: 1287-1294.

{marker BDE75}{...}
{phang}Brown, R. L., J. Durbin, and J. M. Evans. 1975. Techniques for testing
the constancy of regression relationships over time.
{it:Journal of the Royal Statistical Society, Series B} 37: 149-192.

{marker Buhl97}{...}
{phang}Buehlmann, P. 1997. Sieve bootstrap for time series.
{it:Bernoulli} 3: 123-148.

{marker CZ99}{...}
{phang}Cribari-Neto, F., and S. G. Zarkos. 1999. Bootstrap methods for
heteroskedastic regression models: evidence on estimation and testing.
{it:Econometric Reviews} 18: 211-228.

{marker DF08}{...}
{phang}Davidson, R., and E. Flachaire. 2008. The wild bootstrap, tamed at last.
{it:Journal of Econometrics} 146: 162-169.

{marker DM00}{...}
{phang}Davidson, R., and J. G. MacKinnon. 2000. Bootstrap tests: how many
bootstraps? {it:Econometric Reviews} 19: 55-68.

{marker DM07}{...}
{phang}Davidson, R., and J. G. MacKinnon. 2007. Improving the reliability of
bootstrap tests with the fast double bootstrap.
{it:Computational Statistics and Data Analysis} 51: 3259-3281.

{marker DC96}{...}
{phang}Diebold, F. X., and C. Chen. 1996. Testing structural stability with
endogenous breakpoint: a size comparison of analytic and bootstrap procedures.
{it:Journal of Econometrics} 70: 221-241.

{marker DK96}{...}
{phang}Dufour, J.-M., and J. F. Kiviet. 1996. Exact tests for structural change
in first-order dynamic models. {it:Journal of Econometrics} 70: 39-68.

{marker DKBG04}{...}
{phang}Dufour, J.-M., L. Khalaf, J.-T. Bernard, and I. Genest. 2004.
Simulation-based finite-sample tests for heteroskedasticity and ARCH effects.
{it:Journal of Econometrics} 122: 317-347.

{marker Fla05}{...}
{phang}Flachaire, E. 2005. Bootstrapping heteroskedastic regression models:
wild bootstrap vs. pairs bootstrap.
{it:Computational Statistics and Data Analysis} 49: 361-376.

{marker GT05}{...}
{phang}Godfrey, L. G., and A. R. Tremayne. 2005. The wild bootstrap and
heteroskedasticity-robust tests for serial correlation in dynamic regression
models. {it:Computational Statistics and Data Analysis} 49: 377-395.

{marker JB80}{...}
{phang}Jarque, C. M., and A. K. Bera. 1980. Efficient tests for normality,
homoscedasticity and serial independence of regression residuals.
{it:Economics Letters} 6: 255-259.

{marker JC01}{...}
{phang}Jeong, J., and S. Chung. 2001. Bootstrap tests for autocorrelation.
{it:Computational Statistics and Data Analysis} 38: 49-69.

{marker KD00}{...}
{phang}Kilian, L., and U. Demiroglu. 2000. Residual-based tests for normality
in autoregressions: asymptotic theory and simulation evidence.
{it:Journal of Business and Economic Statistics} 18: 40-50.

{marker KPA88}{...}
{phang}Kraemer, W., W. Ploberger, and R. Alt. 1988. Testing for structural
change in dynamic models. {it:Econometrica} 56: 1355-1369.

{marker Kun89}{...}
{phang}Kuensch, H. R. 1989. The jackknife and the bootstrap for general
stationary observations. {it:Annals of Statistics} 17: 1217-1241.

{marker LB20}{...}
{phang}Lee, T., and C. Baek. 2020. Block wild bootstrap-based CUSUM tests
robust to high persistence and misspecification.
{it:Computational Statistics and Data Analysis} 150: 106996.

{marker Mac06}{...}
{phang}MacKinnon, J. G. 2006. Bootstrap methods in econometrics.
{it:Economic Record} 82: S2-S18.

{marker Mac07}{...}
{phang}MacKinnon, J. G. 2007. Bootstrap hypothesis testing. Queen's Economics
Department Working Paper 1127.

{marker Mam93}{...}
{phang}Mammen, E. 1993. Bootstrap and wild bootstrap for high dimensional
linear models. {it:Annals of Statistics} 21: 255-285.

{marker MW85}{...}
{phang}MacKinnon, J. G., and H. White. 1985. Some heteroskedasticity-consistent
covariance matrix estimators with improved finite sample properties.
{it:Journal of Econometrics} 29: 305-325.

{marker OW05}{...}
{phang}O'Reilly, G., and K. Whelan. 2005. Testing parameter stability: a wild
bootstrap approach. Central Bank of Ireland Research Technical Paper 8/RT/05.

{marker PR94}{...}
{phang}Politis, D. N., and J. P. Romano. 1994. The stationary bootstrap.
{it:Journal of the American Statistical Association} 89: 1303-1313.

{marker PV20}{...}
{phang}Psaradakis, Z., and M. Vavra. 2020. Normality tests for dependent data:
large-sample and bootstrap approaches.
{it:Communications in Statistics - Simulation and Computation} 49: 283-304.

{marker RM07}{...}
{phang}Racine, J. S., and J. G. MacKinnon. 2007. Simulation-based tests that
can use any number of simulations.
{it:Communications in Statistics - Simulation and Computation} 36: 357-365.

{marker Stu98}{...}
{phang}Stute, W., W. Gonzalez Manteiga, and M. Presedo Quindimil. 1998.
Bootstrap approximations in model checks for regression.
{it:Journal of the American Statistical Association} 93: 141-149.

{marker Whi80}{...}
{phang}White, H. 1980. A heteroskedasticity-consistent covariance matrix
estimator and a direct test for heteroskedasticity.
{it:Econometrica} 48: 817-838.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
Independent Researcher{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}


{title:Also see}

{psee}
Online: {helpb regress}, {helpb newey}, {helpb ardl}, {helpb aardl},
{helpb fbardl}, {helpb fbnardl}, {helpb mtnardl}, {helpb estat}
{p_end}
