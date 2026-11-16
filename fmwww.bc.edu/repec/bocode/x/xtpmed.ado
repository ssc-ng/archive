*! version 2.3.0  15nov2026
*! xtpmed: causal mediation analysis for (unbalanced) panel data with
*! multiple mediators, nine panel estimators and residual diagnostics
*! Author: Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria

program define xtpmed, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "xtpmed") error 301
        _xp_display `0'
        exit
    }

    syntax varname(numeric) [if] [in],              ///
        TREATment(varname numeric)                  ///
        MEDiators(varlist numeric)                  ///
        [ CONTrols(varlist numeric)                 ///
          ESTimator(string)                         ///
          VCE(string)                               ///
          DKLag(integer -1)                         ///
          TIMEfe                                    ///
          LAGs(integer 1)                           ///
          IVLags(integer 3)                         ///
          POLY(integer 2)                           ///
          FOLDs(integer 5)                          ///
          REPeat(integer 1)                         ///
          RIDGE(real 0)                             ///
          DSQ                                       ///
          ONEstep                                   ///
          NOCOLlapse                                ///
          D1(real 1) D0(real 0)                     ///
          BOOTstrap(integer 0)                      ///
          SEED(string)                              ///
          NODOTS                                    ///
          NODIAG                                    ///
          BREAK(string)                             ///
          ARDLlags(numlist integer min=2 max=2 >=1) ///
          IC(string) MAXP(integer 3) MAXQ(integer 3) ///
          Level(cilevel) ]

    local depvar `varlist'

    * ---------------- estimator and vce ----------------
    if "`estimator'" == "" local estimator dml
    local estimator = lower("`estimator'")
    local estlist dml fe re dfe mg pmg ccep ccemg csardl
    if !`: list estimator in estlist' {
        di as err "estimator() must be one of: `estlist'"
        exit 198
    }
    local estcode : list posof "`estimator'" in estlist
    if "`vce'" == "" local vce cluster
    local vce = lower("`vce'")
    if "`vce'" == "dkraay" | "`vce'" == "driscoll" local vce dk
    if !inlist("`vce'", "cluster", "dk") {
        di as err "vce() must be {bf:cluster} or {bf:dk} (Driscoll-Kraay)"
        exit 198
    }
    if "`vce'" == "dk" & inlist("`estimator'", "mg", "ccemg", "csardl") {
        di as err "vce(dk) is not available for mean-group estimators; their variance is the mean-group (cross-unit) variance"
        exit 198
    }
    if "`timefe'" != "" & !inlist("`estimator'", "fe", "re", "dfe") {
        di as txt "(note: timefe applies to fe, re and dfe only; ignored)"
        local timefe
    }
    if "`estimator'" != "dml" {
        foreach o in dsq onestep nocollapse {
            if "``o''" != "" {
                di as txt "(note: `o' applies to estimator(dml) only; ignored)"
                local `o'
            }
        }
        if `repeat' > 1 {
            di as txt "(note: repeat() applies to estimator(dml) only; ignored)"
            local repeat 1
        }
    }

    * ---------------- ARDL lag orders ----------------
    local isardl = inlist("`estimator'", "dfe", "mg", "pmg", "csardl")
    local icode 0
    local pf 1
    local qf 1
    if "`ic'`ardllags'" != "" & !`isardl' {
        di as txt "(note: ardllags() and ic() apply to dfe, mg, pmg and csardl only; ignored)"
        local ic
        local ardllags
    }
    if "`ic'" != "" & "`ardllags'" != "" {
        di as err "specify either ardllags() or ic(), not both"
        exit 198
    }
    if "`ardllags'" != "" {
        local pf : word 1 of `ardllags'
        local qf : word 2 of `ardllags'
    }
    if "`ic'" != "" {
        local ic = lower("`ic'")
        if "`ic'" == "sbc" | "`ic'" == "sic" local ic bic
        if "`ic'" == "hq" local ic hqic
        local icode = cond("`ic'"=="aic", 1, cond("`ic'"=="bic", 2, cond("`ic'"=="hqic", 3, 0)))
        if `icode' == 0 {
            di as err "ic() must be aic, bic or hqic"
            exit 198
        }
        if `maxp' < 1 | `maxq' < 1 | `maxp' > 8 | `maxq' > 8 {
            di as err "maxp() and maxq() must be between 1 and 8"
            exit 198
        }
    }
    local lagmax = cond(`icode' > 0, max(`maxp', `maxq'), max(`pf', `qf'))

    * ---------------- checks on options ----------------
    if `lags' < 0 | `ivlags' < 1 | `repeat' < 1 | `ridge' < 0 | `bootstrap' < 0 {
        di as err "invalid lags(), ivlags(), repeat(), ridge() or bootstrap()"
        exit 198
    }
    if !inrange(`poly', 1, 3) {
        di as err "poly() must be 1, 2 or 3"
        exit 198
    }
    if `folds' < 3 {
        di as err "folds() must be at least 3"
        exit 198
    }
    if `bootstrap' > 0 & `bootstrap' < 50 {
        di as err "bootstrap() should be at least 50 replications"
        exit 198
    }
    if `d1' == `d0' {
        di as err "d1() and d0() must differ"
        exit 198
    }
    local allv `depvar' `treatment' `mediators'
    local dups : list dups allv
    if "`dups'" != "" {
        di as err "depvar, treatment() and mediators() must be distinct variables"
        exit 198
    }
    local controls : list controls - allv
    local km : word count `mediators'
    local kx : word count `controls'
    local kdsq = ("`dsq'" != "")
    if "`estimator'" == "dml" {
        if `ivlags'*(1+`kdsq') < `lags' + 1 + `kdsq' {
            di as err "too few instruments: increase ivlags() (need ivlags() >= lags()+1)"
            exit 481
        }
    }

    * ---------------- panel structure (unbalanced allowed) ----------------
    qui xtset
    local ivar  "`r(panelvar)'"
    local tvar  "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local delta = cond(missing(r(tdelta)), 1, r(tdelta))

    marksample touse
    markout `touse' `treatment' `mediators' `controls'
    qui count if `touse'
    local NT = r(N)
    if `NT' == 0 error 2000

    tempvar gid tid
    qui egen long `gid' = group(`ivar') if `touse'
    qui summ `tvar' if `touse', meanonly
    local tmin = r(min)
    qui gen long `tid' = round((`tvar' - `tmin')/`delta') + 1 if `touse'
    qui summ `gid', meanonly
    local N = r(max)
    qui summ `tid', meanonly
    local T = r(max)
    qui count if `touse' & abs((`tvar' - `tmin')/`delta' + 1 - `tid') > 1e-6
    if r(N) > 0 {
        di as err "time variable is not on a regular grid of the xtset delta"
        exit 459
    }
    local minT = cond("`estimator'"=="dml", `lags' + 4, cond(`isardl', `lagmax' + 4, 4))
    if `T' < `minT' {
        di as err "too few time periods (T = `T')"
        exit 2001
    }
    if `N' < 2*`folds' & "`estimator'" == "dml" {
        di as err "too few panels for `folds' folds (N = `N')"
        exit 2001
    }

    * break period for the stability test (grid index)
    if "`break'" == "" local brk = floor((`T' + 1)/2)
    else {
        capture confirm number `break'
        if _rc {
            di as err "break() must be a value of the time variable"
            exit 198
        }
        local brk = round((`break' - `tmin')/`delta') + 1
        if `brk' < 2 | `brk' >= `T' {
            di as err "break() must lie strictly inside the sample period"
            exit 198
        }
    }
    if `dklag' < 0 local dklag = floor(4*(`T'/100)^(2/9))

    if "`seed'" != "" set seed `seed'

    * ---------------- estimation (Mata) ----------------
    tempname b V EFF BEFF VEFF BBOOT DIAG CHOWJ
    mata: _xp_main("`depvar'", "`treatment'", "`mediators'", "`controls'",       ///
        "`touse'", "`gid'", "`tid'", `N', `T', `estcode', ("`vce'"=="dk"),     ///
        `dklag', ("`timefe'"!=""), `lags', `ivlags', `poly', `folds',          ///
        `repeat', `ridge', `kdsq', ("`onestep'"==""), ("`nocollapse'"==""),     ///
        `d1', `d0', `bootstrap', ("`nodots'"==""), `level', ("`nodiag'"==""),   ///
        `brk', `icode', `pf', `qf', `maxp', `maxq')

    * ---------------- coefficient names ----------------
    local names ""
    local ecm = inlist("`estimator'", "dfe", "mg", "pmg", "csardl")
    if "`estimator'" == "dml" {
        forvalues l = 0/`lags' {
            local op = cond(`l'==0, "", cond(`l'==1, "L.", "L`l'."))
            local names `names' `depvar':`op'`treatment'
        }
        foreach v of local mediators {
            forvalues l = 0/`lags' {
                local op = cond(`l'==0, "", cond(`l'==1, "L.", "L`l'."))
                local names `names' `depvar':`op'`v'
            }
        }
        if `kdsq' local names `names' `depvar':c.`treatment'#c.`treatment'
        foreach m of local mediators {
            forvalues l = 0/`lags' {
                local op = cond(`l'==0, "", cond(`l'==1, "L.", "L`l'."))
                local names `names' `m':`op'`treatment'
            }
            if `kdsq' local names `names' `m':c.`treatment'#c.`treatment'
        }
    }
    else {
        foreach v in `treatment' `mediators' `controls' {
            local names `names' `depvar':`v'
        }
        if `ecm' local names `names' `depvar':ec
        foreach m of local mediators {
            foreach v in `treatment' `controls' {
                local names `names' `m':`v'
            }
            if `ecm' local names `names' `m':ec
        }
    }

    matrix `b' = __xp_b
    matrix `V' = __xp_V
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'

    local enames NDE NIE TE PM
    if `km' > 1 {
        foreach m of local mediators {
            local enames `enames' NIE_`=substr("`m'", 1, 28)'
        }
    }
    if "`estimator'" == "dml" local enames `enames' NDE_0 NIE_0 TE_0
    matrix `EFF'  = __xp_eff
    matrix `BEFF' = __xp_beff
    matrix `VEFF' = __xp_veff
    matrix rownames `EFF' = `enames'
    matrix colnames `EFF' = b se z pvalue ll ul
    matrix colnames `BEFF' = `enames'
    matrix colnames `VEFF' = `enames'
    matrix rownames `VEFF' = `enames'
    local Jstat = scalar(__xp_J)
    local Jdf   = scalar(__xp_Jdf)
    local nfail = scalar(__xp_bfail)
    if "`nodiag'" == "" {
        matrix `DIAG' = __xp_diag
        matrix `CHOWJ' = __xp_chowj
        local dn SC1 SC2 MWald BF Koenker CD CDw LMbc meanrho JB skew kurt Chow PYdelta PYdadj ECT
        matrix rownames `DIAG' = `dn'
        local cn ""
        foreach v in `depvar' `mediators' {
            local cn `cn' `v':stat `v':df1 `v':df2 `v':p
        }
        matrix colnames `DIAG' = `cn'
        matrix colnames `CHOWJ' = stat df p
    }
    if `bootstrap' > 0 {
        matrix `BBOOT' = __xp_bboot
        matrix colnames `BBOOT' = `enames'
    }
    tempname LAGS SRM
    matrix `LAGS' = __xp_lags
    matrix rownames `LAGS' = `depvar' `mediators'
    matrix colnames `LAGS' = p q
    if `isardl' {
        matrix `SRM' = __xp_sr
        local srn ""
        local q 0
        foreach eq in `depvar' `mediators' {
            local ++q
            local pq = `LAGS'[`q', 1]
            local qq = `LAGS'[`q', 2]
            if `q' == 1 local xv `treatment' `mediators' `controls'
            else local xv `treatment' `controls'
            local srn `srn' `eq':ec
            forvalues j = 0/`=`qq' - 1' {
                local op = cond(`j' == 0, "D.", cond(`j' == 1, "LD.", "L`j'D."))
                foreach v of local xv {
                    local srn `srn' `eq':`op'`v'
                }
            }
            forvalues j = 1/`=`pq' - 1' {
                local op = cond(`j' == 1, "LD.", "L`j'D.")
                local srn `srn' `eq':`op'`eq'
            }
            if "`estimator'" != "dfe" local srn `srn' `eq':_cons
        }
        local zc = invnormal(1 - (1 - `level' / 100) / 2)
        matrix `SRM' = (`SRM', J(rowsof(`SRM'), 4, .))
        forvalues r = 1/`=rowsof(`SRM')' {
            matrix `SRM'[`r', 3] = `SRM'[`r', 1] / `SRM'[`r', 2]
            matrix `SRM'[`r', 4] = 2 * normal(-abs(`SRM'[`r', 1] / `SRM'[`r', 2]))
            matrix `SRM'[`r', 5] = `SRM'[`r', 1] - `zc' * `SRM'[`r', 2]
            matrix `SRM'[`r', 6] = `SRM'[`r', 1] + `zc' * `SRM'[`r', 2]
        }
        matrix rownames `SRM' = `srn'
        matrix colnames `SRM' = b se z pvalue ll ul
    }
    foreach x in b V eff beff veff bboot diag chowj lags sr {
        capture matrix drop __xp_`x'
    }
    foreach x in J Jdf bfail {
        capture scalar drop __xp_`x'
    }

    ereturn post `b' `V', esample(`touse') obs(`NT') depname(`depvar')
    ereturn scalar N_g      = `N'
    ereturn scalar T        = `T'
    ereturn scalar km       = `km'
    ereturn scalar d1       = `d1'
    ereturn scalar d0       = `d0'
    ereturn scalar level    = `level'
    ereturn scalar bootstrap = `bootstrap'
    ereturn scalar dklag    = `dklag'
    ereturn scalar break_t  = `tmin' + (`brk' - 1)*`delta'
    if "`estimator'" == "dml" {
        ereturn scalar lags   = `lags'
        ereturn scalar ivlags = `ivlags'
        ereturn scalar poly   = `poly'
        ereturn scalar folds  = `folds'
        ereturn scalar repeat = `repeat'
        ereturn scalar J      = `Jstat'
        ereturn scalar J_df   = `Jdf'
        if `Jdf' > 0 ereturn scalar J_p = chi2tail(`Jdf', `Jstat')
        ereturn local gmm   = cond("`onestep'"=="", "two-step", "one-step")
        ereturn local instr = cond("`nocollapse'"=="", "collapsed", "period-specific")
    }
    if `bootstrap' > 0 {
        ereturn scalar boot_fail = `nfail'
        ereturn matrix eff_boot = `BBOOT'
    }
    if "`nodiag'" == "" {
        ereturn matrix diag  = `DIAG'
        ereturn matrix chow  = `CHOWJ'
    }
    if `isardl' {
        ereturn matrix ardllags = `LAGS'
        ereturn matrix sr = `SRM'
        ereturn local ic = cond(`icode' > 0, "`ic'", "")
        ereturn scalar maxp = cond(`icode' > 0, `maxp', .)
        ereturn scalar maxq = cond(`icode' > 0, `maxq', .)
    }
    ereturn matrix effects = `EFF'
    ereturn matrix b_eff   = `BEFF'
    ereturn matrix V_eff   = `VEFF'
    ereturn local estimator  "`estimator'"
    ereturn local vce        = cond("`vce'"=="dk", "Driscoll-Kraay", cond(inlist("`estimator'","mg","ccemg","csardl"), "mean-group", "cluster"))
    ereturn local vcetype    = cond("`vce'"=="dk", "DK", "Robust")
    ereturn local timefe     "`timefe'"
    ereturn local dsq        "`dsq'"
    ereturn local controls   "`controls'"
    ereturn local mediators  "`mediators'"
    ereturn local treatment  "`treatment'"
    ereturn local tvar       "`tvar'"
    ereturn local ivar       "`ivar'"
    ereturn local title      "Panel causal mediation analysis"
    ereturn local cmdline    `"xtpmed `0'"'
    ereturn local cmd        "xtpmed"

    _xp_display, level(`level')
end

program define _xp_display
    syntax [, Level(cilevel)]
    local est "`e(estimator)'"
    local lab_dml    "DML-GMM (Wu-Xiao), two-way FE"
    local lab_fe     "Fixed effects (within)"
    local lab_re     "Random effects (GLS)"
    local lab_dfe    "Dynamic fixed effects, ARDL-ECM"
    local lab_mg     "Mean group, ARDL-ECM"
    local lab_pmg    "Pooled mean group, ARDL-ECM"
    local lab_ccep   "CCE pooled (Pesaran 2006)"
    local lab_ccemg  "CCE mean group (Pesaran 2006)"
    local lab_csardl "CS-ARDL mean group (Chudik-Pesaran)"
    local c1 = 50
    di
    di as txt "`e(title)'" _col(`c1') "Number of obs    = " as res %10.0fc e(N)
    di as txt "Estimator: " as res "`lab_`est''" _col(`c1') as txt "Number of panels = " as res %10.0fc e(N_g)
    di as txt "Std. errors: " as res "`e(vce)'" ///
        cond("`e(vce)'"=="Driscoll-Kraay", " (lag " + string(e(dklag)) + ")", "") ///
        _col(`c1') as txt "Periods (T)      = " as res %10.0fc e(T)
    di as txt "Mediators: " as res "`e(mediators)'"
    if "`e(timefe)'" != "" di as txt "Time fixed effects included"
    if "`est'" == "dml" {
        di as txt "Learner: series degree " as res e(poly) as txt "; folds " as res e(folds) ///
            as txt "; splits " as res e(repeat) as txt "; GMM " as res "`e(gmm)'" ///
            as txt ", instruments " as res "`e(instr)'"
        if e(J_df) > 0 di as txt "Hansen J (df = " as res e(J_df) as txt ") = " ///
            as res %8.3f e(J) as txt ",  p = " as res %6.4f e(J_p)
    }
    if inlist("`est'", "dfe", "mg", "pmg", "csardl") {
        tempname LG
        matrix `LG' = e(ardllags)
        local eqs `e(depvar)' `e(mediators)'
        local ltxt ""
        local q 0
        foreach eq of local eqs {
            local ++q
            local ltxt = "`ltxt' `eq'(" + string(`LG'[`q',1]) + "," + string(`LG'[`q',2]) + ")"
        }
        if "`e(ic)'" != "" di as txt "ARDL(p,q) by equation:" as res "`ltxt'" ///
            as txt "  [selected by " as res upper("`e(ic)'") as txt ", maxp = " as res e(maxp) ///
            as txt ", maxq = " as res e(maxq) as txt "]"
        else di as txt "ARDL(p,q) by equation:" as res "`ltxt'"
        di as txt "Coefficients are long-run; " as res "ec" as txt " = speed of adjustment"
    }
    ereturn display, level(`level')
    _xp_srdisplay, level(`level')

    tempname E
    matrix `E' = e(effects)
    local rn : rownames `E'
    di
    di as txt "Causal mediation effects of moving `e(treatment)' from " as res %9.0g e(d0) ///
        as txt " to " as res %9.0g e(d1)
    if e(bootstrap) > 0 di as txt "Inference: unit bootstrap, " as res e(bootstrap) as txt " replications (percentile CI)"
    else di as txt "Inference: delta method on the joint (cross-equation) variance"
    di as txt "NDE natural direct, NIE natural indirect, TE total effect, PM proportion mediated"
    di as txt "{hline 13}{c TT}{hline 64}"
    di as txt %12s "Effect" " {c |}" ///
        "      Coef.   Std. Err.      z    P>|z|     [`level'% Conf. Interval]"
    di as txt "{hline 13}{c +}{hline 64}"
    local r 0
    foreach nm of local rn {
        local ++r
        if "`nm'" == "NDE" {
            if "`est'" == "dml" di as txt %12s "Sustained" " {c |}"
            else if inlist("`est'", "dfe", "mg", "pmg", "csardl") di as txt %12s "Long run" " {c |}"
        }
        if "`nm'" == "NDE_0" di as txt %12s "Impact" " {c |}"
        local lab "`nm'"
        if "`nm'" == "NDE"  local lab "NDE"
        if "`nm'" == "NIE"  local lab "NIE"
        if "`nm'" == "TE"   local lab "TE"
        if "`nm'" == "PM"   local lab "PM"
        if "`nm'" == "NDE_0" local lab "Impact NDE"
        if "`nm'" == "NIE_0" local lab "Impact NIE"
        if "`nm'" == "TE_0"  local lab "Impact TE"
        if substr("`nm'", 1, 4) == "NIE_" & "`nm'" != "NIE_0" {
            local medn = substr("`nm'", 5, .)
            local lab "via `medn'"
        }
        local lab = abbrev("`lab'", 12)
        di as txt %12s "`lab'" " {c |}  " as res %9.0g `E'[`r',1] "  " %9.0g `E'[`r',2] ///
            "  " %7.2f `E'[`r',3] "  " %6.3f `E'[`r',4] "    " %9.0g `E'[`r',5] "   " %9.0g `E'[`r',6]
    }
    di as txt "{hline 13}{c BT}{hline 64}"

    capture confirm matrix e(diag)
    if _rc == 0 _xp_diagdisplay
end

program define _xp_srdisplay
    syntax [, Level(cilevel)]
    capture confirm matrix e(sr)
    if _rc exit
    tempname S
    matrix `S' = e(sr)
    local rn : rownames `S'
    local req : roweq `S'
    local zc = invnormal(1 - (1 - `level' / 100) / 2)
    di
    di as txt "Short-run coefficients (error-correction form)"
    if "`e(estimator)'" == "dfe" di as txt "Pooled estimates; standard errors clustered by unit"
    else if "`e(estimator)'" == "pmg" di as txt "Averages of unit estimates given the pooled long-run coefficients;" _n ///
        "mean-group standard errors"
    else di as txt "Averages of unit estimates; mean-group standard errors"
    di as txt "{hline 13}{c TT}{hline 64}"
    di as txt %12s "" " {c |}" ///
        "      Coef.   Std. Err.      z    P>|z|     [`level'% Conf. Interval]"
    local r 0
    local prev ""
    foreach nm of local rn {
        local ++r
        local eq : word `r' of `req'
        if "`eq'" != "`prev'" {
            di as txt "{hline 13}{c +}{hline 64}"
            di as res %12s abbrev("`eq'", 12) as txt " {c |}"
            local prev "`eq'"
        }
        local lab "`nm'"
        
        local bb = `S'[`r', 1]
        local ss = `S'[`r', 2]
        di as txt %12s abbrev("`lab'", 12) " {c |}  " as res %9.0g `bb' "  " %9.0g `ss' ///
            "  " %7.2f `bb' / `ss' "  " %6.3f 2 * normal(-abs(`bb' / `ss')) ///
            "    " %9.0g `bb' - `zc' * `ss' "   " %9.0g `bb' + `zc' * `ss'
    }
    di as txt "{hline 13}{c BT}{hline 64}"
end

program define _xp_diagdisplay
    tempname G C
    matrix `G' = e(diag)
    matrix `C' = e(chow)
    local eqs `e(depvar)' `e(mediators)'
    local fd = ("`e(estimator)'" == "dml")
    di
    di as txt "Residual diagnostics (H0 in brackets)"
    local q 0
    foreach eq of local eqs {
        local ++q
        local c0 = 4*(`q' - 1)
        di as txt "{hline 79}"
        di as txt "Equation: " as res "`eq'" _col(46) as txt "Statistic        df      p-value"
        di as txt "{hline 79}"
        if `fd' {
            _xp_drow `G' 1 `c0' "AR(1) in diff. residuals  [no AR(1)]" z
            _xp_drow `G' 2 `c0' "AR(2) in diff. residuals  [no AR(2)]" z
        }
        else _xp_drow `G' 1 `c0' "Wooldridge serial corr.  [no AR(1)]" F
        _xp_drow `G' 4 `c0' "Brown-Forsythe groupwise het. [homosk.]" F
        _xp_drow `G' 3 `c0' "Modified Wald groupwise het. [homosk.]" chi2
        _xp_drow `G' 5 `c0' "Koenker-Breusch-Pagan     [homosk.]" chi2
        _xp_drow `G' 6 `c0' "Pesaran CD                [weak CSD]" z
        _xp_drow `G' 7 `c0' "Juodis-Reese CDw          [weak CSD]" z
        _xp_drow `G' 8 `c0' "Bias-corrected scaled LM  [no CSD]" z
        _xp_drow `G' 9 `c0' "  mean |rho|" none
        _xp_drow `G' 10 `c0' "Jarque-Bera normality     [normal]" chi2
        _xp_drow `G' 11 `c0' "  skewness" none
        _xp_drow `G' 12 `c0' "  kurtosis" none
        _xp_drow `G' 13 `c0' "Chow-type break test      [stable]" chi2
        _xp_drow `G' 14 `c0' "Pesaran-Yamagata delta    [homog. slopes]" z
        _xp_drow `G' 15 `c0' "Pesaran-Yamagata adj.delta [homog.]" z
        if inlist("`e(estimator)'", "dfe", "mg", "pmg", "csardl") {
            _xp_drow `G' 16 `c0' "Error-correction coef.    [ec = 0]" se
        }
    }
    di as txt "{hline 79}"
    if `C'[1,1] < . {
        di as txt "Joint Chow-type test, all equations: chi2(" as res `C'[1,2] as txt ") = " ///
            as res %9.3f `C'[1,1] as txt ",  p = " as res %6.4f `C'[1,3] ///
            as txt "   (break after " as res e(break_t) as txt ")"
    }
    di as txt "Notes: the modified Wald test over-rejects for small T; prefer Brown-Forsythe."
    di as txt "       Pesaran CD lacks power when factor loadings average zero; see LM test."
    if `fd' di as txt "       DML residuals are first-differenced and demeaned; AR(1) is expected." _n ///
        as txt "       AR tests include the Arellano-Bond estimation-effect correction."
    di as txt "       Pesaran-Yamagata uses the static fixed-effects version of each equation."
end

program define _xp_drow
    args G r c0 lab type
    local s  = `G'[`r', `c0' + 1]
    local d1 = `G'[`r', `c0' + 2]
    local d2 = `G'[`r', `c0' + 3]
    local p  = `G'[`r', `c0' + 4]
    if missing(`s') {
        di as txt "  `lab'" _col(46) as txt "      n/a"
        exit
    }
    if "`type'" == "none" {
        di as txt "  `lab'" _col(46) as res %9.3f `s'
        exit
    }
    local dtxt ""
    if "`type'" == "F" local dtxt = string(`d1') + "," + string(`d2')
    if "`type'" == "chi2" local dtxt = string(`d1')
    if "`type'" == "se" local dtxt = "se " + string(`d1', "%6.4f")
    di as txt "  `lab'" _col(46) as res %9.3f `s' as txt %12s "`dtxt'" "   " as res %8.4f `p'
end

version 14.0
mata:

// ======================================================= basic helpers
real matrix _xp_lag(real matrix A, real scalar l, real colvector tt)
{
    real matrix out
    real scalar n, k
    if (l == 0 | cols(A) == 0) return(A)
    n = rows(A); k = cols(A)
    out = J(n, k, .)
    if (n > l) out[|l+1, 1 \ n, k|] = A[|1, 1 \ n-l, k|]
    s = selectindex(tt :<= l)
    if (rows(s)) out[s, .] = J(rows(s), k, .)
    return(out)
}

real matrix _xp_diff(real matrix A, real colvector tt)
{
    if (cols(A) == 0) return(A)
    return(A - _xp_lag(A, 1, tt))
}

real colvector _xp_ok(real matrix A)
{
    if (cols(A) == 0) return(J(rows(A), 1, 1))
    return(rowmissing(A) :== 0)
}

real matrix _xp_setmiss(real matrix A, real colvector v)
{
    real matrix B
    B = A
    s = selectindex(v :== 0)
    if (rows(s) & cols(B)) B[s, .] = J(rows(s), cols(B), .)
    return(B)
}

real matrix _xp_within(real matrix A, real colvector v, real scalar N, real scalar T)
{
    real matrix B, out, S
    real scalar c
    B = _xp_setmiss(A, v)
    out = J(rows(A), cols(A), .)
    for (c = 1; c <= cols(A); c++) {
        S = colshape(B[., c], T)
        out[., c] = colshape(S :- (rowsum(S) :/ rownonmissing(S)), 1)
    }
    return(out)
}

real matrix _xp_unitmean(real matrix A, real colvector v, real scalar N, real scalar T)
{
    real matrix B, out, S
    real scalar c
    B = _xp_setmiss(A, v)
    out = J(N, cols(A), .)
    for (c = 1; c <= cols(A); c++) {
        S = colshape(B[., c], T)
        out[., c] = rowsum(S) :/ rownonmissing(S)
    }
    return(out)
}

real matrix _xp_pmean(real matrix A, real colvector v, real scalar N, real scalar T)
{
    real matrix B, out, S
    real scalar c
    B = _xp_setmiss(A, v)
    out = J(rows(A), cols(A), .)
    for (c = 1; c <= cols(A); c++) {
        S = colshape(B[., c], T)
        out[., c] = J(N, 1, (colsum(S) :/ colnonmissing(S))')
    }
    return(out)
}

real matrix _xp_tdum(real colvector tt, real scalar T)
{
    real matrix Dm
    real scalar s
    Dm = J(rows(tt), T - 1, 0)
    for (s = 2; s <= T; s++) Dm[., s - 1] = (tt :== s)
    return(Dm)
}

real matrix _xp_z0(real matrix A)
{
    return(editmissing(A, 0))
}

real colvector _xp_rows(real colvector u, real scalar T)
{
    real matrix R
    R = J(T, 1, 1) * ((u :- 1)' :* T) + (1::T) * J(1, rows(u), 1)
    return(vec(R))
}

// ======================================================= variance
real matrix _xp_vce(real matrix IF0, real scalar N, real scalar T, real scalar dk, real scalar m)
{
    real matrix IF, G, H, V, Gm
    real scalar c, k, l
    IF = editmissing(IF0, 0)
    k = cols(IF)
    if (!dk) {
        G = J(N, k, .)
        for (c = 1; c <= k; c++) G[., c] = rowsum(colshape(IF[., c], T))
        G = G :- mean(G)
        return(cross(G, G) * N / (N - 1))
    }
    H = J(T, k, .)
    for (c = 1; c <= k; c++) H[., c] = colsum(colshape(IF[., c], T))'
    H = H :- mean(H)
    V = cross(H, H)
    for (l = 1; l <= m; l++) {
        if (l >= T) break
        Gm = H[|l+1, 1 \ T, k|]' * H[|1, 1 \ T-l, k|]
        V = V + (1 - l/(m + 1)) * (Gm + Gm')
    }
    return(V * T / (T - 1))
}

// ======================================================= static FE
void _xp_fe(real colvector y, real matrix X, real colvector tt, real scalar N,
    real scalar T, real scalar tfe, real matrix R, real matrix IF, real matrix res)
{
    real matrix XX, Xt, Ai
    real colvector v, yt, b, e
    real scalar k
    k = cols(X)
    XX = (tfe ? (X, _xp_tdum(tt, T)) : X)
    v  = _xp_ok((y, XX))
    yt = _xp_z0(_xp_within(y, v, N, T))
    Xt = _xp_z0(_xp_within(XX, v, N, T))
    Ai = invsym(cross(Xt, Xt))
    b  = Ai * cross(Xt, yt)
    e  = yt - Xt * b
    IF = (Xt :* e) * Ai
    IF = IF[., 1..k]
    R  = b[1..k]
    res = _xp_setmiss(e, v)
}

// ======================================================= random effects (Swamy-Arora type)
void _xp_re(real colvector y, real matrix X, real colvector tt, real scalar N,
    real scalar T, real scalar tfe, real matrix R, real matrix IF, real matrix res)
{
    real matrix XX, Xt, Xm, Zb, Xs, Ai
    real colvector v, yt, bfe, efe, Ti, ym, u, bb, eb, th, thr, ys, b, e, comp
    real scalar k, kk, n, Nv, s2e, s2b, s2u
    k  = cols(X)
    XX = (tfe ? (X, _xp_tdum(tt, T)) : X)
    kk = cols(XX)
    v  = _xp_ok((y, XX))
    n  = sum(v)
    yt = _xp_z0(_xp_within(y, v, N, T))
    Xt = _xp_z0(_xp_within(XX, v, N, T))
    bfe = invsym(cross(Xt, Xt)) * cross(Xt, yt)
    efe = yt - Xt * bfe
    Ti  = rowsum(colshape(v, T))
    Nv  = sum(Ti :> 0)
    s2e = cross(efe, efe) / (n - Nv - kk)
    ym  = _xp_unitmean(y, v, N, T)
    Xm  = _xp_unitmean(XX, v, N, T)
    u   = selectindex(Ti :> 0)
    Zb  = (J(rows(u), 1, 1), Xm[u, .])
    bb  = invsym(cross(Zb, Zb)) * cross(Zb, ym[u])
    eb  = ym[u] - Zb * bb
    s2b = cross(eb, eb) / (rows(u) - kk - 1)
    s2u = max((0, s2b - s2e * mean(1 :/ Ti[u])))
    th  = 1 :- sqrt(s2e :/ (Ti :* s2u :+ s2e))
    thr = th # J(T, 1, 1)
    ys  = y - thr :* (ym # J(T, 1, 1))
    Xs  = (1 :- thr, XX - thr :* (Xm # J(T, 1, 1)))
    ys  = _xp_z0(_xp_setmiss(ys, v))
    Xs  = _xp_z0(_xp_setmiss(Xs, v))
    Ai  = invsym(cross(Xs, Xs))
    b   = Ai * cross(Xs, ys)
    e   = ys - Xs * b
    IF  = (Xs :* e) * Ai
    IF  = IF[., 2..(k + 1)]
    R   = b[2..(k + 1)]
    comp = _xp_setmiss((y :- b[1]) - _xp_z0(XX) * b[2..(kk + 1)], v)
    res = _xp_within(comp, v, N, T)
}

// ======================================================= ARDL(p,q) building blocks
// short-run regressors of the ARDL(p,q) error-correction form:
// D.x, L.D.x, ..., L(q-1).D.x and L.D.y, ..., L(p-1).D.y
real matrix _xp_srun(real colvector y, real matrix X, real colvector tt,
    real scalar p, real scalar q)
{
    real matrix W, dX
    real colvector dy
    real scalar j
    dX = _xp_diff(X, tt)
    dy = _xp_diff(y, tt)
    W  = J(rows(y), 0, .)
    for (j = 0; j <= q - 1; j++) W = (W, _xp_lag(dX, j, tt))
    for (j = 1; j <= p - 1; j++) W = (W, _xp_lag(dy, j, tt))
    return(W)
}

// regressors: est 4, 5, 6 -> (L.y, L.x, short-run terms) for D.y
//             est 9       -> (L.y ... Lp.y, x ... Lq.x, cross-section averages) for y
real matrix _xp_ardlrg(real scalar est, real colvector y, real matrix X, real colvector tt,
    real scalar N, real scalar T, real scalar p, real scalar q)
{
    real matrix Rg, Zb
    real scalar l, pT
    if (est != 9) return((_xp_lag(y, 1, tt), _xp_lag(X, 1, tt), _xp_srun(y, X, tt, p, q)))
    Rg = J(rows(y), 0, .)
    for (l = 1; l <= p; l++) Rg = (Rg, _xp_lag(y, l, tt))
    for (l = 0; l <= q; l++) Rg = (Rg, _xp_lag(X, l, tt))
    pT = floor(T^(1/3))
    Zb = _xp_csa(y, X, N, T)
    for (l = 0; l <= pT; l++) Rg = (Rg, _xp_lag(Zb, l, tt))
    return(Rg)
}

real scalar _xp_ic(real scalar ic, real scalar ssr, real scalar n, real scalar k)
{
    real scalar pen
    pen = (ic == 1 ? 2 : (ic == 2 ? ln(n) : 2 * ln(ln(n))))
    return(ln(ssr / n) + pen * k / n)
}

// lag orders (p, q) minimising the information criterion over p = 1..maxp,
// q = 1..maxq on a common estimation sample: pooled within regression for DFE,
// average of the unit-specific criteria for MG, PMG and CS-ARDL
real rowvector _xp_icsel(real scalar est, real colvector y, real matrix X, real colvector tt,
    real scalar N, real scalar T, real scalar ic, real scalar maxp, real scalar maxq)
{
    real matrix Rmax, Rg, Rgi, Xi, Xt
    real colvector dep, vmax, ok, idx, depi, b, e, yt
    real scalar p, q, i, a, z, best, val, nu, kc, bp, bq, nobs, nuv
    dep  = (est == 9 ? y : _xp_diff(y, tt))
    Rmax = _xp_ardlrg(est, y, X, tt, N, T, maxp, maxq)
    vmax = _xp_ok((dep, Rmax))
    ok = J(N, 1, 0)
    for (i = 1; i <= N; i++) {
        a = (i - 1) * T + 1
        z = i * T
        if (sum(vmax[|a \ z|]) >= cols(Rmax) + 3) ok[i] = 1
    }
    if (sum(ok) == 0) return((1, 1))
    best = .
    bp = 1
    bq = 1
    for (p = 1; p <= maxp; p++) {
        for (q = 1; q <= maxq; q++) {
            Rg = _xp_ardlrg(est, y, X, tt, N, T, p, q)
            kc = cols(Rg) + 1
            if (est == 4) {
                yt = _xp_z0(_xp_within(dep, vmax, N, T))
                Xt = _xp_z0(_xp_within(Rg, vmax, N, T))
                b  = invsym(cross(Xt, Xt)) * cross(Xt, yt)
                e  = yt - Xt * b
                nobs = sum(vmax)
                nuv  = sum(rowsum(colshape(vmax, T)) :> 0)
                val  = _xp_ic(ic, cross(e, e), nobs, cols(Rg) + nuv)
            }
            else {
                val = 0
                nu = 0
                for (i = 1; i <= N; i++) {
                    if (ok[i] == 0) continue
                    a = (i - 1) * T + 1
                    z = i * T
                    idx  = selectindex(vmax[|a \ z|])
                    Rgi  = Rg[|a, 1 \ z, cols(Rg)|]
                    depi = dep[|a \ z|]
                    Xi = (J(rows(idx), 1, 1), Rgi[idx, .])
                    b  = invsym(cross(Xi, Xi)) * cross(Xi, depi[idx])
                    e  = depi[idx] - Xi * b
                    val = val + _xp_ic(ic, cross(e, e), rows(idx), kc)
                    nu++
                }
                val = val / nu
            }
            if (best >= . | val < best) {
                best = val
                bp = p
                bq = q
            }
        }
    }
    return((bp, bq))
}

// ======================================================= dynamic FE (ECM)
void _xp_dfe(real colvector y, real matrix X, real colvector tt, real scalar N,
    real scalar T, real scalar tfe, real scalar p, real scalar q, real matrix R,
    real matrix IF, real matrix res)
{
    real matrix Rg, XX, Xt, Ai, IFb, Jg
    real colvector dy, v, yt, b, e, beta
    real scalar k, phi
    k  = cols(X)
    dy = _xp_diff(y, tt)
    Rg = _xp_ardlrg(4, y, X, tt, N, T, p, q)
    XX = (tfe ? (Rg, _xp_tdum(tt, T)) : Rg)
    v  = _xp_ok((dy, XX))
    yt = _xp_z0(_xp_within(dy, v, N, T))
    Xt = _xp_z0(_xp_within(XX, v, N, T))
    Ai = invsym(cross(Xt, Xt))
    b  = Ai * cross(Xt, yt)
    e  = yt - Xt * b
    IFb = (Xt :* e) * Ai
    phi = b[1]
    beta = b[2..(k + 1)]
    R  = (-beta / phi) \ phi
    Jg = J(k + 1, rows(b), 0)
    Jg[1..k, 1] = beta / phi^2
    Jg[1..k, 2..(k + 1)] = -I(k) / phi
    Jg[k + 1, 1] = 1
    IF = IFb * Jg'
    res = _xp_setmiss(e, v)
}

// ======================================================= short-run coefficients
// Error-correction form of each ARDL(p,q) equation:
//   ec (speed of adjustment), D.x ... L(q-1)D.x for every regressor (lag by lag),
//   LD.y ... L(p-1)D.y, and _cons (MG, PMG, CS-ARDL).
// DFE: pooled within estimates, standard errors clustered by unit.
// MG, PMG, CS-ARDL: averages of unit estimates with mean-group standard errors
// (PMG: unit regressions given the pooled long-run coefficients; CS-ARDL: unit
// levels coefficients converted to the error-correction form).
real matrix _xp_sr(real scalar est, real colvector y, real matrix X, real colvector tt,
    real scalar N, real scalar T, real scalar p, real scalar q, real scalar tfe)
{
    real matrix Rg, XX, Xt, Ai, IFb, Gc, V, Si, Rgi, Xi, Xl, W, Wi, Xli, Rq, IFq, rq
    real colvector dep, v, yt, b, e, idx, depi, ok, sr, lam, th, ecv, dyi
    real scalar k, kw, i, a, z, j, l, Nv, nsr, nmin
    k  = cols(X)
    W  = _xp_srun(y, X, tt, p, q)
    kw = cols(W)
    nsr = 1 + kw + (est != 4)
    if (est == 4) {
        dep = _xp_diff(y, tt)
        Rg  = _xp_ardlrg(4, y, X, tt, N, T, p, q)
        XX  = (tfe ? (Rg, _xp_tdum(tt, T)) : Rg)
        v   = _xp_ok((dep, XX))
        yt  = _xp_z0(_xp_within(dep, v, N, T))
        Xt  = _xp_z0(_xp_within(XX, v, N, T))
        Ai  = invsym(cross(Xt, Xt))
        b   = Ai * cross(Xt, yt)
        e   = yt - Xt * b
        IFb = (Xt :* e) * Ai
        Gc  = J(N, cols(Xt), 0)
        Nv  = 0
        for (i = 1; i <= N; i++) {
            a = (i - 1) * T + 1
            z = i * T
            Gc[i, .] = colsum(IFb[|a, 1 \ z, cols(Xt)|])
            if (sum(v[|a \ z|]) > 0) Nv++
        }
        V  = cross(Gc, Gc) * Nv / (Nv - 1)
        idx = (1 \ ((k + 2)::(k + 1 + kw)))
        e = diagonal(V)
        return((b[idx], sqrt(e[idx])))
    }
    Si = J(N, nsr, .)
    ok = J(N, 1, 0)
    if (est == 6) {
        _xp_pmg(y, X, tt, N, T, p, q, Rq, IFq, rq)
        th  = Rq[1..k]
        dep = _xp_diff(y, tt)
        Xl  = _xp_lag(X, 1, tt)
        ecv = _xp_lag(y, 1, tt) - Xl * th
        Rg  = (ecv, W)
        nmin = kw + k + 4
    }
    else {
        dep = (est == 9 ? y : _xp_diff(y, tt))
        Rg  = _xp_ardlrg(est, y, X, tt, N, T, p, q)
        nmin = cols(Rg) + 3
    }
    v = _xp_ok((dep, Rg))
    for (i = 1; i <= N; i++) {
        a = (i - 1) * T + 1
        z = i * T
        idx = selectindex(v[|a \ z|])
        if (rows(idx) < nmin) continue
        Rgi  = Rg[|a, 1 \ z, cols(Rg)|]
        depi = dep[|a \ z|]
        Xi = (J(rows(idx), 1, 1), Rgi[idx, .])
        b  = invsym(cross(Xi, Xi)) * cross(Xi, depi[idx])
        if (est == 5) sr = (b[2] \ b[(k + 3)..(k + 2 + kw)] \ b[1])
        else if (est == 6) sr = (b[2] \ b[3..(2 + kw)] \ b[1])
        else {
            // levels: b = (c, lambda_1..lambda_p, x_t (k), ..., x_t-q (k), averages)
            lam = b[2..(p + 1)]
            sr = sum(lam) - 1
            for (j = 0; j <= q - 1; j++) {
                if (j == 0) sr = sr \ b[(p + 2)..(p + 1 + k)]
                else {
                    e = J(k, 1, 0)
                    for (l = j + 1; l <= q; l++) e = e + b[(p + 2 + l * k)..(p + 1 + (l + 1) * k)]
                    sr = sr \ (-e)
                }
            }
            for (j = 1; j <= p - 1; j++) sr = sr \ (-sum(lam[(j + 1)..p]))
            sr = sr \ b[1]
        }
        Si[i, .] = sr'
        ok[i] = 1
    }
    Si = select(Si, ok)
    Nv = rows(Si)
    if (Nv < 2) return(J(nsr, 2, .))
    return((mean(Si)', sqrt(diagonal(variance(Si)) / Nv)))
}

// ======================================================= mean-group family
void _xp_mgcomb(real matrix Ri, real colvector ok, real scalar N, real scalar T,
    real matrix R, real matrix IF)
{
    real matrix IFu
    real colvector s
    real scalar Nv
    s  = selectindex(ok)
    Nv = rows(s)
    R  = (colsum(Ri[s, .]) / Nv)'
    IFu = J(N, cols(Ri), 0)
    IFu[s, .] = (Ri[s, .] :- R') / Nv
    IF = (IFu # J(T, 1, 1)) / T
}

real matrix _xp_csa(real colvector y, real matrix X, real scalar N, real scalar T)
{
    return(_xp_pmean((y, X), _xp_ok((y, X)), N, T))
}

// type: 1 = MG-ECM, 2 = CCEMG, 3 = CS-ARDL
void _xp_mgfam(real scalar type, real colvector y, real matrix X, real colvector tt,
    real scalar N, real scalar T, real scalar p, real scalar q, real matrix R,
    real matrix IF, real matrix res)
{
    real matrix Rg, Ri, Rgi, Xi
    real colvector dep, v, ok, vi, idx, depi, b, ri, bx
    real scalar k, i, l, kR, lam, a, z
    k = cols(X)
    if (type == 1) {
        dep = _xp_diff(y, tt)
        Rg  = _xp_ardlrg(5, y, X, tt, N, T, p, q)
        kR  = k + 1
    }
    else if (type == 2) {
        dep = y
        Rg  = (X, _xp_csa(y, X, N, T))
        kR  = k
    }
    else {
        dep = y
        Rg  = _xp_ardlrg(9, y, X, tt, N, T, p, q)
        kR  = k + 1
    }
    v  = _xp_ok((dep, Rg))
    Ri = J(N, kR, .)
    ok = J(N, 1, 0)
    res = J(rows(y), 1, .)
    for (i = 1; i <= N; i++) {
        a = (i - 1) * T + 1
        z = i * T
        vi = v[|a \ z|]
        idx = selectindex(vi)
        if (rows(idx) < cols(Rg) + 3) continue
        Rgi = Rg[|a, 1 \ z, cols(Rg)|]
        depi = dep[|a \ z|]
        Xi = (J(rows(idx), 1, 1), Rgi[idx, .])
        b = invsym(cross(Xi, Xi)) * cross(Xi, depi[idx])
        if (type == 1) Ri[i, .] = ((-b[3..(k + 2)] / b[2]) \ b[2])'
        else if (type == 2) Ri[i, .] = b[2..(k + 1)]'
        else {
            lam = sum(b[2..(p + 1)])
            bx = J(k, 1, 0)
            for (l = 0; l <= q; l++) bx = bx + b[(p + 2 + l * k)..(p + 1 + (l + 1) * k)]
            Ri[i, .] = ((bx / (1 - lam)) \ (lam - 1))'
        }
        ok[i] = 1
        ri = J(T, 1, .)
        ri[idx] = depi[idx] - Xi * b
        res[|a \ z|] = ri
    }
    _xp_mgcomb(Ri, ok, N, T, R, IF)
}

// ======================================================= CCE pooled
void _xp_ccep(real colvector y, real matrix X, real colvector tt, real scalar N,
    real scalar T, real matrix R, real matrix IF, real matrix res)
{
    real matrix Zb, Xt, H, Mi, Xb, Zi, Ai
    real colvector v, vv, yt, idx, b, e, yi
    real scalar k, i, a, z
    k  = cols(X)
    Zb = _xp_csa(y, X, N, T)
    v  = _xp_ok((y, X, Zb))
    vv = v
    yt = J(rows(y), 1, 0)
    Xt = J(rows(y), k, 0)
    for (i = 1; i <= N; i++) {
        a = (i - 1) * T + 1
        z = i * T
        idx = selectindex(v[|a \ z|])
        if (rows(idx) < cols(Zb) + 3) {
            vv[|a \ z|] = J(T, 1, 0)
            continue
        }
        Zi = Zb[|a, 1 \ z, cols(Zb)|]
        H  = (J(rows(idx), 1, 1), Zi[idx, .])
        Mi = I(rows(idx)) - H * invsym(cross(H, H)) * H'
        yi = y[|a \ z|]
        Xb = X[|a, 1 \ z, k|]
        yt[(a - 1) :+ idx] = Mi * yi[idx]
        Xt[(a - 1) :+ idx, .] = Mi * Xb[idx, .]
    }
    Ai = invsym(cross(Xt, Xt))
    b  = Ai * cross(Xt, yt)
    e  = yt - Xt * b
    IF = (Xt :* e) * Ai
    R  = b
    res = _xp_setmiss(e, vv)
}

// ======================================================= PMG (Pesaran-Shin-Smith ML, back-substitution)
void _xp_pmg(real colvector y, real matrix X, real colvector tt, real scalar N,
    real scalar T, real scalar p, real scalar q, real matrix R, real matrix IF,
    real matrix res)
{
    real matrix Xl, W, Rtmp, IFtmp, rtmp, B, Wi, Hi, Xli, Bi, Wfull, Xlf
    real colvector dy, yl, v, units, th, thn, c, idx, dyi, yli, xi, hx, r, e, phis, ok
    real scalar k, i, it, a, z, phi, s2, Nv, pbar, u, nidx, kw
    k  = cols(X)
    dy = _xp_diff(y, tt)
    yl = _xp_lag(y, 1, tt)
    Xl = _xp_lag(X, 1, tt)
    W  = _xp_srun(y, X, tt, p, q)
    kw = cols(W)
    v  = _xp_ok((dy, yl, Xl, W))
    _xp_dfe(y, X, tt, N, T, 0, p, q, Rtmp, IFtmp, rtmp)
    th = Rtmp[1..k]
    units = J(0, 1, .)
    for (i = 1; i <= N; i++) {
        if (sum(v[|(i - 1) * T + 1 \ i * T|]) >= kw + k + 4) units = units \ i
    }
    for (it = 1; it <= 500; it++) {
        B = J(k, k, 0)
        c = J(k, 1, 0)
        for (u = 1; u <= rows(units); u++) {
            i = units[u]; a = (i - 1) * T + 1; z = i * T
            idx = selectindex(v[|a \ z|])
            dyi = dy[|a \ z|]; dyi = dyi[idx]
            yli = yl[|a \ z|]; yli = yli[idx]
            Xli = Xl[|a, 1 \ z, k|]; Xli = Xli[idx, .]
            Wi  = W[|a, 1 \ z, kw|]; Wi = (J(rows(idx), 1, 1), Wi[idx, .])
            Hi  = I(rows(idx)) - Wi * invsym(cross(Wi, Wi)) * Wi'
            xi  = yli - Xli * th
            hx  = Hi * xi
            phi = (hx' * (Hi * dyi)) / (hx' * hx)
            r   = Hi * dyi - phi * hx
            s2  = (r' * r) / rows(idx)
            B   = B + (phi^2 / s2) * (Xli' * Hi * Xli)
            c   = c + (phi / s2) * (Xli' * Hi * (dyi - phi * yli))
        }
        thn = -lusolve(B, c)
        if (max(abs(thn - th)) < 1e-9) {
            th = thn
            break
        }
        th = thn
    }
    Bi = invsym(B)
    IF = J(rows(y), k + 1, 0)
    res = J(rows(y), 1, .)
    phis = J(N, 1, .)
    ok = J(N, 1, 0)
    for (u = 1; u <= rows(units); u++) {
        i = units[u]; a = (i - 1) * T + 1; z = i * T
        idx = selectindex(v[|a \ z|])
        dyi = dy[|a \ z|]; dyi = dyi[idx]
        yli = yl[|a \ z|]; yli = yli[idx]
        Xli = Xl[|a, 1 \ z, k|]; Xli = Xli[idx, .]
        Wi  = W[|a, 1 \ z, kw|]; Wi = (J(rows(idx), 1, 1), Wi[idx, .])
        Hi  = I(rows(idx)) - Wi * invsym(cross(Wi, Wi)) * Wi'
        xi  = yli - Xli * th
        hx  = Hi * xi
        phi = (hx' * (Hi * dyi)) / (hx' * hx)
        e   = Hi * dyi - phi * hx
        s2  = (e' * e) / rows(idx)
        IF[(a - 1) :+ idx, 1..k] = -(phi / s2) * ((Hi * Xli) :* e) * Bi
        res[(a - 1) :+ idx] = e
        phis[i] = phi
        ok[i] = 1
    }
    Nv = sum(ok)
    pbar = sum(editmissing(phis, 0)) / Nv
    for (u = 1; u <= rows(units); u++) {
        i = units[u]; a = (i - 1) * T + 1; z = i * T
        idx = selectindex(v[|a \ z|])
        IF[(a - 1) :+ idx, k + 1] = J(rows(idx), 1, (phis[i] - pbar) / Nv / rows(idx))
    }
    R = th \ pbar
}

// ======================================================= DML-GMM (Wu & Xiao 2026), k mediators
real matrix _xp_dmdm(real matrix A, real colvector ra, real colvector rs, real scalar T)
{
    real matrix out, S, X
    real scalar c
    out = J(rows(ra), cols(A), .)
    for (c = 1; c <= cols(A); c++) {
        S = colshape(A[rs, c], T)
        X = colshape(A[ra, c], T) :- (colsum(S) :/ colnonmissing(S))
        out[., c] = colshape(X, 1)
    }
    return(out)
}

real matrix _xp_inst(real colvector U, real scalar nl, real scalar sq, real colvector tt)
{
    real matrix Z
    real scalar j
    Z = J(rows(U), 0, .)
    for (j = 1; j <= nl; j++) {
        Ul = _xp_lag(U, j, tt)
        Z = (Z, Ul)
        if (sq) Z = (Z, Ul:^2)
    }
    return(editmissing(Z, 0))
}

real colvector _xp_tsls(real colvector y, real matrix X, real matrix Z)
{
    real matrix ZX, W
    ZX = cross(Z, X)
    W  = invsym(cross(Z, Z))
    return(invsym(ZX' * W * ZX) * (ZX' * W * cross(Z, y)))
}

real colvector _xp_ridge(real colvector y, real matrix X, real scalar lam)
{
    real matrix XX
    XX = cross(X, X)
    if (lam > 0) XX = XX + lam * rows(X) * I(cols(X))
    return(invsym(XX) * cross(X, y))
}

real matrix _xp_poly(real matrix X, real scalar deg)
{
    real matrix Z, P, Xv
    real scalar p, i, j, k
    p = cols(X)
    if (p == 0) return(J(rows(X), 0, .))
    Xv = select(X, _xp_ok(X))
    mu = mean(Xv)
    sd = sqrt(diagonal(variance(Xv)))'
    sd = sd + (sd :== 0)
    Z = (X :- mu) :/ sd
    P = Z
    if (deg >= 2) {
        for (i = 1; i <= p; i++) {
            for (j = i; j <= p; j++) P = (P, Z[., i] :* Z[., j])
        }
    }
    if (deg >= 3) {
        for (i = 1; i <= p; i++) {
            for (j = i; j <= p; j++) {
                for (k = j; k <= p; k++) P = (P, Z[., i] :* Z[., j] :* Z[., k])
            }
        }
    }
    return(P)
}

real matrix _xp_expand(real matrix Z, real colvector tt, real scalar t0, real scalar T)
{
    real matrix out
    real scalar q, s
    q = cols(Z)
    out = J(rows(Z), q * (T - t0 + 1), 0)
    for (s = t0; s <= T; s++) {
        r = selectindex(tt :== s)
        if (rows(r)) out[r, ((s - t0) * q + 1)..((s - t0 + 1) * q)] = Z[r, .]
    }
    return(out)
}

real matrix _xp_rowmom(real colvector b, real matrix ZY, real matrix XY, real colvector yY,
    real matrix ZMg, real matrix XMg, real matrix yMg, real matrix vM, real scalar kY,
    real scalar kM, real scalar km)
{
    real matrix out, ZMj
    real scalar j
    out = ZY :* (yY - XY * b[1..kY])
    for (j = 1; j <= km; j++) {
        ZMj = ZMg :* vM[., j]
        out = (out, ZMj :* (yMg[., j] - (XMg :* vM[., j]) * b[(kY + (j - 1) * kM + 1)..(kY + j * kM)]))
    }
    return(out)
}

real matrix _xp_usum(real matrix A, real scalar T)
{
    real matrix G
    real scalar c
    G = J(rows(A) / T, cols(A), .)
    for (c = 1; c <= cols(A); c++) G[., c] = rowsum(colshape(A[., c], T))
    return(G)
}

void _xp_dml(real colvector Y, real colvector D, real matrix Mm, real matrix P,
    real scalar N, real scalar T, real scalar L, real scalar Jl, real scalar K,
    real scalar dsq, real scalar twostep, real scalar collapse, real scalar lam,
    real matrix R, real matrix IF, real matrix res, real matrix info, real matrix XA)
{
    real scalar km, kP, n, t0, kM, kY, qD, k, kp, j, l
    km = cols(Mm); kP = cols(P); n = N * T
    tt = J(N, 1, (1::T))
    t0 = L + 3

    tauM = J(n, 0, .)
    for (l = 0; l <= L; l++) tauM = (tauM, _xp_lag(D, l, tt))
    if (dsq) tauM = (tauM, D:^2)
    tauY = tauM[., 1..(L + 1)]
    for (j = 1; j <= km; j++) {
        for (l = 0; l <= L; l++) tauY = (tauY, _xp_lag(Mm[., j], l, tt))
    }
    if (dsq) tauY = (tauY, D:^2)
    kM = cols(tauM); kY = cols(tauY)

    dD = _xp_diff(D, tt); dY = _xp_diff(Y, tt); dMm = _xp_diff(Mm, tt)
    dP = _xp_diff(P, tt); dtM = _xp_diff(tauM, tt); dtY = _xp_diff(tauY, tt)

    perm = order(runiform(N, 1), 1)
    fold = J(N, 1, .)
    fold[perm] = mod((1::N) :- 1, K) :+ 1

    qD = Jl * (1 + dsq)
    yYg = J(n, 1, 0); XYg = J(n, kY, 0); ZYg = J(n, qD + Jl * km, 0)
    yMg = J(n, km, 0); XMg = J(n, kM, 0); ZMg = J(n, qD, 0)
    vY = J(n, 1, 0); vM = J(n, km, 0)

    for (k = 1; k <= K; k++) {
        kp  = (k < K ? k + 1 : 1)
        Fk  = selectindex(fold :== k)
        Fkp = selectindex(fold :== kp)
        S   = selectindex((fold :!= k) :& (fold :!= kp))
        rS  = _xp_rows(S, T); rk = _xp_rows(Fk, T); rkp = _xp_rows(Fkp, T)
        ttS = tt[rS]; ttk = tt[rk]

        // ---- training folds ----
        dDS = _xp_dmdm(dD, rS, rS, T); dYS = _xp_dmdm(dY, rS, rS, T)
        dMS = _xp_dmdm(dMm, rS, rS, T); dPS = _xp_dmdm(dP, rS, rS, T)
        dtMS = _xp_dmdm(dtM, rS, rS, T); dtYS = _xp_dmdm(dtY, rS, rS, T)

        if (kP) {
            s  = selectindex((ttS :>= 2) :& _xp_ok((dDS, dPS)))
            bh = _xp_ridge(dDS[s], dPS[s, .], lam)
            UDS = dDS - dPS * bh
        }
        else {
            bh = J(0, 1, .)
            UDS = dDS
        }
        ZD = _xp_inst(UDS, Jl, dsq, ttS)
        GAM = J(kM, km, .)
        BG  = J(kP, km, .)
        ZMl = J(rows(ttS), 0, .)
        for (j = 1; j <= km; j++) {
            e  = selectindex((ttS :>= t0) :& _xp_ok((dMS[., j], dtMS, dPS)))
            if (kP) bm = _xp_tsls(dMS[e, j], (dtMS[e, .], dPS[e, .]), (dPS[e, .], ZD[e, .]))
            else    bm = _xp_tsls(dMS[e, j], dtMS[e, .], ZD[e, .])
            GAM[., j] = bm[1..kM]
            if (kP) BG[., j] = bm[(kM + 1)..(kM + kP)]
            U = dMS[., j] - dtMS * GAM[., j]
            if (kP) U = U - dPS * BG[., j]
            sel = selectindex(ttS :< L + 2)
            if (rows(sel)) U[sel] = J(rows(sel), 1, .)
            ZMl = (ZMl, _xp_inst(U, Jl, 0, ttS))
        }
        if (kP) {
            e  = selectindex((ttS :>= t0) :& _xp_ok((dYS, dtYS, dPS)))
            bY = _xp_tsls(dYS[e], (dtYS[e, .], dPS[e, .]), (dPS[e, .], ZD[e, .], ZMl[e, .]))
            bf = bY[(kY + 1)..(kY + kP)]
        }
        else bf = J(0, 1, .)

        // ---- estimation fold (auxiliary-fold period demeaning) ----
        dDk = _xp_dmdm(dD, rk, rkp, T); dYk = _xp_dmdm(dY, rk, rkp, T)
        dMk = _xp_dmdm(dMm, rk, rkp, T); dPk = _xp_dmdm(dP, rk, rkp, T)
        dtMk = _xp_dmdm(dtM, rk, rkp, T); dtYk = _xp_dmdm(dtY, rk, rkp, T)
        UDk = dDk
        if (kP) UDk = UDk - dPk * bh
        ZDk = _xp_inst(UDk, Jl, dsq, ttk)
        ZMk = J(rows(ttk), 0, .)
        for (j = 1; j <= km; j++) {
            U = dMk[., j] - dtMk * GAM[., j]
            yj = dMk[., j]
            if (kP) {
                U  = U - dPk * BG[., j]
                yj = yj - dPk * BG[., j]
            }
            sel = selectindex(ttk :< L + 2)
            if (rows(sel)) U[sel] = J(rows(sel), 1, .)
            ZMk = (ZMk, _xp_inst(U, Jl, 0, ttk))
            vj = selectindex((ttk :>= t0) :& _xp_ok((yj, dtMk)))
            if (rows(vj)) {
                yMg[rk[vj], j] = yj[vj]
                vM[rk[vj], j] = J(rows(vj), 1, 1)
            }
        }
        va = selectindex((ttk :>= t0) :& _xp_ok(dtMk))
        if (rows(va)) XMg[rk[va], .] = dtMk[va, .]
        ZMg[rk, .] = ZDk
        yy = dYk
        if (kP) yy = yy - dPk * bf
        vy = selectindex((ttk :>= t0) :& _xp_ok((yy, dtYk)))
        if (rows(vy)) {
            yYg[rk[vy]] = yy[vy]
            XYg[rk[vy], .] = dtYk[vy, .]
            vY[rk[vy]] = J(rows(vy), 1, 1)
        }
        ZYg[rk, .] = (ZDk, ZMk)
    }
    if (!collapse) {
        ZYg = _xp_expand(ZYg, tt, t0, T)
        ZMg = _xp_expand(ZMg, tt, t0, T)
    }
    ZY = ZYg :* vY; XY = XYg :* vY; yY = yYg :* vY
    yMg = yMg :* vM

    G  = cross(ZY, XY)
    g0 = cross(ZY, yY)
    Om = invsym(cross(ZY, ZY) / N)
    for (j = 1; j <= km; j++) {
        ZMj = ZMg :* vM[., j]
        XMj = XMg :* vM[., j]
        G  = blockdiag(G, cross(ZMj, XMj))
        g0 = g0 \ cross(ZMj, yMg[., j])
        Om = blockdiag(Om, invsym(cross(ZMj, ZMj) / N))
    }
    G = G / N
    g0 = g0 / N
    b = invsym(G' * Om * G) * (G' * Om * g0)
    if (twostep) {
        ps = _xp_usum(_xp_rowmom(b, ZY, XY, yY, ZMg, XMg, yMg, vM, kY, kM, km), T)
        ps = ps :- mean(ps)
        Om = invsym(cross(ps, ps) / N)
        b  = invsym(G' * Om * G) * (G' * Om * g0)
    }
    mr = _xp_rowmom(b, ZY, XY, yY, ZMg, XMg, yMg, vM, kY, kM, km)
    ps = _xp_usum(mr, T)
    pbar = mean(ps)'
    psc = ps :- pbar'
    Sm = cross(psc, psc) / N
    A  = invsym(G' * Om * G) * G' * Om
    IF = -(mr * A') / N
    Jst = N * pbar' * invsym(Sm) * pbar
    Jdf = rows(G) - cols(G)
    res = _xp_setmiss(yY - XY * b[1..kY], vY)
    for (j = 1; j <= km; j++) {
        rj = yMg[., j] - (XMg :* vM[., j]) * b[(kY + (j - 1) * kM + 1)..(kY + j * kM)]
        res = (res, _xp_setmiss(rj, vM[., j]))
    }
    R = b
    info = (kY, kM, Jst, Jdf)
    XA = XY
    for (j = 1; j <= km; j++) XA = (XA, XMg :* vM[., j])
}

// ======================================================= dispatcher
// est: 1 dml 2 fe 3 re 4 dfe 5 mg 6 pmg 7 ccep 8 ccemg 9 csardl
void _xp_est(real scalar est, real colvector Y, real colvector D, real matrix Mm,
    real matrix X, real matrix P, real scalar N, real scalar T, real matrix opt,
    real matrix R, real matrix IF, real matrix res, real matrix info, real matrix XA)
{
    real scalar km, q, tfe, pl, ql
    real matrix Xq, Rq, IFq, rq
    real colvector y, tt
    km = cols(Mm)
    tt = J(N, 1, (1::T))
    if (est == 1) {
        // opt: L, J, K, dsq, twostep, collapse, ridge, tfe
        _xp_dml(Y, D, Mm, P, N, T, opt[1], opt[2], opt[3], opt[4], opt[5], opt[6], opt[7], R, IF, res, info, XA)
        return
    }
    tfe = opt[8]
    XA = J(rows(Y), 0, .)
    R = J(0, 1, .); IF = J(rows(Y), 0, .); res = J(rows(Y), 0, .)
    info = J(1, 0, .)
    for (q = 0; q <= km; q++) {
        if (q == 0) {
            y = Y
            Xq = (D, Mm, X)
        }
        else {
            y = Mm[., q]
            Xq = (D, X)
        }
        info = (info, rows(R) + 1)
        pl = (cols(opt) >= 10 + 2 * q ? opt[9 + 2 * q] : 1)
        ql = (cols(opt) >= 10 + 2 * q ? opt[10 + 2 * q] : 1)
        if (est == 2)      _xp_fe(y, Xq, tt, N, T, tfe, Rq, IFq, rq)
        else if (est == 3) _xp_re(y, Xq, tt, N, T, tfe, Rq, IFq, rq)
        else if (est == 4) _xp_dfe(y, Xq, tt, N, T, tfe, pl, ql, Rq, IFq, rq)
        else if (est == 5) _xp_mgfam(1, y, Xq, tt, N, T, pl, ql, Rq, IFq, rq)
        else if (est == 6) _xp_pmg(y, Xq, tt, N, T, pl, ql, Rq, IFq, rq)
        else if (est == 7) _xp_ccep(y, Xq, tt, N, T, Rq, IFq, rq)
        else if (est == 8) _xp_mgfam(2, y, Xq, tt, N, T, 1, 1, Rq, IFq, rq)
        else               _xp_mgfam(3, y, Xq, tt, N, T, pl, ql, Rq, IFq, rq)
        R = R \ Rq
        IF = (IF, IFq)
        res = (res, rq)
    }
}

// ======================================================= effects
real rowvector _xp_eff(real colvector R, real scalar est, real matrix info,
    real scalar km, real scalar L, real scalar dsq, real scalar d1, real scalar d0)
{
    real scalar dl, sq, kY, kM, j, thsq, gsq, nde, nde0, nie, nie0, c
    real rowvector nies, nies0, out
    real colvector th, ga, thM
    dl = d1 - d0
    sq = d1^2 - d0^2
    nies = J(1, km, .)
    if (est == 1) {
        kY = info[1]; kM = info[2]
        th = R[1..kY]
        thsq = (dsq ? th[kY] : 0)
        nde  = sum(th[1..(L + 1)]) * dl + thsq * sq
        nde0 = th[1] * dl + thsq * sq
        nies0 = J(1, km, .)
        for (j = 1; j <= km; j++) {
            ga  = R[(kY + (j - 1) * kM + 1)..(kY + j * kM)]
            gsq = (dsq ? ga[kM] : 0)
            thM = th[((L + 1) * j + 1)..((L + 1) * (j + 1))]
            nies[j]  = sum(thM) * (sum(ga[1..(L + 1)]) * dl + gsq * sq)
            nies0[j] = thM[1] * (ga[1] * dl + gsq * sq)
        }
        nie = sum(nies); nie0 = sum(nies0)
        out = (nde, nie, nde + nie, nie / (nde + nie))
        if (km > 1) out = (out, nies)
        return((out, nde0, nie0, nde0 + nie0))
    }
    c = R[info[1]]
    for (j = 1; j <= km; j++) nies[j] = R[info[1] + j] * R[info[1 + j]] * dl
    nde = c * dl
    nie = sum(nies)
    out = (nde, nie, nde + nie, nie / (nde + nie))
    if (km > 1) out = (out, nies)
    return(out)
}

real matrix _xp_effjac(real colvector R, real scalar est, real matrix info,
    real scalar km, real scalar L, real scalar dsq, real scalar d1, real scalar d0)
{
    real matrix Jm
    real colvector Rp, Rm
    real scalar j, h, ne
    ne = cols(_xp_eff(R, est, info, km, L, dsq, d1, d0))
    Jm = J(ne, rows(R), 0)
    for (j = 1; j <= rows(R); j++) {
        h = 1e-6 * max((1, abs(R[j])))
        Rp = R; Rp[j] = Rp[j] + h
        Rm = R; Rm[j] = Rm[j] - h
        Jm[., j] = ((_xp_eff(Rp, est, info, km, L, dsq, d1, d0) - _xp_eff(Rm, est, info, km, L, dsq, d1, d0)) / (2 * h))'
    }
    return(Jm)
}

real scalar _xp_med(real colvector x)
{
    real colvector s
    real scalar n
    s = sort(x, 1)
    n = rows(s)
    return(mod(n, 2) ? s[(n + 1) / 2] : (s[n / 2] + s[n / 2 + 1]) / 2)
}

// estimate (with repeated splits for DML) and joint variance
void _xp_fitV(real scalar est, real colvector Y, real colvector D, real matrix Mm,
    real matrix X, real matrix P, real scalar N, real scalar T, real matrix opt,
    real scalar reps, real scalar dk, real scalar m, real matrix R, real matrix V,
    real matrix res, real matrix info, real matrix IF, real matrix XA)
{
    real matrix B, Vs, Vr, Vagg, Rr, IFr, rr, infr, XAr
    real colvector Js, d
    real scalar r, i, j, k
    _xp_est(est, Y, D, Mm, X, P, N, T, opt, R, IF, res, info, XA)
    V = _xp_vce(IF, N, T, dk, m)
    if (est != 1 | reps == 1) {
        V = (V + V') / 2
        return
    }
    k  = rows(R)
    B  = J(k, reps, .); Vs = J(k * k, reps, .); Js = J(reps, 1, .)
    B[., 1] = R; Vs[., 1] = vec(V); Js[1] = info[3]
    for (r = 2; r <= reps; r++) {
        _xp_est(est, Y, D, Mm, X, P, N, T, opt, Rr, IFr, rr, infr, XAr)
        Vr = _xp_vce(IFr, N, T, dk, m)
        B[., r] = Rr; Vs[., r] = vec(Vr); Js[r] = infr[3]
    }
    for (i = 1; i <= k; i++) R[i] = _xp_med(B[i, .]')
    for (r = 1; r <= reps; r++) {
        d = B[., r] - R
        Vs[., r] = Vs[., r] + vec(d * d')
    }
    Vagg = J(k, k, .)
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= k; j++) Vagg[i, j] = _xp_med(Vs[(j - 1) * k + i, .]')
    }
    V = (Vagg + Vagg') / 2
    info[3] = _xp_med(Js)
}

// ======================================================= diagnostics
real rowvector _xp_wooldridge(real colvector e, real colvector tt, real scalar N, real scalar T)
{
    real colvector de, dl, v, x, y, u, g
    real scalar rho, Ng, var, F
    de = _xp_diff(e, tt)
    dl = _xp_lag(de, 1, tt)
    v  = _xp_ok((de, dl))
    x  = _xp_z0(_xp_setmiss(dl, v))
    y  = _xp_z0(_xp_setmiss(de, v))
    rho = cross(x, y) / cross(x, x)
    u  = y - rho * x
    g  = rowsum(colshape(x :* u, T))
    Ng = sum(rowsum(colshape(v, T)) :> 0)
    var = cross(g, g) / cross(x, x)^2 * Ng / (Ng - 1)
    F = (rho + 0.5)^2 / var
    return((F, 1, Ng - 1, Ftail(1, Ng - 1, F)))
}

real rowvector _xp_abar(real colvector u, real colvector tt, real scalar N, real scalar T, real scalar j)
{
    real colvector ul, p, s
    real scalar z
    ul = _xp_lag(u, j, tt)
    p  = _xp_z0(u :* ul)
    s  = rowsum(colshape(p, T))
    z  = sum(s) / sqrt(cross(s, s))
    return((z, ., ., 2 * normal(-abs(z))))
}

// Arellano-Bond m_j with the estimation-effect correction (influence-function form)
real rowvector _xp_abarc(real colvector u, real matrix X, real matrix IFq, real colvector tt,
    real scalar N, real scalar T, real scalar j)
{
    real colvector ul, ok, u0, u1, si, ci, g
    real matrix Xl, X0, X1, IFi
    real scalar c, z
    ul = _xp_lag(u, j, tt)
    ok = (u :< .) :& (ul :< .)
    u0 = _xp_z0(u) :* ok
    u1 = _xp_z0(ul) :* ok
    Xl = _xp_lag(X, j, tt)
    X0 = _xp_z0(X) :* ok
    X1 = _xp_z0(Xl) :* ok
    si = rowsum(colshape(u0 :* u1, T))
    g  = -colsum(X0 :* u1 + u0 :* X1)'
    IFi = J(N, cols(IFq), .)
    for (c = 1; c <= cols(IFq); c++) IFi[., c] = rowsum(colshape(_xp_z0(IFq[., c]), T))
    ci = si + IFi * g
    z  = sum(si) / sqrt(cross(ci, ci))
    return((z, ., ., 2 * normal(-abs(z))))
}

real rowvector _xp_modwald(real colvector e, real scalar N, real scalar T)
{
    real matrix E
    real colvector ei
    real scalar W, df, s2, i, Ti, si, Vi
    E  = colshape(e, T)
    s2 = sum(_xp_z0(e:^2)) / sum(e :< .)
    W = 0; df = 0
    for (i = 1; i <= N; i++) {
        ei = select(E[i, .]', E[i, .]' :< .)
        Ti = rows(ei)
        if (Ti < 2) continue
        si = mean(ei:^2)
        Vi = sum((ei:^2 :- si):^2) / (Ti * (Ti - 1))
        if (Vi > 0) {
            W = W + (si - s2)^2 / Vi
            df++
        }
    }
    return((W, df, ., chi2tail(df, W)))
}

real rowvector _xp_bf(real colvector e, real scalar N, real scalar T)
{
    real matrix E
    real colvector ei, z, zi, ni, zall
    real scalar i, G, n, zb, num, den
    E = colshape(e, T)
    zi = J(0, 1, .); ni = J(0, 1, .); zall = J(0, 1, .); den = 0
    for (i = 1; i <= N; i++) {
        ei = select(E[i, .]', E[i, .]' :< .)
        if (rows(ei) < 2) continue
        z  = abs(ei :- _xp_med(ei))
        zi = zi \ mean(z)
        ni = ni \ rows(ei)
        zall = zall \ z
        den = den + sum((z :- mean(z)):^2)
    }
    G = rows(zi); n = rows(zall)
    zb = mean(zall)
    num = sum(ni :* (zi :- zb):^2) / (G - 1)
    den = den / (n - G)
    return((num / den, G - 1, n - G, Ftail(G - 1, n - G, num / den)))
}

real rowvector _xp_koenker(real colvector e, real matrix Z)
{
    real matrix X
    real colvector v, y, b, r
    real scalar R2, LM
    v = _xp_ok((e, Z))
    s = selectindex(v)
    y = e[s]:^2
    X = (J(rows(s), 1, 1), Z[s, .])
    b = invsym(cross(X, X)) * cross(X, y)
    r = y - X * b
    R2 = 1 - cross(r, r) / sum((y :- mean(y)):^2)
    LM = rows(s) * R2
    return((LM, cols(Z), ., chi2tail(cols(Z), LM)))
}

// returns (CD, p, mean|rho|, LMbc, p)
real rowvector _xp_csd(real colvector e, real scalar N, real scalar T)
{
    real matrix E, Ok, Ej, m, Ei, di, dj
    real colvector Tij, mi, mj, rho, k
    real scalar i, S, Sa, SL, np, sT, CD, LM, Nn, Tb
    E  = colshape(e, T)
    Ok = (E :< .)
    S = 0; Sa = 0; SL = 0; np = 0; sT = 0
    for (i = 1; i < N; i++) {
        m   = Ok[i, .] :* Ok[(i + 1)..N, .]
        Tij = rowsum(m)
        Ei  = _xp_z0(J(N - i, 1, E[i, .])) :* m
        Ej  = _xp_z0(E[(i + 1)..N, .]) :* m
        mi  = rowsum(Ei) :/ Tij
        mj  = rowsum(Ej) :/ Tij
        di  = (Ei :- mi) :* m
        dj  = (Ej :- mj) :* m
        rho = rowsum(di :* dj) :/ sqrt(rowsum(di:^2) :* rowsum(dj:^2))
        k   = selectindex((Tij :>= 3) :& (rho :< .))
        if (rows(k)) {
            S  = S + sum(sqrt(Tij[k]) :* rho[k])
            Sa = Sa + sum(abs(rho[k]))
            SL = SL + sum(Tij[k] :* rho[k]:^2 :- 1)
            np = np + rows(k)
            sT = sT + sum(Tij[k])
        }
    }
    if (np == 0) return((., ., ., ., .))
    CD = S / sqrt(np)
    Tb = sT / np
    Nn = (1 + sqrt(1 + 8 * np)) / 2
    LM = SL / sqrt(2 * np) - Nn / (2 * (Tb - 1))
    return((CD, 2 * normal(-abs(CD)), Sa / np, LM, 2 * normal(-abs(LM))))
}

real rowvector _xp_jb(real colvector e)
{
    real colvector x, d
    real scalar n, m2, S, K, JB
    x = select(e, e :< .)
    n = rows(x)
    d = x :- mean(x)
    m2 = mean(d:^2)
    S = mean(d:^3) / m2^1.5
    K = mean(d:^4) / m2^2
    JB = n * (S^2 / 6 + (K - 3)^2 / 24)
    return((JB, chi2tail(2, JB), S, K))
}

// Pesaran-Yamagata (2008) on the static FE version: (delta, p, delta_adj, p)
real rowvector _xp_py(real colvector y, real matrix X, real scalar N, real scalar T)
{
    real matrix Xt, Xi, den, XiX
    real colvector v, yt, bfe, num, idx, yi, ei, bi, d, bw, s2l
    real scalar k, i, a, z, Ti, s2, St, Nn, Tb, dl, dadj, pass
    k = cols(X)
    v = _xp_ok((y, X))
    yt = _xp_within(y, v, N, T)
    Xt = _xp_within(X, v, N, T)
    bfe = invsym(cross(_xp_z0(Xt), _xp_z0(Xt))) * cross(_xp_z0(Xt), _xp_z0(yt))
    num = J(k, 1, 0); den = J(k, k, 0); s2l = J(N, 1, .)
    St = 0; Nn = 0; Tb = 0
    bw = J(k, 1, 0)
    for (pass = 1; pass <= 2; pass++) {
        for (i = 1; i <= N; i++) {
            a = (i - 1) * T + 1; z = i * T
            idx = selectindex(v[|a \ z|])
            Ti = rows(idx)
            if (Ti < k + 2) continue
            Xi = Xt[|a, 1 \ z, k|]; Xi = Xi[idx, .]
            yi = yt[|a \ z|]; yi = yi[idx]
            if (pass == 1) {
                ei = yi - Xi * bfe
                s2 = cross(ei, ei) / (Ti - 1)
                s2l[i] = s2
                num = num + cross(Xi, yi) / s2
                den = den + cross(Xi, Xi) / s2
            }
            else {
                XiX = cross(Xi, Xi)
                bi = invsym(XiX) * cross(Xi, yi)
                d = bi - bw
                St = St + d' * XiX * d / s2l[i]
                Nn++
                Tb = Tb + Ti
            }
        }
        if (pass == 1) bw = lusolve(den, num)
    }
    if (Nn < 2) return((., ., ., .))
    Tb = Tb / Nn
    dl = sqrt(Nn) * (St / Nn - k) / sqrt(2 * k)
    dadj = sqrt(Nn) * (St / Nn - k) / sqrt(2 * k * (Tb - k - 1) / (Tb + 1))
    return((dl, 2 * normal(-abs(dl)), dadj, 2 * normal(-abs(dadj))))
}

// key coefficient positions per equation (for the Chow-type test)
real matrix _xp_keys(real scalar est, real matrix info, real scalar km, real scalar kx, real scalar q)
{
    real scalar ecm, nk
    if (est == 1) {
        if (q == 0) return(1..info[1])
        return((info[1] + (q - 1) * info[2] + 1)..(info[1] + q * info[2]))
    }
    ecm = (est == 4 | est == 5 | est == 6 | est == 9)
    nk = (q == 0 ? 1 + km : 1)
    if (ecm) return((info[q + 1]..(info[q + 1] + nk - 1), info[q + 1] + nk + kx))
    return(info[q + 1]..(info[q + 1] + nk - 1))
}

void _xp_diagall(real scalar est, real colvector Y, real colvector D, real matrix Mm,
    real matrix X, real matrix P, real scalar N, real scalar T, real matrix opt,
    real scalar dk, real scalar m, real matrix R, real matrix V, real matrix res,
    real matrix info, real scalar brk, real matrix DG, real matrix CJ, real matrix IF,
    real matrix XA)
{
    real scalar km, kx, q, c0, fd, ecm, pos
    real colvector tt, e, w, y, dd
    real matrix Z, Rw, Vw, resw, infw, R1, V1, R2, V2, cs, keys, keyall
    km = cols(Mm); kx = cols(X)
    tt = J(N, 1, (1::T))
    fd = (est == 1)
    ecm = (est == 4 | est == 5 | est == 6 | est == 9)
    DG = J(16, 4 * (km + 1), .)
    CJ = J(1, 3, .)
    w  = 2 * (runiform(N, 1) :> .5) :- 1

    // Chow-type: estimate on t <= brk and t > brk
    R1 = .; R2 = .
    for (q = 1; q <= 2; q++) {
        if (q == 1) wm = (tt :<= brk)
        else        wm = (tt :> brk)
        Yw = _xp_setmiss(Y, wm); Dw = _xp_setmiss(D, wm)
        Mw = _xp_setmiss(Mm, wm); Xw = _xp_setmiss(X, wm); Pw = _xp_setmiss(P, wm)
        rc = _xp_trychow(est, Yw, Dw, Mw, Xw, Pw, N, T, opt, dk, m, Rw, Vw, infw)
        if (rc) {
            R1 = .; break
        }
        if (q == 1) {
            R1 = Rw; V1 = Vw
        }
        else {
            R2 = Rw; V2 = Vw
        }
    }

    keyall = J(1, 0, .)
    for (q = 0; q <= km; q++) {
        c0 = 4 * q
        e = res[., q + 1]
        if (fd) {
            if (q == 0) {
                lo_ = 1; hi_ = info[1]
            }
            else {
                lo_ = info[1] + (q - 1) * info[2] + 1; hi_ = info[1] + q * info[2]
            }
            DG[1, (c0 + 1)..(c0 + 4)] = _xp_abarc(e, XA[., lo_..hi_], IF[., lo_..hi_], tt, N, T, 1)
            DG[2, (c0 + 1)..(c0 + 4)] = _xp_abarc(e, XA[., lo_..hi_], IF[., lo_..hi_], tt, N, T, 2)
        }
        else DG[1, (c0 + 1)..(c0 + 4)] = _xp_wooldridge(e, tt, N, T)
        DG[3, (c0 + 1)..(c0 + 4)] = _xp_modwald(e, N, T)
        DG[4, (c0 + 1)..(c0 + 4)] = _xp_bf(e, N, T)
        if (q == 0) {
            y = Y
            Z = (D, Mm, X)
        }
        else {
            y = Mm[., q]
            Z = (D, X)
        }
        DG[5, (c0 + 1)..(c0 + 4)] = _xp_koenker(e, Z)
        cs = _xp_csd(e, N, T)
        DG[6, (c0 + 1)] = cs[1]; DG[6, (c0 + 4)] = cs[2]
        DG[9, (c0 + 1)] = cs[3]
        DG[8, (c0 + 1)] = cs[4]; DG[8, (c0 + 4)] = cs[5]
        cs = _xp_csd(e :* (w # J(T, 1, 1)), N, T)
        DG[7, (c0 + 1)] = cs[1]; DG[7, (c0 + 4)] = cs[2]
        cs = _xp_jb(e)
        DG[10, (c0 + 1)] = cs[1]; DG[10, (c0 + 2)] = 2; DG[10, (c0 + 4)] = cs[2]
        DG[11, (c0 + 1)] = cs[3]; DG[12, (c0 + 1)] = cs[4]
        if (R1 != .) {
            keys = _xp_keys(est, info, km, kx, q)
            keyall = (keyall, keys)
            dd = R1[keys'] - R2[keys']
            W = dd' * invsym(V1[keys, keys] + V2[keys, keys]) * dd
            DG[13, (c0 + 1)..(c0 + 4)] = (W, cols(keys), ., chi2tail(cols(keys), W))
        }
        cs = _xp_py(y, Z, N, T)
        DG[14, (c0 + 1)] = cs[1]; DG[14, (c0 + 4)] = cs[2]
        DG[15, (c0 + 1)] = cs[3]; DG[15, (c0 + 4)] = cs[4]
        if (ecm) {
            keys = _xp_keys(est, info, km, kx, q)
            pos = keys[cols(keys)]
            DG[16, (c0 + 1)] = R[pos]
            DG[16, (c0 + 2)] = sqrt(V[pos, pos])
            DG[16, (c0 + 4)] = 2 * normal(-abs(R[pos] / sqrt(V[pos, pos])))
        }
    }
    if (R1 != .) {
        dd = R1[keyall'] - R2[keyall']
        W = dd' * invsym(V1[keyall, keyall] + V2[keyall, keyall]) * dd
        CJ = (W, cols(keyall), chi2tail(cols(keyall), W))
    }
}

real scalar _xp_trychow(real scalar est, real colvector Y, real colvector D, real matrix Mm,
    real matrix X, real matrix P, real scalar N, real scalar T, real matrix opt,
    real scalar dk, real scalar m, real matrix R, real matrix V, real matrix info)
{
    real matrix XA
    real matrix IF, res
    real scalar nobs, nper
    nobs = sum(_xp_ok((Y, D, Mm)))
    if (nobs < 10 * (cols(Mm) + cols(X) + 2)) return(1)
    nper = sum(colnonmissing(colshape(Y, T)) :> 0)
    if (nper < (est == 1 ? opt[1] + 4 : 5)) return(1)
    _xp_est(est, Y, D, Mm, X, P, N, T, opt, R, IF, res, info, XA)
    if (hasmissing(R)) return(1)
    V = _xp_vce(IF, N, T, dk, m)
    if (hasmissing(V)) return(1)
    return(0)
}

// ======================================================= main
void _xp_main(string scalar yv, string scalar dv, string scalar mv, string scalar cv,
    string scalar touse, string scalar gidv, string scalar tidv, real scalar N,
    real scalar T, real scalar est, real scalar dk, real scalar m, real scalar tfe,
    real scalar L, real scalar Jl, real scalar deg, real scalar K, real scalar reps,
    real scalar lam, real scalar dsq, real scalar twostep, real scalar collapse,
    real scalar d1, real scalar d0, real scalar B, real scalar dots, real scalar level,
    real scalar dodiag, real scalar brk, real scalar icode, real scalar pf, real scalar qf,
    real scalar maxp, real scalar maxq)
{
    real matrix Dat, Mm, X, P, opt, R, V, res, info, Jm, Ve, EB, DG, CJ, Rb, Vb, rb, ib, IF, XA, IFb, XAb
    real matrix LG, Xq, SRM
    real colvector gid, tid, row, Y, D, se, z, p, lo, hi, u, rr, s, tt, yq
    real scalar n, km, kx, cvz, nfail, b, i, a, nok, lo_i, hi_i, qq
    real rowvector eff

    gid = st_data(., gidv, touse)
    tid = st_data(., tidv, touse)
    Dat = st_data(., (yv, dv), touse)
    Mm0 = st_data(., tokens(mv), touse)
    if (strtrim(cv) != "") X0 = st_data(., tokens(cv), touse)
    else X0 = J(rows(gid), 0, .)
    km = cols(Mm0); kx = cols(X0)
    n = N * T
    row = (gid :- 1) * T + tid
    Y = J(n, 1, .); D = J(n, 1, .); Mm = J(n, km, .); X = J(n, kx, .)
    Y[row] = Dat[., 1]; D[row] = Dat[., 2]; Mm[row, .] = Mm0
    if (kx) X[row, .] = X0

    if (est == 1 & kx) {
        P = _xp_poly(X, deg)
        Pc = select(P, _xp_ok(P))
        s = selectindex(diagonal(invsym(cross(Pc :- mean(Pc), Pc :- mean(Pc)))) :!= 0)
        P = P[., s]
    }
    else P = J(n, 0, .)
    LG = J(km + 1, 2, 1)
    if (est == 4 | est == 5 | est == 6 | est == 9) {
        tt = J(N, 1, (1::T))
        for (qq = 0; qq <= km; qq++) {
            if (qq == 0) {
                yq = Y
                Xq = (D, Mm, X)
            }
            else {
                yq = Mm[., qq]
                Xq = (D, X)
            }
            if (icode > 0) LG[qq + 1, .] = _xp_icsel(est, yq, Xq, tt, N, T, icode, maxp, maxq)
            else LG[qq + 1, .] = (pf, qf)
        }
    }
    st_matrix("__xp_lags", LG)
    if (est == 4 | est == 5 | est == 6 | est == 9) {
        SRM = J(0, 2, .)
        for (qq = 0; qq <= km; qq++) {
            if (qq == 0) {
                yq = Y
                Xq = (D, Mm, X)
            }
            else {
                yq = Mm[., qq]
                Xq = (D, X)
            }
            SRM = SRM \ _xp_sr(est, yq, Xq, tt, N, T, LG[qq + 1, 1], LG[qq + 1, 2], tfe)
        }
        st_matrix("__xp_sr", SRM)
    }
    opt = (L, Jl, K, dsq, twostep, collapse, lam, tfe, rowshape(LG, 1))

    _xp_fitV(est, Y, D, Mm, X, P, N, T, opt, reps, dk, m, R, V, res, info, IF, XA)
    if (hasmissing(R)) {
        errprintf("estimation failed (singular design or too few usable observations)\n")
        exit(error(430))
    }

    eff = _xp_eff(R, est, info, km, L, dsq, d1, d0)
    Jm  = _xp_effjac(R, est, info, km, L, dsq, d1, d0)
    Ve  = Jm * V * Jm'
    Ve  = (Ve + Ve') / 2
    se  = sqrt(diagonal(Ve))
    cvz = invnormal(1 - (1 - level / 100) / 2)
    lo  = eff' - cvz * se
    hi  = eff' + cvz * se
    nfail = 0

    if (B > 0) {
        EB = J(B, cols(eff), .)
        if (dots) printf("{txt}Bootstrap replications ({res}%g{txt})\n", B)
        for (b = 1; b <= B; b++) {
            u  = ceil(N * runiform(N, 1))
            rr = _xp_rows(u, T)
            Pb = (cols(P) ? P[rr, .] : J(rows(rr), 0, .))
            Xb = (kx ? X[rr, .] : J(rows(rr), 0, .))
            _xp_fitV(est, Y[rr], D[rr], Mm[rr, .], Xb, Pb, N, T, opt, reps, 0, m, Rb, Vb, rb, ib, IFb, XAb)
            if (hasmissing(Rb)) {
                nfail++
                if (dots) printf("{err}x{txt}")
            }
            else {
                EB[b, .] = _xp_eff(Rb, est, ib, km, L, dsq, d1, d0)
                if (dots) printf(".")
            }
            if (dots & mod(b, 50) == 0) printf(" %g\n", b)
            displayflush()
        }
        if (dots) printf("\n")
        a = (1 - level / 100) / 2
        for (i = 1; i <= cols(eff); i++) {
            s = select(EB[., i], EB[., i] :< .)
            nok = rows(s)
            if (nok > 1) {
                se[i] = sqrt(variance(s))
                s = sort(s, 1)
                lo_i = max((1, floor(a * nok)))
                hi_i = min((nok, ceil((1 - a) * nok)))
                lo[i] = s[lo_i]
                hi[i] = s[hi_i]
            }
        }
        Ve = variance(select(EB, rowmissing(EB) :== 0))
        st_matrix("__xp_bboot", EB)
    }
    z = eff' :/ se
    p = 2 * normal(-abs(z))

    if (dodiag) {
        _xp_diagall(est, Y, D, Mm, X, P, N, T, opt, dk, m, R, V, res, info, brk, DG, CJ, IF, XA)
        st_matrix("__xp_diag", DG)
        st_matrix("__xp_chowj", CJ)
    }

    st_matrix("__xp_b", R')
    st_matrix("__xp_V", V)
    st_matrix("__xp_eff", (eff', se, z, p, lo, hi))
    st_matrix("__xp_beff", eff)
    st_matrix("__xp_veff", Ve)
    st_numscalar("__xp_J", (est == 1 ? info[3] : .))
    st_numscalar("__xp_Jdf", (est == 1 ? info[4] : .))
    st_numscalar("__xp_bfail", nfail)
}

end
