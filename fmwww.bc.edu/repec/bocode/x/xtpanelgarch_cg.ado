*! xtpanelgarch_cg 1.0.0  06nov2026
*! Cermeno & Grier (2001, 2006) panel GARCH / DPD-CCV by (quasi-)maximum likelihood
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (full map in help xtpanelgarch_methods)
*   mean        CG(2001) eq.(2),(10); CG(2006) eq.(10.1); in-mean term CG(2006) eq.(10.9a)
*   variance    CG(2001) eq.(4),(9),(11); CG(2006) eq.(10.3),(10.10a); GJR (1993) term
*   covariance  CG(2006) eq.(10.4) [common eta: Model 2, pair eta_ij: Model 3];
*               CCC: Cermeno-Sanin (2015) eq.(3), Bollerslev (1990)
*   likelihood  independent units CG(2001) eq.(7) = CG(2006) eq.(10.8);
*               correlated units  CG(2006) eq.(10.7)
*   inference   oim: CG(2006) p.264 ; opg: CG(2001) fn.4 ; robust: Bollerslev-Wooldridge (1992)

program define xtpanelgarch_cg, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "cg") error 301
        _xtpg_cg_display `0'
        exit
    }
    syntax varlist(ts min=1) [if] [in] , [ ARCH(integer 1) GARCH(integer 0) ///
        MODel(string) MEANfe VARfe HET(varlist ts) ARCHM ARCHMType(string)     ///
        TARCH EGARCH COV(string) DISTribution(string) VCE(string) TECHnique(string)   ///
        ITERate(integer 300) FROM(string) STARTs(integer -1) noLOG Level(cilevel) noTABle ]

    // ---------------- options --------------------------------------------
    if `arch' < 0 | `garch' < 0 {
        di as err "arch() and garch() must be nonnegative"
        exit 198
    }
    if `arch' == 0 & `garch' > 0 {
        di as err "garch() requires arch() >= 1"
        exit 198
    }
    if `arch' == 0 & "`tarch'" != "" {
        di as err "tarch requires arch() >= 1"
        exit 198
    }
    local mfe = ("`meanfe'" != "")
    local vfe = ("`varfe'" != "")
    if "`model'" != "" {
        local model = upper("`model'")
        if !inlist("`model'", "A", "B", "C", "D") {
            di as err "model() must be A, B, C or D"
            exit 198
        }
        local mfe = inlist("`model'", "B", "D")
        local vfe = inlist("`model'", "C", "D")
    }
    if "`model'" == "" {
        if `mfe' == 0 & `vfe' == 0 local model "A"
        if `mfe' == 1 & `vfe' == 0 local model "B"
        if `mfe' == 0 & `vfe' == 1 local model "C"
        if `mfe' == 1 & `vfe' == 1 local model "D"
    }
    local am 0
    if "`archm'" != "" | "`archmtype'" != "" {
        if "`archmtype'" == "" local archmtype "sd"
        if "`archmtype'" == "sd" local am 1
        else if inlist("`archmtype'", "var", "variance") local am 2
        else if inlist("`archmtype'", "logvar", "lnvar") local am 3
        else {
            di as err "archmtype() must be sd, var or logvar"
            exit 198
        }
    }
    local ta = ("`tarch'" != "")
    local eg = ("`egarch'" != "")
    if `eg' & `ta' {
        di as err "tarch and egarch cannot be combined (EGARCH already has an asymmetry term)"
        exit 198
    }
    if `eg' & `arch' == 0 {
        di as err "egarch requires arch() >= 1"
        exit 198
    }
    if "`cov'" == "" local cov "none"
    local cov = lower("`cov'")
    if "`cov'" == "none" local cv 0
    else if "`cov'" == "common" local cv 1
    else if "`cov'" == "pair" local cv 2
    else if "`cov'" == "ccc" local cv 3
    else {
        di as err "cov() must be none, common, pair or ccc"
        exit 198
    }
    if "`distribution'" == "" local distribution "normal"
    local distribution = lower("`distribution'")
    if inlist("`distribution'", "normal", "gaussian") local dst 1
    else if inlist("`distribution'", "t", "student") local dst 2
    else {
        di as err "distribution() must be normal or t"
        exit 198
    }
    if "`vce'" == "" local vce "oim"
    local vce = lower("`vce'")
    if !inlist("`vce'", "oim", "opg", "robust") {
        di as err "vce() must be oim, opg or robust"
        exit 198
    }
    if "`technique'" == "" {
        local technique "nr"
        if `cv' > 0 local technique "bfgs"
    }
    local showlog = ("`log'" == "")
    if `starts' < 0 {
        local starts 10
        if "`cov'" != "" & "`cov'" != "none" local starts 3
    }
    local dosearch = `starts'
    if "`from'" != "" local dosearch 0
    if `starts' < 1 local dosearch 0

    // ---------------- panel structure ------------------------------------
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    if "`het'" != "" markout `touse' `het'

    gettoken yorig xorig : varlist
    tsrevar `varlist'
    local tsv "`r(varlist)'"
    gettoken y xv : tsv
    local zv ""
    local zorig ""
    if "`het'" != "" {
        tsunab zorig : `het'
        tsrevar `het'
        local zv "`r(varlist)'"
    }
    if "`xorig'" != "" tsunab xorig : `xorig'

    // balanced, gap-free, common time span (Omega_t is N x N)
    tempvar cnt tmin tmax
    qui bysort `ivar' (`tvar'): egen long `cnt' = total(`touse')
    qui by `ivar': egen double `tmin' = min(cond(`touse', `tvar', .))
    qui by `ivar': egen double `tmax' = max(cond(`touse', `tvar', .))
    qui replace `touse' = 0 if `cnt' == 0
    qui count if `touse'
    if r(N) == 0 error 2000
    qui sum `cnt' if `touse', meanonly
    if r(min) != r(max) {
        di as err "panel is unbalanced on the estimation sample (T_i from " r(min) " to " r(max) ")"
        di as err "{bf:xtpanelgarch cg} needs a balanced panel without gaps; restrict with if/in"
        exit 459
    }
    local T = r(min)
    qui sum `tmin' if `touse', meanonly
    local t0 = r(min)
    if r(min) != r(max) {
        di as err "panels do not share the same time span on the estimation sample"
        exit 459
    }
    qui sum `tmax' if `touse', meanonly
    if r(min) != r(max) | (r(min) - `t0') / `tdelta' + 1 != `T' {
        di as err "panels have gaps or different end dates on the estimation sample"
        exit 459
    }
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    if `N' < 1 error 2000
    if `cv' > 0 & `N' < 2 {
        di as err "cov() requires at least 2 panels"
        exit 198
    }
    if `cv' == 2 & `N' > 10 {
        di as txt "(note: cov(pair) with N = `N' estimates " `N'*(`N'-1)/2 " pair-specific intercepts)"
    }
    local mxlag = max(`arch', `garch')
    if `T' < 10 + `mxlag' {
        di as err "too few time periods (T = `T')"
        exit 2001
    }
    sort `ivar' `tvar'

    // ---------------- starting values ------------------------------------
    tempvar res
    tempname b0 Cm
    if `mfe' {
        qui regress `y' `xv' ibn.`ivar' if `touse', noconstant
    }
    else {
        qui regress `y' `xv' if `touse'
    }
    qui predict double `res' if `touse', residuals
    local k : word count `xv'
    // mean block
    if `mfe' {
        foreach u of local units {
            matrix `b0' = (nullmat(`b0'), _b[`u'.`ivar'])
        }
    }
    else {
        matrix `b0' = (_b[_cons])
    }
    foreach v of local xv {
        matrix `b0' = (`b0', _b[`v'])
    }
    if `am' > 0 matrix `b0' = (`b0', 0)
    // variance block
    local gsum 0
    if `arch' > 0 {
        if `garch' > 0 local gsum = 0.10
        else local gsum = 0.30
    }
    local dsum 0
    if `garch' > 0 local dsum = 0.80
    local pers = `gsum' + `dsum'
    if `eg' local gsum = 0.10
    if `vfe' {
        foreach u of local units {
            qui sum `res' if `touse' & `ivar' == `u'
            if `eg' matrix `b0' = (`b0', ln(r(Var) * (r(N) - 1) / r(N)) * (1 - `dsum'))
            else matrix `b0' = (`b0', r(Var) * (r(N) - 1) / r(N) * (1 - `pers'))
        }
    }
    else {
        qui sum `res' if `touse'
        if `eg' matrix `b0' = (`b0', ln(r(Var) * (r(N) - 1) / r(N)) * (1 - `dsum'))
        else matrix `b0' = (`b0', r(Var) * (r(N) - 1) / r(N) * (1 - `pers'))
    }
    forvalues l = 1/`arch' {
        matrix `b0' = (`b0', `gsum' / `arch')
    }
    forvalues l = 1/`garch' {
        matrix `b0' = (`b0', `dsum' / `garch')
    }
    if `ta' matrix `b0' = (`b0', 0)
    if `eg' {
        forvalues l = 1/`arch' {
            matrix `b0' = (`b0', 0)
        }
    }
    local m : word count `zv'
    forvalues l = 1/`m' {
        matrix `b0' = (`b0', 0)
    }
    // covariance block
    if `cv' > 0 {
        local rho0 0.05
        local lam0 0.80
        if `cv' == 3 {
            local rho0 0
            local lam0 0
        }
        local etasum 0
        local npair = `N' * (`N' - 1) / 2
        mata: _xtpg_rescov("`res'", "`touse'", `N', `T', "`Cm'", (`cv' == 3))
        forvalues i = 1/`=`N'-1' {
            forvalues j = `=`i'+1'/`N' {
                local cij = `Cm'[`i', `j']
                if `cv' == 2 matrix `b0' = (`b0', `cij' * (1 - `rho0' - `lam0'))
                if `cv' == 3 matrix `b0' = (`b0', `cij')
                local etasum = `etasum' + `cij'
            }
        }
        if `cv' == 1 matrix `b0' = (`b0', `etasum' / `npair' * (1 - `rho0' - `lam0'), `rho0', `lam0')
        if `cv' == 2 matrix `b0' = (`b0', `rho0', `lam0')
    }
    if `dst' == 2 matrix `b0' = (`b0', 10)
    if "`from'" != "" {
        tempname bf
        matrix `bf' = `from'
        if colsof(`bf') != colsof(`b0') {
            di as err "from() must have " colsof(`b0') " columns"
            exit 503
        }
        matrix `b0' = `bf'
    }

    // ---------------- estimation -----------------------------------------
    di as txt _n "Cermeño-Grier panel GARCH: maximum likelihood (`technique')"
    local tacode = cond(`eg', -`arch', `ta')
    mata: _xtpg_cg_fit("`y'", "`xv'", "`zv'", "`touse'", `N', `T', `arch', `garch', ///
        `mfe', `vfe', `am', `tacode', `cv', `dst', "`b0'", "`technique'", `iterate', "`vce'", `showlog', `dosearch')
    if scalar(__xtpg_rc) != 0 {
        di as err "estimation failed"
        exit 430
    }

    // ---------------- names ----------------------------------------------
    local names ""
    if `mfe' {
        foreach u of local units {
            local names "`names' mean:mu`u'"
        }
    }
    else local names "mean:_cons"
    foreach v of local xorig {
        local names "`names' mean:`v'"
    }
    if `am' == 1 local names "`names' ARCHM:sigma"
    if `am' == 2 local names "`names' ARCHM:sigma2"
    if `am' == 3 local names "`names' ARCHM:lnsigma2"
    if `vfe' {
        foreach u of local units {
            local names "`names' variance:alpha`u'"
        }
    }
    else local names "`names' variance:_cons"
    if `eg' {
        forvalues l = 1/`arch' {
            local names "`names' variance:L`l'.earch_a"
        }
        forvalues l = 1/`garch' {
            local names "`names' variance:L`l'.egarch"
        }
        forvalues l = 1/`arch' {
            local names "`names' variance:L`l'.earch"
        }
    }
    else {
        forvalues l = 1/`arch' {
            local names "`names' variance:L`l'.arch"
        }
        forvalues l = 1/`garch' {
            local names "`names' variance:L`l'.garch"
        }
    }
    if `ta' local names "`names' variance:L1.tarch"
    foreach v of local zorig {
        local names "`names' variance:`v'"
    }
    if `cv' == 1 local names "`names' covariance:_cons covariance:L1.uu covariance:L1.cov"
    if `cv' == 2 | `cv' == 3 {
        forvalues i = 1/`=`N'-1' {
            local ui : word `i' of `units'
            forvalues j = `=`i'+1'/`N' {
                local uj : word `j' of `units'
                if `cv' == 2 local names "`names' covariance:eta`ui'_`uj'"
                if `cv' == 3 local names "`names' correlation:r`ui'_`uj'"
            }
        }
        if `cv' == 2 local names "`names' covariance:L1.uu covariance:L1.cov"
    }
    if `dst' == 2 local names "`names' t:df"

    tempname b V
    matrix `b' = __xtpg_b
    matrix `V' = __xtpg_V
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local np = colsof(`b')
    local NT = `N' * `T'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar ll = scalar(__xtpg_ll)
    ereturn scalar k = `np'
    ereturn scalar rank = `np'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar arch = `arch'
    ereturn scalar garch = `garch'
    ereturn scalar converged = scalar(__xtpg_conv)
    ereturn scalar iterations = scalar(__xtpg_iter)
    ereturn scalar aic = -2 * e(ll) + 2 * `np'
    ereturn scalar bic = -2 * e(ll) + ln(`nobs') * `np'
    if `cv' > 0 ereturn scalar minpd = scalar(__xtpg_minpd)
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "cg"
    ereturn local title "Cermeño-Grier panel GARCH"
    ereturn local model "`model'"
    ereturn local meanfe = cond(`mfe', "fe", "pooled")
    ereturn local varfe = cond(`vfe', "fe", "common")
    ereturn local cov "`cov'"
    ereturn local archm = cond(`am' == 0, "", "`archmtype'")
    ereturn local tarch = cond(`ta', "tarch", "")
    ereturn local egarch = cond(`eg', "egarch", "")
    ereturn local dist "`distribution'"
    ereturn local depvar "`yorig'"
    ereturn local xvars "`xorig'"
    ereturn local het "`zorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local vce "`vce'"
    ereturn local vcetype = cond("`vce'" == "robust", "Robust", cond("`vce'" == "opg", "OPG", "OIM"))
    ereturn local technique "`technique'"
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix sigma2 = __xtpg_S2
    ereturn matrix resid = __xtpg_U
    ereturn matrix ll_t = __xtpg_ll_t
    if `cv' > 0 {
        ereturn matrix covt = __xtpg_CV
        ereturn matrix pairs = __xtpg_pairs
    }
    capture scalar drop __xtpg_rc __xtpg_ll __xtpg_conv __xtpg_iter __xtpg_minpd
    capture matrix drop __xtpg_b __xtpg_V

    _xtpg_cg_display, level(`level') `table'
end

// --------------------------------------------------------------------------
program define _xtpg_cg_display
    syntax [, Level(cilevel) noTABle]
    local N = e(N_g)
    di _n as txt "`e(title)'" _col(49) "Number of obs" _col(67) "=" as res %10.0fc e(N)
    di as txt "Model `e(model)': mean `e(meanfe)', variance `e(varfe)'" _col(49) "Number of panels" _col(67) "=" as res %10.0f e(N_g)
    local spec "GARCH(`e(garch)',`e(arch)')"
    if e(garch) == 0 local spec "ARCH(`e(arch)')"
    if e(arch) == 0 local spec "homoskedastic"
    if "`e(tarch)'" != "" local spec "GJR-`spec'"
    if "`e(egarch)'" != "" local spec "E`spec' (Nelson 1991, log variance)"
    if "`e(archm)'" != "" local spec "`spec'-M (`e(archm)')"
    di as txt "Variance: `spec'" _col(49) "Time periods" _col(67) "=" as res %10.0f e(T)
    di as txt "Covariance: `e(cov)'" _col(49) "Distribution" _col(67) "=" as res %10s "`e(dist)'"
    di as txt "Log likelihood = " as res %12.4f e(ll) _col(49) as txt "AIC / BIC" _col(67) "=" as res %10.2f e(aic)
    di as txt _col(49) _col(67) " " as res %10.2f e(bic)
    if "`table'" == "" {
        ereturn display, level(`level')
    }
    _xtpg_cg_dynamics
end

// persistence, unconditional variance and half-life (delta method)
program define _xtpg_cg_dynamics
    tempname b V a
    matrix `b' = e(b)
    matrix `V' = e(V)
    local np = colsof(`b')
    local cn : colfullnames `b'
    matrix `a' = J(1, `np', 0)
    local hasdyn 0
    local j 0
    foreach c of local cn {
        local ++j
        if substr("`c'", 1, 10) == "variance:L" & (strpos("`c'", ".arch") | strpos("`c'", ".garch")) {
            matrix `a'[1, `j'] = 1
            local hasdyn 1
        }
        if strpos("`c'", "variance:L") & strpos("`c'", ".tarch") matrix `a'[1, `j'] = 0.5
        if strpos("`c'", "variance:L") & strpos("`c'", ".egarch") {
            matrix `a'[1, `j'] = 1
            local hasdyn 1
        }
    }
    if `hasdyn' == 0 exit
    mata: _xtpg_lincom("`b'", "`V'", "`a'")
    local P = scalar(__xtpg_lc)
    local Pse = scalar(__xtpg_lcse)
    di _n as txt "{hline 78}"
    di as txt "Volatility dynamics" _col(40) "Estimate" _col(54) "Std. err." _col(68) "z"
    di as txt "{hline 78}"
    di as txt "  variance persistence (Σγ+Σδ)" _col(37) as res %11.4f `P' _col(51) %11.4f `Pse' _col(63) %9.2f (`P' - 1) / `Pse' as txt " (H0:=1)"
    if `P' > 0 & `P' < 1 {
        di as txt "  half-life of a variance shock" _col(37) as res %11.2f ln(0.5) / ln(`P') as txt "  periods"
    }
    if "`e(cov)'" == "common" | "`e(cov)'" == "pair" {
        matrix `a' = J(1, `np', 0)
        local j 0
        foreach c of local cn {
            local ++j
            if strpos("`c'", "covariance:L") & (strpos("`c'", ".uu") | strpos("`c'", ".cov")) matrix `a'[1, `j'] = 1
        }
        mata: _xtpg_lincom("`b'", "`V'", "`a'")
        di as txt "  covariance persistence (ρ+λ)" _col(37) as res %11.4f scalar(__xtpg_lc) _col(51) %11.4f scalar(__xtpg_lcse) _col(63) %9.2f (scalar(__xtpg_lc) - 1) / scalar(__xtpg_lcse) as txt " (H0:=1)"
    }
    if "`e(cov)'" != "none" {
        local pdmsg "positive definite at every t"
        if e(minpd) <= 0 local pdmsg "NOT positive definite at some t"
        di as txt "  min eigenvalue of Ω_t over t" _col(37) as res %11.4g e(minpd) as txt "  (`pdmsg')"
    }
    di as txt "{hline 78}"
    if `P' >= 1 di as txt "Note: persistence >= 1, the variance process is not covariance stationary."
    capture scalar drop __xtpg_lc __xtpg_lcse
end
