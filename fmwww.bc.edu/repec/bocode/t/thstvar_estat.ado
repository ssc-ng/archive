*! thstvar_estat 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thstvar.
*!   transition   the transition function, summarised and plotted
*!   regimes      regime weights and the implied Phi2 = Phi1 + Delta
*!   phi2         Phi2 with delta-method standard errors
*!   lintest      linearity tests, optionally for another candidate variable
*!   misspec      the three Terasvirta-Yang (2014a) system misspecification tests
*!   girf         generalised impulse response, Koop-Pesaran-Potter (1996)
*!   table        a publication summary of the fit
*!   serial       system LM test of no residual autocorrelation
*!   archlm       Lutkepohl multivariate ARCH-LM
*!   normality    Jarque-Bera on the orthogonalised residuals
*!   mvdiag       all three of the above in one table

program define thstvar_estat, rclass
    version 15
    if "`e(cmd)'" != "thstvar" {
        display as error "last estimates not found, or not from {bf:thstvar}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("transition", 1, max(5, `l')) {
        Transition `0'
        return add
        exit
    }
    if "`sub'" == substr("regimes", 1, max(4, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == "phi2" {
        Phi2 `0'
        return add
        exit
    }
    if "`sub'" == substr("lintest", 1, max(3, `l')) {
        Lintest `0'
        return add
        exit
    }
    if "`sub'" == substr("misspec", 1, max(4, `l')) {
        Misspec `0'
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
    if inlist("`sub'", "serial", "archlm", "normality", "mvdiag") {
        Mvdiag "`sub'" `0'
        return add
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: transition regimes phi2 lintest misspec girf"
    display as error "           irf fevd table,"
    display as error "           serial archlm normality mvdiag"
    exit 198
end

* ======================================================================
* Multivariate residual diagnostics. The null regressors are the model
* GRADIENT, which tk_stv_refit already assembles; the common block and the
* equation-specific transition columns are stacked here into one design,
* because these tests are system tests and need one design.
* ======================================================================
* Regime-specific CONDITIONALLY LINEAR impulse responses and FEVD for the
* two LIMITING linear systems, Phi1 (as G -> 0) and Phi2 = Phi1 + Delta
* (as G -> 1). A different object from estat girf, which simulates the
* actual smooth-transition system; see _tk_irf.ado and the help file.
* ======================================================================
program define Irf, rclass
    version 15
    syntax [, * ]
    local kw = e(k_w)
    local k  = e(k_var)
    local p  = e(lags)
    local hc = e(hascons)
    local wn "`e(wnames)'"
    local dv "`e(depvars)'"
    if "`dv'" == "" local dv "`e(depvar)'"

    tempname b B1 B2
    matrix `b' = e(b)
    matrix `B1' = J(`kw', `k', .)
    matrix `B2' = J(`kw', `k', .)
    local eqn 0
    foreach d of local dv {
        local ++eqn
        local base = (`eqn' - 1) * 2 * `kw'
        forvalues j = 1/`kw' {
            * e(b) holds Phi1 then DELTA, so Phi2 = Phi1 + Delta
            matrix `B1'[`j',`eqn'] = `b'[1, `=`base'+`j'']
            matrix `B2'[`j',`eqn'] = `b'[1, `=`base'+`j''] ///
                                   + `b'[1, `=`base'+`kw'+`j'']
        }
    }

    tempname SG
    matrix `SG' = e(Sigma)

    tempvar touse
    quietly generate byte `touse' = e(sample)
    * e(wnames) carries _cons FIRST for thstvar, matching the rows of e(b).
    * _tk_irf builds the constant itself, so only the lag names are passed.
    local wv ""
    foreach nm of local wn {
        if "`nm'" == "_cons" continue
        local sn = strtoname("`nm'")
        tempvar wx`sn'
        quietly generate double `wx`sn'' = `nm' if `touse'
        local wv "`wv' `wx`sn''"
    }

    _tk_irf , yvars("`dv'") wvars("`wv'") touse("`touse'")               ///
        b1mat("`B1'") b2mat("`B2'") lagp(`p') hasconsn(`hc')             ///
        sgmat("`SG'") pooled consfirst                                   ///
        r1name("Phi1 limit (G -> 0)") r2name("Phi2 limit (G -> 1)")      ///
        `options'
    return add
end

* ======================================================================
program define Mvdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "mvdiag" local which "serial arch normality"
    if "`which'" == "archlm" local which "arch"

    Rebuild
    local touse   "`s(touse)'"
    local yvars   "`s(yvars)'"
    local wvars   "`s(wvars)'"
    local zvar    "`s(zvar)'"
    local hascons "`s(hascons)'"
    PushScalars
    _tk_drop __tk_graddump __tk_edump
    mata: tk_stv_mvdump()

    local yv "`e(depvars)'"
    _tk_mvdiag , emat(__tk_edump) xmat(__tk_graddump) lags(`lags') ///
        eqnames("`yv'") which("`which'") model("thstvar")
    return add
    _tk_drop __tk_graddump __tk_edump
    _tk_drop __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_fixg
    _tk_drop __tk_bmat
    RebuildDrop
end

* ======================================================================
* Rebuild the design of the fitted model into temporary variables. Returns
* the names the Mata drivers read out of their calling scope.
* ======================================================================
program define Rebuild, sclass
    version 15
    * NOT tempvar: a temporary variable is dropped the moment the program that
    * allocated it exits, so these are explicitly named and the caller drops
    * them with RebuildDrop
    RebuildDrop
    quietly generate byte __tkv_touse = e(sample)
    local yvars "`e(depvars)'"
    local exl   "`e(exog)'"
    local lags  = e(lags)
    local wvars ""
    local n 0
    forvalues j = 1/`lags' {
        foreach v of local yvars {
            local ++n
            quietly generate double __tkv_w`n' = L`j'.`v' if __tkv_touse
            local wvars `wvars' __tkv_w`n'
        }
    }
    local nlag = `n'
    foreach v of local exl {
        local ++n
        quietly generate double __tkv_w`n' = `v' if __tkv_touse
        local wvars `wvars' __tkv_w`n'
    }
    quietly generate double __tkv_z = `e(threshold_var)' if __tkv_touse

    sreturn local touse   "__tkv_touse"
    sreturn local yvars   "`yvars'"
    sreturn local wvars   "`wvars'"
    sreturn local nlag    "`nlag'"
    sreturn local zvar    "__tkv_z"
    sreturn local hascons "`=e(hascons)'"
end

program define RebuildDrop
    version 15
    capture drop __tkv_*
end

* Push the fitted transition parameters where Mata expects them.
program define PushScalars
    version 15
    _tk_drop __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_fixg
    scalar __tk_fixg  = cond(e(fix_gamma) < ., e(fix_gamma), 0)
    scalar __tk_gamma = e(gamma)
    scalar __tk_c1    = e(c)
    scalar __tk_c2    = cond(e(typenum) == 3, e(c2), .)
    scalar __tk_type  = e(typenum)
    scalar __tk_sz    = e(sd_z)
    _tk_drop __tk_bmat
    matrix __tk_bmat = e(Bmat)
end

* Generate G(z) into a named variable over `touse'.
program define MakeG
    version 15
    args G zv touse
    local gg = e(gamma)
    local cc = e(c)
    local sz = e(sd_z)
    local tn = e(typenum)
    if `tn' == 1 {
        quietly generate double `G' = 1/(1+exp(-`gg'*(`zv'-`cc')/`sz')) if `touse'
    }
    else if `tn' == 2 {
        quietly generate double `G' = 1-exp(-`gg'*(`zv'-`cc')^2/`sz'^2) if `touse'
    }
    else {
        local c2 = e(c2)
        quietly generate double `G' = ///
            1/(1+exp(-`gg'*(`zv'-`cc')*(`zv'-`c2')/`sz'^2)) if `touse'
    }
end

* ======================================================================
program define Transition, rclass
    version 15
    syntax [, GRaph TIMEgraph SAVing(string asis) * ]

    tempvar touse G zv
    quietly generate byte `touse' = e(sample)
    quietly generate double `zv' = `e(threshold_var)' if `touse'
    MakeG `G' `zv' `touse'

    display _n as text "Transition function G(z), " as result "`e(model)'"
    display as text "{hline 66}"
    quietly summarize `G' if `touse', detail
    display as text "  mean" _col(24) as result %12.6f r(mean) ///
        as text _col(42) "p25" _col(50) as result %10.6f r(p25)
    display as text "  minimum" _col(24) as result %12.6f r(min) ///
        as text _col(42) "p50" _col(50) as result %10.6f r(p50)
    display as text "  maximum" _col(24) as result %12.6f r(max) ///
        as text _col(42) "p75" _col(50) as result %10.6f r(p75)
    quietly count if `G' < 0.5 & `touse'
    local nl = r(N)
    quietly count if `G' >= 0.5 & `touse'
    local nh = r(N)
    quietly count if (`G' < 0.1 | `G' > 0.9) & `touse'
    local nx = r(N)
    display as text "{hline 66}"
    display as text "  observations with G < .5 (nearer regime 1)" _col(52) ///
        as result %10.0fc `nl'
    display as text "  observations with G >= .5 (nearer regime 2)" _col(52) ///
        as result %10.0fc `nh'
    display as text "  observations in a corner (G < .1 or G > .9)" _col(52) ///
        as result %10.0fc `nx'
    display as text "{hline 66}"
    display as text "  A transition that spends nearly all its time in the corners is"
    display as text "  effectively a sharp threshold model: compare {bf:thtvar}. One that"
    display as text "  never leaves the middle identifies gamma poorly -- read the"
    display as text "  standard error of gamma with that in mind."

    return scalar G_mean   = e(G_mean)
    return scalar N_low    = `nl'
    return scalar N_high   = `nh'
    return scalar N_corner = `nx'

    if "`graph'" != "" {
        local gs : display %6.3f e(gamma)
        local cs : display %6.4g e(c)
        twoway (scatter `G' `zv' if `touse', msymbol(oh) msize(small)) ///
            , yline(0.5, lpattern(dash) lcolor(gs8))                   ///
              xline(`=e(c)', lpattern(dot) lcolor(red))                ///
              ytitle("G(z)") xtitle("`e(threshold_var)'")              ///
              title("Estimated transition function")                   ///
              subtitle("gamma = `=trim("`gs'")', c = `=trim("`cs'")'")  ///
              legend(off) `options'
        if `"`saving'"' != "" _tk_gsave `saving'
    }
    if "`timegraph'" != "" {
        twoway (line `G' `e(timevar)' if `touse')                      ///
            , yline(0.5, lpattern(dash) lcolor(gs8))                   ///
              ytitle("G(z)") xtitle("`e(timevar)'")                    ///
              title("Transition function over time")                   ///
              legend(off) `options'
        if `"`saving'"' != "" _tk_gsave `saving'
    }
end

* ======================================================================
program define Regimes, rclass
    version 15
    display _n as text "Regimes of the smooth transition"
    display as text "{hline 70}"
    display as text "  Phi1 is reached as G(z) -> 0, Phi2 = Phi1 + Delta as G(z) -> 1."
    display as text "  Effective weight of regime 2 = mean G(z) = " ///
        as result %7.4f e(G_mean)
    display as text "  Observations nearer regime 1 / regime 2 = " ///
        as result %6.0fc e(N_low) as text " / " as result %6.0fc e(N_high)
    display as text "{hline 70}"
    tempname B P1 P2 D
    matrix `B' = e(Bmat)
    local kw = e(k_w)
    local k1 = `kw' + 1
    local k2 = 2 * `kw'
    local wn "`e(wnames)'"
    matrix `P1' = `B'[1..`kw', 1...]
    matrix `D'  = `B'[`k1'..`k2', 1...]
    matrix `P2' = `P1' + `D'
    foreach m in P1 P2 D {
        matrix rownames ``m'' = `wn'
        matrix colnames ``m'' = `e(depvars)'
    }
    display _n as text "Phi1 (regime reached as G -> 0)"
    matrix list `P1', noheader format(%9.5f)
    display _n as text "Phi2 (regime reached as G -> 1)"
    matrix list `P2', noheader format(%9.5f)
    return matrix Delta = `D', copy
    return matrix Phi2  = `P2'
    return matrix Phi1  = `P1'
end

* ======================================================================
* Phi2 = Phi1 + Delta with delta-method standard errors. The covariance of
* the sum is Var(Phi1) + Var(Delta) + 2 Cov, all of which e(V) already holds,
* so no refitting of a reparameterised model is needed.
* ======================================================================
program define Phi2, rclass
    version 15
    local kw = e(k_w)
    local wn "`e(wnames)'"
    local dv "`e(depvars)'"
    local k  = e(k_var)
    tempname b V out EST VV
    matrix `b' = e(b)
    matrix `V' = e(V)
    local nr = `k' * `kw'
    matrix `out' = J(`nr', 4, .)
    local rn ""
    local r 0
    local eqn 0
    foreach d of local dv {
        local ++eqn
        local base = (`eqn' - 1) * 2 * `kw'
        local j 0
        foreach w of local wn {
            local ++j
            local ++r
            local i1 = `base' + `j'
            local i2 = `base' + `kw' + `j'
            * scalars, not locals: a local rounds to about 9 significant digits
            scalar `EST' = `b'[1,`i1'] + `b'[1,`i2']
            scalar `VV'  = `V'[`i1',`i1'] + `V'[`i2',`i2'] + 2*`V'[`i1',`i2']
            matrix `out'[`r',1] = `EST'
            if `VV' > 0 {
                matrix `out'[`r',2] = sqrt(`VV')
                matrix `out'[`r',3] = `EST'/sqrt(`VV')
                matrix `out'[`r',4] = 2*normal(-abs(`EST'/sqrt(`VV')))
            }
            local rn `rn' `d':`w'
        }
    }
    matrix rownames `out' = `rn'
    matrix colnames `out' = Phi2 se z p
    display _n as text "Regime-2 coefficients Phi2 = Phi1 + Delta (delta method)"
    display as text "  z and p test Phi2 = 0, not Phi2 = Phi1. For the latter read the"
    display as text "  {bf:Delta} block of the main table directly. These standard errors"
    display as text "  come from the FULL covariance, so they include the cost of having"
    display as text "  estimated gamma and c: they are slightly larger than a regression"
    display as text "  that conditioned on the fitted transition would report."
    matrix list `out', noheader format(%10.5f)
    return matrix phi2 = `out'
end

* ======================================================================
program define Lintest, rclass
    version 15
    syntax [, ZVar(varname numeric ts) ORDer(integer 0) ]

    tempname L
    if "`zvar'" == "" & `order' == 0 {
        matrix `L' = e(lintest)
        local zn  "`e(threshold_var)'"
        local ord = e(order)
    }
    else {
        local zn  "`e(threshold_var)'"
        local ord = cond(`order' == 0, e(order), `order')
        Rebuild
        local touse   "`s(touse)'"
        local yvars   "`s(yvars)'"
        local wvars   "`s(wvars)'"
        local hascons "`s(hascons)'"
        local zvarfit "`s(zvar)'"
        if "`zvar'" != "" {
            tempvar zz
            quietly generate double `zz' = `zvar' if `touse'
            quietly replace `touse' = 0 if missing(`zz')
            local zvarfit `zz'
            local zn "`zvar'"
        }
        local zvar `zvarfit'
        _tk_drop __tk_order
        scalar __tk_order = `ord'
        _tk_drop __tk_lin
        mata: tk_stv_linrun()
        matrix `L' = __tk_lin
        _tk_drop __tk_lin
        _tk_drop __tk_order
    }

    display _n as text "Linearity tests, transition variable " as result "`zn'"
    display as text "  The auxiliary regression adds w_t z^j, j = 1..`ord' (Luukkonen,"
    display as text "  Saikkonen and Terasvirta 1988; system version Terasvirta and"
    display as text "  Yang 2014a). Restrictions are counted by RANK, so the test stays"
    display as text "  valid when z is itself one of the regressors."
    display as text "{hline 78}"
    display as text "  Hypothesis" _col(24) "LM" _col(35) "p" _col(45) "F" ///
        _col(55) "df" _col(69) "p"
    display as text "{hline 78}"
    local lab1 "H0: linearity"
    local lab2 "H04: Gamma3 = 0"
    local lab3 "H03: Gamma2 = 0"
    local lab4 "H02: Gamma1 = 0"
    forvalues r = 1/4 {
        if `L'[`r',1] < . {
            display as text "  `lab`r''" _col(22) as result %10.3f `L'[`r',1] ///
                _col(32) %8.4f `L'[`r',7] _col(41) %10.3f `L'[`r',3] ///
                _col(52) as text "(" as result %3.0f `L'[`r',4] as text "," ///
                as result %5.0f `L'[`r',5] as text ")" _col(65) ///
                as result %8.4f `L'[`r',9]
        }
    }
    display as text "{hline 78}"
    display as text "  Report the F version: the chi-square forms are heavily oversized"
    display as text "  at these sample sizes (Terasvirta and Yang 2014a)."
    if `L'[2,9] < . & `L'[3,9] < . & `L'[4,9] < . {
        if `L'[3,9] < `L'[2,9] & `L'[3,9] < `L'[4,9] {
            display as text "  H03 is the most strongly rejected: choose " ///
                as result "ESTAR" as text " (or LSTAR2)."
        }
        else {
            display as text "  H03 is not the most strongly rejected: choose " ///
                as result "LSTAR" as text "."
        }
    }
    RebuildDrop
    return matrix lintest = `L', copy
end

* ======================================================================
program define Misspec, rclass
    version 15
    syntax [, ARlags(integer 4) ZVar(varname numeric ts) ]
    if `arlags' < 1 {
        display as error "arlags() must be 1 or more"
        exit 198
    }
    local zcand "`zvar'"
    Rebuild
    local touse   "`s(touse)'"
    local yvars   "`s(yvars)'"
    local wvars   "`s(wvars)'"
    local zvar    "`s(zvar)'"
    local hascons "`s(hascons)'"
    * a SECOND transition variable for the remaining-nonlinearity test; the
    * default is the variable the model itself transitions on
    local z2var ""
    if "`zcand'" != "" {
        tempvar z2
        quietly generate double `z2' = `zcand' if `touse'
        quietly replace `touse' = 0 if missing(`z2')
        local z2var `z2'
    }
    PushScalars
    _tk_drop __tk_arq
    scalar __tk_arq = `arlags'
    _tk_drop __tk_ms __tk_msf1 __tk_msf2 __tk_msf3
    mata: tk_stv_misspec()

    tempname M F1 F2 F3
    matrix `M' = __tk_ms
    local has1 0
    local has2 0
    local has3 0
    capture matrix `F1' = __tk_msf1
    if !_rc local has1 1
    capture matrix `F2' = __tk_msf2
    if !_rc local has2 1
    capture matrix `F3' = __tk_msf3
    if !_rc local has3 1
    _tk_drop __tk_ms __tk_msf1 __tk_msf2 __tk_msf3
    _tk_drop __tk_arq __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_fixg
    _tk_drop __tk_bmat

    display _n as text "Misspecification tests of the fitted VSTAR"
    display as text "  Each test adds a block to the MODEL GRADIENT, so each is an LM"
    display as text "  test (Eitrheim and Terasvirta 1996; system form Terasvirta and"
    display as text "  Yang 2014a)."
    display as text "{hline 78}"
    display as text "  H0" _col(38) "F" _col(48) "df" _col(62) "p" _col(71) "chi2 p"
    display as text "{hline 78}"
    local lab1 "no error autocorrelation to lag `arlags'"
    local lab2 "no remaining nonlinearity"
    local lab3 "parameter constancy"
    forvalues r = 1/3 {
        if `M'[`r',3] < . {
            display as text "  `lab`r''" _col(34) as result %9.3f `M'[`r',3] ///
                _col(44) as text "(" as result %3.0f `M'[`r',4] as text "," ///
                as result %6.0f `M'[`r',5] as text ")" _col(58) ///
                as result %8.4f `M'[`r',9] _col(68) %8.4f `M'[`r',7]
        }
        else display as text "  `lab`r''" _col(34) as text "(not computable)"
    }
    display as text "{hline 78}"
    display as text "  Rejection of {bf:no remaining nonlinearity} points to a third regime"
    display as text "  or a second transition variable. Rejection of {bf:parameter}"
    display as text "  {bf:constancy} means the regimes themselves drift, which a"
    display as text "  two-regime model cannot absorb. Rejection of {bf:no}"
    display as text "  {bf:autocorrelation} usually means too few lags."

    local dv "`e(depvars)'"
    display _n as text "Per-equation F tests (the small-sample reliable version)"
    display as text "{hline 78}"
    display as text "  equation" _col(22) "autocorr." _col(40) "nonlinearity" ///
        _col(60) "constancy"
    display as text "{hline 78}"
    local i 0
    foreach d of local dv {
        local ++i
        display as text "  `d'" _continue
        forvalues r = 1/3 {
            if `has`r'' {
                display as result _col(`=2+18*`r'') %8.3f `F`r''[`i',1] ///
                    as text " [" as result %5.3f `F`r''[`i',4] as text "]" _continue
            }
            else display as text _col(`=2+18*`r'') "       .  [    .]" _continue
        }
        display ""
    }
    display as text "{hline 78}"
    display as text "  F statistic with its p-value in brackets."
    if "`zcand'" != "" {
        display as text "  Remaining nonlinearity tested against " as result "`zcand'"
    }

    return matrix misspec = `M', copy
    if `has3' return matrix f_const = `F3'
    if `has2' return matrix f_nonlin = `F2'
    RebuildDrop
    if `has1' return matrix f_arlag = `F1'
end

* ======================================================================
* Generalised impulse response, Koop, Pesaran and Potter (1996).
* ======================================================================
program define Girf, rclass
    version 15
    syntax [, SHock(string) SIZE(real 1) Horizon(integer 12)        ///
              HISTories(string) REPS(integer 100) noCHolesky        ///
              COMPare GRaph SEED(string) SAVing(string asis) * ]

    if e(girf_ok) != 1 {
        display as error "a generalised impulse response can only be simulated when the"
        display as error "transition variable is a lag of a modelled variable that the lag"
        display as error "block already carries, and there are no exogenous regressors."
        display as error "Refit with {bf:delay()} rather than {bf:thvar()}, with delay()"
        display as error "no greater than lags()."
        exit 198
    }
    if `horizon' < 1 {
        display as error "horizon() must be 1 or more"
        exit 198
    }
    if `reps' < 1 {
        display as error "reps() must be 1 or more"
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
    * syntax noCHolesky puts what the user typed into the local `cholesky',
    * NOT into `nocholesky' -- test the string, not emptiness
    local chol = cond("`cholesky'" == "nocholesky", 0, 1)

    tempname SIG P D
    matrix `SIG' = e(Sigma)
    if `chol' {
        matrix `P' = cholesky(`SIG')
        matrix `D' = (`size' * `P'[1..`k', `sj'..`sj'])'
        local shlab "Cholesky column `sj' of Sigma, variables ordered as given"
    }
    else {
        matrix `D' = J(1, `k', 0)
        matrix `D'[1,`sj'] = `size' * sqrt(`SIG'[`sj',`sj'])
        local shlab "`shock' alone; other equations get no contemporaneous shock"
    }

    Rebuild
    local touse   "`s(touse)'"
    local yvars   "`s(yvars)'"
    local wvars   "`s(wvars)'"
    local zvar    "`s(zvar)'"
    local hascons "`s(hascons)'"
    local nlag    "`s(nlag)'"
    PushScalars
    _tk_drop __tk_lagp __tk_hascons __tk_delay __tk_qeq __tk_h __tk_reps
    scalar __tk_lagp    = `p'
    scalar __tk_hascons = `=e(hascons)'
    scalar __tk_delay   = e(delay)
    scalar __tk_qeq     = e(q_eq)
    scalar __tk_h       = `horizon'
    scalar __tk_reps    = `reps'
    _tk_drop __tk_delta __tk_states __tk_girf
    matrix __tk_delta = `D'

    * the lag block only: the first p*k temporary variables of wvars
    local lagvars ""
    local i 0
    foreach v of local wvars {
        local ++i
        if `i' <= `nlag' local lagvars `lagvars' `v'
    }

    tempvar G
    MakeG `G' `zvar' `touse'

    display _n as text "{hline 78}"
    display as text "Generalised impulse response (Koop, Pesaran and Potter 1996)"
    display as text "{hline 78}"
    display as text "  Shock" _col(26) as result "`: display %5.2f `size'' s.d. to `shock'"
    display as text "  Composition" _col(26) as result "`shlab'"
    display as text "  Horizon / draws" _col(26) as result "`horizon' / `reps' per history"
    display as text "  A nonlinear model has no single impulse response: it depends on"
    display as text "  the history and on the sign and size of the shock. Both paths use"
    display as text "  the SAME future shocks, so the difference is the effect of the"
    display as text "  shock and not simulation noise."
    display as text "{hline 78}"

    if "`compare'" != "" {
        tempname GL GH
        GirfOne `touse' "`lagvars'" "`G' < 0.5" "`yvars'" "`wvars'" "`zvar'" `hascons'
        matrix `GL' = r(girf)
        local nlo = r(N_hist)
        GirfOne `touse' "`lagvars'" "`G' >= 0.5" "`yvars'" "`wvars'" "`zvar'" `hascons'
        matrix `GH' = r(girf)
        local nhi = r(N_hist)
        GirfShow `GL' "regime-1 histories, G < .5 (`nlo' of them)" `horizon' "`yv'"
        GirfShow `GH' "regime-2 histories, G >= .5 (`nhi' of them)" `horizon' "`yv'"
        display _n as text "  The two tables are the point of a smooth transition model:"
        display as text "  the same shock propagates differently depending on the state."
        if "`graph'" != "" GirfGraph `GL' `GH' `horizon' "`yv'" "`shock'" 1 `"`saving'"'
        return scalar N_hist_high = `nhi'
        return scalar N_hist_low  = `nlo'
        return matrix girf_high = `GH'
        return matrix girf_low  = `GL'
    }
    else {
        local cond "1"
        local hlab "all histories in the estimation sample"
        if "`histories'" == "low" {
            local cond "`G' < 0.5"
            local hlab "regime-1 histories (G < .5)"
        }
        else if "`histories'" == "high" {
            local cond "`G' >= 0.5"
            local hlab "regime-2 histories (G >= .5)"
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
        GirfOne `touse' "`lagvars'" "`cond'" "`yvars'" "`wvars'" "`zvar'" `hascons'
        matrix `GA' = r(girf)
        local nha = r(N_hist)
        GirfShow `GA' "`hlab' (`nha' of them)" `horizon' "`yv'"
        return scalar N_hist = `nha'
        return matrix girf = `GA', copy
        if "`graph'" != "" GirfGraph `GA' `GA' `horizon' "`yv'" "`shock'" 0 `"`saving'"'
    }
    RebuildDrop
    _tk_drop __tk_delta __tk_states __tk_girf __tk_bmat
    _tk_drop __tk_lagp __tk_hascons __tk_delay __tk_qeq __tk_h __tk_reps __tk_gamma __tk_c1 __tk_c2 __tk_type __tk_sz __tk_fixg
end

program define GirfOne, rclass
    version 15
    * the Mata driver reads yvars / wvars / zvar / touse / hascons out of the
    * calling program's scope, so they are passed in by name here
    args touse lagvars cond yvars wvars zvar hascons
    _tk_drop __tk_states __tk_girf
    quietly count if `touse' & (`cond')
    if r(N) < 1 {
        display as error "no histories satisfy the requested condition"
        exit 2000
    }
    local nh = r(N)
    mkmat `lagvars' if `touse' & (`cond'), matrix(__tk_states)
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
                twoway (line ga`j' horizon, lcolor(navy) lwidth(medthick))   ///
                       (line gb`j' horizon, lcolor(cranberry) lpattern(dash) ///
                            lwidth(medthick))                               ///
                     , yline(0, lcolor(gs10)) ytitle("`vn'")                 ///
                       xtitle("horizon") name(tkg`j', replace) nodraw        ///
                       legend(order(1 "regime 1" 2 "regime 2") size(vsmall) rows(1))
            }
            else {
                twoway (line ga`j' horizon, lcolor(navy) lwidth(medthick))   ///
                     , yline(0, lcolor(gs10)) ytitle("`vn'")                 ///
                       xtitle("horizon") name(tkg`j', replace) nodraw legend(off)
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
    display as text "Vector smooth transition autoregression -- summary"
    display as text "{hline 78}"
    display as text "  Dependent variables" _col(46) as result "`e(depvars)'"
    display as text "  Transition function" _col(46) as result "`e(model)'"
    display as text "  Transition variable" _col(46) as result "`e(threshold_var)'"
    display as text "  Lags" _col(46) as result %12.0f e(lags)
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "  Free parameters" _col(46) as result %12.0f e(k_par)
    display as text "{hline 78}"
    display as text "  gamma (scaled by sd(z))" _col(46) as result %12.4f e(gamma)
    display as text "  c" _col(46) as result %12.6g e(c)
    if e(typenum) == 3 display as text "  c2" _col(46) as result %12.6g e(c2)
    display as text "  mean G(z)" _col(46) as result %12.4f e(G_mean)
    display as text "{hline 78}"
    display as text "  ln|Sigma|" _col(46) as result %12.5f e(lndet)
    display as text "  ln|Sigma| of the linear VAR" _col(46) as result %12.5f e(lndet0)
    display as text "  log likelihood" _col(46) as result %12.4f e(ll)
    display as text "  log likelihood of the linear VAR" _col(46) as result %12.4f e(ll_0)
    display as text "  AIC / BIC / HQIC" _col(40) as result ///
        %11.2f e(aic) " " %11.2f e(bic) " " %11.2f e(hqic)
    display as text "{hline 78}"
    tempname L
    matrix `L' = e(lintest)
    display as text "  Linearity test, F version" _col(46) as result %12.4f `L'[1,3] ///
        as text "   p = " as result %6.4f `L'[1,9]
    display as text "{hline 78}"
end
