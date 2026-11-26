*! xtgamfe_estat 1.1.1  2026-11-23
*! estat after xtgamfe
*
* Syntax:
*   estat ic [, n(#|exp)]
*   estat ape [varlist] [, level(#) ybar finite delta(#)]
*   estat fepoisson [, reps(#) seed(#) level(#) nodots]
*   estat park [, level(#)]
*   estat summarize, estat vce   (standard)
*
* estat ic reports AIC and BIC from the marginal log likelihood of the
* within-panel shares, e(ll), counting the coefficients and the shape.
*
* estat fepoisson fits fixed-effects Poisson (xtpoisson, fe) to the same
* observations, shows the two coefficient vectors side by side, and tests
* their difference with a bootstrap that resamples the clusters of the fit
* (the panels unless the fit clustered on a variable that nests them); the
* joint test refers the Wald statistic D of the bootstrap covariance to a
* Hotelling-type F approximation.
*
* estat park is Park's (1966) test of the variance function: the OLS
* regression of ln(squared raw residual) on ln(fitted mean) on the
* estimation sample, with standard errors clustered as in the fit (each
* copy of a frequency-weighted panel a cluster), and the test of slope 2,
* the value under independent gamma errors with one shape in balanced
* panels, unweighted or with weights constant within panel (with weights
* that vary within panel, or panels with different numbers of observations,
* the test is not reported).  Its p-value is nominal: the regression treats
* the fitted means and residuals as data.  (Manning and Mullahy 2001 give
* the GLM form, the modified Park test.)
*
* A coefficient that rests on one cluster (from 1.1.1): a term that varies
* within panels in only one cluster (e(xtg_onecl)), or a term involved in a
* direction of the coefficients that the other clusters do not identify
* (e(xtg_ocdterms), e(xtg_ocdir)); e(onecl) lists both.  estat ape shows
* without standard errors the effects of the variables in the first kind
* and the effects whose derivative has a part along such a direction, and
* estat fepoisson compares such terms without resampling their differences
* and leaves them out of the joint test (_xtgamfe_oneclnote).  Both
* commands make the check for the clusters they use, also after vce(oim),
* vce(bootstrap) and vce(jackknife) (and estat ape after a bootstrap or
* jackknife prefix), by refitting the model from the stored estimates
* (_xtgamfe_oclinfo).
*
* estat ape and estat fepoisson find the terms that xtgamfe omitted by
* their position in e(b), not by name, so that a term entered twice is
* handled (_xtgamfe_omitpos); estat ape takes the numerically lowest level
* as the base of a factor with no base level in the model, and reports
* without standard error an effect to whose influence function every
* cluster contributes the same; estat fepoisson shows the comparison
* without a bootstrap when every term compared rests on one cluster, and
* adds a note when fewer than 199 replications are used.
*
* estat ape reports average partial effects on the conditional mean
* exp(alpha_i + x'b + offset), averaged over the estimation sample with the
* estimated fixed effects: the average derivative for a continuous
* variable, and the average change from the base level for each level of a
* factor variable.  Standard errors come from the influence functions of
* the averages, clustered as in the fitted model's robust variance (on
* panels if the model was fitted with vce(oim), bootstrap, or jackknife).
* From 1.1.1 an effect is reported only if the change it describes is
* identified by the estimation sample (see _xtgamfe_ape).  With ybar (from
* 1.1.1) each effect is computed with the observed outcome in place of the
* fitted mean: b_j times the mean outcome for a regressor that enters
* linearly, which stays consistent when period indicators absorb a period
* pattern in the errors and the fitted means do not.
program define xtgamfe_estat, rclass
    version 15.0

    // One replication of estat fepoisson, called by the bootstrap prefix
    // through xtgamfe _fepb (the prefix cannot call a subprogram of this
    // file directly); the results in memory are then those of the previous
    // replication.  The replication leaves only e(sample) in e(), so that
    // the prefix collects the differences alone (_xtgamfe_fepb_e).
    gettoken sub rest : 0, parse(" ,")
    if "`sub'" == "_fepb" {
        _xtgamfe_fepb_e `rest'
        return add
        exit
    }

    if "`e(cmd)'" != "xtgamfe" {
        di as error "xtgamfe estimation results not found"
        exit 301
    }

    if "`sub'" == "ic" {
        xtgamfe_estat_ic `rest'
    }
    else if "`sub'" == "ape" {
        xtgamfe_estat_ape `rest'
    }
    else if "`sub'" == "fepoisson" {
        xtgamfe_estat_fep `rest'
    }
    else if "`sub'" == "park" {
        xtgamfe_estat_park `rest'
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
    // n() takes a number or an expression that evaluates to one, such as
    // e(N_g)
    syntax [, N(string)]

    if e(ll) >= . {
        di as error "the log likelihood is not available for this fit"
        di as error "(it is not computed when weights vary within panel or when no finite"
        di as error " maximum likelihood shape estimate exists, as in an exact or near-exact"
        di as error " fit; see e(kappa_ml_status))"
        exit 498
    }
    local N = e(N)
    if `"`n'"' != "" {
        capture local N = (`n')
        local bad = (_rc != 0)
        if !`bad' {
            capture confirm number `N'
            if _rc local bad = 1
        }
        if !`bad' {
            if `N' <= 0 | `N' >= . local bad = 1
        }
        if `bad' {
            di as error `"n(`n') invalid: n() must be a positive number or an expression that"'
            di as error "evaluates to one, such as e(N_g)"
            exit 198
        }
    }
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
    if inlist("`e(wtype)'", "pweight", "iweight") {
        di as text "Note: with `e(wtype)'s, ll(model) is a weighted pseudo-likelihood; reading AIC"
        di as text "      and BIC from it as from a likelihood needs a justification that"
        di as text "      xtgamfe does not supply."
    }

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
    // The variables are names, wildcards or ranges of the fitted model's
    // variables, optionally with a factor-variable or time-series prefix
    // (i.time is time); they are resolved against the model (below).
    syntax [anything(name=vlist)] [, Level(cilevel) YBar FINite DELta(numlist max=1)]
    local useY = ("`ybar'" != "")
    // finite: for a continuous variable, the average change in the mean when
    // the variable rises by delta (default 1) in place of the derivative
    local useF = ("`finite'" != "" | "`delta'" != "")
    if "`delta'" == "" local delta = 1
    if `useF' & (`delta' == 0 | `delta' >= .) {
        di as error "delta() must be a nonzero number"
        exit 198
    }

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
    // opos: the positions in e(b) of the terms that xtgamfe omitted (by
    // position, not by name, so that of a term entered twice the estimated
    // copy is not taken for the omitted one; _xtgamfe_omitpos)
    _xtgamfe_omitpos
    local opos "`r(pos)'"
    // Relations stored by xtgamfe 1.1.1 (see xtgamfe.ado, _xtgamfe_fit):
    // each row q gives a linear function x'q of the terms that is constant
    // within the panels of the estimation sample.  A change c in the terms
    // is identified only if c'q = 0 for every row.  relpos lists the terms,
    // other than the estimated ones, that enter a relation.
    tempname RQ RC
    local has_rel = 0
    capture matrix `RQ' = e(xtg_relq)
    if _rc == 0 {
        capture matrix `RC' = e(xtg_relc)
        if _rc == 0 {
            if colsof(`RQ') == `n_exp' & rowsof(`RQ') == rowsof(`RC') + 2 local has_rel = 1
        }
    }
    local relpos ""
    if `has_rel' {
        local nrel = rowsof(`RC')
        forvalues r = 1/`nrel' {
            forvalues j = 1/`n_exp' {
                if `RQ'[`r', `j'] != 0 local relpos : list relpos | j
            }
        }
    }
    local need_rel = 0
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
        local was_omitted : list j in opos
        if `was_omitted' local is_est = 0
        if `was_omitted' local need_rel = 1
        local ncomp : word count `comps'
        if `is_est' {
            local K = `K' + 1
            local estcols "`estcols' `j'"
            if `ncomp' > `maxc' local maxc = `ncomp'
        }
        local in_rel : list j in relpos
        if `in_rel' & !`is_est' & `ncomp' > `maxc' local maxc = `ncomp'
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
                // effects) can serve as the base.  Whether the effects of
                // the variables in an omitted term are identified is
                // decided effect by effect (_xtgamfe_ape).
                if `ncomp' == 1 & `c_factor' {
                    local lv = r(level)
                    local omain_`vc' : list omain_`vc' | lv
                    local omainvars : list omainvars | nm
                }
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
            if `is_est' | `in_rel' local U : list U | c
        }
        // An interaction that is omitted although none of its components is
        // a base level is an empty cell.  The fitted mean of an observation
        // moved into that cell is not estimable; the relations stored by
        // xtgamfe say which changes would move an observation there.
        if `t_omit' & !`was_omitted' & `ncomp' >= 2 & !`anybase' local need_rel = 1
        // an estimated term with a level of the time variable, alone or in
        // an interaction (for the notes on period indicators)
        // anytlev: such a term whose other components are factor levels too
        // (i.time, or i.g#i.time), which can absorb a period pattern in
        // the errors; a level of time interacted with a continuous variable
        // (c.x1#i.time) lets that variable's slope vary by period and is
        // not a period indicator
        if `is_est' & "`e(timevar)'" != "" {
            local thas = 0
            local tcont = 0
            foreach c of local comps {
                _ms_parse_parts `c'
                if "`r(type)'" == "factor" & "`r(name)'" == "`e(timevar)'" & "`r(ts_op)'" == "" & r(base) != 1 {
                    local anytime = 1
                    local thas = 1
                }
                if "`r(type)'" != "factor" local tcont = 1
            }
            if `thas' & !`tcont' local anytlev = 1
        }
    }
    if "`anytime'" == "" local anytime = 0
    if "`anytlev'" == "" local anytlev = 0

    // The requested variables, resolved against the variables of the model:
    // a name (or an unambiguous abbreviation of one), a wildcard, or a
    // range, with any operator prefix (i., c., ib2., L., ...) removed.  The
    // whole token is checked first (from 1.1.1): an interaction (with #) and
    // a prefix that is not a factor-variable or time-series operator are
    // refused, naming the variables that can be requested (junk.x1 and
    // c.x2#c.x1 reported the effect of x1).
    local canreq : list contvars | factvars
    local canreq : list canreq - tsvars
    local both : list contvars & factvars
    local canreq : list canreq - both
    local fvop "i|c|o|bn|ibn|[0-9]+|[0-9]+bn?|b[0-9]+|ib[0-9]+|ob[0-9]+|i[(][^()]*[)]|ib[(][^()]*[)]|b[(][^()]*[)]"
    local tsop "[LlFfDdSs][LlFfDdSs0-9]*([(][^()]*[)])?"
    local varlist ""
    foreach tok of local vlist {
        local t "`tok'"
        local badtok ""
        local badtok2 ""
        if strpos("`t'", "#") {
            local badtok "`tok' is an interaction; estat ape reports the effect of a variable,"
            local badtok2 "which includes its interactions"
        }
        else if strpos("`t'", ".") {
            local pre = substr("`t'", 1, strrpos("`t'", ".") - 1)
            if !regexm("`pre'", "^((`fvop'|`tsop')[.])*(`fvop'|`tsop')$") {
                local badtok "`tok': `pre'. is not a factor-variable or time-series operator"
            }
            // a lag or lead: the command does not differentiate through
            // them (L.x1 reported the effect of x1 when x1 entered without
            // the operator)
            else if regexm("`pre'", "(^|[.])(`tsop')([.]|$)") {
                local badtok "`tok': estat ape does not report effects through lags or leads;"
                local badtok2 "to report the effect of a lag, generate it as a variable (see help xtgamfe##ape)"
            }
        }
        if "`badtok'" != "" {
            di as error "`badtok'"
            if "`badtok2'" != "" di as error "`badtok2'"
            di as error "request variables of the fitted model: `canreq'"
            exit 198
        }
        if strpos("`t'", ".") local t = substr("`t'", strrpos("`t'", ".") + 1, .)
        local got ""
        if strpos("`t'", "*") | strpos("`t'", "?") | strpos("`t'", "~") {
            local pat : subinstr local t "~" "*", all
            foreach v of local allvars {
                if strmatch("`v'", "`pat'") local got "`got' `v'"
            }
            if "`got'" == "" {
                di as error "`tok': no variable of the fitted model matches"
                exit 111
            }
        }
        else if strpos("`t'", "-") {
            capture unab rng : `t'
            if !_rc {
                foreach v of local rng {
                    if `: list v in allvars' local got "`got' `v'"
                }
            }
            if "`got'" == "" {
                di as error "`tok': no variable of the fitted model in that range"
                exit 111
            }
        }
        else if `: list t in allvars' local got "`t'"
        else {
            capture unab ab : `t', max(1)
            if !_rc {
                if `: list ab in allvars' local got "`ab'"
            }
            if "`got'" == "" {
                di as error "`tok' is not in the fitted model"
                exit 111
            }
        }
        local varlist : list varlist | got
    }
    if `need_rel' & !`has_rel' {
        di as error "the model has an omitted term or an empty cell, and these results do not"
        di as error "carry what estat ape needs to tell which effects are identified;"
        di as error "re-estimate with xtgamfe 1.1.1 or later"
        exit 498
    }
    local obasenote ""
    foreach nm of local omainvars {
        local vc : list posof "`nm'" in allvars
        local n_om : word count `omain_`vc''
        if "`base_`vc''" == "" & `n_om' == 1 {
            local base_`vc' `omain_`vc''
            local obasenote "`obasenote' `nm' (`omain_`vc'')"
        }
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
    // TCx: the estimated terms followed by the other terms that enter a
    // relation; Qx: the relations over those terms (one row each), followed
    // by the within-panel root mean square of each term; Qt: the tolerance
    // and the scale m of each relation.
    tempname TCx Qx Qt
    matrix `TCx' = `TC'
    local xcols "`estcols'"
    if `has_rel' {
        foreach j of local relpos {
            if `: list j in estcols' continue
            local xcols "`xcols' `j'"
            local t : word `j' of `full'
            local comps : subinstr local t "#" " ", all
            matrix `TCx' = `TCx' \ J(1, `maxc', 0)
            local m = 0
            foreach c of local comps {
                local m = `m' + 1
                matrix `TCx'[rowsof(`TCx'), `m'] = `: list posof "`c'" in U'
            }
        }
        local nx : word count `xcols'
        matrix `Qx' = J(`nrel' + 1, `nx', 0)
        matrix `Qt' = J(`nrel', 2, 0)
        local i = 0
        foreach j of local xcols {
            local i = `i' + 1
            forvalues r = 1/`nrel' {
                matrix `Qx'[`r', `i'] = `RQ'[`r', `j']
            }
            matrix `Qx'[`nrel' + 1, `i'] = `RQ'[`nrel' + 2, `j']
        }
        forvalues r = 1/`nrel' {
            matrix `Qt'[`r', 1] = `RC'[`r', 4]
            matrix `Qt'[`r', 2] = `RC'[`r', 5]
        }
    }
    else {
        matrix `Qx' = J(1, 1, 0)
        matrix `Qt' = J(1, 2, 0)
    }

    // ---- targets ----
    // Not reported: a variable that enters with a time-series operator (the
    // command does not differentiate through lags and leads), and a
    // variable without within-panel variation (its effect on the mean is
    // absorbed by the fixed effects).  Every other effect is computed and
    // then reported only if the change it describes is identified by the
    // estimation sample (from 1.1.1; see _xtgamfe_ape).
    local skipped_ts ""
    local skipped_un ""
    local skipped_ti ""
    local skipped_cf ""
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
            // a variable that enters both as a factor and as a continuous
            // variable (as time in i.time i.g#c.time) is not reported; it is
            // an error only when it is requested by name (below)
            if `: list v in contvars' & `: list v in factvars' {
                local skipped_cf "`skipped_cf' `v'"
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
        if `in_c' & `in_f' {
            di as error "`v' enters the model both as a continuous and as a factor variable;"
            di as error "estat ape does not support that"
            exit 498
        }
        // A variable that is also the offset moves the offset with it: its
        // effect includes the offset's (whose coefficient is one).
        local isoff = ("`v'" == "`e(offset)'")
        if `isoff' local offtgt "`offtgt' `v'"
        if `in_c' {
            local q = `q' + 1
            if `useF' matrix `TG' = nullmat(`TG') \ (`vc', 3, `delta', 0, `isoff')
            else      matrix `TG' = nullmat(`TG') \ (`vc', 1, 0, 0, `isoff')
            local rnames "`rnames' `v'"
        }
        else {
            if "`base_`vc''" == "" {
                // No base level in the model.  From 1.1.1, when the
                // estimation sample contains values of the factor that no
                // term names (as with 2.time or i(2 4)bn.time), those
                // values all have every indicator of the factor equal to
                // zero, and that observed coding is the reference: the
                // lowest such value is shown as the base.  Otherwise the
                // lowest named level is used.  (A named level taken as the
                // base here would make the only named level of 2.time its
                // own base, and estat ape time would stop with r(498).)
                tempvar named
                quietly generate byte `named' = missing(`v')
                foreach lv of local lev_`vc' {
                    quietly replace `named' = 1 if `v' == `lv'
                }
                quietly summarize `v' if `touse' & !`named', meanonly
                if r(N) > 0 {
                    local base_`vc' = r(min)
                    local zbasenote "`zbasenote' `v' (`r(min)')"
                }
                else {
                    // the numerically lowest named level (by value: sorted
                    // as text, 10 would come before 2), shown in the note
                    local bmin = .
                    foreach lv of local lev_`vc' {
                        if `lv' < `bmin' local bmin = `lv'
                    }
                    local base_`vc' = `bmin'
                    local basenote "`basenote' `v' (`bmin')"
                }
                drop `named'
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
                local q = `q' + 1
                local any = 1
                local anyfactor = 1
                matrix `TG' = nullmat(`TG') \ (`vc', 2, `lv', `base_`vc'', `isoff')
                local rnames "`rnames' `lv'.`v'"
            }
            if !`any' {
                di as error "no estimated level of factor variable `v'"
                exit 498
            }
        }
    }
    if `q' == 0 {
        di as error "no average partial effect to compute"
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
        local tdelta_now = r(tdelta)
        if e(tdelta) < . & `tdelta_now' != e(tdelta) {
            di as error "the model contains time-series operators, and the data are xtset with"
            di as error "delta(`tdelta_now'), not delta(`=e(tdelta)') as at estimation"
            di as error "type:  xtset `panvar' `timevar', delta(`=e(tdelta)')"
            exit 459
        }
    }
    else sort `panvar' `timevar'

    // The data must be those of the estimation (as for predict, mu).
    if `has_ts' & inlist("`e(version)'", "1.1.0", "1.1.1") {
        fvrevar `full'
        local rvfull "`r(varlist)'"
        sort `caller_order'
        _xtgamfe_dschk_e `rvfull'
    }
    else {
        sort `caller_order'
        _xtgamfe_dschk_e
    }
    _xtgamfe_rowcheck
    // The weights are evaluated here, in the caller's order, and a weight
    // expression (or the weights of a fit under a resampling prefix) must
    // give the values of the fit, row by row (from 1.1.1).
    tempvar wv
    if "`e(wtype)'" != "" quietly generate double `wv' `e(wexp)' if `touse'
    else                    quietly generate double `wv' = 1 if `touse'
    _xtgamfe_wsigchk `wv'
    // the clusters of the fit must nest the panels (they do for xtgamfe's
    // own vce(cluster); a bootstrap or jackknife prefix can set others)
    _xtgamfe_clchk `touse'
    // The coefficients that rest on one of the clusters used here (also
    // after vce(oim) and under a bootstrap or jackknife, by a refit from the
    // stored estimates; _xtgamfe_oclinfo)
    tempname OCD
    _xtgamfe_oclinfo, touse(`touse') wv(`wv') cmd(ape)
    local oc_src "`r(src)'"
    local oc_onecl `"`r(onecl)'"'
    local oc_ocdt `"`r(ocdterms)'"'
    local oc_has_od = 0
    capture confirm matrix r(ocdir)
    if _rc == 0 {
        matrix `OCD' = r(ocdir)
        local oc_has_od = 1
    }

    tempvar clid
    local clname ""
    if "`e(clustvar)'" != "" & "`e(clustvar)'" != "`panvar'" {
        quietly egen long `clid' = group(`e(clustvar)') if `touse'
        local clname "`clid'"
    }
    // The data in a fixed order, so that no sum depends on how Stata breaks
    // ties when it sorts: rows that tie on the panel and time variables
    // (missing time values, or no time variable) are put in the order of
    // their values, and then of the caller's order (rows whose values are
    // all equal add equal terms).
    local tie = ("`timevar'" == "")
    if !`tie' {
        quietly count if `touse' & missing(`timevar')
        local tie = (r(N) > 0)
    }
    local skeys ""
    if `tie' {
        local skeys "`depvar' `wv' `e(offset)' `allvars'"
        local skeys : list uniq skeys
        local skeys : list skeys - panvar
        local skeys : list skeys - timevar
    }
    sort `panvar' `timevar' `skeys' `caller_order'

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
        else if "`r(ts_op)'" != "" {
            fvrevar `r(ts_op)'.`r(name)'
            local uvars "`uvars' `r(varlist)'"
        }
        else local uvars "`uvars' `r(name)'"
    }

    tempvar lny lyo yo ofv pfirst panid
    quietly generate double `lny' = ln(`depvar') if `touse'
    if "`e(offset)'" != "" quietly generate double `lyo' = `lny' - `e(offset)' if `touse'
    else                     quietly generate double `lyo' = `lny' if `touse'
    quietly generate double `yo' = `depvar' if `touse'
    if "`e(offset)'" != "" quietly generate double `ofv' = `e(offset)' if `touse'
    else                     quietly generate double `ofv' = 0 if `touse'
    quietly by `panvar': generate byte `pfirst' = `touse' & (sum(`touse') == 1)
    quietly generate long `panid' = sum(`pfirst')
    quietly replace `panid' = . if !`touse'

    // The coefficient directions that rest on one cluster and involve
    // several terms (e(xtg_ocdir), in the columns of e(b); from 1.1.1),
    // over the estimated terms: an effect whose derivative with respect to
    // the coefficients, through the change it describes, has a part along
    // one of them is treated as the effect of a variable in a term that
    // varies within panels in only one cluster (aOC = 1; below).
    tempname ab aV aM aE aok ayb ODm aOC aZV
    local has_od = 0
    if `oc_has_od' {
        mata: st_matrix("`ODm'", st_matrix("`OCD'")[., strtoreal(tokens("`estcols'"))])
        local has_od = 1
    }
    else matrix `ODm' = J(1, 1, 0)
    mata: _xtgamfe_ape("`lyo'", "`lny'", "`uvars'", "`touse'", "`panid'", ///
        "`wv'", "`e(wtype)'", "`clname'", "`TC'", "`UM'", "`TG'", "`bK'", ///
        "`ab'", "`aV'", "`aM'", "`TCx'", "`Qx'", "`Qt'", `has_rel', "`aE'", ///
        "`yo'", "`ofv'", `useY', "`aok'", "`ayb'", "`ODm'", `has_od', "`aOC'", "`aZV'")
    // Results outside the numeric range (overflow, or underflow of an effect
    // or of its variance) are refused rather than reported with a missing
    // or zero standard error.
    if !scalar(`aok') {
        di as error "the fitted means, the average partial effects, or their variances are outside"
        di as error "Stata's numeric range for these data; the coefficients do not depend on the"
        di as error "units of the outcome, so rescale it (multiply or divide it by a power of 10)"
        di as error "and refit"
        exit 459
    }

    // Keep the identified effects.  A variable requested by name whose
    // effect is not identified is an error; otherwise a note lists it.
    local keep ""
    local rkeep ""
    forvalues t = 1/`q' {
        local nm : word `t' of `rnames'
        if `aE'[1, `t'] {
            local keep "`keep' `t'"
            local rkeep "`rkeep' `nm'"
        }
        else local skipped_un "`skipped_un' `nm'"
    }
    if "`varlist'" != "" & "`skipped_un'" != "" {
        foreach v of local targets {
            local vc : list posof "`v'" in allvars
            local anyok = 0
            forvalues t = 1/`q' {
                if `TG'[`t', 1] == `vc' & `aE'[1, `t'] local anyok = 1
            }
            if !`anyok' {
                di as error "the effect of `v' on the mean is not identified by the estimation"
                di as error "sample: the change it describes cannot be separated from a term that"
                di as error "xtgamfe omitted, or it moves observations into an empty cell"
                exit 498
            }
        }
    }
    if "`keep'" == "" {
        di as error "no average partial effect is identified by the estimation sample"
        di as error "(not identified:`skipped_un')"
        exit 498
    }
    if "`skipped_un'" != "" {
        mata: st_matrix("`aOC'", st_matrix("`aOC'")[strtoreal(tokens("`keep'"))])
        mata: st_matrix("`aZV'", st_matrix("`aZV'")[strtoreal(tokens("`keep'"))])
        mata: st_matrix("`ab'", st_matrix("`ab'")[strtoreal(tokens("`keep'"))])
        mata: st_matrix("`aV'", st_matrix("`aV'")[strtoreal(tokens("`keep'")), strtoreal(tokens("`keep'"))])
        local rnames : list clean rkeep
        local q : word count `rnames'
        local anyfactor = strpos("`rnames'", ".") > 0
    }

    matrix colnames `ab' = `rnames'
    matrix colnames `aV' = `rnames'
    matrix rownames `aV' = `rnames'

    // Terms that vary within panels in only one cluster (e(xtg_onecl), from
    // 1.1.1): the clusters cannot estimate the sampling variation of their
    // coefficients.  The effect of a variable that enters such a term
    // depends on that coefficient directly, and its std. err., test and
    // interval are not shown (r(V) keeps the computed values, as e(V)
    // does).  Any other effect depends on it only through the fitted means
    // of the panels in which the term varies (with ybar not at all), and
    // its std. err. leaves out that part of its sampling variation: the
    // term's score is zero in every other cluster and sums to zero, so its
    // score in its one cluster is zero too (see help xtgamfe##tn_onecl).
    // Coefficients that rest on one cluster through a direction that
    // involves several terms (e(xtg_ocdterms), as x1 and mix = x1 + r when
    // r varies in one cluster; from 1.1.1): the effects whose derivative
    // has a part along such a direction (aOC, from _xtgamfe_ape) are
    // treated in the same way; the others depend on it only through the
    // fitted means of the panels of that cluster (with ybar not at all).
    local ocl `"`oc_onecl'"'
    local ocdt `"`oc_ocdt'"'
    local oclvars ""
    foreach t of local ocl {
        local comps : subinstr local t "#" " ", all
        foreach c of local comps {
            _ms_parse_parts `c'
            local nm "`r(name)'"
            local oclvars : list oclvars | nm
        }
    }
    local withheld ""
    local wpos ""
    if "`oclvars'" != "" | `has_od' {
        forvalues t = 1/`q' {
            local nm : word `t' of `rnames'
            local vn "`nm'"
            if strpos("`vn'", ".") local vn = substr("`vn'", strrpos("`vn'", ".") + 1, .)
            local wh = `: list vn in oclvars'
            if `has_od' {
                if `aOC'[1, `t'] == 1 local wh = 1
            }
            if `wh' {
                local withheld "`withheld' `nm'"
                local wpos "`wpos' `t'"
            }
        }
    }
    local withheld : list clean withheld
    // Effects to whose influence function every cluster contributes the
    // same, to rounding (aZV, from _xtgamfe_ape): their
    // variance is zero, and what was computed is rounding error, so the
    // effect is shown without std. err., test and interval, with a note
    // (r(V) holds the computed values).
    local zerov ""
    local zpos ""
    forvalues t = 1/`q' {
        if `aZV'[1, `t'] == 1 & !`: list t in wpos' {
            local zerov "`zerov' `: word `t' of `rnames''"
            local zpos "`zpos' `t'"
        }
    }
    local zerov : list clean zerov
    local M = `aM'
    local clv "`panvar'"
    if "`clname'" != "" local clv "`e(clustvar)'"
    local Md : display %12.0fc `M'
    local Md = strtrim("`Md'")

    // ---- display ----
    // With e(df_r) posted (option small, or a jackknife), t statistics
    // with e(df_r) degrees of freedom; otherwise z.
    local dfr = e(df_r)
    if `dfr' < . & `dfr' > 0 {
        local z = invttail(`dfr', (100 - `level') / 200)
        local zlab "     t    P>|t|"
    }
    else {
        local dfr = .
        local z = invnormal(1 - (100 - `level') / 200)
        local zlab "     z    P>|z|"
    }
    local elab "     dy/dx"
    if `useF' local elab "    Change"
    di ""
    di as text "Average partial effects on the conditional mean" ///
        _col(55) "Number of obs = " as result %9.0fc e(N)
    if `useY' {
        di as text "Model: exp(alpha_i + x'b" cond("`e(offset)'" != "", " + offset", "") ///
            "), observed outcomes in place of fitted means"
    }
    else {
        di as text "Model: exp(alpha_i + x'b" cond("`e(offset)'" != "", " + offset", "") ///
            "), fixed effects as estimated"
    }
    di as text "{ralign 78:(Std. err. adjusted for `Md' clusters in `clv')}"
    di as text "{hline 13}{c TT}{hline 64}"
    di as text "             {c |} `elab'   Std. err. `zlab'     [`level'% conf. interval]"
    di as text "{hline 13}{c +}{hline 64}"
    forvalues t = 1/`q' {
        local nm : word `t' of `rnames'
        local est = `ab'[1, `t']
        local se  = sqrt(`aV'[`t', `t'])
        if `: list t in wpos' local se = .
        if `: list t in zpos' local se = .
        local zz  = `est' / `se'
        if `dfr' < . local pv = 2 * ttail(`dfr', abs(`zz'))
        else         local pv = 2 * normal(-abs(`zz'))
        di as text %12s abbrev("`nm'", 12) " {c |}  " as result %9.0g `est' "  " %9.0g `se' " " ///
            %8.2f `zz' " " %7.3f `pv' "    " %9.0g (`est' - `z' * `se') "   " %9.0g (`est' + `z' * `se')
    }
    di as text "{hline 13}{c BT}{hline 64}"
    // (a continuous variable's row is named by the variable; a factor
    // level's row by level.variable)
    local anycont = 0
    foreach nm of local rnames {
        if !strpos("`nm'", ".") local anycont = 1
    }
    if `useF' & `anycont' {
        local dld : display %10.0g `delta'
        local dld = strtrim("`dld'")
        di as text "Note: for a continuous variable, the average change in the mean when it"
        di as text "      rises by `dld'."
    }
    if `anyfactor' {
        di as text "Note: `=strtrim("`elab'")' for a factor level is the average change from the base level."
    }
    if "`basenote'" != "" {
        _xtgamfe_note_e "no base level in the model for:`basenote'; the lowest level, shown, is used as the base."
    }
    if "`zbasenote'" != "" {
        di as text "Note: no base level in the model for:`zbasenote'; the base is the coding"
        di as text "      shared by the values that no term names (lowest shown)."
    }
    if `useY' {
        local ybd : display %10.0g scalar(`ayb')
        local ybd = strtrim("`ybd'")
        if `useF' {
            di as text "Note: each effect averages the observed outcome times the relative change"
            di as text "      in exp(x'b): for a regressor that enters linearly, exp(b delta) - 1"
            di as text "      times the mean outcome, `ybd'."
        }
        else {
            di as text "Note: each effect averages the observed outcome times the change in"
            di as text "      exp(x'b): for a regressor that enters linearly, b times the mean"
            di as text "      outcome, `ybd'."
        }
        // The contrasts of period indicators are not consistent when the
        // indicators absorb a period pattern in the errors, the case for
        // which ybar is meant: a note when the model has an estimated term
        // with a level of the time variable (alone or in an interaction,
        // the rule of the note without ybar) and the table reports
        // contrasts of it.
        local tv "`e(timevar)'"
        local anyper = 0
        if "`tv'" != "" & `anytime' {
            foreach nm of local rnames {
                if regexm("`nm'", "^[0-9]+[.]`tv'$") local anyper = 1
            }
        }
        if `anyper' {
            di as text "Note: the contrasts of `tv' are effects of the period indicators themselves;"
            di as text "      when the indicators absorb a period pattern in the errors, these"
            di as text "      contrasts are not consistent, with or without ybar (see {help xtgamfe##caveats:help xtgamfe})."
        }
    }
    else if `anytime' & `anytlev' {
        // Without ybar, after a model with an estimated term with a level of
        // the time variable, alone or in an interaction with other factor
        // levels: the fitted means, and so these effects, are not consistent
        // when the indicators absorb a period pattern in the errors; ybar
        // gives an effect that is consistent when the coefficients that
        // enter the change are (the wording of Roebuck 2026, sec. 2.7).
        local tv "`e(timevar)'"
        di as text "Note: the model includes indicators of `tv'; if they absorb a period pattern"
        di as text "      in the errors, these effects are not consistent.  Option ybar averages"
        di as text "      the outcome times the implied change, which is consistent when the"
        di as text "      coefficients that enter the change are consistent (see {help xtgamfe##caveats:help xtgamfe})."
    }
    else if `anytime' {
        // levels of time only in interactions with continuous variables
        // (c.x1#i.time), which are not period indicators (although, with x
        // of nonzero mean, x*1(t = k) contains a scaled period indicator):
        // an effect with ybar is consistent when the coefficients that
        // enter the change are consistent, and an effect from the fitted
        // means, as these are, only when every coefficient is (Roebuck
        // 2026, sec. 2.7), so the note states both conditions rather than
        // point to ybar (from 1.1.1)
        local tv "`e(timevar)'"
        di as text "Note: the model includes indicators of `tv' only in interactions with"
        di as text "      continuous variables, which are not period indicators.  With ybar,"
        di as text "      an effect is consistent when the coefficients that enter the change"
        di as text "      are consistent; without ybar, when every coefficient is consistent"
        di as text "      (see {help xtgamfe##caveats:help xtgamfe})."
    }
    if "`offtgt'" != "" {
        di as text "Note: `=strtrim("`offtgt'")' is also the offset; its effect includes the offset's."
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
    if "`skipped_cf'" != "" {
        di as text "Note: not reported (enters both as a factor and as a continuous variable):`skipped_cf'"
    }
    if "`skipped_un'" != "" {
        di as text "Note: not reported (not identified by the estimation sample):`skipped_un'"
    }
    // effects whose cluster contributions do not vary (above)
    if "`zerov'" != "" {
        local nz : word count `zerov'
        local cw "clusters"
        if "`clv'" == "`panvar'" local cw "panels"
        if `nz' == 1 _xtgamfe_note_e "the `Md' `cw' contribute equally, to rounding, to the influence function of the effect of `zerov': the empirical variance of their contributions is zero, so its std. err., test and interval are not shown (r(V) holds the computed values)."
        else {
            _xtgamfe_andlist_e `zerov'
            _xtgamfe_note_e "the `Md' `cw' contribute equally, to rounding, to the influence functions of the effects of `r(list)': the empirical variances of their contributions are zero, so their std. errs., tests and intervals are not shown (r(V) holds the computed values)."
        }
    }
    // After an exact fit the scores are zero to rounding, so the influence
    // functions reduce to the deviations of the panels' averages from the
    // effect: the std. errs. reflect only the sampling of the panels over
    // which the effects are averaged (from 1.1.1)
    if e(xtg_boundary) == 1 {
        _xtgamfe_note_e "the fit is exact (the std. errs. of its coefficients are rounding error), so these std. errs. reflect only the sampling of the panels over which the effects are averaged."
    }
    // the one-cluster terms (above), or the rank warning of the fit,
    // repeated (from 1.1.1)
    if "`ocl'" != "" & "`ocdt'" == "" {
        local n1 : word count `ocl'
        local nw : word count `withheld'
        local it = cond(`n1' == 1, "it", "them")
        local tail ""
        if `nw' > 0 {
            local tail ": the effects of the variables in `it' (`withheld') are shown without std. errs., tests and intervals (r(V) holds the computed values)"
        }
        if `nw' < `q' {
            local lead ":"
            local oth ""
            if `nw' > 0 {
                local lead ", and"
                local oth "other "
            }
            local coef "that coefficient"
            local tv "the term varies"
            if `n1' > 1 {
                local coef "those coefficients"
                local tv "the terms vary"
            }
            if `useY' local tail "`tail'`lead' the `oth'effects, computed with ybar, do not depend on `coef'"
            else      local tail "`tail'`lead' the std. errs. of the `oth'effects leave out that variation, which enters them only through the fitted means of the panels in which `tv'"
        }
        _xtgamfe_oneclnote `"`tail'."' `"`ocl'"' `"`ocdt'"' `oc_src'
    }
    else if "`ocdt'" != "" {
        // with a direction that involves several terms
        local nw : word count `withheld'
        local tail ""
        if `nw' > 0 {
            local tail ": the effects that depend on those coefficients (`withheld') are shown without std. errs., tests and intervals (r(V) holds the computed values)"
        }
        if `nw' < `q' {
            local lead ":"
            local oth ""
            if `nw' > 0 {
                local lead ", and"
                local oth "other "
            }
            if `useY' local tail "`tail'`lead' the `oth'effects, computed with ybar, do not depend on the part of the coefficients that rests on one cluster"
            else      local tail "`tail'`lead' the std. errs. of the `oth'effects leave out that variation, which enters them only through the fitted means in the clusters on which those coefficients rest"
        }
        _xtgamfe_oneclnote `"`tail'."' `"`ocl'"' `"`ocdt'"' `oc_src'
    }
    else _xtgamfe_ranknote `"`ocl'"' `"`ocdt'"'

    return scalar N = e(N)
    return scalar N_clust = `M'
    return scalar level = `level'
    if `dfr' < . return scalar df_r = `dfr'
    if `useY' return scalar ybar = scalar(`ayb')
    if `useF' return scalar delta = `delta'
    return local method = cond(`useY', "ybar", "fitted")
    return local change = cond(`useF', "finite", "derivative")
    return local clustvar "`clv'"
    local skipped "`skipped_ts' `skipped_ti' `skipped_cf' `skipped_un' `skipped_ne'"
    local skipped : list clean skipped
    return local skipped "`skipped'"
    if "`withheld'" != "" return local onecl "`withheld'"
    if "`zerov'" != "" return local zerovar "`zerov'"
    return matrix b = `ab'
    return matrix V = `aV'
end

// ---------------------------------------------------------------
// Copy of _xtgamfe_dschk_p in xtgamfe_p.ado (keep identical): Stata's
// data-signature check of the estimation sample, without the weights when
// the fit received them as a temporary variable (e(xtg_wds) = 0; the row
// hash e(xtg_wsig) covers them then).
// ---------------------------------------------------------------
program define _xtgamfe_dschk_e
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
// The weights realized from e(wexp) (variable wv, double, on the estimation
// sample) must be those of the fit, row by row with the other estimation
// inputs of each row: the row signature of e(xtg_rkeys) with the weights as
// one more column is compared with e(xtg_wsig), which xtgamfe stores for a
// weight expression and for the weights of a fit under a resampling prefix
// (from 1.1.1).
// ---------------------------------------------------------------
program define _xtgamfe_wsigchk
    version 15.0
    args wv
    if `"`e(xtg_wsig)'"' == "" exit
    _xtgamfe_rsig_e `"`e(xtg_rkeys)' `wv'"' `e(panvar)' `"`e(timevar)'"'
    if `"`r(sig)'"' != `"`e(xtg_wsig)'"' {
        di as error "the weights `e(wexp)' give values other than those of the fit, or in other rows"
        di as error "(the data were changed or reordered, or the expression depends on the order"
        di as error "of the observations); generate the weight variable and refit with it"
        exit 459
    }
end

// ---------------------------------------------------------------
// The clusters of the results, e(clustvar), must be in the data and nest
// the panels on the estimation sample (marked by touse) before estat ape,
// estat park or estat fepoisson uses them (from 1.1.1).  xtgamfe's own
// vce(cluster clustvar) requires this, but a bootstrap or jackknife prefix
// with cluster() can set clusters that cross the panels (jackknife,
// cluster(time):), whose sums would mix the contributions of a panel.
// ---------------------------------------------------------------
program define _xtgamfe_clchk
    version 15.0
    args touse
    local cv "`e(clustvar)'"
    if "`cv'" == "" | "`cv'" == "`e(panvar)'" exit
    capture confirm variable `cv', exact
    if _rc {
        di as error "the cluster variable of these results, `cv', is not in the data"
        exit 111
    }
    tempvar g lo hi ord
    quietly generate long `ord' = _n
    quietly egen long `g' = group(`cv') if `touse'
    quietly count if `touse' & missing(`g')
    local nmis = r(N)
    quietly egen long `lo' = min(`g') if `touse', by(`e(panvar)')
    quietly egen long `hi' = max(`g') if `touse', by(`e(panvar)')
    quietly count if `touse' & `lo' != `hi'
    local ncross = r(N)
    sort `ord'
    if `nmis' > 0 | `ncross' > 0 {
        local who "of these results"
        if "`e(prefix)'" != "" local who "of the `e(prefix)' prefix"
        if `nmis' > 0 {
            di as error "the cluster variable `who', `cv', has missing values on the"
            di as error "estimation sample"
        }
        else {
            di as error "the clusters `who', `cv', do not nest the panels (`e(panvar)')"
            di as error "on the estimation sample: standard errors clustered on them would treat the"
            di as error "observations of one panel in different clusters as independent"
        }
        di as error "refit with clusters in which the panels are nested (vce(cluster clustvar),"
        di as error "or the cluster() option of the prefix)"
        exit 498
    }
end

// ---------------------------------------------------------------
// Copy of _xtgamfe_rsig in xtgamfe.ado (keep identical): the row signature
// of the estimation inputs.
// ---------------------------------------------------------------
program define _xtgamfe_rsig_e, rclass
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
    mata: st_local("h", _xtgamfe_rh_e("`nl'", "`sl'", "`es'"))
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    return local sig "`h'"
end

// ---------------------------------------------------------------
// A note wrapped at about 78 characters: "Note:" and the words of text, with
// continuation lines indented by six spaces.
// ---------------------------------------------------------------
program define _xtgamfe_note_e
    version 15.0
    args text
    local line "Note:"
    foreach w of local text {
        if strlen("`line' `w'") > 78 {
            di as text "`line'"
            local line "     "
        }
        local line "`line' `w'"
    }
    di as text "`line'"
end

// ---------------------------------------------------------------
// The note of estat ape and estat fepoisson on the terms that vary within
// panels in only one cluster (e(xtg_onecl)), printed whatever the rank of
// e(V) and with or without a resampling prefix (from 1.1.1); when the fit
// warned that e(V) has deficient rank, the note starts with that warning.
// tail says what the command does about such terms.  onecl and ocdt are
// the terms of the two kinds for the clusters that the command uses, and
// src says where they come from (_xtgamfe_oclinfo): "fit"
// (they are those of e(xtg_onecl) and e(xtg_ocdterms), and e(onecl) names
// them) or "refit" (e(onecl) does not).
// ---------------------------------------------------------------
program define _xtgamfe_oneclnote
    version 15.0
    args tail onecl ocdt src
    if "`onecl'`ocdt'" == "" exit
    local n1 : word count `onecl'
    if "`ocdt'" == "" {
        if `n1' == 1 local txt "`onecl' varies within panels in only one cluster, so the clusters cannot estimate the sampling variation of its coefficient"
        else         local txt "`onecl' vary within panels in only one cluster each, so the clusters cannot estimate the sampling variation of their coefficients"
    }
    else {
        // a direction of the coefficients that involves several terms rests
        // on one cluster (from 1.1.1)
        local dl ""
        local nd : word count `ocdt'
        forvalues i = 1/`nd' {
            local w : word `i' of `ocdt'
            if `i' == 1        local dl "`w'"
            else if `i' == `nd' local dl "`dl' and `w'"
            else               local dl "`dl', `w'"
        }
        local lead ""
        if `n1' == 1 local lead "`onecl' varies within panels in only one cluster, and "
        if `n1' > 1  local lead "`onecl' vary within panels in only one cluster each, and "
        local txt "`lead'`dl' are collinear within panels once one cluster is left out, so the clusters cannot estimate the sampling variation of the coefficients that rest on one cluster"
        if "`src'" == "fit" local txt "`txt' (e(onecl))"
    }
    if e(rank_v) < e(rank_h) & "`e(prefix)'" == "" {
        local txt "e(V) of the fit has rank `=e(rank_v)', below its `=e(rank_h)' coefficients: `txt'"
    }
    _xtgamfe_note_e `"`txt'`tail'"'
end

// ---------------------------------------------------------------
// A list of words as "a", "a and b", or "a, b and c", in r(list).
// ---------------------------------------------------------------
program define _xtgamfe_andlist_e, rclass
    version 15.0
    local n : word count `0'
    local dl ""
    forvalues i = 1/`n' {
        local w : word `i' of `0'
        if `i' == 1       local dl "`w'"
        else if `i' == `n' local dl "`dl' and `w'"
        else              local dl "`dl', `w'"
    }
    return local list "`dl'"
end

// ---------------------------------------------------------------
// The fit's warning when e(V) has deficient rank, repeated by estat ape and
// estat fepoisson (from 1.1.1): that there are too few clusters, or that
// the cluster scores do not span the coefficients.  A fit with a term that
// varies within panels in only one cluster gets _xtgamfe_oneclnote instead
// (onecl and ocdt as there).
// ---------------------------------------------------------------
program define _xtgamfe_ranknote
    version 15.0
    args onecl ocdt
    if `"`onecl'`ocdt'"' != "" exit
    if !(e(rank_v) < e(rank_h)) exit
    if "`e(prefix)'" != "" exit
    local rv = e(rank_v)
    local rh = e(rank_h)
    if e(N_clust) < . & e(N_clust) - 1 < e(rank_h) {
        _xtgamfe_note_e "e(V) of the fit has rank `rv', below its `rh' coefficients (too few clusters); with so few clusters inference may be unreliable."
    }
    else {
        _xtgamfe_note_e "e(V) of the fit has rank `rv', below its `rh' coefficients: the cluster scores do not span the coefficients, and a coefficient may rest on one cluster."
    }
end

// ---------------------------------------------------------------
// The data must be those of the estimation, row by row: the row signature
// of the estimation inputs is compared with the one stored at estimation
// (results of xtgamfe 1.1.1 and later).  Stata's own data signature, which
// checks each variable separately, is checked by the caller.
// ---------------------------------------------------------------
program define _xtgamfe_rowcheck
    version 15.0
    if `"`e(xtg_rsig)'"' == "" exit
    _xtgamfe_rsig_e `"`e(xtg_rkeys)'"' `e(panvar)' `"`e(timevar)'"'
    if `"`r(sig)'"' != `"`e(xtg_rsig)'"' {
        di as error "data have changed since estimation"
        di as error "(on the estimation sample, values of the outcome, regressors, offset,"
        di as error "weights or cluster variable are not in the rows they had at estimation)"
        exit 459
    }
end

// ---------------------------------------------------------------
// The estimation sample and data checks shared by estat fepoisson and
// estat park: e(sample) must be available and the data unchanged.
// ---------------------------------------------------------------
program define _xtgamfe_esample
    version 15.0
    args touse
    tempvar ord
    quietly generate long `ord' = _n
    capture quietly generate byte `touse' = e(sample)
    local bad = (_rc != 0)
    if !`bad' {
        quietly count if `touse'
        if r(N) == 0 local bad = 1
    }
    if `bad' {
        di as error "the estimation sample is not available (results loaded with estimates use?);"
        di as error "re-estimate on the data"
        exit 459
    }
    local has_ts = 0
    foreach t in `e(indepvars_full)' {
        local comps : subinstr local t "#" " ", all
        foreach c of local comps {
            _ms_parse_parts `c'
            if "`r(ts_op)'" != "" local has_ts = 1
        }
    }
    if `has_ts' {
        capture quietly xtset
        if _rc | "`r(panelvar)'" != "`e(panvar)'" | "`r(timevar)'" != "`e(timevar)'" {
            di as error "the model contains time-series operators, and the data are not xtset as at estimation"
            di as error "type:  xtset `e(panvar)' `e(timevar)'"
            exit 459
        }
        if e(tdelta) < . & r(tdelta) != e(tdelta) {
            di as error "the model contains time-series operators, and the data are xtset with"
            di as error "another delta than at estimation"
            di as error "type:  xtset `e(panvar)' `e(timevar)', delta(`=e(tdelta)')"
            exit 459
        }
        fvrevar `e(indepvars_full)'
        local rvfull "`r(varlist)'"
        sort `ord'
        _xtgamfe_dschk_e `rvfull'
    }
    else _xtgamfe_dschk_e
    _xtgamfe_rowcheck
    sort `ord'
    if `"`e(xtg_wsig)'"' != "" {
        tempvar wv
        quietly generate double `wv' `e(wexp)' if `touse'
        _xtgamfe_wsigchk `wv'
    }
    _xtgamfe_clchk `touse'
end

// ---------------------------------------------------------------
// The positions in e(b) of the terms that xtgamfe omitted as not identified,
// the terms that e(omitted) names, in r(pos).
// e(omitted) holds names, and a term entered twice (x1 x2 x1, or x1 next to
// the x1 that i.k##c.x1 expands to) has the same name at two positions, of
// which the fit estimates the first and omits the second: a test by name
// took the estimated copy for omitted too, and estat ape and estat
// fepoisson then left out a coefficient that the fit estimated.  A name
// that occurs in e(b) as often as in e(omitted) is omitted at every
// position (every name that occurs once).  For a name that occurs more
// often, the relations stored by the fit give the positions: the first rows
// of e(xtg_relq) are those of the omitted terms, in the order of
// e(omitted), each with 1 at the position of its own term and -1 (to
// rounding) at the position of the copy it duplicates.  Without them (or if
// they do not single out one position) the later positions are taken: the
// fit sweeps the terms in order, so of two collinear terms it omits the
// later one.
// ---------------------------------------------------------------
program define _xtgamfe_omitpos, rclass
    version 15.0
    local full `"`e(indepvars_full)'"'
    local omitted `"`e(omitted)'"'
    local m : word count `omitted'
    if `m' == 0 {
        return local pos ""
        exit
    }
    local n : word count `full'
    local uom : list uniq omitted
    local nu : word count `uom'
    forvalues u = 1/`nu' {
        local P_`u' ""
        local S_`u' ""
    }
    // P_u: the positions in e(b) of the u-th name; S_u: its ranks in
    // e(omitted)
    local j = 0
    foreach t of local full {
        local j = `j' + 1
        local u : list posof `"`t'"' in uom
        if `u' > 0 local P_`u' "`P_`u'' `j'"
    }
    local s = 0
    foreach t of local omitted {
        local s = `s' + 1
        local u : list posof `"`t'"' in uom
        local S_`u' "`S_`u'' `s'"
    }
    tempname RQ RC
    local hasq = 0
    capture matrix `RQ' = e(xtg_relq)
    if _rc == 0 {
        capture matrix `RC' = e(xtg_relc)
        if _rc == 0 {
            if colsof(`RQ') == `n' & rowsof(`RQ') == rowsof(`RC') + 2 & rowsof(`RC') >= `m' local hasq = 1
        }
    }
    local pos ""
    forvalues u = 1/`nu' {
        local np : word count `P_`u''
        local mu : word count `S_`u''
        if `np' <= `mu' {
            local pos "`pos' `P_`u''"
            continue
        }
        local okq = `hasq'
        local got ""
        if `okq' {
            foreach s of local S_`u' {
                local code = `RC'[`s', 1]
                if !inlist(`code', 1, 2, 3) local okq = 0
                if !`okq' continue
                local hit ""
                foreach j of local P_`u' {
                    if `RQ'[`s', `j'] == 1 local hit "`hit' `j'"
                }
                if `: word count `hit'' != 1 local okq = 0
                else local got "`got' `hit'"
            }
            if `okq' {
                local ug : list uniq got
                if `: word count `ug'' != `mu' local okq = 0
            }
        }
        if !`okq' {
            local got ""
            forvalues i = `=`np' - `mu' + 1'/`np' {
                local got "`got' `: word `i' of `P_`u'''"
            }
        }
        local pos "`pos' `got'"
    }
    local pos : list clean pos
    return local pos "`pos'"
end

// ---------------------------------------------------------------
// The iterate() of the fit, r(iterate): from its command line, or, after a
// prefix, from the command that the prefix ran (1000, the default,
// otherwise).
// ---------------------------------------------------------------
program define _xtgamfe_fititer, rclass
    version 15.0
    local cl `"`e(cmdline)'"'
    gettoken c1 rest : cl
    if "`c1'" != "xtgamfe" {
        local cl `"`e(command)'"'
        gettoken c1 rest : cl
    }
    local it = 1000
    if "`c1'" == "xtgamfe" {
        local 0 `"`rest'"'
        capture syntax anything [if] [in] [fweight iweight pweight] [, ITERate(integer 1000) *]
        if _rc == 0 local it = `iterate'
    }
    return scalar iterate = `it'
end

// ---------------------------------------------------------------
// The coefficients that rest on one cluster, for the clusters that estat ape
// and estat fepoisson use: e(clustvar) when it is set and is not the panel
// variable, and otherwise the panels.  xtgamfe finds them (e(xtg_onecl),
// e(xtg_ocdterms), e(xtg_onecl_pos), e(xtg_ocdir)) only for a clustered
// variance of its own, with its own clusters.  After vce(oim) it computes
// no clustered variance and finds none, although both commands report a
// sandwich clustered on the panels and estat fepoisson resamples them;
// after a bootstrap or jackknife (the prefix, or vce(bootstrap) or
// vce(jackknife)) the full-sample fit found them for its own clusters (the
// panels, unless the command it ran set others), which need not be those
// of the prefix.  In those cases (any fit that is not xtgamfe's own
// vce(robust) or vce(cluster)) they are found by fitting the model again,
// quietly, with vce(cluster) on the clusters used, to the terms of the fit
// (e(indepvars_full)) on the estimation sample, with the realized weights
// wv, the offset, tolerance() and iterate() of the fit, starting from the
// coefficients of the results.  The check depends on the design, the
// weights and the clusters, not on the coefficients or on the variance of
// the fit.  Started from the coefficients of a converged fit of the same
// model, the refit converges at once, whatever the starting values,
// tolerance() and iterate() of the fit (a refit from the default starting
// values could stop at coefficients that differ by more than rounding from
// those of a fit started elsewhere, or not converge within iterate()).
// from() takes the start in the order of the estimated terms (the terms of
// e(indepvars_full) without a base or omission marker, as xtgamfe counts
// them), with every column named _cons, which no term can be: by name, a
// term entered twice (x1 x2 x1) would have two columns.  The results in
// memory are held and come back, the sort seed is restored where Stata has
// c(sortseed), and the data are preserved and xtset as at estimation for
// the refit, unless the caller has already done both (option preserved).
// The refit must reproduce the coefficients of the results: the same names,
// the same number of observations, and the same values to a relative 1e-12
// (the start is rescaled with the regressors and back, which can change the
// last bit).  A refit that moves away from them is of another model or
// sample, or the coefficients are not those of the model fitted to these
// data (as when e(b) was changed after the fit); then, or when the refit
// fails, the command stops with return code 498.  r(src) is "fit" or
// "refit"; r(onecl), r(ocdterms), r(onepos) and r(ocdir) are what
// e(xtg_onecl), e(xtg_ocdterms), e(xtg_onecl_pos) and e(xtg_ocdir) hold
// after a clustered fit.
// ---------------------------------------------------------------
program define _xtgamfe_oclinfo, rclass
    version 15.0
    syntax , TOUSE(varname) CMD(string) [WV(string) PRESERVED]
    if "`e(prefix)'" == "" & "`e(vce)'" == "cluster" {
        return local src "fit"
        return local onecl `"`e(xtg_onecl)'"'
        return local ocdterms `"`e(xtg_ocdterms)'"'
        return local onepos `"`e(xtg_onecl_pos)'"'
        capture confirm matrix e(xtg_ocdir)
        if _rc == 0 {
            tempname OD
            matrix `OD' = e(xtg_ocdir)
            return matrix ocdir = `OD'
        }
        exit
    }
    local panvar "`e(panvar)'"
    local timevar "`e(timevar)'"
    local tdelta = e(tdelta)
    local cv "`panvar'"
    if "`e(clustvar)'" != "" & "`e(clustvar)'" != "`panvar'" local cv "`e(clustvar)'"
    local vceopt "vce(robust)"
    if "`cv'" != "`panvar'" local vceopt "vce(cluster `cv')"
    local wgt ""
    if "`e(wtype)'" != "" local wgt "[`e(wtype)'=`wv']"
    local offopt ""
    if "`e(offset)'" != "" local offopt "offset(`e(offset)')"
    _xtgamfe_fititer
    local itopt "iterate(`=r(iterate)')"
    local tolopt "tolerance(`=e(tolerance)')"
    local full `"`e(indepvars_full)'"'
    local depvar "`e(depvar)'"
    local Nref = e(N)
    tempname bref bnew eh OD bst
    matrix `bref' = e(b)
    // the start: the coefficients of the estimated terms, in order
    local epos ""
    local j = 0
    foreach t of local full {
        local j = `j' + 1
        _ms_parse_parts `t'
        if r(base) != 1 & r(omit) != 1 local epos "`epos' `j'"
    }
    local nst : word count `epos'
    if `nst' > 0 {
        mata: st_matrix("`bst'", st_matrix("`bref'")[strtoreal(tokens(st_local("epos")))])
        local cst : display _dup(`nst') "_cons "
        matrix colnames `bst' = `cst'
    }
    local sseed ""
    capture local sseed = c(sortseed)
    if "`preserved'" == "" {
        preserve
        if "`timevar'" != "" {
            local dopt ""
            if `tdelta' < . local dopt "delta(`tdelta')"
            capture quietly xtset `panvar' `timevar', `dopt'
        }
        else capture quietly xtset `panvar'
        if _rc {
            di as error "the data cannot be xtset with the panel and time variables of the fit"
            di as error "(`panvar' `timevar'), which estat `cmd' uses"
            exit 459
        }
    }
    _estimates hold `eh', restore copy
    capture quietly xtgamfe `depvar' `full' if `touse' `wgt', `vceopt' `offopt' `tolopt' `itopt' from(`bst') nolog nofe
    local rc = _rc
    local same = 0
    local has_od = 0
    if !`rc' {
        local r_onecl `"`e(xtg_onecl)'"'
        local r_ocdt `"`e(xtg_ocdterms)'"'
        local r_pos `"`e(xtg_onecl_pos)'"'
        capture confirm matrix e(xtg_ocdir)
        if _rc == 0 {
            matrix `OD' = e(xtg_ocdir)
            local has_od = 1
        }
        matrix `bnew' = e(b)
        local c0 : colfullnames `bref'
        local c1 : colfullnames `bnew'
        local same = (`"`c0'"' == `"`c1'"') & (e(N) == `Nref')
        if `same' local same = (mreldif(`bnew', `bref') <= 1e-12)
    }
    _estimates unhold `eh'
    if "`sseed'" != "" capture set sortseed `sseed'
    if "`preserved'" == "" restore
    if `rc' | !`same' {
        di as error "estat `cmd': the check of which coefficients rest on one of the clusters"
        di as error "used (`cv') failed: fitting the model again with `vceopt' on the"
        di as error "estimation sample failed or did not reproduce the coefficients; refit"
        di as error "with `vceopt' and type estat `cmd' again"
        exit 498
    }
    return local src "refit"
    return local onecl `"`r_onecl'"'
    return local ocdterms `"`r_ocdt'"'
    return local onepos `"`r_pos'"'
    if `has_od' return matrix ocdir = `OD'
end

// ---------------------------------------------------------------
// estat fepoisson: comparison with fixed-effects Poisson on the estimation
// sample.  Both estimators are fitted to the same observations; the
// difference of their coefficients is tested with a bootstrap that
// resamples the clusters of the fit (the panels, unless the fit clustered
// on a variable that nests them), giving each resampled cluster its own
// identifier.  For a fit clustered on panels this is
//     program gpdiff, rclass: xtgamfe ...; xtpoisson ... if e(sample), fe;
//         return the differences
//     generate newid = panvar; xtset newid timevar
//     bootstrap ..., cluster(panvar) idcluster(newid) reps() seed(): gpdiff
// run on the data in memory, so that the same seed gives the same
// replications.
//
// The model compared is the one that was fitted, whatever has changed in
// the variables or settings since.  The terms come from e(indepvars_full),
// the expanded term list of the fit with its factor levels and base
// levels (not from the command line, so a wildcard is not expanded again
// and a later fvset base does not change a contrast), and the data are
// xtset with the panel variable, time variable and delta of the fit for
// the duration of the command (the caller's settings come back with the
// data).  Each estimated term is realized as a variable on the estimation
// sample: a factor level as the indicator of that level, a lag or lead with
// the fit's delta.  Both estimators are fitted to these variables, in the
// full sample and in every replication, so each Poisson coefficient is
// paired with the xtgamfe coefficient of the same term by construction,
// and the replications need no rows outside the estimation sample.  The
// clusters are resampled through dense identifiers (1, 2, ... in the order
// of the cluster variable), so any storage type of the identifiers works
// and the same seed draws the same clusters as the recipe above.  An
// xtpoisson fit that does not converge is a failed fit: on the full sample
// the command stops, and in a replication the replication is left out.
// ---------------------------------------------------------------
program define xtgamfe_estat_fep, rclass sortpreserve
    version 15.0
    syntax [, Reps(integer 999) SEED(string) Level(cilevel) noDOTS]
    if `reps' < 2 {
        di as error "reps() must be at least 2"
        exit 198
    }
    // the clusters of the results must nest the panels (before anything is
    // computed; from 1.1.1)
    tempvar es0
    capture quietly generate byte `es0' = e(sample)
    if _rc == 0 _xtgamfe_clchk `es0'
    capture drop `es0'
    if "`e(wtype)'" != "" {
        di as error "estat fepoisson does not allow weights: the bootstrap that tests the"
        di as error "difference does not accept them, and xtpoisson, fe accepts only weights"
        di as error "that are constant within panel"
        exit 498
    }
    // The results must be those of xtgamfe itself (not of a prefix typed
    // before it); the command line supplies only the iterate() of the fit.
    local cl `"`e(cmdline)'"'
    gettoken c1 rest : cl
    if "`c1'" != "xtgamfe" {
        di as error "estat fepoisson needs results fitted by xtgamfe itself; after a prefix"
        di as error "command, refit with xtgamfe (with vce(cluster clustvar) for clusters that"
        di as error "nest the panels) and type estat fepoisson again"
        exit 498
    }
    local 0 `"`rest'"'
    capture syntax anything [if] [in] [fweight iweight pweight] [, ITERate(integer 1000) *]
    if _rc local iterate = 1000

    local depvar  "`e(depvar)'"
    local panvar  "`e(panvar)'"
    local timevar "`e(timevar)'"
    local tdelta = e(tdelta)
    local offopt ""
    if "`e(offset)'" != "" local offopt "offset(`e(offset)')"
    local tolopt "tolerance(`=e(tolerance)')"

    // clusters resampled: those of the fit
    local cv "`panvar'"
    if "`e(clustvar)'" != "" & "`e(clustvar)'" != "`panvar'" local cv "`e(clustvar)'"
    local nested = ("`cv'" != "`panvar'")

    // ---- the terms of the fit ----
    // fitj: positions in e(b) of the estimated terms (both estimators are
    // fitted with all of them); cmpj: those compared (with a nonzero
    // variance in the fit).
    tempname bg Vg
    matrix `bg' = e(b)
    matrix `Vg' = e(V)
    local cn : colnames `bg'
    local full `"`e(indepvars_full)'"'
    if `: word count `full'' != colsof(`bg') {
        di as error "estat fepoisson requires results stored by xtgamfe 1.1.1 or later"
        exit 498
    }
    // the terms that xtgamfe omitted, by position (a term entered twice
    // has the same name at both positions, and only the second is omitted;
    // _xtgamfe_omitpos)
    _xtgamfe_omitpos
    local opos "`r(pos)'"
    local fitj ""
    local cmpj ""
    local terms ""
    local j = 0
    foreach t of local cn {
        local j = `j' + 1
        _ms_parse_parts `t'
        if r(base) == 1 | r(omit) == 1 continue
        if `: list j in opos' continue
        local tf : word `j' of `full'
        if "`tf'" != "`t'" {
            di as error "estat fepoisson: the term list of the fit does not match e(b) (`tf', `t')"
            exit 498
        }
        local fitj "`fitj' `j'"
        if `Vg'[`j', `j'] == 0 continue
        local cmpj "`cmpj' `j'"
        local terms "`terms' `t'"
    }
    local terms : list clean terms
    if "`terms'" == "" {
        di as error "no estimated coefficient to compare"
        exit 498
    }
    local dfr = e(df_r)

    // ---- the data of the fit ----
    tempvar ord0 touse
    quietly generate long `ord0' = _n
    preserve
    // the panel and time variables and the delta of the fit
    if "`timevar'" != "" {
        local dopt ""
        if `tdelta' < . local dopt "delta(`tdelta')"
        capture quietly xtset `panvar' `timevar', `dopt'
    }
    else capture quietly xtset `panvar'
    if _rc {
        di as error "the data cannot be xtset with the panel and time variables of the fit"
        di as error "(`panvar' `timevar'), which estat fepoisson uses"
        exit 459
    }
    sort `ord0'
    _xtgamfe_esample `touse'
    // The terms that rest on one of the clusters resampled (also after
    // vce(oim), vce(bootstrap) or vce(jackknife), by a refit from the stored
    // estimates on the data as they are now: preserved and xtset as at
    // estimation; _xtgamfe_oclinfo)
    _xtgamfe_oclinfo, touse(`touse') cmd(fepoisson) preserved
    local oc_src "`r(src)'"
    local oc_onecl `"`r(onecl)'"'
    local oc_ocdt `"`r(ocdterms)'"'
    local onepos `"`r(onepos)'"'

    // each estimated term as a variable on the estimation sample
    if "`timevar'" != "" sort `panvar' `timevar'
    local rvars ""
    local rcmp ""
    foreach j of local fitj {
        local t : word `j' of `full'
        local comps : subinstr local t "#" " ", all
        local ex ""
        foreach c of local comps {
            _ms_parse_parts `c'
            local op "`r(ts_op)'"
            if "`op'" != "" local op "`op'."
            if "`r(type)'" == "factor" local f "(`op'`r(name)' == `r(level)')"
            else                        local f "`op'`r(name)'"
            if "`ex'" == "" local ex "`f'"
            else            local ex "`ex' * `f'"
        }
        tempvar rv
        quietly generate double `rv' = `ex' if `touse'
        local rvars "`rvars' `rv'"
        if `: list j in cmpj' local rcmp "`rcmp' `rv'"
    }
    sort `ord0'
    quietly keep if `touse'

    // ---- the full-sample Poisson fit ----
    tempname ehold bp Vp
    _estimates hold `ehold', restore copy
    capture noisily quietly xtpoisson `depvar' `rvars', fe `offopt' vce(robust)
    local prc = _rc
    local pconv = e(converged)
    if !`prc' & `pconv' == 1 {
        matrix `bp' = e(b)
        matrix `Vp' = e(V)
    }
    _estimates unhold `ehold'
    if `prc' | `pconv' != 1 {
        if `prc' == 430 | (!`prc' & `pconv' != 1) {
            di as error "xtpoisson, fe did not converge on the estimation sample of xtgamfe"
            exit 430
        }
        di as error "xtpoisson, fe failed on the estimation sample of xtgamfe"
        exit `prc'
    }
    local cnp : colnames `bp'

    // pair the coefficients: the Poisson coefficient of each realized term
    local k = 0
    local nterms ""
    local bvars ""
    local skipped ""
    local i = 0
    foreach j of local cmpj {
        local i = `i' + 1
        local t : word `i' of `terms'
        local rv : word `i' of `rcmp'
        local jp : list posof "`rv'" in cnp
        local ok = (`jp' > 0)
        if `ok' {
            if `Vp'[`jp', `jp'] == 0 | missing(`Vp'[`jp', `jp']) local ok = 0
        }
        if !`ok' {
            local skipped "`skipped' `t'"
            continue
        }
        local k = `k' + 1
        local nterms "`nterms' `t'"
        local bvars "`bvars' `rv'"
        local bg_`k' = `bg'[1, `j']
        local jg_`k' = `j'
        local jp_`k' = `jp'
        local sg_`k' = sqrt(`Vg'[`j', `j'])
        local bp_`k' = `bp'[1, `jp']
        local sp_`k' = sqrt(`Vp'[`jp', `jp'])
    }
    local nterms : list clean nterms
    if `k' == 0 {
        di as error "xtpoisson, fe estimated none of the coefficients of xtgamfe"
        exit 498
    }

    // Terms that rest on one cluster (onepos, the e(xtg_onecl_pos) of a
    // clustered fit or of the refit of _xtgamfe_oclinfo: those that vary
    // within panels in only one cluster and those involved in a direction
    // that rests on one cluster; from 1.1.1): the clusters cannot estimate
    // the sampling variation of their coefficients, so their differences
    // are shown but not resampled, without the fit's std. errs. (except
    // after vce(oim), whose std. errs. do not use the clusters) and without
    // the xtpoisson std. err. when the fit clusters on the panels, on which
    // the xtpoisson sandwich clusters too, and are left out of the joint
    // test.  The bootstrap resamples the other kt differences (kt = k
    // otherwise).  A replication that does not draw the one cluster drops
    // such a term (or one of the terms of the direction) from both refits
    // and is kept when every tested difference is estimated (see
    // _xtgamfe_fepb_e), so the bootstrap is not conditional on drawing that
    // cluster.
    local kt = 0
    local tvars ""
    local tnames ""
    local ocl ""
    forvalues i = 1/`k' {
        local jj = `jg_`i''
        local oc_`i' = `: list jj in onepos'
        local nm : word `i' of `nterms'
        if `oc_`i'' {
            local ocl "`ocl' `nm'"
            local ti_`i' = 0
        }
        else {
            local kt = `kt' + 1
            local ti_`i' = `kt'
            local rv : word `i' of `bvars'
            local tvars "`tvars' `rv'"
            local tnames "`tnames' `nm'"
        }
    }
    local ocl : list clean ocl
    local tnames : list clean tnames
    // When every coefficient compared rests on one cluster (kt = 0), no
    // difference can be resampled: the comparison is shown with the
    // inference fields left blank, no bootstrap is run, and a note says
    // why.  M is then counted here.
    local noboot = (`kt' == 0)
    if `noboot' {
        tempvar dcl0
        quietly egen long `dcl0' = group(`cv')
        quietly summarize `dcl0', meanonly
        local Mb = r(max)
        local nreps = 0
        local nmis = 0
        local brc = 0
        restore
    }
    else {

    // ---- the bootstrap of the differences ----
    local explist ""
    forvalues i = 1/`kt' {
        local explist "`explist' d`i'=r(d`i')"
    }
    local seedopt ""
    if "`seed'" != "" local seedopt "seed(`seed')"
    // Each resampled cluster gets its own identifier (idcluster()); when
    // the clusters nest the panels, group() gives each copy of each panel
    // its own identifier too, and the data are xtset on it.
    tempvar dcl newc newp
    quietly egen long `dcl' = group(`cv')
    local grpopt ""
    if `nested' {
        quietly egen long `newp' = group(`panvar')
        quietly generate long `newc' = .
        sort `ord0'
        quietly xtset `newp' `timevar'
        local grpopt "group(`newp')"
    }
    else {
        quietly generate long `newc' = `dcl'
        sort `ord0'
        quietly xtset `newc' `timevar'
    }
    _estimates hold `ehold', restore copy
    // the replication dots are shown unless nodots is given.  The
    // replications are run through xtgamfe (xtgamfe _fepb, which calls
    // _xtgamfe_fepb below while this global is set), so that the bootstrap
    // names xtgamfe, not this program, when it starts (from 1.1.1).
    local qui ""
    if "`dots'" != "" local qui "quietly"
    global XTGAMFE_FEPB "1"
    capture noisily `qui' bootstrap `explist', cluster(`dcl') idcluster(`newc') ///
        `grpopt' reps(`reps') `seedopt' `dots' notable noheader nolegend: ///
        xtgamfe _fepb `depvar' `"`rvars'"' `"`tvars'"' `"`offopt' `tolopt' iterate(`iterate')"'
    local brc = _rc
    global XTGAMFE_FEPB
    if !`brc' {
        tempname bb bV
        matrix `bb' = e(b)
        matrix `bV' = e(V)
        local nreps = e(N_reps)
        local nmis = e(N_misreps)
        if "`nmis'" == "" local nmis = 0
        local Mb = e(N_clust)
    }
    _estimates unhold `ehold'
    restore
    }
    if `brc' {
        di as error "the bootstrap of the difference failed"
        exit `brc'
    }

    // ---- display ----
    if `dfr' < . & `dfr' > 0 {
        local crit = invttail(`dfr', (100 - `level') / 200)
        local zlab "     t    P>|t|"
    }
    else {
        local dfr = .
        local crit = invnormal(1 - (100 - `level') / 200)
        local zlab "     z    P>|z|"
    }
    local Mbd : display %12.0fc `Mb'
    local Mbd = strtrim("`Mbd'")
    di ""
    di as text "Comparison with fixed-effects Poisson (xtpoisson, fe) on the estimation sample"
    di as text "{hline 13}{c TT}{hline 64}"
    di as text "             {c |}          xtgamfe                xtpoisson, fe"
    di as text "             {c |}  Coefficient  Std. err.    Coefficient  Std. err."
    di as text "{hline 13}{c +}{hline 64}"
    forvalues i = 1/`k' {
        local nm : word `i' of `nterms'
        local sgd = `sg_`i''
        local spd = `sp_`i''
        // A coefficient that rests on one cluster: the fit's std. err. is
        // not shown when it is clustered or resampled, since the clusters
        // cannot measure that coefficient's sampling variation, but it is
        // after vce(oim), whose std. err. does not use the clusters.  The
        // xtpoisson sandwich clusters on the panels: when these are the
        // clusters of the fit, it cannot measure that variation either.
        if `oc_`i'' & "`e(vce)'" != "oim" local sgd = .
        if `oc_`i'' & !`nested' local spd = .
        di as text %12s abbrev("`nm'", 12) " {c |}" as result _col(19) %9.0g `bg_`i'' ///
            _col(30) %9.0g `sgd' _col(45) %9.0g `bp_`i'' _col(56) %9.0g `spd'
    }
    di as text "{hline 13}{c BT}{hline 64}"
    local vtg "`e(vcetype)'"
    if "`vtg'" == "" local vtg = cond("`e(vce)'" == "oim", "OIM", "`e(vce)'")
    if "`e(clustvar)'" != "" di as text "Std. errs.: xtgamfe as fitted (`vtg', clustered on `e(clustvar)'); xtpoisson"
    else                     di as text "Std. errs.: xtgamfe as fitted (`vtg'); xtpoisson"
    di as text "            vce(robust), clustered on panels."
    di ""
    if `noboot' {
        // no difference is resampled
        di as text "Difference (xtgamfe - xtpoisson), not resampled"
    }
    else {
        di as text "Difference (xtgamfe - xtpoisson), bootstrap std. err." ///
            _col(55) "Replications  = " as result %9.0fc `nreps'
        if `nested' local how "the `Mbd' clusters in `cv'"
        else        local how "the `Mbd' panels"
        di as text "Bootstrap resampling `how'"
    }
    di as text "{hline 13}{c TT}{hline 64}"
    di as text "             {c |} Difference   Std. err. `zlab'     [`level'% conf. interval]"
    di as text "{hline 13}{c +}{hline 64}"
    tempname D VD Dt
    matrix `D' = J(1, `k', .)
    if !`noboot' matrix `Dt' = J(1, `kt', .)
    forvalues i = 1/`k' {
        local nm : word `i' of `nterms'
        local d = `bg_`i'' - `bp_`i''
        matrix `D'[1, `i'] = `d'
        if `oc_`i'' local se = .
        else {
            matrix `Dt'[1, `ti_`i''] = `d'
            local se = sqrt(`bV'[`ti_`i'', `ti_`i''])
        }
        local zz = `d' / `se'
        if `dfr' < . local pv = 2 * ttail(`dfr', abs(`zz'))
        else         local pv = 2 * normal(-abs(`zz'))
        di as text %12s abbrev("`nm'", 12) " {c |}  " as result %9.0g `d' "  " %9.0g `se' " " ///
            %8.2f `zz' " " %7.3f `pv' "    " %9.0g (`d' - `crit' * `se') "   " %9.0g (`d' + `crit' * `se')
    }
    di as text "{hline 13}{c BT}{hline 64}"
    // Joint test of equal coefficients, with the bootstrap covariance.  It
    // is reported only when that covariance has full rank: the rank of a
    // covariance from B replications is at most B - 1, and a quadratic form
    // in a generalized inverse of a singular covariance tests only some of
    // the differences, which ones depending on their order.  The Wald
    // statistic D of the k differences is referred to a Hotelling-type F
    // approximation: (B - k)/(k(B - 1)) D is referred to F(k, B - k), the
    // exact law when the differences are normal and the covariance is an
    // independent Wishart estimate from B draws.  A bootstrap covariance
    // is neither independent of the differences nor Wishart, so this is an
    // approximation: under a normal approximation to the differences it
    // allows for the variability of a covariance estimated from a finite
    // number B of resamples, which matters when B is not much larger than k.
    // (Referred to chi2(k), D rejects far too often when B is near k.)
    // The joint test is of the kt resampled differences (all k of them
    // unless a term varies within panels in only one cluster).
    matrix colnames `D' = `nterms'
    tempname chi rkn Fh
    if !`noboot' {
        matrix `VD' = `bV'
        matrix colnames `Dt' = `tnames'
        matrix colnames `VD' = `tnames'
        matrix rownames `VD' = `tnames'
        mata: _xtgamfe_fep_wald("`Dt'", "`VD'", `nreps', "`chi'", "`rkn'")
    }
    else {
        scalar `chi' = .
        scalar `rkn' = 0
    }
    local chi2 = scalar(`chi')
    local rk = scalar(`rkn')
    scalar `Fh' = .
    local dfh = .
    if `noboot' {
        local chi2 = .
        local pj = .
        di as text "Joint test of equal coefficients: not reported (no difference is resampled)"
    }
    else if `chi2' < . & `rk' == `kt' & `nreps' > `kt' {
        local dfh = `nreps' - `kt'
        scalar `Fh' = (`nreps' - `kt') / (`kt' * (`nreps' - 1)) * scalar(`chi')
        local pj = Ftail(`kt', `dfh', scalar(`Fh'))
        di as text "Joint test of equal coefficients: F(" as result `kt' as text ", " ///
            as result `dfh' as text ") = " as result %9.2f scalar(`Fh') as text "   Prob > F = " as result %6.4f `pj'
        di as text "      (Hotelling-type F approximation: (B-k)/(k(B-1)) times the Wald"
        di as text "      statistic D = " as result strtrim(string(`chi2', "%9.0g")) as text "; B = " ///
            as result `nreps' as text " replications used, k = " as result `kt' as text cond(`kt' == 1, " difference)", " differences)")
    }
    else {
        local chi2 = .
        local pj = .
        if `rk' > 0 & `rk' < `kt' {
            di as text "Joint test of equal coefficients: not reported (the bootstrap covariance has"
            di as text "      rank `rk', below the `kt' differences)"
            if `nreps' - 1 < `kt' {
                di as text "      With `nreps' replications its rank is at most `=`nreps' - 1'; increase reps()."
            }
        }
        else {
            di as text "Joint test of equal coefficients: not available (the bootstrap covariance"
            di as text "      has a missing or zero variance)"
        }
    }
    if `nmis' > 0 {
        di as text "Note: `nmis' replication(s) failed and are left out."
    }
    // Few replications.  A bootstrap std. err. from B
    // replications has a relative sampling error of about 1/sqrt(2B) for
    // normal differences (5 percent with B = 199, 10 percent with 50, 32
    // percent with 5), and the z statistics and p-values of the single
    // differences treat it as known; the F approximation of the joint test
    // allows for B under normality, but its covariance rests on as few
    // draws.  Below 199 replications used, a note says so.
    if !`noboot' & `nreps' < 199 {
        local rw "replications were"
        if `nreps' == 1 local rw "replication was"
        _xtgamfe_note_e "only `nreps' `rw' used: the std. errs. and p-values of the single differences, and the joint test, rest on few draws (a bootstrap std. err. from B replications has a relative error of about 1/sqrt(2B)); use reps(199) or more."
    }
    if "`skipped'" != "" {
        di as text "Note: not compared (not estimated by xtpoisson, fe):`skipped'"
    }
    // the one-cluster terms (above), or the rank warning of the fit,
    // repeated (from 1.1.1)
    if "`ocl'" != "" {
        local n1 : word count `ocl'
        local othd "the other `kt' differences"
        if `kt' == 1 local othd "the other difference"
        if `noboot' {
            // every term compared rests on one cluster
            if `n1' == 1 local tail ": its difference is shown without std. errs., test and interval; with no other difference to resample, no bootstrap is run and no joint test is reported."
            else         local tail ": their differences are shown without std. errs., tests and intervals; with no other difference to resample, no bootstrap is run and no joint test is reported."
        }
        else {
            if `n1' == 1 local tail ": its difference is not resampled, is shown without std. errs., test and interval, and is left out of the joint test, which covers `othd'."
            else         local tail ": their differences are not resampled, are shown without std. errs., tests and intervals, and are left out of the joint test, which covers `othd'."
            // replications that do not draw that cluster are kept
            local tail "`tail'  Replications that do not draw such a cluster are kept; their refits leave out what that cluster alone identifies."
        }
        _xtgamfe_oneclnote `"`tail'"' `"`oc_onecl'"' `"`oc_ocdt'"' `oc_src'
    }
    else _xtgamfe_ranknote `"`oc_onecl'"' `"`oc_ocdt'"'
    di as text "Note: a material difference calls for a check of the mean specification,"
    di as text "      of strict exogeneity, and of share centering, the condition of xtgamfe"
    di as text "      (see {help xtgamfe##caveats:help xtgamfe})."

    tempname BG BP
    matrix `BG' = J(1, `k', .)
    matrix `BP' = J(1, `k', .)
    forvalues i = 1/`k' {
        // from the coefficient matrices, not from the macros used for display (a number passed
        // through a macro can lose its last bit)
        matrix `BG'[1, `i'] = `bg'[1, `jg_`i'']
        matrix `BP'[1, `i'] = `bp'[1, `jp_`i'']
    }
    matrix colnames `BG' = `nterms'
    matrix colnames `BP' = `nterms'
    return scalar N = e(N)
    return scalar N_clust = `Mb'
    return scalar reps = `reps'
    return scalar N_reps = `nreps'
    return scalar level = `level'
    return scalar df = `kt'
    return scalar rank = `rk'
    // the t statistics of the single differences, after small or
    // vce(jackknife)
    if `dfr' < . return scalar df_t = `dfr'
    // the joint test (from the scalars, not from the macros used for
    // display, which can lose the last bits)
    if `chi2' < . {
        return scalar chi2 = scalar(`chi')
        return scalar F = scalar(`Fh')
        return scalar df_m = `kt'
        return scalar df_r = `dfh'
    }
    return scalar p = `pj'
    if "`seed'" != "" return local seed "`seed'"
    return local clustvar "`cv'"
    local skipped : list clean skipped
    if "`skipped'" != "" return local skipped "`skipped'"
    if "`ocl'" != "" return local onecl "`ocl'"
    if !`noboot' return matrix V_diff = `VD'
    return matrix diff = `D'
    return matrix b_poisson = `BP'
    return matrix b_xtgamfe = `BG'
end

// ---------------------------------------------------------------
// One replication of estat fepoisson, as the bootstrap prefix runs it
// (through xtgamfe _fepb): _xtgamfe_fepb below, after which e() is left
// with e(sample) alone.  The prefix compares the
// omitted terms of the e(b) that each replication leaves with those of the
// full sample, and posts missing values for a replication whose omitted
// terms differ ("collinearity in replicate sample is not the same as the
// full sample").  e(b) was that of the last xtpoisson fit, so a
// replication that did not draw the one cluster of a term that rests on
// one cluster (e(onecl)), in which that term or direction drops out of
// both fits, was left out although every tested difference was estimated,
// and the bootstrap was conditional on drawing that cluster.  Without an
// e(b) the prefix makes no such check; whether a replication counts is
// decided by _xtgamfe_fepb from the tested differences alone.  e(sample)
// is kept as the last fit left it, because the prefix keeps the rows of
// e(sample) of the full-sample run before it resamples.
// ---------------------------------------------------------------
program define _xtgamfe_fepb_e, eclass
    version 15.0
    _xtgamfe_fepb `0'
    tempvar es
    quietly generate byte `es' = e(sample)
    ereturn post, esample(`es')
end

// ---------------------------------------------------------------
// One replication of estat fepoisson: both fits on the resampled data, to
// the realized terms of the fit, the differences tested returned as r(d1),
// r(d2), ...  A term that is not tested (one that rests on one cluster, or
// that xtpoisson did not estimate on the full sample) may drop out of
// either fit.  A tested coefficient that either fit does not estimate in a
// replication makes every difference missing (the prefix uses only
// replications in which every statistic is present; it cannot check their
// omitted terms, since a replication leaves no e(b)), as does an xtpoisson
// fit that fails or does not converge; an
// xtgamfe fit that fails stops the replication.  Either way the
// replication is left out.  The fits are run quietly, and xtgamfe's notes
// and warnings are written as text, so nothing is printed per replication.
// ---------------------------------------------------------------
program define _xtgamfe_fepb, rclass
    version 15.0
    args depvar rvars bvars opts
    quietly xtgamfe `depvar' `rvars', `opts' nofe nolog
    local i = 0
    foreach v of local bvars {
        local i = `i' + 1
        local g_`i' = .
        local sg = .
        capture local g_`i' = _b[`v']
        capture local sg = _se[`v']
        if `sg' == 0 | missing(`sg') local g_`i' = .
    }
    tempvar s
    quietly generate byte `s' = e(sample)
    local offopt ""
    if "`e(offset)'" != "" local offopt "offset(`e(offset)')"
    capture quietly xtpoisson `depvar' `rvars' if `s', fe `offopt'
    local pok = (_rc == 0)
    if `pok' local pok = (e(converged) == 1)
    local i = 0
    local anymis = 0
    foreach v of local bvars {
        local i = `i' + 1
        local p = .
        local sp = .
        if `pok' {
            capture local p = _b[`v']
            capture local sp = _se[`v']
        }
        if `sp' == 0 | missing(`sp') local p = .
        return scalar d`i' = `g_`i'' - `p'
        if missing(`g_`i'') | missing(`p') local anymis = 1
    }
    if `anymis' {
        forvalues j = 1/`i' {
            return scalar d`j' = .
        }
    }
end

// ---------------------------------------------------------------
// estat park: Park's (1966) test of the variance function, as the OLS
// regression on the estimation sample of the log squared residual on the
// log fitted mean, with the fitted means of the model (Manning and Mullahy
// 2001 give the GLM form, the modified Park test).  The log squared
// residual is formed as 2 ln|y - mu|, which neither overflows nor
// underflows with the units of the outcome; an observation whose residual
// is exactly zero has no logarithm and is left out.  The weights of the
// fit are used (fweights as frequency weights, pweights and iweights as
// sampling weights), and the standard errors are clustered as in the fit
// (on panels after vce(oim), vce(bootstrap) or vce(jackknife)).  A
// frequency weight of k stands for k panels, as in the fit: clustered on
// panels, the covariance and its degrees of freedom are those of the data
// expanded with each copy its own panel (each copy's score enters the
// meat once, and every copy is a cluster); with a cluster variable that
// nests the panels, the copies of a panel stay in its cluster, as in the
// fit.  The slope is 2 under independent gamma errors with one shape in
// balanced panels, unweighted or with weights constant within panel (the
// relative residuals are then independent of the fitted means), so the
// test of slope 2 checks the gamma model; it is not a test of the share
// condition under which the coefficients are consistent.  With weights
// that vary within panel the slope can differ from 2 even under the gamma
// model: the slope and its standard error are reported, the test is not
// (from 1.1.1); so too when the panels have different numbers of
// observations in the estimation sample.  The regression treats the
// fitted means and residuals as data, so the p-value of the test is
// nominal and its calibration depends on the design (the note says so).
// After an exact fit the residuals are rounding error,
// and the test is refused.
// ---------------------------------------------------------------
program define xtgamfe_estat_park, rclass sortpreserve
    version 15.0
    syntax [, Level(cilevel)]
    if e(xtg_boundary) == 1 {
        di as error "estat park is not available after an exact or near-exact fit: the fitted"
        di as error "within-panel shares are equal to numerical precision, so the residuals"
        di as error "are rounding error"
        exit 498
    }
    tempvar touse mu lr2 lmu wv ord
    quietly generate long `ord' = _n
    _xtgamfe_esample `touse'
    local panvar "`e(panvar)'"
    local cv "`panvar'"
    if "`e(clustvar)'" != "" local cv "`e(clustvar)'"
    local depvar "`e(depvar)'"
    quietly predict double `mu' if `touse', mu
    quietly generate double `lr2' = 2 * ln(abs(`depvar' - `mu')) if `touse'
    quietly generate double `lmu' = ln(`mu') if `touse'
    quietly count if `touse' & `depvar' == `mu'
    local nzero = r(N)
    local wt ""
    local fwpan = 0
    if "`e(wtype)'" != "" {
        quietly generate double `wv' `e(wexp)' if `touse'
        if "`e(wtype)'" == "fweight" {
            local wt "[fweight=`wv']"
            local fwpan = ("`cv'" == "`panvar'")
        }
        else {
            local wt "[pweight=`wv']"
            // sampling weights of an extreme scale are brought to order one
            // by an exact power of two (the regression does not depend on
            // their scale), so that their totals do not overflow
            quietly summarize `wv' if `touse', meanonly
            if r(max) < . & r(max) > 0 & (r(max) > 1e150 | r(max) < 1e-150) {
                tempname w2
                mata: st_numscalar("`w2'", _xtgamfe_w2_e(st_numscalar("r(max)")))
                quietly replace `wv' = `wv' * scalar(`w2')
            }
        }
    }
    // Weights that vary within panel (pweights or iweights; fweights are
    // constant within panel): the slope can then differ from 2 even under
    // the gamma model, and the test of slope 2 is not reported (from 1.1.1).
    local wvary = 0
    if inlist("`e(wtype)'", "pweight", "iweight") {
        tempvar wlo whi
        quietly egen double `wlo' = min(`wv') if `touse', by(`panvar')
        quietly egen double `whi' = max(`wv') if `touse', by(`panvar')
        quietly count if `touse' & `wlo' != `whi'
        local wvary = (r(N) > 0)
        drop `wlo' `whi'
    }
    // Panels with different numbers of observations in the estimation
    // sample: under independent gamma errors the relative residuals of a
    // panel are independent of its fitted level given its length, but their
    // distribution depends on the length, so when length is related to the
    // level the slope can differ from 2 too (with exponential errors, half
    // the panels of length 2 at level 1 and half of length 8 at level e^2,
    // it is 2.18; 2.22 with gamma errors of shape 2), and the test of
    // slope 2 is not reported.  A frequency weight
    // stands for copies of a panel of the same length.
    tempvar tlen
    quietly egen long `tlen' = total(`touse'), by(`panvar')
    quietly summarize `tlen' if `touse', meanonly
    local unbal = (r(min) < r(max))
    drop `tlen'
    // The rows in a fixed order (by cluster, panel and time, then the
    // caller's order), so that no sum depends on how Stata breaks ties
    // when it sorts.
    local cvs "`cv'"
    if "`cv'" == "`panvar'" local cvs ""
    sort `cvs' `panvar' `e(timevar)' `ord'
    tempname ehold po bs ses cs bchk
    _estimates hold `ehold', restore copy
    if `fwpan' {
        // the slope from regress with the frequency weights; the clustered
        // covariance of the expanded data, in which each copy of a panel is
        // a cluster: (X'WX)^-1 (sum_i k_i u_i u_i') (X'WX)^-1 times
        // (N-1)/(N-2) M/(M-1), with u_i the score of one copy of panel i,
        // k_i its weight, N the sum of the weights and M = sum_i k_i
        quietly regress `lr2' `lmu' `wt' if `touse'
        _xtgamfe_park_id
        local lomit = r(omit)
        scalar `bs' = _b[`lmu']
        scalar `cs' = _b[_cons]
        local N = e(N)
        if !`lomit' {
            tempvar rs
            quietly generate byte `rs' = e(sample)
            mata: _xtgamfe_park_fw("`lr2'", "`lmu'", "`wv'", "`panvar'", "`rs'", ///
                st_matrix("e(b)"), "`po'")
            scalar `ses' = `po'[1, 1]
            local M = `po'[1, 2]
            local dfr = `M' - 1
        }
    }
    else {
        quietly regress `lr2' `lmu' `wt' if `touse', vce(cluster `cv') level(`level')
        _xtgamfe_park_id
        local lomit = r(omit)
        scalar `bs' = _b[`lmu']
        scalar `ses' = _se[`lmu']
        scalar `cs' = _b[_cons]
        local dfr = e(df_r)
        local N = e(N)
        local M = e(N_clust)
    }
    _estimates unhold `ehold'
    // The slope must have been estimated: ln(fitted mean) must vary over
    // the observations used (those whose residual is not exactly zero).
    if `lomit' {
        di as error "estat park: ln(fitted mean) does not vary over the observations used (those"
        di as error "with a nonzero residual), so the slope of the Park regression is not identified"
        exit 498
    }
    // An estimated slope whose cluster-robust variance is zero (or not
    // available) has no standard error: inference is withheld.
    local noinf = (`ses' >= . | `ses' <= 0 | `dfr' >= . | `dfr' < 1)
    if `noinf' scalar `ses' = .

    tempname tt pp
    scalar `tt' = .
    scalar `pp' = .
    local crit = .
    local t0 = .
    local p0 = .
    if !`noinf' {
        scalar `tt' = (`bs' - 2) / `ses'
        scalar `pp' = 2 * ttail(`dfr', abs(`tt'))
        local crit = invttail(`dfr', (100 - `level') / 200)
        // the row of the table shows the test of slope 2 (from 1.1.1; it
        // showed the test of slope 0, which nobody asks for)
        local t0 = scalar(`tt')
        local p0 = scalar(`pp')
        // with weights that vary within panel, or panels of different
        // lengths, the slope can differ from 2 under the gamma model: the
        // slope, its std. err. and its interval are reported, the test is not
        if `wvary' | `unbal' {
            scalar `tt' = .
            scalar `pp' = .
            local t0 = .
            local p0 = .
        }
    }
    local Md : display %12.0fc `M'
    local Md = strtrim("`Md'")
    di ""
    di as text "Park test of the variance function (Park 1966)" ///
        _col(55) "Number of obs = " as result %9.0fc `N'
    di as text "OLS regression of ln(squared residual) on ln(fitted mean)"
    di as text "{ralign 78:(Std. err. adjusted for `Md' clusters in `cv')}"
    di as text "{hline 13}{c TT}{hline 64}"
    di as text "             {c |} Coefficient  Std. err.  t(b=2)   P>|t|     [`level'% conf. interval]"
    di as text "{hline 13}{c +}{hline 64}"
    di as text %12s "ln(mu)" " {c |}  " as result %9.0g `bs' "  " %9.0g `ses' " " ///
        %8.2f `t0' " " %7.3f `p0' "    " %9.0g (`bs' - `crit' * `ses') "   " %9.0g (`bs' + `crit' * `ses')
    di as text "{hline 13}{c BT}{hline 64}"
    // The test is of the slope of this auxiliary regression; 2 is its value
    // under independent gamma errors with one shape in balanced panels,
    // unweighted or with weights constant within panel, so it checks the
    // gamma model, not share centering (from 1.1.1 the label says so;
    // before, it read "variance proportional to the squared mean", which
    // lognormal errors with such a variance reject).
    di as text "Test of slope = 2 (regression of log squared residuals on log fitted means):"
    if `noinf' {
        di as text "      not reported"
        di as text "Note: the cluster-robust variance of the slope is zero or not available"
        di as text "      (`Md' cluster(s)), so no standard error, interval or test is reported."
    }
    // (the slope can differ from 2 there, even under the gamma model)
    else if `wvary' & !`unbal' {
        di as text "      not reported (the weights of the fit vary within panel)"
        di as text "Note: with weights that vary within panel the slope can differ from 2 even"
        di as text "      under the gamma model, so the slope and its std. err. are descriptive"
        di as text "      and no test is reported (see {help xtgamfe##park:help xtgamfe})."
    }
    else if `unbal' & !`wvary' {
        di as text "      not reported (the panels have different numbers of observations)"
        di as text "Note: with panels of different lengths the slope can differ from 2 even under"
        di as text "      the gamma model, so the slope and its std. err. are descriptive and no"
        di as text "      test is reported (see {help xtgamfe##park:help xtgamfe})."
    }
    else if `unbal' & `wvary' {
        di as text "      not reported (the weights of the fit vary within panel, and the panels"
        di as text "      have different numbers of observations)"
        di as text "Note: with weights that vary within panel or panels of different lengths"
        di as text "      the slope can differ from 2 even under the gamma model, so the slope and"
        di as text "      its std. err. are descriptive and no test is reported (see {help xtgamfe##park:help xtgamfe})."
    }
    else {
        di as text "      t(" as result `dfr' as text ") = " as result %8.2f `tt' ///
            as text "   P>|t| = " as result %6.4f `pp'
    }
    if `fwpan' {
        di as text "Note: each copy of a panel that a frequency weight stands for is a cluster,"
        di as text "      as in the fit."
    }
    if `nzero' > 0 {
        di as text "Note: `nzero' observation(s) with a residual of exactly zero left out."
    }
    if `wvary' | `unbal' {
        di as text "Note: the std. err. is that of this OLS regression, clustered as shown, which"
        di as text "      treats the fitted means and residuals as data."
    }
    else {
        // (the p-value is nominal)
        di as text "Note: t(b=2) and the test above are of slope = 2.  The std. err. is that of"
        di as text "      this OLS regression, clustered as shown, which treats the fitted means"
        di as text "      and residuals as data, so the p-value is nominal: its calibration"
        di as text "      depends on the design.  The slope is 2 under independent gamma errors"
        di as text "      with one shape in balanced panels, unweighted or with weights constant"
        di as text "      within panel, so the test checks the gamma model, not share centering,"
        di as text "      the condition of xtgamfe (see {help xtgamfe##park:help xtgamfe})."
    }

    return scalar slope = `bs'
    return scalar se = `ses'
    return scalar cons = `cs'
    return scalar t = `tt'
    return scalar p = `pp'
    return scalar df_r = `dfr'
    return scalar N = `N'
    return scalar N_clust = `M'
    return scalar N_zero = `nzero'
    return scalar level = `level'
    return local clustvar "`cv'"
end

// ---------------------------------------------------------------
// Was the first coefficient of the regression in e() (ln(fitted mean) in
// estat park) estimated?  r(omit) = 1 when regress omitted it.
// ---------------------------------------------------------------
program define _xtgamfe_park_id, rclass
    version 15.0
    tempname b
    matrix `b' = e(b)
    local cn : colnames `b'
    local c1 : word 1 of `cn'
    _ms_parse_parts `c1'
    return scalar omit = (r(omit) == 1)
end

capture mata: mata drop _xtgamfe_ape_cf()
capture mata: mata drop _xtgamfe_ape_d()
capture mata: mata drop _xtgamfe_ape_fd()
capture mata: mata drop _xtgamfe_ape_ok()
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

// Derivative of each term of TC with respect to continuous variable v.
real matrix _xtgamfe_ape_d(real matrix C, real matrix TC, real matrix UM, real scalar v)
{
    real matrix D
    real rowvector idx, isx, others
    real colvector xcol, col
    real scalar n, j, k, m

    n = rows(C)
    D = J(n, rows(TC), 0)
    for (j = 1; j <= rows(TC); j++) {
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
    return(D)
}

// Change of each term of TC when continuous variable v rises by dl: for a
// term x^m P (P the product of its other components),
// ((x + dl)^m - x^m) P = sum_k binomial(m, k) x^(m-k) dl^k P, which avoids
// the cancellation of the difference of the two designs.
real matrix _xtgamfe_ape_fd(real matrix C, real matrix TC, real matrix UM,
    real scalar v, real scalar dl)
{
    real matrix F
    real rowvector idx, isx, others
    real colvector xcol, col
    real scalar n, j, k, m, cb

    n = rows(C)
    F = J(n, rows(TC), 0)
    for (j = 1; j <= rows(TC); j++) {
        idx = select(TC[j, .], TC[j, .] :> 0)
        isx = (UM[idx, 1]' :== v) :& (UM[idx, 2]' :== 0)
        m = sum(isx)
        if (m > 0) {
            xcol = C[., select(idx, isx)[1]]
            col = J(n, 1, 0)
            cb = 1
            for (k = 1; k <= m; k++) {
                cb = cb * (m - k + 1) / k
                if (k < m) col = col + cb * dl^k * xcol:^(m - k)
                else       col = col :+ cb * dl^k
            }
            // a missing value of the variable stays missing
            col = col + 0 :* xcol
            if (m < cols(idx)) {
                others = select(idx, !isx)
                for (k = 1; k <= cols(others); k++) col = col :* C[., others[k]]
            }
            F[., j] = col
        }
    }
    return(F)
}

// Is the change Cm (one row per observation, one column per term of TCx)
// identified?  Each relation q (a row of Qr) requires Cm q = 0: exactly
// when its tolerance is zero (an empty cell or a term without within-panel
// variation), and otherwise to tau m sum_k |Cm_k| / s_k over the terms in
// q, where s_k is the within-panel root mean square of term k and
// m = max_k |q_k| s_k.
real scalar _xtgamfe_ape_ok(real matrix Cm, real matrix Qr, real rowvector sx,
    real matrix Qt)
{
    real scalar r
    real colvector sv, sc
    real rowvector inq

    for (r = 1; r <= rows(Qr); r++) {
        sv = Cm * Qr[r, .]'
        if (Qt[r, 1] == 0) {
            if (any(sv :!= 0)) return(0)
            continue
        }
        inq = (Qr[r, .] :!= 0) :& (sx :> 0)
        sc = Qt[r, 2] :* (abs(Cm) * (inq :/ (sx + !inq))')
        if (any(abs(sv) :> Qt[r, 1] :* sc)) return(0)
    }
    return(1)
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
//
// Finite change (TG[t, 2] = 3).  For continuous variable v raised by
// delta, f_it = mu_it (e1_it - 1) with e1_it = exp(h_it), h_it = c_it'b
// and c_it the change of the terms; for a regressor that enters linearly,
// theta = (exp(b_j delta) - 1) m, m the weighted mean fitted mean.
// e1 - 1 is evaluated as expm1(h) (_xtgamfe_expm1), without the
// cancellation of exp(h) - 1 for a small h, and J by the product rule,
// J = sum w mu [expm1(h) (x_it - xbar_i) + e1 c_it]' / sum(w), without the
// difference of two nearly equal cross products; for a linear regressor
// it is (exp(b_j delta) - 1) dm/db' + delta exp(b_j delta) m e_j' with
// dm/db' = sum w mu (x_it - xbar_i)' / sum(w).  As delta goes to zero,
// the effect and its standard error divided by delta tend to the
// derivative and its standard error.  With ybar, f_it = y_it expm1(h_it)
// and J = sum w y e1 c' / sum(w).
//
// A variable that is also the offset (TG[t, 5] = 1) moves the offset with
// it: the derivative gains 1, a finite change delta, and a factor level l
// the change l - offset_it in the index.  The offset does not depend on b,
// so J keeps its form.
//
// ybar (useY = 1, from 1.1.1).  The observed outcome y_it replaces the
// fitted mean: f_it = y_it d(x_it'b)/dx, or y_it [exp(x_it(l)'b - x_it'b)
// - exp(x_it(base)'b - x_it'b)].  Because E[y_it | X_i, alpha_i] = mu_it,
// these average to the same effects, and they involve the fixed effects
// and the period coefficients only through the coefficients that the
// change itself moves.  For a regressor that enters linearly theta is
// b_j times the weighted mean outcome; then J = ybar e_j'.  In general
// J = sum_it w_it y_it D_it / sum(w) for a continuous variable (D_it the
// derivative of the terms) and sum_it w_it y_it [e1_it (x_it(l) - x_it)
// - e0_it (x_it(base) - x_it)] / sum(w) for a factor level.  The
// clustering is that of the fitted-mean effects.
//
// Within-panel index.  When the terms of the index and the offset are
// large somewhere, sum_j |x_itj b_j| + |o_it| > 1024, the fitted
// quantities are computed from the design and offset minus their smallest
// values in each panel (exact differences of stored values); the profiled
// fixed effect absorbs the shift.  The bound is on the separate products,
// not on their sum, so that terms that are large but cancel (two
// regressors with large origins and opposite slopes) are centered too.
// Below that bound the uncentered computation is kept.
//
// Identification (from 1.1.1).  The data identify the coefficients only
// up to the relations stored by xtgamfe (a term omitted as collinear or
// without within-panel variation, or an empty cell, is tied to the others
// by x'q = constant within panels).  An effect is identified when the
// change it makes in the terms, for every observation, satisfies c'q = 0
// for every relation: for a factor level, the moves to the level and to
// the base; for a continuous variable, the derivative of the terms.  E
// returns 1 for an identified effect.  (Through 1.1.0 every variable in an
// omitted term was dropped, which reported a derivative for one copy of a
// duplicated regressor and suppressed identified contrasts when the
// omitted term depended on the choice of base.)
//
// ok returns 0 when a fitted mean that the effects use (not with ybar), an
// effect, or a variance is missing or outside the numeric range
// (quadsum() would otherwise skip the missing terms), or when an effect is
// nonzero and its variance is zero or below the smallest normal double
// (underflow; the effect then has no standard error that Stata can
// represent), or the effect itself is below it; and ybar the weighted mean
// outcome.  The covariance is formed from the influence functions scaled
// by an exact power of two when they are very small or very large, and
// scaled back, so that their squares and cross products neither underflow
// nor overflow where the variances themselves are representable; for
// influence functions of ordinary magnitude no scaling is applied.
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
    string scalar M_out,
    string scalar TCx_name,
    string scalar Qx_name,
    string scalar Qt_name,
    real   scalar has_rel,
    string scalar E_out,
    string scalar yo_name,
    string scalar of_name,
    real   scalar useY,
    string scalar ok_out,
    string scalar yb_out,
    string scalar OD_name,
    real   scalar has_od,
    string scalar OC_out,
    string scalar ZV_out)
{
    real colvector y, lny, pid, w, beta, xb, u, sh, e, S, lnmean, p, mu
    real colvector Tp, Wp, wfirst, cl, clp, d, f, e1, e0, col, xcol
    real colvector yo, of, oref
    real matrix Df
    real scalar ofl
    real matrix C, TC, UM, TG, X, Xp, dX, Z, H, Hinv, Gs, info, A, D, X1, X0, Sc, Vout
    real matrix TCx, Qx, Qr, XX, Qt, Xu, Xr, Xsh
    real rowvector s, theta, Jb, E, sx
    real scalar n, K, G, q, t, i, v, sw, th, M, isfw, nx, ctr, ok, ybar, sc2, tiny
    real colvector hd, em, xm
    real matrix As
    real rowvector xd
    real matrix Xf
    real matrix OD
    real rowvector OC, Jd
    real matrix Ab, Gsa, Sb
    real rowvector ZV

    y   = st_data(., ly_name,    touse_name)
    lny = st_data(., lny_name,   touse_name)
    C   = st_data(., tokens(uvars), touse_name)
    pid = st_data(., panid_name, touse_name)
    w   = st_data(., w_name,     touse_name)
    yo  = st_data(., yo_name,    touse_name)
    of  = st_data(., of_name,    touse_name)
    TC  = st_matrix(TC_name)
    UM  = st_matrix(UM_name)
    TG  = st_matrix(TG_name)
    beta = st_matrix(b_name)'
    isfw = (wtype == "fweight")

    n = rows(y)
    // pweights and iweights are scaled to mean one, as in the fit (first
    // by the exact power of two that brings the largest to [1, 2), so that
    // their total cannot overflow): the effects, their variances and ybar
    // then do not depend on the scale of such weights, and no intermediate
    // sum overflows or underflows because of it.  fweights keep their
    // counts.
    if (wtype == "pweight" | wtype == "iweight") {
        w = w :* _xtgamfe_w2_e(max(w))
        w = w :* (n / quadsum(w))
    }
    K = rows(TC)
    q = rows(TG)
    info = panelsetup(pid, 1)
    G = rows(info)
    Tp = info[., 2] - info[., 1] :+ 1
    Wp = panelsum(w, info)
    wfirst = w[info[., 1]]
    sw = quadsum(w)
    ybar = quadsum(w :* yo) / sw

    if (clid_name != "") {
        cl  = st_data(., clid_name, touse_name)
        clp = cl[info[., 1]]
    }

    // fitted quantities at the estimates
    Xu = _xtgamfe_ape_cf(C, TC, UM, 0, 0)
    X  = Xu
    xb = X * beta
    xm = abs(of)
    for (i = 1; i <= K; i++) xm = xm + abs(X[., i] * beta[i])
    ctr = (max(xm) > 1024)
    // The design is also centered when a term is large next to its
    // variation within panels, whatever its coefficient (from 1.1.1): the
    // Hessian, the coefficient scores and the derivative of the fitted
    // means use the within-panel deviations of the terms, which lose their
    // digits when formed from values with a large origin (an exact change
    // of origin, as z = 2^52 + x, changed the variance of an effect at a
    // zero slope).  The ratio of a term's largest absolute value to its
    // largest deviation from the first value of a panel is compared with
    // 1024; the deviations are exact differences of stored values.
    if (!ctr) {
        Xf = Xu[info[., 1], .]
        xd = colmax(abs(Xu - Xf[pid, .]))
        ctr = any(colmax(abs(Xu)) :> 1024 :* xd)
    }
    Xsh = 0
    if (ctr) {
        Xr = J(G, K, .)
        oref = J(G, 1, .)
        for (i = 1; i <= G; i++) {
            Xr[i, .] = colmin(Xu[|info[i, 1], 1 \ info[i, 2], .|])
            oref[i] = min(of[|info[i, 1] \ info[i, 2]|])
        }
        Xsh = Xr[pid, .]
        X  = Xu - Xsh
        xb = X * beta
        y  = lny - (of - oref[pid])
    }
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
    // with ybar the effects do not use the fitted means
    ok = (useY | !hasmissing(mu))

    Xp = panelsum(X, p, info)
    dX = X - Xp[pid, .]
    s  = sqrt(quadcolsum(dX:^2) / n)
    Z  = dX :/ s
    H  = cross(Z, Wp[pid] :* p, Z)
    H  = (H + H') / 2
    Hinv = invsym(H)
    Gs = panelsum(X, w - Wp[pid] :* p, info) :/ s
    // the sums of the absolute values from which the scores are formed (for
    // the test of zero variation below)
    Gsa = panelsum(abs(X), w + Wp[pid] :* p, info) :/ s

    theta = J(1, q, .)
    A = J(G, q, .)
    Ab = J(G, q, .)
    // OC: 1 for an effect whose direct derivative (Jd, the part of J that
    // comes from the change the effect describes, not from the fitted
    // means) has a part along a direction of the coefficients that rests on
    // one cluster (a row of OD): |Jd v| above 1e-6 sum_j |Jd_j v_j|
    OC = J(1, q, 0)
    if (has_od) OD = st_matrix(OD_name)
    for (t = 1; t <= q; t++) {
        v = TG[t, 1]
        // ofl: variable v is also the offset, whose coefficient is one
        ofl = TG[t, 5]
        if (TG[t, 2] == 1) {
            // derivative of each estimated term with respect to variable v
            D  = _xtgamfe_ape_d(C, TC, UM, v)
            d  = D * beta
            if (ofl) d = d :+ 1
            if (useY) {
                f  = yo :* d
                th = quadsum(w :* f) / sw
                Jb = quadcross(D, w :* yo)' / sw
                if (has_od) Jd = Jb
            }
            else {
                f  = mu :* d
                th = quadsum(w :* f) / sw
                Jb = (quadcross(dX, w :* f) + quadcross(D, w :* mu))' / sw
                if (has_od) Jd = quadcross(D, w :* mu)' / sw
            }
        }
        else if (TG[t, 2] == 3) {
            // finite change: v rises by TG[t, 3]; Df is the change of each
            // term (exact for a term in which v enters linearly), and
            // e1 - 1 the relative change of the mean
            Df = _xtgamfe_ape_fd(C, TC, UM, v, TG[t, 3])
            if (ofl) hd = Df * beta :+ TG[t, 3]
            else     hd = Df * beta
            e1 = exp(hd)
            em = _xtgamfe_expm1(hd)
            if (useY) {
                f  = yo :* em
                th = quadsum(w :* f) / sw
                Jb = quadcross(Df, w :* yo :* e1)' / sw
                if (has_od) Jd = Jb
            }
            else {
                f  = mu :* em
                th = quadsum(w :* f) / sw
                Jb = (quadcross(dX, w :* f) + quadcross(Df, w :* mu :* e1))' / sw
                if (has_od) Jd = quadcross(Df, w :* mu :* e1)' / sw
            }
        }
        else {
            X1 = _xtgamfe_ape_cf(C, TC, UM, v, TG[t, 3])
            X0 = _xtgamfe_ape_cf(C, TC, UM, v, TG[t, 4])
            // a factor variable that is also the offset: the offset moves
            // from its value to the level
            if (ofl) {
                e1 = exp((X1 - Xu) * beta + (TG[t, 3] :- of))
                e0 = exp((X0 - Xu) * beta + (TG[t, 4] :- of))
            }
            else {
                e1 = exp((X1 - Xu) * beta)
                e0 = exp((X0 - Xu) * beta)
            }
            if (useY) {
                f  = yo :* (e1 - e0)
                th = quadsum(w :* f) / sw
                Jb = (quadcross(X1 - Xu, w :* yo :* e1) -
                      quadcross(X0 - Xu, w :* yo :* e0))' / sw
                if (has_od) Jd = Jb
            }
            else {
                f  = mu :* (e1 - e0)
                th = quadsum(w :* f) / sw
                Jb = (quadcross((X1 :- Xsh) - Xp[pid, .], w :* mu :* e1) -
                      quadcross((X0 :- Xsh) - Xp[pid, .], w :* mu :* e0))' / sw
                if (has_od) Jd = (quadcross(X1 - Xu, w :* mu :* e1) -
                                  quadcross(X0 - Xu, w :* mu :* e0))' / sw
            }
        }
        if (has_od) {
            for (i = 1; i <= rows(OD); i++) {
                if (abs(Jd * OD[i, .]') > 1e-6 * (abs(Jd) * abs(OD[i, .])')) OC[t] = 1
            }
        }
        if (hasmissing(f) | hasmissing(Jb)) ok = 0
        theta[t] = th
        A[., t] = panelsum(w :* (f :- th), info) / sw - Gs * (Hinv * (Jb :/ s)')
        // a bound on the magnitudes that A[., t] is formed from, panel by
        // panel
        Ab[., t] = panelsum(w :* (abs(f) :+ abs(th)), info) / sw + Gsa * (abs(Hinv) * abs(Jb :/ s)')
    }

    // an exact power of two that brings very small or very large influence
    // functions to order one (1 otherwise; see above)
    sc2 = _xtgamfe_p2scale(A)
    As = A :* sc2
    if (clid_name == "") {
        if (isfw) {
            M = quadsum(wfirst)
            Vout = (M / (M - 1)) * cross(As :/ sqrt(wfirst), As :/ sqrt(wfirst))
        }
        else {
            M = G
            Vout = (M / (M - 1)) * cross(As, As)
        }
    }
    else {
        Sc = _xtgamfe_ape_csum(As, clp, M)
        Vout = (M / (M - 1)) * cross(Sc, Sc)
    }
    if (sc2 != 1) Vout = (Vout :/ sc2) :/ sc2
    Vout = (Vout + Vout') / 2
    if (hasmissing(theta) | hasmissing(A) | hasmissing(Vout)) ok = 0

    // identification of each effect
    E = J(1, q, 1)
    if (has_rel) {
        TCx  = st_matrix(TCx_name)
        Qx   = st_matrix(Qx_name)
        Qt   = st_matrix(Qt_name)
        nx   = rows(TCx)
        Qr   = Qx[1..(rows(Qx) - 1), .]
        sx   = Qx[rows(Qx), .]
        XX   = _xtgamfe_ape_cf(C, TCx, UM, 0, 0)
        for (t = 1; t <= q; t++) {
            v = TG[t, 1]
            if (TG[t, 2] == 1) E[t] = _xtgamfe_ape_ok(_xtgamfe_ape_d(C, TCx, UM, v), Qr, sx, Qt)
            else if (TG[t, 2] == 3) E[t] = _xtgamfe_ape_ok(_xtgamfe_ape_fd(C, TCx, UM, v, TG[t, 3]), Qr, sx, Qt)
            else {
                E[t] = _xtgamfe_ape_ok(_xtgamfe_ape_cf(C, TCx, UM, v, TG[t, 3]) - XX, Qr, sx, Qt)
                if (E[t]) E[t] = _xtgamfe_ape_ok(_xtgamfe_ape_cf(C, TCx, UM, v, TG[t, 4]) - XX, Qr, sx, Qt)
            }
        }
    }

    // Zero variation: ZV[t] = 1 when the contributions of
    // the clusters to the influence function of effect t are equal, to
    // rounding.  They sum to zero, so they are then all zero, and the
    // variance is zero in exact arithmetic (as with identical panels, each
    // with the same outcomes and regressors): what was computed is rounding
    // error, which gave a standard error of 4e-17 and z = 5e16, or a zero
    // variance that the underflow check below took for an underflow.  The
    // test: the largest absolute cluster contribution is at most 1e-10 times
    // the largest cluster sum of the absolute values from which the
    // contributions are formed (Ab); rounding leaves a relative error of
    // the order of the number of terms summed times 2.2e-16, far below that
    // bound, and contributions that genuinely differ differ far above it.
    // The effect is reported; its standard error is not (the display).
    if (clid_name == "") Sb = Ab
    else                 Sb = _xtgamfe_ape_csum(Ab, clp, M)
    if (clid_name == "") Sc = A
    else                 Sc = _xtgamfe_ape_csum(A, clp, M)
    ZV = J(1, q, 0)
    for (t = 1; t <= q; t++) {
        if (hasmissing(Sc[., t]) | hasmissing(Sb[., t])) continue
        if (max(abs(Sc[., t])) <= 1e-10 * max(abs(Sb[., t]))) ZV[t] = 1
    }

    // underflow, for the effects that are reported: a nonzero effect whose
    // variance is zero or below the smallest normal double, or an effect
    // below it (an effect whose variance is zero by the test above is not
    // an underflow)
    tiny = _xtgamfe_minnorm()
    for (t = 1; t <= q; t++) {
        if (!E[t]) continue
        if (theta[t] != 0 & theta[t] < . & Vout[t, t] < tiny & !ZV[t]) ok = 0
        if (theta[t] != 0 & abs(theta[t]) < tiny) ok = 0
    }

    st_matrix(b_out, theta)
    st_matrix(V_out, Vout)
    st_numscalar(M_out, M)
    st_matrix(E_out, E)
    st_numscalar(ok_out, ok)
    st_numscalar(yb_out, ybar)
    st_matrix(OC_out, OC)
    st_matrix(ZV_out, ZV)
}
end

capture mata: mata drop _xtgamfe_ape_csum()
capture mata: mata drop _xtgamfe_rh_e()
capture mata: mata drop _xtgamfe_fep_wald()
capture mata: mata drop _xtgamfe_expm1()
capture mata: mata drop _xtgamfe_p2scale()
capture mata: mata drop _xtgamfe_minnorm()
capture mata: mata drop _xtgamfe_park_fw()
capture mata: mata drop _xtgamfe_w2_e()
mata:
// Copy of _xtgamfe_w2 in xtgamfe.ado: the exact power of two s for which
// m s lies in [1, 2), for a positive finite m (1 otherwise).
real scalar _xtgamfe_w2_e(real scalar m)
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

// Copy of _xtgamfe_rh in xtgamfe.ado (keep identical).
string scalar _xtgamfe_rh_e(string scalar nvars, string scalar svars, string scalar es)
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

// Wald statistic d V^-1 d' of the differences of estat fepoisson, on the
// correlation scale, and the rank of V.  The rank is the number of
// eigenvalues of the correlation matrix above 1e-12 times the largest,
// which does not depend on the order of the differences, and at most
// nrep - 1 for a covariance from nrep replications.  The statistic is
// computed only when V has full rank (and is missing otherwise, or when V
// has missing values or a zero variance), so it never rests on a
// generalized inverse.
void _xtgamfe_fep_wald(string scalar dn, string scalar vn, real scalar nrep,
    string scalar cn, string scalar rn)
{
    real rowvector d, sd
    real matrix V, R, Ri
    real colvector ev
    real scalar k, rk, w

    d = st_matrix(dn)
    V = st_matrix(vn)
    k = cols(d)
    w = .
    rk = 0
    if (!hasmissing(V) & !hasmissing(d)) {
        sd = sqrt(diagonal(V))'
        if (min(sd) > 0) {
            R = V :/ (sd' * sd)
            R = (R + R') / 2
            ev = symeigenvalues(R)'
            rk = sum(ev :> 1e-12 * max(ev))
            if (nrep < .) rk = min((rk, nrep - 1))
            if (rk == k) {
                Ri = invsym(R)
                if (diag0cnt(Ri) == 0) w = (d :/ sd) * Ri * (d :/ sd)'
            }
        }
    }
    st_numscalar(cn, w)
    st_numscalar(rn, rk)
}

// exp(h) - 1 without cancellation for a small h (Mata in Stata 15 has no
// expm1()): with u = exp(h), (u - 1) h / ln(u) is accurate to a few units
// in the last place for |h| < 1 (a formula due to W. Kahan); h itself
// when u rounds to 1; u - 1 for |h| >= 1, where it is accurate.
// A missing h gives a missing value.
real colvector _xtgamfe_expm1(real colvector h)
{
    real colvector u, r, idx
    real scalar i, j

    u = exp(h)
    r = u :- 1
    idx = selectindex(abs(h) :< 1)
    for (j = 1; j <= rows(idx); j++) {
        i = idx[j]
        if (u[i] == 1) r[i] = h[i]
        else           r[i] = (u[i] - 1) * h[i] / ln(u[i])
    }
    return(r)
}

// An exact power of two s such that max|A| s is of order one when max|A|
// is below 2^-200 or above 2^200, and 1 otherwise (and for a zero or
// missing maximum).  Built by repeated halving or doubling, which is exact;
// at most 2^1000 either way.
real scalar _xtgamfe_p2scale(real matrix A)
{
    real scalar m, s, lo, hi, i

    m = max(abs(A))
    if (m >= . | m <= 0) return(1)
    lo = 1
    hi = 1
    for (i = 1; i <= 200; i++) {
        lo = lo / 2
        hi = hi * 2
    }
    if (m >= lo & m <= hi) return(1)
    s = 1
    i = 0
    if (m < lo) {
        while (m * s < .5 & i < 1000) {
            s = s * 2
            i++
        }
    }
    else {
        while (m * s > 2 & i < 1000) {
            s = s / 2
            i++
        }
    }
    return(s)
}

// The smallest normal double, 2^-1022, built by exact halving (2^-1022
// written as a power is not exact in Mata).
real scalar _xtgamfe_minnorm()
{
    real scalar x, i

    x = 1
    for (i = 1; i <= 1022; i++) x = x / 2
    return(x)
}

// estat park with frequency weights, clustered on panels: the clustered
// covariance of the data expanded with each copy of a panel its own
// cluster.  The regression sample (rs) is sorted by the panel variable.
// With X = (ln mu, 1), residuals e at the coefficients b, u_i the score of
// one copy of panel i (sum over its rows of x e), k_i its frequency weight
// (constant within the panel), N = sum of the weights and M = sum_i k_i:
//     V = (X'WX)^-1 (sum_i k_i u_i u_i') (X'WX)^-1 (N-1)/(N-2) M/(M-1),
// the variance regress reports with vce(cluster) on the expanded data.
// Returns (standard error of the slope, M, N).
void _xtgamfe_park_fw(string scalar yn, string scalar xn, string scalar wn,
    string scalar pn, string scalar rs, real rowvector b, string scalar out)
{
    real colvector y, x, w, pid, e, k
    real matrix X, info, U, XWXi, B, V
    real scalar N, M

    y   = st_data(., yn, rs)
    x   = st_data(., xn, rs)
    w   = st_data(., wn, rs)
    pid = st_data(., pn, rs)
    X = (x, J(rows(x), 1, 1))
    e = y - X * b'
    info = panelsetup(pid, 1)
    U = panelsum(X :* e, info)
    k = w[info[., 1]]
    XWXi = invsym(cross(X, w, X))
    B = cross(U, k, U)
    N = quadsum(w)
    M = quadsum(k)
    V = XWXi * B * XWXi * ((N - 1) / (N - 2)) * (M / (M - 1))
    st_matrix(out, (sqrt(V[1, 1]), M, N))
}

// Sums of the rows of Z within groups defined by the integer vector id;
// n returns the number of groups.  Rows of one group are added in their
// order in Z (a stable order: order() alone breaks ties with the sort
// seed).
real matrix _xtgamfe_ape_csum(real matrix Z, real colvector id, real scalar n)
{
    real colvector o
    real matrix cinfo

    o = order((id, (1::rows(id))), (1, 2))
    cinfo = panelsetup(id[o], 1)
    n = rows(cinfo)
    return(panelsum(Z[o, .], cinfo))
}
end
