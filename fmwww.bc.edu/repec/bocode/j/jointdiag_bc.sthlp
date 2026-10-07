{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag nonnest" "help jointdiag_nonnest"}{...}
{vieweralsosee "boxcox" "help boxcox"}{...}
{viewerjumpto "Syntax" "jointdiag_bc##syntax"}{...}
{viewerjumpto "Description" "jointdiag_bc##description"}{...}
{viewerjumpto "Options" "jointdiag_bc##options"}{...}
{viewerjumpto "C versus G: the central idea" "jointdiag_bc##cg"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_bc##interpret"}{...}
{viewerjumpto "Examples" "jointdiag_bc##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_bc##results"}{...}

{title:Title}

{phang}
{bf:jointdiag bc} {hline 2} Box{c 150}Cox functional form tested jointly with
autocorrelation, heteroskedasticity and omitted variables


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:bc} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {it:options}]

{p 4 4 2}{it:depvar} must be strictly positive.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Directions to test}
{synopt:{opt lambda0(#)}}the null value of {&lambda}; default {cmd:lambda0(1)}
(linear).  Use {cmd:lambda0(0)} for log-linear{p_end}
{synopt:{opt rho}}also free the AR(1) parameter{p_end}
{synopt:{opt delta}}also free the heteroskedasticity parameter (needs
{cmd:het()}){p_end}
{synopt:{opt omit:ted}}also test for omitted variables{p_end}
{synopt:{opt het(varname)}}the {it:z} of Var({it:u}) = {it:sigma}{c 94}2
{it:z}{c 94}{&delta}; must be positive{p_end}
{synopt:{opt reset(#)}}highest power of the Thursby{c 150}Schmidt variables;
default {cmd:reset(4)}{p_end}

{syntab:Estimation}
{synopt:{opt grid(#)}}grid points for {&lambda}; default {cmd:grid(25)}{p_end}
{synopt:{opt lr:ange(a b)}}search range for {&lambda}; default {cmd:-2 3}{p_end}

{syntab:LM alternative}
{synopt:{opt lm}}also report the Tse (1984) score versions{p_end}
{synopt:{opt stud:entize}}studentised LM (Yang{c 150}Tse 2008){p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt gr:aph}}likelihood profile over {&lambda}{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
Four papers in this literature estimate and test the functional form and the
error structure {it:together}, and {cmd:jointdiag bc} implements the most
general of them with the others as restrictions.  The model is

{p 8 8 2}
{it:y_t}{c 94}({&lambda}) = {it:x_t'b} + {it:x*_t'b*} + {it:u_t},{space 2}
{it:u_t} = {&rho}{it:u_{t-1}} + {it:e_t},{space 2}
Var({it:u_t}) = {it:sigma}{c 94}2 {it:z_t}{c 94}{&delta}

{pstd}
{&delta} = 0 gives the Box{c 150}Cox autoregressive model of Savin and White
(1978); {&rho} = 0 gives the Box{c 150}Cox heteroskedastic model of Lahiri and
Egy (1981); the full thing is Ghali and Snow (1987).

{pstd}
{bf:Stata's} {helpb boxcox} {bf:cannot do this}: it has no AR and no
heteroskedasticity option.  It is still useful as a cross-check on the
{&rho} = {&delta} = 0 case, where its {cmd:e(chi2_t1)} equals this command's
{it:C}({&lambda}).


{marker cg}{...}
{title:C versus G: the central idea}

{pstd}
Two families of likelihood-ratio test are reported for each direction.

{p 4 7 2}
{bf:C}(.) {c 150} the {bf:conditional} test.  The other parameters are
{it:fixed at their null values} on both sides.  This is what you are implicitly
doing when you run {helpb estat dwatson} on an OLS fit: testing {&rho} while
assuming {&lambda} = 1.

{p 4 7 2}
{bf:G}(.) {c 150} the {bf:unconditional} test.  The other parameters are
{it:free} under both hypotheses.

{pstd}
{bf:When C rejects and G does not, the rejection belongs to the other
direction.}  Savin and White's artificial example makes this unmissable.  They
generate {it:ln(Y)} = 0.1 + 0.1{it:X} + {it:u} with independent errors and fit
the linear model.  The Durbin{c 150}Watson statistic is 0.675, which any
textbook reads as strong autocorrelation, and {it:C}({&rho}) = 53.59 rejects
independence overwhelmingly.  But {it:G}({&rho}) = 0.97 accepts it comfortably.
There is no autocorrelation; there is a wrong functional form.  The example
do-file reproduces this.

{pstd}
The command prints a warning whenever a conditional statistic exceeds its
unconditional counterpart.


{marker options}{...}
{title:Options}

{phang}
{opt lambda0(#)} is the functional form under the null: 1 for linear, 0 for
log-linear, 0.5 for square-root.  Ghali and Snow note that in economics only
{&lambda} = 0 and {&lambda} = 1 usually carry an interpretation, except in
production functions where {&lambda} is the elasticity of substitution
(Zarembka 1974).

{phang}
{opt rho}, {opt delta} and {opt omitted} switch directions on.  Each adds one
row to the table and one degree of freedom (or {it:3k} for {cmd:omitted}) to
the joint statistic.  Leaving them all off tests {&lambda} alone.

{phang}
{opt het(varname)} names {it:z}.  Lahiri and Egy take it to be a regressor or
the expected value of the dependent variable; with {&delta} = 2 and
{it:z} = {it:x} you get the Rutemiller{c 150}Bowers model.

{phang}
{opt omitted} adds the squares, cubes and fourth powers of each regressor,
following Thursby and Schmidt (1977), whom Ghali and Snow follow because that
set "is more powerful than a variety of alternative tests ... and is robust to
autocorrelated disturbances" (Thursby 1979).

{phang}
{opt lm} adds the score versions of Tse (1984), which need only the restricted
fit and so are much cheaper than the LR tests.  {opt studentize} makes them
robust to excess skewness and kurtosis (Yang and Tse 2008, Cor. 3.2).

{phang}
{opt graph} plots the concentrated log likelihood against {&lambda}, with the
other parameters re-optimised at each point, the MLE marked, the null value
marked, and the {cmd:level()} likelihood-ratio cut-off drawn.  It is usually
the fastest way to see whether {&lambda} is well identified.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:The estimates block.}  Read {&lambda} first.  Values near 1 say the linear
form is adequate, near 0 the log-linear.  A {&lambda} far outside [-1, 2]
usually means the data are telling you something other than a power
transformation.

{pstd}
{bf:The LR block.}  Compare each {it:C} with its {it:G}.  A large gap in either
direction is informative:

{p 8 8 2}
{it:C} >> {it:G}{space 3}{c 174}{space 3}this direction is being blamed for a
problem that belongs elsewhere{break}
{it:G} >> {it:C}{space 3}{c 174}{space 3}the restriction on the {it:other}
parameters was masking this one

{pstd}
Savin and White's Longley example shows the second pattern, their money-demand
example the first.

{pstd}
{bf:The joint row.}  Ghali and Snow's eq. (32).  Rejecting it says at least one
of the directions fails; the individual {it:G} rows localise it.


{marker examples}{...}
{title:Examples}

{pstd}The Savin{c 150}White trap: is it autocorrelation or functional form?{p_end}
{phang2}{cmd:. jointdiag bc Y X, rho graph}{p_end}

{pstd}Lahiri{c 150}Egy: functional form and heteroskedasticity together{p_end}
{phang2}{cmd:. jointdiag bc sales income, het(income) delta}{p_end}

{pstd}Ghali{c 150}Snow: all four directions at once{p_end}
{phang2}{cmd:. jointdiag bc y x1 x2, rho delta omitted het(x1)}{p_end}

{pstd}Test the log-linear form rather than the linear one{p_end}
{phang2}{cmd:. jointdiag bc M A R, lambda0(0) rho}{p_end}

{pstd}The cheap score versions{p_end}
{phang2}{cmd:. jointdiag bc Y X, rho lm studentize}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(lambda)}, {cmd:r(rho)}, {cmd:r(delta)}}unrestricted MLEs{p_end}
{synopt:{cmd:r(ll)}, {cmd:r(ll_0)}}unrestricted and fully restricted log
likelihoods{p_end}
{synopt:{cmd:r(C_lambda)}, {cmd:r(p_C_lambda)}}conditional test of {&lambda}{p_end}
{synopt:{cmd:r(G_lambda)}, {cmd:r(p_G_lambda)}}unconditional test of {&lambda}{p_end}
{synopt:{cmd:r(C_rho)}, {cmd:r(G_rho)}, ...}the same for {&rho}, {&delta},
{&beta}*{p_end}
{synopt:{cmd:r(J)}, {cmd:r(df_J)}, {cmd:r(p_J)}}the joint test{p_end}
{synopt:{cmd:r(lm_lambda)}, {cmd:r(lm_joint)}}score versions, with {cmd:lm}{p_end}
{synopt:{cmd:r(N)}}observations{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(profile)}}the {&lambda} profile used for the graph{p_end}


{title:References}

{phang}Savin, N. E., and K. J. White. 1978. {it:J. Econometrics} 8: 1{c 150}12.
{browse "https://doi.org/10.1016/0304-4076(78)90085-4"}{p_end}
{phang}Lahiri, K., and D. Egy. 1981. {it:J. Econometrics} 15: 299{c 150}307.
{browse "https://doi.org/10.1016/0304-4076(81)90119-6"}{p_end}
{phang}Tse, Y. K. 1984. {it:Economics Letters} 14: 333{c 150}337.
{browse "https://doi.org/10.1016/0165-1765(84)90007-7"}{p_end}
{phang}Ghali, M. A., and M. S. Snow. 1987. {it:Economic Modelling} 4: 65{c 150}76.
{browse "https://doi.org/10.1016/0264-9993(87)90004-6"}{p_end}
{phang}Yang, Z., and Y. K. Tse. 2008. {it:Econometrics Journal} 11: 349{c 150}376.
{browse "https://doi.org/10.1111/j.1368-423x.2008.00242.x"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
