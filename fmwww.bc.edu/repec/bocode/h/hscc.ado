*! hscc 1.0.2 28sep2026
*! Heterogeneous-Slope SCC estimator
*! Joint partial-pooling heterogeneous slopes + HC3 Driscoll-Kraay inference
*!
*! Syntax:
*!     hscc depvar indepvars [if] [in] [, lag(#) timefe]
*!
*! Requirements:
*!     - panel data must already be xtset
*!     - balanced panel
*!     - no missing values in estimation sample
*!
*! Example:
*!     xtset i time
*!     hscc GGI lnREC lnT GPATDE FD
*!     hscc GGI lnREC lnT GPATDE FD, lag(2)
*!     hscc GGI lnREC lnT GPATDE FD, timefe

capture program drop hscc
program define hscc, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 numeric) [if] [in] [, LAG(integer -1) TIMEFE]

    marksample touse
    markout `touse' `varlist'

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    quietly xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"

    if "`panelvar'" == "" | "`timevar'" == "" {
        di as err "data must be xtset before using hscc"
        exit 459
    }

    markout `touse' `panelvar' `timevar'

    quietly count if `touse'
    local Nobs = r(N)

    if `Nobs' == 0 {
        error 2000
    }

    tempvar __hscc_t
    quietly egen long `__hscc_t' = group(`timevar') if `touse'

    quietly summarize `__hscc_t' if `touse', meanonly
    local Tdim = r(max)

    quietly levelsof `panelvar' if `touse', local(__hscc_ids)
    local Ng : word count `__hscc_ids'

    quietly levelsof `timevar' if `touse', local(__hscc_timevals)

    if `Ng' < 2 {
        di as err "hscc requires at least two panel units"
        exit 459
    }

    * Require a balanced estimation sample.
    tempvar __hscc_n
    quietly bysort `panelvar': egen long `__hscc_n' = total(`touse')
    quietly summarize `__hscc_n' if `touse', meanonly

    if r(min) != r(max) | r(min) != `Tdim' {
        di as err "hscc v1.0 requires a strongly balanced estimation sample"
        exit 459
    }

    local L = `lag'

    if `L' < 0 {
        local L = floor(4*(`Tdim'/100)^(2/9))
        if `L' < 1 local L = 1
    }

    if `L' >= `Tdim' {
        di as err "lag() must be smaller than the time dimension T=`Tdim'"
        exit 198
    }

    local xlist "`indepvars'"
    local use_timefe = ("`timefe'" != "")

    mata: hscc__estimate("`depvar'", "`xlist'", "`panelvar'", "`__hscc_t'", "`touse'", `L', `use_timefe')

    matrix colnames HSCC_B = `indepvars'
    matrix rownames HSCC_V = `indepvars'
    matrix colnames HSCC_V = `indepvars'
    matrix colnames HSCC_MG = `indepvars'

    if "`timefe'" != "" {
        local __hscc_tfcols
        forvalues j = 1/`Tdim' {
            local __hscc_tfcols "`__hscc_tfcols' t`j'"
        }
        matrix colnames HSCC_TIMEFE = `__hscc_tfcols'
    }

    ereturn post HSCC_B HSCC_V, obs(`Nobs') depname(`depvar')

    ereturn scalar N_g = `Ng'
    ereturn scalar T   = `Tdim'
    ereturn scalar lag = `L'
    ereturn scalar df_r = `=`Tdim'-1'
    ereturn scalar heterogeneity_trace = scalar(HSCC_HETTRACE)
    ereturn scalar r2_w = scalar(HSCC_R2W)

    ereturn matrix mg_b = HSCC_MG

    if "`timefe'" != "" {
        ereturn matrix timefe_b = HSCC_TIMEFE
        ereturn local timefe_normalization "centered_mean_zero"
    }

    ereturn local cmd "hscc"
    ereturn local cmdline `"hscc `0'"'
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local panelvar "`panelvar'"
    ereturn local timevar "`timevar'"
    ereturn local vcetype "HC3 Driscoll-Kraay"
    ereturn local timefe "`timefe'"
    ereturn local title "Heterogeneous-Slope SCC estimator"

    di
    di as txt "Heterogeneous-Slope SCC estimator" ///
        _col(49) "Number of obs   = " as res %9.0g e(N)
    di as txt "Joint partial-pooling slopes + HC3-DK" ///
        _col(49) "Number of groups= " as res %9.0g e(N_g)
    di as txt "Panel variable: " as res "`panelvar'" ///
        _col(49) as txt "Time periods    = " as res %9.0g e(T)
    di as txt "Time variable:  " as res "`timevar'" ///
        _col(49) as txt "DK lag          = " as res %9.0g e(lag)
    if "`timefe'" != "" {
        di as txt "Time fixed effects: " as res "Yes (partialled out)"
    }
    else {
        di as txt "Time fixed effects: " as res "No"
    }
    di as txt "Within R-squared = " as res %10.4f e(r2_w)
    di as txt "Slope heterogeneity trace = " as res %10.6f e(heterogeneity_trace)
    di

    ereturn display, level(95)

    if "`timefe'" != "" {
        tempname __hscc_tfdisp
        matrix `__hscc_tfdisp' = e(timefe_b)

        di
        di as txt "Common time fixed effects (centered; mean-zero normalization)"
        di as txt "{hline 36}"
        di as txt "Time" _col(21) "Effect"
        di as txt "{hline 36}"

        forvalues j = 1/`Tdim' {
            local __tv : word `j' of `__hscc_timevals'
            di as txt "`__tv'" _col(21) as res %12.6f el(`__hscc_tfdisp',1,`j')
        }

        di as txt "{hline 36}"
        di as txt "Stored in e(timefe_b)"
    }
end


mata:

void hscc__estimate(
    string scalar depvar,
    string scalar xvars,
    string scalar panelname,
    string scalar timename,
    string scalar tousename,
    real scalar L,
    real scalar timefe)
{
    real colvector use, sel, panel, tt, y, ids, times, idx, yg, yc, ug
    real matrix X, Xg, Xc, XX, Xy

    real matrix BB, Z, ZA, C0, M0, R0
    real matrix Sr, Vbar, Sraw, Seta, EV
    real rowvector EL, ELp, zbar

    real matrix Vi_store, Vi, Qinv, Hdiag, PSI, G0

    real matrix D, Dpre, Pmat, H, Hinv, PenEta, invEig
    real colvector YcAll, YcPre, theta, resid, lev, resid3, timeeff

    real scalar NN, TT, KK, g, Tg, q, k, j
    real scalar pGamma, pEta, pTot
    real scalar col0, e0, a, b
    real scalar s2sum, s2i, s2bar, epsEig
    real scalar hq, u3, r, tpos, ell, ww
    real scalar sse, sst, r2w

    real colvector bg, psi

    real matrix Ghs, Vhs, AA, CC, GG
    real colvector sehs
    real rowvector BHSCC, BMG

    string rowvector xnames

    use = st_data(., tousename)
    sel = selectindex(use :== 1)

    panel = st_data(sel, panelname)
    tt    = st_data(sel, timename)
    y     = st_data(sel, depvar)

    xnames = tokens(xvars)
    X = st_data(sel, xnames)

    ids   = uniqrows(panel)
    times = uniqrows(tt)

    NN = rows(ids)
    TT = rows(times)
    KK = cols(X)

    BB = J(NN,KK,.)
    Z  = J(NN,KK,.)
    Vi_store = J(NN*KK,KK,.)

    s2sum = 0

    /*
     * 1. Preliminary unit-specific within slopes
     */
    for (g=1; g<=NN; g++) {

        idx = selectindex(panel :== ids[g])

        yg = y[idx,.]
        Xg = X[idx,.]
        Tg = rows(yg)

        Z[g,.] = mean(Xg)

        yc = yg :- mean(yg)
        Xc = Xg :- mean(Xg)

        XX = quadcross(Xc,Xc)
        Xy = quadcross(Xc,yc)

        if (rank(XX) < KK) {
            errprintf("unit %g has a rank-deficient within-regressor matrix\n", ids[g])
            _error(459)
        }

        bg = invsym(XX)*Xy
        ug = yc - Xc*bg

        BB[g,.] = bg'

        s2i = quadcross(ug,ug)/(Tg-KK-1)
        s2sum = s2sum + s2i

        /*
         * HC3 covariance proxy V_i
         */
        Qinv = invsym(XX/Tg)
        Hdiag = rowsum((Xc*invsym(XX)) :* Xc)

        PSI = J(Tg,KK,0)

        for (q=1; q<=Tg; q++) {

            hq = Hdiag[q]

            if (hq < 0) hq = 0
            if (hq > .999999) hq = .999999

            u3 = ug[q]/(1-hq)

            psi = Qinv*(Xc[q,.]'*u3)

            PSI[q,.] = psi'
        }

        G0 = quadcross(PSI,PSI)/Tg

        Vi = G0/Tg
        Vi = (Vi+Vi')/2

        e0 = (g-1)*KK + 1
        Vi_store[e0..(e0+KK-1),.] = Vi
    }

    s2bar = s2sum/NN
    BMG = mean(BB)

    /*
     * 2. Systematic slope heterogeneity:
     *    beta_i = beta + Gamma*z_i + eta_i
     */
    zbar = mean(Z)
    Z = Z :- zbar

    ZA = J(NN,1,1), Z

    C0 = pinv(quadcross(ZA,ZA))*quadcross(ZA,BB)

    M0 = ZA*C0
    R0 = BB-M0

    Sr = variance(R0)

    Vbar = J(KK,KK,0)

    for (g=1; g<=NN; g++) {

        e0 = (g-1)*KK + 1
        Vi = Vi_store[e0..(e0+KK-1),.]

        Vbar = Vbar + Vi
    }

    Vbar = Vbar/NN

    Sraw = Sr - Vbar
    Sraw = (Sraw+Sraw')/2

    /*
     * PSD projection of residual slope covariance
     */
    symeigensystem(Sraw, EV=., EL=.)

    ELp = EL :* (EL :> 0)

    Seta = EV*diag(ELp)*EV'
    Seta = (Seta+Seta')/2

    /*
     * 3. Penalty:
     *    P_eta = sigma_u^2 * (Sigma_eta + eps I)^(-1)
     */
    symeigensystem(Seta, EV=., EL=.)

    epsEig = 1e-8

    if (max(EL)>0) {
        epsEig = max((1e-8,1e-8*max(EL)))
    }

    invEig = 1 :/ (EL :+ epsEig)

    PenEta = s2bar * EV*diag(invEig)*EV'
    PenEta = (PenEta+PenEta')/2

    /*
     * 4. Joint design
     *
     * eta_N = -sum_{i=1}^{N-1} eta_i
     */
    pGamma = KK*KK
    pEta   = (NN-1)*KK
    pTot   = KK + pGamma + pEta

    D = J(rows(y),pTot,0)
    YcAll = J(rows(y),1,.)

    for (g=1; g<=NN; g++) {

        idx = selectindex(panel :== ids[g])

        yg = y[idx,.]
        Xg = X[idx,.]

        yc = yg :- mean(yg)
        Xc = Xg :- mean(Xg)

        YcAll[idx,.] = yc

        /*
         * central slope beta
         */
        D[idx,1..KK] = Xc

        /*
         * systematic slope heterogeneity
         */
        for (k=1; k<=KK; k++) {

            for (j=1; j<=KK; j++) {

                col0 = KK + (k-1)*KK + j

                D[idx,col0] = Xc[,k] :* Z[g,j]
            }
        }

        /*
         * residual unit slope deviation
         */
        if (g < NN) {

            e0 = KK + pGamma + (g-1)*KK + 1

            D[idx,e0..(e0+KK-1)] = Xc
        }
        else {

            for (a=1; a<NN; a++) {

                e0 = KK + pGamma + (a-1)*KK + 1

                D[idx,e0..(e0+KK-1)] = -Xc
            }
        }
    }

    /*
     * Preserve the one-way within-transformed joint system so that
     * common time effects can be recovered after FWL estimation.
     */
    Dpre  = D
    YcPre = YcAll

    /*
     * 4b. Optional common time fixed effects
     *
     * Residualize the complete joint design and the within-transformed
     * outcome with respect to common time effects. This is FWL-equivalent
     * to including additive time dummies as unpenalized nuisance terms,
     * while keeping time dummies outside the heterogeneous-slope blocks.
     */
    if (timefe==1) {
        for (tpos=1; tpos<=TT; tpos++) {
            idx = selectindex(tt :== tpos)
            YcAll[idx,.] = YcAll[idx,.] :- mean(YcAll[idx,.])
            D[idx,.]     = D[idx,.]     :- mean(D[idx,.])
        }
    }

    /*
     * 5. Penalized joint estimation
     */
    Pmat = J(pTot,pTot,0)

    for (a=1; a<NN; a++) {

        for (b=1; b<NN; b++) {

            e0   = KK + pGamma + (a-1)*KK + 1
            col0 = KK + pGamma + (b-1)*KK + 1

            Pmat[e0..(e0+KK-1),
                 col0..(col0+KK-1)] =
                Pmat[e0..(e0+KK-1),
                     col0..(col0+KK-1)] + PenEta

            if (a==b) {

                Pmat[e0..(e0+KK-1),
                     col0..(col0+KK-1)] =
                    Pmat[e0..(e0+KK-1),
                         col0..(col0+KK-1)] + PenEta
            }
        }
    }

    H = quadcross(D,D) + Pmat

    Hinv = pinv(H)

    theta = Hinv*quadcross(D,YcAll)

    BHSCC = theta[1..KK]'

    /*
     * Recover common time fixed effects after FWL estimation.
     *
     * With unit effects already removed, lambda_t is recovered as the
     * cross-sectional mean of the pre-time-demeaned residual at time t.
     * In a balanced panel, the recovered effects are mean-zero over time.
     */
    timeeff = J(TT,1,0)

    if (timefe==1) {
        for (tpos=1; tpos<=TT; tpos++) {
            idx = selectindex(tt :== tpos)
            timeeff[tpos] = mean(YcPre[idx,.] - Dpre[idx,.]*theta)
        }
    }

    /*
     * Descriptive within R-squared:
     * 1 - SSE_HSCC / SST_within
     *
     * Since YcAll is within-demeaned, its mean is zero by unit.
     */
    resid = YcAll - D*theta
    sse = quadcross(resid,resid)
    sst = quadcross(YcAll,YcAll)
    r2w = 1 - sse/sst

    /*
     * 6. HC3-adjusted DK/SCC covariance
     */
    lev = rowsum((D*Hinv) :* D)

    resid3 = resid

    for (r=1; r<=rows(resid); r++) {

        hq = lev[r]

        if (hq < 0) hq = 0
        if (hq > .999999) hq = .999999

        resid3[r] = resid[r]/(1-hq)
    }

    Ghs = J(TT,KK,0)

    for (r=1; r<=rows(y); r++) {

        tpos = tt[r]

        psi =
            Hinv[1..KK,.] *
            (D[r,.]'*resid3[r])

        Ghs[tpos,.] =
            Ghs[tpos,.] + psi'
    }

    Vhs = quadcross(Ghs,Ghs)

    for (ell=1; ell<=L; ell++) {

        ww = 1 - ell/(L+1)

        AA = Ghs[(ell+1)..TT,.]
        CC = Ghs[1..(TT-ell),.]

        GG = quadcross(AA,CC)

        Vhs =
            Vhs +
            ww*(GG+GG')
    }

    Vhs = (Vhs+Vhs')/2

    /*
     * Return results to Stata
     */
    st_matrix("HSCC_B",BHSCC)
    st_matrix("HSCC_V",Vhs)
    st_matrix("HSCC_MG",BMG)
    st_matrix("HSCC_TIMEFE",timeeff')

    st_numscalar("HSCC_HETTRACE",trace(Seta))
    st_numscalar("HSCC_R2W",r2w)
}

end
