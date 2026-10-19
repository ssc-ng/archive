*! lassour 1.0.0  17oct2026
*! Adaptive Lasso activation-knot unit root tests with sieve wild bootstrap
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements the tau and tauIE activation-knot unit root tests of
*! Arnold & Reinschluessel (2024) and their sieve wild bootstrap analogues
*! of Arnold & Reinschluessel (2026, arXiv:2409.07859v2).
*!
*! Step -> equation map (full map in: help lassour methods)
*!   FD detrending                      Schmidt & Phillips (1992); AR24 Tab. D1
*!   ADF(p) regression, zero-padded     [T] eq. (3), Alg. 1 step 2
*!   adaptive Lasso objective           [T] eq. (4), penalty 2*lambda
*!   adaptive weights w1, w2j           [T] sec. 2.2
*!   enriched weight wbreve1 = J/|rho|  AR24 main text (see help methods)
*!   activation knot lambda_0           AR24 Definition 1
*!   tau = lambda_0 / sigma2hat         [T] eq. (8); AR24 eq. (22)
*!   J_alpha range statistic            AR24 Algorithm 1; Herwartz-Siedenburg
*!   RSMAIC lag selection               Cavaliere, Phillips, Smeekes & Taylor
*!   sieve wild bootstrap               [T] Algorithm 1
*!
*! The Mata engine ships as the compiled library llassour.mlib; the source
*! and its build script are in lassour_mata.do.

program define lassour, rclass
    version 14.0

    * ---- The Mata engine lives in the compiled library llassour.mlib, not
    * ---- inside this file.  That matters: some packages (bootur among them)
    * ---- issue "mata clear", which would drop embedded functions while
    * ---- leaving this program in memory and break the next call.  Functions
    * ---- resolved from a .mlib on the adopath are re-found automatically.
    * ---- All we check here is that the library is actually installed.
    capture findfile llassour.mlib
    if (_rc) {
        di as error "the Mata library {bf:llassour.mlib} is not on the adopath"
        di as error "reinstall lassour, or rebuild it with {bf:do lassour_mata.do}"
        exit 601
    }

    gettoken sub rest : 0, parse(" ,")

    if ("`sub'" == "cv") {
        lassour_cv `rest'
        return add
        exit
    }

    _lassour_test `0'
    return add
end


* =====================================================================
* lassour cv -- published critical values
* =====================================================================
program define lassour_cv, rclass
    version 14.0
    syntax [, Deterministics(string) ]

    if ("`deterministics'" == "") local deterministics "constant"
    local det = 1
    if (substr("`deterministics'", 1, 1) == "n") local det = 0
    if (substr("`deterministics'", 1, 1) == "c") local det = 1
    if (substr("`deterministics'", 1, 1) == "t") local det = 2

    local dlab "constant (FD)"
    if (`det' == 0) local dlab "none"
    if (`det' == 2) local dlab "linear trend (FD)"

    di ""
    di as text "Simulated critical values, adaptive Lasso activation knot tests"
    di as text "Deterministics: " as result "`dlab'"
    di as text "{hline 69}"
    di as text _col(10) "{c |}" _col(22) "tau" _col(52) "tauIE"
    di as text %8s "T" _col(10) "{c |}" ///
        _col(14) %9s "1%" _col(24) %9s "5%" _col(34) %9s "10%" ///
        _col(44) %9s "1%" _col(54) %9s "5%" _col(64) %9s "10%"
    di as text "{hline 9}{c +}{hline 59}"

    tempname CV
    mata: lsr_cvtable(`det', "`CV'")

    di as text "{hline 69}"
    if (`det' == 0) {
        di as text "Source: Arnold & Reinschluessel (2024), Table 1 (d_t = 0, p = 0,"
    }
    else {
        di as text "Source: Arnold & Reinschluessel (2024), Table D1 (FD adjusted, p = 0,"
    }
    di as text "        Gaussian random walks, 5e5 replications)."
    di as text "tauIE uses J with alpha = .1, R = 150. lassour interpolates linearly"
    di as text "in T between the tabulated sample sizes."
    di ""

    return local det "`deterministics'"
    return matrix cv = `CV'
end


* =====================================================================
* Main test
* =====================================================================
program define _lassour_test, rclass
    version 14.0

    syntax varname(numeric ts) [if] [in] [,          ///
        Deterministics(string)                        ///
        LAGs(integer -1)                              ///
        MAXlag(integer -1)                            ///
        MINlag(integer 0)                             ///
        CRITerion(string)                             ///
        ICDet(string)                                 ///
        SIEVElags(integer -1)                         ///
        Test(string)                                  ///
        NOBOOTstrap                                   ///
        Reps(integer 499)                             ///
        SEED(string)                                  ///
        ALpha(real 0.1)                               ///
        JReps(integer 150)                            ///
        LRVlags(integer -1)                           ///
        BANDwidth(real 0.1)                           ///
        Level(cilevel)                                ///
        GRAPH                                         ///
        GRAPHOpts(string asis)                        ///
        Name(string)                                  ///
        NOTABle                                       ///
        NODOTs                                        ]

    * ---------- resolve time-series operators ----------
    tsrevar `varlist'
    local yv "`r(varlist)'"
    local yname "`varlist'"

    * ---------- time series setup ----------
    capture qui tsset
    if (_rc) {
        di as error "data must be {bf:tsset} before using lassour"
        exit 459
    }
    local tvar "`r(timevar)'"
    if ("`tvar'" == "") {
        di as error "data must be {bf:tsset} with a time variable"
        exit 459
    }

    marksample touse
    markout `touse' `yv'
    qui count if `touse'
    local nobs = r(N)
    if (`nobs' < 20) {
        di as error "too few observations (`nobs'); lassour needs at least 20"
        exit 2001
    }

    * ---------- no internal gaps ----------
    qui summ `tvar' if `touse', meanonly
    local t1 = r(min)
    local t2 = r(max)
    if (`nobs' != `t2' - `t1' + 1) {
        di as error "the sample has internal gaps; lassour requires a contiguous series"
        exit 198
    }

    * ---------- deterministics ----------
    if ("`deterministics'" == "") local deterministics "constant"
    local dok = 0
    local det = 1
    if (substr("`deterministics'", 1, 1) == "n") {
        local det = 0
        local dok = 1
    }
    if (substr("`deterministics'", 1, 1) == "c") {
        local det = 1
        local dok = 1
    }
    if (substr("`deterministics'", 1, 1) == "t") {
        local det = 2
        local dok = 1
    }
    if (`dok' == 0) {
        di as error "deterministics() must be none, constant or trend"
        exit 198
    }

    * ---------- criterion ----------
    if ("`criterion'" == "") local criterion "rsmaic"
    local criterion = lower("`criterion'")
    local icode = 0
    if ("`criterion'" == "rsmaic") local icode = 3
    if ("`criterion'" == "rsmbic") local icode = 4
    if ("`criterion'" == "maic")   local icode = 13
    if ("`criterion'" == "mbic")   local icode = 14
    if ("`criterion'" == "aic")    local icode = 11
    if ("`criterion'" == "bic")    local icode = 12
    if (`icode' == 0) {
        di as error "criterion() must be rsmaic, rsmbic, maic, mbic, aic or bic"
        exit 198
    }

    * ---------- information-criterion input transform ----------
    if ("`icdet'" == "") local icdet "ols"
    local icdet = lower("`icdet'")
    local icd = -1
    if (substr("`icdet'", 1, 1) == "f") local icd = 0
    if (substr("`icdet'", 1, 1) == "o") local icd = 1
    if (`icd' == -1) {
        di as error "icdetrend() must be fd or ols"
        exit 198
    }

    * ---------- which statistics ----------
    if ("`test'" == "") local test "both"
    local test = lower("`test'")
    if (!inlist("`test'", "tau", "tauie", "both")) {
        di as error "test() must be tau, tauie or both"
        exit 198
    }
    local dotau = 1
    local doie  = 1
    if ("`test'" == "tau")   local doie  = 0
    if ("`test'" == "tauie") local dotau = 0

    * ---------- bootstrap or asymptotic ----------
    local boot = 1
    if ("`nobootstrap'" != "") local boot = 0
    if (`boot' == 1 & `reps' < 99) {
        di as error "reps() must be at least 99"
        exit 198
    }

    * ---------- lag bounds ----------
    if (`maxlag' == -1) local maxlag = floor(12 * (`nobs' / 100) ^ 0.25)
    if (`maxlag' >= floor(`nobs' / 3)) local maxlag = floor(`nobs' / 3) - 1
    if (`maxlag' < 0)  local maxlag = 0
    if (`minlag' < 0)  local minlag = 0
    if (`minlag' > `maxlag') local minlag = `maxlag'

    if (`alpha' <= 0 | `alpha' >= 0.5) {
        di as error "alpha() must lie strictly between 0 and .5"
        exit 198
    }
    if (`jreps' < 20) {
        di as error "jreps() must be at least 20"
        exit 198
    }
    if (`bandwidth' <= 0) {
        di as error "bandwidth() must be positive"
        exit 198
    }

    if (`lags' >= 0) local criterion "user-specified"

    if ("`seed'" != "") set seed `seed'

    local dots = 1
    if ("`nodots'" != "" | `boot' == 0) local dots = 0

    * ---------- engine ----------
    tempname RES BOOT PATH VOL
    mata: lsr_main("`yv'", "`touse'", `det', `lags', `minlag', `maxlag',  ///
                   `icode', `sievelags', `dotau', `doie', `boot', `reps', ///
                   `alpha', `jreps', `lrvlags', `bandwidth', `level',     ///
                   `dots', `icd', "`RES'", "`BOOT'", "`PATH'", "`VOL'")

    * ---------- unpack ----------
    local tau      = `RES'[1, 1]
    local tauie    = `RES'[1, 2]
    local rho      = `RES'[1, 3]
    local sigma2   = `RES'[1, 4]
    local Jstat    = `RES'[1, 5]
    local p        = `RES'[1, 6]
    local q        = `RES'[1, 7]
    local tau_cv   = `RES'[1, 8]
    local tauie_cv = `RES'[1, 9]
    local tau_p    = `RES'[1, 10]
    local tauie_p  = `RES'[1, 11]
    local nadf     = `RES'[1, 12]
    local kl       = `RES'[1, 13]
    local lam      = `RES'[1, 14]
    local lamie    = `RES'[1, 15]

    * ---------- table ----------
    if ("`notable'" == "") {
        _lassour_table , tau(`tau') tauie(`tauie') tcv(`tau_cv')       ///
            icv(`tauie_cv') tp(`tau_p') ip(`tauie_p') dotau(`dotau')   ///
            doie(`doie') boot(`boot') level(`level') reps(`reps')      ///
            p(`p') q(`q') nadf(`nadf') rho(`rho') sigma2(`sigma2')     ///
            jstat(`Jstat') kl(`kl') yname(`yname') det(`det')          ///
            crit(`criterion') alpha(`alpha') jreps(`jreps')
    }

    * ---------- graphs: BEFORE any return matrix move (gotcha: ,copy) ----
    if ("`graph'" != "") {
        * pass gopts() only when non-empty: an empty `string asis' option
        * arrives as unbalanced compound quotes and breaks graph combine
        local gpass ""
        if (`"`graphopts'"' != "") local gpass `"gopts(`graphopts')"'
        _lassour_graph , boot(`boot') tau(`tau') tauie(`tauie')         ///
            tcv(`tau_cv') icv(`tauie_cv') dotau(`dotau') doie(`doie')   ///
            level(`level') yv(`yv') yname(`yname') tvar(`tvar')         ///
            touse(`touse') det(`det') bmat(`BOOT') pmat(`PATH')         ///
            vmat(`VOL') lam(`lam') lamie(`lamie')                       ///
            name(`name') `gpass'
    }

    * ---------- returns ----------
    return local cmd       "lassour"
    return local depvar    "`yname'"
    return local det       "`deterministics'"
    return local criterion "`criterion'"
    return local icdetrend "`icdet'"
    if (`boot' == 1) return local method "sieve wild bootstrap"
    if (`boot' == 0) return local method "asymptotic (published critical values)"

    return scalar level   = `level'
    return scalar N       = `nobs'
    return scalar N_adf   = `nadf'
    return scalar p       = `p'
    return scalar q       = `q'
    return scalar lrvlags = `kl'
    return scalar rho     = `rho'
    return scalar sigma2  = `sigma2'
    if (`doie' == 1) return scalar J = `Jstat'
    if (`boot' == 1) return scalar reps = `reps'

    if (`dotau' == 1) {
        return scalar lambda = `lam'
        return scalar tau    = `tau'
        return scalar tau_cv = `tau_cv'
        if (`boot' == 1) return scalar tau_p = `tau_p'
    }
    if (`doie' == 1) {
        return scalar lambda_ie = `lamie'
        return scalar tauie     = `tauie'
        return scalar tauie_cv  = `tauie_cv'
        if (`boot' == 1) return scalar tauie_p = `tauie_p'
    }

    capture confirm matrix `BOOT'
    if (!_rc & `boot' == 1) return matrix bootdist = `BOOT', copy
    capture confirm matrix `PATH'
    if (!_rc) return matrix path = `PATH', copy
end


* =====================================================================
* Journal-style results table
* =====================================================================
program define _lassour_table
    version 14.0
    syntax , tau(string) tauie(string) tcv(string) icv(string)        ///
             tp(string) ip(string) dotau(integer) doie(integer)       ///
             boot(integer) level(real) reps(integer) p(integer)       ///
             q(integer) nadf(integer) rho(string) sigma2(string)      ///
             jstat(string) kl(integer) yname(string) det(integer)     ///
             crit(string) alpha(real) jreps(integer)

    local dlab "constant (FD, Schmidt-Phillips)"
    if (`det' == 0) local dlab "none"
    if (`det' == 2) local dlab "linear trend (FD, Schmidt-Phillips)"

    local a = 100 - `level'
    local al : di %3.0f `a'
    local al = trim("`al'")

    di ""
    di as text "Adaptive Lasso activation knot unit root test"
    if (`boot' == 1) {
        di as text "Sieve wild bootstrap" as text "   (Arnold & Reinschluessel 2026)"
    }
    else {
        di as text "Asymptotic critical values" as text "   (Arnold & Reinschluessel 2024)"
    }
    di as text "{hline 73}"
    di as text "Series" _col(28) "{c |}  " as result abbrev("`yname'", 24)
    di as text "Deterministics" _col(28) "{c |}  " as result "`dlab'"
    di as text "ADF observations" _col(28) "{c |}  " as result `nadf'
    di as text "ADF lag order p" _col(28) "{c |}  " as result `p' ///
        as text "   (selected by `crit')"
    if (`boot' == 1) {
        di as text "Sieve lag order q" _col(28) "{c |}  " as result `q'
        di as text "Bootstrap replications B" _col(28) "{c |}  " as result `reps'
    }
    di as text "{hline 73}"
    di as text "H0: unit root (rho* = 0)" _col(38) "H1: stationary (rho* < 0)"
    di as text "{hline 73}"
    if (`boot' == 1) {
        di as text %-10s "Statistic" _col(13) %12s "value" ///
            _col(27) %12s "boot. c.v." _col(41) %10s "p-value" _col(56) "decision"
    }
    else {
        di as text %-10s "Statistic" _col(13) %12s "value" ///
            _col(27) %12s "crit. value" _col(41) %10s " " _col(56) "decision"
    }
    di as text "{hline 73}"

    if (`dotau' == 1) {
        _lassour_row tau `tau' `tcv' `tp' `boot'
    }
    if (`doie' == 1) {
        _lassour_row tauIE `tauie' `icv' `ip' `boot'
    }

    di as text "{hline 73}"
    di as text "Auxiliary quantities"
    di as text "  rho-hat   (OLS, penalty-weight regression)" _col(48) "= " ///
        as result %12.6f `rho'
    di as text "  sigma2-hat (AR24 eq. 22)" _col(48) "= " as result %12.6f `sigma2'
    if (`doie' == 1) {
        di as text "  J(alpha=" as result %3.2f `alpha' as text ", R=" ///
            as result `jreps' as text ")" _col(48) "= " as result %12.6f `jstat'
        di as text "  LRV lag k (Algorithm 1, step 1)" _col(48) "= " ///
            as result %12.0f `kl'
    }
    di as text "{hline 73}"
    di as text "Right-sided test: a rejection of H0 is evidence of stationarity."
    if (`boot' == 1) {
        di as text "Significance: * p<.10, ** p<.05, *** p<.01." ///
            " Bootstrap c.v. at the `al'% level."
        di as text "Sieve wild bootstrap with Gaussian multipliers; penalty weights"
        di as text "and lag order are re-estimated in every replication."
    }
    else {
        di as text "Critical value at the `al'% level, interpolated in T from the"
        di as text "published tables. Prefer the bootstrap (the default) under serial"
        di as text "correlation or non-stationary volatility."
    }
    di ""
end

program define _lassour_row
    version 14.0
    args lab stat cv pv boot

    local dec "do not reject"
    if (`stat' > `cv') local dec "reject H0"

    if (`boot' == 1) {
        local st "   "
        if (`pv' <= 0.10) local st "*  "
        if (`pv' <= 0.05) local st "** "
        if (`pv' <= 0.01) local st "***"
        di as text %-10s "`lab'" as result _col(13) %12.4f `stat' ///
            _col(27) %12.4f `cv' _col(41) %10.4f `pv' ///
            as text _col(52) "`st'" _col(56) "`dec'"
    }
    else {
        di as text %-10s "`lab'" as result _col(13) %12.4f `stat' ///
            _col(27) %12.4f `cv' _col(41) %10s " " ///
            as text _col(56) "`dec'"
    }
end


* =====================================================================
* Journal-style graphs
* =====================================================================
program define _lassour_graph
    version 14.0
    syntax , boot(integer) tau(string) tauie(string) tcv(string)      ///
             icv(string) dotau(integer) doie(integer) level(real)     ///
             yv(string) yname(string) tvar(string) touse(string)      ///
             det(integer) bmat(string) pmat(string) vmat(string)      ///
             [ lam(string) lamie(string) name(string)                 ///
               gopts(string asis) ]

    if ("`name'" == "") local name "lassour"
    local alev : di %3.0f 100 - `level'
    local pan ""

    * ---------- Panel A: series and deterministic adjustment ----------
    tempvar fdser
    qui gen double `fdser' = .
    capture mata: lsr_putfd("`yv'", "`touse'", `det', "`fdser'")

    local dlab "FD-detrended (constant)"
    if (`det' == 0) local dlab "no adjustment"
    if (`det' == 2) local dlab "FD-detrended (trend)"

    capture twoway                                                          ///
        (line `yv' `tvar' if `touse', lcolor(navy) lwidth(medthin))          ///
        (line `fdser' `tvar' if `touse', lcolor(cranberry)                   ///
            lpattern(dash) lwidth(medthin))                                  ///
        , legend(order(1 "`yname'" 2 "`dlab'") rows(1) size(vsmall)           ///
            region(lstyle(none)) position(6) ring(0) bmargin(zero))           ///
          ytitle("") xtitle("`tvar'", size(small))                            ///
          title("{bf:A}  Series and deterministic adjustment", size(medsmall)) ///
          graphregion(color(white)) plotregion(style(none))                    ///
          name(`name'_series, replace) nodraw
    if (!_rc) local pan "`pan' `name'_series"

    * ---------- Panel B: adaptive Lasso solution path ----------
    capture confirm matrix `pmat'
    if (!_rc) {
        local pr = rowsof(`pmat')
        local pc = colsof(`pmat')
        if (`pr' > 1) {
            preserve
            qui {
                clear
                svmat double `pmat', name(pc)
                local lines ""
                if (`pc' > 2) {
                    forvalues j = 3 / `pc' {
                        local lines "`lines' (line pc`j' pc1, lcolor(gs11) lwidth(vthin))"
                    }
                }
                local kline ""
                if ("`lam'" != "" & "`lam'" != ".") {
                    local kline "xline(`lam', lcolor(cranberry) lpattern(dash) lwidth(medthin))"
                }
                capture twoway `lines'                                        ///
                    (line pc2 pc1, lcolor(navy) lwidth(medthick))             ///
                    , xscale(reverse) `kline'                                 ///
                      xtitle("penalty {&lambda}", size(small))                ///
                      ytitle("coefficient", size(small))                      ///
                      title("{bf:B}  Adaptive Lasso solution path",           ///
                          size(medsmall))                                     ///
                      subtitle("navy: y{subscript:t-1};  red dash: activation knot {&lambda}{subscript:0}", ///
                          size(vsmall))                                       ///
                      legend(off) yline(0, lcolor(gs9) lpattern(dot))         ///
                      graphregion(color(white)) plotregion(style(none))       ///
                      name(`name'_path, replace) nodraw
                local prc = _rc
            }
            restore
            if (`prc' == 0) local pan "`pan' `name'_path"
        }
    }

    * ---------- Panel C: bootstrap null distribution ----------
    if (`boot' == 1) {
        capture confirm matrix `bmat'
        if (!_rc) {
            local which = 1
            local lab "{&tau}"
            local obs = `tau'
            local cvv = `tcv'
            if (`dotau' == 0) {
                local which = 2
                local lab "{&tau}{superscript:IE}"
                local obs = `tauie'
                local cvv = `icv'
            }
            preserve
            qui {
                clear
                svmat double `bmat', name(bs)
                capture confirm variable bs`which'
                local crc = _rc
                if (`crc' == 0) {
                    capture kdensity bs`which', nograph generate(bkx bky)
                    local crc = _rc
                }
                if (`crc' == 0) {
                    * a decisive rejection puts the observed statistic far
                    * outside the bootstrap range, where an xline would be
                    * clipped; say so numerically instead of promising a line
                    * the reader cannot see.
                    summarize bkx, meanonly
                    local bmax = r(max)
                    local obss : di %9.4g `obs'
                    local obss = trim("`obss'")
                    local cvs  : di %9.4g `cvv'
                    local cvs  = trim("`cvs'")
                    local oline "xline(`obs', lcolor(cranberry) lwidth(medthick))"
                    local sub "red: observed `lab' = `obss';  green dash: `alev'% c.v. = `cvs'"
                    if (`obs' > `bmax') {
                        local oline ""
                        local sub "observed `lab' = `obss' lies beyond the axis;  green dash: `alev'% c.v. = `cvs'"
                    }
                    capture twoway                                             ///
                        (area bky bkx, color(navy*0.25) lcolor(navy)           ///
                            lwidth(thin))                                      ///
                        , `oline'                                              ///
                          xline(`cvv', lcolor(forest_green) lpattern(dash))    ///
                          xtitle("bootstrap `lab'", size(small))               ///
                          ytitle("density", size(small))                       ///
                          title("{bf:C}  Bootstrap null distribution",         ///
                              size(medsmall))                                  ///
                          subtitle("`sub'", size(vsmall))                      ///
                          legend(off) graphregion(color(white))                ///
                          plotregion(style(none))                              ///
                          name(`name'_boot, replace) nodraw
                    local crc = _rc
                }
            }
            restore
            if (`crc' == 0) local pan "`pan' `name'_boot"
        }
    }

    * ---------- Panel D: estimated volatility profile ----------
    capture confirm matrix `vmat'
    if (!_rc) {
        preserve
        qui {
            clear
            svmat double `vmat', name(vv)
            capture twoway (line vv2 vv1, lcolor(dkorange) lwidth(medthick))  ///
                , xtitle("t/T", size(small))                                  ///
                  ytitle("{&sigma}(t/T)", size(small))                        ///
                  title("{bf:D}  Estimated volatility profile", size(medsmall)) ///
                  subtitle("Nadaraya-Watson, Gaussian kernel", size(vsmall))   ///
                  legend(off) graphregion(color(white))                        ///
                  plotregion(style(none))                                      ///
                  name(`name'_vol, replace) nodraw
            local vrc = _rc
        }
        restore
        if (`vrc' == 0) local pan "`pan' `name'_vol"
    }

    * ---------- combine ----------
    local nn : word count `pan'
    if (`nn' > 0) {
        capture graph combine `pan'                                        ///
            , graphregion(color(white)) cols(2) imargin(small)             ///
              title("Adaptive Lasso activation knot test: `yname'",        ///
                  size(medsmall))                                           ///
              name(`name', replace) `gopts'
        if (!_rc) {
            * graph display fails in batch / headless sessions; the combined
            * graph still exists under `name' and can be exported.
            capture graph display `name'
        }
        else {
            di as text "note: graph combine failed; panels are named" ///
                as result " `pan'"
        }
    }
end


