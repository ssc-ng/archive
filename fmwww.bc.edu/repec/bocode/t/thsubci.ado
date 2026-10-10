*! thsubci 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Subsampling confidence interval for a SETAR threshold, with the rate of
*! convergence estimated from the data.
*!
*!   Gonzalo, J. and M. Wolf (2005) Journal of Econometrics 127:201-224,
*!     doi:10.1016/j.jeconom.2004.08.004
*!   Politis, Romano and Wolf (1999), Subsampling, Springer
*!   Chan (1993) Annals of Statistics 21:520-533, doi:10.1214/aos/1176349040
*!   Chan and Tsay (1998) Biometrika 85:413-426
*!
*! See thsubci.sthlp.

program define thsubci, rclass
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        [ AR(integer 1)                    ///
          DELAY(integer 1)                 ///
          RATE(string)                     ///
          BLock(integer 0)                 ///
          GVals(numlist min=2 >0 <1 sort)  ///
          TVals(numlist min=1 >0.5 <1 sort) ///
          MAXBlk(integer 150)              ///
          TRIM(real 0.15)                  ///
          MINObs(integer 0)                ///
          Level(cilevel) ]

    * ------------------------------------------------ option validation
    if `ar' < 1 | `ar' > 12 {
        display as error "{bf:ar()} must be between 1 and 12"
        exit 198
    }
    if `delay' < 1 | `delay' > 12 {
        display as error "{bf:delay()} must be between 1 and 12"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `maxblk' < 10 {
        display as error "{bf:maxblk()} must be at least 10"
        exit 198
    }

    if "`rate'" == "" local rate estimate
    local rate = lower("`rate'")
    if !inlist("`rate'", "estimate", "continuous", "discontinuous") {
        display as error "{bf:rate()} must be {bf:estimate}, {bf:continuous}"
        display as error "or {bf:discontinuous}."
        display as error "The rate is n^(1/2) for a CONTINUOUS SETAR (a kink)"
        display as error "and n for a DISCONTINUOUS one (a jump). If you do"
        display as error "not know which, leave it at {bf:estimate}: that is"
        display as error "the case the method was built for."
        exit 198
    }
    local ratemode = 0
    if "`rate'" == "continuous"    local ratemode 1
    if "`rate'" == "discontinuous" local ratemode 2

    if "`level'" == "" local level = c(level)
    local alphav = (100 - `level')/100

    if "`gvals'" == "" local gvals "0.5 0.6 0.7 0.8"
    if "`tvals'" == "" local tvals "0.6 0.7 0.8 0.9"

    capture tsset
    if _rc {
        display as error "{bf:thsubci} needs the data {bf:tsset}"
        exit 111
    }
    if "`r(panelvar)'" != "" {
        display as error "{bf:thsubci} is a single time-series command;"
        display as error "panel threshold models are outside this package."
        exit 198
    }
    local tvar "`r(timevar)'"

    marksample touse
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 60 {
        display as error "subsampling needs a reasonable series; `nobs'"
        display as error "observations is too few. Use {helpb thregress} with"
        display as error "{bf:ci(lr)} for an inverted-likelihood-ratio set."
        exit 2001
    }

    * the series is cut into CONTIGUOUS blocks, so a hole in the calendar
    * would put observations from either side of it into one block
    quietly summarize `tvar' if `touse', meanonly
    if (r(max) - r(min) + 1) != `nobs' {
        display as error "the estimation sample has gaps in `tvar'."
        display as error "Subsampling cuts the series into contiguous blocks,"
        display as error "and a gap would put observations from either side"
        display as error "of it into the same block."
        exit 198
    }

    local yv     "`varlist'"
    local plag   `ar'
    local dly    `delay'
    local trimv  `trim'
    local mobs   = cond(`minobs' > 0, `minobs', max(5, ceil(`trim'*60)))
    local maxblk `maxblk'
    local blk    `block'

    _tk_drop
    mata: tk_thsubci()

    if __tk_sbfail == 1 {
        _tk_drop
        display as error "too few usable observations"
        exit 2001
    }
    if __tk_sbfail == 2 {
        _tk_drop
        display as error "the full-sample SETAR could not be fitted"
        exit 498
    }
    if __tk_sbfail == 3 {
        _tk_drop
        display as error "the rate could not be estimated: too few block"
        display as error "sizes gave a usable quantile. Widen {bf:gvals()},"
        display as error "or set {bf:rate()} explicitly if you know whether"
        display as error "the model is continuous."
        exit 498
    }
    if __tk_sbfail == 4 {
        _tk_drop
        display as error "too few usable subsample blocks at that block size"
        exit 498
    }

    tempname INFO
    local rhat  = __tk_sbr
    tempname rhat_s
    scalar `rhat_s' = __tk_sbr
    local lo    = __tk_sblo
    local hi    = __tk_sbhi
    local hw    = __tk_sbhw
    local nblk  = __tk_sbnblk
    local beta  = __tk_sbbeta
    local ubeta = __tk_sbubeta
    local nrate = __tk_sbnrate
    local bused = __tk_sbb
    local nuse  = __tk_sbn
    capture confirm matrix __tk_sbinfo
    local hasinfo = (_rc == 0)
    if `hasinfo' matrix `INFO' = __tk_sbinfo
    _tk_drop

    * ------------------------------------------------ display
    display _n as text "Subsampling confidence interval for a SETAR threshold"
    display as text "{hline 74}"
    display as text "  series" _col(46) as result %26s "`yv'"
    display as text "  SETAR(2;`ar') with delay" _col(46) as result %26.0f `delay'
    display as text "  observations" _col(46) as result %26.0f `nuse'
    display as text "  block size b" _col(46) as result %26.0f `bused'
    display as text "  subsample blocks used" _col(46) as result %26.0f `nblk'
    display as text "{hline 74}"
    display as text "  threshold estimate" _col(46) as result %26.6f `rhat'
    display as text "  `level'% interval" _col(46) as result %26s ///
        "[`=string(`lo',"%9.5f")', `=string(`hi',"%9.5f")']"
    display as text "  half-width" _col(46) as result %26.6f `hw'
    display as text "{hline 74}"

    if "`rate'" == "estimate" {
        display as text "  rate exponent beta, ESTIMATED" _col(46) ///
            as result %26.4f `beta'
        display as text "  block sizes used in the rate fit" _col(46) ///
            as result %26.0f `nrate'
        if abs(`beta' - `ubeta') > 1e-9 {
            display as error "  beta was CLAMPED to " ///
                "`=string(`ubeta',"%5.3f")' for the interval."
            display as error "  The theory says beta is 0.5 (continuous) or"
            display as error "  1 (discontinuous). An estimate outside a"
            display as error "  generous bracket around that range is a"
            display as error "  failure of the estimator on this sample, not"
            display as error "  a refinement of the theory, and using it"
            display as error "  would give an interval wrong by a power of n."
        }
        else {
            local lean "neither clearly"
            if `beta' < 0.7 local lean "towards CONTINUOUS (a kink)"
            if `beta' > 0.8 local lean "towards DISCONTINUOUS (a jump)"
            display as text "  that leans" _col(46) as result %26s "`lean'"
        }
    }
    else {
        display as text "  rate exponent beta, ASSUMED" _col(46) ///
            as result %26.4f `ubeta'
        display as text "  (you asserted the model is `rate')"
    }
    display as text "{hline 74}"

    * ------------------------------------------------ the standing notes
    display as text "  WHY THE RATE IS THE WHOLE PROBLEM. The limit of the"
    display as text "  threshold estimator depends on something usually"
    display as text "  unknown: with a JUMP the rate is n and the limit is"
    display as text "  the argmin of a compound Poisson process, which nobody"
    display as text "  knows how to estimate consistently; with a KINK the"
    display as text "  rate is n^(1/2) and the limit is normal. The two rates"
    display as text "  differ by a factor of n^(1/2), so an interval built on"
    display as text "  the wrong one is not slightly wrong -- it is wrong by"
    display as text "  a factor that GROWS with the sample."
    display as text ""
    display as text "  Subsampling needs neither limit. The rate is read off"
    display as text "  the speed at which subsample estimates concentrate as"
    display as text "  the block grows, so the interval is valid under either"
    display as text "  case without being told which."
    display as text ""
    display as text "  The interval is SYMMETRIC about the estimate by"
    display as text "  construction. The true limiting distribution is not"
    display as text "  symmetric in the jump case, so read this as a valid"
    display as text "  interval, not as a picture of the sampling density."
    display as text ""
    display as text "  Compare with {bf:thregress, ci(lr)} for the inverted"
    display as text "  likelihood ratio, and with {bf:estat gridboot} for the"
    display as text "  grid bootstrap. They answer the same question by"
    display as text "  different routes and can disagree; when they do, say so."

    * ------------------------------------------------ stored results
    return scalar gamma  = `rhat_s'
    return scalar lb     = `lo'
    return scalar ub     = `hi'
    return scalar hw     = `hw'
    return scalar beta   = `beta'
    return scalar beta_used = `ubeta'
    return scalar block  = `bused'
    return scalar nblocks = `nblk'
    return scalar nrate  = `nrate'
    return scalar N      = `nuse'
    return scalar level  = `level'
    return scalar ar     = `ar'
    return scalar delay  = `delay'
    return local  rate   "`rate'"
    return local  cmd    "thsubci"
    return local  depvar "`yv'"
    if `hasinfo' return matrix rateinfo = `INFO', copy
end
