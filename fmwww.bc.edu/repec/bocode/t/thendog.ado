*! thendog 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Structural threshold regression: a threshold model whose THRESHOLD
*! VARIABLE is endogenous, and whose regressors may be too.
*!
*!   Kourtellos, A., T. Stengos and C. M. Tan (2016) "Structural Threshold
*!     Regression", Econometric Theory 32:827-860,
*!     doi:10.1017/S0266466615000067
*!   Hansen, B. E. (2000) Econometrica 68:575-603, doi:10.1111/1468-0262.00124
*!   Caner, M. and B. E. Hansen (2004) Econometric Theory 20:813-843,
*!     doi:10.1017/S0266466604205011
*!
*! Syntax follows ivregress / thivreg:
*!   thendog y x2 (x1 = z1 z2), threshvar(q)
*! where x1 are endogenous regressors, x2 exogenous, and q is the
*! ENDOGENOUS threshold variable, instrumented by the same z.
*!
*! See thendog.sthlp.

program define thendog, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thendog" error 301
        Display
        exit
    }

    syntax anything(equalok) [if] [in] , ///
        THRESHvar(varname numeric)       ///
        [ TRIM(real 0.15)                ///
          GRIDn(integer 0)               ///
          MINObs(integer 0)              ///
          NOMills                        ///
          NODFadj                        ///
          Level(cilevel) ]

    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `gridn' < 0 {
        display as error "{bf:gridn()} cannot be negative"
        exit 198
    }
    if "`level'" == "" local level = c(level)

    * ---------------------------------------------- parse the ivregress form
    local eqn `"`anything'"'
    local lp = strpos(`"`eqn'"', "(")
    if `lp' == 0 {
        display as error "no instrument block found."
        display as error "The syntax follows {helpb ivregress}:"
        display as error "  {bf:thendog y x2 (x1 = z1 z2), threshvar(q)}"
        display as error "If nothing is endogenous but the THRESHOLD still is,"
        display as error "write an empty left side: {bf:thendog y x (= z)}."
        exit 198
    }
    local rp = strpos(`"`eqn'"', ")")
    if `rp' <= `lp' {
        display as error "unbalanced parentheses in the instrument block"
        exit 198
    }
    local exog  = trim(substr(`"`eqn'"', 1, `lp' - 1))
    local inner = trim(substr(`"`eqn'"', `lp' + 1, `rp' - `lp' - 1))
    local eqp = strpos(`"`inner'"', "=")
    if `eqp' == 0 {
        display as error "the instrument block needs an {bf:=}"
        exit 198
    }
    local endog = trim(substr(`"`inner'"', 1, `eqp' - 1))
    local insts = trim(substr(`"`inner'"', `eqp' + 1, .))

    gettoken yv exog : exog
    if "`yv'" == "" {
        display as error "no dependent variable"
        exit 198
    }
    confirm numeric variable `yv'
    if "`insts'" == "" {
        display as error "no instruments given. The threshold variable is"
        display as error "treated as endogenous here, so instruments are"
        display as error "required even when every regressor is exogenous."
        exit 198
    }
    * each loop body on its own line: inside a program Stata refuses an
    * open brace with code after it on the same line, even though the
    * interactive command window accepts it
    foreach v of local exog {
        confirm numeric variable `v'
    }
    foreach v of local endog {
        confirm numeric variable `v'
    }
    foreach v of local insts {
        confirm numeric variable `v'
    }

    local kend : word count `endog'
    local kexo : word count `exog'
    local kins : word count `insts'
    if `kins' < `kend' {
        display as error "`kins' instrument(s) for `kend' endogenous"
        display as error "regressor(s): the model is under-identified."
        display as error "Note the THRESHOLD variable also needs the"
        display as error "instruments, so they are doing double duty here."
        exit 481
    }

    marksample touse
    markout `touse' `yv' `exog' `endog' `insts' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        display as error "too few observations: `nobs'"
        exit 2001
    }

    * ---------------------------------------------- the reduced forms
    * g_x = E(x|z): fitted values for the ENDOGENOUS regressors, and the
    * exogenous regressors as they stand (they are their own projections,
    * since they belong to z).
    local gxv ""
    local glab ""
    local gi 0
    foreach v of local endog {
        local ++gi
        * a plain counter, not a name assembled from the variable's length:
        * two regressors of the same name length would collide, and a
        * tempvar reference built out of an expression is brittle in a way
        * that fails silently rather than loudly.
        tempvar gfit`gi'
        quietly regress `v' `insts' `exog' if `touse'
        if _rc {
            display as error "the reduced form for {bf:`v'} could not be fitted"
            exit 498
        }
        quietly predict double `gfit`gi'' if `touse', xb
        local gxv `gxv' `gfit`gi''
        local glab `glab' `v'
    }
    foreach v of local exog {
        local gxv `gxv' `v'
        local glab `glab' `v'
    }
    * the constant enters the regime blocks, so it is a column of G
    tempvar one
    quietly generate byte `one' = 1 if `touse'
    local gxv `gxv' `one'
    local glab `glab' _cons

    * the instrument matrix for the SELECTION equation includes a constant
    tempvar zone
    quietly generate byte `zone' = 1 if `touse'
    local zv "`insts' `exog' `zone'"

    local qv     "`threshvar'"
    local trimv  `trim'
    local maxg   `gridn'
    local mobs   = cond(`minobs' > 0, `minobs', max(5, ceil(`trim'*`nobs')))
    local nomills = cond("`nomills'" != "", 1, 0)
    local nodfadj = cond("`nodfadj'" != "", 1, 0)

    _tk_drop
    mata: tk_thendog()

    if __tk_enfail == 1 {
        _tk_drop
        display as error "too few observations for this many regressors"
        exit 2001
    }
    if __tk_enfail == 2 {
        _tk_drop
        display as error "the selection equation for {bf:`threshvar'} could"
        display as error "not be fitted: the instruments are collinear, or"
        display as error "they explain none of its variation."
        exit 498
    }
    if __tk_enfail == 3 {
        _tk_drop
        display as error "the threshold grid is empty at trim(`trim')"
        exit 498
    }
    if __tk_enfail == 4 {
        _tk_drop
        display as error "no admissible threshold. Either every split leaves"
        display as error "a regime below {bf:minobs()}, or the inverse Mills"
        display as error "ratios overflow at every candidate -- which happens"
        display as error "when the selection equation fits so well that the"
        display as error "regime is nearly deterministic given the"
        display as error "instruments."
        exit 498
    }

    tempname B V PROF PIQ
    matrix `B'    = __tk_enb
    matrix `V'    = __tk_enV
    matrix `PROF' = __tk_enprof
    matrix `PIQ'  = __tk_enpiq
    * gamma, the residual variance and sigma_v are carried in SCALARS, not
    * locals. `local g = <scalar>` formats through %18.0g, and gamma is an
    * OBSERVED value of the threshold variable -- losing its last bit flips
    * the q <= gamma comparison for exactly that observation, moving the
    * regime split by one and e(ssr) by one squared residual. thivreg posts
    * its threshold straight from the Mata scalar for this reason.
    tempname GAM SSR SIG SVv
    scalar `GAM' = __tk_engam
    scalar `SSR' = __tk_enssr
    scalar `SIG' = __tk_ensig
    scalar `SVv' = __tk_ensv
    local gam  = __tk_engam
    local ssr  = __tk_enssr
    local sig  = __tk_ensig
    local sv   = __tk_ensv
    local n1   = __tk_enn1
    local n2   = __tk_enn2
    local npt  = __tk_ennpt
    local ng   = __tk_enng
    local nuse = __tk_enn
    local kw   = __tk_enk
    _tk_drop

    * ---------------------------------------------- names
    local nm ""
    foreach v of local glab {
        local nm `nm' r1:`v'
    }
    foreach v of local glab {
        local nm `nm' r2:`v'
    }
    if !`nomills' local nm `nm' mills:kappa
    local cn ""
    local ce ""
    foreach t of local nm {
        local ce `ce' `=substr("`t'", 1, strpos("`t'",":")-1)'
        local cn `cn' `=substr("`t'", strpos("`t'",":")+1, .)'
    }
    matrix colnames `B' = `cn'
    matrix coleq    `B' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    * ---------------------------------------------- post
    ereturn post `B' `V', esample(`touse') depname(`yv') obs(`nuse')
    ereturn scalar gamma     = `GAM'
    ereturn scalar ssr       = `SSR'
    ereturn scalar sigma2    = `SIG'
    ereturn scalar sigma_v   = `SVv'
    ereturn scalar N_regime1 = `n1'
    ereturn scalar N_regime2 = `n2'
    ereturn scalar ngrid     = `ng'
    ereturn scalar npoints   = `npt'
    ereturn scalar trim      = `trim'
    ereturn scalar level     = `level'
    ereturn scalar k_coef    = `kw'
    ereturn local  cmd       "thendog"
    ereturn local  depvar    "`yv'"
    ereturn local  indepvars "`glab'"
    ereturn local  endogvars "`endog'"
    ereturn local  exogvars  "`exog'"
    ereturn local  insts     "`insts'"
    ereturn local  threshold_var "`threshvar'"
    ereturn local  vcetype   "Robust"
    ereturn local  vcelab    "heteroskedasticity-robust, conditional on gamma-hat"
    ereturn local  title     "Structural threshold regression"
    ereturn local  properties "b V"
    ereturn matrix profile = `PROF'
    ereturn matrix piq     = `PIQ'

    Display
end

program define Display
    version 15

    local gam = e(gamma)
    local nomills = (strpos("`: colnames e(b)'", "kappa") == 0)

    display _n as text "`e(title)'" _col(52) "Number of obs = " ///
        as result %8.0f e(N)
    display as text "{hline 78}"
    display as text "  threshold variable" _col(46) as result %30s ///
        "`e(threshold_var)' (ENDOGENOUS)"
    display as text "  instruments" _col(46) as result %30s "`e(insts)'"
    if "`e(endogvars)'" != "" {
        display as text "  endogenous regressors" _col(46) as result %30s ///
            "`e(endogvars)'"
    }
    display as text "  threshold estimate" _col(46) as result %30.6f `gam'
    display as text "  regime sizes" _col(46) as result %30s ///
        "`=e(N_regime1)' / `=e(N_regime2)'"
    display as text "  selection-equation sigma" _col(46) as result %30.6f ///
        e(sigma_v)
    display as text "  grid points searched" _col(46) as result %30.0f e(npoints)
    display as text "{hline 78}"

    ereturn display, level(`e(level)')

    * ---- the endogeneity test, which is just a t test on kappa
    if !`nomills' {
        capture local kb = _b[mills:kappa]
        capture local ks = _se[mills:kappa]
        if !_rc & `ks' > 0 {
            local kt = `kb'/`ks'
            local kp = 2*normal(-abs(`kt'))
            display as text "  {bf:Test of threshold exogeneity} (kappa = 0)"
            display as text "    kappa" _col(24) as result %12.6f `kb' ///
                as text "   z = " as result %8.3f `kt' ///
                as text "   p = " as result %7.4f `kp'
            if `kp' < 0.10 {
                display as text "    The threshold variable IS endogenous at"
                display as text "    the 10% level: the inverse Mills terms"
                display as text "    belong in the model, and {helpb thivreg}"
                display as text "    or {helpb thregress} would be biased here."
            }
            else {
                display as text "    No evidence that the threshold variable is"
                display as text "    endogenous. {helpb thivreg} (endogenous"
                display as text "    regressors, exogenous threshold) or"
                display as text "    {helpb thregress} may be the better fit,"
                display as text "    and both are more efficient than this."
            }

            * ---------------------------------------------------------------
            * THE CONSISTENCY CONDITION, and it has to be shown rather than
            * buried in the help.
            *
            * Yu, Liao and Phillips (2024) Econometric Theory 40:1065-1119,
            * doi:10.1017/S0266466623000014, section 2.2, prove that THIS
            * estimator of gamma is INCONSISTENT unless kappa/delta <= 0.587,
            * and that no kappa makes it consistent for every delta: in their
            * words, only if q is exogenous is the KST estimator consistent
            * for any delta != 0. Even below 0.587 it may still be
            * inconsistent.
            *
            * So the very case this command is for is the case where its
            * threshold estimate may not converge to the truth. The SLOPES
            * are not the problem; gamma is.
            *
            * delta is the regime difference. The paper's 0.587 is derived
            * for a scalar jump, so with several coefficients there is no
            * single ratio the theorem speaks to. The largest |difference| is
            * used, which is the most FAVOURABLE reading -- if even that
            * fails the condition, the warning is unambiguous.
            * ---------------------------------------------------------------
            tempname BE
            matrix `BE' = e(b)
            local kc = colsof(`BE')
            local nblk = (`kc' - 1)/2
            local dmax = 0
            if `nblk' == int(`nblk') & `nblk' >= 1 {
                forvalues j = 1/`nblk' {
                    local d = abs(`BE'[1,`j'] - `BE'[1,`=`j'+`nblk''])
                    if `d' > `dmax' local dmax = `d'
                }
            }
            if `dmax' > 0 {
                local ratio = abs(`kb')/`dmax'
                display as text ""
                display as text "  {bf:Consistency of the threshold estimate}"
                display as text "    |kappa| / largest regime difference" ///
                    _col(48) as result %26.4f `ratio'
                display as text "    Yu-Liao-Phillips bound" _col(48) ///
                    as result %26.4f 0.587
                if `ratio' > 0.587 {
                    display as error "    {bf:WARNING. Above the bound.}" ///
                        " Yu, Liao and"
                    display as error "    Phillips (2024, sec. 2.2) prove this"
                    display as error "    estimator of the THRESHOLD is"
                    display as error "    INCONSISTENT when this ratio exceeds"
                    display as error "    0.587. The slopes are not the issue;"
                    display as error "    gamma is. Treat the threshold above as"
                    display as error "    unreliable, and prefer a method built"
                    display as error "    for an endogenous threshold from the"
                    display as error "    start."
                }
                else {
                    display as text "    Below the bound, which is necessary but"
                    display as text "    NOT sufficient: the same paper shows"
                    display as text "    gamma may be inconsistent even here,"
                    display as text "    and that only an EXOGENOUS threshold"
                    display as text "    makes this estimator consistent for"
                    display as text "    every regime difference. Read the"
                    display as text "    threshold as indicative."
                }
            }
        }
    }
    display as text "{hline 78}"
    display as text "  kappa is ONE number shared by both regimes: it is the"
    display as text "  covariance between the structural error and the"
    display as text "  selection error, and the regimes differ only in which"
    display as text "  branch of the truncation they sit on. Two separate"
    display as text "  kappas would be a different, unidentified model."
    display as text ""
    display as text "  Standard errors are heteroskedasticity-robust and"
    display as text "  CONDITION on the estimated threshold. They do not"
    display as text "  carry the first-stage estimation error, so treat them"
    display as text "  as the usual two-step understatement."
    display as text ""
    display as text "  The threshold has no standard error here either: its"
    display as text "  limit distribution is non-standard, and the paper"
    display as text "  recommends a bootstrap interval for it."
end
