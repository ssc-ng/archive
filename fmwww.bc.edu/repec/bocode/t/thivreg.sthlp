{smcl}
{* *! version 1.0.0  05oct2026}{...}
{vieweralsosee "thregress" "help thregress"}{...}
{vieweralsosee "ivregress" "help ivregress"}{...}
{vieweralsosee "thsearch" "help thsearch"}{...}
{vieweralsosee "threshkit choose" "help threshkit_choose"}{...}
{viewerjumpto "Syntax" "thivreg##syntax"}{...}
{viewerjumpto "Description" "thivreg##description"}{...}
{viewerjumpto "Options" "thivreg##options"}{...}
{viewerjumpto "Why the threshold is 2SLS and the slopes are GMM" "thivreg##why"}{...}
{viewerjumpto "Which interval to report" "thivreg##which"}{...}
{viewerjumpto "The threshold variable must be exogenous" "thivreg##exog"}{...}
{viewerjumpto "Weak instruments inside a regime" "thivreg##weak"}{...}
{viewerjumpto "What is NOT provided" "thivreg##limits"}{...}
{viewerjumpto "Examples" "thivreg##examples"}{...}
{viewerjumpto "Stored results" "thivreg##results"}{...}
{viewerjumpto "References" "thivreg##refs"}{...}
{title:Title}

{phang}
{bf:thivreg} {hline 2} Threshold regression with endogenous regressors
(Caner-Hansen 2004)


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:thivreg} {it:depvar} [{it:varlist1}]
{cmd:(}{it:varlist2} {cmd:=} {it:varlist_iv}{cmd:)} {ifin}{cmd:,}
{opth thresh:var(varname)} [{it:options}]

{pstd}
{it:varlist1} are the exogenous regressors, {it:varlist2} the endogenous ones
and {it:varlist_iv} the excluded instruments — exactly as in
{helpb ivregress}.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth threshvar(varname)}}the threshold variable; must be
{bf:exogenous}{p_end}
{synopt:{opt red:uced(string)}}{opt linear} (default) or {opt threshold}{p_end}
{synopt:{opt trim(#)}}trimming of the grid; default {cmd:trim(0.05)}{p_end}
{synopt:{opt gridn(#)}}cap the grid at # points{p_end}
{synopt:{opt nocons:tant}}suppress the constant{p_end}
{synopt:{opt cim:ethod(string)}}{opt quadratic} (default), {opt uncorrected} or {opt kernel}{p_end}
{synopt:{opt cilevel2(#)}}level of the gamma interval the union bound uses; default 0.80{p_end}
{synopt:{opt notw:ostep}}skip the union slope intervals{p_end}
{synopt:{opt level(#)}}level of the reported gamma interval{p_end}
{synoptline}
{p 4 6 2}* {opt threshvar()} is required.{p_end}
{p 4 6 2}
{cmd:estat} subcommands: {bf:lrplot}, {bf:regimes}, {bf:firststage},
{bf:jtest}, {bf:twostep}, {bf:table}. {cmd:predict} supports {bf:xb},
{bf:residuals} and {bf:regime}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:thivreg} fits

{p 8 8 2}
y{subscript:i} = z{subscript:i}'{bf:b}{subscript:1}
1{c -(}q{subscript:i} {ul:<} {&gamma}{c )-}
+ z{subscript:i}'{bf:b}{subscript:2}
1{c -(}q{subscript:i} > {&gamma}{c )-} + e{subscript:i}

{pstd}
where z = (z{subscript:1}, z{subscript:2}) contains {bf:endogenous}
regressors z{subscript:1} alongside exogenous ones, x are the excluded
instruments, and q is an exogenous threshold variable.

{pstd}
This is the gap that {helpb threshold} and {helpb thregress} cannot fill and
that {helpb ivregress} cannot fill either: {cmd:ivregress} will estimate a
threshold model if you build the interactions by hand, but only at a
threshold you supply, and it gives you no confidence interval for the
threshold and no way to search for it. {cmd:thivreg} searches for
{&gamma}, inverts a likelihood ratio for it, and then does something neither
command does — it propagates that uncertainty into the slope intervals.

{pstd}
Four steps, in the order the paper takes them.

{phang}
{bf:1. Reduced form.} z{subscript:1} is regressed on (x, z{subscript:2}) to
give z{subscript:1}-hat. With {opt reduced(threshold)} that first stage is
itself fitted as a threshold model, by a multivariate search minimising
det(E'E).

{phang}
{bf:2. The threshold.} {&gamma} minimises the sum of squares of y on
(z-hat, z-hat·1{c -(}q {ul:<} {&gamma}{c )-}) — concentrated {bf:2SLS}. Its
confidence interval comes from inverting the likelihood ratio with the
critical value −2·ln(1−{&radic}level), in three versions: uncorrected and
two heteroskedasticity corrections.

{phang}
{bf:3. The slopes.} Having split at {&gamma}-hat, each regime is estimated by
two-step efficient {bf:GMM} on the {bf:actual} z, with its own
heteroskedasticity-robust weight matrix and its own Hansen J.

{phang}
{bf:4. The slope intervals that matter.} Both regimes are refitted at every
grid point inside the confidence interval for {&gamma}, and the union of the
resulting per-coefficient intervals is reported. These are wider than the
coefficient table, and they are the ones to report.


{marker options}{...}
{title:Options}

{phang}
{opth threshvar(varname)} is the threshold variable. It must be exogenous;
see {it:The threshold variable must be exogenous} below.

{phang}
{opt reduced(linear|threshold)} chooses the first stage.
{opt reduced(linear)} is the default and is right when the relation between
the endogenous regressors and the instruments does not itself switch.
{opt reduced(threshold)} fits the reduced form as a threshold model, which the
paper recommends when it might: a first stage that switches and is modelled as
linear produces a z-hat that is wrong in both regimes, and the threshold
search then inherits that error. The reduced form's own threshold is reported
as {cmd:e(gamma_rf)} and need not equal {&gamma}-hat.

{phang}
{opt trim(#)} trims the grid. The default is {bf:0.05}, not the 0.15 used
elsewhere in THRESHKIT, because that is what the paper's own program uses and
the published numbers were produced with it. Note also that the trimming rule
here is applied to the {bf:order statistics} — the sorted sample is cut at
indices round({it:trim}·n)+k and round((1−{it:trim})·n)−k and then reduced to
its distinct values — which is not the cumulative-count rule {helpb thregress}
uses. With heavy ties in q the two differ.

{phang}
{opt gridn(#)} thins the grid to # of its own quantiles. The union bound
refits two GMM problems at every grid point inside the interval for
{&gamma}, so this is the option that controls the running time.

{phang}
{opt cimethod(quadratic|uncorrected|kernel)} chooses which of the three
{&gamma} intervals the union bound uses as its input. All three are always
reported; this only selects the one that drives step 4.
{opt quadratic} is the default and is the paper's own choice.

{phang}
{opt cilevel2(#)} is the level of the {&gamma} interval fed into the union
bound, as a fraction. The default 0.80 is the paper's. It is deliberately
{it:lower} than the level of the reported {&gamma} interval: the union bound
is a conservative construction, so feeding it a 95% interval for {&gamma}
produces slope intervals wide enough to be useless.

{phang}
{opt notwostep} skips step 4. The slope intervals then come straight from the
GMM standard errors and {bf:condition on} {&gamma}{bf:-hat}. Use it only when
you are reporting the conditional intervals deliberately and saying so.

{phang}
{opt level(#)} is the level of the reported {&gamma} interval.


{marker why}{...}
{title:Why the threshold is 2SLS and the slopes are GMM}

{pstd}
This asymmetry looks like an inconsistency and is not. It is the paper's, and
the reason is worth understanding before changing anything.

{pstd}
The threshold is estimated by {bf:concentrated 2SLS} because the criterion has
to be minimised over {&gamma}, and a GMM criterion whose weight matrix is
re-estimated at every {&gamma} is not a well-behaved objective: the weight
moves with the parameter, the criterion can be non-monotone for reasons that
have nothing to do with fit, and the limit theory for the argmin would have to
account for it. The 2SLS sum of squares does not have that problem, and the
LR-inversion interval of Hansen (2000) carries over to it.

{pstd}
The slopes are estimated by {bf:two-step efficient GMM} because at a
{it:fixed} {&gamma} there is no reason to give up efficiency, and the
heteroskedasticity-robust weight is exactly what one wants when the two
regimes have different error variances — which, in a model whose whole point
is that the regimes differ, they usually do.

{pstd}
So: {&gamma}-hat comes from a criterion chosen for its behaviour as a function
of {&gamma}, and the slopes from a criterion chosen for its efficiency at the
{&gamma} you ended up with. Both are the paper's; neither is a compromise.


{marker which}{...}
{title:Which interval to report}

{pstd}
{bf:For} {&gamma}{bf::} one of the three printed intervals, and say which.
They can differ substantially. {&eta}-squared scales the critical value for
heteroskedasticity; an {&eta}-squared far from 1 means the uncorrected
interval is simply the wrong width. {opt cimethod(quadratic)} is the paper's
default. If the interval covers the whole trimmed range, the threshold is
{bf:not identified} and no amount of reporting the point estimate fixes that.

{pstd}
If the output says {bf:NOT an interval}, the accepted set
{c -(}{&gamma}: LR({&gamma}) {c <} cv{c )-} has a hole in it. The printed
bounds are its hull. This is a genuine feature of inverting a likelihood ratio
whose profile is not unimodal, not a numerical artefact, and reporting the
hull without saying so overstates what the data pin down.

{pstd}
{bf:For the slopes:} the {bf:union} intervals from step 4, which
{bf:estat twostep} also returns as a matrix. The coefficient table printed
above them treats {&gamma} as known and is therefore too narrow. The union
intervals use a fixed 1.96 multiplier, as the authors' program does, so they
are a 95% bound whatever {opt level()} says; this is stated rather than
quietly improved, because the published numbers were produced that way.


{marker exog}{...}
{title:The threshold variable must be exogenous}

{pstd}
The whole theory assumes q is exogenous. Yu (2013) shows that when q is
endogenous the 2SLS threshold estimator is {bf:inconsistent} — not merely
inefficient, and not fixable by using more instruments. {cmd:thivreg} cannot
detect this and does not try to.

{pstd}
In practice this rules out the most tempting specification: splitting on a
variable that is itself a choice of the same agents whose behaviour you are
modelling. A predetermined variable, a lag, a geographic or institutional
characteristic, or an aggregate the individual unit cannot influence is safe.
"Firm size in the same year as the outcome" is not.

{pstd}
If q must be endogenous, this command is the wrong tool and so is every other
one in the package; the relevant literature is small and the estimators are
not the same.


{marker weak}{...}
{title:Weak instruments inside a regime}

{pstd}
Run {bf:estat firststage} before reading any coefficient. It reports, for each
endogenous variable and {it:each regime separately}, the F on the excluded
instruments and the partial R-squared.

{pstd}
The failure it catches has no analogue in a linear IV model. An instrument can
be strong in the full sample and weak — or constant — {it:inside one regime},
particularly when the instrument and the threshold variable are related. That
regime's coefficients are then unidentified while the pooled first stage looks
perfectly healthy. No official Stata command can warn you, because none of
them knows the regimes exist.

{pstd}
Treat F {c >} 10 as a floor, not a licence: the rule of thumb was derived for
a single sample, not for a subsample selected by minimising a sum of squares.


{marker limits}{...}
{title:What is NOT provided}

{pstd}
Stated plainly so nothing here is read as more than it is.

{phang}
o {bf:There is no test of no threshold.} Caner and Hansen (2004) give
estimation and confidence intervals; they do not give a test, and inventing
one would be inventing inference. Report the confidence interval for
{&gamma}: if it covers the trimmed range, you have no threshold. Work on
testing under endogeneity exists (Rothfelder and Boldea, 2022) and is not
implemented here because it has not been verified against a reference.

{phang}
o {bf:One threshold only.} The theory is two-regime.

{phang}
o {bf:No endogenous threshold variable.} See above.

{phang}
o {bf:No weak-instrument-robust inference.} The GMM standard errors and the J
statistics are the conventional ones and assume the instruments are strong
inside each regime. {bf:estat firststage} tells you whether that is plausible;
it does not repair it.

{phang}
o {bf:No cluster or HAC variance.} The weight matrix is
heteroskedasticity-robust (the paper's), not clustered and not
autocorrelation-robust.

{phang}
o {bf:No panel version.} Out of scope for THRESHKIT by design.


{marker examples}{...}
{title:Examples}

{pstd}Setup: a threshold model with one endogenous regressor{p_end}
{phang2}{cmd:. set seed 20261005}{p_end}
{phang2}{cmd:. set obs 400}{p_end}
{phang2}{cmd:. generate double q  = rnormal()}{p_end}
{phang2}{cmd:. generate double x1 = rnormal()}{p_end}
{phang2}{cmd:. generate double x2 = rnormal()}{p_end}
{phang2}{cmd:. generate double u  = rnormal()}{p_end}
{phang2}{cmd:. generate double z  = 0.6*x1 + 0.6*x2 + 0.7*u + rnormal()}{p_end}
{phang2}{cmd:. generate double y  = cond(q <= 0, 1, -1)*z + u + rnormal()}{p_end}

{pstd}Fit it{p_end}
{phang2}{cmd:. thivreg y (z = x1 x2), threshvar(q)}{p_end}

{pstd}Always check instrument strength {it:within each regime}{p_end}
{phang2}{cmd:. estat firststage}{p_end}

{pstd}The intervals that do not condition on gamma-hat{p_end}
{phang2}{cmd:. estat twostep}{p_end}

{pstd}The LR profile with all three critical values drawn on it{p_end}
{phang2}{cmd:. estat lrplot}{p_end}

{pstd}Overidentification, regime by regime{p_end}
{phang2}{cmd:. estat jtest}{p_end}

{pstd}When the first stage may switch regime too{p_end}
{phang2}{cmd:. thivreg y (z = x1 x2), threshvar(q) reduced(threshold)}{p_end}

{pstd}With exogenous controls, the kernel correction, and a coarser grid{p_end}
{phang2}{cmd:. thivreg y x1 (z = x2), threshvar(q) cimethod(kernel) gridn(60)}{p_end}

{pstd}Conditional intervals only, said out loud{p_end}
{phang2}{cmd:. thivreg y (z = x1 x2), threshvar(q) notwostep}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:thivreg} stores the following in {cmd:e()}:

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations{p_end}
{synopt:{cmd:e(k_endog)}}, {cmd:e(k_exog)}, {cmd:e(k_regime)}, {cmd:e(k_inst)}dimensions{p_end}
{synopt:{cmd:e(gamma)}}the threshold{p_end}
{synopt:{cmd:e(gamma_rf)}}the reduced form's own threshold, with {opt reduced(threshold)}{p_end}
{synopt:{cmd:e(gamma_lo)}}, {cmd:e(gamma_hi)}uncorrected interval{p_end}
{synopt:{cmd:e(gamma_lo_quad)}}, {cmd:e(gamma_hi_quad)}quadratic correction{p_end}
{synopt:{cmd:e(gamma_lo_kern)}}, {cmd:e(gamma_hi_kern)}kernel correction{p_end}
{synopt:{cmd:e(ci_contiguous)}}, {cmd:..._quad}, {cmd:..._kern}1 if that accepted set is an interval{p_end}
{synopt:{cmd:e(eta2_quad)}}, {cmd:e(eta2_kern)}the two eta-squared estimates{p_end}
{synopt:{cmd:e(lr_cv)}}−2 ln(1 − sqrt(level)){p_end}
{synopt:{cmd:e(ssr)}}, {cmd:e(ssr0)}2SLS sums of squares with and without the threshold{p_end}
{synopt:{cmd:e(sigma2)}}e(ssr)/N{p_end}
{synopt:{cmd:e(N_regime1)}}, {cmd:e(N_regime2)}the split{p_end}
{synopt:{cmd:e(n_grid)}}, {cmd:e(n_gridci)}grid points searched, and used by the union bound{p_end}
{synopt:{cmd:e(J_regime1)}}, {cmd:e(J_regime2)}, {cmd:e(J_df)}Hansen's J per regime{p_end}
{synopt:{cmd:e(p_J1)}}, {cmd:e(p_J2)}their p-values{p_end}
{synopt:{cmd:e(trim)}}, {cmd:e(level)}, {cmd:e(cilevel2)}what was asked for{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:thivreg}{p_end}
{synopt:{cmd:e(depvar)}}, {cmd:e(endog)}, {cmd:e(exog)}, {cmd:e(insts)}the variable lists{p_end}
{synopt:{cmd:e(zn)}}the per-regime coefficient names{p_end}
{synopt:{cmd:e(threshold_var)}}the threshold variable{p_end}
{synopt:{cmd:e(reduced)}}, {cmd:e(cimethod)}what was asked for{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}, {cmd:e(V)}coefficients, {cmd:Regime1} then {cmd:Regime2}.
{cmd:e(V)} is block-diagonal, which is exact: the regimes use disjoint
observations, so their GMM estimators are independent{p_end}
{synopt:{cmd:e(profile)}}grid x 3: {cmd:gamma ssr lr}{p_end}
{synopt:{cmd:e(gamma_ci)}}3 x 2, one row per correction{p_end}
{synopt:{cmd:e(slopeci1)}}, {cmd:e(slopeci2)}the union intervals per regime{p_end}
{synopt:{cmd:e(rf_profile)}}the reduced form's det(E'E) path, with {opt reduced(threshold)}{p_end}


{marker refs}{...}
{title:References}

{phang}
Caner, M., and B. E. Hansen. 2004. Instrumental variable estimation of a
threshold model. {it:Econometric Theory} 20: 813-843.
{browse "https://doi.org/10.1017/S0266466604205011":doi:10.1017/S0266466604205011}.

{phang}
Hansen, B. E. 2000. Sample splitting and threshold estimation.
{it:Econometrica} 68: 575-603.
{browse "https://doi.org/10.1111/1468-0262.00124":doi:10.1111/1468-0262.00124}.

{phang}
Yu, P. 2013. Inconsistency of 2SLS estimators in threshold regression with
endogeneity. {it:Economics Letters} 120: 532-536.

{phang}
Rothfelder, M., and O. Boldea. 2022. Testing for a threshold in models with
endogenous regressors. arXiv:2207.10076.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{break}
merwanroudane920@gmail.com
{p_end}


{title:Also see}

{psee}
Manual: {helpb threshkit}, {helpb threshkit_choose}

{psee}
Online: {helpb thivtest} (the threshold TEST for this model),
{helpb thregress}, {helpb thsearch}, {helpb thkink}, {helpb thendog},
{helpb thexport}, {helpb ivregress}, {helpb estat overid}
{p_end}
