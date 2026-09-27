*! cointvol_resid 0.2.0  26sep2026
*! Single-equation residual-based tests of no cointegration under GARCH errors
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_resid.sthlp, section Methods):
*!   OLS y = d(t)'delta + x'b + u ; ADF t on u (eg)     -> Engle & Granger (1987); FKM (1994) eqs (5)-(6)
*!   T(a-1), CRDW, tau-White (White HC0 DF t)          -> Lee & Tse (1996) sec. 2, Tables 1-6
*!   TAR/MTAR F (rho1 = rho2 = 0), tau = 0 or Chan     -> Enders & Siklos (2001) eqs (6)-(7), (10)-(11);
*!                                                        CVs: E-S (WP) Tables 1-2
*!   KSS t_NLEG (residual t on u^3), t_NLECM           -> Kapetanios, Shin & Snell (2006; WP 497)
*!                                                        eqs (3.1)-(3.6), (3.13)-(3.16); Table 1
*!   GH ADF*, Zt*, Za* (models C, C/T, C/S)            -> Gregory & Hansen (1996) eqs (2.2)-(3.3); Table 1
*!   HJ ADF*, Zt*, Za* (two regime shifts)             -> Hatemi-J (2008) eqs (2)-(9); Table 1
*!   Breitung Lambda_q, q = m+1 (H0 r = 0)             -> Breitung (2002) eq (12); Table A.2
*!   cv(auto): published table where tabulated, else simulated
*!   cv(sim): finite-sample null CVs, iid or GARCH(1,1) -> Lee & Tse (1996) sec. 2 (burn-in 500);
*!            random-walk DGP, re-run of lag/grid search    Maki (2013) sec. 3
*!   cv(fkm): 5% CV of eg, Table 1 / eq (7) / eq (8)    -> Franses, Kofman & Moser (1994)
*!   bootstrap(wild): EXTENDED implementation (null-imposed wild bootstrap of dy,
*!            re-projection on the original regressors, full re-search)

program define cointvol_resid, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in] [, TESTs(string) LAGs(string)   ///
        MAXLags(integer -1) TRIM(real 0.15) TRend(string) CV(string)           ///
        GARCH(numlist min=2 max=2 >=0) SIMReps(integer -1) BOOTstrap(string)   ///
        Reps(integer 499) SEED(string) MULTiplier(string) Level(cilevel) NODOTS ///
        THReshold(string) SHIFT(string) ]

    // ---------------- load / reload the Mata engine ----------------------
    local __cvever ""
    capture mata: st_local("__cvever", cve_version())
    if _rc | "`__cvever'" != "0.2.0" {
        capture program drop cointvol_eng_resid
        quietly findfile cointvol_eng_resid.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- options --------------------------------------------
    local canon "eg ta1 crdw hc0 tar mtar kss gh hj vr kssecm ghzt ghza hjzt hjza"
    local brk   "gh hj ghzt ghza hjzt hjza"
    local hjset "hj hjzt hjza"
    local tests = strlower(strtrim(`"`tests'"'))
    if `"`tests'"' == "" local tests "eg ta1 crdw hc0"
    if `"`tests'"' == "all" local tests "`canon'"
    local tests : list uniq tests
    local bad : list tests - canon
    if `"`bad'"' != "" {
        di as err "test(): unknown test(s) `bad'; valid are `canon' (or all)"
        exit 198
    }

    local cv = strlower(strtrim(`"`cv'"'))
    if `"`cv'"' == "" local cv "auto"
    local okcv "auto table sim fkm none"
    local bad : list cv - okcv
    if `"`bad'"' != "" {
        di as err "cv() must contain auto, table, sim, fkm or none"
        exit 198
    }
    local hasauto : list posof "auto" in cv
    local hastab  : list posof "table" in cv
    local hassim  : list posof "sim" in cv
    local dofkm   : list posof "fkm" in cv
    local hasauto = (`hasauto' > 0)
    local hastab  = (`hastab' > 0)
    local hassim  = (`hassim' > 0)
    local dofkm   = (`dofkm' > 0)
    if `dofkm' {
        local haseg : list posof "eg" in tests
        if `haseg' == 0 {
            local tests "eg `tests'"
            di as txt "(note: cv(fkm) refers to the Engle-Granger test; eg added to test())"
        }
    }

    local wflags ""
    local tlist ""
    foreach t of local canon {
        local on : list t in tests
        local wflags "`wflags' `on'"
        if `on' local tlist "`tlist' `t'"
    }
    local tlist = strtrim("`tlist'")
    local hasgrid 0
    foreach t of local brk {
        local k : list posof "`t'" in tlist
        if `k' > 0 local hasgrid 1
    }
    local hashj 0
    foreach t of local hjset {
        local k : list posof "`t'" in tlist
        if `k' > 0 local hashj 1
    }
    local haslin 0
    foreach t in eg ta1 crdw hc0 tar mtar kss vr kssecm {
        local k : list posof "`t'" in tlist
        if `k' > 0 local haslin 1
    }

    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "constant"
    if inlist(`"`trend'"', "n", "no", "non", "none") local trend "none"
    else if inlist(`"`trend'"', "c", "co", "con", "cons", "const", "consta", "constan", "constant") local trend "constant"
    else if inlist(`"`trend'"', "t", "tr", "tre", "tren", "trend") local trend "trend"
    else {
        di as err "trend() must be none, constant or trend"
        exit 198
    }
    if "`trend'" == "none"     local det 0
    if "`trend'" == "constant" local det 1
    if "`trend'" == "trend"    local det 2

    local threshold = strlower(strtrim(`"`threshold'"'))
    if `"`threshold'"' == "" local threshold "estimate"
    if inlist(`"`threshold'"', "e", "est", "estimate", "chan") local threshold "estimate"
    else if inlist(`"`threshold'"', "z", "zero", "0") local threshold "zero"
    else {
        di as err "threshold() must be estimate or zero"
        exit 198
    }
    local thr = ("`threshold'" == "zero")

    local shift = strlower(strtrim(`"`shift'"'))
    if `"`shift'"' == "" local shift "regime"
    if inlist(`"`shift'"', "r", "reg", "regime", "cs") local shift "regime"
    else if inlist(`"`shift'"', "l", "lev", "level", "c") local shift "level"
    else {
        di as err "shift() must be regime or level"
        exit 198
    }
    local shiftc = ("`shift'" == "regime")
    if `hasgrid' & `shiftc' == 0 & `det' == 0 {
        di as err "shift(level) needs trend(constant) or trend(trend): a level shift requires an intercept"
        exit 198
    }

    local lags = strlower(strtrim(`"`lags'"'))
    if `"`lags'"' == "" local lags "aic"
    local pfix 0
    if "`lags'" == "aic" {
        local lagmode 1
    }
    else if "`lags'" == "bic" {
        local lagmode 2
    }
    else if "`lags'" == "tsig" {
        local lagmode 3
    }
    else {
        capture confirm integer number `lags'
        if _rc {
            di as err "lags() must be a nonnegative integer, aic, bic or tsig"
            exit 198
        }
        if `lags' < 0 {
            di as err "lags() must be a nonnegative integer, aic, bic or tsig"
            exit 198
        }
        local lagmode 0
        local pfix = `lags'
    }

    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie strictly between 0 and 0.5"
        exit 198
    }
    if `hashj' & `trim' >= 1/3 {
        di as err "tests hj, hjzt and hjza require trim() < 1/3"
        exit 198
    }

    local ga 0
    local gb 0
    local hasgarch 0
    if "`garch'" != "" {
        local ga : word 1 of `garch'
        local gb : word 2 of `garch'
        local hasgarch 1
    }

    // simulation mode: 0 none, 1 tests without a published table, 2 all tests
    local simmode 0
    if `hasauto' local simmode 1
    if `hassim' | (`hasauto' & `hasgarch') local simmode 2

    local bootstrap = strlower(strtrim(`"`bootstrap'"'))
    if `"`bootstrap'"' == "" local bootstrap "none"
    if !inlist(`"`bootstrap'"', "none", "wild") {
        di as err "bootstrap() must be wild or none"
        exit 198
    }
    local B 0
    if "`bootstrap'" == "wild" {
        if `reps' < 19 {
            di as err "reps() must be at least 19"
            exit 198
        }
        local B = `reps'
    }
    local multiplier = strlower(strtrim(`"`multiplier'"'))
    if `"`multiplier'"' == "" local multiplier "rademacher"
    if inlist(`"`multiplier'"', "gaussian", "normal", "n") local multiplier "gauss"
    if inlist(`"`multiplier'"', "rad", "r")                 local multiplier "rademacher"
    if inlist(`"`multiplier'"', "mam", "m")                 local multiplier "mammen"
    if !inlist(`"`multiplier'"', "gauss", "rademacher", "mammen") {
        di as err "multiplier() must be gauss, rademacher or mammen"
        exit 198
    }

    local R1 0
    local R2 0
    if `simmode' > 0 {
        if `simreps' == -1 {
            local R1 10000
            local R2 1000
        }
        else {
            if `simreps' < 20 {
                di as err "simreps() must be at least 20"
                exit 198
            }
            local R1 = `simreps'
            local R2 = `simreps'
        }
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar   "`r(timevar)'"
    local pvar   "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt   "`r(tsfmt)'"
    if "`tfmt'" == "" local tfmt "%9.0g"
    if "`pvar'" != "" {
        di as err "cointvol resid requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    if `N0' == 0 {
        error 2000
    }
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol resid needs consecutive observations"
        exit 498
    }
    local nv : word count `varlist'
    local m = `nv' - 1
    gettoken depvar indepvars : varlist
    local indepvars = strtrim("`indepvars'")

    if `maxlags' < 0 {
        local maxlags = floor(4 * (`N0'/100)^0.25)
    }
    if `lagmode' == 0 {
        local pmax = `pfix'
    }
    else {
        local pmax = `maxlags'
    }
    if `N0' < `pmax' + 2*`m' + 20 {
        di as err "too few observations (`N0') for `m' regressor(s) and up to `pmax' lag(s)"
        exit 2001
    }
    if `hasgrid' {
        if floor(`trim' * `N0') < `m' + 3 {
            di as err "trim() x N too small for the break tests: each regime needs at least " `m' + 3 " observations"
            exit 2001
        }
    }

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    // ---------------- computation ------------------------------------------
    local dots = ("`nodots'" == "")
    if `dots' & `hasgrid' & (`simmode' == 2 | `B' > 0) {
        di as txt "(note: the break tests re-run the full break-date search in every simulated/bootstrap sample;"
        di as txt "       this can take several minutes -- use lags(#) or smaller simreps()/reps() to speed up)"
    }
    mata: cve_resid_main("`mvars'", "`touse'", `det', `lagmode', `pfix', `pmax', `trim', ///
        `shiftc', `thr', "`wflags'", `simmode', `R1', `R2', `ga', `gb', `B', "`multiplier'", `dots')

    tempname res bdraw
    matrix `res' = __cve_res
    local Teff = scalar(__cve_T)
    capture matrix drop __cve_res
    capture scalar drop __cve_T
    if `B' > 0 {
        matrix `bdraw' = __cve_boot
        capture matrix drop __cve_boot
        matrix colnames `bdraw' = `canon'
    }
    local i 0
    foreach t of local canon {
        local i = `i' + 1
        local j_`t' = `i'
    }

    // ---------------- Franses-Kofman-Moser critical value ------------------
    local fkmok 0
    if `dofkm' {
        tempname fkmG fkmr sca scb
        matrix `fkmG' = J(`nv', 2, .)
        matrix colnames `fkmG' = alpha beta
        if `hasgarch' {
            local fa = `ga'
            local fb = `gb'
            local fsrc "user-supplied, garch()"
            local fkmok 1
        }
        else {
            tempname esth
            capture _estimates hold `esth', restore nullok
            tempvar tu2
            qui gen byte `tu2' = `touse'
            qui replace `tu2' = 0 if L.`touse' != 1
            local sa 0
            local sb 0
            local nfit 0
            local i 0
            foreach v of local mvars {
                local i = `i' + 1
                capture quietly arch D.`v' if `tu2', arch(1) garch(1)
                if _rc == 0 {
                    if e(converged) == 1 {
                        capture scalar `sca' = _b[ARCH:L.arch]
                        local rc1 = _rc
                        capture scalar `scb' = _b[ARCH:L.garch]
                        if `rc1' == 0 & _rc == 0 {
                            matrix `fkmG'[`i', 1] = `sca'
                            matrix `fkmG'[`i', 2] = `scb'
                            local sa = `sa' + `sca'
                            local sb = `sb' + `scb'
                            local nfit = `nfit' + 1
                        }
                    }
                }
            }
            matrix rownames `fkmG' = `varlist'
            if `nfit' > 0 {
                local fa = `sa' / `nfit'
                local fb = `sb' / `nfit'
                local fsrc "GARCH(1,1) fitted to the first differences, averaged over `nfit' of `nv' series"
                local fkmok 1
            }
            else {
                di as txt "(note: GARCH(1,1) could not be fitted to the first differences; cv(fkm) unavailable."
                di as txt "       Supply garch(# #) to use the FKM critical value.)"
            }
        }
        if `fkmok' {
            mata: st_matrix("__cve_fkm", cve_fkm(`fa', `fb'))
            matrix `fkmr' = __cve_fkm
            capture matrix drop __cve_fkm
            local fkmcv  = `fkmr'[1, 1]
            local fkmreg = `fkmr'[1, 2]
            local fkmdst = `fkmr'[1, 3]
        }
    }

    // ---------------- assemble results ---------------------------------------
    local eta = 1 - `level'/100
    local lev : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local tcol .
    if `level' == 99 local tcol 13
    if `level' == 95 local tcol 14
    if `level' == 90 local tcol 15
    tempname R row CT crow
    local first 1
    local anysim1 0
    local anysim2 0
    local anytabsh 0
    foreach t of local tlist {
        local j = `j_`t''
        local tcode = `res'[`j', 16]
        local nsim  = `res'[`j', 12]
        local simd = 0
        if `nsim' < . {
            if `nsim' > 0 local simd 1
        }
        if `simd' {
            local bk : list posof "`t'" in brk
            if `bk' > 0 local anysim2 1
            else local anysim1 1
        }
        // source of the reported critical values: 0 none, 1 table, 2 sim, 3 FKM
        local src 0
        if `simmode' == 2 {
            if `simd' local src 2
        }
        else if `simmode' == 1 {
            if `tcode' > 0 local src 1
            else if `simd' local src 2
        }
        else if `hastab' {
            if `tcode' > 0 local src 1
        }
        if `src' == 0 & "`t'" == "eg" & `fkmok' local src 3
        if `tcode' > 0 & `src' != 1 local anytabsh 1
        local src_`t' = `src'
        local tc_`t' = `tcode'
        matrix `row' = `res'[`j', 1..12]
        if `src' == 1 {
            matrix `row'[1, 2] = `res'[`j', 13]
            matrix `row'[1, 3] = `res'[`j', 14]
            matrix `row'[1, 4] = `res'[`j', 15]
        }
        if `src' == 3 {
            matrix `row'[1, 2] = .
            matrix `row'[1, 3] = `fkmcv'
            matrix `row'[1, 4] = .
        }
        local ps = `res'[`j', 5]
        local pb = `res'[`j', 6]
        local tl = `res'[`j', 8]
        local st = `res'[`j', 1]
        local rej = .
        if `B' > 0 {
            if `pb' < . local rej = (`pb' < `eta')
        }
        else if `src' == 2 {
            if `ps' < . local rej = (`ps' < `eta')
        }
        else if `src' == 1 & `tcol' < . {
            local c = `res'[`j', `tcol']
            if `c' < . & `st' < . {
                if `tl' < 0 local rej = (`st' < `c')
                else local rej = (`st' > `c')
            }
        }
        else if `src' == 3 {
            local rej = (`st' < `fkmcv')
        }
        matrix `row' = `row', J(1, 1, `rej')
        matrix `crow' = `res'[`j', 13..16], J(1, 1, `src')
        if `first' {
            matrix `R' = `row'
            matrix `CT' = `crow'
            local first 0
        }
        else {
            matrix `R' = `R' \ `row'
            matrix `CT' = `CT' \ `crow'
        }
        local rej_`t' = `rej'
        local j2_`t' = rowsof(`R')
    }
    matrix colnames `R' = stat cv01 cv05 cv10 p_sim p_boot lags tail param1 param2 bcv05 simreps reject
    matrix rownames `R' = `tlist'
    matrix colnames `CT' = tcv01 tcv05 tcv10 tabcode cvsrc
    matrix rownames `CT' = `tlist'

    // ---------------- labels -------------------------------------------------
    local lab_eg     "EG ADF t"
    local lab_ta1    "T(a-1)"
    local lab_crdw   "CRDW"
    local lab_hc0    "tau-White"
    local lab_tar    "E-S TAR F"
    local lab_mtar   "E-S MTAR F"
    local lab_kss    "KSS t_NLEG"
    local lab_kssecm "KSS t_NLECM"
    local lab_gh     "GH ADF*"
    local lab_ghzt   "GH Zt*"
    local lab_ghza   "GH Za*"
    local lab_hj     "HJ ADF*"
    local lab_hjzt   "HJ Zt*"
    local lab_hjza   "HJ Za*"
    local lab_vr     "Breitung VR"
    if "`trend'" == "none"     local tlab "none"
    if "`trend'" == "constant" local tlab "constant"
    if "`trend'" == "trend"    local tlab "constant + linear trend"
    if `lagmode' == 0 local laglab "fixed, `pfix'"
    if `lagmode' == 1 local laglab "AIC, max `pmax'"
    if `lagmode' == 2 local laglab "BIC, max `pmax'"
    if `lagmode' == 3 local laglab "t-sig, max `pmax'"
    local sfrom : display `tfmt' `tmin'
    local sto   : display `tfmt' `tmax'
    local sfrom = strtrim("`sfrom'")
    local sto   = strtrim("`sto'")

    // ---------------- table ----------------------------------------------------
    di
    di as txt "Residual-based tests of no cointegration" _col(52) "Number of obs  = " as res %8.0f `Teff'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Regressors (m) = " as res %8.0f `m'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags: " as res %19s "`laglab'"
    di as txt "Cointegrating regression: " as res abbrev("`depvar'", 20) as txt " on " as res "`indepvars'"
    if `hasauto' & `simmode' == 1 {
        di as txt "Critical values: " as res "published tables" as txt " where tabulated (Src = tab), otherwise simulated"
    }
    if `anysim1' | `anysim2' {
        if `hasgarch' {
            local elab "GARCH(1,1) errors, a = `ga', b = `gb'"
        }
        else {
            local elab "iid N(0,1) errors"
        }
        if `anysim1' & `anysim2' & `R1' != `R2' {
            local rlab "R = `R1' (break tests: `R2')"
        }
        else if `anysim1' {
            local rlab "R = `R1'"
        }
        else {
            local rlab "R = `R2'"
        }
        di as txt "Simulated CVs: " as res "under H0 (independent random walks)" as txt ", `rlab', " as res "`elab'"
    }
    if `B' > 0 {
        di as txt "Bootstrap: " as res "wild (extended)" as txt ", multiplier " as res "`multiplier'" ///
            as txt ", B = " as res `B' as txt ", seed " as res `"`seeduse'"'
    }
    di as txt "{hline 13}{c TT}{hline 65}"
    di as txt " Test" _col(14) "{c |}" _col(16) "Statistic" _col(30) "1%" _col(38) "5%" _col(45) "10%" ///
        _col(50) "Src" _col(55) "Sim.p" _col(61) "Boot.p" _col(67) "Lags" _col(72) "Decision"
    di as txt "{hline 13}{c +}{hline 65}"
    foreach t of local tlist {
        local j = `j2_`t''
        local stat = `R'[`j', 1]
        local c1 = `R'[`j', 2]
        local c5 = `R'[`j', 3]
        local c10 = `R'[`j', 4]
        local ps = `R'[`j', 5]
        local pb = `R'[`j', 6]
        local lg = `R'[`j', 7]
        local rj = `rej_`t''
        local cf "%7.3f"
        local mx = max(abs(`c1'), abs(`c5'), abs(`c10'))
        if `mx' < . {
            if `mx' >= 100 local cf "%7.2f"
            if `mx' >= 1000 local cf "%7.1f"
        }
        local sf "%10.3f"
        if abs(`stat') >= 100000 & `stat' < . local sf "%10.0f"
        local sl " - "
        if `src_`t'' == 1 local sl "tab"
        if `src_`t'' == 2 local sl "sim"
        if `src_`t'' == 3 local sl "fkm"
        if `rj' == 1 {
            local dec "Reject*"
        }
        else if `rj' == 0 {
            local dec "Accept"
        }
        else {
            local dec "  n/a"
        }
        di as txt " `lab_`t''" _col(14) "{c |}" as res _col(15) `sf' `stat' _col(26) `cf' `c1' ///
            _col(34) `cf' `c5' _col(42) `cf' `c10' as txt _col(50) "`sl'" as res _col(54) %6.3f `ps' ///
            _col(61) %6.3f `pb' _col(67) %4.0f `lg' as txt _col(72) "`dec'"
    }
    di as txt "{hline 13}{c BT}{hline 65}"
    di as txt "H0: no cointegration. * rejects H0 at the `lev'% level (bootstrap p if requested, otherwise"
    di as txt "    the simulated p or the published critical value). CRDW, TAR/MTAR F and VR reject"
    di as txt "    for large values (CV columns = 99/95/90% quantiles); all other tests are left-tailed."
    if `B' == 0 & `tcol' == . {
        di as txt "    (published tables give only 1/5/10% values: no table-based decision at level(`level'))"
    }

    // sources of the published critical values used
    local srcshown ""
    foreach t of local tlist {
        if `src_`t'' == 1 | `tc_`t'' > 0 {
            if inlist("`t'", "tar", "mtar") local sk "es"
            if inlist("`t'", "kss", "kssecm") local sk "kss"
            if inlist("`t'", "gh", "ghzt", "ghza") local sk "gh"
            if inlist("`t'", "hj", "hjzt", "hjza") local sk "hj"
            if "`t'" == "vr" local sk "br"
            local srcshown : list srcshown | sk
        }
    }
    foreach sk of local srcshown {
        if "`sk'" == "es"  di as txt "Tables: E-S F: Enders-Siklos (2001, WP) Tables 1-2 (tau = 0, T = 100/500)"
        if "`sk'" == "kss" di as txt "Tables: KSS: Kapetanios-Shin-Snell (2006; WP 497) Table 1 (asymptotic)"
        if "`sk'" == "gh"  di as txt "Tables: GH: Gregory-Hansen (1996) Table 1 (asymptotic, trim 0.15)"
        if "`sk'" == "hj"  di as txt "Tables: HJ: Hatemi-J (2008) Table 1 (asymptotic, trim 0.15)"
        if "`sk'" == "br"  di as txt "Tables: VR: Breitung (2002; DP 1999) Table A.2 (T = 500)"
    }
    foreach t in tar mtar {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            if `tc_`t'' == 3 di as txt "`lab_`t'': T outside 100-500, nearest tabulated T used"
        }
    }

    // published values for tests whose reported CVs are simulated
    if `anytabsh' {
        di as txt "Published critical values (1% / 5% / 10%) for comparison:"
        foreach t of local tlist {
            local j = `j2_`t''
            if `CT'[`j', 4] > 0 & `src_`t'' != 1 {
                local a1 : display %9.3f `CT'[`j', 1]
                local a2 : display %9.3f `CT'[`j', 2]
                local a3 : display %9.3f `CT'[`j', 3]
                di as txt "  `lab_`t'':" _col(18) as res "`a1'  `a2'  `a3'"
            }
        }
    }

    // details of grid searches
    foreach t in tar mtar {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            local th = `R'[`j2_`t'', 9]
            local thd : display %9.4f `th'
            if `thr' {
                di as txt "`lab_`t'': threshold fixed at 0 (attractor; Enders-Siklos Tables 1-2)"
            }
            else {
                di as txt "`lab_`t'': threshold = " as res strtrim("`thd'") ///
                    as txt " (Chan 1993; trimmed `=100*`trim''%-`=100*(1-`trim')'% order statistics)"
            }
        }
    }
    if "`shift'" == "regime" local shl "regime shift (level and slopes)"
    else local shl "level shift"
    foreach t in gh ghzt ghza {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            local tb = `R'[`j2_`t'', 9]
            if `tb' < . {
                local bd : display `tfmt' (`tmin' + `tb'*`tdelta')
                di as txt "`lab_`t'': `shl', new regime starts at " as res strtrim("`bd'")
            }
        }
    }
    foreach t in hj hjzt hjza {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            local tb1 = `R'[`j2_`t'', 9]
            local tb2 = `R'[`j2_`t'', 10]
            if `tb1' < . {
                local bd1 : display `tfmt' (`tmin' + `tb1'*`tdelta')
                local bd2 : display `tfmt' (`tmin' + `tb2'*`tdelta')
                di as txt "`lab_`t'': `shl'; regimes start at " as res strtrim("`bd1'") as txt " and " ///
                    as res strtrim("`bd2'")
            }
        }
    }
    local k1 : list posof "hc0" in tlist
    local k2 : list posof "eg" in tlist
    if `k1' > 0 & `k2' > 0 & `simmode' > 0 {
        di as txt "Lee-Tse tau'-White: compare tau-White with the EG ADF t critical values (oversized under GARCH)."
    }
    if `anysim1' & `R1' < 1000 {
        di as txt "(note: simreps() < 1000; simulated 1% critical values are imprecise)"
    }

    // ---------------- FKM block --------------------------------------------------
    if `dofkm' & `fkmok' {
        local statEG = `res'[`j_eg', 1]
        if `fkmreg' == 1 {
            if `fkmdst' <= 0.05 {
                local rglab "stationary GARCH, FKM Table 1 (nearest design point)"
            }
            else {
                local rglab "stationary GARCH away from a+b = 1: no-GARCH fractile, FKM Table 1 row (0,0)"
            }
        }
        if `fkmreg' == 2 local rglab "(near-)IGARCH, |a+b-1| < 0.02: response surface FKM eq. (7)"
        if `fkmreg' == 3 local rglab "non-covariance-stationary GARCH, a+b >= 1.02: FKM eq. (8)"
        local fdec "Accept"
        if `statEG' < `fkmcv' local fdec "Reject*"
        di
        di as txt "Franses-Kofman-Moser (1994) GARCH-adjusted 5% critical value for the EG test"
        di as txt "{hline 78}"
        di as txt "  GARCH(1,1): alpha = " as res %6.3f `fa' as txt "   beta = " as res %6.3f `fb' ///
            as txt "   alpha+beta = " as res %6.3f `fa' + `fb'
        di as txt "  source: `fsrc'"
        di as txt "  region: `rglab'"
        di as txt "  EG ADF t = " as res %8.3f `statEG' as txt "   FKM 5% CV = " as res %8.3f `fkmcv' ///
            as txt "   Decision: " as res "`fdec'"
        di as txt "{hline 78}"
        di as txt "  FKM values are calibrated for T = 250, one regressor, constant, no lags"
        if abs(`Teff' - 250) > 75 | `m' != 1 | "`trend'" != "constant" {
            local fas : display %5.3f `fa'
            local fbs : display %5.3f `fb'
            local fas = strtrim("`fas'")
            local fbs = strtrim("`fbs'")
            di as txt "  Warning: the present design (T = `Teff', m = `m', trend = `trend') differs from the"
            di as txt "  FKM calibration; prefer cv(sim) with garch(`fas' `fbs')."
        }
    }

    // ---------------- stored results ---------------------------------------------
    return scalar N     = `Teff'
    return scalar m     = `m'
    return scalar level = `level'
    return scalar trim  = `trim'
    if `lagmode' == 0 {
        return scalar lags = `pfix'
    }
    else {
        return scalar maxlags = `pmax'
    }
    if `anysim1' {
        return scalar simreps = `R1'
    }
    if `anysim2' {
        return scalar simreps_break = `R2'
    }
    if `B' > 0 {
        return scalar reps = `B'
    }
    if `hasgarch' {
        return scalar garch_a = `ga'
        return scalar garch_b = `gb'
    }
    foreach t of local tlist {
        local j = `j2_`t''
        return scalar `t'      = `R'[`j', 1]
        return scalar cv05_`t' = `R'[`j', 3]
        return scalar p_`t'    = `R'[`j', 5]
        return scalar pb_`t'   = `R'[`j', 6]
        if `CT'[`j', 4] > 0 {
            return scalar tcv05_`t' = `CT'[`j', 2]
        }
    }
    foreach t in tar mtar {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            return scalar `t'_threshold = `R'[`j2_`t'', 9]
        }
    }
    foreach t in gh ghzt ghza {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            local tb = `R'[`j2_`t'', 9]
            if `tb' < . {
                return scalar `t'_break = `tmin' + `tb'*`tdelta'
            }
        }
    }
    foreach t in hj hjzt hjza {
        local k : list posof "`t'" in tlist
        if `k' > 0 {
            local tb1 = `R'[`j2_`t'', 9]
            local tb2 = `R'[`j2_`t'', 10]
            if `tb1' < . {
                return scalar `t'_break1 = `tmin' + `tb1'*`tdelta'
                return scalar `t'_break2 = `tmin' + `tb2'*`tdelta'
            }
        }
    }
    if `dofkm' & `fkmok' {
        return scalar fkm_cv     = `fkmcv'
        return scalar fkm_alpha  = `fa'
        return scalar fkm_beta   = `fb'
        return scalar fkm_region = `fkmreg'
    }
    return local depvar     "`depvar'"
    return local indepvars  "`indepvars'"
    return local tests      "`tlist'"
    return local trend      "`trend'"
    return local lags       "`lags'"
    return local cv         "`cv'"
    return local threshold  "`threshold'"
    return local shift      "`shift'"
    return local bootstrap  "`bootstrap'"
    return local multiplier "`multiplier'"
    return local seed       `"`seed'"'
    return local cmd        "cointvol resid"
    return matrix results = `R'
    return matrix cvtable = `CT'
    if `B' > 0 {
        return matrix boot = `bdraw'
    }
    if `dofkm' & `hasgarch' == 0 {
        return matrix fkm_garch = `fkmG'
    }
end
