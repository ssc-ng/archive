*! _tsurcoint_kpssc 1.0.0  12nov2026   (engine of: tsurcoint shin | cissanso)
*! KPSS-type tests of the null of cointegration: Shin (1994) and
*! Carrion-i-Silvestre and Sanso (2006) with one structural break
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -tsurcoint- library (ports of GAUSS time-series tests).
*!
*! Faithful port of the GAUSS routines coint_shin and coint_cissanso
*!   (tspdlib 3.0.0, with _get_lrv_type, bartlett, qs, spc_bartlett, spc_qs,
*!   kurozumi_bartlett, kurozumi_qs and _get_LeadsLags) by Saban Nazlioglu,
*!   updated from the GAUSS code of Carrion-i-Silvestre and Sanso.
*!
*! References:
*!   Shin, Y. (1994). A residual-based test of the null of cointegration
*!     against the alternative of no cointegration. Econometric Theory 10(1):
*!     91-115. <doi:10.1017/S0266466600008240>
*!   Carrion-i-Silvestre, J. L., Sanso, A. (2006). Testing the null of
*!     cointegration with structural breaks. Oxford Bulletin of Economics and
*!     Statistics 68(5): 623-646. <doi:10.1111/j.1468-0084.2006.00180.x>
*!   Carrion-i-Silvestre, J. L., Sanso, A. (2006). A guide to the computation of
*!     stationarity tests. Empirical Economics 31(2): 433-448.
*!     <doi:10.1007/s00181-005-0023-5>
*!   Sul, D., Phillips, P. C. B., Choi, C.-Y. (2005). Prewhitening bias in HAC
*!     estimation. Oxford Bulletin of Economics and Statistics 67(4): 517-546.
*!   Kurozumi, E. (2002). Testing for stationarity with a break. Journal of
*!     Econometrics 108(1): 63-99. <doi:10.1016/S0304-4076(01)00106-3>
*!
*! Step -> code map (see -help tsurcoint_shin-, -help tsurcoint_cissanso-):
*!   OLS and DOLS (q leads and lags) cointegrating regressions -> _tskp_dols
*!   seven long-run variance estimators                         -> _tskp_lrv
*!   statistic T^-2 sum S_t^2 / lrv                             -> _tskp_one
*!   break date by min SSR (OLS and DOLS separately)            -> _tskp_run
*!   Shin (1994) and CiS-S (2006) critical values               -> _tskp_cv

program _tsurcoint_kpssc, rclass
    version 14.0
    gettoken test 0 : 0
    syntax varlist(min=2 numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        BWidth(integer -1)   ///
        LRV(string)          ///
        LEADs(integer -1)    ///
        TRIM(real 0.10)      ///
        PAPer                ]

    marksample touse
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "tsurcoint needs a single time series: the data are {bf:xtset}/panel. Use {help xturcoint} for panel tests."
        exit 459
    }
    gettoken dv xv : varlist
    local xv = strtrim("`xv'")
    local k : word count `xv'
    if "`test'" == "shin" {
        if ("`model'"=="") local model "constant"
        local model = strlower("`model'")
        if inlist("`model'","none","n","0")            local mod 0
        else if inlist("`model'","constant","c","1")   local mod 1
        else if inlist("`model'","trend","ct","t","2") local mod 2
        else {
            di as err "model() must be none, constant or trend"
            exit 198
        }
    }
    if "`test'" == "cissanso" {
        if ("`model'"=="") local model "an"
        local model = strlower("`model'")
        if inlist("`model'","an","level","1")             local mod 1
        else if inlist("`model'","a","leveltrend","2")    local mod 2
        else if inlist("`model'","d","regime","3")        local mod 3
        else if inlist("`model'","e","regimetrend","4")   local mod 4
        else {
            di as err "model() must be an (level shift), a (level shift with trend), d (regime shift) or e (regime and trend shift)"
            exit 198
        }
        if `trim' <= 0 | `trim' >= 0.5 {
            di as err "trim() must lie in (0, 0.5)"
            exit 198
        }
    }
    if ("`lrv'"=="") local lrv "iid"
    local lrv = strlower("`lrv'")
    local vm = 0
    if "`lrv'"=="iid"          local vm 1
    if "`lrv'"=="bartlett"     local vm 2
    if "`lrv'"=="qs"           local vm 3
    if "`lrv'"=="spcbartlett"  local vm 4
    if "`lrv'"=="spcqs"        local vm 5
    if "`lrv'"=="kurbartlett"  local vm 6
    if "`lrv'"=="kurqs"        local vm 7
    if `vm' == 0 {
        di as err "lrv() must be iid, bartlett, qs, spcbartlett, spcqs, kurbartlett or kurqs"
        exit 198
    }
    qui count if `touse'
    local T = r(N)
    qui summ `tvar' if `touse', meanonly
    if (r(max) - r(min) + 1) != `T' {
        di as err "the sample must be contiguous (no gaps or missing values inside the sample)"
        exit 459
    }
    if `bwidth' < 0 local bwidth = round(4*(`T'/100)^(2/9))
    if `leads'  < 0 local leads  = int(4*(`T'/100)^(2/9))
    local ppr = ("`paper'" != "")
    sort `tvar'
    tempname tv
    local tn = cond("`test'"=="shin", 1, 2)
    mata: _tskp_run("`dv'", "`xv'", "`touse'", `tn', `mod', `bwidth', `vm', `leads', `trim', `ppr')
    local s1 = r(s1)
    local s2 = r(s2)
    local hascv = (r(cv1) < .)
    local c1 = r(cv1)
    local c5 = r(cv5)
    local c10 = r(cv10)
    if `tn'==2 {
        local i1 = r(tb1)
        local i2 = r(tb2)
        qui levelsof `tvar' if `touse', local(tlev)
        mata: st_matrix("`tv'", strtoreal(tokens(st_local("tlev")))')
        local d1 = `tv'[`i1',1]
        local d2 = `tv'[`i2',1]
        local f1 = `i1'/`T'
        local f2 = `i2'/`T'
    }

    local lrl = cond(`vm'==1,"iid",cond(`vm'==2,"Bartlett",cond(`vm'==3,"Quadratic Spectral",cond(`vm'==4,"SPC Bartlett (Sul-Phillips-Choi)",cond(`vm'==5,"SPC QS (Sul-Phillips-Choi)",cond(`vm'==6,"Kurozumi Bartlett","Kurozumi QS"))))))
    if `tn'==1 {
        local ttl "Shin (1994) test of the null of cointegration"
        local mlab = cond(`mod'==0,"none",cond(`mod'==1,"constant","constant and trend"))
    }
    else {
        local ttl "Carrion-i-Silvestre and Sanso (2006) cointegration test with one structural break"
        local mlab = cond(`mod'==1,"An: level shift",cond(`mod'==2,"A: level shift with trend",cond(`mod'==3,"D: regime shift","E: regime and trend shift")))
    }
    di
    di as txt "`ttl'"
    di as txt "{hline 72}"
    di as txt "H0: cointegration" _col(46) "Observations" _col(64) "= " as res %6.0f `T'
    di as txt "H1: no cointegration" _col(46) "Regressors (k)" _col(64) "= " as res %6.0f `k'
    di as txt "Model : " as res "`mlab'" _col(46) as txt "DOLS leads/lags" _col(64) "= " as res %6.0f `leads'
    di as txt "Long-run variance : " as res "`lrl'" as txt cond(inlist(`vm',2,3),"  (bandwidth `bwidth')","")
    if `tn'==2 di as txt "Break (min SSR) : OLS " as res "`d1'" as txt " (" as res %5.3f `f1' as txt "),  DOLS " as res "`d2'" as txt " (" as res %5.3f `f2' as txt ");  trimming " as res %4.2f `trim'
    di as txt "{hline 72}"
    di as txt _col(5) "Estimator" _col(28) "Statistic" _col(46) "1%" _col(56) "5%" _col(66) "10%"
    di as txt "{hline 72}"
    foreach e in 1 2 {
        local v = `s`e''
        local nm = cond(`e'==1,"OLS","DOLS")
        if `hascv' {
            local st = cond(`v'>`c1',"***",cond(`v'>`c5',"**",cond(`v'>`c10',"*","")))
            di as txt _col(5) "`nm'" _col(22) as res %12.4f `v' _col(40) %8.4f `c1' %10.4f `c5' %10.4f `c10' as txt " `st'"
        }
        else di as txt _col(5) "`nm'" _col(22) as res %12.4f `v' _col(42) as txt "critical values not tabulated for k = `k'"
    }
    di as txt "{hline 72}"
    di as txt "Right-tailed; large values reject cointegration.  *** 1%, ** 5%, * 10%"
    if `tn'==2 & `hascv' di as txt "Critical values: Carrion-i-Silvestre and Sanso (2006) at the DOLS break fraction (used for both rows, as in GAUSS)."
    if `ppr'  di as txt "Formulas: paper (option {bf:paper}): the DOLS statistic is normalised by the DOLS sample size."
    if !`ppr' di as txt "Formulas: GAUSS tspdlib (default): both statistics are normalised by the full T. Option {bf:paper}: DOLS sample size."

    return scalar stat_ols  = `s1'
    return scalar stat_dols = `s2'
    if `hascv' {
        return scalar cv1  = `c1'
        return scalar cv5  = `c5'
        return scalar cv10 = `c10'
    }
    if `tn'==2 {
        return scalar break_ols  = `d1'
        return scalar break_dols = `d2'
        return scalar lambda_ols  = `f1'
        return scalar lambda_dols = `f2'
        return scalar trim = `trim'
    }
    return scalar T = `T'
    return scalar k = `k'
    return scalar leads = `leads'
    return scalar bwidth = `bwidth'
    return local lrv "`lrv'"
    return local model "`model'"
    return local formulas = cond(`ppr', "paper", "gauss")
    return local depvar "`dv'"
    return local indepvars "`xv'"
end

mata:

real scalar _tskp_bart(real colvector e, real scalar l, real scalar T)
{
    real scalar lrv, bw, n
    n = rows(e)
    lrv = (e'*e)/T
    for (bw=1; bw<=l; bw=bw+1) {
        lrv = lrv + 2*(e[|1 \ n-bw|]'*e[|1+bw \ n|])*(1 - bw/(l+1))/T
    }
    return(lrv)
}

real scalar _tskp_qs(real colvector e, real scalar l, real scalar T)
{
    real scalar lrv, bw, n, x1, x2, w
    n = rows(e)
    lrv = (e'*e)/T
    for (bw=1; bw<=l; bw=bw+1) {
        x1 = bw/l
        x2 = 6*pi()*x1/5
        w  = (25/(12*(pi()*x1)^2))*(sin(x2)/x2 - cos(x2))
        lrv = lrv + 2*(e[|1 \ n-bw|]'*e[|1+bw \ n|])*w/T
    }
    return(lrv)
}

real scalar _tskp_ls1(real colvector y, real colvector x)
{
    return((x'*y)/(x'*x))
}

// Sul-Phillips-Choi: AR(i) prewhitening chosen by BIC, then Bartlett (qs = 0) or QS (qs = 1)
real scalar _tskp_spc(real colvector e, real scalar lags, real scalar T, real scalar qs)
{
    real scalar i, j, n, bic, minbic, a, l, lrv, rc, w, m
    real colvector rho, res, rt, rs, d, rho_k, res_k
    real matrix X
    n = rows(e)
    if (lags <= 0) lags = 1
    minbic = 1e25
    for (i=1; i<=lags; i=i+1) {
        X = J(n-i, i, .)
        for (j=1; j<=i; j=j+1) {
            X[., j] = e[|i+1-j \ n-j|]
        }
        d  = e[|i+1 \ n|]
        rt = luinv(X'*X)*(X'*d)
        rs = d - X*rt
        bic = ln((rs'*rs)/(T-lags)) + (i*ln(T-lags)/(T-lags))
        if (bic < minbic) {
            minbic = bic
            rho_k = rt
            res_k = rs
        }
    }
    rho = rho_k
    res = res_k
    a = _tskp_ls1(res[|2 \ rows(res)|], res[|1 \ rows(res)-1|])
    if (qs == 0) {
        l = trunc(1.1447*(4*a^2*T/((1+a)^2*(1-a)^2))^(1/3))
        lrv = _tskp_bart(res, l, T)
    } else {
        l = trunc(1.3221*(4*a^2*T/((1+a)^2*(1-a)^2))^(1/5))
        m = rows(res)
        lrv = (res'*res)/T
        for (i=1; i<=l; i=i+1) {
            w = 25/(12*pi()^2*(i/l)^2)*(sin(6*pi()*i/(l*5))/(6*pi()*i/(l*5)) - cos(6*pi()*i/(l*5)))
            lrv = lrv + 2*(res[|1 \ m-i|]'*res[|1+i \ m|])*w/T
        }
    }
    rc = lrv/(1 - sum(rho))^2
    return(min((rc, T*lrv)))
}

// Kurozumi (2002) bandwidth with an AR(1) cap at 0.7
real scalar _tskp_kur(real colvector e, real scalar T, real scalar qs)
{
    real scalar a, k, l, lrv, i, w, n
    n = rows(e)
    a = _tskp_ls1(e[|2 \ n|], e[|1 \ n-1|])
    k = 0.7
    if (qs == 0) {
        l = min((1.1447*(4*a^2*T/((1+a)^2*(1-a)^2))^(1/3), 1.1447*(4*k^2*T/((1+k)^2*(1-k)^2))^(1/3)))
        l = trunc(l)
        return(_tskp_bart(e, l, n))
    }
    l = min((1.3221*(4*a^2*T/((1+a)^2*(1-a)^2))^(1/5), 1.3221*(4*k^2*T/((1+k)^2*(1-k)^2))^(1/5)))
    l = trunc(l)
    lrv = (e'*e)/n
    for (i=1; i<=l; i=i+1) {
        w = 25/(12*pi()^2*(i/l)^2)*(sin(6*pi()*i/(l*5))/(6*pi()*i/(l*5)) - cos(6*pi()*i/(l*5)))
        lrv = lrv + 2*(e[|1 \ n-i|]'*e[|1+i \ n|])*w/n
    }
    return(lrv)
}

// GAUSS _get_lrv_type(varm, ssr, e, bwl) with maxlags = 8 and bigT = rows(e)
real scalar _tskp_lrv(real scalar vm, real colvector e, real scalar bwl)
{
    real scalar T
    T = rows(e)
    if (vm == 1) return((e'*e)/T)
    if (vm == 2) return(_tskp_bart(e, bwl, T))
    if (vm == 3) return(_tskp_qs(e, bwl, T))
    if (vm == 4) return(_tskp_spc(e, 8, T, 0))
    if (vm == 5) return(_tskp_spc(e, 8, T, 1))
    if (vm == 6) return(_tskp_kur(e, T, 0))
    return(_tskp_kur(e, T, 1))
}

// OLS and DOLS residuals for a deterministic/regressor matrix z
void _tskp_dols(real colvector y, real matrix x, real matrix z, real scalar q,
                real colvector e1, real colvector e2)
{
    real matrix dx, xd, zd, Ld
    real scalar T, c, j, n
    real colvector yd
    T  = rows(y)
    e1 = y - z*(luinv(z'*z)*(z'*y))
    dx = J(1,cols(x),0) \ (x[|2,1 \ T,cols(x)|] - x[|1,1 \ T-1,cols(x)|])
    // GAUSS _get_LeadsLags: for each regressor, leads 1..q then lags 1..q
    xd = z
    Ld = J(T, 0, .)
    for (c=1; c<=cols(x); c=c+1) {
        for (j=1; j<=q; j=j+1) {
            Ld = Ld, (dx[|1+j,c \ T,c|] \ J(j,1,.))
        }
    }
    xd = xd, Ld, dx
    Ld = J(T, 0, .)
    for (c=1; c<=cols(x); c=c+1) {
        for (j=1; j<=q; j=j+1) {
            Ld = Ld, (J(j,1,.) \ dx[|1,c \ T-j,c|])
        }
    }
    xd = xd, Ld
    zd = xd[|q+2,1 \ T-q,cols(xd)|]
    yd = y[|q+2 \ T-q|]
    e2 = yd - zd*(luinv(zd'*zd)*(zd'*yd))
}

real scalar _tskp_stat(real colvector e, real scalar Tn, real scalar vm, real scalar bwl)
{
    real colvector S
    S = runningsum(e)
    return(Tn^(-2)*(S'*S)/_tskp_lrv(vm, e, bwl))
}

real rowvector _tskp_cv(real scalar tn, real scalar model, real scalar k, real scalar lam)
{
    real matrix m
    real scalar c
    if (tn == 1) {
        if (k > 5) return((., ., .))
        if (model == 0) m = (2.126, 1.199, 0.841 \ 1.623, 0.895, 0.624 \ 1.305, 0.682, 0.475 \ 1.003, 0.537, 0.374 \ 0.781, 0.433, 0.307)
        if (model == 1) m = (0.533, 0.314, 0.231 \ 0.380, 0.221, 0.163 \ 0.271, 0.159, 0.121 \ 0.208, 0.121, 0.094 \ 0.158, 0.097, 0.075)
        if (model == 2) m = (0.184, 0.121, 0.097 \ 0.150, 0.101, 0.081 \ 0.126, 0.085, 0.069 \ 0.109, 0.073, 0.056 \ 0.087, 0.061, 0.050)
        return(m[k,.])
    }
    if (k > 4) return((., ., .))
    // rows: 10%, 5%, 1%; columns: lambda = 0.1, ..., 0.5
    if (model == 1) {
        if (k == 1) m = (0.1932, 0.1583, 0.1395, 0.1281, 0.1256 \ 0.2582, 0.2087, 0.1855, 0.1632, 0.1553 \ 0.4546, 0.3543, 0.2948, 0.2503, 0.2287)
        if (k == 2) m = (0.1336, 0.1157, 0.1079, 0.1020, 0.1029 \ 0.1796, 0.1557, 0.1400, 0.1306, 0.1292 \ 0.3116, 0.2631, 0.2259, 0.2035, 0.1903)
        if (k == 3) m = (0.1007, 0.0907, 0.0856, 0.0847, 0.0840 \ 0.1319, 0.1179, 0.1094, 0.1063, 0.1051 \ 0.2238, 0.1989, 0.1773, 0.1602, 0.1594)
        if (k == 4) m = (0.0799, 0.0738, 0.0712, 0.0704, 0.0706 \ 0.1037, 0.0924, 0.0873, 0.0878, 0.0874 \ 0.1754, 0.1502, 0.1385, 0.1365, 0.350)
    }
    if (model == 2) {
        if (k == 1) m = (0.0827, 0.0736, 0.0747, 0.0821, 0.0840 \ 0.1028, 0.0855, 0.0907, 0.1021, 0.1060 \ 0.1537, 0.1305, 0.1251, 0.1508, 0.1642)
        if (k == 2) m = (0.0700, 0.0630, 0.0650, 0.0690, 0.0693 \ 0.0865, 0.0759, 0.0774, 0.0852, 0.0858 \ 0.1273, 0.1095, 0.1083, 0.1254, 0.1348)
        if (k == 3) m = (0.0594, 0.0554, 0.0571, 0.0581, 0.0584 \ 0.0728, 0.0670, 0.0692, 0.0712, 0.0725 \ 0.1064, 0.0941, 0.0971, 0.1035, 0.1103)
        if (k == 4) m = (0.0507, 0.0490, 0.0501, 0.0509, 0.0510 \ 0.0616, 0.0588, 0.0606, 0.0617, 0.0621 \ 0.0898, 0.0846, 0.0864, 0.0886, 0.0938)
    }
    if (model == 3) {
        if (k == 1) m = (0.1908, 0.1547, 0.1265, 0.1098, 0.1044 \ 0.2560, 0.2067, 0.1670, 0.1395, 0.1309 \ 0.4463, 0.3449, 0.2669, 0.2224, 0.1941)
        if (k == 2) m = (0.1319, 0.1087, 0.0885, 0.0760, 0.0735 \ 0.1759, 0.1459, 0.1163, 0.0969, 0.0922 \ 0.3068, 0.2510, 0.1942, 0.1578, 0.1419)
        if (k == 3) m = (0.0983, 0.0803, 0.0664, 0.0572, 0.0542 \ 0.1286, 0.1049, 0.0851, 0.0721, 0.0672 \ 0.2307, 0.1816, 0.1425, 0.1145, 0.1039)
        if (k == 4) m = (0.0772, 0.0616, 0.0512, 0.0451, 0.0423 \ 0.0981, 0.0791, 0.0648, 0.0548, 0.0514 \ 0.1579, 0.1312, 0.1048, 0.0852, 0.0766)
    }
    if (model == 4) {
        if (k == 1) m = (0.0808, 0.0654, 0.0538, 0.0463, 0.0436 \ 0.1004, 0.0804, 0.0659, 0.0552, 0.0512 \ 0.1480, 0.1223, 0.0960, 0.0763, 0.0681)
        if (k == 2) m = (0.0671, 0.0540, 0.0448, 0.0387, 0.0363 \ 0.0832, 0.0661, 0.0544, 0.0462, 0.0423 \ 0.1218, 0.0980, 0.0795, 0.0641, 0.0574)
        if (k == 3) m = (0.0561, 0.0457, 0.0375, 0.0323, 0.0309 \ 0.0696, 0.0559, 0.0454, 0.0379, 0.0360 \ 0.1040, 0.0821, 0.0660, 0.0529, 0.0474)
        if (k == 4) m = (0.0484, 0.0391, 0.0326, 0.0282, 0.0266 \ 0.0597, 0.0476, 0.0393, 0.0329, 0.0308 \ 0.0899, 0.0703, 0.0570, 0.0454, 0.0411)
    }
    c = round(10*lam)
    if (c > 5) c = 10 - c
    if (c < 1) c = 1
    return((m[3,c], m[2,c], m[1,c]))
}

void _tskp_run(string scalar dv, string scalar xv, string scalar touse, real scalar tn,
               real scalar model, real scalar bwl, real scalar vm, real scalar q,
               real scalar trimm, real scalar paper)
{
    real colvector y, e1, e2, dc, dt, du1, dt1
    real matrix x, z
    real scalar T, s1, s2, t1, t2, tb, ssr1, ssr2, m1, m2, b1, b2, S1, S2, Td
    real rowvector cv
    y = st_data(., dv, touse)
    x = st_data(., tokens(xv), touse)
    T = rows(y)
    dc = J(T,1,1)
    dt = (1::T)
    e1 = .
    e2 = .
    if (tn == 1) {
        z = x
        if (model == 1) z = dc, x
        if (model == 2) z = dc, dt, x
        _tskp_dols(y, x, z, q, e1, e2)
        Td = T
        if (paper) Td = rows(e2)
        s1 = _tskp_stat(e1, T, vm, bwl)
        s2 = _tskp_stat(e2, Td, vm, bwl)
        cv = _tskp_cv(1, model, cols(x), 0)
        st_rclear()
        st_numscalar("r(s1)", s1)
        st_numscalar("r(s2)", s2)
    }
    if (tn == 2) {
        t1 = round(trimm*T)
        t2 = round((1-trimm)*T)
        m1 = 1e6
        m2 = 1e6
        b1 = 0
        b2 = 0
        S1 = 0
        S2 = 0
        for (tb=t1; tb<=t2; tb=tb+1) {
            du1 = J(tb,1,0) \ J(T-tb,1,1)
            dt1 = J(tb,1,0) \ (1::(T-tb))
            if (model == 1) z = dc, du1, x
            if (model == 2) z = dc, du1, dt, x
            if (model == 3) z = dc, du1, x, du1:*x
            if (model == 4) z = dc, du1, x, du1:*x, dt, dt1
            _tskp_dols(y, x, z, q, e1, e2)
            ssr1 = e1'*e1
            ssr2 = e2'*e2
            if (ssr1 < m1) {
                m1 = ssr1
                b1 = tb
                S1 = _tskp_stat(e1, T, vm, bwl)
            }
            if (ssr2 < m2) {
                m2 = ssr2
                b2 = tb
                Td = T
                if (paper) Td = rows(e2)
                S2 = _tskp_stat(e2, Td, vm, bwl)
            }
        }
        cv = _tskp_cv(2, model, cols(x), b2/T)
        st_rclear()
        st_numscalar("r(s1)", S1)
        st_numscalar("r(s2)", S2)
        st_numscalar("r(tb1)", b1)
        st_numscalar("r(tb2)", b2)
    }
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
}
end
