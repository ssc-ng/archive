*! cointvol_restrict_p 0.1.0  26sep2026
*! predict after -cointvol restrict-: error-correction terms beta#'Z1t
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!   ect : beta_j#'(X(t-1)', D1(t)')' = beta_j'X(t-1) + rho1_j'D1(t)  -> BCRT (2016) eq (1)
*!         D1(t) = 1 (rconstant) or t (rtrend, t = 1 at the first observation of the
*!         estimation sample incl. initial values, as in the estimation recursion);
*!         restricted estimates by default, unrestricted with -unrestricted-.

program define cointvol_restrict_p
    version 14.0
    if `"`e(cmd)'"' != "cointvol restrict" {
        di as err "last estimates not found; run cointvol restrict first"
        exit 301
    }
    syntax newvarlist(min=1) [if] [in] [, ECT UNRestricted Equation(integer 0) ]
    local r = e(rank)
    local nnew : word count `varlist'
    if `equation' != 0 {
        if `nnew' != 1 {
            di as err "equation() requires exactly one new variable"
            exit 198
        }
        if `equation' < 1 | `equation' > `r' {
            di as err "equation() must lie in 1,...,`r'"
            exit 198
        }
    }
    else if `nnew' > `r' {
        di as err "at most r = `r' new variables (one per cointegrating relation)"
        exit 198
    }
    if "`ect'" == "" {
        di as txt "(option ect assumed; error-correction terms)"
    }
    marksample touse, novarlist

    tempname B
    if "`unrestricted'" != "" {
        matrix `B' = e(beta)
        local lab "unrestricted"
    }
    else {
        matrix `B' = e(beta_r)
        local lab "restricted"
    }
    local vl "`e(varlist)'"
    local p : word count `vl'
    local trend "`e(trend)'"
    local tvar "`e(timevar)'"

    // lagged levels X(t-1) (ts operators in the original varlist are resolved first)
    tsrevar `vl'
    local base "`r(varlist)'"
    local lvl ""
    foreach x of local base {
        local lvl "`lvl' L.`x'"
    }
    tsrevar `lvl'
    local lv "`r(varlist)'"

    local i 0
    foreach nv of local varlist {
        local i = `i' + 1
        local j = `i'
        if `equation' > 0 local j = `equation'
        local ty : word `i' of `typlist'
        tempvar tmp
        qui gen double `tmp' = 0 if `touse'
        forvalues m = 1/`p' {
            local x : word `m' of `lv'
            qui replace `tmp' = `tmp' + `B'[`m', `j'] * `x' if `touse'
        }
        if "`trend'" == "rconstant" {
            qui replace `tmp' = `tmp' + `B'[`p' + 1, `j'] if `touse'
        }
        if "`trend'" == "rtrend" {
            qui replace `tmp' = `tmp' + `B'[`p' + 1, `j'] * ((`tvar' - e(tmin))/e(tdelta) + 1) if `touse'
        }
        qui gen `ty' `nv' = `tmp' if `touse'
        label variable `nv' "ect `j' (`lab' beta#'Z1t)"
    }
end
