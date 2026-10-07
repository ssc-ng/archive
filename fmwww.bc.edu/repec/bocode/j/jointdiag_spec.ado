*! jointdiag_spec 1.0.0  06oct2026
*! Generalised-spectral JOINT and MARGINAL tests for the conditional
*! mean and conditional variance, with a wild bootstrap.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCE
*   Escanciano (2008), J. Econometrics 143, 74-87
*     H0 (eq.2):  E[e1t|I_{t-1}] = 0  AND  E[e2t|I_{t-1}] = 0
*                 e1t = Y_t - f(I,theta) ,  e2t = e1t^2 - h^2(I,theta)
*     eq.(8)  : gamma_hat_{j,w}(x) = n_j^-1 sum_t e_hat_t w(Z_{t-j}, x)
*     eq.(9)  : J^2_{n,w} = sum_j  n_j /(j pi)^2  Int |gamma_j,w(x)|^2_M W(dx)
*               M = diag(m1, m2) :  (1,1) joint, (1,0) mean, (0,1) variance
*     the two weights of sec.4:
*       w = indicator  1(Y_{t-j} <= x)  with W = empirical cdf     -> J^2_{n,I}
*       w = exp(i x Y_{t-j}) with W = standard normal density      -> J^2_{n,C}
*         J^2_{n,C} = sum_j (n_j (j pi)^2)^-1 sum_t sum_s
*                     [m1 s1^-2 e1t e1s + m2 s2^-2 e2t e2s]
*                     * exp(-0.5 (Y_{t-j} - Y_{s-j})^2)
*     sec.3   : the asymptotic null distribution depends on the DGP, so a
*               WILD BOOTSTRAP is required.  Steps 1-4, with V_t the
*               two-point Bernoulli variable of eq.(11).
*               Step 4 RE-ESTIMATES theta on the bootstrap data; the
*               consistency of the procedure rests on Assumption A6 of
*               Escanciano (2007, CAEPR WP 2007-009), which requires the
*               bootstrap estimator to satisfy the same Bahadur expansion.
*               We therefore refit by default; -norefit- is faster but only
*               approximate and is flagged in the output.
*
*  WHY IT MATTERS (the paper's own simulations, Tables 2-3):
*     marginal variance tests have essentially NO power when the
*     conditional mean is misspecified (GARCH-M: 2.7-4.0 %, AR(2)-CH(1):
*     1.0-3.5 %).  Only the joint test keeps size and power.

program define jointdiag_spec, rclass
    version 14.0

    syntax [anything] [if] [in] [,   ///
        Weight(string)                ///
        REPS(integer 299)             ///
        SEED(integer 0)               ///
        NOREFIT                       ///
        Level(cilevel)                ///
        NOTABle                       ///
        GRaph                         ///
        NAME(string)                  ///
    ]

    if ("`weight'" == "") local weight "exp"
    local weight = lower("`weight'")
    if (!inlist("`weight'","exp","ind","both")) {
        di as err "weight() must be exp, ind or both"
        exit 198
    }
    if (`reps' < 49) {
        di as err "reps() should be at least 49"
        exit 198
    }
    if (`seed' > 0) set seed `seed'

    if ("`anything'" != "") {
        di as err "jointdiag spec is a postestimation command: fit the model first"
        exit 198
    }
    if ("`e(cmd)'" == "") {
        di as err "fit a model first (regress or arch)"
        exit 301
    }
    local ecmd "`e(cmd)'"
    if (!inlist("`ecmd'","regress","arch")) {
        di as err "jointdiag spec supports -regress- and -arch- models; found -`ecmd'-"
        exit 322
    }
    local cmdline `"`e(cmdline)'"'
    local dv "`e(depvar)'"

    tempvar touse
    qui gen byte `touse' = e(sample)

    *---------------------------------------------- observed statistic
    tempvar f0 h0 e1 e2
    qui predict double `f0' if `touse', xb
    if ("`ecmd'" == "arch") {
        qui predict double `h0' if `touse', variance
    }
    else {
        qui predict double `h0' if `touse'
        qui replace `h0' = e(rmse)^2 if `touse'
    }
    qui gen double `e1' = `dv' - `f0'      if `touse'
    qui gen double `e2' = `e1'^2 - `h0'    if `touse'

    qui count if `touse'
    local n = r(N)

    tempname OBS
    mata: _jd_spec_stat("`e1'", "`e2'", "`dv'", "`touse'", "`weight'", "`OBS'")
    * OBS rows: 1=exp joint 2=exp mean 3=exp var 4=ind joint 5=ind mean 6=ind var

    *---------------------------------------------- wild bootstrap
    local dorefit = ("`norefit'" == "")
    tempname BOOT
    matrix `BOOT' = J(`reps', 6, .)

    tempvar v ys e1s e2s f1 h1
    qui gen double `v'   = .
    qui gen double `ys'  = .
    qui gen double `e1s' = .
    qui gen double `e2s' = .

    tempname bhold
    capture _estimates hold `bhold', copy

    local b1 = 0.5*(1+sqrt(5))
    local pB = (sqrt(5)+1)/(2*sqrt(5))

    _dots 0, title("Wild bootstrap (`reps' replications)") reps(`reps')
    forvalues b = 1/`reps' {
        qui replace `v' = cond(runiform() < `pB', 0.5*(1-sqrt(5)), 0.5*(1+sqrt(5))) if `touse'
        qui replace `e1s' = `e1' * `v' if `touse'
        qui replace `e2s' = `e2' * `v' if `touse'
        qui replace `ys'  = `f0' + `e1s' if `touse'

        local ok 1
        if (`dorefit') {
            capture {
                tempvar fb hb
                if ("`ecmd'" == "regress") {
                    local rhs : colnames e(b)
                    local rhs : subinstr local rhs "_cons" "", word
                    qui regress `ys' `rhs' if `touse'
                    qui predict double `fb' if `touse', xb
                    qui gen double `hb' = e(rmse)^2 if `touse'
                }
                else {
                    local nc : subinstr local cmdline "`dv'" "`ys'", word
                    qui `nc'
                    qui predict double `fb' if `touse', xb
                    qui predict double `hb' if `touse', variance
                }
            }
            if (_rc) local ok 0
        }
        if (`ok' & `dorefit') {
            qui replace `e1s' = `ys' - `fb' if `touse'
            qui replace `e2s' = `e1s'^2 - `hb' if `touse'
            capture drop `fb'
            capture drop `hb'
        }

        tempname Bq
        capture mata: _jd_spec_stat("`e1s'", "`e2s'", "`dv'", "`touse'", ///
                                    "`weight'", "`Bq'")
        if (!_rc) {
            forvalues c = 1/6 {
                matrix `BOOT'[`b',`c'] = `Bq'[`c',1]
            }
        }
        _dots `b' 0
    }
    di ""
    capture _estimates unhold `bhold'

    *---------------------------------------------- p-values
    tempname PV
    mata: _jd_spec_pv("`OBS'", "`BOOT'", "`PV'")

    local lab1 "J2(n,C)  joint"
    local lab2 "J2(n,C)  mean"
    local lab3 "J2(n,C)  variance"
    local lab4 "J2(n,I)  joint"
    local lab5 "J2(n,I)  mean"
    local lab6 "J2(n,I)  variance"

    *---------------------------------------------- display
    if ("`notable'" == "") {
        _jd_head "Generalised-spectral joint and marginal specification tests"  ///
                 "Escanciano (2008, J. Econometrics 143)    model: `ecmd'   (n = `n')" ///
                 "H0: BOTH the conditional mean and the conditional variance are correct"

        di as txt %-34s "Test" " {c |}" %14s "statistic" %14s "boot. p-value"
        di as txt "{hline 35}{c +}{hline 42}"
        forvalues i = 1/6 {
            local st = `OBS'[`i',1]
            local pv = `PV'[`i',1]
            if (`st' < .) {
                _jd_stars `pv'
                di as txt %-34s "`lab`i''" " {c |}" as res %14.5f `st' ///
                   as res %14.4f `pv' "  " as res "`r(stars)'"
            }
        }
        di as txt "{hline 35}{c BT}{hline 42}"
        di as txt "  Bootstrap: wild, `reps' replications, two-point weights (eq. 11)."
        if (`dorefit') {
            di as txt "  Step 4 RE-ESTIMATES the model in every replication"
            di as txt "  (Escanciano 2007, Assumption A6)."
        }
        else {
            di as err "  -norefit- used: theta is held fixed in the bootstrap."
            di as err "  This ignores the estimation effect and can OVER-REJECT."
        }
        di as txt ""
        di as txt "  How to read it: if the {bf:variance} marginal is insignificant while"
        di as txt "  the {bf:mean} marginal rejects, do NOT conclude the variance is fine -"
        di as txt "  Escanciano's Tables 2-3 show the variance marginal loses almost all"
        di as txt "  power once the mean is misspecified.  Fix the mean, then re-test."
        _jd_foot ""
    }

    *---------------------------------------------- returns
    local nm1 "cj"
    local nm2 "cm"
    local nm3 "cv"
    local nm4 "ij"
    local nm5 "im"
    local nm6 "iv"
    forvalues i = 1/6 {
        return scalar stat_`nm`i''  = `OBS'[`i',1]
        return scalar p_`nm`i''     = `PV'[`i',1]
    }
    return scalar N    = `n'
    return scalar reps = `reps'
    return local  cmd  "jointdiag spec"
    return matrix boot = `BOOT'
end



