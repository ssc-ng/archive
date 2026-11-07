*! xtpanelgarch_hgarch 1.0.0  06nov2026
*! Brownlees (2019) Hierarchical GARCH
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Brownlees 2019, Journal of Empirical Finance 51: 17-27)
*   level I      r_it = b_i rF_t + e_it,  e_it ~ N(0, h_it)                          eq.(1)
*                h_it = (1-pi_i) h_i + pi_i [lambda_i e2_i,t-1 + (1-lambda_i) h_i,t-1] eq.(2)
*   level II     b_i, ln h_i, Phi^-1(lambda_i), Phi^-1(pi_i) = delta'x_i + u, u ~ N(0, tau^2)  eqs.(3)-(6)
*   estimation   simulated ML of the marginal likelihood, common draws, log-sum-exp form  eqs.(7)-(9)
*   coefficients E(g_i | data) with importance weights w_is                           eqs.(10)-(12)
*   start values naive estimator: series-by-series ML, then OLS of level II            sec. 3
* Decision: presample h_i0 = e2_i0 = h_i (the unconditional variance); the paper does not state it.

program define xtpanelgarch_hgarch, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "hgarch") error 301
        _xtpg_hg_display `0'
        exit
    }
    syntax varname(ts) [if] [in] , CHARacteristics(varlist numeric) [ FACtor(varname ts) ///
        DRAWs(integer 100) SEED(integer 12345) FIXPi(real -1) VCE(string) noLOG Level(cilevel) noTABle ]
    if `draws' < 10 {
        di as err "draws() must be at least 10"
        exit 198
    }
    local fixp = (`fixpi' > 0 & `fixpi' < 1)
    if `fixpi' != -1 & !`fixp' {
        di as err "fixpi() must lie in (0,1)"
        exit 198
    }
    if "`vce'" == "" local vce "oim"
    local vce = lower("`vce'")
    if !inlist("`vce'", "oim", "opg", "robust") {
        di as err "vce() must be oim, opg or robust"
        exit 198
    }
    local showlog = ("`log'" == "")
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    markout `touse' `characteristics' `factor'
    local yorig "`varlist'"
    tsrevar `varlist'
    local y "`r(varlist)'"
    local f ""
    if "`factor'" != "" {
        tsrevar `factor'
        local f "`r(varlist)'"
    }
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch hgarch"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    // characteristics must be time invariant; the factor must be common across panels
    foreach v of local characteristics {
        tempvar sdv
        qui by `ivar': egen double `sdv' = sd(`v') if `touse'
        qui sum `sdv' if `touse', meanonly
        if r(max) > 1e-10 & r(max) < . {
            di as err "characteristic `v' varies over time within a panel; use a time-invariant variable"
            exit 459
        }
        drop `sdv'
    }
    tempname R X F
    mata: _xtpg_getE("`y'", "`touse'", `N', "`R'")
    if "`f'" != "" {
        tempvar sdf
        qui bysort `tvar': egen double `sdf' = sd(`f') if `touse'
        qui sum `sdf' if `touse', meanonly
        if r(max) > 1e-10 & r(max) < . {
            di as err "factor() must take the same value for all panels at each date"
            exit 459
        }
        sort `ivar' `tvar'
        mata: _xtpg_firstT("`f'", "`touse'", `T', "`F'")
    }
    sort `ivar' `tvar'
    mata: _xtpg_hg_xi("`characteristics'", "`touse'", `N', `T', "`X'")

    if `showlog' di as txt _n "Hierarchical GARCH: naive start values, then simulated ML (S = `draws' draws)"
    local pfx = cond(`fixp', `fixpi', 0.5)
    local fname ""
    if "`f'" != "" local fname "`F'"
    mata: _xtpg_hg_fit("`R'", "`X'", "`fname'", `draws', `fixp', `pfx', `seed', "`vce'", `showlog')

    // names
    local xn "`characteristics' _cons"
    local names ""
    local tn ""
    if "`f'" != "" {
        foreach v of local xn {
            local names "`names' beta:`v'"
        }
        local tn "`tn' lntau:beta"
    }
    foreach eq in lnh lambda {
        foreach v of local xn {
            local names "`names' `eq':`v'"
        }
    }
    local tn "`tn' lntau:lnh lntau:lambda"
    if !`fixp' {
        foreach v of local xn {
            local names "`names' pi:`v'"
        }
        local tn "`tn' lntau:pi"
    }
    local names "`names' `tn'"
    tempname b V C NV
    matrix `b' = __xtpg_b
    matrix `V' = __xtpg_V
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    matrix `C' = __xtpg_coef
    matrix colnames `C' = beta se_beta h se_h lambda se_lambda pi se_pi
    matrix rownames `C' = `units'
    matrix `NV' = __xtpg_naive
    matrix rownames `NV' = `units'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar ll = scalar(__xtpg_ll)
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar draws = `draws'
    ereturn scalar seed = `seed'
    ereturn scalar converged = scalar(__xtpg_conv)
    if `fixp' ereturn scalar fixpi = `fixpi'
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "hgarch"
    ereturn local title "Hierarchical GARCH (Brownlees 2019)"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local factor "`factor'"
    ereturn local characteristics "`characteristics'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local vce "`vce'"
    ereturn local vcetype = cond("`vce'" == "robust", "Robust", cond("`vce'" == "opg", "OPG", "OIM"))
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix coef = `C'
    ereturn matrix naive = `NV'
    ereturn matrix ess = __xtpg_ess
    capture matrix drop __xtpg_b __xtpg_V __xtpg_coef __xtpg_naive __xtpg_th0
    capture scalar drop __xtpg_ll __xtpg_conv
    _xtpg_hg_display, level(`level') `table'
end

program define _xtpg_hg_display
    syntax [, Level(cilevel) noTABle]
    di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "=" as res %10.0fc e(N)
    di as txt "Level II: coefficient = delta'x_i + u_i" _col(49) "Number of series" _col(67) "=" as res %10.0f e(N_g)
    di as txt "Simulated ML, draws = " as res e(draws) as txt ", seed = " as res e(seed) _col(49) as txt "Time periods" _col(67) "=" as res %10.0f e(T)
    di as txt "Simulated log likelihood (7) = " as res %14.4f e(ll)
    if "`table'" == "" ereturn display, level(`level')
    tempname C
    matrix `C' = e(coef)
    di as txt "{hline 78}"
    di as txt "Random-effect variances tau^2 and shrinkage estimates of the series coefficients"
    foreach eq in beta lnh lambda pi {
        capture local lt = _b[lntau:`eq']
        if _rc == 0 {
            di as txt "  tau^2(`eq')" _col(24) "= " as res %10.5f exp(2 * `lt')
        }
    }
    mata: st_local("mb", strofreal(_xtpg_mcolmean("`C'", 1)))
    mata: st_local("mh", strofreal(_xtpg_mcolmean("`C'", 3)))
    mata: st_local("ml", strofreal(_xtpg_mcolmean("`C'", 5)))
    mata: st_local("mp", strofreal(_xtpg_mcolmean("`C'", 7)))
    if "`e(factor)'" != "" di as txt "  mean factor loading beta_i" _col(40) "= " as res %10.4f `mb'
    di as txt "  mean unconditional variance h_i" _col(40) "= " as res %10.4g `mh'
    di as txt "  mean smoothness lambda_i = a/(a+b)" _col(40) "= " as res %10.4f `ml'
    di as txt "  mean persistence pi_i = a+b" _col(40) "= " as res %10.4f `mp'
    di as txt "  series estimates E(coef | data) and posterior s.d.: matrix list e(coef)"
    di as txt "  GARCH form: omega = h(1-pi), alpha = pi*lambda, beta = pi(1-lambda)"
    di as txt "{hline 78}"
end
