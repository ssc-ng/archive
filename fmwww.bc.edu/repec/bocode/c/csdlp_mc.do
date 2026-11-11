*! csdlp_mc.do -- Monte Carlo replication of David, Giacomini, Jiao & Wang
*! (2026), Section 5: RIMSE (Table 2) and uniform-band coverage (Table 3)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*
* DGP (eqs. 22-23):  Y_it = g(Z_{i,t-1}) X_t + 0.8 Y_{i,t-1} + e_it
*                    Z_it = mu_i + xi_it, mu_i ~ N(0,3), xi AR(1) rho=.8
*                    g(z) = 0.5 z + 0.3 z^2 - 0.25 z^3
* truth (eq. 24):    g_h(z) = 0.8^h g(z)
* LP:                Y_{i,t+h} = g_h(Z_{i,t-1}) X_t + gamma_h Y_{i,t-1} + u
* coverage is evaluated on a grid over the 5th-95th percentiles of Z.
*
* Usage:  do csdlp_mc.do            (defaults below; edit the locals)
* The paper uses 300 replications and B = 2000; the defaults here are
* smaller so that the file finishes in a few minutes.

version 15.0
clear all
set more off

local REPS   50          // Monte Carlo replications (paper: 300)
local N      100         // units
local T      120         // time periods after burn-in
local HLIST  0 4         // horizons
local SELECT aic         // aic | bic | gcv | fixed (then set NB)
local NB     4           // oracle J when SELECT==fixed
local B      1000        // Gaussian draws for the uniform band
local BURN   500

capture program drop _mc_dgp
program define _mc_dgp
    args N T burn
    clear
    local TT = `T' + `burn'
    tempfile xs
    qui {
        set obs `TT'
        gen t = _n
        gen double x = rnormal()
        save `xs'
        clear
        set obs `N'
        gen id = _n
        gen double mu = rnormal(0, sqrt(3))
        expand `TT'
        bysort id: gen t = _n
        merge m:1 t using `xs', nogen
        gen double v = rnormal()
        gen double e = rnormal()
        sort id t
        gen double xi = v if t==1
        by id: replace xi = 0.8*xi[_n-1] + sqrt(1-0.8^2)*v if t>1
        gen double z = mu + xi
        gen double y = e if t==1
        by id: replace y = (0.5*z[_n-1] + 0.3*z[_n-1]^2 - 0.25*z[_n-1]^3)*x ///
            + 0.8*y[_n-1] + e if t>1
        drop if t <= `burn'
        replace t = t - `burn'
        xtset id t
    }
end

tempname P
postfile `P' rep h J cover width rimse_s rimse_l using _csdlp_mc_results, replace
local selopt select(`SELECT')
if "`SELECT'" == "fixed" {
    local selopt nbasis(`NB')
}
forvalues r = 1/`REPS' {
    set seed `=20260000 + `r''
    _mc_dgp `N' `T' `BURN'
    qui csdlp y, shock(x) state(L.z) controls(L.y) horizons(`HLIST') ///
        noconstant `selopt' reps(`B') seed(`=1000 + `r'') range(5 95) ///
        grid(200) nograph notable
    tempname M S
    matrix `M' = e(irf)
    matrix `S' = e(summary)
    preserve
    qui {
        clear
        svmat double `M', names(col)
        gen double truth = 0.8^h*(0.5*z + 0.3*z^2 - 0.25*z^3)
        gen byte inu = truth >= u_lo & truth <= u_hi
        gen double w  = u_hi - u_lo
        gen double e2 = (g - truth)^2
        gen double l2 = (glin - truth)^2
        collapse (min) inu (mean) w e2 l2, by(h)
    }
    local k 0
    foreach h of local HLIST {
        local k = `k' + 1
        post `P' (`r') (`h') (`S'[`k',5]) (inu[`k']) (w[`k']) ///
            (sqrt(e2[`k'])) (sqrt(l2[`k']))
    }
    restore
    if mod(`r', 10) == 0 {
        di as txt "  replication `r' of `REPS' done"
    }
}
postclose `P'

use _csdlp_mc_results, clear
di _n as txt "{bf:csdlp Monte Carlo: N=`N', T=`T', `REPS' reps, selector `SELECT', nominal 95%}"
di as txt "{hline 66}"
di as txt "    h   mean J   Coverage   Width    RIMSE sieve   RIMSE linear"
di as txt "{hline 66}"
foreach h of local HLIST {
    qui summarize J if h==`h'
    local mj = r(mean)
    qui summarize cover if h==`h'
    local cv = r(mean)
    qui summarize width if h==`h'
    local wd = r(mean)
    qui summarize rimse_s if h==`h'
    local rs = r(mean)
    qui summarize rimse_l if h==`h'
    local rl = r(mean)
    di as res %5.0f `h' %9.2f `mj' %11.3f `cv' %9.3f `wd' %14.3f `rs' %14.3f `rl'
}
di as txt "{hline 66}"
di as txt "Paper, Table 3 (AIC, N=100): h=0 T=120 cov .83 width .08; h=4 T=120 cov .82 width 2.01"
di as txt "Paper, Table A1 (oracle J=4, N=100, T=120): h=0 cov .91; h=4 cov .90"
