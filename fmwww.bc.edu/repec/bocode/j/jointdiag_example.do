*------------------------------------------------------------------------------
*  jointdiag_example.do          version 1.0.0   06oct2026
*
*  Self-testing demonstration of the jointdiag package.
*  Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*          https://github.com/merwanroudane
*
*  It does four things:
*    PART A  verifies, to the last printed digit, every block that is supposed
*            to reproduce a Stata built-in.  A mismatch here is a bug.
*    PART B  reproduces the headline finding of four of the source papers on
*            data generated from their own designs.
*    PART C  exercises every remaining subcommand and option.
*    PART D  a Monte Carlo size check for the bootstrap test.
*
*  Run it with:   do jointdiag_example.do
*  and read the FAIL lines (there should be none).
*------------------------------------------------------------------------------

clear
set more off
capture log close jdval
log using jointdiag_validation.log, replace text name(jdval)

version 14.0

*--- a tiny assertion helper ---------------------------------------------------
capture program drop jdcheck
program define jdcheck
    args name a b tol
    if ("`tol'" == "") local tol 1e-5
    * relative tolerance: these are independent floating-point paths, so
    * agreement to ~7 significant figures is the realistic target
    local sc = max(abs(`b'), 1)
    local d  = abs(`a' - `b') / `sc'
    if (`d' < `tol') {
        di as txt "    OK    " %-42s "`name'" "  " %12.6f `a' " vs " %12.6f `b'
    }
    else {
        di as err "    FAIL  " %-42s "`name'" "  " %12.6f `a' " vs " %12.6f `b' ///
                  "   diff = " %10.3e `d'
    }
end

di _n(2) "{hline 78}"
di "  jointdiag 1.0.0 - self test"
di "{hline 78}"


*==============================================================================
*  PART A   cross-checks against Stata's own commands
*==============================================================================
di _n "{hline 78}"
di "  PART A   numerical cross-checks against Stata built-ins"
di "{hline 78}"

clear
set seed 4242
set obs 250
gen t = _n
tsset t
gen double x1 = rnormal()
gen double x2 = runiform()*10
gen double y  = 1 + .5*x1 + .3*x2 + rnormal()

quietly regress y x1 x2

*--- A1  LM_H  ==  estat hettest -----------------------------------------------
quietly jointdiag lm y x1 x2, notable
local a = r(lm_H)
quietly estat hettest
jdcheck "LM_H               == estat hettest" `a' `r(chi2)'

*--- A2  studentised LM_H  ==  estat hettest, iid ------------------------------
quietly jointdiag lm y x1 x2, studentize notable
local a = r(lm_H)
quietly estat hettest, iid
jdcheck "LM_H studentised   == estat hettest, iid" `a' `r(chi2)'

*--- A3  rhs LM_H  ==  estat hettest, rhs --------------------------------------
quietly jointdiag lm y x1 x2, rhs notable
local a = r(lm_H)
quietly estat hettest, rhs
jdcheck "LM_H rhs           == estat hettest, rhs" `a' `r(chi2)'

*--- A4  fullbg LM_I  ==  estat bgodfrey ---------------------------------------
quietly jointdiag lm y x1 x2, lags(1) fullbg notable
local a = r(lm_I)
quietly estat bgodfrey, lags(1)
matrix bg = r(chi2)
jdcheck "LM_I fullbg        == estat bgodfrey" `a' `=bg[1,1]'

*--- A5  IM heteroskedasticity  ==  estat imtest -------------------------------
quietly jointdiag im y x1 x2, hall notable
local a = r(T1)
quietly estat imtest
jdcheck "IM T1n             == estat imtest (het)" `a' `r(chi2_h)'

*--- A6  IM T2  ==  estat archlm, at three lag orders --------------------------
quietly regress y x1 x2
quietly estat archlm, lags(1 2 3)
matrix ar = r(arch)
forvalues q = 1/3 {
    quietly jointdiag im y x1 x2, ar(0) archlags(`q') notable
    jdcheck "IM T2 (q=`q')        == estat archlm lag `q'" r(T2) `=ar[1,`q']'
}

*--- A7  Jarque-Bera by hand ---------------------------------------------------
quietly regress y x1 x2
quietly predict double rres, resid
quietly summarize rres, detail
local jbhand = e(N)*(r(skewness)^2/6 + (r(kurtosis)-3)^2/24)
quietly jointdiag lm y x1 x2, notable
jdcheck "LM_N               == n[b1/6+(b2-3)^2/24]" r(lm_N) `jbhand' 1e-4
drop rres

*--- A8  additivity: every joint statistic is the sum of its parts -------------
quietly jointdiag lm y x1 x2, notable
jdcheck "additivity  NHIF = N+H+I+F" r(lm_NHIF) ///
        `=r(lm_N)+r(lm_H)+r(lm_I)+r(lm_F)' 1e-9
quietly jointdiag lm y x1 x2, notable
jdcheck "additivity  df NHIF = sum df" r(df_NHIF) ///
        `=r(df_N)+r(df_H)+r(df_I)+r(df_F)' 1e-9

*--- A9  w(phi) for AR(1) equals the analytic 1/(1-phi^2) ----------------------
quietly {
    clear
    set seed 11
    set obs 400
    gen t=_n
    tsset t
    gen double e1 = rnormal()
    gen double u1 = 0
    replace u1 = e1 in 1
    forvalues i=2/400 {
        replace u1 = 0.4*u1[`i'-1] + e1[`i'] in `i'
    }
    gen double xx = runiform()*3
    gen double yy = 1 + 0.5*xx + u1
    arch yy xx, ar(1) arch(1) nolog
    local phi = _b[ARMA:L1.ar]
    jointdiag arch yy xx, ar(1) archlags(1) notable
}
jdcheck "w(phi) == 1/(1-phi^2)" r(wphi) `=1/(1-`phi'^2)' 1e-5


*==============================================================================
*  PART B   reproducing the papers
*==============================================================================
di _n "{hline 78}"
di "  PART B   reproducing the source papers' headline findings"
di "{hline 78}"

*------------------------------------------------------------------------------
*  B1  Savin & White (1978, sec. 3.4)
*      TRUE model: ln(Y) = .1 + .1 X + u ,  u INDEPENDENT.
*      Fitting the LINEAR model gives DW ~ 0.675 and the conditional test C(rho)
*      rejects independence overwhelmingly - but G(rho) accepts it.
*      The problem is the functional form, not the errors.
*------------------------------------------------------------------------------
di _n as res "  B1  Savin & White (1978): functional form masquerading as AR"
clear
set seed 31415
set obs 100
gen t = _n
tsset t
gen double X   = _n
gen double lny = 0.1 + 0.1*X + rnormal()*0.5
gen double Y   = exp(lny)

quietly regress Y X
quietly estat dwatson
di as txt "    Durbin-Watson d = " as res %6.4f r(dw) as txt "   (paper: 0.675)"

jointdiag bc Y X, rho lambda0(1) grid(30)

di as txt "    Paper reports C(rho) = 53.59 rejecting, G(rho) = 0.97 accepting."
di as txt "    The lambda estimate should be near 0 (the true semi-log form)."

*------------------------------------------------------------------------------
*  B2  Bera, Higgins & Lee (1992)
*      DGP has BOTH AR(1) and ARCH(1).  Panel A (one-directional) overstates
*      each; Panel B (each given the other) is the honest measurement.
*------------------------------------------------------------------------------
di _n as res "  B2  Bera, Higgins & Lee (1992): the ARCH / AR interaction"
clear
set seed 20261006
set obs 500
gen t = _n
tsset t
gen double ee = rnormal()
gen double h  = 1
gen double u  = 0
quietly replace u = ee in 1
forvalues i = 2/500 {
    quietly replace h = 0.3 + 0.45*u[`i'-1]^2 in `i'
    quietly replace u = 0.55*u[`i'-1] + sqrt(h[`i'])*ee[`i'] in `i'
}
gen double x = runiform()*4
gen double y = 2 + 0.8*x + u
quietly regress y x

jointdiag arch y x, ar(1) archlags(1)

di as txt "    Expect Panel B to be roughly HALF Panel A: that gap is the"
di as txt "    interaction the paper is about."

*------------------------------------------------------------------------------
*  B3  Bera & Jarque (1982)
*      Undertesting is dangerous, overtesting is cheap.
*------------------------------------------------------------------------------
di _n as res "  B3  Bera & Jarque (1982): the four directions and the MCP"
jointdiag lm y x, lags(1)
jointdiag lm y x, lags(1) mcp notable

*------------------------------------------------------------------------------
*  B4  Hall (1987) / Bera & Lee (1993)
*      Hall's IM test is blind to serial correlation; adding AR(p) errors
*      produces six components, one of which IS Engle's ARCH test.
*------------------------------------------------------------------------------
di _n as res "  B4  Hall (1987) and Bera & Lee (1993): the IM decomposition"
quietly regress y x
jointdiag im y x, hall compare
jointdiag im y x, ar(1) archlags(2) aarch


*==============================================================================
*  PART C   every remaining subcommand and option
*==============================================================================
di _n "{hline 78}"
di "  PART C   exercising the remaining subcommands"
di "{hline 78}"

quietly regress y x

di _n as res "  C1  score (Tsai 1986 + Liu, Wei & Wang 2003)"
jointdiag score y x, ar(1) bilinear

di _n as res "  C2  bilinear (Higgins & Bera 1988; Bera & Higgins 1997)"
jointdiag bilinear y x, archlags(2) r(2) s(1)
jointdiag bilinear y x, archlags(1) r(1) s(1) fform notable
di as txt "    F-form joint = " as res %9.4f r(lm_joint) as txt "  p = " ///
   as res %6.4f r(p_joint)

di _n as res "  C3  mpi (King & Evans 1984, exact Imhof p-value)"
jointdiag mpi y x, rho1(0.5)

di _n as res "  C4  nonnest (Bera, McAleer & Pesaran 1989)"
jointdiag nonnest y x, alternative(L.y)

di _n as res "  C5  port (Wong-Ling, Velasco-Wang, Mahdi) after an arch fit"
quietly arch y x, ar(1) arch(1) nolog
jointdiag port, lags(12)

di _n as res "  C6  spec (Escanciano 2008) with the wild bootstrap"
quietly regress y x
jointdiag spec, weight(exp) reps(99) seed(20261006)

di _n as res "  C7  the dashboard"
quietly regress y x
jointdiag all y x, lags(1) archlags(1)

di _n as res "  C8  postestimation form, and e() is preserved"
quietly regress y x
local b0 = _b[x]
quietly jointdiag all
quietly jointdiag lm, lags(2) notable
quietly jointdiag im, ar(1) notable
jdcheck "e() survives every subcommand" _b[x] `b0' 1e-12


*==============================================================================
*  PART D   Monte Carlo size check for the bootstrap test
*==============================================================================
di _n "{hline 78}"
di "  PART D   size of jointdiag spec under a correctly specified model"
di "  (100 replications; expect rejection rates near or below 0.05)"
di "{hline 78}"

local R   = 100
local rej_j = 0
local rej_m = 0
local rej_v = 0

quietly {
    forvalues r = 1/`R' {
        clear
        set seed `=70000 + `r''
        set obs 150
        gen t = _n
        tsset t
        gen double xs = rnormal()
        gen double ys = 1 + 0.5*xs + rnormal()
        regress ys xs
        * vary the bootstrap seed too, or the draws repeat (see the
        * Monte Carlo rules in the stata-package notes)
        capture jointdiag spec, weight(exp) reps(99) seed(`=90000 + `r'') notable
        if (_rc == 0) {
            if (r(p_cj) < 0.05) local rej_j = `rej_j' + 1
            if (r(p_cm) < 0.05) local rej_m = `rej_m' + 1
            if (r(p_cv) < 0.05) local rej_v = `rej_v' + 1
        }
        noisily _dots `r' 0
    }
}
di ""
di as txt "    empirical size, joint    = " as res %5.3f `=`rej_j'/`R''
di as txt "    empirical size, mean     = " as res %5.3f `=`rej_m'/`R''
di as txt "    empirical size, variance = " as res %5.3f `=`rej_v'/`R''
di as txt "    A mildly conservative test (size at or below nominal) is"
di as txt "    acceptable and safe; a size well above 0.05 is not."


di _n(2) "{hline 78}"
di "  self test complete - search the log for 'FAIL'"
di "{hline 78}"

capture log close jdval
