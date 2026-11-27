*! _xtqqr_savelong 1.0.0  25nov2026
*! Saves a quantile-on-quantile surface (xtqqr / xtqqkrls) in long format
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
* save the surface in long format
program define _xtqqr_savelong
    version 14.0
    syntax anything, saving(string)
    tokenize `anything'
    local B `1'
    local SE `2'
    local T `3'
    local P `4'
    local R2 `5'
    local TAU `6'
    local TH `7'
    _prefix_saving `saving'
    local fn `"`s(filename)'"'
    local rep `"`s(replace)'"'
    preserve
    qui {
        clear
        local M = rowsof(`B')
        local L = colsof(`B')
        set obs `=`M'*`L''
        gen double tau = .
        gen double theta = .
        gen double coef = .
        gen double se = .
        gen double t = .
        gen double p = .
        gen double r2 = .
        local k = 0
        forvalues j = 1/`L' {
            forvalues i = 1/`M' {
                local ++k
                replace tau   = `TAU'[`i', 1] in `k'
                replace theta = `TH'[`j', 1] in `k'
                replace coef  = `B'[`i', `j'] in `k'
                replace se    = `SE'[`i', `j'] in `k'
                replace t     = `T'[`i', `j'] in `k'
                replace p     = `P'[`i', `j'] in `k'
                replace r2    = `R2'[`i', `j'] in `k'
            }
        }
        label var tau   "quantile of the dependent variable"
        label var theta "quantile of the QQ regressor"
        label var coef  "QQ slope b1(tau,theta)"
        save `"`fn'"', `rep'
    }
    restore
    di as txt "(QQ surface saved to " `"`fn'"' ")"
end
