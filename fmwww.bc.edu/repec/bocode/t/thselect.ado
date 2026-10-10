*! thselect 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! How many thresholds? Information criteria and a sequential bootstrap
*! test F(m+1|m), reported side by side with a full selection trace.
*! Gonzalo & Pitarakis (2002) JoE 110:319-352, doi:10.1016/S0304-4076(02)00098-2
*! Hansen (1999) J. Economic Surveys 13:551-576, doi:10.1111/1467-6419.00098

program define thselect, rclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        THRESHvar(varname numeric ts fv)             ///
        [ INVariant(varlist numeric fv ts)          ///
          MAXTHRESH(integer 3)                      ///
          TRIM(real 0.15)                           ///
          GRIDn(integer 0)                          ///
          REFINE(integer 0)                         ///
          MINOBS(integer 0)                         ///
          noCONStant                                ///
          TEST                                      ///
          REPS(integer 500)                         ///
          BOOT(string)                              ///
          SEED(string)                              ///
          ALPHA(real 0.10) ]

    if `maxthresh' < 1 | `maxthresh' > 10 {
        display as error "{bf:maxthresh()} must be between 1 and 10"
        exit 198
    }
    if `trim' < 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in [0, 0.5)"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    local hascons = cond("`constant'"=="", 1, 0)
    local dotest  = cond("`test'"!="", 1, 0)
    if "`boot'" == "" local boot wild
    if !inlist("`boot'", "wild", "normal") {
        display as error "boot() must be wild or normal"
        exit 198
    }
    local bootdgp `boot'
    local refinen `refine'

    marksample touse
    markout `touse' `threshvar' `invariant'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'
    quietly count if `touse'
    if r(N) == 0 error 2000

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

    * threshvar() may carry a time-series or factor operator -- thtar hands
    * one straight through as thvar(L.x) -- so it is materialised here. The
    * reported name stays the one the user typed.
    local qname "`threshvar'"
    fvrevar `threshvar' if `touse'
    local qvar `r(varlist)'
    mata: tk_thselect()

    tempname SS GG PP
    matrix `SS' = __tk_sel
    matrix `GG' = __tk_selg
    matrix `PP' = __tk_selp
    local n  = __tk_n
    local ng = __tk_ngrid

    * ---------------------------------------------- pick the IC minimisers
    local names aic bic hqic bicgp
    forvalues c = 3/6 {
        local best = .
        local bestm = .
        forvalues r = 1/`=rowsof(`SS')' {
            if `SS'[`r',`c'] < . {
                if `best' == . | `SS'[`r',`c'] < `best' {
                    local best = `SS'[`r',`c']
                    local bestm = `SS'[`r',1]
                }
            }
        }
        local j = `c' - 2
        local nm : word `j' of `names'
        local m_`nm' = `bestm'
    }

    * ---------------------------------------------- sequential decision
    local m_seq = 0
    if `dotest' {
        forvalues r = 1/`=rowsof(`PP')' {
            if `PP'[`r',2] < . & `PP'[`r',2] <= `alpha' {
                local m_seq = `r'
            }
            else {
                continue, break
            }
        }
    }

    * ---------------------------------------------- display
    display ""
    display as text "Selecting the number of thresholds"
    display as text "  Model: " as result "`depv'" as text " on " as result "`xlist'" ///
        cond(`hascons'," _cons","")
    display as text "  Threshold variable: " as result "`threshvar'" ///
        as text "   candidates: " as result "`ng'" ///
        as text "   trim: " as result %4.2f `trim' ///
        as text "   N = " as result `n'
    display ""
    display as text "{hline 78}"
    display as text "   m" _col(8) "SSR" _col(22) "AIC" _col(34) "BIC" _col(46) "HQIC" ///
        _col(58) "BIC-GP" _col(70) "thresholds"
    display as text "{hline 78}"
    forvalues r = 1/`=rowsof(`SS')' {
        local m = `SS'[`r',1]
        local gl ""
        if `m' > 0 {
            forvalues i = 1/`m' {
                local gv : display %8.0g `GG'[`m',`i']
                local gl "`gl' `=trim("`gv'")'"
            }
        }
        display as text "  `m'" _col(6) as result %11.6f `SS'[`r',2] ///
            _col(19) %10.3f `SS'[`r',3] _col(31) %10.3f `SS'[`r',4] ///
            _col(43) %10.3f `SS'[`r',5] _col(55) %10.3f `SS'[`r',6] ///
            _col(68) as text "`gl'"
    }
    display as text "{hline 78}"
    display as text "  minimised by:" _col(19) as result %10.0f `m_aic' ///
        _col(31) %10.0f `m_bic' _col(43) %10.0f `m_hqic' _col(55) %10.0f `m_bicgp' ///
        _col(68) as text "thresholds"
    display as text "{hline 78}"
    display as text "  BIC-GP is the Gonzalo-Pitarakis / official {bf:optthresh()} form,"
    display as text "  n*ln(SSR/n) + K*ln(n); AIC/BIC/HQIC are the usual likelihood forms."

    if `dotest' {
        display ""
        display as text "Sequential bootstrap test F(m+1 | m)"
        display as text "{hline 78}"
        display as text "  H0" _col(16) "H1" _col(30) "F statistic" _col(46) "boot p" _col(58) "MC s.e."
        display as text "{hline 78}"
        forvalues r = 1/`=rowsof(`PP')' {
            local m0 = `r' - 1
            local m1 = `r'
            if `PP'[`r',1] >= . continue
            display as text "  `m0' threshold(s)" _col(16) "`m1' threshold(s)" ///
                _col(28) as result %12.4f `PP'[`r',1] ///
                _col(44) %10.4f `PP'[`r',2] _col(56) as text %9.4f `PP'[`r',3]
        }
        display as text "{hline 78}"
        display as text "  Stop at the first non-rejection: selected " as result "`m_seq'" ///
            as text " threshold(s) at alpha = " as result %4.2f `alpha' as text "."
        display as text "  DGP: " as result cond("`boot'"=="wild", ///
            "wild bootstrap (each observation keeps its own residual scale)", ///
            "iid normal draws, Hansen's fixed-regressor convention")
        display as text "       on the fitted m-threshold model, regressors and the threshold"
        display as text "       variable held fixed; `reps' replications."
        display as text "  The statistic is the homoskedastic F; the p-value is simulated, so"
        display as text "  with {bf:boot(wild)} it is heteroskedasticity-robust. The two DGPs can"
        display as text "  give visibly different p-values: report which you used."
    }

    display ""
    if `dotest' {
        display as text "  {bf:Recommendation}: report the sequential test as the headline and"
        display as text "  the information criteria as a robustness check. When they disagree"
        display as text "  the extra threshold is weakly identified: say so."
    }
    else {
        display as text "  {it:note}: information criteria are model selection, not inference."
        display as text "  Add {bf:test} for the bootstrap sequential test with p-values."
    }

    * ---------------------------------------------- return
    matrix colnames `SS' = m ssr aic bic hqic bic_gp
    matrix colnames `PP' = F p mcse
    return matrix table = `SS'
    return matrix thresholds = `GG'
    if `dotest' return matrix seqtest = `PP'
    return scalar N       = `n'
    return scalar n_grid  = `ng'
    return scalar m_aic   = `m_aic'
    return scalar m_bic   = `m_bic'
    return scalar m_hqic  = `m_hqic'
    return scalar m_bicgp = `m_bicgp'
    if `dotest' {
        return local  boot "`boot'"
        return scalar m_seq = `m_seq'
        return scalar alpha = `alpha'
        return scalar reps  = `reps'
    }
    return local threshvar "`threshvar'"
    return local cmd "thselect"

    _tk_drop
end
