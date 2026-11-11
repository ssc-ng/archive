*! _xtcollin_load  version 1.0.0  21oct2026
*! Makes sure the Mata functions of xtcollin are in memory. They are kept in
*! _xtcollin_mata.ado and loaded with -do- when missing or out of date.

capture program drop _xtcollin_load
program define _xtcollin_load
    version 14
    scalar _xtc_ver = 0
    capture mata: st_numscalar("_xtc_ver", xtc_loaded())
    if scalar(_xtc_ver) != 101 {
        capture mata: mata drop xtc_*()
        capture mata: mata drop _xtc_*()
        quietly findfile _xtcollin_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _xtc_ver
end
