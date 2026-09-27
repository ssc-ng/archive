*! cointvol_stoch_p 0.1.0  26sep2026
*! predict after -cointvol stoch- and -cointvol hetcoint-: linear prediction and residuals
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!   xb        : x_t'b (+ trend coefficient * t, t = 1 at the first estimation period) + _cons
*!   residuals : depvar - xb  (MLH 2006 eq (8) residuals when e(estimator) = aiv)

program define cointvol_stoch_p
    version 14.0
    if !inlist(`"`e(cmd)'"', "cointvol stoch", "cointvol hetcoint") {
        di as err "last estimates not found; run cointvol stoch or cointvol hetcoint first"
        exit 301
    }
    syntax newvarname [if] [in] [, XB Residuals ]
    local nopt : word count `xb' `residuals'
    if `nopt' > 1 {
        di as err "only one of xb and residuals may be specified"
        exit 198
    }
    if `nopt' == 0 {
        di as txt "(option xb assumed; linear prediction)"
        local xb "xb"
    }
    marksample touse, novarlist

    tempname b
    tempvar xbv
    matrix `b' = e(b)
    local names : colnames `b'
    local tvar "`e(timevar)'"
    qui gen double `xbv' = 0 if `touse'
    local j 0
    foreach c of local names {
        local j = `j' + 1
        if "`c'" == "_cons" {
            qui replace `xbv' = `xbv' + `b'[1, `j'] if `touse'
        }
        else if "`c'" == "_trend" {
            qui replace `xbv' = `xbv' + `b'[1, `j'] * ((`tvar' - e(tmin))/e(tdelta) + 1) if `touse'
        }
        else {
            qui replace `xbv' = `xbv' + `b'[1, `j'] * `c' if `touse'
        }
    }
    if "`xb'" != "" {
        qui gen `typlist' `varlist' = `xbv' if `touse'
        label variable `varlist' "Linear prediction"
    }
    else {
        qui gen `typlist' `varlist' = `e(depvar)' - `xbv' if `touse'
        label variable `varlist' "Residuals"
    }
end
