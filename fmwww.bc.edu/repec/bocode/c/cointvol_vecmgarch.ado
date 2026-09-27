*! cointvol_vecmgarch 0.1.0  26sep2026
*! Joint (Q)ML estimation of a cointegrated VAR / VECM with multivariate GARCH errors
*! (mean and variance estimated jointly; two-step and LS variants)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_vecmgarch.sthlp, section Methods):
*!   mean dX_t = alpha beta#'Z1_t + sum Gamma_i dX_{t-i} + det + e_t      Lee (1994) eq (1); LLW (2001) eq (2.1);
*!     c'beta = I_r (normalize()), beta() fixed (Lee: z = f - s)           Seo (2007) eq (1); BDV (1997) eqs (3)-(4)
*!   variance(dbekk) [+ garchx()]  H = C'C + A'ee'A + B'HB [+ D'D x^2]     Lee (1994) eq (2)
*!   variance(bekk)                H = C'C + sum A'ee'A + sum G'HG          BDV (1997) eqs (5)-(7)
*!   variance(cccgarch)            CCC-GARCH(p,q)                          Sin, Mi & Ling (2024) eq (2.3)
*!   variance(ecccgarch)           h = w + A e~^2 + B h, Gamma = I          Wong, Li & Ling (2005) eq (2.2)
*!   variance(darch)               diagonal ARCH(q)                        Li, Ling & Wong (2001) eq (4.1)
*!   variance(trigarch)            Omega_t = L^-1 diag(s2_jt) L^-1'         Seo (2007) eqs (3)-(4)
*!   method(qmle): joint Gaussian QMLE, RRR start                          Seo (2007) eq (7); Lee (1994) Sec II
*!   method(twostep): variance on LS/RRR residuals, mean given variance    LLW (2001) Secs 3-4; WLL (2005) Secs 3-4
*!   vce(robust) sandwich; only the sandwich Wald is chi2 (non-normal)     Bollerslev & Wooldridge (1992); Seo Thm 2

program define cointvol_vecmgarch, eclass sortpreserve
    version 14.0

    // ---------------- load / reload the Mata engines ---------------------
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

    if replay() {
        if `"`e(cmd)'"' != "cointvol vecmgarch" {
            error 301
        }
        syntax [, BRief LEVel(cilevel)]
        _cvg_display, `brief' level(`level')
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in], LAgs(integer)                      ///
        [ RAnk(integer -1) FULLrank BETA(numlist) NORMalize(string)              ///
          TRend(string) VARiance(string) ARCH(integer -1) GARCH(integer -1)      ///
          GARCHX(string) Method(string) TECHnique(string) ITERate(integer 500)   ///
          STARTs(integer 0) SEED(string) VCE(string) NONCONVok UNCONstrained     ///
          LEVel(cilevel) LOG NOLOG NOVCE BRief ]

    local cmdline `"cointvol vecmgarch `0'"'

    // ---------------- options --------------------------------------------
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "constant"
    if inlist(`"`trend'"', "n", "no", "non", "none")                        local trend "none"
    else if inlist(`"`trend'"', "rc", "rco", "rcon", "rconst", "rconstant") local trend "rconstant"
    else if inlist(`"`trend'"', "c", "co", "con", "const", "constant")      local trend "constant"
    else if inlist(`"`trend'"', "rt", "rtr", "rtrend")                      local trend "rtrend"
    else if inlist(`"`trend'"', "t", "tr", "trend")                         local trend "trend"
    else {
        di as err "trend() must be one of none, rconstant, constant, rtrend, trend"
        exit 198
    }

    local variance = strlower(strtrim(`"`variance'"'))
    local vgiven = (`"`variance'"' != "")
    if `"`variance'"' == "" local variance "dbekk"
    if inlist(`"`variance'"', "dbekk", "diagbekk", "diag")                  local variance "dbekk"
    else if inlist(`"`variance'"', "bekk", "fullbekk")                      local variance "bekk"
    else if inlist(`"`variance'"', "ccc", "cccgarch")                       local variance "cccgarch"
    else if inlist(`"`variance'"', "eccc", "ecccgarch")                     local variance "ecccgarch"
    else if inlist(`"`variance'"', "darch", "arch", "diagarch")             local variance "darch"
    else if inlist(`"`variance'"', "tri", "trigarch", "triangular")         local variance "trigarch"
    else if inlist(`"`variance'"', "none", "const", "homoskedastic")        local variance "none"
    else {
        di as err "variance() must be one of dbekk, bekk, cccgarch, ecccgarch, darch, trigarch, none"
        exit 198
    }

    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "qmle"
    if inlist(`"`method'"', "ml", "mle", "qml", "qmle")        local method "qmle"
    else if inlist(`"`method'"', "two", "twostep", "2step")    local method "twostep"
    else if inlist(`"`method'"', "ls", "ols", "rrr")           local method "ls"
    else {
        di as err "method() must be qmle, twostep or ls"
        exit 198
    }
    if "`method'" == "ls" & "`variance'" != "none" {
        if `vgiven' {
            di as txt "(note: method(ls) fits the homoskedastic Gaussian VECM; variance() ignored)"
        }
        local variance "none"
    }
    if "`variance'" == "none" & "`method'" != "ls" {
        di as txt "(note: variance(none) is estimated by LS/RRR, the exact Gaussian ML; method(ls) used)"
        local method "ls"
    }

    local vce = strlower(strtrim(`"`vce'"'))
    if `"`vce'"' == "" local vce "robust"
    if inlist(`"`vce'"', "r", "ro", "rob", "robu", "robus", "robust", "sandwich") local vce "robust"
    else if inlist(`"`vce'"', "oim", "hessian")                                    local vce "oim"
    else if inlist(`"`vce'"', "opg", "outer")                                      local vce "opg"
    else {
        di as err "vce() must be robust, oim or opg"
        exit 198
    }

    local technique = strlower(strtrim(`"`technique'"'))
    if `"`technique'"' == "" local technique "bfgs"
    local w1 : word 1 of `technique'
    if !inlist("`w1'", "nr", "bhhh", "bfgs", "dfp") {
        di as err "technique() must start with nr, bhhh, bfgs or dfp"
        exit 198
    }
    foreach w of local technique {
        if !inlist("`w'", "nr", "bhhh", "bfgs", "dfp") {
            capture confirm integer number `w'
            if _rc {
                di as err "technique(): `w' is not a valid technique or iteration count"
                exit 198
            }
        }
    }
    if `iterate' < 1 {
        di as err "iterate() must be a positive integer"
        exit 198
    }
    if `starts' < 0 {
        di as err "starts() must be a nonnegative integer"
        exit 198
    }
    if `lags' < 1 {
        di as err "lags() must be a positive integer (lag order of the VAR in levels)"
        exit 198
    }

    // ARCH / GARCH orders
    if inlist("`variance'", "dbekk", "ecccgarch", "trigarch") {
        if (`arch' != -1 & `arch' != 1) | (`garch' != -1 & `garch' != 1) {
            di as err "variance(`variance') is of order (1,1); arch() and garch() cannot be changed"
            exit 198
        }
        local arch 1
        local garch 1
    }
    if inlist("`variance'", "bekk", "cccgarch") {
        if `arch' == -1 local arch 1
        if `garch' == -1 local garch 1
        if `arch' < 1 | `arch' > 10 | `garch' < 0 | `garch' > 10 {
            di as err "arch() must lie in 1,...,10 and garch() in 0,...,10"
            exit 198
        }
    }
    if "`variance'" == "darch" {
        if `arch' == -1 local arch 1
        if `garch' > 0 {
            di as err "variance(darch) has no GARCH terms; use variance(cccgarch) for GARCH"
            exit 198
        }
        if `arch' < 1 | `arch' > 20 {
            di as err "arch() must lie in 1,...,20"
            exit 198
        }
        local garch 0
    }
    if "`variance'" == "none" {
        local arch 0
        local garch 0
    }

    // ---------------- time-series checks ----------------------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol vecmgarch requires time-series data; the data are xtset as a panel"
        exit 459
    }
    sort `tvar'
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
        di as err "the estimation sample contains gaps; cointvol vecmgarch needs consecutive observations"
        exit 498
    }
    local p : word count `varlist'
    local nd1 = inlist("`trend'", "rconstant", "rtrend")
    local p1 = `p' + `nd1'
    local T = `N0' - `lags'
    if `T' < `p'*(`p'*(`lags' - 1) + `p1' + 2) + 30 {
        di as err "too few observations (" `N0' ") for p = `p' variables and `lags' lags"
        exit 2001
    }

    // ---------------- cointegration rank / beta ----------------------------
    local nrk = ("`fullrank'" != "") + (`rank' >= 0) + ("`beta'" != "")
    if "`fullrank'" != "" & `nrk' > 1 {
        di as err "fullrank cannot be combined with rank() or beta()"
        exit 198
    }
    local bvals ""
    local nidx ""
    if "`beta'" != "" {
        local rmode "fixed"
        local bvals "`beta'"
        local nb : word count `beta'
        if `rank' >= 0 {
            local r = `rank'
            if `r' < 1 | (`nb' != `p'*`r' & `nb' != `p1'*`r') {
                di as err "beta() must contain p*r = `=`p'*max(`rank',1)' (levels) or p1*r = `=`p1'*max(`rank',1)' values"
                exit 198
            }
        }
        else {
            if mod(`nb', `p') == 0 {
                local r = `nb'/`p'
            }
            else if mod(`nb', `p1') == 0 {
                local r = `nb'/`p1'
            }
            else {
                di as err "beta() must contain p*r (levels only) or p1*r values, column by column"
                exit 198
            }
        }
        if `r' >= `p' {
            di as err "beta(): the number of cointegrating vectors must be below p = `p'"
            exit 198
        }
        local rdisp = `r'
    }
    else if "`fullrank'" != "" {
        local rmode "full"
        local r = `p1'
        local rdisp = `p'
    }
    else {
        if `rank' == -1 {
            di as txt "(note: rank(1) assumed)"
            local rank 1
        }
        if `rank' >= `p' {
            di as err "rank() must lie in 0,...,p-1 = `=`p'-1'; use fullrank for a stationary VAR"
            exit 198
        }
        local r = `rank'
        local rdisp = `rank'
        local rmode "est"
        if `rank' == 0 local rmode "zero"
    }
    if `"`normalize'"' != "" & "`rmode'" != "est" {
        di as err "normalize() is only allowed when beta is estimated (rank() with 1 <= r < p)"
        exit 198
    }
    if "`rmode'" == "est" {
        if `"`normalize'"' != "" {
            tsunab normalize : `normalize'
            local nn : word count `normalize'
            local nu : list uniq normalize
            local nnu : word count `nu'
            if `nn' != `r' | `nnu' != `r' {
                di as err "normalize() must list exactly r = `r' distinct variables of the varlist"
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
            forvalues i = 1/`r' {
                local nidx "`nidx' `i'"
                local v : word `i' of `varlist'
                local normalize "`normalize' `v'"
            }
        }
        local normalize = strtrim("`normalize'")
    }

    // ---------------- GARCH-X regressors -----------------------------------
    local xmode "none"
    local xvars ""
    local xlag ""
    if `"`garchx'"' != "" {
        if !inlist("`variance'", "dbekk", "bekk") {
            di as err "garchx() requires variance(dbekk) or variance(bekk)"
            exit 198
        }
        if strlower(strtrim(`"`garchx'"')) == "ect" {
            if inlist("`rmode'", "full", "zero") {
                di as err "garchx(ect) needs error-correction terms (1 <= rank < p)"
                exit 198
            }
            local xmode "ect"
        }
        else {
            tsunab xvars : `garchx'
            local xmode "vars"
            tsrevar L.(`xvars')
            local xlag "`r(varlist)'"
        }
    }

    // seed
    if `"`seed'"' != "" {
        set seed `seed'
    }

    // ---------------- estimation sample (effective) ------------------------
    tempvar esamp
    qui gen byte `esamp' = `touse'
    qui replace `esamp' = 0 if `tvar' < `tmin' + `lags'*`tdelta'

    tsrevar `varlist'
    local mvars "`r(varlist)'"
    local dn ""
    foreach v of local varlist {
        local nm = substr(strtoname("`v'"), 1, 28)
        local dn "`dn' `nm'"
    }
    local dn = strtrim("`dn'")
    local trace = ("`log'" != "" & "`nolog'" == "")
    local uncon = ("`unconstrained'" != "")
    local nv = ("`novce'" != "")

    foreach m in b V Vopg Voim alpha beta Pi bfree Gamma H Hbar H0 persist llst {
        capture matrix drop __cvg_`m'
    }
    local __vmlist ""
    mata: cvg_main("`mvars'", "`touse'", "`esamp'", `lags', "`trend'", "`variance'", ///
        `arch', `garch', "`rmode'", `r', "`bvals'", "`nidx'", "`xmode'", "`xlag'",   ///
        "`method'", "`technique'", `iterate', `starts', "`vce'", `trace', `uncon',  ///
        `nv', "`dn'")

    local Neff  = scalar(__cvg_N)
    local ll    = scalar(__cvg_ll)
    local ll0   = scalar(__cvg_ll0)
    local conv  = scalar(__cvg_conv)
    local convv = scalar(__cvg_convv)
    local iter  = scalar(__cvg_iter)
    local iterv = scalar(__cvg_iterv)
    local K     = scalar(__cvg_k)
    local km    = scalar(__cvg_km)
    local kv    = scalar(__cvg_kv)
    local scale = scalar(__cvg_scale)
    local rint  = scalar(__cvg_rint)
    local nx    = scalar(__cvg_nx)
    local xect  = scalar(__cvg_xect)
    local nsc   = scalar(__cvg_nsc)
    local vmiss = scalar(__cvg_vmiss)
    local vsing = scalar(__cvg_vsing)
    capture scalar drop __cvg_N __cvg_ll __cvg_ll0 __cvg_conv __cvg_convv __cvg_iter __cvg_iterv
    capture scalar drop __cvg_k __cvg_km __cvg_kv __cvg_scale __cvg_rint __cvg_nx __cvg_xect
    capture scalar drop __cvg_nsc __cvg_vmiss __cvg_vsing

    if `conv' == 0 & "`nonconvok'" == "" {
        foreach m in b V Vopg Voim alpha beta Pi bfree Gamma H Hbar H0 persist llst {
            capture matrix drop __cvg_`m'
        }
        foreach m of local __vmlist {
            capture matrix drop __cvg_vm_`m'
        }
        di as err "convergence not achieved (log likelihood = " %12.3f `ll' ")"
        di as err "try technique(bhhh) or technique(bfgs 10 bhhh 10), iterate(), starts(), or"
        di as err "specify nonconvok to report the non-converged estimates (flagged e(converged) = 0)"
        exit 430
    }

    // ---------------- names ---------------------------------------------------
    local d1n ""
    if "`trend'" == "rconstant" local d1n "_cons"
    if "`trend'" == "rtrend"    local d1n "_trend"
    local d2n ""
    if inlist("`trend'", "constant", "rtrend") local d2n "_cons"
    if "`trend'" == "trend" local d2n "_cons _trend"
    local z1n "`dn' `d1n'"
    local eqn ""
    foreach v of local dn {
        local eqn "`eqn' D_`v'"
    }
    local z2n ""
    forvalues j = 1/`=`lags'-1' {
        foreach v of local dn {
            local z2n "`z2n' L`j'D_`v'"
        }
    }
    local z2n "`z2n' `d2n'"
    local cen ""
    forvalues j = 1/`rint' {
        local cen "`cen' _ce`j'"
    }
    if "`rmode'" == "full" {
        local cen ""
        foreach v of local z1n {
            if "`v'" == "_cons" | "`v'" == "_trend" {
                local cen "`cen' L`v'"
            }
            else {
                local cen "`cen' L_`v'"
            }
        }
    }

    tempname b V al be Pi bf Gm H Hb H0 Pe Vo Vp Ls
    matrix `b' = __cvg_b
    local hasV = (`vmiss' == 0 & `nv' == 0)
    if `hasV' {
        matrix `V'  = __cvg_V
        matrix `Vp' = __cvg_Vopg
        if "`vce'" != "opg" {
            matrix `Vo' = __cvg_Voim
        }
    }
    local hasR = (`rint' > 0)
    if `hasR' {
        matrix `al' = __cvg_alpha
        matrix `be' = __cvg_beta
        matrix `Pi' = __cvg_Pi
        matrix `bf' = __cvg_bfree
        matrix rownames `al' = `eqn'
        matrix colnames `al' = `cen'
        matrix rownames `be' = `z1n'
        matrix colnames `be' = `cen'
        if "`rmode'" == "full" {
            local cc ""
            forvalues j = 1/`rint' {
                local cc "`cc' _ce`j'"
            }
            matrix colnames `be' = `cc'
        }
        matrix rownames `Pi' = `eqn'
        matrix colnames `Pi' = `z1n'
        matrix rownames `bf' = `z1n'
        matrix colnames `bf' = free
    }
    local hasG 0
    capture confirm matrix __cvg_Gamma
    if !_rc {
        local hasG 1
        matrix `Gm' = __cvg_Gamma
        matrix rownames `Gm' = `eqn'
        matrix colnames `Gm' = `z2n'
    }
    matrix `H'  = __cvg_H
    matrix `Hb' = __cvg_Hbar
    matrix `H0' = __cvg_H0
    foreach m in H Hb H0 {
        matrix rownames ``m'' = `dn'
        matrix colnames ``m'' = `dn'
    }
    local hasP 0
    capture confirm matrix __cvg_persist
    if !_rc {
        local hasP 1
        matrix `Pe' = __cvg_persist
    }
    local hasL 0
    capture confirm matrix __cvg_llst
    if !_rc {
        local hasL 1
        matrix `Ls' = __cvg_llst
        matrix colnames `Ls' = ll
    }
    local vmn ""
    foreach m of local __vmlist {
        tempname vm_`m'
        matrix `vm_`m'' = __cvg_vm_`m'
        capture matrix drop __cvg_vm_`m'
        local vmn "`vmn' `m'"
    }
    foreach m in b V Vopg Voim alpha beta Pi bfree Gamma H Hbar H0 persist llst {
        capture matrix drop __cvg_`m'
    }

    // ---------------- labels --------------------------------------------------
    local gx ""
    if "`xmode'" != "none" local gx "-X"
    if "`variance'" == "none"      local vlab "homoskedastic (constant Sigma)"
    if "`variance'" == "dbekk"     local vlab "diagonal BEKK(1,1)`gx'"
    if "`variance'" == "bekk"      local vlab "BEKK(`arch',`garch')`gx'"
    if "`variance'" == "cccgarch"  local vlab "CCC-GARCH(`garch',`arch')"
    if "`variance'" == "ecccgarch" local vlab "extended CCC-GARCH(1,1)"
    if "`variance'" == "darch"     local vlab "diagonal ARCH(`arch')"
    if "`variance'" == "trigarch"  local vlab "triangular GARCH(1,1)"
    local plab ""
    if "`variance'" == "dbekk"     local plab "a_i^2 + b_i^2"
    if "`variance'" == "bekk"      local plab "spectral radius of sum A#A + sum G#G"
    if inlist("`variance'", "cccgarch", "darch") local plab "sum of ARCH and GARCH coefficients"
    if "`variance'" == "ecccgarch" local plab "spectral radius of A + B"
    if "`variance'" == "trigarch"  local plab "psi_j + phi_j (orthogonalised errors)"

    local s1 = `tmin' + `lags'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `tmax'
    local np = `p'*(`p'+1)/2
    local aic = -2*`ll' + 2*`K'
    local bic = -2*`ll' + `K'*ln(`Neff')

    local optcore "lags(`lags') trend(`trend') variance(`variance') method(`method') technique(`technique') iterate(`iterate')"
    if inlist("`variance'", "bekk", "cccgarch", "darch") {
        local optcore "`optcore' arch(`arch') garch(`garch')"
    }
    if `uncon' local optcore "`optcore' unconstrained"
    local optmean ""
    if "`rmode'" == "est"   local optmean "rank(`r') normalize(`normalize')"
    if "`rmode'" == "zero"  local optmean "rank(0)"
    if "`rmode'" == "full"  local optmean "fullrank"
    if "`rmode'" == "fixed" local optmean "beta(`bvals') rank(`r')"

    // ---------------- post ------------------------------------------------------
    if `hasV' {
        ereturn post `b' `V', esample(`esamp') obs(`Neff') properties(b V)
    }
    else {
        if `nv' == 0 {
            di as txt "(note: the variance matrix could not be computed; e(V) not posted)"
        }
        ereturn post `b', esample(`esamp') obs(`Neff') properties(b)
    }
    ereturn scalar ll          = `ll'
    ereturn scalar ll_0        = `ll0'
    ereturn scalar k           = `K'
    ereturn scalar k_mean      = `km'
    ereturn scalar k_var       = `kv'
    ereturn scalar k_0         = `km' + `np'
    ereturn scalar aic         = `aic'
    ereturn scalar bic         = `bic'
    ereturn scalar converged   = `conv'
    ereturn scalar converged_v = `convv'
    ereturn scalar ic          = `iter'
    ereturn scalar ic_v        = `iterv'
    ereturn scalar rank        = `rdisp'
    ereturn scalar rank_int    = `rint'
    ereturn scalar lags        = `lags'
    ereturn scalar p           = `p'
    ereturn scalar arch        = `arch'
    ereturn scalar garch       = `garch'
    ereturn scalar nx          = `nx'
    ereturn scalar xect        = `xect'
    ereturn scalar scale       = `scale'
    ereturn scalar starts      = `starts'
    ereturn scalar starts_conv = `nsc'
    ereturn scalar level       = `level'
    ereturn scalar tmin        = `tmin'
    ereturn scalar tmax        = `tmax'
    ereturn scalar tdelta      = `tdelta'
    ereturn scalar vsing       = `vsing'
    ereturn local varlist    "`varlist'"
    ereturn local depvar     "`varlist'"
    ereturn local eqnames    "`eqn'"
    ereturn local trend      "`trend'"
    ereturn local variance   "`variance'"
    ereturn local vlabel     "`vlab'"
    ereturn local perslab    "`plab'"
    ereturn local method     "`method'"
    ereturn local technique  "`technique'"
    ereturn local rmode      "`rmode'"
    ereturn local normalize  "`normalize'"
    ereturn local betaspec   "`bvals'"
    ereturn local garchx     `"`garchx'"'
    ereturn local xmode      "`xmode'"
    ereturn local xvars      "`xvars'"
    ereturn local unconstrained "`unconstrained'"
    ereturn local opt_core   "`optcore'"
    ereturn local opt_mean   "`optmean'"
    ereturn local sfrom      "`sfrom'"
    ereturn local sto        "`sto'"
    ereturn local timevar    "`tvar'"
    ereturn local vmats      "`vmn'"
    if `hasV' {
        ereturn local vce "`vce'"
        if "`vce'" == "robust" ereturn local vcetype "Robust"
        if "`vce'" == "opg"    ereturn local vcetype "OPG"
        if "`vce'" == "oim"    ereturn local vcetype "OIM"
    }
    else {
        ereturn local vce "none"
    }
    ereturn local title      "Cointegrated VAR with `vlab' errors"
    ereturn local predict    "cointvol_vecmgarch_p"
    ereturn local estat_cmd  "cointvol_vecmgarch_estat"
    ereturn local cmdline    `"`cmdline'"'
    if `hasV' {
        ereturn matrix V_opg = `Vp'
        if "`vce'" != "opg" {
            ereturn matrix V_oim = `Vo'
        }
    }
    if `hasR' {
        ereturn matrix alpha = `al'
        ereturn matrix beta  = `be'
        ereturn matrix Pi    = `Pi'
        ereturn matrix bfree = `bf'
    }
    if `hasG' {
        ereturn matrix Gamma = `Gm'
    }
    ereturn matrix H    = `H'
    ereturn matrix Hbar = `Hb'
    ereturn matrix H0   = `H0'
    if `hasP' {
        ereturn matrix persist = `Pe'
    }
    if `hasL' {
        ereturn matrix ll_starts = `Ls'
    }
    foreach m of local vmn {
        ereturn matrix `m' = `vm_`m''
    }
    ereturn local cmd "cointvol vecmgarch"

    _cvg_display, `brief' level(`level')
end

// ---------------------------------------------------------------------------
//  Display (also on replay); everything is read from e()
// ---------------------------------------------------------------------------
program define _cvg_display
    version 14.0
    syntax [, BRief Level(cilevel)]
    local p     = e(p)
    local rint  = e(rank_int)
    local rmode "`e(rmode)'"
    local zc = invnormal(1 - (1 - `level'/100)/2)
    local trend "`e(trend)'"
    if "`trend'" == "none"      local tlab "none"
    if "`trend'" == "rconstant" local tlab "restricted constant"
    if "`trend'" == "constant"  local tlab "unrestricted constant"
    if "`trend'" == "rtrend"    local tlab "restricted trend"
    if "`trend'" == "trend"     local tlab "unrestricted trend"
    if "`e(method)'" == "qmle"    local mlab "joint Gaussian QMLE"
    if "`e(method)'" == "twostep" local mlab "two-step (variance | LS/RRR, then mean | variance)"
    if "`e(method)'" == "ls"      local mlab "LS / Johansen RRR (homoskedastic Gaussian ML)"
    local rlab = e(rank)
    if "`rmode'" == "full"  local rlab "full"
    if "`rmode'" == "fixed" local rlab "`rlab' (fixed)"

    di
    di as txt "`e(title)'" _col(52) "Number of obs  = " as res %9.0f e(N)
    di as txt "Sample: " as res "`e(sfrom)' - `e(sto)'" as txt _col(52) "Variables (p)  = " as res %9.0f `p'
    di as txt "Deterministic: " as res "`tlab'" as txt _col(52) "Lags (levels)  = " as res %9.0f e(lags)
    di as txt "Method: " as res "`mlab'" as txt _col(52) "Coint. rank    = " as res %9s "`rlab'"
    if "`e(xmode)'" == "ect" {
        di as txt "GARCH-X regressor: squared lagged error-correction term(s) z{c 94}2(t-1)"
    }
    if "`e(xmode)'" == "vars" {
        di as txt "GARCH-X regressor(s): squared first lag of " as res "`e(xvars)'"
    }

    tempname b V B BF
    matrix `b' = e(b)
    local hasV 0
    local Vn "none"
    if "`e(vce)'" != "none" {
        matrix `V' = e(V)
        local hasV 1
        local Vn "`V'"
    }
    local vt "Std. Err."
    if "`e(vcetype)'" == "Robust" local vt "Robust SE"
    di as txt "{hline 13}{c TT}{hline 64}"
    di as txt _col(14) "{c |}" _col(21) "Coef." _col(29) "`vt'" _col(44) "z" _col(49) "P>|z|" ///
        _col(59) "[`level'% Conf. Interval]"

    // long run
    if `rint' > 0 & "`rmode'" != "full" {
        matrix `B'  = e(beta)
        matrix `BF' = e(bfree)
        local rn : rownames `B'
        di as txt "{hline 13}{c +}{hline 64}"
        di as txt _col(14) "{c |} " as res "Long run (beta)"
        forvalues j = 1/`rint' {
            di as res %-12s "_ce`j'" as txt " {c |}"
            local i 0
            foreach nm of local rn {
                local i = `i' + 1
                if `BF'[`i', 1] == 1 {
                    local col = colnumb(`b', "_ce`j':`nm'")
                    _cvg_row "`nm'" `b' `Vn' `col' `zc' `hasV'
                }
                else {
                    local lab "(fixed)"
                    if "`rmode'" == "est" local lab "(normalised)"
                    local nma = abbrev("`nm'", 12)
                    di as txt %12s "`nma'" " {c |}" as res _col(17) %9.0g `B'[`i', `j'] as txt _col(30) "`lab'"
                }
            }
        }
    }
    _cvg_part adj "Adjustment (alpha)" `b' `Vn' `zc' `hasV'
    if "`brief'" == "" {
        _cvg_part sr "Short run (Gamma, deterministic terms)" `b' `Vn' `zc' `hasV'
    }
    local vtit "Volatility (`e(vlabel)')"
    _cvg_part vol "`vtit'" `b' `Vn' `zc' `hasV'
    di as txt "{hline 13}{c BT}{hline 64}"

    di as txt "Log likelihood = " as res %12.3f e(ll) as txt "    AIC = " as res %12.3f e(aic) ///
        as txt "    BIC = " as res %12.3f e(bic)
    if "`e(variance)'" != "none" {
        di as txt "Homoskedastic Gaussian log likelihood (LS/RRR mean, constant Sigma) = " as res %12.3f e(ll_0)
    }
    capture confirm matrix e(persist)
    if !_rc {
        tempname P
        matrix `P' = e(persist)
        local prn : rownames `P'
        local txt ""
        local i 0
        foreach nm of local prn {
            local i = `i' + 1
            local vv : display %6.4f `P'[`i', 1]
            local txt "`txt' `nm' = `vv'"
        }
        di as txt "Persistence (`e(perslab)'):" as res "`txt'"
    }
    local cvl "yes"
    if e(converged) == 0 local cvl "NO"
    if "`e(method)'" != "ls" {
        di as txt "Converged: " as res "`cvl'" as txt " (iterations = " as res e(ic) as txt ///
            ", technique = " as res "`e(technique)'" as txt ")"
        if e(starts) > 0 {
            di as txt "Random restarts: " as res e(starts) as txt " (" as res e(starts_conv) as txt " converged)"
        }
    }
    if e(converged) == 0 {
        di as err "Warning: the optimiser did not converge; the estimates are not reliable."
    }
    if e(vsing) > 0 & e(vsing) < . {
        di as txt "Note: the (pseudo-)information matrix is singular (" as res e(vsing) as txt ///
            " dropped direction(s)); some parameters may lie on a boundary."
    }
    local v "`e(variance)'"
    if "`v'" == "dbekk" {
        di as txt "Model: H_t = C'C + A'e e'A + B'H B" _c
        if "`e(xmode)'" != "none" di as txt " + D'D x{c 94}2(t-1)" _c
        di as txt "; A, B diagonal (Lee 1994, JIMF 13, eq. 2)."
        if "`e(xmode)'" != "none" {
            di as txt "  The score is zero at D = 0: Wald / LR tests of D = 0 are non-standard."
        }
    }
    if "`v'" == "bekk" {
        di as txt "Model: H_t = C'C + sum A_i'e e'A_i + sum G_j'H G_j (Bauwens, Deprins & Vandeuren 1997,"
        di as txt "  CORE DP 9780, eqs 5-7; Engle & Kroner 1995); a11 > 0, g11 > 0 normalisation."
    }
    if "`v'" == "cccgarch" {
        di as txt "Model: h_it = w_i + sum a_il e{c 94}2 + sum b_il h, V_t = D_t Gamma D_t (Sin, Mi & Ling 2024,"
        di as txt "  CMR 40, eq. 2.3; Bollerslev 1990)."
    }
    if "`v'" == "ecccgarch" {
        di as txt "Model: h_t = w + A e{c 94}2(t-1) + B h(t-1), A full, B diagonal, Gamma = I (Wong, Li &"
        di as txt "  Ling 2005, AISM 57, eq. 2.2)."
    }
    if "`v'" == "darch" {
        di as txt "Model: h_kt = g_k + sum_i s_ki e{c 94}2(k,t-i), no conditional correlation (Li, Ling & Wong"
        di as txt "  2001, Biometrika 88, eq. 4.1)."
    }
    if "`v'" == "trigarch" {
        di as txt "Model: e_t = L u_t, s2_jt = w_j + psi_j e{c 94}2 + phi_j s2, Omega_t = L{c 94}-1 S_t L{c 94}-1'"
        di as txt "  (Seo 2007, JoE 137, eqs 3-4); correlations vary over time unless L = I."
    }
    if "`e(vcetype)'" == "Robust" {
        di as txt "Robust SE: QML sandwich (Bollerslev & Wooldridge 1992); only the sandwich Wald is chi2"
        di as txt "  under non-normal errors (Seo 2007, Thm 2). beta is super-consistent (mixed normal)."
    }
end

program define _cvg_row
    version 14.0
    args nm b V j zc hasV
    local coef = `b'[1, `j']
    local nma = abbrev("`nm'", 12)
    local se = .
    if `hasV' {
        local se = sqrt(`V'[`j', `j'])
    }
    if `se' < . & `se' > 0 {
        local z  = `coef'/`se'
        local pv = 2*normal(-abs(`z'))
        di as txt %12s "`nma'" " {c |}" as res _col(17) %9.0g `coef' _col(28) %9.0g `se' ///
            _col(38) %8.2f `z' _col(48) %6.3f `pv' _col(58) %9.0g (`coef' - `zc'*`se') ///
            _col(70) %9.0g (`coef' + `zc'*`se')
    }
    else {
        di as txt %12s "`nma'" " {c |}" as res _col(17) %9.0g `coef' as txt _col(30) "(SE not available)"
    }
end

program define _cvg_part
    version 14.0
    args mode title b V zc hasV
    local cn : colfullnames `b'
    local j 0
    local cureq ""
    local first 1
    foreach c of local cn {
        local j = `j' + 1
        gettoken eq nm : c, parse(":")
        local nm = substr(`"`nm'"', 2, .)
        local isd  = (substr("`eq'", 1, 2) == "D_")
        local isce = (substr("`eq'", 1, 3) == "_ce")
        local isadj = (substr("`nm'", 1, 3) == "_ce" | substr("`nm'", 1, 2) == "L_")
        local show 0
        if "`mode'" == "adj" & `isd' & `isadj'   local show 1
        if "`mode'" == "sr"  & `isd' & !`isadj'  local show 1
        if "`mode'" == "vol" & !`isd' & !`isce'  local show 1
        if `show' {
            if `first' {
                di as txt "{hline 13}{c +}{hline 64}"
                di as txt _col(14) "{c |} " as res "`title'"
                local first 0
            }
            if "`eq'" != "`cureq'" {
                local eqa = abbrev("`eq'", 12)
                di as res %-12s "`eqa'" as txt " {c |}"
                local cureq "`eq'"
            }
            _cvg_row "`nm'" `b' `V' `j' `zc' `hasV'
        }
    }
end
