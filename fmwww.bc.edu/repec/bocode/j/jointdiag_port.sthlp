{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag spec" "help jointdiag_spec"}{...}
{vieweralsosee "jointdiag arch" "help jointdiag_arch"}{...}
{vieweralsosee "wntestq" "help wntestq"}{...}
{viewerjumpto "Syntax" "jointdiag_port##syntax"}{...}
{viewerjumpto "Description" "jointdiag_port##description"}{...}
{viewerjumpto "Options" "jointdiag_port##options"}{...}
{viewerjumpto "The four families" "jointdiag_port##families"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_port##interpret"}{...}
{viewerjumpto "Examples" "jointdiag_port##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_port##results"}{...}

{title:Title}

{phang}
{bf:jointdiag port} {hline 2} Mixed portmanteau tests for the conditional mean
AND the conditional variance


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:port} [{cmd:,} {it:options}]

{p 4 4 2}
A postestimation command: fit the model first, usually with {helpb arch} or
{helpb arima}.  Alternatively supply residuals directly.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:ags(#)}}number of lags {it:M}; default min(floor(sqrt({it:n})), 20){p_end}
{synopt:{opt l0(#)}}starting lag of the mean block in {it:Q1M}; default
{cmd:l0(1)}{p_end}
{synopt:{opt meth:od(string)}}which families to show: {cmd:all} (default),
{cmd:marginal}, {cmd:wl}, {cmd:vw}, {cmd:mahdi}{p_end}
{synopt:{opt res:id(varname)}}use these residuals instead of a fitted model{p_end}
{synopt:{opt v:ariance(varname)}}the matching conditional variance (required
with {cmd:resid()}){p_end}
{synopt:{opt l:evel(#)}}confidence level for the graph band{p_end}
{synopt:{opt gr:aph}}paired correlogram of residuals and squared residuals{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
A Ljung{c 150}Box test on the residuals checks the conditional mean.  A
Li{c 150}Mak test on the squared standardised residuals checks the conditional
variance.  Running both and reading them separately is a multiple-testing
problem, and worse, the variance test is not reliable when the mean is
misspecified.  {cmd:jointdiag port} computes the mixed statistics that handle
both moments at once.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets {it:M}.  Two cautions.  The Velasco{c 150}Wang transform can
only project {it:M} - {it:k} pairs, where {it:k} is the number of estimated
parameters, so with a GARCH(1,1) plus an AR(1) and a regressor you need
{it:M} comfortably above 5.  Mahdi's cross-correlation blocks use the same
{it:M}.

{phang}
{opt l0(#)} is the lag from which the mean block of {it:Q1M} starts.
Wong and Ling note that {it:X_q} is close to zero for large lags in many
models, which is what makes the simplification legitimate, and their
simulations recommend {cmd:l0(1)}.

{phang}
{opt resid()} and {opt variance()} let you feed in residuals from a model this
command cannot refit.  Only the derivative-free statistics
(Ljung{c 150}Box, Li{c 150}Mak, {it:Q_S}, Mahdi) are then available;
{it:Q_M} and the Velasco{c 150}Wang transform need the model's derivatives.


{marker families}{...}
{title:The four families}

{pstd}
{bf:Marginal.}  Ljung{c 150}Box on the standardised residuals and Li{c 150}Mak
on their squares.  Reported for reference, not for decisions.

{pstd}
{bf:Wong and Ling (2005).}  Three statistics.  {it:Q_S} is their eq. (12), the
simple Ljung{c 150}Box-corrected sum of the two marginals.  {it:Q1M} applies the
Li{c 150}Mak variance correction to the squared-residual block.  {it:Q_M} is the
full Corollary 1 statistic using the complete covariance matrix
{it:V}{&Omega}{it:V}'.  Their simulations found {it:Q_M} and {it:Q_S} very
similar in power, especially in large samples, with improvements over the
individual statistics of 39 to 47 percent when the model is wrong in both
moments.

{pstd}
{bf:Velasco and Wang (2015).}  A recursive projection that removes the
estimation effect {it:entirely}, so the transformed autocorrelations are
asymptotically standard normal and a plain Box{c 150}Pierce sum of them is
chi-squared.  The practical pay-off: you do not need the asymptotic theory of
whatever estimator produced the residuals, which may be an inefficient two-step
one, and you do not need the lag order to grow with the sample.  The price is
that only {it:M} - {it:k} pairs survive.

{pstd}
{bf:Mahdi (2024).}  Adds the cross-correlations between the residuals and their
squares, at positive lags ({it:C_12}) and negative lags ({it:C_21}).  These
catch models in which the residual and its own square are linked across time
{c 150} a direction the other three families are blind to.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Read the marginals together, never alone.}  The decision table:

{p2colset 8 44 46 2}{...}
{p2col:mean rejects, variance does not}the conditional mean is misspecified{p_end}
{p2col:variance rejects, mean does not}most likely genuine ARCH left over{p_end}
{p2col:both reject}fix the mean first, then re-test{p_end}
{p2col:neither rejects, joint rejects}the model is still inadequate; the
failure is in the cross-moment or spread over lags{p_end}
{p2colreset}{...}

{pstd}
That last row is exactly Wong and Ling's advice: "if both Box{c 150}Pierce and
Li{c 150}Mak are insignificant but {it:Q_M} is significant, then it is an
indication that our model can still be inadequate.  Trial over-fitting in the
conditional mean or conditional variance part is still worthwhile."

{pstd}
{bf:If the Velasco{c 150}Wang rows are missing} the model has too few lags
relative to its parameter count; raise {cmd:lags()}.

{pstd}
{bf:The graph} is a paired correlogram with the pointwise band under the null.
Spikes in the left panel point to the mean, spikes in the right panel to the
variance.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. arch dln_inv dln_inc, ar(1) arch(1)}{p_end}

{pstd}The full battery{p_end}
{phang2}{cmd:. jointdiag port, lags(12)}{p_end}

{pstd}Only the Wong{c 150}Ling family, with the correlogram{p_end}
{phang2}{cmd:. jointdiag port, lags(12) method(wl) graph}{p_end}

{pstd}Mahdi's cross-correlation statistics only{p_end}
{phang2}{cmd:. jointdiag port, lags(10) method(mahdi)}{p_end}

{pstd}With residuals computed elsewhere{p_end}
{phang2}{cmd:. jointdiag port, resid(myres) variance(myh) lags(8)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(q_lb)}, {cmd:r(p_lb)}}Ljung{c 150}Box on the residuals{p_end}
{synopt:{cmd:r(q_limak)}, {cmd:r(p_limak)}}Li{c 150}Mak on the squares{p_end}
{synopt:{cmd:r(q_s)}, {cmd:r(p_s)}}Wong{c 150}Ling {it:Q_S}{p_end}
{synopt:{cmd:r(q_1m)}, {cmd:r(p_1m)}}Wong{c 150}Ling {it:Q1M}{p_end}
{synopt:{cmd:r(q_m)}, {cmd:r(p_m)}}Wong{c 150}Ling {it:Q_M}{p_end}
{synopt:{cmd:r(vw)}, {cmd:r(p_vw)}}Velasco{c 150}Wang joint{p_end}
{synopt:{cmd:r(c12)}, {cmd:r(c21)}}Mahdi's two statistics{p_end}
{synopt:{cmd:r(N)}, {cmd:r(M)}}observations and lags{p_end}


{title:References}

{phang}Li, W. K., and T. K. Mak. 1994. {it:JTSA} 15: 627{c 150}636.
{browse "https://doi.org/10.1111/j.1467-9892.1994.tb00217.x"}{p_end}
{phang}Ling, S., and W. K. Li. 1997. {it:JTSA} 18: 447{c 150}464.
{browse "https://doi.org/10.1111/1467-9892.00061"}{p_end}
{phang}Wong, H., and S. Ling. 2005. {it:JTSA} 26: 569{c 150}579.
{browse "https://doi.org/10.1111/j.1467-9892.2005.00420.x"}{p_end}
{phang}Velasco, C., and X. Wang. 2015. {it:JTSA} 36: 39{c 150}60.
{browse "https://doi.org/10.1111/jtsa.12091"}{p_end}
{phang}Mahdi, E. 2024. {it:Statistics and Computing} 34: 76.
{browse "https://doi.org/10.1007/s11222-024-10393-w"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
