*! xtgamfe_p 1.1.0  2026-11-12
*! predict after xtgamfe
*
* Syntax:
*   predict [type] newvar [if] [in] [, statistic nooffset alpha(varname)]
*
* statistic:
*   xb         linear prediction x'b (+ offset); the default
*   stdp       standard error of the linear prediction
*   fe         profiled fixed effect alpha_hat_i
*   mu         fitted mean exp(alpha_hat_i + x'b + offset)
*   residuals  y - mu
*   score      y/mu - 1: derivative of the profiled quasi-log likelihood with
*              respect to the linear index (also the Pearson residual)
*
* xb and stdp work with new covariate values.  fe, mu, residuals, and score
* use the fixed effects of the estimated panels: by default these are
* recomputed from the estimation sample, whose variables must be unchanged
* since estimation, and are returned for every observation of an estimated
* panel.  alpha(varname) instead takes the fixed effects from varname (saved
* earlier with predict, fe), which allows mu to be evaluated at changed
* covariate values.  nooffset is allowed only with xb.
program define xtgamfe_p, sortpreserve
    version 15.0

    if "`e(cmd)'" != "xtgamfe" & "`e(cmdname)'" != "xtgamfe" {
        di as error "xtgamfe_p requires xtgamfe estimates in e()"
        exit 301
    }

    syntax newvarname [if] [in] [, XB STDP FE MU Residuals SCore ///
        noOFFset ALPHA(varname numeric)]

    // if and in refer to the caller's observation order: mark first.
    marksample touse, novarlist
    tempvar caller_order
    quietly generate long `caller_order' = _n

    local nopt = ("`xb'" != "") + ("`stdp'" != "") + ("`fe'" != "") + ///
        ("`mu'" != "") + ("`residuals'" != "") + ("`score'" != "")
    if `nopt' > 1 {
        di as error "specify only one of xb, stdp, fe, mu, residuals, or score"
        exit 198
    }
    local ptype "xb"
    foreach s in stdp fe mu residuals score {
        if "``s''" != "" local ptype "`s'"
    }

    if "`offset'" == "nooffset" & "`ptype'" != "xb" {
        di as error "nooffset is allowed only with the default xb statistic"
        exit 198
    }
    if "`alpha'" != "" & inlist("`ptype'", "xb", "stdp", "fe") {
        di as error "alpha() is allowed only with mu, residuals, or score"
        exit 198
    }

    // fe, mu, residuals, and score depend on y, regressors, panel/time
    // identifiers, weights, and offset in the original e(sample); the data
    // are checked against the signature taken at estimation (below, once
    // the design columns exist).  With alpha() the fixed effects are
    // supplied, so no check is made.
    local need_alpha = inlist("`ptype'", "fe", "mu", "residuals", "score")
    local need_check = (`need_alpha' & "`alpha'" == "")

    tempvar esamp
    capture quietly generate byte `esamp' = e(sample)
    local no_esample = (_rc != 0)
    if !`no_esample' {
        quietly count if `esamp'
        if r(N) == 0 {
            local no_esample = 1
            drop `esamp'
        }
    }
    if `no_esample' {
        // e(sample) is lost when results are reloaded with estimates use
        if `need_check' {
            di as error "the estimation sample is not available (results loaded with estimates use?)"
            di as error "`ptype' needs it: re-estimate on the data, or supply the fixed effects with alpha()"
            exit 459
        }
        quietly generate byte `esamp' = 1
    }

    // Time-series operators are evaluated with the current xtset settings,
    // which must be those of the estimation, and need the data in panel
    // order (xtset sorts).
    local panvar "`e(panvar)'"
    local depvar "`e(depvar)'"
    local has_ts = 0
    foreach t in `e(indepvars_full)' `e(indepvars)' {
        local comps : subinstr local t "#" " ", all
        foreach c of local comps {
            _ms_parse_parts `c'
            if "`r(ts_op)'" != "" local has_ts = 1
        }
    }
    if `has_ts' {
        capture quietly xtset
        if _rc | "`r(panelvar)'" != "`panvar'" | "`r(timevar)'" != "`e(timevar)'" {
            di as error "the model contains time-series operators, and the data are not xtset as at estimation"
            di as error "type:  xtset `panvar' `e(timevar)'"
            exit 459
        }
    }

    if "`ptype'" == "stdp" {
        _predict `typlist' `varlist' if `touse', stdp
        label variable `varlist' "S.E. of the linear prediction"
        exit
    }

    // Reproduce the estimation design from the full fvexpand list.  From
    // 1.1.0, e(b) has one column per expanded term, with zero coefficients
    // for base, empty-cell, and omitted terms.  Results stored by earlier
    // versions carry only the nonbase/nonomitted columns; that layout is
    // recognized by its column count and still supported.
    tempname bhat
    matrix `bhat' = e(b)
    local K = colsof(`bhat')

    local full `"`e(indepvars_full)'"'
    if `"`full'"' != "" {
        fvrevar `full'
        local rvfull "`r(varlist)'"
        local rv "`rvfull'"
        if `: word count `rvfull'' != `K' {
            local rv ""
            local j = 0
            foreach t of local full {
                local j = `j' + 1
                local v : word `j' of `rvfull'
                _ms_parse_parts `t'
                if !((r(base) == 1) | (r(omit) == 1)) local rv "`rv' `v'"
            }
        }
        local rv : list clean rv
    }
    else {
        local rhsnames `"`e(indepvars)'"'
        if `"`rhsnames'"' == "" local rhsnames : colnames `bhat'
        fvrevar `rhsnames'
        local rv "`r(varlist)'"
    }

    if `: word count `rv'' != `K' {
        di as error "xtgamfe_p internal error: `: word count `rv'' design columns for `K' coefficients"
        exit 459
    }

    // The signature was taken in the caller's observation order.  With
    // time-series operators it also covers the realized design columns, so
    // a change in a row that supplies a lag or lead is detected.
    if `need_check' {
        sort `caller_order'
        if `has_ts' & "`e(version)'" == "1.1.0" & `"`full'"' != "" {
            checkestimationsample, extra(`rvfull')
        }
        else checkestimationsample
    }

    // Linear index without the fixed effect and without the offset.
    tempvar xb_tmp
    quietly generate double `xb_tmp' = 0
    local j = 0
    foreach v of local rv {
        local j = `j' + 1
        if `bhat'[1,`j'] != 0 {
            quietly replace `xb_tmp' = `xb_tmp' + `v' * `bhat'[1,`j']
        }
        else quietly replace `xb_tmp' = . if missing(`v')
    }

    // xb: following official Stata convention, the model offset is included
    // by default; nooffset requests the coefficient-only linear index.
    if "`ptype'" == "xb" {
        quietly generate `typlist' `varlist' = `xb_tmp' if `touse'
        if "`offset'" != "nooffset" & `"`e(offset)'"' != "" {
            quietly replace `varlist' = `varlist' + `e(offset)' if `touse'
            label variable `varlist' "Linear prediction (x'b + offset)"
        }
        else label variable `varlist' "Linear prediction (x'b)"
        exit
    }

    if "`panvar'" == "" | "`depvar'" == "" {
        di as error "estimation variable metadata not found; re-estimate with xtgamfe"
        exit 459
    }

    local offvar `"`e(offset)'"'
    tempvar otmp
    if "`offvar'" != "" quietly generate double `otmp' = `offvar'
    else                  quietly generate double `otmp' = 0

    tempvar alpha_all
    if "`alpha'" != "" {
        quietly generate double `alpha_all' = `alpha'
    }
    else {
        // Stable recovery on the estimation sample:
        //   u = ln(y) - offset - xb,  alpha = ln( sum w exp(u) / sum w ).
        // Subtracting the panel maximum bounds every exponent by one.
        tempvar wtmp u_it umax shifted sum_shift sum_w alpha_hat
        if `"`e(wtype)'"' != "" quietly generate double `wtmp' `e(wexp)' if `esamp'
        else                      quietly generate double `wtmp' = 1 if `esamp'

        quietly generate double `u_it' = ln(`depvar') - `otmp' - `xb_tmp' if `esamp'
        quietly bysort `panvar': egen double `umax' = max(`u_it') if `esamp'
        quietly generate double `shifted' = `wtmp' * exp(`u_it' - `umax') if `esamp'
        quietly bysort `panvar': egen double `sum_shift' = total(`shifted') if `esamp'
        quietly bysort `panvar': egen double `sum_w' = total(`wtmp') if `esamp'
        quietly generate double `alpha_hat' = `umax' + ln(`sum_shift') - ln(`sum_w') if `esamp'

        quietly count if `esamp' & missing(`alpha_hat')
        if r(N) > 0 {
            di as error "numerical failure while recovering profiled fixed effects"
            exit 459
        }
        // one value per estimated panel, carried to every row of the panel
        quietly bysort `panvar': egen double `alpha_all' = max(`alpha_hat')
    }

    if "`ptype'" == "fe" {
        quietly generate `typlist' `varlist' = `alpha_all' if `touse'
        quietly count if `touse' & missing(`varlist') & !missing(`alpha_all')
        if r(N) > 0 {
            drop `varlist'
            di as error "requested storage type cannot represent one or more fixed effects; use predict double"
            exit 459
        }
        label variable `varlist' "Profiled fixed effect (alpha_hat_i)"
        exit
    }

    // mu: form the combined log mean before exponentiating, so large offsets
    // that cancel large fixed effects remain numerically benign.
    tempvar logmu mu_tmp
    quietly generate double `logmu' = `alpha_all' + `xb_tmp' + `otmp'
    quietly generate double `mu_tmp' = exp(`logmu')
    quietly count if `touse' & !missing(`logmu') & (missing(`mu_tmp') | `mu_tmp' <= 0)
    if r(N) > 0 {
        di as error "one or more fitted means are outside Stata's representable numeric range"
        exit 459
    }

    if "`ptype'" == "mu" {
        quietly generate `typlist' `varlist' = `mu_tmp' if `touse'
        quietly count if `touse' & !missing(`mu_tmp') & (missing(`varlist') | `varlist' <= 0)
        if r(N) > 0 {
            drop `varlist'
            di as error "requested storage type cannot represent one or more fitted means; use predict double"
            exit 459
        }
        label variable `varlist' "Fitted mean exp(alpha_hat + x'b + offset)"
        exit
    }

    if "`ptype'" == "residuals" {
        quietly generate `typlist' `varlist' = `depvar' - `mu_tmp' if `touse'
        label variable `varlist' "Residual (y - mu)"
        exit
    }

    // score: defined on the estimation sample, where it sums to zero within
    // each panel and is orthogonal to every regressor.
    quietly generate `typlist' `varlist' = `depvar' / `mu_tmp' - 1 if `touse' & `esamp'
    label variable `varlist' "Score with respect to the linear index (y/mu - 1)"
end
