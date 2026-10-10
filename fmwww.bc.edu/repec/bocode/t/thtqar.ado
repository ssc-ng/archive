*! thtqar 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold quantile autoregression: a SETAR fitted at a chosen quantile
*! rather than at the conditional mean. It builds the autoregression, picks the
*! threshold variable (a lag of the series by default) and hands the whole
*! thing to thqreg, so the estimator, the solver, the test and the reporting
*! are the certified ones and there is no second implementation to keep in step.
*! Galvao, Montes-Rojas & Olmo (2011) JTSA 32:253-267,
*!   doi:10.1111/j.1467-9892.2010.00696.x
*! Caner (2002) Econometric Theory 18:800-814, doi:10.1017/s0266466602183113
*! Koenker & Xiao (2006) JASA 101:980-990, doi:10.1198/016214506000000672
*!   for the quantile autoregression this nests at a single regime

program define thtqar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thtqar" error 301
        * thqreg's own replay branch refuses anything whose e(cmd) is not
        * "thqreg", so handing it a thtqar fit raised error 301 and plain
        * `thtqar' -- the reprint -- always failed. Borrow e(cmd) for the
        * duration of the call and give it back, which is what thtar does
        * for thregress. Restore it even if the call errors, or a failed
        * reprint would leave the fit claiming to be a thqreg.
        ereturn local cmd "thqreg"
        capture noisily thqreg
        local rc = _rc
        ereturn local cmd "thtqar"
        exit `rc'
    }

    syntax varname(numeric ts) [if] [in] , AR(numlist integer >0 sort) ///
        [ DELAY(integer 1)                                             ///
          THVar(varname numeric ts)                                   ///
          Quantile(numlist >0 <1 sort)                                 ///
          INVariant(varlist numeric fv ts)                             ///
          TRIM(real 0.15)                                              ///
          GRIDn(integer 50)                                            ///
          MINOBS(integer 0)                                            ///
          TEST                                                         ///
          STAT(string)                                                 ///
          REPS(integer 0)                                              ///
          BOOT(string)                                                 ///
          SEED(string)                                                 ///
          MAXIT(integer 25)                                            ///
          QTOL(real 1e-10)                                             ///
          VCE(string)                                                  ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thtqar} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"
    if `delay' < 1 {
        display as error "{bf:delay()} must be 1 or more"
        exit 198
    }
    local depv `varlist'
    local p : word count `ar'

    marksample touse
    markout `touse' `depv' `invariant'

    * ---- the autoregression, under explicit names so the coefficient table
    *      reads L1.y, L2.y and not a temporary variable
    local arnames ""
    local arvars ""
    capture drop __tkt_*
    foreach j of local ar {
        quietly generate double __tkt_L`j' = L`j'.`depv' if `touse'
        label variable __tkt_L`j' "L`j'.`depv'"
        local arvars `arvars' __tkt_L`j'
        local arnames `arnames' L`j'.`depv'
    }

    * ---- the threshold variable
    if "`thvar'" != "" {
        quietly generate double __tkt_q = `thvar' if `touse'
        local qname "`thvar'"
        local searched 0
    }
    else {
        quietly generate double __tkt_q = L`delay'.`depv' if `touse'
        local qname "L`delay'.`depv'"
        local searched 1
    }
    label variable __tkt_q "`qname'"
    markout `touse' `arvars' __tkt_q

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        capture drop __tkt_*
        exit 2001
    }

    * ---- hand it to thqreg, which is the certified estimator
    local opts ""
    if "`quantile'"  != "" local opts `opts' quantile(`quantile')
    if "`invariant'" != "" local opts `opts' invariant(`invariant')
    if "`stat'"      != "" local opts `opts' stat(`stat')
    if "`boot'"      != "" local opts `opts' boot(`boot')
    if "`seed'"      != "" local opts `opts' seed(`seed')
    if "`vce'"       != "" local opts `opts' vce(`vce')
    if "`test'"      != "" local opts `opts' test
    if `reps' > 0          local opts `opts' reps(`reps')

    display _n as text "{hline 78}"
    display as text "Threshold quantile autoregression" _col(40) ///
        as text "lags: " as result "`arnames'"
    display as text "  Threshold variable: " as result "`qname'"
    if `searched' {
        display as text "  The threshold variable is a lag of the series itself, so this is a"
        display as text "  quantile SETAR: the regime is decided by where the series was."
    }
    display as text "  Fitted by {bf:thqreg} on this autoregressive design: the same"
    display as text "  certified solver, the same check-function search, the same"
    display as text "  sup/ave/exp-LR test, and the same reporting through official"
    display as text "  {bf:qreg}. See {bf:help thqreg} for what the numbers mean and for"
    display as text "  what is deliberately not provided (no confidence set for gamma)."
    display as text "{hline 78}"

    capture noisily thqreg `depv' `arvars' if `touse', threshvar(__tkt_q) ///
        qvarname("`qname'")                                             ///
        trim(`trim') gridn(`gridn') minobs(`minobs') maxit(`maxit')      ///
        qtol(`qtol') level(`level') `opts'
    local rc = _rc
    if `rc' {
        capture drop __tkt_*
        exit `rc'
    }

    * ---- relabel the coefficients with the real lag names, and overwrite the
    *      parts of e() that describe the model rather than the numbers
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local cn : colnames `b'
    local ce : coleq `b'
    local new ""
    foreach c of local cn {
        local nm "`c'"
        local k 0
        foreach j of local ar {
            local ++k
            if "`c'" == "__tkt_L`j'" local nm "L`j'.`depv'"
        }
        local new `new' `nm'
    }
    matrix colnames `b' = `new'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `new'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `new'
    matrix roweq    `V' = `ce'
    ereturn repost b = `b' V = `V', rename

    ereturn local cmd      "thtqar"
    ereturn local cmdline  "thtqar `0'"
    ereturn local title    "Threshold quantile autoregression"
    ereturn local model    = cond("`thvar'"=="", "quantile SETAR", "quantile TAR")
    ereturn local arlags   "`ar'"
    ereturn local arnames  "`arnames'"
    ereturn local indepvars "`arnames'"
    ereturn local threshold_var "`qname'"
    ereturn local timevar  "`timevar'"
    ereturn local estat_cmd "thqreg_estat"
    ereturn local predict   "thqreg_p"
    ereturn scalar lags    = `p'
    ereturn scalar delay   = `delay'
    ereturn scalar searched_delay = `searched'

    capture drop __tkt_*
end
