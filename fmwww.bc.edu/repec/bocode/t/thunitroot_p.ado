*! thunitroot_p 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thunitroot.
*!   xb        fitted D.depvar from the two-regime ADF regression (default)
*!   residuals D.depvar - xb
*!   regime    1 if Z(t-1) < lambda, 2 otherwise
*!   zvar      the threshold variable Z(t-1) itself
*!
*! The design is rebuilt from time-series operators, not from stored columns,
*! so what predict computes is exactly what the help file writes down and the
*! user can reproduce by hand. The one column that is not an operator is the
*! trend, which the engine numbers 1, 2, ... over the estimation rows; it is
*! rebuilt the same way here, and predict therefore refuses to extrapolate a
*! trend model outside e(sample).

program define thunitroot_p
    version 15
    syntax newvarname [if] [in] , [ XB RESiduals REGime ZVar SCores ]

    if "`e(cmd)'" != "thunitroot" {
        display as error "last estimates not found, or not from {bf:thunitroot}"
        exit 301
    }
    if "`scores'" != "" {
        display as error "{bf:predict, scores} is not available after {bf:thunitroot}"
        display as error "the estimator is least squares on a design that depends on"
        display as error "an estimated threshold, so the score of a likelihood is not"
        display as error "the score of what was actually minimised"
        exit 198
    }
    local nopt : word count `xb' `residuals' `regime' `zvar'
    if `nopt' > 1 {
        display as error "choose one of {bf:xb}, {bf:residuals}, {bf:regime}, {bf:zvar}"
        exit 198
    }
    if `nopt' == 0 local xb xb

    local depv   "`e(depvar)'"
    local lags   = e(k_lags)
    local trendn = e(trend)
    local mm     = e(delay)
    tempname LAM
    scalar `LAM' = e(lambda)
    local ztype  "`e(ztype)'"

    marksample touse, novarlist

    * ---- the threshold variable
    tempvar zz
    if "`ztype'" == "long" {
        quietly generate double `zz' = L1.`depv' - L`=`mm'+1'.`depv'
    }
    else if "`ztype'" == "lagdiff" {
        quietly generate double `zz' = L`mm'D.`depv'
    }
    else {
        quietly generate double `zz' = L`mm'.`depv'
    }

    if "`zvar'" != "" {
        quietly generate double `varlist' = `zz' if `touse'
        label variable `varlist' "Z(t-1), the threshold variable"
        exit
    }
    if "`regime'" != "" {
        quietly generate byte `varlist' = cond(`zz' < `LAM', 1, 2) ///
            if `touse' & !missing(`zz')
        label variable `varlist' "regime (1 = Z < lambda)"
        exit
    }

    * ---- rebuild the design columns, one tempvar per name in e(xnames)
    if `trendn' & "`xb'`residuals'" != "" {
        quietly count if `touse' & !e(sample)
        if r(N) > 0 {
            display as error "this fit includes a linear trend, whose values are"
            display as error "defined only over the estimation sample, so"
            display as error "{bf:predict} cannot be extended beyond {bf:e(sample)}."
            display as error "Add {bf:if e(sample)}."
            exit 198
        }
    }
    tempvar tr
    if `trendn' {
        quietly generate double `tr' = sum(e(sample)) if e(sample)
    }

    local swn "`e(swnames)'"
    local nsn "`e(nsnames)'"
    local nsw : word count `swn'

    tempname b
    matrix `b' = e(b)
    tempvar d1 fit
    quietly generate byte `d1' = (`zz' < `LAM') if !missing(`zz')
    quietly generate double `fit' = 0 if `touse' & !missing(`zz')

    * switching block: coefficient j is regime 1, coefficient j+nsw is regime 2
    local j 0
    foreach v of local swn {
        local ++j
        tempname c1 c2
        scalar `c1' = `b'[1,`j']
        scalar `c2' = `b'[1,`=`j' + `nsw'']
        Xexpr "`v'" "`depv'" "`tr'"
        quietly replace `fit' = `fit' + ///
            (`c1' * `d1' + `c2' * (1 - `d1')) * (`s(xx)') if `touse'
    }
    * common block, if the model is constrained
    local j = 2 * `nsw'
    foreach v of local nsn {
        local ++j
        tempname c3
        scalar `c3' = `b'[1,`j']
        Xexpr "`v'" "`depv'" "`tr'"
        quietly replace `fit' = `fit' + `c3' * (`s(xx)') if `touse'
    }

    quietly generate double `varlist' = `fit' if `touse' & !missing(`zz')
    if "`residuals'" != "" {
        quietly replace `varlist' = D.`depv' - `varlist' if `touse' & `varlist' < .
        label variable `varlist' "residuals, D.`depv'"
    }
    else label variable `varlist' "fitted D.`depv'"
end

* ======================================================================
* One design column's Stata expression. The names are exactly the ones
* thunitroot puts in e(xnames): _cons, trend, L1.y, L1D.y, L2D.y, ...
* ======================================================================
program define Xexpr, sclass
    version 15
    args nm depv tr
    if "`nm'" == "_cons" {
        sreturn local xx "1"
        exit
    }
    if "`nm'" == "trend" {
        sreturn local xx "`tr'"
        exit
    }
    * L1.depv or L#D.depv -- the stored name already is the expression
    sreturn local xx "`nm'"
end
