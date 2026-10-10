*! thstr 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Cross-sectional smooth transition regression: the coefficients change
*! gradually with an observed transition variable instead of jumping at a
*! threshold. Same engine as thstar, without the autoregressive structure
*! and without any need for tsset.
*! Terasvirta (1994) JASA 89:208-218, doi:10.1080/01621459.1994.10476462
*! Luukkonen, Saikkonen & Terasvirta (1988) Biometrika 75:491-499, doi:10.2307/2336599
*! Granger & Terasvirta (1993); van Dijk, Terasvirta & Franses (2002) survey

program define thstr, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thstr" error 301
        Display
        exit
    }

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        THVar(varname numeric ts)                   ///
        [ TYpe(string)                              ///
          TRIM(real 0.15)                           ///
          NGAMMA(integer 20)                        ///
          NC(integer 40)                            ///
          noCONStant                                ///
          VCE(string)                               ///
          Level(cilevel) ]

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

    local robust  = cond("`vce'"=="robust", 1, 0)
    local hascons = cond("`constant'"=="", 1, 0)

    marksample touse
    markout `touse' `thvar'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'

    local xlist ""
    local xvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local xlist `r(varlist)'
        fvrevar `xlist' if `touse'
        local xvars `r(varlist)'
    }
    if "`xlist'" == "" & `hascons' == 0 {
        display as error "no regressors: a smooth transition model needs at least one"
        exit 102
    }
    tempvar zv
    quietly generate double `zv' = `thvar' if `touse'
    local zvar `zv'
    markout `touse' `zv'

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

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

    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`nobs')

    ereturn local cmd        "thstr"
    ereturn local cmdline    "thstr `0'"
    ereturn local title      "Smooth transition regression"
    ereturn local model      "`type'"
    ereturn local estimator  "nonlinear least squares (concentrated)"
    ereturn local depvar     "`depv'"
    ereturn local indepvars  "`xlist'"
    ereturn local threshold_var "`thvar'"
    ereturn local vcetype    = cond(`robust', "Robust", "")
    ereturn local properties "b V"
    ereturn local estat_cmd  "thstar_estat"
    ereturn local predict    "thstar_p"

    ereturn scalar N       = __tk_n
    ereturn scalar gamma   = __tk_gamma
    ereturn scalar c       = __tk_c1
    if `typenum' == 3 ereturn scalar c2 = __tk_c2
    ereturn scalar sd_z    = __tk_sz
    ereturn scalar ssr     = __tk_ssr
    ereturn scalar ssr0    = __tk_ssr0
    ereturn scalar converged = __tk_conv
    ereturn scalar trim    = `trim'
    ereturn scalar level   = `level'
    ereturn scalar hascons = `hascons'
    ereturn scalar typenum = `typenum'
    tempname M
    matrix `M' = __tk_lm
    matrix colnames `M' = F df p
    matrix rownames `M' = LM3 H04 H03 H02
    ereturn matrix lmtest = `M'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local t = upper("`e(model)'")
    display ""
    display as text "Smooth transition regression (`t')" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Transition variable: " as result "`e(threshold_var)'" _col(52) ///
        as text "SSR" _col(68) "=" _col(71) as result %9.0g e(ssr)
    display as text "  Std. err.: " as result ///
        cond("`e(vcetype)'"=="Robust", "robust", "classical") _col(52) ///
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
    tempname L
    matrix `L' = e(lmtest)
    display as text "  Linearity tests on the transition variable"
    display as text "     LM3 (linearity)" _col(30) as result %10.4f `L'[1,1] ///
        as text "   p = " as result %6.4f `L'[1,3]
    display as text "     H04 / H03 / H02" _col(30) as result ///
        %6.4f `L'[2,3] " " %6.4f `L'[3,3] " " %6.4f `L'[4,3] as text "   (p-values)"
    local p04 = `L'[2,3]
    local p03 = `L'[3,3]
    local p02 = `L'[4,3]
    display as text "  Terasvirta (1994) rule points to " as result ///
        cond(`p03' < `p04' & `p03' < `p02', "ESTAR", "LSTAR") ///
        as text "; you fitted " as result "`t'"
    display as text "{hline 78}"
    display ""
    _coef_table, level(`=e(level)')
    display as text "Linear block = the regime when G = 0; Transition block = the CHANGE"
    display as text "added as G goes to 1. The upper regime is their sum ({bf:lincom} it)."
    if e(converged) != 1 {
        display as text "{bf:Warning.} The optimiser did not converge; the grid value is reported."
    }
end
