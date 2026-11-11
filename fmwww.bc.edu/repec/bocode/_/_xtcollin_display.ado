*! _xtcollin_display  version 1.0.0  21oct2026
capture program drop _xtcollin_display
program define _xtcollin_display
    version 14
    syntax, vif(name) ci(name) vdpm(name) ws(name) un(name) names(string) tname(string asis) ///
        how(integer) n(integer) ntr(integer) cnraw(real) cntr(real) panel(integer) theta(real) ///
        [UNITs VDP]

    local k = rowsof(`vif')
    di
    di as txt "Collinearity diagnostics" _col(56) "Obs = " as res %9.0f `n'
    di as txt "Transformation: " as res `tname'
    if `how' == 4 di as txt "theta = " as res %6.4f `theta'
    if `how' == 3 | `how' == 5 di as txt "Rows after transformation = " as res `ntr'
    di as txt "{hline 70}"
    if `how' > 0 {
        if `panel' di as txt "Variable" _col(26) "VIF raw" _col(38) "VIF transformed" _col(56) "Within share"
        else di as txt "Variable" _col(26) "VIF raw" _col(38) "VIF transformed"
    }
    else {
        if `panel' di as txt "Variable" _col(26) "VIF" _col(56) "Within share"
        else di as txt "Variable" _col(26) "VIF"
    }
    di as txt "{hline 70}"
    forvalues j = 1/`k' {
        local nm : word `j' of `names'
        local nm = abbrev("`nm'", 22)
        local line `"di as txt "`nm'" _col(22) as res %11.2f el(`vif', `j', 1)"'
        if `how' > 0 local line `"`line' _col(40) as res %11.2f el(`vif', `j', 2)"'
        if `panel' local line `"`line' _col(56) as res %9.3f el(`ws', `j', 1)"'
        `line'
    }
    di as txt "{hline 70}"
    di as txt "Mean VIF" _col(22) _c
    tempname m1 m2
    mata: _xtc_vm = st_matrix("`vif'")
    mata: st_numscalar("`m1'", mean(_xtc_vm[., 1])); st_numscalar("`m2'", mean(_xtc_vm[., 2]))
    mata: mata drop _xtc_vm
    if `how' > 0 di as res %11.2f scalar(`m1') _col(40) %11.2f scalar(`m2')
    else di as res %11.2f scalar(`m1')
    di as txt "Condition number" _col(22) as res %11.2f `cnraw' _c
    if `how' > 0 di as res _col(40) %11.2f `cntr'
    else di
    di as txt "{hline 70}"
    di as txt "Raw: pooled data with an intercept. Transformed: the design used by the estimator."
    if `panel' di as txt "Within share: share of the variable's variance that is within units."
    di as txt "Rules of thumb: VIF > 10 or condition number > 30 signal harmful collinearity."

    if "`vdp'" != "" {
        local nc = rowsof(`vdpm')
        local vn : colnames `vdpm'
        local nv : word count `vn'
        di
        di as txt "Variance-decomposition proportions (Belsley, Kuh and Welsch 1980), transformed design"
        di as txt "{hline 78}"
        di as txt "Cond. index" _c
        local c 14
        foreach v of local vn {
            di as txt _col(`c') %9s abbrev("`v'", 9) _c
            local c = `c' + 10
            if `c' > 70 {
                di
                local c 14
            }
        }
        di
        di as txt "{hline 78}"
        forvalues i = 1/`nc' {
            di as res %10.2f el(`ci', `i', 1) _c
            local c 14
            forvalues j = 1/`nv' {
                di as res _col(`c') %9.3f el(`vdpm', `i', `j') _c
                local c = `c' + 10
                if `c' > 70 {
                    di
                    local c 14
                }
            }
            di
        }
        di as txt "{hline 78}"
        di as txt "Harmful collinearity: a condition index > 30 with two or more proportions > 0.5 in its row."
    }

    if "`units'" != "" {
        tempname U
        matrix `U' = `un'
        local G = rowsof(`U')
        di
        di as txt "Unit-by-unit diagnostics (the design of mean-group and CCE unit regressions)"
        di as txt "{hline 70}"
        di as txt "Variable" _col(24) "Median VIF" _col(38) "Max VIF" _col(50) "Share VIF > 10"
        di as txt "{hline 70}"
        tempname US
        mata: _xtc_unitsum("`U'", `k', "`US'")
        forvalues j = 1/`k' {
            local nm : word `j' of `names'
            local nm = abbrev("`nm'", 22)
            di as txt "`nm'" _col(22) as res %11.2f el(`US', `j', 1) _col(34) %11.2f el(`US', `j', 2) _col(52) %9.3f el(`US', `j', 3)
        }
        di as txt "{hline 70}"
        di as txt "Condition number: median " as res %9.2f el(`US', `k' + 1, 1) as txt ", max " as res %9.2f el(`US', `k' + 1, 2) ///
            as txt ", share > 30 " as res %5.3f el(`US', `k' + 1, 3) as txt "   (units = " as res `G' as txt ")"
        di as txt "Use {bf:matrix list r(units)} for the unit-level values."
    }
end

