*! thnregimes 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! How many regimes? The FULL triangle of sequential threshold tests F(j | i)
*! for every i < j -- Hansen's (1999) F12 / F13 / F23 battery generalised to
*! any number of thresholds -- with a choice of bootstrap, including the
*! RECURSIVE (model-based) bootstrap that an autoregressive design requires.
*! Hansen (1999) J. Economic Surveys 13:551-576, doi:10.1111/1467-6419.00098
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Gonzalo & Pitarakis (2002) JoE 110:319-352, doi:10.1016/S0304-4076(02)00098-2

program define thnregimes, rclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] ,  ///
        THRESHvar(varname numeric ts)                ///
        [ INVariant(varlist numeric fv ts)           ///
          MAXTHRESH(integer 2)                       ///
          TRIM(real 0.15)                            ///
          GRIDn(integer 0)                           ///
          REFINE(integer 0)                          ///
          MINOBS(integer 0)                          ///
          noCONStant                                 ///
          REPS(integer 500)                          ///
          BOOT(string)                               ///
          ARLags(numlist integer >0 sort)            ///
          QLag(integer 0)                            ///
          SEED(string)                               ///
          ALPHA(real 0.10) ]

    if `maxthresh' < 1 | `maxthresh' > 6 {
        display as error "{bf:maxthresh()} must be between 1 and 6"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} must be 0 or more"
        exit 198
    }
    if `alpha' <= 0 | `alpha' >= 1 {
        display as error "{bf:alpha()} must be in (0, 1)"
        exit 198
    }
    if "`boot'" == "" local boot normal
    local dgpnum = .
    if "`boot'" == "normal"    local dgpnum 1
    if "`boot'" == "wild"      local dgpnum 2
    if "`boot'" == "recursive" local dgpnum 3
    if "`boot'" == "recwild"   local dgpnum 4
    if `dgpnum' == . {
        display as error "boot() must be normal, wild, recursive or recwild"
        exit 198
    }
    local isrec = cond(`dgpnum' >= 3, 1, 0)
    if `isrec' & "`arlags'" == "" {
        display as error "{bf:boot(recursive)} rebuilds the series forward from the"
        display as error "fitted model, so it must be told which regressors are lags"
        display as error "of the dependent variable: give {bf:arlags(numlist)} listing"
        display as error "their lag orders, in the order they appear in the varlist."
        display as error "With exogenous regressors use {bf:boot(normal)} or {bf:boot(wild)}."
        exit 198
    }
    if !`isrec' & "`arlags'" != "" {
        display as error "{bf:arlags()} is only used by {bf:boot(recursive)} or {bf:boot(recwild)}"
        exit 198
    }
    if `qlag' < 0 {
        display as error "{bf:qlag()} must be 0 or more"
        exit 198
    }
    if `qlag' > 0 & !`isrec' {
        display as error "{bf:qlag()} rebuilds the threshold variable, which only a"
        display as error "recursive bootstrap does"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    local hascons = cond("`constant'"=="", 1, 0)
    local refinen `refine'

    marksample touse
    markout `touse' `threshvar' `invariant'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'

    local xlist ""
    local xvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local xlist `r(varlist)'
        fvrevar `xlist' if `touse'
        local xvars `r(varlist)'
    }
    local zlist ""
    local zvars ""
    if "`invariant'" != "" {
        fvexpand `invariant' if `touse'
        local zlist `r(varlist)'
        fvrevar `zlist' if `touse'
        local zvars `r(varlist)'
    }
    if "`xlist'" == "" & `hascons' == 0 {
        display as error "no regressors to test for a threshold effect"
        exit 102
    }
    markout `touse' `xvars' `zvars'
    quietly count if `touse'
    if r(N) < 20 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

    * ---- map arlags() onto the columns of X. The lag orders are given in the
    *      order the variables appear in the varlist, so position j of arlags()
    *      is column j of X.
    local arposl ""
    local arlagl ""
    if "`arlags'" != "" {
        local nx : word count `xlist'
        local na : word count `arlags'
        if `na' > `nx' {
            display as error "{bf:arlags()} lists `na' lags but there are only `nx' regressors"
            exit 198
        }
        local j 0
        foreach L of local arlags {
            local ++j
            local arposl `arposl' `j'
            local arlagl `arlagl' `L'
        }
        if `qlag' > 0 {
            capture tsset
            if _rc {
                display as error "{bf:qlag()} needs the data {bf:tsset}"
                exit 459
            }
        }
    }
    local qlagn `qlag'
    local qvar `threshvar'

    _tk_drop __tk_tri __tk_nrsel
    mata: tk_thnregimes()

    tempname TRI SS
    matrix `TRI' = __tk_tri
    matrix `SS'  = __tk_nrsel
    matrix colnames `TRI' = m0 m1 F p mcse reps_used
    matrix colnames `SS'  = m SSR aic bic hqic bic_gp
    local ng = __tk_ngrid
    _tk_drop __tk_tri __tk_nrsel
    _tk_drop __tk_n __tk_ngrid

    * ---- how many regimes does the sequence choose?
    *      stop at the first non-rejection of the adjacent test, which is the
    *      sequential rule; report it as a rule, not as a truth.
    local mseq 0
    forvalues m = 0/`=`maxthresh'-1' {
        local found 0
        forvalues r = 1/`=rowsof(`TRI')' {
            if `TRI'[`r',1] == `m' & `TRI'[`r',2] == `=`m'+1' {
                local pv = `TRI'[`r',4]
                local found 1
            }
        }
        if `found' & `pv' < . {
            if `pv' <= `alpha' local mseq = `m' + 1
            else continue, break
        }
        else continue, break
    }

    local blab "fixed regressors, iid normal errors"
    if `dgpnum' == 2 local blab "fixed regressors, wild errors"
    if `dgpnum' == 3 local blab "recursive (model based), resampled errors"
    if `dgpnum' == 4 local blab "recursive (model based), wild errors"

    display _n as text "How many regimes? Sequential threshold tests" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc `nobs'
    display as text "  Dependent variable: " as result "`depv'" _col(52) ///
        as text "Grid points" _col(68) "=" _col(71) as result %9.0f `ng'
    display as text "  Threshold variable: " as result "`threshvar'" _col(52) ///
        as text "Replications" _col(68) "=" _col(71) as result %9.0f `reps'
    display as text "  Bootstrap: " as result "`blab'"
    if `qlag' > 0 {
        display as text "  The threshold variable is rebuilt as lag `qlag' of the"
        display as text "  simulated series, and its grid with it."
    }
    display ""
    display as text "{hline 78}"
    display as text "  Model fit by number of thresholds"
    display as text "    m" _col(14) "SSR" _col(28) "AIC" _col(40) "BIC" ///
        _col(52) "HQIC" _col(64) "BIC-GP"
    display as text "{hline 78}"
    forvalues r = 1/`=rowsof(`SS')' {
        display as text "    " as result %2.0f `SS'[`r',1] ///
            _col(8) %12.6f `SS'[`r',2] _col(22) %11.3f `SS'[`r',3] ///
            _col(34) %11.3f `SS'[`r',4] _col(46) %11.3f `SS'[`r',5] ///
            _col(58) %11.3f `SS'[`r',6]
    }
    display as text "{hline 78}"
    display as text "  Sequential tests: H0 = i thresholds against H1 = j thresholds"
    display as text "    test" _col(16) "F" _col(30) "boot p" _col(42) "MC s.e." ///
        _col(54) "reps used"
    display as text "{hline 78}"
    forvalues r = 1/`=rowsof(`TRI')' {
        local i0 = `TRI'[`r',1]
        local i1 = `TRI'[`r',2]
        local lab "F(`=`i1'+1'|`=`i0'+1')"
        display as text "    " as result %-10s "`lab'" ///
            _col(12) %12.4f `TRI'[`r',3] _col(28) %8.4f `TRI'[`r',4] ///
            _col(40) %8.4f `TRI'[`r',5] _col(54) %8.0f `TRI'[`r',6]
    }
    display as text "{hline 78}"
    display as text "  Labels are in REGIMES, not thresholds: F(2|1) is one threshold"
    display as text "  against none, F(3|1) is two thresholds against none, and so on."
    display as text "  Sequential rule at alpha = " as result %4.2f `alpha' as text ///
        ": " as result "`mseq'" as text " threshold(s), " ///
        as result "`=`mseq'+1'" as text " regime(s)."
    display as text "{hline 78}"
    display as text "  The sequential rule stops at the FIRST adjacent test that does"
    display as text "  not reject. The non-adjacent tests F(3|1), F(4|1), ... are there"
    display as text "  because the sequence can stop early: a model with two thresholds"
    display as text "  can be far better than one with none while the one-threshold"
    display as text "  model in between is not, and then F(2|1) fails to reject and the"
    display as text "  sequence never looks further. Read F(3|1) before accepting it."
    if `dgpnum' <= 2 {
        display as text "  The regressors were held FIXED. For an autoregression that is"
        display as text "  wrong -- the regressors are lags of the dependent variable, so"
        display as text "  they must be rebuilt with it. Use {bf:boot(recursive)} with"
        display as text "  {bf:arlags()} (and {bf:qlag()} for a self-exciting threshold)."
    }
    display as text "  Having chosen the number of regimes this way, every p-value"
    display as text "  reported afterwards is conditional on that choice."

    return matrix seqtri = `TRI'
    return matrix table  = `SS'
    return scalar m_seq  = `mseq'
    return scalar N      = `nobs'
    return scalar n_grid = `ng'
    return scalar reps   = `reps'
    return scalar alpha  = `alpha'
    return local  boot   "`boot'"
    return local  threshvar "`threshvar'"
    return local  cmd    "thnregimes"
end
