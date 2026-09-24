capture program drop xtie2

program define xtie2, eclass
    version 18
    syntax varlist(min=3 numeric) [if] [in] [, ROBust]

    marksample touse

    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local n_vars : word count `indepvars'

    local interactions ""

    display "--------------------------------------------------"
    display "Interactive Panel Data Estimation - xtie2"
    display "Dependent variable: `depvar'"
    display "Independent variables: `indepvars'"
    display "--------------------------------------------------"

    local i = 1

    foreach var1 of local indepvars {

        local j = `i' + 1

        while `j' <= `n_vars' {

            local var2 : word `j' of `indepvars'

            tempvar inter_`i'_`j'
            quietly gen `inter_`i'_`j'' = `var1' * `var2' if `touse'

            local interactions "`interactions' `inter_`i'_`j''"

            display "Created interaction: `var1' x `var2'"

            local j = `j' + 1
        }

        local i = `i' + 1
    }

    display "--------------------------------------------------"
    display "Estimating fixed-effects model..."
    display "--------------------------------------------------"

    if "`robust'" != "" {
        xtreg `depvar' `indepvars' `interactions' if `touse', fe vce(robust)
    }
    else {
        xtreg `depvar' `indepvars' `interactions' if `touse', fe
    }

    local x1 : word 1 of `indepvars'
    local x2 : word 2 of `indepvars'
    local first_inter : word 1 of `interactions'

    scalar beta_x1 = _b[`x1']
    scalar beta_x2 = _b[`x2']
    scalar beta_inter = _b[`first_inter']
    scalar se_inter = _se[`first_inter']
    scalar t_inter = beta_inter / se_inter
    scalar p_inter = 2 * ttail(e(df_r), abs(t_inter))

    quietly summarize `x1' if e(sample), detail
    scalar x1_min = r(min)
    scalar x1_mean = r(mean)
    scalar x1_median = r(p50)
    scalar x1_max = r(max)

    quietly summarize `x2' if e(sample), detail
    scalar x2_min = r(min)
    scalar x2_mean = r(mean)
    scalar x2_median = r(p50)
    scalar x2_max = r(max)

    display "--------------------------------------------------"
    display "Post-estimation IPDF outputs"
    display "--------------------------------------------------"

    display "Main variable 1: `x1'"
    display "Main variable 2: `x2'"
    display "Primary interaction: `x1' x `x2'"

    display "Beta `x1' = " %10.6f beta_x1
    display "Beta `x2' = " %10.6f beta_x2
    display "Beta interaction = " %10.6f beta_inter
    display "SE interaction = " %10.6f se_inter
    display "t interaction = " %10.3f t_inter
    display "p interaction = " %10.4f p_inter

    if beta_inter != 0 {

        scalar critical_x2 = -beta_x1 / beta_inter
        scalar critical_x1 = -beta_x2 / beta_inter

        display "--------------------------------------------------"
        display "Marginal-effect zero-crossing values"
        display "--------------------------------------------------"

        display "Critical `x2' value where marginal effect of `x1' equals zero:"
        display %10.4f critical_x2

        display "Observed `x2' range: " %10.4f x2_min " to " %10.4f x2_max

        if critical_x2 >= x2_min & critical_x2 <= x2_max {
            display "The critical value lies WITHIN the observed sample range."
        }
        else {
            display "The critical value lies OUTSIDE the observed sample range."
            display "No within-sample sign change in the marginal effect of `x1' is implied."
        }

        display " "

        display "Critical `x1' value where marginal effect of `x2' equals zero:"
        display %10.4f critical_x1

        display "Observed `x1' range: " %10.4f x1_min " to " %10.4f x1_max

        if critical_x1 >= x1_min & critical_x1 <= x1_max {
            display "The critical value lies WITHIN the observed sample range."
        }
        else {
            display "The critical value lies OUTSIDE the observed sample range."
            display "No within-sample sign change in the marginal effect of `x2' is implied."
        }
    }

    capture drop me_`x1'
    capture drop me_`x2'
    capture drop regime_`x2'

    gen me_`x1' = beta_x1 + beta_inter * `x2' if `touse'
    gen me_`x2' = beta_x2 + beta_inter * `x1' if `touse'

    display "--------------------------------------------------"
    display "Marginal effect summaries"
    display "--------------------------------------------------"

    display "Marginal effect of `x1' on `depvar':"
    summarize me_`x1'

    display "Marginal effect of `x2' on `depvar':"
    summarize me_`x2'

    display "--------------------------------------------------"
    display "Marginal effect of `x1' at selected values of `x2'"
    display "--------------------------------------------------"

    quietly lincom _b[`x1'] + x2_min * _b[`first_inter']
    display "At minimum `x2' (" %9.3f x2_min "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x1'] + x2_mean * _b[`first_inter']
    display "At mean `x2' (" %9.3f x2_mean "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x1'] + x2_median * _b[`first_inter']
    display "At median `x2' (" %9.3f x2_median "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x1'] + x2_max * _b[`first_inter']
    display "At maximum `x2' (" %9.3f x2_max "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    display "--------------------------------------------------"
    display "Marginal effect of `x2' at selected values of `x1'"
    display "--------------------------------------------------"

    quietly lincom _b[`x2'] + x1_min * _b[`first_inter']
    display "At minimum `x1' (" %9.3f x1_min "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x2'] + x1_mean * _b[`first_inter']
    display "At mean `x1' (" %9.3f x1_mean "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x2'] + x1_median * _b[`first_inter']
    display "At median `x1' (" %9.3f x1_median "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    quietly lincom _b[`x2'] + x1_max * _b[`first_inter']
    display "At maximum `x1' (" %9.3f x1_max "): ME = " %9.5f r(estimate) "  SE = " %9.5f r(se) "  p = " %7.4f r(p)

    if beta_inter != 0 {

        gen regime_`x2' = .

        replace regime_`x2' = 0 if `x2' <= critical_x2 & `touse'
        replace regime_`x2' = 1 if `x2' > critical_x2 & `touse'

        label define ipdf_regime 0 "Low regime" 1 "High regime", replace
        label values regime_`x2' ipdf_regime

        display "--------------------------------------------------"
        display "Classification around marginal-effect zero-crossing"
        display "--------------------------------------------------"

        tab regime_`x2'
    }

    display "--------------------------------------------------"
    display "Automatic interpretation"
    display "--------------------------------------------------"

    if p_inter < 0.01 {
        display "The interaction coefficient is statistically significant at the 1% level."
    }
    else if p_inter < 0.05 {
        display "The interaction coefficient is statistically significant at the 5% level."
    }
    else if p_inter < 0.10 {
        display "The interaction coefficient is statistically significant at the 10% level."
    }
    else {
        display "The interaction coefficient is not statistically significant at conventional levels."
    }

    if beta_inter > 0 {
        display "The interaction coefficient is positive."
        display "As `x2' increases, the marginal effect of `x1' becomes more positive."
    }
    else if beta_inter < 0 {
        display "The interaction coefficient is negative."
        display "As `x2' increases, the marginal effect of `x1' becomes more negative."
    }
    else {
        display "The interaction coefficient is zero."
    }

    quietly summarize me_`x1'

    if r(mean) > 0 {
        display "The average marginal effect of `x1' is positive."
    }
    else if r(mean) < 0 {
        display "The average marginal effect of `x1' is negative."
    }
    else {
        display "The average marginal effect of `x1' is approximately zero."
    }

    ereturn local cmd "xtie2"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"

    ereturn scalar beta_inter = beta_inter
    ereturn scalar se_inter = se_inter
    ereturn scalar t_inter = t_inter
    ereturn scalar p_inter = p_inter

    if beta_inter != 0 {
        ereturn scalar critical_x2 = critical_x2
        ereturn scalar critical_x1 = critical_x1
    }

    display "--------------------------------------------------"
    display "xtie2 completed successfully."
    display "Generated variables:"
    display "me_`x1'"
    display "me_`x2'"

    if beta_inter != 0 {
        display "regime_`x2'"
    }

    display "--------------------------------------------------"

end