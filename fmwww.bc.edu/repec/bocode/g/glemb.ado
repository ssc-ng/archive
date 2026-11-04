*! version 0.1.3 19may2026
program define glemb, rclass
    version 17.0

    syntax varlist(numeric) [if] [in], NOMS(varlist numeric) ///
        [ ADD(integer 20) ID(varlist numeric) IDVARS(varlist numeric) CATINTeract(integer 2) ///
          CATPRior(real -1) EMPRI(real -1) MAXITS(integer 1000) ///
          MEANMODEL(string) SEED(integer -1) REPLACE SAVING(string asis) DOTS NOISILY DRYRUN PROFILE ]

    marksample touse, novarlist

    capture mata: glemb_make_margins(1, 2)
    if (_rc) {
        findfile lglemb.mata
        quietly do "`r(fn)'"
    }

    if (`add' < 1) {
        di as err "add() must be a positive integer"
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

    if (`seed' != -1 & (`seed' <= 0 | `seed' > 2000000000)) {
        di as err "seed() must be a positive integer no greater than 2,000,000,000"
        exit 198
    }

    if "`id'" != "" & "`idvars'" != "" {
        di as err "specify only one of id() or idvars()"
        exit 198
    }
    if "`id'" != "" {
        local idvars `id'
    }

    local overlap : list noms & idvars
    if "`overlap'" != "" {
        di as err "variables may not appear in both noms() and idvars(): `overlap'"
        exit 198
    }

    local modelvars `varlist'
    local badnoms : list noms - modelvars
    if "`badnoms'" != "" {
        di as err "noms() variables must be included in varlist: `badnoms'"
        exit 198
    }

    local continuous : list modelvars - noms
    local continuous : list continuous - idvars

    if "`noms'" == "" {
        di as err "noms() must specify at least one categorical variable"
        exit 198
    }

    if "`continuous'" == "" {
        di as err "glemb requires at least one continuous variable not listed in noms()"
        exit 198
    }

    local workvars `modelvars'
    local workvars : list workvars - idvars
    quietly count if `touse'
    local n = r(N)
    if (`n' == 0) {
        error 2000
    }
    local nmodelvars : word count `workvars'
    if (`n' < 5 * `nmodelvars') {
        di as txt "note: imputation sample is small relative to the number of model variables; results may be unstable"
    }

    local anymissing = 0
    local extvars
    foreach v of local workvars {
        quietly count if `touse' & `v' == .
        if (r(N) > 0) local anymissing = 1
        quietly count if `touse' & `v' > .
        if (r(N) > 0) {
            local extvars `extvars' `v'
        }
    }
    local extvars : list uniq extvars
    if "`extvars'" != "" {
        di as txt "note: extended missing values (.a-.z) will not be imputed: `extvars'"
    }
    if (!`anymissing') {
        di as err "no ordinary missing values found in imputation-model variables"
        if "`extvars'" != "" {
            di as err "extended missing values (.a-.z) are left unchanged by glemb"
        }
        exit 459
    }

    local p : word count `noms'
    local q : word count `continuous'
    tempname nlevels margins design
    matrix `nlevels' = J(1, `p', .)
    local ncells = 1
    local maxcells = 50000
    local maxcompat = 50000000
    local j = 0
    foreach v of local noms {
        local ++j
        quietly levelsof `v' if `touse' & !missing(`v'), local(levels)
        local k : word count `levels'
        if (`k' < 2) {
            di as err "categorical variable `v' has fewer than 2 observed categories"
            exit 459
        }
        if (`k' > 20) {
            di as err "categorical variable `v' has `k' observed categories; maximum is 20"
            exit 459
        }
        matrix `nlevels'[1, `j'] = `k'
        local ncells = `ncells' * `k'
    }
    if (`ncells' > `maxcells') {
        di as err "categorical variables define " as res %12.0fc `ncells' ///
            as err " cells; maximum allowed is " as res %12.0fc `maxcells'
        di as err "reduce the number of variables in noms() or combine sparse categories"
        exit 459
    }
    if (`n' * `ncells' > `maxcompat') {
        di as err "imputation sample and categorical cells imply " ///
            as res %12.0fc (`n' * `ncells') as err " row-cell checks"
        di as err "maximum allowed is " as res %12.0fc `maxcompat'
        di as err "reduce the number of variables in noms() or combine sparse categories"
        exit 459
    }

    foreach v of local continuous {
        quietly summarize `v' if `touse' & !missing(`v'), meanonly
        if (r(N) == 0) {
            di as err "continuous variable `v' has no observed values"
            di as err "remove it or supply observed values before imputing"
            exit 459
        }
        else if (r(min) == r(max)) {
            di as err "continuous variable `v' has no variance"
            exit 459
        }
    }

    mata: st_matrix("`margins'", glemb_make_margins(`p', `catinteract'))
    mata: st_matrix("`design'", glemb_make_mean_design(st_matrix("`nlevels'"), `meanmodel_code'))

    local catprior_resolved = cond(`catprior' < 0, 1 / `ncells', `catprior')
    local empri_resolved = cond(`empri' < 0, `q' / `n', `empri')

    return scalar N = `n'
    return scalar p = `p'
    return scalar q = `q'
    return scalar ncells = `ncells'
    return scalar add = `add'
    return scalar catinteract = `catinteract'
    return local meanmodel `meanmodel'
    return scalar catprior = `catprior_resolved'
    return scalar empri = `empri_resolved'
    return matrix nlevels = `nlevels'
    return matrix margins = `margins'

    if "`dryrun'" != "" {
        di as txt "glemb dry run: " as res `p' as txt " categorical, " ///
            as res `q' as txt " continuous, " as res `ncells' as txt " cells" ///
            as txt ", meanmodel(" as res "`meanmodel'" as txt ")"
        exit
    }

    if `"`saving'"' == "" {
        di as err "saving() is required for the standalone glemb scaffold"
        exit 198
    }

    local savebase `"`saving'"'
    local savebase : subinstr local savebase `"""' "", all
    if lower(substr(`"`savebase'"', -4, 4)) == ".dta" {
        local savebase = substr(`"`savebase'"', 1, length(`"`savebase'"') - 4)
    }

    tempvar order
    quietly gen long `order' = _n

    local wvars
    local outvars
    local catmapvars
    local j = 0
    foreach v of local noms {
        local ++j
        tempvar w`j' outw`j'
        quietly gen double `w`j'' = .
        quietly gen double `outw`j'' = .
        local code = 0
        quietly levelsof `v' if `touse' & !missing(`v'), local(levels`j')
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

    local eps = 0.0001
    tempname iter conv p_read p_boot p_pseudo p_bootprelim p_ecm p_origprelim
    tempname p_impute p_store p_estep p_mstep p_ipf
    tempname p_detrow p_detwt p_activerow p_activewt
    local nonconv = 0
    local iter_sum = 0
    local iter_max = 0
    local sec_sum = 0
    local sec_max = 0
    local prof_read = 0
    local prof_boot = 0
    local prof_pseudo = 0
    local prof_bootprelim = 0
    local prof_ecm = 0
    local prof_origprelim = 0
    local prof_impute = 0
    local prof_store = 0
    local prof_estep = 0
    local prof_mstep = 0
    local prof_ipf = 0
    local prof_detrow = 0
    local prof_detwt = 0
    local prof_activerow = 0
    local prof_activewt = 0

    di as txt "glemb: " as res `n' as txt " observations, " ///
        as res `p' as txt " categorical variable(s), " ///
        as res `q' as txt " continuous variable(s), " ///
        as res `ncells' as txt " categorical cell(s)"
    di as txt "glemb: add = " as res `add' ///
        as txt ", catprior = " as res %9.4g `catprior_resolved' ///
        as txt ", maxits = " as res `maxits' ///
        as txt ", meanmodel = " as res "`meanmodel'"

    forvalues b = 1/`add' {
        if (`seed' != -1) {
            set seed `=`seed' + `b''
        }

        timer clear 99
        timer on 99
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
        timer off 99
        quietly timer list 99
        local sec_b = r(t99)

        local iter_b = scalar(`iter')
        local conv_b = scalar(`conv')
        local iter_sum = `iter_sum' + `iter_b'
        local iter_max = max(`iter_max', `iter_b')
        local sec_sum = `sec_sum' + `sec_b'
        local sec_max = max(`sec_max', `sec_b')
        if (`conv_b' == 0) local ++nonconv
        if "`profile'" != "" {
            local prof_read = `prof_read' + scalar(`p_read')
            local prof_boot = `prof_boot' + scalar(`p_boot')
            local prof_pseudo = `prof_pseudo' + scalar(`p_pseudo')
            local prof_bootprelim = `prof_bootprelim' + scalar(`p_bootprelim')
            local prof_ecm = `prof_ecm' + scalar(`p_ecm')
            local prof_origprelim = `prof_origprelim' + scalar(`p_origprelim')
            local prof_impute = `prof_impute' + scalar(`p_impute')
            local prof_store = `prof_store' + scalar(`p_store')
            local prof_estep = `prof_estep' + scalar(`p_estep')
            local prof_mstep = `prof_mstep' + scalar(`p_mstep')
            local prof_ipf = `prof_ipf' + scalar(`p_ipf')
            local prof_detrow = `prof_detrow' + scalar(`p_detrow')
            local prof_detwt = `prof_detwt' + scalar(`p_detwt')
            local prof_activerow = `prof_activerow' + scalar(`p_activerow')
            local prof_activewt = `prof_activewt' + scalar(`p_activewt')
        }

        preserve
            local j = 0
            foreach v of local noms {
                local ++j
                local outw : word `j' of `outvars'
                local code = 0
                foreach lev of local levels`j' {
                    local ++code
                    quietly replace `v' = `lev' if `touse' & `v' == . & round(`outw') == `code'
                }
            }

            local zstart = `p' + 1
            local k = 0
            foreach v of local zvars {
                local ++k
                local outz : word `=`p' + `k'' of `outvars'
                quietly replace `v' = `outz' if `touse' & `v' == .
            }

            quietly sort `order'
            quietly drop `touse' `order' `wvars' `outvars'
            local outfile `"`savebase'`b'.dta"'
            quietly save `"`outfile'"', `replace'
        restore

        if "`noisily'" != "" {
            di as txt "imputation " as res `b' ///
                as txt ": ECM iterations = " as res `iter_b' ///
                as txt ", seconds = " as res %7.2f `sec_b' ///
                as txt cond(`conv_b', " (converged)", " (not converged)") ///
                as txt "; saved " as res `"`outfile'"'
        }
        else if "`dots'" != "" {
            di as txt "." _continue
            if (mod(`b', 50) == 0 | `b' == `add') di
        }
        else if (`conv_b' == 0) {
            di as err "warning: imputation `b' reached maxits = `maxits' without convergence"
        }
        else if "`dots'" != "" | "`noisily'" != "" {
            di as txt "saved imputation " as res `b' as txt " to " as res `"`outfile'"'
        }
    }

    if (`nonconv' > 0) {
        di as err "warning: " as res `nonconv' as err " of " as res `add' ///
            as err " imputation(s) did not converge within maxits = " as res `maxits'
    }
    di as txt "glemb: saved " as res `add' as txt " completed dataset(s); " ///
        as txt "mean ECM iterations = " as res %6.2f (`iter_sum' / `add') ///
        as txt ", max = " as res `iter_max' ///
        as txt "; mean seconds = " as res %7.2f (`sec_sum' / `add') ///
        as txt ", max = " as res %7.2f `sec_max'

    if "`profile'" != "" {
        di as txt "glemb profile: mean Mata seconds per imputation"
        di as txt "  read data        " as res %8.4f (`prof_read' / `add') ///
            as txt "    bootstrap       " as res %8.4f (`prof_boot' / `add') ///
            as txt "    pseudo/prior    " as res %8.4f (`prof_pseudo' / `add')
        di as txt "  boot prelim      " as res %8.4f (`prof_bootprelim' / `add') ///
            as txt "    ECM             " as res %8.4f (`prof_ecm' / `add') ///
            as txt "    orig prelim     " as res %8.4f (`prof_origprelim' / `add')
        di as txt "  impute           " as res %8.4f (`prof_impute' / `add') ///
            as txt "    store to Stata   " as res %8.4f (`prof_store' / `add')
        di as txt "glemb profile: mean ECM component seconds per imputation"
        di as txt "  E-step           " as res %8.4f (`prof_estep' / `add') ///
            as txt "    M-step          " as res %8.4f (`prof_mstep' / `add') ///
            as txt "    IPF             " as res %8.4f (`prof_ipf' / `add')
        di as txt "glemb profile: mean E-step row counts per imputation"
        di as txt "  deterministic    " as res %8.2f (`prof_detrow' / `add') ///
            as txt "    active rows     " as res %8.2f (`prof_activerow' / `add')
        di as txt "  deterministic wt " as res %8.2f (`prof_detwt' / `add') ///
            as txt "    active wt       " as res %8.2f (`prof_activewt' / `add')
    }

    return scalar nonconverged = `nonconv'
    return scalar mean_iter = `iter_sum' / `add'
    return scalar max_iter = `iter_max'
    return scalar mean_sec = `sec_sum' / `add'
    return scalar max_sec = `sec_max'
    if "`profile'" != "" {
        return scalar profile_read = `prof_read' / `add'
        return scalar profile_bootstrap = `prof_boot' / `add'
        return scalar profile_pseudo = `prof_pseudo' / `add'
        return scalar profile_boot_prelim = `prof_bootprelim' / `add'
        return scalar profile_ecm = `prof_ecm' / `add'
        return scalar profile_orig_prelim = `prof_origprelim' / `add'
        return scalar profile_impute = `prof_impute' / `add'
        return scalar profile_store = `prof_store' / `add'
        return scalar profile_estep = `prof_estep' / `add'
        return scalar profile_mstep = `prof_mstep' / `add'
        return scalar profile_ipf = `prof_ipf' / `add'
        return scalar profile_det_rows = `prof_detrow' / `add'
        return scalar profile_det_weight = `prof_detwt' / `add'
        return scalar profile_active_rows = `prof_activerow' / `add'
        return scalar profile_active_weight = `prof_activewt' / `add'
    }
end
