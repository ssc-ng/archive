*! surardl_p 1.0.1  10oct2026
*! predict after surardl
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! github.com/merwanroudane

program define surardl_p
    version 14.0
    syntax newvarname [if] [in] [, XB Residuals OLSResiduals EC ///
                                   EQuation(string) ]

    if ("`e(cmd)'" != "surardl") error 301

    local opt "`xb'`residuals'`olsresiduals'`ec'"
    if ("`opt'" == "") local residuals residuals
    local nopt : word count `xb' `residuals' `olsresiduals' `ec'
    if (`nopt' > 1) {
        di as error "only one statistic may be requested"
        exit 198
    }

    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)

    local ivar "`e(ivar)'"
    local tvar "`e(tvar)'"
    local N    = e(N_eq)
    local K    = e(k_x)
    local ids  "`e(ids)'"
    local t0   = e(tmin)
    local dd   = e(delta)

    tempname M
    if ("`residuals'" != "")    matrix `M' = e(resid)
    if ("`olsresiduals'" != "") matrix `M' = e(residols)

    qui gen double `varlist' = .

    if ("`residuals'" != "" | "`olsresiduals'" != "") {
        mata: _sa_p_put("`varlist'", "`touse'", "`ivar'", "`tvar'", ///
              st_matrix("`M'"), strtoreal(tokens("`ids'"))', `t0', `dd')
        label variable `varlist' "SUR-ARDL residuals"
        if ("`olsresiduals'" != "") label variable `varlist' "equation-by-equation OLS residuals"
        exit
    }

    if ("`xb'" != "") {
        tempvar dy
        qui gen double `dy' = D.`e(depvar)'
        matrix `M' = e(resid)
        mata: _sa_p_put("`varlist'", "`touse'", "`ivar'", "`tvar'", ///
              st_matrix("`M'"), strtoreal(tokens("`ids'"))', `t0', `dd')
        qui replace `varlist' = `dy' - `varlist' if `touse'
        label variable `varlist' "linear prediction of D.`e(depvar)'"
        exit
    }

    if ("`ec'" != "") {
        * error-correction term  y_{t-1} - sum_k theta_k x_{k,t-1}
        local dep "`e(depvar)'"
        local xv  "`e(indepvars)'"
        local eqn "`e(eqnames)'"
        tempname LR
        matrix `LR' = e(longrun)
        qui replace `varlist' = L.`dep' if `touse'
        local i 1
        foreach id of local ids {
            local k 1
            foreach x of local xv {
                local r = (`i'-1)*`K' + `k'
                qui replace `varlist' = `varlist' - `LR'[`r',3] * L.`x' ///
                    if `touse' & `ivar' == `id'
                local k = `k' + 1
            }
            local i = `i' + 1
        }
        label variable `varlist' "error-correction term"
        exit
    }
end

version 14.0
mata:

// Scatter a T x N matrix of per-equation series back onto the long
// panel, matching on (panel value, time value).
void _sa_p_put(string scalar vname, string scalar touse, string scalar ivar,
        string scalar tvar, real matrix M, real colvector ids,
        real scalar t0, real scalar delta)
{
    real colvector uv, tv, out
    real scalar r, n, i, c, ti

    uv  = st_data(., ivar, touse)
    tv  = st_data(., tvar, touse)
    n   = rows(uv)
    out = J(n, 1, .)
    for (r = 1; r <= n; r++) {
        ti = (tv[r] - t0) / delta + 1
        i  = 0
        for (c = 1; c <= rows(ids); c++) {
            if (ids[c] == uv[r]) {
                i = c
            }
        }
        if (i > 0 & ti >= 1 & ti <= rows(M)) {
            out[r] = M[ti, i]
        }
    }
    st_store(., vname, touse, out)
}

end
