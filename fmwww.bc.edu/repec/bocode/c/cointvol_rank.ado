*! cointvol_rank 0.1.0  26sep2026
*! Cointegration-rank tests robust to conditional and nonstationary volatility
*! Johansen trace / max-eigenvalue with asymptotic, iid-bootstrap and
*! wild-bootstrap inference (Cavaliere, Rahbek & Taylor 2010, 2012, 2014;
*! Swensen 2006; Cavaliere, De Angelis, Rahbek & Taylor 2018)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_rank.sthlp, section Methods):
*!   Z0/Z1/Z2 moment matrices, S_ij, eigenproblem |lam S11 - S10 S00^-1 S01| = 0
*!       -> Johansen (1996); CRT (2010) eqs (3),(7)
*!   Q_r = -T sum_{i>r} log(1-lam_i);  Q_r,max = -T log(1-lam_{r+1})
*!       -> CRT (2010) eq (8), Remark 3.5
*!   algorithm(crt14): all estimates from H(r), recentred residuals, data initial
*!       values, deterministics in the recursion -> CDRT (2018) Algorithm 1 = CRT (2012, 2014)
*!   algorithm(crt10): alpha,beta from H(r); Gamma, unrestricted deterministics and
*!       residuals from H(p) -> CRT (2010) Algorithm 1; iid version = Swensen (2006)
*!   p-value: strict  p = B^-1 sum 1(Q* > Q)   -> CRT (2010) Remark 4.4
*!            plusone p = (#{Q* >= Q} + 1)/(B+1) -> VARtests convention
*!   sequential: first H(r) with p > 1-level/100 -> CRT (2010) fn 1; CDRT (2018) Alg 1 (iv)

program define cointvol_rank, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in], Lags(integer) ///
        [ TRend(string) Method(string) ALGorithm(string) MULTiplier(string) ///
          Reps(integer 999) SEED(string) Level(cilevel) PVALue(string)    ///
          Rank(numlist integer >=0) SAVing(string) NODOTS CV GRaph         ///
          GRAPHName(string) ]

    // ---------------- load / reload the Mata engine ----------------------
    // (Mata code in an autoloaded ado is private to that file, so the engine
    //  is -run- as a do-file, which compiles its functions globally.)
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- options --------------------------------------------
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "rconstant"
    if inlist(`"`trend'"', "n", "no", "non", "none")                    local trend "none"
    else if inlist(`"`trend'"', "rc", "rco", "rcon", "rconst", "rconstant") local trend "rconstant"
    else if inlist(`"`trend'"', "c", "co", "con", "const", "constant")  local trend "constant"
    else if inlist(`"`trend'"', "rt", "rtr", "rtrend")                  local trend "rtrend"
    else if inlist(`"`trend'"', "t", "tr", "trend")                     local trend "trend"
    else {
        di as err "trend() must be one of none, rconstant, constant, rtrend, trend"
        exit 198
    }

    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "wild"
    if !inlist(`"`method'"', "asy", "iid", "wild") {
        di as err "method() must be asy, iid or wild"
        exit 198
    }
    local algorithm = strlower(strtrim(`"`algorithm'"'))
    if `"`algorithm'"' == "" local algorithm "crt14"
    if !inlist(`"`algorithm'"', "crt14", "crt10") {
        di as err "algorithm() must be crt14 or crt10"
        exit 198
    }
    local multiplier = strlower(strtrim(`"`multiplier'"'))
    if `"`multiplier'"' == "" local multiplier "gauss"
    if inlist(`"`multiplier'"', "gaussian", "normal", "n") local multiplier "gauss"
    if inlist(`"`multiplier'"', "rad", "r")                 local multiplier "rademacher"
    if inlist(`"`multiplier'"', "mam", "m")                 local multiplier "mammen"
    if !inlist(`"`multiplier'"', "gauss", "rademacher", "mammen") {
        di as err "multiplier() must be gauss, rademacher or mammen"
        exit 198
    }
    if `"`method'"' != "wild" & `"`multiplier'"' != "gauss" {
        di as txt "(note: multiplier() is ignored unless method(wild))"
    }
    local pvalue = strlower(strtrim(`"`pvalue'"'))
    if `"`pvalue'"' == "" local pvalue "strict"
    if !inlist(`"`pvalue'"', "strict", "plusone") {
        di as err "pvalue() must be strict or plusone"
        exit 198
    }
    if `lags' < 1 {
        di as err "lags() must be a positive integer (lag order of the VAR in levels)"
        exit 198
    }
    if `"`method'"' != "asy" & `reps' < 19 {
        di as err "reps() must be at least 19"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol rank requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol rank needs consecutive observations"
        exit 498
    }
    local p : word count `varlist'
    local T = `N0' - `lags'
    if `T' < `p'*`lags' + 10 {
        di as err "too few observations (" `N0' ") for p = `p' variables and `lags' lags"
        exit 2001
    }

    // tests requested
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

    // seed
    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    // ts-operated variables -> temporary variables for Mata
    tsrevar `varlist'
    local mvars "`r(varlist)'"

    local dots = ("`nodots'" == "") & ("`method'" != "asy")
    if `dots' {
        di as txt _n "Bootstrap replications (" as res `reps' as txt "), one dot = 50:"
    }
    mata: cv_rank_main("`mvars'", "`touse'", `lags', "`trend'", "`method'", ///
        "`algorithm'", "`multiplier'", `reps', "`pvalue'", `level', `dots', "`rlist'")

    tempname res lam beta QT QM
    matrix `res'  = __cv_res
    matrix `lam'  = __cv_lam
    matrix `beta' = __cv_beta
    local Teff    = scalar(__cv_T)
    local rat     = scalar(__cv_rat)
    local rbt     = scalar(__cv_rbt)
    local ram     = scalar(__cv_ram)
    local rbm     = scalar(__cv_rbm)
    capture matrix drop __cv_res __cv_lam __cv_beta
    capture scalar drop __cv_T __cv_p __cv_rat __cv_rbt __cv_ram __cv_rbm
    if "`method'" != "asy" {
        matrix `QT' = __cv_QT
        matrix `QM' = __cv_QM
        capture matrix drop __cv_QT __cv_QM
    }
    matrix colnames `res' = r eigenvalue trace p_asy_tr p_boot_tr cv_asy_tr cv_boot_tr ///
        maxeig p_asy_mx p_boot_mx cv_asy_mx cv_boot_mx explosive fails
    local rn ""
    foreach r of local rlist {
        local rn "`rn' r`r'"
    }
    matrix rownames `res' = `rn'

    // ---------------- labels ----------------------------------------------
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`trend'" == "trend"     local tlab "unrestricted trend"
    if "`method'" == "asy"  local mlab "asymptotic only"
    if "`method'" == "iid"  local mlab "iid bootstrap"
    if "`method'" == "wild" local mlab "wild bootstrap"
    if "`algorithm'" == "crt14" local alab "CRT (2012/2014): restricted estimates"
    if "`algorithm'" == "crt10" local alab "CRT (2010): unrestricted Gamma, residuals"
    if "`method'" == "iid" & "`algorithm'" == "crt10" local alab "Swensen (2006)"
    local s1 = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local eta   = 1 - `level'/100
    local lev   : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")

    // ---------------- table -----------------------------------------------
    di
    di as txt "Cointegration rank tests" _col(52) "Number of obs  = " as res %9.0f `Teff'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Variables (p)  = " as res %9.0f `p'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags (levels)  = " as res %9.0f `lags'
    if "`method'" != "asy" {
        di as txt "Inference: " as res "`mlab'" as txt ", " as res "`alab'"
        if "`method'" == "wild" {
            di as txt "Multiplier: " as res "`multiplier'" as txt "   Replications: " as res `reps' ///
                as txt "   Seed: " as res `"`seeduse'"'
        }
        else {
            di as txt "Replications: " as res `reps' as txt "   Seed: " as res `"`seeduse'"'
        }
    }
    di as txt "{hline 9}{c TT}{hline 37}{c TT}{hline 30}"
    di as txt _col(10) "{c |}" _col(24) "Trace test" _col(48) "{c |}" _col(56) "Max-eigenvalue test"
    di as txt "   H0: r" _col(10) "{c |}" _col(12) "Eigenval." _col(23) "Statistic" _col(34) "Asy.p" ///
        _col(41) "Boot.p" _col(48) "{c |}" _col(51) "Statistic" _col(63) "Asy.p" _col(70) "Boot.p"
    di as txt "{hline 9}{c +}{hline 37}{c +}{hline 30}"
    forvalues i = 1/`ntests' {
        local r   = `res'[`i', 1]
        local ev  = `res'[`i', 2]
        local qt  = `res'[`i', 3]
        local pat = `res'[`i', 4]
        local pbt = `res'[`i', 5]
        local qm  = `res'[`i', 8]
        local pam = `res'[`i', 9]
        local pbm = `res'[`i', 10]
        local s_at = cond(`pat' < `eta', "*", " ")
        local s_bt = cond(`pbt' < `eta' & `pbt' < ., "*", " ")
        local s_am = cond(`pam' < `eta', "*", " ")
        local s_bm = cond(`pbm' < `eta' & `pbm' < ., "*", " ")
        if "`method'" == "asy" {
            di as txt %8.0f `r' _col(10) "{c |}" as res _col(11) %9.4f `ev' _col(22) %10.3f `qt' ///
                _col(33) %6.3f `pat' as txt "`s_at'" _col(46) "." _col(48) "{c |}" ///
                as res _col(50) %10.3f `qm' _col(62) %6.3f `pam' as txt "`s_am'" _col(75) "."
        }
        else {
            di as txt %8.0f `r' _col(10) "{c |}" as res _col(11) %9.4f `ev' _col(22) %10.3f `qt' ///
                _col(33) %6.3f `pat' as txt "`s_at'" as res _col(40) %6.3f `pbt' as txt "`s_bt'" ///
                _col(48) "{c |}" as res _col(50) %10.3f `qm' _col(62) %6.3f `pam' as txt "`s_am'" ///
                as res _col(69) %6.3f `pbm' as txt "`s_bm'"
        }
    }
    di as txt "{hline 9}{c BT}{hline 37}{c BT}{hline 30}"
    if `rat' < . {
        di as txt "Selected rank (sequential testing at the `lev'% level):"
        if "`method'" == "asy" {
            di as txt "   trace: " as res `rat' as txt "      max-eigenvalue: " as res `ram'
        }
        else {
            di as txt "   trace:          asymptotic = " as res `rat' as txt "   bootstrap = " as res `rbt'
            di as txt "   max-eigenvalue: asymptotic = " as res `ram' as txt "   bootstrap = " as res `rbm'
        }
    }
    di as txt "* rejects H0 at the `lev'% level.  H0: rank <= r  vs  H1: rank = p (trace) or rank = r+1 (max-eig)."
    di as txt "Asymptotic p-values: Gamma approximation to the Johansen limit (Doornik 1998), moments simulated."
    if "`method'" == "wild" {
        di as txt "Wild bootstrap valid under conditional and nonstationary (unconditional) heteroskedasticity."
    }
    if "`method'" == "iid" {
        di as txt "iid bootstrap valid under conditional heteroskedasticity only, not under nonstationary volatility."
    }
    if "`method'" != "asy" {
        local nexp 0
        local rexp ""
        forvalues i = 1/`ntests' {
            if `res'[`i', 13] > 0 & `res'[`i', 13] < . {
                local nexp = `nexp' + 1
                local rexp "`rexp' `=`res'[`i',1]'"
            }
        }
        if `nexp' > 0 {
            di as txt "Note: the estimated bootstrap DGP has explosive root(s) under H0: r =`rexp';"
            di as txt "      CDRT (2018) show this can be ignored asymptotically (Cavaliere, Taylor & Trenkler 2015)."
        }
        local nf 0
        forvalues i = 1/`ntests' {
            local nf = `nf' + `res'[`i', 14]
        }
        if `nf' > 0 {
            di as txt "Note: " as res `nf' as txt " bootstrap sample(s) were singular/explosive and were redrawn."
        }
    }

    if "`cv'" != "" {
        di
        di as txt "Critical values at the `lev'% level"
        di as txt "{hline 9}{c TT}{hline 24}{c TT}{hline 24}"
        di as txt "   H0: r {c |}  Trace: asy.    boot.  {c |}  Maxeig: asy.   boot."
        di as txt "{hline 9}{c +}{hline 24}{c +}{hline 24}"
        forvalues i = 1/`ntests' {
            di as txt %8.0f `res'[`i',1] " {c |} " as res %10.3f `res'[`i',6] " " %9.3f `res'[`i',7] ///
                as txt "   {c |} " as res %10.3f `res'[`i',11] " " %9.3f `res'[`i',12]
        }
        di as txt "{hline 9}{c BT}{hline 24}{c BT}{hline 24}"
        di as txt "(asymptotic critical values are always at the 5% level)"
    }

    // ---------------- saving / graph (before return matrix moves) ---------
    if "`method'" != "asy" & (`"`saving'"' != "" | "`graph'" != "") {
        preserve
        qui clear
        local cn ""
        foreach r of local rlist {
            local cn "`cn' trace_r`r'"
        }
        matrix colnames `QT' = `cn'
        local cn ""
        foreach r of local rlist {
            local cn "`cn' maxeig_r`r'"
        }
        matrix colnames `QM' = `cn'
        qui svmat double `QT', names(col)
        qui svmat double `QM', names(col)
        qui gen long rep = _n
        order rep
        if "`graph'" != "" {
            local glist ""
            local i 0
            foreach r of local rlist {
                local i = `i' + 1
                local obs = `res'[`i', 3]
                local pb  : display %5.3f `res'[`i', 5]
                local ob  : display %8.2f `obs'
                tempname g`i'
                qui twoway (histogram trace_r`r', color(ltbluishgray) lcolor(gs10)) ///
                    (kdensity trace_r`r', lcolor(navy) lwidth(medthin)), ///
                    xline(`obs', lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                    title("H0: r = `r'", size(medsmall)) ///
                    subtitle("Q = `ob', bootstrap p = `pb'", size(small)) ///
                    xtitle("bootstrap trace statistic", size(small)) ytitle("density", size(small)) ///
                    legend(off) graphregion(color(white)) plotregion(color(white)) ///
                    name(`g`i'', replace) nodraw
                local glist "`glist' `g`i''"
            }
            if `"`graphname'"' == "" local graphname "cointvol_rank"
            graph combine `glist', graphregion(color(white)) ///
                title("Bootstrap distributions of the trace statistic", size(medium)) ///
                note("Dashed line: observed statistic. `mlab' (`algorithm'), B = `reps'.", size(vsmall)) ///
                name(`graphname', replace)
        }
        if `"`saving'"' != "" {
            qui save `saving'
        }
        restore
    }

    // ---------------- stored results --------------------------------------
    return scalar N        = `Teff'
    return scalar p        = `p'
    return scalar lags     = `lags'
    return scalar level    = `level'
    if "`method'" != "asy" {
        return scalar reps = `reps'
    }
    return scalar rank_asy_trace  = `rat'
    return scalar rank_asy_max    = `ram'
    if "`method'" != "asy" {
        return scalar rank_boot_trace = `rbt'
        return scalar rank_boot_max   = `rbm'
    }
    return local varlist    "`varlist'"
    return local trend      "`trend'"
    return local method     "`method'"
    return local algorithm  "`algorithm'"
    return local multiplier "`multiplier'"
    return local pvalue     "`pvalue'"
    return local seed       `"`seed'"'
    return local cmd        "cointvol rank"
    return matrix stats       = `res'
    return matrix eigenvalues = `lam'
    return matrix beta        = `beta'
    if "`method'" != "asy" {
        return matrix boot_trace = `QT'
        return matrix boot_max   = `QM'
    }
end
