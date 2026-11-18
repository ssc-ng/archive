*! version 1.0.0.0  16nov2026
*! cdid_load: load results saved by cdid or estat
program define cdid_load, eclass
    version 19.5
    local caller_cmdline `"cdid_load `0'"'
    syntax using/ [, POSTING(string) WORKSPACE(real 1073741824)]
    if "`posting'" == "" local posting "matrix"
    if !inlist("`posting'", "matrix", "state") {
        display as error "posting() must be matrix or state"
        exit 198
    }
    if `workspace' < 8 | missing(`workspace') | `workspace' != floor(`workspace') | `workspace' > 9007199254740991 {
        display as error "workspace() must be an integer number of bytes, at least 8"
        exit 198
    }
    local caller_rng `"`c(rngstate)'"'
    local caller_sort_rng `"`c(sortrngstate)'"'
    tempname held limits prior_r b V Omega se analytic ci pointci mapping
    tempvar heldsample
    local loaded_token ""
    local final_token ""
    _return hold `prior_r'
    _estimates hold `held', copy restore nullok varname(`heldsample')
    capture noisily {
        quietly mata: mata mlib index
        mata: st_local("loaded_token", cdid_public_load_open(st_local("using"), `workspace', st_local("limits")))
        if "`pload_mode'" == "ordinary" {
            _cdid_ordinary_post, token("`loaded_token'") limits(`limits') posting(`posting')
            local final_token `"`e(state_token)'"'
            mata: cdid_state_drop(st_local("loaded_token"))
            local loaded_token ""
            ereturn local cmd "cdid"
            ereturn local cmdline `"`caller_cmdline'"'
            ereturn local mode "ordinary"
            ereturn local sample_scope "results loaded from a file; e(sample) is not set"
            ereturn local estat_cmd "cdid_estat"
            if `"`pload_depvar'"' != "" ereturn local depvar `"`pload_depvar'"'
            ereturn local source_state_token ""
            ereturn local state_file `"`using'"'
            mata: cdid_post_state_names(st_global("e(state_token)"))
            local load_kind = subinstr("`e(result_kind)'", "ordinary_", "", 1)
            local load_title "Difference-in-differences (ordinary mode)"
            if "`load_kind'"!="cells" local load_title "`load_title': `load_kind' aggregation"
            _cdid_post_finish, title("`load_title'") endpoint(`load_kind') ivar(`state_ivar') clustvar(`state_clustvar') ///
                time(`state_time') gvar(`state_gvar') depvar(`state_depvar') method(`state_method') covariates(`state_covariates')
            // As estimates use: the command line of the saved results (files saved by
            // earlier versions do not store it and keep the cdid_load command line)
            if `"`state_cmdline'"' != "" ereturn local cmdline `"`state_cmdline'"'
            mata: cdid_ord_replay(st_global("e(state_token)"))
        }
        else {
            mata: cdid_public_load_stage(st_local("loaded_token"), st_local("limits"), ///
                st_local("posting"), st_local("b"), st_local("V"), st_local("Omega"), ///
                st_local("se"), st_local("analytic"), st_local("ci"), ///
                st_local("pointci"), st_local("mapping"), `=c(max_matdim)')
            local final_token `"`loaded_token'"'
            local loaded_token ""
            if `bridge_npost' {
                if `bridge_hasV' ereturn post `b' `V', obs(`bridge_N') properties(b V)
                else ereturn post `b', obs(`bridge_N') properties(b)
            }
            else ereturn post, obs(`bridge_N') properties("")
            ereturn local cmd "cdid"
            ereturn local cmdline `"`caller_cmdline'"'
            ereturn local mode "chained"
            ereturn local estat_cmd "cdid_estat"
            if `"`pload_depvar'"' != "" ereturn local depvar `"`pload_depvar'"'
            foreach setting in method gmm_weighting gmm_covariance base_period control_group pt_assumption ///
                selection selection_canonical selection_model selection_pooling selection_universe ///
                selection_est_method imputation_pooling outcome_pooling selection_justification inactive_arguments ///
                weight_source weight_reduction fix_weights_requested {
                if `pl_has_`setting'' ereturn local `setting' `"`bridge_`setting''"'
            }
            if `bridge_has_anticipation' ereturn scalar anticipation = `bridge_anticipation'
            ereturn local state_token `"`final_token'"'
            ereturn local source_state_token ""
            ereturn local state_file `"`using'"'
            ereturn local result_kind "`bridge_kind'"
            ereturn local result_status "`bridge_status'"
            ereturn local inference_status "`bridge_inference_status'"
            ereturn local flag_law "`bridge_flags'"
            ereturn local warning `"`bridge_warning'"'
            ereturn local posting_mode "`bridge_posting_mode'"
            if "`bridge_posting_mode'" == "state" ereturn local posting_reason "posting(state): complete results stored without e(b) and e(V)"
            else ereturn local posting_reason "finite coefficients posted; e(coef_map) gives their rows in the complete results table"
            if `"`bridge_rng_mode'"' != "" ereturn local multiplier_source "`bridge_rng_mode' random-number stream; multiplier draws only when requested"
            else ereturn local multiplier_source "loaded results: no new multiplier draws"
            if `"`bridge_rng_mode'"' != "" ereturn local rng_mode "`bridge_rng_mode'"
            ereturn local wald_status "`bridge_wald_status'"
            ereturn local wald_reason `"`bridge_wald_reason'"'
            ereturn local sample_scope "results loaded from a file; e(sample) is not set"
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
            if `bridge_has_rng' {
                ereturn scalar draws_used = `bridge_draws_used'
                ereturn scalar n_draws = `bridge_n_draws'
            }
            if "`bridge_kind'" == "aggregation" {
                ereturn local subcmd "`bridge_agg_type'"
                ereturn local agg_type "`bridge_agg_type'"
                ereturn local selector_warning `"`macval(bridge_selector_warning)'"'
                ereturn local target_definition `"`bridge_target_def'"'
                ereturn local band_family "`bridge_band_family'"
                ereturn local overall_status "`bridge_overall_status'"
                ereturn local overall_reason `"`bridge_overall_reason'"'
                ereturn local overall_inference_status "`bridge_overall_inf_status'"
                ereturn local overall_inference_kind "`bridge_overall_inf_kind'"
                ereturn scalar na_rm = `bridge_na_rm'
                ereturn scalar min_e = `bridge_min_e'
                ereturn scalar max_e = `bridge_max_e'
                ereturn scalar balance_e = `bridge_balance_e'
                ereturn scalar overall_att = `bridge_overall_est'
                ereturn scalar overall_se = `bridge_overall_se'
                ereturn scalar overall_analytic_se = `bridge_overall_analytic_se'
                ereturn scalar overall_ci_low = `bridge_overall_ci_lo'
                ereturn scalar overall_ci_high = `bridge_overall_ci_hi'
                ereturn scalar overall_draws_used = `bridge_overall_draws_used'
                ereturn scalar overall_n_draws = `bridge_overall_n_draws'
            }
            if `bridge_npost' {
                ereturn matrix se = `se'
                ereturn matrix analytic_se = `analytic'
                ereturn matrix ci = `ci'
                ereturn matrix ci_pointwise = `pointci'
                ereturn matrix coef_map = `mapping'
                if `bridge_hasV' ereturn matrix V_asymptotic = `Omega'
            }
            mata: st_local("nuis_kept", strofreal(cdid_nuis_has(st_global("e(state_token)"))))
            if "`nuis_kept'"=="1" ereturn local nuisance "kept"
            mata: cdid_post_state_names(st_global("e(state_token)"))
            local load_kind "cells"
            local load_title "Chained difference-in-differences"
            if "`bridge_kind'" == "aggregation" {
                local load_kind "`bridge_agg_type'"
                local load_title "`load_title': `load_kind' aggregation"
            }
            _cdid_post_finish, title("`load_title'") endpoint(`load_kind') ivar(`state_ivar') clustvar(`state_clustvar') ///
                time(`state_time') gvar(`state_gvar') depvar(`state_depvar') method(`state_method') covariates(`state_covariates')
            if `"`state_cmdline'"' != "" ereturn local cmdline `"`state_cmdline'"'
            mata: cdid_public_load_display(st_global("e(state_token)"))
            capture mata: cdid_mref_load_post(st_global("e(state_token)"))
            if !_rc capture noisily mata: cdid_mref_note()
        }
        _estimates unhold `held', not
    }
    local rc = _rc
    if `"`loaded_token'"' != "" capture mata: cdid_state_drop(st_local("loaded_token"))
    capture mata: rmexternal(st_local("limits"))
    if `rc' {
        if `"`final_token'"' != "" capture mata: cdid_state_drop(st_local("final_token"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `caller_sort_rng'
    quietly set rngstate `caller_rng'
    _return restore `prior_r'
    if `rc' exit `rc'
end
