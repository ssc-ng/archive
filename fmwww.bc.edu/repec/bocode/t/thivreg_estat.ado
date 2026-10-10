*! thivreg_estat 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thivreg.
*!   lrplot     the LR profile with all three critical values drawn on it
*!   regimes    what each regime looks like
*!   firststage instrument strength INSIDE EACH REGIME -- the check that
*!              matters most here and that no other command can do for you
*!   jtest      Hansen's J by regime
*!   twostep    the union slope intervals, as a returnable matrix
*!   table      a publication summary

program define thivreg_estat, rclass
    version 15
    if "`e(cmd)'" != "thivreg" {
        display as error "last estimates not found, or not from {bf:thivreg}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        display as error "available: lrplot regimes firststage jtest twostep table"
        exit 198
    }
    if "`sub'" == substr("lrplot", 1, max(2, `l')) {
        LRplot `0'
        exit
    }
    if "`sub'" == substr("regimes", 1, max(3, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("firststage", 1, max(5, `l')) {
        Firststage `0'
        return add
        exit
    }
    if "`sub'" == substr("jtest", 1, max(1, `l')) {
        Jtest `0'
        return add
        exit
    }
    if "`sub'" == substr("twostep", 1, max(3, `l')) {
        Twostep `0'
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: lrplot regimes firststage jtest twostep table"
    exit 198
end

* ======================================================================
program define LRplot
    version 15
    syntax [, SAVing(string asis) TItle(string asis) NOCI * ]
    tempname P
    matrix `P' = e(profile)
    local cv  = e(lr_cv)
    local e1  = e(eta2_quad)
    local e2  = e(eta2_kern)
    if `"`title'"' == "" {
        local title "LR sequence in gamma, and the three critical values"
    }
    preserve
        quietly {
            clear
            svmat double `P', names(col)
            keep if lr < .
        }
        local yl ""
        if "`noci'" == "" {
            local yl yline(`cv', lcolor(red) lpattern(dash))
            if `e1' < . {
                local yl `yl' yline(`=`cv'*`e1'', lcolor(navy) lpattern(shortdash))
            }
            if `e2' < . {
                local yl `yl' yline(`=`cv'*`e2'', lcolor(forest_green) lpattern(dot))
            }
        }
        twoway (line lr gamma, sort lcolor(black))                       ///
            , `yl' xline(`=e(gamma)', lcolor(gs10))                      ///
              ytitle("LR(gamma)") xtitle("`e(threshold_var)'")           ///
              title(`"`title'"')                                         ///
              note("red = uncorrected, navy = quadratic, green = kernel") ///
              legend(off) `options'
        if `"`saving'"' != "" _tk_gsave `saving'
    restore
end

* ======================================================================
program define Regimes, rclass
    version 15
    local depv "`e(depvar)'"
    local qv   "`e(threshold_var)'"
    tempvar rg
    quietly predict byte `rg' if e(sample), regime
    tempname out
    matrix `out' = J(2, 5, .)
    forvalues j = 1/2 {
        quietly summarize `qv' if `rg' == `j'
        matrix `out'[`j',1] = r(N)
        matrix `out'[`j',2] = r(min)
        matrix `out'[`j',3] = r(max)
        quietly summarize `depv' if `rg' == `j'
        matrix `out'[`j',4] = r(mean)
        matrix `out'[`j',5] = r(sd)
    }
    matrix colnames `out' = N q_min q_max mean_y sd_y
    matrix rownames `out' = regime1 regime2

    display _n as text "The two regimes"
    display as text "{hline 74}"
    display as text "  regime" _col(16) "N" _col(28) "`qv' range" ///
        _col(52) "mean `depv'"
    display as text "{hline 74}"
    forvalues j = 1/2 {
        display as text "  `j'  " _continue
        display as text cond(`j'==1, "(q <= gamma)", "(q >  gamma)") _continue
        display as result _col(20) %8.0f `out'[`j',1] ///
            _col(30) %10.4g `out'[`j',2] " " %10.4g `out'[`j',3] ///
            _col(54) %12.5f `out'[`j',4]
    }
    display as text "{hline 74}"
    display as text "  gamma" _col(50) as result %12.6g e(gamma)
    display as text "{hline 74}"
    display as text "  A regime with fewer observations than about four times its"
    display as text "  own number of coefficients is not an IV estimate, whatever"
    display as text "  the table prints: GMM needs the regime's own moment matrix"
    display as text "  to be well conditioned. Check {bf:estat firststage}."
    return matrix regimes = `out', copy
end

* ======================================================================
* Instrument strength INSIDE EACH REGIME.
* This is the diagnostic that matters most for this estimator and the reason
* it has its own subcommand. An instrument can be strong in the full sample
* and weak -- or constant -- inside one regime, and then that regime's
* coefficients are not identified even though the overall first stage looks
* fine. Nothing in official Stata will tell you this, because no official
* command knows the regimes exist.
* ======================================================================
program define Firststage, rclass
    version 15
    local endl "`e(endog)'"
    local exl  "`e(exog)'"
    local ivl  "`e(insts)'"
    local hc   = e(hascons)
    local k1 : word count `endl'
    local miv : word count `ivl'
    tempvar rg
    quietly predict byte `rg' if e(sample), regime

    * the per-regime first-stage regressions below REPLACE the stored
    * estimates, which would leave thivreg's e() gone and every later estat
    * failing with "not valid". Everything e() is needed for has been read
    * above; _estimates hold with restore puts it back when this program
    * ends, error or not.
    tempname ESTH
    _estimates hold `ESTH', restore

    tempname out
    matrix `out' = J(`=2*`k1'', 5, .)
    local rn ""
    local row 0
    forvalues j = 1/2 {
        foreach v of local endl {
            local ++row
            local rn "`rn' r`j'_`=abbrev("`v'",12)'"
            capture quietly regress `v' `exl' `ivl' if `rg' == `j', ///
                `=cond(`hc',"","noconstant")'
            if _rc continue
            local r2f = e(r2)
            local nj  = e(N)
            capture quietly test `ivl'
            if _rc continue
            matrix `out'[`row',1] = `nj'
            matrix `out'[`row',2] = r(F)
            matrix `out'[`row',3] = r(p)
            * with no exogenous controls the restricted model is the
            * constant alone, which regress will not fit on its own, so its
            * R-squared is zero by definition and the partial R-squared is
            * just the full one
            if "`exl'" == "" {
                matrix `out'[`row',4] = `r2f'
            }
            else {
                capture quietly regress `v' `exl' if `rg' == `j', ///
                    `=cond(`hc',"","noconstant")'
                if !_rc matrix `out'[`row',4] = `r2f' - e(r2)
            }
            matrix `out'[`row',5] = `miv'
        }
    }
    matrix colnames `out' = N F p partial_R2 n_inst
    matrix rownames `out' = `rn'

    display _n as text "Instrument strength, regime by regime"
    display as text "{hline 76}"
    display as text "  endogenous / regime" _col(32) "N" _col(42) "F" ///
        _col(54) "p" _col(64) "partial R2"
    display as text "{hline 76}"
    local row 0
    forvalues j = 1/2 {
        foreach v of local endl {
            local ++row
            display as text "  " %-20s abbrev("`v'", 20) " regime `j'" ///
                as result _col(28) %8.0f `out'[`row',1] ///
                _col(37) %10.3f `out'[`row',2] _col(49) %10.4f `out'[`row',3] ///
                _col(61) %12.4f `out'[`row',4]
        }
    }
    display as text "{hline 76}"
    display as text "  F is the test that the excluded instruments jointly have no"
    display as text "  effect on that endogenous variable WITHIN that regime."
    display as text "{hline 76}"
    display as text "  THIS IS THE DIAGNOSTIC TO READ FIRST. An instrument can be"
    display as text "  strong in the full sample and weak inside one regime -- or"
    display as text "  constant inside it, if the instrument and the threshold"
    display as text "  variable are related -- and then that regime's coefficients"
    display as text "  are not identified, even though the pooled first stage looks"
    display as text "  perfectly healthy. No official Stata command can warn you"
    display as text "  about this, because none of them knows the regimes exist."
    display as text ""
    display as text "  The usual F > 10 rule of thumb was derived for a single"
    display as text "  sample, not for a subsample chosen by minimising an SSR, so"
    display as text "  treat it as a floor and not as a licence."
    return matrix firststage = `out', copy
end

* ======================================================================
program define Jtest, rclass
    version 15
    display _n as text "Overidentification by regime (Hansen's J)"
    display as text "{hline 72}"
    if e(J_df) <= 0 {
        display as text "  Exactly identified in each regime: there is no"
        display as text "  overidentifying restriction to test."
        display as text "{hline 72}"
        return scalar df = 0
        exit
    }
    display as text "  regime" _col(26) "J" _col(40) "df" _col(52) "p"
    display as text "{hline 72}"
    display as text "  1  (q <= gamma)" _col(22) as result %12.4f e(J_regime1) ///
        _col(36) %10.0f e(J_df) _col(46) %12.4f e(p_J1)
    display as text "  2  (q >  gamma)" _col(22) as result %12.4f e(J_regime2) ///
        _col(36) %10.0f e(J_df) _col(46) %12.4f e(p_J2)
    display as text "{hline 72}"
    display as text "  Each J uses only its own regime's observations and its own"
    display as text "  weight matrix, so the two are independent. A rejection in"
    display as text "  one regime and not the other says the instruments are valid"
    display as text "  in one state of the world and not in the other, which is a"
    display as text "  substantive finding about the exclusion restriction, not a"
    display as text "  nuisance to be averaged away."
    display as text "  Both J's condition on the estimated threshold."
    return scalar J1 = e(J_regime1)
    return scalar J2 = e(J_regime2)
    return scalar df = e(J_df)
    return scalar p1 = e(p_J1)
    return scalar p2 = e(p_J2)
end

* ======================================================================
program define Twostep, rclass
    version 15
    local kz = e(k_regime)
    local zn "`e(zn)'"
    tempname C1 C2 out b
    matrix `C1' = e(slopeci1)
    matrix `C2' = e(slopeci2)
    matrix `b'  = e(b)
    matrix `out' = J(`kz', 6, .)
    forvalues i = 1/`kz' {
        matrix `out'[`i',1] = `b'[1,`i']
        matrix `out'[`i',2] = `C1'[`i',1]
        matrix `out'[`i',3] = `C1'[`i',2]
        matrix `out'[`i',4] = `b'[1,`=`i'+`kz'']
        matrix `out'[`i',5] = `C2'[`i',1]
        matrix `out'[`i',6] = `C2'[`i',2]
    }
    matrix colnames `out' = b1 lo1 hi1 b2 lo2 hi2
    matrix rownames `out' = `zn'

    display _n as text "Slope intervals that do NOT condition on gamma-hat"
    display as text "{hline 78}"
    display as text "  Built by refitting both regimes at every one of the " ///
        as result e(n_gridci) as text " grid"
    display as text "  points inside the " as result %4.2f e(cilevel2) ///
        as text " confidence interval for gamma (method " ///
        as result "`e(cimethod)'" as text ")"
    display as text "  and taking the union of the resulting intervals."
    display as text "{hline 78}"
    matrix list `out', noheader format(%10.4f)
    display as text "{hline 78}"
    display as text "  Report these, not the coefficient table. The table's"
    display as text "  standard errors treat gamma as known; these do not."
    display as text "  They use a fixed 1.96 multiplier, as the authors' own"
    display as text "  program does, so they are a 95% union bound whatever"
    display as text "  {bf:level()} says."
    return matrix twostep = `out', copy
end

* ======================================================================
program define Table
    version 15
    tempname QCI
    matrix `QCI' = e(gamma_ci)
    display _n as text "{hline 78}"
    display as text "IV threshold regression -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(46) as result "`e(depvar)'"
    display as text "  Endogenous" _col(46) as result "`e(endog)'"
    display as text "  Excluded instruments" _col(46) as result "`e(insts)'"
    display as text "  Threshold variable" _col(46) as result "`e(threshold_var)'"
    display as text "  Reduced form" _col(46) as result "`e(reduced)'"
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "  Split" _col(46) as result ///
        %6.0f e(N_regime1) " /" %6.0f e(N_regime2)
    display as text "{hline 78}"
    display as text "  Threshold gamma" _col(46) as result %12.6g e(gamma)
    display as text "  `e(level)'% interval, `e(cimethod)'" _col(40) as result ///
        "[" %10.5g `QCI'[`=cond("`e(cimethod)'"=="uncorrected",1,cond("`e(cimethod)'"=="quadratic",2,3))',1] ///
        ", " %10.5g `QCI'[`=cond("`e(cimethod)'"=="uncorrected",1,cond("`e(cimethod)'"=="quadratic",2,3))',2] "]"
    display as text "  SSR with / without the threshold" _col(40) as result ///
        %11.5f e(ssr) " " %11.5f e(ssr0)
    display as text "{hline 78}"
    if e(J_df) > 0 {
        display as text "  J regime 1 / 2" _col(40) as result ///
            %11.4f e(J_regime1) " " %11.4f e(J_regime2) ///
            as text "  df " as result e(J_df)
        display as text "{hline 78}"
    }
    display as text "  There is NO test of no threshold here: Caner and Hansen"
    display as text "  (2004) give estimation and confidence intervals, not a test,"
    display as text "  and inventing one would be inventing inference. Report the"
    display as text "  confidence interval for gamma instead -- if it covers the"
    display as text "  whole trimmed range, the threshold is not identified."
    display as text "{hline 78}"
end
