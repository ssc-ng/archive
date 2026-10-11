*! surardl_example.do 1.0.1  10oct2026
*! Self-test for surardl on the paper's own Monte Carlo design.
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! github.com/merwanroudane
*!
*! Every parameter below is KNOWN, so each block states what the command
*! must return. Run the whole file and read the "PASS / CHECK" column.
*!
*!   Data-generating process, Arif & Furuoka (2026, section 4.1):
*!       x_{k,i,t} = x_{k,i,t-1} + v_{k,i,t}            eq. (123)
*!       eps_t ~ N(0, (1-rho) I_N + rho 1 1')           eq. (124)
*!       Dy_{i,t} = mu_i + lambda y_{i,t-1}
*!                  + sum_k beta_k x_{k,i,t-1}
*!                  + sum_k gamma_k Dx_{k,i,t} + u_{i,t} eq. (125)
*!   Baseline truth: mu = 0.5, lambda = -0.3, beta = 0.09, gamma = 0.2,
*!   so the true long-run coefficient is theta = -beta/lambda = 0.3.
*!
*!   Note on the sign of beta. Section 4.1 of the draft prints the
*!   baseline as "beta = -0.09" while also stating lambda = -0.3 and
*!   theta = 0.3. Those three are mutually inconsistent, since
*!   theta = -beta/lambda = -(-0.09)/(-0.3) = -0.3. The internally
*!   consistent set, used here, is beta = +0.09, which delivers the
*!   stated theta = 0.3.

version 14.0
clear
set more off

* -------------------------------------------------------------------
* A reusable generator for the paper's DGP.
*   N, T, K, rho, lambda, beta, gamma  as above
*   lambda = 0 and beta = 0 imposes the null of no level relationship
* -------------------------------------------------------------------
capture program drop sa_dgp
program define sa_dgp
    syntax , n(integer) t(integer) [ k(integer 1) rho(real 0)        ///
             lambda(real -0.3) beta(real 0.09) gamma(real 0.2)      ///
             burn(integer 50) ]

    local tt = `t' + `burn' + 1
    clear
    qui set obs `=`n'*`tt''
    qui gen int id = ceil(_n / `tt')
    qui bysort id: gen int time = _n
    qui xtset id time

    * common factor giving equicorrelation rho across units, eq. (124)
    tempvar cf
    qui gen double `cf' = .
    qui sort time id
    qui by time: replace `cf' = rnormal() if _n == 1
    qui by time: replace `cf' = `cf'[1]
    qui sort id time

    qui gen double u = sqrt(`rho') * `cf' + sqrt(1 - `rho') * rnormal()

    * I(1) regressors, eq. (123)
    forvalues j = 1/`k' {
        qui gen double vx`j' = rnormal()
        qui by id: gen double x`j' = sum(vx`j')
    }

    * recursive dependent variable, eq. (125)
    qui gen double y = 0
    local rhs ""
    forvalues j = 1/`k' {
        local rhs "`rhs' + `beta' * x`j'[_n-1] + `gamma' * (x`j' - x`j'[_n-1])"
    }
    qui by id: replace y = y[_n-1] + 0.5 + `lambda' * y[_n-1] `rhs' + u ///
        if _n > 1

    qui drop if time <= `burn' + 1
    qui by id: replace time = _n
    qui xtset id time
    qui keep id time y x*
end

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 1  Recovery of the true parameters (lambda = -0.3, theta = 0.3)"
di as text "{hline 78}"
* ===================================================================
set seed 90210
sa_dgp, n(3) t(500) k(1) rho(0.6)
surardl y x1, case(3) lags(1) noctable nobounds nodiagnostics

* A single draw is noisy, so average over replications before judging.
local R 50
local sl 0
local st 0
forvalues r = 1/`R' {
    set seed `=90210 + 7*`r''
    qui sa_dgp, n(3) t(500) k(1) rho(0.6)
    qui surardl y x1, case(3) lags(1)
    tempname LRr
    matrix `LRr' = e(longrun)
    local sl = `sl' + _b[id_1:L.y]
    local st = `st' + `LRr'[1, 3]
}
local ml = `sl' / `R'
local mt = `st' / `R'
local f1 = cond(abs(`ml' + 0.3) < 0.02, "PASS", "CHECK")
local f2 = cond(abs(`mt' - 0.3) < 0.02, "PASS", "CHECK")
di as text "   mean over `R' replications, T = 500:"
di as text "      lambda = " as result %8.4f `ml' as text "   (truth -0.300)   `f1'"
di as text "      theta  = " as result %8.4f `mt' as text "   (truth  0.300)   `f2'"
di as text "   -> " cond("`f1'`f2'" == "PASSPASS", ///
   "PASS: the estimator recovers the DGP.", ///
   "CHECK: investigate before trusting the build.")

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 2  Consistency: bias and RMSE of lambda must fall with T"
di as text "{hline 78}"
* ===================================================================
di as text "       T      mean lambda       bias        RMSE"
foreach T in 50 100 200 400 {
    local sb 0
    local ss 0
    forvalues r = 1/40 {
        set seed `=5000 + 13*`r' + `T''
        qui sa_dgp, n(3) t(`T') k(1) rho(0.6)
        qui surardl y x1, case(3) lags(1)
        local l1 = _b[id_1:L.y]
        local sb = `sb' + `l1'
        local ss = `ss' + (`l1' + 0.3)^2
    }
    di as text %8.0f `T' as result %15.4f `sb'/40 %12.4f `sb'/40 + 0.3 %12.4f sqrt(`ss'/40)
}
di as text "   -> bias and RMSE should both shrink toward zero as T grows (Theorem 1)."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 3  Efficiency: SUR must beat OLS when rho > 0, and tie when rho = 0"
di as text "{hline 78}"
di as text "   Reproduces the relative-efficiency pattern of the paper's Tables 1-2."
* ===================================================================
di as text "      rho     RMSE(OLS)   RMSE(SUR)    RE = OLS/SUR   expected"
foreach rho in 0 0.3 0.6 0.8 {
    local so 0
    local ss 0
    forvalues r = 1/60 {
        set seed `=7000 + 17*`r' + 100*`rho''
        qui sa_dgp, n(5) t(100) k(1) rho(`rho')
        qui surardl y x1, case(3) lags(1) method(ols)
        local lo = _b[id_1:L.y]
        qui surardl y x1, case(3) lags(1)
        local ls = _b[id_1:L.y]
        local so = `so' + (`lo' + 0.3)^2
        local ss = `ss' + (`ls' + 0.3)^2
    }
    local ro = sqrt(`so'/60)
    local rs = sqrt(`ss'/60)
    local exp = cond(`rho' == 0, "RE ~ 1.00", "RE > 1")
    di as text %9.1f `rho' as result %13.4f `ro' %12.4f `rs' %15.3f `ro'/`rs' as text "   `exp'"
}
di as text "   -> RE must rise with rho (Proposition 2); RE ~ 1 at rho = 0 (Proposition 1)."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 4  Proposition 1: with a diagonal Sigma, SUR = OLS numerically"
di as text "{hline 78}"
* ===================================================================
set seed 4242
sa_dgp, n(3) t(200) k(1) rho(0)
qui surardl y x1, case(3) lags(1) method(ols)
tempname BO
matrix `BO' = e(b)
qui surardl y x1, case(3) lags(1) method(iterated) iterate(500)
tempname BI
matrix `BI' = e(b)
qui surardl y x1, case(3) lags(1)
tempname BT
matrix `BT' = e(b)
mata: b1 = st_matrix("`BO'"); b2 = st_matrix("`BT'");                  ///
      printf("   max |b(OLS) - b(SUR)| with rho = 0 : %10.3e\n",        ///
             max(abs(b1 - b2)))
di as text "   -> small but non-zero: Sigma-hat is estimated, so the equality is"
di as text "      exact only when Sigma-hat is exactly diagonal (Proposition 1)."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 5  Size of the bounds test under H0 (lambda = 0, beta = 0)"
di as text "{hline 78}"
di as text "   Tabulated PSS values vs the SUR residual bootstrap, nominal 5%."
* ===================================================================
local nrep 100
local rpss 0
local rboot 0
local rsim 0
forvalues r = 1/`nrep' {
    set seed `=20000 + 29*`r''
    qui sa_dgp, n(3) t(60) k(1) rho(0.6) lambda(0) beta(0)
    qui surardl y x1, case(3) lags(1) bootstrap(199) seed(`=31*`r'')
    tempname BND DF BPV
    matrix `BND' = e(bounds)
    matrix `DF'  = e(decF)
    matrix `BPV' = e(bootp)
    if (`DF'[1, 2] == 2) local rpss = `rpss' + 1
    if (`BPV'[1, 1] < 0.05) local rboot = `rboot' + 1
}
di as text "   PSS 5% bound          rejection rate = " as result %6.3f `rpss'/`nrep'
di as text "   SUR bootstrap 5%      rejection rate = " as result %6.3f `rboot'/`nrep'
di as text "   -> the bootstrap rate should sit near 0.05; the tabulated rate need not"
di as text "      (Simulation 2 of the paper). A bootstrap rate far above 0.05 is a bug."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 6  Power of the bounds test under H1 (lambda = -0.3)"
di as text "{hline 78}"
* ===================================================================
local nrep 100
local pboot 0
forvalues r = 1/`nrep' {
    set seed `=40000 + 37*`r''
    qui sa_dgp, n(3) t(60) k(1) rho(0.6)
    qui surardl y x1, case(3) lags(1) bootstrap(199) seed(`=41*`r'')
    tempname BPV
    matrix `BPV' = e(bootp)
    if (`BPV'[1, 1] < 0.05) local pboot = `pboot' + 1
}
di as text "   SUR bootstrap 5%      rejection rate = " as result %6.3f `pboot'/`nrep'
di as text "   -> power should be high (well above the size in TEST 5)."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 7  Every code path runs"
di as text "{hline 78}"
* ===================================================================
set seed 1234
sa_dgp, n(4) t(120) k(2) rho(0.5)

local nfail 0
foreach c in 1 2 3 4 5 {
    capture qui surardl y x1 x2, case(`c') lags(1)
    if _rc {
        di as error "   case(`c') FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
foreach m in twostep iterated ols {
    capture qui surardl y x1 x2, method(`m')
    if _rc {
        di as error "   method(`m') FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
foreach s in t dfmax dfk dfk2 {
    capture qui surardl y x1 x2, sigmadf(`s')
    if _rc {
        di as error "   sigmadf(`s') FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
foreach f in wald rss rssall {
    capture qui surardl y x1 x2, fstat(`f')
    if _rc {
        di as error "   fstat(`f') FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
capture qui surardl y x1 x2, maxlags(3) aic
if _rc {
    di as error "   maxlags/aic FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui surardl y x1 x2, lags(2 1 1) small level(90)
if _rc {
    di as error "   lags/small/level FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui surardl y x1 x2, bootstrap(99) boottarget(joint) bootdgp(vecm)
if _rc {
    di as error "   bootstrap(joint,vecm) FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui surardl y x1 x2, simulate(99) simrho(0.5)
if _rc {
    di as error "   simulate FAILED, rc = " _rc
    local nfail = `nfail' + 1
}

qui surardl y x1 x2, case(3) lags(1) bootstrap(199)
foreach sc in summary sigma efficiency shortrun ecequal poolability {
    capture qui estat `sc'
    if _rc {
        di as error "   estat `sc' FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
capture qui estat longrun, fieller
if _rc {
    di as error "   estat longrun, fieller FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui estat longrun, bootstrap(99)
if _rc {
    di as error "   estat longrun, bootstrap FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui estat lrequal
if _rc {
    di as error "   estat lrequal FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui estat serial, lags(2)
if _rc {
    di as error "   estat serial FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
foreach st in residuals olsresiduals xb ec {
    capture drop _tst
    capture qui predict double _tst, `st'
    if _rc {
        di as error "   predict, `st' FAILED, rc = " _rc
        local nfail = `nfail' + 1
    }
}
capture drop _tst
capture qui estat graph, lambda bounds longrun sigma efficiency
if _rc {
    di as error "   estat graph FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui estat graph, bootdist
if _rc {
    di as error "   estat graph, bootdist FAILED, rc = " _rc
    local nfail = `nfail' + 1
}
capture qui test [id_1]L.y = [id_2]L.y
if _rc {
    di as error "   test across equations FAILED, rc = " _rc
    local nfail = `nfail' + 1
}

if (`nfail' == 0) di as text "   -> PASS: every option and postestimation path ran without error."
else              di as error "   -> `nfail' path(s) FAILED."

* ===================================================================
di _n(2) as text "{hline 78}"
di as text "TEST 8  Error handling"
di as text "{hline 78}"
* ===================================================================
set seed 77
sa_dgp, n(3) t(80) k(1) rho(0.3)
local nbad 0
capture noisily {
    qui xtset, clear
    capture surardl y x1
    if _rc == 0 local nbad = `nbad' + 1
    qui xtset id time
}
capture surardl y x1, case(9)
if _rc == 0 local nbad = `nbad' + 1
capture surardl y x1, method(nonsense)
if _rc == 0 local nbad = `nbad' + 1
capture surardl y x1, lags(0)
if _rc == 0 local nbad = `nbad' + 1
capture surardl y x1, trendvar(time) case(3)
if _rc == 0 local nbad = `nbad' + 1
capture surardl y x1, noconstant trend
if _rc == 0 local nbad = `nbad' + 1
if (`nbad' == 0) di as text "   -> PASS: all six invalid calls were rejected."
else             di as error "   -> `nbad' invalid call(s) were wrongly accepted."

di _n(2) as text "{hline 78}"
di as text "End of surardl self-test."
di as text "{hline 78}"
