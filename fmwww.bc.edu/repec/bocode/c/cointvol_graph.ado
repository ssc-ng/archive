*! cointvol_graph 0.1.0  26sep2026
*! Publication graphs from cointvol results in memory
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*!   bootdist    bootstrap distributions of the rank statistics (after cointvol rank)
*!               or of the LR / Wald statistics (after cointvol restrict)
*!   ic          information criteria by lag and rank (after cointvol select)
*!   ect         error-correction term(s) (after cointvol vecmgarch / restrict)
*!   volatility  conditional standard deviations (after cointvol vecmgarch)
*!   correlation conditional correlations (after cointvol vecmgarch)
*!   varprofile  variance profiles of VECM residuals (runs cointvol diag)

program define cointvol_graph
    version 14.0
    gettoken type 0 : 0, parse(" ,")
    local type = strlower(`"`type'"')
    if `"`type'"' == "" {
        di as err "cointvol graph requires a graph type:"
        di as err "  bootdist | ic | ect | volatility | correlation | varprofile"
        exit 198
    }
    if `"`type'"' == "bootdist" {
        _cvg_bootdist `0'
    }
    else if `"`type'"' == "ic" {
        _cvg_ic `0'
    }
    else if inlist(`"`type'"', "ect", "volatility", "vol", "correlation", "corr") {
        _cvg_vecm `type' `0'
    }
    else if `"`type'"' == "varprofile" {
        _cvg_varprofile `0'
    }
    else {
        di as err `"unknown graph type `type'"'
        exit 198
    }
end

// ---------------------------------------------------------------------------
// common look
// ---------------------------------------------------------------------------
program define _cvg_style, rclass
    syntax [, MONO]
    if "`mono'" != "" {
        return local c1 "black"
        return local c2 "gs6"
        return local c3 "gs10"
        return local fill "gs14"
    }
    else {
        return local c1 "navy"
        return local c2 "cranberry"
        return local c3 "dkgreen"
        return local fill "ltbluishgray"
    }
end

// ---------------------------------------------------------------------------
// bootdist
// ---------------------------------------------------------------------------
program define _cvg_bootdist
    syntax [, STATistic(string) NAME(string) SAVing(string) MONO]
    if "`statistic'" == "" local statistic "trace"
    tempname B S
    local src ""
    capture confirm matrix r(boot_trace)
    if _rc == 0 & "`r(cmd)'" == "cointvol rank" {
        if "`statistic'" == "maxeig" {
            matrix `B' = r(boot_max)
            local sc 8
            local slab "max-eigenvalue"
        }
        else {
            matrix `B' = r(boot_trace)
            local sc 3
            local slab "trace"
        }
        matrix `S' = r(stats)
        local src "rank"
        local pc = cond("`statistic'" == "maxeig", 10, 5)
        local mlab "`r(method)' bootstrap, `r(algorithm)', B = `r(reps)'"
    }
    else if "`e(cmd)'" == "cointvol restrict" {
        capture confirm matrix e(boot_lr)
        if _rc {
            di as err "no bootstrap distribution in e(); rerun cointvol restrict with method(wild) or method(iid)"
            exit 301
        }
        local src "restrict"
        if "`statistic'" == "wald" {
            matrix `B' = e(boot_wald)
            local obs = e(wald)
            local pb = e(wald_p_boot)
            local slab "Wald"
        }
        else {
            matrix `B' = e(boot_lr)
            local obs = e(lr)
            local pb = e(lr_p_boot)
            local slab "PLR"
        }
        local mlab "`e(method)' bootstrap, B = `e(reps)'"
    }
    else {
        di as err "no bootstrap results in memory: run {cmd:cointvol rank} (bootstrap) or {cmd:cointvol restrict} (bootstrap) immediately before"
        exit 301
    }
    _cvg_style, `mono'
    local c1 "`r(c1)'"
    local c2 "`r(c2)'"
    local fill "`r(fill)'"
    preserve
    qui clear
    local K = colsof(`B')
    qui svmat double `B', names(q)
    local glist ""
    if "`src'" == "rank" {
        forvalues i = 1/`K' {
            local r   = `S'[`i', 1]
            local obs = `S'[`i', `sc']
            local pb  : display %5.3f `S'[`i', `pc']
            local ob  : display %8.2f `obs'
            qui summarize q`i', meanonly
            local xlo = min(r(min), `obs')
            local xhi = max(r(max), `obs') * 1.03
            tempname g`i'
            qui twoway (histogram q`i', color(`fill') lcolor(gs11)) ///
                (kdensity q`i', lcolor(`c1') lwidth(medthin)), ///
                xline(`obs', lcolor(`c2') lwidth(medthick) lpattern(dash)) ///
                xscale(range(`xlo' `xhi')) ///
                title("H0: r = `r'", size(medsmall)) ///
                subtitle("observed = `ob', bootstrap p = `pb'", size(small)) ///
                xtitle("bootstrap `slab' statistic", size(small)) ytitle("density", size(small)) ///
                legend(off) graphregion(color(white)) plotregion(color(white)) name(`g`i'', replace) nodraw
            local glist "`glist' `g`i''"
        }
        if "`name'" == "" local name "cointvol_bootdist"
        graph combine `glist', graphregion(color(white)) ///
            title("Bootstrap distributions of the `slab' statistic", size(medium)) ///
            note("Dashed line: observed statistic. `mlab'.", size(vsmall)) name(`name', replace)
    }
    else {
        local pbs : display %5.3f `pb'
        local ob  : display %8.2f `obs'
        qui summarize q1, meanonly
        local xlo = min(r(min), `obs')
        local xhi = max(r(max), `obs') * 1.03
        if "`name'" == "" local name "cointvol_bootdist"
        twoway (histogram q1, color(`fill') lcolor(gs11)) (kdensity q1, lcolor(`c1')), ///
            xline(`obs', lcolor(`c2') lwidth(medthick) lpattern(dash)) xscale(range(`xlo' `xhi')) ///
            title("Bootstrap distribution of the `slab' statistic", size(medium)) ///
            subtitle("observed = `ob', bootstrap p = `pbs'", size(small)) ///
            xtitle("bootstrap `slab' statistic") ytitle("density") legend(off) ///
            note("Dashed line: observed statistic. `mlab'.", size(vsmall)) ///
            graphregion(color(white)) plotregion(color(white)) name(`name', replace)
    }
    restore
    if `"`saving'"' != "" {
        graph export `saving', name(`name') replace
    }
end

// ---------------------------------------------------------------------------
// ic grid (after cointvol select)
// ---------------------------------------------------------------------------
program define _cvg_ic
    syntax [, IC(string) NAME(string) SAVing(string) MONO]
    if "`r(cmd)'" != "cointvol select" {
        di as err "run {cmd:cointvol select} immediately before {cmd:cointvol graph ic}"
        exit 301
    }
    local mats : r(matrices)
    if "`ic'" == "" {
        foreach c in bic hqc aic {
            if `: list posof "IC_`c'" in mats' {
                local ic "`c'"
                continue, break
            }
        }
    }
    capture confirm matrix r(IC_`ic')
    if _rc {
        di as err "r(IC_`ic') not found; available: `mats'"
        exit 301
    }
    tempname M
    matrix `M' = r(IC_`ic')
    local nk = rowsof(`M')
    local nr = colsof(`M')
    preserve
    qui clear
    qui svmat double `M', names(r)
    qui gen lag = _n
    local plots ""
    local leg ""
    forvalues j = 1/`nr' {
        local rr = `j' - 1
        local pat = cond(mod(`j', 2), "solid", "dash")
        local plots "`plots' (connected r`j' lag, lpattern(`pat') msize(small))"
        local leg `"`leg' `j' "r = `rr'""'
    }
    if "`name'" == "" local name "cointvol_ic"
    local ICU = strupper("`ic'")
    twoway `plots', legend(order(`leg') rows(1) size(small) position(6)) ///
        xtitle("lag order k (levels VAR)") ytitle("`ICU'(k, r)") xlabel(1(1)`nk') ///
        title("Information criterion by lag order and cointegration rank", size(medium)) ///
        note("Minimum of the surface gives the joint choice of (k, r); Cavaliere et al. (2018).", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white)) name(`name', replace)
    restore
    if `"`saving'"' != "" {
        graph export `saving', name(`name') replace
    }
end

// ---------------------------------------------------------------------------
// ect / volatility / correlation (after vecmgarch; ect also after restrict)
// ---------------------------------------------------------------------------
program define _cvg_vecm
    gettoken type 0 : 0
    syntax [, NAME(string) SAVing(string) MONO]
    _cvg_style, `mono'
    local c1 "`r(c1)'"
    local c2 "`r(c2)'"
    local c3 "`r(c3)'"
    local ok 0
    if "`e(cmd)'" == "cointvol vecmgarch" local ok 1
    if "`e(cmd)'" == "cointvol restrict" & "`type'" == "ect" local ok 1
    if !`ok' {
        di as err "graph `type' requires {cmd:cointvol vecmgarch} results in memory"
        if "`type'" == "ect" di as err "(or {cmd:cointvol restrict})"
        exit 301
    }
    qui tsset
    local tvar "`r(timevar)'"
    local vars "`e(varlist)'"
    if "`vars'" == "" local vars "`e(depvar)'"
    local p : word count `vars'
    local r = e(rank)
    if "`name'" == "" local name "cointvol_`type'"
    local plots ""
    local leg ""
    local cols "`c1' `c2' `c3' orange purple teal"
    if "`type'" == "ect" {
        if `r' == . | `r' < 1 {
            di as err "no cointegrating relation (rank 0)"
            exit 498
        }
        forvalues j = 1/`r' {
            tempvar e`j'
            qui predict double `e`j'' if e(sample), ect eq(`j')
            local cc : word `j' of `cols'
            local plots "`plots' (tsline `e`j'', lcolor(`cc') lwidth(thin))"
            local leg `"`leg' `j' "ECT `j'""'
        }
        local ytit "beta' X(t-1) (+ restricted deterministics)"
        local tit "Estimated error-correction term(s)"
    }
    else if inlist("`type'", "volatility", "vol") {
        forvalues j = 1/`p' {
            tempvar s`j'
            qui predict double `s`j'' if e(sample), sd eq(`j')
            local vn : word `j' of `vars'
            local cc : word `j' of `cols'
            local plots "`plots' (tsline `s`j'', lcolor(`cc') lwidth(thin))"
            local leg `"`leg' `j' "`vn'""'
        }
        local ytit "conditional standard deviation"
        local tit "Conditional volatility (`e(variance)')"
    }
    else {
        if `p' < 2 {
            di as err "correlation needs at least two equations"
            exit 498
        }
        local k 0
        forvalues i = 1/`p' {
            forvalues j = `=`i'+1'/`p' {
                local k = `k' + 1
                tempvar q`k'
                qui predict double `q`k'' if e(sample), correlation eq(`i' `j')
                local vi : word `i' of `vars'
                local vj : word `j' of `vars'
                local cc : word `=mod(`k'-1, 6)+1' of `cols'
                local plots "`plots' (tsline `q`k'', lcolor(`cc') lwidth(thin))"
                local leg `"`leg' `k' "`vi'-`vj'""'
            }
        }
        local ytit "conditional correlation"
        local tit "Conditional correlations (`e(variance)')"
    }
    twoway `plots', yline(0, lcolor(gs12)) legend(order(`leg') rows(1) size(small) position(6)) ///
        ytitle("`ytit'") xtitle("") title("`tit'", size(medium)) ///
        note("Source: `e(cmd)'.", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white)) name(`name', replace)
    if `"`saving'"' != "" {
        graph export `saving', name(`name') replace
    }
end

// ---------------------------------------------------------------------------
// varprofile: delegate to cointvol diag
// ---------------------------------------------------------------------------
program define _cvg_varprofile
    syntax varlist(numeric ts min=1) [if] [in], Lags(integer) [TRend(string) RANK(string) NAME(string) *]
    local ro ""
    if "`rank'" != "" local ro "rank(`rank')"
    local to ""
    if "`trend'" != "" local to "trend(`trend')"
    local no ""
    if "`name'" != "" local no "graphname(`name')"
    cointvol_diag `varlist' `if' `in', lags(`lags') `to' `ro' varprofile graph `no' `options'
end
