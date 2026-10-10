*! thqtest 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold-existence tests in QUANTILE regression.
*!
*!   thqtest y x, threshvar(q) quantile(0.5)        sup-score at one tau
*!   thqtest y x, threshvar(q) quantiles(0.1(0.1)0.9) uniform over a set
*!
*! See thqtest.sthlp. The two nulls are different and the help says so at
*! length: a threshold can be invisible at the median and plain in the
*! tails, which is the usual reason to fit a quantile threshold model at
*! all, and a test run at tau = 0.5 alone would miss it.

program define thqtest, rclass
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] , ///
        THRESHvar(varname numeric ts fv)             ///
        [ Quantile(real -1)                          ///
          QUANTiles(numlist >0 <1 sort)              ///
          TRIM(real 0.15)                            ///
          GRIDn(integer 0)                           ///
          MINOBS(integer 0)                          ///
          noCONStant                                 ///
          REPS(integer 499)                          ///
          SEED(string)                               ///
          MAXIT(integer 200)                         ///
          QTOL(real 1e-8)                            ///
          Level(cilevel)                             ///
          GRaph BINs(integer 30) SAVing(string asis) * ]

    * ---- exactly one of quantile() and quantiles()
    local nq : word count `quantiles'
    if `quantile' > 0 & `nq' > 0 {
        display as error "specify {bf:quantile()} for a single quantile OR"
        display as error "{bf:quantiles()} for a set, not both. They test"
        display as error "DIFFERENT nulls -- see the help."
        exit 198
    }
    if `quantile' <= 0 & `nq' == 0 local quantile 0.5
    if `quantile' > 0 {
        if `quantile' >= 1 {
            display as error "{bf:quantile()} must be in (0, 1)"
            exit 198
        }
        local taulist `quantile'
        local moden 1
    }
    else {
        if `nq' < 2 {
            display as error "{bf:quantiles()} needs at least two quantiles."
            display as error "For one, use {bf:quantile()} -- the uniform test"
            display as error "over a single point IS the single-quantile test,"
            display as error "and calling it uniform would overstate it."
            exit 198
        }
        local taulist `quantiles'
        local moden 2
    }

    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `reps' < 100 {
        display as error "{bf:reps()} below 100 gives a p-value with no useful"
        display as error "precision. The multiplier simulation is cheap here"
        display as error "-- it refits nothing -- so there is no reason to"
        display as error "economise on it."
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    gettoken depv xlist : varlist
    local hascons = cond("`constant'"=="", 1, 0)
    if "`xlist'" == "" & `hascons' == 0 {
        display as error "no regressors: specify some, or drop {bf:noconstant}"
        exit 198
    }

    * resolve any time-series or factor notation
    local qvar "`threshvar'"
    capture fvrevar `threshvar'
    if !_rc local qvar "`r(varlist)'"
    local xvars ""
    if "`xlist'" != "" {
        fvrevar `xlist'
        local xvars "`r(varlist)'"
    }

    marksample touse
    markout `touse' `depv' `xvars' `qvar'
    quietly count if `touse'
    if r(N) < 40 {
        display as error "too few observations (`r(N)')"
        exit 2001
    }
    local nobs = r(N)

    mata: tk_thqtest()

    if __tk_qtfail == 1 {
        _tk_drop
        display as error "the design has no columns"
        exit 198
    }
    if __tk_qtfail == 2 {
        _tk_drop
        display as error "the trimmed grid has fewer than 3 points: lower"
        display as error "{bf:trim()} or use a longer sample"
        exit 498
    }
    if __tk_qtfail == 3 {
        _tk_drop
        display as error "the restricted quantile regression did not converge."
        display as error "That is the fit under the NULL, so without it there"
        display as error "is no test. Raise {bf:maxit()} or check for"
        display as error "collinearity."
        exit 498
    }
    if __tk_qtfail == 4 {
        _tk_drop
        display as error "the statistic could not be computed at any"
        display as error "admissible threshold"
        exit 498
    }

    tempname ST GM TAU P NN NG NT PATH TAB BD
    scalar `ST'  = __tk_qtstat
    scalar `GM'  = __tk_qtgam
    scalar `TAU' = __tk_qttau
    scalar `P'   = __tk_qtp
    scalar `NN'  = __tk_qtn
    scalar `NG'  = __tk_qtng
    scalar `NT'  = __tk_qtnt
    local haspath = 0
    local hastab  = 0
    local hasbd   = 0
    capture confirm matrix __tk_qtpath
    if !_rc {
        matrix `PATH' = __tk_qtpath
        local haspath = 1
    }
    capture confirm matrix __tk_qttab
    if !_rc {
        matrix `TAB' = __tk_qttab
        local hastab = 1
    }
    capture confirm matrix __tk_qtbd
    if !_rc {
        matrix `BD' = __tk_qtbd
        local hasbd = 1
    }
    _tk_drop

    if `haspath' matrix colnames `PATH' = gamma score
    if `hastab'  matrix colnames `TAB'  = tau sup gamma

    if `moden' == 1 {
        display _n as text "Sup-score test for a covariate threshold in quantile regression"
        display as text "  Zhang, Wang and Zhu (2014)"
    }
    else {
        display _n as text "Uniform sup-score test of linearity against threshold effects"
        display as text "  Galvao, Kato, Montes-Rojas and Olmo (2014)"
    }
    display as text "{hline 74}"
    display as text "  observations" _col(50) as result %22.0f `NN'
    display as text "  thresholds searched" _col(50) as result %22.0f `NG'
    if `moden' == 2 ///
        display as text "  quantiles searched" _col(50) as result %22.0f `NT'
    display as text "  trimming" _col(50) as result %22.4f `trim'
    display as text "  multiplier replications" _col(50) as result %22.0f `reps'
    display as text "{hline 74}"
    if `moden' == 1 {
        display as text "  quantile tested" _col(50) as result %22.4f `TAU'
        display as text "  sup-score statistic" _col(50) as result %22.4f `ST'
        display as text "  argmax threshold" _col(50) as result %22.6g `GM'
    }
    else {
        display as text "  uniform sup-score statistic" _col(50) as result %22.4f `ST'
        display as text "  attained at quantile" _col(50) as result %22.4f `TAU'
        display as text "  and threshold" _col(50) as result %22.6g `GM'
    }
    display as text "  p-value" _col(50) as result %22.4f `P'
    display as text "  Monte Carlo s.e." _col(50) as result %22.4f ///
        sqrt(`P'*(1-`P')/`reps')
    display as text "{hline 74}"

    if `hastab' {
        display as text "  per-quantile statistics:"
        display as text "      tau          sup-score      argmax threshold"
        forvalues i = 1/`=rowsof(`TAB')' {
            if `TAB'[`i',2] >= . {
                display as text %9.3f `TAB'[`i',1] as text "   (not computed)"
                continue
            }
            display as result %9.3f `TAB'[`i',1] %17.4f `TAB'[`i',2] ///
                %22.6g `TAB'[`i',3]
        }
        display as text "{hline 74}"
        display as text "  Read this column before the single p-value. If one"
        display as text "  quantile dominates, the threshold effect is in that"
        display as text "  part of the distribution and not in the mean -- "
        display as text "  which is the finding, and it is invisible in a"
        display as text "  conditional-mean threshold model."
    }

    display as text ""
    display as text "  The statistic is a SCORE: it is built from the"
    display as text "  subgradient of the check function at the RESTRICTED"
    display as text "  (no-threshold) fit, so nothing is estimated under the"
    display as text "  alternative and no threshold is ever fitted. That is"
    display as text "  why the multiplier simulation refits nothing and why"
    display as text "  `reps' replications cost almost nothing."
    display as text ""
    if `moden' == 2 {
        display as text "  The p-value is corrected for searching over BOTH the"
        display as text "  threshold grid and the quantile set: every"
        display as text "  replication repeats the whole double search. A"
        display as text "  p-value taken at the winning (tau, gamma) pair"
        display as text "  would be the p-value of a test nobody ran."
        display as text ""
        display as text "  One multiplier draw is reused across the quantiles"
        display as text "  within a replication, on purpose. The subgradients"
        display as text "  at different quantiles come from the SAME"
        display as text "  observations, and their dependence across tau is"
        display as text "  part of what the uniform limit describes; drawing"
        display as text "  independently per quantile would destroy exactly"
        display as text "  that dependence."
    }
    else {
        display as text "  This tests quantile " as result %6.3f `TAU' ///
            as text " ONLY. A threshold can be"
        display as text "  invisible at the median and plain in the tails --"
        display as text "  which is the usual reason to fit a quantile"
        display as text "  threshold model at all. For the stronger null that"
        display as text "  there is no threshold at ANY quantile, use"
        display as text "  {bf:quantiles()}."
    }
    display as text ""
    display as text "  A rejection says a threshold exists at this quantile."
    display as text "  It does not locate it: the argmax above is where the"
    display as text "  score is largest, not an estimate with a confidence"
    display as text "  set. Fit {helpb thqreg} for that."

    return scalar stat   = `ST'
    return scalar p      = `P'
    return scalar gamma  = `GM'
    return scalar tau    = `TAU'
    return scalar N      = `NN'
    return scalar n_grid = `NG'
    return scalar n_tau  = `NT'
    return scalar reps   = `reps'
    return scalar trim   = `trim'
    return scalar p_mcse = sqrt(`P'*(1-`P')/`reps')
    return local  mode   = cond(`moden'==1, "single", "uniform")
    return local  depvar "`depv'"
    return local  cmd    "thqtest"
    if `haspath' return matrix path = `PATH', copy
    if `hastab'  return matrix bytau = `TAB', copy
    if `hasbd'   return matrix bdist = `BD', copy

    if "`graph'" != "" & `hasbd' {
        preserve
            quietly {
                clear
                svmat double `BD', names(qtb)
                keep if qtb1 < .
            }
            twoway (histogram qtb1, bin(`bins') fcolor(gs12) lcolor(gs6)) ///
                , xline(`=`ST'', lcolor(red) lwidth(medthick))            ///
                  xtitle("multiplier sup-score") ytitle("density")        ///
                  title("Multiplier null distribution")                   ///
                  subtitle("red line: observed statistic", size(small))    ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
    else if "`graph'" != "" {
        display as error "no multiplier distribution to graph"
    }
end
