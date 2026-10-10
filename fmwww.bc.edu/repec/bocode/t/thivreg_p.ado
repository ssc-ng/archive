*! thivreg_p 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thivreg.
*!   xb        fitted value from the regime GMM coefficients (default)
*!   residuals depvar - xb
*!   regime    1 if q <= gamma, 2 otherwise
*!
*! The fitted value uses the ACTUAL endogenous regressors, not their first-
*! stage fits: e(b) estimates the structural coefficients, and the residual
*! that matters for diagnostics is y - z'beta, not y - zhat'beta.

program define thivreg_p
    version 15
    syntax newvarname [if] [in] , [ XB RESiduals REGime SCores ]

    if "`e(cmd)'" != "thivreg" {
        display as error "last estimates not found, or not from {bf:thivreg}"
        exit 301
    }
    if "`scores'" != "" {
        display as error "{bf:predict, scores} is not available after {bf:thivreg}"
        display as error "the estimator is GMM on a design that depends on an"
        display as error "estimated threshold; there is no likelihood to score"
        exit 198
    }
    local nopt : word count `xb' `residuals' `regime'
    if `nopt' > 1 {
        display as error "choose one of {bf:xb}, {bf:residuals}, {bf:regime}"
        exit 198
    }
    if `nopt' == 0 local xb xb

    local depv  "`e(depvar)'"
    local qv    "`e(threshold_var)'"
    tempname GAM
    scalar `GAM' = e(gamma)
    local kz    = e(k_regime)
    local zn    "`e(zn)'"

    marksample touse, novarlist
    markout `touse' `qv'

    tempvar d1
    quietly generate byte `d1' = (`qv' <= `GAM') if !missing(`qv')

    if "`regime'" != "" {
        quietly generate byte `varlist' = 2 - `d1' if `touse' & !missing(`qv')
        label variable `varlist' "regime (1 = `qv' <= gamma)"
        exit
    }

    tempname b
    matrix `b' = e(b)
    tempvar fit
    quietly generate double `fit' = 0 if `touse' & !missing(`qv')
    local j 0
    foreach v of local zn {
        local ++j
        tempname c1 c2
        scalar `c1' = `b'[1,`j']
        scalar `c2' = `b'[1,`=`j' + `kz'']
        if "`v'" == "_cons" {
            quietly replace `fit' = `fit' + ///
                (`c1' * `d1' + `c2' * (1 - `d1')) if `touse'
        }
        else {
            quietly replace `fit' = `fit' + ///
                (`c1' * `d1' + `c2' * (1 - `d1')) * `v' if `touse'
        }
    }

    quietly generate double `varlist' = `fit' if `touse' & !missing(`qv')
    if "`residuals'" != "" {
        quietly replace `varlist' = `depv' - `varlist' if `touse' & `varlist' < .
        label variable `varlist' "residuals, `depv'"
    }
    else label variable `varlist' "fitted `depv'"
end
