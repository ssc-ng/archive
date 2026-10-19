*! tvtmathar 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Moving average threshold heterogeneous autoregression (MAT-HAR).
*!
*! Motegi, K., X. Cai, S. Hamori and H. Xu (2020) Journal of Forecasting
*!   39(7):1035-1042, doi:10.1002/for.2671  (DOI verified via Crossref
*!   2026-10-13. The PDF on disk is the longer SSRN working paper,
*!   doi:10.2139/ssrn.3426182; its tables may differ from the published
*!   ones.)
*!
*! Clean-room. Validated against the authors' own MATLAB to machine
*! precision. See validation/tvthresh/tvtmathar_equation_map.md.

program define tvtmathar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtmathar" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varname(numeric ts) [if] [in] ,          ///
        [ FREQ(numlist integer >0 sort)             ///
          LAGSmu(integer 0)                         ///
          CRITerion(string)                         ///
          MODel(integer 0)                          ///
          noROBust                                  ///
          Level(cilevel) ]

    if "`freq'" == "" local freq 1 5 20
    local K : word count `freq'
    if `K' < 2 {
        display as error "{bf:freq()} needs at least two frequencies"
        display as error "it lists the averaging horizons, e.g." ///
            " {bf:freq(1 5 20)} for daily data"
        display as error "(day, week, month) or {bf:freq(1 3 12)} for" ///
            " monthly (month,"
        display as error "quarter, year). The first should normally be 1."
        exit 198
    }
    if `K' > 6 {
        display as error "{bf:freq()} is limited to six frequencies"
        display as error "the model space is 2^K and the command fits" ///
            " every one of them"
        exit 198
    }
    local mmax 0
    foreach f of local freq {
        if `f' > `mmax' local mmax `f'
    }
    if "`criterion'" == "" local criterion aic
    local criterion = lower("`criterion'")
    if "`criterion'" != "aic" & "`criterion'" != "bic" {
        display as error "{bf:criterion()} must be {bf:aic} or {bf:bic}"
        exit 198
    }
    local crit = cond("`criterion'"=="aic", 1, 2)
    local nmod = 2^`K'
    if `model' < 0 | `model' > `nmod' {
        display as error "{bf:model()} must be between 1 and `nmod'" ///
            " for `K' frequencies"
        exit 198
    }

    * ----------------------------------------------------------- sample
    marksample touse
    markout `touse' `varlist'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < `mmax' + 3*(2*`K'+1) {
        display as error "too few observations (`nobs') for freq()" ///
            " up to `mmax'"
        exit 2001
    }

    * The averages and the thresholds are rolling windows taken by
    * position, so the series must be contiguous.
    capture quietly tsset
    if _rc == 0 {
        local tvar "`r(timevar)'"
        if "`tvar'" != "" {
            quietly summarize `tvar' if `touse', meanonly
            local span = r(max) - r(min) + 1
            if `span' != `nobs' {
                display as error "`tvar' has gaps inside the sample" ///
                    " (span `span', `nobs' observations)"
                display as error "the frequency averages and the" ///
                    " thresholds are rolling windows"
                display as error "taken by position, so the series must" ///
                    " be equally spaced."
                exit 459
            }
        }
    }

    if `lagsmu' == 0 {
        * the paper's rule of thumb, l_n = delta*sqrt(n) with delta = 1
        local lagsmu = floor(sqrt(`nobs'))
        local lnauto 1
    }
    if `lagsmu' < 2 {
        display as error "{bf:lagsmu()} must be at least 2"
        exit 198
    }

    local hetero = cond("`robust'"=="", 1, 0)

    local yvar   "`varlist'"
    local mlist  "`freq'"
    local lnmu   `lagsmu'
    local robflag `hetero'
    local critnum `crit'
    local forcemod `model'
    _tvt_drop

    mata: tvt_mathar()

    tempname SEL NOBS LN
    scalar `SEL'  = __tvt_mh_sel
    scalar `NOBS' = __tvt_mh_nobs
    scalar `LN'   = __tvt_mh_ln
    tempname BM VM OUTM
    matrix `BM'   = __tvt_mh_b
    matrix `VM'   = __tvt_mh_V
    matrix `OUTM' = __tvt_mh_out
    tempname MASKSV
    matrix `MASKSV' = __tvt_mh_mask
    tempname SSR AIC BIC WALD PW NPSI
    scalar `SSR'  = __tvt_mh_ssr
    scalar `AIC'  = __tvt_mh_aic
    scalar `BIC'  = __tvt_mh_bic
    scalar `WALD' = __tvt_mh_wald
    scalar `PW'   = __tvt_mh_pw
    scalar `NPSI' = __tvt_mh_npsi
    _tvt_drop

    * ---- coefficient names, built from the selected model's own mask so
    * that the threshold terms are named for the frequencies that actually
    * carry one. The engine returns the mask rather than the ado guessing
    * it from the coefficient count.
    local nm _cons
    foreach f of local freq {
        local nm `nm' avg`f'
    }
    local j 0
    foreach f of local freq {
        local ++j
        if `MASKSV'[1,`j'] == 1 local nm `nm' thr`f'
    }
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    ereturn post `BM' `VM', esample(`touse') depname(`varlist') ///
        obs(`nobs')
    ereturn scalar N        = `nobs'
    ereturn scalar N_eff    = `NOBS'
    ereturn scalar model    = `SEL'
    ereturn scalar n_models = `nmod'
    ereturn scalar K        = `K'
    ereturn scalar lagsmu   = `LN'
    ereturn scalar ssr      = `SSR'
    ereturn scalar aic      = `AIC'
    ereturn scalar bic      = `BIC'
    ereturn scalar n_thresh = `NPSI'
    ereturn scalar wald     = `WALD'
    ereturn scalar p_wald   = `PW'
    ereturn scalar robust   = `hetero'
    ereturn local  cmd      "tvtmathar"
    ereturn local  cmdline  "tvtmathar `0'"
    ereturn local  depvar   "`varlist'"
    ereturn local  freq     "`freq'"
    ereturn local  criterion "`criterion'"
    ereturn local  title    "Moving average threshold HAR (MAT-HAR)"
    ereturn matrix models = `OUTM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Motegi, Cai, Hamori and Xu (2020)" ///
        _col(52) as text "Used in fit" _col(68) "=" ///
        _col(71) as result %9.0fc e(N_eff)
    display as text "Frequencies: " as result "`e(freq)'" ///
        _col(52) as text "Threshold lags" _col(68) "=" ///
        _col(71) as result %9.0f e(lagsmu)
    display ""
    display as text "{hline 78}"
    display as text "  Model " as result e(model) as text " of " ///
        as result e(n_models) as text " selected by " ///
        as result upper("`e(criterion)'") as text ///
        ", with " as result e(n_thresh) as text " threshold term" ///
        cond(e(n_thresh)==1,"","s")
    display as text "    AIC " as result %12.6f e(aic) ///
        as text "    BIC " as result %12.6f e(bic) ///
        as text "    SSR " as result %12.4f e(ssr)
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    if e(n_thresh) > 0 {
        display as text "  No-threshold-effect test:  H0: every" ///
            " threshold coefficient is 0"
        display as text "    Wald = " as result %10.4f e(wald) ///
            as text "   chi2(" as result e(n_thresh) as text ") " ///
            "   p = " as result %6.4f e(p_wald)
        display as text ""
        display as text "  The threshold here is {bf:observed} -- a" ///
            " moving average of the data --"
        display as text "  so nothing is unidentified under this null" ///
            " and the test is an"
        display as text "  ordinary Wald test. No bootstrap is needed."
        display as text "  {bf:But} the paper states it does not derive" ///
            " the asymptotic theory"
        display as text "  for these estimators, so the chi-squared" ///
            " limit is asserted, not"
        display as text "  proved. Treat a borderline p-value with care."
    }
    else {
        display as text "  The selected model has NO threshold terms:" ///
            " plain HAR was preferred."
        display as text "  There is nothing to test."
    }
    display as text "{hline 78}"
    display as text "  {cmd:e(models)} holds every model's SSR, AIC," ///
        " BIC and Wald test."
end
