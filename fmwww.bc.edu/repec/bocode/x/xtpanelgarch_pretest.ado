*! xtpanelgarch_pretest 1.0.0  06nov2026
*! Pre-estimation identification strategy for panel GARCH
*! Cermeno & Grier (2001, sec. 5; 2006, sec. 10.3)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> source map
*  [1] individual effects in the mean: LSDV + HAC Wald, chi2(N-1)          CG(2001) 5.1, CG(2006) 10.3.1
*  [2] PACF of squared residuals + Engle LM-ARCH(j)                        CG(2001) 5.2, Table 1; Engle (1982)
*  [3] individual effects in the variance: AR regression of u^2 with and
*      without unit intercepts (F, chi2) + LR groupwise heteroskedasticity CG(2001) 5.2; CG(2006) 10.3.2
*  [4] cross-sectional correlation: LR diagonal-Sigma test, Breusch-Pagan
*      LM, Pesaran CD                                                      CG(2006) 10.3.2 / 10.4.1
*  [5] AR regression of residual cross products + pair-specific effects    CG(2006) 10.3.2

program define xtpanelgarch_pretest, rclass
    version 14.0
    syntax varlist(ts min=1) [if] [in] , [ HACLags(integer -1) Lags(integer 10) ///
        ARFE(integer 1) CPLags(integer 1) SIGlevel(real 0.05) noXS ]
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    gettoken yorig xorig : varlist
    tsrevar `varlist'
    local tsv "`r(varlist)'"
    gettoken y xv : tsv
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch pretest"
    local N = r(N)
    local T = r(T)
    local units "`r(units)'"
    if `N' < 2 {
        di as err "pretest needs at least 2 panels"
        exit 2001
    }
    if `haclags' < 0 local haclags = floor(4 * (`T' / 100)^(2 / 9))
    if `lags' >= `T' - 5 local lags = max(1, `T' - 6)

    tempname h
    capture _estimates hold `h', restore nullok

    // [1] individual effects in the mean ----------------------------------
    qui newey `y' `xv' i.`ivar' if `touse', lag(`haclags') force
    qui testparm i.`ivar'
    local Wmu = r(F) * r(df)
    local Wdf = r(df)
    local Wp = chi2tail(`Wdf', `Wmu')
    local usefe = (`Wp' < `siglevel')
    tempvar e e2
    if `usefe' {
        qui regress `y' `xv' i.`ivar' if `touse'
        local rtype "LSDV"
    }
    else {
        qui regress `y' `xv' if `touse'
        local rtype "OLS"
    }
    qui predict double `e' if `touse', residuals
    qui gen double `e2' = `e' * `e' if `touse'

    // [2]-[3] squared residuals ------------------------------------------
    tempname W E PAC LM FE XS CP CPFE
    mata: _xtpg_getE("`e2'", "`touse'", `N', "`W'")
    mata: _xtpg_getE("`e'", "`touse'", `N', "`E'")
    mata: _xtpg_pre_ar(st_matrix("`W'"), `lags', "`PAC'", "`LM'", "`FE'", `arfe')
    if "`xs'" == "" {
        mata: _xtpg_pre_xs(st_matrix("`E'"), `cplags', "`XS'", "`CP'", "`CPFE'")
    }

    // ---------------- display --------------------------------------------
    di _n as txt "{hline 78}"
    di as txt "Panel GARCH pre-tests (Cermeño & Grier 2001, 2006)" _col(56) "N = " as res `N' as txt ",  T = " as res `T'
    di as txt "Dependent variable: " as res "`yorig'" as txt "   regressors: " as res "`xorig'"
    di as txt "{hline 78}"
    di as txt "[1] Individual effects in the mean (LSDV, HAC lag = `haclags')"
    di as txt "    H0: mu_1 = ... = mu_N" _col(44) "Wald chi2(" as res `Wdf' as txt ") = " as res %9.3f `Wmu' _col(68) as txt "p = " as res %6.4f `Wp'
    di as txt "    -> residuals used below: " as res "`rtype'"
    di as txt "{hline 78}"
    di as txt "[2] Squared `rtype' residuals: partial autocorrelations and LM-ARCH"
    di as txt _col(8) "lag" _col(17) "PAC" _col(28) "t-ratio" _col(40) "p (1-sided)" _col(55) "LM-ARCH(j)" _col(70) "p-value"
    forvalues k = 1/`lags' {
        local pv = `PAC'[`k', 3]
        local st ""
        if `pv' < 0.10 local st "*"
        if `pv' < 0.05 local st "**"
        if `pv' < 0.01 local st "***"
        di as txt _col(6) %4.0f `k' as res _col(12) %9.4f `PAC'[`k', 1] as txt "`st'" _col(26) as res %9.3f `PAC'[`k', 2] _col(40) %9.4f `pv' _col(53) %11.3f `LM'[`k', 1] _col(68) %8.4f `LM'[`k', 3]
    }
    local nsig 0
    forvalues k = 1/`lags' {
        if `PAC'[`k', 3] < `siglevel' local nsig = `nsig' + 1
    }
    local sig1 = (`PAC'[1, 3] < `siglevel')
    di as txt "{hline 78}"
    di as txt "[3] Individual effects in the variance"
    di as txt "    AR(`arfe') of u^2 with vs without unit intercepts" _col(52) "F(" as res `FE'[1,2] as txt "," as res `FE'[1,3] as txt ") = " as res %8.3f `FE'[1,1] _col(71) as txt " p = " as res %5.3f `FE'[1,4]
    di as txt _col(52) "chi2(" as res `FE'[1,2] as txt ")  = " as res %8.3f `FE'[1,5] _col(71) as txt " p = " as res %5.3f `FE'[1,6]
    if "`xs'" == "" {
        di as txt "    LR groupwise heteroskedasticity" _col(52) "chi2(" as res `XS'[1,2] as txt ")  = " as res %8.3f `XS'[1,1] _col(71) as txt " p = " as res %5.3f `XS'[1,3]
        di as txt "{hline 78}"
        di as txt "[4] Cross-sectional correlation of `rtype' residuals"
        di as txt "    LR test, H0: Sigma diagonal" _col(52) "chi2(" as res `XS'[2,2] as txt ") = " as res %8.3f `XS'[2,1] _col(71) as txt " p = " as res %5.3f `XS'[2,3]
        di as txt "    Breusch-Pagan LM" _col(52) "chi2(" as res `XS'[3,2] as txt ") = " as res %8.3f `XS'[3,1] _col(71) as txt " p = " as res %5.3f `XS'[3,3]
        di as txt "    Pesaran CD" _col(52) "N(0,1)   = " as res %8.3f `XS'[4,1] _col(71) as txt " p = " as res %5.3f `XS'[4,3]
        di as txt "{hline 78}"
        di as txt "[5] Cross products u_it*u_jt: pooled AR(`cplags')"
        forvalues k = 1/`cplags' {
            di as txt "    lag `k'" _col(20) "coef = " as res %9.4f `CP'[`k',1] as txt "   t = " as res %8.3f `CP'[`k',2] as txt "   p = " as res %6.4f `CP'[`k',3]
        }
        capture confirm matrix `CPFE'
        if _rc == 0 {
            di as txt "    pair-specific intercepts" _col(52) "F(" as res `CPFE'[1,2] as txt "," as res `CPFE'[1,3] as txt ") = " as res %8.3f `CPFE'[1,1] _col(71) as txt " p = " as res %5.3f `CPFE'[1,4]
        }
    }
    di as txt "{hline 78}"

    // ---------------- recommendation -------------------------------------
    local vfe = (`FE'[1, 4] < `siglevel')
    if "`xs'" == "" {
        if `XS'[1, 3] < `siglevel' local vfe 1
    }
    local mdl "A"
    if `usefe' & !`vfe' local mdl "B"
    if !`usefe' & `vfe' local mdl "C"
    if `usefe' & `vfe' local mdl "D"
    local vspec "arch(1)"
    if `nsig' > 1 local vspec "arch(1) garch(1)"
    if `nsig' == 0 local vspec "none detected"
    local cvspec "none"
    if "`xs'" == "" {
        if `XS'[2, 3] < `siglevel' {
            local cvspec "common"
            capture confirm matrix `CPFE'
            if _rc == 0 {
                if `CPFE'[1, 4] < `siglevel' local cvspec "pair"
            }
        }
    }
    di as txt "Suggested starting specification (informal, CG 2006 p. 266):"
    di as txt "  model(" as res "`mdl'" as txt ")  variance: " as res "`vspec'" as txt "  cov(" as res "`cvspec'" as txt ")"
    di as txt "  Significant PACs of u^2 at `=100*`siglevel''%: " as res `nsig' as txt " of `lags'"
    di as txt "  CG (2006) stress that several ML specifications should still be compared (LR tests)."
    di as txt "{hline 78}"

    return scalar N = `N'
    return scalar T = `T'
    return scalar wald_mu = `Wmu'
    return scalar wald_mu_df = `Wdf'
    return scalar wald_mu_p = `Wp'
    return scalar haclags = `haclags'
    return scalar F_varfe = `FE'[1, 1]
    return scalar p_varfe = `FE'[1, 4]
    return scalar chi2_varfe = `FE'[1, 5]
    return scalar n_sig_pac = `nsig'
    if "`xs'" == "" {
        return scalar lr_grouphet = `XS'[1, 1]
        return scalar p_grouphet = `XS'[1, 3]
        return scalar lr_xcorr = `XS'[2, 1]
        return scalar p_xcorr = `XS'[2, 3]
        return scalar lm_bp = `XS'[3, 1]
        return scalar p_bp = `XS'[3, 3]
        return scalar cd = `XS'[4, 1]
        return scalar p_cd = `XS'[4, 3]
        return matrix crossprod_ar = `CP'
    }
    return local residuals "`rtype'"
    return local suggest_model "`mdl'"
    return local suggest_var "`vspec'"
    return local suggest_cov "`cvspec'"
    return matrix pac = `PAC'
    return matrix lmarch = `LM'
end
