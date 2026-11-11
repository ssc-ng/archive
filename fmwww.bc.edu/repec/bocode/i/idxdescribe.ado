*! version 1.2.2  09nov2026
*! idxdescribe: characterize index covariates before nonlinear or interactive modelling
program define idxdescribe, rclass
    version 14
    syntax varlist(numeric) [if] [in] [, BOUNDS(numlist min=2 max=2) SE(varlist numeric) ///
        SCALE(string) TRIM(real 0.05) ]

    marksample touse, novarlist
    if `trim' <= 0 | `trim' >= 0.25 {
        di as err "trim() must be in (0, 0.25)"
        exit 198
    }
    local nv : word count `varlist'
    if "`se'" != "" {
        local ns : word count `se'
        if `ns' != `nv' {
            di as err "se() must contain one variable for each index variable"
            exit 198
        }
    }
    if "`scale'" != "" {
        if !inlist("`scale'", "interval", "ordinal", "ratio") {
            di as err "scale() must be interval, ordinal, or ratio"
            exit 198
        }
    }
    if "`bounds'" != "" {
        local blo : word 1 of `bounds'
        local bhi : word 2 of `bounds'
        if `bhi' <= `blo' {
            di as err "bounds() must be specified as lower upper"
            exit 198
        }
    }
    local ivar ""
    capture quietly xtset
    if !_rc local ivar "`r(panelvar)'"

    tempname R
    matrix `R' = J(`nv', 16, .)
    local plo = 100*`trim'
    local phi = 100*(1 - `trim')
    local row = 0
    foreach v of local varlist {
        local ++row
        tempvar ok tag w m
        quietly gen byte `ok' = `touse' & !missing(`v')
        quietly summarize `v' if `ok', detail
        local n = r(N)
        local mean = r(mean)
        local sd = r(sd)
        local mn = r(min)
        local mx = r(max)
        local sk = r(skewness)
        quietly _pctile `v' if `ok', percentiles(`plo' 50 `phi')
        local q1 = r(r1)
        local q2 = r(r2)
        local q3 = r(r3)
        quietly egen byte `tag' = tag(`v') if `ok'
        quietly count if `tag' == 1
        local nd = r(N)
        quietly count if `ok' & `v' != round(`v')
        local nonint = r(N)
        local signed = (`mn' < 0 & `mx' > 0)
        local floor = .
        local ceil = .
        local cover = .
        if "`bounds'" != "" {
            local rg = `bhi' - `blo'
            quietly count if `ok' & `v' <= `blo' + 0.05*`rg'
            local floor = r(N)/`n'
            quietly count if `ok' & `v' >= `bhi' - 0.05*`rg'
            local ceil = r(N)/`n'
            local cover = (`mx' - `mn')/`rg'
        }
        local sdw = .
        local sdb = .
        local wsh = .
        if "`ivar'" != "" {
            quietly egen double `m' = mean(`v') if `ok', by(`ivar')
            quietly gen double `w' = `v' - `m' if `ok'
            quietly summarize `w' if `ok'
            local sdw = r(sd)
            tempvar pt
            quietly egen byte `pt' = tag(`ivar') if `ok'
            quietly summarize `m' if `pt' == 1
            local sdb = r(sd)
            local wsh = (`sdw')^2/(`sd')^2
        }
        local rel = .
        local relw = .
        if "`se'" != "" {
            local sv : word `row' of `se'
            tempvar s2
            quietly gen double `s2' = (`sv')^2 if `ok'
            quietly summarize `s2' if `ok', meanonly
            local s2u = r(mean)
            local rel = (`sd')^2/((`sd')^2 + `s2u')
            if "`ivar'" != "" local relw = (`sdw')^2/((`sdw')^2 + `s2u')
        }
        * scale classification
        if "`scale'" != "" local sc`row' "`scale' (declared)"
        else if `nonint' == 0 & `nd' <= 20 local sc`row' "ordinal? (few integer values)"
        else if `nonint' == 0 & `mn' >= 0 & `nd'/`n' > 0.5 local sc`row' "rank/score? (integer-valued)"
        else local sc`row' "interval (assumed)"

        matrix `R'[`row', 1] = `n'
        matrix `R'[`row', 2] = `mean'
        matrix `R'[`row', 3] = `sd'
        matrix `R'[`row', 4] = `mn'
        matrix `R'[`row', 5] = `mx'
        matrix `R'[`row', 6] = `sk'
        matrix `R'[`row', 7] = `q1'
        matrix `R'[`row', 8] = `q2'
        matrix `R'[`row', 9] = `q3'
        matrix `R'[`row', 10] = `nd'
        matrix `R'[`row', 11] = `floor'
        matrix `R'[`row', 12] = `ceil'
        matrix `R'[`row', 13] = `sdw'
        matrix `R'[`row', 14] = `sdb'
        matrix `R'[`row', 15] = `wsh'
        matrix `R'[`row', 16] = `relw'

        * ------------------------------------------------ display
        di
        di as txt "Index covariate: " as res "`v'" as txt "   (N = " as res `n' as txt ")"
        di as txt "{hline 72}"
        di as txt "  mean " as res %9.4f `mean' as txt "   sd " as res %9.4f `sd' as txt "   skewness " as res %7.3f `sk'
        di as txt "  min  " as res %9.4f `mn' as txt "   max " as res %9.4f `mx' as txt "   distinct values " as res `nd'
        di as txt "  p" `plo' " = " as res %9.4f `q1' as txt "   median = " as res %9.4f `q2' as txt "   p" `phi' " = " as res %9.4f `q3'
        di as txt "  sign: " as res cond(`signed', "signed (takes negative and positive values)", ///
            cond(`mn' >= 0, "non-negative", "non-positive"))
        di as txt "  measurement scale: " as res "`sc`row''"
        if "`bounds'" != "" {
            di as txt "  bounds [" as res `blo' as txt ", " as res `bhi' as txt "]: share within 5% of floor " ///
                as res %5.3f `floor' as txt ", of ceiling " as res %5.3f `ceil' as txt "; observed range covers " ///
                as res %5.1f 100*`cover' as txt "% of bounds"
        }
        if "`ivar'" != "" {
            di as txt "  panel (" as res "`ivar'" as txt "): sd within " as res %8.4f `sdw' as txt ", sd between " ///
                as res %8.4f `sdb' as txt ", within share of variance " as res %5.3f `wsh'
        }
        if "`se'" != "" {
            di as txt "  reliability (classical error, mean se^2 from " as res "`sv'" as txt "): total " ///
                as res %5.3f `rel' as txt cond("`ivar'"!="", ", within " + string(`relw', "%5.3f"), "")
            if "`ivar'" != "" {
                di as txt "    implied attenuation of a within quadratic coefficient (normal approx.): " ///
                    as res %5.3f (`relw')^2
            }
        }
        di as txt "  Diagnostics:"
        local nflag = 0
        if `signed' {
            local ++nflag
            di as txt "   - zero is an interior point; check whether it is substantively meaningful before using"
            di as txt "     origin-dependent terms (signed squares x*|x|, logs, fractional powers, products"
            di as txt "     without constitutive terms)."
        }
        if strpos("`sc`row''", "ordinal") | strpos("`sc`row''", "rank") {
            local ++nflag
            di as txt "   - ordinal or rank scale: curvature (convex/concave) is not invariant to monotone"
            di as txt "     recoding; restrict claims to sign changes and report turning points as quantiles."
        }
        if "`bounds'" != "" {
            if `floor' > 0.2 | `ceil' > 0.2 {
                local ++nflag
                di as txt "   - more than 20% of observations sit near a bound; curvature near that bound is"
                di as txt "     driven by a mass point. Prefer splines with interior knots or separate"
                di as txt "     treatment of the boundary mass."
            }
        }
        if "`ivar'" != "" {
            if `wsh' < 0.2 {
                local ++nflag
                di as txt "   - within-unit variation is small (share < 0.20); fixed-effects nonlinear terms are"
                di as txt "     identified from little variation and are sensitive to measurement error."
            }
        }
        if abs(`sk') > 1 {
            local ++nflag
            di as txt "   - strong skewness: one tail is thinly populated; evaluate turning points and"
            di as txt "     conditional effects only inside the trimmed support [p`plo', p`phi']."
        }
        if `nflag' == 0 di as txt "   - no specific flags"
        di as txt "{hline 72}"
    }
    matrix rownames `R' = `varlist'
    matrix colnames `R' = N mean sd min max skew p_lo p50 p_hi distinct floor ceiling sd_within sd_between within_share rel_within
    return matrix table = `R'
end
