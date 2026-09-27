* cointvol_example.do -- a guided tour of cointvol
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
* Runs in a few minutes; increase reps() for publication-quality p-values.
version 14.0
clear
set more off

* ---------------------------------------------------------------------------
* 1. Real data: US macro series (Stata example data set)
* ---------------------------------------------------------------------------
webuse balance2, clear

* diagnostics on the VAR: ARCH effects and variance profiles
cointvol diag y i c, lags(2) trend(rconstant) archlm(4) march(2) varprofile

* lag order and rank chosen jointly by information criteria
cointvol select y i c, maxlag(4) trend(rconstant) ic(bic hqc)

* Johansen rank tests with wild-bootstrap p-values (CRT 2014 algorithm)
cointvol rank y i c, lags(2) trend(rconstant) method(wild) reps(199) seed(2026)
cointvol graph bootdist

* adaptive LR test robust to nonstationary volatility (Boswijk and Zu 2022)
cointvol adaptive y i c, lags(2) trend(rconstant) reps(199) seed(2026)

* test weak exogeneity of consumption with the wild bootstrap (BCRT 2016)
cointvol restrict y i c, lags(2) rank(1) trend(rconstant) exog(c) method(wild) reps(199) seed(2026)
cointvol table

* ---------------------------------------------------------------------------
* 2. Simulated data: a cointegrated VAR with a variance break
* ---------------------------------------------------------------------------
cointvol simulate, nobs(300) dgp(vecm) innov(break) seed(11) clear
cointvol rank y1 y2, lags(1) trend(none) method(asy)
cointvol rank y1 y2, lags(1) trend(none) method(wild) reps(199) seed(11)

* single-equation tests and the null of cointegration
cointvol resid y1 y2, test(eg crdw) simreps(499) seed(11)
cointvol nullcoint y1 y2, reps(199) seed(11)

* ---------------------------------------------------------------------------
* 3. Joint VECM-GARCH estimation (Lee 1994 style diagonal BEKK)
* ---------------------------------------------------------------------------
cointvol simulate, nobs(600) dgp(vecm) innov(garch) seed(7) clear
cointvol vecmgarch y1 y2, lags(1) rank(1) trend(constant) variance(dbekk)
estat moments
cointvol graph volatility

di as txt _n "cointvol_example.do finished"
