*! thtvar_estat 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thtvar.
*!   profile      ln|Sigma| over the candidate thresholds, with a plot
*!   regimes      regime sizes and the two coefficient matrices
*!   stability    largest eigenvalue modulus of each regime's companion matrix
*!   bootdist     the bootstrap distribution of the LR statistic
*!   girf         generalised impulse response, Koop-Pesaran-Potter (1996)
*!   table        a publication summary of the fit
*!   serial       system LM test of no residual autocorrelation
*!   archlm       Lutkepohl multivariate ARCH-LM
*!   normality    Jarque-Bera on the orthogonalised residuals
*!   diag         all three of the above in one table

program define thtvar_estat, rclass
    version 15
    if "`e(cmd)'" != "thtvar" {
        display as error "last estimates not found, or not from {bf:thtvar}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("profile", 1, max(4, `l')) {
        Profile `0'
        return add
        exit
    }
    if "`sub'" == substr("regimes", 1, max(4, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("stability", 1, max(4, `l')) {
        Stability `0'
        return add
        exit
    }
    if "`sub'" == substr("bootdist", 1, max(4, `l')) {
        Bootdist `0'
        return add
        exit
    }
    if "`sub'" == "girf" {
        Girf `0'
        return add
        exit
    }
    if "`sub'" == substr("irf", 1, max(3, `l')) {
        Irf `0'
        return add
        exit
    }
    if "`sub'" == substr("fevd", 1, max(4, `l')) {
        * the fevd option has to be MERGED into the caller's option list,
        * not appended after a second comma
        local opts `"`0'"'
        if strpos(`"`opts'"', ",") == 0 local opts ", fevd"
        else local opts `"`opts' fevd"'
        Irf `opts'
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    if inlist("`sub'", "serial", "archlm", "normality", "diag") {
        Mvdiag "`sub'" `0'
        return add
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: profile regimes stability bootdist girf irf"
    display as error "           fevd table serial archlm normality diag"
    exit 198
end

* ======================================================================
* Regime-specific CONDITIONALLY LINEAR impulse responses and FEVD.
* A different object from estat girf: see _tk_irf.ado and the help file.
* ======================================================================
program define Irf, rclass
    version 15
    syntax [, * ]
    local k   = e(k_var)
    local p   = e(lags)
    local hc  = e(hascons)
    local yv  "`e(depvars)'"
    if "`yv'" == "" local yv "`e(depvar)'"
    tempname B1 B2
    capture matrix `B1' = e(B1)
    if _rc {
        display as error "{bf:e(B1)} not found: {bf:estat irf} needs the regime"
        display as error "coefficient matrices, which {bf:thtvar} stores only for"
        display as error "a two-regime fit. With {bf:nthresh()} above 1 there is"
        display as error "no two-regime companion form to build."
        exit 498
    }
    matrix `B2' = e(B2)

    * the regime indicator and the design, rebuilt from e()
    tempvar touse d1
    quietly generate byte `touse' = e(sample)
    quietly predict byte `d1' if `touse', regime
    quietly replace `d1' = 2 - `d1' if `touse'

    local wn "`e(wnames)'"
    local wv ""
    foreach nm of local wn {
        tempvar wx`=strtoname("`nm'")'
        quietly generate double `wx`=strtoname("`nm'")'' = `nm' if `touse'
        local wv "`wv' `wx`=strtoname("`nm'")''"
    }
    _tk_irf , yvars("`yv'") wvars("`wv'") d1var("`d1'") touse("`touse'") ///
        b1mat("`B1'") b2mat("`B2'") lagp(`p') hasconsn(`hc')             ///
        consfirst                                                        ///
        r1name("regime 1 (q <= gamma)") r2name("regime 2 (q >  gamma)")  ///
        `options'
    return add
end

* ======================================================================
* Multivariate residual diagnostics. The null regressors are the model's own
* REGIME-SPLIT design, which for a jump-threshold VAR is its gradient.
* ======================================================================
program define Mvdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "diag"   local which "serial arch normality"
    if "`which'" == "archlm" local which "arch"

    local yv "`e(depvars)'"
    local p  = e(lags)
    local m  = e(nthresh)
    if `m' == . local m 1
    local hc = e(hascons)
    tempname TH
    matrix `TH' = e(thresholds)

    capture drop __tkm_*
    quietly generate byte __tkm_touse = e(sample)
    quietly generate double __tkm_q = `e(threshold_var)' if __tkm_touse

    local wv ""
    local nw 0
    forvalues j = 1/`p' {
        foreach v of local yv {
            local ++nw
            quietly generate double __tkm_w`nw' = L`j'.`v' if __tkm_touse
            local wv `wv' __tkm_w`nw'
        }
    }
    forvalues r = 1/`=`m'+1' {
        if `r' == 1 {
            quietly generate byte __tkm_d`r' = (__tkm_q <= `TH'[1,1]) if __tkm_touse
        }
        else if `r' == `=`m'+1' {
            quietly generate byte __tkm_d`r' = (__tkm_q > `TH'[1,`m']) if __tkm_touse
        }
        else {
            quietly generate byte __tkm_d`r' = ///
                (__tkm_q > `TH'[1,`=`r'-1'] & __tkm_q <= `TH'[1,`r']) if __tkm_touse
        }
    }
    local xl ""
    local nx 0
    forvalues r = 1/`=`m'+1' {
        if `hc' {
            local ++nx
            quietly generate double __tkm_x`nx' = __tkm_d`r' if __tkm_touse
            local xl `xl' __tkm_x`nx'
        }
        foreach v of local wv {
            local ++nx
            quietly generate double __tkm_x`nx' = `v' * __tkm_d`r' if __tkm_touse
            local xl `xl' __tkm_x`nx'
        }
    }
    local el ""
    local i 0
    foreach v of local yv {
        local ++i
        quietly predict double __tkm_e`i' if __tkm_touse, residuals equation(`i')
        local el `el' __tkm_e`i'
    }
    _tk_drop __tkm_E __tkm_X
    mkmat `el' if __tkm_touse, matrix(__tkm_E)
    mkmat `xl' if __tkm_touse, matrix(__tkm_X)

    _tk_mvdiag , emat(__tkm_E) xmat(__tkm_X) lags(`lags') ///
        eqnames("`yv'") which("`which'") model("thtvar")
    return add
    _tk_drop __tkm_E __tkm_X
    capture drop __tkm_*
end

* ======================================================================
program define Profile, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]
    tempname P
    matrix `P' = e(profile)
    local G = rowsof(`P')
    quietly count if e(sample)
    display _n as text "Profile of ln|Sigma| over the candidate thresholds"
    display as text "{hline 66}"
    display as text "  candidate thresholds searched" _col(50) as result %14.0f `G'
    display as text "  minimum at" _col(50) as result %14.6g e(gamma)
    display as text "  ln|Sigma| there" _col(50) as result %14.6f e(lndet)
    display as text "  ln|Sigma| of the linear VAR" _col(50) as result %14.6f e(lndet0)
    display as text "{hline 66}"
    display as text "  A flat profile means the threshold is weakly identified: the"
    display as text "  coefficients are still consistent, but do not read much into the"
    display as text "  point estimate of the threshold itself."
    return matrix profile = `P', copy
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `P', names(col)
                keep if lndet < .
            }
            twoway (line lndet gamma, lcolor(navy))                      ///
                , xline(`=e(gamma)', lcolor(red) lpattern(dash))         ///
                  yline(`=e(lndet0)', lcolor(gs10) lpattern(dot))        ///
                  ytitle("ln|Sigma|") xtitle("`e(threshold_var)'")       ///
                  title("Concentrated objective over the threshold grid") ///
                  subtitle("dashed: the estimate; dotted: the linear VAR") ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Regimes, rclass
    version 15
    tempname B1 B2 D
    matrix `B1' = e(B1)
    matrix `B2' = e(B2)
    matrix `D'  = `B2' - `B1'
    local wn ""
    if e(hascons) == 1 local wn _cons
    local wn `wn' `e(wnames)'
    foreach m in B1 B2 D {
        matrix rownames ``m'' = `wn'
    }
    display _n as text "Regimes of the threshold VAR"
    display as text "{hline 70}"
    display as text "  Threshold variable" _col(46) as result "`e(threshold_var)'"
    display as text "  Threshold" _col(46) as result %14.6g e(gamma)
    display as text "  Regime 1 (q <= gamma) observations" _col(46) ///
        as result %14.0fc e(N_regime1)
    display as text "  Regime 2 (q >  gamma) observations" _col(46) ///
        as result %14.0fc e(N_regime2)
    display as text "{hline 70}"
    display _n as text "Regime 1 coefficients"
    matrix list `B1', noheader format(%9.5f)
    display _n as text "Regime 2 coefficients"
    matrix list `B2', noheader format(%9.5f)
    display _n as text "Difference, regime 2 - regime 1"
    matrix list `D', noheader format(%9.5f)
    return matrix diff = `D', copy
    return matrix B2 = `B2', copy
    return matrix B1 = `B1', copy
end

* ======================================================================
program define Stability, rclass
    version 15
    local k = e(k_var)
    local p = e(lags)
    local hc = e(hascons)
    tempname B1 B2 A1 A2
    matrix `B1' = e(B1)
    matrix `B2' = e(B2)
    local r1 = `hc' + 1
    local r2 = `hc' + `k' * `p'
    if `r2' > rowsof(`B1') {
        display as error "cannot locate the lag block; stability unavailable"
        exit 498
    }
    matrix `A1' = `B1'[`r1'..`r2', 1...]
    matrix `A2' = `B2'[`r1'..`r2', 1...]
    _tk_drop __tk_m1 __tk_m2
    mata: st_numscalar("__tk_m1", tk_var_maxmod(st_matrix("`A1'"), `k', `p'))
    mata: st_numscalar("__tk_m2", tk_var_maxmod(st_matrix("`A2'"), `k', `p'))
    local m1 = __tk_m1
    local m2 = __tk_m2
    _tk_drop __tk_m1 __tk_m2

    display _n as text "Regime-wise stability (companion-matrix eigenvalues)"
    display as text "{hline 70}"
    display as text "  Regime 1: largest modulus" _col(46) as result %14.6f `m1' ///
        as text "  " cond(`m1' < 1, "stable", "explosive")
    display as text "  Regime 2: largest modulus" _col(46) as result %14.6f `m2' ///
        as text "  " cond(`m2' < 1, "stable", "explosive")
    display as text "{hline 70}"
    display as text "  An individual regime MAY be explosive while the whole threshold"
    display as text "  process is stationary and ergodic, because the process leaves that"
    display as text "  regime. A unit root in the OUTER regime is the serious case: then"
    display as text "  nothing pulls the process back and the model has no stationary law."
    return scalar maxmod2 = `m2'
    return scalar maxmod1 = `m1'
end

* ======================================================================
program define Bootdist, rclass
    version 15
    syntax [, GRaph BINs(integer 30) SAVing(string asis) * ]
    capture confirm matrix e(bdist)
    if _rc {
        display as error "no bootstrap distribution stored; refit with {bf:test}"
        exit 498
    }
    tempname D
    matrix `D' = e(bdist)
    local R = rowsof(`D')
    display _n as text "Bootstrap distribution of the `e(teststat)'-LR statistic"
    display as text "{hline 66}"
    display as text "  replications" _col(46) as result %14.0f `R'
    display as text "  observed statistic" _col(46) as result %14.4f e(lr)
    display as text "  bootstrap p-value" _col(46) as result %14.4f e(p)
    display as text "  Monte Carlo s.e. of the p-value" _col(46) as result %14.4f e(p_mcse)
    display as text "{hline 66}"
    return matrix bdist = `D', copy
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `D', names(lrb)
                keep if lrb1 < .
            }
            twoway (histogram lrb1, bin(`bins') fcolor(gs12) lcolor(gs6)) ///
                , xline(`=e(lr)', lcolor(red) lwidth(medthick))           ///
                  xtitle("bootstrap `e(teststat)'-LR") ytitle("density")  ///
                  title("Fixed-regressor bootstrap under a linear VAR")   ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
* Generalised impulse response. A sharp threshold is the limit of a logistic
* transition as gamma -> infinity, so the smooth-transition simulator is
* reused exactly, with gamma set so large that G(z) is 0 or 1 to machine
* precision. There is no second implementation to keep in step.
* ======================================================================
program define Girf, rclass
    version 15
    syntax [, SHock(string) SIZE(real 1) Horizon(integer 12)        ///
              HISTories(string) REPS(integer 100) noCHolesky        ///
              COMPare GRaph SEED(string) SAVing(string asis) * ]

    if e(girf_ok) != 1 {
        display as error "a generalised impulse response can only be simulated when the"
        display as error "threshold variable is a lag of a modelled variable that the lag"
        display as error "block already carries. Refit with {bf:delay()} rather than"
        display as error "{bf:thvar()}, with delay() no greater than lags()."
        exit 198
    }
    if `horizon' < 1 | `reps' < 1 {
        display as error "horizon() and reps() must be 1 or more"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    local k  = e(k_var)
    local p  = e(lags)
    local yv "`e(depvars)'"

    if "`shock'" == "" local shock : word 1 of `yv'
    local sj 0
    local i 0
    foreach v of local yv {
        local ++i
        if "`v'" == "`shock'" local sj `i'
    }
    if `sj' == 0 {
        display as error "shock() must name one of `yv'"
        exit 198
    }
    tempname SIG P D
    matrix `SIG' = e(Sigma)
    * syntax noCHolesky puts what the user typed into the local `cholesky'
    if "`cholesky'" != "nocholesky" {
        matrix `P' = cholesky(`SIG')
        matrix `D' = (`size' * `P'[1..`k', `sj'..`sj'])'
        local shlab "Cholesky column `sj' of Sigma, variables ordered as given"
    }
    else {
        matrix `D' = J(1, `k', 0)
        matrix `D'[1,`sj'] = `size' * sqrt(`SIG'[`sj',`sj'])
        local shlab "`shock' alone; no contemporaneous shock elsewhere"
    }

    * ---- rebuild the design
    tempvar touse
    quietly generate byte `touse' = e(sample)
    local wvars ""
    forvalues j = 1/`p' {
        foreach v of local yv {
            tempvar w`j'_`v'
            quietly generate double `w`j'_`v'' = L`j'.`v' if `touse'
            local wvars `wvars' `w`j'_`v''
        }
    }
    tempvar zv
    quietly generate double `zv' = `e(threshold_var)' if `touse'
    local yvars "`yv'"
    local zvar  "`zv'"
    local hascons "`=e(hascons)'"

    * ---- a sharp threshold as the gamma -> infinity logistic
    tempname B1 B2 BM
    matrix `B1' = e(B1)
    matrix `B2' = e(B2)
    matrix `BM' = `B1' \ (`B2' - `B1')
    _tk_drop __tk_bmat __tk_delta __tk_states __tk_girf
    matrix __tk_bmat  = `BM'
    matrix __tk_delta = `D'
    _tk_drop __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_lagp __tk_hascons __tk_delay __tk_qeq __tk_h __tk_reps __tk_fixg
    scalar __tk_fixg    = 0
    scalar __tk_gamma   = 1e12
    scalar __tk_c1      = e(gamma)
    scalar __tk_c2      = .
    scalar __tk_type    = 1
    scalar __tk_sz      = 1
    scalar __tk_lagp    = `p'
    scalar __tk_hascons = `=e(hascons)'
    scalar __tk_delay   = e(delay)
    scalar __tk_qeq     = e(q_eq)
    scalar __tk_h       = `horizon'
    scalar __tk_reps    = `reps'

    display _n as text "{hline 78}"
    display as text "Generalised impulse response (Koop, Pesaran and Potter 1996)"
    display as text "{hline 78}"
    display as text "  Shock" _col(26) as result "`: display %5.2f `size'' s.d. to `shock'"
    display as text "  Composition" _col(26) as result "`shlab'"
    display as text "  Horizon / draws" _col(26) as result "`horizon' / `reps' per history"
    display as text "  A threshold model has no single impulse response: it depends on"
    display as text "  the history and on the sign and size of the shock, because the"
    display as text "  shock can push the process across the threshold. Both paths use"
    display as text "  the SAME future shocks, so the difference is the shock's effect."
    display as text "{hline 78}"

    if "`compare'" != "" {
        tempname GL GH
        GirfOne `touse' "`wvars'" "`zv' <= `=e(gamma)'" "`yvars'" "`zvar'" `hascons'
        matrix `GL' = r(girf)
        local nlo = r(N_hist)
        GirfOne `touse' "`wvars'" "`zv' > `=e(gamma)'" "`yvars'" "`zvar'" `hascons'
        matrix `GH' = r(girf)
        local nhi = r(N_hist)
        GirfShow `GL' "regime-1 histories, q <= gamma (`nlo' of them)" `horizon' "`yv'"
        GirfShow `GH' "regime-2 histories, q >  gamma (`nhi' of them)" `horizon' "`yv'"
        return scalar N_hist_high = `nhi'
        return scalar N_hist_low  = `nlo'
        return matrix girf_high = `GH', copy
        return matrix girf_low  = `GL', copy
        if "`graph'" != "" GirfGraph `GL' `GH' `horizon' "`yv'" "`shock'" 1 `"`saving'"'
    }
    else {
        local cond "1"
        local hlab "all histories in the estimation sample"
        if "`histories'" == "low" {
            local cond "`zv' <= `=e(gamma)'"
            local hlab "regime-1 histories"
        }
        else if "`histories'" == "high" {
            local cond "`zv' > `=e(gamma)'"
            local hlab "regime-2 histories"
        }
        else if "`histories'" != "" {
            capture confirm number `histories'
            if _rc {
                display as error "histories() must be low, high or a number"
                exit 198
            }
            tempvar u rk
            quietly generate double `u' = runiform() if `touse'
            quietly egen double `rk' = rank(`u') if `touse'
            local cond "`rk' <= `histories'"
            local hlab "a random `histories' histories"
        }
        tempname GA
        GirfOne `touse' "`wvars'" "`cond'" "`yvars'" "`zvar'" `hascons'
        matrix `GA' = r(girf)
        local nha = r(N_hist)
        GirfShow `GA' "`hlab' (`nha' of them)" `horizon' "`yv'"
        return scalar N_hist = `nha'
        return matrix girf = `GA', copy
        if "`graph'" != "" GirfGraph `GA' `GA' `horizon' "`yv'" "`shock'" 0 `"`saving'"'
    }
    _tk_drop __tk_bmat __tk_delta __tk_states __tk_girf
    _tk_drop __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_lagp __tk_hascons __tk_delay __tk_qeq __tk_h __tk_reps __tk_fixg
end

program define GirfOne, rclass
    version 15
    args touse wvars cond yvars zvar hascons
    _tk_drop __tk_states __tk_girf
    quietly count if `touse' & (`cond')
    if r(N) < 1 {
        display as error "no histories satisfy the requested condition"
        exit 2000
    }
    local nh = r(N)
    mkmat `wvars' if `touse' & (`cond'), matrix(__tk_states)
    mata: tk_stv_girfrun()
    tempname G
    matrix `G' = __tk_girf
    _tk_drop __tk_girf __tk_states
    return matrix girf = `G'
    return scalar N_hist = `nh'
end

program define GirfShow
    version 15
    args M lab h yv
    local k : word count `yv'
    display _n as text "  `lab'"
    display as text "  {hline 70}"
    display as text "  horizon" _continue
    local j 0
    foreach v of local yv {
        local ++j
        display as text _col(`=10+14*`j'') %13s abbrev("`v'", 13) _continue
    }
    display ""
    display as text "  {hline 70}"
    forvalues s = 1/`h' {
        display as text "  " %5.0f `s' _continue
        forvalues j = 1/`k' {
            display as result _col(`=10+14*`j'') %13.6f `M'[`s',`j'] _continue
        }
        display ""
    }
    display as text "  {hline 70}"
end

program define GirfGraph
    version 15
    args A B h yv shock cmp sav
    local k : word count `yv'
    preserve
        quietly {
            clear
            set obs `h'
            generate int horizon = _n
            forvalues j = 1/`k' {
                generate double ga`j' = .
                generate double gb`j' = .
                forvalues s = 1/`h' {
                    replace ga`j' = `A'[`s',`j'] in `s'
                    replace gb`j' = `B'[`s',`j'] in `s'
                }
            }
        }
        local gl ""
        forvalues j = 1/`k' {
            local vn : word `j' of `yv'
            if `cmp' {
                twoway (line ga`j' horizon, lcolor(navy) lwidth(medthick))      ///
                       (line gb`j' horizon, lcolor(cranberry) lpattern(dash)    ///
                            lwidth(medthick))                                  ///
                     , yline(0, lcolor(gs10)) ytitle("`vn'") xtitle("horizon")  ///
                       name(tkg`j', replace) nodraw                            ///
                       legend(order(1 "regime 1" 2 "regime 2") size(vsmall) rows(1))
            }
            else {
                twoway (line ga`j' horizon, lcolor(navy) lwidth(medthick))      ///
                     , yline(0, lcolor(gs10)) ytitle("`vn'") xtitle("horizon")  ///
                       name(tkg`j', replace) nodraw legend(off)
            }
            local gl `gl' tkg`j'
        }
        graph combine `gl', title("Generalised impulse response to a shock in `shock'") ///
            subtitle("Koop, Pesaran and Potter (1996)") name(tkgirf, replace)
        if `"`sav'"' != "" _tk_gsave `sav', name(tkgirf)
    restore
end

* ======================================================================
program define Table
    version 15
    display _n as text "{hline 78}"
    display as text "Threshold vector autoregression -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variables" _col(46) as result "`e(depvars)'"
    display as text "  Threshold variable" _col(46) as result "`e(threshold_var)'"
    display as text "  Lags" _col(46) as result %12.0f e(lags)
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "{hline 78}"
    display as text "  Threshold" _col(46) as result %12.6g e(gamma)
    display as text "  Regime sizes" _col(40) as result ///
        %11.0fc e(N_regime1) " " %11.0fc e(N_regime2)
    display as text "{hline 78}"
    display as text "  ln|Sigma|" _col(46) as result %12.5f e(lndet)
    display as text "  ln|Sigma| of the linear VAR" _col(46) as result %12.5f e(lndet0)
    display as text "  log likelihood" _col(46) as result %12.4f e(ll)
    display as text "  log likelihood of the linear VAR" _col(46) as result %12.4f e(ll_0)
    display as text "  AIC / BIC / HQIC" _col(40) as result ///
        %11.2f e(aic) " " %11.2f e(bic) " " %11.2f e(hqic)
    display as text "{hline 78}"
    if e(p) < . {
        display as text "  `e(teststat)'-LR" _col(46) as result %12.4f e(lr) ///
            as text "   bootstrap p = " as result %6.4f e(p)
        display as text "{hline 78}"
    }
end
