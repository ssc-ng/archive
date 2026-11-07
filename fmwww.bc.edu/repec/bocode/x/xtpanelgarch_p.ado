*! xtpanelgarch_p 1.0.0  06nov2026
*! predict after xtpanelgarch
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program define xtpanelgarch_p
    version 14.0
    if "`e(cmd)'" != "xtpanelgarch" error 301
    syntax newvarname [if] [in] , [ Variance SD Residuals STDresiduals QUANTile ///
        COVariance(numlist min=2 max=2 integer) CORRelation(numlist min=2 max=2 integer) ]
    local nopt = ("`variance'" != "") + ("`sd'" != "") + ("`residuals'" != "") + ///
        ("`stdresiduals'" != "") + ("`covariance'" != "") + ("`correlation'" != "") + ("`quantile'" != "")
    if `nopt' > 1 {
        di as err "only one statistic may be specified"
        exit 198
    }
    if `nopt' == 0 & "`e(subcmd)'" == "qgarch" local quantile quantile
    if `nopt' == 0 & "`e(subcmd)'" != "qgarch" {
        local variance variance
        di as txt "(option variance assumed; conditional variance)"
    }
    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)
    local ivar "`e(ivar)'"
    local tvar "`e(tvar)'"
    tempvar uix tix
    qui gen long `uix' = .
    local j 0
    foreach u in `e(units)' {
        local ++j
        qui replace `uix' = `j' if `ivar' == `u'
    }
    qui gen long `tix' = round((`tvar' - e(t0)) / e(tdelta)) + 1
    qui gen double `varlist' = .
    if "`covariance'`correlation'" != "" {
        local a : word 1 of `covariance' `correlation'
        local b : word 2 of `covariance' `correlation'
        capture confirm matrix e(covt)
        if _rc & "`e(cov)'" != "feasible" & "`e(cov)'" != "ccc" {
            di as err "no conditional covariances in e(); estimate with cov()"
            exit 198
        }
        local ia : list posof "`a'" in e(units)
        local ib : list posof "`b'" in e(units)
        if `ia' == 0 | `ib' == 0 {
            di as err "panels `a' and/or `b' not in the estimation sample"
            exit 198
        }
        if `ia' > `ib' {
            local tmp `ia'
            local ia `ib'
            local ib `tmp'
        }
        mata: _xtpg_fillcov("`varlist'", "`tix'", "`touse'", `ia', `ib', ("`correlation'" != ""))
        qui replace `varlist' = . if !`touse'
        if "`correlation'" != "" label variable `varlist' "conditional correlation `a'-`b'"
        else label variable `varlist' "conditional covariance `a'-`b'"
        exit
    }
    if "`variance'`sd'" != "" {
        capture confirm matrix e(sigma2)
        if _rc {
            di as err "no conditional variances stored after xtpanelgarch `e(subcmd)'; use predict, quantile"
            exit 198
        }
        mata: _xtpg_fillvar("`varlist'", "`uix'", "`tix'", "`touse'", st_matrix("e(sigma2)"), ("`sd'" != ""))
        if "`sd'" != "" label variable `varlist' "conditional standard deviation"
        else label variable `varlist' "conditional variance"
    }
    if "`quantile'" != "" {
        capture confirm matrix e(qtau)
        if _rc {
            di as err "predict, quantile requires xtpanelgarch qgarch"
            exit 198
        }
        mata: _xtpg_fillvar("`varlist'", "`uix'", "`tix'", "`touse'", st_matrix("e(qtau)"), 0)
        label variable `varlist' "conditional `=e(quantile)' quantile (VaR)"
    }
    if "`residuals'" != "" {
        mata: _xtpg_fillvar("`varlist'", "`uix'", "`tix'", "`touse'", st_matrix("e(resid)"), 0)
        label variable `varlist' "residuals"
    }
    if "`stdresiduals'" != "" {
        mata: _xtpg_fillvar("`varlist'", "`uix'", "`tix'", "`touse'", st_matrix("e(resid)") :/ sqrt(st_matrix("e(sigma2)")), 0)
        label variable `varlist' "standardized residuals"
    }
    qui replace `varlist' = . if !`touse'
end
