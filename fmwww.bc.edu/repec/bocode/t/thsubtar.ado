*! thsubtar 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Subset SETAR with REGIME-SPECIFIC autoregressive orders, SETAR(2; k1, k2),
*! selected by the Tong and Lim (1980) section 8 minimum-AIC procedure.
*!   Tong & Lim (1980) JRSS-B 42:245-292, doi:10.1111/j.2517-6161.1980.tb01126.x
*!   Chan (1993) Ann. Statist. 21:520-533, doi:10.1214/aos/1176349040
*!
*! thtar fits ONE lag set in both regimes. This fits a DIFFERENT order in
*! each, which is what Tong and Lim's own lynx and sunspot models are, and
*! selects (k1, k2, d, gamma) by their eqs (8.3)-(8.6). See thsubtar.sthlp
*! and validation/subset_tar/equation_map.md.

program define thsubtar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thsubtar" error 301
        Display `0'
        exit
    }

    syntax varname(numeric ts) [if] [in] ,          ///
        [ MAXP(integer 4)                           ///
          ARLower(integer -1)                       ///
          ARUpper(integer -1)                       ///
          DELAY(numlist integer >0 sort)            ///
          THReshold(string)                         ///
          TRIM(real 0.15)                           ///
          GRIDn(integer 0)                          ///
          MINObs(integer 0)                         ///
          noCONStant                                ///
          VCE(string)                               ///
          DETail                                    ///
          Level(cilevel) ]

    * ---------------------------------------------------------------- checks
    capture quietly tsset
    if _rc {
        display as error "{bf:thsubtar} requires the data to be {bf:tsset}"
        display as error "the lags and the delay are taken from the time"
        display as error "order, so there has to be one"
        exit 459
    }
    local timevar "`r(timevar)'"
    local tdelta = r(tdelta)

    if `maxp' < 1 | `maxp' > 12 {
        display as error "{bf:maxp()} must be between 1 and 12"
        display as error "it is the largest order considered in EITHER regime"
        exit 198
    }
    if `arlower' > `maxp' | `arupper' > `maxp' {
        display as error "{bf:arlower()} and {bf:arupper()} cannot exceed" ///
            " {bf:maxp()} (`maxp')"
        exit 198
    }
    if `arlower' == 0 & "`constant'" != "" {
        display as error "{bf:arlower(0)} with {bf:noconstant} leaves nothing"
        display as error "to fit in the lower regime"
        exit 198
    }
    if `arupper' == 0 & "`constant'" != "" {
        display as error "{bf:arupper(0)} with {bf:noconstant} leaves nothing"
        display as error "to fit in the upper regime"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `minobs' < 0 {
        display as error "{bf:minobs()} cannot be negative"
        exit 198
    }
    if "`delay'" == "" local delay 1
    local dmax 0
    foreach d of local delay {
        if `d' > `dmax' local dmax `d'
    }
    if `dmax' > `maxp' {
        display as error "a delay of `dmax' exceeds {bf:maxp()} (`maxp')."
        display as error "The transition variable would then not be part of"
        display as error "the state the model propagates, so the model is not"
        display as error "self-exciting in the usual sense and none of the"
        display as error "theory behind this command would apply to it."
        exit 198
    }

    if "`vce'" == "" local vce ols
    local vce = lower("`vce'")
    if !inlist("`vce'", "ols", "robust") {
        display as error "{bf:vce()} must be {bf:ols} or {bf:robust}"
        exit 198
    }
    local robust = cond("`vce'"=="robust", 1, 0)

    local gamfix .
    if "`threshold'" != "" {
        capture confirm number `threshold'
        if _rc {
            display as error "{bf:threshold()} must be a number"
            exit 198
        }
        local gamfix `threshold'
    }

    * ----------------------------------------------------------- the sample
    local depv `varlist'
    marksample touse
    markout `touse' `depv'
    quietly summarize `timevar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    quietly count if `touse'
    local nraw = r(N)

    * THE GAP CHECK, and it has to be here rather than left to chance.
    * The engine builds the lags by ROW POSITION inside the used sample:
    * row i's first lag is row i-1. If the used rows are not contiguous in
    * time -- an internal missing value, a hole in the calendar, an if
    * restriction that removes a middle stretch -- then row i-1 is not the
    * previous PERIOD, and the model fitted would silently be a different
    * model from the one reported. There is no way to detect that from the
    * output, so it is refused here.
    if `tdelta' > 0 & `tdelta' < . {
        local span = (`tmax' - `tmin')/`tdelta' + 1
        if abs(`nraw' - `span') > 0.5 {
            display as error "the estimation sample is not contiguous in time:"
            display as error "`nraw' usable observations span `span' periods."
            display as error "This command takes its lags by position inside"
            display as error "the sample, so a gap would pair observations"
            display as error "that are not one period apart and the fitted"
            display as error "model would not be the model reported."
            display as error "Fill the gap ({bf:tsfill}), or restrict to a"
            display as error "contiguous stretch with {bf:if}."
            exit 459
        }
    }
    if `nraw' < 40 {
        display as error "too few observations (`nraw'); this command needs" ///
            " at least 40"
        exit 2001
    }

    * ---- the locals the Mata driver reads
    local kmax   `maxp'
    local dlist  "`delay'"
    local hascons = cond("`constant'"=="", 1, 0)
    local k1fix  = cond(`arlower' >= 0, `arlower', .)
    local k2fix  = cond(`arupper' >= 0, `arupper', .)

    _tk_drop __tk_su_b __tk_su_V __tk_su_trace __tk_su_dtrace
    _tk_drop __tk_su_n __tk_su_off __tk_su_gamma __tk_su_d __tk_su_k1
    _tk_drop __tk_su_k2 __tk_su_aic __tk_su_aicn __tk_su_n1 __tk_su_n2
    _tk_drop __tk_su_ssr1 __tk_su_ssr2 __tk_su_s1 __tk_su_s2 __tk_su_ngrid

    mata: tk_thsubtar()

    * ------------------------------------------------------------ the names
    * The two blocks have DIFFERENT lengths, which is the point of the
    * command. k1 and k2 are read straight from the Mata scalars, never
    * through a local: a local formats through %18.0g, and although these
    * two are small integers the threshold below is an OBSERVED value of the
    * series, where that formatting has already cost this project a wrong
    * regime split once.
    local k1 = __tk_su_k1
    local k2 = __tk_su_k2
    local dsel = __tk_su_d
    local cn ""
    local ce ""
    forvalues i = 1/`k1' {
        local cn `cn' L`i'.`depv'
        local ce `ce' lower
    }
    if `hascons' {
        local cn `cn' _cons
        local ce `ce' lower
    }
    forvalues i = 1/`k2' {
        local cn `cn' L`i'.`depv'
        local ce `ce' upper
    }
    if `hascons' {
        local cn `cn' _cons
        local ce `ce' upper
    }

    tempname b V
    matrix `b' = __tk_su_b
    matrix `V' = __tk_su_V
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    * the estimation sample is the FIXED sample the engine scored on, which
    * reserves max(maxp, dmax) leading rows. Mark it so e(sample) is the
    * rows actually used and not the rows marksample kept.
    local off = __tk_su_off
    tempvar esamp ord
    quietly generate byte `esamp' = `touse'
    * `_n <= off' would be WRONG: the engine reserves the first `off' rows of
    * the USED sample, which are not the first `off' rows of the dataset
    * whenever an if/in restriction removes earlier rows. Count within touse.
    quietly generate long `ord' = sum(`touse')
    quietly replace `esamp' = 0 if `touse' & `ord' <= `off'

    quietly count if `esamp'
    local nobs = r(N)

    ereturn post `b' `V', esample(`esamp') depname(`depv') obs(`nobs')

    ereturn local cmd          "thsubtar"
    ereturn local cmdline      "thsubtar `0'"
    ereturn local title        "Subset SETAR with regime-specific AR orders"
    ereturn local model        "setar(2; k1, k2)"
    ereturn local estimator    "per-regime conditional least squares; Tong-Lim MAIC"
    ereturn local depvar       "`depv'"
    ereturn local threshold_var "L`dsel'.`depv'"
    ereturn local timevar      "`timevar'"
    ereturn local vce          "`vce'"
    ereturn local vcetype      = cond(`robust', "Robust", "")
    ereturn local properties   "b V"
    ereturn local predict      "thsubtar_p"
    ereturn local estat_cmd    "thsubtar_estat"

    ereturn scalar gamma      = __tk_su_gamma
    ereturn scalar delay      = __tk_su_d
    ereturn scalar k1         = __tk_su_k1
    ereturn scalar k2         = __tk_su_k2
    ereturn scalar maxp       = `maxp'
    ereturn scalar aic        = __tk_su_aic
    ereturn scalar aic_n      = __tk_su_aicn
    ereturn scalar N_regime1  = __tk_su_n1
    ereturn scalar N_regime2  = __tk_su_n2
    ereturn scalar ssr1       = __tk_su_ssr1
    ereturn scalar ssr2       = __tk_su_ssr2
    ereturn scalar ssr        = __tk_su_ssr1 + __tk_su_ssr2
    ereturn scalar sigma2_1   = __tk_su_s1
    ereturn scalar sigma2_2   = __tk_su_s2
    ereturn scalar n_grid     = __tk_su_ngrid
    ereturn scalar reserved   = __tk_su_off
    ereturn scalar trim       = `trim'
    ereturn scalar hascons    = `hascons'
    ereturn scalar level      = `level'

    tempname TR DT
    matrix `TR' = __tk_su_trace
    matrix colnames `TR' = gamma aic k1 k2 N1 N2
    ereturn matrix trace = `TR'
    matrix `DT' = __tk_su_dtrace
    matrix colnames `DT' = delay aic aic_n gamma k1 k2
    ereturn matrix dtrace = `DT'

    _tk_drop __tk_su_b __tk_su_V __tk_su_trace __tk_su_dtrace
    _tk_drop __tk_su_n __tk_su_off __tk_su_gamma __tk_su_d __tk_su_k1
    _tk_drop __tk_su_k2 __tk_su_aic __tk_su_aicn __tk_su_n1 __tk_su_n2
    _tk_drop __tk_su_ssr1 __tk_su_ssr2 __tk_su_s1 __tk_su_s2 __tk_su_ngrid

    Display , level(`level') `detail'
end

* ======================================================================
program define Display
    syntax [, Level(cilevel) DETail ]
    if "`level'" == "" local level = e(level)

    local k1 = e(k1)
    local k2 = e(k2)
    local d  = e(delay)

    display ""
    display as text "Subset SETAR(2; " as result `k1' as text ", " ///
        as result `k2' as text ")" _col(49) "Number of obs" _col(66) "=" ///
        _col(69) as result %10.0fc e(N)
    display as text "Threshold variable: " as result "`e(threshold_var)'" ///
        _col(49) as text "AIC (Tong-Lim)" _col(66) "=" ///
        _col(69) as result %10.3f e(aic)
    display as text "Delay: " as result `d' _col(49) ///
        as text "AIC / n" _col(66) "=" _col(69) as result %10.5f e(aic_n)
    display as text "Std. err.: " as result ///
        cond("`e(vcetype)'"=="Robust", "Robust", "OLS, per regime") ///
        _col(49) as text "Total SSR" _col(66) "=" ///
        _col(69) as result %10.4f e(ssr)
    display ""
    display as text "{hline 78}"
    display as text "  Threshold" _col(26) as result %14.6g e(gamma)
    display as text "  Observations: lower regime" _col(26) ///
        as result %14.0fc e(N_regime1) as text "   order " ///
        as result `k1'
    display as text "                upper regime" _col(26) ///
        as result %14.0fc e(N_regime2) as text "   order " ///
        as result `k2'
    display as text "  Innovation variance: lower" _col(26) ///
        as result %14.6g e(sigma2_1)
    display as text "                       upper" _col(26) ///
        as result %14.6g e(sigma2_2)
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "The orders were chosen by the Tong-Lim (1980, eq. 8.3)"
    display as text "minimum-AIC rule, each regime on {bf:its own} count of"
    display as text "observations, and the threshold by the summed criterion"
    display as text "(eq. 8.4). Every candidate was scored on the same " ///
        as result e(reserved) as text " reserved"
    display as text "leading rows, so the criteria are comparable across" ///
        " delays by"
    display as text "construction rather than by the eq. (8.6) normalisation."
    display as text ""
    display as text "The standard errors are {bf:conditional on the threshold}."
    display as text "Chan (1993) shows the threshold converges at rate n"
    display as text "against root-n for the coefficients, which is what makes"
    display as text "that conditioning legitimate to first order. It is not a"
    display as text "licence to quote an interval for the threshold, and none"
    display as text "is offered here: use {helpb thtar} for that."
    if e(k1) == e(k2) {
        display as text ""
        display as text "The two orders came out {bf:equal} (`=e(k1)'), so"
        display as text "{helpb thtar} with {bf:ar(1/`=e(k1)')} fits the same"
        display as text "model and gives the threshold an interval as well."
    }

    if "`detail'" != "" {
        tempname TR DT
        matrix `TR' = e(trace)
        matrix `DT' = e(dtrace)
        display ""
        display as text "{hline 78}"
        display as text "  Delay search (eq. 8.6 normalisation shown)"
        display as text "    delay" _col(14) "AIC" _col(28) "AIC/n" ///
            _col(42) "threshold" _col(58) "k1" _col(64) "k2"
        display as text "{hline 78}"
        forvalues r = 1/`=rowsof(`DT')' {
            display as text "    " as result %5.0f `DT'[`r',1] ///
                _col(10) %12.3f `DT'[`r',2] _col(24) %12.5f `DT'[`r',3] ///
                _col(38) %12.6g `DT'[`r',4] _col(54) %5.0f `DT'[`r',5] ///
                _col(60) %5.0f `DT'[`r',6]
        }
        display as text "{hline 78}"
        display as text "  Threshold search at the selected delay" ///
            " (" as result rowsof(`TR') as text " candidates)"
        display as text "    threshold" _col(20) "AIC" _col(34) "k1" ///
            _col(40) "k2" _col(48) "N1" _col(56) "N2"
        display as text "{hline 78}"
        forvalues r = 1/`=rowsof(`TR')' {
            display as text "    " as result %12.6g `TR'[`r',1] ///
                _col(16) %12.3f `TR'[`r',2] _col(30) %5.0f `TR'[`r',3] ///
                _col(36) %5.0f `TR'[`r',4] _col(44) %7.0f `TR'[`r',5] ///
                _col(52) %7.0f `TR'[`r',6]
        }
        display as text "{hline 78}"
        display as text "  A FLAT criterion across candidates means the rule"
        display as text "  did not actually decide anything, which is worth"
        display as text "  knowing before building on the choice."
    }
end
