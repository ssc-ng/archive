*! cointvol_vecmgarch_estat 0.1.0  26sep2026
*! estat after -cointvol vecmgarch-: moments, garchx, diagonal, effgain, ranklr, archlm
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!   moments  : BEKK covariance stationarity rho(sum A#A + sum G#G) < 1   BDV (1997) eq (8);
*!              Engle & Kroner (1995) Prop 2.7; GARCH 4th moment rho(E A_t#A_t) < 1,
*!              = 3a^2+2ab+b^2 < 1 for GARCH(1,1)                          Bollerslev (1986); SML (2024) Ass 2.4
*!   garchx   : LR GARCH vs homoskedastic, LR GARCH-X vs GARCH (df 3 for p=2), robust
*!              Wald on D, LM T R^2 of e_i^2 - h_ii on z^2_{t-1}           Lee (1994) Tables 1-3, fn 3
*!   diagonal : Wald test that the off-diagonal BEKK elements are zero    BDV (1997) Table 5
*!   effgain  : g_j = [s + (kappa-1) H] / [s + 2H]^2                        Seo (2007) eq (21)
*!   ranklr   : LR across ranks, Johansen asymptotic critical values
*!              (validity conjectured)                                    BDV (1997) Sec 4.2, Table 3
*!   archlm   : Engle ARCH-LM on standardised residuals                   WLL (2005) Table 11

program define cointvol_vecmgarch_estat, rclass sortpreserve
    version 14.0
    if `"`e(cmd)'"' != "cointvol vecmgarch" {
        di as err "last estimates not found; run cointvol vecmgarch first"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = strlower(`"`sub'"')
    local l = strlen(`"`sub'"')
    local target ""
    foreach s in moments:3 garchx:6 diagonal:4 effgain:3 ranklr:4 archlm:4 {
        gettoken nm ml : s, parse(":")
        local ml = subinstr("`ml'", ":", "", 1)
        if `l' >= `ml' & `"`sub'"' == substr("`nm'", 1, `l') {
            local target "`nm'"
        }
    }
    if "`target'" == "" {
        estat_default `0'
        return add
        exit
    }

    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvgver", cvg_version())
    if _rc {
        capture program drop cointvol_eng_vecmgarch
        quietly findfile cointvol_eng_vecmgarch.ado
        quietly run `"`r(fn)'"'
    }

    // data objects shared by the subcommands (created here so that they persist)
    local tvar "`e(timevar)'"
    qui tsset
    sort `tvar'
    tempvar win es
    qui gen byte `win' = inrange(`tvar', e(tmin), e(tmax))
    qui gen byte `es' = e(sample)
    tsrevar `e(varlist)'
    local mvars "`r(varlist)'"
    local xl ""
    if "`e(xmode)'" == "vars" {
        tsrevar L.(`e(xvars)')
        local xl "`r(varlist)'"
    }
    local rest = strtrim(`"`rest'"')
    if substr(`"`rest'"', 1, 1) != "," {
        local rest `", `rest'"'
    }
    _cvg_estat_`target' `rest' mv(`mvars') win(`win') es(`es') xl(`xl')
    return add
end

// ---------------------------------------------------------------------------
program define _cvg_estat_moments, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) ]
    local v "`e(variance)'"
    if "`v'" == "none" {
        di as err "estat moments requires a conditionally heteroskedastic variance model"
        exit 498
    }
    foreach m in eig mom Su Se kap {
        capture matrix drop __cvg_`m'
    }
    mata: cvg_moments("`mv'", "`win'", "`es'", "`xl'")
    tempname eig mom Su Se kap
    matrix `eig' = __cvg_eig
    matrix `Su'  = __cvg_Su
    matrix `Se'  = __cvg_Se
    matrix `kap' = __cvg_kap
    local hasm 0
    capture confirm matrix __cvg_mom
    if !_rc {
        local hasm 1
        matrix `mom' = __cvg_mom
    }
    foreach m in eig mom Su Se kap {
        capture matrix drop __cvg_`m'
    }
    local dn ""
    foreach e in `e(eqnames)' {
        local dn "`dn' `=substr("`e'", 3, .)'"
    }
    local p = e(p)
    di
    di as txt "Moment conditions of the fitted variance model: " as res "`e(vlabel)'"
    local ne = rowsof(`eig')
    local rho = `eig'[1, 1]
    if inlist("`v'", "dbekk", "bekk") {
        di as txt "Covariance stationarity: moduli of the eigenvalues of sum A#A + sum G#G"
        di as txt "  (Bauwens, Deprins & Vandeuren 1997, eq. 8; Engle & Kroner 1995, Prop. 2.7)"
    }
    else if "`v'" == "ecccgarch" {
        di as txt "Covariance stationarity: moduli of the eigenvalues of A + B (Wong, Li & Ling 2005, Sec. 2)"
    }
    else {
        di as txt "Covariance stationarity: sum of ARCH and GARCH coefficients per equation"
    }
    local txt ""
    forvalues i = 1/`ne' {
        local vv : display %7.4f `eig'[`i', 1]
        local txt "`txt' `vv'"
    }
    di as txt "  " as res "`txt'"
    local stat "yes"
    if `rho' >= 1 local stat "NO (unconditional covariance does not exist)"
    di as txt "  largest = " as res %7.4f `rho' as txt "  -> covariance stationary: " as res "`stat'"
    if `hasm' {
        di
        di as txt "Per-equation (own) GARCH coefficients and fourth-moment condition"
        di as txt "  rho4 = spectral radius of E(A_t # A_t); finite 4th moment iff rho4 < 1"
        di as txt "  (GARCH(1,1): rho4 = kappa a{c 94}2 + 2ab + b{c 94}2; Bollerslev 1986; Sin, Mi & Ling 2024, Ass. 2.4)"
        di as txt "{hline 14}{c TT}{hline 62}"
        di as txt _col(15) "{c |}" _col(20) "ARCH" _col(29) "GARCH" _col(37) "Persist." _col(47) "rho4(normal)" ///
            _col(61) "rho4(kappa^)" _col(74) "kappa^"
        di as txt "{hline 14}{c +}{hline 62}"
        local lab "`dn'"
        if "`v'" == "trigarch" {
            local lab ""
            forvalues j = 1/`p' {
                local lab "`lab' e`j'"
            }
        }
        forvalues i = 1/`p' {
            local nm : word `i' of `lab'
            local nm = abbrev("`nm'", 13)
            di as txt %13s "`nm'" " {c |}" as res _col(17) %7.4f `mom'[`i', 1] _col(27) %7.4f `mom'[`i', 2] ///
                _col(37) %7.4f `mom'[`i', 3] _col(49) %7.4f `mom'[`i', 4] _col(63) %7.4f `mom'[`i', 5] ///
                _col(72) %7.3f `mom'[`i', 6]
        }
        di as txt "{hline 14}{c BT}{hline 62}"
        di as txt "kappa^ = sample kurtosis of the standardised residuals (normal: 3)."
        if "`v'" == "dbekk" {
            di as txt "Diagonal BEKK: own ARCH = a_i{c 94}2, own GARCH = b_i{c 94}2 (h_ii is a univariate GARCH(1,1) in e_i)."
        }
        matrix colnames `mom' = arch garch persist rho4_normal rho4_kappa kappa
        matrix rownames `mom' = `lab'
    }
    if "`v'" == "bekk" {
        di as txt "(fourth-moment conditions of the full BEKK are not computed)"
    }
    matrix rownames `Su' = `dn'
    matrix colnames `Su' = `dn'
    matrix rownames `Se' = `dn'
    matrix colnames `Se' = `dn'
    di
    di as txt "Implied unconditional covariance of e_t (missing if not stationary or not available):"
    matlist `Su', format(%11.0g) border(rows)
    di as txt "Sample covariance of the residuals:"
    matlist `Se', format(%11.0g) border(rows)
    return scalar rho = `rho'
    return matrix eig = `eig'
    if `hasm' {
        return matrix moments = `mom'
    }
    return matrix Sigma_u = `Su'
    return matrix Sigma_e = `Se'
    return matrix kappa = `kap'
end

// ---------------------------------------------------------------------------
program define _cvg_estat_garchx, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) ]
    local v "`e(variance)'"
    if "`v'" == "none" {
        di as err "estat garchx requires a GARCH-type variance model"
        exit 498
    }
    if e(rank_int) == 0 | "`e(rmode)'" == "full" {
        di as err "estat garchx needs error-correction terms (1 <= rank < p)"
        exit 498
    }
    local p   = e(p)
    local np  = `p'*(`p'+1)/2
    local ll  = e(ll)
    local ll0 = e(ll_0)
    local kv  = e(k_var)
    local N   = e(N)
    local hasx = ("`e(xmode)'" != "none")
    local ndd = e(nx) * `np'
    local ll2 = `ll'
    local conv2 = e(converged)
    local lmsrc "model in memory"
    tempname LM W
    if `hasx' {
        // D coefficients for the robust Wald test (model in memory)
        local dlist ""
        local cn : colfullnames e(b)
        foreach c of local cn {
            gettoken eq nm : c, parse(":")
            if substr("`eq'", 1, 3) == "X_D" {
                local nm = substr(`"`nm'"', 2, .)
                local dlist "`dlist' [`eq']`nm'"
            }
        }
        local wd = .
        local wdf = .
        local wp = .
        if "`e(vce)'" != "none" {
            qui test `dlist'
            local wd = r(chi2)
            local wdf = r(df)
            local wp = r(p)
        }
        // refit without the X term
        local vars "`e(varlist)'"
        local tv "`e(timevar)'"
        local t0 = e(tmin)
        local t1 = e(tmax)
        local oc "`e(opt_core)'"
        local om "`e(opt_mean)'"
        tempname hold
        _estimates hold `hold', restore
        di as txt "(refitting the model without the GARCH-X term ...)"
        capture noisily quietly cointvol_vecmgarch `vars' if inrange(`tv', `t0', `t1'), ///
            `oc' `om' novce nonconvok nolog
        if _rc {
            di as err "the restricted (no GARCH-X) model could not be estimated"
            exit _rc
        }
        local ll2 = e(ll)
        local conv2 = e(converged)
        local lmsrc "model without GARCH-X (refitted)"
        capture matrix drop __cvg_lmx
        mata: cvg_lmx("`mv'", "`win'", "`es'", "`xl'")
        matrix `LM' = __cvg_lmx
        capture matrix drop __cvg_lmx
        _estimates unhold `hold'
    }
    else {
        capture matrix drop __cvg_lmx
        mata: cvg_lmx("`mv'", "`win'", "`es'", "`xl'")
        matrix `LM' = __cvg_lmx
        capture matrix drop __cvg_lmx
    }
    local df21 = `kv' - `ndd' - `np'
    local lr21 = 2*(`ll2' - `ll0')
    local p21  = chi2tail(`df21', `lr21')
    di
    di as txt "GARCH-X diagnostics (Lee 1994, JIMF 13, Tables 1-3)"
    di as txt "{hline 44}{c TT}{hline 33}"
    di as txt _col(45) "{c |}" _col(48) "logL / stat" _col(63) "df" _col(70) "p-value"
    di as txt "{hline 44}{c +}{hline 33}"
    di as txt "Model 1: homoskedastic ECM (LS/RRR)" _col(45) "{c |}" as res _col(46) %13.3f `ll0'
    di as txt "Model 2: ECM + `e(vlabel)'" _col(45) "{c |}" as res _col(46) %13.3f `ll2'
    if `hasx' {
        di as txt "Model 3: ECM + GARCH-X (in memory)" _col(45) "{c |}" as res _col(46) %13.3f `ll'
    }
    di as txt "LR Model 2 vs 1 (GARCH vs homoskedastic)" _col(45) "{c |}" as res _col(46) %13.3f `lr21' ///
        _col(61) %4.0f `df21' _col(69) %7.4f `p21'
    if `hasx' {
        local lr32 = 2*(`ll' - `ll2')
        local p32  = chi2tail(`ndd', `lr32')
        di as txt "LR Model 3 vs 2 (GARCH-X vs GARCH)" _col(45) "{c |}" as res _col(46) %13.3f `lr32' ///
            _col(61) %4.0f `ndd' _col(69) %7.4f `p32'
        di as txt "Robust Wald: D = 0" _col(45) "{c |}" as res _col(46) %13.3f `wd' _col(61) %4.0f `wdf' ///
            _col(69) %7.4f `wp'
    }
    di as txt "{hline 44}{c BT}{hline 33}"
    di
    di as txt "LM test for GARCH-X: T R{c 94}2 (uncentred) of e_i{c 94}2 - h_ii on z{c 94}2(t-1), chi2(1)"
    di as txt "  h_ii from the " as res "`lmsrc'" as txt "; ARCH[0]-X uses a constant variance"
    di as txt "{hline 20}{c TT}{hline 22}{c TT}{hline 22}"
    di as txt _col(21) "{c |}" _col(24) "GARCH-X (model h)" _col(44) "{c |}" _col(48) "ARCH[0]-X"
    di as txt "  equation   ECT" _col(21) "{c |}" _col(25) "T R2" _col(35) "p-value" _col(44) "{c |}" ///
        _col(48) "T R2" _col(58) "p-value"
    di as txt "{hline 20}{c +}{hline 22}{c +}{hline 22}"
    local nr = rowsof(`LM')
    local vl "`e(varlist)'"
    forvalues i = 1/`nr' {
        local w : word `=`LM'[`i',1]' of `vl'
        local w = abbrev("`w'", 10)
        di as txt "  " %-10s "`w'" %4.0f `LM'[`i', 2] _col(21) "{c |}" as res _col(22) %9.3f `LM'[`i', 3] ///
            _col(35) %7.4f `LM'[`i', 4] as txt _col(44) "{c |}" as res _col(45) %9.3f `LM'[`i', 5] ///
            _col(58) %7.4f `LM'[`i', 6]
    }
    di as txt "{hline 20}{c BT}{hline 22}{c BT}{hline 22}"
    di as txt "Notes: LR and LM tests assume conditional normality (Lee 1994, fn 3); only the robust Wald"
    di as txt "  test is valid under non-normal errors. Under the D'D parameterisation the score is zero at"
    di as txt "  D = 0, so the LR and Wald tests of D = 0 are non-standard (boundary / singular information)."
    if `conv2' == 0 {
        di as err "Warning: the refitted model without GARCH-X did not converge."
    }
    matrix colnames `LM' = equation ect lm_model p_model lm_arch0 p_arch0
    return scalar ll_1 = `ll0'
    return scalar ll_2 = `ll2'
    return scalar lr21 = `lr21'
    return scalar df21 = `df21'
    return scalar p21  = `p21'
    if `hasx' {
        return scalar ll_3 = `ll'
        return scalar lr32 = `lr32'
        return scalar df32 = `ndd'
        return scalar p32  = `p32'
        return scalar wald = `wd'
        return scalar wald_df = `wdf'
        return scalar wald_p = `wp'
    }
    return matrix lm = `LM'
end

// ---------------------------------------------------------------------------
program define _cvg_estat_diagonal, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) ]
    local v "`e(variance)'"
    if !inlist("`v'", "bekk", "ecccgarch") {
        di as err "estat diagonal requires variance(bekk) or variance(ecccgarch)"
        exit 498
    }
    if "`e(vce)'" == "none" {
        di as err "estat diagonal requires e(V)"
        exit 498
    }
    local p = e(p)
    local la ""
    local lg ""
    if "`v'" == "bekk" {
        forvalues l = 1/`=e(arch)' {
            forvalues i = 1/`p' {
                forvalues j = 1/`p' {
                    if `i' != `j' local la "`la' [A`l']a`i'_`j'"
                }
            }
        }
        forvalues l = 1/`=e(garch)' {
            forvalues i = 1/`p' {
                forvalues j = 1/`p' {
                    if `i' != `j' local lg "`lg' [G`l']g`i'_`j'"
                }
            }
        }
    }
    else {
        local k 0
        foreach e in `e(eqnames)' {
            local k = `k' + 1
            local nm = substr("`e'", 3, .)
            forvalues j = 1/`p' {
                if `j' != `k' local la "`la' [V_`nm']arch`j'"
            }
        }
    }
    di
    di as txt "Wald tests of diagonality (" as res "`e(vlabel)'" as txt "; " as res "`e(vcetype)'" as txt " variance)"
    di as txt "{hline 40}{c TT}{hline 30}"
    di as txt _col(41) "{c |}" _col(45) "chi2" _col(55) "df" _col(62) "p-value"
    di as txt "{hline 40}{c +}{hline 30}"
    qui test `la'
    local c1 = r(chi2)
    local d1 = r(df)
    local p1 = r(p)
    local lab "off-diagonal ARCH (A) elements = 0"
    di as txt "`lab'" _col(41) "{c |}" as res _col(42) %9.3f `c1' _col(53) %4.0f `d1' _col(61) %7.4f `p1'
    return scalar chi2_A = `c1'
    return scalar df_A = `d1'
    return scalar p_A = `p1'
    if "`lg'" != "" {
        qui test `lg'
        local c2 = r(chi2)
        local d2 = r(df)
        local p2 = r(p)
        di as txt "off-diagonal GARCH (G) elements = 0" _col(41) "{c |}" as res _col(42) %9.3f `c2' _col(53) %4.0f `d2' ///
            _col(61) %7.4f `p2'
        qui test `la' `lg'
        local c3 = r(chi2)
        local d3 = r(df)
        local p3 = r(p)
        di as txt "all off-diagonal elements = 0" _col(41) "{c |}" as res _col(42) %9.3f `c3' _col(53) %4.0f `d3' ///
            _col(61) %7.4f `p3'
        return scalar chi2_G = `c2'
        return scalar df_G = `d2'
        return scalar p_G = `p2'
        return scalar chi2 = `c3'
        return scalar df = `d3'
        return scalar p = `p3'
    }
    else {
        return scalar chi2 = `c1'
        return scalar df = `d1'
        return scalar p = `p1'
    }
    di as txt "{hline 40}{c BT}{hline 30}"
    if "`v'" == "bekk" {
        di as txt "H0: diagonal BEKK (Bauwens, Deprins & Vandeuren 1997, Table 5)."
    }
    else {
        di as txt "H0: no volatility spillovers (A diagonal) in the extended CCC model (Wong, Li & Ling 2005)."
    }
end

// ---------------------------------------------------------------------------
program define _cvg_estat_effgain, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) ]
    local v "`e(variance)'"
    if !inlist("`v'", "trigarch", "cccgarch", "darch", "dbekk") {
        di as err "estat effgain requires variance(trigarch), cccgarch, darch or dbekk"
        exit 498
    }
    capture matrix drop __cvg_eff
    mata: cvg_effgain("`mv'", "`win'", "`es'", "`xl'")
    tempname R
    matrix `R' = __cvg_eff
    capture matrix drop __cvg_eff
    local p = e(p)
    local lab ""
    if "`v'" == "trigarch" {
        forvalues j = 1/`p' {
            local lab "`lab' e`j'"
        }
    }
    else {
        foreach e in `e(eqnames)' {
            local lab "`lab' `=substr("`e'", 3, .)'"
        }
    }
    di
    di as txt "Partial efficiency gains of the QMLE of beta relative to Johansen RRR (Seo 2007, eq. 21)"
    di as txt "  g_j = [s_j + (kappa_j - 1) H_j] / [s_j + 2 H_j]{c 94}2,  s_j = E(s2_jt) E(1/s2_jt)"
    di as txt "{hline 14}{c TT}{hline 56}"
    di as txt _col(15) "{c |}" _col(21) "s_j" _col(32) "H_j" _col(40) "kappa_j" _col(52) "g_j" _col(60) "g_j (normal)"
    di as txt "{hline 14}{c +}{hline 56}"
    forvalues j = 1/`p' {
        local nm : word `j' of `lab'
        local nm = abbrev("`nm'", 13)
        di as txt %13s "`nm'" " {c |}" as res _col(17) %8.4f `R'[`j', 1] _col(27) %8.4f `R'[`j', 2] ///
            _col(38) %8.3f `R'[`j', 3] _col(48) %8.4f `R'[`j', 4] _col(61) %8.4f `R'[`j', 5]
    }
    di as txt "{hline 14}{c BT}{hline 56}"
    di as txt "g_j < 1: the joint QMLE of beta is more efficient than RRR in the direction of error j;"
    di as txt "  fat tails (kappa > 3) reduce the gain. The overall gain also depends on alpha and L."
    if "`v'" != "trigarch" {
        di as txt "  (Seo derives g_j for the triangular model; for `v' the formula is applied to the"
        di as txt "   univariate own-variance recursion of each equation - an approximation.)"
    }
    matrix rownames `R' = `lab'
    matrix colnames `R' = s H kappa gain gain_normal
    return matrix effgain = `R'
end

// ---------------------------------------------------------------------------
program define _cvg_estat_ranklr, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) Level(cilevel) ]
    local p = e(p)
    local vars "`e(varlist)'"
    local tv "`e(timevar)'"
    local t0 = e(tmin)
    local t1 = e(tmax)
    local oc "`e(opt_core)'"
    local trend "`e(trend)'"
    local gx ""
    if "`e(xmode)'" == "vars" local gx "garchx(`e(xvars)')"
    if "`e(xmode)'" == "ect" {
        di as txt "(note: garchx(ect) is dropped in the rank refits, the ECT does not exist at every rank)"
    }
    local rcur "`e(rank)'"
    local vlab "`e(vlabel)'"
    tempname hold R
    matrix `R' = J(`p' + 1, 6, .)
    _estimates hold `hold', restore
    di as txt "(estimating the VAR with `vlab' errors at ranks 0,...,`p' ...)"
    forvalues r = 0/`p' {
        local om "rank(`r')"
        if `r' == `p' local om "fullrank"
        capture noisily quietly cointvol_vecmgarch `vars' if inrange(`tv', `t0', `t1'), ///
            `oc' `om' `gx' novce nonconvok nolog
        if _rc {
            di as err "the model at rank `r' could not be estimated"
            exit _rc
        }
        matrix `R'[`r' + 1, 1] = `r'
        matrix `R'[`r' + 1, 2] = e(ll)
        matrix `R'[`r' + 1, 6] = e(converged)
    }
    _estimates unhold `hold'
    local llp = `R'[`p' + 1, 2]
    forvalues r = 0/`=`p'-1' {
        local lr = 2*(`llp' - `R'[`r' + 1, 2])
        matrix `R'[`r' + 1, 3] = `lr'
        capture matrix drop __cvg_ap
        mata: st_matrix("__cvg_ap", cv_asyp(`lr', `p' - `r', "`trend'", 1))
        matrix `R'[`r' + 1, 4] = __cvg_ap[1, 1]
        matrix `R'[`r' + 1, 5] = __cvg_ap[1, 2]
        capture matrix drop __cvg_ap
    }
    local eta = 1 - `level'/100
    di
    di as txt "LR rank tests in the VAR with `vlab' errors (Bauwens, Deprins & Vandeuren 1997)"
    di as txt "{hline 9}{c TT}{hline 58}"
    di as txt "   H0: r {c |}" _col(15) "logL(r)" _col(28) "LR(r|p)" _col(40) "Asy.p" _col(49) "cv 5%" _col(59) "Converged"
    di as txt "{hline 9}{c +}{hline 58}"
    local rsel ""
    forvalues r = 0/`p' {
        local s " "
        if `r' < `p' {
            if `R'[`r' + 1, 4] < `eta' local s "*"
            if "`rsel'" == "" & `R'[`r' + 1, 4] >= `eta' local rsel `r'
        }
        local cvl "yes"
        if `R'[`r' + 1, 6] == 0 local cvl "NO"
        if `r' < `p' {
            di as txt %8.0f `r' " {c |}" as res _col(11) %12.3f `R'[`r'+1, 2] _col(25) %10.3f `R'[`r'+1, 3] ///
                _col(38) %6.3f `R'[`r'+1, 4] as txt "`s'" as res _col(46) %8.3f `R'[`r'+1, 5] as txt _col(61) "`cvl'"
        }
        else {
            di as txt %8.0f `r' " {c |}" as res _col(11) %12.3f `R'[`r'+1, 2] as txt _col(34) "(unrestricted)" _col(61) "`cvl'"
        }
    }
    di as txt "{hline 9}{c BT}{hline 58}"
    if "`rsel'" == "" local rsel `p'
    local lev : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    di as txt "* rejects H0: rank <= r at the `lev'% level.  Sequential choice: r = " as res "`rsel'" ///
        as txt "  (model in memory: rank `rcur')"
    di as txt "LR(r|p) = 2[logL(p) - logL(r)] from the joint VAR-GARCH fits; p-values and critical values"
    di as txt "  from the asymptotic Johansen trace distribution (trend: `trend') - asymptotics conjectured"
    di as txt "  (BDV 1997, Sec. 4.2), not proved under GARCH. See cointvol garchrank for SML (2024) tests."
    matrix colnames `R' = r ll lr p_asy cv95 converged
    return matrix ranklr = `R'
    return scalar rank_sel = `rsel'
end

// ---------------------------------------------------------------------------
program define _cvg_estat_archlm, rclass
    version 14.0
    syntax [, mv(string) win(string) es(string) xl(string) Lags(numlist integer >0) ]
    if "`lags'" == "" local lags "1 5 10"
    capture matrix drop __cvg_alm
    mata: cvg_archlm("`mv'", "`win'", "`es'", "`xl'", "`lags'")
    tempname R
    matrix `R' = __cvg_alm
    capture matrix drop __cvg_alm
    local vl "`e(varlist)'"
    local p = e(p)
    di
    di as txt "ARCH-LM tests on the standardised residuals (Engle 1982; n R{c 94}2 ~ chi2(q))"
    if "`e(variance)'" == "trigarch" {
        di as txt "  (orthogonalised errors e_jt / s_jt of the triangular model)"
    }
    di as txt "{hline 16}{c TT}{hline 34}"
    di as txt "  equation" _col(12) "q" _col(17) "{c |}" _col(21) "LM stat" _col(34) "df" _col(41) "p-value"
    di as txt "{hline 16}{c +}{hline 34}"
    local nr = rowsof(`R')
    forvalues i = 1/`nr' {
        local w : word `=`R'[`i',1]' of `vl'
        if "`e(variance)'" == "trigarch" local w "e`=`R'[`i',1]'"
        local w = abbrev("`w'", 9)
        di as txt "  " %-9s "`w'" %3.0f `R'[`i', 2] _col(17) "{c |}" as res _col(18) %10.3f `R'[`i', 3] ///
            _col(31) %5.0f `R'[`i', 4] _col(40) %7.4f `R'[`i', 5]
    }
    di as txt "{hline 16}{c BT}{hline 34}"
    di as txt "H0: no remaining ARCH effects in the standardised residuals."
    matrix colnames `R' = equation lag stat df p
    return matrix archlm = `R'
end
