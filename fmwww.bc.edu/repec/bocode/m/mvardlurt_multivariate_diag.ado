*! mvardlurt_multivariate_diag  version 1.1.2  03oct2026
*! Residual diagnostics after mvardlurt_multivariate (also run by the diag option)
*! Breusch-Godfrey(1), Ramsey RESET, Breusch-Pagan (Koenker), ARCH(1), Jarque-Bera

capture program drop mvardlurt_multivariate_diag
program define mvardlurt_multivariate_diag, rclass
    version 14

    if "`e(cmd)'" != "mvardlurt_multivariate" {
        di as err "last estimates not found; run mvardlurt_multivariate first"
        exit 301
    }

    _mvardlurt_multivariate_load

    local case = e(case)
    tempname DG
    local mvu_err ""
    capture mata: mvu_diag_run()
    if _rc | "`mvu_err'" != "" {
        di as err "regression objects are no longer in memory (was Mata cleared?)"
        di as err "re-run mvardlurt_multivariate"
        exit 498
    }

    local W 78
    di as txt _n "{hline `W'}"
    di as res _col(5) "Diagnostic Tests on the ARDL Regression (dependent variable: D.`e(depvar)')"
    di as txt "{hline `W'}"
    di as txt _col(3) "Test" _col(33) "Statistic" _col(46) "df" _col(53) "p-value" _col(65) "Decision (5%)"
    di as txt "{hline `W'}"

    local names `""Breusch-Godfrey LM(1)" "Ramsey RESET" "Breusch-Pagan (Koenker)" "ARCH LM(1)" "Jarque-Bera""'
    local oks   `""No serial corr." "Correct form" "Homoskedastic" "No ARCH" "Normal""'
    local bads  `""Serial corr." "Misspecified" "Heteroskedastic" "ARCH effects" "Non-normal""'

    forvalues i = 1/5 {
        local nm  : word `i' of `names'
        local ok  : word `i' of `oks'
        local bad : word `i' of `bads'
        local stt = el(`DG', `i', 1)
        local dff = el(`DG', `i', 2)
        local pv  = el(`DG', `i', 3)
        if `stt' >= . {
            di as txt _col(3) "`nm'" _col(33) "n/a"
        }
        else {
            local dec "`ok'"
            if `pv' < 0.05 local dec "`bad'"
            di as txt _col(3) "`nm'" _col(30) as res %10.4f `stt' _col(45) %3.0f `dff' ///
                _col(52) %8.4f `pv' _col(65) as txt "`dec'"
        }
    }
    di as txt "{hline `W'}"
    di as txt _col(3) "BG: residual regression on regressors and lagged residual."
    di as txt _col(3) "RESET: squared, cubed and fourth powers of fitted values added."

    matrix colnames `DG' = statistic df p_value
    matrix rownames `DG' = BG1 RESET BP ARCH1 JB
    return matrix diag = `DG'
end
