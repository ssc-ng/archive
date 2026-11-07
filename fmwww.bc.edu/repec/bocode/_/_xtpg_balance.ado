*! _xtpg_balance 1.0.0  06nov2026
*! balanced / gap-free / common-span check for xtpanelgarch (modifies caller's touse)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
program define _xtpg_balance, rclass
    version 14.0
    args touse ivar tvar tdelta cmdname
    tempvar cnt tmin tmax
    qui bysort `ivar' (`tvar'): egen long `cnt' = total(`touse')
    qui by `ivar': egen double `tmin' = min(cond(`touse', `tvar', .))
    qui by `ivar': egen double `tmax' = max(cond(`touse', `tvar', .))
    qui replace `touse' = 0 if `cnt' == 0
    qui count if `touse'
    if r(N) == 0 error 2000
    qui sum `cnt' if `touse', meanonly
    if r(min) != r(max) {
        di as err "panel is unbalanced on the estimation sample (T_i from " r(min) " to " r(max) ")"
        di as err "{bf:`cmdname'} needs a balanced panel without gaps; restrict with if/in"
        exit 459
    }
    local T = r(min)
    qui sum `tmin' if `touse', meanonly
    local t0 = r(min)
    if r(min) != r(max) {
        di as err "panels do not share the same time span on the estimation sample"
        exit 459
    }
    qui sum `tmax' if `touse', meanonly
    if r(min) != r(max) | (r(min) - `t0') / `tdelta' + 1 != `T' {
        di as err "panels have gaps or different end dates on the estimation sample"
        exit 459
    }
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    sort `ivar' `tvar'
    return scalar N = `N'
    return scalar T = `T'
    return scalar t0 = `t0'
    return local units "`units'"
end
