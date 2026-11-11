*! _tsnormal_load  version 1.0.0  21oct2026
*! Makes sure the Mata functions of tsnormal are in memory. They are kept in
*! _tsnormal_mata.ado and loaded with -do- when missing or out of date.

capture program drop _tsnormal_load
program define _tsnormal_load
    version 14
    scalar _tsn_ver = 0
    capture mata: st_numscalar("_tsn_ver", tsn_loaded())
    if scalar(_tsn_ver) != 100 {
        capture mata: mata drop tsn_*()
        quietly findfile _tsnormal_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    capture scalar drop _tsn_ver
end
