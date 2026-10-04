*! _mvardlurt_multivariate_display  version 1.1.2  03oct2026
*! Result tables; reads everything from e(), so it can be re-run any time
*! after the command:   _mvardlurt_multivariate_display

capture program drop _mvardlurt_multivariate_display
program define _mvardlurt_multivariate_display
    version 14
    syntax [, NOTable]

    if "`e(cmd)'" != "mvardlurt_multivariate" {
        di as err "last estimates not found"
        exit 301
    }

    local depvar "`e(depvar)'"
    local indep  "`e(indepvars)'"
    local k      = e(k)
    local p      = e(opt_p)
    local qlist  "`e(opt_q)'"
    local qtxt : subinstr local qlist " " ",", all
    local boot   = e(boot)
    local usestr = e(stars)
    local alpha  = e(alpha)
    local tstat  = e(tstat)
    local fstat  = e(fstat)
    local W 78

    tempname cv bb VV ict
    matrix `cv' = e(cv)
    matrix `bb' = e(b)
    matrix `VV' = e(V)

    local modeltxt "ARDL(`p'; `qtxt')"
    local howtxt = "selected by " + upper("`e(ic)'")
    if "`e(manual)'" == "1" local howtxt "user specified"
    local ctxt ""
    if e(contemp) == 1 local ctxt " + contemporaneous D.x"

    // -------------------------------------------------------------------
    // information-criterion table
    // -------------------------------------------------------------------
    if "`notable'" == "" & "`e(manual)'" == "0" {
        matrix `ict' = e(ic_table)
        local ml = e(maxlag)
        local oq : word 1 of `qlist'
        di as txt _n "{hline `W'}"
        di as res _col(5) upper("`e(ic)'") " selection table: ARDL(p; q), common q for all covariates"
        di as txt _col(5) "p = lags of D.y, q = lags of each D.x   (selected model marked *)"
        di as txt "{hline `W'}"
        forvalues q0 = 0(7)`ml' {
            local q1 = min(`q0' + 6, `ml')
            di as txt _col(3) "p \ q" _c
            forvalues qq = `q0'/`q1' {
                di as txt %10s "q=`qq'" _c
            }
            di as txt ""
            forvalues pp = 0/`ml' {
                di as txt _col(3) "p=`pp'" _c
                forvalues qq = `q0'/`q1' {
                    local v = el(`ict', `pp' + 1, `qq' + 1)
                    if `v' >= . {
                        di as txt %10s "." _c
                    }
                    else if `pp' == `p' & `qq' == `oq' {
                        di as res %9.2f `v' "*" _c
                    }
                    else {
                        di as txt %9.2f `v' " " _c
                    }
                }
                di as txt ""
            }
        }
        di as txt "{hline `W'}"
    }

    // -------------------------------------------------------------------
    // stars (bootstrap critical values)
    // -------------------------------------------------------------------
    local tstar ""
    local fstar ""
    local tlev ""
    local flev ""
    if `boot' == 1 {
        local c11 = el(`cv', 1, 1)
        local c12 = el(`cv', 1, 2)
        local c13 = el(`cv', 1, 3)
        local c14 = el(`cv', 1, 4)
        local c21 = el(`cv', 2, 1)
        local c22 = el(`cv', 2, 2)
        local c23 = el(`cv', 2, 3)
        local c24 = el(`cv', 2, 4)
        _mvardlurt_multivariate_stars, stat(`tstat') tail(lower) ///
            cv10(`c11') cv05(`c12') cv025(`c13') cv01(`c14')
        local tstar "`r(stars)'"
        local tlev  "`r(level)'"
        _mvardlurt_multivariate_stars, stat(`fstat') tail(upper) ///
            cv10(`c21') cv05(`c22') cv025(`c23') cv01(`c24')
        local fstar "`r(stars)'"
        local flev  "`r(level)'"
    }
    local tshow "`tstar'"
    local fshow "`fstar'"
    if `usestr' == 0 {
        local tshow ""
        local fshow ""
    }

    // -------------------------------------------------------------------
    // TABLE 1
    // -------------------------------------------------------------------
    di as txt _n "{hline `W'}"
    di as res _col(5) "Table 1: Multivariate ARDL Unit Root Test"
    di as txt _col(5) "Sam, McNown, Goh and Goh (2024)"
    di as txt "{hline `W'}"
    di as txt _col(3) "Dependent variable :" _col(24) as res "`depvar'"
    di as txt _col(3) "Covariates (k=`k')   :" _col(24) as res "`indep'"
    di as txt _col(3) "Deterministics      :" _col(24) as res "Case `e(case)' (`e(casename)')"
    di as txt _col(3) "ARDL specification  :" _col(24) as res "`modeltxt'`ctxt'  " as txt "(`howtxt')"
    di as txt _col(3) "Sample (full)       :" _col(24) as res "`e(t_start)' to `e(t_end)'" ///
        as txt "   T = " as res e(T)
    di as txt _col(3) "Effective obs       :" _col(24) as res e(N) ///
        _col(45) as txt "R-squared (D.y) :" _col(64) as res %8.4f e(r2)
    di as txt _col(3) "AIC / BIC           :" _col(24) as res %10.3f e(aic) " / " %10.3f e(bic)
    di as txt "{hline `W'}"
    di as txt _col(3) "t-statistic (L.y)   :" _col(24) as res %12.6f `tstat' ///
        as res " `tshow'" _col(46) as txt "H0: pi = 0 (unit root)"
    di as txt _col(3) "F-statistic (L.x)   :" _col(24) as res %12.6f `fstat' ///
        as res " `fshow'" _col(46) as txt "H0: delta_1=...=delta_k=0"
    if `boot' == 1 {
        di as txt _col(3) "Bootstrap p-values  :" _col(24) ///
            as txt "t: " as res %6.4f e(p_t) as txt "   F: " as res %6.4f e(p_f)
    }
    di as txt "{hline `W'}"

    // -------------------------------------------------------------------
    // TABLE 2
    // -------------------------------------------------------------------
    if `boot' == 1 {
        local dtxt = strtrim(string(100*`alpha', "%5.2f")) + "%"
        di as txt _n "{hline `W'}"
        di as res _col(5) "Table 2: Bootstrap Critical Values (valid draws: t " e(B_t) ", F " e(B_f) ")"
        di as txt "{hline `W'}"
        di as txt _col(3) "Significance level" _col(25) "10%" _col(37) "5%" _col(49) "2.5%" ///
            _col(61) "1%" _col(70) "`dtxt'*"
        di as txt "{hline `W'}"
        di as txt _col(3) "t-critical (lower)" _col(17) as res ///
            %10.4f el(`cv',1,1) _col(29) %10.4f el(`cv',1,2) _col(41) %10.4f el(`cv',1,3) ///
            _col(53) %10.4f el(`cv',1,4) _col(65) %10.4f el(`cv',1,5)
        di as txt _col(3) "F-critical (upper)" _col(17) as res ///
            %10.4f el(`cv',2,1) _col(29) %10.4f el(`cv',2,2) _col(41) %10.4f el(`cv',2,3) ///
            _col(53) %10.4f el(`cv',2,4) _col(65) %10.4f el(`cv',2,5)
        di as txt "{hline `W'}"
        di as txt _col(3) "* decision level = 100*(1 - level()/100)"
    }

    // -------------------------------------------------------------------
    // TABLE 3
    // -------------------------------------------------------------------
    di as txt _n "{hline `W'}"
    di as res _col(5) "Table 3: ARDL Coefficient Summary (dependent variable: D.`depvar')"
    di as txt "{hline `W'}"
    di as txt _col(3) "Parameter" _col(21) "Variable" _col(40) "Coefficient" ///
        _col(55) "Std. Err." _col(69) "t-stat"
    di as txt "{hline `W'}"
    local pic = el(`bb', 1, 1)
    local pis = sqrt(el(`VV', 1, 1))
    local pit = `pic' / `pis'
    di as txt _col(3) "pi (unit root)" _col(21) "L.`depvar'" _col(34) as res %12.6f `pic' ///
        _col(49) %12.6f `pis' _col(64) %10.4f `pit' as res " `tshow'"
    local i 0
    foreach v of local indep {
        local ++i
        local dc = el(`bb', 1, 1 + `i')
        local ds = sqrt(el(`VV', 1 + `i', 1 + `i'))
        local dt = `dc' / `ds'
        di as txt _col(3) "delta_`i' (coint.)" _col(21) "L.`v'" _col(34) as res %12.6f `dc' ///
            _col(49) %12.6f `ds' _col(64) %10.4f `dt'
    }
    di as txt "{hline `W'}"
    if `pic' != 0 {
        di as txt _col(3) "Long-run multipliers -delta_i/pi (point estimates)"
        local i 0
        foreach v of local indep {
            local ++i
            local dc = el(`bb', 1, 1 + `i')
            local lr = (-1) * `dc' / `pic'
            di as txt _col(5) "`v'" _col(34) as res %12.6f `lr'
        }
        di as txt "{hline `W'}"
    }
    di as txt _col(3) "Individual t-statistics on L.x are for information only; their null"
    di as txt _col(3) "distributions are non-standard (use Table 2 for valid inference)."

    // -------------------------------------------------------------------
    // TABLE 4
    // -------------------------------------------------------------------
    di as txt _n "{hline `W'}"
    di as res _col(5) "Table 4: Decision and Inference"
    di as txt "{hline `W'}"

    if `boot' == 0 {
        di as txt _col(3) "Bootstrap suppressed (noboot): no critical values, so no decision."
        di as txt _col(3) "Re-run without noboot to obtain valid inference."
        di as txt "{hline `W'}"
        exit
    }

    local rt = (`tstat' < el(`cv',1,5))
    local rf = (`fstat' > el(`cv',2,5))
    local dlev = strtrim(string(100*`alpha', "%5.2f")) + "%"

    di as txt _col(3) "A. Hypothesis tests (decision at the `dlev' level)"
    di as txt _col(3) "{hline 74}"
    di as txt _col(5) "Test" _col(15) "Null hypothesis" _col(42) "Statistic" _col(55) "Decision" _col(72) "Sig."
    di as txt _col(3) "{hline 74}"
    if `rt' {
        di as txt _col(5) "t-test" _col(15) "pi = 0" _col(40) as res %10.4f `tstat' ///
            _col(55) "Reject" _col(72) as txt "`tlev'"
    }
    else {
        di as txt _col(5) "t-test" _col(15) "pi = 0" _col(40) as res %10.4f `tstat' ///
            _col(55) as txt "Fail to reject" _col(72) "n.s."
    }
    if `rf' {
        di as txt _col(5) "F-test" _col(15) "delta = 0 (all)" _col(40) as res %10.4f `fstat' ///
            _col(55) "Reject" _col(72) as txt "`flev'"
    }
    else {
        di as txt _col(5) "F-test" _col(15) "delta = 0 (all)" _col(40) as res %10.4f `fstat' ///
            _col(55) as txt "Fail to reject" _col(72) "n.s."
    }
    di as txt _col(3) "{hline 74}"

    local m1 "  "
    local m2 "  "
    local m3 "  "
    local m4 "  "
    if `rt' == 0 & `rf' == 0 local m1 "=>"
    if `rt' == 1 & `rf' == 0 local m2 "=>"
    if `rt' == 0 & `rf' == 1 local m3 "=>"
    if `rt' == 1 & `rf' == 1 local m4 "=>"

    di as txt _n _col(3) "B. Four-case framework (paper, section 3.2)"
    di as txt _col(3) "{hline 74}"
    di as txt _col(5) "Case" _col(13) "t-test" _col(23) "F-test" _col(33) "Interpretation"
    di as txt _col(3) "{hline 74}"
    di as txt _col(3) "`m1'" _col(6) "I"   _col(13) "No rej" _col(23) "No rej" _col(33) "Nonstationary, no cointegration"
    di as txt _col(3) "`m2'" _col(6) "II"  _col(13) "Reject" _col(23) "No rej" _col(33) "Stationary, I(0)"
    di as txt _col(3) "`m3'" _col(6) "III" _col(13) "No rej" _col(23) "Reject" _col(33) "Degenerate lagged y (possibly I(2))"
    di as txt _col(3) "`m4'" _col(6) "IV"  _col(13) "Reject" _col(23) "Reject" _col(33) "Nonstationary, cointegration"
    di as txt _col(3) "{hline 74}"

    di as txt _n _col(3) "C. Conclusion"
    di as txt _col(3) "{hline 74}"
    if `rt' == 0 & `rf' == 0 {
        di as res _col(5) "CASE I: nonstationary process, no cointegration"
        di as txt _col(5) "Neither pi = 0 nor delta = 0 is rejected: `depvar' behaves as an I(1)"
        di as txt _col(5) "process and the covariates add no long-run information."
    }
    else if `rt' == 1 & `rf' == 0 {
        di as res _col(5) "CASE II: stationary process"
        di as txt _col(5) "pi < 0 and delta = 0 not rejected: `depvar' is I(0); its stationarity"
        di as txt _col(5) "is not driven by the lagged covariate levels."
    }
    else if `rt' == 0 & `rf' == 1 {
        di as res _col(5) "CASE III: degenerate lagged dependent variable"
        di as txt _col(5) "pi = 0 but delta != 0: `depvar' is nonstationary and may be I(2)."
        di as txt _col(5) "Check the order of integration of the covariates."
    }
    else {
        di as res _col(5) "CASE IV: nonstationary process, cointegration"
        di as txt _col(5) "pi < 0 and delta != 0: `depvar' is cointegrated with the covariates."
        di as txt _col(5) "If the covariates are I(1), `depvar' is I(1) too: its unit root"
        di as txt _col(5) "comes from the long-run relation with them."
    }
    di as txt _col(3) "{hline 74}"
    if `usestr' == 1 {
        di as txt _col(3) "Significance (bootstrap):  ***  1%    **  2.5%    *  5%    +  10%"
    }
    di as txt _col(3) "Valid when the system has at most one cointegrating relation"
    di as txt _col(3) "(no feedback from y to the covariates)."
    di as txt "{hline `W'}"
end
