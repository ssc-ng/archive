*! indsat_cmp 1.0.0  12nov2026
*! original versus indicator-saturated estimates: table and coefficient graph
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program define indsat_cmp
    syntax , B0(name) V0(name) B1(name) V1(name) LIST(string) LAB0(string) [ NOGRaph TItle(string) NAME(string) ]
    if ("`name'"=="") local name "indsat_compare"
    local f0 : colfullnames `b0'
    local f1 : colfullnames `b1'
    local f0n = subinstr("`f0'","bn.",".",.)
    local f1n = subinstr("`f1'","bn.",".",.)
    tempname C
    local labs ""
    local k 0
    foreach c of local list {
        local cc = subinstr("`c'","bn.",".",.)
        local j0 : list posof "`cc'" in f0n
        local j1 : list posof "`cc'" in f1n
        if (`j0'==0 | `j1'==0) continue
        local ++k
        matrix `C' = nullmat(`C') \ (`b0'[1,`j0'], sqrt(`v0'[`j0',`j0']), `b1'[1,`j1'], sqrt(`v1'[`j1',`j1']))
        local lab "`cc'"
        if (substr("`lab'",1,4)=="ADJ:") local lab = "adjustment speed (" + substr("`lab'",5,.) + ")"
        if (substr("`lab'",1,3)=="LR:") local lab = "long run: " + substr("`lab'",4,.)
        if (substr("`lab'",1,3)=="SR:") local lab = "short run: " + substr("`lab'",4,.)
        local labs `"`labs' `"`lab'"'"'
    }
    if (`k'==0) exit
    di
    di as text "{bf:`title'}"
    di as text "{hline 82}"
    di as text %26s "Coefficient" %12s "Original" %10s "(s.e.)" %12s "Saturated" %10s "(s.e.)" %10s "Change %"
    di as text "{hline 82}"
    forvalues j = 1/`k' {
        local lab : word `j' of `labs'
        local bo = `C'[`j',1]
        local bs = `C'[`j',3]
        local ch = cond(`bo'!=0, 100*(`bs'-`bo')/abs(`bo'), .)
        di as text %26s abbrev("`lab'",26) as res %12.5g `bo' as text " (" as res %7.4g `C'[`j',2] as text ")" ///
           as res %12.5g `bs' as text " (" as res %7.4g `C'[`j',4] as text ")" as res %9.1f `ch'
    }
    di as text "{hline 82}"
    di as text "Large changes signal that outliers or breaks distorted the original estimates."
    if ("`nograph'"!="") exit
    preserve
    qui {
        clear
        svmat double `C', name(c)
        gen id = _n
        gen double y0 = id - 0.15
        gen double y1 = id + 0.15
        gen double lo0 = c1 - 1.96*c2
        gen double hi0 = c1 + 1.96*c2
        gen double lo1 = c3 - 1.96*c4
        gen double hi1 = c3 + 1.96*c4
    }
    local ylab ""
    forvalues j = 1/`k' {
        local lab : word `j' of `labs'
        local ylab `"`ylab' `j' `"`lab'"'"'
    }
    twoway (rcap lo0 hi0 y0, horizontal lcolor(gs9) lwidth(medthick)) ///
           (scatter y0 c1, msymbol(O) mcolor(gs6) msize(medium)) ///
           (rcap lo1 hi1 y1, horizontal lcolor(navy) lwidth(medthick)) ///
           (scatter y1 c3, msymbol(D) mcolor(cranberry) msize(medium)), ///
           ylabel(`ylab', angle(0) labsize(small) nogrid) yscale(reverse range(0.5 `=`k'+0.5')) ///
           xline(0, lcolor(gs12) lpattern(dash)) ytitle("") xtitle("Estimate with 95% confidence interval", size(small)) ///
           legend(order(2 "Original (`lab0')" 4 "Indicator-saturated") rows(1) position(6) size(small) region(lcolor(white))) ///
           title("`title'", size(medsmall)) graphregion(color(white)) plotregion(color(white)) name(`name', replace)
    restore
end

