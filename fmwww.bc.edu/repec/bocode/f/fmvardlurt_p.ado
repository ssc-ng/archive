*! fmvardlurt_p  version 1.0.0  13oct2026
*! predict after fmvardlurt:  predict newvar [, xb | residuals | fourier]
*! All refer to the D.y equation; fourier = fitted Fourier component a1 sin + a2 cos.

capture program drop fmvardlurt_p
program define fmvardlurt_p, sortpreserve
    version 14
    syntax newvarname [if] [in] [, XB Residuals FOURier]

    if "`e(cmd)'" != "fmvardlurt" {
        di as err "last estimates not found"
        exit 301
    }
    if ("`xb'" != "") + ("`residuals'" != "") + ("`fourier'" != "") > 1 {
        di as err "specify only one of xb, residuals and fourier"
        exit 198
    }
    _fmvardlurt_load

    local mode 1
    if "`residuals'" != "" local mode 2
    if "`fourier'"   != "" local mode 3

    marksample touse, novarlist
    tempvar es
    qui gen byte `es' = e(sample)

    qui tsset
    sort `r(timevar)'

    qui gen `typlist' `varlist' = .
    local fmv_err ""
    capture mata: fmv_predict("`es'", "`varlist'", `mode')
    if _rc | "`fmv_err'" != "" {
        capture drop `varlist'
        di as err "regression objects are no longer in memory (was Mata cleared?)"
        di as err "re-run fmvardlurt"
        exit 498
    }
    qui replace `varlist' = . if !`touse'
    if `mode' == 1 label var `varlist' "Fitted values of D.`e(depvar)'"
    if `mode' == 2 label var `varlist' "Residuals of D.`e(depvar)' equation"
    if `mode' == 3 label var `varlist' "Fourier component of D.`e(depvar)' equation"
end
