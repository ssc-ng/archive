*! _xtutest_display  version 1.3.0  20oct2026
*! Output of xtutest; reads e(), so typing -xtutest- alone redisplays it.

capture program drop _xtutest_display
program define _xtutest_display
    version 14
    syntax [, UNITs DIag]
    if "`e(cmd)'" != "xtutest" {
        di as err "last estimates not found"
        exit 301
    }
    local W 78
    local lev = e(level)
    local shape = cond(e(ushape), "U", "inverse U")
    local nrm = (e(normal) | e(df) >= .)
    local ref = cond(`nrm', "N(0,1)", "t(" + string(e(df)) + ")")
    local het = e(het)
    local curv = cond(e(ushape), "convex", "concave")

    di as txt _n "{hline `W'}"
    di as res _col(3) "Panel test for an `shape' relationship and its turning point"
    di as txt "{hline `W'}"
    di as txt _col(3) "Dependent variable : " as res "`e(depvar)'" _col(48) as txt "Units (N)   = " as res %7.0f e(N_g)
    di as txt _col(3) "Shape variable     : " as res "`e(xvar)'" _col(48) as txt "Periods (T) = " as res %7.0f e(T)
    if e(balanced) == 0 {
        if `het' di as txt _col(48) "Unbalanced: T_i min " as res e(T_min) as txt ", mean " as res %5.1f e(T_avg)
        else di as txt _col(48) "Unbalanced panel"
    }
    if "`e(controls)'" != "" di as txt _col(3) "Controls           : " as res "`e(controls)'"
    di as txt _col(3) "Estimator          : " as res "`e(estname)'" as txt ", reference " as res "`ref'"
    if `het' == 0 di as txt _col(3) "Standard errors    : " as res "`e(vce)'" as txt " (slopes assumed equal across units)"
    if "`e(estimator)'" == "ccep" di as txt _col(3) "Standard errors    : " as res "`e(vce)'" as txt " (common slopes; unit results below are CCE)"
    di as txt "{hline `W'}"

    // mean-group coefficients
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local cn : colnames `b'
    local q = cond(`nrm', invnormal(1 - (1 - `lev'/100)/2), invttail(e(df), (1 - `lev'/100)/2))
    local tz = cond(`nrm', "z", "t")
    local ctitle = cond(`het' & "`e(estimator)'" != "ccep", "Mean-group coefficients", "Coefficients")
    di as txt _col(3) "`ctitle'"
    di as txt _col(3) "{hline 74}"
    di as txt _col(3) %-18s "`e(depvar)'" _col(22) "Coef." _col(33) "Std. err." _col(47) "`tz'" _col(53) "P>|`tz'|" _col(62) "[`lev'% conf. int.]"
    di as txt _col(3) "{hline 74}"
    local j 0
    foreach c of local cn {
        local ++j
        local bb = el(`b', 1, `j')
        local se = sqrt(el(`V', `j', `j'))
        local st = `bb' / `se'
        local pv = cond(`nrm', 2 * normal(-abs(`st')), 2 * ttail(e(df), abs(`st')))
        di as txt _col(3) %-17s abbrev("`c'", 17) as res _col(20) %10.0g `bb' _col(31) %10.0g `se' ///
            _col(43) %7.2f `st' _col(52) %6.3f `pv' _col(60) %9.0g `bb' - `q'*`se' _col(70) %9.0g `bb' + `q'*`se'
    }
    di as txt _col(3) "{hline 74}"
    di as txt "{hline `W'}"

    // shape test
    di as txt _col(3) "Interval [xL, xH] = [" as res %9.4g e(xL) as txt ", " as res %9.4g e(xH) as txt "]  (`e(interval)')"
    di as txt _col(5) "Slope of the mean curve at xL" as res _col(40) %10.0g e(sL) as txt "   t = " as res %7.3f e(tL)
    di as txt _col(5) "Slope of the mean curve at xH" as res _col(40) %10.0g e(sH) as txt "   t = " as res %7.3f e(tH)
    di as txt _col(3) "Intersection-union test (Lind and Mehlum 2010):  S = " as res %7.3f e(S) ///
        as txt "   p = " as res %6.4f e(p)
    di as txt _col(5) "H1: `shape' on [xL, xH]     H0: monotone or the opposite shape"
    di as txt "{hline `W'}"

    // turning points
    local tplab = cond("`e(estimator)'" == "ccep" | `het' == 0, "Turning point (common curve)", "Turning point of the mean curve")
    di as txt _col(3) "`tplab'" as res _col(40) %10.4f e(tp)
    if e(f_bounded) == 1 {
        di as txt _col(5) "Fieller `lev'% interval" as res _col(40) "[" %9.4f e(f_lo) ", " %9.4f e(f_hi) "]"
    }
    else {
        di as txt _col(5) "Fieller `lev'% interval" as res _col(40) "unbounded (curvature not significant)"
    }
    di as txt _col(5) "Delta-method `lev'% interval" as res _col(40) "[" %9.4f e(d_lo) ", " %9.4f e(d_hi) "]"
    if `het' == 0 {
        * homogeneous slopes: no unit turning points
    }
    else if e(tp_median) < . {
        di as txt _col(3) "Median unit turning point" as res _col(40) %10.4f e(tp_median)
        di as txt _col(5) "Order-statistic `lev'% interval" as res _col(40) "[" %9.4f e(m_lo) ", " %9.4f e(m_hi) "]"
    }
    else {
        di as txt _col(3) "Median unit turning point" as res _col(40) "not computed (fewer than 5 `curv' units)"
    }
    if `het' di as txt _col(5) "Units with `curv' curvature" as res _col(40) %10.0f e(n_curv) as txt "  (share " as res %5.3f e(share) as txt ")"
    if e(tp) < e(xL) | e(tp) > e(xH) {
        di as txt _col(3) "Note: the turning point of the mean curve lies outside [xL, xH]."
    }
    di as txt "{hline `W'}"
    if `het' di as txt _col(3) "Pesaran CD test on the unit residuals:  CD = " as res %7.3f e(cd) as txt "   p = " as res %6.4f e(cd_p)
    if `het' & e(cce) == 0 & e(cd_p) < 0.05 {
        di as txt _col(3) "Note: residuals are cross-sectionally dependent; the CCE estimator (default) is advised."
    }

    // pooled comparison
    capture confirm matrix e(pooled)
    if _rc == 0 {
        tempname P
        matrix `P' = e(pooled)
        di as txt "{hline `W'}"
        di as txt _col(3) "Pooled two-way fixed effects (homogeneous slopes; cluster-robust; for comparison)"
        di as txt _col(5) "S = " as res %7.3f el(`P', 1, 5) as txt "   p = " as res %6.4f el(`P', 1, 6) ///
            as txt "   turning point = " as res %9.4f el(`P', 1, 7)
    }
    di as txt "{hline `W'}"

    // estimator-specific checks
    if "`e(estimator)'" == "re" {
        di as txt _col(3) "Mundlak test, RE vs FE (cluster-robust): chi2(" e(mundlak_df) ") = " as res %8.3f e(mundlak) ///
            as txt "   p = " as res %6.4f e(mundlak_p)
        if e(mundlak_p) < 0.05 di as txt _col(5) "the unit means of the regressors matter: random effects are inconsistent; use fe"
    }
    if "`e(estimator)'" == "iv" {
        tempname G
        matrix `G' = e(ivgmm)
        di as txt _col(3) "First-stage F of excluded instruments (cluster-robust): x " as res %8.2f el(`G', 1, 1) ///
            as txt "   x^2 " as res %8.2f el(`G', 1, 2)
        if el(`G', 1, 3) < . di as txt _col(3) "Overidentification (score test): " as res %8.3f el(`G', 1, 3) as txt "   p = " as res %6.4f el(`G', 1, 4)
        else di as txt _col(3) "Exactly identified: no overidentification test"
    }
    if "`e(estimator)'" == "gmm" {
        tempname G
        matrix `G' = e(ivgmm)
        di as txt _col(3) "Coefficient on L.`e(depvar)' = " as res %7.4f e(rho) ///
            as txt "; long-run turning point = short-run turning point"
        di as txt _col(3) "Arellano-Bond AR(1) p = " as res %6.4f el(`G', 1, 5) as txt "   AR(2) p = " as res %6.4f el(`G', 1, 6)
    }

    // residual diagnostics
    tempname D
    matrix `D' = e(diag)
    di as txt "{hline `W'}"
    if `het' {
        di as txt _col(3) "Residual diagnostics, unit regressions" _col(45) "units rej. 5%" _col(61) "Fisher p" _col(71) "Choi p"
        local tn1 "Serial correlation (BG 1)"
        local tn2 "Heteroskedasticity (Koenker)"
        local tn3 "Normality (Jarque-Bera)"
        local tn4 "Stability (CUSUM)"
        forvalues r = 1/4 {
            di as txt _col(5) "`tn`r''" as res _col(47) %5.0f el(`D', `r', 1) * el(`D', `r', 2) as txt " of " as res %3.0f el(`D', `r', 2) ///
                _col(60) %8.4f el(`D', `r', 4) _col(70) %8.4f el(`D', `r', 6)
        }
        di as txt _col(5) "Fisher and Choi combine the unit p-values; they assume independent units (see CD test)."
    }
    else {
        di as txt _col(3) "Residual diagnostics, pooled residuals" _col(52) "statistic" _col(66) "df" _col(72) "p"
        local tn1 = cond("`e(estimator)'" == "gmm", "Serial correlation (Arellano-Bond AR(2))", "Serial correlation (Wooldridge, F)")
        local tn2 "Groupwise heteroskedasticity (mod. Wald)"
        local tn3 "Normality (Jarque-Bera)"
        local tn4 = "Stability of x, x^2 across halves (Wald)"
        forvalues r = 1/4 {
            if el(`D', `r', 3) >= . {
                di as txt _col(5) "`tn`r''" _col(52) "not available for this estimator"
                continue
            }
            di as txt _col(5) "`tn`r''" as res _col(50) %10.3f el(`D', `r', 1) _col(62) %6.0f el(`D', `r', 2) _col(69) %7.4f el(`D', `r', 3)
        }
        if inlist("`e(estimator)'", "fe", "re") di as txt _col(5) "(stability: break after " e(tbreak) ")"
    }
    di as txt "{hline `W'}"

    if ("`units'" != "" | "`diag'" != "") & `het' {
        tempname U
        matrix `U' = e(units)
        di as txt _n _col(3) "Unit estimates and residual-test p-values"
        di as txt _col(3) "unit" _col(13) "b(x)" _col(24) "b(x^2)" _col(36) "turning pt" _col(48) "`curv'" ///
            _col(56) "BG(1)" _col(64) "Koenker" _col(73) "JB" _col(79) "CUSUM"
        forvalues i = 1/`=rowsof(`U')' {
            di as txt _col(3) %6.0g el(`U', `i', 1) as res _col(10) %9.0g el(`U', `i', 2) _col(21) %9.0g el(`U', `i', 3) ///
                _col(33) %11.3f el(`U', `i', 4) _col(50) %1.0f el(`U', `i', 5) ///
                _col(55) %6.3f el(`U', `i', 6) _col(64) %6.3f el(`U', `i', 7) _col(71) %6.3f el(`U', `i', 8) _col(78) %6.3f el(`U', `i', 9)
        }
    }
end
