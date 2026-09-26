*! lillardhaz_p v1.0.0  25sep2026
*! predict subroutine for lillardhaz
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>

capture program drop lillardhaz_p
program define lillardhaz_p
    version 17
    if "`e(cmd)'" != "lillardhaz" {
        error 301
    }
    syntax newvarname [if] [in] [, XB1 XB2 PR1 SUrv1 SUrv2 Dens1 Dens2]

    local nopt : word count `xb1' `xb2' `pr1' `surv1' `surv2' `dens1' `dens2'
    if `nopt' > 1 {
        display as error "only one prediction statistic may be specified"
        exit 198
    }
    if `nopt' == 0 local surv2 "surv2"

    marksample touse, novarlist

    local eq1type "`e(eq1type)'"
    local eq2type "`e(eq2type)'"
    local nodes1 "`e(nodes1)'"
    local nodes2 "`e(nodes2)'"

    tempname beta
    matrix `beta' = e(b)
    tempvar theta1 theta2
    quietly matrix score double `theta1' = `beta' if `touse', eq(eq1)
    quietly matrix score double `theta2' = `beta' if `touse', eq(eq2)

    if "`xb1'" != "" {
        quietly gen double `varlist' = `theta1' if `touse'
        label variable `varlist' "Fitted eq1 linear index"
        exit
    }
    if "`xb2'" != "" {
        quietly gen double `varlist' = `theta2' if `touse'
        label variable `varlist' "Fitted eq2 linear index"
        exit
    }

    if "`pr1'" != "" {
        if "`eq1type'" != "probit" {
            display as error "pr1 is only available when eq1(probit) was used"
            exit 198
        }
        quietly gen double `varlist' = normal(`theta1') if `touse'
        label variable `varlist' "Predicted Pr(y1=1)"
        exit
    }

    if ("`surv1'" != "" | "`dens1'" != "") & "`eq1type'" == "probit" {
        display as error "surv1/dens1 are not available when eq1(probit) was used"
        exit 198
    }

    * -------- eq1 survival/density (hazard types only) --------
    if "`surv1'" != "" | "`dens1'" != "" {
        tempvar S1 f1
        if "`eq1type'" == "lognormal" {
            tempname lnsig1
            scalar `lnsig1' = _b[ln_sigma1:_cons]
            quietly gen double `S1' = 1 - normal((ln(`e(timevar1)') - `theta1')/exp(`lnsig1')) if `touse'
            quietly gen double `f1' = normalden((ln(`e(timevar1)') - `theta1')/exp(`lnsig1')) ///
                / (exp(`lnsig1') * `e(timevar1)') if `touse'
        }
        else {
            local K1 : word count `nodes1'
            local K1 = `K1' + 1
            tempname slopes1
            matrix `slopes1' = J(1, `K1', 0)
            forvalues k = 1/`K1' {
                matrix `slopes1'[1,`k'] = _b[s1_`k':_cons]
            }
            quietly _lillardhaz_pgomp `theta1' `slopes1' "`nodes1'" `e(timevar1)' `S1' `f1'
        }
        if "`surv1'" != "" {
            quietly gen double `varlist' = `S1' if `touse'
            label variable `varlist' "Predicted S1(t) at observed eq1 duration"
        }
        else {
            quietly gen double `varlist' = `f1' if `touse'
            label variable `varlist' "Predicted f1(t) at observed eq1 duration"
        }
        exit
    }

    * -------- eq2 survival/density (always a hazard type) --------
    tempvar S2 f2
    if "`eq2type'" == "lognormal" {
        tempname lnsig2
        scalar `lnsig2' = _b[ln_sigma2:_cons]
        quietly gen double `S2' = 1 - normal((ln(`e(timevar2)') - `theta2')/exp(`lnsig2')) if `touse'
        quietly gen double `f2' = normalden((ln(`e(timevar2)') - `theta2')/exp(`lnsig2')) ///
            / (exp(`lnsig2') * `e(timevar2)') if `touse'
    }
    else {
        local K2 : word count `nodes2'
        local K2 = `K2' + 1
        tempname slopes2
        matrix `slopes2' = J(1, `K2', 0)
        forvalues k = 1/`K2' {
            matrix `slopes2'[1,`k'] = _b[s2_`k':_cons]
        }
        quietly _lillardhaz_pgomp `theta2' `slopes2' "`nodes2'" `e(timevar2)' `S2' `f2'
    }

    if "`dens2'" != "" {
        quietly gen double `varlist' = `f2' if `touse'
        label variable `varlist' "Predicted f2(t) at observed eq2 duration"
    }
    else {
        quietly gen double `varlist' = `S2' if `touse'
        label variable `varlist' "Predicted S2(t) at observed eq2 duration"
    }
end
