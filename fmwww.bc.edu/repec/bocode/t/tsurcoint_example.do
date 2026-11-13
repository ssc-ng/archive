* tsurcoint_example.do -- runs every example of the tsurcoint help files
* Dr Merwan Roudane (merwanroudane920@gmail.com)
version 14.0
clear

tsurcoint

webuse lutkepohl2, clear

* ---- Fourier / wavelet KSS and ADF -------------------------------------
tsurcoint fkss ln_inv
tsurcoint fkss ln_inv, model(trend) simulate(1000) seed(123)
tsurcoint fkss ln_inv, bootstrap(199) seed(123)
tsurcoint fadf ln_inv, pmax(4) ic(aic)
tsurcoint wkss ln_inv, simulate(1000) seed(1)
tsurcoint wkss ln_inv, model(trend) simulate(1000) seed(1)
tsurcoint wkss ln_inv, gauss
tsurcoint fwkss ln_inv, simulate(1000) seed(1)
tsurcoint fwkss ln_inv, model(trend) pmax(4) fmax(3) ic(bic)
tsurcoint fwadf ln_inv, simulate(1000) seed(1)
tsurcoint fwadf ln_inv, model(trend) ic(aic) paper

* ---- quantile tests -----------------------------------------------------
tsurcoint qkss ln_inv
tsurcoint qkss ln_inv, tau(0.1(0.1)0.9) lags(4) model(trend)
tsurcoint qfkss ln_inv, freq(1) lags(4)
tsurcoint qfkss ln_inv, tau(0.5) freq(1) lags(4) bootstrap(99) seed(12)
tsurcoint qks ln_inv, testtype(kss) lags(2)
tsurcoint qks ln_inv, testtype(fkss) freq(1) lags(2) model(trend)
tsurcoint qks ln_inv, testtype(adf) lags(4)
tsurcoint qks ln_inv, testtype(fadf) lags(2)

* ---- GLS tests with breaks ----------------------------------------------
tsurcoint glsbreak ln_inv
tsurcoint glsbreak ln_inv, model(level)
tsurcoint glsbreak ln_inv, model(trend) breaks(2) pmax(4)
tsurcoint glsbreak ln_inv, paper

* ---- cointegration ------------------------------------------------------
tsurcoint shin ln_consump ln_inc
tsurcoint shin ln_consump ln_inc ln_inv, lrv(spcqs)
tsurcoint shin ln_consump ln_inc, model(trend) lrv(bartlett) paper
tsurcoint cissanso ln_consump ln_inc
tsurcoint cissanso ln_consump ln_inc, model(e) lrv(bartlett) trim(0.15)
return list
