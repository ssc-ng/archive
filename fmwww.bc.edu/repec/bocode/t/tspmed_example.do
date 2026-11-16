* tspmed_example.do
* Examples for tspmed: causal mediation analysis for time series.
* All data are simulated with two mediators and known effects.
* True values for d1 = 1, d0 = 0 in every design below:
*   NDE = 1.5,  NIE via m1 = 0.8*1.0 = 0.8,  NIE via m2 = -0.5*0.6 = -0.3
*   NIE = 0.5,  TE = 2.0,  PM = 0.25

clear all
set more off
set seed 20261114
local T 300

* =====================================================================
* PART A. Stationary series with serially correlated errors
*         estimators: ols, ardl
* =====================================================================
set obs `T'
gen t = _n
tsset t

* AR(1) disturbances
foreach v in x d m1 m2 y {
    gen double e_`v' = rnormal()
    gen double u_`v' = e_`v'
    replace u_`v' = 0.5*u_`v'[_n-1] + e_`v' if _n > 1
}
gen double x  = u_x
gen double d  = 0.5*x + u_d
gen double m1 =  0.8*d + 0.3*x + u_m1
gen double m2 = -0.5*d + 0.3*x + u_m2
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + 0.5*x + u_y
keep t x d m1 m2 y

* 1. OLS; default long-run variance: prewhitened quadratic-spectral kernel,
*    Andrews (1991) automatic bandwidth
tspmed y, treatment(d) mediators(m1 m2) controls(x)

* 2. Newey-West or White standard errors instead
tspmed y, treatment(d) mediators(m1 m2) controls(x) vce(hac) haclag(4) nodiag
tspmed y, treatment(d) mediators(m1 m2) controls(x) vce(robust) nodiag

* 3. ARDL: lags chosen by AIC (or ic(bic)); long-run effects; bounds tests with
*    simulated I(0) and I(1) p-values in the diagnostics
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(ardl)

* 4. ARDL with fixed lags and a chosen break date for the Chow test; the second table
*    gives the short-run (error-correction) coefficients, also stored in e(sr)
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(ardl) ardllags(2 1) break(150)
matrix list e(sr)

* 5. Moving-block bootstrap of the effects
tspmed y, treatment(d) mediators(m1 m2) controls(x) bootstrap(199) seed(1) nodiag

* 6. A different treatment contrast: effect of moving d from its mean to mean + 1 sd
quietly summarize d
local lo = r(mean)
local hi = r(mean) + r(sd)
tspmed y, treatment(d) mediators(m1 m2) controls(x) d0(`lo') d1(`hi') nodiag

* 7. Stored results (e(diag) exists only when nodiag is not specified)
quietly tspmed y, treatment(d) mediators(m1 m2) controls(x)
ereturn list
matrix list e(effects)
matrix list e(diag)

* =====================================================================
* PART B. Cointegrated I(1) series
*         estimators: fmols, dols
* =====================================================================
clear
set obs `T'
gen t = _n
tsset t

gen double eD = rnormal()
gen double d  = sum(eD)                 // random walk treatment
gen double x  = sum(rnormal())          // random walk control
foreach v in m1 m2 y {
    gen double e_`v' = rnormal()
    gen double u_`v' = e_`v'
    replace u_`v' = 0.5*u_`v'[_n-1] + e_`v' if _n > 1
}
gen double m1 =  0.8*d + 0.3*x + u_m1
gen double m2 = -0.5*d + 0.3*x + u_m2
* the outcome error is correlated with the treatment innovation (endogeneity)
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + 0.5*x + u_y + 0.5*eD
keep t x d m1 m2 y

* 8. FMOLS (Phillips-Hansen): automatic bandwidth, prewhitening, mixed-normal
*    joint covariance; Engle-Granger residual ADF with simulated p-value
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(fmols)

* 9. FMOLS with sieve (VAR) bootstrap-t confidence intervals and p-values
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(fmols) bootstrap(199) seed(1) nodiag

* 10. FMOLS with a fixed bandwidth and no prewhitening
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(fmols) fmbw(6) noprewhite nodiag

* 11. DOLS (Stock-Watson) with two leads and two lags of the differences
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(dols) leads(2) dlags(2)

* 12. DOLS with a linear trend and sieve bootstrap
tspmed y, treatment(d) mediators(m1 m2) controls(x) estimator(dols) trend bootstrap(199) seed(1) nodiag

* =====================================================================
* PART C. Nonlinear confounding
*         estimator: dml (double machine learning, blocked cross-fitting)
* =====================================================================
clear
set obs `T'
gen t = _n
tsset t

foreach v in x1 x2 d m1 m2 y {
    gen double e_`v' = rnormal()
    gen double u_`v' = e_`v'
    replace u_`v' = 0.4*u_`v'[_n-1] + e_`v' if _n > 1
}
gen double x1 = u_x1
gen double x2 = u_x2
gen double d  = tanh(x1) + 0.5*sin(x2) + 0.3*x1*x2 + u_d
gen double g  = cos(x1) + 0.4*x1*x2
gen double m1 =  0.8*d + g + u_m1
gen double m2 = -0.5*d + 0.5*g + u_m2
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + sin(x2) + 0.5*x1*x2 + u_y
keep t x1 x2 d m1 m2 y

* 13. DML: treatment, mediators and outcome residualised on a cubic series in
*     the controls with blocked cross-fitting
tspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(dml) poly(3)

* 14. For comparison: OLS with linear controls is biased in this design
tspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) nodiag
