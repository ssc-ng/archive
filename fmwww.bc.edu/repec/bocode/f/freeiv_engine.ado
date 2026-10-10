*! freeiv_engine 1.0.0  06oct2026  A. Araar
*! Loader of the Mata engine.  An ado-file loaded automatically does not
*! execute its mata: block, so freeiv_mata.ado is run on demand, once.
*!
*! Every entry point is checked, not just the first: a session that has
*! already used an older freeiv still holds that older engine in memory, and
*! a function added since would never be defined.  When one is missing, the
*! engine in memory is dropped before freeiv_mata.ado runs again -- Mata
*! refuses to redefine a function that exists, and 1.0.0 changes the
*! arguments of _freeiv_all() and _freeiv_lit(), so an upgrade inside a live
*! session must replace the whole engine, not complete it.  A new brick adds
*! its entry point to the list below.

cap program drop _freeiv_engine_ck
cap program drop freeiv_engine

* sets s(fiv_missing) to the entry points not currently in memory, if any
program define _freeiv_engine_ck, sclass
    version 16
    args need
    sreturn clear
    local gone ""
    foreach f of local need {
        mata: st_local("ok", strofreal(findexternal("`f'()") != NULL))
        if ("`ok'" != "1") local gone "`gone' `f'()"
    }
    sreturn local fiv_missing = trim("`gone'")
end

program define freeiv_engine
    version 16
    local need "_freeiv_all _freeiv_proxy _freeiv_lit _freeiv_gmm"
    local need "`need' _freeiv_jgmm _freeiv_lsz _freeiv_ptests _freeiv_gmm16"
    local need "`need' _fiv_vset _fiv_vclear _fiv_vinfo _fiv_cov"

    _freeiv_engine_ck "`need'"
    if ("`s(fiv_missing)'" == "") exit

    cap findfile freeiv_mata.ado
    if (_rc) {
        cap findfile freeiv_mata.ado, path("stata")
    }
    if (_rc) {
        di as err "freeiv_mata.ado not found on the adopath"
        exit 601
    }
    local fn "`r(fn)'"
    * every function of the engine is named _fiv*() or _freeiv*()
    cap mata: mata drop _fiv*()
    cap mata: mata drop _freeiv*()
    cap noisily version `c(stata_version)': run "`fn'"

    _freeiv_engine_ck "`need'"
    if ("`s(fiv_missing)'" != "") {
        di as err "the freeiv Mata engine could not be loaded:"
        di as err "    `s(fiv_missing)' still undefined after running"
        di as err "    `fn'"
        di as err "the ado files and freeiv_mata.ado are out of step;"
        di as err "reinstall the package, or -clear all- and try again"
        exit 601
    }
end
