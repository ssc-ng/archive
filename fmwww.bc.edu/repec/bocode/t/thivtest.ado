*! thivtest 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Sup-Wald test for an unknown threshold with ENDOGENOUS regressors.
*!
*!   Rothfelder, M. P. and O. Boldea (2022) "Testing for a Threshold in
*!     Models with Endogenous Regressors", arXiv:2207.10076
*!   Caner, M. and B. E. Hansen (2004) Econometric Theory 20:813-843,
*!     doi:10.1017/S0266466604205011
*!
*! Syntax follows ivregress / thivreg:
*!   thivtest y x2 (x1 = z1 z2), threshvar(q)
*!
*! See thivtest.sthlp.

program define thivtest, rclass
    version 15

    syntax anything(equalok) [if] [in] , ///
        THRESHvar(varname numeric)       ///
        [ TRIM(real 0.15)                ///
          GRIDn(integer 100)             ///
          MINObs(integer 0)              ///
          REPS(integer 499)              ///
          SEED(string)                   ///
          CHtest                         ///
          noBOOTstrap                    ///
          Level(cilevel) ]

    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `gridn' < 0 {
        display as error "{bf:gridn()} cannot be negative"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }
    if "`level'" == "" local level = c(level)

    * ---------------------------------------------- parse the ivregress form
    local eqn `"`anything'"'
    local lp = strpos(`"`eqn'"', "(")
    if `lp' == 0 {
        display as error "no instrument block found."
        display as error "The syntax follows {helpb ivregress}:"
        display as error "  {bf:thivtest y x2 (x1 = z1 z2), threshvar(q)}"
        display as error "With nothing endogenous there is no reason to use"
        display as error "this command: use {helpb thtest} instead, which is"
        display as error "the ordinary sup-Wald test."
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
    if "`endog'" == "" {
        display as error "no endogenous regressors given."
        display as error "This test exists for the endogenous case; with"
        display as error "everything exogenous use {helpb thtest}."
        exit 198
    }
    if "`insts'" == "" {
        display as error "no excluded instruments given"
        exit 198
    }
    confirm numeric variable `yv'
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
    local kins : word count `insts'
    if `kins' < `kend' {
        display as error "`kins' excluded instrument(s) for `kend'"
        display as error "endogenous regressor(s): under-identified."
        exit 481
    }

    marksample touse
    markout `touse' `yv' `exog' `endog' `insts' `threshvar'
    quietly count if `touse'
    local nobs = r(N)

    * ---------------------------------------------- build the matrices
    * w_t = (endogenous, exogenous, constant); z_t = (instruments,
    * exogenous, constant). The exogenous regressors and the constant are
    * their own instruments, which is what makes q - p2 >= p1 the
    * identification condition rather than a raw count of z.
    tempvar one
    quietly generate byte `one' = 1 if `touse'
    local wv "`endog' `exog' `one'"
    local zv "`insts' `exog' `one'"
    local kw : word count `wv'
    local kz : word count `zv'
    if `nobs' < 10*`kw' {
        display as error "too few observations (`nobs') for `kw' coefficients"
        exit 2001
    }

    local qv     "`threshvar'"
    local trimv  `trim'
    local maxg   `gridn'
    local mobs   = cond(`minobs' > 0, `minobs', max(`=`kw'+2', ceil(`trim'*`nobs')))
    local chtest = cond("`chtest'" != "", 1, 0)
    local nreps  = cond("`bootstrap'" != "", 0, `reps')

    if "`seed'" != "" set seed `seed'

    _tk_drop
    mata: tk_thivtest()

    if __tk_ivtfail == 1 {
        _tk_drop
        display as error "too few observations for this many coefficients"
        exit 2001
    }
    if __tk_ivtfail == 2 {
        _tk_drop
        display as error "the full-sample GMM fit failed: the instruments"
        display as error "are collinear, or too weak to identify the model"
        display as error "under the null."
        exit 498
    }
    if __tk_ivtfail == 3 {
        _tk_drop
        display as error "the threshold grid is empty at trim(`trim')"
        exit 498
    }
    if __tk_ivtfail == 4 {
        _tk_drop
        display as error "the statistic could not be computed at any"
        display as error "candidate threshold. Every split leaves a regime"
        display as error "too small to identify its own GMM fit; raise"
        display as error "{bf:trim()} or lower {bf:minobs()}."
        exit 498
    }

    tempname TH GRID BOOT
    matrix `TH'   = __tk_ivtth
    matrix `GRID' = __tk_ivtgrid
    capture confirm matrix __tk_ivtboot
    local hasboot = (_rc == 0)
    if `hasboot' matrix `BOOT' = __tk_ivtboot
    * the statistic and the threshold are carried in SCALARS: `local x =
    * <scalar>` formats through %18.0g, and a threshold that is an OBSERVED
    * value of q loses its last bit that way, so anyone re-splitting on
    * r(gamma) would get a different sample than the test used.
    tempname WST GAM WALT GALT
    scalar `WST'  = __tk_ivtw
    scalar `GAM'  = __tk_ivtgam
    scalar `WALT' = __tk_ivtwalt
    scalar `GALT' = __tk_ivtgalt
    local wstat = __tk_ivtw
    local gam   = __tk_ivtgam
    local pb    = __tk_ivtp
    local walt  = __tk_ivtwalt
    local galt  = __tk_ivtgalt
    local npt   = __tk_ivtnpt
    local ng    = __tk_ivtng
    local nb    = __tk_ivtnb
    local nuse  = __tk_ivtn
    local kk    = __tk_ivtk
    local qq    = __tk_ivtq
    _tk_drop

    local nm ""
    foreach v of local endog {
        local nm `nm' `v'
    }
    foreach v of local exog {
        local nm `nm' `v'
    }
    local nm `nm' _cons
    matrix colnames `TH' = `nm'

    * ---------------------------------------------- display
    local tname = cond(`chtest', "Caner-Hansen (2004)", ///
                                 "Rothfelder-Boldea, size-corrected")
    local aname = cond(`chtest', "Rothfelder-Boldea, size-corrected", ///
                                 "Caner-Hansen (2004)")

    display _n as text "Sup-Wald test for a threshold with endogenous regressors"
    display as text "{hline 76}"
    display as text "  H0: no threshold (theta1 = theta2)"
    display as text "{hline 76}"
    display as text "  dependent variable" _col(44) as result %32s "`yv'"
    display as text "  endogenous regressors" _col(44) as result %32s "`endog'"
    if "`exog'" != "" {
        display as text "  exogenous regressors" _col(44) as result %32s "`exog'"
    }
    display as text "  excluded instruments" _col(44) as result %32s "`insts'"
    display as text "  threshold variable (exogenous)" _col(44) ///
        as result %32s "`threshvar'"
    display as text "  observations" _col(44) as result %32.0f `nuse'
    display as text "  coefficients / instruments" _col(44) as result %32s ///
        "`kk' / `qq'"
    display as text "  grid points searched" _col(44) as result %32.0f `npt'
    display as text "{hline 76}"
    display as text "  variant reported" _col(44) as result %32s "`tname'"
    display as text "  sup-Wald statistic" _col(44) as result %32.4f `wstat'
    display as text "  attained at threshold" _col(44) as result %32.6f `gam'
    if `nb' > 0 {
        display as text "  bootstrap p-value" _col(44) as result %32.4f `pb'
        display as text "  replications used" _col(44) as result %32.0f `nb'
    }
    display as text "{hline 76}"
    display as text "  for comparison, `aname':"
    display as text "    statistic" _col(44) as result %32.4f `walt'
    display as text "    at threshold" _col(44) as result %32.6f `galt'
    display as text "{hline 76}"

    * ---------------------------------------------- the standing notes
    if `chtest' {
        display as error "  You asked for the ORIGINAL Caner-Hansen variant."
        display as error "  Rothfelder and Boldea show by simulation that it"
        display as error "  is severely size-distorted in small and even"
        display as error "  moderately large samples -- oversized in small"
        display as error "  ones, undersized in larger ones. Drop {bf:chtest}"
        display as error "  unless you are deliberately reproducing it."
    }
    else {
        display as text "  TWO corrections are applied, and they only work"
        display as text "  as a pair. The bootstrap draws the pseudo-series"
        display as text "  from FULL-SAMPLE residuals under the null rather"
        display as text "  than per-threshold ones, which removes the"
        display as text "  UNDERSIZING; that alone leaves the test"
        display as text "  OVERSIZED, so the robust weight matrices are"
        display as text "  built from full-sample residuals too. Both"
        display as text "  corrections exist for one reason: subsample"
        display as text "  residuals are poor near the edges of the grid,"
        display as text "  where a regime holds few observations."
    }
    display as text ""
    display as text "  The limit is NOT pivotal, so the bootstrap p-value is"
    display as text "  the only one to report. Every replication re-searches"
    display as text "  the whole grid, because the observed statistic did."
    if `nb' == 0 {
        display as error "  No bootstrap was run, so there is NO p-value."
        display as error "  The statistic alone cannot be compared with any"
        display as error "  tabulated critical value: its distribution"
        display as error "  depends on the data. Drop {bf:nobootstrap}."
    }
    display as text ""
    display as text "  The threshold variable is assumed EXOGENOUS. If it is"
    display as text "  not, this test is not the right one -- see"
    display as text "  {helpb thendog}, which corrects for an endogenous"
    display as text "  threshold and tests that endogeneity directly."

    * ---------------------------------------------- stored results
    return scalar stat     = `WST'
    return scalar p        = `pb'
    return scalar gamma    = `GAM'
    return scalar stat_alt = `WALT'
    return scalar gamma_alt = `GALT'
    return scalar N        = `nuse'
    return scalar k        = `kk'
    return scalar q        = `qq'
    return scalar ngrid    = `ng'
    return scalar npoints  = `npt'
    return scalar reps     = `nb'
    return scalar trim     = `trim'
    return local  variant  = cond(`chtest', "ch", "rb")
    return local  cmd      "thivtest"
    return local  depvar   "`yv'"
    return local  endogvars "`endog'"
    return local  insts    "`insts'"
    return local  threshold_var "`threshvar'"
    return matrix b     = `TH', copy
    return matrix grid  = `GRID', copy
    if `hasboot' return matrix bootdist = `BOOT', copy
end
