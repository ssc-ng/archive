*! version 1.0.0.0  16nov2026
*! cdid_pretest_load: load results saved by cdid_pretest
program define cdid_pretest_load, rclass
    version 19.5
    tempname prior_r
    _return hold `prior_r'
    capture noisily {
        syntax using/ [, STORE(name) POSTING(string) WORKSPACE(real 1073741824)]
        if "`posting'" == "" local posting "matrix"
        if !inlist("`posting'", "matrix", "state") {
            display as error "posting() must be matrix or state"
            exit 198
        }
        if "`posting'" == "state" & "`store'" == "" {
            display as error "posting(state) requires store(name), which names the stored results"
            exit 198
        }
        if `workspace' < 8 | missing(`workspace') | `workspace' != floor(`workspace') | `workspace' > 9007199254740991 {
            display as error "workspace() must be an integer number of bytes, at least 8"
            exit 198
        }
    }
    local syntax_rc=_rc
    if `syntax_rc' {
        _return restore `prior_r'
        return add
        exit `syntax_rc'
    }
    local entries = max(1, floor(`workspace' / 8))
    local caller_rng `"`c(rngstate)'"'
    local caller_sort_rng `"`c(sortrngstate)'"'
    tempname held result stats draws family grid
    tempvar heldsample
    local made_result = 0
    local made_user = 0
    _estimates hold `held', copy restore nullok varname(`heldsample')
    capture noisily {
        quietly mata: mata mlib index
        if "`store'" != "" mata: cdid_pt_assert_free(st_local("store"))
        mata: cdid_pt_load(st_local("using"), "`result'", `entries')
        local made_result = 1
        mata: cdid_pt_export("`result'", "`stats'", "`draws'", "`family'", "`grid'", ///
            st_local("posting"), `=c(max_matdim)', `entries')
        mata: cdid_pt_load_meta("`result'")
        if "`store'" != "" {
            mata: cdid_pt_put(st_local("store"), *findexternal("`result'"), `entries')
            local made_user = 1
        }
    }
    local rc = _rc
    if `made_result' capture mata: rmexternal("`result'")
    capture _estimates unhold `held'
    quietly set sortrngstate `caller_sort_rng'
    quietly set rngstate `caller_rng'
    if `rc' {
        if `made_user' capture mata: rmexternal(st_local("store"))
        _return restore `prior_r'
        return add
        exit `rc'
    }
    _return drop `prior_r'
    return clear
    local j = 0
    foreach stat in N M K C B alpha CvM CvMcval CvMpval N_distinct N_rows N_requested N_input {
        local ++j
        return scalar `stat' = `stats'[1, `j']
    }
    if "`posting'" == "matrix" {
        if `pt_draws' > 0 return matrix CvMb = `draws'
        if `pt_family' > 0 {
            matrix colnames `family' = `pt_family_columns'
            return matrix family = `family'
        }
        if `pt_grid' > 0 {
            matrix colnames `grid' = first_grid_row multiplicity
            return matrix grid = `grid'
        }
    }
    return local status "`pt_status'"
    return local reason `"`pt_reason'"'
    return local mode "`pt_mode'"
    return local method "`pt_method'"
    return local outcome_pooling "`pt_outcome_pooling'"
    return local formula `"`pt_formula'"'
    return local X_columns `"`pt_xcols'"'
    return local Z_columns `"`pt_zcols'"'
    return local clustervars `"`pt_cluster'"'
    return local state_token "`store'"
    return local state_file `"`using'"'
    return local posting "`posting'"
    return local rng "`pt_rng'"
    return local description `"`pt_policy'"'
    return local influence_function `"`pt_channel'"'
    return local grid_rule `"`pt_membership'"'
    return scalar bstrap_requested = `pt_bstrap_req'
    return scalar cband_requested = `pt_cband_req'
    return scalar multipliers_used = `pt_used'
    return scalar rcs_dr_corrected_if = `pt_d1_exc'
    return scalar formula_defaulted = `pt_rf04_form'
    return scalar id_defaulted = `pt_rf04_id'
    return scalar allowunbalanced_supplied = `pt_allow_sup'
    return local allowunbalanced_requested "`pt_allow_req'"
    _cdid_pretest_display, stats(`stats') mode(`pt_mode') method(`pt_method') status(`pt_status') ///
        reason(`"`pt_reason'"') clustervars(`pt_cluster')
end
