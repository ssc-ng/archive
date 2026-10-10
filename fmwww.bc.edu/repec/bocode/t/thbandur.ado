*! thbandur 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Unit-root tests against a globally stationary three-regime SETAR with a
*! random walk in the corridor regime (a band of inaction).
*!
*!   Kapetanios, G. and Y. Shin (2006) Econometrics Journal 9:252-278,
*!     doi:10.1111/j.1368-423X.2006.00184.x
*!
*! See thbandur.sthlp.

program define thbandur, rclass
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        [ LAGS(integer 0)                  ///
          CASE(integer 2)                  ///
          CONSTant                         ///
          TREND                            ///
          Cpar(real 3)                     ///
          Delta(real 0.5)                  ///
          GRIDn(integer 20)                ///
          MINObs(integer 0)                ///
          MINGap(real 0)                   ///
          REPS(integer 0)                  ///
          SEED(string)                     ///
          Level(cilevel) ]

    * ------------------------------------------------ option validation
    if "`constant'" != "" & "`trend'" != "" {
        display as error "{bf:constant} and {bf:trend} are alternatives;"
        display as error "use {bf:trend} for a series with both a mean and a"
        display as error "linear trend."
        exit 198
    }
    if "`constant'" != "" local case 2
    if "`trend'"    != "" local case 3
    if `case' < 1 | `case' > 3 {
        display as error "{bf:case()} must be 1, 2 or 3"
        exit 198
    }
    if `lags' < 0 | `lags' > 24 {
        display as error "{bf:lags()} must be between 0 and 24"
        exit 198
    }
    * delta >= 1/2 is Assumption 3, not a tuning preference: it is what
    * keeps the corridor of FINITE width under the null, and the tabulated
    * critical values are derived under it. A smaller delta would let the
    * thresholds diverge and quietly invalidate every critical value below.
    if `delta' < 0.5 {
        display as error "{bf:delta()} must be at least 0.5."
        display as error "Assumption 3 of Kapetanios and Shin requires the"
        display as error "corridor to stay of FINITE width under the null,"
        display as error "and delta < 0.5 lets the thresholds diverge. The"
        display as error "tabulated critical values would no longer apply."
        exit 198
    }
    if `cpar' <= 0 {
        display as error "{bf:c()} must be positive"
        exit 198
    }
    if `gridn' < 2 | `gridn' > 200 {
        display as error "{bf:gridn()} must be between 2 and 200"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    if `mingap' < 0 {
        display as error "{bf:mingap()} cannot be negative"
        exit 198
    }
    if "`level'" == "" local level = c(level)

    capture tsset
    if _rc {
        display as error "{bf:thbandur} needs the data {bf:tsset}"
        exit 111
    }
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        display as error "{bf:thbandur} is a single time-series command;"
        display as error "these data are panel-tsset. Panel threshold models"
        display as error "are outside the scope of this package."
        exit 198
    }

    marksample touse
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 25 + `lags' {
        display as error "too few observations: `nobs'"
        exit 2001
    }

    * the sample must be one contiguous run: the test is built on lags and
    * differences, and a hole in the calendar would misalign both
    quietly summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin' + 1) != `nobs' {
        display as error "the estimation sample has gaps in `tvar'."
        display as error "Restrict to a contiguous span with {bf:if}."
        exit 198
    }

    local yv     "`varlist'"
    local plags  `lags'
    local dcase  `case'
    local cpar2  `cpar'
    local dpar   `delta'
    local nreps  `reps'
    local mobs   = cond(`minobs' > 0, `minobs', max(10, ceil(0.05*`nobs')))
    local mgap   `mingap'
    local cpar   `cpar2'

    if "`seed'" != "" set seed `seed'

    _tk_drop
    mata: tk_thbandur()

    if __tk_bufail == 1 {
        _tk_drop
        display as error "too few usable observations"
        exit 2001
    }
    if __tk_bufail == 2 {
        _tk_drop
        display as error "the threshold grid is empty. Try a larger {bf:c()}"
        display as error "or check the series is not nearly constant."
        exit 498
    }
    if __tk_bufail == 3 {
        _tk_drop
        display as error "no admissible (r1,r2) pair left after {bf:minobs()}"
        display as error "and {bf:mingap()}. Lower them, or widen {bf:c()}."
        exit 498
    }

    tempname ST PB CVS CVE GRID
    matrix `ST'   = __tk_bustat
    matrix `PB'   = __tk_bup
    matrix `CVS'  = __tk_bucvs
    matrix `CVE'  = __tk_bucve
    matrix `GRID' = __tk_bugrid
    local r1   = __tk_bur1
    tempname r1_s
    scalar `r1_s' = __tk_bur1
    local r2   = __tk_bur2
    tempname r2_s
    scalar `r2_s' = __tk_bur2
    local npt  = __tk_bunpt
    local ng   = __tk_bung
    local plo  = __tk_buplo
    local phi  = __tk_buphi
    local nuse = __tk_bun
    local nb   = __tk_bunb
    _tk_drop

    local wsup = `ST'[1,1]
    local wavg = `ST'[1,2]
    local wexp = `ST'[1,3]

    * ------------------------------------------------ display
    local clab "zero mean"
    if `case' == 2 local clab "non-zero mean (de-meaned)"
    if `case' == 3 local clab "mean and linear trend (de-trended)"

    display _n as text ///
        "Unit root against a globally stationary three-regime SETAR"
    display as text "{hline 74}"
    display as text "  H0: unit root everywhere (beta1 = beta2 = 0)"
    display as text "  H1: random walk in the corridor, mean reversion outside"
    display as text "{hline 74}"
    display as text "  series" _col(46) as result %26s "`yv'"
    display as text "  deterministic case" _col(46) as result %26s "`case' -- `clab'"
    display as text "  observations used" _col(46) as result %26.0f `nuse'
    display as text "  augmentation lags" _col(46) as result %26.0f `lags'
    display as text "  grid points per threshold" _col(46) as result %26.0f `ng'
    display as text "  admissible (r1,r2) pairs" _col(46) as result %26.0f `npt'
    display as text "  quantile band searched" _col(46) as result %26s ///
        "`=string(`plo',"%5.3f")' to `=string(`phi',"%5.3f")'"
    display as text "{hline 74}"
    display as text "  thresholds at the supremum" _col(46) as result %26s ///
        "`=string(`r1',"%9.4f")' , `=string(`r2',"%9.4f")'"
    display as text "{hline 74}"

    display as text "  statistic" _col(22) "value" _col(36) "10%" ///
        _col(48) "5%" _col(60) "1%"
    display as text "  " "{hline 70}"
    display as text "  sup Wald" _col(20) as result %10.4f `wsup' ///
        _col(32) %10.2f `CVS'[1,1] _col(44) %10.2f `CVS'[1,2] ///
        _col(56) %10.2f `CVS'[1,3]
    display as text "  avg Wald" _col(20) as result %10.4f `wavg' ///
        _col(32) %10.2f `CVS'[1,1] _col(44) %10.2f `CVS'[1,2] ///
        _col(56) %10.2f `CVS'[1,3]
    display as text "  exp Wald" _col(20) as result %10.4f `wexp' ///
        _col(32) %10.2f `CVE'[1,1] _col(44) %10.2f `CVE'[1,2] ///
        _col(56) %10.2f `CVE'[1,3]
    display as text "{hline 74}"

    * the verdicts
    local vsup "not rejected"
    if `wsup' > `CVS'[1,1] local vsup "rejected at 10%"
    if `wsup' > `CVS'[1,2] local vsup "rejected at 5%"
    if `wsup' > `CVS'[1,3] local vsup "rejected at 1%"
    local vavg "not rejected"
    if `wavg' > `CVS'[1,1] local vavg "rejected at 10%"
    if `wavg' > `CVS'[1,2] local vavg "rejected at 5%"
    if `wavg' > `CVS'[1,3] local vavg "rejected at 1%"
    local vexp "not rejected"
    if `wexp' > `CVE'[1,1] local vexp "rejected at 10%"
    if `wexp' > `CVE'[1,2] local vexp "rejected at 5%"
    if `wexp' > `CVE'[1,3] local vexp "rejected at 1%"

    display as text "  asymptotic verdict, sup Wald" _col(46) ///
        as result %26s "`vsup'"
    display as text "  asymptotic verdict, avg Wald" _col(46) ///
        as result %26s "`vavg'"
    display as text "  asymptotic verdict, exp Wald" _col(46) ///
        as result %26s "`vexp'"

    if `nb' > 0 {
        display as text "{hline 74}"
        display as text "  bootstrap p, sup Wald" _col(46) ///
            as result %26.4f `PB'[1,1]
        display as text "  bootstrap p, avg Wald" _col(46) ///
            as result %26.4f `PB'[1,2]
        display as text "  bootstrap p, exp Wald" _col(46) ///
            as result %26.4f `PB'[1,3]
        display as text "  replications" _col(46) as result %26.0f `nb'
    }
    display as text "{hline 74}"

    * ------------------------------------------------ the standing notes
    display as text "  The critical values are the TABULATED asymptotic ones"
    display as text "  of the paper's Table 1, which apply because the limit"
    display as text "  of the Wald statistic does {bf:not} depend on the"
    display as text "  thresholds: a unit-root process spends a vanishing"
    display as text "  fraction of its time inside a corridor of fixed width,"
    display as text "  so in the limit the corridor does not matter. That is"
    display as text "  why sup and average Wald share one column here."
    if `nb' == 0 {
        display as text ""
        display as text "  Those values were tabulated from series of 5,000"
        display as text "  observations. With `nuse' here, consider"
        display as text "  {bf:reps()} for a bootstrap p-value as a check:"
        display as text "  unit-root tests are size-distorted in short samples."
    }
    display as text ""
    display as text "  A rejection says the series is {bf:not} a unit root"
    display as text "  everywhere; it does not establish the band. The"
    display as text "  thresholds shown are where the statistic peaked and"
    display as text "  carry no confidence set. To estimate the band itself,"
    display as text "  fit it with {helpb thmtar} or {helpb thtvecm}."

    * ------------------------------------------------ stored results
    return scalar wsup   = `wsup'
    return scalar wavg   = `wavg'
    return scalar wexp   = `wexp'
    return scalar p_sup  = `PB'[1,1]
    return scalar p_avg  = `PB'[1,2]
    return scalar p_exp  = `PB'[1,3]
    return scalar r1     = `r1_s'
    return scalar r2     = `r2_s'
    return scalar N      = `nuse'
    return scalar lags   = `lags'
    return scalar case   = `case'
    return scalar ngrid  = `ng'
    return scalar npairs = `npt'
    return scalar plo    = `plo'
    return scalar phi    = `phi'
    return scalar reps   = `nb'
    return scalar cv90   = `CVS'[1,1]
    return scalar cv95   = `CVS'[1,2]
    return scalar cv99   = `CVS'[1,3]
    return scalar cve90  = `CVE'[1,1]
    return scalar cve95  = `CVE'[1,2]
    return scalar cve99  = `CVE'[1,3]
    return local  cmd    "thbandur"
    return local  depvar "`yv'"
    return matrix stat   = `ST', copy
    return matrix cvsup  = `CVS', copy
    return matrix cvexp  = `CVE', copy
    return matrix grid   = `GRID', copy
end
