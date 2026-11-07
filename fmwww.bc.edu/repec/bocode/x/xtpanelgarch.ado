*! xtpanelgarch 1.0.0  06nov2026
*! Panel GARCH models: Cermeno-Grier, Asai, Pakel-Shephard-Sheppard, Su-Zhu,
*! Zhu-Li-Zhang-Li, Brownlees, Bauwens-Rombouts, Casarin et al.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define xtpanelgarch, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch") error 301
        xtpanelgarch_`e(subcmd)' `0'
        exit
    }
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    if inlist("`sub'", "cg", "cermenogrier") {
        xtpanelgarch_cg `0'
    }
    else if inlist("`sub'", "pretest", "pre") {
        xtpanelgarch_pretest `0'
    }
    else if inlist("`sub'", "vt", "asai") {
        xtpanelgarch_vt `0'
    }
    else if inlist("`sub'", "cl", "composite") {
        xtpanelgarch_cl `0'
    }
    else if inlist("`sub'", "armagarch", "suzhu") {
        xtpanelgarch_armagarch `0'
    }
    else if inlist("`sub'", "qgarch", "quantile") {
        xtpanelgarch_qgarch `0'
    }
    else if inlist("`sub'", "hgarch", "hierarchical") {
        xtpanelgarch_hgarch `0'
    }
    else if inlist("`sub'", "cluster") {
        xtpanelgarch_cluster `0'
    }
    else if inlist("`sub'", "msgarch") {
        xtpanelgarch_msgarch `0'
    }
    else {
        di as err "unknown subcommand {bf:`sub'}"
        di as err "valid subcommands: pretest, cg, vt, cl, armagarch, qgarch, hgarch, cluster, msgarch"
        exit 198
    }
end
