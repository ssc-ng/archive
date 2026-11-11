*! version 1.2.2  09nov2026
*! _idxspec_iv: instrumental-variables version of the idxspec turning-point protocol.
*! Every function f(x) of the endogenous index is instrumented by f(xhat), where xhat is the
*! first-stage fitted value (generated instruments); fixed effects by within transformation.
program define _idxspec_iv, rclass
    version 14
    syntax varlist(min=2 numeric fv) if, IV(varlist numeric) [FE PANEL(varname) VCE(string) ///
        TRIM(real 0.05) NKnots(integer 4) Level(cilevel) ALPha(real 0.05) XNAME(string) ///
        POWer(real 0.8) noTABle]
    marksample touse
    gettoken y rest : varlist
    gettoken x W : rest
    if "`xname'" == "" local xname "`x'"
    local vceo ""
    if "`vce'" != "" local vceo "vce(`vce')"
    if "`fe'" != "" {
        local estcmd "xtreg"
        local estfe "fe"
    }
    else {
        local estcmd "regress"
        local estfe ""
    }
    quietly count if `touse'
    local N = r(N)
    local plo = 100*`trim'
    local phi = 100*(1 - `trim')
    quietly _pctile `x' if `touse', percentiles(`plo' `phi')
    local lo = r(r1)
    local hi = r(r2)

    * ---------------------------------------------------------------- first stage
    tempvar xh v
    quietly `estcmd' `x' `iv' `W' if `touse', `estfe' `vceo'
    quietly test `iv'
    local F1 = r(F)
    local p1 = r(p)
    if "`fe'" != "" quietly predict double `xh' if `touse', xbu
    else quietly predict double `xh' if `touse', xb
    quietly gen double `v' = `x' - `xh' if `touse'

    * ---------------------------------------------------------------- bases and generated instruments
    tempvar x2 h2
    quietly gen double `x2' = (`x')^2 if `touse'
    quietly gen double `h2' = (`xh')^2 if `touse'
    if `nknots' == 3 local hp "10 50 90"
    if `nknots' == 4 local hp "5 35 65 95"
    if `nknots' == 5 local hp "5 27.5 50 72.5 95"
    if `nknots' == 6 local hp "5 23 41 59 77 95"
    if `nknots' == 7 local hp "2.5 18.33 34.17 50 65.83 81.67 97.5"
    quietly _pctile `x' if `touse', percentiles(`hp')
    forvalues j = 1/`nknots' {
        local t`j' = r(r`j')
    }
    local k = `nknots'
    local km1 = `k' - 1
    local sx ""
    local sh ""
    forvalues i = 1/`=`k'-2' {
        foreach u in x h {
            tempvar s`u'`i'
            local src = cond("`u'" == "x", "`x'", "`xh'")
            quietly gen double `s`u'`i'' = (max(`src' - `t`i'', 0)^3 ///
                - (`t`k'' - `t`i'')/(`t`k'' - `t`km1'')*max(`src' - `t`km1'', 0)^3 ///
                + (`t`km1'' - `t`i'')/(`t`k'' - `t`km1'')*max(`src' - `t`k'', 0)^3) ///
                / (`t`k'' - `t1')^2 if `touse'
            local s`u' "`s`u'' `s`u'`i''"
        }
    }

    * ---------------------------------------------------------------- control-function endogeneity check
    quietly `estcmd' `y' `x' `x2' `v' `W' if `touse', `estfe' `vceo'
    local tcf = _b[`v']/_se[`v']
    local pcf = cond(missing(e(df_r)), 2*(1 - normal(abs(`tcf'))), 2*ttail(e(df_r), abs(`tcf')))

    * ---------------------------------------------------------------- 2SLS fits
    local Wv ""
    if "`W'" != "" {
        fvrevar `W' if `touse'
        local Wv "`r(varlist)'"
    }
    * linear
    _idxspec_2sls `y' if `touse', endog(`x') inst(`xh') wv(`Wv') `fe' panel(`panel') vceo(`vceo')
    local blin = r(b1)
    local selin = r(se1)
    * quadratic
    _idxspec_2sls `y' if `touse', endog(`x' `x2') inst(`xh' `h2') wv(`Wv') `fe' panel(`panel') vceo(`vceo')
    local b1 = r(b1)
    local b2 = r(b2)
    local v11 = r(v11)
    local v22 = r(v22)
    local v12 = r(v12)
    local df = r(df)
    local p_quad = r(p2)
    * restricted cubic spline
    _idxspec_2sls `y' if `touse', endog(`x' `sx') inst(`xh' `sh') wv(`Wv') `fe' panel(`panel') ///
        vceo(`vceo') testlast(`=`k'-2')
    local p_rcs = r(ptest)

    if missing(`df') {
        local crit = invnormal(0.5 + `level'/200)
        local crit1 = invnormal(1 - `alpha')
    }
    else {
        local crit = invttail(`df', (1 - `level'/100)/2)
        local crit1 = invttail(`df', `alpha')
    }
    _idxtp_core, b1(`b1') b2(`b2') v11(`v11') v22(`v22') v12(`v12') lo(`lo') hi(`hi') crit(`crit') df(`df')
    foreach s in tp se_tp delta_lb delta_ub fieller_lb fieller_ub lm_t lm_p slope_lo slope_hi {
        local `s' = r(`s')
    }
    local ftype "`r(fieller_type)'"
    local shape "`r(shape)'"
    local inside = (`tp' > `lo' & `tp' < `hi')
    local finside = ("`ftype'" == "bounded" & `fieller_lb' > `lo' & `fieller_ub' < `hi')
    quietly count if `touse' & `x' <= `tp'
    local tppct = r(N)/`N'

    * ---------------------------------------------------------------- two-lines check (instrumented)
    local tlok = 0
    local tlb1 = .
    local tlb2 = .
    local tlt1 = .
    local tlt2 = .
    local mds = .
    local nbeyond = .
    if `inside' {
        tempvar a1 a2 a3 c1 c2 c3
        quietly gen double `a1' = cond(`x' <= `tp', `x' - `tp', 0) if `touse'
        quietly gen double `a2' = cond(`x' >  `tp', `x' - `tp', 0) if `touse'
        quietly gen double `a3' = (`x' > `tp') if `touse'
        quietly gen double `c1' = cond(`xh' <= `tp', `xh' - `tp', 0) if `touse'
        quietly gen double `c2' = cond(`xh' >  `tp', `xh' - `tp', 0) if `touse'
        quietly gen double `c3' = (`xh' > `tp') if `touse'
        _idxspec_2sls `y' if `touse', endog(`a1' `a2' `a3') inst(`c1' `c2' `c3') wv(`Wv') `fe' ///
            panel(`panel') vceo(`vceo')
        local tlb1 = r(b1)
        local tlb2 = r(b2)
        local tlt1 = r(b1)/sqrt(r(v11))
        local tlt2 = r(b2)/sqrt(r(v22))
        if "`shape'" == "invU" local tlok = (`tlt1' > `crit1' & `tlt2' < -(`crit1'))
        else                   local tlok = (`tlt1' < -(`crit1') & `tlt2' > `crit1')
        if missing(r(df)) local mds = (invnormal(1 - `alpha') + invnormal(`power'))*sqrt(r(v22))
        else local mds = (invttail(r(df), `alpha') + invttail(r(df), 1 - `power'))*sqrt(r(v22))
        quietly count if `touse' & `x' > `tp'
        local nbeyond = r(N)
    }
    local fw = (`lm_p' < `alpha' & `finside' & `tlok')
    if `fw' local verdict = cond("`shape'"=="invU", "inverted U-shape supported within S (IV)", "U-shape supported within S (IV)")
    else if (`p_rcs' < `alpha' | `p_quad' < `alpha') local verdict "nonlinear (IV); turning point within S not established"
    else local verdict "no evidence against linearity over S (IV)"

    if "`table'" == "" {
        di
        di as txt "Instrumental-variables specification analysis for index covariate " as res "`xname'"
        di as txt "Dependent variable: " as res "`y'" as txt "   Instruments for the index: " as res "`iv'" ///
            as txt "   N = " as res `N' as txt cond("`fe'" != "", "   (within estimator)", "")
        di as txt "f(x) instrumented by f(xhat); S = [" as res %8.4f `lo' as txt ", " as res %8.4f `hi' as txt "]"
        di as txt "{hline 78}"
        di as txt "  First stage: F(excluded instruments) = " as res %9.2f `F1' as txt ", p = " as res %6.4f `p1' ///
            as txt cond(`F1' < 10, "   (weak: F < 10)", "")
        di as txt "  Control-function test of exogeneity: t = " as res %6.3f `tcf' as txt ", p = " as res %6.4f `pcf'
        di as txt "  Linear IV effect = " as res %9.4f `blin' as txt " (se " as res %7.4f `selin' as txt ")"
        di as txt "  Quadratic IV: b(x) = " as res %9.4f `b1' as txt ", b(x^2) = " as res %9.4f `b2' ///
            as txt " (p = " as res %6.4f `p_quad' as txt ");  spline nonlinearity p = " as res %6.4f `p_rcs'
        di as txt "  Turning point = " as res %9.4f `tp' as txt " (percentile " as res %5.1f 100*`tppct' as txt ")"
        if "`ftype'" == "bounded" di as txt "  Fieller `level'% CI = [" as res %9.4f `fieller_lb' as txt ", " as res %9.4f `fieller_ub' as txt "]"
        else if "`ftype'" == "union" di as txt "  Fieller `level'% CI = (-inf, " as res %9.4f `fieller_lb' as txt "] U [" as res %9.4f `fieller_ub' as txt ", +inf)"
        else di as txt "  Fieller `level'% CI = " as res "unbounded"
        di as txt "  Lind-Mehlum on S: t = " as res %6.3f `lm_t' as txt ", p = " as res %6.4f `lm_p'
        if `inside' {
            di as txt "  Two-lines (IV) at turning point: slope below = " as res %8.4f `tlb1' as txt " (t = " as res %5.2f `tlt1' ///
                as txt "), above = " as res %8.4f `tlb2' as txt " (t = " as res %5.2f `tlt2' as txt ")"
            di as txt "  Beyond turning point: " as res `nbeyond' as txt " obs.; minimum detectable opposite-sign slope = " as res %8.4f `mds'
        }
        else di as txt "  Two-lines check not evaluated: turning point outside S"
        di as txt "{hline 78}"
        di as txt "  Verdict: " as res "`verdict'"
    }
    return scalar N = `N'
    return scalar F_first = `F1'
    return scalar p_first = `p1'
    return scalar p_endog = `pcf'
    return scalar b_lin = `blin'
    return scalar se_lin = `selin'
    return scalar b1 = `b1'
    return scalar b2 = `b2'
    return scalar p_quad = `p_quad'
    return scalar p_rcs = `p_rcs'
    return scalar tp = `tp'
    return scalar tp_pct = `tppct'
    return scalar fieller_lb = `fieller_lb'
    return scalar fieller_ub = `fieller_ub'
    return scalar lm_t = `lm_t'
    return scalar lm_p = `lm_p'
    return scalar twolines_t1 = `tlt1'
    return scalar twolines_t2 = `tlt2'
    return scalar mds = `mds'
    return scalar n_beyond = `nbeyond'
    return scalar supported = `fw'
    return scalar lo = `lo'
    return scalar hi = `hi'
    return local fieller_type "`ftype'"
    return local shape "`shape'"
    return local verdict "`verdict'"
end

program define _idxspec_2sls, rclass
    version 14
    syntax varname if, ENDOG(varlist) INST(varlist) [WV(string) FE PANEL(string) VCEO(string) TESTLAST(integer 0)]
    marksample touse, novarlist
    local y `varlist'
    if "`fe'" == "" {
        quietly ivregress 2sls `y' `wv' (`endog' = `inst') if `touse', small `vceo'
        local en "`endog'"
    }
    else {
        * within transformation of all variables, then 2SLS without constant
        local all "`y' `endog' `inst' `wv'"
        local dy ""
        local den ""
        local din ""
        local dw ""
        local i = 0
        foreach v of local all {
            local ++i
            tempvar m`i' d`i'
            quietly egen double `m`i'' = mean(`v') if `touse', by(`panel')
            quietly gen double `d`i'' = `v' - `m`i'' if `touse'
        }
        local ne : word count `endog'
        local ni : word count `inst'
        local dy "`d1'"
        local j = 1
        forvalues q = 1/`ne' {
            local ++j
            local den "`den' `d`j''"
        }
        forvalues q = 1/`ni' {
            local ++j
            local din "`din' `d`j''"
        }
        while `j' < `i' {
            local ++j
            local dw "`dw' `d`j''"
        }
        quietly ivregress 2sls `dy' `dw' (`den' = `din') if `touse', noconstant small `vceo'
        local en "`den'"
    }
    tempname V
    matrix `V' = e(V)
    local e1 : word 1 of `en'
    return scalar b1 = _b[`e1']
    return scalar se1 = _se[`e1']
    return scalar v11 = _se[`e1']^2
    local ne : word count `en'
    if `ne' >= 2 {
        local e2 : word 2 of `en'
        return scalar b2 = _b[`e2']
        return scalar v22 = _se[`e2']^2
        return scalar v12 = `V'[colnumb(`V', "`e1'"), colnumb(`V', "`e2'")]
        quietly test `e2'
        return scalar p2 = r(p)
    }
    if `testlast' > 0 {
        local tl ""
        forvalues q = `=`ne' - `testlast' + 1'/`ne' {
            local w : word `q' of `en'
            local tl "`tl' `w'"
        }
        quietly test `tl'
        return scalar ptest = r(p)
    }
    return scalar df = e(df_r)
end
