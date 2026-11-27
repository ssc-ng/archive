*! _xtqqr_load 1.0.0  25nov2026
*! Loads the Mata engine of the xtqqr package (lxtqqr.ado) once per session
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
program _xtqqr_load
    version 14.0
    capture mata: xqq_loaded()
    if _rc {
        quietly findfile lxtqqr.ado
        quietly do `"`r(fn)'"'
    }
end
