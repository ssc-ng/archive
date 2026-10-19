*! fmvardlurt_graph  version 1.0.0  13oct2026
*! Graphs after fmvardlurt (drawn unless nograph is specified)
*!   fmv_fourier  D.y, fitted values and the fitted Fourier component
*!   fmv_boot_t   bootstrap distribution of t*, observed value and 5%/1% critical values
*!   fmv_boot_f   bootstrap distribution of F*
*!   fmv_boot_ff  bootstrap distribution of the Fourier F* (when Fourier terms are in the model)
*!   fmv_cusum    CUSUM of recursive residuals with 5% bands
*!   fmv_panel    combined panel

capture program drop fmvardlurt_graph
program define fmvardlurt_graph
    version 14
    syntax [, SCHeme(string) NOCombine]
    if "`e(cmd)'" != "fmvardlurt" {
        di as err "last estimates not found; run fmvardlurt first"
        exit 301
    }
    if e(boot) != 1 {
        di as err "graphs need the bootstrap results; re-run fmvardlurt without noboot"
        exit 198
    }
    _fmvardlurt_load
    if "`scheme'" == "" local scheme "s2color"

    local depvar "`e(depvar)'"
    local fk  = e(freq)
    local ts  = e(tstat)
    local fs  = e(fstat)
    local ffs = e(ffstat)
    tempname cv
    matrix `cv' = e(cv)
    local t05  = el(`cv', 1, 2)
    local t01  = el(`cv', 1, 4)
    local f05  = el(`cv', 2, 2)
    local f01  = el(`cv', 2, 4)
    local ff05 = el(`cv', 3, 2)
    local ff01 = el(`cv', 3, 4)
    local nd = cond("`nocombine'" == "", "nodraw", "")
    local gr "graphregion(color(white)) scheme(`scheme')"
    local glist ""

    preserve
    drop _all
    local fmv_err ""
    capture mata: fmv_to_data()
    if _rc | "`fmv_err'" != "" {
        restore
        di as err "results not in memory (was Mata cleared?); re-run fmvardlurt"
        exit 498
    }

    if `fk' > 0 {
        capture twoway (line dy obs, lcolor(gs10)) (line fit obs, lcolor(navy)) ///
            (line four obs, lcolor(red) lwidth(medthick)), ///
            title("D.`depvar' and the Fourier component (k = `fk')", size(medium)) ///
            legend(order(1 "D.`depvar'" 2 "fitted" 3 "Fourier component") rows(1) size(vsmall)) ///
            xtitle("Observation in estimation sample") ytitle("") `gr' name(fmv_fourier, replace) `nd'
        if _rc == 0 local glist "`glist' fmv_fourier"
    }
    capture twoway (histogram tboot, bin(40) fcolor(ltblue) lcolor(navy)), ///
        xline(`ts', lcolor(red) lwidth(medthick)) xline(`t05', lcolor(black) lpattern(dash)) ///
        xline(`t01', lcolor(gs8) lpattern(shortdash)) ///
        title("Bootstrap t* (H0: unit root)", size(medium)) ///
        subtitle("red = observed; dashed = 5% and 1% critical values", size(vsmall)) ///
        xtitle("t*") legend(off) `gr' name(fmv_boot_t, replace) `nd'
    if _rc == 0 local glist "`glist' fmv_boot_t"
    capture twoway (histogram fboot, bin(40) fcolor(ltblue) lcolor(navy)), ///
        xline(`fs', lcolor(red) lwidth(medthick)) xline(`f05', lcolor(black) lpattern(dash)) ///
        xline(`f01', lcolor(gs8) lpattern(shortdash)) ///
        title("Bootstrap F* (H0: no level relation)", size(medium)) ///
        subtitle("red = observed; dashed = 5% and 1% critical values", size(vsmall)) ///
        xtitle("F*") legend(off) `gr' name(fmv_boot_f, replace) `nd'
    if _rc == 0 local glist "`glist' fmv_boot_f"
    if `fk' > 0 {
        capture twoway (histogram ffboot, bin(40) fcolor(ltblue) lcolor(navy)), ///
            xline(`ffs', lcolor(red) lwidth(medthick)) xline(`ff05', lcolor(black) lpattern(dash)) ///
            xline(`ff01', lcolor(gs8) lpattern(shortdash)) ///
            title("Bootstrap Fourier F* (H0: no Fourier component)", size(medium)) ///
            subtitle("red = observed; dashed = 5% and 1% critical values", size(vsmall)) ///
            xtitle("F* (sin, cos)") legend(off) `gr' name(fmv_boot_ff, replace) `nd'
        if _rc == 0 local glist "`glist' fmv_boot_ff"
    }
    capture twoway (line cusum cobs, lcolor(navy) lwidth(medthick)) ///
        (line ub cobs, lcolor(red) lpattern(dash)) (line lb cobs, lcolor(red) lpattern(dash)), ///
        yline(0, lcolor(gs10)) title("CUSUM of recursive residuals", size(medium)) ///
        subtitle("5% bands", size(vsmall)) xtitle("Observation") ytitle("CUSUM") legend(off) ///
        `gr' name(fmv_cusum, replace) `nd'
    if _rc == 0 local glist "`glist' fmv_cusum"
    restore

    local ng : word count `glist'
    if "`nocombine'" == "" & `ng' >= 2 {
        capture graph combine `glist', cols(2) title("Fourier multivariate ARDL test: `depvar'", size(medsmall)) ///
            `gr' name(fmv_panel, replace)
        if _rc di as txt _col(3) "(combined panel could not be drawn)"
    }
    di as txt _col(3) "Graphs in memory:" as res "`glist'"
end
