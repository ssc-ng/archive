*! tvtlatent 1.0.0  14oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold model whose threshold is a LATENT AR(1) process, estimated by
*! MCMC under a Bayesian framework.
*!
*! This is the one family in TVTHRESH where the threshold is not a
*! function of anything observed. It is an unobserved state with an
*! autoregression of its own, so the whole path is a parameter and there
*! is no profile likelihood to maximise over a grid.
*!
*! Zhu, Y., H. Chen and M. Lin (2018) Studies in Nonlinear Dynamics &
*!   Econometrics 23(5), article 20170114, doi:10.1515/snde-2017-0114
*!   (DOI verified via Crossref 2026-10-14; the journal gives an article
*!    number, not page numbers.)
*!
*! Clean-room. The authors' MATLAB carries NO licence, so it was read and
*! run only, never copied; it was run to produce the numerical reference
*! lock. Two defects in their phi step are corrected here and declared.
*! See validation/tvthresh/tvtlatent_equation_map.md.

program define tvtlatent, eclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] ,     ///
        THReshvar(varname numeric ts)                   ///
        [ MCMCreps(integer 20000)                       ///
          BURNin(integer 10000)                         ///
          THIN(integer 1)                               ///
          TRIM(real 0.1)                                ///
          SEED(string)                                  ///
          AU(real 2) BU(real 2)                         ///
          AE(real 2) BE(real 2)                         ///
          PHIA(real 1) PHIB(real 1)                     ///
          MUMean(real 0) MUVar(real 1000)               ///
          noCONStant                                    ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    * The latent threshold is an AR(1) IN TIME, so the order of the
    * observations is part of the model, not a presentation choice.
    capture quietly tsset
    if _rc {
        display as error "the data must be {bf:tsset}"
        display as error ""
        display as error "The threshold here follows an autoregression" ///
            " in TIME, so the order of"
        display as error "the observations is part of the model. Use" ///
            " {helpb tvtboundary} or"
        display as error "{helpb tvtindex} if your data are" ///
            " cross-sectional."
        exit 459
    }
    local tvar "`r(timevar)'"

    if `burnin' >= `mcmcreps' {
        display as error "{bf:burnin()} must be less than {bf:mcmcreps()}"
        exit 198
    }
    if `thin' < 1 {
        display as error "{bf:thin()} must be at least 1"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `mcmcreps' < 500 {
        display as error "{bf:mcmcreps()} must be at least 500"
        exit 198
    }
    if `au' <= 0 | `bu' <= 0 | `ae' <= 0 | `be' <= 0 {
        display as error "the inverse-gamma prior parameters" ///
            " {bf:au() bu() ae() be()} must be positive"
        exit 198
    }
    if `phia' <= 0 | `phib' <= 0 {
        display as error "{bf:phia()} and {bf:phib()} must be positive"
        exit 198
    }
    if `muvar' <= 0 {
        display as error "{bf:muvar()} must be positive"
        exit 198
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is the threshold variable" ///
                " and cannot also be a regressor"
            exit 198
        }
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        display as error "too few observations (`nobs')"
        display as error "a latent path needs enough observations to be" ///
            " identified at all"
        exit 2001
    }

    * the sample must be a single unbroken stretch: a gap in time is a
    * gap in the AR(1), and silently treating it as contiguous would
    * misdate every threshold after it
    tempvar seq
    quietly generate long `seq' = `tvar' if `touse'
    quietly summarize `seq', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin' + 1) != `nobs' {
        display as error "the estimation sample has gaps in `tvar'"
        display as error ""
        display as error "The threshold follows an AR(1) in time, so a" ///
            " gap is not simply a"
        display as error "missing row: the state continues to evolve" ///
            " across it. Restrict to an"
        display as error "unbroken stretch with {bf:if}, or fill the gaps."
        exit 198
    }

    local qvar "`threshvar'"
    local hascons = 1
    if "`constant'" != "" local hascons = 0
    if `hascons' == 0 & "`xvars'" == "" {
        display as error "{bf:noconstant} with no regressors leaves" ///
            " nothing to estimate"
        exit 198
    }

    if "`seed'" != "" set seed `seed'

    capture matrix drop __tvt_lat_draws
    capture matrix drop __tvt_lat_path
    capture scalar drop __tvt_lat_fail
    mata: tvt_latent()

    if __tvt_lat_fail != 0 {
        local fc = __tvt_lat_fail
        capture scalar drop __tvt_lat_fail
        if `fc' == 1 {
            display as error "the starting constant-threshold fit failed"
            display as error "No split in the trimmed range left both" ///
                " regimes able to support"
            display as error "the regression. Widen {bf:trim()}, or" ///
                " check for collinearity."
            exit 498
        }
        if `fc' == 2 {
            display as error "{bf:thin()} leaves no draws after" ///
                " {bf:burnin()}"
            exit 198
        }
        display as error "the sampler did not produce usable draws"
        exit 498
    }

    tempname DR PATH b V
    matrix `DR'   = __tvt_lat_draws
    matrix `PATH' = __tvt_lat_path
    local n     = __tvt_lat_n
    local p     = __tvt_lat_p
    local kept  = __tvt_lat_kept
    local gstar = __tvt_lat_gstar
    local ngrid = __tvt_lat_ngrid
    local accg  = __tvt_lat_accg
    local accp  = __tvt_lat_accp
    capture scalar drop __tvt_lat_fail
    capture matrix drop __tvt_lat_draws
    capture matrix drop __tvt_lat_path

    * ---- names for the draws, in the order the engine stacked them
    local nm ""
    local xn "`xvars'"
    if `hascons' local xn "`xvars' _cons"
    foreach v of local xn {
        local nm "`nm' r1:`v'"
    }
    foreach v of local xn {
        local nm "`nm' r2:`v'"
    }
    local nm "`nm' thr:mu thr:phi thr:sigma2_u var:sigma2_1 var:sigma2_2"
    matrix colnames `DR' = `nm'

    * ---- posterior mean and variance become e(b) and e(V)
    quietly {
        tempname M S
        matrix `M' = J(1, colsof(`DR'), 0)
        forvalues j = 1/`=colsof(`DR')' {
            mata: st_matrix("`S'", mean(st_matrix("`DR'")[., `j']))
            matrix `M'[1, `j'] = `S'[1,1]
        }
        mata: st_matrix("`V'", variance(st_matrix("`DR'")))
    }
    matrix `b' = `M'
    matrix colnames `b' = `nm'
    matrix colnames `V' = `nm'
    matrix rownames `V' = `nm'

    * ---- HPD intervals for the table
    tempname LO HI
    matrix `LO' = J(1, colsof(`DR'), .)
    matrix `HI' = J(1, colsof(`DR'), .)
    forvalues j = 1/`=colsof(`DR')' {
        mata: __lo = .; __hi = .
        mata: tvt_lat_hpd(st_matrix("`DR'")[., `j'], `level'/100, __lo, __hi)
        mata: st_numscalar("__tlo", __lo); st_numscalar("__thi", __hi)
        matrix `LO'[1, `j'] = __tlo
        matrix `HI'[1, `j'] = __thi
    }
    capture scalar drop __tlo
    capture scalar drop __thi

    * ------------------------------------------------------------ output
    display ""
    display as text "Threshold model with a LATENT (AR(1)) threshold" ///
        _col(56) "Obs" _col(68) "=" _col(71) as result %9.0fc `n'
    display as text "Zhu, Chen and Lin (2018), SNDE 23(5)" ///
        _col(56) "Draws kept" _col(68) "=" _col(71) as result %9.0fc `kept'
    display as text "{hline 78}"
    display as text "  The threshold is NOT a function of anything" ///
        " observed. It is a latent"
    display as text "  state: {bf:g(t) = mu + phi*(g(t-1) - mu) + u(t)}," ///
        " u ~ N(0, sigma2_u)."
    display as text "{hline 78}"

    local K = colsof(`DR')
    display as text %-22s "parameter" %12s "post. mean" %12s "post. sd" ///
        %11s "[`level'% HPD" %11s "interval]"
    display as text "{hline 78}"
    forvalues j = 1/`K' {
        local nmj : word `j' of `nm'
        local sdj = sqrt(`V'[`j',`j'])
        display as text %-22s "`nmj'" as result ///
            %12.4f `b'[1,`j'] %12.4f `sdj' ///
            %11.4f `LO'[1,`j'] %11.4f `HI'[1,`j']
    }
    display as text "{hline 78}"
    display as text "  constant-threshold start" _col(34) as result ///
        %12.4f `gstar' as text "   (grid of `ngrid' candidates)"
    display as text "  acceptance rate, threshold path" _col(34) ///
        as result %12.3f `accg'
    display as text "  acceptance rate, phi" _col(34) ///
        as result %12.3f `accp'
    display as text "{hline 78}"
    display as text "  {bf:phi} near 1 means the threshold wanders" ///
        " rather than reverting;"
    display as text "  {bf:sigma2_u} near 0 means it barely moves, and a" ///
        " constant-threshold model"
    display as text "  would do. Compare the path with {helpb tvtplot}" ///
        " before reading the slopes."
    display as text "{hline 78}"

    * ----------------------------------------------------------- returns
    ereturn post `b' `V', depname("`depv'") obs(`n') esample(`touse')
    ereturn matrix path     = `PATH'
    ereturn matrix hpd_lo   = `LO'
    ereturn matrix hpd_hi   = `HI'
    ereturn matrix draws    = `DR'
    ereturn scalar N        = `n'
    ereturn scalar k_regr   = `p'
    ereturn scalar mcmcreps = `mcmcreps'
    ereturn scalar burnin   = `burnin'
    ereturn scalar thin     = `thin'
    ereturn scalar kept     = `kept'
    ereturn scalar level    = `level'
    ereturn scalar trim     = `trim'
    ereturn scalar gamma_ct = `gstar'
    ereturn scalar n_grid   = `ngrid'
    ereturn scalar acc_path = `accg'
    ereturn scalar acc_phi  = `accp'
    ereturn local  threshvar "`threshvar'"
    ereturn local  indepvars "`xvars'"
    ereturn local  timevar   "`tvar'"
    ereturn local  title     "Threshold model with a latent AR(1) threshold"
    ereturn local  cmd       "tvtlatent"
end
