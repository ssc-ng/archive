*! version 0.1.3 19may2026
program define mi_impute_cmd_glemb, rclass
    version 17.0

    syntax [, NOMS(varlist numeric) CATINTeract(integer 2) ///
        CATPRior(real -1) EMPRI(real -1) MAXITS(integer 1000) ///
        MEANMODEL(string) PROFILE * ]

    if `"`options'"' != "" {
        di as err "options not allowed: `options'"
        exit 198
    }

    capture mata: glemb_make_margins(1, 2)
    if (_rc) {
        findfile lglemb.mata
        quietly do "`r(fn)'"
    }

    if "`noms'" == "" {
        di as err "noms() must specify at least one categorical variable"
        exit 198
    }

    if !inlist(`catinteract', 2, 3) {
        di as err "catinteract() must be 2 or 3"
        exit 198
    }

    if `"`meanmodel'"' == "" {
        local meanmodel main
    }
    local meanmodel = lower(`"`meanmodel'"')
    if !inlist(`"`meanmodel'"', "main", "saturated") {
        di as err "meanmodel() must be main or saturated"
        exit 198
    }
    local meanmodel_code = cond(`"`meanmodel'"' == "main", 1, 2)

    if (`catprior' < -1) {
        di as err "catprior() must be nonnegative"
        exit 198
    }

    if (`empri' < -1) {
        di as err "empri() must be nonnegative"
        exit 198
    }

    if (`maxits' < 1) {
        di as err "maxits() must be a positive integer"
        exit 198
    }

    local ivars $MI_IMPUTE_user_ivarsinc
    local xvars $MI_IMPUTE_user_xvars
    local touse $MI_IMPUTE_user_touse
    quietly count if `touse'
    local n = r(N)
    local modelvars `ivars' `xvars'
    local modelvars : list uniq modelvars

    local badnoms : list noms - modelvars
    if "`badnoms'" != "" {
        di as err "noms() variables must be included in the imputation model: `badnoms'"
        exit 198
    }

    local badx : list ivars & xvars
    if "`badx'" != "" {
        di as err "imputation variables may not also be predictors: `badx'"
        exit 198
    }

    local continuous : list modelvars - noms
    if "`continuous'" == "" {
        di as err "glemb requires at least one continuous variable not listed in noms()"
        exit 198
    }
    local nmodelvars : word count `modelvars'
    if (`n' < 5 * `nmodelvars') {
        di as txt "note: imputation sample is small relative to the number of model variables; results may be unstable"
    }

    foreach v of local xvars {
        quietly count if `touse' & missing(`v')
        if (r(N) > 0) {
            di as err "complete predictor `v' contains missing values in the imputation sample"
            exit 498
        }
    }

    local p : word count `noms'
    local q : word count `continuous'
    local ncells = 1
    local maxcells = 50000
    local maxcompat = 50000000
    local j = 0
    foreach v of local noms {
        local ++j
        quietly levelsof `v' if `touse' & !missing(`v'), local(levels`j')
        local k : word count `levels`j''
        if (`k' < 2) {
            di as err "categorical variable `v' has fewer than 2 observed categories"
            exit 498
        }
        if (`k' > 20) {
            di as err "categorical variable `v' has `k' observed categories; maximum is 20"
            exit 498
        }
        local ncells = `ncells' * `k'
    }
    if (`ncells' > `maxcells') {
        di as err "categorical variables define " as res %12.0fc `ncells' ///
            as err " cells; maximum allowed is " as res %12.0fc `maxcells'
        di as err "reduce the number of variables in noms() or combine sparse categories"
        exit 498
    }
    if (`n' * `ncells' > `maxcompat') {
        di as err "imputation sample and categorical cells imply " ///
            as res %12.0fc (`n' * `ncells') as err " row-cell checks"
        di as err "maximum allowed is " as res %12.0fc `maxcompat'
        di as err "reduce the number of variables in noms() or combine sparse categories"
        exit 498
    }
    if (`catprior' == 0) {
        local nomisscond `touse'
        foreach v of local noms {
            local nomisscond `nomisscond' & !missing(`v')
        }
        tempvar cellgrp
        quietly egen long `cellgrp' = group(`noms') if `nomisscond'
        quietly levelsof `cellgrp' if `nomisscond', local(obscells)
        local n_obscells : word count `obscells'
        if (`n_obscells' < `ncells') {
            di as err "catprior(0) is not allowed with empty observed categorical cells"
            di as err "observed cells = " as res %12.0fc `n_obscells' ///
                as err "; possible cells = " as res %12.0fc `ncells'
            di as err "specify catprior()>0 or combine sparse categories"
            exit 498
        }
    }

    foreach v of local continuous {
        quietly summarize `v' if `touse' & !missing(`v'), meanonly
        if (r(N) == 0) {
            di as err "continuous variable `v' has no observed values"
            di as err "remove it or supply observed values before imputing"
            exit 498
        }
        else if (r(min) == r(max)) {
            di as err "continuous variable `v' has no variance"
            exit 498
        }
    }

    local catprior_resolved = cond(`catprior' < 0, 1 / `ncells', `catprior')
    local eps = 0.0001

    tempvar order
    quietly gen long `order' = _n

    local wvars
    local outvars
    local j = 0
    foreach v of local noms {
        local ++j
        tempvar w`j' outw`j'
        quietly gen double `w`j'' = .
        quietly gen double `outw`j'' = .
        local code = 0
        foreach lev of local levels`j' {
            local ++code
            quietly replace `w`j'' = `code' if `touse' & `v' == `lev'
        }
        local wvars `wvars' `w`j''
        local outvars `outvars' `outw`j''
    }

    local zvars `continuous'
    local k = 0
    foreach v of local zvars {
        local ++k
        tempvar outz`k'
        quietly gen double `outz`k'' = .
        local outvars `outvars' `outz`k''
    }

    tempname iter conv p_read p_boot p_pseudo p_bootprelim p_ecm p_origprelim
    tempname p_impute p_store p_estep p_mstep p_ipf
    tempname p_detrow p_detwt p_activerow p_activewt

    if "`profile'" != "" {
        mata: glemb_stata_emb_once_profile("`wvars'", "`zvars'", "`touse'", ///
            "`outvars'", "`iter'", "`conv'", ///
            "`p_read'", "`p_boot'", "`p_pseudo'", "`p_bootprelim'", ///
            "`p_ecm'", "`p_origprelim'", "`p_impute'", "`p_store'", ///
            "`p_estep'", "`p_mstep'", "`p_ipf'", ///
            "`p_detrow'", "`p_detwt'", "`p_activerow'", "`p_activewt'", ///
            `catinteract', `meanmodel_code', `catprior_resolved', `maxits', `eps')
    }
    else {
        mata: glemb_stata_emb_once("`wvars'", "`zvars'", "`touse'", ///
            "`outvars'", "`iter'", "`conv'", ///
            `catinteract', `meanmodel_code', `catprior_resolved', `maxits', `eps')
    }

    local j = 0
    foreach v of local noms {
        local ++j
        local outw : word `j' of `outvars'
        local missvar
        forvalues i = 1/$MI_IMPUTE_user_k_ivarsinc {
            if "`v'" == "${MI_IMPUTE_user_ivar`i'}" {
                local missvar ${MI_IMPUTE_user_miss`i'}
            }
        }
        if "`missvar'" != "" {
            local code = 0
            foreach lev of local levels`j' {
                local ++code
                quietly replace `v' = `lev' if `missvar' == 1 & `v' == . & round(`outw') == `code'
            }
        }
    }

    local k = 0
    foreach v of local zvars {
        local ++k
        local outz : word `=`p' + `k'' of `outvars'
        local missvar
        forvalues i = 1/$MI_IMPUTE_user_k_ivarsinc {
            if "`v'" == "${MI_IMPUTE_user_ivar`i'}" {
                local missvar ${MI_IMPUTE_user_miss`i'}
            }
        }
        if "`missvar'" != "" {
            quietly replace `v' = `outz' if `missvar' == 1 & `v' == .
        }
    }

    quietly sort `order'
    quietly drop `order' `wvars' `outvars'

    return scalar iterations = scalar(`iter')
    return scalar converged = scalar(`conv')
    return scalar catprior = `catprior_resolved'
    return local meanmodel `meanmodel'
    if "`profile'" != "" {
        local n = ${MI_IMPUTE_GLEMB_n} + 1
        global MI_IMPUTE_GLEMB_n `n'
        local iter_b = scalar(`iter')
        local conv_b = scalar(`conv')
        local nonconv = ${MI_IMPUTE_GLEMB_nonconv} + (`conv_b' == 0)
        global MI_IMPUTE_GLEMB_nonconv `nonconv'
        local iter_sum = ${MI_IMPUTE_GLEMB_iter_sum} + `iter_b'
        global MI_IMPUTE_GLEMB_iter_sum `iter_sum'
        local iter_max = max(${MI_IMPUTE_GLEMB_iter_max}, `iter_b')
        global MI_IMPUTE_GLEMB_iter_max `iter_max'
        local read = ${MI_IMPUTE_GLEMB_read} + scalar(`p_read')
        global MI_IMPUTE_GLEMB_read `read'
        local bootstrap = ${MI_IMPUTE_GLEMB_bootstrap} + scalar(`p_boot')
        global MI_IMPUTE_GLEMB_bootstrap `bootstrap'
        local pseudo = ${MI_IMPUTE_GLEMB_pseudo} + scalar(`p_pseudo')
        global MI_IMPUTE_GLEMB_pseudo `pseudo'
        local boot_prelim = ${MI_IMPUTE_GLEMB_boot_prelim} + scalar(`p_bootprelim')
        global MI_IMPUTE_GLEMB_boot_prelim `boot_prelim'
        local ecm = ${MI_IMPUTE_GLEMB_ecm} + scalar(`p_ecm')
        global MI_IMPUTE_GLEMB_ecm `ecm'
        local orig_prelim = ${MI_IMPUTE_GLEMB_orig_prelim} + scalar(`p_origprelim')
        global MI_IMPUTE_GLEMB_orig_prelim `orig_prelim'
        local impute = ${MI_IMPUTE_GLEMB_impute} + scalar(`p_impute')
        global MI_IMPUTE_GLEMB_impute `impute'
        local store = ${MI_IMPUTE_GLEMB_store} + scalar(`p_store')
        global MI_IMPUTE_GLEMB_store `store'
        local estep = ${MI_IMPUTE_GLEMB_estep} + scalar(`p_estep')
        global MI_IMPUTE_GLEMB_estep `estep'
        local mstep = ${MI_IMPUTE_GLEMB_mstep} + scalar(`p_mstep')
        global MI_IMPUTE_GLEMB_mstep `mstep'
        local ipf = ${MI_IMPUTE_GLEMB_ipf} + scalar(`p_ipf')
        global MI_IMPUTE_GLEMB_ipf `ipf'
        local det_rows = ${MI_IMPUTE_GLEMB_det_rows} + scalar(`p_detrow')
        global MI_IMPUTE_GLEMB_det_rows `det_rows'
        local det_weight = ${MI_IMPUTE_GLEMB_det_weight} + scalar(`p_detwt')
        global MI_IMPUTE_GLEMB_det_weight `det_weight'
        local active_rows = ${MI_IMPUTE_GLEMB_active_rows} + scalar(`p_activerow')
        global MI_IMPUTE_GLEMB_active_rows `active_rows'
        local active_weight = ${MI_IMPUTE_GLEMB_active_weight} + scalar(`p_activewt')
        global MI_IMPUTE_GLEMB_active_weight `active_weight'

        return scalar profile_ecm = scalar(`p_ecm')
        return scalar profile_estep = scalar(`p_estep')
        return scalar profile_mstep = scalar(`p_mstep')
        return scalar profile_ipf = scalar(`p_ipf')
        return scalar profile_det_rows = scalar(`p_detrow')
        return scalar profile_active_rows = scalar(`p_activerow')
    }
end
