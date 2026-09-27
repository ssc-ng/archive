*! cointvol_stoch 0.1.0  26sep2026
*! Stochastic cointegration: AIV estimation with HAC inference and residual-based
*! tests of stochastic / heteroskedastic cointegration and heteroskedastic integration
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_stoch.sthlp, section Methods):
*!   AIV b_k = (sum X_{t-k}X_t')^-1 sum X_{t-k}y_t, X_t = (x_t', [t], 1)'
*!       -> Harris, McCabe & Leybourne (2002) eq (6) (IV form); MLH (2006) eq (7)
*!   Sigma_k = T (sum X_{t-k}X_t')^-1 Omega(X_{t-k}u_t) (sum X_t X_{t-k}')^-1
*!       -> HML (2002) eq (9), Theorem 4; Bartlett lambda(j/l), l = ceil(T^1/3) < k
*!   t = (b_i - b_i0)/sqrt((Sigma_k)_ii)
*!       -> HML (2002) eq (10), printed (Sigma_k^-1)_ii corrected (Theorem 4)
*!   residuals u_t for all t -> MLH (2006) eq (8)
*!   S_nc -> MLH Thm 1; S_hc (sqrt(12), corrected) -> MLH Thm 2; S_hi -> MLH Sec 3.2
*!   omega^2(a) = g0 + 2 sum lambda(j/l) g_j, g_j not demeaned -> MLH eq (5)
*!   l fixed = [12(T/100)^1/4] or Newey-West (1994) automatic; l < k enforced

program define cointvol_stoch, eclass
    version 14.0

    // ---------------- load / reload the Mata engine ----------------------
    capture mata: st_local("__cvsv", cvs_version())
    if _rc {
        capture program drop cointvol_eng_stoch
        quietly findfile cointvol_eng_stoch.ado
        quietly run `"`r(fn)'"'
    }

    if replay() {
        if `"`e(cmd)'"' != "cointvol stoch" {
            error 301
        }
        syntax [, LEVel(cilevel)]
        _cvs_stoch_display, level(`level')
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] [,          ///
        Estimator(string) k(integer 0) KTest(integer 0)    ///
        l(string) LTest(string) TRend TESTs(string)        ///
        NOTESTs LEVel(cilevel) ]

    local cmdline `"cointvol stoch `0'"'

    // ---------------- options --------------------------------------------
    local estimator = strlower(strtrim(`"`estimator'"'))
    if `"`estimator'"' == "" local estimator "aiv"
    if !inlist(`"`estimator'"', "aiv", "ols") {
        di as err "estimator() must be aiv or ols"
        exit 198
    }
    local dotests = ("`notests'" == "")
    local tests = strlower(strtrim(`"`tests'"'))
    if `"`tests'"' == "" local tests "snc shc shi"
    foreach t of local tests {
        if !inlist("`t'", "snc", "shc", "shi") {
            di as err "tests() may contain snc, shc and shi only"
            exit 198
        }
    }
    local do_snc : list posof "snc" in tests
    local do_shc : list posof "shc" in tests
    local do_shi : list posof "shi" in tests
    local dotrend = ("`trend'" != "")

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol stoch requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local T = r(N)
    if `T' < 20 {
        di as err "too few observations (" `T' "); at least 20 are required"
        exit 2001
    }
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `T' {
        di as err "the estimation sample contains gaps; cointvol stoch needs consecutive observations"
        exit 498
    }

    gettoken depvar indepvars : varlist
    local nx : word count `indepvars'
    local K = `nx' + 1 + `dotrend'

    // ---------------- tuning parameters ----------------------------------
    // k: HML (2002) Monte Carlo rule k = ceil(T^1/2)
    local kuser = (`k' != 0)
    if `k' == 0 {
        local k = ceil(sqrt(`T') - 1e-9)
    }
    if `k' < 1 {
        di as err "k() must be a positive integer"
        exit 198
    }
    // ktest: MLH (2006) recommended k = [T^1/2]; equals k() when k() is given
    if `ktest' == 0 {
        if `kuser' {
            local ktest = `k'
        }
        else {
            local ktest = floor(sqrt(`T') + 1e-9)
        }
    }
    if `dotests' & `ktest' < 2 {
        di as err "ktest() must be at least 2 (the tests need 1 <= l < k)"
        exit 198
    }
    foreach kk in k ktest {
        if `T' - ``kk'' < `K' + 10 {
            di as err "`kk'() = ``kk'' leaves too few observations for the instrument (T = `T')"
            exit 2001
        }
    }

    // l: HAC truncation for the estimator covariance (HML: l = ceil(T^1/3))
    local l = strlower(strtrim(`"`l'"'))
    local lrule "fixed"
    local lsrc "default"
    local lnote ""
    if `"`l'"' == "" {
        local lval = ceil(`T'^(1/3) - 1e-9)
        if "`estimator'" == "aiv" & `lval' >= `k' {
            local lval = `k' - 1
            local lnote "default l reduced to k-1 = `lval' to satisfy l < k"
        }
    }
    else if `"`l'"' == "nw" {
        local lrule "nw"
        local lsrc "nw"
        local lval = .
    }
    else {
        capture confirm integer number `l'
        if _rc | real(`"`l'"') < 0 {
            di as err "l() must be a nonnegative integer or nw"
            exit 198
        }
        local lval = real(`"`l'"')
        local lsrc "user"
        if "`estimator'" == "aiv" & `lval' >= `k' {
            di as err "l() must be smaller than k() (HML 2002, Assumption KN: l = o(k))"
            exit 198
        }
    }

    // ltest: truncation for the residual tests
    local ltest = strlower(strtrim(`"`ltest'"'))
    local ltrule "fixed"
    if `"`ltest'"' == "" | `"`ltest'"' == "fixed" {
        local ltval = floor(12*(`T'/100)^0.25 + 1e-9)
        local ltlab "fixed [12(T/100)^(1/4)]"
    }
    else if `"`ltest'"' == "nw" {
        local ltrule "nw"
        local ltval = floor(12*(`T'/100)^0.25 + 1e-9)
        local ltlab "Newey-West (1994) automatic"
    }
    else {
        capture confirm integer number `ltest'
        if _rc | real(`"`ltest'"') < 1 {
            di as err "ltest() must be a positive integer, fixed or nw"
            exit 198
        }
        local ltval = real(`"`ltest'"')
        local ltrule "user"
        local ltlab "user-specified"
    }
    local ltmode "`ltrule'"
    if "`ltmode'" == "user" local ltmode "fixed"

    // ---------------- ts operators -> temporary variables -----------------
    tsrevar `depvar'
    local ydat "`r(varlist)'"
    tsrevar `indepvars'
    local xdat "`r(varlist)'"
    local hivars "`ydat' `xdat'"
    local hinames "`depvar' `indepvars'"

    mata: cvs_stoch_main("`ydat'", "`xdat'", "`touse'", `dotrend', "`estimator'", ///
        `k', `lval', "`lrule'", `dotests', `ktest', `ltval', "`ltmode'", "`hivars'")

    tempname b V tst
    matrix `b' = __cvs_b
    matrix `V' = __cvs_V
    local Neff = scalar(__cvs_Neff)
    local lused = scalar(__cvs_l)
    local ladj = scalar(__cvs_ladj)
    local s2 = scalar(__cvs_s2)
    if `dotests' {
        matrix `tst' = __cvs_tests
    }
    capture matrix drop __cvs_b __cvs_V __cvs_tests
    capture scalar drop __cvs_T __cvs_Neff __cvs_l __cvs_ladj __cvs_s2
    if `ladj' {
        local lnote "Newey-West l reduced to k-1 = `lused' to satisfy l < k"
    }

    // coefficient names
    local cn "`indepvars'"
    if `dotrend' local cn "`cn' _trend"
    local cn "`cn' _cons"
    matrix colnames `b' = `cn'
    matrix colnames `V' = `cn'
    matrix rownames `V' = `cn'

    // tests matrix: keep requested rows
    if `dotests' {
        local rn "S_nc S_hc"
        foreach v of local hinames {
            local nm = substr(strtoname("S_hi_`v'"), 1, 32)
            local rn "`rn' `nm'"
        }
        matrix colnames `tst' = stat pvalue k l l_adjusted
        matrix rownames `tst' = `rn'
    }

    // ---------------- post -----------------------------------------------
    local trendlab "none"
    if `dotrend' local trendlab "trend"
    local testlab ""
    if `dotests' local testlab "`tests'"
    ereturn post `b' `V', esample(`touse') depname(`depvar') obs(`T')
    capture qui test `indepvars'
    if !_rc {
        ereturn scalar chi2 = r(chi2)
        ereturn scalar df_m = r(df)
        ereturn scalar p    = r(p)
    }
    ereturn scalar N_eff  = `Neff'
    ereturn scalar k      = `k'
    ereturn scalar l      = `lused'
    ereturn scalar k_test = `ktest'
    ereturn scalar l_test = `ltval'
    ereturn scalar sigma2 = `s2'
    ereturn scalar level  = `level'
    ereturn scalar tmin   = `tmin'
    ereturn scalar tmax   = `tmax'
    ereturn scalar tdelta = `tdelta'
    if `dotests' {
        local nt = rowsof(`tst')
        if `do_snc' {
            ereturn scalar S_nc = `tst'[1,1]
            ereturn scalar p_nc = `tst'[1,2]
            ereturn scalar l_nc = `tst'[1,4]
        }
        if `do_shc' {
            ereturn scalar S_hc = `tst'[2,1]
            ereturn scalar p_hc = `tst'[2,2]
            ereturn scalar l_hc = `tst'[2,4]
        }
        if `do_shi' {
            ereturn scalar S_hi = `tst'[3,1]
            ereturn scalar p_hi = `tst'[3,2]
            ereturn scalar l_hi = `tst'[3,4]
        }
    }
    ereturn local cmd        "cointvol stoch"
    ereturn local cmdline    `"`cmdline'"'
    ereturn local title      "Stochastic cointegration regression"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local estimator  "`estimator'"
    ereturn local trend      "`trendlab'"
    ereturn local vce        "hac"
    ereturn local vcetype    "HAC"
    ereturn local kernel     "bartlett"
    ereturn local lrule      "`lsrc'"
    ereturn local ltestrule  "`ltrule'"
    ereturn local lnote      "`lnote'"
    ereturn local testlist   "`testlab'"
    ereturn local timevar    "`tvar'"
    ereturn local properties "b V"
    ereturn local predict    "cointvol_stoch_p"
    if `dotests' {
        ereturn matrix tests = `tst'
    }

    _cvs_stoch_display, level(`level')
end

// ---------------------------------------------------------------------------
program define _cvs_stoch_display
    version 14.0
    syntax [, LEVel(cilevel)]

    local est "`e(estimator)'"
    if "`est'" == "aiv" {
        local ttl "AIV estimation of a stochastically cointegrating regression"
    }
    else {
        local ttl "OLS estimation of a cointegrating regression (comparison)"
    }
    local tlab "constant"
    if "`e(trend)'" == "trend" local tlab "constant + linear trend"
    local lrl "T^(1/3) rule"
    if "`e(lrule)'" == "nw"   local lrl "NW 1994 auto"
    if "`e(lrule)'" == "user" local lrl "user"

    di
    di as txt "`ttl'"
    di as txt "{hline 78}"
    di as txt "Dependent variable: " as res "`e(depvar)'" as txt _col(52) "Number of obs  = " as res %9.0f e(N)
    if "`est'" == "aiv" {
        di as txt "Instrument: X(t-k), k = " as res e(k) as txt _col(52) "Effective obs  = " as res %9.0f e(N_eff)
    }
    else {
        di as txt "Instrument: none (OLS)" as txt _col(52) "Effective obs  = " as res %9.0f e(N_eff)
    }
    di as txt "Deterministics: " as res "`tlab'" as txt _col(52) "Wald chi2(" as res e(df_m) as txt ")   = " ///
        as res %9.2f e(chi2)
    di as txt "HAC: Bartlett, l = " as res e(l) as txt " (`lrl')" _col(52) "Prob > chi2    = " ///
        as res %9.4f e(p)
    di
    ereturn display, level(`level')
    di as txt "Std. errors: sqrt of diag(Sigma_k), Sigma_k = T(sum Z X')^-1 Omega(Z u)(sum X Z')^-1"
    di as txt "  (HML 2002, Theorem 4; the (Sigma_k^-1)_ii printed in their eq. 10 is a misprint)."
    if "`est'" == "aiv" {
        di as txt "Note: _cons is not consistent under heteroskedastic cointegration (HML 2002, Thm 2);"
        di as txt "      its t-ratio is asymptotically N(0,1) but has no power. Keep it in the model."
    }
    else {
        di as txt "Note: OLS is inconsistent when a regressor is heteroskedastically integrated"
        di as txt "      (HML 2002, Thm 1). Reported for comparison only; prefer estimator(aiv)."
    }
    if `"`e(lnote)'"' != "" {
        di as txt "Note: `e(lnote)'."
    }

    if `"`e(testlist)'"' == "" {
        exit
    }
    tempname T
    matrix `T' = e(tests)
    local eta = 1 - `level'/100
    local lev : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local tests "`e(testlist)'"
    local names "`e(depvar)' `e(indepvars)'"
    local nr = rowsof(`T')

    di
    di as txt "Residual-based tests on AIV residuals (McCabe, Leybourne & Harris 2006)"
    di as txt "{hline 26}{c TT}{hline 51}"
    di as txt " Test" _col(27) "{c |}" _col(29) "H0" _col(52) "Statistic" _col(63) "p-value" ///
        _col(72) "k" _col(76) "l"
    di as txt "{hline 26}{c +}{hline 51}"
    local anyadj 0
    forvalues i = 1/`nr' {
        local show 0
        if `i' == 1 {
            local show : list posof "snc" in tests
            local lab " S_nc"
            local h0 "stochastic coint."
        }
        else if `i' == 2 {
            local show : list posof "shc" in tests
            local lab " S_hc"
            local h0 "stationary coint."
        }
        else {
            local show : list posof "shi" in tests
            local j = `i' - 2
            local v : word `j' of `names'
            local v = abbrev("`v'", 16)
            local lab " S_hi: `v'"
            local h0 "I(1)"
        }
        if `show' == 0 {
            continue
        }
        local st = `T'[`i', 1]
        local pv = `T'[`i', 2]
        local kk = `T'[`i', 3]
        local ll = `T'[`i', 4]
        local aj = `T'[`i', 5]
        if `aj' == 1 local anyadj 1
        local star " "
        if `pv' < `eta' local star "*"
        local kd "  ."
        if `kk' < . local kd : display %3.0f `kk'
        local ad " "
        if `aj' == 1 local ad "a"
        di as txt "`lab'" _col(27) "{c |}" _col(29) "`h0'" as res _col(50) %10.3f `st' ///
            _col(62) %7.3f `pv' as txt "`star'" _col(70) "`kd'" as res _col(74) %3.0f `ll' as txt "`ad'"
    }
    di as txt "{hline 26}{c BT}{hline 51}"
    di as txt "* rejects H0 at the `lev'% level; all statistics N(0,1) under H0, two-sided p-values."
    di as txt "S_nc: H0 stochastic cointegration (stationary or heteroskedastic) vs no cointegration."
    di as txt "S_hc: H0 stationary cointegration vs heteroskedastic cointegration (sqrt(12) scaling)."
    di as txt "S_hi: H0 I(1) vs heteroskedastic integration, on Delta of each series."
    di as txt "Bartlett kernel, l: `e(ltestrule)' rule (l < k enforced for S_nc and S_hc)."
    if `anyadj' {
        di as txt "a: l reduced to k - 1 to satisfy l < k (MLH 2006, Theorem 1)."
    }
end
