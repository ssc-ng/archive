*! xtpanelgarch_vt 1.0.0  06nov2026
*! Asai (2023) feasible panel GARCH: three-step variance-targeting estimator
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Asai 2023, Econometrics and Statistics 25, 23-38)
*   model            eqs.(1),(2),(14); scalar-BEKK VT form, PD by Props. 1-2 / Remark 2.4
*   CCP alternative  eq.(27) (Cermeno-Sanin 2015; Ribeiro et al. 2017)
*   step 1           fixed-effects estimator eqs.(18)-(19)
*   step 2           Sigma-hat = T^-1 sum u_t u_t'                 eq.(20)
*   step 3           QL in lambda = (gamma, phi) given step 1-2   eqs.(21)-(22), H_1 = Sigma-hat
*   inference        step 1: robust Omega_m eq.(25) or model-based eq.(26)
*                    step 3: Prop. 4, P0 Omega_v P0' / T with Xi_lambda, Xi_sigma eq.(A.13)

program define xtpanelgarch_vt, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "vt") error 301
        _xtpg_vt_display `0'
        exit
    }
    syntax varlist(ts min=2) [if] [in] , [ CCP QML VCE(string) Level(cilevel) noTABle ]
    if "`vce'" == "" local vce "robust"
    local vce = lower("`vce'")
    if !inlist("`vce'", "robust", "model") {
        di as err "vce() must be robust (eq. 25) or model (eq. 26)"
        exit 198
    }
    local isccp = ("`ccp'" != "")
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
    tsunab xorig : `xorig'
    tsrevar `varlist'
    local tsv "`r(varlist)'"
    gettoken y zv : tsv
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch vt"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    if `N' < 2 {
        di as err "vt needs at least 2 panels"
        exit 2001
    }
    if `T' <= `N' + 10 {
        di as err "T must be large relative to N (Sigma-hat is N x N); T = `T', N = `N'"
        exit 2001
    }
    local k : word count `zv'

    tempname b1 V1 U lam Vl Sig V1m
    mata: _xtpg_vt_step1("`y'", "`zv'", "`touse'", `N', `T', "`b1'", "`V1'", "`U'")
    mata: _xtpg_vt_fit("`U'", `isccp', "`lam'", "`Vl'", "`Sig'")
    mata: _xtpg_vt_modelV(`N', `T', "`V1m'")
    if "`vce'" == "model" matrix `V1' = `V1m'

    // optional full QML refinement started at the VT estimates (Remark 3.3, Table 5)
    local isqml 0
    if "`qml'" != "" {
        tempname bq Vq Sq
        mata: _xtpg_vt_qml("`y'", "`zv'", "`touse'", `N', `T', `isccp', "`b1'", "`Sig'", "`lam'", "`bq'", "`Vq'", "`Sq'")
        if scalar(__xtpg_qmlrc) == 0 {
            local isqml 1
            matrix `Sig' = `Sq'
        }
    }
    // assemble e(b), e(V): block diagonal (Asai Remark 3.2)
    local names ""
    foreach v of local xorig {
        local names "`names' mean:`v'"
    }
    foreach u of local units {
        local names "`names' mean:alpha`u'"
    }
    local names "`names' variance:gamma variance:phi"
    tempname b V Z
    matrix `b' = (`b1', `lam')
    local p1 = colsof(`b1')
    matrix `Z' = J(`p1', 2, 0)
    matrix `V' = (`V1', `Z' \ `Z'', `Vl')
    if `isqml' {
        matrix `b' = `bq'
        matrix `V' = `Vq'
    }
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local np = colsof(`b')
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar ll = scalar(__xtpg_ll)
    ereturn scalar k = `np'
    ereturn scalar rank = `np'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar converged = scalar(__xtpg_conv)
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "vt"
    ereturn local title = cond(`isccp', "Asai (2023) VT estimator: CCP-GARCH", "Asai (2023) VT estimator: feasible panel GARCH")
    ereturn local cov = cond(`isccp', "ccc", "feasible")
    ereturn local depvar "`yorig'"
    ereturn local xvars "`xorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local vce "`vce'"
    ereturn local vcetype = cond("`vce'" == "robust", "Robust", "Model")
    if `isqml' ereturn local vcetype "Robust"
    ereturn local estimator = cond(`isqml', "QML", "VT")
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix Sigma = `Sig'
    ereturn matrix V_model1 = `V1m'
    ereturn matrix sigma2 = __xtpg_S2
    ereturn matrix covt = __xtpg_CV
    ereturn matrix pairs = __xtpg_pairs
    ereturn matrix resid = __xtpg_U
    capture matrix drop __xtpg_Zt __xtpg_Zbar __xtpg_iQ
    capture scalar drop __xtpg_ll __xtpg_conv
    _xtpg_vt_display, level(`level') `table'
end

program define _xtpg_vt_display
    syntax [, Level(cilevel) noTABle]
    di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "=" as res %10.0fc e(N)
    if "`e(estimator)'" == "QML" di as txt "Full QML of (22) started at the VT estimates" _col(49) "Number of panels" _col(67) "=" as res %10.0f e(N_g)
    else di as txt "Steps: FE (18)-(19) -> Sigma (20) -> QL (21)-(22)" _col(49) "Number of panels" _col(67) "=" as res %10.0f e(N_g)
    if "`e(estimator)'" == "QML" di as txt "VCE: Bollerslev-Wooldridge sandwich" _col(49) "Time periods" _col(67) "=" as res %10.0f e(T)
    else di as txt "Step-1 VCE: `e(vcetype)' (eq. " cond("`e(vce)'" == "robust", "25", "26") ")" _col(49) "Time periods" _col(67) "=" as res %10.0f e(T)
    di as txt "Quasi-log-likelihood (22) = " as res %12.4f e(ll)
    if "`table'" == "" ereturn display, level(`level')
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local g = _b[variance:gamma]
    local f = _b[variance:phi]
    local se = sqrt(`V'[colnumb(`V', "variance:gamma"), colnumb(`V', "variance:gamma")] + ///
        `V'[colnumb(`V', "variance:phi"), colnumb(`V', "variance:phi")] + ///
        2 * `V'[colnumb(`V', "variance:gamma"), colnumb(`V', "variance:phi")])
    di as txt "{hline 78}"
    di as txt "  gamma + phi (persistence)" _col(37) as res %11.4f `g' + `f' _col(51) %11.4f `se' _col(63) %9.2f (`g' + `f' - 1) / `se' as txt "  (H0: =1)"
    if `g' + `f' < 1 & `g' + `f' > 0 {
        di as txt "  half-life of a shock" _col(37) as res %11.2f ln(0.5) / ln(`g' + `f') as txt "  periods"
    }
    di as txt "  stationarity gamma + phi < 1 (eq. 10, Remark 2.4): " as res cond(`g' + `f' < 1, "satisfied", "VIOLATED")
    di as txt "{hline 78}"
end
