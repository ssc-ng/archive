*! _jd_efetch 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_efetch, rclass
    version 14.0
    syntax [, REQuire(string) ]

    if ("`e(cmd)'" == "") {
        di as err "no estimation results in memory"
        di as err "fit a model first (regress, arch, newey, prais, ...) " ///
                  "or give {it:depvar indepvars} explicitly"
        exit 301
    }

    local ecmd "`e(cmd)'"
    if ("`require'" != "") {
        local ok 0
        foreach c of local require {
            if ("`ecmd'" == "`c'") local ok 1
        }
        if (!`ok') {
            di as err "last estimates are from -`ecmd'-; this subcommand needs one of: `require'"
            exit 301
        }
    }

    local dv "`e(depvar)'"
    local iv : colnames e(b)
    local iv : subinstr local iv "_cons" "", word all
    * strip equation prefixes that arch/arima leave behind
    local clean ""
    foreach v of local iv {
        capture confirm variable `v'
        if (_rc == 0) local clean "`clean' `v'"
    }
    local iv : list retokenize clean

    qui tsset
    local tvar "`r(timevar)'"

    return local dv  "`dv'"
    return local iv  "`iv'"
    return local cmd "`ecmd'"
    return local tvar "`tvar'"
    return scalar N = e(N)
end


