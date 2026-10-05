*! xtmvardlurt_multivariate_graph  v1.0.0  03oct2026
*! Graphs after xtmvardlurt_multivariate: bootstrap distributions of t-bar and F-bar
*! and unit-level bootstrap p-values.
program define xtmvardlurt_multivariate_graph
	version 14
	syntax [, SCHeme(string) NOCombine]
	if "`e(cmd)'" != "xtmvardlurt_multivariate" {
		di as err "last estimates not found: run xtmvardlurt_multivariate first"
		exit 301
	}
	_xtmvu_load
	capture mata: st_numscalar("_xmu_chk2", rows(xmu_tbs))
	if _rc {
		di as err "bootstrap draws are no longer in memory; re-run xtmvardlurt_multivariate"
		exit 498
	}
	tempname P U
	matrix `P' = e(panel)
	matrix `U' = e(unit)
	local alpha = e(alpha)
	local pct = 100*e(alpha)
	local tobs = `P'[1,1]
	local tcv  = `P'[1,7]
	local fobs = `P'[4,1]
	local fcv  = `P'[4,7]
	local ptb  = `P'[1,2]
	local pfb  = `P'[4,2]
	local sch ""
	if "`scheme'" != "" local sch "scheme(`scheme')"
	preserve
	quietly drop _all
	mata: xmu_to_data("`U'")
	local tobsf : display %6.3f `tobs'
	local fobsf : display %6.3f `fobs'
	local ptf : display %5.3f `ptb'
	local pff : display %5.3f `pfb'
	quietly histogram tbs if !missing(tbs), xline(`tobs', lcolor(red) lwidth(medthick)) xline(`tcv', lcolor(black) lpattern(dash)) title("Bootstrap distribution of t-bar") subtitle("observed `tobsf' (red), `pct'% CV (dashed); p = `ptf'") xtitle("t-bar*") `sch' name(xmu_g1, replace) nodraw
	quietly histogram fbs if !missing(fbs), xline(`fobs', lcolor(red) lwidth(medthick)) xline(`fcv', lcolor(black) lpattern(dash)) title("Bootstrap distribution of F-bar") subtitle("observed `fobsf' (red), `pct'% CV (dashed); p = `pff'") xtitle("F-bar*") `sch' name(xmu_g2, replace) nodraw
	quietly twoway scatter upt uidx if !missing(upt), yline(`alpha', lcolor(red) lpattern(dash)) title("Unit-level p-values: t-test") xtitle("unit (order in table)") ytitle("bootstrap p-value") ylabel(0(.2)1) `sch' name(xmu_g3, replace) nodraw
	quietly twoway scatter upF uidx if !missing(upF), yline(`alpha', lcolor(red) lpattern(dash)) title("Unit-level p-values: F-test") xtitle("unit (order in table)") ytitle("bootstrap p-value") ylabel(0(.2)1) `sch' name(xmu_g4, replace) nodraw
	if "`nocombine'" == "" {
		graph combine xmu_g1 xmu_g2 xmu_g3 xmu_g4, cols(2) title("Panel multivariate ARDL unit root test") `sch' name(xmu_panel, replace)
	}
	else {
		graph display xmu_g1
		graph display xmu_g2
		graph display xmu_g3
		graph display xmu_g4
	}
	restore
end
