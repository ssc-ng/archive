*! thsim 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Simulate data from a USER-SPECIFIED threshold model, for size and power
*! studies, certification scripts and teaching examples.
*! Tong (1990) Non-linear Time Series, for the SETAR recursion
*! Terasvirta (1994) doi:10.1080/01621459.1994.10476462 for the STAR form
*! Hansen (2000) doi:10.1111/1468-0262.00124 for the cross-sectional form
*! Tsay (1998) doi:10.1080/01621459.1998.10473779 for the multivariate form

program define thsim, rclass
    version 15

    syntax [anything(name=stub)] , MODel(string)        ///
        [ N(integer 500)                                ///
          Burn(integer 500)                             ///
          Coef(string)                                  ///
          Coef2(string)                                 ///
          THresholds(numlist sort)                      ///
          AR(numlist integer >0 sort)                   ///
          DELay(integer 1)                              ///
          noCONStant                                    ///
          Gamma(real 5)                                 ///
          C(real 0)                                     ///
          C2(real 0)                                    ///
          TYpe(string)                                  ///
          SIGma(real 1)                                 ///
          Errors(string)                                ///
          DF(integer 5)                                 ///
          RESiduals(varname numeric)                    ///
          SMat(string)                                  ///
          LAGs(integer 1)                               ///
          K(integer 2)                                  ///
          SLope(numlist)                                ///
          TVar(string)                                  ///
          SEED(string)                                  ///
          CLEAR                                         ///
          REPLACE ]

    local model = lower("`model'")
    if !inlist("`model'", "tr", "kink", "setar", "star", "tvar") {
        display as error "{bf:model()} must be tr, kink, setar, star or tvar"
        display as error ""
        display as error "  tr     cross-sectional threshold regression"
        display as error "  kink   cross-sectional continuous (kink) regression"
        display as error "  setar  self-exciting threshold autoregression"
        display as error "  star   smooth transition autoregression"
        display as error "  tvar   two-regime threshold VAR"
        exit 198
    }
    if `n' < 10 {
        display as error "{bf:n()} must be 10 or more"
        exit 198
    }
    if `burn' < 0 {
        display as error "{bf:burn()} must be 0 or more"
        exit 198
    }
    if `burn' == 0 & inlist("`model'", "setar", "star", "tvar") {
        display as text "{bf:Warning.} {bf:burn(0)} on a recursive model."
        display as text "A threshold recursion started from zero spends its first"
        display as text "observations in whichever regime contains zero, so the"
        display as text "regime mix of a short series reflects the starting value"
        display as text "and not the model's stationary law. A size study built on"
        display as text "it reports the size of a different model. Use the default"
        display as text "{bf:burn(500)} unless you have a reason not to."
    }
    if `sigma' <= 0 {
        display as error "{bf:sigma()} must be positive"
        exit 198
    }
    if "`errors'" == "" local errors normal
    local errors = lower("`errors'")
    if !inlist("`errors'", "normal", "t", "resample") {
        display as error "{bf:errors()} must be normal, t or resample"
        exit 198
    }
    local etypen = cond("`errors'"=="normal", 1, cond("`errors'"=="t", 2, 3))
    if "`errors'" == "t" & `df' <= 2 {
        display as error "{bf:df()} must exceed 2 for a t with finite variance"
        exit 198
    }
    if "`errors'" == "resample" & "`residuals'" == "" {
        display as error "{bf:errors(resample)} needs {bf:residuals(}{it:varname}{bf:)}"
        exit 198
    }
    if "`type'" == "" local type lstar1
    local type = lower("`type'")
    if !inlist("`type'", "lstar1", "estar", "lstar2") {
        display as error "{bf:type()} must be lstar1, estar or lstar2"
        exit 198
    }
    local typen = cond("`type'"=="lstar1", 1, cond("`type'"=="estar", 2, 3))
    if "`seed'" != "" set seed `seed'
    local hasconsn = cond("`constant'"=="", 1, 0)
    local nobs  = `n'
    local burnn = `burn'
    local delayn = `delay'
    local sdn   = `sigma'
    local dfn   = `df'
    local gamman = `gamma'
    local c1n   = `c'
    local c2n   = `c2'
    local szn   = 1
    local ehvar ""
    local ehtouse ""
    if "`residuals'" != "" {
        local ehvar "`residuals'"
        tempvar ehtv
        quietly generate byte `ehtv' = !missing(`residuals')
        local ehtouse "`ehtv'"
    }

    * ================================================= cross-sectional
    if inlist("`model'", "tr", "kink") {
        if "`slope'" == "" {
            display as error "{bf:model(`model')} needs {bf:slope()}"
            if "`model'" == "tr" {
                display as error "two numbers: the slope on x below and above"
                display as error "the threshold, e.g. {bf:slope(1 -1)}"
            }
            else {
                display as error "two numbers: the slope below the kink and the"
                display as error "CHANGE in slope above it, e.g. {bf:slope(1 -2)}"
            }
            exit 198
        }
        local ns : word count `slope'
        if `ns' != 2 {
            display as error "{bf:slope()} takes exactly two numbers"
            exit 198
        }
        local b1 : word 1 of `slope'
        local b2 : word 2 of `slope'
        local gthr = 0
        if "`thresholds'" != "" {
            local nth : word count `thresholds'
            if `nth' != 1 {
                display as error "a cross-sectional design takes ONE threshold"
                exit 198
            }
            local gthr : word 1 of `thresholds'
        }
        if "`clear'" != "" quietly clear
        quietly set obs `n'
        capture drop __simx __simq __sime
        quietly generate double __simq = rnormal()
        quietly generate double __simx = rnormal()
        if "`errors'" == "t" {
            quietly generate double __sime = ///
                rt(`df') * `sigma' / sqrt(`df'/(`df'-2))
        }
        else quietly generate double __sime = rnormal(0, `sigma')
        local yv = cond("`stub'"=="", "ysim", "`stub'")
        capture confirm new variable `yv'
        if _rc & "`replace'" == "" {
            display as error "variable {bf:`yv'} exists; use {bf:replace}"
            exit 110
        }
        capture drop `yv'
        if "`model'" == "tr" {
            quietly generate double `yv' = ///
                cond(__simq <= `gthr', `b1', `b2') * __simx + __sime
            label variable `yv' "threshold regression, slopes `b1' / `b2'"
        }
        else {
            quietly generate double `yv' = `b1' * __simx ///
                + `b2' * cond(__simx - `gthr' > 0, __simx - `gthr', 0) + __sime
            label variable `yv' "kink regression, slope `b1', change `b2'"
        }
        rename __simx x
        rename __simq q
        capture drop __sime
        label variable x "regressor"
        label variable q "threshold variable"
        display _n as text "Simulated `=upper("`model'")' design: " ///
            as result "`n'" as text " observations"
        display as text "  y = " _continue
        if "`model'" == "tr" {
            display as text "`b1'*x if q <= `gthr', `b2'*x otherwise, + e"
            display as text "  (the threshold variable q is INDEPENDENT of x, which"
            display as text "   is the easy case; a q correlated with x makes the"
            display as text "   threshold harder to find and is the realistic one)"
        }
        else {
            display as text "`b1'*x + `b2'*(x - `gthr')_+ + e"
            display as text "  (continuous at x = `gthr' by construction, so a jump"
            display as text "   model fitted to this will find a spurious gap)"
        }
        display as text "  e ~ " as result ///
            cond("`errors'"=="t", "t(`df') scaled to sd `sigma'", "N(0, `sigma'^2)")
        return scalar N = `n'
        return scalar threshold = `gthr'
        return local  model "`model'"
        return local  depvar "`yv'"
        return local  cmd "thsim"
        exit
    }

    * ================================================= recursive models
    if "`ar'" == "" local ar 1
    local laglist "`ar'"
    local nl : word count `laglist'
    local pmax 0
    foreach j of local laglist {
        if `j' > `pmax' local pmax = `j'
    }

    tempname BMAT GMAT B1MAT B2MAT SMATX
    if inlist("`model'", "setar", "star") {
        if "`coef'" == "" {
            display as error "{bf:model(`model')} needs {bf:coef()}: the"
            display as error "coefficients row by row, regimes separated by"
            display as error "{bf:|}. Each row is the coefficients on {bf:ar()}"
            display as error "in order, then the constant unless"
            display as error "{bf:noconstant}."
            display as error ""
            display as error "e.g. a two-regime SETAR(1): {bf:coef(0.8 0 | -0.5 0)}"
            exit 198
        }
        local nrow : word count `=subinstr("`coef'", "|", " | ", .)'
        local rows : subinstr local coef "|" "@", all count(local nbar)
        local nreg = `nbar' + 1
        local wide = `nl' + `hasconsn'
        matrix `BMAT' = J(`nreg', `wide', .)
        local r 0
        local rest `"`coef'"'
        while `"`rest'"' != "" {
            gettoken piece rest : rest, parse("|")
            if `"`piece'"' == "|" continue
            local ++r
            local np : word count `piece'
            if `np' != `wide' {
                display as error "regime `r' has `np' coefficient(s) but the"
                display as error "design needs `wide' (`nl' lag(s)" _continue
                if `hasconsn' display as error " plus a constant)"
                else display as error ", no constant)"
                exit 198
            }
            forvalues cc = 1/`wide' {
                local v : word `cc' of `piece'
                matrix `BMAT'[`r',`cc'] = `v'
            }
        }
        if "`model'" == "setar" {
            if "`thresholds'" == "" {
                display as error "{bf:model(setar)} needs {bf:thresholds()}:"
                display as error "`=`nreg'-1' value(s) for `nreg' regime(s)"
                exit 198
            }
            local nth : word count `thresholds'
            if `nth' != `=`nreg'-1' {
                display as error "`nreg' regime(s) need `=`nreg'-1' threshold(s),"
                display as error "but `nth' were given"
                exit 198
            }
            matrix `GMAT' = J(1, `nth', .)
            local i 0
            foreach g of local thresholds {
                local ++i
                matrix `GMAT'[1,`i'] = `g'
            }
            local modeln 1
        }
        else {
            if `nreg' != 2 {
                display as error "{bf:model(star)} takes exactly two coefficient"
                display as error "rows: the LINEAR block and the TRANSITION block,"
                display as error "so that the upper regime is their sum -- the same"
                display as error "parameterisation {bf:thstar} reports"
                exit 198
            }
            matrix `GMAT' = J(1, 1, 0)
            local modeln 2
        }
        if `delay' > `pmax' {
            display as text "{bf:Note.} {bf:delay(`delay')} exceeds the longest"
            display as text "lag `pmax', which is allowed: the regime can depend"
            display as text "on a value the mean does not use."
        }
    }
    else {
        * ---------------------------------------------- TVAR
        if "`coef'" == "" | "`coef2'" == "" {
            display as error "{bf:model(tvar)} needs {bf:coef()} and {bf:coef2()},"
            display as error "one per regime, each holding the coefficients"
            display as error "equation by equation separated by {bf:|}: the"
            display as error "constant first (unless {bf:noconstant}), then the"
            display as error "lags."
            display as error ""
            display as error "e.g. a two-variable TVAR(1):"
            display as error "  {bf:coef(0 0.7 0.2 | 0 0.3 0.4)}"
            display as error "  {bf:coef2(0 -0.6 0.2 | 0 0.3 0.4)}"
            exit 198
        }
        local wide = `lags' * `k' + `hasconsn'
        foreach which in 1 2 {
            local src = cond(`which'==1, `"`coef'"', `"`coef2'"')
            local MT  = cond(`which'==1, "`B1MAT'", "`B2MAT'")
            matrix `MT' = J(`wide', `k', .)
            local e 0
            local rest `"`src'"'
            while `"`rest'"' != "" {
                gettoken piece rest : rest, parse("|")
                if `"`piece'"' == "|" continue
                local ++e
                if `e' > `k' {
                    display as error "more than `k' equations in {bf:coef`=cond(`which'==1,"","2")'()}"
                    exit 198
                }
                local np : word count `piece'
                if `np' != `wide' {
                    display as error "equation `e' of regime `which' has `np'"
                    display as error "coefficient(s) but needs `wide'"
                    exit 198
                }
                forvalues cc = 1/`wide' {
                    local v : word `cc' of `piece'
                    matrix `MT'[`cc',`e'] = `v'
                }
            }
            if `e' != `k' {
                display as error "regime `which' has `e' equation(s), not `k'"
                exit 198
            }
        }
        if "`smat'" != "" {
            capture confirm matrix `smat'
            if _rc {
                display as error "{bf:smat(`smat')} is not a matrix"
                exit 198
            }
            matrix `SMATX' = `smat'
            if rowsof(`SMATX') != `k' | colsof(`SMATX') != `k' {
                display as error "{bf:smat()} must be `k' x `k'"
                exit 198
            }
        }
        else matrix `SMATX' = `sigma'^2 * I(`k')
        local SMAT "`SMATX'"
        local gscaln = 0
        if "`thresholds'" != "" {
            local gscaln : word 1 of `thresholds'
        }
        local lagp `lags'
        local modeln 3
        if `delay' > `lags' {
            display as text "{bf:Note.} {bf:delay(`delay')} exceeds {bf:lags(`lags')},"
            display as text "which is allowed here but means the regime depends on"
            display as text "a lag the companion form does not carry -- so"
            display as text "{bf:estat girf} will refuse the fitted model."
        }
    }

    * ================================================= simulate
    _tk_drop
    capture noisily mata: tk_thsim()
    if _rc {
        display as error "the simulation engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }

    if "`clear'" != "" quietly clear
    if `modeln' == 3 {
        tempname YS
        matrix `YS' = __tk_simY
        _tk_drop
        quietly set obs `n'
        local tv = cond("`tvar'"=="", "t", "`tvar'")
        capture confirm new variable `tv'
        if _rc & "`replace'" == "" {
            display as error "variable {bf:`tv'} exists; use {bf:replace}"
            exit 110
        }
        capture drop `tv'
        quietly generate int `tv' = _n
        local ylist ""
        forvalues j = 1/`k' {
            local yv = cond("`stub'"=="", "y", "`stub'") + "`j'"
            capture confirm new variable `yv'
            if _rc & "`replace'" == "" {
                display as error "variable {bf:`yv'} exists; use {bf:replace}"
                exit 110
            }
            capture drop `yv'
            quietly generate double `yv' = .
            forvalues i = 1/`n' {
                quietly replace `yv' = `YS'[`i',`j'] in `i'
            }
            label variable `yv' "simulated TVAR equation `j'"
            local ylist "`ylist' `yv'"
        }
        quietly tsset `tv'
        display _n as text "Simulated two-regime TVAR: " as result `n' ///
            as text " observations, " as result `k' as text " equations, " ///
            as result `lags' as text " lag(s)"
        display as text "  regime 1 when " as result "`=word("`ylist'",1)'" ///
            as text "(t-`delay') <= " as result %8.4g `gscaln'
        display as text "  burn-in discarded: " as result `burn'
        display as text "  tsset on " as result "`tv'"
        return local  depvars "`=trim("`ylist'")'"
        return scalar k = `k'
        return scalar lags = `lags'
    }
    else {
        tempname YS
        matrix `YS' = __tk_simy
        _tk_drop
        quietly set obs `n'
        local tv = cond("`tvar'"=="", "t", "`tvar'")
        capture drop `tv'
        quietly generate int `tv' = _n
        local yv = cond("`stub'"=="", "ysim", "`stub'")
        capture confirm new variable `yv'
        if _rc & "`replace'" == "" {
            display as error "variable {bf:`yv'} exists; use {bf:replace}"
            exit 110
        }
        capture drop `yv'
        quietly generate double `yv' = .
        forvalues i = 1/`n' {
            quietly replace `yv' = `YS'[`i',1] in `i'
        }
        quietly tsset `tv'
        if `modeln' == 1 {
            label variable `yv' "simulated SETAR"
            display _n as text "Simulated SETAR: " as result `n' ///
                as text " observations, " as result `nreg' as text " regime(s)"
            display as text "  lags" _col(26) as result "`laglist'"
            display as text "  delay" _col(26) as result `delay'
            display as text "  thresholds" _col(26) as result "`thresholds'"
        }
        else {
            label variable `yv' "simulated STAR (`type')"
            display _n as text "Simulated STAR (`type'): " as result `n' ///
                as text " observations"
            display as text "  lags" _col(26) as result "`laglist'"
            display as text "  delay" _col(26) as result `delay'
            display as text "  gamma, c" _col(26) as result %10.4f `gamma' ///
                " " %10.4f `c'
            if `typen' == 3 {
                display as text "  c2" _col(26) as result %10.4f `c2'
            }
        }
        display as text "  errors" _col(26) as result ///
            cond("`errors'"=="normal", "N(0, `sigma'^2)", ///
            cond("`errors'"=="t", "t(`df') scaled to sd `sigma'", ///
                 "resampled from `residuals' (centred)"))
        display as text "  burn-in discarded" _col(26) as result `burn'
        display as text "  tsset on" _col(26) as result "`tv'"
        return local depvar "`yv'"
    }

    display as text ""
    display as text "  The burn-in matters: without it the first observations"
    display as text "  sit in whichever regime contains the starting value, so"
    display as text "  the regime mix would reflect that rather than the model's"
    display as text "  stationary law. " as result `burn' as text " observations were discarded."
    return scalar N = `n'
    return scalar burn = `burn'
    return scalar delay = `delay'
    return local  model "`model'"
    return local  errors "`errors'"
    return local  cmd "thsim"
end
