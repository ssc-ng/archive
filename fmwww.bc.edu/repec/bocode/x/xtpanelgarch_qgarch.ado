*! xtpanelgarch_qgarch 1.0.0  06nov2026
*! Zhu, Li, Zhang & Li (2026) panel quantile GARCH models under homogeneity
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Zhu, Li, Zhang and Li 2026, JBES 44: 270-281; supplement S.51)
*   model        Q_tau(y_it|F) = w_i(tau) + a_i(tau) sum_j b_i(tau)^{j-1} |y_i,t-j|     eq.(3)
*   groups       w, a, b each with its own partition                                    eq.(4)
*   Stage I      self-weighted CQE per unit, eq.(5); weights eq.(9) (He-Yi 2021),
*                c_i = 95% quantile of y_i; start from a GARCH(1,1) fit to sqrt|y|sgn(y)
*                + 9^3 grid (Zhu et al. 2023 code: fit1_optim, fit1_optim_grid)
*   Stage II     binary segmentation on sorted initial estimates, CUSUM eq.(6);
*                threshold by BIC3 = loss + g ln N (authors' code), adaptive grid on [0, deltamax]
*   Stage III    pooled self-weighted CQE under detected groups, eq.(7)
*   inference    sqrt(NT): Omega1^-1 Omega0 Omega1^-1 (Thm 3.1), density by difference quotient
*                with Hall-Sheather (default) or Bofinger bandwidth (supplement S.51); n = NT

program define xtpanelgarch_qgarch, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "qgarch") error 301
        _xtpg_qg_display `0'
        exit
    }
    syntax varname(ts) [if] [in] , [ Quantile(real 0.05) GRoup(string) DELTAMax(real 2) ///
        NCANDidates(integer 6) TOLerance(real 0.0001) BWidth(string) FACtors(varlist numeric ts) ///
        noLOG Level(cilevel) noTABle ]
    if `quantile' <= 0 | `quantile' >= 1 {
        di as err "quantile() must be in (0,1)"
        exit 198
    }
    // parameter blocks: omega alpha beta + one loading per factor (eq. 10)
    local fnames ""
    if "`factors'" != "" {
        tsunab factors : `factors'
        foreach v of local factors {
            local cl = subinstr(subinstr("`v'", ".", "_", .), "#", "_", .)
            local fnames "`fnames' lambda_`cl'"
        }
    }
    local pnames "omega alpha beta `fnames'"
    if "`group'" == "" local group "`pnames'"
    if "`group'" == "all" local group "`pnames'"
    local group = lower("`group'")
    if "`factors'" != "" & strpos("`group'", "lambda") == 0 & "`group'" != "none" {
        if strpos("`group'", "loadings") local group "`group' `fnames'"
    }
    local gs ""
    foreach p of local pnames {
        local pl = lower("`p'")
        local ingrp : list pl in group
        local gs "`gs'`ingrp'"
    }
    if "`group'" == "none" {
        local gs ""
        foreach p of local pnames {
            local gs "`gs'0"
        }
    }
    if "`bwidth'" == "" local bwidth "hs"
    local bwidth = lower("`bwidth'")
    if !inlist("`bwidth'", "hs", "b") {
        di as err "bwidth() must be hs (Hall-Sheather) or b (Bofinger)"
        exit 198
    }
    local bwt = cond("`bwidth'" == "hs", 1, 2)
    local showlog = ("`log'" == "")
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    local yorig "`varlist'"
    tsrevar `varlist'
    local y "`r(varlist)'"
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch qgarch"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    if `N' < 2 {
        di as err "qgarch needs at least 2 panels"
        exit 2001
    }
    tempname FM
    local fmn ""
    if "`factors'" != "" {
        markout `touse' `factors'
        tsrevar `factors'
        local fv "`r(varlist)'"
        foreach v of local fv {
            tempvar sdf
            qui bysort `tvar': egen double `sdf' = sd(`v') if `touse'
            qui sum `sdf' if `touse', meanonly
            if r(max) > 1e-10 & r(max) < . {
                di as err "factors() must take the same value for all panels at each date"
                exit 459
            }
            drop `sdf'
        }
        sort `ivar' `tvar'
        mata: _xtpg_qg_factormat("`fv'", "`touse'", `T', "`FM'")
        local fmn "`FM'"
    }
    mata: _xtpg_qg_setF("`fmn'")

    mata: _xtpg_qg_fit("`y'", "`touse'", `N', `T', `quantile', "`gs'", 0, `deltamax', `ncandidates', `tolerance', `bwt', `showlog')

    tempname b V g
    matrix `b' = __xtpg_th
    matrix `V' = __xtpg_V
    matrix `g' = __xtpg_g
    local names ""
    local k 0
    foreach p of local pnames {
        local ++k
        local gk = `g'[1, `k']
        forvalues j = 1/`gk' {
            local names "`names' `p':g`j'"
        }
    }
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    tempname LAB P0 P1
    matrix `LAB' = __xtpg_lab
    matrix `P0' = __xtpg_ph0
    matrix `P1' = __xtpg_ph
    matrix colnames `LAB' = `pnames'
    matrix colnames `P0' = `pnames'
    matrix colnames `P1' = `pnames'
    matrix rownames `LAB' = `units'
    matrix rownames `P0' = `units'
    matrix rownames `P1' = `units'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar quantile = `quantile'
    ereturn scalar loss = scalar(__xtpg_loss)
    ereturn scalar bandwidth = scalar(__xtpg_ell)
    ereturn scalar hit = scalar(__xtpg_hit)
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar g_omega = `g'[1, 1]
    ereturn scalar g_alpha = `g'[1, 2]
    ereturn scalar g_beta = `g'[1, 3]
    ereturn local factors "`factors'"
    ereturn local pnames "`pnames'"
    ereturn matrix g = `g'
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "qgarch"
    ereturn local title "Panel quantile GARCH under homogeneity (Zhu-Li-Zhang-Li)"
    ereturn local group "`group'"
    ereturn local bwidth "`bwidth'"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local vcetype "Sandwich"
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix groups = `LAB'
    ereturn matrix phi_initial = `P0'
    ereturn matrix phi = `P1'
    ereturn matrix delta = __xtpg_delta
    ereturn matrix qtau = __xtpg_q
    ereturn matrix weights = __xtpg_w
    capture matrix drop __xtpg_th __xtpg_V
    capture scalar drop __xtpg_loss __xtpg_ell __xtpg_hit
    _xtpg_qg_display, level(`level') `table'
end

program define _xtpg_qg_display
    syntax [, Level(cilevel) noTABle]
    di _n as txt "`e(title)'"
    di as txt _col(52) "Number of obs" _col(68) "=" as res %9.0fc e(N)
    if "`e(factors)'" == "" di as txt "Q_tau = w(tau) + a(tau) sum b(tau)^(j-1) |y_t-j|" _col(52) "Number of panels" _col(68) "=" as res %9.0f e(N_g)
    else di as txt "Q_tau = w + a sum b^(j-1)|y_t-j| + lambda'f_t (eq. 10)" _col(52) "Number of panels" _col(68) "=" as res %9.0f e(N_g)
    di as txt "Quantile level tau = " as res %6.4f e(quantile) _col(52) as txt "Time periods" _col(68) "=" as res %9.0f e(T)
    di as txt "Groups: omega " as res e(g_omega) as txt ", alpha " as res e(g_alpha) as txt ", beta " as res e(g_beta) ///
        _col(52) as txt "Weighted loss" _col(68) "=" as res %9.3f e(loss)
    if "`table'" == "" ereturn display, level(`level')
    tempname G D Q GG
    matrix `G' = e(groups)
    matrix `D' = e(delta)
    matrix `GG' = e(g)
    di as txt "{hline 78}"
    di as txt "Detected homogeneity (binary segmentation, BIC3 threshold)"
    local k 0
    foreach p in `e(pnames)' {
        local ++k
        local dk = `D'[1, `k']
        local gk = `GG'[1, `k']
        di as txt "  `p'" _col(10) "delta = " as res %7.4f `dk' as txt "   groups = " as res `gk'
        forvalues j = 1/`gk' {
            local mem ""
            local i 0
            foreach u in `e(units)' {
                local ++i
                if `G'[`i', `k'] == `j' local mem "`mem' `u'"
            }
            local nm : word count `mem'
            if `nm' > 14 {
                local mem : piece 1 70 of "`mem'"
                local mem "`mem' ..."
            }
            di as txt "     g`j' (n=`nm'):" as res "`mem'"
        }
    }
    // in-sample VaR coverage
    di as txt "  in-sample hit rate 1(y < Q_tau) = " as res %6.4f e(hit) as txt "   (nominal " %5.3f e(quantile) ")"
    di as txt "  bandwidth (`e(bwidth)', n = NT) = " as res %8.5f e(bandwidth)
    di as txt "{hline 78}"
end
