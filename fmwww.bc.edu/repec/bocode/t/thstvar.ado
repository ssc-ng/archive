*! thstvar 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Vector smooth transition autoregression (VSTAR / STVAR): two regimes joined
*! by a smooth transition function, estimated by concentrated Gaussian ML.
*! Terasvirta & Yang (2014a) CREATES RP 2014-04 (linearity and misspecification)
*! Terasvirta & Yang (2014b) CREATES RP 2014-08 (specification and evaluation)
*! Luukkonen, Saikkonen & Terasvirta (1988) Biometrika 75:491-499, doi:10.2307/2336599
*! Terasvirta (1994) JASA 89:208-218, doi:10.1080/01621459.1994.10476462
*! Weise (1999) JMCB 31:85-108, doi:10.2307/2601141
*! Auerbach & Gorodnichenko (2012) AEJ:Policy 4:1-27, doi:10.1257/pol.4.2.1

program define thstvar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thstvar" error 301
        Display
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] , ///
        [ LAGS(integer 1)                        ///
          THVar(varname numeric ts)              ///
          DELAY(integer 1)                       ///
          TYPE(string)                           ///
          EXog(varlist numeric ts)               ///
          TRIM(real 0.15)                        ///
          NGamma(integer 20)                     ///
          NC(integer 0)                          ///
          FIXGamma(real 0)                       ///
          ORDer(integer 3)                       ///
          noCONStant                             ///
          Robust                                 ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thstvar} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `lags' < 1 {
        display as error "{bf:lags()} must be 1 or more"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if !inlist(`order', 1, 2, 3) {
        display as error "{bf:order()} must be 1, 2 or 3"
        exit 198
    }
    if `delay' < 1 {
        display as error "{bf:delay()} must be 1 or more"
        exit 198
    }
    if "`type'" == "" local type lstar
    local typenum = .
    if "`type'" == "lstar"  local typenum 1
    if "`type'" == "lstar1" local typenum 1
    if "`type'" == "estar"  local typenum 2
    if "`type'" == "lstar2" local typenum 3
    if `typenum' == . {
        display as error "type() must be lstar (= lstar1), estar or lstar2"
        exit 198
    }
    if `fixgamma' < 0 {
        display as error "{bf:fixgamma()} must be positive"
        exit 198
    }
    local fixg `fixgamma'
    local robust = cond("`robust'"!="", 1, 0)
    local hascons = cond("`constant'"=="", 1, 0)

    local yvars `varlist'
    local k : word count `yvars'

    marksample touse
    markout `touse' `yvars' `exog'

    * ---- the lag block, then any exogenous regressors
    local wvars ""
    local wnames ""
    forvalues j = 1/`lags' {
        foreach v of local yvars {
            tempvar w`j'_`v'
            quietly generate double `w`j'_`v'' = L`j'.`v' if `touse'
            local wvars `wvars' `w`j'_`v''
            local wnames `wnames' L`j'.`v'
        }
    }
    local nexog 0
    foreach v of local exog {
        local ++nexog
        tempvar x`nexog'
        quietly generate double `x`nexog'' = `v' if `touse'
        local wvars `wvars' `x`nexog''
        local wnames `wnames' `v'
    }
    markout `touse' `wvars'

    * ---- the transition variable
    tempvar zv
    local girfok 0
    local qeq 0
    if "`thvar'" != "" {
        quietly generate double `zv' = `thvar' if `touse'
        local zname "`thvar'"
        local delayv .
    }
    else {
        local first : word 1 of `yvars'
        quietly generate double `zv' = L`delay'.`first' if `touse'
        local zname "L`delay'.`first'"
        local delayv `delay'
        local qeq 1
        * a generalised impulse response can only be simulated when the
        * transition variable is itself a lag of a modelled variable that the
        * lag block already carries, and there are no exogenous regressors
        if `delay' <= `lags' & `nexog' == 0 local girfok 1
    }
    markout `touse' `zv'
    local zvar `zv'

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)
    local kw = `lags' * `k' + `nexog' + `hascons'
    if `nobs' <= 2 * `kw' + 4 {
        display as error "the smooth transition model needs 2 x `kw' slope"
        display as error "coefficients per equation; `nobs' observations is too few"
        exit 2001
    }

    mata: tk_thstvar()

    * ---- coefficient names. vec(B) is equation major: for each equation the
    *      kw Phi1 coefficients, then the kw Delta = Phi2 - Phi1 coefficients.
    local wn ""
    if `hascons' local wn _cons
    local wn `wn' `wnames'
    local cn ""
    local ce ""
    foreach dv of local yvars {
        foreach w of local wn {
            local cn `cn' `w'
            local ce `ce' Phi1_`dv'
        }
        foreach w of local wn {
            local cn `cn' `w'
            local ce `ce' Delta_`dv'
        }
    }
    * a calibrated gamma is not a coefficient: it has no standard error
    if `fixg' <= 0 {
        local cn `cn' gamma
        local ce `ce' Transition
    }
    local cn `cn' c
    local ce `ce' Transition
    if `typenum' == 3 {
        local cn `cn' c2
        local ce `ce' Transition
    }

    tempname b V
    matrix `b' = __tk_b
    matrix `V' = __tk_V
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    ereturn post `b' `V', esample(`touse') obs(`nobs')

    ereturn local cmd        "thstvar"
    ereturn local cmdline    "thstvar `0'"
    ereturn local title      "Vector smooth transition autoregression"
    ereturn local model      "`type'"
    ereturn local estimator  "concentrated Gaussian ML (multivariate NLS)"
    ereturn local depvars    "`yvars'"
    ereturn local lagnames   "`wnames'"
    ereturn local wnames     "`wn'"
    ereturn local exog       "`exog'"
    ereturn local threshold_var "`zname'"
    ereturn local timevar    "`timevar'"
    ereturn local vcetype    = cond(`robust', "Robust", "")
    ereturn local properties "b V"
    ereturn local estat_cmd  "thstvar_estat"
    ereturn local predict    "thstvar_p"

    ereturn scalar N        = __tk_n
    * k_eq drives how many equations _coef_table prints: the Transition
    * block is an equation of its own, so it must be counted here
    ereturn scalar k_eq      = 2 * `k' + 1
    ereturn scalar n_tpar    = __tk_ntp
    ereturn scalar k_var     = __tk_k
    ereturn scalar k_w       = __tk_kw
    ereturn scalar lags      = `lags'
    ereturn scalar n_exog    = `nexog'
    ereturn scalar typenum   = `typenum'
    ereturn scalar gamma     = __tk_gamma
    ereturn scalar fix_gamma = __tk_fixg
    ereturn scalar c         = __tk_c1
    if `typenum' == 3 ereturn scalar c2 = __tk_c2
    ereturn scalar sd_z      = __tk_sz
    ereturn scalar lndet     = __tk_lndet
    ereturn scalar lndet0    = __tk_lndet0
    ereturn scalar ll        = __tk_ll
    ereturn scalar ll_0      = __tk_ll0
    ereturn scalar lr        = __tk_lr
    ereturn scalar aic       = __tk_aic
    ereturn scalar bic       = __tk_bic
    ereturn scalar hqic      = __tk_hqic
    ereturn scalar k_par     = __tk_npar
    ereturn scalar converged = __tk_conv
    ereturn scalar G_min     = __tk_gmin
    ereturn scalar G_max     = __tk_gmx
    ereturn scalar G_mean    = __tk_gmean
    ereturn scalar N_low     = __tk_nlow
    ereturn scalar N_high    = __tk_nhigh
    ereturn scalar trim      = `trim'
    ereturn scalar order     = `order'
    ereturn scalar hascons   = `hascons'
    ereturn scalar level     = `level'
    ereturn scalar girf_ok   = `girfok'
    if "`delayv'" != "." ereturn scalar delay = `delayv'
    ereturn scalar q_eq      = `qeq'

    tempname M
    matrix `M' = __tk_sigma
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `yvars'
    ereturn matrix Sigma = `M'
    matrix `M' = __tk_lin
    matrix colnames `M' = LM LR F df1 df2 chi2_df p_LM p_LR p_F
    matrix rownames `M' = H0_linearity H04_g3 H03_g2 H02_g1
    ereturn matrix lintest = `M'
    matrix `M' = __tk_bmat
    ereturn matrix Bmat = `M'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local tn = e(typenum)
    local tlab "logistic, one location (LSTAR1)"
    if `tn' == 2 local tlab "exponential (ESTAR)"
    if `tn' == 3 local tlab "logistic, two locations (LSTAR2)"

    display ""
    display as text "Vector smooth transition autoregression" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Variables: " as result "`e(depvars)'" _col(52) ///
        as text "Lags" _col(68) "=" _col(71) as result %9.0f e(lags)
    display as text "  Transition: " as result "`tlab'" _col(52) ///
        as text "ln|Sigma|" _col(68) "=" _col(71) as result %9.5f e(lndet)
    display as text "  Transition variable: " as result "`e(threshold_var)'" _col(52) ///
        as text "BIC" _col(68) "=" _col(71) as result %9.3f e(bic)
    if e(converged) != 1 {
        display as error "  warning: the optimiser did not converge; the reported"
        display as error "  fit is the best point of the starting grid"
    }
    display ""
    display as text "{hline 78}"
    display as text "  Smoothness gamma (scaled by sd(z) = " ///
        as result %7.4f e(sd_z) as text ")" _col(48) as result %14.4f e(gamma) ///
        as text cond(e(fix_gamma) > 0, "  (calibrated)", "")
    display as text "  Location c" _col(48) as result %14.6g e(c)
    if `tn' == 3 display as text "  Location c2" _col(48) as result %14.6g e(c2)
    display as text "  G(z) range" _col(48) as result ///
        %7.4f e(G_min) " to " %7.4f e(G_max)
    display as text "  Observations with G < .5 / G >= .5" _col(48) as result ///
        %7.0fc e(N_low) "   " %7.0fc e(N_high)
    display as text "  ln|Sigma| of the linear VAR" _col(48) as result %14.5f e(lndet0)
    display as text "{hline 78}"

    tempname L
    matrix `L' = e(lintest)
    display as text "  Linearity tests against a smooth transition (LM form, F version)"
    display as text "    H0: linearity" _col(28) ///
        as result %9.3f `L'[1,3] as text " F(" as result %4.0f `L'[1,4] ///
        as text "," as result %6.0f `L'[1,5] as text ")  p = " as result %6.4f `L'[1,9]
    if `L'[2,3] < . {
        display as text "    H04: third-order term" _col(28) ///
            as result %9.3f `L'[2,3] as text " F(" as result %4.0f `L'[2,4] ///
            as text "," as result %6.0f `L'[2,5] as text ")  p = " as result %6.4f `L'[2,9]
    }
    if `L'[3,3] < . {
        display as text "    H03: second-order term" _col(28) ///
            as result %9.3f `L'[3,3] as text " F(" as result %4.0f `L'[3,4] ///
            as text "," as result %6.0f `L'[3,5] as text ")  p = " as result %6.4f `L'[3,9]
    }
    if `L'[4,3] < . {
        display as text "    H02: first-order term" _col(28) ///
            as result %9.3f `L'[4,3] as text " F(" as result %4.0f `L'[4,4] ///
            as text "," as result %6.0f `L'[4,5] as text ")  p = " as result %6.4f `L'[4,9]
    }
    if `L'[3,9] < . & `L'[2,9] < . & `L'[4,9] < . {
        local rule "LSTAR: the first-order or third-order term is the strongest"
        if `L'[3,9] < `L'[2,9] & `L'[3,9] < `L'[4,9] ///
            local rule "ESTAR (or LSTAR2): H03 is the most strongly rejected"
        display as text "    Terasvirta (1994) rule: " as result "`rule'"
    }
    display as text "{hline 78}"
    display as text "  Wilks LR of the linear VAR against this fit" _col(48) ///
        as result %14.4f e(lr)
    display as text "  That LR is NOT chi-square: under linearity gamma and c are"
    display as text "  unidentified. Use the linearity tests above, not the LR."
    display ""
    display as text "  {bf:Phi1} is the regime reached as G(z) -> 0, {bf:Delta} = Phi2 - Phi1 is"
    display as text "  the change on the way to G(z) -> 1. A zero Delta coefficient means"
    display as text "  that regressor acts the same in both regimes."
    display ""
    _coef_table, level(`=e(level)')
    display as text "Transition: G(z) = " _continue
    if `tn' == 1 display as text "1/(1+exp(-gamma (z-c)/sd(z)))"
    if `tn' == 2 display as text "1-exp(-gamma (z-c)^2/sd(z)^2)"
    if `tn' == 3 display as text "1/(1+exp(-gamma (z-c)(z-c2)/sd(z)^2))"
end
