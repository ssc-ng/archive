{smcl}
{* *! version 1.0.0  14oct2026}{...}
{vieweralsosee "xtpqgmm" "help xtpqgmm"}{...}
{vieweralsosee "xtpqgmm_methods" "help xtpqgmm_methods"}{...}
{vieweralsosee "xtpqgmmplot" "help xtpqgmmplot"}{...}
{viewerjumpto "Postestimation commands" "xtpqgmm_postestimation##commands"}{...}
{viewerjumpto "predict" "xtpqgmm_postestimation##predict"}{...}
{viewerjumpto "estat overid" "xtpqgmm_postestimation##overid"}{...}
{viewerjumpto "estat diagnostics" "xtpqgmm_postestimation##diag"}{...}
{viewerjumpto "estat alpha" "xtpqgmm_postestimation##alpha"}{...}
{viewerjumpto "What is deliberately absent" "xtpqgmm_postestimation##absent"}{...}
{viewerjumpto "Examples" "xtpqgmm_postestimation##examples"}{...}

{p2colset 1 30 32 2}{...}
{p2col:{bf:xtpqgmm postestimation} {hline 2}}Postestimation tools for
{helpb xtpqgmm}{p_end}
{p2colreset}{...}


{marker commands}{...}
{title:Postestimation commands}

{pstd}
The following are available after {helpb xtpqgmm}:

{synoptset 24 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb xtpqgmm_postestimation##predict:predict}}fitted quantiles,
fixed effects, residuals{p_end}
{synopt:{helpb xtpqgmmplot:xtpqgmmplot}}the coefficient path over {it:tau}{p_end}
{synopt:{helpb xtpqgmm_postestimation##overid:estat overid}}Hansen's J{p_end}
{synopt:{helpb xtpqgmm_postestimation##diag:estat diagnostics}}everything the
fit knows about itself{p_end}
{synopt:{helpb xtpqgmm_postestimation##alpha:estat alpha}}the profiled-out
fixed effects{p_end}
{synopt:{helpb estat vce}}the covariance matrix{p_end}
{synopt:{helpb test}, {helpb testnl}, {helpb lincom}, {helpb nlcom}}Wald tests
and linear or nonlinear combinations{p_end}
{synopt:{helpb estimates}}store, restore, tabulate{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{helpb test} and friends are valid {it:within} a quantile. With several
quantiles {cmd:e(V)} is block diagonal with exactly zero off-diagonal blocks,
because the paper supplies no cross-quantile covariance, so a test
{it:across} quantiles will run and report a number that is {bf:not} valid.
See {help xtpqgmm_methods##uniform:[methods] Uniform inference}.


{marker predict}{...}
{title:predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin}
[{cmd:,} {it:statistic} {opt q:uantile(#)} | {opt eq:uation(name)}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xba}}{it:alpha}-hat_i + {it:x}'{it:beta}-hat, the fitted
conditional quantile; the default{p_end}
{synopt:{opt xb}}{it:x}'{it:beta}-hat, with no fixed effect{p_end}
{synopt:{opt al:pha}}{it:alpha}-hat_i, the unit's own profiled effect{p_end}
{synopt:{opt r:esiduals}}{it:y} {c -} {it:alpha}-hat_i {c -}
{it:x}'{it:beta}-hat{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{opt quantile(#)} or {opt equation(name)} picks the quantile when the fit
holds more than one. Either form works: {cmd:quantile(50)} and
{cmd:equation(q50)} are the same request. With a single-quantile fit both are
ignored.

{pstd}
All four statistics are filled in on {cmd:e(sample)} and left missing
elsewhere. Time-series operators in the model are rebuilt, so
{cmd:predict} works after a dynamic specification such as
{cmd:xtpqgmm yd (L.yd = L2.yd L3.yd), quantile(50)}.

{pstd}
{bf:On residuals.} The share of the estimation sample at or below the fitted
quantile will be near {it:tau} but need not equal it. Equation (8) imposes the
quantile restriction {it:within each unit} through the smoothed indicator, not
as an unconditional proportion over the pooled sample, and the smoothing
itself shifts the count by {it:O}({it:h}^4). {cmd:predict, residuals} prints
the realised share so the discrepancy is visible rather than assumed away.

{pstd}
{bf:The fitted quantiles are not forced to be monotone in {it:tau}.} Each
quantile is estimated on its own, so three {cmd:predict} calls at
{it:tau} = 0.25, 0.50, 0.75 can cross for some observations. Neither the paper
nor this command rearranges them.


{marker overid}{...}
{title:estat overid}

{p 8 16 2}
{cmd:estat overid}

{pstd}
Reports Hansen's J for the over-identifying restrictions, one row per fitted
quantile:

{pin}
{it:J} = {it:nT} {it:m}-hat' {it:Omega}-hat^{c -}1 {it:m}-hat
{space 4}~{space 4}chi2({it:dz} {c -} {it:d})

{pstd}
where {it:m}-hat is the profiled sample moment at the reported estimate and
{it:Omega}-hat its Bartlett long-run variance -- both of them Section 5
objects the fit already computed, so nothing is refitted.

{pstd}
{bf:The paper does not state this test.} It is the standard GMM statistic
assembled from the paper's own quantities, and this command says so in its own
footer rather than leaving the user to assume it was blessed in print. Three
caveats come with it:

{phang2}
o With exact identification ({it:dz} = {it:d}) there is nothing to test, the
moment conditions hold at the estimate by construction, and the command says
so instead of printing a zero.

{phang2}
o After {opt mm} or {opt onestep} the reported {it:beta}-hat does not minimise
the quadratic form the statistic evaluates, so J is computed at a
non-minimising point and is conservative.

{phang2}
o On short panels the {it:O}({it:h}^4) smoothing bias is not removed before
the statistic is formed, so J can reject for bandwidth reasons rather than
instrument reasons. Re-run with a smaller {opt bandwidth()} before believing a
rejection when {it:T} is small.

{pstd}
Stored in {cmd:r()}: {cmd:r(jtable)} (the full table), {cmd:r(df)}, and with a
single quantile {cmd:r(J)} and {cmd:r(p)}. The same table is in
{cmd:e(jtable)} straight after estimation.


{marker diag}{...}
{title:estat diagnostics}

{p 8 16 2}
{cmd:estat diagnostics}

{pstd}
Prints, in one place, every number the fit knows about its own quality: the
bandwidth and the HAC lag together with the verdict on
{it:L}^2 log({it:nT})/({it:T h}^2); the panel shape and {it:n}/{it:T}-bar; the
optimiser's iteration count, convergence flag, ||{it:D}'{it:Wm}||, ||{it:m}||
and criterion value; and the profiling counts -- how many unit-evaluations
found no root for equation (8), how many units had multiple roots, and the
largest |{it:A}_i| at the solution.

{pstd}
It then reads those numbers back in plain words, and complains when they
deserve it. In particular a max |{it:A}_i| above 1e{c -}6 means the profile
restriction is {bf:not} satisfied at the reported estimate, and the command
says not to report the numbers.

{pstd}
Stored in {cmd:r()}: {cmd:r(converged)}, {cmd:r(gnorm)}, {cmd:r(maxA)}.


{marker alpha}{...}
{title:estat alpha}

{p 8 16 2}
{cmd:estat alpha} [{cmd:,} {opt gen:erate(newvar)} {opt q:uantile(#)}
{opt det:ail}]

{pstd}
Summarises the profiled-out fixed effects {it:alpha}-hat_i({it:tau}) and,
with {opt generate()}, writes each unit's own value onto every row of
{cmd:e(sample)}. {opt quantile()} is required when the fit holds more than one
quantile. {opt detail} passes through to {helpb summarize}.

{pstd}
{bf:Read them with care.} Each {it:alpha}-hat_i is estimated from that unit's
own {it:T} observations alone: they are consistent as {it:T} grows, not as
{it:n} grows. Their dispersion is therefore {bf:not} an estimate of the
dispersion of the true effects -- it is that plus estimation noise of order
1/sqrt({it:T}) per unit -- and they should not be used as a regressand in a
second stage.

{pstd}
Stored in {cmd:r()}: {cmd:r(alpha)}, {cmd:r(N_g)}.


{marker absent}{...}
{title:What is deliberately absent}

{pstd}
{bf:There is no {cmd:pr} or probability statistic.} The smoothed indicator
{it:G_h} that the estimator evaluates looks like a conditional CDF and is not
one: the fourth-order kernel of Section 6 takes negative values, so {it:G_h}
leaves [0,1] -- this package's own kernel test measures
{it:G}({c -}1/sqrt(3)) = {c -}0.0533. It is a device for making the moment
condition differentiable, nothing more, and offering it as a predicted
probability would hand back numbers that can be negative or exceed one.

{pstd}
{bf:There is no {cmd:scores} option.} The estimator is GMM on a profiled
moment, not maximum likelihood, so there is no likelihood score. The moment
vector at the estimate is in {cmd:e(mvec)} and its long-run variance in
{cmd:e(Omega)} (single-quantile fits).

{pstd}
{bf:There is no uniform confidence band.} See
{help xtpqgmm_methods##uniform:[methods] Uniform inference} and
{helpb xtpqgmmplot}.


{marker examples}{...}
{title:Examples}

{pstd}Fit, then test the over-identifying restriction{p_end}
{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(50)}{p_end}
{phang2}{cmd:. estat overid}{p_end}

{pstd}Everything the fit knows about itself{p_end}
{phang2}{cmd:. estat diagnostics}{p_end}

{pstd}The fixed effects, kept as a variable{p_end}
{phang2}{cmd:. estat alpha, generate(ahat) detail}{p_end}

{pstd}Fitted median, and residuals from it{p_end}
{phang2}{cmd:. predict double q50}{p_end}
{phang2}{cmd:. predict double r50, residuals}{p_end}

{pstd}Three quantiles at once, then the fitted values of each{p_end}
{phang2}{cmd:. xtpqgmm y (x = z1 z2), quantile(25 50 75)}{p_end}
{phang2}{cmd:. estat overid}{p_end}
{phang2}{cmd:. predict double f25, xba quantile(25)}{p_end}
{phang2}{cmd:. predict double f75, xba equation(q75)}{p_end}
{phang2}{cmd:. count if f25 > f75}{space 4}{it:// crossings are not ruled out}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
