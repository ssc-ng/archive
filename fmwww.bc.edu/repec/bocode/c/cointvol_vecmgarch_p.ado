*! cointvol_vecmgarch_p 0.1.0  26sep2026
*! predict after -cointvol vecmgarch-: fitted values, residuals, standardised residuals,
*! error-correction terms, conditional variances / covariances / correlations, log likelihood
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!   xb          fitted dX_it = alpha_i beta#'Z1_t + Psi_i Z2_t            (mean equation)
*!   residuals   e_it                                                      (mean equation)
*!   variance    h_ii,t, the (i,i) element of H_t from the fitted recursion (variance model)
*!   covariance  h_ij,t ; correlation h_ij,t / sqrt(h_ii,t h_jj,t) ; sd sqrt(h_ii,t)
*!   stdresid    e_it / sqrt(h_ii,t)
*!   ect         beta_j#'Z1_t = beta_j'X(t-1) + rho_j'D1(t)
*!   loglik      l_t = -.5[p log 2pi + log|H_t| + e_t'H_t^-1 e_t]
*!   Only observations in e(sample) are predicted (the recursions need the full sample).

program define cointvol_vecmgarch_p, sortpreserve
    version 14.0
    if `"`e(cmd)'"' != "cointvol vecmgarch" {
        di as err "last estimates not found; run cointvol vecmgarch first"
        exit 301
    }
    syntax newvarname [if] [in] [, XB Residuals STDResid ECT Variance COVariance ///
        CORRelation SD LOGLik EQuation(string) ]
    local stat "`xb'`residuals'`stdresid'`ect'`variance'`covariance'`correlation'`sd'`loglik'"
    local nst : word count `xb' `residuals' `stdresid' `ect' `variance' `covariance' `correlation' `sd' `loglik'
    if `nst' > 1 {
        di as err "only one statistic may be specified"
        exit 198
    }
    if `nst' == 0 {
        local stat "xb"
        di as txt "(option xb assumed; fitted values of the differenced variables)"
    }

    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvgver", cvg_version())
    if _rc {
        capture program drop cointvol_eng_vecmgarch
        quietly findfile cointvol_eng_vecmgarch.ado
        quietly run `"`r(fn)'"'
    }

    local vl "`e(varlist)'"
    local p = e(p)
    local rint = e(rank_int)

    // ---------------- equations ------------------------------------------------
    local neq 1
    if inlist("`stat'", "covariance", "correlation") local neq 2
    if "`stat'" == "loglik" local neq 0
    local eqs ""
    if `"`equation'"' != "" {
        foreach e of local equation {
            local e = subinstr("`e'", "#", "", .)
            capture confirm integer number `e'
            if !_rc {
                local eqs "`eqs' `e'"
            }
            else {
                local nm = subinstr("`e'", "D_", "", 1)
                local pos : list posof "`nm'" in vl
                if `pos' == 0 {
                    local k 0
                    foreach v of local vl {
                        local k = `k' + 1
                        if "`nm'" == substr(strtoname("`v'"), 1, 28) local pos = `k'
                    }
                }
                if `pos' == 0 {
                    di as err "equation(): `e' not found"
                    exit 198
                }
                local eqs "`eqs' `pos'"
            }
        }
    }
    local ne : word count `eqs'
    if `neq' == 1 {
        if `ne' == 0 {
            local eqs 1
            if "`stat'" != "ect" & `p' > 1 {
                di as txt "(equation 1 assumed)"
            }
        }
        else if `ne' > 1 {
            di as err "equation() takes one equation for `stat'"
            exit 198
        }
    }
    if `neq' == 2 {
        if `ne' == 0 {
            local eqs "1 2"
            di as txt "(equations 1 and 2 assumed)"
        }
        else if `ne' != 2 {
            di as err "equation() takes two equations for `stat'"
            exit 198
        }
    }
    local i1 : word 1 of `eqs'
    local i2 : word 2 of `eqs'
    if "`i1'" == "" local i1 1
    if "`i2'" == "" local i2 1
    if "`stat'" == "ect" {
        if `rint' == 0 | "`e(rmode)'" == "full" {
            di as err "ect is not available: the model has no cointegrating relations (rank 0 or full rank)"
            exit 498
        }
        if `i1' < 1 | `i1' > `rint' {
            di as err "equation() must lie in 1,...,`rint' for ect"
            exit 198
        }
    }
    else if `neq' > 0 {
        if `i1' < 1 | `i1' > `p' | `i2' < 1 | `i2' > `p' {
            di as err "equation() must lie in 1,...,`p'"
            exit 198
        }
    }

    marksample touse, novarlist
    local tvar "`e(timevar)'"
    qui tsset
    sort `tvar'
    tempvar win es out
    qui gen byte `win' = inrange(`tvar', e(tmin), e(tmax))
    qui gen byte `es' = e(sample)
    tsrevar `vl'
    local mvars "`r(varlist)'"
    local xl ""
    if "`e(xmode)'" == "vars" {
        tsrevar L.(`e(xvars)')
        local xl "`r(varlist)'"
    }
    qui gen double `out' = .
    mata: cvg_predict("`mvars'", "`win'", "`es'", "`xl'", "`stat'", `i1', `i2', "`out'")
    qui gen `typlist' `varlist' = `out' if `touse' & `es'
    local w1 : word `i1' of `vl'
    local w2 : word `i2' of `vl'
    if "`stat'" == "xb"          label variable `varlist' "fitted D.`w1'"
    if "`stat'" == "residuals"   label variable `varlist' "residual, D.`w1' equation"
    if "`stat'" == "stdresid"    label variable `varlist' "standardised residual, D.`w1' equation"
    if "`stat'" == "variance"    label variable `varlist' "conditional variance of `w1'"
    if "`stat'" == "sd"          label variable `varlist' "conditional s.d. of `w1'"
    if "`stat'" == "covariance"  label variable `varlist' "conditional covariance `w1', `w2'"
    if "`stat'" == "correlation" label variable `varlist' "conditional correlation `w1', `w2'"
    if "`stat'" == "ect"         label variable `varlist' "error-correction term `i1'"
    if "`stat'" == "loglik"      label variable `varlist' "log-likelihood contribution"
end
