*! thstar 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Smooth transition autoregression: LSTAR, ESTAR and second-order LSTAR,
*! estimated by nonlinear least squares with the linear parameters
*! concentrated out, from a grid of starting values.
*! Luukkonen, Saikkonen & Terasvirta (1988) Biometrika 75:491-499, doi:10.2307/2336599
*! Terasvirta (1994) JASA 89:208-218, doi:10.1080/01621459.1994.10476462
*! Eitrheim & Terasvirta (1996) JoE 74:59-75, doi:10.1016/0304-4076(95)01751-8

program define thstar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thstar" error 301
        Display
        exit
    }

    syntax varname(numeric ts) [if] [in] , ///
        [ AR(numlist integer >0 sort)      ///
          TYpe(string)                     ///
          THVar(varname numeric ts)        ///
          DELAY(integer 1)                 ///
          TRIM(real 0.15)                  ///
          NGAMMA(integer 20)               ///
          NC(integer 40)                   ///
          noCONStant                       ///
          VCE(string)                      ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thstar} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if "`type'" == "" local type lstar1
    local typenum = .
    if "`type'" == "lstar1" local typenum 1
    if "`type'" == "estar"  local typenum 2
    if "`type'" == "lstar2" local typenum 3
    if `typenum' == . {
        display as error "type() must be lstar1, estar or lstar2"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `ngamma' < 3 | `nc' < 3 {
        display as error "{bf:ngamma()} and {bf:nc()} must be at least 3"
        exit 198
    }
    if "`ar'" == "" local ar 1
    local robust = cond("`vce'"=="robust", 1, 0)
    local hascons = cond("`constant'"=="", 1, 0)
    local depv `varlist'

    marksample touse
    markout `touse' `depv'

    local xlist ""
    local xvars ""
    foreach j of local ar {
        tempvar l`j'
        quietly generate double `l`j'' = L`j'.`depv' if `touse'
        local xvars `xvars' `l`j''
        local xlist `xlist' L`j'.`depv'
    }
    markout `touse' `xvars'

    tempvar zv
    if "`thvar'" != "" {
        quietly generate double `zv' = `thvar' if `touse'
        local zname "`thvar'"
    }
    else {
        quietly generate double `zv' = L`delay'.`depv' if `touse'
        local zname "L`delay'.`depv'"
    }
    markout `touse' `zv'
    local zvar `zv'

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }

    mata: tk_thstar()

    * ------------------------------------------------ post
    local cn ""
    local ce ""
    foreach v of local xlist {
        local cn `cn' `v'
        local ce `ce' Linear
    }
    if `hascons' {
        local cn `cn' _cons
        local ce `ce' Linear
    }
    foreach v of local xlist {
        local cn `cn' `v'
        local ce `ce' Transition
    }
    if `hascons' {
        local cn `cn' _cons
        local ce `ce' Transition
    }
    local cn `cn' gamma c
    local ce `ce' Transition_parms Transition_parms
    if `typenum' == 3 {
        local cn `cn' c2
        local ce `ce' Transition_parms
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

    quietly count if `touse'
    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`r(N)')

    ereturn local cmd        "thstar"
    ereturn local cmdline    "thstar `0'"
    ereturn local title      "Smooth transition autoregression"
    ereturn local model      "`type'"
    ereturn local estimator  "nonlinear least squares (concentrated)"
    ereturn local depvar     "`depv'"
    ereturn local arlags     "`ar'"
    ereturn local arnames    "`xlist'"
    ereturn local threshold_var "`zname'"
    ereturn local timevar    "`timevar'"
    ereturn local vcetype    = cond(`robust', "Robust", "")
    ereturn local properties "b V"
    ereturn local estat_cmd  "thstar_estat"
    ereturn local predict    "thstar_p"

    ereturn scalar N      = __tk_n
    ereturn scalar gamma  = __tk_gamma
    ereturn scalar c      = __tk_c1
    if `typenum' == 3 ereturn scalar c2 = __tk_c2
    ereturn scalar sd_z   = __tk_sz
    ereturn scalar ssr    = __tk_ssr
    ereturn scalar ssr0   = __tk_ssr0
    ereturn scalar converged = __tk_conv
    ereturn scalar trim   = `trim'
    ereturn scalar level  = `level'
    ereturn scalar k_lags = `: word count `ar''
    ereturn scalar hascons = `hascons'
    ereturn scalar typenum = `typenum'
    * thforecast needs the delay as a NUMBER, not parsed back out of
    * e(threshold_var); it is 0 when the threshold variable is exogenous
    ereturn scalar delay   = cond("`thvar'"=="", `delay', 0)
    tempname M MR
    matrix `M' = __tk_lm
    matrix colnames `M' = F df p
    matrix rownames `M' = LM3 H04 H03 H02
    ereturn matrix lmtest = `M', copy
    * the same four hypotheses in the heteroskedasticity-robust LM form.
    * Neglected conditional heteroskedasticity makes the linearity test
    * reject a LINEAR series, so a rejection by the F form alone can be a
    * GARCH effect wearing a transition's clothes; the robust form uses no
    * assumption about the error variance.
    matrix `MR' = __tk_lmrob
    matrix colnames `MR' = LM df p
    matrix rownames `MR' = LM3 H04 H03 H02
    ereturn matrix lmtest_robust = `MR'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local t = upper("`e(model)'")
    display ""
    display as text "Smooth transition autoregression (`t')" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  `e(depvar)' on lags " as result "`e(arlags)'" _col(52) ///
        as text "SSR" _col(68) "=" _col(71) as result %9.0g e(ssr)
    display as text "  Transition variable: " as result "`e(threshold_var)'" _col(52) ///
        as text "SSR (linear)" _col(68) "=" _col(71) as result %9.0g e(ssr0)
    display ""
    display as text "{hline 78}"
    display as text "  Transition function" _col(26) as result ///
        cond("`e(model)'"=="lstar1", "logistic, first order", ///
        cond("`e(model)'"=="estar",  "exponential", "logistic, second order"))
    display as text "  Smoothness  gamma" _col(26) as result %12.4f e(gamma) ///
        as text _col(44) "(scaled by sd(z) = " as result %6.4f e(sd_z) as text ")"
    display as text "  Location    c" _col(26) as result %12.4f e(c)
    if e(c2) < . {
        display as text "  Location    c2" _col(26) as result %12.4f e(c2)
    }
    display as text "  Convergence" _col(26) as result ///
        cond(e(converged)==1, "yes", "NO - grid value reported")
    display as text "{hline 78}"
    display as text "  Linearity tests on the TRANSITION VARIABLE (auxiliary regression)"
    tempname L
    matrix `L' = e(lmtest)
    display as text "     LM3  (linearity)" _col(30) as result %10.4f `L'[1,1] ///
        as text "   p = " as result %6.4f `L'[1,3]
    display as text "     H04  (third-order term)" _col(30) as result %10.4f `L'[2,1] ///
        as text "   p = " as result %6.4f `L'[2,3]
    display as text "     H03  (second-order term)" _col(30) as result %10.4f `L'[3,1] ///
        as text "   p = " as result %6.4f `L'[3,3]
    display as text "     H02  (first-order term)" _col(30) as result %10.4f `L'[4,1] ///
        as text "   p = " as result %6.4f `L'[4,3]
    local p04 = `L'[2,3]
    local p03 = `L'[3,3]
    local p02 = `L'[4,3]
    local pick = "LSTAR"
    if `p03' < `p04' & `p03' < `p02' local pick = "ESTAR"
    display as text "  Terasvirta (1994) rule: smallest p-value among H04/H03/H02 is " ///
        as result cond(`p03' < `p04' & `p03' < `p02', "H03", ///
                  cond(`p04' <= `p02', "H04", "H02"))
    display as text "  => the sequence points to " as result "`pick'" ///
        as text ", and you fitted " as result "`t'"
    display as text "{hline 78}"
    display ""
    _coef_table, level(`=e(level)')
    display as text "Linear block = the regime when G = 0; Transition block = the CHANGE"
    display as text "added as G goes to 1. The upper regime is their sum ({bf:lincom} it)."
    if e(converged) != 1 {
        display as text "{bf:Warning.} The optimiser did not converge; the reported values are"
        display as text "the best grid point. Raise ngamma()/nc() or rethink the specification."
    }
end
