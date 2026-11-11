*! xtcdmax  version 1.0.0  21oct2026
*! Tests of cross-sectional independence in panels that combine sum-type (CD) and
*! max-type statistics and allow for serial correlation: Pesaran CD, long-run
*! standardized CD, a max-type test (Beta law of squared correlations, Sidak correction),
*! their Fisher combination, and a sum test with the variance of Wang et al. (2023).
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop xtcdmax
program define xtcdmax, rclass sortpreserve
    version 14

    syntax [varlist(default=none ts numeric)] [if] [in] [, ///
        NODEMean LAGs(integer -1) MINT(integer 8) NODisplay ]

    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "panel and time variables must be set; use {bf:xtset} panelvar timevar"
        exit 459
    }
    marksample touse, novarlist
    tempvar e
    local nv : word count `varlist'

    if `nv' == 0 {
        if "`e(cmd)'" == "" {
            di as err "specify a variable, or run an estimation command first to test its residuals"
            exit 301
        }
        // residuals of the last estimation; for xtreg use the idiosyncratic error e_it
        capture predict double `e' if e(sample), e
        if _rc capture predict double `e' if e(sample), residuals
        if _rc capture predict double `e' if e(sample), resid
        if _rc {
            di as err "residuals are not available after {bf:`e(cmd)'}; create them and pass the variable"
            exit 198
        }
        local what "residuals of `e(cmd)' `e(depvar)'"
        markout `touse' `e'
    }
    else if `nv' == 1 {
        tsrevar `varlist'
        local v "`r(varlist)'"
        markout `touse' `v'
        if "`nodemean'" == "" {
            tempvar mu
            qui bysort `touse' `ivar': egen double `mu' = mean(`v') if `touse'
            qui gen double `e' = `v' - `mu' if `touse'
            local what "`varlist' (demeaned by unit)"
        }
        else {
            qui gen double `e' = `v' if `touse'
            local what "`varlist'"
        }
    }
    else {
        tsrevar `varlist'
        local vl "`r(varlist)'"
        markout `touse' `vl'
        gettoken yv xv : vl
        gettoken dep : varlist
        qui gen double `e' = .
        sort `ivar' `tvar'
        _xtcdmax_load
        mata: xcd_unitols("`yv'", "`xv'", "`ivar'", "`touse'", "`e'")
        markout `touse' `e'
        local what "unit-by-unit OLS residuals of `dep'"
    }

    sort `ivar' `tvar'
    _xtcdmax_load
    tempname R
    local lg = cond(`lags' < 0, ., `lags')
    mata: xcd_run("`e'", "`ivar'", "`tvar'", "`touse'", `lg', `mint', "`R'")
    if el(`R', 1, 3) >= . | el(`R', 1, 1) < 3 {
        di as err "too few units with at least `mint' observations"
        exit 2001
    }
    matrix colnames `R' = N T pairs CD p_CD CDlr p_CDlr MAX p_MAX FISHER p_FISHER ///
        SN p_SN balanced M id_i id_j rho_max mean_absrho T_min

    if "`nodisplay'" == "" _xtcdmax_display, res(`R') what(`"`what'"') ivar(`ivar')

    local cn : colnames `R'
    local j 0
    foreach nm of local cn {
        local ++j
        if !missing(el(`R', 1, `j')) return scalar `nm' = el(`R', 1, `j')
    }
    return local ivar "`ivar'"
    return local tvar "`tvar'"
    return matrix table = `R'
end
