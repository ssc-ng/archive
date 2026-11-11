*! csdlp_graph 1.0.0  09nov2026
*! Graphs after csdlp: state-dependent IRFs with uniform bands, Lemma-1
*! diagnostic, and (h,z) response surface
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define csdlp_graph
    version 15.0
    if "`e(cmd)'" != "csdlp" {
        di as err "csdlp_graph requires {cmd:csdlp} results in memory"
        exit 301
    }
    syntax [, Horizons(numlist integer >=0) noLINear POINTwise LEMma      ///
              SURFace NAME(string) SAVing(string) XTitle(string)          ///
              YTitle(string) COLS(integer 0) noCOMBine ]

    tempname M
    matrix `M' = e(irf)
    local lev  = e(level)
    local lev2 = e(level2)
    local hall "`e(horizons)'"
    if "`horizons'" == "" {
        local nh : word count `hall'
        if `nh' <= 4 {
            local horizons `hall'
        }
        else {
            local i1 : word 1 of `hall'
            local i2 : word `=ceil(`nh'/3)' of `hall'
            local i3 : word `=ceil(2*`nh'/3)' of `hall'
            local i4 : word `nh' of `hall'
            local horizons `i1' `i2' `i3' `i4'
            local horizons : list uniq horizons
        }
    }
    foreach h of local horizons {
        local ok : list h in hall
        if !`ok' {
            di as err "horizon `h' was not estimated"
            exit 198
        }
    }
    if "`xtitle'" == "" {
        local xtitle "State: `e(state)'"
    }
    if "`ytitle'" == "" {
        local ytitle "Response of `e(depvar)'"
    }
    if "`name'" == "" {
        local name csdlp
    }
    local gs graphregion(color(white)) plotregion(color(white) lcolor(gs12)) ///
        ylabel(, angle(horizontal) labsize(small) grid glcolor(gs15) glpattern(solid)) ///
        xlabel(, labsize(small) grid glcolor(gs15) glpattern(solid))

    preserve
    qui {
        clear
        svmat double `M', names(col)
    }

    * ------------------------------------------------ Lemma-1 diagnostic
    if "`lemma'" != "" {
        local h : word 1 of `horizons'
        twoway (line gprime z if h==`h', lcolor(navy) lwidth(medthick)), ///
            yline(0, lcolor(gs10)) title("g{subscript:h}'(z), h = `h'", size(medium)) ///
            xtitle("`xtitle'") ytitle("Local slope of g{subscript:h}") `gs' ///
            name(`name'_d, replace) nodraw
        twoway (area omega z if h==`h', base(0) color(dkorange%40) lwidth(none)) ///
            (line omega z if h==`h', lcolor(dkorange)), legend(off)      ///
            title("Lemma 1 weight {&omega}{subscript:h}(z)", size(medium)) ///
            xtitle("`xtitle'") ytitle("Weight") `gs' name(`name'_w, replace) nodraw
        graph combine `name'_d `name'_w, cols(2) graphregion(color(white)) ///
            title("What the linear-interaction slope averages", size(medium)) ///
            note("Linear SD-LP slope = {&integral}{&omega}{subscript:h}(z) g{subscript:h}'(z) dz (Prop. 2)", size(small)) ///
            name(`name'_lemma, replace)
        if "`saving'" != "" {
            qui graph export "`saving'_lemma.png", replace width(2000)
        }
        restore
        exit
    }

    * ------------------------------------------------ surface
    if "`surface'" != "" {
        local nh : word count `hall'
        if `nh' < 2 {
            di as err "surface requires at least two estimated horizons"
            restore
            exit 198
        }
        capture noisily twoway contour g h z, levels(10)                    ///
            ccolors("53 42 135" "15 92 221" "18 125 216" "7 156 207"         ///
            "21 177 180" "89 189 140" "165 190 107" "225 185 82"             ///
            "252 206 46" "249 251 14" "249 251 14")                          ///
            xtitle("`xtitle'") ytitle("Horizon h") ztitle("g{subscript:h}(z)") ///
            title("State-dependent IRF surface", size(medium)) `gs'          ///
            name(`name'_surface, replace)
        if _rc {
            twoway contour g h z, levels(10) xtitle("`xtitle'")              ///
                ytitle("Horizon h") `gs' name(`name'_surface, replace)
        }
        if "`saving'" != "" {
            qui graph export "`saving'_surface.png", replace width(2000)
        }
        restore
        exit
    }

    * ------------------------------------------------ IRF panels (Fig. 3)
    local gl
    local k 0
    foreach h of local horizons {
        local k = `k' + 1
        local p1 (rarea u_lo u_hi z if h==`h', color(navy%18) lwidth(none))
        local lg1 1 "`lev'% uniform band"
        local p2
        local nxt 2
        if `lev2' > 0 {
            local p2 (rarea u2_lo u2_hi z if h==`h', color(navy%38) lwidth(none))
            local lg1 `lg1' 2 "`lev2'% uniform band"
            local nxt 3
        }
        local p3
        if "`pointwise'" != "" {
            local p3 (line pw_lo pw_hi z if h==`h', lcolor(navy navy) lpattern(shortdash shortdash) lwidth(thin thin))
            local nxt = `nxt' + 2
        }
        local p4 (line g z if h==`h', lcolor(navy) lwidth(medthick))
        local lg `lg1' `nxt' "Nonparametric (sieve)"
        local p5
        if "`linear'" == "" {
            local p5 (line glin z if h==`h', lcolor(cranberry) lpattern(dash) lwidth(medthick))
            local lg `lg' `=`nxt'+1' "Linear interaction"
        }
        twoway `p1' `p2' `p3' `p4' `p5', yline(0, lcolor(gs8) lpattern(solid)) ///
            title("h = `h'", size(medium)) xtitle("`xtitle'", size(small))    ///
            ytitle("`ytitle'", size(small)) `gs'                               ///
            legend(order(`lg') rows(2) size(small) position(6) ring(1) region(lcolor(white)))     ///
            name(`name'_h`h', replace) nodraw
        local gl `gl' `name'_h`h'
    }
    local ng : word count `gl'
    if `ng' == 1 | "`combine'" != "" {
        foreach g of local gl {
            graph display `g'
        }
        if "`saving'" != "" {
            qui graph export "`saving'.png", replace width(2000)
        }
    }
    else {
        if `cols' == 0 {
            local cols = cond(`ng' <= 2, `ng', 2)
        }
        local done 0
        capture which grc1leg2
        if !_rc {
            capture grc1leg2 `gl', cols(`cols') graphregion(color(white))    ///
                title("Causal state-dependent impulse responses", size(medium)) ///
                name(`name', replace)
            if !_rc {
                local done 1
            }
        }
        if !`done' {
            capture which grc1leg
            if !_rc {
                capture grc1leg `gl', cols(`cols') graphregion(color(white))  ///
                    title("Causal state-dependent impulse responses", size(medium)) ///
                    name(`name', replace)
                if !_rc {
                    local done 1
                }
            }
        }
        if !`done' {
            graph combine `gl', cols(`cols') graphregion(color(white))        ///
                title("Causal state-dependent impulse responses", size(medium)) ///
                name(`name', replace)
        }
        if "`saving'" != "" {
            qui graph export "`saving'.png", replace width(2400)
        }
    }
    restore
end
