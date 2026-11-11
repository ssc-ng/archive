*! version 1.2.2  09nov2026
*! idxspec: compare and interpret nonlinear specifications for an index covariate
program define idxspec, rclass
    version 14
    syntax varlist(min=2 numeric fv) [if] [in] [, FE VCE(string) TRIM(real 0.05) ///
        NKnots(integer 4) KFold(integer 5) FOLDvar(varname numeric) SEED(string) ///
        NGrid(integer 41) Level(cilevel) ALPha(real 0.05) GRaph GRAPHOPTs(string asis) noTABle ///
        DK DKLag(integer -1) IV(varlist numeric) SIMEX(real 0) PSEudo(integer 50) ///
        BReps(integer 199) RANK RANKBy(varlist) POWer(real 0.8) CCE TWOway]

    * ---------------------------------------------------------------- parse
    gettoken y rest : varlist
    gettoken x W : rest
    foreach v in y x {
        if strpos("``v''", ".") {
            di as err "`v' variable may not be a factor or time-series operated variable"
            exit 198
        }
    }
    if `trim' <= 0 | `trim' >= 0.25 {
        di as err "trim() must be in (0, 0.25)"
        exit 198
    }
    if `nknots' < 3 | `nknots' > 7 {
        di as err "nknots() must be between 3 and 7"
        exit 198
    }
    if `kfold' < 2 {
        di as err "kfold() must be at least 2"
        exit 198
    }
    if `alpha' <= 0 | `alpha' >= 0.5 {
        di as err "alpha() must be in (0, 0.5)"
        exit 198
    }
    if `power' <= 0 | `power' >= 1 {
        di as err "power() must be in (0, 1)"
        exit 198
    }
    if `simex' < 0 {
        di as err "simex() must be a non-negative measurement-error standard deviation"
        exit 198
    }
    if "`dk'" != "" & "`iv'" != "" {
        di as err "options dk and iv() may not be combined; use vce(cluster) with iv()"
        exit 198
    }
    if "`dk'" != "" & "`twoway'" != "" {
        di as err "options dk and twoway may not be combined"
        exit 198
    }
    if "`twoway'" != "" & "`iv'" != "" {
        di as err "options twoway and iv() may not be combined; use vce(cluster) with iv()"
        exit 198
    }
    if "`twoway'" != "" & "`vce'" != "" {
        di as txt "(note: vce() ignored because twoway was specified)"
        local vce ""
    }
    if "`dk'" != "" & "`vce'" != "" {
        di as txt "(note: vce() ignored because dk was specified)"
        local vce ""
    }
    marksample touse
    if "`iv'" != "" markout `touse' `iv'
    local xname "`x'"
    * panel and time identifiers (used by fe, dk, the CD test and simex)
    local pvar ""
    local tvar ""
    capture quietly xtset
    if !_rc {
        local pvar "`r(panelvar)'"
        local tvar "`r(timevar)'"
    }
    if ("`dk'`twoway'`cce'" != "") & ("`pvar'" == "" | "`tvar'" == "") {
        di as err "options dk, twoway, and cce require the data to be xtset with panel and time variables"
        exit 459
    }
    if "`cce'" != "" & "`fe'" == "" {
        di as err "option cce requires fe (common correlated effects pooled estimator)"
        exit 198
    }
    local ivar ""
    if "`fe'" != "" {
        capture quietly xtset
        if _rc {
            di as err "option fe requires the data to be xtset"
            exit 459
        }
        local ivar "`r(panelvar)'"
        markout `touse' `ivar'
        local estcmd "xtreg"
        local estopt "fe"
    }
    else {
        local estcmd "regress"
        local estopt ""
    }
    if "`vce'" != "" local estopt "`estopt' vce(`vce')"
    quietly count if `touse'
    local N = r(N)
    if `N' < 30 {
        di as err "too few observations (`N')"
        exit 2001
    }

    * optional percentile-rank (ordinal) version of the index
    if "`rank'" != "" | "`rankby'" != "" {
        tempvar xr xn
        if "`rankby'" != "" {
            quietly egen double `xr' = rank(`x') if `touse', by(`rankby')
            quietly egen double `xn' = count(`x') if `touse', by(`rankby')
        }
        else {
            quietly egen double `xr' = rank(`x') if `touse'
            quietly egen double `xn' = count(`x') if `touse'
        }
        quietly replace `xr' = 100*`xr'/`xn' if `touse'
        local xname "`x' (percentile rank)"
        local x "`xr'"
    }

    * common correlated effects: period averages of y, x, x^2 and continuous controls,
    * each interacted with panel indicators (heterogeneous loadings), added to the controls
    local ncce = 0
    if "`cce'" != "" {
        tempvar cx2
        quietly gen double `cx2' = (`x')^2 if `touse'
        local clist "`y' `x' `cx2'"
        foreach w of local W {
            if !strpos("`w'", ".") & !strpos("`w'", "#") local clist "`clist' `w'"
        }
        local cceav ""
        local i = 0
        foreach v of local clist {
            local ++i
            tempvar ca`i'
            quietly egen double `ca`i'' = mean(`v') if `touse', by(`tvar')
            local cceav "`cceav' `ca`i''"
        }
        local ncce = `i'
        local W "`W' i.`pvar'#c.(`cceav')"
    }

    * DK or two-way covariance helper call
    local dkcall ""
    if "`dk'" != "" {
        local dkcall "_idxnl_dkrepost, time(`tvar') panel(`pvar') lag(`dklag')"
        if "`fe'" != "" local dkcall "`dkcall' fe"
    }
    if "`twoway'" != "" {
        local dkcall "_idxnl_dkrepost, time(`tvar') panel(`pvar') twoway"
        if "`fe'" != "" local dkcall "`dkcall' fe"
    }

    * instrumental-variables branch (separate routine)
    if "`iv'" != "" {
        local ivopts ""
        if "`ivar'" != "" local ivopts "`ivopts' panel(`ivar')"
        if "`vce'" != "" local ivopts "`ivopts' vce(`vce')"
        _idxspec_iv `y' `x' `W' if `touse', iv(`iv') `fe' `ivopts' trim(`trim') ///
            nknots(`nknots') level(`level') alpha(`alpha') xname(`xname') power(`power') `table'
        return add
        exit
    }

    * expanded (temporary) controls for the manual cross-validation step
    local Wv ""
    if "`W'" != "" {
        fvrevar `W' if `touse'
        local Wv "`r(varlist)'"
    }

    * ---------------------------------------------------------------- support & bases
    local plo = 100*`trim'
    local phi = 100*(1 - `trim')
    quietly _pctile `x' if `touse', percentiles(`plo' `phi')
    local lo = r(r1)
    local hi = r(r2)
    quietly summarize `x' if `touse', meanonly
    local xmin = r(min)
    local xmax = r(max)

    tempvar x2 x3 kx tl1 tl2 tl3 fold r2 xb
    quietly gen double `x2' = (`x')^2 if `touse'
    quietly gen double `x3' = (`x')^3 if `touse'

    if `nknots' == 3 local hp "10 50 90"
    if `nknots' == 4 local hp "5 35 65 95"
    if `nknots' == 5 local hp "5 27.5 50 72.5 95"
    if `nknots' == 6 local hp "5 23 41 59 77 95"
    if `nknots' == 7 local hp "2.5 18.33 34.17 50 65.83 81.67 97.5"
    quietly _pctile `x' if `touse', percentiles(`hp')
    local knots ""
    forvalues j = 1/`nknots' {
        local t`j' = r(r`j')
        local knots "`knots' `t`j''"
    }
    forvalues j = 2/`nknots' {
        local jm = `j' - 1
        if `t`j'' <= `t`jm'' {
            di as err "knots are not distinct; reduce nknots() (index has too few distinct values)"
            exit 498
        }
    }
    local k = `nknots'
    local km1 = `k' - 1
    local rcsvars ""
    forvalues i = 1/`=`k'-2' {
        tempvar s`i'
        quietly gen double `s`i'' = (max(`x' - `t`i'', 0)^3 ///
            - (`t`k'' - `t`i'')/(`t`k'' - `t`km1'')*max(`x' - `t`km1'', 0)^3 ///
            + (`t`km1'' - `t`i'')/(`t`k'' - `t`km1'')*max(`x' - `t`k'', 0)^3) ///
            / (`t`k'' - `t1')^2 if `touse'
        local rcsvars "`rcsvars' `s`i''"
    }

    * ---------------------------------------------------------------- kink grid search
    local feflag = cond("`fe'" != "", "isfe", "")
    quietly gen double `kx' = .
    local cbest = .
    local ssrbest = .
    local cprev = .
    local ng = 0
    forvalues g = 0/`=`ngrid'-1' {
        local p = 100*(`trim' + `g'*(1 - 2*`trim')/(`ngrid' - 1))
        quietly _pctile `x' if `touse', percentiles(`p')
        local c = r(r1)
        if `c' == `cprev' continue
        local cprev = `c'
        local ++ng
        quietly replace `kx' = max(`x' - `c', 0) if `touse'
        _idxspec_ssr `y' `x' `kx' `W' if `touse', `feflag'
        local ssr`ng' = r(ssr)
        local cg`ng' = `c'
        if `ssr`ng'' < `ssrbest' {
            local ssrbest = `ssr`ng''
            local cbest = `c'
        }
    }
    local c = `cbest'
    quietly replace `kx' = max(`x' - `c', 0) if `touse'
    local critLR = invchi2(1, `level'/100)
    local clo = .
    local chi = .
    forvalues g = 1/`ng' {
        local LR = `N'*(`ssr`g'' - `ssrbest')/`ssrbest'
        if `LR' <= `critLR' {
            local clo = min(`clo', `cg`g'')
            if missing(`chi') local chi = `cg`g''
            else local chi = max(`chi', `cg`g'')
        }
    }

    * ---------------------------------------------------------------- full-sample fits
    local fl_lin  "`x'"
    local fl_quad "`x' `x2'"
    local fl_cub  "`x' `x2' `x3'"
    local fl_rcs  "`x' `rcsvars'"
    local fl_kink "`x' `kx'"
    local models "lin quad cub rcs kink"
    tempname bq Vq brc Vrc bk Vk cmp
    matrix `cmp' = J(5, 6, .)
    local row = 0
    foreach m of local models {
        local ++row
        quietly `estcmd' `y' `fl_`m'' `W' if `touse', `estopt'
        `dkcall'
        local df = e(df_r)
        * number of estimated slope coefficients: positive variance, excluding _cons
        * (e(df_m) is not used: under clustering it can be smaller than the number of parameters)
        tempname vd
        matrix `vd' = vecdiag(e(V))
        local icn = colnumb(`vd', "_cons")
        local dfm = 0
        forvalues jj = 1/`=colsof(`vd')' {
            if `vd'[1, `jj'] > 0 & !missing(`vd'[1, `jj']) & `jj' != `icn' local ++dfm
        }
        if "`m'" == "quad" {
            matrix `bq' = e(b)
            matrix `Vq' = e(V)
            local dfq = e(df_r)
            quietly test `x2'
            local F_quad = r(F)
            local p_quad = r(p)
            local b1 = _b[`x']
            local b2 = _b[`x2']
            local v11 = _se[`x']^2
            local v22 = _se[`x2']^2
            matrix `Vq' = e(V)
            local v12 = `Vq'[colnumb(`Vq', "`x'"), colnumb(`Vq', "`x2'")]
        }
        if "`m'" == "rcs" {
            matrix `brc' = e(b)
            matrix `Vrc' = e(V)
            quietly test `rcsvars'
            local F_rcs = r(F)
            local p_rcs = r(p)
        }
        if "`m'" == "kink" {
            matrix `bk' = e(b)
            matrix `Vk' = e(V)
            quietly test `kx'
            local F_kink = r(F)
            local p_kink = r(p)
            local sl_lo = _b[`x']
            local se_lo = _se[`x']
            quietly lincom `x' + `kx'
            local sl_hi = r(estimate)
            local se_hi = r(se)
        }
        * SSR from residuals (within residuals under fe)
        capture drop `r2'
        if "`fe'" != "" {
            quietly predict double `r2' if `touse', e
        }
        else {
            quietly predict double `r2' if `touse', residuals
        }
        quietly replace `r2' = (`r2')^2
        quietly summarize `r2' if `touse', meanonly
        local ssr = r(sum)
        local kpar = `dfm' + ("`fe'" == "") + ("`m'" == "kink")
        local ll = -(`N')/2*(ln(2*_pi) + ln(`ssr'/`N') + 1)
        matrix `cmp'[`row', 1] = `kpar'
        matrix `cmp'[`row', 2] = -2*`ll' + 2*`kpar'
        matrix `cmp'[`row', 3] = -2*`ll' + ln(`N')*`kpar'
    }
    * Pesaran CD test on the residuals of the quadratic model
    local cdstat = .
    local cdp = .
    local cdrho = .
    if "`pvar'" != "" & "`tvar'" != "" {
        tempvar rq
        quietly `estcmd' `y' `fl_quad' `W' if `touse', `estopt'
        if "`fe'" != "" quietly predict double `rq' if `touse', e
        else quietly predict double `rq' if `touse', residuals
        capture _idxnl_cd `rq' if `touse', panel(`pvar') time(`tvar')
        if !_rc {
            local cdstat = r(cd)
            local cdp = r(p)
            local cdrho = r(absrho)
        }
    }
    matrix `cmp'[2, 5] = `F_quad'
    matrix `cmp'[2, 6] = `p_quad'
    matrix `cmp'[4, 5] = `F_rcs'
    matrix `cmp'[4, 6] = `p_rcs'
    matrix `cmp'[5, 5] = `F_kink'
    matrix `cmp'[5, 6] = `p_kink'

    * ---------------------------------------------------------------- K-fold CV
    if "`foldvar'" != "" {
        tempvar fg
        quietly egen `fg' = group(`foldvar') if `touse'
        quietly gen long `fold' = `fg' - 1 if `touse'
        quietly summarize `fold' if `touse', meanonly
        local kfold = r(max) + 1
    }
    else if "`seed'" != "" {
        set seed `seed'
        quietly gen long `fold' = floor(`kfold'*runiform()) if `touse'
    }
    else if "`pvar'" != "" & "`tvar'" != "" {
        * panel data: diagonal assignment so that every period and every panel
        * appears in every fold (period effects are then always estimable)
        tempvar fgp fgt
        quietly egen long `fgp' = group(`pvar') if `touse'
        quietly egen long `fgt' = group(`tvar') if `touse'
        quietly gen long `fold' = mod(`fgp' + `fgt', `kfold') if `touse'
    }
    else {
        quietly gen long `fold' = mod(sum(`touse') - 1, `kfold') if `touse'
    }
    foreach m of local models {
        local sse_`m' = 0
    }
    local ncv = 0
    tempvar tr te
    quietly gen byte `tr' = 0
    quietly gen byte `te' = 0
    forvalues f = 0/`=`kfold'-1' {
        quietly replace `tr' = `touse' & `fold' != `f'
        quietly replace `te' = `touse' & `fold' == `f'
        if "`fe'" == "" {
            foreach m of local models {
                quietly regress `y' `fl_`m'' `Wv' if `tr'
                capture drop `xb'
                quietly predict double `xb' if `te', xb
                quietly replace `xb' = (`y' - `xb')^2 if `te'
                quietly summarize `xb' if `te', meanonly
                local sse_`m' = `sse_`m'' + r(sum)
            }
            quietly count if `te'
            local ncv = `ncv' + r(N)
        }
        else {
            * demean with training-fold panel means; spread means to test obs
            local allv "`y' `x' `x2' `x3' `rcsvars' `kx' `Wv'"
            local dlist ""
            local i = 0
            foreach v of local allv {
                local ++i
                tempvar m`i' d`i'
                quietly egen double `m`i'' = mean(cond(`tr', `v', .)), by(`ivar')
                quietly gen double `d`i'' = `v' - `m`i'' if `touse'
                local dlist "`dlist' `d`i''"
            }
            local dy "`d1'"
            local my "`m1'"
            local dx "`d2'"
            local dx2 "`d3'"
            local dx3 "`d4'"
            local j = 4
            local drcs ""
            foreach s of local rcsvars {
                local ++j
                local drcs "`drcs' `d`j''"
            }
            local ++j
            local dkx "`d`j''"
            local dW ""
            foreach w of local Wv {
                local ++j
                local dW "`dW' `d`j''"
            }
            local dfl_lin  "`dx'"
            local dfl_quad "`dx' `dx2'"
            local dfl_cub  "`dx' `dx2' `dx3'"
            local dfl_rcs  "`dx' `drcs'"
            local dfl_kink "`dx' `dkx'"
            foreach m of local models {
                quietly regress `dy' `dfl_`m'' `dW' if `tr', noconstant
                capture drop `xb'
                quietly predict double `xb' if `te' & !missing(`my'), xb
                quietly replace `xb' = (`y' - `my' - `xb')^2 if `te' & !missing(`my')
                quietly summarize `xb' if `te' & !missing(`my'), meanonly
                local sse_`m' = `sse_`m'' + r(sum)
            }
            quietly count if `te' & !missing(`my')
            local ncv = `ncv' + r(N)
            forvalues ii = 1/`i' {
                capture drop `m`ii'' `d`ii''
            }
        }
    }
    local row = 0
    foreach m of local models {
        local ++row
        matrix `cmp'[`row', 4] = sqrt(`sse_`m''/`ncv')
    }
    matrix rownames `cmp' = linear quadratic cubic rcs kink
    matrix colnames `cmp' = k AIC BIC CV_RMSE F_nonlin p_nonlin

    * best by CV and BIC
    local bestcv = 1
    local bestbic = 1
    forvalues r = 2/5 {
        if `cmp'[`r', 4] < `cmp'[`bestcv', 4] local bestcv = `r'
        if `cmp'[`r', 3] < `cmp'[`bestbic', 3] local bestbic = `r'
    }
    local mnames "linear quadratic cubic rcs kink"
    local bestcvname : word `bestcv' of `mnames'
    local bestbicname : word `bestbic' of `mnames'

    * ---------------------------------------------------------------- turning point & shape
    if missing(`dfq') {
        local crit = invnormal(0.5 + `level'/200)
        local crit1 = invnormal(1 - `alpha')
    }
    else {
        local crit = invttail(`dfq', (1 - `level'/100)/2)
        local crit1 = invttail(`dfq', `alpha')
    }
    _idxtp_core, b1(`b1') b2(`b2') v11(`v11') v22(`v22') v12(`v12') lo(`lo') hi(`hi') ///
        crit(`crit') df(`dfq')
    foreach s in tp se_tp delta_lb delta_ub fieller_lb fieller_ub lm_t lm_p slope_lo slope_hi t_lo t_hi {
        local `s' = r(`s')
    }
    local ftype "`r(fieller_type)'"
    local shape "`r(shape)'"
    _idxtp_core, b1(`b1') b2(`b2') v11(`v11') v22(`v22') v12(`v12') lo(`xmin') hi(`xmax') ///
        crit(`crit') df(`dfq')
    local lmf_t = r(lm_t)
    local lmf_p = r(lm_p)
    quietly count if `touse' & `x' <= `tp'
    local tppct = r(N)/`N'
    local inside = (`tp' > `lo' & `tp' < `hi')
    local finside = ("`ftype'" == "bounded" & `fieller_lb' > `lo' & `fieller_ub' < `hi')

    * two-lines check at the turning point (if inside S) or at the kink
    local xc = cond(`inside', `tp', `c')
    quietly gen double `tl1' = cond(`x' <= `xc', `x' - `xc', 0) if `touse'
    quietly gen double `tl2' = cond(`x' >  `xc', `x' - `xc', 0) if `touse'
    quietly gen double `tl3' = (`x' > `xc') if `touse'
    quietly `estcmd' `y' `tl1' `tl2' `tl3' `W' if `touse', `estopt'
    `dkcall'
    local dftl = e(df_r)
    local tlb1 = _b[`tl1']
    local tlb2 = _b[`tl2']
    local tlt1 = _b[`tl1']/_se[`tl1']
    local tlt2 = _b[`tl2']/_se[`tl2']
    if "`shape'" == "invU" local tlok = (`tlt1' > `crit1' & `tlt2' < -(`crit1'))
    else                   local tlok = (`tlt1' < -(`crit1') & `tlt2' > `crit1')

    * minimum detectable opposite-sign slope beyond xc (power analysis of the two-lines check)
    if missing(`dftl') local mds = (invnormal(1 - `alpha') + invnormal(`power'))*_se[`tl2']
    else local mds = (invttail(`dftl', `alpha') + invttail(`dftl', 1 - `power'))*_se[`tl2']
    quietly count if `touse' & `x' > `xc'
    local nbeyond = r(N)
    local fw = (`lm_p' < `alpha' & `finside' & `tlok')
    local adhoc = (`p_quad' < `alpha')
    local nonlin = (`p_rcs' < `alpha' | `p_quad' < `alpha')
    if `fw' {
        local verdict = cond("`shape'"=="invU", "inverted U-shape supported within S", "U-shape supported within S")
    }
    else if `nonlin' {
        if (`sl_lo' > 0 & `sl_hi' > 0) | (`sl_lo' < 0 & `sl_hi' < 0) {
            local verdict "nonlinear but monotone over S; turning point not established"
        }
        else {
            local verdict "nonlinear; turning point within S not established"
        }
    }
    else {
        local verdict "no evidence against linearity over S"
    }

    * ---------------------------------------------------------------- display
    if "`table'" == "" {
        di
        di as txt "Specification analysis for index covariate " as res "`xname'"
        di as txt "Dependent variable: " as res "`y'" as txt "   Estimator: " as res "`estcmd' `estopt'" ///
            as txt cond("`dk'" != "", "  (Driscoll-Kraay SE)", cond("`twoway'" != "", "  (two-way clustered SE)", "")) ///
            as txt cond("`cce'" != "", "  (CCE: " + string(`ncce') + " averages x panel)", "") as txt "   N = " as res `N'
        di as txt "Supported interval S = [" as res %9.4f `lo' as txt ", " as res %9.4f `hi' ///
            as txt "]  (percentiles " as res `plo' as txt " and " as res `phi' as txt ");  observed range [" ///
            as res %9.4f `xmin' as txt ", " as res %9.4f `xmax' as txt "]"
        di as txt "RCS knots:" as res "`knots'"
        di
        di as txt "{hline 13}{c TT}{hline 64}"
        di as txt "   Model     {c |}     k        AIC         BIC     CV-RMSE    F(nonlin)    p"
        di as txt "{hline 13}{c +}{hline 64}"
        local row = 0
        foreach m in linear quadratic cubic rcs kink {
            local ++row
            local Fs = cond(missing(`cmp'[`row',5]), "", string(`cmp'[`row',5], "%9.3f"))
            local ps = cond(missing(`cmp'[`row',6]), "", string(`cmp'[`row',6], "%6.4f"))
            di as txt %12s "`m'" " {c |}" as res %6.0f `cmp'[`row',1] %11.2f `cmp'[`row',2] ///
                %12.2f `cmp'[`row',3] %12.4f `cmp'[`row',4] "  " %11s "`Fs'" "  " %6s "`ps'"
        }
        di as txt "{hline 13}{c BT}{hline 64}"
        di as txt "Lowest CV-RMSE: " as res "`bestcvname'" as txt ";  lowest BIC: " as res "`bestbicname'" ///
            as txt ";  CV folds: " as res `kfold'
        di as txt "Kink at c = " as res %9.4f `c' as txt "  (LR `level'% set [" as res %8.4f `clo' as txt ", " ///
            as res %8.4f `chi' as txt "]);  slope below = " as res %8.4f `sl_lo' as txt " (" as res %6.4f `se_lo' ///
            as txt "), above = " as res %8.4f `sl_hi' as txt " (" as res %6.4f `se_hi' as txt ")"
        di
        di as txt "Shape inference from the quadratic"
        di as txt "{hline 78}"
        di as txt "  b(x) = " as res %9.4f `b1' as txt ",  b(x^2) = " as res %9.4f `b2' ///
            as txt "  (p = " as res %6.4f `p_quad' as txt ")"
        di as txt "  Turning point = " as res %9.4f `tp' as txt "  at percentile " as res %5.1f 100*`tppct' ///
            as txt " of " as res "`xname'"
        di as txt "  Delta `level'% CI  = [" as res %9.4f `delta_lb' as txt ", " as res %9.4f `delta_ub' as txt "]"
        if "`ftype'" == "bounded" {
            di as txt "  Fieller `level'% CI = [" as res %9.4f `fieller_lb' as txt ", " as res %9.4f `fieller_ub' as txt "]"
        }
        else if "`ftype'" == "union" {
            di as txt "  Fieller `level'% CI = (-inf, " as res %9.4f `fieller_lb' as txt "] U [" as res %9.4f `fieller_ub' as txt ", +inf)"
        }
        else {
            di as txt "  Fieller `level'% CI = " as res "unbounded"
        }
        di as txt "  Lind-Mehlum on S       : t = " as res %6.3f `lm_t' as txt ", p = " as res %6.4f `lm_p' ///
            as txt "   (full range: t = " as res %6.3f `lmf_t' as txt ", p = " as res %6.4f `lmf_p' as txt ")"
        di as txt "  Two-lines at " as res %8.4f `xc' as txt ": slope below = " as res %8.4f `tlb1' ///
            as txt " (t = " as res %5.2f `tlt1' as txt "), above = " as res %8.4f `tlb2' as txt " (t = " as res %5.2f `tlt2' as txt ")"
        di as txt "{hline 78}"
        di as txt "  Criteria (alpha = " as res `alpha' as txt "):  U-test on S " as res cond(`lm_p' < `alpha', "pass", "fail") ///
            as txt ";  Fieller CI within S " as res cond(`finside', "pass", "fail") ///
            as txt ";  two-lines " as res cond(`tlok', "pass", "fail")
        di as txt "  Beyond " as res %8.4f `xc' as txt ": " as res `nbeyond' as txt " obs.; minimum detectable opposite-sign slope (" ///
            as res 100*`power' as txt "% power) = " as res %8.4f `mds'
        if !missing(`cdstat') {
            di as txt "  Pesaran CD test (quadratic-model residuals): CD = " as res %7.3f `cdstat' as txt ", p = " ///
                as res %6.4f `cdp' as txt ", mean |rho| = " as res %5.3f `cdrho' ///
                as txt cond(`cdp' < 0.05 & "`cce'" == "", "  -> consider options fe cce", "")
        }
        di as txt "  Conventional rule (significant x^2): " as res cond(`adhoc', "would claim a turning point", "no claim")
        di as txt "  Verdict: " as res "`verdict'"
    }

    * ---------------------------------------------------------------- graph
    if "`graph'" != "" {
        _idxspec_graph, bq(`bq') vq(`Vq') brc(`brc') vrc(`Vrc') bk(`bk') vk(`Vk') x(`x') ///
            lo(`lo') hi(`hi') knots(`knots') c(`c') crit(`crit') rcsvars(`rcsvars') ///
            x2(`x2') kx(`kx') xname(`xname') `graphopts'
    }

    * ---------------------------------------------------------------- SIMEX correction
    if `simex' > 0 {
        local bvar "`pvar'"
        if "`fe'" != "" local bvar "`ivar'"
        _idxspec_simex `y' `x' if `touse', wv(`Wv') su(`simex') b(`pseudo') reps(`breps') ///
            panel(`ivar') bvar(`bvar') lo(`lo') hi(`hi') level(`level') alpha(`alpha') `table'
        foreach s in simex_b1 simex_b2 simex_se1 simex_se2 simex_tp simex_fieller_lb simex_fieller_ub ///
            simex_lm_t simex_lm_p naive_b1 naive_b2 {
            local R_`s' = r(`s')
        }
        local R_simex_ftype "`r(simex_fieller_type)'"
    }

    * ---------------------------------------------------------------- returns
    if `simex' > 0 {
        foreach s in simex_b1 simex_b2 simex_se1 simex_se2 simex_tp simex_fieller_lb simex_fieller_ub ///
            simex_lm_t simex_lm_p naive_b1 naive_b2 {
            return scalar `s' = `R_`s''
        }
        return local simex_fieller_type "`R_simex_ftype'"
    }
    return scalar mds = `mds'
    return scalar n_beyond = `nbeyond'
    return scalar cd = `cdstat'
    return scalar cd_p = `cdp'
    return scalar cd_absrho = `cdrho'
    return matrix compare = `cmp'
    return scalar N = `N'
    return scalar lo = `lo'
    return scalar hi = `hi'
    return scalar tp = `tp'
    return scalar tp_pct = `tppct'
    return scalar se_tp = `se_tp'
    return scalar delta_lb = `delta_lb'
    return scalar delta_ub = `delta_ub'
    return scalar fieller_lb = `fieller_lb'
    return scalar fieller_ub = `fieller_ub'
    return scalar lm_t = `lm_t'
    return scalar lm_p = `lm_p'
    return scalar lmfull_t = `lmf_t'
    return scalar lmfull_p = `lmf_p'
    return scalar kink = `c'
    return scalar kink_lb = `clo'
    return scalar kink_ub = `chi'
    return scalar slope_below = `sl_lo'
    return scalar slope_above = `sl_hi'
    return scalar twolines_b1 = `tlb1'
    return scalar twolines_b2 = `tlb2'
    return scalar twolines_t1 = `tlt1'
    return scalar twolines_t2 = `tlt2'
    return scalar twolines_at = `xc'
    return scalar p_quad = `p_quad'
    return scalar p_rcs = `p_rcs'
    return scalar p_kink = `p_kink'
    return scalar fieller_inside = `finside'
    return scalar twolines_pass = `tlok'
    return scalar supported = `fw'
    return scalar adhoc = `adhoc'
    return local fieller_type "`ftype'"
    return local shape "`shape'"
    return local verdict "`verdict'"
    return local best_cv "`bestcvname'"
    return local best_bic "`bestbicname'"
    return local knots "`knots'"
end

program define _idxspec_ssr, rclass
    version 14
    syntax varlist(fv) if [, ISFE]
    marksample touse
    gettoken y rhs : varlist
    if "`isfe'" == "" {
        quietly regress `y' `rhs' if `touse'
        return scalar ssr = e(rss)
    }
    else {
        tempvar e
        quietly xtreg `y' `rhs' if `touse', fe
        quietly predict double `e' if `touse', e
        quietly replace `e' = (`e')^2
        quietly summarize `e' if `touse', meanonly
        return scalar ssr = r(sum)
    }
end

program define _idxspec_graph
    version 14
    syntax , bq(name) vq(name) brc(name) vrc(name) bk(name) vk(name) x(varname) lo(real) hi(real) ///
        knots(numlist) c(real) crit(real) rcsvars(string) x2(string) kx(string) [xname(string) *]
    tempname bQ VQ bR VR bK VK
    * extract sub-vectors for the index terms
    matrix `bQ' = (`bq'[1, "`x'"], `bq'[1, "`x2'"])
    matrix `VQ' = J(2, 2, .)
    local nq "`x' `x2'"
    forvalues i = 1/2 {
        forvalues j = 1/2 {
            local a : word `i' of `nq'
            local b : word `j' of `nq'
            matrix `VQ'[`i', `j'] = `vq'["`a'", "`b'"]
        }
    }
    local nr "`x' `rcsvars'"
    local kr : word count `nr'
    matrix `bR' = J(1, `kr', .)
    matrix `VR' = J(`kr', `kr', .)
    forvalues i = 1/`kr' {
        local a : word `i' of `nr'
        matrix `bR'[1, `i'] = `brc'[1, "`a'"]
        forvalues j = 1/`kr' {
            local b : word `j' of `nr'
            matrix `VR'[`i', `j'] = `vrc'["`a'", "`b'"]
        }
    }
    matrix `bK' = (`bk'[1, "`x'"], `bk'[1, "`kx'"])
    matrix `VK' = J(2, 2, .)
    local nk "`x' `kx'"
    forvalues i = 1/2 {
        forvalues j = 1/2 {
            local a : word `i' of `nk'
            local b : word `j' of `nk'
            matrix `VK'[`i', `j'] = `vk'["`a'", "`b'"]
        }
    }
    preserve
    quietly {
        clear
        set obs 101
        gen double grid = `lo' + (_n - 1)*(`hi' - `lo')/100
        mata: _idxnl_mecurves("`bQ'", "`VQ'", "`bR'", "`VR'", "`bK'", "`VK'", "`knots'", `c', `crit')
    }
    twoway (rarea q_lo q_hi grid, color(gs13)) (line q_me grid, lcolor(black) lpattern(dash)) ///
        (rarea r_lo r_hi grid, color(gs11)) (line r_me grid, lcolor(black)) ///
        (line k_me grid, lcolor(gs6) lpattern(shortdash)), ///
        yline(0, lcolor(gs8)) xtitle("`xname' (supported interval)") ytitle("Marginal effect") ///
        legend(order(2 "Quadratic" 4 "Restricted cubic spline" 5 "Kink") rows(1)) `options'
    restore
end

version 14
mata:
void _idxnl_mecurves(string scalar bq, string scalar vq, string scalar br, string scalar vr,
    string scalar bk, string scalar vk, string scalar kn, real scalar c, real scalar crit)
{
    real colvector g, me, se, t
    real matrix D
    real scalar k, i
    g = st_data(., "grid")
    // quadratic
    D = (J(rows(g), 1, 1), 2*g)
    me = D*st_matrix(bq)'
    se = sqrt(rowsum((D*st_matrix(vq)) :* D))
    (void) st_addvar("double", ("q_me", "q_lo", "q_hi"))
    st_store(., ("q_me", "q_lo", "q_hi"), (me, me - crit*se, me + crit*se))
    // restricted cubic spline derivative (Stata mkspline convention)
    t = strtoreal(tokens(kn))'
    k = rows(t)
    D = J(rows(g), 1, 1)
    for (i = 1; i <= k - 2; i++) {
        D = D, (3*(g :- t[i]):^2 :* (g :> t[i]) ///
            - (t[k] - t[i])/(t[k] - t[k-1]) * 3*(g :- t[k-1]):^2 :* (g :> t[k-1]) ///
            + (t[k-1] - t[i])/(t[k] - t[k-1]) * 3*(g :- t[k]):^2 :* (g :> t[k])) / (t[k] - t[1])^2
    }
    me = D*st_matrix(br)'
    se = sqrt(rowsum((D*st_matrix(vr)) :* D))
    (void) st_addvar("double", ("r_me", "r_lo", "r_hi"))
    st_store(., ("r_me", "r_lo", "r_hi"), (me, me - crit*se, me + crit*se))
    // kink
    D = (J(rows(g), 1, 1), (g :> c))
    me = D*st_matrix(bk)'
    (void) st_addvar("double", "k_me")
    st_store(., "k_me", me)
}
end
