*! thqkink_p 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thqkink. The prediction is the fitted CONDITIONAL QUANTILE,
*! so "residuals" are deviations from that quantile and about tau of them are
*! negative by construction. segment() says which linear segment of the bent
*! line an observation sits on.

program define thqkink_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals SEGment ]

    if "`e(cmd)'" != "thqkink" {
        display as error "last estimates not found, or not from {bf:thqkink}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `segment'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, segment may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    local kv "`e(kink_var)'"
    local nk = e(nkinks)
    local zl "`e(invariant)'"

    if "`segment'" != "" {
        quietly generate byte `varlist' = 1 if `touse' & !missing(`kv')
        forvalues k = 1/`nk' {
            tempname G`k'
            scalar `G`k'' = e(kink`k')
            quietly replace `varlist' = `varlist' + 1 ///
                if `touse' & `kv' > `G`k'' & !missing(`kv')
        }
        label variable `varlist' "Segment of the bent line (1 = leftmost)"
        exit
    }

    tempname b
    matrix `b' = e(b)
    * e(b) is: the base slope, one slope change per kink, invariants, _cons
    tempvar xb_
    quietly generate double `xb_' = `b'[1,1] * `kv' if `touse'
    forvalues k = 1/`nk' {
        tempname G`k'
        scalar `G`k'' = e(kink`k')
        quietly replace `xb_' = `xb_' + `b'[1,`=`k'+1'] * ///
            cond(`kv' - `G`k'' > 0, `kv' - `G`k'', 0) if `touse'
    }
    local j = `nk' + 1
    foreach v of local zl {
        local ++j
        quietly replace `xb_' = `xb_' + `b'[1,`j'] * `v' if `touse'
    }
    quietly replace `xb_' = `xb_' + `b'[1,`=colsof(`b')'] if `touse'

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Fitted conditional quantile, tau = `=e(tau)'"
        exit
    }
    quietly generate double `varlist' = `e(depvar)' - `xb_' if `touse'
    label variable `varlist' "Deviation from the fitted quantile"
end
