*! xtgamfe_p 1.1.1  2026-11-21
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
* since estimation, value by value and row by row (Stata's data signature
* and the row signature stored by xtgamfe), and are returned for every
* observation of an estimated panel.  alpha(varname) instead takes the fixed effects from varname (saved
* earlier with predict, fe), which allows mu to be evaluated at changed
* covariate values.  nooffset is allowed only with xb.
*
* From 1.1.1, xb, stdp, mu, residuals, and score are missing, with a note,
* for an observation whose covariate profile the estimation sample does not
* identify: a factor level that has no term in the model, unless the
* estimation sample itself contains values of that factor without a term
* (as with 2.time, whose other periods share the indicator value zero); an
* empty cell of an interaction; or a value that breaks a relation by which
* xtgamfe omitted a term.  For mu, residuals, and score, which describe a
* panel's fitted mean, a term omitted by a relation specific to each panel
* (a term without within-panel variation, for example) must also keep its
* panel's value on the estimation sample; with alpha() this is checked once
* the values of that relation on the estimation sample are verified to be
* unchanged, and an observation of a panel without rows in the estimation
* sample, which has no such value, is not identified (from round 9).  xb and stdp are the index under the fitted normalization and
* are not compared with panel values.  score needs the estimation sample.
* The fitted means are computed from the within-panel index, so that a
* regressor with a large origin does not cost them precision.
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
    // as official commands do when no statistic is given
    if `nopt' == 0 di as text "(option xb assumed; linear prediction)"

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
            if inlist("`ptype'", "mu", "residuals") {
                di as error "`ptype' needs it: re-estimate on the data, or supply the fixed effects with alpha()"
            }
            else di as error "`ptype' needs it: re-estimate on the data"
            exit 459
        }
        // The score is a relative residual on the estimation sample; without
        // the sample marker it cannot be restricted to it (from 1.1.1;
        // through 1.1.0 every observation was treated as in the sample).
        if "`ptype'" == "score" {
            di as error "the estimation sample is not available (results loaded with estimates use?)"
            di as error "score is defined on the estimation sample only: re-estimate on the data"
            exit 459
        }
        quietly generate byte `esamp' = 1
    }
    // The score is defined on the estimation sample only: its computation
    // and its range checks are restricted to it from the start, so that a
    // row outside it cannot stop the prediction.
    if "`ptype'" == "score" quietly replace `touse' = 0 if !`esamp'

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
        // The time increment defines the lags too (from 1.1.1 it is
        // checked for every statistic, not only through the data signature).
        local tdelta_now = r(tdelta)
        if e(tdelta) < . & `tdelta_now' != e(tdelta) {
            di as error "the model contains time-series operators, and the data are xtset with"
            di as error "delta(`tdelta_now'), not delta(`=e(tdelta)') as at estimation"
            di as error "type:  xtset `panvar' `e(timevar)', delta(`=e(tdelta)')"
            exit 459
        }
    }

    // Observations whose covariate profile the estimation sample does not
    // identify (from 1.1.1).  For mu, residuals, and score with the fixed
    // effects recomputed from the unchanged data, a term without
    // within-panel variation must also keep its panel's value.
    //   mode 0 (xb, stdp): the factor levels and the relations whose
    //     constant is the same in every panel;
    //   mode 1 (mu, residuals, score with the data verified): also the
    //     relations specific to each panel, against the estimation sample;
    //   mode 2 (mu, residuals, score with alpha()): the same, once the
    //     values that define those relations on the estimation sample are
    //     verified to be unchanged (from 1.1.1).
    tempvar unsup
    quietly generate byte `unsup' = 0
    local relchg = 0
    if "`ptype'" != "fe" {
        local smode = 0
        if `need_check' local smode = 1
        else if `need_alpha' local smode = 2
        _xtgamfe_psupport `unsup' `smode' `esamp' `=!`no_esample''
        local relchg = r(relchg)
    }

    if "`ptype'" == "stdp" {
        _predict `typlist' `varlist' if `touse', stdp
        _xtgamfe_punsup `varlist' `unsup' `touse' stdp
        _xtgamfe_ponecl `varlist' `touse'
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
        if `has_ts' & inlist("`e(version)'", "1.1.0", "1.1.1") & `"`full'"' != "" {
            _xtgamfe_dschk_p `rvfull'
        }
        else _xtgamfe_dschk_p
        // Stata's signature checks each variable separately; the row
        // signature also sees values moved to other observations (from
        // 1.1.1; see _xtgamfe_rsig in xtgamfe.ado).
        if `"`e(xtg_rsig)'"' != "" {
            _xtgamfe_rsig_p `"`e(xtg_rkeys)'"' `panvar' `"`e(timevar)'"'
            if `"`r(sig)'"' != `"`e(xtg_rsig)'"' {
                di as error "data have changed since estimation"
                di as error "(on the estimation sample, values of the outcome, regressors, offset,"
                di as error "weights or cluster variable are not in the rows they had at estimation)"
                exit 459
            }
        }
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
    // The whole index, with the offset, is formed in double precision and
    // stored once in the type requested (from 1.1.1; before, a float index
    // was rounded before the offset was added).
    if "`ptype'" == "xb" {
        if "`offset'" != "nooffset" & `"`e(offset)'"' != "" {
            quietly replace `xb_tmp' = `xb_tmp' + `e(offset)' if `touse'
            quietly generate `typlist' `varlist' = `xb_tmp' if `touse'
            label variable `varlist' "Linear prediction (x'b + offset)"
        }
        else {
            quietly generate `typlist' `varlist' = `xb_tmp' if `touse'
            label variable `varlist' "Linear prediction (x'b)"
        }
        _xtgamfe_punsup `varlist' `unsup' `touse' xb
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
    local xbuse "`xb_tmp'"
    local ouse  "`otmp'"
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
        // A weight expression (or the weights of a fit under a resampling
        // prefix) is evaluated again here, in the caller's order; its values
        // must be those of the fit, row by row with the other estimation
        // inputs of each row (from 1.1.1: compared with the hash stored at
        // estimation).
        if `"`e(xtg_wsig)'"' != "" {
            _xtgamfe_rsig_p `"`e(xtg_rkeys)' `wtmp'"' `panvar' `"`e(timevar)'"'
            if `"`r(sig)'"' != `"`e(xtg_wsig)'"' {
                di as error "the weight expression `e(wexp)' gives values other than those of the fit"
                di as error "(the data were changed or reordered, or the expression depends on the order"
                di as error "of the observations); generate the weight variable and refit with it"
                exit 459
            }
        }

        // The fitted means, residuals, and scores are formed from the index
        // centered within each panel when the terms of the index and the
        // offset are large somewhere: sum_j |x_j b_j| + |offset| > 1024.  The
        // fixed effect cancels a panel constant from the log mean, and
        // adding a large index to a large opposite fixed effect, or adding
        // large terms that cancel (two regressors with large origins and
        // opposite slopes), would cost the fitted mean its precision.  The
        // bound is on the separate products, not on their sum, for that
        // reason.  Below it the uncentered computation is kept, whose
        // rounding error in the log mean is then below about 1e-12.  fe is
        // the uncentered fixed effect.
        if "`ptype'" != "fe" {
            tempvar mrow
            tempname mag
            quietly generate byte `mrow' = `esamp' | `touse'
            mata: st_numscalar("`mag'", _xtgamfe_pmag("`rv'", "`bhat'", "`mrow'", "`otmp'"))
            if scalar(`mag') < . & scalar(`mag') > 1024 {
                tempvar xbc oc
                _xtgamfe_pctr `xbc' `oc' `"`rv'"' `bhat' `esamp' `panvar' `otmp'
                local xbuse "`xbc'"
                local ouse  "`oc'"
            }
            drop `mrow'
        }

        // Weights of an extreme scale are brought to order one by an exact
        // power of two (the fixed effects do not depend on the scale), so
        // that their panel totals neither overflow nor underflow.
        if `"`e(wtype)'"' != "" {
            quietly summarize `wtmp' if `esamp', meanonly
            if r(max) < . & r(max) > 0 & (r(max) > 1e150 | r(max) < 1e-150) {
                tempname w2
                mata: st_numscalar("`w2'", _xtgamfe_w2_p(st_numscalar("r(max)")))
                quietly replace `wtmp' = `wtmp' * scalar(`w2')
            }
        }

        // The panel sums are formed in a fixed order: by panel, time, and
        // the values summed (then the caller's order, among rows whose
        // terms are equal), so that the fitted means do not depend on how
        // the data are sorted or on how Stata breaks ties when it sorts.
        quietly generate double `u_it' = ln(`depvar') - `ouse' - `xbuse' if `esamp'
        sort `panvar' `e(timevar)' `u_it' `wtmp' `caller_order'
        quietly by `panvar': generate double `umax' = `u_it'
        quietly by `panvar': replace `umax' = max(`umax', `umax'[_n - 1]) if _n > 1
        quietly by `panvar': replace `umax' = `umax'[_N]
        quietly replace `umax' = . if !`esamp'
        quietly generate double `shifted' = `wtmp' * exp(`u_it' - `umax') if `esamp'
        quietly by `panvar': generate double `sum_shift' = sum(`shifted')
        quietly by `panvar': replace `sum_shift' = `sum_shift'[_N]
        quietly by `panvar': generate double `sum_w' = sum(`wtmp')
        quietly by `panvar': replace `sum_w' = `sum_w'[_N]
        quietly generate double `alpha_hat' = `umax' + ln(`sum_shift') - ln(`sum_w') if `esamp'

        quietly count if `esamp' & missing(`alpha_hat')
        if r(N) > 0 {
            di as error "numerical failure while recovering profiled fixed effects"
            exit 459
        }
        // one value per estimated panel, carried to every row of the panel
        quietly by `panvar': generate double `alpha_all' = `alpha_hat'
        quietly by `panvar': replace `alpha_all' = max(`alpha_all', `alpha_all'[_n - 1]) if _n > 1
        quietly by `panvar': replace `alpha_all' = `alpha_all'[_N]
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
    // The range checks cover the rows whose prediction is returned: not
    // those whose covariate values the sample does not identify (their
    // prediction is missing, as documented).
    tempvar logmu mu_tmp
    quietly generate double `logmu' = `alpha_all' + `xbuse' + `ouse'
    quietly generate double `mu_tmp' = exp(`logmu')
    quietly count if `touse' & !`unsup' & !missing(`logmu') & (missing(`mu_tmp') | `mu_tmp' <= 0)
    if r(N) > 0 {
        di as error "one or more fitted means are outside Stata's representable numeric range"
        exit 459
    }

    if "`ptype'" == "mu" {
        quietly generate `typlist' `varlist' = `mu_tmp' if `touse'
        quietly count if `touse' & !`unsup' & !missing(`mu_tmp') & (missing(`varlist') | `varlist' <= 0)
        if r(N) > 0 {
            drop `varlist'
            di as error "requested storage type cannot represent one or more fitted means; use predict double"
            exit 459
        }
        label variable `varlist' "Fitted mean exp(alpha_hat + x'b + offset)"
        _xtgamfe_punsup `varlist' `unsup' `touse' mu `relchg'
        exit
    }

    if "`ptype'" == "residuals" {
        tempvar r_tmp
        quietly generate double `r_tmp' = `depvar' - `mu_tmp' if `touse'
        quietly generate `typlist' `varlist' = `r_tmp' if `touse'
        quietly count if `touse' & !`unsup' & !missing(`r_tmp') & missing(`varlist')
        if r(N) > 0 {
            drop `varlist'
            di as error "requested storage type cannot represent one or more residuals; use predict double"
            exit 459
        }
        label variable `varlist' "Residual (y - mu)"
        _xtgamfe_punsup `varlist' `unsup' `touse' residuals `relchg'
        exit
    }

    // score: defined on the estimation sample (to which touse was
    // restricted above), where, at the fitted effects and coefficients, it
    // sums to zero within each panel and is orthogonal to every regressor
    // (with alpha() at other effects it need not).
    tempvar s_tmp
    quietly generate double `s_tmp' = `depvar' / `mu_tmp' - 1 if `touse' & `esamp'
    // A ratio that overflows although the outcome and the fitted mean are
    // finite (the fitted mean is positive here; with alpha() a supplied
    // fixed effect can make it tiny) is a range failure, not a missing
    // value (from round 9 of 1.1.1; before, the score was returned missing
    // with return code 0).
    quietly count if `touse' & `esamp' & !`unsup' & !missing(`depvar', `mu_tmp') & missing(`s_tmp')
    if r(N) > 0 {
        di as error "one or more scores are outside Stata's representable numeric range"
        di as error "(the outcome divided by the fitted mean overflows)"
        exit 459
    }
    quietly generate `typlist' `varlist' = `s_tmp' if `touse' & `esamp'
    quietly count if `touse' & `esamp' & !`unsup' & !missing(`s_tmp') & missing(`varlist')
    if r(N) > 0 {
        drop `varlist'
        di as error "requested storage type cannot represent one or more scores; use predict double"
        exit 459
    }
    label variable `varlist' "Score with respect to the linear index (y/mu - 1)"
    _xtgamfe_punsup `varlist' `unsup' `touse' score `relchg'
end

// ---------------------------------------------------------------
// Set to missing the predictions of observations flagged by
// _xtgamfe_psupport, with a note.
// ---------------------------------------------------------------
program define _xtgamfe_punsup
    version 15.0
    args v unsup touse stat relchg
    quietly count if `touse' & `unsup' & !missing(`v')
    if r(N) == 0 exit
    local n = r(N)
    // rows of panels without estimation-sample rows, in a model with a
    // relation specific to each panel (unsup = 2; from round 9 of 1.1.1)
    quietly count if `touse' & `unsup' == 2 & !missing(`v')
    local n2 = r(N)
    local n = `n' - `n2'
    quietly replace `v' = . if `touse' & `unsup'
    if `n2' > 0 {
        local txt "note: `stat' set to missing for `n2' observation(s) in panels that have no observations in the estimation sample: the relation by which `e(omitted)' was omitted is specific to each panel and has no value for these panels, so fitted means there are not identified"
        local line ""
        foreach w of local txt {
            if "`line'" != "" & strlen("`line' `w'") > 78 {
                di as text "`line'"
                local line "     "
            }
            if "`line'" == "" local line "`w'"
            else              local line "`line' `w'"
        }
        di as text "`line'"
    }
    if `n' == 0 exit
    if "`relchg'" == "1" {
        di as text "note: `stat' set to missing for `n' observation(s): on the estimation sample,"
        local rk = strtrim(subinstr(" `e(xtg_relkeys)'", " .", " ", .))
        di as text "      the values of `rk' have changed since estimation; they"
        di as text "      define, for each panel, the relation by which `e(omitted)' was"
        di as text "      omitted, so fitted means at the new values are not identified"
        exit
    }
    di as text "note: `stat' set to missing for `n' observation(s): the estimation sample"
    di as text "      does not identify their covariate values (a factor level or a"
    di as text "      combination of levels that it does not contain, or values that break"
    di as text "      a relation by which a term was omitted)"
end

// ---------------------------------------------------------------
// stdp where a term that varies within panels in only one cluster
// (e(xtg_onecl)) is not zero (from 1.1.1): the clusters cannot estimate the
// sampling variation of its coefficient, so x'Vx there rests on the
// computed values in e(V) that the coefficient table does not show; stdp
// is set to missing, with a note.  Where every such term is zero, stdp
// does not involve them.
// ---------------------------------------------------------------
program define _xtgamfe_ponecl
    version 15.0
    args v touse
    local ocl `"`e(xtg_onecl)'"'
    // the directions of the coefficients that involve several terms and
    // rest on one cluster (e(xtg_ocdir), in the columns of e(b); from
    // 1.1.1): stdp is set to missing where x'v is not zero for such a
    // direction v, to a relative tolerance of 1e-6 (of sum_j |x_j v_j|)
    local has_od = 0
    capture confirm matrix e(xtg_ocdir)
    if _rc == 0 local has_od = 1
    if "`ocl'" == "" & !`has_od' exit
    tempvar nz
    quietly generate byte `nz' = 0
    foreach t of local ocl {
        fvrevar `t'
        quietly replace `nz' = 1 if `r(varlist)' != 0
    }
    if `has_od' {
        tempname OD
        matrix `OD' = e(xtg_ocdir)
        local full `"`e(indepvars_full)'"'
        local nr = rowsof(`OD')
        local nc = colsof(`OD')
        tempvar sx ax
        forvalues r = 1/`nr' {
            quietly generate double `sx' = 0 if `touse'
            quietly generate double `ax' = 0 if `touse'
            forvalues j = 1/`nc' {
                if `OD'[`r', `j'] == 0 continue
                local t : word `j' of `full'
                fvrevar `t'
                quietly replace `sx' = `sx' + `r(varlist)' * `OD'[`r', `j'] if `touse'
                quietly replace `ax' = `ax' + abs(`r(varlist)' * `OD'[`r', `j']) if `touse'
            }
            quietly replace `nz' = 1 if `touse' & abs(`sx') > 1e-6 * `ax'
            drop `sx' `ax'
        }
    }
    quietly count if `touse' & `nz' & !missing(`v')
    if r(N) == 0 exit
    local n = r(N)
    quietly replace `v' = . if `touse' & `nz'
    local n1 : word count `ocl'
    if `n1' == 1 local txt "`ocl' is not zero (it varies within panels in only one cluster, so the clusters cannot estimate the sampling variation of its coefficient)"
    else         local txt "one of `ocl' is not zero (they vary within panels in only one cluster each, so the clusters cannot estimate the sampling variation of their coefficients)"
    if `has_od' local txt "the linear prediction depends on a coefficient that rests on one cluster (`e(onecl)'), whose sampling variation the clusters cannot estimate"
    local line "note: stdp set to missing for `n' observation(s) in which"
    foreach w of local txt {
        if strlen("`line' `w'") > 78 {
            di as text "`line'"
            local line "     "
        }
        local line "`line' `w'"
    }
    di as text "`line'"
end

// ---------------------------------------------------------------
// Flag (unsup = 1) the observations whose covariate profile the estimation
// sample does not identify.
//   (a) A value of a factor variable that has no term in the model (it did
//       not occur in the estimation sample): no coefficient exists for it.
//       From 1.1.1 this is not applied to a factor whose estimation sample
//       already contains values without a term, as with 2.time or
//       i(2 3).time: every such value has all the indicators of the factor
//       equal to zero, a coding that the sample contains, and the model
//       pools them (through the first 1.1.1 build every value outside the
//       named levels was flagged, which removed 600 of 800 in-sample
//       predictions after xtgamfe cost x1 x2 2.time).  These factors are
//       listed in e(xtg_fvzero); for results of 1.1.0 they are found from
//       the estimation sample, when it is available.
//   (b) The relations stored by xtgamfe in e(xtg_relq) and e(xtg_relc): an
//       empty cell of an interaction must be zero, and x'q must equal the
//       constant of a relation by which a term was omitted.  Relations
//       whose constant is the same in every panel are checked always;
//       relations whose constant differs between panels (a term without
//       within-panel variation) are checked in modes 1 and 2, against the
//       value on the estimation sample of the observation's panel.  Mode 1
//       has the data verified by the signature; in mode 2 (alpha()) the
//       values that define those constants on the estimation sample are
//       first compared with the hash stored at estimation; if they have
//       changed, every observation is flagged and r(relchg) is 1.  An
//       observation of a panel that has no rows in the estimation sample
//       has no value to keep for a relation specific to each panel: it is
//       flagged with unsup = 2 (from round 9 of 1.1.1; before, it passed
//       unchecked, so that with alpha() the fitted mean depended on which
//       term of the relation the fit had omitted).
// ---------------------------------------------------------------
program define _xtgamfe_psupport, rclass
    version 15.0
    args unsup mode esamp has_es
    return scalar relchg = 0

    local full `"`e(indepvars_full)'"'
    if `"`full'"' == "" exit

    // (a) represented levels of each factor variable, by time-series operator
    local keys ""
    local nk = 0
    foreach t of local full {
        local comps : subinstr local t "#" " ", all
        foreach c of local comps {
            _ms_parse_parts `c'
            if "`r(type)'" != "factor" continue
            local key "`r(ts_op)'.`r(name)'"
            local lv = r(level)
            local k : list posof "`key'" in keys
            if `k' == 0 {
                local keys "`keys' `key'"
                local nk = `nk' + 1
                local k = `nk'
                local levs_`k' ""
            }
            local levs_`k' : list levs_`k' | lv
        }
    }
    local have_z = ("`e(version)'" != "1.1.0")
    local zkeys `"`e(xtg_fvzero)'"'
    forvalues k = 1/`nk' {
        local key : word `k' of `keys'
        if `: list key in zkeys' continue
        if substr("`key'", 1, 1) == "." local src = substr("`key'", 2, .)
        else {
            fvrevar `key'
            local src "`r(varlist)'"
        }
        tempvar ok
        quietly generate byte `ok' = missing(`src')
        foreach lv of local levs_`k' {
            quietly replace `ok' = 1 if `src' == `lv'
        }
        // results of 1.1.0: unnamed values in the estimation sample?
        if !`have_z' & `has_es' {
            quietly count if `esamp' & !`ok'
            if r(N) > 0 {
                drop `ok'
                continue
            }
        }
        quietly replace `unsup' = 1 if !`ok'
        drop `ok'
    }

    // (b) relations
    tempname RQ RC
    capture matrix `RQ' = e(xtg_relq)
    if _rc exit
    capture matrix `RC' = e(xtg_relc)
    if _rc exit
    local n : word count `full'
    local nr = rowsof(`RC')
    if colsof(`RQ') != `n' | rowsof(`RQ') != `nr' + 2 exit
    // In mode 2, verify the values behind the panel constants first.
    local pcheck = (`mode' == 1)
    if `mode' == 2 & `"`e(xtg_relkeys)'"' != "" {
        if !`has_es' {
            di as error "the estimation sample is not available (results loaded with estimates use?),"
            di as error "and the model omits a term by a relation specific to each panel"
            di as error "(`e(omitted)'): predict cannot check new values against it; re-estimate"
            exit 459
        }
        _xtgamfe_ksig_p `"`e(xtg_relkeys)'"' `e(panvar)' `"`e(timevar)'"'
        if `"`r(sig)'"' == `"`e(xtg_relhash)'"' local pcheck = 1
        else {
            quietly replace `unsup' = 1
            return scalar relchg = 1
            exit
        }
    }
    // natural value of every term that enters a relation
    local need ""
    forvalues r = 1/`nr' {
        forvalues j = 1/`n' {
            if `RQ'[`r', `j'] != 0 local need : list need | j
        }
    }
    foreach j of local need {
        local t : word `j' of `full'
        tempvar nat`j'
        _xtgamfe_natcol `nat`j'' `t'
    }
    tempvar s sc kp kes
    forvalues r = 1/`nr' {
        local gl  = `RC'[`r', 2]
        local cc  = `RC'[`r', 3]
        local tau = `RC'[`r', 4]
        local mr  = `RC'[`r', 5]
        if !`gl' & !`pcheck' continue
        quietly generate double `s' = 0
        quietly generate double `sc' = 1
        forvalues j = 1/`n' {
            if `RQ'[`r', `j'] != 0 {
                local mu = `RQ'[`nr' + 1, `j']
                local sj = `RQ'[`nr' + 2, `j']
                quietly replace `s' = `s' + `RQ'[`r', `j'] * (`nat`j'' - `mu')
                if `sj' > 0 quietly replace `sc' = `sc' + abs(`nat`j'' - `mu') / `sj'
            }
        }
        if `gl' {
            quietly replace `unsup' = 1 if !missing(`s') & abs(`s' - `cc') > `tau' * `mr' * `sc'
        }
        else {
            quietly generate double `kes' = `s' if `esamp'
            quietly bysort `e(panvar)': egen double `kp' = max(`kes')
            quietly replace `unsup' = 1 if !missing(`s', `kp') & abs(`s' - `kp') > `tau' * `mr' * `sc'
            // a panel without rows in the estimation sample has no value
            // of the relation to keep, so the fitted mean of a supplied
            // fixed effect there would depend on which term of the
            // relation was omitted (unsup = 2, with its own note; from
            // round 9 of 1.1.1)
            quietly replace `unsup' = 2 if `unsup' == 0 & !missing(`s') & missing(`kp')
            drop `kes' `kp'
        }
        drop `s' `sc'
    }
end

// ---------------------------------------------------------------
// The index and the offset centered within each estimated panel (from
// 1.1.1): every design column, and the offset, minus its smallest value on
// the estimation sample of the panel.  The minimum is an exact value of the
// column, so the differences are formed exactly from exactly stored values.
// Observations of panels without estimation-sample rows get missing.
// ---------------------------------------------------------------
program define _xtgamfe_pctr
    version 15.0
    args xbc oc rv bhat esamp panvar otmp
    tempvar ord
    quietly generate long `ord' = _n
    // Stata 15 has no c(sortseed); there the seed cannot be restored.
    local sseed ""
    capture local sseed = c(sortseed)
    sort `panvar' `ord'
    quietly generate double `xbc' = .
    quietly generate double `oc' = .
    mata: _xtgamfe_pctr_m("`rv'", "`bhat'", "`esamp'", "`panvar'", "`otmp'", "`xbc'", "`oc'")
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
end

// ---------------------------------------------------------------
// Stata's data-signature check of the estimation sample (from 1.1.1;
// xtgamfe_estat.ado has a copy, _xtgamfe_dschk_e, to be kept identical).
// When the fit received its weights as a temporary variable (under a
// resampling prefix; e(xtg_wds) = 0), the signature leaves the weights out,
// and the row hash e(xtg_wsig) covers them, so the check is made without
// e(wexp); otherwise it is checkestimationsample.  The arguments are the
// extra variables of the signature (the realized lags and leads).
// ---------------------------------------------------------------
program define _xtgamfe_dschk_p
    version 15.0
    if e(xtg_wds) == 0 {
        quietly _datasignature `e(datasignaturevars)' `0', esample nodefault nonames
        if r(datasignature) != e(datasignature) {
            di as error "data have changed since estimation"
            exit 459
        }
    }
    else if `"`0'"' != "" checkestimationsample, extra(`0')
    else checkestimationsample
end

// ---------------------------------------------------------------
// Copy of _xtgamfe_ksig in xtgamfe.ado (keep identical): a hash of the
// values of some variables on the estimation sample, row by row in the
// order of the panel and time variables.
// ---------------------------------------------------------------
program define _xtgamfe_ksig_p, rclass
    version 15.0
    args keys panvar timevar
    // Stata 15 has no c(sortseed); there the seed cannot be restored.
    local sseed ""
    capture local sseed = c(sortseed)
    tempvar ord es
    quietly generate long `ord' = _n
    quietly generate byte `es' = e(sample)
    sort `panvar' `timevar' `ord'
    local vl ""
    foreach k of local keys {
        if strpos("`k'", ".") == 0 local vl "`vl' `k'"
        else if substr("`k'", 1, 1) == "." local vl "`vl' `=substr("`k'", 2, .)'"
        else {
            fvrevar `k'
            local vl "`vl' `r(varlist)'"
        }
    }
    // Rows that tie on the panel and time variables (missing time values,
    // or no time variable) are put in the order of their values, so that a
    // re-sort of the data does not change the hash.
    local tie = ("`timevar'" == "")
    if !`tie' {
        quietly count if `es' & missing(`timevar')
        local tie = (r(N) > 0)
    }
    if `tie' {
        local sv : list vl - panvar
        local sv : list sv - timevar
        sort `panvar' `timevar' `sv' `ord'
    }
    mata: st_local("h", _xtgamfe_vh_p("`vl'", "`es'"))
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    return local sig "`h'"
end

// ---------------------------------------------------------------
// Copy of _xtgamfe_rsig in xtgamfe.ado (keep identical): the row signature
// of the estimation inputs.
// ---------------------------------------------------------------
program define _xtgamfe_rsig_p, rclass
    version 15.0
    args keys panvar timevar
    // Stata 15 has no c(sortseed); there the seed cannot be restored.
    local sseed ""
    capture local sseed = c(sortseed)
    tempvar ord es
    quietly generate long `ord' = _n
    quietly generate byte `es' = e(sample)
    sort `panvar' `timevar' `ord'
    local nl ""
    local sl ""
    foreach k of local keys {
        if strpos("`k'", ".") == 0 local v "`k'"
        else if substr("`k'", 1, 1) == "." local v = substr("`k'", 2, .)
        else {
            fvrevar `k'
            local v "`r(varlist)'"
        }
        capture confirm string variable `v'
        if _rc local nl : list nl | v
        else   local sl : list sl | v
    }
    // Rows that tie on the panel and time variables (missing time values,
    // or no time variable) are put in the order of their values.
    local tie = ("`timevar'" == "")
    if !`tie' {
        quietly count if `es' & missing(`timevar')
        local tie = (r(N) > 0)
    }
    if `tie' {
        local sv : list nl - panvar
        local sv : list sv - timevar
        sort `panvar' `timevar' `sv' `sl' `ord'
    }
    mata: st_local("h", _xtgamfe_rh_p("`nl'", "`sl'", "`es'"))
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    return local sig "`h'"
end

// ---------------------------------------------------------------
// Natural value of a term of the expanded list: the product of its
// components, with each factor component the indicator of its level
// (base and omission markers are ignored).  Data must be xtset when a
// component has a time-series operator.
// ---------------------------------------------------------------
program define _xtgamfe_natcol
    version 15.0
    args newv term
    quietly generate double `newv' = 1
    local comps : subinstr local term "#" " ", all
    foreach c of local comps {
        _ms_parse_parts `c'
        local nm "`r(name)'"
        local op "`r(ts_op)'"
        local ty "`r(type)'"
        local lv = r(level)
        if "`op'" != "" {
            fvrevar `op'.`nm'
            local src "`r(varlist)'"
        }
        else local src "`nm'"
        if "`ty'" == "factor" {
            quietly replace `newv' = cond(missing(`src'), ., `newv' * (`src' == `lv'))
        }
        else quietly replace `newv' = `newv' * `src'
    }
end

capture mata: mata drop _xtgamfe_vh_p()
capture mata: mata drop _xtgamfe_rh_p()
capture mata: mata drop _xtgamfe_pctr_m()
capture mata: mata drop _xtgamfe_pmag()
capture mata: mata drop _xtgamfe_w2_p()
mata:
// Copy of _xtgamfe_w2 in xtgamfe.ado: the exact power of two s for which
// m s lies in [1, 2), for a positive finite m (1 otherwise).
real scalar _xtgamfe_w2_p(real scalar m)
{
    real scalar s, i

    s = 1
    if (m >= . | m <= 0) return(s)
    i = 0
    while (m * s >= 2 & i < 1022) {
        s = s / 2
        i++
    }
    while (m * s < 1 & i < 1022) {
        s = s * 2
        i++
    }
    return(s)
}

// Copy of _xtgamfe_vh in xtgamfe.ado (keep identical).
string scalar _xtgamfe_vh_p(string scalar vars, string scalar es)
{
    real matrix V
    real scalar n, i, i2, h

    V = st_data(., tokens(vars), es)
    n = rows(V)
    h = 0
    for (i = 1; i <= n; i = i + 4096) {
        i2 = min((i + 4095, n))
        h = hash1(strofreal(h, "%12.0f") + " " +
                  invtokens(strofreal(vec(V[|i, 1 \ i2, .|]'), "%21x")'))
    }
    return(strofreal(n) + ":" + strofreal(h, "%12.0f"))
}

// Copy of _xtgamfe_rh in xtgamfe.ado (keep identical).
string scalar _xtgamfe_rh_p(string scalar nvars, string scalar svars, string scalar es)
{
    real matrix V
    string matrix S
    string colvector sv
    real colvector B
    real scalar n, i, i2, h, k
    string scalar C

    h = 0
    n = 0
    if (nvars != "") {
        V = st_data(., tokens(nvars), es)
        n = rows(V)
        k = cols(V)
        B = bufio()
        bufbyteorder(B, 1)
        for (i = 1; i <= n; i = i + 4096) {
            i2 = min((i + 4095, n))
            C = (8 * (i2 - i + 1) * k) * " "
            bufput(B, C, 0, "%8z", V[|i, 1 \ i2, .|])
            h = hash1(strofreal(h, "%12.0f") + " " + C)
        }
    }
    if (svars != "") {
        S = st_sdata(., tokens(svars), es)
        n = rows(S)
        for (i = 1; i <= n; i = i + 4096) {
            i2 = min((i + 4095, n))
            sv = vec(S[|i, 1 \ i2, .|]')
            h = hash1(strofreal(h, "%12.0f") + " " +
                      invtokens((strofreal(strlen(sv)) :+ ":" :+ sv)'))
        }
    }
    return(strofreal(n) + ":" + strofreal(h, "%12.0f"))
}

// The largest sum over the terms of |x_j b_j|, plus |offset|, over the rows
// marked by mn (missing if no row has all its values); see the caller.  The
// data are viewed, not copied, and summed one column at a time.
real scalar _xtgamfe_pmag(string scalar rv, string scalar bname, string scalar mn,
    string scalar ovn)
{
    real matrix X
    real colvector o, m
    real rowvector b
    real scalar j

    st_view(X, ., tokens(rv), mn)
    st_view(o, ., ovn, mn)
    b = st_matrix(bname)
    m = abs(o)
    for (j = 1; j <= cols(X); j++) m = m + abs(X[., j] * b[j])
    return(max(m))
}

// Centered index and offset (see _xtgamfe_pctr).  The data are sorted by
// the panel variable.  A column whose coefficient is zero contributes only
// its missing values, as in the uncentered index.
void _xtgamfe_pctr_m(string scalar rv, string scalar bname, string scalar esn,
    string scalar pvn, string scalar ovn, string scalar xbcn, string scalar ocn)
{
    real matrix X, R, info, Xi
    real colvector pv, es, o, ro, xbc, ei, z
    real rowvector b, nz, zc
    real scalar i, G, a, e

    X  = st_data(., tokens(rv))
    b  = st_matrix(bname)
    pv = st_data(., pvn)
    es = st_data(., esn)
    o  = st_data(., ovn)
    info = panelsetup(pv, 1)
    G  = rows(info)
    R  = J(rows(X), cols(X), .)
    ro = J(rows(X), 1, .)
    for (i = 1; i <= G; i++) {
        a = info[i, 1]
        e = info[i, 2]
        ei = es[|a \ e|]
        if (!any(ei :== 1)) continue
        Xi = select(X[|a, 1 \ e, .|], ei :== 1)
        R[|a, 1 \ e, .|] = J(e - a + 1, 1, colmin(Xi))
        ro[|a \ e|] = J(e - a + 1, 1, min(select(o[|a \ e|], ei :== 1)))
    }
    nz = selectindex(b :!= 0)
    zc = selectindex(b :== 0)
    if (cols(nz) > 0) xbc = (X[., nz] - R[., nz]) * b[nz]'
    else              xbc = J(rows(X), 1, 0) :* ro
    xbc = xbc + 0 :* ro
    if (cols(zc) > 0) {
        z = rowmissing(X[., zc]) :> 0
        xbc = xbc :/ (!z)
    }
    st_store(., xbcn, xbc)
    st_store(., ocn, o - ro)
}
end
