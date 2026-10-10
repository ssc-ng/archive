*! freeivmenu 1.0.0  06oct2026  A. Araar (Universite Laval / PEP)
*! The identification menu: before any estimation, what these data can carry.
*! One line per family of strategies, with the signal it needs, its value, and
*! a verdict.
*!
*!   freeivmenu depvar [indepvars] (endogvar) [if] [in] [pw aw] [, BW(#) ]
*!   freeivmenu depvar [indepvars] (endogvar1 endogvar2) [if] [in] [pw aw]
*!              [, BW(#) ]
*!
*! 1.0.0 follows freeiv 1.0.0: the lines of the equal-variance routes (rre,
*! sce) and quantile() are gone with them, fweights are removed, and the
*! third moments A, B and mu are read at the qme -- or at the vertex when
*! the discriminant is negative, which the menu then says.
*!
*! 0.4.0 adds the menu of the two-indicator model (two variables in the
*! parentheses): relevance of the pair, the two third-order cross-moments
*! with their z and the sign guard, the implied loadings, variances and
*! confounder skewness with the precision regime of Araar (2026d), the
*! one-factor check, and the slope profile of xi on each indicator.
*! Reference: python/export_menu2.py, values in python/export_menu2.txt.
*! 0.4.1 keeps every displayed line within 78 columns (verdicts of at most
*! 16 characters, explanations on an indented line) and prints n on its own
*! line when the control list is long.
*!
*! 0.3.0 adds the local slope profile of E[xi | eps2]: the kernel-weighted
*! slope of xi on eps2 at seven percentiles of eps2.  Flat means Gaussian-
*! like (the third order will find little); its minimum is an upper bound
*! on gamma when E[U | eps2] is increasing; the ratio of the two tail slopes
*! tends to 1 + alpha1/(gamma alpha2), i.e. 2 under scale consistency.
*! Reference: python/freeiv/profile.py, values in python/export_profile.txt.
*!
*! Every displayed statistic is returned in r().

cap program drop freeivmenu
cap program drop _fivm_verdict
cap program drop _fivm_header
cap program drop _fivm_profile

program define freeivmenu, rclass
    version 16
    syntax anything(name=eqs equalok) [if] [in] [pw aw] [, BW(real -1) ]

    local p1 = strpos("`eqs'", "(")
    local p2 = strpos("`eqs'", ")")
    if (`p1' == 0 | `p2' == 0 | `p2' < `p1') {
        di as err "the endogenous variable must be given in parentheses"
        exit 198
    }
    local endog = trim(substr("`eqs'", `p1' + 1, `p2' - `p1' - 1))
    local rest  = trim(substr("`eqs'", 1, `p1' - 1)) + " " ///
                + trim(substr("`eqs'", `p2' + 1, .))
    local rest  = trim(stritrim("`rest'"))
    gettoken depvar exog : rest
    local nend : word count `endog'
    if (`nend' != 1 & `nend' != 2) {
        di as err "freeivmenu expects one or two endogenous variables in parentheses"
        exit 198
    }
    confirm numeric variable `depvar' `endog'

    * factor variables among the controls, as in freeiv itself
    local exogfv   "`exog'"
    local exogbase ""
    if ("`exog'" != "") {
        cap fvrevar `exog', list
        if (_rc) {
            di as err "invalid varlist for the exogenous controls:"
            di as err "    `exog'"
            exit 198
        }
        local exogbase "`r(varlist)'"
        confirm numeric variable `exogbase'
    }
    local clash : list depvar & endog
    if ("`clash'" != "") {
        di as err "`clash' cannot be both the dependent and the endogenous variable"
        exit 198
    }

    freeiv_engine
    marksample touse
    markout `touse' `depvar' `endog' `exogbase'
    qui count if `touse'
    local N = r(N)

    * the covariance of the moment contributions, as in freeiv: in sandwich
    * form with pweights, so that the z of the discriminant is freeiv's
    cap mata: _fiv_vclear()
    if ("`weight'" == "pweight") mata: _fiv_vset("", "", "", "`touse'", 0)

    tempvar wv xi e2 e2sq
    if ("`weight'" != "") {
        qui gen double `wv' `exp' if `touse'
        local wname "`wv'"
        local wexp2 "[aw = `wv']"
    }
    else {
        local wname ""
        local wexp2 ""
    }
    if ("`exogfv'" != "") {
        fvrevar `exogfv' if `touse', substitute
        local exog "`r(varlist)'"
    }

    * ================= two indicators of one confounder ===================
    if (`nend' == 2) {
        gettoken en2 en3 : endog
        local en3 = trim("`en3'")
        cap noisily mata: _freeiv_proxy("`depvar'", "`en2'", "`en3'", ///
                                        "`exog'", "`wname'", "`touse'")
        local rc = _rc
        cap mata: _fiv_vclear()
        if (`rc') exit `rc'
        tempname PB
        matrix `PB' = __freeiv_P
        cap matrix drop __freeiv_P __freeiv_PV
        local pvals : colnames `PB'
        local j = 0
        foreach v of local pvals {
            local ++j
            local p_`v' = `PB'[1, `j']
        }

        * the residuals, for the z statistics and the profiles: weighted least
        * squares on the controls, as the engine computes them
        tempvar xi e2 e3
        foreach pr in "`depvar' xi" "`en2' e2" "`en3' e3" {
            gettoken yv rv : pr
            local rv = trim("`rv'")
            cap qui regress `yv' `exog' `wexp2' if `touse'
            if (_rc) {
                di as err "could not regress `yv' on the controls"
                exit _rc
            }
            qui predict double ``rv'' if `touse', resid
        }
        tempvar pr23 pr223 pr233
        qui gen double `pr23'  = `e2' * `e3'      if `touse'
        qui gen double `pr223' = `e2'^2 * `e3'    if `touse'
        qui gen double `pr233' = `e2' * `e3'^2    if `touse'
        foreach v in 23 223 233 {
            qui summarize `pr`v'' `wexp2' if `touse'
            local se_m`v' = r(sd) / sqrt(`N')
            local z_m`v'  = cond(`se_m`v'' > 0, r(mean) / `se_m`v'', .)
        }

        * the slope profile of xi on each indicator
        tempname P2 P3
        _fivm_profile `P2' `xi' `e2' `touse' "`wname'" "`wexp2'" `bw' `N'
        local h2 = `prof_h'
        local min2 = `pmin'
        local minse2 = `pmin_se'
        local minp2 "`pmin_p'"
        local jmin2 = `jmin'
        local ratio2 = `pratio'
        local z2 = `pz'
        _fivm_profile `P3' `xi' `e3' `touse' "`wname'" "`wexp2'" `bw' `N'
        local h3 = `prof_h'
        local min3 = `pmin'
        local minse3 = `pmin_se'
        local minp3 "`pmin_p'"
        local jmin3 = `jmin'
        local ratio3 = `pratio'
        local z3 = `pz'

        * ================= display ========================================
        di
        di as txt "Identification menu: two indicators of one confounder"
        _fivm_header "`depvar' on `en2' and `en3'" "`exogfv'" `N'
        di as txt "{hline 76}"
        di as txt %-22s "route" %-28s "signal" %10s "value" "  verdict"
        di as txt "{hline 76}"

        * 1. relevance of the pair ------------------------------------------
        local vt = cond(abs(`p_t_rho') >= 10, "strong", ///
                   cond(abs(`p_t_rho') >= 5, "weak", "absent"))
        di as txt %-22s "relevance of the pair" %-28s "corr(eps2, eps3), t" ///
           as res %10.2f `p_t_rho' as txt "  `vt'"
        di as txt %-22s "" %-28s "alpha2 alpha3 = E[eps2 eps3]" ///
           as res %10.4f `p_m23' as txt "  z " %5.2f `z_m23'
        di as txt %-22s "" %-28s "rule of Araar (2026d): t >= 10"

        * 2. third order: the two cross-moments and the sign guard ----------
        _fivm_verdict `z_m223' 3 2
        local v223 "`s'"
        _fivm_verdict `z_m233' 3 2
        local v233 "`s'"
        di as txt %-22s "third order" %-28s "E[eps2^2 eps3], z" ///
           as res %10.2f `z_m223' as txt "  `v223'"
        di as txt %-22s "" %-28s "E[eps2 eps3^2], z" ///
           as res %10.2f `z_m233' as txt "  `v233'"
        * every verdict is at most 16 characters so that a line never exceeds
        * 78 columns; what needs more words goes on an indented line below
        local samesign = (`p_m223' * `p_m233' > 0)
        di as txt %-22s "" %-28s "same sign: guard (i)" ///
           as res %10s cond(`samesign', "yes", "NO") ///
           as txt cond(`samesign', "  passes", "  FIRES: (i)")
        if (!`samesign') {
            di as txt %-22s "" "  guard (i): Y2 affects Y3, or a second factor"
        }

        * 3. loadings and implied variances: guards (ii) and (iii) -----------
        local coher = (`p_m23' * `p_R1' > 0)
        di as txt %-22s "loadings" %-28s "alpha2/alpha3 = R1" ///
           as res %10.4f `p_R1' ///
           as txt cond(`coher', "  coherent", "  FIRES: (ii)")
        if (!`coher') {
            di as txt %-22s "" "  guard (ii): E[eps2 eps3] and R1 differ in sign"
        }
        if (`p_guard' == 0) {
            di as txt %-22s "" %-28s "alpha2, alpha3" ///
               as res %10.4f `p_a2' " " %7.4f `p_a3'
            di as txt %-22s "" %-28s "implied Var(V2), Var(V3)" ///
               as res %10.4f `p_s2' " " %7.4f `p_s3' as txt "  positive"
        }
        else if (`p_guard' == 3) {
            di as txt %-22s "" %-28s "implied Var(V2), Var(V3)" ///
               as res %10s "." as txt "  FIRES: (iii)"
            di as txt %-22s "" "  guard (iii): an implied variance is negative"
        }
        else {
            di as txt %-22s "" %-28s "implied Var(V2), Var(V3)" ///
               as res %10s "." as txt "  not computed"
        }

        * 4. the confounder's skewness and the precision regime --------------
        if (`p_guard' == 0) {
            local reg = cond(abs(`p_mu3') < 0.5, "low", ///
                        cond(abs(`p_mu3') < 1.5, "moderate", "full"))
            local regx = cond(abs(`p_mu3') < 0.5, "g2 recovered, a1 imprecise", ///
                         cond(abs(`p_mu3') < 1.5, "all parameters, sc test weak", ///
                         "all parameters, sc testable"))
            di as txt %-22s "confounder" %-28s "implied skewness E[U^3]" ///
               as res %10.4f `p_mu3' as txt "  `reg'"
            di as txt %-22s "" "  `regx'"
        }
        else {
            di as txt %-22s "confounder" %-28s "implied skewness E[U^3]" ///
               as res %10s "." as txt "  guard fired"
        }

        * 5. one factor: the three estimates of alpha2/alpha3 ----------------
        local weak3 = (abs(`z_m223') < 2 | abs(`z_m233') < 2)
        di as txt %-22s "one factor" %-28s "R1 / R2 / R3" ///
           as res %10.4f `p_R1' " " %7.4f `p_R2' " " %7.4f `p_R3'
        di as txt %-22s "" %-28s "|R3/R1 - 1|" as res %10.4f `p_disc_R' ///
           as txt cond(`weak3', "  not informative", ///
              cond(`p_disc_R' < 0.15, "  consistent", "  2 factors likely"))

        * 6. the slope profiles, laid out as in the one-indicator menu --------
        foreach k in 2 3 {
            local M = cond(`k' == 2, "`P2'", "`P3'")
            local lab = cond(`k' == 2, "local slope profile", "")
            local tight`k' = cond(`jmin`k'' > 2, "interior min", "rising")
            di as txt %-22s "`lab'" %-28s "slope of xi on eps`k' at p5" ///
               as res %10.4f `M'[1, 2] as txt "  h = " %5.3f `h`k''
            di as txt %-22s "  of E[xi | eps`k']" %-28s "p10 / p25 / p50" ///
               as res %7.4f `M'[2, 2] " " %7.4f `M'[3, 2] " " %7.4f `M'[4, 2]
            di as txt %-22s "" %-28s "p75 / p90 / p95" ///
               as res %7.4f `M'[5, 2] " " %7.4f `M'[6, 2] " " %7.4f `M'[7, 2]
            di as txt %-22s "" %-28s "curvature z (max-min)" as res %10.2f `z`k'' ///
               as txt cond(`z`k'' >= 2 & `z`k'' < ., "  curved", cond(`z`k'' < ., "  flat", ""))
            di as txt %-22s "" %-28s "min slope, at p`minp`k''" as res %10.4f `min`k'' ///
               as txt "  `tight`k''"
        }

        di as txt "{hline 76}"
        di as txt "Reading: the pair must be relevant (t >= 10) and the two third-order"
        di as txt "cross-moments must share a sign, or Theorem 1 has nothing to work"
        di as txt "with; a guard that fires here will fire in freeiv.  The implied"
        di as txt "skewness sets the precision: near 0.5 the causal coefficient is"
        di as txt "recovered but the free direct effect a1 is not; above 1.5 all"
        di as txt "parameters are precise and scale consistency becomes testable."
        di as txt "The one-factor check reads only when the third order is strong;"
        di as txt "a profile whose minimum is interior does not bound anything."

        * ---- r() -----------------------------------------------------------
        foreach v of local pvals {
            return scalar `v' = `p_`v''
        }
        foreach v in 23 223 233 {
            return scalar z_m`v' = `z_m`v''
        }
        return scalar prof2_h = `h2'
        return scalar prof2_min = `min2'
        return scalar prof2_minse = `minse2'
        return scalar prof2_ratio = `ratio2'
        return scalar prof2_z = `z2'
        return scalar prof3_h = `h3'
        return scalar prof3_min = `min3'
        return scalar prof3_minse = `minse3'
        return scalar prof3_ratio = `ratio3'
        return scalar prof3_z = `z3'
        return matrix profile3 = `P3'
        return matrix profile2 = `P2'
        return matrix moments = `PB'
        exit
    }

    qui gen double `xi' = .
    qui gen double `e2' = .
    cap noisily mata: _freeiv_all("`depvar'", "`endog'", "`exog'", ///
                                  "`wname'", "`touse'", "`xi'", "`e2'")
    local rc = _rc
    cap mata: _fiv_vclear()
    if (`rc') exit `rc'
    tempname M
    matrix `M' = __freeiv_M
    matrix drop __freeiv_M
    cap matrix drop __freeiv_V __freeiv_G
    local vals : colnames `M'
    local j = 0
    foreach v of local vals {
        local ++j
        local `v' = `M'[1, `j']
    }

    * ---- heteroskedasticity signal for Lewbel (2012) ----------------------
    local F_lew = .
    local p_lew = .
    local df_lew = 0
    if ("`exog'" != "") {
        qui gen double `e2sq' = `e2'^2 if `touse'
        cap qui regress `e2sq' `exog' `wexp2' if `touse'
        if (_rc == 0) {
            local F_lew  = e(F)
            local df_lew = e(df_m)
            local p_lew  = Ftail(e(df_m), e(df_r), e(F))
        }
    }

    * ---- z statistic of the third moment of eps2 --------------------------
    tempvar c3
    qui summarize `e2' `wexp2' if `touse', meanonly
    qui gen double `c3' = (`e2' - r(mean))^3 if `touse'
    qui summarize `c3' `wexp2' if `touse'
    local se_m03 = r(sd) / sqrt(`N')
    local z_m03  = cond(`se_m03' > 0, `m03' / `se_m03', .)

    * ---- local slope profile of E[xi | eps2] ------------------------------
    tempname P
    _fivm_profile `P' `xi' `e2' `touse' "`wname'" "`wexp2'" `bw' `N'
    local h = `prof_h'

    * ================= display ============================================
    di
    di as txt "Identification menu: what these data can carry"
    _fivm_header "`depvar' on `endog'" "`exogfv'" `N'
    di as txt "{hline 76}"
    di as txt %-22s "route" %-28s "signal" %10s "value" "  verdict"
    di as txt "{hline 76}"

    * 1. bounds ------------------------------------------------------------
    local w = `hi' - `lo'
    di as txt %-22s "bounds" %-28s "width of the interval" ///
       as res %10.4f `w' as txt "  always"
    di as txt %-22s "" %-28s "[gamma-tilde/2, gamma-tilde]" ///
       as res "  [" %6.4f `lo' ", " %6.4f `hi' "]"

    * 2. third order -------------------------------------------------------
    _fivm_verdict `z_m03' 3 2
    local v1 "`s'"
    di as txt %-22s "third order: qme," %-28s "skewness of eps2" ///
       as res %10.4f `skew2'
    di as txt %-22s "  hme, lsz" %-28s "z of m03" as res %10.2f `z_m03' ///
       as txt "  `v1'"
    if (`disc' < .) {
        _fivm_verdict `disc_z' 2 1
        local v2 "`s'"
        * D = gamma^2 (2A - B)^2 cannot be negative under the model: far
        * below zero it is not a strong signal but a refutation
        if (`disc_z' <= -2) local v2 "REFUTES"
        di as txt %-22s "" %-28s "z of the discriminant D" ///
           as res %10.2f `disc_z' as txt "  `v2'"
        if (`disc_z' <= -2) {
            di as txt %-22s "" "  D < 0 beyond its noise: no one-factor model gives it"
        }
    }
    if (`disc' < 0) {
        di as txt %-22s "" %-28s "D < 0: the roots merge" ///
           as res %10s "." as txt "  vertex used"
    }
    * a precise qme outside the bounds is not usable: say that first
    if (`disc' >= 0 & `disc' < . & `nroots' == 0) {
        di as txt %-22s "" %-28s "roots inside the bounds" ///
           as res %10.0f `nroots' as txt "  NONE"
        di as txt %-22s "" "  no root is compatible with scale consistency"
    }
    else if (`se_qme' < .) {
        di as txt %-22s "" %-28s "implied s.e. of the QME" ///
           as res %10.4f `se_qme' as txt cond(`se_qme' > `w' / 4, ///
           "  wide", "  usable")
    }
    * A, B and mu are read at the qme, or at the vertex when the
    * discriminant is negative -- where B = 2A by construction, so that mu
    * is then 1/3 whatever the data, and says nothing
    if (`A' < .) {
        di as txt %-22s "" %-28s "A = alpha2^3 E[U^3]" as res %10.4f `A' ///
           as txt cond(`at_vertex' == 1, "  at the vertex", "")
        di as txt %-22s "" %-28s "mu = A/(A+B)" as res %10.4f `mu' ///
           as txt cond(`at_vertex' == 1, "  1/3 there", ///
                  cond(abs(`mu' - 1/3) < 0.10, "  near 1/3", ""))
    }

    * 3. symmetry of V2 (HME) ------------------------------------------------
    if (`B' < .) {
        local rel = cond(`m03' != 0, abs(`B' / `m03'), .)
        di as txt %-22s "symmetry of V2: hme" %-28s "B = E[V2^3], hme sets 0" ///
           as res %10.4f `B' as txt cond(`rel' < 0.2, "  plausible", "  doubtful")
        if (`at_vertex' == 1) {
            di as txt %-22s "" "  B read at the vertex, where B = 2A by construction"
        }
    }

    * 4. heteroskedasticity (Lewbel 2012) ------------------------------------
    if (`F_lew' < .) {
        di as txt %-22s "heteroskedasticity:" %-28s "F of eps2^2 on X" ///
           as res %10.2f `F_lew' as txt cond(`p_lew' < 0.05, "  present", "  absent")
        di as txt %-22s "  lewbel12" %-28s "p" as res %10.4f `p_lew'
    }
    else di as txt %-22s "heteroskedasticity:" %-28s "no exogenous control" ///
         as res %10s "." as txt "  unavailable"

    * 5. local slope profile --------------------------------------------------
    di as txt %-22s "local slope profile" %-28s "slope of xi on eps2 at p5" ///
       as res %10.4f `P'[1, 2] as txt "  h = " %5.3f `h'
    di as txt %-22s "  of E[xi | eps2]" %-28s "p10 / p25 / p50" ///
       as res %7.4f `P'[2, 2] " " %7.4f `P'[3, 2] " " %7.4f `P'[4, 2]
    di as txt %-22s "" %-28s "p75 / p90 / p95" ///
       as res %7.4f `P'[5, 2] " " %7.4f `P'[6, 2] " " %7.4f `P'[7, 2]
    di as txt %-22s "" %-28s "curvature z (max-min)" as res %10.2f `pz' ///
       as txt cond(`pz' >= 2 & `pz' < ., "  curved", cond(`pz' < ., "  flat", ""))
    * the bound reading needs a rising profile (m increasing): the minimum
    * must sit at p5 or p10.  An interior minimum is reported as such.
    local tight = cond(`jmin' > 2, "interior min", ///
        cond(`pmin' + 1.96 * `pmin_se' < `hi', "tightens", "no tightening"))
    di as txt %-22s "" %-28s "min slope, at p`pmin_p'" as res %10.4f `pmin' ///
       as txt "  `tight'"
    di as txt %-22s "" %-28s "tail ratio p95/p5" as res %10.2f `pratio' ///
       as txt cond(`pratio' < ., cond(abs(`pratio' - 2) < 0.5, "  near 2", "  not 2"), "")

    * 6. proxy ---------------------------------------------------------------
    di as txt %-22s "two indicators" %-28s "freeivmenu y1 x (y2 y3)" ///
       as res %10s "." as txt "  by syntax"

    di as txt "{hline 76}"
    di as txt "Reading: the first line is always true; the others say whether the"
    di as txt "assumption that identifies is carried by the data.  A weak signal does"
    di as txt "not make an estimator wrong, it makes it imprecise.  B = 0 is a"
    di as txt "restriction on the model, which the hme adds to the qme's."
    di as txt "The slope profile is flat when the confounder is Gaussian-like; its"
    di as txt "minimum bounds gamma from above when E[U|eps2] is increasing, and the"
    di as txt "tail ratio tends to 2 under scale consistency.  A curved profile is"
    di as txt "a skewed confounder or a non-linear outcome equation: it does not say"
    di as txt "which."

    * ---- r() ---------------------------------------------------------------
    foreach v of local vals {
        return scalar `v' = ``v''
    }
    return scalar z_m03 = `z_m03'
    return scalar prof_h     = `h'
    return scalar prof_min   = `pmin'
    return scalar prof_minse = `pmin_se'
    return scalar prof_ratio = `pratio'
    return scalar prof_z     = `pz'
    return matrix profile = `P'
    return scalar F_lewbel = `F_lew'
    return scalar p_lewbel = `p_lew'
    return matrix moments = `M'
end


program define _fivm_verdict
    args z hi lo
    if ("`z'" == "" | `z' >= .) local s "undecidable"
    else if (abs(`z') >= `hi')  local s "strong"
    else if (abs(`z') >= `lo')  local s "weak"
    else                        local s "absent"
    c_local s "`s'"
end


* the header line "y on ..., controls ...   n = N": n sits at column 56 when
* the text leaves room for it, on its own line otherwise
program define _fivm_header
    args text controls N
    local controls = trim(stritrim("`controls'"))
    if ("`controls'" != "") local text "`text', controls `controls'"
    if (length("`text'") <= 52) {
        di as txt "`text'" _col(56) "n = " as res %8.0f `N'
    }
    else {
        di as txt "`text'"
        di as txt _col(56) "n = " as res %8.0f `N'
    }
end


* the local slope profile of xi on e2: kernel-weighted slope at seven
* percentiles of e2, Gaussian kernel, h = 2 * 1.06 * sd(e2) * N^(-1/5) unless
* bw > 0.  Fills matrix M (7 x 3: point, slope, se) and sets in the caller
* prof_h, pmin, pmin_se, pmin_p, jmin, pratio, pz.
program define _fivm_profile
    args M xi e2 touse wname wexp2 bw N
    qui summarize `e2' `wexp2' if `touse'
    local h = cond(`bw' > 0, `bw', 2 * 1.06 * r(sd) * `N'^(-0.2))
    local probs "5 10 25 50 75 90 95"
    _pctile `e2' `wexp2' if `touse', p(`probs')
    forvalues j = 1/7 {
        local q`j' = r(r`j')
    }
    matrix `M' = J(7, 3, .)
    tempvar kw
    forvalues j = 1/7 {
        qui gen double `kw' = exp(-0.5 * ((`e2' - `q`j'') / `h')^2) if `touse'
        if ("`wname'" != "") qui replace `kw' = `kw' * `wname' if `touse'
        cap qui regress `xi' `e2' [aw = `kw'] if `touse', vce(robust)
        if (_rc == 0) {
            matrix `M'[`j', 1] = `q`j''
            matrix `M'[`j', 2] = _b[`e2']
            matrix `M'[`j', 3] = _se[`e2']
        }
        drop `kw'
    }
    matrix colnames `M' = eps2 slope se
    matrix rownames `M' = p5 p10 p25 p50 p75 p90 p95
    local pmin = .
    local jmin = 0
    local jmax = 0
    local pmax = .
    forvalues j = 1/7 {
        local b = `M'[`j', 2]
        if (`b' < . & (`pmin' >= . | `b' < `pmin')) {
            local pmin = `b'
            local jmin = `j'
        }
        if (`b' < . & (`pmax' >= . | `b' > `pmax')) {
            local pmax = `b'
            local jmax = `j'
        }
    }
    local pmin_se = cond(`jmin' > 0, `M'[`jmin', 3], .)
    local pmax_se = cond(`jmax' > 0, `M'[`jmax', 3], .)
    local pratio  = cond(`M'[1, 2] != 0 & `M'[1, 2] < ., `M'[7, 2] / `M'[1, 2], .)
    local pz      = cond(`pmin_se' < . & `pmax_se' < ., ///
                    (`pmax' - `pmin') / sqrt(`pmax_se'^2 + `pmin_se'^2), .)
    local pmin_p : word `jmin' of `probs'
    c_local prof_h  `h'
    c_local pmin    `pmin'
    c_local pmin_se `pmin_se'
    c_local pmin_p  `pmin_p'
    c_local jmin    `jmin'
    c_local pratio  `pratio'
    c_local pz      `pz'
end
