*! thstar_p 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*! predict after thstar / thstr.

program define thstar_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals TRANSition ]

    if !inlist("`e(cmd)'", "thstar", "thstr") {
        display as error "last estimates not found or not from {bf:thstar}/{bf:thstr}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `transition'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, transition may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    local g  = e(gamma)
    local c  = e(c)
    local sz = e(sd_z)
    local ty = e(typenum)

    tempvar zz G
    quietly generate double `zz' = `e(threshold_var)' if `touse'
    if `ty' == 1 {
        quietly generate double `G' = 1/(1+exp(-`g'*(`zz'-`c')/`sz')) if `touse'
    }
    else if `ty' == 2 {
        quietly generate double `G' = 1-exp(-`g'*(`zz'-`c')^2/`sz'^2) if `touse'
    }
    else {
        local c2 = e(c2)
        quietly generate double `G' = 1/(1+exp(-`g'*(`zz'-`c')*(`zz'-`c2')/`sz'^2)) if `touse'
    }

    if "`transition'" != "" {
        quietly generate double `varlist' = `G' if `touse'
        label variable `varlist' "Transition function G(z)"
        exit
    }

    * xb = x'phi1 + (x G)'delta, built from the two equations of e(b)
    tempname b
    matrix `b' = e(b)
    local xnames "`e(arnames)'"
    if "`xnames'" == "" local xnames "`e(indepvars)'"
    tempvar fit
    quietly generate double `fit' = 0 if `touse'
    local j 0
    foreach v of local xnames {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j']*(`v') if `touse'
    }
    local k = e(hascons) + `: word count `xnames''
    if e(hascons) {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j'] if `touse'
    }
    local j2 = `k'
    foreach v of local xnames {
        local ++j2
        quietly replace `fit' = `fit' + `b'[1,`j2']*(`v')*`G' if `touse'
    }
    if e(hascons) {
        local ++j2
        quietly replace `fit' = `fit' + `b'[1,`j2']*`G' if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `fit' if `touse'
        label variable `varlist' "Linear prediction"
        exit
    }
    quietly generate double `varlist' = `e(depvar)' - `fit' if `touse'
    label variable `varlist' "Residuals"
end
