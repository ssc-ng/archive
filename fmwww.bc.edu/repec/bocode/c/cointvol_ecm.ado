*! cointvol_ecm 0.2.0  26sep2026
*! Single-equation ECM t-tests of no cointegration (KED known beta; BDM/E&M
*! estimated coefficients) with published critical values and a wild bootstrap
*! robust to GARCH errors
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_ecm.sthlp, section Methods):
*!   dy = a dx + b (y - beta x)(t-1) + e, t on b (known)   -> KED (1992) eqs (1), (3), (14); Mantalos eq (3)
*!   signal-to-noise q = -(a - beta) s, s = sd(dx)/sd(e)    -> KED (1992) eq (16); limits (13), (17), (18)
*!   dy = g0'dx + rho y(t-1) + th'x(t-1) + det + lags, t on rho -> BDM (1998) eqs (1'), (3');
*!                                                             E&M (2002) eqs (16), (24)
*!   cv(em): c(p) = th_inf + th1/Ta + th2/Ta^2 + th3/Ta^3,  -> E&M (2002) eq (26), Tables 2-5;
*!           Ta = T - h (h = # regressors incl. det)          sec. 5 (lags); k = 1 for known beta
*!   cv(bdm): BDM Table I, 1/T interpolation                 -> BDM (1998) Table I
*!   wild bootstrap dy* = fitted(b = 0) + e^ u*, Mammen u*  -> Mantalos eqs (4)-(5); Mammen (1993)
*!   p = P*(t* <= t) (left tail)                           -> correction of Mantalos' P*(T* >= T)
*!   ARCH-LM(1) = T R^2 on ECM residuals                   -> Mantalos sec. 3 (Engle 1982)

program define cointvol_ecm, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in] [, BETA(string) TRend(string) LAGs(integer 0) ///
        CV(string) BOOTstrap(string) MULTiplier(string) Reps(integer 199) SEED(string)         ///
        CONStant BSResid(string) SIMReps(integer 10000) Level(cilevel) NODOTS * ]
    local addcons "`constant'"
    local nocons ""
    if `"`options'"' != "" {
        local 0 `", `options'"'
        syntax [, NOCONStant ]
        if "`addcons'" != "" {
            di as err "options constant and noconstant may not be combined"
            exit 184
        }
        local nocons "noconstant"
    }

    // ---------------- load / reload the Mata engine ----------------------
    local __cvever ""
    capture mata: st_local("__cvever", cve_version())
    if _rc | "`__cvever'" != "0.2.0" {
        capture program drop cointvol_eng_resid
        quietly findfile cointvol_eng_resid.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- options --------------------------------------------
    local nv : word count `varlist'
    local m = `nv' - 1
    local beta = strlower(strtrim(`"`beta'"'))
    if inlist(`"`beta'"', "e", "es", "est", "esti", "estim", "estimate", "estimated", "unrestricted") {
        local mode 1
        local bval 0
    }
    else {
        local mode 0
        if `"`beta'"' == "" local beta 1
        capture confirm number `beta'
        if _rc {
            di as err "beta() must be a number (known cointegrating coefficient) or estimate"
            exit 198
        }
        local bval = `beta'
        if `m' != 1 {
            di as err "a known beta requires exactly one indepvar; specify beta(estimate) for several regressors"
            exit 103
        }
    }
    if `mode' == 1 & `m' > 11 {
        di as err "at most 11 regressors (E&M tabulate k = 1, ..., 12 variables)"
        exit 103
    }

    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' != "" {
        if inlist(`"`trend'"', "n", "no", "non", "none", "nc") local trend "none"
        else if inlist(`"`trend'"', "c", "co", "con", "cons", "const", "constant") local trend "constant"
        else if inlist(`"`trend'"', "t", "tr", "tre", "tren", "trend", "ct") local trend "trend"
        else if inlist(`"`trend'"', "q", "qt", "qtrend", "quadratic", "ctt") local trend "qtrend"
        else {
            di as err "trend() must be none, constant, trend or qtrend"
            exit 198
        }
        if "`addcons'" != "" & "`trend'" != "constant" {
            di as err "option constant conflicts with trend(`trend')"
            exit 184
        }
        if "`nocons'" != "" & "`trend'" != "none" {
            di as err "option noconstant conflicts with trend(`trend')"
            exit 184
        }
    }
    else {
        if `mode' == 0 local trend "none"
        if `mode' == 1 local trend "constant"
        if "`addcons'" != "" local trend "constant"
        if "`nocons'" != "" local trend "none"
    }
    if "`trend'" == "none"     local det 0
    if "`trend'" == "constant" local det 1
    if "`trend'" == "trend"    local det 2
    if "`trend'" == "qtrend"   local det 3
    if "`trend'" == "none"     local dl "nc"
    if "`trend'" == "constant" local dl "c"
    if "`trend'" == "trend"    local dl "ct"
    if "`trend'" == "qtrend"   local dl "ctt"
    local cons = (`det' >= 1)

    if `lags' < 0 {
        di as err "lags() must be a nonnegative integer"
        exit 198
    }
    local p = `lags'

    local cv = strlower(strtrim(`"`cv'"'))
    if `"`cv'"' == "" local cv "em"
    if !inlist(`"`cv'"', "em", "bdm", "sim", "ked", "normal") {
        di as err "cv() must be em, bdm, sim, ked or normal"
        exit 198
    }
    if "`cv'" == "ked" & `mode' == 1 {
        di as err "cv(ked) applies to a known beta (KED signal-to-noise q); use em, bdm or sim"
        exit 198
    }
    if "`cv'" == "bdm" & `mode' == 0 {
        di as err "cv(bdm) applies to beta(estimate) (BDM Table I); use em, sim, ked or normal"
        exit 198
    }

    local bootstrap = strlower(strtrim(`"`bootstrap'"'))
    if `"`bootstrap'"' == "" local bootstrap "wild"
    if !inlist(`"`bootstrap'"', "wild", "none") {
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
    if `"`multiplier'"' == "" local multiplier "mammen"
    if inlist(`"`multiplier'"', "gaussian", "normal", "n") local multiplier "gauss"
    if inlist(`"`multiplier'"', "rad", "r")                 local multiplier "rademacher"
    if inlist(`"`multiplier'"', "mam", "m")                 local multiplier "mammen"
    if !inlist(`"`multiplier'"', "gauss", "rademacher", "mammen") {
        di as err "multiplier() must be mammen, rademacher or gauss"
        exit 198
    }
    local bsresid = strlower(strtrim(`"`bsresid'"'))
    if `"`bsresid'"' == "" local bsresid "unrestricted"
    if inlist(`"`bsresid'"', "u", "unr", "unrestricted") local bsresid "unrestricted"
    if inlist(`"`bsresid'"', "r", "res", "restricted")   local bsresid "restricted"
    if !inlist(`"`bsresid'"', "unrestricted", "restricted") {
        di as err "bsresid() must be unrestricted or restricted"
        exit 198
    }
    local restr = ("`bsresid'" == "restricted")
    if `simreps' < 0 {
        di as err "simreps() must be 0 (skip) or a positive integer"
        exit 198
    }
    if `simreps' > 0 & `simreps' < 100 {
        di as err "simreps() must be 0 or at least 100"
        exit 198
    }
    if inlist("`cv'", "sim", "ked") & `simreps' == 0 {
        di as err "cv(`cv') needs simreps() > 0"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar   "`r(timevar)'"
    local pvar   "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt   "`r(tsfmt)'"
    if "`tfmt'" == "" local tfmt "%9.0g"
    if "`pvar'" != "" {
        di as err "cointvol ecm requires time-series data; the data are xtset as a panel"
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
        di as err "the estimation sample contains gaps; cointvol ecm needs consecutive observations"
        exit 498
    }
    local hh = `m' + 1 + `mode'*`m' + `det' + `p'*(1 + `m')
    if `N0' < 15 | `N0' - 1 - `p' - `hh' < 5 {
        di as err "too few observations (`N0') for `hh' ECM regressors"
        exit 2001
    }
    gettoken depvar indepvars : varlist
    local indepvars = strtrim("`indepvars'")

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    local dots = ("`nodots'" == "")
    mata: cve_ecm_main("`mvars'", "`touse'", `mode', `bval', `det', `p', `B', "`multiplier'", ///
        `restr', `simreps', `dots')

    tempname res fit tb cf
    matrix `res' = __cve_ecmres
    matrix `fit' = __cve_ecmfit
    matrix `cf'  = __cve_ecmcoef
    capture matrix drop __cve_ecmres __cve_ecmfit __cve_ecmcoef
    if `B' > 0 {
        matrix `tb' = __cve_ecmboot
        capture matrix drop __cve_ecmboot
        matrix colnames `tb' = t_star
    }
    local t    = `fit'[1, 1]
    local bh   = `fit'[1, 2]
    local seb  = `fit'[1, 3]
    local s2   = `fit'[1, 4]
    local n    = `fit'[1, 5]
    local h    = `fit'[1, 6]
    local Ta   = `fit'[1, 7]
    local lm   = `fit'[1, 8]
    local plm  = `fit'[1, 9]
    local qh   = `fit'[1, 10]
    local kem  = `fit'[1, 11]
    local bdc  = `fit'[1, 12]

    // ---------------- decisions ----------------------------------------------
    local eta = 1 - `level'/100
    local lev : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local ccol .
    if `level' == 99 local ccol 1
    if `level' == 95 local ccol 2
    if `level' == 90 local ccol 3
    tempname R
    matrix `R' = `res', J(6, 1, .)
    forvalues i = 1/6 {
        if `R'[`i', 4] < . {
            matrix `R'[`i', 5] = (`R'[`i', 4] < `eta')
        }
        else if `ccol' < . {
            if `R'[`i', `ccol'] < . {
                matrix `R'[`i', 5] = (`t' < `R'[`i', `ccol'])
            }
        }
    }
    matrix colnames `R' = cv01 cv05 cv10 p reject
    matrix rownames `R' = bootstrap sim normal em bdm kedq
    if "`cv'" == "em"     local rref 4
    if "`cv'" == "bdm"    local rref 5
    if "`cv'" == "sim"    local rref 2
    if "`cv'" == "ked"    local rref 6
    if "`cv'" == "normal" local rref 3
    local rejref = `R'[`rref', 5]
    if `B' > 0 {
        local rmain 1
        local plab "wild bootstrap"
    }
    else {
        local rmain = `rref'
        if "`cv'" == "em"     local plab "Ericsson-MacKinnon response surface"
        if "`cv'" == "bdm"    local plab "BDM Table I"
        if "`cv'" == "sim"    local plab "simulated null distribution"
        if "`cv'" == "ked"    local plab "KED plug-in q = q^ (simulated)"
        if "`cv'" == "normal" local plab "N(0,1)"
    }
    local rej = `R'[`rmain', 5]
    local pmain = `R'[`rmain', 4]

    // ---------------- table ------------------------------------------------
    local s1 = `tmin' + (`p' + 1)*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local sfrom = strtrim("`sfrom'")
    local sto   = strtrim("`sto'")
    local bdisp : display %9.4g `bval'
    local bdisp = strtrim("`bdisp'")
    local dy "D.`depvar'"
    if "`trend'" == "none"     local tlab "none"
    if "`trend'" == "constant" local tlab "constant"
    if "`trend'" == "trend"    local tlab "constant + trend"
    if "`trend'" == "qtrend"   local tlab "constant + trend + trend^2"
    di
    if `mode' == 0 {
        local dx "D.`indepvars'"
        di as txt "Kremers-Ericsson-Dolado ECM test (known beta)" _col(54) "Number of obs = " as res %7.0f `n'
        di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(54) "beta (known)  = " as res %7s "`bdisp'"
        di as txt "ECM: " as res "`dy' = a*`dx' + b*(`depvar' - `bdisp'*`indepvars')(t-1) + det + e"
    }
    else {
        di as txt "ECM test, estimated coefficients (BDM 1998; E&M 2002)" _col(54) "Number of obs = " as res %7.0f `n'
        di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(54) "variables k   = " as res %7.0f `kem'
        di as txt "ECM: " as res "`dy' = g0'D.x + rho*`depvar'(t-1) + th'x(t-1) + det + e" as txt ",  x = " ///
            as res "`indepvars'"
    }
    di as txt "Deterministic: " as res "`tlab'" as txt _col(54) "Lags (p)      = " as res %7.0f `p'
    if `B' > 0 {
        di as txt "Wild bootstrap: multiplier " as res "`multiplier'" as txt ", B = " as res `B' ///
            as txt ", seed " as res `"`seeduse'"' as txt ", residuals " as res "`bsresid'"
    }
    di as txt "{hline 17}{c TT}{hline 44}"
    di as txt _col(18) "{c |}" _col(25) "Coef." _col(34) "Std. err." _col(49) "t"
    di as txt "{hline 17}{c +}{hline 44}"
    if `mode' == 0 {
        local ah  = `cf'[1, 1]
        local sea = `cf'[2, 1]
        di as txt " a  (" abbrev("`dx'", 10) ")" _col(18) "{c |}" as res _col(20) %10.4f `ah' ///
            _col(33) %10.4f `sea' _col(44) %8.3f `ah'/`sea'
        di as txt " b  (ECT, t-1)" _col(18) "{c |}" as res _col(20) %10.4f `bh' ///
            _col(33) %10.4f `seb' _col(44) %8.3f `t'
        if `cons' {
            local ch  = `cf'[1, 3]
            local sec = `cf'[2, 3]
            di as txt " c  (_cons)" _col(18) "{c |}" as res _col(20) %10.4f `ch' ///
                _col(33) %10.4f `sec' _col(44) %8.3f `ch'/`sec'
        }
    }
    else {
        local i 0
        foreach v of local indepvars {
            local i = `i' + 1
            local c1 = `cf'[1, `i']
            local c2 = `cf'[2, `i']
            di as txt " D." abbrev("`v'", 12) _col(18) "{c |}" as res _col(20) %10.4f `c1' ///
                _col(33) %10.4f `c2' _col(44) %8.3f `c1'/`c2'
        }
        di as txt " rho " abbrev("`depvar'", 8) "(t-1)" _col(18) "{c |}" as res _col(20) %10.4f `bh' ///
            _col(33) %10.4f `seb' _col(44) %8.3f `t'
        local i 0
        foreach v of local indepvars {
            local i = `i' + 1
            local c1 = `cf'[1, `m' + 1 + `i']
            local c2 = `cf'[2, `m' + 1 + `i']
            di as txt " " abbrev("`v'", 10) "(t-1)" _col(18) "{c |}" as res _col(20) %10.4f `c1' ///
                _col(33) %10.4f `c2' _col(44) %8.3f `c1'/`c2'
        }
        if `cons' {
            local c1 = `cf'[1, 2*`m' + 2]
            local c2 = `cf'[2, 2*`m' + 2]
            di as txt " _cons" _col(18) "{c |}" as res _col(20) %10.4f `c1' ///
                _col(33) %10.4f `c2' _col(44) %8.3f `c1'/`c2'
        }
    }
    di as txt "{hline 17}{c BT}{hline 44}"
    if `det' >= 2 | `p' > 0 {
        di as txt "(trend terms and `p' lag(s) of (D.y, D.x) included, not shown)"
    }
    di
    if `mode' == 0 {
        di as txt "H0: b = 0 (no cointegration)  vs  H1: b < 0.   t_ECM = " as res %8.3f `t'
    }
    else {
        di as txt "H0: rho = 0 (no cointegration)  vs  H1: rho < 0.   kappa_`dl'(`kem') = " as res %8.3f `t'
    }
    di as txt "{hline 25}{c TT}{hline 52}"
    di as txt " Inference" _col(26) "{c |}" _col(32) "1%" _col(42) "5%" _col(51) "10%" _col(58) "p-value" ///
        _col(69) "Decision"
    di as txt "{hline 25}{c +}{hline 52}"
    local rl1 "Wild bootstrap"
    local rl3 "N(0,1) (reference)"
    local rl5 "BDM (1998) Table I"
    local rl6 "KED q = q^ (simulated)"
    if `mode' == 0 {
        local rl2 "Sim. q = 0 (DF-type)"
        local rl3 "N(0,1) (q -> infinity)"
        local rl4 "E&M `dl'(1): q = 0 bound"
    }
    else {
        local rl2 "Simulated (E&M DGP)"
        local rl4 "E&M `dl'(`kem') resp. surf."
    }
    foreach i in 1 4 5 2 6 3 {
        local c1 = `R'[`i', 1]
        local c5 = `R'[`i', 2]
        local c10 = `R'[`i', 3]
        local pv = `R'[`i', 4]
        local rj = `R'[`i', 5]
        if `c1' == . & `c5' == . & `pv' == . continue
        local dec "   ."
        if `rj' == 1 local dec "Reject*"
        if `rj' == 0 local dec "Accept"
        local mk " "
        if `i' == `rmain' local mk ">"
        di as txt "`mk'`rl`i''" _col(26) "{c |}" as res _col(27) %8.3f `c1' _col(37) %8.3f `c5' ///
            _col(47) %8.3f `c10' _col(58) %7.3f `pv' as txt _col(69) "`dec'"
    }
    di as txt "{hline 25}{c BT}{hline 52}"
    di as txt "* rejects H0 at the `lev'% level. > main inference: " as res "`plab'" as txt "."
    di as txt "E&M: Ericsson-MacKinnon (2002) Tables 2-5 at Ta = T - h = " as res `n' as txt " - " ///
        as res `h' as txt " = " as res `Ta' as txt ";"
    di as txt "     E&M p-value: probit interpolation of the 1/5/10% quantiles (approximate)."
    di as txt "     Bootstrap p = P*(t* <= t) (left tail)."
    if `n' < 20 {
        di as txt "     (T < 20 lies below the E&M simulation design; values extrapolated)"
    }
    if `mode' == 1 & `bdc' > 0 {
        if `bdc' == 2 di as txt "BDM: linear interpolation in 1/T between the tabulated T = 25, 50, 100, 500, inf"
        if `bdc' == 3 di as txt "BDM: T < 25, the T = 25 row is used"
    }
    if `mode' == 1 & `bdc' == 0 {
        di as txt "BDM Table I covers 1-5 regressors with constant or constant + trend only"
    }
    if `mode' == 0 {
        di as txt "KED (1992): with known beta, t_ECM is DF-type when q = 0 (E&M k = 1 row) and N(0,1)"
        di as txt "as q -> infinity; its null distribution depends on q (eqs 15-18)."
        local qd : display %8.3f `qh'
        di as txt "Estimated signal-to-noise q = -(a - beta) sd(`dx')/sd(e) = " as res strtrim("`qd'")
    }
    if `p' > 0 {
        di as txt "(lags: E&M response surfaces are for no lagged differences; Ta = T - h adjusts, E&M sec. 5)"
    }
    di as txt "ARCH-LM(1) on the ECM residuals: T*R2 = " as res %7.3f `lm' as txt ",  p = " ///
        as res %5.3f `plm' as txt "  (chi2(1))"

    // ---------------- stored results -----------------------------------------
    return scalar N        = `n'
    return scalar h        = `h'
    return scalar Ta       = `Ta'
    return scalar k        = `kem'
    return scalar lags     = `p'
    if `mode' == 0 {
        return scalar beta = `bval'
        return scalar a    = `cf'[1, 1]
        return scalar se_a = `cf'[2, 1]
        return scalar q    = `qh'
        if `cons' {
            return scalar c    = `cf'[1, 3]
            return scalar se_c = `cf'[2, 3]
        }
    }
    return scalar t        = `t'
    return scalar b        = `bh'
    return scalar se_b     = `seb'
    return scalar sigma2   = `s2'
    return scalar archlm   = `lm'
    return scalar p_archlm = `plm'
    return scalar p_boot   = `R'[1, 4]
    return scalar p_df     = `R'[2, 4]
    return scalar p_norm   = `R'[3, 4]
    return scalar p_em     = `R'[4, 4]
    return scalar p_ked    = `R'[6, 4]
    return scalar cv05_boot = `R'[1, 2]
    return scalar cv05_df   = `R'[2, 2]
    return scalar cv01_em   = `R'[4, 1]
    return scalar cv05_em   = `R'[4, 2]
    return scalar cv10_em   = `R'[4, 3]
    return scalar cv05_bdm  = `R'[5, 2]
    return scalar reject   = `rej'
    return scalar reject_cv = `rejref'
    return scalar level    = `level'
    if `B' > 0 {
        return scalar reps = `B'
    }
    return scalar simreps  = `simreps'
    return local depvar     "`depvar'"
    return local indepvar   "`indepvars'"
    return local indepvars  "`indepvars'"
    return local constant   = cond(`cons', "constant", "noconstant")
    return local trend      "`trend'"
    return local cv         "`cv'"
    return local betatype   = cond(`mode' == 0, "known", "estimated")
    return local bootstrap  "`bootstrap'"
    return local multiplier "`multiplier'"
    return local bsresid    "`bsresid'"
    return local seed       `"`seed'"'
    return local cmd        "cointvol ecm"
    return matrix results = `R'
    return matrix coef = `cf'
    if `B' > 0 {
        return matrix boot = `tb'
    }
end
