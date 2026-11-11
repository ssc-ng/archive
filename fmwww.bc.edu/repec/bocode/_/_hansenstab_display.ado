*! _hansenstab_display  version 1.0.0  21oct2026
capture program drop _hansenstab_display
program define _hansenstab_display
    version 14
    syntax, res(name) names(string) kname(string) bw(real) boot(integer) t(integer) ///
        k(integer) dovar(integer) depvar(string) kern(integer)

    local m = `k' + `dovar'
    di
    di as txt "Hansen (1992) tests for parameter stability" _col(56) "Obs = " as res %9.0f `t'
    di as txt "Dependent variable: " as res "`depvar'"
    if `kern' == 0 di as txt "Variance: iid (Hansen 1992)"
    else di as txt "Variance: HAC, `kname' kernel, bandwidth " as res %6.2f `bw'
    di as txt "H0: the parameter(s) are constant over the sample; H1: martingale variation (random walk)"
    di as txt "{hline 78}"
    if `boot' > 0 di as txt "Parameter" _col(26) "L statistic" _col(42) "df" _col(48) "P (asymptotic)" _col(65) "P (bootstrap)"
    else di as txt "Parameter" _col(26) "L statistic" _col(42) "df" _col(48) "P (asymptotic)"
    di as txt "{hline 78}"
    forvalues i = 1/`m' {
        local nm : word `i' of `names'
        if "`nm'" == "_variance" local nm "error variance"
        _hst_row "`nm'" `=el(`res',`i',1)' 1 `=el(`res',`i',2)' `=el(`res',`i',3)' `boot'
    }
    di as txt "{hline 78}"
    _hst_row "Coefficients jointly" `=el(`res',`m'+1,1)' `k' `=el(`res',`m'+1,2)' `=el(`res',`m'+1,3)' `boot'
    if `dovar' _hst_row "All (incl. variance)" `=el(`res',`m'+2,1)' `m' `=el(`res',`m'+2,2)' `=el(`res',`m'+2,3)' `boot'
    di as txt "{hline 78}"
    di as txt "Asymptotic p-values: distribution of the integral of a squared Brownian bridge (Nyblom 1989)."
    if `boot' > 0 {
        if `kern' == 0 di as txt "Bootstrap: fixed-regressor wild bootstrap (Rademacher), `boot' replications."
        else di as txt "Bootstrap: fixed-regressor dependent wild bootstrap (Shao 2010), `boot' replications."
    }
    if `kern' == 0 di as txt "If the errors are serially correlated, use {bf:kernel(bartlett)} or {bf:kernel(qs)}."
end

capture program drop _hst_row
program define _hst_row
    args lab stat df p pb boot
    local lab = abbrev("`lab'", 24)
    if `boot' > 0 di as txt "`lab'" _col(24) as res %11.4f `stat' _col(40) as res %4.0f `df' _col(52) as res %7.4f `p' _col(68) as res %7.4f `pb'
    else di as txt "`lab'" _col(24) as res %11.4f `stat' _col(40) as res %4.0f `df' _col(52) as res %7.4f `p'
end
