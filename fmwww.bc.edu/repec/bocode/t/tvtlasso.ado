*! tvtlasso 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Weighted LASSO for a HIGH-DIMENSIONAL threshold regression whose
*! threshold is a Fourier function of time. Selects covariates and
*! distinguishes a linear model from a threshold model.
*!
*! Yang, L. (2024) "High dimensional threshold model with a time-varying
*!   threshold based on Fourier approximation", Studies in Nonlinear
*!   Dynamics & Econometrics 28(1):83-117, doi:10.1515/snde-2021-0047
*!
*! Clean-room; the paper ships no code. See
*! validation/tvthresh/tvtlasso_equation_map.md.

program define tvtlasso, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtlasso" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric fv min=2) [if] [in] ,    ///
        THReshvar(varname numeric)                  ///
        [ LAMBDA(real -1)                           ///
          TRIM(real 0.15)                           ///
          GSTEP(real 0.1)                           ///
          KGRid(numlist integer >0 sort)            ///
          noFOURier                                 ///
          noTHRESHolded                             ///
          CGRid(numlist min=3 max=3)                ///
          ITerate(integer 2)                        ///
          NPath(integer 100)                        ///
          LRatio(real 0.001)                        ///
          MAXIter(integer 10000)                    ///
          TOLerance(real 1e-7)                      ///
          noCONStant                                ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        display as error "the paper uses 0.15, which is the default"
        exit 198
    }
    if `gstep' <= 0 {
        display as error "{bf:gstep()} must be positive"
        exit 198
    }
    if `iterate' < 1 {
        display as error "{bf:iterate()} must be at least 1"
        exit 198
    }
    if `npath' < 5 {
        display as error "{bf:npath()} must be at least 5"
        exit 198
    }
    if `lratio' <= 0 | `lratio' >= 1 {
        display as error "{bf:lratio()} must be in (0, 1)"
        exit 198
    }
    if `maxiter' < 10 {
        display as error "{bf:maxiter()} must be at least 10"
        exit 198
    }
    if `tolerance' <= 0 {
        display as error "{bf:tolerance()} must be positive"
        exit 198
    }

    if "`kgrid'" == "" local kgrid 1 2 3 4 5
    if "`cgrid'" == "" local cgrid 0.1 5 0.1
    local clo   : word 1 of `cgrid'
    local chi   : word 2 of `cgrid'
    local cstep : word 3 of `cgrid'
    if `clo' <= 0 | `chi' <= `clo' | `cstep' <= 0 {
        display as error "{bf:cgrid(}{it:lo hi step}{bf:)} needs" ///
            " 0 < lo < hi and step > 0"
        display as error "the paper uses 0.1 5 0.1, which is the default"
        exit 198
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is the threshold variable and" ///
                " cannot also be a regressor"
            exit 198
        }
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar'
    quietly count if `touse'
    local nobs = r(N)

    local m : word count `xvars'
    if `nobs' < 10 {
        display as error "too few observations (`nobs')"
        exit 2001
    }
    if `m' < 1 {
        display as error "at least one regressor is required"
        exit 198
    }

    local qvar "`threshvar'"
    local noconstant "`constant'"
    _tvt_drop

    mata: tvt_lasso()

    if __tvt_la_fail == 1 {
        _tvt_drop
        display as error "no admissible split was found"
        display as error "every point of the threshold grid left a regime" ///
            " below the minimum size."
        display as error "Widen {bf:trim()}, or check that" ///
            " `threshvar' actually varies."
        exit 498
    }

    tempname G0 G1 G2 KK LAM LAM0 HH CC CRIT SSR MSE DF DFT N1 N2
    tempname NVIS NSKIP NDET MINN
    scalar `G0'   = __tvt_la_g0
    scalar `G1'   = __tvt_la_g1
    scalar `G2'   = __tvt_la_g2
    scalar `KK'   = __tvt_la_k
    scalar `LAM'  = __tvt_la_lam
    scalar `LAM0' = __tvt_la_lam0
    scalar `HH'   = __tvt_la_h
    scalar `CC'   = __tvt_la_c
    scalar `CRIT' = __tvt_la_crit
    scalar `SSR'  = __tvt_la_ssr
    scalar `MSE'  = __tvt_la_mse
    scalar `DF'   = __tvt_la_df
    scalar `DFT'  = __tvt_la_dft
    scalar `N1'   = __tvt_la_n1
    scalar `N2'   = __tvt_la_n2
    scalar `NVIS' = __tvt_la_nvis
    scalar `NSKIP' = __tvt_la_nskip
    scalar `NDET' = __tvt_la_ndet
    scalar `MINN' = __tvt_la_minn
    local lamauto = __tvt_la_lamauto
    tempname BM BWL SELM SELWL PM
    matrix `BM'    = __tvt_la_b
    matrix `BWL'   = __tvt_la_bwl
    matrix `SELM'  = __tvt_la_sel
    matrix `SELWL' = __tvt_la_selwl
    matrix `PM'    = __tvt_la_path
    _tvt_drop

    * -------------------------------------------------------- the names
    local nm
    foreach v of local xvars {
        local nm `nm' level:`v'
    }
    foreach v of local xvars {
        local nm `nm' shift:`v'
    }
    foreach M in `BM' `BWL' `SELM' `SELWL' {
        matrix colnames `M' = `nm'
    }

    * No covariance is reported -- see the note at the end of Display --
    * but ereturn post requires one, and it must carry the SAME names as
    * b or Stata answers "name conflict", r(507).
    tempname VM
    local k = colsof(`BM')
    matrix `VM' = J(`k', `k', 0)
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    local nused = `nobs'
    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nused')
    ereturn scalar N          = `nobs'
    ereturn scalar m           = `m'
    ereturn scalar gamma0     = `G0'
    ereturn scalar gamma1     = `G1'
    ereturn scalar gamma2     = `G2'
    ereturn scalar k          = `KK'
    ereturn scalar lambda     = `LAM'
    ereturn scalar lambda_pilot = `LAM0'
    ereturn scalar lambda_auto = `lamauto'
    ereturn scalar H          = `HH'
    ereturn scalar C          = `CC'
    ereturn scalar crit       = `CRIT'
    ereturn scalar ssr        = `SSR'
    ereturn scalar mse        = `MSE'
    ereturn scalar df_wl      = `DF'
    ereturn scalar df_th      = `DFT'
    ereturn scalar N_lower    = `N1'
    ereturn scalar N_upper    = `N2'
    ereturn scalar n_visited  = `NVIS'
    ereturn scalar n_skipped  = `NSKIP'
    ereturn scalar k_shift    = `NDET'
    ereturn scalar minreg     = `MINN'
    ereturn scalar trim       = `trim'
    ereturn scalar gstep      = `gstep'
    ereturn local  cmd        "tvtlasso"
    ereturn local  cmdline    "tvtlasso `0'"
    ereturn local  depvar     "`depv'"
    ereturn local  indepvars  "`xvars'"
    ereturn local  threshvar  "`threshvar'"
    ereturn local  kgrid      "`kgrid'"
    ereturn local  estimator  "thresholded LASSO"
    if "`thresholded'" == "nothresholded" {
        ereturn local estimator "weighted LASSO"
    }
    ereturn local  fourier    "`=cond("`fourier'"=="nofourier","constant","Fourier")'"
    ereturn local  title      "High-dimensional threshold LASSO, time-varying threshold"
    ereturn matrix b_wl       = `BWL'
    ereturn matrix selected   = `SELM'
    ereturn matrix selected_wl = `SELWL'
    ereturn matrix path       = `PM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    tempname SEL B
    matrix `SEL' = e(selected)
    matrix `B'   = e(b)
    local xv "`e(indepvars)'"
    local m  = e(m)

    display ""
    display as text "`e(title)'" ///
        _col(56) "Number of obs" _col(72) "=" _col(75) as result %8.0fc e(N)
    display as text "Yang (2024), SNDE 28(1)" ///
        _col(56) as text "Candidates 2m" _col(72) "=" ///
        _col(75) as result %8.0fc `=2*`m''
    display as text "Threshold variable: " as result "`e(threshvar)'" ///
        _col(56) as text "Terms retained" _col(72) "=" ///
        _col(75) as result %8.0f e(df_th)
    display as text "Estimator: " as result "`e(estimator)'" ///
        _col(56) as text "Models fitted" _col(72) "=" ///
        _col(75) as result %8.0fc e(n_visited)
    display ""
    display as text "{hline 82}"
    display as text "  THE THRESHOLD" _col(40) "(" as result ///
        "`e(fourier)'" as text ")"
    if "`e(fourier)'" == "Fourier" {
        local eq = "    gamma(t) = " + string(e(gamma0), "%9.0g")
        local s1 = cond(e(gamma1) < 0, " - ", " + ")
        local s2 = cond(e(gamma2) < 0, " - ", " + ")
        local eq = "`eq'" + "`s1'" + string(abs(e(gamma1)), "%9.0g") ///
            + " sin(2*pi*" + string(e(k), "%9.0g") + "*t/T)"
        local eq = "`eq'" + "`s2'" + string(abs(e(gamma2)), "%9.0g") ///
            + " cos(2*pi*" + string(e(k), "%9.0g") + "*t/T)"
        display as text "`eq'"
        display as text "    frequency k" _col(26) as result %12.0f e(k) ///
            as text "   searched over " as result "`e(kgrid)'"
    }
    else {
        display as text "    gamma(t) = " as result %9.0g e(gamma0) ///
            as text "  (constant; {bf:nofourier} was specified)"
    }
    display as text "    observations below / above" _col(36) as result ///
        %7.0f e(N_lower) as text " /" as result %7.0f e(N_upper)
    display as text "{hline 82}"
    display as text "  RETAINED TERMS"
    display as text "    " %-24s "variable" _col(34) "level" _col(50) "shift"
    local any 0
    forvalues i = 1/`m' {
        local vi : word `i' of `xv'
        local bl = `B'[1,`i']
        local bs = `B'[1,`=`i'+`m'']
        if `bl' != 0 | `bs' != 0 {
            local any 1
            display as text "    " %-24s "`vi'" _col(30) as result ///
                %12.4f `bl' _col(46) %12.4f `bs'
        }
    }
    if !`any' {
        display as text "    nothing was retained: every coefficient was" ///
            " shrunk to zero"
    }
    display as text "{hline 82}"
    if e(k_shift) > 0 {
        display as text "  THRESHOLD EFFECT: " as result e(k_shift) ///
            as text " of the retained terms SHIFT between regimes,"
        display as text "  so this is a threshold model, not a linear one."
    }
    else {
        display as text "  NO THRESHOLD EFFECT: not one shift term" ///
            " survived selection, so the"
        display as text "  evidence here is for a LINEAR model. The" ///
            " threshold above is then not"
        display as text "  interpretable -- nothing switches at it."
    }
    display as text "{hline 82}"
    display as text "  lambda" _col(22) as result %14.8f e(lambda) ///
        cond(e(lambda_auto), " (BIC)", " (given)") ///
        as text _col(50) "H = C*lambda" _col(66) as result %12.6f e(H)
    display as text "  C (by BIC)" _col(22) as result %14.4f e(C) ///
        as text _col(50) "SSR/T" _col(66) as result %12.6f e(mse)
    display as text "{hline 82}"
    display as text "  {bf:NO standard errors are reported.} They would" ///
        " be conditional on the"
    display as text "  selection and would ignore it, which is the" ///
        " standard objection to"
    display as text "  post-selection inference. The paper derives" ///
        " oracle inequalities and"
    display as text "  selection consistency, not a post-selection" ///
        " distribution, and neither"
    display as text "  does this command. Refit the retained" ///
        " specification with {helpb tvtfourier}"
    display as text "  on independent data if you need inference."
end
