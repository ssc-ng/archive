*! _fmvardlurt_load  version 1.0.0  13oct2026
*! Makes sure the Mata functions of fmvardlurt are in memory. They are kept in
*! _fmvardlurt_mata.ado and loaded with -do- when missing or out of date.

capture program drop _fmvardlurt_load
program define _fmvardlurt_load
    version 14
    scalar _fmv_ver = 0
    capture mata: st_numscalar("_fmv_ver", fmv_loaded())
    if scalar(_fmv_ver) != 100 {
        capture mata: mata drop fmv_*()
        capture mata: mata drop fmv_*
        quietly findfile _fmvardlurt_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _fmv_ver
end
