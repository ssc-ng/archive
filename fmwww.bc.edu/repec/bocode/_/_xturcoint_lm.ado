*! _xturcoint_lm 1.0.0  11nov2026   (engine of: xturcoint lm)
*! Panel LM unit-root tests with level shifts (Im-Lee-Tieslau 2005) and with
*! level-and-trend shifts (Lee-Tieslau 2019), 0, 1 or 2 endogenous breaks
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routines PDLM / PDLMlevel / PDLMtrend
*!   (tspdlib, PD_ILTlevel.src and PD_LTtrend.src) by Saban Nazlioglu, which
*!   call LM, LM_1break and LM_2breaks (Lee-Strazicich minimum LM).
*!
*! References:
*!   Im, K. S., Lee, J., Tieslau, M. (2005). Panel LM unit-root tests with
*!     level shifts. Oxford Bulletin of Economics and Statistics 67(3):
*!     393-419. <doi:10.1111/j.1468-0084.2005.00125.x>
*!   Lee, J., Tieslau, M. (2019). Panel LM unit root tests with level and
*!     trend shifts. Economic Modelling 80: 1-10.
*!     <doi:10.1016/j.econmod.2018.07.025>
*!   Schmidt, P., Phillips, P. C. B. (1992). LM tests for a unit root in the
*!     presence of deterministic trends. Oxford Bulletin of Economics and
*!     Statistics 54(3): 257-287. <doi:10.1111/j.1468-0084.1992.tb00002.x>
*!   Lee, J., Strazicich, M. C. (2003). Minimum Lagrange multiplier unit root
*!     test with two structural breaks. Review of Economics and Statistics
*!     85(4): 1082-1089. <doi:10.1162/003465303772815961>
*!
*! Step -> code map (see -help xturcoint_lm-):
*!   SP (1992) LM with no break                      -> _xtpdlm_lm0
*!   LS minimum LM, level breaks (ILT 2005)          -> _xtpdlm_lmbr (lt = 0)
*!   LT transformed LM, level+trend breaks (LT 2019) -> _xtpdlm_lmbr (lt = 1)
*!   lag selection (AIC / BIC / t-sig 10%)           -> _xtpdlm_getlag
*!   panel LM = sqrt(N)(mean LM_i - E)/sqrt(V)       -> _xtpdlm_moments

program _xturcoint_lm, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        NBreak(integer 0)    ///
        PMax(integer 8)      ///
        IC(string)           ///
        TRIM(real 0.10)      ///
        PAPer                ///
        noTABle ]

    marksample touse
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    if ("`model'"=="") local model "level"
    local model = strlower("`model'")
    if inlist("`model'","level","l","1","ilt")       local mod 1
    else if inlist("`model'","trend","t","2","lt")   local mod 2
    else {
        di as err "model() must be level (Im-Lee-Tieslau) or trend (Lee-Tieslau)"
        exit 198
    }
    if !inlist(`nbreak',0,1,2) {
        di as err "nbreak() must be 0, 1 or 2"
        exit 198
    }
    if ("`ic'"=="") local ic "tstat"
    local ic = strlower("`ic'")
    if inlist("`ic'","aic","1")              local icn 1
    else if inlist("`ic'","bic","sic","2")   local icn 2
    else if inlist("`ic'","tstat","t","3")   local icn 3
    else {
        di as err "ic() must be aic, bic or tstat"
        exit 198
    }
    if `pmax' < 0 | `pmax' > 12 {
        di as err "pmax() must lie in [0, 12]"
        exit 198
    }
    if `mod'==2 & `nbreak'>0 & `pmax'==0 {
        di as err "the Lee-Tieslau trend-break test needs pmax() >= 1 (as in GAUSS)"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie in (0, 0.5)"
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
    if `T' < `pmax' + 12 {
        di as err "too few time periods (T = `T') for pmax(`pmax')"
        exit 2001
    }
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    sort `ivar' `tvar'
    tempname IND tv
    local ppr = ("`paper'" != "")
    mata: _xtpdlm_run("`varlist'", "`touse'", `N', `T', `mod', `nbreak', `pmax', `icn', `trim', `ppr')
    matrix `IND' = r(ind)
    local pd   = r(PDLM)
    local Em   = r(mean)
    local Vm   = r(var)
    local pval = normal(`pd')
    qui levelsof `tvar' if `touse', local(tlev)
    mata: st_matrix("`tv'", strtoreal(tokens(st_local("tlev")))')
    // map break indices to time values
    if `nbreak' > 0 {
        forvalues i = 1/`N' {
            forvalues b = 1/`nbreak' {
                local ix = `IND'[`i',2+`b']
                matrix `IND'[`i',2+`b'] = `tv'[`ix',1]
            }
        }
    }
    if `nbreak'==0 matrix colnames `IND' = LM lags
    if `nbreak'==1 matrix colnames `IND' = LM lags break1
    if `nbreak'==2 matrix colnames `IND' = LM lags break1 break2
    matrix rownames `IND' = `units'

    local ttl = cond(`mod'==1, "Im, Lee and Tieslau (2005) panel LM test with level shifts", ///
                               "Lee and Tieslau (2019) panel LM test with level and trend shifts")
    if `nbreak'==0 local ttl "Panel LM unit-root test, no break (Schmidt-Phillips LM)"
    local icl = cond(`icn'==1,"AIC",cond(`icn'==2,"BIC","t-sig (10%)"))
    di
    di as txt "`ttl'"
    di as txt "{hline 70}"
    di as txt "H0: all panels contain a unit root" _col(44) "Number of panels" _col(62) "= " as res %5.0f `N'
    di as txt "H1: some panels are stationary"    _col(44) "Number of periods" _col(62) "= " as res %5.0f `T'
    di as txt "Breaks : " as res "`nbreak'" as txt "   Trimming: " as res %4.2f `trim' _col(44) as txt "Max lags (" as res "`icl'" as txt ")" _col(62) "= " as res %5.0f `pmax'
    di as txt "{hline 70}"
    di as txt _col(5) "Statistic" _col(26) "Value" _col(42) "p-value"
    di as txt "{hline 70}"
    local st = cond(`pval'<.01,"***",cond(`pval'<.05,"**",cond(`pval'<.10,"*","")))
    di as txt _col(5) "Panel LM (Z)" _col(20) as res %11.4f `pd' _col(38) %9.4f `pval' as txt " `st'"
    di as txt _col(5) "mean LM_i" _col(20) as res %11.4f `=r(lmbar)'
    di as txt "{hline 70}"
    di as txt "Left-tailed N(0,1) test; E(LM) = " as res %7.4f `Em' as txt ", V(LM) = " as res %7.4f `Vm'
    di as txt "*** p<0.01, ** p<0.05, * p<0.10"
    if `mod'==2 & `nbreak'>0 {
        if `ppr' di as txt "Lag of each unit: selected at its minimizing break date (option {bf:paper})."
        else     di as txt "Lag of each unit: as in GAUSS tspdlib (default). Option {bf:paper} uses the lag at the minimizing break date."
    }
    if "`table'"=="" {
        di
        di as txt "Unit-specific minimum LM statistics"
        di as txt "{hline 56}"
        if `nbreak'==0 di as txt _col(3) "`ivar'" _col(16) "LM_i" _col(28) "lags"
        if `nbreak'==1 di as txt _col(3) "`ivar'" _col(16) "LM_i" _col(28) "lags" _col(38) "break"
        if `nbreak'==2 di as txt _col(3) "`ivar'" _col(16) "LM_i" _col(28) "lags" _col(38) "break 1" _col(49) "break 2"
        di as txt "{hline 56}"
        forvalues i = 1/`N' {
            local u : word `i' of `units'
            if `nbreak'==0 di as txt _col(3) "`u'" _col(10) as res %10.4f `IND'[`i',1] _col(26) %6.0f `IND'[`i',2]
            if `nbreak'==1 di as txt _col(3) "`u'" _col(10) as res %10.4f `IND'[`i',1] _col(26) %6.0f `IND'[`i',2] _col(34) %9.0g `IND'[`i',3]
            if `nbreak'==2 di as txt _col(3) "`u'" _col(10) as res %10.4f `IND'[`i',1] _col(26) %6.0f `IND'[`i',2] _col(34) %9.0g `IND'[`i',3] _col(45) %9.0g `IND'[`i',4]
        }
        di as txt "{hline 56}"
    }
    return scalar PDLM = `pd'
    return scalar p    = `pval'
    return scalar mean = `Em'
    return scalar var  = `Vm'
    return scalar N = `N'
    return scalar T = `T'
    return scalar nbreak = `nbreak'
    return scalar pmax = `pmax'
    return scalar trim = `trim'
    return local model "`model'"
    return local ic "`ic'"
    return local formulas = cond(`ppr', "paper", "gauss")
    return local varname "`varlist'"
    return matrix individual = `IND'
end

mata:

real colvector _xtpdlm_diff(real colvector x)
{
    return(0 \ (x[|2 \ rows(x)|] - x[|1 \ rows(x)-1|]))
}

real matrix _xtpdlm_dmat(real matrix x)
{
    return(J(1,cols(x),0) \ (x[|2,1 \ rows(x),cols(x)|] - x[|1,1 \ rows(x)-1,cols(x)|]))
}

real colvector _xtpdlm_lag(real colvector x, real scalar j)
{
    return(J(j,1,.) \ x[|1 \ rows(x)-j|])
}

real matrix _xtpdlm_trim(real matrix x, real scalar a)
{
    return(x[|a+1,1 \ rows(x),cols(x)|])
}

// GAUSS myols: returns (b, se, ssr) packed; b and se are columns
void _xtpdlm_ols(real colvector y, real matrix x, real colvector b,
                 real colvector se, real scalar ssr)
{
    real matrix m
    real colvector e
    m   = luinv(x'*x)
    b   = m*(x'*y)
    e   = y - x*b
    ssr = e'*e
    se  = sqrt(diagonal(m)*(ssr/(rows(y)-cols(x))))
}

real scalar _xtpdlm_getlag(real scalar ic, real scalar pmax, real colvector aicp,
                           real colvector sicp, real colvector tstatp)
{
    real scalar p, j
    if (ic == 1) p = _xtpdlm_minind(aicp)
    if (ic == 2) p = _xtpdlm_minind(sicp)
    if (ic == 3) {
        j = pmax + 1
        while (j >= 1) {
            if (abs(tstatp[j]) > 1.645) break
            j = j - 1
        }
        p = j
        if (p == 0) p = 1
    }
    return(p)
}

real scalar _xtpdlm_minind(real colvector x)
{
    real scalar i, m
    m = 1
    for (i=2; i<=rows(x); i=i+1) {
        if (x[i] < x[m]) m = i
    }
    return(m)
}

// GAUSS LM(y, pmax, ic): Schmidt-Phillips LM, returns (tau, lags)
real rowvector _xtpdlm_lm0(real colvector y, real scalar pmax, real scalar ic)
{
    real scalar T, t, b0, psi, p, j, n, k, LL, ssr, ps
    real colvector dy, ylm, ds, ly, dep, y1, b, se, taup, aicp, sicp, tstatp
    real matrix lmat, x
    T  = rows(y)
    dy = _xtpdlm_trim(_xtpdlm_diff(y), 1)
    b0 = mean(dy)
    psi = y[1] - b0
    ylm = (y :- psi) - (1::T)*b0
    ylm = _xtpdlm_trim(ylm, 1)
    t  = rows(ylm)
    ds = _xtpdlm_diff(ylm)
    ly = _xtpdlm_lag(ylm, 1)
    taup = J(pmax+1,1,0)
    aicp = J(pmax+1,1,0)
    sicp = J(pmax+1,1,0)
    tstatp = J(pmax+1,1,0)
    for (p=0; p<=pmax; p=p+1) {
        dep = _xtpdlm_trim(dy, p+1)
        y1  = _xtpdlm_trim(ly, p+1)
        x   = y1, J(rows(y1),1,1)
        if (p > 0) {
            lmat = J(t, p, .)
            for (j=1; j<=p; j=j+1) {
                lmat[., j] = _xtpdlm_lag(ds, j)
            }
            x = x, _xtpdlm_trim(lmat, p+1)
        }
        b = .
        se = .
        ssr = .
        _xtpdlm_ols(dep, x, b, se, ssr)
        taup[p+1] = b[1]/se[1]
        n = rows(x)
        k = cols(x)
        LL = -n/2*(1 + ln(2*pi()) + ln(ssr/n))
        aicp[p+1] = (2*k - 2*LL)/n
        sicp[p+1] = (k*ln(n) - 2*LL)/n
        tstatp[p+1] = abs(b[k]/se[k])
    }
    ps = _xtpdlm_getlag(ic, pmax, aicp, sicp, tstatp)
    return((taup[ps], ps-1))
}

real matrix _xtpdlm_zmat(real scalar t, real scalar model, real scalar nb,
                         real scalar tb1, real scalar tb2)
{
    real matrix z
    real colvector du1, du2, dt1, dt2, dt
    dt  = (1::t)
    du1 = J(tb1,1,0) \ J(t-tb1,1,1)
    if (nb == 1) {
        if (model == 1) z = dt, du1
        if (model == 2) {
            dt1 = J(tb1,1,0) \ (1::(t-tb1))
            z = dt, du1, dt1
        }
    }
    if (nb == 2) {
        du2 = J(tb2,1,0) \ J(t-tb2,1,1)
        if (model == 1) z = dt, du1, du2
        if (model == 2) {
            dt1 = J(tb1,1,0) \ (1::(t-tb1))
            dt2 = J(tb2,1,0) \ (1::(t-tb2))
            z = dt, du1, dt1, du2, dt2
        }
    }
    return(z)
}

// GAUSS LM_1break / LM_2breaks (lt = 0) and _get_LMtrend_1break/2breaks (lt = 1)
// returns (LM_min, lags, tb1, tb2)
real rowvector _xtpdlm_lmbr(real colvector y, real scalar model, real scalar nb,
                            real scalar pmax, real scalar ic, real scalar trimm,
                            real scalar lt, real scalar paper)
{
    real scalar t, T1, T2, tb1, tb2, tb2s, LMmin, tb1m, tb2m, optlag, s0, p, j,
                lmk, ssr, laglm, stat
    real colvector dyf, dy, b0, st, s2, dst, ls, b, se, aicp, sicp, tstatp, lmt, ylm, dylm
    real matrix z, dzf, dz, lmat, ds, x
    t = rows(y)
    LMmin = 1000
    tb1m = 0
    tb2m = 0
    optlag = 0
    laglm = 1
    T1 = round(trimm*t)
    T2 = round((1-trimm)*t)
    if (T1 < pmax+2) T1 = pmax + 3
    dyf = _xtpdlm_diff(y)
    for (tb1=T1; tb1<=T2; tb1=tb1+1) {
        tb2s = tb1
        if (nb == 2) {
            tb2s = tb1 + 2
            if (model == 2) tb2s = tb1 + 3
        }
        for (tb2=tb2s; tb2<=T2; tb2=tb2+1) {
            z   = _xtpdlm_zmat(t, model, nb, tb1, tb2)
            dzf = _xtpdlm_dmat(z)
            dy  = _xtpdlm_trim(dyf, 1)
            dz  = _xtpdlm_trim(dzf, 1)
            b0  = luinv(dz'*dz)*(dz'*dy)
            s0  = y[1] - z[1,.]*b0
            st  = (y :- s0) - z*b0
            if (lt == 0) {
                if (pmax == 0) {
                    ls = _xtpdlm_trim(_xtpdlm_lag(st,1), 1)
                    x  = ls, dz
                    b = .
                    se = .
                    ssr = .
                    _xtpdlm_ols(dy, x, b, se, ssr)
                    lmk = b[1]/se[1]
                    p = 1
                }
                if (pmax > 0) {
                    dst = _xtpdlm_trim(_xtpdlm_diff(st), 1)
                    aicp = J(pmax+1,1,0)
                    sicp = J(pmax+1,1,0)
                    tstatp = J(pmax+1,1,0)
                    lmt = J(pmax+1,1,0)
                    for (p=0; p<=pmax; p=p+1) {
                        dy = _xtpdlm_trim(dyf, p+1)
                        ls = _xtpdlm_trim(_xtpdlm_lag(st,1), p+1)
                        dz = _xtpdlm_trim(dzf, p+1)
                        x  = ls, dz
                        if (p > 0) {
                            lmat = J(rows(dst), p, .)
                            for (j=1; j<=p; j=j+1) {
                                lmat[., j] = _xtpdlm_lag(dst, j)
                            }
                            x = x, _xtpdlm_trim(lmat, p)
                        }
                        b = .
                        se = .
                        ssr = .
                        _xtpdlm_ols(dy, x, b, se, ssr)
                        aicp[p+1] = ln(ssr/rows(x)) + 2*(cols(x)+2)/rows(x)
                        sicp[p+1] = ln(ssr/rows(x)) + (cols(x)+2)*ln(rows(x))/rows(x)
                        tstatp[p+1] = b[cols(x)]/se[cols(x)]
                        lmt[p+1] = b[1]/se[1]
                    }
                    p = _xtpdlm_getlag(ic, pmax, aicp, sicp, tstatp)
                    lmk = lmt[p]
                }
                if (lmk < LMmin) {
                    tb1m = tb1
                    tb2m = tb2
                    LMmin = lmk
                    optlag = p
                }
            }
            if (lt == 1) {
                s2 = J(t,1,0)
                if (nb == 1) {
                    s2[|1 \ tb1|] = st[|1 \ tb1|]/(tb1/t)
                    s2[|tb1+1 \ t|] = st[|tb1+1 \ t|]/((t-tb1)/t)
                }
                if (nb == 2) {
                    s2[|1 \ tb1|] = st[|1 \ tb1|]/(tb1/t)
                    s2[|tb1+1 \ tb2|] = st[|tb1+1 \ tb2|]/((tb2-tb1)/t)
                    s2[|tb2+1 \ t|] = st[|tb2+1 \ t|]/((t-tb2)/t)
                }
                ylm  = s2
                dylm = _xtpdlm_trim(_xtpdlm_diff(ylm), 1)
                lmat = J(rows(dylm), pmax, .)
                for (j=1; j<=pmax; j=j+1) {
                    lmat[., j] = _xtpdlm_lag(dylm, j)
                }
                aicp = J(pmax+1,1,0)
                sicp = J(pmax+1,1,0)
                tstatp = J(pmax+1,1,0)
                lmt = J(pmax+1,1,0)
                for (p=0; p<=pmax; p=p+1) {
                    dy = _xtpdlm_trim(dyf, p+1)
                    ls = _xtpdlm_trim(_xtpdlm_lag(ylm,1), p+1)
                    dz = _xtpdlm_trim(dzf, p+1)
                    x  = ls, dz
                    if (p > 0) {
                        ds = _xtpdlm_trim(lmat, p)
                        x  = x, ds[|1,1 \ rows(ds),p|]
                    }
                    b = .
                    se = .
                    ssr = .
                    _xtpdlm_ols(dy, x, b, se, ssr)
                    lmt[p+1] = b[1]/se[1]
                    aicp[p+1] = ln(ssr/rows(x)) + 2*(cols(x)+2)/rows(x)
                    sicp[p+1] = ln(ssr/rows(x)) + (cols(x)+2)*ln(rows(x))/rows(x)
                    tstatp[p+1] = abs(b[cols(x)]/se[cols(x)])
                }
                laglm = _xtpdlm_getlag(ic, pmax, aicp, sicp, tstatp)
                stat = lmt[laglm]
                if (stat < LMmin) {
                    tb1m = tb1
                    tb2m = tb2
                    LMmin = stat
                    if (paper != 0) optlag = laglm
                }
                // GAUSS returns the lag of the LAST break-date candidate
                if (paper == 0) optlag = laglm
            }
            if (nb == 1) break
        }
    }
    // pmax = 0 in GAUSS LM_1break/LM_2breaks returns lag -1; report 0
    return((LMmin, max((optlag-1, 0)), tb1m, tb2m))
}

real rowvector _xtpdlm_moments(real scalar T, real colvector lags, real scalar R)
{
    real matrix ilt, ltt
    real rowvector crit
    real scalar row, i, k, m, v, N
    ilt = J(27, 19, .)
    ilt[1,.] = (10,-2.016,0.521,-1.995,0.662,-1.754,0.704,-1.747,1.094,-1.575,1.528,-1.618,2.602,-1.635,8.591,-1.693,10.596,-1.693,10.596)
    ilt[2,.] = (11,-2.008,0.493,-1.991,0.596,-1.778,0.619,-1.763,0.901,-1.590,1.066,-1.593,1.599,-1.482,2.348,-1.693,10.596,-1.693,10.596)
    ilt[3,.] = (12,-2.008,0.481,-1.991,0.561,-1.793,0.568,-1.776,0.752,-1.610,0.894,-1.600,1.242,-1.472,1.551,-1.513,3.137,-1.557,3.708)
    ilt[4,.] = (13,-2.003,0.470,-1.995,0.542,-1.813,0.538,-1.791,0.693,-1.636,0.778,-1.616,1.001,-1.487,1.187,-1.501,1.704,-1.410,2.808)
    ilt[5,.] = (14,-1.995,0.446,-1.986,0.515,-1.819,0.507,-1.802,0.638,-1.650,0.701,-1.632,0.894,-1.509,1.008,-1.509,1.295,-1.400,1.587)
    ilt[6,.] = (15,-1.999,0.447,-1.988,0.494,-1.828,0.487,-1.808,0.588,-1.671,0.639,-1.653,0.813,-1.532,0.897,-1.519,1.120,-1.410,1.289)
    ilt[7,.] = (16,-1.991,0.425,-1.987,0.486,-1.838,0.467,-1.824,0.555,-1.693,0.605,-1.673,0.734,-1.559,0.819,-1.550,1.005,-1.446,1.108)
    ilt[8,.] = (17,-1.998,0.430,-1.988,0.468,-1.849,0.460,-1.833,0.533,-1.703,0.578,-1.688,0.695,-1.578,0.757,-1.565,0.906,-1.459,0.992)
    ilt[9,.] = (18,-1.989,0.414,-1.983,0.448,-1.856,0.440,-1.840,0.504,-1.720,0.540,-1.700,0.635,-1.592,0.694,-1.573,0.823,-1.475,0.902)
    ilt[10,.] = (19,-1.989,0.416,-1.984,0.455,-1.865,0.439,-1.852,0.494,-1.741,0.534,-1.723,0.614,-1.620,0.662,-1.599,0.778,-1.501,0.850)
    ilt[11,.] = (20,-1.991,0.410,-1.987,0.445,-1.868,0.431,-1.858,0.491,-1.751,0.515,-1.729,0.583,-1.630,0.626,-1.610,0.734,-1.518,0.803)
    ilt[12,.] = (21,-1.984,0.400,-1.981,0.424,-1.874,0.415,-1.864,0.470,-1.762,0.492,-1.745,0.557,-1.655,0.597,-1.635,0.691,-1.546,0.746)
    ilt[13,.] = (22,-1.987,0.402,-1.983,0.431,-1.879,0.414,-1.870,0.463,-1.770,0.481,-1.752,0.541,-1.662,0.578,-1.649,0.662,-1.564,0.710)
    ilt[14,.] = (23,-1.984,0.396,-1.983,0.424,-1.883,0.411,-1.875,0.449,-1.779,0.461,-1.767,0.520,-1.683,0.556,-1.665,0.623,-1.583,0.672)
    ilt[15,.] = (24,-1.982,0.394,-1.982,0.423,-1.885,0.403,-1.879,0.445,-1.789,0.451,-1.772,0.500,-1.691,0.530,-1.678,0.602,-1.598,0.638)
    ilt[16,.] = (25,-1.983,0.389,-1.980,0.414,-1.890,0.399,-1.882,0.432,-1.798,0.442,-1.786,0.493,-1.706,0.527,-1.691,0.582,-1.612,0.624)
    ilt[17,.] = (30,-1.980,0.381,-1.979,0.399,-1.905,0.384,-1.900,0.402,-1.824,0.408,-1.814,0.436,-1.746,0.456,-1.734,0.497,-1.667,0.522)
    ilt[18,.] = (35,-1.979,0.369,-1.979,0.387,-1.919,0.374,-1.914,0.390,-1.849,0.391,-1.842,0.416,-1.785,0.427,-1.777,0.460,-1.717,0.478)
    ilt[19,.] = (40,-1.977,0.365,-1.976,0.379,-1.922,0.370,-1.917,0.383,-1.863,0.381,-1.857,0.400,-1.807,0.409,-1.800,0.433,-1.746,0.444)
    ilt[20,.] = (45,-1.978,0.365,-1.977,0.373,-1.932,0.363,-1.928,0.371,-1.879,0.365,-1.874,0.381,-1.828,0.385,-1.822,0.408,-1.773,0.419)
    ilt[21,.] = (50,-1.974,0.359,-1.973,0.366,-1.932,0.358,-1.933,0.369,-1.892,0.367,-1.888,0.378,-1.845,0.383,-1.841,0.399,-1.798,0.404)
    ilt[22,.] = (60,-1.973,0.354,-1.975,0.363,-1.940,0.355,-1.938,0.363,-1.903,0.357,-1.902,0.366,-1.869,0.368,-1.867,0.380,-1.830,0.381)
    ilt[23,.] = (70,-1.974,0.352,-1.974,0.356,-1.946,0.348,-1.945,0.353,-1.915,0.351,-1.912,0.354,-1.883,0.354,-1.879,0.365,-1.850,0.367)
    ilt[24,.] = (80,-1.972,0.350,-1.972,0.355,-1.948,0.350,-1.947,0.355,-1.921,0.350,-1.919,0.351,-1.893,0.352,-1.892,0.359,-1.864,0.358)
    ilt[25,.] = (90,-1.977,0.347,-1.978,0.351,-1.955,0.344,-1.954,0.348,-1.931,0.345,-1.930,0.352,-1.906,0.352,-1.906,0.358,-1.882,0.354)
    ilt[26,.] = (100,-1.972,0.346,-1.972,0.348,-1.952,0.343,-1.951,0.345,-1.930,0.341,-1.930,0.344,-1.911,0.346,-1.910,0.351,-1.888,0.351)
    ilt[27,.] = (200,-1.971,0.339,-1.971,0.339,-1.962,0.338,-1.962,0.337,-1.952,0.335,-1.952,0.336,-1.941,0.334,-1.940,0.336,-1.929,0.333)
    ltt = J(7, 19, .)
    ltt[1,.] = (25,-2.69,0.40,-2.73,0.40,-2.67,0.37,-2.68,0.42,-2.59,0.50,-2.57,0.62,-2.44,0.73,-2.35,0.89,-2.18,1.04)
    ltt[2,.] = (50,-2.67,0.37,-2.68,0.36,-2.65,0.34,-2.67,0.34,-2.63,0.34,-2.64,0.36,-2.59,0.37,-2.58,0.41,-2.52,0.44)
    ltt[3,.] = (100,-2.65,0.34,-2.66,0.34,-2.64,0.33,-2.65,0.32,-2.63,0.32,-2.64,0.32,-2.62,0.31,-2.62,0.32,-2.60,0.32)
    ltt[4,.] = (200,-2.64,0.33,-2.64,0.33,-2.63,0.32,-2.64,0.32,-2.63,0.31,-2.63,0.31,-2.63,0.31,-2.63,0.31,-2.62,0.31)
    ltt[5,.] = (50,-3.22,0.37,-3.27,0.35,-3.26,0.32,-3.30,0.33,-3.27,0.35,-3.28,0.40,-3.21,0.45,-3.18,0.53,-3.08,0.59)
    ltt[6,.] = (100,-3.19,0.34,-3.21,0.33,-3.21,0.31,-3.23,0.30,-3.23,0.30,-3.24,0.30,-3.23,0.29,-3.24,0.30,-3.22,0.31)
    ltt[7,.] = (200,-3.17,0.33,-3.18,0.32,-3.18,0.32,-3.19,0.31,-3.19,0.30,-3.20,0.30,-3.20,0.29,-3.21,0.29,-3.20,0.28)
    if (R == 0) {
        // GAUSS _get_ILTmoments row map (T = 10 and T = 53-54 left undefined in GAUSS are mapped to the nearest row)
        row = 1
        if (T > 10 & T < 25) row = T - 10 + 1
        if (T > 24 & T < 28) row = 16
        if (T > 27 & T < 33) row = 17
        if (T > 32 & T < 38) row = 18
        if (T > 37 & T < 43) row = 19
        if (T > 42 & T < 48) row = 20
        if (T > 47 & T < 55) row = 21
        if (T > 54 & T < 65) row = 22
        if (T > 64 & T < 75) row = 23
        if (T > 74 & T < 85) row = 24
        if (T > 84 & T < 95) row = 25
        if (T > 94 & T < 150) row = 26
        if (T > 149) row = 27
        crit = ilt[row, .]
    }
    if (R == 1) {
        row = 1
        if (T > 33 & T <= 75) row = 2
        if (T > 75 & T <= 150) row = 3
        if (T > 150) row = 4
        crit = ltt[row, .]
    }
    if (R == 2) {
        row = 5
        if (T > 75 & T <= 150) row = 6
        if (T > 150) row = 7
        crit = ltt[row, .]
    }
    N = rows(lags)
    m = 0
    v = 0
    for (i=1; i<=N; i=i+1) {
        k = lags[i]
        if (k > 8) k = 8
        m = m + crit[2+2*k]
        v = v + crit[3+2*k]
    }
    return((m/N, v/N))
}

void _xtpdlm_run(string scalar vn, string scalar touse, real scalar N, real scalar T,
                 real scalar model, real scalar nb, real scalar pmax, real scalar ic,
                 real scalar trimm, real scalar paper)
{
    real matrix Y, ind
    real colvector y
    real rowvector r, mom
    real scalar i, R, pd
    Y = st_data(., vn, touse)
    ind = J(N, 2+nb, .)
    for (i=1; i<=N; i=i+1) {
        y = Y[|(i-1)*T+1 \ i*T|]
        if (nb == 0) {
            r = _xtpdlm_lm0(y, pmax, ic)
            ind[i,.] = r
        }
        if (nb > 0) {
            r = _xtpdlm_lmbr(y, model, nb, pmax, ic, trimm, model-1, paper)
            ind[i,1] = r[1]
            ind[i,2] = r[2]
            ind[i,3] = r[3]
            if (nb == 2) ind[i,4] = r[4]
        }
    }
    R = 0
    if (model == 2) R = nb
    mom = _xtpdlm_moments(T, ind[.,2], R)
    pd = sqrt(N)*(mean(ind[.,1]) - mom[1])/sqrt(mom[2])
    st_rclear()
    st_numscalar("r(PDLM)", pd)
    st_numscalar("r(mean)", mom[1])
    st_numscalar("r(var)", mom[2])
    st_numscalar("r(lmbar)", mean(ind[.,1]))
    st_matrix("r(ind)", ind)
}
end
