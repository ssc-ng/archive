*****************************************************************************************
**** Multi-Chain Adaptive Markov Chain Monte Carlo (MCMC) Estimation and Diagnostics ****
******** for Quantile Regression for Panel Data with Non-Additive Fixed Effects *********
*****************************************************************************************
*! version 1.0 2026-09-28
*! authors Kamilla Kosheeva & Michail Liatos
*! Multi-Chain Adaptive Markov Chain Monte Carlo (MCMC) Estimation and Diagnostics for Quantile Regression for Panel Data with Non-Additive Fixed Effects

capture program drop qrpdmcmc
program define qrpdmcmc, eclass
    version 15.1
    
    local missing_packages ""

    capture findfile lmoremata.mlib
    if _rc {
        local missing_packages "`missing_packages' moremata"
    }

    capture findfile lamcmc.mlib
    if _rc {
        local missing_packages "`missing_packages' amcmc"
    }

    if "`missing_packages'" != "" {

        di as error ""
        di as error "{bf:qrpdmcmc requires the following SSC package(s):}"
        di as error ""

        foreach pkg of local missing_packages {
            di as error "    - `pkg'"
        }

        di as error ""
        di as error "Install the missing package(s) with:"

        foreach pkg of local missing_packages {
            di as error "    ssc install `pkg'"
        }

        di as error ""
        exit 199
    }

    local qrpdd_cmdline `"qrpdmcmc `0'"'   
	
    if ustrregexm(`"`0'"', "\busing\(") | ustrregexm(`"`0'"', "^ *(if|in)\b") {
        if ustrregexm(`"`0'"', "\b(if|in)\b") {
            di as error "if/in qualifiers are not allowed in post-estimation and saved draws modes."
            di as error "To filter draws, load the draws dataset directly, drop observations, and run qrpdmcmc."
            exit 198
        }
    }

    syntax [anything(name=model id="model specification")] [if] [in], ///
        [ ///
          USING(string) ///
          STATS ///
          DENS ///
          TRACE ///
          AVG ///
          ACF ///
          ESS ///
          GR ///
          GEWEKE ///
          CCM ///
          ALL ///
          EST ///
          VAR(string) ///
          ID(name) ///
          FIX(name) ///
          Quantile(numlist max=1) ///
          CHAINS(numlist integer max=1 >0) ///
          SEEDS(numlist integer) ///
          mcmcopt(string asis) ///
          SAVING(string) ///
          REPLACE ///
          CHAINvar(name) ///
          TIMEvar(name) ///
          PLOT(string) ///
          LAGS(numlist integer max=1 >0) ///
          GRAPHSave(string) ///
        ]
       
            local chains_specified    = ("`chains'" != "")
            local seeds_specified     = ("`seeds'" != "")
            local mcmcopt_specified   = (`"`mcmcopt'"' != "")
            local quantile_specified  = ("`quantile'" != "")
            local saving_specified    = (`"`saving'"' != "")
            local replace_specified   = ("`replace'" != "")
            local chainvar_specified  = ("`chainvar'" != "")
            local timevar_specified   = ("`timevar'" != "")
            local lags_specified = ("`lags'" != "")
            local plot_specified = ("`plot'" != "")
            local id_specified  = ("`id'" != "")
            local fix_specified = ("`fix'" != "")
            
        if "`chains'" == "" {
            local chains 1
        }

        if "`quantile'" == "" {
            local quantile 0.5
        }
		
		if `quantile' <= 0 {
            di as error "Invalid quantile: `quantile'. Value must be strictly greater than 0."
            exit 198
        }
        else if `quantile' >= 100 {
            di as error "Invalid quantile: `quantile'. Specify a fraction (0 < q < 1) or a percentage (1 <= q < 100)."
            exit 198
        }

        if "`lags'" == "" {
            local lags 20
        }

    if "`all'" != "" {
        local stats stats
        local dens  dens
        local trace trace
        local avg   avg
        local acf   acf
        local ess   ess
        local gr    gr
        local geweke    geweke
        local ccm    ccm
    }
    
    if "`ccm'" != "" {
        local nvars : word count `var'
        if `nvars' < 2 {
            if "`all'" != "" {
                di as text "Note: ccm is ignored because at least two variables are required for cross-correlations."
                local ccm ""
            }
            else {
                di as error "The ccm option requires at least two variables in var(). Example: var(var1 var2)"
                exit 198
            }
        }
    }
    
    if `lags_specified' & "`acf'" == "" {
        di as text "Note: lags() is ignored because the ACF diagnostic was not requested."
    }
    
if `"`graphsave'"' != "" & "`dens'`trace'`avg'`acf'`gr'`ccm'" == "" {
    di as text "Note: graphsave() is ignored because no graphical diagnostic was requested."
}

local graphsave_opt ""

if `"`graphsave'"' != "" {
    local graphsave_opt `"graphsave(`graphsave')"'
}

    if "`dens'`trace'`avg'`acf'`ess'`gr'`geweke'`stats'`est'`ccm'" == "" {

        if `"`saving'"' == "" | `"`model'"' != "" {

            di as error ///
                "No diagnostic, estimation, or saving action requested."

            di as error ///
                "Specify a diagnostic, est, or saving()."

            exit 198
        }
    }
    

    if "`chainvar'" == "" {
        local chainvar chain
    }

    if "`timevar'" == "" {
        local timevar t
    }

if "`plot'" == "" {
    local plot both
}

local plot = lower("`plot'")

if `plot_specified' & "`dens'`trace'`avg'" == "" {
    di as text "Note: plot() is ignored because none of the requested diagnostics use this option."
}

if "`dens'`trace'`avg'" != "" {
    if !inlist("`plot'", "panel", "overlay", "both") {
        di as error "plot() must be one of: panel, overlay, both."
        exit 198
    }
}

    if "`var'" == "" {
        if "`trace'" != "" | "`avg'" != "" | "`acf'" != "" | "`ess'" != "" | "`dens'" != "" | "`gr'" != "" | "`geweke'" != "" | "`stats'" != "" | "`ccm'" != "" {
            di as error "For diagnostics, specify var()."
            di as error "Example: qrpdmcmc, using(allchains.dta) gr var(var1)"
            exit 198
        }
    }


    if "`var'" != "" & "`stats'`trace'`avg'`acf'`ess'`dens'`gr'`geweke'`ccm'" == "" {
        di as text "Note: var() option is ignored for estimation."
    }

    if `lags' < 1 {
        di as error "lags() must be at least 1."
        exit 198
    }
    
   
    if "`est'" != "" & `"`using'"' != "" {
        di as error "The est option is for model estimation and cannot be used with using()."
        exit 198
    }

    if `"`model'"' != "" & `"`using'"' != "" {
        di as error "Specify either a model or using(), not both."
        di as error "Use the estimation mode to estimate new chains, or using() to diagnose existing draws."
        exit 198
    }

	local qrpdd_mode ""

	if `"`model'"' != "" {
		local qrpdd_mode "model"
	}

	else if `"`using'"' != "" {
		local qrpdd_mode "fromfile"
	}

else {

    if "`est'" != "" {
        di as error "The est option requires a model specification."
        exit 198
    }

    if `"`e(cmd)'"' != "qrpdmcmc" | `"`e(mode)'"' != "model" {
        di as error "No previous qrpdmcmc model estimation found."
        di as error "Estimate a model first, or use using()."
        exit 301
    }

    if `"`e(chainvar)'"' != "" {
        local chainvar `"`e(chainvar)'"'
    }

    if `"`e(timevar)'"' != "" {
        local timevar `"`e(timevar)'"'
    }

    local qrpdd_postfile `"`e(cachefile)'"'

    if `"`qrpdd_postfile'"' == "" {
        di as error "Postestimation MCMC draws for the previous qrpdmcmc model could not be found."
        exit 601
    }

    capture confirm file `"`qrpdd_postfile'"'

    if _rc {
        di as error "Postestimation MCMC draws for the previous qrpdmcmc model could not be found."
        exit 601
    }

    local qrpdd_mode "postestimation"
}
        
    if "`qrpdd_mode'" == "postestimation" ///
        & `replace_specified' ///
        & !`saving_specified' {

        di as text ///
            "Note: In PostEstimation mode, replace is ignored without saving()."
    }
    
    if `"`using'"' != "" {

        local ignored_draws ""

        if `id_specified'       local ignored_draws "`ignored_draws' id()"
        
        if `fix_specified'      local ignored_draws "`ignored_draws' fix()"

        if `chains_specified' {
            local ignored_draws "`ignored_draws' chains()"
        }

        if `seeds_specified' {
            local ignored_draws "`ignored_draws' seeds()"
        }

        if `mcmcopt_specified' {
            local ignored_draws "`ignored_draws' mcmcopt()"
        }

        if `quantile_specified' {
            local ignored_draws "`ignored_draws' quantile()"
        }

        if `replace_specified' & !`saving_specified' {
            local ignored_draws "`ignored_draws' replace"
        }

        if `"`ignored_draws'"' != "" {
            di as text ///
                "Note: In saved draws mode, the following option(s) are ignored:`ignored_draws'"
        }
    }

else if `"`model'"' != "" {

    if `timevar_specified' {
        di as text "Note: In estimation mode, timevar() is ignored; the iteration variable is t."
        local timevar t
    }

    if `chainvar_specified' & !`saving_specified' {
        di as text "Note: Without saving(), chainvar() is redundant and ignored."
        local chainvar chain
    }
}
  
preserve

if "`qrpdd_mode'" == "fromfile" {

    local drawfile `"`using'"'

    capture confirm file `"`drawfile'"'

    if _rc {
        capture confirm file `"`drawfile'.dta"'

        if !_rc {
            local drawfile `"`drawfile'.dta"'
        }
        else {
            di as error "Draws file not found: `drawfile'"
            restore
            exit 601
        }
    }

    quietly use `"`drawfile'"', clear
}

else if "`qrpdd_mode'" == "postestimation" {

    quietly use `"`qrpdd_postfile'"', clear
}

else {

        if "`id'" == "" {
            di as error "You must specify a panel identifier. Please use the option id()."
            restore
            exit 198
        }

        if "`fix'" == "" {
            di as error "You must specify a time identifier. Please use the option fix()."
            restore
            exit 198
        }
        
        if "`gr'" != "" & `chains' < 2 {
            di as error "Minimum 2 chains are required to calculate Gelman-Rubin."
            restore
            exit 198
        }

        if "`seeds'" == "" {
            if `chains' == 1 {
                local seeds 10101
            }
            else {
                di as error "For chains() other than 1, please specify seeds()."
                di as error "Example: seeds(10101 20202 30303 40404)"
                restore
                exit 198
            }
        }

        local nseeds : word count `seeds'

        if `nseeds' != `chains' {
            di as error "Number of seeds must equal number of chains. You specified chains(`chains') but provided `nseeds' seed(s)."
            restore
            exit 198
        }

		if `"`mcmcopt'"' != "" {
            capture _qrpdd_validate_mcmcopt , `mcmcopt'
            if _rc {
                di as error "Invalid option(s) specified in mcmcopt()."
                di as error "Only the specific MCMC options documented in {help qrpdmcmc} are allowed."
                restore
                exit 198
            }
        }
		
		if ustrregexm(`"`qrpdd_cmdline'"', "(?i)\bsaving\([ \t]*\)") {
            di as error "You must specify a valid filename inside saving()."
            restore
            exit 198
        }
		
        local main_replace "`replace'"
        
        if `"`saving'"' != "" {
            local 0 `"`saving'"'
            syntax anything(name=savefile) [, REPLACE]
            
            // Combine both replace checks
            if "`main_replace'" != "" {
                local replace "replace"
            }
            
            if !strmatch(`"`savefile'"', "*.dta*") {
                local savefile `"`savefile'.dta"'
            }
            
            if "`replace'" == "" {
                capture confirm new file `"`savefile'"'
                if _rc {
                    di as error "file `savefile' already exists"
                    restore
                    exit 602
                }
            }
        }

        if !strpos(lower(`"`mcmcopt'"'), "optimize(") {
            local mcmcopt `"`mcmcopt' optimize(mcmc)"'
        }
        
        local inst_vars ""
        if ustrregexm(`"`mcmcopt'"', "(?i)\binst[a-z]*\(([^)]+)\)") {
            local inst_vars = ustrregexs(1)
        }

        if "`inst_vars'" != "" {
            gettoken temp_dep temp_indep : model
            local n_indep : word count `temp_indep'
            local n_inst  : word count `inst_vars'
            
            if `n_inst' < `n_indep' {
                di as error "Number of instruments cannot be smaller than the number of variables specified in the model."
                restore
                exit 198
            }
        }

        tempvar panel_nobs qrpdd_touse
        mark `qrpdd_touse' `if' `in'
        markout `qrpdd_touse' `model' `id' `fix'
        if "`inst_vars'" != "" {
            capture markout `qrpdd_touse' `inst_vars'
        }

        quietly keep if `qrpdd_touse'
		
		quietly count
        if r(N) == 0 {
            di as error "no observations."
            restore
            exit 2000
        }

        quietly bysort `id': egen long `panel_nobs' = count(`id')
        quietly count if `panel_nobs' == 1
        local qrpdd_N_singletons = r(N)

        if `qrpdd_N_singletons' > 0 {
            quietly drop if `panel_nobs' == 1
            di as text "Note: `qrpdd_N_singletons' singleton observation(s) dropped."
            di as text ""
        }

        quietly count
        if r(N) == 0 {
            di as error "No observations remain after dropping singletons."
            restore
            exit 2000
        }

        tempfile original_data
        quietly save `original_data', replace

        local append_files ""

        forvalues c = 1/`chains' {
            
            local thisseed : word `c' of `seeds'

            quietly use `original_data', clear
            set seed `thisseed'

            tempfile rawdraws`c'
            tempfile chaindraws`c'

            local rawfile `"`rawdraws`c''"'
            
di as text "Running MCMC chain `c' of `chains' (seed `thisseed')..."

local qregpd_prefix "quietly"

if strpos(lower(`"`mcmcopt'"'), "noisy") {
    local qregpd_prefix "noisily"
}

capture `qregpd_prefix' qregpd2 `model' `if' `in', ///
    id(`id') ///
    fix(`fix') ///
    quantile(`quantile') ///
    `mcmcopt' ///
    saving(`"`rawfile'"') ///
    replace

local qregpd_rc = _rc

if `qregpd_rc' {
    di as error "qregpd2 failed in chain `c' with return code `qregpd_rc'."
    restore
    exit `qregpd_rc'
}

local this_N_singletons = e(N_singletons)

di as text "Chain `c' completed."
di as text ""

local this_N     = e(N)
local this_N_g   = e(N_g)
local this_g_min = e(g_min)
local this_g_max = e(g_max)

local this_draws = e(draws)
local this_burn  = e(burn)
local this_thin  = e(thin)

local this_instruments `"`e(instruments)'"'


if `c' == 1 {
    local qrpdd_N = `this_N'
    local qrpdd_instruments `"`this_instruments'"'
    local qrpdd_N_g   = `this_N_g'
    local qrpdd_g_min = `this_g_min'
    local qrpdd_g_max = `this_g_max'
    local qrpdd_draws = `this_draws'
    local qrpdd_burn  = `this_burn'
    local qrpdd_thin  = `this_thin'
    local qrpdd_N_singletons = `this_N_singletons'  
}

else {

    if `this_N' != `qrpdd_N' {
        di as error "The estimation sample size differs across chains."
        restore
        exit 498
    }
    
    if `this_N_g' != `qrpdd_N_g' | ///
   `this_g_min' != `qrpdd_g_min' | ///
   `this_g_max' != `qrpdd_g_max' {

    di as error "Panel sample structure differs across chains."
    restore
    exit 498
}

    if `this_draws' != `qrpdd_draws' | ///
       `this_burn'  != `qrpdd_burn'  | ///
       `this_thin'  != `qrpdd_thin' {

        di as error "MCMC draw settings differ across chains."
        restore
        exit 498
    }

    if `"`this_instruments'"' != `"`qrpdd_instruments'"' {
        di as error "The instrument specification differs across chains."
        restore
        exit 498
    }
    
}


            local savedfile `"`e(saving)'"'

            if `"`savedfile'"' == "" {
                local savedfile `"`rawfile'"'
            }

            capture confirm file `"`savedfile'"'
            if _rc {
                capture confirm file `"`savedfile'.dta"'
                if !_rc {
                    local savedfile `"`savedfile'.dta"'
                }
                else {
                    di as error "Could not find saved MCMC draws for chain `c'."
                    restore
                    exit 601
                }
            }

            quietly use `"`savedfile'"', clear

            capture confirm variable `chainvar'
            if !_rc {
                drop `chainvar'
            }

            gen int `chainvar' = `c'
            label variable `chainvar' "MCMC chain"

            capture confirm variable `timevar'
            if _rc {
                gen long `timevar' = _n
                label variable `timevar' "MCMC iteration"
            }
            else {
                capture isid `timevar'
                if _rc {
                    di as text "Existing `timevar' is not unique within chain `c'; replacing it with observation number."
                    drop `timevar'
                    gen long `timevar' = _n
                    label variable `timevar' "MCMC iteration"
                }
            }

            gen long _qrpdd_seed = `thisseed'
            label variable _qrpdd_seed "Seed used for this chain"

            quietly save `chaindraws`c'', replace

            local append_files `append_files' `chaindraws`c''
        }

        local firstfile : word 1 of `append_files'

        quietly use `firstfile', clear

        forvalues c = 2/`chains' {
            local nextfile : word `c' of `append_files'
            quietly append using `nextfile'
        }

        local qrpdd_cache_index = 1
        local qrpdd_cache_saved = 0

        while !`qrpdd_cache_saved' {

            local qrpdd_postfile ///
                `"`c(tmpdir)'/qrpdmcmc_postest_`qrpdd_cache_index'.dta"'

            capture quietly save `"`qrpdd_postfile'"'
            local qrpdd_cache_rc = _rc

            if `qrpdd_cache_rc' == 0 {
                local qrpdd_cache_saved = 1
            }
            else if `qrpdd_cache_rc' == 602 {
                local ++qrpdd_cache_index
            }
            else {
                di as error "Could not save postestimation MCMC draws."
                restore
                exit `qrpdd_cache_rc'
            }
        }

        if `"`saving'"' != "" {
            if "`replace'" != "" {
                quietly save `"`saving'"', replace
            }
            else {
                quietly save `"`saving'"'
            }

            di ""
            di as result "Combined MCMC draws saved to the current working directory as: `saving'"
        }
    }

    if inlist("`qrpdd_mode'", "fromfile", "postestimation") ///
        & `"`saving'"' != "" {

        if "`qrpdd_mode'" == "fromfile" {
            local qrpdd_sourcefile `"`drawfile'"'
        }
        else {
            local qrpdd_sourcefile `"`qrpdd_postfile'"'
        }

        local qrpdd_samefile 0

        if `"`saving'"' == `"`qrpdd_sourcefile'"' {
            local qrpdd_samefile 1
        }

        if `"`saving'.dta"' == `"`qrpdd_sourcefile'"' {
            local qrpdd_samefile 1
        }

        if `qrpdd_samefile' {

            di as error ///
                "In saved draws mode, saving() cannot overwrite the file currently being used."

            restore
            exit 198
        }

        if "`replace'" != "" {
            quietly save `"`saving'"', replace
        }
        else {
            quietly save `"`saving'"'
        }

        di ""
di as result ///
    `"MCMC draws saved as: `saving'"'
    }

    capture confirm variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' not found."
        restore
        exit 111
    }

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must be numeric."
        restore
        exit 109
    }

    capture confirm variable `timevar'
    if _rc {
        bysort `chainvar': gen long `timevar' = _n
        label variable `timevar' "MCMC iteration"
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must be numeric."
        restore
        exit 109
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        di as error "Check for duplicate chain-iteration pairs."
        restore
        exit 459
    }

    quietly tsset `chainvar' `timevar'

    quietly levelsof `chainvar', local(total_chains)
    local num_chains : word count `total_chains'
    if "`gr'" != "" & `num_chains' < 2 {
        di as error "Minimum 2 chains are required to calculate Gelman-Rubin."
        restore
        exit 198
    }
    if `num_chains' == 1 {
        local plot panel
    }
    
local warn_graphlimit 0

if "`acf'" != "" {
    local warn_graphlimit 1
}

if inlist("`plot'", "panel", "both") & "`dens'`trace'`avg'" != "" {
    local warn_graphlimit 1
}

if `num_chains' > 4 & `warn_graphlimit' {

    local graph_chains ""
    local n_graph_chains 0

    foreach c of local total_chains {
        if `n_graph_chains' < 4 {
            local graph_chains `graph_chains' `c'
            local ++n_graph_chains
        }
    }
    
    di as text ""
    di as text "Note: Chain-specific graphs are displayed only for the first 4 chains."
    if "`acf'" != "" | "`gr'" != "" {
        di as text "Numerical diagnostics continue to use all `num_chains' chains."
    }
}
    
    tempname chain_lbl
    quietly levelsof `chainvar', local(lbl_chains)
    foreach c of local lbl_chains {
        local box_text "Chain `c'"
        capture confirm variable _qrpdd_seed
        if !_rc {
            quietly summarize _qrpdd_seed if `chainvar' == `c', meanonly
            if r(N) > 0 & !missing(r(mean)) {
                local s = r(mean)
                local box_text "Seed: `s'"
            }
        }
        label define `chain_lbl' `c' "`box_text'", modify
    }

    
    label values `chainvar' `chain_lbl' 

local diagnostics ""

foreach d in stats dens trace avg acf ess gr geweke ccm {
    if "``d''" != "" {
        local diagnostics "`diagnostics' `d'"
    }
}

if "`est'" != "" {
    local diagnostics "`diagnostics' est"
}

local diagnostics : list retokenize diagnostics

if "`qrpdd_mode'" == "model" {

    gettoken qrpdd_depvar qrpdd_coefvars : model

    local qrpdd_depvar   : list retokenize qrpdd_depvar
    local qrpdd_coefvars : list retokenize qrpdd_coefvars

    if `"`qrpdd_coefvars'"' == "" {
        di as error "No coefficient variables found in the model specification."
        restore
        exit 198
    }

    foreach p of local qrpdd_coefvars {

        capture confirm numeric variable `p'

        if _rc {
            di as error "Coefficient draws for `p' were not found in the combined MCMC draws."
            restore
            exit 111
        }

        quietly count if missing(`p')

        if r(N) > 0 {
            di as error "Coefficient `p' contains missing retained MCMC draws."
            restore
            exit 498
        }
    }

    tempname QRPDD_B QRPDD_V

    local k : word count `qrpdd_coefvars'

    matrix `QRPDD_B' = J(1, `k', .)

    local j 1

    foreach p of local qrpdd_coefvars {

        quietly summarize `p', meanonly

        matrix `QRPDD_B'[1,`j'] = r(mean)

        local ++j
    }

    matrix colnames `QRPDD_B' = `qrpdd_coefvars'

    if `k' == 1 {

        quietly summarize `qrpdd_coefvars'

        matrix `QRPDD_V' = r(Var)
    }
    else {

        quietly correlate `qrpdd_coefvars', covariance

        matrix `QRPDD_V' = r(C)
    }

    matrix colnames `QRPDD_V' = `qrpdd_coefvars'
    matrix rownames `QRPDD_V' = `qrpdd_coefvars'

    quietly count
    local qrpdd_N_draws = r(N)

    ereturn clear

    ereturn post `QRPDD_B' `QRPDD_V', ///
        obs(`qrpdd_N') ///
        depname(`qrpdd_depvar')
}

if "`qrpdd_mode'" == "fromfile" {

    quietly count
    local qrpdd_N_draws = r(N)

    ereturn clear
}

else if "`qrpdd_mode'" == "postestimation" {

    quietly count
    local qrpdd_N_draws = r(N)

}

if "`qrpdd_mode'" != "postestimation" {

    ereturn local cmd         "qrpdmcmc"
    ereturn local cmdline     `"`qrpdd_cmdline'"'
    ereturn local mode        "`qrpdd_mode'"
    ereturn local diagnostics "`diagnostics'"
    ereturn local dvar        "`var'"
    ereturn local chainvar    "`chainvar'"
    ereturn local timevar     "`timevar'"
    ereturn local chains      "`total_chains'"

    ereturn scalar nchains = `num_chains'
    ereturn scalar N_draws = `qrpdd_N_draws'

    if "`qrpdd_mode'" == "model" {
    
        ereturn scalar N_singletons = `qrpdd_N_singletons'
        ereturn scalar N_g   = `qrpdd_N_g'
        ereturn scalar g_min = `qrpdd_g_min'
        ereturn scalar g_max = `qrpdd_g_max'
        ereturn scalar g_avg = round(`qrpdd_N' / `qrpdd_N_g', 0.1)
        ereturn scalar draws = `qrpdd_draws'
        ereturn scalar burn  = `qrpdd_burn'
        ereturn scalar thin  = `qrpdd_thin'
        ereturn scalar quantile = `quantile'
        ereturn local seeds       "`seeds'"
        ereturn local model       `"`model'"'
        ereturn local depvar      "`qrpdd_depvar'"
        ereturn local coefvars    "`qrpdd_coefvars'"
        ereturn local instruments `"`qrpdd_instruments'"'
        ereturn local id          "`id'"
        ereturn local fix         "`fix'"

        ereturn hidden local cachefile `"`qrpdd_postfile'"'

        if `"`saving'"' != "" {
            ereturn local saving `"`saving'"'
        }
    }

    else if "`qrpdd_mode'" == "fromfile" {

        ereturn local drawsfile `"`drawfile'"'
    }
}

else {

    ereturn local diagnostics "`diagnostics'"
    ereturn local dvar        "`var'"
}

if "`qrpdd_mode'" == "model" {
    
    di ""
    di as text "{bf:Quantile Regression for Panel Data}" ///
       _col(49) as text "Number of obs        = " as result %7.0f e(N)
    di as text "{bf:with Non-additive Fixed Effects:}" ///
       _col(49) as text "Number of groups     = " as result %7.0f e(N_g)
    di as text "{bf:Adaptive MCMC Estimation and Diagnostics}" ///
       _col(49) as text "Min obs per group    = " as result %7.0f e(g_min)
    di _col(49) as text "Avg obs per group    = " as result %7.1f (e(N) / e(N_g))
    di _col(49) as text "Max obs per group    = " as result %7.0f e(g_max)

    ereturn display
    di as text "Note: Estimates are based on pooled retained MCMC draws across chains;" 
    di as text "      use {bf:stats} or/and the MCMC option {bf:noisy} for chain-specific results."
    di ""
    
    local value_col 20

	if e(quantile) < 1 {
		local qfmt "%-9.2f"
	}
	else {
		local qfmt "%-9.4g"
	}

    di as text "Quantile:" ///
	_col(`value_col') as result `qfmt' e(quantile)

    di as text "Chains:" ///
    _col(`value_col') as result %-5.0f e(nchains) ///
    as text "  (Seed(s): " as result "`e(seeds)'" as text ")"

    di as text "Draws per chain:" ///
    _col(`value_col') as result %-6.0f e(draws) ///
    as text " (Burn-in: " as result e(burn) ///
    as text ", Thin: " as result e(thin) as text ")"

    di as text "Retained draws:" ///
    _col(`value_col') as result %-6.0f e(N_draws) ///
    as text " (" as result (e(N_draws) / e(nchains)) ///
    as text " per chain)"

di ""

}
    
    if "`stats'" != "" {
        capture noisily _qrpdd_stats, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar')

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }

        tempname STATSRESULT
        matrix `STATSRESULT' = r(stats)
        ereturn matrix stats = `STATSRESULT'
    }
    
    if "`dens'" != "" {
        capture noisily _qrpdd_dens, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar') ///
            plot(`plot') ///
            `graphsave_opt'

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }
    }


    if "`trace'" != "" {
        capture noisily _qrpdd_trace, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar') ///
            plot(`plot') ///
            `graphsave_opt'

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }
    }
    
    
    if "`avg'" != "" {
        capture noisily _qrpdd_avg, ///
        params(`var') ///
        chainvar(`chainvar') ///
        timevar(`timevar') ///
        plot(`plot') ///
        `graphsave_opt'

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }
    }
    

if "`acf'" != "" {

    capture noisily _qrpdd_acf, ///
        params(`var') ///
        chainvar(`chainvar') ///
        timevar(`timevar') ///
        lags(`lags') ///
        `graphsave_opt'

    local rc = _rc

    if `rc' {
        restore
        exit `rc'
    }

    local acf_nparams = r(nparams)
    local acf_nchains = r(nchains)
    local acf_params `"`r(params)'"'
    local acf_chains `"`r(chains)'"'

    local acf_matrices ""

    forvalues k = 1/`acf_nparams' {

        tempname ACFRESULT

        matrix `ACFRESULT' = r(acf`k')

        local acf_matrices ///
            `"`acf_matrices' `ACFRESULT'"'
    }

    forvalues k = 1/`acf_nparams' {
        local thismatrix : word `k' of `acf_matrices'
        ereturn matrix acf`k' = `thismatrix'
    }

    ereturn scalar acf_ndvar = `acf_nparams'
    ereturn scalar acf_nchains = `acf_nchains'
    ereturn local acf_dvar `"`acf_params'"'
    ereturn local acf_chains `"`acf_chains'"'
}


    if "`ess'" != "" {
        capture noisily _qrpdd_ess, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar')

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }

        tempname ESSRESULT NDRAWSRESULT
        quietly matrix `ESSRESULT' = r(ess)
        quietly matrix `NDRAWSRESULT' = r(n_draws)
        quietly local ess_nchains = r(nchains)
        quietly local ess_chains `"`r(chains)'"'

        quietly ereturn matrix ess = `ESSRESULT'
        quietly ereturn matrix ess_n_draws = `NDRAWSRESULT'
    }


    if "`gr'" != "" {

        capture noisily _qrpdd_gr, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar')

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }

        tempname GRRESULT
        matrix `GRRESULT' = r(gr)

        local gr_nchains = r(nchains)
        local gr_chains `"`r(chains)'"'

        capture noisily _qrpdd_grplot, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar') ///
            `graphsave_opt'

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }

        ereturn matrix gr = `GRRESULT'

    }


    if "`geweke'" != "" {
        capture noisily _qrpdd_geweke, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar')

        local rc = _rc

        if `rc' {
            restore
            exit `rc'
        }

        tempname GEWEKERESULT
        matrix `GEWEKERESULT' = r(geweke)
        local geweke_nchains = r(nchains)
        local geweke_chains `"`r(chains)'"'

        ereturn matrix geweke = `GEWEKERESULT'

    }
    
    if "`ccm'" != "" {
        capture noisily _qrpdd_ccm, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar')

        local rc = _rc
        if `rc' {
            restore
            exit `rc'
        }

        tempname CCRESULT
        matrix `CCRESULT' = r(cc_total)
        ereturn matrix ccm = `CCRESULT'

        capture noisily _qrpdd_ccm_graph, ///
            params(`var') ///
            chainvar(`chainvar') ///
            timevar(`timevar') ///
            `graphsave_opt'

        local rc = _rc
        if `rc' {
            restore
            exit `rc'
        }
    }

    restore
end



/************************************************************
    Helper program: Validate mcmcopt against allowed list
************************************************************/
capture program drop _qrpdd_validate_mcmcopt
program define _qrpdd_validate_mcmcopt
    version 15.1
    syntax , [ ///
        INSTruments(string asis) ///
        DRAWS(string asis) ///
        BURN(string asis) ///
        ARATE(string asis) ///
        THIN(string asis) ///
        SAMPLER(string asis) ///
        DAMPPARM(string asis) ///
        FROM(string asis) ///
        FROMVARIANCE(string asis) ///
        JUMBLE ///
        NOISY ///
        USEMAX ///
        ANALYTIC ///
    ]
end



/************************************************************
    Helper program: Posterior Summary Statistics
************************************************************/

capture program drop _qrpdd_stats
program define _qrpdd_stats, rclass
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name)

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    quietly levelsof `chainvar', local(chains)
    local nchains : word count `chains'
    local nparams : word count `params'

    local totalrows = `nparams' * (`nchains' + 1)

    tempname STATSMAT
    matrix `STATSMAT' = J(`totalrows', 6, .)

    local roweq ""
    local rownames ""
    local rowidx = 1

    foreach p of local params {
        
        /****************************************************
            1. Chain-specific statistics
        ****************************************************/
        foreach c of local chains {
            
            quietly count if `chainvar' == `c' & !missing(`p')
            if r(N) == 0 {
                di as error "No nonmissing draws for parameter `p' in chain `c'."
                exit 2001
            }

            quietly summarize `p' if `chainvar' == `c'
            matrix `STATSMAT'[`rowidx', 1] = r(mean)
            matrix `STATSMAT'[`rowidx', 2] = r(sd)
            matrix `STATSMAT'[`rowidx', 3] = r(mean) / r(sd)
            matrix `STATSMAT'[`rowidx', 4] = 2 * (1 - normal(abs(r(mean) / r(sd))))
            matrix `STATSMAT'[`rowidx', 5] = r(mean) - 1.96 * r(sd)
            matrix `STATSMAT'[`rowidx', 6] = r(mean) + 1.96 * r(sd)

            local roweq `"`roweq' `p'"'
            local rownames `"`rownames' Chain`c'"'
            
            local ++rowidx
        }

        /****************************************************
            2. Aggregated (Total) statistics
        ****************************************************/
        quietly count if !missing(`p')
        if r(N) == 0 {
            di as error "No nonmissing draws for parameter `p'."
            exit 2001
        }

        quietly summarize `p'
        matrix `STATSMAT'[`rowidx', 1] = r(mean)
        matrix `STATSMAT'[`rowidx', 2] = r(sd)
        matrix `STATSMAT'[`rowidx', 3] = r(mean) / r(sd)
        matrix `STATSMAT'[`rowidx', 4] = 2 * (1 - normal(abs(r(mean) / r(sd))))
        matrix `STATSMAT'[`rowidx', 5] = r(mean) - 1.96 * r(sd)
        matrix `STATSMAT'[`rowidx', 6] = r(mean) + 1.96 * r(sd)

        local roweq `"`roweq' `p'"'
        local rownames `"`rownames' Total"'
        
        local ++rowidx
    }

    matrix rownames `STATSMAT' = `rownames'
    matrix roweq `STATSMAT' = `roweq'
    matrix colnames `STATSMAT' = "Coefficient" `"Std. err."' `"z"' `"P>|z|"' `"CI Lower"' `"CI Upper"'

    di as text ""
    di as text "{bf:Summary Statistics}"
    matlist `STATSMAT', format(%10.3f) names(all)

    di as text ""
    di as text "Notes: Point estimates correspond to mean of draws."
    di as text "       Standard errors are derived from variance of draws."
    di as text "       95% CI calculated as Coefficient +/- 1.96 * Std. err."
    di as text "       The 'Total' row pools all draws across chains to compute the overall mean and variance."
    di as text "       Total z, P>|z|, and CIs are derived directly from these pooled estimates."
    di as text "       Always verify mixing before interpretation."

    return matrix stats = `STATSMAT'
end



/************************************************************
    Helper program: Marginal Density Plot (Histogram + KDE)
************************************************************/

capture program drop _qrpdd_dens
program define _qrpdd_dens
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          PLOT(string) ///
          graphsave(string asis) ///
        ]

    if "`plot'" == "" {
        local plot both
    }
    local plot = lower("`plot'")

    quietly tsset `chainvar' `timevar'
    quietly levelsof `chainvar', local(chains)

    local i = 1
    foreach p of local params {

if inlist("`plot'", "panel", "both") {

    local graphlist ""
    local nshown = 0

    foreach c of local chains {

        if `nshown' < 4 {

            tempname gdens

            quietly twoway ///
                (histogram `p' if `chainvar' == `c', ///
                density) ///
                (kdensity `p' if `chainvar' == `c', ///
                lcolor(black) ///
                lwidth(medthick)), ///
                title("Chain `c'") ///
                legend(off) ///
                note("") ///
                xtitle("Draw value") ///
                ytitle("Density") ///
                name(`gdens', replace) ///
                nodraw

                local graphlist `graphlist' `gdens'
                local ++nshown
            }
        }

        if `nshown' == 0 {
            di as error "No density plots could be produced for variable `p'."
            exit 2001
        }

        if `nshown' == 1 {
            local panelcols 1
        }
        else {
            local panelcols 2
        }

        quietly graph combine `graphlist', ///
            cols(`panelcols') ///
            title("Marginal Density by chain: `p'") ///
            name(dens_p`i', replace)

            if `"`graphsave'"' != "" {
                graph save ///
                `"`graphsave'_dens_panel_`p'.gph"', ///
                replace
            }

            foreach g of local graphlist {
            capture graph close `g'
        }
    }

        if inlist("`plot'", "overlay", "both") {
            local tw_cmd ""
            local legcmd ""
            local c_idx = 1

            foreach c of local chains {
                local tw_cmd `tw_cmd' (kdensity `p' if `chainvar' == `c', lwidth(medthick))
                local legcmd `legcmd' `c_idx' "Chain `c'"
                local ++c_idx
            }

            quietly twoway `tw_cmd', ///
                title("Overlaid Marginal Density Plots: `p'") ///
                xtitle("Draw value") ///
                ytitle("Density") ///
                legend(order(`legcmd')) ///
                name(dens_o`i', replace)

            if `"`graphsave'"' != "" {
                graph save `"`graphsave'_dens_overlay_`p'.gph"', replace
            }
        }
        local ++i
    }
end



/************************************************************
    Helper program: Trace Plot
************************************************************/

capture program drop _qrpdd_trace
program define _qrpdd_trace
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          PLOT(string) ///
          graphsave(string asis) ///
        ]

    if "`plot'" == "" {
        local plot both
    }

    local plot = lower("`plot'")

    if !inlist("`plot'", "panel", "overlay", "both") {
        di as error "plot() must be one of: panel, overlay, both."
        exit 198
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must be numeric."
        exit 109
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    quietly tsset `chainvar' `timevar'

    quietly levelsof `chainvar', local(chains)

    tempfile tracebase
    quietly save `tracebase', replace

    local i = 1
    foreach p of local params {

if inlist("`plot'", "panel", "both") {

    local graphlist ""
    local nshown = 0

    foreach c of local chains {

        if `nshown' < 4 {

            quietly use `tracebase', clear
            quietly keep if `chainvar' == `c'
            quietly tsset `chainvar' `timevar'

            tempname gtrace

tsline `p', ///
    title("Chain `c'") ///
    xtitle("MCMC iteration") ///
    ytitle("Draw value") ///
    name(`gtrace', replace) ///
    nodraw

            local graphlist `graphlist' `gtrace'
            local ++nshown
        }
    }

    if `nshown' == 0 {
        di as error "No trace plots could be produced for variable `p'."
        exit 2001
    }

    if `nshown' == 1 {
        local panelcols 1
    }
    else {
        local panelcols 2
    }

graph combine `graphlist', ///
    cols(`panelcols') ///
    title("Trace Plot by chain: `p'") ///
    name(trace_p`i', replace)

    if `"`graphsave'"' != "" {
        graph save ///
            `"`graphsave'_trace_panel_`p'.gph"', ///
            replace
    }

    *Close temporary component graphs; keep combined graph live
    foreach g of local graphlist {
        capture graph close `g'
    }
}

        if inlist("`plot'", "overlay", "both") {

            quietly use `tracebase', clear

            quietly keep `chainvar' `timevar' `p'

            quietly reshape wide `p', i(`timevar') j(`chainvar')

            quietly tsset `timevar'

            local widevars ""
            local legcmd ""
            local j = 1

            foreach c of local chains {
                local w `p'`c'

                capture confirm variable `w'
                if !_rc {
                    local widevars `widevars' `w'
                    local legcmd `legcmd' `j' "Chain `c'"
                    local ++j
                }
            }

            if `"`widevars'"' == "" {
                di as error "No wide chain variables were created for `p'."
                exit 111
            }

            tsline `widevars', ///
                title("Overlaid Trace Plots: `p'") ///
                xtitle("MCMC iteration") ///
                ytitle("Draw value") ///
                legend(order(`legcmd')) ///
                name(trace_o`i', replace)

            if `"`graphsave'"' != "" {
                graph save `"`graphsave'_trace_overlay_`p'.gph"', replace
            }
        }

        quietly use `tracebase', clear
        local ++i
    }
end



/************************************************************
    Helper program: Running Average Plot
************************************************************/

capture program drop _qrpdd_avg
program define _qrpdd_avg
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          PLOT(string) ///
          graphsave(string asis) ///
        ]

    if "`plot'" == "" {
        local plot both
    }

    local plot = lower("`plot'")

    if !inlist("`plot'", "panel", "overlay", "both") {
        di as error "plot() must be one of: panel, overlay, both."
        exit 198
    }

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    quietly levelsof `chainvar', local(chains)

    tempfile avgbase
    quietly save `avgbase', replace

    local i = 1

    foreach p of local params {

        quietly use `avgbase', clear

        sort `chainvar' `timevar'

        tempvar runs runn runmean

        by `chainvar' (`timevar'): ///
            gen double `runs' = ///
            sum(cond(missing(`p'), 0, `p'))

        by `chainvar' (`timevar'): ///
            gen long `runn' = ///
            sum(!missing(`p'))

        gen double `runmean' = ///
            `runs' / `runn' if `runn' > 0

        foreach c of local chains {

            quietly count if ///
                `chainvar' == `c' & !missing(`p')

            if r(N) == 0 {
                di as error "No nonmissing draws for parameter `p' in chain `c'."
                exit 2001
            }
        }

        if inlist("`plot'", "panel", "both") {

            local graphlist ""
            local nshown 0

            foreach c of local chains {

                if `nshown' < 4 {

                    tempname gavg

                    twoway ///
                        (line `runmean' `timevar' ///
                            if `chainvar' == `c', ///
                            sort), ///
                        title("Chain `c'") ///
                        xtitle("MCMC iteration") ///
                        ytitle("Running average") ///
                        legend(off) ///
                        name(`gavg', replace) ///
                        nodraw

                    local graphlist `graphlist' `gavg'
                    local ++nshown
                }
            }

            if `nshown' == 0 {
                di as error "No running-average plots could be produced for variable `p'."
                exit 2001
            }

            if `nshown' == 1 {
                local panelcols 1
            }
            else {
                local panelcols 2
            }

            graph combine `graphlist', ///
                cols(`panelcols') ///
                title("Running Average by chain: `p'") ///
                name(avg_p`i', replace)

            if `"`graphsave'"' != "" {
                graph save ///
                    `"`graphsave'_avg_panel_`p'.gph"', ///
                    replace
            }

            foreach g of local graphlist {
                capture graph close `g'
            }
        }

        if inlist("`plot'", "overlay", "both") {

            local tw_cmd ""
            local legcmd ""
            local j 1

            foreach c of local chains {

                local tw_cmd ///
                    `tw_cmd' ///
                    (line `runmean' `timevar' ///
                        if `chainvar' == `c', sort)

                local legcmd ///
                    `legcmd' `j' "Chain `c'"

                local ++j
            }

            twoway `tw_cmd', ///
                title("Overlaid Running Averages: `p'") ///
                xtitle("MCMC iteration") ///
                ytitle("Running average") ///
                legend(order(`legcmd')) ///
                name(avg_o`i', replace)

            if `"`graphsave'"' != "" {
                graph save ///
                    `"`graphsave'_avg_overlay_`p'.gph"', ///
                    replace
            }
        }


        local ++i
    }

    quietly use `avgbase', clear
end



/************************************************************
    Helper program: Autocorrelation Function (ACF)
************************************************************/

capture program drop _qrpdd_acf
program define _qrpdd_acf, rclass
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          LAGS(integer 20) ///
          graphsave(string asis) ///
        ]

    if `lags' < 1 {
        di as error "lags() must be at least 1."
        exit 198
    }

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    quietly levelsof `chainvar', local(chains)

    local nchains : word count `chains'
    local nparams : word count `params'

    tempfile acfbase
    quietly save `acfbase', replace

    local i = 1

    foreach p of local params {

        tempname ACFMAT
        matrix `ACFMAT' = J(`lags', `nchains', .)

        local maxlags 0
        local graphlist ""
        local nchains_plotted 0
        local ngraphs_created 0
        local c_index 1

            foreach c of local chains {

            quietly use `acfbase', clear

            quietly keep if `chainvar' == `c'
            quietly keep `chainvar' `timevar' `p'
            quietly drop if missing(`p')
            quietly sort `timevar'

            quietly count
            local n = r(N)

            if `n' < 3 {
                di as error "Too few nonmissing draws for parameter `p' in chain `c'."
                di as error "At least 3 draws are required for the autocorrelation diagnostic."
                exit 2001
            }

            local thislags = min(`lags', `n' - 1)

            if `thislags' < `lags' {
                di as text "Note: lags(`lags') reduced to `thislags' for `p', chain `c' (N = `n')."
            }

            if `thislags' > `maxlags' {
                local maxlags `thislags'
            }

            quietly tsset `timevar'

            tempvar acf_dev acf_sq acf_cross
            tempname ACFDEN ACFNUM

            quietly summarize `p', meanonly
            local acf_mean = r(mean)

            quietly gen double `acf_dev' = ///
                `p' - `acf_mean'

            quietly gen double `acf_sq' = ///
                `acf_dev'^2

            quietly summarize `acf_sq', meanonly
            scalar `ACFDEN' = r(mean) * r(N)

            quietly gen double `acf_cross' = .

            forvalues L = 1/`thislags' {

                quietly replace `acf_cross' = ///
                    `acf_dev' * L`L'.`acf_dev'

                quietly summarize `acf_cross', meanonly

                if r(N) > 0 & scalar(`ACFDEN') > 0 {

                    scalar `ACFNUM' = ///
                        r(mean) * r(N)

                    matrix `ACFMAT'[`L', `c_index'] = ///
                        scalar(`ACFNUM') / scalar(`ACFDEN')
                }
                else {
                    matrix `ACFMAT'[`L', `c_index'] = .
                }
            }


            /************************************************
                Helper program: ACF Plot
            ************************************************/

            if `ngraphs_created' < 4 {

                clear
                quietly set obs `thislags'

                tempvar acf_lag acf_value acf_upper acf_lower

                quietly gen int `acf_lag' = _n
                quietly gen double `acf_value' = .
                quietly gen double `acf_upper' = .
                quietly gen double `acf_lower' = .

                forvalues L = 1/`thislags' {
                    quietly replace `acf_value' = ///
                        `ACFMAT'[`L', `c_index'] in `L'
                }

                forvalues L = 1/`thislags' {

                    local bartlett_sum = 0

                    if `L' > 1 {
                        forvalues j = 1/`=`L'-1' {

                            local rho = ///
                                `ACFMAT'[`j', `c_index']

                            if !missing(`rho') {
                                local bartlett_sum = ///
                                    `bartlett_sum' + (`rho'^2)
                            }
                        }
                    }

                    quietly replace `acf_upper' = ///
                        invnormal(.975) * ///
                        sqrt((1 + 2*`bartlett_sum') / `n') in `L'

                    quietly replace `acf_lower' = ///
                        -invnormal(.975) * ///
                        sqrt((1 + 2*`bartlett_sum') / `n') in `L'
                }

                local gac = "acf_chain`c_index'"

                twoway ///
                    (spike `acf_value' `acf_lag') ///
                    (line `acf_upper' `acf_lag', ///
                        lpattern(dash) lcolor(gs8)) ///
                    (line `acf_lower' `acf_lag', ///
                        lpattern(dash) lcolor(gs8)), ///
                    yscale(range(-1 1)) ///
                    ylabel(-1 -.5 0 .5 1) ///
                    yline(0) ///
                    title("Chain `c'") ///
                    xtitle("Lag") ///
                    ytitle("Autocorrelation") ///
                    legend(off) ///
                    name(`gac', replace) ///
                    nodraw

                local graphlist `graphlist' `gac'

                local ++ngraphs_created
                local ++nchains_plotted
            }

            local ++c_index
        }

        tempname ACFOUT

        matrix `ACFOUT' = ///
            `ACFMAT'[1..`maxlags', 1..`nchains']

        local rownames ""

        forvalues L = 1/`maxlags' {
            local rownames "`rownames' Lag`L'"
        }

        local colnames ""

        forvalues j = 1/`nchains' {
            local colnames "`colnames' Chain`j'"
        }

        matrix rownames `ACFOUT' = `rownames'
        matrix colnames `ACFOUT' = `colnames'

        di as text ""
        di as text "{bf:Autocorrelation table: `p'}"

        matlist `ACFOUT', ///
            format(%10.4f) ///
            names(all)

        di as text ""

        if `nchains_plotted' == 0 {
            di as error "No autocorrelation plots could be produced for variable `p'."
            exit 2001
        }

        if `nchains_plotted' == 1 {
            local panelcols 1
        }
        else {
            local panelcols 2
        }

        graph combine `graphlist', ///
            cols(`panelcols') ///
            title("Autocorrelation by chain: `p'") ///
            note("Dashed lines: 95% confidence intervals based on Bartlett's formula") ///
            name(acf_p`i', replace)

        if `"`graphsave'"' != "" {
            graph save ///
                `"`graphsave'_acf_`p'.gph"', ///
                replace
        }

        foreach g of local graphlist {
            capture graph close `g'
        }

        return matrix acf`i' = `ACFOUT'

        local ++i
    }

    return scalar nparams = `nparams'
    return scalar nchains = `nchains'
    return local params "`params'"
    return local chains "`chains'"

    quietly use `acfbase', clear
end



/************************************************************
    Helper program: Gelman-Rubin Convergence Diagnostic
************************************************************/

capture program drop _qrpdd_gr
program define _qrpdd_gr, rclass
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name)

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    sort `chainvar' `timevar'
    quietly levelsof `chainvar', local(chains)

    local nchains : word count `chains'
    local nparams : word count `params'

    if `nchains' < 2 {
        di as error "Minimum 2 chains are required to calculate Gelman-Rubin."
        exit 198
    }

    tempname GRMAT
    matrix `GRMAT' = J(`nparams', 5, .)

    local rownames ""
    local i = 1

    foreach p of local params {

        local rownames `rownames' `p'

        tempname SUMMEANS SUMVARS GRANDMEAN W B VARPLUS RHAT SSBE

        scalar `SUMMEANS' = 0
        scalar `SUMVARS'  = 0

        local n_common .
        local j = 1

        foreach c of local chains {

            quietly summarize `p' if `chainvar' == `c'

            local n = r(N)

            if `n' < 2 {
                di as error "Too few nonmissing draws for parameter `p' in chain `c'."
                di as error "At least 2 retained draws per chain are required for Gelman-Rubin."
                exit 2001
            }

            if `j' == 1 {
                local n_common = `n'
            }
            else if `n' != `n_common' {
                di as error "Chains have unequal numbers of nonmissing draws for parameter `p'."
                di as error "Classical Gelman-Rubin requires equal chain lengths."
                exit 498
            }

            if r(Var) <= 0 | missing(r(Var)) {
                di as error "Parameter `p' has zero or undefined variance in chain `c'."
                di as error "Gelman-Rubin cannot be calculated for a constant chain."
                exit 498
            }

            scalar `SUMMEANS' = scalar(`SUMMEANS') + r(mean)
            scalar `SUMVARS'  = scalar(`SUMVARS')  + r(Var)

            local ++j
        }

        scalar `GRANDMEAN' = scalar(`SUMMEANS') / `nchains'
        scalar `W'         = scalar(`SUMVARS')  / `nchains'

        scalar `SSBE' = 0

        foreach c of local chains {

            quietly summarize `p' if `chainvar' == `c', meanonly

            scalar `SSBE' = scalar(`SSBE') + ///
                (r(mean) - scalar(`GRANDMEAN'))^2
        }

        scalar `B' = (`n_common' / (`nchains' - 1)) * scalar(`SSBE')

        scalar `VARPLUS' = ///
            ((`n_common' - 1) / `n_common') * scalar(`W') + ///
            (1 / `n_common') * scalar(`B')

        scalar `RHAT' = sqrt(scalar(`VARPLUS') / scalar(`W'))

        matrix `GRMAT'[`i', 1] = scalar(`RHAT')
        matrix `GRMAT'[`i', 2] = scalar(`W')
        matrix `GRMAT'[`i', 3] = scalar(`B')
        matrix `GRMAT'[`i', 4] = `n_common'
        matrix `GRMAT'[`i', 5] = `nchains'

        local ++i
    }

    matrix rownames `GRMAT' = `rownames'
    matrix colnames `GRMAT' = R-hat W B N Chains

    di as text ""
    di as text "{bf:Gelman-Rubin Convergence Diagnostic}"
    matlist `GRMAT', format(%10.5g) names(all)

    di as text ""
    di as text "W: Average within-chain variance."
    di as text "B: Between-chain variance."
    di as text "N: Number of retained draws per chain."
    di as text "R-hat values < 1.1 typically indicate convergence."
    di as text ""

    return matrix gr = `GRMAT'
    return scalar nchains = `nchains'
    return local chains "`chains'"
end


/************************************************************
    Helper program: Gelman-Rubin R-hat Plot
************************************************************/

capture program drop _qrpdd_grplot
program define _qrpdd_grplot
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          graphsave(string asis) ///
        ]

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    sort `chainvar' `timevar'
    quietly levelsof `chainvar', local(chains)

    local nchains : word count `chains'

    if `nchains' < 2 {
        di as error "Minimum 2 chains are required to calculate Gelman-Rubin."
        exit 198
    }

    tempfile grplotbase
    quietly save `grplotbase', replace

    local i = 1

    foreach p of local params {

        quietly use `grplotbase', clear
        sort `chainvar' `timevar'

        tempvar seq

        by `chainvar' (`timevar'): ///
            gen long `seq' = sum(!missing(`p'))

        local n_common .
        local j 1

        foreach c of local chains {

            quietly count if ///
                `chainvar' == `c' & !missing(`p')

            local n = r(N)

            if `n' < 2 {
                di as error "Too few nonmissing draws for parameter `p' in chain `c'."
                di as error "At least 2 retained draws per chain are required for Gelman-Rubin."
                exit 2001
            }

            if `j' == 1 {
                local n_common = `n'
            }
            else if `n' != `n_common' {
                di as error "Chains have unequal numbers of nonmissing draws for parameter `p'."
                di as error "Classical Gelman-Rubin requires equal chain lengths."
                exit 498
            }

            quietly summarize `p' if `chainvar' == `c'

            if r(Var) <= 0 | missing(r(Var)) {
                di as error "Parameter `p' has zero or undefined variance in chain `c'."
                di as error "Gelman-Rubin cannot be calculated for a constant chain."
                exit 498
            }

            local ++j
        }

        quietly tempfile grcurve
        quietly tempname POST

        quietly postfile `POST' ///
            long draw ///
            double rhat ///
            using "`grcurve'", replace

        quietly tempname SUMMEANS SUMVARS GRANDMEAN W B VARPLUS RHAT SSBE

        forvalues n = 2/`n_common' {

            quietly scalar `SUMMEANS' = 0
            quietly scalar `SUMVARS'  = 0

            quietly local valid 1

            foreach c of local chains {

                quietly summarize `p' if ///
                    `chainvar' == `c' & ///
                    `seq' <= `n' & ///
                    !missing(`p')

                if r(N) != `n' | ///
                    r(Var) <= 0 | ///
                    missing(r(Var)) {

                    quietly local valid 0
                    continue, break
                }

                quietly scalar `SUMMEANS' = ///
                    scalar(`SUMMEANS') + r(mean)

                quietly scalar `SUMVARS' = ///
                    scalar(`SUMVARS') + r(Var)
            }

            if `valid' {

                quietly scalar `GRANDMEAN' = ///
                    scalar(`SUMMEANS') / `nchains'

                quietly scalar `W' = ///
                    scalar(`SUMVARS') / `nchains'

                quietly scalar `SSBE' = 0

                foreach c of local chains {

                    quietly summarize `p' if ///
                        `chainvar' == `c' & ///
                        `seq' <= `n' & ///
                        !missing(`p'), ///
                        meanonly

                    quietly scalar `SSBE' = ///
                        scalar(`SSBE') + ///
                        (r(mean) - scalar(`GRANDMEAN'))^2
                }

                quietly scalar `B' = ///
                    (`n' / (`nchains' - 1)) * ///
                    scalar(`SSBE')

                quietly scalar `VARPLUS' = ///
                    ((`n' - 1) / `n') * scalar(`W') + ///
                    (1 / `n') * scalar(`B')

                quietly scalar `RHAT' = ///
                    sqrt(scalar(`VARPLUS') / scalar(`W'))

                quietly post `POST' ///
                    (`n') ///
                    (scalar(`RHAT'))
            }
        }

        quietly postclose `POST'

        quietly use "`grcurve'", clear

        quietly count if !missing(rhat)

        if r(N) == 0 {
            di as error "No defined Gelman-Rubin plot values could be calculated for parameter `p'."
            exit 498
        }

quietly summarize rhat, meanonly

local ymin = min(r(min), .9)
local ymax = max(r(max), 1)

local yrange = `ymax' - `ymin'

if `yrange' <= 0 {
    local yrange = .1
}

local ymin = `ymin' - .05 * `yrange'
local ymax = `ymax' + .05 * `yrange'

quietly twoway ///
    (line rhat draw, sort), ///
    yscale(range(`ymin' `ymax')) ///
    ylabel(, grid) ///
    ylabel(1, add) ///
    yline(1, lpattern(dash)) ///
    title("Gelman-Rubin R-hat: `p'") ///
    xtitle("Retained draw per chain") ///
    ytitle("R-hat") ///
    legend(off) ///
    name(gr_p`i', replace)




        if `"`graphsave'"' != "" {
            graph save ///
                `"`graphsave'_gr_`p'.gph"', ///
                replace
        }

        local ++i
    }

    quietly use `grplotbase', clear
end



/************************************************************
    Helper program: Effective Sample Size (ESS) & MCSE
************************************************************/

capture program drop _qrpdd_ess
program define _qrpdd_ess, rclass
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name)

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    sort `chainvar' `timevar'
    quietly levelsof `chainvar', local(chains)

    quietly local nchains : word count `chains'
    quietly local nparams : word count `params'

    if `nchains' < 1 {
        di as error "No MCMC chains found."
        exit 2000
    }

    tempname ESSMAT NMAT
    quietly matrix `ESSMAT' = J(`nparams', 2 * `nchains' + 2, .)
    quietly matrix `NMAT'   = J(`nparams', `nchains', .)

    quietly local rownames ""
    quietly local colnames ""

    forvalues j = 1/`nchains' {
        quietly local colnames `colnames' ESS_C`j'
    }
    quietly local colnames `colnames' ESS_Tot

    forvalues j = 1/`nchains' {
        quietly local colnames `colnames' MCSE_C`j'
    }
    quietly local colnames `colnames' MCSE_Tot

    local i = 1

    foreach p of local params {

        quietly local rownames `rownames' `p'
        tempname totaless
        quietly scalar `totaless' = 0

        local j = 1

        foreach c of local chains {

            quietly count if `chainvar' == `c' & !missing(`p')
            local n = r(N)

            if `n' < 3 {
                di as error "Too few nonmissing draws for parameter `p' in chain `c'."
                exit 2001
            }

            quietly summarize `p' if `chainvar' == `c'
            local c_sd = r(sd)

            if r(Var) <= 0 | missing(r(Var)) {
                di as error "Parameter `p' has zero variance in chain `c'."
                exit 498
            }

            tempname oneess

            mata: st_numscalar("`oneess'", ///
                _qrpdd_ess_ips( ///
                    st_data( ///
                        selectindex(st_data(., "`chainvar'") :== `c'), ///
                        "`p'" ///
                    ) ///
                ) ///
            )

            if missing(`oneess') {
                di as error "ESS calculation failed for parameter `p' in chain `c'."
                exit 498
            }

            quietly matrix `ESSMAT'[`i', `j'] = `oneess'
            quietly matrix `NMAT'[`i', `j']   = `n'
            
            quietly matrix `ESSMAT'[`i', `j' + `nchains' + 1] = `c_sd' / sqrt(`oneess')

            quietly scalar `totaless' = `totaless' + `oneess'

            quietly local ++j
        }

        quietly summarize `p'
        local t_sd = r(sd)
        
        quietly matrix `ESSMAT'[`i', `=`nchains' + 1'] = `totaless'
        quietly matrix `ESSMAT'[`i', 2 * `nchains' + 2] = `t_sd' / sqrt(scalar(`totaless'))
        
        local ++i
    }

    quietly matrix rownames `ESSMAT' = `rownames'
    quietly matrix colnames `ESSMAT' = `colnames'

    quietly matrix rownames `NMAT' = `rownames'

    local ncolnames ""
    forvalues j = 1/`nchains' {
        quietly local ncolnames `ncolnames' Chain`j'
    }
    quietly matrix colnames `NMAT' = `ncolnames'

    di as text ""
    di as text "{bf:Effective Sample Size (ESS) & Monte Carlo Standard Error (MCSE)}"
    local colnames
    forvalues j = 1/`nchains' {
        local colnames `"`colnames' `"ESS c`j'"'"'
    }
    local colnames `"`colnames' `"ESS Total"'"'
    forvalues j = 1/`nchains' {
        local colnames `"`colnames' `"MCSE c`j'"'"'
    }
    local colnames `"`colnames' `"MCSE Total"'"'
    
    matrix colnames `ESSMAT' = `colnames'
    matlist `ESSMAT', format(%10.3f) names(all)
    di as text ""
    di as text "Note: Total ESS measures total independent information captured across all chains."
    di as text "      MCSE = Standard Deviation / sqrt(ESS). Evaluated per chain and pooled."
    di as text "      Lower MCSE values indicate greater simulation precision."

    quietly return matrix ess = `ESSMAT'
    quietly return matrix n_draws = `NMAT'
    quietly return scalar nchains = `nchains'
    quietly return local chains "`chains'"
end

/************************************************************
    Mata function used by _qrpdd_ess
************************************************************/

capture mata: mata drop _qrpdd_ess_ips()
mata:
real scalar _qrpdd_ess_ips(real colvector x)
{
    real scalar n, ss, maxlag, k
    real scalar rho_even, rho_odd, pairsum, sumpairs, tau, ess
    real colvector z

    x = select(x, x :< .)
    n = rows(x)

    if (n < 3) return(.)

    z = x :- mean(x)
    ss = quadcross(z, z)

    if (ss <= 0 | missing(ss)) return(.)

    maxlag = n - 1
    k = 0
    sumpairs = 0

    while (k + 1 <= maxlag) {

        if (k == 0) {
            rho_even = 1
        }
        else {
            rho_even = quadcross(
                           z[|1 \ n-k|],
                           z[|k+1 \ n|]
                       ) / ss
        }

        rho_odd = quadcross(
                      z[|1 \ n-k-1|],
                      z[|k+2 \ n|]
                  ) / ss

        pairsum = rho_even + rho_odd

        if (pairsum <= 0) break

        sumpairs = sumpairs + pairsum
        k = k + 2
    }

    if (sumpairs <= 0) {
        tau = 1
    }
    else {
        tau = -1 + 2 * sumpairs
    }

    if (tau < 1) tau = 1

    ess = n / tau

    if (ess > n) ess = n
    if (ess < 1) ess = 1

    return(ess)
}
end



/************************************************************
    Helper program: Geweke Convergence Diagnostic
************************************************************/

capture program drop _qrpdd_geweke
program define _qrpdd_geweke, rclass
    version 15.1

    syntax , ///
        PARAMS(string asis) ///
        CHAINvar(name) ///
        TIMEvar(name) ///
        [ ///
          FRAC1(real 0.1) ///
          FRAC2(real 0.5) ///
        ]

    capture confirm numeric variable `chainvar'
    if _rc {
        di as error "Chain variable `chainvar' must exist and be numeric."
        exit 109
    }

    capture confirm numeric variable `timevar'
    if _rc {
        di as error "Iteration variable `timevar' must exist and be numeric."
        exit 109
    }

    foreach p of local params {
        capture confirm numeric variable `p'
        if _rc {
            di as error "Variable `p' not found or not numeric."
            exit 111
        }
    }

    capture isid `chainvar' `timevar'
    if _rc {
        di as error "`chainvar' and `timevar' do not uniquely identify observations."
        exit 459
    }

    sort `chainvar' `timevar'
    quietly levelsof `chainvar', local(chains)

    local nchains : word count `chains'
    local nparams : word count `params'

    if `nchains' < 1 {
        di as error "No MCMC chains found."
        exit 2000
    }

    tempname GEWMAT
    matrix `GEWMAT' = J(`nparams', `=`nchains' * 2', .)

    local rownames ""
    local colnames ""
    forvalues j = 1/`nchains' {
        if `nchains' == 1 {
            local colnames `colnames' z P>|z|
        }
        else {
            local colnames `colnames' z`j' P>|z`j'|
        }
    }

    local i = 1

    foreach p of local params {
        local rownames `rownames' `p'
        local j = 1

        tempvar seq maxseq slice1 slice2
        quietly by `chainvar' (`timevar'): gen long `seq' = sum(!missing(`p'))
        quietly by `chainvar' (`timevar'): gen long `maxseq' = `seq'[_N]
        
        quietly gen byte `slice1' = (`seq' >= 1 & `seq' <= floor(`frac1' * `maxseq') & !missing(`p'))
        quietly gen byte `slice2' = (`seq' > `maxseq' - floor(`frac2' * `maxseq') & !missing(`p'))

        foreach c of local chains {
            quietly count if `chainvar' == `c' & !missing(`p')
            local n = r(N)

            if `n' < 20 {
                di as error "Too few draws for variable `p' in chain `c' to compute Geweke diagnostic."
                exit 2001
            }

            quietly summarize `p' if `chainvar' == `c' & `slice1' == 1
            local mean1 = r(mean)
            local var1 = r(Var)

            quietly summarize `p' if `chainvar' == `c' & `slice2' == 1
            local mean2 = r(mean)
            local var2 = r(Var)

            if `var1' <= 0 | missing(`var1') | `var2' <= 0 | missing(`var2') {
                di as text "Note: Variable `p' has no variation in the early or late segment of chain `c'. Excluding from the calculation."
                local zval = .
                local pval = .
            } 
            else {
                tempname ess1 ess2
                
                capture mata: st_numscalar("`ess1'", _qrpdd_ess_ips(st_data(selectindex(st_data(., "`chainvar'") :== `c' :& st_data(., "`slice1'") :== 1), "`p'")))
                capture mata: st_numscalar("`ess2'", _qrpdd_ess_ips(st_data(selectindex(st_data(., "`chainvar'") :== `c' :& st_data(., "`slice2'") :== 1), "`p'")))

                if missing(`ess1') | missing(`ess2') {
                    local zval = .
                    local pval = .
                } 
                else {
                    local ase1 = `var1' / `ess1'
                    local ase2 = `var2' / `ess2'
                    
                    local zval = (`mean1' - `mean2') / sqrt(`ase1' + `ase2')
                    local pval = 2 * (1 - normal(abs(`zval')))
                }
            }

            local col_z = (`j' * 2) - 1
            local col_p = `j' * 2

            matrix `GEWMAT'[`i', `col_z'] = `zval'
            matrix `GEWMAT'[`i', `col_p'] = `pval'

            local ++j
        }

        drop `seq' `maxseq' `slice1' `slice2'
        local ++i
    }

    matrix rownames `GEWMAT' = `rownames'
    matrix colnames `GEWMAT' = `colnames'

    di as text ""
    di as text "{bf:Geweke Convergence Diagnostic}"
    di as text "Fraction 1: First " `frac1'*100 "%   Fraction 2: Last " `frac2'*100 "%"
    matlist `GEWMAT', format(%10.4f) names(all)

    di as text ""
    di as text "Chain order: `chains'"
    di as text "P-values < 0.05 suggest the chain has not reached stationarity."

    return matrix geweke = `GEWMAT'
    return scalar nchains = `nchains'
    return local chains "`chains'"
end



/*******************************************************************************
    Helper program: Parameter Cross-Correlation Matrix
*******************************************************************************/

capture program drop _qrpdd_ccm
program define _qrpdd_ccm, rclass
    version 15.1
    syntax , PARAMS(string asis) CHAINvar(name) TIMEvar(name)

    foreach p of local params {
        confirm numeric variable `p'
    }

    quietly levelsof `chainvar', local(chains)

    foreach c of local chains {
        di as text ""
        di as text "{bf:Parameter Cross-Correlation Matrix: Chain `c'}"
        quietly correlate `params' if `chainvar' == `c'
        tempname CCMAT`c'
        matrix `CCMAT`c'' = r(C)
        matlist `CCMAT`c'', format(%10.3f) names(all)
    }

    di as text ""
    di as text "{bf:Parameter Cross-Correlation Matrix: Pooled Total}"
    quietly correlate `params'
    tempname CCMAT_Tot
    matrix `CCMAT_Tot' = r(C)
    matlist `CCMAT_Tot', format(%10.3f) names(all)

    di as text ""
    di as text "Note: High cross-correlations (|r| > 0.8) indicate potential multicollinearity."

    quietly return matrix cc_total = `CCMAT_Tot'
end

/*******************************************************************************
    Graph Program: Joint Parameter Space Graph Matrix
*******************************************************************************/

capture program drop _qrpdd_ccm_graph
program define _qrpdd_ccm_graph
    version 15.1
    syntax , PARAMS(string asis) CHAINvar(name) TIMEvar(name) [ graphsave(string asis) ]

    local nparams : word count `params'
    if `nparams' < 2 {
        di as error "At least two parameters are required for a cross-correlation graph matrix."
        exit 198
    }

    foreach p of local params {
        confirm numeric variable `p'
    }

    quietly levelsof `chainvar', local(chains)

    foreach c of local chains {
        graph matrix `params' if `chainvar' == `c', ///
            title("{bf:Joint Parameter Space: Chain `c'}") ///
            subtitle("Evaluated over posterior MCMC draws") ///
            name(ccm_c`c', replace)

        if `"`graphsave'"' != "" {
            graph save `"`graphsave'_ccm_chain`c'.gph"', replace
        }
    }

    graph matrix `params', ///
        title("{bf:Joint Parameter Space: Pooled Total}") ///
        subtitle("Evaluated over posterior MCMC draws") ///
        name(ccm_tot, replace)

    if `"`graphsave'"' != "" {
        graph save `"`graphsave'_ccm_pooled.gph"', replace
    }
end
