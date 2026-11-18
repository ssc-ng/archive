*! Displays the conditional pretrend test reported by cdid_pretest and cdid_pretest_load.
program define _cdid_pretest_display
    version 19.5
    syntax, STATS(name) MODE(string) METHOD(string) STATUS(string) [REASON(string asis) CLUSTERVARS(string)]
    local N = `stats'[1,1]
    local M = `stats'[1,2]
    local K = `stats'[1,3]
    local C = `stats'[1,4]
    local B = `stats'[1,5]
    local alpha = `stats'[1,6]
    display
    display as text "Conditional pretrend test (Cramer-von Mises)" _col(49) "Mode" _col(70) "= " as result %8s "`mode'"
    display as text _col(49) "Method" _col(70) "= " as result %8s "`method'"
    if !missing(`N') display as text _col(49) "Number of units" _col(70) "= " as result %8.0fc `N'
    if !missing(`K') display as text _col(49) "Pre-treatment cells" _col(70) "= " as result %8.0fc `K'
    if !missing(`M') display as text _col(49) "Grid points" _col(70) "= " as result %8.0fc `M'
    if "`status'"!="available" {
        local why = strtrim(`"`reason'"')
        if `"`why'"'=="" local why "`status'"
        display as text "Test not computed: " as result `"`why'"'
        exit
    }
    display as text "{hline 44}"
    display as text "CvM statistic" _col(30) "= " as result %12.0g `stats'[1,7]
    local lev = strofreal(100*(1-`alpha'), "%9.0g")
    display as text "Critical value (`lev'%)" _col(30) "= " as result %12.0g `stats'[1,8]
    display as text "p-value" _col(30) "= " as result %12.4f `stats'[1,9]
    display as text "{hline 44}"
    local unit = cond("`clustervars'"!="", "clusters (`clustervars')", "units")
    display as text "Multiplier bootstrap: " as result `B' as text " draws over " as result `C' as text " `unit'."
end
