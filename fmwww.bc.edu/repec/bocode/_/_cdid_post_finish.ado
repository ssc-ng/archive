*! Completes the results posted by cdid, estat and cdid_load: estimation-command
*! conventions, inference labels and plain-language descriptions.
program define _cdid_post_finish, eclass
    version 19.5
    syntax, TITLE(string) ENDPOINT(string) [IVAR(string) TIME(string) GVAR(string) ///
        CLUSTVAR(string) DEPVAR(string) METHOD(string) COVARIATES(string)]

    // Inference: type of standard errors, of intervals, and how bstrap() and cband() applied
    local mode "`e(mode)'"
    local law `"`e(flag_law)'"'
    local point_only = cond(missing(e(point_only)), 0, e(point_only))
    if "`mode'"=="ordinary" {
        local bs = e(bstrap)
        local cb = e(cband)
    }
    else {
        local bs = e(bstrap_requested)
        local cb = e(cband_requested)
    }
    if missing(`bs') local bs = .
    if missing(`cb') local cb = 0
    local crit = e(critical_value)
    local norm = e(normal_critical_value)
    if missing(`crit') local crit = .
    if missing(`norm') local norm = .
    mata: cdid_post_inference_labels(st_local("law"), `bs', `cb', `point_only', ///
        st_local("endpoint"), st_local("mode"), `crit', `norm')
    ereturn local title `"`title'"'
    ereturn local vce "`vce'"
    ereturn local vcetype "`vcetype'"
    ereturn local band "`band'"
    ereturn local inference_rule `"`rule'"'

    // Variables and estimator
    if "`depvar'"!="" & "`e(depvar)'"=="" ereturn local depvar "`depvar'"
    if "`method'"!="" & "`e(method)'"=="" ereturn local method "`method'"
    if "`ivar'"!="" ereturn local ivar "`ivar'"
    if "`time'"!="" ereturn local time "`time'"
    if "`gvar'"!="" ereturn local gvar "`gvar'"
    local covariates = strtrim(`"`covariates'"')
    if `"`covariates'"'!="" ereturn local covariates `"`covariates'"'

    // Counts: cells of the fit, rows of the current results table, clusters
    if !missing(e(N_source_cells)) local n_cells = e(N_source_cells)
    else local n_cells = e(N_ledger)
    if !missing(e(N_targets)) local n_targets = e(N_targets)
    else local n_targets = e(N_ledger)
    local n_clust = e(N_clusters)
    local wald_clust = e(wald_N_clusters)
    local clustered = (e(clustered)==1)
    mata: st_numscalar("e(N_source_cells)", J(0,0,.)); st_numscalar("e(N_ledger)", J(0,0,.))
    mata: st_numscalar("e(N_clusters)", J(0,0,.)); st_numscalar("e(wald_N_clusters)", J(0,0,.))
    if !missing(`n_cells') ereturn scalar N_cells = `n_cells'
    if !missing(`n_targets') ereturn scalar N_targets = `n_targets'
    if `clustered' {
        if !missing(`n_clust') ereturn scalar N_clust = `n_clust'
        if !missing(`wald_clust') ereturn scalar wald_N_clust = `wald_clust'
        if "`clustvar'"!="" ereturn local clustvar "`clustvar'"
    }

    // Plain-language descriptions in place of internal codes
    local reason `"`e(wald_reason)'"'
    mata: st_local("reason", cdid_text_reason(st_local("reason")))
    ereturn local wald_reason `"`reason'"'
    if "`e(wald_status)'"=="not_computed" & "`vce'"=="none" ereturn local wald_reason "point estimates only (noinffunc)"
    if `"`e(overall_reason)'"'!="" {
        local reason `"`e(overall_reason)'"'
        mata: st_local("reason", cdid_text_unavailable(st_local("reason")))
        ereturn local overall_reason `"`reason'"'
    }
    local warning `"`e(warning)'"'
    local warning = ustrregexra(`"`warning'"', "^[; ]+", "")
    ereturn local warning `"`warning'"'
    local inactive `"`e(inactive_arguments)'"'
    if `"`inactive'"'!="" {
        local options ""
        foreach a of local inactive {
            local o "`a'"
            if "`a'"=="imputation_pooling" local o "imppooling()"
            else if "`a'"=="selection_model" local o "selmodel()"
            else if "`a'"=="selection_pooling" local o "selpooling()"
            else if "`a'"=="selection_xformla" local o "selcovars()"
            else if "`a'"=="outcome_pooling" local o "outcomepooling()"
            local options "`options' `o'"
        }
        ereturn local inactive_arguments ""
        ereturn local inactive_options = strtrim("`options'")
    }
    local stream "`e(rng_mode)'"
    if "`stream'"=="" & strpos(`"`e(multiplier_source)'"', "caller")==1 local stream "caller"
    if "`stream'"=="" & strpos(`"`e(multiplier_source)'"', "fixed")==1 local stream "fixed"
    if strpos(`"`e(multiplier_source)'"', "loaded")==1 local stream "loaded"
    if `"`e(multiplier_source)'"'!="" | "`e(rng_mode)'"!="" {
        if "`stream'"=="fixed" local rng "fixed multiplier signs supplied with the request"
        else if "`stream'"=="loaded" local rng "results loaded from a file; no new multiplier draws"
        else local rng "Stata random-number generator (set seed); draws only for the multiplier bootstrap or simultaneous bands"
        ereturn local rng `"`rng'"'
    }
    ereturn local multiplier_source ""
    ereturn local rng_mode ""
    ereturn local flag_law ""
    ereturn local fit_state_lifetime ""
    ereturn local source_state_token ""

    // Ordinary mode: covariance descriptions and the covariance computed as R's did package
    if "`mode'"=="ordinary" {
        if "`e(result_kind)'"=="ordinary_cells" {
            local cov "e(V) is the covariance of the influence functions and e(V_asymptotic) is N_full times e(V)"
            capture confirm matrix e(V_source)
            if !_rc {
                tempname vd vda
                matrix `vd' = e(V_source)
                matrix `vda' = e(V_source_asymptotic)
                mata: st_matrix("e(V_source)", J(0,0,.)); st_matrix("e(V_source_asymptotic)", J(0,0,.))
                ereturn matrix V_did = `vd'
                ereturn matrix V_did_asymptotic = `vda'
                local cov "`cov'; e(V_did_asymptotic) is the analytic covariance R's att_gt() reports as V_analytical (cluster sums only when clustering without the bootstrap), and e(V_did) is e(V_did_asymptotic) divided by N_full"
            }
        }
        else local cov "e(V) is the covariance of the influence functions of the aggregates (R's aggte() reports standard errors only) and e(V_asymptotic) is N_full times e(V)"
        ereturn local covariance_scale "`cov'"
        ereturn local covariance_origin ""
        ereturn local source_covariance_scale ""
    }
end
