*! thnseq 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! The number of regimes by the Strikholm-Terasvirta sequential procedure.
*!
*!   Strikholm, B. and T. Terasvirta (2006) "A sequential procedure for
*!     determining the number of regimes in a threshold autoregressive
*!     model", Econometrics Journal 9:472-491,
*!     doi:10.1111/j.1368-423X.2006.00194.x
*!   Chan, K. S. (1993) Annals of Statistics 21:520-533,
*!     doi:10.1214/aos/1176349040  (the super-consistency that the whole
*!     procedure rests on)
*!   Luukkonen, Saikkonen and Terasvirta (1988) Biometrika 75:491-499,
*!     doi:10.1093/biomet/75.3.491  (the Taylor-expansion linearity test)
*!
*! See thnseq.sthlp.
*!
*! THE IDEA, AND WHY IT IS CHEAP.
*!
*! Adding a regime to a threshold model is normally expensive to test,
*! because the new threshold is not identified under the null and the
*! statistic has to be bootstrapped (which is what thnregimes does).
*! Strikholm and Terasvirta avoid that entirely, and the reason is Chan
*! (1993): the threshold estimates are SUPER-CONSISTENT, converging at rate
*! T rather than root-T, and -- the part that matters here -- they stay
*! super-consistent even when FEWER thresholds are fitted than the truth.
*!
*! So at every stage the thresholds already found can be treated as KNOWN.
*! The current model is then just a linear model in regime-interacted
*! regressors, and "is there another regime?" becomes an ordinary LINEARITY
*! test with a chi-squared limit. No bootstrap, no unidentified nuisance
*! parameter, no Davies problem.
*!
*! THE SHRINKING SIGNIFICANCE LEVEL is not a detail either. Each stage is
*! tested at tau times the level of the one before, which biases the
*! sequence towards parsimony; and the whole procedure is consistent only
*! because alpha is meant to fall with T. Running a fixed 5% at every stage
*! would keep finding regimes in long series.

program define thnseq, rclass
    version 15

    syntax varname(numeric ts) [if] [in] ,  ///
        [ AR(numlist integer >0 sort)       ///
          THRESHvar(varname numeric ts)     ///
          XVars(varlist numeric ts)         ///
          DELAY(integer 1)                  ///
          MMAX(integer 3)                   ///
          ALpha(real 0.05)                  ///
          TAU(real 0.5)                     ///
          ORDer(integer 3)                  ///
          TRIM(real 0.15)                   ///
          MINObs(integer 0)                 ///
          noCONStant ]

    * ------------------------------------------------ option validation
    if !inlist(`order', 1, 3, 4) {
        display as error "{bf:order()} must be 1, 3 or 4."
        display as error "3 is the Luukkonen-Saikkonen-Terasvirta default"
        display as error "(the squared terms vanish identically, so the"
        display as error "expansion jumps from 1 to 3); 4 adds the quartic"
        display as error "terms that carry power against an exponential"
        display as error "transition."
        exit 198
    }
    if `mmax' < 1 | `mmax' > 6 {
        display as error "{bf:mmax()} must be between 1 and 6"
        exit 198
    }
    if `alpha' <= 0 | `alpha' >= 1 {
        display as error "{bf:alpha()} must be in (0,1)"
        exit 198
    }
    * tau < 1 is what biases the sequence towards parsimony; tau >= 1 would
    * make each later test EASIER to reject, which is the opposite of the
    * procedure and would over-state the number of regimes
    if `tau' <= 0 | `tau' > 1 {
        display as error "{bf:tau()} must be in (0,1]."
        display as error "It shrinks the significance level at each stage, so"
        display as error "a value above 1 would make later tests easier to"
        display as error "reject and over-state the number of regimes. The"
        display as error "paper uses 0.5."
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if "`ar'" == "" & "`xvars'" == "" {
        display as error "specify {bf:ar()} for a self-exciting model, or"
        display as error "{bf:xvars()} with {bf:threshvar()} for a threshold"
        display as error "regression."
        exit 198
    }

    capture tsset
    if _rc & "`ar'" != "" {
        display as error "{bf:ar()} needs the data {bf:tsset}"
        exit 111
    }

    local yv "`varlist'"
    marksample touse

    * ------------------------------------------------ the regressors
    local xl ""
    local xlab ""
    foreach k of local ar {
        tempvar a`k'
        quietly generate double `a`k'' = L`k'.`yv' if `touse'
        local xl `xl' `a`k''
        local xlab `xlab' L`k'.`yv'
    }
    if "`xvars'" != "" {
        quietly tsrevar `xvars'
        local xl `xl' `r(varlist)'
        local xlab `xlab' `xvars'
    }

    * ------------------------------------------------ the threshold variable
    if "`threshvar'" != "" {
        quietly tsrevar `threshvar'
        local sv "`r(varlist)'"
        local slab "`threshvar'"
    }
    else {
        tempvar ss
        quietly generate double `ss' = L`delay'.`yv' if `touse'
        local sv "`ss'"
        local slab "L`delay'.`yv'"
    }

    markout `touse' `xl' `sv'
    quietly count if `touse'
    local nobs = r(N)
    local kx : word count `xl'
    if `nobs' < 10*(`kx' + 1) {
        display as error "too few observations (`nobs') for `kx' regressors"
        exit 2001
    }
    local mobs = cond(`minobs' > 0, `minobs', max(5, ceil(`trim'*`nobs')))

    * the Taylor terms: x_t times powers of the threshold variable. These
    * are the SAME at every stage -- only the null model changes.
    * The raw expansion of a logistic transition has vanishing square
    * powers, but the auxiliary regression is written in the IDENTIFIED
    * parameters after recombination, and there the quadratic block is
    * present -- it is exactly the block Terasvirta's F2 tests. So order 3
    * means z, z^2, z^3 and not z, z^3.
    local tay ""
    local plist "1"
    if `order' == 3 local plist "1 2 3"
    if `order' == 4 local plist "1 2 3 4"
    local j 0
    foreach v of local xl {
        local ++j
        foreach k of local plist {
            tempvar ty`j'_`k'
            quietly generate double `ty`j'_`k'' = `v'*`sv'^`k' if `touse'
            local tay `tay' `ty`j'_`k''
        }
    }
    * x_t contains the CONSTANT, so the powers of the threshold variable
    * must also enter on their own. Leaving them out would silently test a
    * smaller hypothesis than the one the procedure specifies.
    if "`constant'" == "" {
        foreach k of local plist {
            tempvar tc_`k'
            quietly generate double `tc_`k'' = `sv'^`k' if `touse'
            local tay `tay' `tc_`k''
        }
    }

    * ------------------------------------------------ the sequence
    tempname HOLD
    capture _estimates hold `HOLD', restore nullok

    tempname GAMS PV STAT LEV
    matrix `GAMS' = J(1, `mmax', .)
    matrix `PV'   = J(1, `=`mmax'+1', .)
    matrix `STAT' = J(1, `=`mmax'+1', .)
    matrix `LEV'  = J(1, `=`mmax'+1', .)

    local mhat    = .
    local stage   0
    local lev     = `alpha'
    local stopped 0
    local nfit    0

    display _n as text ///
        "Number of regimes: the Strikholm-Terasvirta sequential procedure"
    display as text "{hline 76}"
    display as text "  series" _col(46) as result %30s "`yv'"
    display as text "  threshold variable" _col(46) as result %30s "`slab'"
    display as text "  regressors" _col(46) as result %30s "`xlab'"
    display as text "  observations" _col(46) as result %30.0f `nobs'
    display as text "  Taylor order" _col(46) as result %30.0f `order'
    display as text "  starting level alpha" _col(46) as result %30.4f `alpha'
    display as text "  level shrinkage tau" _col(46) as result %30.4f `tau'
    display as text "{hline 76}"
    display as text "  stage" _col(14) "H0: m =" _col(26) "level" ///
        _col(38) "F" _col(52) "p" _col(64) "verdict"
    display as text "  {hline 72}"

    * regime dummies accumulate as thresholds are found
    local dums ""
    local gfound ""

    forvalues m = 0/`mmax' {
        * ---- the null model at this stage: the linear part, interacted
        * with the regimes implied by the thresholds found so far. With
        * m = 0 that is just the linear model.
        local nullx "`xl'"
        if `m' > 0 {
            * the regime-interacted design: every regressor in every regime,
            * plus a per-regime constant unless noconstant was asked for
            local nullx ""
            local r 0
            foreach d of local dums {
                local ++r
                local vv 0
                foreach v of local xl {
                    local ++vv
                    tempvar ri`m'_`r'_`vv'
                    quietly generate double `ri`m'_`r'_`vv'' = `v'*`d' ///
                        if `touse'
                    local nullx `nullx' `ri`m'_`r'_`vv''
                }
                if "`constant'" == "" {
                    tempvar rc`m'_`r'
                    quietly generate double `rc`m'_`r'' = `d' if `touse'
                    local nullx `nullx' `rc`m'_`r''
                }
            }
        }

        * ---- the linearity test of that null against one more transition
        local useconst "`constant'"
        if `m' > 0 local useconst "noconstant"
        capture quietly regress `yv' `nullx' `tay' if `touse', `useconst'
        if _rc {
            display as error "  the auxiliary regression failed at stage `m'"
            continue, break
        }
        local dfr = e(df_r)
        if `dfr' < 5 {
            display as error "  stage `m': only `dfr' residual df left; stopping"
            continue, break
        }
        quietly test `tay'
        local F = r(F)
        local pv = Ftail(r(df), `dfr', r(F))

        matrix `STAT'[1, `=`m'+1'] = `F'
        matrix `PV'[1, `=`m'+1']   = `pv'
        matrix `LEV'[1, `=`m'+1']  = `lev'

        local verdict = cond(`pv' < `lev', "reject", "STOP")
        display as text "  " %-10.0f `m' _col(14) %6.0f `m' ///
            _col(24) as result %8.4f `lev' ///
            _col(34) %10.4f `F' _col(48) %10.4f `pv' ///
            _col(62) as text cond(`pv' < `lev', "{txt}", "{res}") "`verdict'"

        if `pv' >= `lev' {
            local mhat = `m'
            local stopped 1
            continue, break
        }
        if `m' == `mmax' {
            local mhat = `mmax'
            display as error "  reached mmax(`mmax') still rejecting; the"
            display as error "  sequence did not terminate on its own."
            continue, break
        }

        * ---- rejected: estimate one more threshold and carry on
        local mnew = `m' + 1
        capture quietly thregress `yv' `xl' if `touse', ///
            threshvar(`sv') nthresh(`mnew') trim(`trim') minobs(`mobs') ///
            `constant'
        if _rc {
            display as error "  could not place `mnew' threshold(s); stopping"
            local mhat = `m'
            local stopped 1
            continue, break
        }
        local ++nfit
        tempname TT
        matrix `TT' = e(thresholds)
        local gfound ""
        local nt = max(rowsof(`TT'), colsof(`TT'))
        forvalues i = 1/`nt' {
            local gi = cond(rowsof(`TT') >= colsof(`TT'), `TT'[`i',1], `TT'[1,`i'])
            local gfound `gfound' `gi'
            if `i' <= `mmax' matrix `GAMS'[1, `i'] = `gi'
        }

        * rebuild the regime dummies from the thresholds found
        local dums ""
        local prev = .
        local r 0
        foreach g of local gfound {
            local ++r
            tempvar dd`mnew'_`r'
            if `r' == 1 {
                quietly generate byte `dd`mnew'_`r'' = (`sv' <= `g') if `touse'
            }
            else {
                quietly generate byte `dd`mnew'_`r'' = ///
                    (`sv' > `prev' & `sv' <= `g') if `touse'
            }
            local dums `dums' `dd`mnew'_`r''
            local prev = `g'
        }
        local ++r
        tempvar dd`mnew'_`r'
        quietly generate byte `dd`mnew'_`r'' = (`sv' > `prev') if `touse'
        local dums `dums' `dd`mnew'_`r''

        * the level shrinks for the next stage
        local lev = `lev'*`tau'
    }

    capture _estimates unhold `HOLD'

    display as text "  {hline 72}"
    display as text "{hline 76}"
    display as text "  thresholds selected" _col(46) as result %30.0f `mhat'
    display as text "  regimes selected" _col(46) as result %30.0f `=`mhat'+1'
    if `mhat' > 0 {
        local gl ""
        forvalues i = 1/`mhat' {
            local gi = `GAMS'[1,`i']
            local gl = cond(`i' == 1, "`=string(`gi',"%9.4f")'", ///
                            "`gl', `=string(`gi',"%9.4f")'")
        }
        display as text "  threshold estimate(s)" _col(46) as result %30s "`gl'"
    }
    display as text "{hline 76}"

    * ------------------------------------------------ the standing notes
    display as text "  Each stage treats the thresholds already found as"
    display as text "  {bf:known}. That is legitimate because threshold"
    display as text "  estimates are super-consistent (Chan 1993), converging"
    display as text "  at rate T against root-T for everything else, and they"
    display as text "  stay so even when fewer thresholds are fitted than the"
    display as text "  truth. Each test is then an ordinary linearity test"
    display as text "  with a chi-squared limit -- which is why this"
    display as text "  procedure needs no bootstrap at all."
    display as text ""
    display as text "  The level FALLS by a factor of tau at each stage. That"
    display as text "  favours parsimony deliberately; the paper uses 0.5."
    display as text "  Consistency also needs alpha to fall with the sample"
    display as text "  size, so a fixed 5% at every stage will keep finding"
    display as text "  regimes in a long series."
    if `mhat' > 0 {
        display as text ""
        display as text "  Fit it with:"
        display as text "    {bf:thregress `yv' `xlab', threshvar(`slab') nthresh(`mhat')}"
    }
    display as text ""
    display as text "  Compare with {helpb thnregimes}, which tests the same"
    display as text "  question by bootstrapping the full F(j|i) triangle, and"
    display as text "  with {helpb thselect}, which uses information criteria."
    display as text "  They can disagree; when they do, say so."

    * ------------------------------------------------ stored results
    return scalar m       = `mhat'
    return scalar regimes = `=`mhat'+1'
    return scalar N       = `nobs'
    return scalar alpha   = `alpha'
    return scalar tau     = `tau'
    return scalar order   = `order'
    return scalar mmax    = `mmax'
    return scalar stopped = `stopped'
    return scalar nfit    = `nfit'
    if `mhat' > 0 {
        return scalar gamma1 = `GAMS'[1,1]
    }
    if `mhat' > 1 {
        return scalar gamma2 = `GAMS'[1,2]
    }
    return local  cmd     "thnseq"
    return local  depvar  "`yv'"
    return local  thvar   "`slab'"
    return matrix gammas  = `GAMS', copy
    return matrix p       = `PV', copy
    return matrix F       = `STAT', copy
    return matrix levels  = `LEV', copy
end
