*! version 1.0.0.0  16nov2026
*! cdid_export: save cdid results as a Stata dataset
program define cdid_export
    version 19.5
    syntax using/ [, TYPE(string) REPLACE]
    local type = strlower(strtrim("`type'"))
    local defaulted 0
    if "`type'"=="" {
        local type "cells"
        local defaulted 1
    }
    if !inlist("`type'","cells","aggregate","units","influence","summary") {
        display as error "type() must be cells, aggregate, units, influence or summary"
        exit 198
    }
    if "`e(cmd)'"=="cdid" & "`e(design)'"=="static" {
        if !inlist("`type'","cells","aggregate") {
            display as error "after dvar() estimation, cdid_export supports type(cells) and type(aggregate)"
            exit 198
        }
        _cdid_static_export `"`using'"', type(`type') `replace'
        exit
    }
    local rng0 `"`c(rngstate)'"'
    local sort0 `"`c(sortrngstate)'"'
    tempname prior_r outframe
    tempfile staged
    local target ""
    local ur_rows 0
    _return hold `prior_r'
    capture noisily {
        quietly mata: mata mlib index
        mata: cdid_ur_check("`type'")
        _cdid_ur_target target, file(`"`using'"') default(.dta) allowed(.dta) `replace'
        frame create `outframe'
        frame `outframe' {
            mata: cdid_ur_export("`type'")
            label data "cdid `type' export"
            quietly save `"`staged'"'
        }
        if "`replace'"!="" quietly copy `"`staged'"' `"`target'"', replace
        else quietly copy `"`staged'"' `"`target'"'
    }
    local rc = _rc
    capture frame drop `outframe'
    quietly set sortrngstate `sort0'
    quietly set rngstate `rng0'
    _return restore `prior_r'
    if `rc' exit `rc'
    display as text `"(`ur_rows' rows of type(`type') written to `target')"'
    if `defaulted' & "`ur_kind'"=="aggregation" {
        display as text "(the default type(cells) exports the original cell ledger; type(aggregate) exports the current `ur_agg_type' aggregation)"
    }
end

program define _cdid_static_export
    version 19.5
    syntax anything(name=target id="filename"), TYPE(string) [REPLACE]
    tempname fr C
    frame create `fr'
    frame `fr' {
        if "`type'"=="cells" {
            matrix `C'=e(cells)
            quietly svmat double `C', names(col)
            quietly generate str5 direction=cond(d==0,"entry","exit")
            order time tprev direction
            drop d
            label variable time "Date t of the transition"
            label variable tprev "Reference date t-1"
            label variable direction "Transition direction (entry: 0 to 1; exit: 1 to 0)"
            label variable sign "Sign applied to the switcher-stayer contrast"
            label variable available "Cell is estimable"
            label variable switchers "Number of switchers"
            label variable stayers "Number of stayers"
            label variable att "Average effect of treatment on switchers"
            label variable theta "Switcher-stayer contrast in outcome changes"
            label variable se "Standard error"
            label variable lower "Lower bound"
            label variable upper "Upper bound"
            label variable analytic_se "Analytical standard error"
            label variable bootstrap_se "Multiplier bootstrap standard error"
        }
        else {
            quietly set obs 1
            quietly generate double estimate=e(att)
            quietly generate double se=e(se_att)
            quietly generate double analytic_se=e(se_att_analytic)
            quietly generate double bootstrap_se=e(se_att_bootstrap)
            quietly generate double switchers=e(n_switchers)
            quietly generate double level=e(level)
            label variable estimate "Switcher-weighted average effect"
            label variable se "Standard error"
            label variable analytic_se "Analytical standard error"
            label variable bootstrap_se "Multiplier bootstrap standard error"
            label variable switchers "Switchers in the requested cells"
            label variable level "Confidence level"
        }
        label data "cdid `type' export"
        save `target', `replace'
    }
end
