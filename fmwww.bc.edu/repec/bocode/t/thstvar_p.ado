*! thstvar_p 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thstvar. A system estimator has one prediction per equation,
*! so equation() selects it; transition returns G(z), which is the same for
*! every equation.

program define thstvar_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals TRansition EQuation(string) ]

    if "`e(cmd)'" != "thstvar" {
        display as error "last estimates not found, or not from {bf:thstvar}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `transition'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, transition may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    local yv "`e(depvars)'"
    local k  = e(k_var)
    local kw = e(k_w)
    local lags = e(lags)
    local exl  "`e(exog)'"

    * ---- G(z)
    tempvar zv G
    quietly generate double `zv' = `e(threshold_var)' if `touse'
    local gg = e(gamma)
    local cc = e(c)
    local sz = e(sd_z)
    local tn = e(typenum)
    if `tn' == 1 {
        quietly generate double `G' = 1/(1+exp(-`gg'*(`zv'-`cc')/`sz')) if `touse'
    }
    else if `tn' == 2 {
        quietly generate double `G' = 1-exp(-`gg'*(`zv'-`cc')^2/`sz'^2) if `touse'
    }
    else {
        local c2 = e(c2)
        quietly generate double `G' = ///
            1/(1+exp(-`gg'*(`zv'-`cc')*(`zv'-`c2')/`sz'^2)) if `touse'
    }

    if "`transition'" != "" {
        quietly generate double `varlist' = `G' if `touse'
        label variable `varlist' "Transition function G(`e(threshold_var)')"
        exit
    }

    * ---- which equation
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

    * ---- rebuild w_t exactly as thstvar did
    local wv ""
    forvalues j = 1/`lags' {
        foreach v of local yv {
            tempvar w`j'_`v'
            quietly generate double `w`j'_`v'' = L`j'.`v' if `touse'
            local wv `wv' `w`j'_`v''
        }
    }
    foreach v of local exl {
        local wv `wv' `v'
    }

    tempname B
    matrix `B' = e(Bmat)
    tempvar xb_
    quietly generate double `xb_' = 0 if `touse'
    local r 0
    if e(hascons) == 1 {
        local ++r
        quietly replace `xb_' = `xb_' + `B'[`r',`ej'] + `B'[`=`r'+`kw'',`ej']*`G' ///
            if `touse'
    }
    foreach v of local wv {
        local ++r
        quietly replace `xb_' = `xb_' + ///
            (`B'[`r',`ej'] + `B'[`=`r'+`kw'',`ej']*`G') * `v' if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Linear prediction, equation `dv'"
        exit
    }
    quietly generate double `varlist' = `dv' - `xb_' if `touse'
    label variable `varlist' "Residuals, equation `dv'"
end
