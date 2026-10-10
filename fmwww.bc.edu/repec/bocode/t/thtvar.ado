*! thtvar 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold vector autoregression: two regimes, unknown threshold, with a
*! bootstrap LR test of a linear VAR against the TVAR.
*! Tsay (1998) JASA 93:1188-1202, doi:10.1080/01621459.1998.10473779
*! Balke (2000) REStat 82:344-349, doi:10.1162/rest.2000.82.2.344
*! Lo & Zivot (2001) Macroeconomic Dynamics 5:533-576, doi:10.1017/S1365100501023057
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789

program define thtvar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thtvar" error 301
        Display
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] , ///
        [ LAGS(integer 1)                        ///
          NTHRESH(integer 1)                     ///
          REFINE(integer 0)                      ///
          THVar(varname numeric ts)              ///
          DELAY(integer 1)                       ///
          TRIM(real 0.15)                        ///
          GRIDn(integer 0)                       ///
          MINOBS(integer 0)                      ///
          noCONStant                             ///
          TEST                                   ///
          STAT(string)                           ///
          REPS(integer 500)                      ///
          BOOT(string)                           ///
          SEED(string)                           ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thtvar} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `lags' < 1 {
        display as error "{bf:lags()} must be 1 or more"
        exit 198
    }
    if `nthresh' < 1 | `nthresh' > 4 {
        display as error "{bf:nthresh()} must be between 1 and 4"
        exit 198
    }
    if `refine' < 0 {
        display as error "{bf:refine()} must be 0 or more"
        exit 198
    }
    local refinen `refine'
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if "`stat'" == "" local stat sup
    local statnum = .
    if "`stat'" == "sup" local statnum 1
    if "`stat'" == "ave" local statnum 2
    if "`stat'" == "exp" local statnum 3
    if `statnum' == . {
        display as error "stat() must be sup, ave or exp"
        exit 198
    }
    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "wild") {
        display as error "boot() must be resample or wild"
        exit 198
    }
    local boottype `boot'
    local dotest  = cond("`test'"!="", 1, 0)
    local hascons = cond("`constant'"=="", 1, 0)
    if "`seed'" != "" set seed `seed'

    local yvars `varlist'
    local k : word count `yvars'

    marksample touse
    markout `touse' `yvars'

    * ---- build the lag matrix
    local wvars ""
    local wnames ""
    forvalues j = 1/`lags' {
        foreach v of local yvars {
            tempvar w`j'_`v'
            quietly generate double `w`j'_`v'' = L`j'.`v' if `touse'
            local wvars `wvars' `w`j'_`v''
            local wnames `wnames' L`j'.`v'
        }
    }
    markout `touse' `wvars'

    * ---- threshold variable
    tempvar qv
    local girfok 0
    local qeq 0
    local delayv .
    if "`thvar'" != "" {
        quietly generate double `qv' = `thvar' if `touse'
        local qname "`thvar'"
    }
    else {
        local first : word 1 of `yvars'
        quietly generate double `qv' = L`delay'.`first' if `touse'
        local qname "L`delay'.`first'"
        local delayv `delay'
        local qeq 1
        * a generalised impulse response can be simulated only when the
        * threshold variable is a lag the lag block already carries
        if `delay' <= `lags' local girfok 1
    }
    markout `touse' `qv'
    local qvar `qv'

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

    if `nthresh' == 1 {
        mata: tk_thtvar()
    }
    else {
        * three or more regimes: the sequential search with refinement, and
        * the test becomes m-1 against m rather than linear against two
        mata: tk_thtvarm()
    }

    * ---- names. For one threshold the engine stacks (vec(B1)', vec(B2)'),
    *      which is regime major then equation; for m >= 2 the multiple-
    *      threshold engine stacks vec(B) with B = (B_1, ..., B_{m+1}), which
    *      is the same ordering. So one naming loop serves both.
    local nreg = `nthresh' + 1
    local cn ""
    local ce ""
    forvalues r = 1/`nreg' {
        foreach dv of local yvars {
            if `hascons' {
                local cn `cn' _cons
                local ce `ce' R`r'_`dv'
            }
            foreach w of local wnames {
                local cn `cn' `w'
                local ce `ce' R`r'_`dv'
            }
        }
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

    ereturn post `b' `V', esample(`touse') obs(`nobs')

    ereturn local cmd        "thtvar"
    ereturn local cmdline    "thtvar `0'"
    ereturn local title      "Threshold vector autoregression"
    ereturn local model      "tvar"
    ereturn local estimator  "regime-wise least squares (concentrated ln|Sigma|)"
    ereturn local depvars    "`yvars'"
    ereturn local lagnames   "`wnames'"
    ereturn local threshold_var "`qname'"
    ereturn local timevar    "`timevar'"
    ereturn local properties "b V"
    ereturn local estat_cmd  "thtvar_estat"
    ereturn local predict    "thtvar_p"
    ereturn local wnames     "`wnames'"
    ereturn scalar hascons   = `hascons'
    ereturn scalar girf_ok   = `girfok'
    ereturn scalar q_eq      = `qeq'
    if "`delayv'" != "." ereturn scalar delay = `delayv'

    ereturn scalar N        = __tk_n
    ereturn scalar k_eq     = (`nthresh' + 1) * `k'
    ereturn scalar k_var    = __tk_k
    ereturn scalar lags     = `lags'
    ereturn scalar nthresh  = `nthresh'
    if `nthresh' == 1 ereturn scalar gamma = __tk_gamma
    if `nthresh' == 1 {
        ereturn scalar N_regime1 = __tk_n1
        ereturn scalar N_regime2 = __tk_n2
    }
    ereturn scalar lndet    = __tk_lndet
    ereturn scalar lndet0   = __tk_lndet0
    ereturn scalar ll       = __tk_ll
    ereturn scalar ll_0     = __tk_ll0
    ereturn scalar aic      = __tk_aic
    if `nthresh' > 1 ereturn scalar k_par = __tk_npar
    ereturn scalar bic      = __tk_bic
    ereturn scalar hqic     = __tk_hqic
    ereturn scalar trim     = `trim'
    ereturn scalar level    = `level'
    if `dotest' {
        ereturn scalar lr        = __tk_lr
        ereturn scalar p         = __tk_p
        ereturn scalar p_mcse    = sqrt(__tk_p*(1-__tk_p)/`reps')
        ereturn scalar boot_reps = `reps'
        ereturn local  boot      "`boot'"
        if `nthresh' == 1 {
            ereturn scalar lr_sup    = __tk_lrsup
            ereturn scalar lr_ave    = __tk_lrave
            ereturn scalar lr_exp    = __tk_lrexp
            ereturn scalar gamma_test = __tk_gmax
            ereturn local  teststat  "`stat'"
        }
        else {
            * with m >= 2 the null is m-1 regimes, not linearity, and the
            * functional is the plain LR: there is no single gamma to take a
            * sup over, because m-1 of them are already in the model
            ereturn local teststat "lr"
            ereturn scalar test_m0 = `nthresh' - 1
            ereturn scalar test_m1 = `nthresh'
        }
        capture ereturn matrix bdist = __tk_bdist
    }
    tempname M
    matrix `M' = __tk_sigma
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `yvars'
    ereturn matrix Sigma = `M'
    if `nthresh' == 1 {
        matrix `M' = __tk_profile
        matrix colnames `M' = gamma lndet
        ereturn matrix profile = `M'
        matrix `M' = __tk_b2
        matrix colnames `M' = `yvars'
        ereturn matrix B2 = `M'
        matrix `M' = __tk_b1
        matrix colnames `M' = `yvars'
        ereturn matrix B1 = `M'
        tempname TH NR
        matrix `TH' = J(1, 1, __tk_gamma)
        matrix colnames `TH' = gamma1
        ereturn matrix thresholds = `TH'
        matrix `NR' = (__tk_n1, __tk_n2)
        matrix colnames `NR' = regime1 regime2
        ereturn matrix nobs_regime = `NR'
    }
    else {
        tempname TH NR
        matrix `TH' = __tk_gammas
        local thn ""
        forvalues j = 1/`nthresh' {
            local thn `thn' gamma`j'
        }
        matrix colnames `TH' = `thn'
        ereturn matrix thresholds = `TH'
        matrix `NR' = __tk_nreg
        local rn ""
        forvalues j = 1/`=`nthresh'+1' {
            local rn `rn' regime`j'
        }
        matrix colnames `NR' = `rn'
        ereturn matrix nobs_regime = `NR'
        matrix `M' = __tk_bmat
        ereturn matrix Bmat = `M'
        matrix `M' = __tk_sel
        matrix colnames `M' = m lndet ll aic bic hqic
        ereturn matrix select = `M'
    }

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local m = e(nthresh)
    if `m' == . local m 1
    tempname TH NR
    matrix `TH' = e(thresholds)
    matrix `NR' = e(nobs_regime)
    local g : display %10.0g `TH'[1,1]
    local g = trim("`g'")
    if `m' > 1 {
        local g ""
        forvalues j = 1/`m' {
            local gj : display %10.0g `TH'[1,`j']
            local g "`g' `=trim("`gj'")'"
        }
        local g = trim("`g'")
    }
    display ""
    display as text "Threshold vector autoregression" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Variables: " as result "`e(depvars)'" _col(52) ///
        as text "Lags" _col(68) "=" _col(71) as result %9.0f e(lags)
    display as text "  Threshold variable: " as result "`e(threshold_var)'" _col(52) ///
        as text "ln|Sigma|" _col(68) "=" _col(71) as result %9.5f e(lndet)
    display as text "  Time variable: " as result "`e(timevar)'" _col(52) ///
        as text "BIC" _col(68) "=" _col(71) as result %9.3f e(bic)
    display ""
    display as text "{hline 78}"
    display as text "  Threshold estimate(s)" _col(28) as result %24s "`g'"
    display as text "  ln|Sigma| linear VAR" _col(28) as result %14.5f e(lndet0)
    local obsline ""
    forvalues j = 1/`=`m'+1' {
        local nj : display %7.0fc `NR'[1,`j']
        local obsline "`obsline' `=trim("`nj'")'"
    }
    display as text "  Observations by regime" _col(28) as result "`=trim("`obsline'")'"
    display as text "{hline 78}"
    if `m' > 1 {
        tempname SELM
        matrix `SELM' = e(select)
        display as text "  Fit by number of thresholds"
        display as text "    m" _col(14) "ln|Sigma|" _col(28) "ll" _col(42) ///
            "AIC" _col(56) "BIC"
        forvalues r = 1/`=rowsof(`SELM')' {
            display as text "    " as result %2.0f `SELM'[`r',1] ///
                _col(8) %12.6f `SELM'[`r',2] _col(22) %12.3f `SELM'[`r',3] ///
                _col(36) %12.3f `SELM'[`r',4] _col(50) %12.3f `SELM'[`r',5]
        }
        display as text "{hline 78}"
    }
    if e(p) < . & `m' > 1 {
        display as text "  Test of H0: " as result "`=e(test_m0)'" as text ///
            " threshold(s) against " as result "`=e(test_m1)'"
        display as text "     LR" _col(28) as result %14.4f e(lr)
        display as text "     bootstrap p" _col(28) as result %14.4f e(p) ///
            as text _col(48) "`e(boot_reps)' reps, MC s.e. " %5.4f e(p_mcse)
        display as text "{hline 78}"
        display as text "  The EXTRA threshold is unidentified under this null, so the"
        display as text "  statistic is not chi-square: the p-value is simulated with the"
        display as text "  design and the threshold variable held fixed (`e(boot)')."
        display as text "  The sequential search finds the thresholds one at a time and"
        display as text "  then sweeps each again holding the others fixed, because a"
        display as text "  threshold found first is conditional on a model that did not"
        display as text "  yet contain the second."
    }
    else if e(p) < . {
        display as text "  Test of H0: linear VAR against a two-regime TVAR"
        display as text "     `e(teststat)'-LR" _col(28) as result %14.4f e(lr) ///
            as text _col(48) "argmax at " as result %9.0g e(gamma_test)
        display as text "     bootstrap p" _col(28) as result %14.4f e(p) ///
            as text _col(48) "`e(boot_reps)' reps, MC s.e. " %5.4f e(p_mcse)
        display as text "     sup / ave / exp" _col(28) as result ///
            %8.3f e(lr_sup) " " %8.3f e(lr_ave) " " %8.3f e(lr_exp)
        display as text "{hline 78}"
        display as text "  The LR statistic is n(ln|Sigma_0| - ln|Sigma(gamma)|). Under H0 the"
        display as text "  threshold is unidentified, so the p-value is simulated with the"
        display as text "  regressors and the threshold variable held fixed (`e(boot)')."
    }
    display ""
    display as text "  Log likelihood uses -n/2 (k(ln 2pi + 1) + ln|Sigma|)."
    display as text "  Tsay (1998) as published used ln|n Sigma| by mistake, which shifts"
    display as text "  every information criterion by (n k / 2) ln n. THRESHKIT does not."
    display ""
    _coef_table, level(`=e(level)')
end
