*! version 1.2.2  09nov2026
*! idxint: support-aware interaction analysis for two index covariates
program define idxint, rclass
    version 14
    syntax varlist(min=3 numeric fv) [if] [in] [, FE VCE(string) TRIM(real 0.05) ///
        NBins(integer 3) Level(cilevel) NGrid(integer 25) MINCount(integer 0) ///
        GRaph GRAPHOPTs(string asis) noTABle DK DKLag(integer -1) CCE TWOway]

    gettoken y rest : varlist
    gettoken x rest : rest
    gettoken z W : rest
    foreach v in y x z {
        if strpos("``v''", ".") {
            di as err "`v' variable may not be a factor or time-series operated variable"
            exit 198
        }
    }
    if `trim' <= 0 | `trim' >= 0.25 {
        di as err "trim() must be in (0, 0.25)"
        exit 198
    }
    if `nbins' < 2 | `nbins' > 5 {
        di as err "nbins() must be between 2 and 5"
        exit 198
    }
    if `ngrid' < 5 {
        di as err "ngrid() must be at least 5"
        exit 198
    }
    marksample touse
    local dkcall ""
    if "`dk'" != "" & "`twoway'" != "" {
        di as err "options dk and twoway may not be combined"
        exit 198
    }
    if "`twoway'`cce'" != "" {
        capture quietly xtset
        if _rc | "`r(timevar)'" == "" {
            di as err "options twoway and cce require the data to be xtset with panel and time variables"
            exit 459
        }
        local pvar "`r(panelvar)'"
        local tvar "`r(timevar)'"
        if "`twoway'" != "" {
            local dkcall "_idxnl_dkrepost, time(`tvar') panel(`pvar') twoway"
            if "`fe'" != "" local dkcall "`dkcall' fe"
            if "`vce'" != "" {
                di as txt "(note: vce() ignored because twoway was specified)"
                local vce ""
            }
        }
        if "`cce'" != "" {
            if "`fe'" == "" {
                di as err "option cce requires fe"
                exit 198
            }
            tempvar cx2
            quietly gen double `cx2' = (`x')^2 if `touse'
            local clist "`y' `x' `cx2' `z'"
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
            local W "`W' i.`pvar'#c.(`cceav')"
        }
    }
    if "`dk'" != "" {
        capture quietly xtset
        if _rc | "`r(timevar)'" == "" {
            di as err "option dk requires the data to be xtset with panel and time variables"
            exit 459
        }
        local dkcall "_idxnl_dkrepost, time(`r(timevar)') panel(`r(panelvar)') lag(`dklag')"
        if "`fe'" != "" local dkcall "`dkcall' fe"
        if "`vce'" != "" {
            di as txt "(note: vce() ignored because dk was specified)"
            local vce ""
        }
    }
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
    quietly correlate `x' `z' if `touse'
    local rho = r(rho)
    quietly summarize `x' if `touse'
    local sdx = r(sd)
    quietly summarize `z' if `touse'
    local sdz = r(sd)
    local zmin = r(min)
    local zmax = r(max)
    local plo = 100*`trim'
    local phi = 100*(1 - `trim')
    quietly _pctile `z' if `touse', percentiles(`plo' `phi')
    local zl = r(r1)
    local zh = r(r2)

    tempvar xz x2 z2
    quietly gen double `xz' = `x'*`z' if `touse'
    quietly gen double `x2' = (`x')^2 if `touse'
    quietly gen double `z2' = (`z')^2 if `touse'

    * (A) conventional linear interaction
    quietly `estcmd' `y' `x' `z' `xz' `W' if `touse', `estopt'
    `dkcall'
    local df = e(df_r)
    tempname bA VA
    local bAx = _b[`x']
    local bAz = _b[`z']
    local bAxz = _b[`xz']
    local sAx = _se[`x']
    local sAz = _se[`z']
    local sAxz = _se[`xz']
    matrix `VA' = e(V)
    local vxx = `VA'[colnumb(`VA', "`x'"), colnumb(`VA', "`x'")]
    local vii = `VA'[colnumb(`VA', "`xz'"), colnumb(`VA', "`xz'")]
    local vxi = `VA'[colnumb(`VA', "`x'"), colnumb(`VA', "`xz'")]
    local tA = `bAxz'/`sAxz'
    if missing(`df') local crit = invnormal(0.5 + `level'/200)
    else local crit = invttail(`df', (1 - `level'/100)/2)
    local pA = cond(missing(`df'), 2*(1 - normal(abs(`tA'))), 2*ttail(`df', abs(`tA')))

    * (B) adding own quadratic terms (curvature-robust check)
    quietly `estcmd' `y' `x' `z' `xz' `x2' `z2' `W' if `touse', `estopt'
    `dkcall'
    local bBxz = _b[`xz']
    local sBxz = _se[`xz']
    local tB = `bBxz'/`sBxz'
    local pB = cond(missing(e(df_r)), 2*(1 - normal(abs(`tB'))), 2*ttail(e(df_r), abs(`tB')))
    local bBx2 = _b[`x2']
    local bBz2 = _b[`z2']
    quietly test `x2' `z2'
    local Fq = r(F)
    local pq = r(p)

    * (N) nested test of the linear-interaction assumption with moderator bins
    local cuts ""
    forvalues j = 1/`=`nbins'-1' {
        local cuts "`cuts' `=100*`j'/`nbins''"
    }
    quietly _pctile `z' if `touse', percentiles(`cuts')
    tempvar bin
    quietly gen byte `bin' = 0 if `touse'
    forvalues j = 1/`=`nbins'-1' {
        local q`j' = r(r`j')
    }
    forvalues j = 1/`=`nbins'-1' {
        quietly replace `bin' = `bin' + (`z' >= `q`j'') if `touse'
    }
    local gl ""
    local xgl ""
    forvalues j = 1/`=`nbins'-1' {
        tempvar g`j' xg`j'
        quietly gen double `g`j'' = (`bin' == `j') if `touse'
        quietly gen double `xg`j'' = `x'*`g`j'' if `touse'
        local gl "`gl' `g`j''"
        local xgl "`xgl' `xg`j''"
    }
    quietly `estcmd' `y' `x' `z' `xz' `gl' `xgl' `W' if `touse', `estopt'
    `dkcall'
    quietly test `xgl'
    local Fbin = r(F)
    local pbin = r(p)

    * (C) binned conditional effects for display
    local cl ""
    forvalues j = 0/`=`nbins'-1' {
        tempvar d`j' xd`j' zd`j'
        quietly gen double `d`j'' = (`bin' == `j') if `touse'
        quietly _pctile `z' if `touse' & `bin' == `j', percentiles(50)
        local zmed`j' = r(r1)
        quietly count if `touse' & `bin' == `j'
        local sh`j' = r(N)/`N'
        quietly gen double `xd`j'' = `x'*`d`j'' if `touse'
        quietly gen double `zd`j'' = (`z' - `zmed`j'')*`d`j'' if `touse'
        if `j' > 0 local cl "`cl' `d`j''"
        local cl "`cl' `xd`j'' `zd`j''"
    }
    quietly `estcmd' `y' `cl' `W' if `touse', `estopt'
    `dkcall'
    forvalues j = 0/`=`nbins'-1' {
        local bb`j' = _b[`xd`j'']
        local sb`j' = _se[`xd`j'']
    }

    * support of the moderator and conditional effects from (A)
    if `mincount' == 0 local mincount = max(20, floor(0.02*`N'))
    local bw = 1.06*`sdz'*(`N')^(-0.2)
    tempname T
    matrix `T' = J(`ngrid', 7, .)
    local nsup = 0
    local zsup_lo = .
    local zsup_hi = .
    forvalues g = 1/`ngrid' {
        local zg = `zmin' + (`g' - 1)*(`zmax' - `zmin')/(`ngrid' - 1)
        quietly summarize `x' if `touse' & abs(`z' - `zg') <= `bw'
        local cnt = r(N)
        local sdl = cond(r(N) > 2, r(sd), 0)
        local me = `bAx' + `bAxz'*`zg'
        local se = sqrt(`vxx' + (`zg')^2*`vii' + 2*`zg'*`vxi')
        local sup = (`cnt' >= `mincount' & `sdl' >= 0.25*`sdx' & `zg' >= `zl' & `zg' <= `zh')
        matrix `T'[`g', 1] = `zg'
        matrix `T'[`g', 2] = `me'
        matrix `T'[`g', 3] = `me' - `crit'*`se'
        matrix `T'[`g', 4] = `me' + `crit'*`se'
        matrix `T'[`g', 5] = `cnt'
        matrix `T'[`g', 6] = `sdl'
        matrix `T'[`g', 7] = `sup'
        if `sup' {
            local ++nsup
            local zsup_lo = min(`zsup_lo', `zg')
            if missing(`zsup_hi') local zsup_hi = `zg'
            else local zsup_hi = max(`zsup_hi', `zg')
        }
    }
    matrix colnames `T' = z me lb ub n_local sd_x_local supported

    * Johnson-Neyman bounds from (A)
    local a = (`bAxz')^2 - (`crit')^2*`vii'
    local b = 2*(`bAx'*`bAxz' - (`crit')^2*`vxi')
    local c = (`bAx')^2 - (`crit')^2*`vxx'
    local disc = (`b')^2 - 4*`a'*`c'
    local jn1 = .
    local jn2 = .
    if `disc' >= 0 & `a' != 0 {
        local jn1 = min((-(`b') - sqrt(`disc'))/(2*`a'), (-(`b') + sqrt(`disc'))/(2*`a'))
        local jn2 = max((-(`b') - sqrt(`disc'))/(2*`a'), (-(`b') + sqrt(`disc'))/(2*`a'))
    }
    * theoretical spurious-interaction factor under bivariate normality
    local spur = 2*`rho'/(1 + (`rho')^2)

    if "`table'" == "" {
        di
        di as txt "Interaction analysis: effect of " as res "`x'" as txt " conditional on " as res "`z'"
        di as txt "Dependent variable: " as res "`y'" as txt "   Estimator: " as res "`estcmd' `estopt'" ///
            as txt cond("`dk'" != "", " (Driscoll-Kraay SE)", cond("`twoway'" != "", " (two-way clustered SE)", "")) as txt cond("`cce'" != "", " (CCE)", "") as txt "   N = " as res `N'
        di as txt "corr(`x', `z') = " as res %6.3f `rho' as txt ";  a pure x^2 effect b would load 2r/(1+r^2) = " ///
            as res %5.3f `spur' as txt " x b onto the product term under bivariate normality"
        di as txt "{hline 78}"
        di as txt "(A) linear interaction       : b(x*z) = " as res %9.4f `bAxz' as txt " (se " as res %7.4f `sAxz' ///
            as txt ", p = " as res %6.4f `pA' as txt ")"
        di as txt "(B) adding x^2 and z^2       : b(x*z) = " as res %9.4f `bBxz' as txt " (se " as res %7.4f `sBxz' ///
            as txt ", p = " as res %6.4f `pB' as txt ")"
        di as txt "    joint test x^2 = z^2 = 0 : F = " as res %7.3f `Fq' as txt ", p = " as res %6.4f `pq'
        di as txt "(N) linearity of interaction : F(" as res `nbins'-1 as txt ") = " as res %7.3f `Fbin' ///
            as txt ", p = " as res %6.4f `pbin' as txt "  (`nbins' moderator bins)"
        di as txt "{hline 78}"
        di as txt "Binned effects of `x' (C)    :"
        forvalues j = 0/`=`nbins'-1' {
            di as txt "   bin " `j'+1 ": median z = " as res %8.4f `zmed`j'' as txt ", share = " as res %5.3f `sh`j'' ///
                as txt ", effect = " as res %8.4f `bb`j'' as txt " (se " as res %7.4f `sb`j'' as txt ")"
        }
        di as txt "{hline 78}"
        di as txt "Moderator support: trimmed interval [" as res %8.4f `zl' as txt ", " as res %8.4f `zh' ///
            as txt "];  bandwidth " as res %6.4f `bw' as txt ";  min. local n " as res `mincount'
        if `nsup' > 0 {
            di as txt "Supported grid range for z   : [" as res %8.4f `zsup_lo' as txt ", " as res %8.4f `zsup_hi' ///
                as txt "]  (" as res `nsup' as txt " of " as res `ngrid' as txt " grid points)"
        }
        else di as txt "No grid point meets the support criteria"
        if !missing(`jn1') {
            di as txt "Johnson-Neyman bounds (A)    : z = " as res %8.4f `jn1' as txt " and " as res %8.4f `jn2' ///
                as txt cond(`jn1' < `zsup_lo' | `jn2' > `zsup_hi', "  (at least one bound outside supported range)", "")
        }
        else di as txt "Johnson-Neyman bounds (A)    : none (effect significance does not change with z)"
        di as txt "{hline 78}"
        di as txt "        z       effect     [`level'% CI]           local n  supported"
        foreach g of numlist 1 `=ceil(`ngrid'/4)' `=ceil(`ngrid'/2)' `=ceil(3*`ngrid'/4)' `ngrid' {
            di as res %9.4f `T'[`g',1] %11.4f `T'[`g',2] "  [" %8.4f `T'[`g',3] "," %8.4f `T'[`g',4] "]" ///
                %10.0f `T'[`g',5] "     " cond(`T'[`g',7]==1, "yes", "no")
        }
        di as txt "{hline 78}"
        if `pA' < 0.05 & `pB' >= 0.05 {
            di as txt "Note: the product term is not robust to own curvature terms; interpret (A) with caution."
        }
    }

    if "`graph'" != "" {
        preserve
        quietly {
            clear
            svmat double `T', names(col)
            gen double me_s = me if supported == 1
            gen double me_u = me if supported == 0
        }
        twoway (rarea lb ub z, color(gs13)) (line me_s z, lcolor(black)) ///
            (line me_u z, lcolor(black) lpattern(dash)), yline(0, lcolor(gs8)) ///
            xtitle("`z'") ytitle("Effect of `x'") ///
            legend(order(2 "supported" 3 "extrapolated") rows(1)) `graphopts'
        restore
    }

    return matrix grid = `T'
    return scalar N = `N'
    return scalar rho = `rho'
    return scalar b_xz_A = `bAxz'
    return scalar se_xz_A = `sAxz'
    return scalar p_xz_A = `pA'
    return scalar b_xz_B = `bBxz'
    return scalar se_xz_B = `sBxz'
    return scalar p_xz_B = `pB'
    return scalar F_quad = `Fq'
    return scalar p_quad = `pq'
    return scalar F_bin = `Fbin'
    return scalar p_bin = `pbin'
    return scalar jn_lb = `jn1'
    return scalar jn_ub = `jn2'
    return scalar zsup_lo = `zsup_lo'
    return scalar zsup_hi = `zsup_hi'
    return scalar spur_factor = `spur'
end
