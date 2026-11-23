
{smcl}
{* *! version 2.1, 22 Nov 2026}{...}
help for {helpb xtgls2}{right:Manh Hoang-Ba (hbmanh9492@gmail, {browse "https://www.youtube.com/@manhb.econometrics":Youtube}, {browse "https://www.facebook.com/ManhHB94/":Facebook}, {browse "https://manhb94econometrics.wordpress.com":Website})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{pstd}{cmd:xtgls2} {hline 2} Estimating General GLS estimator for large N, small T panel data models
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}{cmd:xtgls2} {depvar} [{indepvars}] {ifin} {weight} [{cmd:,} {it:options}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt p:gls}}use feasible pooled GLS estimator, default{p_end}
{synopt :{opt re:gls}}use feasible random-effects GLS estimator{p_end}
{synopt :{opt fe:gls}}use feasible fixed-effects GLS estimator{p_end}
{synopt :{opt fd:gls}}use feasible first-difference GLS estimator{p_end}
{synopt :{opt nocons:tant}}suppress constant term, default when {opt fegls} or {opt fdgls} is specified{p_end}
{synopt :{cmd:igls}}use iterated GLS estimator instead of two-step GLS estimator{p_end}

{syntab:SE}
{synopt :{cmdab:r:obust}}use panelvar-clustered standard errors{p_end}
{synopt :{cmdab:cl:uster(}{it:varname}{cmd:)}}use varname-clustered standard errors{p_end}
{synopt :{opt nmk}}use N-k small-sample adjustment of the variance estimator{p_end}

{syntab:Error covariance matrix}
{synopt :{opt nopdf:ix}}stop with an error if the estimated error covariance matrix (Omega) is not positive definite{p_end}
{synopt :{opt pdf:loor(#)}}floor of the repair, relative to the largest eigenvalue; default is {cmd:pdfloor(0.01)}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Optimization}
{synopt :{opt iter:ate(#)}}specifies the maximum number of iterations; default is {cmd:iterate(300)}{p_end}
{synopt :{opt tol:erance(#)}}specifies the tolerance for the coefficient vector; default is {cmd:tolerance(1e-7)}{p_end}
{synopt :{opt nolo:g}}suppress iteration log in iterated GLS estimator{p_end}

{synoptline}
{p2colreset}{...}
{p 4 8 2}The data must be {helpb xtset} (panel and time variables). {it:indepvars} may contain time-series operators and, except with {cmd:fdgls}, factor variables; see {help fvvarlist} and {help tsvarlist}.
{cmd:aweight}s and {cmd:pweight}s are allowed (see {help xtgls2##weights:Weights}). {cmd:by} is allowed; see {help by}.{p_end}


{title:Description}

{pstd}{cmd:xtgls2} estimates General GLS estimator for large N, small T linear panel data models (Pooled, RE, FE, FD), aiming to obtain (asymptotically) efficient estimators in the context of non-spherical idiosyncratic errors.{p_end}

{pstd}Specifically, in each estimator, the error covariance matrix Omega (TxT, or its analogue after the transformation) is assumed to have a general form within panels, and identical across panels. 
For more details, see Kiefer (1980) and Wooldridge (2002, 2010).{p_end}

{pstd}{cmd:xtgls2} is appropriate for panel data with N >> T. Panels may be balanced or unbalanced: for an unbalanced panel Omega is still one TxT matrix 
and the panel observed in a subset of the periods is weighted by the corresponding sub-matrix (see {help xtgls2##unbalanced:Unbalanced panels}).{p_end}

{p 4 8 2}The latest version of {cmd:xtgls2} can be found at the following link: {browse "https://github.com/ManhHB94/":https://github.com/ManhHB94/}{p_end}

{pstd}To update the {cmd:xtgls2} package to the latest version, run either of the following commands{p_end}
{phang2}. {stata `"ssc install xtgls2, replace"'}{p_end}
{phang2}. {stata `"ado update xtgls2, update"'}{p_end}
{phang2}. {stata `"net install xtgls2, from("https://raw.githubusercontent.com/ManhHB94/xtgls2/main/") replace"'}{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt pgls} is the default: the pooled GLS estimator. It uses the observed regressors and the pooled-OLS residuals to estimate Omega.

{phang}
{opt regls} is the random-effects GLS estimator. Omega is estimated from the residuals of a random-effects (Swamy and Arora, 1972) regression, and then used in a GLS on the original data. 
With unbalanced panels the Swamy-Arora variance components use the group sizes T_i (harmonic mean), as in {helpb xtreg}, {cmd:re}.

{phang}
{opt fegls} is the fixed-effects GLS estimator: the within (time-demeaned) data are transformed with a Helmert matrix, which gives a full-rank error covariance matrix of order T-1. No constant is estimated.

{phang}
{opt fdgls} is the first-difference GLS estimator. No constant is estimated.

{phang}
{opt noconstant} suppresses the constant term; it is the default with {opt fegls} and {opt fdgls}.

{phang}
{opt igls} iterates the GLS estimator (re-estimating Omega at each step) until the coefficient vector changes by less than {opt tolerance()}, or {opt iterate()} iterations.

{dlgtab:SE}

{phang}
{opt robust} requests the cluster-robust (sandwich) variance estimator with the panel variable as cluster, as in Wooldridge (2010, chapter 7). 
With {cmd:pweight}, {cmd:robust} is implied. {opt cluster(varname)} clusters on {it:varname} instead, which must be constant within panel.

{phang}
{opt nmk} multiplies the variance estimator by N/(N-k) (or (N-1)/(N-k) with {opt robust} or {opt cluster()} in addition to the usual cluster factor), where N is the number of observations used and k the number of coefficients.

{dlgtab:Error covariance matrix}

{phang}
{opt nopdfix} and {opt pdfloor(#)} concern unbalanced panels, where the pairwise estimate of Omega need not be positive (semi)definite. 
By default, when a sub-matrix of Omega (Omega_i) that is actually used for some panel is singular or not positive definite, the whole Omega is repaired once: 
eigenvalues smaller than {it:#} x {it:the largest eigenvalue} are raised to that value (default {bf:0.01}). The repair is asymptotically irrelevant, it is made only when needed, 
and a single note reports the smallest eigenvalue before the repair and the number of iterations in which it was needed ({cmd:e(omega_nfix)}, {cmd:e(omega_mineig)}). {opt nopdfix} switches the repair off: 
the command then stops with an error that reports the smallest eigenvalue. {opt pdfloor(#)} must be strictly between 0 and 1.

{dlgtab:Reporting and optimization}

{phang}
{opt level(#)}, {opt iterate(#)}, {opt tolerance(#)} and {opt nolog} are as described in the table above.


{marker methods}{...}
{title:Methods and formulas}

{pstd}For panel i = 1,...,N the model is{p_end}

{p 8 8 2}y_i = X_i*beta + u_i{p_end}
{p 8 8 2}u_i = c_i*j_T + e_i{p_end}

{pstd}where c_i is individual effects, j_T is a vector of ones. For each of the variables z_it = y_it, x_it and u_it, the transformed data z0_it are{p_end}

{p2colset 9 24 26 2}{...}
{p2col:{cmd:pgls}, {cmd:regls}}z0_it = z_it (original data){p_end}
{p2col:{cmd:fegls}}z0_it = z_it - (1/T) sum_t z_it   (time-demeaning; implemented with the Helmert transformation below){p_end}
{p2col:{cmd:fdgls}}z0_it = z_it - z_i,t-1{p_end}
{p2colreset}{...}

{pstd}The GLS estimator and its variance estimators are{p_end}

{p 8 8 2}beta_hat = (sum_i X0_i'*(Omega_i^-1)*X0_i)^-1 (sum_i X0_i'*(Omega_i^-1)*y0_i){p_end}
{p 8 8 2}Var(beta_hat) = c*A^-1,   A = sum_i X0_i'*(Omega_i^-1)*X0_i{p_end}
{p 8 8 2}RobVar(beta_hat) = c*A^-1*(sum_i X0_i'*(Omega_i^-1)*ubar_i*ubar_i'*(Omega_i^-1)*X0_i)*A^-1{p_end}

{pstd}where ubar_i = y0_i - X0_i*beta_hat, c is adjustment coefficient and Omega_i is estimated from the first-step residuals (pooled OLS, random effects, fixed effects, first differences). 
With {cmd:regls} the GLS step uses the untransformed data. The iterated estimator ({opt igls}) repeats the GLS step with Omega re-estimated from its own residuals.{p_end}

{pstd}{bf:Omega.} Balanced panels: Omega_i = Omega = N^-1 sum_i uhat0_i*uhat0_i', where uhat0_i = y0_i - X0_i*beta_hat from the first step. 
Unbalanced panels: Omega_i = S_i*Omega*S_i', where S_i (T_ixT) is the selection matrix whose rows contain a single unity entry for each period in which panel i is observed, and zeros elsewhere. 
T is the number of distinct time values of the estimation sample. Omega is the TxT matrix with elements:{p_end}

{p 8 8 2}sigma_ts = (1/N_ts) sum_i s_it*s_is*uhat0_it*uhat0_is{p_end}
{p 8 8 2}N_ts = sum_i s_it*s_is > 0{p_end}

{pstd}with s_it = 1 if panel i is observed in period t and 0 otherwise.{p_end}

{pstd}{bf:Small-sample adjustments.} Let N be the number of observations used ({cmd:e(N)}), k the number of estimated coefficients and G the number of clusters 
(with {opt robust}, the panels; with {opt cluster()}, the groups of that variable). The cluster-robust variance is multiplied by c = G/(G-1), 
and by (N-1)/(N-k) in addition when {opt nmk} is specified; that is, c = G/(G-1) without {opt nmk} and c = [G/(G-1)] x [(N-1)/(N-k)] with it. 
Without {opt robust} and {opt cluster()}, the model-based variance A^-1 is multiplied by N/(N-k) with {opt nmk} and is left unchanged otherwise.{p_end}

{pstd}{bf:Helmert transformation ({cmd:fegls}).} The time-demeaned errors of a panel have a singular covariance matrix of rank T-1. {cmd:xtgls2} therefore premultiplies the data by the (T-1)xT Helmert matrix H, 
whose r-th row (r = 1,...,T-1) has the value 1/sqrt(r(r+1)) in its first r columns, -r/sqrt(r(r+1)) in column r+1 and zero elsewhere. H is orthonormal, H*H' = I_(T-1) and H'H = I_T - j_T*j_T'/T, 
so that H*j_T = 0: the unit effect c_i is eliminated, the transformed errors have a full-rank (T-1)x(T-1) covariance matrix (stored in {cmd:e(Omega0)}), 
and GLS on the transformed data is the same as GLS on the demeaned data using the generalized inverse of their covariance matrix. {cmd:e(Omega)} is the covariance matrix of the demeaned errors in the original 
TxT basis, H'*Omega0*H (rank T-1). With unbalanced panels each panel is demeaned over its own observed periods and transformed with the Helmert matrix of order T_i - 1; 
see {help xtgls2##unbalanced:Unbalanced panels}. The Helmert transformation is closely related to the forward orthogonal deviations of Arellano and Bover (1995).{p_end}


{marker weights}{...}
{title:Weights}

{pstd}{cmd:aweight}s and {cmd:pweight}s are allowed with {cmd:pgls}, {cmd:fegls} and {cmd:fdgls}; they are not allowed with {cmd:regls}. The estimator is a weighted GLS: 
data are multiplied by the square root of the weights (normalised to mean one) before the transformation and Omega is estimated from the weighted residuals. {cmd:pweight}s imply {opt robust}.{p_end}

{pstd}Weights must be constant within each panel, with one exception: with {cmd:pgls} an {cmd:aweight} may vary within the panel. In that exceptional case {cmd:predict, scores} (and therefore {cmd:margins, vce(unconditional)}) is not available, 
because the estimating function is no longer a weighted sum of observation-level scores. Observations with missing or zero weights are excluded from the estimation sample, which can make a balanced panel unbalanced; negative weights are an error.{p_end}


{marker unbalanced}{...}
{title:Unbalanced panels}

{pstd}For an unbalanced panel Omega is still T x T matrix, estimated pairwise, and panel i is weighted by the sub-matrix S_i*Omega*S_i' of the periods in which it is observed; the formulas are in {help xtgls2##methods:Methods and formulas}. 
Panels with the same pattern of observed periods share one inversion.{p_end}

{pstd}Specific points:{p_end}

{phang2}- {cmd:fegls}: each panel is demeaned over its own observed periods. A panel with a single observation has no within variation and is dropped. 
The error covariance matrix of the transformed data, of order T-1, is estimated by least squares on the moment conditions that link it to every observation pattern; with a balanced panel this is the usual estimator. 
An error is issued if the observation patterns do not identify it.{p_end}

{phang2}- {cmd:fdgls}: a first difference exists only between two observed periods that are neighbours in the calendar of the {helpb xtset} time variable ({it:t} and {it:t - tdelta}). 
Difference periods in which no panel has an observation are dropped, and panels that have no first difference at all are dropped as singletons.{p_end}

{phang2}- {cmd:igls}: with unbalanced panels the iterated estimator is not the maximum likelihood estimator and {cmd:e(ll)}, {cmd:e(N_ic)} and {cmd:e(df_ic)} are not stored.{p_end}


{title:Postestimation}

{pstd}The following postestimation commands are available after {cmd:xtgls2}:

{synoptset 25 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{p2coldent:* {bf:{help estat ic}}}Akaike's, consistent Akaike's, corrected Akaike's, and Schwarz's Bayesian information criteria (AIC, CAIC, AICc, and BIC,respectively){p_end}
{synopt :{bf:{help estimates}}}cataloging estimation results.{p_end}
{synopt :{bf:{help predict}}}predictions, residuals and scores.{p_end}
{synopt :{bf:{help test}}}Wald tests of simple and composite linear hypotheses.{p_end}
{synopt :{bf:{help testnl}}}Wald tests of nonlinear hypotheses.{p_end}
{p2coldent:* {bf:{help lrtest}}}likelihood-ratio test{p_end}
{synopt :{bf:{help lincom}}}point estimates, standard errors, testing, and inference for linear combinations of parameters.{p_end}
{synopt :{bf:{help nlcom}}}point estimates, standard errors, testing, and inference for nonlinear combinations of parameters.{p_end}
{synopt :{bf:{help margins}}}marginal means, predictive margins, marginal effects, and average marginal effects.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 8 2}* {cmd:estat ic} and {cmd:lrtest} are available only if {cmd:igls} is specified at estimation with a balanced sample.{p_end}

{dlgtab:predict}

{p 8 16 2}{cmd:predict} [{it:type}] {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt :{opt xb}}linear prediction from the regressors named in {cmd:e(b)}; the default. No constant and no fixed effect with {cmd:fegls} and {cmd:fdgls}; with {cmd:fdgls} it is the fitted value of {cmd:D.}{it:y}.{p_end}
{synopt :{opt r:esiduals}}{cmd:e(depvar)} minus the linear prediction. After {cmd:fegls} it still contains the unit effect.{p_end}
{synopt :{opt sc:ores}}equation-level score r_it: the score of the coefficient vector for panel i is sum_t x_it*r_it, with r_i = (Omega_i^-1) times its residuals. 
Not available when {cmd:aweight}s vary within panel.{p_end}
{synoptline}
{p2colreset}{...}

{dlgtab:margins}

{pstd}{cmd:margins} may be used with its default delta-method standard errors, which treat the covariates as fixed, or with {cmd:vce(unconditional)}, which also accounts for the sampling of the covariates (Korn and Graubard, 1999). 
The latter requires that {cmd:robust} or {cmd:cluster()} was specified at estimation. With weights, specify them at estimation, not in {cmd:margins}.{p_end}

{pstd}Do not use the options {cmd:chainrule} or {cmd:nochainrule} of {cmd:margins} unless you know their effect: {cmd:xtgls2} stores {cmd:e(marginsprop)} so that {cmd:margins} uses the numerical derivative ({cmd:nochainrule}) after {cmd:pgls}, 
{cmd:regls} and {cmd:fegls}, and leaves the default (chain rule) after {cmd:fdgls}. Adding {cmd:nochainrule} after {cmd:fdgls} gives wrong unconditional standard errors.{p_end}


{title:Citation}

{p 4 8 2}{cmd:xtgls2} is not an official Stata command.
It is a free contribution to the research community.
Please cite it as such: {p_end}

{p 8 8 2}Manh Hoang-Ba, 2025. XTGLS2: Stata module to estimate GLS estimator for large N, small T panel data models.{browse "https://ideas.repec.org/c/boc/bocode/s459498.html":https://ideas.repec.org/c/boc/bocode/s459498.html}{p_end}


{title:Examples}

{phang2} {stata . webuse abdata, clear}{p_end}
{phang2} {stata . xtset id year}{p_end}

{pstd}Balanced panel{p_end}
{phang2} {stata . keep if year > 1977 & year < 1983}{p_end}
{phang2} {stata `". xtgls2 n w k ys i.ind i.year"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys i.year, regls robust"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys i.year, fegls"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys i.year, fegls cl(id)"'}{p_end}
{phang2} {stata `". xtgls2 n l(0/2).w k ys, fdgls"'}{p_end}
{phang2} {stata `". xtgls2 n l(0/2).w k ys, fdgls cl(id) igls"'}{p_end}

{pstd}Weights (constant within panel){p_end}
{phang2} {stata `". bysort id: egen double wgt = mean(ys)"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys [aw = wgt], fegls robust"'}{p_end}

{pstd}Unbalanced panel{p_end}
{phang2} {stata . webuse abdata, clear}{p_end}
{phang2} {stata . xtset id year}{p_end}
{phang2} {stata `". xtgls2 n w k ys, pgls robust"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys, fegls robust"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys, fdgls robust"'}{p_end}

{pstd}Postestimation{p_end}
{phang2} {stata `". xtgls2 n w k ys, pgls robust"'}{p_end}
{phang2} {stata `". margins, dydx(w k ys) vce(unconditional)"'}{p_end}
{phang2} {stata `". predict double xbhat, xb"'}{p_end}
{phang2} {stata `". xtgls2 n w k ys, fdgls robust"'}{p_end}
{phang2} {stata `". margins, dydx(D.w D.k D.ys) vce(unconditional)"'}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtgls2} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_ic)}}number of observations used to compute information criteria{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(N_t)}}number of periods (of difference periods with {cmd:fdgls}){p_end}
{synopt:{cmd:e(T_o)}}order of the estimated error covariance matrix{p_end}
{synopt:{cmd:e(g_min)}}smallest number of observations per group{p_end}
{synopt:{cmd:e(g_avg)}}average number of observations per group{p_end}
{synopt:{cmd:e(g_max)}}largest number of observations per group{p_end}
{synopt:{cmd:e(n_cv)}}number of estimated covariances{p_end}
{synopt:{cmd:e(n_cf)}}number of estimated coefficients{p_end}
{synopt:{cmd:e(df)}}degrees of freedom of the Wald test{p_end}
{synopt:{cmd:e(df_pear)}}degrees of freedom for Pearson chi-squared{p_end}
{synopt:{cmd:e(df_ic)}}degrees of freedom for information criteria{p_end}
{synopt:{cmd:e(ll)}}log likelihood (iterated GLS, balanced, unweighted samples){p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(r2_o)}}R-squared overall{p_end}
{synopt:{cmd:e(r2_w)}}R-squared within{p_end}
{synopt:{cmd:e(r2_b)}}R-squared between{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(tgap)}}1 if the time values of the estimation sample have gaps, 0 otherwise{p_end}
{synopt:{cmd:e(iterations)}}number of iterations in iterated GLS{p_end}
{synopt:{cmd:e(wmean)}}mean of the weights used to normalise them{p_end}
{synopt:{cmd:e(wvary)}}1 if the weights vary within panel, 0 otherwise{p_end}
{synopt:{cmd:e(omega_nfix)}}number of iterations in which the error covariance matrix was repaired{p_end}
{synopt:{cmd:e(omega_mineig)}}smallest eigenvalue of the error covariance matrix before the first repair{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtgls2}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title of the estimation{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(tvar)}}variable denoting time within groups{p_end}
{synopt:{cmd:e(model)}}name of model: {cmd:pgls}, {cmd:regls}, {cmd:fegls} or {cmd:fdgls}{p_end}
{synopt:{cmd:e(igls)}}{cmd:igls} if iterated GLS{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(vce)}}{cmd:cluster} if {cmd:robust} or {cmd:cluster()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtgls2_p}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsprop)}}properties used by {cmd:margins}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance, (sum X_i'inv(Omega_i)X_i)^-1 with {cmd:e(Omega0)}{p_end}
{synopt:{cmd:e(Omega)}}estimated error covariance matrix Omega; for {cmd:fegls} in the original T x T basis (rank T-1){p_end}
{synopt:{cmd:e(Omega0)}}error covariance matrix used in the GLS step, of order {cmd:e(T_o)} (for {cmd:fegls}, in the Helmert basis, full rank){p_end}
{synopt:{cmd:e(tdiff)}}time values of the difference periods ({cmd:fdgls}){p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Acknowledgments}

{pstd}I am grateful to Professor Jeffrey M. Wooldridge for his valuable suggestions on extending the features of this command, in particular the support of unbalanced panels and of {cmd:margins} with {cmd:vce(unconditional)}, which have made it more useful. I also thank the Stata users who tested {cmd:xtgls2} and sent comments, questions and bug reports during its use; their feedback has improved the command considerably.{p_end}


{title:References}

{pstd} Arellano, M. (1987). Computing robust standard errors for within-groups estimators. {it:Oxford Bulletin of Economics & Statistics, 49}(4).

{pstd} Arellano, M., and O. Bover. (1995). Another look at the instrumental variable estimation of error-components models. {it:Journal of Econometrics, 68}(1), 29-51.

{pstd} Kiefer, N. M. (1980). Estimation of fixed effect models for time series of cross-sections with arbitrary intertemporal covariance. {it:Journal of econometrics, 14}(2), 195-202.

{pstd} Korn, E. L., and B. I. Graubard. (1999). {it:Analysis of Health Surveys}. Wiley.

{pstd} Swamy, P. A. V. B., and S. S. Arora. (1972). The exact finite sample properties of the estimators of coefficients in the error components regression models. {it:Econometrica, 40}(2), 261-275.

{pstd} Wooldridge, J. M. (2002). {it:Econometric analysis of cross section and panel data}. The MIT Press.

{pstd} Wooldridge, J. M. (2010). {it:Econometric analysis of cross section and panel data} (2nd ed.). MIT press.

{title:Authors}

    Manh Hoang-Ba, independent researcher, Vietnam
    hbmanh9492@gmail.com

{title:Also see}

{pstd}Online: help for {helpb xtgls}, {helpb xtreg}, {helpb xtivreg}, {helpb margins}, {helpb xttest4} (if installed).

