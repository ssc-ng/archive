*! _xtutest_pooled  version 1.3.0  20oct2026
*! Homogeneous-slope estimators for xtutest: fixed effects (fe), random effects (re),
*! fixed-effects instrumental variables (iv), and system GMM (gmm), with the residual
*! diagnostics used by xtutest. Called by xtutest; not meant to be run directly.

capture program drop _xtutest_pooled
program define _xtutest_pooled, rclass
    version 14
    syntax , DEPvar(varname) XVar(varname) IVAR(varname) TVAR(varname) TOUSE(varname) ///
        EST(string) ESAMP(varname) [CONTROLS(varlist) IVINST(varlist ts) ENDOG GMMLags(integer 2) NOTIME ONEstep]

    // square of x, time dummies
    tempvar x2
    qui gen double `x2' = `xvar'^2 if `touse'
    local tdum ""
    if "`notime'" == "" {
        qui levelsof `tvar' if `touse', local(tl)
        local first 1
        foreach t of local tl {
            if `first' {
                local first 0
                continue
            }
            tempvar d
            qui gen byte `d' = (`tvar' == `t') if `touse'
            local tdum "`tdum' `d'"
        }
    }
    local rhs "`xvar' `x2' `controls'"
    local kc : word count `controls'
    qui count if `touse'
    local Ng 0
    tempvar first1
    qui bysort `touse' `ivar': gen byte `first1' = (_n == 1) if `touse'
    qui count if `first1' == 1 & `touse'
    local Ng = r(N)
    sort `ivar' `tvar'

    tempvar res
    local esmp "`esamp'"
    local mund    = .
    local mund_df = .
    local mund_p  = .
    local rho     = .
    local tbreak  = .
    tempname b V ST
    local extra ""
    matrix `ST' = J(1, 6, .)     // first-stage F (x), first-stage F (x^2), overid stat, p, AR(1) p, AR(2) p

    // ---------------------------------------------------------------
    if "`est'" == "fe" | "`est'" == "re" {
        qui xtreg `depvar' `rhs' `tdum' if `touse', `est' vce(cluster `ivar')
        qui replace `esmp' = e(sample)
        qui predict double `res' if `esmp', e
        local estname = cond("`est'" == "fe", "fixed effects", "random effects (GLS)")
        if "`est'" == "re" {
            // Mundlak (1978) cluster-robust test of RE against FE: unit means of the regressors
            local mvars ""
            foreach v of local rhs {
                tempvar mv
                qui bysort `ivar': egen double `mv' = mean(`v') if `esmp'
                local mvars "`mvars' `mv'"
            }
            sort `ivar' `tvar'
            qui xtreg `depvar' `rhs' `tdum' `mvars' if `esmp', re vce(cluster `ivar')
            qui test `mvars'
            local mund    = r(chi2)
            local mund_df = r(df)
            local mund_p  = r(p)
            qui xtreg `depvar' `rhs' `tdum' if `touse', re vce(cluster `ivar')
        }
        matrix `b' = e(b)
        matrix `V' = e(V)
        local df = `Ng' - 1
    }
    // ---------------------------------------------------------------
    else if "`est'" == "iv" {
        // instruments: user list, or the first lags of x and x^2
        local inst ""
        if "`ivinst'" == "" {
            tempvar lx lx2
            qui gen double `lx'  = L.`xvar' if `touse'
            qui gen double `lx2' = `lx'^2
            local inst "`lx' `lx2'"
        }
        else {
            foreach v of local ivinst {
                tempvar iz
                qui gen double `iz' = `v' if `touse'
                local inst "`inst' `iz'"
            }
        }
        // within (unit-demeaned) data; time dummies are kept as regressors
        tempvar tu2
        qui gen byte `tu2' = `touse'
        markout `tu2' `depvar' `rhs' `inst'
        local dvars ""
        foreach v in `depvar' `rhs' `tdum' `inst' {
            tempvar m dv
            qui bysort `ivar': egen double `m' = mean(`v') if `tu2'
            qui gen double `dv' = `v' - `m' if `tu2'
            local dvars "`dvars' `dv'"
        }
        sort `ivar' `tvar'
        local nr : word count `rhs'
        local nt : word count `tdum'
        local ni : word count `inst'
        tokenize `dvars'
        local dy "`1'"
        local dx "`2' `3'"
        local dc ""
        forvalues j = 4/`=1 + `nr'' {
            local dc "`dc' ``j''"
        }
        local dt ""
        forvalues j = `=2 + `nr''/`=1 + `nr' + `nt'' {
            local dt "`dt' ``j''"
        }
        local di ""
        forvalues j = `=2 + `nr' + `nt''/`=1 + `nr' + `nt' + `ni'' {
            local di "`di' ``j''"
        }
        qui ivregress 2sls `dy' `dc' `dt' (`dx' = `di') if `tu2', vce(cluster `ivar') noconstant
        qui replace `esmp' = e(sample)
        matrix `b' = e(b)
        matrix `V' = e(V)
        qui predict double `res' if `esmp', residuals
        // overidentification (score test, robust to clustering)
        if `ni' > 2 {
            capture qui estat overid
            if _rc == 0 {
                matrix `ST'[1, 3] = r(score)
                matrix `ST'[1, 4] = r(p_score)
            }
        }
        // first-stage cluster-robust F of the excluded instruments, for x and for x^2
        local j 0
        foreach e of local dx {
            local ++j
            qui regress `e' `dc' `dt' `di' if `esmp', vce(cluster `ivar') noconstant
            qui test `di'
            matrix `ST'[1, `j'] = r(F)
        }
        local estname "fixed-effects IV (2SLS on within data)"
        local df = `Ng' - 1
    }
    // ---------------------------------------------------------------
    else if "`est'" == "gmm" {
        capture which xtdpdsys
        if _rc {
            di as err "estimator(gmm) needs the official command xtdpdsys (Stata 11 or later)"
            exit 199
        }
        if "`endog'" == "" {
            local gcmd "xtdpdsys `depvar' `rhs' `tdum' if `touse', lags(1) maxldep(`gmmlags')"
        }
        else {
            local gcmd "xtdpdsys `depvar' `controls' `tdum' if `touse', lags(1) maxldep(`gmmlags') endogenous(`xvar' `x2', lagstruct(0, `gmmlags'))"
        }
        // two-step with the Windmeijer correction; with few units its weight matrix can be
        // singular, and then the one-step robust estimator is used instead
        local gstep "two-step, Windmeijer-robust"
        if "`onestep'" == "" {
            capture `gcmd' twostep vce(robust)
            local grc = _rc
        }
        else local grc 1
        if `grc' {
            if "`onestep'" == "" di as txt "(two-step GMM not available: its weight matrix is singular with these units and instruments; one-step robust used)"
            capture `gcmd' vce(robust)
            if _rc {
                di as err "system GMM could not be estimated (rc = " _rc "): too many instruments for the number of units."
                di as err "Try notime (drops the time dummies) or a smaller gmmlags()."
                exit 498
            }
            local gstep "one-step, robust"
        }
        qui replace `esmp' = e(sample)
        matrix `b' = e(b)
        matrix `V' = e(V)
        qui predict double `res' if `esmp', e
        capture qui estat abond
        if _rc == 0 {
            tempname AR
            matrix `AR' = r(arm)
            local ca = colsof(`AR')
            matrix `ST'[1, 5] = el(`AR', 1, `ca')
            if rowsof(`AR') >= 2 matrix `ST'[1, 6] = el(`AR', 2, `ca')
        }
        local estname = "system GMM (`gstep')" + cond("`endog'" != "", ", x endogenous", ", x exogenous")
        local df = .
        local rho = _b[L.`depvar']
    }
    else {
        di as err "estimator() must be cce, mg, fe, re, iv or gmm"
        exit 198
    }

    // coefficients on x, x^2 and the controls, in that order
    tempname bb VV
    local names "`xvar' `x2' `controls'"
    if "`est'" == "iv" local names "`dx' `dc'"
    local k : word count `names'
    matrix `bb' = J(1, `k', .)
    matrix `VV' = J(`k', `k', .)
    local i 0
    foreach r of local names {
        local ++i
        local ci = colnumb(`b', "`r'")
        matrix `bb'[1, `i'] = el(`b', 1, `ci')
        local j 0
        foreach c of local names {
            local ++j
            local cj = colnumb(`b', "`c'")
            matrix `VV'[`i', `j'] = el(`V', `ci', `cj')
        }
    }

    // ---------------------------------------------------------------
    // diagnostics on the residuals
    // ---------------------------------------------------------------
    tempname PDG DGP
    matrix `DGP' = J(4, 3, .)      // rows: serial correlation, heteroskedasticity, normality, stability
    // serial correlation: Wooldridge (2002) test (first-difference regression, H0: corr(du_t, du_t-1) = -0.5)
    if "`est'" != "gmm" {
        tempvar u ul
        local dctrl ""
        foreach v of local controls {
            local dctrl "`dctrl' D.`v'"
        }
        qui regress D.`depvar' D.`xvar' D.`x2' `dctrl' if `esmp', vce(cluster `ivar')
        qui predict double `u' if e(sample), residuals
        qui gen double `ul' = L.`u'
        qui regress `u' `ul', noconstant vce(cluster `ivar')
        qui test `ul' = -0.5
        matrix `DGP'[1, 1] = r(F)
        matrix `DGP'[1, 2] = r(df_r)
        matrix `DGP'[1, 3] = r(p)
    }
    else {
        matrix `DGP'[1, 1] = .
        matrix `DGP'[1, 3] = el(`ST', 1, 6)
    }
    // groupwise heteroskedasticity (modified Wald) and normality (Jarque-Bera)
    mata: xtu_pdiag("`res'", "`ivar'", "`esmp'")
    matrix `DGP'[2, 1] = el(`PDG', 1, 1)
    matrix `DGP'[2, 2] = el(`PDG', 1, 2)
    matrix `DGP'[2, 3] = el(`PDG', 1, 3)
    matrix `DGP'[3, 1] = el(`PDG', 2, 1)
    matrix `DGP'[3, 2] = 2
    matrix `DGP'[3, 3] = el(`PDG', 2, 3)
    // stability: do the coefficients on x and x^2 differ between the two halves of the sample?
    if inlist("`est'", "fe", "re") {
        qui su `tvar' if `esmp', meanonly
        local tmid = floor((r(min) + r(max)) / 2)
        tempvar post px px2
        qui gen byte `post' = (`tvar' > `tmid') if `esmp'
        qui gen double `px'  = `post' * `xvar'
        qui gen double `px2' = `post' * `x2'
        qui xtreg `depvar' `rhs' `px' `px2' `tdum' if `esmp', `est' vce(cluster `ivar')
        qui test `px' `px2'
        matrix `DGP'[4, 1] = cond("`est'" == "fe", r(F), r(chi2))
        matrix `DGP'[4, 2] = 2
        matrix `DGP'[4, 3] = r(p)
        local tbreak = `tmid'
    }

    return scalar mundlak    = `mund'
    return scalar mundlak_df = `mund_df'
    return scalar mundlak_p  = `mund_p'
    return scalar rho        = `rho'
    return scalar tbreak     = `tbreak'
    return matrix b = `bb'
    return matrix V = `VV'
    return matrix pdiag = `DGP'
    return matrix stats = `ST'
    return scalar df = `df'
    return scalar N_g = `Ng'
    qui count if `esmp'
    return scalar N = r(N)
    return local estname "`estname'"
end
