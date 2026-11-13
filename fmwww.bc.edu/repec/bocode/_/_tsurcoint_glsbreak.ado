*! _tsurcoint_glsbreak 1.0.0  12nov2026   (engine of: tsurcoint glsbreak)
*! GLS-detrended unit-root tests (ADF-GLS, PT, MZa, MZt, MSB, MPT) with one or
*! two structural breaks at unknown dates
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -tsurcoint- library (ports of GAUSS time-series tests).
*!
*! Faithful port of the GAUSS routines gls_1break and GLS_2breaks (tspdlib
*!   3.0.0, gls_1br.src and gls_2br.src) by Saban Nazlioglu.
*!
*! References:
*!   Perron, P., Rodriguez, G. (2003). GLS detrending, efficient unit root tests
*!     and structural change. Journal of Econometrics 115(1): 1-27.
*!     <doi:10.1016/S0304-4076(03)00090-3>
*!   Carrion-i-Silvestre, J. L., Kim, D., Perron, P. (2009). GLS-based unit root
*!     tests with multiple structural breaks under both the null and the
*!     alternative hypotheses. Econometric Theory 25(6): 1754-1792.
*!     <doi:10.1017/S0266466609990338>
*!   Ng, S., Perron, P. (2001). Lag length selection and the construction of
*!     unit root tests with good size and power. Econometrica 69(6): 1519-1554.
*!     <doi:10.1111/1468-0262.00256>
*!
*! Step -> code map (see -help tsurcoint_glsbreak-):
*!   break dates by min SSR of the GLS-detrending regression -> _tsgls_run
*!   c-bar: -13.5 (level shift) or CKP response surface      -> _tsgls_cbar
*!   GLS detrending, quasi-differences with a = 1 + c/T     -> _tsgls_detrend
*!   ADF-GLS with lag selection (no deterministics)          -> _tsgls_adf
*!   s2_AR, PT, MZa, MZt, MSB, MPT                           -> _tsgls_s2ar / _tsgls_run

program _tsurcoint_glsbreak, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        BReaks(integer 1)    ///
        PMax(integer 8)      ///
        IC(string)           ///
        PAPer                ]

    marksample touse
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "tsurcoint needs a single time series: the data are {bf:xtset}/panel."
        exit 459
    }
    if ("`model'"=="") local model "both"
    local model = strlower("`model'")
    if inlist("`model'","level","l","0")                local mod 0
    else if inlist("`model'","trend","slope","t","1")   local mod 1
    else if inlist("`model'","both","levtrend","b","2") local mod 2
    else {
        di as err "model() must be level, trend or both"
        exit 198
    }
    if !inlist(`breaks',1,2) {
        di as err "breaks() must be 1 or 2"
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
    if `pmax' < 0 {
        di as err "pmax() must be >= 0"
        exit 198
    }
    qui count if `touse'
    local T = r(N)
    qui summ `tvar' if `touse', meanonly
    if (r(max) - r(min) + 1) != `T' {
        di as err "the sample must be contiguous (no gaps or missing values inside the sample)"
        exit 459
    }
    if `T' < `pmax' + 20 {
        di as err "too few observations (T = `T') for pmax(`pmax')"
        exit 2001
    }
    local ppr = ("`paper'" != "")
    sort `tvar'
    tempname S CV tv
    mata: _tsgls_run("`varlist'", "`touse'", `mod', `breaks', `pmax', `icn', `ppr', "`S'", "`CV'")
    local tb1 = r(tb1)
    local tb2 = r(tb2)
    local lags = r(lags)
    local s2 = r(s2)
    qui levelsof `tvar' if `touse', local(tlev)
    mata: st_matrix("`tv'", strtoreal(tokens(st_local("tlev")))')
    local d1 = `tv'[`tb1',1]
    if `breaks'==2 local d2 = `tv'[`tb2',1]

    local mlab = cond(`mod'==0,"level shift",cond(`mod'==1,"trend (slope) shift","level and trend shift"))
    local icl = cond(`icn'==1,"AIC",cond(`icn'==2,"BIC","t-sig (10%)"))
    local cbl = cond(`mod'==0, "-13.5", "Carrion-i-Silvestre-Kim-Perron response surface")
    di
    di as txt "GLS unit-root tests with " as res `breaks' as txt " structural break" cond(`breaks'==2,"s","") " (Perron-Rodriguez 2003; Carrion-i-Silvestre-Kim-Perron 2009)"
    di as txt "{hline 72}"
    di as txt "H0: unit root (with breaks)" _col(46) "Observations" _col(64) "= " as res %6.0f `T'
    di as txt "Model : " as res "`mlab'" _col(46) as txt "Max lags (" as res "`icl'" as txt ")" _col(64) "= " as res %6.0f `pmax'
    di as txt "c-bar : " as res "`cbl'" as txt "   (c-bar = " as res %7.3f r(cbar) as txt ")"
    if `breaks'==1 di as txt "Break date (min SSR of the GLS regression): " as res "`d1'" as txt "  (fraction " as res %5.3f `tb1'/`T' as txt ")"
    if `breaks'==2 di as txt "Break dates (min SSR of the GLS regression): " as res "`d1'" as txt " and " as res "`d2'" as txt "  (fractions " as res %5.3f `tb1'/`T' as txt ", " as res %5.3f `tb2'/`T' as txt ")"
    di as txt "{hline 72}"
    di as txt _col(5) "Statistic" _col(26) "Value" _col(42) "1%" _col(52) "5%" _col(62) "10%"
    di as txt "{hline 72}"
    local nm1 "ADF-GLS"
    local nm2 "PT"
    local nm3 "MZa"
    local nm4 "MZt"
    local nm5 "MSB"
    local nm6 "MPT"
    local any0 0
    forvalues j = 1/6 {
        local v = `S'[1,`j']
        local c1 = `CV'[`j',1]
        local c5 = `CV'[`j',2]
        local c10 = `CV'[`j',3]
        if `c1'==0 & `c5'==0 & `c10'==0 {
            local any0 1
            di as txt _col(5) "`nm`j''" _col(18) as res %12.4f `v' _col(38) as txt "   n.a.      n.a.      n.a."
            continue
        }
        local st = cond(`v'<`c1',"***",cond(`v'<`c5',"**",cond(`v'<`c10',"*","")))
        di as txt _col(5) "`nm`j''" _col(18) as res %12.4f `v' _col(36) %8.3f `c1' %10.3f `c5' %10.3f `c10' as txt " `st'"
    }
    di as txt "{hline 72}"
    di as txt "All six tests reject for small values.  *** 1%, ** 5%, * 10%.  Lags = " as res `lags' as txt ", s2_AR = " as res %9.6f `s2'
    if `any0' di as txt "n.a.: the GAUSS two-break table has no entry for these break fractions (both fall in the same decile)."
    if `ppr'  di as txt "Formulas: paper (option {bf:paper}): Ng-Perron s2_AR, lag and s2_AR taken at the selected break date(s)."
    if !`ppr' di as txt "Formulas: GAUSS tspdlib (default). Option {bf:paper} uses the Ng-Perron (2001) s2_AR; see help."

    matrix colnames `S' = ADF_GLS PT MZa MZt MSB MPT
    matrix rownames `CV' = ADF_GLS PT MZa MZt MSB MPT
    matrix colnames `CV' = cv1 cv5 cv10
    return scalar ADF_GLS = `S'[1,1]
    return scalar PT  = `S'[1,2]
    return scalar MZa = `S'[1,3]
    return scalar MZt = `S'[1,4]
    return scalar MSB = `S'[1,5]
    return scalar MPT = `S'[1,6]
    return scalar lags = `lags'
    return scalar s2ar = `s2'
    return scalar cbar = r(cbar)
    return scalar break1 = `d1'
    return scalar lambda1 = `tb1'/`T'
    if `breaks'==2 {
        return scalar break2 = `d2'
        return scalar lambda2 = `tb2'/`T'
    }
    return scalar T = `T'
    return local model "`model'"
    return local formulas = cond(`ppr', "paper", "gauss")
    return local varname "`varlist'"
    return matrix stats = `S'
    return matrix cv = `CV'
end

mata:

// GAUSS _get_cbar: CKP (2009) response surface for c-bar
real scalar _tsgls_cbar(real rowvector lam)
{
    real scalar l1, l2, l3, l4, l5
    real rowvector xr, par
    l1 = lam[1]
    l2 = lam[2]
    l3 = lam[3]
    l4 = lam[4]
    l5 = lam[5]
    xr = (1, l1, l2, l3, l4, l5, l1^2, l2^2, l3^2, l4^2, l5^2, l1^3, l2^3, l3^3, l4^3, l5^3,
          l1^4, l2^4, l3^4, l4^4, l5^4,
          abs(l1-l2), abs(l1-l3), abs(l1-l4), abs(l1-l5), abs(l2-l3), abs(l2-l4), abs(l2-l5), abs(l3-l4), abs(l3-l5), abs(l4-l5),
          abs(l1-l2)^2, abs(l1-l3)^2, abs(l1-l4)^2, abs(l1-l5)^2, abs(l2-l3)^2, abs(l2-l4)^2, abs(l2-l5)^2, abs(l3-l4)^2, abs(l3-l5)^2, abs(l4-l5)^2,
          abs(l1-l2)^3, abs(l1-l3)^3, abs(l1-l4)^3, abs(l1-l5)^3, abs(l2-l3)^3, abs(l2-l4)^3, abs(l2-l5)^3, abs(l3-l4)^3, abs(l3-l5)^3, abs(l4-l5)^3,
          abs(l1-l2)^4, abs(l1-l3)^4, abs(l1-l4)^4, abs(l1-l5)^4, abs(l2-l3)^4, abs(l2-l4)^4, abs(l2-l5)^4, abs(l3-l4)^4, abs(l3-l5)^4, abs(l4-l5)^4)
    par = (-13.12832, -36.53045, 0, 20.2423, -4.596202, -10.31678, 115.2092, -29.18712, -68.36453, 5.873121, 0,
           -130.337, 74.64396, 85.48737, 0, 0, 51.98117, -53.03452, -36.27221, 0, 11.27727, -23.39517, -5.360149, 23.99683,
           4.788676, -27.10002, -35.78388, 51.12371, -29.8518, -3.069174, -37.45898, 64.95842, 5.825729, -88.78176,
           -11.54197, 83.48645, 125.2349, -173.1259, 80.95821, 2.863782, 118.2829, -80.1287, 0, 128.872, 6.387147,
           -118.1043, -199.0615, 247.6469, -98.05947, 0, -160.5713, 38.52177, 0, -65.21576, 0, 62.86494,
           117.9976, -127.5544, 46.2304, 0, 79.1693)
    return(xr*par')
}

// GAUSS glsDetrend + _get_ygls: returns (ygls) and SSRa, SSR1 via pointers
real colvector _tsgls_detrend(real colvector y, real matrix z, real scalar cbar,
                              real scalar ssra, real scalar ssr1)
{
    real scalar t, a
    real colvector ya, ua, u1, bh
    real matrix za
    t  = rows(y)
    a  = 1 + cbar/t
    ya = y[1] \ (y[|2 \ t|] - a*y[|1 \ t-1|])
    za = z[1,.] \ (z[|2,1 \ t,cols(z)|] - a*z[|1,1 \ t-1,cols(z)|])
    bh = luinv(za'*za)*(za'*ya)
    ua = ya - za*bh
    ssra = ua'*ua
    ya = y[1] \ (y[|2 \ t|] - y[|1 \ t-1|])
    za = z[1,.] \ (z[|2,1 \ t,cols(z)|] - z[|1,1 \ t-1,cols(z)|])
    u1 = ya - za*(luinv(za'*za)*(za'*ya))
    ssr1 = u1'*u1
    return(y - z*bh)
}

// GAUSS ADF(e, 0, pmax, ic): returns (tau, lags)
real rowvector _tsgls_adf(real colvector y, real scalar pmax, real scalar ic)
{
    real scalar t, p, j, n, k, LL, ssr, po, i
    real colvector dy, ly, dep, b, se, e, taup, aicp, sicp, tstatp
    real matrix L, x, m
    t  = rows(y)
    dy = 0 \ (y[|2 \ t|] - y[|1 \ t-1|])
    ly = . \ y[|1 \ t-1|]
    L  = J(t, max((pmax,1)), .)
    for (j=1; j<=pmax; j=j+1) {
        L[., j] = J(j,1,.) \ dy[|1 \ t-j|]
    }
    taup = J(pmax+1,1,0)
    aicp = J(pmax+1,1,0)
    sicp = J(pmax+1,1,0)
    tstatp = J(pmax+1,1,0)
    for (p=0; p<=pmax; p=p+1) {
        dep = dy[|p+2 \ t|]
        x = ly[|p+2 \ t|]
        if (p > 0) x = x, L[|p+2,1 \ t,p|]
        m  = luinv(x'*x)
        b  = m*(x'*dep)
        e  = dep - x*b
        ssr = e'*e
        n = rows(x)
        k = cols(x)
        se = sqrt(diagonal(m)*(ssr/(n-k)))
        taup[p+1] = b[1]/se[1]
        LL = -n/2*(1 + ln(2*pi()) + ln(ssr/n))
        aicp[p+1] = (2*k - 2*LL)/n
        sicp[p+1] = (k*ln(n) - 2*LL)/n
        tstatp[p+1] = abs(b[k]/se[k])
    }
    po = 1
    if (ic == 1 | ic == 2) {
        for (i=2; i<=pmax+1; i=i+1) {
            if (ic == 1) {
                if (aicp[i] < aicp[po]) po = i
            }
            if (ic == 2) {
                if (sicp[i] < sicp[po]) po = i
            }
        }
    }
    if (ic == 3) {
        j = pmax + 1
        while (j >= 1) {
            if (abs(tstatp[j]) > 1.645) break
            j = j - 1
        }
        po = j
        if (po == 0) po = 1
    }
    return((taup[po], po-1))
}

// GAUSS _get_s2ar (paper = 0) or Ng-Perron (2001) s2_AR (paper = 1)
real scalar _tsgls_s2ar(real colvector e, real scalar p, real scalar paper)
{
    real colvector de, e1, d, b, et
    real matrix L, x
    real scalar k, j, n, s2ek
    de = e[|2 \ rows(e)|] - e[|1 \ rows(e)-1|]
    e1 = e[|1 \ rows(e)-1|]
    n  = rows(de)
    k  = max((p,1))
    if (paper & p == 0) k = 0
    L  = J(n, max((k,1)), .)
    for (j=1; j<=k; j=j+1) {
        L[., j] = J(j,1,.) \ de[|1 \ n-j|]
    }
    x = e1[|p+2 \ n|]
    if (k > 0) x = x, L[|p+2,1 \ n,k|]
    d = de[|p+2 \ n|]
    b = luinv(x'*x)*(x'*d)
    et = d - x*b
    s2ek = (et'*et)/(rows(et) - k)
    if (paper) {
        if (k == 0) return(s2ek)
        return(s2ek/(1 - sum(b[|2 \ rows(b)|]))^2)
    }
    // GAUSS: sumc(b[2:cols(b)]) with b a column vector = b[2] + b[1]
    return(s2ek/(1 - (b[1] + b[2])))
}

void _tsgls_run(string scalar vn, string scalar touse, real scalar model, real scalar nb,
                real scalar pmax, real scalar ic, real scalar paper, string scalar Sn, string scalar CVn)
{
    real colvector y, dc, dt, du1, du2, dt1, dt2, yg, y1
    real matrix z, CV
    real rowvector a, best
    real scalar t, tb1, tb2, tb2s, tb1m, tb2m, cbar, ssra, ssr1, ssrmin, s2, PT, MZa, MSB, MZt, MPT,
                p, plast, s2last, cbm, l1, l2, row, col
    real matrix PT1, PT5, PT10, MZt1, MZt5, MZt10, MSB1, MSB5, MSB10, MZa1, MZa5, MZa10, cm
    y  = st_data(., vn, touse)
    t  = rows(y)
    dc = J(t,1,1)
    dt = (1::t)
    ssrmin = 1000
    tb1m = 0
    tb2m = 0
    best = J(1,6,.)
    cbm = .
    ssra = .
    ssr1 = .
    for (tb1=3; tb1<=t-3-2*(nb==2); tb1=tb1+1) {
        tb2s = tb1
        if (nb == 2) tb2s = tb1 + 2
        for (tb2=tb2s; tb2<=t-3; tb2=tb2+1) {
            du1 = J(tb1,1,0) \ J(t-tb1,1,1)
            dt1 = J(tb1,1,0) \ (1::(t-tb1))
            du2 = J(tb2,1,0) \ J(t-tb2,1,1)
            dt2 = J(tb2,1,0) \ (1::(t-tb2))
            if (nb == 1) {
                if (model == 0) z = dc, dt, du1
                if (model == 1) z = dc, dt, dt1
                if (model == 2) z = dc, dt, du1, dt1
                cbar = -13.5
                if (model > 0) cbar = _tsgls_cbar((tb1/t, 0, 0, 0, 0))
            }
            if (nb == 2) {
                if (model == 0) z = dc, dt, du1, du2
                if (model == 1) z = dc, dt, dt1, dt2
                if (model == 2) z = dc, dt, du1, du2, dt1, dt2
                cbar = -13.5
                if (model > 0) cbar = _tsgls_cbar((tb1/t, tb2/t, 0, 0, 0))
            }
            yg = _tsgls_detrend(y, z, cbar, ssra, ssr1)
            a  = _tsgls_adf(yg, pmax, ic)
            p  = a[2]
            s2 = _tsgls_s2ar(yg, p, paper)
            PT = (ssra - (1 + cbar/t)*ssr1)/s2
            y1 = yg[|1 \ t-1|]
            MZa = (yg[t]^2/t - s2)/(2*sum(y1:^2)/t^2)
            MSB = sqrt(sum(y1:^2)/t^2/s2)
            MZt = MZa*MSB
            MPT = (cbar^2*sum(y1:^2)/t^2 + (1-cbar)*yg[t]^2/t)/s2
            if (ssra < ssrmin) {
                best = (a[1], PT, MZa, MZt, MSB, MPT)
                tb1m = tb1
                tb2m = tb2
                ssrmin = ssra
                cbm = cbar
                if (paper) {
                    plast = p
                    s2last = s2
                }
            }
            // GAUSS returns the lag and s2 of the LAST candidate break date(s)
            if (!paper) {
                plast = p
                s2last = s2
            }
            if (nb == 1) break
        }
    }
    // critical values: rows ADF-GLS, PT, MZa, MZt, MSB, MPT; cols 1%, 5%, 10%
    CV = J(6,3,.)
    if (model == 0) {
        CV = (-3.420, -2.910, -2.620 \ 3.960, 5.620, 6.890 \ -23.800, -17.300, -14.200 \
              -3.420, -2.910, -2.620 \ 0.143, 0.168, 0.185 \ 4.030, 5.480, 6.670)
    }
    if (model > 0 & nb == 1) {
        l1 = tb1m/t
        col = 9
        if (l1 <= 0.15) col = 1
        if (l1 > 0.15 & l1 <= 0.85) col = round(10*l1)
        cm = (4.354, 4.807, 5.042, 5.079, 4.949, 4.704, 4.423, 4.191, 4.075 \
              6.238, 6.759, 6.992, 6.986, 6.789, 6.746, 6.146, 5.910, 5.865 \
              7.492, 8.076, 8.344, 8.335, 8.105, 7.744, 7.373, 7.118, 7.086)
        CV[2,.] = cm[.,col]'
        CV[6,.] = cm[.,col]'
        cm = (-3.800, -3.942, -3.981, -3.969, -3.938, -3.897, -3.843, -3.763, -3.639 \
              -3.232, -3.396, -3.448, -3.445, -3.419, -3.382, -3.328, -3.240, -3.094 \
              -2.950, -3.118, -3.171, -3.166, -3.137, -3.096, -3.039, -2.949, -2.801)
        CV[1,.] = cm[.,col]'
        CV[4,.] = cm[.,col]'
        cm = (0.130, 0.125, 0.123, 0.124, 0.125, 0.127, 0.129, 0.132, 0.137 \
              0.152, 0.144, 0.142, 0.143, 0.144, 0.147, 0.149, 0.154, 0.161 \
              0.166, 0.157, 0.154, 0.155, 0.157, 0.159, 0.163, 0.169, 0.178)
        CV[5,.] = cm[.,col]'
        cm = (-29.315, -31.442, -32.024, -31.828, -31.333, -30.713, -29.873, -28.539, -26.400 \
              -21.244, -23.322, -24.018, -23.969, -23.612, -23.113, -22.393, -21.188, -19.126 \
              -17.815, -19.793, -20.433, -20.350, -19.965, -19.450, -18.743, -17.599, -15.657)
        CV[3,.] = cm[.,col]'
    }
    if (model > 0 & nb == 2) {
        l1 = tb1m/t
        l2 = tb2m/t
        row = 8
        if (l1 <= 0.15) row = 1
        if (l1 > 0.15 & l1 <= 0.75) row = round(10*l1)
        col = 8
        if (l2 <= 0.25) col = 1
        if (l2 > 0.25 & l2 <= 0.85) col = round(10*l2) - 1
        _tsgls_cv2(PT1, PT5, PT10, MZt1, MZt5, MZt10, MSB1, MSB5, MSB10, MZa1, MZa5, MZa10)
        CV[2,.] = (PT1[row,col], PT5[row,col], PT10[row,col])
        CV[6,.] = CV[2,.]
        CV[4,.] = (MZt1[row,col], MZt5[row,col], MZt10[row,col])
        CV[1,.] = CV[4,.]
        CV[5,.] = (MSB1[row,col], MSB5[row,col], MSB10[row,col])
        CV[3,.] = (MZa1[row,col], MZa5[row,col], MZa10[row,col])
    }
    st_matrix(Sn, best)
    st_matrix(CVn, CV)
    st_rclear()
    st_numscalar("r(tb1)", tb1m)
    st_numscalar("r(tb2)", tb2m)
    st_numscalar("r(lags)", plast)
    st_numscalar("r(s2)", s2last)
    st_numscalar("r(cbar)", cbm)
}

void _tsgls_cv2(real matrix PT1, real matrix PT5, real matrix PT10, real matrix MZt1,
                real matrix MZt5, real matrix MZt10, real matrix MSB1, real matrix MSB5,
                real matrix MSB10, real matrix MZa1, real matrix MZa5, real matrix MZa10)
{
    PT1 = J(8,8,0)
    PT1[1,.] = (4.723, 5.213, 5.536, 5.710, 5.724, 5.573, 5.266, 4.810)
    PT1[2,.] = (0, 5.134, 5.585, 5.819, 5.866, 5.743, 5.475, 5.087)
    PT1[3,.] = (0, 0, 5.471, 5.829, 5.932, 5.841, 5.596, 5.241)
    PT1[4,.] = (0, 0, 0, 5.617, 5.848, 5.812, 5.595, 5.252)
    PT1[5,.] = (0, 0, 0, 0, 5.524, 5.622, 5.461, 5.135)
    PT1[6,.] = (0, 0, 0, 0, 0, 5.214, 5.197, 4.923)
    PT1[7,.] = (0, 0, 0, 0, 0, 0, 4.722, 4.654)
    PT1[8,.] = (0, 0, 0, 0, 0, 0, 0, 4.328)
    PT5 = J(8,8,0)
    PT5[1,.] = (6.478, 7.034, 7.398, 7.592, 7.607, 7.434, 7.072, 6.511)
    PT5[2,.] = (0, 6.897, 7.431, 7.708, 7.765, 7.624, 7.310, 5.844)
    PT5[3,.] = (0, 0, 7.264, 7.712, 7.850, 7.749, 7.461, 7.037)
    PT5[4,.] = (0, 0, 0, 7.435, 7.747, 7.727, 7.475, 7.070)
    PT5[5,.] = (0, 0, 0, 0, 7.338, 7.498, 7.328, 6.951)
    PT5[6,.] = (0, 0, 0, 0, 0, 6.997, 7.015, 6.719)
    PT5[7,.] = (0, 0, 0, 0, 0, 0, 6.524, 6.424)
    PT5[8,.] = (0, 0, 0, 0, 0, 0, 0, 6.094)
    PT10 = J(8,8,0)
    PT10[1,.] = (7.791, 8.376, 8.733, 8.903, 8.887, 8.697, 8.361, 7.902)
    PT10[2,.] = (0, 8.210, 8.757, 9.013, 9.039, 8.873, 8.563, 8.159)
    PT10[3,.] = (0, 0, 8.568, 9.012, 9.123, 8.997, 8.706, 8.322)
    PT10[4,.] = (0, 0, 0, 8.719, 9.019, 8.978, 8.722, 8.345)
    PT10[5,.] = (0, 0, 0, 0, 8.600, 8.754, 8.582, 8.226)
    PT10[6,.] = (0, 0, 0, 0, 0, 8.245, 8.276, 7.998)
    PT10[7,.] = (0, 0, 0, 0, 0, 0, 7.772, 7.705)
    PT10[8,.] = (0, 0, 0, 0, 0, 0, 0, 7.358)
    MZt1 = J(8,8,0)
    MZt1[1,.] = (-4.131, -4.726, -4.338, -4.347, -4.326, -4.285, -4.222, -4.124)
    MZt1[2,.] = (0, -4.288, -4.384, -4.415, -4.403, -4.363, -4.298, -4.203)
    MZt1[3,.] = (0, 0, -4.337, -4.403, -4.415, -4.385, -4.321, -4.226)
    MZt1[4,.] = (0, 0, 0, -4.325, -4.371, -4.365, -4.313, -4.223)
    MZt1[5,.] = (0, 0, 0, 0, -4.278, -4.304, -4.277, -4.202)
    MZt1[6,.] = (0, 0, 0, 0, 0, -4.203, -4.206, -4.158)
    MZt1[7,.] = (0, 0, 0, 0, 0, 0, -4.100, -4.079)
    MZt1[8,.] = (0, 0, 0, 0, 0, 0, 0, -3.960)
    MZt5 = J(8,8,0)
    MZt5[1,.] = (-3.566, -3.729, -3.797, -3.812, -3.801, -3.768, -3.699, -3.558)
    MZt5[2,.] = (0, -3.723, -3.836, -3.872, -3.865, -3.834, -3.775, -3.665)
    MZt5[3,.] = (0, 0, -3.780, -3.861, -3.875, -3.849, -3.792, -3.693)
    MZt5[4,.] = (0, 0, 0, -3.777, -3.836, -3.832, -3.781, -3.684)
    MZt5[5,.] = (0, 0, 0, 0, -3.737, -3.777, -3.747, -3.657)
    MZt5[6,.] = (0, 0, 0, 0, 0, -3.665, -3.678, -3.609)
    MZt5[7,.] = (0, 0, 0, 0, 0, 0, -3.551, -3.524)
    MZt5[8,.] = (0, 0, 0, 0, 0, 0, 0, -3.377)
    MZt10 = J(8,8,0)
    MZt10[1,.] = (-3.266, -3.425, -3.499, -3.524, -3.519, -3.489, -3.417, -3.272)
    MZt10[2,.] = (0, -3.437, -3.553, -3.598, -3.600, -3.571, -3.507, -3.387)
    MZt10[3,.] = (0, 0, -3.502, -3.588, -3.611, -3.589, -3.528, -3.417)
    MZt10[4,.] = (0, 0, 0, -3.502, -3.566, -3.565, -3.512, -3.405)
    MZt10[5,.] = (0, 0, 0, 0, -3.463, -3.503, -3.470, -3.372)
    MZt10[6,.] = (0, 0, 0, 0, 0, -3.388, -3.395, -3.319)
    MZt10[7,.] = (0, 0, 0, 0, 0, 0, -3.269, -3.232)
    MZt10[8,.] = (0, 0, 0, 0, 0, 0, 0, -3.089)
    MSB1 = J(8,8,0)
    MSB1[1,.] = (0.120, 0.115, 0.114, 0.114, 0.115, 0.116, 0.118, 0.121)
    MSB1[2,.] = (0, 0.115, 0.113, 0.112, 0.113, 0.114, 0.116, 0.119)
    MSB1[3,.] = (0, 0, 0.114, 0.112, 0.112, 0.113, 0.115, 0.118)
    MSB1[4,.] = (0, 0, 0, 0.115, 0.114, 0.114, 0.115, 0.118)
    MSB1[5,.] = (0, 0, 0, 0, 0.116, 0.115, 0.116, 0.119)
    MSB1[6,.] = (0, 0, 0, 0, 0, 0.118, 0.118, 0.120)
    MSB1[7,.] = (0, 0, 0, 0, 0, 0, 0.121, 0.122)
    MSB1[8,.] = (0, 0, 0, 0, 0, 0, 0, 0.126)
    MSB5 = J(8,8,0)
    MSB5[1,.] = (0.138, 0.132, 0.130, 0.129, 0.130, 0.131, 0.134, 0.140)
    MSB5[2,.] = (0, 0.132, 0.128, 0.127, 0.128, 0.129, 0.132, 0.136)
    MSB5[3,.] = (0, 0, 0.131, 0.128, 0.128, 0.129, 0.131, 0.135)
    MSB5[4,.] = (0, 0, 0, 0.131, 0.129, 0.130, 0.132, 0.135)
    MSB5[5,.] = (0, 0, 0, 0, 0.133, 0.131, 0.133, 0.137)
    MSB5[6,.] = (0, 0, 0, 0, 0, 0.135, 0.135, 0.138)
    MSB5[7,.] = (0, 0, 0, 0, 0, 0, 0.140, 0.142)
    MSB5[8,.] = (0, 0, 0, 0, 0, 0, 0, 0.148)
    MSB10 = J(8,8,0)
    MSB10[1,.] = (0.150, 0.143, 0.140, 0.140, 0.140, 0.142, 0.145, 0.153)
    MSB10[2,.] = (0, 0.143, 0.138, 0.137, 0.137, 0.139, 0.141, 0.147)
    MSB10[3,.] = (0, 0, 0.140, 0.137, 0.137, 0.138, 0.141, 0.146)
    MSB10[4,.] = (0, 0, 0, 0.131, 0.138, 0.139, 0.141, 0.146)
    MSB10[5,.] = (0, 0, 0, 0, 0.143, 0.141, 0.143, 0.148)
    MSB10[6,.] = (0, 0, 0, 0, 0, 0.146, 0.146, 0.150)
    MSB10[7,.] = (0, 0, 0, 0, 0, 0, 0.152, 0.154)
    MSB10[8,.] = (0, 0, 0, 0, 0, 0, 0, 0.162)
    MZa1 = J(8,8,0)
    MZa1[1,.] = (-34.600, -36.957, -38.023, -38.147, -37.698, -36.884, -35.727, -34.161)
    MZa1[2,.] = (0, -37.208, -38.881, -39.455, -39.195, -38.368, -37.097, -35.403)
    MZa1[3,.] = (0, 0, -38.001, -39.208, -39.418, -38.798, -37.548, -35.792)
    MZa1[4,.] = (0, 0, 0, -37.720, -38.551, -38.408, -37.405, -35.764)
    MZa1[5,.] = (0, 0, 0, 0, -36.806, -37.238, -36.726, -35.428)
    MZa1[6,.] = (0, 0, 0, 0, 0, -35.447, -35.441, -34.674)
    MZa1[7,.] = (0, 0, 0, 0, 0, 0, -33.666, -33.314)
    MZa1[8,.] = (0, 0, 0, 0, 0, 0, 0, -31.352)
    MZa5 = J(8,8,0)
    MZa5[1,.] = (-25.856, -28.150, -29.163, -29.379, -29.144, -28.555, -27.445, -25.411)
    MZa5[2,.] = (0, -28.133, -29.825, -30.383, -30.243, -29.663, -28.640, -26.924)
    MZa5[3,.] = (0, 0, -28.948, -30.194, -30.399, -29.929, -28.935, -27.329)
    MZa5[4,.] = (0, 0, 0, -28.848, -29.736, -29.612, -28.740, -27.186)
    MZa5[5,.] = (0, 0, 0, 0, -28.176, -28.715, -28.187, -26.768)
    MZa5[6,.] = (0, 0, 0, 0, 0, -27.045, -27.150, -26.073)
    MZa5[7,.] = (0, 0, 0, 0, 0, 0, -25.350, -24.879)
    MZa5[8,.] = (0, 0, 0, 0, 0, 0, 0, -22.848)
    MZa10 = J(8,8,0)
    MZa10[1,.] = (-21.932, -23.932, -24.888, -25.178, -25.044, -24.528, -23.466, -21.514)
    MZa10[2,.] = (0, -24.159, -25.683, -26.270, -26.245, -25.760, -24.763, -23.021)
    MZa10[3,.] = (0, 0, -24.966, -26.113, -26.385, -26.014, -25.061, -23.405)
    MZa10[4,.] = (0, 0, 0, -24.890, -25.715, -25.642, -24.811, -23.218)
    MZa10[5,.] = (0, 0, 0, 0, -24.275, -24.744, -24.210, -22.756)
    MZa10[6,.] = (0, 0, 0, 0, 0, -23.210, -23.204, -22.054)
    MZa10[7,.] = (0, 0, 0, 0, 0, 0, -21.564, -20.930)
    MZa10[8,.] = (0, 0, 0, 0, 0, 0, 0, -19.082)
}
end
