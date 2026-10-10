*! thtvar_p 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thtvar. A system estimator has one prediction per equation,
*! so equation() selects it; regime is common to all equations.

program define thtvar_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals REGime EQuation(string) ]

    if "`e(cmd)'" != "thtvar" {
        display as error "last estimates not found, or not from {bf:thtvar}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `regime'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, regime may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    tempvar qv
    quietly generate double `qv' = `e(threshold_var)' if `touse'
    * the threshold must be held in a scalar: a local rounds to ~9 digits and a
    * boundary observation then falls on the wrong side of the split
    tempname GAM
    scalar `GAM' = e(gamma)

    if "`regime'" != "" {
        quietly generate byte `varlist' = 1 + (`qv' > `GAM') if `touse'
        label variable `varlist' ///
            "Regime (1: `e(threshold_var)' <= gamma, 2: > gamma)"
        exit
    }

    local yv "`e(depvars)'"
    local k  = e(k_var)
    local p  = e(lags)
    if "`equation'" == "" local equation 1
    local ej 0
    local i 0
    foreach v of local yv {
        local ++i
        if "`v'" == "`equation'" local ej `i'
    }
    if `ej' == 0 {
        capture confirm integer number `equation'
        if _rc | `equation' < 1 | `equation' > `k' {
            display as error "equation() must be a name in `yv' or an integer 1-`k'"
            exit 198
        }
        local ej `equation'
    }
    local dv : word `ej' of `yv'

    local wvars ""
    forvalues j = 1/`p' {
        foreach v of local yv {
            tempvar w`j'_`v'
            quietly generate double `w`j'_`v'' = L`j'.`v' if `touse'
            local wvars `wvars' `w`j'_`v''
        }
    }

    tempname B1 B2
    matrix `B1' = e(B1)
    matrix `B2' = e(B2)
    tempvar xb_
    quietly generate double `xb_' = 0 if `touse'
    local r 0
    if e(hascons) == 1 {
        local ++r
        quietly replace `xb_' = `xb_' + ///
            cond(`qv' <= `GAM', `B1'[`r',`ej'], `B2'[`r',`ej']) if `touse'
    }
    foreach v of local wvars {
        local ++r
        quietly replace `xb_' = `xb_' + ///
            cond(`qv' <= `GAM', `B1'[`r',`ej'], `B2'[`r',`ej']) * `v' if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Linear prediction, equation `dv'"
        exit
    }
    quietly generate double `varlist' = `dv' - `xb_' if `touse'
    label variable `varlist' "Residuals, equation `dv'"
end
