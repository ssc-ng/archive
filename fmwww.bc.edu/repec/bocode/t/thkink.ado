*! thkink 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Regression kink with an unknown threshold: the regression function is
*! CONTINUOUS at gamma and only its slope in the kink variable changes.
*! Hansen (2017) JBES 35:228-240, doi:10.1080/07350015.2015.1073595

program define thkink, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thkink" error 301
        Display `0'
        exit
    }

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        KINKvar(varname numeric)                    ///
        [ TRIM(real 0.15)                           ///
          GRANGE(numlist min=2 max=2)               ///
          GSTEP(real -1)                            ///
          MINOBS(integer 0)                         ///
          noCONStant                                ///
          TEST                                      ///
          REPS(integer 1000)                        ///
          SEED(string)                              ///
          Level(cilevel) ]

    if `trim' < 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in [0, 0.5)"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    local hascons = cond("`constant'"=="", 1, 0)
    local dotest  = cond("`test'"!="", 1, 0)
    local glo .
    local ghi .
    if "`grange'" != "" {
        local glo : word 1 of `grange'
        local ghi : word 2 of `grange'
        if `glo' >= `ghi' {
            display as error "grange() must be increasing"
            exit 198
        }
    }
    local gstep = cond(`gstep' > 0, `gstep', .)

    marksample touse
    markout `touse' `kinkvar'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'
    quietly count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)

    local zlist ""
    local zvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local zlist `r(varlist)'
        fvrevar `zlist' if `touse'
        local zvars `r(varlist)'
    }

    mata: tk_thkink()

    * ---------------------------------------------- post
    local colnames "kink_below kink_above"
    foreach v of local zlist {
        local colnames `colnames' `v'
    }
    if `hascons' local colnames `colnames' _cons
    local colnames `colnames' gamma

    tempname b V
    matrix `b' = __tk_b
    matrix `V' = __tk_V
    matrix colnames `b' = `colnames'
    matrix colnames `V' = `colnames'
    matrix rownames `V' = `colnames'

    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`nobs')

    ereturn local cmd        "thkink"
    ereturn local cmdline    "thkink `0'"
    ereturn local title      "Regression kink"
    ereturn local model      "kink"
    ereturn local family     "gaussian"
    ereturn local estimator  "least squares (continuous threshold)"
    ereturn local kink_var   "`kinkvar'"
    ereturn local threshold_var "`kinkvar'"
    ereturn local depvar     "`depv'"
    ereturn local indepvars  "`zlist'"
    ereturn local vcetype    "Robust"
    ereturn local vcelab     "robust, threshold-corrected"
    ereturn local properties "b V"
    ereturn local predict    "thkink_p"
    ereturn local estat_cmd  "thkink_estat"

    ereturn scalar N       = __tk_n
    ereturn scalar gamma   = __tk_gamma
    ereturn scalar se_gamma = __tk_segam
    ereturn scalar gamma_lo = __tk_cilo
    ereturn scalar gamma_hi = __tk_cihi
    ereturn scalar ssr     = __tk_ssr
    ereturn scalar ssr0    = __tk_ssr0
    ereturn scalar wald    = __tk_wald
    ereturn scalar level   = `level'
    ereturn scalar trim    = `trim'
    ereturn scalar n_grid  = __tk_ngrid
    ereturn scalar N_below = __tk_n1
    ereturn scalar N_above = __tk_n2
    if `dotest' {
        ereturn scalar p         = __tk_p
        ereturn scalar p_mcse    = sqrt(__tk_p*(1-__tk_p)/`reps')
        ereturn scalar crit      = __tk_crit
        ereturn scalar boot_reps = `reps'
        ereturn local  boot "multiplier (Gaussian)"
        capture ereturn matrix bdist = __tk_bdist
    }
    tempname M
    matrix `M' = __tk_profile
    matrix colnames `M' = gamma ssr wald
    ereturn matrix profile = `M'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    syntax [, Level(cilevel) ]
    if "`level'" == "" local level = e(level)
    local g : display %10.0g e(gamma)
    local g = trim("`g'")

    display ""
    display as text "Regression kink (continuous threshold)" _col(50) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Kink variable: " as result "`e(kink_var)'" _col(50) ///
        as text "SSR" _col(68) "=" _col(71) as result %9.0g e(ssr)
    display as text "Std. err.: `e(vcelab)'" _col(50) ///
        as text "SSR (linear)" _col(68) "=" _col(71) as result %9.0g e(ssr0)
    display ""
    display as text "{hline 78}"
    display as text "  Kink point (gamma)" _col(26) as result %12s "`g'" ///
        as text _col(42) "s.e. " as result %9.0g e(se_gamma)
    local lo : display %8.0g e(gamma_lo)
    local hi : display %8.0g e(gamma_hi)
    display as text "  `level'% confidence interval" _col(26) as result ///
        %12s "[`=trim("`lo'")', `=trim("`hi'")']" ///
        as text _col(42) "Wald (asymptotically normal)"
    display as text "  Observations below / above" _col(26) as result ///
        %5.0fc e(N_below) as text " / " as result %-5.0fc e(N_above) ///
        as text _col(42) "grid points: " as result e(n_grid)
    display as text "{hline 78}"
    if e(p) < . {
        display as text "  Test of H0: no kink (linear in `e(kink_var)')"
        display as text "    sup-Wald" _col(26) as result %12.5f e(wald) ///
            as text _col(42) "bootstrap p = " as result %6.4f e(p) ///
            as text " (" as result e(boot_reps) as text " reps)"
        display as text "    `level'% critical value" _col(26) as result %12.5f e(crit) ///
            as text _col(42) "multiplier bootstrap"
        display as text "{hline 78}"
    }
    display ""
    _coef_table, level(`level')
    display as text "kink_below / kink_above are the slopes in `e(kink_var)' on either"
    display as text "side of gamma. The fitted function is continuous at gamma, so the"
    display as text "slope CHANGE is kink_above - kink_below ({bf:lincom} it)."
    display as text "gamma is estimated jointly: its standard error already accounts for"
    display as text "that (Hansen 2017). Unlike {bf:thregress}, the limit here is normal."
end
