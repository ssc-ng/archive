*! jointdiag_score 1.0.0  06oct2026
*! Score (Rao) tests for autocorrelation, heteroskedasticity and
*! bilinearity in the errors, singly and jointly.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   Tsai (1986), Biometrika 73(2), 455-460
*     model (2.1)-(2.3):  y_t = x_t'beta + u_t ,  u_t = rho u_{t-1} + e_t ,
*                         var(e_t) = w(z_t, lambda) sigma^2
*     eq.(2-4):   S = S1 + S2
*                 S1 = (T rho_hat)^2 / (T-1)              ~ chi2(1)
*                 S2 = 0.5 V' Dbar (Dbar'Dbar)^-1 Dbar' V ~ chi2(q)
*                 S                                        ~ chi2(q+1)
*                 rho_hat = sum' e_t e_{t-1} / sum e_t^2   (eq. 2-5)
*     sec.3: S is large exactly when Cook's normal curvature of the
*            influence graph is large, or when the GLS coefficients are
*            sensitive to the perturbation.
*   Liu, Wei & Wang (2003), Comm. Statist. Theory Meth. 32(12), 2441-2463
*     model (1.1): NONLINEAR regression with DBL(p,0,1) errors
*                  u_t = sum_i phi_i u_{t-i} + psi u_{t-1} e_{t-1} + e_t
*     eq.(3.2) SCa : bilinearity      H0: psi = 0             ~ chi2(1)
*     eq.(3.3) SCb : correlation      H0: phi = 0, psi = 0    ~ chi2(p+1)
*     eq.(3.4) SCc : homogeneity of variance  H0: gamma = 0   ~ chi2(q)
*     eq.(3.5) SCd : variance AND correlation jointly         ~ chi2(p+q+1)
*     sec.4: the power of a score test falls away again once the
*            alternative is far from the null - it is a LOCAL test.

program define jointdiag_score, rclass
    version 14.0

    syntax [anything] [if] [in] [,   ///
        HET(varlist numeric ts)       ///
        AR(integer 1)                 ///
        BILinear                      ///
        LOG                           ///
        Level(cilevel)                ///
        GRaph                         ///
        NAME(string)                  ///
        NOTABle                       ///
    ]

    _jd_parse `anything' `if' `in'
    local dv   "`r(dv)'"
    local iv   "`r(iv)'"
    local post = r(post)

    marksample touse, novarlist
    markout `touse' `dv' `iv' `het'
    if (`post') {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        qui replace `touse' = 0 if `esamp' == 0
    }
    if (`ar' < 1) {
        di as err "ar() must be positive"
        exit 198
    }

    tempname _h
    capture _estimates hold `_h', restore nullok

    qui regress `dv' `iv' if `touse'
    tempvar res xb
    qui predict double `res' if e(sample), resid
    qui predict double `xb'  if e(sample), xb
    qui replace `touse' = 0 if missing(`res')

    *---- the z variables of w(z,lambda); default = fitted values
    local zv "`het'"
    if ("`zv'" == "") {
        tempvar zfit
        qui gen double `zfit' = `xb' if `touse'
        local zv "`zfit'"
        local zlab "fitted values"
    }
    else {
        local zlab "`het'"
    }

    tempname S
    mata: _jd_score_core("`res'", "`zv'", "`touse'", `ar',    ///
                         ("`bilinear'" != ""), ("`log'" != ""), "`S'")

    local S1  = `S'[1,1]
    local d1  = `S'[1,2]
    local S2  = `S'[2,1]
    local d2  = `S'[2,2]
    local SCa = `S'[3,1]
    local da  = `S'[3,2]
    local SCb = `S'[4,1]
    local db  = `S'[4,2]
    local nn  = `S'[5,1]
    local rh  = `S'[5,2]

    local Stot = `S1' + `S2'
    local dtot = `d1' + `d2'
    local SCd  = `SCb' + `S2'
    local dd   = `db'  + `d2'

    foreach s in S1 S2 Stot SCa SCb SCd {
        local dfx = cond("`s'"=="S1","`d1'",                   ///
                    cond("`s'"=="S2","`d2'",                   ///
                    cond("`s'"=="Stot","`dtot'",               ///
                    cond("`s'"=="SCa","`da'",                  ///
                    cond("`s'"=="SCb","`db'","`dd'")))))
        if (``s'' < . & `dfx' > 0) local p`s' = chi2tail(`dfx', ``s'')
        else                        local p`s' = .
    }

    *------------------------------------------------- display
    if ("`notable'" == "") {
        _jd_head "Score tests for the error structure"                    ///
                 "Model: `dv' on `iv'    (N = `nn')    AR order p = `ar'"  ///
                 "Variance function w(z,lambda) with z = `zlab'"

        _jd_coln "Score test"
        _jd_row "S1  autocorrelation"      `S1'  `d1'  `pS1'  "Tsai (1986) eq.(2-4)"
        _jd_row "S2  homogeneity of var."  `S2'  `d2'  `pS2'  "Cook-Weisberg form"
        _jd_row "S   = S1 + S2  (joint)"   `Stot' `dtot' `pStot' "Tsai (1986)"
        di as txt "{hline 35}{c +}{hline 42}"
        if ("`bilinear'" != "") {
            di as txt %-34s "Liu, Wei & Wang (2003)" " {c |}"
            _jd_row "  SCa  bilinearity"       `SCa' `da' `pSCa' "eq.(3.2)"
            _jd_row "  SCb  correlation+bilin" `SCb' `db' `pSCb' "eq.(3.3)"
            _jd_row "  SCd  variance+correl."  `SCd' `dd' `pSCd' "eq.(3.5)"
            di as txt "{hline 35}{c BT}{hline 42}"
            di as txt "  Score tests are {bf:local}.  Liu, Wei & Wang (2003, sec.4)"
            di as txt "  document that power rises near H0 and then FALLS once the"
            di as txt "  bilinear parameter passes about |psi| = 0.5."
        }
        else {
            di as txt "{hline 35}{c BT}{hline 42}"
        }
        di as txt "  Estimated first-order residual correlation: " as res %8.5f `rh'
        _jd_foot ""
    }

    *------------------------------------------------- graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_score"
        local hasbil = ("`bilinear'" != "")
        _jd_score_graph `S1' `S2' `SCa' `d1' `d2' `da' `level' "`name'" ///
                        `hasbil'
    }

    return scalar S1   = `S1'
    return scalar df1  = `d1'
    return scalar p1   = `pS1'
    return scalar S2   = `S2'
    return scalar df2  = `d2'
    return scalar p2   = `pS2'
    return scalar S    = `Stot'
    return scalar df   = `dtot'
    return scalar p    = `pStot'
    return scalar SCa  = `SCa'
    return scalar p_SCa = `pSCa'
    return scalar SCb  = `SCb'
    return scalar p_SCb = `pSCb'
    return scalar SCd  = `SCd'
    return scalar p_SCd = `pSCd'
    return scalar rho  = `rh'
    return scalar N    = `nn'
    return local  cmd  "jointdiag score"
end


program define _jd_score_graph
    version 14.0
    args S1 S2 SCa d1 d2 da level name hasbil

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local a = (100 - `level') / 100

    preserve
    clear
    qui set obs 3
    qui gen byte id = _n
    qui gen double st = .
    qui gen double cv = .
    qui replace st = `S1' in 1
    qui replace st = `S2' in 2
    if (`hasbil') qui replace st = `SCa' in 3
    qui replace cv = invchi2(`d1', 1-`a') in 1
    qui replace cv = invchi2(`d2', 1-`a') in 2
    if (`hasbil') qui replace cv = invchi2(`da', 1-`a') in 3
    qui drop if missing(st) | missing(cv)
    if (_N == 0) {
        di as txt "  (graph skipped: no score statistic could be computed)"
        restore
        exit
    }
    qui gen double ratio = st/cv
    label define _jdsc 1 "S1 autocorrelation" 2 "S2 heteroskedasticity" ///
                       3 "SCa bilinearity", replace
    label values id _jdsc
    qui su ratio, meanonly
    local top = max(1.35, r(max)*1.2)

    twoway (bar ratio id if ratio <  1, horizontal barwidth(.5)  ///
                color(navy%70) lcolor(navy))                      ///
           (bar ratio id if ratio >= 1, horizontal barwidth(.5)  ///
                color(maroon%85) lcolor(maroon)),                 ///
           yscale(reverse) ylabel(1(1)3, valuelabel labsize(small)) ///
           ytitle("") xtitle("score statistic / critical value", size(small)) ///
           xline(1, lcolor(black) lpattern(dash)) xscale(range(0 `top')) ///
           title("Score tests for the error structure", size(medium))   ///
           subtitle("Tsai (1986); Liu, Wei & Wang (2003)", size(small))  ///
           legend(order(1 "not rejected" 2 "rejected") ring(0) pos(5)    ///
                  region(lcolor(white)) size(small) cols(1))             ///
           `gopt' name(`name', replace)
    restore
end



