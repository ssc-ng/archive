*! tsnormal  version 1.0.0  21oct2026
*! Normality tests for time series and regression residuals that remain valid under
*! serial correlation: Bai and Ng (2005) skewness, kurtosis and joint tests (HAC),
*! Lobato and Velasco (2004), and an AR-sieve bootstrap of the Anderson-Darling and
*! Jarque-Bera statistics under the Gaussian null; classical Jarque-Bera for comparison.
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop tsnormal
program define tsnormal, rclass
    version 14

    syntax [varlist(default=none ts numeric)] [if] [in] [,     ///
        KERnel(string) BW(real -1) BOOT(integer 0) SEED(string) ///
        PMAX(integer -1) Level(cilevel) NODisplay ]

    // ---------------------------------------------------------------
    // series to test: a varlist, or the residuals of the last estimation
    // ---------------------------------------------------------------
    local resid 0
    if "`varlist'" == "" {
        if "`e(cmd)'" == "" {
            di as err "specify a variable, or run an estimation command first to test its residuals"
            exit 301
        }
        tempvar ehat
        capture predict double `ehat' if e(sample), residuals
        if _rc {
            capture predict double `ehat' if e(sample), resid
        }
        if _rc {
            di as err "{bf:predict, residuals} is not available after {bf:`e(cmd)'}; create the residuals and pass them as a variable"
            exit 198
        }
        local varlist "`ehat'"
        local vlabels "residuals (`e(cmd)' `e(depvar)')"
        local resid 1
    }

    qui tsset
    local tvar "`r(timevar)'"
    local pvar "`r(panelvar)'"
    local delta = r(tdelta)
    if "`pvar'" != "" {
        di as err "tsnormal is for a single time series; with panel data, use {bf:if} to select one unit"
        exit 459
    }
    marksample touse0, novarlist
    tsrevar `varlist'
    local tvlist "`r(varlist)'"

    local kernel = lower(strtrim("`kernel'"))
    if "`kernel'" == "" | "`kernel'" == "qs" | "`kernel'" == "quadraticspectral" local kern 1
    else if inlist("`kernel'", "bartlett", "nw", "neweywest") local kern 2
    else {
        di as err "kernel() must be qs or bartlett"
        exit 198
    }
    local kname = cond(`kern' == 1, "quadratic spectral", "Bartlett")
    local bwm = cond(`bw' < 0, ., `bw')
    local pmx = cond(`pmax' < 0, ., `pmax')
    if `boot' < 0 {
        di as err "boot() must be a positive integer"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    _tsnormal_load

    local nv : word count `varlist'
    tempname R ONE
    local j 0
    foreach v of local varlist {
        local ++j
        local tv : word `j' of `tvlist'
        tempvar touse
        qui gen byte `touse' = `touse0' & !missing(`tv')
        qui count if `touse'
        local N = r(N)
        if `N' < 20 {
            di as err "`v': at least 20 observations are needed (N = `N')"
            exit 2001
        }
        // the sample must be one run of consecutive periods
        qui su `tvar' if `touse', meanonly
        if `N' != round((r(max) - r(min)) / `delta') + 1 {
            di as err "`v': the sample has gaps in `tvar'; tsnormal needs consecutive observations"
            exit 459
        }
        mata: tsn_run("`tv'", "`touse'", `kern', `bwm', `boot', `pmx', "`ONE'")
        matrix `R' = nullmat(`R') \ `ONE'
        if `resid' local rn "residuals"
        else local rn = abbrev("`v'", 32)
        local rnames `"`rnames' `"`rn'"'"'
        drop `touse'
    }

    matrix colnames `R' = N skew kurt pi3 p_pi3 pi4 p_pi4 bn p_bn lv p_lv lv3 p_lv3 lv4 p_lv4 jb p_jb ad p_ad p_jbboot arp bw3 bw4
    local rr ""
    foreach rn of local rnames {
        local rr `"`rr' `=strtoname("`rn'")'"'
    }
    matrix rownames `R' = `rr'

    if "`nodisplay'" == "" _tsnormal_display, res(`R') names(`"`rnames'"') kname(`kname') boot(`boot') level(`level') resid(`resid')

    // r() results for the last (or only) series
    local k = rowsof(`R')
    local cn : colnames `R'
    local c 0
    foreach nm of local cn {
        local ++c
        if !missing(el(`R', `k', `c')) return scalar `nm' = el(`R', `k', `c')
    }
    return local kernel "`kname'"
    return scalar boot = `boot'
    return matrix table = `R'
end
