*! tvtfourier 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold regression whose threshold is a Fourier function of time.
*! The flagship estimator of TVTHRESH: it is to this library what an
*! ordinary threshold regression is to a constant-threshold one.
*!
*! Yang, L., C. Lee and I.-P. Chen (2021) Journal of Time Series Analysis
*!   42(4):406-430, doi:10.1111/jtsa.12574
*!   (DOI verified via Crossref 2026-10-13. NOTE the year: the paper's own
*!    running footer says 2020, the online-first date; the issue is 2021.)
*!
*! See tvtfourier.sthlp and validation/tvthresh/tvtfourier_equation_map.md.

program define tvtfourier, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtfourier" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric fv ts min=1) [if] [in] ,   ///
        THReshvar(varname numeric ts)                 ///
        [ TRIM(real 0.15)                             ///
          NGrid(integer 15)                           ///
          AMPlitude(real 2)                           ///
          KMAX(integer 5)                             ///
          REFine(integer 2)                           ///
          REPS(integer 0)                             ///
          BLevel(cilevel)                             ///
          noCI                                        ///
          noCONStant                                  ///
          Level(cilevel) ]

    * ------------------------------------------------------------ checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `ngrid' < 2 {
        display as error "{bf:ngrid()} must be at least 2"
        display as error "it is the number of points per side of the" ///
            " grid over the two"
        display as error "Fourier coefficients; the paper does not" ///
            " specify one"
        exit 198
    }
    if `amplitude' <= 0 {
        display as error "{bf:amplitude()} must be positive"
        exit 198
    }
    if `kmax' < 1 | `kmax' > 20 {
        display as error "{bf:kmax()} must be between 1 and 20"
        display as error "the paper uses the integer frequencies 1 to 5," ///
            " following Becker,"
        display as error "Enders and Lee (2006), which is the default"
        exit 198
    }
    if `refine' < 0 | `refine' > 10 {
        display as error "{bf:refine()} must be between 0 and 10"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }

    * ----------------------------------------------------------- sample
    gettoken depv xvars : varlist
    marksample touse
    markout `touse' `depv' `xvars' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        display as error "too few observations (`nobs')"
        exit 2001
    }

    * The threshold is a Fourier function of TIME, so the observations must
    * be equally spaced: sin(2 pi k t/T) with t the row position is the
    * intended basis only when position and calendar agree. A hole in the
    * calendar would compress the time axis across the gap and the fitted
    * period would mean something different either side of it. Refuse
    * rather than silently fit the wrong basis.
    capture quietly tsset
    if _rc == 0 {
        local tvar "`r(timevar)'"
        if "`tvar'" != "" {
            tempvar tt
            quietly generate double `tt' = `tvar' if `touse'
            quietly summarize `tt', meanonly
            local tspan = r(max) - r(min) + 1
            quietly count if `touse'
            if `tspan' != r(N) {
                display as error "`tvar' has gaps inside the estimation" ///
                    " sample"
                display as error "(span `tspan' periods, " r(N) ///
                    " observations)."
                display as error ""
                display as error "The threshold here is a Fourier" ///
                    " function of time, so the"
                display as error "observations must be equally spaced." ///
                    " Across a gap the fitted"
                display as error "period would mean different things" ///
                    " either side of it."
                display as error "Fill the gaps, or restrict to an" ///
                    " unbroken span."
                exit 459
            }
        }
    }

    local hascons = cond("`constant'"=="", 1, 0)
    if "`xvars'" == "" & !`hascons' {
        display as error "with {bf:noconstant} there must be at least" ///
            " one regressor"
        exit 198
    }
    local doci = cond("`ci'"=="", 1, 0)
    if `reps' == 0 local doci 0

    * ---- locals the engine reads
    local qvar    "`threshvar'"
    local ngrid   `ngrid'
    local ampmult `amplitude'
    local npass   `refine'
    tempvar regvar pathvar
    quietly generate byte   `regvar'  = .
    quietly generate double `pathvar' = .

    _tvt_drop

    if `reps' > 0 {
        display as text "running `reps' bootstrap replications; each one" ///
            " repeats the whole"
        display as text "search, including the frequency selection" ///
            " {hline 2} see the help."
    }

    mata: tvt_fourier()

    * ---- harvest everything before any other command touches r()/e()
    tempname SSR SSRD SSRC SSR0 G0 G1 G2 KK GC F1 F2 F2S P1 P2 AMP
    scalar `SSR'  = __tvt_fo_ssr
    scalar `SSRD' = __tvt_fo_ssrd
    scalar `SSRC' = __tvt_fo_ssrc
    scalar `SSR0' = __tvt_fo_ssr0
    scalar `G0'   = __tvt_fo_g0
    scalar `G1'   = __tvt_fo_g1
    scalar `G2'   = __tvt_fo_g2
    scalar `KK'   = __tvt_fo_k
    scalar `GC'   = __tvt_fo_gc
    scalar `F1'   = __tvt_fo_f1
    scalar `F2'   = __tvt_fo_f2
    scalar `F2S'  = __tvt_fo_f2sup
    scalar `P1'   = __tvt_fo_p1
    scalar `P2'   = __tvt_fo_p2
    scalar `AMP'  = __tvt_fo_amp
    local TT  = __tvt_fo_T
    local MM  = __tvt_fo_m
    local N1  = __tvt_fo_n1
    tempname BM SSRK CIM PATH
    matrix `BM'   = __tvt_fo_b
    matrix `SSRK' = __tvt_fo_ssrk
    matrix `PATH' = __tvt_fo_path
    local hasci 0
    capture confirm matrix __tvt_fo_ci
    if _rc == 0 {
        matrix `CIM' = __tvt_fo_ci
        local hasci 1
        local nboot = __tvt_fo_nboot
    }
    _tvt_drop

    * ---- conventional covariance, CONDITIONAL on the fitted path.
    * Hansen's (2000) argument carries over: the threshold estimate
    * converges fast enough that the slope coefficients have their usual
    * asymptotics given it. That is what this V is. It does NOT account for
    * the uncertainty in the threshold path itself -- the bootstrap
    * intervals are what do that, and they are the paper's own inference.
    tempvar dvar
    quietly generate byte `dvar' = `regvar' if `touse'
    tempname bfull Vfull
    quietly _regress_fourier `depv' `xvars' if `touse', ///
        dummy(`dvar') hascons(`hascons') bname(`bfull') vname(`Vfull')

    * ---- names for the coefficient vector of eq (4): b2 first, then the
    *      differential b1 - b2. That is the paper's ordering.
    local nm
    foreach v of local xvars {
        local nm `nm' upper:`v'
    }
    if `hascons' local nm `nm' upper:_cons
    foreach v of local xvars {
        local nm `nm' diff:`v'
    }
    if `hascons' local nm `nm' diff:_cons
    matrix colnames `bfull' = `nm'
    matrix colnames `Vfull' = `nm'
    matrix rownames `Vfull' = `nm'

    * ----------------------------------------------------------- post
    ereturn post `bfull' `Vfull', esample(`touse') depname(`depv') ///
        obs(`TT')
    ereturn scalar N        = `TT'
    ereturn scalar k_x      = `MM'
    ereturn scalar N_lower  = `N1'
    ereturn scalar N_upper  = `TT' - `N1'
    ereturn scalar gamma0   = `G0'
    ereturn scalar gamma1   = `G1'
    ereturn scalar gamma2   = `G2'
    ereturn scalar k        = `KK'
    ereturn scalar gamma_c  = `GC'
    ereturn scalar ssr      = `SSR'
    ereturn scalar ssr_refit = `SSRD'
    ereturn scalar ssr_const = `SSRC'
    ereturn scalar ssr_lin  = `SSR0'
    ereturn scalar F1       = `F1'
    ereturn scalar F2       = `F2'
    ereturn scalar F2_sup   = `F2S'
    ereturn scalar p1       = `P1'
    ereturn scalar p2       = `P2'
    ereturn scalar reps     = `reps'
    ereturn scalar trim     = `trim'
    ereturn scalar ngrid    = `ngrid'
    ereturn scalar kmax     = `kmax'
    ereturn scalar refine   = `refine'
    ereturn scalar amp      = `AMP'
    ereturn scalar blevel   = `blevel'
    ereturn local  cmd      "tvtfourier"
    ereturn local  cmdline  "tvtfourier `0'"
    ereturn local  depvar   "`depv'"
    ereturn local  indepvars "`xvars'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  title    "Fourier time-varying threshold regression"
    ereturn matrix ssrk = `SSRK'
    ereturn matrix path = `PATH'
    if `hasci' {
        ereturn matrix ci = `CIM'
        ereturn scalar n_boot = `nboot'
    }

    Display, level(`level')
end

* ---------------------------------------------------------------------
* The output. Shared by the estimation path and by replay.
* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Yang, Lee and Chen (2021)" ///
        _col(52) as text "Lower regime" _col(68) "=" ///
        _col(71) as result %9.0fc e(N_lower)
    display as text "Threshold variable: " as result "`e(threshvar)'" ///
        _col(52) as text "Upper regime" _col(68) "=" ///
        _col(71) as result %9.0fc e(N_upper)
    display ""

    * the fitted threshold path
    display as text "{hline 78}"
    display as text "  The fitted threshold:  " ///
        "gamma(t) = g0 + g1 sin(2*pi*k*t/T) + g2 cos(2*pi*k*t/T)"
    display as text "{hline 78}"
    display as text "    g0 (level)" _col(26) as result %14.6g e(gamma0)
    display as text "    g1 (sine)" _col(26) as result %14.6g e(gamma1)
    display as text "    g2 (cosine)" _col(26) as result %14.6g e(gamma2)
    display as text "    k  (frequency)" _col(26) as result %14.0f e(k)
    if e(n_boot) < . {
        tempname C
        matrix `C' = e(ci)
        local nb = rowsof(`C')
        display as text "    " as text "{bf:" ///
            string(e(blevel)*100, "%4.0f") "% bootstrap intervals}" ///
            " (symmetric percentile, " as result e(n_boot) as text " reps)"
        display as text "    g0" _col(26) as result ///
            "[" %10.6g `C'[`=`nb'-2',1] ", " %10.6g `C'[`=`nb'-2',2] "]"
        display as text "    g1" _col(26) as result ///
            "[" %10.6g `C'[`=`nb'-1',1] ", " %10.6g `C'[`=`nb'-1',2] "]"
        display as text "    g2" _col(26) as result ///
            "[" %10.6g `C'[`nb',1] ", " %10.6g `C'[`nb',2] "]"
        display as text "    (no interval for k: the paper proves its" ///
            " convergence rate"
        display as text "     cannot be obtained, so one would be" ///
            " invented -- see help)"
    }
    display as text "{hline 78}"

    * the coefficients
    ereturn display, level(`level')

    * the two tests
    display as text "{hline 78}"
    display as text "  Specification tests"
    display as text "{hline 78}"
    display as text "    SSR, linear model" _col(34) as result %14.4f ///
        e(ssr_lin)
    display as text "    SSR, constant threshold" _col(34) as result ///
        %14.4f e(ssr_const)
    display as text "    SSR, Fourier threshold" _col(34) as result ///
        %14.4f e(ssr)
    display as text "{hline 78}"
    display as text "    F1  linear vs Fourier threshold" ///
        _col(40) as result %12.4f e(F1)
    if e(p1) < . {
        display as text "        bootstrap p-value" _col(40) ///
            as result %12.4f e(p1)
    }
    else {
        display as text "        bootstrap p-value" _col(40) ///
            as text "          --   (reps(0))"
    }
    display as text "    F2  constant vs Fourier threshold" ///
        _col(40) as result %12.4f e(F2)
    if e(p2) < . {
        display as text "        bootstrap p-value" _col(40) ///
            as result %12.4f e(p2)
    }
    else {
        display as text "        bootstrap p-value" _col(40) ///
            as text "          --   (reps(0))"
    }
    display as text "{hline 78}"
    if e(reps) == 0 {
        display as text "  Both statistics have NON-STANDARD null" ///
            " distributions: the threshold is"
        display as text "  unidentified under each null (Davies'" ///
            " problem), so F1 and F2 cannot"
        display as text "  be compared with an F table. Specify" ///
            " {bf:reps()} for bootstrap"
        display as text "  p-values. Until then the statistics above are" ///
            " descriptive only."
    }
    else {
        display as text "  p-values are two-point wild bootstrap," ///
            " each generating under its"
        display as text "  own null and re-running the whole search." ///
            "  See {helpb tvtfourier}."
    }
end

* ---------------------------------------------------------------------
* The conditional least-squares fit of eq (4). Factored out so that the
* main program never has to build interaction variables by hand, which is
* where a name collision with the user's own variables would come from.
* ---------------------------------------------------------------------
program define _regress_fourier, rclass
    version 15
    syntax varlist(numeric fv ts) [if] [in], Dummy(varname) ///
        HASCONS(integer) BNAME(string) VNAME(string)

    gettoken depv xvars : varlist
    marksample touse
    tempvar one
    quietly generate byte `one' = 1

    * THE ORDERING IS THE WHOLE POINT OF THIS SUBPROGRAM.
    *
    * The engine's coefficient vector follows the paper's eq (4): the upper
    * regime's full vector b2 -- regressors THEN the constant -- followed by
    * the differential b1 - b2 in the same order. Stata's -regress- instead
    * appends _cons LAST, after every interaction, so a plain
    *
    *     regress y x xd d
    *
    * returns (b2_x, diff_x, diff_cons, b2_cons): the constant terms land in
    * the wrong blocks and e(b) would not line up with e(ci), with the
    * engine's own b, or with the column names this command advertises.
    *
    * So the constant is built as an explicit variable in its proper place
    * and the fit is run with -noconstant-. The column order is then exactly
    * the engine's by construction, and the suite checks the two agree.
    local rhs
    foreach v of local xvars {
        local rhs `rhs' `v'
    }
    if `hascons' {
        tempvar one
        quietly generate double `one' = 1 if `touse'
        local rhs `rhs' `one'
    }
    foreach v of local xvars {
        tempvar z
        quietly generate double `z' = `v' * `dummy' if `touse'
        local rhs `rhs' `z'
    }
    if `hascons' {
        tempvar zc
        quietly generate double `zc' = `dummy' if `touse'
        local rhs `rhs' `zc'
    }

    quietly regress `depv' `rhs' if `touse', noconstant
    matrix `bname' = e(b)
    matrix `vname' = e(V)
end
