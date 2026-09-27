*! cointvol_adaptive 0.1.0  26sep2026
*! Adaptive likelihood-ratio cointegration rank test under nonstationary volatility
*! (Boswijk & Zu 2022), with the Johansen trace test reported side by side
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_adaptive.sthlp, Methods and formulas):
*!   e_t = unrestricted OLS residuals of H(p)            -> BZ (2022) Sec 4.1
*!   Sigma_t = Gaussian-kernel smoother of e_s e_s'       -> BZ (2022) eq (19)
*!   h by leave-one-out cross-validation (Frobenius)      -> BZ (2022) eq (20)
*!   restricted estimates by GRRR switching algorithm     -> BZ (2022) eqs (9)-(10)
*!   unrestricted estimates by GLS                        -> BZ (2022) eqs (11)-(12)
*!   ALR(r) = sum_t (e~'S_t^-1 e~ - e^'S_t^-1 e^)          -> BZ (2022) eq (13)
*!   deterministics: restricted constant / trend          -> BZ (2022) eqs (17)-(18)
*!   bootstrap DGP under H(r), data initial values        -> BZ (2022) eq (21)
*!   VBS e*_t = S_t^{1/2} z_t ; WBS e*_t = e_t w_t          -> BZ (2022) Sec 4.2, Thm 3
*!   p = B^-1 sum 1(ALR* > ALR), Sigma_t not re-estimated -> BZ (2022) Sec 4.2 / Ox code
*!   Johansen trace + asymptotic / bootstrap p-values     -> Johansen (1996); BZ (2022) Tables 1, 5

program define cointvol_adaptive, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in], Lags(integer)               ///
        [ TRend(string) BW(string) KERnel(string) Method(string)            ///
          BOOTdgp(string) Reps(integer 999) SEED(string) Level(cilevel)     ///
          Rank(numlist integer >=0) TOLerance(real 1e-7) ITERate(integer 1000) ///
          NODOTS GRaph GRAPHName(string) ]

    // ---------------- load the Mata engines (core first) -------------------
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvaver", cva_version())
    if _rc {
        capture program drop cointvol_eng_adaptive
        quietly findfile cointvol_eng_adaptive.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- options --------------------------------------------
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "rconstant"
    if inlist(`"`trend'"', "n", "no", "non", "none")                        local trend "none"
    else if inlist(`"`trend'"', "rc", "rco", "rcon", "rconst", "rconstant") local trend "rconstant"
    else if inlist(`"`trend'"', "c", "co", "con", "const", "constant")      local trend "constant"
    else if inlist(`"`trend'"', "rt", "rtr", "rtrend")                      local trend "rtrend"
    else {
        di as err "trend() must be one of none, rconstant, constant, rtrend"
        exit 198
    }

    local bw = strlower(strtrim(`"`bw'"'))
    if `"`bw'"' == "" local bw "cv"
    if `"`bw'"' == "cv" {
        local bwnum 0
    }
    else {
        capture confirm number `bw'
        if _rc {
            di as err "bw() must be cv or a positive number (fraction of the sample)"
            exit 198
        }
        if `bw' <= 0 | `bw' > 10 {
            di as err "bw() must be cv or a number in (0, 10] (fraction of the sample)"
            exit 198
        }
        local bwnum = `bw'
    }

    local kernel = strlower(strtrim(`"`kernel'"'))
    if `"`kernel'"' == "" local kernel "gauss"
    if inlist(`"`kernel'"', "gaussian", "normal", "g") local kernel "gauss"
    if `"`kernel'"' != "gauss" {
        di as err "kernel() must be gauss (Gaussian kernel, as in Boswijk & Zu 2022)"
        exit 198
    }

    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "vbs wild"
    local dovbs 0
    local dowild 0
    foreach m of local method {
        if inlist("`m'", "vbs", "volatility", "vb") {
            local dovbs 1
        }
        else if inlist("`m'", "wild", "wbs", "wb") {
            local dowild 1
        }
        else {
            di as err "method() must contain vbs and/or wild"
            exit 198
        }
    }
    local method ""
    if `dovbs'  local method "vbs"
    if `dowild' local method "`method' wild"
    local method = strtrim("`method'")

    local bootdgp = strlower(strtrim(`"`bootdgp'"'))
    if `"`bootdgp'"' == "" local bootdgp "adaptive"
    if inlist(`"`bootdgp'"', "adapt", "gls", "grrr") local bootdgp "adaptive"
    if inlist(`"`bootdgp'"', "joh", "ols", "rrr")    local bootdgp "johansen"
    if !inlist(`"`bootdgp'"', "adaptive", "johansen") {
        di as err "bootdgp() must be adaptive or johansen"
        exit 198
    }
    if `lags' < 1 {
        di as err "lags() must be a positive integer (lag order of the VAR in levels)"
        exit 198
    }
    if `reps' != 0 & `reps' < 19 {
        di as err "reps() must be 0 (no bootstrap) or at least 19"
        exit 198
    }
    if `tolerance' <= 0 {
        di as err "tolerance() must be positive"
        exit 198
    }
    if `iterate' < 1 {
        di as err "iterate() must be a positive integer"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol adaptive requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol adaptive needs consecutive observations"
        exit 498
    }
    local p : word count `varlist'
    local T = `N0' - `lags'
    if `T' < `p'*`lags' + 20 {
        di as err "too few observations (" `N0' ") for p = `p' variables and `lags' lags"
        exit 2001
    }

    local maxr = `p' - 1
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
        local rlist "`rank'"
    }
    local ntests : word count `rlist'

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    local dots = ("`nodots'" == "") & (`reps' > 0)
    if `dots' {
        di as txt _n "Bootstrap replications (" as res `reps' as txt "), one dot = 50:"
    }
    mata: cva_adaptive_main("`mvars'", "`touse'", `lags', "`trend'", `bwnum', ///
        `reps', `dovbs', `dowild', "`bootdgp'", `level', `dots', "`rlist'",   ///
        `tolerance', `iterate')

    tempname res sel vol lam
    matrix `res' = __cva_res
    matrix `sel' = __cva_sel
    matrix `vol' = __cva_vol
    matrix `lam' = __cva_lam
    local Teff = scalar(__cva_T)
    local h    = scalar(__cva_h)
    local cvv  = scalar(__cva_cv)
    capture matrix drop __cva_res __cva_sel __cva_vol __cva_lam
    capture scalar drop __cva_T __cva_h __cva_cv __cva_ldet
    local hobs = `h' * `Teff'

    matrix colnames `res' = r eigenvalue trace p_asy p_plr_vbs p_plr_wbs alr ///
        p_alr_vbs p_alr_wbs iterations redrawn explosive
    local rn ""
    foreach r of local rlist {
        local rn "`rn' r`r'"
    }
    matrix rownames `res' = `rn'
    matrix colnames `sel' = plr_asy plr_vbs plr_wbs alr_vbs alr_wbs
    local cn ""
    forvalues j = 1/`p' {
        forvalues i = `j'/`p' {
            local cn "`cn' s`i'_`j'"
        }
    }
    matrix colnames `vol' = `cn'

    // ---------------- labels ----------------------------------------------
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`bootdgp'" == "adaptive" local dlab "adaptive (GRRR) restricted estimates"
    if "`bootdgp'" == "johansen" local dlab "Johansen (RRR) restricted estimates"
    local s1 = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local eta   = 1 - `level'/100
    local lev   : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local hlab  : display %7.4f `h'
    local holab : display %6.1f `hobs'
    local hl2 = strtrim("`hlab'")
    if "`bw'" == "cv" local bwlab "leave-one-out cross-validation"
    else              local bwlab "user-supplied"

    // ---------------- table -----------------------------------------------
    di
    di as txt "Adaptive cointegration rank tests" _col(52) "Number of obs  = " as res %9.0f `Teff'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Variables (p)  = " as res %9.0f `p'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags (levels)  = " as res %9.0f `lags'
    di as txt "Volatility: Gaussian kernel, h = " as res strtrim("`hlab'") ///
        as txt " (" as res strtrim("`holab'") as txt " obs.), " as res "`bwlab'"
    if `reps' > 0 {
        di as txt "Bootstrap DGP: " as res "`dlab'" as txt "   B = " as res `reps' ///
            as txt "   Seed: " as res `"`seeduse'"'
    }
    di as txt "{hline 8}{c TT}{hline 37}{c TT}{hline 29}"
    di as txt _col(9) "{c |}" _col(15) "Johansen trace (PLR)" _col(47) "{c |}" _col(53) "Adaptive LR (ALR)"
    di as txt "  H0: r" _col(9) "{c |}" _col(12) "Statistic" _col(23) "Asy.p" _col(31) "VBS.p" ///
        _col(39) "WBS.p" _col(47) "{c |}" _col(50) "Statistic" _col(61) "VBS.p" _col(69) "WBS.p"
    di as txt "{hline 8}{c +}{hline 37}{c +}{hline 29}"
    forvalues i = 1/`ntests' {
        local r = `res'[`i', 1]
        forvalues c = 3/9 {
            local v`c' = `res'[`i', `c']
        }
        foreach c in 4 5 6 8 9 {
            local s`c' = cond(`v`c'' < `eta' & `v`c'' < ., "*", " ")
        }
        di as txt %7.0f `r' _col(9) "{c |}" as res _col(11) %10.3f `v3' ///
            _col(22) %6.3f `v4' as txt "`s4'" as res _col(30) %6.3f `v5' as txt "`s5'" ///
            as res _col(38) %6.3f `v6' as txt "`s6'" _col(47) "{c |}" ///
            as res _col(49) %10.3f `v7' _col(60) %6.3f `v8' as txt "`s8'" ///
            as res _col(68) %6.3f `v9' as txt "`s9'"
    }
    di as txt "{hline 8}{c BT}{hline 37}{c BT}{hline 29}"
    local ra  = `sel'[1, 1]
    local rpv = `sel'[1, 2]
    local rpw = `sel'[1, 3]
    local rav = `sel'[1, 4]
    local raw = `sel'[1, 5]
    if `ra' < . {
        di as txt "Selected rank (sequential testing at the `lev'% level):"
        di as txt "   PLR: asymptotic = " as res `ra' as txt "   VBS = " as res `rpv' ///
            as txt "   WBS = " as res `rpw' as txt "      ALR: VBS = " as res `rav' ///
            as txt "   WBS = " as res `raw'
    }
    di as txt "* rejects H0 at the `lev'% level.  H0: rank <= r  vs  H1: rank = p.  . = not computed."
    di as txt "ALR: Gaussian likelihood with kernel volatility Sigma_t (GRRR switching algorithm),"
    di as txt "     Boswijk & Zu (2022) eq. (13); adaptive under nonstationary volatility."
    if `reps' > 0 {
        di as txt "VBS: e*_t = Sigma_t^(1/2) z_t;  WBS: e*_t = e_t w_t (unrestricted residuals);"
        di as txt "     Sigma_t is not re-estimated in the bootstrap (Boswijk & Zu 2022, Sec. 4.2)."
    }
    di as txt "Asy.p: Johansen limit (Gamma approximation); valid only under constant volatility."
    local nexp 0
    local nf 0
    local nit 0
    forvalues i = 1/`ntests' {
        if `res'[`i', 12] > 0 & `res'[`i', 12] < . local nexp = `nexp' + 1
        if `res'[`i', 11] < . local nf = `nf' + `res'[`i', 11]
        if `res'[`i', 10] >= `iterate' & `res'[`i', 10] < . local nit = `nit' + 1
    }
    if `nexp' > 0 {
        di as txt "Note: the bootstrap DGP has explosive root(s) for " as res `nexp' ///
            as txt " null rank(s); see column explosive of r(stats)."
    }
    if `nf' > 0 {
        di as txt "Note: " as res `nf' as txt " bootstrap sample(s) were singular/explosive and were redrawn."
    }
    if `nit' > 0 {
        di as txt "Note: the switching algorithm hit iterate(`iterate') for " as res `nit' ///
            as txt " rank(s); consider a larger iterate()."
    }

    // ---------------- graph (before return matrix moves) ------------------
    if "`graph'" != "" {
        preserve
        qui clear
        tempname vv
        matrix `vv' = `vol'
        qui svmat double `vv', name(sg)
        qui gen double time = `s1' + (_n - 1)*`tdelta'
        format time `tfmt'
        local glist ""
        local pos 0
        local cols "navy cranberry dkgreen dkorange purple teal maroon gs6"
        forvalues j = 1/`p' {
            forvalues i = `j'/`p' {
                local pos = `pos' + 1
                if `i' == `j' {
                    qui gen double vol`i' = sqrt(sg`pos')
                    local vn : word `i' of `varlist'
                    label variable vol`i' "`vn'"
                    local ci = mod(`i' - 1, 8) + 1
                    local cc : word `ci' of `cols'
                    local glist "`glist' (line vol`i' time, lcolor(`cc') lwidth(medthin))"
                }
            }
        }
        if `"`graphname'"' == "" local graphname "cointvol_adaptive"
        twoway `glist', graphregion(color(white)) plotregion(color(white)) ///
            title("Estimated volatilities (kernel, h = `hl2')", size(medium)) ///
            ytitle("sqrt of diagonal of Sigma_t", size(small)) xtitle("", size(small)) ///
            legend(size(small) region(lcolor(white))) ///
            note("Two-sided Gaussian kernel on unrestricted VAR residuals (Boswijk & Zu 2022, eq. 19).", size(vsmall)) ///
            name(`graphname', replace)
        restore
    }

    // ---------------- stored results --------------------------------------
    return scalar N       = `Teff'
    return scalar p       = `p'
    return scalar lags    = `lags'
    return scalar level   = `level'
    return scalar reps    = `reps'
    return scalar h       = `h'
    return scalar h_obs   = `hobs'
    return scalar cvcrit  = `cvv'
    return scalar rank_plr_asy = `ra'
    return scalar rank_plr_vbs = `rpv'
    return scalar rank_plr_wbs = `rpw'
    return scalar rank_alr_vbs = `rav'
    return scalar rank_alr_wbs = `raw'
    return local varlist  "`varlist'"
    return local trend    "`trend'"
    return local method   "`method'"
    return local bootdgp  "`bootdgp'"
    return local kernel   "gauss"
    return local bw       "`bw'"
    return local seed     `"`seed'"'
    return local cmd      "cointvol adaptive"
    return matrix stats       = `res'
    return matrix select      = `sel'
    return matrix eigenvalues = `lam'
    return matrix vol         = `vol'
end
