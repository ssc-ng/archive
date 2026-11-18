*! Request preparation with cohort-specific reference eligibility; private.
*! Under missingreference(exclude), a preparation that finds a required
*! time-varying covariate missing records the restricted contexts (or the
*! unavailable pretrend comparisons) and is repeated once they are known.
program define _cdid_request_prepare_mref, rclass
    version 19.5
    local pass=0
    while 1 {
        capture noisily _cdid_request_prepare `0'
        local rc=_rc
        if `rc'==0 {
            return add
            exit
        }
        local pending 0
        capture mata: st_local("pending",strofreal(cdid_mref_pending()))
        if "`pending'"!="1" | `pass'>=3 exit `rc'
        mata: cdid_mref_clear_pending()
        local ++pass
    }
end
