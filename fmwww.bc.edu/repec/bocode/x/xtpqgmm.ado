*! xtpqgmm 1.0.0  14oct2026
*! Smoothed profiled GMM for panel data quantile regression with
*! individual fixed-effects and endogenous regressors.
*!
*! Implements Galvao, A. F., U. Hounyo and J. Lin (2026), "GMM for Panel Data
*! Quantile Regression", arXiv:2610.12824.  The paper's own labels: SP-GMM for
*! the two-step estimator (eq. 11), SP-MM for the exactly-identified
*! method-of-moments version (eq. 9) used as the starting value.
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*!         github.com/merwanroudane
*!
*! Requires Stata 17.0 or later.  Numeric core in Mata:
*!   xtpqgmm_proto.mata  kernels, bandwidth, scalar profile solver
*!   xtpqgmm_panel.mata  panel profiling, moments, Jacobian, HAC, GMM, Sigma

program xtpqgmm, eclass byable(recall) sortpreserve
    version 17.0

    if replay() {
        if `"`e(cmd)'"' != "xtpqgmm" {
            error 301
        }
        syntax [, Level(cilevel)]
        _xtpqgmm_display , level(`level')
        exit
    }

    local cmdline `"xtpqgmm `0'"'

    * ---------------------------------------------------------------- parse
    * depvar [exog] (endog = excluded)  -- same shape as ivregress and sivqr
    _iv_parse `0'
    local lhs   `s(lhs)'
    local endog `s(endog)'
    local exog  `s(exog)'
    local excl  `s(inst)'
    local 0     `s(zero)'

    syntax [if] [in] [fweight aweight pweight iweight] ,  ///
        Quantile(numlist >0 <100 sort)                    ///
        [ ID(varname)                                     ///
          Bandwidth(real -1)                              ///
          LAGs(integer -1)                                ///
          MM ONEstep                                      ///
          NONMfallback SMOOTHWeight                       ///
          Level(cilevel)                                  ///
          MINT(integer 5) WARNT(integer 20)               ///
          ITERlog noWARNings ]

    if ("`weight'" != "") {
        di as error "weights are not supported"
        di as error "{p 4 4 2}The asymptotic theory and the bandwidth rule" ///
            " are stated for unweighted panels; see" ///
            " {help xtpqgmm_methods##limits:Limitations}.{p_end}"
        exit 101
    }
    if ("`mm'" != "" & "`onestep'" != "") {
        di as error "only one of {bf:mm} and {bf:onestep} may be specified"
        exit 198
    }
    if ("`endog'" == "") {
        di as error "no endogenous regressors specified"
        di as error "{p 4 4 2}Write the model as {bf:xtpqgmm} {it:depvar}" ///
            " [{it:exogvars}] {bf:(}{it:endog} {bf:=}" ///
            " {it:instruments}{bf:)}.  With no endogenous regressor there" ///
            " is nothing to instrument: use {help mmqreg} or" ///
            " {help qregfe}.{p_end}"
        exit 198
    }

    local mode 3
    local modetxt "Two-step SP-GMM (eq. 11), Bartlett HAC weighting"
    if ("`onestep'" != "") {
        local mode 2
        local modetxt "One-step SP-GMM (eq. 10), identity weighting"
    }
    if ("`mm'" != "") {
        local mode 1
        local modetxt "SP-MM, exactly identified (eq. 9)"
    }
    local nmfall  = ("`nonmfallback'" == "")
    local smoothw = ("`smoothweight'" != "")

    * ------------------------------------------------------- panel variable
    local tvar ""
    capture xtset
    if !_rc {
        local xtid   `r(panelvar)'
        local tvar   `r(timevar)'
    }
    if ("`id'" == "") {
        local id `xtid'
    }
    if ("`id'" == "") {
        di as error "no panel variable"
        di as error "{p 4 4 2}Either {bf:xtset} the data or specify" ///
            " {bf:id(}{it:panelvar}{bf:)}.{p_end}"
        exit 459
    }

    * ---------------------------------------------- time-series / factor vars
    * The paper's leading case is a dynamic panel, so L.y and friends must
    * work.  fvrevar makes temporaries where needed; the ORIGINAL names are
    * kept for the output table.
    local xnames `endog' `exog'
    local znames `exog' `excl'
    fvrevar `lhs'
    local yv `r(varlist)'
    fvrevar `xnames'
    local xv `r(varlist)'
    fvrevar `znames'
    local zv `r(varlist)'

    * ---------------------------------------------------------------- sample
    marksample touse
    markout `touse' `yv' `xv' `zv' `id'
    quietly count if `touse'
    if r(N) == 0 {
        error 2000
    }

    local d  : word count `xnames'
    local dz : word count `znames'
    if (`dz' < `d') {
        di as error "under-identified: `dz' instrument(s) for `d' parameter(s)"
        di as error "{p 4 4 2}Equation (3) needs at least as many" ///
            " instruments as regressors.  Add excluded instruments --" ///
            " in a dynamic model, further lags.{p_end}"
        exit 481
    }

    * -------------------------------------------- panel shape and gap checks
    tempvar nid ng
    quietly egen long `nid' = group(`id') if `touse'
    quietly bysort `touse' `nid' : gen long `ng' = _N if `touse'
    quietly summarize `ng' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    quietly summarize `nid' if `touse', meanonly
    local n = r(max)
    quietly count if `touse'
    local NT   = r(N)
    local Tbar = `NT'/`n'

    if (`Tmin' < `mint') {
        di as error "a unit has only `Tmin' usable observation(s); minimum is `mint'"
        di as error "{p 4 4 2}Graham, Hahn and Powell (2009) show the common" ///
            " slope is not identified at T = 2, and the profiled quantile" ///
            " restriction (8) needs enough within-unit variation to have a" ///
            " root.  Drop short units, or lower {bf:mint()} knowing why." ///
            "{p_end}"
        exit 2001
    }

    * contiguity: the Bartlett sums of Section 5 are undefined across a gap
    if ("`tvar'" != "") {
        tempvar gap
        quietly bysort `touse' `nid' (`tvar') : ///
            gen byte `gap' = (`tvar' != `tvar'[_n-1] + 1) & _n > 1 if `touse'
        quietly count if `gap' == 1 & `touse'
        if r(N) > 0 {
            local ngap = r(N)
            di as error "the panel has internal gaps in `tvar' (`ngap' break(s))"
            di as error "{p 4 4 2}The HAC covariance of Section 5 sums" ///
                " products at t and t+j within a unit, which is undefined" ///
                " across a gap.  Fill or drop the gaps, or restrict to a" ///
                " contiguous span.  Nothing is interpolated for you.{p_end}"
            exit 459
        }
    }

    * --------------------------------------------------------------- warnings
    if ("`warnings'" == "") {
        if (`Tmin' < `warnt') {
            di as text "{p 0 2 2}Note: the shortest unit has T = `Tmin'." ///
                " In the paper's own simulations coverage was 0.896 at" ///
                " (n,T) = (20,20), so inference may be liberal here.{p_end}"
        }
        if (`n' >= `Tbar') {
            local nTr = string(sqrt(`n'/`Tbar'), "%5.3f")
            di as text "{p 0 2 2}Note: n = `n' is not small relative to" ///
                " T-bar = " %4.1f `Tbar' ".  Theorem 4.1 assumes n/T -> 0;" ///
                " the incidental-parameter bias is O(sqrt(n/T)) = `nTr'," ///
                " and it is {it:not} corrected.  See" ///
                " {help xtpqgmm_methods##nT:the methods page}.{p_end}"
        }
    }

    * ------------------------------------------------------------------ fit
    * Sort ONCE, here, for every quantile.  The Mata core calls panelsetup(),
    * which requires the rows of a unit to be contiguous, and the Bartlett
    * sums of Section 5 pair t with t+j, which requires them to be in TIME
    * order inside the unit.  Stata's sort leaves ties in an indeterminate
    * order, so `sort `nid'' alone would scramble time within a unit -- a
    * silent HAC bug.  `ord' is the original record order and breaks every
    * remaining tie, so the sort is total and reproducible.  `sortpreserve'
    * on the program line puts the user's own sort back afterwards.
    tempvar ord
    quietly generate long `ord' = _n
    if ("`tvar'" != "") {
        sort `nid' `tvar' `ord'
    }
    else {
        sort `nid' `ord'
    }

    local nq : word count `quantile'
    local taulist ""
    local cnames   ""
    local ceqs     ""
    local k 0

    foreach q of local quantile {
        * accept either 25 or 0.25, as sivqr and qreg both do
        local tau = `q'
        if (`tau' >= 1) {
            local tau = `tau'/100
        }
        local qtag = subinstr(string(100*`tau'), ".", "_", .)
        local ++k

        * The 12th argument is the sample-selection variable.  st_data() does
        * the subsetting, so there is no preserve / keep if touse / restore
        * round trip -- that copied the whole dataset once per quantile.
        if ("`iterlog'" != "") {
            capture noisily mata: xtpq_panelfit("`yv'", "`xv'", "`zv'",  ///
                "`nid'", `tau', 4, `bandwidth', `lags', `mode',         ///
                `nmfall', `smoothw', "`touse'")
        }
        else {
            capture quietly mata: xtpq_panelfit("`yv'", "`xv'", "`zv'",  ///
                "`nid'", `tau', 4, `bandwidth', `lags', `mode',         ///
                `nmfall', `smoothw', "`touse'")
        }
        local frc = _rc
        if (`frc' == 0) {
            matrix __xq`k'_b = __pf_b
            matrix __xq`k'_V = __pf_V
            * Hansen's J at this quantile.  Cheap -- one dz x dz inverse of a
            * matrix already computed -- so it is always available rather
            * than something `estat overid' has to refit for.
            capture quietly mata: xtpq_jstat()
            if (_rc == 0) {
                matrix __xq`k'_J = (`tau', scalar(__pf_J), ///
                                    scalar(__pf_Jdf), scalar(__pf_Jp))
            }
            else {
                matrix __xq`k'_J = (`tau', ., `dz'-`d', .)
            }
            foreach sc in h lag lagd n T N d dz mnorm gnorm Q it conv ///
                           nfail nmulti nT maxA {
                scalar __kp_`sc' = scalar(__pf_`sc')
            }
            * alphas: one COLUMN per quantile.  Overwriting here -- which is
            * what a single `matrix __kp_a = __pf_a' did -- silently left
            * e(alpha) holding the LAST quantile's fixed effects with no
            * label saying so, which predict would then have used for every
            * quantile.
            if (`k' == 1) {
                matrix __kp_a = __pf_a
            }
            else {
                matrix __kp_a = __kp_a, __pf_a
            }
            if (`nq' == 1) {
                foreach mt in D Om W m Sig bmm {
                    capture matrix __kp_`mt' = __pf_`mt'
                }
            }
        }
        if (`frc') {
            di as error "estimation failed at quantile `q' (rc = `frc')"
            if ("`iterlog'" == "") {
                di as error "{p 4 4 2}Re-run with {bf:iterlog} to see the" ///
                    " optimiser's own messages.{p_end}"
            }
            capture matrix drop __xq1_b __xq1_V
            exit `frc'
        }

        * names: `matrix colnames' will NOT accept an "eq:name" token, so the
        * names and the equations are built as two parallel lists and applied
        * with colnames/coleq separately.
        local cnames `cnames' `xnames'
        foreach xn of local xnames {
            local ceqs `ceqs' q`qtag'
        }
        local taulist `taulist' `tau'
        if (`nq' > 1) local eqnames `eqnames' q`qtag'
    }

    * ---- the over-identification table, one row per quantile ------------
    tempname Jtab
    matrix `Jtab' = __xq1_J
    forvalues j = 2/`nq' {
        matrix `Jtab' = `Jtab' \ __xq`j'_J
    }
    matrix colnames `Jtab' = tau J df p
    local jrn
    foreach tt of local taulist {
        local jrn `jrn' q`=subinstr(string(100*`tt', "%4.0f"), ".", "_", .)'
    }
    matrix rownames `Jtab' = `jrn'
    matrix colnames __kp_a = `jrn'
    forvalues j = 1/`nq' {
        capture matrix drop __xq`j'_J
    }

    * ---- stack the quantiles.  Stata's matrix operators cannot do this:
    * ---- `A , B' demands identical row names, so a block-diagonal V across
    * ---- equations raises r(507).  Mata assembles it, names go on after.
    tempname ball Vall
    mata: xtpq_stackq(`nq')
    matrix `ball' = __xq_ball
    matrix `Vall' = __xq_Vall
    * ORDER MATTERS.  Set the equations FIRST: with several quantiles the
    * name list is "x x x", and assigning duplicate names to a matrix that
    * has no equations yet is itself a r(507) name conflict.  Equations make
    * them unique, so they go on before the names.
    if (`nq' > 1) {
        matrix coleq `ball' = `ceqs'
        matrix roweq `Vall' = `ceqs'
        matrix coleq `Vall' = `ceqs'
    }
    matrix colnames `ball' = `cnames'
    matrix rownames `Vall' = `cnames'
    matrix colnames `Vall' = `cnames'
    capture matrix drop __xq_ball __xq_Vall
    forvalues j = 1/`nq' {
        capture matrix drop __xq`j'_b __xq`j'_V
    }

    * ---------------------------------------------------------------- post
    ereturn post `ball' `Vall', depname("`lhs'") obs(`NT') esample(`touse')

    ereturn local cmdline   `"`cmdline'"'
    ereturn local title     "Smoothed profiled GMM for panel quantile regression"
    ereturn local estimator "`modetxt'"
    ereturn local idvar     "`id'"
    if ("`tvar'" != "") ereturn local timevar "`tvar'"
    ereturn local instd     "`endog'"
    ereturn local exogr     "`exog'"
    ereturn local insts     "`znames'"
    ereturn local kernel    "fourth-order (Galvao-Hounyo-Lin, Section 6)"
    ereturn local hackernel "Bartlett"
    ereturn local vcetype   "HAC"
    ereturn local quantiles "`taulist'"
    if ("`eqnames'" != "") ereturn local eqnames "`eqnames'"

    ereturn scalar n_q      = `nq'
    if (`nq' == 1) ereturn scalar q = `taulist'
    ereturn scalar korder   = 4
    ereturn scalar N_g      = scalar(__kp_n)
    ereturn scalar T_bar    = scalar(__kp_T)
    ereturn scalar T_min    = `Tmin'
    ereturn scalar T_max    = `Tmax'
    ereturn scalar n_over_T = scalar(__kp_nT)
    ereturn scalar df_m     = `d'
    ereturn scalar n_inst   = `dz'
    ereturn scalar n_over   = `dz' - `d'
    ereturn scalar bwidth   = scalar(__kp_h)
    ereturn scalar haclag   = scalar(__kp_lag)
    ereturn scalar haclagok = scalar(__kp_lagd)
    ereturn scalar mnorm    = scalar(__kp_mnorm)
    ereturn scalar gnorm    = scalar(__kp_gnorm)
    ereturn scalar Qval     = scalar(__kp_Q)
    ereturn scalar ic       = scalar(__kp_it)
    ereturn scalar converged     = scalar(__kp_conv)
    ereturn scalar n_profilefail = scalar(__kp_nfail)
    ereturn scalar n_multiroot   = scalar(__kp_nmulti)
    ereturn scalar maxA     = scalar(__kp_maxA)
    ereturn matrix alpha    = __kp_a
    * ORDER MATTERS: `ereturn matrix' MOVES the matrix, it does not copy it,
    * so `Jtab' ceases to exist the moment it is posted.  Read the scalars
    * out first or the next line is r(111) "__000006 not found".
    local js  = `Jtab'[1,2]
    local jdf = `Jtab'[1,3]
    local jp  = `Jtab'[1,4]
    ereturn matrix jtable   = `Jtab'
    if (`nq' == 1) {
        ereturn scalar jstat    = `js'
        ereturn scalar jstat_df = `jdf'
        ereturn scalar jstat_p  = `jp'
    }
    if (`nq' == 1) {
        capture ereturn matrix D     = __kp_D
        capture ereturn matrix Omega = __kp_Om
        capture ereturn matrix Wmat  = __kp_W
        capture ereturn matrix mvec  = __kp_m
        capture ereturn matrix Sigma = __kp_Sig
        capture ereturn matrix b_mm  = __kp_bmm
    }
    ereturn local properties "b V"
    ereturn local estat_cmd  "xtpqgmm_estat"
    ereturn local predict    "xtpqgmm_p"
    ereturn local cmd        "xtpqgmm"

    capture scalar drop __kp_h __kp_lag __kp_lagd __kp_n __kp_T __kp_N     ///
        __kp_d __kp_dz __kp_mnorm __kp_gnorm __kp_Q __kp_it __kp_conv      ///
        __kp_nfail __kp_nmulti __kp_nT __kp_maxA
    capture matrix drop __kp_D __kp_Om __kp_W __kp_m __kp_Sig __kp_bmm

    _xtpqgmm_display , level(`level')
end


program _xtpqgmm_display
    version 17.0
    syntax [, Level(cilevel)]

    local nq = e(n_q)

    di ""
    di as text "Smoothed profiled GMM, panel quantile regression"           ///
        _col(52) as text "Number of obs"    _col(69) "=" as result %10.0fc e(N)
    di as text "`e(estimator)'"                                            ///
        _col(52) as text "Number of groups" _col(69) "=" as result %10.0fc e(N_g)
    di as text "Kernel: order " as result e(korder) as text ", Bartlett HAC" ///
        _col(52) as text "Obs per group:"
    di as text "Bandwidth    =" as result %10.0g e(bwidth)                  ///
        _col(52) as text "              avg" _col(69) "=" as result %10.1f e(T_bar)
    di as text "HAC lag      =" as result %10.0f e(haclag)                  ///
        _col(52) as text "              min" _col(69) "=" as result %10.0f e(T_min)
    if (`nq' == 1) {
        di as text "Quantile     =" as result %10.0g e(q)                   ///
            _col(52) as text "              max" _col(69) "=" as result %10.0f e(T_max)
    }
    else {
        di as text "Quantiles    = " as result "`e(quantiles)'"             ///
            _col(52) as text "              max" _col(69) "=" as result %10.0f e(T_max)
    }
    di as text "Instruments  =" as result %10.0f e(n_inst)                  ///
        _col(52) as text "Over-id. restr." _col(69) "=" as result %10.0f e(n_over)
    di as text "n / T-bar    =" as result %10.3f e(n_over_T)                ///
        _col(52) as text "||g|| at optimum" _col(69) "=" as result %10.2e e(gnorm)
    di ""

    ereturn display , level(`level')

    di as text "Instrumented:  " as result "`e(instd)'"
    if ("`e(exogr)'" != "") {
        di as text "Exogenous:     " as result "`e(exogr)'"
    }
    di as text "Instruments:   " as result "`e(insts)'"
    di as text "{p 0 15 2}Std. err.:     HAC (Bartlett, lag " as result    ///
        e(haclag) as text "), within unit.  Cross-unit independence is"     ///
        " assumed.{p_end}"

    * ---- diagnostics, printed every run, good news or bad ----------------
    * The Mata core uses a very tight tolerance (1e-12 on ||g||).  Missing it
    * at, say, 4e-10 is not a problem a user should be alarmed about, so the
    * message is graded by the size of ||g|| rather than by the flag alone.
    if (e(converged) != 1) {
        if (e(gnorm) < 1e-6) {
            di as text "{p 0 2 2}Note: the optimiser stopped just short of" ///
                " its tolerance, at ||g|| = " as result %9.2e e(gnorm) ///
                as text ".  That is far smaller than any sampling" ///
                " uncertainty here, so the estimates are usable.{p_end}"
        }
        else {
            di as error "{p 0 2 2}Warning: the GMM criterion did NOT" ///
                " converge: ||g|| = " %9.2e e(gnorm) " at the reported" ///
                " point.  Treat these estimates as provisional; try" ///
                " {bf:iterlog} to see the optimiser, a different" ///
                " {bf:bandwidth()}, or fewer instruments.{p_end}"
        }
    }
    if (e(n_profilefail) > 0) {
        di as error "{p 0 2 2}Warning: the profile equation (8) had no root" ///
            " in " as result e(n_profilefail) as error " unit-evaluation(s);" ///
            " those fell back to the unsmoothed quantile.{p_end}"
    }
    if (e(n_multiroot) > 0) {
        di as text "{p 0 2 2}Note: the profile equation had multiple roots" ///
            " for " as result e(n_multiroot) as text " unit(s) at the" ///
            " solution.  That is a property of the fourth-order kernel, not" ///
            " of your data; the root nearest the unsmoothed quantile was" ///
            " used.  See {help xtpqgmm_methods##roots:Multiple roots}.{p_end}"
    }
    if (e(haclagok) == 0) {
        di as text "{p 0 2 2}Note: the HAC lag does not comfortably satisfy" ///
            " lag^2 log(nT)/(T h^2) -> 0.  Consider a shorter" ///
            " {bf:lags()}.{p_end}"
    }
    if (`nq' > 1) {
        di as text "{p 0 2 2}Note: quantiles are estimated separately and" ///
            " the off-diagonal blocks of e(V) are zero -- the paper" ///
            " supplies no cross-quantile covariance, so tests {it:across}" ///
            " quantiles are not valid.  Monotonicity is not imposed.{p_end}"
    }
end
