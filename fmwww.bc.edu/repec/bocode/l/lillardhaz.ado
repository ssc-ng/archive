*! lillardhaz v1.0.0  25sep2026
*! Front-end for Lillard (1993)-style simultaneous-equations hazard
*! models: eq1 in {probit, lognormal, pgompertz} paired with eq2 in
*! {lognormal, pgompertz}, correlated via a Gaussian copula (or fit
*! independently with nocorr, which reduces exactly to two separate
*! univariate fits -- see docs/manual.html for the identification
*! argument and its empirical verification).
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*!
*! Syntax:
*!   lillardhaz depvars [if] [in], eq1(type) eq2(type)
*!       [x1(varlist) x2(varlist) nocorr nodes1(numlist) nodes2(numlist)
*!        technique(string) iterate(#) level(#) nolog]
*!
*!   depvars: if eq1(probit),               exactly 3 vars: y1 time2 event2
*!            if eq1(lognormal|pgompertz),   exactly 4 vars: time1 event1 time2 event2
*!   eq1(): "probit", "lognormal", or "pgompertz"
*!   eq2(): "lognormal" or "pgompertz"
*!   nodes1()/nodes2(): interior nodes (ascending numlist), required
*!       when eq1()/eq2() is pgompertz
*!
*! See docs/manual.html for the full model, likelihood derivation
*! (Gaussian-copula joint density/survival for every eq1 x eq2
*! combination), and worked examples.

capture program drop lillardhaz
program define lillardhaz, eclass
    version 17
    syntax varlist(min=3 max=4) [if] [in], Eq1(string) Eq2(string) ///
        [ X1(varlist) X2(varlist) NOCorr NODes1(numlist ascending) ///
          NODes2(numlist ascending) TECHnique(string) ITERate(integer 300) ///
          LEVel(cilevel) NOLog ]

    local eq1 = lower("`eq1'")
    local eq2 = lower("`eq2'")

    if !inlist("`eq1'","probit","lognormal","pgompertz") {
        display as error "eq1() must be probit, lognormal, or pgompertz"
        exit 198
    }
    if !inlist("`eq2'","lognormal","pgompertz") {
        display as error "eq2() must be lognormal or pgompertz"
        exit 198
    }
    if "`eq1'"=="pgompertz" & "`nodes1'"=="" {
        display as error "nodes1() required when eq1(pgompertz)"
        exit 198
    }
    if "`eq2'"=="pgompertz" & "`nodes2'"=="" {
        display as error "nodes2() required when eq2(pgompertz)"
        exit 198
    }

    local ndep : word count `varlist'
    if "`eq1'"=="probit" & `ndep'!=3 {
        display as error "with eq1(probit), specify exactly 3 depvars: y1 time2 event2"
        exit 198
    }
    if "`eq1'"!="probit" & `ndep'!=4 {
        display as error "with eq1(`eq1'), specify exactly 4 depvars: time1 event1 time2 event2"
        exit 198
    }

    marksample touse
    markout `touse' `x1' `x2'

    * -------- record depvar roles for lillardhaz_p (predict) --------
    tokenize `varlist'
    if "`eq1'"=="probit" {
        local yvar1_    "`1'"
        local timevar2_ "`2'"
        local eventvar2_ "`3'"
        local timevar1_ ""
        local eventvar1_ ""
    }
    else {
        local timevar1_  "`1'"
        local eventvar1_ "`2'"
        local timevar2_  "`3'"
        local eventvar2_ "`4'"
        local yvar1_ ""
    }

    if "`technique'"=="" local technique "bfgs"

    * -------- build the ml model equation bracket --------
    if "`x1'"=="" local eqlist "(eq1: `varlist')"
    else          local eqlist "(eq1: `varlist' = `x1')"

    if "`eq1'"=="lognormal" {
        local eqlist "`eqlist' (ln_sigma1:)"
    }
    else if "`eq1'"=="pgompertz" {
        local K1 : word count `nodes1'
        local K1 = `K1' + 1
        forvalues k = 1/`K1' {
            local eqlist "`eqlist' (s1_`k':)"
        }
    }

    if "`x2'"=="" local eqlist "`eqlist' (eq2:)"
    else          local eqlist "`eqlist' (eq2: `x2')"

    if "`eq2'"=="lognormal" {
        local eqlist "`eqlist' (ln_sigma2:)"
    }
    else {
        local K2 : word count `nodes2'
        local K2 = `K2' + 1
        forvalues k = 1/`K2' {
            local eqlist "`eqlist' (s2_`k':)"
        }
    }

    if "`nocorr'"=="" {
        local eqlist "`eqlist' (atanh_rho:)"
        global LH_corr = 1
    }
    else {
        global LH_corr = 0
    }

    global LH_eq1type "`eq1'"
    global LH_eq2type "`eq2'"
    global LH_nodes1 "`nodes1'"
    global LH_nodes2 "`nodes2'"

    ml model d0 lillardhaz_d0 `eqlist' if `touse', technique(`technique')
    ml maximize, iterate(`iterate') level(`level') `nolog'

    ereturn local cmd "lillardhaz"
    ereturn local cmdline `"lillardhaz `0'"'
    ereturn local eq1type "`eq1'"
    ereturn local eq2type "`eq2'"
    ereturn local nodes1 "`nodes1'"
    ereturn local nodes2 "`nodes2'"
    ereturn local yvar1 "`yvar1_'"
    ereturn local timevar1 "`timevar1_'"
    ereturn local eventvar1 "`eventvar1_'"
    ereturn local timevar2 "`timevar2_'"
    ereturn local eventvar2 "`eventvar2_'"
    ereturn scalar corr = ("`nocorr'"=="")
    ereturn local predict "lillardhaz_p"

    if "`nocorr'"=="" {
        tempname rho_b rho_se
        scalar `rho_b'  = tanh(_b[atanh_rho:_cons])
        scalar `rho_se' = (1 - `rho_b'^2) * _se[atanh_rho:_cons]
        ereturn scalar rho = `rho_b'
        ereturn scalar rho_se = `rho_se'
        display as text _n "Estimated copula correlation: " ///
            as result "rho = " %6.4f `rho_b' as text "  (se = " %6.4f `rho_se' ")"
    }

    macro drop LH_eq1type LH_eq2type LH_nodes1 LH_nodes2 LH_corr
end
