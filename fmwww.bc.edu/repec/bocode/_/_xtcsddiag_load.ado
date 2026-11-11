*! _xtcsddiag_load  version 1.0.0  21oct2026
*! Makes sure the Mata functions of xtcsddiag are in memory. They are kept in
*! _xtcsddiag_mata.ado and loaded with -do- when missing or out of date.

capture program drop _xtcsddiag_load
program define _xtcsddiag_load
    version 14
    scalar _xcs_ver = 0
    capture mata: st_numscalar("_xcs_ver", xcs_loaded())
    if scalar(_xcs_ver) != 100 {
        capture mata: mata drop xcs_*()
        quietly findfile _xtcsddiag_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _xcs_ver
end
