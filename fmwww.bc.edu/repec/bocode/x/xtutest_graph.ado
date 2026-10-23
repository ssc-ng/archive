*! xtutest_graph  version 1.3.0  20oct2026
*! Graphs after xtutest:
*!   xtu_curve  mean curve b1 x + b2 x^2 with a pointwise interval, the interval [xL, xH],
*!              and the turning point with its Fieller interval
*!   xtu_tp     histogram of the unit turning points (units with the relevant curvature)
*!   xtu_panel  both

capture program drop xtutest_graph
program define xtutest_graph
    version 14
    syntax [, SCHeme(string) NOCombine RANge(numlist min=2 max=2 ascending)]
    if "`e(cmd)'" != "xtutest" {
        di as err "last estimates not found; run xtutest first"
        exit 301
    }
    _xtutest_load
    if "`scheme'" == "" local scheme "s2color"
    local x "`e(xvar)'"
    if "`range'" == "" {
        qui su `x' if e(sample), meanonly
        local lo = r(min)
        local hi = r(max)
    }
    else {
        local lo : word 1 of `range'
        local hi : word 2 of `range'
    }
    local lev = e(level)
    local df  = cond(e(normal) | e(df) >= ., ., e(df))
    local tp  = e(tp)
    local xL  = e(xL)
    local xH  = e(xH)
    local tpl ""
    if `tp' >= `lo' & `tp' <= `hi' local tpl "xline(`tp', lcolor(red))"
    local fl ""
    if e(f_bounded) == 1 {
        if e(f_lo) >= `lo' & e(f_lo) <= `hi' local fl "`fl' `=e(f_lo)'"
        if e(f_hi) >= `lo' & e(f_hi) <= `hi' local fl "`fl' `=e(f_hi)'"
    }
    if "`fl'" != "" local fl "xline(`fl', lcolor(red) lpattern(dash))"
    local nd = cond("`nocombine'" == "", "nodraw", "")
    local gr "graphregion(color(white)) scheme(`scheme')"
    tempname U
    capture matrix `U' = e(units)
    local hasu = (_rc == 0)
    local glist ""

    preserve
    drop _all
    mata: xtu_curve(`lo', `hi', 200, `lev', `df')
    capture twoway (rarea flo fhi xg, color(gs13)) (line fg xg, lcolor(navy) lwidth(medthick)), ///
        xline(`xL' `xH', lcolor(gs8) lpattern(shortdash)) `tpl' `fl' ///
        title("Mean curve of `e(depvar)' in `x'", size(medium)) ///
        subtitle("`lev'% pointwise band; red = turning point and Fieller interval", size(vsmall)) ///
        xtitle("`x'") ytitle("b1 x + b2 x{superscript:2}") legend(off) `gr' name(xtu_curve, replace) `nd'
    if _rc == 0 local glist "`glist' xtu_curve"
    drop _all
    if `hasu' {
    qui svmat double `U', names(col)
    qui keep if curvature == 1
    qui keep if inrange(tp, `lo' - (`hi' - `lo'), `hi' + (`hi' - `lo'))
    if _N >= 5 {
        capture histogram tp, bin(`=min(20, max(5, floor(_N/2)))') fcolor(ltblue) lcolor(navy) ///
            xline(`=e(tp_median)', lcolor(red)) ///
            title("Unit turning points", size(medium)) subtitle("units with the relevant curvature, within the data range widened by its width; red = median", size(vsmall)) ///
            xtitle("turning point") `gr' name(xtu_tp, replace) `nd'
        if _rc == 0 local glist "`glist' xtu_tp"
    }
    }
    restore
    local ng : word count `glist'
    if "`nocombine'" == "" & `ng' >= 1 {
        if `ng' == 2 graph combine `glist', cols(2) `gr' name(xtu_panel, replace)
        else graph display `glist'
    }
    di as txt _col(3) "Graphs in memory:" as res "`glist'"
end
