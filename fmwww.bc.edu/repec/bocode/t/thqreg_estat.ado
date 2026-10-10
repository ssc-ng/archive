*! thqreg_estat 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thqreg and thtqar.
*!   profile   the check-function objective over the threshold grid, with a
*!             plot, one line per quantile
*!   regimes   regime sizes and both regimes' coefficients side by side
*!   quantiles the threshold and the test across the fitted quantiles, with a
*!             plot of gamma against tau
*!   table     a publication summary

program define thqreg_estat, rclass
    version 15
    if !inlist("`e(cmd)'", "thqreg", "thtqar") {
        display as error "last estimates not found, or not from {bf:thqreg}"
        display as error "or {bf:thtqar}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("profile", 1, max(4, `l')) {
        Profile `0'
        return add
        exit
    }
    if "`sub'" == substr("regimes", 1, max(4, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("quantiles", 1, max(5, `l')) {
        Quantiles `0'
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: profile regimes quantiles table"
    exit 198
end

* ======================================================================
program define Profile, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    tempname P Q
    matrix `P' = e(profile)
    matrix `Q' = e(byquantile)
    local nt = e(n_tau)
    local tl "`e(quantiles)'"

    display _n as text "Check-function objective over the threshold grid"
    display as text "{hline 70}"
    display as text "  grid points searched" _col(50) as result %14.0f rowsof(`P')
    display as text "  trimming" _col(50) as result %14.2f e(trim)
    display as text "{hline 70}"
    display as text "    tau" _col(14) "gamma-hat" _col(28) "V(gamma)" ///
        _col(42) "V linear" _col(58) "gap to 2nd"
    display as text "{hline 70}"
    forvalues i = 1/`nt' {
        * the runner-up on the grid, which is what says whether the threshold
        * is sharply identified or merely the winner of a near-tie
        local b1 = .
        local b2 = .
        forvalues r = 1/`=rowsof(`P')' {
            if `P'[`r',`=`i'+1'] < . {
                if `b1' == . | `P'[`r',`=`i'+1'] < `b1' {
                    local b2 = `b1'
                    local b1 = `P'[`r',`=`i'+1']
                }
                else if `b2' == . | `P'[`r',`=`i'+1'] < `b2' {
                    local b2 = `P'[`r',`=`i'+1']
                }
            }
        }
        local gap = cond(`b2' < . & `b1' < ., `b2' - `b1', .)
        display as text "   " as result %5.3f `Q'[`i',1] ///
            _col(9) %12.6g `Q'[`i',2] _col(23) %12.6f `Q'[`i',3] ///
            _col(37) %12.6f `Q'[`i',4] _col(53) %12.3e `gap'
    }
    display as text "{hline 70}"
    display as text "  The last column is the distance from the winning grid point to the"
    display as text "  runner-up. A gap of the same order as the search solver's accuracy"
    display as text "  (about 1e-8 relative) means the threshold is a near-tie and should"
    display as text "  not be interpreted; the certification suite checks that on the"
    display as text "  example data the gap is six orders of magnitude larger."
    return matrix profile = `P', copy

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `P', names(col)
            }
            local pl ""
            local lg ""
            local cn : colnames `P'
            local gv : word 1 of `cn'
            forvalues i = 1/`nt' {
                local vn : word `=`i'+1' of `cn'
                local ti : word `i' of `tl'
                local pl `pl' (line `vn' `gv', sort)
                local lg `lg' `i' "tau = `ti'"
            }
            twoway `pl' , ytitle("check-function objective") ///
                xtitle("`e(threshold_var)'")                 ///
                title("Threshold profile by quantile")       ///
                legend(order(`lg') size(small)) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Regimes, rclass
    version 15
    local xl "`e(indepvars)'"
    local zl "`e(invariant)'"
    local kx : word count `xl'
    tempname b V out
    matrix `b' = e(b)
    matrix `V' = e(V)

    display _n as text "Regimes at tau = " as result %5.3f e(tau)
    display as text "{hline 72}"
    display as text "  Threshold variable" _col(44) as result "`e(threshold_var)'"
    display as text "  Threshold" _col(44) as result %14.6g e(gamma)
    display as text "  Observations: lower / upper" _col(44) as result ///
        %7.0fc e(N_regime1) " " %7.0fc e(N_regime2)
    display as text "  Objective: split / linear" _col(40) as result ///
        %11.6f e(obj) " " %11.6f e(obj0)
    display as text "{hline 72}"

    * e(b) is lower slopes, lower _cons, upper slopes, upper _cons, invariant
    local nr = `kx' + 1
    matrix `out' = J(`nr', 6, .)
    local rn ""
    forvalues j = 1/`nr' {
        local ilo = `j'
        local ihi = `kx' + 1 + `j'
        matrix `out'[`j',1] = `b'[1,`ilo']
        matrix `out'[`j',2] = sqrt(`V'[`ilo',`ilo'])
        matrix `out'[`j',3] = `b'[1,`ihi']
        matrix `out'[`j',4] = sqrt(`V'[`ihi',`ihi'])
        matrix `out'[`j',5] = `b'[1,`ihi'] - `b'[1,`ilo']
        local vd = `V'[`ilo',`ilo'] + `V'[`ihi',`ihi'] - 2*`V'[`ilo',`ihi']
        if `vd' > 0 {
            matrix `out'[`j',6] = ///
                2*normal(-abs((`b'[1,`ihi'] - `b'[1,`ilo'])/sqrt(`vd')))
        }
        if `j' <= `kx' {
            local nm : word `j' of `xl'
            local rn `rn' `nm'
        }
        else local rn `rn' _cons
    }
    matrix rownames `out' = `rn'
    matrix colnames `out' = lower se_lo upper se_hi difference p_diff
    matrix list `out', noheader format(%10.5f)
    display as text "{hline 72}"
    display as text "  p_diff tests upper = lower for that coefficient, using the full"
    display as text "  covariance from {bf:qreg}. It conditions on the threshold, like"
    display as text "  every standard error in this model."
    return matrix regimes = `out'
end

* ======================================================================
program define Quantiles, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    tempname Q
    matrix `Q' = e(byquantile)
    local nt = e(n_tau)

    display _n as text "The threshold across quantiles"
    display as text "{hline 74}"
    local slab = cond("`e(teststat)'" == "", "LR", "`e(teststat)'-LR")
    display as text "    tau" _col(14) "gamma" _col(28) "n lower" _col(40) ///
        "n upper" _col(52) "`slab'" _col(66) "boot p"
    display as text "{hline 74}"
    forvalues i = 1/`nt' {
        local col = cond("`e(teststat)'"=="ave", 8, cond("`e(teststat)'"=="exp", 9, 7))
        display as text "   " as result %5.3f `Q'[`i',1] ///
            _col(9) %12.6g `Q'[`i',2] _col(24) %8.0fc `Q'[`i',5] ///
            _col(36) %8.0fc `Q'[`i',6] _col(48) %12.4f `Q'[`i',`col'] ///
            _col(62) %10.4f `Q'[`i',11]
    }
    display as text "{hline 74}"
    if `nt' > 1 {
        local gmin = `Q'[1,2]
        local gmax = `Q'[1,2]
        forvalues i = 2/`nt' {
            if `Q'[`i',2] < `gmin' local gmin = `Q'[`i',2]
            if `Q'[`i',2] > `gmax' local gmax = `Q'[`i',2]
        }
        display as text "  gamma ranges over " as result %12.6g `gmin' ///
            as text " to " as result %12.6g `gmax'
        return scalar gamma_min = `gmin'
        return scalar gamma_max = `gmax'
        display as text "{hline 74}"
        display as text "  Read this table as a whole. A gamma that is stable with changing"
        display as text "  coefficients is one regime boundary acting differently along the"
        display as text "  distribution. A gamma that drifts monotonically with tau often"
        display as text "  means the true transition is smooth rather than sharp -- compare"
        display as text "  {bf:thstr}. A gamma that jumps about with no pattern is usually"
        display as text "  weak identification, not a discovery: check the gap column of"
        display as text "  {bf:estat profile} before interpreting any of it."
    }
    return matrix byquantile = `Q', copy

    if "`graph'" != "" & `nt' > 1 {
        preserve
            quietly {
                clear
                svmat double `Q', names(col)
            }
            twoway (connected gamma tau, sort msymbol(O))    ///
                , ytitle("estimated threshold")              ///
                  xtitle("quantile tau")                     ///
                  title("Does the regime boundary move across quantiles?") ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Table
    version 15
    display _n as text "{hline 78}"
    display as text "`e(title)' -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(46) as result "`e(depvar)'"
    display as text "  Regressors" _col(46) as result "`e(indepvars)'"
    if "`e(invariant)'" != "" {
        display as text "  Regime invariant" _col(46) as result "`e(invariant)'"
    }
    display as text "  Threshold variable" _col(46) as result "`e(threshold_var)'"
    display as text "  Quantiles fitted" _col(46) as result "`e(quantiles)'"
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "  Grid points" _col(46) as result %12.0f e(n_grid)
    display as text "{hline 78}"
    display as text "  Reported quantile" _col(46) as result %12.3f e(tau)
    display as text "  Threshold" _col(46) as result %12.6g e(gamma)
    display as text "  Regime sizes" _col(40) as result ///
        %11.0fc e(N_regime1) " " %11.0fc e(N_regime2)
    display as text "  Objective: split / linear" _col(40) as result ///
        %11.6f e(obj) " " %11.6f e(obj0)
    display as text "{hline 78}"
    if e(lr_sup) < . {
        display as text "  sup-LR" _col(46) as result %12.4f e(lr_sup)
        display as text "  ave-LR / exp-LR" _col(40) as result ///
            %11.4f e(lr_ave) " " %11.4f e(lr_exp)
        if e(p) < . {
            display as text "  bootstrap p" _col(46) as result %12.4f e(p) ///
                as text "   MC s.e. " as result %6.4f e(p_mcse)
        }
        display as text "{hline 78}"
    }
    display as text "  Coefficients and standard errors come from official {bf:qreg}"
    display as text "  (vce(`e(vce)')) at the estimated threshold, and condition on it."
    display as text "{hline 78}"
end
