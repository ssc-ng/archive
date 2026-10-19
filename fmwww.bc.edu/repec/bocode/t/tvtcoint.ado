*! tvtcoint 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold cointegration in which the threshold is a LINEAR FUNCTION OF
*! OBSERVED COVARIATES: gamma_t = gamma_0 + gamma_1'z_t.
*!
*! Yang, L. (2022) "Time-varying threshold cointegration with an application
*!   to the Fisher hypothesis", Studies in Nonlinear Dynamics & Econometrics
*!   26(2):257-274, doi:10.1515/snde-2018-0101  (Crossref 2026-10-13)
*!
*! Clean-room from the paper. The authors' GAUSS was read and RUN to produce
*! the reference lock (_work/reflock/coint_lock.txt) but no line of it is
*! reproduced here. See validation/tvthresh/tvtcoint_equation_map.md.

program define tvtcoint, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtcoint" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] ,    ///
        THReshvar(varname numeric ts)               ///
        Zvars(varlist numeric ts)                   ///
        [ noCONStant                                ///
          TRIM(real 0.10)                           ///
          TIES(string)                              ///
          GStep(real 0.1)                           ///
          GRID0(numlist)                            ///
          GRID1(numlist)                            ///
          REPS(integer 0)                           ///
          GAUSSian                                  ///
          MAXPoints(integer 20000000)               ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        display as error "The paper states no trimming fraction, but the" ///
            " authors' code imposes"
        display as error "10% -- the default here. It is not cosmetic:" ///
            " without it their own"
        display as error "application finds a 15-observation regime with" ///
            " a lower SSR than the"
        display as error "published estimate."
        exit 198
    }
    if "`ties'" == "" local ties nested
    local ties = lower("`ties'")
    if !inlist("`ties'", "nested", "flat") {
        display as error "{bf:ties()} must be {bf:nested} or {bf:flat}"
        display as error "{bf:nested}, the default, is the authors' own" ///
            " rule and the one that"
        display as error "reproduces the published estimates;" ///
            " {bf:flat} is the literal reading"
        display as error "of the paper's footnote 2. See the help."
        exit 198
    }
    if `gstep' <= 0 {
        display as error "{bf:gstep()} must be positive"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    if `maxpoints' < 100 {
        display as error "{bf:maxpoints()} must be at least 100"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar' `zvars'
    quietly count if `touse'
    local nobs = r(N)

    local nx : word count `xvars'
    local nz : word count `zvars'
    local kk = `nx' + ("`constant'" == "")
    if `nobs' < 3*`kk' + 10 {
        display as error "too few observations (`nobs') for `kk'" ///
            " regressors in each of two regimes"
        exit 2001
    }

    * the threshold variable must not be one of the cointegrating
    * regressors: q_t is stationary by Assumption 1 and x_t is I(1)
    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' cannot be both a cointegrating" ///
                " regressor and the"
            display as error "threshold variable: Assumption 1 makes q_t" ///
                " stationary and"
            display as error "Assumption 5 makes x_t I(1)."
            exit 198
        }
    }

    * a large z vector makes the grid a cartesian product and explodes
    if `nz' > 2 {
        display as error "{bf:zvars()} holds `nz' variables, so the" ///
            " gamma_1 grid is a `nz'-fold"
        display as error "cartesian product. The paper's application and" ///
            " all of its simulations"
        display as error "use a SINGLE z. Two is already expensive;" ///
            " three is not a search."
        exit 198
    }

    local qvar "`threshvar'"
    local noconstant "`constant'"
    _tvt_drop

    if `reps' > 0 {
        display as text "running `reps' bootstrap replications; each one" ///
            " re-runs the whole"
        display as text "two-dimensional search twice -- see the help."
    }

    mata: tvt_coint()

    tempname G0 SSR SSR0 SSRC GC N1 N2 NT NF NC NG0 NG1 F1 F2 RHO NOK MINN
    scalar `G0'   = __tvt_ci_g0
    scalar `SSR'  = __tvt_ci_ssr
    scalar `SSR0' = __tvt_ci_ssr0
    scalar `SSRC' = __tvt_ci_ssrc
    scalar `GC'   = __tvt_ci_gc
    scalar `N1'   = __tvt_ci_n1
    scalar `N2'   = __tvt_ci_n2
    scalar `NT'   = __tvt_ci_nties
    scalar `NF'   = __tvt_ci_nfeas
    scalar `NC'   = __tvt_ci_ncand
    scalar `NG0'  = __tvt_ci_ng0
    scalar `NG1'  = __tvt_ci_ng1
    scalar `F1'   = __tvt_ci_f1
    scalar `F2'   = __tvt_ci_f2
    scalar `RHO'  = __tvt_ci_rho
    scalar `NOK'  = __tvt_ci_nok
    scalar `MINN' = __tvt_ci_minn
    tempname SSRG
    scalar `SSRG' = __tvt_ci_ssrg
    tempname BM VM G1M GTM PVM
    matrix `BM'  = __tvt_ci_b
    matrix `VM'  = __tvt_ci_V
    matrix `G1M' = __tvt_ci_g1
    matrix `GTM' = __tvt_ci_gt
    matrix `PVM' = __tvt_ci_pv
    _tvt_drop

    * -------------------------------------------------------- the names
    local nm
    foreach v of local xvars {
        local nm `nm' lower:`v'
    }
    if "`constant'" == "" local nm `nm' lower:_cons
    foreach v of local xvars {
        local nm `nm' upper:`v'
    }
    if "`constant'" == "" local nm `nm' upper:_cons
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'
    matrix colnames `G1M' = `zvars'

    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nobs')
    ereturn scalar N        = `nobs'
    ereturn scalar gamma0   = `G0'
    ereturn scalar gamma_const = `GC'
    ereturn scalar N_lower  = `N1'
    ereturn scalar N_upper  = `N2'
    ereturn scalar ssr      = `SSR'
    ereturn scalar ssr_lin  = `SSR0'
    ereturn scalar ssr_const = `SSRC'
    ereturn scalar n_ties   = `NT'
    ereturn scalar n_feasible = `NF'
    ereturn scalar n_cand   = `NC'
    ereturn scalar n_grid0  = `NG0'
    ereturn scalar n_grid1  = `NG1'
    ereturn scalar minreg   = `MINN'
    ereturn scalar ssr_grid = `SSRG'
    ereturn scalar trim     = `trim'
    ereturn scalar gstep    = `gstep'
    ereturn scalar reps     = `reps'
    ereturn scalar F1       = `F1'
    ereturn scalar F2       = `F2'
    ereturn scalar rho_e    = `RHO'
    if `reps' > 0 {
        ereturn scalar n_boot = `NOK'
        ereturn scalar p_F1   = `PVM'[1,1]
        ereturn scalar p_F2   = `PVM'[1,2]
    }
    ereturn local  cmd       "tvtcoint"
    ereturn local  cmdline   "tvtcoint `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  indepvars "`xvars'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  zvars     "`zvars'"
    ereturn local  ties      "`ties'"
    ereturn local  boottype  = cond(`reps'==0, "", ///
        cond("`gaussian'"!="", "parametric Gaussian (shipped-code variant)", ///
             "multiplier (paper, Step 1)"))
    ereturn local  title     "Time-varying threshold cointegration"
    ereturn matrix gamma1 = `G1M'
    ereturn matrix path = `GTM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    tempname G1
    matrix `G1' = e(gamma1)
    local zv "`e(zvars)'"
    local nz : word count `zv'

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Yang (2022), SNDE 26(2):257-274" ///
        _col(52) as text "Grid points" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_cand)
    display as text "Threshold variable: " as result "`e(threshvar)'" ///
        _col(52) as text "Admissible" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_feasible)
    display ""
    display as text "{hline 78}"
    display as text "  The threshold is a LINEAR FUNCTION OF COVARIATES:"
    local eq = "    gamma(t) = " + string(e(gamma0), "%9.0g")
    forvalues j = 1/`nz' {
        local zz : word `j' of `zv'
        local cf = `G1'[1,`j']
        local sgn = cond(`cf' < 0, " - ", " + ")
        local eq = "`eq'" + "`sgn'" + string(abs(`cf'), "%9.0g") + " `zz'"
    }
    display as text "`eq'"
    display as text "{hline 78}"
    display as text "    gamma_0" _col(30) as result %14.6g e(gamma0)
    forvalues j = 1/`nz' {
        local zz : word `j' of `zv'
        display as text "    gamma_1 (`zz')" _col(30) as result %14.6g ///
            `G1'[1,`j']
    }
    display as text "    constant threshold" _col(30) as result %14.6g ///
        e(gamma_const)
    display as text "    observations below / above" _col(32) as result ///
        %6.0f e(N_lower) as text " /" as result %6.0f e(N_upper)
    if e(n_ties) > 1 {
        display as text "    tied minimisers averaged" _col(30) as result ///
            %14.0f e(n_ties)
    }
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  SSR: linear " as result %11.4f e(ssr_lin) ///
        as text "  constant gamma " as result %11.4f e(ssr_const) ///
        as text "  tv gamma " as result %11.4f e(ssr)
    display as text "{hline 78}"
    display as text "  Tests" _col(36) "statistic" _col(52) "p-value"
    display as text "    F1  no threshold at all" _col(36) ///
        as result %11.4f e(F1) _col(50) ///
        cond(e(reps)>0, string(e(p_F1), "%9.4f"), "       --")
    display as text "    F2  threshold is CONSTANT" _col(36) ///
        as result %11.4f e(F2) _col(50) ///
        cond(e(reps)>0, string(e(p_F2), "%9.4f"), "       --")
    display as text "{hline 78}"
    if e(reps) == 0 {
        display as text "  Both have NON-STANDARD null distributions" ///
            " (Davies' problem: gamma is"
        display as text "  unidentified under H1). Specify {bf:reps()}" ///
            " for bootstrap p-values;"
        display as text "  until then the statistics are descriptive only."
    }
    else {
        display as text "  Bootstrap: `e(boottype)', `e(n_boot)'" ///
            " usable replications."
        display as text "  F1 asks whether there is a threshold; F2 asks" ///
            " whether it MOVES."
    }
    display as text "{hline 78}"
    if e(rho_e) < . {
        display as text "  First-order autocorrelation of the residuals" ///
            _col(52) as result %9.4f e(rho_e)
        * Under a genuine unit root the OLS estimate of rho is biased
        * down to about 1 - 5/T, so that, and not 1, is the value a
        * non-stationary error would actually produce at this sample
        * size. Warning any earlier would fire on the paper's own
        * application, whose residuals have rho = 0.95 at T = 323 -- a
        * persistent but perfectly stationary error.
        local rhoref = 1 - 5/e(N)
        if abs(e(rho_e)) > `rhoref' {
            display as error "  At T = " e(N) " a unit-root error would" ///
                " show rho near " %5.3f `rhoref' ", so this"
            display as error "  is indistinguishable from one." ///
                " Assumption 1 requires a STATIONARY"
            display as error "  error: if it fails the regression is" ///
                " spurious in at least one"
            display as error "  regime and nothing above is" ///
                " interpretable. Test the residuals."
        }
        else {
            display as text "  (descriptive only -- the paper derives no" ///
                " residual-based test;"
            display as text "   a unit-root error would show rho near " ///
                as result %5.3f `rhoref' as text " at this T)"
        }
    }
    display as text "{hline 78}"
    display as text "  NO interval is reported for gamma or for the" ///
        " slopes. Theorem 1 gives"
    display as text "  the threshold's limiting distribution but its" ///
        " scale factors depend on"
    display as text "  the joint density of (q,z), for which the paper" ///
        " proposes no estimator;"
    display as text "  and no distribution for beta is derived at all." ///
        " The standard errors"
    display as text "  above are OLS GIVEN the estimated path -- see" ///
        " {help tvtcoint##inference:the help}."
end
