{smcl}
{* *! version 1.0.0  21nov2026}{...}
{*! spxa help file}{...}
{hline}
help for {hi:spxa}{right:(version 1.0.0)}
{hline}

{title:Title}

{pstd}{bf:spxa} {hline 2} Lévy processes as objects: exact Lévy--Khintchine arithmetic,
simulation, and cumulants

{title:Syntax}

{pstd}{cmd:spxa} {cmd:define} {it:name}{cmd:,} {cmd:process(}{it:procname}{cmd:)}
[{cmd:params(}{it:name}{cmd:=}{it:#} [{cmd:,} {it:name}{cmd:=}{it:#} {cmd:...}]{cmd:)}]

{pstd}{cmd:spxa} {cmd:define} {it:name}{cmd:,} {cmd:expr(}{it:expression}{cmd:)}

{pstd}{cmd:spxa} {cmd:simulate} {it:name} [{cmd:,} {opt paths(#)} {opt steps(#)}
{opt t(#)} {opt seed(#)} {opt generate(newvar)} {opt initial(#)} {opt log}
{opt wide} {opt clear}]

{pstd}{cmd:spxa} {cmd:report} {it:name} [{cmd:,} {opt cumulants(#)}
{opt matrix(matname)} {opt story} {opt detail}]

{pstd}{cmd:spxa} {cmd:list}

{pstd}{cmd:spxa} {cmd:drop} {it:name}

{pstd}{cmd:spxa} {cmd:clear}

{title:Description}

{pstd}{cmd:spxa} gives a do-file access to the probability laws of continuous-time
stochastic processes, through the {bf:spxa} Python library.  A process is built
once and then used as an object: processes can be added, scaled, and time-changed,
and the resulting object carries its exact Lévy--Khintchine triplet, its exact
cumulants, and a simulation routine.

{pstd}{cmd:spxa define} builds a process from a named process class and its
parameters, or from an expression over processes that are already defined, and
registers it under {it:name}.  The registry lives in Stata's Python session for
the duration of the session.

{pstd}{cmd:spxa simulate} writes simulated paths of a registered process into the
current dataset, in long layout ({cmd:path}, {cmd:step}, {cmd:t}, and the
simulated variable) or, with {opt wide}, one variable per path.  Because
Stata's time variable must be integer-valued, the time index is written as
{cmd:step} (0, 1, {cmd:...}, {opt steps()}), so that {cmd:xtset path step}
works as it stands; {cmd:t} holds the time itself.

{pstd}{cmd:spxa report} displays the law of a registered process---its exactness
level, its triplet, its cumulants, and the implied skewness and excess
kurtosis---and stores these in {cmd:r()}.

{pstd}{cmd:spxa list}, {cmd:spxa drop}, and {cmd:spxa clear} manage the registry.

{pstd}Stata 16 or newer is required, with the Python integration configured;
the Python interpreter that Stata uses must have the {bf:spxa} package installed
({cmd:pip install spxa}).

{title:Options}

{phang}{opt process(}{it:procname}{opt :)} specifies the process to build.  A
short name ({cmd:vg}, {cmd:nig}, {cmd:cgmy}, {cmd:gamma}, {cmd:merton}, ...) or
the full spxa class name ({cmd:VarianceGamma}, {cmd:CGMY}, ...) may be given;
names are matched without regard to case.

{phang}{opt params(}{it:name}{opt =}{it:#}{opt , ...:)} gives the parameters of
the process, as a comma-separated list of {it:name}{cmd:=}{it:value} pairs using
the names of the spxa constructor, for example
{cmd:params(sigma=0.2, nu=0.1, theta=-0.1)}.  Parameters left out take the
values that the spxa library assigns.

{phang}{opt expr(}{it:expression}{opt :)} builds the process from an expression.
{it:expression} may contain the handles of processes that are already defined,
the operators {cmd:+}, {cmd:-}, {cmd:*}, and {cmd:@}, numbers, and process
constructors written out in full, as in {cmd:expr(vg + 0.5*cgmy(C=1, G=5, M=5, Y=0.5))}.
Here {cmd:+} is the sum of independent processes, {cmd:*} is scalar
multiplication, and {cmd:@} is subordination, {it:X}{cmd:@}{it:T}, that is,
the process {it:X} run on the clock {it:T}.  The clock must be a subordinator,
such as a gamma process.

{phang}{opt paths(#)} sets the number of simulated paths; the default is 1.

{phang}{opt steps(#)} sets the number of steps per path; the default is 252.

{phang}{opt t(#)} sets the terminal time {it:T} of the simulation, so each step
covers {it:T}{cmd:/}{opt steps()} and the variable {cmd:t} runs from 0 to
{it:T}; the default is 1.

{phang}{opt seed(#)} sets the seed of the random number generator.  If it is not
specified, {cmd:c(seed)}---that is, whatever {cmd:set seed} last set---is used, so
{cmd:set seed 12345} before {cmd:spxa simulate} makes the simulation reproducible.

{phang}{opt generate(}{it:newvar}{opt :)} names the simulated variable; the default
is {cmd:generate(x)}.  With {opt wide}, variables {it:newvar}{cmd:1},
{it:newvar}{cmd:2}, {cmd:...} are created instead.

{phang}{opt initial(#)} sets the starting value.  Without {opt log} the simulated
value is {it:initial}{cmd:+}{it:X}{cmd:_t}; with {opt log} it is
{it:initial}{cmd:*exp(}{it:X}{cmd:_t}{cmd:)}.  The default is 0 and 1 respectively.

{phang}{opt log} reports levels rather than log levels: the simulated variable is
{it:initial}{cmd:*exp(}{it:X}{cmd:_t}{cmd:)}, which is what one wants when the
process describes log prices.  {opt initial()} defaults to 1 in this case.

{phang}{opt wide} writes one variable per path instead of one observation per
path-time; {it:newvar}{cmd:1}, {it:newvar}{cmd:2}, {cmd:...} hold the paths and
{cmd:t} becomes the integer time index.  The default is long layout.

{phang}{opt clear} is required when the dataset in memory is not empty, because
{cmd:spxa simulate} replaces it.

{phang}{opt cumulants(#)} sets how many cumulants of {it:X}{cmd:_1} are reported
and stored; the default is 4, the maximum is 20.

{phang}{opt matrix(}{it:matname}{opt :)} stores the cumulants in the Stata matrix
{it:matname}, as a row vector with columns {cmd:k1}, {cmd:k2}, {cmd:...}, the
same shape as the coefficient vector {cmd:e(b)} of an estimation command, so
{it:kappa}{cmd:_}{it:j} is read as {it:matname}{cmd:[1,}{it:j}{cmd:]}.

{phang}{opt story} displays the derivation trace of the process: how it was
composed, which rule was applied at each step, and the primary references.

{phang}{opt detail} adds the process properties (stationary increments,
independent increments, martingale, finiteness of moments, self-similarity,
tail index).

{title:Remarks and examples}

{pstd}Build two processes and add them.  The sum has an exact triplet, so its
law is known in closed form:

{phang}{cmd:. spxa define vg, process(vg) params(sigma=0.2, nu=0.1, theta=-0.1)}
{phang}{cmd:. spxa define jump, process(cgmy) params(C=1, G=5, M=5, Y=0.5)}
{phang}{cmd:. spxa define model, expr(vg + 0.5*jump)}
{phang}{cmd:. spxa report model}

{pstd}The result of {cmd:report} is also in {cmd:r()}:

{phang}{cmd:. di r(exactness)}
{phang}{cmd:. di r(kappa3)}
{phang}{cmd:. di r(skewness), r(exkurtosis)}

{pstd}Simulate paths and analyse them with ordinary Stata time-series tools:

{phang}{cmd:. set seed 12345}
{phang}{cmd:. spxa simulate model, paths(500) steps(52) t(1) generate(dx)}
{phang}{cmd:. xtset path step}
{phang}{cmd:. by path: regress dx L.dx}

{pstd}A time-changed process, that is, a variance-gamma process run on a gamma
clock, which is again a variance-gamma process but with a different
parametrization:

{phang}{cmd:. spxa define clock, process(gamma) params(a=1, b=2)}
{phang}{cmd:. spxa define sub, expr(vg @ clock)}
{phang}{cmd:. spxa report sub, cumulants(4) matrix(K) detail}

{pstd}Prices rather than log prices:

{phang}{cmd:. spxa define gbm, expr(bm(mu=0.05, sigma=0.2) + drift(mu=-0.02))}
{phang}{cmd:. spxa simulate gbm, paths(100) steps(12) t(1) generate(px) initial(100) log clear}

{title:Saved results}

{pstd}{cmd:spxa define} stores in {cmd:r()}:

{phang}{cmd:r(handle)} the handle that was defined
{phang}{cmd:r(structure)} the composition of the process, as text
{phang}{cmd:r(exactness)} {cmd:EXACT}, {cmd:MOMENT_PROPAGATION}, or {cmd:SIMULATION_ONLY}

{pstd}{cmd:spxa simulate} stores in {cmd:r()}:

{phang}{cmd:r(paths)} the number of paths
{phang}{cmd:r(steps)} the number of steps
{phang}{cmd:r(obs)} the number of observations written
{phang}{cmd:r(T)} the terminal time
{phang}{cmd:r(stepvar)} the name of the integer time index ({cmd:step} in long
layout, {cmd:t} with {opt wide})
{phang}{cmd:r(initial)} the starting value
{phang}{cmd:r(seed)} the seed used, or {cmd:-1} if none was supplied
{phang}{cmd:r(generate)} the name of the simulated variable
{phang}{cmd:r(layout)} {cmd:long} or {cmd:wide}
{phang}{cmd:r(handle)} the handle that was simulated

{pstd}{cmd:spxa report} stores in {cmd:r()}:

{phang}{cmd:r(exactness)} the exactness level of the process
{phang}{cmd:r(structure)} the composition of the process, as text
{phang}{cmd:r(handle)} the handle that was reported
{phang}{cmd:r(b)}, {cmd:r(sigma_sq)} the drift and Gaussian variance of the triplet,
missing if the triplet is not known in closed form
{phang}{cmd:r(kappa1)}, {cmd:r(kappa2)}, {cmd:...} the cumulants of {it:X}{cmd:_1},
missing when unavailable
{phang}{cmd:r(skewness)}, {cmd:r(exkurtosis)} the skewness and excess kurtosis
implied by the cumulants, missing when they are not defined

{pstd}{cmd:spxa list} stores {cmd:r(n_defined)}, the number of handles defined.

{title:Methods and formulas}

{pstd}The Lévy--Khintchine triplet of a process is
{it:(b, }{cmd:sigma}{it:^2, nu)}, where {it:b} is the drift, {cmd:sigma}{it:^2} is
the Gaussian variance, and {it:nu} is the Lévy measure.  Triplets of independent
processes add, so a composition has an exact triplet whenever its components do;
{cmd:spxa} computes it analytically rather than by simulation.

{pstd}The cumulants of {it:X}{cmd:_1} follow from the triplet as

{pmore}{cmd:kappa_1 = b + }integral over {it:|x|>1} of {it:x nu(dx)}
{pmore}{cmd:kappa_2 = sigma^2 + }integral of {it:x^2 nu(dx)}
{pmore}{cmd:kappa_n = }integral of {it:x^n nu(dx)} for {it:n >= 3}

{pstd}and the skewness and excess kurtosis reported are
{cmd:kappa_3/kappa_2^1.5} and {cmd:kappa_4/kappa_2^2}.

{title:References}

{phang}Baum, C. F. 2022.  Submitting and retrieving materials from the SSC Archive.
{cmd:http://repec.org/bocode/s/sscsubmit.html}

{phang}Cont, R., and P. Tankov. 2004.  {it:Financial Modelling with Jump
Processes}.  Boca Raton, FL: Chapman and Hall/CRC.

{phang}Sato, K. 1999.  {it:Lévy Processes and Infinitely Divisible Distributions}.
Cambridge: Cambridge University Press.

{title:Also see}

{pstd}Online:  {help python}, {help python set}, {help ssc}, {help findfile}
