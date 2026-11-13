*! indsat 1.0.0  12nov2026
*! Indicator saturation (IIS / SIS / TIS / MIS / BIS / UIS) by general-to-specific selection
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> paper map (full map in: help indsat_methods)
*  [1] GUM with a saturating set of indicators D (T x T)          Pretis et al. (2016) eq.(2)-(3)
*  [2] indicator sets: IIS impulses, SIS steps, TIS broken trends,  Hendry et al. (2008); Castle et al. (2015);
*      MIS steps x regressor, BIS designed shapes, UIS user set     Kitov-Tabor (2014); Pretis et al. (2016) Tab.1
*  [3] block split of each set (ratio threshold, max block size)   Santos-Hendry-Johansen (2008) split-half,
*                                                                   generalised to J blocks (gets::isat)
*  [4] multi-path backward elimination within each block, keeping   Hoover-Perez (1999); Doornik (2009);
*      the regressors fixed; terminal chosen by information crit.   Sucarrat (2021) getsFun
*  [5] union of block survivors -> GETS -> union over sets -> GETS  gets::isat (Pretis, Reade, Sucarrat 2018)
*  [6] algorithm(split): JN split-half IIS 1-step Huber-skip        Johansen & Nielsen (2009) Sec.2.2.2
*      algorithm(split)+sis: split-half SIS on forward differences   Nielsen & Qian (2025) Alg.2.2
*      algorithm(mstep): m-step robustified least squares          Johansen & Nielsen (2016) Alg.1
*  [7] consistency/efficiency corrections (varcorr)                 Johansen & Nielsen (2009, 2016)
*  [8] outlier proportion/count tests, distortion test              Jiao-Pretis; Jiao-Pretis-Schwarz

* =====================================================================
* central command: one entry point for the whole library
* =====================================================================
program define indsat
    version 14.0
    gettoken sub rest : 0, parse(" ,")
    local s = lower(`"`sub'"')
    * post-estimation mode: no variables, only options, after regress / newey / ardl
    if (substr(trim(`"`0'"'),1,1)==",") {
        if inlist("`e(cmd)'","regress","newey","ardl") {
            indsat_post `0'
            exit
        }
        if ("`e(cmd)'"=="indsat") {
            indsat_display `0'
            exit
        }
        di as err "no variables specified; to saturate an estimated model, run {bf:regress}, {bf:newey} or {bf:ardl} first"
        exit 198
    }
    if (`"`0'"'=="") {
        if ("`e(cmd)'"=="indsat") {
            indsat_display
            exit
        }
        indsat_menu
        exit
    }
    if inlist("`s'","est","estimate","fit") {
        indsat_fit `rest'
    }
    else if ("`s'"=="ardl") {
        indsat_ardl `rest'
    }
    else if ("`s'"=="loop") {
        indsat_loop `rest'
    }
    else if ("`s'"=="gauge") {
        indsat_gauge `rest'
    }
    else if inlist("`s'","sim","simulate") {
        indsat_sim `rest'
    }
    else if inlist("`s'","dates","breaks","path","plot","graph","test","outlier","distort") | ///
            inlist("`s'","biascorr","bias","forecast","diag") {
        if ("`e(cmd)'"!="indsat") {
            di as err "indsat `s' is a postestimation command: estimate a model with {bf:indsat} first"
            exit 301
        }
        indsat_estat `0'
    }
    else if ("`s'"=="types") {
        help indsat_types
    }
    else if ("`s'"=="methods") {
        help indsat_methods
    }
    else if ("`s'"=="postestimation") {
        help indsat_postestimation
    }
    else if ("`s'"=="menu" | "`s'"=="about") {
        indsat_menu
    }
    else {
        indsat_fit `0'
    }
end

* =====================================================================
* post-estimation mode: saturate the model already in memory
* =====================================================================
program define indsat_post, eclass
    syntax , [ NOCOMPare NOGRaph * ]
    local graph "`nograph'"
    local cmd "`e(cmd)'"
    if ("`e(wtype)'"!="") {
        di as err "indsat: weighted estimation is not supported"
        exit 198
    }
    tempvar es
    qui gen byte `es' = e(sample)
    if ("`cmd'"=="ardl") {
        tempname L
        matrix `L' = e(lags)
        local vn : colnames `L'
        gettoken y xs : vn
        local lags ""
        forvalues j = 1/`=colsof(`L')' {
            local lags "`lags' `=`L'[1,`j']'"
        }
        local exog ""
        local cl `"`e(cmdline)'"'
        if regexm(`"`cl'"', "exog\(([^)]*)\)") local exog = regexs(1)
        local ecf ""
        if ("`e(model)'"=="ec") local ecf "ec"
        local nc "noconstant"
        tempname bA
        matrix `bA' = e(b)
        local cnA : colnames `bA'
        if (strpos(" `cnA' "," _cons ")) local nc ""
        di
        di as text "{bf:indsat} {hline 2} saturating the ARDL(" trim("`lags'") ") model in memory: `y' on" "`xs'"
        local exo ""
        if ("`exog'"!="") local exo "exog(`exog')"
        indsat_ardl `y' `xs' if `es', lags(`lags') ec `nc' `exo' `nograph' `nocompare' `options'
        exit
    }
    * regress / newey: rebuild the regression from e(b)
    local y "`e(depvar)'"
    tempname b0 V0
    matrix `b0' = e(b)
    matrix `V0' = e(V)
    local cn : colnames `b0'
    local x ""
    local cons 0
    foreach c of local cn {
        if ("`c'"=="_cons") {
            local cons 1
            continue
        }
        if regexm("`c'","^[0-9]*b\.|^[0-9]*o\.|^o\.|\.o\.") continue
        local x "`x' `c'"
    }
    local nc ""
    if (!`cons') local nc "noconstant"
    local orig "`cmd'"
    if ("`cmd'"=="newey") local orig "newey (lag `e(lag)')"
    di
    local xs2 "`x'"
    if ("`xs2'"=="") local xs2 " (constant only)"
    di as text "{bf:indsat} {hline 2} saturating the `orig' model in memory: `y' on" "`xs2'"
    indsat_fit `y' `x' if `es', `nc' `options'
    ereturn local postof "`cmd'"
    if ("`graph'"=="") {
        indsat_estat plot, name(indsat_dash)
    }
    if ("`nocompare'"=="") {
        tempname b1 V1
        matrix `b1' = e(b)
        matrix `V1' = e(V)
        local cl "`x'"
        if ("`cl'"=="") local cl "_cons"
        indsat_cmp, b0(`b0') v0(`V0') b1(`b1') v1(`V1') list(`cl') lab0("`cmd'") `graph' ///
            title("Original `cmd' versus indicator-saturated estimates")
        di as text "Retained indicators: " as res e(nret) as text "  (" as res "`e(saturation)'" as text ", tpval = " as res e(tpval) as text ")"
    }
end

program define indsat_menu
    di
    di as text "{bf:indsat} {hline 2} indicator saturation library (Dr Merwan Roudane)"
    di as text "{hline 72}"
    di as text "{bf:Estimation}"
    di as text "  {help indsat##syntax:indsat} {it:y x}, {it:iis sis tis qis cis dis pis() mis() bis() uis() super ultra}"
    di as text "{bf:After your own model}  (regress, newey, ardl)"
    di as text "  {help indsat##post:indsat}, {it:sis iis ...}   saturates the model in memory"
    di as text "{bf:Companion tools}"
    di as text "  {help indsat_ardl:indsat ardl}     ARDL / EC model with saturation + PSS bounds test"
    di as text "  {help indsat_loop:indsat loop}     results over target sizes + Jiao-Pretis scaling tests"
    di as text "  {help indsat_gauge:indsat gauge}    null theory: cut-offs, expected false indicators, efficiency"
    di as text "  {help indsat_sim:indsat sim}      Monte Carlo gauge and potency"
    di as text "{bf:After estimation}  ({help indsat_postestimation:help})"
    di as text "  indsat dates | path | plot | test | outlier | distort | biascorr | bias | forecast | diag"
    di as text "{bf:Guides}"
    di as text "  {help indsat_types:indsat types}     which indicator type to use, and when"
    di as text "  {help indsat_methods:indsat methods}   formulas, algorithms, step-to-paper map"
    di as text "{hline 72}"
end

* =====================================================================
* estimation
* =====================================================================
program define indsat_fit, eclass sortpreserve
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "indsat") error 301
        indsat_display `0'
        exit
    }

    syntax varlist(min=1 ts numeric fv) [if] [in] [, ///
        IIS SIS TIS QIS CIS DIS PIS(integer 0) SUPER ULTRA ///
        MIS(varlist ts numeric) BIS(string) UIS(varlist numeric) ///
        SISForm(string) AR(numlist integer >0 sort) NOCONStant ///
        TPval(real 0.001) RATio(real 0.8) MAXBlock(integer -1) BLOCKs(integer 0) ///
        VCE(string) IC(string) MAXPaths(integer 0) ///
        ALGorithm(string) MSteps(integer 1) ///
        ARLB(numlist max=2) ARCHLB(numlist max=2) JB(real -1) ///
        SELect FIXed(varlist ts numeric) VARCORr GENerate(string) COMmon ///
        noOUTliertests noDATes noTABle noHEADer GRaph Level(cilevel) ///
        TOL(real 1e-7) noADDblock noLOG ]

    * ---------------------------------------------------------------- checks
    if ("`super'"!="") {
        local iis "iis"
        local sis "sis"
    }
    if ("`ultra'"!="") {
        local iis "iis"
        local sis "sis"
        local tis "tis"
    }
    if (`pis'<0) {
        di as err "pis() must be a positive integer (distance j between paired impulses)"
        exit 198
    }
    if ("`iis'`sis'`tis'`qis'`cis'`dis'"=="" & `pis'==0 & "`mis'"=="" & `"`bis'"'=="" & "`uis'"=="" & "`select'"=="") {
        di as err "specify at least one saturation option: {bf:iis sis tis qis cis dis pis() mis() bis() uis() super ultra}"
        di as err "(or {bf:select} for plain general-to-specific selection over the regressors)"
        exit 198
    }
    if (`tpval'<=0 | `tpval'>=1) {
        di as err "tpval() must lie in (0,1)"
        exit 198
    }
    if (`ratio'<=0 | `ratio'>1) {
        di as err "ratio() must lie in (0,1]"
        exit 198
    }
    local sisform = lower("`sisform'")
    if ("`sisform'"=="") local sisform "up"
    if !inlist("`sisform'","up","down") {
        di as err "sisform() must be {bf:up} (0..0,1..1; gets) or {bf:down} (1..1,0..0; Autometrics)"
        exit 198
    }
    local vce = lower("`vce'")
    if inlist("`vce'","","ols","ordinary","conventional") local vt 1
    else if inlist("`vce'","robust","white","hc0","r") local vt 2
    else if inlist("`vce'","nw","neweywest","newey-west","hac") local vt 3
    else {
        di as err "vce() must be {bf:ols}, {bf:robust} or {bf:nw}"
        exit 198
    }
    local vcelab : word `vt' of "Ordinary (OLS)" "White (1980) HC0" "Newey-West (1987) HAC"
    local ic = lower("`ic'")
    if inlist("`ic'","","sc","bic","schwarz") local icm 1
    else if ("`ic'"=="aic") local icm 2
    else if ("`ic'"=="aicc") local icm 3
    else if inlist("`ic'","hq","hqic") local icm 4
    else {
        di as err "ic() must be {bf:sc}, {bf:aic}, {bf:aicc} or {bf:hq}"
        exit 198
    }
    local iclab : word `icm' of "SC" "AIC" "AICc" "HQ"
    local algorithm = lower("`algorithm'")
    if ("`algorithm'"=="") local algorithm "gets"
    if !inlist("`algorithm'","gets","split","mstep") {
        di as err "algorithm() must be {bf:gets}, {bf:split} or {bf:mstep}"
        exit 198
    }
    if ("`algorithm'"!="gets" & ("`tis'`qis'`cis'`dis'"!="" | `pis'>0)) {
        di as err "algorithm(`algorithm') is defined for {bf:iis} (and {bf:sis} with split) only"
        exit 198
    }
    if ("`algorithm'"=="split" & ("`tis'"!="" | "`mis'"!="" | `"`bis'"'!="" | "`uis'"!="")) {
        di as err "algorithm(split) is defined for {bf:iis} and {bf:sis} only"
        exit 198
    }
    if ("`algorithm'"=="mstep" & ("`sis'`tis'"!="" | "`mis'"!="" | `"`bis'"'!="" | "`uis'"!="" | "`iis'"=="")) {
        di as err "algorithm(mstep) (m-step Huber-skip) is defined for {bf:iis} only"
        exit 198
    }
    if (`msteps'<1) {
        di as err "msteps() must be >= 1"
        exit 198
    }

    * diagnostics guard (gets: ar.LjungB, arch.LjungB, normality.JarqueB)
    local dg ". . . . ."
    if ("`arlb'"!="") {
        local a1 : word 1 of `arlb'
        local a2 : word 2 of `arlb'
        if ("`a2'"=="") local a2 0.025
        local dg "`a1' `a2'"
    }
    else local dg ". ."
    if ("`archlb'"!="") {
        local a1 : word 1 of `archlb'
        local a2 : word 2 of `archlb'
        if ("`a2'"=="") local a2 0.025
        local dg "`dg' `a1' `a2'"
    }
    else local dg "`dg' . ."
    if (`jb'>0) local dg "`dg' `jb'"
    else local dg "`dg' ."

    * ---------------------------------------------------------------- time
    local istime 0
    capture tsset
    if (_rc==0) {
        local tvar "`r(timevar)'"
        local pvar "`r(panelvar)'"
        if ("`pvar'"!="") {
            di as err "indsat is a time-series command; data are {bf:xtset} as a panel (see {help xtgets})"
            exit 459
        }
        local tfmt "`r(tsfmt)'"
        local tdelta = r(tdelta)
        local istime 1
    }
    if (!`istime' & "`ar'"!="") {
        di as err "ar() requires {bf:tsset} data"
        exit 111
    }

    * ---------------------------------------------------------------- variables
    gettoken yname xnames : varlist
    _fv_check_depvar `yname'
    marksample touse
    local xorig ""
    local xtemp ""
    if ("`ar'"!="") {
        foreach l of local ar {
            local xorig "`xorig' L`l'.`yname'"
        }
    }
    if ("`xnames'"!="") {
        * syntax compacts explicit levels (2.month 3.month) into i(2 3).month; fvexpand would then
        * treat level 2 as the base. Explicit level lists are expanded here as Nbn.var; genuine
        * factor terms (i.var, #) go through fvexpand.
        local rest "`xnames'"
        while (`"`rest'"'!="") {
            gettoken tok rest : rest, bind
            if regexm("`tok'","^i\(([0-9 ]+)\)\.(.+)$") {
                local lv = regexs(1)
                local vv = regexs(2)
                foreach l of local lv {
                    local xorig "`xorig' `l'bn.`vv'"
                }
            }
            else if regexm("`tok'","^([0-9]+)\.([^#]+)$") {
                local xorig "`xorig' `=regexs(1)'bn.`=regexs(2)'"
            }
            else if regexm("`tok'","(^|[.#(])i[0-9(.bn]|#") {
                fvexpand `tok' if `touse'
                local xorig "`xorig' `r(varlist)'"
            }
            else {
                local xorig "`xorig' `tok'"
            }
        }
    }
    local xorig : list retokenize xorig
    * drop omitted factor levels (o. / b.)
    local xclean ""
    foreach v of local xorig {
        if !regexm("`v'","^[0-9]+b\.|^[0-9]*o\.|\.o\.") {
            local xclean "`xclean' `v'"
        }
    }
    local xorig : list retokenize xclean
    if ("`xorig'"!="") {
        * normalise names exactly as Stata writes them in e(b) (L1.y -> L.y, etc.)
        tempname nmx
        local nxo : word count `xorig'
        matrix `nmx' = J(1, `nxo', 0)
        matrix colnames `nmx' = `xorig'
        local xorig : colnames `nmx'
        fvrevar `xorig'
        local xtemp "`r(varlist)'"
        markout `touse' `xtemp'
    }
    tsrevar `yname'
    local ytemp "`r(varlist)'"
    markout `touse' `ytemp'
    if ("`mis'"!="") {
        tempname nmm
        matrix `nmm' = J(1, `: word count `mis'', 0)
        matrix colnames `nmm' = `mis'
        local mis : colnames `nmm'
        fvrevar `mis'
        local mistemp "`r(varlist)'"
        foreach v of local mis {
            local isin : list v in xorig
            if (!`isin') {
                di as err "mis(): `v' must also be a regressor of the model"
                exit 198
            }
        }
    }
    if ("`uis'"!="") markout `touse' `uis'
    if ("`fixed'"!="") {
        tempname nmf
        matrix `nmf' = J(1, `: word count `fixed'', 0)
        matrix colnames `nmf' = `fixed'
        local fixed : colnames `nmf'
        foreach v of local fixed {
            local isin : list v in xorig
            if (!`isin') {
                di as err "fixed(): `v' is not a regressor of the model"
                exit 198
            }
        }
    }
    quietly count if `touse'
    local N = r(N)
    if (`N'<10) {
        di as err "too few observations (`N')"
        exit 2001
    }

    * time index and contiguity
    tempvar tt
    if (`istime') {
        qui gen double `tt' = `tvar' if `touse'
        sort `tt'
        mata: indsat_checkgap("`tt'","`touse'",`tdelta')
        if (r(gap)==1) {
            di as err "the estimation sample has gaps in `tvar'; indicator saturation needs a contiguous sample"
            exit 459
        }
    }
    else {
        qui gen double `tt' = _n if `touse'
        local tfmt "%9.0g"
        local tvar "_n"
    }

    * designed break function (BIS)
    local bisshape ""
    local bislab ""
    if (`"`bis'"'!="") {
        indsat_bisparse `bis'
        local bisshape "`r(shape)'"
        local bislab "`r(label)'"
    }

    * ---------------------------------------------------------------- engine
    local types ""
    if ("`iis'"!="") local types "`types' 1"
    if ("`sis'"!="") local types "`types' 2"
    if ("`tis'"!="") local types "`types' 3"
    if ("`mis'"!="") local types "`types' 4"
    if ("`uis'"!="") local types "`types' 5"
    if (`"`bis'"'!="") local types "`types' 6"
    if ("`qis'"!="") local types "`types' 7"
    if ("`cis'"!="") local types "`types' 8"
    if ("`dis'"!="") local types "`types' 9"
    if (`pis'>0) local types "`types' 10"
    local cons = ("`noconstant'"=="")
    local sisdown = ("`sisform'"=="down")
    local alg = 1*("`algorithm'"=="gets") + 2*("`algorithm'"=="split") + 3*("`algorithm'"=="mstep")

    * fixed flags (select option)
    local fixflag ""
    foreach v of local xorig {
        local isin : list v in fixed
        if ("`select'"=="") local isin 1
        local fixflag "`fixflag' `isin'"
    }

    tempname bmat Vmat
    mata: indsat_main()

    * ---------------------------------------------------------------- post
    local cn "`r(colnames)'"
    matrix colnames `bmat' = `cn'
    matrix colnames `Vmat' = `cn'
    matrix rownames `Vmat' = `cn'
    local df_r = r(df_r)
    local nobs = r(N)
    tempname S_brk S_X S_t S_bc S_res
    matrix `S_brk' = __isat_brk
    matrix `S_X' = __isat_X
    matrix `S_t' = __isat_t
    matrix `S_res' = __isat_res
    capture matrix drop __isat_brk __isat_X __isat_t __isat_res
    foreach s in rss ll sigma r2 r2_a icval nest ncand nret niis nsis ntis nmis nuis nbis nqis ncis ndis npis ///
                 sigcor lb_ar lb_ar_p lb_ar_df lb_arch lb_arch_p lb_arch_df jb jb_p ///
                 op_z op_p op_count op_count_p dist_chi2 dist_df dist_p k_x nblk tss xi eta {
        local R_`s' = r(`s')
    }
    local retnames "`r(retnames)'"
    local xret "`r(xret)'"
    local blkinfo "`r(blkinfo)'"

    ereturn post `bmat' `Vmat', esample(`touse') depname(`yname') obs(`nobs') dof(`df_r')
    foreach s in rss ll sigma r2 r2_a icval nest ncand nret niis nsis ntis nmis nuis nbis nqis ncis ndis npis k_x {
        ereturn scalar `s' = `R_`s''
    }
    ereturn scalar tss = `R_tss'
    ereturn scalar df_r = `df_r'
    ereturn scalar tpval = `tpval'
    ereturn scalar ratio = `ratio'
    ereturn scalar maxblock = cond(`maxblock'>0, `maxblock', 30)
    ereturn scalar msteps = `msteps'
    ereturn scalar crit = invnormal(1-`tpval'/2)
    ereturn scalar gauge_exp = `tpval'*`R_ncand'
    ereturn scalar gauge = cond(`R_ncand'>0, `R_nret'/`R_ncand', .)
    ereturn scalar pis = `pis'
    ereturn scalar sigma_cor = `R_sigcor'
    ereturn scalar xi = `R_xi'
    ereturn scalar eta = `R_eta'
    ereturn scalar cons = `cons'
    ereturn scalar varcorr = ("`varcorr'"!="")
    if (`R_lb_ar'<.) {
        ereturn scalar lb_ar = `R_lb_ar'
        ereturn scalar lb_ar_p = `R_lb_ar_p'
        ereturn scalar lb_ar_df = `R_lb_ar_df'
        ereturn scalar lb_arch = `R_lb_arch'
        ereturn scalar lb_arch_p = `R_lb_arch_p'
        ereturn scalar lb_arch_df = `R_lb_arch_df'
        ereturn scalar jb = `R_jb'
        ereturn scalar jb_p = `R_jb_p'
    }
    if (`R_op_z'<.) {
        ereturn scalar op_z = `R_op_z'
        ereturn scalar op_p = `R_op_p'
        ereturn scalar op_count = `R_op_count'
        ereturn scalar op_count_p = `R_op_count_p'
    }
    if (`R_dist_chi2'<.) {
        ereturn scalar dist_chi2 = `R_dist_chi2'
        ereturn scalar dist_df = `R_dist_df'
        ereturn scalar dist_p = `R_dist_p'
    }
    ereturn local saturation = trim(cond("`iis'"!="","IIS ","") + cond("`sis'"!="","SIS ","") + ///
        cond("`tis'"!="","TIS ","") + cond("`mis'"!="","MIS ","") + cond("`uis'"!="","UIS ","") + ///
        cond(`"`bis'"'!="","BIS ","") + cond("`qis'"!="","QIS ","") + cond("`cis'"!="","CIS ","") + ///
        cond("`dis'"!="","DIS ","") + cond(`pis'>0,"PIS(`pis')",""))
    if ("`ultra'"!="") ereturn local family "ultra saturation (IIS+SIS+TIS)"
    else if ("`super'"!="" | ("`iis'"!="" & "`sis'"!="")) ereturn local family "super saturation (IIS+SIS)"
    else ereturn local family "" 
    ereturn local retained "`retnames'"
    ereturn local xvars "`xorig'"
    ereturn local xret "`xret'"
    ereturn local misvars "`mis'"
    ereturn local uisvars "`uis'"
    ereturn local bis `"`bislab'"'
    ereturn local bisshape "`bisshape'"
    ereturn local sisform "`sisform'"
    ereturn local ar "`ar'"
    ereturn local algorithm "`algorithm'"
    ereturn local blkinfo "`blkinfo'"
    ereturn local vce "`vce'"
    ereturn local vcetype "`vcelab'"
    ereturn local ic "`iclab'"
    ereturn local timevar "`tvar'"
    ereturn local tsfmt "`tfmt'"
    ereturn local select "`select'"
    ereturn local fixed "`fixed'"
    ereturn local title "Indicator saturation (indsat)"
    ereturn local predict "indsat_p"
    ereturn local estat_cmd "indsat_estat"
    ereturn local cmdline `"indsat `0'"'
    ereturn local cmd "indsat"
    ereturn matrix breaks = `S_brk'
    ereturn matrix X = `S_X'
    ereturn matrix tvals = `S_t'
    ereturn matrix resid = `S_res'

    * optional: generate retained indicators as variables
    if ("`generate'"!="") {
        indsat_genind `generate'
    }

    indsat_display, level(`level') `table' `header' `dates' `outliertests'
    if ("`graph'"!="") {
        indsat_estat plot
    }
end

* =====================================================================
program define indsat_bisparse, rclass
    * bis(volcanic [gamma(#) length(#)]) | bis(shape(numlist)) | bis(ramp(#)) | bis(decay(# #))
    syntax [anything] [, GAMma(real 0.5) LENgth(integer -1) SHape(numlist) DELta(real 0.7) ]
    local kind = lower(trim("`anything'"))
    if regexm("`kind'","^(tc|transitory)") {
        * transitory change (TRAMO / X-13 'TC'; Marczak-Proietti 2016): delta^k, k = 0..L-1
        if (`delta'<=0 | `delta'>=1) {
            di as err "bis(tc): delta() must lie in (0,1)"
            exit 198
        }
        if (`length'<1) local length = ceil(ln(0.01)/ln(`delta')) + 1
        local s ""
        forvalues t = 1/`length' {
            local s "`s' `=`delta'^(`t'-1)'"
        }
        return local shape "`s'"
        return local label "transitory change, delta=`delta', L=`length'"
        exit
    }
    if (`length'<1) local length 3
    if ("`shape'"!="") {
        return local shape "`shape'"
        return local label "user shape (`shape')"
        exit
    }
    if inlist("`kind'","","volcanic","volcano") {
        * Pretis, Schneider, Smerdon & Hendry (2016) eq.(31), tau = C/theta = 1:
        * d(t) = exp(-t) (1-1/gamma)^(-1) [exp(t(1-1/gamma)) - 1],  t = 1..L, normalised max|d| = 1
        local s ""
        local mx 0
        forvalues t = 1/`length' {
            if (abs(`gamma'-1)<1e-10) local d = `t'*exp(-`t')
            else local d = exp(-`t')*(1/(1-1/`gamma'))*(exp(`t'*(1-1/`gamma'))-1)
            local d`t' = `d'
            if (abs(`d')>`mx') local mx = abs(`d')
        }
        forvalues t = 1/`length' {
            local s "`s' `=`d`t''/`mx''"
        }
        return local shape "`s'"
        return local label "volcanic, gamma=`gamma', L=`length'"
        exit
    }
    if regexm("`kind'","^ramp") {
        * linear recovery ramp of length L: 1, (L-1)/L, ..., 1/L
        local s ""
        forvalues t = 1/`length' {
            local s "`s' `=(`length'-`t'+1)/`length''"
        }
        return local shape "`s'"
        return local label "ramp, L=`length'"
        exit
    }
    di as err "bis(): use {bf:volcanic} [, gamma() length()], {bf:tc} [, delta() length()], {bf:ramp} [, length()] or {bf:, shape(numlist)}"
    exit 198
end

* =====================================================================
program define indsat_genind
    args stub
    tempname X
    matrix `X' = e(X)
    local cn : colnames `X'
    local k : word count `cn'
    local xv "`e(xvars)'"
    tempvar es
    qui gen byte `es' = e(sample)
    local j 0
    foreach c of local cn {
        local ++j
        local isx : list c in xv
        if ("`c'"=="_cons" | `isx') continue
        local nm = substr("`stub'`c'",1,32)
        local nm = subinstr("`nm'",".","_",.)
        capture drop `nm'
        qui gen double `nm' = .
        mata: indsat_fillvar("`nm'", `j', "`es'")
        label var `nm' "indsat indicator `c'"
    }
end

* =====================================================================
program define indsat_display
    syntax [, Level(cilevel) noTABle noHEADer noDATes noOUTliertests ]
    local y "`e(depvar)'"
    local tf "`e(tsfmt)'"
    tempname T
    matrix `T' = e(tvals)
    local n = e(N)
    local t1 = `T'[1,1]
    local t2 = `T'[`n',1]
    if ("`e(timevar)'"!="_n") {
        local s1 : display `tf' `t1'
        local s2 : display `tf' `t2'
    }
    else {
        local s1 "1"
        local s2 "`n'"
    }
    local s1 = trim("`s1'")
    local s2 = trim("`s2'")
    local alg "`e(algorithm)'"
    if ("`alg'"=="gets") local algl "multi-path GETS (blocks)"
    if ("`alg'"=="split") local algl "split-half (JN 2009)"
    if ("`alg'"=="mstep") local algl "`e(msteps)'-step Huber-skip"

    if ("`header'"=="") {
        di
        di as text "{bf:Indicator saturation (indsat)} {hline 2} general-to-specific selection of indicators"
        di as text "{hline 78}"
        di as text "Dependent variable : " as res "`y'" _col(50) as text "Number of obs    = " as res %9.0f e(N)
        di as text "Sample             : " as res "`s1' - `s2'" _col(50) as text "Candidate ind.   = " as res %9.0f e(ncand)
        di as text "Saturation         : " as res "`e(saturation)'" _col(50) as text "Retained ind.    = " as res %9.0f e(nret)
        di as text "Target size (p)    : " as res %6.4f e(tpval) as text "  (|t| > " as res %4.2f e(crit) as text ")" ///
            _col(50) as text "Expected false   = " as res %9.2f e(gauge_exp)
        di as text "Algorithm          : " as res "`algl'" _col(50) as text "Estimations      = " as res %9.0f e(nest)
        di as text "Terminal selection : " as res "`e(ic)'" _col(50) as text "IC value         = " as res %9.4f e(icval)
        di as text "Covariance         : " as res "`e(vcetype)'" _col(50) as text "R-squared        = " as res %9.4f e(r2)
        if ("`e(sisform)'"=="down" & strpos("`e(saturation)'","SIS")) {
            di as text "Step form          : " as res "1(t<=j) (Autometrics / Castle et al. 2015)"
        }
        if (`"`e(bis)'"'!="") di as text "Break function     : " as res `"`e(bis)'"'
        if (e(varcorr)==1) di as text "Variance correction: " as res "Johansen-Nielsen consistency xi=" %6.4f e(xi) " , efficiency eta=" %6.4f e(eta)
    }
    if ("`table'"=="") {
        indsat_coeftable, level(`level')
    }
    * diagnostics & fit
    di as text "{bf:Diagnostics and fit}"
    di as text "{hline 78}"
    di as text %-34s "Test" _col(38) %12s "Statistic" _col(52) %6s "df" _col(62) %10s "p-value"
    di as text "{hline 78}"
    if (e(lb_ar)<.) {
        indsat_drow "Ljung-Box AR(`=e(lb_ar_df)')" `=e(lb_ar)' `=e(lb_ar_df)' `=e(lb_ar_p)'
        indsat_drow "Ljung-Box ARCH(`=e(lb_arch_df)')" `=e(lb_arch)' `=e(lb_arch_df)' `=e(lb_arch_p)'
        indsat_drow "Jarque-Bera normality" `=e(jb)' 2 `=e(jb_p)'
    }
    if (e(op_z)<. & "`outliertests'"=="") {
        indsat_drow "Jiao-Pretis outlier proportion (z)" `=e(op_z)' . `=e(op_p)'
        indsat_drow "Jiao-Pretis outlier count (Poisson)" `=e(op_count)' . `=e(op_count_p)'
        if (e(dist_chi2)<.) indsat_drow "Jiao-Pretis-Schwarz distortion (chi2)" `=e(dist_chi2)' `=e(dist_df)' `=e(dist_p)'
    }
    di as text "{hline 78}"
    di as text "SE of regression   = " as res %10.5g e(sigma) _col(40) as text "Log-likelihood   = " as res %12.4f e(ll)
    di as text "Adj. R-squared     = " as res %10.4f e(r2_a) _col(40) as text "RSS              = " as res %12.5g e(rss)
    if (e(sigma_cor)<.) di as text "Consistency-corrected sigma (Johansen-Nielsen) = " as res %10.5g e(sigma_cor)
    di as text "{hline 78}"
    di as text "Significance: * p<0.10, ** p<0.05, *** p<0.01.  Indicators retained at p < " %6.4f e(tpval) "."
    if ("`dates'"=="" & e(nret)>0) {
        indsat_estat dates, compact
    }
end

program define indsat_drow
    args lab st df p
    local stars ""
    if (`p'<0.10) local stars "*"
    if (`p'<0.05) local stars "**"
    if (`p'<0.01) local stars "***"
    if (`df'<.) di as text %-36s "`lab'" _col(38) as res %12.4f `st' _col(52) as res %6.0f `df' _col(62) as res %10.4f `p' as text " `stars'"
    else di as text %-36s "`lab'" _col(38) as res %12.4f `st' _col(52) as text %6s "" _col(62) as res %10.4f `p' as text " `stars'"
end

program define indsat_coeftable
    syntax [, Level(cilevel)]
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local cn : colnames `b'
    local k = colsof(`b')
    local df = e(df_r)
    local q = invttail(`df', (100-`level')/200)
    local xv "`e(xvars)'"
    di as text "{hline 20}{c TT}{hline 62}"
    di as text %19s abbrev("`e(depvar)'",19) " {c |}" %11s "Coef." %11s "Std. err." %8s "t" %8s "P>|t|" "    [`level'% conf. interval]"
    di as text "{hline 20}{c +}{hline 62}"
    * two passes: regressors, then indicators
    forvalues pass = 1/2 {
        local shown 0
        forvalues j = 1/`k' {
            local c : word `j' of `cn'
            local isx : list c in xv
            local isreg = (`isx' | "`c'"=="_cons")
            if ((`pass'==1 & `isreg') | (`pass'==2 & !`isreg')) {
                if (`shown'==0) {
                    if (`pass'==1) di as text "{it:Regressors}" _col(21) "{c |}"
                    else di as text "{it:Retained indicators}" _col(21) "{c |}"
                    local shown 1
                }
                local bb = `b'[1,`j']
                local se = sqrt(`V'[`j',`j'])
                local tt = `bb'/`se'
                local pp = 2*ttail(`df',abs(`tt'))
                local st ""
                if (`pp'<0.10) local st "*"
                if (`pp'<0.05) local st "**"
                if (`pp'<0.01) local st "***"
                di as text %19s abbrev("`c'",19) " {c |}" as res %11.5g `bb' %11.5g `se' %8.2f `tt' %8.3f `pp' ///
                    "   " %11.5g `bb'-`q'*`se' " " %11.5g `bb'+`q'*`se' as text " `st'"
            }
        }
    }
    di as text "{hline 20}{c BT}{hline 62}"
end

* =====================================================================
version 14.0
mata:

real scalar indsat_ping()
{
    return(1)
}

void indsat_checkgap(string scalar tv, string scalar touse, real scalar delta)
{
    real colvector t, d
    t = st_data(., tv, touse)
    st_numscalar("r(gap)", 0)
    if (rows(t)<2) return
    d = t[|2 \ rows(t)|] - t[|1 \ rows(t)-1|]
    if (max(abs(d :- delta)) > 1e-8) {
        st_numscalar("r(gap)", 1)
    }
}

void indsat_fillvar(string scalar nm, real scalar j, string scalar es)
{
    real matrix X
    real colvector idx
    X = st_matrix("e(X)")
    idx = selectindex(st_data(., es) :!= 0)
    st_store(idx, nm, X[., j])
}

/* ---------------------------------------------------------- utilities */
real rowvector indsat_setdiff(real rowvector a, real rowvector b)
{
    real rowvector out
    real scalar i
    out = J(1, 0, .)
    for (i=1; i<=cols(a); i++) {
        if (cols(b)==0) {
            out = out, a[i]
        }
        else {
            if (!anyof(b, a[i])) {
                out = out, a[i]
            }
        }
    }
    return(out)
}

real rowvector indsat_union(real rowvector a, real rowvector b)
{
    real rowvector out
    real scalar i
    out = a
    for (i=1; i<=cols(b); i++) {
        if (cols(out)==0) {
            out = b[i]
        }
        else {
            if (!anyof(out, b[i])) {
                out = out, b[i]
            }
        }
    }
    return(out)
}

real rowvector indsat_sortrow(real rowvector a)
{
    if (cols(a)<=1) return(a)
    return(sort(a', 1)')
}

real rowvector indsat_sub(real rowvector a, real rowvector idx)
{
    real rowvector out
    real scalar i
    out = J(1, cols(idx), .)
    for (i=1; i<=cols(idx); i++) {
        out[i] = a[idx[i]]
    }
    return(out)
}

real rowvector indsat_which(real rowvector cond)
{
    real rowvector out
    real scalar i
    out = J(1, 0, .)
    for (i=1; i<=cols(cond); i++) {
        if (cond[i]!=0) {
            out = out, i
        }
    }
    return(out)
}

real matrix indsat_cols(real matrix X, real rowvector idx)
{
    real matrix out
    real scalar i
    out = J(rows(X), cols(idx), .)
    for (i=1; i<=cols(idx); i++) {
        out[., i] = X[., idx[i]]
    }
    return(out)
}

real scalar indsat_icval(real scalar ll, real scalar n, real scalar k, real scalar icm)
{
    real scalar v
    v = -2*ll/n + k*ln(n)/n
    if (icm==2) {
        v = -2*ll/n + 2*k/n
    }
    if (icm==3) {
        v = -2*ll/n + 2*k/(n-k-1)
    }
    if (icm==4) {
        v = -2*ll/n + 2*k*ln(ln(n))/n
    }
    return(v)
}

/* OLS as in gets::ols(method=3/4/5): sigma2 = RSS/(n-k); logl uses that sigma2 */
real scalar indsat_ols(real colvector y, real matrix X, real scalar vt,
    real colvector b, real matrix V, real scalar ll, real scalar rss,
    real colvector e)
{
    real scalar n, k, df, s2, L, l, w
    real matrix XXi, Xe, S0, A, B
    n = rows(y)
    k = cols(X)
    if (k==0) {
        b = J(0, 1, .)
        V = J(0, 0, .)
        e = y
        rss = quadcross(e, e)
        s2 = rss/n
        ll = -n*ln(2*s2*pi())/2 - rss/(2*s2)
        return(1)
    }
    df = n - k
    if (df<=0) {
        return(0)
    }
    XXi = invsym(quadcross(X, X))
    if (diag0cnt(XXi)>0) {
        return(0)
    }
    b = XXi*quadcross(X, y)
    e = y - X*b
    rss = quadcross(e, e)
    s2 = rss/df
    if (vt==2) {
        Xe = X :* e
        V = XXi*quadcross(Xe, Xe)*XXi
    }
    else {
        if (vt==3) {
            Xe = X :* e
            S0 = quadcross(Xe, Xe)
            L = round(n^(1/4))
            for (l=1; l<=L; l++) {
                w = 1 - l/(L+1)
                A = Xe[|l+1, 1 \ n, k|]
                B = Xe[|1, 1 \ n-l, k|]
                S0 = S0 + w*(quadcross(A, B) + quadcross(B, A))
            }
            V = XXi*S0*XXi
        }
        else {
            V = s2*XXi
        }
    }
    ll = -n*ln(2*s2*pi())/2 - rss/(2*s2)
    return(1)
}

/* Ljung-Box Q statistic (stats::Box.test, type="Ljung") */
real scalar indsat_lbstat(real colvector x, real scalar lag)
{
    real scalar n, k, Q, den, r
    real colvector d
    n = rows(x)
    d = x :- mean(x)
    den = quadcross(d, d)
    Q = 0
    for (k=1; k<=lag; k++) {
        r = quadcross(d[|1 \ n-k|], d[|k+1 \ n|])/den
        Q = Q + r*r/(n-k)
    }
    return(n*(n+2)*Q)
}

/* Jarque-Bera as in gets::diagnostics */
real scalar indsat_jbstat(real colvector x)
{
    real scalar n, K, S
    real colvector d
    n = rows(x)
    d = x :- mean(x)
    K = n*sum(d:^4)/(sum(d:^2)^2)
    S = (sum(d:^3)/n)/((sum(d:^2)/n)^(3/2))
    return((n/6)*(S^2 + 0.25*((K-3)^2)))
}

real scalar indsat_diagok(real colvector e, real rowvector dg)
{
    real scalar ok
    ok = 1
    if (dg[1]<.) {
        if (chi2tail(dg[1], indsat_lbstat(e, dg[1])) <= dg[2]) {
            ok = 0
        }
    }
    if (ok==1 & dg[3]<.) {
        if (chi2tail(dg[3], indsat_lbstat(e:^2, dg[3])) <= dg[4]) {
            ok = 0
        }
    }
    if (ok==1 & dg[5]<.) {
        if (chi2tail(2, indsat_jbstat(e)) <= dg[5]) {
            ok = 0
        }
    }
    return(ok)
}

/* drop collinear columns in order (LINPACK dqrdc2 behaviour of gets::dropvar) */
real rowvector indsat_dropvar(real matrix X, real scalar tol)
{
    real rowvector keepi
    real matrix Q
    real colvector x, r
    real scalar j, nx, nr
    keepi = J(1, 0, .)
    Q = J(rows(X), 0, .)
    for (j=1; j<=cols(X); j++) {
        x = X[., j]
        nx = sqrt(quadcross(x, x))
        if (nx<=0) {
            continue
        }
        r = x
        if (cols(Q)>0) {
            r = x - Q*(Q'x)
            r = r - Q*(Q'r)
        }
        nr = sqrt(quadcross(r, r))
        if (nr > tol*nx) {
            Q = Q, r/nr
            keepi = keepi, j
        }
    }
    return(keepi)
}

/* p-values of t-ratios */
real rowvector indsat_pvals(real colvector b, real matrix V, real scalar df)
{
    real rowvector p
    real scalar j
    p = J(1, rows(b), .)
    for (j=1; j<=rows(b); j++) {
        p[j] = 2*ttail(df, abs(b[j]/sqrt(V[j, j])))
    }
    return(p)
}

/* ------------------------------------------------------------------
   Multi-path GETS: port of gets::getsFun (include.gum=TRUE, no PET,
   optional diagnostics, information-criterion tie-break)
   returns sorted column indices of the selected terminal
------------------------------------------------------------------- */
real rowvector indsat_getsfun(real colvector y, real matrix X, real rowvector keep,
    real scalar tp, real scalar vt, real scalar icm, real rowvector dg,
    real scalar maxpaths, real scalar nest)
{
    real scalar n, k, ok, gumok, ll, rss, i, r, pmax, best, j, dok, lastdel, isnew, done
    real rowvector gum, del, insig, p, dadj, kadj, cc, spec, row, pins, ordv
    real colvector b, e, ICV
    real matrix V, TT
    n = rows(y)
    k = cols(X)
    gum = J(1, 0, .)
    for (j=1; j<=k; j++) {
        gum = gum, j
    }
    del = indsat_setdiff(gum, keep)
    TT = J(0, k, .)
    ICV = J(0, 1, .)
    ok = indsat_ols(y, X, vt, b, V, ll, rss, e)
    nest = nest + 1
    gumok = 0
    if (ok==1) {
        gumok = indsat_diagok(e, dg)
    }
    insig = J(1, 0, .)
    if (gumok==1) {
        if (k>0) {
            p = indsat_pvals(b, V, n-k)
            for (j=1; j<=cols(del); j++) {
                if (p[del[j]] > tp) {
                    insig = insig, del[j]
                }
            }
        }
        TT = TT \ J(1, k, 1)
        ICV = ICV \ indsat_icval(ll, n, k, icm)
    }
    if (gumok==1 & cols(del)>0 & cols(insig)>0) {
        if (maxpaths>0 & maxpaths<cols(insig)) {
            pins = indsat_sub(p, insig)
            ordv = order(-pins', 1)'
            row = J(1, cols(insig), 0)
            for (j=1; j<=maxpaths; j++) {
                row[ordv[j]] = 1
            }
            insig = indsat_sub(insig, indsat_which(row))
        }
        for (i=1; i<=cols(insig); i++) {
            dadj = indsat_setdiff(del, insig[i])
            kadj = keep
            lastdel = insig[i]
            done = 0
            spec = J(1, 0, .)
            while (done==0) {
                cc = dadj, kadj
                ok = indsat_ols(y, indsat_cols(X, cc), vt, b, V, ll, rss, e)
                nest = nest + 1
                dok = 0
                if (ok==1) {
                    dok = indsat_diagok(e, dg)
                }
                if (dok==0) {
                    if (anyof(kadj, lastdel)) {
                        spec = indsat_sortrow(cc)
                        done = 1
                    }
                    else {
                        kadj = indsat_union(J(1, 1, lastdel), kadj)
                    }
                    continue
                }
                if (cols(dadj)==0) {
                    spec = indsat_sortrow(kadj)
                    done = 1
                    continue
                }
                p = indsat_pvals(b, V, n-cols(cc))
                pmax = -1
                r = 0
                for (j=1; j<=cols(dadj); j++) {
                    if (p[j] > pmax) {
                        pmax = p[j]
                        r = j
                    }
                }
                if (pmax > tp) {
                    lastdel = dadj[r]
                    dadj = indsat_setdiff(dadj, J(1, 1, lastdel))
                }
                else {
                    spec = indsat_sortrow(cc)
                    done = 1
                }
            }
            row = J(1, k, 0)
            for (j=1; j<=cols(spec); j++) {
                row[spec[j]] = 1
            }
            isnew = 1
            for (j=1; j<=rows(TT); j++) {
                if (TT[j, .]==row) {
                    isnew = 0
                }
            }
            if (isnew==1) {
                TT = TT \ row
                ICV = ICV \ indsat_icval(ll, n, cols(spec), icm)
            }
        }
    }
    if (rows(TT)==0) {
        return(J(1, 0, .))
    }
    best = 1
    for (j=2; j<=rows(ICV); j++) {
        if (ICV[j] < ICV[best]) {
            best = j
        }
    }
    return(indsat_which(TT[best, .]))
}

/* gets wrapper: dropvar first (keep = first kx columns), return original column indices */
real rowvector indsat_gets_dv(real colvector y, real matrix X, real rowvector keepin,
    real scalar tp, real scalar vt, real scalar icm, real rowvector dg,
    real scalar maxpaths, real scalar tol, real scalar nest)
{
    real rowvector kept, keep, spec, out
    real scalar j
    kept = indsat_dropvar(X, tol)
    keep = J(1, 0, .)
    for (j=1; j<=cols(kept); j++) {
        if (anyof(keepin, kept[j])) {
            keep = keep, j
        }
    }
    spec = indsat_getsfun(y, indsat_cols(X, kept), keep, tp, vt, icm, dg, maxpaths, nest)
    out = J(1, 0, .)
    for (j=1; j<=cols(spec); j++) {
        out = out, kept[spec[j]]
    }
    return(out)
}

/* additional (leave-one-out interleaved) block search, gets ISadditionalblocksearch */
real rowvector indsat_addblock(real colvector y, real matrix mX, real matrix M, real rowvector sel,
    real rowvector keepx, real scalar tp, real scalar vt, real scalar icm, real rowvector dg,
    real scalar maxpaths, real scalar tol, real scalar nest)
{
    real scalar n, kx, nis, nb, j, jj
    real rowvector newsel, idx, keepin, spec, ret
    n = rows(y)
    kx = cols(mX)
    nis = cols(sel)
    nb = 2
    while (kx + ceil(nis/nb) >= n) {
        nb = nb + 1
    }
    newsel = J(1, 0, .)
    for (j=1; j<=nb; j++) {
        idx = J(1, 0, .)
        for (jj=j; jj<=nis; jj=jj+nb) {
            idx = idx, sel[jj]
        }
        if (cols(idx)==0) {
            continue
        }
        spec = indsat_gets_dv(y, (mX, indsat_cols(M, idx)), keepx, tp, vt, icm, dg, maxpaths, tol, nest)
        ret = J(1, 0, .)
        for (jj=1; jj<=cols(spec); jj++) {
            if (spec[jj] > kx) {
                ret = ret, idx[spec[jj]-kx]
            }
        }
        newsel = indsat_union(newsel, ret)
    }
    if (kx + cols(newsel) >= n) {
        errprintf("indsat retains too many indicators even after an additional block search;\n")
        errprintf("use a smaller tpval() or maxblock(), or improve the model specification\n")
        exit(error(498))
    }
    return(newsel)
}

/* block search for one indicator set M, gets ISMatricesLoop */
real rowvector indsat_isblock(real colvector y, real matrix mX, real matrix M,
    real scalar ratio, real scalar maxblock, real scalar nbuser, real rowvector keepx,
    real scalar tp, real scalar vt, real scalar icm, real rowvector dg,
    real scalar maxpaths, real scalar tol, real scalar addblock, real scalar nest,
    real scalar nblk)
{
    real scalar n, m, kx, nb, den, a2, a3, bs, b, j, jj
    real rowvector t1, t2, sel, idx, spec, ret
    n = rows(y)
    m = cols(M)
    kx = cols(mX)
    if (nbuser>0) {
        nb = nbuser
    }
    else {
        den = ratio*m - kx
        a2 = 2
        if (den > 0) {
            a2 = m/den
        }
        if (den == 0) {
            a2 = m
        }
        a3 = m/min((n*ratio, maxblock))
        nb = ceil(max((2, a2, a3)))
        nb = min((m, nb))
    }
    bs = ceil(m/nb)
    t2 = J(1, 0, .)
    for (j=1; j<=nb; j++) {
        if (bs*j <= m) {
            t2 = t2, bs*j
        }
    }
    if (cols(t2)==0) {
        t2 = m
    }
    if (t2[cols(t2)] < m) {
        t2 = t2, m
    }
    t1 = J(1, cols(t2), 1)
    for (j=2; j<=cols(t2); j++) {
        t1[j] = t2[j-1] + 1
    }
    nblk = cols(t2)
    sel = J(1, 0, .)
    for (b=1; b<=cols(t2); b++) {
        idx = J(1, 0, .)
        for (jj=t1[b]; jj<=t2[b]; jj++) {
            idx = idx, jj
        }
        if (kx + cols(idx) >= n) {
            errprintf("too many regressors and indicators in a block for the sample size;\n")
            errprintf("set a smaller maxblock() or fewer regressors\n")
            exit(error(498))
        }
        spec = indsat_gets_dv(y, (mX, indsat_cols(M, idx)), keepx, tp, vt, icm, dg, maxpaths, tol, nest)
        ret = J(1, 0, .)
        for (jj=1; jj<=cols(spec); jj++) {
            if (spec[jj] > kx) {
                ret = ret, idx[spec[jj]-kx]
            }
        }
        sel = indsat_union(sel, ret)
    }
    if (cols(sel)==0) {
        return(sel)
    }
    if (kx + cols(sel) >= n) {
        if (addblock==0) {
            errprintf("too many indicators retained in the block search; use a smaller tpval()\n")
            exit(error(498))
        }
        sel = indsat_addblock(y, mX, M, sel, keepx, tp, vt, icm, dg, maxpaths, tol, nest)
    }
    spec = indsat_gets_dv(y, (mX, indsat_cols(M, sel)), keepx, tp, vt, icm, dg, maxpaths, tol, nest)
    ret = J(1, 0, .)
    for (jj=1; jj<=cols(spec); jj++) {
        if (spec[jj] > kx) {
            ret = ret, sel[spec[jj]-kx]
        }
    }
    return(ret)
}

/* ------------------------------------------------------------------
   Indicator matrices.  type: 1 IIS 2 SIS 3 TIS 4 MIS 5 UIS 6 BIS
   tau[j] = observation index at which column j starts (or ends, SIS-down)
------------------------------------------------------------------- */
real matrix indsat_makeM(real scalar type, real scalar n, real scalar sisdown,
    real colvector xb, real rowvector shape, real rowvector tau)
{
    real matrix M
    real scalar j, t, L
    if (type==1) {
        M = I(n)
        tau = J(1, n, .)
        for (j=1; j<=n; j++) {
            tau[j] = j
        }
        return(M)
    }
    if (type==2 | type==4) {
        M = J(n, n-1, 0)
        tau = J(1, n-1, .)
        if (type==2 & sisdown==1) {
            for (j=1; j<=n-1; j++) {
                M[|1, j \ j, j|] = J(j, 1, 1)
                tau[j] = j
            }
            return(M)
        }
        for (j=2; j<=n; j++) {
            M[|j, j-1 \ n, j-1|] = J(n-j+1, 1, 1)
            tau[j-1] = j
        }
        if (type==4) {
            M = M :* xb
        }
        return(M)
    }
    if (type==3) {
        M = J(n, n-1, 0)
        tau = J(1, n-1, .)
        for (j=2; j<=n; j++) {
            for (t=j; t<=n; t++) {
                M[t, j-1] = t - j + 1
            }
            tau[j-1] = j
        }
        return(M)
    }
    if (type==7 | type==8) {
        /* broken quadratic / cubic trends (Ericsson 2011b): (t-j+1)^p 1{t>=j} */
        M = J(n, n-1, 0)
        tau = J(1, n-1, .)
        for (j=2; j<=n; j++) {
            for (t=j; t<=n; t++) {
                M[t, j-1] = (t - j + 1)^(type - 5)
            }
            tau[j-1] = j
        }
        return(M)
    }
    if (type==9) {
        /* differenced (zero-sum pairwise) IIS: Z_j = I_j - I_(j-1) */
        M = J(n, n-1, 0)
        tau = J(1, n-1, .)
        for (j=2; j<=n; j++) {
            M[j, j-1] = 1
            M[j-1, j-1] = -1
            tau[j-1] = j
        }
        return(M)
    }
    if (type==10) {
        /* pairwise IIS: P_i = I_i + I_(i+pj) ; pj = shape[1] */
        L = shape[1]
        M = J(n, n-L, 0)
        tau = J(1, n-L, .)
        for (j=1; j<=n-L; j++) {
            M[j, j] = 1
            M[j+L, j] = 1
            tau[j] = j
        }
        return(M)
    }
    if (type==6) {
        L = cols(shape)
        M = J(n, n, 0)
        tau = J(1, n, .)
        for (j=1; j<=n; j++) {
            for (t=j; t<=min((n, j+L-1)); t++) {
                M[t, j] = shape[t-j+1]
            }
            tau[j] = j
        }
        return(M)
    }
    return(J(n, 0, .))
}

string scalar indsat_tlab(real scalar t, string scalar fmt)
{
    string scalar s
    s = strtrim(strofreal(t, fmt))
    s = subinstr(s, "-", "m")
    s = subinstr(s, ".", "p")
    s = ustrregexra(s, "[^A-Za-z0-9_]", "")
    return(s)
}

/* ------------------------------------------------------------------
   Johansen-Nielsen split-half IIS (2009, Sec.2.2.2) and m-step Huber-skip
------------------------------------------------------------------- */
real colvector indsat_lsgood(real colvector y, real matrix X, real colvector g)
{
    real rowvector idx
    real matrix Xg
    real scalar j
    idx = indsat_which(g')
    if (cols(X)==0) {
        return(J(0, 1, .))
    }
    Xg = J(cols(idx), cols(X), .)
    for (j=1; j<=cols(idx); j++) {
        Xg[j, .] = X[idx[j], .]
    }
    return(invsym(quadcross(Xg, Xg))*quadcross(Xg, y[idx']))
}

real rowvector indsat_splitiis(real colvector y, real matrix X, real scalar alpha, real scalar sigcor)
{
    real scalar n, n1, c, psi, tau, xi2, j, t, s2, rssg
    real colvector v, g, bj, ej, bt, et, yj
    real matrix Xj, XXi
    real rowvector Ij, Io
    n = rows(y)
    c = invnormal(1 - alpha/2)
    psi = 1 - alpha
    tau = psi - 2*c*normalden(c)
    xi2 = tau/psi
    n1 = floor(n/2)
    v = J(n, 1, .)
    for (j=1; j<=2; j++) {
        if (j==1) {
            Ij = (1..n1)
            Io = ((n1+1)..n)
        }
        else {
            Ij = ((n1+1)..n)
            Io = (1..n1)
        }
        yj = y[Ij']
        if (cols(X)>0) {
            Xj = X[Ij', .]
            XXi = invsym(quadcross(Xj, Xj))
            bj = XXi*quadcross(Xj, yj)
            ej = yj - Xj*bj
        }
        else {
            ej = yj
        }
        s2 = quadcross(ej, ej)/cols(Ij)
        for (t=1; t<=cols(Io); t++) {
            if (cols(X)>0) {
                v[Io[t]] = (y[Io[t]] - X[Io[t], .]*bj)/sqrt(s2*(1 + X[Io[t], .]*XXi*X[Io[t], .]'))
            }
            else {
                v[Io[t]] = y[Io[t]]/sqrt(s2)
            }
        }
    }
    g = abs(v) :<= c
    bt = indsat_lsgood(y, X, g)
    if (cols(X)>0) {
        et = y - X*bt
    }
    else {
        et = y
    }
    rssg = quadcross(et :* g, et :* g)
    s2 = (1/xi2)*rssg/sum(g)
    g = abs(et/sqrt(s2)) :<= c
    bt = indsat_lsgood(y, X, g)
    if (cols(X)>0) {
        et = y - X*bt
    }
    else {
        et = y
    }
    rssg = quadcross(et :* g, et :* g)
    sigcor = sqrt((1/xi2)*rssg/sum(g))
    return(indsat_which((!g)'))
}

real rowvector indsat_mstep(real colvector y, real matrix X, real scalar alpha, real scalar m, real scalar sigcor)
{
    real scalar n, k, c, psi, tau, xi2, it, s2
    real colvector b, e, g
    n = rows(y)
    k = cols(X)
    c = invnormal(1 - alpha/2)
    psi = 1 - alpha
    tau = psi - 2*c*normalden(c)
    xi2 = tau/psi
    g = J(n, 1, 1)
    b = indsat_lsgood(y, X, g)
    if (k>0) {
        e = y - X*b
    }
    else {
        e = y
    }
    s2 = quadcross(e, e)/(n - k)
    for (it=1; it<=m; it++) {
        g = abs(e) :<= c*sqrt(s2)
        b = indsat_lsgood(y, X, g)
        if (k>0) {
            e = y - X*b
        }
        else {
            e = y
        }
        s2 = (1/xi2)*quadcross(e :* g, e :* g)/sum(g)
    }
    sigcor = sqrt(s2)
    return(indsat_which((!g)'))
}

/* Nielsen-Qian (2025) split-half SIS, Algorithm 2.2 (forward differences) */
real rowvector indsat_splitsis(real colvector y, real matrix Z, real scalar alpha)
{
    real scalar n, n1, c, j, i, s2, om2, st, nz
    real rowvector Ij, Io, out
    real colvector yj, bj, ej, dz
    real matrix Zj, Szz
    n = rows(y)
    nz = cols(Z)
    c = invnormal(1 - alpha/2)
    n1 = floor(n/2)
    out = J(1, 0, .)
    for (j=1; j<=2; j++) {
        if (j==1) {
            Ij = (1..n1)
            Io = ((n1+1)..(n-1))
        }
        else {
            Ij = ((n1+1)..n)
            Io = (1..(n1-1))
        }
        yj = y[Ij'] :- mean(y[Ij'])
        if (nz>0) {
            Zj = Z[Ij', .] :- mean(Z[Ij', .])
            Szz = quadcross(Zj, Zj)
            bj = invsym(Szz)*quadcross(Zj, yj)
            ej = yj - Zj*bj
        }
        else {
            ej = yj
        }
        s2 = quadcross(ej, ej)/cols(Ij)
        for (i=1; i<=cols(Io); i++) {
            st = y[Io[i]] - y[Io[i]+1]
            om2 = 1
            if (nz>0) {
                dz = (Z[Io[i], .] - Z[Io[i]+1, .])'
                st = st - dz'*bj
                om2 = 1 + dz'*invsym(2*Szz)*dz
            }
            if (abs(st)/sqrt(2*s2*om2) >= c) {
                out = out, Io[i] + 1
            }
        }
    }
    return(indsat_sortrow(out))
}

/* ------------------------------------------------------------------
   Jiao-Pretis / Johansen-Nielsen gauge variance (gets::vargaugeiis)
------------------------------------------------------------------- */
real scalar indsat_vargauge(real scalar alpha, real scalar T, real scalar m)
{
    real scalar c, fc, psi, tau, chi, rho, k, m1, eta1, etag, viis
    c = abs(invnormal(alpha/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tau = psi - 2*c*fc
    chi = 3*psi - 2*c*(c^2 + 3)*fc
    rho = (c^2 - tau/psi)*c*fc/tau
    k = 3
    m1 = m - 1
    eta1 = (((1 - rho^m1)/((1 - rho)*tau))^2 + 2*((1 - rho^m1)/((1 - rho)*tau))*rho^m1)*(chi - tau^2/psi)/(k - 1) + rho^(2*m1)
    etag = (c*fc)^2*eta1*(k - 1) + 2*c*fc*rho^(m - 1)*(tau - psi)
    viis = psi*(1 - psi) + etag
    return(viis/T)
}

/* R stats::poisson.test two-sided p-value */
real scalar indsat_poistest(real scalar x, real scalar m)
{
    real scalar d, relErr, N, y, i
    if (m==0) {
        return(x==0)
    }
    relErr = 1 + 1e-7
    d = poissonp(m, x)
    if (x==m) {
        return(1)
    }
    if (x < m) {
        N = ceil(2*m - x)
        while (poissonp(m, N) > d) {
            N = 2*N
        }
        y = 0
        for (i=ceil(m); i<=N; i++) {
            if (poissonp(m, i) <= d*relErr) {
                y = y + 1
            }
        }
        return(min((1, poisson(m, x) + poissontail(m, N - y + 1))))
    }
    y = 0
    for (i=0; i<=floor(m); i++) {
        if (poissonp(m, i) <= d*relErr) {
            y = y + 1
        }
    }
    if (y - 1 < 0) {
        return(min((1, poissontail(m, x))))
    }
    return(min((1, poisson(m, y - 1) + poissontail(m, x))))
}

/* ==================================================================
   main driver
=================================================================== */
void indsat_main()
{
    real colvector y, tv, e, b, xb, bols, eols, sb
    real matrix X, mX, M, Mall, V, Vols, Xf, brk, Vk
    real rowvector types, fixflag, keepx, tau, shape, sel, meta_type, meta_tau, meta_base
    real rowvector spec, xsurv, ind, keepall, tauall, typall, baseall, kidx
    real scalar n, k, kx, cons, tp, vt, icm, ratio, maxb, nbu, maxp, tol, addb, alg, msteps
    real scalar nest, nblk, ty, j, jj, i, ll, rss, sigcor, sisdown, ok, df, tss, ybar, r2
    real scalar niis, nsis, ntis, nmis, nuis, nbis, ncand, nret, misj, lbq, c, fc, psi, tauc
    real scalar varsig, rho1, avar1, nrob, d, llols, rssols, xi, eta, rhob, varcorr
    real rowvector dg, nty, scl, sclall
    real scalar mbt
    string rowvector xn, xnt, mis, uis, cn, misn, pref, cn0
    string scalar fmt, blk, nm, retn, xret
    real rowvector mistemp_idx

    y = st_data(., st_local("ytemp"), st_local("touse"))
    n = rows(y)
    xnt = tokens(st_local("xtemp"))
    xn = tokens(st_local("xorig"))
    cons = strtoreal(st_local("cons"))
    if (cols(xnt)>0) {
        X = st_data(., xnt, st_local("touse"))
    }
    else {
        X = J(n, 0, .)
    }
    cn = xn
    fixflag = strtoreal(tokens(st_local("fixflag")))
    if (cols(fixflag)==0) {
        fixflag = J(1, 0, .)
    }
    if (cons==1) {
        X = X, J(n, 1, 1)
        cn = cn, "_cons"
        fixflag = fixflag, 1
    }
    tv = st_data(., st_local("tt"), st_local("touse"))
    fmt = st_local("tfmt")
    tp = strtoreal(st_local("tpval"))
    vt = strtoreal(st_local("vt"))
    icm = strtoreal(st_local("icm"))
    ratio = strtoreal(st_local("ratio"))
    maxb = strtoreal(st_local("maxblock"))
    nbu = strtoreal(st_local("blocks"))
    maxp = strtoreal(st_local("maxpaths"))
    tol = strtoreal(st_local("tol"))
    addb = (st_local("addblock")=="")
    alg = strtoreal(st_local("alg"))
    msteps = strtoreal(st_local("msteps"))
    sisdown = strtoreal(st_local("sisdown"))
    varcorr = (st_local("varcorr")!="")
    dg = strtoreal(tokens(st_local("dg")))
    types = strtoreal(tokens(st_local("types")))
    mis = tokens(st_local("mistemp"))
    misn = tokens(st_local("mis"))
    uis = tokens(st_local("uis"))
    shape = strtoreal(tokens(st_local("bisshape")))

    /* drop collinear regressors up front (keep order) */
    xsurv = indsat_dropvar(X, tol)
    if (cols(xsurv) < cols(X)) {
        printf("{txt}note: %g collinear regressor(s) dropped\n", cols(X)-cols(xsurv))
        X = indsat_cols(X, xsurv)
        cn = indsat_subs(cn, xsurv)
        fixflag = indsat_sub(fixflag, xsurv)
    }
    mX = X
    cn0 = cn
    kx = cols(mX)
    keepx = J(1, 0, .)
    for (j=1; j<=kx; j++) {
        keepx = keepx, j
    }

    nest = 0
    ncand = 0
    Mall = J(n, 0, .)
    sclall = J(1, 0, .)
    typall = J(1, 0, .)
    tauall = J(1, 0, .)
    baseall = J(1, 0, .)
    blk = ""
    sigcor = .

    /* -------------------------------------------------- selection */
    for (i=1; i<=cols(types); i++) {
        ty = types[i]
        if (ty==4) {
            for (jj=1; jj<=cols(mis); jj++) {
                xb = st_data(., mis[jj], st_local("touse"))
                M = indsat_makeM(4, n, 0, xb, shape, tau)
                ncand = ncand + cols(M)
                misj = indsat_findname(cn, misn[jj])
                if (alg==1) {
                    mbt = maxb
                    if (mbt<=0) {
                        mbt = 30
                    }
                    sel = indsat_isblock(y, mX, M, ratio, mbt, nbu, keepx, tp, vt, icm, dg, maxp, tol, addb, nest, nblk)
                    blk = blk + sprintf("MIS(%s):%g ", misn[jj], nblk)
                }
                indsat_appendsel(Mall, typall, tauall, baseall, M, sel, tau, 4, misj)
                sclall = sclall, J(1, cols(sel), 1)
            }
            continue
        }
        if (ty==5) {
            M = st_data(., uis, st_local("touse"))
            tau = J(1, cols(M), .)
            for (j=1; j<=cols(M); j++) {
                tau[j] = indsat_firstnz(M[., j])
            }
        }
        else {
            if (ty==10) {
                M = indsat_makeM(ty, n, sisdown, J(n, 1, 1), strtoreal(st_local("pis")), tau)
            }
            else {
                M = indsat_makeM(ty, n, sisdown, J(n, 1, 1), shape, tau)
            }
        }
        scl = J(1, cols(M), 1)
        if (ty==3 | ty==7 | ty==8) {
            for (j=1; j<=cols(M); j++) {
                scl[j] = max(abs(M[., j]))
                if (scl[j]>0) {
                    M[., j] = M[., j]/scl[j]
                }
                else {
                    scl[j] = 1
                }
            }
        }
        ncand = ncand + cols(M)
        mbt = maxb
        if (mbt<=0) {
            mbt = 30
            if (ty==7) {
                mbt = 15
            }
            if (ty==8) {
                mbt = 8
            }
        }
        if (alg==1) {
            sel = indsat_isblock(y, mX, M, ratio, mbt, nbu, keepx, tp, vt, icm, dg, maxp, tol, addb, nest, nblk)
            pref = ("IIS", "SIS", "TIS", "MIS", "UIS", "BIS", "QIS", "CIS", "DIS", "PIS")
            blk = blk + sprintf("%s:%g ", pref[ty], nblk)
        }
        if (alg==2) {
            if (ty==1) {
                sel = indsat_splitiis(y, mX, tp, sigcor)
            }
            else {
                sel = indsat_splitsis(y, indsat_nocons(mX, cn), tp)
                if (sisdown==1) {
                    sel = sel :- 1
                }
                else {
                    sel = sel :- 1
                }
            }
            nest = nest + 3
        }
        if (alg==3) {
            sel = indsat_mstep(y, mX, tp, msteps, sigcor)
            nest = nest + msteps + 1
        }
        indsat_appendsel(Mall, typall, tauall, baseall, M, sel, tau, ty, 0)
        for (j=1; j<=cols(sel); j++) {
            sclall = sclall, scl[sel[j]]
        }
    }

    /* -------------------------------------------------- union GETS */
    if (alg==1) {
        keepall = keepx
        if (st_local("select")!="") {
            keepall = indsat_which(fixflag)
        }
        if (cols(Mall)>0 | st_local("select")!="") {
            sel = J(1, 0, .)
            for (j=1; j<=cols(Mall); j++) {
                sel = sel, j
            }
            if (kx + cols(Mall) >= n) {
                sel = indsat_addblock(y, mX, Mall, sel, keepx, tp, vt, icm, dg, maxp, tol, nest)
            }
            spec = indsat_gets_dv(y, (mX, indsat_cols(Mall, sel)), keepall, tp, vt, icm, dg, maxp, tol, nest)
            xsurv = J(1, 0, .)
            ind = J(1, 0, .)
            for (j=1; j<=cols(spec); j++) {
                if (spec[j]<=kx) {
                    xsurv = xsurv, spec[j]
                }
                else {
                    ind = ind, sel[spec[j]-kx]
                }
            }
        }
        else {
            /* gets runs the final GETS on the regressors alone (all kept): one estimation */
            xsurv = keepx
            ind = J(1, 0, .)
            nest = nest + 1
        }
    }
    else {
        xsurv = keepx
        ind = J(1, 0, .)
        for (j=1; j<=cols(Mall); j++) {
            ind = ind, j
        }
        if (cols(Mall)>0) {
            kidx = indsat_dropvar((mX, Mall), tol)
            ind = J(1, 0, .)
            for (j=1; j<=cols(kidx); j++) {
                if (kidx[j]>kx) {
                    ind = ind, kidx[j]-kx
                }
            }
        }
    }

    /* -------------------------------------------------- common break dates */
    if (st_local("common")!="" & alg==1 & cols(ind)>0) {
        indsat_common(y, mX, xsurv, Mall, typall, tauall, baseall, sclall, ind, tp, vt, sisdown, anyof(types, 2), mis, st_local("touse"), nest)
    }

    /* -------------------------------------------------- final model */
    Xf = indsat_cols(mX, xsurv)
    if (cols(ind)>0) {
        Xf = Xf, indsat_cols(Mall, ind)
    }
    k = cols(Xf)
    ok = indsat_ols(y, Xf, vt, b, V, ll, rss, e)
    if (ok==0) {
        errprintf("final model could not be estimated (singular design)\n")
        exit(error(498))
    }
    df = n - k
    for (j=1; j<=cols(ind); j++) {
        jj = cols(xsurv) + j
        if (sclall[ind[j]]!=1) {
            b[jj] = b[jj]/sclall[ind[j]]
            V[jj, .] = V[jj, .]/sclall[ind[j]]
            V[., jj] = V[., jj]/sclall[ind[j]]
            Xf[., jj] = Xf[., jj]*sclall[ind[j]]
        }
    }

    /* names */
    retn = ""
    xret = ""
    cn = indsat_subs(cn, xsurv)
    for (j=1; j<=cols(cn); j++) {
        if (cn[j]!="_cons") {
            xret = xret + " " + cn[j]
        }
    }
    nty = J(1, 10, 0)
    pref = ("iis", "sis", "tis", "mis", "uis", "bis", "qis", "cis", "dis", "pis")
    brk = J(cols(ind), 7, .)
    for (j=1; j<=cols(ind); j++) {
        ty = typall[ind[j]]
        d = tauall[ind[j]]
        nty[ty] = nty[ty] + 1
        nm = pref[ty] + indsat_tlab(tv[d], fmt)
        if (ty==4) {
            nm = "mis" + substr(ustrregexra(cn0[baseall[ind[j]]], "[^A-Za-z0-9_]", ""), 1, 12) + "_" + indsat_tlab(tv[d], fmt)
        }
        if (ty==5) {
            nm = uis[baseall[ind[j]]]
        }
        nm = substr(nm, 1, 32)
        cn = cn, nm
        retn = retn + " " + nm
        brk[j, 1] = ty
        brk[j, 2] = d
        brk[j, 3] = tv[d]
        brk[j, 4] = b[cols(xsurv)+j]
        brk[j, 5] = sqrt(V[cols(xsurv)+j, cols(xsurv)+j])
        brk[j, 6] = brk[j, 4]/brk[j, 5]
        brk[j, 7] = 2*ttail(df, abs(brk[j, 6]))
    }
    nret = cols(ind)

    /* Johansen-Nielsen variance corrections (gets::isatvarcorrect) */
    c = abs(invnormal(tp/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tauc = psi - 2*c*fc
    xi = 1/sqrt(tauc/psi)
    rhob = 2*c*fc/psi
    eta = sqrt((((1 - rhob^1)/((1 - rhob)*psi))^2 + 2*(1 - rhob^1)/((1 - rhob)*psi)*rhob^1)*tauc + rhob^(2))
    if (varcorr==1 & anyof(types, 1)) {
        V = V*xi^2
        for (j=1; j<=cols(xsurv); j++) {
            for (jj=1; jj<=cols(xsurv); jj++) {
                V[j, jj] = V[j, jj]*eta^2
            }
        }
        for (j=1; j<=cols(ind); j++) {
            brk[j, 5] = sqrt(V[cols(xsurv)+j, cols(xsurv)+j])
            brk[j, 6] = brk[j, 4]/brk[j, 5]
            brk[j, 7] = 2*ttail(df, abs(brk[j, 6]))
        }
    }
    if (varcorr==1 & sigcor>=.) {
        sigcor = sqrt(rss/df)*xi
    }

    /* fit */
    ybar = mean(y)
    tss = quadcross(y :- ybar, y :- ybar)
    if (cons==0) {
        tss = quadcross(y, y)
    }
    r2 = 1 - rss/tss

    st_matrix(st_local("bmat"), b')
    st_matrix(st_local("Vmat"), V)
    st_global("r(colnames)", indsat_join(cn))
    st_numscalar("r(df_r)", df)
    st_numscalar("r(N)", n)
    st_numscalar("r(rss)", rss)
    st_numscalar("r(tss)", tss)
    st_numscalar("r(ll)", ll)
    st_numscalar("r(sigma)", sqrt(rss/df))
    st_numscalar("r(r2)", r2)
    st_numscalar("r(r2_a)", 1 - (1 - r2)*(n - cons)/df)
    st_numscalar("r(icval)", indsat_icval(ll, n, k, icm))
    st_numscalar("r(nest)", nest)
    st_numscalar("r(ncand)", ncand)
    st_numscalar("r(nret)", nret)
    for (j=1; j<=10; j++) {
        st_numscalar("r(n" + pref[j] + ")", nty[j])
    }
    st_numscalar("r(k_x)", cols(tokens(xret)))
    st_numscalar("r(nblk)", .)
    st_numscalar("r(sigcor)", sigcor)
    st_numscalar("r(xi)", xi)
    st_numscalar("r(eta)", eta)
    st_global("r(retnames)", strtrim(retn))
    if (nret==0) {
        st_global("r(retnames)", "")
    }
    st_global("r(xret)", strtrim(xret))
    st_global("r(blkinfo)", strtrim(blk))

    /* residual diagnostics as printed by gets (AR(q), ARCH(1), JB) */
    lbq = 1
    if (st_local("ar")!="") {
        lbq = max(strtoreal(tokens(st_local("ar"))))
    }
    st_numscalar("r(lb_ar)", indsat_lbstat(e, lbq))
    st_numscalar("r(lb_ar_df)", lbq)
    st_numscalar("r(lb_ar_p)", chi2tail(lbq, indsat_lbstat(e, lbq)))
    st_numscalar("r(lb_arch)", indsat_lbstat(e:^2, 1))
    st_numscalar("r(lb_arch_df)", 1)
    st_numscalar("r(lb_arch_p)", chi2tail(1, indsat_lbstat(e:^2, 1)))
    st_numscalar("r(jb)", indsat_jbstat(e))
    st_numscalar("r(jb_p)", chi2tail(2, indsat_jbstat(e)))

    /* Jiao-Pretis outlier tests: IIS only, as in gets::isat */
    st_numscalar("r(op_z)", .)
    st_numscalar("r(dist_chi2)", .)
    if (cols(types)==1 & types[1]==1 & st_local("outliertests")=="") {
        niis = nty[1]
        d = (niis/n - tp)/sqrt(indsat_vargauge(tp, n, 1))
        st_numscalar("r(op_z)", d)
        st_numscalar("r(op_p)", 2*normal(-abs(d)))
        st_numscalar("r(op_count)", niis)
        st_numscalar("r(op_count_p)", indsat_poistest(niis, tp*n))
        /* distortion test (gets::distorttest, coef="all") */
        if (cols(xsurv)>0) {
            ok = indsat_ols(y, indsat_cols(mX, xsurv), vt, bols, Vols, llols, rssols, eols)
            varsig = tauc/psi
            rho1 = psi^2/(4*(c^2)*(fc^2) + 4*tauc*c*fc + tauc)
            avar1 = ((2*c*fc - psi)^2 + 2*tauc*(2*c*fc - psi) + tauc)/psi^2
            nrob = n - nret
            Vk = V[|1, 1 \ cols(xsurv), cols(xsurv)|]
            Vk = (nrob/n)*(1/rho1)*(1/varsig)*Vk
            sb = b[|1 \ cols(xsurv)|] - bols
            if (max(abs(sb))>0) {
                d = n*sb'*invsym(avar1*n*rho1*Vk)*sb
            }
            else {
                d = 0
            }
            st_numscalar("r(dist_chi2)", d)
            st_numscalar("r(dist_df)", cols(xsurv))
            st_numscalar("r(dist_p)", chi2tail(cols(xsurv), d))
        }
    }

    if (nret==0) {
        brk = J(1, 7, .)
        retn = "none"
    }
    st_matrix("__isat_brk", brk)
    st_matrixrowstripe("__isat_brk", (J(rows(brk), 1, ""), tokens(retn)'))
    st_matrixcolstripe("__isat_brk", (J(7, 1, ""), ("type", "obs", "time", "coef", "se", "t", "p")'))
    st_matrix("__isat_X", Xf)
    st_matrixcolstripe("__isat_X", (J(k, 1, ""), cn'))
    st_matrix("__isat_t", tv)
    st_matrix("__isat_res", (y, y - e, e))
    st_matrixcolstripe("__isat_res", (J(3, 1, ""), ("y", "fitted", "resid")'))
}

/* Common break dates across step-type indicators (SIS and MIS):
   candidate dates = dates of retained SIS/MIS indicators (adjacent dates merged);
   each date contributes a block {S_tau, x_k S_tau (k in MIS)}; blocks are removed by
   backward elimination on their Wald F-test (OxRegimes RgSaturation::JointSelection) */
void indsat_common(real colvector y, real matrix mX, real rowvector xsurv, real matrix Mall,
    real rowvector typall, real rowvector tauall, real rowvector baseall, real rowvector sclall,
    real rowvector ind, real scalar tp, real scalar vt, real scalar sisdown, real scalar hassis,
    string rowvector mis, string scalar touse, real scalar nest)
{
    real rowvector cand, other, alive, merged, cidx
    real matrix K, W, Bk, V, Xm, Mn
    real colvector b, e, S, bb
    real scalar n, j, k, nb, ok, ll, rss, pmax, jmax, q, F, p, df, st, nmis, kk, tau
    real rowvector newtyp, newtau, newbase
    pointer(real matrix) rowvector blocks
    n = rows(y)
    cand = J(1, 0, .)
    other = J(1, 0, .)
    for (j=1; j<=cols(ind); j++) {
        if (typall[ind[j]]==2 | typall[ind[j]]==4) {
            cand = indsat_union(cand, J(1, 1, tauall[ind[j]]))
        }
        else {
            other = other, ind[j]
        }
    }
    if (cols(cand)==0) {
        return
    }
    cand = indsat_sortrow(cand)
    /* a regime between two dates must contain at least q observations (q = parameters per
       date block); closer dates are merged into the earlier one (OxRegimes merge rule) */
    q = cols(mis) + hassis
    merged = cand[1]
    for (j=2; j<=cols(cand); j++) {
        if (cand[j] - merged[cols(merged)] >= max((2, q))) {
            merged = merged, cand[j]
        }
    }
    cand = merged
    nmis = cols(mis)
    Xm = J(n, 0, .)
    if (nmis>0) {
        Xm = st_data(., mis, touse)
    }
    nb = cols(cand)
    blocks = J(1, nb, NULL)
    for (j=1; j<=nb; j++) {
        tau = cand[j]
        S = J(n, 1, 0)
        if (sisdown==1 & hassis==1) {
            S[|1 \ tau|] = J(tau, 1, 1)
        }
        else {
            S[|tau \ n|] = J(n - tau + 1, 1, 1)
        }
        Bk = J(n, 0, .)
        if (hassis==1) {
            Bk = Bk, S
        }
        for (k=1; k<=nmis; k++) {
            Bk = Bk, Xm[., k] :* (J(n, 1, 0) + ((1::n) :>= tau))
        }
        blocks[j] = &(Bk :* 1)
    }
    K = indsat_cols(mX, xsurv)
    if (cols(other)>0) {
        K = K, indsat_cols(Mall, other)
    }
    alive = J(1, nb, 1)
    while (1) {
        W = K
        cidx = J(1, nb, .)
        for (j=1; j<=nb; j++) {
            if (alive[j]==1) {
                cidx[j] = cols(W) + 1
                W = W, *blocks[j]
            }
        }
        if (sum(alive)==0) {
            break
        }
        ok = indsat_ols(y, W, vt, b, V, ll, rss, e)
        nest = nest + 1
        if (ok==0) {
            break
        }
        df = n - cols(W)
        pmax = -1
        jmax = 0
        for (j=1; j<=nb; j++) {
            if (alive[j]==1) {
                q = cols(*blocks[j])
                bb = b[|cidx[j] \ cidx[j] + q - 1|]
                F = (bb'*invsym(V[|cidx[j], cidx[j] \ cidx[j] + q - 1, cidx[j] + q - 1|])*bb)/q
                p = Ftail(q, df, F)
                if (p > pmax) {
                    pmax = p
                    jmax = j
                }
            }
        }
        if (pmax <= tp) {
            break
        }
        alive[jmax] = 0
    }
    /* rebuild the indicator set: other retained indicators + all indicators at surviving dates */
    Mn = indsat_cols(Mall, other)
    newtyp = indsat_sub(typall, other)
    newtau = indsat_sub(tauall, other)
    newbase = indsat_sub(baseall, other)
    for (j=1; j<=nb; j++) {
        if (alive[j]==1) {
            kk = 0
            if (hassis==1) {
                kk = kk + 1
                Mn = Mn, (*blocks[j])[., kk]
                newtyp = newtyp, 2
                newtau = newtau, cand[j]
                newbase = newbase, 0
            }
            for (k=1; k<=nmis; k++) {
                kk = kk + 1
                Mn = Mn, (*blocks[j])[., kk]
                newtyp = newtyp, 4
                newtau = newtau, cand[j]
                newbase = newbase, indsat_misbaseidx(k)
            }
        }
    }
    Mall = Mn
    typall = newtyp
    tauall = newtau
    baseall = newbase
    sclall = J(1, cols(Mn), 1)
    ind = J(1, 0, .)
    for (j=1; j<=cols(Mn); j++) {
        ind = ind, j
    }
    st_numscalar("r(ncommon)", sum(alive))
}

real scalar indsat_misbaseidx(real scalar k)
{
    string rowvector cn, misn
    real scalar j
    cn = tokens(st_local("xorig"))
    misn = tokens(st_local("mis"))
    for (j=1; j<=cols(cn); j++) {
        if (cn[j]==misn[k]) {
            return(j)
        }
    }
    return(1)
}

void indsat_appendsel(real matrix Mall, real rowvector typall, real rowvector tauall,
    real rowvector baseall, real matrix M, real rowvector sel, real rowvector tau,
    real scalar ty, real scalar base)
{
    real scalar j
    for (j=1; j<=cols(sel); j++) {
        Mall = Mall, M[., sel[j]]
        typall = typall, ty
        tauall = tauall, tau[sel[j]]
        baseall = baseall, base
    }
}

real scalar indsat_firstnz(real colvector x)
{
    real scalar t
    for (t=1; t<=rows(x); t++) {
        if (x[t]!=0) {
            return(t)
        }
    }
    return(1)
}

real scalar indsat_findname(string rowvector cn, string scalar s)
{
    real scalar j
    for (j=1; j<=cols(cn); j++) {
        if (cn[j]==s) {
            return(j)
        }
    }
    return(1)
}

string rowvector indsat_subs(string rowvector a, real rowvector idx)
{
    string rowvector out
    real scalar i
    out = J(1, cols(idx), "")
    for (i=1; i<=cols(idx); i++) {
        out[i] = a[idx[i]]
    }
    return(out)
}

real matrix indsat_nocons(real matrix X, string rowvector cn)
{
    real rowvector idx
    real scalar j
    idx = J(1, 0, .)
    for (j=1; j<=cols(cn); j++) {
        if (cn[j]!="_cons") {
            idx = idx, j
        }
    }
    return(indsat_cols(X, idx))
}

string scalar indsat_join(string rowvector s)
{
    string scalar out
    real scalar j
    out = ""
    for (j=1; j<=cols(s); j++) {
        out = out + " " + s[j]
    }
    return(strtrim(out))
}

end
