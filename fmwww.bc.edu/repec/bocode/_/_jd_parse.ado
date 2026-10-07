*! _jd_parse 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_parse, rclass
    version 14.0
    syntax [anything] [if] [in] [, TOUSE(string) REQuire(string) NOTSrequired ]

    if (`"`anything'"' == "") {
        _jd_efetch, require(`require')
        local dv  "`r(dv)'"
        local iv  "`r(iv)'"
        local post 1
    }
    else {
        gettoken dv iv : anything
        unab dv  : `dv'
        if ("`iv'" != "") unab iv : `iv'
        local post 0
    }

    if ("`notsrequired'" == "") {
        capture qui tsset
        if (_rc) {
            di as err "data must be {bf:tsset} for time-series diagnostics"
            exit 459
        }
        local tvar "`r(timevar)'"
    }

    return local dv   "`dv'"
    return local iv   "`iv'"
    return local tvar "`tvar'"
    return scalar post = `post'
end


