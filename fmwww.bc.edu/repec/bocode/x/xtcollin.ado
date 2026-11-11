*! xtcollin  version 1.0.0  21oct2026
*! Collinearity diagnostics for the design an estimator actually uses: variance inflation
*! factors, condition indices and variance-decomposition proportions after the within,
*! two-way, first-difference, random-effects (quasi-demeaned), between or CCE
*! transformation, pooled and unit by unit; within-unit share of each regressor's variance.
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop xtcollin
program define xtcollin, rclass sortpreserve
    version 14

    syntax [varlist(default=none ts fv numeric)] [if] [in] [,   ///
        TRansform(string) THeta(real -1) CCEvars(varlist ts numeric) ///
        UNITs VDP NOConstant NODisplay ]

    // ---------------------------------------------------------------
    // regressors: varlist, or those of the last estimation
    // ---------------------------------------------------------------
    local post 0
    local depvar ""
    if "`varlist'" == "" {
        if "`e(cmd)'" == "" {
            di as err "specify the regressors, or run an estimation command first"
            exit 301
        }
        local post 1
        local depvar "`e(depvar)'"
        local cn : colnames e(b)
        local eqs : coleq e(b), quoted
        local first : word 1 of `eqs'
        tempname om
        _ms_omit_info e(b)
        matrix `om' = r(omit)
        local xs ""
        local i 0
        foreach c of local cn {
            local ++i
            local eq : word `i' of `eqs'
            if `"`eq'"' != `"`first'"' continue
            if "`c'" == "_cons" continue
            if `om'[1, `i'] continue
            local xs "`xs' `c'"
        }
        if "`transform'" == "" {
            local transform "none"
            if "`e(cmd)'" == "xtreg" {
                if "`e(model)'" == "fe" local transform "within"
                else if "`e(model)'" == "re" local transform "quasi"
                else if "`e(model)'" == "be" local transform "between"
            }
            else if inlist("`e(cmd)'", "xtdcce2", "xtutest") local transform "cce"
            else if inlist("`e(cmd)'", "areg", "reghdfe", "xtivreg") local transform "within"
        }
        if "`transform'" == "quasi" & `theta' < 0 {
            capture confirm scalar e(thta_50)
            if !_rc local theta = e(thta_50)
            else {
                capture local theta = e(theta)
                if "`theta'" == "" | "`theta'" == "." {
                    di as err "theta not found in e(); specify theta()"
                    exit 198
                }
            }
        }
        tempvar es
        qui gen byte `es' = e(sample)
    }
    else local xs "`varlist'"

    local transform = lower(strtrim("`transform'"))
    if "`transform'" == "" {
        capture xtset
        if _rc local transform "none"
        else local transform "within"
    }
    local hows "none within twoway fd quasi between cce"
    local how : list posof "`transform'" in hows
    if `how' == 0 {
        di as err "transform() must be none, within, twoway, fd, quasi, between or cce"
        exit 198
    }
    local how = `how' - 1
    if `how' == 4 & !inrange(`theta', 0, 1) {
        di as err "transform(quasi) needs theta(#) between 0 and 1 (stored by xtreg, re as e(theta))"
        exit 198
    }

    local ivar ""
    local tvar ""
    capture xtset
    if !_rc {
        local ivar "`r(panelvar)'"
        local tvar "`r(timevar)'"
    }
    if `how' > 0 & "`ivar'" == "" {
        di as err "transform(`transform') needs panel data; use {bf:xtset} panelvar timevar"
        exit 459
    }
    if "`units'" != "" & "`ivar'" == "" {
        di as err "option units needs panel data"
        exit 459
    }

    // ---------------------------------------------------------------
    // sample and design
    // ---------------------------------------------------------------
    marksample touse, novarlist
    if `post' qui replace `touse' = 0 if !`es'
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
    markout `touse' `xtemp'
    if "`ivar'" != "" markout `touse' `ivar' `tvar'
    local k : word count `xtemp'
    if `k' < 2 {
        di as err "at least two regressors are needed"
        exit 102
    }
    // CCE averages: of the dependent variable (if known) and the regressors
    local ztemp ""
    if `how' == 6 {
        if "`ccevars'" != "" {
            tsrevar `ccevars'
            local ztemp "`r(varlist)'"
        }
        else {
            local ztemp "`xtemp'"
            if "`depvar'" != "" {
                tsrevar `depvar'
                local ztemp "`r(varlist)' `ztemp'"
            }
        }
        markout `touse' `ztemp'
    }
    qui count if `touse'
    local N = r(N)
    if `N' <= `k' + 1 {
        di as err "too few observations"
        exit 2001
    }
    if "`ivar'" != "" sort `ivar' `tvar'

    _xtcollin_load
    tempname VIF CI VDP NTR CTR CNR CNT WS UN
    local dou = ("`units'" != "")
    local nocons = ("`noconstant'" != "")
    mata: xtc_run("`xtemp'", "`ivar'", "`tvar'", "`ztemp'", "`touse'", `how', `theta', `dou', `nocons', ///
        "`VIF' `CI' `VDP' `NTR' `CTR' `CNR' `CNT' `WS' `UN'")

    local rn ""
    foreach c of local xs {
        local rn "`rn' `=abbrev(strtoname("`c'"), 32)'"
    }
    matrix rownames `VIF' = `rn'
    matrix colnames `VIF' = raw transformed
    local vn "`rn'"
    if scalar(`CTR') local vn "_cons `vn'"
    matrix colnames `VDP' = `vn'
    local nci = rowsof(`CI')
    local cr ""
    forvalues j = 1/`nci' {
        local cr "`cr' ci`j'"
    }
    matrix rownames `CI' = `cr'
    matrix colnames `CI' = condition_index
    matrix rownames `VDP' = `cr'
    if "`ivar'" != "" {
        matrix rownames `WS' = `rn'
        matrix colnames `WS' = within_share
    }
    if `dou' {
        matrix colnames `UN' = `ivar' cond_number `rn'
    }

    local tname : word `=`how'+1' of "untransformed (pooled)" "within (unit fixed effects)" "two-way within (unit and time effects)" "first differences" "quasi-demeaned (random effects)" "between (unit means)" "CCE (unit-specific cross-section averages partialled out)"
    if "`nodisplay'" == "" {
        _xtcollin_display, vif(`VIF') ci(`CI') vdpm(`VDP') ws(`WS') un(`UN') names(`xs') ///
            tname(`"`tname'"') how(`how') n(`N') ntr(`=scalar(`NTR')') cnraw(`=scalar(`CNR')') ///
            cntr(`=scalar(`CNT')') `units' `vdp' panel(`="`ivar'" != ""') theta(`theta')
    }

    return scalar N = `N'
    return scalar N_tr = scalar(`NTR')
    return scalar cn_raw = scalar(`CNR')
    return scalar cn_tr = scalar(`CNT')
    return local transform "`transform'"
    return local varlist "`xs'"
    if `how' == 4 return scalar theta = `theta'
    return matrix vif = `VIF'
    return matrix ci = `CI'
    return matrix vdp = `VDP'
    if "`ivar'" != "" return matrix within_share = `WS'
    if `dou' return matrix units = `UN'
end
