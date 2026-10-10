*! freeivreport 1.0.0  06oct2026  A. Araar (Universite Laval / PEP)
*! One command for the whole pipeline: what the data can carry, every route
*! against the identified set, and the tests -- assembled into a single table
*! that can be written straight to a file for a paper.
*!
*!   freeivreport depvar [indepvars] (endogvar) [if] [in] [pw aw]
*!                [, SAVing(filename[, replace]) noMENU noTESTs VCE(svy)
*!                   Level(#) DELta(#) RMAX(#) SIGN(#) ]
*!
*!   freeivreport depvar [indepvars] (endogvar1 endogvar2) ...
*!
*! 1.0.0 follows freeiv 1.0.0: the routes in its order (the interval, order
*! 3, order 4, the other maintained models), the removed routes and
*! quantile() gone, vce(svy) passed on, fweights removed.
*!
*! The report is deliberately ordered the way the results should be read:
*! identification first, estimates second, tests last.  An estimate is never
*! shown without the interval that judges it, and never without the signal
*! that says whether its own route is available at all.
*!
*! saving() writes the same table as a comma-delimited file with one row per
*! line: block, label, value, standard error, note.

cap program drop freeivreport
cap program drop _fivr_row
cap program drop _fivr_open
cap program drop _fivr_close

program define freeivreport, rclass
    version 16
    syntax anything(name=eqs equalok) [if] [in] [pw aw] ///
        [, SAVing(string) noMENU noTESTs VCE(string) Level(cilevel) ///
           DELta(real 1) RMAX(real -1) SIGN(real 1) ]

    * ---- how many endogenous variables ------------------------------------
    local p1 = strpos("`eqs'", "(")
    local p2 = strpos("`eqs'", ")")
    if (`p1' == 0 | `p2' == 0 | `p2' < `p1') {
        di as err "the endogenous variable(s) must be given in parentheses"
        exit 198
    }
    local endog = trim(substr("`eqs'", `p1' + 1, `p2' - `p1' - 1))
    local nend : word count `endog'
    local rest  = trim(substr("`eqs'", 1, `p1' - 1)) + " " ///
                + trim(substr("`eqs'", `p2' + 1, .))
    gettoken depvar exog : rest
    local exog = trim("`exog'")

    local rmopt = ""
    if (`rmax' >= 0) local rmopt "rmax(`rmax')"
    local wt ""
    if ("`weight'" != "") local wt "[`weight'`exp']"
    * vce() is passed on as given; freeiv judges it before anything is written
    local vceopt ""
    if (`"`vce'"' != "") local vceopt "vce(`vce')"

    * ======================= estimation =====================================
    * with two endogenous regressors freeiv refuses the options that steer a
    * one-endogenous route, so they must not be forwarded.  It runs first,
    * so that an error stops the report before the file is opened.
    if (`nend' == 2) {
        * r(498) is a guard of Proposition 1: e() is posted and the report
        * says which guard fired; any other error stops the report, shown
        cap qui freeiv `eqs' `if' `in' `wt', level(`level') `vceopt'
        local frc = _rc
        local fguard = (`frc' == 498 & "`e(cmd)'" == "freeiv" & e(guard) != 0 & e(guard) < .)
        if (`frc' & !`fguard') {
            freeiv `eqs' `if' `in' `wt', level(`level') `vceopt'
        }
    }
    else {
        qui freeiv `eqs' `if' `in' `wt', method(all) level(`level') ///
            delta(`delta') `rmopt' sign(`sign') `vceopt'
    }
    * the menu runs -regress- inside, which would replace e()
    tempname est
    _estimates hold `est', copy restore

    _fivr_open, saving(`saving')
    local fh "`r(fh)'"

    * ======================= identification ================================
    * the menu weights as freeiv did: under vce(svy), by the weight of svyset
    local mwt "`wt'"
    if ("`e(vce)'" == "linearized" & "`e(wtype)'" != "") {
        local mwt "[`e(wtype)' `e(wexp)']"
    }
    if ("`menu'" == "" & `nend' == 1) {
        cap qui freeivmenu `eqs' `if' `in' `mwt'
        if (_rc == 0) {
            local m_zm03 = r(z_m03)
            local m_skew = r(skew2)
            local m_Flew = r(F_lewbel)
            local m_plew = r(p_lewbel)
            local m_dz   = r(disc_z)
            local m_B    = r(B)
            local m_mu   = r(mu)
            local m_atv  = r(at_vertex)
        }
    }
    _estimates unhold `est'

    * t on the design degrees of freedom under vce(svy), the normal otherwise
    local st = cond(e(df_r) < ., "t", "z")

    * n beside the model when the line leaves room for it, on its own line
    * otherwise, so that nothing passes column 78
    local mtext "`depvar' on `endog'"
    if ("`exog'" != "") local mtext "`mtext', controls `exog'"
    di
    if (length("`mtext'") <= 34) {
        di as txt "freeiv report" _col(30) as res "`mtext'" ///
           _col(66) as txt "n = " as res %8.0f e(N)
    }
    else {
        di as txt "freeiv report" _col(66) "n = " as res %8.0f e(N)
        di as res "`mtext'"
    }
    if ("`e(vce)'" == "linearized") {
        di as txt "variance linearized over the svyset design" _col(66) ///
           "df = " as res %7.0f e(df_r)
    }
    else if ("`e(vce)'" == "robust") {
        di as txt "variance in sandwich form for the sampling weights"
    }
    di as txt "{hline 76}"

    if (`nend' == 1) {
        di as txt "IDENTIFICATION" _col(38) "value" _col(52) "verdict"
        _fivr_row "identification" "bounds, width" ///
            `=e(hi) - e(lo)' . "[`=string(e(lo),"%7.5f")', `=string(e(hi),"%7.5f")']" "`fh'"
        if ("`menu'" == "") {
            _fivr_row "identification" "z of m03 (third-order route)" ///
                `m_zm03' . "`=cond(abs(`m_zm03')>3,"strong",cond(abs(`m_zm03')>2,"weak","absent"))'" "`fh'"
            _fivr_row "identification" "z of the discriminant D" ///
                `m_dz' . "`=cond(abs(`m_dz')>2,"usable","fragile")'" "`fh'"
            _fivr_row "identification" "F of eps2^2 on X (lewbel12)" ///
                `m_Flew' . "`=cond(`m_plew'<0.05,"present","absent")'" "`fh'"
            _fivr_row "identification" "B = E[V2^3] (hme sets 0)" ///
                `m_B' . "`=cond(`m_atv'==1,"at the vertex","")'" "`fh'"
        }

        di as txt "{hline 76}"
        di as txt "ESTIMATES" _col(32) "estimate" _col(46) "s.e." _col(60) "vs the set"
        * the order of freeiv: the interval (ols its upper end), order 3,
        * order 4, the other maintained models
        foreach k in ols qme hme gmm pgmm lsz lewbel12 copula rank oster {
            local kk "`k'"
            local lab "`k'"
            if ("`k'" == "rank") local kk "g_rank"
            * gmm is the JOINT nine-moment route of Araar (2026c) and pgmm the
            * profiled one; they are different estimators
            if ("`k'" == "gmm")  local kk "g_gmm"
            if ("`k'" == "pgmm") local kk "g_pgmm"
            local v  = e(`kk')
            local se = .
            if ("`k'" == "ols") local se = e(se_gt)
            if ("`k'" == "qme") local se = e(se_qme)
            if ("`k'" == "hme") local se = e(se_hme)
            * the qme retains the vertex when the discriminant is negative
            if ("`k'" == "qme" & e(at_vertex) == 1) {
                local v   = e(vertex)
                local se  = e(se_vertex)
                local lab "qme (vertex)"
            }
            * suppressed, not absent: on the boundary there is nothing for the
            * delta method to expand around
            if ("`k'" == "gmm")  local se = cond(e(gmm_bound) == 1, ., e(se_gmm))
            if ("`k'" == "pgmm") local se = e(se_pgmm)
            * a non-converged solver does not get to show a standard error
            if ("`k'" == "lsz") local se = cond(e(lsz_conv) != 1, ., e(se_lsz))
            local nt ""
            if (`v' < . & e(lo) < .) {
                * the OLS slope IS the upper bound, so compare with a
                * relative tolerance or it is reported as outside its own set
                local tol = 1e-9 * max(1, abs(e(hi)))
                if (`v' < e(lo) - `tol' | `v' > e(hi) + `tol') local nt "outside"
                else if (abs(`v' - e(hi)) < `tol')             local nt "at the upper bound"
                else if (abs(`v' - e(lo)) < `tol')             local nt "at the lower bound"
                else                                          local nt "inside"
            }
            if ("`k'" == "lsz" & e(lsz_conv) != 1) local nt "NOT CONVERGED"
            _fivr_row "estimate" "`lab'" `v' `se' "`nt'" "`fh'"
        }
        _fivr_row "estimate" "identified set" . . ///
            "[`=string(e(lo),"%7.5f")', `=string(e(hi),"%7.5f")']" "`fh'"

        if ("`tests'" == "") {
            di as txt "{hline 76}"
            di as txt "TESTS" _col(32) "statistic" _col(46) "p" _col(60) "tests"
            cap qui freeivtest
            if (_rc == 0) {
                local ref "`r(ref)'"
                if (r(F_endo) < .) {
                    _fivr_row "test" "endogeneity, adjusted F" `=r(F_endo)' ///
                        `=r(p_endo)' "theta = 0" "`fh'"
                }
                else {
                    _fivr_row "test" "endogeneity, chi2(2)" `=r(W_endo)' ///
                        `=r(p_endo)' "theta = 0" "`fh'"
                }
                _fivr_row "test" "`ref' - ols, `st'" `=r(z_ols)' . "theta = 0" "`fh'"
                _fivr_row "test" "`ref' - hme, `st'" `=r(z_hme)' . "B = 0" "`fh'"
            }
            _fivr_row "test" "joint GMM, J chi2(1)" `=e(J_gmm)' `=e(p_gmm)' ///
                "SC and linearity" "`fh'"
            * the region is valid where the standard error is not, so it is
            * reported whenever the minimum sits on a boundary -- and its
            * share of the identified interval says what the higher moments
            * actually added
            if (e(ar_frac) < .) {
                _fivr_row "test" "  J within 3.84 of its min" `=e(ar_lo)' ///
                    `=e(ar_hi)' "`=string(100*e(ar_frac),"%4.0f")'% of the set" "`fh'"
                if (e(ar_frac) > 0.95) {
                    di as txt "      the region IS the identified set: orders 3 and 4"
                    di as txt "      add nothing to the assumption-free bounds here"
                }
            }
            if (e(gmm_bound) == 1) {
                di as txt "      the joint minimum is on the boundary, so its s.e."
                di as txt "      and the chi2(1) law for its J are both invalid"
            }
            _fivr_row "test" "profiled GMM, J chi2(1)" `=e(J_pgmm)' ///
                `=e(p_pgmm)' "orders 2-3 exact" "`fh'"
            _fivr_row "test" "  its identification factor" `=e(z_idfac)' . ///
                "`=cond(abs(e(z_idfac))<2,"near knife edge","usable")'" "`fh'"
        }
    }

    * ======================= model B ========================================
    else {
        di as txt "MODEL B: TWO INDICATORS" _col(32) "estimate" _col(46) "s.e."
        _fivr_row "estimate" "g2 (`=word("`endog'",1)')" `=e(g2)' `=e(se_g2)' "" "`fh'"
        _fivr_row "estimate" "g3 (`=word("`endog'",2)')" `=e(g3)' `=e(se_g3)' "" "`fh'"
        _fivr_row "estimate" "a1 (free loading of U)" `=e(a1)' `=e(se_a1)' "" "`fh'"
        _fivr_row "estimate" "g2 a2 + g3 a3" `=e(sc)' . "model A's a1" "`fh'"
        _fivr_row "estimate" "condition number" `=e(cnum)' . ///
            "`=cond(e(cnum)>100,"ill conditioned","")'" "`fh'"
        _fivr_row "estimate" "`=e(endog3)' as an instrument" `=e(ivgap)' . ///
            "vs g2 above" "`fh'"

        di as txt "{hline 76}"
        di as txt "TESTS" _col(32) "statistic" _col(46) "s.e. / p"
        _fivr_row "test" "scale consistency, a1 - sc" ///
            `=e(sc_d)' `=e(se_sc)' "`st' = `=string(e(z_sc),"%6.3f")'" "`fh'"
        _fivr_row "test" "one factor, R1 - R3" `=e(of_d)' `=e(se_of)' ///
            "`st' = `=string(e(z_of),"%6.3f")'" "`fh'"
        _fivr_row "test" "GMM16, J chi2(4)" `=e(q_J)' `=e(q_pJ)' ///
            "one factor, linear" "`fh'"
        _fivr_row "test" "guard of Proposition 1" `=e(guard)' . ///
            "`=cond(e(guard)==0,"none fired","a guard fired")'" "`fh'"
    }

    di as txt "{hline 76}"
    di as txt "Read down, not across: the first block says which routes these"
    di as txt "data can carry, the second shows what each returns against the"
    di as txt "identified set, the third what the data say about the assumptions."
    _fivr_close, fh("`fh'") saving(`saving')

    return scalar n = e(N)
    if (`nend' == 1) {
        return scalar lo = e(lo)
        return scalar hi = e(hi)
        return scalar qme = e(qme)
        return scalar gamma = e(gamma)
    }
    return local endog "`endog'"
    return local depvar "`depvar'"
end


program define _fivr_row
    args block label value se note fh
    local sv "         ."
    local ss "         ."
    cap if (`value' < .) local sv = string(`value', "%10.6f")
    cap if (`se' < .)    local ss = string(`se', "%10.6f")
    if ("`block'" == "identification") {
        di as txt "  " %-34s "`label'" _col(38) as res "`sv'" ///
           _col(52) as txt "`note'"
    }
    else {
        di as txt "  " %-28s "`label'" _col(32) as res "`sv'" ///
           _col(46) "`ss'" _col(60) as txt "`note'"
    }
    if ("`fh'" != "") {
        * plain CSV, no quoting: commas inside a field become semicolons, so
        * no embedded double quote can reach the file and break a later read
        local lab = subinstr(`"`label'"', ",", ";", .)
        local nt2 = subinstr(`"`note'"', ",", ";", .)
        local lab = subinstr(`"`lab'"', `"""', "", .)
        local nt2 = subinstr(`"`nt2'"', `"""', "", .)
        file write `fh' `"`block',`lab',`=trim("`sv'")',`=trim("`ss'")',`nt2'"' _n
    }
end


program define _fivr_open, rclass
    syntax [, SAVing(string)]
    if ("`saving'" == "") {
        return local fh ""
        exit
    }
    gettoken fn rest : saving, parse(",")
    local fn = trim(`"`fn'"')
    local fn = subinstr(`"`fn'"', `"""', "", .)
    if (strpos(lower("`rest'"), "replace")) local rep "replace"
    * NOT a tempname: a tempname handle is closed when the program that
    * created it ends, so the handle must survive across _fivr_row calls
    cap file close __fivrpt
    file open __fivrpt using `"`fn'"', write text `rep'
    file write __fivrpt "block,label,value,se,note" _n
    return local fh "__fivrpt"
end


program define _fivr_close
    syntax [, fh(string) SAVing(string)]
    if ("`fh'" == "") exit
    file close `fh'
    gettoken fn rest : saving, parse(",")
    local fn = trim(subinstr(`"`fn'"', `"""', "", .))
    di as txt "table written to " as res `"`fn'"'
end
