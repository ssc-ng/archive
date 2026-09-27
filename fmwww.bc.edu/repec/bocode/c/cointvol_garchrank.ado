*! cointvol_garchrank 0.1.0  26sep2026
*! Cointegration-rank tests designed for CCC-GARCH errors: LR_G and Hausman H_G
*! (one-step QMLE) and Wald W_G / robust W*_G (one-step WLS), with Johansen LR_NG
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_garchrank.sthlp, Methods and formulas):
*!   ECM W_t = C Y_{t-1} + sum Phi*_j W_{t-j} (+ mu) + e_t, C = AB, CCC-GARCH(p,q)
*!       -> Sin, Mi & Ling (2024, SML) (2.3)-(2.7)
*!   LS + CCC-GARCH on residuals; one-step FR QMLE with F_t and grad h (B.1)
*!       -> SML (3.2), (3.4), (B.1)
*!   Johansen RRR initial RR estimator; one-step RR QMLE -> SML Sec 4.1, (4.5)-(4.8)
*!   LR_G computational form -> SML (5.4); Hausman H_G -> SML (5.5)-(5.6)
*!   nuisance lambda (Thm 5.2) and lambda^H (Thm 5.1) -> SML Sec 6
*!   critical values: SML Tables 1-3 (interpolated) or simulation of (6.1)-(6.4)
*!   method(wls): FGLS one-step FR/RR, W_G (5.2), W*_G (5.4), lambda, lambda*
*!       -> Sin (c. 2004) Secs 3-5, Cor 5.1, Tables A.1-A.2
*!   LR_NG: Johansen trace statistic (core engine), limit = lambda 0 case (SML Rem 5.1)

program define cointvol_garchrank, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in], Lags(integer) ///
        [ TRend(string) Method(string) GARCH(numlist integer min=2 max=2 >=0) ///
          CV(string) SIMReps(integer 20000) SIMN(integer 1000) SEED(string)   ///
          Level(cilevel) Rank(numlist integer >=0) NODOTS NOGARCHtable ]

    // ---------------- load / reload the Mata engines ---------------------
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvkver", cvk_version())
    if _rc {
        capture program drop cointvol_eng_garchrank
        quietly findfile cointvol_eng_garchrank.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- options --------------------------------------------
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "rconstant"
    if inlist(`"`trend'"', "n", "no", "non", "none") local trend "none"
    else if inlist(`"`trend'"', "rc", "rco", "rcon", "rconst", "rconstant") local trend "rconstant"
    else {
        di as err "trend() must be none or rconstant for cointvol garchrank"
        di as err "(the tabulated limits of Sin, Mi & Ling (2024) cover only these two cases)"
        exit 198
    }
    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "qmle"
    if !inlist(`"`method'"', "qmle", "wls") {
        di as err "method() must be qmle or wls"
        exit 198
    }
    if "`garch'" == "" local garch "1 1"
    local gp : word 1 of `garch'
    local gq : word 2 of `garch'
    if `gq' < 1 {
        di as err "garch(p q): the ARCH order q must be at least 1"
        exit 198
    }
    if `gp' > 4 | `gq' > 4 {
        di as err "garch(p q): orders above 4 are not supported"
        exit 198
    }
    local cv = strlower(strtrim(`"`cv'"'))
    if `"`cv'"' == "" local cv "table"
    if inlist(`"`cv'"', "tab", "tables") local cv "table"
    if inlist(`"`cv'"', "simulate", "simulation") local cv "sim"
    if !inlist(`"`cv'"', "table", "sim") {
        di as err "cv() must be table or sim"
        exit 198
    }
    if "`cv'" == "table" & !inlist(`level', 90, 95, 99) {
        di as err "with cv(table) level() must be 90, 95 or 99; use cv(sim) for other levels"
        exit 198
    }
    if `lags' < 1 {
        di as err "lags() must be a positive integer (lag order of the VAR in levels)"
        exit 198
    }
    if `simreps' < 100 {
        di as err "simreps() must be at least 100"
        exit 198
    }
    if `simn' < 100 {
        di as err "simn() must be at least 100"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol garchrank requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol garchrank needs consecutive observations"
        exit 498
    }
    local m : word count `varlist'
    local T = `N0' - `lags'
    if `T' < max(50, `m'*`lags' + 20) {
        di as err "too few observations (" `N0' ") for m = `m' variables, `lags' lags and a GARCH model"
        exit 2001
    }
    local maxr = `m' - 1
    if "`rank'" == "" {
        numlist "0/`maxr'"
        local rlist "`r(numlist)'"
    }
    else {
        foreach r of local rank {
            if `r' > `maxr' {
                di as err "rank(): each H0 rank must lie in 0,...,`maxr'"
                exit 198
            }
        }
        numlist "`rank'", sort
        local rlist "`r(numlist)'"
    }
    local ntests : word count `rlist'

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"
    local dots = ("`nodots'" == "")

    capture matrix drop __cvk_res
    mata: cvk_main("`mvars'", "`touse'", `lags', "`trend'", "`method'", `gp', `gq', ///
        "`cv'", `simreps', `simn', `level', "`rlist'", `dots')

    tempname res lam1 lam2 jlam PiLS PiFR g0 G0 g1 G1 Om1 EV Om1s Dl
    matrix `res'  = __cvk_res
    matrix `lam1' = __cvk_lam1
    matrix `lam2' = __cvk_lam2
    matrix `jlam' = __cvk_jlam
    matrix `PiLS' = __cvk_PiLS
    matrix `PiFR' = __cvk_PiFR
    matrix `g0'   = __cvk_garch0
    matrix `G0'   = __cvk_Gamma0
    matrix `g1'   = __cvk_garch
    matrix `G1'   = __cvk_Gamma
    matrix `Om1'  = __cvk_Om1
    if "`method'" == "qmle" {
        matrix `EV'   = __cvk_EV
        matrix `Om1s' = __cvk_Om1s
        matrix `Dl'   = __cvk_Delta
    }
    local Teff  = scalar(__cvk_T)
    local nfail = scalar(__cvk_nfail)
    local nsim  = scalar(__cvk_nsim)
    local nclip = scalar(__cvk_nclip)
    local sel0  = scalar(__cvk_sel0)
    local sel1  = scalar(__cvk_sel1)
    local sel2  = scalar(__cvk_sel2)
    foreach r of local rlist {
        if `r' > 0 {
            tempname A`r' B`r'
            matrix `A`r'' = __cvk_A`r'
            matrix `B`r'' = __cvk_B`r'
            capture matrix drop __cvk_A`r' __cvk_B`r'
        }
    }
    capture matrix drop __cvk_res __cvk_lam1 __cvk_lam2 __cvk_jlam __cvk_PiLS __cvk_PiFR
    capture matrix drop __cvk_garch0 __cvk_Gamma0 __cvk_garch __cvk_Gamma __cvk_Om1
    capture matrix drop __cvk_EV __cvk_Om1s __cvk_Delta
    capture scalar drop __cvk_T __cvk_K __cvk_nfail __cvk_nsim __cvk_nclip
    capture scalar drop __cvk_sel0 __cvk_sel1 __cvk_sel2

    // ---------------- names -----------------------------------------------
    if "`method'" == "qmle" {
        local s1 "LR_G"
        local s2 "H_G"
        local s1n "LRG"
        local s2n "HG"
        local s1lab "LR_G  (SML Thm 5.2)"
        local s2lab "H_G  (SML Thm 5.1)"
        local l1lab "lambda   (LR_G)"
        local l2lab "lambda^H (H_G)"
    }
    else {
        local s1 "W_G"
        local s2 "W*_G"
        local s1n "WG"
        local s2n "WsG"
        local s1lab "W_G  (Sin Thm 5.1)"
        local s2lab "W*_G  (Sin Cor 5.1)"
        local l1lab "lambda   (W_G)"
        local l2lab "lambda*  (W*_G)"
    }
    matrix colnames `res' = r d LRNG cv_LRNG p_LRNG `s1n' cv_`s1n' p_`s1n' `s2n' cv_`s2n' ///
        p_`s2n' cvsource cv90_LRNG cv95_LRNG cv99_LRNG cv90_`s1n' cv95_`s1n' cv99_`s1n' ///
        cv90_`s2n' cv95_`s2n' cv99_`s2n' lamclip
    local rn ""
    foreach r of local rlist {
        local rn "`rn' r`r'"
    }
    matrix rownames `res'  = `rn'
    matrix rownames `lam1' = `rn'
    matrix rownames `lam2' = `rn'
    local cn ""
    forvalues j = 1/`m' {
        local cn "`cn' lam`j'"
    }
    matrix colnames `lam1' = `cn'
    matrix colnames `lam2' = `cn'
    local yn ""
    foreach v of local varlist {
        local yn "`yn' `v'"
    }
    local gcn "a0"
    forvalues j = 1/`gq' {
        local gcn "`gcn' a`j'"
    }
    forvalues j = 1/`gp' {
        local gcn "`gcn' b`j'"
    }
    matrix colnames `g0' = `gcn'
    matrix colnames `g1' = `gcn'
    capture matrix rownames `g0' = `yn'
    capture matrix rownames `g1' = `yn'

    // ---------------- labels ----------------------------------------------
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "constant, no linear trend (SML (5.9))"
    if "`method'" == "qmle" local mlab "one-step QMLE (Sin, Mi & Ling 2024)"
    if "`method'" == "wls"  local mlab "one-step WLS (Sin c. 2004)"
    local s1d = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1d'
    local sto   : display `tfmt' `tmax'
    local lev : display %4.0g `level'
    local lev = strtrim("`lev'")
    local eta = 1 - `level'/100
    if "`cv'" == "table" {
        if "`method'" == "qmle" | "`trend'" == "rconstant" local cvlab "tabulated, SML Tables 1-3"
        else local cvlab "tabulated, Sin Tables A.1-A.2"
    }
    else local cvlab "simulated (R = `simreps', n = `simn')"

    // ---------------- main table ------------------------------------------
    di
    di as txt "Cointegration rank tests under CCC-GARCH errors" _col(60) "Number of obs = " as res %8.0f `Teff'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(60) "Variables (m) = " as res %8.0f `m'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(60) "Lags (levels) = " as res %8.0f `lags'
    di as txt "Estimator: " as res "`mlab'" as txt _col(60) "GARCH(p,q)    = " as res %8s "(`gp',`gq')"
    di as txt "Critical values: " as res "`cvlab'" as txt ", level " as res "`lev'%"
    di as txt "{hline 8}{c TT}{hline 4}{c TT}{hline 26}{c TT}{hline 25}{c TT}{hline 25}"
    di as txt _col(9) "{c |}" _col(14) "{c |}" _col(18) "Johansen LR_NG" _col(41) "{c |}" ///
        _col(44) "`s1lab'" _col(67) "{c |}" _col(70) "`s2lab'"
    di as txt "   H0: r" _col(9) "{c |}" _col(11) "d" _col(14) "{c |}" _col(16) "Statistic" ///
        _col(28) "c.v." _col(34) "p" _col(41) "{c |}" _col(42) "Statistic" _col(54) "c.v." ///
        _col(60) "p" _col(67) "{c |}" _col(68) "Statistic" _col(80) "c.v." _col(86) "p"
    di as txt "{hline 8}{c +}{hline 4}{c +}{hline 26}{c +}{hline 25}{c +}{hline 25}"
    forvalues i = 1/`ntests' {
        local r = `res'[`i', 1]
        local d = `res'[`i', 2]
        foreach k in 0 1 2 {
            local cs = 3 + 3*`k'
            local cc = 4 + 3*`k'
            local cp = 5 + 3*`k'
            local cb = 13 + 3*`k'
            local st`k' = `res'[`i', `cs']
            local cv`k' = `res'[`i', `cc']
            local pv = `res'[`i', `cp']
            local star`k' " "
            if `st`k'' > `cv`k'' & `cv`k'' < . local star`k' "*"
            if `pv' < . {
                local p`k' : display %5.3f `pv'
            }
            else {
                local c90 = `res'[`i', `cb']
                local c95 = `res'[`i', `cb' + 1]
                local c99 = `res'[`i', `cb' + 2]
                local p`k' ">.10"
                if `st`k'' > `c90' local p`k' "<.10"
                if `st`k'' > `c95' local p`k' "<.05"
                if `st`k'' > `c99' local p`k' "<.01"
                if `c90' >= . local p`k' "  . "
            }
        }
        di as txt %8.0f `r' _col(9) "{c |}" as res _col(10) %3.0f `d' as txt _col(14) "{c |}" ///
            as res _col(15) %10.3f `st0' _col(26) %7.3f `cv0' _col(34) "`p0'" as txt "`star0'" ///
            _col(41) "{c |}" as res _col(42) %9.3f `st1' _col(52) %7.3f `cv1' _col(60) "`p1'" ///
            as txt "`star1'" _col(67) "{c |}" as res _col(68) %9.3f `st2' _col(78) %7.3f `cv2' ///
            _col(86) "`p2'" as txt "`star2'"
    }
    di as txt "{hline 8}{c BT}{hline 4}{c BT}{hline 26}{c BT}{hline 25}{c BT}{hline 25}"
    if `sel0' < . {
        di as txt "Selected rank (sequential testing at the `lev'% level): LR_NG = " as res `sel0' ///
            as txt ",  `s1' = " as res `sel1' as txt ",  `s2' = " as res `sel2'
    }
    di as txt "* rejects H0: rank <= r against rank = m at the `lev'% level;  d = m - r."
    di as txt "p: simulated p-value; <.01/<.05/<.10/>.10 = bracket from the tabulated 90/95/99% values."
    if "`method'" == "qmle" {
        di as txt "LR_G: SML (5.4), limit (5.8) with lambda-hat (valid when Omega*_1 = Omega_1, e.g. Gaussian eta)."
        di as txt "H_G : SML (5.5)-(5.6), limit (5.7) with lambda-hat^H (robust to non-Gaussian eta)."
    }
    else {
        di as txt "W_G : Sin (5.2), limit (5.3) with lambda-hat (valid when the GARCH variance is correct)."
        di as txt "W*_G: Sin (5.4), limit (5.5) with lambda-hat* (robust to variance misspecification)."
    }
    di as txt "LR_NG: Johansen trace statistic; its limit is the lambda = 0 case of the same functional."
    if "`trend'" == "rconstant" {
        di as txt "Constant estimated freely under H0 and H1; limits use the demeaned Brownian motion"
        di as txt "(SML Cor. 5.1-5.2), which presumes no linear trend in the data (mu in sp(A))."
    }
    if "`cv'" == "table" & `nsim' > 0 {
        di as txt "Rows with d > 2: critical values simulated (R = `simreps', n = `simn', seed: `seeduse')."
    }
    if `nclip' > 0 {
        di as txt "Note: lambda-hat above the tabulated range (0.9) was truncated for the look-up;"
        di as txt "      the tabulated value is then conservative. Consider cv(sim)."
    }
    if `nfail' > 0 {
        di as txt "Note: " as res `nfail' as txt " univariate GARCH fit(s) did not converge; best available point used."
    }

    // ---------------- nuisance eigenvalues ----------------------------------
    di
    di as txt "Estimated nuisance eigenvalues (ascending)"
    di as txt "{hline 8}{c TT}{hline 4}{c TT}{hline 70}"
    di as txt "   H0: r" _col(9) "{c |}" _col(11) "d" _col(14) "{c |} " "`l1lab'" _col(52) "`l2lab'"
    di as txt "{hline 8}{c +}{hline 4}{c +}{hline 70}"
    forvalues i = 1/`ntests' {
        local r = `res'[`i', 1]
        local d = `res'[`i', 2]
        local t1 ""
        local t2 ""
        forvalues j = 1/`d' {
            local x : display %6.3f `lam1'[`i', `j']
            local t1 "`t1' `x'"
            local x : display %6.3f `lam2'[`i', `j']
            local t2 "`t2' `x'"
        }
        if `d' <= 5 {
            di as txt %8.0f `r' _col(9) "{c |}" as res _col(10) %3.0f `d' as txt _col(14) "{c |}" ///
                as res _col(15) "`t1'" _col(52) "`t2'"
        }
        else {
            di as txt %8.0f `r' _col(9) "{c |}" as res _col(10) %3.0f `d' as txt _col(14) "{c |}" ///
                as res _col(15) "`t1'"
            di as txt _col(9) "{c |}" _col(14) "{c |}" as res _col(15) "`t2'"
        }
    }
    di as txt "{hline 8}{c BT}{hline 4}{c BT}{hline 70}"

    // ---------------- volatility model ------------------------------------
    if "`nogarchtable'" == "" {
        local np = 1 + `gq' + `gp'
        di
        if "`method'" == "qmle" {
            di as txt "CCC-GARCH(`gp',`gq') re-estimated on the one-step full-rank residuals (delta-dot)"
        }
        else {
            di as txt "CCC-GARCH(`gp',`gq') estimated on the full-rank LS residuals (WLS weights)"
        }
        local hdr ""
        local cpos = 18
        foreach c of local gcn {
            local hdr `"`hdr' _col(`cpos') "`c'""'
            local cpos = `cpos' + 10
        }
        di as txt "{hline 14}{c TT}{hline `=10*`np' + 12'}"
        di as txt "Equation" _col(15) "{c |}" `hdr' _col(`cpos') "persist."
        di as txt "{hline 14}{c +}{hline `=10*`np' + 12'}"
        local j = 0
        foreach v of local varlist {
            local j = `j' + 1
            local line ""
            local cpos = 15
            local pers = 0
            forvalues c = 1/`np' {
                local x = `g1'[`j', `c']
                local line `"`line' _col(`cpos') %9.4f `x'"'
                local cpos = `cpos' + 10
                if `c' > 1 local pers = `pers' + `x'
            }
            local vv = abbrev("`v'", 13)
            di as txt "`vv'" _col(15) "{c |}" as res `line' _col(`cpos') %9.4f `pers'
        }
        di as txt "{hline 14}{c BT}{hline `=10*`np' + 12'}"
        di as txt "Constant conditional correlation matrix Gamma: see r(Gamma)."
    }

    // ---------------- stored results --------------------------------------
    return scalar N        = `Teff'
    return scalar m        = `m'
    return scalar lags     = `lags'
    return scalar level    = `level'
    return scalar garch_p  = `gp'
    return scalar garch_q  = `gq'
    return scalar simreps  = `simreps'
    return scalar simn     = `simn'
    return scalar nsim     = `nsim'
    return scalar garch_fail = `nfail'
    return scalar rank_LRNG  = `sel0'
    return scalar rank_`s1n' = `sel1'
    return scalar rank_`s2n' = `sel2'
    return local varlist "`varlist'"
    return local trend   "`trend'"
    return local method  "`method'"
    return local cv      "`cv'"
    return local stat1   "`s1'"
    return local stat2   "`s2'"
    return local seed    `"`seed'"'
    return local cmd     "cointvol garchrank"
    foreach r of local rlist {
        if `r' > 0 {
            return matrix A_r`r' = `A`r''
            return matrix B_r`r' = `B`r''
        }
    }
    if "`method'" == "qmle" {
        return matrix EV     = `EV'
        return matrix Omega1s = `Om1s'
        return matrix Delta  = `Dl'
    }
    return matrix Omega1      = `Om1'
    return matrix Gamma       = `G1'
    return matrix garch       = `g1'
    return matrix Gamma0      = `G0'
    return matrix garch0      = `g0'
    return matrix Pi_fr       = `PiFR'
    return matrix Pi_ls       = `PiLS'
    return matrix eigenvalues = `jlam'
    return matrix lambda2     = `lam2'
    return matrix lambda1     = `lam1'
    return matrix stats       = `res'
end
