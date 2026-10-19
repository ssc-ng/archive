*! tvtlr 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Test whether an AR model became a THRESHOLD AR model at an unknown date.
*!
*! Berkes, I., L. Horvath, S. Ling and J. Schauer (2011) Journal of Time
*!   Series Analysis 32(5):547-565, doi:10.1111/j.1467-9892.2010.00714.x
*!   (DOI verified via Crossref 2026-10-13)
*!
*! See tvtlr.sthlp and validation/tvthresh/tvtlr_equation_map.md.

program define tvtlr, rclass sortpreserve
    version 15

    syntax varname(numeric ts) [if] [in] ,          ///
        [ METHod(string)                            ///
          GRIDn(integer 0)                          ///
          DEMean                                    ///
          LAGs(integer 1)                           ///
          DELay(integer 1)                          ///
          TRIM(real 0.10)                           ///
          SIMreps(integer 1000)                     ///
          GRIDm(integer 300)                        ///
          SEED(string)                              ///
          Level(cilevel) ]

    if "`method'" == "" local method berkes
    local method = lower("`method'")

    if "`method'" == "zhuling" {
        Zhuling `varlist' `if' `in', lags(`lags') delay(`delay') ///
            trim(`trim') simreps(`simreps') gridm(`gridm') ///
            level(`level') seed(`seed')
        * the subprogram's r() is local to it; without return add the
        * caller exits with an empty return list and every r(stat),
        * r(reject) and r(p) comes back missing to the user
        return add
        exit
    }
    if "`method'" != "berkes" {
        display as error "{bf:method()} must be {bf:berkes}"
        exit 198
    }
    if `gridn' < 0 {
        display as error "{bf:gridn()} cannot be negative"
        exit 198
    }

    * ----------------------------------------------------------- sample
    marksample touse
    markout `touse' `varlist'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        display as error "too few observations (`nobs'); this test needs" ///
            " at least 30"
        exit 2001
    }

    * The series must be contiguous: the statistic maximises over a break
    * DATE, so a hole in the calendar would make "before" and "after" mean
    * different spans either side of it.
    capture quietly tsset
    if _rc == 0 {
        local tvar "`r(timevar)'"
        if "`tvar'" != "" {
            quietly summarize `tvar' if `touse', meanonly
            local span = r(max) - r(min) + 1
            if `span' != `nobs' {
                display as error "`tvar' has gaps inside the sample" ///
                    " (span `span', `nobs' observations)"
                display as error "this test maximises over a break date," ///
                    " so the series must be"
                display as error "contiguous. Restrict to an unbroken span."
                exit 459
            }
        }
    }

    * ---- the model has NO INTERCEPT. That is the paper's model, and the
    * tabulated critical values belong to it. Rather than silently fit
    * something else, demeaning is an explicit choice the user makes.
    tempvar yv
    quietly generate double `yv' = `varlist' if `touse'
    if "`demean'" != "" {
        quietly summarize `yv' if `touse', meanonly
        quietly replace `yv' = `yv' - r(mean) if `touse'
        local demeaned 1
    }
    else {
        quietly summarize `yv' if `touse', meanonly
        local ybar = r(mean)
        quietly summarize `yv' if `touse'
        local ysd = r(sd)
        * THE TWO THRESHOLDS HERE WERE SET BY MEASUREMENT, NOT BY TASTE.
        *
        * The model has no intercept, so a series with a substantial mean is
        * misspecified: the mean is attributed to the AR coefficient, which
        * is pushed toward 1. The question is where to draw the line.
        *
        * A first version refused at |mean|/sd > 0.25 and was WRONG. Under
        * the null the sample mean of a persistent AR(1) has standard error
        * sd*sqrt((1+rho)/((1-rho)n)), which at rho = 0.5, n = 200 is about
        * 0.12*sd -- so a 0.25 ratio is barely two standard errors and fires
        * on ordinary sampling noise. In the size study it refused 14 of 300
        * perfectly valid null replications, and because it refused exactly
        * the draws with the largest means it biased the measured size
        * downward.
        *
        * So: WARN where the mean is large enough to matter for
        * interpretation, REFUSE only where the series is plainly a level
        * series rather than a centred one. No null realisation of a
        * stationary mean-zero process reaches |mean| > 2*sd.
        if `ysd' > 0 {
            local mratio = abs(`ybar')/`ysd'
            if `mratio' > 2 {
                display as error "the series is dominated by its level" ///
                    " (mean " %9.4g `ybar' ", sd " %9.4g `ysd' ")."
                display as error ""
                display as error "This test's model has {bf:no intercept}" ///
                    " -- that is the model the"
                display as error "critical values belong to, not a" ///
                    " simplification. On a level"
                display as error "series the mean is attributed to the AR" ///
                    " coefficient, pushing it"
                display as error "toward 1, and the test is not testing" ///
                    " what it claims to."
                display as error ""
                display as error "Specify {bf:demean}, or difference the" ///
                    " series, or pass a series"
                display as error "that is already centred -- returns," ///
                    " growth rates, deviations."
                exit 459
            }
            if `mratio' > 0.5 local meanwarn `mratio'
        }
    }

    local yvar "`yv'"
    _tvt_drop

    mata: tvt_lr()

    tempname STAT KH RH ZN S2 RHO NG NN
    scalar `STAT' = __tvt_lr_stat
    scalar `KH'   = __tvt_lr_k
    scalar `RH'   = __tvt_lr_r
    scalar `ZN'   = __tvt_lr_Z
    scalar `S2'   = __tvt_lr_s2
    scalar `RHO'  = __tvt_lr_rho
    scalar `NG'   = __tvt_lr_ng
    scalar `NN'   = __tvt_lr_n
    _tvt_drop

    * ---- Table 1 of the paper. The limit is distribution-free, so these
    * are not bootstrapped and do not depend on the data, the sample size
    * or any tuning choice. The certification suite reproduces all three
    * by simulating the Brownian sheet rather than trusting them.
    local cv10 = 2.343
    local cv05 = 2.758
    local cv01 = 3.604

    local cvuse = `cv05'
    local lvl 95
    if `level' == 90 {
        local cvuse = `cv10'
        local lvl 90
    }
    if `level' == 99 {
        local cvuse = `cv01'
        local lvl 99
    }
    if `level' != 90 & `level' != 95 & `level' != 99 local interp 1
    local rej = cond(`STAT' > `cvuse', 1, 0)

    * a p-value bracket: only three quantiles exist, so an interpolated
    * p-value would be invented
    local pbr "> 0.10"
    if `STAT' > `cv10' local pbr "in (0.05, 0.10]"
    if `STAT' > `cv05' local pbr "in (0.01, 0.05]"
    if `STAT' > `cv01' local pbr "<= 0.01"

    * -------------------------------------------------------------- display
    display ""
    display as text "AR against threshold AR at an unknown date" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc `NN'
    display as text "Berkes, Horvath, Ling and Schauer (2011)" ///
        _col(52) as text "Candidates" _col(68) "=" ///
        _col(71) as result %9.0f `NG'
    display ""
    display as text "  H0: one AR(1) throughout," ///
        "  y(i) = rho*y(i-1) + e(i)"
    display as text "  H1: after an unknown date k*, a threshold term" ///
        " switches on"
    display as text "{hline 72}"
    display as text "  rho under H0" _col(34) as result %14.6f `RHO'
    display as text "  sigma^2 under H0" _col(34) as result %14.6f `S2'
    display as text "{hline 72}"
    display as text "  Rbar(n) statistic" _col(34) as result %14.4f `STAT'
    display as text "{hline 72}"
    display as text "  Critical values (Berkes et al. Table 1;" ///
        " distribution-free)"
    display as text "     10%" _col(14) as result %8.3f `cv10' ///
        as text _col(26) "5%" _col(32) as result %8.3f `cv05' ///
        as text _col(44) "1%" _col(50) as result %8.3f `cv01'
    display as text "  p-value " as result "`pbr'"
    display as text "{hline 72}"
    if `rej' {
        display as text "  " as result "REJECTED" as text " at the `lvl'%" ///
            " level: the AR(1) model does not hold"
        display as text "  throughout. A threshold term switches on at" ///
            " some point."
    }
    else {
        display as text "  Not rejected at the `lvl'% level: no evidence" ///
            " against a single"
        display as text "  AR(1) over the whole sample."
    }
    display as text "{hline 72}"
    display as text "  Maximum attained at k = " as result %6.0f `KH' ///
        as text " and r = " as result %9.5f `RH'
    display as text ""
    display as text "  {bf:Read k with care.} The paper locates its" ///
        " application's break"
    display as text "  dates this way, so it is reported here. But the" ///
        " maximised quantity"
    display as text "  is {bf:weighted}, and the weight rewards" ///
        " configurations in which many"
    display as text "  observations fall below r after k -- which favours" ///
        " SMALL k. On"
    display as text "  simulated series with a known break this argmax" ///
        " tracked the true"
    display as text "  date only loosely and was biased early (a break at" ///
        " 200 of 300 was"
    display as text "  located at 91). No consistency result for it is" ///
        " given. Treat it"
    display as text "  as where the evidence peaked, not as a dated" ///
        " estimate."
    if "`demeaned'" != "" {
        display as text ""
        display as text "  ({bf:demean} was applied: the mean was removed" ///
            " before testing.)"
    }
    if "`meanwarn'" != "" {
        display as text ""
        display as text "  {bf:Note.} The series mean is " ///
            as result %4.2f `meanwarn' as text " times its standard" ///
            " deviation."
        display as text "  This model has no intercept, so that mean is" ///
            " absorbed into rho."
        display as text "  Not large enough to refuse, but consider" ///
            " {bf:demean} and compare."
    }
    if "`interp'" != "" {
        display as text ""
        display as text "  ({bf:level(`level')} has no tabulated value." ///
            " Reported at 5%.)"
    }

    * --------------------------------------------------------- stored results
    return scalar stat    = `STAT'
    return scalar reject  = `rej'
    return scalar level   = `lvl'
    return scalar cv      = `cvuse'
    return scalar cv10    = `cv10'
    return scalar cv05    = `cv05'
    return scalar cv01    = `cv01'
    return scalar k       = `KH'
    return scalar r       = `RH'
    return scalar rho     = `RHO'
    return scalar sigma2  = `S2'
    return scalar Z       = `ZN'
    return scalar N       = `NN'
    return scalar n_cand  = `NG'
    return scalar demean  = cond("`demeaned'"!="", 1, 0)
    return local  pbracket "`pbr'"
    return local  method  "berkes"
    return local  varname "`varlist'"
    return local  cmd     "tvtlr"
end


* =====================================================================
* method(zhuling): Zhu and Ling (2012). A DIFFERENT STATISTIC from
* method(berkes), not a setting of it.
*
*   berkes   AR(1) null, NO intercept, delay fixed at 1, slope-only
*            shift, WEIGHTED and UNTRIMMED, three tabulated constants
*   zhuling  AR(p) null WITH an intercept, FREE delay d, intercept and
*            slopes both shift, UNWEIGHTED and TRIMMED, critical values
*            that depend on p and on how much you trim
*
* The trimming is not a convenience here. The paper, just below its
* Theorem 1: without cutting the range of k and r the maximum of
* LR_n(k,r) diverges in probability. Berkes et al. buy the untrimmed
* range with a weight; Zhu and Ling buy it by trimming.
* =====================================================================
program define Zhuling, rclass
    version 15

    syntax varname(numeric ts) [if] [in] ,          ///
        [ LAGs(integer 1)                           ///
          DELay(integer 1)                          ///
          TRIM(real 0.10)                           ///
          SIMreps(integer 1000)                     ///
          GRIDm(integer 300)                        ///
          SEED(string)                              ///
          Level(cilevel) ]

    if `lags' < 0 {
        display as error "{bf:lags()} cannot be negative"
        display as error "lags(0) is the pure intercept model, the p = 0" ///
            " case of the paper"
        exit 198
    }
    if `delay' < 1 {
        display as error "{bf:delay()} must be at least 1"
        exit 198
    }
    if `trim' <= 0 | `trim' > 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5]"
        display as error "This is the paper's pi0. It uses 0.10 or 0.15," ///
            " and says plainly that"
        display as error "how to choose it optimally remains unclear." ///
            " It cannot be 0: without"
        display as error "trimming the statistic diverges."
        exit 198
    }
    if `simreps' < 100 {
        display as error "{bf:simreps()} must be at least 100"
        exit 198
    }
    if `gridm' < 50 {
        display as error "{bf:gridm()} must be at least 50"
        exit 198
    }

    marksample touse
    markout `touse' `varlist'
    quietly count if `touse'
    local nobs = r(N)
    local l = max(`lags', `delay')
    if `nobs' < `l' + 20 {
        display as error "too few observations (`nobs') for lags(`lags')" ///
            " and delay(`delay')"
        exit 2001
    }

    local yvar "`varlist'"
    if "`seed'" != "" set seed `seed'
    _tvt_drop
    mata: tvt_zl()

    if __tvt_zl_fail == 1 {
        _tvt_drop
        display as error "the statistic could not be computed"
        display as error ""
        display as error "No admissible split produced a usable residual" ///
            " variance. Two causes,"
        display as error "in the order worth checking:"
        display as error "  1. {bf:`varlist' is not stationary.} The null" ///
            " here is a STABLE AR(p):"
        display as error "     the paper assumes every root of the" ///
            " characteristic equation lies"
        display as error "     inside the unit circle. An explosive or" ///
            " unit-root series makes the"
        display as error "     sums of squares meaningless rather than" ///
            " merely large. Check it"
        display as error "     with a unit-root test first."
        display as error "  2. too few observations on one side: lower" ///
            " {bf:lags()} or widen {bf:trim()}."
        exit 498
    }

    tempname STAT KH RH NV CV C90 C95 C99 PV NN
    scalar `STAT' = __tvt_zl_stat
    scalar `KH'   = __tvt_zl_k
    scalar `RH'   = __tvt_zl_r
    scalar `NV'   = __tvt_zl_nvis
    scalar `CV'   = __tvt_zl_cv
    scalar `C90'  = __tvt_zl_cv90
    scalar `C95'  = __tvt_zl_cv95
    scalar `C99'  = __tvt_zl_cv99
    scalar `PV'   = __tvt_zl_p
    scalar `NN'   = __tvt_zl_n
    _tvt_drop

    local rej = (`STAT' > `CV')

    display ""
    display as text "LR test, AR(`lags') against threshold AR(`lags')" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result ///
        %9.0fc `NN'
    display as text "Zhu and Ling (2012), JTSA 33(2)" ///
        _col(52) as text "Splits searched" _col(68) "=" ///
        _col(71) as result %9.0fc `NV'
    display as text "{hline 78}"
    display as text "  H0: AR(`lags') with intercept, no change"
    display as text "  H1: changes to a threshold AR(`lags') at some" ///
        " date, with the threshold"
    display as text "      on L`delay'.`yvar'"
    display as text "{hline 78}"
    display as text "  LR statistic" _col(26) as result %14.4f `STAT'
    display as text "  break at observation" _col(26) as result %14.0f `KH'
    display as text "  threshold value" _col(26) as result %14.6f `RH'
    display as text "{hline 78}"
    display as text "  simulated critical values (trim = " as result ///
        %4.2f `trim' as text ", p = " as result `lags' as text ")"
    display as text "     10%" _col(14) as result %10.4f `C90' ///
        as text _col(28) "5%" _col(34) as result %10.4f `C95' ///
        as text _col(48) "1%" _col(54) as result %10.4f `C99'
    display as text "  simulated p-value" _col(26) as result %14.4f `PV' ///
        as text "   (`simreps' draws, grid `gridm')"
    display as text "{hline 78}"
    display as text "  At the `level'% level the null is " as result ///
        cond(`rej', "REJECTED", "not rejected") as text "."
    display as text "{hline 78}"
    display as text "  The critical values are SIMULATED from the" ///
        " paper's own limiting"
    display as text "  distribution, not read from its Tables 1-2," ///
        " so any p and any trim()"
    display as text "  are available rather than only the tabulated" ///
        " ones. The simulation"
    display as text "  reproduces the published points at p = 0, 1, 3, 4" ///
        " and 5; at {bf:p = 2} it"
    display as text "  does not, and the paper's own p = 2 column is" ///
        " anomalous against its"
    display as text "  neighbours. See the equation map before" ///
        " relying on p = 2."
    display as text "{hline 78}"

    return scalar stat   = `STAT'
    return scalar reject = `rej'
    return scalar level  = `level'
    return scalar cv     = `CV'
    return scalar cv10   = `C90'
    return scalar cv05   = `C95'
    return scalar cv01   = `C99'
    return scalar p      = `PV'
    return scalar k      = `KH'
    return scalar r      = `RH'
    return scalar N      = `NN'
    return scalar lags   = `lags'
    return scalar delay  = `delay'
    return scalar trim   = `trim'
    return scalar simreps = `simreps'
    return scalar gridm  = `gridm'
    return scalar n_split = `NV'
    return local  method  "zhuling"
    return local  varname "`varlist'"
    return local  cmd     "tvtlr"
end
