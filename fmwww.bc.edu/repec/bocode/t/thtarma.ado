*! thtarma 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Supremum Lagrange-multiplier test for a threshold in an ARMA model.
*! H0: ARMA(p,q)   H1: TARMA(p,q) with an unknown threshold in X(t-d).
*!
*!   Goracci, Giannerini, Chan and Tong (2023) Statistica Sinica
*!     33:1879-1901, doi:10.5705/ss.202021.0120
*!   Giannerini, Goracci and Rahbek (2022) arXiv:2201.00028 -- validity of
*!     the recursive bootstrap, and the oversizing of the asymptotic test
*!   Chan and Goracci (2019) JTSA 40:256-264, doi:10.1111/jtsa.12440
*!
*! See thtarma.sthlp.

program define thtarma, rclass
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        AR(integer)                        ///
        [ MA(integer 1)                    ///
          DELAY(integer 1)                 ///
          STAR                             ///
          TRIM(real 0.25)                  ///
          GRIDn(integer 100)               ///
          REPS(integer 499)                ///
          SEED(string)                     ///
          ASYMPtotic                       ///
          Level(cilevel) ]

    * ------------------------------------------------ option validation
    if `ar' < 1 | `ar' > 12 {
        display as error "{bf:ar()} must be between 1 and 12"
        exit 198
    }
    if `ma' < 0 | `ma' > 6 {
        display as error "{bf:ma()} must be between 0 and 6"
        exit 198
    }
    if `delay' < 1 | `delay' > 12 {
        display as error "{bf:delay()} must be between 1 and 12"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    local starflag = cond("`star'" != "", 1, 0)
    if `starflag' & `ma' == 0 {
        display as error "{bf:star} tests a threshold in the MA part, but"
        display as error "{bf:ma(0)} leaves no MA part to test. Either drop"
        display as error "{bf:star} or raise {bf:ma()}."
        exit 198
    }
    if "`level'" == "" local level = c(level)

    * the series must be tsset, because the delay and the lags are
    * time-series operations and a gap would silently misalign them
    capture tsset
    if _rc {
        display as error "{bf:thtarma} needs the data {bf:tsset}"
        exit 111
    }
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        display as error "{bf:thtarma} is a single time-series command;"
        display as error "these data are panel-tsset. Panel threshold models"
        display as error "are outside the scope of this package."
        exit 198
    }

    marksample touse
    quietly count if `touse'
    local n = r(N)
    if `n' < 20 + `ar' + `ma' {
        display as error "too few observations: `n'"
        exit 2001
    }

    * the sample must be a single contiguous run, or the recursion that
    * defines an ARMA residual would run across a hole in the calendar
    quietly summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    quietly count if `touse'
    if (`tmax' - `tmin' + 1) != r(N) {
        display as error "the estimation sample has gaps in `tvar'."
        display as error "An ARMA residual is defined by a recursion over"
        display as error "consecutive periods; a gap would make every"
        display as error "residual after it meaningless. Restrict to a"
        display as error "contiguous span with {bf:if}."
        exit 198
    }

    local yv "`varlist'"
    local plag `ar'
    local qlag `ma'
    local dly  `delay'
    local rlo  `trim'
    local rhi  = 1 - `trim'
    if `gridn' < 0 {
        display as error "{bf:gridn()} cannot be negative"
        exit 198
    }
    * The bootstrap re-searches the grid on EVERY replication, so an
    * uncapped grid multiplies the cost by reps(). The cap is applied
    * identically to the observed statistic and to every bootstrap draw,
    * which is what matters: the bootstrap must mimic the procedure that
    * produced the observed number, cap included. gridn(0) means every
    * distinct value in the range.
    local maxgrid `gridn'
    local nreps = cond("`asymptotic'" != "", 0, `reps')

    if "`seed'" != "" set seed `seed'

    _tk_drop
    mata: tk_thtarma()

    if __tk_tafail == 1 {
        _tk_drop
        display as error "too few usable observations"
        exit 2001
    }
    if __tk_tafail == 2 {
        _tk_drop
        display as error "the null ARMA(`ar',`ma') could not be estimated."
        display as error "Try a smaller {bf:ma()}, or check the series is"
        display as error "stationary with {helpb thunitroot}."
        exit 498
    }
    if __tk_tafail == 3 {
        _tk_drop
        display as error "the threshold grid is empty at trim(`trim')"
        exit 498
    }
    if __tk_tafail == 4 {
        _tk_drop
        display as error "the statistic could not be computed at any"
        display as error "candidate threshold"
        exit 498
    }

    tempname B QT GRID BOOT
    matrix `B'  = __tk_tab
    matrix `QT' = __tk_taqt
    matrix `GRID' = __tk_tagrid
    capture confirm matrix __tk_taboot
    local hasboot = (_rc == 0)
    if `hasboot' matrix `BOOT' = __tk_taboot

    local stat  = __tk_tastat
    local rhat  = __tk_tarhat
    tempname rhat_s
    scalar `rhat_s' = __tk_tarhat
    local pb    = __tk_tap
    local s2    = __tk_tas2
    local npt   = __tk_tanpt
    local ng    = __tk_tang
    local conv  = __tk_taconv
    local iter  = __tk_taiter
    local marad = __tk_tamarad
    local nbt   = __tk_tanboot
    local nused = __tk_tan
    _tk_drop

    * ------------------------------------------------ the names of e(b)
    local nm "_cons"
    forvalues i = 1/`ar' {
        local nm "`nm' L`i'.`yv'"
    }
    forvalues i = 1/`ma' {
        local nm "`nm' ma`i'"
    }
    matrix colnames `B' = `nm'

    * ------------------------------------------------ display
    local sname = cond(`starflag', "sLM*", "sLM")
    local what  = cond(`starflag', "AR and MA parameters", "AR parameters")

    display _n as text "Supremum LM test for a threshold in an ARMA model"
    display as text "{hline 72}"
    display as text "  H0: ARMA(`ar',`ma')" _col(40) ///
        "H1: TARMA(`ar',`ma'), threshold in L`delay'.`yv'"
    display as text "  threshold tested in the" _col(40) as result "`what'"
    display as text "{hline 72}"
    display as text "  observations" _col(50) as result %20.0f `nused'
    display as text "  null ARMA converged" _col(50) as result %20s ///
        cond(`conv', "yes (`iter' iterations)", "NO")
    display as text "  residual variance" _col(50) as result %20.6f `s2'
    if `ma' > 0 {
        display as text "  largest MA root modulus (inverse)" _col(50) ///
            as result %20.4f `marad'
    }
    display as text "  threshold grid points" _col(50) as result %20.0f `ng'
    display as text "  usable grid points" _col(50) as result %20.0f `npt'
    display as text "{hline 72}"
    display as text "  `sname' statistic" _col(50) as result %20.4f `stat'
    display as text "  attained at threshold" _col(50) as result %20.6f `rhat'

    if `nbt' > 0 {
        display as text "  bootstrap p-value" _col(50) as result %20.4f `pb'
        display as text "  bootstrap replications used" _col(50) ///
            as result %20.0f `nbt'
    }

    * the tabulated asymptotic quantiles, only where they are valid
    local hasqt = (`QT'[1,1] < .)
    if `hasqt' {
        display as text "{hline 72}"
        display as text "  Asymptotic critical values (Table 1 of the paper)"
        display as text "    90%" _col(20) as result %10.2f `QT'[1,1] ///
            as text _col(34) "95%" _col(44) as result %10.2f `QT'[1,2]
        display as text "    99%" _col(20) as result %10.2f `QT'[1,3] ///
            as text _col(34) "99.9%" _col(44) as result %10.2f `QT'[1,4]
        local verdict "not rejected at 10%"
        if `stat' > `QT'[1,1] local verdict "rejected at 10%"
        if `stat' > `QT'[1,2] local verdict "rejected at 5%"
        if `stat' > `QT'[1,3] local verdict "rejected at 1%"
        if `stat' > `QT'[1,4] local verdict "rejected at 0.1%"
        display as text "    asymptotic verdict" _col(50) as result %20s "`verdict'"
    }
    display as text "{hline 72}"

    * ------------------------------------------------ the standing caveats
    if `nbt' > 0 {
        display as text "  The bootstrap p-value is the one to report."
        display as text "  Giannerini, Goracci and Rahbek (2022) prove the"
        display as text "  recursive bootstrap valid for this statistic and"
        display as text "  show the asymptotic test is {bf:oversized} at small"
        display as text "  and moderate n -- it rejects a linear ARMA too"
        display as text "  often. Every replication re-estimates the ARMA and"
        display as text "  re-searches the whole grid, so the p-value prices"
        display as text "  in the search the statistic performed."
    }
    else {
        display as error "  No bootstrap was run, so only the asymptotic"
        display as error "  verdict is available. That test is OVERSIZED at"
        display as error "  small and moderate n. Drop {bf:asymptotic} to get"
        display as error "  the bootstrap p-value before reporting a rejection."
    }
    if !`hasqt' {
        display as text "  No tabulated critical values apply here. The"
        display as text "  paper's Table 1 covers p = 1..4, q = 1..2 and the"
        display as text "  25th-75th percentile range ({bf:trim(0.25)}) only,"
        display as text "  and a quantile read off a different configuration"
        display as text "  would be a wrong critical value that looks right."
    }
    if `conv' == 0 {
        display as error "  WARNING: the null ARMA did not converge. The"
        display as error "  statistic is computed at the last iterate and"
        display as error "  should not be reported."
    }
    if `ma' > 0 & `marad' > 0.95 {
        display as error "  WARNING: the estimated MA polynomial is close to"
        display as error "  non-invertible (modulus `=string(`marad',"%5.3f")')."
        display as error "  Assumption A1 of the paper is close to failing and"
        display as error "  every score recursion is near-explosive here."
    }

    * ------------------------------------------------ stored results
    return scalar stat    = `stat'
    return scalar p       = `pb'
    return scalar gamma   = `rhat_s'
    return scalar sigma2  = `s2'
    return scalar N       = `nused'
    return scalar ar      = `ar'
    return scalar ma      = `ma'
    return scalar delay   = `delay'
    return scalar trim    = `trim'
    return scalar ngrid   = `ng'
    return scalar npoints = `npt'
    return scalar reps    = `nbt'
    return scalar converged = `conv'
    return scalar marad   = `marad'
    if `hasqt' {
        return scalar cv90  = `QT'[1,1]
        return scalar cv95  = `QT'[1,2]
        return scalar cv99  = `QT'[1,3]
        return scalar cv999 = `QT'[1,4]
    }
    return local  statname "`sname'"
    return local  cmd      "thtarma"
    return local  depvar   "`yv'"
    return matrix b     = `B', copy
    return matrix grid  = `GRID', copy
    if `hasboot' return matrix bootdist = `BOOT', copy
end
