{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag postestimation" "help jointdiag_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag im" "help jointdiag_im"}{...}
{vieweralsosee "jointdiag arch" "help jointdiag_arch"}{...}
{vieweralsosee "jointdiag bilinear" "help jointdiag_bilinear"}{...}
{vieweralsosee "jointdiag bc" "help jointdiag_bc"}{...}
{vieweralsosee "jointdiag score" "help jointdiag_score"}{...}
{vieweralsosee "jointdiag port" "help jointdiag_port"}{...}
{vieweralsosee "jointdiag spec" "help jointdiag_spec"}{...}
{vieweralsosee "jointdiag mpi" "help jointdiag_mpi"}{...}
{vieweralsosee "jointdiag nonnest" "help jointdiag_nonnest"}{...}
{vieweralsosee "jointdiag all" "help jointdiag_all"}{...}
{viewerjumpto "Syntax" "jointdiag##syntax"}{...}
{viewerjumpto "Description" "jointdiag##description"}{...}
{viewerjumpto "Why joint tests" "jointdiag##why"}{...}
{viewerjumpto "Map of the package" "jointdiag##map"}{...}
{viewerjumpto "Which subcommand do I need?" "jointdiag##which"}{...}
{viewerjumpto "Options" "jointdiag##options"}{...}
{viewerjumpto "Examples" "jointdiag##examples"}{...}
{viewerjumpto "Stored results" "jointdiag##results"}{...}
{viewerjumpto "References" "jointdiag##refs"}{...}
{viewerjumpto "Author" "jointdiag##author"}{...}

{title:Title}

{phang}
{bf:jointdiag} {hline 2} Joint and simultaneous diagnostic tests for
time-series regression and conditional mean{c 150}variance models


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {it:subcommand} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{p 4 4 2}
With no {it:depvar}, every subcommand reads the model from the estimation
results in memory; see {helpb jointdiag_postestimation:jointdiag postestimation}.

{synoptset 20 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{syntab:Classical regression{c 58} four directions at once}
{synopt:{helpb jointdiag_lm:lm}}normality, heteroskedasticity, serial
independence and functional form, all 15 combinations, plus the
multiple-comparison procedure{p_end}
{synopt:{helpb jointdiag_im:im}}information-matrix test and its decomposition,
with AR(p) errors{p_end}
{synopt:{helpb jointdiag_score:score}}score tests for autocorrelation,
heteroskedasticity and bilinearity in the errors{p_end}
{synopt:{helpb jointdiag_mpi:mpi}}one-sided most-powerful-invariant joint test{p_end}

{syntab:Functional form and the error structure together}
{synopt:{helpb jointdiag_bc:bc}}Box{c 150}Cox functional form jointly with AR
errors, heteroskedasticity and omitted variables{p_end}
{synopt:{helpb jointdiag_nonnest:nonnest}}a non-nested alternative jointly with
a general error specification{p_end}

{syntab:Conditional variance}
{synopt:{helpb jointdiag_arch:arch}}ARCH / AARCH and autocorrelation, each in
the presence of the other, plus the joint stationarity condition{p_end}
{synopt:{helpb jointdiag_bilinear:bilinear}}ARCH versus bilinearity{p_end}

{syntab:Conditional mean AND variance of a fitted time-series model}
{synopt:{helpb jointdiag_port:port}}mixed portmanteau tests{p_end}
{synopt:{helpb jointdiag_spec:spec}}generalised-spectral joint and marginal
tests with a wild bootstrap{p_end}

{syntab:Everything}
{synopt:{helpb jointdiag_all:all}}the full dashboard with a verdict{p_end}
{synoptline}

{p 4 6 2}
You must {helpb tsset} the data before using any subcommand except
{helpb jointdiag_bc:bc}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:jointdiag} implements the family of {it:joint} (also called
{it:simultaneous} or {it:multi-directional}) specification tests for
time-series regression models.  An ordinary diagnostic answers one question:
{it:is there heteroskedasticity?}  A joint diagnostic answers a different and
usually more useful one: {it:which combination of problems does this model
have, and is the evidence for each one real once the others are allowed for?}

{pstd}
Stata ships excellent one-directional tests ({helpb estat hettest},
{helpb estat bgodfrey}, {helpb estat archlm}, {helpb estat ovtest},
{helpb sktest}, {helpb wntestq}).  It does not ship a single joint test.
{cmd:jointdiag} fills that gap, and {it:re-uses} the built-ins wherever they
already compute the right quantity rather than recoding them.


{marker why}{...}
{title:Why joint tests}

{pstd}
Two phrases from {bind:Bera and Jarque (1982)} organise the whole package.

{phang2}
{bf:Undertesting} {hline 2} testing fewer directions than the data actually
depart in.  The consequences are severe.  In their Monte Carlo the LM test for
serial correlation has power 0.996 against pure autocorrelation but only 0.476
once non-normality and a wrong functional form are also present.

{phang2}
{bf:Overtesting} {hline 2} testing more directions than necessary.  The
consequences are mild: applying the four-directional statistic when only one
direction is violated costs about 0.04 of power.

{pstd}
The practical rule follows immediately: {bf:overtesting is cheap, undertesting
is dangerous}.  Four concrete illustrations, each reproducible with this
package:

{phang2}
{bf:1.}  A wrong functional form reads as autocorrelation.  In
{bind:Savin and White's (1978)} artificial example the Durbin{c 150}Watson
statistic is 0.675 and the conditional test {it:C}({&rho}) rejects
independence overwhelmingly {c 150} yet the errors are independent by
construction and the unconditional test {it:G}({&rho}) accepts comfortably.
See {helpb jointdiag_bc:jointdiag bc}.

{phang2}
{bf:2.}  Autocorrelation and ARCH masquerade as each other.  Standard ARCH
tests are invalid under autocorrelation and standard autocorrelation tests are
invalid under ARCH.  See {helpb jointdiag_arch:jointdiag arch}.

{phang2}
{bf:3.}  A marginal test of the conditional variance loses nearly all its
power when the conditional mean is misspecified {c 150} in
{bind:Escanciano's (2008)} tables it falls to 1{c 150}4 percent.  See
{helpb jointdiag_spec:jointdiag spec} and {helpb jointdiag_port:jointdiag port}.

{phang2}
{bf:4.}  The information-matrix test is blind to serial correlation: its power
there equals its size ({bind:Hall 1987}).  Adding AR(p) errors to the null
model restores it and, remarkably, one of the new components {it:is} Engle's
ARCH test ({bind:Bera and Lee 1993}).  See {helpb jointdiag_im:jointdiag im}.


{marker map}{...}
{title:Map of the package}

{pstd}
Every subcommand implements named published tests.  The complete
step{c 174}equation map lives in {helpb jointdiag_methods:help jointdiag methods}.

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb jointdiag_lm:lm}}Jarque{c 150}Bera (1980); Bera{c 150}Jarque (1982);
Higgins{c 150}Bera (1988); Koenker (1981){p_end}
{synopt:{helpb jointdiag_im:im}}White (1982); Chesher (1983, 1984); Hall (1987);
Bera{c 150}Lee (1993){p_end}
{synopt:{helpb jointdiag_arch:arch}}Bera{c 150}Higgins{c 150}Lee (1992);
Engle (1982); Wooldridge (1990){p_end}
{synopt:{helpb jointdiag_bilinear:bilinear}}Higgins{c 150}Bera (1988);
Bera{c 150}Higgins (1997){p_end}
{synopt:{helpb jointdiag_bc:bc}}Savin{c 150}White (1978); Lahiri{c 150}Egy (1981);
Tse (1984); Ghali{c 150}Snow (1987); Yang{c 150}Tse (2008){p_end}
{synopt:{helpb jointdiag_score:score}}Tsai (1986); Liu{c 150}Wei{c 150}Wang (2003){p_end}
{synopt:{helpb jointdiag_port:port}}Li{c 150}Mak (1994); Ling{c 150}Li (1997);
Wong{c 150}Ling (2005); Velasco{c 150}Wang (2015); Mahdi (2024){p_end}
{synopt:{helpb jointdiag_spec:spec}}Escanciano (2008){p_end}
{synopt:{helpb jointdiag_mpi:mpi}}King{c 150}Evans (1984); Imhof (1961){p_end}
{synopt:{helpb jointdiag_nonnest:nonnest}}Bera{c 150}McAleer{c 150}Pesaran (1989);
Godfrey{c 150}Wickens (1982){p_end}
{synoptline}


{marker which}{...}
{title:Which subcommand do I need?}

{pstd}
{bf:Start here.}  Run {helpb jointdiag_all:jointdiag all} on your model; it
prints every diagnostic plus a plain-language verdict that tells you which page
to open next.  Then:

{phang2}
{it:"I fitted} {helpb regress} {it:and want to know what is wrong."}{break}
{helpb jointdiag_lm:jointdiag lm}, then add {cmd:mcp} to see which single
directions survive a controlled overall level.

{phang2}
{it:"The DW statistic is low."}{break}
Do {bf:not} reach for {helpb prais} yet.  Run
{helpb jointdiag_bc:jointdiag bc {it:y} {it:x}, rho} first: if
{it:G}({&rho}) accepts while {it:C}({&rho}) rejects, your problem is the
functional form, not the errors.

{phang2}
{it:"} {helpb estat archlm} {it:rejects."}{break}
{helpb jointdiag_arch:jointdiag arch}.  If the ARCH signal disappears once
AR({it:p}) is allowed, it was autocorrelation all along.

{phang2}
{it:"I fitted an} {helpb arch} {it:model; is it adequate?"}{break}
{helpb jointdiag_port:jointdiag port} for the fast portmanteau battery, then
{helpb jointdiag_spec:jointdiag spec} for the omnibus bootstrap test.

{phang2}
{it:"I have two competing non-nested models."}{break}
{helpb jointdiag_nonnest:jointdiag nonnest}, which tests the rival model and
the error assumptions in one step and so removes the pre-testing problem.

{phang2}
{it:"My alternative is one-sided (I expect positive autocorrelation)."}{break}
{helpb jointdiag_mpi:jointdiag mpi}.  King and Evans (1984) show the two-sided
LM test throws away about a third of the available power.


{marker options}{...}
{title:Options common to most subcommands}

{synoptset 24 tabbed}{...}
{synopthdr:option}
{synoptline}
{synopt:{opt l:ags(#)}}order of the serial-correlation alternative{p_end}
{synopt:{opt het(varlist)}}the {it:z} variables of the variance function{p_end}
{synopt:{opt l:evel(#)}}confidence level for critical values and graphs{p_end}
{synopt:{opt gr:aph}}draw the diagnostic figure{p_end}
{synopt:{opt name(string)}}name for the graph{p_end}
{synopt:{opt notab:le}}suppress the table, keep the {cmd:r()} results{p_end}
{synoptline}

{pstd}
Each subcommand has further options of its own; follow its link above.


{marker examples}{...}
{title:Examples}

{pstd}Set up a model{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}The whole dashboard with a verdict{p_end}
{phang2}{cmd:. jointdiag all}{p_end}

{pstd}The four-directional LM test and the multiple-comparison procedure{p_end}
{phang2}{cmd:. jointdiag lm, lags(2) mcp}{p_end}

{pstd}Is the ARCH evidence real once autocorrelation is allowed?{p_end}
{phang2}{cmd:. jointdiag arch, ar(1) archlags(1)}{p_end}

{pstd}Is the "autocorrelation" really a wrong functional form?{p_end}
{phang2}{cmd:. jointdiag bc inv inc, rho graph}{p_end}

{pstd}After a GARCH fit, check both conditional moments{p_end}
{phang2}{cmd:. arch dln_inv dln_inc, ar(1) arch(1) garch(1)}{p_end}
{phang2}{cmd:. jointdiag port, lags(12) graph}{p_end}
{phang2}{cmd:. jointdiag spec, reps(299)}{p_end}

{pstd}
A complete, self-contained demonstration that exercises every code path and
checks each result against the papers is shipped with the package:{p_end}
{phang2}{cmd:. net get jointdiag}{p_end}
{phang2}{cmd:. do jointdiag_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
Every subcommand is {cmd:rclass} and returns its statistics, degrees of freedom
and p-values in {cmd:r()}, so results can be tabled or looped over.  The names
are documented on each subcommand's page.  All subcommands also return:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:jointdiag} {it:subcommand}{p_end}


{marker refs}{...}
{title:References}

{phang}
Bera, A. K., and C. M. Jarque. 1982. Model specification tests: A simultaneous
approach. {it:Journal of Econometrics} 20: 59{c 150}82.
{browse "https://doi.org/10.1016/0304-4076(82)90103-8"}.

{phang}
Bera, A. K., M. L. Higgins, and S. Lee. 1992. Interaction between
autocorrelation and conditional heteroscedasticity: A random-coefficient
approach. {it:Journal of Business & Economic Statistics} 10: 133{c 150}142.
{browse "https://doi.org/10.1080/07350015.1992.10509893"}.

{phang}
Bera, A. K., and S. Lee. 1993. Information matrix test, parameter heterogeneity
and ARCH: A synthesis. {it:Review of Economic Studies} 60: 229{c 150}240.
{browse "https://doi.org/10.2307/2297820"}.

{phang}
Escanciano, J. C. 2008. Joint and marginal specification tests for conditional
mean and variance models. {it:Journal of Econometrics} 143: 74{c 150}87.
{browse "https://doi.org/10.1016/j.jeconom.2007.08.010"}.

{phang}
Hall, A. 1987. The information matrix test for the linear model.
{it:Review of Economic Studies} 54: 257{c 150}263.
{browse "https://doi.org/10.2307/2297515"}.

{phang}
Savin, N. E., and K. J. White. 1978. Estimation and testing for functional form
and autocorrelation: A simultaneous approach. {it:Journal of Econometrics}
8: 1{c 150}12. {browse "https://doi.org/10.1016/0304-4076(78)90085-4"}.

{phang}
Wong, H., and S. Ling. 2005. Mixed portmanteau tests for time-series models.
{it:Journal of Time Series Analysis} 26: 569{c 150}579.
{browse "https://doi.org/10.1111/j.1467-9892.2005.00420.x"}.

{pstd}
The full bibliography, with every DOI verified, is in
{helpb jointdiag_methods:help jointdiag methods}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Comments and bug reports are welcome.
