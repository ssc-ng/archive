*! Private native result bridge; explicit token/settings/signs only, no data fit.
program define _cdid_public_post, eclass
    version 19.5
    syntax, TOKEN(string) REQUEST(name) [SIGNS(name) SIGNMode(string) SAVING(string)]
    if "`signmode'"=="" local signmode = cond("`signs'"=="","caller","fixed")
    if !inlist("`signmode'","caller","fixed") | ("`signmode'"=="caller" & "`signs'"!="") {
        display as error "signmode() must be caller or fixed; caller mode cannot also supply signs()"
        exit 198
    }
    tempname held b V Omega se analytic ci pointci mapping
    tempvar heldsample
    local newtoken ""
    local caller_sort_rng `"`c(sortrngstate)'"'
    capture noisily {
        _estimates hold `held', copy restore nullok varname(`heldsample')
        mata: st_local("newtoken",cdid_public_bridge_stage(st_local("token"),st_local("request"), ///
            st_local("signs"),st_local("signmode"),st_local("b"),st_local("V"), ///
            st_local("Omega"),st_local("se"),st_local("analytic"),st_local("ci"), ///
            st_local("pointci"),st_local("mapping"),`=c(max_matdim)'))
        if `bridge_npost' {
            if `bridge_hasV' ereturn post `b' `V', obs(`bridge_N') properties(b V)
            else ereturn post `b', obs(`bridge_N') properties(b)
        }
        else ereturn post, obs(`bridge_N') properties("")
        ereturn local cmd "_cdid_public_post"
        ereturn local state_token `"`newtoken'"'
        ereturn local source_state_token `"`token'"'
        ereturn local result_kind "`bridge_kind'"
        ereturn local result_status "`bridge_status'"
        ereturn local inference_status "`bridge_inference_status'"
        ereturn local flag_law "`bridge_flags'"
        ereturn local warning `"`bridge_warning'"'
        ereturn local posting_mode "`bridge_posting_mode'"
        if "`bridge_posting_mode'"=="state" ereturn local posting_reason "posting(state): complete results stored without e(b) and e(V)"
        else ereturn local posting_reason "finite coefficients posted; e(coef_map) gives their rows in the complete results table"
        ereturn scalar alpha = `bridge_alpha'
        ereturn scalar level = `=100*(1-`bridge_alpha')'
        ereturn scalar B_requested = `bridge_B'
        ereturn scalar bstrap_requested = `bridge_bstrap'
        ereturn scalar cband_requested = `bridge_cband'
        ereturn scalar clustered = `bridge_clustered'
        ereturn scalar N_source_cells = `bridge_N_source'
        ereturn local multiplier_source "`signmode' random-number stream; multiplier draws only when requested"
        ereturn scalar N_full = `bridge_N'
        ereturn scalar N_clusters = `bridge_C'
        ereturn scalar N_ledger = `bridge_K'
        ereturn scalar N_posted = `bridge_npost'
        ereturn scalar point_only = `bridge_point_only'
        ereturn scalar critical_value = `bridge_critical'
        ereturn scalar normal_critical_value = `bridge_normal'
        ereturn scalar wald_N_clusters = `bridge_wald_C'
        ereturn scalar wald_df = `bridge_wald_df'
        ereturn scalar wald_statistic = `bridge_wald_stat'
        ereturn scalar wald_p = `bridge_wald_p'
        ereturn local wald_status "`bridge_wald_status'"
        ereturn local wald_reason `"`bridge_wald_reason'"'
        ereturn local sample_scope "e(sample) marks the observations used in estimation"
        ereturn local covariance_scale "e(V) is the estimator covariance; e(V_asymptotic) is N_full times e(V)"
        ereturn local se_scale "e(se) holds the reported standard errors (multiplier-bootstrap IQR when requested); e(analytic_se) is sqrt(diagonal(e(V)))"
        ereturn local coefficient_map "e(coef_map): posted position and the corresponding row of the complete results table"
        if `bridge_npost' {
            ereturn matrix se = `se'
            ereturn matrix analytic_se = `analytic'
            ereturn matrix ci = `ci'
            ereturn matrix ci_pointwise = `pointci'
            ereturn matrix coef_map = `mapping'
            if `bridge_hasV' ereturn matrix V_asymptotic = `Omega'
        }
        if `"`saving'"'!="" {
            mata: cdid_bridge_save(st_local("newtoken"),st_local("saving"),st_local("request"))
            ereturn local state_file `"`saving'"'
        }
        _estimates unhold `held', not
    }
    local failure=_rc
    if `failure' {
        if `"`newtoken'"'!="" capture mata: cdid_state_drop(st_local("newtoken"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `caller_sort_rng'
    if `failure' exit `failure' 
    if `"`bridge_warning'"'!="" display as text `"`bridge_warning'"'
end
