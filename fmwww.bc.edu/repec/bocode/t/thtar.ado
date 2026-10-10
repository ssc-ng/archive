*! thtar 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold autoregression: SETAR(m+1; p, d) and TAR with an exogenous
*! threshold variable. Builds the autoregression, searches the delay, and
*! hands the design to the shared THRESHKIT threshold engine.
*! Hansen (1997) SNDE 2(1), doi:10.2202/1558-3708.1024
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Hansen (2000) Econometrica 68:575-603, doi:10.1111/1468-0262.00124
*! Tong (1990); Chan (1993) Ann. Statist. 21:520-533, doi:10.1214/aos/1176349040

program define thtar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thtar" error 301
        Header
        ereturn local cmd "thregress"
        thregress, `0'
        ereturn local cmd "thtar"
        exit
    }

    syntax varname(numeric ts) [if] [in] , ///
        [ AR(numlist integer >0 sort)       ///
          THVar(varname numeric ts)         ///
          DELAY(numlist integer >0 sort)    ///
          NTHRESH(integer 1)                ///
          REFINE(integer 0)                 ///
          MINOBS(integer 0)                 ///
          TRIM(real 0.15)                   ///
          GRIDn(integer 0)                  ///
          noCONStant                        ///
          VCE(string)                       ///
          ETA2(string)                      ///
          BWidth(real 0)                    ///
          CI(string)                        ///
          CONSERVative                      ///
          RHO(real 0.8)                     ///
          ESTimator(string)                 ///
          CONTinuous                        ///
          HETvar                            ///
          HANSENCOMPAT                      ///
          TEST                              ///
          REPS(integer 1000)                ///
          SEED(string)                      ///
          STAT(string)                      ///
          REGimevar(name)                   ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thtar} requires the data to be {bf:tsset}"
        display as error "a threshold autoregression needs a time index"
        exit 459
    }
    local timevar "`r(timevar)'"

    if "`ar'" == "" local ar 1
    local p : word count `ar'
    local pmax = 0
    foreach j of local ar {
        if `j' > `pmax' local pmax = `j'
    }

    if "`delay'" == "" local delay 1
    local nd : word count `delay'
    if "`thvar'" != "" & `nd' > 1 {
        display as error "{bf:delay()} searches the SETAR delay; it cannot be combined"
        display as error "with an exogenous {bf:thvar()}"
        exit 198
    }

    local depv `varlist'

    * ------------------------------------------------ build the autoregression
    tempvar touse
    mark `touse' `if' `in'
    markout `touse' `depv'

    local xlist ""
    foreach j of local ar {
        tempvar l`j'
        quietly generate double `l`j'' = L`j'.`depv' if `touse'
        local xlist `xlist' `l`j''
        local arnames `arnames' L`j'.`depv'
    }
    markout `touse' `xlist'

    * ------------------------------------------------ delay search
    local bestd = .
    local bestssr = .
    if "`thvar'" != "" {
        local qv `thvar'
        markout `touse' `qv'
        local dsel .
    }
    else {
        tempvar qtmp
        foreach d of local delay {
            capture drop `qtmp'
            quietly generate double `qtmp' = L`d'.`depv' if `touse'
            tempvar tu2
            quietly generate byte `tu2' = `touse' & !missing(`qtmp')
            quietly count if `tu2'
            if r(N) < 20 continue
            capture quietly thregress `depv' `xlist' if `tu2', ///
                threshvar(`qtmp') trim(`trim') ci(none) `constant' ///
                nthresh(`nthresh') minobs(`minobs')
            if _rc continue
            if `bestssr' == . | e(ssr) < `bestssr' {
                local bestssr = e(ssr)
                local bestd = `d'
            }
        }
        if `bestd' == . {
            display as error "no admissible delay in {bf:delay(`delay')}"
            exit 459
        }
        local dsel `bestd'
        tempvar qv
        quietly generate double `qv' = L`bestd'.`depv' if `touse'
        local qname "L`bestd'.`depv'"
        markout `touse' `qv'
    }
    if "`thvar'" != "" local qname "`thvar'"

    * ================================================================
    * CONTINUOUS (kink) SETAR -- Chan and Tsay (1998), Biometrika 85:413-426,
    * doi:10.1093/biomet/85.2.413 (verified 2026-10-06).
    *
    *   y_t = phi0 + phi1 y_{t-d} + phi2 (y_{t-d} - r) 1{y_{t-d} > r}
    *              + (other lags) + e_t
    *
    * The conditional mean is CONTINUOUS at r: the slope on y_{t-d} changes
    * but the level does not jump. That one restriction changes the
    * asymptotics completely. In the discontinuous SETAR the threshold
    * converges at rate n and its limit is not normal, so it gets an
    * inverted-likelihood-ratio interval and no standard error. Chan and
    * Tsay show that under continuity r is root-n consistent and
    * ASYMPTOTICALLY NORMAL -- so it has an ordinary standard error and a
    * Wald interval, exactly as Hansen (2017) later showed for the
    * cross-sectional kink.
    *
    * That is the same estimator thkink already implements and certifies, so
    * this delegates to it rather than duplicating the engine: the kink
    * variable is the delay lag, and the OTHER autoregressive lags are
    * ordinary regressors. The delay lag is not passed twice -- it carries
    * its own linear term through kink_below.
    * ================================================================
    if "`continuous'" != "" {
        if `nthresh' > 1 {
            display as error "{bf:continuous} fits ONE kink. A continuous"
            display as error "SETAR with several kinks in the CONDITIONAL MEAN"
            display as error "is a different model and is not implemented here."
            display as error "The nearest available thing is {bf:thqkink}, which"
            display as error "fits up to four kinks with {bf:nkinks()}, but in"
            display as error "the CONDITIONAL QUANTILE sense -- at one quantile"
            display as error "it is a median regression, not least squares, so"
            display as error "it answers a related but different question."
            exit 198
        }
        local badopt ""
        if "`hetvar'" != ""        local badopt `badopt' hetvar
        if "`ci'" != ""            local badopt `badopt' ci()
        if "`eta2'" != ""          local badopt `badopt' eta2()
        if "`conservative'" != ""  local badopt `badopt' conservative
        if "`estimator'" != ""     local badopt `badopt' estimator()
        if "`hansencompat'" != ""  local badopt `badopt' hansencompat
        if `bwidth' != 0           local badopt `badopt' bwidth()
        if "`badopt'" != "" {
            display as error "{bf:continuous} cannot be combined with:`badopt'"
            display as error "Those options all concern the inverted-likelihood"
            display as error "-ratio confidence set for a DISCONTINUOUS"
            display as error "threshold, whose limit distribution is not normal."
            display as error "Under continuity the threshold is root-n normal"
            display as error "and gets a Wald interval instead, so none of them"
            display as error "applies."
            exit 198
        }

        * the other lags: everything in ar() except the delay, which becomes
        * the kink variable and carries its own linear term
        local othervars ""
        local othernames ""
        local j 0
        foreach L of local ar {
            local ++j
            if `L' == `dsel' continue
            local v : word `j' of `xlist'
            local n : word `j' of `arnames'
            local othervars  `othervars' `v'
            local othernames `othernames' `n'
        }

        quietly thkink `depv' `othervars' if `touse', kinkvar(`qv')  ///
            trim(`trim') minobs(`minobs') `constant'                 ///
            `test' reps(`reps') seed(`seed') level(`level')

        * relabel: the engine saw temporary variables
        local cn "`qname'_below `qname'_above"
        foreach nm of local othernames {
            local cn `cn' `nm'
        }
        if "`constant'" == "" local cn `cn' _cons
        local cn `cn' gamma
        tempname bk Vk
        matrix `bk' = e(b)
        matrix `Vk' = e(V)
        local ncol = colsof(`bk')
        local nnm : word count `cn'
        if `ncol' != `nnm' {
            display as error "internal: `ncol' coefficients but `nnm' names"
            exit 498
        }
        matrix colnames `bk' = `cn'
        matrix colnames `Vk' = `cn'
        matrix rownames `Vk' = `cn'
        ereturn repost b = `bk' V = `Vk', rename

        ereturn local cmd           "thtar"
        ereturn local cmdline       "thtar `0'"
        ereturn local title         "Continuous threshold autoregression"
        ereturn local model         "setar_continuous"
        ereturn local estimator     "conditional least squares, continuous at the threshold"
        ereturn local arlags        "`ar'"
        ereturn local arnames       "`arnames'"
        ereturn local threshold_var "`qname'"
        ereturn local timevar       "`timevar'"
        * thkink stores the kink variable's NAME and six consumers read it
        * back -- predict, estat kinkplot, estat slopetest, the display. The
        * one thtar handed it was a TEMPVAR, which is gone by the time any of
        * them runs. Overwrite it with the time-series expression instead:
        * "L1.y" is valid wherever a variable is valid once the data are
        * tsset, so every consumer works unchanged and prints readably.
        ereturn local kink_var      "L`dsel'.`depv'"
        ereturn local kinkvar       "`qname'"
        ereturn scalar k_lags       = `p'
        ereturn scalar delay        = `dsel'
        ereturn local  delays       "`delay'"
        ereturn local  estat_cmd    "thkink_estat"
        ereturn local  predict      "thkink_p"

        display _n as text "Continuous (kink) SETAR -- Chan and Tsay (1998)"
        display as text "  The conditional mean does NOT jump at the threshold:"
        display as text "  the slope on " as result "`qname'" as text " changes and the level"
        display as text "  does not. Under that restriction the threshold is"
        display as text "  root-n consistent and asymptotically NORMAL, so it"
        display as text "  has an ordinary standard error and a Wald interval --"
        display as text "  which a discontinuous SETAR's threshold does not."
        display as text ""
        display as text "  If you are not sure the mean is continuous, fit both"
        display as text "  and compare: {bf:thtar} without {bf:continuous} gives"
        display as text "  the jump model, and {bf:estat gridboot} after it gives"
        display as text "  an interval valid under EITHER."
        exit
    }

    * ------------------------------------------------ final fit
    quietly thregress `depv' `xlist' if `touse', threshvar(`qv')  ///
        trim(`trim') gridn(`gridn') nthresh(`nthresh')            ///
        refine(`refine') minobs(`minobs') `constant'              ///
        vce(`vce') eta2(`eta2') bwidth(`bwidth') ci(`ci')         ///
        `conservative' rho(`rho') estimator(`estimator') `hetvar' ///
        `hansencompat' `test' reps(`reps') seed(`seed')           ///
        stat(`stat') level(`level')

    * ---- relabel the coefficients: the engine saw temporary variables
    local nreg = e(k_regime)
    local hascons = cond("`constant'"=="", 1, 0)
    local cn ""
    local ce ""
    forvalues j = 1/`nreg' {
        foreach nm of local arnames {
            local cn `cn' `nm'
            local ce `ce' Region`j'
        }
        if `hascons' {
            local cn `cn' _cons
            local ce `ce' Region`j'
        }
    }
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'
    ereturn repost b = `b' V = `V', rename

    * ---- thtar-specific e() entries
    ereturn local cmdline    "thtar `0'"
    ereturn local title      "Threshold autoregression"
    ereturn local model      = cond("`thvar'"=="", "setar", "tar")
    ereturn local arlags     "`ar'"
    ereturn local arnames    "`arnames'"
    ereturn local threshold_var "`qname'"
    ereturn local timevar    "`timevar'"
    ereturn scalar k_lags    = `p'
    ereturn scalar pmax      = `pmax'
    if "`thvar'" == "" {
        ereturn scalar delay = `dsel'
        ereturn local delays "`delay'"
    }

    * ---- a searched delay invalidates the nominal p-value: say so
    if "`test'" != "" & `nd' > 1 {
        display as text ""
        display as text "{bf:Warning.} The delay was chosen from " as result "`delay'" ///
            as text " by minimising the SSR, and"
        display as text "the threshold test is then conditional on that data-dependent choice."
        display as text "Its p-value is {bf:not} a valid test of linearity. Fix the delay with"
        display as text "{bf:delay(#)} for the reported test, or treat the search as exploratory."
    }

    * ---- header, then replay the standard threshold table
    Header
    ereturn local cmd "thregress"
    thregress
    ereturn local cmd        "thtar"
    ereturn local estat_cmd  "thregress_estat"
    ereturn local predict    "thregress_p"

    if "`regimevar'" != "" {
        capture confirm new variable `regimevar'
        if _rc {
            display as error "variable {bf:`regimevar'} already exists"
            exit 110
        }
        quietly predict byte `regimevar', regime
        label variable `regimevar' "THRESHKIT regime from thtar"
    }
end

* ----------------------------------------------------------------------
program define Header
    display ""
    display as text "Threshold autoregression" _col(50) "Time variable" _col(68) "=" ///
        _col(71) as result %9s "`e(timevar)'"
    display as text "  `e(depvar)' on lags " as result "`e(arlags)'" as text " of itself"
    if "`e(model)'" == "setar" {
        display as text "  Self-exciting: threshold is " as result "`e(threshold_var)'" ///
            as text ", delay " as result e(delay) as text " chosen from {c -(}" ///
            as result "`e(delays)'" as text "{c )-}"
    }
    else {
        display as text "  Exogenous threshold variable: " as result "`e(threshold_var)'"
    }
end
