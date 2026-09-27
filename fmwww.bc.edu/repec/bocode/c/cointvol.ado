*! cointvol 0.1.0  26sep2026
*! Cointegration under volatility and heteroskedasticity: dispatcher
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane

program define cointvol, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    local sub = strlower(`"`sub'"')
    local l = strlen(`"`sub'"')
    if `"`sub'"' == "" | `"`sub'"' == "," {
        di as err "cointvol requires a subcommand; see {help cointvol}"
        exit 198
    }
    // subcommand : minimal abbreviation length
    local subs "rank:2 select:3 adaptive:5 restrict:4 vecmgarch:4 garchrank:6"
    local subs "`subs' resid:4 ecm:3 nullcoint:4 stoch:5 hetcoint:3 diag:4 simulate:3"
    local subs "`subs' table:3 graph:2"
    local target ""
    foreach s of local subs {
        gettoken name minl : s, parse(":")
        local minl = subinstr(`"`minl'"', ":", "", 1)
        if `l' >= `minl' & `"`sub'"' == substr("`name'", 1, `l') {
            local target "`name'"
            continue, break
        }
    }
    if `"`sub'"' == "about" | `"`sub'"' == "version" {
        di as txt "cointvol 0.1.0 (26sep2026) - Dr Merwan Roudane, merwanroudane920@gmail.com"
        di as txt "Please cite the original method papers and the cointvol package; see {help cointvol}."
        exit
    }
    if `"`target'"' == "" {
        di as err `"unknown cointvol subcommand: `sub'"'
        di as err "available: rank select adaptive restrict vecmgarch garchrank resid ecm"
        di as err "           nullcoint stoch hetcoint diag simulate table graph"
        exit 198
    }
    // findfile is r-class: keep the caller's r() (needed by table/graph)
    tempname rhold
    _return hold `rhold'
    capture findfile cointvol_`target'.ado
    local frc = _rc
    _return restore `rhold'
    if `frc' {
        di as err "cointvol_`target'.ado not found; reinstall cointvol"
        exit 601
    }
    cointvol_`target' `0'
    if !inlist("`target'", "table", "graph") {
        capture _cointvol_store `target'
    }
    return add
end
