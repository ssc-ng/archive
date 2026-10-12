*! suradf 1.0.0  11oct2026
*! Series-specific SUR-ADF panel unit root test
*! Breuer, J. B., McNown, R. and Wallace, M. (2002), Oxford Bulletin of
*! Economics and Statistics 64(5), 527-546.  doi:10.1111/1468-0084.00276
*! Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*!
*! Step -> equation map (full version: help suradf methods)
*!   S1  design matrices, heterogeneous k_i ..... Eq. (1)   p.529
*!   S2  BMW general-to-specific lag selection .. Sec. V    p.539-540
*!   S3  SUR fit, t-ratio on the lagged level ... Eq. (3)   p.532 / Sec. III
*!   S4  restricted null SUR (no cons, no level)  Sec. V    p.540
*!   S5  Cholesky-correlated normal innovations . Eq. (2)   p.532 / fn.10
*!   S6  driftless unit-root recursion, own lags  Sec. V    p.540
*!   S7  50 burn-in obs, zero initial values .... fn.5 p.532 / Sec. V
*!   S8  re-estimate WITH intercept and level ... Sec. III  p.532
*!   S9  series-specific empirical quantiles .... Sec. III  p.532 / Table 5
*!   S10 AVECOR from the null-model Sigma-hat ... Table 5 note p.541
*!   S11 Dickey-Fuller benchmark (MacKinnon) .... p.533

program define suradf, rclass
    version 14.0

    syntax [anything] [if] [in] [,          ///
        LAGS(string)                        ///
        MAXLAGs(integer 8)                   ///
        REPS(integer 1000)                   ///
        SEED(string)                         ///
        BURN(integer 50)                     ///
        DIST(string)                         ///
        ADFPretest                           ///
        PTLevel(integer 5)                   ///
        DFK                                  ///
        ISURE                                ///
        TREND                                ///
        GRAPH                                ///
        DISTPlot                             ///
        GRAPHopts(string)                    ///
        NAME(string)                         ///
        NODOTS                               ///
        NOTABle                              ///
        SAVEDist(string)                     ///
    ]

    * ------------------------------------------------------------------
    * 0. parse the variable specification and the data layout
    * ------------------------------------------------------------------
    if (`"`anything'"' == "") {
        di as error "{p}specify one variable with {cmd:xtset} panel data, or two or"
        di as error "more variables with {cmd:tsset} time-series data{p_end}"
        exit 100
    }
    unab vlist : `anything'
    local nv : word count `vlist'

    local ivar ""
    local tvar ""
    local delta = 1

    if (`nv' == 1) {
        capture qui xtset
        if (_rc) {
            di as error "{p}data are not {cmd:xtset}.  With ONE variable {cmd:suradf}"
            di as error "reads a panel in long form, so it needs a panel identifier and a"
            di as error "time variable.  For a single time series use {helpb dfuller}; for"
            di as error "several series held as separate variables, list them all{p_end}"
            exit 459
        }
        local ivar "`r(panelvar)'"
        local tvar "`r(timevar)'"
        capture local delta = r(tdelta)
        if ("`ivar'" == "" | "`tvar'" == "") {
            di as error "{p}{cmd:xtset} must declare BOTH a panel variable and a time"
            di as error "variable.  These data look like a single time series: for one"
            di as error "series use {helpb dfuller}, and for several series held as separate"
            di as error "variables list them all, e.g. {cmd:suradf y1 y2 y3}{p_end}"
            exit 459
        }
        local long 1
    }
    else {
        capture qui tsset
        if (_rc) {
            di as error "{p}data are not {cmd:tsset}; with two or more variables {cmd:suradf}"
            di as error "treats each variable as one panel member of a time-series system{p_end}"
            exit 459
        }
        local tvar "`r(timevar)'"
        capture local delta = r(tdelta)
        local long 0
    }

    marksample touse, novarlist
    markout `touse' `vlist'
    if (`long') {
        markout `touse' `ivar' `tvar'
    }
    else {
        markout `touse' `tvar'
    }

    * ------------------------------------------------------------------
    * 1. shape checks: balance, gaps, and the small-N large-T requirement
    * ------------------------------------------------------------------
    qui levelsof `tvar' if `touse', local(tmlist)
    local T : word count `tmlist'
    local t1 : word 1 of `tmlist'
    local tL : word `T' of `tmlist'
    if (`delta' <= 0) local delta = 1
    local tspan = (`tL' - `t1') / `delta' + 1
    if (`tspan' != `T') {
        di as error "{p}the time variable has gaps over the estimation sample."
        di as error "SUR needs one contiguous common sample; fill or trim the gaps{p_end}"
        exit 451
    }

    if (`long') {
        qui levelsof `ivar' if `touse', local(idlist)
        local N : word count `idlist'
        qui count if `touse'
        if (r(N) != `N' * `T') {
            di as error "{p}the panel is unbalanced over the estimation sample"
            di as error "(`r(N)' observations for `N' units x `T' periods)."
            di as error "SUR requires a balanced common sample; restrict the sample"
            di as error "with {cmd:if} or drop the short units{p_end}"
            exit 451
        }
        local i = 0
        foreach v of local idlist {
            local ++i
            local lbl : label (`ivar') `v'
            if (`"`lbl'"' == "") local lbl "`v'"
            local nm`i' `"`lbl'"'
        }
    }
    else {
        local N = `nv'
        qui count if `touse'
        if (r(N) != `T') {
            di as error "missing values leave an incomplete common sample"
            exit 451
        }
        local i = 0
        foreach v of local vlist {
            local ++i
            local nm`i' "`v'"
        }
    }

    if (`N' < 2) {
        di as error "{p}{cmd:suradf} needs at least two series; with one series a"
        di as error "SUR system is just the single-equation ADF test ({helpb dfuller}){p_end}"
        exit 2001
    }

    * ------------------------------------------------------------------
    * 2. options
    * ------------------------------------------------------------------
    if (`maxlags' < 0) {
        di as error "{bf:maxlags()} must be non-negative"
        exit 198
    }
    if (`reps' < 0) {
        di as error "{bf:reps()} must be non-negative"
        exit 198
    }
    if (`burn' < 0) {
        di as error "{bf:burn()} must be non-negative"
        exit 198
    }

    local trd = 0
    if ("`trend'" != "") local trd = 1
    local dfkv = 0
    if ("`dfk'" != "") local dfkv = 1
    local maxit = 1
    if ("`isure'" != "") local maxit = 50

    * An option declared as noXXX is parsed by syntax as a negation, and the
    * result may arrive in the macro XXX rather than noXXX.  Check both, so
    * nodots and notable work whichever convention this Stata version uses.
    local dotsv = 1
    if ("`nodots'" != "")     local dotsv = 0
    if ("`dots'" == "nodots") local dotsv = 0

    local notab = 0
    if ("`notable'" != "")      local notab = 1
    if ("`table'" == "notable") local notab = 1

    local distb = 0
    if ("`dist'" != "") {
        local dist = lower(`"`dist'"')
        if ("`dist'" == "normal") local distb = 0
        else if (substr("`dist'", 1, 4) == "boot") local distb = 1
        else {
            di as error "{bf:dist()} must be {bf:normal} or {bf:bootstrap}"
            exit 198
        }
    }

    * ---- lag specification ----------------------------------------------
    local lmode = 1
    tempname kmat
    if (`"`lags'"' == "") local lags "bmw"
    local lags = lower(`"`lags'"')
    if ("`lags'" == "bmw") {
        local lmode = 1
    }
    else if ("`lags'" == "aic") {
        local lmode = 2
    }
    else if ("`lags'" == "bic" | "`lags'" == "sbic") {
        local lmode = 3
    }
    else {
        capture numlist "`lags'", integer range(>=0)
        if (_rc) {
            di as error "{p}{bf:lags()} takes {bf:bmw}, {bf:aic}, {bf:bic}, a single"
            di as error "non-negative integer, or `N' integers, one per series{p_end}"
            exit 198
        }
        local klist "`r(numlist)'"
        local nk : word count `klist'
        if (`nk' != 1 & `nk' != `N') {
            di as error "{bf:lags()} needs either one value or `N' values"
            exit 198
        }
        matrix `kmat' = J(`N', 1, 0)
        forvalues i = 1/`N' {
            if (`nk' == 1) local kv : word 1 of `klist'
            else local kv : word `i' of `klist'
            matrix `kmat'[`i', 1] = `kv'
            if (`kv' > `maxlags') local maxlags = `kv'
        }
        local lmode = 0
    }
    if (`lmode' != 0) {
        matrix `kmat' = J(`N', 1, 0)
    }

    * ---- the small-N large-T guard --------------------------------------
    * SUR needs Sigma-hat (N x N) invertible, so the usable sample must
    * comfortably exceed N.  This is the documented failure mode of the
    * original RATS implementation.
    local maxfeas = `T' - `N' - 3
    if (`maxlags' > `maxfeas') {
        if (`maxfeas' < 0) local maxfeas = 0
        di as text "{p}note: {bf:maxlags()} reduced from `maxlags' to `maxfeas' so that"
        di as text "the usable sample stays larger than the number of equations{p_end}"
        local maxlags = `maxfeas'
        if (`lmode' == 0) {
            forvalues i = 1/`N' {
                if (`kmat'[`i', 1] > `maxlags') matrix `kmat'[`i', 1] = `maxlags'
            }
        }
    }
    local teffmin = `T' - `maxlags' - 1
    if (`teffmin' <= `N' + 2) {
        di as error "{p}T = `T' is too short for N = `N' equations: the usable sample"
        di as error "would be `teffmin' observations.  SURADF is a small-N large-T"
        di as error "procedure -- the estimated cross-equation covariance matrix is"
        di as error "singular or near-singular otherwise.  Shorten {bf:maxlags()},"
        di as error "drop panel members, or use a longer sample{p_end}"
        exit 459
    }

    if ("`seed'" != "") {
        set seed `seed'
    }

    * ------------------------------------------------------------------
    * 2c. optional single-equation ADF pre-test for panel membership
    *
    * Breuer, McNown and Wallace (2006, RIE 14(3), p.515) recommend exactly
    * this when T is small: run the single-equation ADF first and EXCLUDE the
    * series that reject, so that the panel to which SURADF is applied is one
    * whose members all plausibly carry a unit root.  Their reasoning is that
    * the SUR critical values are simulated under "every member is I(1)", and
    * leaving a known I(0) member in the system distorts that null.
    * ------------------------------------------------------------------
    local ptdropped = 0
    if ("`adfpretest'" != "") {
        if (!inlist(`ptlevel', 1, 5, 10)) {
            di as error "{bf:ptlevel()} must be 1, 5 or 10"
            exit 198
        }
        tempname PT
        mata: _suradf_main("`vlist'", "`ivar'", "`tvar'", "`touse'", `long', ///
            `lmode', "`kmat'", `maxlags', 0, `burn', `trd', `dfkv',          ///
            `maxit', `distb', 0)
        if (scalar(__sa_fail) == 1) {
            capture scalar drop __sa_fail
            di as error "the system is singular; the ADF pre-test cannot be run"
            exit 506
        }
        matrix `PT' = __sa_tab
        mata: _sa_putdfcv(st_numscalar("__sa_Teff"))
        local ptcv = `dfc'
        if (`ptlevel' == 1)  local ptcv = `dfc1'
        if (`ptlevel' == 10) local ptcv = `dfc10'

        local keep ""
        local dropnm ""
        local nkeep = 0
        forvalues i = 1/`N' {
            local a = `PT'[`i', 3]
            if (`a' < . & `a' <= `ptcv') {
                local dropnm `"`dropnm' `nm`i''"'
            }
            else {
                local ++nkeep
                local keep "`keep' `i'"
            }
        }

        if (`nkeep' < `N') {
            di as text _n "ADF pre-test for panel membership (Breuer, McNown and"
            di as text "Wallace 2006): series rejecting the unit root in the"
            di as text "single-equation framework at the `ptlevel'% level are excluded."
            di as text "  Dickey-Fuller `ptlevel'% critical value: " as result %7.3f `ptcv'
            di as text "  Excluded (" as result `=`N'-`nkeep'' as text "):" as result `"`dropnm'"'

            if (`nkeep' < 2) {
                di as error "{p}only `nkeep' series survive the pre-test, and SURADF needs"
                di as error "at least two.  Every other series is already stationary by the"
                di as error "single-equation test -- report those ADF results instead{p_end}"
                exit 2001
            }

            * ---- rebuild the sample, the names and the lag matrix ----
            tempname KM2
            matrix `KM2' = J(`nkeep', 1, 0)
            local j = 0
            local newids ""
            local newvl ""
            local k2 = 0
            forvalues i = 1/`N' {
                if (`: list posof "`i'" in keep' > 0) {
                    local ++k2
                    local nmn`k2' `"`nm`i''"'
                    matrix `KM2'[`k2', 1] = `kmat'[`i', 1]
                    if (`long') {
                        local vv : word `i' of `idlist'
                        local newids "`newids' `vv'"
                    }
                    else {
                        local vv : word `i' of `vlist'
                        local newvl "`newvl' `vv'"
                    }
                }
            }
            if (`long') {
                local cond ""
                foreach v of local newids {
                    local cond "`cond' `ivar'==`v' |"
                }
                local cond = substr("`cond'", 1, length("`cond'") - 1)
                qui replace `touse' = 0 if !(`cond')
                local idlist "`newids'"
            }
            else {
                local vlist "`newvl'"
            }
            local N = `nkeep'
            matrix `kmat' = `KM2'
            forvalues i = 1/`N' {
                local nm`i' `"`nmn`i''"'
            }
            local ptdropped = 1

            * ---- the N/T guard must be re-checked on the smaller panel ----
            local teffmin = `T' - `maxlags' - 1
            if (`teffmin' <= `N' + 2) {
                di as error "{p}after the pre-test the sample is still too short:"
                di as error "T_eff = `teffmin' against N = `N'{p_end}"
                exit 459
            }
        }
        else {
            di as text _n "ADF pre-test: no series rejects at the `ptlevel'% level;"
            di as text "the panel is unchanged."
        }
        capture scalar drop __sa_fail __sa_T __sa_Teff __sa_N __sa_kmax
        capture matrix drop __sa_tab __sa_corr
    }

    * ------------------------------------------------------------------
    * 3. engine
    * ------------------------------------------------------------------
    tempname TAB CORR SIM
    if (`dotsv' & `reps' > 0) {
        di as text ""
        di as text "Simulating critical values under H0 (`reps' replications)"
    }

    mata: _suradf_main("`vlist'", "`ivar'", "`tvar'", "`touse'", `long',   ///
        `lmode', "`kmat'", `maxlags', `reps', `burn', `trd', `dfkv',       ///
        `maxit', `distb', `dotsv')

    if (`dotsv' & `reps' > 0) di as text ""

    if (scalar(__sa_fail) == 1) {
        capture scalar drop __sa_fail __sa_T __sa_Teff __sa_N __sa_kmax
        di as error "{p}the estimated cross-equation covariance matrix is not positive"
        di as error "definite, so the critical values cannot be simulated.  This almost"
        di as error "always means N is too large relative to T, or two series in the"
        di as error "panel are collinear.  Drop a member and re-run{p_end}"
        exit 506
    }

    matrix `TAB'  = __sa_tab
    matrix `CORR' = __sa_corr
    local Teff = scalar(__sa_Teff)
    local kmax = scalar(__sa_kmax)

    * matrix row names must be plain Stata names: strip anything else
    local rn ""
    local nmlist ""
    forvalues i = 1/`N' {
        local nmlist `"`nmlist' `"`nm`i''"'"'
        local nmi `"`nm`i''"'
        local nmi = subinstr(`"`nmi'"', " ", "_", .)
        local nmi = subinstr(`"`nmi'"', "-", "_", .)
        local nmi = subinstr(`"`nmi'"', ".", "_", .)
        local nmi = subinstr(`"`nmi'"', ",", "", .)
        local nmi = subinstr(`"`nmi'"', "'", "", .)
        local nmi = substr(`"`nmi'"', 1, 28)
        capture confirm name `nmi'
        if (_rc) local nmi "s`i'"
        local rn "`rn' `nmi'"
    }
    matrix rownames `TAB'  = `rn'
    matrix rownames `CORR' = `rn'
    matrix colnames `CORR' = `rn'
    matrix colnames `TAB'  = k avecor adf suradf cv1 cv5 cv10 p

    * ------------------------------------------------------------------
    * 4. display
    * ------------------------------------------------------------------
    if (`notab' == 0) {
        _suradf_disp, tab(`TAB') n(`N') nper(`T') teff(`Teff')            ///
            reps(`reps') burn(`burn') lmode(`lmode') maxlags(`maxlags')  ///
            trend(`trd') dist(`distb') isure("`isure'")                  ///
            islong(`long') var("`vlist'") ivar("`ivar'") kmax(`kmax')
        _suradf_body, tab(`TAB') n(`N') labs(`"`nmlist'"') teff(`Teff')
        _suradf_verdict, tab(`TAB') n(`N') labs(`"`nmlist'"') reps(`reps') ///
            teff(`Teff') lmode(`lmode')
    }

    * ------------------------------------------------------------------
    * 5. graphs  (built BEFORE any return matrix move -- see gotcha #6)
    * ------------------------------------------------------------------
    if ("`graph'" != "") {
        _suradf_gph, tab(`TAB') n(`N') labs(`"`nmlist'"')                ///
            gname("`name'") gopts(`"`graphopts'"') var("`vlist'")
    }
    if ("`distplot'" != "" & `reps' > 0) {
        _suradf_gdist, n(`N') labs(`"`nmlist'"') tab(`TAB')              ///
            gname("`name'") reps(`reps')
    }

    * ------------------------------------------------------------------
    * 6. stored results
    * ------------------------------------------------------------------
    if (`"`savedist'"' != "" & `reps' > 0) {
        matrix `SIM' = __sa_sim
        matrix colnames `SIM' = `rn'
        matrix `savedist' = `SIM'
    }

    tempname STAT CV
    matrix `STAT' = `TAB'[1..., 4]
    matrix `CV'   = `TAB'[1..., 5..7]
    matrix colnames `STAT' = suradf
    matrix colnames `CV'   = cv1 cv5 cv10

    return matrix cv     = `CV',    copy
    return matrix stat   = `STAT',  copy
    return matrix corr   = `CORR',  copy
    return matrix table  = `TAB',   copy

    return scalar avecor = scalar(__sa_avecor)
    return scalar nI0    = scalar(__sa_nI0)
    return scalar nI1    = scalar(__sa_nI1)
    return scalar kmax   = `kmax'
    return scalar burn   = `burn'
    return scalar reps   = `reps'
    return scalar Teff   = `Teff'
    return scalar T      = `T'
    return scalar N      = `N'
    return scalar ptdrop = `ptdropped'
    local disttxt "normal"
    if (`distb') local disttxt "bootstrap"
    local lagtxt "bic"
    if (`lmode' == 0) local lagtxt "fixed"
    if (`lmode' == 1) local lagtxt "bmw"
    if (`lmode' == 2) local lagtxt "aic"

    return local  dist   "`disttxt'"
    return local  lags   "`lagtxt'"
    return local  depvar "`vlist'"
    return local  cmd    "suradf"

    capture scalar drop __sa_fail __sa_T __sa_Teff __sa_N __sa_kmax __sa_avecor __sa_nI0 __sa_nI1
    capture matrix drop __sa_tab __sa_corr __sa_sim
end


* ======================================================================
* header block
* ======================================================================
program define _suradf_disp
    * every option optional with a default: a REQUIRED option that also
    * carries a default is rejected by syntax with r(197)
    syntax [, tab(name) n(integer 0) nper(integer 0) teff(integer 0)      ///
        reps(integer 0) burn(integer 0) lmode(integer 1)                  ///
        maxlags(integer 0) trend(integer 0) dist(integer 0)               ///
        isure(string) islong(integer 0) var(string)                       ///
        ivar(string) kmax(integer 0) ]

    * these must stay within 20 characters: %-20s pads but does not truncate,
    * and an overlong label pushes the right-hand column out of alignment
    local lagtxt "BMW general-to-spec."
    if (`lmode' == 0) local lagtxt "user-specified"
    if (`lmode' == 2) local lagtxt "minimum AIC"
    if (`lmode' == 3) local lagtxt "minimum BIC"

    local dettxt "constant"
    if (`trend') local dettxt "constant and trend"

    local esttxt "two-step FGLS"
    if ("`isure'" != "") local esttxt "iterated FGLS"

    di as text ""
    di as text "Breuer-McNown-Wallace series-specific SUR-ADF unit root test"
    di as text "{hline 78}"
    di as text "  Series tested      " as result %-20s substr("`var'", 1, 20) _c
    di as text "  Equations (N)      " as result %9.0g `n'
    di as text "  Periods (T)        " as result %-20.0g `nper' _c
    di as text "  Usable obs (T_eff) " as result %9.0g `teff'
    di as text "  Deterministics     " as result %-20s "`dettxt'" _c
    di as text "  Estimator          " as result %9s "`esttxt'"
    di as text "  Lag selection      " as result %-20s "`lagtxt'" _c
    di as text "  Max lag searched   " as result %9.0g `maxlags'
    if (`reps' > 0) {
        local dtxt "normal"
        if (`dist') local dtxt "resid. bootstrap"
        di as text "  Replications       " as result %-20.0gc `reps' _c
        di as text "  Burn-in / innov.   " as result %5.0f `burn' as result " / `dtxt'"
    }
    di as text "{hline 78}"
    di as text "  H0: series i contains a unit root       (beta_i = 0)"
    di as text "  H1: series i is stationary              (beta_i < 0)"
    di as text "  tested separately for every i -- there is no joint panel hypothesis"
end


* ======================================================================
* main results table
* ======================================================================
program define _suradf_body
    syntax [, tab(name) n(integer 0) labs(string) teff(integer 0) ]

    * Column layout, fixed by _col() so the rule and the data always agree:
    *   name 1-14 | k 16-17 | AVECOR 20-25 | ADF 28-34 | bar 37
    *   SURADF 39-46 | 1% 47-53 | 5% 54-60 | 10% 61-67 | p 68-74 | stars 76-78
    di as text ""
    di as text "{hline 78}"
    di as text _col(25) "Single eq." _col(45) "Simulated critical values"
    di as text "Series" _col(17) "k" _col(20) "AVECOR" _col(32) "ADF"     ///
       _col(37) "{c |}" _col(41) "SURADF" _col(52) "1%" _col(59) "5%"     ///
       _col(65) "10%" _col(70) "p-val"
    di as text "{hline 78}"

    forvalues i = 1/`n' {
        local nmi : word `i' of `labs'
        local nmi = abbrev(`"`nmi'"', 14)
        local k   = `tab'[`i', 1]
        local ac  = `tab'[`i', 2]
        local adf = `tab'[`i', 3]
        local st  = `tab'[`i', 4]
        local c1  = `tab'[`i', 5]
        local c5  = `tab'[`i', 6]
        local c10 = `tab'[`i', 7]
        local pv  = `tab'[`i', 8]

        local star ""
        if (`pv' < .) {
            if (`st' <= `c10') local star "*"
            if (`st' <= `c5')  local star "**"
            if (`st' <= `c1')  local star "***"
        }

        di as text %-14s `"`nmi'"'                                        ///
           as result _col(16) %2.0f `k' _col(20) %6.3f `ac'               ///
           _col(28) %7.3f `adf'                                           ///
           as text _col(37) "{c |}"                                       ///
           as result _col(39) %8.3f `st' _col(47) %7.3f `c1'              ///
           _col(54) %7.3f `c5' _col(61) %7.3f `c10' _col(68) %7.3f `pv'   ///
           as text _col(76) "`star'"
    }

    di as text "{hline 78}"

    * ---- panel averages (Table 1 of the paper reports this form) ----
    local sac = 0
    local s1 = 0
    local s5 = 0
    local s10 = 0
    forvalues i = 1/`n' {
        local sac = `sac' + `tab'[`i', 2]
        local s1  = `s1'  + `tab'[`i', 5]
        local s5  = `s5'  + `tab'[`i', 6]
        local s10 = `s10' + `tab'[`i', 7]
    }
    local sac = `sac' / `n'
    local s1  = `s1'  / `n'
    local s5  = `s5'  / `n'
    local s10 = `s10' / `n'

    mata: _sa_putdfcv(`teff')

    di as text "Panel average" as result _col(20) %6.3f `sac'               ///
       as text _col(37) "{c |}"                                             ///
       as result _col(47) %7.3f `s1' _col(54) %7.3f `s5' _col(61) %7.3f `s10'
    di as text "Dickey-Fuller benchmark" as text _col(37) "{c |}"            ///
       as result _col(47) %7.3f `dfc1' _col(54) %7.3f `dfc'                  ///
       _col(61) %7.3f `dfc10'
    di as text "{hline 78}"
    di as text "{p 0 2}* p<0.10, ** p<0.05, *** p<0.01, read off the series-specific"
    di as text "simulated critical values -- reject when the statistic is MORE NEGATIVE."
    di as text "AVECOR is the mean residual correlation of series i with the rest of the"
    di as text "panel.  The Dickey-Fuller row is the single-equation benchmark at the same"
    di as text "sample size: the gap between the two rows is what the SUR correction buys,"
    di as text "and why Dickey-Fuller tables must not be used on a SUR statistic.{p_end}"
end


* ======================================================================
* verdict / decision block -- the point of the test
* ======================================================================
program define _suradf_verdict
    syntax [, tab(name) n(integer 0) labs(string) reps(integer 0) ///
        teff(integer 0) lmode(integer 1) ]

    local i0 ""
    local i1 ""
    local n0 = 0
    local n1 = 0
    local sac = 0
    forvalues i = 1/`n' {
        local sac = `sac' + `tab'[`i', 2]
        local nmi : word `i' of `labs'
        local st = `tab'[`i', 4]
        local c5 = `tab'[`i', 6]
        if (`c5' >= .) continue
        if (`st' < . & `st' <= `c5') {
            local ++n0
            local i0 `"`i0' `nmi'"'
        }
        else {
            local ++n1
            local i1 `"`i1' `nmi'"'
        }
    }

    if (`reps' < 1) {
        di as text ""
        di as text "{p 0 2}No critical values were simulated ({bf:reps(0)}), so no"
        di as text "series-specific verdict can be given: the statistics above cannot"
        di as text "be compared with any published table.  Re-run with {bf:reps()}"
        di as text "positive to obtain the test.{p_end}"
        exit
    }

    di as text ""
    di as text "Series-specific inference at the 5% level"
    di as text "{hline 78}"
    di as text "  Stationary, I(0) :" as result %3.0f `n0' as text " of `n'" _c
    if (`n0' > 0) di as result `"   `i0'"'
    else di ""
    di as text "  Unit root, I(1)  :" as result %3.0f `n1' as text " of `n'" _c
    if (`n1' > 0) di as result `"   `i1'"'
    else di ""
    di as text "{hline 78}"

    * ---- honest warnings -------------------------------------------------
    local warned = 0
    if (`reps' > 0 & `reps' < 1000) {
        di as text "{p 0 2}Warning: `reps' replications is below the 1,000 generally"
        di as text "recommended; Breuer, McNown and Wallace use 10,000.  The critical"
        di as text "values above carry visible Monte Carlo error.{p_end}"
        local warned = 1
    }
    if (`teff' < 60) {
        di as text "{p 0 2}Warning: with T_eff = `teff' the power of this test against a"
        di as text "root near one is low (BMW report power around 0.08-0.22 at T = 50)."
        di as text "A failure to reject is weak evidence of a unit root here.{p_end}"
        local warned = 1
    }
    local sac = `sac' / `n'
    if (`sac' < 0.20) {
        di as text "{p 0 2}Warning: the average residual cross-correlation is only " ///
            %5.3f `sac' as text ".  SURADF's whole advantage over the"
        di as text "single-equation test comes from that correlation; this weak, the two"
        di as text "are close to equivalent and {helpb dfuller} series by series is simpler"
        di as text "to report and to defend.  Compare the SURADF and ADF columns above"
        di as text "before choosing.{p_end}"
        local warned = 1
    }
    di as text "{p 0 2}Note: the critical values are specific to this panel's estimated"
    di as text "covariance matrix.  Adding or removing one series changes them for every"
    di as text "other series, so results are not comparable across panels of different"
    di as text "composition.  See {help suradf##guidance:help suradf} before reporting.{p_end}"
end


* ======================================================================
* decision plot: each statistic against its own simulated critical values
* ======================================================================
program define _suradf_gph
    syntax [, tab(name) n(integer 0) labs(string) gname(string) gopts(string) var(string) ]

    preserve
    clear
    qui set obs `n'
    qui gen int    _idx  = _n
    qui gen double _stat = .
    qui gen double _c1   = .
    qui gen double _c5   = .
    qui gen double _c10  = .
    qui gen str32  _nm   = ""
    forvalues i = 1/`n' {
        local nmi : word `i' of `labs'
        qui replace _stat = `tab'[`i', 4] in `i'
        qui replace _c1   = `tab'[`i', 5] in `i'
        qui replace _c5   = `tab'[`i', 6] in `i'
        qui replace _c10  = `tab'[`i', 7] in `i'
        qui replace _nm   = substr(`"`nmi'"', 1, 32) in `i'
    }
    qui levelsof _idx, local(ix)
    local xlab ""
    forvalues i = 1/`n' {
        local nmi : word `i' of `labs'
        local nmi = abbrev(`"`nmi'"', 10)
        local xlab `"`xlab' `i' `"`nmi'"'"'
    }

    if ("`gname'" == "") local gname "suradf"

    twoway  (rbar _c1 _c10 _idx, barwidth(0.55)                           ///
                 color(gs13) lcolor(gs10) lwidth(vthin))                   ///
            (line _c5 _idx, connect(J) lpattern(dash) lcolor(navy)          ///
                 lwidth(medthick))                                          ///
            (scatter _stat _idx, msymbol(O) msize(medlarge)                ///
                 mcolor(cranberry) mlcolor(black) mlwidth(vthin))          ///
        , legend(order(3 "SURADF statistic" 2 "5% critical value"          ///
                       1 "1%-10% critical range") rows(1) size(small)      ///
                 region(lcolor(none)))                                     ///
          xlabel(`xlab', angle(45) labsize(small) nogrid)                  ///
          xtitle("") ytitle("t-statistic on the lagged level")             ///
          title("Series-specific SUR-ADF test", size(medium))              ///
          subtitle("`var' -- a marker below the dashed line rejects the unit root at 5%", ///
                   size(vsmall))                                           ///
          xscale(range(0.4 `=`n'+0.6'))                                    ///
          graphregion(color(white)) plotregion(color(white))               ///
          ylabel(, angle(0) labsize(small) grid glcolor(gs15))             ///
          name(`gname', replace) `gopts'
    restore
end


* ======================================================================
* simulated null densities with the observed statistic marked
* ======================================================================
program define _suradf_gdist
    syntax [, n(integer 0) labs(string) tab(name) reps(integer 0) gname(string) ]

    capture confirm matrix __sa_sim
    if (_rc) {
        di as text "note: {bf:distplot} needs the simulated draws; re-run without {bf:nodots}"
        exit
    }
    if ("`gname'" == "") local gname "suradf"

    preserve
    clear
    qui set obs `reps'
    qui svmat double __sa_sim, name(sd)

    local glist ""
    local nshow = min(`n', 9)
    forvalues i = 1/`nshow' {
        local nmi : word `i' of `labs'
        local nmi = abbrev(`"`nmi'"', 14)
        local st  = `tab'[`i', 4]
        local c5  = `tab'[`i', 6]
        capture kdensity sd`i', nograph generate(x`i' d`i') n(`reps')
        if (_rc) continue
        twoway  (area d`i' x`i', color(gs13) lcolor(gs9) lwidth(vthin))     ///
            , xline(`st', lcolor(cranberry) lwidth(medthick))               ///
              xline(`c5', lcolor(navy) lpattern(dash))                      ///
              legend(off) xtitle("") ytitle("")                             ///
              title(`"`nmi'"', size(small))                                 ///
              ylabel(none) xlabel(, labsize(vsmall))                        ///
              graphregion(color(white)) plotregion(color(white))            ///
              name(`gname'_d`i', replace) nodraw
        local glist "`glist' `gname'_d`i'"
    }
    if (`"`glist'"' != "") {
        graph combine `glist'                                              ///
            , title("Simulated null distribution of the SURADF statistic", size(medium)) ///
              subtitle("red = observed statistic, blue dash = 5% critical value", size(vsmall)) ///
              graphregion(color(white)) name(`gname'_dist, replace)
    }
    restore
end


* ======================================================================
* Mata engine
* ======================================================================
version 14.0
mata:

// ------------------------------------------------------------------
// S11  MacKinnon response surface, constant-only ADF.
// Reproduces the -2.93 / -2.89 / -2.88 quoted on p.533 of the paper.
// ------------------------------------------------------------------
real rowvector _sa_dfcv(real scalar T)
{
    real rowvector cv
    real scalar a, b, c

    a = 1 / T
    b = a * a
    c = b * a
    cv = J(1, 3, 0)
    cv[1] = -3.43035 - 6.5393 * a - 16.786 * b - 79.433 * c
    cv[2] = -2.86154 - 2.8903 * a -  4.234 * b - 40.040 * c
    cv[3] = -2.56677 - 1.5384 * a -  2.809 * b
    return(cv)
}

// Mata cannot subscript a function result inline, so the caller gets
// the three values through a staging variable.
void _sa_putdfcv(real scalar T)
{
    real rowvector cv

    cv = _sa_dfcv(T)
    st_local("dfc1", strofreal(cv[1]))
    st_local("dfc",  strofreal(cv[2]))
    st_local("dfc10", strofreal(cv[3]))
}

// ------------------------------------------------------------------
// empirical quantile, linear interpolation between order statistics
// ------------------------------------------------------------------
real scalar _sa_quantile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo, hi, g

    n = rows(x)
    if (n < 1) {
        return(.)
    }
    s = sort(x, 1)
    h = (n - 1) * p + 1
    lo = floor(h)
    hi = ceil(h)
    if (lo < 1) {
        lo = 1
    }
    if (hi > n) {
        hi = n
    }
    g = h - lo
    return(s[lo] + g * (s[hi] - s[lo]))
}

// ------------------------------------------------------------------
// Ljung-Box Q, df = m (matches wntestq)
// ------------------------------------------------------------------
real scalar _sa_lbq(real colvector e, real scalar m)
{
    real scalar n, j, q, r0, rj
    real colvector ec

    n = rows(e)
    ec = e :- mean(e)
    r0 = quadcross(ec, ec)
    if (r0 <= 0) {
        return(.)
    }
    q = 0
    for (j = 1; j <= m; j++) {
        if (n - j >= 1) {
            rj = quadcross(ec[(j+1)..n], ec[1..(n-j)]) / r0
            q = q + rj * rj / (n - j)
        }
    }
    return(n * (n + 2) * q)
}

// ------------------------------------------------------------------
// |t| on the highest lag of  Dy on Dy(-1)..Dy(-k), NO intercept
// ------------------------------------------------------------------
real scalar _sa_lastt(real colvector dy, real scalar k)
{
    real scalar n, T, j, s2, se
    real colvector y, b, e
    real matrix X, iXX

    if (k < 1) {
        return(0)
    }
    n = rows(dy)
    T = n - k
    if (T <= k + 1) {
        return(0)
    }
    y = dy[(k+1)..n]
    X = J(T, k, 0)
    for (j = 1; j <= k; j++) {
        X[., j] = dy[(k+1-j)..(n-j)]
    }
    iXX = invsym(quadcross(X, X))
    b = iXX * quadcross(X, y)
    e = y - X * b
    s2 = quadcross(e, e) / (T - k)
    if (s2 <= 0) {
        return(0)
    }
    if (iXX[k, k] <= 0) {
        return(0)
    }
    se = sqrt(s2 * iXX[k, k])
    if (se <= 0) {
        return(0)
    }
    return(abs(b[k] / se))
}

// ------------------------------------------------------------------
// does a k-lag fit leave serial correlation?  Q at 4, 8 and 12 lags,
// 10% level, exactly as Breuer-McNown-Wallace Sec. V describes.
// ------------------------------------------------------------------
real scalar _sa_serialbad(real colvector dy, real scalar k)
{
    real scalar n, T, j, q, ne
    real colvector y, b, e
    real matrix X

    n = rows(dy)
    if (k < 1) {
        e = dy
    } else {
        T = n - k
        if (T <= k + 1) {
            return(1)
        }
        y = dy[(k+1)..n]
        X = J(T, k, 0)
        for (j = 1; j <= k; j++) {
            X[., j] = dy[(k+1-j)..(n-j)]
        }
        b = invsym(quadcross(X, X)) * quadcross(X, y)
        e = y - X * b
    }
    ne = rows(e)
    for (j = 4; j <= 12; j = j + 4) {
        if (ne > j + 2) {
            q = _sa_lbq(e, j)
            if (q < .) {
                if (chi2tail(j, q) < 0.10) {
                    return(1)
                }
            }
        }
    }
    return(0)
}

// ------------------------------------------------------------------
// S2  BMW general-to-specific lag selection
// ------------------------------------------------------------------
real scalar _sa_lagsel_bmw(real colvector dy, real scalar kmaxin)
{
    real scalar k

    k = kmaxin
    while (k >= 1) {
        if (_sa_lastt(dy, k) >= 1.6449) {
            return(k)
        }
        if (_sa_serialbad(dy, k - 1) == 1) {
            return(k)
        }
        k = k - 1
    }
    return(0)
}

// ------------------------------------------------------------------
// AIC / BIC lag selection on a sample held fixed at kmaxin, so that
// the competing orders are compared on identical observations.
// ------------------------------------------------------------------
real scalar _sa_lagsel_ic(real colvector y, real scalar kmaxin, real scalar bic,
                          real scalar trend)
{
    real scalar n, s0, T, k, j, best, bestv, v, s2, nc
    real colvector dy, dep, b, e
    real matrix X

    n = rows(y)
    s0 = kmaxin + 2
    T = n - kmaxin - 1
    if (T < 5) {
        return(0)
    }
    dy = y[2..n] - y[1..(n-1)]
    dep = dy[(s0-1)..(n-1)]
    best = 0
    bestv = .
    for (k = 0; k <= kmaxin; k++) {
        nc = 2 + trend + k
        if (T <= nc + 1) {
            continue
        }
        X = y[(s0-1)..(n-1)], J(T, 1, 1)
        if (trend == 1) {
            X = X, (1::T)
        }
        for (j = 1; j <= k; j++) {
            X = X, dy[(s0-1-j)..(n-1-j)]
        }
        b = invsym(quadcross(X, X)) * quadcross(X, dep)
        e = dep - X * b
        s2 = quadcross(e, e) / T
        if (s2 <= 0) {
            continue
        }
        v = log(s2) + 2 * nc / T
        if (bic == 1) {
            v = log(s2) + log(T) * nc / T
        }
        if (v < bestv) {
            bestv = v
            best = k
        }
    }
    return(best)
}

// ------------------------------------------------------------------
// S1  design matrix for the ALTERNATIVE model, all equations stacked
// side by side on one common sample.  For equation i the columns are
//     [ y_i(t-1) , 1 , (trend) , Dy_i(t-1) ... Dy_i(t-k_i) ]
// so the lagged level is always the FIRST column of block i.
// ys and eqid are returned by reference.
// ------------------------------------------------------------------
real matrix _sa_design(real matrix Y, real colvector kk, real scalar trend,
                       real matrix ys, real colvector eqid)
{
    real scalar T, N, kmax, s0, Teff, i, j, nc, p
    real matrix dy, W

    T = rows(Y)
    N = cols(Y)
    kmax = max(kk)
    s0 = kmax + 2
    Teff = T - kmax - 1
    dy = Y[|2, 1 \ T, N|] - Y[|1, 1 \ T - 1, N|]
    ys = dy[|s0 - 1, 1 \ T - 1, N|]

    nc = 0
    for (i = 1; i <= N; i++) {
        nc = nc + 2 + trend + kk[i]
    }
    W = J(Teff, nc, 0)
    eqid = J(nc, 1, 0)
    p = 0
    for (i = 1; i <= N; i++) {
        p = p + 1
        W[., p] = Y[|s0 - 1, i \ T - 1, i|]
        eqid[p] = i
        p = p + 1
        W[., p] = J(Teff, 1, 1)
        eqid[p] = i
        if (trend == 1) {
            p = p + 1
            W[., p] = (1::Teff)
            eqid[p] = i
        }
        for (j = 1; j <= kk[i]; j++) {
            p = p + 1
            W[., p] = dy[|s0 - 1 - j, i \ T - 1 - j, i|]
            eqid[p] = i
        }
    }
    return(W)
}

// ------------------------------------------------------------------
// S4  design for the RESTRICTED null model: Dy_i on its own lagged
// differences only -- no intercept, no lagged level.
// ------------------------------------------------------------------
real matrix _sa_design0(real matrix Y, real colvector kk, real matrix ys,
                        real colvector eqid)
{
    real scalar T, N, kmax, s0, Teff, i, j, nc, p
    real matrix dy, W

    T = rows(Y)
    N = cols(Y)
    kmax = max(kk)
    s0 = kmax + 2
    Teff = T - kmax - 1
    dy = Y[|2, 1 \ T, N|] - Y[|1, 1 \ T - 1, N|]
    ys = dy[|s0 - 1, 1 \ T - 1, N|]

    nc = 0
    for (i = 1; i <= N; i++) {
        nc = nc + kk[i]
    }
    eqid = J(nc, 1, 0)
    if (nc < 1) {
        return(J(Teff, 0, 0))
    }
    W = J(Teff, nc, 0)
    p = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= kk[i]; j++) {
            p = p + 1
            W[., p] = dy[|s0 - 1 - j, i \ T - 1 - j, i|]
            eqid[p] = i
        }
    }
    return(W)
}

// ------------------------------------------------------------------
// S3  two-step (optionally iterated) FGLS on the stacked system.
// Equation-specific regressors are handled by indexing Sigma-inverse
// through eqid, which is both exact and fully vectorised:
//     A  = Sinv[eqid, eqid] :* (W'W)
//     c  = rowsum( Sinv[eqid, .] :* (W'ys) )
// Returns b by reference; V, Sig and the per-equation OLS residual
// matrix E likewise.  Function value is 1 on success, 0 on failure.
// ------------------------------------------------------------------
real scalar _sa_surfit(real matrix ys, real matrix W, real colvector eqid,
                       real colvector kcols, real scalar dfk, real scalar maxit,
                       real colvector b, real matrix V, real matrix Sig,
                       real matrix E)
{
    real scalar N, T, K, i, it, p1, p2, conv, prev
    real colvector off, cc, bi
    real matrix C, D, Si, A

    N = cols(ys)
    T = rows(ys)
    K = cols(W)

    off = J(N, 1, 0)
    for (i = 2; i <= N; i++) {
        off[i] = off[i - 1] + kcols[i - 1]
    }

    if (K > 0) {
        C = quadcross(W, W)
        D = quadcross(W, ys)
    }

    // ---- stage 1: equation-by-equation OLS ----
    E = J(T, N, 0)
    for (i = 1; i <= N; i++) {
        if (kcols[i] < 1) {
            E[., i] = ys[., i]
            continue
        }
        p1 = off[i] + 1
        p2 = off[i] + kcols[i]
        bi = invsym(C[|p1, p1 \ p2, p2|]) * D[|p1, i \ p2, i|]
        E[., i] = ys[., i] - W[|1, p1 \ T, p2|] * bi
    }

    Sig = _sa_sigma(E, kcols, dfk)
    if (K < 1) {
        b = J(0, 1, .)
        V = J(0, 0, .)
        return(1)
    }

    prev = .
    for (it = 1; it <= maxit; it++) {
        Si = invsym(Sig)
        if (hasmissing(Si)) {
            return(0)
        }
        A = Si[eqid, eqid] :* C
        cc = rowsum(Si[eqid, .] :* D)
        V = invsym(A)
        if (hasmissing(V)) {
            return(0)
        }
        b = V * cc
        if (it >= maxit) {
            break
        }
        for (i = 1; i <= N; i++) {
            if (kcols[i] < 1) {
                E[., i] = ys[., i]
                continue
            }
            p1 = off[i] + 1
            p2 = off[i] + kcols[i]
            E[., i] = ys[., i] - W[|1, p1 \ T, p2|] * b[|p1 \ p2|]
        }
        Sig = _sa_sigma(E, kcols, dfk)
        conv = abs(trace(Sig) - prev)
        if (conv < 1e-10) {
            break
        }
        prev = trace(Sig)
    }
    return(1)
}

// ------------------------------------------------------------------
// cross-equation covariance.  Default divisor T (Stata's sureg
// default); dfk uses sqrt((T-k_i)(T-k_j)), keeping Sigma symmetric.
// ------------------------------------------------------------------
real matrix _sa_sigma(real matrix E, real colvector kcols, real scalar dfk)
{
    real scalar N, T, i, j, d
    real matrix S

    N = cols(E)
    T = rows(E)
    S = quadcross(E, E)
    if (dfk == 1) {
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= N; j++) {
                d = sqrt((T - kcols[i]) * (T - kcols[j]))
                if (d <= 0) {
                    d = T
                }
                S[i, j] = S[i, j] / d
            }
        }
        return(S)
    }
    return(S / T)
}

// ------------------------------------------------------------------
// t-ratios on the lagged level: first column of each block
// ------------------------------------------------------------------
real colvector _sa_tvec(real colvector b, real matrix V, real colvector kcols)
{
    real scalar N, i, p
    real colvector off, t

    N = rows(kcols)
    off = J(N, 1, 0)
    for (i = 2; i <= N; i++) {
        off[i] = off[i - 1] + kcols[i - 1]
    }
    t = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        if (kcols[i] < 1) {
            continue
        }
        p = off[i] + 1
        if (V[p, p] > 0) {
            t[i] = b[p] / sqrt(V[p, p])
        }
    }
    return(t)
}

// ------------------------------------------------------------------
// single-equation ADF benchmark, same design, OLS equation by equation
// ------------------------------------------------------------------
real colvector _sa_adfvec(real matrix ys, real matrix W, real colvector kcols)
{
    real scalar N, T, i, p1, p2, s2
    real colvector off, adf, bi, ei
    real matrix Xi, iXX

    N = cols(ys)
    T = rows(ys)
    off = J(N, 1, 0)
    for (i = 2; i <= N; i++) {
        off[i] = off[i - 1] + kcols[i - 1]
    }
    adf = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        if (kcols[i] < 1) {
            continue
        }
        p1 = off[i] + 1
        p2 = off[i] + kcols[i]
        Xi = W[|1, p1 \ T, p2|]
        iXX = invsym(quadcross(Xi, Xi))
        bi = iXX * quadcross(Xi, ys[., i])
        ei = ys[., i] - Xi * bi
        if (T - kcols[i] <= 0) {
            continue
        }
        s2 = quadcross(ei, ei) / (T - kcols[i])
        if (s2 * iXX[1, 1] > 0) {
            adf[i] = bi[1] / sqrt(s2 * iXX[1, 1])
        }
    }
    return(adf)
}

// ------------------------------------------------------------------
// S10  AVECOR: mean residual correlation of series i with the rest
// ------------------------------------------------------------------
real matrix _sa_corrmat(real matrix Sig)
{
    real colvector s

    s = sqrt(diagonal(Sig))
    return(Sig :/ (s * s'))
}

// ------------------------------------------------------------------
// S5-S9  simulate the null distribution.
// D is kmax x N holding the own-lag coefficients (zero beyond k_i),
// so the recursion can never pick up a cross-equation term -- the
// error that broke the original RATS implementation.
// ------------------------------------------------------------------
real matrix _sa_sim(real matrix D, real matrix Sig0, real scalar Tlev,
                    real scalar burn, real scalar reps, real colvector kk,
                    real scalar trend, real scalar dfk, real scalar maxit,
                    real scalar distb, real matrix E0, real scalar dots)
{
    real scalar N, kmax, Tgen, r, t, j, every, nE, ok
    real colvector eqid, kcols, bb, idx, tvv
    real matrix S, U, DY, YL, Ysim, W, ys, V, Sig, E, out, acc

    N = cols(Sig0)
    kmax = rows(D)
    Tgen = burn + Tlev
    out = J(reps, N, .)

    // these are filled by reference inside _sa_design and _sa_surfit;
    // declare them up front so Mata does not warn about use before set
    eqid = J(0, 1, 0)
    bb   = J(0, 1, 0)
    ys   = J(0, 0, 0)
    V    = J(0, 0, 0)
    Sig  = J(0, 0, 0)
    E    = J(0, 0, 0)

    S = cholesky(Sig0)
    if (hasmissing(S)) {
        return(J(0, 0, .))
    }

    kcols = J(N, 1, 0)
    for (j = 1; j <= N; j++) {
        kcols[j] = 2 + trend + kk[j]
    }

    nE = rows(E0)
    every = ceil(reps / 50)
    if (every < 1) {
        every = 1
    }

    for (r = 1; r <= reps; r++) {
        // ---- S5 innovations ----
        if (distb == 1) {
            idx = ceil(runiform(Tgen, 1) :* nE)
            for (j = 1; j <= Tgen; j++) {
                if (idx[j] < 1) {
                    idx[j] = 1
                }
            }
            U = E0[idx, .]
        } else {
            U = rnormal(Tgen, N, 0, 1) * S'
        }

        // ---- S6 driftless unit-root recursion, own lags only ----
        DY = J(Tgen, N, 0)
        for (t = 1; t <= Tgen; t++) {
            acc = U[t, .]
            for (j = 1; j <= kmax; j++) {
                if (t - j >= 1) {
                    acc = acc + D[j, .] :* DY[t - j, .]
                }
            }
            DY[t, .] = acc
        }
        YL = J(Tgen, N, 0)
        YL[1, .] = DY[1, .]
        for (t = 2; t <= Tgen; t++) {
            YL[t, .] = YL[t - 1, .] + DY[t, .]
        }

        // ---- S7 discard the burn-in ----
        Ysim = YL[|burn + 1, 1 \ Tgen, N|]

        // ---- S8 re-estimate the FULL model, intercept included ----
        W = _sa_design(Ysim, kk, trend, ys, eqid)
        ok = _sa_surfit(ys, W, eqid, kcols, dfk, maxit, bb, V, Sig, E)
        if (ok == 1) {
            tvv = _sa_tvec(bb, V, kcols)
            out[r, .] = tvv'
        }

        if (dots == 1) {
            if (mod(r, every) == 0) {
                printf(".")
                displayflush()
            }
        }
    }
    return(out)
}

// ------------------------------------------------------------------
// long panel -> T x N wide matrix of levels (already checked balanced)
// ------------------------------------------------------------------
real matrix _sa_long2wide(string scalar var, string scalar ivar,
                          string scalar tvar, string scalar touse)
{
    real colvector v, id, tt, p
    real scalar N, T
    real matrix M

    v  = st_data(., var,  touse)
    id = st_data(., ivar, touse)
    tt = st_data(., tvar, touse)

    p  = order((id, tt), (1, 2))
    v  = v[p]
    id = id[p]

    N = rows(uniqrows(id))
    T = rows(v) / N
    M = colshape(v', T)
    return(M')
}

// ==================================================================
// driver
// ==================================================================
void _suradf_main(string scalar vars, string scalar ivar, string scalar tvar,
                  string scalar touse, real scalar islong, real scalar lmode,
                  string scalar kmatname, real scalar maxlags, real scalar reps,
                  real scalar burn, real scalar trend, real scalar dfk,
                  real scalar maxit, real scalar distb, real scalar dots)
{
    real scalar N, T, Teff, kmax, i, j, ok, nI0, nI1
    real colvector kk, kcols, kcols0, eqid, eqid0, bb, bb0, tt, adf, off0
    real matrix Y, dy, W, W0, ys, ys0, V, V0, Sig, Sig0, E, E0, R, D
    real matrix TAB, CC, SIMS

    // filled by reference inside _sa_design, _sa_design0 and _sa_surfit;
    // set here so Mata does not warn about use before set
    eqid = J(0, 1, 0)
    eqid0 = J(0, 1, 0)
    bb = J(0, 1, 0)
    bb0 = J(0, 1, 0)
    ys = J(0, 0, 0)
    ys0 = J(0, 0, 0)
    V = J(0, 0, 0)
    V0 = J(0, 0, 0)
    Sig = J(0, 0, 0)
    Sig0 = J(0, 0, 0)
    E = J(0, 0, 0)
    E0 = J(0, 0, 0)

    st_numscalar("__sa_fail", 0)

    // ---- read the data ----
    if (islong == 1) {
        Y = _sa_long2wide(vars, ivar, tvar, touse)
    } else {
        Y = st_data(., tokens(vars), touse)
    }
    T = rows(Y)
    N = cols(Y)

    // ---- S2 lag orders ----
    kk = J(N, 1, 0)
    if (lmode == 0) {
        kk = st_matrix(kmatname)
        if (cols(kk) > 1) {
            kk = kk'
        }
    } else {
        dy = Y[|2, 1 \ T, N|] - Y[|1, 1 \ T - 1, N|]
        for (i = 1; i <= N; i++) {
            if (lmode == 1) {
                kk[i] = _sa_lagsel_bmw(dy[., i], maxlags)
            } else if (lmode == 2) {
                kk[i] = _sa_lagsel_ic(Y[., i], maxlags, 0, trend)
            } else {
                kk[i] = _sa_lagsel_ic(Y[., i], maxlags, 1, trend)
            }
        }
    }
    kmax = max(kk)
    Teff = T - kmax - 1

    kcols = J(N, 1, 0)
    for (i = 1; i <= N; i++) {
        kcols[i] = 2 + trend + kk[i]
    }

    // ---- S3 observed SURADF statistics ----
    W = _sa_design(Y, kk, trend, ys, eqid)
    ok = _sa_surfit(ys, W, eqid, kcols, dfk, maxit, bb, V, Sig, E)
    if (ok == 0) {
        st_numscalar("__sa_fail", 1)
        return
    }
    tt  = _sa_tvec(bb, V, kcols)
    adf = _sa_adfvec(ys, W, kcols)

    // ---- S4 restricted null model ----
    W0 = _sa_design0(Y, kk, ys0, eqid0)
    kcols0 = kk
    ok = _sa_surfit(ys0, W0, eqid0, kcols0, dfk, maxit, bb0, V0, Sig0, E0)
    if (ok == 0) {
        st_numscalar("__sa_fail", 1)
        return
    }

    // own-lag coefficient matrix, zero beyond k_i
    D = J(kmax, N, 0)
    off0 = J(N, 1, 0)
    for (i = 2; i <= N; i++) {
        off0[i] = off0[i - 1] + kk[i - 1]
    }
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= kk[i]; j++) {
            D[j, i] = bb0[off0[i] + j]
        }
    }

    // ---- S10 AVECOR from the null-model covariance ----
    CC = _sa_corrmat(Sig0)

    // ---- S5-S9 simulate ----
    TAB = J(N, 8, .)
    for (i = 1; i <= N; i++) {
        TAB[i, 1] = kk[i]
        TAB[i, 2] = (rowsum(CC[i, .]) - 1) / (N - 1)
        TAB[i, 3] = adf[i]
        TAB[i, 4] = tt[i]
    }

    if (reps > 0) {
        SIMS = _sa_sim(D, Sig0, T, burn, reps, kk, trend, dfk, maxit,
                       distb, E0, dots)
        if (rows(SIMS) < 1) {
            st_numscalar("__sa_fail", 1)
            return
        }
        for (i = 1; i <= N; i++) {
            R = select(SIMS[., i], SIMS[., i] :< .)
            if (rows(R) > 10) {
                TAB[i, 5] = _sa_quantile(R, 0.01)
                TAB[i, 6] = _sa_quantile(R, 0.05)
                TAB[i, 7] = _sa_quantile(R, 0.10)
                TAB[i, 8] = sum(R :< tt[i]) / rows(R)
            }
        }
        st_matrix("__sa_sim", SIMS)
    }

    // A number always compares <= missing, so an unsimulated critical value
    // would otherwise be read as a rejection.  Count only decided series.
    nI0 = 0
    nI1 = 0
    for (i = 1; i <= N; i++) {
        if (TAB[i, 6] < .) {
            if (TAB[i, 4] <= TAB[i, 6]) {
                nI0 = nI0 + 1
            } else {
                nI1 = nI1 + 1
            }
        }
    }

    st_matrix("__sa_tab", TAB)
    st_matrix("__sa_corr", CC)
    st_numscalar("__sa_T", T)
    st_numscalar("__sa_N", N)
    st_numscalar("__sa_Teff", Teff)
    st_numscalar("__sa_kmax", kmax)
    st_numscalar("__sa_nI0", nI0)
    st_numscalar("__sa_nI1", nI1)
    st_numscalar("__sa_avecor", (sum(CC) - N) / (N * N - N))
}

end
