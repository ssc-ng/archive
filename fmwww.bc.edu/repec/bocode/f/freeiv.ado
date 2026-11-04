*! freeiv 1.0.0  06oct2026  A. Araar (Universite Laval / PEP)
*! Instrument-free estimation of a linear model whose endogenous regressor
*! shares an unobserved confounder with the outcome.
*!
*!   freeiv depvar [indepvars] (endogvar) [if] [in] [pw aw]
*!          [, METHod(name) VCE(svy) Level(#) DELta(#) RMAX(#) SIGN(#)
*!             noHEADer ]
*!   freeiv depvar [indepvars] (endogvar1 endogvar2) [if] [in] [pw aw]
*!          [, VCE(svy) Level(#) noHEADer ]
*!
*! MODEL A, one endogenous regressor,
*!     Y2 = X'b2 + alpha2 U + V2,    Y1 = X'b1 + gamma Y2 + alpha1 U + V1,
*! with scale consistency, alpha1 = gamma alpha2, maintained.  The second
*! moments give the OLS slope gamma-tilde = gamma (1 + c), where
*! c = theta/(theta + sigma2_V2) in [0, 1] is the one number they leave free:
*! hence the bounds [gamma-tilde/2, gamma-tilde].  The routes impose the
*! structure order after order:
*!   bounds ols    order 2: the interval (OLS is its upper end)
*!   qme           order 3, exactly identified: the root in the bounds of
*!                 2 m03 g^2 - 3 m12 g + m21 = 0 (the default)
*!   hme           order 3 with V1 and V2 symmetric: (m30/m03)^(1/3) / 2
*!   gmm           orders 2 to 4: nine moments, eight parameters, a J on
*!                 1 df, minimised on a deterministic grid, with the region
*!                 where the profiled J stays within 3.84 of its minimum
*!   pgmm          the same moments with orders 2 and 3 fitted exactly: the
*!                 companion of gmm; a gap between the two signals a flat
*!                 criterion
*!   lsz lewbel12 copula rank oster
*!                 other maintained models -- Lewbel, Schennach and Zhang
*!                 (2024), Lewbel (2012), Park and Gupta (2012), Breitung,
*!                 Mayer and Wied (2024), Oster (2019) -- on the same data,
*!                 judged by the same bounds
*!   all           every route; retains the qme
*!
*! MODEL B, two indicators of the same confounder, (y2 y3): the closed form
*! of Theorem 1 of ARAARP4 identifies g2, g3 and the loading a1 with no
*! scale-consistency restriction, under three guards; that restriction
*! becomes testable, and sixteen moments over-identify the model (J, 4 df).
*!
*! Standard errors: the delta method on the covariance of the moment
*! contributions, the estimation of the coefficients on X accounted for --
*! with [pweight], in sandwich form; with vce(svy), linearized over the
*! design of svyset (strata, PSUs and fpc of the first stage), with t on
*! the design degrees of freedom.  lewbel12, copula, rank and oster have a
*! point estimate only: use the -bootstrap- prefix.
*!
*! 1.0.0 (6 Oct 2026): the routes sce, rre, qbe, rpiv and ape are removed,
*! with quantile(); fweights are removed; pweights in sandwich form and
*! vce(svy) are added; e(g_gmm) is the joint GMM and e(g_pgmm) the profiled
*! one; e(cshare) replaces k and k*; the hme takes a negative effect; the
*! joint GMM is computed only where it is reported, under method(gmm) and
*! method(all), so that every other route runs ten times faster.
*!
*! Reference: Araar, A. (2026), Zenodo, concept DOIs (all versions)
*! 10.5281/zenodo.20312356, 22068003, 22119231, 22207331; the paper of the
*! command, 10.5281/zenodo.22770175.

* Notes for the maintainer.
*
* The joint GMM is minimised deterministically rather than by multi-start:
* fix gamma AND theta and the only non-linearity left, the product
* theta*sV2, disappears, so the nine residuals are linear in the six
* remaining parameters; the eight-parameter problem is a two-dimensional
* surface, and a surface can be gridded.  Multi-start over the eight
* parameters returns a LOCAL minimum on six of the eight datasets of ARAARP3.
*
* What the J tests: scale consistency itself, plus the linearity of the
* confounder's effect.  Write eps2 = U + V2 and xi = tau U + gamma V2 + V1
* with tau free; scale consistency is tau = 2 gamma.  The Jacobian of the
* nine moments in the nine free parameters has determinant
*     -(gamma - tau)^5 * (B kurt_U - A kurt_V2)
* so tau = 2 gamma is testable everywhere except on tau = gamma and where
* the second factor vanishes -- which a normal V2 does (B = 0, kurt_V2 = 0).
* Only the vanishing of that factor is meaningful, not its magnitude.
*
* lsz is Lewbel, Schennach and Zhang (2024) with p(0 1), exactly as trigmm
* implements it: just identified, so a damped Newton reaches trigmm's root.
* It leaves the loading of U in the outcome free -- the whole difference
* with scale consistency -- so confronting it with the bounds tests the
* scale-consistent model, not LSZ.

cap program drop freeiv
cap program drop _freeiv_lev
cap program drop _freeiv_display
cap program drop _freeiv_fmt
cap program drop _freeiv_out
cap program drop _freeiv_row
cap program drop _freeiv_ident
cap program drop _freeiv_vcefoot
cap program drop _freeiv_pdisplay
cap program drop _freeiv_pident
cap program drop _fivp_line
cap program drop _freeiv_bsnote

program define freeiv, eclass
    version 16
    if replay() {
        if ("`e(cmd)'" != "freeiv") error 301
        syntax [, noHEADer Level(string) *]
        local lopt ""
        if ("`level'" != "") {
            cap confirm number `level'
            if (_rc) local level = -1
            if (`level' < 10 | `level' > 99.99) {
                di as err "level() must be between 10 and 99.99 inclusive"
                exit 198
            }
            local lopt "level(`level')"
        }
        _freeiv_display, `header' `lopt'
        exit
    }

    syntax anything(name=eqs equalok) [if] [in] [pw aw] ///
        [, METHod(name) VCE(string) Level(cilevel) noHEADer ///
           DELta(real 1) RMAX(real -1) SIGN(real 1) ]

    * ---- option values that can be judged before the data ----------------
    * An option quietly absorbed is worse than one refused: sign() used to go
    * straight to Mata, where any positive value acted as 1 and any negative
    * as -1, so a typo survived intact into e(lsz_sign).
    if (`sign' != 1 & `sign' != -1) {
        di as err "sign() must be 1 or -1"
        exit 198
    }
    if (`delta' >= .) {
        di as err "delta() must be a number"
        exit 198
    }
    if (`rmax' != -1 & (`rmax' <= 0 | `rmax' > 1)) {
        di as err "rmax() is an R-squared: it must lie in (0, 1]"
        di as err "    omit it for the default, min(1.3 R1, 1)"
        exit 198
    }
    local vce = lower(trim("`vce'"))
    if (!inlist("`vce'", "", "svy")) {
        di as err "vce(`vce') not allowed: vce() takes svy only"
        di as err "    without it, the standard errors are the delta method on the"
        di as err "    covariance of the moment contributions, in sandwich form"
        di as err "    with pweights; vce(svy) uses the design declared by svyset"
        exit 198
    }
    if ("`vce'" == "svy" & "`weight'" != "") {
        di as err "weights not allowed with vce(svy): the weights are those"
        di as err "    declared by svyset"
        exit 101
    }

    * ---- method ----------------------------------------------------------
    local usermeth "`method'"
    if ("`method'" == "") local method qme
    local method = lower("`method'")
    if (inlist("`method'", "sce", "rre", "qbe", "rpiv", "ape")) {
        di as err "method(`method') was removed in freeiv 1.0.0; see the"
        di as err "    section on the routes removed in -help freeiv-"
        exit 198
    }
    if (!inlist("`method'", "bounds", "ols", "qme", "hme", "gmm") & ///
        !inlist("`method'", "pgmm", "lsz", "lewbel12", "copula") & ///
        !inlist("`method'", "rank", "oster", "all")) {
        di as err "method() must be one of:"
        di as err "    bounds ols                       the interval"
        di as err "    qme hme                          order 3"
        di as err "    gmm pgmm                         order 4"
        di as err "    lsz lewbel12 copula rank oster   other maintained models"
        di as err "    all"
        exit 198
    }
    local rmaxopt = cond(`rmax' < 0, ., `rmax')

    * ---- endogenous variables go in parentheses --------------------------
    local p1 = strpos("`eqs'", "(")
    local p2 = strpos("`eqs'", ")")
    if (`p1' == 0 | `p2' == 0 | `p2' < `p1') {
        di as err "the endogenous variable must be given in parentheses:"
        di as err "    freeiv depvar [indepvars] (endogvar) ..."
        exit 198
    }
    local endog = trim(substr("`eqs'", `p1' + 1, `p2' - `p1' - 1))
    local rest  = trim(substr("`eqs'", 1, `p1' - 1)) + " " ///
                + trim(substr("`eqs'", `p2' + 1, .))
    local rest  = trim(stritrim("`rest'"))
    gettoken depvar exog : rest
    local exog = trim("`exog'")

    if ("`depvar'" == "") {
        di as err "dependent variable missing"
        exit 198
    }
    confirm numeric variable `depvar'
    local nend : word count `endog'
    if (`nend' == 0) {
        di as err "no endogenous variable inside the parentheses"
        exit 198
    }
    if (`nend' > 2) {
        di as err "freeiv accepts one endogenous regressor, or two sharing a"
        di as err "single latent confounder:  freeiv y1 x (y2 y3)"
        exit 198
    }
    confirm numeric variable `endog'

    * ---- factor variables among the controls -----------------------------
    * i.sex, ib2.region, i.sex##c.age.  fvrevar expands them into temporary
    * indicators with the base level omitted; the projection that partials X
    * out is computed with invsym, a generalized inverse, so an expansion
    * that turns out collinear is absorbed rather than fatal.
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

    * ---- one variable, one role ------------------------------------------
    local clash : list depvar & endog
    if ("`clash'" != "") {
        di as err "`clash' cannot be both the dependent and an endogenous variable"
        exit 198
    }
    if ("`exogbase'" != "") {
        local clash : list depvar & exogbase
        if ("`clash'" != "") {
            di as err "`clash' cannot be both the dependent variable and a control"
            exit 198
        }
        local clash : list endog & exogbase
        if ("`clash'" != "") {
            di as err "`clash' cannot be both endogenous and a control"
            exit 198
        }
    }
    if (`nend' == 2) {
        local e2chk : word 1 of `endog'
        local e3chk : word 2 of `endog'
        if ("`e2chk'" == "`e3chk'") {
            di as err "the two endogenous variables must differ"
            exit 198
        }
    }

    * ---- a route the specification cannot carry --------------------------
    if ("`exogfv'" == "" & inlist("`method'", "lewbel12", "rank", "oster")) {
        di as err "method(`method') needs at least one exogenous control"
        if ("`method'" == "lewbel12") {
            di as err "    its instruments are (X - mean X) * eps2"
        }
        else if ("`method'" == "rank") {
            di as err "    its control function is the rank of the residual of"
            di as err "    `endog' on the controls; with none it is the copula"
        }
        else {
            di as err "    it compares the R-squared with and without controls"
        }
        exit 198
    }
    if ("`exogfv'" == "" & "`method'" == "all") {
        di as txt "note: no exogenous control, so lewbel12, rank and oster are unavailable"
    }
    if (`nend' == 2) {
        * These steer a route of the one-endogenous model and are inert
        * here.  Accepting them silently would return a result that looks
        * like the result of what was asked for, so they are refused,
        * exactly like method(lewbel12) with no exogenous control.
        local inert ""
        if ("`usermeth'" != "")  local inert "`inert' method()"
        if (`delta' != 1)        local inert "`inert' delta()"
        if (`rmax' != -1)        local inert "`inert' rmax()"
        if (`sign' != 1)         local inert "`inert' sign()"
        if ("`inert'" != "") {
            di as err "these options do not apply with two endogenous" ///
                      " regressors:`inert'"
            di as err "    the two-indicator model has a single closed-form"
            di as err "    route; level(), vce(svy) and noheader are the only"
            di as err "    options it takes"
            exit 198
        }
    }

    freeiv_engine

    marksample touse
    markout `touse' `depvar' `endog' `exogbase'

    * ---- weights and the variance -----------------------------------------
    * Every standard error is the delta method on the covariance of the
    * moment contributions, and one Mata function, _fiv_cov(), computes that
    * covariance for all of them.  The design it uses is set just before the
    * engines run and cleared right after, so that freeivmenu and the other
    * commands never meet a stale one:
    *     no weight, [aweight]   sum w psi psi' / sum w
    *     [pweight]              sandwich form, every observation its own
    *                            primary unit
    *     vce(svy)               the strata, PSUs and fpc of svyset, first
    *                            stage (Taylor linearization)
    cap mata: _fiv_vclear()
    local wname   ""
    local svyw    ""
    local svystr  ""
    local svypsu  ""
    local svyfpc  ""
    local svysu   ""
    local svycert = 0
    local fpcdrop = 0
    if ("`vce'" == "svy") {
        qui svyset
        if ("`r(settings)'" == ", clear") {
            di as err "data not set up for svy, use svyset"
            exit 119
        }
        if ("`r(poststrata)'" != "") {
            di as err "vce(svy) does not handle poststratification"
            exit 198
        }
        local svysu "`r(singleunit)'"
        if (!inlist("`svysu'", "", "missing", "certainty")) {
            di as err "vce(svy) handles singleunit(missing) and"
            di as err "    singleunit(certainty), not singleunit(`svysu')"
            exit 198
        }
        local svycert = ("`svysu'" == "certainty")
        local weight "`r(wtype)'"
        local exp    "`r(wexp)'"
        local svyw   "`r(wvar)'"
        local svystr "`r(strata1)'"
        local svypsu "`r(su1)'"
        local svyfpc "`r(fpc1)'"
        if ("`svypsu'" == "_n") local svypsu ""
        * In a multistage design with an fpc at the first stage, the
        * linearized variance adds the later stages; freeiv uses the first
        * stage only, so it drops that fpc and treats the first stage as
        * drawn with replacement, which errs towards a larger variance.
        if (r(stages) > 1 & "`svyfpc'" != "") {
            local svyfpc ""
            local fpcdrop = 1
        }
        markout `touse' `svyw' `svyfpc'
        markout `touse' `svystr' `svypsu', strok
        if ("`svyw'" != "") {
            qui count if `touse' & `svyw' < 0
            if (r(N)) {
                di as err "negative weights encountered"
                exit 402
            }
            local wname "`svyw'"
        }
    }
    else if ("`weight'" != "") {
        tempvar wv
        qui gen double `wv' `exp' if `touse'
        qui count if `touse' & `wv' < 0
        if (r(N)) {
            di as err "negative weights encountered"
            exit 402
        }
        local wname "`wv'"
    }

    qui count if `touse'
    local N = r(N)
    if (`N' < 20) {
        di as err "too few observations (`N')"
        exit 2001
    }
    if ("`wname'" != "") {
        qui su `wname' if `touse', meanonly
        local Npop = r(sum)
    }
    else local Npop = `N'

    * the factor variables become temporary indicators, built on the
    * estimation sample so that an empty level outside it cannot create a
    * column of zeros
    if ("`exogfv'" != "") {
        fvrevar `exogfv' if `touse', substitute
        local exog "`r(varlist)'"
    }

    * ---- the design, then the engines -------------------------------------
    if ("`vce'" == "svy") {
        mata: _fiv_vset("`svystr'", "`svypsu'", "`svyfpc'", "`touse'", `svycert')
    }
    else if ("`weight'" == "pweight") {
        mata: _fiv_vset("", "", "", "`touse'", 0)
    }
    tempname DI
    mata: st_matrix("`DI'", _fiv_vinfo())
    local Nstrata = `DI'[1, 1]
    local Npsu    = `DI'[1, 2]
    local Nsingle = `DI'[1, 3]
    local df_r = .
    if ("`vce'" == "svy") {
        local df_r = `Npsu' - `Nstrata'
        if (`df_r' < 1) local df_r = .
    }
    local dofopt ""
    if (`df_r' < .) local dofopt "dof(`df_r')"

    capture noisily {
        if (`nend' == 2) {
            * ============ model B: two indicators of one confounder ==========
            gettoken en2 en3 : endog
            local en3 = trim("`en3'")
            mata: _freeiv_proxy("`depvar'", "`en2'", "`en3'", "`exog'", ///
                                "`wname'", "`touse'")
            tempname P PV
            matrix `P'  = __freeiv_P
            matrix `PV' = __freeiv_PV
            matrix drop __freeiv_P __freeiv_PV
            local pvals : colnames `P'
            local j = 0
            foreach v of local pvals {
                local ++j
                local q`v' = `P'[1, `j']
            }

            * the over-identified GMM on sixteen moments
            mata: _freeiv_gmm16("`depvar'", "`en2'", "`en3'", "`exog'", ///
                                "`wname'", "`touse'")
            tempname Q16
            matrix `Q16' = __freeiv_Q16
            matrix drop __freeiv_Q16
            local qvals : colnames `Q16'
            local j = 0
            foreach v of local qvals {
                local ++j
                local Q_`v' = `Q16'[1, `j']
            }

            * the two tests model A cannot perform
            mata: _freeiv_ptests("`depvar'", "`en2'", "`en3'", "`exog'", ///
                                 "`wname'", "`touse'")
            tempname PT
            matrix `PT' = __freeiv_PT
            matrix drop __freeiv_PT
            local ptvals : colnames `PT'
            local j = 0
            foreach v of local ptvals {
                local ++j
                local T_`v' = `PT'[1, `j']
            }
        }
        else {
            * ============ model A: one endogenous regressor ==================
            mata: _freeiv_all("`depvar'", "`endog'", "`exog'", "`wname'", ///
                              "`touse'", "", "")
            tempname M VM GM
            matrix `M'  = __freeiv_M
            matrix `VM' = __freeiv_V
            matrix `GM' = __freeiv_G
            matrix drop __freeiv_M __freeiv_V __freeiv_G
            local vals : colnames `M'
            local j = 0
            foreach v of local vals {
                local ++j
                local `v' = `M'[1, `j']
            }

            * the other maintained models, on the same data
            mata: _freeiv_lit("`depvar'", "`endog'", "`exog'", "`wname'", ///
                              "`touse'", `delta', `rmaxopt')
            tempname L
            matrix `L' = __freeiv_L
            matrix drop __freeiv_L
            local lvals : colnames `L'
            local j = 0
            foreach v of local lvals {
                local ++j
                local L_`v' = `L'[1, `j']
            }

            * the profiled GMM, method(pgmm)
            mata: _freeiv_gmm("`depvar'", "`endog'", "`exog'", "`wname'", ///
                              "`touse'")
            tempname G4
            matrix `G4' = __freeiv_G4
            matrix drop __freeiv_G4
            local gvals : colnames `G4'
            local j = 0
            foreach v of local gvals {
                local ++j
                local G_`v' = `G4'[1, `j']
            }

            * The joint nine-moment GMM, method(gmm): nine residuals in eight
            * free parameters, minimised on the two-dimensional profile in
            * (gamma, theta) -- deterministic, no seed -- with the region where
            * its profiled J stays within 3.84 of its minimum.  It is computed
            * only where it is reported, under method(gmm) and method(all):
            * without its region it is still nine tenths of the time of a call
            * (0.375 of 0.40 s on Card), so every other route, and every
            * bootstrap replication of it, runs ten times faster.  The other
            * methods post e(g_gmm) and its companions as missing, as they do
            * e(lsz*), and their output reads the J of the profiled GMM, which
            * tests the same restriction on the same moments.
            local jvals "n g_gmm se_gmm J_gmm p_gmm df_gmm gmm_theta gmm_sV2 gmm_sV1 gmm_A gmm_B gmm_A4 gmm_B4 gmm_kurt ar_lo ar_hi ar_frac gmm_weak gmm_bound g_lo g_hi"
            tempname G9
            if (inlist("`method'", "gmm", "all")) {
                mata: _freeiv_jgmm("`depvar'", "`endog'", "`exog'", ///
                                   "`wname'", "`touse'", 1)
                matrix `G9' = __freeiv_G9
                matrix drop __freeiv_G9
                local jvals : colnames `G9'
                local j = 0
                foreach v of local jvals {
                    local ++j
                    local G_`v' = `G9'[1, `j']
                }
            }
            else {
                foreach v of local jvals {
                    local G_`v' = .
                }
                local G_n = `N'
                matrix `G9' = J(1, `: word count `jvals'', .)
                matrix `G9'[1, 1] = `N'
                matrix colnames `G9' = `jvals'
            }

            * LSZ (2024), as trigmm implements it, p(0 1).  A Levenberg-
            * Marquardt on 5 + 2(k+1) parameters with a numeric Jacobian, whose
            * cost grows with the number of controls as well as with n: it runs
            * only when asked for, and the other methods post e(lsz*) as
            * missing so that the shape of e() does not depend on method().
            local zvals "n lsz se_lsz lsz_beta lsz_var_u lsz_var_v lsz_var_r lsz_crit lsz_conv lsz_iter lsz_nmom lsz_npar lsz_sign"
            tempname LZ
            if (inlist("`method'", "lsz", "all")) {
                mata: _freeiv_lsz("`depvar'", "`endog'", "`exog'", ///
                                  "`wname'", "`touse'", `sign')
                matrix `LZ' = __freeiv_LSZ
                matrix drop __freeiv_LSZ
                local zvals : colnames `LZ'
                local j = 0
                foreach v of local zvals {
                    local ++j
                    local Z_`v' = `LZ'[1, `j']
                }
            }
            else {
                foreach v of local zvals {
                    local Z_`v' = .
                }
                local Z_n = `N'
                matrix `LZ' = J(1, `: word count `zvals'', .)
                matrix `LZ'[1, 1] = `N'
                matrix colnames `LZ' = `zvals'
            }
        }
    }
    local rc = _rc
    cap mata: _fiv_vclear()
    if (`rc') exit `rc'

    if (`nend' == 2) {
        * ---- e(), model B -----------------------------------------------------
        tempname b V
        if (`qguard' == 0) {
            matrix `b' = (`qg2', `qg3')
            matrix colnames `b' = `en2' `en3'
            matrix rownames `b' = y1
            matrix `V' = `PV'[1..2, 1..2]
            matrix colnames `V' = `en2' `en3'
            matrix rownames `V' = `en2' `en3'
            cap ereturn post `b' `V', esample(`touse') obs(`N') ///
                depname(`depvar') `dofopt'
            if (_rc) ereturn post `b', esample(`touse') obs(`N') ///
                depname(`depvar') `dofopt'
        }
        else ereturn post, esample(`touse') obs(`N') depname(`depvar') `dofopt'

        ereturn local cmd     "freeiv"
        ereturn local cmdline "freeiv `0'"
        ereturn local method  "proxy"
        ereturn local model   "B"
        ereturn local depvar  "`depvar'"
        ereturn local endog   "`endog'"
        ereturn local endog2  "`en2'"
        ereturn local endog3  "`en3'"
        ereturn local exog    "`exogfv'"
        ereturn local title   "Instrument-free estimation, two indicators"
        foreach v of local pvals {
            ereturn scalar `v' = `q`v''
        }
        foreach v of local ptvals {
            if ("`v'" != "n") ereturn scalar `v' = `T_`v''
        }
        foreach v of local qvals {
            if ("`v'" != "n") ereturn scalar `v' = `Q_`v''
        }
        ereturn matrix pmoments = `P'
        cap ereturn matrix pcov = `PV'
        ereturn matrix ptests = `PT'
        ereturn matrix gmm16  = `Q16'
    }
    else {
        * ---- the retained value and its standard error ------------------------
        * method(all) retains the same point as method(qme), vertex fallback
        * included, so that e(b) and e(V) mean the same thing in both
        local qme_flag ""
        if (inlist("`method'", "qme", "all") & `at_vertex' == 1) {
            local gamma = `vertex'
            local segam = `se_vertex'
            local qme_flag "vertex"
        }
        else if (inlist("`method'", "qme", "all")) {
            local gamma = `qme'
            local segam = `se_qme'
        }
        else if ("`method'" == "ols") {
            local gamma = `ols'
            local segam = `se_gt'
        }
        else if ("`method'" == "hme") {
            local gamma = `hme'
            local segam = `se_hme'
        }
        else if ("`method'" == "bounds") {
            local gamma = .
            local segam = .
        }
        else if ("`method'" == "gmm") {
            local gamma = `G_g_gmm'
            * at a minimum on the boundary the delta method has nothing to
            * expand around: the standard error is suppressed, not missing
            local segam = cond(`G_gmm_bound' == 1, ., `G_se_gmm')
        }
        else if ("`method'" == "pgmm") {
            local gamma = `G_g_pgmm'
            local segam = `G_se_pgmm'
        }
        else if ("`method'" == "lsz") {
            local gamma = `Z_lsz'
            * a solver that did not converge would report the most precise-
            * looking number of the table: its standard error is not shown
            local segam = cond(`Z_lsz_conv' != 1, ., `Z_se_lsz')
        }
        else {
            local gamma = `L_`method''
            local segam = .
        }

        * ---- e(), model A -----------------------------------------------------
        * e(V) carries the variance of the retained value.  At a boundary
        * minimum of method(gmm) the display suppresses the standard error
        * and e(se) is missing, but e(V) still carries the delta-method one:
        * the -bootstrap- prefix requires e(V) in every replication once the
        * full sample has posted one (_check_omit), and a draw whose minimum
        * is on the boundary is an estimate, which must be kept, not dropped
        local vpost = `segam'
        if ("`method'" == "gmm" & `vpost' >= .) local vpost = `G_se_gmm'
        tempname b V
        if (`gamma' < .) {
            matrix `b' = (`gamma')
            matrix colnames `b' = `endog'
            matrix rownames `b' = y1
            if (`vpost' < .) {
                matrix `V' = (`vpost'^2)
                matrix colnames `V' = `endog'
                matrix rownames `V' = `endog'
                ereturn post `b' `V', esample(`touse') obs(`N') ///
                    depname(`depvar') `dofopt'
            }
            else ereturn post `b', esample(`touse') obs(`N') ///
                depname(`depvar') `dofopt'
        }
        else ereturn post, esample(`touse') obs(`N') depname(`depvar') `dofopt'

        ereturn local cmd      "freeiv"
        ereturn local cmdline  "freeiv `0'"
        ereturn local method   "`method'"
        ereturn local model    "A"
        ereturn local depvar   "`depvar'"
        ereturn local endog    "`endog'"
        ereturn local exog     "`exogfv'"
        ereturn local title    "Instrument-free estimation"
        ereturn local qme_flag "`qme_flag'"
        foreach v of local vals {
            ereturn scalar `v' = ``v''
        }
        * e(rank) belongs to -ereturn post- (the rank of V), so the rank-based
        * control-function estimate is posted as e(g_rank); e(ols) is already
        * there from the moments
        foreach v of local lvals {
            if (inlist("`v'", "n", "ols")) continue
            if ("`v'" == "rank") ereturn scalar g_rank = `L_rank'
            else                 ereturn scalar `v' = `L_`v''
        }
        * g_lo and g_hi are the search domains of the two GMM, the bounds
        * pulled in by a hair, and e(lo), e(hi) already carry the bounds
        foreach v in `gvals' `jvals' {
            if (inlist("`v'", "n", "g_lo", "g_hi")) continue
            ereturn scalar `v' = `G_`v''
        }
        foreach v of local zvals {
            if ("`v'" != "n") ereturn scalar `v' = `Z_`v''
        }
        ereturn scalar gamma   = `gamma'
        ereturn scalar se      = `segam'
        ereturn matrix moments = `M'
        ereturn matrix Vmom    = `VM'
        ereturn matrix grad    = `GM'
        ereturn matrix lit     = `L'
        ereturn matrix pgmm    = `G4'
        ereturn matrix gmm     = `G9'
        ereturn matrix lszmat  = `LZ'
    }

    * ---- e(), the variance ---------------------------------------------------
    ereturn local wtype "`weight'"
    ereturn local wexp  "`exp'"
    ereturn scalar level = `level'
    ereturn scalar N_pop = `Npop'
    if ("`vce'" == "svy") {
        ereturn local vce        "linearized"
        ereturn local vcetype    "Linearized"
        ereturn local strata1    "`svystr'"
        ereturn local su1        "`svypsu'"
        ereturn local fpc1       "`svyfpc'"
        ereturn local singleunit "`svysu'"
        ereturn scalar N_strata    = `Nstrata'
        ereturn scalar N_psu       = `Npsu'
        ereturn scalar N_single    = `Nsingle'
        ereturn scalar fpc_dropped = `fpcdrop'
    }
    else if ("`weight'" == "pweight") {
        ereturn local vce     "robust"
        ereturn local vcetype "Robust"
    }
    else {
        ereturn local vce     "delta"
    }

    if (`nend' == 2) _freeiv_pdisplay, `header'
    else             _freeiv_display, `header'

    * A route asked for alone that has no estimate on these data ends, after
    * its display and with e() posted, with a return code, as Stata's own
    * estimators do when they do not converge (ivpoisson: r(430)).  Under
    * the -bootstrap- prefix such a draw is then dropped and counted
    * (e(N_misreps)), as -equaids- and -easi- do in their vce(bootstrap),
    * instead of being kept at the value where a solver stopped.  The count
    * is the measure of that selection: the standard error of the draws
    * kept describes the estimator where the data satisfy the conditions of
    * its model, so it is read only when the count is small.  method(all)
    * is a table of routes and keeps r(0); method(bounds) has no point.
    * The display above says why there is no estimate, so the code comes
    * without a message of its own: under the prefix, a message would be
    * printed once for every replication dropped.
    if (`nend' == 1 & !inlist("`method'", "all", "bounds")) {
        if ("`method'" == "lsz" & e(lsz_conv) != 1) exit 430
        if (e(gamma) >= .) exit 498
    }
    * the two-indicator model when a guard of Proposition 1 fires: no estimate
    if (`nend' == 2 & e(guard) != 0) exit 498
end


* Under the -bootstrap- or -jackknife- prefix: how many replications have an
* estimate.  A replication in which the route has none ends with r(430) or
* r(498) (the end of -freeiv-), the prefix drops it, and every statistic of
* the table above is computed on the replications kept.  The share is part
* of the result: where it is low, the data often fail the conditions of the
* route's model, and the replications kept are a selected subset of them.
program define _freeiv_bsnote
    if (e(N_reps) >= .) exit
    local nok  = e(N_reps)
    local nmis = cond(e(N_misreps) < ., e(N_misreps), 0)
    local ntot = `nok' + `nmis'
    if (`ntot' <= 0) exit
    local pfx = cond("`e(prefix)'" != "", "`e(prefix)'", "bootstrap")
    di as txt "`pfx': " as res `nok' as txt " of " as res `ntot' ///
       as txt " replications have an estimate (" ///
       as res string(round(100 * `nok' / `ntot')) as txt "%)"
    if (`nmis' > 0) {
        di as txt "    the statistics above are computed on these " ///
           as res `nok' as txt " only (help freeiv, bootstrap)"
    }
end


* the confidence level of a display: the one asked for, or that of the
* estimation
program define _freeiv_lev
    args level
    if ("`level'" != "") local lev = `level'
    else                 local lev = e(level)
    cap confirm number `lev'
    if (_rc) local lev = 95
    if (`lev' >= . | `lev' <= 0 | `lev' >= 100) local lev = 95
    c_local lev `lev'
end


program define _freeiv_fmt
    args v
    if ("`v'" == "") local v = .
    cap confirm number `v'
    if (_rc) local v = .
    if (`v' >= .) local s "        ."
    else          local s = string(`v', "%10.6f")
    c_local s "`s'"
end


* "outside the bounds" when an estimate lies outside [e(lo), e(hi)], with a
* tolerance: the OLS slope IS an end of the interval, and a rounding error
* must not move it outside
program define _freeiv_out
    args v
    local o ""
    if ("`v'" != "" & "`v'" != ".") {
        if (`v' < . & e(lo) < . & e(hi) < .) {
            local tol = 1e-8 * max(abs(e(lo)), abs(e(hi)), 1)
            if (`v' < e(lo) - `tol' | `v' > e(hi) + `tol') {
                local o "outside the bounds"
            }
        }
    }
    c_local out "`o'"
end


* one row of the method(all) table
program define _freeiv_row
    args lab est se extra
    _freeiv_fmt `est'
    local se1 "`s'"
    _freeiv_fmt `se'
    di as txt "    " %-18s "`lab'" _col(26) as res "`se1'" _col(38) "`s'" ///
       as txt "  `extra'"
end


program define _freeiv_display
    syntax [, noHEADer Level(string)]
    if ("`e(cmd)'" != "freeiv") exit
    if ("`e(model)'" == "B") {
        local lopt ""
        if ("`level'" != "") local lopt "level(`level')"
        _freeiv_pdisplay, `header' `lopt'
        exit
    }
    _freeiv_lev `level'
    * Under a prefix (bootstrap, jackknife) the prefix owns the coefficient
    * table: let it print, and only add the identification block.
    local pref "`e(prefix)'"
    if ("`pref'" != "" | e(N_reps) < .) {
        cap noisily ereturn display, level(`lev')
        _freeiv_bsnote
        cap noisily _freeiv_ident
        exit
    }
    * t on the design degrees of freedom under vce(svy), the normal otherwise
    if (e(df_r) < .) {
        local crit = invttail(e(df_r), (100 - `lev') / 200)
        local st "t"
    }
    else {
        local crit = invnormal(1 - (100 - `lev') / 200)
        local st "z"
    }
    local m "`e(method)'"
    di
    if ("`header'" == "") {
        di as txt "Instrument-free estimation" _col(44) "Number of obs    = " ///
           as res %9.0fc e(N)
        if ("`e(vce)'" == "linearized") {
            di as txt _col(44) "Number of strata = " as res %9.0fc e(N_strata)
            di as txt _col(44) "Number of PSUs   = " as res %9.0fc e(N_psu)
            di as txt _col(44) "Design df        = " as res %9.0fc e(df_r)
        }
        di as txt "model: " as res "`e(depvar)'" as txt " on " ///
           as res "`e(endog)'" as txt cond("`e(exog)'" != "", ", controls " + "`e(exog)'", "")
        di as txt "method: " as res "`m'"
    }
    di as txt "{hline 72}"

    if ("`m'" == "all") {
        local anyout 0
        di as txt "Estimates of gamma" _col(28) "estimate" _col(39) "std. err."
        di as txt "  the interval"
        _freeiv_fmt `=e(lo)'
        local slo = trim("`s'")
        _freeiv_fmt `=e(hi)'
        di as txt "    bounds" _col(26) as res "[`slo', `=trim("`s'")']"
        _freeiv_row "ols = gamma-tilde" `=e(ols)' `=e(se_gt)' ""
        di as txt "  order 3"
        if (e(at_vertex) == 1) {
            _freeiv_out `=e(vertex)'
            local ex "vertex"
            if ("`out'" != "") {
                local ex "vertex; `out'"
                local anyout 1
            }
            _freeiv_row "qme" `=e(vertex)' `=e(se_vertex)' "`ex'"
        }
        else {
            _freeiv_out `=e(qme)'
            if ("`out'" != "") local anyout 1
            _freeiv_row "qme" `=e(qme)' `=e(se_qme)' "`out'"
        }
        _freeiv_out `=e(hme)'
        if ("`out'" != "") local anyout 1
        _freeiv_row "hme" `=e(hme)' `=e(se_hme)' "`out'"
        di as txt "  order 4"
        local ex = "J " + string(e(J_gmm), "%6.3f") + "  p " + string(e(p_gmm), "%5.3f")
        _freeiv_row "gmm" `=e(g_gmm)' `=cond(e(gmm_bound) == 1, ., e(se_gmm))' "`ex'"
        local ex = "J " + string(e(J_pgmm), "%6.3f") + "  p " + string(e(p_pgmm), "%5.3f")
        _freeiv_row "pgmm" `=e(g_pgmm)' `=e(se_pgmm)' "`ex'"
        di as txt "  other maintained models"
        * the same rule as the single-method display: a solver that did not
        * converge does not get to show a standard error
        if (e(lsz_conv) != 1) local ex "did not converge"
        else {
            _freeiv_out `=e(lsz)'
            local ex "`out'"
            if ("`out'" != "") local anyout 1
        }
        _freeiv_row "lsz" `=e(lsz)' `=cond(e(lsz_conv) != 1, ., e(se_lsz))' "`ex'"
        foreach k in lewbel12 copula rank oster {
            local kk "`k'"
            if ("`k'" == "rank") local kk "g_rank"
            _freeiv_out `=e(`kk')'
            if ("`out'" != "") local anyout 1
            _freeiv_row "`k'" `=e(`kk')' . "`out'"
        }
        if (e(at_vertex) == 1) {
            di as txt "    qme: negative discriminant, no real root -- the vertex"
            di as txt "    3 m12/(4 m03), where the two roots merge"
        }
        if (e(gmm_bound) == 1) {
            di as txt "    gmm: minimum on the boundary, so no standard error;"
            di as txt "    read the region of the J below"
        }
        if (`anyout') {
            di as txt "    an estimate outside the bounds implies a negative variance"
            di as txt "    under scale consistency; -freeivdiag, gamma(#)- says which"
        }
    }
    else if ("`m'" == "bounds") {
        _freeiv_fmt `=e(lo)'
        local slo "`s'"
        _freeiv_fmt `=e(hi)'
        di as txt "Partial identification: gamma in [" as res ///
           "`=trim("`slo'")'" as txt ", " as res "`=trim("`s'")'" as txt "]"
        foreach k in half full {
            if ("`k'" == "half") {
                local v  = e(gt) / 2
                local sv = e(se_lo)
                local lb "gamma-tilde/2"
            }
            else {
                local v  = e(gt)
                local sv = e(se_gt)
                local lb "gamma-tilde = ols"
            }
            _freeiv_fmt `v'
            local sg "`s'"
            _freeiv_fmt `sv'
            if (`sv' < .) {
                di as txt "    `lb'" _col(24) as res "`sg'" as txt "  s.e. " ///
                   as res "`=trim("`s'")'" as txt "   [" ///
                   as res %9.6f `v' - `crit' * `sv' as txt ", " ///
                   as res %9.6f `v' + `crit' * `sv' as txt "]"
            }
            else di as txt "    `lb'" _col(24) as res "`sg'"
        }
    }
    else {
        _freeiv_fmt `=e(gamma)'
        local sg "`s'"
        _freeiv_fmt `=e(se)'
        if (e(se) < .) {
            local cl = e(gamma) - `crit' * e(se)
            local cu = e(gamma) + `crit' * e(se)
            di as txt "    gamma (" as res "`e(endog)'" as txt ")" _col(24) ///
               as res "`sg'" as txt "  s.e. " as res "`=trim("`s'")'" ///
               as txt "   [" as res %9.6f `cl' as txt ", " as res %9.6f `cu' as txt "]"
            local tv = e(gamma) / e(se)
            if ("`st'" == "t") local pv = 2 * ttail(e(df_r), abs(`tv'))
            else               local pv = 2 * normal(-abs(`tv'))
            di as txt "        `st' = " as res %7.3f `tv' ///
               as txt "    P>|`st'| = " as res %6.4f `pv'
        }
        else {
            di as txt "    gamma (" as res "`e(endog)'" as txt ")" _col(24) as res "`sg'"
            if (e(gamma) >= .) {
                if ("`m'" == "qme") {
                    di as res "note: no value -- m03, the third moment of the first-stage"
                    di as res "      residual, is numerically zero, so the quadratic has no"
                    di as res "      leading term"
                }
                else if ("`m'" == "hme") {
                    di as res "note: no value -- m30/m03 does not have the sign of"
                    di as res "      gamma-tilde, which the model with V1 and V2 symmetric"
                    di as res "      cannot produce (or m03 is numerically zero)"
                }
                else {
                    di as res "note: no value for method(`m') on these data"
                }
            }
            else if ("`m'" == "lsz" & e(lsz_conv) != 1) {
                di as res "note: the LSZ solver DID NOT CONVERGE, so no standard error"
                di as res "      is shown and the point above should not be read as an"
                di as res "      estimate.  The objective is non-convex and needs"
                di as res "      multi-start; -trigmm- with several starts is the"
                di as res "      reference implementation for this route."
            }
            else if ("`m'" == "gmm" & e(gmm_bound) == 1) {
                * not a missing standard error but a suppressed one: at a
                * boundary the delta method has nothing to expand around
                di as res "note: no standard error is REPORTED here, not none exists:"
                di as res "      the minimum is on the boundary of the parameter space,"
                di as res "      where the delta method has nothing to expand around and"
                di as res "      the chi2(1) law for J does not hold either.  Read the"
                di as res "      region below the J instead: it rests on no standard"
                di as res "      error, and its share says how flat the criterion is."
            }
            else {
                di as res "note: no analytic standard error for method(`m'): this"
                di as res "      model is reported for comparison, not re-derived; use"
                di as res "      the -bootstrap- prefix"
            }
        }
        if ("`e(qme_flag)'" == "vertex") {
            di as res "note: negative discriminant -- the value shown is the vertex"
            di as res "      3*m12/(4*m03), where the two roots merge; it coincides with"
            di as res "      gamma when B = 2A, the very configuration where D vanishes"
        }
        _freeiv_out `=e(gamma)'
        if ("`out'" != "") {
            di as res "note: the estimate lies OUTSIDE the identification bounds:"
            di as res "      under scale consistency it implies a negative variance"
            di as res "      (see the nuisances below, or -freeivdiag-)"
        }
    }

    cap noisily _freeiv_ident
    _freeiv_vcefoot
end


program define _freeiv_ident
    di as txt "{hline 72}"
    di as txt "Identification"
    _freeiv_fmt `=e(gt)'
    di as txt "    OLS slope, gamma-tilde = gamma (1 + c)" _col(46) as res "`s'"
    _freeiv_fmt `=e(lo)'
    local slo "`s'"
    _freeiv_fmt `=e(hi)'
    di as txt "    bounds, c in [0, 1]" _col(46) as res ///
       "[`=trim("`slo'")', `=trim("`s'")']"
    _freeiv_fmt `=e(skew2)'
    di as txt "    skewness of the first-stage residual" _col(46) as res "`s'"
    _freeiv_fmt `=e(disc)'
    local sd "`s'"
    _freeiv_fmt `=e(disc_se)'
    di as txt "    discriminant D = 9m12^2 - 8m03m21" _col(46) as res "`sd'" ///
       as txt "  (s.e. " as res "`=trim("`s'")'" as txt ")"
    _freeiv_fmt `=e(disc_z)'
    di as txt "        D = gamma^2 (2A - B)^2 : z against 0" _col(46) as res "`s'"
    * the model cannot produce a negative D: far below zero is a refutation,
    * not a weak signal
    if (e(disc_z) <= -2) {
        di as res "note: D is NEGATIVE beyond its sampling noise.  Under the model"
        di as res "      D = gamma^2 (2A - B)^2 cannot be below zero, so these data"
        di as res "      reject the linear one-factor model with scale consistency,"
        di as res "      and the vertex below is not an estimate."
    }
    if (e(disc) >= 0 & e(disc) < .) {
        _freeiv_fmt `=e(root1)'
        local s1 "`s'"
        _freeiv_fmt `=e(root2)'
        di as txt "    roots of the quadratic" _col(46) as res ///
           "`=trim("`s1'")' and `=trim("`s'")'"
        di as txt "        of which inside the bounds" _col(46) as res %10.0f e(nroots)
        if (e(nroots) == 0) {
            di as res "note: NEITHER root lies in [gamma-tilde/2, gamma-tilde]."
            di as res "      That interval is exactly the region where the implied"
            di as res "      variances are non-negative, so the retained value is"
            di as res "      not compatible with the model under scale consistency."
            di as res "      Read the J below, and freeivmenu, before using it."
        }
    }
    else {
        _freeiv_fmt `=e(vertex)'
        di as txt "    no real root; vertex" _col(46) as res "`s'"
    }
    _freeiv_fmt `=e(rstar)'
    di as txt "    R* = m12^2/(m03 m21)" _col(46) as res "`s'"
    di as txt "        its floor is 8/9 when m03 m21 > 0"

    if (e(gamma) < . & e(gamma) != 0) {
        * The nuisances the RETAINED gamma implies, recomputed from it: the
        * engine solves them at the qme, which is the retained value only
        * under method(qme).  Given gamma, the second and third moments give
        * them in closed form.
        tempname MM gr th s2 s1 cs aa bb
        matrix `MM' = e(moments)
        * by NAME, not by position: the layout of e(moments) is not
        * something this display should depend on
        local c02 = colnumb(`MM', "m02c")
        local c11 = colnumb(`MM', "m11c")
        local c20 = colnumb(`MM', "m20c")
        local c03 = colnumb(`MM', "m03")
        local c12 = colnumb(`MM', "m12")
        if (`c02' < . & `c11' < . & `c20' < . & `c03' < . & `c12' < .) {
            * a value within rounding of zero is zero: at an end of the
            * bounds theta (at gamma-tilde, the ols route) or sigma2_V2 (at
            * gamma-tilde/2) IS zero, and must not read as negative
            local tol = 1e-9 * max(abs(`MM'[1,`c02']), abs(`MM'[1,`c20']), 1)
            scalar `gr' = e(gamma)
            scalar `th' = `MM'[1,`c11'] / `gr' - `MM'[1,`c02']
            if (abs(`th') < `tol') scalar `th' = 0
            scalar `s2' = `MM'[1,`c02'] - `th'
            if (abs(`s2') < `tol') scalar `s2' = 0
            scalar `s1' = `MM'[1,`c20'] - `gr'^2 * `MM'[1,`c02'] ///
                        - 3 * `gr'^2 * `th'
            if (abs(`s1') < `tol') scalar `s1' = 0
            scalar `cs' = `th' / `MM'[1,`c02']
            scalar `aa' = `MM'[1,`c12'] / `gr' - `MM'[1,`c03']
            scalar `bb' = 2 * `MM'[1,`c03'] - `MM'[1,`c12'] / `gr'
            di as txt "{hline 72}"
            di as txt "Nuisances implied by the retained value"
            _freeiv_fmt `=scalar(`th')'
            di as txt "    theta = alpha2^2 Var(U)" _col(46) as res "`s'"
            _freeiv_fmt `=scalar(`s2')'
            di as txt "    sigma2_V2" _col(46) as res "`s'"
            _freeiv_fmt `=scalar(`s1')'
            di as txt "    sigma2_V1" _col(46) as res "`s'"
            _freeiv_fmt `=scalar(`cs')'
            di as txt "    c = theta/(theta + sigma2_V2)" _col(46) as res "`s'" ///
               as txt "  the share the"
            di as txt "        bounds leave free: gamma = gamma-tilde/(1 + c)"
            _freeiv_fmt `=scalar(`aa')'
            di as txt "    E[(alpha2 U)^3], the confounder's" _col(46) as res "`s'"
            _freeiv_fmt `=scalar(`bb')'
            di as txt "    E[V2^3]" _col(46) as res "`s'" ///
               as txt "  (hme takes it 0)"
            * theta, sV2 and sV1 are variances up to a positive factor.  A
            * negative one is not a small number to be read as approximately
            * zero: it says the retained gamma is outside the region the model
            * allows.
            if (`th' < 0 | `s2' < 0 | `s1' < 0) {
                di as res "note: an implied variance is NEGATIVE, which no model can"
                di as res "      produce.  The retained value lies outside the region"
                di as res "      where scale consistency is feasible; the numbers just"
                di as res "      above are arithmetic, not estimates."
            }
        }
    }

    if (e(J_gmm) < . | e(J_pgmm) < .) {
        di as txt "{hline 72}"
        di as txt "Over-identification at order four: nine moments, eight parameters"
        * the joint GMM is computed only under method(gmm) and method(all)
        if (e(J_gmm) < .) {
            di as txt "    joint GMM, method(gmm)"
            _freeiv_fmt `=e(g_gmm)'
            di as txt "        gamma" _col(46) as res "`s'"
            di as txt "        J, 1 df" _col(46) as res %10.4f e(J_gmm) ///
               as txt "   P>chi2 " as res %6.4f e(p_gmm)
            * Guard on the region being there at all -- in Stata a missing
            * value is LARGER than any number, so an unguarded -> 0.95- test
            * fires on a missing.
            if (e(ar_frac) < .) {
                _freeiv_fmt `=e(ar_lo)'
                local arl "`s'"
                _freeiv_fmt `=e(ar_hi)'
                di as txt "        J within 3.84 of its minimum on [" as res ///
                   "`=trim("`arl'")'" as txt ", " as res "`=trim("`s'")'" as txt "]"
                di as txt "        that is " as res %5.1f 100*e(ar_frac) ///
                   as txt "% of [gamma-tilde/2, gamma-tilde]"
            }
            * The region profiles the J over gamma instead of inverting a Wald
            * statistic around the optimum, so it rests on no standard error and
            * shows how flat the criterion is (the statistic that would keep its
            * law under weak identification is the S of Stock and Wright 2000,
            * J(gamma) itself; this is the difference J(gamma) - min J).  When it
            * fills the whole interval, the moments of orders 3 and 4 have added
            * nothing to the bounds.
            if (e(ar_frac) > 0.95 & e(ar_frac) < .) {
                di as res "    note: that region is the WHOLE identified interval, so the"
                di as res "          moments of orders 3 and 4 add nothing here to the"
                di as res "          assumption-free bounds.  The point estimate is the"
                di as res "          argmin of a flat criterion; report the interval."
            }
            if (e(gmm_bound) == 1) {
                di as res "    note: the minimum is ON THE BOUNDARY -- gamma at an end of"
                di as res "          the interval, or theta at its floor.  Neither the"
                di as res "          standard error nor the chi2(1) law for J is valid"
                di as res "          there, so no standard error is printed."
            }
            if (e(gmm_weak) == 1) {
                di as res "    note: theta < 0.05 at the minimum: the implied confounder"
                di as res "          has almost no variance, so kurt_U is not defined and"
                di as res "          there is nothing for the higher moments to bind on."
            }
        }
        di as txt "    profiled GMM, method(pgmm): orders 2 and 3 fitted exactly"
        _freeiv_fmt `=e(g_pgmm)'
        di as txt "        gamma" _col(46) as res "`s'"
        di as txt "        J, 1 df" _col(46) as res %10.4f e(J_pgmm) ///
           as txt "   P>chi2 " as res %6.4f e(p_pgmm)
        if (e(J_gmm) < .) {
            di as txt "        a different estimator, not the same one solved"
            di as txt "        differently: a wide gap from the joint GMM signals a"
            di as txt "        flat criterion"
        }
        else {
            di as txt "        the joint GMM, and the region where its J stays within"
            di as txt "        3.84 of its minimum: method(gmm) or method(all)"
        }
        di as txt "    B kurt_U - A kurt_V2" _col(46) as res %10.4f e(idfac) ///
           as txt "   z " as res %6.2f e(z_idfac)
        di as txt "    The J tests alpha1 = gamma alpha2.  The Jacobian of the"
        di as txt "    model with alpha1 FREE has determinant -(gamma - tau)^5"
        di as txt "    times the factor above, so the restriction is testable"
        di as txt "    everywhere except where that factor vanishes -- and a"
        di as txt "    normal V2 sits exactly there, since it makes both B and"
        di as txt "    kurt_V2 zero."
        * the verdict reads the joint J when it was computed, the profiled one
        * otherwise; a joint minimum on the boundary has no chi2(1) law
        if (e(J_gmm) < .) {
            local pJ  = e(p_gmm)
            local okJ = (e(gmm_bound) != 1)
        }
        else {
            local pJ  = e(p_pgmm)
            local okJ = (e(p_pgmm) < .)
        }
        if (`okJ') {
            if (`pJ' < 0.05) {
                di as txt "    The J rejects, so the rejection stands on its own and the"
                di as txt "    factor need not be read: it is computed at the restricted"
                di as txt "    estimates, which are not consistent under the alternative."
            }
            else if (abs(e(z_idfac)) < 2) {
                di as res "    The J does not reject AND the factor is not distinguishable"
                di as res "    from zero, so this non-rejection carries no information"
                di as res "    about scale consistency: the design is near the surface"
                di as res "    where the restriction cannot be tested at all."
            }
            else {
                di as txt "    The J does not reject and the factor is clearly non-zero,"
                di as txt "    so the non-rejection is informative."
            }
        }
        di as txt "    The factor's magnitude is NOT a calibrated measure of power;"
        di as txt "    only its vanishing, under the null, is meaningful."
    }
    di as txt "{hline 72}"
    di as txt "s.e.: delta method on the stacked moments; the estimation of the"
    di as txt "coefficients on X is accounted for.  The QME's own standard error is"
    di as txt "proportional to 1/sqrt(D): it explodes as the discriminant nears zero."
end


* what the variance is, after the identification block of either model
program define _freeiv_vcefoot
    if ("`e(vce)'" == "linearized") {
        di as txt "Variance linearized over the design of svyset -- strata, PSUs and"
        di as txt "fpc of the first stage -- with t on " as res e(df_r) ///
           as txt " design degrees of freedom."
        if (e(fpc_dropped) == 1) {
            di as res "note: a multistage design with an fpc at the first stage: freeiv"
            di as res "      uses the first stage only and drops that fpc, as if the"
            di as res "      PSUs were drawn with replacement, which errs towards a"
            di as res "      larger variance"
        }
        if (e(N_single) > 0 & e(N_single) < .) {
            if ("`e(singleunit)'" == "certainty") {
                di as txt "note: " as res e(N_single) as txt ///
                   " stratum(a) with a single PSU, treated as certainty units"
            }
            else {
                di as res "note: missing standard errors -- " e(N_single) ///
                   " stratum(a) with a single PSU;"
                di as res "      see the singleunit() option of svyset"
            }
        }
    }
    else if ("`e(vce)'" == "robust") {
        di as txt "Variance in sandwich form for the sampling weights, every"
        di as txt "observation its own primary unit."
    }
end


program define _freeiv_pdisplay
    syntax [, noHEADer Level(string)]
    if ("`e(cmd)'" != "freeiv" | "`e(model)'" != "B") exit
    _freeiv_lev `level'

    * under a prefix the prefix owns the coefficient table
    local pref "`e(prefix)'"
    if ("`pref'" != "" | e(N_reps) < .) {
        cap noisily ereturn display, level(`lev')
        _freeiv_bsnote
        cap noisily _freeiv_pident
        exit
    }
    if (e(df_r) < .) local crit = invttail(e(df_r), (100 - `lev') / 200)
    else             local crit = invnormal(1 - (100 - `lev') / 200)

    di
    if ("`header'" == "") {
        di as txt "Instrument-free estimation, two indicators" _col(44) ///
           "Number of obs    = " as res %9.0fc e(N)
        if ("`e(vce)'" == "linearized") {
            di as txt _col(44) "Number of strata = " as res %9.0fc e(N_strata)
            di as txt _col(44) "Number of PSUs   = " as res %9.0fc e(N_psu)
            di as txt _col(44) "Design df        = " as res %9.0fc e(df_r)
        }
        di as txt "model: " as res "`e(depvar)'" as txt " on " ///
           as res "`e(endog2)' `e(endog3)'" ///
           as txt cond("`e(exog)'" != "", ", controls " + "`e(exog)'", "")
        di as txt "method: " as res "proxy" as txt ///
           "  (Theorem 1, one latent confounder behind both)"
    }
    di as txt "{hline 72}"

    if (e(guard) != 0) {
        local g = e(guard)
        di as res "no estimate: guard " as res %1.0f `g' as res " of Proposition 1 fired"
        if (`g' == 1) {
            di as txt "    E[eps2^2 eps3] and E[eps2 eps3^2] do not share a sign, or the"
            di as txt "    second is numerically zero: the third moment of the confounder"
            di as txt "    is too weak to orient the loadings"
        }
        if (`g' == 2) {
            di as txt "    E[eps2 eps3] and the ratio of the two third moments disagree"
            di as txt "    in sign, so a2 a3 would be negative: the two indicators are"
            di as txt "    not loading on one common factor with the same sign"
        }
        if (`g' == 3) {
            di as txt "    an implied idiosyncratic variance is negative: the common"
            di as txt "    factor would have to explain more than the whole variance of"
            di as txt "    an indicator"
        }
        if (`g' == 4) di as txt "    the 3x3 system of Theorem 1 is singular"
        di as txt "{hline 72}"
        exit
    }

    di as txt "Structural coefficients"
    _fivp_line g2 `=e(g2)' `=e(se_g2)' "`e(endog2)'" `crit'
    _fivp_line g3 `=e(g3)' `=e(se_g3)' "`e(endog3)'" `crit'
    _fivp_line a1 `=e(a1)' `=e(se_a1)' "U in the outcome" `crit'
    di as txt "        a1 is free here: the two-indicator route needs no"
    di as txt "        scale-consistency restriction to identify it"
    cap noisily _freeiv_pident
    _freeiv_vcefoot
end


program define _fivp_line
    args nm est se lab crit
    _freeiv_fmt `est'
    local sg "`s'"
    _freeiv_fmt `se'
    local ss "`s'"
    * the estimate right-aligned in a fixed width: a minus sign must not push
    * the rest of the line past 79 columns
    if (`se' < .) {
        di as txt "    `nm' (" as res "`lab'" as txt ")" _col(32) ///
           as res %10.6f `est' as txt "  s.e. " as res "`=trim("`ss'")'" ///
           as txt "   [" as res %8.5f `est' - `crit' * `se' as txt ", " ///
           as res %8.5f `est' + `crit' * `se' as txt "]"
    }
    else di as txt "    `nm' (" as res "`lab'" as txt ")" _col(32) as res %10.6f `est'
end


program define _freeiv_pident
    * the tests below at 5%: t on the design df under vce(svy), else normal
    if (e(df_r) < .) {
        local c95 = invttail(e(df_r), 0.025)
        local st "t"
    }
    else {
        local c95 = invnormal(0.975)
        local st "z"
    }
    di as txt "{hline 72}"
    di as txt "The confounder, recovered from the two indicators"
    _freeiv_fmt `=e(a2)'
    local s2 "`s'"
    _freeiv_fmt `=e(a3)'
    di as txt "    loadings a2, a3" _col(40) as res "`=trim("`s2'")'   `=trim("`s'")'"
    _freeiv_fmt `=e(mu3)'
    di as txt "    E[U^3] (mu3)" _col(40) as res "`s'"
    _freeiv_fmt `=e(s2)'
    local s2 "`s'"
    _freeiv_fmt `=e(s3)'
    di as txt "    sigma2_V2, sigma2_V3" _col(40) as res "`=trim("`s2'")'   `=trim("`s'")'"
    _freeiv_fmt `=e(sc)'
    di as txt "    g2 a2 + g3 a3" _col(40) as res "`s'" ///
       as txt "   (what model A would call a1)"
    di as txt "    condition number of the 3x3 system" _col(40) as res ///
       %10.4f e(cnum) cond(e(cnum) > 100, "   ill conditioned", "")

    di as txt "{hline 72}"
    di as txt "One-factor check: three estimates of a2/a3 that must agree"
    _freeiv_fmt `=e(R1)'
    di as txt "    R1  from eps2, eps3 alone" _col(40) as res "`s'"
    _freeiv_fmt `=e(R2)'
    di as txt "    R2  from xi eps^2" _col(40) as res "`s'"
    _freeiv_fmt `=e(R3)'
    di as txt "    R3  from xi^2 eps" _col(40) as res "`s'"
    * the ratio is read only when both third-order cross-moments are
    * measured (z >= 2): R2 and R3 divide by them and are noise otherwise,
    * which is the same gate as the menu applies
    local weak3 = (abs(e(z_m223)) < 2 | abs(e(z_m233)) < 2 | e(z_m223) >= . | e(z_m233) >= .)
    di as txt "    |R3/R1 - 1|" _col(40) as res %10.4f e(disc_R) ///
       cond(`weak3', "   not informative", ///
       cond(e(disc_R) < 0.15, "   consistent", "   a second factor is likely"))
    di as txt "    z of eps2^2 eps3, eps2 eps3^2" _col(40) as res ///
       %10.2f e(z_m223) "  " %8.2f e(z_m233) ///
       as txt cond(`weak3', "   both must reach 2", "")
    di as txt "    With one factor all three equal a2/a3.  With two, R1 becomes"
    di as txt "    (a2^2 a3 E[U^3] + b2^2 b3 E[W^3]) / (a2 a3^2 E[U^3] +"
    di as txt "    b2 b3^2 E[W^3]), which is a2/a3 only if the second factor is"
    di as txt "    symmetric or loads proportionally, and R3 weights the two"
    di as txt "    factors differently again.  A gap is therefore a second"
    di as txt "    factor, by derivation, not a sampling artefact."

    di as txt "    R1 - R3" _col(40) as res %10.6f e(of_d) ///
       as txt "  s.e. " as res %8.6f e(se_of) as txt "  `st' " as res %7.3f e(z_of)
    di as txt "    R1 equals a2/a3 under one factor with no side condition;"
    di as txt "    R3 needs symmetric V2 and V3 as well, so a rejection here is"
    di as txt "    against one factor AND that symmetry, jointly."

    if (e(q_J) < .) {
        di as txt "{hline 72}"
        di as txt "Over-identified GMM, 16 moments for 12 parameters"
        di as txt "    J, 4 df" _col(40) as res %10.4f e(q_J) ///
           as txt "   P>chi2 " as res %6.4f e(q_pJ)
        di as txt "    g2, g3, a1 from the GMM" _col(40) as res %10.6f e(q_g2) ///
           "  " %10.6f e(q_g3) "  " %10.6f e(q_a1)
        di as txt "    E[U^3], E[V2^3], E[V3^3]" _col(40) as res %10.6f e(q_mu3) ///
           "  " %10.6f e(q_k2) "  " %10.6f e(q_k3)
        di as txt "    The closed form uses eight of these sixteen moments and"
        di as txt "    fits them exactly; the J asks whether the eight it leaves"
        di as txt "    out agree, so it tests the one-factor linear structure"
        di as txt "    itself.  k2 and k3 are E[V2^3] and E[V3^3], the symmetry"
        di as txt "    that R3 -- and only R3 -- needs."
    }

    di as txt "{hline 72}"
    di as txt "Scale consistency, which model A cannot test"
    di as txt "    a1 (free, identified here)" _col(40) as res %10.6f e(a1)
    di as txt "    g2 a2 + g3 a3" _col(40) as res %10.6f e(sc)
    di as txt "    difference" _col(40) as res %10.6f e(sc_d) ///
       as txt "  s.e. " as res %8.6f e(se_sc) as txt "  `st' " as res %7.3f e(z_sc)
    di as txt "    Model A imposes alpha1 = gamma1 alpha2, which with two"
    di as txt "    endogenous regressors reads a1 = g2 a2 + g3 a3.  Its own nine"
    di as txt "    moments pin the ratio of the two loadings only up to that"
    di as txt "    normalisation; the second indicator frees a1 and makes the"
    di as txt "    restriction testable.  No fourth moment is needed."
    if (abs(e(z_sc)) > `c95' & e(z_sc) < .) {
        di as res "    The restriction is rejected on these data, so the"
        di as res "    single-indicator route would not be valid here."
    }

    di as txt "{hline 72}"
    di as txt "What `e(endog3)' used as an instrument for `e(endog2)' would return"
    di as txt "    iv estimate" _col(40) as res %10.6f e(ivgap)
    di as txt "    An indicator of the confounder is not an instrument: it is"
    di as txt "    correlated with the very thing it is meant to purge.  The gap"
    di as txt "    against g2 above is the bias that route would carry."
    di as txt "    correlation of the two indicators, t" _col(40) as res %10.4f e(t_rho)
    di as txt "{hline 72}"
    di as txt "s.e.: delta method, numeric Jacobian of Theorem 1 on the eight"
    di as txt "moments, with the estimation of the coefficients on X accounted for."
    di as txt "Theorem 1 involves square roots, so the linearisation is only good"
    di as txt "locally: in the reference design it tracked a 600-replication"
    di as txt "bootstrap to within about ten percent, in either direction.  Prefer"
    di as txt "the -bootstrap- prefix when the inference matters."
end
