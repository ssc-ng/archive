*! indsat_sim 1.0.0  12nov2026
*! Monte Carlo gauge and potency of indicator saturation (Castle, Doornik, Hendry & Pretis 2015 design)
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define indsat_sim, rclass
    version 14.0
    tempname _indsat_hold
    capture _estimates hold `_indsat_hold', restore nullok
    syntax , [ T(integer 100) REPs(integer 100) SIZes(numlist) BREAKdate(real 0.5) ///
        OUTlier(real 0) OUTdate(real 0.25) RHO(real 0) TPval(real 0.01) WINdow(integer 2) ///
        SATuration(string) SEED(string) * ]
    if ("`sizes'"=="") local sizes "0 1 2 3 4 5"
    if ("`saturation'"=="") local saturation "sis"
    if ("`seed'"!="") set seed `seed'
    local tau = max(2, round(`breakdate'*`t'))
    local tauo = max(1, round(`outdate'*`t'))
    local arop ""
    if (`rho'!=0) local arop "ar(1)"
    local K : word count `sizes'
    tempname R
    matrix `R' = J(`K', 8, .)
    di as text "Simulating `reps' replications for each of `K' break sizes (T = `t', `saturation', alpha = `tpval') ..."
    local i 0
    foreach lam of local sizes {
        local ++i
        local sumfalse 0
        local sumret 0
        local hit 0
        local sumest 0
        local sumsq 0
        local nest 0
        local ncand 0
        forvalues r = 1/`reps' {
            preserve
            quietly {
                clear
                set obs `t'
                gen tt = _n
                tsset tt
                gen double e = rnormal()
                gen double y = `lam'*(tt>=`tau') + `outlier'*(tt==`tauo') + e
                if (`rho'!=0) replace y = `rho'*L.y + `lam'*(tt>=`tau') + `outlier'*(tt==`tauo') + e if tt>1
                capture indsat y, `saturation' tpval(`tpval') `arop' `options' nodates notable noheader
            }
            if (_rc==0) {
                local ncand = e(ncand)
                local nr = e(nret)
                local sumret = `sumret' + `nr'
                local nfalse 0
                local found 0
                local shift 0
                if (`nr'>0) {
                    tempname B
                    matrix `B' = e(breaks)
                    forvalues j = 1/`nr' {
                        local o = `B'[`j',2]
                        local ty = `B'[`j',1]
                        local near = (abs(`o'-`tau') <= `window')
                        local nearo = (`outlier'!=0 & abs(`o'-`tauo') <= `window')
                        if (`lam'==0) {
                            if (!`nearo') local ++nfalse
                        }
                        else if (`near' & inlist(`ty',1,2)) {
                            local found 1
                            if (`ty'==2) local shift = `shift' + `B'[`j',4]*cond("`e(sisform)'"=="down",-1,1)
                        }
                        else if (!`nearo') local ++nfalse
                    }
                }
                local sumfalse = `sumfalse' + `nfalse'
                if (`lam'!=0) {
                    local hit = `hit' + `found'
                    local sumest = `sumest' + `shift'
                    local sumsq = `sumsq' + (`shift'-`lam')^2
                }
                local ++nest
            }
            restore
        }
        matrix `R'[`i',1] = `lam'
        matrix `R'[`i',2] = `nest'
        matrix `R'[`i',3] = `sumfalse'/(`nest'*max(1,`ncand'-cond(`lam'!=0,1,0)))
        matrix `R'[`i',4] = cond(`lam'!=0, `hit'/`nest', .)
        matrix `R'[`i',5] = `sumret'/`nest'
        matrix `R'[`i',6] = cond(`lam'!=0, `sumest'/`nest', .)
        matrix `R'[`i',7] = cond(`lam'!=0, `sumest'/`nest' - `lam', .)
        matrix `R'[`i',8] = cond(`lam'!=0, sqrt(`sumsq'/`nest'), .)
    }
    matrix colnames `R' = lambda reps gauge potency retained shift bias rmse
    di
    di as text "{bf:Monte Carlo: gauge and potency of `saturation' (T = `t', alpha = `tpval', reps = `reps')}"
    di as text "DGP: y_t = " cond(`rho'!=0,"`rho' y_{t-1} + ","") "lambda 1(t>=`tau')" cond(`outlier'!=0," + `outlier' 1(t=`tauo')","") " + e_t,  e_t ~ IN(0,1); detection window +/-`window'"
    di as text "{hline 76}"
    di as text %8s "lambda" %8s "reps" %10s "Gauge" %10s "Potency" %11s "Retained" %10s "Shift" %9s "Bias" %9s "RMSE"
    di as text "{hline 76}"
    forvalues i = 1/`K' {
        di as res %8.2f `R'[`i',1] %8.0f `R'[`i',2] %10.4f `R'[`i',3] %10.3f `R'[`i',4] %11.2f `R'[`i',5] %10.3f `R'[`i',6] %9.3f `R'[`i',7] %9.3f `R'[`i',8]
    }
    di as text "{hline 76}"
    di as text "Gauge = retention rate of irrelevant indicators; potency = share of replications detecting"
    di as text "the true shift within the window; shift = sum of retained step coefficients near the break."
    return matrix sim = `R'
end
