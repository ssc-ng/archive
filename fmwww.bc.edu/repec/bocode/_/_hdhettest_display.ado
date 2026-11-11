*! _hdhettest_display  version 1.1.0  10nov2026
capture program drop _hdhettest_display
program define _hdhettest_display
    version 14
    syntax, res(name) info(name) reps(integer) dist(integer) depvar(string) n0(integer) [zmode(integer 0)]

    local n = el(`info', 1, 1)
    local p = el(`info', 1, 2)
    di
    di as txt "Heteroskedasticity tests for regressions with many regressors"
    di as txt "Dependent variable: " as res "`depvar'" _col(52) as txt "Obs        = " as res %9.0f `n'
    di as txt "H0: constant error variance" _col(52) as txt "Parameters = " as res %9.0f `p'
    di as txt _col(52) "p/n        = " as res %9.3f `p' / `n'
    if el(`info', 1, 3) > 0 {
        di as txt "(" el(`info', 1, 3) " observation(s) with leverage 1 excluded: their residuals are zero by construction)"
    }
    di as txt "{hline 78}"
    di as txt "Test" _col(40) "Statistic" _col(53) "df" _col(57) "P asymptotic" _col(71) "P exact"
    di as txt "{hline 78}"
    _hdh_row "Coefficient of variation (CVT)"  1 `res'
    _hdh_row "Approximate LR (ALRT)"           2 `res'
    _hdh_row "Koenker, all regressors"         3 `res'
    _hdh_row "Koenker, fitted values"          4 `res'
    if `zmode' == 1 _hdh_row "Koenker, indicators()"            6 `res'
    if `zmode' == 2 _hdh_row "Koenker, levels and squares"      6 `res'
    if `zmode' == 3 _hdh_row "Koenker, White (levels, sq., cp.)" 6 `res'
    di as txt "{hline 78}"
    _hdh_row "Normality pre-test: Jarque-Bera" 5 `res'
    di as txt "{hline 78}"
    if `dist' == 1 {
        di as txt "P exact: Monte Carlo test (`reps' draws) under Gaussian errors with the design held fixed;"
        di as txt "its size is exact for any n and number of regressors when the errors are normal."
    }
    else {
        di as txt "P exact: Monte Carlo test (`reps' draws) under Student-t errors with the estimated excess"
        if el(`info', 1, 5) < . {
            di as txt "kurtosis " as res %6.3f el(`info', 1, 4) as txt " (df = " as res %6.2f el(`info', 1, 5) as txt ")."
        }
        else di as txt "kurtosis " as res %6.3f el(`info', 1, 4) as txt " (<= 0: Gaussian errors used)."
        di as txt "The ALRT is not robust to non-normal errors and the CVT is conservative under this option."
    }
    di as txt "CVT and ALRT respond to non-normality as well as to heteroskedasticity: read them"
    di as txt "together with the normality pre-test. The asymptotic Koenker test is undersized when"
    di as txt "p/n is large; the exact p-values are not."
    if `zmode' > 0 {
        di as txt "After OLS the Pagan-Hall (1983) test has the same limit as the Koenker test on the"
        di as txt "same indicators; after IV estimation use {helpb ivhettest}."
    }
    if el(`info', 1, 6) < . {
        di as txt "CVT null mean " as res %6.3f el(`info', 1, 6) as txt " and s.d. " as res %6.3f el(`info', 1, 7) ///
            as txt " (normal errors, this design)."
    }
end

capture program drop _hdh_row
program define _hdh_row
    args lab j res
    local df = el(`res', `j', 2)
    local pa = el(`res', `j', 3)
    di as txt "`lab'" _col(38) as res %11.4f el(`res', `j', 1) _c
    if `df' < . di as res _col(51) %4.0f `df' _c
    if `pa' < . di as res _col(60) %7.4f `pa' _c
    di as res _col(71) %7.4f el(`res', `j', 4)
end
