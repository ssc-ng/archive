*! cointvol_hetcoint 0.1.0  26sep2026
*! Heteroskedastic cointegration: OLS with HAC (bandwidth o(T^1/4)) Wald inference
*! and split-sample test of equal error variance (Hansen 1992)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_hetcoint.sthlp, section Methods):
*!   y_t = b0 + b1'x_t + w_t, w_t = sigma_t u_1t, sigma_t I(1)   -> Hansen (1992) eqs (1)-(4)
*!   OLS slope sqrt(T)-consistent, intercept shifted by Lambda_21 -> Hansen (1992) Thm 1
*!   V1 = T^-1 sum_{|m|<=B} k_m sum_t (x_{t+m}-xbar)(x_t-xbar)' w_{t+m} w_t
*!   W  = T (R'b1 - r)'(R' M1^-1 V1 M1^-1 R)^-1 (R'b1 - r) -> chi2(q)  -> Hansen (1992) Thm 3
*!   B = o(T^1/4); default B = floor(T^(1/5))
*!   split-sample t-test of equal variance, Bartlett lag 5          -> Hansen (1992) Table 1

program define cointvol_hetcoint, eclass
    version 14.0

    // ---------------- load / reload the Mata engine ----------------------
    capture mata: st_local("__cvsv", cvs_version())
    if _rc {
        capture program drop cointvol_eng_stoch
        quietly findfile cointvol_eng_stoch.ado
        quietly run `"`r(fn)'"'
    }

    if replay() {
        if `"`e(cmd)'"' != "cointvol hetcoint" {
            error 301
        }
        syntax [, LEVel(cilevel)]
        _cvs_het_display, level(`level')
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] [,          ///
        BWidth(integer -1) KERnel(string) SPLITTest        ///
        SPLITLag(integer 5) LEVel(cilevel) ]

    local cmdline `"cointvol hetcoint `0'"'

    // ---------------- options --------------------------------------------
    local kernel = strlower(strtrim(`"`kernel'"'))
    if `"`kernel'"' == "" local kernel "bartlett"
    if inlist(`"`kernel'"', "bar", "bart", "nw", "neweywest") local kernel "bartlett"
    if inlist(`"`kernel'"', "par", "parz")                     local kernel "parzen"
    if inlist(`"`kernel'"', "quadraticspectral", "quadratic")  local kernel "qs"
    if !inlist(`"`kernel'"', "bartlett", "parzen", "qs") {
        di as err "kernel() must be bartlett, parzen or qs"
        exit 198
    }
    if `splitlag' < 0 {
        di as err "splitlag() must be a nonnegative integer"
        exit 198
    }
    local dosplit = ("`splittest'" != "")

    // ---------------- sample and time-series checks ----------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    if "`pvar'" != "" {
        di as err "cointvol hetcoint requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local T = r(N)
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `T' {
        di as err "the estimation sample contains gaps; cointvol hetcoint needs consecutive observations"
        exit 498
    }
    gettoken depvar indepvars : varlist
    local nx : word count `indepvars'
    if `T' < `nx' + 10 {
        di as err "too few observations (" `T' ")"
        exit 2001
    }

    // ---------------- bandwidth: B = o(T^1/4) ----------------------------
    local bnote ""
    if `bwidth' == -1 {
        local bwidth = floor(`T'^(1/5) + 1e-9)
        local bsrc "default floor(T^(1/5))"
    }
    else {
        local bsrc "user-specified"
        if `bwidth' < 0 {
            di as err "bwidth() must be a nonnegative integer"
            exit 198
        }
        if `bwidth' > `T'^(1/4) {
            local bnote "B exceeds T^(1/4); Hansen (1992, Thm 3) requires B = o(T^(1/4))"
        }
    }
    if "`kernel'" == "qs" & `bwidth' == 0 {
        di as err "kernel(qs) requires bwidth() >= 1"
        exit 198
    }

    // ---------------- estimation ------------------------------------------
    tsrevar `depvar'
    local ydat "`r(varlist)'"
    tsrevar `indepvars'
    local xdat "`r(varlist)'"

    mata: cvs_het_main("`ydat'", "`xdat'", "`touse'", `bwidth', "`kernel'", `dosplit', `splitlag')

    tempname b V
    matrix `b' = __cvs_b
    matrix `V' = __cvs_V
    local s2  = scalar(__cvs_s2)
    local st  = scalar(__cvs_st)
    local sv1 = scalar(__cvs_s1)
    local sv2 = scalar(__cvs_s2h)
    capture matrix drop __cvs_b __cvs_V
    capture scalar drop __cvs_T __cvs_s2 __cvs_st __cvs_s1 __cvs_s2h

    local cn "`indepvars' _cons"
    matrix colnames `b' = `cn'
    matrix colnames `V' = `cn'
    matrix rownames `V' = `cn'

    // ---------------- post -----------------------------------------------
    ereturn post `b' `V', esample(`touse') depname(`depvar') obs(`T')
    capture qui test `indepvars'
    if !_rc {
        ereturn scalar chi2 = r(chi2)
        ereturn scalar df_m = r(df)
        ereturn scalar p    = r(p)
    }
    ereturn scalar bwidth = `bwidth'
    ereturn scalar sigma2 = `s2'
    ereturn scalar level  = `level'
    ereturn scalar tmin   = `tmin'
    ereturn scalar tmax   = `tmax'
    ereturn scalar tdelta = `tdelta'
    if `dosplit' {
        ereturn scalar split_s1  = `sv1'
        ereturn scalar split_s2  = `sv2'
        ereturn scalar split_t   = `st'
        ereturn scalar split_p   = 2*normal(-abs(`st'))
        ereturn scalar split_lag = `splitlag'
    }
    ereturn local cmd        "cointvol hetcoint"
    ereturn local cmdline    `"`cmdline'"'
    ereturn local title      "Heteroskedastic cointegration regression"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local kernel     "`kernel'"
    ereturn local bwsource   "`bsrc'"
    ereturn local bnote      "`bnote'"
    ereturn local vce        "hac"
    ereturn local vcetype    "HAC"
    ereturn local timevar    "`tvar'"
    ereturn local properties "b V"
    ereturn local predict    "cointvol_stoch_p"

    _cvs_het_display, level(`level')
end

// ---------------------------------------------------------------------------
program define _cvs_het_display
    version 14.0
    syntax [, LEVel(cilevel)]

    local kl "Bartlett"
    if "`e(kernel)'" == "parzen" local kl "Parzen"
    if "`e(kernel)'" == "qs"     local kl "Quadratic spectral"

    di
    di as txt "Heteroskedastic cointegration: OLS with HAC inference (Hansen 1992)"
    di as txt "{hline 78}"
    di as txt "Dependent variable: " as res "`e(depvar)'" as txt _col(52) "Number of obs  = " as res %9.0f e(N)
    di as txt "Kernel: " as res "`kl'" as txt _col(52) "Wald chi2(" as res e(df_m) as txt ")   = " ///
        as res %9.2f e(chi2)
    di as txt "Bandwidth B = " as res e(bwidth) as txt " (`e(bwsource)')" _col(52) "Prob > chi2    = " ///
        as res %9.4f e(p)
    di
    ereturn display, level(`level')
    di as txt "HAC sandwich on (1, x_t) w_t, no small-sample correction; slope block = Hansen (1992)"
    di as txt "  Thm 3: T^-1 M1^-1 V1 M1^-1 with demeaned regressors. Wald tests (-test-) are chi2(q)."
    di as txt "Note: _cons is not consistent (pseudo-true value b0 + Lambda_21, Hansen 1992 Thm 1);"
    di as txt "      do not use its standard error for inference."
    di as txt "Validity requires long-run orthogonality of u_1t with (sigma_t, x_t) (Assumption 3)."
    if `"`e(bnote)'"' != "" {
        di as txt "Warning: `e(bnote)'."
    }

    if e(split_t) < . {
        local eta = 1 - `level'/100
        local lev : display %4.3g 100 - `level'
        local lev = strtrim("`lev'")
        local star " "
        if e(split_p) < `eta' local star "*"
        di
        di as txt "Split-sample test of equal error variance (Hansen 1992, Table 1)"
        di as txt "{hline 20}{c TT}{hline 57}"
        di as txt _col(21) "{c |}" _col(23) "sigma2 (1st half)" _col(42) "sigma2 (2nd half)" ///
            _col(62) "t-test" _col(71) "p-value"
        di as txt "{hline 20}{c +}{hline 57}"
        di as txt " residual variance" _col(21) "{c |}" as res _col(24) %14.4g e(split_s1) ///
            _col(43) %14.4g e(split_s2) _col(59) %9.3f e(split_t) _col(70) %7.3f e(split_p) ///
            as txt "`star'"
        di as txt "{hline 20}{c BT}{hline 57}"
        di as txt "t-test: HAC t-ratio of the second-half dummy in a regression of w_t^2 on (1, dummy),"
        di as txt "  Bartlett weights, lag " as res e(split_lag) as txt "; N(0,1), two-sided. * rejects at the `lev'% level."
    }
end
