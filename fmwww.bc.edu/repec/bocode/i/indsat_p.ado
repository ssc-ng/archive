*! indsat_p 1.0.0  12nov2026
*! predict after indsat
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
program define indsat_p
    version 14.0
    syntax newvarname [if] [in] [, XB Residuals RSTandard PATH PATHSE]
    local nopt = ("`xb'"!="") + ("`residuals'"!="") + ("`rstandard'"!="") + ("`path'"!="") + ("`pathse'"!="")
    if (`nopt'>1) {
        di as err "only one statistic may be specified"
        exit 198
    }
    if (`nopt'==0) {
        local xb "xb"
        di as text "(option xb assumed; fitted values)"
    }
    tempvar es
    qui gen byte `es' = e(sample)
    qui gen double `varlist' = .
    tempname R P
    matrix `R' = e(resid)
    if ("`xb'"!="") mata: st_store(selectindex(st_data(., "`es'")), "`varlist'", st_matrix("`R'")[., 2])
    if ("`residuals'"!="") mata: st_store(selectindex(st_data(., "`es'")), "`varlist'", st_matrix("`R'")[., 3])
    if ("`rstandard'"!="") mata: st_store(selectindex(st_data(., "`es'")), "`varlist'", st_matrix("`R'")[., 3] :/ st_numscalar("e(sigma)"))
    if ("`path'"!="" | "`pathse'"!="") {
        qui indsat_estat path, nodisplay
        matrix `P' = r(path)
        local c = cond("`path'"!="", 2, 3)
        mata: st_store(selectindex(st_data(., "`es'")), "`varlist'", st_matrix("`P'")[., `c'])
    }
    if ("`if'`in'"!="") {
        marksample touse, novarlist
        qui replace `varlist' = . if !`touse'
    }
    if ("`xb'"!="") label var `varlist' "indsat fitted values"
    if ("`residuals'"!="") label var `varlist' "indsat residuals"
    if ("`rstandard'"!="") label var `varlist' "indsat scaled residuals"
    if ("`path'"!="") label var `varlist' "indsat intercept path"
    if ("`pathse'"!="") label var `varlist' "indsat intercept path s.e."
end
