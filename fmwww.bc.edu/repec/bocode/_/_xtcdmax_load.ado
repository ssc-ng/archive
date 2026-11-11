*! _xtcdmax_load  version 1.0.0  21oct2026
*! Makes sure the Mata functions of xtcdmax are in memory. They are kept in
*! _xtcdmax_mata.ado and loaded with -do- when missing or out of date.

capture program drop _xtcdmax_load
program define _xtcdmax_load
    version 14
    scalar _xcd_ver = 0
    capture mata: st_numscalar("_xcd_ver", xcd_loaded())
    if scalar(_xcd_ver) != 100 {
        capture mata: mata drop xcd_*()
        quietly findfile _xtcdmax_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _xcd_ver
end
