*! _xtcdmax_display  version 1.0.0  21oct2026
capture program drop _xtcdmax_display
program define _xtcdmax_display
    version 14
    syntax, res(name) what(string asis) ivar(string)
    local N = el(`res', 1, 1)
    local T = el(`res', 1, 2)
    local bal = el(`res', 1, 14)
    di
    di as txt "Tests of cross-sectional independence" _col(52) "Units   = " as res %9.0f `N'
    di as txt "Variable: " as res `what' _col(52) as txt "Periods = " as res %9.0f `T'
    di as txt "H0: no cross-sectional correlation" _col(52) "Pairs   = " as res %9.0f el(`res', 1, 3)
    di as txt "{hline 78}"
    di as txt "Test" _col(46) "Statistic" _col(58) "Reference" _col(70) "P-value"
    di as txt "{hline 78}"
    di as txt "Sum-type"
    _xcd_row "  CD (Pesaran 2015)"                   4  "N(0,1)"  5 `res'
    _xcd_row "  CD, long-run standardized"           6  "N(0,1)"  7 `res'
    if `bal' _xcd_row "  SN (Wang et al. 2023), one-sided" 12 "N(0,1)" 13 `res'
    di as txt "Max-type"
    _xcd_row "  MAX, long-run standardized"          8  "Sidak"   9 `res'
    di as txt "Combined (Fisher)"
    _xcd_row "  CD long-run + MAX"                   10 "chi2(4)" 11 `res'
    di as txt "{hline 78}"
    di as txt "Mean |rho| = " as res %6.3f el(`res', 1, 19) as txt ";  most significant correlation " ///
        as res %6.3f el(`res', 1, 18) as txt " (`ivar' " as res el(`res', 1, 16) ///
        as txt " and " as res el(`res', 1, 17) as txt ")"
    if el(`res', 1, 15) < . di as txt "Bartlett lags for the long-run correlations: " as res el(`res', 1, 15)
    else di as txt "Bartlett lags for the long-run correlations: floor(4 (T_ij/100)^(2/9)) for each pair"
    di as txt "MAX: smallest pairwise p-value (Beta law of a squared correlation), Sidak-corrected."
    if !`bal' {
        di as txt "Unbalanced panel: correlations use each pair's common periods (min " ///
            as res el(`res', 1, 20) as txt "); SN needs a balanced panel and is not reported."
    }
    di as txt "CD and SN detect dense dependence (many weak correlations); MAX detects sparse"
    di as txt "dependence (a few strong correlations); the Fisher test combines both."
end

capture program drop _xcd_row
program define _xcd_row
    args lab cs ref cp res
    di as txt "`lab'" _col(42) as res %13.4f el(`res', 1, `cs') _col(60) as txt "`ref'" _col(70) as res %7.4f el(`res', 1, `cp')
end
