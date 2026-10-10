*! thunitroot_estat 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thunitroot.
*!   regimes   what each regime looks like, and the two rho's side by side
*!   delay     the whole battery by delay m, with the search made visible
*!   coefeq    which coefficients actually differ across regimes (Table VIII)
*!   bootdist  the two bootstrap distributions of W, and why they differ
*!   zplot     the threshold variable over time with lambda marked
*!   regimeplot the series itself, coloured by regime
*!   table     a publication summary

program define thunitroot_estat, rclass
    version 15
    if "`e(cmd)'" != "thunitroot" {
        display as error "last estimates not found, or not from {bf:thunitroot}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        display as error "available: regimes delay coefeq bootdist zplot regimeplot table"
        exit 198
    }
    if "`sub'" == substr("regimeplot", 1, max(7, `l')) {
        Regimeplot `0'
        exit
    }
    if "`sub'" == substr("regimes", 1, max(3, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("delay", 1, max(3, `l')) {
        Delay `0'
        return add
        exit
    }
    if "`sub'" == substr("coefeq", 1, max(3, `l')) {
        Coefeq `0'
        return add
        exit
    }
    if "`sub'" == substr("bootdist", 1, max(4, `l')) {
        Bootdist `0'
        return add
        exit
    }
    if "`sub'" == substr("zplot", 1, max(2, `l')) {
        Zplot `0'
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: regimes delay coefeq bootdist zplot regimeplot table"
    exit 198
end

* ======================================================================
program define Regimes, rclass
    version 15
    local depv "`e(depvar)'"
    tempvar rg zz
    quietly predict byte `rg' if e(sample), regime
    quietly predict double `zz' if e(sample), zvar

    tempname out
    matrix `out' = J(2, 6, .)
    forvalues j = 1/2 {
        quietly summarize `zz' if `rg' == `j'
        matrix `out'[`j',1] = r(N)
        matrix `out'[`j',2] = r(min)
        matrix `out'[`j',3] = r(max)
        quietly summarize D.`depv' if `rg' == `j'
        matrix `out'[`j',4] = r(mean)
        matrix `out'[`j',5] = r(sd)
    }
    * the two rho's, read out of e(b) by name
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local cn : colnames `b'
    local ce : coleq `b'
    local k = colsof(`b')
    local i1 .
    local i2 .
    forvalues i = 1/`k' {
        local nm : word `i' of `cn'
        local eq : word `i' of `ce'
        if "`nm'" == "L1.`depv'" & "`eq'" == "Regime1" local i1 `i'
        if "`nm'" == "L1.`depv'" & "`eq'" == "Regime2" local i2 `i'
    }
    if `i1' < . matrix `out'[1,6] = `b'[1,`i1']
    if `i2' < . matrix `out'[2,6] = `b'[1,`i2']

    matrix colnames `out' = N z_min z_max mean_dy sd_dy rho
    matrix rownames `out' = regime1 regime2

    display _n as text "The two regimes"
    display as text "{hline 76}"
    display as text "  regime" _col(14) "N" _col(24) "Z range" _col(46) ///
        "mean D.`depv'" _col(64) "rho"
    display as text "{hline 76}"
    forvalues j = 1/2 {
        display as text "  `j'  " _continue
        display as text cond(`j'==1, "(Z <  lambda)", "(Z >= lambda)") _continue
        display as result _col(22) %8.0f `out'[`j',1] ///
            _col(32) %9.4f `out'[`j',2] " " %9.4f `out'[`j',3] ///
            _col(54) %10.5f `out'[`j',4] _col(66) %10.5f `out'[`j',6]
    }
    display as text "{hline 76}"
    display as text "  lambda" _col(50) as result %12.6g e(lambda) ///
        as text "   (delay m = " as result e(delay) as text ")"
    display as text "{hline 76}"
    display as text "  rho is the coefficient on `depv'(t-1): zero means a unit root"
    display as text "  IN THAT REGIME. A negative rho in one regime and a rho of"
    display as text "  essentially zero in the other is the partial unit root."
    display as text "  A regime holding under a tenth of the sample is identified by"
    display as text "  very few observations whatever the trimming allowed."
    return matrix regimes = `out', copy
    return scalar lambda = e(lambda)
end

* ======================================================================
program define Delay, rclass
    version 15
    tempname TAB PM
    matrix `TAB' = e(bydelay)
    matrix `PM'  = e(pbydelay)
    local mmin = e(mmin)

    display _n as text "The whole battery, delay by delay"
    display as text "{hline 79}"
    display as text "    m" _col(8) "SSR" _col(22) "lambda" _col(34) "W" ///
        _col(43) "p(W)" _col(52) "R1T" _col(60) "R2T" _col(68) "-t1" _col(75) "-t2"
    display as text "{hline 79}"
    forvalues r = 1/`=rowsof(`TAB')' {
        local m = `mmin' + `r' - 1
        local mk = cond(`m' == e(delay_ssr), "*", cond(`m' == e(delay), "+", " "))
        display as text "  `mk'" as result %3.0f `m' ///
            _col(6) %13.6f `TAB'[`r',2] _col(19) %11.5g `TAB'[`r',1] ///
            _col(30) %9.3f `TAB'[`r',3] _col(39) %9.3f `PM'[`r',2] ///
            _col(48) %8.3f `TAB'[`r',4] _col(56) %8.3f `TAB'[`r',5] ///
            _col(64) %8.3f `TAB'[`r',6] _col(71) %8.3f `TAB'[`r',7]
    }
    display as text "{hline 79}"
    display as text "  * minimises the SSR   + the delay the estimates are reported at"
    display as text "  p(W) is the unit-root-imposed bootstrap p-value of W."
    display as text "{hline 79}"
    display as text "  Why this table and not just the winning row. The delay was"
    display as text "  chosen by minimising the SSR over " as result ///
        `=rowsof(`TAB')' as text " candidates, and the"
    display as text "  p-value in the winning row does not know about that search."
    display as text "  Caner and Hansen report the whole column for the same reason:"
    display as text "  a conclusion that holds at every m is robust, and one that"
    display as text "  holds only at the argmin is a conclusion about the argmin."
    display as text "  Their own application prefers m = 9 over the SSR's m = 12"
    display as text "  because the fits are nearly identical and 9 is interpretable."
    return matrix bydelay  = `TAB', copy
    return matrix pbydelay = `PM', copy
end

* ======================================================================
program define Coefeq, rclass
    version 15
    tempname TSC PT out
    matrix `TSC' = e(wald_coef)
    local haspt 0
    capture confirm matrix e(p_wald_coef)
    if !_rc {
        matrix `PT' = e(p_wald_coef)
        local haspt 1
    }
    local nm : colnames `TSC'
    local k = colsof(`TSC')
    matrix `out' = J(`k', 3, .)
    forvalues i = 1/`k' {
        matrix `out'[`i',1] = `TSC'[1,`i']
        matrix `out'[`i',2] = chi2tail(1, `TSC'[1,`i'])
        if `haspt' matrix `out'[`i',3] = `PT'[1,`i']
    }
    matrix colnames `out' = wald p_chi2 p_boot
    matrix rownames `out' = `nm'

    display _n as text "Which coefficients differ across regimes?"
    display as text "{hline 72}"
    display as text "  coefficient" _col(36) "Wald" _col(50) "chi2(1) p" ///
        _col(62) "boot p"
    display as text "{hline 72}"
    forvalues i = 1/`k' {
        local v : word `i' of `nm'
        display as text "  " %-30s abbrev("`v'", 30) ///
            as result _col(32) %12.4f `out'[`i',1] _col(46) %12.4f `out'[`i',2] ///
            _col(58) %12.4f `out'[`i',3]
    }
    display as text "{hline 72}"
    display as text "  Each statistic is (b1 - b2)^2 / (v1 + v2) for one coefficient."
    display as text "  USE THE BOOTSTRAP COLUMN. The chi2(1) p-value is printed only"
    display as text "  to show how far off it is: the threshold was estimated, so the"
    display as text "  limit is not chi-squared, and for the coefficient on the LEVEL"
    display as text "  it is not even nuisance-free. Caner and Hansen bootstrap every"
    display as text "  one of these (their Table VIII)."
    display as text "{hline 72}"
    display as text "  What to do with it. If only the intercept and `e(depvar)'(t-1)"
    display as text "  differ, the threshold acts on the LEVEL and the persistence and"
    display as text "  not on the short-run dynamics. Refit with {bf:switch()} naming"
    display as text "  just the lags that do differ, and {bf:joint()} to test the"
    display as text "  restriction jointly rather than coefficient by coefficient."
    return matrix coefeq = `out', copy
end

* ======================================================================
program define Bootdist, rclass
    version 15
    syntax [, GRaph BINs(integer 30) SAVing(string asis) * ]
    tempname BU BC
    * matrix X = e(name) does NOT fail when e(name) is undefined: Stata reads
    * the missing scalar and builds a 1 x 1 matrix, rc = 0. Confirm first.
    local hasu 0
    local hasc 0
    capture confirm matrix e(bdist_unres)
    if !_rc {
        matrix `BU' = e(bdist_unres)
        local hasu 1
    }
    capture confirm matrix e(bdist_ur)
    if !_rc {
        matrix `BC' = e(bdist_ur)
        local hasc 1
    }
    if !`hasu' & !`hasc' {
        display as error "no bootstrap distribution stored; refit with {bf:reps()} > 0"
        exit 498
    }

    display _n as text "The two bootstrap distributions of W"
    display as text "{hline 72}"
    display as text "  observed W" _col(46) as result %14.4f e(W)
    display as text "  replications" _col(46) as result %14.0f e(reps)
    display as text "{hline 72}"
    display as text "  DGP" _col(30) "90%" _col(42) "95%" _col(54) "99%" _col(64) "p"
    display as text "{hline 72}"
    if `hasu' {
        Quants `BU' `=e(reps)'
        display as text "  rho unrestricted" _col(24) as result ///
            %12.3f r(q90) _col(36) %12.3f r(q95) _col(48) %12.3f r(q99) ///
            _col(60) %10.4f e(p_W_unres)
        return scalar q95_unres = r(q95)
    }
    if `hasc' {
        Quants `BC' `=e(reps)'
        display as text "  unit root imposed" _col(24) as result ///
            %12.3f r(q90) _col(36) %12.3f r(q95) _col(48) %12.3f r(q99) ///
            _col(60) %10.4f e(p_W_ur)
        return scalar q95_ur = r(q95)
    }
    display as text "{hline 72}"
    display as text "  The two differ because the DGP differs: the first draws"
    display as text "  from a stationary AR using rho-hat, the second from a random"
    display as text "  walk. Which of them gives the larger p-value is not fixed in"
    display as text "  advance and depends on the series; when rho-hat is close to"
    display as text "  zero the two DGPs are nearly the same and the ordering is"
    display as text "  essentially noise at a few hundred replications."
    display as text "  Report " as result %6.4f e(p_W) as text ", the larger of the two."
    if `hasu' return matrix bdist_unres = `BU', copy
    if `hasc' return matrix bdist_ur    = `BC', copy

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                if `hasu' svmat double `BU', names(wu)
                if `hasc' svmat double `BC', names(wc)
            }
            local pl ""
            local lg ""
            local i 0
            if `hasu' {
                local ++i
                local pl `pl' (histogram wu1, bin(`bins') fcolor(navy%40) lcolor(navy))
                local lg `lg' `i' "rho unrestricted"
            }
            if `hasc' {
                local ++i
                local pl `pl' (histogram wc1, bin(`bins') fcolor(cranberry%40) lcolor(cranberry))
                local lg `lg' `i' "unit root imposed"
            }
            twoway `pl' , xline(`=e(W)', lcolor(black) lwidth(medthick))   ///
                xtitle("bootstrap W") ytitle("density")                    ///
                title("Two null distributions for one statistic")          ///
                subtitle("the vertical line is the observed W")            ///
                legend(order(`lg') size(small) rows(2)) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

program define Quants, rclass
    version 15
    args M reps
    preserve
        quietly {
            clear
            svmat double `M', names(w)
            keep if w1 < .
            sort w1
            local n = _N
            local i90 = round(`n' * 0.90)
            local i95 = round(`n' * 0.95)
            local i99 = round(`n' * 0.99)
            if `i90' < 1 local i90 1
            if `i95' < 1 local i95 1
            if `i99' < 1 local i99 1
            if `i99' > `n' local i99 `n'
            scalar __q90 = w1[`i90']
            scalar __q95 = w1[`i95']
            scalar __q99 = w1[`i99']
        }
    restore
    return scalar q90 = __q90
    return scalar q95 = __q95
    return scalar q99 = __q99
    _tk_drop __q90 __q95 __q99
end

* ======================================================================
program define Zplot
    version 15
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local tv "`e(timevar)'"
    tempvar zz
    quietly predict double `zz' if e(sample), zvar
    if `"`title'"' == "" {
        local title "Threshold variable Z(t-1) and the estimated lambda"
    }
    twoway (line `zz' `tv' if e(sample), lcolor(navy))        ///
        , yline(`=e(lambda)', lcolor(red) lpattern(dash))     ///
          ytitle("Z(t-1)") xtitle("`tv'")                     ///
          title(`"`title'"')                                  ///
          note("regime 1 is below the dashed line")           ///
          legend(off) `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
program define Regimeplot
    version 15
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local depv "`e(depvar)'"
    local tv   "`e(timevar)'"
    tempvar rg y1 y2
    quietly predict byte `rg' if e(sample), regime
    quietly generate double `y1' = `depv' if `rg' == 1
    quietly generate double `y2' = `depv' if `rg' == 2
    if `"`title'"' == "" {
        local title "`depv', classified by regime"
    }
    twoway (scatter `y1' `tv', msymbol(Oh) msize(small) mcolor(navy))        ///
           (scatter `y2' `tv', msymbol(X)  msize(small) mcolor(cranberry))   ///
        , ytitle("`depv'") xtitle("`tv'")                                    ///
          title(`"`title'"')                                                 ///
          legend(order(1 "regime 1 (Z < lambda)" 2 "regime 2 (Z >= lambda)") ///
            size(small) rows(1))                                             ///
          `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
program define Table
    version 15
    tempname CV
    matrix `CV' = e(cv)
    display _n as text "{hline 78}"
    display as text "Threshold autoregression with a near unit root -- summary"
    display as text "{hline 78}"
    display as text "  Series" _col(46) as result "`e(depvar)'"
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "  Lags of the difference" _col(46) as result %12.0f e(k_lags)
    display as text "  Deterministics" _col(42) as result ///
        cond(e(trend), "constant + trend", "constant")
    display as text "  Threshold variable" _col(42) as result "`e(ztype)'"
    display as text "  Delay m (reported / argmin SSR)" _col(42) as result ///
        %7.0f e(delay) " /" %7.0f e(delay_ssr)
    display as text "  Threshold lambda" _col(46) as result %12.6g e(lambda)
    display as text "  Split" _col(46) as result ///
        %6.0f e(N_regime1) " /" %6.0f e(N_regime2)
    display as text "{hline 78}"
    display as text "  Threshold effect W" _col(46) as result %12.4f e(W)
    display as text "    p, rho unrestricted" _col(46) as result %12.4f e(p_W_unres)
    display as text "    p, unit root imposed" _col(46) as result %12.4f e(p_W_ur)
    display as text "    p to report (the larger)" _col(46) as result %12.4f e(p_W)
    display as text "{hline 78}"
    display as text "  Unit root R1T (one-sided)" _col(46) as result %12.4f e(R1T) ///
        as text "  p = " as result %6.4f e(p_R1T)
    display as text "  Unit root R2T (two-sided)" _col(46) as result %12.4f e(R2T) ///
        as text "  p = " as result %6.4f e(p_R2T)
    display as text "  -t1 regime 1" _col(46) as result %12.4f e(t1) ///
        as text "  p = " as result %6.4f e(p_t1)
    display as text "  -t2 regime 2" _col(46) as result %12.4f e(t2) ///
        as text "  p = " as result %6.4f e(p_t2)
    display as text "{hline 78}"
    display as text "  Linear ADF t for comparison" _col(46) as result %12.4f e(adf)
    display as text "{hline 78}"
    display as text "  5% bounds: R1T " as result %6.2f `CV'[1,2] as text ///
        "   R2T " as result %6.2f `CV'[2,2] as text ///
        "   -t " as result %6.2f `CV'[3,2]
    display as text "  R2T under an IDENTIFIED threshold (Theorem 6): " ///
        as result %6.2f `CV'[4,2]
    display as text "{hline 78}"
end
