*! xtboundpanico_example.do   1.0.0  27oct2026
* Self-testing demonstration of xtboundpanico.
* Author: Dr Merwan Roudane -- merwanroudane920@gmail.com
*         https://github.com/merwanroudane
*
* It exercises every code path on the Monte Carlo design of
*   Banerjee, A. and Carrion-i-Silvestre, J. L. (2026),
*   "Bounds and PANICO testing for cointegration in panels with common
*    factors", University of Canterbury WP 8/2026, Section 5, eqs (23)-(26),
* where the truth is known, and closes by reproducing the paper's Table C.3.
*
* Run it with:   do xtboundpanico_example.do
* Part 7 is the slow one (about 2-5 minutes); set `runmc' to 0 to skip it.

clear
set more off
local runmc 1

*==============================================================================
* The paper's DGP, eqs (23)-(26)
*
*   y_it  = sum_j x_jit + ly_i F_t + u_it        (beta = 1 on every regressor)
*   x_jit = lx_ji F_t + x0_jit,   D.x0_jit ~ N(0,1)
*   F_t   = rho F_{t-1} + w_t                    ONE factor, shared by all units
*   u_it  = phi u_{i,t-1} + e_it
*
*   phi = 1   -> the null of a panel spurious relationship
*   phi < 1   -> the alternative of panel cointegration
*   rho = 1   -> an I(1) common factor;  rho = 0 -> an I(0) common factor
*
* Note the two things that have to be right in any such simulation:
*   (a) F_t is COMMON, so it is drawn once and shared -- a per-observation draw
*       would make it idiosyncratic and the whole method pointless;
*   (b) the loadings are drawn once PER UNIT, not per observation.
*==============================================================================
mata:
mata set matastrict off
void xbp_dgp(real scalar N, real scalar T, real scalar k, real scalar rho,
             real scalar phi, real scalar b)
{
    real matrix X, U, Y, D, ex, x0, e
    real colvector F, w
    real rowvector ly, lx
    string rowvector nm
    real scalar t, j
    // (a) the common factor: one draw, shared
    w = rnormal(T,1,0,1)
    F = J(T,1,0)
    F[1] = w[1]
    for (t=2; t<=T; t++) {
        F[t] = rho*F[t-1] + w[t]
    }
    // (b) loadings: one draw per unit
    ly = runiform(1,N):*b
    X  = J(T, N*k, .)
    Y  = J(T, N, 0)
    for (j=1; j<=k; j++) {
        lx = runiform(1,N):*b
        ex = rnormal(T,N,0,1)
        x0 = J(T,N,0)
        x0[1,] = ex[1,]
        for (t=2; t<=T; t++) {
            x0[t,] = x0[t-1,] + ex[t,]
        }
        X[|1,(j-1)*N+1 \ T,j*N|] = F*lx + x0
        Y = Y + X[|1,(j-1)*N+1 \ T,j*N|]
    }
    // the idiosyncratic error, recursive within each unit
    e = rnormal(T,N,0,1)
    U = J(T,N,0)
    U[1,] = e[1,]
    for (t=2; t<=T; t++) {
        U[t,] = phi*U[t-1,] + e[t,]
    }
    Y = Y + F*ly + U
    // write out, sorted i then t
    D = J(N*T, 3+k, .)
    D[,1] = (1::N)#J(T,1,1)
    D[,2] = J(N,1,(1::T))
    D[,3] = vec(Y)
    for (j=1; j<=k; j++) {
        D[,3+j] = vec(X[|1,(j-1)*N+1 \ T,j*N|])
    }
    st_addobs(N*T)
    nm = ("id","t","y")
    for (j=1; j<=k; j++) {
        nm = nm, ("x" + strofreal(j))
    }
    for (j=1; j<=cols(D); j++) {
        st_store(., st_addvar("double", nm[j]), D[,j])
    }
}
end

capture program drop xbpdgp
program define xbpdgp
    syntax , NPAN(integer) TPER(integer) [KREG(integer 1) RHO(real 1) ///
        PHI(real 1) BLOAD(real 1) SEED(integer 20261027)]
    clear
    mata: rseed(`seed')
    mata: xbp_dgp(`npan', `tper', `kreg', `rho', `phi', `bload')
    qui xtset id t
    label var y  "y_it"
    label var x1 "x_1it"
    capture label var x2 "x_2it"
end


*==============================================================================
* PART 1.  Does the pooled CCE estimator recover the truth?  (eq. 13)
*          beta = 1 by construction, and Banerjee and Carrion-i-Silvestre
*          (2017) prove consistency at rate min(sqrt(T), sqrt(N)) UNDER THE
*          NULL, so the estimate must approach 1 as T grows even though the
*          regression is spurious.
*==============================================================================
* The rate is C_NT = min(sqrt(T), sqrt(N)), so N and T must grow TOGETHER:
* holding N fixed makes the RMSE plateau at order 1/sqrt(N) however large T is.
* And one draw per cell says nothing, so the RMSE is averaged over replications.
di _n(2) "{hline 78}"
di "PART 1.  Consistency of the pooled CCE estimator under the null (eq. 13)"
di "         Rate is min(sqrt(T), sqrt(N)), so N and T grow together."
di "{hline 78}"
di %-8s "N" %-8s "T" %10s "reps" %14s "mean beta" %14s "RMSE" %16s "C_NT * RMSE"
di "{hline 78}"
local reps 40
foreach c in "20 40" "30 60" "40 120" "60 240" {
    local N : word 1 of `c'
    local T : word 2 of `c'
    local sb = 0
    local sq = 0
    local ok = 0
    forvalues r = 1/`reps' {
        qui xbpdgp , npan(`N') tper(`T') kreg(1) rho(1) phi(1) ///
            seed(`=70000 + 53*`r'')
        capture qui xtboundpanico bounds y x1 , model(2) nocips
        if (_rc == 0) {
            matrix b = r(b_cce)
            local ok = `ok' + 1
            local sb = `sb' + b[1,1]
            local sq = `sq' + (b[1,1]-1)^2
        }
    }
    local rmse = sqrt(`sq'/`ok')
    local cnt  = min(sqrt(`T'), sqrt(`N'))
    di %-8.0f `N' %-8.0f `T' %10.0f `ok' %14.5f `=`sb'/`ok'' ///
       %14.5f `rmse' %16.5f `=`cnt'*`rmse''
}
di "{hline 78}"
di "EXPECT: mean beta near 1; RMSE falling as (N,T) grow; and C_NT * RMSE"
di "        roughly CONSTANT, which is the O_p(C_NT^-1) rate of Banerjee and"
di "        Carrion-i-Silvestre (2017) made visible."


*==============================================================================
* PART 2.  The bounds test under the null and under the alternative
*==============================================================================
di _n(2) "{hline 78}"
di "PART 2a.  NULL: phi = 1, I(1) factor.  Expect NO COINTEGRATION."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(1) phi(1) seed(20261027)
xtboundpanico bounds y x1 , model(2)

di _n(2) "{hline 78}"
di "PART 2b.  ALTERNATIVE: phi = 0.9.  Expect COINTEGRATION."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(1) phi(0.9) seed(20261027)
xtboundpanico bounds y x1 , model(2) graph name(xbp_fig1)

di _n(2) "{hline 78}"
di "PART 2c.  Same data, Table C.1 asymptotic critical values as a cross-check"
di "{hline 78}"
xtboundpanico bounds y x1 , model(2) cvmethod(asymptotic) nocips

di _n(2) "{hline 78}"
di "PART 2d.  The two literal readings of eq. (17) -- both over-reject.  See"
di "          help xtboundpanico methods."
di "{hline 78}"
xtboundpanico bounds y x1 , model(2) dffull  nocips
xtboundpanico bounds y x1 , model(2) dfpaper nocips


*==============================================================================
* PART 3.  How many common factors?  The truth is r = 1.
*==============================================================================
di _n(2) "{hline 78}"
di "PART 3.  Factor-number criteria.  TRUTH: r = 1."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(1) phi(1) seed(20261027)
xtboundpanico nfactors y x1 , model(2) rmax(5)
di _n "EXPECT: rhat = 1 from almost every criterion.  AIC3 selecting rmax is"
di "        the known failure Bai and Ng (2002) document, not a bug."
xtboundpanico nfactors y x1 , model(2) method(ca)


*==============================================================================
* PART 4.  PANICO.  Under the null nothing should reject; the single factor
*          should be classified I(1) when rho = 1 and I(0) when rho = 0.
*==============================================================================
di _n(2) "{hline 78}"
di "PART 4a.  PANICO, NULL (phi = 1), I(1) factor (rho = 1)."
di "          Expect: no rejection; Fhat classified I(1)."
di "{hline 78}"
xtboundpanico panico y x1 , model(2) rmax(5)

di _n(2) "{hline 78}"
di "PART 4b.  PANICO, ALTERNATIVE (phi = 0.9).  Expect rejection."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(1) phi(0.9) seed(20261027)
xtboundpanico panico y x1 , model(2) rmax(5) graph name(xbp_fig2)

di _n(2) "{hline 78}"
di "PART 4c.  PANICO with a STATIONARY factor (rho = 0), null in the"
di "          idiosyncratic component.  Expect: no rejection, Fhat I(0)."
di "          Note this is genuinely unstructured data for the I(0) branch,"
di "          not structured data with the option flipped."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(0) phi(1) seed(20261027)
xtboundpanico panico y x1 , model(2) rmax(5)

di _n(2) "{hline 78}"
di "PART 4d.  PANICCA (cross-section-average factors), and savecomp()."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(1) rho(1) phi(0.9) seed(20261027)
xtboundpanico panicca y x1 , model(2) savecomp(ca)
qui su ca_u
di _n "saved uhat*: N = " r(N) ", mean = " %9.5f r(mean)
qui su ca_f1
di "saved Fhat1: mean = " %9.5f r(mean)


*==============================================================================
* PART 5.  Every remaining code path
*==============================================================================
di _n(2) "{hline 78}"
di "PART 5.  Remaining code paths: k = 2, Models 0 and 1, fixed lags,"
di "         MQ tests with r > 1, each lag criterion, nwbw(0)."
di "{hline 78}"
xbpdgp , npan(20) tper(200) kreg(2) rho(1) phi(0.9) seed(4242)

di _n "-- k = 2, Model 1, rank condition with equality (r = 3)"
xtboundpanico bounds y x1 x2 , model(1) nocips

di _n "-- k = 2, Model 0 (no deterministics)"
xtboundpanico bounds y x1 x2 , model(0) nocips

di _n "-- fixed VAR order"
xtboundpanico bounds y x1 x2 , model(2) lags(2) nocips

foreach c in bic aic maic mbic {
    di _n "-- lagcrit(`c')"
    qui xtboundpanico bounds y x1 x2 , model(2) lagcrit(`c') nocips
    di "   tybar = " %8.4f r(tybar) "   decision = " r(decision)
}

di _n "-- PANICO with r = 3 forced, so MQc and MQf run instead of the ADF"
xtboundpanico panico y x1 x2 , model(2) factors(3)

di _n "-- PANICO with the autocovariance correction switched off"
qui xtboundpanico panico y x1 x2 , model(2) factors(1) nwbw(0)
di "   Pb = " %8.4f r(Pb) "  p = " %6.4f r(Pb_p)

di _n(2) "{hline 78}"
di "PART 5b.  The all subcommand"
di "{hline 78}"
xtboundpanico all y x1 x2 , model(2)


*==============================================================================
* PART 6.  Error handling -- every one of these SHOULD fail, with a clear
*          message.  They are run under capture and the return code reported.
*==============================================================================
di _n(2) "{hline 78}"
di "PART 6.  Error handling.  Every line below must report a non-zero rc."
di "{hline 78}"
xbpdgp , npan(20) tper(100) kreg(1) rho(1) phi(1) seed(1)

capture xtboundpanico bounds y x1 , model(5)
di "model(5) out of range{col 50}rc = " _rc
capture xtboundpanico bounds y x1 , factors(9)
di "factors() above 1+k{col 50}rc = " _rc
capture xtboundpanico bounds y x1 , lagcrit(hqic)
di "unknown lagcrit(){col 50}rc = " _rc
capture xtboundpanico panico y x1 , nfactors(onatski)
di "unknown nfactors(){col 50}rc = " _rc
capture xtboundpanico bounds y x1 , maxlags(40)
di "T too short for maxlags(40){col 50}rc = " _rc
capture xtboundpanico wibble y x1
di "invalid subcommand{col 50}rc = " _rc
preserve
    qui drop if id == 3 & t == 50
    capture xtboundpanico bounds y x1
    di "unbalanced panel{col 50}rc = " _rc
restore
preserve
    qui xtset id
    capture xtboundpanico bounds y x1
    di "no time variable in xtset{col 50}rc = " _rc
restore
qui xtset id t


*==============================================================================
* PART 7.  THE COMPATIBILITY PROOF.
*          Reproduce Table C.3 of the paper: empirical size and power of the
*          bounds test, r = 1, k = 1, rhat = 2, N = 20, lambda ~ U[0,1],
*          Model 2, 5% level.
*
*          Published Table C.3, N = 20, size (phi = 1):
*             rho = 1  : T= 50 ty(1) .07 ty(0) .24 Amb .17
*                        T=100 ty(1) .04 ty(0) .13 Amb .09
*                        T=200 ty(1) .05 ty(0) .08 Amb .04
*             rho = 0.9: T= 50 ty(1) .05 ty(0) .20 Amb .15
*                        T=100 ty(1) .02 ty(0) .09 Amb .06
*                        T=200 ty(1) .01 ty(0) .03 Amb .01
*
*          The seed is varied every replication, so the data differ across
*          replications rather than the loop re-drawing the same panel.
*==============================================================================
if (`runmc') {
    local R 200
    di _n(2) "{hline 78}"
    di "PART 7.  Replication of Table C.3  (`R' reps; the paper uses 1,000)"
    di "{hline 78}"
    di %-6s "rho" %-6s "phi" %7s "T" %11s "ty(1)" %11s "ty(0)" %11s "Amb" ///
       %13s "mean b-1"
    di "{hline 78}"
    foreach rho in 1 0.9 {
      foreach phi in 1 0.9 {
        foreach T in 50 100 200 {
          local n1 = 0
          local n0 = 0
          local bs = 0
          local ok = 0
          forvalues r = 1/`R' {
            qui xbpdgp , npan(20) tper(`T') kreg(1) rho(`rho') phi(`phi') ///
                bload(1) seed(`=90000 + 31*`r'')
            capture qui xtboundpanico bounds y x1 , model(2) nocips
            if (_rc == 0) {
              local ok = `ok' + 1
              if (r(tybar) < r(cv_i1)) local n1 = `n1' + 1
              if (r(tybar) < r(cv_i0)) local n0 = `n0' + 1
              matrix B = r(b_cce)
              local bs = `bs' + B[1,1]
            }
          }
          di %-6s "`rho'" %-6s "`phi'" %7.0f `T' %11.3f `=`n1'/`ok'' ///
             %11.3f `=`n0'/`ok'' %11.3f `=(`n0'-`n1')/`ok'' ///
             %13.4f `=`bs'/`ok' - 1'
        }
        di "{dup 78:-}"
      }
    }
    di "EXPECT (phi = 1): ty(1) near 0.05 and falling in T; ty(0) over-rejecting"
    di "        and converging; Amb shrinking.  (phi = 0.9): power -> 1 by T=200."
    di "        mean b-1 within about +/- 0.01 everywhere."
}
else {
    di _n "PART 7 skipped (set local runmc 1 to run it)."
}

di _n(2) "{hline 78}"
di "xtboundpanico_example.do completed."
di "{hline 78}"
