{smcl}
{* *! version 2.0  29oct2026}{...}
{* *! Manh Hoang-Ba, hbmanh9492@gmail.com}{...}

help for {helpb xtgmmfa}{right:Manh Hoang-Ba (hbmanh9492@gmail, {browse "https://www.youtube.com/@manhb.econometrics":Youtube}, {browse "https://www.facebook.com/ManhHB94/":Facebook}, {browse "https://manhb94econometrics.wordpress.com":Website})}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{bf:xtgmmfa} {hline 2}}GMM estimation of fixed-T factor-augmented panel data models{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:xtgmmfa} {depvar} [{indepvars}] {ifin} [{it:{help weight:weight}}]{cmd:,} {opt gmm:vars(varlist [, gmm_opts])} [{it:options}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtgmmfa} performs two-step GMM estimation of a fixed-T panel data model with a multifactor error structure and endogenous regressors.
The unobserved common factors are approximated by observed factor proxies, so that the moment conditions are linear in the parameters.
See {browse "https://doi.org/10.1080/07350015.2020.1766469":Juodis and Sarafidis (2022)} for more details.


{marker options}{...}
{title:Options}

{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{p2coldent :* {opt gmm:vars(varlist [, gmm_opts])}}GMM-style instruments; can be specified more than once{p_end}
{synopt:{opt iv:vars(varlist)}}IV-style instruments{p_end}
{synopt:{opt unof:actors(Vlist [, unof_opts])}}construction or selection of the factor proxies{p_end}
{synopt:{opt obsf:actors(varlist)}}observed factors with unit-specific loadings{p_end}
{synopt:{opt w:mat(1|2)}}initial weighting matrix; default is {cmd:wmat(2)}{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt rho(#)}}penalty constant of the BIC; default is {cmd:rho(0.75)}{p_end}

{syntab:SE/Robust}
{synopt:{opt r:obust}}Windmeijer-corrected robust standard errors{p_end}
{synopt:{opt cl:uster(varname)}}Windmeijer-corrected cluster-robust standard errors{p_end}
{synopt:{opt small}}small-sample adjustment; t and F statistics{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {cmd:gmmvars()} is required.{p_end}
{p 4 6 2}
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed; see {help xtgmmfa##weights:Weights}.{p_end}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtgmmfa}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}

{pstd}
{opt gmm_opts} are

{synoptset 28 tabbed}{...}
{synopthdr:gmm_opts}
{synoptline}
{synopt:{cmd:lag(}{it:a b}{cmd:)}}use lags {it:a} to {it:b} of the variables; {it:b} = {cmd:.} means all earlier periods; default is {cmd:lag(0 .)}{p_end}
{synopt:{cmd:mlag(}{it:#}{cmd:)}}shorthand for {cmd:lag(0 }{it:#}{cmd:-1)}{p_end}
{synopt:{opt col:lapse}}one moment condition per lag instead of one per lag and period{p_end}
{synopt:{opt pre:sample}}also use values from periods before the first estimation period{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{opt unof_opts} are

{synoptset 28 tabbed}{...}
{synopthdr:unof_opts}
{synoptline}
{synopt:{it:Vlist}}time-varying variables driven by the factors; the dependent variable and the regressors are added after {it:Vlist}; {it:Vlist} may be empty{p_end}
{synopt:{opt noreg:ressor}}do not add the dependent variable and the regressors to {it:Vlist}{p_end}
{synopt:{opt w:var(varname)}}time-invariant variable that defines the weights w_i; default is the first available value of the dependent variable{p_end}
{synopt:{opt ty:pe(1|2|3)}}how {it:Vlist} and the weights are combined; default is {cmd:type(1)}{p_end}
{synopt:{opt p:ower(#)}}power of {cmd:wvar()} used as the single weight by {cmd:type(2)}; default is {cmd:power(0)}{p_end}
{synopt:{opt er}}use the eigenvalue-ratio statistic instead of the growth ratio (default) to estimate the number of factor proxies{p_end}
{synopt:{opt see:d(#)}}seed of the Rademacher mock column used by the ER/GR statistics; default is {cmd:seed(120)}{p_end}
{synopt:{opt le(#)}}fix the number of factor proxies of the regularization method{p_end}
{synopt:{opt bss}}best-subset selection instead of regularization (default){p_end}
{synopt:{opt l:max(#)}}maximum number of factor proxies searched by {cmd:bss}; default is {cmd:lmax(2)}{p_end}
{synoptline}
{p2colreset}{...}


{marker optdesc}{...}
{title:Description of options}

{dlgtab:Model}

{phang}
{opt gmmvars(varlist [, gmm_opts])} specifies the variables that generate the GMM-style instruments. The option may be repeated with different {it:gmm_opts}. Variables are used as typed: to use the first lag of a variable as an instrument, specify {cmd:gmm(L.}{it:var}{cmd:)} or {cmd:gmm(}{it:var}{cmd:, lag(1 .)}. 
For the equation of period t, {cmd:lag(}{it:a b}{cmd:)} uses the values of the variable {it:a} to {it:b} periods before the period t, {it:a} < {it:b} and {it:b} = {cmd:.} uses all earlier periods in the estimation sample. 
By default {cmd:collapse} is off and every lag in every period gives its own moment condition; {cmd:collapse} gives one moment condition per lag. {cmd:presample} allows instruments from periods before the first estimation period.

{phang}
{opt ivvars(varlist)} specifies IV-style instruments, one moment condition per variable, summed over periods (equivalent to {cmd:gmmvars()} with {cmd:lag(0 0) collapse}). The constant is treated in the same way unless {cmd:noconstant} is specified.

{phang}
{opt unofactors(Vlist [, unof_opts])} specifies how the factor proxies are constructed. {it:Vlist} contains time-varying variables that are driven by the factors inside (and possibly outside) the model; 
they are used to construct the vector v_i of equation (11) and the matrix V_i of equation (17) in Juodis and Sarafidis (2022). The dependent variable and the regressors are added after {it:Vlist} unless {cmd:noregressor} is specified,
 so {it:Vlist} can be empty. The proxies are cross-sectional averages of the variables multiplied by the weights w_i, which are powers of the variable in {cmd:wvar()}.

{phang2}
{cmd:type(1)} uses the first variable in {it:Vlist} (after added y, X) and several weights (the powers 0 to T-2 of w_i, where T is the length of the longest panel), {cmd:type(2)} uses all variables in {it:Vlist} and a single weight w_i^{cmd:power()}, and {cmd:type(3)} combines both.

{phang2}
By default the number of factor proxies is estimated (regularization): the proxies are replaced by the principal components of the proxy matrix and their number is chosen by the growth-ratio statistic; 
{cmd:er} uses the eigenvalue-ratio statistic instead. The GR statistic requires at least 3 periods. {cmd:le(#)} fixes the number of proxies. With {cmd:bss} all subsets of the proxies with up to {cmd:lmax(#)} elements are estimated 
and the one with the smallest BIC is selected; the command reports the number of candidates it searches and stores it in {cmd:e(n_cand)}.

{phang}
{opt obsfactors(varlist)} specifies observed common factors (for example macro variables) with unit-specific loadings. Too many observed factors may lead to identification problems.

{phang}
{opt wmat(1|2)} specifies the initial weighting matrix: 1 = identity matrix, 2 = inverse of Z'Z (default).

{phang}
{opt noconstant} suppresses the constant term.

{phang}
{opt rho(#)} sets the constant of the BIC, BIC = J - ln(N)/T^0.3 * rho * df, where df is the degrees of freedom of the J statistic.

{dlgtab:SE/Robust}

{phang}
{opt robust} requests the Windmeijer (2005) finite-sample correction of the two-step standard errors. {opt cluster(varname)} requests cluster-robust standard errors with the same correction; 
the cluster variable must be constant within panel, and observations with a missing cluster value are excluded.

{phang}
{opt small} multiplies the variance matrix by N_obs/(N_obs - r + 1) * G/(G - 1), where r is the rank of the Jacobian and G the number of groups (clusters), 
and reports t and F statistics with G - 1 degrees of freedom (G when {opt noconstant} specified).

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level; the default is {cmd:level(95)}.


{marker weights}{...}
{title:Weights}

{pstd}
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed; {cmd:iweight}s are not. The weight must be constant within panel and must not be negative, frequency weights must be integers, and observations with zero weight are dropped.
{cmd:aweight}s and {cmd:pweight}s are rescaled to sum to the number of units. {cmd:fweight}s are not rescaled, and the sum of the weights is used as the number of units; they are equivalent to replicating the units.

{pstd}
All averages over units (moment conditions, proxies, observed factors, normalisation of unbalanced moments) are weighted. The covariance matrix of the moment conditions uses the squared weights for {cmd:aweight}s and {cmd:pweight}s, 
and the weights themselves for {cmd:fweight}s without {cmd:cluster()}. The weights used are stored in {cmd:e(wt)} when the number of units does not exceed {cmd:c(matsize)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Two-step estimation.} Step 1 uses the weighting matrix of {cmd:wmat()} and its residuals give the covariance matrix of the moment conditions used in step 2. 
The reported J statistic (Hansen) has {cmd:e(j_df)} degrees of freedom, equal to the rank of that covariance matrix minus the rank of the Jacobian.

{pstd}
{bf:Singular covariance matrix.} The covariance matrix of the moment conditions cannot have a rank larger than the number of units (clusters). If its rank is smaller than the number of moment conditions, 
the weighting matrix is not defined, and the coefficients, standard errors and J statistic would be unreliable. {cmd:xtgmmfa} then stops with the message:

{p 8 8 2}{err:- moment covariance matrix is singular (rank r < z moments, g units/clusters)}{p_end}
{p 8 8 2}{err:- 2-step GMM estimates, standard errors and the J test would be unreliable}{p_end}
{p 8 8 2}{err:- too many or dependent instruments; use {bf:lag()}, {bf:collapse} or fewer variables in {bf:gmmvars()}/{bf:ivvars()}}{p_end}

{pstd}
{bf:Collinearity.} Collinear regressors, collinear variables within each {cmd:gmmvars()} group, {cmd:ivvars()} and {cmd:obsfactors()} are dropped with the note of {cmd:_rmcoll}, and collinear variables in {it:Vlist} are dropped silently.

{pstd}
{bf:Units of measurement.} The regularization method uses the principal components of the proxy matrix, so with {cmd:type(2)} and {cmd:type(3)}, where the regressors are added to {it:Vlist}, the result depends on the units of the variables.

{pstd}
{bf:Unbalanced panels.} A moment condition is used for a unit only if all its components are observed, and it is averaged over the units that have it.


{marker examples}{...}
{title:Examples}

{pstd}Water data (Juodis and Sarafidis, 2022){p_end}
{phang2}. {stata use js22data, clear}{p_end}
{phang2}. {stata xtset id year}{p_end}

{pstd}Regularization: column M_F of table 1{p_end}
{phang2}. {stata xtgmmfa l(0/1).lcons price rain temp, gmm(l.lcons l.price rain temp) unof(smi, type(1) er) nocons wmat(1)}{p_end}

{pstd}Best-subset selection: column M1_y0 of table 1{p_end}
{phang2}. {stata xtgmmfa l(0/1).lcons price rain temp, gmm(l.lcons l.price rain temp) unof(smi, bss type(1) lmax(2)) nocons wmat(1)}{p_end}

{pstd}Arellano-Bond data{p_end}
{phang2}. {stata webuse abdata, clear}{p_end}

{pstd}Windmeijer-corrected robust standard errors{p_end}
{phang2}. {stata xtgmmfa l(0/1).n k w ys, gmm(l.n l.k) iv(w ys) r}{p_end}

{pstd}Frequency weights constant within firm{p_end}
{phang2}. {stata gen byte ones = 1}{p_end}
{phang2}. {stata xtgmmfa l(0/1).n k w ys [pw=ones], gmm(l.n l.k) iv(w ys) r}{p_end}

{pstd}With all lags of four variables there are more moment conditions than units; the command stops with an error message{p_end}
{phang2}. {stata xtgmmfa l(0/1).n k w ys, gmm(l.n l.k l.w l.ys)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtgmmfa} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (sum of weights with {cmd:fweight}){p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(Tmin)}}smallest group size{p_end}
{synopt:{cmd:e(Tbar)}}average group size{p_end}
{synopt:{cmd:e(Tmax)}}largest group size (longest panel){p_end}
{synopt:{cmd:e(Teq)}}number of periods of the factor proxy matrix{p_end}
{synopt:{cmd:e(k)}}number of regressors, including the constant{p_end}
{synopt:{cmd:e(r_ga)}}rank of the Jacobian (number of estimated coefficients){p_end}
{synopt:{cmd:e(n_par)}}number of coefficients before the rank reduction{p_end}
{synopt:{cmd:e(j)}}number of moment conditions{p_end}
{synopt:{cmd:e(d)}}number of nuisance parameters per factor proxy{p_end}
{synopt:{cmd:e(rank_D)}}rank of the covariance matrix of the moment conditions{p_end}
{synopt:{cmd:e(j_s)}}Hansen J statistic{p_end}
{synopt:{cmd:e(j_p)}}p-value of the J statistic{p_end}
{synopt:{cmd:e(j_df)}}degrees of freedom of the J statistic{p_end}
{synopt:{cmd:e(Le)}}number of estimated or selected factor proxies{p_end}
{synopt:{cmd:e(bic)}}BIC{p_end}
{synopt:{cmd:e(type)}}type of construction of the factor proxies{p_end}
{synopt:{cmd:e(n_cand)}}number of candidate sets searched (only with {cmd:bss}){p_end}
{synopt:{cmd:e(G)}}number of groups or clusters used in the small-sample adjustment{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (with {cmd:robust} or {cmd:cluster()}){p_end}
{synopt:{cmd:e(sum_w)}}sum of the weights (number of units without weights){p_end}
{synopt:{cmd:e(chi2)}}chi2 statistic for all coefficients except the constant (regressors and nuisance parameters){p_end}
{synopt:{cmd:e(df_m)}}degrees of freedom of {cmd:e(chi2)} (rank of the tested covariance block){p_end}
{synopt:{cmd:e(chi2_p)}}p-value of {cmd:e(chi2)}{p_end}
{synopt:{cmd:e(chi2_b)}}chi2 statistic for the regressors only, constant excluded{p_end}
{synopt:{cmd:e(df_b_m)}}degrees of freedom of {cmd:e(chi2_b)}{p_end}
{synopt:{cmd:e(chi2_b_p)}}p-value of {cmd:e(chi2_b)}{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom (with {cmd:small}){p_end}
{synopt:{cmd:e(F)}}F statistic (with {cmd:small}){p_end}
{synopt:{cmd:e(F_p)}}p-value of cmd:e(F)} (with {cmd:small}){p_end}
{synopt:{cmd:e(F_b)}}F statistic for the regressors only (with {cmd:small}){p_end}
{synopt:{cmd:e(F_b_p)}}p-value of {cmd:e(F_b)} (with {cmd:small}){p_end}
{synopt:{cmd:e(v_bad)}}1 if a coefficient variance is missing or not positive{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtgmmfa}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(method)}}Regularization or Best-Subset Selection (BSS){p_end}
{synopt:{cmd:e(stat_note)}}how the number of factor proxies was obtained{p_end}
{synopt:{cmd:e(gmmstep)}}{cmd:twostep}{p_end}
{synopt:{cmd:e(overid)}}{cmd:Hansen}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:WC-Robust} with {cmd:robust} or {cmd:cluster()}{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(small)}}{cmd:small} if specified{p_end}
{synopt:{cmd:e(constant)}}{cmd:hasconstant} or {cmd:noconstant}{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the regressors{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the regressors{p_end}
{synopt:{cmd:e(theta)}}coefficient vector including the nuisance parameters{p_end}
{synopt:{cmd:e(Vtheta)}}variance-covariance matrix including the nuisance parameters{p_end}
{synopt:{cmd:e(spec)}}instrument specification: variable index, lower lag, upper lag, collapse, presample{p_end}
{synopt:{cmd:e(Fe_hat)}}factor proxies{p_end}
{synopt:{cmd:e(wt)}}weights of the units{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker update}{...}
{title:Version updates}

{pstd}To update the {cmd:xtgmmfa} package to the latest version, run either of the following commands{p_end}
{phang2}. {stata `"ssc install xtgmmfa, replace"'}{p_end}
{phang2}. {stata `"ado apdate xtgmmfa, apdate"'}{p_end}
{phang2}. {stata `"net install xtgmmfa, from("https://raw.githubusercontent.com/ManhHB94/xtgmmfa/main/") replace"'}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Manh Hoang-Ba, {browse "https://manhb94econometrics.wordpress.com/"}

{pstd}
hbmanh9492@gmail.com


{title:Acknowledgement}

{pstd}
I would like to express my sincere gratitude to Arturas Juodis and Vasilis Sarafidis, who developed the linear GMM approach for this class of models. The implementation of {cmd:xtgmmfa} benefited substantially from the MATLAB code provided with their research.


{marker references}{...}
{title:References}

{phang}
Juodis, A., and V. Sarafidis. 2022. A linear estimator for factor-augmented fixed-T panels with endogenous regressors. {it:Journal of Business & Economic Statistics} 40(1): 1-15.

{phang}
Roodman, D. 2009. How to do xtabond2: An introduction to difference and system GMM in Stata. {it:Stata Journal} 9(1): 86-136.

{phang}
Windmeijer, F. 2005. A finite sample correction for the variance of linear efficient two-step GMM estimators. {it:Journal of Econometrics} 126: 25-51.

{title:Also see}

{phang}
{help xtset}, {help xtdpd}, {help xtabond2} (if installed), {help xtdpdgmm} (if installed)

