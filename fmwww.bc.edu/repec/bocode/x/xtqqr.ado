*! xtqqr 1.0.0  25nov2026
*! Panel Quantile-on-Quantile Regression
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* Implements, for panel data, the quantile-on-quantile (QQ) approach of
*   Sim, N. & Zhou, H. (2015), J. Banking & Finance 55, 1-12.
* with the panel variants used in
*   Atsalakis, Bouri & Pasiouras (2021), Ann. Oper. Res.  (unit quantiles)
*   Hassan, Iqbal & Arshed (2021), Environ. Sci. Pollut. Res. (PQR + QQR)
*   Wu, Chang, Wang, Wu, Lin & Huang (2021), Front. Public Health (pooled QQ)
*   Clance, Gozgor, Gupta & Lau (2023)  (quantile-group panel QQ)
* Fixed effects: Canay (2011) two-step or unit dummies (Koenker 2004, l=0).
*
* Step -> equation map (Sim & Zhou 2015 numbering)
*   [S1] y_it = beta^tau(x_it) + z_it'g + a_i + v_it        eq.(3), panel form
*   [S2] beta^tau(x) ~ b0(tau,theta) + b1(tau,theta)(x - x^theta)   eq.(4)-(5)
*   [S3] F_n(x_it) = (1/n) sum 1(x_k < x_it)                 eq.(7)
*   [S4] min sum rho_tau(y~ - b0 - b1(x - x^theta) - z'g) K((F_n - theta)/h)
*                                                             eq. after (6)
*   [S5] a_i removed by Canay (2011): y~ = y - a_i(within)  (fe(canay))
*   [S6] validation: mean_theta b1(tau,theta) vs panel QR slope b(tau)
*        (Sim-Zhou sec. 4.3; Wu et al. 2021 eq. gamma1(theta))

program define xtqqr, eclass
    version 14.0
    if replay() {
        if "`e(cmd)'" != "xtqqr" {
            error 301
        }
        _xtqqr_show `0'
        exit
    }

    syntax varlist(min=2 numeric ts) [if] [in] [,        ///
        TAU(numlist >0 <1 sort)                           ///
        THETA(numlist >0 <1 sort)                         ///
        BW(real 0.05)                                     ///
        KERnel(string)                                    ///
        FE(string)                                        ///
        TIMEfe                                            ///
        XREF(string)                                      ///
        METhod(string)                                    ///
        GROUPs(integer 4)                                 ///
        VCE(string)                                       ///
        REPS(integer 100)                                 ///
        SEED(string)                                      ///
        Level(cilevel)                                    ///
        VALidate                                          ///
        NOTABle                                           ///
        GRaph                                             ///
        SAVing(string)                                    ///
        BLOCK(integer 8)                                  ///
        NODOTS ]

    _xtqqr_load

    * ---------------------------------------------------------------- panel
    capture xtset
    if _rc {
        di as err "data must be {bf:xtset} (panel variable and time variable)"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" {
        di as err "no panel variable set; use {bf:xtset panelvar timevar}"
        exit 459
    }

    * ---------------------------------------------------------- defaults
    if "`tau'"   == "" local tau   "0.05(0.05)0.95"
    if "`theta'" == "" local theta "0.05(0.05)0.95"
    numlist "`tau'"
    local tau `r(numlist)'
    numlist "`theta'"
    local theta `r(numlist)'

    if "`kernel'" == "" local kernel "gaussian"
    local kernel = lower("`kernel'")
    if inlist("`kernel'", "gaussian", "gauss", "normal")      local ktype 1
    else if inlist("`kernel'", "epanechnikov", "epan")        local ktype 2
    else if inlist("`kernel'", "uniform", "rectangle")        local ktype 3
    else {
        di as err "kernel() must be gaussian, epanechnikov or uniform"
        exit 198
    }
    if "`ktype'" == "1" local kernel "gaussian"
    if "`ktype'" == "2" local kernel "epanechnikov"
    if "`ktype'" == "3" local kernel "uniform"

    if "`fe'" == "" local fe "canay"
    local fe = lower("`fe'")
    if !inlist("`fe'", "canay", "none", "dummy", "pooled") {
        di as err "fe() must be canay, dummy or none"
        exit 198
    }
    if "`fe'" == "pooled" local fe "none"

    if "`xref'" == "" local xref "pooled"
    local xref = lower("`xref'")
    if !inlist("`xref'", "pooled", "unit") {
        di as err "xref() must be pooled or unit"
        exit 198
    }

    if "`method'" == "" local method "kernel"
    local method = lower("`method'")
    if "`method'" == "group" local method "groups"
    if !inlist("`method'", "kernel", "groups") {
        di as err "method() must be kernel or groups"
        exit 198
    }
    if "`method'" == "groups" & "`validate'" != "" {
        di as err "option validate compares QQ slopes with the panel QR slope;" ///
            " it is not defined for method(groups)"
        exit 198
    }
    if "`method'" == "groups" & (`groups' < 2 | `groups' > 20) {
        di as err "groups() must be between 2 and 20"
        exit 198
    }

    if "`vce'" == "" local vce "cluster"
    local vce = lower(word("`vce'", 1))
    if inlist("`vce'", "cl", "clu", "clus", "clust", "cluster")  local vce "cluster"
    if inlist("`vce'", "r", "rob", "robust")                    local vce "robust"
    if inlist("`vce'", "boot", "bs", "bootstrap")               local vce "bootstrap"
    if !inlist("`vce'", "cluster", "robust", "iid", "bootstrap") {
        di as err "vce() must be cluster, robust, iid or bootstrap"
        exit 198
    }
    if `bw' <= 0 | `bw' >= 1 {
        di as err "bw() must lie in (0,1); Sim & Zhou (2015) use 0.05"
        exit 198
    }
    if `reps' < 2 {
        di as err "reps() must be at least 2"
        exit 198
    }

    * -------------------------------------------------------- variables
    gettoken y rest : varlist
    gettoken x ctrl : rest
    local ctrl = strtrim("`ctrl'")

    marksample touse
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    local N = r(N)
    if `N' < 30 {
        di as err "insufficient observations (`N'); at least 30 required"
        exit 2001
    }
    tempvar gid
    qui egen long `gid' = group(`ivar') if `touse'
    qui su `gid', meanonly
    local Ng = r(max)
    if `Ng' < 2 {
        di as err "at least 2 panel units are required"
        exit 2001
    }

    local M : word count `tau'
    local L : word count `theta'
    if "`method'" == "groups" local L = `groups' - 1

    * ----------------------------------------------------------- header
    di as txt _n "{hline 78}"
    if "`method'" == "kernel" {
        di as txt "{bf:Panel Quantile-on-Quantile Regression}" ///
            _col(50) "Sim & Zhou (2015), panel form"
    }
    else {
        di as txt "{bf:Panel Quantile-on-Quantile Regression: quantile groups}" ///
            _col(62) "Clance et al."
    }
    di as txt "{hline 78}"
    di as txt "Dependent variable  : " as res "`y'" ///
        as txt _col(45) "Number of obs      = " as res %9.0f `N'
    di as txt "QQ regressor        : " as res "`x'" ///
        as txt _col(45) "Number of groups   = " as res %9.0f `Ng'
    local ctrlshow "`ctrl'"
    if "`ctrlshow'" == "" local ctrlshow "(none)"
    if strlen("`ctrlshow'") > 22 local ctrlshow = substr("`ctrlshow'", 1, 19) + "..."
    di as txt "Controls            : " as res "`ctrlshow'" ///
        as txt _col(45) "Panel variable     = " as res %9s abbrev("`ivar'", 9)
    local feshow "Canay (2011) two-step"
    if "`fe'" == "dummy" local feshow "unit dummies"
    if "`fe'" == "none"  local feshow "none (pooled)"
    if "`timefe'" != "" local feshow "`feshow' + time"
    di as txt "Fixed effects       : " as res "`feshow'"
    if "`method'" == "kernel" {
        di as txt "Kernel / bandwidth  : " as res "`kernel'" as txt ", h = " ///
            as res %5.3f `bw' as txt _col(45) "x-quantile ref.    = " ///
            as res %9s "`xref'"
    }
    else {
        di as txt "Quantile groups of x: " as res "`groups'" as txt ///
            " (base = 1)" _col(45) "x-quantile ref.    = " ///
            as res %9s "`xref'"
    }
    local vceshow "`vce'"
    if "`vce'" == "cluster"   local vceshow "cluster(`ivar'), Powell sandwich"
    if "`vce'" == "robust"    local vceshow "robust Powell sandwich"
    if "`vce'" == "iid"       local vceshow "iid"
    if "`vce'" == "bootstrap" local vceshow "panel block bootstrap, `reps' reps"
    di as txt "Std. errors         : " as res "`vceshow'"
    di as txt "Grid                : " as res "`M'" as txt " tau x " ///
        as res "`L'" as txt " " cond("`method'" == "kernel", "theta", "groups") ///
        as txt " = " as res `M' * `L' as txt " quantile regressions"
    di as txt "{hline 78}"

    * --------------------------------------------------------- estimate
    local vt = 3
    if "`vce'" == "robust" local vt = 2
    if "`vce'" == "iid"    local vt = 1
    local nose ""
    if "`vce'" == "bootstrap" local nose "nose"

    tempname B SE R2 QR NOBS
    _xtqqr_core `y' `x' `ctrl', touse(`touse') ivar(`gid') tvar(`tvar') ///
        tau(`tau') theta(`theta') bw(`bw') ktype(`ktype') fe(`fe')        ///
        `timefe' xref(`xref') method(`method') groups(`groups') vt(`vt')  ///
        `validate' `nose' `nodots'
    matrix `B'  = r(B)
    matrix `R2' = r(R2)
    matrix `NOBS' = r(nobs)
    local kpar = r(k)
    if "`method'" == "kernel" {
        local essmin = .
        forvalues j = 1/`L' {
            local essmin = min(`essmin', `NOBS'[1, `j'])
        }
        if `essmin' < 10 * `kpar' {
            di as txt "{p 0 6 2}{bf:Warning}: the smallest effective (kernel-weighted)" ///
                " sample is " %6.1f `essmin' " observations for " `kpar'     ///
                " parameters per local fit. Estimates can be unstable;"       ///
                " widen bw(), use a smaller grid, or drop fixed-effect"       ///
                " dummies (fe(canay) instead of fe(dummy)).{p_end}"
        }
    }
    if "`vce'" != "bootstrap" {
        matrix `SE' = r(SE)
    }
    if "`validate'" != "" {
        matrix `QR' = r(QR)
    }

    * -------------------------------------------- panel block bootstrap
    if "`vce'" == "bootstrap" {
        if "`seed'" != "" {
            set seed `seed'
        }
        tempname BB QB SUM SUM2 QSUM QSUM2 NB
        matrix `SUM'  = J(`M', `L', 0)
        matrix `SUM2' = J(`M', `L', 0)
        matrix `NB'   = J(`M', `L', 0)
        if "`validate'" != "" {
            matrix `QSUM'  = J(`M', 1, 0)
            matrix `QSUM2' = J(`M', 1, 0)
        }
        if "`nodots'" == "" {
            di as txt _n "Panel block bootstrap (`reps' replications; resampling `ivar')"
        }
        forvalues r = 1/`reps' {
            preserve
            qui keep if `touse'
            tempvar bid btouse
            qui bsample, cluster(`gid') idcluster(`bid')
            qui gen byte `btouse' = 1
            capture _xtqqr_core `y' `x' `ctrl', touse(`btouse') ivar(`bid') ///
                tvar(`tvar') tau(`tau') theta(`theta') bw(`bw')             ///
                ktype(`ktype') fe(`fe') `timefe' xref(`xref')               ///
                method(`method') groups(`groups') vt(`vt') `validate' nose nodots
            local brc = _rc
            if !`brc' {
                matrix `BB' = r(B)
                if "`validate'" != "" {
                    matrix `QB' = r(QR)
                }
            }
            restore
            if !`brc' {
                forvalues i = 1/`M' {
                    forvalues j = 1/`L' {
                        local v = `BB'[`i', `j']
                        if `v' < . {
                            matrix `SUM'[`i', `j']  = `SUM'[`i', `j'] + `v'
                            matrix `SUM2'[`i', `j'] = `SUM2'[`i', `j'] + `v' * `v'
                            matrix `NB'[`i', `j']   = `NB'[`i', `j'] + 1
                        }
                    }
                    if "`validate'" != "" {
                        local v = `QB'[`i', 1]
                        if `v' < . {
                            matrix `QSUM'[`i', 1]  = `QSUM'[`i', 1] + `v'
                            matrix `QSUM2'[`i', 1] = `QSUM2'[`i', 1] + `v' * `v'
                        }
                    }
                }
            }
            if "`nodots'" == "" {
                if `brc' di as err "x" _c
                else     di as txt "." _c
                if mod(`r', 50) == 0 di as txt " " `r'
            }
        }
        if "`nodots'" == "" di ""
        matrix `SE' = J(`M', `L', .)
        forvalues i = 1/`M' {
            forvalues j = 1/`L' {
                local nb = `NB'[`i', `j']
                if `nb' > 1 {
                    local mb = `SUM'[`i', `j'] / `nb'
                    local vb = (`SUM2'[`i', `j'] - `nb' * `mb' * `mb') / (`nb' - 1)
                    if `vb' > 0 matrix `SE'[`i', `j'] = sqrt(`vb')
                }
            }
            if "`validate'" != "" {
                local mb = `QSUM'[`i', 1] / `reps'
                local vb = (`QSUM2'[`i', 1] - `reps' * `mb' * `mb') / (`reps' - 1)
                if `vb' > 0 matrix `QR'[`i', 2] = sqrt(`vb')
                else        matrix `QR'[`i', 2] = .
                local zq = `QR'[`i', 1] / `QR'[`i', 2]
                matrix `QR'[`i', 3] = 2 * normal(-abs(`zq'))
            }
        }
    }

    * ----------------------------------------------------- t, p matrices
    tempname T P TAUV THV
    matrix `T' = J(`M', `L', .)
    matrix `P' = J(`M', `L', .)
    forvalues i = 1/`M' {
        forvalues j = 1/`L' {
            local b = `B'[`i', `j']
            local s = `SE'[`i', `j']
            if `b' < . & `s' < . & `s' > 0 {
                matrix `T'[`i', `j'] = `b' / `s'
                matrix `P'[`i', `j'] = 2 * normal(-abs(`b' / `s'))
            }
        }
    }
    matrix `TAUV' = J(`M', 1, .)
    local i = 0
    foreach t of local tau {
        local ++i
        matrix `TAUV'[`i', 1] = `t'
    }
    matrix `THV' = J(`L', 1, .)
    if "`method'" == "kernel" {
        local j = 0
        foreach t of local theta {
            local ++j
            matrix `THV'[`j', 1] = `t'
        }
    }
    else {
        forvalues j = 1/`L' {
            matrix `THV'[`j', 1] = `j' + 1
        }
    }

    * labels
    local rn ""
    foreach t of local tau {
        local rn "`rn' tau`=round(100*`t', 1)'"
    }
    local cn ""
    if "`method'" == "kernel" {
        foreach t of local theta {
            local cn "`cn' theta`=round(100*`t', 1)'"
        }
    }
    else {
        forvalues j = 2/`groups' {
            local cn "`cn' g`j'"
        }
    }
    foreach m in B SE T P R2 {
        matrix rownames ``m'' = `rn'
        matrix colnames ``m'' = `cn'
    }
    if "`validate'" != "" {
        matrix rownames `QR' = `rn'
        matrix colnames `QR' = b_QR se_QR p_QR b_QQavg sd_QQ diff
    }

    * ----------------------------------------------------------- saving
    if `"`saving'"' != "" {
        _xtqqr_savelong `B' `SE' `T' `P' `R2' `TAUV' `THV', saving(`saving')
    }

    * ------------------------------------------------------------- post
    ereturn post, esample(`touse') obs(`N')
    ereturn matrix coef  = `B', copy
    ereturn matrix se    = `SE', copy
    ereturn matrix t     = `T', copy
    ereturn matrix p     = `P', copy
    ereturn matrix r2    = `R2', copy
    ereturn matrix nobs  = `NOBS', copy
    ereturn matrix tau   = `TAUV', copy
    ereturn matrix theta = `THV', copy
    if "`validate'" != "" {
        ereturn matrix qrcomp = `QR', copy
    }
    ereturn scalar N      = `N'
    ereturn scalar N_g    = `Ng'
    ereturn scalar bw     = `bw'
    ereturn scalar level  = `level'
    ereturn scalar n_tau  = `M'
    ereturn scalar n_theta = `L'
    if "`vce'" == "bootstrap" ereturn scalar reps = `reps'
    if "`method'" == "groups" ereturn scalar groups = `groups'
    ereturn local depvar   "`y'"
    ereturn local qqvar    "`x'"
    ereturn local controls "`ctrl'"
    ereturn local ivar     "`ivar'"
    ereturn local tvar     "`tvar'"
    ereturn local fe       "`fe'"
    ereturn local timefe   "`timefe'"
    ereturn local xref     "`xref'"
    ereturn local method   "`method'"
    ereturn local kernel   "`kernel'"
    ereturn local vce      "`vce'"
    ereturn local taulist  "`tau'"
    ereturn local thetalist "`theta'"
    ereturn local title    "Panel quantile-on-quantile regression"
    ereturn local estimator "qqr"
    ereturn local cmdline  "xtqqr `0'"
    ereturn local cmd      "xtqqr"

    if "`notable'" == "" {
        _xtqqr_show, block(`block')
    }
    if "`graph'" != "" {
        capture noisily xtqqplot, heatmap
    }
end


* =====================================================================
* Estimation core: one full pass over the (tau, theta) grid.
* Called once on the data and once per bootstrap replication.
* =====================================================================
program define _xtqqr_core, rclass
    version 14.0
    syntax varlist(min=2 numeric ts), touse(varname) ivar(varname)     ///
        tvar(varname) tau(numlist) theta(numlist) bw(real) ktype(integer) ///
        fe(string) xref(string) method(string) groups(integer)          ///
        vt(integer) [ TIMEfe VALidate NOSE NODOTS ]

    gettoken y rest : varlist
    gettoken x ctrl : rest

    local M : word count `tau'
    local L : word count `theta'
    if "`method'" == "groups" local L = `groups' - 1

    * ts operators -> plain temporary variables
    tempvar yy xx
    qui gen double `yy' = `y' if `touse'
    qui gen double `xx' = `x' if `touse'
    local cvars ""
    foreach c of local ctrl {
        tempvar cv
        qui gen double `cv' = `c' if `touse'
        local cvars "`cvars' `cv'"
    }

    * time dummies (first period = base)
    local tdums ""
    if "`timefe'" != "" {
        qui levelsof `tvar' if `touse', local(tlev)
        local first 1
        foreach l of local tlev {
            if `first' {
                local first 0
                continue
            }
            tempvar td
            qui gen byte `td' = (`tvar' == `l') if `touse'
            local tdums "`tdums' `td'"
        }
    }
    * unit dummies for fe(dummy)
    local udums ""
    if "`fe'" == "dummy" {
        qui levelsof `ivar' if `touse', local(ulev)
        local first 1
        foreach l of local ulev {
            if `first' {
                local first 0
                continue
            }
            tempvar ud
            qui gen byte `ud' = (`ivar' == `l') if `touse'
            local udums "`udums' `ud'"
        }
    }

    * ------------------------------------------- [S5] fixed effects step
    tempvar ytil
    if "`fe'" == "canay" {
        tempvar ahat
        * within (FE) regression; a_i = absorbed unit effect
        capture areg `yy' `xx' `cvars' `tdums' if `touse', absorb(`ivar')
        if _rc {
            di as err "Canay first step (within regression) failed"
            exit 498
        }
        qui predict double `ahat' if `touse', d
        qui gen double `ytil' = `yy' - `ahat' if `touse'
    }
    else {
        qui gen double `ytil' = `yy' if `touse'
    }

    * ---------------------------------------------------- [S3] F_n(x)
    tempvar F xq w xc one
    qui gen double `F'  = .
    qui gen double `xq' = .
    qui gen double `w'  = .
    qui gen double `xc' = .
    qui gen byte `one' = 1 if `touse'
    if "`xref'" == "unit" {
        mata: st_store(., "`F'", "`touse'", ///
            xqq_ecdf_by(st_data(., "`xx'", "`touse'"), st_data(., "`ivar'", "`touse'")))
    }
    else {
        mata: st_store(., "`F'", "`touse'", xqq_ecdf(st_data(., "`xx'", "`touse'")))
    }

    tempname B SE R2 NOBS bb VV
    matrix `B'  = J(`M', `L', .)
    matrix `SE' = J(`M', `L', .)
    matrix `R2' = J(`M', `L', .)
    matrix `NOBS' = J(1, `L', .)
    local rhs_extra "`cvars' `tdums' `udums'"

    if "`method'" == "kernel" {
        local j = 0
        foreach th of local theta {
            local ++j
            * x^theta : pooled or unit-specific theta-quantile    [S2]
            if "`xref'" == "unit" {
                mata: st_store(., "`xq'", "`touse'", xqq_quant_by( ///
                    st_data(., "`xx'", "`touse'"), st_data(., "`ivar'", "`touse'"), `th'))
            }
            else {
                mata: st_store(., "`xq'", "`touse'", J(rows(st_data(., "`xx'", ///
                    "`touse'")), 1, xqq_quant(st_data(., "`xx'", "`touse'"), `th')))
            }
            * kernel weights K((F_n - theta)/h)/h and x - x^theta  [S4]
            mata: xqq_cellvars("`F'", "`xx'", "`xq'", "`touse'", `th', `bw', ///
                `ktype', "`w'", "`xc'")
            * Kish effective sample size of the kernel weights
            mata: st_numscalar("r(ess)", xqq_ess(st_data(., "`w'", "`touse'")))
            matrix `NOBS'[1, `j'] = r(ess)
            local i = 0
            foreach t of local tau {
                local ++i
                capture qreg `ytil' `xc' `rhs_extra' [iw = `w'] ///
                    if `touse' & `w' > 0, quantile(`t')
                if _rc {
                    continue
                }
                matrix `bb' = e(b)
                matrix `B'[`i', `j'] = `bb'[1, 1]
                if "`nose'" == "" {
                    mata: xqq_sandwich("`ytil'", "`xc' `rhs_extra'", "`bb'", ///
                        `t', "`w'", `vt', "`ivar'", "`touse'", "`VV'")
                    if `VV'[1, 1] > 0 & `VV'[1, 1] < . {
                        matrix `SE'[`i', `j'] = sqrt(`VV'[1, 1])
                    }
                    mata: st_numscalar("r(pr2)", xqq_pr2("`ytil'", ///
                        "`xc' `rhs_extra'", "`bb'", `t', "`w'", "`touse'"))
                    matrix `R2'[`i', `j'] = r(pr2)
                }
            }
            if "`nodots'" == "" {
                di as txt "." _c
            }
        }
        if "`nodots'" == "" di ""
    }
    else {
        * ------------------------------- quantile-group variant (Clance)
        tempvar gx
        if "`xref'" == "unit" {
            qui gen int `gx' = .
            mata: st_store(., "`gx'", "`touse'", ///
                1 :+ floor(`groups' :* xqq_ecdf_by(st_data(., "`xx'", "`touse'"), ///
                st_data(., "`ivar'", "`touse'"))))
        }
        else {
            qui xtile `gx' = `xx' if `touse', nquantiles(`groups')
        }
        qui replace `gx' = `groups' if `gx' > `groups' & `gx' < . & `touse'
        local gdums ""
        forvalues g = 2/`groups' {
            tempvar gd
            qui gen byte `gd' = (`gx' == `g') if `touse'
            local gdums "`gdums' `gd'"
        }
        forvalues g = 2/`groups' {
            qui count if `touse' & `gx' == `g'
            matrix `NOBS'[1, `g' - 1] = r(N)
        }
        local i = 0
        foreach t of local tau {
            local ++i
            capture qreg `ytil' `gdums' `rhs_extra' if `touse', quantile(`t')
            if _rc {
                continue
            }
            matrix `bb' = e(b)
            forvalues g = 1/`L' {
                matrix `B'[`i', `g'] = `bb'[1, `g']
            }
            if "`nose'" == "" {
                mata: xqq_sandwich("`ytil'", "`gdums' `rhs_extra'", "`bb'", ///
                    `t', "`one'", `vt', "`ivar'", "`touse'", "`VV'")
                mata: st_numscalar("r(pr2)", xqq_pr2("`ytil'", ///
                    "`gdums' `rhs_extra'", "`bb'", `t', "`one'", "`touse'"))
                forvalues g = 1/`L' {
                    if `VV'[`g', `g'] > 0 & `VV'[`g', `g'] < . {
                        matrix `SE'[`i', `g'] = sqrt(`VV'[`g', `g'])
                    }
                    matrix `R2'[`i', `g'] = r(pr2)
                }
            }
            if "`nodots'" == "" {
                di as txt "." _c
            }
        }
        if "`nodots'" == "" di ""
    }

    * ------------------------------------- [S6] validation vs panel QR
    if "`validate'" != "" {
        tempname QR
        matrix `QR' = J(`M', 6, .)
        local i = 0
        foreach t of local tau {
            local ++i
            capture qreg `ytil' `xx' `rhs_extra' if `touse', quantile(`t')
            if !_rc {
                matrix `bb' = e(b)
                matrix `QR'[`i', 1] = `bb'[1, 1]
                if "`nose'" == "" {
                    mata: xqq_sandwich("`ytil'", "`xx' `rhs_extra'", "`bb'", ///
                        `t', "`one'", `vt', "`ivar'", "`touse'", "`VV'")
                    if `VV'[1, 1] > 0 & `VV'[1, 1] < . {
                        matrix `QR'[`i', 2] = sqrt(`VV'[1, 1])
                        matrix `QR'[`i', 3] = 2 * normal(-abs(`bb'[1, 1] / sqrt(`VV'[1, 1])))
                    }
                }
            }
            * average of the QQ slopes over theta (Sim-Zhou; Wu et al. 2021)
            local s = 0
            local s2 = 0
            local n = 0
            forvalues j = 1/`L' {
                local v = `B'[`i', `j']
                if `v' < . {
                    local s = `s' + `v'
                    local s2 = `s2' + `v' * `v'
                    local ++n
                }
            }
            if `n' > 0 {
                matrix `QR'[`i', 4] = `s' / `n'
                if `n' > 1 {
                    matrix `QR'[`i', 5] = sqrt(max(0, (`s2' - `n' * (`s' / `n')^2) / (`n' - 1)))
                }
                if `QR'[`i', 1] < . {
                    matrix `QR'[`i', 6] = `QR'[`i', 4] - `QR'[`i', 1]
                }
            }
        }
        * in the bootstrap the replicated statistic is the QR slope (col 1)
        return matrix QR = `QR'
    }

    local kpar : word count `rhs_extra'
    return scalar k = `kpar' + 2
    return matrix B  = `B'
    return matrix SE = `SE'
    return matrix R2 = `R2'
    return matrix nobs = `NOBS'
end


* =====================================================================
* Display of results stored in e()
* =====================================================================
program define _xtqqr_show
    version 14.0
    syntax [, BLOCK(integer 8)]
    tempname B P S TAU TH Q
    matrix `B'   = e(coef)
    matrix `P'   = e(p)
    matrix `TAU' = e(tau)
    matrix `TH'  = e(theta)
    local fmt "%7.3f"

    if "`e(method)'" == "kernel" {
        di as txt _n "{bf:QQ slope estimates  b1(tau, theta)}" ///
            "   rows: quantiles of `e(depvar)';  columns: quantiles of `e(qqvar)'"
    }
    else {
        di as txt _n "{bf:Quantile-group effects}  rows: quantiles of `e(depvar)';" ///
            "  columns: group g of `e(qqvar)' vs group 1"
    }
    mata: xqq_print("`B'", "`P'", st_matrix("`TAU'"), st_matrix("`TH'"), `block', "`fmt'")

    mata: xqq_summary("`B'", "`P'", "`S'")
    local nc = `S'[1, 9]
    di as txt _n "{bf:Summary of the estimated surface}"
    di as txt "{hline 40}{c TT}{hline 12}"
    di as txt "  Mean of b1(tau,theta)" _col(41) "{c |}" as res %11.4f `S'[1, 1]
    di as txt "  Median" _col(41) "{c |}" as res %11.4f `S'[1, 2]
    di as txt "  Minimum" _col(41) "{c |}" as res %11.4f `S'[1, 3]
    di as txt "  Maximum" _col(41) "{c |}" as res %11.4f `S'[1, 4]
    di as txt "  Std. dev. across cells" _col(41) "{c |}" as res %11.4f `S'[1, 5]
    di as txt "  Cells significant at 10% / 5% / 1%" _col(41) "{c |}" ///
        as res %4.0f `S'[1, 6] " /" %3.0f `S'[1, 7] " /" %3.0f `S'[1, 8]
    di as txt "  Cells estimated" _col(41) "{c |}" as res %11.0f `nc'
    di as txt "{hline 40}{c BT}{hline 12}"

    capture confirm matrix e(qrcomp)
    if !_rc {
        matrix `Q' = e(qrcomp)
        local M = rowsof(`Q')
        di as txt _n "{bf:Validation: averaged QQ slopes vs panel quantile regression}"
        di as txt "  (Sim & Zhou 2015; Wu et al. 2021:  mean over theta of b1(tau,theta)" ///
            " vs b(tau))"
        di as txt "{hline 9}{c TT}{hline 40}{c TT}{hline 26}"
        di as txt "     tau {c |}   Panel QR b(tau)    s.e.      p-value  {c |}" ///
            "  QQ average   sd    diff"
        di as txt "{hline 9}{c +}{hline 40}{c +}{hline 26}"
        forvalues i = 1/`M' {
            local p = `Q'[`i', 3]
            local st ""
            if `p' < 0.10 local st "*"
            if `p' < 0.05 local st "**"
            if `p' < 0.01 local st "***"
            di as txt "   " %5.2f `TAU'[`i', 1] " {c |}" as res %13.4f `Q'[`i', 1] ///
                as txt %-3s "`st'" as res %10.4f `Q'[`i', 2] %11.4f `Q'[`i', 3] ///
                as txt "  {c |}" as res %10.4f `Q'[`i', 4] %7.3f `Q'[`i', 5] ///
                %8.4f `Q'[`i', 6]
        }
        di as txt "{hline 9}{c BT}{hline 40}{c BT}{hline 26}"
        tempname c1 c4
        matrix `c1' = `Q'[1..., 1]
        matrix `c4' = `Q'[1..., 4]
        mata: st_numscalar("r(rho)", correlation((st_matrix("`c1'"), st_matrix("`c4'")))[2,1])
        di as txt "  Correlation(panel QR, QQ average) across tau = " as res %6.3f r(rho)
    }

    di as txt _n "Notes: *** p<0.01, ** p<0.05, * p<0.10 (normal approximation)."
    if "`e(vce)'" == "cluster" {
        di as txt "       Std. errors: Powell kernel sandwich clustered by `e(ivar)'" ///
            " (Parente & Santos Silva 2016)."
    }
    else if "`e(vce)'" == "bootstrap" {
        di as txt "       Std. errors: panel block bootstrap (`e(reps)' replications," ///
            " whole procedure re-estimated)."
    }
    else {
        di as txt "       Std. errors: Powell kernel sandwich, `e(vce)'."
    }
    if "`e(fe)'" == "canay" {
        di as txt "       Fixed effects removed by Canay (2011) two-step transformation."
    }
    di as txt "       Plots: {stata xtqqplot, heatmap} {c |} {stata xtqqplot, slices}" ///
        " {c |} {stata xtqqplot, validate}"
end
