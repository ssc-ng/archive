*! _xtcsddiag_display  version 1.0.0  21oct2026
capture program drop _xtcsddiag_display
program define _xtcsddiag_display
    version 14
    syntax, un(name) cb(name) cd(name) estname(string) ivar(string) nall(integer) ///
        n(integer) tmin(real) tmax(real) lags(integer) reps(integer) depvar(string) ///
        est(integer) [ units ]

    di
    di as txt "Residual diagnostics for panels with cross-sectional dependence"
    di as txt "Dependent variable: " as res "`depvar'" _col(52) as txt "Units tested = " as res %8.0f `n'
    di as txt "Residuals: " as res "`estname'" _col(52) as txt "T_i: " as res `tmin' as txt " to " as res `tmax'
    if `n' < `nall' di as txt "(" `nall' - `n' " unit(s) with too few observations not tested)"
    di as txt "{hline 78}"
    di as txt _col(36) "{c |}  Fisher  " _col(52) "{c |} Inverse normal" _col(70) "{c |} Units"
    di as txt "Test (H0)" _col(36) "{c |} chi2    P" _col(52) "{c |}   Z       P" _col(70) "{c |} rej."
    di as txt "{hline 35}{c +}{hline 15}{c +}{hline 17}{c +}{hline 8}"
    _xcs_row "Serial correlation, BG(`lags')"  1 `cb'
    _xcs_row "Heteroskedasticity, Koenker"     2 `cb'
    _xcs_row "Normality, Jarque-Bera"          3 `cb'
    _xcs_row "Stability, OLS-CUSUM"            4 `cb'
    _xcs_row "Stability, Hansen L (joint)"     5 `cb'
    di as txt "{hline 78}"
    di as txt "Cross-sectional dependence of the residuals" _col(52) "Statistic" _col(70) "P-value"
    di as txt "  CD (Pesaran 2015)" _col(48) as res %12.3f el(`cd', 1, 1) _col(70) as res %7.4f el(`cd', 1, 2)
    di as txt "  CDw, random weights (Juodis and Reese 2022)" _col(48) as res %12.3f el(`cd', 1, 3) _col(70) as res %7.4f el(`cd', 1, 4)
    di as txt "  Mean |rho| = " as res %5.3f el(`cd', 1, 6) as txt " over " as res el(`cd', 1, 5) as txt " pairs"
    di as txt "{hline 78}"
    di as txt "Unit p-values: exact Monte Carlo (`reps' draws; Gaussian errors, regressors fixed)."
    di as txt "Fisher: -2 sum ln p_i ~ chi2(2N); inverse normal: sum invnorm(p_i)/sqrt(N) ~ N(0,1),"
    di as txt "small values reject. Both assume the units' residuals are independent:"
    if `est' == 1 {
        di as txt "after CCE use CDw (CD itself over-rejects after CCE); if CDw rejects, the"
        di as txt "factors are not fully removed and the combined p-values are too small."
    }
    else {
        di as txt "if CD rejects, common factors remain in the residuals and the combined"
        di as txt "p-values are too small; use estimator(cce)."
    }

    if "`units'" != "" {
        di
        di as txt "Unit p-values"
        di as txt "{hline 70}"
        di as txt %12s abbrev("`ivar'", 12) _col(14) "T_i" _col(20) "  serial" _col(30) "  hetero" ///
            _col(40) "  normal" _col(50) "  cusum" _col(60) "  hansen"
        di as txt "{hline 70}"
        local R = rowsof(`un')
        forvalues i = 1/`R' {
            if el(`un', `i', 8) >= . {
                di as res %12.0g el(`un', `i', 1) _col(14) %4.0f el(`un', `i', 2) as txt "   (not tested)"
                continue
            }
            di as res %12.0g el(`un', `i', 1) _col(14) %4.0f el(`un', `i', 2) ///
                _col(20) %8.3f el(`un', `i', 8) _col(30) %8.3f el(`un', `i', 9) ///
                _col(40) %8.3f el(`un', `i', 10) _col(50) %8.3f el(`un', `i', 11) ///
                _col(60) %8.3f el(`un', `i', 12)
        }
        di as txt "{hline 70}"
    }
end

capture program drop _xcs_row
program define _xcs_row
    args lab j cb
    di as txt "`lab'" _col(36) "{c |}" as res %7.2f el(`cb', `j', 2) %7.4f el(`cb', `j', 3) ///
        as txt _col(52) "{c |}" as res %7.3f el(`cb', `j', 4) %8.4f el(`cb', `j', 5) ///
        as txt _col(70) "{c |}" as res %6.1f 100 * el(`cb', `j', 6) as txt "%"
end
