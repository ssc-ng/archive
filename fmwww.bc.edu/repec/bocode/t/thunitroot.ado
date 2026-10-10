*! thunitroot 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold autoregression with a near unit root: the Caner-Hansen (2001)
*! battery. One command answers both questions at once -- is there a
*! threshold, and is there a unit root -- because neither can be settled
*! without the other.
*!
*! Caner, M. and B. E. Hansen (2001) Econometrica 69:1555-1596,
*!   doi:10.1111/1468-0262.00257
*! Hansen, B. E. (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Hansen, B. E. (1997) JBES 15:60-67, doi:10.1080/07350015.1997.10524687
*!   (the approximate asymptotic p-value functions)

program define thunitroot, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thunitroot" error 301
        Display
        exit
    }

    syntax varname(numeric ts) [if] [in] ,   ///
        [ LAGS(integer 1)                    ///
          MMIN(integer 1)                    ///
          MMAX(integer 0)                    ///
          DELAY(integer 0)                   ///
          ZType(string)                      ///
          TRIM(real 0.15)                    ///
          TREND                              ///
          SWitch(string)                     ///
          JOINT(numlist integer >0 sort)     ///
          REPS(integer 1000)                 ///
          SEED(string)                       ///
          REGimevar(name)                    ///
          Level(cilevel) ]

    * ------------------------------------------------ option checks
    capture tsset
    if _rc {
        display as error "{bf:thunitroot} requires the data to be {bf:tsset}"
        display as error "a threshold autoregression needs a time index"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `lags' < 1 {
        display as error "{bf:lags()} must be 1 or more: the model is written in"
        display as error "ADF form and needs at least one lagged difference"
        exit 198
    }
    if `mmax' == 0 local mmax = `mmin'
    if `mmin' < 1 | `mmax' < `mmin' {
        display as error "need 1 {ul:<} {bf:mmin()} {ul:<} {bf:mmax()}"
        exit 198
    }
    if `mmax' > `lags' {
        display as error "{bf:mmax()} cannot exceed {bf:lags()} (`lags')"
        display as error "the threshold variable reaches back m periods before the"
        display as error "first regressor, so a delay beyond the lag length would"
        display as error "shorten the sample and change the model being compared"
        exit 198
    }
    if `delay' != 0 & (`delay' < `mmin' | `delay' > `mmax') {
        display as error "{bf:delay(`delay')} is outside {bf:mmin()}-{bf:mmax()}"
        exit 198
    }
    if "`ztype'" == "" local ztype long
    local ztype = lower("`ztype'")
    if !inlist("`ztype'", "long", "lagdiff", "laglevel") {
        display as error "{bf:ztype()} must be long, lagdiff or laglevel"
        exit 198
    }
    local znum = cond("`ztype'"=="long", 1, cond("`ztype'"=="lagdiff", 2, 3))

    * trim is restricted to the three tabulated regions: the asymptotic
    * critical values and p-value functions exist only for these
    local trimc = 0
    if abs(`trim' - 0.15) < 1e-8 local trimc 1
    if abs(`trim' - 0.10) < 1e-8 local trimc 2
    if abs(`trim' - 0.05) < 1e-8 local trimc 3
    if `trimc' == 0 {
        display as error "{bf:trim()} must be 0.15, 0.10 or 0.05"
        display as error "Caner and Hansen tabulate the asymptotic bound only for"
        display as error "these three trimming regions. A different trim would leave"
        display as error "the asymptotic critical values and p-value functions"
        display as error "undefined, and reporting them anyway would be wrong."
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} must be 0 or more"
        exit 198
    }
    local trendn = cond("`trend'"=="", 0, 1)

    local swlist ""
    if "`switch'" != "" {
        local sl = lower(trim("`switch'"))
        if "`sl'" == "none" local swlist none
        else {
            capture numlist "`switch'", integer range(>0) sort
            if _rc {
                display as error "{bf:switch()} takes a numlist of lag indices, or {bf:none}"
                exit 198
            }
            local swlist "`r(numlist)'"
            foreach k of local swlist {
                if `k' > `lags' {
                    display as error "{bf:switch()} names lag `k' but {bf:lags(`lags')}"
                    exit 198
                }
            }
        }
    }
    local jointlist ""
    if "`joint'" != "" {
        local jointlist "`joint'"
        foreach k of local jointlist {
            if `k' > `lags' {
                display as error "{bf:joint()} names lag `k' but {bf:lags(`lags')}"
                exit 198
            }
            if "`swlist'" != "" & "`swlist'" != "none" {
                local ok 0
                foreach s of local swlist {
                    if `s' == `k' local ok 1
                }
                if !`ok' {
                    display as error "{bf:joint(`k')} asks whether lag `k' differs across"
                    display as error "regimes, but {bf:switch()} holds it common, so it"
                    display as error "cannot differ. Add `k' to {bf:switch()} or drop it"
                    display as error "from {bf:joint()}."
                    exit 198
                }
            }
            if "`swlist'" == "none" {
                display as error "{bf:joint()} needs switching lags, but {bf:switch(none)}"
                display as error "holds every lag common"
                exit 198
            }
        }
    }
    if "`seed'" != "" set seed `seed'

    * ------------------------------------------------ sample
    marksample touse
    local depv "`varlist'"
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 2 * (2 + `trendn' + `lags') + 20 {
        display as error "only `nobs' observations: too few for a two-regime"
        display as error "ADF regression with `lags' lag(s)"
        exit 2001
    }

    * The engine reads the series as consecutive observations, so the sample
    * must be one unbroken stretch of the time index. Counting observations
    * that are present but unused would MISS the case that matters, where the
    * rows are absent from the dataset altogether, so the span implied by the
    * time variable is compared with the number of observations in it.
    quietly tsset
    local tdelta = r(tdelta)
    if "`tdelta'" == "" | `tdelta' <= 0 local tdelta 1
    quietly summarize `timevar' if `touse', meanonly
    local span = (r(max) - r(min)) / `tdelta' + 1
    quietly count if `touse'
    if abs(r(N) - `span') > 1e-6 {
        display as error "the sample spans `span' periods but holds only `r(N)'"
        display as error "observations, so it has at least one internal gap."
        display as error "{bf:thunitroot} builds long differences y(t-1) - y(t-1-m)"
        display as error "directly from consecutive observations, so an unbroken"
        display as error "stretch is required: a gap would make Z the difference"
        display as error "across the gap and silently change what is being tested."
        display as error "Restrict with {bf:if} to a gap-free span, or fill the gaps"
        display as error "with {bf:tsfill} if the series really is complete."
        exit 198
    }

    * ------------------------------------------------ engine
    local lagsn `lags'
    _tk_drop
    capture noisily mata: tk_thunitroot()
    if _rc {
        display as error "the Caner-Hansen engine failed (rc=" _rc ")"
        exit _rc
    }
    if __tk_urfail == 1 {
        display as error "no admissible threshold: every grid point left a regime"
        display as error "with fewer observations than the regression needs"
        display as error "try a smaller {bf:lags()} or a wider {bf:trim()}"
        _tk_drop
        exit 459
    }

    tempname b V TAB PM CV LIN LSE TSC PTSC SE BU BC
    matrix `TAB' = __tk_urtab
    matrix `PM'  = __tk_urp
    matrix `CV'  = __tk_urcv
    matrix `LIN' = __tk_urlin
    matrix `LSE' = __tk_urlse
    matrix `TSC' = __tk_urtsc
    capture matrix `PTSC' = __tk_urptsc
    matrix `b'   = __tk_urb
    matrix `SE'  = __tk_urse
    capture matrix `BU' = __tk_urbu
    capture matrix `BC' = __tk_urbc
    local n      = __tk_urn
    local ssr0   = __tk_urssr0
    local ssr    = __tk_urssr
    local mhat   = __tk_urmhat
    local mused  = __tk_urmused
    local pwu    = __tk_urpwu
    local pwc    = __tk_urpwc
    local wtest  = __tk_urwtest
    local pwj    = __tk_urpwj
    local kz     = __tk_urkz
    local nsw    = __tk_urnsw
    local adf    = __tk_uradf
    local rho    = __tk_urrho
    local sig2   = __tk_ursig2

    * ------------------------------------------------ names
    * x = (1, [t], y(t-1), dy(t-1), ..., dy(t-p))
    local xn "_cons"
    if `trendn' local xn "`xn' trend"
    local xn "`xn' L1.`depv'"
    forvalues k = 1/`lags' {
        local xn "`xn' L`k'D.`depv'"
    }
    local kx : word count `xn'

    * which of those switch
    if "`swlist'" == "" {
        local swn "`xn'"
        local nsn ""
    }
    else {
        local swn "_cons"
        if `trendn' local swn "`swn' trend"
        local swn "`swn' L1.`depv'"
        if "`swlist'" != "none" {
            forvalues k = 1/`lags' {
                foreach s of local swlist {
                    if `s' == `k' local swn "`swn' L`k'D.`depv'"
                }
            }
        }
        local nsn ""
        forvalues k = 1/`lags' {
            local inlist 0
            if "`swlist'" != "none" {
                foreach s of local swlist {
                    if `s' == `k' local inlist 1
                }
            }
            if !`inlist' local nsn "`nsn' L`k'D.`depv'"
        }
    }

    local cn ""
    local ce ""
    foreach v of local swn {
        local cn "`cn' `v'"
        local ce "`ce' Regime1"
    }
    foreach v of local swn {
        local cn "`cn' `v'"
        local ce "`ce' Regime2"
    }
    foreach v of local nsn {
        local cn "`cn' `v'"
        local ce "`ce' Common"
    }

    * ------------------------------------------------ the covariance matrix
    * the FULL homoskedastic covariance matrix comes out of the engine, not a
    * diagonal built from the standard errors: a diagonal would silently
    * break every test that needs a covariance between two coefficients,
    * starting with the equality tests reported below
    matrix `V' = __tk_urV
    local kb : word count `cn'
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    * ------------------------------------------------ post
    * e(sample) must be the rows the REGRESSION uses, not the rows the series
    * occupies: the ADF form consumes the first lags+1 observations, so
    * e(sample) is the trailing n of them. Posting touse instead would make
    * e(sample) wider than e(N) and quietly corrupt every predict and estat
    * that relies on it.
    tempvar seq esample
    quietly generate long `seq' = sum(`touse')
    quietly generate byte `esample' = `touse' & `seq' > `lags' + 1
    quietly count if `esample'
    if r(N) != `n' {
        display as error "internal: e(sample) has `r(N)' rows but the regression"
        display as error "used `n'. This should not happen; please report it."
        exit 498
    }
    ereturn post `b' `V', depname("D.`depv'") obs(`n') esample(`esample')

    ereturn local cmd        "thunitroot"
    ereturn local cmdline    "thunitroot `0'"
    ereturn local title      "Threshold autoregression with a near unit root"
    ereturn local depvar     "`depv'"
    ereturn local timevar    "`timevar'"
    ereturn local ztype      "`ztype'"
    ereturn local model      = cond("`swlist'"=="", "unconstrained", "constrained")
    ereturn local xnames     "`xn'"
    ereturn local swnames    "`swn'"
    ereturn local nsnames    "`nsn'"
    ereturn local switchlags "`swlist'"
    ereturn local jointlags  "`jointlist'"
    ereturn local estat_cmd  "thunitroot_estat"
    ereturn local predict    "thunitroot_p"
    ereturn local properties "b V"

    ereturn scalar N        = `n'
    ereturn scalar k_lags   = `lags'
    ereturn scalar k_x      = `kx'
    ereturn scalar k_switch = `nsw'
    ereturn scalar k_total  = `kz'
    ereturn scalar trend    = `trendn'
    ereturn scalar trim     = `trim'
    ereturn scalar trimcode = `trimc'
    ereturn scalar mmin     = `mmin'
    ereturn scalar mmax     = `mmax'
    ereturn scalar delay    = `mused'
    ereturn scalar delay_ssr = `mhat'
    ereturn scalar reps     = `reps'
    ereturn scalar level    = `level'

    local i = `mused' - `mmin' + 1
    ereturn scalar lambda   = `TAB'[`i',1]
    ereturn scalar ssr      = `ssr'
    ereturn scalar ssr0     = `ssr0'
    ereturn scalar sigma2   = `ssr'/(`n' - `kz')
    ereturn scalar sigma2_0 = `sig2'
    ereturn scalar ll       = -(`n'/2)*(1 + ln(2*c(pi)*`ssr'/`n'))
    ereturn scalar N_regime1 = `TAB'[`i',9]
    ereturn scalar N_regime2 = `TAB'[`i',10]
    ereturn scalar n_grid   = `TAB'[`i',8]

    ereturn scalar W        = `TAB'[`mhat'-`mmin'+1,3]
    ereturn scalar W_m      = `TAB'[`i',3]
    ereturn scalar p_W_unres = `pwu'
    ereturn scalar p_W_ur    = `pwc'
    ereturn scalar p_W       = max(`pwu', `pwc')
    ereturn scalar R1T      = `TAB'[`i',4]
    ereturn scalar R2T      = `TAB'[`i',5]
    ereturn scalar t1       = `TAB'[`i',6]
    ereturn scalar t2       = `TAB'[`i',7]
    ereturn scalar p_R1T    = `PM'[`i',3]
    ereturn scalar p_R2T    = `PM'[`i',4]
    ereturn scalar p_t1     = `PM'[`i',5]
    ereturn scalar p_t2     = `PM'[`i',6]
    ereturn scalar pa_R1T   = `PM'[`i',7]
    ereturn scalar pa_R2T   = `PM'[`i',8]
    ereturn scalar pa_t1    = `PM'[`i',9]
    ereturn scalar pa_t2    = `PM'[`i',9]
    ereturn scalar adf      = `adf'
    ereturn scalar rho_lin  = `rho'
    if `wtest' < . {
        ereturn scalar W_joint  = `wtest'
        ereturn scalar p_W_joint = `pwj'
    }

    matrix colnames `TAB' = lambda ssr W R1T R2T t1 t2 ngrid n1 n2
    matrix colnames `PM'  = p_W_unres p_W_ur p_R1T p_R2T p_t1 p_t2 ///
        pa_R1T pa_R2T pa_t
    local rn ""
    forvalues m = `mmin'/`mmax' {
        local rn "`rn' m`m'"
    }
    matrix rownames `TAB' = `rn'
    matrix rownames `PM'  = `rn'
    matrix colnames `CV'  = cv10 cv5 cv1
    matrix rownames `CV'  = R1T R2T t R2T_identified
    matrix colnames `LIN' = `xn'
    matrix colnames `LSE' = `xn'
    matrix colnames `TSC' = `swn'
    capture matrix colnames `PTSC' = `swn'

    ereturn matrix bydelay   = `TAB'
    ereturn matrix pbydelay  = `PM'
    ereturn matrix cv        = `CV'
    ereturn matrix b_linear  = `LIN'
    ereturn matrix se_linear = `LSE'
    ereturn matrix wald_coef = `TSC'
    capture ereturn matrix p_wald_coef = `PTSC'
    capture ereturn matrix bdist_unres = `BU'
    capture ereturn matrix bdist_ur    = `BC'

    if "`regimevar'" != "" {
        capture confirm new variable `regimevar'
        if _rc {
            display as error "variable {bf:`regimevar'} already exists"
            exit 110
        }
        * Z is rebuilt with time-series operators rather than by mapping the
        * engine's row numbers back onto observations: the operators are what
        * the user can check by hand, and predict uses the same expression.
        tempvar zz
        local mm = e(delay)
        if "`ztype'" == "long" {
            quietly generate double `zz' = L1.`depv' - L`=`mm'+1'.`depv'
        }
        else if "`ztype'" == "lagdiff" {
            quietly generate double `zz' = L`mm'D.`depv'
        }
        else {
            quietly generate double `zz' = L`mm'.`depv'
        }
        quietly generate byte `regimevar' = ///
            cond(`zz' < e(lambda), 1, 2) if e(sample) & !missing(`zz')
        label variable `regimevar' "Caner-Hansen regime (1 = Z < lambda)"
    }

    _tk_drop
    Display
end

* ======================================================================
program define Display
    version 15
    local depv  "`e(depvar)'"
    local mmin  = e(mmin)
    local mmax  = e(mmax)
    local trimc = e(trimcode)
    local trendn = e(trend)
    tempname TAB PM CV LIN LSE TSC
    matrix `TAB' = e(bydelay)
    matrix `PM'  = e(pbydelay)
    matrix `CV'  = e(cv)
    matrix `LIN' = e(b_linear)
    matrix `LSE' = e(se_linear)
    matrix `TSC' = e(wald_coef)
    local i = e(delay) - `mmin' + 1

    display _n as text "Threshold autoregression with a near unit root" ///
        _col(55) "Number of obs = " as result %8.0f e(N)
    display as text "Caner and Hansen (2001)" _col(55) as text ///
        "Lags of D.`depv'  = " as result %8.0f e(k_lags)
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(40) as result "D.`depv'"
    display as text "  Threshold variable Z(t-1)" _col(40) as result ///
        cond("`e(ztype)'"=="long",  "`depv'(t-1) - `depv'(t-1-m)", ///
        cond("`e(ztype)'"=="lagdiff","D.`depv'(t-m)", "`depv'(t-m)"))
    display as text "  Deterministics" _col(40) as result ///
        cond(`trendn', "constant and linear trend", "constant")
    display as text "  Model" _col(40) as result "`e(model)'"
    display as text "  Trimming region" _col(40) as result ///
        "[" %4.2f e(trim) ", " %4.2f (1 - e(trim)) "]"
    display as text "  Delay reported / argmin SSR" _col(40) as result ///
        %6.0f e(delay) "  /" %6.0f e(delay_ssr)
    display as text "  Threshold lambda" _col(40) as result %12.6g e(lambda)
    display as text "  Regime 1 (Z < lambda) / regime 2" _col(40) as result ///
        %6.0f e(N_regime1) "  /" %6.0f e(N_regime2)
    display as text "  Grid points searched" _col(40) as result %12.0f e(n_grid)
    display as text "  Residual variance: linear / TAR" _col(38) as result ///
        %10.6f e(sigma2_0) " " %10.6f e(sigma2)
    display as text "  Gaussian log-likelihood" _col(40) as result %12.4f e(ll)
    display as text "{hline 78}"

    display _n as text "Linear ADF benchmark"
    display as text "{hline 78}"
    display as text "  rho (coefficient on `depv'(t-1))" _col(44) as result ///
        %14.6f e(rho_lin)
    display as text "  ADF t statistic" _col(44) as result %14.4f e(adf)
    display as text "{hline 78}"
    display as text "  Compare with {bf:dfuller} critical values. If this does not"
    display as text "  reject and the regime-specific t's below do, the unit root was"
    display as text "  an artefact of forcing one regime on the data."

    ereturn display, level(`e(level)')

    display _n as text "Is there a threshold?  H0: theta1 = theta2"
    display as text "{hline 78}"
    display as text "  Wald W at the argmin-SSR delay (m = " as result e(delay_ssr) ///
        as text ")" _col(52) as result %14.4f e(W)
    if e(p_W_unres) < . {
        display as text "  bootstrap p, rho unrestricted" _col(52) as result %14.4f e(p_W_unres)
        display as text "  bootstrap p, unit root imposed" _col(52) as result %14.4f e(p_W_ur)
        display as text "{hline 78}"
        display as text "  Report " as result %6.4f e(p_W) as text ///
            ", the LARGER of the two. The limit distribution of W"
        display as text "  depends on whether rho = 0, and which case holds is exactly"
        display as text "  what is not known, so Caner and Hansen recommend computing"
        display as text "  both bootstraps and acting on the larger p-value."
    }
    else {
        display as text "{hline 78}"
        display as text "  No bootstrap was run ({bf:reps(0)}). W has no tabulated"
        display as text "  distribution: its limit mixes a unit-root term with Hansen's"
        display as text "  (1996) chi-square process and is not pivotal. Without the"
        display as text "  bootstrap there is no p-value, and none is invented here."
    }
    display as text "{hline 78}"

    display _n as text "Is there a unit root?  H0: rho1 = rho2 = 0"
    display as text "{hline 78}"
    display as text "  statistic" _col(26) "value" _col(38) "boot p" ///
        _col(50) "asym p" _col(62) "5% bound"
    display as text "{hline 78}"
    display as text "  R1T (one-sided)" _col(22) as result %12.4f e(R1T) ///
        _col(34) %12.4f e(p_R1T) _col(46) %12.4f e(pa_R1T) ///
        _col(58) %12.2f `CV'[1,2]
    display as text "  R2T (two-sided)" _col(22) as result %12.4f e(R2T) ///
        _col(34) %12.4f e(p_R2T) _col(46) %12.4f e(pa_R2T) ///
        _col(58) %12.2f `CV'[2,2]
    display as text "  -t1 (regime 1)" _col(22) as result %12.4f e(t1) ///
        _col(34) %12.4f e(p_t1) _col(46) %12.4f e(pa_t1) ///
        _col(58) %12.2f `CV'[3,2]
    display as text "  -t2 (regime 2)" _col(22) as result %12.4f e(t2) ///
        _col(34) %12.4f e(p_t2) _col(46) %12.4f e(pa_t2) ///
        _col(58) %12.2f `CV'[3,2]
    display as text "{hline 78}"
    display as text "  Large values reject the unit root. The asymptotic column uses"
    display as text "  the nuisance-free BOUND of Theorem 5, valid when the threshold"
    display as text "  is not identified; it is conservative when it is. The bootstrap"
    display as text "  column imposes rho = 0 and theta1 = theta2, which is the"
    display as text "  distribution Caner and Hansen prefer for these four statistics."
    display as text "{hline 78}"

    * the partial unit root is the finding only this battery can produce
    local r1 = (e(t1) > `CV'[3,2])
    local r2 = (e(t2) > `CV'[3,2])
    display as text "  Reading -t1 and -t2 together at the 5% bound:"
    if `r1' & `r2' {
        display as text "    both reject: " as result "stationary in both regimes"
    }
    else if `r1' & !`r2' {
        display as text "    regime 1 rejects, regime 2 does not: " as result ///
            "PARTIAL UNIT ROOT"
        display as text "    stationary when Z < lambda, a unit root when Z >= lambda."
    }
    else if !`r1' & `r2' {
        display as text "    regime 2 rejects, regime 1 does not: " as result ///
            "PARTIAL UNIT ROOT"
        display as text "    a unit root when Z < lambda, stationary when Z >= lambda."
    }
    else {
        display as text "    neither rejects: " as result ///
            "no evidence against a unit root in either regime"
    }
    display as text "    A partial unit root is a real possibility here and is"
    display as text "    invisible to a linear ADF, which averages the two regimes."
    display as text "{hline 78}"

    if `mmax' > `mmin' {
        display _n as text "By delay m  (the whole battery, so nothing is hidden by"
        display as text "             the delay that happened to win)"
        display as text "{hline 78}"
        display as text "    m" _col(10) "SSR" _col(24) "W" _col(34) "p(W)" ///
            _col(44) "R1T" _col(54) "p" _col(62) "-t1" _col(70) "-t2"
        display as text "{hline 78}"
        forvalues r = 1/`=rowsof(`TAB')' {
            local m = `mmin' + `r' - 1
            local mk = cond(`m' == e(delay_ssr), "*", " ")
            display as text "  `mk'" as result %3.0f `m' ///
                _col(6) %13.6f `TAB'[`r',2] _col(20) %10.3f `TAB'[`r',3] ///
                _col(31) %8.3f `PM'[`r',2] _col(40) %10.3f `TAB'[`r',4] ///
                _col(50) %8.3f `PM'[`r',3] _col(58) %8.3f `TAB'[`r',6] ///
                _col(66) %8.3f `TAB'[`r',7]
        }
        display as text "{hline 78}"
        display as text "  * minimises the residual sum of squares. p(W) is the"
        display as text "  unit-root-imposed bootstrap; p is the bootstrap p of R1T."
        display as text "  Choosing m by minimum SSR and then reading that row's"
        display as text "  p-value is a search the p-value does not know about: the"
        display as text "  whole column is printed so the sensitivity is visible."
    }

    if e(W_joint) < . {
        display _n as text "Joint Wald: do lags " as result "`e(jointlags)'" ///
            as text " of D.`depv' differ across regimes?"
        display as text "{hline 78}"
        display as text "  Wald statistic" _col(50) as result %14.4f e(W_joint)
        if e(p_W_joint) < . {
            display as text "  bootstrap p-value" _col(50) as result %14.4f e(p_W_joint)
        }
        display as text "{hline 78}"
        display as text "  Not rejecting is useful: it says the threshold acts through"
        display as text "  the LEVEL and the persistence, not through the short-run"
        display as text "  dynamics, and the constrained model of {bf:switch()} is"
        display as text "  then the one to report."
    }
end
