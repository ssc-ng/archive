*! _xtmvu_load  v1.0.0  03oct2026  Yusuf Toyin Yusuf
*! Loads the Mata engine of xtmvardlurt_multivariate on demand.
program define _xtmvu_load
	version 14
	capture mata: _xmu_chk = xmu_loaded()
	if _rc {
		quietly findfile _xtmvu_mata.ado
		quietly do "`r(fn)'"
	}
	capture mata: mata drop _xmu_chk
end
