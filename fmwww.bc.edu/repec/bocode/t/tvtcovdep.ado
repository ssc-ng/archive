*! tvtcovdep 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Variable selection in a threshold model with a covariate-dependent
*! threshold: chooses the explanatory variables, which of them SHIFT
*! between regimes, and which variables move the threshold -- all at once.
*!
*! Yang, L. (2023) "Variable selection in threshold model with a
*!   covariate-dependent threshold", Empirical Economics 65:189-202,
*!   doi:10.1007/s00181-022-02340-3
*!
*! Clean-room. The paper solves its l0 problem with mixed integer
*! programming through Gurobi; Stata has no MIO solver, so the paper's own
*! block coordinate descent is used with each block solved by EXHAUSTIVE
*! ENUMERATION. See validation/tvthresh/tvtcovdep_equation_map.md and the
*! help file, which both say so prominently.

program define tvtcovdep, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtcovdep" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric fv min=2) [if] [in] ,    ///
        THReshvar(varname numeric)                  ///
        Zvars(varlist numeric)                      ///
        [ LAMBDA(real -1)                           ///
          TRIM(real 0.15)                           ///
          GRIDn(integer 21)                         ///
          CYCles(integer 3)                         ///
          REFine(integer 2)                         ///
          ITerate(integer 3)                        ///
          MAXSubsets(integer 200000)                ///
          SELECTCONS                                ///
          noCONStant                                ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        display as error "the paper uses 0.15, which is the default"
        exit 198
    }
    if `gridn' < 5 {
        display as error "{bf:gridn()} must be at least 5"
        exit 198
    }
    if `cycles' < 1 | `iterate' < 1 | `refine' < 1 {
        display as error "{bf:cycles()}, {bf:refine()} and" ///
            " {bf:iterate()} must be at least 1"
        exit 198
    }
    if `maxsubsets' < 1024 {
        display as error "{bf:maxsubsets()} must be at least 1024"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar' `zvars'
    quietly count if `touse'
    local nobs = r(N)

    local nx : word count `xvars'
    local nz : word count `zvars'
    local px = `nx' + ("`constant'" == "")
    if `nobs' < 4*(2*`px' + `nz') {
        display as error "too few observations (`nobs') to select among" ///
            " `=2*`px'+`nz'' candidate terms"
        exit 2001
    }
    if 2^(2*`px') > `maxsubsets' {
        display as error "`=2*`px'' slope candidates means" ///
            " 2^`=2*`px'' = `=2^(2*`px')' subsets,"
        display as error "above {bf:maxsubsets(`maxsubsets')}. Raise it" ///
            " if you are willing to wait,"
        display as error "or reduce the candidate list. This command" ///
            " enumerates exhaustively"
        display as error "rather than approximating, so the cost is real."
        exit 198
    }
    if 2^`nz' > `maxsubsets' {
        display as error "`nz' threshold candidates means 2^`nz' subsets," ///
            " above {bf:maxsubsets()}"
        exit 198
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is the threshold variable and" ///
                " cannot also be a regressor"
            exit 198
        }
    }

    * ---- lambda. The paper: "in applications we can set
    *      lambda = sigma^2 log(T)/T as BIC can lead to a consistent model
    *      selection". sigma^2 comes from the full, unselected model.
    if `lambda' < 0 {
        tempvar dd
        quietly regress `depv' `xvars' if `touse', `constant'
        local s2 = e(rss)/e(df_r)
        local lambda = `s2' * log(`nobs') / `nobs'
        local lamauto 1
    }
    else local lamauto 0

    if "`selectcons'" != "" & "`constant'" != "" {
        display as error "{bf:selectcons} and {bf:noconstant} together ask" ///
            " for a constant to be selected"
        display as error "when there is no constant to select"
        exit 198
    }

    local qvar "`threshvar'"
    local noconstant "`constant'"
    _tvt_drop

    mata: tvt_covdep()

    tempname G0 SSR SSR0 S2 CRIT LAM N1 N2 NSEL NXS NZS NVIS IT GRD MINN
    tempname STEP
    scalar `G0'   = __tvt_cd_g0
    scalar `SSR'  = __tvt_cd_ssr
    scalar `SSR0' = __tvt_cd_ssr0
    scalar `S2'   = __tvt_cd_s2
    scalar `CRIT' = __tvt_cd_crit
    scalar `LAM'  = __tvt_cd_lam
    scalar `N1'   = __tvt_cd_n1
    scalar `N2'   = __tvt_cd_n2
    scalar `NSEL' = __tvt_cd_nsel
    scalar `NXS'  = __tvt_cd_nx
    scalar `NZS'  = __tvt_cd_nz
    scalar `NVIS' = __tvt_cd_nvis
    scalar `IT'   = __tvt_cd_it
    scalar `GRD'  = __tvt_cd_greedy
    scalar `MINN' = __tvt_cd_minn
    scalar `STEP' = __tvt_cd_step
    tempname BM SELM ZSELM G1M PM
    matrix `BM'    = __tvt_cd_b
    matrix `SELM'  = __tvt_cd_sel
    matrix `ZSELM' = __tvt_cd_zsel
    matrix `G1M'   = __tvt_cd_g1
    matrix `PM'    = __tvt_cd_path
    _tvt_drop

    * -------------------------------------------------------- the names
    local nm
    if "`constant'" == "" local nm level:_cons
    foreach v of local xvars {
        local nm `nm' level:`v'
    }
    if "`constant'" == "" local nm `nm' shift:_cons
    foreach v of local xvars {
        local nm `nm' shift:`v'
    }
    matrix colnames `BM' = `nm'
    matrix colnames `SELM' = `nm'
    matrix colnames `ZSELM' = `zvars'
    matrix colnames `G1M' = `zvars'

    * No covariance is reported (see the note at the end of Display), but
    * ereturn post still needs one, and it must carry the SAME names as b
    * or Stata answers "name conflict", r(507).
    tempname VM
    local k = colsof(`BM')
    matrix `VM' = J(`k', `k', 0)
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    local nused = `nobs'
    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nused')
    ereturn scalar N         = `nobs'
    ereturn scalar gamma0    = `G0'
    ereturn scalar ssr       = `SSR'
    ereturn scalar ssr_full  = `SSR0'
    ereturn scalar sigma2    = `S2'
    ereturn scalar crit      = `CRIT'
    ereturn scalar lambda    = `LAM'
    ereturn scalar lambda_auto = `lamauto'
    ereturn scalar N_lower   = `N1'
    ereturn scalar N_upper   = `N2'
    ereturn scalar k_sel     = `NSEL'
    ereturn scalar k_slope   = `NXS'
    ereturn scalar k_thresh  = `NZS'
    ereturn scalar n_visited = `NVIS'
    ereturn scalar iterations = `IT'
    ereturn scalar greedy    = `GRD'
    ereturn scalar minreg    = `MINN'
    ereturn scalar trim      = `trim'
    ereturn scalar refine    = `refine'
    ereturn scalar g1step    = `STEP'
    ereturn scalar selectcons = ("`selectcons'" != "")
    ereturn local  cmd       "tvtcovdep"
    ereturn local  cmdline   "tvtcovdep `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  indepvars "`xvars'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  zvars     "`zvars'"
    ereturn local  title     "Variable selection, covariate-dependent threshold"
    ereturn matrix selected  = `SELM'
    ereturn matrix zselected = `ZSELM'
    ereturn matrix gamma1    = `G1M'
    ereturn matrix path      = `PM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    tempname SEL ZSEL G1
    matrix `SEL'  = e(selected)
    matrix `ZSEL' = e(zselected)
    matrix `G1'   = e(gamma1)
    local xv "`e(indepvars)'"
    local zv "`e(zvars)'"
    local nx : word count `xv'
    local nz : word count `zv'
    local kk = colsof(`SEL')/2

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Yang (2023), Empirical Economics" ///
        _col(52) as text "Terms selected" _col(68) "=" ///
        _col(71) as result %9.0f e(k_sel)
    display as text "Threshold variable: " as result "`e(threshvar)'" ///
        _col(52) as text "Models visited" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_visited)
    display ""
    display as text "{hline 78}"
    display as text "  SELECTED: level equation" _col(40) "shift between regimes"
    local j 0
    if "`e(indepvars)'" != "" {
        local names ""
        if `kk' > `nx' local names "_cons"
        local names "`names' `xv'"
    }
    forvalues i = 1/`kk' {
        local nmi : word `i' of `names'
        local inL = `SEL'[1,`i']
        local inS = `SEL'[1,`=`i'+`kk'']
        display as text "    " %-22s "`nmi'" ///
            cond(`inL', "{txt}   yes", "{txt}    . ") ///
            _col(40) cond(`inS', "{txt}   yes", "{txt}    . ")
    }
    if "`e(indepvars)'" != "" & `kk' > `nx' & !e(selectcons) {
        display as text "    the level constant was kept in rather than" ///
            " selected over;"
        display as text "    {bf:selectcons} applies the paper's penalty to" ///
            " it as well"
    }
    display as text "{hline 78}"
    display as text "  THE THRESHOLD"
    local eq = "    gamma(t) = " + string(e(gamma0), "%9.0g")
    local anyz 0
    forvalues j = 1/`nz' {
        if `ZSEL'[1,`j'] {
            local zz : word `j' of `zv'
            local cf = `G1'[1,`j']
            local sgn = cond(`cf' < 0, " - ", " + ")
            local eq = "`eq'" + "`sgn'" + string(abs(`cf'), "%9.0g") + " `zz'"
            local anyz 1
        }
    }
    display as text "`eq'"
    if !`anyz' {
        display as text "    no threshold variable was selected, so the" ///
            " threshold is CONSTANT"
    }
    display as text "    observations below / above" _col(34) as result ///
        %6.0f e(N_lower) as text " /" as result %6.0f e(N_upper)
    display as text "{hline 78}"
    display as text "  Coefficients at the selected model"
    display as text "{hline 78}"
    matrix list e(b), noheader format(%10.4f)
    display as text "{hline 78}"
    display as text "  l0 criterion" _col(26) as result %14.6f e(crit) ///
        as text "   lambda " as result %12.8f e(lambda) ///
        cond(e(lambda_auto), " (BIC)", " (given)")
    display as text "  SSR, selected" _col(26) as result %14.4f e(ssr) ///
        as text "   full model " as result %12.4f e(ssr_full)
    display as text "  BCD iterations" _col(26) as result %14.0f e(iterations)
    display as text "{hline 78}"
    if e(greedy) {
        display as error "  The subset enumeration was abandoned and the" ///
            " answer is NOT the exact"
        display as error "  block minimiser. Raise {bf:maxsubsets()} or" ///
            " shorten the candidate list."
        display as text "{hline 78}"
    }
    display as text "  {bf:NO standard errors are reported.} They would" ///
        " be conditional on the"
    display as text "  selection and would ignore it, which is the" ///
        " standard objection to"
    display as text "  post-selection inference. The paper derives no" ///
        " post-selection"
    display as text "  distribution and neither does this command. Refit" ///
        " the selected"
    display as text "  specification with {helpb tvtboundary} on" ///
        " independent data if you"
    display as text "  need inference."
end
