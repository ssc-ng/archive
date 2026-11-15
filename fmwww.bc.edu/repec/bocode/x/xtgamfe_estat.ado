*! xtgamfe_estat 1.1.0  2026-11-12
*! estat after xtgamfe
*
* Syntax:
*   estat ic [, n(#)]
*   estat ape [varlist] [, level(#)]
*   estat summarize, estat vce   (standard)
*
* estat ic reports AIC and BIC from the marginal log likelihood of the
* within-panel shares, e(ll), counting the coefficients and the shape.
*
* estat ape reports average partial effects on the conditional mean
* exp(alpha_i + x'b + offset), averaged over the estimation sample with the
* estimated fixed effects: the average derivative for a continuous
* variable, and the average change from the base level for each level of a
* factor variable.  Standard errors come from the influence functions of
* the averages, clustered as in the fitted model's robust variance (on
* panels if the model was fitted with vce(oim), bootstrap, or jackknife).
program define xtgamfe_estat, rclass
    version 15.0

    if "`e(cmd)'" != "xtgamfe" {
        di as error "xtgamfe estimation results not found"
        exit 301
    }

    gettoken sub rest : 0, parse(" ,")
    if "`sub'" == "ic" {
        xtgamfe_estat_ic `rest'
    }
    else if "`sub'" == "ape" {
        xtgamfe_estat_ape `rest'
    }
    else {
        estat_default `0'
    }
    return add
end

// ---------------------------------------------------------------
// estat ic
// ---------------------------------------------------------------
program define xtgamfe_estat_ic, rclass
    version 15.0
    syntax [, N(numlist max=1 >0)]

    if e(ll) >= . {
        di as error "the log likelihood is not available for this fit"
        di as error "(it is not computed when weights vary within panel or when no finite"
        di as error " maximum likelihood shape estimate exists)"
        exit 498
    }
    local N = e(N)
    if "`n'" != "" local N = `n'
    local k   = e(rank_h) + 1
    local aic = -2 * e(ll) + 2 * `k'
    local bic = -2 * e(ll) + `k' * ln(`N')

    di ""
    di as text "Akaike's information criterion and Bayesian information criterion"
    di ""
    di as text "{hline 13}{c TT}{hline 63}"
    di as text "       Model {c |}          N   ll(null)  ll(model)      df        AIC        BIC"
    di as text "{hline 13}{c +}{hline 63}"
    di as text "           . {c |} " as result %10.0fc `N' "          . " ///
        %10.0g e(ll) " " %7.0f `k' " " %10.0g `aic' " " %10.0g `bic'
    di as text "{hline 13}{c BT}{hline 63}"
    di as text "Note: ll(model) is the marginal log likelihood of the within-panel shares,"
    di as text "      evaluated at the coefficients and the maximum likelihood shape; df"
    di as text "      counts the estimated coefficients and the shape.  BIC uses N = " ///
        as result `N' as text "."

    tempname S
    matrix `S' = (`N', ., e(ll), `k', `aic', `bic')
    matrix colnames `S' = N ll0 ll df AIC BIC
    matrix rownames `S' = .
    return matrix S = `S'
end

// ---------------------------------------------------------------
// estat ape
// ---------------------------------------------------------------
program define xtgamfe_estat_ape, rclass sortpreserve
    version 15.0
    syntax [varlist(default=none numeric)] [, Level(cilevel)]

    tempvar caller_order
    quietly generate long `caller_order' = _n

    local panvar  "`e(panvar)'"
    local timevar "`e(timevar)'"
    local depvar  "`e(depvar)'"
    local full    `"`e(indepvars_full)'"'
    local n_exp : word count `full'

    tempname b
    matrix `b' = e(b)
    if colsof(`b') != `n_exp' | `n_exp' == 0 {
        di as error "estat ape requires results stored by xtgamfe 1.1.0 or later"
        exit 498
    }

    tempvar touse
    capture quietly generate byte `touse' = e(sample)
    local no_esample = (_rc != 0)
    if !`no_esample' {
        quietly count if `touse'
        if r(N) == 0 local no_esample = 1
    }
    if `no_esample' {
        di as error "the estimation sample is not available (results loaded with estimates use?)"
        di as error "estat ape needs it: re-estimate on the data"
        exit 459
    }

    // ---- components of the estimated terms ----
    // A term is estimated unless it is a base level or empty cell of the
    // expanded list or was omitted by xtgamfe as not identified.
    // U: distinct components (e.g. c.x1, 2.time, L.x2), each with the code
    // of its underlying variable, a kind (0 continuous, 1 factor, 2 with a
    // time-series operator), and its level.
    local omitted `"`e(omitted)'"'
    local U ""
    local allvars ""
    local tsvars ""
    local contvars ""
    local factvars ""
    local unident ""
    local estcols ""
    local has_ts = 0
    local K = 0
    local maxc = 1
    local j = 0
    foreach t of local full {
        local j = `j' + 1
        local comps : subinstr local t "#" " ", all
        _ms_parse_parts `t'
        local is_est = !((r(base) == 1) | (r(omit) == 1))
        local t_omit = (r(omit) == 1)
        local was_omitted : list t in omitted
        if `was_omitted' local is_est = 0
        local ncomp : word count `comps'
        if `is_est' {
            local K = `K' + 1
            local estcols "`estcols' `j'"
            if `ncomp' > `maxc' local maxc = `ncomp'
        }
        local anybase = 0
        local cellpairs ""
        foreach c of local comps {
            _ms_parse_parts `c'
            local nm "`r(name)'"
            local allvars : list allvars | nm
            local vc : list posof "`nm'" in allvars
            local c_factor = ("`r(type)'" == "factor" & "`r(ts_op)'" == "")
            if r(base) == 1 local anybase = 1
            if `was_omitted' {
                // A single level of a factor that xtgamfe omitted (as in
                // ibn.time, where one level is collinear with the fixed
                // effects) can serve as the base; any other omitted term
                // leaves its variables without an identified effect.
                if `ncomp' == 1 & `c_factor' {
                    local lv = r(level)
                    local omain_`vc' : list omain_`vc' | lv
                    local omainvars : list omainvars | nm
                }
                else local unident : list unident | nm
            }
            if "`r(ts_op)'" != "" {
                local tsvars : list tsvars | nm
                local has_ts = 1
            }
            else if "`r(type)'" == "factor" {
                local factvars : list factvars | nm
                local lv = r(level)
                local lev_`vc' : list lev_`vc' | lv
                if r(base) == 1 local base_`vc' = `lv'
                local cellpairs "`cellpairs' `vc':`lv'"
            }
            else local contvars : list contvars | nm
            if `is_est' local U : list U | c
        }
        // An interaction that is omitted although none of its components is
        // a base level is an empty cell.  The fitted mean of an observation
        // moved into that cell is not estimable, so no effect is reported
        // for the factor levels that define it.
        if `t_omit' & !`was_omitted' & `ncomp' >= 2 & !`anybase' {
            foreach pr of local cellpairs {
                gettoken pvc plv : pr, parse(":")
                local plv : subinstr local plv ":" ""
                local empty_`pvc' : list empty_`pvc' | plv
            }
        }
    }
    local obasenote ""
    foreach nm of local omainvars {
        local vc : list posof "`nm'" in allvars
        local n_om : word count `omain_`vc''
        if "`base_`vc''" == "" & `n_om' == 1 & !`: list nm in unident' {
            local base_`vc' `omain_`vc''
            local obasenote "`obasenote' `nm' (`omain_`vc'')"
        }
        else local unident : list unident | nm
    }

    // Variables that do not vary within any panel of the estimation sample.
    // Their effect on the mean is absorbed by the fixed effects whether or
    // not a main-effect term for them is in the model.
    local tinv ""
    tempvar touse0
    capture quietly generate byte `touse0' = e(sample)
    if _rc == 0 {
        foreach v of local allvars {
            if `: list v in tsvars' continue
            tempvar vlo vhi
            quietly egen double `vlo' = min(`v') if `touse0', by(`panvar')
            quietly egen double `vhi' = max(`v') if `touse0', by(`panvar')
            quietly count if `touse0' & `vhi' > `vlo'
            if r(N) == 0 local tinv "`tinv' `v'"
            drop `vlo' `vhi'
        }
        sort `caller_order'
    }
    if `K' == 0 {
        di as error "no estimated coefficients"
        exit 498
    }
    local nU : word count `U'

    tempname TC UM bK
    matrix `TC' = J(`K', `maxc', 0)
    matrix `UM' = J(`nU', 3, 0)
    matrix `bK' = J(1, `K', 0)
    local u = 0
    foreach c of local U {
        local u = `u' + 1
        _ms_parse_parts `c'
        local nm "`r(name)'"
        local vc : list posof "`nm'" in allvars
        matrix `UM'[`u', 1] = `vc'
        if "`r(ts_op)'" != "" matrix `UM'[`u', 2] = 2
        else if "`r(type)'" == "factor" {
            matrix `UM'[`u', 2] = 1
            matrix `UM'[`u', 3] = r(level)
        }
    }
    local k = 0
    foreach j of local estcols {
        local k = `k' + 1
        local t : word `j' of `full'
        matrix `bK'[1, `k'] = `b'[1, `j']
        local comps : subinstr local t "#" " ", all
        local m = 0
        foreach c of local comps {
            local m = `m' + 1
            matrix `TC'[`k', `m'] = `: list posof "`c'" in U'
        }
    }

    // ---- targets ----
    // Not reported: a variable that enters with a time-series operator (the
    // command does not differentiate through lags and leads), and a
    // variable in a term that was omitted as not identified (the effect of
    // such a variable on the mean is not identified either: for a
    // time-invariant variable it is absorbed by the fixed effect).
    local skipped_ts ""
    local skipped_un ""
    local skipped_ti ""
    local skipped_ne ""
    if "`varlist'" == "" {
        local cand : list contvars | factvars
        local targets ""
        foreach v of local cand {
            local vc : list posof "`v'" in allvars
            local found = 0
            forvalues u = 1/`nU' {
                if `UM'[`u', 1] == `vc' & `UM'[`u', 2] != 2 local found = 1
            }
            if !`found' continue
            if `: list v in tsvars' {
                local skipped_ts "`skipped_ts' `v'"
                continue
            }
            if `: list v in tinv' {
                local skipped_ti "`skipped_ti' `v'"
                continue
            }
            if `: list v in unident' {
                local skipped_un "`skipped_un' `v'"
                continue
            }
            local targets "`targets' `v'"
        }
        foreach v of local tinv {
            if !`: list v in skipped_ti' & !`: list v in tsvars' local skipped_ti "`skipped_ti' `v'"
        }
        foreach v of local tsvars {
            if !`: list v in skipped_ts' local skipped_ts "`skipped_ts' `v'"
        }
        foreach v of local unident {
            if !`: list v in skipped_un' & !`: list v in skipped_ts' & !`: list v in skipped_ti' ///
                local skipped_un "`skipped_un' `v'"
        }
    }
    else local targets "`varlist'"

    if "`targets'" == "" {
        di as error "no variable for which an average partial effect can be computed"
        exit 498
    }

    tempname TG
    local rnames ""
    local q = 0
    local anyfactor = 0
    local basenote ""
    foreach v of local targets {
        local vc : list posof "`v'" in allvars
        if `vc' == 0 {
            di as error "`v' is not in the fitted model"
            exit 111
        }
        local in_c : list v in contvars
        local in_f : list v in factvars
        if `: list v in tsvars' {
            di as error "`v' enters the model with a time-series operator;"
            di as error "estat ape does not differentiate through lags or leads"
            exit 498
        }
        if `: list v in tinv' {
            di as error "`v' does not vary within panel in the estimation sample; the effect of a"
            di as error "time-invariant variable on the mean is absorbed by the fixed effects and is"
            di as error "not identified, even when its interaction with another variable is"
            exit 498
        }
        if `: list v in unident' {
            di as error "`v' is in a term that xtgamfe omitted because of collinearity, so its"
            di as error "effect on the mean is not separately identified"
            exit 498
        }
        if `in_c' & `in_f' {
            di as error "`v' enters the model both as a continuous and as a factor variable;"
            di as error "estat ape does not support that"
            exit 498
        }
        if `in_c' {
            local q = `q' + 1
            matrix `TG' = nullmat(`TG') \ (`vc', 1, 0, 0)
            local rnames "`rnames' `v'"
        }
        else {
            if "`base_`vc''" == "" {
                // no base level in the model: use the lowest level
                local base_`vc' : word 1 of `: list sort lev_`vc''
                local basenote "`basenote' `v'"
            }
            local any = 0
            foreach lv of local lev_`vc' {
                if `lv' == `base_`vc'' continue
                // report only levels with an estimated term
                local has = 0
                forvalues u = 1/`nU' {
                    if `UM'[`u', 1] == `vc' & `UM'[`u', 2] == 1 & `UM'[`u', 3] == `lv' local has = 1
                }
                if !`has' continue
                if `: list lv in empty_`vc'' {
                    local skipped_ne "`skipped_ne' `lv'.`v'"
                    local any = 1
                    continue
                }
                local q = `q' + 1
                local any = 1
                local anyfactor = 1
                matrix `TG' = nullmat(`TG') \ (`vc', 2, `lv', `base_`vc'')
                local rnames "`rnames' `lv'.`v'"
            }
            if !`any' {
                di as error "no estimated level of factor variable `v'"
                exit 498
            }
        }
    }
    if `q' == 0 {
        di as error "no estimable average partial effect:`skipped_ne' not estimable (empty cell)"
        exit 498
    }

    // ---- data in panel order ----
    // Time-series operators are evaluated with the current xtset settings,
    // which must be those of the estimation.
    if `has_ts' {
        capture quietly xtset
        if _rc | "`r(panelvar)'" != "`panvar'" | "`r(timevar)'" != "`timevar'" {
            di as error "the model contains time-series operators, and the data are not xtset as at estimation"
            di as error "type:  xtset `panvar' `timevar'"
            exit 459
        }
    }
    else sort `panvar' `timevar'

    // The data must be those of the estimation (as for predict, mu).
    if `has_ts' & "`e(version)'" == "1.1.0" {
        fvrevar `full'
        local rvfull "`r(varlist)'"
        sort `caller_order'
        checkestimationsample, extra(`rvfull')
    }
    else {
        sort `caller_order'
        checkestimationsample
    }

    tempvar clid
    local clname ""
    if "`e(clustvar)'" != "" & "`e(clustvar)'" != "`panvar'" {
        quietly egen long `clid' = group(`e(clustvar)') if `touse'
        local clname "`clid'"
    }
    sort `panvar' `timevar'

    // One variable per component.  Factor levels are built as indicators
    // here (fvrevar would return zeros for a level marked as base, which is
    // wrong inside an interaction that is itself estimated).
    local uvars ""
    foreach c of local U {
        _ms_parse_parts `c'
        if "`r(type)'" == "factor" {
            tempvar ind
            if "`r(ts_op)'" != "" {
                quietly generate byte `ind' = (`r(ts_op)'.`r(name)' == r(level)) if `touse'
            }
            else quietly generate byte `ind' = (`r(name)' == r(level)) if `touse'
            local uvars "`uvars' `ind'"
        }
        else {
            fvrevar `c'
            local uvars "`uvars' `r(varlist)'"
        }
    }

    tempvar lny lyo wv pfirst panid
    quietly generate double `lny' = ln(`depvar') if `touse'
    if "`e(offset)'" != "" quietly generate double `lyo' = `lny' - `e(offset)' if `touse'
    else                     quietly generate double `lyo' = `lny' if `touse'
    if "`e(wtype)'" != "" quietly generate double `wv' `e(wexp)' if `touse'
    else                    quietly generate double `wv' = 1 if `touse'
    quietly by `panvar': generate byte `pfirst' = `touse' & (sum(`touse') == 1)
    quietly generate long `panid' = sum(`pfirst')
    quietly replace `panid' = . if !`touse'

    tempname ab aV aM
    mata: _xtgamfe_ape("`lyo'", "`lny'", "`uvars'", "`touse'", "`panid'", ///
        "`wv'", "`e(wtype)'", "`clname'", "`TC'", "`UM'", "`TG'", "`bK'", ///
        "`ab'", "`aV'", "`aM'")

    matrix colnames `ab' = `rnames'
    matrix colnames `aV' = `rnames'
    matrix rownames `aV' = `rnames'
    local M = `aM'
    local clv "`panvar'"
    if "`clname'" != "" local clv "`e(clustvar)'"

    // ---- display ----
    local z = invnormal(1 - (100 - `level') / 200)
    di ""
    di as text "Average partial effects on the conditional mean" ///
        _col(55) "Number of obs = " as result %9.0fc e(N)
    di as text "Model: exp(alpha_i + x'b" cond("`e(offset)'" != "", " + offset", "") ///
        "), fixed effects as estimated"
    di as text "{ralign 78:(Std. err. adjusted for `M' clusters in `clv')}"
    di as text "{hline 13}{c TT}{hline 64}"
    di as text "             {c |}      dy/dx   Std. err.      z    P>|z|     [`level'% conf. interval]"
    di as text "{hline 13}{c +}{hline 64}"
    forvalues t = 1/`q' {
        local nm : word `t' of `rnames'
        local est = `ab'[1, `t']
        local se  = sqrt(`aV'[`t', `t'])
        local zz  = `est' / `se'
        local pv  = 2 * normal(-abs(`zz'))
        di as text %12s abbrev("`nm'", 12) " {c |}  " as result %9.0g `est' "  " %9.0g `se' " " ///
            %8.2f `zz' " " %7.3f `pv' "    " %9.0g (`est' - `z' * `se') "   " %9.0g (`est' + `z' * `se')
    }
    di as text "{hline 13}{c BT}{hline 64}"
    if `anyfactor' {
        di as text "Note: dy/dx for a factor level is the average change from the base level."
    }
    if "`basenote'" != "" {
        di as text "Note: no base level in the model for:`basenote'; the lowest level is used."
    }
    if "`skipped_ts'" != "" {
        di as text "Note: not reported (enters with a time-series operator):`skipped_ts'"
    }
    if "`obasenote'" != "" {
        di as text "Note: base level taken as the level that xtgamfe omitted for:`obasenote'."
    }
    if "`skipped_ti'" != "" {
        di as text "Note: not reported (no within-panel variation; absorbed by the fixed effects):`skipped_ti'"
    }
    if "`skipped_un'" != "" {
        di as text "Note: not reported (in a term omitted because of collinearity):`skipped_un'"
    }
    if "`skipped_ne'" != "" {
        di as text "Note: not reported (not estimable; the level is part of an empty cell):`skipped_ne'"
    }

    return scalar N = e(N)
    return scalar N_clust = `M'
    return scalar level = `level'
    return local clustvar "`clv'"
    return local skipped "`skipped_ts' `skipped_ti' `skipped_un' `skipped_ne'"
    return matrix b = `ab'
    return matrix V = `aV'
end

capture mata: mata drop _xtgamfe_ape_cf()
capture mata: mata drop _xtgamfe_ape()

mata:

// Design matrix of the estimated terms with every component that is a
// level of factor variable v evaluated as if v equalled the given level.
// With v = 0 the actual design is returned.
real matrix _xtgamfe_ape_cf(real matrix C, real matrix TC, real matrix UM,
    real scalar v, real scalar level)
{
    real matrix X
    real scalar j, k, u

    X = J(rows(C), rows(TC), 1)
    for (j = 1; j <= rows(TC); j++) {
        for (k = 1; k <= cols(TC); k++) {
            u = TC[j, k]
            if (u == 0) continue
            if (v > 0 & UM[u, 1] == v & UM[u, 2] == 1) X[., j] = X[., j] :* (UM[u, 3] == level)
            else X[., j] = X[., j] :* C[., u]
        }
    }
    return(X)
}

// Average partial effects and their covariance.
//
// With mu_it = exp(alpha_i(b) + x_it'b + o_it) and the fixed effects
// profiled, the derivative of mu_it with respect to b is
// mu_it (x_it - xbar_i), xbar_i being the within-panel mean of x weighted
// by p_it = w_it exp(u_it)/sum_s w_is exp(u_is).  Each effect is a weighted
// average of f_it over the estimation sample:
//   continuous variable   f_it = mu_it * d(x_it'b)/dx
//   factor level l        f_it = mu_it(l) - mu_it(base)
// Its influence function for panel i is
//   sum_t w_it (f_it - theta) / sum(w)  -  J H^{-1} g_i,
// where J is the derivative of theta with respect to b and -H^{-1} g_i is
// the influence function of the coefficients.
void _xtgamfe_ape(
    string scalar ly_name,
    string scalar lny_name,
    string scalar uvars,
    string scalar touse_name,
    string scalar panid_name,
    string scalar w_name,
    string scalar wtype,
    string scalar clid_name,
    string scalar TC_name,
    string scalar UM_name,
    string scalar TG_name,
    string scalar b_name,
    string scalar b_out,
    string scalar V_out,
    string scalar M_out)
{
    real colvector y, lny, pid, w, beta, xb, u, sh, e, S, lnmean, p, mu
    real colvector Tp, Wp, wfirst, cl, clp, d, f, e1, e0, col, xcol
    real matrix C, TC, UM, TG, X, Xp, dX, Z, H, Hinv, Gs, info, A, D, X1, X0, Sc, Vout
    real rowvector s, theta, Jb, idx, isx, others
    real scalar n, K, G, q, t, j, k, i, m, v, sw, th, M, isfw

    y   = st_data(., ly_name,    touse_name)
    lny = st_data(., lny_name,   touse_name)
    C   = st_data(., tokens(uvars), touse_name)
    pid = st_data(., panid_name, touse_name)
    w   = st_data(., w_name,     touse_name)
    TC  = st_matrix(TC_name)
    UM  = st_matrix(UM_name)
    TG  = st_matrix(TG_name)
    beta = st_matrix(b_name)'
    isfw = (wtype == "fweight")

    n = rows(y)
    K = rows(TC)
    q = rows(TG)
    info = panelsetup(pid, 1)
    G = rows(info)
    Tp = info[., 2] - info[., 1] :+ 1
    Wp = panelsum(w, info)
    wfirst = w[info[., 1]]
    sw = quadsum(w)

    if (clid_name != "") {
        cl  = st_data(., clid_name, touse_name)
        clp = cl[info[., 1]]
    }

    // fitted quantities at the estimates
    X  = _xtgamfe_ape_cf(C, TC, UM, 0, 0)
    xb = X * beta
    u  = y - xb
    sh = panelsum(u, info) :/ Tp
    e  = exp(u - sh[pid])
    if (hasmissing(e)) {
        for (i = 1; i <= G; i++) sh[i] = max(u[|info[i, 1] \ info[i, 2]|])
        e = exp(u - sh[pid])
    }
    e  = w :* e
    S  = panelsum(e, info)
    lnmean = sh + ln(S) - ln(Wp)
    p  = e :/ S[pid]
    mu = exp(lny - u + lnmean[pid])

    Xp = panelsum(X, p, info)
    dX = X - Xp[pid, .]
    s  = sqrt(quadcolsum(dX:^2) / n)
    Z  = dX :/ s
    H  = cross(Z, Wp[pid] :* p, Z)
    H  = (H + H') / 2
    Hinv = invsym(H)
    Gs = panelsum(X, w - Wp[pid] :* p, info) :/ s

    theta = J(1, q, .)
    A = J(G, q, .)
    for (t = 1; t <= q; t++) {
        v = TG[t, 1]
        if (TG[t, 2] == 1) {
            // derivative of each estimated term with respect to variable v
            D = J(n, K, 0)
            for (j = 1; j <= K; j++) {
                idx = select(TC[j, .], TC[j, .] :> 0)
                isx = (UM[idx, 1]' :== v) :& (UM[idx, 2]' :== 0)
                m = sum(isx)
                if (m > 0) {
                    xcol = C[., select(idx, isx)[1]]
                    col = J(n, 1, m)
                    if (m > 1) col = col :* xcol:^(m - 1)
                    if (m < cols(idx)) {
                        others = select(idx, !isx)
                        for (k = 1; k <= cols(others); k++) col = col :* C[., others[k]]
                    }
                    D[., j] = col
                }
            }
            d  = D * beta
            f  = mu :* d
            th = quadsum(w :* f) / sw
            Jb = (quadcross(dX, w :* f) + quadcross(D, w :* mu))' / sw
        }
        else {
            X1 = _xtgamfe_ape_cf(C, TC, UM, v, TG[t, 3])
            X0 = _xtgamfe_ape_cf(C, TC, UM, v, TG[t, 4])
            e1 = exp((X1 - X) * beta)
            e0 = exp((X0 - X) * beta)
            f  = mu :* (e1 - e0)
            th = quadsum(w :* f) / sw
            Jb = (quadcross(X1 - Xp[pid, .], w :* mu :* e1) -
                  quadcross(X0 - Xp[pid, .], w :* mu :* e0))' / sw
        }
        theta[t] = th
        A[., t] = panelsum(w :* (f :- th), info) / sw - Gs * (Hinv * (Jb :/ s)')
    }

    if (clid_name == "") {
        if (isfw) {
            M = quadsum(wfirst)
            Vout = (M / (M - 1)) * cross(A :/ sqrt(wfirst), A :/ sqrt(wfirst))
        }
        else {
            M = G
            Vout = (M / (M - 1)) * cross(A, A)
        }
    }
    else {
        Sc = _xtgamfe_ape_csum(A, clp, M)
        Vout = (M / (M - 1)) * cross(Sc, Sc)
    }
    Vout = (Vout + Vout') / 2

    st_matrix(b_out, theta)
    st_matrix(V_out, Vout)
    st_numscalar(M_out, M)
}
end

capture mata: mata drop _xtgamfe_ape_csum()
mata:
// Sums of the rows of Z within groups defined by the integer vector id;
// n returns the number of groups.
real matrix _xtgamfe_ape_csum(real matrix Z, real colvector id, real scalar n)
{
    real colvector o
    real matrix cinfo

    o = order(id, 1)
    cinfo = panelsetup(id[o], 1)
    n = rows(cinfo)
    return(panelsum(Z[o, .], cinfo))
}
end
