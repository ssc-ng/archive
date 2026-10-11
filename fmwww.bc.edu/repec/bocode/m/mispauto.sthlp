{smcl}
{* *! version 1.0.1  07oct2026}{...}
{vieweralsosee "mispauto methods" "help mispauto_methods"}{...}
{vieweralsosee "mispauto thursby" "help mispauto_thursby"}{...}
{vieweralsosee "mispauto godfrey" "help mispauto_godfrey"}{...}
{vieweralsosee "mispauto ghutton" "help mispauto_ghutton"}{...}
{vieweralsosee "mispauto knottnerus" "help mispauto_knottnerus"}{...}
{vieweralsosee "mispauto postestimation" "help mispauto_postestimation"}{...}
{vieweralsosee "[R] regress postestimation time series" "help regress_postestimation_time_series"}{...}
{viewerjumpto "Syntax" "mispauto##syntax"}{...}
{viewerjumpto "Description" "mispauto##description"}{...}
{viewerjumpto "The problem" "mispauto##problem"}{...}
{viewerjumpto "Which strategy" "mispauto##which"}{...}
{viewerjumpto "Options" "mispauto##options"}{...}
{viewerjumpto "Interpreting the output" "mispauto##interp"}{...}
{viewerjumpto "Remarks and practical guidance" "mispauto##remarks"}{...}
{viewerjumpto "Examples" "mispauto##examples"}{...}
{viewerjumpto "Stored results" "mispauto##results"}{...}
{viewerjumpto "References" "mispauto##refs"}{...}
{viewerjumpto "Author" "mispauto##author"}{...}

{title:Title}

{phang}
{bf:mispauto} {hline 2} Discriminating between autocorrelation and
misspecification in regression analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mispauto} {it:subcommand} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{helpb mispauto_thursby:thursby}}Thursby's (1981) three-procedure
strategy: Durbin{c 150}Watson, RESET and LRS, resolved by his eight-cell rule{p_end}
{synopt :{helpb mispauto_godfrey:godfrey}}Godfrey's (1987) ordered sequence of
four hypotheses, headed by an autocorrelation-robust check{p_end}
{synopt :{helpb mispauto_ghutton:ghutton}}Godfrey and Hutton's (1994) two-stage
procedure for errors in variables and simultaneity{p_end}
{synopt :{helpb mispauto_knottnerus:knottnerus}}Knottnerus's (1985) diagnostics:
when do the strategies above go blind{p_end}
{synopt :{opt all}}run all of them and print the verdicts side by side{p_end}
{synoptline}

{pstd}
{cmd:ghutton} and {cmd:all} accept an instrument list:

{p 8 17 2}
{cmd:mispauto ghutton} {it:depvar} [{it:varlist1}]
{cmd:(}{it:varlist2} {cmd:=} {it:varlist_iv}{cmd:)} {ifin}
[{cmd:,} {it:options}]

{pstd}
The data must be {helpb tsset} as a single time series. If {it:depvar} and
{it:indepvars} are omitted, the model is taken from the last {helpb regress};
see {helpb mispauto_postestimation:mispauto postestimation}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mispauto} implements, in one command, the four published strategies for
deciding {it:what a significant Durbin{c 150}Watson statistic actually means}.
Each returns a single diagnosis and a recommended response, together with the
individual test statistics, the adjusted significance levels, and journal-ready
tables and plots.

{pstd}
The four strategies are a single connected literature, not four alternatives
chosen at random. {bf:Thursby (1981)} proposed the original three-test
procedure; {bf:Knottnerus (1985)} showed it is blind to important cases;
{bf:Thursby (1985)} replied; {bf:Godfrey (1987)} proposed a replacement that is
not subject to those criticisms; and {bf:Godfrey and Hutton (1994)} extended
the same logic to errors in variables and simultaneity. The command reproduces
all of them faithfully, including the parts later authors showed to be weak,
and tells you when those weaknesses bite on your data.


{marker problem}{...}
{title:The problem these strategies solve}

{pstd}
A significant Durbin{c 150}Watson statistic is consistent with at least four
quite different states of the world:

{p2colset 9 24 26 2}{...}
{p2col :{bf:NP}}no problem with the regression{p_end}
{p2col :{bf:AR(1)}}first-order autoregressive disturbances{p_end}
{p2col :{bf:NAR}}non-white-noise disturbances other than AR(1){p_end}
{p2col :{bf:MS}}misspecification: an omitted variable or the wrong functional
form{p_end}
{p2colreset}{...}

{pstd}
The responses are incompatible. Correcting for AR(1) when the real problem is a
missing regressor leaves the estimator inconsistent; respecifying when the real
problem is AR(1) throws away an efficient estimator. Guessing from the
Durbin{c 150}Watson statistic alone cannot separate them, because that statistic
has power against all four.


{marker which}{...}
{title:Which strategy should I use}

{pstd}
{bf:Use}{space 1}{helpb mispauto_godfrey:godfrey}{space 1}{bf:unless you have a
specific reason not to.} It is the most recent of the three autocorrelation
strategies and was designed to be robust to precisely the failures Knottnerus
identified in Thursby's. Its first stage checks for misspecification using an
autocorrelation-consistent covariance matrix, so a rejection there cannot be
blamed on serial correlation.

{pstd}
{bf:Use}{space 1}{helpb mispauto_thursby:thursby}{space 1}when you need the
original published procedure, for example to reproduce or to compare with
earlier work. Read the Knottnerus warnings that the command prints.

{pstd}
{bf:Use}{space 1}{helpb mispauto_ghutton:ghutton}{space 1}when the question is
whether to instrument. It is a different question from the other three: it
asks whether a significant Hausman statistic really reflects simultaneity or
measurement error, rather than some other misspecification that instrumenting
will not repair.

{pstd}
{bf:Always run}{space 1}{helpb mispauto_knottnerus:knottnerus}{space 1}as well.
It costs nothing and tells you whether your series falls in one of the three
cases where the other strategies give the wrong answer with high probability.
{cmd:mispauto all} does this for you and prints a comparison.


{marker options}{...}
{title:Options}

{pstd}
Options specific to each subcommand are documented on its own page. These are
shared.

{dlgtab:Main}

{phang}
{opt level(#)} sets the {it:overall} nominal significance level of the strategy
as a whole, in percent; default {cmd:level(5)}. Each strategy then allocates
that level across its component tests by its own published rule, and the
realised overall level is printed in the header. This is not
{helpb level:set level}: it governs a multiple-testing allocation, not a
confidence interval.

{phang}
{opt resetvars(string)} chooses the RESET test variables from the four sets
compared by Thursby and Schmidt (1977, section 4):

{p2colset 13 26 28 2}{...}
{p2col :{cmd:pox}}powers of the included regressors; {bf:the default}, and the
set Thursby and Schmidt found best and Thursby (1981) used{p_end}
{p2col :{cmd:poy}}powers of the fitted values; Ramsey's (1969) original{p_end}
{p2col :{cmd:ts}}a truncated Taylor series: squares and cross products of the
regressors{p_end}
{p2col :{cmd:pc}}powers of the principal components of the regressors{p_end}
{p2colreset}{...}

{phang}
{opt resetpowers(numlist)} gives the powers to use; default
{cmd:resetpowers(2 3 4)}. If the implied number of test variables leaves fewer
than 10 residual degrees of freedom the set is reduced automatically, first to
{cmd:2 3} and then to {cmd:2}, and the set actually used is reported.

{phang}
{opt graph} draws the residual correlogram with Bartlett bands, annotated with
the diagnosis. Seasonal lags are highlighted.

{phang}
{opt name(string)} names the graph, so several can be
{helpb graph combine:combined}.

{phang}
{opt notable} suppresses the display. All results are still returned in
{cmd:r()}.


{marker interp}{...}
{title:Interpreting the output}

{pstd}
Every strategy prints the same four-column table.

{p2colset 9 24 26 2}{...}
{p2col :{bf:Statistic}}the test statistic. The distribution is named in the
{bf:df} column and in the line beneath each row.{p_end}
{p2col :{bf:df}}degrees of freedom. Two numbers separated by a comma denote an
F test; a single number a chi-squared test; a dot means a statistic compared
with the normal or with its own exact distribution.{p_end}
{p2col :{bf:p-value}}with the conventional stars, {cmd:*} 10%, {cmd:**} 5%,
{cmd:***} 1%. {bf:The stars mark conventional levels, not the adjusted level
the decision actually uses} -- see the next column.{p_end}
{p2col :{bf:Outcome}}{cmd:reject} or {cmd:accept} {it:at the adjusted level
printed in the header}. This column, not the stars, is what drives the
diagnosis.{p_end}
{p2colreset}{...}

{pstd}
The italic line beneath each row states the null hypothesis that row tests. The
block at the foot gives the diagnosis, what it means in words, and the response
the source paper recommends.

{pstd}
{bf:Why the stars and the outcome column can disagree.} Each strategy runs
several tests and must control the level of the procedure as a whole, so each
component is run at a stricter level than the headline figure. With
{cmd:level(5)} Thursby's rule gives each of his three procedures 1.6952%, so a
p-value of 0.03 earns two stars but does {it:not} trigger a rejection. This is
deliberate and is the whole point of equations (6) and (8) of his paper.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:Sample size.} Every statistic here is asymptotic except the exact
Durbin{c 150}Watson p-value. Thursby's own Monte Carlo evidence covers
T = 30, 60 and 90 and shows the procedure working poorly at T = 30 for moderate
autocorrelation; Godfrey reports no size or power evidence at all for his
sequence. Treat samples below about 50 observations with caution and say so in
print.

{pstd}
{bf:RESET is not robust to autocorrelation, and this matters.} Thursby (1981,
p.117) assumed it was, on the strength of Monte Carlo experiments in which the
regressors were serially independent. Porter and Kashyap (1984) repeated the
experiment with autocorrelated regressors and found that at a nominal 5% level
the Thursby{c 150}Schmidt RESET rejects a {it:correctly specified} model in
41% of samples at T = 200 when the regressor and the error are both AR(0.9),
and in {bf:77%} of samples when both are AR(0.95). This is the single most
important practical fact in this literature. It is why {cmd:godfrey} exists, and
why {cmd:thursby} prints a warning whenever its RESET rejects. Two remedies are
available: {cmd:mispauto godfrey}, which uses an autocorrelation-consistent
covariance matrix, or {cmd:mispauto thursby, resetmod}, which applies Porter
and Kashyap's own repair of estimating the autocorrelation parameter in both
the maintained and the augmented model.

{pstd}
{bf:Evidence from this implementation.} A Monte Carlo shipped with the package
settles which remedy to prefer. The model is {it:correctly specified}
throughout, T = 200, 300 replications, nominal level 5%. The column headed
"Stata" is {cmd:regress, vce(robust)} followed by {cmd:testparm} on the
identical augmented regression, included as an independent reference.

{col 6}{hline 72}
{col 6}{bf:Rejection rate for a CORRECTLY SPECIFIED model (size; want 5%)}
{col 6}{hline 72}
{col 6}design{col 26}plain{col 36}Stata{col 48}robust{col 60}resetmod
{col 6}{hline 72}
{col 6}independent errors{col 26}  3.3%{col 36} 17.3%{col 48} 19.0%{col 60}  2.3%
{col 6}x and u both AR(0.90){col 26} 45.7%{col 36} 62.3%{col 48} 38.7%{col 60}  6.3%
{col 6}x and u both AR(0.95){col 26} 61.7%{col 36} 80.7%{col 48} 43.7%{col 60}  4.7%
{col 6}{hline 72}
{col 6}{bf:Rejection rate when the model IS misspecified (power; want high)}
{col 6}{hline 72}
{col 6}omitted x squared{col 26}100.0%{col 36}     -{col 48}100.0%{col 60}100.0%
{col 6}wrong functional form{col 26} 52.3%{col 36}     -{col 48} 46.7%{col 60} 43.0%
{col 6}omitted AR variable,{col 26} 42.3%{col 36}     -{col 48} 38.0%{col 60}  5.0%
{col 6}{space 2}orthogonal to x
{col 6}{hline 72}

{pstd}
Three things follow. First, the plain test reproduces Porter and Kashyap
closely, which validates the implementation against their published figures.
Second, {bf:Godfrey's autocorrelation-robust Wald statistic does not fix the
size problem} -- it is worse than plain OLS with independent errors and only
partly better with autocorrelated ones. That is a property of the statistic,
not of this code: Stata's own robust Wald on the same regression behaves the
same way, and the difference between the two columns is exactly the
{cmd:n/(n-k)} adjustment Stata applies and Godfrey's asymptotic formula does
not. Third, {bf:only}{space 1}{opt resetmod}{space 1}{bf:holds its nominal size
in every design}, and it keeps full power against genuine functional-form
misspecification.

{pstd}
The last row is the one trade-off and it deserves care. {opt resetmod} has no
power against an omitted variable that is orthogonal to the included
regressors. {bf:But neither should it:} by Thursby and Schmidt's own condition
such a variable is undetectable by RESET, so the 38-42% recorded for the other
two columns is not power but the same autocorrelation sensitivity that produces
their false rejections -- the omitted series is itself AR(0.9) and they are
reacting to that. An omitted variable of that kind is properly found by the
autocorrelation branch of the strategy, which returns {bf:AR(1)} or {bf:NAR},
and that is exactly what Thursby reports for his own models 13 and 14.

{pstd}
{bf:Practical recommendation.} For the misspecification question use
{cmd:mispauto thursby, resetmod}, and read a resulting {bf:MS} as reliable. Use
{cmd:mispauto godfrey} for the error-process question, where its tests of (c)
and (d) are not affected by any of this. Do not set {opt truncate()}
generously: the robust Wald's size distortion grows with the number of lags.

{pstd}
{bf:RESET cannot detect every omitted variable, and this is not a bug.}
Thursby and Schmidt (1977, section 2) show that the expected value of the
coefficient vector on the test variables is {cmd:(Z'MxZ)^-1 Z'Mx xi}, so the
test has power only when {cmd:Z'Mx xi} is non-zero: that is, when the omitted
part of the regression is correlated with the test variables, or, failing that,
when both it and the test variables are correlated with the included
regressors. {bf:An omitted regressor orthogonal to everything in the model is
invisible to RESET} however large its coefficient. Thursby (1981, p.122)
reports exactly this for his model 14, where RESET never detects the omitted
variable; the omitted series instead "looks like" an autocorrelated disturbance
and the strategy returns AR(1). If you suspect a specific variable, test it
directly rather than relying on RESET.

{pstd}
{bf:The power of RESET can fall as the misspecification gets worse.} Thursby
and Schmidt (1977, section 3) show that the mean of the statistic rises with
the severity of the misspecification only if
{cmd:lambda1*(nu2-4) >= lambda2*nu1}, and falls for every severity if
{cmd:lambda1*nu2 <= nu1*lambda2}. They also show the variance tends to zero as
the misspecification grows, so the power tends to either one or zero. The
possibility is remote and recedes as the sample grows, but it is real.

{pstd}
{bf:Seasonal data.} If your data are quarterly or monthly, run
{cmd:mispauto knottnerus} first. A pure seasonal error process has a
first-order autocorrelation of zero, and Knottnerus proved that Thursby's
procedure then returns {bf:NP} no matter how strong the seasonal dependence.
{cmd:mispauto godfrey} handles it provided {opt q()} is at least one less than
the seasonal period, which is the default when the data are {helpb tsset} with
a quarterly or monthly format.

{pstd}
{bf:What these papers do not provide.} There is no finite-sample distribution
for Godfrey's robust Wald statistic; no power evidence of any kind for the
Godfrey (1987) sequence; no joint size result for the Godfrey{c 150}Hutton pair
beyond the asymptotic independence proof; and no guidance on the truncation lag
beyond a remark about seasonality. The command does not invent any of these.
Where a choice had to be made it follows the source paper and documents the
choice in {helpb mispauto_methods:mispauto methods}.

{pstd}
{bf:Gaps in the sample.} Every statistic is built from lagged residuals, so
gaps cost observations, and the exact Durbin{c 150}Watson distribution no
longer applies. The command reports the number of gaps and continues.


{marker examples}{...}
{title:Examples}

{pstd}Set up{p_end}
{phang2}{cmd:. webuse klein, clear}{p_end}
{phang2}{cmd:. tsset yr}{p_end}

{pstd}Run everything and compare{p_end}
{phang2}{cmd:. mispauto all consump wagepriv wagegovt}{p_end}

{pstd}The recommended single strategy, with a plot{p_end}
{phang2}{cmd:. mispauto godfrey consump wagepriv wagegovt, graph}{p_end}

{pstd}The original procedure, for comparison{p_end}
{phang2}{cmd:. mispauto thursby consump wagepriv wagegovt}{p_end}

{pstd}As postestimation after {helpb regress}{p_end}
{phang2}{cmd:. regress consump wagepriv wagegovt}{p_end}
{phang2}{cmd:. mispauto godfrey}{p_end}

{pstd}Quarterly data: let the seasonal defaults work{p_end}
{phang2}{cmd:. tsset qtr, quarterly}{p_end}
{phang2}{cmd:. mispauto knottnerus y x1 x2}{p_end}
{phang2}{cmd:. mispauto godfrey y x1 x2}{p_end}

{pstd}Should I instrument{c 63}{p_end}
{phang2}{cmd:. mispauto ghutton y x1 (x2 = z1 z2)}{p_end}

{pstd}A full self-test on seven known-truth designs ships with the package{p_end}
{phang2}{cmd:. net get mispauto}{p_end}
{phang2}{cmd:. do mispauto_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mispauto} is {cmd:rclass}. Every subcommand returns at least:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:mispauto}{p_end}
{synopt:{cmd:r(subcmd)}}the subcommand run{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indeps)}}independent variables{p_end}
{synopt:{cmd:r(verdict)}}the diagnosis: {cmd:NP}, {cmd:AR(1)}, {cmd:NAR},
{cmd:MS}, {cmd:MS+ARMA}, {cmd:RESPEC}, {cmd:EV/S} or {cmd:OLS}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(level)}}nominal overall level, in percent{p_end}

{pstd}
Each subcommand returns its own statistics, p-values and accept/reject
indicators in addition; they are listed on its own help page.


{marker refs}{...}
{title:References}

{phang}
Godfrey, L. G. 1987. Discriminating between autocorrelation and misspecification
in regression analysis: an alternative test strategy.
{it:The Review of Economics and Statistics} 69(1): 128{c 150}134.
{browse "https://doi.org/10.2307/1937909":doi:10.2307/1937909}.

{phang}
Godfrey, L. G., and J. P. Hutton. 1994. Discriminating between
errors-in-variables/simultaneity and misspecification in linear regression
models. {it:Economics Letters} 44(4): 359{c 150}364.
{browse "https://doi.org/10.1016/0165-1765(94)90103-1":doi:10.1016/0165-1765(94)90103-1}.

{phang}
Knottnerus, P. 1985. A test strategy for discriminating between autocorrelation
and misspecification in regression analysis: a critical note.
{it:The Review of Economics and Statistics} 67(1): 175{c 150}177.
{browse "https://doi.org/10.2307/1928452":doi:10.2307/1928452}.

{phang}
Thursby, J. G. 1981. A test strategy for discriminating between autocorrelation
and misspecification in regression analysis.
{it:The Review of Economics and Statistics} 63(1): 117{c 150}123.
{browse "https://doi.org/10.2307/1924224":doi:10.2307/1924224}.

{phang}
Thursby, J. G. 1985. A test strategy for discriminating between autocorrelation
and misspecification in regression analysis: reply.
{it:The Review of Economics and Statistics} 67(1): 177{c 150}178.
{browse "https://doi.org/10.2307/1928453":doi:10.2307/1928453}.

{pstd}
Supporting results that the package implements rather than merely cites are
listed in {helpb mispauto_methods:mispauto methods}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
