*! xtgamfe 1.1.0  2026-11-13
*! Fixed-effects gamma regression with log link for strictly positive panel outcomes
*! Author: M. Christopher Roebuck, RxEconomics LLC
*
* Syntax:
*   xtgamfe depvar indepvars [if] [in] [weight] [, options]
*   indepvars may contain factor variables and time-series operators.
*   fweights, iweights, and pweights are allowed.
*
* Options:
*   vce(robust | cluster clustvar | oim | bootstrap | jackknife)
*   offset(varname)      log-scale offset: log mu = alpha_i + x'b + offset
*   tolerance(#)         Newton-decrement convergence tolerance (default 1e-6)
*   iterate(#)           maximum Newton iterations (default 1000)
*   nolog                suppress the iteration log
*   from(matname)        starting values for beta (1 x K or K x 1)
*   level(#)             confidence level for the coefficient table
*   eform                report exponentiated coefficients
*   display options      as for official estimation commands
program define xtgamfe, eclass sortpreserve
    version 15.0

    // ----------------------------------------------------------------
    // 1. vce(bootstrap) and vce(jackknife) are run by the standard prefix
    //    machinery, resampling panels.  Then dispatch replay vs. estimate.
    // ----------------------------------------------------------------
    //    The prefix commands reorder the data before the command sees it,
    //    so an if or in qualifier is resolved here, in the caller's order,
    //    and handed on as a marker variable.  Any vce() other than robust,
    //    cluster, and oim is treated as a resampling request, whatever its
    //    spelling (bootstrap, bs, bstrap, jackknife, jknife, ...).
    //
    //    The bootstrap prefix also drops the observations excluded by if or
    //    in before it resamples.  With a time-series operator in the model
    //    that removes rows that supply lags or leads to retained rows, and
    //    the replications would be run on a smaller sample than the fit.
    //    In that case the marker is passed as the internal option
    //    samplemark() instead of an if qualifier, so every row stays.
    local zero_typed : copy local 0
    local resamp = 0
    if !replay() {
        capture syntax anything [if] [in] [fweight iweight pweight] ///
            [, VCE(string) SAMPLEMARK(string) *]
        if _rc == 0 & `"`vce'"' != "" {
            gettoken vh : vce, parse(" ,")
            local vh = lower("`vh'")
            local vl = length("`vh'")
            local resamp = 1
            if strpos("robust", "`vh'") == 1 local resamp = 0
            if strpos("cluster", "`vh'") == 1 & `vl' >= 2 local resamp = 0
            if "`vh'" == "oim" local resamp = 0
        }
        if `resamp' & `"`samplemark'"' != "" {
            di as error "option samplemark() is internal to xtgamfe"
            exit 198
        }
        if `resamp' & `"`if'`in'"' != "" {
            local isboot = (strpos("bootstrap", "`vh'") == 1) | (strpos("bstrap", "`vh'") == 1)
            local ts_text = regexm(`" `anything'"', "[^A-Za-z0-9_][LFDSlfds][LFDSlfds0-9]*[.(]")
            tempvar premark
            mark `premark' `if' `in'
            local wt ""
            if "`weight'" != "" local wt "[`weight'`exp']"
            if `isboot' & `ts_text' {
                local 0 `"`anything' `wt', vce(`vce') samplemark(`premark') `options'"'
            }
            else local 0 `"`anything' if `premark' `wt', vce(`vce') `options'"'
        }
        else local 0 : copy local zero_typed
    }
    if `resamp' {
        // An error in a replication must not cost the caller the results
        // that were in memory: hold them, and let them come back unless
        // the resampling run succeeds.
        tempname ehold
        _estimates hold `ehold', restore nullok
    }
    _vce_parserun xtgamfe, panel jkopts(eclass) noeqlist: `0'
    if "`s(exit)'" != "" {
        if `resamp' _estimates drop `ehold'
        ereturn local cmdline `"xtgamfe `zero_typed'"'
        exit
    }
    if `resamp' {
        // not reached for a valid resampling request
        _estimates unhold `ehold'
    }
    local 0 : copy local zero_typed

    if replay() {
        if "`e(cmd)'" != "xtgamfe" error 301
        xtgamfe_display `0'
        exit
    }

    local cmdline0 : copy local 0
    // Record the caller's order before anything sorts the data.
    // signestimationsample evaluates the signature in this order.
    tempvar original_order
    quietly generate long `original_order' = _n

    // ----------------------------------------------------------------
    // 2. Syntax and scalar-option validation.  The variable list is first
    //    read as text: time-series operators cannot be validated until the
    //    data are in panel order, and if/in must be applied before that.
    // ----------------------------------------------------------------
    syntax anything(name=vlist id="varlist") [if] [in]   ///
        [fweight iweight pweight]                        ///
        [, VCE(string)                                   ///
           OFFset(varname numeric)                       ///
           TOLerance(real 1e-6)                          ///
           ITERate(integer 1000)                         ///
           noLOG                                         ///
           from(name)                                    ///
           Level(cilevel)                                ///
           EForm                                         ///
           SAMPLEMARK(varname numeric)                   ///
           *                                             ///
        ]
    _get_diopts diopts, `options'

    if missing(`tolerance') | `tolerance' <= 0 {
        di as error "tolerance() must be strictly positive"
        exit 198
    }
    if missing(`iterate') | `iterate' < 1 {
        di as error "iterate() must be at least 1"
        exit 198
    }

    // ----------------------------------------------------------------
    // 3. if, in, and weights select observations now, in the caller's
    //    observation order.  (Through 1.0.0 the sample was marked after
    //    xtset had sorted the data, so an in range picked other rows.)
    // ----------------------------------------------------------------
    if regexm(`" `exp'"', "[^A-Za-z0-9_][LFDSlfds][LFDSlfds0-9]*[.(]") {
        di as error "time-series operators are not allowed in the weight expression"
        di as error "generate the weight variable first, for example:  generate double w1 = L.w"
        exit 198
    }
    tempvar touse0 ifin0
    mark `touse0' `if' `in' [`weight'`exp']
    // samplemark() is set only by xtgamfe itself, for vce(bootstrap)
    if "`samplemark'" != "" quietly replace `touse0' = 0 if `samplemark' == 0
    // the if and in selection alone, used below to see whether it splits
    // a panel
    mark `ifin0' `if' `in'
    local has_ifin = (`"`if'`in'"' != "")

    local wtype    "`weight'"
    local wexp     `"`exp'"'
    local vce_o    `"`vce'"'
    local offset_o "`offset'"
    local tol_o    `tolerance'
    local iter_o   `iterate'
    local log_o    "`log'"
    local from_o   "`from'"
    local level_o  `level'
    local eform_o  "`eform'"
    local diopts_o `"`diopts'"'

    // ----------------------------------------------------------------
    // 4. Panel setup
    // ----------------------------------------------------------------
    capture quietly xtset
    if _rc {
        di as error "data must be xtset with a panel variable before calling xtgamfe"
        di as error "use, e.g.:  xtset panelvar timevar"
        exit 459
    }
    local panvar  "`r(panelvar)'"
    local timevar "`r(timevar)'"
    if "`panvar'" == "" {
        di as error "data must be xtset with a panel variable"
        exit 459
    }

    // ----------------------------------------------------------------
    // 5. Variable list, now that the data are in panel order
    // ----------------------------------------------------------------
    local 0 `"`vlist' if `touse0'"'
    syntax varlist(numeric fv ts min=2) [if]
    gettoken depvar rhs : varlist

    if strpos("`depvar'", ".") | strpos("`depvar'", "#") {
        di as error "the dependent variable may not carry factor-variable or time-series operators"
        exit 198
    }
    confirm numeric variable `depvar'
    unab depvar : `depvar'

    if "`rhs'" == "" {
        di as error "must specify at least one regressor"
        exit 102
    }

    marksample touse
    markout `touse' `panvar'
    if "`offset_o'" != "" markout `touse' `offset_o'

    // ----------------------------------------------------------------
    // 6. VCE option.  robust is clustering on the panel variable; a
    //    cluster variable in which the panels are nested is allowed.
    //    Standard unambiguous abbreviations are accepted.
    // ----------------------------------------------------------------
    local vcetype "robust"
    local clustvar "`panvar'"
    if `"`vce_o'"' == "" local vce_o "robust"
    gettoken vhead vrest : vce_o
    local vhead = lower("`vhead'")
    local vrest : list clean vrest
    if strpos("robust", "`vhead'") == 1 & "`vrest'" == "" {
        // default; nothing further to check
    }
    else if strpos("cluster", "`vhead'") == 1 & length("`vhead'") >= 2 {
        if "`vrest'" == "" {
            di as error "vce(cluster) requires a cluster variable"
            exit 198
        }
        capture unab vrest : `vrest'
        if _rc | `: word count `vrest'' != 1 {
            di as error "vce(cluster `vrest'): variable not found or ambiguous"
            exit 111
        }
        local clustvar "`vrest'"
    }
    else if "`vhead'" == "oim" & "`vrest'" == "" {
        local vcetype "oim"
        if inlist("`wtype'", "pweight", "iweight") {
            di as error "vce(oim) may not be combined with `wtype's"
            exit 198
        }
    }
    else {
        di as error `"vce(`vce_o') not supported;"' ///
            " use vce(robust), vce(cluster clustvar), vce(oim), vce(bootstrap), or vce(jackknife)"
        exit 198
    }
    local nested_cluster = ("`vcetype'" == "robust" & "`clustvar'" != "`panvar'")
    if `nested_cluster' markout `touse' `clustvar', strok

    // ----------------------------------------------------------------
    // 7. Weights
    // ----------------------------------------------------------------
    tempvar wv
    if "`wtype'" != "" {
        quietly generate double `wv' `wexp' if `touse'
        markout `touse' `wv'
        capture assert `wv' >= 0 if `touse'
        if _rc {
            di as error "negative weights encountered"
            exit 402
        }
        if "`wtype'" == "fweight" {
            capture assert `wv' == int(`wv') if `touse'
            if _rc {
                di as error "may not use noninteger frequency weights"
                exit 401
            }
        }
        quietly replace `touse' = 0 if `wv' == 0
    }
    else quietly generate byte `wv' = 1 if `touse'

    // Numeric cluster identifier (egen may reorder the data; the panel
    // order is restored immediately below).
    tempvar clid
    if `nested_cluster' {
        quietly egen long `clid' = group(`clustvar') if `touse'
    }
    sort `panvar' `timevar'

    // ----------------------------------------------------------------
    // 8. Drop singleton panels, then enforce positivity on the retained
    //    slope-estimation sample.  A nonpositive singleton cannot affect beta.
    // ----------------------------------------------------------------
    tempvar Ti
    quietly by `panvar': generate long `Ti' = sum(`touse')
    quietly by `panvar': replace `Ti' = `Ti'[_N]

    local n_sing = 0
    quietly count if `touse' & `Ti' == 1
    if r(N) > 0 {
        local n_sing = r(N)
        di as text "note: `n_sing' singleton observation(s) (Ti=1) excluded from estimation"
        quietly replace `touse' = 0 if `Ti' == 1
    }

    quietly count if `touse'
    if r(N) == 0 {
        di as error "no observations remain after dropping singletons"
        exit 2000
    }

    quietly count if `touse' & (`depvar' <= 0)
    if r(N) > 0 {
        di as error "`depvar' has `r(N)' nonpositive value(s) in the retained estimation sample"
        di as error "xtgamfe requires strictly positive outcomes in nonsingleton panels"
        exit 459
    }

    // ----------------------------------------------------------------
    // 9. Numeric panel id (1..G) in panel order
    // ----------------------------------------------------------------
    tempvar pfirst panid
    quietly by `panvar': generate byte `pfirst' = `touse' & (sum(`touse') == 1)
    quietly generate long `panid' = sum(`pfirst')
    quietly replace `panid' = . if !`touse'
    quietly summarize `panid' if `touse', meanonly
    local N_panels = r(max)

    if `N_panels' < 2 {
        di as error "at least two retained panels are required"
        exit 459
    }

    // ----------------------------------------------------------------
    // 10. Expand factor variables and time-series operators.  Base and
    //     empty-cell terms are not estimated, but they keep their place in
    //     the posted coefficient vector (as b. and o. columns) so that
    //     contrast and other factor-variable postestimation tools see the
    //     full term list.  est_pos records the position of each estimated
    //     term in that list.
    // ----------------------------------------------------------------
    fvexpand `rhs' if `touse'
    local rhs_expanded "`r(varlist)'"
    fvrevar `rhs_expanded' if `touse'
    local rhs_revars "`r(varlist)'"
    local n_exp : word count `rhs_expanded'
    local n_rev : word count `rhs_revars'
    if `n_exp' != `n_rev' {
        di as error "xtgamfe internal error: fvrevar returned `n_rev' variables for `n_exp' terms"
        exit 459
    }

    local rhs_names ""
    local rhsv ""
    local est_pos ""
    local j = 0
    foreach t of local rhs_expanded {
        local j = `j' + 1
        local v : word `j' of `rhs_revars'
        _ms_parse_parts `t'
        if !((r(base) == 1) | (r(omit) == 1)) {
            local rhs_names "`rhs_names' `t'"
            local rhsv "`rhsv' `v'"
            local est_pos "`est_pos' `j'"
        }
    }
    local rhs_names : list clean rhs_names
    local rhsv      : list clean rhsv

    // Does the model contain a time-series operator?
    local has_ts = 0
    foreach term of local rhs_expanded {
        local components : subinstr local term "#" " ", all
        foreach component of local components {
            _ms_parse_parts `component'
            if "`r(ts_op)'" != "" local has_ts = 1
        }
    }
    // Under the bootstrap prefix, the observations excluded by if or in
    // are dropped before resampling.  If the selection splits a panel and
    // the model has a time-series operator, rows that supply lags or leads
    // to the estimation sample would be lost in every replication and the
    // standard errors would be those of a smaller sample.  vce(bootstrap)
    // avoids this (section 1); the prefix typed by the user cannot.
    if `has_ts' & `has_ifin' & strpos("`c(prefix)'", "bootstrap") {
        tempvar sel_lo sel_hi
        quietly egen byte `sel_lo' = min(`ifin0'), by(`panvar')
        quietly egen byte `sel_hi' = max(`ifin0'), by(`panvar')
        quietly count if `sel_lo' != `sel_hi'
        local n_split = r(N)
        sort `panvar' `timevar'
        if `n_split' > 0 {
            di as error "the model has time-series operators and the if or in qualifier excludes"
            di as error "part of a panel: bootstrap would drop the excluded rows, including rows"
            di as error "that supply lags or leads to the estimation sample, before it resamples"
            di as error "use xtgamfe's option vce(bootstrap), which keeps them, or generate the"
            di as error "lagged variables before selecting the sample"
            exit 198
        }
    }
    if "`rhs_names'" == "" {
        di as error "no estimable regressors remain after dropping base levels"
        exit 102
    }
    local K : word count `rhsv'

    // The dependent variable may not also be a regressor.  Terms without
    // within-panel variation, and terms collinear after the within
    // transformation, are identified in Mata on the within-centered design,
    // where the checks are invariant to the origin and units of each
    // regressor.  Such terms are omitted with a note and posted as omitted
    // columns, as official estimators do.
    foreach v of local rhsv {
        if "`v'" == "`depvar'" {
            di as error "the dependent variable `depvar' may not also be a regressor"
            exit 198
        }
    }

    // ----------------------------------------------------------------
    // 11. Log outcome, offset, and starting values
    // ----------------------------------------------------------------
    tempvar lny lyo alpha_v
    quietly generate double `lny' = ln(`depvar') if `touse'
    if "`offset_o'" != "" quietly generate double `lyo' = `lny' - `offset_o' if `touse'
    else                    quietly generate double `lyo' = `lny' if `touse'
    quietly generate double `alpha_v' = .

    tempname b0
    local b0name ""
    if "`from_o'" != "" {
        confirm matrix `from_o'
        if rowsof(`from_o') == `K' & colsof(`from_o') == 1 matrix `b0' = `from_o''
        else                                                  matrix `b0' = `from_o'
        if rowsof(`b0') != 1 | colsof(`b0') != `K' {
            di as error "from() must be a 1 x `K' (or `K' x 1) vector of starting values"
            exit 503
        }
        forvalues j = 1/`K' {
            if missing(`b0'[1,`j']) {
                di as error "from() contains missing or nonfinite values"
                exit 504
            }
        }
        local b0name "`b0'"
    }

    // ----------------------------------------------------------------
    // 12. Fit.  The data are in panel order; Mata reads the estimation
    //     sample, optimizes, and returns every numerical result.
    // ----------------------------------------------------------------
    tempname b V omit_out stats fe_vec fe_id_vec
    local nolog_flag = ("`log_o'" == "nolog")
    local fe_post_max = 5000
    local clid_name ""
    if `nested_cluster' local clid_name "`clid'"

    mata: _xtgamfe_fit(                                          ///
        "`lyo'", "`lny'", "`rhsv'", "`touse'", "`panid'", "`wv'", ///
        "`wtype'", "`clid_name'", "`vcetype'",                   ///
        `tol_o', `iter_o', `nolog_flag', "`b0name'",             ///
        "`b'", "`V'", "`omit_out'", "`stats'",                   ///
        "`alpha_v'", "`panvar'", `fe_post_max', "`fe_vec'", "`fe_id_vec'")

    local conv_flag     = `stats'[1, 1]
    local iter_value    = `stats'[1, 2]
    local gnorm_value   = `stats'[1, 3]
    local conv_code     = `stats'[1, 4]
    local decrement_val = `stats'[1, 5]
    local rank_h        = `stats'[1, 6]
    local rank_v        = `stats'[1, 7]
    local hcondition    = `stats'[1, 8]
    local N_clust       = `stats'[1, 9]
    local wconst        = `stats'[1, 10]
    local sum_pearson   = `stats'[1, 11]
    local kappa_hat     = `stats'[1, 12]
    local shape_code    = `stats'[1, 13]
    local kappa_ml      = `stats'[1, 14]
    local kappa_ml_se   = `stats'[1, 15]
    local ll            = `stats'[1, 16]
    local N_obs_final   = `stats'[1, 17]
    local N_g_final     = `stats'[1, 18]
    local g_min         = `stats'[1, 19]
    local g_avg         = `stats'[1, 20]
    local g_max         = `stats'[1, 21]
    local fe_ok         = `stats'[1, 22]
    local kml_code      = `stats'[1, 23]

    // Omitted terms: note each one and build the posted coefficient names.
    // Codes: 1 no within-panel variation; 2 collinear with earlier terms;
    //        3 within-panel variation at rounding level only.
    local k_omit = 0
    local names_post ""
    local names_post_o ""
    local omitted_terms ""
    forvalues j = 1/`K' {
        local nm : word `j' of `rhs_names'
        local oc = `omit_out'[1, `j']
        if `oc' == 0 {
            local names_post "`names_post' `nm'"
            local names_post_o "`names_post_o' `nm'"
        }
        else {
            local k_omit = `k_omit' + 1
            local omitted_terms "`omitted_terms' `nm'"
            _ms_put_omit `nm'
            local names_post "`names_post' `nm'"
            local names_post_o "`names_post_o' `s(ospec)'"
            if `oc' == 1 {
                di as text "note: `nm' omitted because it has no within-panel variation"
            }
            else if `oc' == 2 {
                di as text "note: `nm' omitted because of collinearity after the within-panel transformation"
            }
            else {
                di as text "note: `nm' omitted because its within-panel variation is below 1e-12 of its" ///
                    " magnitude; if that variation is real, subtract a constant from it"
            }
        }
    }
    local names_post    : list clean names_post
    local names_post_o  : list clean names_post_o
    local omitted_terms : list clean omitted_terms
    local K_est = `K' - `k_omit'

    // Convergence is declared on the Newton decrement only (code 2), or,
    // when no representable decrease of the objective remains, at the
    // numerical resolution of the objective (code 5).  The gradient norm is
    // reported but is not a stopping criterion.
    local converged_by "none"
    if `conv_code' == 2 local converged_by "newton_decrement"
    if `conv_code' == 3 local converged_by "step_failure"
    if `conv_code' == 4 local converged_by "maxiter"
    if `conv_code' == 5 local converged_by "objective_resolution"

    if `conv_flag' == 0 {
        if `conv_code' == 3 {
            di as error "xtgamfe line search failed after `iter_value' completed Newton iteration(s)"
        }
        else {
            di as error "xtgamfe did not converge after `iter_value' completed Newton iteration(s)" ///
                " (reason: `converged_by')"
        }
        di as error "achieved Newton decrement = " %12.5g `decrement_val' ///
            " (tolerance " %9.3g `tol_o' ")"
        di as error "achieved gradient norm (standardized regressors) = " %12.5g `gnorm_value'
        exit 430
    }

    if `hcondition' >= . | `hcondition' > 1e12 {
        di as error "warning: the profiled Hessian is ill-conditioned" ///
            " (condition number = " %10.3g `hcondition' ")"
    }

    // ----------------------------------------------------------------
    // 13. Shape estimates.  e(kappa) is the fixed-T moment estimate;
    //     e(kappa_ml) maximizes the marginal likelihood of the within-panel
    //     shares.  Neither is defined when weights vary within panel.
    // ----------------------------------------------------------------
    local df_kappa      = `N_obs_final' - `N_g_final' - `K_est'
    local kappa_pearson = .
    if `wconst' & `sum_pearson' > 0 & `sum_pearson' < . & `df_kappa' > 0 {
        local kappa_pearson = `df_kappa' / `sum_pearson'
    }

    local shape_status "finite"
    if `shape_code' == 1 local shape_status "infinite_precision"
    if `shape_code' == 2 local shape_status "no_positive_root"
    if `shape_code' == 3 local shape_status "unbracketed"
    if `shape_code' == 4 local shape_status "invalid_moment"
    if `shape_code' == 6 local shape_status "weights_vary_within_panel"

    if "`shape_status'" == "infinite_precision" {
        di as text "note: no finite gamma shape estimate; the Pearson moment is numerically zero"
    }
    else if "`shape_status'" == "no_positive_root" {
        di as text "note: no positive gamma shape root; the observed moment is outside the model-implied range"
    }
    else if "`shape_status'" == "unbracketed" {
        di as text "note: shape root could not be bracketed within double-precision limits"
    }
    else if "`shape_status'" == "invalid_moment" {
        di as text "note: gamma shape moment is nonfinite or otherwise invalid"
    }
    else if "`shape_status'" == "weights_vary_within_panel" {
        di as text "note: the gamma shape and the log likelihood are not computed" ///
            " because the weights vary within panel"
        di as text "note: with weights that vary within panel, weights whose within-panel" ///
            " pattern"
        di as text "      follows that of the regressors can bias the coefficients;"
        di as text "      see {help xtgamfe##weights:help xtgamfe}"
    }

    local phi_hat = .
    if `kappa_hat' < . & `kappa_hat' > 0 local phi_hat = 1 / `kappa_hat'

    if "`vcetype'" == "oim" & (`kappa_ml' >= . | `rank_v' >= .) {
        di as error "vce(oim) requires a finite maximum likelihood estimate of the gamma shape," ///
            " which is not available for these data; use vce(robust)"
        exit 459
    }

    if `fe_ok' {
        matrix colnames `fe_vec' = fe
        matrix colnames `fe_id_vec' = panel_id
    }
    else {
        di as text "note: e(fe) and e(fe_id) are posted only for up to `fe_post_max' panels" ///
            " (or the matrix-size limit of this Stata flavor, if lower); use predict, fe"
    }

    // ----------------------------------------------------------------
    // 14. Omnibus Wald test of the estimated (non-omitted) coefficients.
    // ----------------------------------------------------------------
    tempname wald_out p_wald_out b_est V_est
    mata: st_matrix("`b_est'", select(st_matrix("`b'"), st_matrix("`omit_out'") :== 0))
    mata: st_matrix("`V_est'", select(select(st_matrix("`V'"), st_matrix("`omit_out'") :== 0), st_matrix("`omit_out'")' :== 0))
    mata: _xtgamfe_wald("`b_est'", "`V_est'", `rank_v', ///
        "`wald_out'", "`p_wald_out'")
    local wald = `wald_out'
    local p_wald = `p_wald_out'

    // Underlying variables used for the estimation-sample signature.
    local sigvars "`depvar' `panvar' `timevar' `offset_o'"
    if `nested_cluster' local sigvars "`sigvars' `clustvar'"
    foreach term of local rhs_expanded {
        local components : subinstr local term "#" " ", all
        foreach component of local components {
            local base "`component'"
            while strpos("`base'", ".") > 0 {
                local base = substr("`base'", strpos("`base'", ".") + 1, .)
            }
            local sigvars "`sigvars' `base'"
        }
    }
    local sigvars : list clean sigvars
    local sigvars : list uniq sigvars

    // ----------------------------------------------------------------
    // 15. Post results and sign the immutable estimation state used by fe/mu.
    // ----------------------------------------------------------------
    // Full coefficient vector: every term of the expanded list, with zero
    // coefficient and variance for base, empty-cell, and omitted terms.
    // Two spellings of the names are prepared: one in which the omitted
    // terms keep their plain names, and one in which they carry the o.
    // operator (see below for which is posted).
    local names_full ""
    local names_full_o ""
    local j = 0
    local k = 0
    foreach t of local rhs_expanded {
        local j = `j' + 1
        local is_est : list posof "`j'" in est_pos
        if `is_est' {
            local k = `k' + 1
            local nm  : word `k' of `names_post'
            local nmo : word `k' of `names_post_o'
            local names_full "`names_full' `nm'"
            local names_full_o "`names_full_o' `nmo'"
        }
        else {
            local names_full "`names_full' `t'"
            local names_full_o "`names_full_o' `t'"
        }
    }
    local names_full   : list clean names_full
    local names_full_o : list clean names_full_o
    tempname b_post V_post b_alt V_alt
    mata: _xtgamfe_expand("`b'", "`V'", strtoreal(tokens("`est_pos'")), `n_exp', "`b_post'", "`V_post'")
    matrix `b_alt' = `b_post'
    matrix `V_alt' = `V_post'
    matrix colnames `b_post' = `names_full'
    matrix colnames `V_post' = `names_full'
    matrix rownames `V_post' = `names_full'
    matrix colnames `b_alt' = `names_full_o'
    matrix colnames `V_alt' = `names_full_o'
    matrix rownames `V_alt' = `names_full_o'

    local N_post = `N_obs_final'
    ereturn post `b_post' `V_post', obs(`N_post') esample(`touse') ///
        depname("`depvar'")

    // Estimable-function information for contrast and pwcompare.
    //
    // The panel effects absorb the constant, so the check must treat the
    // model as having one.  Official conditional fixed-effects commands
    // (clogit; xtpoisson, fe) arrange this with the ADDCONS option of
    // ereturn repost together with the hidden macro e(marginsprop); the
    // same is done here.  That information is computed from the raw
    // regressors, in which a term omitted for lack of within-panel
    // variation looks estimable; as in xtpoisson, fe, such terms are
    // therefore posted under their plain names with a zero coefficient and
    // zero variance, and are displayed as omitted.
    //
    // Neither ADDCONS nor e(marginsprop) is in the ereturn documentation.
    // If a Stata release rejects either, the results are posted without
    // estimable-function information and with the o. operator on omitted
    // terms: contrast and pwcompare then rely on the b. and o. operators
    // alone and say that the estimability check was not performed.  Plain
    // buildfvinfo is never used: without the constant it gives wrong
    // degrees of freedom or reports valid contrasts as not testable.
    local fvinfo_ok = 0
    capture ereturn hidden local marginsprop "addcons"
    if _rc == 0 {
        capture ereturn repost, buildfvinfo ADDCONS
        if _rc == 0 local fvinfo_ok = 1
        else capture ereturn hidden local marginsprop ""
    }
    if !`fvinfo_ok' {
        ereturn repost b = `b_alt' V = `V_alt', rename
    }
    capture ereturn hidden scalar fvinfo_ok = `fvinfo_ok'

    // The results above are posted while the data are still in panel order,
    // which the estimable-function check needs when the model has
    // time-series operators.  signestimationsample is evaluated in the
    // caller's observation order: restoring that order before signing makes
    // immediate fe/mu prediction compatible with sortpreserve and makes
    // later row reordering detectable.
    // The weight enters the signature through e(wexp), which
    // signestimationsample and checkestimationsample both read.
    if "`wtype'" != "" {
        ereturn local wexp  `"`wexp'"'
        ereturn local wtype "`wtype'"
    }
    sort `original_order'
    // With time-series operators the realized regressors depend on rows
    // outside the estimation sample (the rows that supply lags and leads).
    // The realized columns are then signed as well, so that predict detects
    // a change in those rows.
    if `has_ts' signestimationsample `sigvars', extra(`rhs_revars')
    else        signestimationsample `sigvars'

    local few_clusters = ("`vcetype'" == "robust" & `N_clust' < 30)

    ereturn scalar N_g              = `N_g_final'
    ereturn scalar N_panels         = `N_g_final'
    if "`vcetype'" == "robust" ereturn scalar N_clust = `N_clust'
    ereturn scalar N_singletons     = `n_sing'
    ereturn scalar g_min            = `g_min'
    ereturn scalar g_avg            = `g_avg'
    ereturn scalar g_max            = `g_max'
    // e(rank) follows the official convention: the rank of e(V).  The
    // Hessian rank remains available separately as e(rank_h).
    ereturn scalar rank             = `rank_v'
    ereturn scalar rank_h           = `rank_h'
    ereturn scalar rank_v           = `rank_v'
    ereturn scalar hcondition       = `hcondition'
    ereturn scalar k_omitted        = `k_omit'
    ereturn scalar few_clusters     = `few_clusters'
    ereturn scalar df_m             = `rank_v'
    ereturn scalar chi2             = `wald'
    ereturn scalar p                = `p_wald'
    ereturn scalar converged        = `conv_flag'
    ereturn scalar iterations       = `iter_value'
    ereturn scalar gnorm            = `gnorm_value'
    ereturn scalar newton_decrement = `decrement_val'
    ereturn scalar tolerance        = `tol_o'
    ereturn scalar kappa            = `kappa_hat'
    ereturn scalar phi              = `phi_hat'
    ereturn scalar kappa_pearson    = `kappa_pearson'
    ereturn scalar kappa_ml         = `kappa_ml'
    ereturn scalar kappa_ml_se      = `kappa_ml_se'
    ereturn scalar ll               = `ll'
    ereturn scalar pearson_ss       = `sum_pearson'
    ereturn scalar df_kappa         = `df_kappa'
    ereturn scalar level            = `level_o'
    if `fe_ok' {
        ereturn matrix fe    = `fe_vec'
        ereturn matrix fe_id = `fe_id_vec'
    }

    ereturn local chi2type       "Wald"
    ereturn local converged_by   "`converged_by'"
    ereturn local shape_status   "`shape_status'"
    ereturn local version        "1.1.0"
    if "`offset_o'" != "" ereturn local offset "`offset_o'"
    if "`vcetype'" == "robust" {
        ereturn local clustvar   "`clustvar'"
        ereturn local vce        "cluster"
        ereturn local vcetype    "Robust"
    }
    else {
        ereturn local vce        "oim"
    }
    ereturn local panvar         "`panvar'"
    ereturn local timevar        "`timevar'"
    ereturn local indepvars      "`rhs_names'"
    ereturn local indepvars_full "`rhs_expanded'"
    ereturn local omitted        "`omitted_terms'"
    ereturn local depvar         "`depvar'"
    ereturn local title          "FE gamma regression (log link)"
    ereturn local predict        "xtgamfe_p"
    ereturn local estat_cmd      "xtgamfe_estat"
    capture ereturn hidden scalar has_ts = `has_ts'
    // margins support is not implemented; block it rather than let it
    // produce xb-scale output that ignores the fixed effect and offset.
    // estat ape reports average partial effects on the outcome scale.
    ereturn local marginsnotok   "_ALL"
    ereturn local cmdline        `"xtgamfe `cmdline0'"'
    ereturn local cmd            "xtgamfe"

    if "`eform_o'" != "" local eform_o "eform"
    xtgamfe_display, level(`level_o') `eform_o' `diopts_o'
end

// ---------------------------------------------------------------
// Display subroutine (also serves replay)
// ---------------------------------------------------------------
program define xtgamfe_display
    version 15.0
    syntax [, Level(passthru) EForm *]
    _get_diopts diopts, `options'
    if "`level'" == "" local level "level(`=e(level)')"
    if "`eform'" != "" local eformopt "eform(exp(b))"
    local convtxt = cond(e(converged), "yes", "NO")

    di ""
    di as text "Fixed-effects gamma regression (log link)"
    di as text "Panel variable: " as result "`e(panvar)'"       ///
       as text "                    Obs: "  as result e(N)
    di as text "Number of panels: " as result e(N_g)            ///
       as text "     Obs per panel: min " as result e(g_min)    ///
       as text ", avg " as result %4.1f e(g_avg)                ///
       as text ", max " as result e(g_max)

    if e(kappa) < . {
        di as text "Gamma shape kappa (fixed-T moment): " as result %9.4f e(kappa) ///
           as text "   dispersion 1/kappa: " as result %9.4f e(phi)
    }
    else {
        di as text "Gamma shape kappa (fixed-T moment): " as result "n/a" ///
           as text "  (" as result "`e(shape_status)'" as text ")"
    }
    if e(kappa_ml) < . {
        di as text "Gamma shape kappa (marginal ML):    " as result %9.4f e(kappa_ml) ///
           as text "   std. err.:          " as result %9.4f e(kappa_ml_se)
    }
    if `"`e(offset)'"' != "" di as text "Offset: " as result "`e(offset)'"
    if `"`e(wtype)'"' != ""  di as text "Weights: " as result "[`e(wtype)'`e(wexp)']"

    if e(df_m) > 0 & e(chi2) < . {
        di as text "Wald chi2(" as result e(df_m) as text ") = " ///
           as result %9.2f e(chi2)                              ///
           as text "      Prob > chi2 = " as result %6.4f e(p)
    }
    else if e(F) < . & "`e(prefix)'" != "" {
        di as text "F(" as result e(df_m) as text ", " as result e(df_r) as text ") = " ///
           as result %9.2f e(F)                                 ///
           as text "      Prob > F = " as result %6.4f e(p)
    }
    else if e(rank_v) < e(rank_h) {
        di as text "Omnibus Wald test: " as result "not reported" ///
           as text " (rank of e(V) is " as result e(rank_v)       ///
           as text ", below the " as result e(rank_h) as text " coefficients)"
    }
    else di as text "Omnibus Wald test: " as result "not available"

    di as text "Convergence: " as result "`convtxt'"            ///
       as text " (" as result "`e(converged_by)'" as text ")" ///
       as text "       Iterations: " as result e(iterations)
    di as text "Gradient norm: " as result %10.3g e(gnorm)      ///
       as text "       Hessian rank: " as result e(rank_h)      ///
       as text "       VCE rank: " as result e(rank_v)

    if "`e(converged_by)'" == "objective_resolution" {
        di as text "note: convergence declared at the numerical resolution of the objective;" ///
            " achieved Newton decrement = " as result %9.3g e(newton_decrement)
    }
    if e(fvinfo_ok) == 0 {
        di as text "note: this Stata did not accept the estimable-function information for the" ///
            " model;"
        di as text "      contrast and pwcompare do not check estimability, so do not rely on" ///
            " a contrast"
        di as text "      that involves an empty cell or an omitted term"
    }
    if e(few_clusters) == 1 & "`e(prefix)'" == "" {
        di as error "warning: conventional cluster-robust normal inference may be unreliable" ///
            " with only " e(N_clust) " clusters"
    }
    if e(rank_v) < e(rank_h) & "`e(prefix)'" == "" {
        local why ""
        if e(N_clust) < . & e(N_clust) - 1 < e(rank_h) local why " (too few clusters)"
        di as error "warning: e(V) has rank " e(rank_v) ", below the " e(rank_h) ///
            " estimated coefficients`why';"
        di as error "         joint tests of all coefficients are not available"
        if "`why'" == "" & e(rank_v) > 0 {
            di as error "         (the cluster scores do not span the coefficients: a coefficient" ///
                " may rest on one cluster)"
        }
        if e(rank_v) == 0 {
            di as error "         (every score is zero: the model fits the estimation sample exactly," ///
                " so the standard errors"
            di as error "          are zero and coefficients estimated as zero are displayed as omitted)"
        }
    }

    di ""
    if "`e(prefix)'" != "" _coef_table, `level' `eformopt' `diopts'
    else ereturn display, `level' `eformopt' `diopts'
end

// ===================================================================
// Embedded Mata core. The capture-drop prelude makes discard/reload safe.
// ===================================================================
capture mata: mata drop _xtgamfe_wald()
capture mata: mata drop _xtgamfe_center()
capture mata: mata drop _xtgamfe_expand()
capture mata: mata drop _xtgamfe_eval()
capture mata: mata drop _xtgamfe_csum()
capture mata: mata drop _xtgamfe_bygroup()
capture mata: mata drop _xtgamfe_shape_moment()
capture mata: mata drop _xtgamfe_shape_solve()
capture mata: mata drop _xtgamfe_shape()
capture mata: mata drop _xtgamfe_kml_score()
capture mata: mata drop _xtgamfe_kml()
capture mata: mata drop _xtgamfe_fit()

mata:

// Omnibus Wald test of all slope coefficients, shared by estimation and the
// acceptance tests.  The test is reported only when the covariance matrix
// has full rank.  With a singular V (for example, fewer than K+1 clusters)
// a quadratic form in a generalized inverse tests only the coefficients the
// inverse happens to retain, and which ones it retains changes with the
// units of the regressors; no such number is a test of the joint null, so
// the statistic and its p-value are returned as missing.  The quadratic
// form is evaluated on the correlation scale, which makes it exactly
// invariant to rescaling of individual regressors.  The rank argument is
// the covariance rank found by the optimizer.
void _xtgamfe_wald(
    string scalar b_name,
    string scalar V_name,
    real scalar rank,
    string scalar wald_name,
    string scalar p_name)
{
    real matrix V, R, Rinv, WW
    real rowvector b, d, z
    real scalar K, wald_q, wald, p_wald

    wald = .
    p_wald = .
    b = st_matrix(b_name)
    V = st_matrix(V_name)
    K = cols(b)
    if (K > 0 & rank == K & rows(V) == K & cols(V) == K &
        !hasmissing(b) & !hasmissing(V)) {
        d = sqrt(diagonal(V))'
        if (min(d) > 0) {
            R = V :/ (d' * d)
            R = (R + R') / 2
            Rinv = invsym(R)
            if (diag0cnt(Rinv) == 0) {
                z = b :/ d
                WW = z * Rinv * z'
                wald_q = WW[1, 1]
                if (!missing(wald_q)) {
                    wald = max((wald_q, 0))
                    p_wald = chi2tail(K, wald)
                }
            }
        }
    }
    st_numscalar(wald_name, wald)
    st_numscalar(p_name, p_wald)
}

// Place the K estimated-term results into the full n-term coefficient
// vector and covariance matrix; all other entries are zero.
void _xtgamfe_expand(
    string scalar b_name,
    string scalar V_name,
    real rowvector pos,
    real scalar n,
    string scalar b_out,
    string scalar V_out)
{
    real rowvector bfull
    real matrix Vfull

    bfull = J(1, n, 0)
    bfull[pos] = st_matrix(b_name)
    Vfull = J(n, n, 0)
    Vfull[pos, pos] = st_matrix(V_name)
    st_matrix(b_out, bfull)
    st_matrix(V_out, Vfull)
}

// Within-panel centering at the weighted panel means.  Two passes: the
// second removes the rounding error left by the first when a regressor has
// a large origin.  The profiled criterion, its score, and its Hessian are
// exactly invariant to subtracting a panel-specific constant from any
// regressor.
//
// Xbar returns the panel means that were removed, which are needed to
// express the fixed effects in the original parameterization.
real matrix _xtgamfe_center(real matrix X, real colvector w,
    real matrix info, real colvector pid, real colvector Wp, real matrix Xbar)
{
    real matrix Xc, m2

    Xbar = panelsum(X, w, info) :/ Wp
    Xc = X - Xbar[pid, .]
    m2 = panelsum(Xc, w, info) :/ Wp
    Xc = Xc - m2[pid, .]
    Xbar = Xbar + m2
    return(Xc)
}

// Profiled criterion and its derivatives.
//
//   Q(b) = sum_i W_i * ln( sum_t w_it exp(u_it) / W_i ) + sum_it w_it x_it'b,
//   u_it = ln(y_it) - offset_it - x_it'b,   W_i = sum_t w_it.
//
// todo = 0: Q only; 1: Q and g; 2: Q, g, and H.  lnmean returns the log of
// the weighted panel mean of exp(u), which is the profiled fixed effect.
// p returns the within-panel weights w_it exp(u_it) / sum_s w_is exp(u_is).
// The exponent is shifted by the panel mean of u; if any panel's spread in
// u is so large that this overflows, the panel maximum is used instead.
void _xtgamfe_eval(
    real scalar    todo,
    real colvector y,
    real matrix    X,
    real colvector w,
    real matrix    info,
    real colvector pid,
    real colvector Wp,
    real colvector Tp,
    real colvector beta,
    real scalar    Q,
    real colvector g,
    real matrix    H,
    real colvector p,
    real colvector lnmean)
{
    real colvector xb, u, sh, e, S
    real matrix    dX
    real scalar    i

    xb = X * beta
    u  = y - xb
    sh = panelsum(u, info) :/ Tp
    e  = exp(u - sh[pid])
    if (hasmissing(e)) {
        for (i = 1; i <= rows(info); i++) sh[i] = max(u[|info[i, 1] \ info[i, 2]|])
        e = exp(u - sh[pid])
    }
    e = w :* e
    S = panelsum(e, info)
    lnmean = sh + ln(S) - ln(Wp)
    Q = quadsum(Wp :* lnmean) + quadsum(w :* xb)
    if (todo == 0) return

    p = e :/ S[pid]
    g = quadcross(X, w - Wp[pid] :* p)
    if (todo == 1) return

    dX = X - panelsum(X, p, info)[pid, .]
    H  = cross(dX, Wp[pid] :* p, dX)
    H  = (H + H') / 2
}

// Sums of the rows of Z within groups defined by the integer vector id.
// Returns one row per distinct id, in ascending id order; n returns the
// number of groups.
real matrix _xtgamfe_csum(real matrix Z, real colvector id, real scalar n)
{
    real colvector o
    real matrix cinfo

    o = order(id, 1)
    cinfo = panelsetup(id[o], 1)
    n = rows(cinfo)
    return(panelsum(Z[o, .], cinfo))
}

// Totals of the columns of Z by distinct value of the panel length T.
// Returns (T value, column totals...), one row per distinct T.
real matrix _xtgamfe_bygroup(real colvector T, real matrix Z)
{
    real colvector o
    real matrix tinfo

    o = order(T, 1)
    tinfo = panelsetup(T[o], 1)
    return((T[o][tinfo[., 1]], panelsum(Z[o, .], tinfo)))
}

// Fixed-T moment equation for the shape.  TN holds (T, weighted count).
real scalar _xtgamfe_shape_moment(real matrix TN, real scalar kappa)
{
    return(sum(TN[., 2] :* TN[., 1] :* (TN[., 1] :- 1) :/ (kappa :* TN[., 1] :+ 1)))
}

// Solve sum_i om_i T_i(T_i-1)/(kappa*T_i+1) = target.
// status: 0 finite root; 1 root at infinity; 2 no positive root;
//         3 bracket failure; 4 invalid moment.
void _xtgamfe_shape_solve(
    real matrix TN,
    real scalar target,
    real scalar kappa,
    real scalar status)
{
    real scalar maxmom, lo, hi, mid, flo, fhi, fmid, j

    kappa = .
    status = 4

    if (rows(TN) > 0 & target < . & target >= 0) {
        maxmom = sum(TN[., 2] :* TN[., 1] :* (TN[., 1] :- 1))

        if (target == 0) {
            status = 1
        }
        else if (target >= maxmom) {
            status = 2
        }
        else {
            lo = 1
            hi = 1
            flo = _xtgamfe_shape_moment(TN, lo) - target

            if (flo == 0) {
                kappa = 1
                status = 0
            }
            else if (flo > 0) {
                hi = 10
                fhi = _xtgamfe_shape_moment(TN, hi) - target
                while (fhi > 0 & hi < 1e300) {
                    lo = hi
                    hi = hi * 10
                    fhi = _xtgamfe_shape_moment(TN, hi) - target
                }
                if (fhi <= 0) status = 0
                else          status = 3
            }
            else {
                hi = 1
                lo = .1
                flo = _xtgamfe_shape_moment(TN, lo) - target
                while (flo < 0 & lo > 1e-300) {
                    hi = lo
                    lo = lo / 10
                    flo = _xtgamfe_shape_moment(TN, lo) - target
                }
                if (flo >= 0) status = 0
                else          status = 3
            }

            if (status == 0 & missing(kappa)) {
                for (j = 1; j <= 200; j++) {
                    mid = exp((ln(lo) + ln(hi)) / 2)
                    fmid = _xtgamfe_shape_moment(TN, mid) - target
                    if (fmid > 0) lo = mid
                    else          hi = mid
                }
                kappa = exp((ln(lo) + ln(hi)) / 2)
            }
        }
    }
}

// The same solver addressed through Stata objects: panel lengths in the
// nonmissing rows of a variable, results in two scalars.  The acceptance
// tests call the solver this way.
void _xtgamfe_shape(
    string scalar T_name,
    real scalar   target,
    string scalar kappa_name,
    string scalar status_name)
{
    real colvector Tall, T
    real scalar kappa, status

    Tall = st_data(., T_name)
    T = select(Tall, Tall :< .)
    kappa = .
    status = 4
    if (rows(T) > 0) _xtgamfe_shape_solve(_xtgamfe_bygroup(T, J(rows(T), 1, 1)), target, kappa, status)
    st_numscalar(kappa_name, kappa)
    st_numscalar(status_name, status)
}

// Score in kappa of the marginal log likelihood of the within-panel shares,
//   l_i(kappa) = lngamma(T_i kappa) - T_i lngamma(kappa) + kappa A_i + c_i,
//   A_i = sum_t ln(share_it) of the fitted mean-scaled outcomes.
// TN holds (T, weighted count); sumA is the weighted total of A_i.
real scalar _xtgamfe_kml_score(real matrix TN, real scalar sumA, real scalar kappa)
{
    return(sum(TN[., 2] :* TN[., 1] :* (digamma(TN[., 1] :* kappa) :- digamma(kappa))) + sumA)
}

// Maximum of the marginal likelihood in kappa.  The log likelihood is
// strictly concave with score +infinity at zero, so the root is unique when
// it exists.  status: 0 finite root; 1 no finite root (score positive
// everywhere: the shares are numerically equal); 3 bracket failure.
void _xtgamfe_kml(
    real matrix TN,
    real scalar sumA,
    real scalar kappa,
    real scalar status)
{
    real scalar lo, hi, mid, flo, fhi, fmid, j

    kappa = .
    status = 3
    if (sumA >= .) return

    lo = 1
    hi = 1
    flo = _xtgamfe_kml_score(TN, sumA, 1)
    if (flo >= .) return
    if (flo > 0) {
        fhi = flo
        while (fhi > 0 & hi < 1e15) {
            lo = hi
            hi = hi * 10
            fhi = _xtgamfe_kml_score(TN, sumA, hi)
        }
        if (fhi > 0 | fhi >= .) {
            status = 1
            return
        }
    }
    else if (flo < 0) {
        while (flo < 0 & lo > 1e-300) {
            hi = lo
            lo = lo / 10
            flo = _xtgamfe_kml_score(TN, sumA, lo)
        }
        if (flo < 0 | flo >= .) return
    }
    for (j = 1; j <= 200; j++) {
        mid = exp((ln(lo) + ln(hi)) / 2)
        fmid = _xtgamfe_kml_score(TN, sumA, mid)
        if (fmid > 0) lo = mid
        else          hi = mid
    }
    kappa = exp((ln(lo) + ln(hi)) / 2)
    status = 0
}

// Estimation.  Newton's method with analytic derivatives, rank checks, and
// step halving, on the vectorized profiled criterion.
//
// The optimizer works on within-centered regressors scaled to unit
// within-panel root mean square, z_j = (x_j - xbar_ij)/s_j, with
// gamma_j = s_j*beta_j.  Centering changes nothing in the criterion;
// scaling is a reparameterization.  Coefficients and their covariance are
// mapped back to the original units on exit, so results are equivariant to
// the units and invariant to the origin of every regressor.
//
// Convergence is declared on the Newton decrement sqrt(g'H^{-1}g), which
// is invariant to linear reparameterization.  The gradient norm is not a
// stopping criterion: by itself it depends on the units of the regressors
// and can be small far from the optimum.
//
// Weights.  With weights w_it the criterion is the weighted quasi-log
// likelihood with the fixed effects profiled out (see _xtgamfe_eval).
// fweights must be constant within panel and stand for that many identical
// panels.  pweights and iweights may vary within panel; they enter the
// sandwich through the weighted panel scores.
void _xtgamfe_fit(
    string scalar ly_name,
    string scalar lny_name,
    string scalar rhs_names,
    string scalar touse_name,
    string scalar panid_name,
    string scalar w_name,
    string scalar wtype,
    string scalar clid_name,
    string scalar vcetype,
    real   scalar tol,
    real   scalar maxiter,
    real   scalar nolog,
    string scalar b0_name,
    string scalar b_out,
    string scalar V_out,
    string scalar omit_name,
    string scalar stats_name,
    string scalar alpha_name,
    string scalar panvar_name,
    real   scalar fe_post_max,
    string scalar fe_name,
    string scalar feid_name)
{
    real colvector y, lny, pid, w, beta, g, beta_new, g_new, delta, vd
    real colvector Wp, Tp, wfirst, p, p_new, lnmean, lnmean_new, yc
    real colvector cl, clp, om, lr, ratio, A, sk, ci, alpha
    real matrix X, Xbar, H, H_new, Hinv, Hinv_new, V, Vinv, info, ZZinv, Vfull
    real matrix Gs, Gt, Sc, B, TN, bg
    real rowvector xmaxabs, xdev, novar, collin, xscale, omit, keep, bfull, stats
    real scalar Q, Q_new, step, conv, conv_code, iter, iter_done, K, Kfull, gnorm
    real scalar max_halve, halve_count, accepted, candidate_ok, j, n, G, M
    real scalar qform, qform_new, decrement, decrement_new
    real scalar rank_h, rank_h_new, rank_v, hcondition, objective_slack
    real scalar wconst, isfw, ss, kappa, shape_code, kml, kml_code, kml_se, ll, hk
    real scalar Nw, Gw, sumA, fe_ok
    string rowvector rhs_list

    rhs_list = tokens(rhs_names)
    y   = st_data(., ly_name,    touse_name)
    lny = st_data(., lny_name,   touse_name)
    X   = st_data(., rhs_list,   touse_name)
    pid = st_data(., panid_name, touse_name)
    w   = st_data(., w_name,     touse_name)
    n   = rows(y)
    isfw = (wtype == "fweight")
    // pweights and iweights are scaled to mean one.  The estimates and
    // the sandwich do not depend on the scale of such weights, but the
    // Newton decrement does, and it is compared with a fixed tolerance.
    if (wtype == "pweight" | wtype == "iweight") w = w :* (n / quadsum(w))

    info = panelsetup(pid, 1)
    G = rows(info)
    if (pid[1] != 1 | pid[n] != G) {
        errprintf("xtgamfe internal error: panel identifiers are not 1..%g in order\n", G)
        exit(459)
    }
    Tp = info[., 2] - info[., 1] :+ 1
    Wp = panelsum(w, info)
    wfirst = w[info[., 1]]
    wconst = all(w :== wfirst[pid])
    if (isfw & !wconst) {
        errprintf("fweights must be constant within panel\n")
        exit(459)
    }

    // ---- clusters ----
    if (clid_name != "") {
        cl  = st_data(., clid_name, touse_name)
        clp = cl[info[., 1]]
        if (any(cl :!= clp[pid])) {
            errprintf("panels are not nested within clusters\n")
            exit(498)
        }
    }
    else clp = (1::G)

    K = cols(X)
    Kfull = K

    // ---- within-panel centering and the within-variation screen ----
    // A regressor is treated as having no within-panel variation when its
    // largest within-panel deviation is no more than 1e-12 of its largest
    // absolute value: at that level the deviations are not distinguishable
    // from rounding of the stored values.  The rule is relative, so it does
    // not depend on units.  omit codes: 1 exactly no within variation,
    // 3 variation at rounding level only, 2 collinear (set below).
    xmaxabs = colmax(abs(X))
    X = _xtgamfe_center(X, w, info, pid, Wp, Xbar)
    xdev = colmax(abs(X))
    novar = (xdev :<= 1e-12 :* xmaxabs)
    omit = novar :+ 2 :* (novar :& (xdev :> 0))

    // ---- collinearity after the within transformation ----
    // The profiled Hessian is singular at every beta exactly when the
    // within-centered columns are linearly dependent.  Columns are scaled
    // to unit root mean square and swept in order, so a dependent column is
    // attributed to the later term.
    keep = select(1..Kfull, omit :== 0)
    if (cols(keep) > 0) {
        xscale = sqrt(quadcolsum(X[., keep]:^2) / n)
        ZZinv = invsym(quadcross(X[., keep] :/ xscale, X[., keep] :/ xscale), 1..cols(keep))
        collin = (diagonal(ZZinv) :== 0)'
        for (j = 1; j <= cols(keep); j++) if (collin[j]) omit[keep[j]] = 2
    }
    keep = select(1..Kfull, omit :== 0)
    if (cols(keep) == 0) {
        errprintf("no regressor is identified: every term either has no within-panel variation\n")
        errprintf("or is collinear with the others after the within-panel transformation\n")
        exit(459)
    }

    // ---- estimation design: identified columns at unit within-panel RMS ----
    X = X[., keep]
    K = cols(X)
    xscale = sqrt(quadcolsum(X:^2) / n)
    X = X :/ xscale

    // ---- starting values: from(), or weighted within-panel log-OLS ----
    if (b0_name != "") {
        beta = st_matrix(b0_name)'
        if (rows(beta) != Kfull) {
            errprintf("starting-value dimension mismatch: expected %g, got %g\n", Kfull, rows(beta))
            exit(503)
        }
        if (hasmissing(beta)) {
            errprintf("from() contains missing or nonfinite values\n")
            exit(504)
        }
        beta = beta[keep'] :* xscale'
    }
    else {
        yc = y - (panelsum(y, w, info) :/ Wp)[pid]
        beta = invsym(quadcross(X, w, X)) * quadcross(X, w, yc)
    }

    Q = .
    g = J(K, 1, .)
    H = J(K, K, .)
    p = J(0, 1, .)
    lnmean = J(0, 1, .)
    _xtgamfe_eval(2, y, X, w, info, pid, Wp, Tp, beta, Q, g, H, p, lnmean)

    if (Q >= . | hasmissing(g) | hasmissing(H)) {
        errprintf("profiled objective or derivatives are nonfinite at the starting values\n")
        exit(459)
    }

    Hinv = invsym(H)
    rank_h = K - diag0cnt(Hinv)
    if (rank_h < K) {
        errprintf("profiled Hessian is numerically singular at the starting values (rank %g of %g)\n", rank_h, K)
        if (b0_name != "") {
            errprintf("the within-panel design has full rank, so this indicates starting values too far\n")
            errprintf("from the solution; omit from() or supply better starting values\n")
        }
        else {
            errprintf("the within-panel design has full rank, so the default starting values are too far\n")
            errprintf("from the solution; this happens when the outcome varies within panels by many\n")
            errprintf("orders of magnitude that the regressors do not explain; supply from()\n")
        }
        exit(430)
    }
    hcondition = cond(H)
    gnorm = sqrt(g' * g)
    qform = g' * Hinv * g
    decrement = sqrt(max((qform, 0)))

    conv = 0
    conv_code = 0
    iter = 0
    iter_done = 0

    if (decrement <= tol) {
        conv = 1
        conv_code = 2
    }

    for (iter = 1; iter <= maxiter & !conv; iter++) {
        delta = -Hinv * g
        step = 1
        max_halve = 30
        halve_count = 0
        accepted = 0

        do {
            beta_new = beta + step * delta
            _xtgamfe_eval(2, y, X, w, info, pid, Wp, Tp, beta_new, Q_new, g_new, H_new, p_new, lnmean_new)
            candidate_ok = (Q_new < . & !hasmissing(g_new) & !hasmissing(H_new))

            if (candidate_ok & (Q_new < Q)) {
                accepted = 1
                break
            }

            /*
              Close to the optimum, the true objective improvement can be
              smaller than double-precision resolution.  In that case a
              converged Newton candidate may appear microscopically worse.
              Accept a numerically tied candidate only when its Hessian is
              full rank and its Newton decrement already satisfies the
              tolerance.  This preserves the strict-decrease rule away from
              convergence.
            */
            if (candidate_ok) {
                objective_slack = 64 * epsilon(max((1, abs(Q), abs(Q_new))))
                if (Q_new <= Q + objective_slack) {
                    Hinv_new = invsym(H_new)
                    rank_h_new = K - diag0cnt(Hinv_new)
                    if (rank_h_new == K) {
                        qform_new = g_new' * Hinv_new * g_new
                        decrement_new = sqrt(max((qform_new, 0)))
                        if (decrement_new <= tol) {
                            accepted = 1
                            break
                        }
                    }
                }
            }

            if (halve_count >= max_halve) break
            step = step / 2
            halve_count++
        } while (1)

        if (!accepted) {
            /*
              No step along the Newton direction produced a representable
              decrease.  If the decrease predicted by the quadratic model,
              decrement^2/2, is itself below the resolution of the
              objective, the current point cannot be improved in double
              precision: report convergence at objective resolution (code
              5) together with the achieved decrement.  Otherwise this is a
              genuine line-search failure (code 3).
            */
            objective_slack = 64 * epsilon(max((1, abs(Q))))
            if (decrement <= tol) {
                conv = 1
                conv_code = 2
            }
            else if (decrement^2 / 2 <= objective_slack) {
                conv = 1
                conv_code = 5
            }
            else {
                conv_code = 3
            }
            break
        }

        beta = beta_new
        Q = Q_new
        g = g_new
        H = H_new
        p = p_new
        lnmean = lnmean_new
        iter_done = iter_done + 1

        Hinv = invsym(H)
        rank_h = K - diag0cnt(Hinv)
        if (rank_h < K) {
            errprintf("profiled Hessian lost numerical rank at completed iteration %g\n", iter_done)
            exit(459)
        }
        hcondition = cond(H)
        gnorm = sqrt(g' * g)
        qform = g' * Hinv * g
        decrement = sqrt(max((qform, 0)))

        if (!nolog) {
            printf("Iteration %g: Q = %12.6g, |grad| = %12.6g, decrement = %12.6g\n",
                   iter_done, Q, gnorm, decrement)
            displayflush()
        }

        if (decrement <= tol) {
            conv = 1
            conv_code = 2
        }
    }

    if (!conv & conv_code == 0) conv_code = 4

    // ---- counts ----
    if (isfw) {
        Nw = quadsum(w)
        Gw = quadsum(wfirst)
    }
    else {
        Nw = n
        Gw = G
    }

    // ---- shape, marginal likelihood ----
    ss = .
    kappa = .
    shape_code = 4
    kml = .
    kml_code = 3
    kml_se = .
    ll = .
    hk = .
    M = .
    if (conv & wconst) {
        // om: panel multiplicity.  fweights count panels; pweights and
        // iweights are normalized to mean one across panels; otherwise one.
        if (isfw)             om = wfirst
        else if (wtype != "") om = wfirst :* (G / quadsum(wfirst))
        else                  om = J(G, 1, 1)

        lr = y - X * beta - lnmean[pid]          // ln(y_it / mu_it)
        ratio = exp(lr)
        ss = quadsum(om[pid] :* (ratio :- 1):^2)

        TN = _xtgamfe_bygroup(Tp, om)
        _xtgamfe_shape_solve(TN, ss, kappa, shape_code)

        // A_i = sum_t ln(share_it), share_it = (y_it/mu_it)/T_i
        A = panelsum(lr, info) - Tp :* ln(Tp)
        sumA = quadsum(om :* A)
        _xtgamfe_kml(TN, sumA, kml, kml_code)
        if (kml_code == 0) {
            hk = sum(TN[., 2] :* (TN[., 1] :* trigamma(kml) - TN[., 1]:^2 :* trigamma(TN[., 1] :* kml)))
            // constant of the share density: -sum_t ln(y_it / sum_s y_is)
            ci = Tp :* ln(panelsum(exp(lny), info)) - panelsum(lny, info)
            ll = sum(TN[., 2] :* (lngamma(TN[., 1] :* kml) - TN[., 1] :* lngamma(kml))) +
                 kml * sumA + quadsum(om :* ci)
        }
    }
    else if (conv & !wconst) shape_code = 6

    // ---- covariance ----
    if (conv) {
        if (vcetype == "oim") {
            if (kml < . & kml > 0) V = Hinv / kml
            else                   V = J(K, K, .)
            if (hk < . & hk > 0) kml_se = 1 / sqrt(hk)
        }
        else {
            // Sandwich, clustered on panels or on clusters that nest them,
            // with the one-way M/(M-1) correction.  The cluster scores are
            // centered before forming the meat.  At an exact optimum their
            // mean is zero, so this changes only optimization roundoff; it
            // also preserves the theoretical rank bound rank(B) <= M-1.
            Gs = panelsum(X, w - Wp[pid] :* p, info)
            if (clid_name == "") {
                if (isfw) {
                    M  = Gw
                    Gt = (Gs :/ wfirst) :- (colsum(Gs) / M)
                    B  = cross(Gt, wfirst, Gt)
                }
                else {
                    M  = G
                    Gt = Gs :- (colsum(Gs) / M)
                    B  = cross(Gt, Gt)
                }
            }
            else {
                Sc = _xtgamfe_csum(Gs, clp, M)
                Sc = Sc :- (colsum(Sc) / M)
                B  = cross(Sc, Sc)
            }
            if (M < 2) {
                errprintf("at least two clusters are required for cluster-robust inference\n")
                exit(459)
            }
            V = Hinv * B * Hinv
            V = (V + V') / 2
            V = V * (M / (M - 1))

            // robust standard error of the marginal ML shape estimate
            if (kml_code == 0 & hk < . & hk > 0) {
                sk = om :* (Tp :* (digamma(Tp :* kml) :- digamma(kml)) + A)
                if (clid_name == "") {
                    if (isfw) kml_se = sqrt((M / (M - 1)) * quadsum(wfirst :* (sk :/ wfirst):^2)) / hk
                    else      kml_se = sqrt((M / (M - 1)) * quadsum(sk:^2)) / hk
                }
                else {
                    bg = _xtgamfe_csum(sk, clp, j)
                    kml_se = sqrt((M / (M - 1)) * quadsum(bg:^2)) / hk
                }
            }
        }

        // rank on the correlation scale, so that it cannot depend on the
        // magnitude of the variances
        if (hasmissing(V)) {
            rank_v = .
        }
        else {
            vd = sqrt(diagonal(V))
            if (min(vd) <= 0) Vinv = invsym(V)
            else {
                Vinv = V :/ (vd * vd')
                Vinv = invsym((Vinv + Vinv') / 2)
            }
            rank_v = K - diag0cnt(Vinv)
        }
        // back to the original units: beta_j = gamma_j/s_j
        V = V :/ (xscale' * xscale)
    }
    else {
        V = J(K, K, .)
        rank_v = .
    }
    if (vcetype == "oim") M = .

    beta = beta :/ xscale'

    // ---- fixed effects ----
    // lnmean is the profiled effect for the centered design; in the
    // original parameterization alpha_i = lnmean_i - xbar_i'b.
    fe_ok = 0
    if (conv) {
        alpha = lnmean - Xbar[., keep] * beta
        st_store(., alpha_name, touse_name, alpha[pid])
        if (G <= fe_post_max) {
            st_matrix(fe_name, alpha)
            st_matrix(feid_name, st_data(., panvar_name, touse_name)[info[., 1]])
            fe_ok = (rows(st_matrix(fe_name)) == G)
        }
    }

    // Full-length results: omitted terms carry a zero coefficient and zero
    // variance, and are named as omitted by the caller.
    bfull = J(1, Kfull, 0)
    bfull[keep] = beta'
    Vfull = J(Kfull, Kfull, 0)
    Vfull[keep, keep] = V

    stats = (conv, iter_done, gnorm, conv_code, decrement, rank_h, rank_v, hcondition,
             M, wconst, ss, kappa, shape_code, kml, kml_se, ll,
             Nw, Gw, min(Tp), Nw / Gw, max(Tp), fe_ok, kml_code)

    st_matrix(b_out, bfull)
    st_matrix(V_out, Vfull)
    st_matrix(omit_name, omit)
    st_matrix(stats_name, stats)
}
end
