*! xtpanelgarch_cluster 1.0.0  06nov2026
*! Bauwens & Rombouts (2007) Bayesian clustering of many GARCH models
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Bauwens and Rombouts 2007, Econometric Reviews 26: 365-386)
*   model        finite mixture of G GARCH(1,1) groups, eqs.(1)-(3), (29)-(31); variance targeting w_j
*   prior        Dirichlet(a0) on eta (15); independent uniforms on (alpha_g, beta_g) truncated to
*                alpha + beta < 1 (trapezium), separated supports identify the labels (sec. 3.4, 5.1)
*   Gibbs        S_j | eta, theta: eq.(13); eta | S: Dirichlet(a0 + x) eq.(14)-(15);
*                theta_g | S, y: griddy-Gibbs on alpha_g | beta_g and beta_g | alpha_g, eqs.(16)-(17)
*   choice of G  log marginal likelihood by Chib (1995), eq.(28): ordinate of eta* from
*                re-simulated allocations (23); ordinate of theta* from a reduced run at eta* (24),
*                with m(y_g) by 2-D quadrature over the trapezium (25)-(27)

program define xtpanelgarch_cluster, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "cluster") error 301
        _xtpg_br_display `0'
        exit
    }
    syntax varname(ts) [if] [in] , Groups(integer) [ ALPHAprior(numlist) BETAprior(numlist) ///
        DIRichlet(real 2) BURN(integer 500) DRAWs(integer 2000) GRID(integer 33) SEED(integer 12345) ///
        MARGlik MLREPS(integer 200) DEMEAN noLOG Level(cilevel) ]
    if `groups' < 1 {
        di as err "groups() must be at least 1"
        exit 198
    }
    local G = `groups'
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
    local yorig "`varlist'"
    tsrevar `varlist'
    local y "`r(varlist)'"
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch cluster"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    tempvar yy
    if "`demean'" != "" {
        qui by `ivar': egen double `yy' = mean(`y') if `touse'
        qui replace `yy' = `y' - `yy'
    }
    else qui gen double `yy' = `y' if `touse'
    tempname Y PR A0
    mata: _xtpg_getE("`yy'", "`touse'", `N', "`Y'")
    // prior supports
    local na : word count `alphaprior'
    local nb : word count `betaprior'
    local auto 0
    if `na' == 0 | `nb' == 0 local auto 1
    if !`auto' & (`na' != 2 * `G' | `nb' != 2 * `G') {
        di as err "alphaprior() and betaprior() need 2 x groups() numbers: lo1 hi1 lo2 hi2 ..."
        exit 198
    }
    if `auto' {
        di as txt "(no prior supports given: separating the alpha supports at quantiles of series-by-series estimates)"
        mata: _xtpg_br_auto("`Y'", `G', "`PR'")
    }
    else {
        matrix `PR' = J(`G', 4, .)
        forvalues g = 1/`G' {
            matrix `PR'[`g', 1] = real(word("`alphaprior'", 2 * `g' - 1))
            matrix `PR'[`g', 2] = real(word("`alphaprior'", 2 * `g'))
            matrix `PR'[`g', 3] = real(word("`betaprior'", 2 * `g' - 1))
            matrix `PR'[`g', 4] = real(word("`betaprior'", 2 * `g'))
        }
    }
    matrix `A0' = J(1, `G', `dirichlet')
    if `showlog' di as txt _n "Gibbs sampler: burn-in `burn', kept draws `draws', griddy-Gibbs grid `grid'"
    mata: _xtpg_br_fit("`Y'", `G', "`PR'", "`A0'", `burn', `draws', `grid', `seed', ("`marglik'" != ""), `mlreps', `showlog')

    tempname ETA TH b V AL
    matrix `ETA' = __xtpg_eta
    matrix `TH' = __xtpg_th
    matrix `AL' = __xtpg_alloc
    mata: _xtpg_br_post("`ETA'", "`TH'", "`b'", "`V'")
    local names ""
    forvalues g = 1/`G' {
        local names "`names' eta:g`g'"
    }
    forvalues g = 1/`G' {
        local names "`names' alpha:g`g'"
    }
    forvalues g = 1/`G' {
        local names "`names' beta:g`g'"
    }
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local cn ""
    forvalues g = 1/`G' {
        local cn "`cn' g`g'"
    }
    matrix colnames `AL' = `cn'
    matrix rownames `AL' = `units'
    matrix colnames `PR' = alpha_lo alpha_hi beta_lo beta_hi
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar groups = `G'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar burn = `burn'
    ereturn scalar draws = `draws'
    ereturn scalar seed = `seed'
    if "`marglik'" != "" {
        ereturn scalar lnml = scalar(__xtpg_lnml)
        ereturn matrix lnml_parts = __xtpg_mlparts
    }
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "cluster"
    ereturn local title "Bayesian clustering of GARCH models (Bauwens-Rombouts)"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix prior = `PR'
    ereturn matrix alloc = `AL'
    ereturn matrix draws_eta = `ETA'
    ereturn matrix draws_theta = `TH'
    ereturn matrix omega = __xtpg_om
    capture scalar drop __xtpg_lnml
    _xtpg_br_display, level(`level')
end

program define _xtpg_br_display, rclass
    syntax [, Level(cilevel)]
    local G = e(groups)
    di _n as txt "`e(title)'"
    di as txt _col(52) "Number of series" _col(68) "=" as res %9.0f e(N_g)
    di as txt "Gibbs + griddy-Gibbs, variance targeting" _col(52) "Time periods" _col(68) "=" as res %9.0f e(T)
    di as txt "Groups G = " as res `G' as txt ", burn-in " as res e(burn) as txt ", draws " as res e(draws) _col(52) as txt "Seed" _col(68) "=" as res %9.0f e(seed)
    tempname E TH P AL
    matrix `E' = e(draws_eta)
    matrix `TH' = e(draws_theta)
    matrix `P' = e(prior)
    matrix `AL' = e(alloc)
    local lo = (100 - `level') / 200
    local hi = 1 - `lo'
    di as txt "{hline 78}"
    di as txt _col(3) "group" _col(12) "parameter" _col(27) "post. mean" _col(40) "post. sd" _col(52) "[`level'% cred. interval]" _col(71) "prior"
    di as txt "{hline 78}"
    forvalues g = 1/`G' {
        mata: _xtpg_br_summ("`E'", `g', `lo', `hi')
        di as txt _col(4) "g`g'" _col(12) "eta" as res _col(26) %10.4f r(m) _col(38) %9.4f r(s) _col(50) %9.4f r(l) %10.4f r(u)
        mata: _xtpg_br_summ("`TH'", `g', `lo', `hi')
        di as txt _col(12) "alpha" as res _col(26) %10.4f r(m) _col(38) %9.4f r(s) _col(50) %9.4f r(l) %10.4f r(u) as txt _col(70) "[" %4.3f `P'[`g',1] "," %4.3f `P'[`g',2] "]"
        mata: _xtpg_br_summ("`TH'", `G' + `g', `lo', `hi')
        di as txt _col(12) "beta" as res _col(26) %10.4f r(m) _col(38) %9.4f r(s) _col(50) %9.4f r(l) %10.4f r(u) as txt _col(70) "[" %4.3f `P'[`g',3] "," %4.3f `P'[`g',4] "]"
        mata: _xtpg_br_nmap("`AL'", `g')
        di as txt _col(12) "series allocated (MAP)" _col(38) as res %9.0f r(n)
        di as txt "{hline 78}"
    }
    capture confirm scalar e(lnml)
    if _rc == 0 {
        di as txt "  log marginal likelihood (Chib 1995, eq. 28) = " as res %14.4f e(lnml)
        di as txt "  compare across groups() and choose the largest (sec. 4)"
    }
    else di as txt "  add {bf:marglik} to compute the log marginal likelihood used to choose G"
    di as txt "  P(S_j = g | y) for each series: matrix list e(alloc)"
end
