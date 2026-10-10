*! thqreg 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold quantile regression with an unknown threshold: the threshold is
*! estimated at each requested quantile by minimising the check-function
*! objective, and the coefficients and standard errors reported at it come
*! from official Stata qreg, so they are exactly Stata's own.
*! Caner (2002) Econometric Theory 18:800-814, doi:10.1017/s0266466602183113
*! Galvao, Montes-Rojas & Olmo (2011) JTSA 32:253-267, doi:10.1111/j.1467-9892.2010.00696.x
*! Koenker & Bassett (1978) Econometrica 46:33-50, doi:10.2307/1913643

program define thqreg, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thqreg" error 301
        Display
        exit
    }

    syntax varlist(numeric fv ts min=1) [if] [in] ,  ///
        THRESHvar(varname numeric ts)                ///
        [ Quantile(numlist >0 <1 sort)               ///
          INVariant(varlist numeric fv ts)           ///
          TRIM(real 0.15)                            ///
          GRIDn(integer 50)                          ///
          MINOBS(integer 0)                          ///
          noCONStant                                 ///
          TEST                                       ///
          STAT(string)                               ///
          REPS(integer 0)                            ///
          BOOT(string)                               ///
          SEED(string)                               ///
          MAXIT(integer 25)                          ///
          QTOL(real 1e-10)                           ///
          VCE(string)                                ///
          QVARname(string)                           ///
          Level(cilevel) ]

    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `gridn' < 5 {
        display as error "{bf:gridn()} must be 5 or more"
        exit 198
    }
    if "`quantile'" == "" local quantile 0.5
    local ntau : word count `quantile'
    local taulist "`quantile'"
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
    local dotest  = cond("`test'"!="", 1, 0)
    local hascons = cond("`constant'"=="", 1, 0)
    if `hascons' == 0 {
        display as error "official {bf:qreg} does not allow {bf:noconstant}, and the"
        display as error "coefficients reported here come from {bf:qreg}, so"
        display as error "{bf:thqreg} cannot either"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} must be 0 or more"
        exit 198
    }
    if `dotest' == 0 & `reps' > 0 {
        display as error "{bf:reps()} has no effect without {bf:test}"
        exit 198
    }
    if "`vce'" == "" local vce robust
    if !inlist("`vce'", "robust", "iid") {
        display as error "vce() must be robust or iid"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    marksample touse
    markout `touse' `threshvar' `invariant'
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'

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
        display as error "no regressors whose coefficients could switch"
        exit 102
    }
    markout `touse' `xvars' `zvars'
    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)
    local qvar `threshvar'
    * a wrapper (thtqar) hands in a temporary threshold variable but wants the
    * real time-series expression printed and stored
    local qlabel = cond("`qvarname'" != "", "`qvarname'", "`threshvar'")

    * ---- the search, and the test, all in Mata
    _tk_drop __tk_qres __tk_qprof
    mata: tk_thqreg()
    tempname QR QP
    matrix `QR' = __tk_qres
    matrix `QP' = __tk_qprof
    local ng = __tk_ngrid
    _tk_drop __tk_qres __tk_qprof
    _tk_drop __tk_n __tk_ngrid

    * ---- the FINAL fit at each estimated threshold comes from official qreg,
    *      so the printed coefficients and standard errors are Stata's own and
    *      not this package's solver
    local kx : word count `xlist'
    local nsw = `kx' + `hascons'
    local firsttau : word 1 of `quantile'
    tempvar dlo dhi
    local post 0
    forvalues i = 1/`ntau' {
        local tau : word `i' of `quantile'
        local g = `QR'[`i',2]
        if `g' >= . continue
        capture drop __tkq_*
        tempname GAM
        scalar `GAM' = `QR'[`i',2]
        quietly generate byte __tkq_d1 = (`threshvar' <= `GAM') if `touse'
        * qreg insists on its own constant, so the design carries the
        * regime-1 INDICATOR rather than two regime constants, and the two
        * constants are recovered afterwards by a linear map:
        *   regime 1 constant = _cons + b(d1),   regime 2 constant = _cons
        * applied to b and to V, so both standard errors are correct.
        local rhs ""
        local nm 0
        foreach v of local xlist {
            local ++nm
            quietly generate double __tkq_a`nm' = `v' * __tkq_d1 if `touse'
            quietly generate double __tkq_b`nm' = `v' * (1 - __tkq_d1) if `touse'
            local rhs `rhs' __tkq_a`nm' __tkq_b`nm'
        }
        local rhs `rhs' __tkq_d1 `zlist'
        if "`vce'" == "robust" {
            quietly qreg `depv' `rhs' if `touse', quantile(`tau') vce(robust)
        }
        else {
            quietly qreg `depv' `rhs' if `touse', quantile(`tau')
        }
        if `i' == 1 {
            tempname braw Vraw TT b V
            matrix `braw' = e(b)
            matrix `Vraw' = e(V)
            local qsum = e(sum_adev)
            local qdf  = e(df_r)
            local nz : word count `zlist'
            local praw = colsof(`braw')
            local ptgt = 2*`kx' + 2 + `nz'
            matrix `TT' = J(`ptgt', `praw', 0)
            * qreg's raw vector is
            *   [ a1 b1 a2 b2 ... aK bK , d1 , z... , _cons ]
            * with a_j the LOWER-regime slope and b_j the UPPER one. Reorder
            * into two clean blocks so the coefficient table groups by regime
            * instead of alternating, and recover both regime constants:
            *   lower _cons = _cons + b(d1) ,  upper _cons = _cons
            local cd1 = 2*`kx' + 1
            forvalues j = 1/`kx' {
                matrix `TT'[`j', `=2*`j'-1'] = 1
                matrix `TT'[`=`kx'+1+`j'', `=2*`j''] = 1
            }
            matrix `TT'[`=`kx'+1', `cd1']  = 1
            matrix `TT'[`=`kx'+1', `praw'] = 1
            matrix `TT'[`=2*`kx'+2', `praw'] = 1
            forvalues j = 1/`nz' {
                matrix `TT'[`=2*`kx'+2+`j'', `=2*`kx'+1+`j'' ] = 1
            }
            matrix `b' = (`TT' * `braw'')'
            matrix `V' = `TT' * `Vraw' * `TT''
            local post 1
        }
    }
    capture drop __tkq_*
    if `post' == 0 {
        display as error "no admissible threshold at any requested quantile"
        exit 498
    }

    * ---- names. The transformed vector is: for each regressor its lower and
    *      upper slope interleaved, then the two regime constants, then the
    *      regime-invariant block.
    local cnm ""
    local cem ""
    foreach v of local xlist {
        local cnm `cnm' `v'
        local cem `cem' lower
    }
    local cnm `cnm' _cons
    local cem `cem' lower
    foreach v of local xlist {
        local cnm `cnm' `v'
        local cem `cem' upper
    }
    local cnm `cnm' _cons
    local cem `cem' upper
    foreach v of local zlist {
        local cnm `cnm' `v'
        local cem `cem' invariant
    }
    matrix colnames `b' = `cnm'
    matrix coleq    `b' = `cem'
    matrix colnames `V' = `cnm'
    matrix coleq    `V' = `cem'
    matrix rownames `V' = `cnm'
    matrix roweq    `V' = `cem'

    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`nobs')

    ereturn local cmd        "thqreg"
    ereturn local cmdline    "thqreg `0'"
    ereturn local title      "Threshold quantile regression"
    ereturn local model      "jump-quantile"
    ereturn local estimator  "check-function threshold search; qreg at the threshold"
    ereturn local depvar     "`depv'"
    ereturn local indepvars  "`xlist'"
    ereturn local invariant  "`zlist'"
    ereturn local threshold_var "`qlabel'"
    ereturn local quantiles  "`quantile'"
    ereturn local vcetype    = cond("`vce'"=="robust", "Robust", "")
    ereturn local vce        "`vce'"
    ereturn local properties "b V"
    ereturn local estat_cmd  "thqreg_estat"
    ereturn local predict    "thqreg_p"
    if `dotest' {
        ereturn local teststat "`stat'"
        ereturn local boot     "`boot'"
    }

    ereturn scalar N        = `nobs'
    ereturn scalar n_grid   = `ng'
    ereturn scalar n_tau    = `ntau'
    ereturn scalar tau      = `firsttau'
    ereturn scalar gamma    = `QR'[1,2]
    ereturn scalar obj      = `QR'[1,3]
    ereturn scalar obj0     = `QR'[1,4]
    ereturn scalar N_regime1 = `QR'[1,5]
    ereturn scalar N_regime2 = `QR'[1,6]
    ereturn scalar k_switch = `nsw'
    ereturn scalar trim     = `trim'
    ereturn scalar level    = `level'
    ereturn scalar hascons  = `hascons'
    if `dotest' {
        ereturn scalar lr       = `QR'[1,7]
        ereturn scalar lr_sup   = `QR'[1,7]
        ereturn scalar lr_ave   = `QR'[1,8]
        ereturn scalar lr_exp   = `QR'[1,9]
        ereturn scalar gamma_test = `QR'[1,10]
        if `QR'[1,11] < . {
            ereturn scalar p         = `QR'[1,11]
            ereturn scalar boot_reps = `QR'[1,12]
            ereturn scalar p_mcse    = sqrt(`QR'[1,11]*(1-`QR'[1,11])/`QR'[1,12])
        }
    }

    tempname M
    matrix `M' = `QR'
    matrix colnames `M' = tau gamma obj obj0 n1 n2 lr_sup lr_ave lr_exp gmax p reps
    ereturn matrix byquantile = `M'
    matrix `M' = `QP'
    local pn gamma
    forvalues i = 1/`ntau' {
        local ti : word `i' of `quantile'
        local pn `pn' q`=subinstr("`ti'",".","",.)'
    }
    matrix colnames `M' = `pn'
    ereturn matrix profile = `M'

    Display
end

* ----------------------------------------------------------------------
program define Display
    tempname Q
    matrix `Q' = e(byquantile)
    local nt = e(n_tau)
    display ""
    display as text "Threshold quantile regression" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Dependent variable: " as result "`e(depvar)'" _col(52) ///
        as text "Grid points" _col(68) "=" _col(71) as result %9.0f e(n_grid)
    display as text "  Threshold variable: " as result "`e(threshold_var)'" _col(52) ///
        as text "Quantiles" _col(68) "=" _col(71) as result %9.0f `nt'
    display ""
    display as text "{hline 78}"
    display as text "  The threshold by quantile"
    display as text "    tau" _col(14) "gamma" _col(28) "V(gamma)" _col(42) ///
        "V linear" _col(56) "n1" _col(64) "n2"
    display as text "{hline 78}"
    forvalues i = 1/`nt' {
        display as text "   " as result %5.3f `Q'[`i',1] ///
            _col(9) %12.6g `Q'[`i',2] _col(23) %12.6f `Q'[`i',3] ///
            _col(37) %12.6f `Q'[`i',4] _col(51) %7.0fc `Q'[`i',5] ///
            _col(60) %7.0fc `Q'[`i',6]
    }
    display as text "{hline 78}"
    if `Q'[1,7] < . {
        display as text "  H0: no threshold effect in that quantile (sup/ave/exp-LR)"
        display as text "    tau" _col(14) "`e(teststat)'-LR" _col(30) ///
            "argmax" _col(44) "boot p" _col(58) "MC s.e."
        forvalues i = 1/`nt' {
            display as text "   " as result %5.3f `Q'[`i',1] ///
                _col(10) %12.4f `Q'[`i',`=cond("`e(teststat)'"=="sup",7,cond("`e(teststat)'"=="ave",8,9))'] ///
                _col(25) %12.6g `Q'[`i',10] _col(40) %10.4f `Q'[`i',11] ///
                _col(54) %10.4f cond(`Q'[`i',11] < ., ///
                    sqrt(`Q'[`i',11]*(1-`Q'[`i',11])/`Q'[`i',12]), .)
        }
        display as text "{hline 78}"
        display as text "  LR(gamma) = 2(V_0 - V(gamma)) from the check-function objective."
        display as text "  The threshold is unidentified under this null, so it is not"
        display as text "  chi-square: the p-value is simulated from the LINEAR quantile"
        display as text "  regression with the regressors and the threshold variable held"
        display as text "  fixed (`e(boot)'). The sparsity 1/f(0) that a Wald version would"
        display as text "  need is a constant common to the statistic and to every draw, so"
        display as text "  it cancels in the p-value and is not estimated at all."
    }
    display ""
    display as text "  The threshold is estimated SEPARATELY at each quantile, because"
    display as text "  nothing requires the regimes of the median to be the regimes of"
    display as text "  the tenth percentile. A gamma that moves across quantiles is a"
    display as text "  finding, not an error."
    display ""
    display as text "  Coefficients below are for tau = " as result %5.3f e(tau) ///
        as text " only, and come from official"
    display as text "  {bf:qreg} at the estimated threshold, so the standard errors are"
    display as text "  Stata's own (vce(`e(vce)')). They do NOT account for gamma having"
    display as text "  been estimated; Caner (2002) gives the rate, and the confidence"
    display as text "  set for gamma itself is not implemented."
    display ""
    _coef_table, level(`=e(level)')
end
