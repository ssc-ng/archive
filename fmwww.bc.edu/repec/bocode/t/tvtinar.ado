*! tvtinar 1.0.0  14oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! EQTINAR(1): an integer-valued autoregression for COUNTS whose
*! threshold is the empirical quantile of a sliding window of recent
*! observations.
*!
*! This is the only command in TVTHRESH for count data. The rest of the
*! library is Gaussian, and a Gaussian threshold model fitted to counts
*! is the wrong family however the threshold behaves -- which is why
*! tvtsel sends integer-valued dependent variables here.
*!
*! Jia, Y., F. Zhu, T. Wang and Q. Li (2026) Communications in Nonlinear
*!   Science and Numerical Simulation 163: 110445,
*!   doi:10.1016/j.cnsns.2026.110445
*!
*! Clean-room; no code ships with the paper. Validated against its own
*! Table 1. See validation/tvthresh/tvtinar_equation_map.md.

program define tvtinar, eclass sortpreserve
    version 15

    syntax varlist(numeric ts min=1 max=1) [if] [in] ,   ///
        [ MEMory(integer 6)                              ///
          PCT(string)                                    ///
          METHod(string)                                 ///
          INNOVation(string)                             ///
          MINReg(real 0.15)                              ///
          Level(cilevel) ]

    local depv `varlist'

    * ------------------------------------------------------------- checks
    capture quietly tsset
    if _rc {
        display as error "the data must be {bf:tsset}"
        display as error ""
        display as error "The threshold is a quantile of the series' own" ///
            " recent past, so the order"
        display as error "of the observations is the model."
        exit 459
    }
    local tvar "`r(timevar)'"

    if "`method'" == "" local method cls
    local method = lower("`method'")
    if !inlist("`method'", "cls", "cml") {
        display as error "{bf:method()} must be {bf:cls} or {bf:cml}"
        exit 198
    }
    if "`innovation'" == "" local innovation poisson
    local innovation = lower("`innovation'")
    if !inlist("`innovation'", "poisson", "geometric") {
        display as error "{bf:innovation()} must be {bf:poisson} or" ///
            " {bf:geometric}"
        exit 198
    }
    if `memory' < 2 {
        display as error "{bf:memory()} must be at least 2"
        exit 198
    }
    if `minreg' <= 0 | `minreg' >= 0.5 {
        display as error "{bf:minreg()} must be in (0, 0.5)"
        exit 198
    }
    if "`pct'" != "" {
        capture confirm number `pct'
        if _rc {
            display as error "{bf:pct()} must be a number in (0, 1]"
            exit 198
        }
        if `pct' <= 0 | `pct' > 1 {
            display as error "{bf:pct()} must be in (0, 1]"
            exit 198
        }
    }

    marksample touse
    markout `touse' `depv'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < `=`memory' + 12' {
        display as error "too few observations (`nobs') for" ///
            " {bf:memory(`memory')}"
        display as error "the first `=`memory'+1' are spent building the" ///
            " first local memory"
        exit 2001
    }

    * the sample must be one unbroken stretch: the memory is the previous
    * m observations IN TIME, and a gap silently changes which they are
    tempvar seq
    quietly generate long `seq' = `tvar' if `touse'
    quietly summarize `seq', meanonly
    if (r(max) - r(min) + 1) != `nobs' {
        display as error "the estimation sample has gaps in `tvar'"
        display as error ""
        display as error "The local memory is the previous" ///
            " {bf:memory()} observations in TIME."
        display as error "Across a gap those are not the ones the model" ///
            " means. Restrict to an"
        display as error "unbroken stretch with {bf:if}."
        exit 198
    }

    capture matrix drop __tvt_in_b
    capture matrix drop __tvt_in_V
    capture matrix drop __tvt_in_thr
    capture scalar drop __tvt_in_fail
    mata: tvt_inar()

    if __tvt_in_fail != 0 {
        local fc = __tvt_in_fail
        capture scalar drop __tvt_in_fail
        if `fc' == 2 {
            display as error "`depv' is not a count"
            display as error ""
            display as error "{bf:tvtinar} is built on BINOMIAL" ///
                " THINNING, which is only defined for"
            display as error "non-negative integers. For continuous data" ///
                " use {helpb tvtcotar}, which"
            display as error "is the same rolling-quantile threshold" ///
                " without the count structure."
            exit 459
        }
        if `fc' == 3 {
            display as error "too few usable observations after building" ///
                " the local memory"
            exit 2001
        }
        if `fc' == 4 {
            display as error "no admissible percentile left both regimes" ///
                " above {bf:minreg(`minreg')}"
            display as error ""
            display as error "Either the series does not split, or" ///
                " {bf:memory(`memory')} is too small"
            display as error "to offer a usable candidate. Try a larger" ///
                " {bf:memory()}, a smaller"
            display as error "{bf:minreg()}, or name a {bf:pct()}" ///
                " directly."
            exit 498
        }
        if `fc' == 5 {
            display as error "the likelihood did not converge"
            display as error "Try {bf:method(cls)}, which is closed form."
            exit 430
        }
        display as error "estimation failed"
        exit 498
    }

    tempname b V THR bb VV
    matrix `b'   = __tvt_in_b
    matrix `V'   = __tvt_in_V
    matrix `THR' = __tvt_in_thr
    local N     = __tvt_in_N
    local s2    = __tvt_in_s2
    local vs2   = __tvt_in_vs2
    local ll    = __tvt_in_ll
    local kk    = __tvt_in_k
    local cc    = __tvt_in_c
    local ncand = __tvt_in_ncand
    local sh1   = __tvt_in_sh1
    capture scalar drop __tvt_in_fail
    capture matrix drop __tvt_in_b
    capture matrix drop __tvt_in_V
    capture matrix drop __tvt_in_thr

    * ---- the variance parameter joins the table as a fourth entry
    matrix `bb' = `b', (`s2')
    matrix `VV' = J(4, 4, 0)
    forvalues i = 1/3 {
        forvalues j = 1/3 {
            matrix `VV'[`i',`j'] = `V'[`i',`j']
        }
    }
    matrix `VV'[4,4] = `vs2'
    local nm "alpha1 alpha2 lambda sigma2_z"
    matrix colnames `bb' = `nm'
    matrix colnames `VV' = `nm'
    matrix rownames `VV' = `nm'

    * CLS is a closed-form least squares solve, so NOTHING holds the
    * thinning parameters inside (0,1) -- and at small n that bites. In
    * this library's own replication of the paper's Scenario A, 20.7% of
    * alpha1 estimates left (0,1) at n = 50, against 0.2% for alpha2.
    * An estimate outside (0,1) is not a probability and cannot be read
    * as one, so it is called out rather than printed as though it were.
    *
    * COMPUTED HERE, BEFORE THE POST: -ereturn post- CONSUMES the
    * matrices handed to it, so reading `bb' afterwards is
    * "__00000x not found".
    local inrange = 1
    if `bb'[1,1] <= 0 | `bb'[1,1] >= 1 local inrange = 0
    if `bb'[1,2] <= 0 | `bb'[1,2] >= 1 local inrange = 0

    * ------------------------------------------------------------ output
    local mname = cond("`method'"=="cls", ///
        "conditional least squares", ///
        "conditional maximum likelihood, `innovation' innovations")

    display ""
    display as text "EQTINAR(1): count threshold model, EMPIRICAL" ///
        " QUANTILE threshold"
    display as text "Jia, Zhu, Wang and Li (2026), CNSNS 163:110445" ///
        _col(56) "Obs used" _col(68) "=" _col(71) as result %9.0fc `N'
    display as text "{hline 78}"
    display as text "  estimator: " as result "`mname'"
    display as text "  threshold: the " as result %5.3f `cc' as text ///
        " quantile of the previous " as result `memory' as text ///
        " counts"
    display as text "             (the " as result `kk' as text ///
        "-th smallest of {bf:X(t-`=`memory'+1')} to {bf:X(t-2)})"
    display as text "{hline 78}"

    ereturn post `bb' `VV', depname("`depv'") obs(`N') esample(`touse')
    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  lower regime (X(t-1) at or below the threshold)" ///
        _col(56) as result %8.3f `sh1' as text " of the sample"
    if "`pct'" == "" {
        display as text "  the percentile was CHOSEN by minimum SSR" ///
            " from " as result `ncand' as text " candidates"
        display as text "  that left both regimes above " as result ///
            %4.2f `minreg' as text ". {bf:The standard errors above"
        display as text "  condition on that choice} and do not account" ///
            " for the search."
    }
    else {
        display as text "  the percentile was SET by {bf:pct(`pct')}," ///
            " not searched"
    }
    if "`method'" == "cml" {
        display as text "  log likelihood" _col(56) as result %12.4f `ll'
        if "`innovation'" == "poisson" {
            display as text "  {bf:sigma2_z = lambda} under Poisson" ///
                " innovations: one free parameter,"
            display as text "  not two, so the two rows carry the same" ///
                " information."
        }
        else {
            display as text "  {bf:sigma2_z = lambda(1+lambda)} under" ///
                " geometric innovations, so the"
            display as text "  variance is not free either."
        }
    }
    display as text "{hline 78}"
    display as text "  {bf:alpha1} and {bf:alpha2} are thinning" ///
        " probabilities: the chance that any one"
    display as text "  of the previous period's counts survives into" ///
        " this one. They are not"
    display as text "  regression slopes and they must lie in (0,1)."
    display as text "{hline 78}"

    if !`inrange' {
        display as error "  WARNING: a thinning parameter is outside" ///
            " (0,1), so it is NOT a"
        display as error "  probability and must not be reported as one."
        if "`method'" == "cls" {
            display as error ""
            display as error "  {bf:cls} is a closed-form least squares" ///
                " solve and nothing constrains"
            display as error "  it to the parameter space. Use" ///
                " {bf:method(cml)}, which is bounded by"
            display as error "  construction, or fit a longer series."
        }
        display as text "{hline 78}"
    }

    * ----------------------------------------------------------- returns
    ereturn matrix path     = `THR'
    ereturn scalar inrange  = `inrange'
    ereturn scalar N        = `N'
    ereturn scalar memory   = `memory'
    ereturn scalar pct      = `cc'
    ereturn scalar k_order  = `kk'
    ereturn scalar sigma2_z = `s2'
    ereturn scalar share1   = `sh1'
    ereturn scalar n_cand   = `ncand'
    ereturn scalar minreg   = `minreg'
    ereturn scalar level    = `level'
    if "`method'" == "cml" ereturn scalar ll = `ll'
    ereturn local  searched = cond("`pct'"=="", "yes", "no")
    ereturn local  innovation "`innovation'"
    ereturn local  method   "`method'"
    ereturn local  timevar  "`tvar'"
    ereturn local  threshvar "L.`depv'"
    ereturn local  title    "EQTINAR(1) count threshold model"
    ereturn local  cmd      "tvtinar"
end
