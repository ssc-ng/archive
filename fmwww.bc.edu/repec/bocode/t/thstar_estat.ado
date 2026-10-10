*! thstar_estat 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thstar / thstr.
*!   estat misspec     all three Eitrheim-Terasvirta (1996) tests at once
*!   estat nonlinear   no remaining nonlinearity
*!   estat serial      no remaining serial correlation
*!   estat constancy   parameter constancy
*!   estat transition  plot the fitted transition function
*!   estat regimeplot  data and fitted values against the transition variable
*!   estat archlm      Engle ARCH LM on the squared residuals
*!   estat mcleodli    McLeod-Li portmanteau on the squared residuals
*!   estat normality   Jarque-Bera, with its skewness and kurtosis components
*!   estat diag        archlm, mcleodli and normality in one table
*! Eitrheim & Terasvirta (1996) JoE 74:59-75, doi:10.1016/0304-4076(95)01751-8

program define thstar_estat, rclass
    version 15
    if !inlist("`e(cmd)'", "thstar", "thstr") {
        display as error "last estimates not found or not from {bf:thstar}/{bf:thstr}"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")
    if inlist("`sub'", "misspec", "nonlinear", "serial", "constancy") {
        Misspec `sub' `rest'
        * a child program's r() is discarded when the parent posts its own:
        * return add carries it up so the user actually sees r(misspec)
        return add
    }
    else if inlist("`sub'", "skeleton", "skel") {
        Skeleton `rest'
        return add
    }
    else if "`sub'" == "girf" {
        Ugirf `rest'
        return add
    }
    else if "`sub'" == "linearity" {
        Linearity `rest'
        return add
    }
    else if "`sub'" == "transition" {
        Transition `rest'
    }
    else if "`sub'" == "regimeplot" {
        Regimeplot `rest'
    }
    else if inlist("`sub'", "archlm", "mcleodli", "normality", "diag") {
        Resdiag "`sub'" `rest'
        return add
    }
    else {
        display as error "unknown {bf:estat} subcommand {bf:`sub'}"
        display as error "valid: misspec, nonlinear, serial, constancy, linearity,"
        display as error "       girf, skeleton,"
        display as error "       transition, regimeplot, archlm, mcleodli, normality,"
        display as error "       diag"
        exit 198
    }
end

* ----------------------------------------------------------------------
* ARCH / McLeod-Li / normality on the residuals. The null regressors are the
* model GRADIENT, assembled in Mata by tk_star_graddump() -- the same
* gradient the Eitrheim-Terasvirta tests use -- and handed to the shared
* worker as a matrix, so no gradient variables have to be created here.
* `estat serial' is deliberately NOT routed here: the Eitrheim-Terasvirta
* version above already is the serial-correlation test for this model.
* ----------------------------------------------------------------------
program define Resdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "diag"   local which "arch mcleodli normality"
    if "`which'" == "archlm" local which "arch"

    capture drop __tkg_*
    quietly generate byte __tkg_touse = e(sample)
    local touse __tkg_touse

    local depv  "`e(depvar)'"
    local xnames "`e(arnames)'"
    if "`xnames'" == "" local xnames "`e(indepvars)'"
    local xvars ""
    local j 0
    foreach v of local xnames {
        local ++j
        quietly generate double __tkg_x`j' = `v' if `touse'
        local xvars `xvars' __tkg_x`j'
    }
    quietly generate double __tkg_z = `e(threshold_var)' if `touse'
    local zvar __tkg_z
    local hascons = e(hascons)
    local typenum = e(typenum)
    local gammahat = e(gamma)
    local chat     = e(c)
    local c2hat    = cond(e(c2) < ., e(c2), .)
    local szhat    = e(sd_z)

    _tk_drop __tk_grad
    mata: tk_star_graddump()

    _tk_resdiag __tkg_e , touse(__tkg_touse) gradmat(__tk_grad) ///
        lags(`lags') which("`which'") model("`e(cmd)'")
    return add
    _tk_drop __tk_grad
    capture drop __tkg_*
end

* ----------------------------------------------------------------------
program define Misspec, rclass
    gettoken which 0 : 0
    syntax [, LAGS(integer 4) THVar2(varname numeric ts) ]

    tempvar touse
    quietly generate byte `touse' = e(sample)

    * rebuild the design from e(): the stored names are valid ts expressions
    local depv  "`e(depvar)'"
    local xnames "`e(arnames)'"
    if "`xnames'" == "" local xnames "`e(indepvars)'"
    local xvars ""
    foreach v of local xnames {
        tempvar xx
        quietly generate double `xx' = `v' if `touse'
        local xvars `xvars' `xx'
    }
    tempvar zv
    quietly generate double `zv' = `e(threshold_var)' if `touse'
    local zvar `zv'
    local z2var ""
    if "`thvar2'" != "" {
        tempvar z2
        quietly generate double `z2' = `thvar2' if `touse'
        local z2var `z2'
    }

    local hascons = e(hascons)
    local typenum = e(typenum)
    local gammahat = e(gamma)
    local chat     = e(c)
    local c2hat    = cond(e(c2)<., e(c2), .)
    local szhat    = e(sd_z)
    local nlags    = `lags'

    mata: tk_star_estat()

    tempname M
    matrix `M' = __tk_ms
    matrix colnames `M' = F df p
    matrix rownames `M' = nonlinearity serial constancy

    display ""
    display as text "Eitrheim-Terasvirta (1996) misspecification tests after `e(cmd)'"
    display as text "{hline 74}"
    display as text "  Test" _col(38) "F" _col(50) "df" _col(58) "p-value"
    display as text "{hline 74}"
    if inlist("`which'", "misspec", "nonlinear") {
        display as text "  No remaining nonlinearity" _col(32) as result %10.4f `M'[1,1] ///
            _col(46) %6.0f `M'[1,2] _col(54) %10.4f `M'[1,3]
    }
    if inlist("`which'", "misspec", "serial") {
        display as text "  No remaining serial correlation" _col(32) ///
            as result %10.4f `M'[2,1] _col(46) %6.0f `M'[2,2] _col(54) %10.4f `M'[2,3] ///
            as text "   (`lags' lags)"
    }
    if inlist("`which'", "misspec", "constancy") {
        display as text "  Parameter constancy" _col(32) as result %10.4f `M'[3,1] ///
            _col(46) %6.0f `M'[3,2] _col(54) %10.4f `M'[3,3]
    }
    display as text "{hline 74}"
    display as text "  All three are F tests of an added block in a regression of the STAR"
    display as text "  residuals on the GRADIENT of the fitted model, so they respect the"
    display as text "  orthogonality the estimates impose. Degrees of freedom are the rank"
    display as text "  increase, which matters when the transition variable is a regressor."
    if `M'[2,3] < 0.05 & inlist("`which'", "misspec", "serial") {
        display as text ""
        display as text "  {bf:Read the serial-correlation test first.} It rejects, so the"
        display as text "  dynamics are underspecified. Omitted lags masquerade as regime"
        display as text "  switching: add lags before interpreting the nonlinearity."
    }
    else if `M'[1,3] < 0.05 & inlist("`which'", "misspec", "nonlinear") {
        display as text ""
        display as text "  Remaining nonlinearity: one transition is not enough. Either a"
        display as text "  second regime (type(lstar2)) or a different transition variable."
    }
    if `M'[3,3] < 0.05 & inlist("`which'", "misspec", "constancy") {
        display as text ""
        display as text "  Parameter constancy rejects: the coefficients drift over time,"
        display as text "  which a two-regime STAR cannot represent. Consider {bf:thtv}."
    }
    return matrix misspec = `M'
    _tk_drop
end

* ----------------------------------------------------------------------
program define Transition
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local zname "`e(threshold_var)'"
    local g  = e(gamma)
    local c  = e(c)
    local sz = e(sd_z)
    local ty = e(typenum)
    tempvar zz gg
    quietly generate double `zz' = `e(threshold_var)' if e(sample)
    if `ty' == 1 {
        quietly generate double `gg' = 1/(1+exp(-`g'*(`zz'-`c')/`sz')) if e(sample)
    }
    else if `ty' == 2 {
        quietly generate double `gg' = 1-exp(-`g'*(`zz'-`c')^2/`sz'^2) if e(sample)
    }
    else {
        local c2 = e(c2)
        quietly generate double `gg' = 1/(1+exp(-`g'*(`zz'-`c')*(`zz'-`c2')/`sz'^2)) if e(sample)
    }
    if "`title'" == "" local title "Estimated transition function"
    twoway (scatter `gg' `zz', sort mcolor(navy%50) msymbol(O) msize(small)), ///
        ytitle("G(z)") xtitle("`zname'") yscale(range(0 1))                   ///
        ylabel(0(.25)1)                                                        ///
        title("`title'", size(medium))                                         ///
        subtitle("`=upper("`e(model)'")'  gamma = `=string(`g',"%7.3f")'  c = `=string(`c',"%7.4f")'", size(small)) ///
        yline(0.5, lcolor(gs10) lpattern(dash))                                ///
        xline(`c', lcolor(cranberry) lpattern(dash))                           ///
        graphregion(color(white)) plotregion(color(white))                     ///
        note("G = 0 is the lower regime, G = 1 the upper one. A steep curve is" ///
             "a sharp threshold; a flat one means gamma is weakly identified.", size(vsmall)) ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ----------------------------------------------------------------------
program define Regimeplot
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local zname "`e(threshold_var)'"
    local dv "`e(depvar)'"
    tempvar zz fit
    quietly generate double `zz' = `e(threshold_var)' if e(sample)
    quietly predict double `fit' if e(sample), xb
    if "`title'" == "" local title "Fitted values against the transition variable"
    twoway (scatter `dv' `zz' if e(sample), mcolor(navy%40) msymbol(O) msize(small)) ///
           (scatter `fit' `zz' if e(sample), mcolor(cranberry%70) msymbol(Oh) msize(small)), ///
        ytitle("`dv'") xtitle("`zname'")                                       ///
        title("`title'", size(medium))                                          ///
        legend(order(1 "observed" 2 "fitted") rows(1) position(6)               ///
               region(lstyle(none)) size(small))                                ///
        xline(`=e(c)', lcolor(black) lpattern(dash))                            ///
        graphregion(color(white)) plotregion(color(white))                      ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
* estat linearity -- the LST(1988) Taylor linearity tests in BOTH forms,
* side by side.
*
* The F form assumes the errors are homoskedastic under the null. The
* damage when they are not is specific, not generic: neglected conditional
* heteroskedasticity makes the linearity test reject a LINEAR series. So a
* rejection by the F form alone can be a GARCH effect masquerading as a
* smooth transition, and fitting a STAR model to it would be modelling the
* variance with the mean.
*
* The robust form (van Dijk, Terasvirta and Franses 2002) is Wooldridge's
* LM: regress a vector of ones on the auxiliary scores, and use no
* assumption about the error variance at all. Printing the two together is
* the point -- when they agree the rejection is about the mean, and when
* only the F form rejects, look at the variance before the transition.
* ======================================================================
program define Linearity, rclass
    version 15
    syntax [, Level(cilevel) ]

    tempname LM LR
    capture confirm matrix e(lmtest)
    if _rc {
        display as error "no linearity table stored; refit"
        exit 498
    }
    matrix `LM' = e(lmtest)
    local hasrob = 0
    capture confirm matrix e(lmtest_robust)
    if !_rc {
        matrix `LR' = e(lmtest_robust)
        local hasrob = 1
    }

    display _n as text "Linearity against smooth transition: the Taylor LM tests"
    display as text "{hline 78}"
    display as text "                  homoskedastic F form        heteroskedasticity-robust"
    display as text "  hypothesis        stat    df       p          stat    df       p"
    display as text "{hline 78}"
    local rn : rownames `LM'
    forvalues i = 1/4 {
        local r : word `i' of `rn'
        if `hasrob' {
            display as text "  " %-12s "`r'" ///
                as result %9.3f `LM'[`i',1] %6.0f `LM'[`i',2] %8.4f `LM'[`i',3] ///
                as text "   " ///
                as result %9.3f `LR'[`i',1] %6.0f `LR'[`i',2] %8.4f `LR'[`i',3]
        }
        else {
            display as text "  " %-12s "`r'" ///
                as result %9.3f `LM'[`i',1] %6.0f `LM'[`i',2] %8.4f `LM'[`i',3]
        }
    }
    display as text "{hline 78}"
    display as text "  LM3 is linearity against the whole third-order Taylor"
    display as text "  expansion. H04, H03 and H02 are the Terasvirta sequence"
    display as text "  used to choose the transition: reject H03 most strongly"
    display as text "  and the transition is ESTAR, otherwise LSTAR."

    if `hasrob' {
        local pf = `LM'[1,3]
        local pr = `LR'[1,3]
        display as text ""
        if `pf' < 0.05 & `pr' >= 0.05 {
            display as error "  WARNING. The F form rejects linearity and the robust"
            display as error "  form does not. That pattern is what neglected"
            display as error "  conditional heteroskedasticity looks like: the"
            display as error "  rejection may be about the VARIANCE, not the mean."
            display as text  "  Run {bf:estat archlm} before fitting a transition to"
            display as text  "  this series, and if there is ARCH, model it first."
        }
        else if `pf' >= 0.05 & `pr' < 0.05 {
            display as text "  The robust form rejects and the F form does not."
            display as text "  The F form is the less reliable of the two here,"
            display as text "  since it is the one carrying an assumption. Treat"
            display as text "  the robust result as the finding."
        }
        else if `pf' < 0.05 & `pr' < 0.05 {
            display as text "  Both forms reject. The nonlinearity is in the mean,"
            display as text "  and does not rest on the homoskedasticity"
            display as text "  assumption."
        }
        else {
            display as text "  Neither form rejects linearity at 5%."
        }
        * the two degree-of-freedom columns must agree: both count the RANK
        * increase of the auxiliary block, not its column count, which is
        * what keeps the self-exciting case honest
        local dfbad = 0
        forvalues i = 1/4 {
            if `LM'[`i',2] != `LR'[`i',2] local dfbad = 1
        }
        if `dfbad' {
            display as error "  NOTE: the two forms report different degrees of"
            display as error "  freedom, which should not happen -- both count the"
            display as error "  rank increase of the auxiliary block."
        }
    }

    return matrix lmtest = `LM', copy
    if `hasrob' return matrix lmtest_robust = `LR', copy
    return scalar p_LM3 = `LM'[1,3]
    if `hasrob' return scalar p_LM3_robust = `LR'[1,3]
end

* ======================================================================
* estat girf -- the generalised impulse response of Koop, Pesaran and
* Potter (1996) for a UNIVARIATE threshold model.
*
* A nonlinear model has no single impulse response. The response depends on
* the HISTORY the shock arrives into, on the SIGN of the shock, and on its
* SIZE -- responses do not scale. So the object simulated here is
*
*   GIRF(h, delta, omega) = E[y_t+h | e_t = delta, omega] - E[y_t+h | omega]
*
* with both expectations simulated and the two paths sharing the SAME
* future shocks. Without those common random numbers the difference of two
* independent averages would be swamped by Monte Carlo error.
*
* Three responses are reported together, and the comparison is the point:
* the response to +delta, the response to -delta, and the response split by
* the regime the shock arrives into. In a LINEAR model the first two would
* be exact mirror images and the last two identical. Where they are not,
* that difference IS the nonlinearity.
* ======================================================================
program define Ugirf, rclass
    version 15
    syntax [, SIZE(real 1) Horizon(integer 12) REPS(integer 200)       ///
              HISTories(integer 150) BOOT(string) SEED(string)          ///
              GRaph SAVing(string asis) * ]

    if `horizon' < 1 {
        display as error "horizon() must be at least 1"
        exit 198
    }
    if `reps' < 20 {
        display as error "reps() below 20 cannot average out the shock draws"
        exit 198
    }
    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "normal") {
        display as error "boot() must be resample or normal"
        exit 198
    }
    local boottype `boot'
    if "`seed'" != "" set seed `seed'

    local depv  "`e(depvar)'"
    local hascons = e(hascons)
    tempvar touse
    quietly generate byte `touse' = e(sample)

    * ---- which model, and its pieces
    tempname BB
    matrix `BB' = e(b)
    local kindn = .
    if inlist("`e(cmd)'", "thtar") & "`e(model)'" != "setar_continuous" {
        local kindn 1
    }
    if inlist("`e(cmd)'", "thstar", "thstr") local kindn 2
    if `kindn' == . {
        display as error "{bf:estat girf} is for {bf:thtar} (SETAR) and"
        display as error "{bf:thstar} (STAR). After {bf:thtar, continuous}"
        display as error "the model is a kink, not a regime switch, and its"
        display as error "response is not computed here."
        exit 198
    }

    * ---- the delay must be a MODEL lag, or the system cannot simulate its
    *      own transition variable forward and the GIRF is not defined
    local delayn = e(delay)
    if `delayn' >= . | `delayn' <= 0 {
        display as error "{bf:estat girf} needs a self-exciting model: the"
        display as error "transition variable must be a lag of the dependent"
        display as error "variable, so that the simulation can compute it"
        display as error "forward. This fit used an exogenous threshold"
        display as error "variable, whose future path is unknown, and"
        display as error "freezing it would answer a different question."
        exit 198
    }

    local arl "`e(arlags)'"
    if "`arl'" == "" {
        display as error "{bf:e(arlags)} is empty; refit"
        exit 498
    }
    local maxlag = 0
    foreach L of local arl {
        if `L' > `maxlag' local maxlag = `L'
    }
    if `delayn' > `maxlag' {
        display as error "the delay (`delayn') exceeds the largest"
        display as error "autoregressive lag (`maxlag'), so the transition"
        display as error "variable is not part of the state the model"
        display as error "propagates and cannot be simulated forward."
        exit 198
    }

    * ---- the coefficient matrix, one row per regime (SETAR) or the linear
    *      and transition blocks (STAR), columns in the order the simulator
    *      builds its regressor row: the ar() lags then the constant
    local nl : word count `arl'
    local kw = `nl' + `hascons'
    tempname UB
    if `kindn' == 1 {
        local nreg = e(k_regime)
        local nrow = colsof(`BB')/`kw'
        matrix `UB' = J(`nrow', `kw', 0)
        forvalues r = 1/`nrow' {
            forvalues j = 1/`kw' {
                matrix `UB'[`r',`j'] = `BB'[1, (`r'-1)*`kw' + `j']
            }
        }
        tempname GG
        capture confirm matrix e(gammas)
        if !_rc  matrix `GG' = e(gammas)
        else {
            matrix `GG' = J(1,1,0)
            matrix `GG'[1,1] = e(gamma)
        }
        local gammav = e(gamma)
        local c1v = 0
        local c2v = 0
        local typen = 1
        local szv = 1
    }
    else {
        matrix `UB' = J(2, `kw', 0)
        forvalues j = 1/`kw' {
            matrix `UB'[1,`j'] = `BB'[1, `j']
            matrix `UB'[2,`j'] = `BB'[1, `kw' + `j']
        }
        tempname GG
        matrix `GG' = J(1,1,0)
        local gammav = e(gamma)
        local c1v  = e(c)
        local c2v  = cond(e(c2) < ., e(c2), 0)
        local typen = e(typenum)
        local szv  = cond(e(zscale) < ., e(zscale), 1)
        matrix `GG'[1,1] = `c1v'
    }

    * ---- the lag list as a matrix for the engine
    tempname LAGS
    matrix `LAGS' = J(1, `nl', 0)
    local j 0
    foreach L of local arl {
        local ++j
        matrix `LAGS'[1,`j'] = `L'
    }

    * ---- the residuals: the shock pool
    tempvar resv
    capture quietly predict double `resv' if `touse', residuals
    if _rc {
        display as error "could not recover the residuals for the shock pool"
        exit 498
    }
    quietly replace `touse' = 0 if missing(`resv')

    local deltav = `size'
    matrix __tk_ugB    = `UB'
    matrix __tk_uglags = `LAGS'
    matrix __tk_uggam  = `GG'
    local maxhist = `histories'
    local resvar "`resv'"

    mata: tk_thugirf()

    if __tk_ugfail == 1 {
        _tk_drop
        display as error "the residual standard deviation is zero or missing"
        exit 498
    }
    if __tk_ugfail == 2 {
        _tk_drop
        display as error "too few usable histories to average over"
        exit 498
    }

    tempname G N1 N2 NH SIG
    matrix `G' = __tk_uggirf
    scalar `N1' = __tk_ugn1
    scalar `N2' = __tk_ugn2
    scalar `NH' = __tk_ugnh
    scalar `SIG' = __tk_ugsig
    _tk_drop
    matrix colnames `G' = h pos neg regime1 regime2

    display _n as text "Generalised impulse response (Koop-Pesaran-Potter)"
    display as text "{hline 74}"
    display as text "  shock size" _col(50) as result %20.4f `deltav'
    display as text "  residual s.d. for comparison" _col(50) as result %20.4f `SIG'
    display as text "  horizons" _col(50) as result %20.0f `horizon'
    display as text "  replications per history" _col(50) as result %20.0f `reps'
    display as text "  histories averaged" _col(50) as result %20.0f `NH'
    display as text "    of which regime 1 / regime 2" _col(50) ///
        as result %10.0f `N1' %10.0f `N2'
    display as text "  shock pool" _col(50) as result %20s "`boot'"
    display as text "{hline 74}"
    display as text "     h      to +delta     to -delta    from reg 1    from reg 2"
    display as text "{hline 74}"
    forvalues i = 1/`=rowsof(`G')' {
        display as text %6.0f `G'[`i',1] ///
            as result %14.6f `G'[`i',2] %14.6f `G'[`i',3] ///
            %14.6f `G'[`i',4] %14.6f `G'[`i',5]
    }
    display as text "{hline 74}"
    display as text "  {bf:Read the columns against each other, not alone.}"
    display as text "  In a LINEAR model the first two would be exact mirror"
    display as text "  images and the last two identical. Where they are not,"
    display as text "  that difference IS the nonlinearity, and it is the only"
    display as text "  part of this table a linear model could not produce."
    display as text ""
    display as text "  Responses here do NOT scale: the answer to a shock of"
    display as text "  2 sigma is not twice the answer to 1 sigma. Report the"
    display as text "  size you used, and if the conclusion matters, report"
    display as text "  more than one."

    return matrix girf = `G', copy
    return scalar size     = `deltav'
    return scalar horizon  = `horizon'
    return scalar reps     = `reps'
    return scalar n_hist   = `NH'
    return scalar n_hist1  = `N1'
    return scalar n_hist2  = `N2'
    return scalar sigma    = `SIG'
    return local  boot     "`boottype'"

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `G', names(gi)
                keep if gi1 < .
            }
            twoway (line gi2 gi1, lcolor(navy) lwidth(medthick))           ///
                   (line gi3 gi1, lcolor(cranberry) lpattern(dash))        ///
                   (line gi4 gi1, lcolor(forest_green) lpattern(shortdash)) ///
                   (line gi5 gi1, lcolor(orange) lpattern(longdash))       ///
                 , yline(0, lcolor(gs10))                                  ///
                   xtitle("horizon") ytitle("response")                    ///
                   title("Generalised impulse response")                   ///
                   subtitle("shock size `=string(`deltav',"%6.3f")'", size(small)) ///
                   legend(order(1 "+delta" 2 "-delta" 3 "from regime 1"    ///
                                4 "from regime 2") rows(2) size(small))    ///
                   `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
* estat skeleton -- the DETERMINISTIC SKELETON of the fitted model, its
* per-regime roots, and the limit cycle it settles into if it has one.
*
*   Tong and Lim (1980) JRSS-B 42:245-292,
*     doi:10.1111/j.2517-6161.1980.tb01126.x
*
* The skeleton is the model iterated forward with the errors set to ZERO.
* It is the model's own dynamics with the noise stripped out, and it is
* where the interesting nonlinear behaviour lives: a threshold model can
* settle to a point, cycle forever between a few values, or diverge, and
* which of those it does is a property of the coefficients that no amount of
* staring at the coefficient table reveals.
*
* THREE THINGS THIS REPORTS, AND WHY EACH MATTERS
*
* 1. The per-regime roots. Each regime is a linear AR, so it has its own
*    companion eigenvalues. A regime with a modulus of 1 or more is LOCALLY
*    EXPLOSIVE -- and that is not a defect of the fit: a threshold model can
*    be globally stationary with an explosive inner regime, because the
*    system is thrown out of it before it can run away. Reporting the roots
*    without saying this invites the reader to conclude the model is broken.
*
* 2. The skeleton's long-run behaviour, found by iterating. A FIXED POINT
*    means the deterministic model converges; a LIMIT CYCLE of period k
*    means it settles into k repeating values and never converges. Tong's
*    whole point was that threshold models produce limit cycles, which a
*    linear model cannot.
*
* 3. The half-life of a shock, measured on the skeleton from each regime
*    separately. In a linear model the half-life is one number. In a
*    threshold model it is not, and the difference between the regimes is
*    usually the economically interesting quantity.
*
* The skeleton is NOT a forecast. Clements and Smith (1997) show the
* deterministic path differs from E[y_t+h] for a nonlinear model, and the
* gap does not shrink with the sample. For forecasts use thforecast, which
* says the same thing in its own output.
* ======================================================================
program define Skeleton, rclass
    version 15
    syntax [, Horizon(integer 60) TOLerance(real 1e-8) MAXCycle(integer 24) ///
              START(numlist) GRaph SAVing(string asis) * ]

    if `horizon' < 10 {
        display as error "horizon() must be at least 10 for the skeleton to"
        display as error "settle"
        exit 198
    }

    local depv  "`e(depvar)'"
    local arl   "`e(arlags)'"
    local hascons = e(hascons)
    local delayn  = e(delay)

    local kindn = .
    if "`e(cmd)'" == "thtar" & "`e(model)'" != "setar_continuous" local kindn 1
    if inlist("`e(cmd)'", "thstar", "thstr") local kindn 2
    if `kindn' == . {
        display as error "{bf:estat skeleton} is for {bf:thtar} (SETAR) and"
        display as error "{bf:thstar} (STAR)."
        exit 198
    }
    if "`arl'" == "" | `delayn' >= . | `delayn' <= 0 {
        display as error "{bf:estat skeleton} needs a self-exciting model:"
        display as error "the transition variable must be a lag of the"
        display as error "dependent variable, or there is no autonomous"
        display as error "recursion to iterate."
        exit 198
    }

    local nl : word count `arl'
    local maxlag = 0
    foreach L of local arl {
        if `L' > `maxlag' local maxlag = `L'
    }
    local kw = `nl' + `hascons'

    * ---- the coefficient matrix in the simulator's column order
    tempname BB UB LAGS GG
    matrix `BB' = e(b)
    if `kindn' == 1 {
        local nrow = colsof(`BB')/`kw'
        matrix `UB' = J(`nrow', `kw', 0)
        forvalues r = 1/`nrow' {
            forvalues j = 1/`kw' {
                matrix `UB'[`r',`j'] = `BB'[1, (`r'-1)*`kw' + `j']
            }
        }
        matrix `GG' = J(1,1,0)
        matrix `GG'[1,1] = e(gamma)
        local gammav = e(gamma)
        local c1v = 0
        local c2v = 0
        local typen = 1
        local szv = 1
    }
    else {
        matrix `UB' = J(2, `kw', 0)
        forvalues j = 1/`kw' {
            matrix `UB'[1,`j'] = `BB'[1, `j']
            matrix `UB'[2,`j'] = `BB'[1, `kw' + `j']
        }
        matrix `GG' = J(1,1,0)
        local gammav = e(gamma)
        local c1v  = e(c)
        local c2v  = cond(e(c2) < ., e(c2), 0)
        local typen = e(typenum)
        local szv  = cond(e(zscale) < ., e(zscale), 1)
        matrix `GG'[1,1] = `c1v'
    }
    matrix `LAGS' = J(1, `nl', 0)
    local j 0
    foreach L of local arl {
        local ++j
        matrix `LAGS'[1,`j'] = `L'
    }

    * ---- starting value: the user's, or the sample mean of the series
    if "`start'" == "" {
        quietly summarize `depv' if e(sample), meanonly
        local y0 = r(mean)
        local startsrc "the sample mean"
    }
    else {
        local y0 : word 1 of `start'
        local startsrc "user supplied"
    }

    matrix __tk_skB    = `UB'
    matrix __tk_sklags = `LAGS'
    matrix __tk_skgam  = `GG'
    local maxlagn = `maxlag'

    mata: tk_thskel()

    if __tk_skfail == 1 {
        _tk_drop
        display as error "the coefficient matrix could not be read"
        exit 498
    }

    tempname PATH ROOTS FIX CYC MOD1 MOD2 HL1 HL2 DIV
    matrix `PATH'  = __tk_skpath
    matrix `ROOTS' = __tk_skroots
    scalar `FIX'  = __tk_skfix
    scalar `CYC'  = __tk_skcyc
    scalar `MOD1' = __tk_skmod1
    scalar `MOD2' = __tk_skmod2
    scalar `HL1'  = __tk_skhl1
    scalar `HL2'  = __tk_skhl2
    scalar `DIV'  = __tk_skdiv
    _tk_drop
    matrix colnames `PATH'  = t y
    matrix colnames `ROOTS' = regime modulus

    display _n as text "Deterministic skeleton of the fitted model"
    display as text "{hline 72}"
    display as text "  iterated from" _col(46) as result %24s "`startsrc'"
    display as text "  starting value" _col(46) as result %24.6f `y0'
    display as text "  horizons iterated" _col(46) as result %24.0f `horizon'
    display as text "{hline 72}"
    display as text "  largest root modulus, regime 1" _col(46) ///
        as result %24.6f `MOD1'
    display as text "  largest root modulus, regime 2" _col(46) ///
        as result %24.6f `MOD2'
    display as text "{hline 72}"

    if `DIV' == 1 {
        display as error "  The skeleton DIVERGES from this starting value."
        display as text  "  That does not by itself mean the model is"
        display as text  "  misspecified: a threshold model can be globally"
        display as text  "  stationary with a locally explosive regime,"
        display as text  "  because the system is thrown out of that regime"
        display as text  "  before it can run away. But check the regime"
        display as text  "  moduli above, and try other starting values with"
        display as text  "  {bf:start()} -- divergence from every start is a"
        display as text  "  different matter from divergence from one."
    }
    else if `CYC' > 1 {
        display as text "  The skeleton settles into a {bf:LIMIT CYCLE} of"
        display as text "  period " as result `CYC' as text "."
        display as text ""
        display as text "  This is what Tong's work was about, and a linear"
        display as text "  model CANNOT produce it: the deterministic path"
        display as text "  does not converge to a point but repeats " ///
            as result `CYC' as text " values"
        display as text "  forever. If your series shows persistent cycles"
        display as text "  that a linear model fits only with a long lag"
        display as text "  structure, this is the mechanism to report."
    }
    else if `FIX' < . {
        display as text "  The skeleton converges to a {bf:FIXED POINT} at"
        display as text "  y = " as result %12.6f `FIX'
        display as text ""
        display as text "  The deterministic model settles, so the series'"
        display as text "  movement comes from the shocks rather than from"
        display as text "  the model's own dynamics."
    }
    else {
        display as text "  The skeleton neither converged nor closed a cycle"
        display as text "  within `horizon' steps and did not diverge. Raise"
        display as text "  {bf:horizon()} or {bf:maxcycle()}; a long cycle"
        display as text "  needs both."
    }

    display as text "{hline 72}"
    display as text "  half-life of a shock on the skeleton:"
    if `HL1' < . display as text "    starting in regime 1" _col(46) ///
        as result %24.2f `HL1'
    else         display as text "    starting in regime 1" _col(46) ///
        as result %24s "does not halve"
    if `HL2' < . display as text "    starting in regime 2" _col(46) ///
        as result %24.2f `HL2'
    else         display as text "    starting in regime 2" _col(46) ///
        as result %24s "does not halve"
    display as text "{hline 72}"
    display as text "  In a LINEAR model the half-life is one number. Here it"
    display as text "  is not, and the difference between the regimes is"
    display as text "  usually the economically interesting quantity -- it is"
    display as text "  how long the system takes to forget a shock depending"
    display as text "  on where it was when the shock arrived."
    display as text ""
    display as text "  {bf:The skeleton is not a forecast.} Clements and Smith"
    display as text "  (1997) show the deterministic path differs from"
    display as text "  E[y(t+h)] for a nonlinear model, and the gap does not"
    display as text "  shrink with the sample. Use {helpb thforecast} for"
    display as text "  forecasts; it simulates, and says so."

    return matrix path  = `PATH', copy
    return matrix roots = `ROOTS', copy
    return scalar modulus1 = `MOD1'
    return scalar modulus2 = `MOD2'
    return scalar fixedpoint = `FIX'
    return scalar cycle    = `CYC'
    return scalar halflife1 = `HL1'
    return scalar halflife2 = `HL2'
    return scalar diverges = `DIV'
    return scalar start    = `y0'

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `PATH', names(sk)
                keep if sk1 < .
            }
            twoway (line sk2 sk1, lcolor(navy) lwidth(medthick))     ///
                 , xtitle("iteration") ytitle("`depv'")              ///
                   title("Deterministic skeleton")                   ///
                   subtitle(`"`=cond(`CYC'>1, "limit cycle of period " + string(`CYC'), cond(`DIV'==1, "diverges", "converges to a fixed point"))'"', size(small)) ///
                   `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end
