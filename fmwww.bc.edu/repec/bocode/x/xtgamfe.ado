*! xtgamfe 1.1.1  2026-11-21
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
*   robust, cluster(clustvar)   synonyms of vce(robust), vce(cluster clustvar)
*   small                t and F statistics with M-1 degrees of freedom
*                        (M clusters) for the cluster-robust variance
*   offset(varname)      log-scale offset: log mu = alpha_i + x'b + offset
*   tolerance(#)         Newton-decrement convergence tolerance (default 1e-6)
*   iterate(#)           maximum Newton iterations (default 1000)
*   nolog                suppress the iteration log
*   from(matname)        starting values for beta: a vector with the column
*                        names of the terms (such as e(b) from the same
*                        specification), or 1 x K (K x 1) in term order
*   nofe                 do not post e(fe) and e(fe_id)
*   level(#)             confidence level for the coefficient table
*   eform                report exponentiated coefficients
*   display options      as for official estimation commands
program define xtgamfe, eclass sortpreserve
    version 15.0

    // One replication of estat fepoisson, run by the bootstrap prefix as
    // xtgamfe _fepb ... while estat fepoisson runs (it sets the global), so
    // that the prefix names xtgamfe when it starts; see xtgamfe_estat.ado.
    if "$XTGAMFE_FEPB" == "1" & strpos("`c(prefix)'", "bootstrap") {
        gettoken fepb0 fepb1 : 0
        if "`fepb0'" == "_fepb" {
            xtgamfe_estat _fepb `fepb1'
            exit
        }
    }

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
    // The two globals below carry a weight expression to the display while
    // a resampling run is under way (see below).  A run that was broken off
    // can leave them behind; a call that is not itself inside a prefix
    // clears them.
    if "`c(prefix)'" == "" {
        global XTGAMFE_WFZ_NAME
        global XTGAMFE_WFZ_SHOW
    }
    local resamp = 0
    if !replay() {
        // A time-series operator in the weight expression is refused first,
        // from the text as typed: syntax and the prefix machinery evaluate
        // the expression, which with the data not in panel order would stop
        // with "not sorted".  An operator is recognized by its syntax, the
        // operator letters (and lags) followed by a dot, as in L., F2.,
        // LD. or L(1/2).; a function such as F() is not an operator.
        if regexm(`"`zero_typed'"', "\[ *(fw|fweight|pw|pweight|iw|iweight|aw|aweight|weight) *= *([^]]*)\]") {
            local wtx = regexs(2)
            if regexm(`" `wtx'"', "[^A-Za-z0-9_][LFDSlfds][LFDSlfds0-9]*([(][^()]*[)])?[.]") {
                _xtgamfe_newname w
                di as error "time-series operators are not allowed in the weight expression"
                di as error "generate the weight variable first, for example:  generate double `r(name)' = L.w"
                exit 198
            }
        }
        capture syntax anything [if] [in] [fweight iweight pweight] ///
            [, VCE(string) SAMPLEMARK(string) *]
        // nofe, for the command line stored after resampling (below)
        local nofe_typed = 0
        if _rc == 0 local nofe_typed = regexm(`" `options' "', "[ ,]nofe[ ,]")
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
            di as error "option samplemark() not allowed"
            exit 198
        }
        // vce(bootstrap) and vce(jackknife) resample panels; clusters that
        // nest the panels are resampled by the prefix commands
        if `resamp' & regexm(`" `vce'"', "[ ,]cl(u|us|ust|uste|uster)?[(]") {
            di as error "vce(bootstrap) and vce(jackknife) resample or delete whole panels and take"
            di as error "no cluster() suboption; to resample or delete clusters that nest the"
            di as error "panels, use the prefix commands:"
            di as error "    jackknife, cluster(clustvar): xtgamfe ..."
            di as error "    bootstrap, cluster(clustvar) idcluster(newvar) group(panelvar): xtgamfe ..."
            di as error "(see help xtgamfe, option vce(), for how to set up the bootstrap prefix)"
            exit 198
        }
        // robust and cluster() are synonyms of vce(robust) and
        // vce(cluster clustvar); they cannot be combined with vce()
        if `"`vce'"' != "" & (regexm(`" `options' "', "[ ,]r(o|ob|obu|obus|obust)?[ ,]") | ///
            regexm(`" `options'"', "[ ,]cl(u|us|ust|uste|uster)?[(]")) {
            di as error "options vce() and robust or cluster() may not be combined"
            exit 198
        }
        // small with resampling: vce(jackknife) already reports t
        // statistics with M-1 degrees of freedom, so small changes nothing
        // there; the bootstrap reports normal-based intervals, and small
        // is not allowed with it.
        if `resamp' & _rc == 0 {
            local isboot0 = (strpos("bootstrap", "`vh'") == 1) | (strpos("bstrap", "`vh'") == 1)
            if `isboot0' & regexm(`" `options' "', "[ ,]small[ ,]") {
                di as error "option small is not allowed with vce(bootstrap); the bootstrap"
                di as error "reports normal-based intervals.  With few clusters use vce(robust)"
                di as error "or vce(cluster clustvar) with small, or vce(jackknife), whose t"
                di as error "statistics use M-1 degrees of freedom"
                exit 198
            }
        }
        // A weight expression must give the same value for each row in any
        // row order (section 3).  Check it here, in the caller's order,
        // before the prefix reorders the data.
        //
        // From 1.1.1 the realized values of a weight expression (anything
        // but a plain variable name) are also frozen here, in the caller's
        // order, into a variable that the replications use by name, so that
        // no replication evaluates the expression again on reordered or
        // reduced data; e(wexp) and e(command) are given back the expression
        // afterwards.  A finite set of reorderings cannot prove that an
        // expression does not depend on the order of the rows.
        local wfz_name ""
        local wexp_typed ""
        if `resamp' & "`weight'" != "" {
            tempvar wck_if
            mark `wck_if' `if' `in'
            _xtgamfe_wcheck `"`exp'"' `wck_if'
            local wname0 = strtrim(substr(strtrim(`"`exp'"'), 2, .))
            capture confirm numeric variable `wname0', exact
            if _rc | `: word count `wname0'' != 1 {
                tempvar wfz
                quietly generate double `wfz' `exp'
                local wfz_name "`wfz'"
                local wexp_typed `"`exp'"'
            }
        }
        if `resamp' & (`"`if'`in'"' != "" | "`wfz_name'" != "") {
            local wt ""
            if "`weight'" != "" {
                if "`wfz_name'" != "" local wt "[`weight'=`wfz_name']"
                else                  local wt "[`weight'`exp']"
            }
            if `"`if'`in'"' != "" {
                local isboot = (strpos("bootstrap", "`vh'") == 1) | (strpos("bstrap", "`vh'") == 1)
                local ts_text = regexm(`" `anything'"', "[^A-Za-z0-9_][LFDSlfds][LFDSlfds0-9]*([(][^()]*[)])?[.]")
                tempvar premark
                mark `premark' `if' `in'
                if `isboot' & `ts_text' {
                    local 0 `"`anything' `wt', vce(`vce') samplemark(`premark') `options'"'
                    // the marker that the replications may pass as samplemark()
                    global XTGAMFE_SMARK "`premark'"
                    local smset = 1
                }
                else local 0 `"`anything' if `premark' `wt', vce(`vce') `options'"'
            }
            else local 0 `"`anything' `wt', vce(`vce') `options'"'
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
    // The prefix displays the results before this program can give e(wexp)
    // back the expression; the display shows the expression meanwhile.
    if "`wfz_name'" != "" {
        global XTGAMFE_WFZ_NAME "`wfz_name'"
        global XTGAMFE_WFZ_SHOW `"`wexp_typed'"'
    }
    capture noisily _vce_parserun xtgamfe, panel jkopts(eclass) noeqlist: `0'
    local vrc = _rc
    if "`wfz_name'" != "" {
        global XTGAMFE_WFZ_NAME
        global XTGAMFE_WFZ_SHOW
    }
    if "`smset'" == "1" global XTGAMFE_SMARK
    if `vrc' exit `vrc'
    if "`s(exit)'" != "" {
        if `resamp' _estimates drop `ehold'
        // e(command), the command the replications ran, names the marker
        // of an if or in qualifier (as "if marker" or as samplemark()) and
        // the variable of frozen weights; it is given back the qualifier and
        // the expression as typed.
        local cmdr `"`e(command)'"'
        if "`premark'" != "" {
            local ifin = strtrim(`"`if' `in'"')
            local cmdr : subinstr local cmdr "if (`premark' )" `"`ifin'"'
            local cmdr : subinstr local cmdr "if (`premark')" `"`ifin'"'
            local cmdr : subinstr local cmdr "if `premark'" `"`ifin'"'
            if strpos(`"`cmdr'"', "samplemark(`premark')") {
                local cmdr : subinstr local cmdr " samplemark(`premark')" ""
                local cmdr : subinstr local cmdr "samplemark(`premark')" ""
                local cpos = strpos(`"`cmdr'"', ",")
                if `cpos' > 0 {
                    local c1 = substr(`"`cmdr'"', 1, `cpos' - 1)
                    local c2 = substr(`"`cmdr'"', `cpos', .)
                    local cmdr `"`c1' `ifin'`c2'"'
                }
                else local cmdr `"`cmdr' `ifin'"'
            }
            local cmdr = strtrim(`"`cmdr'"')
        }
        if "`wfz_name'" != "" {
            // the replications used the frozen values; report the expression
            local wbody = strtrim(substr(strtrim(`"`wexp_typed'"'), 2, .))
            local cmdr : subinstr local cmdr "`wfz_name'" `"`wbody'"', all
        }
        if "`premark'`wfz_name'" != "" ereturn local command `"`cmdr'"'
        if "`wfz_name'" != "" {
            ereturn local wexp `"`wexp_typed'"'
            // The full-sample fit received the weights as a temporary
            // variable: Stata's data signature leaves them out
            // (e(xtg_wds) = 0), and the row hash e(xtg_wsig) signs the
            // frozen values with the other estimation inputs of each row
            // (section 15); it is taken again here from the frozen values.
            _xtgamfe_rsig `"`e(xtg_rkeys)' `wfz_name'"' `"`e(panvar)'"' `"`e(timevar)'"'
            capture ereturn hidden local xtg_wsig `"`r(sig)'"'
        }
        // With nofe, the command line, and the command that the
        // replications ran, are stored without the if and in qualifier and
        // without a weight expression (section 15).
        local cmdl `"xtgamfe `zero_typed'"'
        if "`nofe_typed'" == "1" {
            _xtgamfe_nofecl `"`zero_typed'"'
            if "`r(what)'" != "" {
                local cmdl `"xtgamfe `r(cl)'"'
                local what "`r(what)'"
                local cmdr `"`e(command)'"'
                if substr(`"`cmdr'"', 1, 8) == "xtgamfe " {
                    _xtgamfe_nofecl `"`=substr(`"`cmdr'"', 9, .)'"'
                    ereturn local command `"xtgamfe `r(cl)'"'
                }
                _xtgamfe_nofenote `"`what'"' "e(cmdline) and e(command) are"
            }
        }
        ereturn local cmdline `"`cmdl'"'
        // A term that varies within only one panel (e(xtg_onecl) of the
        // full-sample fit, whose clusters are the panels; section 14): the
        // prefix's test of all coefficients includes it and is not kept, as
        // the display did not show it.
        if `"`e(xtg_onecl)'`e(xtg_ocdterms)'"' != "" {
            foreach sc in chi2 F p {
                if e(`sc') < . ereturn scalar `sc' = .
            }
        }
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
           SMALL                                         ///
           NOFE                                          ///
           Robust                                        ///
           CLuster(string)                               ///
           SAMPLEMARK(varname numeric)                   ///
           *                                             ///
        ]
    // samplemark() is set only by xtgamfe itself, for vce(bootstrap) with
    // an if or in qualifier and time-series operators (section 1)
    if "`samplemark'" != "" & "`samplemark'" != "$XTGAMFE_SMARK" {
        di as error "option samplemark() not allowed"
        exit 198
    }
    // An iterate() or tolerance() that is not a number is left by syntax
    // among the other options; say what is wrong with it.
    if regexm(`" `options'"', "[ ,]iter(a|at|ate)?[(]") {
        di as error "option iterate() incorrectly specified: iterate() takes an integer of at least 1"
        exit 198
    }
    if regexm(`" `options'"', "[ ,]tol(e|er|era|eran|eranc|erance)?[(]") {
        di as error "option tolerance() incorrectly specified: tolerance() takes a strictly positive number"
        exit 198
    }
    // The fixed effects are always estimated: there is no option fe (nofe
    // keeps e(fe) and e(fe_id) from being stored).
    if regexm(`" `options' "', "[ ,]fe[ ,]") {
        di as error "option fe not allowed: the fixed effects are always estimated; option"
        di as error "nofe keeps them from being stored in e(fe) and e(fe_id)"
        exit 198
    }
    _get_diopts diopts, `options'

    if missing(`tolerance') | `tolerance' <= 0 {
        di as error "tolerance() must be strictly positive"
        exit 198
    }
    if missing(`iterate') | `iterate' < 1 {
        di as error "iterate() must be at least 1"
        exit 198
    }
    // robust and cluster() as synonyms of vce(robust) and
    // vce(cluster clustvar), as official commands accept them
    if "`robust'" != "" | `"`cluster'"' != "" {
        if `"`vce'"' != "" {
            di as error "options vce() and robust or cluster() may not be combined"
            exit 198
        }
        if `"`cluster'"' != "" local vce `"cluster `cluster'"'
        else                   local vce "robust"
    }

    // ----------------------------------------------------------------
    // 3. if, in, and weights select observations now, in the caller's
    //    observation order.  (Through 1.0.0 the sample was marked after
    //    xtset had sorted the data, so an in range picked other rows.)
    // ----------------------------------------------------------------
    if regexm(`" `exp'"', "[^A-Za-z0-9_][LFDSlfds][LFDSlfds0-9]*([(][^()]*[)])?[.]") {
        _xtgamfe_newname w
        di as error "time-series operators are not allowed in the weight expression"
        di as error "generate the weight variable first, for example:  generate double `r(name)' = L.w"
        exit 198
    }
    tempvar touse0 ifin0 wfrozen
    // the if and in selection alone, used below to see whether it splits
    // a panel
    mark `ifin0' `if' `in'
    // The weights are evaluated once, here, in the caller's order, and these
    // values are used for the selection and the estimation.  (Through 1.1.0
    // the expression was evaluated again after the data were sorted, so an
    // expression in _n selected other rows.)  predict, estat ape, and the
    // data signature evaluate e(wexp) again later, so an expression whose
    // values depend on the row order is refused.
    //
    // From 1.1.1 the realized values of a weight expression are also
    // checked whenever they are evaluated again: a hash of the values on
    // the estimation sample, keyed by panel and time, is stored (section
    // 15), and predict and estat ape refuse to use values that differ.
    // (The jackknife prefix itself evaluates a weight expression once,
    // before its replications, and the bootstrap prefix does not allow
    // weights.)
    local wexpr = 0
    if "`weight'" != "" {
        local wname0 = strtrim(substr(strtrim(`"`exp'"'), 2, .))
        capture confirm numeric variable `wname0', exact
        if _rc | `: word count `wname0'' != 1 local wexpr = 1
        _xtgamfe_wcheck `"`exp'"' `ifin0'
        quietly generate double `wfrozen' `exp'
        mark `touse0' `if' `in' [`weight'=`wfrozen']
    }
    else mark `touse0' `if' `in'
    // samplemark() is set only by xtgamfe itself, for vce(bootstrap)
    if "`samplemark'" != "" quietly replace `touse0' = 0 if `samplemark' == 0
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
    local small_o  "`small'"
    local fe_o     "`nofe'"
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
    local tdelta = r(tdelta)
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
        if `: word count `vrest'' != 1 {
            di as error "vce(cluster `vrest'): specify one cluster variable"
            exit 198
        }
        local vtyped "`vrest'"
        capture unab vrest : `vrest', max(1)
        if _rc {
            di as error "vce(cluster `vtyped'): variable `vtyped' not found or ambiguous"
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
        if "`small_o'" != "" {
            di as error "option small is not allowed with vce(oim); it gives t and F statistics"
            di as error "with M-1 degrees of freedom for the cluster-robust variance"
            di as error "(vce(robust) or vce(cluster clustvar))"
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
        quietly generate double `wv' = `wfrozen' if `touse'
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

    quietly count if `touse'
    if r(N) == 0 error 2000

    // Numeric cluster identifier (egen may reorder the data; the panel
    // order is restored immediately below).  Rows that tie on the panel and
    // time variables (missing time values, or no time variable) keep the
    // caller's order, so that no sum depends on how Stata breaks ties.
    tempvar clid
    if `nested_cluster' {
        quietly egen long `clid' = group(`clustvar') if `touse'
    }
    sort `panvar' `timevar' `original_order'

    // ----------------------------------------------------------------
    // 8. Drop singleton panels, then enforce positivity on the retained
    //    slope-estimation sample.  A nonpositive singleton cannot affect beta.
    // ----------------------------------------------------------------
    tempvar Ti
    quietly by `panvar': generate long `Ti' = sum(`touse')
    quietly by `panvar': replace `Ti' = `Ti'[_N]

    // With frequency weights the count is of the observations they stand
    // for, as e(N) is.
    local n_sing = 0
    quietly count if `touse' & `Ti' == 1
    if r(N) > 0 {
        local n_sing = r(N)
        if "`wtype'" == "fweight" {
            quietly summarize `wv' if `touse' & `Ti' == 1, meanonly
            local n_sing = r(sum)
        }
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
        di as error "xtgamfe requires strictly positive outcomes in nonsingleton panels;"
        di as error "to fit the model to the positive outcomes, add  if `depvar' > 0  (this"
        di as error "changes what is estimated: the mean among positive outcomes, given the"
        di as error "regressors and the panel, and panels left with one observation drop out)"
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
        sort `panvar' `timevar' `original_order'
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
    // Nor may it enter a term (an interaction or a factor variable).  With a
    // time-series operator (a lag, lead or difference of the outcome) it is
    // accepted with a note: strict exogeneity then fails by construction.
    local ydep_ts ""
    foreach term of local rhs_expanded {
        local components : subinstr local term "#" " ", all
        foreach component of local components {
            _ms_parse_parts `component'
            if "`r(name)'" != "`depvar'" continue
            if "`r(ts_op)'" == "" {
                di as error "the dependent variable `depvar' may not also enter a regressor (`term')"
                exit 198
            }
            local yts "`r(ts_op)'.`depvar'"
            local ydep_ts : list ydep_ts | yts
        }
    }
    if "`ydep_ts'" != "" {
        di as text "note: `ydep_ts' (the dependent variable with a time-series operator) among"
        di as text "      the regressors: strict exogeneity fails by construction, and the"
        di as text "      estimates are not consistent with the number of periods fixed"
    }

    // ----------------------------------------------------------------
    // 11. Log outcome, offset, and starting values
    // ----------------------------------------------------------------
    // The offset enters through its within-panel differences only: a
    // constant added to it in a panel moves that panel's fixed effect by
    // the opposite amount and changes nothing else.  It is therefore
    // combined with ln(y) after its smallest value on the estimation sample
    // of each panel (oref) is subtracted.  The difference of two stored
    // values is formed exactly when they are within a factor of two, so an
    // offset with a large common or panel-specific origin costs ln(y) none of
    // its digits, and the criterion, its convergence checks and the test of
    // an exact fit see the same numbers whatever the origin.  oref is added
    // back to the fixed effects, which keep the parameterization
    // log mu = alpha_i + x'b + offset.
    tempvar lny lyo alpha_v oref
    quietly generate double `lny' = ln(`depvar') if `touse'
    local oref_name ""
    if "`offset_o'" != "" {
        quietly by `panvar': generate double `oref' = `offset_o' if `touse'
        quietly by `panvar': replace `oref' = min(`oref', `oref'[_n-1]) if _n > 1
        quietly by `panvar': replace `oref' = `oref'[_N]
        quietly generate double `lyo' = `lny' - (`offset_o' - `oref') if `touse'
        local oref_name "`oref'"
    }
    else quietly generate double `lyo' = `lny' if `touse'
    quietly generate double `alpha_v' = .

    // Starting values.  A vector whose column names are those of the terms
    // (such as e(b) from the same specification) is matched by name, and
    // its base and omitted columns that are not terms of this model are
    // ignored; a vector without such names is taken in the order of the
    // terms, 1 x K or K x 1.
    tempname b0
    local b0name ""
    if "`from_o'" != "" {
        confirm matrix `from_o'
        _xtgamfe_from `from_o' `b0' `"`rhs_names'"'
        local b0name "`b0'"
    }

    // ----------------------------------------------------------------
    // 12. Fit.  The data are in panel order; Mata reads the estimation
    //     sample, optimizes, and returns every numerical result.
    // ----------------------------------------------------------------
    tempname b V omit_out stats fe_vec fe_id_vec prec_out rel_out relc_out relq_full relc_full ncl_out ocd_out
    local nolog_flag = ("`log_o'" == "nolog")
    // set iterlog off suppresses the log unless the option log is typed
    // (as for official commands); Stata 15 may not have c(iterlog).  The
    // option noLOG leaves log and no option alike, so log is looked for in
    // the options as typed.
    local itl ""
    capture local itl = c(iterlog)
    if "`log_o'" == "" & "`itl'" == "off" {
        local log_typed = 0
        local cpos = strpos(`"`cmdline0'"', ",")
        if `cpos' > 0 {
            local otext = substr(`"`cmdline0'"', `cpos' + 1, .)
            local log_typed = regexm(`" `otext' "', "[ ,]log[ ,]")
        }
        if !`log_typed' local nolog_flag = 1
    }
    // e(fe) and e(fe_id), one row per panel with its identifier, are posted
    // for up to 5,000 panels unless nofe is given, and never for more panels
    // than this Stata's largest matrix dimension, c(max_matdim) (800 in
    // Stata/BE and in Stata 15 IC), which Mata's st_matrix() does not
    // enforce
    local fe_post_max = 5000
    local mmd = .
    capture local mmd = c(max_matdim)
    if `mmd' < . & `mmd' > 0 local fe_post_max = min(5000, `mmd')
    if "`fe_o'" == "nofe" local fe_post_max = 0
    local clid_name ""
    if `nested_cluster' local clid_name "`clid'"

    mata: _xtgamfe_fit(                                          ///
        "`lyo'", "`lny'", "`rhsv'", "`touse'", "`panid'", "`wv'", ///
        "`wtype'", "`clid_name'", "`vcetype'",                   ///
        `tol_o', `iter_o', `nolog_flag', "`b0name'",             ///
        "`b'", "`V'", "`omit_out'", "`stats'",                   ///
        "`alpha_v'", "`panvar'", `fe_post_max', "`fe_vec'", "`fe_id_vec'", ///
        "`prec_out'", "`rel_out'", "`relc_out'", "`oref_name'", "`ncl_out'", "`ocd_out'")

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
    local boundary      = `stats'[1, 24]
    // clusters of the shape's standard error, without fweights (from 1.1.1)
    local kse_M         = `stats'[1, 25]

    // Omitted terms: note each one and build the posted coefficient names.
    // Codes: 1 no within-panel variation; 2 collinear with earlier terms;
    //        3 within-panel variation at rounding level only.
    // The levels of one factor variable omitted for the same reason (as
    // with i.id, all of whose levels lack within-panel variation) are
    // noted in one line.
    local k_omit = 0
    local names_post ""
    local names_post_o ""
    local omitted_terms ""
    local okeys ""
    local nok = 0
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
            local okey "t`j'"
            if !strpos("`nm'", "#") {
                _ms_parse_parts `nm'
                if "`r(type)'" == "factor" local okey "`r(ts_op)'|`r(name)'|`oc'"
            }
            local ok : list posof "`okey'" in okeys
            if `ok' == 0 {
                local okeys `"`okeys' `okey'"'
                local nok = `nok' + 1
                local ok = `nok'
                local on_`ok' = 0
                local of_`ok' "`nm'"
                local oc_`ok' = `oc'
                if "`okey'" != "t`j'" {
                    local ov_`ok' = substr("`okey'", strpos("`okey'", "|") + 1, .)
                    local ov_`ok' = substr("`ov_`ok''", 1, strpos("`ov_`ok''", "|") - 1)
                    local oo_`ok' = substr("`okey'", 1, strpos("`okey'", "|") - 1)
                }
            }
            local on_`ok' = `on_`ok'' + 1
            local ol_`ok' "`nm'"
        }
    }
    forvalues k = 1/`nok' {
        local why "because it has no within-panel variation"
        if `oc_`k'' != 1 local why "because of collinearity after the within-panel transformation"
        if `on_`k'' == 1 di as text "note: `of_`k'' omitted `why'"
        else {
            local why : subinstr local why "it has" "they have"
            local fv "`ov_`k''"
            if "`oo_`k''" != "" local fv "`oo_`k''.`fv'"
            di as text "note: `on_`k'' levels of `fv' omitted `why'"
            di as text "      (`of_`k'' to `ol_`k'')"
        }
    }
    // A term is kept whenever its stored values vary within a panel.  When
    // that variation is tiny next to the values themselves, the stored
    // values resolve it only to a few digits: say so.
    forvalues j = 1/`K' {
        if `omit_out'[1, `j'] == 0 & `prec_out'[1, `j'] <= 1e-10 * `prec_out'[2, `j'] {
            local nm : word `j' of `rhs_names'
            local dig = max(0, floor(log10(`prec_out'[1, `j'] / `prec_out'[2, `j'] / c(epsdouble))))
            local dv : display %9.3g `prec_out'[1, `j']
            local mv : display %9.3g `prec_out'[2, `j']
            local dv = strtrim("`dv'")
            local mv = strtrim("`mv'")
            di as text "note: `nm' varies within panels by at most `dv', next to values as"
            di as text "      large as `mv'; the stored values resolve that variation to about"
            di as text "      `dig' significant digits (if it is rounding error, drop `nm'; if it"
            di as text "      is real, store it with a smaller origin)"
        }
    }
    local names_post    : list clean names_post
    local names_post_o  : list clean names_post_o
    local omitted_terms : list clean omitted_terms
    local K_est = `K' - `k_omit'
    // terms that vary within panels in only one cluster (see _xtgamfe_fit;
    // with a clustered covariance), with their positions in e(b), for the
    // display
    local onecl ""
    local onepos ""
    capture confirm matrix `ncl_out'
    if _rc == 0 {
        forvalues j = 1/`K' {
            if `omit_out'[1, `j'] == 0 & `ncl_out'[1, `j'] <= 1 {
                local nm : word `j' of `rhs_names'
                local onecl "`onecl' `nm'"
                local p : word `j' of `est_pos'
                local onepos "`onepos' `p'"
            }
        }
    }
    local onecl  : list clean onecl
    local onepos : list clean onepos
    // The terms whose coefficients rest on one cluster through a direction
    // that involves several terms (from 1.1.1; see _xtgamfe_ocdir): the
    // terms with a nonzero entry in a row of ocd_out, for example x1 and
    // mix = x1 + r when r varies within panels in only one cluster.
    // oneall and oneallpos: every term that rests on one cluster, either
    // way, in the order of the terms, and its position in e(b).
    local ocdt ""
    local oneall ""
    local oneallpos ""
    local has_ocd = 0
    capture confirm matrix `ocd_out'
    if _rc == 0 local has_ocd = (rowsof(`ocd_out') > 0)
    forvalues j = 1/`K' {
        if `omit_out'[1, `j'] != 0 continue
        local nm : word `j' of `rhs_names'
        local p : word `j' of `est_pos'
        local inp = 0
        if `has_ocd' {
            forvalues r = 1/`=rowsof(`ocd_out')' {
                if `ocd_out'[`r', `j'] != 0 local inp = 1
            }
        }
        local inc : list nm in onecl
        if `inc' | `inp' {
            local oneall "`oneall' `nm'"
            local oneallpos "`oneallpos' `p'"
        }
        if `inp' & !`inc' local ocdt "`ocdt' `nm'"
    }
    local ocdt      : list clean ocdt
    local oneall    : list clean oneall
    local oneallpos : list clean oneallpos

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
        if `conv_code' == 3 {
            di as error "when the outcome varies within panels by many orders of magnitude that the"
            di as error "regressors do not explain, the default starting values can be too far from"
            di as error "the solution; supply from()"
        }
        exit 430
    }

    // Notes and warnings are written as text, so that quietly silences
    // them, as it does those of official commands.
    if `hcondition' >= . | `hcondition' > 1e12 {
        di as text "warning: the profiled Hessian is ill-conditioned" ///
            " (condition number = " %10.3g `hcondition' ")"
    }

    // ----------------------------------------------------------------
    // 13. Shape estimates.  e(kappa) is the fixed-T moment estimate;
    //     e(kappa_ml) maximizes the marginal likelihood of the within-panel
    //     shares.  Neither is defined when weights vary within panel.
    // ----------------------------------------------------------------
    local df_kappa      = `N_obs_final' - `N_g_final' - `K_est'
    local kappa_pearson = .
    if `wconst' & !`boundary' & `sum_pearson' > 0 & `sum_pearson' < . & `df_kappa' > 0 {
        local kappa_pearson = `df_kappa' / `sum_pearson'
    }

    local shape_status "finite"
    if `shape_code' == 1 local shape_status "infinite_precision"
    if `shape_code' == 2 local shape_status "no_positive_root"
    if `shape_code' == 3 local shape_status "unbracketed"
    if `shape_code' == 4 local shape_status "invalid_moment"
    if `shape_code' == 6 local shape_status "weights_vary_within_panel"

    // Status of the maximum likelihood shape (from 1.1.1).
    local kml_status "finite"
    if `kml_code' == 1 local kml_status "infinite_precision"
    if `kml_code' == 3 local kml_status "unbracketed"
    if `shape_code' == 6 local kml_status "weights_vary_within_panel"

    if `boundary' & `wconst' {
        di as text "note: the fitted within-panel shares are equal to numerical precision (an"
        di as text "      exact or near-exact fit), so the gamma shape is not finite; e(kappa),"
        di as text "      e(kappa_ml), its standard error, e(ll), the information criteria and"
        di as text "      the Wald test are not reported, and the standard errors are at the"
        di as text "      level of rounding error"
    }
    else if `boundary' {
        // with weights that vary within panel the shape is not computed in
        // any case (below); the fit is exact all the same
        di as text "note: the fitted within-panel shares are equal to numerical precision (an"
        di as text "      exact or near-exact fit); the Wald test is not reported, and the"
        di as text "      standard errors are at the level of rounding error"
    }
    if `boundary' & `wconst' {
        // the exact-fit note above covers the shape
    }
    else if "`shape_status'" == "infinite_precision" {
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

    if `wconst' & !`boundary' & "`kml_status'" == "infinite_precision" {
        di as text "note: no finite maximum likelihood shape estimate; the share likelihood"
        di as text "      increases without bound"
    }
    else if `wconst' & "`kml_status'" == "unbracketed" {
        di as text "note: the maximum likelihood shape could not be bracketed within"
        di as text "      double-precision limits"
    }

    if "`vcetype'" == "oim" & `boundary' {
        di as error "vce(oim) is not available: the fitted within-panel shares are equal to"
        di as error "numerical precision (an exact or near-exact fit), so the maximum likelihood"
        di as error "shape is infinite and the observed information does not exist; use"
        di as error "vce(robust)"
        exit 459
    }
    if "`vcetype'" == "oim" & (`kappa_ml' >= . | `rank_v' >= .) {
        di as error "vce(oim) requires a finite maximum likelihood estimate of the gamma shape," ///
            " which is not available for these data; use vce(robust)"
        exit 459
    }

    if `fe_ok' {
        matrix colnames `fe_vec' = fe
        matrix colnames `fe_id_vec' = panel_id
        // saved estimates carry these rows (help xtgamfe, option nofe)
        di as text "note: e(fe), e(fe_id): one row per panel with its identifier; nofe omits them"
    }
    else if "`fe_o'" != "nofe" {
        di as text "note: e(fe) and e(fe_id) are not posted with more than 5,000 panels (or more"
        di as text "      than c(max_matdim) in this Stata); predict, fe gives the fixed effects"
    }
    // With nofe the command line is stored without the if and in qualifier
    // and without a weight expression, which can name values of the data
    // (as in if id != 17); e(wexp) keeps the expression, which predict and
    // estat need (from 1.1.1).  Under a prefix the prefix stores its own
    // command line.
    local cmdl `"xtgamfe `cmdline0'"'
    if "`fe_o'" == "nofe" {
        _xtgamfe_nofecl `"`cmdline0'"'
        if "`r(what)'" != "" {
            local cmdl `"xtgamfe `r(cl)'"'
            if "`c(prefix)'" == "" _xtgamfe_nofenote `"`r(what)'"' "e(cmdline) is"
        }
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
    // On the boundary of an exact fit the scores, and so the standard
    // errors, are rounding error, and a Wald statistic from them means
    // nothing: it is not reported.
    if `boundary' {
        local wald = .
        local p_wald = .
    }
    // A term that varies within panels in only one cluster (onecl, above),
    // or whose coefficient rests on one cluster through a direction that
    // involves several terms (ocdt), has a variance that the clusters
    // cannot estimate, whatever the rank of e(V) (with clusters that nest
    // the panels the rank can stay full): a test of all coefficients would
    // include it, and is not reported.
    if "`oneall'" != "" {
        local wald = .
        local p_wald = .
    }
    // small: the cluster-robust variance with t and F statistics on M-1
    // degrees of freedom, as regress reports them with clustered standard
    // errors; the Wald statistic is then reported as F = chi2/df_m.
    local df_r = .
    local F_stat = .
    if "`small_o'" != "" {
        local df_r = `N_clust' - 1
        if `wald' < . & `rank_v' > 0 & `rank_v' < . {
            local F_stat = `wald' / `rank_v'
            local p_wald = Ftail(`rank_v', `df_r', `F_stat')
        }
        else local p_wald = .
    }

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
    // The equation is named after the outcome, as xtpoisson and glm name
    // it, so that estimates table sets the two side by side.
    foreach m in `b_post' `b_alt' {
        matrix coleq `m' = `depvar'
    }
    foreach m in `V_post' `V_alt' {
        matrix coleq `m' = `depvar'
        matrix roweq `m' = `depvar'
    }

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
    // signestimationsample and checkestimationsample both read.  A
    // temporary weight variable (the double copy of the weights that a
    // resampling prefix, or vce(bootstrap) and vce(jackknife), passes to
    // the fit) is gone when the results are used, and the prefix gives
    // e(wexp) back the user's variable or expression, whose storage type
    // can differ from that of the copy: such weights are left out of
    // Stata's data signature (e(xtg_wds) = 0) and are signed instead, from
    // the copy the fit used, by the row hash e(xtg_wsig) below (from
    // 1.1.1).
    local wtemp = 0
    if "`wtype'" != "" & !`wexpr' local wtemp = regexm("`wname0'", "^__[0-9A-Z]+$")
    if "`wtype'" != "" & !`wtemp' {
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
    if `wtemp' {
        ereturn local wexp  `"`wexp'"'
        ereturn local wtype "`wtype'"
        capture ereturn hidden scalar xtg_wds = 0
    }

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
    if "`small_o'" != "" {
        ereturn scalar df_r         = `df_r'
        ereturn scalar F            = `F_stat'
    }
    else ereturn scalar chi2        = `wald'
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
        capture ereturn matrix fe    = `fe_vec'
        if _rc == 0 capture ereturn matrix fe_id = `fe_id_vec'
        if _rc {
            di as text "note: Stata did not accept e(fe) and e(fe_id) as matrices; predict, fe"
            di as text "      gives the fixed effects"
        }
    }

    if "`small_o'" != "" ereturn local small "small"
    else                 ereturn local chi2type "Wald"
    ereturn local converged_by   "`converged_by'"
    ereturn local shape_status   "`shape_status'"
    ereturn local kappa_ml_status "`kml_status'"
    ereturn local version        "1.1.1"
    if "`offset_o'" != "" ereturn local offset "`offset_o'"
    if "`vcetype'" == "robust" {
        ereturn local clustvar   "`clustvar'"
        ereturn local vce        "cluster"
        ereturn local vcetype    "Robust"
    }
    else {
        ereturn local vce        "oim"
        ereturn local vcetype    "OIM"
    }
    ereturn local panvar         "`panvar'"
    ereturn local timevar        "`timevar'"
    ereturn local indepvars      "`rhs_names'"
    ereturn local indepvars_full "`rhs_expanded'"
    ereturn local omitted        "`omitted_terms'"
    ereturn local depvar         "`depvar'"
    ereturn local title          "Fixed-effects gamma regression (log link)"
    ereturn local predict        "xtgamfe_p"
    ereturn local estat_cmd      "xtgamfe_estat"
    capture ereturn hidden scalar has_ts = `has_ts'
    // e(onecl): every term that rests on one cluster (documented); the
    // hidden e(xtg_onecl) lists those that vary within panels in only one
    // cluster, e(xtg_ocdterms) the others, e(xtg_onecl_pos) the positions
    // of all of them in e(b), and e(xtg_ocdir) the directions of the
    // coefficients, in the columns of e(b), that involve several terms
    if "`onecl'" != "" capture ereturn hidden local xtg_onecl "`onecl'"
    if "`oneall'" != "" {
        capture ereturn hidden local xtg_onecl_pos "`oneallpos'"
        ereturn local onecl "`oneall'"
    }
    if "`ocdt'" != "" capture ereturn hidden local xtg_ocdterms "`ocdt'"
    if `has_ocd' {
        tempname ocd_b
        matrix `ocd_b' = J(rowsof(`ocd_out'), `n_exp', 0)
        forvalues j = 1/`K' {
            if `omit_out'[1, `j'] != 0 continue
            local p : word `j' of `est_pos'
            forvalues r = 1/`=rowsof(`ocd_out')' {
                matrix `ocd_b'[`r', `p'] = `ocd_out'[`r', `j']
            }
        }
        local cnb : colfullnames e(b)
        matrix colnames `ocd_b' = `cnb'
        capture ereturn hidden matrix xtg_ocdir = `ocd_b'
    }
    // an exact fit (xtgamfe_display does not report the Wald test)
    capture ereturn hidden scalar xtg_boundary = `boundary'
    // The xtset delta (predict and estat ape check it when the model has
    // time-series operators), and the relations that predict and estat ape
    // use to tell which covariate profiles and changes the sample
    // identifies (see _xtgamfe_fit).  An empty cell of an interaction
    // contributes the relation "this term is zero".
    capture ereturn hidden scalar tdelta = `tdelta'
    local epos ""
    local j = 0
    foreach t of local rhs_expanded {
        local j = `j' + 1
        local comps : subinstr local t "#" " ", all
        local ncomp : word count `comps'
        if `ncomp' < 2 continue
        _ms_parse_parts `t'
        if r(omit) != 1 continue
        local anybase = 0
        foreach c of local comps {
            _ms_parse_parts `c'
            if r(base) == 1 local anybase = 1
        }
        if !`anybase' local epos "`epos' `j'"
    }
    local relname ""
    capture confirm matrix `relc_out'
    if _rc == 0 local relname "`rel_out'"
    mata: _xtgamfe_relfull("`relname'", "`relc_out'", strtoreal(tokens("`est_pos'")), ///
        `n_exp', strtoreal(tokens("`epos'")), "`relq_full'", "`relc_full'")
    local relkeys ""
    capture confirm matrix `relc_full'
    if _rc == 0 {
        // The components of the terms in relations whose constant differs
        // between panels (a term without within-panel variation, or one
        // collinear with the fixed effects and other terms).  Their values
        // on the estimation sample define each panel's constant; a hash of
        // them, keyed by panel and time, lets predict with alpha() check
        // that they are unchanged before it compares new values with them
        // (from 1.1.1).
        local nrel = rowsof(`relc_full')
        forvalues r = 1/`nrel' {
            if `relc_full'[`r', 2] != 0 continue
            forvalues j = 1/`n_exp' {
                if `relq_full'[`r', `j'] == 0 continue
                local t : word `j' of `rhs_expanded'
                local comps : subinstr local t "#" " ", all
                foreach c of local comps {
                    _ms_parse_parts `c'
                    local key "`r(ts_op)'.`r(name)'"
                    local relkeys : list relkeys | key
                }
            }
        }
        // (ereturn matrix moves the matrices, so they are posted last)
        capture ereturn hidden matrix xtg_relq = `relq_full'
        if _rc == 0 capture ereturn hidden matrix xtg_relc = `relc_full'
    }
    if "`relkeys'" != "" {
        _xtgamfe_ksig `"`relkeys'"' `panvar' `"`timevar'"'
        capture ereturn hidden local xtg_relkeys `"`relkeys'"'
        capture ereturn hidden local xtg_relhash `"`r(sig)'"'
    }
    // Factor variables some of whose values in the estimation sample have
    // no term of their own in the model (as with 2.time, whose other
    // periods all have the indicator zero): for them every value outside
    // the listed levels shares that observed coding, so predict accepts it
    // (from 1.1.1; see _xtgamfe_psupport in xtgamfe_p.ado).
    _xtgamfe_fvzero `"`rhs_expanded'"' `panvar' `"`timevar'"'
    capture ereturn hidden local xtg_fvzero `"`r(keys)'"'
    // the number of clusters of the standard error of the ML shape, which a
    // bootstrap or jackknife prefix does not resample (xtgamfe_display)
    if "`vcetype'" == "robust" capture ereturn hidden scalar xtg_kse_M = `kse_M'
    // Row signature of the estimation inputs (see _xtgamfe_rsig): the
    // outcome, the panel and time variables, the offset, a weight variable,
    // a cluster variable that nests the panels, and every variable of the
    // regressors (op.name for one with a time-series operator, realized).
    // Stata's data signature, checked as well, is a checksum of each
    // variable separately and does not see values moved between rows;
    // predict and estat compare this one.  (A weight expression, and a
    // temporary weight variable, which a resampling prefix or
    // vce(bootstrap) and vce(jackknife) create and which is gone when the
    // fit is used, are covered by e(xtg_wsig) below.)
    local rkeys "`depvar' `panvar' `timevar' `offset_o'"
    if "`wtype'" != "" & !`wexpr' & !`wtemp' local rkeys "`rkeys' `wname0'"
    if `nested_cluster' local rkeys "`rkeys' `clustvar'"
    local rkeys : list clean rkeys
    local rkeys : list uniq rkeys
    foreach term of local rhs_expanded {
        local comps : subinstr local term "#" " ", all
        foreach c of local comps {
            _ms_parse_parts `c'
            local key "`r(ts_op)'.`r(name)'"
            local rkeys : list rkeys | key
        }
    }
    _xtgamfe_rsig `"`rkeys'"' `panvar' `"`timevar'"'
    capture ereturn hidden local xtg_rkeys `"`rkeys'"'
    capture ereturn hidden local xtg_rsig `"`r(sig)'"'
    // The weights realized from an expression, or passed as a temporary
    // variable by a resampling prefix: the fit freezes one realized set of
    // weights, and it is signed row by row together with the estimation
    // inputs of its row (the row signature above with the realized weights
    // as one more column; rows that tie on the panel and time variables
    // are put in the order of all their values), so that weights moved to
    // other rows, also within a panel and without a time variable, change
    // the hash.  predict and estat evaluate e(wexp) again, into a double,
    // and compare (from 1.1.1).
    if `wexpr' | `wtemp' {
        _xtgamfe_rsig `"`rkeys' `wfrozen'"' `panvar' `"`timevar'"'
        capture ereturn hidden local xtg_wsig `"`r(sig)'"'
    }
    // margins support is not implemented; block it rather than let it
    // produce xb-scale output that ignores the fixed effect and offset.
    // estat ape reports average partial effects on the outcome scale.
    ereturn local marginsnotok   "_ALL"
    ereturn local cmdline        `"`cmdl'"'
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
    // An invalid level() stops before anything is displayed.
    if "`level'" != "" {
        local 0 `", `level'"'
        syntax [, Level(cilevel)]
        local level "level(`level')"
    }
    else local level "level(`=e(level)')"
    if "`eform'" != "" local eformopt "eform(exp(b))"
    local convtxt = cond(e(converged), "yes", "NO")

    // the header in the layout of official panel-data commands
    di ""
    di as text "Fixed-effects gamma regression (log link)" ///
       _col(49) "Number of obs" _col(67) "= " as result %10.0fc e(N)
    di as text "Group variable: " as result abbrev("`e(panvar)'", 31) ///
       as text _col(49) "Number of groups" _col(67) "= " as result %10.0fc e(N_g)
    di ""
    di as text _col(49) "Obs per group:"
    di as text _col(63) "min" _col(67) "= " as result %10.0fc e(g_min)
    di as text _col(63) "avg" _col(67) "= " as result %10.1fc e(g_avg)
    di as text _col(63) "max" _col(67) "= " as result %10.0fc e(g_max)
    di ""

    // %9.4f, and %9.3e for a value below 0.0001, which %9.4f shows as
    // 0.0000 (Stata switches to e-notation itself for a value too large for
    // %9.4f)
    local fk "%9.4f"
    local fp "%9.4f"
    local fm "%9.4f"
    local fs "%9.4f"
    if e(kappa) < 1e-4 local fk "%9.3e"
    if e(phi) < 1e-4 local fp "%9.3e"
    if e(kappa_ml) < 1e-4 local fm "%9.3e"
    if e(kappa_ml_se) < 1e-4 local fs "%9.3e"
    if e(kappa) < . {
        di as text "Gamma shape kappa (fixed-T moment): " as result `fk' e(kappa) ///
           as text "   dispersion 1/kappa: " as result `fp' e(phi)
    }
    else {
        di as text "Gamma shape kappa (fixed-T moment): " as result "n/a" ///
           as text "  (" as result "`e(shape_status)'" as text ")"
    }
    // Under a bootstrap or jackknife prefix (or vce(bootstrap) or
    // vce(jackknife)) the coefficients are resampled but the shape is not:
    // e(kappa_ml_se) is the analytic standard error of the full-sample fit,
    // clustered on panels.  It is shown, with a note, when the prefix
    // resampled the panels; otherwise it is not shown (from 1.1.1; through
    // 1.1.0 the header showed it as if it were clustered like the
    // coefficients).
    local kse_case = 0
    if e(kappa_ml) < . & "`e(prefix)'" != "" & inlist("`e(vce)'", "bootstrap", "jackknife") {
        local kM = e(xtg_kse_M)
        if `kM' >= . local kM = e(N_g)
        local kse_case = cond(e(N_clust) == `kM', 1, 2)
    }
    if e(kappa_ml) < . & `kse_case' == 2 {
        di as text "Gamma shape kappa (marginal ML):    " as result `fm' e(kappa_ml) ///
           as text "   std. err.: " as result "n/a" as text " (see note)"
    }
    else if e(kappa_ml) < . {
        di as text "Gamma shape kappa (marginal ML):    " as result `fm' e(kappa_ml) ///
           as text "   std. err.:          " as result `fs' e(kappa_ml_se)
    }
    else if inlist("`e(kappa_ml_status)'", "infinite_precision", "unbracketed") {
        di as text "Gamma shape kappa (marginal ML):    " as result "n/a" ///
           as text "  (" as result "`e(kappa_ml_status)'" as text ")"
    }
    if `"`e(offset)'"' != "" di as text "Offset: " as result "`e(offset)'"
    local wshow `"`e(wexp)'"'
    if `"$XTGAMFE_WFZ_NAME"' != "" {
        if strtrim(substr(strtrim(`"`e(wexp)'"'), 2, .)) == `"$XTGAMFE_WFZ_NAME"' local wshow `"$XTGAMFE_WFZ_SHOW"'
    }
    if `"`e(wtype)'"' != "" {
        local wbody = strtrim(substr(strtrim(`"`wshow'"'), 2, .))
        di as text "Weights: " as result `"[`e(wtype)'=`wbody']"'
    }

    // A term identified by one cluster: the test of all coefficients is not
    // shown, with or without a resampling prefix (whose own test, in e(chi2)
    // or e(F), includes that term), unless the rank of e(V) already explains
    // why it is missing (below).
    local onecl `"`e(xtg_onecl)'"'
    local ocdt  `"`e(xtg_ocdterms)'"'
    local n1 : word count `onecl'
    local nd : word count `ocdt'
    if e(xtg_boundary) == 1 & "`e(prefix)'" == "" {
        di as text "Omnibus Wald test: " as result "not reported" ///
           as text " (exact fit: the std. errs. are rounding error)"
    }
    else if `n1' + `nd' > 0 & !(e(rank_v) < e(rank_h) & "`e(prefix)'" == "") {
        if `nd' == 0 & `n1' == 1 local why "`onecl' varies within panels in only one cluster"
        else if `nd' == 0        local why "`n1' terms vary within panels in only one cluster each"
        else if `n1' + `nd' == 2 local why "`: word 1 of `onecl' `ocdt'' and `: word 2 of `onecl' `ocdt'' rest on one cluster"
        else                     local why "`=`n1' + `nd'' terms rest on one cluster"
        di as text "Omnibus Wald test: " as result "not reported" ///
           as text " (`why')"
    }
    else if e(df_m) > 0 & e(chi2) < . {
        di as text "Wald chi2(" as result e(df_m) as text ") = " ///
           as result %9.2f e(chi2)                              ///
           as text "      Prob > chi2 = " as result %6.4f e(p)
    }
    else if e(F) < . {
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

    if `kse_case' {
        // With frequency weights the analytic standard error counts each
        // copy of a panel as a cluster, as the header counts the panels.
        local kMn = `kM'
        local kfw = ("`e(wtype)'" == "fweight")
        if `kfw' local kMn = e(N_g)
        local kMd : display %12.0fc `kMn'
        local kMd = strtrim("`kMd'")
        if `kse_case' == 1 & `kfw' {
            di as text "note: the std. err. of the ML shape is not resampled; it is the analytic one,"
            di as text "      clustered on the `kMd' panels that the frequency weights stand for"
        }
        else if `kse_case' == 1 {
            di as text "note: the std. err. of the ML shape is not resampled; it is the analytic one,"
            di as text "      clustered on the `kMd' panels"
        }
        else {
            if "`e(clustvar)'" != "" & e(N_clust) < . {
                local nCd : display %12.0fc e(N_clust)
                local nCd = strtrim("`nCd'")
                local how "over the `nCd' clusters in `e(clustvar)'"
            }
            else local how "over observations"
            di as text "note: the coefficients' std. errs. were resampled `how',"
            di as text "      but the ML shape is not resampled; e(kappa_ml_se) is the analytic"
            di as text "      std. err., clustered on the `kMd' panels"
            if "`e(clustvar)'" != "" {
                di as text "      (fit with vce(cluster `e(clustvar)') for one clustered on `e(clustvar)')"
            }
        }
    }
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
    // Warnings are written as text, so that quietly silences them, as it
    // does those of official commands.
    if e(few_clusters) == 1 & "`e(prefix)'" == "" {
        // "1 degree", "2 degrees"
        local dgw "degrees"
        if "`e(small)'" == "small" {
            if e(df_r) == 1 local dgw "degree"
            di as text "warning: with only " e(N_clust) " clusters, cluster-robust inference may be" ///
                " unreliable even"
            di as text "         with t and F on " e(df_r) " `dgw' of freedom (option small)"
        }
        else {
            if e(N_clust) - 1 == 1 local dgw "degree"
            di as text "warning: conventional cluster-robust normal inference may be unreliable"
            di as text "         with only " e(N_clust) " clusters; option small gives t and F"
            di as text "         statistics with " e(N_clust) - 1 " `dgw' of freedom"
        }
    }
    if e(rank_v) < e(rank_h) & "`e(prefix)'" == "" {
        local why ""
        if e(N_clust) < . & e(N_clust) - 1 < e(rank_h) local why " (too few clusters)"
        di as text "warning: e(V) has rank " e(rank_v) ", below the " e(rank_h) ///
            " estimated coefficients`why';"
        di as text "         joint tests of all coefficients are not available"
        if "`why'" == "" & e(rank_v) > 0 {
            di as text "         (the cluster scores do not span the coefficients: a coefficient"
            di as text "         may rest on one cluster)"
        }
        // with too few clusters and terms that rest on one cluster, the
        // two explanations are given together
        if "`why'" != "" & `"`e(xtg_onecl)'`e(xtg_ocdterms)'"' != "" & e(rank_v) > 0 {
            di as text "         (besides the lack of clusters, some terms rest on one cluster;"
            di as text "         see the note below the table)"
        }
        if e(rank_v) == 0 {
            di as text "         (every score is zero: the model fits the estimation sample"
            di as text "         exactly, so the standard errors are zero and coefficients"
            di as text "         estimated as zero are displayed as omitted)"
        }
    }

    // After a bootstrap or jackknife prefix whose clusters do not nest the
    // panels (as with jackknife, cluster(time):), the replications treat
    // the observations of one panel in different clusters as independent,
    // and the postestimation commands refuse the results (from 1.1.1).
    if "`e(prefix)'" != "" & "`e(clustvar)'" != "" & "`e(clustvar)'" != "`e(panvar)'" {
        tempvar es
        capture quietly generate byte `es' = e(sample)
        if _rc == 0 {
            _xtgamfe_nest `"`e(clustvar)'"' `"`e(panvar)'"' `es'
            if r(nested) == 0 {
                di as text "warning: the clusters of the `e(prefix)' prefix, `e(clustvar)', do not nest the"
                di as text "         panels: its std. errs. treat the observations of a panel in"
                di as text "         different clusters as independent; estat ape, estat park and"
                di as text "         estat fepoisson refuse these results (use clusters in which the"
                di as text "         panels are nested)"
            }
        }
    }

    // first: one equation, displayed without its name (as xtpoisson and glm
    // display theirs).  Inference that the clusters cannot support is not
    // shown (from 1.1.1): for a term that varies within panels in only one
    // cluster (e(xtg_onecl)), and for every term of an exact fit, whose
    // standard errors are rounding error; e(V) keeps the computed values.
    // The terms identified by one cluster are blanked under a resampling
    // prefix as well, whose replications cannot assess them either.
    local blank ""
    if e(xtg_boundary) == 1 & "`e(prefix)'" == "" local blank "all"
    else if "`e(xtg_onecl_pos)'" != "" local blank "`e(xtg_onecl_pos)'"
    di ""
    if "`blank'" != "" {
        tempname Vd
        matrix `Vd' = e(V)
        if "`blank'" == "all" {
            forvalues j = 1/`=colsof(`Vd')' {
                matrix `Vd'[`j', `j'] = .
            }
        }
        else {
            foreach j of local blank {
                matrix `Vd'[`j', `j'] = .
            }
        }
        _coef_table, first `level' `eformopt' `diopts' vmatrix(`Vd')
        if "`blank'" == "all" {
            di as text "note: exact fit: the std. errs., test statistics, p-values and intervals are"
            di as text "      rounding error and are not shown (e(V) holds the std. errs.)"
        }
        else {
            local onecl `"`e(xtg_onecl)'"'
            local ocdt  `"`e(xtg_ocdterms)'"'
            local n1 : word count `onecl'
            local nd : word count `ocdt'
            local who "the cluster scores"
            if "`e(prefix)'" != "" local who "the replications"
            local zt "z"
            if e(df_r) < . local zt "t"
            if `nd' == 0 {
                if `n1' == 1 local lead "`onecl' varies"
                else         local lead "`onecl' vary"
                local txt "`lead' within panels in only one cluster; `who' cannot estimate the sampling variation of such a coefficient, so its std. err., `zt', p-value and interval are not shown, nor is the test of all coefficients (e(V) holds the computed values, which test and lincom use)"
            }
            else {
                // a direction that involves several terms (e(xtg_ocdterms))
                _xtgamfe_andlist `ocdt'
                local dl "`r(list)'"
                local lead ""
                if `n1' == 1 local lead "`onecl' varies within panels in only one cluster, and "
                if `n1' > 1  local lead "`onecl' vary within panels in only one cluster, and "
                local txt "`lead'`dl' are collinear within panels once one cluster is left out; `who' cannot estimate the sampling variation of a coefficient that rests on one cluster, so the std. errs., `zt', p-values and intervals of these terms are not shown, nor is the test of all coefficients (e(V) holds the computed values, which test and lincom use)"
            }
            _xtgamfe_wrapnote "note:" `"`txt'"'
            // the values in e(V) reach tables built from it (from 1.1.1)
            local txt "tables made from e(V), as by estimates table, etable or esttab, show a std. err. for such a term; e(onecl) names these terms"
            if `nd' > 0 local txt "`txt', and help xtgamfe##tn_onecl says which combinations of them keep a meaningful std. err."
            _xtgamfe_wrapnote "note:" `"`txt'"'
        }
    }
    else if "`e(prefix)'" != "" _coef_table, first `level' `eformopt' `diopts'
    else ereturn display, first `level' `eformopt' `diopts'
end

// ---------------------------------------------------------------
// A variable name that does not exist in the data, for the examples in
// messages: stub1, stub2, ... (r(name)).
// ---------------------------------------------------------------
program define _xtgamfe_newname, rclass
    version 15.0
    args stub
    local i = 1
    capture confirm new variable `stub'`i'
    while _rc & `i' < 1000 {
        local i = `i' + 1
        capture confirm new variable `stub'`i'
    }
    return local name "`stub'`i'"
end

// ---------------------------------------------------------------
// A note wrapped at about 78 characters: the lead ("note:") and the words of
// text, with continuation lines indented by six spaces.
// ---------------------------------------------------------------
program define _xtgamfe_wrapnote
    version 15.0
    args lead text
    local line "`lead'"
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
// A list of names written as "a", "a and b", or "a, b and c" (r(list)).
// ---------------------------------------------------------------
program define _xtgamfe_andlist, rclass
    version 15.0
    local n : word count `0'
    local out ""
    forvalues i = 1/`n' {
        local w : word `i' of `0'
        if `i' == 1            local out "`w'"
        else if `i' == `n'     local out "`out' and `w'"
        else                   local out "`out', `w'"
    }
    return local list "`out'"
end

// ---------------------------------------------------------------
// Do the clusters of variable cv nest the panels of pv on the observations
// marked by touse?  r(nested) is 1 if every panel lies in one cluster, 0 if
// not, or if cv has missing values there or is not in the data (r(present)
// is then 0).
// ---------------------------------------------------------------
program define _xtgamfe_nest, rclass
    version 15.0
    args cv pv touse
    capture confirm variable `cv', exact
    if _rc {
        return scalar present = 0
        return scalar nested = 0
        exit
    }
    return scalar present = 1
    tempvar g lo hi ord
    quietly generate long `ord' = _n
    quietly egen long `g' = group(`cv') if `touse'
    quietly count if `touse' & missing(`g')
    if r(N) > 0 {
        sort `ord'
        return scalar nested = 0
        exit
    }
    quietly egen long `lo' = min(`g') if `touse', by(`pv')
    quietly egen long `hi' = max(`g') if `touse', by(`pv')
    quietly count if `touse' & `lo' != `hi'
    local nn = (r(N) == 0)
    sort `ord'
    return scalar nested = `nn'
end

// ---------------------------------------------------------------
// The weight expression must give each observation the same value in any
// row order: xtgamfe sorts the data, and predict, estat ape, and the data
// signature evaluate e(wexp) again later.  A plain variable name passes at
// once.  Otherwise the expression is evaluated in the current order, in
// the reverse order, with the odd-numbered rows first, and with the first
// row moved to the end, and the values are compared on the rows selected by
// if and in.  An expression in _n or a subscript, a running sum, or one
// that draws random numbers fails.
// ---------------------------------------------------------------
program define _xtgamfe_wcheck
    version 15.0
    args wexp mk
    local wname = strtrim(substr(strtrim(`"`wexp'"'), 2, .))
    capture confirm numeric variable `wname', exact
    if _rc == 0 & `: word count `wname'' == 1 exit
    // The sorts below leave the sort seed as they found it, so that the
    // check does not change how later ties are broken (Mata's order()
    // breaks ties with it).
    // Stata 15 has no c(sortseed); there the seed cannot be restored.
    local sseed ""
    capture local sseed = c(sortseed)
    tempvar ord key w0 w1 w2 w3
    quietly generate long `ord' = _n
    quietly generate double `w0' `wexp'
    quietly generate long `key' = -`ord'
    sort `key'
    quietly generate double `w1' `wexp'
    quietly replace `key' = cond(mod(`ord', 2) == 1, `ord', `ord' + _N)
    sort `key'
    quietly generate double `w2' `wexp'
    quietly replace `key' = cond(`ord' == 1, _N + 1, `ord')
    sort `key'
    quietly generate double `w3' `wexp'
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    quietly count if `mk' & (`w1' != `w0' | `w2' != `w0' | `w3' != `w0')
    if r(N) > 0 {
        di as error "the weight expression gives other values when the observations are in"
        di as error "another order (it uses _n, a subscript, a running sum, or random numbers);"
        di as error "xtgamfe sorts the data, and predict and estat ape evaluate the weights"
        di as error "again, so generate the weight variable first, for example"
        _xtgamfe_newname w
        di as error `"    generate double `r(name)' `wexp'"'
        di as error "and specify it by name"
        exit 198
    }
end

// ---------------------------------------------------------------
// The command text as typed (without the command name), with the if and in
// qualifier and a weight expression removed, for e(cmdline) under nofe
// (from 1.1.1): either can name values of the data, such as a panel
// identifier.  A weight given by a variable name is kept; one given by an
// expression is shown as [wtype=...].  The options are kept as typed.
// r(what) says what was removed (empty if nothing).
// ---------------------------------------------------------------
program define _xtgamfe_nofecl, rclass
    version 15.0
    args typed
    local 0 `"`typed'"'
    capture syntax anything [if] [in] [fweight iweight pweight aweight] [, *]
    if _rc {
        return local cl `"`typed'"'
        return local what ""
        exit
    }
    local what ""
    if `"`if'`in'"' != "" local what "the if/in qualifier"
    local wt ""
    if "`weight'" != "" {
        local wn = strtrim(substr(strtrim(`"`exp'"'), 2, .))
        capture confirm variable `wn', exact
        if _rc == 0 & `: word count `wn'' == 1 local wt " [`weight'=`wn']"
        else {
            local wt " [`weight'=...]"
            if "`what'" != "" local what "`what' and the weight expression"
            else              local what "the weight expression"
        }
    }
    if "`what'" == "" {
        return local cl `"`typed'"'
        return local what ""
        exit
    }
    // the options as typed: from the first comma outside parentheses,
    // brackets and quotes
    mata: st_local("opts", _xtgamfe_tlopts(st_local("typed")))
    return local cl `"`anything'`wt'`opts'"'
    return local what "`what'"
end

// ---------------------------------------------------------------
// The note on what nofe leaves out of the stored command line, wrapped at
// about 78 characters.
// ---------------------------------------------------------------
program define _xtgamfe_nofenote
    version 15.0
    args what subj
    local line "note: with nofe, `subj' stored without"
    local out ""
    foreach w of local what {
        if strlen("`line' `w'") > 78 {
            di as text "`line'"
            local line "     "
        }
        local line "`line' `w'"
    }
    di as text "`line'"
end

// ---------------------------------------------------------------
// Hash of the values of some variables on the estimation sample, row by
// row in the order of the panel and time variables (and of the values
// themselves for rows that tie on them: missing time values, or no time
// variable), so that it does not depend on how the data are sorted (from
// 1.1.1).  A key is a variable
// name, or op.name for a variable with a time-series operator (realized
// with fvrevar; the data must be xtset).  Stata's own data signature is a
// checksum of each variable separately, which a permutation of the values
// between rows leaves unchanged; this one is not.  The sort seed and the
// order of the data are restored.  xtgamfe_p.ado and xtgamfe_estat.ado
// carry copies under other names; the three must stay identical.
// ---------------------------------------------------------------
program define _xtgamfe_ksig, rclass
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
    mata: st_local("h", _xtgamfe_vh("`vl'", "`es'"))
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    return local sig "`h'"
end

// ---------------------------------------------------------------
// Row signature of the estimation inputs: a hash of the rows of the
// estimation sample, with the values of every key (a variable name, or
// op.name for a variable with a time-series operator, realized with
// fvrevar), in the order of the panel and time variables.  Rows that tie
// on them (missing time values, or no time variable) are put in the order
// of their values.  So values reassigned to other observations change it,
// and a re-sort of intact rows does not.  Numeric values are hashed bit for bit (their
// eight bytes, high byte first), strings with their lengths.  The sort seed
// and the order of the data are restored.  xtgamfe_p.ado and
// xtgamfe_estat.ado carry copies under other names; the three must stay
// identical.
// ---------------------------------------------------------------
program define _xtgamfe_rsig, rclass
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
    mata: st_local("h", _xtgamfe_rh("`nl'", "`sl'", "`es'"))
    sort `ord'
    if "`sseed'" != "" capture set sortseed `sseed'
    return local sig "`h'"
end

// ---------------------------------------------------------------
// The factor variables (op.name) of the term list some of whose values in
// the estimation sample are not among the levels that the term list
// names, base levels included (from 1.1.1).  For such a variable the
// observed rows with an unnamed value have every indicator of it equal to
// zero, so any unnamed value has a coding that the sample contains.
// ---------------------------------------------------------------
program define _xtgamfe_fvzero, rclass
    version 15.0
    args full panvar timevar
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
                local lev_`k' ""
            }
            local lev_`k' : list lev_`k' | lv
        }
    }
    local zkeys ""
    if `nk' > 0 {
        // the data are sorted (and the order and sort seed restored) only
        // when a factor carries a time-series operator
        local anyts = 0
        foreach key of local keys {
            if substr("`key'", 1, 1) != "." local anyts = 1
        }
        // Stata 15 has no c(sortseed); there the seed cannot be restored.
        local sseed ""
        capture local sseed = c(sortseed)
        tempvar ord es
        quietly generate long `ord' = _n
        quietly generate byte `es' = e(sample)
        if `anyts' sort `panvar' `timevar' `ord'
        forvalues k = 1/`nk' {
            local key : word `k' of `keys'
            if substr("`key'", 1, 1) == "." local src = substr("`key'", 2, .)
            else {
                fvrevar `key'
                local src "`r(varlist)'"
            }
            local levs : subinstr local lev_`k' " " ",", all
            mata: st_local("unl", strofreal(_xtgamfe_fvunl("`src'", "`es'", (`levs'))))
            if `unl' local zkeys "`zkeys' `key'"
        }
        if `anyts' {
            sort `ord'
            if "`sseed'" != "" capture set sortseed `sseed'
        }
    }
    local zkeys : list clean zkeys
    return local keys "`zkeys'"
end

// ---------------------------------------------------------------
// Canonical form of a term name, for matching the columns of from() with
// the terms of the model: for each component of an interaction, its
// time-series operator, its level (factor variables) and its variable, so
// that base (b), no-base (bn) and omission (o) markers and the c. prefix do
// not matter.  r(base) and r(omit) say whether the name carries a base or
// an omission marker.  r(canon) is empty for a name that is not a term.
// ---------------------------------------------------------------
program define _xtgamfe_canon, rclass
    version 15.0
    args term
    local comps : subinstr local term "#" " ", all
    local out ""
    local isbase = 0
    local isomit = 0
    foreach c of local comps {
        capture _ms_parse_parts `c'
        if _rc {
            return local canon ""
            return scalar base = 0
            return scalar omit = 0
            exit
        }
        local lv ""
        if "`r(type)'" == "factor" {
            local lv = r(level)
            if r(base) == 1 local isbase = 1
        }
        if r(omit) == 1 local isomit = 1
        local piece "`r(ts_op)'|`lv'|`r(name)'"
        if "`out'" == "" local out "`piece'"
        else local out "`out'#`piece'"
    }
    return local canon "`out'"
    return scalar base = `isbase'
    return scalar omit = `isomit'
end

// ---------------------------------------------------------------
// Starting values (from()).  Returns in bout a 1 x K vector in the order of
// the K terms in names.  A vector whose column names (row names, for a
// column vector) are terms of the model is matched by name: every term must
// be found once, and a column that is not a term of the model must carry a
// base or omission marker (it is ignored).  A vector none of whose names is
// a term of the model is taken in order, 1 x K or K x 1.
// ---------------------------------------------------------------
program define _xtgamfe_from
    version 15.0
    args from bout names
    local K : word count `names'
    tempname F
    if colsof(`from') == 1 & rowsof(`from') > 1 matrix `F' = `from''
    else matrix `F' = `from'
    if rowsof(`F') != 1 {
        di as error "from() must be a row or column vector"
        exit 503
    }
    local C = colsof(`F')
    local fnames : colnames `F'
    // canonical names of the terms of the model
    forvalues k = 1/`K' {
        local t : word `k' of `names'
        _xtgamfe_canon `t'
        local tc_`k' `"`r(canon)'"'
    }
    // canonical names of the columns, and which term each one matches
    local nmatch = 0
    forvalues j = 1/`C' {
        local f : word `j' of `fnames'
        _xtgamfe_canon `f'
        local fc_`j' `"`r(canon)'"'
        local fb_`j' = (r(base) == 1 | r(omit) == 1)
        local fm_`j' = 0
        forvalues k = 1/`K' {
            if `"`fc_`j''"' != "" & `"`fc_`j''"' == `"`tc_`k''"' {
                local fm_`j' = `k'
                local nmatch = `nmatch' + 1
            }
        }
    }
    matrix `bout' = J(1, `K', .)
    if `nmatch' == 0 {
        // no name matches: the vector is taken in the order of the terms
        if `C' != `K' {
            di as error "from() has `C' element(s); the model has `K' estimated term(s):"
            di as error "    `names'"
            di as error "supply a 1 x `K' vector in that order, or a vector whose column names"
            di as error "are those terms (such as e(b) from the same specification)"
            exit 503
        }
        forvalues k = 1/`K' {
            matrix `bout'[1, `k'] = `F'[1, `k']
        }
    }
    else {
        local missing ""
        forvalues k = 1/`K' {
            local found = 0
            forvalues j = 1/`C' {
                if `fm_`j'' == `k' {
                    if `found' {
                        local t : word `k' of `names'
                        di as error "from(): more than one column for the term `t'"
                        exit 503
                    }
                    local found = 1
                    matrix `bout'[1, `k'] = `F'[1, `j']
                }
            }
            if !`found' {
                local t : word `k' of `names'
                local missing "`missing' `t'"
            }
        }
        local extra ""
        forvalues j = 1/`C' {
            if `fm_`j'' == 0 & !`fb_`j'' {
                local f : word `j' of `fnames'
                local extra "`extra' `f'"
            }
        }
        if "`missing'`extra'" != "" {
            di as error "from(): the column names do not match the terms of the model"
            if "`missing'" != "" di as error "    terms without a column:`missing'"
            if "`extra'" != "" di as error "    columns that are not terms of the model:`extra'"
            di as error "the model's estimated terms are:  `names'"
            exit 503
        }
    }
    forvalues k = 1/`K' {
        if missing(`bout'[1, `k']) {
            di as error "from() contains missing or nonfinite values"
            exit 504
        }
    }
end

// ===================================================================
// Embedded Mata core. The capture-drop prelude makes discard/reload safe.
// ===================================================================
capture mata: mata drop _xtgamfe_wald()
capture mata: mata drop _xtgamfe_center()
capture mata: mata drop _xtgamfe_expand()
capture mata: mata drop _xtgamfe_eval()
capture mata: mata drop _xtgamfe_csum()
capture mata: mata drop _xtgamfe_ocdir()
capture mata: mata drop _xtgamfe_bygroup()
capture mata: mata drop _xtgamfe_shape_moment()
capture mata: mata drop _xtgamfe_shape_solve()
capture mata: mata drop _xtgamfe_shape()
capture mata: mata drop _xtgamfe_kml_score()
capture mata: mata drop _xtgamfe_kml()
capture mata: mata drop _xtgamfe_dlt()
capture mata: mata drop _xtgamfe_disp()
capture mata: mata drop _xtgamfe_bshare()
capture mata: mata drop _xtgamfe_relfull()
capture mata: mata drop _xtgamfe_fit()
capture mata: mata drop _xtgamfe_vh()
capture mata: mata drop _xtgamfe_fvunl()
capture mata: mata drop _xtgamfe_rh()
capture mata: mata drop _xtgamfe_w2()
capture mata: mata drop _xtgamfe_tlopts()

mata:

// Hash of the rows of the variables vars over the observations selected by
// es, in the current order: Jenkins' one-at-a-time hash (hash1) of the %21x
// text of every value, row by row, in blocks of 4,096 rows, each block's
// hash seeding the next.  Returns "n:hash" (see _xtgamfe_ksig).
string scalar _xtgamfe_vh(string scalar vars, string scalar es)
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

// Hash of the rows of the numeric variables nvars and the string variables
// svars over the observations selected by es, in the current order (see
// _xtgamfe_rsig): Jenkins' one-at-a-time hash (hash1) of the eight bytes of
// every numeric value, high byte first, row by row in blocks of 4,096 rows,
// each block's hash seeding the next; then of every string, prefixed by its
// length.  Returns "n:hash".
string scalar _xtgamfe_rh(string scalar nvars, string scalar svars, string scalar es)
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

// The text of s from its first comma outside parentheses, brackets and
// double quotes (the options of a command), or "" if there is none.
string scalar _xtgamfe_tlopts(string scalar s)
{
    real scalar i, n, d, q
    string scalar c

    n = strlen(s)
    d = 0
    q = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q) {
            if (c == char(34)) q = 0
            continue
        }
        if (c == char(34)) q = 1
        else if (c == "(" | c == "[") d++
        else if (c == ")" | c == "]") d--
        else if (c == "," & d == 0) return(substr(s, i, .))
    }
    return("")
}

// The exact power of two s for which m s lies in [1, 2), for a positive
// finite m (1 otherwise), built by repeated halving or doubling, which is
// exact; at most 2^1022 either way.
real scalar _xtgamfe_w2(real scalar m)
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

// 1 if some nonmissing value of variable src on the observations selected
// by es is not among the levels L (see _xtgamfe_fvzero).
real scalar _xtgamfe_fvunl(string scalar src, string scalar es, real rowvector L)
{
    real colvector v, ok
    real scalar k

    v = st_data(., src, es)
    ok = (v :>= .)
    for (k = 1; k <= cols(L); k++) ok = ok :| (v :== L[k])
    return(any(!ok))
}

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
// number of groups.  Rows of one group are added in their order in Z (a
// stable order: order() alone breaks ties with the sort seed).
real matrix _xtgamfe_csum(real matrix Z, real colvector id, real scalar n)
{
    real colvector o
    real matrix cinfo

    o = order((id, (1::rows(id))), (1, 2))
    cinfo = panelsetup(id[o], 1)
    n = rows(cinfo)
    return(panelsum(Z[o, .], cinfo))
}

// The coefficient directions that rest on one cluster (from 1.1.1).  For
// a cluster c, a direction v of the coefficients with X_(-c) v = 0, where
// X_(-c) holds the rows of the other clusters of the within-panel design
// X, is not identified by the other clusters: moving the coefficients
// along v changes no fitted mean outside c.  The clustered covariance then
// cannot estimate the sampling variation of a coefficient or contrast
// whose vector has a part along v (the score along v is zero in every
// other cluster and the scores sum to zero), whatever the rank of e(V).
// A term whose within-panel variation lies in one cluster is such a
// direction by itself; the caller counts those terms (nclv), and they are
// left out here.  Returned are the other directions, which involve
// several terms (as x1 and x1 + r when r varies in one cluster): an
// orthonormal basis of their span, one row each, in the coordinates of X
// (the coefficients times the scale of each column), with exact zeros for
// the terms that none of them involves; 0 rows when there are none.
//
// X: the centered design, columns at unit root mean square; info and pid:
// the panels; clp: the cluster of each panel (any codes) or, with
// panels = 1, the panels themselves; Pvk: 1 where a term varies within a
// panel; S: quadcross(X, X).
//
// The rank follows the collinearity rule of the fit: the cross products
// of the other clusters' rows, scaled to a unit diagonal, are swept by
// invsym() in term order, and a term whose pivot is zero to invsym()'s
// tolerance is collinear with earlier ones.  A term is involved in the
// null directions when the part of its unit vector in them, on that
// scale, exceeds 1e-6.
//
// Cost.  The rows of a cluster that loses a direction carry a leverage
// tr(S^-1 S_c) of 1 or more (S_c the cross products of its rows); the
// leverages of the clusters sum to K, so at most 2K clusters reach 1/2,
// and only those are examined.  The leverage is bounded by
// tr(S_c)/lambda_min(S), which costs one pass over the rows; it is
// computed only for the clusters that this bound does not clear (a
// cluster with a leverage below 1/2 keeps more than half of the design's
// information in every direction).  For the clusters examined, the cross
// products of the other clusters are summed directly, not formed as a
// difference.
real matrix _xtgamfe_ocdir(real matrix X, real matrix info, real colvector pid,
    real colvector clp, real matrix Pvk, real matrix S, real scalar panels)
{
    real scalar n, K, G, Mc, lmin, i, m, k, nd, c
    real colvector o, cs, g, gr, trc, cand, sel, lev, tc, c3, inc3, rw, csel
    real matrix Cv, Sinv, Xc, A, R, Gi, N, Q, ev, D, Sm, Srest, B
    real rowvector ncl, Jc, r, dr, kp, dd, rn, lam

    n = rows(X)
    K = cols(X)
    G = rows(info)
    if (K < 2) return(J(0, K, .))
    // the cluster of each panel as 1..Mc
    if (panels) {
        g  = (1::G)
        Mc = G
    }
    else {
        o  = order((clp, (1::G)), (1, 2))
        cs = clp[o]
        g  = J(G, 1, .)
        g[o] = runningsum(1 \ (cs[|2 \ G|] :!= cs[|1 \ G - 1|]))
        Mc = max(g)
    }
    if (Mc < 2) return(J(0, K, .))
    // the clusters with a panel in which each term varies
    if (panels) Cv = Pvk
    else        Cv = (_xtgamfe_csum(Pvk, g, m) :> 0)
    ncl = colsum(Cv)

    // bound on the leverage of each cluster: tr(S_c)/lambda_min(S)
    lmin = min(symeigenvalues((S + S') / 2))
    trc = panelsum(rowsum(X :* X), info)
    if (!panels) trc = _xtgamfe_csum(trc, g, m)
    if (lmin > 0 & lmin < .) cand = (trc :>= .5 * lmin)
    else                     cand = J(Mc, 1, 1)
    if (!any(cand)) return(J(0, K, .))

    // the leverage of the clusters that the bound does not clear
    gr = g[pid]
    sel = selectindex(cand[gr])
    Sinv = invsym((S + S') / 2)
    Xc = X[sel, .]
    lev = rowsum((Xc * Sinv) :* Xc)
    tc = J(Mc, 1, 0)
    csel = selectindex(cand)
    tc[csel] = _xtgamfe_csum(lev, gr[sel], m)
    c3 = selectindex(tc :>= .5)
    if (rows(c3) == 0) return(J(0, K, .))

    // the cross products of each cluster examined and of all other rows
    inc3 = J(Mc, 1, 0)
    inc3[c3] = J(rows(c3), 1, 1)
    rw = inc3[gr]
    Srest = quadcross(X, 1 :- rw, X)
    Sm = J(rows(c3) * K, K, 0)
    for (i = 1; i <= rows(c3); i++) {
        sel = selectindex(gr :== c3[i])
        Sm[|(i - 1) * K + 1, 1 \ i * K, K|] = quadcross(X[sel, .], X[sel, .])
    }

    D = J(K, 0, .)
    for (i = 1; i <= rows(c3); i++) {
        c = c3[i]
        // the terms that vary within panels outside c (the others are the
        // terms counted by the caller)
        Jc = selectindex((ncl :- Cv[c, .]) :> 0)
        k = cols(Jc)
        if (k < 2) continue
        A = Srest
        for (m = 1; m <= rows(c3); m++) {
            if (m != i) A = A + Sm[|(m - 1) * K + 1, 1 \ m * K, K|]
        }
        A = A[Jc, Jc]
        r = sqrt(diagonal(A))'
        R = A :/ (r' * r)
        R = (R + R') / 2
        Gi = invsym(R, 1..k)
        dr = (diagonal(Gi) :== 0)'
        if (!any(dr)) continue
        kp = selectindex(!dr)
        dd = selectindex(dr)
        nd = cols(dd)
        // a basis of the null directions: each collinear term against the
        // earlier ones, then orthonormalized
        N = J(k, nd, 0)
        N[dd, .] = I(nd)
        if (cols(kp) > 0) N[kp, .] = -Gi[kp, kp] * R[kp, dd]
        ev = .
        lam = .
        symeigensystem(N' * N, ev, lam)
        Q = (N * ev) :/ sqrt(lam)
        rn = sqrt(rowsum(Q :* Q))'
        Q = Q :* (rn' :> 1e-6)
        // to the coordinates of X (theta_j = gamma_j r_j), unit length
        N = J(K, nd, 0)
        N[Jc, .] = Q :/ r'
        rn = sqrt(colsum(N :* N))
        D = D, (N :/ (rn + (rn :== 0)))
    }
    if (cols(D) == 0) return(J(0, K, .))
    // an orthonormal basis of all the directions; terms that none of them
    // involves keep exact zeros
    ev = .
    lam = .
    symeigensystem(D * D', ev, lam)
    B = ev[., selectindex(lam :> 1e-12 * max(lam))]
    B = B :* (rowsum(D :!= 0) :> 0)
    return(B')
}

// Totals of the columns of Z by distinct value of the panel length T.
// Returns (T value, column totals...), one row per distinct T.  Rows with
// the same T are added in their order in Z (a stable order).
real matrix _xtgamfe_bygroup(real colvector T, real matrix Z)
{
    real colvector o
    real matrix tinfo

    o = order((T, (1::rows(T))), (1, 2))
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

// digamma(T k) - digamma(k) - ln(T) for large k, from the asymptotic
// series of digamma in u = 1/k.  The direct difference loses all accuracy
// as k grows (the two digamma values agree in their leading digits); the
// series is exact to double precision for k > 1e4, where it is used.
real colvector _xtgamfe_dlt(real colvector T, real scalar k)
{
    real scalar u

    u = 1 / k
    return((1 :- 1 :/ T) :* (u / 2) + (1 :- 1 :/ T:^2) :* (u^2 / 12) -
           (1 :- 1 :/ T:^4) :* (u^4 / 120) + (1 :- 1 :/ T:^6) :* (u^6 / 252))
}

// Score in kappa of the marginal log likelihood of the within-panel shares,
//   l_i(kappa) = lngamma(T_i kappa) - T_i lngamma(kappa) + kappa A_i + c_i,
//   A_i = sum_t ln(share_it) of the fitted mean-scaled outcomes.
// TN holds (T, weighted count); sumA is the weighted total of A_i, and sumB
// that of B_i = A_i + T_i ln(T_i), the sum of the log residuals of panel i.
// For kappa > 1e4 the score is evaluated as sum T_i dlt(T_i, kappa) + sumB,
// which avoids the cancellation between T_i ln(T_i) and the digamma
// difference (through 1.1.0 that cancellation produced a spurious finite
// root near 1e14 for exact fits).
real scalar _xtgamfe_kml_score(real matrix TN, real scalar sumA, real scalar sumB,
    real scalar kappa)
{
    if (kappa <= 1e4) {
        return(sum(TN[., 2] :* TN[., 1] :* (digamma(TN[., 1] :* kappa) :- digamma(kappa))) + sumA)
    }
    return(sum(TN[., 2] :* TN[., 1] :* _xtgamfe_dlt(TN[., 1], kappa)) + sumB)
}

// Maximum of the marginal likelihood in kappa.  The log likelihood is
// strictly concave with score +infinity at zero, so the root is unique when
// it exists.  status: 0 finite root; 1 no finite root (score positive
// everywhere: the shares are numerically equal); 3 bracket failure.
void _xtgamfe_kml(
    real matrix TN,
    real scalar sumA,
    real scalar sumB,
    real scalar kappa,
    real scalar status)
{
    real scalar lo, hi, mid, flo, fhi, fmid, j

    kappa = .
    status = 3
    if (sumA >= . | sumB >= .) return

    lo = 1
    hi = 1
    flo = _xtgamfe_kml_score(TN, sumA, sumB, 1)
    if (flo >= .) return
    if (flo > 0) {
        fhi = flo
        while (fhi > 0 & hi < 1e300) {
            lo = hi
            hi = hi * 10
            fhi = _xtgamfe_kml_score(TN, sumA, sumB, hi)
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
            flo = _xtgamfe_kml_score(TN, sumA, sumB, lo)
        }
        if (flo < 0 | flo >= .) return
    }
    for (j = 1; j <= 200; j++) {
        mid = exp((ln(lo) + ln(hi)) / 2)
        fmid = _xtgamfe_kml_score(TN, sumA, sumB, mid)
        if (fmid > 0) lo = mid
        else          hi = mid
    }
    kappa = exp((ln(lo) + ln(hi)) / 2)
    status = 0
}

// Dispersion of the fitted within-panel shares, for the test of an exact
// fit.  dd is the weighted sum of squared within-panel deviations of the
// log residuals ln(y_it/mu_it).  dn bounds the part of dd that rounding can
// produce: each log residual is formed from ln(y), the offset, the index
// and the fixed effect, each of which carries a relative error of the
// order of epsilon(1), and y itself is stored with that relative precision.
void _xtgamfe_disp(
    real colvector y,
    real colvector lny,
    real matrix    X,
    real colvector beta,
    real colvector lnmean,
    real colvector w,
    real matrix    info,
    real colvector pid,
    real colvector Tp,
    real scalar    dd,
    real scalar    dn)
{
    real colvector lr, mag

    lr  = y - X * beta - lnmean[pid]
    lr  = lr - (panelsum(lr, info) :/ Tp)[pid]
    dd  = quadsum(w :* lr:^2)
    mag = 1 :+ abs(lny) :+ abs(y - lny) :+ abs(X) * abs(beta) :+ abs(lnmean[pid])
    dn  = quadsum(w :* (64 * epsilon(1) :* mag):^2)
}

// B_i = sum_t ln(T_i s_it), the log share term of panel i, with s_it the
// share of y_it/mu_it in its panel total.  It is a second-order quantity
// (about -1/2 the within-panel sum of squares of the log residuals), so it
// is formed from the within-panel deviations d of the log residuals: for a
// panel with sum d^2 <= 1e-6, from the cumulant series
// -T (m2/2 + m3/6 + (m4 - 3 m2^2)/24) in the central moments of d, exact
// to double precision there; otherwise directly, as
// sum d - T ln(mean exp(d)).  Used where the shape exceeds 1e4.
real colvector _xtgamfe_bshare(real colvector lr, real matrix info,
    real colvector pid, real colvector Tp)
{
    real colvector d, m2, m3, m4, B, Bd, big

    d  = lr - (panelsum(lr, info) :/ Tp)[pid]
    m2 = panelsum(d:^2, info) :/ Tp
    m3 = panelsum(d:^3, info) :/ Tp
    m4 = panelsum(d:^4, info) :/ Tp
    B  = -Tp :* (m2 / 2 + m3 / 6 + (m4 - 3 * m2:^2) / 24)
    big = (Tp :* m2 :> 1e-6)
    if (any(big)) {
        Bd = panelsum(d, info) - Tp :* ln(panelsum(exp(d), info) :/ Tp)
        B[selectindex(big)] = Bd[selectindex(big)]
    }
    return(B)
}

// Relations for the term list of the posted coefficient vector.  rel and
// relc (see _xtgamfe_fit) are over the Kfull estimated-or-omitted terms;
// they are placed at the positions pos of the n terms of the full list, and
// one relation is added for each empty cell (positions epos), whose term
// must be exactly zero.  qout: the relation rows, then mu, then s; cout:
// code, global, constant, tau, m.
void _xtgamfe_relfull(
    string scalar rel_name,
    string scalar relc_name,
    real rowvector pos,
    real scalar n,
    real rowvector epos,
    string scalar qout_name,
    string scalar cout_name)
{
    real matrix rel, relc, qout, cout
    real scalar m0, m, r

    if (rel_name != "") {
        rel  = st_matrix(rel_name)
        relc = st_matrix(relc_name)
    }
    else {
        rel  = J(2, cols(pos), 0)
        relc = J(0, 5, .)
    }
    m0 = rows(relc)
    m = m0 + cols(epos)
    if (m == 0) return
    qout = J(m + 2, n, 0)
    cout = J(m, 5, 0)
    for (r = 1; r <= m0; r++) qout[r, pos] = rel[r, .]
    qout[m + 1, pos] = rel[m0 + 1, .]
    qout[m + 2, pos] = rel[m0 + 2, .]
    if (m0 > 0) cout[1..m0, .] = relc
    for (r = 1; r <= cols(epos); r++) {
        qout[m0 + r, epos[r]] = 1
        cout[m0 + r, .] = (4, 1, 0, 0, 0)
    }
    st_matrix(qout_name, qout)
    st_matrix(cout_name, cout)
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
    string scalar feid_name,
    string scalar prec_name,
    string scalar rel_name,
    string scalar relc_name,
    string scalar oref_name,
    string scalar ncl_name,
    string scalar ocd_name)
{
    real colvector y, lny, pid, w, beta, g, beta_new, g_new, delta, vd
    real colvector Wp, Tp, wfirst, p, p_new, lnmean, lnmean_new, yc
    real colvector cl, clp, om, lr, ratio, A, sk, ci, alpha
    real matrix X, Xbar, H, H_new, Hinv, Hinv_new, V, Vinv, info, ZZinv, Vfull
    real matrix ZZ, OD
    real rowvector kpos
    real matrix Gs, Gt, Sc, B, TN, bg
    real rowvector xmaxabs, xdev, novar, collin, xscale, omit, keep, bfull, stats
    real scalar Q, Q_new, step, conv, conv_code, iter, iter_done, K, Kfull, gnorm
    real scalar max_halve, halve_count, accepted, candidate_ok, j, n, G, M
    real scalar qform, qform_new, decrement, decrement_new
    real scalar rank_h, rank_h_new, rank_v, hcondition, objective_slack
    real scalar wconst, isfw, ss, kappa, shape_code, kml, kml_code, kml_se, ll, hk
    real scalar Nw, Gw, sumA, fe_ok
    real scalar sumB, boundary, dd, dn, m, jj, gl, tau, mr
    real colvector Bp, xj, rho, rhot, kp, res, rsc, Sy, lmx
    real scalar i
    real matrix Xfirst, Xom, ZZi, rel, relc
    real rowvector xref
    real rowvector omc
    string rowvector rhs_list
    real matrix Pv
    real rowvector nclv, nclf
    real scalar nc

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
    // They are first multiplied by the exact power of two that brings the
    // largest to [1, 2), so that their total cannot overflow (for weights
    // of ordinary size this changes no bit of the result).
    if (wtype == "pweight" | wtype == "iweight") {
        w = w :* _xtgamfe_w2(max(w))
        w = w :* (n / quadsum(w))
    }

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
    // A regressor has no within-panel variation when its stored values are
    // equal within every panel.  The comparison is exact, so it does not
    // depend on the origin or the units of the regressor.  (Through 1.1.0 a
    // regressor whose largest within-panel deviation was no more than 1e-12
    // of its largest absolute value was also omitted; that dropped a
    // regressor with a large origin whose variation was exactly stored.)
    // The largest deviation and the largest absolute value are returned so
    // that the caller can note a possible loss of precision in the stored
    // values.  omit codes: 1 no within-panel variation, 2 collinear (below).
    xmaxabs = colmax(abs(X))
    Xfirst = X[info[., 1], .]
    // reference point of the relations below: the mean of each term over
    // the estimation sample (no observation's own values are stored)
    xref = quadcolsum(X) :/ n
    // Pv: 1 for a panel in which the term takes more than one value
    Pv = panelsum(X :!= Xfirst[pid, .], info) :> 0
    novar = (colsum(Pv) :== 0)
    X = _xtgamfe_center(X, w, info, pid, Wp, Xbar)
    xdev = colmax(abs(X))
    omit = novar

    // ---- collinearity after the within transformation ----
    // The profiled Hessian is singular at every beta exactly when the
    // within-centered columns are linearly dependent.  Columns are scaled
    // to unit root mean square and swept in order, so a dependent column is
    // attributed to the later term.
    keep = select(1..Kfull, omit :== 0)
    if (cols(keep) > 0) {
        xscale = sqrt(quadcolsum(X[., keep]:^2) / n)
        ZZ = quadcross(X[., keep] :/ xscale, X[., keep] :/ xscale)
        ZZinv = invsym(ZZ, 1..cols(keep))
        collin = (diagonal(ZZinv) :== 0)'
        for (j = 1; j <= cols(keep); j++) if (collin[j]) omit[keep[j]] = 2
    }
    keep = select(1..Kfull, omit :== 0)
    if (cols(keep) == 0) {
        errprintf("no regressor is identified: every term either has no within-panel variation\n")
        errprintf("or is collinear with the others after the within-panel transformation\n")
        exit(459)
    }

    // positions of the identified terms among those checked for
    // collinearity (the rows and columns of ZZ)
    kpos = select(1..cols(select(1..Kfull, novar :== 0)), (omit :== 0)[select(1..Kfull, novar :== 0)])

    // ---- estimation design: identified columns at unit within-panel RMS ----
    omc = select(1..Kfull, omit :!= 0)
    if (cols(omc) > 0) Xom = X[., omc]
    X = X[., keep]
    K = cols(X)
    xscale = sqrt(quadcolsum(X:^2) / n)
    X = X :/ xscale

    // ---- relations that tie each omitted term to the identified ones ----
    // For omitted column j, q_j has 1 in column j and -rho_j in the kept
    // columns, where a_j - A_K rho_j is constant within every panel of the
    // estimation sample (rho_j = 0 for a term without within-panel
    // variation).  A covariate profile x identifies the fitted mean of
    // panel i only if x'q_j equals that panel's constant, and a change c in
    // the covariates is identified only if c'q_j = 0.  rel holds the rows
    // q_j, then a reference point mu (the mean of each term over the
    // estimation sample, so that no observation's values are stored; zero
    // for a term without within-panel variation, which is compared
    // exactly) and
    // the within-panel root mean square s of every column.  relc holds, per
    // relation: the code; whether the constant, k = (x - mu)'q, is the same
    // in every panel; that constant; a tolerance tau; and m = max_k |q_k|
    // s_k.  The relation holds for x when |(x - mu)'q - k| <= tau m (1 +
    // sum over the terms in q of |x_k - mu_k| / s_k); tau is 100 times the
    // largest such ratio on the estimation sample, and at least 1e-9.
    rel = J(0, Kfull, .)
    relc = J(0, 5, .)
    if (cols(omc) > 0) {
        ZZi = invsym(quadcross(X, X))
        rel = J(cols(omc) + 2, Kfull, 0)
        relc = J(cols(omc), 5, 0)
        rel[cols(omc) + 1, keep] = xref[keep]
        rel[cols(omc) + 2, keep] = xscale
        for (m = 1; m <= cols(omc); m++) {
            jj = omc[m]
            rel[m, jj] = 1
            if (omit[jj] == 2) {
                xj   = Xom[., m]
                rhot = ZZi * quadcross(X, xj)
                rho  = rhot :/ xscale'
                rel[m, keep] = -rho'
                rel[cols(omc) + 1, jj] = xref[jj]
                rel[cols(omc) + 2, jj] = sqrt(quadsum(xj:^2) / n)
                mr   = max(abs(rel[m, .]) :* rel[cols(omc) + 2, .])
                kp   = (Xbar[., jj] :- xref[jj]) - (Xbar[., keep] :- xref[keep]) * rho
                res  = abs(xj - X * rhot)
                rsc  = 1 :+ abs(xj + Xbar[pid, jj] :- xref[jj]) / rel[cols(omc) + 2, jj] +
                       rowsum(abs(X :* xscale + Xbar[pid, keep] :- xref[keep]) :/ xscale :*
                       (rho' :!= 0))
                tau  = max((1e-9, 100 * max(res :/ (mr :* rsc))))
                gl   = (max(abs(kp :- kp[1])) <= tau * mr)
            }
            else {
                // compared exactly: mu_j = 0, s_j = 0, tau = 0
                kp  = Xfirst[., jj]
                mr  = 0
                tau = 0
                gl  = (max(abs(kp :- kp[1])) == 0)
            }
            relc[m, .] = (omit[jj], gl, (gl ? kp[1] : .), tau, mr)
        }
    }
    st_matrix(prec_name, (xdev \ xmaxabs))
    if (rows(relc) > 0) {
        st_matrix(rel_name, rel)
        st_matrix(relc_name, relc)
    }

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
            // a failure to converge, as the other exits of the iterations
            // (from 1.1.1; return code 459 before)
            errprintf("profiled Hessian lost numerical rank at completed iteration %g\n", iter_done)
            exit(430)
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

    // ---- exact and near-exact fits ----
    // When the fitted within-panel shares are equal to numerical precision
    // (the regressors and fixed effects reproduce the outcome), the share
    // likelihood increases without bound in kappa, and neither shape
    // estimate, the log likelihood, nor the observed information is
    // defined.  The fit is on that boundary when the dispersion of the log
    // residuals, dd, is not distinguishable from what rounding (dn) and the
    // convergence tolerance (decrement^2, which approximates the dispersion
    // that stopping the optimizer leaves) can produce.  When dd is not well
    // above the latter, Newton steps continue while the decrement falls, so
    // that a small but real dispersion is resolved before it is judged.
    // Both apply only to a near-exact fit, whose mean squared within-panel
    // deviation of the log residuals is at most 1e-4 (a coefficient of
    // variation of about 0.01): with a loose tolerance() the decrement can
    // be large next to the dispersion of an ordinary fit, which is not
    // judged.  The further steps count against iterate(), which caps
    // e(iterations).  Ordinary fits are many orders of magnitude away from
    // this region and are unaffected.
    boundary = 0
    if (conv) {
        _xtgamfe_disp(y, lny, X, beta, lnmean, w, info, pid, Tp, dd, dn)
        if (dd > dn & dd <= 1e4 * decrement^2 & dd <= 1e-4 * quadsum(w)) {
            for (jj = 1; jj <= 20 & iter_done < maxiter; jj++) {
                delta = -Hinv * g
                beta_new = beta + delta
                _xtgamfe_eval(2, y, X, w, info, pid, Wp, Tp, beta_new, Q_new, g_new, H_new, p_new, lnmean_new)
                if (Q_new >= . | hasmissing(g_new) | hasmissing(H_new)) break
                if (Q_new > Q + 64 * epsilon(max((1, abs(Q))))) break
                Hinv_new = invsym(H_new)
                if (K - diag0cnt(Hinv_new) < K) break
                decrement_new = sqrt(max((g_new' * Hinv_new * g_new, 0)))
                if (decrement_new >= decrement) break
                beta = beta_new
                Q = Q_new
                g = g_new
                H = H_new
                p = p_new
                lnmean = lnmean_new
                Hinv = Hinv_new
                decrement = decrement_new
                hcondition = cond(H)
                gnorm = sqrt(g' * g)
                iter_done = iter_done + 1
                if (!nolog) {
                    printf("Iteration %g: Q = %12.6g, |grad| = %12.6g, decrement = %12.6g\n",
                           iter_done, Q, gnorm, decrement)
                    displayflush()
                }
            }
            _xtgamfe_disp(y, lny, X, beta, lnmean, w, info, pid, Tp, dd, dn)
        }
        boundary = (dd <= dn + 100 * decrement^2 & dd <= 1e-4 * quadsum(w))
    }

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
        // quadsum() skips missing values: a ratio outside the numeric
        // range must not be dropped from the moment (from 1.1.1)
        if (hasmissing(ratio)) ss = .

        TN = _xtgamfe_bygroup(Tp, om)
        if (boundary) shape_code = 1
        else          _xtgamfe_shape_solve(TN, ss, kappa, shape_code)

        // A_i = sum_t ln(share_it), share_it = (y_it/mu_it)/T_i
        A = panelsum(lr, info) - Tp :* ln(Tp)
        sumA = quadsum(om :* A)
        // B_i = A_i + T_i ln(T_i), evaluated stably for use at large kappa
        Bp = _xtgamfe_bshare(lr, info, pid, Tp)
        sumB = quadsum(om :* Bp)
        if (hasmissing(A) | hasmissing(Bp)) {
            sumA = .
            sumB = .
        }
        if (boundary) kml_code = 1
        else          _xtgamfe_kml(TN, sumA, sumB, kml, kml_code)
        if (kml_code == 0) {
            // constant of the share density: -sum_t ln(y_it / sum_s y_is).
            // From 1.1.1, when the panel sums of the outcome overflow or
            // underflow, the panel maximum of ln(y) is factored out before
            // exponentiating (through 1.1.0 an overflowed sum gave a missing
            // constant that quadsum() skipped, and so a finite but wrong
            // e(ll), after the outcome was multiplied by a large number).
            // Otherwise the 1.1.0 expression is used unchanged.
            Sy = panelsum(exp(lny), info)
            if (hasmissing(Sy) | min(Sy) < 1e-290) {
                lmx = J(G, 1, .)
                for (i = 1; i <= G; i++) lmx[i] = max(lny[|info[i, 1] \ info[i, 2]|])
                ci = Tp :* (lmx + ln(panelsum(exp(lny - lmx[pid]), info))) - panelsum(lny, info)
            }
            else ci = Tp :* ln(Sy) - panelsum(lny, info)
            if (kml <= 1e4) {
                hk = sum(TN[., 2] :* (TN[., 1] :* trigamma(kml) - TN[., 1]:^2 :* trigamma(TN[., 1] :* kml)))
                ll = sum(TN[., 2] :* (lngamma(TN[., 1] :* kml) - TN[., 1] :* lngamma(kml))) +
                     kml * sumA + quadsum(om :* ci)
            }
            else {
                // asymptotic series in u = 1/kappa of the same quantities
                // (the direct forms cancel catastrophically for large kappa)
                hk = sum(TN[., 2] :* ((TN[., 1] :- 1) :* (1 / kml)^2 / 2 +
                     (TN[., 1] - 1 :/ TN[., 1]) :* (1 / kml)^3 / 6 -
                     (TN[., 1] - 1 :/ TN[., 1]:^3) :* (1 / kml)^5 / 30 +
                     (TN[., 1] - 1 :/ TN[., 1]:^5) :* (1 / kml)^7 / 42))
                ll = kml * sumB + sum(TN[., 2] :* ((TN[., 1] :- 1) / 2 :* (ln(kml) - ln(2 * pi())) -
                     ln(TN[., 1]) / 2 - (TN[., 1]:^2 :- 1) :/ (12 :* TN[., 1]) :* (1 / kml) +
                     (TN[., 1]:^4 :- 1) :/ (360 :* TN[., 1]:^3) :* (1 / kml)^3)) + quadsum(om :* ci)
            }
            // a constant that is still not finite leaves no likelihood
            if (hasmissing(ci)) ll = .
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
                if (kml <= 1e4) sk = om :* (Tp :* (digamma(Tp :* kml) :- digamma(kml)) + A)
                else            sk = om :* (Tp :* _xtgamfe_dlt(Tp, kml) + Bp)
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
            // The rank of the clustered covariance matrix cannot exceed
            // the number of distinct clusters less one (the cluster scores
            // are centered); a rounding-level pivot of invsym() must not
            // count beyond that bound.
            if (vcetype != "oim") rank_v = min((rank_v, (isfw & clid_name == "" ? G : M) - 1))
        }
        // The terms that vary within panels in only one cluster (from
        // 1.1.1): for each kept term, the number of clusters with a panel
        // in which it varies (copies of a frequency-weighted panel count
        // once: they are identical).  The clustered covariance cannot
        // assess such a term: its score is zero in every other cluster and
        // the total score is zero at the optimum, so its score in that
        // cluster is zero too, up to rounding and the convergence
        // tolerance, which the rank of e(V) need not reveal.
        if (vcetype != "oim") {
            if (clid_name != "") nclv = colsum(_xtgamfe_csum(Pv[., keep], clp, nc) :> 0)
            else                 nclv = colsum(Pv[., keep])
            nclf = J(1, Kfull, .)
            nclf[keep] = nclv
            st_matrix(ncl_name, nclf)
            // The coefficient directions that the other clusters do not
            // identify when one cluster is deleted, beyond those of the
            // terms counted above (from 1.1.1; _xtgamfe_ocdir): one row
            // each, in the units of the coefficients.
            OD = _xtgamfe_ocdir(X, info, pid, clp, Pv[., keep], ZZ[kpos, kpos], (clid_name == ""))
            if (rows(OD) > 0) {
                OD = OD :/ xscale
                nclf = J(rows(OD), Kfull, 0)
                nclf[., keep] = OD
                st_matrix(ocd_name, nclf)
            }
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
        // the offset was centered on its panel minimum (see the caller)
        if (oref_name != "") alpha = alpha - st_data(., oref_name, touse_name)[info[., 1]]
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
             Nw, Gw, min(Tp), Nw / Gw, max(Tp), fe_ok, kml_code, boundary,
             (isfw & clid_name == "" ? G : M))

    st_matrix(b_out, bfull)
    st_matrix(V_out, Vfull)
    st_matrix(omit_name, omit)
    st_matrix(stats_name, stats)
}
end
