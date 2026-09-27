*! cointvol_restrict 0.1.0  26sep2026
*! Inference on the cointegration parameters alpha and beta in heteroskedastic VARs:
*! restricted PML, PLR and sandwich-Wald tests, Bartlett correction, wild/iid bootstrap
*! (Boswijk, Cavaliere, Rahbek & Taylor 2016; Boswijk & Doornik 2004; Johansen 2000;
*!  Kurita 2013)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_restrict.sthlp, section Methods):
*!   model dX = alpha beta#'Z1 + Psi Z2 + e, beta# = (beta', rho1')'     -> BCRT (2016) eqs (1),(4)
*!   normalisation c'beta = I_r (normalize()), H0b, H0a, joint           -> BCRT (2016) eq (5)
*!   vec beta# = H phi + h, vec alpha' = G psi + g                        -> BCRT (2016) eq (6)
*!   restricted PML by switching (phi|psi,Omega; psi|phi,Omega;
*!     Omega|psi,phi); closed form for beta# = H phi                    -> Boswijk & Doornik (2004) Sec. 4.4, eq (39)
*!                                                                          and the explicit steps; Johansen (1996, Thm 7.2)
*!   identification: rank of J(theta) at the restricted MLE              -> Boswijk & Doornik (2004) eqs (20), (40)
*!   LR_T = T log(|Sigma~|/|Sigma^|) (= Kurita's QLR for beta# = H phi)  -> BCRT (2016) Sec. 3.1; Kurita (2013) eq (6)
*!   sandwich Wald W_T                                                    -> BCRT (2016) eq (18)
*!   Bartlett-corrected LR_T / BC, BC at the restricted estimates         -> Johansen (2000) Cor. 6 / Thm 4, eqs (30)-(35)
*!   wild bootstrap (Algorithm 1), iid bootstrap                          -> BCRT (2016) Sec. 4.1, eq (21)

program define cointvol_restrict, eclass
    version 14.0

    // ---------------- load / reload the Mata engines ---------------------
    // (Mata code in an autoloaded ado is private to that file, so the engines
    //  are -run- as do-files, which compiles their functions globally.)
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvrver", cvr_version())
    if _rc {
        capture program drop cointvol_eng_restrict
        quietly findfile cointvol_eng_restrict.ado
        quietly run `"`r(fn)'"'
    }

    if replay() {
        if `"`e(cmd)'"' != "cointvol restrict" {
            error 301
        }
        syntax [, BRief LEVel(cilevel)]
        _cvr_display, `brief' level(`level')
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in], LAgs(integer) RAnk(integer)    ///
        [ TRend(string) NORMalize(string) SPReads KNown(string)               ///
          HMATrix(string) BCONstraints(string) EXog(string)                    ///
          ACONstraints(string) SEParate Method(string) MULTiplier(string)      ///
          REps(integer 999) SEED(string) LEVel(cilevel) PVALue(string)         ///
          BARTlett TOLerance(real 1e-8) ITERate(integer 5000) NODOTS BRief ]

    local cmdline `"cointvol restrict `0'"'

    // ---------------- options --------------------------------------------
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
    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "wild"
    if !inlist(`"`method'"', "asy", "iid", "wild") {
        di as err "method() must be asy, iid or wild"
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
    if `tolerance' <= 0 {
        di as err "tolerance() must be positive"
        exit 198
    }
    if `iterate' < 1 {
        di as err "iterate() must be a positive integer"
        exit 198
    }

    local p : word count `varlist'
    if `rank' < 1 | `rank' >= `p' {
        di as err "rank() must lie in 1,...,p-1 = `=`p'-1'"
        exit 198
    }

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol restrict requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol restrict needs consecutive observations"
        exit 498
    }
    local T = `N0' - `lags'
    if `T' < `p'*`lags' + 10 {
        di as err "too few observations (" `N0' ") for p = `p' variables and `lags' lags"
        exit 2001
    }

    // ---------------- hypothesis on beta ----------------------------------
    local nbopt = ("`spreads'" != "") + (`"`known'"' != "") + (`"`hmatrix'"' != "") + (`"`bconstraints'"' != "")
    if `nbopt' > 1 {
        di as err "specify at most one of spreads, known(), hmatrix() and bconstraints()"
        exit 198
    }
    local __btype "none"
    local __bm1 ""
    local __bm2 ""
    local __sref 1
    local hbeta ""
    local ref1 : word 1 of `varlist'
    if "`spreads'" != "" {
        local __btype "spreads"
        local hbeta "spreads: every cointegrating vector is a combination of x_i - `ref1' (beta# = H*phi)"
    }
    if `"`known'"' != "" {
        capture confirm matrix `known'
        if !_rc {
            local __btype "knownmat"
            local __bm1 "`known'"
            local hbeta "beta fully specified by matrix `known'"
        }
        else {
            capture numlist `"`known'"'
            if _rc {
                di as err "known() must be a numlist or the name of an existing matrix"
                exit 198
            }
            local __btype "knownnum"
            local __bm1 "`r(numlist)'"
            local hbeta "beta fully specified (known())"
        }
    }
    if `"`hmatrix'"' != "" {
        local hmatrix = strtrim(`"`hmatrix'"')
        confirm matrix `hmatrix'
        local __btype "H"
        local __bm1 "`hmatrix'"
        local hbeta "beta# = H*phi, H = `hmatrix'"
    }
    if `"`bconstraints'"' != "" {
        local nw : word count `bconstraints'
        if `nw' > 2 {
            di as err "bconstraints() takes one or two matrix names: R_b [q_b]"
            exit 198
        }
        local __bm1 : word 1 of `bconstraints'
        local __bm2 : word 2 of `bconstraints'
        confirm matrix `__bm1'
        if "`__bm2'" != "" {
            confirm matrix `__bm2'
        }
        local __btype "R"
        local qtxt = cond("`__bm2'" == "", "0", "`__bm2'")
        local hbeta "R_b vec(beta2#) = q_b, R_b = `__bm1', q_b = `qtxt'"
    }

    // ---------------- hypothesis on alpha ---------------------------------
    local __eidx ""
    local __am1 ""
    local __am2 ""
    local halpha ""
    if `"`exog'"' != "" {
        tsunab exog : `exog'
        local exog : list uniq exog
        foreach v of local exog {
            local pos : list posof "`v'" in varlist
            if `pos' == 0 {
                di as err "exog(): `v' is not in the varlist"
                exit 198
            }
            local __eidx "`__eidx' `pos'"
        }
        local halpha "weak exogeneity of `exog' (rows of alpha = 0)"
    }
    if `"`aconstraints'"' != "" {
        local nw : word count `aconstraints'
        if `nw' > 2 {
            di as err "aconstraints() takes one or two matrix names: R_a [q_a]"
            exit 198
        }
        local __am1 : word 1 of `aconstraints'
        local __am2 : word 2 of `aconstraints'
        confirm matrix `__am1'
        if "`__am2'" != "" {
            confirm matrix `__am2'
        }
        local qtxt = cond("`__am2'" == "", "0", "`__am2'")
        if "`halpha'" != "" local halpha "`halpha'; "
        local halpha "`halpha'R_a vec(alpha') = q_a, R_a = `__am1', q_a = `qtxt'"
    }
    if "`__btype'" == "none" & "`halpha'" == "" {
        di as err "no hypothesis specified: use spreads, known(), hmatrix(), bconstraints(),"
        di as err "exog() and/or aconstraints()"
        exit 198
    }
    if "`bartlett'" != "" & !inlist("`__btype'", "spreads", "knownnum", "knownmat", "H") {
        di as txt "(note: bartlett requires a hypothesis beta# = H*phi (spreads, known(), hmatrix()); ignored)"
    }

    // ---------------- normalisation ---------------------------------------
    local nidx ""
    if `"`normalize'"' != "" {
        tsunab normalize : `normalize'
        local nn : word count `normalize'
        local nu : list uniq normalize
        local nnu : word count `nu'
        if `nn' != `rank' | `nnu' != `rank' {
            di as err "normalize() must list exactly r = `rank' distinct variables of the varlist"
            exit 198
        }
        foreach v of local normalize {
            local pos : list posof "`v'" in varlist
            if `pos' == 0 {
                di as err "normalize(): `v' is not in the varlist"
                exit 198
            }
            local nidx "`nidx' `pos'"
        }
    }
    else {
        local first = cond("`spreads'" != "", 2, 1)
        forvalues i = `first'/`=`first'+`rank'-1' {
            local nidx "`nidx' `i'"
            local v : word `i' of `varlist'
            local normalize "`normalize' `v'"
        }
    }
    local normalize = strtrim("`normalize'")

    // seed
    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    // ---------------- computation -----------------------------------------
    foreach m in res alpha beta Pi Sig seA seB theta V lam alpha_r beta_r Pi_r Sig_r Psi Psi_r LRB WB {
        capture matrix drop __cvr_`m'
    }
    local dots = ("`nodots'" == "") & ("`method'" != "asy")
    if `dots' {
        di as txt _n "Bootstrap replications (" as res `reps' as txt "), one dot = 50:"
    }
    local __hlabels ""
    mata: cvr_main("`mvars'", "`touse'", `lags', "`trend'", `rank', "`nidx'")

    tempname res al be Pi Sg seA seB b V lam alr ber Pir Sgr Gm Gmr LRB WB
    matrix `res' = __cvr_res
    matrix `al'  = __cvr_alpha
    matrix `be'  = __cvr_beta
    matrix `Pi'  = __cvr_Pi
    matrix `Sg'  = __cvr_Sig
    matrix `seA' = __cvr_seA
    matrix `seB' = __cvr_seB
    matrix `b'   = __cvr_theta
    matrix `V'   = __cvr_V
    matrix `lam' = __cvr_lam
    matrix `alr' = __cvr_alpha_r
    matrix `ber' = __cvr_beta_r
    matrix `Pir' = __cvr_Pi_r
    matrix `Sgr' = __cvr_Sig_r
    local hasG 0
    capture confirm matrix __cvr_Psi
    if !_rc {
        local hasG 1
        matrix `Gm'  = __cvr_Psi
        matrix `Gmr' = __cvr_Psi_r
    }
    if "`method'" != "asy" {
        matrix `LRB' = __cvr_LRB
        matrix `WB'  = __cvr_WB
    }
    local Teff  = scalar(__cvr_T)
    local nh    = scalar(__cvr_nh)
    local ll    = scalar(__cvr_ll)
    local ll_r  = scalar(__cvr_ll_r)
    local vmiss = scalar(__cvr_vmiss)
    foreach m in res alpha beta Pi Sig seA seB theta V lam alpha_r beta_r Pi_r Sig_r Psi Psi_r LRB WB {
        capture matrix drop __cvr_`m'
    }
    capture scalar drop __cvr_T __cvr_nh __cvr_ll __cvr_ll_r __cvr_vmiss __cvr_s

    // ---------------- names -----------------------------------------------
    local d1n ""
    if "`trend'" == "rconstant" local d1n "_cons"
    if "`trend'" == "rtrend"    local d1n "_trend"
    local d2n ""
    if "`trend'" == "constant"  local d2n "_cons"
    if "`trend'" == "rtrend"    local d2n "_cons"
    if "`trend'" == "trend"     local d2n "_cons _trend"
    local bnames "`varlist' `d1n'"
    local eqn ""
    foreach v of local varlist {
        local e = substr(strtoname("D_`v'"), 1, 32)
        local eqn "`eqn' `e'"
    }
    local cen ""
    forvalues j = 1/`rank' {
        local cen "`cen' _ce`j'"
    }
    // non-normalising rows of beta# (vec beta2#)
    local b2n ""
    local i 0
    foreach v of local bnames {
        local i = `i' + 1
        if !`: list i in nidx' {
            local b2n "`b2n' `v'"
        }
    }
    local stripe ""
    forvalues j = 1/`rank' {
        foreach v of local b2n {
            local stripe "`stripe' _ce`j':`v'"
        }
    }
    foreach e of local eqn {
        forvalues j = 1/`rank' {
            local stripe "`stripe' `e':_ce`j'"
        }
    }
    matrix colnames `b' = `stripe'
    matrix colnames `V' = `stripe'
    matrix rownames `V' = `stripe'
    foreach m in be seB ber {
        matrix rownames ``m'' = `bnames'
        matrix colnames ``m'' = `cen'
    }
    foreach m in al seA alr {
        matrix rownames ``m'' = `eqn'
        matrix colnames ``m'' = `cen'
    }
    foreach m in Pi Pir {
        matrix rownames ``m'' = `eqn'
        matrix colnames ``m'' = `bnames'
    }
    foreach m in Sg Sgr {
        matrix rownames ``m'' = `eqn'
        matrix colnames ``m'' = `eqn'
    }
    if `hasG' {
        local gn ""
        forvalues j = 1/`=`lags'-1' {
            foreach v of local varlist {
                local g = substr(strtoname("L`j'D_`v'"), 1, 32)
                local gn "`gn' `g'"
            }
        }
        local gn "`gn' `d2n'"
        foreach m in Gm Gmr {
            matrix rownames ``m'' = `eqn'
            matrix colnames ``m'' = `gn'
        }
    }
    matrix colnames `res' = df lr lr_p_asy lr_p_boot lr_cv_boot bc lr_bc lr_bc_p ///
        wald wald_p_asy wald_p_boot wald_cv_boot iter converged explosive redrawn nonconv ///
        rank_J n_free bc_v bc_c
    matrix rownames `res' = `__hlabels'
    if "`method'" != "asy" {
        matrix colnames `LRB' = `__hlabels'
        matrix colnames `WB'  = `__hlabels'
    }

    local s1 = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'

    // main hypothesis = last row
    local im = `nh'
    local e_df    = `res'[`im', 1]
    local e_lr    = `res'[`im', 2]
    local e_lrpa  = `res'[`im', 3]
    local e_lrpb  = `res'[`im', 4]
    local e_bc    = `res'[`im', 6]
    local e_lrbc  = `res'[`im', 7]
    local e_lrbcp = `res'[`im', 8]
    local e_w     = `res'[`im', 9]
    local e_wpa   = `res'[`im', 10]
    local e_wpb   = `res'[`im', 11]
    local e_iter  = `res'[`im', 13]
    local e_conv  = `res'[`im', 14]
    local e_rkj   = `res'[`im', 18]
    local e_nfr   = `res'[`im', 19]

    // ---------------- post ------------------------------------------------
    tempvar esamp
    qui gen byte `esamp' = `touse'
    qui replace `esamp' = 0 if `tvar' < `tmin' + `lags'*`tdelta'
    if `vmiss' == 0 {
        ereturn post `b' `V', esample(`esamp') obs(`Teff') properties(b V)
    }
    else {
        di as txt "(note: sandwich variance matrix not available; e(V) not posted)"
        ereturn post `b', esample(`esamp') obs(`Teff') properties(b)
    }
    ereturn scalar lr          = `e_lr'
    ereturn scalar lr_df       = `e_df'
    ereturn scalar lr_p_asy    = `e_lrpa'
    ereturn scalar lr_p_boot   = `e_lrpb'
    ereturn scalar wald        = `e_w'
    ereturn scalar wald_df     = `e_df'
    ereturn scalar wald_p_asy  = `e_wpa'
    ereturn scalar wald_p_boot = `e_wpb'
    ereturn scalar bc          = `e_bc'
    ereturn scalar lr_bc       = `e_lrbc'
    ereturn scalar lr_bc_p     = `e_lrbcp'
    ereturn scalar ll          = `ll'
    ereturn scalar ll_r        = `ll_r'
    ereturn scalar iter        = `e_iter'
    ereturn scalar converged   = `e_conv'
    ereturn scalar rank_J      = `e_rkj'
    ereturn scalar n_free      = `e_nfr'
    ereturn scalar rank        = `rank'
    ereturn scalar lags        = `lags'
    ereturn scalar p           = `p'
    ereturn scalar level       = `level'
    ereturn scalar tmin        = `tmin'
    ereturn scalar tmax        = `tmax'
    ereturn scalar tdelta      = `tdelta'
    ereturn scalar tolerance   = `tolerance'
    if "`method'" != "asy" {
        ereturn scalar reps = `reps'
    }
    ereturn local varlist    "`varlist'"
    ereturn local trend      "`trend'"
    ereturn local normalize  "`normalize'"
    ereturn local method     "`method'"
    ereturn local multiplier "`multiplier'"
    ereturn local pvalue     "`pvalue'"
    ereturn local seed       `"`seed'"'
    ereturn local seeduse    `"`seeduse'"'
    ereturn local h_beta     `"`hbeta'"'
    ereturn local h_alpha    `"`halpha'"'
    ereturn local hlabels    "`__hlabels'"
    ereturn local sfrom      "`sfrom'"
    ereturn local sto        "`sto'"
    ereturn local timevar    "`tvar'"
    ereturn local bartlett   "`bartlett'"
    ereturn local vce        "sandwich"
    ereturn local vcetype    "Sandwich"
    ereturn local title      "Inference on cointegration parameters (PML)"
    ereturn local predict    "cointvol_restrict_p"
    ereturn local cmdline    `"`cmdline'"'
    ereturn matrix tests    = `res'
    ereturn matrix alpha    = `al'
    ereturn matrix beta     = `be'
    ereturn matrix se_alpha = `seA'
    ereturn matrix se_beta  = `seB'
    ereturn matrix alpha_r  = `alr'
    ereturn matrix beta_r   = `ber'
    ereturn matrix Pi       = `Pi'
    ereturn matrix Pi_r     = `Pir'
    ereturn matrix Omega    = `Sg'
    ereturn matrix Omega_r  = `Sgr'
    ereturn matrix eigenvalues = `lam'
    if `hasG' {
        ereturn matrix Gamma   = `Gm'
        ereturn matrix Gamma_r = `Gmr'
    }
    if "`method'" != "asy" {
        ereturn matrix boot_lr   = `LRB'
        ereturn matrix boot_wald = `WB'
    }
    ereturn local cmd "cointvol restrict"

    _cvr_display, `brief' level(`level')
end

// ---------------------------------------------------------------------------
//  Display (also used on replay); everything is read from e()
// ---------------------------------------------------------------------------
program define _cvr_display
    version 14.0
    syntax [, BRief Level(cilevel)]
    local r = e(rank)
    local eta = 1 - `level'/100
    local lev : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    local trend "`e(trend)'"
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`trend'" == "trend"     local tlab "unrestricted trend"
    local method "`e(method)'"
    if "`method'" == "asy"  local mlab "asymptotic only"
    if "`method'" == "iid"  local mlab "iid bootstrap"
    if "`method'" == "wild" local mlab "wild bootstrap (BCRT 2016, Algorithm 1)"

    di
    di as txt "`e(title)'" _col(52) "Number of obs  = " as res %9.0f e(N)
    di as txt "Sample: " as res "`e(sfrom)' - `e(sto)'" as txt _col(52) "Variables (p)  = " as res %9.0f e(p)
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags (levels)  = " as res %9.0f e(lags)
    di as txt "Normalised on: " as res "`e(normalize)'" as txt _col(52) "Coint. rank    = " as res %9.0f e(rank)
    di as txt "Log pseudo-likelihood: unrestricted = " as res %11.3f e(ll) ///
        as txt "   restricted = " as res %11.3f e(ll_r)

    if "`brief'" == "" {
        tempname Bm Sm Am Tm Br Ar
        matrix `Bm' = e(beta)
        matrix `Sm' = e(se_beta)
        matrix `Am' = e(alpha)
        matrix `Tm' = e(se_alpha)
        matrix `Br' = e(beta_r)
        matrix `Ar' = e(alpha_r)
        _cvr_mattab `Bm' `Sm' "Unrestricted PML estimates of beta# (sandwich standard errors in parentheses)" "beta"
        _cvr_mattab `Am' `Tm' "Unrestricted PML estimates of alpha (sandwich standard errors in parentheses)" "alpha"
        _cvr_mattab `Br' "" "Restricted PML estimates of beta# (under the last hypothesis in the table below)" "beta"
        _cvr_mattab `Ar' "" "Restricted PML estimates of alpha" "alpha"
    }

    tempname Ts
    matrix `Ts' = e(tests)
    local nh = rowsof(`Ts')
    local hl "`e(hlabels)'"
    di
    di as txt "Tests of restrictions on the cointegration parameters (r = `r')"
    di as txt "{hline 16}{c TT}{hline 31}{c TT}{hline 30}"
    di as txt _col(17) "{c |}" _col(24) "PLR test  LR_T" _col(49) "{c |}" _col(54) "Wald test (sandwich)"
    di as txt "  H0" _col(12) "df" _col(17) "{c |}" _col(20) "Statistic" _col(32) "Asy.p" _col(40) "Boot.p" ///
        _col(49) "{c |}" _col(51) "Statistic" _col(63) "Asy.p" _col(71) "Boot.p"
    di as txt "{hline 16}{c +}{hline 31}{c +}{hline 30}"
    forvalues i = 1/`nh' {
        local lab : word `i' of `hl'
        local df  = `Ts'[`i', 1]
        local lr  = `Ts'[`i', 2]
        local pa  = `Ts'[`i', 3]
        local pb  = `Ts'[`i', 4]
        local wd  = `Ts'[`i', 9]
        local wa  = `Ts'[`i', 10]
        local wb  = `Ts'[`i', 11]
        local s1 = cond(`pa' < `eta', "*", " ")
        local s2 = cond(`pb' < `eta' & `pb' < ., "*", " ")
        local s3 = cond(`wa' < `eta', "*", " ")
        local s4 = cond(`wb' < `eta' & `wb' < ., "*", " ")
        if "`method'" == "asy" {
            di as txt "  `lab'" _col(10) as res %4.0f `df' as txt _col(17) "{c |}" ///
                as res _col(18) %11.3f `lr' _col(31) %6.3f `pa' as txt "`s1'" _col(43) "." ///
                _col(49) "{c |}" as res _col(50) %10.3f `wd' _col(62) %6.3f `wa' as txt "`s3'" _col(74) "."
        }
        else {
            di as txt "  `lab'" _col(10) as res %4.0f `df' as txt _col(17) "{c |}" ///
                as res _col(18) %11.3f `lr' _col(31) %6.3f `pa' as txt "`s1'" ///
                as res _col(39) %6.3f `pb' as txt "`s2'" ///
                _col(49) "{c |}" as res _col(50) %10.3f `wd' _col(62) %6.3f `wa' as txt "`s3'" ///
                as res _col(70) %6.3f `wb' as txt "`s4'"
        }
    }
    di as txt "{hline 16}{c BT}{hline 31}{c BT}{hline 30}"
    if `"`e(h_beta)'"' != "" {
        di as txt "H0 beta : " as res `"`e(h_beta)'"'
    }
    if `"`e(h_alpha)'"' != "" {
        di as txt "H0 alpha: " as res `"`e(h_alpha)'"'
    }
    forvalues i = 1/`nh' {
        local bc = `Ts'[`i', 6]
        if `bc' < . {
            local lab : word `i' of `hl'
            di as txt "Bartlett-corrected PLR (`lab'): LR_T/BC = " as res %9.3f `Ts'[`i', 7] ///
                as txt ", BC = " as res %6.4f `bc' as txt ", chi2(" as res `Ts'[`i', 1] as txt ") p = " ///
                as res %6.3f `Ts'[`i', 8]
            local bcnote 1
        }
    }
    if "`bcnote'" == "1" {
        di as txt "  BC = E(LR_T)/df of Johansen (2000, Cor. 6; Thm 4), iid Gaussian errors, evaluated at"
        di as txt "  the restricted estimates; it does not correct for (non)stationary volatility."
    }
    else if "`e(bartlett)'" != "" {
        di as txt "Note: Bartlett factor not available (needs beta# = H*phi without alpha restrictions"
        di as txt "      and a stable companion matrix P at the restricted estimates)."
    }
    di as txt "* rejects H0 at the `lev'% level.  LR_T = T log(|Sigma~|/|Sigma^|) (BCRT 2016, Sec. 3.1);"
    di as txt "  Wald with PML sandwich variance (BCRT 2016, eq. 18); asymptotic p-values from chi2(df)."
    di as txt "  Under nonstationary volatility the chi2 limit fails for the PLR tests and for the Wald"
    di as txt "  test on beta (BCRT 2016, Thms 1-2); the Wald test on alpha stays chi2."
    if "`method'" != "asy" {
        di as txt "Inference: " as res "`mlab'" as txt ", restricted estimates, recentred restricted residuals;"
        if "`method'" == "wild" {
            di as txt "  multiplier = " as res "`e(multiplier)'" as txt ", B = " as res e(reps) ///
                as txt ", seed = " as res `"`e(seeduse)'"' as txt ", p = B{c 94}-1 sum 1(S* > S)."
        }
        else {
            di as txt "  B = " as res e(reps) as txt ", seed = " as res `"`e(seeduse)'"' ///
                as txt "; iid bootstrap is not valid under nonstationary volatility."
        }
        local nx 0
        local nf 0
        local nc 0
        forvalues i = 1/`nh' {
            if `Ts'[`i', 15] > 0 & `Ts'[`i', 15] < . local nx = `nx' + 1
            local nf = `nf' + `Ts'[`i', 16]
            local nc = `nc' + `Ts'[`i', 17]
        }
        if `nx' > 0 {
            di as txt "Note: the restricted bootstrap DGP has explosive root(s); BCRT (2016, Sec. 4.1) note the"
            di as txt "      root check can usually be ignored."
        }
        if `nf' > 0 {
            di as txt "Note: " as res `nf' as txt " bootstrap sample(s) were singular/explosive and were redrawn."
        }
        if `nc' > 0 {
            di as txt "Note: the switching algorithm hit iterate() in " as res `nc' as txt " bootstrap sample(s)."
        }
    }
    local nci 0
    local nid 0
    forvalues i = 1/`nh' {
        if `Ts'[`i', 14] == 0 local nci = `nci' + 1
        if colsof(`Ts') >= 19 {
            if `Ts'[`i', 18] < `Ts'[`i', 19] local nid = `nid' + 1
        }
    }
    if `nid' > 0 {
        di as err "Warning: the Jacobian J(theta) is rank deficient at the restricted estimates for " `nid'
        di as err "  hypothesis(es): theta is not locally identified there and the chi2 df may be wrong"
        di as err "  (Boswijk and Doornik 2004, Thm 1-2); see e(tests), columns rank_J and n_free."
    }
    if `nci' > 0 {
        di as err "Warning: the switching algorithm did not converge on the data; increase iterate()."
    }
end

// ---------------------------------------------------------------------------
//  Matrix table with optional standard errors (two lines per row)
// ---------------------------------------------------------------------------
program define _cvr_mattab
    version 14.0
    args C S title cpre
    local nr = rowsof(`C')
    local nc = colsof(`C')
    local rn : rownames `C'
    di
    di as txt "`title'"
    local c1 = 1
    while `c1' <= `nc' {
        local c2 = min(`nc', `c1' + 4)
        local w = 12*(`c2' - `c1' + 1)
        di as txt "{hline 13}{c TT}{hline `w'}"
        di as txt _col(14) "{c |}" _c
        forvalues j = `c1'/`c2' {
            local pos = 14 + 12*(`j' - `c1') + 3
            di as txt _col(`pos') %9s "`cpre'`j'" _c
        }
        di
        di as txt "{hline 13}{c +}{hline `w'}"
        forvalues i = 1/`nr' {
            local nm : word `i' of `rn'
            local nm = abbrev("`nm'", 12)
            di as txt %-12s "`nm'" _col(14) "{c |}" _c
            forvalues j = `c1'/`c2' {
                local pos = 14 + 12*(`j' - `c1') + 2
                di as res _col(`pos') %10.4f `C'[`i', `j'] _c
            }
            di
            if "`S'" != "" {
                local any 0
                forvalues j = `c1'/`c2' {
                    if `S'[`i', `j'] < . local any 1
                }
                if `any' {
                    di as txt _col(14) "{c |}" _c
                    forvalues j = `c1'/`c2' {
                        local se = `S'[`i', `j']
                        if `se' < . {
                            local pos = 14 + 12*(`j' - `c1') + 2
                            local sef : display %8.4f `se'
                            di as txt _col(`pos') " (" strtrim("`sef'") ")" _c
                        }
                    }
                    di
                }
            }
        }
        di as txt "{hline 13}{c BT}{hline `w'}"
        local c1 = `c2' + 1
    }
end
