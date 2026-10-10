*! thqkink 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Bent-line (kink) quantile regression with one or several unknown kink
*! points. The fitted conditional quantile is CONTINUOUS in the kink variable
*! and changes slope at each estimated kink.
*! The kinks are found by minimising the check-function objective; the
*! coefficients and standard errors reported at them come from official Stata
*! qreg, so they are exactly Stata's own.
*! Li, Wei, Chappell & He (2011) Biometrics 67:242-249, doi:10.1111/j.1541-0420.2010.01436.x
*! Zhong, Wan & Zhang (2022) JBES 40:1123-1139, doi:10.1080/07350015.2021.1901720
*! Muggeo (2003) Statistics in Medicine 22:3055-3071, doi:10.1002/sim.1545

program define thqkink, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "thqkink" error 301
        Display
        exit
    }

    syntax varname(numeric ts) [if] [in] ,           ///
        KINKvar(varname numeric ts)                  ///
        [ NKinks(integer 1)                          ///
          Quantile(numlist >0 <1 sort)               ///
          INVariant(varlist numeric fv ts)           ///
          TRIM(real 0.15)                            ///
          GRIDn(integer 50)                          ///
          REFINE(integer 1)                          ///
          MINOBS(integer 0)                          ///
          TEST                                       ///
          STAT(string)                               ///
          REPS(integer 0)                            ///
          BOOT(string)                               ///
          SEED(string)                               ///
          MAXIT(integer 25)                          ///
          QTOL(real 1e-10)                           ///
          VCE(string)                                ///
          Level(cilevel) ]

    if `nkinks' < 1 | `nkinks' > 4 {
        display as error "{bf:nkinks()} must be between 1 and 4"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `gridn' < 5 {
        display as error "{bf:gridn()} must be 5 or more"
        exit 198
    }
    if `refine' < 0 {
        display as error "{bf:refine()} must be 0 or more"
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
    local dotest = cond("`test'"!="", 1, 0)
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
    local refinen `refine'

    local depv `varlist'
    marksample touse
    markout `touse' `depv' `kinkvar' `invariant'

    local zlist ""
    local zvars ""
    if "`invariant'" != "" {
        fvexpand `invariant' if `touse'
        local zlist `r(varlist)'
        fvrevar `zlist' if `touse'
        local zvars `r(varlist)'
        markout `touse' `zvars'
    }
    local kvar `kinkvar'
    quietly count if `touse'
    if r(N) < 30 {
        display as error "too few usable observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

    _tk_drop __tk_kres __tk_kg __tk_ksel __tk_kprof
    mata: tk_thqkink()
    tempname KR KG KS KP
    matrix `KR' = __tk_kres
    matrix `KG' = __tk_kg
    matrix `KS' = __tk_ksel
    matrix `KP' = __tk_kprof
    local ng = __tk_ngrid
    _tk_drop __tk_kres __tk_kg __tk_ksel __tk_kprof
    _tk_drop __tk_n __tk_ngrid

    if `KR'[1,2] >= . {
        display as error "no admissible set of `nkinks' kink(s) at the first quantile:"
        display as error "every candidate left a segment too thin. Lower nkinks() or trim()."
        exit 498
    }

    * ---- the final fit at the estimated kinks comes from official qreg
    local firsttau : word 1 of `quantile'
    capture drop __tkk_*
    local rhs `kvar'
    forvalues k = 1/`nkinks' {
        tempname G`k'
        scalar `G`k'' = `KG'[1,`k']
        quietly generate double __tkk_s`k' = ///
            cond(`kvar' - `G`k'' > 0, `kvar' - `G`k'', 0) if `touse'
        local rhs `rhs' __tkk_s`k'
    }
    local rhs `rhs' `zlist'
    if "`vce'" == "robust" {
        quietly qreg `depv' `rhs' if `touse', quantile(`firsttau') vce(robust)
    }
    else {
        quietly qreg `depv' `rhs' if `touse', quantile(`firsttau')
    }
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local qobj = e(sum_adev)
    capture drop __tkk_*

    * ---- names: the base slope, one slope change per kink, invariants, _cons
    local cn `kvar'
    forvalues k = 1/`nkinks' {
        local cn `cn' slope_change`k'
    }
    local cn `cn' `zlist' _cons
    matrix colnames `b' = `cn'
    matrix colnames `V' = `cn'
    matrix rownames `V' = `cn'

    ereturn post `b' `V', esample(`touse') depname(`depv') obs(`nobs')

    ereturn local cmd        "thqkink"
    ereturn local cmdline    "thqkink `0'"
    ereturn local title      "Bent-line quantile regression"
    ereturn local model      "kink-quantile"
    ereturn local estimator  "check-function kink search; qreg at the kinks"
    ereturn local depvar     "`depv'"
    ereturn local kink_var   "`kvar'"
    ereturn local threshold_var "`kvar'"
    ereturn local invariant  "`zlist'"
    ereturn local quantiles  "`quantile'"
    ereturn local vcetype    = cond("`vce'"=="robust", "Robust", "")
    ereturn local vce        "`vce'"
    ereturn local properties "b V"
    ereturn local estat_cmd  "thqkink_estat"
    ereturn local predict    "thqkink_p"
    if `dotest' {
        ereturn local teststat "`stat'"
        ereturn local boot     "`boot'"
    }

    ereturn scalar N       = `nobs'
    ereturn scalar nkinks  = `nkinks'
    ereturn scalar n_tau   = `ntau'
    ereturn scalar tau     = `firsttau'
    ereturn scalar n_grid  = `ng'
    ereturn scalar obj     = `KR'[1,2]
    ereturn scalar obj0    = `KR'[1,3]
    ereturn scalar trim    = `trim'
    ereturn scalar level   = `level'
    forvalues k = 1/`nkinks' {
        ereturn scalar kink`k' = `KG'[1,`k']
    }
    ereturn scalar gamma   = `KG'[1,1]
    if `dotest' {
        ereturn scalar lr_sup = `KR'[1,4]
        ereturn scalar lr_ave = `KR'[1,5]
        ereturn scalar lr_exp = `KR'[1,6]
        ereturn scalar lr     = `KR'[1,`=3+`statnum'']
        ereturn scalar gamma_test = `KR'[1,7]
        if `KR'[1,8] < . {
            ereturn scalar p         = `KR'[1,8]
            ereturn scalar boot_reps = `KR'[1,9]
            ereturn scalar p_mcse    = sqrt(`KR'[1,8]*(1-`KR'[1,8])/`KR'[1,9])
        }
    }

    tempname M
    matrix `M' = `KR'
    matrix colnames `M' = tau obj obj0 lr_sup lr_ave lr_exp gmax p reps
    ereturn matrix byquantile = `M'
    matrix `M' = `KG'
    local kn ""
    forvalues k = 1/`nkinks' {
        local kn `kn' kink`k'
    }
    matrix colnames `M' = `kn'
    ereturn matrix kinks = `M'
    matrix `M' = `KS'
    matrix colnames `M' = tau K obj bic sbic
    ereturn matrix select = `M'
    matrix `M' = `KP'
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
    tempname K KG S
    matrix `K'  = e(byquantile)
    matrix `KG' = e(kinks)
    matrix `S'  = e(select)
    local nt = e(n_tau)
    local nk = e(nkinks)

    display ""
    display as text "Bent-line quantile regression" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "  Dependent variable: " as result "`e(depvar)'" _col(52) ///
        as text "Kinks" _col(68) "=" _col(71) as result %9.0f `nk'
    display as text "  Kink variable: " as result "`e(kink_var)'" _col(52) ///
        as text "Grid points" _col(68) "=" _col(71) as result %9.0f e(n_grid)
    display as text "  Quantiles: " as result "`e(quantiles)'"
    display ""
    display as text "{hline 78}"
    display as text "  Kink location(s) by quantile"
    display as text "    tau" _continue
    forvalues k = 1/`nk' {
        display as text _col(`=6+14*`k'') %13s "kink `k'" _continue
    }
    display as text _col(`=10+14*`=`nk'+1'') "V(kinks)" _col(`=24+14*`=`nk'+1'') "V linear"
    display as text "{hline 78}"
    forvalues i = 1/`nt' {
        display as text "   " as result %5.3f `K'[`i',1] _continue
        forvalues k = 1/`nk' {
            display as result _col(`=6+14*`k'') %13.6g `KG'[`i',`k'] _continue
        }
        display as result _col(`=10+14*`=`nk'+1'') %12.6f `K'[`i',2] ///
            _col(`=24+14*`=`nk'+1'') %12.6f `K'[`i',3]
    }
    display as text "{hline 78}"
    if `K'[1,4] < . {
        display as text "  H0: " as result "`=`nk'-1'" as text ///
            " kink(s) against " as result "`nk'" as text ///
            " (sup/ave/exp-LR, bootstrap p)"
        display as text "    tau" _col(16) "`e(teststat)'-LR" _col(32) ///
            "argmax" _col(48) "boot p" _col(62) "MC s.e."
        forvalues i = 1/`nt' {
            local sc = cond("`e(teststat)'"=="ave", 5, cond("`e(teststat)'"=="exp", 6, 4))
            display as text "   " as result %5.3f `K'[`i',1] ///
                _col(12) %12.4f `K'[`i',`sc'] _col(27) %12.6g `K'[`i',7] ///
                _col(43) %10.4f `K'[`i',8] _col(57) %10.4f ///
                cond(`K'[`i',8] < ., sqrt(`K'[`i',8]*(1-`K'[`i',8])/`K'[`i',9]), .)
        }
        display as text "{hline 78}"
        display as text "  LR(g) = 2(V_null - V(g)). With nkinks(1) the null is a STRAIGHT"
        display as text "  LINE in `e(kink_var)'. The extra kink is unidentified under the"
        display as text "  null, so this is not chi-square and the p-value is simulated"
        display as text "  with `e(kink_var)' held fixed (`e(boot)')."
    }
    display as text "  How many kinks? (lower is better; see the help on the penalty)"
    display as text "    tau" _col(12) "K" _col(22) "objective" _col(40) ///
        "BIC" _col(56) "sBIC"
    forvalues r = 1/`=rowsof(`S')' {
        if `S'[`r',3] < . {
            display as text "   " as result %5.3f `S'[`r',1] ///
                _col(10) %3.0f `S'[`r',2] _col(16) %14.6f `S'[`r',3] ///
                _col(32) %14.3f `S'[`r',4] _col(48) %14.3f `S'[`r',5]
        }
    }
    display as text "{hline 78}"
    display as text "  The fitted quantile is CONTINUOUS at every kink: the slope changes"
    display as text "  there, the level does not. {bf:slope_change}{it:k} is the change in"
    display as text "  slope at kink {it:k}, so the slope on segment {it:k}+1 is"
    display as text "  `e(kink_var)' plus the slope changes up to {it:k}. A slope change of"
    display as text "  zero means that kink is not doing anything."
    display ""
    display as text "  Coefficients are for tau = " as result %5.3f e(tau) ///
        as text " and come from official {bf:qreg} at"
    display as text "  the estimated kinks, so the standard errors are Stata's own"
    display as text "  (vce(`e(vce)')). They condition on the kinks: see {bf:help thqkink}."
    display ""
    _coef_table, level(`=e(level)')
end
