*! thqreg_p 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thqreg. The prediction is the fitted CONDITIONAL QUANTILE at
*! the quantile that was reported, not a conditional mean, so "residuals" are
*! deviations from that quantile and are NOT expected to average zero: about
*! tau of them are negative. That is the model, not a defect.

program define thqreg_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals REGime ]

    * thtqar is thqreg on an autoregressive design and posts the same e()
    if !inlist("`e(cmd)'", "thqreg", "thtqar") {
        display as error "last estimates not found, or not from {bf:thqreg}"
        display as error "or {bf:thtqar}"
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

    local tv "`e(threshold_var)'"
    tempname GAM
    scalar `GAM' = e(gamma)

    if "`regime'" != "" {
        quietly generate byte `varlist' = 1 + (`tv' > `GAM') ///
            if `touse' & !missing(`tv')
        label variable `varlist' "Regime (1: `tv' <= gamma, 2: > gamma)"
        exit
    }

    local xl "`e(indepvars)'"
    local zl "`e(invariant)'"
    local kx : word count `xl'
    tempname b
    matrix `b' = e(b)

    * e(b) is ordered: lower slopes, lower _cons, upper slopes, upper _cons,
    * then the regime-invariant block
    tempvar d1 xb_
    quietly generate byte `d1' = (`tv' <= `GAM') if `touse'
    quietly generate double `xb_' = 0 if `touse'
    local j 0
    foreach v of local xl {
        local ++j
        quietly replace `xb_' = `xb_' + ///
            cond(`d1', `b'[1,`j'], `b'[1,`=`kx'+1+`j'']) * `v' if `touse'
    }
    quietly replace `xb_' = `xb_' + ///
        cond(`d1', `b'[1,`=`kx'+1'], `b'[1,`=2*`kx'+2']) if `touse'
    local j = 2*`kx' + 2
    foreach v of local zl {
        local ++j
        quietly replace `xb_' = `xb_' + `b'[1,`j'] * `v' if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Fitted conditional quantile, tau = `=e(tau)'"
        exit
    }
    quietly generate double `varlist' = `e(depvar)' - `xb_' if `touse'
    label variable `varlist' "Deviation from the fitted quantile"
end
