*! thmtar 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Asymmetric (threshold) unit-root and threshold-cointegration tests:
*! TAR and momentum-TAR adjustment, with a fixed or consistently estimated
*! threshold, bootstrap p-values, and an asymmetric error-correction model.
*! Enders & Granger (1998) JBES 16:304-311, doi:10.1080/07350015.1998.10524769
*! Enders & Siklos (2001) JBES 19:166-176, doi:10.1198/073500101316970395
*! Chan (1993) Ann. Statist. 21:520-533, doi:10.1214/aos/1176349040

program define thmtar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thmtar" error 301
        Display
        exit
    }

    syntax varlist(numeric ts min=1) [if] [in] , ///
        [ MODel(string)                          ///
          LAGS(integer 0)                        ///
          THREShold(real 0)                      ///
          CONSistent                             ///
          BAND                                   ///
          BANDType(string)                       ///
          BANDLimits(numlist min=2 max=2)        ///
          ASYMmetric                             ///
          GRIDn(integer 0)                       ///
          TRIM(real 0.15)                        ///
          COINT                                  ///
          noCONStant                             ///
          VCE(string)                            ///
          REPS(integer 1000)                     ///
          BOOT(string)                           ///
          SEED(string)                           ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thmtar} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if "`model'" == "" local model tar
    if !inlist("`model'", "tar", "mtar") {
        display as error "model() must be tar or mtar"
        exit 198
    }
    local ismtar = ("`model'" == "mtar")

    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "wild") {
        display as error "boot() must be resample or wild"
        exit 198
    }
    local btype = cond("`boot'"=="wild", 2, 1)

    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `lags' < 0 {
        display as error "{bf:lags()} must be 0 or more"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    local isband = cond("`band'"!="" | "`bandtype'"!="" | "`bandlimits'"!="", 1, 0)
    if "`bandtype'" == "" local bandtype btar
    if !inlist("`bandtype'", "btar", "eqtar") {
        display as error "bandtype() must be btar (adjust to the band edge) or"
        display as error "eqtar (adjust to equilibrium)"
        exit 198
    }
    local iseqtar = cond("`bandtype'"=="eqtar", 1, 0)
    local isasym  = cond("`asymmetric'"!="", 1, 0)
    local bandlower .
    local bandupper .
    if "`bandlimits'" != "" {
        local bandlower : word 1 of `bandlimits'
        local bandupper : word 2 of `bandlimits'
        if `bandlower' >= `bandupper' {
            display as error "bandlimits() must be increasing"
            exit 198
        }
    }
    if `isband' & "`consistent'" == "" & "`bandlimits'" == "" {
        display as error "with {bf:band} give either {bf:bandlimits(# #)} or {bf:consistent}"
        exit 198
    }
    if `isband' & `isasym' & "`consistent'" != "" & `gridn' == 0 {
        local gridn 30
    }

    local robust = cond("`vce'"=="robust", 1, 0)
    local cons   = cond("`constant'"=="", 1, 0)
    local consist = cond("`consistent'"!="", 1, 0)

    local nv : word count `varlist'
    gettoken depv rest : varlist
    if "`coint'" != "" & `nv' < 2 {
        display as error "{bf:coint} needs at least two variables:"
        display as error "the dependent variable and the cointegrating regressors"
        exit 198
    }
    if "`coint'" == "" & `nv' > 1 {
        display as error "with one variable {bf:thmtar} tests for an asymmetric unit root;"
        display as error "add {bf:coint} to test for threshold cointegration among several"
        exit 198
    }

    marksample touse
    markout `touse' `varlist'

    * ------------------------------------------------ stage 1
    tempvar z
    if "`coint'" != "" {
        quietly regress `depv' `rest' if `touse'
        quietly predict double `z' if `touse', residuals
        local stage1 "Engle-Granger residual from `depv' on `rest'"
        local k1 = e(df_m)
        * keep the first-stage coefficients: predict needs to rebuild z ONE
        * PERIOD BEFORE the estimation sample, because the design uses L.z, and
        * re-running the first stage there would use a different sample
        tempname BS1
        matrix `BS1' = e(b)
    }
    else {
        quietly generate double `z' = `depv' if `touse'
        local stage1 "the series itself"
        local k1 = 0
    }

    * ------------------------------------------------ build the design
    tempvar dz zl dzl
    quietly generate double `dz'  = D.`z' if `touse'
    quietly generate double `zl'  = L.`z' if `touse'
    quietly generate double `dzl' = L.`dz' if `touse'
    local Lv ""
    forvalues j = 1/`lags' {
        tempvar dl`j'
        quietly generate double `dl`j'' = L`j'.`dz' if `touse'
        local Lv `Lv' `dl`j''
    }
    tempvar tu
    quietly generate byte `tu' = `touse' & !missing(`dz', `zl')
    if `ismtar' quietly replace `tu' = 0 if missing(`dzl')
    foreach v of local Lv {
        quietly replace `tu' = 0 if missing(`v')
    }
    quietly count if `tu'
    if r(N) < 20 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }

    local indv = cond(`ismtar', "`dzl'", "`zl'")
    local Lvars "`Lv'"

    mata: tk_thmtar()

    * ------------------------------------------------ post
    local cn = cond(`isband', "rho_above rho_below", "rho1 rho2")
    forvalues j = 1/`lags' {
        local cn `cn' LD`j'
    }
    if `cons' local cn `cn' _cons

    tempname b V
    matrix `b' = __tk_b
    matrix `V' = __tk_V
    matrix colnames `b' = `cn'
    matrix colnames `V' = `cn'
    matrix rownames `V' = `cn'

    quietly count if `tu'
    ereturn post `b' `V', esample(`tu') depname(D.`depv') obs(`r(N)')

    ereturn local cmd       "thmtar"
    ereturn local cmdline   "thmtar `0'"
    ereturn local title     = cond("`coint'"!="", "Threshold cointegration test", ///
                                                  "Asymmetric unit-root test")
    ereturn local model     "`model'"
    if `isband' {
        ereturn local model = "band-" + cond(`iseqtar', "eqtar", "btar")
    }
    ereturn local stage1    "`stage1'"
    ereturn local depvar    "`depv'"
    ereturn local cointvars "`rest'"
    ereturn local timevar   "`timevar'"
    ereturn local threshtype = cond(`consist', "consistent (Chan 1993 grid)", "fixed")
    ereturn local boot      "`boot'"
    ereturn local vcetype   = cond(`robust', "Robust", "")
    ereturn local properties "b V"
    ereturn local estat_cmd  "thmtar_estat"
    ereturn local predict    "thmtar_p"

    ereturn scalar N        = __tk_n
    ereturn scalar tau      = __tk_tau
    ereturn scalar lags     = `lags'
    ereturn scalar trim     = `trim'
    ereturn scalar ssr      = __tk_ssr
    ereturn scalar phi      = __tk_phi
    ereturn scalar p_phi    = __tk_pphi
    ereturn scalar p_mcse   = sqrt(__tk_pphi*(1-__tk_pphi)/`reps')
    ereturn scalar f_sym    = __tk_fsym
    ereturn scalar p_sym    = chi2tail(1, __tk_fsym)
    ereturn scalar tmax     = __tk_tmax
    ereturn scalar N_regime1 = __tk_n1
    ereturn scalar N_regime2 = __tk_n2
    ereturn scalar band      = `isband'
    if `isband' {
        ereturn scalar tau_lower = __tk_tl
        ereturn scalar tau_upper = __tk_tu
        ereturn scalar N_inband  = __tk_nin
        ereturn local  bandtype  "`bandtype'"
        ereturn local  bandsym   = cond(`isasym', "asymmetric", "symmetric")
        ereturn local  model     = "band-" + cond(`iseqtar', "eqtar", "btar")
    }
    ereturn scalar boot_reps = `reps'
    ereturn scalar level    = `level'
    ereturn scalar k_coint  = `k1'
    tempname M
    matrix `M' = __tk_prof
    if rowsof(`M') > 1 {
        matrix colnames `M' = tau ssr
        ereturn matrix profile = `M'
    }
    capture ereturn matrix bdist = __tk_bdist
    if "`coint'" != "" ereturn matrix b_stage1 = `BS1'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local m = upper("`e(model)'")
    local tau : display %9.0g e(tau)
    local tau = trim("`tau'")
    local isband = e(band)

    display ""
    display as text "`e(title)' — `m' adjustment" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Applied to: " as result "`e(stage1)'" _col(52) ///
        as text "Lags of D" _col(68) "=" _col(71) as result %9.0f e(lags)
    display as text "Threshold: " as result "`e(threshtype)'" _col(52) ///
        as text "SSR" _col(68) "=" _col(71) as result %9.0g e(ssr)
    if `isband' {
        local tl : display %9.0g e(tau_lower)
        local tu : display %9.0g e(tau_upper)
        display as text "Band = [" as result trim("`tl'") as text ", " ///
            as result trim("`tu'") as text "]  (`e(bandsym)', `e(bandtype)')" ///
            _col(52) as text "Model" _col(68) "=" _col(71) as result %9s "`m'"
    }
    else {
        display as text "tau = " as result "`tau'" _col(52) ///
            as text "Model" _col(68) "=" _col(71) as result %9s "`m'"
    }
    display ""
    display as text "{hline 78}"
    display as text "  H0: rho1 = rho2 = 0   (no cointegration / unit root, no adjustment)"
    display as text "     Phi statistic" _col(30) as result %10.4f e(phi) ///
        as text _col(45) "bootstrap p = " as result %6.4f e(p_phi) ///
        as text "  (" as result e(boot_reps) as text " reps)"
    if e(tmax) < . {
        display as text "     t-Max" _col(30) as result %10.4f e(tmax) ///
            as text _col(45) "MC s.e. " as result %6.4f e(p_mcse)
    }
    else {
        display as text "     " _col(45) "MC s.e. " as result %6.4f e(p_mcse)
    }
    display as text "{hline 78}"
    display as text "  H0: rho1 = rho2       (symmetric adjustment)"
    display as text "     F statistic" _col(30) as result %10.4f e(f_sym) ///
        as text _col(45) "p = " as result %6.4f e(p_sym) ///
        as text "   (standard chi2(1))"
    display as text "{hline 78}"
    if `isband' {
        display as text "  Observations above the band: " as result e(N_regime1) ///
            as text ";  inside: " as result e(N_inband) ///
            as text ";  below: " as result e(N_regime2)
        display as text "  Inside the band there is NO adjustment by construction:"
        display as text "  the series is a unit root there. That is the transaction-cost"
        display as text "  story of Balke & Fomby (1997)."
    }
    else {
        display as text "  Observations above the threshold: " as result e(N_regime1) ///
            as text ";  below: " as result e(N_regime2)
    }
    display as text "  The Phi null distribution is non-standard (Enders & Siklos 2001"
    display as text "  tabulate it); the p-value above is simulated, which also covers"
    display as text "  the estimated-threshold case their tables do not."
    display ""
    _coef_table, level(`=e(level)')
    if `isband' {
        display as text "rho1 is the adjustment speed ABOVE the band, rho2 BELOW it."
        if "`e(bandtype)'" == "btar" {
            display as text "B-TAR: the series is pulled back to the nearer band EDGE."
        }
        else {
            display as text "EQ-TAR: the series is pulled back to EQUILIBRIUM (zero)."
        }
    }
    else {
        display as text "rho1 applies when the indicator is at or above tau, rho2 below."
    }
    if !`isband' {
        if "`e(model)'" == "mtar" {
            display as text "M-TAR: the indicator is built on the lagged DIFFERENCE, so the"
            display as text "asymmetry is in the speed of adjustment to rising vs falling gaps."
        }
        else {
            display as text "TAR: the indicator is built on the lagged LEVEL of the series."
        }
    }
    if e(p_sym) < 0.05 {
        display as text "Adjustment is asymmetric at the 5% level: report both half-lives."
    }
end
