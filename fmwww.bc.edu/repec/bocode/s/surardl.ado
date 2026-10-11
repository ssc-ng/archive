*! surardl 1.0.1  10oct2026
*! Seemingly unrelated ARDL (SUR-ARDL) cointegration: estimation,
*! bounds testing and cross-equation inference
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! github.com/merwanroudane
*!
*! Implements Arif & Furuoka (2026), "Seemingly Unrelated Cointegrating
*! Regressions with Autoregressive Distributed Lag Dynamics", embedding
*! the Pesaran, Shin & Smith (2001) conditional error-correction model
*! in a Zellner (1962) SUR system.
*!
*! Step -> equation map (full map: help surardl methods)
*!   conditional ECM design .................. eq. (7), (12)-(15)
*!   equation-by-equation OLS ................ eq. (18)
*!   contemporaneous covariance Sigma-hat .... eq. (55)-(56)
*!   two-step / iterated FGLS ................ eq. (50)-(53), (57)-(58)
*!   equation bounds restriction matrix ...... eq. (61)-(64)
*!   bounds F via Wald form .................. eq. (76)-(77), (112)
*!   bounds F via restricted-system RSS ...... eq. (69)-(76)
*!   joint / subset bounds test .............. eq. (65)-(67), (78)-(79)
*!   long-run coefficients ................... eq. (82)-(84)
*!   delta-method standard errors ............ eq. (85)-(91)
*!   cross-equation long-run hypotheses ...... eq. (92)-(93), Remark 10
*!   efficiency gain ......................... eq. (95)
*!   Breusch-Pagan LM test ................... eq. (96)-(99)
*!   Pesaran CD test ......................... eq. (100)
*!   bounds decision rule .................... eq. (118)
*!   tabulated critical values ............... PSS (2001) Tables CI, CII
*!                                             Narayan (2005)
*!   simulated bounds (Approach A) ........... section 2.4, Approach A
*!   residual bootstrap (Approach B) ......... section 2.4, Approach B,
*!                                             implemented following
*!                                             McNown, Sam & Goh (2018)
*!                                             and Palm, Smeekes &
*!                                             Urbain (2010)

program define surardl, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "surardl") error 301
        syntax [, Level(cilevel) noCTable noHEader noLRtable noBOUNDS ///
                  noDIAGnostics ]
        _sa_display, level(`level') `ctable' `header' `lrtable' ///
            `bounds' `diagnostics'
        exit
    }

    syntax varlist(min=2 numeric ts) [if] [in] [,          ///
        LAGs(numlist integer >=0)                          ///
        MAXLags(numlist integer >=0)                       ///
        LAGMatrix(name)                                    ///
        aic bic MAXCombs(integer 20000) QMIN(integer 1)    ///
        CASe(integer 3) noCONstant trend restricted        ///
        TRENDVar(varname numeric)                          ///
        METHod(string) ITERate(integer 200)                 ///
        TOLerance(real 1e-9)                               ///
        SIGmadf(string) small Level(cilevel)               ///
        Fstat(string)                                      ///
        BOOTstrap(integer 0) SEED(string)                  ///
        BOOTTarget(string) BOOTDgp(string)                 ///
        BOOTLags(integer 1) NODRift                        ///
        SIMulate(integer 0) SIMRho(real 0)                 ///
        BGLags(integer 1)                                  ///
        EQnames(string)                                    ///
        noCTable noHEader noLRtable noBOUNDS               ///
        noDIAGnostics                                      ///
        GRaph GRAPHName(string) dots ]

    * ---------------------------------------------------------------
    * panel and time identifiers
    * ---------------------------------------------------------------
    capture qui xtset
    if _rc {
        di as error "data are not xtset"
        di as error "{p 4 4 2}surardl needs a long panel: each panel is one equation of the system.{p_end}"
        di as error "{p 4 4 2}Use {bf:xtset panelvar timevar} first.{p_end}"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local delta = r(tdelta)
    if ("`ivar'" == "" | "`tvar'" == "") {
        di as error "surardl requires both a panel and a time variable in xtset"
        exit 459
    }
    if (`delta' >= .) local delta 1

    gettoken depvar xvars : varlist
    local K : word count `xvars'

    * ---------------------------------------------------------------
    * deterministic case
    * ---------------------------------------------------------------
    local csgiven 0
    foreach o in constant trend restricted {
        if ("``o''" != "") local csgiven 1
    }
    if (`csgiven') {
        local cs 3
        if ("`constant'" != "") local cs 1
        if ("`trend'" != "")    local cs 5
        if ("`restricted'" != "") {
            if ("`trend'" != "")    local cs 4
            else if ("`constant'" == "") local cs 2
            else {
                di as error "restricted may not be combined with noconstant"
                exit 198
            }
        }
        if ("`constant'" != "" & "`trend'" != "") {
            di as error "noconstant may not be combined with trend"
            exit 198
        }
        local case `cs'
    }
    if (!inrange(`case', 1, 5)) {
        di as error "case() must be an integer between 1 and 5"
        exit 198
    }
    if ("`trendvar'" != "" & `case' < 4) {
        di as error "trendvar() requires case(4) or case(5) (or option trend)"
        exit 198
    }

    * ---------------------------------------------------------------
    * estimation method
    * ---------------------------------------------------------------
    if ("`method'" == "") local method twostep
    local method = lower("`method'")
    if ("`method'" == "sur") local method twostep
    if ("`method'" == "isure") local method iterated
    if (!inlist("`method'", "twostep", "iterated", "ols")) {
        di as error "method() must be twostep, iterated or ols"
        exit 198
    }
    local doiter 0
    local dools  0
    if ("`method'" == "iterated") local doiter `iterate'
    if ("`method'" == "ols")      local dools 1

    if ("`sigmadf'" == "") local sigmadf t
    local sigmadf = lower("`sigmadf'")
    if ("`sigmadf'" == "t")        local dfk 0
    else if ("`sigmadf'" == "dfmax") local dfk 1
    else if ("`sigmadf'" == "dfk")   local dfk 2
    else if ("`sigmadf'" == "dfk2")  local dfk 3
    else {
        di as error "sigmadf() must be t, dfmax, dfk or dfk2"
        exit 198
    }

    if ("`fstat'" == "") local fstat wald
    local fstat = lower("`fstat'")
    if ("`fstat'" == "wald")        local rssform 0
    else if ("`fstat'" == "rss")    local rssform 1
    else if ("`fstat'" == "rssall") local rssform 2
    else {
        di as error "fstat() must be wald, rss or rssall"
        exit 198
    }

    * ---------------------------------------------------------------
    * bootstrap / simulation settings
    * ---------------------------------------------------------------
    if ("`boottarget'" == "") local boottarget equation
    local boottarget = lower("`boottarget'")
    if ("`boottarget'" == "equation")      local btarget 1
    else if ("`boottarget'" == "joint")    local btarget 0
    else {
        di as error "boottarget() must be equation or joint"
        exit 198
    }
    if ("`bootdgp'" == "") local bootdgp rw
    local bootdgp = lower("`bootdgp'")
    if ("`bootdgp'" == "vecm")      local bdgp 1
    else if ("`bootdgp'" == "rw")   local bdgp 0
    else {
        di as error "bootdgp() must be vecm or rw"
        exit 198
    }
    if ("`seed'" == "") local bseed 20261010
    else {
        capture confirm integer number `seed'
        if _rc {
            di as error "seed() must be an integer"
            exit 198
        }
        local bseed `seed'
    }
    if (`bootlags' < 0) local bootlags 0
    local bndrift 0
    if ("`nodrift'" != "") local bndrift 1
    if (`simrho' < -1 | `simrho' > 1) {
        di as error "simrho() must lie between 0 and 1"
        exit 198
    }

    * ---------------------------------------------------------------
    * sample
    * ---------------------------------------------------------------
    marksample touse
    markout `touse' `depvar' `xvars' `ivar' `tvar'
    if ("`trendvar'" != "") markout `touse' `trendvar'

    tempvar nok
    qui bysort `tvar' : egen double `nok' = total(`touse')

    qui levelsof `ivar' if `touse', local(idlist)
    local N : word count `idlist'
    if (`N' < 2) {
        di as error "surardl needs at least 2 panels (equations); found `N'"
        exit 2001
    }

    * complete periods: every panel observed with no missing values
    tempvar okt
    qui gen byte `okt' = (`nok' == `N')
    qui levelsof `tvar' if `okt' & `touse', local(tlist)
    local nT : word count `tlist'
    if (`nT' < 5) {
        di as error "fewer than 5 periods are complete across all `N' panels"
        exit 2001
    }

    * longest contiguous run of complete periods
    local best 0
    local bt0 .
    local bt1 .
    local run 0
    local r0 .
    local prev .
    foreach t of local tlist {
        if (`prev' == . ) {
            local run 1
            local r0 `t'
        }
        else if (abs(`t' - `prev' - `delta') < 1e-8) {
            local run = `run' + 1
        }
        else {
            local run 1
            local r0 `t'
        }
        if (`run' > `best') {
            local best `run'
            local bt0 `r0'
            local bt1 `t'
        }
        local prev `t'
    }
    local Tfull `best'
    local ngap  = `nT' - `Tfull'

    tempvar use2
    qui gen byte `use2' = `touse' & `okt' & inrange(`tvar', `bt0', `bt1')

    * ---------------------------------------------------------------
    * lag orders
    * ---------------------------------------------------------------
    tempname LAGS QMAX
    local dosel 0
    if ("`lagmatrix'" != "") {
        capture confirm matrix `lagmatrix'
        if _rc {
            di as error "matrix `lagmatrix' not found"
            exit 111
        }
        if (rowsof(`lagmatrix') != `N' | colsof(`lagmatrix') != `=`K'+1') {
            di as error "lagmatrix() must be `N' x `=`K'+1' (p, q1, ..., q`K' by panel)"
            exit 503
        }
        matrix `LAGS' = `lagmatrix'
    }
    else if ("`maxlags'" != "") {
        local dosel 1
        local nm : word count `maxlags'
        if (`nm' == 1) {
            local pmax : word 1 of `maxlags'
            matrix `QMAX' = J(1, `K', `pmax')
        }
        else if (`nm' == `=`K'+1') {
            local pmax : word 1 of `maxlags'
            matrix `QMAX' = J(1, `K', 0)
            forvalues k = 1/`K' {
                local v : word `=`k'+1' of `maxlags'
                matrix `QMAX'[1, `k'] = `v'
            }
        }
        else {
            di as error "maxlags() must contain 1 or `=`K'+1' numbers"
            exit 198
        }
        if (`pmax' < 1) {
            di as error "the maximum lag order for `depvar' must be at least 1"
            exit 198
        }
        if ("`aic'" != "" & "`bic'" != "") {
            di as error "only one of aic and bic may be specified"
            exit 198
        }
        local crit 2
        if ("`aic'" != "") local crit 1
    }
    else {
        if ("`lags'" == "") local lags 1
        local nl : word count `lags'
        matrix `LAGS' = J(`N', `=`K'+1', 1)
        if (`nl' == 1) {
            local p : word 1 of `lags'
            matrix `LAGS' = J(`N', `=`K'+1', `p')
        }
        else if (`nl' == `=`K'+1') {
            forvalues j = 1/`=`K'+1' {
                local v : word `j' of `lags'
                forvalues i = 1/`N' {
                    matrix `LAGS'[`i', `j'] = `v'
                }
            }
        }
        else {
            di as error "lags() must contain 1 or `=`K'+1' numbers"
            exit 198
        }
        if (`LAGS'[1, 1] < 1) {
            di as error "the lag order p for `depvar' must be at least 1"
            exit 198
        }
    }

    * ---------------------------------------------------------------
    * equation names
    * ---------------------------------------------------------------
    local eqnm ""
    if ("`eqnames'" != "") {
        local ne : word count `eqnames'
        if (`ne' != `N') {
            di as error "eqnames() must supply `N' names, one per panel"
            exit 198
        }
        foreach nm of local eqnames {
            local eqnm "`eqnm' `=strtoname("`nm'")'"
        }
    }
    else {
        local vl : value label `ivar'
        foreach id of local idlist {
            local lab ""
            if ("`vl'" != "") local lab : label `vl' `id', strict
            if ("`lab'" == "") local lab "`ivar'_`id'"
            local eqnm "`eqnm' `=strtoname("`lab'")'"
        }
    }
    local eqnm = trim("`eqnm'")

    * ---------------------------------------------------------------
    * trend values: 1 at the first estimation observation
    * ---------------------------------------------------------------
    tempname TR IDS
    mata: st_matrix("`IDS'", strtoreal(tokens(st_local("idlist")))')
    if ("`trendvar'" != "") {
        tempvar tvv
        qui gen double `tvv' = `trendvar'
        mata: _sa_trendvar("`tvv'", "`use2'", "`tvar'", `bt0', `delta', ///
              `Tfull', "`TR'")
    }
    else {
        mata: st_matrix("`TR'", (1 :: `Tfull'))
    }

    * ---------------------------------------------------------------
    * load the level series and run the engine
    * ---------------------------------------------------------------
    scalar __sa_N       = `N'
    scalar __sa_K       = `K'
    scalar __sa_case    = `case'
    scalar __sa_dfk     = `dfk'
    scalar __sa_iterate = `doiter'
    scalar __sa_tol     = `tolerance'
    scalar __sa_level   = `level'
    scalar __sa_ols     = `dools'
    scalar __sa_rssform = `rssform'
    scalar __sa_bglags  = `bglags'
    scalar __sa_breps   = `bootstrap'
    scalar __sa_bseed   = `bseed'
    scalar __sa_btarget = `btarget'
    scalar __sa_bdgp    = `bdgp'
    scalar __sa_blags   = `bootlags'
    scalar __sa_bndrift = `bndrift'
    scalar __sa_sreps   = `simulate'
    scalar __sa_srho    = `simrho'
    scalar __sa_dosel   = `dosel'
    scalar __sa_rc      = 0
    scalar __sa_badeq   = 0
    scalar __sa_ncomb   = 0
    if (`dosel') {
        scalar __sa_pmax    = `pmax'
        scalar __sa_crit    = `crit'
        scalar __sa_qmin    = `qmin'
        scalar __sa_maxcomb = `maxcombs'
        matrix __sa_qmax    = `QMAX'
        matrix __sa_lags    = J(`N', `=`K'+1', 1)
    }
    else {
        matrix __sa_lags = `LAGS'
    }
    matrix __sa_TR = `TR'

    mata: st_numscalar("__sa_rcload", _surardl_load("`depvar' `xvars'",   ///
        "`use2'", "`ivar'", "`tvar'", st_matrix("`IDS'"), `bt0',          ///
        `delta', `Tfull', `K', "__sa_LV"))
    if (__sa_rcload != 0) {
        _sa_cleanup
        di as error "the estimation window is not balanced across panels"
        exit 459
    }

    local eqnames "`eqnm'"
    mata: _surardl_main()

    if (__sa_rc != 0) {
        local rc = __sa_rc
        local be = __sa_badeq
        _sa_cleanup
        if (`rc' == 459 & `be' > 0) {
            local nmbad : word `be' of `eqnm'
            di as error "equation `be' (`nmbad') has collinear regressors"
            di as error "{p 4 4 2}Reduce the lag orders, drop a regressor, or check for a constant series.{p_end}"
        }
        else if (`rc' == 459) {
            di as error "too many lag combinations; raise maxcombs() or lower maxlags()"
        }
        else {
            di as error "too few usable time periods for the requested specification"
        }
        exit `rc'
    }

    * ---------------------------------------------------------------
    * post results
    * ---------------------------------------------------------------
    local T  = __sa_T
    local M  = __sa_M
    local L  = `Tfull' - `T'
    local t0e = `bt0' + `L' * `delta'

    tempvar esamp
    qui gen byte `esamp' = `use2' & inrange(`tvar', `t0e', `bt1')
    qui count if `esamp'
    local nobs = r(N)

    tempname b V
    matrix `b' = __sa_b
    matrix `V' = __sa_V

    ereturn post `b' `V', esample(`esamp') depname(`depvar') obs(`nobs')

    ereturn scalar N        = `nobs'
    ereturn scalar T        = `T'
    ereturn scalar N_eq     = `N'
    ereturn scalar N_g      = `N'
    ereturn scalar k_x      = `K'
    ereturn scalar M        = `M'
    ereturn scalar case     = `case'
    ereturn scalar level    = `level'
    ereturn scalar n_gaps   = `ngap'
    ereturn scalar tmin     = `t0e'
    ereturn scalar tmax     = `bt1'
    ereturn scalar lvl_t0   = `bt0'
    ereturn scalar delta    = `delta'
    ereturn scalar iterations = __sa_nit
    ereturn scalar converged  = __sa_conv
    ereturn scalar df_q     = __sa_bnd[1, 4]

    tempname JT BP SD
    matrix `JT' = __sa_joint
    ereturn scalar chi2_joint = `JT'[1, 1]
    ereturn scalar df_joint   = `JT'[1, 2]
    ereturn scalar F_joint    = `JT'[1, 3]
    ereturn scalar p_joint    = `JT'[1, 4]

    matrix `BP' = __sa_bpcd
    ereturn scalar bp     = `BP'[1, 1]
    ereturn scalar bp_df  = `BP'[1, 2]
    ereturn scalar bp_p   = `BP'[1, 3]
    ereturn scalar cd     = `BP'[1, 4]
    ereturn scalar cd_p   = `BP'[1, 5]
    ereturn scalar avg_absr = `BP'[1, 6]

    matrix `SD' = __sa_sigdiag
    ereturn scalar sig_rcond = `SD'[1, 4]
    ereturn scalar sig_mineig = `SD'[1, 5]
    ereturn scalar sig_pd    = `SD'[1, 6]
    ereturn scalar sig_rfn   = `SD'[1, 8]
    ereturn scalar TN        = `SD'[1, 3]

    if (`bootstrap' > 0) {
        ereturn scalar reps   = `bootstrap'
        ereturn scalar seed   = `bseed'
        ereturn scalar bfail  = __sa_bfail
    }
    if (`simulate' > 0) {
        ereturn scalar simreps = `simulate'
        ereturn scalar sfail   = __sa_sfail
        ereturn scalar simrho  = `simrho'
    }
    if (`dosel') {
        ereturn scalar numcombs = __sa_ncomb
    }

    ereturn local cmd       "surardl"
    ereturn local cmdline   `"surardl `0'"'
    ereturn local title     "Seemingly unrelated ARDL error-correction model"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`xvars'"
    ereturn local ivar      "`ivar'"
    ereturn local tvar      "`tvar'"
    ereturn local eqnames   "`eqnm'"
    ereturn local ids       "`idlist'"
    ereturn local method    "`method'"
    ereturn local sigmadf   "`sigmadf'"
    ereturn local fstat     "`fstat'"
    ereturn local small     "`small'"

    if (`case' == 1) local detname "no constant, no trend"
    if (`case' == 2) local detname "restricted constant, no trend"
    if (`case' == 3) local detname "unrestricted constant, no trend"
    if (`case' == 4) local detname "unrestricted constant, restricted trend"
    if (`case' == 5) local detname "unrestricted constant, unrestricted trend"
    ereturn local det "`detname'"

    local selname ""
    if (`dosel') {
        local selname "bic"
        if (`crit' == 1) local selname "aic"
    }
    ereturn local lagsel "`selname'"

    if (`bootstrap' > 0) {
        ereturn local boottarget "`boottarget'"
        ereturn local bootdgp    "`bootdgp'"
    }
    ereturn local predict   "surardl_p"
    ereturn local estat_cmd "surardl_estat"
    ereturn local properties "b V"
    ereturn local marginsnotok "_ALL"

    ereturn matrix lags     = __sa_lagsout
    ereturn matrix Sigma    = __sa_Sigma
    ereturn matrix Corr     = __sa_Corr
    ereturn matrix bounds   = __sa_bnd
    ereturn matrix longrun  = __sa_lr
    ereturn matrix fieller  = __sa_fieller
    ereturn matrix eqfit    = __sa_fit
    ereturn matrix efficiency = __sa_eff
    ereturn matrix cvF      = __sa_cvF
    ereturn matrix cvt      = __sa_cvt
    ereturn matrix cvN      = __sa_cvN
    ereturn matrix decF     = __sa_decF
    ereturn matrix decN     = __sa_decN
    ereturn matrix dect     = __sa_dect
    ereturn matrix sigdiag  = __sa_sigdiag
    ereturn matrix bpcd     = __sa_bpcd
    ereturn matrix resid    = __sa_resid
    ereturn matrix residols = __sa_residols
    ereturn matrix lv       = __sa_LV
    ereturn matrix tr       = __sa_TR
    if (`bglags' > 0)    ereturn matrix bgodfrey = __sa_bg
    if (`rssform' > 0)   ereturn matrix Frss     = __sa_Frss
    if (`bootstrap' > 0) {
        ereturn matrix bootcv   = __sa_bcv
        ereturn matrix bootp    = __sa_bpv
        ereturn matrix bootdist = __sa_bdist
    }
    if (`simulate' > 0) {
        ereturn matrix simcv1 = __sa_scv1
        ereturn matrix simcv0 = __sa_scv0
    }

    _sa_cleanup

    * ---------------------------------------------------------------
    * display
    * ---------------------------------------------------------------
    _sa_display, level(`level') `ctable' `header' `lrtable' `bounds' ///
        `diagnostics'

    if ("`graph'" != "") {
        surardl_estat graph, `graphname'
    }
end

* -------------------------------------------------------------------
* helpers
* -------------------------------------------------------------------
program define _sa_cleanup
    foreach m in LV TR lags lagsout qmax b V Sigma Corr bnd lr fieller   ///
                 fit eff cvF cvt cvN decF decN dect sigdiag bpcd resid    ///
                 residols bg Frss bcv bpv bdist scv1 scv0 joint {
        capture matrix drop __sa_`m'
    }
    foreach s in N K case dfk iterate tol level ols rssform bglags breps  ///
                 bseed btarget bdgp blags bndrift sreps srho dosel rc    ///
                 badeq ncomb                                             ///
                 pmax crit qmin maxcomb T M nit conv bfail sfail rcload {
        capture scalar drop __sa_`s'
    }
end

* -------------------------------------------------------------------
* Display: journal-style tables built by hand (not ereturn display)
* -------------------------------------------------------------------
program define _sa_display
    syntax [, Level(cilevel) noCTable noHEader noLRtable noBOUNDS ///
              noDIAGnostics ]

    local N    = e(N_eq)
    local K    = e(k_x)
    local T    = e(T)
    local case = e(case)
    local dep  "`e(depvar)'"
    local xv   "`e(indepvars)'"
    local eqn  "`e(eqnames)'"
    local small "`e(small)'"

    tempname LAGS FIT BND LR FI CVF CVT CVN DF DN DT SG BP BG BCV BPV S1 S0 EFF
    matrix `LAGS' = e(lags)
    matrix `FIT'  = e(eqfit)
    matrix `BND'  = e(bounds)
    matrix `LR'   = e(longrun)
    matrix `FI'   = e(fieller)
    matrix `CVF'  = e(cvF)
    matrix `CVT'  = e(cvt)
    matrix `CVN'  = e(cvN)
    matrix `DF'   = e(decF)
    matrix `DN'   = e(decN)
    matrix `DT'   = e(dect)
    matrix `SG'   = e(sigdiag)
    matrix `BP'   = e(bpcd)
    matrix `EFF'  = e(efficiency)

    * ===============================================================
    * header
    * ===============================================================
    if ("`header'" == "") {
        di ""
        di as text "{hline 80}"
        di as text "Seemingly unrelated ARDL (SUR-ARDL) error-correction model"
        di as text "{hline 80}"
        local mname "Two-step feasible GLS (Zellner SUR)"
        if ("`e(method)'" == "iterated") local mname "Iterated FGLS (converges to ML)"
        if ("`e(method)'" == "ols")      local mname "Equation-by-equation OLS (benchmark)"
        di as text %-42s "`mname'"  _col(44) as text "Equations     = " as result %8.0f `N'
        di as text %-42s "Dependent variable: D.`dep'" _col(44) as text "Time periods  = " as result %8.0f `T'
        di as text %-42s "Case `case': `e(det)'" _col(44) as text "Observations  = " as result %8.0f e(N)
        di as text %-42s "Panel: `e(ivar)'   Time: `e(tvar)'" _col(44) as text "Parameters    = " as result %8.0f e(M)
        local lagtxt = "ARDL(" + "`=`LAGS'[1,1]'"
        forvalues k = 1/`K' {
            local lagtxt "`lagtxt',`=`LAGS'[1,`k'+1]'"
        }
        local lagtxt "`lagtxt')"
        local homog 1
        forvalues i = 2/`N' {
            forvalues j = 1/`=`K'+1' {
                if (`LAGS'[`i',`j'] != `LAGS'[1,`j']) local homog 0
            }
        }
        if (`homog' == 0) local lagtxt "unit-specific (see e(lags))"
        if ("`e(lagsel)'" != "") local lagtxt "`lagtxt', selected by `=upper("`e(lagsel)'")'"
        di as text %-42s "Lag structure: `lagtxt'" _col(44) as text "Restrictions  = " as result %8.0f e(df_q)
        if (e(n_gaps) > 0) {
            di as text "{p 0 2 2}Note: `=e(n_gaps)' complete period(s) outside the longest contiguous window were dropped.{p_end}"
        }
        if ("`e(method)'" == "iterated") {
            if (e(converged) == 0) {
                di as text "{p 0 2 2}Warning: iteration did not converge in `=e(iterations)' steps.{p_end}"
            }
            else {
                di as text "{p 0 2 2}Converged in `=e(iterations)' iterations.{p_end}"
            }
        }
    }

    * ===============================================================
    * coefficient table, grouped ADJ / LR / SR as in the EC form
    * ===============================================================
    if ("`ctable'" == "") {
        di ""
        di as text "{hline 80}"
        di as text "Conditional error-correction estimates     " _col(44) "D.`dep' is the dependent variable"
        di as text "{hline 80}"
        di as text "             {c |}       Coef.    Std. err.      " _continue
        if ("`small'" != "") di as text "t   P>|t|     [" %2.0f `level' "% conf. interval]"
        else                 di as text "z   P>|z|     [" %2.0f `level' "% conf. interval]"

        local M = e(M)
        tempname b V
        matrix `b' = e(b)
        matrix `V' = e(V)
        local cn : colnames `b'
        local ce : coleq `b'

        forvalues i = 1/`N' {
            local nm : word `i' of `eqn'
            local dfi = `FIT'[`i', 4]
            di as text "{hline 13}{c +}{hline 66}"
            di as text %-12s abbrev("`nm'", 12) " {c |}"
            * ADJ block
            di as text "         ADJ {c |}"
            _sa_coefrow `b' `V' "`ce'" "`cn'" "`nm'" "L.`dep'" `level' `dfi' "`small'"
            * LR block (lagged levels)
            di as text "          LR {c |}"
            foreach x of local xv {
                _sa_coefrow `b' `V' "`ce'" "`cn'" "`nm'" "L.`x'" `level' `dfi' "`small'"
            }
            * SR block (everything else)
            di as text "          SR {c |}"
            local j 1
            foreach c of local cn {
                local eq : word `j' of `ce'
                if ("`eq'" == "`nm'") {
                    local islev 0
                    if ("`c'" == "L.`dep'") local islev 1
                    foreach x of local xv {
                        if ("`c'" == "L.`x'") local islev 1
                    }
                    if (`islev' == 0) {
                        _sa_coefrow `b' `V' "`ce'" "`cn'" "`nm'" "`c'" `level' `dfi' "`small'"
                    }
                }
                local j = `j' + 1
            }
        }
        di as text "{hline 13}{c BT}{hline 66}"
        di as text "{p 0 2 2}ADJ: speed of adjustment, eq. (8). LR: lagged level terms whose ratio to ADJ gives the long-run coefficients, eq. (82). SR: short-run dynamics and deterministic terms.{p_end}"
    }

    * ===============================================================
    * long-run coefficients
    * ===============================================================
    if ("`lrtable'" == "") {
        di ""
        di as text "{hline 80}"
        di as text "Long-run coefficients  theta = -beta/lambda   (delta method, eq. 82-91)"
        di as text "{hline 80}"
        di as text "                         Coef.   Std. err.      z   P>|z|      [" %2.0f `level' "% conf. int.]"
        di as text "{hline 80}"
        forvalues i = 1/`N' {
            local nm : word `i' of `eqn'
            di as text %-24s abbrev("`nm'", 24)
            forvalues k = 1/`K' {
                local r = (`i'-1)*`K' + `k'
                local x : word `k' of `xv'
                local th = `LR'[`r', 3]
                local se = `LR'[`r', 4]
                local zz = `LR'[`r', 5]
                local pp = `LR'[`r', 6]
                local lo = `LR'[`r', 7]
                local hi = `LR'[`r', 8]
                _sa_stars `pp'
                di as text "  " %-20s abbrev("`x'", 20) as result ///
                   %11.4f `th' "  " %10.4f `se' " " %7.2f `zz' " " %6.3f `pp' ///
                   " " %10.4f `lo' " " %10.4f `hi' as text " `r(stars)'"
            }
        }
        di as text "{hline 80}"
        di as text "{p 0 2 2}Significance: * p<0.10, ** p<0.05, *** p<0.01.{p_end}"
        di as text "{p 0 2 2}Simulation 5 of the paper documents severe under-coverage of the delta-method interval when |lambda| is small or T is moderate. Use {bf:estat longrun, fieller} for the Fieller (1954) set, which does not divide by lambda, or {bf:estat longrun, bootstrap(#)}.{p_end}"
    }

    * ===============================================================
    * bounds test
    * ===============================================================
    if ("`bounds'" == "") {
        local haveb = ("`e(boottarget)'" != "")
        if (`haveb') {
            matrix `BCV' = e(bootcv)
            matrix `BPV' = e(bootp)
        }
        local haves = (e(simreps) != . & e(simreps) > 0)
        if (`haves') {
            matrix `S1' = e(simcv1)
            matrix `S0' = e(simcv0)
        }
        di ""
        di as text "{hline 80}"
        di as text "SUR bounds test for a long-run level relationship      H0: lambda_i = beta_i = 0"
        di as text "{hline 80}"
        di as text "                        F        t      " _continue
        if (`haveb') di as text "p(boot)   decision (10%/5%/1%)"
        else         di as text "         decision (10%/5%/1%)"
        di as text "{hline 80}"
        forvalues i = 1/`N' {
            local nm : word `i' of `eqn'
            local Fi = `BND'[`i', 1]
            local ti = `BND'[`i', 3]
            local d10 = `DF'[`i', 1]
            local d05 = `DF'[`i', 2]
            local d01 = `DF'[`i', 4]
            _sa_dec `d10'
            local s10 "`r(d)'"
            _sa_dec `d05'
            local s05 "`r(d)'"
            _sa_dec `d01'
            local s01 "`r(d)'"
            if (`haveb') {
                di as text %-20s abbrev("`nm'", 20) as result %9.3f `Fi' " " %8.3f `ti' ///
                   "  " %7.3f `BPV'[`i',1] as text "   `s10'  `s05'  `s01'"
            }
            else {
                di as text %-20s abbrev("`nm'", 20) as result %9.3f `Fi' " " %8.3f `ti' ///
                   as text "           `s10'  `s05'  `s01'"
            }
        }
        di as text "{hline 80}"
        di as text "Pesaran, Shin & Smith (2001) asymptotic bounds, case `case', k = `K':"
        di as text "              10%            5%           2.5%            1%"
        di as text "   F   " _continue
        forvalues j = 1/4 {
            di as result %7.2f `CVF'[`j',1] "/" %-6.2f `CVF'[`j',2] _continue
        }
        di ""
        di as text "   t   " _continue
        forvalues j = 1/4 {
            di as result %7.2f `CVT'[`j',1] "/" %-6.2f `CVT'[`j',2] _continue
        }
        di ""
        if (`CVN'[1,1] < .) {
            di as text "Narayan (2005) small-sample bounds, n = `T':"
            di as text "              10%            5%             1%"
            di as text "   F   " _continue
            forvalues j = 1/3 {
                di as result %7.2f `CVN'[`j',1] "/" %-6.2f `CVN'[`j',2] _continue
            }
            di ""
        }
        if (`haveb') {
            di as text "SUR residual-bootstrap critical values for F (`e(reps)' reps, seed `e(seed)', `e(boottarget)' null, `e(bootdgp)' marginal DGP):"
            di as text "                       10%        5%        1%     p-value"
            forvalues i = 1/`N' {
                local nm : word `i' of `eqn'
                di as text "   " %-18s abbrev("`nm'", 18) as result ///
                   %9.3f `BCV'[`i',1] " " %9.3f `BCV'[`i',2] " " %9.3f `BCV'[`i',3] ///
                   "  " %9.3f `BPV'[`i',1]
            }
            if (e(bfail) > 0) {
                di as text "{p 3 5 2}Note: `=e(bfail)' replication(s) failed and were discarded.{p_end}"
            }
        }
        if (`haves') {
            di as text "SUR simulated bounds for F (`e(simreps)' reps): I(0) lower / I(1) upper"
            di as text "                        10%            5%             1%"
            forvalues i = 1/`N' {
                local nm : word `i' of `eqn'
                di as text "   " %-18s abbrev("`nm'", 18) as result ///
                   %7.2f `S0'[`i',1] "/" %-6.2f `S1'[`i',1] ///
                   %7.2f `S0'[`i',2] "/" %-6.2f `S1'[`i',2] ///
                   %7.2f `S0'[`i',3] "/" %-6.2f `S1'[`i',3]
            }
        }
        di as text "{hline 80}"
        di as text "Joint test across all `N' equations (eq. 78-79): " _continue
        di as result "F = " %7.3f e(F_joint) as text "  chi2(" %2.0f e(df_joint) ") = " ///
           as result %8.3f e(chi2_joint) as text "  p = " as result %6.4f e(p_joint)
        di as text "{p 0 2 2}Decision codes: {bf:R} reject (above the I(1) bound), {bf:-} inconclusive, {bf:N} no rejection (below the I(0) bound), {bf:.} bounds unavailable.{p_end}"
        if (`haveb' == 0 & `haves' == 0) {
            di as text "{p 0 2 2}{bf:Note:} the PSS and Narayan bounds above are calibrated for the {it:single-equation OLS} F statistic. The SUR statistic has a more dispersed null distribution in small samples, because Sigma is estimated jointly, so these bounds are liberal here. For SUR-specific values use {bf:bootstrap(}#{bf:)} (data-tailored, recommended) or {bf:simulate(}#{bf:)} (I(0)/I(1) bounds).{p_end}"
        }
        if (`N' >= 5 & `BP'[1,6] >= 0.5) {
            di as text "{p 0 2 2}{bf:Caution:} with N = `N' and mean |correlation| = " %4.2f `BP'[1,6] ", Simulation 2 of the paper puts the size distortion at its worst. Bootstrap critical values are not optional here.{p_end}"
        }
        if ("`e(fstat)'" != "wald") {
            di as text "{p 0 2 2}F reported from the restricted-system RSS form (eq. 73-76), fstat(`e(fstat)').{p_end}"
        }
    }

    * ===============================================================
    * diagnostics
    * ===============================================================
    if ("`diagnostics'" == "") {
        di ""
        di as text "{hline 80}"
        di as text "Diagnostics"
        di as text "{hline 80}"
        di as text "Cross-sectional dependence of the OLS residuals (justifies the SUR step):"
        di as text "   Breusch-Pagan LM (eq. 96-99)  chi2(" %3.0f `BP'[1,2] ") = " ///
           as result %9.4f `BP'[1,1] as text "   p = " as result %6.4f `BP'[1,3]
        di as text "   Pesaran CD (eq. 100)                      = " ///
           as result %9.4f `BP'[1,4] as text "   p = " as result %6.4f `BP'[1,5]
        di as text "   Mean absolute off-diagonal correlation    = " as result %9.4f `BP'[1,6]
        if (`BP'[1,3] > 0.10) {
            di as text "{p 3 5 2}The LM test does not reject a diagonal Sigma. By Proposition 1 the SUR estimator then offers no efficiency gain over equation-by-equation OLS.{p_end}"
        }
        di as text "Covariance matrix Sigma-hat (`=`SG'[1,1]' x `=`SG'[1,1]'):"
        di as text "   T/N ratio                                 = " as result %9.3f `SG'[1,3]
        di as text "   Reciprocal condition number               = " as result %9.3e `SG'[1,4]
        di as text "   Positive definite                         = " as result %9s cond(`SG'[1,6]==1, "yes", "NO")
        di as text "   Relative Frobenius norm of off-diagonal   = " as result %9.4f `SG'[1,8]
        if (`SG'[1,3] < 5) {
            di as text "{p 3 5 2}Warning: T/N < 5. Section 2.3 of the paper warns that Sigma-hat is estimated imprecisely in this regime.{p_end}"
        }
        capture matrix `BG' = e(bgodfrey)
        if (_rc == 0) {
            di as text "Breusch-Godfrey LM test on the SUR residuals (Assumption 1(iii), Remark 5):"
            di as text "                          LM       df        p"
            forvalues i = 1/`N' {
                local nm : word `i' of `eqn'
                local pb = `BG'[`i',3]
                local flag ""
                if (`pb' < 0.05) local flag "  <- serial correlation at 5%"
                di as text "   " %-18s abbrev("`nm'", 18) as result %10.4f `BG'[`i',1] ///
                   " " %7.0f `BG'[`i',2] " " %8.4f `pb' as text "`flag'"
            }
            di as text "{p 3 5 2}If the null is rejected, raise the ARDL lag orders until the conditional errors are serially uncorrelated; Sigma rather than a long-run covariance is the correct weight only then (Remark 4).{p_end}"
        }
        * speed of adjustment sign check
        local nneg 0
        forvalues i = 1/`N' {
            tempname bb
            matrix `bb' = e(b)
            local nm : word `i' of `eqn'
            local lam = _b[`nm':L.`dep']
            if (`lam' >= 0) {
                local nneg = `nneg' + 1
                di as text "{p 3 5 2}Warning: lambda = " %6.3f `lam' " >= 0 for `nm'; the error-correction mechanism is not stable, so no valid long-run relationship exists for that unit whatever the F statistic shows (section 2.5).{p_end}"
            }
        }
        di as text "{hline 80}"
    }
end

program define _sa_coefrow
    args b V ce cn nm cname level dfr small

    local j 1
    local pos 0
    foreach c of local cn {
        local eq : word `j' of `ce'
        if ("`eq'" == "`nm'" & "`c'" == "`cname'") local pos `j'
        local j = `j' + 1
    }
    if (`pos' == 0) exit

    local bb = `b'[1, `pos']
    local vv = `V'[`pos', `pos']
    if (`vv' <= 0) exit
    local se = sqrt(`vv')
    local zz = `bb' / `se'
    if ("`small'" != "") {
        local pp = 2 * ttail(`dfr', abs(`zz'))
        local cv = invttail(`dfr', (1 - `level'/100)/2)
    }
    else {
        local pp = 2 * normal(-abs(`zz'))
        local cv = invnormal(1 - (1 - `level'/100)/2)
    }
    local lo = `bb' - `cv' * `se'
    local hi = `bb' + `cv' * `se'
    _sa_stars `pp'
    di as text %12s abbrev("`cname'", 12) " {c |}" as result ///
       %11.4f `bb' " " %11.4f `se' " " %7.2f `zz' " " %6.3f `pp' " " ///
       %10.4f `lo' " " %10.4f `hi' as text " `r(stars)'"
end

program define _sa_stars, rclass
    args p
    local s "   "
    if (`p' < 0.10) local s "*  "
    if (`p' < 0.05) local s "** "
    if (`p' < 0.01) local s "***"
    return local stars "`s'"
end

program define _sa_dec, rclass
    args d
    local s "."
    if (`d' == 0) local s "N"
    if (`d' == 1) local s "-"
    if (`d' == 2) local s "R"
    return local d "`s'"
end

* -------------------------------------------------------------------
* Mata library.
*
* Stata compiles this block into a namespace private to this ado-file,
* so the same library is carried by surardl.ado and surardl_estat.ado.
* Edit the _sa_*.mata sources and re-run build.py; do not edit here.
* -------------------------------------------------------------------
version 14.0

mata:

// ================================================================
// from _sa_cv.mata
// ================================================================

// ------------------------------------------------------------------
// Pesaran, Shin & Smith (2001), Table CI: asymptotic critical value
// bounds for the bounds F statistic. Rows are k = 0..10; the returned
// 4 x 2 matrix has rows 10%, 5%, 2.5%, 1% and columns I(0), I(1).
// ------------------------------------------------------------------
real matrix _surardl_cvF_pss(real scalar cs, real scalar k)
{
    real matrix T
    real rowvector r

    if (cs == 1) {
        T = (
            3, 3, 4.2, 4.2, 5.47, 5.47, 7.17, 7.17 \
            2.44, 3.28, 3.15, 4.11, 3.88, 4.92, 4.81, 6.02 \
            2.17, 3.19, 2.72, 3.83, 3.22, 4.5, 3.88, 5.3 \
            2.01, 3.1, 2.45, 3.63, 2.87, 4.16, 3.42, 4.84 \
            1.9, 3.01, 2.26, 3.48, 2.62, 3.9, 3.07, 4.44 \
            1.81, 2.93, 2.14, 3.34, 2.44, 3.71, 2.82, 4.21 \
            1.75, 2.87, 2.04, 3.24, 2.32, 3.59, 2.66, 4.05 \
            1.7, 2.83, 1.97, 3.18, 2.22, 3.49, 2.54, 3.91 \
            1.66, 2.79, 1.91, 3.11, 2.15, 3.4, 2.45, 3.79 \
            1.63, 2.75, 1.86, 3.05, 2.08, 3.33, 2.34, 3.68 \
            1.6, 2.72, 1.82, 2.99, 2.02, 3.27, 2.26, 3.6 )
    }
    if (cs == 2) {
        T = (
            3.8, 3.8, 4.6, 4.6, 5.39, 5.39, 6.44, 6.44 \
            3.02, 3.51, 3.62, 4.16, 4.18, 4.79, 4.94, 5.58 \
            2.63, 3.35, 3.1, 3.87, 3.55, 4.38, 4.13, 5 \
            2.37, 3.2, 2.79, 3.67, 3.15, 4.08, 3.65, 4.66 \
            2.2, 3.09, 2.56, 3.49, 2.88, 3.87, 3.29, 4.37 \
            2.08, 3, 2.39, 3.38, 2.7, 3.73, 3.06, 4.15 \
            1.99, 2.94, 2.27, 3.28, 2.55, 3.61, 2.88, 3.99 \
            1.92, 2.89, 2.17, 3.21, 2.43, 3.51, 2.73, 3.9 \
            1.85, 2.85, 2.11, 3.15, 2.33, 3.42, 2.62, 3.77 \
            1.8, 2.8, 2.04, 3.08, 2.24, 3.35, 2.5, 3.68 \
            1.76, 2.77, 1.98, 3.04, 2.18, 3.28, 2.41, 3.61 )
    }
    if (cs == 3) {
        T = (
            6.58, 6.58, 8.21, 8.21, 9.8, 9.8, 11.79, 11.79 \
            4.04, 4.78, 4.94, 5.73, 5.77, 6.68, 6.84, 7.84 \
            3.17, 4.14, 3.79, 4.85, 4.41, 5.52, 5.15, 6.36 \
            2.72, 3.77, 3.23, 4.35, 3.69, 4.89, 4.29, 5.61 \
            2.45, 3.52, 2.86, 4.01, 3.25, 4.49, 3.74, 5.06 \
            2.26, 3.35, 2.62, 3.79, 2.96, 4.18, 3.41, 4.68 \
            2.12, 3.23, 2.45, 3.61, 2.75, 3.99, 3.15, 4.43 \
            2.03, 3.13, 2.32, 3.5, 2.6, 3.84, 2.96, 4.26 \
            1.95, 3.06, 2.22, 3.39, 2.48, 3.7, 2.79, 4.1 \
            1.88, 2.99, 2.14, 3.3, 2.37, 3.6, 2.65, 3.97 \
            1.83, 2.94, 2.06, 3.24, 2.28, 3.5, 2.54, 3.86 )
    }
    if (cs == 4) {
        T = (
            5.37, 5.37, 6.29, 6.29, 7.14, 7.14, 8.26, 8.26 \
            4.05, 4.49, 4.68, 5.15, 5.3, 5.83, 6.1, 6.73 \
            3.38, 4.02, 3.88, 4.61, 4.37, 5.16, 4.99, 5.85 \
            2.97, 3.74, 3.38, 4.23, 3.8, 4.68, 4.3, 5.23 \
            2.68, 3.53, 3.05, 3.97, 3.4, 4.36, 3.81, 4.92 \
            2.49, 3.38, 2.81, 3.76, 3.11, 4.13, 3.5, 4.63 \
            2.33, 3.25, 2.63, 3.62, 2.9, 3.94, 3.27, 4.39 \
            2.22, 3.17, 2.5, 3.5, 2.76, 3.81, 3.07, 4.23 \
            2.13, 3.09, 2.38, 3.41, 2.62, 3.7, 2.93, 4.06 \
            2.05, 3.02, 2.3, 3.33, 2.52, 3.6, 2.79, 3.93 \
            1.98, 2.97, 2.21, 3.25, 2.42, 3.52, 2.68, 3.84 )
    }
    if (cs == 5) {
        T = (
            9.81, 9.81, 11.64, 11.64, 13.36, 13.36, 15.73, 15.73 \
            5.59, 6.26, 6.56, 7.3, 7.46, 8.27, 8.74, 9.63 \
            4.19, 5.06, 4.87, 5.85, 5.49, 6.59, 6.34, 7.52 \
            3.47, 4.45, 4.01, 5.07, 4.52, 5.62, 5.17, 6.36 \
            3.03, 4.06, 3.47, 4.57, 3.89, 5.07, 4.4, 5.72 \
            2.75, 3.79, 3.12, 4.25, 3.47, 4.67, 3.93, 5.23 \
            2.53, 3.59, 2.87, 4, 3.19, 4.38, 3.6, 4.9 \
            2.38, 3.45, 2.69, 3.83, 2.98, 4.16, 3.34, 4.63 \
            2.26, 3.34, 2.55, 3.68, 2.82, 4.02, 3.15, 4.43 \
            2.16, 3.24, 2.43, 3.56, 2.67, 3.87, 2.97, 4.24 \
            2.07, 3.16, 2.33, 3.46, 2.56, 3.76, 2.84, 4.1 )
    }

    if (k < 0 | k > 10) {
        return(J(4, 2, .))
    }
    r = T[k + 1, .]
    return((r[1], r[2] \ r[3], r[4] \ r[5], r[6] \ r[7], r[8]))
}

// ------------------------------------------------------------------
// Pesaran, Shin & Smith (2001), Table CII: asymptotic critical value
// bounds for the bounds t statistic on lambda. PSS tabulate cases I,
// III and V only. Because the deterministic restrictions are ignored
// for this single-coefficient test (Kripfganz & Schneider 2020, p.
// 1461), case II uses the case III bounds and case IV the case V ones.
// ------------------------------------------------------------------
real matrix _surardl_cvt_pss(real scalar cs, real scalar k)
{
    real matrix T
    real rowvector r
    real scalar c

    c = cs
    if (cs == 2) {
        c = 3
    }
    if (cs == 4) {
        c = 5
    }

    if (c == 1) {
        T = (
            -1.62, -1.62, -1.95, -1.95, -2.24, -2.24, -2.58, -2.58 \
            -1.62, -2.28, -1.95, -2.6, -2.24, -2.9, -2.58, -3.22 \
            -1.62, -2.68, -1.95, -3.02, -2.24, -3.31, -2.58, -3.66 \
            -1.62, -3, -1.95, -3.33, -2.24, -3.64, -2.58, -3.97 \
            -1.62, -3.26, -1.95, -3.6, -2.24, -3.89, -2.58, -4.23 \
            -1.62, -3.49, -1.95, -3.83, -2.24, -4.12, -2.58, -4.44 \
            -1.62, -3.7, -1.95, -4.04, -2.24, -4.34, -2.58, -4.67 \
            -1.62, -3.9, -1.95, -4.23, -2.24, -4.54, -2.58, -4.88 \
            -1.62, -4.09, -1.95, -4.43, -2.24, -4.72, -2.58, -5.07 \
            -1.62, -4.26, -1.95, -4.61, -2.24, -4.89, -2.58, -5.25 \
            -1.62, -4.42, -1.95, -4.76, -2.24, -5.06, -2.58, -5.44 )
    }
    if (c == 3) {
        T = (
            -2.57, -2.57, -2.86, -2.86, -3.13, -3.13, -3.43, -3.43 \
            -2.57, -2.91, -2.86, -3.22, -3.13, -3.5, -3.43, -3.82 \
            -2.57, -3.21, -2.86, -3.53, -3.13, -3.8, -3.43, -4.1 \
            -2.57, -3.46, -2.86, -3.78, -3.13, -4.05, -3.43, -4.37 \
            -2.57, -3.66, -2.86, -3.99, -3.13, -4.26, -3.43, -4.6 \
            -2.57, -3.86, -2.86, -4.19, -3.13, -4.46, -3.43, -4.79 \
            -2.57, -4.04, -2.86, -4.38, -3.13, -4.66, -3.43, -4.99 \
            -2.57, -4.23, -2.86, -4.57, -3.13, -4.85, -3.43, -5.19 \
            -2.57, -4.4, -2.86, -4.72, -3.13, -5.02, -3.43, -5.37 \
            -2.57, -4.56, -2.86, -4.88, -3.13, -5.18, -3.42, -5.54 \
            -2.57, -4.69, -2.86, -5.03, -3.13, -5.34, -3.43, -5.68 )
    }
    if (c == 5) {
        T = (
            -3.13, -3.13, -3.41, -3.41, -3.65, -3.66, -3.96, -3.97 \
            -3.13, -3.4, -3.41, -3.69, -3.65, -3.96, -3.96, -4.26 \
            -3.13, -3.63, -3.41, -3.95, -3.65, -4.2, -3.96, -4.53 \
            -3.13, -3.84, -3.41, -4.16, -3.65, -4.42, -3.96, -4.73 \
            -3.13, -4.04, -3.41, -4.36, -3.65, -4.62, -3.96, -4.96 \
            -3.13, -4.21, -3.41, -4.52, -3.65, -4.79, -3.96, -5.13 \
            -3.13, -4.37, -3.41, -4.69, -3.65, -4.96, -3.96, -5.31 \
            -3.13, -4.53, -3.41, -4.85, -3.65, -5.14, -3.96, -5.49 \
            -3.13, -4.68, -3.41, -5.01, -3.65, -5.3, -3.96, -5.65 \
            -3.13, -4.82, -3.41, -5.15, -3.65, -5.44, -3.96, -5.79 \
            -3.13, -4.96, -3.41, -5.29, -3.65, -5.59, -3.96, -5.94 )
    }

    if (k < 0 | k > 10) {
        return(J(4, 2, .))
    }
    r = T[k + 1, .]
    return((r[1], r[2] \ r[3], r[4] \ r[5], r[6] \ r[7], r[8]))
}

// ------------------------------------------------------------------
// Narayan (2005) small-sample critical value bounds for the bounds F
// statistic: cases II-V, effective sample size n = 30(5)80, k = 0..7,
// at the 10%, 5% and 1% levels, linearly interpolated in n. Column 1
// of each stored table is n; the remaining 48 columns run level-major
// (10%, 5%, 1%), then k = 0..7, then (I(0), I(1)).
//
// Two documented departures from the printed tables:
//  (a) case II, 10%, n = 80: the published I(0) entry for k = 5
//      repeats the k = 4 entry (2.303). It is replaced by 2.180, the
//      value printed for the same row on Narayan's case IV page.
//  (b) case IV, n = 80: all three published rows are verbatim copies
//      of the case II n = 80 rows and are evidently a typesetting
//      error. They are not stored, so case IV interpolation is
//      clamped at n = 75, which is mildly conservative.
// ------------------------------------------------------------------
real matrix _surardl_cvF_nar(real scalar cs, real scalar k, real scalar n)
{
    real matrix T, O
    real scalar i, nr, lo, hi, w, j
    real rowvector a, b

    if (cs < 2 | cs > 5 | k < 0 | k > 7) {
        return(J(3, 2, .))
    }

    if (cs == 2) {
        T = J(11, 49, .)
        T[1, .] = (30, 4.025, 4.025, 3.303, 3.797, 2.915, 3.695, 2.676, 3.586, 2.525, 3.56, 2.407, 3.517, 2.334, 3.515, 2.277, 3.498, 5.07, 5.07, 4.09, 4.663, 3.538, 4.428, 3.272, 4.306, 3.058, 4.223, 2.91, 4.193, 2.794, 4.148, 2.73, 4.163, 7.595, 7.595, 6.027, 6.76, 5.155, 6.265, 4.614, 5.966, 4.28, 5.84, 4.134, 5.761, 3.976, 5.691, 3.864, 5.694)
        T[2, .] = (35, 3.98, 3.98, 3.223, 3.757, 2.845, 3.623, 2.618, 3.532, 2.46, 3.46, 2.331, 3.417, 2.254, 3.388, 2.196, 3.37, 4.945, 4.945, 3.957, 4.53, 3.478, 4.335, 3.164, 4.194, 2.947, 4.088, 2.804, 4.013, 2.685, 3.96, 2.597, 3.907, 7.35, 7.35, 5.763, 6.48, 4.948, 6.028, 4.428, 5.816, 4.093, 5.532, 3.9, 5.419, 3.713, 5.326, 3.599, 5.23)
        T[3, .] = (40, 3.955, 3.955, 3.21, 3.73, 2.835, 3.585, 2.592, 3.454, 2.427, 3.395, 2.306, 3.353, 2.218, 3.314, 2.152, 3.296, 4.96, 4.96, 3.937, 4.523, 3.435, 4.26, 3.1, 4.088, 2.893, 4, 2.734, 3.92, 2.618, 3.863, 2.523, 3.829, 7.22, 7.22, 5.593, 6.333, 4.77, 5.855, 4.31, 5.544, 3.967, 5.455, 3.657, 5.256, 3.505, 5.121, 3.402, 5.031)
        T[4, .] = (45, 3.95, 3.95, 3.19, 3.73, 2.788, 3.54, 2.56, 3.428, 2.402, 3.345, 2.276, 3.297, 2.188, 3.254, 2.131, 3.223, 4.895, 4.895, 3.877, 4.46, 3.368, 4.203, 3.078, 4.022, 2.85, 3.905, 2.694, 3.829, 2.591, 3.766, 2.504, 3.723, 7.265, 7.265, 5.607, 6.193, 4.8, 5.725, 4.27, 5.412, 3.892, 5.173, 3.674, 5.019, 3.54, 4.931, 3.383, 4.832)
        T[5, .] = (50, 3.935, 3.935, 3.177, 3.653, 2.788, 3.513, 2.538, 3.398, 2.372, 3.32, 2.259, 3.264, 2.17, 3.22, 2.099, 3.181, 4.815, 4.815, 3.86, 4.44, 3.368, 4.178, 3.048, 4.002, 2.823, 3.872, 2.67, 3.781, 2.55, 3.708, 2.457, 3.65, 7.065, 7.065, 5.503, 6.24, 4.695, 5.758, 4.188, 5.328, 3.845, 5.15, 3.593, 4.981, 3.424, 4.88, 3.282, 4.73)
        T[6, .] = (55, 3.9, 3.9, 3.143, 3.67, 2.748, 3.495, 2.508, 3.356, 2.345, 3.28, 2.226, 3.241, 2.139, 3.204, 2.069, 3.148, 4.795, 4.795, 3.79, 4.393, 3.303, 4.1, 2.982, 3.942, 2.763, 3.813, 2.617, 3.743, 2.49, 3.658, 2.414, 3.608, 6.965, 6.965, 5.377, 6.047, 4.61, 5.563, 4.118, 5.2, 3.738, 4.947, 3.543, 4.839, 3.33, 4.708, 3.194, 4.562)
        T[7, .] = (60, 3.88, 3.88, 3.127, 3.65, 2.738, 3.465, 2.496, 3.346, 2.323, 3.273, 2.204, 3.21, 2.114, 3.153, 2.044, 3.104, 4.78, 4.78, 3.803, 4.363, 3.288, 4.07, 2.962, 3.91, 2.743, 3.792, 2.589, 3.683, 2.456, 3.598, 2.373, 3.54, 6.96, 6.96, 5.383, 6.033, 4.558, 5.59, 4.068, 5.25, 3.71, 4.965, 3.451, 4.764, 3.293, 4.615, 3.129, 4.507)
        T[8, .] = (65, 3.88, 3.88, 3.143, 3.623, 2.74, 3.455, 2.492, 3.35, 2.335, 3.252, 2.209, 3.201, 2.12, 3.145, 2.043, 3.094, 4.78, 4.78, 3.787, 4.343, 3.285, 4.07, 2.976, 3.896, 2.75, 3.755, 2.596, 3.677, 2.473, 3.583, 2.373, 3.519, 6.825, 6.825, 5.35, 6.017, 4.538, 5.475, 4.056, 5.158, 3.725, 4.94, 3.43, 4.721, 3.225, 4.571, 3.092, 4.478)
        T[9, .] = (70, 3.875, 3.875, 3.12, 3.623, 2.73, 3.445, 2.482, 3.31, 2.32, 3.232, 2.193, 3.161, 2.1, 3.121, 2.024, 3.079, 4.75, 4.75, 3.78, 4.327, 3.243, 4.043, 2.924, 3.86, 2.725, 3.718, 2.564, 3.65, 2.451, 3.559, 2.351, 3.498, 6.74, 6.74, 5.157, 5.957, 4.398, 5.463, 3.916, 5.088, 3.608, 4.86, 3.373, 4.717, 3.18, 4.596, 3.034, 4.426)
        T[10, .] = (75, 3.895, 3.895, 3.133, 3.597, 2.725, 3.455, 2.482, 3.334, 2.313, 3.228, 2.196, 3.166, 2.103, 3.111, 2.023, 3.068, 4.76, 4.76, 3.777, 4.32, 3.253, 4.065, 2.946, 3.862, 2.725, 3.718, 2.574, 3.641, 2.449, 3.55, 2.36, 3.478, 6.915, 6.915, 5.26, 5.957, 4.458, 5.41, 4.048, 5.092, 3.687, 4.842, 3.427, 4.62, 3.219, 4.526, 3.057, 4.413)
        T[11, .] = (80, 3.87, 3.87, 3.113, 3.61, 2.713, 3.453, 2.474, 3.312, 2.303, 3.22, 2.18, 3.154, 2.088, 3.103, 2.017, 3.052, 4.725, 4.725, 3.74, 4.303, 3.235, 4.053, 2.92, 3.838, 2.688, 3.698, 2.55, 3.606, 2.431, 3.518, 2.336, 3.458, 6.695, 6.695, 5.157, 5.917, 4.358, 5.393, 3.908, 5.004, 3.602, 4.787, 3.351, 4.587, 3.173, 4.485, 3.021, 4.35)
    }
    if (cs == 3) {
        T = J(11, 49, .)
        T[1, .] = (30, 6.84, 6.84, 4.29, 5.08, 3.437, 4.47, 3.008, 4.15, 2.752, 3.994, 2.578, 3.858, 2.457, 3.797, 2.384, 3.728, 8.77, 8.77, 5.395, 6.35, 4.267, 5.473, 3.71, 5.018, 3.354, 4.774, 3.125, 4.608, 2.97, 4.499, 2.875, 4.445, 13.68, 13.68, 8.17, 9.285, 6.183, 7.873, 5.333, 7.063, 4.768, 6.67, 4.537, 6.37, 4.27, 6.211, 4.104, 6.151)
        T[2, .] = (35, 6.81, 6.81, 4.225, 5.05, 3.393, 4.41, 2.958, 4.1, 2.696, 3.898, 2.508, 3.763, 2.387, 3.671, 2.3, 3.606, 8.64, 8.64, 5.29, 6.175, 4.183, 5.333, 3.615, 4.913, 3.276, 4.63, 3.037, 4.443, 2.864, 4.324, 2.753, 4.209, 13.29, 13.29, 7.87, 8.96, 6.14, 7.607, 5.198, 6.845, 4.59, 6.368, 4.257, 6.04, 4.016, 5.797, 3.841, 5.686)
        T[3, .] = (40, 6.76, 6.76, 4.235, 5, 3.373, 4.377, 2.933, 4.02, 2.66, 3.838, 2.483, 3.708, 2.353, 3.599, 2.26, 3.534, 8.57, 8.57, 5.26, 6.16, 4.133, 5.26, 3.548, 4.803, 3.202, 4.544, 2.962, 4.338, 2.797, 4.211, 2.676, 4.13, 13.07, 13.07, 7.625, 8.825, 5.893, 7.337, 5.018, 6.61, 4.428, 6.25, 4.045, 5.898, 3.8, 5.643, 3.644, 5.464)
        T[4, .] = (45, 6.76, 6.76, 4.225, 5.02, 3.33, 4.347, 2.893, 3.983, 2.638, 3.772, 2.458, 3.647, 2.327, 3.541, 2.238, 3.461, 8.59, 8.59, 5.235, 6.135, 4.083, 5.207, 3.535, 4.733, 3.178, 4.45, 2.922, 4.268, 2.764, 4.123, 2.643, 4.004, 12.93, 12.93, 7.74, 8.65, 5.92, 7.197, 4.983, 6.423, 4.394, 5.914, 4.03, 5.598, 3.79, 5.411, 3.595, 5.225)
        T[5, .] = (50, 6.74, 6.74, 4.19, 4.94, 3.333, 4.313, 2.873, 3.973, 2.614, 3.746, 2.435, 3.6, 2.309, 3.507, 2.205, 3.421, 8.51, 8.51, 5.22, 6.07, 4.07, 5.19, 3.5, 4.7, 3.136, 4.416, 2.9, 4.218, 2.726, 4.057, 2.593, 3.941, 12.73, 12.73, 7.56, 8.685, 5.817, 7.303, 4.865, 6.36, 4.306, 5.874, 3.955, 5.583, 3.656, 5.331, 3.498, 5.149)
        T[6, .] = (55, 6.7, 6.7, 4.155, 4.925, 3.28, 4.273, 2.843, 3.92, 2.578, 3.71, 2.393, 3.583, 2.27, 3.486, 2.181, 3.398, 8.39, 8.39, 5.125, 6.045, 3.987, 5.09, 3.408, 4.623, 3.068, 4.334, 2.848, 4.16, 2.676, 3.999, 2.556, 3.904, 12.7, 12.7, 7.435, 8.46, 5.707, 6.977, 4.828, 6.195, 4.244, 5.726, 3.928, 5.408, 3.636, 5.169, 3.424, 4.989)
        T[7, .] = (60, 6.7, 6.7, 4.145, 4.95, 3.27, 4.26, 2.838, 3.923, 2.568, 3.712, 2.385, 3.565, 2.253, 3.436, 2.155, 3.353, 8.46, 8.46, 5.125, 6, 4, 5.057, 3.415, 4.615, 3.062, 4.314, 2.817, 4.097, 2.643, 3.939, 2.513, 3.823, 12.49, 12.49, 7.4, 8.51, 5.697, 6.987, 4.748, 6.188, 4.176, 5.676, 3.783, 5.338, 3.531, 5.081, 3.346, 4.895)
        T[8, .] = (65, 6.74, 6.74, 4.175, 4.93, 3.3, 4.25, 2.843, 3.923, 2.574, 3.682, 2.397, 3.543, 2.256, 3.43, 2.156, 3.334, 8.49, 8.49, 5.13, 5.98, 4.01, 5.08, 3.435, 4.583, 3.068, 4.274, 2.835, 4.09, 2.647, 3.921, 2.525, 3.808, 12.4, 12.4, 7.32, 8.435, 5.583, 6.853, 4.69, 6.143, 4.188, 5.694, 3.783, 5.3, 3.501, 5.051, 3.31, 4.871)
        T[9, .] = (70, 6.67, 6.67, 4.125, 4.88, 3.25, 4.237, 2.818, 3.88, 2.552, 3.648, 2.363, 3.51, 2.233, 3.407, 2.138, 3.325, 8.37, 8.37, 5.055, 5.915, 3.947, 5.02, 3.37, 4.545, 3.022, 4.256, 2.788, 4.073, 2.629, 3.906, 2.494, 3.786, 12.24, 12.24, 7.17, 8.405, 5.487, 6.88, 4.635, 6.055, 4.098, 5.57, 3.747, 5.285, 3.436, 5.044, 3.261, 4.821)
        T[10, .] = (75, 6.72, 6.72, 4.15, 4.885, 3.277, 4.243, 2.838, 3.898, 2.558, 3.654, 2.38, 3.515, 2.244, 3.397, 2.134, 3.313, 8.42, 8.42, 5.14, 5.92, 3.983, 5.06, 3.408, 4.55, 3.042, 4.244, 2.802, 4.065, 2.637, 3.9, 2.503, 3.768, 12.54, 12.54, 7.225, 8.3, 5.513, 6.86, 4.725, 6.08, 4.168, 5.548, 3.772, 5.213, 3.496, 4.966, 3.266, 4.801)
        T[11, .] = (80, 6.72, 6.72, 4.135, 4.895, 3.26, 4.247, 2.823, 3.885, 2.548, 3.644, 2.355, 3.5, 2.236, 3.381, 2.129, 3.289, 8.4, 8.4, 5.06, 5.93, 3.94, 5.043, 3.363, 4.515, 3.01, 4.216, 2.787, 4.015, 2.627, 3.864, 2.476, 3.746, 12.12, 12.12, 7.095, 8.26, 5.407, 6.783, 4.568, 5.96, 4.096, 5.512, 3.725, 5.163, 3.457, 4.943, 3.233, 4.76)
    }
    if (cs == 4) {
        T = J(10, 49, .)
        T[1, .] = (30, 5.785, 5.785, 4.427, 4.957, 3.77, 4.535, 3.378, 4.274, 3.097, 4.118, 2.907, 4.01, 2.781, 3.941, 2.681, 3.887, 7.04, 7.04, 5.377, 5.963, 4.535, 5.415, 4.048, 5.09, 3.715, 4.878, 3.504, 4.743, 3.326, 4.653, 3.194, 4.604, 10.2, 10.2, 7.593, 8.35, 6.428, 7.505, 5.666, 6.988, 5.205, 6.64, 4.85, 6.473, 4.689, 6.358, 4.49, 6.328)
        T[2, .] = (35, 5.69, 5.69, 4.38, 4.867, 3.698, 4.42, 3.29, 4.176, 3.035, 3.997, 2.831, 3.879, 2.685, 3.785, 2.578, 3.71, 6.9, 6.9, 5.233, 5.777, 4.433, 5.245, 3.936, 4.918, 3.578, 4.668, 3.353, 4.5, 3.174, 4.383, 3.057, 4.319, 9.975, 9.975, 7.477, 8.213, 6.328, 7.408, 5.654, 6.926, 5.147, 6.617, 4.849, 6.511, 4.629, 5.698, 4.489, 5.064)
        T[3, .] = (40, 5.68, 5.68, 4.343, 4.823, 3.663, 4.378, 3.264, 4.094, 2.985, 3.918, 2.781, 3.813, 2.634, 3.719, 2.517, 3.65, 6.87, 6.87, 5.18, 5.733, 4.36, 5.138, 3.85, 4.782, 3.512, 4.587, 3.257, 4.431, 3.07, 4.309, 2.933, 4.224, 9.575, 9.575, 7.207, 7.86, 5.98, 6.973, 5.258, 6.526, 4.763, 6.2, 4.427, 5.837, 4.154, 5.699, 3.971, 5.486)
        T[4, .] = (45, 5.625, 5.625, 4.3, 4.78, 3.625, 4.33, 3.226, 4.054, 2.95, 3.862, 2.75, 3.739, 2.606, 3.644, 2.484, 3.57, 6.75, 6.75, 5.13, 5.68, 4.335, 5.078, 3.822, 4.714, 3.47, 4.47, 3.211, 4.309, 3.025, 4.198, 2.899, 4.087, 9.555, 9.555, 7.133, 7.82, 5.878, 6.87, 5.15, 6.28, 4.628, 5.865, 4.251, 5.596, 3.998, 5.463, 3.829, 5.313)
        T[5, .] = (50, 5.57, 5.57, 4.23, 4.74, 3.573, 4.288, 3.174, 4.004, 2.905, 3.822, 2.703, 3.697, 2.55, 3.609, 2.44, 3.523, 6.685, 6.685, 5.043, 5.607, 4.225, 5.03, 3.73, 4.666, 3.383, 4.432, 3.149, 4.293, 2.975, 4.143, 2.832, 4.012, 9.32, 9.32, 7.017, 7.727, 5.805, 6.79, 5.05, 6.182, 4.557, 5.793, 4.214, 5.52, 3.983, 5.345, 3.762, 5.172)
        T[6, .] = (55, 5.57, 5.57, 4.23, 4.73, 3.553, 4.238, 3.132, 3.956, 2.868, 3.782, 2.674, 3.659, 2.538, 3.56, 2.42, 3.481, 6.66, 6.66, 5.013, 5.547, 4.183, 4.955, 3.692, 4.582, 3.358, 4.365, 3.131, 4.206, 2.946, 4.065, 2.791, 3.95, 9.3, 9.3, 6.893, 7.537, 5.678, 6.578, 4.99, 6.018, 4.455, 5.615, 4.111, 5.329, 3.87, 5.171, 3.643, 5.021)
        T[7, .] = (60, 5.555, 5.555, 4.203, 4.693, 3.54, 4.235, 3.13, 3.968, 2.852, 3.773, 2.653, 3.637, 2.51, 3.519, 2.392, 3.444, 6.63, 6.63, 4.98, 5.527, 4.18, 4.938, 3.684, 4.584, 3.323, 4.333, 3.086, 4.154, 2.9, 3.999, 2.756, 3.892, 9.245, 9.245, 6.78, 7.377, 5.62, 6.503, 4.928, 5.95, 4.412, 5.545, 4.013, 5.269, 3.775, 5.086, 3.584, 4.922)
        T[8, .] = (65, 5.51, 5.51, 4.187, 4.66, 3.535, 4.208, 3.122, 3.942, 2.848, 3.743, 2.647, 3.603, 2.499, 3.49, 2.379, 3.406, 6.55, 6.55, 4.95, 5.467, 4.123, 4.903, 3.626, 4.538, 3.3, 4.28, 3.063, 4.123, 2.88, 3.978, 2.73, 3.879, 8.96, 8.96, 6.707, 7.36, 5.545, 6.453, 4.848, 5.842, 4.347, 5.552, 4.02, 5.263, 3.758, 5.04, 3.557, 4.902)
        T[9, .] = (70, 5.53, 5.53, 4.173, 4.647, 3.505, 4.198, 3.098, 3.92, 2.832, 3.738, 2.631, 3.589, 2.485, 3.473, 2.363, 3.394, 6.53, 6.53, 4.93, 5.457, 4.1, 4.9, 3.6, 4.512, 3.272, 4.272, 3.043, 4.1, 2.86, 3.951, 2.711, 3.842, 8.89, 8.89, 6.577, 7.313, 5.448, 6.435, 4.76, 5.798, 4.293, 5.46, 3.966, 5.234, 3.72, 5.004, 3.509, 4.808)
        T[10, .] = (75, 5.53, 5.53, 4.193, 4.647, 3.505, 4.213, 3.11, 3.9, 2.832, 3.717, 2.636, 3.579, 2.486, 3.469, 2.372, 3.37, 6.58, 6.58, 4.937, 5.443, 4.12, 4.855, 3.624, 4.488, 3.298, 4.26, 3.054, 4.079, 2.874, 3.914, 2.718, 3.807, 8.905, 8.905, 6.613, 7.253, 5.505, 6.298, 4.808, 5.786, 4.3, 5.377, 3.984, 5.153, 3.728, 4.954, 3.511, 4.789)
    }
    if (cs == 5) {
        T = J(11, 49, .)
        T[1, .] = (30, 10.34, 10.34, 6.01, 6.78, 4.577, 5.6, 3.868, 4.965, 3.43, 4.624, 3.157, 4.412, 2.977, 4.26, 2.843, 4.16, 12.74, 12.74, 7.36, 8.265, 5.55, 6.747, 4.683, 5.98, 4.154, 5.54, 3.818, 5.253, 3.576, 5.065, 3.394, 4.939, 18.56, 18.56, 10.605, 11.65, 7.977, 9.413, 6.643, 8.313, 5.856, 7.578, 5.347, 7.242, 5.046, 6.93, 4.779, 6.821)
        T[2, .] = (35, 10.24, 10.24, 5.95, 6.68, 4.517, 5.48, 3.8, 4.888, 3.374, 4.512, 3.087, 4.277, 2.879, 4.114, 2.729, 3.985, 12.58, 12.58, 7.21, 8.055, 5.457, 6.57, 4.568, 5.795, 4.036, 5.304, 3.673, 5.002, 3.426, 4.79, 3.251, 4.64, 18.02, 18.02, 10.365, 11.295, 7.643, 9.063, 6.38, 7.73, 5.604, 7.172, 5.095, 6.77, 4.704, 6.537, 4.459, 6.206)
        T[3, .] = (40, 10.16, 10.16, 5.915, 6.63, 4.477, 5.42, 3.76, 4.795, 3.334, 4.438, 3.032, 4.213, 2.831, 4.04, 2.668, 3.92, 12.51, 12.51, 7.135, 7.98, 5.387, 6.437, 4.51, 5.643, 3.958, 5.226, 3.577, 4.923, 3.327, 4.7, 3.121, 4.564, 17.91, 17.91, 10.15, 11.23, 7.527, 8.803, 6.238, 7.74, 5.376, 7.092, 4.885, 6.55, 4.527, 6.263, 4.31, 5.965)
        T[4, .] = (45, 10.15, 10.15, 5.88, 6.64, 4.437, 5.377, 3.74, 4.78, 3.298, 4.378, 3.012, 4.147, 2.796, 3.97, 2.635, 3.838, 12.4, 12.4, 7.08, 7.91, 5.36, 6.373, 4.45, 5.56, 3.89, 5.104, 3.532, 4.8, 3.267, 4.584, 3.091, 4.413, 17.5, 17.5, 9.89, 10.965, 7.317, 8.72, 6.053, 7.458, 5.224, 6.696, 4.715, 6.293, 4.364, 6.006, 4.109, 5.785)
        T[5, .] = (50, 10.02, 10.02, 5.78, 6.54, 4.38, 5.35, 3.673, 4.715, 3.24, 4.35, 2.95, 4.11, 2.75, 3.944, 2.59, 3.789, 12.17, 12.17, 6.985, 7.86, 5.247, 6.303, 4.368, 5.545, 3.834, 5.064, 3.48, 4.782, 3.229, 4.536, 3.039, 4.339, 17.53, 17.53, 9.895, 10.965, 7.337, 8.643, 5.995, 7.335, 5.184, 6.684, 4.672, 6.232, 4.31, 5.881, 4.055, 5.64)
        T[6, .] = (55, 10.11, 10.11, 5.8, 6.515, 4.37, 5.303, 3.64, 4.67, 3.21, 4.294, 2.927, 4.068, 2.724, 3.893, 2.573, 3.76, 12.17, 12.17, 6.93, 7.785, 5.19, 6.223, 4.313, 5.425, 3.794, 4.986, 3.442, 4.69, 3.197, 4.46, 2.989, 4.271, 17.48, 17.48, 9.8, 10.675, 7.227, 8.34, 5.955, 7.225, 5.108, 6.494, 4.608, 5.977, 4.23, 5.713, 3.955, 5.474)
        T[7, .] = (60, 10.03, 10.03, 5.765, 6.5, 4.35, 5.283, 3.645, 4.678, 3.2, 4.31, 2.912, 4.047, 2.709, 3.856, 2.551, 3.716, 12.2, 12.2, 6.905, 7.735, 5.19, 6.2, 4.298, 5.445, 3.772, 4.956, 3.407, 4.632, 3.137, 4.393, 2.956, 4.23, 17.02, 17.02, 9.585, 10.42, 7.057, 8.243, 5.835, 7.108, 5.066, 6.394, 4.505, 5.92, 4.117, 5.597, 3.87, 5.338)
        T[8, .] = (65, 9.97, 9.97, 5.755, 6.47, 4.353, 5.257, 3.638, 4.643, 3.196, 4.262, 2.897, 4.022, 2.69, 3.83, 2.531, 3.685, 11.96, 11.96, 6.89, 7.66, 5.137, 6.173, 4.268, 5.415, 3.732, 4.92, 3.372, 4.613, 3.137, 4.363, 2.924, 4.206, 16.85, 16.85, 9.475, 10.515, 7.013, 8.23, 5.795, 7.053, 4.974, 6.378, 4.482, 5.923, 4.111, 5.586, 3.835, 5.339)
        T[9, .] = (70, 10.02, 10.02, 5.765, 6.455, 4.33, 5.243, 3.615, 4.635, 3.182, 4.258, 2.893, 4.008, 2.683, 3.807, 2.519, 3.669, 12, 12, 6.86, 7.645, 5.11, 6.19, 4.235, 5.363, 3.72, 4.904, 3.368, 4.59, 3.107, 4.343, 2.913, 4.168, 16.66, 16.66, 9.37, 10.32, 6.873, 8.163, 5.663, 6.953, 4.922, 6.328, 4.428, 5.898, 4.07, 5.534, 3.774, 5.248)
        T[10, .] = (75, 10.03, 10.03, 5.765, 6.47, 4.323, 5.273, 3.618, 4.63, 3.182, 4.248, 2.89, 3.993, 2.681, 3.8, 2.53, 3.648, 12.08, 12.08, 6.88, 7.675, 5.14, 6.153, 4.253, 5.333, 3.724, 4.88, 3.382, 4.567, 3.111, 4.31, 2.915, 4.143, 16.61, 16.61, 9.325, 10.325, 6.93, 8.027, 5.698, 6.97, 4.932, 6.224, 4.393, 5.788, 4.06, 5.459, 3.768, 5.229)
        T[11, .] = (80, 9.96, 9.96, 5.725, 6.45, 4.307, 5.223, 3.588, 4.605, 3.16, 4.23, 2.867, 3.975, 2.657, 3.776, 2.504, 3.631, 12.06, 12.06, 6.82, 7.67, 5.067, 6.103, 4.203, 5.32, 3.678, 4.84, 3.335, 4.535, 3.077, 4.284, 2.885, 4.111, 16.6, 16.6, 9.17, 10.24, 6.73, 8.053, 5.62, 6.908, 4.89, 6.164, 4.375, 5.703, 4, 5.397, 3.728, 5.16)
    }

    nr = rows(T)
    lo = 1
    hi = 1
    w  = 0
    if (n > T[1, 1]) {
        if (n >= T[nr, 1]) {
            lo = nr
            hi = nr
            w  = 0
        }
        else {
            for (i = 1; i <= nr - 1; i++) {
                if (n >= T[i, 1]) {
                    lo = i
                }
            }
            hi = lo + 1
            w  = (n - T[lo, 1]) / (T[hi, 1] - T[lo, 1])
        }
    }
    a = T[lo, .]
    b = T[hi, .]
    O = J(3, 2, .)
    for (i = 1; i <= 3; i++) {
        j = 1 + (i - 1) * 16 + k * 2
        O[i, 1] = (1 - w) * a[j + 1] + w * b[j + 1]
        O[i, 2] = (1 - w) * a[j + 2] + w * b[j + 2]
    }
    return(O)
}

// ------------------------------------------------------------------
// Bounds decision code, equation (118):
//   2 = reject H0 (statistic beyond the I(1) bound)
//   1 = inconclusive
//   0 = do not reject (statistic inside the I(0) bound)
//   . = bounds unavailable
// upper != 0 for the right-tailed F statistic; upper == 0 for the
// left-tailed t statistic on lambda.
// ------------------------------------------------------------------
real scalar _surardl_decide(real scalar stat, real scalar c0, real scalar c1,
                            real scalar upper)
{
    if (c0 >= . | c1 >= .) {
        return(.)
    }
    if (upper != 0) {
        if (stat > c1) {
            return(2)
        }
        if (stat < c0) {
            return(0)
        }
        return(1)
    }
    if (stat < c1) {
        return(2)
    }
    if (stat > c0) {
        return(0)
    }
    return(1)
}


// ================================================================
// from _sa_engine.mata
// ================================================================

real scalar _surardl_ver()
{
    return(101)
}

struct surardl_eq {
    real colvector y
    real matrix    X
    real scalar    m
    real scalar    p
    real rowvector q
    real rowvector rst
    real scalar    ilam
    real rowvector ibeta
    real scalar    itr
    real scalar    ico
    real rowvector ipsi
    real rowvector igam
    real scalar    off
    string rowvector cn
}

// Column of unit i, variable v (v = 0 is the dependent variable,
// v = 1..K the regressors) in a level-series matrix LV.
real scalar _surardl_col(real scalar i, real scalar v, real scalar K)
{
    return((i - 1) * (K + 1) + 1 + v)
}

// Number of initial observations consumed by the lag structure.
real scalar _surardl_lagmax(real matrix LAGS, real scalar K)
{
    real scalar i, k, L
    L = 1
    for (i = 1; i <= rows(LAGS); i++) {
        if (LAGS[i, 1] > L) {
            L = LAGS[i, 1]
        }
        for (k = 1; k <= K; k++) {
            if (LAGS[i, k+1] > L) {
                L = LAGS[i, k+1]
            }
        }
    }
    return(L)
}

// ------------------------------------------------------------------
// Build the per-equation conditional ECM designs directly from the
// matrix of level series LV (Tfull x N*(K+1), gap-free and balanced;
// column block per unit, ordered y_i, x_1i, ..., x_Ki) and the vector
// of trend values TR (Tfull x 1).
// Implements equations (7) and (12)-(15) of Arif & Furuoka (2026).
// The same routine serves the observed data and every bootstrap
// replication, so the bootstrap reproduces the whole statistic.
// ------------------------------------------------------------------
struct surardl_eq vector _surardl_build(real matrix LV, real colvector TR,
        real scalar N, real scalar K, real matrix LAGS, real scalar cs,
        string scalar dep, string rowvector xn)
{
    struct surardl_eq vector E
    real scalar i, k, j, off, pos, L, T, Tf, c0, ck
    real colvector rr
    string rowvector cn

    E  = surardl_eq(N)
    Tf = rows(LV)
    L  = _surardl_lagmax(LAGS, K)
    T  = Tf - L
    rr = ((L + 1) :: Tf)

    off = 0
    for (i = 1; i <= N; i++) {
        E[i].p = LAGS[i, 1]
        E[i].q = LAGS[i, (2..(K+1))]
        c0     = _surardl_col(i, 0, K)

        E[i].y = LV[rr, c0] - LV[rr :- 1, c0]

        // --- lagged levels: lambda then beta_1..beta_K (eq. 14) ---
        E[i].X = LV[rr :- 1, c0]
        cn     = J(1, 1, "L." + dep)
        for (k = 1; k <= K; k++) {
            ck     = _surardl_col(i, k, K)
            E[i].X = E[i].X , LV[rr :- 1, ck]
            cn     = cn , ("L." + xn[k])
        }
        E[i].ilam  = 1
        E[i].ibeta = (2..(K+1))
        pos        = K + 1

        // --- lagged differences of the dependent variable (psi, eq. 10) ---
        E[i].ipsi = J(1, 0, .)
        for (j = 1; j <= E[i].p - 1; j++) {
            E[i].X    = E[i].X , (LV[rr :- j, c0] - LV[rr :- (j+1), c0])
            pos       = pos + 1
            E[i].ipsi = E[i].ipsi , pos
            if (j == 1) {
                cn = cn , ("LD." + dep)
            }
            else {
                cn = cn , ("L" + strofreal(j) + "D." + dep)
            }
        }

        // --- current and lagged differences of regressors (gamma, eq. 11) ---
        E[i].igam = J(1, 0, .)
        for (k = 1; k <= K; k++) {
            ck = _surardl_col(i, k, K)
            for (j = 0; j <= E[i].q[k] - 1; j++) {
                E[i].X    = E[i].X , (LV[rr :- j, ck] - LV[rr :- (j+1), ck])
                pos       = pos + 1
                E[i].igam = E[i].igam , pos
                if (j == 0) {
                    cn = cn , ("D." + xn[k])
                }
                else {
                    if (j == 1) {
                        cn = cn , ("LD." + xn[k])
                    }
                    else {
                        cn = cn , ("L" + strofreal(j) + "D." + xn[k])
                    }
                }
            }
        }

        // --- deterministic terms ---
        E[i].itr = 0
        E[i].ico = 0
        if (cs >= 4) {
            E[i].X   = E[i].X , TR[rr]
            pos      = pos + 1
            E[i].itr = pos
            cn       = cn , "_trend"
        }
        if (cs >= 2) {
            E[i].X   = E[i].X , J(T, 1, 1)
            pos      = pos + 1
            E[i].ico = pos
            cn       = cn , "_cons"
        }

        E[i].m   = pos
        E[i].cn  = cn
        E[i].off = off
        off      = off + pos

        // --- restriction set for H0: lambda_i = beta_1i = ... = beta_Ki = 0,
        //     plus the restricted deterministic term in cases 2 and 4.
        //     eq. (61)/(63); see also Kripfganz & Schneider (2020, fn. 12):
        //     q = K+1 in cases 1, 3, 5 and q = K+2 in cases 2, 4.
        E[i].rst = (1..(K+1))
        if (cs == 2) {
            E[i].rst = E[i].rst , E[i].ico
        }
        if (cs == 4) {
            E[i].rst = E[i].rst , E[i].itr
        }
    }
    return(E)
}

real scalar _surardl_M(struct surardl_eq vector E)
{
    real scalar i, M
    M = 0
    for (i = 1; i <= length(E); i++) {
        M = M + E[i].m
    }
    return(M)
}

// ------------------------------------------------------------------
// Equation-by-equation OLS, equation (18). Returns the T x N residual
// matrix and fills bols, seols, rssv, r2v, rmsev.
// ------------------------------------------------------------------
real matrix _surardl_ols(struct surardl_eq vector E, real colvector bols,
                         real colvector seols, real colvector rssv,
                         real colvector r2v, real colvector rmsev)
{
    real scalar i, N, T, s2, tss
    real matrix U, iXX
    real colvector bi, ui, my

    N = length(E)
    T = rows(E[1].y)
    U = J(T, N, 0)
    bols  = J(0, 1, .)
    seols = J(0, 1, .)
    rssv  = J(N, 1, .)
    r2v   = J(N, 1, .)
    rmsev = J(N, 1, .)

    for (i = 1; i <= N; i++) {
        iXX = invsym(quadcross(E[i].X, E[i].X))
        bi  = iXX * quadcross(E[i].X, E[i].y)
        ui  = E[i].y - E[i].X * bi
        U[., i] = ui
        rssv[i] = quadcross(ui, ui)
        s2      = rssv[i] / (T - E[i].m)
        rmsev[i]= sqrt(s2)
        bols    = bols  \ bi
        seols   = seols \ sqrt(diagonal(s2 * iXX))
        my      = E[i].y :- mean(E[i].y)
        tss     = quadcross(my, my)
        r2v[i]  = 1 - rssv[i] / tss
    }
    return(U)
}

// ------------------------------------------------------------------
// Contemporaneous covariance matrix Sigma-hat, equations (55)-(56).
// dfk = 0 : divide by T          (Zellner MLE; sureg default; the
//                                 divisor used by the authors' code)
// dfk = 1 : T - max(m_i, m_j)    (paper's third option)
// dfk = 2 : sqrt((T-m_i)(T-m_j)) (sureg's dfk)
// dfk = 3 : T - m_i - m_j        (sureg's dfk2, leading term)
// ------------------------------------------------------------------
real matrix _surardl_sigma(real matrix U, struct surardl_eq vector E, real scalar dfk)
{
    real scalar i, j, N, T, d
    real matrix S

    N = cols(U)
    T = rows(U)
    S = J(N, N, 0)
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            d = T
            if (dfk == 1) {
                d = T - max((E[i].m, E[j].m))
            }
            if (dfk == 2) {
                d = sqrt((T - E[i].m) * (T - E[j].m))
            }
            if (dfk == 3) {
                d = T - E[i].m - E[j].m
                if (d <= 0) {
                    d = T
                }
            }
            S[i, j] = quadcross(U[., i], U[., j]) / d
        }
    }
    return(S)
}

// ------------------------------------------------------------------
// FGLS cross-products, equations (50)-(53). The (i,j) block of A is
// s^ij X_i'X_j and the i-th block of b is sum_j s^ij X_i'y_j.
// ------------------------------------------------------------------
void _surardl_Ab(struct surardl_eq vector E, real matrix Si, real matrix A,
                 real colvector b)
{
    real scalar i, j, N, M, r0, c0
    real colvector bi

    N = length(E)
    M = _surardl_M(E)
    A = J(M, M, 0)
    b = J(M, 1, 0)

    for (i = 1; i <= N; i++) {
        r0 = E[i].off
        bi = J(E[i].m, 1, 0)
        for (j = 1; j <= N; j++) {
            c0 = E[j].off
            A[|r0+1, c0+1 \ r0+E[i].m, c0+E[j].m|] =
                Si[i, j] * quadcross(E[i].X, E[j].X)
            bi = bi + Si[i, j] * quadcross(E[i].X, E[j].y)
        }
        b[|r0+1 \ r0+E[i].m|] = bi
    }
}

void _surardl_resid(struct surardl_eq vector E, real colvector th, real matrix U)
{
    real scalar i, N
    N = length(E)
    for (i = 1; i <= N; i++) {
        U[., i] = E[i].y - E[i].X * th[|E[i].off+1 \ E[i].off+E[i].m|]
    }
}

// ------------------------------------------------------------------
// Two-step / iterated FGLS, equations (57)-(58) and the iteration
// scheme (a)-(d) of section 2.3.
// ------------------------------------------------------------------
void _surardl_fgls(struct surardl_eq vector E, real matrix U0,
        real scalar dfk, real scalar iterate, real scalar tol,
        real colvector th, real matrix V, real matrix S, real matrix U,
        real scalar nit, real scalar conv)
{
    real scalar it, dmax
    real matrix A, Si
    real colvector b, thold

    U = U0
    S = _surardl_sigma(U, E, dfk)
    Si = invsym(S)
    _surardl_Ab(E, Si, A, b)
    V  = invsym(A)
    th = V * b
    _surardl_resid(E, th, U)
    nit  = 1
    conv = 1

    if (iterate > 0) {
        conv = 0
        for (it = 1; it <= iterate; it++) {
            thold = th
            S  = _surardl_sigma(U, E, dfk)
            Si = invsym(S)
            _surardl_Ab(E, Si, A, b)
            V  = invsym(A)
            th = V * b
            _surardl_resid(E, th, U)
            nit  = it
            dmax = max(abs(th - thold))
            if (dmax < tol) {
                conv = 1
                it   = iterate + 1
            }
        }
    }
}

// ------------------------------------------------------------------
// System-level restriction matrix for H0^(i), equations (63)-(64).
// ------------------------------------------------------------------
real matrix _surardl_R(struct surardl_eq vector E, real scalar i, real scalar M)
{
    real scalar r, nr
    real matrix R

    nr = length(E[i].rst)
    R  = J(nr, M, 0)
    for (r = 1; r <= nr; r++) {
        R[r, E[i].off + E[i].rst[r]] = 1
    }
    return(R)
}

// Restriction matrix selecting only the lagged x levels (beta_1..beta_K)
// of equation i. This is the second PSS degenerate case, tested by
// McNown, Sam & Goh (2018) with t_IDV.
real matrix _surardl_Rbeta(struct surardl_eq vector E, real scalar i, real scalar M)
{
    real scalar r, nr
    real matrix R

    nr = length(E[i].ibeta)
    R  = J(nr, M, 0)
    for (r = 1; r <= nr; r++) {
        R[r, E[i].off + E[i].ibeta[r]] = 1
    }
    return(R)
}

// ------------------------------------------------------------------
// Wald statistic, equations (77) / (112); F form F = W/q, eq. (76).
// Returns (W, q, F).
// ------------------------------------------------------------------
real rowvector _surardl_wald(real matrix R, real colvector th, real matrix V)
{
    real colvector d
    real matrix    Q
    real scalar    w, q

    d = R * th
    Q = R * V * R'
    w = (d' * invsym(Q) * d)
    q = rows(R)
    return((w, q, w / q))
}

// ------------------------------------------------------------------
// RSS-based F statistic, equations (73)-(76). The restricted system
// drops the level terms from equation i only (eq. 69: "the models for
// all other units j != i remain unrestricted"). With allq != 0 the
// level terms are dropped from every equation simultaneously, which is
// what the authors' own OxGauss / Stata scripts do.
// Sigma-hat is held at its unrestricted value, as in eq. (73).
// ------------------------------------------------------------------
real colvector _surardl_rssF(struct surardl_eq vector E, real matrix Si,
        real colvector rssU, real scalar allq)
{
    real scalar i, j, N, T, M, nk, q
    real colvector F, bR, keep, rssR, b, uj
    real matrix A, Si2
    struct surardl_eq vector ER

    N = length(E)
    T = rows(E[1].y)
    F = J(N, 1, .)

    for (i = 1; i <= N; i++) {
        ER = E
        for (j = 1; j <= N; j++) {
            if (allq != 0 | j == i) {
                keep = J(0, 1, .)
                for (nk = 1; nk <= E[j].m; nk++) {
                    if (!anyof(E[j].rst, nk)) {
                        keep = keep \ nk
                    }
                }
                ER[j].X   = E[j].X[., keep]
                ER[j].m   = rows(keep)
            }
        }
        // recompute offsets
        M = 0
        for (j = 1; j <= N; j++) {
            ER[j].off = M
            M = M + ER[j].m
        }
        Si2 = Si
        _surardl_Ab(ER, Si2, A, b)
        bR  = invsym(A) * b
        rssR = J(N, 1, .)
        for (j = 1; j <= N; j++) {
            uj = ER[j].y - ER[j].X * bR[|ER[j].off+1 \ ER[j].off+ER[j].m|]
            rssR[j] = quadcross(uj, uj)
        }
        q = length(E[i].rst)
        F[i] = ((rssR[i] - rssU[i]) / q) / (rssU[i] / (T - E[i].m))
    }
    return(F)
}

// ------------------------------------------------------------------
// Long-run coefficients, equation (84), with delta-method variances,
// equations (85)-(91).
// Returns a (N*K) x 5 matrix: unit, regressor, theta, se, and the
// covariance block determinant flag.
// ------------------------------------------------------------------
real matrix _surardl_longrun(struct surardl_eq vector E, real colvector th,
                             real matrix V, real scalar K)
{
    real scalar i, k, N, il, ib, lam, bet, vll, vbb, vlb, va
    real matrix Out

    N = length(E)
    Out = J(N * K, 4, .)
    for (i = 1; i <= N; i++) {
        il  = E[i].off + E[i].ilam
        lam = th[il]
        vll = V[il, il]
        for (k = 1; k <= K; k++) {
            ib  = E[i].off + E[i].ibeta[k]
            bet = th[ib]
            vbb = V[ib, ib]
            vlb = V[il, ib]
            // eq. (89): Var = (b^2/l^4) v_ll - (2b/l^3) v_lb + (1/l^2) v_bb
            va  = (bet * bet) / (lam^4) * vll
            va  = va - 2 * bet / (lam^3) * vlb
            va  = va + vbb / (lam * lam)
            Out[(i-1)*K + k, 1] = i
            Out[(i-1)*K + k, 2] = k
            Out[(i-1)*K + k, 3] = -bet / lam
            Out[(i-1)*K + k, 4] = sqrt(va)
        }
    }
    return(Out)
}

// ------------------------------------------------------------------
// Fieller (1954) confidence set for theta = -beta/lambda. Inverts
// H0: beta + theta*lambda = 0 and therefore never divides by lambda.
// Recommended over the delta method in section 4.6 of the paper.
// Returns (lo, hi, type) with type
//   0 = bounded interval
//   1 = unbounded: complement of (lo,hi), i.e. (-inf,lo] U [hi,+inf)
//   2 = entire real line
//   3 = empty set
// ------------------------------------------------------------------
real rowvector _surardl_fieller(real scalar lam, real scalar bet, real scalar vll,
                                real scalar vbb, real scalar vlb, real scalar z)
{
    real scalar A, B, C, Disc, r1, r2, zz

    zz = z * z
    A  = lam * lam - zz * vll
    B  = 2 * (bet * lam - zz * vlb)
    C  = bet * bet - zz * vbb
    Disc = B * B - 4 * A * C

    if (A > 0) {
        if (Disc <= 0) {
            return((., ., 3))
        }
        r1 = (-B - sqrt(Disc)) / (2 * A)
        r2 = (-B + sqrt(Disc)) / (2 * A)
        return((min((r1, r2)), max((r1, r2)), 0))
    }
    if (A < 0) {
        if (Disc <= 0) {
            return((., ., 2))
        }
        r1 = (-B - sqrt(Disc)) / (2 * A)
        r2 = (-B + sqrt(Disc)) / (2 * A)
        return((min((r1, r2)), max((r1, r2)), 1))
    }
    return((., ., 2))
}

// ------------------------------------------------------------------
// Breusch & Pagan (1980) LM test of diagonal Sigma, equations (96)-(99),
// and the Pesaran (2004) CD statistic, equation (100).
// NOTE on eq. (100): as printed in the draft the CD statistic omits the
// factor 2 inside the square root. The formula implemented here is
// Pesaran's own, CD = sqrt(2T/(N(N-1))) * sum_{i<j} r_ij, which
// reproduces the value CD = 1.32 reported in section 5 of the paper
// from the correlation matrix in its Table 9.
// Returns (LM, df, p_LM, CD, p_CD, mean|r|).
// ------------------------------------------------------------------
real rowvector _surardl_bpcd(real matrix U)
{
    real scalar i, j, N, T, s2, sr, sa, lm, cd, df
    real matrix R

    N = cols(U)
    T = rows(U)
    R = correlation(U)
    s2 = 0
    sr = 0
    sa = 0
    for (i = 2; i <= N; i++) {
        for (j = 1; j <= i - 1; j++) {
            s2 = s2 + R[i, j] * R[i, j]
            sr = sr + R[i, j]
            sa = sa + abs(R[i, j])
        }
    }
    df = N * (N - 1) / 2
    lm = T * s2
    cd = sqrt(2 * T / (N * (N - 1))) * sr
    return((lm, df, chi2tail(df, lm), cd, 2 * normal(-abs(cd)), sa / df))
}

// ------------------------------------------------------------------
// Breusch-Godfrey LM test for serial correlation in each equation's
// residuals, used to verify Assumption 1(iii) (Remark 5).
// Auxiliary regression of u on [X, u_{t-1},...,u_{t-L}]; LM = n*R2.
// Returns N x 3: (LM, df, p).
// ------------------------------------------------------------------
real matrix _surardl_bg(struct surardl_eq vector E, real matrix U, real scalar L)
{
    real scalar i, l, N, T, n, r2, tss
    real matrix Out, W
    real colvector u, e2, mu, ui

    N = length(E)
    T = rows(U)
    Out = J(N, 3, .)
    if (L >= T - 2) {
        return(Out)
    }
    for (i = 1; i <= N; i++) {
        u = U[((L+1)::T), i]
        W = E[i].X[((L+1)::T), .]
        for (l = 1; l <= L; l++) {
            ui = U[((L+1-l)::(T-l)), i]
            W  = W , ui
        }
        n  = rows(u)
        e2 = u - W * (invsym(quadcross(W, W)) * quadcross(W, u))
        mu = u :- mean(u)
        tss = quadcross(mu, mu)
        r2 = 1 - quadcross(e2, e2) / tss
        Out[i, 1] = n * r2
        Out[i, 2] = L
        Out[i, 3] = chi2tail(L, n * r2)
    }
    return(Out)
}


// ================================================================
// from _sa_boot.mata
// ================================================================

// ==================================================================
// Statistic vector for one data set. Returns N x 3:
//   col 1  F_i    bounds F for H0: lambda_i = beta_.i = 0 (plus the
//                 restricted deterministic term in cases 2 and 4),
//                 equations (76)-(77)
//   col 2  t_i    t statistic on lambda_i (PSS step 2; first
//                 degenerate case)
//   col 3  Fidv_i F for H0: beta_1i = ... = beta_Ki = 0 (second
//                 degenerate case; t_IDV of McNown et al. 2018)
// ==================================================================
real matrix _surardl_stats(struct surardl_eq vector E, real scalar dfk,
                           real scalar iterate, real scalar tol)
{
    real scalar i, N, M, il, nit, conv
    real matrix S, U, U0, V, Out, R
    real colvector th, bols, seols, rssv, r2v, rmsev
    real rowvector w

    N  = length(E)
    M  = _surardl_M(E)
    U0 = _surardl_ols(E, bols, seols, rssv, r2v, rmsev)
    _surardl_fgls(E, U0, dfk, iterate, tol, th, V, S, U, nit, conv)

    Out = J(N, 3, .)
    for (i = 1; i <= N; i++) {
        R = _surardl_R(E, i, M)
        w = _surardl_wald(R, th, V)
        Out[i, 1] = w[3]
        il = E[i].off + E[i].ilam
        Out[i, 2] = th[il] / sqrt(V[il, il])
        R = _surardl_Rbeta(E, i, M)
        w = _surardl_wald(R, th, V)
        Out[i, 3] = w[3]
    }
    return(Out)
}

// Trap a failed replication (singular design or non-invertible
// Sigma-hat) instead of aborting the whole bootstrap.
real scalar _surardl_try(struct surardl_eq vector E, real scalar dfk,
        real scalar iterate, real scalar tol, real matrix St)
{
    real scalar i, N, ok

    N  = length(E)
    ok = 1
    for (i = 1; i <= N; i++) {
        if (rank(quadcross(E[i].X, E[i].X)) < E[i].m) {
            ok = 0
        }
    }
    if (ok == 0) {
        return(1)
    }
    St = _surardl_stats(E, dfk, iterate, tol)
    if (hasmissing(St)) {
        return(1)
    }
    return(0)
}

// Rescale and recentre residuals column by column; McNown, Sam & Goh
// (2018, eq. 13), following Davidson & MacKinnon (2004). np holds the
// number of estimated parameters behind each column.
real matrix _surardl_rescale(real matrix U, real rowvector np)
{
    real scalar n, c, f
    real matrix R

    n = rows(U)
    R = U
    for (c = 1; c <= cols(U); c++) {
        f = 1
        if (n > np[c]) {
            f = sqrt(n / (n - np[c]))
        }
        R[., c] = f :* (U[., c] :- mean(U[., c]))
    }
    return(R)
}

// ==================================================================
// Marginal (conditioning) model for the regressors of unit i, used
// only to generate pseudo-data. Equation X of McNown, Sam & Goh
// (2018, eq. 12), generalised to K regressors and VECM order mo:
//
//   dx_{k,i,t} = a + b'(y_{i,t-1}, x_{i,t-1}')
//                  + sum_{j=1..mo} phi_j'(dy_{i,t-j}, dx_{i,t-j}')
//                  + v_{k,i,t}
//
// Fitted by OLS on rows Lg+1..Tf. Returns the (nreg x K) coefficient
// matrix and fills VR with the (Tf-Lg) x K residuals.
// ==================================================================
real matrix _surardl_marg(real matrix LV, real colvector TR, real scalar i,
        real scalar K, real scalar Lg, real scalar mo, real scalar cs,
        real matrix VR)
{
    real scalar k, j, Tb, Tf, c0, ck
    real colvector rr, yk
    real matrix W, B

    Tf = rows(LV)
    Tb = Tf - Lg
    rr = ((Lg + 1) :: Tf)
    c0 = _surardl_col(i, 0, K)

    W = LV[rr :- 1, c0]
    for (k = 1; k <= K; k++) {
        ck = _surardl_col(i, k, K)
        W  = W , LV[rr :- 1, ck]
    }
    for (j = 1; j <= mo; j++) {
        W = W , (LV[rr :- j, c0] - LV[rr :- (j+1), c0])
        for (k = 1; k <= K; k++) {
            ck = _surardl_col(i, k, K)
            W  = W , (LV[rr :- j, ck] - LV[rr :- (j+1), ck])
        }
    }
    if (cs >= 4) {
        W = W , TR[rr]
    }
    if (cs >= 2) {
        W = W , J(Tb, 1, 1)
    }

    B  = J(cols(W), K, 0)
    VR = J(Tb, K, 0)
    for (k = 1; k <= K; k++) {
        ck = _surardl_col(i, k, K)
        yk = LV[rr, ck] - LV[rr :- 1, ck]
        B[., k]  = invsym(quadcross(W, W)) * quadcross(W, yk)
        VR[., k] = yk - W * B[., k]
    }
    return(B)
}

// Regressor row for the marginal model of unit i at time t, built
// from the pseudo-level matrix LVs. Must match _surardl_marg()'s W.
real colvector _surardl_margrow(real matrix LVs, real colvector TR,
        real scalar i, real scalar K, real scalar t, real scalar mo,
        real scalar cs)
{
    real scalar k, j, c0
    real colvector z

    c0 = _surardl_col(i, 0, K)
    z  = LVs[t-1, c0]
    for (k = 1; k <= K; k++) {
        z = z \ LVs[t-1, _surardl_col(i, k, K)]
    }
    for (j = 1; j <= mo; j++) {
        z = z \ (LVs[t-j, c0] - LVs[t-j-1, c0])
        for (k = 1; k <= K; k++) {
            z = z \ (LVs[t-j, _surardl_col(i, k, K)]
                   - LVs[t-j-1, _surardl_col(i, k, K)])
        }
    }
    if (cs >= 4) {
        z = z \ TR[t]
    }
    if (cs >= 2) {
        z = z \ 1
    }
    return(z)
}

// Regressor row for the generating y-model of unit i at time t. The
// level terms (and the restricted deterministic term) are omitted
// wherever the null has been imposed, so the column order matches the
// restricted design ES[i].X exactly.
// nodrift != 0 zeroes the deterministic entries of the row for an
// equation whose null has been imposed. The deterministic coefficients
// are still estimated in every replication, so their estimation cost is
// reflected, but they are not propagated into the LEVEL of y*.
//
// This matters. Under the null the generating equation is
//   D.y* = c0 (+ c1 t) + sum_k gamma_k D.x* + u*,
// so a fitted intercept makes y* a random walk WITH DRIFT and a fitted
// trend makes it quadratic. The PSS (2001) Table CI null DGP, and the
// authors' own OxGauss code, generate y* as a driftless random walk.
// Propagating the fitted deterministics instead produces a null
// distribution with a very heavy right tail for strongly trending
// series -- critical values in the dozens rather than single digits --
// which is not the distribution the bounds test is calibrated against.
real colvector _surardl_yrow(real matrix LVs, real colvector TR,
        struct surardl_eq vector E, real scalar i, real scalar K,
        real scalar t, real scalar cs, real scalar restricted,
        real scalar nodrift)
{
    real scalar k, j, c0, ck
    real colvector z

    c0 = _surardl_col(i, 0, K)
    z  = J(0, 1, .)
    if (restricted == 0) {
        z = z \ LVs[t-1, c0]
        for (k = 1; k <= K; k++) {
            z = z \ LVs[t-1, _surardl_col(i, k, K)]
        }
    }
    for (j = 1; j <= E[i].p - 1; j++) {
        z = z \ (LVs[t-j, c0] - LVs[t-j-1, c0])
    }
    for (k = 1; k <= K; k++) {
        ck = _surardl_col(i, k, K)
        for (j = 0; j <= E[i].q[k] - 1; j++) {
            z = z \ (LVs[t-j, ck] - LVs[t-j-1, ck])
        }
    }
    if (cs >= 4) {
        if (!(cs == 4 & restricted != 0)) {
            if (restricted != 0 & nodrift != 0) {
                z = z \ 0
            }
            else {
                z = z \ TR[t]
            }
        }
    }
    if (cs >= 2) {
        if (!(cs == 2 & restricted != 0)) {
            if (restricted != 0 & nodrift != 0) {
                z = z \ 0
            }
            else {
                z = z \ 1
            }
        }
    }
    return(z)
}

// ==================================================================
// Residual bootstrap for the SUR bounds statistics.
//
// Design: McNown, Sam & Goh (2018, section 3.2, steps 1-8), itself the
// procedure of Palm, Smeekes & Urbain (2010, section 3.2 and Remark 2),
// extended to the N-equation SUR system. This supplies the "Approach B"
// that section 2.4 of Arif & Furuoka (2026) calls for but leaves
// unspecified.
//
// Two features make the critical values SUR-specific rather than
// single-equation:
//   * the N y-equation innovations and the N*K marginal innovations
//     are resampled as ONE time-indexed vector, so the contemporaneous
//     cross-equation covariance Sigma and the within-unit y-x
//     dependence are both preserved;
//   * every replication re-runs the ENTIRE statistic -- first-step
//     OLS, re-estimation of Sigma-hat, FGLS solve and Wald form -- so
//     the bootstrap distribution carries the same estimation noise as
//     the observed statistic.
//
// target == 0 : impose H0 on every y-equation at once (the null DGP of
//               the authors' own Monte Carlo code); one pass yields
//               critical values for all N equations and the joint test
// target == i : impose H0 on equation i only, leaving the other y
//               equations and all marginal equations unrestricted
//               (faithful to McNown et al.; the default)
//
// dgp == 1 : marginal VECM of order mo fitted to the data
// dgp == 0 : regressors generated as pure random walks, the DGP behind
//            the PSS and Narayan tabulations (default)
//
// nodrift != 0 : generate y* under the null as a DRIFTLESS random walk,
//            as in the PSS Table CI design. The default 0 propagates the
//            fitted intercept and trend into the level of y*, which is
//            the literal reading of McNown et al. step 4 and keeps the
//            bootstrap faithful to the data's own deterministic
//            behaviour.
//
// Returns B x 3N: columns 1..N are F*, N+1..2N are t*, 2N+1..3N are
// Fidv*.
// ==================================================================
real matrix _surardl_boot(real matrix LV, real colvector TR, real scalar N,
        real scalar K, real matrix LAGS, real scalar cs, real scalar dfk,
        real scalar iterate, real scalar tol, real scalar B, real scalar target,
        real scalar dgp, real scalar mo, real scalar nodrift,
        string scalar dep, string rowvector xn, real scalar nfail)
{
    struct surardl_eq vector E, EG, ES
    real scalar i, k, b, t, L, Lg, T, Tb, Tf, M, c0, ck, jr, rest, rc
    real scalar nit, conv
    real matrix Out, S, U0, V, URes, UR, VR, VRall, VRs, LVs, Bmarg, St
    real colvector ths, bols, seols, rssv, r2v, rmsev, keep, idx, zrow
    real rowvector np, dxs

    Tf    = rows(LV)
    L     = _surardl_lagmax(LAGS, K)
    T     = Tf - L
    Lg    = max((L, mo + 1))
    Tb    = Tf - Lg
    Out   = J(B, 3 * N, .)
    nfail = 0

    // ------- Step 1: generating models, null imposed where required --
    E  = _surardl_build(LV, TR, N, K, LAGS, cs, dep, xn)
    EG = E
    for (i = 1; i <= N; i++) {
        if (target == 0 | target == i) {
            keep = J(0, 1, .)
            for (k = 1; k <= E[i].m; k++) {
                if (!anyof(E[i].rst, k)) {
                    keep = keep \ k
                }
            }
            EG[i].X = E[i].X[., keep]
            EG[i].m = rows(keep)
        }
    }
    M = 0
    for (i = 1; i <= N; i++) {
        EG[i].off = M
        M = M + EG[i].m
    }
    U0 = _surardl_ols(EG, bols, seols, rssv, r2v, rmsev)
    _surardl_fgls(EG, U0, dfk, iterate, tol, ths, V, S, URes, nit, conv)

    // ------- marginal models for the regressors ---------------------
    Bmarg = J(0, 0, .)
    VRall = J(Tb, N * K, 0)
    if (dgp != 0) {
        for (i = 1; i <= N; i++) {
            VR = J(0, 0, .)
            St = _surardl_marg(LV, TR, i, K, Lg, mo, cs, VR)
            if (i == 1) {
                Bmarg = J(rows(St), N * K, 0)
            }
            Bmarg[., ((i-1)*K+1)..(i*K)] = St
            VRall[., ((i-1)*K+1)..(i*K)] = VR
        }
    }
    else {
        for (i = 1; i <= N; i++) {
            for (k = 1; k <= K; k++) {
                ck = _surardl_col(i, k, K)
                VRall[., (i-1)*K+k] = LV[((Lg+1)::Tf), ck] - LV[(Lg::(Tf-1)), ck]
            }
        }
    }

    // ------- Step 2: rescale and recentre, aligned on Tb rows -------
    np = J(1, N, 0)
    for (i = 1; i <= N; i++) {
        np[i] = EG[i].m
    }
    UR  = _surardl_rescale(URes[((T - Tb + 1)::T), .], np)
    VRs = _surardl_rescale(VRall, J(1, N * K, cols(Bmarg)))

    // ------- Steps 3-8 ----------------------------------------------
    for (b = 1; b <= B; b++) {
        // Step 3: ONE index draw per period, shared by every equation.
        idx = ceil(runiform(Tb, 1) :* Tb)
        idx = idx :+ (idx :< 1)

        // Steps 4-5: generate pseudo-levels recursively. Rows up to Lg
        // are kept at their observed values as initial conditions.
        LVs = LV
        for (t = Lg + 1; t <= Tf; t++) {
            jr = idx[t - Lg]
            // regressors first: they do not depend on the current dy
            for (i = 1; i <= N; i++) {
                dxs = J(1, K, 0)
                if (dgp != 0) {
                    zrow = _surardl_margrow(LVs, TR, i, K, t, mo, cs)
                }
                for (k = 1; k <= K; k++) {
                    ck = _surardl_col(i, k, K)
                    if (dgp == 0) {
                        dxs[k] = VRs[jr, (i-1)*K+k]
                    }
                    else {
                        dxs[k] = (zrow' * Bmarg[., (i-1)*K+k]) + VRs[jr, (i-1)*K+k]
                    }
                    LVs[t, ck] = LVs[t-1, ck] + dxs[k]
                }
            }
            // dependent variables, using the just-generated dx
            for (i = 1; i <= N; i++) {
                c0 = _surardl_col(i, 0, K)
                rest = 0
                if (target == 0 | target == i) {
                    rest = 1
                }
                zrow = _surardl_yrow(LVs, TR, E, i, K, t, cs, rest, nodrift)
                LVs[t, c0] = LVs[t-1, c0] +
                    (zrow' * ths[|EG[i].off+1 \ EG[i].off+EG[i].m|]) + UR[jr, i]
            }
        }

        // Explosion guard. An unrestricted marginal VECM estimated on a
        // short sample can have roots outside the unit circle, in which
        // case the recursion diverges and the replication is worthless.
        // Such draws are discarded and counted, never used.
        rc = 0
        if (hasmissing(LVs)) {
            rc = 1
        }
        else {
            if (max(abs(LVs)) > 1e4 * (1 + max(abs(LV)))) {
                rc = 1
            }
        }
        if (rc != 0) {
            nfail = nfail + 1
            continue
        }

        // Steps 6-7: re-run the whole statistic on the pseudo-data.
        ES = _surardl_build(LVs, TR, N, K, LAGS, cs, dep, xn)
        St = J(N, 3, .)
        rc = _surardl_try(ES, dfk, iterate, tol, St)
        if (rc == 0) {
            Out[b, (1..N)]           = St[., 1]'
            Out[b, ((N+1)..(2*N))]   = St[., 2]'
            Out[b, ((2*N+1)..(3*N))] = St[., 3]'
        }
        else {
            nfail = nfail + 1
        }
    }
    return(Out)
}

// Empirical quantile of a column (linear interpolation on the order
// statistics), used for bootstrap and simulated critical values.
real scalar _surardl_quant(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h
    s = sort(select(x, x :< .), 1)
    n = rows(s)
    if (n < 2) {
        return(.)
    }
    h = p * n
    if (h < 1) {
        return(s[1])
    }
    if (h >= n) {
        return(s[n])
    }
    return(s[floor(h)] + (h - floor(h)) * (s[floor(h)+1] - s[floor(h)]))
}

// Bootstrap p-value (1 + #{beyond}) / (B + 1).
// upper != 0 for right-tailed statistics, upper == 0 for the t statistic.
real scalar _surardl_bootp(real colvector x, real scalar stat, real scalar upper)
{
    real colvector s
    real scalar n
    s = select(x, x :< .)
    n = rows(s)
    if (n < 1) {
        return(.)
    }
    if (upper != 0) {
        return((1 + colsum(s :>= stat)) / (n + 1))
    }
    return((1 + colsum(s :<= stat)) / (n + 1))
}

// ==================================================================
// Approach A of section 2.4: SUR-specific Monte Carlo critical value
// BOUNDS. Data are generated under H0 with the estimated Sigma-hat as
// the y-innovation covariance and the regressors either purely I(1)
// (upper bound) or purely I(0) (lower bound), as in the notes to PSS
// (2001, Table CI) and in the authors' own OxGauss
// empirical-distribution code.
//
// i1   != 0 : x_t = x_{t-1} + e_t   (upper bound)
// i1   == 0 : x_t = e_t             (lower bound)
// rhox      : equicorrelation imposed across units on the regressor
//             innovations. rhox = 0 reproduces the PSS design (the
//             regressors are independent across units); rhox = 1
//             reproduces the authors' OxGauss design, in which every
//             unit's regressors are driven by the same shocks.
//             Theorem 3(c) makes the null distribution depend on the
//             other equations' regressors, so this is a real knob.
//
// Returns B x 3N, laid out as in _surardl_boot().
// ==================================================================
real matrix _surardl_sim(real matrix S, real scalar N, real scalar K,
        real matrix LAGS, real scalar cs, real scalar dfk, real scalar iterate,
        real scalar tol, real scalar B, real scalar T, real scalar i1,
        real scalar burn, real scalar rhox, string scalar dep,
        string rowvector xn, real scalar nfail)
{
    struct surardl_eq vector ES
    real scalar b, i, k, t, L, Tf, Tt, rc, sr
    real matrix Out, C, EPS, LVs, St, EX, CM
    real colvector TR

    L     = _surardl_lagmax(LAGS, K)
    Tf    = T + L
    Tt    = Tf + burn
    Out   = J(B, 3 * N, .)
    nfail = 0
    C     = cholesky(S)'
    TR    = (1 :: Tf)

    // equicorrelation factor for the regressor innovations
    sr = sqrt(abs(rhox))
    if (rhox < 0) {
        sr = 0
    }

    for (b = 1; b <= B; b++) {
        EPS = invnormal(runiform(Tt, N)) * C
        EX  = invnormal(runiform(Tt, N * K))
        if (sr > 0) {
            CM = invnormal(runiform(Tt, K))
            for (i = 1; i <= N; i++) {
                for (k = 1; k <= K; k++) {
                    EX[., (i-1)*K+k] = sr :* CM[., k] +
                        sqrt(1 - sr * sr) :* EX[., (i-1)*K+k]
                }
            }
        }

        LVs = J(Tt, N * (K + 1), 0)
        for (t = 2; t <= Tt; t++) {
            for (i = 1; i <= N; i++) {
                LVs[t, _surardl_col(i, 0, K)] =
                    LVs[t-1, _surardl_col(i, 0, K)] + EPS[t, i]
                for (k = 1; k <= K; k++) {
                    if (i1 != 0) {
                        LVs[t, _surardl_col(i, k, K)] =
                            LVs[t-1, _surardl_col(i, k, K)] + EX[t, (i-1)*K+k]
                    }
                    else {
                        LVs[t, _surardl_col(i, k, K)] = EX[t, (i-1)*K+k]
                    }
                }
            }
        }
        LVs = LVs[((burn+1)::Tt), .]

        ES = _surardl_build(LVs, TR, N, K, LAGS, cs, dep, xn)
        St = J(N, 3, .)
        rc = _surardl_try(ES, dfk, iterate, tol, St)
        if (rc == 0) {
            Out[b, (1..N)]           = St[., 1]'
            Out[b, ((N+1)..(2*N))]   = St[., 2]'
            Out[b, ((2*N+1)..(3*N))] = St[., 3]'
        }
        else {
            nfail = nfail + 1
        }
    }
    return(Out)
}


// ================================================================
// from _sa_tests.mata
// ================================================================

// ==================================================================
// Joint / subset bounds restriction matrix, equations (65)-(67).
// units is a row vector of equation indices to include; passing
// (1..N) gives R_Joint of equation (67).
// ==================================================================
real matrix _surardl_Rjoint(struct surardl_eq vector E, real rowvector units,
                            real scalar M)
{
    real scalar u
    real matrix R

    R = J(0, M, .)
    for (u = 1; u <= length(units); u++) {
        R = R \ _surardl_R(E, units[u], M)
    }
    return(R)
}

// ==================================================================
// Poolability restriction matrix, section 4.5(a):
//   H0: beta_{k,i} = beta_{k,1}, i = 2..N, k = 1..K
// with K(N-1) restrictions. what selects the parameter block:
//   1 = long-run level coefficients beta   (K(N-1) restrictions)
//   2 = speed of adjustment lambda         (N-1 restrictions)
//   3 = short-run coefficients gamma/psi   (requires equal lag orders)
//   4 = beta and lambda jointly
// Returns J(0, M, .) when the restrictions are not well defined.
// ==================================================================
real matrix _surardl_Rpool(struct surardl_eq vector E, real scalar M,
                           real scalar K, real scalar what)
{
    real scalar i, k, N, ns
    real matrix R
    real rowvector r

    N = length(E)
    R = J(0, M, .)
    if (N < 2) {
        return(R)
    }

    if (what == 1 | what == 4) {
        for (i = 2; i <= N; i++) {
            for (k = 1; k <= K; k++) {
                r = J(1, M, 0)
                r[E[i].off + E[i].ibeta[k]] =  1
                r[E[1].off + E[1].ibeta[k]] = -1
                R = R \ r
            }
        }
    }
    if (what == 2 | what == 4) {
        for (i = 2; i <= N; i++) {
            r = J(1, M, 0)
            r[E[i].off + E[i].ilam] =  1
            r[E[1].off + E[1].ilam] = -1
            R = R \ r
        }
    }
    if (what == 3) {
        ns = length(E[1].ipsi) + length(E[1].igam)
        for (i = 2; i <= N; i++) {
            if (length(E[i].ipsi) + length(E[i].igam) != ns) {
                return(J(0, M, .))
            }
        }
        for (i = 2; i <= N; i++) {
            for (k = 1; k <= length(E[1].ipsi); k++) {
                r = J(1, M, 0)
                r[E[i].off + E[i].ipsi[k]] =  1
                r[E[1].off + E[1].ipsi[k]] = -1
                R = R \ r
            }
            for (k = 1; k <= length(E[1].igam); k++) {
                r = J(1, M, 0)
                r[E[i].off + E[i].igam[k]] =  1
                r[E[1].off + E[1].igam[k]] = -1
                R = R \ r
            }
        }
    }
    return(R)
}

// Pairwise restriction on the speed of adjustment, section 4.5(c):
//   H0: lambda_i = lambda_j
real matrix _surardl_Rlam(struct surardl_eq vector E, real scalar i,
                          real scalar j, real scalar M)
{
    real rowvector r
    r = J(1, M, 0)
    r[E[i].off + E[i].ilam] =  1
    r[E[j].off + E[j].ilam] = -1
    return(r)
}

// ==================================================================
// Gradient of the long-run coefficients with respect to the system
// parameter vector. Row (i-1)*K+k holds d theta_{k,i} / d theta, with
//   d theta_{k,i} / d lambda_i = beta_{k,i} / lambda_i^2
//   d theta_{k,i} / d beta_{k,i} = -1 / lambda_i
// This is the multivariate delta method of Remark 10, equations
// (92)-(93), written once for the whole system so that ANY linear
// hypothesis C * theta^LR = c can be tested as
//   W = (C th - c)' [C G V G' C']^-1 (C th - c).
// ==================================================================
real matrix _surardl_lrgrad(struct surardl_eq vector E, real colvector th,
                            real scalar K, real scalar M)
{
    real scalar i, k, N, il, ib, lam, bet
    real matrix G

    N = length(E)
    G = J(N * K, M, 0)
    for (i = 1; i <= N; i++) {
        il  = E[i].off + E[i].ilam
        lam = th[il]
        for (k = 1; k <= K; k++) {
            ib  = E[i].off + E[i].ibeta[k]
            bet = th[ib]
            G[(i-1)*K + k, il] = bet / (lam * lam)
            G[(i-1)*K + k, ib] = -1 / lam
        }
    }
    return(G)
}

real colvector _surardl_lrvec(struct surardl_eq vector E, real colvector th,
                              real scalar K)
{
    real scalar i, k, N
    real colvector v

    N = length(E)
    v = J(N * K, 1, .)
    for (i = 1; i <= N; i++) {
        for (k = 1; k <= K; k++) {
            v[(i-1)*K + k] = -th[E[i].off + E[i].ibeta[k]] /
                              th[E[i].off + E[i].ilam]
        }
    }
    return(v)
}

// Wald test of C * theta^LR = 0. Returns (W, df, p).
real rowvector _surardl_lrwald(real matrix C, real colvector thLR,
                               real matrix G, real matrix V)
{
    real colvector d
    real matrix    Q
    real scalar    w, df

    d  = C * thLR
    Q  = C * G * V * G' * C'
    w  = (d' * invsym(Q) * d)
    df = rank(C)
    return((w, df, chi2tail(df, w)))
}

// Contrast selecting theta_{k,i} - theta_{k,j} for one regressor k.
real matrix _surardl_Clrpair(real scalar i, real scalar j, real scalar k,
                             real scalar N, real scalar K)
{
    real rowvector c
    c = J(1, N * K, 0)
    c[(i-1)*K + k] =  1
    c[(j-1)*K + k] = -1
    return(c)
}

// Contrast selecting all K long-run differences between units i and j.
real matrix _surardl_Clrpairall(real scalar i, real scalar j, real scalar N,
                                real scalar K)
{
    real scalar k
    real matrix C
    C = J(0, N * K, .)
    for (k = 1; k <= K; k++) {
        C = C \ _surardl_Clrpair(i, j, k, N, K)
    }
    return(C)
}

// Contrast for H0: theta_{k,1} = ... = theta_{k,N} (N-1 restrictions).
real matrix _surardl_Clrpool(real scalar k, real scalar N, real scalar K)
{
    real scalar i
    real matrix C
    C = J(0, N * K, .)
    for (i = 2; i <= N; i++) {
        C = C \ _surardl_Clrpair(i, 1, k, N, K)
    }
    return(C)
}

// ==================================================================
// Multiple-testing adjustment of a vector of p-values.
// method 1 = Bonferroni, 2 = Holm, 3 = Sidak (all capped at 1).
// Section 4.5 of the paper recommends such a correction for the
// pairwise long-run equality tests, where the maximum pairwise
// rejection rate reaches 53% at N = 5, T = 50.
// ==================================================================
real colvector _surardl_padj(real colvector p, real scalar method)
{
    real scalar m, i, mx
    real colvector a, o, s

    m = rows(p)
    a = p
    if (m < 1) {
        return(a)
    }
    if (method == 1) {
        a = p :* m
    }
    if (method == 3) {
        a = 1 :- (1 :- p) :^ m
    }
    if (method == 2) {
        o = order(p, 1)
        s = p[o]
        mx = 0
        for (i = 1; i <= m; i++) {
            s[i] = s[i] * (m - i + 1)
            if (s[i] < mx) {
                s[i] = mx
            }
            mx = s[i]
        }
        a[o] = s
    }
    for (i = 1; i <= m; i++) {
        if (a[i] > 1) {
            a[i] = 1
        }
    }
    return(a)
}

// ==================================================================
// Sigma-hat quality diagnostics. Returns
//   (N, T, T/N, reciprocal condition number, min eigenvalue,
//    1 if positive definite else 0, mean |off-diagonal correlation|,
//    relative Frobenius norm of the off-diagonal part)
// The last quantity is the natural reading of the "RFN" referred to in
// section 5 of the paper; its defining equation is not given in the
// draft, so it is documented here as surardl's own definition:
//   RFN = ||Sigma - diag(Sigma)||_F / ||Sigma||_F.
// ==================================================================
real rowvector _surardl_sigdiag(real matrix S, real scalar T)
{
    real scalar N, i, j, pd, sa, nf, df, fo, ft
    real matrix R
    real colvector ev

    N  = rows(S)
    R  = S :/ sqrt(diagonal(S) * diagonal(S)')
    ev = symeigenvalues(S)'
    pd = 1
    if (min(ev) <= 0) {
        pd = 0
    }
    sa = 0
    df = N * (N - 1) / 2
    for (i = 2; i <= N; i++) {
        for (j = 1; j <= i - 1; j++) {
            sa = sa + abs(R[i, j])
        }
    }
    fo = 0
    ft = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            ft = ft + S[i, j] * S[i, j]
            if (i != j) {
                fo = fo + S[i, j] * S[i, j]
            }
        }
    }
    nf = sqrt(fo) / sqrt(ft)
    return((N, T, T / N, min(ev) / max(ev), min(ev), pd, sa / df, nf))
}


// ================================================================
// from _sa_load.mata
// ================================================================

// ==================================================================
// Assemble the matrix of level series required by _surardl_build().
//
// Reads the long panel (one row per unit-period) and lays it out as
// LV (Tfull x N*(K+1)), with the column block of unit i ordered
// y_i, x_1i, ..., x_Ki. The window [t0, t1] must already be balanced
// and gap-free; the caller guarantees this.
//
// ids holds the panel values in the order the equations are to appear.
// Returns 0 on success, or the 1-based row of the first cell that
// could not be filled (which would indicate an unbalanced window).
// ==================================================================
real scalar _surardl_load(string scalar vlist, string scalar touse,
        string scalar ivar, string scalar tvar, real colvector ids,
        real scalar t0, real scalar delta, real scalar Tfull,
        real scalar K, string scalar lvname)
{
    real matrix D, LV, FL
    real colvector uv, tv
    real scalar n, r, i, ti, v, N, c

    N  = rows(ids)
    D  = st_data(., vlist, touse)
    uv = st_data(., ivar, touse)
    tv = st_data(., tvar, touse)
    n  = rows(D)

    LV = J(Tfull, N * (K + 1), .)
    FL = J(Tfull, N, 0)

    for (r = 1; r <= n; r++) {
        ti = (tv[r] - t0) / delta + 1
        if (ti < 1 | ti > Tfull) {
            continue
        }
        i = 0
        for (c = 1; c <= N; c++) {
            if (ids[c] == uv[r]) {
                i = c
            }
        }
        if (i == 0) {
            continue
        }
        for (v = 0; v <= K; v++) {
            LV[ti, _surardl_col(i, v, K)] = D[r, v + 1]
        }
        FL[ti, i] = 1
    }
    if (min(FL) == 0) {
        return(1)
    }
    st_matrix(lvname, LV)
    return(0)
}

// Lay a user-supplied trend variable out on the estimation window.
void _sa_trendvar(string scalar v, string scalar touse, string scalar tvar,
        real scalar t0, real scalar delta, real scalar Tfull,
        string scalar trname)
{
    real colvector tv, xv, TR
    real scalar r, ti

    xv = st_data(., v, touse)
    tv = st_data(., tvar, touse)
    TR = J(Tfull, 1, .)
    for (r = 1; r <= rows(tv); r++) {
        ti = (tv[r] - t0) / delta + 1
        if (ti >= 1 & ti <= Tfull) {
            TR[ti] = xv[r]
        }
    }
    st_matrix(trname, TR)
}


// ================================================================
// from _sa_main.mata
// ================================================================

// ==================================================================
// Information-criterion lag selection, Remark 2 and equations
// (19)-(20). Every candidate is fitted on the SAME effective sample,
// the one implied by the maximum lag orders, so the criteria are
// comparable across candidates and Sigma-hat is defined on a common
// window. AIC = T ln(s2) + 2m and SBC = T ln(s2) + m ln T; these are
// monotone equivalents of the paper's equations (19)-(20).
// crit: 1 = AIC, 2 = SBC.
// Returns the N x (1+K) matrix of selected orders.
// ==================================================================
// Helper: unit i keeps its candidate orders while every other unit is
// pinned at the maximum orders, so _surardl_lagmax() -- and therefore
// the effective sample -- stays fixed across candidates.
real matrix _surardl_padlags(real matrix LAGS, real matrix LFIX,
                             real scalar i, real scalar K)
{
    real matrix L
    L = LFIX
    L[i, .] = LAGS[i, .]
    return(L)
}

real matrix _surardl_lagsel(real matrix LV, real colvector TR, real scalar N,
        real scalar K, real scalar cs, real scalar pmax, real rowvector qmax,
        real scalar crit, real scalar qmin, real scalar maxcomb,
        real scalar ncomb)
{
    real matrix LAGS, LFIX, cand
    real scalar i, j, k, p, nc, T, bic, s2, m, v, ok
    real rowvector q, qb
    struct surardl_eq vector E
    real colvector bols, seols, rssv, r2v, rmsev
    real matrix U

    // enumerate candidate (p, q_1..q_K) combinations
    nc = pmax
    for (k = 1; k <= K; k++) {
        nc = nc * (qmax[k] - qmin + 1)
    }
    ncomb = nc
    LAGS  = J(N, K + 1, 1)
    if (nc > maxcomb) {
        return(J(0, 0, .))
    }

    cand = J(nc, K + 1, .)
    j = 0
    for (p = 1; p <= pmax; p++) {
        q = J(1, K, qmin)
        for (v = 1; v <= nc / pmax; v++) {
            j = j + 1
            cand[j, 1] = p
            cand[j, (2..(K+1))] = q
            // odometer increment over q
            k = K
            ok = 1
            while (k >= 1 & ok) {
                q[k] = q[k] + 1
                if (q[k] > qmax[k]) {
                    q[k] = qmin
                    k = k - 1
                }
                else {
                    ok = 0
                }
            }
        }
    }

    // the fixed sample is set by the maximum orders
    LFIX = J(N, K + 1, 1)
    LFIX[., 1] = J(N, 1, pmax)
    for (k = 1; k <= K; k++) {
        LFIX[., k+1] = J(N, 1, qmax[k])
    }
    T = rows(LV) - _surardl_lagmax(LFIX, K)

    for (i = 1; i <= N; i++) {
        bic = .
        qb  = LAGS[i, .]
        for (j = 1; j <= nc; j++) {
            LAGS[i, .] = cand[j, .]
            // build only unit i on the fixed window
            E = _surardl_build(LV, TR, N, K, _surardl_padlags(LAGS, LFIX, i, K),
                               cs, "y", J(1, K, "x"))
            if (rows(E[i].y) != T) {
                continue
            }
            if (rank(quadcross(E[i].X, E[i].X)) < E[i].m) {
                continue
            }
            U  = _surardl_ols(E, bols, seols, rssv, r2v, rmsev)
            m  = E[i].m
            s2 = rssv[i] / T
            if (crit == 1) {
                v = T * ln(s2) + 2 * m
            }
            else {
                v = T * ln(s2) + m * ln(T)
            }
            if (v < bic) {
                bic = v
                qb  = cand[j, .]
            }
        }
        LAGS[i, .] = qb
    }
    return(LAGS)
}

// ==================================================================
// Main driver. Reads its configuration from Stata, estimates the
// system, runs the requested inference and posts everything back.
// ==================================================================
void _surardl_main()
{
    struct surardl_eq vector E
    real matrix LV, LAGS, S, Si, U, U0, V, G, R, C, B1, B0
    real matrix bnd, cvF, cvt, cvN, decF, decN, dect, LR, FI, EFF, FIT
    real matrix bcv, bpv, scv0, scv1, SIMd
    string matrix stripe
    real colvector TR, th, bols, seols, rssv, r2v, rmsev, thLR, Fr
    real rowvector w, dg, bp, sd, qmax
    real scalar N, K, cs, dfk, iterate, tol, lev, M, T, i, k, j, z, il, ib
    real scalar nit, conv, breps, bseed, btarget, bdgp, blags, sreps, srho, bndrift
    real scalar bglag, rssform, nfail, pmax, crit, maxcomb, ncomb, qmin
    real scalar lam, bet, vll, vbb, vlb, nf2
    string scalar dep
    string rowvector xn
    string matrix eqn

    LV   = st_matrix("__sa_LV")
    TR   = st_matrix("__sa_TR")
    N    = st_numscalar("__sa_N")
    K    = st_numscalar("__sa_K")
    cs   = st_numscalar("__sa_case")
    dfk  = st_numscalar("__sa_dfk")
    iterate = st_numscalar("__sa_iterate")
    tol  = st_numscalar("__sa_tol")
    lev  = st_numscalar("__sa_level")
    rssform = st_numscalar("__sa_rssform")
    bglag   = st_numscalar("__sa_bglags")
    breps   = st_numscalar("__sa_breps")
    bseed   = st_numscalar("__sa_bseed")
    btarget = st_numscalar("__sa_btarget")
    bdgp    = st_numscalar("__sa_bdgp")
    blags   = st_numscalar("__sa_blags")
    bndrift = st_numscalar("__sa_bndrift")
    sreps   = st_numscalar("__sa_sreps")
    srho    = st_numscalar("__sa_srho")

    dep = st_local("depvar")
    xn  = tokens(st_local("xvars"))
    eqn = tokens(st_local("eqnames"))'

    // ---------------- lag orders ----------------
    if (st_numscalar("__sa_dosel") != 0) {
        pmax = st_numscalar("__sa_pmax")
        qmax = st_matrix("__sa_qmax")
        crit = st_numscalar("__sa_crit")
        qmin = st_numscalar("__sa_qmin")
        maxcomb = st_numscalar("__sa_maxcomb")
        ncomb = 0
        LAGS = _surardl_lagsel(LV, TR, N, K, cs, pmax, qmax, crit, qmin,
                               maxcomb, ncomb)
        st_numscalar("__sa_ncomb", ncomb)
        if (rows(LAGS) == 0) {
            st_numscalar("__sa_rc", 459)
            return
        }
    }
    else {
        LAGS = st_matrix("__sa_lags")
    }
    st_matrix("__sa_lagsout", LAGS)

    // ---------------- estimation ----------------
    E = _surardl_build(LV, TR, N, K, LAGS, cs, dep, xn)
    M = _surardl_M(E)
    T = rows(E[1].y)
    st_numscalar("__sa_T", T)
    st_numscalar("__sa_M", M)

    for (i = 1; i <= N; i++) {
        if (T - E[i].m < 1) {
            st_numscalar("__sa_rc", 2001)
            return
        }
        if (rank(quadcross(E[i].X, E[i].X)) < E[i].m) {
            st_numscalar("__sa_rc", 459)
            st_numscalar("__sa_badeq", i)
            return
        }
    }
    if (T <= N) {
        st_numscalar("__sa_rc", 2001)
        return
    }

    U0 = _surardl_ols(E, bols, seols, rssv, r2v, rmsev)
    if (st_numscalar("__sa_ols") != 0) {
        // equation-by-equation OLS benchmark: block-diagonal variance
        S  = _surardl_sigma(U0, E, dfk)
        th = bols
        V  = J(M, M, 0)
        for (i = 1; i <= N; i++) {
            V[|E[i].off+1, E[i].off+1 \ E[i].off+E[i].m, E[i].off+E[i].m|] =
                (rssv[i] / (T - E[i].m)) *
                invsym(quadcross(E[i].X, E[i].X))
        }
        U    = U0
        nit  = 0
        conv = 1
    }
    else {
        _surardl_fgls(E, U0, dfk, iterate, tol, th, V, S, U, nit, conv)
    }
    Si = invsym(S)

    st_numscalar("__sa_nit",  nit)
    st_numscalar("__sa_conv", conv)
    st_matrix("__sa_Sigma", S)
    st_matrix("__sa_Corr",  S :/ sqrt(diagonal(S) * diagonal(S)'))

    // coefficient stripe: equation name, coefficient name
    stripe = J(M, 2, "")
    for (i = 1; i <= N; i++) {
        for (k = 1; k <= E[i].m; k++) {
            stripe[E[i].off + k, 1] = eqn[i]
            stripe[E[i].off + k, 2] = E[i].cn[k]
        }
    }
    st_matrix("__sa_b", th')
    st_matrixcolstripe("__sa_b", stripe)
    st_matrix("__sa_V", V)
    st_matrixcolstripe("__sa_V", stripe)
    st_matrixrowstripe("__sa_V", stripe)

    // OLS standard errors and the efficiency gain of equation (95)
    EFF = J(M, 3, .)
    EFF[., 1] = seols
    EFF[., 2] = sqrt(diagonal(V))
    EFF[., 3] = 1 :- EFF[., 2] :/ EFF[., 1]
    st_matrix("__sa_eff", EFF)
    st_matrixrowstripe("__sa_eff", stripe)

    // per-equation fit
    FIT = J(N, 5, .)
    for (i = 1; i <= N; i++) {
        FIT[i, 1] = quadcross(U[., i], U[., i])
        FIT[i, 2] = rssv[i]
        FIT[i, 3] = r2v[i]
        FIT[i, 4] = T - E[i].m
        FIT[i, 5] = E[i].m
    }
    st_matrix("__sa_fit", FIT)

    // ---------------- bounds statistics ----------------
    bnd = J(N, 5, .)
    for (i = 1; i <= N; i++) {
        R = _surardl_R(E, i, M)
        w = _surardl_wald(R, th, V)
        bnd[i, 1] = w[3]
        bnd[i, 2] = w[1]
        bnd[i, 4] = w[2]
        il = E[i].off + E[i].ilam
        bnd[i, 3] = th[il] / sqrt(V[il, il])
        R = _surardl_Rbeta(E, i, M)
        w = _surardl_wald(R, th, V)
        bnd[i, 5] = w[3]
    }
    if (rssform != 0) {
        Fr = _surardl_rssF(E, Si, FIT[., 1], rssform - 1)
        st_matrix("__sa_Frss", Fr)
    }
    st_matrix("__sa_bnd", bnd)

    // joint test, equations (78)-(79)
    R = _surardl_Rjoint(E, (1..N), M)
    w = _surardl_wald(R, th, V)
    st_matrix("__sa_joint", (w[1], w[2], w[3], chi2tail(w[2], w[1])))

    // tabulated critical values (k and the case are common to all
    // equations, so one lookup serves the whole system)
    cvF = _surardl_cvF_pss(cs, K)
    cvt = _surardl_cvt_pss(cs, K)
    cvN = _surardl_cvF_nar(cs, K, T)
    st_matrix("__sa_cvF", cvF)
    st_matrix("__sa_cvt", cvt)
    st_matrix("__sa_cvN", cvN)

    decF = J(N, 4, .)
    dect = J(N, 4, .)
    decN = J(N, 3, .)
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= 4; j++) {
            decF[i, j] = _surardl_decide(bnd[i, 1], cvF[j, 1], cvF[j, 2], 1)
            dect[i, j] = _surardl_decide(bnd[i, 3], cvt[j, 1], cvt[j, 2], 0)
        }
        for (j = 1; j <= 3; j++) {
            decN[i, j] = _surardl_decide(bnd[i, 1], cvN[j, 1], cvN[j, 2], 1)
        }
    }
    st_matrix("__sa_decF", decF)
    st_matrix("__sa_dect", dect)
    st_matrix("__sa_decN", decN)

    // ---------------- long run ----------------
    z    = invnormal(1 - (1 - lev / 100) / 2)
    thLR = _surardl_lrvec(E, th, K)
    G    = _surardl_lrgrad(E, th, K, M)
    LR   = J(N * K, 8, .)
    FI   = J(N * K, 3, .)
    for (i = 1; i <= N; i++) {
        il  = E[i].off + E[i].ilam
        lam = th[il]
        vll = V[il, il]
        for (k = 1; k <= K; k++) {
            ib  = E[i].off + E[i].ibeta[k]
            bet = th[ib]
            vbb = V[ib, ib]
            vlb = V[il, ib]
            j   = (i-1)*K + k
            dg  = G[j, .]
            LR[j, 1] = i
            LR[j, 2] = k
            LR[j, 3] = thLR[j]
            LR[j, 4] = sqrt(dg * V * dg')
            LR[j, 5] = LR[j, 3] / LR[j, 4]
            LR[j, 6] = 2 * normal(-abs(LR[j, 5]))
            LR[j, 7] = LR[j, 3] - z * LR[j, 4]
            LR[j, 8] = LR[j, 3] + z * LR[j, 4]
            FI[j, .] = _surardl_fieller(lam, bet, vll, vbb, vlb, z)
        }
    }
    st_matrix("__sa_lr", LR)
    st_matrix("__sa_fieller", FI)

    // ---------------- diagnostics ----------------
    bp = _surardl_bpcd(U0)
    st_matrix("__sa_bpcd", bp)
    sd = _surardl_sigdiag(S, T)
    st_matrix("__sa_sigdiag", sd)
    if (bglag > 0) {
        st_matrix("__sa_bg", _surardl_bg(E, U, bglag))
    }

    // residuals for predict and for postestimation reuse
    st_matrix("__sa_resid", U)
    st_matrix("__sa_residols", U0)

    // ---------------- bootstrap, Approach B ----------------
    if (breps > 0) {
        rseed(bseed)
        if (btarget == 0) {
            B1 = _surardl_boot(LV, TR, N, K, LAGS, cs, dfk, iterate, tol,
                               breps, 0, bdgp, blags, bndrift, dep, xn, nfail)
        }
        else {
            B1 = J(breps, 3 * N, .)
            nfail = 0
            for (i = 1; i <= N; i++) {
                nf2 = 0
                B0 = _surardl_boot(LV, TR, N, K, LAGS, cs, dfk, iterate, tol,
                                   breps, i, bdgp, blags, bndrift, dep, xn, nf2)
                B1[., i]           = B0[., i]
                B1[., N + i]       = B0[., N + i]
                B1[., 2 * N + i]   = B0[., 2 * N + i]
                nfail = nfail + nf2
            }
        }
        bcv = J(N, 9, .)
        bpv = J(N, 3, .)
        for (i = 1; i <= N; i++) {
            bcv[i, 1] = _surardl_quant(B1[., i], 0.90)
            bcv[i, 2] = _surardl_quant(B1[., i], 0.95)
            bcv[i, 3] = _surardl_quant(B1[., i], 0.99)
            bcv[i, 4] = _surardl_quant(B1[., N+i], 0.10)
            bcv[i, 5] = _surardl_quant(B1[., N+i], 0.05)
            bcv[i, 6] = _surardl_quant(B1[., N+i], 0.01)
            bcv[i, 7] = _surardl_quant(B1[., 2*N+i], 0.90)
            bcv[i, 8] = _surardl_quant(B1[., 2*N+i], 0.95)
            bcv[i, 9] = _surardl_quant(B1[., 2*N+i], 0.99)
            bpv[i, 1] = _surardl_bootp(B1[., i],       bnd[i, 1], 1)
            bpv[i, 2] = _surardl_bootp(B1[., N+i],     bnd[i, 3], 0)
            bpv[i, 3] = _surardl_bootp(B1[., 2*N+i],   bnd[i, 5], 1)
        }
        st_matrix("__sa_bcv", bcv)
        st_matrix("__sa_bpv", bpv)
        st_numscalar("__sa_bfail", nfail)
        st_matrix("__sa_bdist", B1)
    }

    // ---------------- Monte Carlo bounds, Approach A ----------------
    if (sreps > 0) {
        rseed(bseed)
        SIMd = _surardl_sim(S, N, K, LAGS, cs, dfk, iterate, tol, sreps, T,
                            1, 50, srho, dep, xn, nfail)
        scv1 = J(N, 3, .)
        for (i = 1; i <= N; i++) {
            scv1[i, 1] = _surardl_quant(SIMd[., i], 0.90)
            scv1[i, 2] = _surardl_quant(SIMd[., i], 0.95)
            scv1[i, 3] = _surardl_quant(SIMd[., i], 0.99)
        }
        nf2 = 0
        SIMd = _surardl_sim(S, N, K, LAGS, cs, dfk, iterate, tol, sreps, T,
                            0, 50, srho, dep, xn, nf2)
        scv0 = J(N, 3, .)
        for (i = 1; i <= N; i++) {
            scv0[i, 1] = _surardl_quant(SIMd[., i], 0.90)
            scv0[i, 2] = _surardl_quant(SIMd[., i], 0.95)
            scv0[i, 3] = _surardl_quant(SIMd[., i], 0.99)
        }
        st_matrix("__sa_scv1", scv1)
        st_matrix("__sa_scv0", scv0)
        st_numscalar("__sa_sfail", nfail + nf2)
    }

    st_numscalar("__sa_rc", 0)
}


// ================================================================
// from _sa_estat.mata
// ================================================================

// Rebuild the equation structures from what surardl left in e(). The
// level series are stored in e(lv) so that every postestimation
// command works on exactly the estimation window, whatever has
// happened to the data in memory since.
struct surardl_eq vector _surardl_reload()
{
    real matrix LV, LAGS
    real colvector TR
    real scalar cs, N, K
    string scalar dep
    string rowvector xn

    LV   = st_matrix("e(lv)")
    TR   = st_matrix("e(tr)")
    LAGS = st_matrix("e(lags)")
    cs   = st_numscalar("e(case)")
    N    = rows(LAGS)
    K    = cols(LAGS) - 1
    dep  = st_global("e(depvar)")
    xn   = tokens(st_global("e(indepvars)"))
    return(_surardl_build(LV, TR, N, K, LAGS, cs, dep, xn))
}

// ------------------------------------------------------------------
// Pairwise and joint equality of the speeds of adjustment,
// H0: lambda_i = lambda_j and H0: lambda_1 = ... = lambda_N.
// Section 4.5(c). Returns npairs x 5: i, j, chi2, p, adjusted p.
// ------------------------------------------------------------------
void _sa_e_lamtest(real scalar padjm, string scalar outname,
                   string scalar jointname)
{
    struct surardl_eq vector E
    real matrix R, Out
    real colvector th, p
    real rowvector w
    real scalar N, M, i, j, r

    E  = _surardl_reload()
    N  = length(E)
    M  = _surardl_M(E)
    th = st_matrix("e(b)")'

    Out = J(N * (N - 1) / 2, 5, .)
    r = 0
    for (i = 1; i <= N - 1; i++) {
        for (j = i + 1; j <= N; j++) {
            r = r + 1
            R = _surardl_Rlam(E, i, j, M)
            w = _surardl_wald(R, th, st_matrix("e(V)"))
            Out[r, 1] = i
            Out[r, 2] = j
            Out[r, 3] = w[1]
            Out[r, 4] = chi2tail(1, w[1])
        }
    }
    p = Out[., 4]
    Out[., 5] = _surardl_padj(p, padjm)
    st_matrix(outname, Out)

    R = _surardl_Rpool(E, M, cols(st_matrix("e(lags)")) - 1, 2)
    w = _surardl_wald(R, th, st_matrix("e(V)"))
    st_matrix(jointname, (w[1], w[2], chi2tail(w[2], w[1])))
}

// ------------------------------------------------------------------
// Pairwise and joint equality of the long-run coefficients for
// regressor k, H0: theta_{k,i} = theta_{k,j}. Multivariate delta
// method, equations (92)-(93) and Remark 10.
// ------------------------------------------------------------------
void _sa_e_lrtest(real scalar k, real scalar padjm, string scalar outname,
                  string scalar jointname)
{
    struct surardl_eq vector E
    real matrix G, C, V, Out
    real colvector th, thLR, p
    real rowvector w
    real scalar N, M, K, i, j, r

    E    = _surardl_reload()
    N    = length(E)
    M    = _surardl_M(E)
    K    = cols(st_matrix("e(lags)")) - 1
    th   = st_matrix("e(b)")'
    V    = st_matrix("e(V)")
    thLR = _surardl_lrvec(E, th, K)
    G    = _surardl_lrgrad(E, th, K, M)

    Out = J(N * (N - 1) / 2, 6, .)
    r = 0
    for (i = 1; i <= N - 1; i++) {
        for (j = i + 1; j <= N; j++) {
            r = r + 1
            C = _surardl_Clrpair(i, j, k, N, K)
            w = _surardl_lrwald(C, thLR, G, V)
            Out[r, 1] = i
            Out[r, 2] = j
            Out[r, 3] = thLR[(i-1)*K+k] - thLR[(j-1)*K+k]
            Out[r, 4] = w[1]
            Out[r, 5] = w[3]
        }
    }
    p = Out[., 5]
    Out[., 6] = _surardl_padj(p, padjm)
    st_matrix(outname, Out)

    C = _surardl_Clrpool(k, N, K)
    w = _surardl_lrwald(C, thLR, G, V)
    st_matrix(jointname, w)
}

// ------------------------------------------------------------------
// Poolability tests, section 4.5(a). what: 1 = beta, 2 = lambda,
// 3 = short-run, 4 = beta and lambda jointly.
// ------------------------------------------------------------------
void _sa_e_pool(real scalar what, string scalar outname)
{
    struct surardl_eq vector E
    real matrix R
    real colvector th
    real rowvector w
    real scalar M, K

    E  = _surardl_reload()
    M  = _surardl_M(E)
    K  = cols(st_matrix("e(lags)")) - 1
    th = st_matrix("e(b)")'
    R  = _surardl_Rpool(E, M, K, what)
    if (rows(R) == 0) {
        st_matrix(outname, (., ., .))
        return
    }
    w = _surardl_wald(R, th, st_matrix("e(V)"))
    st_matrix(outname, (w[1], w[2], chi2tail(w[2], w[1])))
}

// Fieller sets recomputed at an arbitrary confidence level.
void _sa_e_fieller(real scalar lev, string scalar outname)
{
    struct surardl_eq vector E
    real matrix V, FI
    real colvector th
    real scalar N, K, i, k, il, ib, z

    E  = _surardl_reload()
    N  = length(E)
    K  = cols(st_matrix("e(lags)")) - 1
    th = st_matrix("e(b)")'
    V  = st_matrix("e(V)")
    z  = invnormal(1 - (1 - lev / 100) / 2)
    FI = J(N * K, 3, .)
    for (i = 1; i <= N; i++) {
        il = E[i].off + E[i].ilam
        for (k = 1; k <= K; k++) {
            ib = E[i].off + E[i].ibeta[k]
            FI[(i-1)*K+k, .] = _surardl_fieller(th[il], th[ib], V[il, il],
                                                V[ib, ib], V[il, ib], z)
        }
    }
    st_matrix(outname, FI)
}

// ------------------------------------------------------------------
// Percentile and bias-corrected bootstrap confidence intervals for
// the long-run coefficients. The resampling is done under the
// ALTERNATIVE (unrestricted residuals), which is the right null-free
// design for an interval, and it preserves the cross-equation
// covariance by drawing one time index for the whole system.
// ------------------------------------------------------------------
void _sa_e_lrboot(real scalar B, real scalar seed, real scalar lev,
                  string scalar outname)
{
    struct surardl_eq vector E, ES
    real matrix LV, LAGS, V, U, U0, S, Out, D, LVs, Ub
    real colvector TR, th, bols, seols, rssv, r2v, rmsev, idx, zrow, ths
    real colvector thLR
    real rowvector np
    real scalar N, K, M, cs, T, Tf, L, i, k, t, b, c0, ck, nit, conv, dfk
    real scalar lo, hi, z0, nb
    string scalar dep
    string rowvector xn

    LV   = st_matrix("e(lv)")
    TR   = st_matrix("e(tr)")
    LAGS = st_matrix("e(lags)")
    cs   = st_numscalar("e(case)")
    N    = rows(LAGS)
    K    = cols(LAGS) - 1
    dep  = st_global("e(depvar)")
    xn   = tokens(st_global("e(indepvars)"))
    dfk  = 0

    E  = _surardl_build(LV, TR, N, K, LAGS, cs, dep, xn)
    M  = _surardl_M(E)
    Tf = rows(LV)
    L  = _surardl_lagmax(LAGS, K)
    T  = Tf - L
    U0 = _surardl_ols(E, bols, seols, rssv, r2v, rmsev)
    _surardl_fgls(E, U0, dfk, 0, 1e-9, ths, V, S, U, nit, conv)

    np = J(1, N, 0)
    for (i = 1; i <= N; i++) {
        np[i] = E[i].m
    }
    U = _surardl_rescale(U, np)

    D = J(B, N * K, .)
    rseed(seed)
    for (b = 1; b <= B; b++) {
        idx = ceil(runiform(T, 1) :* T)
        idx = idx :+ (idx :< 1)
        LVs = LV
        for (t = L + 1; t <= Tf; t++) {
            for (i = 1; i <= N; i++) {
                c0   = _surardl_col(i, 0, K)
                zrow = _surardl_yrow(LVs, TR, E, i, K, t, cs, 0, 0)
                LVs[t, c0] = LVs[t-1, c0] +
                    (zrow' * ths[|E[i].off+1 \ E[i].off+E[i].m|]) +
                    U[idx[t - L], i]
            }
        }
        ES = _surardl_build(LVs, TR, N, K, LAGS, cs, dep, xn)
        U0 = _surardl_ols(ES, bols, seols, rssv, r2v, rmsev)
        _surardl_fgls(ES, U0, dfk, 0, 1e-9, th, V, S, Ub, nit, conv)
        D[b, .] = _surardl_lrvec(ES, th, K)'
    }

    thLR = _surardl_lrvec(E, ths, K)
    lo = (1 - lev / 100) / 2
    hi = 1 - lo
    Out = J(N * K, 5, .)
    for (k = 1; k <= N * K; k++) {
        Out[k, 1] = thLR[k]
        Out[k, 2] = _surardl_quant(D[., k], lo)
        Out[k, 3] = _surardl_quant(D[., k], hi)
        // bias-corrected percentile interval
        nb = colsum(select(D[., k], D[., k] :< .) :< thLR[k])
        z0 = invnormal(nb / (B + 1))
        Out[k, 4] = _surardl_quant(D[., k],
                        normal(2 * z0 + invnormal(lo)))
        Out[k, 5] = _surardl_quant(D[., k],
                        normal(2 * z0 + invnormal(hi)))
    }
    st_matrix(outname, Out)
}


end
