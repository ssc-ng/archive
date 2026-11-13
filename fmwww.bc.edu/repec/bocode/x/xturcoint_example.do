* xturcoint_example.do -- runs every example of the xturcoint help files
* Dr Merwan Roudane (merwanroudane920@gmail.com)
version 14.0
clear

xturcoint

* ---- panel unit root and cross-sectional dependence ------------------
webuse pennxrate, clear
xtset id year
xturcoint cd lnrxrate
xturcoint cd lnrxrate, paper
xturcoint panic lnrxrate
xturcoint panic lnrxrate, paper
xturcoint panic lnrxrate, method(bn2010) model(trend) kmax(8) fcrit(icp)
xturcoint panic lnrxrate, method(wl2009) pmax(4) ic(aic)
xturcoint panicca lnrxrate
xturcoint mp lnrxrate, factors(1)
xturcoint mp lnrxrate, factors(2) model(trend)

preserve
keep if id<=20
xturcoint lm lnrxrate
xturcoint lm lnrxrate, model(level) nbreak(1)
xturcoint lm lnrxrate, model(trend) nbreak(1) pmax(4) ic(bic)
xturcoint lm lnrxrate, model(trend) nbreak(1) pmax(4) ic(bic) paper
xturcoint lm lnrxrate, model(level) nbreak(2) pmax(2) notable
matrix list r(individual)
restore

preserve
keep if id<=30 & year>=1990
xturcoint fixedt lnrxrate
xturcoint fixedt lnrxrate, model(trend)
restore

webuse grunfeld, clear
xtset company year
xturcoint cd invest mvalue kstock
xturcoint cd invest mvalue kstock, paper
xturcoint cd invest

* ---- panel cointegration ---------------------------------------------
webuse xtcoint, clear
xtset id time
xturcoint cusum productivity rddomestic rdforeign
xturcoint cusum productivity rddomestic rdforeign, estimator(fmols) model(trend)
xturcoint adfmin productivity rddomestic
xturcoint adfmin productivity rddomestic rdforeign, model(trend) lags(2) trim(0.15)
return list
