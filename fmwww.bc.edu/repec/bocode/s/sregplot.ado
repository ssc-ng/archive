*! sregplot 1.0.0 24sep2026 -- native coefficient and confidence interval plot
program define sregplot
    version 14.2
    if "`e(cmd)'" != "sreg" error 301
    syntax [, Level(cilevel) TREATmentlabels(string asis) ///
        TITLE(string) XTItle(string) YTItle(string) ///
        CICOlor(string) MSYmbol(string) MSIze(string) ///
        MCOlor(string) MFCOlor(string) MLWidth(string) ///
        LABColor(string) LABSize(string) BGCOLor(string) ///
        NOGRID NOZEROline NAME(string) SAVing(string asis)]
    local n = e(N_treatments)
    if `"`treatmentlabels'"' != "" {
        local nl : word count `treatmentlabels'
        if `nl' != `n' {
            di as error "treatmentlabels() must contain one quoted label per treatment."
            exit 198
        }
    }
    if `"`title'"' == "" local title "Estimated ATEs with Confidence Intervals"
    if "`cicolor'" == "" local cicolor teal
    if "`msymbol'" == "" local msymbol D
    if "`msize'" == "" local msize medium
    if "`mcolor'" == "" local mcolor black
    if "`mfcolor'" == "" local mfcolor white
    if "`mlwidth'" == "" local mlwidth medthin
    if "`labcolor'" == "" local labcolor black
    if "`labsize'" == "" local labsize small
    if "`bgcolor'" == "" local bgcolor white
    local zero
    if "`nozeroline'" == "" local zero xline(0, lpattern(dash) lcolor(gs8))
    local grid grid
    if "`nogrid'" != "" local grid nogrid
    local named
    if "`name'" != "" local named name(`name')
    local saved
    if `"`saving'"' != "" local saved saving(`saving')
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    preserve
    quietly clear
    quietly set obs `n'
    quietly gen double effect = .
    quietly gen double se = .
    quietly gen double arm = _n
    local ylabel
    forvalues j=1/`n' {
        quietly replace effect = `b'[1,`j'] in `j'
        quietly replace se = sqrt(`V'[`j',`j']) in `j'
        local label "Treatment `j'"
        if `"`treatmentlabels'"' != "" local label : word `j' of `treatmentlabels'
        local ylabel `"`ylabel' `j' "`label'""'
    }
    quietly gen double lower = effect-invnormal(1-(100-`level')/200)*se
    quietly gen double upper = effect+invnormal(1-(100-`level')/200)*se
    quietly gen str40 annotation = string(effect,"%6.2f")+" ("+string(se,"%6.2f")+")"
    capture noisily twoway (rcap lower upper arm, horizontal lcolor(`cicolor')) ///
        (scatter arm effect, msymbol(`msymbol') msize(`msize') mlcolor(`mcolor') ///
        mfcolor(`mfcolor') mlwidth(`mlwidth') mlabel(annotation) mlabposition(12) ///
        mlabcolor(`labcolor') mlabsize(`labsize')), ///
        ylabel(`ylabel', angle(0) `grid' glcolor(gs14)) ///
        yscale(reverse range(.5 `=`n'+.5')) xlabel(, `grid' glcolor(gs14)) ///
        title(`"`title'"') xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ///
        graphregion(color(`bgcolor')) plotregion(color(`bgcolor')) ///
        legend(off) `zero' `named' `saved'
    local rc = _rc
    restore
    if `rc' exit `rc'
end
