*! _mvardlurt_multivariate_load  version 1.1.2  03oct2026
*! Makes sure the Mata functions of mvardlurt_multivariate are in memory.
*! They are kept in _mvardlurt_multivariate_mata.ado (core) and
*! _mvardlurt_multivariate_bmata.ado (bootstrap) and loaded with -do- when missing.

capture program drop _mvardlurt_multivariate_load
program define _mvardlurt_multivariate_load
    version 14
    syntax [, BOOT]

    capture mata: _mvu_chk = mvu_loaded()
    if _rc {
        quietly findfile _mvardlurt_multivariate_mata.ado
        local fcore `"`r(fn)'"'
        quietly do `"`fcore'"'
    }
    if "`boot'" != "" {
        capture mata: _mvu_chk = mvu_bloaded()
        if _rc {
            quietly findfile _mvardlurt_multivariate_bmata.ado
            local fboot `"`r(fn)'"'
            quietly do `"`fboot'"'
        }
    }
    capture mata: mata drop _mvu_chk
end
