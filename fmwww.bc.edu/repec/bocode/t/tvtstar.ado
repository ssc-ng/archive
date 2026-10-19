*! tvtstar 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! State-dependent contemporaneous-threshold STAR (SDC-STAR / SDC-STARX):
*! a SMOOTH transition whose threshold is a linear function of observed
*! state variables.
*!
*! Dueker, M. J., Z. Psaradakis, M. Sola and F. Spagnolo (2013)
*!   "State-Dependent Threshold Smooth Transition Autoregressive Models",
*!   Oxford Bulletin of Economics and Statistics 75(5):736-759,
*!   doi:10.1111/j.1468-0084.2012.00719.x
*!
*! Clean-room -- no code ships with this paper.
*! See validation/tvthresh/tvtstar_equation_map.md.

program define tvtstar, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtstar" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varname(numeric ts) [if] [in] ,          ///
        [ LAGs(integer 1)                           ///
          Xvars(varlist numeric ts)                 ///
          EXOG(varlist numeric ts)                  ///
          GAUSSian                                  ///
          STARTs(integer 6)                         ///
          MAXiter(integer 300)                      ///
          Level(cilevel) ]

    local depv `varlist'

    * ------------------------------------------------------------- checks
    if `lags' < 1 {
        display as error "{bf:lags()} must be at least 1"
        exit 198
    }
    if `lags' > 12 {
        display as error "{bf:lags(`lags')} is a lot for a model with two" ///
            " regimes and a"
        display as error "state-dependent threshold: every lag is" ///
            " estimated TWICE and enters"
        display as error "the transition function as well."
        exit 198
    }
    if `starts' < 1 {
        display as error "{bf:starts()} must be at least 1"
        exit 198
    }
    if `starts' > 6 {
        display as error "{bf:starts()} above 6 is not used: the grid has" ///
            " six points"
        exit 198
    }
    if `maxiter' < 10 {
        display as error "{bf:maxiter()} must be at least 10"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xvars' `exog'
    quietly count if `touse'
    local nobs = r(N)

    local kx : word count `xvars'
    local ke : word count `exog'
    local npar = 2*(`lags' + 1 + `ke' + 1) + 1 + `kx'
    if "`gaussian'" == "" local npar = `npar' + 2
    if `nobs' - `lags' < 3*`npar' {
        display as error "too few observations (`=`nobs'-`lags'' usable)" ///
            " for `npar' parameters"
        display as error "this is a two-regime model: every regressor is" ///
            " estimated twice."
        exit 2001
    }

    capture quietly tsset
    if _rc == 0 {
        local tvar "`r(timevar)'"
        if "`tvar'" != "" {
            quietly summarize `tvar' if `touse', meanonly
            local span = r(max) - r(min) + 1
            if `span' != `nobs' {
                display as error "`tvar' has gaps inside the sample" ///
                    " (span `span', `nobs' observations)"
                display as error "the model is autoregressive, so the" ///
                    " series must be equally spaced."
                exit 459
            }
        }
    }

    _tvt_drop
    display as text "maximising the likelihood from `starts' starting" ///
        " values; the transition"
    display as text "function depends on every parameter, so there is" ///
        " nothing to profile out."

    mata: tvt_star()

    tempname LL LL0 LLLIN LR LRP LRLIN NN NP KX KE S1 S2 NU1 NU2 YST
    tempname NCONV GMIN GMAX GMEAN NPAR
    scalar `LL'    = __tvt_sr_ll
    scalar `LL0'   = __tvt_sr_ll0
    scalar `LLLIN' = __tvt_sr_lllin
    scalar `LR'    = __tvt_sr_lr
    scalar `LRP'   = __tvt_sr_lrp
    scalar `LRLIN' = __tvt_sr_lrlin
    scalar `NN'    = __tvt_sr_n
    scalar `NP'    = __tvt_sr_np
    scalar `KX'    = __tvt_sr_kx
    scalar `KE'    = __tvt_sr_ke
    scalar `S1'    = __tvt_sr_s1
    scalar `S2'    = __tvt_sr_s2
    scalar `NU1'   = __tvt_sr_nu1
    scalar `NU2'   = __tvt_sr_nu2
    scalar `YST'   = __tvt_sr_yst
    scalar `NCONV' = __tvt_sr_nconv
    scalar `GMIN'  = __tvt_sr_gmin
    scalar `GMAX'  = __tvt_sr_gmax
    scalar `GMEAN' = __tvt_sr_gmean
    scalar `NPAR'  = __tvt_sr_npar
    tempname NOVCE ATFL
    scalar `NOVCE' = __tvt_sr_novce
    scalar `ATFL'  = __tvt_sr_atfloor
    tempname BM VM GM PM
    matrix `BM' = __tvt_sr_b
    matrix `VM' = __tvt_sr_V
    matrix `GM' = __tvt_sr_G
    matrix `PM' = __tvt_sr_path
    _tvt_drop

    * -------------------------------------------------------- the names
    local nm
    foreach r in 1 2 {
        local nm `nm' regime`r':_cons
        forvalues j = 1/`lags' {
            local nm `nm' regime`r':L`j'.`depv'
        }
        foreach v of local exog {
            local nm `nm' regime`r':`v'
        }
        local nm `nm' regime`r':sigma
        if "`gaussian'" == "" local nm `nm' regime`r':df
    }
    local nm `nm' threshold:_cons
    foreach v of local xvars {
        local nm `nm' threshold:`v'
    }
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    * obs() needs a NUMBER, not the NAME of a scalar: passing a tempname
    * answers "option obs() incorrectly specified"
    local nused = `NN'
    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nused')
    ereturn scalar N        = `NN'
    ereturn scalar N_full   = `nobs'
    ereturn scalar ll       = `LL'
    ereturn scalar ll_0     = `LL0'
    ereturn scalar ll_lin   = `LLLIN'
    ereturn scalar lr_const = `LR'
    ereturn scalar p_lr_const = `LRP'
    ereturn scalar lr_lin   = `LRLIN'
    ereturn scalar lags     = `lags'
    ereturn scalar k_state  = `KX'
    ereturn scalar k_exog   = `KE'
    ereturn scalar sigma1   = `S1'
    ereturn scalar sigma2   = `S2'
    if "`gaussian'" == "" {
        ereturn scalar df1  = `NU1'
        ereturn scalar df2  = `NU2'
    }
    ereturn scalar gamma0   = `YST'
    ereturn scalar n_conv   = `NCONV'
    ereturn scalar n_start  = `starts'
    ereturn scalar G_min    = `GMIN'
    ereturn scalar G_max    = `GMAX'
    ereturn scalar G_mean   = `GMEAN'
    ereturn scalar k_par    = `NPAR'
    ereturn scalar novce    = `NOVCE'
    ereturn scalar df_floor = `ATFL'
    ereturn local  cmd       "tvtstar"
    ereturn local  cmdline   "tvtstar `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  statevars "`xvars'"
    ereturn local  exogvars  "`exog'"
    ereturn local  errdist   = cond("`gaussian'"!="", "Gaussian", ///
        "standardised Student t")
    ereturn local  title     "State-dependent threshold STAR (SDC-STAR)"
    ereturn matrix weight = `GM'
    ereturn matrix path   = `PM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    local xv "`e(statevars)'"
    local kx : word count `xv'

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Dueker, Psaradakis, Sola and Spagnolo (2013)" ///
        _col(52) as text "Log likelihood" _col(68) "=" ///
        _col(71) as result %9.3f e(ll)
    display as text "Errors: " as result "`e(errdist)'" ///
        _col(52) as text "Converged from" _col(68) "=" ///
        _col(71) as result %5.0f e(n_conv) as text " /" ///
        as result %3.0f e(n_start)
    display ""
    display as text "{hline 78}"
    if `kx' == 0 {
        display as text "  The threshold is CONSTANT: no {bf:xvars()}" ///
            " was given, so this is an"
        display as text "  ordinary C-STAR."
    }
    else {
        local eq = "    threshold(t) = " + string(e(gamma0), "%9.0g")
        forvalues j = 1/`kx' {
            local zz : word `j' of `xv'
            local cf = _b[threshold:`zz']
            local sgn = cond(`cf' < 0, " - ", " + ")
            local eq = "`eq'" + "`sgn'" + string(abs(`cf'), "%9.0g") ///
                + " L." + "`zz'"
        }
        display as text "  The threshold is STATE DEPENDENT:"
        display as text "`eq'"
    }
    display as text "{hline 78}"
    display as text "  Regime-1 weight G: min " as result %7.4f e(G_min) ///
        as text "  mean " as result %7.4f e(G_mean) ///
        as text "  max " as result %7.4f e(G_max)
    if e(G_max) - e(G_min) < 0.05 {
        display as error "  G barely moves. The transition is close to" ///
            " degenerate and the two"
        display as error "  regimes are nearly indistinguishable; treat" ///
            " the split as unidentified."
    }
    display as text "{hline 78}"

    if e(novce) {
        display as error "  The Hessian was not negative definite at the" ///
            " optimum, so NO standard"
        display as error "  errors are reported. The point estimates" ///
            " stand; the zeros in the"
        display as error "  table below are placeholders, not estimates." ///
            " Try more {bf:starts()}."
        display as text "{hline 78}"
    }

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  Tests" _col(40) "statistic" _col(56) "p-value"
    if `kx' > 0 {
        display as text "    LR, threshold is CONSTANT (beta=0)" _col(40) ///
            as result %11.4f e(lr_const) _col(54) %9.4f e(p_lr_const)
        display as text "      chi2(" as result `kx' as text ")." ///
            " {bf:This test is regular}: under beta = 0 the"
        display as text "      threshold intercept is still identified," ///
            " so there is no"
        display as text "      Davies problem and the usual" ///
            " distribution applies."
    }
    display as text "    LR, linear AR against SDC-STAR" _col(40) ///
        as result %11.4f e(lr_lin) _col(54) "       --"
    display as text "      {bf:NO p-value, and none is offered.} Under" ///
        " linearity the"
    display as text "      transition parameters are unidentified, so" ///
        " this statistic"
    display as text "      does NOT have a chi-squared distribution." ///
        " The paper uses"
    display as text "      Hansen's (1996) method; that is not" ///
        " implemented here, so the"
    display as text "      number is descriptive only."
    display as text "{hline 78}"
    display as text "  Log likelihood: SDC-STAR " as result %12.3f e(ll) ///
        as text "   linear AR " as result %12.3f e(ll_lin)
    if e(ll_0) < . {
        display as text "                  constant threshold " ///
            as result %12.3f e(ll_0)
    }
    if e(df_floor) == 1 {
        display as error "  A regime's degrees of freedom sit on the" ///
            " floor of 2.05. A Student-t"
        display as error "  component at that boundary is swallowing a" ///
            " few outliers rather than"
        display as error "  fitting anyone's tails, and the split should" ///
            " NOT be read as two"
        display as error "  economic regimes. Refit with {bf:gaussian}" ///
            " and compare."
        display as text "{hline 78}"
    }
    display as text "  {bf:regime1} and {bf:regime2} are the two latent" ///
        " AR equations; {bf:sigma} is each"
    display as text "  one's scale and {bf:df} its degrees of freedom." ///
        " The weight on regime 1"
    display as text "  is the model-implied probability that regime 1" ///
        " lands below the"
    display as text "  threshold, so it depends on EVERY parameter above."
end
