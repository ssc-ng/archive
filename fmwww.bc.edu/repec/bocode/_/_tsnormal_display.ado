*! _tsnormal_display  version 1.0.0  21oct2026
capture program drop _tsnormal_display
program define _tsnormal_display
    version 14
    syntax, res(name) names(string) kname(string) boot(integer) level(real) resid(integer)

    local k = rowsof(`res')
    local cn : colnames `res'
    local i 0
    foreach nm of local cn {
        local ++i
        local c_`nm' = `i'
    }
    di
    di as txt "Normality tests robust to serial correlation"
    di as txt "H0: the series is normally distributed (skewness tests: symmetric)"
    local r 0
    foreach nm of local names {
        local ++r
        local N = el(`res', `r', `c_N')
        di
        di as txt "Series: " as res "`nm'" as txt _col(58) "Obs = " as res %9.0f `N'
        di as txt "{hline 78}"
        di as txt _col(1) "Test" _col(44) "Statistic" _col(58) "df" _col(66) "P-value"
        di as txt "{hline 78}"
        _tsn_row "Bai-Ng skewness, pi3 ~ N(0,1)"  `=el(`res',`r',`c_pi3')' "" `=el(`res',`r',`c_p_pi3')'
        _tsn_row "Bai-Ng kurtosis, pi4 ~ N(0,1)"  `=el(`res',`r',`c_pi4')' "" `=el(`res',`r',`c_p_pi4')'
        _tsn_row "Bai-Ng joint, chi2"             `=el(`res',`r',`c_bn')'  2  `=el(`res',`r',`c_p_bn')'
        _tsn_row "Lobato-Velasco G, chi2"         `=el(`res',`r',`c_lv')'  2  `=el(`res',`r',`c_p_lv')'
        _tsn_row "   skewness component"          `=el(`res',`r',`c_lv3')' 1  `=el(`res',`r',`c_p_lv3')'
        _tsn_row "   kurtosis component"          `=el(`res',`r',`c_lv4')' 1  `=el(`res',`r',`c_p_lv4')'
        if `boot' > 0 {
            _tsn_row "Anderson-Darling, sieve bootstrap" `=el(`res',`r',`c_ad')' "" `=el(`res',`r',`c_p_ad')'
            _tsn_row "Jarque-Bera, sieve bootstrap"      `=el(`res',`r',`c_jb')' "" `=el(`res',`r',`c_p_jbboot')'
        }
        di as txt "{hline 78}"
        _tsn_row "Jarque-Bera (valid for iid data only)" `=el(`res',`r',`c_jb')' 2 `=el(`res',`r',`c_p_jb')'
        di as txt "{hline 78}"
        di as txt "Skewness = " as res %7.4f el(`res',`r',`c_skew') ///
           as txt "   Kurtosis = " as res %7.4f el(`res',`r',`c_kurt') ///
           as txt "   HAC: `kname', bandwidths " as res %5.2f el(`res',`r',`c_bw3') ///
           as txt ", " as res %5.2f el(`res',`r',`c_bw4')
        if `boot' > 0 di as txt "Sieve bootstrap: AR(" as res el(`res',`r',`c_arp') as txt ") with Gaussian innovations, " as res `boot' as txt " replications"
    }
    if `resid' di as txt _n "Note: residual-based tests assume the model includes a constant."
    di as txt "Note: the Bai-Ng kurtosis test needs long series (it over-rejects below T = 500 in simulations);"
    di as txt "      Lobato-Velasco and the sieve bootstrap are recommended for short series."
end

capture program drop _tsn_row
program define _tsn_row
    args lab stat df p
    if "`df'" == "" di as txt "`lab'" _col(42) as res %11.4f `stat' _col(66) as res %7.4f `p'
    else di as txt "`lab'" _col(42) as res %11.4f `stat' _col(57) as res %3.0f `df' _col(66) as res %7.4f `p'
end
