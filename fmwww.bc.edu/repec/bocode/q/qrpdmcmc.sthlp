{smcl}
{viewerjumpto "Syntax" "qrpdmcmc##syntax"}{...}
{viewerjumpto "Description" "qrpdmcmc##description"}{...}
{viewerjumpto "Examples" "qrpdmcmc##examples"}{...}
{viewerjumpto "Saved results" "qrpdmcmc##results"}{...}
{viewerjumpto "References" "qrpdmcmc##references"}{...}
{cmd:help qrpdmcmc}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{phang}
{cmd:qrpdmcmc} {hline 2} Multi-Chain Adaptive Markov Chain Monte Carlo (MCMC) Estimation and Diagnostics for Quantile Regression for Panel Data with Non-Additive Fixed Effects (Powell, 2022){p_end}
{p2colreset}{...}

{phang}
{it: This command requires the {cmd:moremata} and {cmd:amcmc} packages to run ({stata ssc install moremata}, {stata ssc install amcmc}).}

{marker syntax}{...}
{title:Syntax}

{pstd}
{hi:Estimation mode:}

{p 8 16 2}
{cmd:qrpdmcmc} {it:{help varname:depvar}} {it:{help varname:indepvars}} {ifin} {cmd:,} {it:diagnostics_list} {opt var(varlist)} {opt id(varname)} {opt fix(varname)} [{it:options}]

{pstd}
Use this mode to estimate one or multiple MCMC chains. Specify {opt est} if only estimation is wanted. Otherwise, specify the diagnostics of interest.
The command combines the retained draws across chains and computes any requested diagnostics.
After a successful model estimation, the combined draws are also saved automatically in Stata's temporary directory for later post-estimation use. 
Specify {opt saving()} to save a copy of the combined draws in the working directory.
Unlike {cmd: qregpd}, the command automatically handles singletons.

{pstd}
{hi:Post-Estimation mode:}

{p 8 16 2}
{cmd:qrpdmcmc} {cmd:,} {it:diagnostics_list} {opt var(varlist)} [{it:options}]

{pstd}
After a successful {cmd:qrpdmcmc} model estimation, one can use this mode to run diagnostics on the draws saved in the temporary directory without re-estimating the model.
Post-estimation is available only while the active estimation results still belong to the preceding {cmd:qrpdmcmc} model.
Running another estimation command invalidates this link.
{opt saving()} may also be used in post-estimation mode to save a copy of the draws.

{pstd}
{hi:Saved draws mode:}

{p 8 16 2}
{cmd:qrpdmcmc} {cmd:,} {it:diagnostics_list} {opt var(varlist)} {opt using(filename)} [{it:options}]

{pstd}
Use this mode to load a previously saved MCMC draws dataset and run diagnostics without re-estimation. Stata will search for the draws file in the working directory.
The loaded draws may also be copied to another file with {opt saving()}. The file supplied in {opt using()} is protected against being overwritten by {opt saving()}, even when {opt replace} is specified.

{synoptset 30 tabbed}{...}
{syntab :{it:variables (Estimation mode)}}
{synoptline}
{synopt :{it:{help varname:depvar}}}dependent (outcome) variable{p_end}
{synopt :{it:{help varname:indepvars}}}explanatory variables{p_end}

{syntab :{it:diagnostics}}
{synoptline}
{synopt :{opt stats}}summary statistics for the retained draws, reported by chain and in aggregate{p_end}
{synopt :{opt dens}}marginal density plot{p_end}
{synopt :{opt trace}}trace plot{p_end}
{synopt :{opt avg}}running-average plot{p_end}
{synopt :{opt acf}}Autocorrelation Function (ACF) table and graph{p_end}
{synopt :{opt ess}}Effective Sample Size (ESS) and Monte Carlo Standard Error (MCSE){p_end}
{synopt :{opt gr}}classical Gelman-Rubin R-hat diagnostic table and cumulative R-hat plot; requires at least two chains{p_end}
{synopt :{opt geweke}}Geweke convergence diagnostic table{p_end}
{synopt :{opt ccm}}parameter cross-correlation matrices and graphs; requires at least two variables in {opt var()}{p_end}
{synopt :{opt all}}compute all available diagnostics; if only one variable is supplied in {opt var()}, {opt ccm} is skipped{p_end}
{synopt :{opt est}}perform estimation without generating diagnostics{p_end}

{syntab :{it:diagnostic options}}
{synoptline}
{synopt :{opt var(varlist)}}variables to diagnose; required when a diagnostic is specified but not when only estimation is needed. Specify {cmd:fun_val} to diagnose the objective function{p_end}
{synopt :{opt plot(string)}}graph style for {opt dens}, {opt trace}, and {opt avg}: {opt panel}, {opt overlay}, or {opt both}; default is {opt both}{p_end}
{synopt :{opt lags(#)}}maximum number of lags for ACF calculation; default is 20{p_end}
{synopt :{opt graphs:ave(string)}}save diagnostic graphs as editable {cmd:.gph} files using the supplied string as a filename prefix{p_end}

{pstd}
Chain-specific panel graphs for density, trace, running average, and ACF display at most the first four chains. Numerical diagnostics and overlay graphs continue to use all chains.

{syntab :{it:Estimation mode options}}
{synoptline}
{synopt :{opt id(varname)}}panel identifier; required in estimation mode{p_end}
{synopt :{opt fix(varname)}}fixed-effect/time identifier; required in estimation mode{p_end}
{synopt :{opt q:uantile(#)}}quantile to estimate; default is 0.5{p_end}
{synopt :{opt chains(#)}}number of MCMC chains to run; default is 1{p_end}
{synopt :{opt seeds(numlist)}}one seed for each chain; required when {opt chains()} is greater than 1; for one chain the default seed is 10101{p_end}
{synopt :{opt mcmcopt(string)}}additional MCMC options passed to the qregpd-based estimation routine; also see {help qrpdmcmc##mcmc_options:MCMC options}{p_end}
{synopt :{opt saving(filename)}}save a user-named copy of the combined draws{p_end}
{synopt :{opt replace}}overwrite an existing file specified in {opt saving()}{p_end}
{synopt :{opt chainvar(varname)}}name of the chain identifier in a saved combined-draws file; without {opt saving()}, this option is redundant in estimation mode{p_end}

{marker mcmc_options}{...}
{syntab :{it:MCMC options passed through mcmcopt()}}
{synoptline}
{synopt :{opt instr(varlist)}}exogenous explanatory variables and additional instruments; if omitted, the explanatory variables are treated as exogenous{p_end}
{synopt :{opt draws(#)}}number of MCMC draws per chain; default is 1000{p_end}
{synopt :{opt burn(#)}}number of burn-in draws to discard; default is 0{p_end}
{synopt :{opt arate(#)}}target acceptance rate; must be between 0 and 1; default is 0.234{p_end}
{synopt :{opt thin(#)}}retain every {it:#}th draw to reduce autocorrelation{p_end}
{synopt :{opt sampler(string)}}MCMC drawing scheme; {cmd:global} (default) or {cmd:mwg} (Metropolis-within-Gibbs){p_end}
{synopt :{opt dampparm(#)}}proposal adaptation parameter (0 to 1); default is 1{p_end}
{synopt :{opt from(matrix)}}matrix of initial parameter values excluding the constant; default is based on {cmd:qreg}{p_end}
{synopt :{opt fromvariance(matrix)}}matrix of initial variance excluding the constant; default is based on {cmd:qreg}{p_end}
{synopt :{opt jumble}}randomly mix retained draws to reduce autocorrelation{p_end}
{synopt :{opt noisy}}display detailed underlying estimation output and iteration feedback{p_end}
{synopt :{opt usemax}}report the draw corresponding to the maximum objective function value as the coefficient estimate{p_end}
{synopt :{opt analytic}}request analytic standard errors in the underlying qregpd routine{p_end}

{pstd}
Do not place {opt saving()} inside {opt mcmcopt()}; {cmd:qrpdmcmc} controls saving of chain draws internally.

{syntab :{it:Post-estimation mode options}}
{synoptline}
{synopt :{opt saving(filename)}}save a user-named copy of the combined draws{p_end}
{synopt :{opt replace}}overwrite an existing file specified in {opt saving()}{p_end}

{syntab :{it:Saved draws mode options}}
{synoptline}
{synopt :{opt using(filename)}}load a previously saved MCMC draws dataset; required in saved draws mode{p_end}
{synopt :{opt saving(filename)}}save a copy of the currently loaded draws to another file; may be used with or without a diagnostic{p_end}
{synopt :{opt replace}}overwrite an existing file specified in {opt saving()}{p_end}
{synopt :{opt chainvar(varname)}}numeric variable identifying MCMC chains; default is {cmd:chain}{p_end}
{synopt :{opt timevar(varname)}}numeric variable identifying retained-draw order or iteration; default is {cmd:t}{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:qrpdmcmc} provides multi-chain adaptive Markov Chain Monte Carlo (MCMC) estimation and convergence diagnostics for Quantile Regression for Panel Data with Non-Additive Fixed Effects (Powell, 2022).
The command has three operating modes.
In estimation mode, the command calls a modified version of {help qregpd} and estimates one or multiple MCMC chains, combines the retained draws,
saves the draws automatically in Stata's temporary directory, and computes any requested diagnostics.
After a model estimation, {cmd:qrpdmcmc} reports one pooled coefficient table rather than separate final results for each chain.
In post-estimation mode, the draws from the most recent {cmd:qrpdmcmc} model can be diagnosed.
In saved draws mode, diagnostics can be computed from a previously saved draws dataset without re-estimation.

{pstd}
The available diagnostics are summary statistics, marginal density plots, trace plots, running-average plots, 
autocorrelation functions, Effective Sample Size (ESS) and Monte Carlo Standard Error (MCSE), classical Gelman-Rubin R-hat,
Geweke convergence diagnostics, and parameter cross-correlations.

{marker examples}{...}
{title:Examples}

{hi:Estimation mode:}

{pstd}Setup{p_end}
{phang2}{stata webuse nlswork}{p_end}

{pstd}Single-chain estimation with default MCMC settings{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year)}{p_end}

{pstd}Custom MCMC options: 1,000 draws, 100 burn-in draws, and target acceptance rate of 0.5{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) mcmcopt(draws(1000) burn(100) arate(.5))}{p_end}

{pstd}Show detailed underlying estimation output{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) mcmcopt(noisy draws(1000) burn(100))}{p_end}

{pstd}Endogenous-regressor specification with instruments{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) mcmcopt(draws(1000) burn(100) instr(ttl_exp wks_work union))}{p_end}

{pstd}Two-chain estimation with specified seeds{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) chains(2) seeds(10101 20202)}{p_end}

{pstd}Two-chain estimation with summary statistics and trace plots for tenure{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, id(idcode) fix(year) chains(2) seeds(10101 20202) stats trace var(tenure)}{p_end}

{pstd}Two-chain estimation with diagnostics for multiple variables{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, id(idcode) fix(year) chains(2) seeds(10101 20202) stats trace ess gr var(tenure union)}{p_end}

{pstd}Estimate and save combined draws{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) chains(2) seeds(10101 20202) saving(mydraws) replace}{p_end}

{hi:Post-estimation mode:}

{pstd}Estimate a model once{p_end}
{phang2}{stata webuse nlswork}{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) chains(2) seeds(10101 20202)}{p_end}

{pstd}Estimate summary statistics for tenure{p_end}
{phang2}{stata qrpdmcmc, stats var(tenure)}{p_end}

{pstd}Save the draws in the working directory{p_end}
{phang2}{stata qrpdmcmc, saving(mydraws)}{p_end}

{hi:Saved draws mode:}

{pstd}Create and save a draws file first{p_end}
{phang2}{stata webuse nlswork}{p_end}
{phang2}{stata qrpdmcmc ln_wage tenure union, est id(idcode) fix(year) chains(2) seeds(10101 20202) saving(mydraws) replace}{p_end}

{pstd}Summary statistics for tenure using saved draws{p_end}
{phang2}{stata qrpdmcmc, using(mydraws) stats var(tenure)}{p_end}

{pstd}Density, trace, and running-average panels{p_end}
{phang2}{stata qrpdmcmc, using(mydraws) dens trace avg var(tenure union) plot(panel)}{p_end}

{pstd}{it:The dataset and model specification in these examples follow the {help qregpd##examples:qregpd} help file. When using {help qregpd:qregpd} directly to produce equivalent estimates, specify {help set seed:seed} before estimation.}{p_end}

{marker results}{...}
{title:Saved results}

{pstd}
{cmd:qrpdmcmc} is an e-class command. Results are stored in {cmd:e()} and can be inspected with {cmd:ereturn list}.
Diagnostic matrices are stored only when the corresponding diagnostic is requested.

{synoptset 28 tabbed}{...}
{syntab :{it:common results}}
{synoptline}
{synopt :{cmd:e(cmd)}}{cmd:qrpdmcmc}{p_end}
{synopt :{cmd:e(cmdline)}}command as typed{p_end}
{synopt :{cmd:e(mode)}}{cmd:model} or {cmd:fromfile}; Post-estimation preserves {cmd:model}{p_end}
{synopt :{cmd:e(diagnostics)}}diagnostics requested{p_end}
{synopt :{cmd:e(dvar)}}variables selected in {opt var()}{p_end}
{synopt :{cmd:e(chainvar)}}chain identifier used for the combined draws{p_end}
{synopt :{cmd:e(timevar)}}iteration/order variable used for the combined draws{p_end}
{synopt :{cmd:e(chains)}}chain values found in the draws{p_end}
{synopt :{cmd:e(nchains)}}number of chains{p_end}
{synopt :{cmd:e(N_draws)}}total number of retained draws across all chains{p_end}

{syntab :{it:estimation mode results}}
{synoptline}
{synopt :{cmd:e(b)}}matrix of pooled mean of retained coefficient draws across all chains{p_end}
{synopt :{cmd:e(V)}}covariance matrix of pooled retained coefficient draws{p_end}
{synopt :{cmd:e(N)}}number of observations used in model estimation{p_end}
{synopt :{cmd:e(N_singletons)}}number of singleton observations dropped{p_end}
{synopt :{cmd:e(N_g)}}number of panel groups used in model estimation{p_end}
{synopt :{cmd:e(g_min)}}minimum number of observations per panel group{p_end}
{synopt :{cmd:e(g_max)}}maximum number of observations per panel group{p_end}
{synopt :{cmd:e(g_avg)}}average number of observations per panel group{p_end}
{synopt :{cmd:e(quantile)}}estimated quantile{p_end}
{synopt :{cmd:e(draws)}}number of MCMC draws requested per chain{p_end}
{synopt :{cmd:e(burn)}}number of burn-in draws per chain{p_end}
{synopt :{cmd:e(thin)}}thinning interval{p_end}
{synopt :{cmd:e(depvar)}}dependent variable{p_end}
{synopt :{cmd:e(coefvars)}}estimated coefficient variables{p_end}
{synopt :{cmd:e(instruments)}}instrument variables used in estimation{p_end}
{synopt :{cmd:e(model)}}model specification{p_end}
{synopt :{cmd:e(id)}}panel identifier{p_end}
{synopt :{cmd:e(fix)}}fixed-effect/time identifier{p_end}
{synopt :{cmd:e(seeds)}}seeds used for the MCMC chains{p_end}
{synopt :{cmd:e(saving)}}combined-draws filename when {opt saving()} is specified during estimation or post-estimation{p_end}

{pstd}
In post-estimation mode, the original estimation {cmd:e()} results are preserved rather than replaced.
The post-estimation mode updates {cmd:e(diagnostics)} and {cmd:e(dvar)}, while also storing any newly requested diagnostic matrices.
Because the original estimation identity is retained, {cmd:e(mode)} remains {cmd:model} and {cmd:e(cmdline)} remains the original model-estimation command.

{syntab :{it:saved draws mode results}}
{synoptline}
{synopt :{cmd:e(drawsfile)}}draws file loaded by {opt using()}{p_end}

{syntab :{it:diagnostic results}}
{synoptline}
{synopt :{cmd:e(stats)}}summary-statistics matrix{p_end}
{synopt :{cmd:e(ess)}}ESS and MCSE matrix{p_end}
{synopt :{cmd:e(ess_n_draws)}}variable-by-chain draw counts matrix used by the ESS calculation{p_end}
{synopt :{cmd:e(gr)}}Gelman-Rubin matrix containing R-hat, W, B, N, and number of chains{p_end}
{synopt :{cmd:e(geweke)}}Geweke z-statistics and p-values by chain matrix{p_end}
{synopt :{cmd:e(ccm)}}pooled parameter cross-correlation matrix{p_end}
{synopt :{cmd:e(acf1)}, {cmd:e(acf2)}, ...}ACF matrices, one for each diagnosed variable requested{p_end}
{synopt :{cmd:e(acf_dvar)}}order of diagnosed variables corresponding to the ACF matrices{p_end}
{synopt :{cmd:e(acf_chains)}}chain order corresponding to ACF matrix columns{p_end}
{synopt :{cmd:e(acf_ndvar)}}number of diagnosed variables with stored ACF matrices{p_end}
{synopt :{cmd:e(acf_nchains)}}number of chains represented in the ACF matrices{p_end}

{marker references}{...}
{title:References}

{pstd}
{browse "https://link.springer.com/article/10.1007/s00181-022-02216-6" :Powell, David. 2022.} Quantile regression with nonadditive fixed effects. {it:Empirical Economics} 63, 2675-2691.


{title:Authors}

{psee}Kamilla Kosheeva{p_end}
{psee}Friedrich-Alexander-University Erlangen-Nuremberg (FAU){p_end}
{psee}Professorship of Health Economics{p_end}
{psee}Nuremberg, Germany{p_end}
{psee}E-mail: kamilla.kosheeva@fau.de{p_end}

{psee}Michail Liatos{p_end}
{psee}Friedrich-Alexander-University Erlangen-Nuremberg (FAU){p_end}
{psee}Professorship of Health Economics{p_end}
{psee}Nuremberg, Germany{p_end}
{psee}E-mail: michail.liatos@fau.de{p_end}

{title:Acknowledgements}

{pstd} We gratefully acknowledge comments and suggestions by Harald Tauchmann. 
During the development of this Stata command, 
the authors used Gemini to assist with code syntax and implementation. 
The core conceptualization and structural logic were driven by the authors. 
All AI-assisted code was iteratively tested, modified, and verified by the authors, 
who assume full responsibility for the logic and academic integrity of the command.{p_end} 

{title:Disclaimer}

{pstd}
This software is provided "as is" without warranty of any kind, either expressed or implied. 
The entire risk as to the quality and performance of the program is with you. 
Should the program prove defective, you assume the cost of all necessary servicing, repair, or correction. 
In no event will the copyright holders or their employers, 
or any other party who may modify and/or redistribute this software, 
be liable to you for damages, including any general, special, incidental, 
or consequential damages arising out of the use or inability to use the program.{p_end}

