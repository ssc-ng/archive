*! version 1.0.0.0  16nov2026
*! cdid_nuisance: report the nuisance models fitted by cdid
program define cdid_nuisance
    version 19.5
    syntax [anything(name=component)] [, BLOCK(string)]
    if "`e(cmd)'"!="cdid" {
        display as error "no cdid results found; run cdid with the keepnuisance option"
        exit 301
    }
    if "`e(mode)'"=="ordinary" {
        display as text "Nuisance models are not reported in ordinary mode, which {cmd:cdid} computes with {cmd:csdid}; {cmd:cdid_nuisance} reports them after chained-mode fits with the {cmd:keepnuisance} option."
        mata: st_rclear(); st_global("r(status)", "unavailable")
        mata: st_global("r(reason)", "ordinary mode is computed by csdid; cdid keeps no nuisance models for ordinary-mode results")
        exit
    }
    if "`e(result_kind)'"=="aggregation" {
        display as text "The current results are an {cmd:estat} aggregation; nuisance models are reported after {cmd:cdid}."
        mata: st_rclear(); st_global("r(status)", "unavailable")
        exit
    }
    capture mata: _cdid_mlib_ready()
    if _rc quietly mata: mata mlib index
    local wtext "w_i = 1 (no weights)"
    if `"`e(wexp)'"'!="" {
        local wx = strtrim(subinstr(`"`e(wexp)'"', "=", "", 1))
        local wtext `"w_i = `wx', fixed within unit"'
    }
    mata: cdid_nuis_show(st_global("e(state_token)"), st_local("component"), st_local("block"), ///
        st_global("e(clustvar)"), st_local("wtext"))
end
