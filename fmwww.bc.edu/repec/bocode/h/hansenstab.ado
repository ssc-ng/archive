*! hansenstab  version 1.0.0  21oct2026
*! Hansen (1992) / Nyblom (1989) tests for parameter stability in linear regression:
*! individual and joint L statistics, exact asymptotic p-values (Imhof inversion), HAC
*! versions for serially correlated errors, and wild or dependent wild bootstrap p-values.
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop hansenstab
program define hansenstab, rclass
    version 14

    syntax [varlist(default=none ts fv numeric)] [if] [in] [,  ///
        NOConstant KERnel(string) BW(real -1) NOVariance        ///
        BOOT(integer 0) SEED(string) NODisplay ]

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
        local post 1
        local depvar "`e(depvar)'"
        // regressors exactly as regress kept them (base levels and omitted
        // terms, including those inside interactions, are flagged by _ms_omit_info)
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
        if !`hascons' local noconstant "noconstant"
        tempvar es
        qui gen byte `es' = e(sample)
        local ifexp "if `es'"
        if "`if'`in'" != "" {
            di as err "if and in are not allowed after regress; the estimation sample is used"
            exit 198
        }
    }
    else {
        gettoken depvar xs : varlist
    }

    qui tsset
    local tvar "`r(timevar)'"
    local delta = r(tdelta)
    if "`r(panelvar)'" != "" {
        di as err "hansenstab is for a single time series; with panel data, use {bf:if} to select one unit"
        exit 459
    }

    local kernel = lower(strtrim("`kernel'"))
    if "`kernel'" == "" | "`kernel'" == "none" local kern 0
    else if "`kernel'" == "qs" local kern 1
    else if inlist("`kernel'", "bartlett", "nw") local kern 2
    else {
        di as err "kernel() must be none, bartlett or qs"
        exit 198
    }
    local kname = word("none Bartlett quadratic-spectral", `kern' + 1)
    local bwm = cond(`bw' < 0, ., `bw')
    if `boot' < 0 {
        di as err "boot() must be a positive integer"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    local dovar = ("`novariance'" == "")
    local cons = ("`noconstant'" == "")

    // ---------------------------------------------------------------
    // sample and design
    // ---------------------------------------------------------------
    if `post' {
        marksample touse, novarlist
        qui replace `touse' = 0 if !`es'
    }
    else marksample touse
    if "`xs'" != "" {
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
    }
    tsrevar `depvar'
    local ytemp "`r(varlist)'"
    markout `touse' `xtemp' `ytemp'
    // drop collinear regressors
    local xkeep ""
    if "`xtemp'" != "" {
        _rmcoll `xtemp' if `touse', `noconstant' forcedrop
        local xkeep "`r(varlist)'"
    }
    local xnames ""
    local i 0
    foreach v of local xtemp {
        local ++i
        if `: list v in xkeep' {
            local nm : word `i' of `xs'
            local xnames "`xnames' `nm'"
        }
    }
    local xtemp "`xkeep'"
    qui count if `touse'
    local T = r(N)
    local k : word count `xtemp'
    local k = `k' + `cons'
    if `k' == 0 | "`xtemp'" == "" & !`cons' {
        di as err "no regressors"
        exit 102
    }
    if `T' < 2 * (`k' + 5) {
        di as err "too few observations (T = `T') for `k' coefficients"
        exit 2001
    }
    qui su `tvar' if `touse', meanonly
    if `T' != round((r(max) - r(min)) / `delta') + 1 {
        di as err "the sample has gaps in `tvar'; hansenstab needs consecutive observations"
        exit 459
    }

    _hansenstab_load
    tempname R BW B
    mata: hst_run("`ytemp'", "`xtemp'", "`touse'", `cons', `kern', `bwm', `dovar', `boot', "`R'", "`BW'", "`B'")

    local rn "`xnames'"
    if `cons' local rn "`rn' _cons"
    if `dovar' local rn "`rn' _variance"
    local rn "`rn' _coefs_joint _all_joint"
    local rr ""
    foreach r of local rn {
        local rr "`rr' `=abbrev(strtoname("`r'"), 32)'"
    }
    matrix rownames `R' = `rr'
    matrix colnames `R' = L p_asy p_boot

    if "`nodisplay'" == "" {
        _hansenstab_display, res(`R') names(`rn') kname(`kname') bw(`=scalar(`BW')') ///
            boot(`boot') t(`T') k(`k') dovar(`dovar') depvar(`depvar') kern(`kern')
    }

    local m = `k' + `dovar'
    return scalar N = `T'
    return scalar k = `k'
    return scalar bw = scalar(`BW')
    return scalar boot = `boot'
    return scalar Lc = el(`R', `m' + 2, 1)
    return scalar p_Lc = el(`R', `m' + 2, 2)
    return scalar Lb = el(`R', `m' + 1, 1)
    return scalar p_Lb = el(`R', `m' + 1, 2)
    if `boot' > 0 {
        return scalar pb_Lc = el(`R', `m' + 2, 3)
        return scalar pb_Lb = el(`R', `m' + 1, 3)
    }
    if `dovar' {
        return scalar Lvar = el(`R', `m', 1)
        return scalar p_Lvar = el(`R', `m', 2)
    }
    return local kernel "`kname'"
    return local depvar "`depvar'"
    return local indepvars "`xnames'"
    local bn "`xnames'"
    if `cons' local bn "`bn' _cons"
    matrix colnames `B' = `bn'
    return matrix b = `B'
    return matrix table = `R'
end
