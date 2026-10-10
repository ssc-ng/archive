*! thregress_p 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*! predict after thregress.

program define thregress_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals REGime SCore ]

    * every command built on the shared threshold engine posts the same e()
    if !inlist("`e(cmd)'", "thregress", "thtar") {
        display as error "last estimates not found, or not from a THRESHKIT"
        display as error "jump-threshold command ({bf:thregress}, {bf:thtar})"
        exit 301
    }
    local nopt : word count `xb' `residuals' `regime' `score'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, regime may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    local tv "`e(threshold_var)'"
    tempname GHAT
    scalar `GHAT' = e(gamma)

    if "`regime'" != "" {
        quietly generate byte `varlist' = cond(`tv' <= `GHAT', 1, 2) if `touse'
        local gshow : display %9.0g e(gamma)
        label variable `varlist' ///
            "Regime (1: `tv' <= `=trim("`gshow'")', 2: above)"
        exit
    }

    tempname b
    matrix `b' = e(b)
    tempvar xb1 xb2 xbz d1
    quietly matrix score double `xb1' = `b' if `touse', eq(Region1)
    quietly matrix score double `xb2' = `b' if `touse', eq(Region2)
    if "`e(invariant)'" != "" {
        quietly matrix score double `xbz' = `b' if `touse', eq(Invariant)
    }
    else {
        quietly generate double `xbz' = 0 if `touse'
    }
    quietly generate byte `d1' = (`tv' <= `GHAT') if `touse'

    if "`xb'" != "" {
        quietly generate double `varlist' = ///
            cond(`d1', `xb1', `xb2') + `xbz' if `touse'
        label variable `varlist' "Linear prediction"
        exit
    }
    if "`residuals'" != "" {
        quietly generate double `varlist' = ///
            `e(depvar)' - (cond(`d1', `xb1', `xb2') + `xbz') if `touse'
        label variable `varlist' "Residuals"
        exit
    }
    display as error "score is not available after thregress"
    exit 198
end
