*! thtvecm 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Two-regime threshold vector error correction model, with the Hansen-Seo
*! SupLM test of a linear VECM against a threshold VECM.
*! Hansen & Seo (2002) JoE 110:293-318, doi:10.1016/S0304-4076(02)00097-0
*! Seo (2006) JoE 134:129-150, doi:10.1016/j.jeconom.2005.06.018
*! Seo (2007) LSE STICERD EM/2007/517 (the n^(3/2) rate that justifies two-step)
*! Balke & Fomby (1997) IER 38:627-645, doi:10.2307/2527284

program define thtvecm, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thtvecm" error 301
        Display
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] , ///
        [ LAGS(integer 1)                        ///
          BETA(numlist)                          ///
          JOINTbeta                              ///
          TRIM(real 0.15)                        ///
          GRIDn(integer 0)                       ///
          MINOBS(integer 0)                      ///
          noCONStant                             ///
          TEST                                   ///
          STAT(string)                           ///
          REPS(integer 500)                      ///
          BOOT(string)                           ///
          SEED(string)                           ///
          NTHresh(integer 1)                     ///
          RESTrict(string)                       ///
          SLS                                    ///
          BWscale(real 1)                        ///
          Level(cilevel) ]

    capture tsset
    if _rc {
        display as error "{bf:thtvecm} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `lags' < 0 {
        display as error "{bf:lags()} must be 0 or more"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if "`stat'" == "" local stat sup
    local statnum = .
    if "`stat'" == "sup" local statnum 1
    if "`stat'" == "ave" local statnum 2
    if "`stat'" == "exp" local statnum 3
    if `statnum' == . {
        display as error "stat() must be sup, ave or exp"
        exit 198
    }
    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "wild") {
        display as error "boot() must be resample or wild"
        exit 198
    }
    local boottype `boot'
    local dotest    = cond("`test'"!="", 1, 0)
    local hascons   = cond("`constant'"=="", 1, 0)
    local jointbeta = cond("`jointbeta'"!="", 1, 0)
    if "`seed'" != "" set seed `seed'

    * ------------------------------------------------ the extension modes
    if !inlist(`nthresh', 1, 2) {
        display as error "{bf:nthresh()} must be 1 or 2"
        display as error "two thresholds give the three-regime BAND model of"
        display as error "Lo and Zivot (2001): a middle band plus an outer"
        display as error "regime on each side"
        exit 198
    }
    if "`restrict'" == "" local restrict none
    local restrict = lower("`restrict'")
    if !inlist("`restrict'", "none", "band", "equal") {
        display as error "{bf:restrict()} must be none, band or equal"
        exit 198
    }
    if "`restrict'" != "none" & `nthresh' == 1 {
        display as error "{bf:restrict(`restrict')} needs {bf:nthresh(2)}:"
        display as error "both restrictions are statements about the MIDDLE"
        display as error "regime of a three-regime model"
        exit 198
    }
    local restrictn = cond("`restrict'"=="none", 0, ///
                      cond("`restrict'"=="band", 1, 2))
    local dosls = cond("`sls'"!="", 1, 0)
    if `dosls' & `nthresh' == 2 {
        display as error "{bf:sls} and {bf:nthresh(2)} cannot be combined:"
        display as error "Seo's smoothed least squares is derived for the"
        display as error "two-regime model, and smoothing two thresholds at"
        display as error "once is not what the paper establishes"
        exit 198
    }
    if `dosls' & `jointbeta' {
        display as error "{bf:sls} already searches over the threshold with a"
        display as error "differentiable criterion; combining it with"
        display as error "{bf:jointbeta} is not implemented"
        exit 198
    }
    if `bwscale' <= 0 {
        display as error "{bf:bwscale()} must be positive"
        exit 198
    }
    if `dosls' & "`test'" != "" {
        display as error "{bf:test} is the Hansen-Seo sup-LM test, which is"
        display as error "derived for the SHARP indicator. It is not valid for"
        display as error "the smoothed fit, so the two cannot be combined."
        display as error "Fit without {bf:sls} for the test, and with it for"
        display as error "the slope standard errors."
        exit 198
    }
    * The three-regime search is over every ORDERED PAIR on the grid, so its
    * cost is quadratic in the number of grid points: a 700-point grid is a
    * quarter of a million fits. An uncapped grid is every distinct value of
    * w, which on a long series is pointless resolution for a band model --
    * the two thresholds are not identified to within one observation. So
    * nthresh(2) caps the grid at 100 points unless the user sets gridn()
    * explicitly, and says so, rather than being silently slow.
    if `nthresh' == 2 & `gridn' == 0 {
        local gridn 100
        local gridauto 1
    }
    else local gridauto 0

    local mode2 = cond(`nthresh' == 2, 1, cond(`dosls', 2, 0))
    local bwscalen = `bwscale'

    local yvars `varlist'
    local k : word count `yvars'

    * The joint beta-gamma search is coded for a BIVARIATE system, where beta
    * normalises to (1, b)' and there is exactly one free element to put on a
    * grid. With three or more variables the engine's guard (rows(beta) == 2)
    * silently skips the search -- and because e(jointbeta) records the OPTION
    * rather than whether it was applied, the header went on printing "then
    * refined jointly with gamma" for a refinement that never ran. Refusing is
    * the only honest outcome: a claim in the output is worse than an error.
    * (`jointbeta' is already 0/1 by here: it was reduced above, so test it
    * numerically. "`jointbeta'" != "" would be true for BOTH values.)
    if `jointbeta' & `k' != 2 {
        display as error "{bf:jointbeta} needs a {bf:bivariate} system."
        display as error "With `k' variables the cointegrating vector has"
        display as error "`=`k'-1' free elements after normalisation, and the"
        display as error "joint search is implemented for the single free"
        display as error "element of the bivariate case (Hansen and Seo 2002)."
        display as error "Either drop {bf:jointbeta} and supply the vector with"
        display as error "{bf:beta()}, or fit the bivariate system."
        exit 198
    }

    marksample touse
    markout `touse' `yvars'

    * ---- differences, lagged levels, lagged differences
    local dvars ""
    local levelvars ""
    local dlagvars ""
    local dnames ""
    local dlagnames ""
    foreach v of local yvars {
        tempvar d_`v' l_`v'
        quietly generate double `d_`v'' = D.`v' if `touse'
        quietly generate double `l_`v'' = L.`v' if `touse'
        local dvars `dvars' `d_`v''
        local levelvars `levelvars' `l_`v''
        local dnames `dnames' D.`v'
    }
    forvalues j = 1/`lags' {
        foreach v of local yvars {
            tempvar dl`j'_`v'
            quietly generate double `dl`j'_`v'' = L`j'.D.`v' if `touse'
            local dlagvars `dlagvars' `dl`j'_`v''
            local dlagnames `dlagnames' LD`j'.`v'
        }
    }
    markout `touse' `dvars' `levelvars' `dlagvars'

    * ---- the cointegrating vector: user-supplied, or from the linear VECM
    if "`beta'" == "" {
        quietly vec `yvars' if `touse', lags(`=`lags'+1') rank(1) noetable
        tempname BE
        matrix `BE' = e(beta)
        local betavec ""
        local b1 = `BE'[1,1]
        forvalues j = 1/`k' {
            local bj = `BE'[1,`j']/`b1'
            local betavec `betavec' `bj'
        }
        local betasrc "linear VECM (Johansen, rank 1)"
    }
    else {
        local nb : word count `beta'
        if `nb' != `k' {
            display as error "beta() needs `k' numbers, one per variable"
            exit 198
        }
        local betavec "`beta'"
        local betasrc "user supplied"
    }

    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

    if `mode2' != 0 {
        Fit2 , mode2(`mode2') restrictn(`restrictn') bwscalen(`bwscalen')  ///
            nthresh(`nthresh') restrict(`restrict') sls(`dosls')           ///
            touse(`touse') yvars(`yvars') dvars(`dvars')                   ///
            levelvars(`levelvars') dlagvars(`dlagvars')                    ///
            betavec(`betavec') betasrc(`betasrc') hascons(`hascons')       ///
            trim(`trim') gridn(`gridn') minobs(`minobs') lags(`lags')      ///
            level(`level') nobs(`nobs') timevar(`timevar')                 ///
            dlagnames(`dlagnames') cmdline(`0') gridauto(`gridauto')
        exit
    }

    mata: tk_thtvecm()

    * ---- coefficient names: 2 regimes x k equations
    local wnames ""
    if `hascons' local wnames _cons
    local wnames `wnames' ec
    local wnames `wnames' `dlagnames'
    local cn ""
    local ce ""
    forvalues r = 1/2 {
        foreach dv of local yvars {
            foreach w of local wnames {
                local cn `cn' `w'
                local ce `ce' R`r'_D_`dv'
            }
        }
    }

    tempname b V
    matrix `b' = __tk_b
    matrix `V' = __tk_V
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    ereturn post `b' `V', esample(`touse') obs(`nobs')

    ereturn local cmd        "thtvecm"
    ereturn local cmdline    "thtvecm `0'"
    ereturn local title      "Threshold vector error correction model"
    ereturn local model      "tvecm"
    ereturn local estimator  "regime-wise least squares, concentrated ln|Sigma|"
    ereturn local depvars    "`yvars'"
    ereturn local beta_src   "`betasrc'"
    ereturn local threshold_var "error-correction term"
    ereturn local timevar    "`timevar'"
    ereturn local properties "b V"
    ereturn local estat_cmd  "thtvecm_estat"
    ereturn local predict    "thtvecm_p"
    ereturn local wnames     "`wnames'"
    ereturn local dlagnames  "`dlagnames'"

    ereturn scalar N         = __tk_n
    ereturn scalar k_eq      = 2 * `k'
    ereturn scalar k_var     = __tk_k
    ereturn scalar lags      = `lags'
    ereturn scalar gamma     = __tk_gamma
    ereturn scalar N_regime1 = __tk_n1
    ereturn scalar N_regime2 = __tk_n2
    ereturn scalar lndet     = __tk_lndet
    ereturn scalar lndet0    = __tk_lndet0
    ereturn scalar ll        = __tk_ll
    ereturn scalar ll_0      = __tk_ll0
    ereturn scalar trim      = `trim'
    ereturn scalar level     = `level'
    ereturn scalar jointbeta = `jointbeta'
    ereturn scalar hascons   = `hascons'
    if `dotest' {
        ereturn scalar lm        = __tk_lm
        ereturn scalar lm_sup    = __tk_lmsup
        ereturn scalar lm_ave    = __tk_lmave
        ereturn scalar lm_exp    = __tk_lmexp
        ereturn scalar gamma_test = __tk_gmax
        ereturn scalar p         = __tk_p
        ereturn scalar p_mcse    = sqrt(__tk_p*(1-__tk_p)/`reps')
        ereturn scalar boot_reps = `reps'
        ereturn local  teststat  "`stat'"
        ereturn local  boot      "`boot'"
        capture ereturn matrix bdist = __tk_bdist
    }
    tempname M
    matrix `M' = __tk_beta
    matrix colnames `M' = `yvars'
    ereturn matrix beta = `M'
    matrix `M' = __tk_sigma
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `yvars'
    ereturn matrix Sigma = `M'
    matrix `M' = __tk_a2
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `wnames'
    ereturn matrix A2 = `M'
    matrix `M' = __tk_a1
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `wnames'
    ereturn matrix A1 = `M'

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    local g : display %10.0g e(gamma)
    local g = trim("`g'")
    tempname BE
    matrix `BE' = e(beta)
    local bstr ""
    forvalues j = 1/`=colsof(`BE')' {
        local bj : display %7.4f `BE'[1,`j']
        local bstr "`bstr' `=trim("`bj'")'"
    }
    display ""
    display as text "Threshold vector error correction model" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Variables: " as result "`e(depvars)'" _col(52) ///
        as text "Lags of D" _col(68) "=" _col(71) as result %9.0f e(lags)
    display as text "  Cointegrating vector: " as result "`bstr'" _col(52) ///
        as text "ln|Sigma|" _col(68) "=" _col(71) as result %9.5f e(lndet)
    display as text "  beta from: " as result "`e(beta_src)'" ///
        cond(e(jointbeta)==1, " then refined jointly with gamma", "")
    display ""
    display as text "{hline 78}"
    display as text "  Threshold on the error-correction term" _col(44) ///
        as result %14s "`g'"
    display as text "  Observations: regime 1" _col(44) as result %14.0fc e(N_regime1)
    display as text "                regime 2" _col(44) as result %14.0fc e(N_regime2)
    display as text "  ln|Sigma| of the linear VECM" _col(44) as result %14.5f e(lndet0)
    display as text "{hline 78}"
    if e(p) < . {
        display as text "  Hansen-Seo test: linear VECM against a threshold VECM"
        display as text "     `e(teststat)'-LM" _col(28) as result %14.4f e(lm) ///
            as text _col(48) "argmax at " as result %9.0g e(gamma_test)
        display as text "     bootstrap p" _col(28) as result %14.4f e(p) ///
            as text _col(48) "`e(boot_reps)' reps, MC s.e. " %5.4f e(p_mcse)
        display as text "     sup / ave / exp" _col(28) as result ///
            %8.3f e(lm_sup) " " %8.3f e(lm_ave) " " %8.3f e(lm_exp)
        display as text "{hline 78}"
        display as text "  The LM statistic compares the two regimes' coefficient matrices"
        display as text "  with the covariance taken from the LINEAR fit, as Hansen and Seo"
        display as text "  (2002) specify. The threshold is unidentified under H0, so the"
        display as text "  p-value is simulated with the design held fixed (`e(boot)')."
    }
    display ""
    display as text "  {bf:ec} is the error-correction term; its coefficient is the speed of"
    display as text "  adjustment in that regime. Seo (2007) shows the cointegrating vector"
    display as text "  converges at n^(3/2) here, so treating beta as known costs little."
    display ""
    _coef_table, level(`=e(level)')
end

* ----------------------------------------------------------------------
* Fit2 -- the three-regime (band) model and the smoothed-least-squares
* fit. Both are posted here rather than in the main body because their
* coefficient vector has a different shape: three blocks instead of two,
* possibly with the middle block's error-correction term removed.
program define Fit2, eclass
    version 15
    syntax , mode2(integer) restrictn(integer) bwscalen(real)        ///
             nthresh(integer) sls(integer) touse(string)             ///
             yvars(string) dvars(string) levelvars(string)           ///
             hascons(integer) trim(real) gridn(integer)              ///
             minobs(integer) lags(integer) level(integer)            ///
             nobs(integer) betavec(string) betasrc(string)           ///
             [ restrict(string) dlagvars(string) dlagnames(string)   ///
               timevar(string) cmdline(string) GRIDAUTO(integer 0) ]

    local k : word count `yvars'

    mata: tk_thtvecm2()

    if __tk_t2fail == 1 {
        _tk_drop
        display as error "the trimmed threshold grid has fewer than 3 points:"
        display as error "either {bf:trim()} is too large or the sample is too"
        display as error "short for a threshold search"
        exit 498
    }
    if __tk_t2fail == 2 {
        _tk_drop
        display as error "no admissible pair of thresholds: every (g1, g2) on"
        display as error "the grid leaves one of the THREE regimes with too"
        display as error "few observations. A three-regime model needs a much"
        display as error "longer series than a two-regime one; lower"
        display as error "{bf:trim()} or fit {bf:nthresh(1)}."
        exit 498
    }
    if __tk_t2fail == 3 {
        _tk_drop
        display as error "the smoothed criterion could not be minimised over"
        display as error "the threshold grid; try a larger {bf:bwscale()}"
        exit 498
    }

    * ---- the names. vec(A) is EQUATION-major, and within an equation the
    *      regressor blocks run in the order tk_tv3_split builds them, so the
    *      loops here must be equation OUTER and block INNER.
    local wnames ""
    if `hascons' local wnames _cons
    local wnames `wnames' ec
    local wnames `wnames' `dlagnames'

    if `mode2' == 1 {
        if `restrictn' == 2  local blocks "Outer Middle"
        else                 local blocks "Low Middle High"
    }
    else local blocks "R1 R2"

    local cn ""
    local ce ""
    foreach dv of local yvars {
        foreach bl of local blocks {
            foreach w of local wnames {
                * the band restriction removes the MIDDLE regime's
                * error-correction term: that is the restriction itself, not a
                * display convention, so the name must go too
                if `restrictn' == 1 & "`bl'" == "Middle" & "`w'" == "ec" ///
                    continue
                local cn `cn' `w'
                local ce `ce' `bl'_D_`dv'
            }
        }
    }

    tempname b V
    matrix `b' = __tk_t2b
    matrix `V' = __tk_t2V
    local ncol = colsof(`b')
    local nnm  : word count `cn'
    if `ncol' != `nnm' {
        _tk_drop
        display as error "internal: `ncol' coefficients but `nnm' names"
        exit 498
    }
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    ereturn post `b' `V', esample(`touse') obs(`nobs')

    ereturn local cmd        "thtvecm"
    ereturn local cmdline    "thtvecm `cmdline'"
    ereturn local depvars    "`yvars'"
    ereturn local beta_src   "`betasrc'"
    ereturn local threshold_var "error-correction term"
    ereturn local timevar    "`timevar'"
    ereturn local properties "b V"
    ereturn local estat_cmd  "thtvecm_estat"
    ereturn local predict    "thtvecm_p"
    ereturn local wnames     "`wnames'"
    ereturn local dlagnames  "`dlagnames'"
    ereturn local blocks     "`blocks'"

    ereturn scalar N       = __tk_t2n
    ereturn scalar k_var   = __tk_t2k
    ereturn scalar k_w     = __tk_t2kw
    ereturn scalar k_coef  = __tk_t2kz
    ereturn scalar lags    = `lags'
    ereturn scalar trim    = `trim'
    ereturn scalar level   = `level'
    ereturn scalar hascons = `hascons'
    ereturn scalar lndet   = __tk_t2ld
    ereturn scalar lndet0  = __tk_t2ld0
    ereturn scalar nthresh = `nthresh'
    ereturn scalar gridn   = `gridn'
    ereturn scalar grid_capped = `gridauto'

    tempname M
    matrix `M' = __tk_t2beta
    matrix colnames `M' = `yvars'
    ereturn matrix beta = `M'
    matrix `M' = __tk_t2Sig
    matrix colnames `M' = `yvars'
    matrix rownames `M' = `yvars'
    ereturn matrix Sigma = `M'

    if `mode2' == 1 {
        ereturn local  model     "tvecm3"
        ereturn local  title     "Three-regime threshold VECM"
        ereturn local  estimator "regime-wise least squares over an ordered threshold pair"
        ereturn local  restrict  "`restrict'"
        ereturn scalar gamma1    = __tk_t2g1
        ereturn scalar gamma2    = __tk_t2g2
        ereturn scalar gamma     = __tk_t2g1
        ereturn scalar N_regime1 = __tk_t2n1
        ereturn scalar N_regime2 = __tk_t2n2
        ereturn scalar N_regime3 = __tk_t2n3
        ereturn scalar n_cells   = __tk_t2ncell
        matrix `M' = __tk_t2grid
        matrix colnames `M' = gamma1 gamma2 lndet
        ereturn matrix grid3 = `M'
    }
    else {
        ereturn local  model     "tvecm_sls"
        ereturn local  title     "Threshold VECM, smoothed least squares"
        ereturn local  estimator "smoothed least squares (integrated normal kernel)"
        ereturn scalar gamma     = __tk_t2gam
        ereturn scalar bw        = __tk_t2bw
        ereturn scalar bwscale   = `bwscalen'
        ereturn scalar N_regime1 = __tk_t2n1
        ereturn scalar N_regime2 = __tk_t2n2
        matrix `M' = __tk_t2prof
        matrix colnames `M' = gamma lndet
        ereturn matrix profile = `M'
    }

    _tk_drop

    Display2
end

* ----------------------------------------------------------------------
program define Display2
    tempname BE
    matrix `BE' = e(beta)
    local k = colsof(`BE')
    local bnames : colnames `BE'
    local bstr ""
    forvalues j = 1/`k' {
        local c : word `j' of `bnames'
        local v : display %9.0g `BE'[1,`j']
        local v = trim("`v'")
        local bstr "`bstr' `v'*`c'"
    }

    display _n as text "`e(title)'" _col(56) "Number of obs = " ///
        as result %8.0f e(N)
    display as text "Cointegrating vector (`e(beta_src)'):" ///
        as result " `bstr'"

    if "`e(model)'" == "tvecm3" {
        local g1 : display %10.0g e(gamma1)
        local g2 : display %10.0g e(gamma2)
        local g1 = trim("`g1'")
        local g2 = trim("`g2'")
        display as text "Thresholds on w(t-1):  " as result "`g1'" ///
            as text "  and  " as result "`g2'"
        display as text "Regime sizes:  low " as result e(N_regime1) ///
            as text "   middle " as result e(N_regime2) ///
            as text "   high "  as result e(N_regime3) ///
            as text "   (of " as result e(N) as text ")"
        display as text "Admissible threshold pairs searched: " ///
            as result e(n_cells)
        if e(grid_capped) == 1 {
            display as text "  (the grid was capped at " as result e(gridn) ///
                as text " points, the default for nthresh(2):"
            display as text "   the search is over every ordered PAIR, so its"
            display as text "   cost is quadratic in the grid. Raise it with"
            display as text "   {bf:gridn()} if you need finer resolution --"
            display as text "   but two thresholds are not identified to"
            display as text "   within one observation anyway.)"
        }
        if "`e(restrict)'" == "band" {
            display _n as text "Restriction: {bf:band}. The middle regime's"
            display as text "error-correction coefficient is held at zero, so"
            display as text "inside the band the system does not adjust towards"
            display as text "the long-run relation at all and moves as a VAR in"
            display as text "differences. That is the Balke-Fomby band of"
            display as text "inaction, and it is a substantive restriction:"
            display as text "test it by comparing ln|Sigma| with the free fit"
            display as text "rather than assuming it."
        }
        else if "`e(restrict)'" == "equal" {
            display _n as text "Restriction: {bf:equal}. The two OUTER regimes"
            display as text "share one coefficient block, so adjustment is"
            display as text "symmetric above and below the band. Asymmetric"
            display as text "adjustment is the usual empirical finding, so this"
            display as text "too is a hypothesis, not a convenience."
        }
    }
    else {
        local gg : display %10.0g e(gamma)
        local bw : display %10.0g e(bw)
        local gg = trim("`gg'")
        local bw = trim("`bw'")
        display as text "Threshold on w(t-1): " as result "`gg'" ///
            as text "    bandwidth h = " as result "`bw'"
        display as text "Effective regime sizes (weight >= 0.5):  " ///
            as result e(N_regime1) as text " / " as result e(N_regime2)
    }

    display as text "ln|Sigma| = " as result %10.6f e(lndet) ///
        as text "   (linear VECM " as result %10.6f e(lndet0) as text ")"

    local lv = e(level)
    ereturn display, level(`lv')

    if "`e(model)'" == "tvecm_sls" {
        display as text "The standard errors above ARE interpretable. Smoothing"
        display as text "the indicator makes the slope estimates asymptotically"
        display as text "normal and asymptotically INDEPENDENT of the threshold,"
        display as text "which is exactly what fails in the sharp fit: there the"
        display as text "threshold converges at a different rate and the usual"
        display as text "standard errors are not valid for inference."
        display as text ""
        display as text "The threshold itself still has NO standard error. Its"
        display as text "limit is a functional of a vector Brownian motion, not"
        display as text "a normal, so report it as a point estimate and never as"
        display as text "an estimate plus or minus something."
        display as text ""
        display as text "The smoothed fit is consistent for the sharp model only"
        display as text "because h shrinks with n; refit with a different"
        display as text "{bf:bwscale()} and check that the conclusions hold."
    }
    else {
        display as text "The thresholds have no standard errors: in a sharp"
        display as text "threshold model their limit distribution is not normal."
        display as text "The two are also searched JOINTLY, so a confidence set"
        display as text "for the pair is not the product of two intervals."
    }
end
