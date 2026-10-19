*! tvtpredreg 1.0.0  14oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Testing a PREDICTIVE regression for structural change to a THRESHOLD
*! predictive regression. Two statistics; which is valid depends on
*! whether the predictor is stationary or a unit root, so method() is
*! REQUIRED and has no default.
*!
*! Zhu, F., M. Liu, S. Ling and Z. Cai (2023) JBES 41(1):228-240,
*!   doi:10.1080/07350015.2021.2008406
*!
*! Clean-room. See validation/tvthresh/tvtpredreg_equation_map.md for the
*! four tuning parameters the preprint leaves undefined.

program define tvtpredreg, rclass
    version 15

    syntax varlist(numeric ts min=2) [if] [in] ,    ///
        THReshvar(varname numeric ts)               ///
        METHod(string)                              ///
        [ PI1(real 0.85)                            ///
          LAMBDA1(real 0.15)                        ///
          LAMBDA2(real 0.85)                        ///
          BOOTReps(integer 499)                     ///
          SEED(string)                              ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    local method = lower("`method'")
    if !inlist("`method'", "glr", "gf") {
        display as error "{bf:method()} must be {bf:glr} or {bf:gf}, and" ///
            " it has no default."
        display as error ""
        display as error "This is not a style preference. The two" ///
            " statistics have DIFFERENT"
        display as error "bootstraps and which one is valid depends on" ///
            " the predictor:"
        display as error "  {bf:glr} a generalised likelihood ratio, for" ///
            " a STATIONARY predictor"
        display as error "  {bf:gf}  a generalised F, for a UNIT-ROOT" ///
            " predictor (fixed-regressor"
        display as error "      bootstrap, because standard bootstrap" ///
            " fails under non-stationarity)"
        display as error "Choosing wrong invalidates the inference, so" ///
            " the choice is yours to make"
        display as error "and to defend. Test the predictor first."
        exit 198
    }
    if `pi1' <= 0 | `pi1' >= 1 {
        display as error "{bf:pi1()} must be in (0, 1)"
        exit 198
    }
    if `lambda1' <= 0 | `lambda2' >= 1 | `lambda1' >= `lambda2' {
        display as error "{bf:lambda1()} and {bf:lambda2()} must satisfy" ///
            " 0 < lambda1 < lambda2 < 1"
        exit 198
    }
    if `bootreps' < 99 {
        display as error "{bf:bootreps()} must be at least 99"
        exit 198
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is the threshold variable and" ///
                " cannot also be a predictor"
            exit 198
        }
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 25 {
        display as error "too few observations (`nobs')"
        exit 2001
    }

    local qvar "`threshvar'"
    local lam1 `lambda1'
    local lam2 `lambda2'
    if "`seed'" != "" set seed `seed'
    _tvt_drop
    mata: tvt_predreg()

    if __tvt_pr_fail == 1 {
        _tvt_drop
        display as error "the statistic could not be computed"
        display as error "No admissible split left both sides able to" ///
            " support the regression."
        display as error "Widen {bf:lambda1()}/{bf:lambda2()}, lower" ///
            " {bf:pi1()}, or check that"
        display as error "`depv' and the predictors are not collinear."
        exit 498
    }

    tempname ST GLR GF KK RR NV CV C90 C95 C99 PV NN
    scalar `ST'  = __tvt_pr_stat
    scalar `GLR' = __tvt_pr_glr
    scalar `GF'  = __tvt_pr_gf
    scalar `KK'  = __tvt_pr_k
    scalar `RR'  = __tvt_pr_r
    scalar `NV'  = __tvt_pr_nvis
    scalar `CV'  = __tvt_pr_cv
    scalar `C90' = __tvt_pr_cv90
    scalar `C95' = __tvt_pr_cv95
    scalar `C99' = __tvt_pr_cv99
    scalar `PV'  = __tvt_pr_p
    scalar `NN'  = __tvt_pr_n
    _tvt_drop

    local rej = (`ST' > `CV')
    local mname = cond("`method'"=="glr", ///
        "generalised likelihood ratio (stationary predictor)", ///
        "generalised F (unit-root predictor)")

    display ""
    display as text "Predictive regression against THRESHOLD predictive" ///
        " regression"
    display as text "Zhu, Liu, Ling and Cai (2023), JBES 41(1)" ///
        _col(56) "Obs used" _col(68) "=" _col(71) as result %9.0fc `NN'
    display as text "{hline 78}"
    display as text "  statistic: " as result "`mname'"
    display as text "  H0: no change and no threshold effect"
    display as text "  H1: changes to a threshold predictive regression," ///
        " threshold on L.`threshvar'"
    display as text "{hline 78}"
    display as text "  `=upper("`method'")' statistic" _col(28) as result ///
        %14.4f `ST'
    display as text "  break at observation" _col(28) as result %14.0f `KK'
    display as text "  threshold value" _col(28) as result %14.6f `RR'
    display as text "  splits searched" _col(28) as result %14.0fc `NV'
    display as text "{hline 78}"
    display as text "  bootstrap critical values (" as result ///
        `bootreps' as text " draws)"
    display as text "     10%" _col(14) as result %10.4f `C90' ///
        as text _col(28) "5%" _col(34) as result %10.4f `C95' ///
        as text _col(48) "1%" _col(54) as result %10.4f `C99'
    display as text "  bootstrap p-value" _col(28) as result %14.4f `PV'
    display as text "{hline 78}"
    display as text "  At the `level'% level the null is " as result ///
        cond(`rej', "REJECTED", "not rejected") as text "."
    display as text "{hline 78}"
    display as text "  The other statistic on these data is " as result ///
        %10.4f cond("`method'"=="glr", `GF', `GLR') as text ///
        cond("`method'"=="glr", "  (GF)", "  (GLR)")
    display as text "  It is reported for comparison ONLY. Its critical" ///
        " values come from a"
    display as text "  DIFFERENT bootstrap and have not been computed," ///
        " so it must not be"
    display as text "  compared with the ones above."
    display as text "{hline 78}"
    display as text "  {bf:pi1(`pi1') lambda1(`lambda1')" ///
        " lambda2(`lambda2') bootreps(`bootreps')}"
    display as text "  These four are {bf:not the paper's values} {hline 2}" ///
        " the preprint on which this"
    display as text "  is based never states them. They are conventional" ///
        " choices. Report them"
    display as text "  with your results, and check the published JBES" ///
        " version if you need to"
    display as text "  match its tables. See {helpb tvtpredreg##tuning:the" ///
        " help file}."
    display as text "{hline 78}"

    return scalar stat     = `ST'
    return scalar glr      = `GLR'
    return scalar gf       = `GF'
    return scalar reject   = `rej'
    return scalar p        = `PV'
    return scalar cv       = `CV'
    return scalar cv10     = `C90'
    return scalar cv05     = `C95'
    return scalar cv01     = `C99'
    return scalar k        = `KK'
    return scalar r        = `RR'
    return scalar N        = `NN'
    return scalar level    = `level'
    return scalar pi1      = `pi1'
    return scalar lambda1  = `lambda1'
    return scalar lambda2  = `lambda2'
    return scalar bootreps = `bootreps'
    return scalar n_split  = `NV'
    return local  method   "`method'"
    return local  depvar   "`depv'"
    return local  predictors "`xvars'"
    return local  threshvar "`threshvar'"
    return local  cmd      "tvtpredreg"
end
