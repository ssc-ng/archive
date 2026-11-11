*! _hansenstab_load  version 1.0.0  21oct2026
*! Makes sure the Mata functions of hansenstab are in memory. They are kept in
*! _hansenstab_mata.ado and loaded with -do- when missing or out of date.

capture program drop _hansenstab_load
program define _hansenstab_load
    version 14
    scalar _hst_ver = 0
    capture mata: st_numscalar("_hst_ver", hst_loaded())
    if scalar(_hst_ver) != 102 {
        capture mata: mata drop hst_*()
        quietly findfile _hansenstab_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _hst_ver
end
