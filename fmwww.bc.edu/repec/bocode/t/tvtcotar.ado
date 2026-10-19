*! tvtcotar 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Conditional threshold autoregression: the threshold is a rolling
*! empirical quantile of the threshold variable's own recent past.
*!
*! Motegi, K., J. W. Dennis and S. Hamori (2024) "Conditional Threshold
*!   Autoregression (CoTAR)", SSRN Working Paper No. 3960058,
*!   doi:10.2139/ssrn.3960058   (Crossref 2026-10-13: posted-content, an
*!   SSRN preprint -- not a journal article.)
*!
*! Clean-room. The authors' MATLAB carries no licence and was not copied;
*! it was run to produce a numerical reference lock, which this
*! implementation reproduces to 1e-13 on every statistic. See
*! validation/tvthresh/tvtcotar_equation_map.md.

program define tvtcotar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtcotar" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varname(numeric ts) [if] [in] ,          ///
        MEMory(integer)                             ///
        [ THReshvar(varname numeric ts)             ///
          LAGs(integer 1)                           ///
          Delays(numlist integer >0 sort)           ///
          TRIM(real 0.15)                           ///
          REPS(integer 0)                           ///
          noROBust                                  ///
          Level(cilevel) ]

    * ------------------------------------------------------------ checks
    if `memory' < 2 {
        display as error "{bf:memory()} must be at least 2"
        display as error ""
        display as error "{bf:memory()} is the length of the rolling" ///
            " window whose quantile is"
        display as error "the threshold. At m = 1 the model degenerates:" ///
            " c is forced to 1,"
        display as error "the threshold becomes the previous observation," ///
            " and the model"
        display as error "collapses to an ordinary threshold model in the" ///
            " DIFFERENCED"
        display as error "threshold variable with a known threshold of" ///
            " zero. That is a"
        display as error "different model, so it is refused rather than" ///
            " fitted here."
        exit 198
    }
    if `lags' < 1 {
        display as error "{bf:lags()} must be at least 1"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    if "`delays'" == "" local delays 1 2 3
    local maxd 0
    foreach dd of local delays {
        if `dd' > `maxd' local maxd `dd'
    }

    * ----------------------------------------------------------- sample
    local depv "`varlist'"
    if "`threshvar'" == "" {
        * the self-exciting case, SE-CoTAR: the series thresholds itself
        local threshvar "`depv'"
        local selfex 1
    }
    marksample touse
    markout `touse' `depv' `threshvar'
    quietly count if `touse'
    local nobs = r(N)

    * The rolling window and the lags are taken by position, so a hole in
    * the calendar would put observations that are not adjacent into the
    * same window.
    capture quietly tsset
    if _rc == 0 {
        local tvar "`r(timevar)'"
        if "`tvar'" != "" {
            quietly summarize `tvar' if `touse', meanonly
            local span = r(max) - r(min) + 1
            if `span' != `nobs' {
                display as error "`tvar' has gaps inside the sample" ///
                    " (span `span', `nobs' observations)"
                display as error "the threshold is a quantile of a" ///
                    " ROLLING WINDOW of the recent"
                display as error "past, so the observations must be" ///
                    " equally spaced. Restrict to"
                display as error "an unbroken span."
                exit 459
            }
        }
    }

    local hetero = cond("`robust'"=="", 1, 0)

    * ---- locals the engine reads
    local qvar   "`threshvar'"
    local plags  `lags'
    local dlist  "`delays'"
    _tvt_drop

    if `reps' > 0 {
        display as text "running `reps' multiplier bootstrap" ///
            " replications"
    }

    mata: tvt_cotar()

    tempname DD CC MM NO SSR SIG SH1 NF NFEAS NG
    scalar `DD'    = __tvt_ct_d
    scalar `CC'    = __tvt_ct_c
    scalar `MM'    = __tvt_ct_m
    scalar `NO'    = __tvt_ct_nobs
    scalar `SSR'   = __tvt_ct_ssr
    scalar `SIG'   = __tvt_ct_sig
    scalar `SH1'   = __tvt_ct_sh1
    scalar `NF'    = __tvt_ct_nfull
    scalar `NFEAS' = __tvt_ct_nfeas
    scalar `NG'    = __tvt_ct_ngrid
    tempname SW AW EW SL AL EL
    scalar `SW' = __tvt_ct_supW
    scalar `AW' = __tvt_ct_aveW
    scalar `EW' = __tvt_ct_expW
    scalar `SL' = __tvt_ct_supL
    scalar `AL' = __tvt_ct_aveL
    scalar `EL' = __tvt_ct_expL
    tempname BM VM GR PVM
    matrix `BM'  = __tvt_ct_b
    matrix `VM'  = __tvt_ct_V
    matrix `GR'  = __tvt_ct_grid
    matrix `PVM' = __tvt_ct_pv
    _tvt_drop

    * ---- coefficient names: regime 1 is x below the rolling quantile
    local nm
    local lo
    forvalues j = 1/`lags' {
        local lo `lo' L`j'.`depv'
    }
    foreach rg in below above {
        local nm `nm' `rg':_cons
        forvalues j = 1/`lags' {
            local nm `nm' `rg':L`j'
        }
    }
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    ereturn post `BM' `VM', esample(`touse') depname(`depv') ///
        obs(`nobs')
    ereturn scalar N         = `NF'
    ereturn scalar N_eff     = `NO'
    ereturn scalar d         = `DD'
    ereturn scalar c         = `CC'
    ereturn scalar memory    = `MM'
    ereturn scalar lags      = `lags'
    ereturn scalar ssr       = `SSR'
    ereturn scalar sigma2    = `SIG'
    ereturn scalar share_lo  = `SH1'
    ereturn scalar n_feasible = `NFEAS'
    ereturn scalar n_grid    = `NG'
    ereturn scalar trim      = `trim'
    ereturn scalar reps      = `reps'
    ereturn scalar robust    = `hetero'
    ereturn scalar supW      = `SW'
    ereturn scalar aveW      = `AW'
    ereturn scalar expW      = `EW'
    ereturn scalar supLM     = `SL'
    ereturn scalar aveLM     = `AL'
    ereturn scalar expLM     = `EL'
    if `reps' > 0 {
        ereturn scalar p_supW  = `PVM'[1,1]
        ereturn scalar p_aveW  = `PVM'[1,2]
        ereturn scalar p_expW  = `PVM'[1,3]
        ereturn scalar p_supLM = `PVM'[1,4]
        ereturn scalar p_aveLM = `PVM'[1,5]
        ereturn scalar p_expLM = `PVM'[1,6]
    }
    ereturn local  cmd       "tvtcotar"
    ereturn local  cmdline   "tvtcotar `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  delays    "`delays'"
    ereturn local  selfex    "`selfex'"
    ereturn local  title     "Conditional threshold autoregression (CoTAR)"
    ereturn matrix grid = `GR'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Motegi, Dennis and Hamori (2024)" ///
        _col(52) as text "Used in fit" _col(68) "=" ///
        _col(71) as result %9.0fc e(N_eff)
    if "`e(selfex)'" != "" {
        display as text "Self-exciting: the series thresholds itself" ///
            _col(52) as text "Feasible (d,c)" _col(68) "=" ///
            _col(71) as result %9.0f e(n_feasible)
    }
    else {
        display as text "Threshold variable: " as result "`e(threshvar)'" ///
            _col(52) as text "Feasible (d,c)" _col(68) "=" ///
            _col(71) as result %9.0f e(n_feasible)
    }
    display ""
    display as text "{hline 78}"
    display as text "  The threshold is a rolling quantile of" ///
        " `e(threshvar)':"
    display as text "    mu(t) = the " as result e(c)*e(memory) ///
        as text "-th smallest of its last " as result e(memory) ///
        as text " values"
    display as text "{hline 78}"
    display as text "    delay d" _col(28) as result %12.0f e(d)
    display as text "    percentile c" _col(28) as result %12.4f e(c)
    display as text "    memory m" _col(28) as result %12.0f e(memory)
    display as text "    share below mu" _col(28) as result %12.4f ///
        e(share_lo)
    display as text "    sigma^2" _col(28) as result %12.6f e(sigma2)
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  No-threshold-effect test:  H0: the two regimes" ///
        " share one AR(p)"
    display as text "{hline 78}"
    display as text "                    sup          ave          exp"
    display as text "    Wald    " as result %12.4f e(supW) %13.4f ///
        e(aveW) %13.4f e(expW)
    if e(reps) > 0 {
        display as text "    p-value " as result %12.4f e(p_supW) ///
            %13.4f e(p_aveW) %13.4f e(p_expW)
    }
    display as text "    LM      " as result %12.4f e(supLM) %13.4f ///
        e(aveLM) %13.4f e(expLM)
    if e(reps) > 0 {
        display as text "    p-value " as result %12.4f e(p_supLM) ///
            %13.4f e(p_aveLM) %13.4f e(p_expLM)
    }
    display as text "{hline 78}"
    if e(reps) == 0 {
        display as text "  The threshold parameters (d,c) are" ///
            " UNIDENTIFIED under this null, so"
        display as text "  these statistics have non-standard" ///
            " distributions and cannot be"
        display as text "  compared with a chi-squared table. Specify" ///
            " {bf:reps()} for wild"
        display as text "  multiplier bootstrap p-values."
    }
    else {
        display as text "  p-values: wild multiplier bootstrap," ///
            " N(0,1) multipliers shared"
        display as text "  across the grid. Nothing is re-estimated --" ///
            " see {helpb tvtcotar}."
        display as text ""
        display as text "  {bf:Prefer the LM row.} In the paper's own" ///
            " Table 1 the Wald"
        display as text "  functionals over-reject badly in short" ///
            " samples (sup-Wald 0.197"
        display as text "  at n = 125 against a nominal 0.05) while the" ///
            " LM versions are"
        display as text "  close to nominal (0.045)."
    }
    display as text "{hline 78}"
    display as text "  No confidence interval is reported for d or c:" ///
        " the paper does not"
    display as text "  derive the asymptotic distribution of the" ///
        " threshold parameters."
end
