*! _tk_irf 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Shared worker for "estat irf" after thtvar and thstvar: regime-specific
*! CONDITIONALLY LINEAR impulse responses and forecast-error variance
*! decompositions.
*! Balke (2000) REStat 82:344-349, doi:10.1162/rest.2000.82.2.344
*! Hubrich & Terasvirta (2013) doi:10.1108/S0731-9053(2013)0000031008
*!
*! Called by thtvar_estat and thstvar_estat, which read the regime coefficient
*! matrices out of e() and pass them in by name. Everything printed here says
*! "conditionally linear" on its face, because that is a different object from
*! the generalised impulse response that estat girf computes, and conflating
*! the two is the error this file exists to prevent.

program define _tk_irf, rclass
    version 15
    syntax , YVars(string) WVars(string) TOUSE(string)              ///
        B1mat(string) B2mat(string) LAGP(integer) HASConsn(integer) ///
        [ D1var(string) SGmat(string) POOLED CONSFirst              ///
          Horizon(integer 12) noCHolesky FEVD REPS(integer 0)       ///
          Level(real 0.95) WILD SEED(string) REGime(integer 0)      ///
          GRaph SAVing(string asis) R1name(string) R2name(string) ]

    if `horizon' < 1 {
        display as error "{bf:horizon()} must be 1 or more"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} must be 0 or more"
        exit 198
    }
    if `level' <= 0 | `level' >= 1 {
        display as error "{bf:level()} is a fraction in (0,1), e.g. 0.90"
        exit 198
    }
    if !inlist(`regime', 0, 1, 2) {
        display as error "{bf:regime()} must be 1 or 2, or omitted for both"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    if "`r1name'" == "" local r1name "regime 1"
    if "`r2name'" == "" local r2name "regime 2"

    local consfirstn = cond("`consfirst'"!="", 1, 0)
    local pooledn = cond("`pooled'"!="", 1, 0)
    local SGMAT  "`sgmat'"
    if `pooledn' & "`sgmat'" == "" {
        display as error "internal: pooled requires sgmat()"
        exit 198
    }
    if `pooledn' & `reps' > 0 {
        display as error "{bf:reps()} is not available for a smooth transition."
        display as error ""
        display as error "A band for a conditionally linear response needs the"
        display as error "model refitted in every draw, and for a smooth"
        display as error "transition that means re-estimating gamma and c -- not"
        display as error "resampling within a fixed regime split, because there"
        display as error "is no regime split. Dichotomising G at 0.5 to create"
        display as error "one would produce a band for a model you did not fit."
        display as error "The honest alternative is {bf:estat girf}, which"
        display as error "simulates the actual nonlinear system."
        exit 198
    }
    local choln  = cond("`cholesky'"=="nocholesky", 0, 1)
    local fevdn  = cond("`fevd'"!="", 1, 0)
    local wildn  = cond("`wild'"!="", 1, 0)
    local levn   = `level'
    local lagp   = `lagp'
    local hasconsn = `hasconsn'

    local yv "`yvars'"
    local k : word count `yv'
    local B1MAT "`b1mat'"
    local B2MAT "`b2mat'"

    * the companion form needs exactly p*k (+1) coefficient rows
    local want = `lagp' * `k' + `hasconsn'
    if rowsof(`B1MAT') != `want' {
        display as error "the regime coefficient matrix has `=rowsof(`B1MAT')'"
        display as error "rows but the companion form needs `want' (= lags x"
        display as error "equations, plus the constant). This fit cannot be"
        display as error "turned into a companion matrix -- most likely it was"
        display as error "fitted with extra exogenous regressors, which a"
        display as error "conditionally linear impulse response has no way to"
        display as error "propagate."
        exit 498
    }

    _tk_drop
    capture noisily mata: tk_thirf()
    if _rc {
        display as error "the impulse-response engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }

    tempname T1 T2 F1 F2 S1 S2 SP B1 B2
    matrix `T1' = __tk_irf1
    matrix `T2' = __tk_irf2
    matrix `F1' = __tk_fev1
    matrix `F2' = __tk_fev2
    matrix `S1' = __tk_irfs1
    matrix `S2' = __tk_irfs2
    matrix `SP' = __tk_irfsp
    local mod1 = __tk_irfmod1
    local mod2 = __tk_irfmod2
    local n1   = __tk_irfn1
    local n2   = __tk_irfn2
    local nn   = __tk_irfn
    capture matrix `B1' = __tk_irfb1
    local hasb1 = (_rc == 0)
    capture matrix `B2' = __tk_irfb2
    local hasb2 = (_rc == 0)
    _tk_drop

    * ------------------------------------------------ header
    display _n as text "{hline 78}"
    display as text "Regime-specific CONDITIONALLY LINEAR impulse responses"
    display as text "{hline 78}"
    display as text "  Equations" _col(30) as result "`yv'"
    display as text "  Lag order" _col(30) as result %10.0f `lagp'
    display as text "  Horizon" _col(30) as result %10.0f `horizon'
    display as text "  Shocks" _col(30) as result ///
        cond(`choln', "orthogonalised (Cholesky)", "unit innovations")
    if `choln' {
        display as text "    Cholesky ordering" _col(30) as result "`yv'"
    }
    if `n1' < . {
        display as text "  Regime sizes" _col(30) as result %6.0f `n1' ///
            as text " /" as result %6.0f `n2'
        display as text "  Innovation covariance" _col(30) as result ///
            "regime-specific"
    }
    else {
        display as text "  Innovation covariance" _col(30) as result ///
            "one Sigma for both limits"
        display as text "    (a smooth transition has no regime membership to"
        display as text "     split the residuals by, so the model's single Sigma"
        display as text "     is used for both limiting linear systems)"
    }
    display as text "{hline 78}"
    display as text "  THIS IS NOT THE IMPULSE RESPONSE OF THE THRESHOLD MODEL."
    display as text "  It is the response of a LINEAR VAR built from one regime's"
    display as text "  coefficients -- what propagation would look like if the"
    display as text "  system stayed in that regime forever. A shock large enough"
    display as text "  to cross the threshold does not do that, and the response"
    display as text "  that accounts for crossing is {bf:estat girf}, which"
    display as text "  simulates the actual nonlinear system. The two answer"
    display as text "  different questions; report which one you used."
    display as text "{hline 78}"
    display as text "  Largest eigenvalue modulus: `r1name' " as result %8.5f `mod1' ///
        as text "   `r2name' " as result %8.5f `mod2'
    if `mod1' >= 1 | `mod2' >= 1 {
        display as text ""
        display as error "  A regime has a modulus of 1 or more, so ITS conditional"
        display as error "  response DIVERGES. That is correct arithmetic, not a"
        display as error "  failure: a threshold model can be globally stationary"
        display as error "  with one locally explosive regime, and that is usually"
        display as error "  the interesting finding. Do not read the long-horizon"
        display as error "  numbers for that regime as a forecast."
    }
    display as text "{hline 78}"

    * ------------------------------------------------ the tables
    local what = cond(`fevdn', "Forecast-error variance decomposition", ///
                              "Impulse responses")
    forvalues rg = 1/2 {
        if `regime' != 0 & `regime' != `rg' continue
        if `rg' == 1 {
            local rn "`r1name'"
            local HB `hasb1'
            if `fevdn' local M "`F1'"
            else       local M "`T1'"
        }
        else {
            local rn "`r2name'"
            local HB `hasb2'
            if `fevdn' local M "`F2'"
            else       local M "`T2'"
        }
        display _n as text "`what' -- `rn'"
        display as text "{hline 78}"
        forvalues m = 1/`k' {
            local sv : word `m' of `yv'
            display as text "  shock to " as result "`sv'"
            display as text "     h" _continue
            forvalues i = 1/`k' {
                local rv : word `i' of `yv'
                display as text _col(`=8+16*`i'') %15s abbrev("`rv'", 15) _continue
            }
            display ""
            forvalues l = 0/`horizon' {
                display as text "   " as result %3.0f `l' _continue
                forvalues i = 1/`k' {
                    local c = (`i'-1)*`k' + `m'
                    display as result _col(`=8+16*`i'') %15.6f ///
                        `M'[`=`l'+1',`c'] _continue
                }
                display ""
            }
            display as text "{hline 78}"
        }
        if `HB' {
            display as text "  `=`level'*100'% percentile band from " ///
                as result `reps' as text " fixed-design bootstrap draws"
            display as text "  (the regime indicator and the regressors are held"
            display as text "   FIXED and only the residuals are resampled, so the"
            display as text "   band conditions on the regime classification --"
            display as text "   exactly what a conditionally linear response"
            display as text "   already conditions on. It therefore does NOT"
            display as text "   include uncertainty about the threshold itself,"
            display as text "   and a band that did would be wider.)"
            display as text "{hline 78}"
        }
    }

    if `fevdn' {
        display as text "  Each row sums to 1 across the shocks, by construction."
        display as text "  The decomposition is of the h-step forecast error of a"
        display as text "  system held in one regime; it is not a decomposition of"
        display as text "  the threshold model's forecast error, which depends on"
        display as text "  the probability of switching."
        display as text "{hline 78}"
    }

    * ------------------------------------------------ graph
    if "`graph'" != "" {
        tempname GA GB
        if `fevdn' {
            matrix `GA' = `F1'
            matrix `GB' = `F2'
        }
        else {
            matrix `GA' = `T1'
            matrix `GB' = `T2'
        }
        preserve
            quietly {
                clear
                local tot = `horizon' + 1
                set obs `tot'
                generate int h = _n - 1
                forvalues i = 1/`k' {
                    forvalues m = 1/`k' {
                        local c = (`i'-1)*`k' + `m'
                        generate double a`i'_`m' = .
                        generate double b`i'_`m' = .
                        forvalues l = 1/`tot' {
                            replace a`i'_`m' = `GA'[`l',`c'] in `l'
                            replace b`i'_`m' = `GB'[`l',`c'] in `l'
                        }
                    }
                }
            }
            local gl ""
            forvalues i = 1/`k' {
                forvalues m = 1/`k' {
                    local rv : word `i' of `yv'
                    local sv : word `m' of `yv'
                    twoway (line a`i'_`m' h, lcolor(navy) lwidth(medthick))    ///
                           (line b`i'_`m' h, lcolor(cranberry) lpattern(dash) ///
                                lwidth(medthick))                              ///
                        , yline(0, lcolor(gs12))                               ///
                          ytitle("`rv'") xtitle("horizon")                     ///
                          subtitle("shock to `sv'", size(small))               ///
                          name(tkirf`i'_`m', replace) nodraw legend(off)
                    local gl `gl' tkirf`i'_`m'
                }
            }
            graph combine `gl', name(tkirfall, replace)                       ///
                title("`what', conditionally linear")                         ///
                note("solid navy = `r1name'   dashed red = `r2name'")
            if `"`saving'"' != "" _tk_gsave `saving', name(tkirfall)
        restore
    }

    * ------------------------------------------------ return
    return matrix irf1  = `T1', copy
    return matrix irf2  = `T2', copy
    return matrix fevd1 = `F1', copy
    return matrix fevd2 = `F2', copy
    return matrix Sigma1 = `S1', copy
    return matrix Sigma2 = `S2', copy
    return matrix Sigma_pooled = `SP', copy
    if `hasb1' return matrix band1 = `B1', copy
    if `hasb2' return matrix band2 = `B2', copy
    return scalar maxmod1 = `mod1'
    return scalar maxmod2 = `mod2'
    return scalar N       = `nn'
    return scalar N1      = `n1'
    return scalar N2      = `n2'
    return scalar horizon = `horizon'
    return scalar k       = `k'
    return scalar lags    = `lagp'
    return scalar cholesky = `choln'
    return local  yvars   "`yv'"
    return local  object  = cond(`fevdn', "fevd", "irf")
end
