*! cointvol_select 0.1.0  26sep2026
*! Joint or sequential selection of the VAR lag order and the cointegration rank
*! by (adaptive) information criteria and bootstrap rank tests with estimated lag
*! (Cavaliere, De Angelis, Rahbek & Taylor 2018; Boswijk, Cavaliere, De Angelis
*! & Taylor 2023)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_select.sthlp, Methods and formulas):
*!   IC(k,r) = T log|S00(k)| + T sum_{i<=r} log(1-lam_i(k)) + c_T pi(k,r)  -> CDRT (2018) eq (3.3)
*!   pi(k,r), cases (i)-(iii) [case (iii) corrected to +p]             -> CDRT (2018) Sec 3; BCDT (2023) fn 1
*!   c_T = 2 / log T / 2 log log T                                      -> CDRT (2018) eqs (3.4)-(3.6)
*!   joint argmin over k = 1..K, r = 0..p (common sample t = K+1..T)   -> CDRT (2018) eq (3.7)
*!   sequential k-hat = argmin_k IC(k,p)                                -> CDRT (2018) eqs (3.10)-(3.11)
*!   r-hat = argmin_r IC(k-hat,r) ; IC(1,r) (Cheng-Phillips)            -> CDRT (2018) eqs (3.12)-(3.14)
*!   rank(plr|iid|wild): PLR sequence with k-hat, Algorithm 1           -> CDRT (2018) eq (3.15), Alg. 1
*!   adaptive: Sigma_t kernel on VAR(K) residuals + LOO-CV              -> BCDT (2023) eq (3.3)
*!             ALS-IC(k,r) = -2 l(k,r) + c_T pi_A(k,r), GRRR / GLS      -> BCDT (2023) eqs (3.1)-(3.2),(3.4),(3.5),(3.9)
*!             rank(vbs|wild): adaptive PLR bootstrap with k-hat        -> BCDT (2023) eqs (3.6)-(3.8)

program define cointvol_select, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in], MAXlag(integer)             ///
        [ TRend(string) IC(string) PROCedure(string) RANK(string) ADAPtive  ///
          BW(string) KERnel(string) Reps(integer 399) SEED(string)          ///
          MULTiplier(string) Level(cilevel) TOLerance(real 1e-7)            ///
          ITERate(integer 1000) NODOTS ]

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
    local adapt = ("`adaptive'" != "")
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "rconstant"
    if inlist(`"`trend'"', "n", "no", "non", "none")                        local trend "none"
    else if inlist(`"`trend'"', "rc", "rco", "rcon", "rconst", "rconstant") local trend "rconstant"
    else if inlist(`"`trend'"', "c", "co", "con", "const", "constant")      local trend "constant"
    else if inlist(`"`trend'"', "rt", "rtr", "rtrend")                      local trend "rtrend"
    else if inlist(`"`trend'"', "t", "tr", "trend")                         local trend "trend"
    else {
        di as err "trend() must be one of none, rconstant, constant, rtrend, trend"
        exit 198
    }

    local ic = strlower(`"`ic'"')
    if `"`ic'"' == "" local ic "bic hqc aic"
    local hasb 0
    local hash 0
    local hasa 0
    foreach c of local ic {
        if inlist("`c'", "bic", "sbic", "sc", "schwarz") {
            local hasb 1
        }
        else if inlist("`c'", "hqc", "hq", "hqic") {
            local hash 1
        }
        else if inlist("`c'", "aic") {
            local hasa 1
        }
        else {
            di as err "ic() must contain one or more of bic, hqc, aic"
            exit 198
        }
    }
    local icl ""
    if `hasb' local icl "`icl' bic"
    if `hash' local icl "`icl' hqc"
    if `hasa' local icl "`icl' aic"
    local icl = strtrim("`icl'")
    local ncr : word count `icl'

    local rank = strlower(strtrim(`"`rank'"'))
    if `"`rank'"' == "" local rank "ic"
    if inlist(`"`rank'"', "wb", "wbs") local rank "wild"
    if inlist(`"`rank'"', "vb", "volatility") local rank "vbs"
    if inlist(`"`rank'"', "trace", "asy") local rank "plr"
    if `adapt' {
        if !inlist(`"`rank'"', "ic", "cp", "wild", "vbs") {
            di as err "with adaptive, rank() must be ic, cp, wild or vbs"
            exit 198
        }
    }
    else {
        if !inlist(`"`rank'"', "ic", "cp", "plr", "iid", "wild") {
            di as err "rank() must be ic, cp, plr, iid or wild (vbs requires adaptive)"
            exit 198
        }
    }
    local istest = inlist(`"`rank'"', "plr", "iid", "wild", "vbs")
    local isboot = inlist(`"`rank'"', "iid", "wild", "vbs")

    local procedure = strlower(strtrim(`"`procedure'"'))
    if inlist(`"`procedure'"', "j", "jo", "joi", "join", "joint") local procedure "joint"
    if inlist(`"`procedure'"', "s", "se", "seq", "sequ", "sequential") local procedure "sequential"
    if `"`procedure'"' == "" {
        if inlist(`"`rank'"', "ic") local procedure "joint"
        else                        local procedure "sequential"
    }
    if !inlist(`"`procedure'"', "joint", "sequential") {
        di as err "procedure() must be joint or sequential"
        exit 198
    }
    if `"`procedure'"' == "joint" & `"`rank'"' != "ic" {
        di as err "rank(`rank') determines the rank given the lag k-hat of the sequential"
        di as err "procedure; specify procedure(sequential) or omit procedure()"
        exit 198
    }

    local bw = strlower(strtrim(`"`bw'"'))
    if `"`bw'"' != "" & !`adapt' {
        di as err "bw() requires the adaptive option"
        exit 198
    }
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
        di as err "kernel() must be gauss"
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
    if `adapt' & `"`multiplier'"' != "gauss" {
        di as txt "(note: multiplier() is ignored with adaptive; Gaussian multipliers are used)"
    }
    if `maxlag' < 1 {
        di as err "maxlag() must be a positive integer (maximum lag order of the VAR in levels)"
        exit 198
    }
    if `isboot' & `reps' < 19 {
        di as err "reps() must be at least 19"
        exit 198
    }
    if `tolerance' <= 0 | `iterate' < 1 {
        di as err "tolerance() must be positive and iterate() a positive integer"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol select requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol select needs consecutive observations"
        exit 498
    }
    local p : word count `varlist'
    local T = `N0' - `maxlag'
    if `T' < `p'*`maxlag' + 20 {
        di as err "too few observations (" `N0' ") for p = `p' variables and maxlag(`maxlag')"
        exit 2001
    }

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    local B = cond(`isboot', `reps', 0)
    local dots = ("`nodots'" == "") & `isboot'
    if `dots' {
        di as txt _n "Bootstrap replications (" as res `reps' as txt "), one dot = 50:"
    }
    mata: cva_select_main("`mvars'", "`touse'", `maxlag', "`trend'", "`icl'", ///
        `adapt', `bwnum', "`rank'", `B', "`multiplier'", `level', `dots',     ///
        `tolerance', `iterate')

    tempname sel tst kl
    matrix `sel' = __cva_sel
    local Teff = scalar(__cva_T)
    local h    = scalar(__cva_h)
    local cvv  = scalar(__cva_cv)
    forvalues i = 1/`ncr' {
        tempname IC`i'
        matrix `IC`i'' = __cva_IC`i'
        capture matrix drop __cva_IC`i'
    }
    if `istest' {
        matrix `tst' = __cva_tst
        matrix `kl'  = __cva_kl
        capture matrix drop __cva_tst __cva_kl
    }
    capture matrix drop __cva_sel
    capture scalar drop __cva_T __cva_h __cva_cv

    local rn ""
    forvalues k = 1/`maxlag' {
        local rn "`rn' k`k'"
    }
    local cn ""
    forvalues r = 0/`p' {
        local cn "`cn' r`r'"
    }
    forvalues i = 1/`ncr' {
        matrix rownames `IC`i'' = `rn'
        matrix colnames `IC`i'' = `cn'
    }
    matrix colnames `sel' = c_T k_joint r_joint k_seq r_ic r_cp r_test
    matrix rownames `sel' = `icl'

    // ---------------- labels ----------------------------------------------
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`trend'" == "trend"     local tlab "unrestricted trend"
    local s1 = `tmin' + `maxlag'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local lev   : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local pre ""
    if `adapt' local pre "ALS-"
    if "`rank'" == "ic"   local rlab "information criterion at k-hat"
    if "`rank'" == "cp"   local rlab "IC(1,r), Cheng-Phillips"
    if "`rank'" == "plr"  local rlab "Johansen trace, asymptotic p-values"
    if "`rank'" == "iid"  local rlab "Johansen trace, iid bootstrap (CDRT 2018, Alg. 1)"
    if "`rank'" == "wild" & !`adapt' local rlab "Johansen trace, wild bootstrap (CDRT 2018, Alg. 1)"
    if "`rank'" == "wild" & `adapt'  local rlab "adaptive PLR, wild bootstrap (BCDT 2023)"
    if "`rank'" == "vbs"             local rlab "adaptive PLR, volatility bootstrap (BCDT 2023)"

    // ---------------- header ----------------------------------------------
    di
    if `adapt' {
        di as txt "Adaptive lag and rank selection (ALS-IC)" _col(52) "Number of obs  = " as res %9.0f `Teff'
    }
    else {
        di as txt "Lag and rank selection by information criteria" _col(52) "Number of obs  = " as res %9.0f `Teff'
    }
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Variables (p)  = " as res %9.0f `p'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Max lag (K)    = " as res %9.0f `maxlag'
    if `adapt' {
        local hlab  : display %7.4f `h'
        local holab : display %6.1f `h'*`Teff'
        di as txt "Volatility: Gaussian kernel on VAR(K) residuals, h = " as res strtrim("`hlab'") ///
            as txt " (" as res strtrim("`holab'") as txt " obs.)"
    }
    di as txt "Procedure: " as res "`procedure'" as txt "   Rank step: " as res "`rlab'"

    // ---------------- IC grids --------------------------------------------
    if `p' <= 7 {
        local w = 10*(`p' + 1)
        forvalues i = 1/`ncr' {
            local c : word `i' of `icl'
            local cu = strupper("`c'")
            local kj = `sel'[`i', 2]
            local rj = `sel'[`i', 3]
            mata: st_local("__mx", strofreal(max(abs(st_matrix("`IC`i''")))))
            local fmt "%9.2f"
            if `__mx' >= 99999 local fmt "%9.0f"
            di
            di as txt "`pre'`cu'(k, r)" _col(26) "(* joint minimum)"
            di as txt "{hline 6}{c TT}{hline `w'}"
            di as txt _col(3) "k" _col(7) "{c |}" _continue
            forvalues r = 0/`p' {
                local cc = 8 + 10*`r'
                di as txt _col(`cc') %9s "r = `r'" _continue
            }
            di
            di as txt "{hline 6}{c +}{hline `w'}"
            forvalues k = 1/`maxlag' {
                di as txt %4.0f `k' _col(7) "{c |}" _continue
                forvalues r = 0/`p' {
                    local cc = 8 + 10*`r'
                    local v = `IC`i''[`k', `r' + 1]
                    local star = cond(`k' == `kj' & `r' == `rj', "*", " ")
                    di as res _col(`cc') `fmt' `v' as txt "`star'" _continue
                }
                di
            }
            di as txt "{hline 6}{c BT}{hline `w'}"
        }
    }
    else {
        di as txt "(IC grids not displayed for p > 7; see r(IC_bic), r(IC_hqc), r(IC_aic))"
    }

    // ---------------- selection summary -----------------------------------
    di
    di as txt "Selected lag order and cointegration rank"
    local hl "{hline 10}{c TT}{hline 14}{c TT}{hline 22}{c TT}{hline 10}"
    local hm "{hline 10}{c +}{hline 14}{c +}{hline 22}{c +}{hline 10}"
    local hb "{hline 10}{c BT}{hline 14}{c BT}{hline 22}{c BT}{hline 10}"
    if `istest' {
        local hl "`hl'{c TT}{hline 12}"
        local hm "`hm'{c +}{hline 12}"
        local hb "`hb'{c BT}{hline 12}"
    }
    di as txt "`hl'"
    if `istest' {
        di as txt _col(11) "{c |}" _col(13) "Joint (3.7)" _col(26) "{c |}" _col(29) "Sequential (3.10)" ///
            _col(49) "{c |}" _col(51) "Cheng-" _col(60) "{c |}" _col(62) "Test seq."
        di as txt " Criterion" _col(11) "{c |}" _col(14) "k" _col(20) "r" _col(26) "{c |}" _col(29) "k-hat" ///
            _col(37) "r-hat (IC)" _col(49) "{c |}" _col(51) "Phil. r" _col(60) "{c |}" _col(62) "r-hat"
    }
    else {
        di as txt _col(11) "{c |}" _col(13) "Joint (3.7)" _col(26) "{c |}" _col(29) "Sequential (3.10)" ///
            _col(49) "{c |}" _col(51) "Cheng-"
        di as txt " Criterion" _col(11) "{c |}" _col(14) "k" _col(20) "r" _col(26) "{c |}" _col(29) "k-hat" ///
            _col(37) "r-hat (IC)" _col(49) "{c |}" _col(51) "Phil. r"
    }
    di as txt "`hm'"
    forvalues i = 1/`ncr' {
        local c : word `i' of `icl'
        local cu = strupper("`c'")
        if `istest' {
            di as txt " `pre'`cu'" _col(11) "{c |}" as res _col(12) %3.0f `sel'[`i',2] _col(18) %3.0f `sel'[`i',3] ///
                as txt _col(26) "{c |}" as res _col(30) %3.0f `sel'[`i',4] _col(40) %3.0f `sel'[`i',5] ///
                as txt _col(49) "{c |}" as res _col(53) %3.0f `sel'[`i',6] as txt _col(60) "{c |}" ///
                as res _col(64) %3.0f `sel'[`i',7]
        }
        else {
            di as txt " `pre'`cu'" _col(11) "{c |}" as res _col(12) %3.0f `sel'[`i',2] _col(18) %3.0f `sel'[`i',3] ///
                as txt _col(26) "{c |}" as res _col(30) %3.0f `sel'[`i',4] _col(40) %3.0f `sel'[`i',5] ///
                as txt _col(49) "{c |}" as res _col(53) %3.0f `sel'[`i',6]
        }
    }
    di as txt "`hb'"
    if `adapt' {
        di as txt "ALS-IC(k,r) = sum_t log|Sigma_t| + sum_t e'Sigma_t^-1 e + c_T pi(k,r), pi without covariance"
        di as txt "   parameters; Sigma_t: kernel estimate from VAR(K) residuals (BCDT 2023, eqs 3.3-3.5)."
    }
    else {
        di as txt "IC(k,r) = T log|S00(k)| + T sum(i<=r) log(1-lam_i(k)) + c_T pi(k,r) (CDRT 2018, eq 3.3)."
    }
    di as txt "c_T: AIC 2, BIC log T, HQC 2 log log T.  All (k,r) use the common sample t = K+1,...,T."
    di as txt "BIC and HQC are consistent for (k0, r0); AIC is not (CDRT 2018, Thm 1)."

    // ---------------- sequential rank tests -------------------------------
    if `istest' {
        local nk = colsof(`kl')
        if `adapt' local stn "ALR"
        else       local stn "Trace"
        forvalues j = 1/`nk' {
            local kk = `kl'[1, `j']
            local who ""
            forvalues i = 1/`ncr' {
                if `sel'[`i', 4] == `kk' {
                    local c : word `i' of `icl'
                    local cu2 = strupper("`c'")
                    local who "`who' `pre'`cu2'"
                }
            }
            local rt = .
            forvalues i = 1/`ncr' {
                if `sel'[`i', 4] == `kk' local rt = `sel'[`i', 7]
            }
            di
            di as txt "Sequential rank tests with k-hat = " as res `kk' as txt " (selected by" as res "`who'" as txt ")"
            di as txt "{hline 8}{c TT}{hline 26}"
            di as txt "  H0: r" _col(9) "{c |}" _col(12) "`stn'" _col(26) "p-value"
            di as txt "{hline 8}{c +}{hline 26}"
            forvalues r = 0/`=`p'-1' {
                local v  = `tst'[`r'+1, 2*`j']
                local pv = `tst'[`r'+1, 2*`j'+1]
                local s  = cond(`pv' < 1 - `level'/100 & `pv' < ., "*", " ")
                di as txt %7.0f `r' _col(9) "{c |}" as res _col(11) %10.3f `v' _col(25) %6.3f `pv' as txt "`s'"
            }
            di as txt "{hline 8}{c BT}{hline 26}"
            di as txt "Selected rank (sequential testing at the `lev'% level): r-hat = " as res `rt'
        }
        di as txt "* rejects H0: rank <= r at the `lev'% level.  Method: `rlab'."
        if `isboot' {
            di as txt "Replications: " as res `reps' as txt "   Seed: " as res `"`seeduse'"'
        }
    }

    // ---------------- stored results --------------------------------------
    return scalar N      = `Teff'
    return scalar p      = `p'
    return scalar maxlag = `maxlag'
    return scalar level  = `level'
    if `isboot' {
        return scalar reps = `reps'
    }
    if `adapt' {
        return scalar h      = `h'
        return scalar h_obs  = `h'*`Teff'
        return scalar cvcrit = `cvv'
    }
    forvalues i = 1/`ncr' {
        local c : word `i' of `icl'
        return scalar k_joint_`c' = `sel'[`i', 2]
        return scalar r_joint_`c' = `sel'[`i', 3]
        return scalar k_seq_`c'   = `sel'[`i', 4]
        return scalar r_ic_`c'    = `sel'[`i', 5]
        return scalar r_cp_`c'    = `sel'[`i', 6]
        if `istest' {
            return scalar r_test_`c' = `sel'[`i', 7]
        }
        if "`procedure'" == "joint" {
            return scalar k_`c' = `sel'[`i', 2]
            return scalar r_`c' = `sel'[`i', 3]
        }
        else {
            return scalar k_`c' = `sel'[`i', 4]
            if "`rank'" == "ic" {
                return scalar r_`c' = `sel'[`i', 5]
            }
            else if "`rank'" == "cp" {
                return scalar r_`c' = `sel'[`i', 6]
            }
            else {
                return scalar r_`c' = `sel'[`i', 7]
            }
        }
    }
    return local varlist    "`varlist'"
    return local trend      "`trend'"
    return local ic         "`icl'"
    return local procedure  "`procedure'"
    return local rank       "`rank'"
    return local adaptive   "`adaptive'"
    if `adapt' {
        return local bw     "`bw'"
        return local kernel "gauss"
    }
    if `isboot' & !`adapt' {
        return local multiplier "`multiplier'"
    }
    return local seed       `"`seed'"'
    return local cmd        "cointvol select"
    if `istest' {
        local cn "r"
        forvalues j = 1/`=colsof(`kl')' {
            local kk = `kl'[1, `j']
            local cn "`cn' stat_k`kk' p_k`kk'"
        }
        matrix colnames `tst' = `cn'
        local rn ""
        forvalues r = 0/`=`p'-1' {
            local rn "`rn' r`r'"
        }
        matrix rownames `tst' = `rn'
        return matrix tests = `tst'
    }
    return matrix select = `sel'
    forvalues i = 1/`ncr' {
        local c : word `i' of `icl'
        return matrix IC_`c' = `IC`i''
    }
end
