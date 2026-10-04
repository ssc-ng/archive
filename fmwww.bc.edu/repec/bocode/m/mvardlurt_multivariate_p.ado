*! mvardlurt_multivariate_p  version 1.1.2  03oct2026
*! predict after mvardlurt_multivariate:  predict newvar [, xb | residuals]
*! Both refer to the dependent variable D.y of the ARDL regression.

capture program drop mvardlurt_multivariate_p
program define mvardlurt_multivariate_p, sortpreserve
    version 14
    syntax newvarname [if] [in] [, XB Residuals]

    if "`e(cmd)'" != "mvardlurt_multivariate" {
        di as err "last estimates not found"
        exit 301
    }
    if "`xb'" != "" & "`residuals'" != "" {
        di as err "specify only one of xb and residuals"
        exit 198
    }
    _mvardlurt_multivariate_load

    local mode 1
    if "`residuals'" != "" local mode 2

    marksample touse, novarlist
    tempvar es
    qui gen byte `es' = e(sample)

    qui tsset
    sort `r(timevar)'

    qui gen `typlist' `varlist' = .
    local mvu_err ""
    capture mata: mvu_predict("`es'", "`varlist'", `mode')
    if _rc | "`mvu_err'" != "" {
        capture drop `varlist'
        di as err "regression objects are no longer in memory (was Mata cleared?)"
        di as err "re-run mvardlurt_multivariate"
        exit 498
    }
    qui replace `varlist' = . if !`touse'
    if `mode' == 1 label var `varlist' "Fitted values of D.`e(depvar)'"
    else           label var `varlist' "Residuals of D.`e(depvar)' equation"
end
