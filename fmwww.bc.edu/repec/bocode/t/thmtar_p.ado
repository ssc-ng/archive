*! thmtar_p 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thmtar. The dependent variable is D.z, where z is either the
*! series itself (asymmetric unit-root case) or the Engle-Granger residual
*! (threshold-cointegration case), so xb and residuals refer to D.z.
*!
*! z must be rebuilt ONE PERIOD BEFORE the estimation sample, because the design
*! uses L.z: an observation whose own lag of z is missing would otherwise fall
*! into regime 1 by accident. So z is built wherever the inputs exist, using the
*! stored first-stage coefficients e(b_stage1) rather than by re-running the
*! first-stage regression on a different sample.

program define thmtar_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals REGime EC INDicator ]

    if "`e(cmd)'" != "thmtar" {
        display as error "last estimates not found, or not from {bf:thmtar}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `regime' `ec' `indicator'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, regime, ec, indicator may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    * ---- copy everything out of e() BEFORE anything can overwrite it
    local depv  "`e(depvar)'"
    local cv    "`e(cointvars)'"
    local lags  = e(lags)
    local isband = e(band)
    local ismtar = ("`e(model)'" == "mtar")
    local iseqtar = ("`e(model)'" == "band-eqtar")
    tempname b TAU TL TU
    matrix `b' = e(b)
    scalar `TAU' = e(tau)
    if `isband' {
        scalar `TL' = e(tau_lower)
        scalar `TU' = e(tau_upper)
    }
    local cn : colnames `b'
    local hascons = cond(strpos(" `cn' ", " _cons ") > 0, 1, 0)

    * ---- rebuild z over EVERY usable observation, not just e(sample)
    tempvar z
    if "`cv'" != "" {
        tempname B1
        matrix `B1' = e(b_stage1)
        local s1n : colnames `B1'
        quietly generate double `z' = `depv'
        local j 0
        foreach v of local s1n {
            local ++j
            if "`v'" == "_cons" {
                quietly replace `z' = `z' - `B1'[1,`j']
            }
            else {
                quietly replace `z' = `z' - `B1'[1,`j']*`v'
            }
        }
    }
    else {
        quietly generate double `z' = `depv'
    }

    if "`ec'" != "" {
        quietly generate double `varlist' = `z' if `touse'
        * label variable takes a literal string, not an expression
        local lab "The series itself"
        if "`cv'" != "" local lab "Error-correction term (Engle-Granger residual)"
        label variable `varlist' "`lab'"
        exit
    }

    * built over the whole series, not just e(sample): L.dz and the lag block
    * all need values from before the estimation sample starts
    tempvar dz zl dzl
    quietly generate double `dz'  = D.`z'
    quietly generate double `zl'  = L.`z'
    quietly generate double `dzl' = L.`dz'

    * ---- the indicator, and the regime
    if `isband' {
        if "`indicator'" != "" {
            quietly generate double `varlist' = `zl' if `touse'
            label variable `varlist' "Band indicator variable, L.z"
            exit
        }
        if "`regime'" != "" {
            quietly generate byte `varlist' = . if `touse'
            quietly replace `varlist' = 1 if `touse' & `zl' < `TL'
            quietly replace `varlist' = 2 if `touse' & `zl' >= `TL' & `zl' <= `TU'
            quietly replace `varlist' = 3 if `touse' & `zl' > `TU' & !missing(`zl')
            label variable `varlist' "Band regime (1 below, 2 inside, 3 above)"
            label define __tkband 1 "below the band" 2 "inside the band" 3 "above the band", modify
            label values `varlist' __tkband
            exit
        }
    }
    else {
        tempvar ind
        quietly generate double `ind' = cond(`ismtar', `dzl', `zl') if `touse'
        if "`indicator'" != "" {
            quietly generate double `varlist' = `ind' if `touse'
            local lab "Indicator variable, L.z (TAR)"
            if `ismtar' local lab "Indicator variable, LD.z (momentum-TAR)"
            label variable `varlist' "`lab'"
            exit
        }
        if "`regime'" != "" {
            * a missing indicator must stay missing, not fall into regime 1
            quietly generate byte `varlist' = 1 + (`ind' < `TAU') ///
                if `touse' & !missing(`ind')
            label variable `varlist' "Regime (1: indicator >= tau, 2: < tau)"
            exit
        }
    }

    * ---- xb and residuals: rebuild the design exactly as thmtar did
    tempvar xb_ w1 w2
    if `isband' {
        if `iseqtar' {
            quietly generate double `w1' = `zl' * (`zl' > `TU') if `touse'
            quietly generate double `w2' = `zl' * (`zl' < `TL') if `touse'
        }
        else {
            quietly generate double `w1' = (`zl' - `TU') * (`zl' > `TU') if `touse'
            quietly generate double `w2' = (`zl' - `TL') * (`zl' < `TL') if `touse'
        }
    }
    else {
        quietly generate double `w1' = `zl' * (cond(`ismtar', `dzl', `zl') >= `TAU') if `touse'
        quietly generate double `w2' = `zl' * (cond(`ismtar', `dzl', `zl') <  `TAU') if `touse'
    }
    quietly generate double `xb_' = `b'[1,1]*`w1' + `b'[1,2]*`w2' if `touse'
    forvalues j = 1/`lags' {
        tempvar dl`j'
        quietly generate double `dl`j'' = L`j'.`dz' if `touse'
        quietly replace `xb_' = `xb_' + `b'[1,`=2+`j''] * `dl`j'' if `touse'
    }
    if `hascons' {
        quietly replace `xb_' = `xb_' + `b'[1,`=3+`lags''] if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Linear prediction of D.z"
        exit
    }
    quietly generate double `varlist' = `dz' - `xb_' if `touse'
    label variable `varlist' "Residuals"
end
