*! version 1.2.2  09nov2026
*! idxtp: turning-point inference and support-restricted U-shape test after estimation
program define idxtp, rclass
    version 14
    syntax varname(numeric) [, SQ(string) MIN(string) MAX(string) TRIM(real 0.05) ///
        Level(cilevel) noDISplay]

    if "`e(cmd)'" == "" {
        di as err "idxtp is a postestimation command; no estimation results found"
        exit 301
    }
    if `trim' < 0 | `trim' >= 0.5 {
        di as err "trim() must be in [0, 0.5)"
        exit 198
    }
    local x `varlist'
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)

    * locate the linear and squared terms
    local i1 = colnumb(`b', "`x'")
    if "`sq'" == "" {
        local sq "c.`x'#c.`x'"
    }
    local i2 = colnumb(`b', "`sq'")
    if missing(`i1') | missing(`i2') {
        di as err "coefficients for `x' and `sq' not found in e(b)"
        di as err "specify the squared term with sq(), e.g. sq(x2) or sq(c.x#c.x)"
        exit 111
    }
    tempname b1 b2 v11 v22 v12
    scalar `b1'  = `b'[1, `i1']
    scalar `b2'  = `b'[1, `i2']
    scalar `v11' = `V'[`i1', `i1']
    scalar `v22' = `V'[`i2', `i2']
    scalar `v12' = `V'[`i1', `i2']
    if `b2' == 0 {
        di as err "coefficient on squared term is zero; no turning point"
        exit 498
    }

    * support interval from the estimation sample
    tempvar touse
    qui gen byte `touse' = e(sample)
    qui summarize `x' if `touse', meanonly
    local xmin = r(min)
    local xmax = r(max)
    local nobs = r(N)
    if "`min'" == "" | "`max'" == "" {
        if `trim' > 0 {
            local plo = 100*`trim'
            local phi = 100*(1 - `trim')
            qui _pctile `x' if `touse', percentiles(`plo' `phi')
            local lo = r(r1)
            local hi = r(r2)
        }
        else {
            local lo = `xmin'
            local hi = `xmax'
        }
    }
    if "`min'" != "" local lo = `min'
    if "`max'" != "" local hi = `max'

    * degrees of freedom
    local df = e(df_r)
    if missing(`df') {
        local crit = invnormal(0.5 + `level'/200)
    }
    else {
        local crit = invttail(`df', (1 - `level'/100)/2)
    }

    _idxtp_core, b1(`=`b1'') b2(`=`b2'') v11(`=`v11'') v22(`=`v22'') v12(`=`v12'') ///
        lo(`lo') hi(`hi') crit(`crit') df(`df')
    foreach s in tp se_tp delta_lb delta_ub fieller_lb fieller_ub lm_t lm_p ///
        slope_lo slope_hi t_lo t_hi {
        local `s' = r(`s')
    }
    local ftype "`r(fieller_type)'"
    local shape "`r(shape)'"

    qui count if `touse' & `x' <= `tp'
    local tppct = r(N)/`nobs'
    * full-range Lind-Mehlum test for comparison
    _idxtp_core, b1(`=`b1'') b2(`=`b2'') v11(`=`v11'') v22(`=`v22'') v12(`=`v12'') ///
        lo(`xmin') hi(`xmax') crit(`crit') df(`df')
    local lmf_t = r(lm_t)
    local lmf_p = r(lm_p)

    local inside = (`tp' > `lo' & `tp' < `hi')
    local finside = ("`ftype'" == "bounded" & `fieller_lb' > `lo' & `fieller_ub' < `hi')

    if "`display'" == "" {
        di
        di as txt "Turning-point inference for " as res "`x'" as txt " (squared term: " as res "`sq'" as txt ")"
        di as txt "{hline 70}"
        di as txt "Estimated shape          : " as res cond("`shape'"=="invU","inverted U (concave)","U (convex)")
        di as txt "Turning point            : " as res %10.4f `tp' as txt "   (percentile of " as res "`x'" as txt ": " as res %5.1f 100*`tppct' as txt ")"
        di as txt "Delta-method SE          : " as res %10.4f `se_tp'
        di as txt "Delta-method `level'% CI     : [" as res %9.4f `delta_lb' as txt ", " as res %9.4f `delta_ub' as txt "]"
        if "`ftype'" == "bounded" {
            di as txt "Fieller `level'% CI          : [" as res %9.4f `fieller_lb' as txt ", " as res %9.4f `fieller_ub' as txt "]"
        }
        else if "`ftype'" == "union" {
            di as txt "Fieller `level'% CI          : (-inf, " as res %9.4f `fieller_lb' as txt "] U [" as res %9.4f `fieller_ub' as txt ", +inf)"
        }
        else {
            di as txt "Fieller `level'% CI          : " as res "unbounded (whole real line)"
        }
        di as txt "Supported interval S     : [" as res %9.4f `lo' as txt ", " as res %9.4f `hi' as txt "]" ///
            as txt cond(`trim'>0 & "`min'`max'"=="", "  (trim = " + string(`trim') + ")", "")
        di as txt "{hline 70}"
        di as txt "Lind-Mehlum test on S    : slope at lower = " as res %8.4f `slope_lo' as txt " (t = " as res %6.2f `t_lo' as txt ")"
        di as txt "                           slope at upper = " as res %8.4f `slope_hi' as txt " (t = " as res %6.2f `t_hi' as txt ")"
        di as txt "   H1: " cond("`shape'"=="invU","inverted U","U") " on S;  t = " as res %6.3f `lm_t' as txt ",  P>t = " as res %6.4f `lm_p'
        di as txt "Lind-Mehlum test, full range [min,max]: t = " as res %6.3f `lmf_t' as txt ",  P>t = " as res %6.4f `lmf_p'
        di as txt "{hline 70}"
        di as txt "Turning point inside S   : " as res cond(`inside', "yes", "no")
        di as txt "Fieller CI inside S      : " as res cond(`finside', "yes", "no")
    }

    return scalar tp = `tp'
    return scalar se_tp = `se_tp'
    return scalar tp_pct = `tppct'
    return scalar delta_lb = `delta_lb'
    return scalar delta_ub = `delta_ub'
    return scalar fieller_lb = `fieller_lb'
    return scalar fieller_ub = `fieller_ub'
    return scalar lm_t = `lm_t'
    return scalar lm_p = `lm_p'
    return scalar lmfull_t = `lmf_t'
    return scalar lmfull_p = `lmf_p'
    return scalar slope_lo = `slope_lo'
    return scalar slope_hi = `slope_hi'
    return scalar t_lo = `t_lo'
    return scalar t_hi = `t_hi'
    return scalar lo = `lo'
    return scalar hi = `hi'
    return scalar inside = `inside'
    return scalar fieller_inside = `finside'
    return local fieller_type "`ftype'"
    return local shape "`shape'"
end
