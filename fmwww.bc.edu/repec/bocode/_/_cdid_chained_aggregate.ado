*! Private chained no-refit aggregation transaction; current StataNow19.5.
program define _cdid_chained_aggregate, eclass
    version 19.5
    syntax, [TYPE(string) TOKEN(string) MINE(string) MAXE(string) BALANCEE(string) NARM ///
        BSTRAP(string) CBAND(integer -1) BITERS(string) Level(string) CLUSTER(string) ///
        WORKSPACE(real 1073741824) CHUNK(integer 1024) POSTING(string) SAVING(string) ///
        REQUEST(name) AGGRequest(name) SIGNS(name) SIGNMode(string) FINISH]
    if "`aggrequest'"=="" & !inlist("`type'","simple","group","dynamic","calendar") {
        display as error "chained aggregation requires simple, group, dynamic, or calendar"
        exit 198
    }
    if ("`request'"!="" & "`aggrequest'"=="") | ("`request'"=="" & "`aggrequest'"!="") {
        display as error "request() and aggrequest() must be supplied together"
        exit 198
    }
    if "`bstrap'"=="" local bstrap "-1"
    else if !inlist("`bstrap'","-1","0","1",".") {
        confirm number `bstrap'
    }
    foreach numeric_option in mine maxe balancee level {
        if "``numeric_option''"=="" local `numeric_option' "."
        else if inlist("``numeric_option''",".",".a",".b") local `numeric_option' "."
        else confirm number ``numeric_option''
    }
    if "`biters'"=="" local biters "-1"
    else if inlist("`biters'",".",".a",".b") local biters "."
    else confirm number `biters'
    if "`token'"=="" local token `"`e(state_token)'"'
    if "`posting'"=="" local posting "matrix"
    if "`cluster'"=="" local cluster "inherit"
    if "`signmode'"=="" local signmode = cond("`signs'"=="","caller","fixed")
    if !inlist("`signmode'","caller","fixed") | ("`signmode'"=="caller" & "`signs'"!="") {
        display as error "signmode() must be caller or fixed; caller mode cannot also supply signs()"
        exit 198
    }
    foreach item in ivar time gvar clustvar depvar covariates cmdline title {
        local prior_`item' `"`e(`item')'"'
    }
    tempname held req_auto agg_auto b V Omega se analytic ci pointci mapping prior_r
    tempvar heldsample fitsample
    local newtoken ""
    local req_use "`request'"
    local agg_use "`aggrequest'"
    if "`req_use'"=="" local req_use "`req_auto'"
    if "`agg_use'"=="" local agg_use "`agg_auto'"
    local caller_sort_rng `"`c(sortrngstate)'"'
    _return hold `prior_r'
    capture noisily {
        _estimates hold `held', copy restore nullok varname(`heldsample')
        quietly mata: mata mlib index
        mata: st_local("newtoken", cdid_chained_agg_stage(st_local("token"), ///
            st_local("type"), `mine', `maxe', `balancee', ("`narm'"!=""), ///
            st_local("bstrap"), `cband', st_local("biters"), `level', ///
            `workspace', `chunk', st_local("posting"), st_local("cluster"), ///
            st_local("request"), st_local("aggrequest"), st_local("req_use"), ///
            st_local("agg_use"), st_local("signs"), st_local("signmode"), ///
            st_local("b"), st_local("V"), st_local("Omega"), st_local("se"), ///
            st_local("analytic"), st_local("ci"), st_local("pointci"), ///
            st_local("mapping"), `=c(max_matdim)'))
        quietly generate byte `fitsample' = e(sample)
        if `bridge_npost' {
            if `bridge_hasV' ereturn post `b' `V', obs(`bridge_N') properties(b V)
            else ereturn post `b', obs(`bridge_N') properties(b)
        }
        else ereturn post, obs(`bridge_N') properties("")
        ereturn repost, esample(`fitsample')
        ereturn local cmd "cdid"
        ereturn local mode "chained"
        ereturn local estat_cmd "cdid_estat"
        foreach setting in method gmm_weighting gmm_covariance base_period control_group pt_assumption ///
            selection selection_canonical selection_model selection_pooling selection_universe ///
            selection_est_method imputation_pooling outcome_pooling weight_source weight_reduction fix_weights_requested {
            ereturn local `setting' `"`bridge_`setting''"'
        }
        ereturn local subcmd "`bridge_agg_type'"
        ereturn local agg_type "`bridge_agg_type'"
        ereturn local state_token `"`newtoken'"'
        ereturn local source_state_token ""
        ereturn local result_kind "`bridge_kind'"
        ereturn local result_status "`bridge_status'"
        ereturn local inference_status "`bridge_inference_status'"
        ereturn local flag_law "`bridge_flags'"
        ereturn local warning `"`bridge_warning'"'
        ereturn local posting_mode "`bridge_posting_mode'"
        if "`bridge_posting_mode'"=="state" ereturn local posting_reason "posting(state): complete results stored without e(b) and e(V)"
        else ereturn local posting_reason "finite coefficients posted; e(coef_map) gives their rows in the complete results table"
        ereturn local multiplier_source "`signmode' random-number stream; multiplier draws only when requested"
        ereturn local rng_mode "`bridge_rng_mode'"
        ereturn local selector_warning `"`macval(bridge_selector_warning)'"'
        ereturn local target_definition `"`bridge_target_def'"'
        ereturn local band_family "`bridge_band_family'"
        ereturn local overall_status "`bridge_overall_status'"
        ereturn local overall_reason `"`bridge_overall_reason'"'
        ereturn local overall_inference_status "`bridge_overall_inf_status'"
        ereturn local overall_inference_kind "`bridge_overall_inf_kind'"
        ereturn local wald_status "`bridge_wald_status'"
        ereturn local wald_reason `"`bridge_wald_reason'"'
        ereturn local sample_scope "e(sample) marks the observations used in estimation"
        ereturn local covariance_scale "e(V) is the estimator covariance; e(V_asymptotic) is N_full times e(V)"
        ereturn local se_scale "e(se) holds the reported standard errors (multiplier-bootstrap IQR when requested); e(analytic_se) is sqrt(diagonal(e(V)))"
        ereturn local coefficient_map "e(coef_map): posted position and the corresponding row of the complete results table"
        ereturn scalar alpha = `bridge_alpha'
        ereturn scalar level = `=100*(1-`bridge_alpha')'
        ereturn scalar B_requested = `bridge_B'
        ereturn scalar bstrap_requested = `bridge_bstrap'
        ereturn scalar cband_requested = `bridge_cband'
        ereturn scalar bstrap = `bridge_bstrap'
        ereturn scalar cband = `bridge_cband'
        ereturn scalar clustered = `bridge_clustered'
        ereturn scalar N_source_cells = `bridge_N_source'
        ereturn scalar N_full = `bridge_N'
        ereturn scalar N_clusters = `bridge_C'
        ereturn scalar N_ledger = `bridge_K'
        ereturn scalar N_targets = `bridge_K'
        ereturn scalar N_posted = `bridge_npost'
        ereturn scalar point_only = `bridge_point_only'
        ereturn scalar critical_value = `bridge_critical'
        ereturn scalar normal_critical_value = `bridge_normal'
        ereturn scalar wald_N_clusters = `bridge_wald_C'
        ereturn scalar wald_df = `bridge_wald_df'
        ereturn scalar wald_statistic = `bridge_wald_stat'
        ereturn scalar wald_p = `bridge_wald_p'
        ereturn scalar na_rm = `bridge_na_rm'
        ereturn scalar min_e = `bridge_min_e'
        ereturn scalar max_e = `bridge_max_e'
        ereturn scalar balance_e = `bridge_balance_e'
        ereturn scalar overall_att = `bridge_overall_est'
        ereturn scalar overall_se = `bridge_overall_se'
        ereturn scalar overall_analytic_se = `bridge_overall_analytic_se'
        ereturn scalar overall_ci_low = `bridge_overall_ci_lo'
        ereturn scalar overall_ci_high = `bridge_overall_ci_hi'
        ereturn scalar draws_used = `bridge_draws_used'
        ereturn scalar n_draws = `bridge_n_draws'
        ereturn scalar overall_draws_used = `bridge_overall_draws_used'
        ereturn scalar overall_n_draws = `bridge_overall_n_draws'
        if `bridge_npost' {
            ereturn matrix se = `se'
            ereturn matrix analytic_se = `analytic'
            ereturn matrix ci = `ci'
            ereturn matrix ci_pointwise = `pointci'
            ereturn matrix coef_map = `mapping'
            if `bridge_hasV' ereturn matrix V_asymptotic = `Omega'
        }
        if `"`saving'"'!="" {
            mata: cdid_bridge_save(st_local("newtoken"), st_local("saving"), st_local("req_use"))
            ereturn local state_file `"`saving'"'
        }
        if "`finish'"!="" {
            local agg_cluster "`prior_clustvar'"
            if !inlist("`cluster'","inherit","") local agg_cluster "`cluster'"
            gettoken prior_title : prior_title, parse(":")
            if `"`prior_title'"'=="" local prior_title "Chained difference-in-differences"
            _cdid_post_finish, title(`"`prior_title': `type' aggregation"') endpoint(`type') ///
                ivar(`prior_ivar') time(`prior_time') gvar(`prior_gvar') clustvar(`agg_cluster') ///
                depvar(`prior_depvar') covariates(`prior_covariates')
            if `"`prior_cmdline'"'!="" ereturn local cmdline `"`prior_cmdline'"'
            mata: cdid_chain_copy(st_local("token"), st_global("e(state_token)"))
        }
        mata: cdid_chained_agg_replay(st_global("e(state_token)"))
        _estimates unhold `held', not
    }
    local failure = _rc
    capture mata: rmexternal(st_local("req_auto"))
    capture mata: rmexternal(st_local("agg_auto"))
    if `failure' {
        if `"`newtoken'"'!="" capture mata: cdid_state_drop(st_local("newtoken"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `caller_sort_rng'
    _return restore `prior_r'
    if `failure' exit `failure'
end
