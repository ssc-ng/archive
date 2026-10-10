*! thregress 1.1.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold regression with unknown thresholds: conditional least squares,
*! threshold-effect test, and confidence sets for the thresholds.
*! Hansen (2000) Econometrica 68:575-603, doi:10.1111/1468-0262.00124
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Gonzalo & Pitarakis (2002) JoE 110:319-352, doi:10.1016/S0304-4076(02)00098-2
*! Donayre (2024) SNDE 29:561-573, doi:10.1515/snde-2023-0029
*! Clean-room implementation. Validation: validation/thregress/reference_lock.yml

program define thregress, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thregress" error 301
        Display `0'
        exit
    }

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        THRESHvar(varname numeric ts fv)             ///
        [ INVariant(varlist numeric fv ts)          ///
          THRESHold(numlist sort)                   ///
          TRIM(real 0.15)                           ///
          GRIDn(integer 0)                          ///
          NTHRESH(integer 1)                        ///
          REFINE(integer 0)                         ///
          MINOBS(integer 0)                         ///
          noCONStant                                ///
          VCE(string)                               ///
          ETA2(string)                              ///
          BWidth(real 0)                            ///
          CI(string)                                ///
          CONSERVative                              ///
          HETvar                                    ///
          RHO(real 0.8)                             ///
          ESTimator(string)                         ///
          HANSENCOMPAT                              ///
          TEST                                      ///
          REPS(integer 1000)                        ///
          SEED(string)                              ///
          STAT(string)                              ///
          Level(cilevel) ]

    * ------------------------------------------------ option validation
    if `nthresh' < 1 {
        display as error "{bf:nthresh()} must be 1 or more"
        exit 198
    }
    if `trim' < 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in [0, 0.5)"
        exit 198
    }
    if `rho' <= 0 | `rho' >= 1 {
        display as error "{bf:rho()} must be in (0, 1)"
        exit 198
    }
    if `refine' < 0 | `refine' > 50 {
        display as error "{bf:refine()} must be between 0 and 50"
        exit 198
    }

    _tk_parse_vce, `vce'
    local vcetype `s(vcetype)'
    local hcnum   `s(hcnum)'
    local vcelab  `"`s(vcelab)'"'

    if "`eta2'" == "" local eta2 hansen
    local eta2num = .
    if "`eta2'" == "hansen"    local eta2num 1
    if "`eta2'" == "quadratic" local eta2num 2
    if "`eta2'" == "kernel"    local eta2num 3
    if `eta2num' == . {
        display as error "eta2() must be hansen, quadratic or kernel"
        exit 198
    }

    if "`ci'" == "" {
        local ci = cond("`vcetype'"=="ols", "lr", "lrstar")
    }
    local cinum = .
    if "`ci'" == "none"   local cinum 0
    if "`ci'" == "lr"     local cinum 1
    if "`ci'" == "lrstar" local cinum 2
    if inlist("`ci'", "boot", "bootstrap", "wild", "residual") {
        display as error "ci(`ci') is blocked, and deliberately so."
        display as error "Yu (2014, Econometric Theory 30:676-714, doi:10.1017/S0266466614000012)"
        display as error "shows the nonparametric, wild and residual bootstraps are INVALID for a"
        display as error "confidence interval on the threshold. They remain valid for test p-values"
        display as error "under the null: see {bf:thtest}. Use ci(lr), ci(lrstar) or ci(none)."
        exit 198
    }
    if `cinum' == . {
        display as error "ci() must be lr, lrstar or none"
        exit 198
    }

    local hetvar = cond("`hetvar'"!="", 1, 0)
    if `hetvar' & "`zlist'" != "" {
        display as error "{bf:hetvar} cannot be used with regime-invariant"
        display as error "regressors. With a separate variance per regime the"
        display as error "two regimes are fitted SEPARATELY, and an invariant"
        display as error "regressor is by definition shared, so the model does"
        display as error "not separate. Move the invariant regressors into the"
        display as error "switching list, or drop {bf:hetvar}."
        exit 198
    }
    if `hetvar' & `nthresh' > 1 {
        display as error "{bf:hetvar} is implemented for ONE threshold."
        display as error "With several thresholds the Gaussian criterion has"
        display as error "a variance per regime and the sequential search"
        display as error "would have to carry all of them; that is not"
        display as error "implemented, and guessing at it would be worse than"
        display as error "its absence."
        exit 198
    }

    if "`estimator'" == "" local estimator left
    local midpoint 0
    if "`estimator'" == "midpoint" local midpoint 1
    else if "`estimator'" != "left" {
        display as error "estimator() must be left or midpoint"
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

    local hansencompat = cond("`hansencompat'"!="", 1, 0)
    local dotest       = cond("`test'"!="", 1, 0)
    local hascons      = cond("`constant'"=="", 1, 0)
    local knowngamma "`threshold'"
    local refinen `refine'

    if "`seed'" != "" set seed `seed'

    * ------------------------------------------------ sample
    marksample touse
    markout `touse' `threshvar' `invariant'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'

    quietly count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)

    local xlist ""
    local xvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local xlist `r(varlist)'
        fvrevar `xlist' if `touse'
        local xvars `r(varlist)'
    }
    local zlist ""
    local zvars ""
    if "`invariant'" != "" {
        fvexpand `invariant' if `touse'
        local zlist `r(varlist)'
        fvrevar `zlist' if `touse'
        local zvars `r(varlist)'
    }
    if "`xlist'" == "" & `hascons' == 0 {
        display as error "no regressors: a threshold model needs at least one switching regressor"
        exit 102
    }

    * ------------------------------------------------ compute
    * threshvar() may carry a time-series or factor operator -- thtar hands
    * one straight through as thvar(L.x) -- so it is materialised here. The
    * reported name stays the one the user typed.
    local qname "`threshvar'"
    fvrevar `threshvar' if `touse'
    local qvar `r(varlist)'
    mata: tk_thregress()

    local m = __tk_m
    local nreg = `m' + 1

    * ------------------------------------------------ names and post
    local cnames ""
    foreach v of local xlist {
        local cnames `cnames' `v'
    }
    if `hascons' local cnames `cnames' _cons
    local colnames ""
    local coleqs ""
    forvalues j = 1/`nreg' {
        foreach v of local cnames {
            local colnames `colnames' `v'
            local coleqs `coleqs' Region`j'
        }
    }
    foreach v of local zlist {
        local colnames `colnames' `v'
        local coleqs `coleqs' Invariant
    }

    tempname b V
    matrix `b' = __tk_b
    matrix `V' = __tk_V
    matrix colnames `b' = `colnames'
    matrix coleq    `b' = `coleqs'
    matrix colnames `V' = `colnames'
    matrix coleq    `V' = `coleqs'
    matrix rownames `V' = `colnames'
    matrix roweq    `V' = `coleqs'

    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`nobs')

    ereturn local cmd          "thregress"
    ereturn local cmdline      "thregress `0'"
    ereturn local title        "Threshold regression"
    ereturn local family       "gaussian"
    ereturn local model        "jump"
    ereturn local estimator    "conditional least squares"
    ereturn local threshold_var "`threshvar'"
    ereturn local depvar       "`depv'"
    ereturn local indepvars    "`xlist'"
    ereturn local invariant    "`zlist'"
    ereturn local vce          "`vcetype'"
    ereturn local vcetype      = cond("`vcetype'"=="ols", "", "Robust")
    ereturn local vcelab       "`vcelab'"
    ereturn local ci_method    "`ci'"
    ereturn local eta2_method  "`eta2'"
    ereturn local point_est    "`estimator'"
    ereturn local hansencompat "`hansencompat'"
    ereturn local search       = cond(`m' > 1, "sequential", "grid")
    ereturn local conservative = cond("`conservative'"!="", "1", "0")
    ereturn local properties   "b V"
    ereturn local predict      "thregress_p"
    ereturn local estat_cmd    "thregress_estat"
    ereturn local marginsnotok "Residuals SCore"

    ereturn scalar N        = __tk_n
    ereturn scalar k_eq     = cond("`zlist'"=="", `nreg', `nreg'+1)
    ereturn scalar k_regime = `nreg'
    ereturn scalar nthresh  = `m'
    ereturn scalar k_switch = __tk_k
    ereturn scalar k_inv    = __tk_p
    ereturn scalar gamma    = __tk_gamma
    ereturn scalar ssr      = __tk_ssr
    ereturn scalar ssr0     = __tk_ssr0
    ereturn scalar ssr1     = __tk_ssr1
    ereturn scalar ssr2     = __tk_ssr2
    ereturn scalar sigma2   = __tk_sigma2
    ereturn scalar rmse     = sqrt(__tk_s2pool)
    ereturn scalar r2       = __tk_r2
    ereturn scalar r2_0     = __tk_r20
    ereturn scalar N_regime1 = __tk_n1
    ereturn scalar N_regime2 = __tk_n2
    ereturn scalar eta2     = __tk_eta2
    ereturn scalar level    = `level'
    ereturn scalar cv       = __tk_cv
    ereturn scalar gamma_lo = __tk_cilo
    ereturn scalar gamma_hi = __tk_cihi
    capture ereturn scalar ci_contiguous = __tk_contig
    capture ereturn scalar ci_npoints    = __tk_nciset
    ereturn scalar trim     = `trim'
    ereturn scalar gridn    = `gridn'
    ereturn scalar hascons  = `hascons'
    ereturn scalar hetvar   = `hetvar'
    capture ereturn scalar sigma2_1 = __tk_sigma2_1
    capture ereturn scalar sigma2_2 = __tk_sigma2_2
    capture ereturn scalar lr_var   = __tk_lr_var
    capture ereturn scalar p_var    = __tk_p_var
    ereturn scalar rho      = `rho'
    ereturn scalar refine   = `refine'
    ereturn scalar n_moved  = __tk_moved
    ereturn scalar n_grid   = __tk_ngrid
    ereturn scalar grid_skipped = __tk_skip
    ereturn scalar het_p_global  = __tk_hetp0
    ereturn scalar het_p_thresh  = __tk_hetp1
    ereturn scalar ll       = __tk_ll
    ereturn scalar aic      = __tk_aic
    ereturn scalar bic      = __tk_bic
    ereturn scalar hqic     = __tk_hqic
    ereturn scalar bic_gp   = __tk_bicgp
    if `dotest' {
        ereturn scalar supf   = __tk_supf
        ereturn scalar suplm  = __tk_suplm
        ereturn scalar stat   = cond("`vcetype'"=="ols", __tk_supf, __tk_suplm)
        ereturn scalar gamma_test = __tk_gmax
        ereturn scalar p       = __tk_pboot
        ereturn scalar p_mcse  = __tk_mcse
        ereturn scalar boot_reps = `reps'
        ereturn scalar n_singular = __tk_nsing
        ereturn local  teststat "`stat'"
        ereturn local  boot "fixed-regressor"
        ereturn local  boot_resid = cond(`hansencompat', "null (global OLS)", "threshold fit")
        capture ereturn matrix bdist = __tk_bdist
    }

    tempname M
    matrix `M' = __tk_gammas
    matrix colnames `M' = gamma
    ereturn matrix thresholds = `M'
    matrix `M' = __tk_cib
    matrix colnames `M' = ll ul
    ereturn matrix ci_benchmark = `M'
    matrix `M' = __tk_cic
    matrix colnames `M' = ll ul
    ereturn matrix ci_conservative = `M'
    matrix `M' = __tk_nreg
    ereturn matrix nobs_regime = `M'
    matrix `M' = __tk_ssrreg
    ereturn matrix ssr_regime = `M'
    matrix `M' = __tk_profile
    if rowsof(`M') > 1 {
        matrix colnames `M' = gamma ssr LR LRstar k
        ereturn matrix profile = `M'
    }
    matrix `M' = __tk_ciset
    if rowsof(`M') > 1 {
        matrix colnames `M' = gamma k
        ereturn matrix ci_set = `M'
    }
    if `m' == 1 {
        matrix `M' = __tk_ci1
        matrix rownames `M' = `cnames'
        matrix colnames `M' = ll ul
        ereturn matrix twostep1 = `M'
        matrix `M' = __tk_ci2
        matrix rownames `M' = `cnames'
        matrix colnames `M' = ll ul
        ereturn matrix twostep2 = `M'
    }

    _tk_drop

    Display
end

* ----------------------------------------------------------------------
program define Display
    syntax [, Level(cilevel) CONSERVative ]
    if "`level'" == "" local level = e(level)
    if "`conservative'" == "" & "`e(conservative)'" == "1" local conservative conservative

    local m = e(nthresh)
    local nreg = `m' + 1

    display ""
    display as text "Threshold regression" _col(50) "Number of obs" _col(68) "=" ///
        _col(71) as result %9.0fc e(N)
    display as text "Model: `nreg' regimes, discontinuous (jump)" _col(50) "SSR" _col(68) "=" ///
        _col(71) as result %9.0g e(ssr)
    display as text "Estimator: `e(estimator)'" _col(50) "R-squared" _col(68) "=" ///
        _col(71) as result %9.4f e(r2)
    display as text "Std. err.: `e(vcelab)'" _col(50) "Root MSE" _col(68) "=" ///
        _col(71) as result %9.0g e(rmse)
    display as text "Threshold variable: " as result "`e(threshold_var)'" _col(50) ///
        as text "BIC" _col(68) "=" _col(71) as result %9.0g e(bic)
    display ""

    tempname G CB CC NR
    matrix `G'  = e(thresholds)
    matrix `CB' = e(ci_benchmark)
    matrix `CC' = e(ci_conservative)
    matrix `NR' = e(nobs_regime)

    display as text "{hline 78}"
    display as text "  Threshold" _col(18) "estimate" _col(32) "`level'% confidence set" ///
        _col(60) "regime" _col(70) "obs"
    display as text "{hline 78}"
    forvalues i = 1/`m' {
        local g  : display %10.0g `G'[`i',1]
        local g  = trim("`g'")
        local lo : display %10.0g `CB'[`i',1]
        local hi : display %10.0g `CB'[`i',2]
        if "`conservative'" != "" {
            local lo : display %10.0g `CC'[`i',1]
            local hi : display %10.0g `CC'[`i',2]
        }
        local ciwd "not computed"
        if `CB'[`i',1] < . {
            local ciwd = "[" + trim("`lo'") + ", " + trim("`hi'") + "]"
        }
        display as text "  gamma_`i'" _col(18) as result %10s "`g'" ///
            _col(32) as result %-26s "`ciwd'" ///
            as text _col(61) "`i'" _col(67) as result %8.0fc `NR'[1,`i']
    }
    display as text _col(61) "`nreg'" _col(67) as result %8.0fc `NR'[1,`nreg']
    display as text "{hline 78}"
    if "`conservative'" != "" {
        display as text "  Confidence sets are the {bf:conservative} inverted-LR intervals"
        display as text "  (Donayre, Eo & Morley 2018; Donayre 2024 eq. 6): the benchmark set"
        display as text "  extended to the adjacent excluded observations."
    }
    else {
        display as text "  Benchmark inverted-LR sets (`e(ci_method)'), c = " ///
            as result %5.3f e(cv) as text ".  Option {bf:conservative} reports the"
        display as text "  Donayre, Eo & Morley (2018) modification instead."
    }
    if e(ci_contiguous) == 0 {
        display as text "  {it:note}: the level set for gamma_1 is " as result e(ci_npoints) ///
            as text " grid points and is {bf:not} an interval;"
        display as text "        the figure shown is its convex hull, as in Hansen (2000)."
        display as text "        See {bf:estat lrplot} and {bf:e(ci_set)}."
    }
    if e(eta2) < . {
        display as text "  eta-squared (gamma_1) = " as result %10.0g e(eta2) ///
            as text "   method: `e(eta2_method)'"
    }
    if `m' > 1 {
        display as text "  Thresholds estimated sequentially (Gonzalo-Pitarakis 2002);" ///
            " refine(" as result e(refine) as text ")"
        if e(refine) > 0 {
            display as text "  refinement moved a threshold " as result e(n_moved) as text " time(s)."
        }
    }

    if e(p) < . {
        display ""
        display as text "Test of H0: no threshold effect  (" as result "`e(teststat)'" ///
            as text "-" as result cond("`e(vce)'"=="ols","F","LM") as text " statistic)"
        display as text "  statistic" _col(32) as result %10.4f e(stat) ///
            as text _col(45) "argmax at " as result %9.0g e(gamma_test)
        display as text "  bootstrap p-value" _col(32) as result %10.4f e(p) ///
            as text _col(45) "`e(boot_reps)' reps, MC s.e. " %5.4f e(p_mcse)
        display as text "  bootstrap" _col(32) as result "`e(boot)'" ///
            _col(48) as text "residuals: " as result "`e(boot_resid)'"
    }

    display ""
    _coef_table, level(`level')
    display as text "Note: inference on the slopes treats the thresholds as known"
    display as text "      (Hansen 2000, eq. 11). For intervals that account for threshold"
    display as text "      uncertainty see {bf:estat twostep} (two-regime models)."
end

* ----------------------------------------------------------------------
* Parse vce() in its own scope. Returns s(vcetype), s(hcnum), s(vcelab).
program define _tk_parse_vce, sclass
    version 15
    syntax [, OLS Robust HC0 HC1 HC2 HC3]
    if "`ols'" != "" & "`robust'`hc0'`hc1'`hc2'`hc3'" != "" {
        display as error "vce(ols) cannot be combined with a heteroskedasticity-robust option"
        exit 198
    }
    local vcetype robust
    local hcnum 0
    if "`ols'" != "" {
        local vcetype ols
    }
    if "`hc1'" != "" {
        local hcnum 1
    }
    if "`hc2'" != "" {
        local hcnum 2
    }
    if "`hc3'" != "" {
        local hcnum 3
    }
    if "`vcetype'" == "ols" {
        local vcelab "OLS (homoskedastic)"
    }
    else {
        local vcelab "robust (HC`hcnum')"
    }
    sreturn clear
    sreturn local vcetype `vcetype'
    sreturn local hcnum   `hcnum'
    sreturn local vcelab  `"`vcelab'"'
end
