*! _bd_report.ado — publication-quality output for bootdiag
*! Version 1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _bd_report
    version 16.0
    syntax , mat(string) names(string) sub(string)      ///
        [ cmd(string) src(string) ok(string) note(string) ///
          dgp(string) weight(string) ftrans(string)      ///
          reps(integer 999) n(integer 0) k(integer 0)    ///
          p(integer 0) case(integer 3)                   ///
          ylev(string) xlev(string) q(string)            ///
          block(real 1) noASYmptotic level(cilevel) ]

    local W 78
    local nst = rowsof(`mat')

    * =================================================================
    * Header
    * =================================================================
    di as txt ""
    di as txt "{hline `W'}"
    di as res _col(3) "bootdiag" _col(14) as txt                    ///
       "Bootstrap and Monte Carlo diagnostic tests"
    di as txt "{hline `W'}"

    local lab "Full battery"
    if "`sub'" == "serial" local lab "Serial correlation"
    if "`sub'" == "het"    local lab "Heteroskedasticity"
    if "`sub'" == "norm"   local lab "Normality of disturbances"
    if "`sub'" == "stab"   local lab "Parameter stability"
    if "`sub'" == "spec"   local lab "Functional form / specification"
    if "`sub'" == "nhi"    local lab "Joint normality / homoskedasticity / independence"

    di as txt _col(3) "Test family"        _col(32) ": " as res "`lab'"
    di as txt _col(3) "Fitted by"          _col(32) ": " as res "`cmd'"  ///
       as txt "  (model read from `src')"
    di as txt _col(3) "Model reconstruction" _col(32) ": " as res "`ok'"

    local qs = trim("`q'")
    di as txt _col(3) "ARDL order"         _col(32) ": " as res          ///
       "p = `p'" _c
    if "`qs'" != "" di as res ", q = (`qs')" _c
    di as txt "   PSS case `case'"
    di as txt _col(3) "Dependent variable" _col(32) ": " as res "`ylev'"
    if trim("`xlev'") != "" ///
      di as txt _col(3) "Long-run regressors" _col(32) ": " as res "`xlev'"
    di as txt _col(3) "Observations / parameters" _col(32) ": " as res   ///
       "`n' / `k'"
    if trim("`note'") != "" di as txt _col(3) "Note" _col(32) ": " as res "`note'"

    local dgplab "`dgp'"
    if "`dgp'" == "wild"       local dgplab "recursive wild"
    if "`dgp'" == "residual"   local dgplab "recursive residual"
    if "`dgp'" == "fixed"      local dgplab "fixed-regressor wild"
    if "`dgp'" == "sieve"      local dgplab "AR sieve"
    if "`dgp'" == "block"      local dgplab "moving block"
    if "`dgp'" == "stationary" local dgplab "stationary (Politis-Romano)"
    if "`dgp'" == "blockwild"  local dgplab "block wild (Lee-Baek)"
    if "`dgp'" == "normal"     local dgplab "parametric Gaussian"

    di as txt _col(3) "Bootstrap DGP"      _col(32) ": " as res "`dgplab'"
    local extra ""
    if inlist("`dgp'", "wild", "fixed", "blockwild") ///
        local extra "weights = `weight'"
    if inlist("`dgp'", "wild", "fixed") ///
        local extra "`extra', f(u) = `ftrans'"
    if inlist("`dgp'", "block", "blockwild") ///
        local extra = "`extra', block = " + string(`block', "%4.0f")
    if trim("`extra'") != "" ///
        di as txt _col(32) "  " as res "`extra'"
    di as txt _col(3) "Replications"       _col(32) ": " as res "`reps'"

    * =================================================================
    * Table
    * =================================================================
    di as txt ""
    di as txt "  {hline 74}"
    di as txt _col(3) "Test" _col(34) "Statistic" _col(47) "Boot p" ///
       _col(58) "5% c.v." _col(69) "H0"
    di as txt "  {hline 74}"

    local anyasym 0
    forvalues j = 1/`nst' {
        local nm : word `j' of `names'
        local s  = `mat'[`j', 1]
        local pb = `mat'[`j', 2]
        local c5 = `mat'[`j', 3]
        local pa = `mat'[`j', 6]
        if `pa' < . local anyasym 1

        local dec "  --"
        if `pb' < . {
            local dec = cond(`pb' < 0.01, "rej 1%",   ///
                        cond(`pb' < 0.05, "rej 5%",   ///
                        cond(`pb' < 0.10, "rej 10%", "not rej")))
        }
        local star ""
        if `pb' < 0.10 local star "*"
        if `pb' < 0.05 local star "**"
        if `pb' < 0.01 local star "***"

        di as txt _col(3) abbrev("`nm'", 29) _c
        if `s' < .  di as res _col(33) %10.4f `s' _c
        else        di as txt _col(33) %10s "." _c
        if `pb' < . di as res _col(45) %7.4f `pb' _c
        else        di as txt _col(45) %7s "." _c
        di as res _col(53) %-3s "`star'" _c
        if `c5' < . di as res _col(57) %9.4f `c5' _c
        else        di as txt _col(57) %9s "." _c
        di as txt _col(69) "`dec'"
    }
    di as txt "  {hline 74}"
    di as txt _col(3) "Stars: *** p<0.01, ** p<0.05, * p<0.10."
    di as txt _col(3) "Boot p = Monte Carlo p-value, (N*Ghat+1)/(N+1);"
    di as txt _col(3) "exact when the statistic is pivotal (Dufour et al. 2004)."
    if "`sub'" == "nhi" {
        di as txt _col(3) ""
        di as txt _col(3) "Jarque & Bera (1980): LM_NHI = LM_N + LM_H + LM_I."
        di as txt _col(3) "The joint test and all six sub-tests come from one"
        di as txt _col(3) "bootstrap loop, so they are mutually consistent."
    }

    * =================================================================
    * Asymptotic comparison
    * =================================================================
    if "`asymptotic'" == "" & `anyasym' {
        di as txt ""
        di as txt _col(3) "{bf:Bootstrap vs asymptotic p-values}"
        di as txt "  {hline 74}"
        di as txt _col(3) "Test" _col(40) "Boot p" _col(53) "Asym p" ///
           _col(66) "Difference"
        di as txt "  {hline 74}"
        forvalues j = 1/`nst' {
            local pa = `mat'[`j', 6]
            if `pa' >= . continue
            local nm : word `j' of `names'
            local pb = `mat'[`j', 2]
            local df = `pb' - `pa'
            di as txt _col(3) abbrev("`nm'", 35) ///
               as res _col(39) %8.4f `pb' _col(52) %8.4f `pa' ///
               _col(66) %9.4f `df'
        }
        di as txt "  {hline 74}"
        di as txt _col(3) "A positive difference means the asymptotic test"
        di as txt _col(3) "over-rejects relative to the bootstrap."
    }

    di as txt "{hline `W'}"
end
