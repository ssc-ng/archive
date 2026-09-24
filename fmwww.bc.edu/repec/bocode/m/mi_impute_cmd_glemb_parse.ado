*! version 0.1.3 19may2026
program define mi_impute_cmd_glemb_parse
    version 17.0

    syntax anything(equalok) [if] [, * ]

    gettoken ivars rest : anything, parse("=")
    gettoken eq xvars : rest, parse("=")
    if `"`eq'"' != "=" {
        local xvars
    }

    unab ivars : `ivars'
    if `"`xvars'"' != "" {
        unab xvars : `xvars'
    }

    tempvar glemb_parse_touse
    quietly gen byte `glemb_parse_touse' = 1 `if'
    quietly replace `glemb_parse_touse' = 0 if missing(`glemb_parse_touse')
    local softmissing = 0
    local extvars
    foreach v of local ivars {
        quietly count if `glemb_parse_touse' & `v' == .
        local softmissing = `softmissing' + r(N)
        quietly count if `glemb_parse_touse' & `v' > .
        if (r(N) > 0) {
            local extvars `extvars' `v'
        }
    }
    local extvars : list uniq extvars
    if "`extvars'" != "" {
        di as txt "note: extended missing values (.a-.z) in imputation variables will not be imputed: `extvars'"
    }
    if (`softmissing' == 0) {
        di as err "no ordinary missing values found in imputation variables"
        if "`extvars'" != "" {
            di as err "extended missing values (.a-.z) are left unchanged by mi impute glemb"
        }
        exit 498
    }

    u_mi_impute_user_setup `if', ivars(`ivars') xvars(`xvars') ///
        title1("Multiple imputation") ///
        title2("General location EMB") ///
        `options'

    local 0 , `options'
    syntax [, PROFILE * ]
    if "`profile'" != "" {
        global MI_IMPUTE_GLEMB_profile 1
        global MI_IMPUTE_GLEMB_n 0
        global MI_IMPUTE_GLEMB_nonconv 0
        global MI_IMPUTE_GLEMB_iter_sum 0
        global MI_IMPUTE_GLEMB_iter_max 0
        global MI_IMPUTE_GLEMB_read 0
        global MI_IMPUTE_GLEMB_bootstrap 0
        global MI_IMPUTE_GLEMB_pseudo 0
        global MI_IMPUTE_GLEMB_boot_prelim 0
        global MI_IMPUTE_GLEMB_ecm 0
        global MI_IMPUTE_GLEMB_orig_prelim 0
        global MI_IMPUTE_GLEMB_impute 0
        global MI_IMPUTE_GLEMB_store 0
        global MI_IMPUTE_GLEMB_estep 0
        global MI_IMPUTE_GLEMB_mstep 0
        global MI_IMPUTE_GLEMB_ipf 0
        global MI_IMPUTE_GLEMB_det_rows 0
        global MI_IMPUTE_GLEMB_det_weight 0
        global MI_IMPUTE_GLEMB_active_rows 0
        global MI_IMPUTE_GLEMB_active_weight 0
    }
end
