*! lassour_example.do   version 1.0.0  17oct2026
*! Self-test and worked examples for the lassour package
*! Dr Merwan Roudane  (merwanroudane920@gmail.com)
*!
*! Run with:   do lassour_example.do
*!
*! Exercises every code path and prints truth-vs-result so the output can be
*! refereed. Sections 1-6 are quick; section 7 (Monte Carlo) takes a few
*! minutes and can be skipped by setting  local run_mc 0  below.

clear
set more off
local run_mc 1          // set to 0 to skip the Monte Carlo section

di _n(2) "{hline 78}"
di "  lassour 1.0.0 -- self test"
di "{hline 78}"

* =====================================================================
* 1. A random walk: the test should NOT reject
* =====================================================================
di _n "{hline 78}"
di "  1. RANDOM WALK (truth: unit root)  -- expect large p-values"
di "{hline 78}"

clear
set obs 201
set seed 20261017
gen int t = _n
tsset t
gen double rw = sum(rnormal())
replace rw = 0 in 1

lassour rw, seed(1) reps(499)

di _n "  stored: tau = " %8.4f r(tau) "   p = " %6.4f r(tau_p)
di   "          tauIE = " %8.4f r(tauie) "   p = " %6.4f r(tauie_p)
assert r(tau_p)   > 0.10
assert r(tauie_p) > 0.10
di as result "  PASS: unit root not rejected, as it should not be."

* =====================================================================
* 2. A stationary AR(1): the test SHOULD reject
* =====================================================================
di _n "{hline 78}"
di "  2. STATIONARY AR(1), rho = 0.5 (truth: stationary) -- expect small p"
di "{hline 78}"

clear
set obs 201
set seed 4242
gen int t = _n
tsset t
gen double ar1 = 0
qui replace ar1 = 0.5*ar1[_n-1] + rnormal() if _n > 1

lassour ar1, seed(1) reps(499)

di _n "  stored: tau = " %10.4f r(tau) "   p = " %6.4f r(tau_p)
di   "          tauIE = " %10.4f r(tauie) "   p = " %6.4f r(tauie_p)
di   "          rho-hat = " %8.4f r(rho) "  (truth: 0.5 - 1 = -0.5)"
di   "          J = " %8.4f r(J) "  (should be SMALL under stationarity)"
assert r(tau_p)   < 0.05
assert r(tauie_p) < 0.05
di as result "  PASS: unit root rejected, as it should be."

* =====================================================================
* 3. A trending series: deterministics(trend)
* =====================================================================
di _n "{hline 78}"
di "  3. RANDOM WALK WITH DRIFT -- deterministics(trend)"
di "{hline 78}"

clear
set obs 201
set seed 7777
gen int t = _n
tsset t
gen double drift = 0
qui replace drift = drift[_n-1] + 0.3 + rnormal() if _n > 1

di _n "  (a) wrongly using deterministics(constant):"
lassour drift, deterministics(constant) seed(2) reps(299) notable
di "      tau = " %8.4f r(tau) "   p = " %6.4f r(tau_p)

di _n "  (b) correctly using deterministics(trend):"
lassour drift, deterministics(trend) seed(2) reps(299)

* =====================================================================
* 4. Serially correlated errors: the sieve step
* =====================================================================
di _n "{hline 78}"
di "  4. UNIT ROOT WITH AR(1) ERRORS -- the sieve (recolouring) step"
di "{hline 78}"

clear
set obs 201
set seed 31415
gen int t = _n
tsset t
gen double e = 0
qui replace e = 0.6*e[_n-1] + rnormal() if _n > 1
gen double yar = sum(e)
replace yar = 0 in 1

di _n "  (a) with the sieve, q = p (the default):"
lassour yar, seed(3) reps(299) notable
di "      p = " r(p) "  q = " r(q) "  tau = " %8.4f r(tau) "  p = " %6.4f r(tau_p)

di _n "  (b) without recolouring, sievelags(0):"
lassour yar, seed(3) reps(299) sievelags(0) notable
di "      p = " r(p) "  q = " r(q) "  tau = " %8.4f r(tau) "  p = " %6.4f r(tau_p)
di _n "  Both should fail to reject; (a) is the more accurate of the two."

* =====================================================================
* 5. Non-stationary volatility -- what the bootstrap is for
* =====================================================================
di _n "{hline 78}"
di "  5. UNIT ROOT WITH A VARIANCE BREAK ([T] eq. 20 logistic transition)"
di "{hline 78}"

clear
set obs 201
set seed 2718
gen int t = _n
tsset t
* late positive shift: kappa = .8, s2^2 = 4
gen double sig = sqrt(1 + 3*(1/(1 + exp(-(25/200)*(t - 0.8*200)))))
gen double yv = sum(rnormal()*sig)
replace yv = 0 in 1

di _n "  (a) asymptotic critical values (NOT valid under this DGP):"
lassour yv, nobootstrap notable
di "      tau = " %8.4f r(tau) "   c.v. = " %8.4f r(tau_cv)

di _n "  (b) sieve wild bootstrap (valid):"
lassour yv, seed(4) reps(499)

* =====================================================================
* 6. Every remaining code path
* =====================================================================
di _n "{hline 78}"
di "  6. OPTION COVERAGE"
di "{hline 78}"

* regenerate both series in one dataset (earlier sections cleared the data)
clear
set obs 201
set seed 4242
gen int t = _n
tsset t
gen double ar1 = 0
qui replace ar1 = 0.5*ar1[_n-1] + rnormal() if _n > 1
set seed 20261017
gen double rw = sum(rnormal())
qui replace rw = 0 in 1

di _n "  (a) test(tau) only:"
qui lassour ar1, test(tau) seed(5) reps(199) notable
di "      tau = " %8.4f r(tau) "  p = " %6.4f r(tau_p)

di _n "  (b) test(tauie) only:"
qui lassour ar1, test(tauie) seed(5) reps(199) notable
di "      tauIE = " %10.4f r(tauie) "  p = " %6.4f r(tauie_p)

di _n "  (c) deterministics(none):"
qui lassour ar1, deterministics(none) seed(5) reps(199) notable
di "      tau = " %8.4f r(tau) "  p = " %6.4f r(tau_p)

di _n "  (d) every lag selection criterion:"
foreach c in rsmaic rsmbic maic mbic aic bic {
    qui lassour ar1, criterion(`c') seed(5) reps(199) notable
    di "      " %-7s "`c'" ": p = " r(p) "   tau = " %9.4f r(tau) ///
       "   pval = " %6.4f r(tau_p)
}

di _n "  (e) fixed lag order, lags(4):"
qui lassour ar1, lags(4) seed(5) reps(199) notable
di "      p = " r(p) " (should be 4)  tau = " %8.4f r(tau)
assert r(p) == 4

di _n "  (e2) icdetrend(ols) vs icdetrend(fd):"
foreach ic in ols fd {
    qui lassour rw, criterion(maic) icdet(`ic') maxlag(12) nobootstrap notable
    di "      icdetrend(" %-4s "`ic'" "): p = " r(p) "   r(icdetrend) = " r(icdetrend)
}

di _n "  (f) tuning: alpha(.2) jreps(400) lrvlags(2) bandwidth(.15):"
qui lassour ar1, alpha(.2) jreps(400) lrvlags(2) bandwidth(.15) ///
    seed(5) reps(199) notable
di "      J = " %8.4f r(J) "   k = " r(lrvlags) "   tauIE = " %10.4f r(tauie)
assert r(lrvlags) == 2

di _n "  (g) level(90) and level(99):"
foreach L in 90 95 99 {
    qui lassour rw, nobootstrap level(`L') notable
    di "      level(`L'): tau c.v. = " %8.4f r(tau_cv) ///
       "   tauIE c.v. = " %8.4f r(tauie_cv)
}

di _n "  (h) published critical value tables:"
foreach d in none constant trend {
    qui lassour cv, deterministics(`d')
    di "      `d': r(cv) is " rowsof(r(cv)) " x " colsof(r(cv))
}
lassour cv, deterministics(constant)

di _n "  (i) returned matrices:"
qui lassour ar1, seed(6) reps(199) notable
matrix B = r(bootdist)
matrix P = r(path)
di "      r(bootdist) is " rowsof(B) " x " colsof(B) "  (expect 199 x 2)"
di "      r(path)     is " rowsof(P) " x " colsof(P)
assert rowsof(B) == 199

di _n "  (j) if/in restriction:"
qui lassour ar1 if t <= 150, seed(7) reps(199) notable
di "      N = " r(N) " (expect 150)   N_adf = " r(N_adf)
assert r(N) == 150

di _n "  (k) time-series operator (D.ar1 is stationary by construction):"
qui lassour D.ar1, seed(7) reps(199) notable
di "      tau = " %10.4f r(tau) "   p = " %6.4f r(tau_p)

di _n "  (l) the four-panel graph:"
lassour ar1, seed(8) reps(299) graph notable name(lsrdemo)
di "      graph drawn: lsrdemo (panels lsrdemo_series/_path/_boot/_vol)"

di _n "  (m) expected errors are caught cleanly:"
capture lassour ar1, deterministics(bogus)
di "      deterministics(bogus) -> rc = " _rc "  (expect 198)"
capture lassour ar1, criterion(bogus)
di "      criterion(bogus)      -> rc = " _rc "  (expect 198)"
capture lassour ar1, test(bogus)
di "      test(bogus)           -> rc = " _rc "  (expect 198)"
capture lassour ar1, reps(10)
di "      reps(10)              -> rc = " _rc "  (expect 198)"
capture lassour ar1, alpha(0.9)
di "      alpha(0.9)            -> rc = " _rc "  (expect 198)"

preserve
qui drop if inrange(t, 50, 60)
capture lassour ar1
di "      internal gap          -> rc = " _rc "  (expect 198)"
restore

preserve
qui tsset, clear
capture lassour ar1
di "      not tsset             -> rc = " _rc "  (expect 459)"
restore

di _n as result "  PASS: all option paths exercised."

* =====================================================================
* 7. Monte Carlo size and power (the real proof of a bootstrap test)
* =====================================================================
if (`run_mc' == 1) {

    di _n "{hline 78}"
    di "  7. MONTE CARLO SIZE AND POWER  (nominal 5%)"
    di "     Paper [T] Table 1, T=75 i.i.d.: tau .049, tauIE .046"
    di "{hline 78}"

    capture program drop lsr_mc
    program define lsr_mc
        args T c nrep B det vol
        local rej_t = 0
        local rej_i = 0
        local nok   = 0
        local rho   = 1 + `c'/`T'
        local dname = cond(`det' == 1, "constant", "trend")
        forvalues r = 1/`nrep' {
            quietly {
                clear
                set obs `=`T'+1'
                gen int t = _n
                tsset t
                gen double sig = 1
                if (`vol' == 1) {
                    replace sig = sqrt(1 - 0.75*(1/(1 + ///
                        exp(-(25/`T')*(t - 0.2*`T')))))
                }
                if (`vol' == 2) {
                    replace sig = sqrt(1 + 3*(1/(1 + ///
                        exp(-(25/`T')*(t - 0.8*`T')))))
                }
                gen double e = rnormal()*sig
                gen double y = 0
                replace y = `rho'*y[_n-1] + e if _n > 1
                * vary the seed each rep: the bootstrap stream must move too
                capture lassour y, reps(`B') deterministics(`dname') ///
                    seed(`=100000 + `r'') nodots notable
            }
            if (_rc == 0) {
                local nok = `nok' + 1
                if (r(tau_p)   <= 0.05) local rej_t = `rej_t' + 1
                if (r(tauie_p) <= 0.05) local rej_i = `rej_i' + 1
            }
        }
        di as text "    T=" as result %4.0f `T' as text " c=" as result %6.1f `c' ///
           as text " det=" as result %-8s "`dname'" as text " vol=" as result `vol' ///
           as text "   tau: " as result %5.3f `rej_t'/`nok' ///
           as text "   tauIE: " as result %5.3f `rej_i'/`nok'
    end

    di _n "  SIZE (c = 0):"
    lsr_mc 75  0 200 199 1 0
    lsr_mc 100 0 200 199 1 0
    lsr_mc 100 0 200 199 2 0

    di _n "  SIZE under non-stationary volatility:"
    lsr_mc 100 0 200 199 1 1
    lsr_mc 100 0 200 199 1 2

    di _n "  POWER (c = -7 constant, c = -13.5 trend):"
    lsr_mc 100  -7.0  150 199 1 0
    lsr_mc 100 -13.5  150 199 2 0

    di _n "  Size should sit near or below .05; power should be well above it."
}

di _n(2) "{hline 78}"
di "  lassour self test complete."
di "{hline 78}"
di ""
