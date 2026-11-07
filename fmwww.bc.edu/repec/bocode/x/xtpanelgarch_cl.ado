*! xtpanelgarch_cl 1.0.0  06nov2026
*! Pakel, Shephard & Sheppard (2011) composite-likelihood GARCH panel
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Pakel, Shephard & Sheppard 2011, Statistica Sinica 21, 307-329)
*   model        y_it = eps_it, sigma2_it = g_i(1-a-b) + a eps2_i,t-1 + b sigma2_i,t-1   eq.(2.3)
*   nuisance     g_i-hat = T^-1 sum_t y_it^2 (method of moments)                          eq.(2.6)
*   start-up     sigma2_i0 = mean of the first floor(T^1/2) squared observations        p.309
*   estimator    m-profile composite likelihood, average over i and t                    eqs.(2.5),(2.9)
*   inference    sqrt(T): J^-1 I~ J^-1 with nuisance-corrected z_{t,N} and HAC           eq.(2.10), p.313
*   comparison   MacGyver median blend of per-series QMLE (Engle 2009)                    sec.4
* Decision: the correction term in z_{t,N} is scaled by 1/T (influence function of g_i-hat);
*           the printed formula omits it. See help xtpanelgarch_methods.

program define xtpanelgarch_cl, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "cl") error 301
        _xtpg_cl_display `0'
        exit
    }
    syntax varname(ts) [if] [in] , [ DEMEAN DISTribution(string) HACLags(integer -1) ///
        MACgyver NOCORRection Level(cilevel) noTABle ]
    if "`distribution'" == "" local distribution "normal"
    local distribution = lower("`distribution'")
    if inlist("`distribution'", "normal", "gaussian") local dst 1
    else if inlist("`distribution'", "t", "student") local dst 2
    else {
        di as err "distribution() must be normal or t"
        exit 198
    }
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    local yorig "`varlist'"
    tsrevar `varlist'
    local y "`r(varlist)'"
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch cl"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    if `haclags' < 0 local haclags = floor(4 * (`T' / 100)^(2 / 9))
    tempvar yy
    if "`demean'" != "" {
        qui by `ivar': egen double `yy' = mean(`y') if `touse'
        qui replace `yy' = `y' - `yy'
    }
    else qui gen double `yy' = `y' if `touse'
    tempname Y b V Vn MG
    mata: _xtpg_getE("`yy'", "`touse'", `N', "`Y'")
    mata: _xtpg_cl_fit("`Y'", `dst', `haclags', "`b'", "`V'", "`Vn'")
    if "`nocorrection'" != "" matrix `V' = `Vn'
    local names "variance:alpha variance:beta"
    if `dst' == 2 local names "`names' t:df"
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    matrix colnames `Vn' = `names'
    matrix rownames `Vn' = `names'
    if "`macgyver'" != "" {
        mata: _xtpg_cl_macgyver("`Y'", "`MG'")
        matrix colnames `MG' = alpha beta converged
    }
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar ll = scalar(__xtpg_ll) * `T'
    ereturn scalar cl = scalar(__xtpg_ll) / `T'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar haclags = `haclags'
    ereturn scalar converged = scalar(__xtpg_conv)
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "cl"
    ereturn local title "Composite-likelihood GARCH panel (Pakel-Shephard-Sheppard)"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local dist "`distribution'"
    ereturn local vcetype = cond("`nocorrection'" != "", "HAC", "HAC+nuis")
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix V_nocorr = `Vn'
    ereturn matrix gamma = __xtpg_gam
    ereturn matrix sigma2 = __xtpg_S2
    ereturn matrix resid = `Y'
    if "`macgyver'" != "" ereturn matrix macgyver = `MG'
    capture scalar drop __xtpg_ll __xtpg_conv
    _xtpg_cl_display, level(`level') `table'
end

program define _xtpg_cl_display
    syntax [, Level(cilevel) noTABle]
    di _n as txt "`e(title)'"
    di as txt _col(52) "Number of obs" _col(68) "=" as res %9.0fc e(N)
    di as txt "sigma2_it = g_i(1-a-b) + a y2_i,t-1 + b sigma2_i,t-1" _col(52) "Number of series" _col(68) "=" as res %9.0f e(N_g)
    di as txt "Nuisance g_i: method of moments (2.6)" _col(52) "Time periods" _col(68) "=" as res %9.0f e(T)
    di as txt "Composite log likelihood (2.5) = " as res %12.6f e(cl) _col(52) as txt "HAC lags" _col(68) "=" as res %9.0f e(haclags)
    if "`table'" == "" ereturn display, level(`level')
    di as txt "  persistence a + b = " as res %8.4f _b[variance:alpha] + _b[variance:beta] ///
        as txt "   SEs: sqrt(T) sandwich J^-1 I J^-1 (eq. 2.10), " as res "`e(vcetype)'"
    capture confirm matrix e(macgyver)
    if _rc == 0 {
        tempname M
        matrix `M' = e(macgyver)
        mata: st_local("mga", strofreal(_xtpg_mcolmed("`M'", 1)))
        mata: st_local("mgb", strofreal(_xtpg_mcolmed("`M'", 2)))
        di as txt "  MacGyver median blend of per-series QMLE (Engle 2009): alpha = " as res %8.4f `mga' as txt ", beta = " as res %8.4f `mgb'
    }
    if e(T) < 500 di as txt "  Note: Pakel et al. (2011, sec. 3.3) find incidental-parameter bias in CL when T < 500."
end
