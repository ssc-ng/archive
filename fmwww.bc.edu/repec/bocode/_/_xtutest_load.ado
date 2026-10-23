*! _xtutest_load  version 1.3.0  20oct2026
*! Makes sure the Mata functions of xtutest are in memory. They are kept in
*! _xtutest_mata.ado and loaded with -do- when missing or out of date.

capture program drop _xtutest_load
program define _xtutest_load
    version 14
    scalar _xtu_ver = 0
    capture mata: st_numscalar("_xtu_ver", xtu_loaded())
    if scalar(_xtu_ver) != 130 {
        capture mata: mata drop xtu_*()
        capture mata: mata drop xtu_*
        quietly findfile _xtutest_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _xtu_ver
end
