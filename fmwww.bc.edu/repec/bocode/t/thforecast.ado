*! thforecast 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Multi-step forecasts from a fitted threshold autoregression.
*! Clements, M. P. and J. Smith (1997) International Journal of Forecasting
*!   13:463-475, doi:10.1016/S0169-2070(97)00017-4
*! Tong (1990) for the deterministic skeleton
*!
*! Works after thtar (SETAR, any number of regimes) and after thstar (smooth
*! transition). It needs the threshold variable to be a lag of the series
*! being forecast, because the future regime has to be computable from the
*! forecast path itself.

program define thforecast, rclass sortpreserve
    version 15

    syntax [anything(name=stub)] [, Horizon(integer 12)   ///
          METHod(string)                                  ///
          REPS(integer 1000)                              ///
          SEED(string)                                    ///
          Level(numlist min=1 max=3 >0 <100 sort)         ///
          GRaph                                           ///
          SAVing(string asis)                             ///
          REPLACE                                         ///
          NOSKELeton ]

    * ------------------------------------------------ what was fitted?
    local ecmd "`e(cmd)'"
    if !inlist("`ecmd'", "thtar", "thstar") {
        display as error "{bf:thforecast} works after {bf:thtar} or {bf:thstar};"
        display as error "the last estimates are from " ///
            cond("`ecmd'"=="", "nothing", "{bf:`ecmd'}")
        if "`ecmd'" == "thstr" {
            display as error "{bf:thstr} is a cross-sectional smooth transition"
            display as error "regression: there is no lag structure and no time"
            display as error "index to iterate, so there is nothing to forecast"
            display as error "dynamically. Use {bf:predict} for fitted values."
        }
        if inlist("`ecmd'", "thtvar", "thstvar", "thtvecm") {
            display as error "for a system, simulate with {bf:estat girf} instead:"
            display as error "a multivariate forecast needs every equation's own"
            display as error "future path, which is a different object"
        }
        exit 301
    }
    if `horizon' < 1 {
        display as error "{bf:horizon()} must be 1 or more"
        exit 198
    }
    if `reps' < 1 {
        display as error "{bf:reps()} must be 1 or more"
        exit 198
    }
    if "`method'" == "" local method bootstrap
    local method = lower("`method'")
    if !inlist("`method'", "bootstrap", "montecarlo", "skeleton") {
        display as error "{bf:method()} must be bootstrap, montecarlo or skeleton"
        exit 198
    }
    local methodn = cond("`method'"=="skeleton", 0, ///
                    cond("`method'"=="montecarlo", 1, 2))
    if "`level'" == "" local level 95
    local levlist "`level'"
    local nlev : word count `levlist'
    if "`seed'" != "" set seed `seed'

    local depv "`e(depvar)'"
    local tv   "`e(timevar)'"
    if "`tv'" == "" {
        capture tsset
        local tv "`r(timevar)'"
    }
    if "`tv'" == "" {
        display as error "no time variable: the fit must come from {bf:tsset} data"
        exit 459
    }

    * ------------------------------------------------ the threshold variable
    * must be a lag of depvar, so that the future regime is computable
    local thv "`e(threshold_var)'"
    local delayn = 0
    if "`ecmd'" == "thtar" {
        if "`e(model)'" == "setar" local delayn = e(delay)
    }
    else if e(delay) < . {
        local delayn = e(delay)
    }
    if `delayn' == 0 {
        * fall back to parsing e(threshold_var), for a fit made before the
        * commands started storing e(delay)
        * parse L#.depvar out of e(threshold_var)
        if regexm("`thv'", "^L([0-9]+)\.(.+)$") {
            if "`=regexs(2)'" == "`depv'" local delayn = real(regexs(1))
        }
        else if regexm("`thv'", "^L\.(.+)$") {
            if "`=regexs(1)'" == "`depv'" local delayn = 1
        }
    }
    if `delayn' <= 0 {
        display as error "the threshold variable is {bf:`thv'}, which is not a"
        display as error "lag of {bf:`depv'}."
        display as error ""
        display as error "A dynamic forecast has to know the regime at every"
        display as error "future date, so the threshold variable must be"
        display as error "computable from the forecast path itself. With an"
        display as error "exogenous threshold variable the future regime depends"
        display as error "on that variable's own future path, which is not"
        display as error "available here. Either refit with a self-exciting"
        display as error "threshold -- {bf:thtar} without {bf:thvar()}, or"
        display as error "{bf:thstar} with {bf:delay()} -- or forecast the"
        display as error "threshold variable with its own model and condition on"
        display as error "that path by hand. Substituting its last observed value"
        display as error "would be a forecast of a different model, so this"
        display as error "command will not do it silently."
        exit 198
    }

    * ------------------------------------------------ the lag structure
    local laglist "`e(arlags)'"
    if "`laglist'" == "" {
        display as error "{bf:e(arlags)} is empty: cannot rebuild the recursion"
        exit 498
    }
    local nl : word count `laglist'
    local pmax 0
    foreach L of local laglist {
        if `L' > `pmax' local pmax = `L'
    }

    * ------------------------------------------------ the coefficient blocks
    tempname b BMAT GAMS
    matrix `b' = e(b)
    local kindn 0
    local hasconsn 0
    local gamlist ""
    local gamman .
    local c1n .
    local c2n .
    local typen .
    local szn .

    if "`ecmd'" == "thtar" {
        local kindn 1
        local nreg = e(k_regime)
        local kreg = colsof(`b') / `nreg'
        local hasconsn = cond(`kreg' > `nl', 1, 0)
        matrix `BMAT' = J(`nreg', `kreg', .)
        forvalues j = 1/`nreg' {
            forvalues i = 1/`kreg' {
                matrix `BMAT'[`j',`i'] = `b'[1, `=(`j'-1)*`kreg' + `i'']
            }
        }
        * the thresholds travel as a MATRIX, never as a macro list: a
        * %18.0g round-trip can cost the last bit of a threshold, and the
        * threshold is itself an observed value of the series
        local hasth 0
        capture confirm matrix e(thresholds)
        if !_rc {
            matrix `GAMS' = e(thresholds)
            local hasth 1
        }
        if !`hasth' matrix `GAMS' = J(1, 1, e(gamma))
        local gamlist "`GAMS'"
    }
    else {
        local kindn 2
        local kreg = `nl' + 1
        * e(b) is Linear block, then Transition block, then gamma c [c2]
        local ncb = colsof(`b')
        local hasconsn = e(hascons)
        local kreg = `nl' + `hasconsn'
        matrix `BMAT' = J(2, `kreg', .)
        forvalues i = 1/`kreg' {
            matrix `BMAT'[1,`i'] = `b'[1,`i']
            matrix `BMAT'[2,`i'] = `b'[1, `=`kreg' + `i'']
        }
        local gamman = e(gamma)
        local c1n    = e(c)
        local c2n    = cond(e(c2) < ., e(c2), 0)
        local typen  = e(typenum)
        local szn    = e(sd_z)
    }

    * ------------------------------------------------ residuals and sigma
    tempvar ehatvar esamp
    quietly generate byte `esamp' = e(sample)
    capture quietly predict double `ehatvar' if `esamp', residuals
    if _rc {
        display as error "could not obtain residuals from {bf:`ecmd'}"
        exit _rc
    }
    local nres = e(N)
    local sigman = sqrt(e(ssr)/e(N))

    * ------------------------------------------------ the engine
    tempvar touse
    quietly generate byte `touse' = `esamp'
    * the recursion reads the last observations in DATASET order, so they have
    * to be in time order; tsset data normally are, but not after a user sort
    sort `tv'
    _tk_drop
    capture noisily mata: tk_thforecast()
    if _rc {
        display as error "the forecast engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }
    if __tk_fcfail == 1 {
        display as error "fewer observations than the recursion needs"
        _tk_drop
        exit 2001
    }

    tempname BAND SHARE SKEL HIST
    matrix `BAND'  = __tk_fcband
    matrix `SHARE' = __tk_fcshare
    matrix `SKEL'  = __tk_fcskel
    matrix `HIST'  = __tk_fchist
    local npath = __tk_fcnpath
    local nhist = __tk_fcnhist
    local nresu = __tk_fcnres
    _tk_drop

    * ------------------------------------------------ display
    display _n as text "Multi-step forecasts from " as result "`ecmd'" ///
        _col(48) as text "horizon = " as result %4.0f `horizon'
    display as text "{hline 78}"
    display as text "  Series" _col(34) as result "`depv'"
    display as text "  Model" _col(34) as result ///
        cond(`kindn'==1, "SETAR, `=e(k_regime)' regime(s)", "smooth transition (`e(model)')")
    display as text "  Threshold variable" _col(34) as result "`thv'" ///
        as text "   (delay " as result `delayn' as text ")"
    display as text "  AR lags" _col(34) as result "`laglist'"
    display as text "  Method" _col(34) as result "`method'" _continue
    if `methodn' == 0 display as text "   (one path, no shocks)"
    else display as text "   " as result `npath' as text " paths"
    if `methodn' == 2 {
        display as text "  Residuals resampled" _col(34) as result `nresu' ///
            as text "   (centred)"
    }
    if `methodn' == 1 {
        display as text "  sigma-hat" _col(34) as result %12.6f `sigman'
    }
    display as text "{hline 78}"

    display as text "     h" _col(12) "forecast" _col(26) "median" ///
        _col(38) "s.d." _col(50) "regime-1 share"
    display as text "{hline 78}"
    forvalues j = 1/`horizon' {
        display as text "   " as result %3.0f `j' ///
            _col(8) %14.6f `BAND'[`j',1] _col(22) %12.6f `BAND'[`j',2] ///
            _col(34) %12.6f `BAND'[`j',3] _col(50) %12.4f `BAND'[`j',4]
    }
    display as text "{hline 78}"
    if `kindn' == 2 {
        display as text "  The last column is the average weight the transition"
        display as text "  function puts on the LOWER block: a smooth transition has"
        display as text "  no regime to count, and this is what actually drives the"
        display as text "  forecast."
    }
    else {
        display as text "  The last column is the share of simulated paths in"
        display as text "  regime 1 at that horizon. If it is 0 or 1 at every"
        display as text "  horizon, the threshold is not doing anything to this"
        display as text "  forecast and a linear model would have said the same."
    }
    display as text "{hline 78}"

    * the bands
    forvalues i = 1/`nlev' {
        local lv : word `i' of `levlist'
        display _n as text "  `lv'% forecast interval"
        display as text "{hline 50}"
        display as text "     h" _col(16) "lower" _col(34) "upper"
        display as text "{hline 50}"
        forvalues j = 1/`horizon' {
            display as text "   " as result %3.0f `j' ///
                _col(10) %14.6f `BAND'[`j',`=4+2*`i'-1'] ///
                _col(28) %14.6f `BAND'[`j',`=4+2*`i'']
        }
        display as text "{hline 50}"
    }
    if `methodn' == 0 {
        display as text "  No interval is reported for {bf:method(skeleton)}: it is"
        display as text "  a single deterministic path, not a distribution."
    }
    else {
        display as text "  These are EMPIRICAL quantiles of the simulated paths, not"
        display as text "  point forecast +/- z*s.d. A threshold model's forecast"
        display as text "  density can be skewed or bimodal, in which case a"
        display as text "  symmetric interval is wrong in both directions."
    }

    * the skeleton comparison, which is the paper's point
    if "`noskeleton'" == "" & `methodn' != 0 {
        display _n as text "  Why not just iterate the model with zero errors?"
        display as text "{hline 78}"
        display as text "     h" _col(14) "simulated" _col(30) "skeleton" ///
            _col(46) "difference"
        display as text "{hline 78}"
        local maxgap 0
        forvalues j = 1/`horizon' {
            local d = `BAND'[`j',1] - `SKEL'[`j',1]
            if abs(`d') > abs(`maxgap') local maxgap = `d'
            display as text "   " as result %3.0f `j' ///
                _col(8) %14.6f `BAND'[`j',1] _col(24) %14.6f `SKEL'[`j',1] ///
                _col(40) %14.6f `d'
        }
        display as text "{hline 78}"
        display as text "  The skeleton is what the model does with NO further"
        display as text "  shocks. For a linear model it equals the conditional"
        display as text "  expectation; for a threshold model it does not, because"
        display as text "  E[f(y)] is not f(E[y]) when f bends. The largest gap here"
        display as text "  is " as result %10.6f `maxgap' as text ", and it does not shrink with the"
        display as text "  sample: it is the wrong object, not sampling error."
        display as text "  Clements and Smith (1997) show the gap is big enough to"
        display as text "  reverse forecast-accuracy rankings."
        return scalar skel_gap = `maxgap'
    }

    * ------------------------------------------------ save to variables
    if `"`stub'"' != "" {
        local sv : word 1 of `stub'
        capture confirm new variable `sv'
        if _rc & "`replace'" == "" {
            display as error "variable {bf:`sv'} already exists; use {bf:replace}"
            exit 110
        }
        capture drop `sv'
        capture drop `sv'_lo
        capture drop `sv'_hi
        quietly generate double `sv'    = .
        quietly generate double `sv'_lo = .
        quietly generate double `sv'_hi = .
        quietly summarize `tv' if `esamp', meanonly
        local tlast = r(max)
        capture tsset
        local td = r(tdelta)
        if "`td'" == "" | `td' <= 0 local td 1
        forvalues j = 1/`horizon' {
            local tj = `tlast' + `j' * `td'
            quietly count if `tv' == `tj'
            if r(N) == 0 continue
            quietly replace `sv'    = `BAND'[`j',1] if `tv' == `tj'
            quietly replace `sv'_lo = `BAND'[`j',5] if `tv' == `tj'
            quietly replace `sv'_hi = `BAND'[`j',6] if `tv' == `tj'
        }
        label variable `sv'    "`method' forecast of `depv'"
        label variable `sv'_lo "lower `: word 1 of `levlist''% bound"
        label variable `sv'_hi "upper `: word 1 of `levlist''% bound"
        quietly count if `sv' < .
        display _n as text "  Forecasts written to " as result ///
            "`sv'" as text ", " as result "`sv'_lo" as text ", " ///
            as result "`sv'_hi" as text " for " as result r(N) ///
            as text " of `horizon' periods."
        if r(N) < `horizon' {
            display as text "  The rest fall outside the dataset. Use"
            display as text "  {bf:tsappend, add(`horizon')} first to make room."
        }
    }

    * ------------------------------------------------ graph
    if "`graph'" != "" {
        Fanchart `BAND' `HIST' `horizon' `nhist' `nlev' "`levlist'" ///
            "`depv'" "`method'" `"`saving'"'
    }

    * ------------------------------------------------ return
    matrix colnames `BAND' = forecast median sd regime1_share
    local cn forecast median sd regime1_share
    forvalues i = 1/`nlev' {
        local lv : word `i' of `levlist'
        local cn "`cn' lo`lv' hi`lv'"
    }
    matrix colnames `BAND' = `cn'
    matrix colnames `SKEL' = skeleton
    return matrix forecast = `BAND', copy
    return matrix skeleton = `SKEL'
    return matrix shares   = `SHARE'
    return scalar horizon  = `horizon'
    return scalar n_paths  = `npath'
    return scalar delay    = `delayn'
    return local  method   "`method'"
    return local  depvar   "`depv'"
    return local  cmd      "thforecast"
end

* ======================================================================
program define Fanchart
    version 15
    args BAND HIST h nhist nlev levlist depv method saving
    preserve
        quietly {
            clear
            local tot = `nhist' + `h'
            set obs `tot'
            generate int step = _n - `nhist'
            generate double y = .
            forvalues i = 1/`nhist' {
                replace y = `HIST'[`i',1] in `i'
            }
            generate double f  = .
            generate double lo = .
            generate double hi = .
            forvalues j = 1/`h' {
                local r = `nhist' + `j'
                replace f  = `BAND'[`j',1] in `r'
                replace lo = `BAND'[`j',5] in `r'
                replace hi = `BAND'[`j',6] in `r'
            }
            * join the fan to the last observation so the chart is continuous
            replace f  = y[`nhist'] in `nhist'
            replace lo = y[`nhist'] in `nhist'
            replace hi = y[`nhist'] in `nhist'
        }
        local lv : word 1 of `levlist'
        twoway (rarea hi lo step, color(navy%25) lwidth(none))        ///
               (line y step, lcolor(black) lwidth(medthick))          ///
               (line f step, lcolor(navy) lpattern(dash) lwidth(medthick)) ///
            , xline(0, lcolor(gs10))                                   ///
              ytitle("`depv'") xtitle("steps ahead (0 = last observation)") ///
              title("`method' forecast with `lv'% band")               ///
              legend(order(2 "data" 3 "forecast" 1 "`lv'% band")       ///
                size(small) rows(1))
        if `"`saving'"' != "" _tk_gsave `saving'
    restore
end
