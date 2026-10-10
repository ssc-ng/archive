*! thtest 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Test of H0: no threshold effect, against a two-regime threshold model
*! with an unknown threshold. Reports the sup, ave and exp statistics of the
*! homoskedastic F family and of the White-robust LM family, each with a
*! fixed-regressor bootstrap p-value.
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Andrews & Ploberger (1994) Econometrica 62:1383-1414, doi:10.2307/2951753

program define thtest, rclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        THRESHvar(varname numeric ts fv)             ///
        [ INVariant(varlist numeric fv ts)          ///
          TRIM(real 0.15)                           ///
          GRIDn(integer 0)                          ///
          noCONStant                                ///
          REPS(integer 1000)                        ///
          DAVies                                    ///
          SEED(string)                              ///
          HANSENCOMPAT ]

    if `trim' < 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in [0, 0.5)"
        exit 198
    }
    if `reps' < 100 {
        display as error "{bf:reps()} below 100 gives a p-value with no useful precision"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    local hascons      = cond("`constant'"=="", 1, 0)
    local hansencompat = cond("`hansencompat'"!="", 1, 0)

    marksample touse
    markout `touse' `threshvar' `invariant'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'
    quietly count if `touse'
    if r(N) == 0 error 2000

    local xlist ""
    local xvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local xlist `r(varlist)'
        fvrevar `xlist' if `touse'
        local xvars `r(varlist)'
    }
    local zlist ""
    local zvars ""
    if "`invariant'" != "" {
        fvexpand `invariant' if `touse'
        local zlist `r(varlist)'
        fvrevar `zlist' if `touse'
        local zvars `r(varlist)'
    }
    if "`xlist'" == "" & `hascons' == 0 {
        display as error "no regressors to test for a threshold effect"
        exit 102
    }

    * threshvar() may carry a time-series or factor operator -- thtar hands
    * one straight through as thvar(L.x) -- so it is materialised here. The
    * reported name stays the one the user typed.
    local qname "`threshvar'"
    fvrevar `threshvar' if `touse'
    local qvar `r(varlist)'
    mata: tk_thtest()

    tempname SF SL PF PL
    matrix `SF' = __tk_statf
    matrix `SL' = __tk_statl
    matrix `PF' = __tk_pf
    matrix `PL' = __tk_pl
    local n     = __tk_n
    local ng    = __tk_ngrid
    local gmaxf = __tk_gmaxf
    tempname gmaxf_s
    scalar `gmaxf_s' = __tk_gmaxf
    local gmaxl = __tk_gmaxl
    tempname gmaxl_s
    scalar `gmaxl_s' = __tk_gmaxl
    local nsing = __tk_nsing

    * ------------------------------------------------ display
    display ""
    display as text "Test of H0: no threshold effect"
    display as text "  Model:    " as result "`depv'" as text " on " ///
        as result "`xlist'" cond(`hascons'," _cons","")
    if "`zlist'" != "" {
        display as text "  Conditioning on (no switch): " as result "`zlist'"
    }
    display as text "  Threshold variable: " as result "`threshvar'" ///
        as text "   candidates: " as result "`ng'" ///
        as text "   trimming: " as result %4.2f `trim'
    display as text "  Bootstrap: fixed-regressor, " as result "`reps'" ///
        as text " reps, residuals from the " ///
        as result cond(`hansencompat', "null (global OLS) fit", "threshold fit")
    display ""
    display as text "{hline 72}"
    display as text "  Statistic" _col(26) "value" _col(40) "boot p" _col(52) "MC s.e." ///
        _col(62) "argmax"
    display as text "{hline 72}"
    display as text "  Homoskedastic F family" as text _col(62) as result %10.0g `gmaxf'
    local names sup ave exp
    forvalues i = 1/3 {
        local nm : word `i' of `names'
        local se = sqrt(`PF'[1,`i']*(1-`PF'[1,`i'])/`reps')
        display as text "    `nm'-F" _col(22) as result %10.4f `SF'[1,`i'] ///
            _col(38) %10.4f `PF'[1,`i'] _col(50) as text %9.4f `se'
    }
    display as text "  White-robust LM family" as text _col(62) as result %10.0g `gmaxl'
    forvalues i = 1/3 {
        local nm : word `i' of `names'
        local se = sqrt(`PL'[1,`i']*(1-`PL'[1,`i'])/`reps')
        display as text "    `nm'-LM" _col(22) as result %10.4f `SL'[1,`i'] ///
            _col(38) %10.4f `PL'[1,`i'] _col(50) as text %9.4f `se'
    }
    display as text "{hline 72}"
    display as text "  Recommended: {bf:sup-LM}. Hansen (1996, Table II) shows the robust"
    display as text "  sup-Wald test is badly oversized in finite samples while sup-LM is not."
    display as text "  Choose the statistic before looking at the table: reporting the"
    display as text "  smallest of six p-values is a specification search."
    if `nsing' > 0 {
        display as text "  {it:note}: " as result `nsing' as text " grid point(s) had a singular" ///
            " variance and contributed 0."
    }

    * ------------------------------------------------ return
    tempname DF DL DVF DVL DQ PATHF PATHL
    scalar `DF'  = __tk_davf
    scalar `DL'  = __tk_davl
    scalar `DVF' = __tk_davvf
    scalar `DVL' = __tk_davvl
    scalar `DQ'  = __tk_davq
    matrix `PATHF' = __tk_pathf
    matrix `PATHL' = __tk_pathl
    matrix colnames `PATHF' = gamma statF
    matrix colnames `PATHL' = gamma statLM

    if "`davies'" != "" {
        display _n as text "Davies (1987) upper bound on the p-value"
        display as text "{hline 72}"
        display as text "  restrictions tested (df)" _col(50) as result %20.0f `DQ'
        display as text "  sup-F bound" _col(50) as result %20.4f `DF'
        display as text "  sup-LM bound" _col(50) as result %20.4f `DL'
        display as text "  total variation of sqrt(F) along the grid" ///
            _col(50) as result %20.4f `DVF'
        display as text "  total variation of sqrt(LM) along the grid" ///
            _col(50) as result %20.4f `DVL'
        display as text "{hline 72}"
        display as text "  The threshold is unidentified under the null, so the"
        display as text "  sup statistic is NOT chi-squared however large the"
        display as text "  sample. Davies bounds its tail analytically:"
        display as text "  P(chi2 > M) plus a penalty that grows with how much"
        display as text "  the path MOVES along the grid. The first term is what"
        display as text "  you would get if the threshold were known; the second"
        display as text "  is the price of having searched for it."
        display as text ""
        display as text "  It is an UPPER BOUND, not a p-value. The true tail"
        display as text "  probability is smaller, so a rejection by Davies is a"
        display as text "  safe rejection and a non-rejection is not evidence of"
        display as text "  linearity. Use it as an independent cross-check on the"
        display as text "  bootstrap: the two are computed from entirely"
        display as text "  different arguments, so agreement is reassuring and a"
        display as text "  large gap is a warning about one of them."
        display as text ""
        display as text "  The variation is measured on the grid, so a coarse"
        display as text "  grid understates it and makes the bound look tighter"
        display as text "  than it is. Compare across {bf:gridn()} before"
        display as text "  leaning on it."
        if `DF' < . & `DL' < . {
            display as text ""
            display as text "  bootstrap p-values for comparison:  sup-F " ///
                as result %6.4f `PF'[1,1] as text "   sup-LM " ///
                as result %6.4f `PL'[1,1]
        }
    }

    return scalar N        = `n'
    return scalar reps     = `reps'
    return scalar trim     = `trim'
    return scalar n_grid   = `ng'
    return scalar gamma_f  = `gmaxf_s'
    return scalar gamma_lm = `gmaxl_s'
    return scalar supF     = `SF'[1,1]
    return scalar aveF     = `SF'[1,2]
    return scalar expF     = `SF'[1,3]
    return scalar supLM    = `SL'[1,1]
    return scalar aveLM    = `SL'[1,2]
    return scalar expLM    = `SL'[1,3]
    return scalar p_supF   = `PF'[1,1]
    return scalar p_aveF   = `PF'[1,2]
    return scalar p_expF   = `PF'[1,3]
    return scalar p_supLM  = `PL'[1,1]
    return scalar p_aveLM  = `PL'[1,2]
    return scalar p_expLM  = `PL'[1,3]
    return local  threshvar "`threshvar'"
    return local  depvar    "`depv'"
    return local  cmd       "thtest"
    matrix colnames `SF' = sup ave exp
    matrix colnames `SL' = sup ave exp
    matrix colnames `PF' = sup ave exp
    matrix colnames `PL' = sup ave exp
    return scalar davies_F  = `DF'
    return scalar davies_LM = `DL'
    return scalar davies_vF = `DVF'
    return scalar davies_vLM = `DVL'
    return scalar davies_df = `DQ'
    return matrix pathF = `PATHF', copy
    return matrix pathLM = `PATHL', copy
    return matrix statF = `SF'
    return matrix statLM = `SL'
    return matrix pF = `PF'
    return matrix pLM = `PL'

    _tk_drop
end
