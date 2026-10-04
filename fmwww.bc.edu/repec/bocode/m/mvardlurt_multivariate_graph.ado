*! mvardlurt_multivariate_graph  version 1.1.2  03oct2026
*! Graphs after mvardlurt_multivariate (also run unless nograph is specified)
*!   mvu_levels   series in levels
*!   mvu_boot_t   bootstrap distribution of the t-statistic
*!   mvu_boot_f   bootstrap distribution of the F-statistic
*!   mvu_resfit   residuals vs fitted values
*!   mvu_reshist  residual histogram + kernel density
*!   mvu_cusum    CUSUM of recursive residuals (5% bands)
*!   mvu_panel    combined panel

capture program drop mvardlurt_multivariate_graph
program define mvardlurt_multivariate_graph
    version 14
    syntax [, SCHeme(string) NOCombine]

    if "`e(cmd)'" != "mvardlurt_multivariate" {
        di as err "last estimates not found; run mvardlurt_multivariate first"
        exit 301
    }
    _mvardlurt_multivariate_load

    if "`scheme'" == "" local scheme "s2color"

    local depvar "`e(depvar)'"
    local indep  "`e(indepvars)'"
    local p      = e(opt_p)
    local oqq    "`e(opt_q)'"
    local qtxt : subinstr local oqq " " ",", all
    local boot   = e(boot)
    local tstat  = e(tstat)
    local fstat  = e(fstat)
    local cname  "`e(casename)'"
    local sub    "ARDL(`p'; `qtxt')  -  `cname'"
    local tobs : di %6.3f `tstat'
    local fobs : di %6.3f `fstat'
    local tobs = strtrim("`tobs'")
    local fobs = strtrim("`fobs'")

    // everything needed from e() is read before the dataset is emptied
    local t05 = .
    local t01 = .
    local f05 = .
    local f01 = .
    if `boot' == 1 {
        tempname cv
        matrix `cv' = e(cv)
        local t05 = el(`cv', 1, 2)
        local t01 = el(`cv', 1, 4)
        local f05 = el(`cv', 2, 2)
        local f01 = el(`cv', 2, 4)
    }

    local nd "nodraw"
    if "`nocombine'" != "" local nd ""
    local glist ""

    // 1. series in levels (uses the data in memory, so it comes first)
    capture tsline `depvar' `indep' if e(sample), ///
        title("Series in levels", size(medium)) subtitle("`depvar' and covariates", size(small)) ///
        xtitle("") ytitle("") legend(size(vsmall) rows(1)) ///
        graphregion(color(white)) scheme(`scheme') name(mvu_levels, replace) `nd'
    if _rc == 0 local glist "`glist' mvu_levels"

    // 2. the rest comes from objects stored in Mata
    preserve
    drop _all
    local mvu_err ""
    capture mata: mvu_to_data()
    if _rc | "`mvu_err'" != "" {
        restore
        di as txt _col(3) "(Mata results not in memory, only the levels graph was drawn;"
        di as txt _col(3) " re-run mvardlurt_multivariate to redraw all graphs)"
        if "`glist'" != "" & "`nocombine'" == "" graph display mvu_levels
        exit
    }

    if `boot' == 1 {
        capture twoway (histogram tboot, bin(40) fcolor(ltblue) lcolor(navy)), ///
            xline(`tstat', lcolor(red) lwidth(medthick)) ///
            xline(`t05', lcolor(black) lpattern(dash)) ///
            xline(`t01', lcolor(gs8) lpattern(shortdash)) ///
            title("Bootstrap t-statistic (H0: pi = 0)", size(medium)) ///
            subtitle("red = observed (`tobs'); dashed = 5% and 1% critical values", size(vsmall)) ///
            xtitle("t*") ytitle("Density") legend(off) ///
            graphregion(color(white)) scheme(`scheme') name(mvu_boot_t, replace) `nd'
        if _rc == 0 local glist "`glist' mvu_boot_t"

        capture twoway (histogram fboot, bin(40) fcolor(ltblue) lcolor(navy)), ///
            xline(`fstat', lcolor(red) lwidth(medthick)) ///
            xline(`f05', lcolor(black) lpattern(dash)) ///
            xline(`f01', lcolor(gs8) lpattern(shortdash)) ///
            title("Bootstrap F-statistic (H0: delta = 0)", size(medium)) ///
            subtitle("red = observed (`fobs'); dashed = 5% and 1% critical values", size(vsmall)) ///
            xtitle("F*") ytitle("Density") legend(off) ///
            graphregion(color(white)) scheme(`scheme') name(mvu_boot_f, replace) `nd'
        if _rc == 0 local glist "`glist' mvu_boot_f"
    }

    capture twoway (scatter res fit, mcolor(navy) msize(small)) ///
        (lowess res fit, lcolor(red) lwidth(medthick)), ///
        yline(0, lcolor(gs8) lpattern(dash)) ///
        title("Residuals vs fitted", size(medium)) subtitle("`sub'", size(vsmall)) ///
        xtitle("Fitted D.`depvar'") ytitle("Residuals") legend(off) ///
        graphregion(color(white)) scheme(`scheme') name(mvu_resfit, replace) `nd'
    if _rc == 0 local glist "`glist' mvu_resfit"

    capture twoway (histogram res, bin(15) fcolor(ltblue) lcolor(navy)) ///
        (kdensity res, lcolor(red) lwidth(medthick)), ///
        title("Residual distribution", size(medium)) subtitle("`sub'", size(vsmall)) ///
        xtitle("Residuals") ytitle("Density") legend(off) ///
        graphregion(color(white)) scheme(`scheme') name(mvu_reshist, replace) `nd'
    if _rc == 0 local glist "`glist' mvu_reshist"

    capture twoway (line cusum cobs, lcolor(navy) lwidth(medthick)) ///
        (line ub cobs, lcolor(red) lpattern(dash)) ///
        (line lb cobs, lcolor(red) lpattern(dash)), ///
        yline(0, lcolor(gs10)) ///
        title("CUSUM of recursive residuals", size(medium)) subtitle("5% significance bands", size(vsmall)) ///
        xtitle("Observation in estimation sample") ytitle("CUSUM") legend(off) ///
        graphregion(color(white)) scheme(`scheme') name(mvu_cusum, replace) `nd'
    if _rc == 0 local glist "`glist' mvu_cusum"

    restore

    // 3. combined panel
    local ng : word count `glist'
    if "`nocombine'" == "" & `ng' >= 2 {
        capture graph combine `glist', cols(2) ///
            title("Multivariate ARDL unit root test: `depvar'", size(medsmall)) ///
            subtitle("Sam, McNown, Goh and Goh (2024)", size(small)) ///
            graphregion(color(white)) scheme(`scheme') name(mvu_panel, replace)
        if _rc di as txt _col(3) "(combined panel could not be drawn)"
    }
    di as txt _col(3) "Graphs in memory:" as res "`glist'"
end
