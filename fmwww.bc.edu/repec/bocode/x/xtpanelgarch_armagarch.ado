*! xtpanelgarch_armagarch 1.0.0  06nov2026
*! Su & Zhu (2024) panel ARMA-GARCH model when both N and T are large
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Su and Zhu 2024, arXiv:2404.18377)
*   model         eq.(2.1a)-(2.1b); VT reparameterisation eq.(2.6)
*   step 1        concentrated LS: mu-hat(lambda) eq.(2.4), Q_lambda eq.(2.5),
*                 presample y = u = 0 (eq. 2.2)
*   step 2        w_i-hat = T^-1 sum u_it^2, VT-QML eq.(2.9), varpi_i = w_i (1 - sum tau - sum nu)
*                 presample u^2 = h = w_i-hat (authors' code: h_i1 = w_i-hat)
*   Var(lambda)   sandwich on concentrated residuals (Thm 4.1 under MDS errors)
*   Var(zeta)     Gamma2^-1 Omega2 Gamma2^-1 with w-hat and lambda-hat estimation effects (Thm 4.4)
*   unit effects  mu_i (Thm 4.2), w_i and varpi_i (Thm 4.5)
*   bias          half-panel jackknife: lambda eq.(4.4); zeta eq.(4.11) using lambda_J residuals,
*                 w re-estimated in each half (authors' code)

program define xtpanelgarch_armagarch, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "armagarch") error 301
        _xtpg_ag_display `0'
        exit
    }
    syntax varlist(ts min=1) [if] [in] , [ AR(integer 1) MA(integer 1) ARCH(integer 1) ///
        GARCH(integer 1) BIAS(string) Level(cilevel) noTABle ]
    if `ar' < 0 | `ma' < 0 | `arch' < 1 | `garch' < 0 {
        di as err "need ar() >= 0, ma() >= 0, arch() >= 1, garch() >= 0"
        exit 198
    }
    if "`bias'" == "" local bias "none"
    local bias = lower("`bias'")
    if !inlist("`bias'", "none", "jackknife", "jk") {
        di as err "bias() must be none or jackknife"
        exit 198
    }
    if "`bias'" == "jk" local bias "jackknife"
    local jack = ("`bias'" == "jackknife")
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
    if "`xorig'" != "" tsunab xorig : `xorig'
    tsrevar `varlist'
    local tsv "`r(varlist)'"
    gettoken y xv : tsv
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch armagarch"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    if `T' < 2 * (`ar' + `ma' + 10) & `jack' {
        di as err "T too small for the half-panel jackknife"
        exit 2001
    }

    // starting values: LSDV of y on x and y lags, MA = 0
    tempname lam0
    local lagl ""
    forvalues p = 1/`ar' {
        tempvar yl`p'
        qui by `ivar': gen double `yl`p'' = L`p'.`y' if `touse'
        local lagl "`lagl' `yl`p''"
    }
    capture qui regress `y' `xv' `lagl' i.`ivar' if `touse'
    foreach v of local xv {
        local bv 0
        capture local bv = _b[`v']
        matrix `lam0' = (nullmat(`lam0'), `bv')
    }
    forvalues p = 1/`ar' {
        local bv 0.1
        capture local bv = _b[`yl`p'']
        if abs(`bv') >= 0.95 local bv = 0.5 * sign(`bv')
        matrix `lam0' = (nullmat(`lam0'), `bv')
    }
    forvalues q = 1/`ma' {
        matrix `lam0' = (nullmat(`lam0'), 0)
    }

    di as txt _n "Su-Zhu panel ARMA(`ar',`ma')-GARCH(`garch',`arch'): step 1 (concentrated LS), step 2 (VT-QML)"
    mata: _xtpg_ag_fit("`y'", "`xv'", "`touse'", `N', `T', `ar', `ma', `arch', `garch', "`lam0'", `jack')

    local names ""
    foreach v of local xorig {
        local names "`names' mean:`v'"
    }
    forvalues p = 1/`ar' {
        local names "`names' ARMA:L`p'.ar"
    }
    forvalues q = 1/`ma' {
        local names "`names' ARMA:L`q'.ma"
    }
    forvalues l = 1/`arch' {
        local names "`names' variance:L`l'.arch"
    }
    forvalues l = 1/`garch' {
        local names "`names' variance:L`l'.garch"
    }
    tempname b V Z Vl Vz bnobc
    matrix `Vl' = __xtpg_Vl
    matrix `Vz' = __xtpg_Vz
    matrix `bnobc' = (__xtpg_lam, __xtpg_zeta)
    if `jack' matrix `b' = (__xtpg_lamJ, __xtpg_zetaJ)
    else matrix `b' = `bnobc'
    matrix `Z' = J(colsof(`Vl'), colsof(`Vz'), 0)
    matrix `V' = (`Vl', `Z' \ `Z'', `Vz')
    matrix colnames `b' = `names'
    matrix colnames `bnobc' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    tempname MU OM VP
    matrix `MU' = __xtpg_MU
    matrix `OM' = __xtpg_OM
    matrix `VP' = __xtpg_VP
    matrix colnames `MU' = mu se
    matrix colnames `OM' = omega se
    matrix colnames `VP' = varpi se
    matrix rownames `MU' = `units'
    matrix rownames `OM' = `units'
    matrix rownames `VP' = `units'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar ll = scalar(__xtpg_ll)
    ereturn scalar Q_ls = scalar(__xtpg_Qls)
    ereturn scalar kappa = scalar(__xtpg_kappa)
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar ar = `ar'
    ereturn scalar ma = `ma'
    ereturn scalar arch = `arch'
    ereturn scalar garch = `garch'
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "armagarch"
    ereturn local title "Su-Zhu panel ARMA-GARCH"
    ereturn local bias "`bias'"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local xvars "`xorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local vcetype "Sandwich"
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix b_nobias = `bnobc'
    ereturn matrix mu = `MU'
    ereturn matrix omega = `OM'
    ereturn matrix varpi = `VP'
    ereturn matrix sigma2 = __xtpg_S2
    ereturn matrix resid = __xtpg_U
    if `jack' ereturn matrix halves = __xtpg_halves
    capture matrix drop __xtpg_lam __xtpg_zeta __xtpg_Vl __xtpg_Vz __xtpg_lamJ __xtpg_zetaJ __xtpg_muJ
    capture scalar drop __xtpg_ll __xtpg_Qls __xtpg_kappa
    _xtpg_ag_display, level(`level') `table'
end

program define _xtpg_ag_display
    syntax [, Level(cilevel) noTABle]
    di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "=" as res %10.0fc e(N)
    di as txt "ARMA(`e(ar)',`e(ma)') mean with fixed effects mu_i" _col(49) "Number of panels" _col(67) "=" as res %10.0f e(N_g)
    di as txt "GARCH(`e(garch)',`e(arch)') variance with fixed effects w_i" _col(49) "Time periods" _col(67) "=" as res %10.0f e(T)
    di as txt "Bias correction: " as res cond("`e(bias)'" == "jackknife", "half-panel jackknife (4.4), (4.11)", "none") ///
        _col(49) as txt "N/T" _col(67) "=" as res %10.3f e(N_g) / e(T)
    di as txt "Quasi log likelihood (2.8) = " as res %14.4f e(ll)
    if "`table'" == "" ereturn display, level(`level')
    tempname b V a
    matrix `b' = e(b)
    matrix `V' = e(V)
    local np = colsof(`b')
    local cn : colfullnames `b'
    matrix `a' = J(1, `np', 0)
    local j 0
    foreach c of local cn {
        local ++j
        if substr("`c'", 1, 10) == "variance:L" matrix `a'[1, `j'] = 1
    }
    mata: _xtpg_lincom("`b'", "`V'", "`a'")
    di as txt "{hline 78}"
    di as txt "  variance persistence (Σtau+Σnu)" _col(37) as res %11.4f scalar(__xtpg_lc) _col(51) %11.4f scalar(__xtpg_lcse) ///
        _col(63) %9.2f (scalar(__xtpg_lc) - 1) / scalar(__xtpg_lcse) as txt " (H0:=1)"
    di as txt "  kurtosis of standardized residuals" _col(37) as res %11.3f e(kappa)
    di as txt "  unit effects mu_i, w_i, varpi_i with SEs:  matrix list e(mu), e(omega), e(varpi)"
    di as txt "  SEs: sqrt(NT) sandwich (Thms 4.1, 4.4); the estimates are biased of order 1/T when N/T > 0"
    if "`e(bias)'" == "none" di as txt "  (use bias(jackknife) to remove it; Thms 4.3, 4.6)"
    di as txt "{hline 78}"
    capture scalar drop __xtpg_lc __xtpg_lcse
end
