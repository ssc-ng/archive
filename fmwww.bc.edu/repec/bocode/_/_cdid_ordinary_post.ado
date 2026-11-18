*! Ordinary no-refit state consumer, current StataNow19.5.
program define _cdid_ordinary_post, eclass
    version 19.5
    syntax, TOKEN(string) LIMITS(name) POSTING(string) [SAVING(string)]
    tempname held b V Omega sourceV sourceOmega se analytic ci pointci mapping
    tempvar heldsample
    local newtoken ""
    local caller_sort `"`c(sortrngstate)'"'
    capture noisily {
        _estimates hold `held', copy restore nullok varname(`heldsample')
        mata: st_local("newtoken",cdid_ord_post_stage(st_local("token"),st_local("limits"),st_local("posting"), ///
            st_local("b"),st_local("V"),st_local("Omega"),st_local("sourceV"),st_local("sourceOmega"), ///
            st_local("se"),st_local("analytic"),st_local("ci"),st_local("pointci"),st_local("mapping"),`=c(max_matdim)'))
        if `ord_npost' {
            if `ord_hasV' ereturn post `b' `V', obs(`ord_N') properties(b V)
            else ereturn post `b', obs(`ord_N') properties(b)
        }
        else ereturn post, obs(`ord_N') properties("")
        ereturn local cmd "_cdid_ordinary_post"
        ereturn local mode "ordinary"
        ereturn local state_token `"`newtoken'"'
        ereturn local source_state_token `"`token'"'
        ereturn local result_kind "`ord_kind'"
        ereturn local posting_mode "`posting'"
        ereturn local warning `"`ord_warning'"'
        ereturn local covariance_origin `"`ord_covariance_origin'"'
        ereturn local covariance_scale "e(V) is the estimator covariance; e(V_asymptotic) is N_full times e(V)"
        ereturn local se_scale "e(se) holds the reported standard errors (multiplier-bootstrap IQR when requested, analytical otherwise); e(analytic_se) is sqrt(diagonal(e(V)))"
        ereturn local source_covariance_scale "group-time cells only: e(V_source_asymptotic) is the analytical covariance of the ordinary estimator; e(V_source) is that matrix divided by N_full"
        ereturn local sample_scope "e(sample) marks the observations used in estimation"
        ereturn local conditional_test_status "use cdid_pretest for the conditional pretrend test"
        ereturn local wald_status "`ord_wald_status'"
        ereturn local wald_reason `"`ord_wald_reason'"'
        ereturn scalar N_full=`ord_N'
        ereturn scalar N_clusters=`ord_C'
        ereturn scalar clustered=`ord_clustered'
        ereturn scalar N_ledger=`ord_sourceK'
        ereturn scalar N_targets=`ord_K'
        ereturn scalar N_posted=`ord_npost'
        ereturn scalar point_only=`ord_point_only'
        ereturn scalar alpha=`ord_alpha'
        ereturn scalar level = `=100*(1-`ord_alpha')'
        ereturn scalar B_requested=`ord_B'
        ereturn scalar bstrap=`ord_bstrap'
        ereturn scalar cband=`ord_cband'
        ereturn scalar critical_value=`ord_critical'
        ereturn scalar normal_critical_value=`ord_normal'
        ereturn scalar wald_df=`ord_wald_df'
        ereturn scalar wald_statistic=`ord_wald_statistic'
        ereturn scalar wald_p=`ord_wald_p'
        ereturn scalar wald_p_unrounded=`ord_wald_p_unrounded'
        if `ord_npost' {
            ereturn matrix se=`se'
            ereturn matrix analytic_se=`analytic'
            ereturn matrix ci=`ci'
            ereturn matrix ci_pointwise=`pointci'
            ereturn matrix coef_map=`mapping'
            if `ord_hasV' ereturn matrix V_asymptotic=`Omega'
            if `ord_has_sourceV' {
                ereturn matrix V_source=`sourceV'
                ereturn matrix V_source_asymptotic=`sourceOmega'
            }
        }
        if `"`saving'"'!="" {
            mata: cdid_ord_save(st_local("newtoken"),st_local("saving"),st_local("limits"))
            ereturn local state_file `"`saving'"'
        }
        _estimates unhold `held', not
    }
    local failure=_rc
    if `failure' {
        if `"`newtoken'"'!="" capture mata: cdid_state_drop(st_local("newtoken"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `caller_sort'
    if `failure' exit `failure'
end
