*! tvtsel 1.0.0  14oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Which TVTHRESH specification does this dataset call for? Runs the
*! library's own diagnostics in order and reports a ranked recommendation
*! with the evidence behind it.
*!
*! This implements no estimator and replicates no paper. It is glue: every
*! number it reports is produced by one of the library's own commands, and
*! it says which. The companion prose guide is tvthresh_choose.

program define tvtsel, rclass
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] ,  ///
        THReshvar(varname numeric ts)                ///
        [ Zvars(varlist numeric)                     ///
          REPS(integer 0)                            ///
          TRIM(real 0.15)                            ///
          NGrid(integer 9)                           ///
          SIMreps(integer 200)                       ///
          Level(cilevel)                             ///
          noCONStant                                 ///
          QUICK                                      ///
          noDETail ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `ngrid' < 3 {
        display as error "{bf:ngrid()} must be at least 3"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is the threshold variable and" ///
                " cannot also be a regressor"
            exit 198
        }
    }
    foreach v of local zvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' cannot also appear in" ///
                " {bf:zvars()}"
            exit 198
        }
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar' `zvars'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 20 {
        display as error "too few observations (`nobs') to diagnose" ///
            " anything"
        exit 2001
    }

    * The user's own estimation results are protected: this command runs
    * several estimators internally and would otherwise leave the last one
    * of them in e(). restore nullok puts back whatever was there, even if
    * there was nothing.
    tempname hold
    capture _estimates hold `hold', restore nullok

    local p : word count `xvars'
    local nz : word count `zvars'
    local univ = (`p' == 0)

    * ============================================================ step 0
    * The shape of the data. No estimation, so this is free, and it rules
    * specifications in and out before any test is run.
    * ------------------------------------------------------------------
    * a count dependent variable needs an integer-valued model, not a
    * Gaussian one, however the threshold behaves
    tempvar nonint
    quietly generate byte `nonint' = ///
        (`depv' != int(`depv') | `depv' < 0) if `touse'
    quietly count if `nonint' == 1 & `touse'
    local iscount = (r(N) == 0)

    * high dimension: the slope block is 2p once regimes are allowed
    local hidim = (2*`p' >= 0.5*`nobs')

    * is the threshold variable plausibly I(1)? A near-unit-root threshold
    * variable with I(1) regressors is the cointegration case.
    local rho = .
    capture {
        tempvar lq
        quietly generate double `lq' = `threshvar'[_n-1] if `touse'
        quietly regress `threshvar' `lq' if `touse'
        local rho = _b[`lq']
    }
    local i1 = 0
    if `rho' < . {
        if `rho' > 1 - 5/`nobs' local i1 = 1
    }

    display _n as text "{hline 78}"
    display as text "tvtsel: which TVTHRESH specification does this data" ///
        " call for?"
    display as text "{hline 78}"
    display as text "  observations" _col(32) "=" _col(36) as result ///
        %10.0fc `nobs'
    display as text "  regressors besides the threshold" _col(32) "=" ///
        _col(36) as result %10.0f `p'
    display as text "  candidate threshold movers (zvars)" _col(32) "=" ///
        _col(36) as result %10.0f `nz'
    display as text "  dependent variable" _col(32) "=" _col(36) as result ///
        %10s cond(`iscount', "counts", "continuous")
    display as text "  threshold variable AR(1) coefficient" _col(32) "=" ///
        _col(36) as result %10.4f `rho'
    display ""

    * ============================================================ step 1
    * IS THE THRESHOLD CONSTANT? This is the question the whole library
    * turns on, and tvthomog is the command built to answer it.
    * ------------------------------------------------------------------
    local ct = .
    local ctcv = .
    local ctrej = .
    display as text "  {bf:1. Is the threshold constant?}" ///
        _col(56) as text "{it:tvthomog}"
    capture noisily quietly tvthomog `depv' `xvars' if `touse', ///
        threshvar(`threshvar') trim(`trim') level(`level') `constant'
    if _rc {
        display as text "     tvthomog could not run (rc = " as result _rc ///
            as text "); skipped"
    }
    else {
        local ct   = r(CT)
        local ctcv = r(cv)
        local ctrej = r(reject)
        display as text "     CT = " as result %9.4f `ct' ///
            as text "   `level'% critical value " as result %9.4f `ctcv' ///
            as text "   =>  " as result ///
            cond(`ctrej', "the threshold MOVES", "constant is not rejected")
    }

    * ============================================================ step 2
    * IS THERE A THRESHOLD EFFECT AT ALL? For a univariate series tvtlr
    * answers it with a distribution-free pivotal limit -- no bootstrap,
    * nothing to tune -- so it is nearly free and is always run.
    * ------------------------------------------------------------------
    local zlr = .
    local zlrrej = .
    if `univ' {
        display as text "  {bf:2. Is there a threshold effect at all?}" ///
            _col(56) as text "{it:tvtlr}"
        capture noisily quietly tvtlr `depv' if `touse', level(`level')
        if _rc {
            display as text "     tvtlr could not run (rc = " as result ///
                _rc as text "); skipped"
        }
        else {
            local zlr = r(Z)
            local zlrrej = r(reject)
            display as text "     Z = " as result %9.4f `zlr' ///
                as text "   `level'% critical value " as result %9.4f r(cv) ///
                as text "   =>  " as result ///
                cond(`zlrrej', "a threshold IS present", "no threshold effect")
        }
    }
    else {
        display as text "  {bf:2. Is there a threshold effect at all?}" ///
            _col(56) as text "{it:tvtfourier}"
        if `reps' == 0 & "`quick'" == "" {
            display as text "     needs a bootstrap: rerun with" ///
                " {bf:reps(399)} or more for F1 and F2"
        }
    }

    * ============================================================ step 3
    * IF IT MOVES, WHAT MOVES IT? Three answers are possible and the
    * library keeps them apart deliberately: TIME, the threshold
    * variable's OWN PAST, or OTHER OBSERVED VARIABLES. Only the first
    * and third can be tested here with what the user has supplied.
    * ------------------------------------------------------------------
    local f1 = .
    local p1 = .
    local f2 = .
    local p2 = .
    if `reps' > 0 & "`quick'" == "" {
        display as text "  {bf:3. Does it move with TIME (Fourier)?}" ///
            _col(56) as text "{it:tvtfourier}"
        capture noisily quietly tvtfourier `depv' `xvars' if `touse', ///
            threshvar(`threshvar') trim(`trim') ngrid(`ngrid') ///
            reps(`reps') noci level(`level') `constant'
        if _rc {
            display as text "     tvtfourier could not run (rc = " ///
                as result _rc as text "); skipped"
        }
        else {
            local f1 = e(F1)
            local p1 = e(p1)
            local f2 = e(F2)
            local p2 = e(p2)
            display as text "     F1 (no threshold effect)   = " ///
                as result %9.4f `f1' as text "   p = " as result %6.3f `p1'
            display as text "     F2 (threshold is constant) = " ///
                as result %9.4f `f2' as text "   p = " as result %6.3f `p2'
        }
    }

    local sc = .
    local screj = .
    if `nz' > 0 & `univ' == 0 {
        display as text "  {bf:4. Does it move with your zvars?}" ///
            _col(56) as text "{it:tvtboundary}"
        capture noisily quietly tvtboundary `depv' `xvars' if `touse', ///
            threshvar(`threshvar') zvars(`zvars') simreps(`simreps') ///
            level(`level') `constant'
        if _rc {
            display as text "     tvtboundary could not run (rc = " ///
                as result _rc as text "); skipped"
        }
        else {
            local sc = e(score)
            local screj = (e(p_score) < (100-`level')/100)
            display as text "     score = " as result %9.4f `sc' ///
                as text "   p = " as result %6.3f e(p_score) ///
                as text "   =>  " as result ///
                cond(`screj', "zvars DO move it", "no evidence they do")
        }
    }

    * ============================================================
    * THE RECOMMENDATION. Ranked, with the reason attached to each line,
    * so that it can be disagreed with.
    * ============================================================
    display _n as text "{hline 78}"
    display as text "  {bf:RECOMMENDATION}"
    display as text "{hline 78}"

    local nrec 0
    local nfam 0
    local primary ""

    * counts override everything else: a Gaussian threshold model is the
    * wrong family for integer data no matter how the threshold behaves
    if `iscount' {
        local ++nrec
        local primary "tvtinar"
        display as text "  `nrec'. " as result "tvtinar" as text ///
            " {hline 2} `depv' is a non-negative integer count."
        display as text "        A Gaussian threshold model is the wrong" ///
            " family here whatever the"
        display as text "        threshold does. {bf:Not yet implemented}" ///
            " in this library."
    }

    if `hidim' {
        local ++nrec
        if "`primary'" == "" local primary "tvtlasso"
        display as text "  `nrec'. " as result "tvtlasso" as text ///
            " {hline 2} 2 x `p' slope terms against `nobs' observations."
        display as text "        That is high-dimensional: the" ///
            " specification needs selecting, not fixing."
        display as text "        See also {helpb tvtcovdep} if you think" ///
            " covariates move the threshold."
    }

    * THE "MOVES" CONDITION MUST INCLUDE EVERY TEST THAT WAS RUN. An
    * earlier version keyed only on tvthomog and on F2, so a score test
    * that had just printed "zvars DO move it" was computed, displayed,
    * and then ignored by the ranking, which went on to recommend a
    * constant threshold on the same screen. Contradicting its own output
    * is worse than being wrong.
    local alpha = (100-`level')/100
    local moves = (`ctrej' == 1 | `p2' < `alpha' | `screj' == 1)
    local conflict = (`ctrej' == 0 & (`p2' < `alpha' | `screj' == 1))

    if `moves' {
        if `i1' {
            local ++nrec
            if "`primary'" == "" local primary "tvtcoint"
            local ++nfam
            display as text "  `nrec'. " as result "tvtcoint" as text ///
                " {hline 2} the threshold moves and " ///
                "`threshvar' is near a unit root"
            display as text "        (AR(1) coefficient " as result ///
                %6.4f `rho' as text "), so this is the cointegrating case."
        }
        if `screj' == 1 {
            local ++nrec
            if "`primary'" == "" local primary "tvtboundary"
            local ++nfam
            display as text "  `nrec'. " as result "tvtboundary" as text ///
                " {hline 2} your zvars move the threshold" ///
                " (score test rejects)."
            display as text "        Use {helpb tvtstar} instead if you" ///
                " want a SMOOTH transition, or"
            display as text "        {helpb tvtcovdep} to choose which" ///
                " zvars matter."
        }
        if `p2' < `alpha' {
            local ++nrec
            if "`primary'" == "" local primary "tvtfourier"
            local ++nfam
            display as text "  `nrec'. " as result "tvtfourier" as text ///
                " {hline 2} F2 rejects a constant threshold" ///
                " (p = " as result %5.3f `p2' as text ")."
            display as text "        The threshold drifts with TIME." ///
                " {bf:But see the warning below.}"
        }
        if `nrec' == 0 | ("`primary'" == "") {
            local ++nrec
            local primary "tvtfourier"
            display as text "  `nrec'. " as result "tvtfourier" as text ///
                " {hline 2} tvthomog rejects a constant threshold," ///
                " but nothing here"
            display as text "        says WHAT moves it. Try each family" ///
                " and compare:"
            display as text "        TIME {helpb tvtfourier}," ///
                " OWN PAST {helpb tvtcotar} / {helpb tvtcotrk},"
            display as text "        OTHER VARIABLES {helpb tvtcoint} /" ///
                " {helpb tvtboundary} / {helpb tvtstar}."
        }
    }
    else if `ctrej' == 0 {
        local ++nrec
        if "`primary'" == "" local primary "constant threshold"
        display as text "  `nrec'. " as result "a CONSTANT threshold" ///
            as text " {hline 2} tvthomog does not reject it."
        display as text "        Nothing in this library is needed:" ///
            " fit a standard threshold model."
        display as text "        A non-rejection is weak evidence though" ///
            " {hline 2} see the warning below."
    }

    * TWO FAMILIES REJECTING IS NOT A RANKING. The three ways a threshold
    * can move are not nested, so a test built for one rejects under the
    * others as well; when more than one rejects, the order they happen to
    * be printed in carries no information and must not be allowed to look
    * as though it does.
    if `nfam' >= 2 {
        display as text ""
        display as text "  {bf:`nfam' families' tests reject, and the" ///
            " numbering above is NOT a}"
        display as text "  {bf:ranking between them.} They are not" ///
            " nested: a test built for one"
        display as text "  family rejects when a different one is true." ///
            " Nothing here can tell"
        display as text "  you which, and the p-values cannot be" ///
            " compared across them. Fit"
        display as text "  each candidate and compare on fit and on" ///
            " whether the estimated"
        display as text "  threshold path is one your subject matter" ///
            " can account for."
    }

    if `conflict' {
        display as text ""
        display as text "  {bf:THE DIAGNOSTICS DISAGREE.} tvthomog does" ///
            " not reject a constant"
        display as text "  threshold, but a test above does. That is not" ///
            " a contradiction to be"
        display as text "  resolved by picking one: the tests have" ///
            " different alternatives, and"
        display as text "  tvthomog's power against a SMOOTH drift or a" ///
            " covariate-driven"
        display as text "  threshold is not the same as its power" ///
            " against a step. Treat the"
        display as text "  evidence as mixed and fit both, then compare" ///
            " on the ranked list above."
    }

    if `univ' & `zlrrej' == 0 {
        display as text ""
        display as text "  Note: {bf:tvtlr found no threshold effect at" ///
            " all} in `depv'. If that is"
        display as text "  right, the question of how a threshold moves" ///
            " does not arise."
    }

    * ---- the warning that matters most, and it is not optional
    display _n as text "{hline 78}"
    display as text "  {bf:HOW TO READ THIS}"
    display as text "{hline 78}"
    display as text "  {bf:A non-rejection is not evidence of a constant" ///
        " threshold.} The power of"
    display as text "  these tests against a STEP change is low: from" ///
        " tvtfourier's own source"
    display as text "  paper, about 0.21 at T = 100 against a single" ///
        " abrupt shift, and still"
    display as text "  only 0.57 at T = 500. If the mechanism you have in" ///
        " mind is a dated"
    display as text "  event, a non-rejection here tells you very little."
    display as text ""
    display as text "  {bf:A rejection does not tell you WHICH family.}" ///
        " The three ways a"
    display as text "  threshold can move {hline 2} with time, with its" ///
        " own past, with other"
    display as text "  variables {hline 2} are not nested, and a test" ///
        " against one of them"
    display as text "  rejects under the others too. The ranking above" ///
        " uses what you"
    display as text "  supplied; it cannot rank a family you gave it no" ///
        " way to test."
    display as text ""
    display as text "  Read {helpb tvthresh_choose} before committing to" ///
        " a specification."
    display as text "{hline 78}"
    if "`detail'" != "nodetail" {
        display as text "  Every number above came from" ///
            " {helpb tvthomog}, {helpb tvtlr},"
        display as text "  {helpb tvtfourier} or {helpb tvtboundary}." ///
            " tvtsel fits nothing itself."
        display as text "{hline 78}"
    }

    * ------------------------------------------------------------ returns
    return scalar N         = `nobs'
    return scalar p         = `p'
    return scalar nz        = `nz'
    return scalar iscount   = `iscount'
    return scalar hidim     = `hidim'
    return scalar rho       = `rho'
    return scalar i1        = `i1'
    return scalar CT        = `ct'
    return scalar CT_cv     = `ctcv'
    return scalar CT_reject = `ctrej'
    return scalar Z         = `zlr'
    return scalar Z_reject  = `zlrrej'
    return scalar F1        = `f1'
    return scalar p_F1      = `p1'
    return scalar F2        = `f2'
    return scalar p_F2      = `p2'
    return scalar score     = `sc'
    return scalar score_reject = `screj'
    return scalar n_rec     = `nrec'
    return scalar n_family  = `nfam'
    return local  primary   "`primary'"
    return local  depvar    "`depv'"
    return local  indepvars "`xvars'"
    return local  threshvar "`threshvar'"
    return local  zvars     "`zvars'"
    return local  cmd       "tvtsel"
end
