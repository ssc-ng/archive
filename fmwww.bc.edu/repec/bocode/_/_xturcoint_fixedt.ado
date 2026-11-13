*! _xturcoint_fixedt 1.0.0  11nov2026   (engine of: xturcoint fixedt)
*! Fixed-T panel stationarity (Hadri-Larsson 2005) and unit-root
*! (Carrion-i-Silvestre-Hadri 2010) LM tests
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routine fixed_T_panel (tspdlib, PD_fixedT.src)
*!   by Saban Nazlioglu.
*!
*! References:
*!   Hadri, K., Larsson, R. (2005). Testing for stationarity in heterogeneous
*!     panel data where the time dimension is finite. Econometrics Journal
*!     8(1): 55-69. <doi:10.1111/j.1368-423X.2005.00151.x>
*!   Carrion-i-Silvestre, J. L., Hadri, K. (2010). Panel data unit root test
*!     with fixed time dimension. Bulletin of Economic Research 62(3):
*!     269-277. <doi:10.1111/j.1467-8586.2009.00336.x>
*!
*! Step -> code map (see -help xturcoint_fixedt-):
*!   OLS residuals on (1) or (1, t)               -> _xtfxt_run
*!   KPSS-type LM_i = sum S_t^2 / (T e'e)         -> _xtfxt_run
*!   Bhargava-type LM_i on differenced residuals  -> _xtfxt_run
*!   exact finite-T moments, Z = sqrt(N)(LM-mu)/sd -> _xtfxt_run

program _xturcoint_fixedt, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in] [ , MODel(string) noTABle ]

    marksample touse
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","constant","c")        local mod 1
    else if inlist("`model'","trend","ct","t") local mod 2
    else {
        di as err "model() must be constant or trend"
        exit 198
    }
    tempvar cnt
    qui bysort `ivar' (`tvar'): gen long `cnt' = sum(`touse')
    qui bysort `ivar' (`tvar'): replace `cnt' = `cnt'[_N]
    qui summ `cnt' if `touse', meanonly
    if r(min) != r(max) {
        di as err "the panel must be balanced over the estimation sample"
        exit 459
    }
    local T = r(max)
    if `T' < 4 {
        di as err "at least 4 time periods are required"
        exit 2001
    }
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    sort `ivar' `tvar'
    tempname IND
    mata: _xtfxt_run("`varlist'", "`touse'", `N', `T', `mod')
    matrix `IND' = r(ind)
    matrix colnames `IND' = LM_HL Z_HL p_HL LM_CH Z_CH p_CH
    matrix rownames `IND' = `units'
    local zhl = r(Zhl)
    local zch = r(Zch)
    local phl = 1 - normal(`zhl')
    local pch = normal(`zch')

    local mlab = cond(`mod'==1, "constant", "constant and trend")
    di
    di as txt "Fixed-T panel LM tests (exact finite-T moments)"
    di as txt "{hline 72}"
    di as txt "Deterministics : " as res "`mlab'" _col(46) as txt "Number of panels" _col(64) "= " as res %5.0f `N'
    di as txt _col(46) "Number of periods" _col(64) "= " as res %5.0f `T'
    di as txt "{hline 72}"
    di as txt _col(3) "Test" _col(37) "H0" _col(54) "Z" _col(63) "p-value"
    di as txt "{hline 72}"
    local st = cond(`phl'<.01,"***",cond(`phl'<.05,"**",cond(`phl'<.10,"*","")))
    di as txt _col(3) "Hadri-Larsson (2005)" _col(37) "stationarity" _col(48) as res %9.4f `zhl' _col(60) %9.4f `phl' as txt " `st'"
    local st = cond(`pch'<.01,"***",cond(`pch'<.05,"**",cond(`pch'<.10,"*","")))
    di as txt _col(3) "Carrion-i-Silvestre-Hadri (2010)" _col(37) "unit root" _col(48) as res %9.4f `zch' _col(60) %9.4f `pch' as txt " `st'"
    di as txt "{hline 72}"
    di as txt "HL: right-tailed N(0,1);  CH: left-tailed N(0,1).  *** p<0.01, ** p<0.05, * p<0.10"
    if "`table'"=="" {
        di
        di as txt "Unit-specific statistics"
        di as txt "{hline 72}"
        di as txt _col(3) "`ivar'" _col(14) "LM(HL)" _col(25) "Z(HL)" _col(35) "p(HL)" _col(46) "LM(CH)" _col(57) "Z(CH)" _col(66) "p(CH)"
        di as txt "{hline 72}"
        forvalues i = 1/`N' {
            local u : word `i' of `units'
            di as txt _col(3) "`u'" _col(10) as res %9.4f `IND'[`i',1] %9.3f `IND'[`i',2] %9.3f `IND'[`i',3] ///
                _col(42) %9.4f `IND'[`i',4] %9.3f `IND'[`i',5] %9.3f `IND'[`i',6]
        }
        di as txt "{hline 72}"
    }
    return scalar Z_HL = `zhl'
    return scalar p_HL = `phl'
    return scalar Z_CH = `zch'
    return scalar p_CH = `pch'
    return scalar mu_HL  = r(mu1)
    return scalar var_HL = r(var1)
    return scalar mu_CH  = r(mu2)
    return scalar var_CH = r(var2)
    return scalar N = `N'
    return scalar T = `T'
    return local model "`model'"
    return local varname "`varlist'"
    return matrix individual = `IND'
end

mata:
void _xtfxt_run(string scalar vn, string scalar touse, real scalar N,
                real scalar T, real scalar mod)
{
    real matrix Y, z, ind
    real colvector y, e, de
    real scalar i, mu1, var1, mu2, var2, lm1, lm2, Zhl, Zch
    Y = st_data(., vn, touse)
    if (mod == 1) {
        mu1  = (T+1)/(6*T)
        var1 = ((T^2+1)/(20*T^2)) - mu1^2
        mu2  = (T+1)/(2*T)
        var2 = (1/12)*((T+1)*(7*T^2+7*T+4)/((2+T)*T^2)) - mu2^2
        z = J(T,1,1)
    }
    if (mod == 2) {
        mu1  = (T+2)/(15*T)
        var1 = (T+2)*(13*T^2+23)/(2100*T^3) - mu1^2
        mu2  = (T+1)/(6*T)
        var2 = ((T^2+1)/(20*T^2)) - mu2^2
        z = J(T,1,1), (1::T)
    }
    ind = J(N, 6, .)
    for (i=1; i<=N; i=i+1) {
        y  = Y[|(i-1)*T+1 \ i*T|]
        e  = y - z*(luinv(z'*z)*(z'*y))
        lm1 = sum(runningsum(e):^2)/(T*(e'*e))
        de = e[|2 \ T|] - e[|1 \ T-1|]
        lm2 = sum(runningsum(de):^2)/(T*(de'*de))
        ind[i,1] = lm1
        ind[i,2] = (lm1 - mu1)/sqrt(var1)
        ind[i,3] = 1 - normal(ind[i,2])
        ind[i,4] = lm2
        ind[i,5] = (lm2 - mu2)/sqrt(var2)
        ind[i,6] = normal(ind[i,5])
    }
    Zhl = sqrt(N)*(mean(ind[.,1]) - mu1)/sqrt(var1)
    Zch = sqrt(N)*(mean(ind[.,4]) - mu2)/sqrt(var2)
    st_rclear()
    st_numscalar("r(Zhl)", Zhl)
    st_numscalar("r(Zch)", Zch)
    st_numscalar("r(mu1)", mu1)
    st_numscalar("r(var1)", var1)
    st_numscalar("r(mu2)", mu2)
    st_numscalar("r(var2)", var2)
    st_matrix("r(ind)", ind)
}
end
