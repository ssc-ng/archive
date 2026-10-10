*! thtarsel 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Joint selection of the autoregressive order, the delay and the number of
*! regimes for a SETAR, with the whole search trace reported.
*!
*! See thtarsel.sthlp. The one thing worth repeating here: every cell is
*! fitted on ONE FIXED SAMPLE. An autoregression of order p loses its first
*! p observations, so a naive sweep compares a model fitted to n-1 rows with
*! one fitted to n-4, and the smallest p wins by arithmetic rather than by
*! evidence. Reserving max(pmax, dmax) leading observations once, for every
*! cell, is what makes the comparison a comparison.

program define thtarsel, rclass
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        [ MAXP(integer 4)                   ///
          MAXDelay(integer 0)               ///
          MAXRegimes(integer 2)             ///
          TRIM(real 0.15)                   ///
          GRIDn(integer 0)                  ///
          MINOBS(integer 0)                 ///
          noCONStant                        ///
          LINear                            ///
          DETail ]

    capture tsset
    if _rc {
        display as error "{bf:thtarsel} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `maxp' < 1 | `maxp' > 12 {
        display as error "{bf:maxp()} must be between 1 and 12"
        exit 198
    }
    if `maxdelay' == 0 local maxdelay = `maxp'
    if `maxdelay' < 1 | `maxdelay' > `maxp' {
        display as error "{bf:maxdelay()} must be between 1 and {bf:maxp()}."
        display as error "A delay larger than the autoregressive order means"
        display as error "the transition variable is not part of the state the"
        display as error "model propagates, so the model is not self-exciting"
        display as error "in the usual sense and nothing here would apply to it."
        exit 198
    }
    if `maxregimes' < 2 | `maxregimes' > 4 {
        display as error "{bf:maxregimes()} must be between 2 and 4"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }

    local depv `varlist'
    local hascons = cond("`constant'"=="", 1, 0)

    marksample touse
    markout `touse' `depv'
    quietly count if `touse'
    if r(N) < 50 {
        display as error "too few observations (`r(N)') to select over a grid"
        exit 2001
    }

    * ---- the three lists
    tempname PL DL ML
    matrix `PL' = J(1, `maxp', 0)
    forvalues i = 1/`maxp' {
        matrix `PL'[1,`i'] = `i'
    }
    matrix `DL' = J(1, `maxdelay', 0)
    forvalues i = 1/`maxdelay' {
        matrix `DL'[1,`i'] = `i'
    }
    local nm = `maxregimes' - 1 + cond("`linear'"!="", 1, 0)
    matrix `ML' = J(1, `nm', 0)
    local j 0
    if "`linear'" != "" {
        local ++j
        matrix `ML'[1,`j'] = 0
    }
    forvalues i = 1/`=`maxregimes'-1' {
        local ++j
        matrix `ML'[1,`j'] = `i'
    }

    matrix __tk_tsp = `PL'
    matrix __tk_tsd = `DL'
    matrix __tk_tsm = `ML'

    mata: tk_thtarsel()

    if __tk_tsfail == 1 {
        _tk_drop
        display as error "after reserving observations for the largest order"
        display as error "and delay, fewer than 30 rows remain. Lower"
        display as error "{bf:maxp()} or use a longer series."
        exit 2001
    }
    if __tk_tsfail == 2 {
        _tk_drop
        display as error "no cell in the grid could be fitted"
        exit 498
    }

    tempname TAB NE OFF NC BA BB BH
    matrix `TAB' = __tk_tstab
    scalar `NE'  = __tk_tsn
    scalar `OFF' = __tk_tsoff
    scalar `NC'  = __tk_tsncell
    scalar `BA'  = __tk_tsbaic
    scalar `BB'  = __tk_tsbbic
    scalar `BH'  = __tk_tsbhq
    _tk_drop
    matrix colnames `TAB' = p delay m ssr lnsigma2 k aic bic hqic

    display _n as text "Joint selection of order, delay and regimes for a SETAR"
    display as text "{hline 76}"
    display as text "  series" _col(52) as result %22s "`depv'"
    display as text "  observations used by EVERY cell" _col(52) as result %22.0f `NE'
    display as text "  leading observations reserved" _col(52) as result %22.0f `OFF'
    display as text "  cells searched" _col(52) as result %22.0f `NC'
    display as text "{hline 76}"

    if "`detail'" != "" {
        display as text "    p  delay   m" ///
            _col(20) "ln sigma2" _col(34) "k" _col(44) "AIC" _col(58) "BIC" _col(70) "HQIC"
        display as text "{hline 76}"
        forvalues i = 1/`=rowsof(`TAB')' {
            if `TAB'[`i',7] >= . {
                display as text %5.0f `TAB'[`i',1] %6.0f `TAB'[`i',2] ///
                    %4.0f `TAB'[`i',3] _col(20) as text "    (not fitted)"
                continue
            }
            local mark ""
            if `i' == `BA' local mark "`mark' A"
            if `i' == `BB' local mark "`mark' B"
            if `i' == `BH' local mark "`mark' H"
            display as text %5.0f `TAB'[`i',1] %6.0f `TAB'[`i',2] ///
                %4.0f `TAB'[`i',3] ///
                as result _col(18) %11.5f `TAB'[`i',5] %6.0f `TAB'[`i',6] ///
                %14.3f `TAB'[`i',7] %14.3f `TAB'[`i',8] %12.3f `TAB'[`i',9] ///
                as text "`mark'"
        }
        display as text "{hline 76}"
        display as text "  A = AIC's choice, B = BIC's, H = HQIC's"
    }

    display as text "  criterion" _col(26) "p" _col(36) "delay" _col(48) "regimes"
    display as text "{hline 76}"
    foreach pair in "AIC `BA'" "BIC `BB'" "HQIC `BH'" {
        local nm : word 1 of `pair'
        local ix : word 2 of `pair'
        display as text "  " %-22s "`nm'" ///
            as result %8.0f `TAB'[`ix',1] %10.0f `TAB'[`ix',2] ///
            %12.0f `=`TAB'[`ix',3]+1'
    }
    display as text "{hline 76}"

    * ---- how decisive was it? A flat surface means the criterion did not
    *      actually choose, which the user has to know before building on it
    tempname SPREAD
    quietly {
        local lo = .
        local hi = .
        forvalues i = 1/`=rowsof(`TAB')' {
            if `TAB'[`i',8] >= . continue
            if `TAB'[`i',8] < `lo' | `lo' == . local lo = `TAB'[`i',8]
            if `TAB'[`i',8] > `hi' | `hi' == . local hi = `TAB'[`i',8]
        }
    }
    * the runner-up on BIC, to say how far ahead the winner is
    quietly {
        local second = .
        forvalues i = 1/`=rowsof(`TAB')' {
            if `TAB'[`i',8] >= . | `i' == `BB' continue
            if `TAB'[`i',8] < `second' | `second' == . local second = `TAB'[`i',8]
        }
    }
    local margin = `second' - `TAB'[`BB',8]
    display as text "  BIC range over the grid" _col(52) as result %22.3f `=`hi'-`lo''
    display as text "  BIC margin over the runner-up" _col(52) as result %22.3f `margin'
    display as text "{hline 76}"
    if `margin' < 2 {
        display as text "  {bf:The margin is small.} A difference of less than"
        display as text "  about 2 on BIC is not a choice, it is a tie. Report"
        display as text "  the table, not the winner, and check that your"
        display as text "  conclusions survive the runner-up."
    }

    display as text ""
    display as text "  Every cell was fitted to the SAME `=`NE'' observations."
    display as text "  That is not a detail. An autoregression of order p loses"
    display as text "  its first p observations, so a sweep that let the sample"
    display as text "  change would compare a model fitted to more data with one"
    display as text "  fitted to less -- and the smallest p would win by"
    display as text "  arithmetic rather than by evidence."
    display as text ""
    display as text "  The regime count here is chosen by an information"
    display as text "  criterion, which is a different question from whether a"
    display as text "  threshold EXISTS. For that, use {helpb thtest} or"
    display as text "  {helpb thnregimes}, which test it. A criterion will"
    display as text "  always name a winner, including on linear data."

    return matrix table = `TAB', copy
    return scalar N        = `NE'
    return scalar reserved = `OFF'
    return scalar n_cells  = `NC'
    return scalar p_aic    = `TAB'[`BA',1]
    return scalar d_aic    = `TAB'[`BA',2]
    return scalar m_aic    = `=`TAB'[`BA',3]+1'
    return scalar p_bic    = `TAB'[`BB',1]
    return scalar d_bic    = `TAB'[`BB',2]
    return scalar m_bic    = `=`TAB'[`BB',3]+1'
    return scalar p_hqic   = `TAB'[`BH',1]
    return scalar d_hqic   = `TAB'[`BH',2]
    return scalar m_hqic   = `=`TAB'[`BH',3]+1'
    return scalar bic_margin = `margin'
    return local  depvar   "`depv'"
    return local  cmd      "thtarsel"
end
