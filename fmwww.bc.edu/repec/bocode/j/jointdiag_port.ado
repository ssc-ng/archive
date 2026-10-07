*! jointdiag_port 1.0.0  06oct2026
*! Mixed portmanteau tests for the conditional MEAN and the conditional
*! VARIANCE of a time-series model, jointly.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   Li & Mak (1994), JTSA 15(6), 627-636
*       squared-residual autocorrelations r_l and their covariance
*          I_M - (1/4) X_r R^-1 X_r'
*   Ling & Li (1997), JTSA 18(5), 447-464
*       the joint linear expansion of (rho_hat, r_hat)
*   Wong & Ling (2005), JTSA 26(4), 569-579
*       Theorem 1  : sqrt(n)(rho_hat', r_hat')' -> N(0, V Omega V')
*       Corollary 1: Q_M = n (rho,r)' [V Om V']^-1 (rho,r)  ~ chi2(2M)
*       eq.(12)    : Q_S, the Ljung-Box corrected mixed statistic
*       Q1M        : n sum rho^2 + n r'[I - .25 Xr R^-1 Xr']^-1 r ~ chi2(2M-L0+1)
*   Velasco & Wang (2015), JTSA 36(1), 39-60
*       sec.2 recursive projection that removes the estimation effect:
*         nu(i) = Lam(i) [ Qt(i) - Cd(i) (sum_{j>i} Cd(j)'Cd(j))^-1
*                                        sum_{j>i} Cd(j)' Qt(j) ]
*         Lam(i) = [ I2 + Cd(i)(sum_{j>i} Cd(j)'Cd(j))^-1 Cd(i)' ]^-1/2
*       the transformed autocorrelations are asymptotically N(0, I),
*       so a plain Box-Pierce sum of them is chi2 with NO estimation
*       correction and no lag-order restriction.
*   Mahdi (2024), Statistics and Computing 34:76
*       eq.(3.1)-(3.8): adds the CROSS-correlations r^(1,2)(k) and
*       r^(2,1)(k) between the residuals and their squares, giving
*       C_rs ~ chi2(3m).
*
*  The derivative matrices X_q, X_r (and Mahdi's X11, X22, Xrs) are
*  obtained by NUMERICALLY differentiating the model recursion around
*  theta hat - a route Velasco & Wang (2015, p.44) explicitly allow.

program define jointdiag_port, rclass
    version 14.0

    syntax [anything] [if] [in] [,        ///
        Lags(integer 0)                    ///
        L0(integer 1)                      ///
        METHod(string)                     ///
        RESid(varname numeric)             ///
        Variance(varname numeric)          ///
        Level(cilevel)                     ///
        GRaph                              ///
        NAME(string)                       ///
        NOTABle                            ///
    ]

    if ("`method'" == "") local method "all"
    local method = lower("`method'")
    if (!inlist("`method'","all","wl","vw","mahdi","marginal")) {
        di as err "method() must be one of: all, wl, vw, mahdi, marginal"
        exit 198
    }

    capture qui tsset
    if (_rc) {
        di as err "data must be {bf:tsset}"
        exit 459
    }

    *------------------------------------------------- residuals + variance
    tempvar g gg touse
    qui gen byte `touse' = 0

    if ("`resid'" != "") {
        *---- user supplied
        if ("`variance'" == "") {
            di as err "resid() also needs variance()"
            exit 198
        }
        qui replace `touse' = 1 if !missing(`resid') & !missing(`variance') ///
                                 & `variance' > 0
        qui gen double `g' = `resid' / sqrt(`variance') if `touse'
        local src "user-supplied residuals"
        local hasder 0
        local nparm 0
    }
    else {
        if ("`anything'" != "") {
            di as err "give either a fitted model in memory, or resid() and variance()"
            exit 198
        }
        if ("`e(cmd)'" == "") {
            di as err "fit a model first (arch, arima, regress ...) or use resid()/variance()"
            exit 301
        }
        local ecmd "`e(cmd)'"
        tempvar rr hh
        capture qui predict double `rr' if e(sample), residuals
        if (_rc) {
            capture qui predict double `rr' if e(sample), resid
            if (_rc) {
                di as err "cannot obtain residuals after -`ecmd'-"
                exit 322
            }
        }
        capture qui predict double `hh' if e(sample), variance
        if (_rc) {
            * homoskedastic model: use the residual variance
            qui su `rr' if e(sample)
            qui gen double `hh' = r(Var) if e(sample)
            local homo 1
        }
        qui replace `touse' = 1 if !missing(`rr') & !missing(`hh') & `hh' > 0
        qui gen double `g' = `rr' / sqrt(`hh') if `touse'
        local src "`ecmd'"
        * NOTE: colsof(e(b)) directly inside -local x = ...- can raise
        * r(509) depending on what is in r()/e(); copy the matrix first.
        tempname _eb
        matrix `_eb' = e(b)
        local nparm = colsof(`_eb')
        local hasder 1
    }

    qui count if `touse'
    local n = r(N)
    if (`n' < 30) {
        di as err "too few usable observations (`n')"
        exit 2001
    }

    if (`lags' <= 0) local lags = min(floor(sqrt(`n')), 20)
    local M = `lags'
    if (`l0' < 1)  local l0 1
    if (`l0' > `M') local l0 = `M'

    *------------------------------------------------- derivative matrices
    tempname DER
    local kder 0
    if (`hasder' & "`homo'" == "") {
        capture _jd_port_deriv "`g'" "`touse'" `M' "`DER'"
        if (!_rc) local kder = rowsof(`DER')
    }

    *------------------------------------------------- Mata engine
    tempname RES
    mata: _jd_port_core("`g'", "`touse'", `M', `l0', `kder',          ///
                        "`DER'", "`RES'")

    * RES layout (rows):
    *  1 Ljung-Box (mean)       2 McLeod-Li / Li-Mak (variance)
    *  3 Q_S  (Wong-Ling eq.12) 4 Q1M (Wong-Ling)
    *  5 Q_M  (Wong-Ling full)  6 VW recursive joint
    *  7 VW mean   8 VW variance
    *  9 Mahdi C_12  10 Mahdi C_21
    * 11 n
    local qlb  = `RES'[1,1]
    local dlb  = `RES'[1,2]
    local qml  = `RES'[2,1]
    local dml  = `RES'[2,2]
    local qs   = `RES'[3,1]
    local ds   = `RES'[3,2]
    local q1m  = `RES'[4,1]
    local d1m  = `RES'[4,2]
    local qm   = `RES'[5,1]
    local dm   = `RES'[5,2]
    local vwj  = `RES'[6,1]
    local dvwj = `RES'[6,2]
    local vwm  = `RES'[7,1]
    local dvwm = `RES'[7,2]
    local vwv  = `RES'[8,1]
    local dvwv = `RES'[8,2]
    local c12  = `RES'[9,1]
    local d12  = `RES'[9,2]
    local c21  = `RES'[10,1]
    local d21  = `RES'[10,2]
    local nn   = `RES'[11,1]

    foreach s in qlb qml qs q1m qm vwj vwm vwv c12 c21 {
        local dd = cond("`s'"=="qlb","`dlb'",            ///
                   cond("`s'"=="qml","`dml'",            ///
                   cond("`s'"=="qs","`ds'",              ///
                   cond("`s'"=="q1m","`d1m'",            ///
                   cond("`s'"=="qm","`dm'",              ///
                   cond("`s'"=="vwj","`dvwj'",           ///
                   cond("`s'"=="vwm","`dvwm'",           ///
                   cond("`s'"=="vwv","`dvwv'",           ///
                   cond("`s'"=="c12","`d12'","`d21'")))))))))
        if (``s'' < . & `dd' > 0) local p`s' = chi2tail(`dd', ``s'')
        else                       local p`s' = .
    }

    *------------------------------------------------- display
    if ("`notable'" == "") {
        _jd_head "Mixed portmanteau tests for conditional mean AND variance"  ///
                 "Source: `src'    standardised residuals    (n = `nn', M = `M')" ///
                 "H0: the fitted model is adequate in BOTH conditional moments"

        if (inlist("`method'","all","marginal")) {
            _jd_coln "Marginal (one moment at a time)"
            _jd_row "Ljung-Box   Q(g)"        `qlb' `dlb' `pqlb' "conditional mean"
            _jd_row "Li-Mak      Q(g^2)"      `qml' `dml' `pqml' "conditional variance"
            di as txt "{hline 35}{c +}{hline 42}"
        }
        if (inlist("`method'","all","wl")) {
            di as txt %-34s "Wong & Ling (2005)" " {c |}"
            _jd_row "  Q_S   mixed Ljung-Box"  `qs'  `ds'  `pqs'  "eq.(12)"
            _jd_row "  Q1M   corrected mixed"  `q1m' `d1m' `pq1m' "L0 = `l0'"
            if (`qm' < .) {
                _jd_row "  Q_M   full joint"   `qm'  `dm'  `pqm'  "Corollary 1"
            }
            di as txt "{hline 35}{c +}{hline 42}"
        }
        if (inlist("`method'","all","vw")) {
            di as txt %-34s "Velasco & Wang (2015)" " {c |}"
            if (`vwj' < .) {
                _jd_row "  BP transformed  joint"  `vwj' `dvwj' `pvwj' "distribution free"
                _jd_row "    .. mean part"         `vwm' `dvwm' `pvwm' ""
                _jd_row "    .. variance part"     `vwv' `dvwv' `pvwv' ""
            }
            else {
                di as txt %-34s "  (needs an estimated model" " {c |}"
                di as txt %-34s "   with derivatives)" " {c |}"
            }
            di as txt "{hline 35}{c +}{hline 42}"
        }
        if (inlist("`method'","all","mahdi")) {
            di as txt %-34s "Mahdi (2024) auto-and-cross" " {c |}"
            _jd_row "  C_12  (positive lags)"   `c12' `d12' `pc12' "eq.(3.8)"
            _jd_row "  C_21  (negative lags)"   `c21' `d21' `pc21' "eq.(3.8)"
        }
        di as txt "{hline 35}{c BT}{hline 42}"

        di as txt "  Reading the table: a significant marginal variance test with an"
        di as txt "  insignificant mean test can be an artefact of a misspecified mean."
        di as txt "  The joint statistics control the overall size; compare them with the"
        di as txt "  marginals to locate the failure (Escanciano 2008; Wong & Ling 2005)."
        _jd_foot ""
    }

    *------------------------------------------------- graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_port"
        _jd_port_graph "`g'" "`touse'" `M' `level' "`name'"
    }

    *------------------------------------------------- returns
    return scalar q_lb   = `qlb'
    return scalar df_lb  = `dlb'
    return scalar p_lb   = `pqlb'
    return scalar q_limak = `qml'
    return scalar df_limak = `dml'
    return scalar p_limak = `pqml'
    return scalar q_s    = `qs'
    return scalar df_s   = `ds'
    return scalar p_s    = `pqs'
    return scalar q_1m   = `q1m'
    return scalar df_1m  = `d1m'
    return scalar p_1m   = `pq1m'
    return scalar q_m    = `qm'
    return scalar df_m   = `dm'
    return scalar p_m    = `pqm'
    return scalar vw     = `vwj'
    return scalar df_vw  = `dvwj'
    return scalar p_vw   = `pvwj'
    return scalar c12    = `c12'
    return scalar p_c12  = `pc12'
    return scalar c21    = `c21'
    return scalar p_c21  = `pc21'
    return scalar N      = `nn'
    return scalar M      = `M'
    return local  cmd    "jointdiag port"
end


*-----------------------------------------------------------------------
* _jd_port_deriv : numerical derivatives of the standardised residuals
*   with respect to the fitted parameter vector, evaluated at theta hat.
*   Returns a (k x 2M) Stata matrix whose rows are
*       [ d rho_l / d theta_j  |  d r_l / d theta_j ]
*   obtained by perturbing each coefficient of e(b), refitting NOTHING
*   and simply recomputing the residual series through -predict-.
*-----------------------------------------------------------------------
program define _jd_port_deriv
    version 14.0
    args gv touse M out

    if ("`e(cmd)'" != "arch" & "`e(cmd)'" != "arima") {
        error 322
    }

    tempname b0 bb
    matrix `b0' = e(b)
    local k = colsof(`b0')
    local names : colfullnames `b0'

    tempname D
    matrix `D' = J(`k', `=2*`M'', 0)

    tempvar r0 h0 g0
    qui predict double `r0' if `touse', residuals
    capture qui predict double `h0' if `touse', variance
    if (_rc) error 322

    tempname R0 R1
    mata: _jd_port_rho("`gv'", "`touse'", `M', "`R0'")

    local eps 1e-5
    forvalues j = 1/`k' {
        matrix `bb' = `b0'
        local bj = `bb'[1,`j']
        local dj = `eps' * max(abs(`bj'), 1)
        matrix `bb'[1,`j'] = `bj' + `dj'

        capture {
            tempname eh
            _estimates hold `eh', copy
            ereturn repost b = `bb', rename
            tempvar r1 h1 g1
            qui predict double `r1' if `touse', residuals
            qui predict double `h1' if `touse', variance
            qui gen double `g1' = `r1'/sqrt(`h1') if `touse' & `h1' > 0
            mata: _jd_port_rho("`g1'", "`touse'", `M', "`R1'")
            _estimates unhold `eh'
            * el() returns a SCALAR; plain A[i,j] - B[i,j] inside a
            * -matrix- command is matrix arithmetic and raises r(509)
            forvalues l = 1/`=2*`M'' {
                matrix `D'[`j',`l'] = ///
                    (el("`R1'",`l',1) - el("`R0'",`l',1)) / `dj'
            }
        }
        if (_rc) {
            capture _estimates unhold `eh'
            continue
        }
    }
    matrix `out' = `D'
end


*-----------------------------------------------------------------------
program define _jd_port_graph
    version 14.0
    args gv touse M level name

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local a = (100 - `level') / 100

    tempname RHO
    mata: _jd_port_rho("`gv'", "`touse'", `M', "`RHO'")
    qui count if `touse'
    local n = r(N)
    local se = 1/sqrt(`n')
    local ci = invnormal(1 - `a'/2) * `se'

    preserve
    clear
    qui set obs `M'
    qui gen int lag = _n
    qui gen double rmean = .
    qui gen double rvar  = .
    forvalues l = 1/`M' {
        qui replace rmean = `RHO'[`l',1]       in `l'
        qui replace rvar  = `RHO'[`=`M'+`l'',1] in `l'
    }
    qui gen double hi =  `ci'
    qui gen double lo = -`ci'

    twoway (rarea hi lo lag, color(gs13%45) lwidth(none))                 ///
           (bar rmean lag, barwidth(.45) color(navy%85) lcolor(navy)),     ///
           ytitle("autocorrelation", size(small)) xtitle("lag", size(small)) ///
           title("Residuals (conditional mean)", size(medsmall))           ///
           legend(off) yline(0, lcolor(black) lwidth(thin))                ///
           `gopt' name(`name'_m, replace) nodraw

    twoway (rarea hi lo lag, color(gs13%45) lwidth(none))                 ///
           (bar rvar lag, barwidth(.45) color(maroon%85) lcolor(maroon)),  ///
           ytitle("autocorrelation", size(small)) xtitle("lag", size(small)) ///
           title("Squared residuals (conditional variance)", size(medsmall)) ///
           legend(off) yline(0, lcolor(black) lwidth(thin))                ///
           `gopt' name(`name'_v, replace) nodraw

    graph combine `name'_m `name'_v, cols(2) imargin(small)              ///
          graphregion(color(white))                                       ///
          title("Mixed portmanteau diagnostics", size(medium))            ///
          subtitle("shaded band = pointwise `=100-`level''% interval under H0", ///
                   size(vsmall))                                          ///
          name(`name', replace)
    restore
end



