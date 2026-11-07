*! xtpanelgarch_estat 1.0.0  06nov2026
*! estat after xtpanelgarch: diagnostics, pd, volatility and correlation graphs
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program define xtpanelgarch_estat, rclass
    version 14.0
    if "`e(cmd)'" != "xtpanelgarch" error 301
    gettoken sub rest : 0, parse(" ,")
    local lsub = length("`sub'")
    if "`sub'" == substr("diagnostics", 1, max(4, `lsub')) {
        _xtpg_estat_diag `rest'
    }
    else if "`sub'" == "pd" {
        _xtpg_estat_pd `rest'
    }
    else if "`sub'" == substr("volatility", 1, max(3, `lsub')) {
        _xtpg_estat_vol `rest'
    }
    else if "`sub'" == substr("correlation", 1, max(4, `lsub')) {
        _xtpg_estat_corr `rest'
    }
    else if "`sub'" == substr("effects", 1, max(3, `lsub')) {
        _xtpg_estat_effects `rest'
    }
    else if "`sub'" == substr("backtest", 1, max(4, `lsub')) {
        _xtpg_estat_backtest `rest'
    }
    else if "`sub'" == substr("forecast", 1, max(4, `lsub')) {
        _xtpg_estat_forecast `rest'
    }
    else if "`sub'" == "ic" {
        estat_default ic `rest'
    }
    else {
        di as err "estat `sub' not allowed after xtpanelgarch"
        di as err "available: diagnostics, pd, volatility, correlation, effects, backtest, forecast, ic"
        exit 198
    }
    return add
end

// Ljung-Box Q on standardized and squared standardized residuals, by unit and pooled
// CG (2001) sec. 5.3 / CG (2006) p. 266: "test the squared normalized residuals"
program define _xtpg_estat_diag, rclass
    syntax [, Lags(integer 10) ]
    tempname U S Z Q
    matrix `U' = e(resid)
    matrix `S' = e(sigma2)
    mata: _xtpg_lbq(st_matrix("`U'") :/ sqrt(st_matrix("`S'")), `lags', "`Q'")
    local N = e(N_g)
    di _n as txt "{hline 78}"
    di as txt "Residual diagnostics: standardized residuals z_it = u_it / sigma_it" _col(64) "lags = " as res `lags'
    di as txt "{hline 78}"
    di as txt _col(3) "panel" _col(14) "Q(z)" _col(26) "p-value" _col(38) "Q(z^2)" _col(50) "p-value" _col(61) "LM-ARCH" _col(71) "p-value"
    di as txt "{hline 78}"
    forvalues i = 1/`N' {
        local u : word `i' of `e(units)'
        di as txt _col(3) "`u'" as res _col(10) %9.3f `Q'[`i',1] _col(24) %8.4f `Q'[`i',2] _col(35) %9.3f `Q'[`i',3] _col(48) %8.4f `Q'[`i',4] _col(59) %9.3f `Q'[`i',5] _col(69) %8.4f `Q'[`i',6]
    }
    local r = `N' + 1
    di as txt "{hline 78}"
    di as txt _col(3) "pooled" as res _col(10) %9.3f `Q'[`r',1] _col(24) %8.4f `Q'[`r',2] _col(35) %9.3f `Q'[`r',3] _col(48) %8.4f `Q'[`r',4] _col(59) %9.3f `Q'[`r',5] _col(69) %8.4f `Q'[`r',6]
    di as txt "{hline 78}"
    di as txt "Pooled Q is the sum of the unit statistics, chi2(N x lags). Remaining structure in"
    di as txt "z^2 signals unmodelled conditional heteroskedasticity (CG 2001, sec. 5.3)."
    matrix colnames `Q' = Q_z p_z Q_z2 p_z2 LM_arch p_lm
    return matrix Q = `Q'
end

program define _xtpg_estat_pd, rclass
    if "`e(cov)'" == "none" | "`e(cov)'" == "" {
        di as txt "independent panels: Omega_t is diagonal with positive variances (PD by construction)"
        exit
    }
    tempname m
    mata: _xtpg_pdreport()
    di _n as txt "Positive definiteness of Omega_t (Asai 2023, Propositions 1-2)"
    di as txt "  min eigenvalue over t      = " as res %12.6g r(mineig)
    di as txt "  periods with Omega_t not PD = " as res r(nbad) as txt " of " as res e(T)
    if "`e(cov)'" == "common" | "`e(cov)'" == "pair" {
        local g = _b[variance:L1.arch]
        local d 0
        capture local d = _b[variance:L1.garch]
        local rr = _b[covariance:L1.uu]
        local ll = _b[covariance:L1.cov]
        local N = e(N_g)
        di as txt "  Asai Prop.1 sufficient conditions for PD H_t (given PD K, H_0):"
        di as txt "    gamma >= rho               : " as res %8.4f `g' as txt " >= " as res %8.4f `rr' _col(60) cond(`g' >= `rr', "yes", "NO")
        di as txt "    gamma + rho(N-1) >= 0      : " as res %8.4f `g' + `rr' * (`N' - 1) _col(60) cond(`g' + `rr' * (`N' - 1) >= 0, "yes", "NO")
        di as txt "    phi >= eta                 : " as res %8.4f `d' as txt " >= " as res %8.4f `ll' _col(60) cond(`d' >= `ll', "yes", "NO")
        di as txt "    phi + eta(N-1) >= 0        : " as res %8.4f `d' + `ll' * (`N' - 1) _col(60) cond(`d' + `ll' * (`N' - 1) >= 0, "yes", "NO")
        di as txt "  Asai Prop.2: K PD if gamma + phi - rho - eta <= 0 : " as res %8.4f `g' + `d' - `rr' - `ll' _col(60) cond(`g' + `d' - `rr' - `ll' <= 0, "yes", "NO")
        di as txt "  (the feasible specification gamma = rho, phi = eta is {bf:xtpanelgarch vt})"
    }
    return scalar mineig = r(mineig)
    return scalar nbad = r(nbad)
end

program define _xtpg_estat_vol
    syntax [, SD NAME(string) COMBine noDRAW SCHeme(string) ]
    if "`name'" == "" local name "xtpg_vol"
    tempname S
    matrix `S' = e(sigma2)
    local N = e(N_g)
    preserve
    qui clear
    qui svmat double `S', name(s)
    qui gen double __t = e(t0) + (_n - 1) * e(tdelta)
    local ytl "Conditional variance"
    if "`sd'" != "" {
        forvalues i = 1/`N' {
            qui replace s`i' = sqrt(s`i')
        }
        local ytl "Conditional standard deviation"
    }
    local gl ""
    forvalues i = 1/`N' {
        local u : word `i' of `e(units)'
        qui twoway line s`i' __t, lcolor("0 114 189") lwidth(medthin) ///
            title("`e(ivar)' = `u'", size(medsmall) color(black)) ytitle("") xtitle("") ///
            graphregion(color(white)) plotregion(lcolor(gs12)) ylabel(, angle(0) labsize(small) nogrid) ///
            xlabel(, labsize(small)) name(__xtpgv`i', replace) nodraw
        local gl "`gl' __xtpgv`i'"
    }
    graph combine `gl', graphregion(color(white)) title("`ytl' by panel", color(black) size(medium)) ///
        note("xtpanelgarch `e(subcmd)': `e(title)'", size(vsmall)) name(`name', replace) `draw'
    forvalues i = 1/`N' {
        capture graph drop __xtpgv`i'
    }
    restore
end

program define _xtpg_estat_corr
    syntax [, Pairs(numlist integer) NAME(string) noDRAW ]
    capture confirm matrix e(covt)
    if _rc {
        di as err "no conditional covariances; estimate with cov()"
        exit 198
    }
    if "`name'" == "" local name "xtpg_corr"
    tempname R
    mata: _xtpg_corrmat("`R'")
    local np = colsof(`R')
    tempname P
    matrix `P' = e(pairs)
    preserve
    qui clear
    qui svmat double `R', name(r)
    qui gen double __t = e(t0) + (_n - 1) * e(tdelta)
    local plots ""
    local leg ""
    local np2 = min(`np', 6)
    local cols `""0 114 189" "217 83 25" "237 177 32" "126 47 142" "119 172 48" "77 190 238""'
    forvalues j = 1/`np2' {
        local a = `P'[`j', 1]
        local b = `P'[`j', 2]
        local ua : word `a' of `e(units)'
        local ub : word `b' of `e(units)'
        local c : word `j' of `cols'
        local plots "`plots' (line r`j' __t, lcolor("`c'") lwidth(medthin))"
        local leg `"`leg' `j' "`ua'-`ub'""'
    }
    twoway `plots', graphregion(color(white)) ytitle("Conditional correlation") xtitle("") ///
        ylabel(, angle(0) nogrid) legend(order(`leg') rows(1) size(small) region(lcolor(white))) ///
        title("Implied conditional correlations", color(black) size(medium)) name(`name', replace) `draw'
    restore
    if `np' > 6 di as txt "(first 6 of `np' pairs shown)"
end

// unit effects with 95% CIs, sorted by w_i (Su and Zhu 2024, Figure 1)
program define _xtpg_estat_effects
    syntax [, NAME(string) noDRAW Level(cilevel) ]
    if "`e(subcmd)'" != "armagarch" {
        di as err "estat effects is available after xtpanelgarch armagarch"
        exit 198
    }
    if "`name'" == "" local name "xtpg_effects"
    local z = invnormal(1 - (1 - `level' / 100) / 2)
    tempname M O
    matrix `M' = e(mu)
    matrix `O' = e(omega)
    preserve
    qui clear
    qui svmat double `M', name(m)
    qui svmat double `O', name(o)
    qui gen long unit = _n
    sort o1
    qui gen long rank = _n
    qui gen double mlo = m1 - `z' * m2
    qui gen double mhi = m1 + `z' * m2
    qui gen double olo = o1 - `z' * o2
    qui gen double ohi = o1 + `z' * o2
    twoway (rcap mlo mhi rank, lcolor("0 114 189")) (scatter m1 rank, mcolor("0 114 189") msymbol(O) msize(small)), ///
        yline(0, lcolor(gs10) lpattern(dash)) ytitle("mu_i") xtitle("units ordered by w_i") legend(off) ///
        graphregion(color(white)) ylabel(, angle(0) nogrid) title("Mean effects", size(medsmall) color(black)) ///
        name(__xtpge1, replace) nodraw
    twoway (rcap olo ohi rank, lcolor("217 83 25")) (scatter o1 rank, mcolor("217 83 25") msymbol(D) msize(small)), ///
        ytitle("w_i = E(u_it^2)") xtitle("units ordered by w_i") legend(off) ///
        graphregion(color(white)) ylabel(, angle(0) nogrid) title("Variance effects", size(medsmall) color(black)) ///
        name(__xtpge2, replace) nodraw
    graph combine __xtpge1 __xtpge2, rows(2) graphregion(color(white)) ///
        title("Individual effects with `level'% CIs (Su and Zhu 2024, Fig. 1)", size(medium) color(black)) ///
        name(`name', replace) `draw'
    capture graph drop __xtpge1 __xtpge2
    restore
end

// VaR backtests after qgarch: Kupiec (1995), Christoffersen (1998), DQ (Engle and Manganelli 2004)
program define _xtpg_estat_backtest, rclass
    if "`e(subcmd)'" != "qgarch" {
        di as err "estat backtest is available after xtpanelgarch qgarch"
        exit 198
    }
    tempvar touse yv
    qui gen byte `touse' = e(sample)
    qui gen double `yv' = `e(depvar)' if `touse'
    sort `e(ivar)' `e(tvar)'
    tempname Y Q R
    local NN = e(N_g)
    mata: _xtpg_getE("`yv'", "`touse'", `NN', "`Y'")
    matrix `Q' = e(qtau)
    local tau = e(quantile)
    mata: _xtpg_backtest("`Y'", "`Q'", `tau', "`R'")
    local N = e(N_g)
    di _n as txt "{hline 78}"
    di as txt "In-sample VaR backtests at tau = " as res %5.3f `tau' as txt "  (hit: y_it < Q_tau)"
    di as txt "{hline 78}"
    di as txt _col(3) "panel" _col(12) "hit rate" _col(24) "LR_uc" _col(33) "p" _col(42) "LR_ind" _col(51) "p" _col(59) "LR_cc" _col(67) "p" _col(72) "DQ p"
    di as txt "{hline 78}"
    forvalues i = 1/`N' {
        local u : word `i' of `e(units)'
        di as txt _col(3) "`u'" as res _col(11) %8.4f `R'[`i',1] _col(21) %8.3f `R'[`i',2] _col(30) %6.3f chi2tail(1, `R'[`i',2]) ///
            _col(39) %8.3f `R'[`i',3] _col(48) %6.3f chi2tail(1, `R'[`i',3]) _col(56) %8.3f `R'[`i',4] _col(65) %6.3f chi2tail(2, `R'[`i',4]) ///
            _col(72) %6.3f chi2tail(6, `R'[`i',5])
    }
    local r = `N' + 1
    di as txt "{hline 78}"
    di as txt _col(3) "pooled" as res _col(11) %8.4f `R'[`r',1] _col(21) %8.3f `R'[`r',2] _col(30) %6.3f chi2tail(`N', `R'[`r',2]) ///
        _col(39) %8.3f `R'[`r',3] _col(48) %6.3f chi2tail(`N', `R'[`r',3]) _col(56) %8.3f `R'[`r',4] _col(65) %6.3f chi2tail(2 * `N', `R'[`r',4]) ///
        _col(72) %6.3f chi2tail(6 * `N', `R'[`r',5])
    di as txt "{hline 78}"
    di as txt "LR_uc: Kupiec coverage chi2(1); LR_ind: Christoffersen independence chi2(1); LR_cc chi2(2);"
    di as txt "DQ: Engle-Manganelli dynamic quantile test on (1, 4 lagged hits, VaR), chi2(6)."
    di as txt "Pooled rows sum the unit statistics (independence across units assumed)."
    matrix colnames `R' = hitrate LR_uc LR_ind LR_cc DQ
    return matrix backtest = `R'
end

// h-step-ahead conditional variance forecasts
program define _xtpg_estat_forecast, rclass
    syntax [, Horizon(integer 10) GRaph NAME(string) ]
    local sc "`e(subcmd)'"
    if !inlist("`sc'", "cg", "vt", "cl", "armagarch") {
        di as err "estat forecast is available after cg, vt, cl and armagarch"
        exit 198
    }
    if "`sc'" == "cg" {
        if "`e(egarch)'" != "" | "`e(archm)'" != "" {
            di as err "estat forecast after cg supports GARCH/GJR variances without in-mean terms"
            exit 198
        }
    }
    tempname F
    mata: _xtpg_fc_dispatch(`horizon', "`F'")
    local N = e(N_g)
    local cn ""
    foreach u in `e(units)' {
        local cn "`cn' u`u'"
    }
    matrix colnames `F' = `cn'
    di _n as txt "Conditional variance forecasts, horizons 1..`horizon' (rows) by panel (columns)"
    local hr = min(`horizon', 12)
    local nc = min(`N', 8)
    tempname Fs
    matrix `Fs' = `F'[1..`hr', 1..`nc']
    matlist `Fs', format(%10.4g) border(rows)
    if `horizon' > 12 | `N' > 8 di as txt "(full matrix in r(forecast))"
    if "`graph'" != "" {
        if "`name'" == "" local name "xtpg_forecast"
        preserve
        qui clear
        qui svmat double `F', name(f)
        qui gen h = _n
        local pl ""
        forvalues i = 1/`=min(`N', 8)' {
            local pl "`pl' (line f`i' h)"
        }
        twoway `pl', graphregion(color(white)) ytitle("Forecast of sigma{sup:2}") xtitle("horizon") ///
            ylabel(, angle(0) nogrid) legend(off) title("Variance forecasts", color(black) size(medium)) name(`name', replace)
        restore
    }
    return matrix forecast = `F'
end
