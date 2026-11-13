*! indsat_ardl 1.0.0  12nov2026
*! ARDL / error-correction model with indicator saturation and the PSS bounds test
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*  Step 1: ARDL lag orders (given, or selected by ardl without indicators)
*  Step 2: indsat on the ARDL regression in levels, ARDL terms kept fixed, indicators selected
*  Step 3: ARDL/EC model re-estimated by -ardl- (Kripfganz & Schneider) with the retained
*          indicators as unrestricted exogenous deterministic terms; Pesaran-Shin-Smith bounds
*          test (estat ectest, Kripfganz-Schneider 2020 response-surface critical values)

program define indsat_ardl, eclass
    version 14.0
    syntax varlist(min=2 ts numeric) [if] [in] [, LAGs(numlist integer >=0) MAXLags(integer 4) ///
        AIC BIC EC EC1 noBOUNDs PREfix(string) TRendvar(varname) EXOG(varlist ts numeric) noCONStant Level(cilevel) NOGRaph NOCOMPare * ]
    capture which ardl
    if (_rc) {
        di as err "indsat ardl requires the {bf:ardl} package (Kripfganz & Schneider): {stata ssc install ardl}"
        exit 199
    }
    qui tsset
    gettoken y xs : varlist
    local nx : word count `xs'
    if ("`prefix'"=="") local prefix "_I"
    local ic "bic"
    if ("`aic'"!="") local ic "aic"
    marksample touse
    * ---------------- step 1: lag orders
    if ("`lags'"=="") {
        di as text "{bf:Step 1}: ARDL lag selection by `=upper("`ic'")' (maxlags `maxlags'), no indicators"
        qui ardl `y' `xs' if `touse', maxlags(`maxlags') `ic' `constant'
        matrix _isl = e(lags)
        local lags ""
        forvalues j = 1/`=colsof(_isl)' {
            local lags "`lags' `=_isl[1,`j']'"
        }
        matrix drop _isl
    }
    local nl : word count `lags'
    if (`nl'!=`nx'+1) {
        di as err "lags() needs `=`nx'+1' integers: p for `y' then q for each regressor"
        exit 198
    }
    local p : word 1 of `lags'
    di as text "ARDL(" trim("`lags'") ")"
    local rhs ""
    if (`p'>0) local rhs "L(1/`p').`y'"
    local j 1
    foreach x of local xs {
        local ++j
        local q : word `j' of `lags'
        local rhs "`rhs' L(0/`q').`x'"
    }
    if ("`trendvar'"!="") local rhs "`rhs' `trendvar'"
    if ("`exog'"!="") local rhs "`rhs' `exog'"
    local ecopt ""
    if ("`ec'"!="") local ecopt "ec"
    if ("`ec1'"!="") local ecopt "ec1"
    if ("`ecopt'"=="" & "`bounds'"=="") local ecopt "ec"
    local tr ""
    if ("`trendvar'"!="") local tr "trendvar(`trendvar')"
    local exo0 ""
    if ("`exog'"!="") local exo0 "exog(`exog')"
    tempname b0 V0
    local havebase 0
    if ("`nocompare'"=="" & "`ecopt'"!="") {
        capture quietly ardl `y' `xs' if `touse', lags(`lags') `exo0' `ecopt' `constant' `tr'
        if (_rc==0) {
            matrix `b0' = e(b)
            matrix `V0' = e(V)
            local havebase 1
        }
    }
    * ---------------- step 2: saturation
    di as text "{bf:Step 2}: indicator saturation of the ARDL regression (ARDL terms fixed)"
    capture drop `prefix'*
    indsat `y' `rhs' if `touse', `options' `constant' generate(`prefix') level(`level')
    if ("`nograph'"=="") {
        local lagc = subinstr(trim("`lags'")," ",",",.)
        indsat_estat plot, name(indsat_dash) title("Indicator saturation of the ARDL(`lagc') regression")
    }
    local ret "`e(retained)'"
    local nret = e(nret)
    local indv ""
    foreach r of local ret {
        local nm = substr("`prefix'`r'",1,32)
        local indv "`indv' `nm'"
    }
    * ---------------- step 3: ARDL / EC with retained indicators
    di
    di as text "{bf:Step 3}: ARDL" cond("`ec'`ec1'"!=""," error-correction","") " model with `nret' retained indicator(s) as unrestricted deterministic terms"
    local exo ""
    if ("`indv'`exog'"!="") local exo "exog(`exog' `indv')"
    ardl `y' `xs' if `touse', lags(`lags') `exo' `ecopt' `constant' `tr' level(`level')
    if (`havebase') {
        tempname b1 V1
        matrix `b1' = e(b)
        matrix `V1' = e(V)
        local f1 : colfullnames `b1'
        local cl ""
        foreach c of local f1 {
            if (substr("`c'",1,4)=="ADJ:" | substr("`c'",1,3)=="LR:") local cl "`cl' `c'"
        }
        indsat_cmp, b0(`b0') v0(`V0') b1(`b1') v1(`V1') list(`cl') lab0("ARDL without indicators") ///
            `nograph' title("Long-run and adjustment coefficients: ARDL without vs with indicators")
    }
    if ("`bounds'"=="") {
        di
        di as text "{bf:Pesaran-Shin-Smith bounds test} with indicator-saturated deterministics"
        estat ectest
    }
    ereturn local indsat_retained "`ret'"
    ereturn local indsat_indicators "`indv'"
    ereturn scalar indsat_nret = `nret'
    ereturn local indsat_lags "`lags'"
    di as text "note: retained indicators were saved as variables `prefix'*; they enter the EC model unrestricted."
end
