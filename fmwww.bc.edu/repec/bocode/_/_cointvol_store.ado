*! _cointvol_store 0.1.0  26sep2026
*! Caches the main result matrix of the last cointvol subcommand for -cointvol table-
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Called by the -cointvol- dispatcher right after a subcommand returns, while its
*! r() / e() results are still current. Not r-class, so r() is left untouched.

program define _cointvol_store
    version 14.0
    args sub
    capture matrix drop __cointvol_last
    global COINTVOL_LAST_sub ""
    global COINTVOL_LAST_src ""

    // 1. r-class results: first matrix found in this priority order
    //    (skipped for estimators: r(table) is only the -ereturn display- matrix)
    local rmats : r(matrices)
    if `"`e(cmd)'"' == "cointvol `sub'" local rmats ""
    foreach m in stats results tests rank ic estimates coef {
        if `: list m in rmats' {
            matrix __cointvol_last = r(`m')
            global COINTVOL_LAST_src "r(`m')"
            continue, break
        }
    }

    // 2. e-class estimators: coefficient table from e(b), e(V)
    if "$COINTVOL_LAST_src" == "" & strpos(`"`e(cmd)'"', "cointvol") == 1 {
        tempname b V T
        capture matrix `b' = e(b)
        capture matrix `V' = e(V)
        if _rc == 0 {
            local k = colsof(`b')
            matrix `T' = J(`k', 4, .)
            forvalues j = 1/`k' {
                local se = sqrt(`V'[`j', `j'])
                matrix `T'[`j', 1] = `b'[1, `j']
                matrix `T'[`j', 2] = `se'
                if `se' > 0 & `se' < . {
                    matrix `T'[`j', 3] = `b'[1, `j'] / `se'
                    matrix `T'[`j', 4] = 2 * normal(-abs(`b'[1, `j'] / `se'))
                }
            }
            local cn : colfullnames `b'
            matrix rownames `T' = `cn'
            matrix colnames `T' = coef std_err z p_value
            matrix __cointvol_last = `T'
            global COINTVOL_LAST_src "e(b), e(V)"
        }
    }
    if "$COINTVOL_LAST_src" != "" {
        global COINTVOL_LAST_sub "`sub'"
    }
end
