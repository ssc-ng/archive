*! thkink_p 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*! predict after thkink.

program define thkink_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals REGime ]

    * thtar, continuous delegates to thkink and keeps e(cmd) == "thtar", so
    * the continuous SETAR must be accepted here too: it IS a thkink fit, on
    * an autoregressive design, and every stored result has the same layout.
    if "`e(cmd)'" != "thkink" & ///
       !("`e(cmd)'" == "thtar" & "`e(model)'" == "setar_continuous") {
        display as error "last estimates not found, or not from {bf:thkink}"
        display as error "or {bf:thtar, continuous}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `regime'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, regime may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    * after thtar, continuous this is a time-series expression (L1.y), which
    * is valid in an expression but not in a varlist; resolve it once
    local kvname "`e(kink_var)'"
    capture tsrevar `kvname'
    local kv = cond(_rc, "`kvname'", "`r(varlist)'")
    tempname GK
    scalar `GK' = e(gamma)

    if "`regime'" != "" {
        quietly generate byte `varlist' = cond(`kv' <= `GK', 1, 2) if `touse'
        local gshow : display %9.0g e(gamma)
        label variable `varlist' ///
            "Side of the kink (1: `kvname' <= `=trim("`gshow'")', 2: above)"
        exit
    }

    tempname b
    matrix `b' = e(b)
    local b1 = `b'[1, 1]
    local b2 = `b'[1, 2]
    local cn : colnames `b'
    tempvar xbz
    quietly generate double `xbz' = 0 if `touse'
    local j 0
    foreach c of local cn {
        local ++j
        if `j' <= 2 continue                 // the two kink slopes
        if "`c'" == "gamma" continue         // the threshold itself
        if "`c'" == "_cons" {
            quietly replace `xbz' = `xbz' + `b'[1,`j'] if `touse'
        }
        else {
            quietly replace `xbz' = `xbz' + `b'[1,`j'] * `c' if `touse'
        }
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xbz' ///
            + `b1' * cond(`kv' - `GK' < 0, `kv' - `GK', 0) ///
            + `b2' * cond(`kv' - `GK' > 0, `kv' - `GK', 0) if `touse'
        label variable `varlist' "Linear prediction"
        exit
    }
    quietly generate double `varlist' = `e(depvar)' - ( `xbz' ///
        + `b1' * cond(`kv' - `GK' < 0, `kv' - `GK', 0) ///
        + `b2' * cond(`kv' - `GK' > 0, `kv' - `GK', 0) ) if `touse'
    label variable `varlist' "Residuals"
end
