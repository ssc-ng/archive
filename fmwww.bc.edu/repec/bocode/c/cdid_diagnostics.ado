*! version 1.0.0.0  16nov2026
*! cdid_diagnostics: summary of the sample, model and inference behind cdid results
program define cdid_diagnostics, rclass
    version 19.5
    if "`e(cmd)'"=="cdid" & "`e(design)'"=="static" {
        display as error "cdid_diagnostics is not available after dvar() estimation; see {help cdid##dvar:dvar()}"
        exit 198
    }
    syntax [, DETail]
    local rng0 `"`c(rngstate)'"'
    local sort0 `"`c(sortrngstate)'"'
    tempname prior_r
    _return hold `prior_r'
    capture noisily {
        quietly mata: mata mlib index
        mata: cdid_ur_diagnostics(`=("`detail'"!="")', `=c(max_matdim)')
    }
    local rc = _rc
    quietly set sortrngstate `sort0'
    quietly set rngstate `rng0'
    if `rc' {
        _return restore `prior_r'
        return add
        exit `rc'
    }
    _return drop `prior_r'
    return add
end
