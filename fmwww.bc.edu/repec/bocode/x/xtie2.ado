*! xtie2 2.3.0 29sep2026
program define xtie2, eclass
    version 17
    syntax varlist(min=3 numeric) [if] [in] [, ROBust LEVEL(real 95) PAIR(string)]
    if `level' <= 0 | `level' >= 100 {
        di as err "level() must be between 0 and 100"
        exit 198
    }
    marksample touse
    gettoken y xs : varlist
    local nx : word count `xs'
    if "`pair'" != "" {
        local np : word count `pair'
        if `np' != 2 {
            di as err "pair() requires exactly two distinct explanatory variables"
            exit 198
        }
        local x1 : word 1 of `pair'
        local x2 : word 2 of `pair'
        local found1 : list x1 in xs
        local found2 : list x2 in xs
        if "`x1'" == "`x2'" | !`found1' | !`found2' {
            di as err "pair() must name two distinct variables from the explanatory varlist"
            exit 198
        }
        local others : list xs - pair
        local xs "`x1' `x2' `others'"
    }
    else {
        local x1 : word 1 of `xs'
        local x2 : word 2 of `xs'
    }
    local primary "c.`x1'#c.`x2'"

    // Preserve the original generated-variable names, but never overwrite data.
    foreach name in me_`x1' me_`x2' regime_`x2' {
        confirm new variable `name'
    }

    local terms
    forvalues i = 1/`=`nx'-1' {
        local xi : word `i' of `xs'
        forvalues j = `=`i'+1'/`nx' {
            local xj : word `j' of `xs'
            local terms `terms' c.`xi'#c.`xj'
        }
    }
    if "`robust'" != "" local vce "vce(robust)"
    quietly xtreg `y' `xs' `terms' if `touse', fe `vce'
    tempvar sample
    quietly generate byte `sample' = e(sample)

    tempname b V J1 J2 K a1 a2 bb va1 va2 vb ca1 ca2 crit
    matrix `b' = e(b)
    matrix `V' = e(V)
    local p = colnumb(`b', "`primary'")
    local q1 = colnumb(`b', "`x1'")
    local q2 = colnumb(`b', "`x2'")
    if missing(`p',`q1',`q2') {
        di as err "focal terms could not be identified in the fitted model"
        exit 498
    }
    matrix `J1' = J(1,colsof(`b'),0)
    matrix `J2' = J(1,colsof(`b'),0)
    matrix `K' = J(1,colsof(`b'),0)
    matrix `J1'[1,`q1'] = 1
    matrix `J2'[1,`q2'] = 1
    matrix `K'[1,`p'] = 1

    if `nx' > 2 {
    forvalues k = 3/`nx' {
        local xk : word `k' of `xs'
        quietly summarize `xk' if `sample', meanonly
        local mk = r(mean)
        local t1 "c.`x1'#c.`xk'"
        local t2 "c.`x2'#c.`xk'"
        local i1 = colnumb(`b',"`t1'")
        local i2 = colnumb(`b',"`t2'")
        if missing(`i1',`i2') {
            di as err "interaction with `xk' could not be identified"
            exit 498
        }
        matrix `J1'[1,`i1'] = `mk'
        matrix `J2'[1,`i2'] = `mk'
    }
    }
    tempname z
    matrix `z' = `J1'*`b''
    scalar `a1' = `z'[1,1]
    matrix `z' = `J2'*`b''
    scalar `a2' = `z'[1,1]
    matrix `z' = `K'*`b''
    scalar `bb' = `z'[1,1]
    matrix `z' = `J1'*`V'*`J1''
    scalar `va1' = `z'[1,1]
    matrix `z' = `J2'*`V'*`J2''
    scalar `va2' = `z'[1,1]
    matrix `z' = `K'*`V'*`K''
    scalar `vb' = `z'[1,1]
    matrix `z' = `J1'*`V'*`K''
    scalar `ca1' = `z'[1,1]
    matrix `z' = `J2'*`V'*`K''
    scalar `ca2' = `z'[1,1]

    if `vb' <= 0 {
        di as err "primary interaction has zero or invalid estimated variance"
        exit 498
    }
    tempname seint tint pint
    scalar `seint' = sqrt(`vb')
    scalar `tint' = `bb'/`seint'
    scalar `pint' = 2*ttail(e(df_r),abs(`tint'))
    scalar `crit' = invttail(e(df_r),(100-`level')/200)
    foreach x in `x1' `x2' {
        quietly summarize `x' if `sample', detail
        local min_`x' = r(min)
        local mean_`x' = r(mean)
        local median_`x' = r(p50)
        local max_`x' = r(max)
    }

    di as txt "Interactive panel fixed-effects model: xtie2"
    estimates replay
    di as txt "Primary interaction: `x1' x `x2'"
    di as txt "Coefficient = " as res %10.5f `bb' as txt "  SE = " as res %10.5f `seint' as txt "  p = " as res %7.4f `pint'
    if `nx' > 2 di as txt "Other moderators fixed at estimation-sample means."

    forvalues h = 1/2 {
        if `h' == 1 {
            local focal `x1'
            local moderator `x2'
            local aa `a1'
            local vv `va1'
            local cc `ca1'
            local Jfocus `J1'
        }
        else {
            local focal `x2'
            local moderator `x1'
            local aa `a2'
            local vv `va2'
            local cc `ca2'
            local Jfocus `J2'
        }
        di as txt "Marginal effect of `focal' across `moderator':"
        if abs(`bb') > 1e-12 {
            tempname zero
            scalar `zero' = -`aa'/`bb'
            di as txt "  Zero crossing: " as res %10.5f `zero'
            if `zero' >= `min_`moderator'' & `zero' <= `max_`moderator'' di as txt "  Within estimation-sample moderator range"
            else di as txt "  Outside estimation-sample moderator range"
            if `h' == 1 {
                ereturn scalar critical_x2 = `zero'
                ereturn scalar zero_cross_x2 = `zero'
            }
            else {
                ereturn scalar critical_x1 = `zero'
                ereturn scalar zero_cross_x1 = `zero'
            }
        }
        else di as txt "  Zero crossing undefined: interaction coefficient is approximately zero."

        tempname A B C D lo hi tmp
        scalar `A' = `bb'^2 - `crit'^2*`vb'
        scalar `B' = 2*(`aa'*`bb' - `crit'^2*`cc')
        scalar `C' = `aa'^2 - `crit'^2*`vv'
        scalar `D' = `B'^2 - 4*`A'*`C'
        if abs(`A') > 1e-12 & `D' >= 0 {
            scalar `lo' = (-`B'-sqrt(`D'))/(2*`A')
            scalar `hi' = (-`B'+sqrt(`D'))/(2*`A')
            if `lo' > `hi' {
                scalar `tmp' = `lo'
                scalar `lo' = `hi'
                scalar `hi' = `tmp'
            }
            di as txt "  Johnson-Neyman boundaries (`level'%): " as res %10.5f `lo' "  " %10.5f `hi'
            if `A' < 0 di as txt "  Significant between boundaries (subject to observed range)."
            else di as txt "  Significant below lower and above upper boundary (subject to observed range)."
            if `h' == 1 {
                ereturn scalar JN_x2_low = `lo'
                ereturn scalar JN_x2_high = `hi'
            }
            else {
                ereturn scalar JN_x1_low = `lo'
                ereturn scalar JN_x1_high = `hi'
            }
        }
        else if `D' < 0 & `A' > 0 di as txt "  Significant throughout moderator range."
        else if `D' < 0 & `A' < 0 di as txt "  No significant moderator region."
        else di as txt "  JN boundary is degenerate or not uniquely determined."

        foreach label in min mean median max {
            local v = ``label'_`moderator''
            tempname me variance se pval Jz vz
            scalar `me' = `aa' + `bb'*`v'
            matrix `Jz' = `Jfocus' + (`v')*`K'
            matrix `vz' = `Jz'*`V'*`Jz''
            scalar `variance' = `vz'[1,1]
            if !missing(`variance') & `variance' >= 0 {
                scalar `se' = sqrt(`variance')
                if `se' > 0 scalar `pval' = 2*ttail(e(df_r),abs(`me'/`se'))
                else scalar `pval' = .
                di as txt "  At `label' `moderator' (" %9.3f `v' "): ME=" as res %10.5f `me' as txt " SE=" as res %10.5f `se' as txt " p=" as res %7.4f `pval'
            }
            else di as err "  At `label' `moderator': variance could not be computed (value=" %12.6g `variance' ")."
        }
    }

    // Dataset outputs are confined to the actual estimation sample.
    quietly generate double me_`x1' = `a1' + `bb'*`x2' if `sample'
    quietly generate double me_`x2' = `a2' + `bb'*`x1' if `sample'
    if abs(`bb') > 1e-12 {
        quietly generate byte regime_`x2' = (`x2' > e(critical_x2)) if `sample'
        tempname regime_label
        label define `regime_label' 0 "Low regime" 1 "High regime"
        label values regime_`x2' `regime_label'
    }
    ereturn local cmd "xtie2"
    ereturn local depvar "`y'"
    ereturn local indepvars "`xs'"
    ereturn local primary_interaction "`x1' x `x2'"
    ereturn scalar beta_inter = `bb'
    ereturn scalar se_inter = `seint'
    ereturn scalar t_inter = `tint'
    ereturn scalar p_inter = `pint'
    ereturn scalar level = `level'
end
