*! thsubtar_p 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thsubtar. xb, residuals, regime.
*!
*! The two regimes carry DIFFERENT numbers of lags, so the fitted value
*! cannot be assembled with the usual "k columns then k columns" walk that
*! works after the symmetric commands. The block lengths are read from
*! e(k1) and e(k2).

program define thsubtar_p
    version 15
    syntax newvarname [if] [in] , [ XB RESiduals REGime SCores ]

    if "`e(cmd)'" != "thsubtar" {
        display as error "thsubtar_p works only after {bf:thsubtar}"
        exit 301
    }
    if "`scores'" != "" {
        display as error "{bf:scores} is not provided after {bf:thsubtar}."
        display as error "The two regimes are fitted on disjoint rows with"
        display as error "different designs, so there is no single score"
        display as error "vector of fixed length to post."
        exit 198
    }
    local nopt : word count `xb' `residuals' `regime'
    if `nopt' > 1 {
        display as error "only one of {bf:xb}, {bf:residuals}, {bf:regime}"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    local depv "`e(depvar)'"
    local d  = e(delay)
    local k1 = e(k1)
    local k2 = e(k2)
    local hc = e(hascons)

    tempname GAM
    scalar `GAM' = e(gamma)

    tempvar qq
    quietly generate double `qq' = L`d'.`depv' if `touse'

    if "`regime'" != "" {
        quietly generate byte `typlist' `varlist' = 1 + (`qq' > `GAM') ///
            if `touse' & !missing(`qq')
        label variable `varlist' ///
            "Regime (1: L`d'.`depv' <= gamma, 2: > gamma)"
        exit
    }

    * e(b) is laid out [lower lags 1..k1, lower cons, upper lags 1..k2,
    * upper cons]. The two blocks have different lengths, so the upper
    * block starts at k1 + hascons + 1 and not at half the width.
    tempname b
    matrix `b' = e(b)
    local lo1 = 1
    local lo2 = `k1' + `hc'
    local up1 = `lo2' + 1

    tempvar d1 fit
    quietly generate byte `d1' = (`qq' <= `GAM') if `touse'
    quietly generate double `fit' = . if `touse'
    quietly replace `fit' = 0 if `touse' & !missing(`qq')

    * lower regime
    local j 0
    forvalues i = 1/`k1' {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j']*L`i'.`depv' ///
            if `touse' & `d1' == 1
    }
    if `hc' {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j'] if `touse' & `d1' == 1
    }
    * upper regime
    local j = `up1' - 1
    forvalues i = 1/`k2' {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j']*L`i'.`depv' ///
            if `touse' & `d1' == 0
    }
    if `hc' {
        local ++j
        quietly replace `fit' = `fit' + `b'[1,`j'] if `touse' & `d1' == 0
    }

    if "`xb'" != "" {
        quietly generate `typlist' `varlist' = `fit' if `touse'
        label variable `varlist' "Fitted values, SETAR(2; `k1', `k2')"
        exit
    }
    quietly generate `typlist' `varlist' = `depv' - `fit' if `touse'
    label variable `varlist' "Residuals, SETAR(2; `k1', `k2')"
end
