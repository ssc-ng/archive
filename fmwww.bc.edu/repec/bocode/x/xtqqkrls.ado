*! xtqqkrls 1.0.0  25nov2026
*! Panel Quantile-on-Quantile Kernel Regularized Least Squares (PQQKRLS)
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* QQKRLS:   Adebayo, T.S., Ozkan, O. & Eweade, B.S. (2024),
*           J. Cleaner Production 440, 140832, eq. (1)-(2).
* Panel:    Sonail, Xu, Hassan, Fazal & Sadat (2026), Economies 14, 338,
*           eq. (3)-(4)  (PQQKRLS on country-year observations).
* KRLS:     Hainmueller, J. & Hazlett, C. (2014), Political Analysis 22,
*           143-168.  Fitted with the SSC command -krls- (same authors).
* QQ idea:  Sim, N. & Zhou, H. (2015), J. Banking & Finance 55, 1-12.
*
* Step -> equation map
*   [K1] (optional) remove unit (and time) effects by within demeaning
*   [K2] theta-regime of the regressor: x_it <= Q_theta(x)    (lower,
*        the reference implementation)  or |F_n(x_it)-theta| <= h (band)
*   [K3] KRLS on the regime:  y = K c,  K_ij = exp(-||x_i-x_j||^2/sigma),
*        lambda by leave-one-out (Hainmueller-Hazlett 2014, sec. 3)
*   [K4] pointwise marginal effects
*        dy/dx_k = -(2/sigma) sum_i c_i e^{-||x_i-x_k||^2/sigma}(x_i-x_k)
*        (Adebayo et al. 2024, eq. 1;  Sonail et al. 2026, eq. 4)
*   [K5] beta(tau,theta) = tau-quantile of the pointwise effects of the
*        theta-regime (Adebayo et al. 2024, eq. 2)
*   [K6] inference: unit-block bootstrap (fast: resample units' effects;
*        refit: re-estimate KRLS on resampled units, lambda held fixed)
*   [K7] average pointwise effect per theta with its analytic s.e.
*        (KRLS e(Output); Hainmueller-Hazlett 2014, eq. 12)

program define xtqqkrls, eclass
    version 14.0
    if replay() {
        if "`e(cmd)'" != "xtqqkrls" {
            error 301
        }
        _xtqqkrls_show `0'
        exit
    }

    syntax varlist(min=2 numeric ts) [if] [in] [,        ///
        TAU(numlist >0 <1 sort)                           ///
        THETA(numlist >0 <1 sort)                         ///
        FE(string)                                        ///
        TIMEfe                                            ///
        XREF(string)                                      ///
        SUBset(string)                                    ///
        BW(real 0.10)                                     ///
        MINobs(integer 20)                                ///
        REPS(integer 200)                                 ///
        SEED(string)                                      ///
        BOOT(string)                                      ///
        Lambda(real 0)                                    ///
        Sigma(real 0)                                     ///
        NOTABle                                           ///
        GRaph                                             ///
        SAVing(string)                                    ///
        BLOCK(integer 8)                                  ///
        NODOTS ]

    capture which krls
    if _rc {
        di as err "{bf:xtqqkrls} requires {bf:krls} (Hainmueller & Hazlett);" ///
            " install it with:  {stata ssc install krls}"
        exit 199
    }
    _xtqqr_load

    capture xtset
    if _rc {
        di as err "data must be {bf:xtset} (panel variable and time variable)"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"

    if "`tau'"   == "" local tau   "0.05(0.05)0.95"
    if "`theta'" == "" local theta "0.05(0.05)0.95"
    numlist "`tau'"
    local tau `r(numlist)'
    numlist "`theta'"
    local theta `r(numlist)'

    if "`fe'" == "" local fe "none"
    local fe = lower("`fe'")
    if "`fe'" == "pooled" local fe "none"
    if !inlist("`fe'", "none", "within") {
        di as err "fe() must be none or within"
        exit 198
    }
    if "`xref'" == "" local xref "pooled"
    local xref = lower("`xref'")
    if !inlist("`xref'", "pooled", "unit") {
        di as err "xref() must be pooled or unit"
        exit 198
    }
    if "`subset'" == "" local subset "lower"
    local subset = lower("`subset'")
    if !inlist("`subset'", "lower", "band") {
        di as err "subset() must be lower or band"
        exit 198
    }
    if "`boot'" == "" local boot "fast"
    local boot = lower("`boot'")
    if !inlist("`boot'", "fast", "refit", "none") {
        di as err "boot() must be fast, refit or none"
        exit 198
    }
    if "`boot'" == "none" local reps 0
    if "`boot'" != "none" & `reps' < 10 {
        di as err "reps() must be at least 10"
        exit 198
    }
    if `bw' <= 0 | `bw' >= 0.5 {
        di as err "bw() must lie in (0, 0.5)"
        exit 198
    }

    gettoken y rest : varlist
    gettoken x ctrl : rest
    local ctrl = strtrim("`ctrl'")

    marksample touse
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    local N = r(N)
    if `N' < 30 {
        di as err "insufficient observations (`N'); at least 30 required"
        exit 2001
    }
    if `N' > 5000 {
        di as txt "{p 0 6 2}note: KRLS builds an n x n kernel matrix;" ///
            " with N = `N' each theta-regime fit can be slow and memory" ///
            " hungry.{p_end}"
    }
    tempvar gid
    qui egen long `gid' = group(`ivar') if `touse'
    qui su `gid', meanonly
    local Ng = r(max)

    local M : word count `tau'
    local L : word count `theta'

    * ----------------------------------------- [K1] within transformation
    tempvar yt xt
    qui gen double `yt' = `y' if `touse'
    qui gen double `xt' = `x' if `touse'
    local ct ""
    foreach c of local ctrl {
        tempvar cv
        qui gen double `cv' = `c' if `touse'
        local ct "`ct' `cv'"
    }
    tempvar xlev
    qui gen double `xlev' = `x' if `touse'
    if "`fe'" == "within" | "`timefe'" != "" {
        local iters = 1
        if "`fe'" == "within" & "`timefe'" != "" local iters = 50
        foreach v in `yt' `xt' `ct' {
            tempvar m
            forvalues it = 1/`iters' {
                if "`fe'" == "within" {
                    capture drop `m'
                    qui bysort `touse' `gid': egen double `m' = mean(`v') if `touse'
                    qui replace `v' = `v' - `m' if `touse'
                }
                if "`timefe'" != "" {
                    capture drop `m'
                    qui bysort `touse' `tvar': egen double `m' = mean(`v') if `touse'
                    qui replace `v' = `v' - `m' if `touse'
                }
            }
            capture drop `m'
        }
        qui sort `ivar' `tvar'
    }
    * a variable that is constant after demeaning cannot enter KRLS
    foreach v in `xt' `ct' {
        qui su `v' if `touse'
        if r(sd) == 0 | r(sd) == . {
            di as err "a regressor has no variation after the within" ///
                " transformation"
            exit 459
        }
    }

    * ------------------------------------------------ regime indicators
    tempvar F xq sub one
    qui gen double `F' = .
    qui gen double `xq' = .
    qui gen byte `sub' = 0
    qui gen byte `one' = 1
    if "`xref'" == "unit" {
        mata: st_store(., "`F'", "`touse'", ///
            xqq_ecdf_by(st_data(., "`xlev'", "`touse'"), st_data(., "`gid'", "`touse'")))
    }
    else {
        mata: st_store(., "`F'", "`touse'", xqq_ecdf(st_data(., "`xlev'", "`touse'")))
    }

    * ------------------------------------------------------------ header
    di as txt _n "{hline 78}"
    di as txt "{bf:Panel Quantile-on-Quantile KRLS (PQQKRLS)}" ///
        _col(48) "Adebayo, Ozkan & Eweade (2024)"
    di as txt "{hline 78}"
    di as txt "Dependent variable  : " as res "`y'" ///
        as txt _col(45) "Number of obs      = " as res %9.0f `N'
    di as txt "QQ regressor        : " as res "`x'" ///
        as txt _col(45) "Number of groups   = " as res %9.0f `Ng'
    local ctrlshow "`ctrl'"
    if "`ctrlshow'" == "" local ctrlshow "(none)"
    if strlen("`ctrlshow'") > 22 local ctrlshow = substr("`ctrlshow'", 1, 19) + "..."
    di as txt "Other KRLS inputs   : " as res "`ctrlshow'"
    local feshow "none (pooled)"
    if "`fe'" == "within" local feshow "within (unit demeaning)"
    if "`timefe'" != "" local feshow "`feshow' + time"
    di as txt "Fixed effects       : " as res "`feshow'"
    if "`subset'" == "lower" {
        di as txt "theta-regime        : " as res "x <= Q_theta(x)" ///
            as txt _col(45) "x-quantile ref.    = " as res %9s "`xref'"
    }
    else {
        di as txt "theta-regime        : " as res "|F(x)-theta| <= " %4.2f `bw' ///
            as txt _col(45) "x-quantile ref.    = " as res %9s "`xref'"
    }
    local bshow "unit-block bootstrap of pointwise effects, `reps' reps"
    if "`boot'" == "refit" local bshow "unit-block bootstrap with KRLS refit, `reps' reps"
    if "`boot'" == "none"  local bshow "none"
    di as txt "Std. errors         : " as res "`bshow'"
    di as txt "{hline 78}"

    if "`seed'" != "" {
        set seed `seed'
    }

    tempname B SE T P AME TAUV THV D Q
    matrix `B'   = J(`M', `L', .)
    matrix `SE'  = J(`M', `L', .)
    matrix `T'   = J(`M', `L', .)
    matrix `P'   = J(`M', `L', .)
    matrix `AME' = J(`L', 7, .)
    matrix `TAUV' = J(`M', 1, .)
    local i = 0
    foreach t of local tau {
        local ++i
        matrix `TAUV'[`i', 1] = `t'
    }

    local sigopt ""
    if `sigma'  > 0 local sigopt "sigma(`sigma')"
    local lamopt ""
    if `lambda' > 0 local lamopt "lambda(`lambda')"
    local dstub "_xqk"

    local j = 0
    foreach th of local theta {
        local ++j
        * ---------------------------------------------- [K2] regime
        qui replace `sub' = 0
        if "`subset'" == "lower" {
            if "`xref'" == "unit" {
                mata: st_store(., "`xq'", "`touse'", xqq_quant_by( ///
                    st_data(., "`xlev'", "`touse'"), st_data(., "`gid'", "`touse'"), `th'))
            }
            else {
                mata: st_store(., "`xq'", "`touse'", J(rows(st_data(., "`xlev'", ///
                    "`touse'")), 1, xqq_quant(st_data(., "`xlev'", "`touse'"), `th')))
            }
            qui replace `sub' = 1 if `touse' & `xlev' <= `xq'
        }
        else {
            qui replace `sub' = 1 if `touse' & abs(`F' - `th') <= `bw'
        }
        qui count if `sub'
        local nsub = r(N)
        matrix `AME'[`j', 7] = `nsub'
        if `nsub' < `minobs' {
            if "`nodots'" == "" di as txt "s" _c
            continue
        }
        * a regressor constant inside the regime cannot enter KRLS
        local okreg 1
        foreach v in `xt' `ct' {
            qui su `v' if `sub'
            if r(sd) == 0 | r(sd) == . local okreg 0
        }
        if !`okreg' {
            if "`nodots'" == "" di as txt "s" _c
            continue
        }

        * ------------------------------------------ [K3]-[K4] KRLS fit
        capture drop `dstub'_*
        capture qui krls `yt' `xt' `ct' if `sub', deriv(`dstub') ///
            `sigopt' `lamopt'
        if _rc {
            if "`nodots'" == "" di as err "x" _c
            continue
        }
        local dvar "`dstub'_`xt'"
        capture confirm variable `dvar'
        if _rc {
            if "`nodots'" == "" di as err "x" _c
            continue
        }
        tempname OUTK
        matrix `OUTK' = e(Output)
        matrix `AME'[`j', 1] = `OUTK'[1, 1]
        matrix `AME'[`j', 2] = `OUTK'[1, 2]
        matrix `AME'[`j', 3] = `OUTK'[1, 4]
        matrix `AME'[`j', 4] = e(lambda)
        matrix `AME'[`j', 5] = e(sigma)
        matrix `AME'[`j', 6] = e(R2)
        local lam_j = e(lambda)
        local sig_j = e(sigma)

        * ------------------------------- [K5]-[K6] quantiles + bootstrap
        local fastreps = `reps'
        if "`boot'" != "fast" local fastreps = 0
        mata: xqq_bootq("`dvar'", "`gid'", "`sub'", st_matrix("`TAUV'"), ///
            `fastreps', "`D'")
        forvalues i = 1/`M' {
            matrix `B'[`i', `j'] = `D'[`i', 2]
            if "`boot'" == "fast" {
                matrix `SE'[`i', `j'] = `D'[`i', 3]
            }
        }

        if "`boot'" == "refit" {
            tempname QS QS2 QR1
            matrix `QS'  = J(1, `M', 0)
            matrix `QS2' = J(1, `M', 0)
            local nok = 0
            forvalues r = 1/`reps' {
                preserve
                qui keep if `sub'
                qui bsample, cluster(`gid')
                capture drop `dstub'_*
                capture qui krls `yt' `xt' `ct', deriv(`dstub') ///
                    sigma(`sig_j') lambda(`lam_j')
                local brc = _rc
                if !`brc' {
                    mata: xqq_qvec("`dvar'", "`one'", st_matrix("`TAUV'"), "`QR1'")
                }
                restore
                if !`brc' {
                    local ++nok
                    forvalues i = 1/`M' {
                        matrix `QS'[1, `i']  = `QS'[1, `i'] + `QR1'[1, `i']
                        matrix `QS2'[1, `i'] = `QS2'[1, `i'] + `QR1'[1, `i']^2
                    }
                }
            }
            if `nok' > 1 {
                forvalues i = 1/`M' {
                    local mb = `QS'[1, `i'] / `nok'
                    local vb = (`QS2'[1, `i'] - `nok' * `mb' * `mb') / (`nok' - 1)
                    if `vb' > 0 matrix `SE'[`i', `j'] = sqrt(`vb')
                }
            }
        }
        forvalues i = 1/`M' {
            local b = `B'[`i', `j']
            local s = `SE'[`i', `j']
            if `b' < . & `s' < . & `s' > 0 {
                matrix `T'[`i', `j'] = `b' / `s'
                matrix `P'[`i', `j'] = 2 * normal(-abs(`b' / `s'))
            }
        }
        capture drop `dstub'_*
        if "`nodots'" == "" di as txt "." _c
    }
    if "`nodots'" == "" di ""

    matrix `THV' = J(`L', 1, .)
    local j = 0
    foreach t of local theta {
        local ++j
        matrix `THV'[`j', 1] = `t'
    }
    local rn ""
    foreach t of local tau {
        local rn "`rn' tau`=round(100*`t', 1)'"
    }
    local cn ""
    foreach t of local theta {
        local cn "`cn' theta`=round(100*`t', 1)'"
    }
    foreach m in B SE T P {
        matrix rownames ``m'' = `rn'
        matrix colnames ``m'' = `cn'
    }
    matrix rownames `AME' = `cn'
    matrix colnames `AME' = ame se p lambda sigma R2 n_regime

    if `"`saving'"' != "" {
        tempname R2D
        matrix `R2D' = J(`M', `L', .)
        _xtqqr_savelong `B' `SE' `T' `P' `R2D' `TAUV' `THV', saving(`saving')
    }

    ereturn post, esample(`touse') obs(`N')
    ereturn matrix coef  = `B', copy
    ereturn matrix se    = `SE', copy
    ereturn matrix t     = `T', copy
    ereturn matrix p     = `P', copy
    ereturn matrix ame   = `AME', copy
    ereturn matrix tau   = `TAUV', copy
    ereturn matrix theta = `THV', copy
    ereturn scalar N       = `N'
    ereturn scalar N_g     = `Ng'
    ereturn scalar reps    = `reps'
    ereturn scalar n_tau   = `M'
    ereturn scalar n_theta = `L'
    ereturn scalar bw      = `bw'
    ereturn scalar minobs  = `minobs'
    ereturn local depvar   "`y'"
    ereturn local qqvar    "`x'"
    ereturn local controls "`ctrl'"
    ereturn local ivar     "`ivar'"
    ereturn local tvar     "`tvar'"
    ereturn local fe       "`fe'"
    ereturn local timefe   "`timefe'"
    ereturn local xref     "`xref'"
    ereturn local subset   "`subset'"
    ereturn local boot     "`boot'"
    ereturn local method   "krls"
    ereturn local taulist  "`tau'"
    ereturn local thetalist "`theta'"
    ereturn local title    "Panel quantile-on-quantile KRLS"
    ereturn local estimator "qqkrls"
    ereturn local cmdline  "xtqqkrls `0'"
    ereturn local cmd      "xtqqkrls"

    if "`notable'" == "" {
        _xtqqkrls_show, block(`block')
    }
    if "`graph'" != "" {
        capture noisily xtqqplot, heatmap
    }
end


program define _xtqqkrls_show
    version 14.0
    syntax [, BLOCK(integer 8)]
    tempname B P S TAU TH A
    matrix `B'   = e(coef)
    matrix `P'   = e(p)
    matrix `TAU' = e(tau)
    matrix `TH'  = e(theta)
    matrix `A'   = e(ame)

    di as txt _n "{bf:QQKRLS effects  beta(tau, theta)}" ///
        "  = tau-quantile of the pointwise KRLS effects of `e(qqvar)'"
    di as txt "  rows: tau (quantile of the effect distribution);" ///
        "  columns: theta (quantile of `e(qqvar)')"
    mata: xqq_print("`B'", "`P'", st_matrix("`TAU'"), st_matrix("`TH'"), `block', "%7.3f")

    di as txt _n "{bf:Average pointwise marginal effect by theta-regime}" ///
        "  (Hainmueller & Hazlett 2014)"
    di as txt "{hline 9}{c TT}{hline 41}{c TT}{hline 26}"
    di as txt "   theta {c |}   avg. effect     s.e.      p-value      {c |}" ///
        "  lambda     R2     n"
    di as txt "{hline 9}{c +}{hline 41}{c +}{hline 26}"
    local L = rowsof(`A')
    forvalues j = 1/`L' {
        local p = `A'[`j', 3]
        local st ""
        if `p' < 0.10 local st "*"
        if `p' < 0.05 local st "**"
        if `p' < 0.01 local st "***"
        di as txt "   " %5.2f `TH'[`j', 1] " {c |}" as res %13.4f `A'[`j', 1] ///
            as txt %-3s "`st'" as res %10.4f `A'[`j', 2] %11.4f `A'[`j', 3] ///
            as txt "      {c |}" as res %8.4f `A'[`j', 4] %7.3f `A'[`j', 6] ///
            %7.0f `A'[`j', 7]
    }
    di as txt "{hline 9}{c BT}{hline 41}{c BT}{hline 26}"

    mata: xqq_summary("`B'", "`P'", "`S'")
    di as txt _n "{bf:Summary of the QQKRLS surface}"
    di as txt "{hline 40}{c TT}{hline 12}"
    di as txt "  Mean of beta(tau,theta)" _col(41) "{c |}" as res %11.4f `S'[1, 1]
    di as txt "  Median" _col(41) "{c |}" as res %11.4f `S'[1, 2]
    di as txt "  Minimum" _col(41) "{c |}" as res %11.4f `S'[1, 3]
    di as txt "  Maximum" _col(41) "{c |}" as res %11.4f `S'[1, 4]
    di as txt "  Cells significant at 10% / 5% / 1%" _col(41) "{c |}" ///
        as res %4.0f `S'[1, 6] " /" %3.0f `S'[1, 7] " /" %3.0f `S'[1, 8]
    di as txt "  Cells estimated" _col(41) "{c |}" as res %11.0f `S'[1, 9]
    di as txt "{hline 40}{c BT}{hline 12}"
    di as txt _n "Notes: *** p<0.01, ** p<0.05, * p<0.10 (normal approximation)."
    if "`e(boot)'" == "fast" {
        di as txt "       Cell s.e.: unit-block bootstrap of the pointwise" ///
            " effects (`e(reps)' reps)."
    }
    if "`e(boot)'" == "refit" {
        di as txt "       Cell s.e.: unit-block bootstrap with KRLS refit" ///
            " (`e(reps)' reps, lambda fixed)."
    }
    di as txt "       Average-effect s.e.: KRLS analytic variance" ///
        " (Hainmueller & Hazlett 2014)."
    di as txt "       Plots: {stata xtqqplot, heatmap} {c |} {stata xtqqplot, slices}" ///
        " {c |} {stata xtqqplot, ame}"
end
