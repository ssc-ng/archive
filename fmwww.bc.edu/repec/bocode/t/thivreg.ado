*! thivreg 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold regression with ENDOGENOUS regressors.
*! Caner, M. and B. E. Hansen (2004) "Instrumental Variable Estimation of a
*! Threshold Model", Econometric Theory 20:813-843,
*! doi:10.1017/S0266466604205011
*! Hansen, B. E. (2000) Econometrica 68:575-603, doi:10.1111/1468-0262.00124
*!   (the LR-inversion interval and the two heteroskedasticity corrections)
*!
*! Syntax follows ivregress: thivreg y x1 x2 (y1 y2 = z1 z2), threshvar(q)

program define thivreg, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thivreg" error 301
        Display
        exit
    }

    * ------------------------------------------------ parse the IV syntax
    * _iv_parse reads the variable lists but returns NOTHING for the rest of
    * the command, so the (endog = inst) block is cut out here by matching
    * parentheses at depth -- a plain strpos() for the first ")" would break
    * on a time-series list like L(1/2).x inside the block.
    local cmdline `"`0'"'
    local L = strlen(`"`cmdline'"')
    local p1 = 0
    local p2 = 0
    local depth = 0
    forvalues i = 1/`L' {
        local ch = substr(`"`cmdline'"', `i', 1)
        if "`ch'" == "(" {
            if `depth' == 0 & `p1' == 0 local p1 = `i'
            local ++depth
        }
        else if "`ch'" == ")" {
            local --depth
            if `depth' == 0 & `p1' > 0 & `p2' == 0 {
                local p2 = `i'
                continue, break
            }
        }
    }
    if `p1' == 0 | `p2' == 0 {
        display as error "no instrument list found"
        display as error "syntax: {bf:thivreg} {it:depvar} [{it:exogvars}]"
        display as error "        ({it:endogvars} = {it:instruments}) {bf:,} threshvar({it:q})"
        display as error "with no endogenous regressor, use {helpb thregress}"
        exit 198
    }
    local before = substr(`"`cmdline'"', 1, `p1' - 1)
    local ivpart = substr(`"`cmdline'"', `p1', `p2' - `p1' + 1)
    local after  = substr(`"`cmdline'"', `p2' + 1, .)

    _iv_parse `before' `ivpart'
    local depv  "`s(lhs)'"
    local exog  "`s(exog)'"
    local endog "`s(endog)'"
    local inst  "`s(inst)'"
    local 0 `"`after'"'

    syntax [if] [in] , THRESHvar(varname numeric) ///
        [ TRIM(real 0.05)                         ///
          GRIDn(integer 0)                        ///
          noCONStant                              ///
          REDuced(string)                         ///
          CIMethod(string)                        ///
          NOTWostep                               ///
          CILevel2(real 0.80)                     ///
          Level(cilevel) ]

    if "`endog'" == "" {
        display as error "no endogenous regressor: use {helpb thregress} instead"
        exit 198
    }
    if "`inst'" == "" {
        display as error "no excluded instrument supplied"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if "`reduced'" == "" local reduced linear
    local reduced = lower("`reduced'")
    if !inlist("`reduced'", "linear", "threshold") {
        display as error "{bf:reduced()} must be linear or threshold"
        exit 198
    }
    local redun = cond("`reduced'"=="threshold", 1, 0)
    if "`cimethod'" == "" local cimethod quadratic
    local cimethod = lower("`cimethod'")
    if !inlist("`cimethod'", "uncorrected", "quadratic", "kernel") {
        display as error "{bf:cimethod()} must be uncorrected, quadratic or kernel"
        exit 198
    }
    local cimn = cond("`cimethod'"=="uncorrected", 0, ///
                 cond("`cimethod'"=="quadratic", 1, 2))
    if `cilevel2' <= 0 | `cilevel2' >= 1 {
        display as error "{bf:cilevel2()} is a fraction in (0,1), e.g. 0.80"
        exit 198
    }
    local dotwostep = cond("`notwostep'"=="", 1, 0)
    local hascons   = cond("`constant'"=="", 1, 0)
    local levn  = `level'/100
    local lev2n = `cilevel2'

    * ------------------------------------------------ sample and variables
    marksample touse
    markout `touse' `depv' `exog' `endog' `inst' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' == 0 error 2000

    fvexpand `endog' if `touse'
    local endlist `r(varlist)'
    fvrevar `endlist' if `touse'
    local endvars `r(varlist)'
    local k1 : word count `endvars'

    local exlist ""
    local exvars ""
    if "`exog'" != "" {
        fvexpand `exog' if `touse'
        local exlist `r(varlist)'
        fvrevar `exlist' if `touse'
        local exvars `r(varlist)'
    }
    fvexpand `inst' if `touse'
    local ivlist `r(varlist)'
    fvrevar `ivlist' if `touse'
    local ivvars `r(varlist)'
    local miv : word count `ivvars'

    if `miv' < `k1' {
        display as error "`miv' excluded instrument(s) for `k1' endogenous"
        display as error "regressor(s): the model is not identified"
        exit 481
    }

    local qvar `threshvar'
    local nex : word count `exlist'
    local kz = `k1' + `nex' + `hascons'
    if `nobs' < 4 * `kz' + 10 {
        display as error "only `nobs' observations for `kz' coefficients per"
        display as error "regime: too few for a two-regime IV model"
        exit 2001
    }

    * ------------------------------------------------ engine
    _tk_drop
    capture noisily mata: tk_thivreg()
    if _rc {
        display as error "the Caner-Hansen IV engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }
    local fail = __tk_ivfail
    if `fail' != 0 {
        if `fail' == 1 {
            display as error "the trimmed grid is empty: widen {bf:trim()} or"
            display as error "reduce the number of regressors"
        }
        else if `fail' == 2 {
            display as error "the threshold reduced form found no admissible"
            display as error "threshold; refit with {bf:reduced(linear)}"
        }
        else if `fail' == 3 {
            display as error "no admissible threshold: every grid point left a"
            display as error "regime smaller than the design"
        }
        else {
            display as error "regime GMM failed: a regime is too small, or its"
            display as error "instruments are collinear within the regime"
            display as error "(this is the commonest failure here -- an instrument"
            display as error "that varies in the full sample can be constant inside"
            display as error "one regime)"
        }
        _tk_drop
        exit 459
    }

    tempname b V V1 V2 CI1 CI2 PROF QCI RFSN
    matrix `b'    = __tk_ivb
    matrix `V1'   = __tk_ivV1
    matrix `V2'   = __tk_ivV2
    matrix `CI1'  = __tk_ivci1
    matrix `CI2'  = __tk_ivci2
    matrix `PROF' = __tk_ivprof
    matrix `QCI'  = __tk_ivqci
    capture matrix `RFSN' = __tk_ivrfsn
    local n      = __tk_ivn
    local gamma  = __tk_ivgamma
    local ssr    = __tk_ivssr
    local ssr0   = __tk_ivssr0
    local sig2   = __tk_ivsig2
    local n1     = __tk_ivn1
    local n2     = __tk_ivn2
    local ng     = __tk_ivngrid
    local ngci   = __tk_ivngci
    local cv     = __tk_ivcv
    local eta1   = __tk_iveta1
    local eta2   = __tk_iveta2
    local J1     = __tk_ivJ1
    local J2     = __tk_ivJ2
    local Jdf    = __tk_ivJdf
    local rfq    = __tk_ivrfq
    local ctg0   = __tk_ivctg0
    local ctg1   = __tk_ivctg1
    local ctg2   = __tk_ivctg2

    * ------------------------------------------------ names
    local zn ""
    foreach v of local endlist {
        local zn "`zn' `v'"
    }
    foreach v of local exlist {
        local zn "`zn' `v'"
    }
    if `hascons' local zn "`zn' _cons"

    local cn ""
    local ce ""
    foreach v of local zn {
        local cn "`cn' `v'"
        local ce "`ce' Regime1"
    }
    foreach v of local zn {
        local cn "`cn' `v'"
        local ce "`ce' Regime2"
    }

    * block-diagonal V: the two regimes use disjoint observations, so their
    * GMM estimators are independent and the cross-block is exactly zero.
    * That is a fact about the estimator, not an approximation.
    matrix `V' = `V1', J(`kz', `kz', 0) \ J(`kz', `kz', 0), `V2'
    matrix colnames `b' = `cn'
    matrix coleq    `b' = `ce'
    matrix colnames `V' = `cn'
    matrix coleq    `V' = `ce'
    matrix rownames `V' = `cn'
    matrix roweq    `V' = `ce'

    tempvar esample
    quietly generate byte `esample' = `touse'
    ereturn post `b' `V', depname("`depv'") obs(`n') esample(`esample')

    ereturn local cmd       "thivreg"
    ereturn local cmdline   `"thivreg `cmdline'"'
    ereturn local title     "IV threshold regression (Caner-Hansen 2004)"
    ereturn local depvar    "`depv'"
    ereturn local endog     "`endlist'"
    ereturn local exog      "`exlist'"
    ereturn local insts     "`ivlist'"
    ereturn local zn        "`zn'"
    ereturn local threshold_var "`threshvar'"
    ereturn local reduced   "`reduced'"
    ereturn local cimethod  "`cimethod'"
    ereturn local estat_cmd "thivreg_estat"
    ereturn local predict   "thivreg_p"
    ereturn local properties "b V"
    ereturn local vcetype   "GMM"

    ereturn scalar N        = `n'
    ereturn scalar k_endog  = `k1'
    ereturn scalar k_exog   = `nex'
    ereturn scalar k_regime = `kz'
    ereturn scalar k_inst   = __tk_ivkx
    ereturn scalar hascons  = `hascons'
    * read straight from the engine: a macro round-trip through %18.0g can
    * cost the last bit, and gamma is itself an observed value of the
    * threshold variable, so one ulp moves the observation AT the threshold
    * into the wrong regime in every later predict and estat
    ereturn scalar gamma    = __tk_ivgamma
    ereturn scalar ssr      = __tk_ivssr
    ereturn scalar ssr0     = __tk_ivssr0
    ereturn scalar sigma2   = __tk_ivsig2
    ereturn scalar N_regime1 = `n1'
    ereturn scalar N_regime2 = `n2'
    ereturn scalar n_grid   = `ng'
    ereturn scalar n_gridci = `ngci'
    ereturn scalar trim     = `trim'
    ereturn scalar level    = `level'
    ereturn scalar cilevel2 = `cilevel2'
    ereturn scalar lr_cv    = __tk_ivcv
    ereturn scalar eta2_quad = __tk_iveta1
    ereturn scalar eta2_kern = __tk_iveta2
    ereturn scalar J_regime1 = __tk_ivJ1
    ereturn scalar J_regime2 = __tk_ivJ2
    ereturn scalar J_df      = `Jdf'
    if `Jdf' > 0 {
        ereturn scalar p_J1 = chi2tail(`Jdf', `J1')
        ereturn scalar p_J2 = chi2tail(`Jdf', `J2')
    }
    ereturn scalar gamma_lo  = `QCI'[1,1]
    ereturn scalar gamma_hi  = `QCI'[1,2]
    ereturn scalar gamma_lo_quad = `QCI'[2,1]
    ereturn scalar gamma_hi_quad = `QCI'[2,2]
    ereturn scalar gamma_lo_kern = `QCI'[3,1]
    ereturn scalar gamma_hi_kern = `QCI'[3,2]
    ereturn scalar ci_contiguous      = `ctg0'
    ereturn scalar ci_contiguous_quad = `ctg1'
    ereturn scalar ci_contiguous_kern = `ctg2'
    if `redun' ereturn scalar gamma_rf = __tk_ivrfq

    matrix colnames `PROF' = gamma ssr lr
    matrix colnames `QCI'  = lower upper
    matrix rownames `QCI'  = uncorrected quadratic kernel
    matrix colnames `CI1'  = lower upper
    matrix colnames `CI2'  = lower upper
    matrix rownames `CI1'  = `zn'
    matrix rownames `CI2'  = `zn'
    ereturn matrix profile   = `PROF'
    ereturn matrix gamma_ci  = `QCI'
    ereturn matrix slopeci1  = `CI1'
    ereturn matrix slopeci2  = `CI2'
    capture ereturn matrix rf_profile = `RFSN'

    _tk_drop
    Display
end

* ======================================================================
program define Display
    version 15
    local depv "`e(depvar)'"
    local kz   = e(k_regime)
    tempname QCI CI1 CI2
    matrix `QCI' = e(gamma_ci)
    matrix `CI1' = e(slopeci1)
    matrix `CI2' = e(slopeci2)

    display _n as text "IV threshold regression" ///
        _col(52) "Number of obs = " as result %8.0f e(N)
    display as text "Caner and Hansen (2004)" ///
        _col(52) as text "Regime 1 / 2  = " as result %4.0f e(N_regime1) ///
        as text " /" as result %4.0f e(N_regime2)
    display as text "{hline 78}"
    display as text "  Dependent variable" _col(38) as result "`depv'"
    display as text "  Endogenous" _col(38) as result "`e(endog)'"
    if "`e(exog)'" != "" {
        display as text "  Exogenous" _col(38) as result "`e(exog)'"
    }
    display as text "  Excluded instruments" _col(38) as result "`e(insts)'"
    display as text "  Threshold variable" _col(38) as result "`e(threshold_var)'"
    display as text "  Reduced form" _col(38) as result "`e(reduced)'"
    if e(gamma_rf) < . {
        display as text "    its own threshold" _col(38) as result %12.6g e(gamma_rf)
    }
    display as text "  Trimming" _col(38) as result %12.3f e(trim) ///
        as text "   grid points " as result e(n_grid)
    display as text "{hline 78}"
    display as text "  Threshold gamma" _col(38) as result %12.6g e(gamma)
    display as text "  SSR: no threshold / threshold" _col(36) as result ///
        %11.5f e(ssr0) " " %11.5f e(ssr)
    display as text "{hline 78}"

    display as text "  Confidence interval for gamma at " ///
        as result e(level) as text "%, LR inversion"
    display as text "    critical value" _col(38) as result %12.4f e(lr_cv)
    display as text "{hline 78}"
    display as text "    method" _col(26) "lower" _col(42) "upper" ///
        _col(56) "eta-squared" _col(70) "set"
    display as text "{hline 78}"
    display as text "    uncorrected" _col(20) as result %14.6g `QCI'[1,1] ///
        _col(36) %14.6g `QCI'[1,2] _col(52) as text "       1" ///
        _col(64) as result cond(e(ci_contiguous), "interval", "NOT an interval")
    display as text "    het, quadratic" _col(20) as result %14.6g `QCI'[2,1] ///
        _col(36) %14.6g `QCI'[2,2] _col(50) %12.4f e(eta2_quad) ///
        _col(64) cond(e(ci_contiguous_quad), "interval", "NOT an interval")
    display as text "    het, kernel" _col(20) as result %14.6g `QCI'[3,1] ///
        _col(36) %14.6g `QCI'[3,2] _col(50) %12.4f e(eta2_kern) ///
        _col(64) cond(e(ci_contiguous_kern), "interval", "NOT an interval")
    display as text "{hline 78}"
    display as text "  eta-squared scales the critical value for"
    display as text "  heteroskedasticity. An eta-squared far from 1 means the"
    display as text "  uncorrected interval is the wrong width; report which"
    display as text "  correction you used, because they can differ by a factor of"
    display as text "  two. ""NOT an interval"" means the accepted set has a hole in"
    display as text "  it: the printed bounds are its hull, and the hole is real."
    display as text "{hline 78}"

    ereturn display, level(`e(level)')

    display _n as text "Slope intervals accounting for the estimated threshold"
    display as text "  (union of the per-regime GMM intervals over the " ///
        as result e(n_gridci) as text " grid points"
    display as text "   inside the " as result %4.2f e(cilevel2) ///
        as text " interval for gamma, method " as result "`e(cimethod)'" as text ")"
    display as text "{hline 78}"
    display as text "  coefficient" _col(30) "regime 1" _col(54) "regime 2"
    display as text "{hline 78}"
    local zn "`e(zn)'"
    forvalues i = 1/`kz' {
        local v : word `i' of `zn'
        display as text "  " %-22s abbrev("`v'", 22) as result ///
            _col(26) "[" %9.4f `CI1'[`i',1] ", " %9.4f `CI1'[`i',2] "]" ///
            _col(50) "[" %9.4f `CI2'[`i',1] ", " %9.4f `CI2'[`i',2] "]"
    }
    display as text "{hline 78}"
    display as text "  These are WIDER than the table above, and that is the point:"
    display as text "  the table conditions on gamma-hat, these do not. Report"
    display as text "  these. They use a fixed 1.96 multiplier, as the authors'"
    display as text "  own program does."
    display as text "{hline 78}"

    if e(J_df) > 0 {
        display _n as text "Overidentification (Hansen's J), by regime"
        display as text "{hline 78}"
        display as text "  regime 1" _col(40) as result %12.4f e(J_regime1) ///
            as text "   df " as result e(J_df) as text "   p " ///
            as result %6.4f e(p_J1)
        display as text "  regime 2" _col(40) as result %12.4f e(J_regime2) ///
            as text "   df " as result e(J_df) as text "   p " ///
            as result %6.4f e(p_J2)
        display as text "{hline 78}"
        display as text "  Each J uses only its own regime's observations, so a"
        display as text "  rejection in one regime and not the other says the"
        display as text "  instruments are valid in one state of the world and not"
        display as text "  the other. That is a finding, not a nuisance."
    }
    else {
        display _n as text "  Exactly identified in each regime, so there is no J"
        display as text "  statistic to report."
    }
end
