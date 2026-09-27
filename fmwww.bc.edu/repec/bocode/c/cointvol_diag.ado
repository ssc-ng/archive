*! cointvol_diag 0.1.0  26sep2026
*! Residual diagnostics for a VECM / VAR: ARCH, CCC-ARCH, autocorrelation (HCCME,
*! wild bootstrap), portmanteau, variance profile, companion roots, spread GARCH
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_diag.sthlp, section Methods):
*!   VECM under H(r) by Johansen RRR (core engine)   -> Johansen (1996); CRT (2010) eqs (3),(7)
*!   archlm : (T-h) R2 of e2_t on (1, e2_{t-1..t-h}) -> Engle (1982)
*!   march  : 0.5 N K(K+1) - N tr(Om_res Om_0^-1), df K^2(K+1)^2 h/4
*!            -> Lutkepohl (2006, s.16.5); VARtests (SRC25)
*!   ca     : max_i N R2_i on Cholesky-standardised residuals, parametric bootstrap
*!            -> Catani & Ahlgren (2017), Algorithm 1; SRC25 archBootTest
*!   et     : LM (14) from Theorem 1 eqs (12)-(13), CCC-ARCH(h) alternative (6), df K h,
*!            on the model residuals, ML nuisance values -> Eklund & Terasvirta (2007)
*!            (etchol: VARtests variant on Cholesky-standardised residuals; SRC25)
*!   etst   : same LM against smooth transition in variances, v_it = (1, t/T)', df K
*!            -> Eklund & Terasvirta (2007) s.5.3, eqs (24),(27)-(29)
*!   lingli : Q(M) = n R'R on q_t = e_t'V_t^-1 e_t, eqs (2.11),(3.10); Q(r,M) (3.11);
*!            finite-sample factor (n - M - 2K - k - q + 1) of (4.6) -> Ling & Li (1997)
*!   aclm   : LM and HC0-HC3, df h K^2; recursive / fixed wild bootstrap
*!            -> Ahlgren & Catani (2017) eqs (6),(8),(9),(11), Algorithms 1-2; SRC25
*!   portmanteau : Q_h and adjusted Q_h, df K^2(h-k+1) - K r -> Lutkepohl (2006, s.8.4.1)
*!   varprofile  : eta_i(u) = sum_{t<=Tu} e_it^2 / sum e_it^2 -> CRT (2010, JoE) s.6
*!   roots       : companion moduli of the fitted VECM   -> Johansen (1996, ch. 4)
*!   spreadgarch : EXTENDED two-step GARCH(1,1) on the ECT(s) with -arch- (contrast case, SRC24)

program define cointvol_diag, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in], Lags(integer) ///
        [ TRend(string) RAnk(integer -1) ARCHlm(integer 0) MARCH(integer 0)   ///
          CA(integer 0) ET(integer 0) ACLM(integer 0) HC(string)              ///
          PORTmanteau(integer 0) VARPROFile ROOTS SPREADgarch BOOTstrap       ///
          Reps(integer 499) SEED(string) MULTiplier(string) WBtype(string)    ///
          Level(cilevel) NODOTS GRaph GRAPHName(string) ETST(integer 0)       ///
          ETCHol LINGli(integer 0) LLARch(integer 0) LLVcov(varlist numeric) ]

    // ---------------- load / reload the Mata engines ---------------------
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvdver", cvd_version())
    if _rc {
        capture program drop cointvol_eng_diag
        quietly findfile cointvol_eng_diag.ado
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
    if `lags' < 1 {
        di as err "lags() must be a positive integer (lag order of the VAR in levels)"
        exit 198
    }
    foreach o in archlm march ca et aclm portmanteau etst lingli llarch {
        if ``o'' < 0 {
            di as err "`o'() must be a positive integer"
            exit 198
        }
    }
    if `etst' > 4 {
        di as err "etst() must be 1 (Eklund-Terasvirta s.5.3) or a polynomial order up to 4"
        exit 198
    }
    if `llarch' > 0 & `lingli' == 0 {
        di as err "llarch() requires lingli()"
        exit 198
    }
    if `lingli' > 0 & `llarch' >= `lingli' {
        di as err "llarch() must be smaller than lingli()"
        exit 198
    }
    if "`llvcov'" != "" & `lingli' == 0 {
        di as err "llvcov() requires lingli()"
        exit 198
    }
    if "`etchol'" != "" & `et' == 0 {
        di as err "etchol requires et()"
        exit 198
    }
    local anytest = (`archlm' + `march' + `ca' + `et' + `aclm' + `portmanteau' + `etst' + `lingli' > 0)
    if "`varprofile'`roots'`spreadgarch'`graph'" != "" local anytest 1
    if !`anytest' {
        local archlm 2
        local march 2
        local aclm 2
        local varprofile varprofile
        local roots roots
    }
    if "`graph'" != "" local varprofile varprofile

    local hc = strlower(strtrim(`"`hc'"'))
    if `"`hc'"' == "" local hc "lm hc0 hc1 hc2 hc3"
    local hcshow ""
    foreach h of local hc {
        if !inlist("`h'", "lm", "hc0", "hc1", "hc2", "hc3") {
            di as err "hc() may contain lm, hc0, hc1, hc2, hc3"
            exit 198
        }
        local hcshow "`hcshow' `h'"
    }
    local multiplier = strlower(strtrim(`"`multiplier'"'))
    if `"`multiplier'"' == "" local multiplier "rademacher"
    if inlist(`"`multiplier'"', "gaussian", "normal", "n", "gauss") local multiplier "gauss"
    if inlist(`"`multiplier'"', "rad", "r")                 local multiplier "rademacher"
    if inlist(`"`multiplier'"', "mam", "m")                 local multiplier "mammen"
    if !inlist(`"`multiplier'"', "gauss", "rademacher", "mammen") {
        di as err "multiplier() must be gauss, rademacher or mammen"
        exit 198
    }
    local wbtype = strlower(strtrim(`"`wbtype'"'))
    if `"`wbtype'"' == "" | `"`wbtype'"' == "both" local wbtype "recursive fixed"
    local wbrec 0
    local wbfix 0
    foreach w of local wbtype {
        if inlist("`w'", "recursive", "rec", "r") local wbrec 1
        else if inlist("`w'", "fixed", "fix", "f") local wbfix 1
        else {
            di as err "wbtype() must be recursive, fixed or both"
            exit 198
        }
    }
    local doboot = ("`bootstrap'" != "")
    if (`doboot' | `ca' > 0) & `reps' < 19 {
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
        di as err "cointvol diag requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local N0 = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `N0' {
        di as err "the estimation sample contains gaps; cointvol diag needs consecutive observations"
        exit 498
    }
    local p : word count `varlist'
    local T = `N0' - `lags'
    if `T' < `p'*`lags' + 10 {
        di as err "too few observations (" `N0' ") for p = `p' variables and `lags' lags"
        exit 2001
    }
    if `rank' == -1 local rank = `p'
    if `rank' < 0 | `rank' > `p' {
        di as err "rank() must lie in 0,...,`p'"
        exit 198
    }
    foreach o in archlm march ca et aclm portmanteau lingli {
        if ``o'' >= `T'/3 & ``o'' > 0 {
            di as err "`o'(``o'') is too large for T = `T' effective observations"
            exit 198
        }
    }
    if `march' > 0 {
        if `T' <= 1 + `march'*`p'*(`p'+1)/2 + 5 {
            di as err "march(`march'): too few observations for the auxiliary regression"
            exit 2001
        }
    }
    if `portmanteau' > 0 {
        local pdf = `p'*`p'*(`portmanteau' - `lags' + 1) - `p'*`rank'
        if `pdf' <= 0 {
            di as err "portmanteau(`portmanteau'): degrees of freedom K^2(h-k+1)-Kr = `pdf' <= 0; increase h"
            exit 198
        }
    }
    if "`llvcov'" != "" {
        local nllv : word count `llvcov'
        if `nllv' != `p'*(`p'+1)/2 {
            di as err "llvcov() needs p(p+1)/2 = `=`p'*(`p'+1)/2' variables: vech(V_t) = v11 v21 ... vp1 v22 ... vpp"
            exit 198
        }
    }
    if "`spreadgarch'" != "" {
        if `rank' < 1 | `rank' >= `p' {
            di as err "spreadgarch requires a cointegrated model, 0 < rank() < `p'"
            exit 198
        }
    }

    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    tsrevar `varlist'
    local mvars "`r(varlist)'"

    local ectn ""
    if "`spreadgarch'" != "" {
        forvalues j = 1/`rank' {
            tempvar ect`j'
            qui gen double `ect`j'' = .
            local ectn "`ectn' `ect`j''"
        }
    }

    local vpn ""
    if "`graph'" != "" {
        forvalues j = 1/`p' {
            tempvar vpv`j'
            qui gen double `vpv`j'' = .
            local vpn "`vpn' `vpv`j''"
        }
    }

    local dots = ("`nodots'" == "")
    local runboot = (`ca' > 0) | (`doboot' & (`march' > 0 | `et' > 0 | `etst' > 0 | `aclm' > 0))
    if !`runboot' local dots 0
    local etc = ("`etchol'" != "")
    local llvn ""
    if "`llvcov'" != "" {
        tsrevar `llvcov'
        local llvn "`r(varlist)'"
    }
    capture matrix drop __cvd_vp
    mata: cvd_diag_main("`mvars'", "`touse'", `lags', "`trend'", `rank', `archlm', ///
        `march', `ca', `et', `aclm', `portmanteau', `doboot', `reps', "`multiplier'", ///
        `wbrec', `wbfix', `dots', "`ectn'", "`vpn'", `etc', `etst', `lingli', ///
        `llarch', "`llvn'")

    tempname archm multi cam acm port vp vpm roots alpha beta bnorm lltab llacf
    matrix `archm' = __cvd_archlm
    matrix `multi' = __cvd_multi
    matrix `cam'   = __cvd_ca
    matrix `acm'   = __cvd_ac
    matrix `port'  = __cvd_port
    matrix `lltab' = __cvd_lltab
    matrix `llacf' = __cvd_llacf
    local hasvp 0
    capture confirm matrix __cvd_vp
    if !_rc {
        matrix `vp' = __cvd_vp
        local hasvp 1
    }
    matrix `vpm'   = __cvd_vpmax
    matrix `roots' = __cvd_roots
    if `rank' > 0 {
        matrix `alpha' = __cvd_alpha
        matrix `beta'  = __cvd_beta
    }
    if "`spreadgarch'" != "" {
        matrix `bnorm' = __cvd_bnorm
    }
    local Teff  = scalar(__cvd_T)
    local ll    = scalar(__cvd_ll)
    local gLM   = scalar(__cvd_gLM)
    local nunit = scalar(__cvd_nunit)
    local nexp  = scalar(__cvd_nexp)
    local lstab = scalar(__cvd_lstab)
    local fa    = scalar(__cvd_fa)
    local fw    = scalar(__cvd_fw)
    foreach m in archlm multi ca ac port vp vpmax roots alpha beta bnorm lltab llacf {
        capture matrix drop __cvd_`m'
    }
    foreach m in T ll gLM nunit nexp lstab fa fw {
        capture scalar drop __cvd_`m'
    }

    // names
    local eqn ""
    forvalues i = 1/`p' {
        local nm : word `i' of `varlist'
        local nm = subinstr("`nm'", ".", "_", .)
        local eqn "`eqn' `nm'"
    }
    matrix colnames `archm' = LM df p R2
    matrix rownames `archm' = `eqn'
    matrix colnames `multi' = stat df p_asy p_boot
    matrix rownames `multi' = MARCH ET CA ETST
    matrix colnames `cam'   = LM df p_asy p_boot
    matrix rownames `cam'   = `eqn'
    matrix colnames `acm'   = Q df p_asy p_wbrec p_wbfix
    matrix rownames `acm'   = LM HC0 HC1 HC2 HC3
    matrix colnames `port'  = Q Qadj df p padj
    matrix colnames `lltab' = stat df p
    matrix rownames `lltab' = Q_M Q_M_adj Q_rM Q_rM_adj
    matrix colnames `llacf' = R_l se z
    local lrn ""
    forvalues j = 1/`=rowsof(`llacf')' {
        local lrn "`lrn' lag`j'"
    }
    matrix rownames `llacf' = `lrn'
    if `hasvp' matrix colnames `vp' = `eqn'
    matrix colnames `vpm'   = maxdev u_at dev_at
    matrix rownames `vpm'   = `eqn'
    matrix colnames `roots' = modulus

    // ---------------- labels ----------------------------------------------
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`trend'" == "trend"     local tlab "unrestricted trend"
    local s1 = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local eta   = 1 - `level'/100
    local lev   : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")
    if `rank' == `p' local mlab "unrestricted VAR (r = p)"
    else local mlab "VECM with rank r = `rank'"

    // ---------------- header ----------------------------------------------
    di
    di as txt "Residual diagnostics" _col(52) "Number of obs  = " as res %9.0f `Teff'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Variables (p)  = " as res %9.0f `p'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags (levels)  = " as res %9.0f `lags'
    di as txt "Model: " as res "`mlab'" as txt _col(52) "Rank (r)       = " as res %9.0f `rank'
    di as txt "Gaussian log likelihood = " as res %12.4f `ll'
    if `runboot' {
        di as txt "Bootstrap replications: " as res `reps' as txt "   Seed: " as res `"`seeduse'"'
    }

    // ---------------- (1) univariate ARCH-LM --------------------------------
    if `archlm' > 0 {
        di
        di as txt "Univariate ARCH-LM tests (Engle 1982), order h = `archlm'"
        di as txt "{hline 22}{c TT}{hline 46}"
        di as txt "  Equation" _col(23) "{c |}" _col(28) "LM (n R2)" _col(42) "df" _col(50) "p-value" _col(63) "R2"
        di as txt "{hline 22}{c +}{hline 46}"
        forvalues i = 1/`p' {
            local nm : word `i' of `varlist'
            local nm = abbrev("`nm'", 19)
            local pv = `archm'[`i', 3]
            local s = cond(`pv' < `eta', "*", " ")
            di as txt "  `nm'" _col(23) "{c |}" as res _col(25) %12.3f `archm'[`i', 1] ///
                _col(40) %4.0f `archm'[`i', 2] _col(48) %8.4f `pv' as txt "`s'" ///
                as res _col(59) %8.4f `archm'[`i', 4]
        }
        di as txt "{hline 22}{c BT}{hline 46}"
        di as txt "H0: no ARCH up to order h; n = T - h; chi2(h) p-values; residuals of the fitted model."
    }

    // ---------------- (2) multivariate ARCH tests ----------------------------
    if `march' + `et' + `ca' + `etst' > 0 {
        di
        di as txt "Multivariate ARCH / covariance-constancy tests"
        di as txt "{hline 26}{c TT}{hline 46}"
        di as txt "  Test" _col(27) "{c |}" _col(30) "Statistic" _col(44) "df" _col(51) "Asy. p" _col(62) "Boot. p"
        di as txt "{hline 26}{c +}{hline 46}"
        local rlab1 "MARCH, h = `march'"
        local rlab2 "ET (CCC-ARCH), h = `et'"
        local rlab3 "CA combined, h = `ca'"
        local rlab4 "ET smooth trans., s = `etst'"
        if `etc' local rlab2 "ET (Cholesky), h = `et'"
        local hh1 `march'
        local hh2 `et'
        local hh3 `ca'
        local hh4 `etst'
        forvalues i = 1/4 {
            if `hh`i'' > 0 {
                local pa = `multi'[`i', 3]
                local pb = `multi'[`i', 4]
                local sa = cond(`pa' < `eta', "*", " ")
                local sb = cond(`pb' < `eta', "*", " ")
                if `pa' >= . local sa " "
                if `pb' >= . local sb " "
                di as txt "  `rlab`i''" _col(27) "{c |}" as res _col(28) %11.3f `multi'[`i', 1] ///
                    _col(40) %6.0f `multi'[`i', 2] _col(49) %7.4f `pa' as txt "`sa'" ///
                    as res _col(60) %7.4f `pb' as txt "`sb'"
            }
        }
        di as txt "{hline 26}{c BT}{hline 46}"
        if `march' > 0 di as txt "MARCH: LM on vech(w_t w_t') (Cholesky-standardised), df K^2(K+1)^2 h/4 (Lutkepohl 2006)."
        if `et' > 0 & !`etc' {
            di as txt "ET: LM (14) against CCC-ARCH(h) on the residuals, df K h (Eklund & Terasvirta 2007, Th. 1)."
        }
        if `et' > 0 & `etc' {
            di as txt "ET: CCC-ARCH(h) LM on Cholesky-standardised residuals (VARtests variant), df K h."
        }
        if `etst' > 0 {
            di as txt "ET smooth transition: LM (14) with v_it = (1, t/T, ..., (t/T)^s)', df K s (ET 2007, s.5.3)."
        }
        if `ca' > 0 {
            di as txt "CA: max_i LM_i = N R2_i (equivalently 1 - min_i p_i = " as res %6.4f `gLM' ///
                as txt "); bootstrap only (Catani & Ahlgren 2017)."
        }
        if `runboot' & (`ca' > 0 | `doboot') {
            di as txt "Bootstrap: parametric Gaussian, fixed design (Catani & Ahlgren 2017, Algorithm 1);"
            di as txt "           p = (#{LM* >= LM} + 1)/(B + 1)."
        }
        if `ca' > 0 {
            di
            di as txt "Catani-Ahlgren equation-by-equation LM statistics, h = `ca'"
            di as txt "{hline 22}{c TT}{hline 40}"
            di as txt "  Equation" _col(23) "{c |}" _col(28) "LM_i" _col(38) "df" _col(46) "Asy. p" _col(56) "Boot. p"
            di as txt "{hline 22}{c +}{hline 40}"
            forvalues i = 1/`p' {
                local nm : word `i' of `varlist'
                local nm = abbrev("`nm'", 19)
                local pa = `cam'[`i', 3]
                local pb = `cam'[`i', 4]
                local sa = cond(`pa' < `eta', "*", " ")
                local sb = cond(`pb' < `eta' & `pb' < ., "*", " ")
                di as txt "  `nm'" _col(23) "{c |}" as res _col(24) %10.3f `cam'[`i', 1] ///
                    _col(36) %4.0f `cam'[`i', 2] _col(44) %7.4f `pa' as txt "`sa'" ///
                    as res _col(54) %7.4f `pb' as txt "`sb'"
            }
            di as txt "{hline 22}{c BT}{hline 40}"
        }
    }

    // ---------------- (3) residual autocorrelation ---------------------------
    if `aclm' > 0 {
        local acdf = `aclm'*`p'*`p'
        di
        di as txt "Residual autocorrelation LM tests, h = `aclm' (df = h K^2 = `acdf')"
        di as txt "{hline 12}{c TT}{hline 58}"
        di as txt "  Version" _col(13) "{c |}" _col(16) "Statistic" _col(30) "df" _col(37) "Asy. p" ///
            _col(47) "WB rec. p" _col(60) "WB fix. p"
        di as txt "{hline 12}{c +}{hline 58}"
        local ii 0
        foreach h in lm hc0 hc1 hc2 hc3 {
            local ii = `ii' + 1
            if strpos(" `hcshow' ", " `h' ") {
                local pa = `acm'[`ii', 3]
                local pr = `acm'[`ii', 4]
                local pf = `acm'[`ii', 5]
                local sa = cond(`pa' < `eta', "*", " ")
                local sr = cond(`pr' < `eta' & `pr' < ., "*", " ")
                local sf = cond(`pf' < `eta' & `pf' < ., "*", " ")
                local hu = strupper("`h'")
                di as txt "  `hu'" _col(13) "{c |}" as res _col(14) %11.3f `acm'[`ii', 1] ///
                    _col(26) %6.0f `acm'[`ii', 2] _col(35) %7.4f `pa' as txt "`sa'" ///
                    as res _col(47) %7.4f `pr' as txt "`sr'" as res _col(60) %7.4f `pf' as txt "`sf'"
            }
        }
        di as txt "{hline 12}{c BT}{hline 58}"
        di as txt "H0: no residual autocorrelation up to lag h. LM: Breusch-Godfrey form; HC0-HC3:"
        di as txt "heteroskedasticity-consistent Wald-type versions (Ahlgren & Catani 2017)."
        if `doboot' {
            di as txt "Wild bootstrap (" as res "`multiplier'" as txt " multipliers): recursive design re-simulates the"
            di as txt "fitted VECM and re-estimates rank `rank'; fixed design keeps the regressors (Algorithms 1-2)."
        }
    }

    // ---------------- (4) portmanteau -----------------------------------------
    if `portmanteau' > 0 {
        local pq  = `port'[1, 1]
        local pqa = `port'[1, 2]
        local pdf = `port'[1, 3]
        local pp  = `port'[1, 4]
        local ppa = `port'[1, 5]
        di
        di as txt "Multivariate portmanteau test, h = `portmanteau' (df = K^2(h-k+1) - K r = `pdf')"
        di as txt "{hline 22}{c TT}{hline 26}"
        di as txt "  Statistic" _col(23) "{c |}" _col(28) "Value" _col(40) "p-value"
        di as txt "{hline 22}{c +}{hline 26}"
        di as txt "  Q_h" _col(23) "{c |}" as res _col(24) %10.3f `pq' _col(38) %8.4f `pp' ///
            as txt cond(`pp' < `eta', "*", " ")
        di as txt "  adjusted Q_h" _col(23) "{c |}" as res _col(24) %10.3f `pqa' _col(38) %8.4f `ppa' ///
            as txt cond(`ppa' < `eta', "*", " ")
        di as txt "{hline 22}{c BT}{hline 26}"
        di as txt "Lutkepohl (2006): chi2 approximation requires h large relative to k."
    }

    // ---------------- (4b) Ling-Li portmanteau ---------------------------------
    if `lingli' > 0 {
        local lr `llarch'
        local ll1 "Q(M), eq. (3.10)"
        local ll2 "Q(M) adj., eq. (4.6)"
        local ll3 "Q(`lr',`lingli'), eq. (3.11)"
        local ll4 "Q(`lr',`lingli') adj., (4.6)"
        di
        di as txt "Ling-Li (1997) portmanteau test on q_t = e_t' V_t{c 94}-1 e_t, M = `lingli'"
        di as txt "{hline 28}{c TT}{hline 36}"
        di as txt "  Statistic" _col(29) "{c |}" _col(34) "Value" _col(46) "df" _col(54) "p-value"
        di as txt "{hline 28}{c +}{hline 36}"
        forvalues i = 1/4 {
            local sv = `lltab'[`i', 1]
            if `sv' < . {
                local pv = `lltab'[`i', 3]
                local sa = cond(`pv' < `eta', "*", " ")
                di as txt "  `ll`i''" _col(29) "{c |}" as res _col(30) %10.3f `sv' ///
                    _col(43) %5.0f `lltab'[`i', 2] _col(52) %8.4f `pv' as txt "`sa'"
            }
        }
        di as txt "{hline 28}{c BT}{hline 36}"
        local line ""
        forvalues j = 1/`lingli' {
            local m : display %7.4f `llacf'[`j', 1]
            local line "`line' `m'"
        }
        di as txt "R_l, l = 1..M (eq. 2.11):" as res "`line'"
        di as txt "Crude s.e. of R_l = 1/sqrt(n) = " as res %6.4f `llacf'[1, 2] ///
            as txt ".  H0: no remaining conditional heteroskedasticity."
        if "`llvcov'" == "" {
            di as txt "V_t = unconditional ML covariance E'E/n: X = 0, so Omega = I_M and Q(M) ~ chi2(M)"
            di as txt "(Ling & Li 1997, Theorem and p. 453). Adjusted: factor n - M - 2K - k - q + 1."
        }
        else {
            di as txt "V_t from llvcov(`llvcov'); Omega set to I_M (the X, A, B terms of the fitted"
            di as txt "variance model are not available here): chi2(M) is typically conservative (p. 453)."
            if `lr' > 0 di as txt "Q(r,M): drops the first r = `lr' lags, chi2(M - r), for an ARCH(r) V_t (eq. 3.11)."
        }
    }

    // ---------------- (5) variance profile -----------------------------------
    if "`varprofile'" != "" {
        di
        di as txt "Variance profiles eta_i(u) = sum_{t<=Tu} e_it^2 / sum_t e_it^2 (CRT 2010, s.6)"
        di as txt "{hline 22}{c TT}{hline 38}"
        di as txt "  Equation" _col(23) "{c |}" _col(26) "max|eta(u)-u|" _col(43) "at u" _col(51) "eta(u)-u"
        di as txt "{hline 22}{c +}{hline 38}"
        forvalues i = 1/`p' {
            local nm : word `i' of `varlist'
            local nm = abbrev("`nm'", 19)
            di as txt "  `nm'" _col(23) "{c |}" as res _col(27) %10.4f `vpm'[`i', 1] ///
                _col(40) %7.3f `vpm'[`i', 2] _col(50) %9.4f `vpm'[`i', 3]
        }
        di as txt "{hline 22}{c BT}{hline 38}"
        di as txt "Homoskedasticity: eta_i(u) = u (45-degree line). Positive deviation: variance higher"
        di as txt "early in the sample; negative: variance higher late (Cavaliere & Taylor 2007)."
    }

    // ---------------- (6) roots -----------------------------------------------
    if "`roots'" != "" {
        local nr = rowsof(`roots')
        di
        di as txt "Companion-matrix moduli of the fitted model (`nr' roots, descending)"
        local line ""
        forvalues j = 1/`nr' {
            local m : display %8.4f `roots'[`j', 1]
            local line "`line' `m'"
            if mod(`j', 8) == 0 | `j' == `nr' {
                di as res "`line'"
                local line ""
            }
        }
        di as txt "Unit roots (|mod - 1| < 1e-5): " as res `nunit' as txt "  (p - r = " as res `p' - `rank' ///
            as txt ");  explosive: " as res `nexp' as txt ";  largest stable modulus: " as res %6.4f `lstab'
    }

    // ---------------- (7) spread GARCH (extended) -----------------------------
    tempname sg
    if "`spreadgarch'" != "" {
        matrix `sg' = J(`rank', 9, .)
        tempname esthold
        _estimates hold `esthold', restore nullok
        forvalues j = 1/`rank' {
            capture qui arch `ect`j'' if `touse', arch(1) garch(1)
            if !_rc {
                matrix `sg'[`j', 1] = _b[ARCH:_cons]
                matrix `sg'[`j', 2] = _b[ARCH:L.arch]
                matrix `sg'[`j', 3] = _se[ARCH:L.arch]
                matrix `sg'[`j', 4] = _b[ARCH:L.garch]
                matrix `sg'[`j', 5] = _se[ARCH:L.garch]
                matrix `sg'[`j', 6] = _b[ARCH:L.arch] + _b[ARCH:L.garch]
                if `sg'[`j', 6] < 1 & `sg'[`j', 6] > 0 {
                    matrix `sg'[`j', 7] = ln(0.5) / ln(`sg'[`j', 6])
                }
                matrix `sg'[`j', 8] = e(ll)
                matrix `sg'[`j', 9] = e(converged)
            }
        }
        matrix colnames `sg' = omega arch se_arch garch se_garch persist halflife ll converged
        local rn ""
        forvalues j = 1/`rank' {
            local rn "`rn' ect`j'"
        }
        matrix rownames `sg' = `rn'
        di
        di as txt "EXTENDED: two-step univariate GARCH(1,1) on the estimated ECT(s) [contrast case]"
        di as txt "{hline 7}{c TT}{hline 66}"
        di as txt "  ECT" _col(8) "{c |}" _col(12) "omega" _col(21) "ARCH a" _col(31) "GARCH b" _col(41) "a + b" ///
            _col(49) "half-life" _col(61) "log L" _col(70) "conv."
        di as txt "{hline 7}{c +}{hline 66}"
        forvalues j = 1/`rank' {
            di as txt "  `j'" _col(8) "{c |}" as res _col(9) %9.4f `sg'[`j', 1] _col(19) %8.4f `sg'[`j', 2] ///
                _col(29) %8.4f `sg'[`j', 4] _col(39) %7.4f `sg'[`j', 6] _col(48) %9.2f `sg'[`j', 7] ///
                _col(58) %9.2f `sg'[`j', 8] _col(71) %2.0f `sg'[`j', 9]
        }
        di as txt "{hline 7}{c BT}{hline 66}"
        di as txt "ECT_j = beta_j'(y_{t-1}, D_t) with beta normalised on the first r variables; GARCH fitted by"
        di as txt "-arch- on the generated regressor. Two-step approach: estimation error in beta is ignored."
        di as txt "The joint VECM-GARCH estimators of -cointvol vecmgarch- are the recommended alternative."
    }

    // ---------------- graph (before return matrix moves) ---------------------
    if "`graph'" != "" {
        tempvar uu
        qui gen double `uu' = sum(`vpv1' < .) / `Teff' if `vpv1' < .
        local cols "navy cranberry forest_green dkorange teal maroon purple olive_teal"
        local plots ""
        local labs ""
        forvalues i = 1/`p' {
            local c : word `=mod(`i'-1, 8)+1' of `cols'
            local nm : word `i' of `varlist'
            local plots "`plots' (line `vpv`i'' `uu', lcolor(`c') lwidth(medthin))"
            local labs `"`labs' label(`i' "`nm'")"'
        }
        local k1 = `p' + 1
        if `"`graphname'"' == "" local graphname "cointvol_varprofile"
        twoway `plots' (line `uu' `uu', lcolor(gs10) lpattern(dash)), ///
            legend(`labs' label(`k1' "45-degree line") rows(1) size(small)) ///
            xtitle("u = t/T", size(small)) ytitle("variance profile", size(small)) ///
            title("Variance profiles of the residuals", size(medium)) ///
            note("CRT (2010, s.6): homoskedastic errors give the 45-degree line. `mlab', k = `lags'.", size(vsmall)) ///
            graphregion(color(white)) plotregion(color(white)) name(`graphname', replace)
    }

    // ---------------- stored results --------------------------------------
    return scalar N     = `Teff'
    return scalar p     = `p'
    return scalar lags  = `lags'
    return scalar rank  = `rank'
    return scalar level = `level'
    return scalar ll    = `ll'
    if `runboot' {
        return scalar reps = `reps'
        return scalar boot_fail_arch = `fa'
        return scalar boot_fail_wild = `fw'
    }
    if `archlm' > 0 return scalar h_archlm = `archlm'
    if `march' > 0 {
        return scalar h_march = `march'
        return scalar march   = `multi'[1, 1]
        return scalar p_march = `multi'[1, 3]
        if `doboot' return scalar pb_march = `multi'[1, 4]
    }
    if `et' > 0 {
        return scalar h_et = `et'
        return scalar et   = `multi'[2, 1]
        return scalar p_et = `multi'[2, 3]
        if `doboot' return scalar pb_et = `multi'[2, 4]
        if `etc' return local et_type "cholesky"
        else return local et_type "residuals"
    }
    if `etst' > 0 {
        return scalar h_etst = `etst'
        return scalar etst   = `multi'[4, 1]
        return scalar p_etst = `multi'[4, 3]
        if `doboot' return scalar pb_etst = `multi'[4, 4]
    }
    if `lingli' > 0 {
        return scalar h_lingli     = `lingli'
        return scalar llarch       = `llarch'
        return scalar lingli       = `lltab'[1, 1]
        return scalar p_lingli     = `lltab'[1, 3]
        return scalar lingli_adj   = `lltab'[2, 1]
        return scalar p_lingli_adj = `lltab'[2, 3]
        if `llarch' > 0 {
            return scalar lingli_r   = `lltab'[3, 1]
            return scalar p_lingli_r = `lltab'[3, 3]
        }
        return local llvcov "`llvcov'"
    }
    if `ca' > 0 {
        return scalar h_ca  = `ca'
        return scalar ca    = `multi'[3, 1]
        return scalar ca_g  = `gLM'
        return scalar pb_ca = `multi'[3, 4]
    }
    if `aclm' > 0 {
        return scalar h_aclm  = `aclm'
        return scalar aclm    = `acm'[1, 1]
        return scalar p_aclm  = `acm'[1, 3]
    }
    if `portmanteau' > 0 {
        return scalar h_port = `portmanteau'
        return scalar port   = `port'[1, 1]
        return scalar p_port = `port'[1, 4]
    }
    return scalar n_unit     = `nunit'
    return scalar n_explosive = `nexp'
    return local varlist    "`varlist'"
    return local trend      "`trend'"
    return local multiplier "`multiplier'"
    return local wbtype     "`wbtype'"
    return local seed       `"`seed'"'
    return local cmd        "cointvol diag"
    if `archlm' > 0 return matrix archlm = `archm'
    if `march' + `et' + `ca' + `etst' > 0 return matrix multarch = `multi'
    if `lingli' > 0 {
        return matrix lingli_tab = `lltab'
        return matrix lingli_acf = `llacf'
    }
    if `ca' > 0 return matrix ca = `cam'
    if `aclm' > 0 return matrix aclm_tab = `acm'
    if `portmanteau' > 0 return matrix portmanteau = `port'
    return matrix vprofile_max = `vpm'
    if `hasvp' return matrix vprofile = `vp'
    return matrix roots        = `roots'
    if `rank' > 0 {
        return matrix alpha = `alpha'
        return matrix beta  = `beta'
    }
    if "`spreadgarch'" != "" {
        return matrix beta_norm   = `bnorm'
        return matrix spreadgarch = `sg'
    }
end
