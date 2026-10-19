{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvtfourier" "help tvtfourier"}{...}
{vieweralsosee "tvthomog" "help tvthomog"}{...}
{viewerjumpto "Syntax" "tvtsim##syntax"}{...}
{viewerjumpto "Description" "tvtsim##description"}{...}
{viewerjumpto "The designs" "tvtsim##designs"}{...}
{viewerjumpto "Options" "tvtsim##options"}{...}
{viewerjumpto "What it creates" "tvtsim##vars"}{...}
{viewerjumpto "Examples" "tvtsim##examples"}{...}
{viewerjumpto "Stored results" "tvtsim##results"}{...}
{viewerjumpto "Author" "tvtsim##author"}{...}
{title:Title}

{phang}
{bf:tvtsim} {hline 2} Simulate a threshold model with a time-varying
threshold


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtsim} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt mod:el(name)}}the threshold path; default
{cmd:model(fourier)}{p_end}
{synopt :{opt n(#)}}number of observations; default {cmd:n(200)}{p_end}
{synopt :{opt g0(#)} {opt g1(#)} {opt g2(#)} {opt k(#)}}Fourier parameters;
defaults 0.5, 1, 1, 1{p_end}
{synopt :{opt b1(# #)}}lower-regime intercept and slope; default
{cmd:b1(10 10)}{p_end}
{synopt :{opt b2(# #)}}upper-regime intercept and slope; default
{cmd:b2(10 20)}{p_end}
{synopt :{opt s:igma(#)}}disturbance standard deviation; default
{cmd:sigma(1)}{p_end}
{synopt :{opt xsd(#)}}standard deviation of the regressor; default
{cmd:xsd(2)}{p_end}
{synopt :{opt seed(#)}}random-number seed{p_end}
{synopt :{opt clear}}replace the data in memory{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtsim} generates data from a two-regime threshold model

{p 8 8 2}
{it:y_t} = {it:b11} + {it:b12 x_t} + {it:e_t}{space 4}if {it:q_t} {ul:<}
{it:gamma_t}{break}
{it:y_t} = {it:b21} + {it:b22 x_t} + {it:e_t}{space 4}if {it:q_t} >
{it:gamma_t}

{pstd}
in which the threshold {it:gamma_t} follows one of several published paths,
and leaves the {bf:true} path in the data as a variable so that any estimate
can be compared with it directly.

{pstd}
{bf:Why this ships as a command rather than living in the test files.} Every
validation study in this library needs data from a known threshold path, and
every source paper states its designs in its own notation. Writing those out
by hand once per study is how a simulation ends up testing a different
process from the one it claims to test. Here each published design is
written once, named for the paper that defines it, and the certification
suites and the user get the same generator.

{pstd}
The designs are those of Yang, Lee and Chen (2021), equations (16) to (23),
which are also the designs used by the Monte Carlo evidence quoted in
{helpb tvtfourier} and {helpb tvthresh_choose}.


{marker designs}{...}
{title:The designs}

{pstd}
{opt model()} takes one of:

{phang}
{bf:fourier} {hline 2} {it:gamma_t} = {it:g0} + {it:g1} sin(2{it:pi k t/n}) +
{it:g2} cos(2{it:pi k t/n}). A smooth cyclical path, the paper's Case 1(a).
This is the design {helpb tvtfourier} is built for and the one it recovers
best.

{phang}
{bf:constant} {hline 2} {it:gamma_t} = 0. The paper's Case 1(b). There is
still a threshold {it:effect}, but the threshold does not move, so this is
the {bf:null} for a test of threshold constancy.

{phang}
{bf:shift3} {hline 2} 1, then 0.8 over the middle third of the sample, then
1 again. The paper's Case 2(a): two abrupt shifts.

{phang}
{bf:shift1} {hline 2} 0.8, then 1 after 80% of the sample. The paper's Case
2(b): a single abrupt shift.

{phang}
{bf:logistic} {hline 2} a smooth logistic path between about 0.5 and 1.5,
the paper's Case 2(c).

{phang}
{bf:twodip} {hline 2} the paper's Case 2(d): a path near 1.5 with two smooth
dips, one at 0.2{it:n} reaching about 0.5 and a deeper one at 0.75{it:n}
reaching about 0.

{phang}
{bf:none} {hline 2} no threshold at all; {it:y} is linear in {it:x}. The
{bf:null} for a test of whether a threshold effect exists. {it:gamma} is
left missing, because there is no threshold to report.

{pstd}
{bf:A note on} {bf:twodip}. The equation defining it is printed with
unbalanced brackets in the source paper, and its figure caption repeats the
same error, so two readings are possible. They differ in whether the two
dips are equal. The paper's own figure shows them {bf:unequal} {hline 2}
about 0.5 at the first and about 0 at the second {hline 2} which settles it,
and that is the reading implemented. The matter is documented in
{bf:validation/tvthresh/tvtfourier_equation_map.md}.

{pstd}
{bf:The abrupt designs are the hard cases on purpose.} A Fourier
approximation fits a smooth path well and a step badly, so {bf:shift1} and
{bf:shift3} are the designs on which {helpb tvtfourier} should be expected
to do least well. They are included precisely so that claim can be checked
rather than asserted.


{marker options}{...}
{title:Options}

{phang}
{opt model(name)} selects the threshold path, as above.

{phang}
{opt n(#)} is the number of observations. The time index runs 1 to {it:n}
and the data are {helpb tsset} on it, so the result can be passed straight
to a time-series command.

{phang}
{opt g0(#)}, {opt g1(#)}, {opt g2(#)} and {opt k(#)} set the Fourier
parameters and are used only by {cmd:model(fourier)}. The defaults are the
paper's: 0.5, 1, 1 and frequency 1.

{phang}
{opt b1(# #)} and {opt b2(# #)} give the intercept and slope in the lower
and upper regimes. The defaults, 10 and 10 against 10 and 20, are the
paper's estimation experiment. Its {it:testing} experiment instead uses
{cmd:b1(1 1)} with {cmd:b2(1 1)} for the null and {cmd:b2(1 1.5)} or
{cmd:b2(1 2)} for the alternative.

{phang}
{opt sigma(#)} and {opt xsd(#)} set the disturbance and regressor standard
deviations. The defaults match the paper: {it:x} is N(0, 2{c 94}2) while
{it:q} and {it:e} are standard normal.

{phang}
{opt seed(#)} sets the random-number seed. {bf:Set it in any loop}: without
it a Monte Carlo study repeats whatever stream it happens to inherit.

{phang}
{opt clear} is required if there are data in memory.


{marker vars}{...}
{title:What it creates}

{synoptset 12 tabbed}{...}
{synopt :{cmd:t}}the time index, 1 to {it:n}; the data are {cmd:tsset} on
it{p_end}
{synopt :{cmd:y}}the dependent variable{p_end}
{synopt :{cmd:x}}the regressor{p_end}
{synopt :{cmd:q}}the threshold variable{p_end}
{synopt :{cmd:gamma}}{bf:the true threshold path}, missing under
{cmd:model(none)}{p_end}
{synopt :{cmd:lower}}1 if the observation is in the lower regime{p_end}
{synopt :{cmd:e}}the disturbance{p_end}

{pstd}
{cmd:gamma} and {cmd:lower} are what make this useful: an estimated path can
be plotted against the truth, and an estimated regime assignment compared
with the real one, without any bookkeeping.


{marker examples}{...}
{title:Examples}

{pstd}The default design, then recover it.{p_end}
{phang2}{cmd:. tvtsim, model(fourier) n(200) seed(71010) clear}{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}

{pstd}Compare the fitted path with the truth.{p_end}
{phang2}{cmd:. matrix p = e(path)}{p_end}
{phang2}{cmd:. svmat double p, name(ghat)}{p_end}
{phang2}{cmd:. twoway (line gamma t) (line ghat1 t, lpattern(dash))}{p_end}

{pstd}A constant threshold {hline 2} the null for a constancy test.{p_end}
{phang2}{cmd:. tvtsim, model(constant) n(200) seed(4242) clear}{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}

{pstd}No threshold at all {hline 2} the null for a threshold-effect
test.{p_end}
{phang2}{cmd:. tvtsim, model(none) n(200) seed(4243) clear}{p_end}

{pstd}The paper's testing experiment, with a weak threshold effect.{p_end}
{phang2}{cmd:. tvtsim, model(fourier) n(100) b1(1 1) b2(1 1.5) seed(99) clear}{p_end}

{pstd}An abrupt shift {hline 2} the design a Fourier approximation handles
worst.{p_end}
{phang2}{cmd:. tvtsim, model(shift1) n(500) seed(7) clear}{p_end}
{phang2}{cmd:. tvtfourier y x, threshvar(q)}{p_end}

{pstd}A size study. Note the seed varying with the replication.{p_end}
{phang2}{cmd:. forvalues i = 1/100 {c -(}}{p_end}
{phang2}{cmd:.     quietly tvtsim, model(constant) n(100) b1(1 1) b2(1 1.5) seed(`=90000+`i'') clear}{p_end}
{phang2}{cmd:.     quietly tvtfourier y x, threshvar(q) reps(99)}{p_end}
{phang2}{cmd:.     ... accumulate e(p2) ...}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtsim} is {bf:r-class} and stores the parameters it used, so a study
can record the design it ran rather than the design it meant to run.

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations{p_end}
{synopt:{cmd:r(N_lower)}}observations in the lower regime{p_end}
{synopt:{cmd:r(g0)}, {cmd:r(g1)}, {cmd:r(g2)}, {cmd:r(k)}}the Fourier
parameters used{p_end}
{synopt:{cmd:r(b11)}, {cmd:r(b12)}}lower-regime intercept and slope{p_end}
{synopt:{cmd:r(b21)}, {cmd:r(b22)}}upper-regime intercept and slope{p_end}
{synopt:{cmd:r(sigma)}}disturbance standard deviation{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(model)}}the design generated{p_end}


{title:Reference}

{phang}
Yang, L., C. Lee, and I.-P. Chen. 2021. Threshold model with a time-varying
threshold based on Fourier approximation. {it:Journal of Time Series
Analysis} 42(4): 406-430.
{browse "https://doi.org/10.1111/jtsa.12574":doi:10.1111/jtsa.12574}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvtfourier}, {helpb tvthomog}
{p_end}
