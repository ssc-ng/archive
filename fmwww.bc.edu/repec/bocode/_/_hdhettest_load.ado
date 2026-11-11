*! _hdhettest_load  version 1.1.0  10nov2026
*! Makes sure the Mata functions of hdhettest are in memory. They are kept in
*! _hdhettest_mata.ado and loaded with -do- when missing or out of date.

capture program drop _hdhettest_load
program define _hdhettest_load
    version 14
    scalar _hdh_ver = 0
    capture mata: st_numscalar("_hdh_ver", hdh_loaded())
    if scalar(_hdh_ver) != 110 {
        capture mata: mata drop hdh_*()
        quietly findfile _hdhettest_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _hdh_ver
end
