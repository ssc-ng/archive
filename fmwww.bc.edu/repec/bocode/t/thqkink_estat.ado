*! thqkink_estat 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thqkink.
*!   kinkplot  the fitted bent line with the data and the kinks marked
*!   kinks     the kink locations by quantile, with a plot against tau
*!   slopes    the slope on each segment, cumulated from the slope changes,
*!             with delta-method standard errors
*!   profile   the check-function objective over the kink grid
*!   select    the BIC / sBIC table over the number of kinks
*!   table     a publication summary

program define thqkink_estat, rclass
    version 15
    if "`e(cmd)'" != "thqkink" {
        display as error "last estimates not found, or not from {bf:thqkink}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("kinkplot", 1, max(5, `l')) {
        Kinkplot `0'
        exit
    }
    if "`sub'" == "kinks" {
        Kinks `0'
        return add
        exit
    }
    if "`sub'" == substr("slopes", 1, max(3, `l')) {
        Slopes `0'
        return add
        exit
    }
    if "`sub'" == substr("profile", 1, max(4, `l')) {
        Profile `0'
        return add
        exit
    }
    if "`sub'" == substr("select", 1, max(3, `l')) {
        Select `0'
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: kinkplot kinks slopes profile select table"
    exit 198
end

* ======================================================================
* The slope on each segment is the base slope plus the slope changes up to
* that kink, so its variance is the sum of the whole relevant block of e(V).
* Doing it here rather than leaving the user to add coefficients by hand is
* the point: adding them and taking one diagonal element is the usual way to
* get a segmented fit's standard errors wrong.
* ======================================================================
program define Slopes, rclass
    version 15
    local nk = e(nkinks)
    tempname b V out est vv
    matrix `b' = e(b)
    matrix `V' = e(V)
    matrix `out' = J(`=`nk'+1', 4, .)
    local rn ""
    forvalues s = 1/`=`nk'+1' {
        scalar `est' = 0
        scalar `vv'  = 0
        forvalues i = 1/`s' {
            scalar `est' = `est' + `b'[1,`i']
            forvalues j = 1/`s' {
                scalar `vv' = `vv' + `V'[`i',`j']
            }
        }
        matrix `out'[`s',1] = `est'
        if `vv' > 0 {
            matrix `out'[`s',2] = sqrt(`vv')
            matrix `out'[`s',3] = `est'/sqrt(`vv')
            matrix `out'[`s',4] = 2*normal(-abs(`est'/sqrt(`vv')))
        }
        local rn `rn' segment`s'
    }
    matrix rownames `out' = `rn'
    matrix colnames `out' = slope se z p

    display _n as text "Slope on each segment, at tau = " as result %5.3f e(tau)
    display as text "{hline 66}"
    forvalues k = 1/`nk' {
        display as text "  kink `k' at `e(kink_var)' = " as result %12.6g e(kink`k')
    }
    display as text "{hline 66}"
    matrix list `out', noheader format(%10.5f)
    display as text "{hline 66}"
    display as text "  Each slope is the base slope plus every slope change to its"
    display as text "  left, and its standard error is the delta-method one from the"
    display as text "  FULL covariance block, not the square root of a single diagonal"
    display as text "  element. Like every standard error here it conditions on the"
    display as text "  kinks having been estimated."
    return matrix slopes = `out'
end

* ======================================================================
program define Kinks, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    tempname K KG
    matrix `K'  = e(byquantile)
    matrix `KG' = e(kinks)
    local nt = e(n_tau)
    local nk = e(nkinks)

    display _n as text "Kink location(s) across quantiles"
    display as text "{hline 70}"
    display as text "    tau" _continue
    forvalues k = 1/`nk' {
        display as text _col(`=6+16*`k'') %15s "kink `k'" _continue
    }
    display ""
    display as text "{hline 70}"
    forvalues i = 1/`nt' {
        display as text "   " as result %5.3f `K'[`i',1] _continue
        forvalues k = 1/`nk' {
            display as result _col(`=6+16*`k'') %15.6g `KG'[`i',`k'] _continue
        }
        display ""
    }
    display as text "{hline 70}"
    if `nt' > 1 {
        display as text "  A kink that sits at the same place in every quantile is one"
        display as text "  breakpoint in the relationship. One that drifts with tau means"
        display as text "  the breakpoint itself depends on where in the distribution you"
        display as text "  look -- a result, not an error. One that jumps about is usually"
        display as text "  weak identification: check {bf:estat profile}."
    }
    return matrix kinks = `KG', copy
    if "`graph'" != "" & `nt' > 1 {
        preserve
            quietly {
                clear
                svmat double `K', names(col)
                svmat double `KG', names(col)
            }
            local pl ""
            local lg ""
            forvalues k = 1/`nk' {
                local pl `pl' (connected kink`k' tau, sort msymbol(O))
                local lg `lg' `k' "kink `k'"
            }
            twoway `pl' , ytitle("kink location") xtitle("quantile tau") ///
                title("Does the kink move across quantiles?")            ///
                legend(order(`lg') size(small)) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Profile, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    tempname P
    matrix `P' = e(profile)
    local nt = e(n_tau)
    local tl "`e(quantiles)'"

    display _n as text "Check-function objective over the kink grid"
    display as text "  (the LAST kink is varied; any others are held at their estimates)"
    display as text "{hline 70}"
    display as text "  grid points" _col(50) as result %14.0f rowsof(`P')
    display as text "  objective at the estimate" _col(50) as result %14.6f e(obj)
    display as text "  objective of the straight line" _col(50) as result %14.6f e(obj0)
    local b1 = .
    local b2 = .
    forvalues r = 1/`=rowsof(`P')' {
        if `P'[`r',2] < . {
            if `b1' == . | `P'[`r',2] < `b1' {
                local b2 = `b1'
                local b1 = `P'[`r',2]
            }
            else if `b2' == . | `P'[`r',2] < `b2' {
                local b2 = `P'[`r',2]
            }
        }
    }
    if `b2' < . {
        display as text "  best vs runner-up on the grid" _col(50) as result ///
            %14.3e (`b2' - `b1')
        return scalar gap = `b2' - `b1'
    }
    display as text "{hline 70}"
    display as text "  A gap of the same order as the search solver's accuracy (about"
    display as text "  1e-8 relative) means the kink is a near-tie on the grid and its"
    display as text "  location should not be interpreted."
    return matrix profile = `P', copy
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `P', names(col)
            }
            local cn : colnames `P'
            local gv : word 1 of `cn'
            local pl ""
            local lg ""
            forvalues i = 1/`nt' {
                local vn : word `=`i'+1' of `cn'
                local ti : word `i' of `tl'
                local pl `pl' (line `vn' `gv', sort)
                local lg `lg' `i' "tau = `ti'"
            }
            twoway `pl' , ytitle("check-function objective")  ///
                xtitle("`e(kink_var)'")                        ///
                title("Kink profile by quantile")              ///
                legend(order(`lg') size(small)) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Select, rclass
    version 15
    tempname S
    matrix `S' = e(select)
    display _n as text "How many kinks?"
    display as text "{hline 70}"
    display as text "    tau" _col(12) "K" _col(22) "objective" _col(40) ///
        "BIC" _col(56) "sBIC"
    display as text "{hline 70}"
    forvalues r = 1/`=rowsof(`S')' {
        if `S'[`r',3] < . {
            display as text "   " as result %5.3f `S'[`r',1] ///
                _col(10) %3.0f `S'[`r',2] _col(16) %14.6f `S'[`r',3] ///
                _col(32) %14.3f `S'[`r',4] _col(48) %14.3f `S'[`r',5]
        }
    }
    display as text "{hline 70}"
    display as text "  BIC  = n ln(V/n) + p ln(n)"
    display as text "  sBIC = n ln(V/n) + p ln(n) ln(ln(n))"
    display as text "  with p counting the intercept, the base slope, one slope change"
    display as text "  per kink, the regime-invariant block AND the kink locations."
    display as text "  Zhong, Wan and Zhang (2022) argue for a penalty inflated like the"
    display as text "  second one when CHOOSING the number of kinks, because the plain"
    display as text "  BIC over-selects. The inflation factor is a tuning choice, so both"
    display as text "  are printed and neither is called the answer."
    return matrix select = `S'
end

* ======================================================================
program define Kinkplot
    version 15
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local kv "`e(kink_var)'"
    local nk = e(nkinks)
    tempvar touse fit
    quietly generate byte `touse' = e(sample)
    quietly predict double `fit' if `touse', xb
    local xl ""
    forvalues k = 1/`nk' {
        local xl `xl' xline(`=e(kink`k')', lcolor(red) lpattern(dash))
    }
    if `"`title'"' == "" {
        local tt : display %5.3f e(tau)
        local title "Bent-line quantile fit, tau = `=trim("`tt'")'"
    }
    twoway (scatter `e(depvar)' `kv' if `touse', msymbol(oh) msize(small)   ///
                mcolor(gs10))                                               ///
           (line `fit' `kv' if `touse', sort lcolor(navy) lwidth(medthick)) ///
        , `xl' ytitle("`e(depvar)'") xtitle("`kv'")                         ///
          title(`"`title'"')                                                ///
          legend(order(1 "data" 2 "fitted quantile") size(small) rows(1))   ///
          `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
program define Table
    version 15
    local nk = e(nkinks)
    display _n as text "{hline 78}"
    display as text "Bent-line quantile regression -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(46) as result "`e(depvar)'"
    display as text "  Kink variable" _col(46) as result "`e(kink_var)'"
    if "`e(invariant)'" != "" {
        display as text "  Regime invariant" _col(46) as result "`e(invariant)'"
    }
    display as text "  Kinks" _col(46) as result %12.0f `nk'
    display as text "  Quantiles fitted" _col(46) as result "`e(quantiles)'"
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "  Grid points" _col(46) as result %12.0f e(n_grid)
    display as text "{hline 78}"
    display as text "  Reported quantile" _col(46) as result %12.3f e(tau)
    forvalues k = 1/`nk' {
        display as text "  kink `k'" _col(46) as result %12.6g e(kink`k')
    }
    display as text "  Objective: kinked / straight line" _col(40) as result ///
        %11.6f e(obj) " " %11.6f e(obj0)
    display as text "{hline 78}"
    if e(lr_sup) < . {
        display as text "  sup-LR" _col(46) as result %12.4f e(lr_sup)
        if e(p) < . {
            display as text "  bootstrap p" _col(46) as result %12.4f e(p) ///
                as text "   MC s.e. " as result %6.4f e(p_mcse)
        }
        display as text "{hline 78}"
    }
    display as text "  Coefficients come from official {bf:qreg} (vce(`e(vce)')) at the"
    display as text "  estimated kinks and condition on them."
    display as text "{hline 78}"
end
