*! _xtmvu_load  v1.0.6  11oct2026  Yusuf Toyin Yusuf
*! Loads the Mata engine of xtmvardlurt_multivariate on demand. Reloads it when the copy in
*! memory is older: Mata functions stay in memory until Stata is restarted or -mata clear- is run,
*! and Mata does not allow a function to be defined twice, so the old copy is cleared first.
program define _xtmvu_load
	version 14
	scalar _xmu_ver = 0
	capture mata: st_numscalar("_xmu_ver", xmu_loaded())
	if _rc | scalar(_xmu_ver) != 106 {
		capture mata: mata clear
		quietly findfile _xtmvu_mata.ado
		quietly do "`r(fn)'"
	}
	capture scalar drop _xmu_ver
end
