*! hdhettest  version 1.1.0  10nov2026
*! Heteroskedasticity tests for linear regressions with many regressors: coefficient-of-
*! variation (Li and Yao 2019; Bai, Pan and Yin 2018), approximate likelihood-ratio (Li and
*! Yao 2019) and Koenker (1981) tests, with exact Monte Carlo p-values (Dufour, Khalaf,
*! Bernard and Genest 2004) that are valid for any number of regressors; Jarque-Bera
*! normality pre-test with an exact Monte Carlo p-value (Dufour et al. 1998). Version 1.1.0
*! adds the Koenker test on chosen indicator variables (indicators(), squares, white), the
*! form in which the Pagan and Hall (1983) test applies after OLS.
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop hdhettest
program define hdhettest, rclass
    version 14

    syntax [varlist(default=none ts fv numeric)] [if] [in] [, ///
        Reps(integer 999) SEED(string) ROBust NOMoments NODisplay ///
        INDicators(varlist numeric ts fv) SQuares WHITE ]

    // ---------------------------------------------------------------
    // model: depvar indepvars, or the last regress
    // ---------------------------------------------------------------
    local post 0
    if "`varlist'" == "" {
        if "`e(cmd)'" != "regress" {
            di as err "specify {it:depvar indepvars}, or run {bf:regress} first"
            exit 301
        }
        if "`e(wtype)'" != "" {
            di as err "weights are not supported"
            exit 198
        }
        if "`if'`in'" != "" {
            di as err "if and in are not allowed after regress; the estimation sample is used"
            exit 198
        }
        local post 1
        local depvar "`e(depvar)'"
        // regressors exactly as regress kept them: _ms_omit_info flags base
        // levels and omitted terms, including those inside interactions
        local cn : colnames e(b)
        tempname om
        _ms_omit_info e(b)
        matrix `om' = r(omit)
        local xs ""
        local hascons 0
        local i 0
        foreach c of local cn {
            local ++i
            if "`c'" == "_cons" {
                local hascons 1
                continue
            }
            if `om'[1, `i'] continue
            local xs "`xs' `c'"
        }
        if !`hascons' {
            di as err "the regression must include a constant"
            exit 198
        }
        tempvar es
        qui gen byte `es' = e(sample)
    }
    else {
        gettoken depvar xs : varlist
    }
    local zmode 0
    if "`indicators'" != "" local zmode 1
    if "`squares'" != "" local zmode 2
    if "`white'" != "" local zmode 3
    if ("`indicators'" != "") + ("`squares'" != "") + ("`white'" != "") > 1 {
        di as err "specify only one of indicators(), squares and white"
        exit 198
    }
    if `reps' < 19 {
        di as err "reps() must be at least 19"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    if `post' {
        marksample touse, novarlist
        qui replace `touse' = 0 if !`es'
    }
    else marksample touse
    if strtrim("`xs'") == "" {
        di as err "at least one regressor is needed"
        exit 102
    }
    if !`post' {
        fvexpand `xs' if `touse'
        local xs2 ""
        foreach c in `r(varlist)' {
            _ms_parse_parts `c'
            if !r(omit) local xs2 "`xs2' `c'"
        }
        local xs "`xs2'"
    }
    // one term at a time: fvrevar given several levels of the same factor
    // treats them as one factor and makes the first listed level its base
    local xtemp ""
    foreach c of local xs {
        fvrevar `c'
        local xtemp "`xtemp' `r(varlist)'"
    }
    tsrevar `depvar'
    local ytemp "`r(varlist)'"
    markout `touse' `xtemp' `ytemp'
    // after regress the design is already of full rank; for a varlist, drop
    // collinear regressors
    if !`post' {
        _rmcoll `xtemp' if `touse', forcedrop
        local xtemp "`r(varlist)'"
    }
    // indicator variables: they must not involve the dependent variable
    local ztemp ""
    if `zmode' == 1 {
        fvexpand `indicators' if `touse'
        local zs ""
        foreach c in `r(varlist)' {
            _ms_parse_parts `c'
            if r(omit) continue
            if "`r(name)'" == "`depvar'" {
                di as err "indicators() must not contain the dependent variable"
                exit 198
            }
            local zs "`zs' `c'"
        }
        foreach c of local zs {
            fvrevar `c'
            local ztemp "`ztemp' `r(varlist)'"
        }
        markout `touse' `ztemp'
    }
    qui count if `touse'
    local n = r(N)
    local k : word count `xtemp'
    if `n' < `k' + 4 {
        di as err "too few observations (n = `n') for `k' regressors"
        exit 2001
    }
    if `zmode' >= 2 {
        local nz = 2 * `k'
        if `zmode' == 3 local nz = `k' + `k' * (`k' + 1) / 2
        if `nz' > `n' - 4 {
            di as err "too many indicator variables (`nz') for `n' observations;"
            di as err "use squares or indicators() instead"
            exit 2001
        }
    }

    _hdhettest_load
    tempname R INFO
    local domom = ("`nomoments'" == "")
    local dist = cond("`robust'" != "", 2, 1)
    local chunk = min(`reps', 200)
    mata: hdh_run("`ytemp'", "`xtemp'", "`touse'", `reps', `dist', `chunk', `domom', "`R'", "`INFO'", "`ztemp'", `zmode')
    local tn "cvt alrt koenker koenker_fitted jb"
    if `zmode' > 0 local tn "`tn' koenker_ind"
    matrix rownames `R' = `tn'
    matrix colnames `R' = statistic df p_asy p_mc
    matrix colnames `INFO' = n p n_dropped nu4 df_t cvt_mean cvt_sd

    if "`nodisplay'" == "" {
        _hdhettest_display, res(`R') info(`INFO') reps(`reps') dist(`dist') depvar(`depvar') n0(`n') zmode(`zmode')
    }

    return scalar N = el(`INFO', 1, 1)
    return scalar p = el(`INFO', 1, 2)
    return scalar ratio = el(`INFO', 1, 2) / el(`INFO', 1, 1)
    return scalar reps = `reps'
    local j 0
    foreach t of local tn {
        local ++j
        return scalar `t' = el(`R', `j', 1)
        if !missing(el(`R', `j', 3)) return scalar p_`t'_asy = el(`R', `j', 3)
        return scalar p_`t' = el(`R', `j', 4)
    }
    if `dist' == 2 {
        return scalar nu4 = el(`INFO', 1, 4)
        if !missing(el(`INFO', 1, 5)) return scalar df_t = el(`INFO', 1, 5)
    }
    return local depvar "`depvar'"
    return local indepvars "`xs'"
    if `zmode' == 1 return local indicators "`zs'"
    if `zmode' == 2 return local indicators "regressors and their squares"
    if `zmode' == 3 return local indicators "regressors, squares and cross-products"
    return local errors = cond(`dist' == 1, "Gaussian", "Student t, matched excess kurtosis")
    return matrix table = `R'
end
