*! duvm_p 1.2.0  2026-09-29  Abdelkrim Araar
*! predict after duvm: the three Engel curves of a good
*!
*!     predict [type] newvar [if] [in], {share|quality|quantity} good(name) [atmeans|asobserved] [stdp]
*!     predict [type] stub* [if] [in], {share|quality|quantity} [atmeans|asobserved] [stdp]
*!
*!   share      the budget share                    w
*!   quality    the log of the unit value           ln v
*!   quantity   the log of the quantity             ln q = ln w + ln x - ln v
*!              (household quantity in the unit of the unit value; normalize
*!              sets it to 0 at the mean of ln x: a unit-free index)
*!   atmeans    (default) at the household's ln x, the other regressors at their
*!              weighted means and the prices at their common level: the Engel curve
*!   asobserved the household's own regressors and the effect of its cluster
*!   stdp       standard error of the Engel curve (atmeans), linearized
program define duvm_p
    version 14.2
    if "`e(cmd)'" != "duvm" error 301
    syntax anything(id="newvarname") [if] [in] [, SHare QUality QUAntity GOod(string) ///
        ATMeans ASObserved STDP NORMalize]

    * ---- what to compute ----
    local nc : word count `share' `quality' `quantity'
    if `nc' > 1 {
        di as err "specify only one of share, quality and quantity"
        exit 198
    }
    if `nc' == 0 {
        local share share
        di as txt "(option share assumed; Engel curve of the budget share)"
    }
    local curve `share'`quality'`quantity'
    if "`atmeans'" != "" & "`asobserved'" != "" {
        di as err "specify atmeans or asobserved, not both"
        exit 198
    }
    if "`stdp'" != "" & "`asobserved'" != "" {
        di as err "stdp is the standard error of the Engel curve: it goes with atmeans, not asobserved"
        exit 198
    }
    if "`normalize'" != "" & "`curve'" != "quantity" {
        di as err "normalize goes with quantity: it sets the log quantity to 0 at the mean of ln x"
        exit 198
    }
    if "`normalize'" != "" & "`asobserved'" != "" {
        di as err "normalize goes with the Engel curve (atmeans), not asobserved"
        exit 198
    }
    if "`e(expend)'" == "" {
        di as err "these duvm results predate the Engel curves; estimate the model again"
        exit 301
    }

    * ---- storage type and names ----
    gettoken typ rest : anything
    if inlist("`typ'", "byte", "int", "long", "float", "double") local anything `rest'
    else local typ "`c(type)'"
    local anything = trim("`anything'")
    local goods `e(goods)'
    local M : word count `goods'
    local idx ""
    local names ""
    if "`good'" != "" {
        local j : list posof "`good'" in goods
        if `j' == 0 {
            di as err "good(`good'): not one of the goods of the model (`goods')"
            exit 198
        }
        if `: word count `anything'' != 1 | strpos("`anything'", "*") {
            di as err "with good(), give one new variable name"
            exit 198
        }
        local idx `j'
        local names `anything'
    }
    else if substr("`anything'", -1, 1) == "*" & `: word count `anything'' == 1 {
        local stub = substr("`anything'", 1, strlen("`anything'") - 1)
        forvalues j = 1/`M' {
            local idx `idx' `j'
            local names `names' `stub'`: word `j' of `goods''
        }
    }
    else if `: word count `anything'' == `M' {
        forvalues j = 1/`M' {
            local idx `idx' `j'
        }
        local names `anything'
    }
    else {
        di as err "give good(name) with one new variable, stub* for one variable per good, or `M' names"
        exit 198
    }
    foreach v of local names {
        confirm new variable `v'
    }

    marksample touse, novarlist
    tempvar lnx
    qui gen double `lnx' = ln(`e(expend)') if `touse'

    local i 0
    foreach j of local idx {
        local ++i
        local v : word `i' of `names'
        local g : word `j' of `goods'
        if "`asobserved'" != "" {
            _duvm_p_obs `typ' `v' `touse' `lnx' `j' `curve'
        }
        else {
            local nov = cond("`stdp'" == "", "novar", "")
            _duvm_engel, good(`j') `nov'
            local L0 = r(L0)
            local wb = r(wbar)
            tempname th V
            matrix `th' = r(theta)
            local a0 = el(`th', 1, 1)
            local b0 = el(`th', 1, 2)
            local a1 = el(`th', 1, 3)
            local b1 = el(`th', 1, 4)
            if "`stdp'" != "" {
                if !r(hasV) {
                    di as err "stdp: the model was estimated with vce(none)"
                    exit 322
                }
                matrix `V' = r(V)
            }
            if "`curve'" == "share" {
                if "`stdp'" == "" qui gen `typ' `v' = `a0' + `b0' * `lnx' if `touse'
                else qui gen `typ' `v' = sqrt(el(`V',1,1) + 2*`lnx'*el(`V',1,2) + `lnx'^2*el(`V',2,2)) if `touse'
                local lab "budget share of `g'"
            }
            else if "`curve'" == "quality" {
                if "`stdp'" == "" qui gen `typ' `v' = `a1' + `b1' * `lnx' if `touse'
                else qui gen `typ' `v' = sqrt(el(`V',3,3) + 2*`lnx'*el(`V',3,4) + `lnx'^2*el(`V',4,4)) if `touse'
                local lab "log unit value of `g'"
            }
            else {
                * ln q = ln(a0 + b0 ln x) + ln x - (a1 + b1 ln x), where the share is positive
                tempvar sh
                qui gen double `sh' = `a0' + `b0' * `lnx' if `touse'
                if "`stdp'" == "" {
                    if "`normalize'" == "" qui gen `typ' `v' = ln(`sh') + `lnx' - (`a1' + `b1' * `lnx') if `touse' & `sh' > 0
                    else qui gen `typ' `v' = ln(`sh') - ln(`wb') + (1 - `b1') * (`lnx' - `L0') if `touse' & `sh' > 0
                }
                else {
                    * gradient over (a0, b0, a1, b1): (1/w, ln x/w, -1, -ln x)
                    qui gen `typ' `v' = . if `touse'
                    if "`normalize'" == "" _duvm_engel, qse(`v' `sh' `lnx' `touse') vmat(`V')
                    else _duvm_engel, qse(`v' `sh' `lnx' `touse') vmat(`V') ref(`L0') sh0(`wb')
                }
                qui count if `touse' & `lnx' < . & !(`sh' > 0)
                if r(N) di as txt "(`r(N)' missing values for `g': the predicted share is not positive there)"
                local lab "log quantity of `g'"
                if "`normalize'" != "" local lab "log quantity of `g', 0 at the mean of ln x"
            }
            local what = cond("`stdp'" == "", "Engel curve", "SE of the Engel curve")
            label variable `v' "`what', `lab' (at means)"
            capture drop `sh'
        }
    }
end

* the fitted value of the household: its own regressors and its cluster effect
program define _duvm_p_obs, sortpreserve
    args typ v touse lnx j curve
    local goods `e(goods)'
    local g : word `j' of `goods'
    tempvar wt es xb0 xb1 fe0 fe1 num den lnhh
    local wexp = trim(subinstr(`"`e(wexp)'"', "=", "", 1))
    if "`wexp'" == "" qui gen double `wt' = 1
    else              qui gen double `wt' = `wexp'
    qui gen byte `es' = e(sample)
    if "`e(hhsize)'" != "" qui gen double `lnhh' = ln(`e(hhsize)')
    tempvar shv uvv
    local mode "`e(nonbuyers)'"
    if "`mode'" == "" local mode "asis"
    _duvm_uv `g', touse(`es') wt(`wt') cluster(`e(clustvar)') mode(`mode') share(`shv') uv(`uvv')
    tempname B0 B1
    matrix `B0' = e(beta0)
    matrix `B1' = e(beta1)
    local xn : rownames `B0'
    qui gen double `xb0' = 0
    qui gen double `xb1' = 0
    local i 0
    foreach x of local xn {
        local ++i
        if "`x'" == "lnexp"         local term "ln(`e(expend)')"
        else if "`x'" == "lnhhsize" local term "`lnhh'"
        else if strpos("`x'", "==") local term "(`=substr("`x'", 1, strpos("`x'", "==") - 1)' == `=substr("`x'", strpos("`x'", "==") + 2, .)')"
        else local term "`x'"
        qui replace `xb0' = `xb0' + el(`B0', `i', `j') * `term'
        qui replace `xb1' = `xb1' + el(`B1', `i', `j') * `term'
    }
    * cluster effects: weighted cluster means of y - xb over the estimation sample
    local cl `e(clustvar)'
    qui gen double `num' = `wt' * (`shv' - `xb0') if `es'
    qui gen double `den' = `wt' if `es'
    qui egen double `fe0' = total(`num'), by(`cl')
    qui egen double `fe1' = total(`den'), by(`cl')
    qui replace `fe0' = cond(`fe1' > 0, `fe0' / `fe1', .)
    drop `num' `den' `fe1'
    qui gen double `num' = `wt' * (`uvv' - `xb1') if `es' & `uvv' < .
    qui gen double `den' = `wt' if `es' & `uvv' < .
    qui egen double `fe1' = total(`num'), by(`cl')
    tempvar d1
    qui egen double `d1' = total(`den'), by(`cl')
    qui replace `fe1' = cond(`d1' > 0, `fe1' / `d1', .)
    if "`curve'" == "share" {
        qui gen `typ' `v' = `fe0' + `xb0' if `touse'
        label variable `v' "Fitted budget share of `g' (as observed)"
    }
    else if "`curve'" == "quality" {
        qui gen `typ' `v' = `fe1' + `xb1' if `touse'
        label variable `v' "Fitted log unit value of `g' (as observed)"
    }
    else {
        qui gen `typ' `v' = ln(`fe0' + `xb0') + `lnx' - (`fe1' + `xb1') if `touse' & `fe0' + `xb0' > 0
        label variable `v' "Fitted log quantity of `g' (as observed)"
    }
    qui count if `touse' & `v' >= .
    if r(N) di as txt "(`r(N)' missing values for `g')"
end
