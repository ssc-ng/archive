*! version 1.2.2  09nov2026
*! _idxtp_core: turning-point, Fieller, and Lind-Mehlum computations used by idxtp and idxspec
program define _idxtp_core, rclass
    version 14
    syntax , b1(real) b2(real) v11(real) v22(real) v12(real) lo(real) hi(real) ///
        crit(real) [df(string)]
    local tp = -(`b1')/(2*`b2')
    local g1 = -1/(2*`b2')
    local g2 = `b1'/(2*(`b2')^2)
    local se = sqrt((`g1')^2*`v11' + (`g2')^2*`v22' + 2*`g1'*`g2'*`v12')
    return scalar tp = `tp'
    return scalar se_tp = `se'
    return scalar delta_lb = `tp' - `crit'*`se'
    return scalar delta_ub = `tp' + `crit'*`se'
    * Fieller interval: {theta : (b1 + 2 b2 theta)^2 <= c^2 Var(b1 + 2 b2 theta)}
    local c2 = (`crit')^2
    local A = 4*((`b2')^2 - `c2'*`v22')
    local B = 4*(`b1'*`b2' - `c2'*`v12')
    local C = (`b1')^2 - `c2'*`v11'
    local disc = (`B')^2 - 4*`A'*`C'
    if `disc' >= 0 & `A' != 0 {
        local r1 = (-(`B') - sqrt(`disc'))/(2*`A')
        local r2 = (-(`B') + sqrt(`disc'))/(2*`A')
        return scalar fieller_lb = min(`r1', `r2')
        return scalar fieller_ub = max(`r1', `r2')
        return local fieller_type = cond(`A' > 0, "bounded", "union")
    }
    else {
        return scalar fieller_lb = .
        return scalar fieller_ub = .
        return local fieller_type "unbounded"
    }
    * Lind-Mehlum (Sasabuchi) test on [lo, hi]
    local sl = `b1' + 2*`b2'*`lo'
    local sh = `b1' + 2*`b2'*`hi'
    local sel = sqrt(`v11' + 4*(`lo')^2*`v22' + 4*`lo'*`v12')
    local seh = sqrt(`v11' + 4*(`hi')^2*`v22' + 4*`hi'*`v12')
    local tl = `sl'/`sel'
    local th = `sh'/`seh'
    if `b2' < 0 {
        local t = min(`tl', -(`th'))
        return local shape "invU"
    }
    else {
        local t = min(-(`tl'), `th')
        return local shape "U"
    }
    if "`df'" == "" | "`df'" == "." {
        local p = 1 - normal(`t')
    }
    else {
        local p = ttail(`df', `t')
    }
    return scalar lm_t = `t'
    return scalar lm_p = `p'
    return scalar slope_lo = `sl'
    return scalar slope_hi = `sh'
    return scalar t_lo = `tl'
    return scalar t_hi = `th'
end
