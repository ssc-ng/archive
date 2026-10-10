*! thmtar_estat 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thmtar.
*!   regimes    the two adjustment coefficients side by side, with the
*!              symmetry test and the regime counts
*!   halflife   the half-life of a deviation in each regime
*!   profile    the SSR profile over the threshold grid, with a plot
*!   bootdist   the bootstrap distribution of the Phi statistic
*!   zplot      the adjustment variable over time with the threshold drawn
*!   table      a publication summary

program define thmtar_estat, rclass
    version 15
    if "`e(cmd)'" != "thmtar" {
        display as error "last estimates not found, or not from {bf:thmtar}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("regimes", 1, max(4, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("halflife", 1, max(4, `l')) {
        Halflife `0'
        return add
        exit
    }
    if "`sub'" == substr("profile", 1, max(4, `l')) {
        Profile `0'
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
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: regimes halflife profile bootdist zplot table"
    exit 198
end

* ======================================================================
program define Regimes, rclass
    version 15
    local isband = e(band)
    tempname b V out
    matrix `b' = e(b)
    matrix `V' = e(V)
    local n1 = e(N_regime1)
    local n2 = e(N_regime2)

    display _n as text "Asymmetric adjustment, " as result "`e(model)'"
    display as text "{hline 72}"
    display as text "  Adjustment variable" _col(44) as result "`e(stage1)'"
    if `isband' {
        display as text "  Band limits" _col(44) as result ///
            %11.6g e(tau_lower) "  " %11.6g e(tau_upper)
        display as text "  Observations below / inside / above" _col(44) as result ///
            %7.0fc `n2' " " %7.0fc e(N_inband) " " %7.0fc `n1'
        display as text "  Inside the band there is NO adjustment by construction."
    }
    else {
        display as text "  Threshold tau" _col(44) as result %14.6g e(tau)
        display as text "  Threshold type" _col(44) as result "`e(threshtype)'"
        display as text "  Observations with indicator >= tau / < tau" _col(48) ///
            as result %7.0fc `n1' " " %7.0fc `n2'
    }
    display as text "{hline 72}"

    matrix `out' = J(2, 4, .)
    forvalues i = 1/2 {
        matrix `out'[`i',1] = `b'[1,`i']
        matrix `out'[`i',2] = sqrt(`V'[`i',`i'])
        if `V'[`i',`i'] > 0 {
            matrix `out'[`i',3] = `b'[1,`i']/sqrt(`V'[`i',`i'])
            matrix `out'[`i',4] = 2*normal(-abs(`b'[1,`i']/sqrt(`V'[`i',`i'])))
        }
    }
    local cn : colnames `b'
    local r1 : word 1 of `cn'
    local r2 : word 2 of `cn'
    matrix rownames `out' = `r1' `r2'
    matrix colnames `out' = rho se z p
    matrix list `out', noheader format(%10.5f)

    display _n as text "  Symmetry test, H0: the two adjustment coefficients are equal"
    display as text "     chi2(1) = " as result %9.4f e(f_sym) ///
        as text ",  p = " as result %6.4f e(p_sym)
    display as text "  Phi test, H0: no adjustment in either regime (rho1 = rho2 = 0)"
    display as text "     Phi = " as result %9.4f e(phi) ///
        as text ",  bootstrap p = " as result %6.4f e(p_phi) ///
        as text " (" as result e(boot_reps) as text " reps, MC s.e. " ///
        as result %5.4f e(p_mcse) as text ")"
    display as text "{hline 72}"
    display as text "  The Phi test is bootstrapped rather than compared with the"
    display as text "  Enders-Siklos tables, which assume a KNOWN threshold. The"
    display as text "  bootstrap repeats the whole procedure, grid search included."
    display as text "  Rejecting Phi but not symmetry means there is adjustment and no"
    display as text "  evidence that it differs across regimes: a linear error-correction"
    display as text "  model is then the parsimonious choice."

    return matrix rho = `out', copy
    return scalar p_sym = e(p_sym)
    return scalar p_phi = e(p_phi)
end

* ======================================================================
* Half-life of a deviation. D.z = rho L.z + ... so z_t = (1+rho) z_{t-1} + ...
* and a deviation decays at rate phi = 1 + rho.
* ======================================================================
program define Halflife, rclass
    version 15
    tempname b V out
    matrix `b' = e(b)
    matrix `V' = e(V)
    local cn : colnames `b'
    matrix `out' = J(2, 4, .)
    local rn ""
    display _n as text "Half-life of a deviation, by regime"
    display as text "{hline 72}"
    display as text "  regime" _col(22) "rho" _col(34) "phi = 1+rho" _col(50) "half-life"
    display as text "{hline 72}"
    * hold rho in a SCALAR: `local rho = b[1,i]' rounds to about 9 significant
    * digits, which is enough to break an exact comparison against e(b)
    tempname RHO PHI HL
    forvalues i = 1/2 {
        local nm : word `i' of `cn'
        scalar `RHO' = `b'[1,`i']
        scalar `PHI' = 1 + `RHO'
        scalar `HL'  = .
        local note ""
        if `PHI' > 0 & `PHI' < 1 {
            scalar `HL' = ln(0.5)/ln(`PHI')
        }
        else if `PHI' >= 1 {
            local note "no mean reversion"
        }
        else if `PHI' <= -1 {
            local note "explosive oscillation"
        }
        else {
            scalar `HL' = ln(0.5)/ln(abs(`PHI'))
            local note "oscillatory"
        }
        matrix `out'[`i',1] = `b'[1,`i']
        matrix `out'[`i',2] = 1 + `b'[1,`i']
        matrix `out'[`i',3] = `HL'
        matrix `out'[`i',4] = sqrt(`V'[`i',`i'])
        local rn `rn' `nm'
        display as text "  `nm'" _col(18) as result %10.5f `RHO' ///
            _col(32) %12.5f `PHI' _col(48) ///
            cond(`HL' < ., "`: display %10.3f `HL''", "         .") ///
            as text "  `note'"
    }
    matrix rownames `out' = `rn'
    matrix colnames `out' = rho phi halflife se_rho
    display as text "{hline 72}"
    display as text "  The half-life is ln(.5)/ln(1+rho), in periods of the time variable."
    display as text "  It is a summary of ONE regime taken on its own: a process that"
    display as text "  switches regimes does not decay at either rate for long. Read the"
    display as text "  two numbers as a comparison, not as a forecast."
    if e(band) == 1 {
        display as text "  In a band model these apply OUTSIDE the band only; inside it"
        display as text "  there is no adjustment and the half-life is infinite."
    }
    return matrix halflife = `out'
end

* ======================================================================
program define Profile, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    capture confirm matrix e(profile)
    if _rc {
        display as error "no threshold profile stored: refit with {bf:consistent}"
        display as error "or {bf:band} so that the threshold is searched over a grid"
        exit 498
    }
    tempname P
    matrix `P' = e(profile)
    display _n as text "Profile of the residual sum of squares over the threshold grid"
    display as text "{hline 72}"
    display as text "  candidate thresholds searched" _col(50) as result %14.0f rowsof(`P')
    if e(band) == 1 {
        display as text "  band limits at the minimum" _col(44) as result ///
            %11.6g e(tau_lower) " " %11.6g e(tau_upper)
    }
    else {
        display as text "  minimum at" _col(50) as result %14.6g e(tau)
    }
    display as text "  SSR there" _col(50) as result %14.6f e(ssr)
    display as text "{hline 72}"
    display as text "  A flat profile means the threshold is weakly identified. The"
    display as text "  adjustment coefficients are still consistent; the threshold itself"
    display as text "  should then not be interpreted as an economic magnitude."
    return matrix profile = `P', copy
    if "`graph'" != "" {
        local cn : colnames `P'
        local band = e(band)
        local tauv = e(tau)
        if "`tauv'" == "" local tauv .
        preserve
            quietly {
                clear
                svmat double `P', names(col)
            }
            local xv : word 1 of `cn'
            local yv : word 2 of `cn'
            quietly keep if `yv' < .
            * a band model profiles over the band limit, and e(tau) is then not
            * the x-axis value, so the reference line is drawn only when it is
            local xl ""
            if `band' == 0 & `tauv' < . local xl xline(`tauv', lcolor(red) lpattern(dash))
            twoway (line `yv' `xv', lcolor(navy))                        ///
                , `xl'                                                   ///
                  ytitle("residual sum of squares")                      ///
                  xtitle("`=cond(`band', "band limit", "threshold")'")    ///
                  title("Chan (1993) grid search")                       ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Bootdist, rclass
    version 15
    syntax [, GRaph BINs(integer 30) SAVing(string asis) * ]
    capture confirm matrix e(bdist)
    if _rc {
        display as error "no bootstrap distribution stored"
        exit 498
    }
    tempname D
    matrix `D' = e(bdist)
    display _n as text "Bootstrap distribution of the Phi statistic"
    display as text "{hline 72}"
    display as text "  replications" _col(50) as result %14.0f rowsof(`D')
    display as text "  observed Phi" _col(50) as result %14.4f e(phi)
    display as text "  bootstrap p-value" _col(50) as result %14.4f e(p_phi)
    display as text "  Monte Carlo s.e. of the p-value" _col(50) as result %14.4f e(p_mcse)
    display as text "{hline 72}"
    display as text "  Each replication builds a random walk from the null residuals and"
    display as text "  re-runs the whole procedure, the grid search included, so the"
    display as text "  distribution accounts for having estimated the threshold."
    return matrix bdist = `D', copy
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `D', names(phib)
                keep if phib1 < .
            }
            twoway (histogram phib1, bin(`bins') fcolor(gs12) lcolor(gs6)) ///
                , xline(`=e(phi)', lcolor(red) lwidth(medthick))           ///
                  xtitle("bootstrap Phi") ytitle("density")                ///
                  title("Bootstrap null distribution of Phi")              ///
                  subtitle("random walks built from the null residuals")   ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Zplot, rclass
    version 15
    syntax [, SAVing(string asis) * ]
    * copy out of e() first: rebuilding z needs a regression
    local depv  "`e(depvar)'"
    local cv    "`e(cointvars)'"
    local isband = e(band)
    local ismtar = ("`e(model)'" == "mtar")
    local tv    "`e(timevar)'"
    local st1   "`e(stage1)'"
    tempname TAU TL TU
    scalar `TAU' = e(tau)
    if `isband' {
        scalar `TL' = e(tau_lower)
        scalar `TU' = e(tau_upper)
    }

    tempname B1
    local hasb1 0
    * matrix X = e(name) does NOT fail when e(name) is undefined: Stata reads
    * the missing scalar and builds a 1 x 1 matrix whose column is called c1.
    * So confirm the matrix exists first, and require a first stage at all.
    if "`cv'" != "" {
        capture confirm matrix e(b_stage1)
        if !_rc {
            matrix `B1' = e(b_stage1)
            local hasb1 1
        }
    }

    * z is rebuilt over EVERY usable observation from the stored first-stage
    * coefficients, because the lag L.z reaches one period before e(sample)
    tempvar touse z
    quietly generate byte `touse' = e(sample)
    quietly generate double `z' = `depv'
    if `hasb1' {
        local s1n : colnames `B1'
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

    tempvar ind
    if `isband' | !`ismtar' {
        quietly generate double `ind' = L.`z'
    }
    else {
        quietly generate double `ind' = LD.`z'
    }

    quietly summarize `ind' if `touse'
    display _n as text "Adjustment variable: " as result "`st1'"
    display as text "{hline 72}"
    display as text "  indicator" _col(44) as result ///
        cond(`isband', "L.z", cond(`ismtar', "LD.z", "L.z"))
    display as text "  mean / s.d." _col(40) as result %11.6f r(mean) " " %11.6f r(sd)
    display as text "  range" _col(40) as result %11.6f r(min) " " %11.6f r(max)
    if `isband' {
        display as text "  band" _col(40) as result %11.6f `TL' " " %11.6f `TU'
    }
    else {
        display as text "  threshold" _col(40) as result %11.6f `TAU'
    }
    display as text "{hline 72}"
    return scalar ind_min = r(min)
    return scalar ind_max = r(max)

    if `isband' {
        twoway (line `ind' `tv' if `touse', lcolor(navy))              ///
            , yline(`=`TL'', lcolor(red) lpattern(dash))               ///
              yline(`=`TU'', lcolor(red) lpattern(dash))               ///
              ytitle("L.z") xtitle("`tv'")                             ///
              title("Adjustment variable and the estimated band")       ///
              legend(off) `options'
    }
    else {
        twoway (line `ind' `tv' if `touse', lcolor(navy))              ///
            , yline(`=`TAU'', lcolor(red) lpattern(dash))              ///
              ytitle(`"`=cond(`ismtar',"LD.z","L.z")'"') xtitle("`tv'") ///
              title("Indicator variable and the estimated threshold")   ///
              legend(off) `options'
    }
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
program define Table
    version 15
    display _n as text "{hline 78}"
    display as text "Asymmetric adjustment -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(46) as result "D.`e(depvar)'"
    display as text "  Model" _col(46) as result "`e(model)'"
    display as text "  Adjustment variable" _col(46) as result "`e(stage1)'"
    if "`e(cointvars)'" != "" {
        display as text "  Cointegrating regressors" _col(46) as result "`e(cointvars)'"
    }
    display as text "  Lagged differences" _col(46) as result %12.0f e(lags)
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "{hline 78}"
    if e(band) == 1 {
        display as text "  Band limits" _col(40) as result ///
            %11.6g e(tau_lower) " " %11.6g e(tau_upper)
        display as text "  Band type" _col(46) as result "`e(bandtype)' (`e(bandsym)')"
        display as text "  Observations inside the band" _col(46) as result %12.0fc e(N_inband)
    }
    else {
        display as text "  Threshold tau" _col(46) as result %12.6g e(tau)
        display as text "  Threshold type" _col(46) as result "`e(threshtype)'"
    }
    display as text "  Regime sizes (outside the band if a band)" _col(40) as result ///
        %11.0fc e(N_regime1) " " %11.0fc e(N_regime2)
    display as text "{hline 78}"
    tempname b
    matrix `b' = e(b)
    local cn : colnames `b'
    local r1 : word 1 of `cn'
    local r2 : word 2 of `cn'
    display as text "  `r1'" _col(46) as result %12.5f `b'[1,1]
    display as text "  `r2'" _col(46) as result %12.5f `b'[1,2]
    display as text "  residual sum of squares" _col(46) as result %12.6f e(ssr)
    display as text "{hline 78}"
    display as text "  Phi (rho1 = rho2 = 0)" _col(46) as result %12.4f e(phi) ///
        as text "   boot p = " as result %6.4f e(p_phi)
    display as text "  Symmetry chi2(1)" _col(46) as result %12.4f e(f_sym) ///
        as text "        p = " as result %6.4f e(p_sym)
    display as text "{hline 78}"
end
