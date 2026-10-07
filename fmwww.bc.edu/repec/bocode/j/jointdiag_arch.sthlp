{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag im" "help jointdiag_im"}{...}
{vieweralsosee "jointdiag bilinear" "help jointdiag_bilinear"}{...}
{vieweralsosee "jointdiag port" "help jointdiag_port"}{...}
{vieweralsosee "arch" "help arch"}{...}
{viewerjumpto "Syntax" "jointdiag_arch##syntax"}{...}
{viewerjumpto "Description" "jointdiag_arch##description"}{...}
{viewerjumpto "Options" "jointdiag_arch##options"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_arch##interpret"}{...}
{viewerjumpto "The stationarity trap" "jointdiag_arch##stat"}{...}
{viewerjumpto "Examples" "jointdiag_arch##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_arch##results"}{...}

{title:Title}

{phang}
{bf:jointdiag arch} {hline 2} ARCH / AARCH and autocorrelation, each tested in
the presence of the other


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:arch} [{it:depvar} {it:indepvars}] {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ar(#)}}AR order tested; default {cmd:ar(1)}{p_end}
{synopt:{opt archl:ags(#)}}ARCH order tested; default {cmd:archlags(1)}{p_end}
{synopt:{opt aarch}}augmented ARCH (cross-products of lagged errors){p_end}
{synopt:{opt robust}}Wooldridge (1990) robust LM forms{p_end}
{synopt:{opt nosta:tionarity}}skip the stationarity block{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt gr:aph}}naive-versus-corrected plot{p_end}
{synopt:{opt name(string)}}graph name{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
Bera, Higgins and Lee (1992) write the disturbance as an autoregression whose
{it:coefficients are random}:

{p 8 8 2}
{&epsilon}_t = {&Sigma}_j ({&phi}_j + {&eta}_jt) {&epsilon}_{t-j} + {it:u_t}

{pstd}
With E({&eta}{&eta}') diagonal this {it:is} Engle's ARCH; with it unrestricted
it is their augmented ARCH.  The formulation makes the interaction between the
two problems explicit, and three consequences follow.

{p 4 7 2}
{bf:1.}  The usual test for autocorrelation is invalid under ARCH, because the
information block {it:I}_{&phi}{&phi} depends on the ARCH parameters.

{p 4 7 2}
{bf:2.}  The usual test for ARCH is invalid under autocorrelation.

{p 4 7 2}
{bf:3.}  {bf:Autocorrelation can destroy the stationarity of an ARCH process
that would be stationary on its own.}

{pstd}
The command reports a naive panel and a corrected panel side by side.  The gap
between them is the interaction effect.


{marker options}{...}
{title:Options}

{phang}
{opt ar(#)} and {opt archlags(#)} set the two orders.  Panel A tests each
direction from OLS residuals; Panel B tests ARCH from the residuals of an
AR({it:p}) fit and autocorrelation from the {it:standardised} residuals of an
ARCH({it:q}) fit.

{phang}
{opt aarch} tests the augmented alternative,
{it:h_t} = {it:sigma}{c 94}2 + {&epsilon}_{t-}'{it:C}{&epsilon}_{t-} with
{it:C} unrestricted, giving {it:q}({it:q}+1)/2 degrees of freedom instead of
{it:q}.  Because AARCH depends on the signs of the lagged errors it displays
the leverage effect of Nelson's (1991) asymmetric ARCH.

{phang}
{opt robust} switches both panels to Wooldridge's (1990) regression-based
robust LM statistics, which stay valid when the conditional variance is
misspecified.  This is what the authors report as LM_R-AR in their Table 2.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Panel A vs Panel B is the whole table.}  Four readings:

{p 4 7 2}
{bf:*}  Panel A rejects ARCH, Panel B does not {c 174} the ARCH signal was
autocorrelation in disguise.  Model the mean, not the variance.

{p 4 7 2}
{bf:*}  Panel A rejects AR, Panel B does not {c 174} the autocorrelation signal
was ARCH in disguise (Diebold 1986: ARCH invalidates the asymptotic theory of
the sample autocorrelations and so of the Box{c 150}Pierce and Ljung{c 150}Box
statistics).

{p 4 7 2}
{bf:*}  Both panels reject {c 174} both are genuinely present.  Fit them
jointly, e.g. {cmd:arch} {it:y} {it:x}{cmd:, ar(1) arch(1)}, and {bf:check the
stationarity block}.

{p 4 7 2}
{bf:*}  Neither rejects {c 174} nothing to do.

{pstd}
{bf:The joint row in Panel A} is LM(ARCH) + LM(AR), valid because the two
blocks are asymptotically orthogonal.  Use it when you want a single omnibus
decision before looking at the pieces.


{marker stat}{...}
{title:The stationarity trap}

{pstd}
For a pure ARCH({it:q}) process the familiar condition is
{&Sigma}{&gamma}_j < 1.  Proposition 1 of the paper shows that once the errors
are also autocorrelated the condition becomes

{p 8 8 2}
{it:w}({&phi}) {&Sigma}_j {&gamma}_j < 1

{pstd}
with {it:w}({&phi}) {&ge} 1 {c 150} for AR(1), {it:w} = 1/(1-{&phi}{c 94}2).
So a process can satisfy the textbook ARCH condition and still be
non-stationary.  The paper's own example: with {&phi} = (0.27, 0.33),
{it:w}({&phi}) = 1.34, so any {&gamma} above 0.75 breaks stationarity even
though {&gamma} < 1.

{pstd}
The block prints {it:w}({&phi}), {&Sigma}{&gamma}, their product, and both
conditions.  If {&Sigma}{&gamma} < 1 but the product exceeds 1, the output says
so explicitly.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. regress dln_inv dln_inc dln_consump}{p_end}

{pstd}The basic comparison{p_end}
{phang2}{cmd:. jointdiag arch, ar(1) archlags(1)}{p_end}

{pstd}Augmented ARCH, robust forms, with the plot{p_end}
{phang2}{cmd:. jointdiag arch, ar(2) archlags(2) aarch robust graph}{p_end}

{pstd}Just the statistics, for a loop{p_end}
{phang2}{cmd:. jointdiag arch, notable}{p_end}
{phang2}{cmd:. display "ARCH naive = " r(lm_arch) "  given AR = " r(lm_arch_ar)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(lm_arch)}, {cmd:r(df_arch)}, {cmd:r(p_arch)}}ARCH ignoring AR{p_end}
{synopt:{cmd:r(lm_ar)}, {cmd:r(df_ar)}, {cmd:r(p_ar)}}AR ignoring ARCH{p_end}
{synopt:{cmd:r(lm_joint)}, {cmd:r(df_joint)}, {cmd:r(p_joint)}}their sum{p_end}
{synopt:{cmd:r(lm_arch_ar)}, {cmd:r(p_arch_ar)}}ARCH given AR{p_end}
{synopt:{cmd:r(lm_ar_arch)}, {cmd:r(p_ar_arch)}}AR given ARCH{p_end}
{synopt:{cmd:r(wphi)}}{it:w}({&phi}){p_end}
{synopt:{cmd:r(sumg)}}{&Sigma}{&gamma}{p_end}
{synopt:{cmd:r(statcond)}}{it:w}({&phi}){&Sigma}{&gamma}{p_end}
{synopt:{cmd:r(maxeig)}}max |eigenvalue| of the AR companion matrix{p_end}
{synopt:{cmd:r(N)}}observations{p_end}


{title:References}

{phang}Bera, A. K., M. L. Higgins, and S. Lee. 1992. {it:JBES} 10: 133{c 150}142.
{browse "https://doi.org/10.1080/07350015.1992.10509893"}{p_end}
{phang}Engle, R. F. 1982. {it:Econometrica} 50: 987{c 150}1007.
{browse "https://doi.org/10.2307/1912773"}{p_end}
{phang}Wooldridge, J. M. 1990. {it:Econometric Theory} 6: 17{c 150}43.
{browse "https://doi.org/10.1017/s0266466600004898"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
