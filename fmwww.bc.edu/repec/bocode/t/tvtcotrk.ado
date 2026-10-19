*! tvtcotrk 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Conditional threshold regression kink: a CONTINUOUS kink at a threshold
*! that is a rolling quantile of the threshold variable's recent past.
*!
*! Yang, L. "Conditional Threshold Regression Kink (CoTRK)", SSRN Working
*!   Paper, doi:10.2139/ssrn.4704637  (Crossref 2026-10-13: posted-content,
*!   no journal publication. The PDF is dated April 2022; 2024 is only the
*!   SSRN posting year.)
*!
*! Clean-room -- no code ships with this paper and none exists. Validated
*! against the paper's Table 1, including its super-consistency property.
*! See validation/tvthresh/tvtcotrk_equation_map.md.

program define tvtcotrk, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtcotrk" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric ts min=2) [if] [in] ,    ///
        [ MMIN(integer 3)                           ///
          MMAX(integer 15)                          ///
          TRIM(real 0.15)                           ///
          REPS(integer 0)                           ///
          Level(cilevel) ]

    gettoken depv rest : varlist
    gettoken xv  zvars : rest

    if `mmin' < 2 {
        display as error "{bf:mmin()} must be at least 2"
        exit 198
    }
    if `mmax' <= `mmin' {
        display as error "{bf:mmax()} must exceed {bf:mmin()}"
        display as error "they bound the memory length m, which this" ///
            " model ESTIMATES"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} cannot be negative"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xv' `zvars'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < `mmax' + 10 {
        display as error "too few observations (`nobs') for" ///
            " {bf:mmax(`mmax')}"
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
                display as error "the threshold is a quantile of a" ///
                    " ROLLING WINDOW, so the series"
                display as error "must be equally spaced."
                exit 459
            }
        }
    }

    local xvar  "`xv'"
    _tvt_drop

    if `reps' > 0 {
        display as text "running `reps' wild bootstrap replications;" ///
            " each one re-runs the"
        display as text "whole (m,c) search and Hansen's grid -- see" ///
            " the help."
    }

    mata: tvt_cotrk()

    tempname MH CH SSR SSR0 SSRC MUC NOB SH NC NF F1C F1T F2
    scalar `MH'   = __tvt_rk_m
    scalar `CH'   = __tvt_rk_c
    scalar `SSR'  = __tvt_rk_ssr
    scalar `SSR0' = __tvt_rk_ssr0
    scalar `SSRC' = __tvt_rk_ssrc
    scalar `MUC'  = __tvt_rk_muc
    scalar `NOB'  = __tvt_rk_nobs
    scalar `SH'   = __tvt_rk_sh
    scalar `NC'   = __tvt_rk_ncand
    scalar `NF'   = __tvt_rk_nfeas
    scalar `F1C'  = __tvt_rk_f1c
    scalar `F1T'  = __tvt_rk_f1t
    scalar `F2'   = __tvt_rk_f2
    tempname BM VM GR PVM
    matrix `BM'  = __tvt_rk_b
    matrix `VM'  = __tvt_rk_V
    matrix `GR'  = __tvt_rk_grid
    matrix `PVM' = __tvt_rk_pv
    _tvt_drop

    local nm below above _cons
    foreach v of local zvars {
        local nm `nm' `v'
    }
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'

    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nobs')
    ereturn scalar N        = `nobs'
    ereturn scalar N_eff    = `NOB'
    ereturn scalar m        = `MH'
    ereturn scalar c        = `CH'
    ereturn scalar mmin     = `mmin'
    ereturn scalar mmax     = `mmax'
    ereturn scalar share_hi = `SH'
    ereturn scalar ssr      = `SSR'
    ereturn scalar ssr_lin  = `SSR0'
    ereturn scalar ssr_const = `SSRC'
    ereturn scalar gamma_const = `MUC'
    ereturn scalar n_cand   = `NC'
    ereturn scalar n_feasible = `NF'
    ereturn scalar trim     = `trim'
    ereturn scalar reps     = `reps'
    ereturn scalar F1C      = `F1C'
    ereturn scalar F1T      = `F1T'
    ereturn scalar F2       = `F2'
    if `reps' > 0 {
        ereturn scalar p_F1C = `PVM'[1,1]
        ereturn scalar p_F1T = `PVM'[1,2]
        ereturn scalar p_F2  = `PVM'[1,3]
    }
    ereturn local  cmd       "tvtcotrk"
    ereturn local  cmdline   "tvtcotrk `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  threshvar "`xv'"
    ereturn local  covars    "`zvars'"
    ereturn local  title     "Conditional threshold regression kink (CoTRK)"
    ereturn matrix grid = `GR'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Yang (SSRN 4704637)" ///
        _col(52) as text "Used in fit" _col(68) "=" ///
        _col(71) as result %9.0fc e(N_eff)
    display as text "Kink variable: " as result "`e(threshvar)'" ///
        _col(52) as text "Candidates" _col(68) "=" ///
        _col(71) as result %9.0f e(n_cand)
    display ""
    display as text "{hline 78}"
    display as text "  The kink sits at a ROLLING QUANTILE of" ///
        " `e(threshvar)':"
    display as text "    mu(t) = the " as result e(c)*e(m) ///
        as text "-th smallest of its last " as result e(m) ///
        as text " values"
    display as text "{hline 78}"
    display as text "    memory m (estimated)" _col(32) as result %12.0f e(m)
    display as text "    percentile c (estimated)" _col(32) as result ///
        %12.4f e(c)
    display as text "    share at or above mu" _col(32) as result %12.4f ///
        e(share_hi)
    display as text "    constant-threshold kink at" _col(32) as result ///
        %12.6g e(gamma_const)
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  SSR: linear " as result %11.4f e(ssr_lin) ///
        as text "   constant kink " as result %11.4f e(ssr_const) ///
        as text "   CoTRK " as result %11.4f e(ssr)
    display as text "{hline 78}"
    display as text "  Tests" _col(34) "statistic" _col(50) "p-value"
    display as text "    F1C  linear vs constant kink" _col(34) ///
        as result %11.4f e(F1C) _col(48) ///
        cond(e(reps)>0, string(e(p_F1C), "%9.4f"), "       --")
    display as text "    F1T  linear vs CoTRK" _col(34) ///
        as result %11.4f e(F1T) _col(48) ///
        cond(e(reps)>0, string(e(p_F1T), "%9.4f"), "       --")
    display as text "    F2   constant vs CoTRK" _col(34) ///
        as result %11.4f e(F2) _col(48) ///
        cond(e(reps)>0, string(e(p_F2), "%9.4f"), "       --")
    display as text "{hline 78}"
    if e(reps) == 0 {
        display as text "  All three have NON-STANDARD null" ///
            " distributions. Specify {bf:reps()}"
        display as text "  for wild bootstrap p-values; until then they" ///
            " are descriptive only."
    }
    else {
        display as text "  {bf:Linearity is rejected if EITHER F1C or" ///
            " F1T rejects}, which is"
        display as text "  the paper's rule. Note that two tests at the" ///
            " 5% level is not one"
        display as text "  test at the 5% level: the pair over-rejects" ///
            " relative to either."
        display as text "  F2 asks the separate question of whether the" ///
            " threshold MOVES."
    }
    display as text "{hline 78}"
    display as text "  No interval is reported for m or c: the paper" ///
        " derives no asymptotic"
    display as text "  distribution for them. At moderate samples they" ///
        " are recovered exactly"
    display as text "  in simulation, which is a stronger statement" ///
        " than an interval."
end
