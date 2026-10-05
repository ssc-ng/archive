*! _bd_model.ado — build the bootdiag model container from e()
*! Version 1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Every supported command is reduced to one uniform LEVELS representation
*!     y_t = sum_{j=1..p} a_j y_{t-j}
*!         + sum_i sum_{l=0..q_i} b_il x_{i,t-l}
*!         + d_t'g + u_t
*! which is what the recursive bootstrap needs.  The conditional ECM is
*! then a reparameterisation of it, built inside Mata.
*!
*! The rebuild is VERIFIED against the fit statistics the original command
*! reported.  If they disagree beyond tol the program errors out rather
*! than returning a silently wrong result.

program define _bd_model, rclass
    version 16.0
    syntax [,                      ///
        YLev(string)               ///
        XLev(string)               ///
        P(integer -1)              ///
        Q(numlist integer >=0)     ///
        DET(string)                ///
        CASE(integer -1)           ///
        TOLerance(real 0.0001)       ///
        noVERify                   ///
        TOUSE(string)              ///
    ]

    local cmd "`e(cmd)'"
    local verified 0
    local note ""

    * =================================================================
    * A. Fully explicit specification by the user
    * =================================================================
    if "`ylev'" != "" {
        local src "user"
        if `p' < 0 local p = 1
        if "`q'" == "" {
            local q ""
            foreach v of local xlev {
                local q "`q' 0"
            }
        }
        if `case' < 0 local case 3
    }
    else {
        * =============================================================
        * B. Recover the ESTIMATED EQUATION, then parse it
        * =============================================================
        * The regressor list is authoritative; e(p)/e(q_*) are not,
        * because each command labels its lag orders differently.
        if "`cmd'" == "" {
            di as err "{bf:bootdiag}: no estimation results found."
            di as err "Run a supported command first, or specify ylev()/xlev()."
            exit 301
        }

        local dv  "`e(depvar)'"
        local rhs ""
        local src ""

        if inlist("`cmd'", "regress", "newey", "prais") {
            capture local nm : colnames e(b)
            if _rc | "`nm'" == "" {
                di as err "{bf:`cmd'} left no coefficient vector."
                exit 301
            }
            local rhs "`nm'"
            local src "`cmd' e(b) colnames"
        }
        else if "`cmd'" == "ardl" {
            local rhs "`e(regressors)'"
            local src "ardl e(regressors)"
        }
        else if "`cmd'" == "aardl" {
            local rhs "`e(ecmvars)'"
            local dv  "D.`e(depvar)'"
            local src "aardl e(ecmvars)"
            * aardl KEEPS its constructed columns, so add any that exist
            capture confirm variable _aardl_sin
            if !_rc local rhs "`rhs' _aardl_sin _aardl_cos"
            capture confirm variable _aardl_trend
            if !_rc & inlist(e(case), 4, 5) local rhs "`rhs' _aardl_trend"
            if e(case) >= 3 local rhs "`rhs' _cons"
        }
        else if "`e(bdvars)'" != "" {
            * fbardl 1.3.1+, fbnardl 2.0.1+, mtnardl 1.0.1+ record the
            * regressor list in e(bdvars) and rebuild the columns they
            * constructed (Fourier terms, asymmetric partial sums,
            * threshold regimes) after restore, precisely so that
            * post-estimation commands can recover the equation.
            local rhs "`e(bdvars)'"
            local dv  "`e(bddepvar)'"
            if "`dv'" == "" local dv "D.`e(depvar)'"
            local src "`cmd' e(bdvars)"
        }
        else {
            * Older fbardl / fbnardl / mtnardl post no coefficient vector
            * AND drop the columns they built inside preserve/restore, so
            * there is nothing left to reconstruct from.
            di as err ""
            di as err "{bf:bootdiag}: this version of {bf:`cmd'} does not leave"
            di as err "its estimated equation behind -- it posts no e(b), drops"
            di as err "the variables it constructed, and sets no e(bdvars)."
            di as err ""
            di as err "Either update {bf:`cmd'} to a bootdiag-aware version, or"
            di as err "give the equation explicitly:"
            di as err "    bootdiag all, ylev({it:y}) xlev({it:x z}) p(#) q({it:# #})"
            di as err ""
            di as err "See {bf:help bootdiag##ardlfamily}."
            exit 301
        }

        if trim("`rhs'") == "" {
            di as err "{bf:bootdiag}: could not read the regressor list from `cmd'."
            exit 301
        }

        _bd_parse, depvar("`dv'") rhs("`rhs'")
        local ylev  "`r(ylev)'"
        local xlev  "`r(xlev)'"
        local q     "`r(qlist)'"
        local p     = r(p)
        local extra "`r(det)'"

        * deterministics found in the regressor list
        local case 3
        local hastr 0
        foreach d of local extra {
            if "`d'" == "_cons" continue
            capture confirm variable `d'
            if !_rc {
                local userdet "`userdet' `d'"
                local hastr 1
            }
        }
        if `hastr' local case 3
    }

    * =================================================================
    * C. Deterministics implied by the PSS case
    *      case 1 : none
    *      case 2 : restricted constant  -> constant in the regression
    *      case 3 : unrestricted constant
    *      case 4 : restricted trend     -> constant + trend
    *      case 5 : unrestricted trend   -> constant + trend
    * =================================================================
    tempvar cons trend
    qui gen byte   `cons'  = 1
    local detlist "`cons'"
    if inlist(`case', 4, 5) {
        qui gen double `trend' = _n
        local detlist "`detlist' `trend'"
    }
    if `case' == 1 local detlist ""

    * Fourier terms, if the fitting command used them
    local kstar = e(best_kstar)
    if `kstar' >= . local kstar = e(kstar)
    tempvar fsin fcos
    if `kstar' < . & `kstar' > 0 {
        qui count
        local TT = r(N)
        qui gen double `fsin' = sin(2*c(pi)*`kstar'*_n/`TT')
        qui gen double `fcos' = cos(2*c(pi)*`kstar'*_n/`TT')
        local detlist "`detlist' `fsin' `fcos'"
        local note "`note' Fourier k*=`kstar' included."
    }
    if "`det'" != "" local detlist "`detlist' `det'"
    * extra deterministic / exogenous columns found in the regressor list
    * (Fourier terms, trends, dummies) -- held fixed in the bootstrap
    if "`userdet'" != "" local detlist "`detlist' `userdet'"

    * =================================================================
    * D. Hand the pieces to Mata
    * =================================================================
    if "`touse'" == "" {
        tempvar touse
        qui gen byte `touse' = 1
    }
    * require every model variable to be present
    markout `touse' `ylev' `xlev' `detlist'

    local np : word count `xlev'
    local nq : word count `q'
    if `np' != `nq' {
        di as err "{bf:bootdiag}: internal mismatch, `np' regressors but `nq' lag orders."
        exit 198
    }

    local qmata = subinstr(trim("`q'"), " ", ",", .)
    if "`qmata'" == "" local qmata "."

    * Align the rebuilt sample with the one the fitting command used.
    * The ARDL commands fix the sample at maxlag+1 so that every model
    * in the lag search is compared on a common sample; the selected p
    * is often smaller, so t0 = max(p,q)+1 would be one observation too
    * early and the fit would not reproduce.
    local ntarget = e(N)
    if `ntarget' >= . local ntarget 0

    mata: bd_load("`ylev'", "`xlev'", "`detlist'", `p', ///
                  (`qmata'), 1, "`touse'", `ntarget')

    * =================================================================
    * E. Verify the rebuild against what the command reported
    * =================================================================
    * The conditional ECM is an exact linear reparameterisation of the
    * levels ARDL, so the RESIDUALS -- and hence the residual sum of
    * squares -- are identical in the two forms.  RSS is therefore the
    * right invariant to verify against.  R-squared is NOT: it changes
    * with the dependent variable (y in levels vs D.y in the ECM).
    local rssrep = e(rss)
    local ecmrep = e(ecm_coef)
    local okmsg  "not checked"

    if "`verify'" == "" {
        mata: bd_fitstats()
        local rssgot = r(bd_rss)
        local ecmgot = r(bd_ecm)
        local ngot   = r(bd_n)

        local bad 0
        local dmax 0
        local what ""

        if `rssrep' < . & `rssgot' < . & `rssrep' > 0 {
            local d = abs(`rssgot' - `rssrep') / `rssrep'
            if `d' > `dmax' local dmax = `d'
            if `d' > `tolerance' {
                local bad 1
                local what "RSS"
            }
        }
        else if `ecmrep' < . & `ecmgot' < . {
            local d = abs(`ecmgot' - `ecmrep')
            if `d' > `dmax' local dmax = `d'
            if `d' > `tolerance' {
                local bad 1
                local what "speed of adjustment"
            }
        }
        else local okmsg "no comparable statistic in e(); not verified"

        if `bad' {
            di as err ""
            di as err "{bf:bootdiag}: could not reproduce the fitted model from e()."
            if "`what'" == "RSS" {
                di as err "  reported RSS = " %12.6f `rssrep' ///
                          "   rebuilt RSS = " %12.6f `rssgot'
            }
            else {
                di as err "  reported ecm = " %12.6f `ecmrep' ///
                          "   rebuilt ecm = " %12.6f `ecmgot'
            }
            di as err "  relative discrepancy = " %9.3e `dmax' ///
                      " (tolerance `tolerance')"
            di as err "  rebuilt model: p = `p', q = (`q'), case `case', N = `ngot'"
            di as err ""
            di as err "This usually means {bf:`cmd'} used options bootdiag cannot see"
            di as err "(extra exogenous regressors, a different deterministic case,"
            di as err "or a transformed regressor). Specify the model explicitly:"
            di as err "    bootdiag ..., ylev({it:y}) xlev({it:xlist}) p(#) q({it:numlist})"
            exit 459
        }
        if "`okmsg'" == "not checked" {
            local verified 1
            local okmsg = "verified on " + cond("`what'"=="", "RSS", "`what'") + ///
                          " (rel. diff " + string(`dmax', "%7.1e") + ")"
        }
    }

    return local cmd      "`cmd'"
    return local source   "`src'"
    return local ylev     "`ylev'"
    return local xlev     "`xlev'"
    return local qlist    "`q'"
    return scalar p       = `p'
    return scalar case    = `case'
    return local detlist  "`detlist'"
    return scalar verified = `verified'
    return local okmsg    "`okmsg'"
    return local note     "`note'"
    return local touse    "`touse'"
end
