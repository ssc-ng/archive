*! version 2.1.0  22nov2026  Yusuf Toyin Yusuf and A. A. Kilishi
*! cgemod: SAM-based computable general equilibrium modelling, sensitivity analysis,
*!         model diagnostics and elasticity estimation with residual diagnostics

program define cgemod, rclass
    version 15
    gettoken sub rest : 0, parse(" ,")
    local sub = lower(`"`sub'"')
    if `"`sub'"' == "" {
        di as err "subcommand required: sam, samimport, samgen, samcheck, sambalance, sammonitor, samexport, compare, calibrate, sim, dynamic, ssa, scenario, poverty, check, validate, elast, or describe"
        exit 198
    }
    if "`sub'" == "sam" {
        _cgemod_sam `rest'
    }
    else if "`sub'" == "samimport" {
        _cgemod_samimport `rest'
    }
    else if "`sub'" == "poverty" {
        _cgemod_poverty `rest'
    }
    else if "`sub'" == "compare" {
        _cgemod_compare `rest'
    }
    else if "`sub'" == "samcheck" {
        _cgemod_samchk `rest'
    }
    else if inlist("`sub'", "sambalance", "sambal") {
        _cgemod_sambal `rest'
    }
    else if inlist("`sub'", "sammonitor", "sammon") {
        _cgemod_sammon `rest'
    }
    else if "`sub'" == "samexport" {
        _cgemod_samexport `rest'
    }
    else if inlist("`sub'", "calibrate", "calib", "cal") {
        _cgemod_cal `rest'
        global CGEMOD_calopts `"`rest'"'
    }
    else if "`sub'" == "samgen" {
        _cgemod_samgen `rest'
    }
    else if inlist("`sub'", "scenario", "scen") {
        _cgemod_scen `rest'
    }
    else if inlist("`sub'", "validate", "valid") {
        _cgemod_validate `rest'
    }
    else if "`sub'" == "sim" {
        _cgemod_sim `rest'
    }
    else if inlist("`sub'", "dynamic", "dyn") {
        _cgemod_dyn `rest'
    }
    else if "`sub'" == "ssa" {
        _cgemod_ssa `rest'
    }
    else if "`sub'" == "check" {
        _cgemod_check `rest'
    }
    else if inlist("`sub'", "elast", "elasticity") {
        _cgemod_elast `rest'
    }
    else if inlist("`sub'", "describe", "des") {
        _cgemod_needmodel
        mata: _cgemod_describe()
    }
    else {
        di as err "unknown subcommand {bf:`sub'}"
        exit 198
    }
    return add
end

* ---------------------------------------------------------------------------
program define _cgemod_needmodel
    mata: st_local("ok", strofreal(findexternal("_cgemod_M") != NULL))
    if "`ok'" != "1" {
        di as err "no calibrated model in memory; run {bf:cgemod calibrate} first"
        exit 301
    }
end

* ---------------------------------------------------------------------------
program define _cgemod_sam, rclass
    syntax [varlist(numeric default=none)] [if] [in] [, LABel(varname) ///
        MATrix(name) NAME(name) BALance TOLerance(real 1e-10) MAXiter(integer 5000) noLIST]
    if "`name'" == "" local name "CGESAM"
    if "`matrix'" != "" & "`varlist'" != "" {
        di as err "specify either a varlist with label() or matrix(), not both"
        exit 198
    }
    if "`matrix'" == "" {
        if "`varlist'" == "" | "`label'" == "" {
            di as err "specify the SAM columns as a varlist together with label(), or use matrix()"
            exit 198
        }
        confirm string variable `label'
        marksample touse, novarlist
        mata: _cgemod_samfromdata("`varlist'", "`label'", "`touse'", "`name'")
    }
    else {
        confirm matrix `matrix'
        if "`matrix'" != "`name'" matrix `name' = `matrix'
    }
    mata: _cgemod_samcheck("`name'", "`balance'" != "", `tolerance', `maxiter', "`list'" == "")
    return scalar accounts = `naccounts'
    return scalar total = `samtotal'
    return scalar maxdiff = `maxdiff'
    if "`balance'" != "" {
        return scalar maxdiff_before = `maxdiff0'
        return scalar iterations = `rasit'
        return scalar converged = `rasconv'
    }
    return local name "`name'"
end

* ---------------------------------------------------------------------------
program define _cgemod_cal, rclass
    syntax , SAM(name) [ACTivities(string) COMmodities(string) FACtors(string)       ///
        HOUseholds(string) GOVernment(string) ROW(string) SAVinv(string)              ///
        ENTerprises(string) MARgins(string) STOCKs(string) TAXes(string) TARiff(string) EXPtax(string) ///
         SIGMAVA(string) SIGMAQ(string) OMEGA(string) SIGMAX(string) FRISCH(real -1) INCELas(string) ///
         SPECific(string) UNEMPloyed(string) WAGECurve(string) URate(string) ELASW(string) ///
         EMISsions(string) PEMISsions(string) FISCal(string)                         ///
         EXChange(string) GSAV(string)            ///
         SICLOSure(string) TOLerance(real 1e-10) MAXiter(integer 100) SOLver(string) noTABle]
    confirm matrix `sam'
    if "`solver'" == "" local solver "newton"
    local solver = lower("`solver'")
    if !inlist("`solver'", "newton", "broyden") {
        di as err "solver() must be newton or broyden"
        exit 198
    }
    if "`activities'" == "" | "`commodities'" == "" {
        mata: _cgemod_getroles("`sam'")
    }
    foreach r in activities commodities factors households government row savinv {
        if "``r''" == "" {
            di as err "`r'() is required (or import the SAM with {bf:cgemod samimport} to detect roles)"
            exit 198
        }
    }
    if "`exchange'" == "" local exchange "flexible"
    if "`gsav'" == "" local gsav "flexible"
    if "`siclosure'" == "" local siclosure "savings"
    local exchange = lower("`exchange'")
    local gsav = lower("`gsav'")
    local siclosure = lower("`siclosure'")
    if !inlist("`exchange'", "flexible", "fixed") {
        di as err "exchange() must be flexible or fixed"
        exit 198
    }
    if "`fiscal'" == "" local fiscal "dirtax"
    local fiscal = lower("`fiscal'")
    if !inlist("`fiscal'", "dirtax", "transfers", "salestax", "spending") {
        di as err "fiscal() must be dirtax, transfers, salestax or spending"
        exit 198
    }
    if !inlist("`gsav'", "flexible", "fixed") {
        di as err "gsav() must be flexible or fixed"
        exit 198
    }
    if !inlist("`siclosure'", "savings", "investment") {
        di as err "siclosure() must be savings or investment"
        exit 198
    }
    if `frisch' >= 0 {
        di as err "frisch() must be negative (use -1 for Cobb-Douglas demand)"
        exit 198
    }
    if `tolerance' <= 0 | `maxiter' < 1 {
        di as err "tolerance() must be positive and maxiter() at least 1"
        exit 198
    }
    mata: _cgemod_calib()
    return scalar activities = `na'
    return scalar commodities = `nc'
    return scalar sectors = `na'
    return scalar factors = `nf'
    return scalar households = `nh'
    return scalar enterprises = `ne'
    return scalar bench_resid = `benchres'
    return local closure "exchange(`exchange') gsav(`gsav') siclosure(`siclosure')"
    return local solver "`solver'"
    return local sam "`sam'"
end

* ---------------------------------------------------------------------------
program define _cgemod_sim, rclass
    syntax [, TM(string) TQ(string) TA(string) TE(string) TY(string) PWM(string) ///
        PWE(string) FS(string) WF(string) TFP(string) GADJ(string) FSAV(string) CTAX(string) MQUOTA(string) XQUOTA(string) PCAP(string) TMSCHED(string) GSAVShare(string) QG(string)    ///
        TITle(string) SAVing(string asis) noTABle]
    _cgemod_needmodel
    mata: _cgemod_sim()
    if `"`saving'"' != "" {
        gettoken fn sopt : saving, parse(",")
        gettoken comma sopt : sopt, parse(",")
        local rn : rownames __cgemod_sector
        preserve
        qui {
            clear
            svmat double __cgemod_sector, names(col)
            gen str32 sector = ""
            local i = 0
            foreach r of local rn {
                local ++i
                replace sector = "`r'" in `i'
            }
            order sector
            label data "cgemod simulation: % change from benchmark"
        }
        save `"`fn'"', `sopt'
        restore
    }
    return scalar iterations = `iter'
    return scalar jacobians = `njac'
    return scalar max_resid = `maxres'
    return scalar walras = `walras'
    return matrix macro = __cgemod_macro
    return matrix sector = __cgemod_sector
    return matrix commodity = __cgemod_commodity
    return matrix prices = __cgemod_prices
    return matrix factor = __cgemod_factor
    return matrix household = __cgemod_hh
end

* ---------------------------------------------------------------------------
* Scenario manager
program define _cgemod_scen, rclass
    gettoken act rest : 0, parse(" ,")
    local act = lower(`"`act'"')
    if "`act'" == "define" | "`act'" == "def" {
        _cgemod_scdef `rest'
    }
    else if "`act'" == "list" {
        _cgemod_sclist
    }
    else if "`act'" == "drop" {
        _cgemod_scdrop `rest'
    }
    else if "`act'" == "run" {
        _cgemod_scrun `rest'
        return add
    }
    else if "`act'" == "table" {
        _cgemod_scok
        mata: _cgemod_sctable()
    }
    else if "`act'" == "graph" {
        _cgemod_scgraph `rest'
    }
    else if "`act'" == "export" {
        _cgemod_scexport `rest'
    }
    else {
        di as err "scenario: specify define, list, drop, run, table, graph or export"
        exit 198
    }
end

program define _cgemod_scdef
    gettoken name 0 : 0, parse(" ,")
    capture confirm name `name'
    if _rc | strlen("`name'") > 20 {
        di as err "scenario name must be a valid Stata name of at most 20 characters"
        exit 198
    }
    syntax [, CLOSure(string) DESCription(string) REPLACE *]
    local simopts `"`options'"'
    * validate the option names against cgemod sim
    local 0 `", `simopts'"'
    capture syntax [, TM(string) TQ(string) TA(string) TE(string) TY(string) PWM(string)        ///
        PWE(string) FS(string) WF(string) TFP(string) GADJ(string) FSAV(string) CTAX(string)    ///
        MQUOTA(string) XQUOTA(string) PCAP(string) TMSCHED(string) GSAVShare(string) QG(string)]
    if _rc {
        di as err "scenario `name': `simopts' contains an option that {bf:cgemod sim} does not allow"
        exit 198
    }
    if `"`closure'"' != "" {
        local 0 `", `closure'"'
        capture syntax [, EXChange(string) GSAV(string) SICLOSure(string) FISCal(string)]
        if _rc {
            di as err "scenario `name': closure() takes exchange(), gsav(), siclosure() and fiscal()"
            exit 198
        }
    }
    local list $CGEMOD_scen
    local there : list name in list
    if `there' & "`replace'" == "" {
        di as err "scenario `name' already defined; specify replace"
        exit 110
    }
    if !`there' global CGEMOD_scen $CGEMOD_scen `name'
    global CGEMOD_scs_`name' `"`simopts'"'
    global CGEMOD_scc_`name' `"`closure'"'
    global CGEMOD_scd_`name' `"`description'"'
    di as txt "scenario {res:`name'} defined: " as res `"`simopts'"' as txt cond(`"`closure'"' != "", `" closure: `closure'"', "")
end

program define _cgemod_sclist
    local list $CGEMOD_scen
    if "`list'" == "" {
        di as txt "no scenarios defined"
        exit
    }
    di _n as txt "{hline 20}{c TT}{hline 57}"
    di as txt %-20s "Scenario" "{c |} Shocks / closure / description"
    di as txt "{hline 20}{c +}{hline 57}"
    foreach s of local list {
        di as txt %-20s "`s'" "{c |} " as res `"${CGEMOD_scs_`s'}"'
        if `"${CGEMOD_scc_`s'}"' != "" di as txt _col(21) "{c |} closure: " as res `"${CGEMOD_scc_`s'}"'
        if `"${CGEMOD_scd_`s'}"' != "" di as txt _col(21) "{c |} " `"${CGEMOD_scd_`s'}"'
    }
    di as txt "{hline 20}{c BT}{hline 57}"
end

program define _cgemod_scdrop
    local 0 `0'
    local list $CGEMOD_scen
    if "`0'" == "_all" | "`0'" == "" {
        foreach s of local list {
            macro drop CGEMOD_scs_`s' CGEMOD_scc_`s' CGEMOD_scd_`s'
        }
        macro drop CGEMOD_scen
        exit
    }
    foreach s of local 0 {
        local there : list s in list
        if !`there' {
            di as err "scenario `s' not defined"
            exit 111
        }
        macro drop CGEMOD_scs_`s' CGEMOD_scc_`s' CGEMOD_scd_`s'
        local list : list list - s
    }
    global CGEMOD_scen `list'
end

program define _cgemod_scok
    capture confirm matrix __cgemod_scmac
    if _rc {
        di as err "no scenario results; run {bf:cgemod scenario run} first"
        exit 301
    }
end

program define _cgemod_scrun, rclass
    syntax [anything(name=names)] [, POVerty(string) noTABle]
    _cgemod_needmodel
    local all $CGEMOD_scen
    if "`names'" == "" local names `all'
    if "`names'" == "" {
        di as err "no scenarios defined; use {bf:cgemod scenario define}"
        exit 198
    }
    foreach s of local names {
        local there : list s in all
        if !`there' {
            di as err "scenario `s' not defined"
            exit 111
        }
    }
    if `"`poverty'"' != "" {
        quietly count
        if r(N) == 0 {
            di as err "poverty() needs the household survey in memory"
            exit 2000
        }
    }
    local calbase = ustrregexra(`"$CGEMOD_calopts"', "(?i)\bnotab[a-z]*\b", "")
    local recal 0
    local ns : word count `names'
    local k 0
    local failed
    foreach s of local names {
        local ++k
        local cl `"${CGEMOD_scc_`s'}"'
        if `"`cl'"' != "" {
            local cb = ustrregexra(`"`calbase'"', "(?i)\b(exc[a-z]*|gsav|siclos[a-z]*|fisc[a-z]*)\([^)]*\)", "")
            capture quietly cgemod calibrate `cb' `cl' notable
            if _rc {
                di as err "scenario `s': calibration with closure `cl' failed"
                exit _rc
            }
            local recal 1
        }
        else if `recal' {
            quietly cgemod calibrate `calbase' notable
            local recal 0
        }
        di as txt "scenario {res:`s'} (`k' of `ns') ..." _c
        capture quietly cgemod sim, ${CGEMOD_scs_`s'} notable
        local rc = _rc
        if `rc' {
            di as err " failed (" _rc ")"
            local failed `failed' `s'
            mata: _cgemod_sccollect(`k', `ns', 0)
            continue
        }
        di as txt " solved in " as res r(iterations) as txt " iterations"
        mata: _cgemod_sccollect(`k', `ns', 1)
        if `"`poverty'"' != "" {
            capture quietly cgemod poverty, `poverty' notable
            if _rc {
                di as err "scenario `s': cgemod poverty, `poverty' failed"
                exit _rc
            }
            mata: _cgemod_scpov(`k', `ns')
        }
    }
    if `recal' quietly cgemod calibrate `calbase' notable
    global CGEMOD_scrun `names'
    mata: _cgemod_scfinish("`names'")
    if "`table'" == "" mata: _cgemod_sctable()
    if "`failed'" != "" di as err "scenarios that failed to solve: `failed'"
    return local scenarios "`names'"
    return local failed "`failed'"
    return matrix macro = __cgemod_scmac, copy
    return matrix sector = __cgemod_scsec, copy
    return matrix ev = __cgemod_scev, copy
    return matrix evpct = __cgemod_scevp, copy
    return matrix wage = __cgemod_scwage, copy
    capture confirm matrix __cgemod_scpov
    if !_rc return matrix poverty = __cgemod_scpov, copy
end

program define _cgemod_scgraph
    syntax [, INDicators(string) HOUseholds SAVing(string asis) NAME(string) TITle(string)]
    _cgemod_scok
    if "`indicators'" == "" local indicators "RGDP RCONS RINV REXP RIMP"
    local mat __cgemod_scmac
    local ylab "% change (levels for balances)"
    if "`households'" != "" {
        local mat __cgemod_scevp
        local ylab "Equivalent variation, % of base spending"
        local indicators : rownames __cgemod_scevp
    }
    local sc : colnames `mat'
    local rn : rownames `mat'
    preserve
    qui {
        clear
        local nr = 0
        foreach ind of local indicators {
            local r : list posof "`ind'" in rn
            if `r' == 0 {
                noi di as err "indicator `ind' not found; choose from `rn'"
                exit 111
            }
            local j = 0
            foreach s of local sc {
                local ++j
                local ++nr
                set obs `nr'
                if `nr' == 1 {
                    gen str32 item = ""
                    gen str32 scenario = ""
                    gen double value = .
                }
                replace item = "`ind'" in `nr'
                replace scenario = "`s'" in `nr'
                replace value = `mat'[`r', `j'] in `nr'
            }
        }
    }
    if `"`title'"' == "" local title "Scenario comparison"
    local gopts
    if "`name'" != "" local gopts `"name(`name')"'
    if `"`saving'"' != "" local gopts `"`gopts' saving(`saving')"'
    graph bar (asis) value, over(scenario) over(item) asyvars ytitle("`ylab'") title(`"`title'"') ///
        legend(rows(1)) `gopts'
    restore
end

program define _cgemod_scexport
    syntax using/ [, REPLACE TITle(string)]
    local ext = lower(substr(`"`using'"', strrpos(`"`using'"', ".") + 1, .))
    if !inlist("`ext'", "html", "htm", "xlsx", "xls", "csv") {
        di as err "export file must end in .html, .xlsx, .xls or .csv"
        exit 198
    }
    _cgemod_scok
    if "`ext'" == "html" | "`ext'" == "htm" {
        if "`replace'" == "" {
            capture confirm new file `"`using'"'
            if _rc {
                di as err `"file `using' already exists; specify replace"'
                exit 602
            }
        }
        if `"`title'"' == "" local title "cgemod scenario dashboard"
        mata: _cgemod_scdash(`"`using'"', `"`title'"')
        di as txt `"dashboard written to {browse "`using'"}"'
    }
    else if "`ext'" == "xlsx" | "`ext'" == "xls" {
        local first 1
        foreach m in scmac scsec scev scevp scwage scpov {
            capture confirm matrix __cgemod_`m'
            if _rc continue
            if "`m'" == "scmac" local sh "Macro"
            if "`m'" == "scsec" local sh "Output"
            if "`m'" == "scev" local sh "EV"
            if "`m'" == "scevp" local sh "EV_pct"
            if "`m'" == "scwage" local sh "Wages"
            if "`m'" == "scpov" local sh "Poverty"
            if `first' {
                if "`replace'" != "" quietly putexcel set `"`using'"', sheet("`sh'") replace
                else quietly putexcel set `"`using'"', sheet("`sh'")
                local first 0
            }
            else quietly putexcel set `"`using'"', sheet("`sh'") modify
            quietly putexcel A1 = matrix(__cgemod_`m'), names
        }
        quietly putexcel set `"`using'"', sheet("Scenarios") modify
        quietly putexcel A1 = "Scenario" B1 = "Shocks" C1 = "Closure" D1 = "Description"
        local r 1
        foreach s of global CGEMOD_scrun {
            local ++r
            quietly putexcel A`r' = "`s'" B`r' = `"${CGEMOD_scs_`s'}"' C`r' = `"${CGEMOD_scc_`s'}"' D`r' = `"${CGEMOD_scd_`s'}"'
        }
        quietly putexcel clear
        di as txt `"scenario results written to {browse "`using'"}"'
    }
    else if "`ext'" == "csv" {
        preserve
        qui {
            clear
            gen str12 block = ""
            gen str32 item = ""
            gen str32 scenario = ""
            gen double value = .
            foreach m in scmac scsec scev scevp scwage scpov {
                capture confirm matrix __cgemod_`m'
                if _rc continue
                local rn : rownames __cgemod_`m'
                local cn : colnames __cgemod_`m'
                local i 0
                foreach r of local rn {
                    local ++i
                    local j 0
                    foreach c of local cn {
                        local ++j
                        local n = _N + 1
                        set obs `n'
                        replace block = substr("`m'", 3, .) in `n'
                        replace item = "`r'" in `n'
                        replace scenario = "`c'" in `n'
                        replace value = __cgemod_`m'[`i', `j'] in `n'
                    }
                }
            }
            export delimited using `"`using'"', `replace'
        }
        restore
        di as txt `"scenario results written to {browse "`using'"}"'
    }
    else {
        di as err "export file must end in .html, .xlsx, .xls or .csv"
        exit 198
    }
end

* ---------------------------------------------------------------------------
program define _cgemod_dyn, rclass
    syntax , PERiods(integer) [LABor(string) CAPital(string) LGRowth(string)       ///
        TFPGRowth(string) GDPGrowth(string) POPGrowth(string) POPulation(string)  ///
        GGRowth(real 0) FSAVGRowth(real 0) PUBShare(real 0) PUBDep(real 0.05)      ///
        PUBElas(string) PUBINV(real 0) EDUCom(string) EDULabor(string)            ///
        EDUElas(real 0) EDUDep(real 0.1) QG(string)                               ///
        DEPRec(real 0.05) RATE(real 0.10) MOBility(real 1)      ///
        START(integer 1) DEBT0(real 0) TM(string) TQ(string) TA(string) TE(string) TY(string)   ///
        PWM(string) PWE(string) FS(string) WF(string) TFP(string) GADJ(string)    ///
        FSAV(string) CTAX(string) MQUOTA(string) XQUOTA(string) PCAP(string) TMSCHED(string) GSAVShare(string) SAVing(string asis) noTABle]
    _cgemod_needmodel
    if `periods' < 1 {
        di as err "periods() must be at least 1"
        exit 198
    }
    if `start' < 0 | `start' > `periods' {
        di as err "start() must lie between 0 and periods()"
        exit 198
    }
    if `deprec' < 0 | `deprec' >= 1 | `rate' + `deprec' <= 0 {
        di as err "invalid deprec() or rate()"
        exit 198
    }
    if `pubshare' < 0 | `pubshare' > 1 | `pubdep' <= 0 | `pubdep' >= 1 | `edudep' <= 0 | `edudep' >= 1 {
        di as err "pubshare() must lie in [0,1]; pubdep() and edudep() in (0,1)"
        exit 198
    }
    if "`gdpgrowth'" != "" confirm number `gdpgrowth'
    if `eduelas' != 0 & ("`educom'" == "" | "`edulabor'" == "") {
        di as err "eduelas() needs educom() and edulabor()"
        exit 198
    }
    mata: _cgemod_dyn()
    if `"`saving'"' != "" {
        gettoken fn sopt : saving, parse(",")
        gettoken comma sopt : sopt, parse(",")
        preserve
        qui {
            clear
            tempname B P D
            matrix `B' = __cgemod_dynbase
            matrix `P' = __cgemod_dynpol
            matrix `D' = __cgemod_dyndev
            svmat double `B', names(col)
            gen str8 scenario = "baseline"
            tempfile b p
            save `b'
            clear
            svmat double `P', names(col)
            gen str8 scenario = "policy"
            save `p'
            clear
            svmat double `D', names(col)
            gen str8 scenario = "pctdev"
            append using `b'
            append using `p'
            order scenario t
            sort scenario t
            label data "cgemod recursive-dynamic paths"
        }
        save `"`fn'"', `sopt'
        restore
    }
    return matrix baseline = __cgemod_dynbase
    return matrix policy = __cgemod_dynpol
    return matrix deviation = __cgemod_dyndev
end

* ---------------------------------------------------------------------------
program define _cgemod_ssa, rclass
    syntax [, ELASticities(string) RANGE(real 0.5) DISTribution(string) METHod(string) ///
        REPs(integer 200) SEED(string) BYSECtor TM(string) TQ(string) TA(string)        ///
        TE(string) TY(string) PWM(string) PWE(string) FS(string) WF(string) TFP(string) ///
        GADJ(string) FSAV(string) CTAX(string) MQUOTA(string) XQUOTA(string) PCAP(string) TMSCHED(string) GSAVShare(string) QG(string) SAVing(string asis) noTABle]
    _cgemod_needmodel
    if "`elasticities'" == "" local elasticities "sigmava sigmaq omega"
    if "`distribution'" == "" local distribution "uniform"
    if "`method'" == "" local method "quadrature"
    local distribution = lower("`distribution'")
    local method = lower("`method'")
    foreach e of local elasticities {
        if !inlist("`e'", "sigmava", "sigmaq", "omega", "sigmax", "frisch") {
            di as err "elasticities() may contain sigmava, sigmaq, omega, sigmax and frisch"
            exit 198
        }
    }
    if !inlist("`distribution'", "uniform", "normal", "triangular") {
        di as err "distribution() must be uniform, normal or triangular"
        exit 198
    }
    if !inlist("`method'", "quadrature", "montecarlo", "mc") {
        di as err "method() must be quadrature or montecarlo"
        exit 198
    }
    if "`method'" == "mc" local method "montecarlo"
    if `range' <= 0 | `range' >= 1 {
        di as err "range() must lie strictly between 0 and 1"
        exit 198
    }
    if `reps' < 10 & "`method'" == "montecarlo" {
        di as err "reps() must be at least 10"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    mata: _cgemod_ssa()
    if `"`saving'"' != "" {
        gettoken fn sopt : saving, parse(",")
        gettoken comma sopt : sopt, parse(",")
        preserve
        qui {
            clear
            svmat double __cgemod_ssadraws, names(col)
            gen long draw = _n
            order draw
            label data "cgemod systematic sensitivity analysis: one row per draw"
        }
        save `"`fn'"', `sopt'
        restore
    }
    return scalar ndraws = `ndraws'
    return scalar failed = `nfail'
    return local method "`method'"
    return local distribution "`distribution'"
    return matrix ssa = __cgemod_ssa
    return matrix draws = __cgemod_ssadraws
end

* ---------------------------------------------------------------------------
* Validation suite
program define _cgemod_validate, rclass
    syntax [, STEPs(integer 5) PERFormance SIZEs(numlist integer >0 <=2000) noTABle]
    _cgemod_needmodel
    if `steps' < 2 {
        di as err "steps() must be at least 2"
        exit 198
    }
    if "`sizes'" == "" local sizes "10 25 50"
    mata: _cgemod_validate(`steps')
    local np = `npass'
    local nf = `nfail'
    * units invariance: the whole SAM scaled by 1,000 must give identical percentage results
    local calopts `"$CGEMOD_calopts"'
    local samname = ustrregexra(`"`calopts'"', "(?is)^.*\bsam\(\s*([^)\s]+)\s*\).*$", "\$1")
    mata: _cgemod_vbackup(1)
    capture {
        quietly cgemod sim, pwm(*1.1) notable
        matrix __cgemod_v1 = r(macro)
        matrix __cgemod_v1h = r(household)
        matrix __cgemod_vsam = 1000*`samname'
        local cv = ustrregexra(`"`calopts'"', "(?i)\bsam\(\s*[^)\s]+\s*\)", "sam(__cgemod_vsam)")
        local cv = ustrregexra(`"`cv'"', "(?i)\bnotab[a-z]*\b", "")
        mata: _cgemod_vcopyroles("`samname'", "__cgemod_vsam")
        quietly cgemod calibrate `cv' notable
        quietly cgemod sim, pwm(*1.1) notable
        matrix __cgemod_v2 = r(macro)
        matrix __cgemod_v2h = r(household)
    }
    local rcu = _rc
    mata: _cgemod_vbackup(0)
    global CGEMOD_calopts `"`calopts'"'
    mata: _cgemod_vunits(`rcu')
    capture matrix drop __cgemod_v1 __cgemod_v2 __cgemod_v1h __cgemod_v2h __cgemod_vsam
    local np = `np' + `upass'
    local nf = `nf' + 1 - `upass'
    mata: _cgemod_vshow(`np', `nf', "`table'" == "")
    if "`performance'" != "" {
        tempname P
        local nsz : word count `sizes'
        matrix `P' = J(`nsz', 9, .)
        mata: _cgemod_vbackup(1)
        local i 0
        foreach n of local sizes {
            local ++i
            capture noisily {
                quietly cgemod samgen, sectors(`n') households(3) name(__cgemod_psam) nolist
                timer clear 98
                timer on 98
                quietly cgemod calibrate, sam(__cgemod_psam) solver(newton) notable
                timer off 98
                quietly timer list 98
                matrix `P'[`i', 1] = `n'
                matrix `P'[`i', 3] = r(t98)
                mata: st_local("nk", strofreal(asarray(*findexternal("_cgemod_M"), "pos")[8]))
                matrix `P'[`i', 2] = `nk'
                timer clear 98
                timer on 98
                quietly cgemod sim, tm(*0) notable
                timer off 98
                quietly timer list 98
                matrix `P'[`i', 4] = r(t98)
                matrix `P'[`i', 5] = r(iterations)
                matrix `P'[`i', 6] = r(jacobians)
                matrix __cgemod_pa = r(macro)
                mata: asarray(*findexternal("_cgemod_M"), "solver", 2)
                timer clear 98
                timer on 98
                quietly cgemod sim, tm(*0) notable
                timer off 98
                quietly timer list 98
                matrix `P'[`i', 7] = r(t98)
                matrix `P'[`i', 8] = r(iterations)
                matrix __cgemod_pb = r(macro)
                mata: st_local("gap", strofreal(max(abs(st_matrix("__cgemod_pa")[., 2] - st_matrix("__cgemod_pb")[., 2]))))
                matrix `P'[`i', 9] = `gap'
            }
            if _rc di as err "performance test with `n' sectors failed"
        }
        capture matrix drop __cgemod_psam __cgemod_pa __cgemod_pb
        mata: _cgemod_vbackup(0)
        global CGEMOD_calopts `"`calopts'"'
        matrix colnames `P' = sectors unknowns t_calib t_newton it_newton jac_newton t_broyden it_broyden gap
        if "`table'" == "" {
            di _n as txt "Performance on synthetic SAMs (tariff removal; times in seconds)"
            di as txt "{hline 9}{c TT}{hline 70}"
            di as txt "  sectors{c |}  unknowns  calibrate     Newton  it  Jacob.    Broyden  it    max gap"
            di as txt "{hline 9}{c +}{hline 70}"
            forvalues r = 1/`nsz' {
                di as res %9.0f `P'[`r', 1] as txt "{c |}" as res %10.0f `P'[`r', 2] %11.3f `P'[`r', 3] ///
                    %11.3f `P'[`r', 4] %4.0f `P'[`r', 5] %8.0f `P'[`r', 6] %11.3f `P'[`r', 7] %4.0f `P'[`r', 8] %11.2e `P'[`r', 9]
            }
            di as txt "{hline 9}{c BT}{hline 70}"
        }
        return matrix performance = `P'
    }
    return scalar passed = `np'
    return scalar failed = `nf'
    return matrix results = __cgemod_valid, copy
end

* ---------------------------------------------------------------------------
program define _cgemod_check, rclass
    syntax [, noTABle]
    _cgemod_needmodel
    mata: _cgemod_check()
    return scalar passed = `npass'
    return scalar failed = `nfail'
    return scalar cond = `jcond'
    return scalar walras = `walras'
    return scalar homog = `homog'
end

* ---------------------------------------------------------------------------
* Elasticity estimation with residual diagnostics and remedies
program define _cgemod_elast, rclass
    syntax varlist(min=2 numeric ts) [if] [in] [, TYPE(string) DYNamic TRend     ///
        IV(varlist numeric ts) REMedy(string) LAGs(integer -1) REPs(integer 499)   ///
        Level(cilevel) SECTor(string) STORE(name) TRIM(real 0.15) RE noSUPF]
    local dosupf = ("`supf'" == "")
    marksample touse
    if "`iv'" != "" markout `touse' `iv'
    gettoken depo rhso : varlist
    gettoken xo ctrlo : rhso
    if "`type'" == "" local type "generic"
    local type = lower("`type'")
    if !inlist("`type'", "armington", "cet", "va", "generic") {
        di as err "type() must be armington, cet, va or generic"
        exit 198
    }
    if "`remedy'" == "" local remedy "auto"
    local remedy = lower("`remedy'")
    if !inlist("`remedy'", "auto", "none", "robust", "newey", "prais", "bootstrap", "break") ///
        & !inlist("`remedy'", "cluster", "dk", "cce") {
        di as err "remedy() must be auto, none, robust, newey, prais, bootstrap, break, cluster, dk or cce"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie between 0 and 0.5"
        exit 198
    }

    * ---- data structure
    local struct "cs"
    local pvar ""
    local tvar ""
    capture qui xtset
    if !_rc & "`r(panelvar)'" != "" {
        local struct "panel"
        local pvar "`r(panelvar)'"
        local tvar "`r(timevar)'"
        if "`tvar'" == "" {
            di as err "panel data must be {bf:xtset} with a time variable"
            exit 459
        }
    }
    else {
        capture qui tsset
        if !_rc & "`r(timevar)'" != "" {
            local struct "ts"
            local tvar "`r(timevar)'"
        }
    }
    if "`struct'" == "cs" & ("`dynamic'" != "" | "`trend'" != "") {
        di as err "dynamic and trend require {bf:tsset} or {bf:xtset} data"
        exit 459
    }
    if "`struct'" != "panel" & inlist("`remedy'", "cluster", "dk", "cce") {
        di as err "remedy(`remedy') requires panel ({bf:xtset}) data"
        exit 198
    }
    if "`struct'" == "panel" & inlist("`remedy'", "newey", "prais", "break") {
        di as err "remedy(`remedy') is for time-series data; use cluster, dk or cce with panels"
        exit 198
    }
    if "`struct'" == "cs" & inlist("`remedy'", "newey", "prais", "break") {
        di as err "remedy(`remedy') requires {bf:tsset} data"
        exit 198
    }

    * ---- variables (ts operators resolved)
    tsrevar `depo'
    local d "`r(varlist)'"
    tsrevar `xo'
    local xv "`r(varlist)'"
    local cv ""
    if "`ctrlo'" != "" {
        tsrevar `ctrlo'
        local cv "`r(varlist)'"
    }
    local zv ""
    if "`iv'" != "" {
        tsrevar `iv'
        local zv "`r(varlist)'"
    }
    local extra ""
    tempvar ldep trendv
    if "`dynamic'" != "" {
        qui gen double `ldep' = L.`d' if `touse'
        markout `touse' `ldep'
        local extra "`extra' `ldep'"
    }
    if "`trend'" != "" {
        qui summarize `tvar' if `touse', meanonly
        qui gen double `trendv' = `tvar' - r(min) if `touse'
        local extra "`extra' `trendv'"
    }
    local rx "`xv' `cv' `extra'"
    local ex "`cv' `extra'"
    local fe = cond("`re'" != "", "re", "fe")

    * ---- base estimation
    tempvar e esamp xb yh2 yh3
    if "`struct'" == "panel" {
        if "`iv'" == "" qui xtreg `d' `rx' if `touse', `fe'
        else qui xtivreg `d' `ex' (`xv' = `zv') if `touse', fe
        qui gen byte `esamp' = e(sample)
        qui predict double `e' if `esamp', e
        qui predict double `xb' if `esamp', xb
    }
    else {
        if "`iv'" == "" qui regress `d' `rx' if `touse'
        else qui ivregress 2sls `d' `ex' (`xv' = `zv') if `touse'
        qui gen byte `esamp' = e(sample)
        qui predict double `e' if `esamp', residuals
        qui predict double `xb' if `esamp', xb
    }
    local N = e(N)
    local b0 = _b[`xv']
    local se0 = _se[`xv']
    if "`iv'" != "" & "`struct'" != "panel" {
        qui estat endogenous
        local endo = r(r_score)
        local endop = r(p_r_score)
        if "`endo'" == "" | "`endo'" == "." {
            local endo = r(durbin)
            local endop = r(p_durbin)
        }
        qui estat firststage
        tempname fs
        matrix `fs' = r(singleresults)
        local fc = colnumb(`fs', "F")
        if `fc' >= . local fc = 4
        local fsF = `fs'[1, `fc']
        local overid = .
        local overidp = .
        local nz : word count `zv'
        if `nz' > 1 {
            qui estat overid
            local overid = r(sargan)
            local overidp = r(p_sargan)
            if "`overid'" == "" | "`overid'" == "." {
                local overid = r(score)
                local overidp = r(p_score)
            }
        }
    }

    * ---- diagnostics: normality
    mata: _cgemod_jb("`e'", "`esamp'")
    local swp = .
    if `N' >= 4 & `N' <= 2000 {
        qui swilk `e' if `esamp'
        local swp = r(p)
        local sww = r(W)
    }

    * ---- RESET
    local resetF = .
    local resetp = .
    if "`iv'" == "" {
        qui summarize `xb' if `esamp'
        qui gen double `yh2' = ((`xb' - r(mean))/r(sd))^2 if `esamp'
        qui gen double `yh3' = ((`xb' - r(mean))/r(sd))^3 if `esamp'
        if "`struct'" == "panel" qui xtreg `d' `rx' `yh2' `yh3' if `esamp', `fe'
        else qui regress `d' `rx' `yh2' `yh3' if `esamp'
        qui test `yh2' `yh3'
        local resetF = cond("`struct'" == "panel" & "`fe'" == "re", r(chi2), r(F))
        local resetp = r(p)
    }

    * ---- multicollinearity
    local vifmax = .
    local vifs ""
    mata: _cgemod_vif("`rx'", "`esamp'", "`pvar'")

    if "`struct'" != "panel" {
        * ---- heteroskedasticity: Koenker-Breusch-Pagan and White-type (levels + squares)
        tempvar e2
        qui gen double `e2' = `e'^2 if `esamp'
        qui regress `e2' `rx' if `esamp'
        local bp = e(N)*e(r2)
        local bpdf = e(df_m)
        local bpp = chi2tail(`bpdf', `bp')
        local sqlist ""
        foreach v of local rx {
            tempvar s
            qui gen double `s' = `v'^2 if `esamp'
            local sqlist "`sqlist' `s'"
        }
        qui regress `e2' `rx' `sqlist' if `esamp'
        local wh = e(N)*e(r2)
        local whdf = e(df_m)
        local whp = chi2tail(`whdf', `wh')
    }

    if "`struct'" == "ts" {
        * ---- serial correlation: Breusch-Godfrey (auxiliary regression) and Durbin-Watson
        local p = `lags'
        if `p' < 1 local p = cond(`N' >= 30, 2, 1)
        local nwlag = `lags'
        if `nwlag' < 1 local nwlag = max(1, floor(4*(`N'/100)^(2/9)))
        local llist ""
        forvalues j = 1/`p' {
            tempvar l`j'
            qui gen double `l`j'' = L`j'.`e' if `esamp'
            qui replace `l`j'' = 0 if `esamp' & missing(`l`j'')
            local llist "`llist' `l`j''"
        }
        qui regress `e' `rx' `llist' if `esamp'
        local bg = e(N)*e(r2)
        local bgp = chi2tail(`p', `bg')
        mata: _cgemod_dw("`e'", "`esamp'")
        * ---- stability: CUSUM of recursive residuals and sup-F with bootstrap p-value
        local cusum = .
        local supfstat = .
        local supfp = .
        local breakt ""
        if "`iv'" == "" {
            mata: _cgemod_cusum("`d'", "`rx'", "`esamp'")
            if `dosupf' & `N' >= 20 {
                mata: _cgemod_supf("`d'", "`rx'", "`xv'", "`esamp'", "`tvar'", `trim', `reps')
            }
        }
        * ---- residual stationarity (information only)
        capture qui dfuller `e' if `esamp', lags(1) noconstant
        local adf = cond(_rc, ., r(Zt))
    }

    if "`struct'" == "panel" {
        mata: _cgemod_cd("`e'", "`esamp'", "`pvar'", "`tvar'")
        mata: _cgemod_mwald("`e'", "`esamp'", "`pvar'")
        tempvar u
        capture {
            qui regress D.`d' D.(`rx') if `esamp', noconstant vce(cluster `pvar')
            qui predict double `u' if e(sample), residuals
            qui regress `u' L.`u' if `esamp', noconstant vce(cluster `pvar')
            qui test L.`u' = -0.5
        }
        if _rc {
            local wser = .
            local wserp = .
        }
        else {
            local wser = r(F)
            local wserp = r(p)
        }
        local nwlag = `lags'
        if `nwlag' < 1 {
            qui levelsof `tvar' if `esamp', local(tl)
            local Tn : word count `tl'
            local nwlag = max(1, floor(4*(`Tn'/100)^(2/9)))
        }
    }

    * ---- flags (5% level)
    local f_norm = (`jbp' < 0.05)
    local f_reset = (`resetp' < 0.05)
    local f_vif = (`vifmax' < . & `vifmax' > 10)
    local f_het = 0
    local f_ser = 0
    local f_stab = 0
    local f_cd = 0
    if "`struct'" != "panel" local f_het = (`bpp' < 0.05 | `whp' < 0.05)
    if "`struct'" == "ts" {
        local f_ser = (`bgp' < 0.05)
        local f_stab = (`cusum' < . & `cusum' > 0.948) | (`supfp' < 0.05)
    }
    if "`struct'" == "panel" {
        local f_het = (`mwp' < 0.05)
        local f_ser = (`wserp' < 0.05)
        local f_cd = (`cdp' < 0.05)
    }

    * ---- choose remedy
    local addbreak = 0
    local rem "`remedy'"
    if "`remedy'" == "auto" {
        if "`struct'" == "panel" {
            if `f_cd' local rem "dk"
            else if `f_het' | `f_ser' local rem "cluster"
            else local rem "none"
        }
        else {
            if `f_ser' & "`struct'" == "ts" local rem "newey"
            else if `f_het' local rem "robust"
            else if `f_norm' & `N' < 50 local rem "bootstrap"
            else local rem "none"
            if `f_stab' & "`breakt'" != "" & "`iv'" == "" local addbreak = 1
        }
    }
    if "`remedy'" == "break" {
        if "`breakt'" == "" {
            di as err "no break date could be estimated (sample too short, IV model, or nosupf)"
            exit 498
        }
        local addbreak = 1
        local rem = cond(`f_ser', "newey", "robust")
    }
    if "`rem'" == "prais" & "`dynamic'" != "" {
        di as txt "note: Prais-Winsten is not valid with a lagged dependent variable; using Newey-West instead"
        local rem "newey"
    }
    if "`iv'" != "" & inlist("`rem'", "dk", "cce") {
        di as txt "note: remedy(`rem') is not available with iv(); using cluster-robust errors instead"
        local rem "cluster"
    }
    if "`iv'" != "" & "`rem'" == "prais" {
        di as txt "note: remedy(prais) is not available with iv(); using HAC errors instead"
        local rem "newey"
    }

    * ---- final estimation
    local rhsf "`rx'"
    tempvar Dbr Dx
    if `addbreak' {
        qui gen byte `Dbr' = (`tvar' >= `breakt') if `touse'
        qui gen double `Dx' = `Dbr'*`xv' if `touse'
        local rhsf "`rhsf' `Dbr' `Dx'"
    }
    di _n as txt "{hline 78}"
    di as txt "cgemod elast: final model (remedy: " as res "`rem'" ///
        as txt cond(`addbreak', " + structural break at `tvar' = `breakt'", "") as txt ")"
    di as txt "{hline 78}"
    if "`struct'" == "panel" {
        if "`rem'" == "dk" {
            tempname bb VV
            mata: _cgemod_dk("`d'", "`rx'", "`esamp'", "`pvar'", "`tvar'", `nwlag', "`bb'", "`VV'")
            tempvar es2
            qui gen byte `es2' = `esamp'
            _cgemod_epost, b(`bb') v(`VV') dep(`depo') n(`N') touse(`es2') lag(`nwlag')
            ereturn display, level(`level')
            di as txt "Driscoll-Kraay standard errors (fixed effects, Bartlett kernel, lag `nwlag')"
        }
        else if "`rem'" == "cce" {
            local csa ""
            foreach v in `d' `xv' `cv' {
                tempvar m
                qui bysort `tvar': egen double `m' = mean(`v') if `esamp'
                local csa "`csa' c.`m'#i.`pvar'"
            }
            qui sort `pvar' `tvar'
            areg `d' `rx' `csa' if `esamp', absorb(`pvar') vce(cluster `pvar') level(`level')
            di as txt "CCE pooled estimator (Pesaran 2006): cross-section averages interacted with panel units"
        }
        else {
            local vce ""
            if "`rem'" == "cluster" | "`rem'" == "robust" local vce "vce(cluster `pvar')"
            if "`rem'" == "bootstrap" local vce "vce(bootstrap, reps(`reps') nodots)"
            if "`iv'" == "" xtreg `d' `rx' if `esamp', `fe' `vce' level(`level')
            else {
                capture noisily xtivreg `d' `ex' (`xv' = `zv') if `esamp', fe `vce' level(`level')
                if _rc {
                    di as txt "note: this vce() is not available for xtivreg here; using bootstrap"
                    xtivreg `d' `ex' (`xv' = `zv') if `esamp', fe vce(bootstrap, reps(`reps') nodots) level(`level')
                }
            }
        }
    }
    else {
        if "`iv'" == "" {
            if "`rem'" == "none" regress `d' `rhsf' if `esamp', level(`level')
            else if "`rem'" == "robust" regress `d' `rhsf' if `esamp', vce(robust) level(`level')
            else if "`rem'" == "newey" newey `d' `rhsf' if `esamp', lag(`nwlag') force level(`level')
            else if "`rem'" == "prais" prais `d' `rhsf' if `esamp', vce(robust) level(`level')
            else if "`rem'" == "bootstrap" regress `d' `rhsf' if `esamp', vce(bootstrap, reps(`reps') nodots) level(`level')
        }
        else {
            local vce ""
            if "`rem'" == "robust" local vce "vce(robust)"
            if "`rem'" == "newey" local vce "vce(hac nwest `nwlag')"
            if "`rem'" == "bootstrap" local vce "vce(bootstrap, reps(`reps') nodots)"
            ivregress 2sls `d' `ex' (`xv' = `zv') if `esamp', `vce' level(`level')
        }
    }

    * ---- elasticity
    local el = _b[`xv']
    local ese = _se[`xv']
    local lr = .
    local lrse = .
    if "`dynamic'" != "" {
        qui nlcom (_b[`xv']/(1 - _b[`ldep']))
        tempname nb nV
        matrix `nb' = r(b)
        matrix `nV' = r(V)
        local lr = `nb'[1,1]
        local lrse = sqrt(`nV'[1,1])
    }
    local post = .
    local postse = .
    if `addbreak' {
        qui lincom _b[`xv'] + _b[`Dx']
        local post = r(estimate)
        local postse = r(se)
    }

    * ---- report
    di _n as txt "{hline 78}"
    foreach m in jb jbp sww swp bp bpp wh whp bg bgp dw cusum supfstat supfp adf cd cdp mw mwp wser wserp ///
        resetF resetp vifmax endo endop fsF overid overidp b0 se0 el ese lr lrse post postse {
        if `"``m''"' == "" local `m' = .
    }
    foreach m in f_reset f_vif f_cd {
        if `"``m''"' == "" local `m' = 0
    }
    di as txt "Residual diagnostics (base model, " cond("`iv'" != "", "2SLS", cond("`struct'" == "panel", "FE", "OLS")) ///
        ", N = `N')"
    di as txt "{hline 40}{c TT}{hline 37}"
    di as txt %-40s "Test" "{c |}" %11s "Statistic" %10s "p-value" "  Verdict"
    di as txt "{hline 40}{c +}{hline 37}"
    _cgemod_drow "Normality: Jarque-Bera" `jb' `jbp'
    if `swp' < . _cgemod_drow "Normality: Shapiro-Wilk W" `sww' `swp'
    if "`struct'" != "panel" {
        _cgemod_drow "Heteroskedasticity: Koenker-BP" `bp' `bpp'
        _cgemod_drow "Heteroskedasticity: White (sq.)" `wh' `whp'
    }
    if "`struct'" == "ts" {
        _cgemod_drow "Serial correlation: BG(`p')" `bg' `bgp'
        _cgemod_drow "Durbin-Watson d" `dw' .
        if `cusum' < . _cgemod_drow "Stability: CUSUM (5% cv 0.948)" `cusum' . `=cond(`cusum' > 0.948, "problem", "ok")'
        if `supfstat' < . _cgemod_drow "Stability: sup-F (bootstrap p)" `supfstat' `supfp'
        if `adf' < . _cgemod_drow "Residual ADF t (see note)" `adf' .
    }
    if "`struct'" == "panel" {
        _cgemod_drow "Cross-sec. dependence: Pesaran CD" `cd' `cdp'
        _cgemod_drow "Groupwise heterosk.: mod. Wald" `mw' `mwp'
        _cgemod_drow "Serial correlation: Wooldridge" `wser' `wserp'
    }
    if `resetp' < . _cgemod_drow "Misspecification: RESET" `resetF' `resetp'
    if `vifmax' < . _cgemod_drow "Multicollinearity: max VIF (>10)" `vifmax' . `=cond(`vifmax' > 10, "problem", "ok")'
    if "`iv'" != "" & "`struct'" != "panel" {
        _cgemod_drow "Endogeneity of `xo' (score)" `endo' `endop'
        _cgemod_drow "First-stage F (weak if < 10)" `fsF' . `=cond(`fsF' < 10, "problem", "ok")'
        if `overid' < . _cgemod_drow "Overidentification (Sargan)" `overid' `overidp'
    }
    di as txt "{hline 40}{c BT}{hline 37}"
    if "`struct'" == "ts" & `adf' < . {
        di as txt "note: compare the residual ADF t with Engle-Granger (not Dickey-Fuller) critical values;"
        di as txt "      a unit root in the residuals signals a spurious levels regression."
    }
    if `f_reset' di as txt "note: RESET rejects; consider {bf:dynamic}, {bf:trend} or nonlinear terms."
    if `f_vif' di as txt "note: high VIF; consider dropping or combining collinear controls."
    if "`struct'" == "panel" & `f_cd' & "`rem'" != "cce" ///
        di as txt "note: cross-sectional dependence; {bf:remedy(cce)} is an alternative to Driscoll-Kraay."

    local lab = cond("`type'" == "armington", "Armington (import-domestic) elasticity",    ///
        cond("`type'" == "cet", "CET (export-domestic) elasticity",                    ///
        cond("`type'" == "va", "Factor substitution elasticity", "Elasticity")))
    di _n as txt "{hline 78}"
    di as txt "`lab'" cond("`sector'" != "", " for `sector'", "") as txt "  [remedy: " as res "`rem'" as txt "]"
    di as txt "{hline 78}"
    di as txt %-40s "Base estimate (no remedy)" as res %10.4f `b0' as txt "  (se " as res %7.4f `se0' as txt ")"
    di as txt %-40s "Final short-run estimate" as res %10.4f `el' as txt "  (se " as res %7.4f `ese' as txt ")"
    if `lr' < . di as txt %-40s "Final long-run estimate b/(1-rho)" as res %10.4f `lr' as txt "  (se " as res %7.4f `lrse' as txt ")"
    if `post' < . di as txt %-40s "Post-break estimate" as res %10.4f `post' as txt "  (se " as res %7.4f `postse' as txt ")"
    local use = cond(`post' < ., `post', cond(`lr' < ., `lr', `el'))
    if "`type'" != "generic" & `use' <= 0 {
        di as err "warning: the estimated elasticity is not positive; check the ratio and price variables"
    }
    if "`store'" != "" {
        local sname = strtoname("`sector'")
        if "`sector'" == "" local sname ""
        mata: _cgemod_store("`store'", "`sname'", `use')
        di as txt "stored " as res %8.4f `use' as txt " in matrix {bf:`store'}" cond("`sector'" != "", " (column `sname')", "")
    }

    return scalar elast = `el'
    return scalar se = `ese'
    return scalar elast_base = `b0'
    return scalar se_base = `se0'
    return scalar elast_lr = `lr'
    return scalar se_lr = `lrse'
    return scalar elast_post = `post'
    return scalar se_post = `postse'
    return scalar elast_used = `use'
    return scalar N = `N'
    return scalar jb = `jb'
    return scalar jb_p = `jbp'
    return scalar reset_p = `resetp'
    return scalar vif_max = `vifmax'
    if "`struct'" != "panel" {
        return scalar bp_p = `bpp'
        return scalar white_p = `whp'
    }
    if "`struct'" == "ts" {
        return scalar bg_p = `bgp'
        return scalar dw = `dw'
        return scalar cusum = `cusum'
        return scalar supf = `supfstat'
        return scalar supf_p = `supfp'
        if "`breakt'" != "" return scalar breakdate = `breakt'
    }
    if "`struct'" == "panel" {
        return scalar cd = `cd'
        return scalar cd_p = `cdp'
        return scalar mwald_p = `mwp'
        return scalar wooldridge_p = `wserp'
    }
    return local remedy "`rem'"
    return local structure "`struct'"
    return local type "`type'"
end

program define _cgemod_drow
    args lab stat p note
    if "`p'" == "" local p = .
    if "`stat'" == "" local stat = .
    local v "`note'"
    if "`v'" == "" {
        if `p' < . local v = cond(`p' < 0.05, "problem", "ok")
        else local v "-"
    }
    di as txt %-40s "`lab'" "{c |}" as res %11.4f `stat' %10.4f `p' as txt "  `v'"
end

program define _cgemod_epost, eclass
    syntax , b(name) v(name) dep(string) n(integer) touse(varname) lag(integer)
    ereturn post `b' `v', depname(`dep') obs(`n') esample(`touse')
    ereturn local cmd "cgemod_dk"
    ereturn local vcetype "Drisc/Kraay"
    ereturn scalar lag = `lag'
end

* ---------------------------------------------------------------------------
* SAM workflow: identity checks, balancing, monitoring, audit log, export
program define _cgemod_samchk, rclass
    syntax , SAM(name) [ACTivities(string) COMmodities(string) FACtors(string)  ///
        HOUseholds(string) GOVernment(string) ROW(string) SAVinv(string)        ///
        TAXes(string) ENTerprises(string) MARgins(string) STOCKs(string)        ///
        TOP(integer 5) LOG(string) noTABle]
    confirm matrix `sam'
    mata: _cgemod_samaudit()
    local stamp "`c(current_date)' `c(current_time)'"
    if `"`log'"' != "" {
        _cgemod_samlog `"`log'"' "samcheck" "`sam'" "" ///
            "accounts=`naccounts' total=`samtotal' maxgap=`maxgap' nneg=`nneg' gdp_income=`gdpi' gdp_exp=`gdpe'"
    }
    return scalar accounts = `naccounts'
    return scalar total = `samtotal'
    return scalar maxgap = `maxgap'
    return scalar negative = `nneg'
    return scalar empty = `nempty'
    return scalar gdp_income = `gdpi'
    return scalar gdp_exp = `gdpe'
    return local worst "`worst'"
    return local stamp "`stamp'"
end

program define _cgemod_sambal, rclass
    syntax , SAM(name) [METHod(string) NAME(name) FIX(name) FIXACCounts(string)    ///
        FIXTOTals(string) WEIGHTs(name) TOTals(string) TOLerance(real 1e-10)       ///
        MAXiter(integer 200) TOP(integer 10) COMPare(string asis) LOG(string) noTABle]
    confirm matrix `sam'
    if "`method'" == "" local method "gras"
    local method = lower("`method'")
    if "`method'" == "ce" local method "gras"
    if !inlist("`method'", "gras", "ras") {
        di as err "method() must be gras (sign-preserving cross-entropy; alias ce) or ras"
        exit 198
    }
    if "`name'" == "" local name = substr("`sam'_bal", 1, 32)
    if "`fix'" != "" confirm matrix `fix'
    if "`weights'" != "" confirm matrix `weights'
    mata: _cgemod_sambal()
    local stamp "`c(current_date)' `c(current_time)'"
    if `"`compare'"' != "" {
        gettoken fn sopt : compare, parse(",")
        gettoken comma sopt : sopt, parse(",")
        preserve
        qui {
            clear
            mata: _cgemod_cmpdata("__cgemod_prior", "`name'", "__cgemod_fixmask")
            label data "cgemod sambalance: cell-by-cell comparison, `stamp'"
        }
        save `"`fn'"', `sopt'
        restore
    }
    if `"`log'"' != "" {
        _cgemod_samlog `"`log'"' "sambalance" "`sam'" "`method'" ///
            "accounts=`naccounts' imb_before=`imb0' imb_after=`imb1' kl=`kl' mape=`mape' maxpct=`maxpct' cells_gt5pct=`n5' signflips=`flips' fixed=`nfixed' targets=`ntgt' iterations=`it' converged=`conv'"
    }
    capture matrix drop __cgemod_prior
    capture matrix drop __cgemod_fixmask
    return scalar imb_before = `imb0'
    return scalar imb_after = `imb1'
    return scalar kl = `kl'
    return scalar mape = `mape'
    return scalar maxpct = `maxpct'
    return scalar cells_gt5pct = `n5'
    return scalar signflips = `flips'
    return scalar entropy = `ceobj'
    return scalar fixed = `nfixed'
    return scalar targets = `ntgt'
    return scalar iterations = `it'
    return scalar converged = `conv'
    return local method "`method'"
    return local name "`name'"
    return local stamp "`stamp'"
end

program define _cgemod_sammon, rclass
    syntax , SAM(name) BENCHmark(name) [THReshold(real 25) TOP(integer 10) LOG(string) noTABle]
    confirm matrix `sam'
    confirm matrix `benchmark'
    if `threshold' <= 0 {
        di as err "threshold() must be positive"
        exit 198
    }
    mata: _cgemod_sammon()
    local stamp "`c(current_date)' `c(current_time)'"
    if `"`log'"' != "" {
        _cgemod_samlog `"`log'"' "sammonitor" "`sam'" "`benchmark'" ///
            "alerts=`alerts' kl=`kl' mape=`mape' cells_over=`nover' new_cells=`nnew' vanished=`nvan' signflips=`nflip' totals_over=`ntot' missing_accounts=`nmiss' imbalance=`imb'"
    }
    return scalar alerts = `alerts'
    return scalar kl = `kl'
    return scalar mape = `mape'
    return scalar cells_over = `nover'
    return scalar new_cells = `nnew'
    return scalar vanished = `nvan'
    return scalar signflips = `nflip'
    return scalar totals_over = `ntot'
    return scalar missing_accounts = `nmiss'
    return scalar imbalance = `imb'
    return local status = cond(`alerts' > 0, "ALERT", "OK")
    return local stamp "`stamp'"
end

program define _cgemod_samexport, rclass
    syntax , SAM(name) [EXCel(string) CSV(string) GAMS(string) PRIor(name) REPLACE]
    confirm matrix `sam'
    if "`prior'" != "" confirm matrix `prior'
    if `"`excel'`csv'`gams'"' == "" {
        di as err "specify at least one of excel(), csv() or gams()"
        exit 198
    }
    local stamp "`c(current_date)' `c(current_time)'"
    if `"`excel'"' != "" {
        preserve
        qui {
            clear
            mata: _cgemod_mat2data("`sam'")
            export excel using `"`excel'"', sheet("SAM") firstrow(variables) `replace'
            if "`prior'" != "" {
                clear
                mata: _cgemod_mat2data("`prior'")
                export excel using `"`excel'"', sheet("prior") firstrow(variables) sheetreplace
                clear
                mata: _cgemod_matdiff("`sam'", "`prior'", "__cgemod_chg")
                mata: _cgemod_mat2data("__cgemod_chg")
                matrix drop __cgemod_chg
                export excel using `"`excel'"', sheet("change") firstrow(variables) sheetreplace
            }
            clear
            mata: _cgemod_infodata("`sam'", "`prior'", "`stamp'")
            export excel using `"`excel'"', sheet("info") firstrow(variables) sheetreplace
        }
        restore
        di as txt "SAM written to Excel file " as res `"`excel'"'
    }
    if `"`csv'"' != "" {
        preserve
        qui {
            clear
            mata: _cgemod_mat2data("`sam'")
            export delimited using `"`csv'"', `replace'
        }
        restore
        di as txt "SAM written to CSV file " as res `"`csv'"'
    }
    if `"`gams'"' != "" {
        mata: _cgemod_gams("`sam'", `"`gams'"', "`replace'" != "", "`stamp'")
        di as txt "SAM written to GAMS include file " as res `"`gams'"'
    }
    return local stamp "`stamp'"
end

program define _cgemod_samlog
    args logfile cmd sam method stats
    if !strmatch(lower(`"`logfile'"'), "*.dta") local logfile `"`logfile'.dta"'
    preserve
    qui {
        clear
        set obs 1
        gen str11 date = "`c(current_date)'"
        gen str8 time = "`c(current_time)'"
        gen str32 user = "`c(username)'"
        gen str12 command = "`cmd'"
        gen str32 sam = "`sam'"
        gen str32 detail = "`method'"
        foreach kv of local stats {
            gettoken k v : kv, parse("=")
            gettoken eq v : v, parse("=")
            if "`v'" == "" local v = .
            gen double `k' = `v'
        }
        tempfile row
        save `row'
        capture confirm file `"`logfile'"'
        if !_rc {
            use `"`logfile'"', clear
            append using `row'
        }
        label data "cgemod SAM audit log"
        save `"`logfile'"', replace
    }
    restore
    di as txt "audit record appended to " as res `"`logfile'"'
end

* ---------------------------------------------------------------------------
* SAM import with role detection, and comparison with external results
program define _cgemod_samgen, rclass
    syntax , SECtors(integer) [HOUseholds(integer 2) SEED(integer 1) NAME(name) noLIST]
    if `sectors' < 1 | `sectors' > 2000 {
        di as err "sectors() must be between 1 and 2000"
        exit 198
    }
    if `households' < 1 | `households' > 100 {
        di as err "households() must be between 1 and 100"
        exit 198
    }
    if `seed' < 0 {
        di as err "seed() must be non-negative"
        exit 198
    }
    if "`name'" == "" local name "GENSAM"
    mata: _cgemod_samgen(`sectors', `households', `seed', "`name'")
    if "`list'" == "" {
        mata: _cgemod_samroles("`name'")
    }
    else {
        quietly mata: _cgemod_samroles("`name'")
    }
    return scalar accounts = `naccounts'
    return scalar total = `samtotal'
    return local name "`name'"
end

* ---------------------------------------------------------------------------
program define _cgemod_samimport, rclass
    syntax using/ [, SHEET(string) CELLRange(string) NAME(name) MERGE(string) MAP(string) LABELCol(integer 1) noROLES noLIST]
    if "`name'" == "" local name "CGESAM"
    local ext = lower(substr(`"`using'"', -4, .))
    if inlist("`ext'", ".inc", ".gms") {
        confirm file `"`using'"'
        mata: _cgemod_gamsread("`name'", `"`using'"')
    }
    else {
        preserve
        qui {
            clear
            if inlist("`ext'", ".csv", ".txt") {
                import delimited using `"`using'"', varnames(nonames) stringcols(_all) clear
            }
            else if "`ext'" == ".tab" {
                import delimited using `"`using'"', varnames(nonames) stringcols(_all) delimiters(tab) clear
            }
            else {
                local opts "allstring clear"
                if `"`sheet'"' != "" local opts `"`opts' sheet(`"`sheet'"')"'
                if "`cellrange'" != "" local opts "`opts' cellrange(`cellrange')"
                import excel using `"`using'"', `opts'
            }
        }
        mata: _cgemod_samread("`name'", `labelcol')
        restore
    }
    if `"`merge'"' != "" mata: _cgemod_sammerge("`name'", `"`merge'"')
    if `"`map'"' != "" {
        confirm file `"`map'"'
        local mext = lower(substr(`"`map'"', -4, .))
        preserve
        qui {
            clear
            if inlist("`mext'", ".csv", ".txt") {
                import delimited using `"`map'"', varnames(nonames) stringcols(_all) clear
            }
            else if "`mext'" == ".tab" {
                import delimited using `"`map'"', varnames(nonames) stringcols(_all) delimiters(tab) clear
            }
            else {
                import excel using `"`map'"', allstring clear
            }
        }
        mata: _cgemod_sammap("`name'")
        restore
    }
    mata: _cgemod_samcheck("`name'", 0, 1e-9, 1, "`list'" == "")
    local gaps = `maxdiff'
    if "`roles'" == "" {
        mata: _cgemod_samroles("`name'")
        foreach r in activities commodities factors households enterprises government row savinv taxes tariff exptax margins stocks unassigned {
            return local `r' "``r''"
        }
    }
    return scalar accounts = `naccounts'
    return scalar maxdiff = `gaps'
    return local name "`name'"
end

program define _cgemod_compare, rclass
    syntax using/ [, VARiable(string) VALue(string) SHEET(string) TOLerance(real 0.001) TOP(integer 15) noTABle]
    mata: st_local("ok", strofreal(findexternal("_cgemod_last") != NULL))
    if "`ok'" != "1" {
        di as err "no simulation results in memory; run {bf:cgemod sim} first"
        exit 301
    }
    if "`variable'" == "" local variable "variable"
    if "`value'" == "" local value "value"
    local ext = lower(substr(`"`using'"', -4, .))
    preserve
    qui {
        clear
        if inlist("`ext'", ".csv", ".txt") import delimited using `"`using'"', varnames(1) clear
        else if "`ext'" == ".dta" use `"`using'"', clear
        else {
            local opts "firstrow clear"
            if `"`sheet'"' != "" local opts `"`opts' sheet(`"`sheet'"')"'
            import excel using `"`using'"', `opts'
        }
        confirm variable `variable' `value'
        capture confirm string variable `variable'
        if _rc {
            di as err "`variable' must be a string variable of result names"
            exit 109
        }
        capture confirm numeric variable `value'
        if _rc destring `value', replace force
    }
    mata: _cgemod_compare("`variable'", "`value'", `tolerance', `top', "`table'" == "")
    restore
    return scalar compared = `ncomp'
    return scalar unmatched = `nmiss'
    return scalar failed = `nfail'
    return scalar maxdiff = `maxd'
    return local worst "`worst'"
    return local status = cond(`nfail' == 0 & `ncomp' > 0, "REPLICATED", "DIFFERENCES")
end

* ---------------------------------------------------------------------------
* Poverty and distribution: top-down microsimulation on a household survey
program define _cgemod_poverty, rclass
    syntax [if] [in], GROUP(varname) WELFare(varname numeric) [WEIGHT(varname numeric) ///
        HHSize(varname numeric) LINE(string) METHod(string) SOURCES(string)                ///
        TRANSfers(varlist numeric) MAP(string) BY(varname) GENerate(name) DYNamic noTABle]
    local ext = cond("`dynamic'" != "", "_cgemod_dynpov", "_cgemod_pov")
    mata: st_local("ok", strofreal(findexternal("`ext'") != NULL))
    if "`ok'" != "1" {
        di as err "no results in memory; run {bf:cgemod `=cond("`dynamic'" != "", "dynamic", "sim")'} first"
        exit 301
    }
    if "`method'" == "" local method "ev"
    local method = lower("`method'")
    if !inlist("`method'", "ev", "real", "income") {
        di as err "method() must be ev, real or income"
        exit 198
    }
    if "`method'" == "income" & "`sources'" == "" {
        di as err "method(income) needs sources(), e.g. sources(inc_lab=LAB inc_cap=CAP)"
        exit 198
    }
    if "`line'" == "" {
        di as err "line() is required: a number or a variable holding the poverty line"
        exit 198
    }
    local linevar ""
    capture confirm number `line'
    if _rc {
        confirm numeric variable `line'
        local linevar "`line'"
    }
    if "`generate'" != "" confirm new variable `generate'
    tempvar touse
    mark `touse' `if' `in'
    markout `touse' `welfare' `weight' `hhsize' `linevar' `transfers'
    if "`by'" != "" markout `touse' `by', strok
    local srcvars ""
    local srcfac ""
    foreach tok of local sources {
        gettoken v f : tok, parse("=")
        gettoken eq f : f, parse("=")
        confirm numeric variable `v'
        local srcvars "`srcvars' `v'"
        local srcfac "`srcfac' `f'"
    }
    if "`srcvars'" != "" markout `touse' `srcvars'
    qui count if `touse'
    if r(N) == 0 error 2000
    tempvar bycode
    if "`by'" != "" qui egen long `bycode' = group(`by') if `touse', label
    if "`dynamic'" != "" mata: _cgemod_povdyn()
    else mata: _cgemod_poverty()
    return scalar N = `npov'
    return local method "`method'"
    if "`dynamic'" != "" {
        return matrix path = __cgemod_povpath
        exit
    }
    return matrix poverty = __cgemod_pov
    return matrix groups = __cgemod_povgrp
    if "`by'" != "" return matrix by = __cgemod_povby
end

* ===========================================================================
version 15
mata:
mata set matastrict off

/* ------------------------------------------------------------------ utils */
real scalar _cgemod_cesp(real colvector th, real colvector rel, real scalar sig)
{
    if (abs(sig - 1) < 1e-8) return(exp(sum(th :* ln(rel))))
    return(sum(th :* rel :^ (1 - sig)) ^ (1/(1 - sig)))
}

real scalar _cgemod_in(transmorphic x, transmorphic v)
{
    if (rows(x)*cols(x) == 0) return(0)
    return(anyof(x, v))
}

real scalar _cgemod_find(string scalar nm, string rowvector n1, string rowvector n2)
{
    real rowvector p
    p = selectindex(n1 :== nm)
    if (cols(p) == 1) return(p[1])
    if (cols(n2) == cols(n1)) {
        p = selectindex(n2 :== nm)
        if (cols(p) == 1) return(p[1])
    }
    return(0)
}

real rowvector _cgemod_ix(string rowvector L, string rowvector names, string scalar what)
{
    real rowvector ix, p
    real scalar i
    ix = J(1, cols(L), .)
    for (i = 1; i <= cols(L); i++) {
        p = selectindex(names :== L[i])
        if (cols(p) != 1) {
            errprintf("%s account %s not found (or duplicated) in the SAM\n", what, L[i])
            exit(111)
        }
        ix[i] = p[1]
    }
    return(ix)
}

real scalar _cgemod_sr(real matrix S, real rowvector idx, real scalar j)
{
    if (cols(idx) == 0) return(0)
    return(sum(S[idx, j]))
}

transmorphic _cgemod_copy(transmorphic A)
{
    transmorphic B
    string colvector k
    real scalar i
    B = asarray_create()
    k = asarray_keys(A)
    for (i = 1; i <= rows(k); i++) asarray(B, k[i], asarray(A, k[i]))
    return(B)
}

real scalar _cgemod_pch(real scalar a, real scalar b)
{
    if (abs(a) < 1e-12) return(.)
    return(100*(b/a - 1))
}

/* ------------------------------------------------------------------- SAM */
void _cgemod_samfromdata(string scalar vars, string scalar labvar, string scalar touse, string scalar name)
{
    real matrix S
    string colvector lab
    real scalar k, i
    S = st_data(., vars, touse)
    lab = st_sdata(., labvar, touse)
    k = rows(S)
    if (k != cols(S)) {
        errprintf("a SAM must be square: %g accounts (rows) but %g columns\n", k, cols(S))
        exit(503)
    }
    if (hasmissing(S)) {
        printf("{txt}note: missing cells set to zero\n")
        S = editmissing(S, 0)
    }
    for (i = 1; i <= k; i++) lab[i] = strtoname(strtrim(lab[i]))
    if (rows(uniqrows(lab)) != k) {
        errprintf("account labels must be unique\n")
        exit(198)
    }
    st_matrix(name, S)
    st_matrixrowstripe(name, (J(k, 1, ""), lab))
    st_matrixcolstripe(name, (J(k, 1, ""), lab))
}

real matrix _cgemod_ras(real matrix S0, real scalar tol, real scalar maxit, real matrix it, real matrix conv)
{
    real matrix S
    real colvector tg, r
    real rowvector cs
    S = S0
    tg = (rowsum(S) + colsum(S)') :/ 2
    conv = 0
    for (it = 1; it <= maxit; it++) {
        r = rowsum(S)
        S = S :* editmissing(tg :/ r, 1)
        cs = colsum(S)
        S = S :* editmissing(tg' :/ cs, 1)
        if (max(abs(rowsum(S) - colsum(S)')) < tol*sum(tg)) {
            conv = 1
            break
        }
    }
    if (it > maxit) it = maxit
    return(S)
}

void _cgemod_samcheck(string scalar name, real scalar bal, real scalar tol, real scalar maxit, real scalar list)
{
    real matrix S
    string colvector lab
    real colvector r, cs_, d
    real scalar k, i, j, tot, maxd, nneg, it, conv
    S = st_matrix(name)
    lab = st_matrixrowstripe(name)[., 2]
    k = rows(S)
    if (k != cols(S)) {
        errprintf("matrix %s is not square\n", name)
        exit(503)
    }
    r = rowsum(S)
    cs_ = colsum(S)'
    d = r - cs_
    tot = sum(r)
    maxd = max(abs(d))
    nneg = sum(S :< 0)
    printf("\n{txt}Social accounting matrix {res}%s{txt}: %g accounts, total transactions {res}%g\n", name, k, tot)
    if (list) {
        printf("{txt}{hline 24}{c TT}{hline 42}\n")
        printf("{txt}%-24s{c |}%14s%14s%14s\n", "Account", "Receipts", "Payments", "Difference")
        printf("{txt}{hline 24}{c +}{hline 42}\n")
        for (i = 1; i <= k; i++) {
            printf("{txt}%-24s{c |}{res}%14.4f%14.4f%14.4f\n", abbrev(lab[i], 24), r[i], cs_[i], d[i])
        }
        printf("{txt}{hline 24}{c BT}{hline 42}\n")
    }
    printf("{txt}largest row-column imbalance: {res}%g{txt} (%g%% of total)\n", maxd, 100*maxd/max((tot, 1e-300)))
    if (nneg) printf("{txt}note: %g negative cell(s)\n", nneg)
    st_local("naccounts", strofreal(k))
    st_local("samtotal", strtrim(strofreal(tot, "%21.0g")))
    st_local("maxdiff", strtrim(strofreal(maxd, "%21.0g")))
    if (bal) {
        st_local("maxdiff0", strtrim(strofreal(maxd, "%21.0g")))
        if (nneg) {
            for (i = 1; i <= k; i++) {
                for (j = 1; j <= k; j++) {
                    if (S[i, j] < 0) {
                        S[j, i] = S[j, i] - S[i, j]
                        S[i, j] = 0
                    }
                }
            }
            printf("{txt}negative cells moved to the transposed cell (sign reversed) before balancing\n")
        }
        S = _cgemod_ras(S, tol, maxit, it, conv)
        maxd = max(abs(rowsum(S) - colsum(S)'))
        if (conv) printf("{txt}RAS balancing converged in {res}%g{txt} iterations; largest imbalance now {res}%g\n", it, maxd)
        else printf("{err}RAS balancing did not converge in %g iterations (largest imbalance %g)\n", it, maxd)
        st_matrix(name, S)
        st_matrixrowstripe(name, (J(k, 1, ""), lab))
        st_matrixcolstripe(name, (J(k, 1, ""), lab))
        st_local("maxdiff", strtrim(strofreal(maxd, "%21.0g")))
        st_local("samtotal", strtrim(strofreal(sum(rowsum(S)), "%21.0g")))
        st_local("rasit", strofreal(it))
        st_local("rasconv", strofreal(conv))
    }
}

/* ------------------------------------------------------------ parameters */
real colvector _cgemod_pvec(string scalar spec0, string rowvector n1, string rowvector n2,
                            real scalar dflt, string scalar what)
{
    real colvector v
    real matrix Mx
    string rowvector t, cn
    string scalar spec, tok, nm
    real scalar i, p, j, val, matched
    v = J(cols(n1), 1, dflt)
    spec = strtrim(spec0)
    if (spec == "") return(v)
    if (strtoreal(spec) < .) return(J(cols(n1), 1, strtoreal(spec)))
    t = tokens(spec)
    if (cols(t) == 1 & strpos(spec, "=") == 0) {
        Mx = st_matrix(spec)
        if (rows(Mx)*cols(Mx) == 0) {
            errprintf("%s(): %s is neither a number nor an existing matrix\n", what, spec)
            exit(111)
        }
        if (rows(Mx) > 1 & cols(Mx) == 1) {
            Mx = Mx'
            cn = st_matrixrowstripe(spec)[., 2]'
        }
        else cn = st_matrixcolstripe(spec)[., 2]'
        matched = 0
        for (j = 1; j <= cols(Mx); j++) {
            p = _cgemod_find(cn[j], n1, n2)
            if (p) {
                v[p] = Mx[1, j]
                matched++
            }
        }
        if (!matched) {
            if (cols(Mx) != cols(n1)) {
                errprintf("%s(): matrix %s has %g columns but there are %g sectors and no names match\n",
                          what, spec, cols(Mx), cols(n1))
                exit(503)
            }
            v = Mx[1, .]'
        }
        return(v)
    }
    for (i = 1; i <= cols(t); i++) {
        tok = t[i]
        p = strpos(tok, "=")
        if (p == 0) {
            val = strtoreal(tok)
            if (val >= .) {
                errprintf("%s(): cannot read %s\n", what, tok)
                exit(198)
            }
            v = J(cols(n1), 1, val)
        }
        else {
            nm = substr(tok, 1, p - 1)
            val = strtoreal(substr(tok, p + 1, .))
            j = _cgemod_find(nm, n1, n2)
            if (j == 0 | val >= .) {
                errprintf("%s(): cannot read %s\n", what, tok)
                exit(198)
            }
            v[j] = val
        }
    }
    return(v)
}

real colvector _cgemod_op(real colvector x0, string scalar spec, string rowvector n1, string rowvector n2,
                          string scalar what)
{
    real colvector x
    string rowvector t
    string scalar tok, op, nm
    real scalar i, p, pe, pm, pp, val, j, lo, hi, q
    x = x0
    t = tokens(spec)
    for (i = 1; i <= cols(t); i++) {
        tok = t[i]
        pe = strpos(tok, "=")
        pm = strpos(tok, "*")
        pp = strpos(tok, "+")
        p = 0
        if (pe) p = pe
        if (pm & (p == 0 | pm < p)) p = pm
        if (pp & (p == 0 | pp < p)) p = pp
        if (p == 0) {
            errprintf("%s(): token %s needs an operator (=, * or +), e.g. %s(*0.5) or %s(NAME=0.1)\n",
                      what, tok, what, what)
            exit(198)
        }
        op = substr(tok, p, 1)
        nm = substr(tok, 1, p - 1)
        val = strtoreal(substr(tok, p + 1, .))
        if (val >= .) {
            errprintf("%s(): cannot read the value in %s\n", what, tok)
            exit(198)
        }
        if (nm == "" | nm == "_all") {
            lo = 1
            hi = rows(x)
        }
        else {
            j = _cgemod_find(nm, n1, n2)
            if (j == 0) {
                errprintf("%s(): %s is not a valid account name here\n", what, nm)
                exit(111)
            }
            lo = j
            hi = j
        }
        for (q = lo; q <= hi; q++) {
            if (op == "=") x[q] = val
            else if (op == "*") x[q] = x[q]*val
            else x[q] = x[q] + val
        }
    }
    return(x)
}

real scalar _cgemod_sop(real scalar x, string scalar spec, string scalar what)
{
    real colvector v
    v = _cgemod_op(x, spec, J(1, 1, "_x_"), J(1, 0, ""), what)
    return(v[1])
}

real scalar _cgemod_applyshocks(transmorphic M)
{
    string rowvector com, act, fac, hh, keys, lists
    string scalar s
    real colvector v, old
    real matrix Fb
    real scalar i, f, ns
    com = asarray(M, "com")
    act = asarray(M, "act")
    fac = asarray(M, "fac")
    hh = asarray(M, "hh")
    ns = 0
    keys = ("tm", "tq", "te", "pwm", "pwe", "ta", "tfp")
    for (i = 1; i <= cols(keys); i++) {
        s = st_local(keys[i])
        if (strtrim(s) != "") {
            if (i <= 5) asarray(M, keys[i], _cgemod_op(asarray(M, keys[i]), s, com, act, keys[i]))
            else asarray(M, keys[i], _cgemod_op(asarray(M, keys[i]), s, act, com, keys[i]))
            ns++
        }
    }
    s = st_local("ty")
    if (strtrim(s) != "") {
        asarray(M, "ty", _cgemod_op(asarray(M, "ty"), s, asarray(M, "ins"), J(1, 0, ""), "ty"))
        ns++
    }
    s = st_local("wf")
    if (strtrim(s) != "") {
        asarray(M, "WFbar", _cgemod_op(asarray(M, "WFbar"), s, fac, J(1, 0, ""), "wf"))
        ns++
    }
    s = st_local("fs")
    if (strtrim(s) != "") {
        old = asarray(M, "FSbar")
        v = _cgemod_op(old, s, fac, J(1, 0, ""), "fs")
        Fb = asarray(M, "Fbar")
        for (f = 1; f <= rows(v); f++) {
            if (asarray(M, "factype")[f] == 2) Fb[f, .] = Fb[f, .] :* (v[f]/old[f])
            if (asarray(M, "factype")[f] == 3 & v[f] != old[f]) {
                printf("{txt}note: fs() ignored for unemployed factor %s (its employment is endogenous)\n", fac[f])
            }
        }
        asarray(M, "Fbar", Fb)
        asarray(M, "FSbar", v)
        ns++
    }
    s = st_local("gadj")
    if (strtrim(s) != "") {
        if (strtoreal(s) < .) asarray(M, "gadj", strtoreal(s))
        else asarray(M, "gadj", _cgemod_sop(asarray(M, "gadj"), s, "gadj"))
        ns++
    }
    s = st_local("fsav")
    if (strtrim(s) != "") {
        if (strtoreal(s) < .) asarray(M, "FSAVbar", strtoreal(s))
        else asarray(M, "FSAVbar", _cgemod_sop(asarray(M, "FSAVbar"), s, "fsav"))
        ns++
    }
    s = st_local("tmsched")
    if (strtrim(s) != "") {
        v = _cgemod_pvec(s, com, J(1, 0, ""), ., "tmsched")
        old = asarray(M, "tm")
        for (f = 1; f <= rows(v); f++) if (v[f] < .) old[f] = v[f]
        asarray(M, "tm", old)
        ns++
    }
    s = st_local("qg")
    if (strtrim(s) != "") {
        asarray(M, "qg0", _cgemod_op(asarray(M, "qg0"), s, com, J(1, 0, ""), "qg"))
        ns++
    }
    s = st_local("gsavshare")
    if (strtrim(s) != "") {
        if (strtoreal(s) >= .) {
            errprintf("gsavshare() must be a number (government savings as a share of GDP at factor cost)\n")
            exit(198)
        }
        if (asarray(M, "gclos") == 1) {
            errprintf("gsavshare() needs a closure with fixed government savings: calibrate with gsav(fixed) fiscal(...)\n")
            exit(198)
        }
        asarray(M, "gshare", strtoreal(s))
        ns++
    }
    s = st_local("ctax")
    if (strtrim(s) != "") {
        if (strtoreal(s) >= . | strtoreal(s) < 0) {
            errprintf("ctax() must be a non-negative number (currency units of the SAM per unit of emissions)\n")
            exit(198)
        }
        if (sum(abs(asarray(M, "efc"))) + sum(abs(asarray(M, "efa"))) == 0) {
            errprintf("ctax() needs emissions; specify emissions() or pemissions() in cgemod calibrate\n")
            exit(198)
        }
        asarray(M, "ctax", strtoreal(s))
        ns++
    }
    keys = ("mquota", "xquota", "pcap")
    lists = ("QM0", "QE0", "PQ0")
    for (i = 1; i <= 3; i++) {
        s = st_local(keys[i])
        if (strtrim(s) != "") {
            v = _cgemod_pvec(s, com, J(1, 0, ""), ., keys[i])
            old = asarray(M, lists[i])
            for (f = 1; f <= rows(v); f++) {
                if (v[f] < .) {
                    if (v[f] <= 0 | old[f] <= 0) {
                        errprintf("%s(): %s needs a positive multiple and a positive benchmark value\n", keys[i], com[f])
                        exit(198)
                    }
                    v[f] = v[f]*old[f]
                }
            }
            asarray(M, keys[i], v)
            ns++
        }
    }
    _cgemod_layout(M)
    return(ns)
}

/* ----------------------------------------------------------- calibration */
void _cgemod_calib()
{
    string scalar samname
    string rowvector names, cnames, act, com, fac, hh, ent, tax, tar, etx, spec, unemp, gnames
    real matrix S, U, INT0, FAC0, MAKE0, HOME0, thm, C0, CONS0, Cq0, beta, gam, shif, shii
    real rowvector A_, C_, F_, H_, E_, INS, TX, TR, ET, TO, allix
    real colvector X0, XM0, QX0, taxa0, E0, etax0, M0, tar0, stax0, MV0, QE0, QD0, QM0, QQ0, te, tm, tq, mr, PQ0, P0
    real colvector ta, VA0, TMV, wmg, yfrow, YF0, shifg, YI0, dtx, sav, ty, mps, DI0, DIs, shir, shc, EH0, eta
    real colvector u0, phiw, efc, efa
    string rowvector wcur
    real colvector qg0, qinv0, qdst, ft, z, R, sigva, sigq, omega, sigx, hasX, hasD, hasE, hasM, hasQ, ftx, tf, trow, NYF0
    real scalar g, r, s, tmg, ds, na, nc, nf, nh, ne, ni, k, i, j, f, h, nbad, frisch, it, nrm, rc, tiny
    transmorphic M, O
    pointer() scalar p

    tiny = 1e-9
    samname = st_local("sam")
    S = st_matrix(samname)
    names = st_matrixrowstripe(samname)[., 2]'
    cnames = st_matrixcolstripe(samname)[., 2]'
    k = rows(S)
    if (k != cols(S) | names != cnames) {
        errprintf("SAM %s must be square with identical row and column names\n", samname)
        exit(503)
    }
    act = tokens(st_local("activities"))
    com = tokens(st_local("commodities"))
    fac = tokens(st_local("factors"))
    hh = tokens(st_local("households"))
    ent = tokens(st_local("enterprises"))
    tax = tokens(st_local("taxes"))
    tar = tokens(st_local("tariff"))
    etx = tokens(st_local("exptax"))
    if (cols(tokens(st_local("government"))) != 1 | cols(tokens(st_local("row"))) != 1 |
        cols(tokens(st_local("savinv"))) != 1 | cols(tokens(st_local("margins"))) > 1 |
        cols(tokens(st_local("stocks"))) > 1) {
        errprintf("government(), row(), savinv(), margins() and stocks() each take one account\n")
        exit(198)
    }
    for (i = 1; i <= cols(tar); i++) if (!_cgemod_in(tax, tar[i])) tax = (tax, tar[i])
    for (i = 1; i <= cols(etx); i++) if (!_cgemod_in(tax, etx[i])) tax = (tax, etx[i])
    A_ = _cgemod_ix(act, names, "activity")
    C_ = _cgemod_ix(com, names, "commodity")
    F_ = _cgemod_ix(fac, names, "factor")
    H_ = _cgemod_ix(hh, names, "household")
    E_ = _cgemod_ix(ent, names, "enterprise")
    INS = (H_, E_)
    g = _cgemod_ix(tokens(st_local("government")), names, "government")[1]
    r = _cgemod_ix(tokens(st_local("row")), names, "rest-of-world")[1]
    s = _cgemod_ix(tokens(st_local("savinv")), names, "savings-investment")[1]
    tmg = 0
    if (cols(tokens(st_local("margins")))) tmg = _cgemod_ix(tokens(st_local("margins")), names, "margin")[1]
    ds = 0
    if (cols(tokens(st_local("stocks")))) ds = _cgemod_ix(tokens(st_local("stocks")), names, "stock-change")[1]
    TX = _cgemod_ix(tax, names, "tax")
    TR = _cgemod_ix(tar, names, "tariff")
    ET = _cgemod_ix(etx, names, "export-tax")
    TO = J(1, 0, .)
    for (i = 1; i <= cols(TX); i++) if (!_cgemod_in(TR, TX[i]) & !_cgemod_in(ET, TX[i])) TO = (TO, TX[i])
    for (i = 1; i <= cols(TR); i++) {
        if (_cgemod_in(ET, TR[i])) {
            errprintf("an account cannot be both a tariff and an export-tax account\n")
            exit(198)
        }
    }
    allix = (A_, C_, F_, INS, g, r, s, TX)
    if (tmg) allix = (allix, tmg)
    if (ds) allix = (allix, ds)
    if (rows(uniqrows(allix')) != cols(allix)) {
        errprintf("each SAM account may be given only one role\n")
        exit(198)
    }
    na = cols(A_)
    nc = cols(C_)
    nf = cols(F_)
    nh = cols(H_)
    ne = cols(E_)
    ni = nh + ne

    /* ---- supported cells (row receives from column) */
    U = J(k, k, 0)
    U[C_, A_] = J(nc, na, 1)
    U[F_, A_] = J(nf, na, 1)
    U[g, A_] = J(1, na, 1)
    if (cols(TX)) U[TX, A_] = J(cols(TX), na, 1)
    U[A_, C_] = J(na, nc, 1)
    U[A_, H_] = J(na, nh, 1)
    if (cols(TX)) U[TX, C_] = J(cols(TX), nc, 1)
    U[g, C_] = J(1, nc, 1)
    U[r, C_] = J(1, nc, 1)
    if (tmg) {
        U[tmg, C_] = J(1, nc, 1)
        U[C_, tmg] = J(nc, 1, 1)
    }
    U[C_, H_] = J(nc, nh, 1)
    U[C_, g] = J(nc, 1, 1)
    U[C_, s] = J(nc, 1, 1)
    U[C_, r] = J(nc, 1, 1)
    if (ds) {
        U[C_, ds] = J(nc, 1, 1)
        U[ds, s] = 1
        U[s, ds] = 1
    }
    U[INS, F_] = J(ni, nf, 1)
    U[g, F_] = J(1, nf, 1)
    if (cols(TX)) U[TX, F_] = J(cols(TX), nf, 1)
    U[r, F_] = J(1, nf, 1)
    U[F_, r] = J(nf, 1, 1)
    U[INS, INS] = J(ni, ni, 1) - I(ni)
    U[INS, g] = J(ni, 1, 1)
    U[INS, r] = J(ni, 1, 1)
    if (cols(TX)) U[TX, INS] = J(cols(TX), ni, 1)
    U[g, INS] = J(1, ni, 1)
    U[s, INS] = J(1, ni, 1)
    U[r, INS] = J(1, ni, 1)
    if (cols(TX)) U[g, TX] = J(1, cols(TX), 1)
    U[g, r] = 1
    U[r, g] = 1
    U[s, g] = 1
    U[g, s] = 1
    U[s, r] = 1
    U[r, s] = 1
    nbad = 0
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= k; j++) {
            if (abs(S[i, j]) > 1e-9 & U[i, j] == 0) {
                if (nbad == 0) errprintf("unsupported SAM flows (payer -> receiver):\n")
                nbad++
                if (nbad <= 25) errprintf("   %s -> %s : %g\n", names[j], names[i], S[i, j])
            }
        }
    }
    if (nbad) {
        errprintf("%g unsupported cell(s); fold them into supported flows (see help cgemod, SAM layout)\n", nbad)
        exit(459)
    }
    if (max(abs(rowsum(S) - colsum(S)')) > 1e-6*max((1, sum(abs(S))))) {
        errprintf("SAM %s is not balanced; use cgemod sambalance, sam(%s)\n", samname, samname)
        exit(459)
    }

    /* ---- production, make matrix and trade */
    MAKE0 = S[A_, C_]
    HOME0 = S[A_, H_]
    XM0 = rowsum(MAKE0)
    X0 = XM0 + rowsum(HOME0)
    INT0 = S[C_, A_]
    FAC0 = S[F_, A_]
    VA0 = colsum(FAC0)'
    taxa0 = J(na, 1, .)
    for (i = 1; i <= na; i++) {
        taxa0[i] = _cgemod_sr(S, TX, A_[i]) + S[g, A_[i]]
        if (XM0[i] <= tiny) {
            errprintf("activity %s sells nothing to commodity markets\n", act[i])
            exit(459)
        }
        if (VA0[i] <= tiny) {
            errprintf("activity %s has no value added\n", act[i])
            exit(459)
        }
    }
    thm = MAKE0 :/ XM0
    QX0 = colsum(MAKE0)'
    E0 = S[C_, r]
    M0 = S[r, C_]'
    etax0 = J(nc, 1, .)
    tar0 = J(nc, 1, .)
    stax0 = J(nc, 1, .)
    for (i = 1; i <= nc; i++) {
        etax0[i] = _cgemod_sr(S, ET, C_[i])
        tar0[i] = _cgemod_sr(S, TR, C_[i])
        stax0[i] = _cgemod_sr(S, TO, C_[i]) + S[g, C_[i]]
    }
    MV0 = J(nc, 1, 0)
    TMV = J(nc, 1, 0)
    if (tmg) {
        MV0 = S[tmg, C_]'
        TMV = S[C_, tmg]
    }
    QE0 = E0 - etax0
    QD0 = QX0 - QE0
    QM0 = M0 + tar0
    QQ0 = QD0 + QM0
    hasX = QX0 :> tiny
    hasD = QD0 :> tiny
    hasE = QE0 :> tiny
    hasM = QM0 :> tiny
    hasQ = QQ0 :> tiny
    for (i = 1; i <= nc; i++) {
        if (QD0[i] < -tiny | QE0[i] < -tiny | M0[i] < -tiny) {
            errprintf("commodity %s has negative domestic sales, exports or imports\n", com[i])
            exit(459)
        }
        if (!hasX[i] & !hasM[i]) {
            errprintf("commodity %s is neither produced nor imported\n", com[i])
            exit(459)
        }
        if (!hasQ[i] & sum(abs(S[C_[i], .])) - E0[i] > 1e-6) {
            errprintf("commodity %s is used domestically but has no domestic supply\n", com[i])
            exit(459)
        }
    }
    te = J(nc, 1, 0)
    tm = J(nc, 1, 0)
    mr = J(nc, 1, 0)
    tq = J(nc, 1, 0)
    for (i = 1; i <= nc; i++) {
        if (E0[i] > 0) te[i] = etax0[i]/E0[i]
        if (M0[i] > 0) tm[i] = tar0[i]/M0[i]
        if (hasQ[i]) {
            mr[i] = MV0[i]/QQ0[i]
            tq[i] = stax0[i]/((1 + mr[i])*QQ0[i])
        }
    }
    PQ0 = (1 :+ mr) :* (1 :+ tq)
    wmg = J(nc, 1, 0)
    if (sum(TMV) > 0) wmg = (TMV :/ sum(TMV)) :/ PQ0
    for (f = 1; f <= nf; f++) {
        if (sum(FAC0[f, .]) <= 0) {
            errprintf("factor %s is not used by any activity\n", fac[f])
            exit(459)
        }
    }

    /* ---- elasticities */
    sigva = _cgemod_pvec(st_local("sigmava"), act, J(1, 0, ""), 0.8, "sigmava")
    sigq = _cgemod_pvec(st_local("sigmaq"), com, J(1, 0, ""), 2, "sigmaq")
    omega = _cgemod_pvec(st_local("omega"), com, J(1, 0, ""), 2, "omega")
    sigx = _cgemod_pvec(st_local("sigmax"), com, J(1, 0, ""), 4, "sigmax")
    if (min(sigva) <= 0 | min(sigq) <= 0 | min(omega) <= 0 | min(sigx) <= 0) {
        errprintf("elasticities must be positive\n")
        exit(198)
    }

    /* ---- factors and institutions */
    yfrow = S[F_, r]
    YF0 = rowsum(FAC0) + yfrow
    ftx = J(nf, 1, 0)
    for (f = 1; f <= nf; f++) ftx[f] = _cgemod_sr(S, TX, F_[f])
    tf = ftx :/ YF0
    trow = S[r, F_]'
    NYF0 = (1 :- tf) :* YF0 - trow
    for (f = 1; f <= nf; f++) {
        if (NYF0[f] <= tiny & sum(abs(S[(INS, g), F_[f]])) > tiny) {
            errprintf("factor %s pays out more in taxes and to the rest of the world than it earns\n", fac[f])
            exit(459)
        }
    }
    NYF0 = NYF0 + (NYF0 :<= tiny)
    shif = S[INS, F_] :/ (NYF0')
    shifg = (S[g, F_]') :/ NYF0
    YI0 = rowsum(S[INS, .])
    dtx = J(ni, 1, .)
    for (i = 1; i <= ni; i++) {
        dtx[i] = _cgemod_sr(S, TX, INS[i]) + S[g, INS[i]]
        if (YI0[i] <= 0) {
            errprintf("institution %s has no income\n", names[INS[i]])
            exit(459)
        }
    }
    sav = S[s, INS]'
    ty = dtx :/ YI0
    mps = sav :/ ((1 :- ty) :* YI0)
    DI0 = YI0 - dtx - sav
    DIs = DI0 + (DI0 :<= tiny)
    shii = S[INS, INS] :/ (DIs')
    shir = (S[r, INS]') :/ DIs
    CONS0 = S[C_, INS] \ S[A_, INS]
    shc = (colsum(CONS0)') :/ DIs
    for (i = nh + 1; i <= ni; i++) {
        if (shc[i] > 1e-9) {
            errprintf("enterprise %s buys consumption goods; list it under households()\n", names[INS[i]])
            exit(459)
        }
    }
    C0 = CONS0[., 1..nh]
    EH0 = colsum(C0)'
    for (h = 1; h <= nh; h++) {
        if (EH0[h] <= 0) {
            errprintf("household %s has no consumption\n", hh[h])
            exit(459)
        }
    }
    P0 = PQ0 \ J(na, 1, 1)
    frisch = strtoreal(st_local("frisch"))
    gnames = (com, act)
    eta = _cgemod_pvec(st_local("incelas"), gnames, J(1, 0, ""), 1, "incelas")
    if (min(eta) <= 0) {
        errprintf("incelas() must be positive\n")
        exit(198)
    }
    beta = (C0 :/ EH0') :* eta
    beta = beta :/ colsum(beta)
    Cq0 = C0 :/ P0
    gam = Cq0 + (beta :* (EH0')) :/ (P0 :* frisch)
    if (frisch > -1 & frisch < 0) printf("{txt}note: frisch() between -1 and 0 implies negative subsistence quantities\n")
    qg0 = S[C_, g] :/ PQ0
    qinv0 = S[C_, s] :/ PQ0
    qdst = J(nc, 1, 0)
    if (ds) qdst = S[C_, ds] :/ PQ0

    /* ---- factor market closures */
    ft = J(nf, 1, 1)
    spec = tokens(st_local("specific"))
    unemp = tokens(st_local("unemployed"))
    wcur = tokens(st_local("wagecurve"))
    for (i = 1; i <= cols(spec); i++) {
        j = _cgemod_find(spec[i], fac, J(1, 0, ""))
        if (!j) {
            errprintf("specific(): %s is not a factor\n", spec[i])
            exit(111)
        }
        ft[j] = 2
    }
    for (i = 1; i <= cols(unemp); i++) {
        j = _cgemod_find(unemp[i], fac, J(1, 0, ""))
        if (!j) {
            errprintf("unemployed(): %s is not a factor\n", unemp[i])
            exit(111)
        }
        if (ft[j] == 2) {
            errprintf("factor %s cannot be both sector-specific and unemployed\n", unemp[i])
            exit(198)
        }
        ft[j] = 3
    }
    for (i = 1; i <= cols(wcur); i++) {
        j = _cgemod_find(wcur[i], fac, J(1, 0, ""))
        if (!j) {
            errprintf("wagecurve(): %s is not a factor\n", wcur[i])
            exit(111)
        }
        if (ft[j] != 1) {
            errprintf("factor %s already has another closure\n", wcur[i])
            exit(198)
        }
        ft[j] = 4
    }
    u0 = _cgemod_pvec(st_local("urate"), fac, J(1, 0, ""), 0.1, "urate")
    phiw = _cgemod_pvec(st_local("elasw"), fac, J(1, 0, ""), 0.1, "elasw")
    for (f = 1; f <= nf; f++) {
        if (ft[f] == 4 & (u0[f] <= 0 | u0[f] >= 1 | phiw[f] <= 0)) {
            errprintf("wage curve for %s needs 0 < urate() < 1 and elasw() > 0\n", fac[f])
            exit(198)
        }
    }
    efc = _cgemod_pvec(st_local("emissions"), com, J(1, 0, ""), 0, "emissions")
    efa = _cgemod_pvec(st_local("pemissions"), act, J(1, 0, ""), 0, "pemissions")
    for (i = 1; i <= nc; i++) efc[i] = (hasQ[i] ? efc[i]/QQ0[i] : 0)
    efa = efa :/ X0

    /* ---- store */
    M = asarray_create()
    asarray(M, "samname", samname)
    asarray(M, "SAM", S)
    asarray(M, "names", names)
    asarray(M, "act", act)
    asarray(M, "com", com)
    asarray(M, "fac", fac)
    asarray(M, "hh", hh)
    asarray(M, "ins", names[INS])
    asarray(M, "na", na)
    asarray(M, "nc", nc)
    asarray(M, "nf", nf)
    asarray(M, "nh", nh)
    asarray(M, "ni", ni)
    asarray(M, "sigva", sigva)
    asarray(M, "sigq", sigq)
    asarray(M, "omega", omega)
    asarray(M, "sigx", sigx)
    asarray(M, "frisch", frisch)
    asarray(M, "eta", eta)
    asarray(M, "MAKE0", MAKE0)
    asarray(M, "thm", thm)
    asarray(M, "X0", X0)
    asarray(M, "XM0", XM0)
    asarray(M, "QX0", QX0)
    asarray(M, "QE0", QE0)
    asarray(M, "QD0", QD0)
    asarray(M, "QM0", QM0)
    asarray(M, "QQ0", QQ0)
    asarray(M, "hasX", hasX)
    asarray(M, "hasD", hasD)
    asarray(M, "hasE", hasE)
    asarray(M, "hasM", hasM)
    asarray(M, "hasQ", hasQ)
    asarray(M, "te", te)
    asarray(M, "tm", tm)
    asarray(M, "tq", tq)
    asarray(M, "mr", mr)
    asarray(M, "wmg", wmg)
    asarray(M, "ta", taxa0 :/ X0)
    asarray(M, "PQ0", PQ0)
    asarray(M, "pwe", 1 :/ (1 :- te))
    asarray(M, "pwm", 1 :/ (1 :+ tm))
    asarray(M, "pwe0", 1 :/ (1 :- te))
    asarray(M, "pwm0", 1 :/ (1 :+ tm))
    asarray(M, "VA0", VA0)
    asarray(M, "iva", VA0 :/ X0)
    asarray(M, "ica", (INT0 :/ PQ0) :/ (X0'))
    asarray(M, "FAC0", FAC0)
    asarray(M, "yfrow", yfrow)
    asarray(M, "YF0", YF0)
    asarray(M, "shif", shif)
    asarray(M, "shifg", shifg)
    asarray(M, "tf", tf)
    asarray(M, "trow", trow)
    asarray(M, "qdst", qdst)
    asarray(M, "trg", S[INS, g])
    asarray(M, "trr", S[INS, r])
    asarray(M, "YI0", YI0)
    asarray(M, "ty", ty)
    asarray(M, "mps", mps)
    asarray(M, "shii", shii)
    asarray(M, "shir", shir)
    asarray(M, "shc", shc)
    asarray(M, "EH0", EH0)
    asarray(M, "beta", beta)
    asarray(M, "gam", gam)
    asarray(M, "Cq0", Cq0)
    asarray(M, "qg0", qg0)
    asarray(M, "qinv0", qinv0)
    asarray(M, "trrg", S[g, r])
    asarray(M, "trgr", S[r, g])
    asarray(M, "GSAV0", S[s, g] - S[g, s])
    asarray(M, "FSAV0", S[s, r] - S[r, s])
    asarray(M, "cwts", rowsum(Cq0[1..nc, .]))
    asarray(M, "scale", max((sum(M0), 1)))
    asarray(M, "invscale", max((sum(S[C_, s]), 1)))
    asarray(M, "factype", ft)
    asarray(M, "u0", u0)
    asarray(M, "phiw", phiw)
    asarray(M, "efc", efc)
    asarray(M, "efa", efa)
    asarray(M, "ctax", 0)
    asarray(M, "mquota", J(nc, 1, .))
    asarray(M, "xquota", J(nc, 1, .))
    asarray(M, "pcap", J(nc, 1, .))
    asarray(M, "gshare", .)
    asarray(M, "qinvx", J(nc, 1, 0))
    asarray(M, "ext", (st_local("exchange") == "fixed" ? 2 : 1))
    asarray(M, "gclos", (st_local("gsav") == "fixed" ?
        1 + (st_local("fiscal") == "dirtax") + 2*(st_local("fiscal") == "transfers") + 3*(st_local("fiscal") == "salestax") + 4*(st_local("fiscal") == "spending") : 1))
    asarray(M, "siclos", (st_local("siclosure") == "investment" ? 2 : 1))
    asarray(M, "EXR0", 1)
    asarray(M, "FSAVbar", S[s, r] - S[r, s])
    asarray(M, "WFbar", J(nf, 1, 1))
    asarray(M, "FSbar", rowsum(FAC0))
    asarray(M, "Fbar", FAC0)
    asarray(M, "tfp", J(na, 1, 1))
    asarray(M, "gadj", 1)
    asarray(M, "IADJbar", 1)
    asarray(M, "MPSADJbar", 0)
    asarray(M, "TINSADJbar", 0)
    asarray(M, "CPI0", 1)
    asarray(M, "tol", strtoreal(st_local("tolerance")))
    asarray(M, "maxit", strtoreal(st_local("maxiter")))
    asarray(M, "solver", (st_local("solver") == "broyden" ? 2 : 1))
    if (asarray(M, "gclos") == 3 & sum(S[INS, g]) <= 0) {
        errprintf("fiscal(transfers) needs government transfers to institutions in the SAM\n")
        exit(459)
    }
    if (asarray(M, "gclos") == 5 & sum(S[C_, g]) <= 0) {
        errprintf("fiscal(spending) needs government consumption in the SAM\n")
        exit(459)
    }
    if (asarray(M, "gclos") == 2 & sum(ty) <= 0) {
        errprintf("gsav(fixed) needs a positive direct-tax rate to adjust, but no institution pays direct tax\n")
        exit(459)
    }
    _cgemod_layout(M)

    /* ---- benchmark replication */
    z = _cgemod_start(M)
    O = asarray_create()
    R = _cgemod_eval(z, M, 0, O)
    st_local("benchres", strtrim(strofreal(max(abs(R)), "%21.0g")))
    rc = _cgemod_solve(M, z, it, nrm)
    if (rc) {
        errprintf("benchmark could not be solved (code %g)\n", rc)
        exit(430)
    }
    asarray(M, "zbase", z)
    p = findexternal("_cgemod_M")
    if (p == NULL) p = crexternal("_cgemod_M")
    *p = M
    st_local("na", strofreal(na))
    st_local("nc", strofreal(nc))
    st_local("nf", strofreal(nf))
    st_local("nh", strofreal(nh))
    st_local("ne", strofreal(ne))
    printf("\n{txt}cgemod: model calibrated from SAM {res}%s{txt} (%g activities, %g commodities, %g factors, %g households, %g enterprises)\n",
           samname, na, nc, nf, nh, ne)
    printf("{txt}benchmark replication: largest residual at benchmark prices = {res}%9.2e\n", max(abs(R)))
    if (st_local("table") == "") _cgemod_describe()
}

real colvector _cgemod_fb(real colvector a, real colvector b)
{
    return(a + b - sqrt(a :^ 2 + b :^ 2))
}

real scalar _cgemod_cesq(real colvector dl, real colvector q, real scalar sig)
{
    real scalar rr
    if (abs(sig - 1) < 1e-8) return(exp(sum(dl :* ln(q))))
    rr = (sig - 1)/sig
    return(sum(dl :* q :^ rr) ^ (1/rr))
}

/* ----------------------------------------------------------------- model */

/* ---------------------------------------------------------------- layout */

/* ---------------------------------------------------------------- layout */
void _cgemod_layout(transmorphic M)
{
    real scalar na, nf, k, f, pPD, pX, pPA, pEXT, pSI, pT, pW, pPMG, pRM, pRX, pSC
    real colvector ft, fpos, fcnt
    real matrix Fbar
    na = asarray(M, "na")
    nf = asarray(M, "nf")
    ft = asarray(M, "factype")
    Fbar = asarray(M, "Fbar")
    fpos = J(nf, 1, 0)
    fcnt = J(nf, 1, 0)
    pPD = 1
    k = sum(asarray(M, "hasD"))
    pX = k + 1
    pPA = k + na + 1
    k = k + 2*na
    pPMG = 0
    if (sum(asarray(M, "wmg")) > 0) {
        pPMG = k + 1
        k++
    }
    for (f = 1; f <= nf; f++) {
        if (ft[f] == 1 | ft[f] == 4) {
            fpos[f] = k + 1
            fcnt[f] = 1
            k++
        }
        else if (ft[f] == 2) {
            fpos[f] = k + 1
            fcnt[f] = sum(Fbar[f, .] :> 0)
            k = k + fcnt[f]
        }
    }
    pEXT = k + 1
    pSI = k + 2
    k = k + 2
    pT = 0
    if (asarray(M, "gclos") > 1) {
        pT = k + 1
        k++
    }
    pW = k + 1
    k++
    pRM = 0
    pRX = 0
    pSC = 0
    if (sum(asarray(M, "mquota") :< .)) {
        pRM = k + 1
        k = k + sum(asarray(M, "mquota") :< .)
    }
    if (sum(asarray(M, "xquota") :< .)) {
        pRX = k + 1
        k = k + sum(asarray(M, "xquota") :< .)
    }
    if (sum(asarray(M, "pcap") :< .)) {
        pSC = k + 1
        k = k + sum(asarray(M, "pcap") :< .)
    }
    asarray(M, "pos", (pPD, pX, pPA, pEXT, pSI, pT, pW, k, pPMG, pRM, pRX, pSC))
    asarray(M, "fpos", fpos)
    asarray(M, "fcnt", fcnt)
    asarray(M, "iD", selectindex(asarray(M, "hasD")))
}

real colvector _cgemod_start(transmorphic M)
{
    real rowvector pos
    real colvector z
    pos = asarray(M, "pos")
    z = J(pos[8], 1, 1)
    z[pos[5]] = (asarray(M, "siclos") == 1 ? 1 : 0)
    if (asarray(M, "ext") == 2) z[pos[4]] = asarray(M, "FSAVbar")/asarray(M, "scale")
    if (pos[6]) z[pos[6]] = (asarray(M, "gclos") == 3 | asarray(M, "gclos") == 5 ? 1 : 0)
    z[pos[7]] = 0
    if (pos[8] > pos[7]) z[|pos[7] + 1 \ pos[8]|] = J(pos[8] - pos[7], 1, 0)
    return(z)
}

/* ----------------------------------------------------------------- model */
real colvector _cgemod_eval(real colvector z, transmorphic M, real scalar full, transmorphic O)
{
    real scalar na, nc, nf, nh, ni, nD, f, i, a, cu, EXR, FSAV, IADJ, MPSADJ, TINSADJ, WAL, CPI, YG, EG, GSAV
    real scalar bop, sav, scale, invscale, PMG, sm, qx
    real rowvector pos, idx
    real colvector fpos, fcnt, ft, iD, X0, QX0, QE0, QD0, QM0, QQ0, te, tm, tq, mr, wmg, ta, pwe, pwm, PQ0, iva, VA0
    real colvector hasX, hasD, hasE, hasM, sigva, sigq, omega, sigx, tfp, WFbar, FSbar, yfrow, shifg
    real colvector trg, trr, tyv, mpsv, shir, shc, qg0, qinv0, qdst, cwts, Dd, binc, YI, EH, Pg, QHA, XM, PAc, aa, dl, q
    real colvector tf, trow, NYF, PDD, PMM, km, kd, kk, rm, rx, sc, efc, efa, u0, phiw, PQN, CW, ii
    real scalar adj, GADJ, TRADJ, DTQ, ctax, CREV, QREV, SUBS, EMIS, NGDP, tgt, D0
    real colvector PD, X, PA, PE, PM, PX, PQA, PQB, PQ, PVA, QE, QDs, QDd, QM, QQ, QX, YF, QG, QINV, base, QT, th, nz, R, TRIR
    real matrix ica, FAC0, Fbar, shif, shii, beta, gam, thm, MAKE0, W, Fd, Cq, QXAC, PXAC

    na = asarray(M, "na")
    nc = asarray(M, "nc")
    nf = asarray(M, "nf")
    nh = asarray(M, "nh")
    ni = asarray(M, "ni")
    pos = asarray(M, "pos")
    fpos = asarray(M, "fpos")
    fcnt = asarray(M, "fcnt")
    ft = asarray(M, "factype")
    iD = asarray(M, "iD")
    nD = rows(iD)
    X0 = asarray(M, "X0")
    QX0 = asarray(M, "QX0")
    QE0 = asarray(M, "QE0")
    QD0 = asarray(M, "QD0")
    QM0 = asarray(M, "QM0")
    QQ0 = asarray(M, "QQ0")
    hasX = asarray(M, "hasX")
    hasD = asarray(M, "hasD")
    hasE = asarray(M, "hasE")
    hasM = asarray(M, "hasM")
    te = asarray(M, "te")
    tm = asarray(M, "tm")
    tq = asarray(M, "tq")
    mr = asarray(M, "mr")
    wmg = asarray(M, "wmg")
    ta = asarray(M, "ta")
    pwe = asarray(M, "pwe")
    pwm = asarray(M, "pwm")
    PQ0 = asarray(M, "PQ0")
    iva = asarray(M, "iva")
    ica = asarray(M, "ica")
    FAC0 = asarray(M, "FAC0")
    VA0 = asarray(M, "VA0")
    MAKE0 = asarray(M, "MAKE0")
    thm = asarray(M, "thm")
    sigva = asarray(M, "sigva")
    sigq = asarray(M, "sigq")
    omega = asarray(M, "omega")
    sigx = asarray(M, "sigx")
    tfp = asarray(M, "tfp")
    WFbar = asarray(M, "WFbar")
    FSbar = asarray(M, "FSbar")
    Fbar = asarray(M, "Fbar")
    yfrow = asarray(M, "yfrow")
    shif = asarray(M, "shif")
    shifg = asarray(M, "shifg")
    tf = asarray(M, "tf")
    trow = asarray(M, "trow")
    qdst = asarray(M, "qdst")
    trg = asarray(M, "trg")
    trr = asarray(M, "trr")
    shii = asarray(M, "shii")
    shir = asarray(M, "shir")
    shc = asarray(M, "shc")
    beta = asarray(M, "beta")
    gam = asarray(M, "gam")
    qg0 = asarray(M, "qg0")
    qinv0 = asarray(M, "qinv0")
    cwts = asarray(M, "cwts")
    scale = asarray(M, "scale")
    invscale = asarray(M, "invscale")

    PD = J(nc, 1, 1)
    if (nD) PD[iD] = z[|pos[1] \ pos[1] + nD - 1|]
    X = z[|pos[2] \ pos[2] + na - 1|] :* X0
    PA = z[|pos[3] \ pos[3] + na - 1|]
    if (asarray(M, "ext") == 1) {
        EXR = z[pos[4]]
        FSAV = asarray(M, "FSAVbar")
    }
    else {
        EXR = asarray(M, "EXR0")
        FSAV = z[pos[4]]*scale
    }
    if (asarray(M, "siclos") == 1) {
        IADJ = z[pos[5]]
        MPSADJ = asarray(M, "MPSADJbar")
    }
    else {
        IADJ = asarray(M, "IADJbar")
        MPSADJ = z[pos[5]]
    }
    adj = (pos[6] ? z[pos[6]] : .)
    TINSADJ = (asarray(M, "gclos") == 2 ? adj : asarray(M, "TINSADJbar"))
    TRADJ = (asarray(M, "gclos") == 3 ? adj : 1)
    DTQ = (asarray(M, "gclos") == 4 ? adj : 0)
    GADJ = (asarray(M, "gclos") == 5 ? adj : asarray(M, "gadj"))
    WAL = z[pos[7]]*scale
    rm = J(nc, 1, 0)
    rx = J(nc, 1, 0)
    sc = J(nc, 1, 0)
    if (pos[10]) {
        ii = selectindex(asarray(M, "mquota") :< .)
        rm[ii] = z[|pos[10] \ pos[10] + rows(ii) - 1|]
    }
    if (pos[11]) {
        ii = selectindex(asarray(M, "xquota") :< .)
        rx[ii] = z[|pos[11] \ pos[11] + rows(ii) - 1|]
    }
    if (pos[12]) {
        ii = selectindex(asarray(M, "pcap") :< .)
        sc[ii] = z[|pos[12] \ pos[12] + rows(ii) - 1|]
    }
    efc = asarray(M, "efc")
    efa = asarray(M, "efa")
    ctax = asarray(M, "ctax")
    u0 = asarray(M, "u0")
    phiw = asarray(M, "phiw")
    tq = tq :+ DTQ

    W = J(nf, na, 1)
    for (f = 1; f <= nf; f++) {
        if (ft[f] == 1 | ft[f] == 4) W[f, .] = J(1, na, z[fpos[f]])
        else if (ft[f] == 3) W[f, .] = J(1, na, WFbar[f])
        else {
            W[f, .] = J(1, na, WFbar[f])
            idx = selectindex(Fbar[f, .] :> 0)
            W[f, idx] = WFbar[f] :* (z[|fpos[f] \ fpos[f] + fcnt[f] - 1|])'
        }
    }
    PMG = (pos[9] ? z[pos[9]] : 0)
    PE = pwe :* EXR :* (1 :- te) :* (1 :- rx)
    PM = pwm :* EXR :* (1 :+ tm) :* (1 :+ rm)
    PDD = PD + mr :* PMG
    PMM = PM + mr :* PMG
    PX = J(nc, 1, 1)
    PQA = J(nc, 1, 1)
    for (i = 1; i <= nc; i++) {
        if (hasD[i] & hasE[i]) PX[i] = _cgemod_cesp((QE0[i] \ QD0[i]) :/ QX0[i], (PE[i] \ PD[i]), -omega[i])
        else if (hasD[i]) PX[i] = PD[i]
        else if (hasE[i]) PX[i] = PE[i]
        if (hasD[i] & hasM[i]) PQA[i] = (1 + mr[i])*_cgemod_cesp((QM0[i] \ QD0[i]) :/ QQ0[i], (PMM[i] \ PDD[i]) :/ (1 + mr[i]), sigq[i])
        else if (hasD[i]) PQA[i] = PDD[i]
        else if (hasM[i]) PQA[i] = PMM[i]
    }
    PQB = PQA
    PQN = PQB :* (1 :+ tq) :* (1 :- sc)
    CW = cwts
    D0 = sum(PQ0 :* CW)
    CPI = sum(PQN :* CW)/(D0 - ctax*sum((1 :- sc) :* efc :* CW))
    PQ = PQN + ctax*CPI :* efc :* (1 :- sc)

    PVA = J(na, 1, 1)
    Fd = J(nf, na, 0)
    for (a = 1; a <= na; a++) {
        th = FAC0[., a] :/ VA0[a]
        nz = selectindex(th :> 0)
        cu = _cgemod_cesp(th[nz], W[nz, a], sigva[a])
        PVA[a] = cu/tfp[a]
        Fd[nz, a] = (iva[a]*X[a]/tfp[a]) :* th[nz] :* (W[nz, a] :/ cu) :^ (-sigva[a])
    }

    YF = rowsum(W :* Fd) + yfrow :* EXR
    NYF = (1 :- tf) :* YF - trow :* EXR
    trg = trg :* TRADJ
    binc = shif*NYF + trg :* CPI + trr :* EXR
    tyv = asarray(M, "ty") :* (1 + TINSADJ)
    mpsv = asarray(M, "mps") :* (1 + MPSADJ)
    Dd = (1 :- mpsv) :* (1 :- tyv)
    YI = lusolve(I(ni) - shii :* (Dd'), binc)
    TRIR = shc :* Dd :* YI
    EH = TRIR[|1 \ nh|]
    Pg = PQ \ PA
    Cq = gam + (beta :/ Pg) :* (EH' - colsum(Pg :* gam))
    QHA = rowsum(Cq[|nc + 1, 1 \ nc + na, nh|])
    XM = X - QHA
    QXAC = thm :* XM
    QX = J(nc, 1, 0)
    PXAC = J(na, nc, 0)
    for (i = 1; i <= nc; i++) {
        if (!hasX[i]) continue
        aa = selectindex(MAKE0[., i] :> 0)
        dl = MAKE0[aa, i] :/ QX0[i]
        q = QXAC[aa, i] :/ MAKE0[aa, i]
        qx = _cgemod_cesq(dl, q, sigx[i])
        QX[i] = qx*QX0[i]
        PXAC[aa, i] = PX[i] :* (q :/ qx) :^ (-1/sigx[i])
    }
    PAc = rowsum(thm :* PXAC)

    QE = J(nc, 1, 0)
    QDs = J(nc, 1, 0)
    for (i = 1; i <= nc; i++) {
        if (hasD[i] & hasE[i]) {
            QE[i] = QX[i]*(QE0[i]/QX0[i])*(PE[i]/PX[i])^omega[i]
            QDs[i] = QX[i]*(QD0[i]/QX0[i])*(PD[i]/PX[i])^omega[i]
        }
        else if (hasD[i]) QDs[i] = QX[i]
        else if (hasE[i]) QE[i] = QX[i]
    }
    QG = qg0 :* GADJ
    QINV = qinv0 :* IADJ
    base = ica*X + rowsum(Cq[|1, 1 \ nc, nh|]) + QG + QINV + qdst + asarray(M, "qinvx")
    km = J(nc, 1, 0)
    kd = J(nc, 1, 0)
    for (i = 1; i <= nc; i++) {
        if (hasD[i] & hasM[i]) {
            km[i] = (QM0[i]/QQ0[i])*(PMM[i]/PQA[i])^(-sigq[i])
            kd[i] = (QD0[i]/QQ0[i])*(PDD[i]/PQA[i])^(-sigq[i])
        }
        else if (hasD[i]) kd[i] = 1
        else if (hasM[i]) km[i] = 1
    }
    kk = mr :* (km + kd)
    sm = 0
    if (sum(wmg) > 0) sm = sum(kk :* base)/(1 - sum(kk :* wmg))
    QT = wmg :* sm
    QQ = base + QT
    QM = km :* QQ
    QDd = kd :* QQ

    CREV = ctax*CPI*(sum(efc :* (1 :- sc) :* QQ) + sum(efa :* X))
    QREV = sum(rm :* pwm :* (1 :+ tm) :* QM)*EXR + sum(rx :* pwe :* (1 :- te) :* QE)*EXR
    SUBS = sum(sc :* (PQB :* (1 :+ tq) + ctax*CPI :* efc) :* QQ)
    YG = sum(tyv :* YI) + sum(ta :* PA :* X) + sum(tq :* PQB :* QQ) + sum(tm :* pwm :* QM)*EXR +
         sum(te :* pwe :* QE)*EXR + sum(tf :* YF) + sum(shifg :* NYF) + asarray(M, "trrg")*EXR + CREV + QREV
    EG = sum(PQ :* QG) + sum(trg)*CPI + asarray(M, "trgr")*EXR + SUBS + sum(PQ :* asarray(M, "qinvx"))
    EMIS = sum(efc :* QQ) + sum(efa :* X)
    NGDP = sum(PVA :* iva :* X)
    GSAV = YG - EG
    TRIR = shir :* Dd :* YI

    R = PA :* (1 :- ta) - (PVA :* iva + ica'*PQ + ctax*CPI :* efa)
    R = R \ (PA - PAc)
    if (pos[9]) R = R \ (PMG - sum(wmg :* PQ))
    if (nD) R = R \ ((QDs[iD] - QDd[iD]) :/ QD0[iD])
    for (f = 1; f <= nf; f++) {
        if (ft[f] == 1) R = R \ ((sum(Fd[f, .]) - FSbar[f])/FSbar[f])
        else if (ft[f] == 4) R = R \ ((sum(Fd[f, .]) - FSbar[f]*(1 - u0[f]*(W[f, 1]/CPI)^(-1/phiw[f]))/(1 - u0[f]))/FSbar[f])
        else if (ft[f] == 2) {
            idx = selectindex(Fbar[f, .] :> 0)
            R = R \ ((Fd[f, idx] - Fbar[f, idx]) :/ Fbar[f, idx])'
        }
    }
    bop = sum(pwm :* QM) + sum(trow) + sum(TRIR)/EXR + asarray(M, "trgr") - sum(pwe :* QE) -
          sum(trr) - asarray(M, "trrg") - sum(yfrow) - FSAV
    R = R \ (bop/scale)
    sav = sum(mpsv :* (1 :- tyv) :* YI) + GSAV + EXR*FSAV
    R = R \ ((sav - sum(PQ :* QINV) - sum(PQ :* qdst) - WAL)/invscale)
    if (pos[6]) {
        tgt = (asarray(M, "gshare") < . ? asarray(M, "gshare")*NGDP : asarray(M, "GSAV0")*CPI)
        R = R \ ((GSAV - tgt)/invscale)
    }
    R = R \ (CPI - asarray(M, "CPI0"))
    if (pos[10]) {
        ii = selectindex(asarray(M, "mquota") :< .)
        R = R \ _cgemod_fb(rm[ii], (asarray(M, "mquota")[ii] - QM[ii]) :/ QM0[ii])
    }
    if (pos[11]) {
        ii = selectindex(asarray(M, "xquota") :< .)
        R = R \ _cgemod_fb(rx[ii], (asarray(M, "xquota")[ii] - QE[ii]) :/ QE0[ii])
    }
    if (pos[12]) {
        ii = selectindex(asarray(M, "pcap") :< .)
        R = R \ _cgemod_fb(sc[ii], (asarray(M, "pcap")[ii] :* CPI - PQ[ii]) :/ PQ0[ii])
    }

    if (full) {
        asarray(O, "PD", PD)
        asarray(O, "X", X)
        asarray(O, "PA", PA)
        asarray(O, "XM", XM)
        asarray(O, "QHA", QHA)
        asarray(O, "EXR", EXR)
        asarray(O, "FSAV", FSAV)
        asarray(O, "IADJ", IADJ)
        asarray(O, "MPSADJ", MPSADJ)
        asarray(O, "TINSADJ", TINSADJ)
        asarray(O, "WAL", WAL)
        asarray(O, "W", W)
        asarray(O, "PE", PE)
        asarray(O, "PM", PM)
        asarray(O, "PX", PX)
        asarray(O, "PQ", PQ)
        asarray(O, "PVA", PVA)
        asarray(O, "Fd", Fd)
        asarray(O, "QX", QX)
        asarray(O, "QE", QE)
        asarray(O, "QD", QDs)
        asarray(O, "QM", QM)
        asarray(O, "QQ", QQ)
        asarray(O, "YF", YF)
        asarray(O, "CPI", CPI)
        asarray(O, "YI", YI)
        asarray(O, "YH", YI[|1 \ nh|])
        asarray(O, "EH", EH)
        asarray(O, "Cq", Cq)
        asarray(O, "QG", QG)
        asarray(O, "QINV", QINV)
        asarray(O, "YG", YG)
        asarray(O, "GSAV", GSAV)
        asarray(O, "VA", iva :* X)
        asarray(O, "R", R)
        asarray(O, "EMIS", EMIS)
        asarray(O, "CREV", CREV)
        asarray(O, "QREV", QREV)
        asarray(O, "SUBS", SUBS)
        asarray(O, "NGDP", NGDP)
        asarray(O, "rm", rm)
        asarray(O, "rx", rx)
        asarray(O, "sc", sc)
        asarray(O, "ADJ", adj)
        asarray(O, "U", u0 :* (W[., 1] :/ CPI) :^ (-1 :/ phiw) :* (ft :== 4))
    }
    return(R)
}

real matrix _cgemod_jac(real colvector z, transmorphic M, real colvector FF)
{
    real matrix Jac
    real colvector zz
    real scalar k, j, h
    transmorphic O
    O = asarray_create()
    k = rows(z)
    Jac = J(k, k, .)
    for (j = 1; j <= k; j++) {
        h = 1e-7*max((1, abs(z[j])))
        zz = z
        zz[j] = zz[j] + h
        Jac[., j] = (_cgemod_eval(zz, M, 0, O) - FF) :/ h
    }
    return(Jac)
}

real scalar _cgemod_solve(transmorphic M, real colvector z, real matrix it, real matrix nrm)
{
    real colvector FF, dz, zn, Fn, sv, yv
    real matrix Jac
    real scalar tol, maxit, lam, f0, ok, broy, fresh, nj
    transmorphic O
    O = asarray_create()
    tol = asarray(M, "tol")
    maxit = asarray(M, "maxit")
    broy = (asarray_contains(M, "solver") ? asarray(M, "solver") == 2 : 0)
    if (rows(z) < asarray(M, "pos")[8]) z = z \ J(asarray(M, "pos")[8] - rows(z), 1, 0)
    if (rows(z) > asarray(M, "pos")[8]) z = z[|1 \ asarray(M, "pos")[8]|]
    FF = _cgemod_eval(z, M, 0, O)
    fresh = 1
    nj = 0
    Jac = J(0, 0, .)
    for (it = 0; it <= maxit; it++) {
        if (hasmissing(FF)) {
            nrm = .
            return(3)
        }
        nrm = max(abs(FF))
        if (nrm < tol) {
            asarray(M, "njac", nj)
            return(0)
        }
        if (it == maxit) break
        if (!broy | rows(Jac) == 0) {
            Jac = _cgemod_jac(z, M, FF)
            nj++
            fresh = 1
        }
        dz = lusolve(Jac, -FF)
        if (hasmissing(dz)) dz = qrsolve(Jac, -FF)
        if (hasmissing(dz)) {
            if (broy & !fresh) {
                Jac = J(0, 0, .)
                continue
            }
            return(2)
        }
        lam = 1
        f0 = sum(FF :^ 2)
        ok = 0
        while (lam > 1e-6) {
            zn = z + lam*dz
            Fn = _cgemod_eval(zn, M, 0, O)
            if (!hasmissing(Fn)) {
                if (sum(Fn :^ 2) < (1 - 1e-4*lam)*f0) {
                    ok = 1
                    break
                }
            }
            lam = lam/2
        }
        if (!ok) {
            /* Broyden: rebuild the Jacobian once before giving up */
            if (broy & !fresh) {
                Jac = J(0, 0, .)
                continue
            }
            return(4)
        }
        if (broy) {
            sv = zn - z
            yv = Fn - FF
            Jac = Jac + ((yv - Jac*sv)*sv')/(sv'*sv)
            fresh = 0
        }
        z = zn
        FF = Fn
    }
    asarray(M, "njac", nj)
    return(1)
}

string scalar _cgemod_rcmsg(real scalar rc)
{
    if (rc == 1) return("iteration limit reached")
    if (rc == 2) return("singular Jacobian (check the closure and the SAM)")
    if (rc == 3) return("model could not be evaluated (non-positive prices or quantities)")
    if (rc == 4) return("line search failed (try a smaller shock or check the data)")
    return("")
}

/* --------------------------------------------------------------- results */
real rowvector _cgemod_macro(transmorphic M0, transmorphic O)
{
    real colvector PQ0, P0, pwe0, pwm0, QD0, VA, PVA, QG, QINV, QE, QM, PD, iD
    real matrix Cq
    real scalar PDI, EXR, nc, na, RCONS
    nc = asarray(M0, "nc")
    na = asarray(M0, "na")
    PQ0 = asarray(M0, "PQ0")
    P0 = PQ0 \ J(na, 1, 1)
    pwe0 = asarray(M0, "pwe0")
    pwm0 = asarray(M0, "pwm0")
    QD0 = asarray(M0, "QD0")
    iD = asarray(M0, "iD")
    VA = asarray(O, "VA")
    PVA = asarray(O, "PVA")
    Cq = asarray(O, "Cq")
    QG = asarray(O, "QG")
    QINV = asarray(O, "QINV")
    QE = asarray(O, "QE")
    QM = asarray(O, "QM")
    PD = asarray(O, "PD")
    EXR = asarray(O, "EXR")
    PDI = (rows(iD) ? sum(PD[iD] :* QD0[iD])/sum(QD0[iD]) : 1)
    RCONS = sum(P0 :* rowsum(Cq))
    return((sum(VA), sum(PVA :* VA), RCONS + sum(PQ0 :* (QG + QINV + asarray(M0, "qdst"))), RCONS,
            sum(PQ0 :* QINV), sum(PQ0 :* QG), sum(pwe0 :* QE), sum(pwm0 :* QM), EXR, asarray(O, "CPI"),
            PDI, EXR/PDI, asarray(O, "FSAV"), asarray(O, "GSAV"), asarray(O, "IADJ"), asarray(O, "MPSADJ"),
            (asarray(M0, "gclos") > 2 ? asarray(O, "ADJ") : asarray(O, "TINSADJ")), asarray(O, "WAL"),
            asarray(O, "EMIS"), asarray(O, "CREV"), asarray(O, "QREV"), asarray(O, "SUBS")))
}

real colvector _cgemod_ev(transmorphic M, transmorphic Ob, transmorphic Os)
{
    real matrix beta, gam
    real colvector Pb, Ps, EHb, EHs, out, b, gm, nz
    real scalar h, sup1
    beta = asarray(M, "beta")
    gam = asarray(M, "gam")
    Pb = asarray(Ob, "PQ") \ asarray(Ob, "PA")
    Ps = asarray(Os, "PQ") \ asarray(Os, "PA")
    EHb = asarray(Ob, "EH")
    EHs = asarray(Os, "EH")
    out = J(rows(EHb), 1, .)
    for (h = 1; h <= rows(EHb); h++) {
        b = beta[., h]
        gm = gam[., h]
        nz = selectindex(b :> 0)
        sup1 = EHs[h] - sum(Ps :* gm)
        out[h] = sup1*exp(sum(b[nz] :* ln(Pb[nz] :/ Ps[nz]))) + sum(Pb :* gm) - EHb[h]
    }
    return(out)
}

void _cgemod_post(string scalar name, real matrix X, string colvector rn, string rowvector cn)
{
    real scalar i
    string colvector r2
    string rowvector c2
    r2 = rn
    c2 = cn
    for (i = 1; i <= rows(r2); i++) r2[i] = strtoname(r2[i])
    for (i = 1; i <= cols(c2); i++) c2[i] = strtoname(c2[i])
    st_matrix(name, X)
    st_matrixrowstripe(name, (J(rows(r2), 1, ""), r2))
    st_matrixcolstripe(name, (J(cols(c2), 1, ""), c2'))
}

void _cgemod_report(transmorphic M0, transmorphic Ms, transmorphic Ob, transmorphic Os, string scalar title, real scalar show)
{
    real rowvector mb, ms
    real matrix Mac, Act, Com, Pri, Fac, Hh, Wb, Ws, Fdb, Fds, Cqb
    real colvector Pb, Ps, pind, rcons
    real scalar nm_, gcl
    real colvector ev, EH0
    real scalar na, nc, nf, nh, i, f, h, flag
    string rowvector act, com, fac, hh, mlab, mnm, fcl
    fcl = ("mobile", "specific", "unemp", "wagecurve")
    na = asarray(M0, "na")
    nc = asarray(M0, "nc")
    nf = asarray(M0, "nf")
    nh = asarray(M0, "nh")
    act = asarray(M0, "act")
    com = asarray(M0, "com")
    fac = asarray(M0, "fac")
    hh = asarray(M0, "hh")
    mb = _cgemod_macro(M0, Ob)
    ms = _cgemod_macro(M0, Os)
    mnm = ("RGDP", "NGDP", "RABS", "RCONS", "RINV", "RGOV", "REXP", "RIMP", "EXR", "CPI", "PDI", "RER",
           "FSAV", "GSAV", "IADJ", "MPSADJ", "FISCADJ", "WALRAS", "EMIS", "CREV", "QREV", "SUBS")
    mlab = ("Real GDP at factor cost", "Nominal GDP at factor cost", "Real absorption",
            "Real household consumption", "Real investment", "Real government consumption",
            "Real exports (world prices)", "Real imports (world prices)", "Exchange rate",
            "Consumer price index", "Domestic price index", "Real exchange rate",
            "Foreign savings (FCU)", "Government savings", "Investment scaling (IADJ)",
            "Savings-rate adjustment (MPSADJ)", "Direct-tax adjustment (TINSADJ)", "Walras check",
            "Emissions", "Carbon tax revenue", "Quota rents", "Price-cap subsidies")
    gcl = asarray(M0, "gclos")
    if (gcl == 3) mlab[17] = "Transfer scaling (TRADJ)"
    if (gcl == 4) mlab[17] = "Sales-tax point change (DTQ)"
    if (gcl == 5) mlab[17] = "Spending scaling (GADJ)"
    nm_ = cols(mnm)
    Mac = J(nm_, 3, .)
    for (i = 1; i <= nm_; i++) {
        Mac[i, 1] = mb[i]
        Mac[i, 2] = ms[i]
        Mac[i, 3] = (i <= 12 | i == 19 ? _cgemod_pch(mb[i], ms[i]) : ms[i] - mb[i])
    }
    Act = J(na, 4, .)
    for (i = 1; i <= na; i++) {
        Act[i, 1] = _cgemod_pch(asarray(Ob, "X")[i], asarray(Os, "X")[i])
        Act[i, 2] = _cgemod_pch(asarray(Ob, "VA")[i], asarray(Os, "VA")[i])
        Act[i, 3] = _cgemod_pch(asarray(Ob, "PA")[i], asarray(Os, "PA")[i])
        Act[i, 4] = _cgemod_pch(asarray(Ob, "XM")[i], asarray(Os, "XM")[i])
    }
    Com = J(nc, 5, .)
    Pri = J(nc, 5, .)
    for (i = 1; i <= nc; i++) {
        Com[i, 1] = _cgemod_pch(asarray(Ob, "QX")[i], asarray(Os, "QX")[i])
        Com[i, 2] = _cgemod_pch(asarray(Ob, "QD")[i], asarray(Os, "QD")[i])
        Com[i, 3] = _cgemod_pch(asarray(Ob, "QE")[i], asarray(Os, "QE")[i])
        Com[i, 4] = _cgemod_pch(asarray(Ob, "QM")[i], asarray(Os, "QM")[i])
        Com[i, 5] = _cgemod_pch(asarray(Ob, "QQ")[i], asarray(Os, "QQ")[i])
        Pri[i, 1] = (asarray(M0, "hasD")[i] ? _cgemod_pch(asarray(Ob, "PD")[i], asarray(Os, "PD")[i]) : .)
        Pri[i, 2] = (asarray(M0, "hasX")[i] ? _cgemod_pch(asarray(Ob, "PX")[i], asarray(Os, "PX")[i]) : .)
        Pri[i, 3] = _cgemod_pch(asarray(Ob, "PQ")[i], asarray(Os, "PQ")[i])
        Pri[i, 4] = (asarray(M0, "hasE")[i] ? _cgemod_pch(asarray(Ob, "PE")[i], asarray(Os, "PE")[i]) : .)
        Pri[i, 5] = (asarray(M0, "hasM")[i] ? _cgemod_pch(asarray(Ob, "PM")[i], asarray(Os, "PM")[i]) : .)
    }
    Wb = asarray(Ob, "W")
    Ws = asarray(Os, "W")
    Fdb = asarray(Ob, "Fd")
    Fds = asarray(Os, "Fd")
    Fac = J(nf, 5, .)
    for (f = 1; f <= nf; f++) {
        Fac[f, 5] = (asarray(M0, "factype")[f] == 4 ? 100*asarray(Os, "U")[f] : .)
        Fac[f, 1] = sum(Fdb[f, .])
        Fac[f, 2] = _cgemod_pch(sum(Fdb[f, .]), sum(Fds[f, .]))
        Fac[f, 3] = _cgemod_pch(sum(Wb[f, .] :* Fdb[f, .])/sum(Fdb[f, .]), sum(Ws[f, .] :* Fds[f, .])/sum(Fds[f, .]))
        Fac[f, 4] = _cgemod_pch(asarray(Ob, "YF")[f], asarray(Os, "YF")[f])
    }
    ev = _cgemod_ev(M0, Ob, Os)
    EH0 = asarray(Ob, "EH")
    Hh = J(nh, 4, .)
    for (h = 1; h <= nh; h++) {
        Hh[h, 1] = _cgemod_pch(asarray(Ob, "YH")[h], asarray(Os, "YH")[h])
        Hh[h, 2] = _cgemod_pch(EH0[h], asarray(Os, "EH")[h])
        Hh[h, 3] = ev[h]
        Hh[h, 4] = 100*ev[h]/EH0[h]
    }
    _cgemod_post("__cgemod_macro", Mac, mnm', ("base", "sim", "change"))
    _cgemod_post("__cgemod_sector", Act, act', ("X", "VA", "PA", "XM"))
    _cgemod_post("__cgemod_commodity", Com, com', ("QX", "QD", "QE", "QM", "QQ"))
    _cgemod_post("__cgemod_prices", Pri, com', ("PD", "PX", "PQ", "PE", "PM"))
    _cgemod_post("__cgemod_factor", Fac, fac', ("base_emp", "pct_emp", "pct_wage", "pct_income", "urate"))
    _cgemod_post("__cgemod_hh", Hh, hh', ("pct_income", "pct_cons", "EV", "EV_pct"))
    st_local("walras", strtrim(strofreal(ms[18], "%21.0g")))
    _cgemod_storelast(Mac, Act, Com, Pri, Fac, Hh, act, com, fac, hh, mnm)
    Pb = asarray(Ob, "PQ") \ asarray(Ob, "PA")
    Ps = asarray(Os, "PQ") \ asarray(Os, "PA")
    Cqb = asarray(Ob, "Cq")
    pind = J(nh, 1, .)
    rcons = J(nh, 1, .)
    for (h = 1; h <= nh; h++) {
        pind[h] = sum(Pb :* Cqb[., h] :* (Ps :/ Pb))/sum(Pb :* Cqb[., h])
        rcons[h] = 100*((asarray(Os, "EH")[h]/pind[h])/EH0[h] - 1)
    }
    _cgemod_storepov(hh, Hh[., 4], rcons, 100*(pind :- 1), Hh[., 2], fac, Fac[., 4], Fac[., 3], Mac[10, 3])
    if (!show) return
    printf("\n{txt}{hline 78}\n")
    printf("{txt}cgemod simulation%s\n", (title != "" ? ": {res}" + title : ""))
    printf("{txt}{hline 40}{c TT}{hline 37}\n")
    printf("{txt}%-40s{c |}%12s%12s%13s\n", "Macro indicator", "Benchmark", "Simulation", "% change")
    printf("{txt}{hline 40}{c +}{hline 37}\n")
    for (i = 1; i <= nm_; i++) {
        flag = (i > 12 & i != 19)
        if (i == 16 & asarray(M0, "siclos") == 1) continue
        if (i == 15 & asarray(M0, "siclos") == 2) continue
        if (i == 17 & asarray(M0, "gclos") == 1) continue
        if (i >= 19 & abs(Mac[i, 1]) + abs(Mac[i, 2]) == 0) continue
        printf("{txt}%-40s{c |}{res}%12.4f%12.4f%13.4f%s\n", mlab[i], Mac[i, 1], Mac[i, 2], Mac[i, 3], (flag ? "{txt} (lvl)" : ""))
    }
    printf("{txt}{hline 40}{c BT}{hline 37}\n")
    printf("{txt}(lvl) = change in level rather than %% change\n")
    printf("\n{txt}Activities (%% change from benchmark)\n")
    printf("{txt}{hline 16}{c TT}{hline 40}\n")
    printf("{txt}%-16s{c |}%10s%10s%10s%10s\n", "Activity", "Output", "VA", "Price", "Marketed")
    printf("{txt}{hline 16}{c +}{hline 40}\n")
    for (i = 1; i <= na; i++) {
        printf("{txt}%-16s{c |}{res}%10.3f%10.3f%10.3f%10.3f\n", abbrev(act[i], 16), Act[i, 1], Act[i, 2], Act[i, 3], Act[i, 4])
    }
    printf("{txt}{hline 16}{c BT}{hline 40}\n")
    printf("\n{txt}Commodities (%% change from benchmark): quantities\n")
    printf("{txt}{hline 16}{c TT}{hline 50}\n")
    printf("{txt}%-16s{c |}%10s%10s%10s%10s%10s\n", "Commodity", "Supply", "Domestic", "Exports", "Imports", "Absorpt.")
    printf("{txt}{hline 16}{c +}{hline 50}\n")
    for (i = 1; i <= nc; i++) {
        printf("{txt}%-16s{c |}{res}%10.3f%10.3f%10.3f%10.3f%10.3f\n", abbrev(com[i], 16),
               Com[i, 1], Com[i, 2], Com[i, 3], Com[i, 4], Com[i, 5])
    }
    printf("{txt}{hline 16}{c BT}{hline 50}\n")
    printf("\n{txt}Commodities (%% change from benchmark): prices\n")
    printf("{txt}{hline 16}{c TT}{hline 50}\n")
    printf("{txt}%-16s{c |}%10s%10s%10s%10s%10s\n", "Commodity", "Domestic", "Producer", "Composite", "Export", "Import")
    printf("{txt}{hline 16}{c +}{hline 50}\n")
    for (i = 1; i <= nc; i++) {
        printf("{txt}%-16s{c |}{res}%10.3f%10.3f%10.3f%10.3f%10.3f\n", abbrev(com[i], 16),
               Pri[i, 1], Pri[i, 2], Pri[i, 3], Pri[i, 4], Pri[i, 5])
    }
    printf("{txt}{hline 16}{c BT}{hline 50}\n")
    printf("\n{txt}Factor markets (%% change)\n")
    printf("{txt}{hline 16}{c TT}{hline 40}\n")
    printf("{txt}%-16s{c |}%10s%10s%10s%10s%10s\n", "Factor", "Closure", "Employ.", "Av. wage", "Income", "Unemp.%")
    printf("{txt}{hline 16}{c +}{hline 50}\n")
    for (f = 1; f <= nf; f++) {
        printf("{txt}%-16s{c |}%10s{res}%10.3f%10.3f%10.3f%10.3f\n", abbrev(fac[f], 16),
               fcl[asarray(M0, "factype")[f]], Fac[f, 2], Fac[f, 3], Fac[f, 4], Fac[f, 5])
    }
    printf("{txt}{hline 16}{c BT}{hline 50}\n")
    if (sum(asarray(Os, "rm") :> 1e-9) + sum(asarray(Os, "rx") :> 1e-9) + sum(asarray(Os, "sc") :> 1e-9)) {
        printf("\n{txt}Binding quantity and price constraints (rent or subsidy as a rate)\n")
        for (i = 1; i <= nc; i++) {
            if (asarray(Os, "rm")[i] > 1e-9) printf("{txt}   import quota on %-16s rent {res}%9.4f\n", com[i], asarray(Os, "rm")[i])
            if (asarray(Os, "rx")[i] > 1e-9) printf("{txt}   export quota on %-16s rent {res}%9.4f\n", com[i], asarray(Os, "rx")[i])
            if (asarray(Os, "sc")[i] > 1e-9) printf("{txt}   price cap on    %-16s subsidy {res}%9.4f\n", com[i], asarray(Os, "sc")[i])
        }
    }
    printf("\n{txt}Households\n")
    printf("{txt}{hline 16}{c TT}{hline 48}\n")
    printf("{txt}%-16s{c |}%12s%12s%12s%12s\n", "Household", "Income %", "Consump. %", "EV (level)", "EV % cons.")
    printf("{txt}{hline 16}{c +}{hline 48}\n")
    for (h = 1; h <= nh; h++) {
        printf("{txt}%-16s{c |}{res}%12.3f%12.3f%12.4f%12.3f\n", abbrev(hh[h], 16), Hh[h, 1], Hh[h, 2], Hh[h, 3], Hh[h, 4])
    }
    printf("{txt}{hline 16}{c BT}{hline 48}\n")
    printf("{txt}EV = Hicksian equivalent variation in benchmark prices (positive = welfare gain)\n")
}

void _cgemod_sim()
{
    transmorphic M0, B, Ob, Os
    real colvector z
    real scalar rc, it, nrm
    M0 = *findexternal("_cgemod_M")
    B = _cgemod_copy(M0)
    if (!_cgemod_applyshocks(B)) printf("{txt}note: no shock specified; the simulation reproduces the benchmark\n")
    z = asarray(M0, "zbase")
    rc = _cgemod_solve(B, z, it, nrm)
    if (rc) {
        errprintf("cgemod sim: solver failed: %s (largest residual %g)\n", _cgemod_rcmsg(rc), nrm)
        exit(430)
    }
    Ob = asarray_create()
    Os = asarray_create()
    (void) _cgemod_eval(asarray(M0, "zbase"), M0, 1, Ob)
    (void) _cgemod_eval(z, B, 1, Os)
    st_local("iter", strofreal(it))
    st_local("njac", strofreal(asarray(B, "njac")))
    st_local("maxres", strtrim(strofreal(nrm, "%21.0g")))
    printf("{txt}solver converged in {res}%g{txt} %s iterations (largest residual %9.2e)\n", it,
           (asarray(B, "solver") == 2 ? "Broyden" : "Newton"), nrm)
    _cgemod_report(M0, B, Ob, Os, st_local("title"), st_local("table") == "")
}

/* -------------------------------------------------------------- describe */
void _cgemod_describe()
{
    transmorphic M
    real scalar na, nc, nf, i, f
    real colvector X0, VA0, QX0, QE0, QM0, QQ0, HQ
    string rowvector act, com, fac, cl, fcl, gcl, scl
    fcl = ("mobile", "sector-specific", "unemployed", "wage curve")
    gcl = ("flexible government savings", "fixed government savings (direct-tax rates adjust)",
           "fixed government savings (transfers adjust)", "fixed government savings (sales-tax rates adjust)",
           "fixed government savings (government spending adjusts)")
    scl = ("savings-driven investment", "investment-driven (savings rates adjust)")
    cl = ("flexible exchange rate, fixed foreign savings", "fixed exchange rate, flexible foreign savings")
    M = *findexternal("_cgemod_M")
    na = asarray(M, "na")
    nc = asarray(M, "nc")
    nf = asarray(M, "nf")
    act = asarray(M, "act")
    com = asarray(M, "com")
    fac = asarray(M, "fac")
    X0 = asarray(M, "X0")
    VA0 = asarray(M, "VA0")
    QX0 = asarray(M, "QX0")
    QE0 = asarray(M, "QE0")
    QM0 = asarray(M, "QM0")
    QQ0 = asarray(M, "QQ0")
    HQ = X0 - asarray(M, "XM0")
    printf("\n{txt}Benchmark structure: activities\n")
    printf("{txt}{hline 16}{c TT}{hline 42}\n")
    printf("{txt}%-16s{c |}%7s%7s%7s%7s%7s%7s\n", "Activity", "X sh%", "VA sh%", "Home%", "Prods", "ta", "sigVA")
    printf("{txt}{hline 16}{c +}{hline 42}\n")
    for (i = 1; i <= na; i++) {
        printf("{txt}%-16s{c |}{res}%7.1f%7.1f%7.1f%7.0f%7.3f%7.2f\n", abbrev(act[i], 16), 100*X0[i]/sum(X0),
               100*VA0[i]/sum(VA0), 100*HQ[i]/X0[i], sum(asarray(M, "MAKE0")[i, .] :> 0), asarray(M, "ta")[i],
               asarray(M, "sigva")[i])
    }
    printf("{txt}{hline 16}{c BT}{hline 42}\n")
    printf("\n{txt}Benchmark structure: commodities\n")
    printf("{txt}{hline 16}{c TT}{hline 61}\n")
    printf("{txt}%-16s{c |}%7s%7s%7s%7s%7s%7s%7s%7s\n", "Commodity", "Exp%X", "Imp%Q", "tq", "tm", "marg.", "sigQ", "omega", "sigX")
    printf("{txt}{hline 16}{c +}{hline 61}\n")
    for (i = 1; i <= nc; i++) {
        printf("{txt}%-16s{c |}{res}%7.1f%7.1f%7.3f%7.3f%7.3f%7.2f%7.2f%7.2f\n", abbrev(com[i], 16),
               (QX0[i] > 0 ? 100*QE0[i]/QX0[i] : 0), (QQ0[i] > 0 ? 100*QM0[i]/QQ0[i] : 0),
               asarray(M, "tq")[i], asarray(M, "tm")[i], asarray(M, "mr")[i], asarray(M, "sigq")[i],
               asarray(M, "omega")[i], asarray(M, "sigx")[i])
    }
    printf("{txt}{hline 16}{c BT}{hline 61}\n")
    printf("{txt}Factor markets: ")
    for (f = 1; f <= nf; f++) printf("{res}%s{txt} (%s)%s", fac[f], fcl[asarray(M, "factype")[f]], (f < nf ? ", " : ""))
    printf("\n")
    printf("{txt}Closures: %s; ", cl[asarray(M, "ext")])
    printf("%s; ", gcl[asarray(M, "gclos")])
    printf("%s\n", scl[asarray(M, "siclos")])
    printf("{txt}Institutions: %s; household demand: %s; numeraire: consumer price index\n", invtokens(asarray(M, "ins")),
           (asarray(M, "frisch") == -1 & max(abs(asarray(M, "eta") :- 1)) < 1e-12 ? "Cobb-Douglas" :
            "linear expenditure system (Frisch " + strofreal(asarray(M, "frisch")) + ")"))
}

/* --------------------------------------------------------------- dynamic */


real scalar _cgemod_dyngap(transmorphic M, real colvector z, real colvector tbase, real scalar th, real scalar target)
{
    real colvector zz
    real scalar rc, it, nrm
    transmorphic O
    asarray(M, "tfp", tbase :* th)
    zz = z
    rc = _cgemod_solve(M, zz, it, nrm)
    if (rc) return(.)
    O = asarray_create()
    (void) _cgemod_eval(zz, M, 1, O)
    z = zz
    return(sum(asarray(O, "VA"))/target - 1)
}

void _cgemod_dynshock(transmorphic M, transmorphic M0, transmorphic D, real scalar NGDP0)
{
    real colvector q0
    (void) _cgemod_applyshocks(M)
    if (asarray(D, "pubinv") != 0) {
        q0 = asarray(M0, "qinv0")
        asarray(M, "qinvx", q0 :/ sum(asarray(M0, "PQ0") :* q0) :* (asarray(D, "pubinv")*NGDP0))
    }
}

real matrix _cgemod_dynpath(transmorphic M0, transmorphic D, real scalar pol, real matrix th, real matrix PCC,
    real matrix PQp, real matrix EHp)
{
    transmorphic M, O, Ob
    real matrix SK, LS, Wm, Fdm, res, gam0, Cqb, Fb
    real colvector z, ft, YF0, PQ0, ksh, gl, ga, gp, pop0, pop, tfpg, eta, pubm, trg0, tr, tfp0, tfpsh, qglev
    real colvector Pb, Ps, EH0b, FS, tb
    real rowvector li, ci, edul, Wf, Fdf, kap, sh, nzr, mrow
    real scalar T, st, n, nf, nh, per, j, f, h, RINV, RINV0, NGDP0, newk, Ravg, rc, it, nrm, debt, KG, KG0, KE, KE0
    real scalar ie, tfpx, qgsc, eff, gdpg, target, th0, th1, th2, f0, f1, k, d, rr, mob, pubsh, pubdep, edudep, etae, e, pind
    M = _cgemod_copy(M0)
    n = asarray(M, "na")
    nf = asarray(M, "nf")
    nh = asarray(M, "nh")
    ft = asarray(M, "factype")
    YF0 = asarray(M, "YF0")
    PQ0 = asarray(M, "PQ0")
    T = asarray(D, "T")
    st = asarray(D, "st")
    li = asarray(D, "li")
    ci = asarray(D, "ci")
    gl = asarray(D, "gl")
    ga = asarray(D, "ga")
    gp = asarray(D, "gp")
    pop0 = asarray(D, "pop0")
    eta = asarray(D, "eta")
    edul = asarray(D, "edul")
    ie = asarray(D, "ie")
    d = asarray(D, "d")
    rr = asarray(D, "rr")
    mob = asarray(D, "mob")
    pubsh = asarray(D, "pubsh")
    pubdep = asarray(D, "pubdep")
    edudep = asarray(D, "edudep")
    etae = asarray(D, "etae")
    gdpg = asarray(D, "gdpg")
    gam0 = asarray(M0, "gam")
    trg0 = asarray(M0, "trg")
    tfp0 = asarray(M0, "tfp")
    Ob = asarray_create()
    (void) _cgemod_eval(asarray(M0, "zbase"), M0, 1, Ob)
    RINV0 = sum(PQ0 :* asarray(Ob, "QINV"))
    NGDP0 = asarray(Ob, "NGDP")
    if (pol & st == 0) _cgemod_dynshock(M, M0, D, NGDP0)
    qglev = asarray(M, "qg0")
    tfpsh = asarray(M, "tfp") :/ tfp0
    SK = J(nf, n, 0)
    LS = J(nf, n, 0)
    for (f = 1; f <= nf; f++) {
        if (ft[f] == 2) LS[f, .] = asarray(M, "Fbar")[f, .]
        else LS[f, 1] = asarray(M, "FSbar")[f]
    }
    for (j = 1; j <= cols(ci); j++) {
        f = ci[j]
        SK[f, .] = LS[f, .] :/ (rr + d)
    }
    ksh = J(0, 1, .)
    if (cols(ci)) {
        ksh = YF0[ci]
        ksh = ksh :/ sum(ksh)
    }
    KG0 = (pubsh > 0 ? pubsh*RINV0/pubdep : 0)
    KG = KG0
    KE0 = (ie ? PQ0[ie]*asarray(Ob, "QG")[ie]/edudep : 0)
    KE = KE0
    pop = J(nh, 1, 1)
    tfpg = J(n, 1, 1)
    qgsc = 1
    tfpx = 1
    debt = asarray(D, "debt0")
    Pb = asarray(Ob, "PQ") \ asarray(Ob, "PA")
    Cqb = asarray(Ob, "Cq")
    EH0b = asarray(Ob, "EH")
    z = asarray(M0, "zbase")
    res = J(T + 1, 18 + nf + n, .)
    PCC = J(T + 1, nh, .)
    PQp = J(T + 1, n + asarray(M, "nc"), .)
    EHp = J(T + 1, nh, .)
    if (!pol) th = J(T + 1, 1, 1)
    O = Ob
    for (per = 0; per <= T; per++) {
        if (per > 0) {
            if (pol & per == st) {
                told = asarray(M, "tfp")
                qold = asarray(M, "qg0")
                _cgemod_dynshock(M, M0, D, NGDP0)
                tfpsh = tfpsh :* (asarray(M, "tfp") :/ told)
                qglev = qglev :* editmissing(asarray(M, "qg0") :/ qold, 1)
            }
            for (j = 1; j <= cols(li); j++) {
                f = li[j]
                LS[f, .] = LS[f, .] :* (1 + gl[f])
            }
            RINV = sum(PQ0 :* asarray(O, "QINV"))
            Wm = asarray(O, "W")
            Fdm = asarray(O, "Fd")
            for (j = 1; j <= cols(ci); j++) {
                f = ci[j]
                newk = ksh[j]*RINV
                if (ft[f] == 2) {
                    Wf = Wm[f, .]
                    Fdf = Fdm[f, .]
                    nzr = (LS[f, .] :> 0)
                    kap = (Wf :* Fdf) :/ sum(Wf :* Fdf)
                    Ravg = sum(Wf :* Fdf)/sum(Fdf)
                    sh = nzr :* kap :* (1 :+ mob :* (Wf :/ Ravg :- 1))
                    sh = sh :* (sh :> 0)
                    sh = sh :/ sum(sh)
                    SK[f, .] = (1 - d) :* SK[f, .] + sh :* newk
                    LS[f, .] = SK[f, .] :* (rr + d)
                }
                else {
                    SK[f, 1] = (1 - d)*SK[f, 1] + newk
                    LS[f, 1] = SK[f, 1]*(rr + d)
                }
            }
            if (KG0 > 0) KG = (1 - pubdep)*KG + pubsh*RINV + sum(PQ0 :* asarray(M, "qinvx"))
            if (ie) KE = (1 - edudep)*KE + PQ0[ie]*asarray(O, "QG")[ie]
            tfpg = tfpg :* (1 :+ ga)
            pop = pop :* (1 :+ gp)
            qgsc = qgsc*(1 + asarray(D, "gg"))
            asarray(M, "FSAVbar", asarray(M, "FSAVbar")*(1 + asarray(D, "gfs")))
        }
        eff = (KE0 > 0 ? (KE/KE0)^etae : 1)
        Fb = asarray(M, "Fbar")
        FS = asarray(M, "FSbar")
        for (f = 1; f <= nf; f++) {
            e = (_cgemod_in(edul, f) ? eff : 1)
            if (ft[f] == 2) Fb[f, .] = LS[f, .] :* e
            else FS[f] = LS[f, 1]*e
        }
        asarray(M, "Fbar", Fb)
        asarray(M, "FSbar", FS)
        pubm = (KG0 > 0 ? (KG/KG0) :^ eta : J(n, 1, 1))
        asarray(M, "gam", gam0 :* (pop'))
        tr = trg0
        tr[|1 \ nh|] = trg0[|1 \ nh|] :* pop
        asarray(M, "trg", tr)
        asarray(M, "qg0", qglev :* qgsc)
        tb = tfp0 :* tfpsh :* tfpg :* pubm
        if (!pol & gdpg < . & per > 0) {
            target = res[1, 2]*(1 + gdpg)^per
            th0 = tfpx
            th1 = tfpx*(1 + gdpg)
            f0 = _cgemod_dyngap(M, z, tb, th0, target)
            f1 = _cgemod_dyngap(M, z, tb, th1, target)
            for (k = 1; k <= 30; k++) {
                if (f0 >= . | f1 >= .) {
                    errprintf("cgemod dynamic: the GDP growth target could not be reached in period %g\n", per)
                    exit(430)
                }
                if (abs(f1) < 1e-11) break
                th2 = th1 - f1*(th1 - th0)/(f1 - f0)
                th0 = th1
                f0 = f1
                th1 = th2
                f1 = _cgemod_dyngap(M, z, tb, th1, target)
            }
            tfpx = th1
            th[per + 1] = tfpx
        }
        else if (pol) tfpx = th[per + 1]
        asarray(M, "tfp", tb :* tfpx)
        rc = _cgemod_solve(M, z, it, nrm)
        if (rc) {
            errprintf("cgemod dynamic: solver failed in period %g of the %s path: %s\n", per,
                      (pol ? "policy" : "baseline"), _cgemod_rcmsg(rc))
            exit(430)
        }
        O = asarray_create()
        (void) _cgemod_eval(z, M, 1, O)
        if (per > 0) debt = debt - asarray(O, "GSAV")
        mrow = _cgemod_macro(M0, O)
        res[per + 1, .] = (per, mrow[1], mrow[3], mrow[4], mrow[5], mrow[7], mrow[8], mrow[9], mrow[10],
                           rowsum(asarray(O, "Fd"))', asarray(O, "X")', asarray(O, "GSAV"), debt,
                           100*debt/asarray(O, "NGDP"), sum(pop0 :* pop)/sum(pop0),
                           mrow[1]/(sum(pop0 :* pop)/sum(pop0)), asarray(O, "EMIS"), KG, KE, tfpx)
        Ps = asarray(O, "PQ") \ asarray(O, "PA")
        for (h = 1; h <= nh; h++) {
            pind = sum(Pb :* Cqb[., h] :* (Ps :/ Pb))/sum(Pb :* Cqb[., h])
            PCC[per + 1, h] = (asarray(O, "EH")[h]/pind/pop[h])/EH0b[h]
        }
        PQp[per + 1, .] = Ps'
        EHp[per + 1, .] = asarray(O, "EH")'
    }
    return(res)
}

void _cgemod_dyn()
{
    transmorphic M0, D, P
    real matrix Bp, Pp, Dv, PQb, PQs, EHb, EHs, beta, gam, PCb, PCp
    real colvector th
    real rowvector li, ci, edul, lvl
    real scalar T, per, j, h, sup1, evt, ie, nf
    string rowvector fac, act, com, hh, cn
    pointer() scalar p
    M0 = *findexternal("_cgemod_M")
    fac = asarray(M0, "fac")
    act = asarray(M0, "act")
    com = asarray(M0, "com")
    hh = asarray(M0, "hh")
    nf = asarray(M0, "nf")
    T = strtoreal(st_local("periods"))
    li = J(1, 0, .)
    ci = J(1, 0, .)
    edul = J(1, 0, .)
    if (strtrim(st_local("labor")) != "") li = _cgemod_ix(tokens(st_local("labor")), fac, "labor")
    if (strtrim(st_local("capital")) != "") ci = _cgemod_ix(tokens(st_local("capital")), fac, "capital")
    if (strtrim(st_local("edulabor")) != "") edul = _cgemod_ix(tokens(st_local("edulabor")), fac, "edulabor")
    for (j = 1; j <= cols(ci); j++) {
        if (asarray(M0, "factype")[ci[j]] == 3 | asarray(M0, "factype")[ci[j]] == 4) {
            errprintf("capital factor %s cannot have an unemployment or wage-curve closure\n", fac[ci[j]])
            exit(198)
        }
    }
    ie = 0
    if (strtrim(st_local("educom")) != "") {
        ie = _cgemod_find(strtrim(st_local("educom")), com, J(1, 0, ""))
        if (!ie) {
            errprintf("educom(): %s is not a commodity\n", st_local("educom"))
            exit(111)
        }
        if (asarray(M0, "qg0")[ie] <= 0) {
            errprintf("educom(): the government does not buy %s in the SAM\n", st_local("educom"))
            exit(459)
        }
    }
    D = asarray_create()
    asarray(D, "T", T)
    asarray(D, "st", strtoreal(st_local("start")))
    asarray(D, "li", li)
    asarray(D, "ci", ci)
    asarray(D, "edul", edul)
    asarray(D, "ie", ie)
    asarray(D, "gl", _cgemod_pvec(st_local("lgrowth"), fac, J(1, 0, ""), 0, "lgrowth"))
    asarray(D, "ga", _cgemod_pvec(st_local("tfpgrowth"), act, J(1, 0, ""), 0, "tfpgrowth"))
    asarray(D, "gp", _cgemod_pvec(st_local("popgrowth"), hh, J(1, 0, ""), 0, "popgrowth"))
    asarray(D, "pop0", (strtrim(st_local("population")) != "" ? _cgemod_pvec(st_local("population"), hh, J(1, 0, ""), ., "population") :
                        asarray(M0, "EH0")))
    if (hasmissing(asarray(D, "pop0"))) {
        errprintf("population(): give the benchmark population of every household group\n")
        exit(198)
    }
    asarray(D, "eta", _cgemod_pvec(st_local("pubelas"), act, J(1, 0, ""), 0, "pubelas"))
    asarray(D, "d", strtoreal(st_local("deprec")))
    asarray(D, "rr", strtoreal(st_local("rate")))
    asarray(D, "mob", strtoreal(st_local("mobility")))
    asarray(D, "debt0", strtoreal(st_local("debt0")))
    asarray(D, "gdpg", (strtrim(st_local("gdpgrowth")) != "" ? strtoreal(st_local("gdpgrowth")) : .))
    asarray(D, "gg", strtoreal(st_local("ggrowth")))
    asarray(D, "gfs", strtoreal(st_local("fsavgrowth")))
    asarray(D, "pubsh", strtoreal(st_local("pubshare")))
    asarray(D, "pubdep", strtoreal(st_local("pubdep")))
    asarray(D, "pubinv", strtoreal(st_local("pubinv")))
    asarray(D, "edudep", strtoreal(st_local("edudep")))
    asarray(D, "etae", strtoreal(st_local("eduelas")))
    if (asarray(D, "pubinv") != 0 & asarray(D, "pubsh") <= 0) {
        printf("{txt}note: pubinv() without pubshare() adds public spending but no public capital effect on productivity\n")
    }
    Bp = _cgemod_dynpath(M0, D, 0, th, PCb, PQb, EHb)
    Pp = _cgemod_dynpath(M0, D, 1, th, PCp, PQs, EHs)
    Dv = J(T + 1, cols(Bp) + 1, .)
    beta = asarray(M0, "beta")
    gam = asarray(M0, "gam")
    lvl = (cols(Bp) - 8, cols(Bp) - 7, cols(Bp) - 6)
    for (per = 1; per <= T + 1; per++) {
        Dv[per, 1] = Bp[per, 1]
        for (j = 2; j <= cols(Bp); j++) Dv[per, j] = (_cgemod_in(lvl, j) ? Pp[per, j] - Bp[per, j] : _cgemod_pch(Bp[per, j], Pp[per, j]))
        evt = 0
        for (h = 1; h <= cols(EHb); h++) {
            sup1 = EHs[per, h] - sum(PQs[per, .] :* gam[., h]')
            evt = evt + sup1*exp(sum(beta[., h]' :* ln(PQb[per, .] :/ PQs[per, .]))) + sum(PQb[per, .] :* gam[., h]') - EHb[per, h]
        }
        Dv[per, cols(Dv)] = evt
    }
    cn = ("t", "RGDP", "RABS", "RCONS", "RINV", "REXP", "RIMP", "EXR", "CPI")
    for (j = 1; j <= cols(fac); j++) cn = (cn, substr("FS_" + fac[j], 1, 32))
    for (j = 1; j <= cols(act); j++) cn = (cn, substr("X_" + act[j], 1, 32))
    cn = (cn, "GSAV", "DEBT", "DEBTGDP", "POP", "RGDPPC", "EMIS", "KG", "KE", "TFPX")
    _cgemod_post("__cgemod_dynbase", Bp, strofreal(Bp[., 1]), cn)
    _cgemod_post("__cgemod_dynpol", Pp, strofreal(Pp[., 1]), cn)
    _cgemod_post("__cgemod_dyndev", Dv, strofreal(Dv[., 1]), (cn, "EV"))
    st_matrixrowstripe("__cgemod_dynbase", (J(T + 1, 1, ""), "t" :+ strofreal(Bp[., 1])))
    st_matrixrowstripe("__cgemod_dynpol", (J(T + 1, 1, ""), "t" :+ strofreal(Bp[., 1])))
    st_matrixrowstripe("__cgemod_dyndev", (J(T + 1, 1, ""), "t" :+ strofreal(Bp[., 1])))
    P = asarray_create()
    asarray(P, "hh", hh)
    asarray(P, "base", PCb)
    asarray(P, "policy", PCp)
    p = findexternal("_cgemod_dynpov")
    if (p == NULL) p = crexternal("_cgemod_dynpov")
    *p = P
    if (st_local("table") != "") return
    printf("\n{txt}cgemod recursive-dynamic simulation: %g periods, shock from period %g\n", T, asarray(D, "st"))
    if (asarray(D, "gdpg") < .) printf("{txt}baseline calibrated to real GDP growth of %g per period (productivity solved each period)\n", asarray(D, "gdpg"))
    printf("{txt}{hline 6}{c TT}{hline 71}\n")
    printf("{txt}%6s{c |}%12s%12s%9s%9s%9s%9s%11s\n", "t", "RGDP base", "RGDP pol.", "RGDP %", "RABS %", "RCONS %", "RINV %", "EV")
    printf("{txt}{hline 6}{c +}{hline 71}\n")
    for (per = 1; per <= T + 1; per++) {
        printf("{txt}%6.0f{c |}{res}%12.3f%12.3f%9.3f%9.3f%9.3f%9.3f%11.4f\n", Bp[per, 1], Bp[per, 2], Pp[per, 2],
               Dv[per, 2], Dv[per, 3], Dv[per, 4], Dv[per, 5], Dv[per, cols(Dv)])
    }
    printf("{txt}{hline 6}{c BT}{hline 71}\n")
    printf("{txt}%% = deviation of the policy path from the baseline path; EV in benchmark prices\n")
    printf("{txt}baseline in the last period: population index %9.4f, GDP per capita index %9.4f, debt/GDP %8.2f%%\n",
           Bp[T + 1, cols(Bp) - 5], Bp[T + 1, cols(Bp) - 4]/Bp[1, cols(Bp) - 4], Bp[T + 1, cols(Bp) - 6])
}

/* ------------------------------------------------------------------- SSA */
string scalar _cgemod_ekey(string scalar e)
{
    if (e == "sigmava") return("sigva")
    if (e == "sigmaq") return("sigq")
    if (e == "sigmax") return("sigx")
    return("omega")
}

real matrix _cgemod_stroud(real scalar k)
{
    real matrix P
    real scalar j, r
    P = J(2*k, k, 0)
    for (j = 1; j <= 2*k; j++) {
        for (r = 1; r <= floor(k/2); r++) {
            P[j, 2*r - 1] = sqrt(2)*cos((2*r - 1)*j*pi()/k)
            P[j, 2*r] = sqrt(2)*sin((2*r - 1)*j*pi()/k)
        }
        if (mod(k, 2) == 1) P[j, k] = (-1)^j
    }
    return(P)
}

real rowvector _cgemod_ssares(transmorphic M0, transmorphic Ob, transmorphic Os)
{
    real rowvector mb, ms, out
    real colvector ev
    real scalar i, n
    mb = _cgemod_macro(M0, Ob)
    ms = _cgemod_macro(M0, Os)
    n = asarray(M0, "na")
    out = J(1, 8, .)
    out[1] = _cgemod_pch(mb[1], ms[1])
    out[2] = _cgemod_pch(mb[3], ms[3])
    out[3] = _cgemod_pch(mb[4], ms[4])
    out[4] = _cgemod_pch(mb[5], ms[5])
    out[5] = _cgemod_pch(mb[7], ms[7])
    out[6] = _cgemod_pch(mb[8], ms[8])
    out[7] = _cgemod_pch(mb[9], ms[9])
    out[8] = _cgemod_pch(mb[10], ms[10])
    for (i = 1; i <= n; i++) out = (out, _cgemod_pch(asarray(Ob, "X")[i], asarray(Os, "X")[i]))
    ev = _cgemod_ev(M0, Ob, Os)
    out = (out, ev')
    return(out)
}

void _cgemod_ssa()
{
    transmorphic M0, B, Ob, Os
    string rowvector els, lab, act, com, hh, scol
    string scalar dist, meth
    real scalar n, ncm, nh, k, i, j, e, q, rng, sdv, reps, bys, nd, rc, it, nrm, nfail, pos, fr
    real matrix P, D, Res, Stat
    real colvector z, v, res0c
    real rowvector res0, np, col, srt
    M0 = *findexternal("_cgemod_M")
    n = asarray(M0, "na")
    ncm = asarray(M0, "nc")
    com = asarray(M0, "com")
    nh = asarray(M0, "nh")
    act = asarray(M0, "act")
    hh = asarray(M0, "hh")
    els = tokens(st_local("elasticities"))
    rng = strtoreal(st_local("range"))
    dist = st_local("distribution")
    meth = st_local("method")
    reps = strtoreal(st_local("reps"))
    bys = (st_local("bysector") != "")
    np = J(1, cols(els), 1)
    for (e = 1; e <= cols(els); e++) if (bys & els[e] != "frisch") np[e] = (els[e] == "sigmava" ? n : ncm)
    k = sum(np)
    if (dist == "uniform") sdv = rng/sqrt(3)
    else if (dist == "triangular") sdv = rng/sqrt(6)
    else sdv = rng/2
    if (meth == "quadrature") {
        P = _cgemod_stroud(k) :* sdv
        if (min(P) <= -0.99) {
            errprintf("range() too wide for quadrature with %g parameters: an elasticity would become non-positive\n", k)
            exit(198)
        }
    }
    else {
        if (dist == "uniform") P = (2 :* runiform(reps, k) :- 1) :* rng
        else if (dist == "triangular") P = (runiform(reps, k) - runiform(reps, k)) :* rng
        else {
            P = rnormal(reps, k, 0, sdv)
            P = P :* (P :> -0.95) + (-0.95) :* (P :<= -0.95)
        }
    }
    nd = rows(P)
    Ob = asarray_create()
    (void) _cgemod_eval(asarray(M0, "zbase"), M0, 1, Ob)
    /* point estimate */
    B = _cgemod_copy(M0)
    if (!_cgemod_applyshocks(B)) {
        errprintf("cgemod ssa: specify the shock to analyse (same options as cgemod sim)\n")
        exit(198)
    }
    z = asarray(M0, "zbase")
    rc = _cgemod_solve(B, z, it, nrm)
    if (rc) {
        errprintf("cgemod ssa: the central simulation failed: %s\n", _cgemod_rcmsg(rc))
        exit(430)
    }
    Os = asarray_create()
    (void) _cgemod_eval(z, B, 1, Os)
    res0 = _cgemod_ssares(M0, Ob, Os)
    Res = J(nd, cols(res0), .)
    nfail = 0
    printf("{txt}running %g sensitivity solutions (%s, %s, range +/-%g%%, %g parameter%s)\n", nd,
           meth, dist, 100*rng, k, (k > 1 ? "s" : ""))
    for (q = 1; q <= nd; q++) {
        B = _cgemod_copy(M0)
        pos = 0
        for (e = 1; e <= cols(els); e++) {
            if (els[e] == "frisch") {
                pos++
                fr = asarray(M0, "frisch")*(1 + P[q, pos])
                asarray(B, "gam", asarray(M0, "Cq0") + (asarray(M0, "beta") :* (asarray(M0, "EH0")')) :/ ((asarray(M0, "PQ0") \ J(asarray(M0, "na"), 1, 1)) :* fr))
            }
            else {
                v = asarray(M0, _cgemod_ekey(els[e]))
                if (np[e] == 1) {
                    pos++
                    v = v :* (1 + P[q, pos])
                }
                else {
                    for (j = 1; j <= np[e]; j++) {
                        pos++
                        v[j] = v[j]*(1 + P[q, pos])
                    }
                }
                asarray(B, _cgemod_ekey(els[e]), v)
            }
        }
        (void) _cgemod_applyshocks(B)
        z = asarray(M0, "zbase")
        rc = _cgemod_solve(B, z, it, nrm)
        if (rc) {
            nfail++
            continue
        }
        Os = asarray_create()
        (void) _cgemod_eval(z, B, 1, Os)
        Res[q, .] = _cgemod_ssares(M0, Ob, Os)
    }
    lab = ("Real GDP %", "Real absorption %", "Real consumption %", "Real investment %",
           "Real exports %", "Real imports %", "Exchange rate %", "CPI %")
    for (i = 1; i <= n; i++) lab = (lab, "Output " + act[i] + " %")
    for (i = 1; i <= nh; i++) lab = (lab, "EV " + hh[i])
    Stat = J(cols(res0), 8, .)
    for (i = 1; i <= cols(res0); i++) {
        col = select(Res[., i], Res[., i] :< .)'
        if (cols(col) == 0) continue
        Stat[i, 1] = res0[i]
        Stat[i, 2] = mean(col')
        Stat[i, 3] = (cols(col) > 1 ? sqrt(sum((col :- Stat[i, 2]) :^ 2)/cols(col)) : 0)
        Stat[i, 4] = min(col)
        Stat[i, 5] = max(col)
        if (meth == "quadrature") {
            Stat[i, 6] = Stat[i, 2] - 1.96*Stat[i, 3]
            Stat[i, 7] = Stat[i, 2] + 1.96*Stat[i, 3]
        }
        else {
            srt = sort(col', 1)'
            Stat[i, 6] = srt[max((1, ceil(0.05*cols(srt))))]
            Stat[i, 7] = srt[max((1, ceil(0.95*cols(srt))))]
        }
        Stat[i, 8] = 100*mean((sign(col) :== sign(res0[i]))')
    }
    _cgemod_post("__cgemod_ssa", Stat, lab', ("point", "mean", "sd", "min", "max", "lower", "upper", "samesign"))
    st_matrix("__cgemod_ssadraws", (P, Res))
    st_matrixrowstripe("__cgemod_ssadraws", (J(nd, 1, ""), "d" :+ strofreal(1::nd)))
    scol = J(1, 0, "")
    pos = 0
    for (e = 1; e <= cols(els); e++) {
        if (np[e] == 1) scol = (scol, "u_" + els[e])
        else for (j = 1; j <= np[e]; j++) scol = (scol, substr("u_" + els[e] + "_" + (els[e] == "sigmava" ? act[j] : com[j]), 1, 32))
    }
    scol = (scol, "RGDP", "RABS", "RCONS", "RINV", "REXP", "RIMP", "EXR", "CPI")
    for (i = 1; i <= n; i++) scol = (scol, substr("X_" + act[i], 1, 32))
    for (i = 1; i <= nh; i++) scol = (scol, substr("EV_" + hh[i], 1, 32))
    for (i = 1; i <= cols(scol); i++) scol[i] = strtoname(scol[i])
    st_matrixcolstripe("__cgemod_ssadraws", (J(cols(scol), 1, ""), scol'))
    st_local("ndraws", strofreal(nd))
    st_local("nfail", strofreal(nfail))
    if (st_local("table") != "") return
    printf("\n{txt}Systematic sensitivity analysis (%s; elasticities: %s)\n", meth, invtokens(els))
    printf("{txt}{hline 26}{c TT}{hline 51}\n")
    printf("{txt}%-26s{c |}%9s%9s%9s%11s%11s%8s\n", "Result", "Point", "Mean", "Std.dev.",
           (meth == "quadrature" ? "Lower 95%" : "5th pct."), (meth == "quadrature" ? "Upper 95%" : "95th pct."), "Sign%")
    printf("{txt}{hline 26}{c +}{hline 51}\n")
    for (i = 1; i <= cols(res0); i++) {
        printf("{txt}%-26s{c |}{res}%9.3f%9.3f%9.3f%11.3f%11.3f%8.1f\n", abbrev(lab[i], 26), Stat[i, 1], Stat[i, 2],
               Stat[i, 3], Stat[i, 6], Stat[i, 7], Stat[i, 8])
    }
    printf("{txt}{hline 26}{c BT}{hline 51}\n")
    printf("{txt}Sign%% = share of draws with the same sign as the point estimate; %g failed solution(s)\n", nfail)
    if (meth == "quadrature") printf("{txt}Gaussian quadrature (Stroud degree-3, %g points) matches the first three moments of the elasticity distribution\n", nd)
}

/* ----------------------------------------------------------------- check */
/* ------------------------------------------------------ validation suite */
void _cgemod_vbackup(real scalar save)
{
    pointer() scalar p, q
    string rowvector ex
    real scalar j
    ex = ("_cgemod_M", "_cgemod_last", "_cgemod_pov")
    for (j = 1; j <= cols(ex); j++) {
        if (save) {
            p = findexternal(ex[j])
            q = findexternal(ex[j] + "_bk")
            if (q == NULL) q = crexternal(ex[j] + "_bk")
            *q = (p == NULL ? J(0, 0, .) : _cgemod_copy(*p))
            q = findexternal(ex[j] + "_bkx")
            if (q == NULL) q = crexternal(ex[j] + "_bkx")
            *q = (p != NULL)
        }
        else {
            q = findexternal(ex[j] + "_bkx")
            if (q == NULL) continue
            if (*q) {
                p = findexternal(ex[j])
                if (p == NULL) p = crexternal(ex[j])
                *p = *findexternal(ex[j] + "_bk")
            }
            else rmexternal(ex[j])
            rmexternal(ex[j] + "_bk")
            rmexternal(ex[j] + "_bkx")
        }
    }
}

void _cgemod_vcopyroles(string scalar from, string scalar to)
{
    pointer() scalar p
    p = findexternal("_cgemod_roles")
    if (p == NULL) return
    if (asarray_contains(*p, from)) asarray(*p, to, asarray(*p, from))
}

real scalar _cgemod_vsolve(transmorphic B, real colvector z, transmorphic O)
{
    real scalar rc, it, nrm
    rc = _cgemod_solve(B, z, it, nrm)
    if (rc == 0) (void) _cgemod_eval(z, B, 1, O)
    return(rc)
}

void _cgemod_vrow(string scalar test, string scalar val, string scalar crit, real scalar ok)
{
    pointer() scalar p
    p = findexternal("_cgemod_vtab")
    if (p == NULL) p = crexternal("_cgemod_vtab")
    if (rows(*p) == 0 | cols(*p) != 4) *p = J(0, 4, "")
    *p = *p \ (test, val, crit, (ok ? "pass" : "FAIL"))
}

void _cgemod_validate(real scalar steps)
{
    transmorphic M0, B, Ob, O1, O2, Bp, Bm
    pointer() scalar p
    real colvector z, z1, z2, X0, Xp, Xm, tm0, PDb
    real scalar rc, j, s, ok, wal, scale, npass, nfail, gap, hasM, hasE, hasT, cpi, dmax, asym, scl
    string rowvector lab
    M0 = *findexternal("_cgemod_M")
    p = findexternal("_cgemod_vtab")
    if (p == NULL) p = crexternal("_cgemod_vtab")
    *p = J(0, 4, "")
    scale = asarray(M0, "scale")
    hasM = sum(asarray(M0, "hasM")) > 0
    hasE = sum(asarray(M0, "hasE")) > 0
    hasT = max(abs(asarray(M0, "tm"))) > 0
    Ob = asarray_create()
    (void) _cgemod_eval(asarray(M0, "zbase"), M0, 1, Ob)
    /* 1. shock battery: convergence, Walras' law and the numeraire */
    lab = ("Import prices +10%", "Export prices +10%", "Tariffs removed", "Productivity +5%",
           "Government spending +10%", "Direct tax rates +2 points", "Foreign savings +10%")
    for (j = 1; j <= cols(lab); j++) {
        if (j == 1 & !hasM) continue
        if (j == 2 & !hasE) continue
        if (j == 3 & !hasT) continue
        B = _cgemod_copy(M0)
        if (j == 1) asarray(B, "pwm", asarray(M0, "pwm") :* 1.1)
        if (j == 2) asarray(B, "pwe", asarray(M0, "pwe") :* 1.1)
        if (j == 3) asarray(B, "tm", asarray(M0, "tm") :* 0)
        if (j == 4) asarray(B, "tfp", asarray(M0, "tfp") :* 1.05)
        if (j == 5) asarray(B, "gadj", asarray(M0, "gadj")*1.1)
        if (j == 6) asarray(B, "ty", asarray(M0, "ty") :+ 0.02 :* (asarray(M0, "ty") :> 0))
        if (j == 7) {
            if (asarray(M0, "ext") == 2 | abs(asarray(M0, "FSAVbar")) < 1e-12) continue
            asarray(B, "FSAVbar", asarray(M0, "FSAVbar")*1.1)
        }
        z = asarray(M0, "zbase")
        O1 = asarray_create()
        rc = _cgemod_vsolve(B, z, O1)
        if (rc) {
            _cgemod_vrow(lab[j], _cgemod_rcmsg(rc), "solves, Walras, CPI", 0)
            continue
        }
        wal = abs(asarray(O1, "WAL"))
        cpi = abs(asarray(O1, "CPI") - asarray(B, "CPI0"))
        ok = (wal < 1e-6*scale & cpi < 1e-8)
        _cgemod_vrow(lab[j], "W " + strofreal(wal, "%8.1e") + " CPI " + strofreal(cpi, "%8.1e"), "solves, Walras, CPI", ok)
    }
    /* 2. path independence: the shock applied in steps gives the same solution as in one step */
    B = _cgemod_copy(M0)
    if (hasT) tm0 = asarray(M0, "tm")
    z1 = asarray(M0, "zbase")
    if (hasT) asarray(B, "tm", tm0 :* 0)
    else if (hasM) asarray(B, "pwm", asarray(M0, "pwm") :* 1.1)
    else asarray(B, "tfp", asarray(M0, "tfp") :* 1.05)
    O1 = asarray_create()
    rc = _cgemod_vsolve(B, z1, O1)
    z2 = asarray(M0, "zbase")
    ok = (rc == 0)
    for (s = 1; s <= steps & ok; s++) {
        Bp = _cgemod_copy(M0)
        if (hasT) asarray(Bp, "tm", tm0 :* (1 - s/steps))
        else if (hasM) asarray(Bp, "pwm", asarray(M0, "pwm") :* (1 + 0.1*s/steps))
        else asarray(Bp, "tfp", asarray(M0, "tfp") :* (1 + 0.05*s/steps))
        O2 = asarray_create()
        ok = (_cgemod_vsolve(Bp, z2, O2) == 0)
    }
    gap = (ok ? max(abs(z1 - z2)) : .)
    ok = ok & gap < 1e-6
    _cgemod_vrow("Path independence (" + strofreal(steps) + " steps)", "max gap " + strofreal(gap, "%8.1e"), "< 1e-6", ok)
    /* 3. symmetry of small shocks: +1% and -1% give mirror-image first-order effects */
    Bp = _cgemod_copy(M0)
    Bm = _cgemod_copy(M0)
    if (hasM) {
        asarray(Bp, "pwm", asarray(M0, "pwm") :* 1.01)
        asarray(Bm, "pwm", asarray(M0, "pwm") :* 0.99)
    }
    else {
        asarray(Bp, "tfp", asarray(M0, "tfp") :* 1.01)
        asarray(Bm, "tfp", asarray(M0, "tfp") :* 0.99)
    }
    O1 = asarray_create()
    O2 = asarray_create()
    z1 = asarray(M0, "zbase")
    z2 = asarray(M0, "zbase")
    ok = (_cgemod_vsolve(Bp, z1, O1) == 0 & _cgemod_vsolve(Bm, z2, O2) == 0)
    asym = .
    if (ok) {
        X0 = asarray(Ob, "X")
        Xp = asarray(O1, "X") :/ X0 :- 1
        Xm = asarray(O2, "X") :/ X0 :- 1
        dmax = max(abs(Xp))
        asym = (dmax > 0 ? max(abs(Xp + Xm))/dmax : 0)
        ok = (asym < 0.05)
    }
    _cgemod_vrow("Symmetry of +/-1% shocks", "asymmetry " + strofreal(asym, "%8.1e"), "< 0.05", ok)
    /* 4. the two solvers agree */
    B = _cgemod_copy(M0)
    Bp = _cgemod_copy(M0)
    if (hasT) {
        asarray(B, "tm", asarray(M0, "tm") :* 0)
        asarray(Bp, "tm", asarray(M0, "tm") :* 0)
    }
    else {
        asarray(B, "tfp", asarray(M0, "tfp") :* 1.05)
        asarray(Bp, "tfp", asarray(M0, "tfp") :* 1.05)
    }
    asarray(B, "solver", 1)
    asarray(Bp, "solver", 2)
    z1 = asarray(M0, "zbase")
    z2 = asarray(M0, "zbase")
    O1 = asarray_create()
    O2 = asarray_create()
    ok = (_cgemod_vsolve(B, z1, O1) == 0 & _cgemod_vsolve(Bp, z2, O2) == 0)
    gap = (ok ? max(abs(z1 - z2)) : .)
    ok = ok & gap < 1e-6
    _cgemod_vrow("Newton and Broyden solvers agree", "max gap " + strofreal(gap, "%8.1e"), "< 1e-6", ok)
    /* 5. homogeneity under a non-trivial shock: domestic prices scale with the numeraire */
    B = _cgemod_copy(M0)
    asarray(B, "tfp", asarray(M0, "tfp") :* 1.05)
    z1 = asarray(M0, "zbase")
    O1 = asarray_create()
    ok = (_cgemod_vsolve(B, z1, O1) == 0)
    z2 = z1
    /* the numeraire is raised in steps, each solve starting from the previous solution */
    for (s = 1; s <= 8 & ok; s++) {
        scl = 1 + 2*s/8
        Bp = _cgemod_copy(B)
        asarray(Bp, "CPI0", scl*asarray(B, "CPI0"))
        asarray(Bp, "WFbar", scl :* asarray(B, "WFbar"))
        if (asarray(B, "ext") == 2) asarray(Bp, "EXR0", scl*asarray(B, "EXR0"))
        O2 = asarray_create()
        ok = (_cgemod_vsolve(Bp, z2, O2) == 0)
    }
    gap = .
    if (ok) {
        PDb = asarray(M0, "iD")
        gap = max((max(abs(asarray(O2, "X") :/ asarray(O1, "X") :- 1)), max(abs(asarray(O2, "PQ") :/ asarray(O1, "PQ") :- scl))))
        ok = gap < 1e-6
    }
    _cgemod_vrow("Homogeneity of degree 0 (numeraire x3)", "max gap " + strofreal(gap, "%8.1e"), "< 1e-6", ok)
    npass = sum((*p)[., 4] :== "pass")
    nfail = rows(*p) - npass
    st_local("npass", strofreal(npass))
    st_local("nfail", strofreal(nfail))
}

void _cgemod_vunits(real scalar rc)
{
    real matrix A, B, Ah, Bh
    real scalar gap, ok
    gap = .
    ok = 0
    if (rc == 0) {
        A = st_matrix("__cgemod_v1")
        B = st_matrix("__cgemod_v2")
        Ah = st_matrix("__cgemod_v1h")
        Bh = st_matrix("__cgemod_v2h")
        gap = max((max(abs(A[1..12, 3] - B[1..12, 3])), max(abs(Ah[., 4] - Bh[., 4]))))
        ok = gap < 1e-6
    }
    _cgemod_vrow("Units invariance (SAM x 1000)", (rc ? "could not run" : "max gap " + strofreal(gap, "%8.1e")), "< 1e-6 (% results)", ok)
    st_local("upass", strofreal(ok))
}

void _cgemod_vshow(real scalar np, real scalar nf, real scalar show)
{
    string matrix T
    string colvector rn
    real scalar s
    T = *findexternal("_cgemod_vtab")
    rn = J(rows(T), 1, "")
    for (s = 1; s <= rows(T); s++) rn[s] = substr(strtoname(T[s, 1]), 1, 32)
    st_matrix("__cgemod_valid", (T[., 4] :== "pass"))
    st_matrixrowstripe("__cgemod_valid", (J(rows(T), 1, ""), rn))
    st_matrixcolstripe("__cgemod_valid", ("", "pass"))
    if (!show) return
    printf("\n{txt}cgemod validate: model validation suite\n")
    printf("{txt}{hline 40}{c TT}{hline 46}\n")
    printf("{txt}%-40s{c |}%-24s%-16s%6s\n", "Test", "Value", "Criterion", "Status")
    printf("{txt}{hline 40}{c +}{hline 46}\n")
    for (s = 1; s <= rows(T); s++) {
        printf("{txt}%-40s{c |}{res}%-24s{txt}%-16s%s%6s\n", T[s, 1], abbrev(T[s, 2], 24), abbrev(T[s, 3], 16),
               (T[s, 4] == "pass" ? "{res}" : "{err}"), T[s, 4])
    }
    printf("{txt}{hline 40}{c BT}{hline 46}\n")
    printf("{txt}%g passed, %g failed\n", np, nf)
}

void _cgemod_check()
{
    transmorphic M0, B, B2, Ob, O1, O2
    real matrix S, Jac, Res
    real colvector z, z1, z2, R, X1, X2, PD1, PD2, zs, FF
    real scalar k, rc, it, nrm, maxd, tot, cnd, rk, wal, hq, hp, ok, npass, nfail, s, diff, maxdiff, nconv, scale, hs
    string matrix T
    string scalar seedstate
    M0 = *findexternal("_cgemod_M")
    T = J(0, 4, "")
    npass = 0
    nfail = 0
    /* 1. SAM balance */
    S = asarray(M0, "SAM")
    tot = sum(rowsum(S))
    maxd = max(abs(rowsum(S) - colsum(S)'))
    ok = (maxd <= 1e-6*max((1, tot)))
    T = T \ ("SAM balance (max row-col gap)", strofreal(maxd, "%10.2e"), "< 1e-6 x total", (ok ? "pass" : "FAIL"))
    npass = npass + ok
    nfail = nfail + !ok
    /* 2. benchmark replication */
    Ob = asarray_create()
    R = _cgemod_eval(_cgemod_start(M0), M0, 1, Ob)
    ok = (max(abs(R)) < 1e-6)
    T = T \ ("Benchmark replication (max resid.)", strofreal(max(abs(R)), "%10.2e"), "< 1e-6", (ok ? "pass" : "FAIL"))
    npass = npass + ok
    nfail = nfail + !ok
    /* 3. parameters */
    ok = (min(asarray(M0, "sigva")) > 0 & min(asarray(M0, "sigq")) > 0 & min(asarray(M0, "omega")) > 0)
    ok = ok & (min(asarray(M0, "mps")) >= 0 & max(asarray(M0, "mps")) < 1)
    ok = ok & (min(asarray(M0, "ty")) >= 0 & max(asarray(M0, "ty")) < 1)
    ok = ok & (min(asarray(M0, "EH0") - colsum((asarray(M0, "PQ0") \ J(asarray(M0, "na"), 1, 1)) :* asarray(M0, "gam"))') > 0)
    ok = ok & (min(asarray(M0, "tq")) > -1 & min(asarray(M0, "ta")) < 1)
    T = T \ ("Parameter admissibility", (ok ? "all valid" : "invalid"), "elast>0, 0<=mps,ty<1", (ok ? "pass" : "FAIL"))
    npass = npass + ok
    nfail = nfail + !ok
    /* 4. Jacobian */
    z = asarray(M0, "zbase")
    FF = _cgemod_eval(z, M0, 0, Ob)
    Jac = _cgemod_jac(z, M0, FF)
    k = rows(z)
    rk = rank(Jac)
    cnd = cond(Jac)
    ok = (rk == k & cnd < 1e12)
    T = T \ ("Jacobian rank / condition number", strofreal(rk) + "/" + strofreal(k) + ", " + strofreal(cnd, "%9.2e"), "full rank, < 1e12", (ok ? "pass" : "FAIL"))
    npass = npass + ok
    nfail = nfail + !ok
    st_local("jcond", strtrim(strofreal(cnd, "%21.0g")))
    /* 5. test shock: Walras' law */
    B = _cgemod_copy(M0)
    if (sum(asarray(M0, "hasM"))) asarray(B, "pwm", asarray(M0, "pwm") :* 1.1)
    else asarray(B, "tfp", asarray(M0, "tfp") :* 1.05)
    z1 = asarray(M0, "zbase")
    rc = _cgemod_solve(B, z1, it, nrm)
    ok = (rc == 0)
    T = T \ ("Test shock solves (import prices +10%)", (ok ? strofreal(it) + " iterations" : _cgemod_rcmsg(rc)), "converges", (ok ? "pass" : "FAIL"))
    npass = npass + ok
    nfail = nfail + !ok
    wal = .
    hq = .
    hp = .
    if (rc == 0) {
        O1 = asarray_create()
        (void) _cgemod_eval(z1, B, 1, O1)
        wal = asarray(O1, "WAL")
        scale = asarray(M0, "scale")
        ok = (abs(wal) < 1e-6*scale)
        T = T \ ("Walras' law (slack after shock)", strofreal(wal, "%10.2e"), "< 1e-6 x imports", (ok ? "pass" : "FAIL"))
        npass = npass + ok
        nfail = nfail + !ok
        /* 6. homogeneity */
        hq = .
        hp = .
        z2 = z1
        rc = 0
        for (hs = 1; hs <= 4 & rc == 0; hs++) {
            B2 = _cgemod_copy(B)
            asarray(B2, "CPI0", (1 + hs/4)*asarray(B, "CPI0"))
            asarray(B2, "WFbar", (1 + hs/4) :* asarray(B, "WFbar"))
            if (asarray(B, "ext") == 2) asarray(B2, "EXR0", (1 + hs/4)*asarray(B, "EXR0"))
            rc = _cgemod_solve(B2, z2, it, nrm)
        }
        if (rc == 0) {
            O2 = asarray_create()
            (void) _cgemod_eval(z2, B2, 1, O2)
            X1 = asarray(O1, "X")
            X2 = asarray(O2, "X")
            PD1 = asarray(O1, "PD")[asarray(M0, "iD")]
            PD2 = asarray(O2, "PD")[asarray(M0, "iD")]
            hq = max(abs(X2 :/ X1 :- 1))
            hp = max(abs(PD2 :/ PD1 :- 2))
            ok = (hq < 1e-6 & hp < 1e-6)
        }
        else ok = 0
        T = T \ ("Homogeneity (numeraire doubled)", "dQ " + strofreal(hq, "%8.1e") + " dP " + strofreal(hp, "%8.1e"), "quantities fixed, prices x2", (ok ? "pass" : "FAIL"))
        npass = npass + ok
        nfail = nfail + !ok
        /* 7. uniqueness from perturbed starts */
        seedstate = rseed()
        rseed(20261115)
        nconv = 0
        maxdiff = 0
        for (s = 1; s <= 5; s++) {
            zs = z1 + 0.25 :* (2 :* runiform(rows(z1), 1) :- 1) :* (abs(z1) :+ 0.1)
            rc = _cgemod_solve(B, zs, it, nrm)
            if (rc == 0) {
                nconv++
                diff = max(abs(zs - z1))
                if (diff > maxdiff) maxdiff = diff
            }
        }
        rseed(seedstate)
        ok = (maxdiff < 1e-6)
        T = T \ ("Uniqueness (5 perturbed starts)", strofreal(nconv) + " converged, max gap " + strofreal(maxdiff, "%8.1e"), "same solution", (ok ? "pass" : "CHECK"))
        npass = npass + ok
        nfail = nfail + !ok
    }
    st_local("npass", strofreal(npass))
    st_local("nfail", strofreal(nfail))
    st_local("walras", strtrim(strofreal(wal, "%21.0g")))
    st_local("homog", strtrim(strofreal(max((hq, hp)), "%21.0g")))
    if (st_local("table") != "") return
    printf("\n{txt}cgemod check: model diagnostics\n")
    printf("{txt}{hline 38}{c TT}{hline 39}\n")
    printf("{txt}%-38s{c |}%-22s%-11s%6s\n", "Check", "Value", "Criterion", "Status")
    printf("{txt}{hline 38}{c +}{hline 39}\n")
    for (s = 1; s <= rows(T); s++) {
        printf("{txt}%-38s{c |}{res}%-22s{txt}%-11s%s%6s\n", T[s, 1], abbrev(T[s, 2], 22), abbrev(T[s, 3], 11),
               (T[s, 4] == "pass" ? "{res}" : "{err}"), T[s, 4])
    }
    printf("{txt}{hline 38}{c BT}{hline 39}\n")
    printf("{txt}%g passed, %g failed\n", npass, nfail)
}

/* ------------------------------------------------------ scenario manager */
transmorphic _cgemod_scstore(real scalar reset)
{
    pointer() scalar p
    p = findexternal("_cgemod_sc")
    if (p == NULL) {
        p = crexternal("_cgemod_sc")
        *p = asarray_create()
    }
    if (reset) *p = asarray_create()
    return(p)
}

void _cgemod_sccollect(real scalar k, real scalar ns, real scalar ok)
{
    pointer() scalar p
    transmorphic A
    real matrix R
    string scalar key
    string rowvector keys, src
    real rowvector col
    real scalar j
    p = _cgemod_scstore(k == 1)
    A = *p
    keys = ("mac", "sec", "ev", "evp", "wage")
    src = ("r(macro)", "r(sector)", "r(household)", "r(household)", "r(factor)")
    col = (3, 1, 3, 4, 3)
    for (j = 1; j <= cols(keys); j++) {
        key = keys[j]
        if (ok) {
            R = st_matrix(src[j])
            if (!asarray_contains(A, key)) {
                asarray(A, key, J(rows(R), ns, .))
                asarray(A, key + "_rn", st_matrixrowstripe(src[j])[., 2])
            }
            R = (rows(R) ? R[., col[j]] : J(0, 1, .))
            asarray(A, key, _cgemod_scput(asarray(A, key), R, k))
        }
    }
    *p = A
}

real matrix _cgemod_scput(real matrix X, real colvector v, real scalar k)
{
    real matrix Y
    Y = X
    if (rows(Y) == rows(v)) Y[., k] = v
    return(Y)
}

void _cgemod_scpov(real scalar k, real scalar ns)
{
    pointer() scalar p
    transmorphic A
    real matrix R, P
    p = _cgemod_scstore(0)
    A = *p
    R = st_matrix("r(poverty)")
    if (!asarray_contains(A, "pov")) asarray(A, "pov", J(4, ns + 1, .))
    P = asarray(A, "pov")
    P[., 1] = R[1..4, 1]
    P[., k + 1] = R[1..4, 2]
    asarray(A, "pov", P)
    *p = A
}

void _cgemod_scfinish(string scalar names)
{
    pointer() scalar p
    transmorphic A
    string rowvector sc, keys, mats
    real scalar j
    p = _cgemod_scstore(0)
    A = *p
    sc = tokens(names)
    keys = ("mac", "sec", "ev", "evp", "wage")
    mats = ("__cgemod_scmac", "__cgemod_scsec", "__cgemod_scev", "__cgemod_scevp", "__cgemod_scwage")
    for (j = 1; j <= cols(keys); j++) {
        if (!asarray_contains(A, keys[j])) {
            errprintf("no scenario could be solved\n")
            exit(430)
        }
        _cgemod_post(mats[j], asarray(A, keys[j]), asarray(A, keys[j] + "_rn"), sc)
    }
    stata("capture matrix drop __cgemod_scpov")
    if (asarray_contains(A, "pov")) {
        _cgemod_post("__cgemod_scpov", asarray(A, "pov"), ("P0", "P1", "P2", "Gini")', ("baseline", sc))
    }
}

void _cgemod_sctable()
{
    real matrix Mc, Ev, Pv
    string colvector rn, hn
    string rowvector sc, pick, lab
    real scalar i, j, r, b, b0, b1, w, hasP
    Mc = st_matrix("__cgemod_scmac")
    rn = st_matrixrowstripe("__cgemod_scmac")[., 2]
    sc = st_matrixcolstripe("__cgemod_scmac")[., 2]'
    Ev = st_matrix("__cgemod_scevp")
    hn = st_matrixrowstripe("__cgemod_scevp")[., 2]
    hasP = (rows(st_matrix("__cgemod_scpov")) > 0)
    if (hasP) Pv = st_matrix("__cgemod_scpov")
    pick = ("RGDP", "RABS", "RCONS", "RINV", "RGOV", "REXP", "RIMP", "EXR", "CPI", "RER", "GSAV", "FSAV", "EMIS")
    lab = ("Real GDP (%)", "Real absorption (%)", "Household consumption (%)", "Real investment (%)",
           "Government consumption (%)", "Exports (%)", "Imports (%)", "Exchange rate (%)", "CPI (%)",
           "Real exchange rate (%)", "Government savings (chg)", "Foreign savings (chg)", "Emissions (%)")
    w = 5
    for (b0 = 1; b0 <= cols(sc); b0 = b0 + w) {
        b1 = min((b0 + w - 1, cols(sc)))
        printf("\n{txt}{hline 28}{c TT}{hline %g}\n", 12*(b1 - b0 + 1))
        printf("{txt}%-28s{c |}", "Scenario comparison")
        for (j = b0; j <= b1; j++) printf("{txt}%12s", abbrev(sc[j], 11))
        printf("\n{txt}{hline 28}{c +}{hline %g}\n", 12*(b1 - b0 + 1))
        for (i = 1; i <= cols(pick); i++) {
            r = 0
            for (b = 1; b <= rows(rn); b++) if (rn[b] == pick[i]) r = b
            if (r == 0) continue
            if (pick[i] == "EMIS" & max(abs(Mc[r, .])) == 0) continue
            printf("{txt}%-28s{c |}", lab[i])
            for (j = b0; j <= b1; j++) printf("{res}%12.3f", Mc[r, j])
            printf("\n")
        }
        printf("{txt}{hline 28}{c +}{hline %g}\n", 12*(b1 - b0 + 1))
        printf("{txt}%-28s{c |}\n", "EV, % of base spending")
        for (i = 1; i <= rows(hn); i++) {
            printf("{txt}  %-26s{c |}", abbrev(hn[i], 26))
            for (j = b0; j <= b1; j++) printf("{res}%12.3f", Ev[i, j])
            printf("\n")
        }
        if (hasP) {
            printf("{txt}{hline 28}{c +}{hline %g}\n", 12*(b1 - b0 + 1))
            lab = ("Headcount P0 (%)", "Poverty gap P1 (%)", "Severity P2 (%)", "Gini (x100)")
            printf("{txt}%-28s{c |}  (baseline P0 = %5.2f)\n", "Poverty after the shock", Pv[1, 1])
            for (i = 1; i <= 4; i++) {
                printf("{txt}  %-26s{c |}", lab[i])
                for (j = b0; j <= b1; j++) printf("{res}%12.3f", Pv[i, j + 1])
                printf("\n")
            }
            lab = ("Real GDP (%)", "Real absorption (%)", "Household consumption (%)", "Real investment (%)",
                   "Government consumption (%)", "Exports (%)", "Imports (%)", "Exchange rate (%)", "CPI (%)",
                   "Real exchange rate (%)", "Government savings (chg)", "Foreign savings (chg)", "Emissions (%)")
        }
        printf("{txt}{hline 28}{c BT}{hline %g}\n", 12*(b1 - b0 + 1))
    }
}

string scalar _cgemod_hesc(string scalar x)
{
    string scalar y
    y = subinstr(x, "&", "&amp;")
    y = subinstr(y, "<", "&lt;")
    y = subinstr(y, ">", "&gt;")
    y = subinstr(y, `"""', "&quot;")
    return(y)
}

string scalar _cgemod_hnum(real scalar v)
{
    if (v >= .) return("&ndash;")
    return(strtrim(strofreal(v, "%12.3f")))
}

void _cgemod_htable(real scalar fh, string scalar title, real matrix X, string colvector rn, string rowvector cn)
{
    real scalar i, j
    fput(fh, "<h2>" + _cgemod_hesc(title) + "</h2>")
    fput(fh, "<div class='tw'><table><thead><tr><th></th>")
    for (j = 1; j <= cols(cn); j++) fput(fh, "<th>" + _cgemod_hesc(cn[j]) + "</th>")
    fput(fh, "</tr></thead><tbody>")
    for (i = 1; i <= rows(X); i++) {
        fput(fh, "<tr><td class='rn'>" + _cgemod_hesc(rn[i]) + "</td>")
        for (j = 1; j <= cols(X); j++) {
            fput(fh, "<td class='" + (X[i, j] < 0 ? "neg" : "pos") + "'>" + _cgemod_hnum(X[i, j]) + "</td>")
        }
        fput(fh, "</tr>")
    }
    fput(fh, "</tbody></table></div>")
}

void _cgemod_hbars(real scalar fh, string scalar title, real rowvector v, string rowvector cn)
{
    real scalar j, mx, w, x0, y, n, bw
    string scalar col
    n = cols(v)
    mx = max(abs(editmissing(v, 0)))
    if (mx == 0) mx = 1
    w = 260
    x0 = 160 + w
    fput(fh, "<figure><figcaption>" + _cgemod_hesc(title) + "</figcaption>")
    fput(fh, sprintf("<svg viewBox='0 0 %g %g' role='img'>", 2*w + 240, 26*n + 10))
    fput(fh, sprintf("<line x1='%g' y1='0' x2='%g' y2='%g' class='axis'/>", x0, x0, 26*n + 10))
    for (j = 1; j <= n; j++) {
        y = 26*(j - 1) + 6
        bw = (v[j] < . ? w*abs(v[j])/mx : 0)
        col = (v[j] < 0 ? "barn" : "barp")
        fput(fh, sprintf("<text x='150' y='%g' class='lab'>%s</text>", y + 14, _cgemod_hesc(cn[j])))
        fput(fh, sprintf("<rect x='%g' y='%g' width='%g' height='18' class='%s'/>",
             (v[j] < 0 ? x0 - bw : x0), y, bw, col))
        fput(fh, sprintf("<text x='%g' y='%g' class='val%s'>%s</text>", (v[j] < 0 ? x0 - bw - 6 : x0 + bw + 6),
             y + 14, (v[j] < 0 ? " r" : ""), _cgemod_hnum(v[j])))
    }
    fput(fh, "</svg></figure>")
}

void _cgemod_scdash(string scalar fn, string scalar title)
{
    real scalar fh, i, r, k
    real matrix Mc
    string colvector rn
    string rowvector sc, ind, ilab
    string scalar s, d
    Mc = st_matrix("__cgemod_scmac")
    rn = st_matrixrowstripe("__cgemod_scmac")[., 2]
    sc = st_matrixcolstripe("__cgemod_scmac")[., 2]'
    if (fileexists(fn)) unlink(fn)
    fh = fopen(fn, "w")
    fput(fh, "<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>")
    fput(fh, "<meta name='viewport' content='width=device-width,initial-scale=1'>")
    fput(fh, "<title>" + _cgemod_hesc(title) + "</title><style>")
    fput(fh, "body{font-family:Georgia,'Times New Roman',serif;margin:0;background:#f7f6f2;color:#1f2328}")
    fput(fh, "header{background:#14324a;color:#fff;padding:28px 40px}header h1{margin:0;font-size:26px;font-weight:normal}")
    fput(fh, "header p{margin:6px 0 0;color:#c9d6e2;font-size:14px}main{max-width:1100px;margin:0 auto;padding:24px 40px 60px}")
    fput(fh, "h2{font-size:18px;font-weight:normal;border-bottom:1px solid #c8c3b6;padding-bottom:4px;margin-top:36px}")
    fput(fh, ".tw{overflow-x:auto}table{border-collapse:collapse;font-family:Helvetica,Arial,sans-serif;font-size:13px;background:#fff}")
    fput(fh, "th,td{padding:6px 12px;border-bottom:1px solid #e5e1d8;text-align:right}th{background:#ece8de;font-weight:600}")
    fput(fh, "td.rn{text-align:left;font-weight:600}td.neg{color:#9b2c2c}td.pos{color:#1f2328}")
    fput(fh, ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(460px,1fr));gap:20px}")
    fput(fh, "figure{margin:0;background:#fff;padding:14px;border:1px solid #e5e1d8}figcaption{font-family:Helvetica,Arial,sans-serif;font-size:13px;font-weight:600;margin-bottom:8px}")
    fput(fh, "svg{width:100%;height:auto;font-family:Helvetica,Arial,sans-serif;font-size:12px}.axis{stroke:#888}.barp{fill:#2f6f8f}.barn{fill:#b5523b}")
    fput(fh, ".lab{text-anchor:end}.val.r{text-anchor:end}dl{font-family:Helvetica,Arial,sans-serif;font-size:13px}dt{font-weight:600;margin-top:8px}dd{margin-left:16px}")
    fput(fh, "footer{font-family:Helvetica,Arial,sans-serif;font-size:12px;color:#666;margin-top:40px}</style></head><body>")
    fput(fh, "<header><h1>" + _cgemod_hesc(title) + "</h1><p>Percentage change from the benchmark equilibrium unless stated; " +
             strofreal(cols(sc)) + " scenarios; generated " + c("current_date") + "</p></header><main>")
    fput(fh, "<h2>Scenarios</h2><dl>")
    for (i = 1; i <= cols(sc); i++) {
        s = st_global("CGEMOD_scs_" + sc[i])
        d = st_global("CGEMOD_scc_" + sc[i])
        fput(fh, "<dt>" + _cgemod_hesc(sc[i]) + "</dt><dd>" + _cgemod_hesc(s) + (d != "" ? "; closure: " + _cgemod_hesc(d) : "") +
                 (st_global("CGEMOD_scd_" + sc[i]) != "" ? "<br>" + _cgemod_hesc(st_global("CGEMOD_scd_" + sc[i])) : "") + "</dd>")
    }
    fput(fh, "</dl><div class='grid'>")
    ind = ("RGDP", "RCONS", "RINV", "REXP")
    ilab = ("Real GDP, % change", "Real household consumption, % change", "Real investment, % change", "Real exports, % change")
    for (i = 1; i <= 4; i++) {
        s = ind[i]
        d = ilab[i]
        r = 0
        for (k = 1; k <= rows(rn); k++) if (rn[k] == s) r = k
        if (r) _cgemod_hbars(fh, d, Mc[r, .], sc)
    }
    fput(fh, "</div>")
    _cgemod_htable(fh, "Macroeconomic results", Mc, rn, sc)
    _cgemod_htable(fh, "Household welfare: equivalent variation, % of base spending", st_matrix("__cgemod_scevp"),
                   st_matrixrowstripe("__cgemod_scevp")[., 2], sc)
    _cgemod_htable(fh, "Household welfare: equivalent variation, value", st_matrix("__cgemod_scev"),
                   st_matrixrowstripe("__cgemod_scev")[., 2], sc)
    _cgemod_htable(fh, "Activity output, % change", st_matrix("__cgemod_scsec"), st_matrixrowstripe("__cgemod_scsec")[., 2], sc)
    _cgemod_htable(fh, "Average factor returns, % change", st_matrix("__cgemod_scwage"), st_matrixrowstripe("__cgemod_scwage")[., 2], sc)
    if (rows(st_matrix("__cgemod_scpov")) > 0) {
        _cgemod_htable(fh, "Poverty and inequality after each scenario (FGT indices and Gini)", st_matrix("__cgemod_scpov"),
                       st_matrixrowstripe("__cgemod_scpov")[., 2], ("baseline", sc))
    }
    fput(fh, "<footer>Produced with cgemod (Stata). Balances (government and foreign savings, adjustment factors, Walras check) are changes in levels.</footer>")
    fput(fh, "</main></body></html>")
    fclose(fh)
}

/* -------------------------------------------------- elasticity helpers */
void _cgemod_jb(string scalar ev, string scalar touse)
{
    real colvector e
    real scalar N, m2, m3, m4, S, K, jb
    e = st_data(., ev, touse)
    N = rows(e)
    e = e :- mean(e)
    m2 = mean(e :^ 2)
    m3 = mean(e :^ 3)
    m4 = mean(e :^ 4)
    S = m3/m2^1.5
    K = m4/m2^2
    jb = N*(S^2/6 + (K - 3)^2/24)
    st_local("jb", strtrim(strofreal(jb, "%21.0g")))
    st_local("jbp", strtrim(strofreal(chi2tail(2, jb), "%21.0g")))
}

void _cgemod_dw(string scalar ev, string scalar touse)
{
    real colvector e
    e = st_data(., ev, touse)
    st_local("dw", strtrim(strofreal(sum((e[|2 \ rows(e)|] - e[|1 \ rows(e) - 1|]) :^ 2)/sum(e :^ 2), "%21.0g")))
}

real matrix _cgemod_within(real matrix X, real colvector id)
{
    real matrix Y
    real colvector ids, s
    real scalar i
    ids = uniqrows(id)
    Y = X
    for (i = 1; i <= rows(ids); i++) {
        s = selectindex(id :== ids[i])
        Y[s, .] = X[s, .] :- mean(X[s, .])
    }
    return(Y)
}

real scalar _cgemod_ssr(real colvector y, real matrix Z)
{
    real colvector e
    e = y - Z*(invsym(cross(Z, Z))*cross(Z, y))
    return(cross(e, e))
}

void _cgemod_cusum(string scalar yv, string scalar xvars, string scalar touse)
{
    real colvector y, w, ws, Wc, bound, b, x
    real matrix X, XXi, Xr
    real scalar T, k, r, m, sig
    y = st_data(., yv, touse)
    X = (st_data(., tokens(xvars), touse), J(rows(y), 1, 1))
    T = rows(y)
    k = cols(X)
    w = J(T, 1, .)
    for (r = k + 1; r <= T; r++) {
        Xr = X[|1, 1 \ r - 1, k|]
        XXi = invsym(cross(Xr, Xr))
        if (diag0cnt(XXi) > 0) continue
        b = XXi*cross(Xr, y[|1 \ r - 1|])
        x = X[r, .]'
        w[r] = (y[r] - x'*b)/sqrt(1 + x'*XXi*x)
    }
    ws = select(w, w :< .)
    m = rows(ws)
    if (m < 5) {
        st_local("cusum", ".")
        return
    }
    sig = sqrt(variance(ws))
    Wc = runningsum(ws) :/ sig
    bound = sqrt(m) :+ 2 :* (1::m) :/ sqrt(m)
    st_local("cusum", strtrim(strofreal(max(abs(Wc) :/ bound), "%21.0g")))
}

real scalar _cgemod_supfstat(real colvector y, real matrix X, real colvector xk, real scalar lo,
                             real scalar hi, real scalar tb)
{
    real scalar T, k, ssr0, ssr1, best, t, Fv
    real colvector D
    T = rows(y)
    k = cols(X)
    ssr0 = _cgemod_ssr(y, X)
    best = -1
    tb = .
    for (t = lo; t <= hi; t++) {
        D = J(t - 1, 1, 0) \ J(T - t + 1, 1, 1)
        ssr1 = _cgemod_ssr(y, (X, D, D :* xk))
        Fv = ((ssr0 - ssr1)/2)/(ssr1/(T - k - 2))
        if (Fv > best) {
            best = Fv
            tb = t
        }
    }
    return(best)
}

void _cgemod_supf(string scalar yv, string scalar xvars, string scalar keyv, string scalar touse,
                  string scalar tvar, real scalar trim, real scalar reps)
{
    real colvector y, xk, tt, e0, ys
    real matrix X
    real scalar T, k, lo, hi, FF, tb, tbb, cnt, b, Fb
    y = st_data(., yv, touse)
    X = (st_data(., tokens(xvars), touse), J(rows(y), 1, 1))
    xk = st_data(., keyv, touse)
    tt = st_data(., tvar, touse)
    T = rows(y)
    k = cols(X)
    lo = max((ceil(trim*T), k + 2))
    hi = min((floor((1 - trim)*T), T - k - 2))
    if (hi <= lo) return
    e0 = y - X*(invsym(cross(X, X))*cross(X, y))
    FF = _cgemod_supfstat(y, X, xk, lo, hi, tb)
    cnt = 0
    for (b = 1; b <= reps; b++) {
        ys = e0 :* rnormal(T, 1, 0, 1)
        Fb = _cgemod_supfstat(ys, X, xk, lo, hi, tbb)
        cnt = cnt + (Fb >= FF)
    }
    st_local("supfstat", strtrim(strofreal(FF, "%21.0g")))
    st_local("supfp", strtrim(strofreal((cnt + 1)/(reps + 1), "%21.0g")))
    st_local("breakt", strtrim(strofreal(tt[tb], "%21.0g")))
}

void _cgemod_vif(string scalar xvars, string scalar touse, string scalar pid)
{
    real matrix X, Z
    real colvector y, e, yc
    real rowvector vif
    real scalar k, j, r2
    X = st_data(., tokens(xvars), touse)
    k = cols(X)
    if (k < 2) return
    if (pid != "") X = _cgemod_within(X, st_data(., pid, touse))
    vif = J(1, k, .)
    for (j = 1; j <= k; j++) {
        y = X[., j]
        Z = (X[., selectindex((1..k) :!= j)], J(rows(X), 1, 1))
        e = y - Z*(invsym(cross(Z, Z))*cross(Z, y))
        yc = y :- mean(y)
        r2 = 1 - cross(e, e)/cross(yc, yc)
        vif[j] = 1/(1 - r2)
    }
    st_local("vifmax", strtrim(strofreal(max(vif), "%21.0g")))
    st_local("vifs", invtokens(strofreal(vif, "%9.2f")))
}

void _cgemod_cd(string scalar ev, string scalar touse, string scalar pid, string scalar tid)
{
    real colvector e, id, tv, ids, ts, a, b
    real matrix E
    real rowvector cc
    real scalar N, T, r, i, j, s, cnt, sabs, rho, Tij, cd
    e = st_data(., ev, touse)
    id = st_data(., pid, touse)
    tv = st_data(., tid, touse)
    ids = uniqrows(id)
    ts = uniqrows(tv)
    N = rows(ids)
    T = rows(ts)
    E = J(N, T, .)
    for (r = 1; r <= rows(e); r++) {
        E[selectindex(ids :== id[r]), selectindex(ts :== tv[r])] = e[r]
    }
    s = 0
    cnt = 0
    sabs = 0
    for (i = 1; i < N; i++) {
        for (j = i + 1; j <= N; j++) {
            cc = selectindex((E[i, .] :< .) :& (E[j, .] :< .))
            Tij = cols(cc)
            if (Tij < 3) continue
            a = E[i, cc]'
            b = E[j, cc]'
            a = a :- mean(a)
            b = b :- mean(b)
            rho = cross(a, b)/sqrt(cross(a, a)*cross(b, b))
            s = s + sqrt(Tij)*rho
            sabs = sabs + abs(rho)
            cnt++
        }
    }
    if (cnt == 0) {
        st_local("cd", ".")
        st_local("cdp", ".")
        return
    }
    cd = s/sqrt(cnt)
    st_local("cd", strtrim(strofreal(cd, "%21.0g")))
    st_local("cdp", strtrim(strofreal(2*normal(-abs(cd)), "%21.0g")))
    st_local("cdabs", strtrim(strofreal(sabs/cnt, "%21.0g")))
}

void _cgemod_mwald(string scalar ev, string scalar touse, string scalar pid)
{
    real colvector e, id, ids, s, ei
    real scalar N, s2, W, i, Ti, si, Vi
    e = st_data(., ev, touse)
    id = st_data(., pid, touse)
    ids = uniqrows(id)
    N = rows(ids)
    s2 = cross(e, e)/rows(e)
    W = 0
    for (i = 1; i <= N; i++) {
        s = selectindex(id :== ids[i])
        ei = e[s]
        Ti = rows(ei)
        if (Ti < 2) continue
        si = cross(ei, ei)/Ti
        Vi = sum((ei :^ 2 :- si) :^ 2)/(Ti*(Ti - 1))
        if (Vi > 0) W = W + (si - s2)^2/Vi
    }
    st_local("mw", strtrim(strofreal(W, "%21.0g")))
    st_local("mwp", strtrim(strofreal(chi2tail(N, W), "%21.0g")))
}

void _cgemod_dk(string scalar yv, string scalar xvars, string scalar touse, string scalar pid,
                string scalar tid, real scalar m, string scalar bname, string scalar vname)
{
    real colvector y, id, tv, yw, b, e, ts
    real matrix X, Xw, XXi, H, S, G, V
    real scalar T, k, r, l, j
    string rowvector xn
    y = st_data(., yv, touse)
    xn = tokens(xvars)
    X = st_data(., xn, touse)
    id = st_data(., pid, touse)
    tv = st_data(., tid, touse)
    yw = _cgemod_within(y, id)
    Xw = _cgemod_within(X, id)
    XXi = invsym(cross(Xw, Xw))
    b = XXi*cross(Xw, yw)
    e = yw - Xw*b
    ts = uniqrows(tv)
    T = rows(ts)
    k = cols(X)
    H = J(T, k, 0)
    for (r = 1; r <= rows(y); r++) {
        j = selectindex(ts :== tv[r])
        H[j, .] = H[j, .] + Xw[r, .]*e[r]
    }
    S = cross(H, H)
    for (l = 1; l <= min((m, T - 1)); l++) {
        G = cross(H[|l + 1, 1 \ T, k|], H[|1, 1 \ T - l, k|])
        S = S + (1 - l/(m + 1)) :* (G + G')
    }
    V = XXi*S*XXi
    st_matrix(bname, b')
    st_matrix(vname, V)
    st_matrixcolstripe(bname, (J(k, 1, ""), xn'))
    st_matrixrowstripe(vname, (J(k, 1, ""), xn'))
    st_matrixcolstripe(vname, (J(k, 1, ""), xn'))
}

void _cgemod_store(string scalar mat, string scalar sec, real scalar val)
{
    real matrix Mx
    string rowvector cn
    real rowvector p
    Mx = st_matrix(mat)
    if (sec == "") sec = "e" + strofreal(cols(Mx) + 1)
    if (rows(Mx)*cols(Mx) == 0) {
        Mx = val
        cn = sec
    }
    else {
        cn = st_matrixcolstripe(mat)[., 2]'
        p = selectindex(cn :== sec)
        if (cols(p)) Mx[1, p[1]] = val
        else {
            Mx = (Mx[1, .], val)
            cn = (cn, sec)
        }
    }
    st_matrix(mat, Mx)
    st_matrixcolstripe(mat, (J(cols(cn), 1, ""), cn'))
    st_matrixrowstripe(mat, ("", "elast"))
}

/* ------------------------------------------------------- SAM workflow */
void _cgemod_samaudit()
{
    string scalar name
    string rowvector nm, roles, glab, L
    real matrix S
    real colvector r, cs_, d, ord
    real rowvector ix, A_, C_, F_, H_, TX, ng
    real scalar K, tot, top, show, nneg, nempty, i, j, k, g, gw, gap, gdpi, gdpe, gv, rw, si, a, cnt
    name = st_local("sam")
    S = st_matrix(name)
    nm = st_matrixrowstripe(name)[., 2]'
    K = rows(S)
    if (K != cols(S)) {
        errprintf("matrix %s is not square\n", name)
        exit(503)
    }
    r = rowsum(S)
    cs_ = colsum(S)'
    d = r - cs_
    tot = sum(r)
    top = min((strtoreal(st_local("top")), K))
    show = (st_local("table") == "")
    nneg = sum(S :< 0)
    nempty = sum((r :== 0) :& (cs_ :== 0))
    ord = order(-abs(d), 1)
    st_local("naccounts", strofreal(K))
    st_local("samtotal", strtrim(strofreal(tot, "%21.0g")))
    st_local("maxgap", strtrim(strofreal(abs(d[ord[1]]), "%21.0g")))
    st_local("worst", nm[ord[1]])
    st_local("nneg", strofreal(nneg))
    st_local("nempty", strofreal(nempty))
    if (show) {
        printf("\n{txt}cgemod samcheck: SAM {res}%s{txt} (%g accounts, total %g)\n", name, K, tot)
        printf("{txt}negative cells: {res}%g{txt}; empty accounts: {res}%g\n", nneg, nempty)
        printf("\n{txt}Largest receipt-payment gaps\n")
        printf("{txt}{hline 22}{c TT}{hline 56}\n")
        printf("{txt}%-22s{c |}%14s%14s%14s%12s\n", "Account", "Receipts", "Payments", "Gap", "% of total")
        printf("{txt}{hline 22}{c +}{hline 56}\n")
        for (i = 1; i <= top; i++) {
            k = ord[i]
            printf("{txt}%-22s{c |}{res}%14.4f%14.4f%14.4f%12.4f\n", abbrev(nm[k], 22), r[k], cs_[k], d[k],
                   (max((abs(r[k]), abs(cs_[k]))) > 0 ? 100*d[k]/max((abs(r[k]), abs(cs_[k]))) : 0))
        }
        printf("{txt}{hline 22}{c BT}{hline 56}\n")
        if (nneg) {
            printf("{txt}negative cells (payer -> receiver):\n")
            cnt = 0
            for (i = 1; i <= K; i++) {
                for (j = 1; j <= K; j++) {
                    if (S[i, j] < 0 & cnt < 10) {
                        printf("{txt}   %s -> %s : {res}%g\n", nm[j], nm[i], S[i, j])
                        cnt++
                    }
                }
            }
            printf("{txt}   GRAS balancing ({cmd:cgemod sambalance}) keeps these cells negative\n")
        }
    }
    roles = ("activities", "commodities", "factors", "households", "government", "row", "savinv", "taxes",
             "enterprises", "margins", "stocks")
    glab = ("Activities: revenue = cost", "Commodities: supply = demand", "Factors: income = payments",
            "Households: income = spending", "Government: revenue = spending", "Rest of world: receipts = payments",
            "Savings = investment", "Tax accounts: collected = paid over", "Enterprises: income = spending",
            "Trade margins: charged = supplied", "Stock changes: financed = used")
    ng = J(1, 11, 0)
    for (g = 1; g <= 11; g++) ng[g] = cols(tokens(st_local(roles[g])))
    if (sum(ng) & show) {
        printf("\n{txt}Accounting identities by account group\n")
        printf("{txt}{hline 38}{c TT}{hline 39}\n")
        printf("{txt}%-38s{c |}%14s  %-22s\n", "Identity", "Sum |gap|", "Largest gap")
        printf("{txt}{hline 38}{c +}{hline 39}\n")
    }
    for (g = 1; g <= 11; g++) {
        if (!ng[g]) continue
        ix = _cgemod_ix(tokens(st_local(roles[g])), nm, roles[g])
        gap = sum(abs(d[ix]))
        gw = ix[1]
        for (i = 1; i <= cols(ix); i++) if (abs(d[ix[i]]) > abs(d[gw])) gw = ix[i]
        if (show) printf("{txt}%-38s{c |}{res}%14.4f  %-22s%s\n", glab[g], gap, abbrev(nm[gw], 22),
                         (gap > 1e-6*max((1, tot)) ? "{err} <" : ""))
    }
    if (sum(ng) & show) printf("{txt}{hline 38}{c BT}{hline 39}\n")
    gdpi = .
    gdpe = .
    if (ng[1] & ng[2] & ng[3] & ng[4] & ng[5] & ng[6] & ng[7]) {
        A_ = _cgemod_ix(tokens(st_local("activities")), nm, "activity")
        C_ = _cgemod_ix(tokens(st_local("commodities")), nm, "commodity")
        F_ = _cgemod_ix(tokens(st_local("factors")), nm, "factor")
        H_ = _cgemod_ix(tokens(st_local("households")), nm, "household")
        gv = _cgemod_ix(tokens(st_local("government")), nm, "government")[1]
        rw = _cgemod_ix(tokens(st_local("row")), nm, "rest-of-world")[1]
        si = _cgemod_ix(tokens(st_local("savinv")), nm, "savings-investment")[1]
        TX = J(1, 0, .)
        if (ng[8]) TX = _cgemod_ix(tokens(st_local("taxes")), nm, "tax")
        gdpi = sum(S[F_, A_])
        for (a = 1; a <= cols(A_); a++) gdpi = gdpi + _cgemod_sr(S, TX, A_[a]) + S[gv, A_[a]]
        for (a = 1; a <= cols(C_); a++) gdpi = gdpi + _cgemod_sr(S, TX, C_[a]) + S[gv, C_[a]]
        gdpe = sum(S[C_, H_]) + sum(S[A_, H_]) + sum(S[C_, gv]) + sum(S[C_, si]) + sum(S[C_, rw]) - sum(S[rw, C_])
        if (ng[11]) gdpe = gdpe + sum(S[C_, _cgemod_ix(tokens(st_local("stocks")), nm, "stocks")[1]])
        if (show) {
            printf("{txt}GDP at market prices: income side {res}%g{txt}, expenditure side {res}%g{txt}, difference {res}%g\n",
                   gdpi, gdpe, gdpi - gdpe)
        }
    }
    st_local("gdpi", strtrim(strofreal(gdpi, "%21.0g")))
    st_local("gdpe", strtrim(strofreal(gdpe, "%21.0g")))
}

real matrix _cgemod_ras2(real matrix S0, real colvector tg, real scalar tol, real scalar maxit,
                         real matrix it, real matrix conv)
{
    real matrix S
    S = S0
    conv = 0
    for (it = 1; it <= maxit; it++) {
        S = S :* editmissing(tg :/ rowsum(S), 1)
        S = S :* editmissing(tg' :/ colsum(S), 1)
        if (max(abs(rowsum(S) - tg)) < tol*sum(tg) & max(abs(colsum(S)' - tg)) < tol*sum(tg)) {
            conv = 1
            break
        }
    }
    if (it > maxit) it = maxit
    return(S)
}

real matrix _cgemod_cebuild(real matrix A, real matrix W, real matrix fr, real matrix sg,
                            real colvector th, real colvector tgt)
{
    real colvector lam, nu
    real matrix E, ex
    real scalar K
    K = rows(A)
    lam = 0 \ th[|1 \ K - 1|]
    nu = J(K, 1, 0)
    if (rows(tgt)) nu[tgt] = th[|K \ rows(th)|]
    E = (lam :+ nu) :- J(K, 1, 1)*(lam')
    ex = -sg :* E :/ W
    ex = ex :* (abs(ex) :<= 50) + 50 :* sign(ex) :* (abs(ex) :> 50)
    return(A :* (fr :* exp(ex) + (1 :- fr)))
}

real colvector _cgemod_ceres(real matrix X, real colvector T, real colvector tgt, real scalar tot)
{
    real colvector rs, cs, g
    rs = rowsum(X)
    cs = colsum(X)'
    g = (rs - cs)[|2 \ rows(rs)|]
    if (rows(tgt)) g = g \ (rs[tgt] - T[tgt])
    return(g :/ tot)
}

real matrix _cgemod_cejac(real matrix X, real matrix W, real matrix fr, real matrix sg,
                          real colvector tgt, real scalar tot)
{
    real matrix C, G, DCr, Ct, Dn, Hl, Hn, Jm
    real colvector Cr, Cc
    real scalar K, nt
    K = rows(X)
    nt = rows(tgt)
    C = fr :* (-X :* sg :/ W)
    Cr = rowsum(C)
    Cc = colsum(C)'
    DCr = diag(Cr)
    Ct = C'
    G = DCr - C - Ct + diag(Cc)
    Jm = G[|2, 2 \ K, K|]
    if (nt) {
        Dn = DCr[., tgt] - Ct[., tgt]
        Hl = DCr[tgt, .] - C[tgt, .]
        Hn = DCr[tgt, tgt]
        Jm = (Jm, Dn[|2, 1 \ K, nt|]) \ (Hl[|1, 2 \ nt, K|], Hn)
    }
    return(Jm :/ tot)
}

real matrix _cgemod_cebal(real matrix A, real matrix W, real matrix FX, real colvector T,
                          real scalar tol, real scalar maxit, real matrix it, real matrix conv)
{
    real matrix fr, sg, X, Xn, Jm
    real colvector tgt, th, FF, Fn, dd
    real scalar K, tot, lam, f0, ok
    K = rows(A)
    tgt = selectindex(T :< .)
    fr = (A :!= 0) :& (FX :== 0)
    sg = sign(A)
    tot = sum(abs(A))
    th = J(K - 1 + rows(tgt), 1, 0)
    conv = 0
    for (it = 0; it <= maxit; it++) {
        X = _cgemod_cebuild(A, W, fr, sg, th, tgt)
        FF = _cgemod_ceres(X, T, tgt, tot)
        if (max(abs(FF)) < tol) {
            conv = 1
            break
        }
        if (it == maxit) break
        Jm = _cgemod_cejac(X, W, fr, sg, tgt, tot)
        dd = lusolve(Jm, -FF)
        if (hasmissing(dd)) dd = qrsolve(Jm, -FF)
        if (hasmissing(dd)) break
        lam = 1
        f0 = sum(FF :^ 2)
        ok = 0
        while (lam > 1e-8) {
            Xn = _cgemod_cebuild(A, W, fr, sg, th + lam*dd, tgt)
            Fn = _cgemod_ceres(Xn, T, tgt, tot)
            if (!hasmissing(Fn)) {
                if (sum(Fn :^ 2) < (1 - 1e-4*lam)*f0) {
                    ok = 1
                    break
                }
            }
            lam = lam/2
        }
        if (!ok) break
        th = th + lam*dd
    }
    if (it > maxit) it = maxit
    return(X)
}

real rowvector _cgemod_bdiag(real matrix A, real matrix X)
{
    real matrix nz, pct, p, q, z
    real scalar kl, mape, mx, n5, flips, obj
    nz = (A :!= 0)
    pct = editmissing(100 :* (X - A) :/ abs(A), 0) :* nz
    mape = sum(abs(pct))/max((1, sum(nz)))
    mx = max(abs(pct))
    n5 = sum(abs(pct) :> 5)
    flips = sum(nz :& (sign(X) :!= sign(A)))
    p = abs(X) :/ sum(abs(X))
    q = abs(A) :/ sum(abs(A))
    kl = sum(editmissing(p :* ln(p :/ q), 0))
    z = editmissing(X :/ A, 1)
    obj = sum(editmissing(abs(A) :* (z :* ln(z) - z :+ 1), 0) :* nz :* (z :> 0))
    return((max(abs(rowsum(A) - colsum(A)')), max(abs(rowsum(X) - colsum(X)')), kl, mape, mx, n5, flips, obj))
}

void _cgemod_topchanges(real matrix A, real matrix X, string rowvector nm, real scalar top, string scalar title)
{
    real colvector ch, ord
    real scalar K, i, k, ri, cj, n
    K = rows(A)
    ch = vec(abs(X - A))
    ord = order(-ch, 1)
    n = min((top, sum(ch :> 1e-12)))
    if (n == 0) return
    printf("\n{txt}%s\n", title)
    printf("{txt}{hline 30}{c TT}{hline 47}\n")
    printf("{txt}%-30s{c |}%12s%12s%12s%11s\n", "Cell (payer -> receiver)", "Before", "After", "Change", "% change")
    printf("{txt}{hline 30}{c +}{hline 47}\n")
    for (i = 1; i <= n; i++) {
        k = ord[i]
        cj = ceil(k/K)
        ri = k - (cj - 1)*K
        printf("{txt}%-30s{c |}{res}%12.4f%12.4f%12.4f%11.3f\n", abbrev(nm[cj] + " -> " + nm[ri], 30),
               A[ri, cj], X[ri, cj], X[ri, cj] - A[ri, cj], (A[ri, cj] != 0 ? 100*(X[ri, cj]/A[ri, cj] - 1) : .))
    }
    printf("{txt}{hline 30}{c BT}{hline 47}\n")
}

void _cgemod_sambal()
{
    string scalar sam, name, method, fixm, wm
    string rowvector nm, fa, ft
    real matrix A, Am, FX, F0, W, X
    real colvector T, tg, rs, cs
    real rowvector D
    real scalar K, tol, maxit, top, show, i, j, k, it, conv, nneg, tot, fixdev
    sam = st_local("sam")
    name = st_local("name")
    method = st_local("method")
    A = st_matrix(sam)
    nm = st_matrixrowstripe(sam)[., 2]'
    K = rows(A)
    if (K != cols(A) | nm != st_matrixcolstripe(sam)[., 2]') {
        errprintf("SAM %s must be square with identical row and column names\n", sam)
        exit(503)
    }
    if (hasmissing(A)) {
        errprintf("SAM %s contains missing cells\n", sam)
        exit(504)
    }
    tol = strtoreal(st_local("tolerance"))
    maxit = strtoreal(st_local("maxiter"))
    top = strtoreal(st_local("top"))
    show = (st_local("table") == "")
    rs = rowsum(A)
    cs = colsum(A)'
    tot = sum(abs(A))
    FX = J(K, K, 0)
    fixm = st_local("fix")
    if (fixm != "") {
        F0 = st_matrix(fixm)
        if (rows(F0) != K | cols(F0) != K) {
            errprintf("fix(): matrix %s must be %g x %g\n", fixm, K, K)
            exit(503)
        }
        FX = (editmissing(F0, 0) :!= 0)
    }
    fa = tokens(st_local("fixaccounts"))
    for (i = 1; i <= cols(fa); i++) {
        k = _cgemod_ix(fa[i], nm, "fixaccounts()")[1]
        if (abs(rs[k] - cs[k]) > 1e-9*max((1, tot))) {
            errprintf("fixaccounts(): account %s is unbalanced (gap %g), so its cells cannot all be locked\n", fa[i], rs[k] - cs[k])
            exit(459)
        }
        FX[k, .] = J(1, K, 1)
        FX[., k] = J(K, 1, 1)
    }
    W = J(K, K, 1)
    wm = st_local("weights")
    if (wm != "") {
        W = st_matrix(wm)
        if (rows(W) != K | cols(W) != K) {
            errprintf("weights(): matrix %s must be %g x %g\n", wm, K, K)
            exit(503)
        }
        if (hasmissing(W) | min(W) <= 0) {
            errprintf("weights(): reliability weights must be positive and nonmissing\n")
            exit(198)
        }
    }
    T = _cgemod_pvec(st_local("totals"), nm, J(1, 0, ""), ., "totals")
    ft = tokens(st_local("fixtotals"))
    for (i = 1; i <= cols(ft); i++) {
        k = _cgemod_ix(ft[i], nm, "fixtotals()")[1]
        T[k] = (rs[k] + cs[k])/2
    }
    if (method == "ras") {
        if (sum(FX) | wm != "") {
            errprintf("fix(), fixaccounts() and weights() require method(gras)\n")
            exit(198)
        }
        Am = A
        nneg = sum(A :< 0)
        for (i = 1; i <= K; i++) {
            for (j = 1; j <= K; j++) {
                if (Am[i, j] < 0) {
                    Am[j, i] = Am[j, i] - Am[i, j]
                    Am[i, j] = 0
                }
            }
        }
        if (nneg & show) printf("{txt}note: RAS cannot keep negative cells; %g moved to the transposed cell (use method(gras) to keep them)\n", nneg)
        tg = (rowsum(Am) + colsum(Am)') :/ 2
        for (k = 1; k <= K; k++) if (T[k] < .) tg[k] = T[k]
        X = _cgemod_ras2(Am, tg, tol, max((maxit, 10000)), it, conv)
    }
    else X = _cgemod_cebal(A, W, FX, T, tol, maxit, it, conv)
    st_matrix(name, X)
    st_matrixrowstripe(name, (J(K, 1, ""), nm'))
    st_matrixcolstripe(name, (J(K, 1, ""), nm'))
    st_matrix("__cgemod_prior", A)
    st_matrixrowstripe("__cgemod_prior", (J(K, 1, ""), nm'))
    st_matrixcolstripe("__cgemod_prior", (J(K, 1, ""), nm'))
    st_matrix("__cgemod_fixmask", FX)
    D = _cgemod_bdiag(A, X)
    fixdev = max(abs((X - A) :* FX))
    st_local("imb0", strtrim(strofreal(D[1], "%21.0g")))
    st_local("imb1", strtrim(strofreal(D[2], "%21.0g")))
    st_local("kl", strtrim(strofreal(D[3], "%21.0g")))
    st_local("mape", strtrim(strofreal(D[4], "%21.0g")))
    st_local("maxpct", strtrim(strofreal(D[5], "%21.0g")))
    st_local("n5", strofreal(D[6]))
    st_local("flips", strofreal(D[7]))
    st_local("ceobj", strtrim(strofreal(D[8], "%21.0g")))
    st_local("nfixed", strofreal(sum(FX :& (A :!= 0))))
    st_local("ntgt", strofreal(sum(T :< .)))
    st_local("it", strofreal(it))
    st_local("conv", strofreal(conv))
    if (!conv) printf("{err}warning: balancing did not converge in %g iterations; locked cells and control totals may be inconsistent\n", it)
    if (!show) return
    printf("\n{txt}cgemod sambalance: {res}%s{txt} -> {res}%s{txt} by %s (%s in %g iterations)\n", sam, name,
           (method == "ras" ? "RAS" : "sign-preserving cross-entropy (GRAS)"), (conv ? "converged" : "NOT converged"), it)
    printf("{txt}locked cells: {res}%g{txt}; control totals: {res}%g{txt}; reliability weights: {res}%s\n",
           sum(FX :& (A :!= 0)), sum(T :< .), (wm != "" ? wm : "none"))
    printf("{txt}{hline 44}{c TT}{hline 20}\n")
    printf("{txt}%-44s{c |}%20s\n", "Diagnostic", "Value")
    printf("{txt}{hline 44}{c +}{hline 20}\n")
    printf("{txt}%-44s{c |}{res}%20.6g\n", "Largest row-column gap before", D[1])
    printf("{txt}%-44s{c |}{res}%20.6g\n", "Largest row-column gap after", D[2])
    printf("{txt}%-44s{c |}{res}%20.6g\n", "Kullback-Leibler divergence of structure", D[3])
    printf("{txt}%-44s{c |}{res}%20.4f\n", "Mean absolute % change of nonzero cells", D[4])
    printf("{txt}%-44s{c |}{res}%20.4f\n", "Largest absolute % change", D[5])
    printf("{txt}%-44s{c |}{res}%20.0f\n", "Cells changed by more than 5%", D[6])
    printf("{txt}%-44s{c |}{res}%20.0f\n", "Sign changes", D[7])
    printf("{txt}%-44s{c |}{res}%20.6g\n", "Cross-entropy objective", D[8])
    printf("{txt}%-44s{c |}{res}%20.6g\n", "Largest change in a locked cell", fixdev)
    printf("{txt}{hline 44}{c BT}{hline 20}\n")
    _cgemod_topchanges(A, X, nm, top, "Largest cell adjustments")
}

void _cgemod_cmpdata(string scalar prior, string scalar newm, string scalar mask)
{
    real matrix A, X, FX
    string rowvector nm
    real colvector ri, cj
    real scalar K, n, i, j, q
    A = st_matrix(prior)
    X = st_matrix(newm)
    FX = st_matrix(mask)
    nm = st_matrixrowstripe(newm)[., 2]'
    K = rows(A)
    n = sum((A :!= 0) :| (X :!= 0))
    ri = J(n, 1, .)
    cj = J(n, 1, .)
    q = 0
    for (j = 1; j <= K; j++) {
        for (i = 1; i <= K; i++) {
            if (A[i, j] != 0 | X[i, j] != 0) {
                q++
                ri[q] = i
                cj[q] = j
            }
        }
    }
    st_addobs(n)
    (void) st_addvar("str32", "receiver")
    (void) st_addvar("str32", "payer")
    (void) st_addvar("double", "before")
    (void) st_addvar("double", "after")
    (void) st_addvar("double", "change")
    (void) st_addvar("double", "pct_change")
    (void) st_addvar("byte", "locked")
    for (q = 1; q <= n; q++) {
        st_sstore(q, "receiver", nm[ri[q]])
        st_sstore(q, "payer", nm[cj[q]])
        st_store(q, "before", A[ri[q], cj[q]])
        st_store(q, "after", X[ri[q], cj[q]])
        st_store(q, "change", X[ri[q], cj[q]] - A[ri[q], cj[q]])
        st_store(q, "pct_change", (A[ri[q], cj[q]] != 0 ? 100*(X[ri[q], cj[q]]/A[ri[q], cj[q]] - 1) : .))
        st_store(q, "locked", FX[ri[q], cj[q]])
    }
}

void _cgemod_sammon()
{
    string scalar sam, bench, flag
    string rowvector nn, bn, newacc, lostacc, cn
    real matrix N, B, Nc, Bc, nzB, nzN, pct, p, q
    real colvector tN, tB, tpct, ord, sc
    real rowvector keep, bpos
    real scalar thr, top, show, i, j, k, K, nmiss, nover, nnew, nvan, nflip, ntot, mape, kl, imb, alerts, n, ri, cj
    sam = st_local("sam")
    bench = st_local("benchmark")
    N = st_matrix(sam)
    B = st_matrix(bench)
    nn = st_matrixrowstripe(sam)[., 2]'
    bn = st_matrixrowstripe(bench)[., 2]'
    thr = strtoreal(st_local("threshold"))
    top = strtoreal(st_local("top"))
    show = (st_local("table") == "")
    keep = J(1, 0, .)
    bpos = J(1, 0, .)
    newacc = J(1, 0, "")
    lostacc = J(1, 0, "")
    for (i = 1; i <= cols(nn); i++) {
        k = _cgemod_find(nn[i], bn, J(1, 0, ""))
        if (k) {
            keep = (keep, i)
            bpos = (bpos, k)
        }
        else newacc = (newacc, nn[i])
    }
    for (i = 1; i <= cols(bn); i++) if (!_cgemod_find(bn[i], nn, J(1, 0, ""))) lostacc = (lostacc, bn[i])
    nmiss = cols(newacc) + cols(lostacc)
    if (cols(keep) == 0) {
        errprintf("%s and %s have no accounts in common\n", sam, bench)
        exit(459)
    }
    Nc = N[keep, keep]
    Bc = B[bpos, bpos]
    cn = nn[keep]
    K = cols(keep)
    nzB = (Bc :!= 0)
    nzN = (Nc :!= 0)
    pct = editmissing(100 :* (Nc - Bc) :/ abs(Bc), 0) :* nzB
    nover = sum((abs(pct) :> thr) :& nzB)
    nnew = sum(nzN :& (1 :- nzB))
    nvan = sum(nzB :& (1 :- nzN))
    nflip = sum(nzB :& nzN :& (sign(Nc) :!= sign(Bc)))
    mape = sum(abs(pct))/max((1, sum(nzB)))
    p = abs(Nc) :/ sum(abs(Nc))
    q = abs(Bc) :/ sum(abs(Bc))
    kl = sum(editmissing(p :* ln(p :/ q), 0))
    tN = (rowsum(Nc) + colsum(Nc)') :/ 2
    tB = (rowsum(Bc) + colsum(Bc)') :/ 2
    tpct = editmissing(100 :* (tN :/ tB :- 1), 0)
    ntot = sum(abs(tpct) :> thr)
    imb = max(abs(rowsum(N) - colsum(N)'))
    alerts = nover + nnew + nvan + nflip + ntot + nmiss + (imb > 1e-6*max((1, sum(abs(N)))))
    st_local("alerts", strofreal(alerts))
    st_local("kl", strtrim(strofreal(kl, "%21.0g")))
    st_local("mape", strtrim(strofreal(mape, "%21.0g")))
    st_local("nover", strofreal(nover))
    st_local("nnew", strofreal(nnew))
    st_local("nvan", strofreal(nvan))
    st_local("nflip", strofreal(nflip))
    st_local("ntot", strofreal(ntot))
    st_local("nmiss", strofreal(nmiss))
    st_local("imb", strtrim(strofreal(imb, "%21.0g")))
    if (!show) return
    printf("\n{txt}cgemod sammonitor: {res}%s{txt} against benchmark {res}%s{txt} (threshold %g%%)\n", sam, bench, thr)
    printf("{txt}status: %s\n", (alerts ? "{err}ALERT (" + strofreal(alerts) + " flag(s))" : "{res}OK"))
    printf("{txt}{hline 46}{c TT}{hline 18}\n")
    printf("{txt}%-46s{c |}%12s%6s\n", "Monitor", "Value", "Flag")
    printf("{txt}{hline 46}{c +}{hline 18}\n")
    printf("{txt}%-46s{c |}{res}%12.6g%6s\n", "Kullback-Leibler divergence of structure", kl, "")
    printf("{txt}%-46s{c |}{res}%12.4f%6s\n", "Mean absolute % deviation of cells", mape, "")
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "Cells deviating more than threshold", nover, (nover ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "New nonzero cells", nnew, (nnew ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "Vanished cells", nvan, (nvan ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "Sign changes", nflip, (nflip ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "Account totals deviating more than threshold", ntot, (ntot ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.0f{err}%6s\n", "Accounts added or missing", nmiss, (nmiss ? "<" : ""))
    printf("{txt}%-46s{c |}{res}%12.6g{err}%6s\n", "Largest row-column gap in new SAM", imb, (imb > 1e-6*max((1, sum(abs(N)))) ? "<" : ""))
    printf("{txt}{hline 46}{c BT}{hline 18}\n")
    if (cols(newacc)) printf("{txt}accounts not in the benchmark: {res}%s\n", invtokens(newacc))
    if (cols(lostacc)) printf("{txt}benchmark accounts missing: {res}%s\n", invtokens(lostacc))
    sc = vec(abs(pct) + 1e6 :* (nzN :& (1 :- nzB)) + 1e6 :* (nzB :& (1 :- nzN)))
    ord = order(-sc, 1)
    n = min((top, sum(sc :> thr)))
    if (n) {
        printf("\n{txt}Largest cell drifts\n")
        printf("{txt}{hline 30}{c TT}{hline 38}\n")
        printf("{txt}%-30s{c |}%13s%13s%12s\n", "Cell (payer -> receiver)", "Benchmark", "New", "% dev.")
        printf("{txt}{hline 30}{c +}{hline 38}\n")
        for (i = 1; i <= n; i++) {
            k = ord[i]
            cj = ceil(k/K)
            ri = k - (cj - 1)*K
            flag = (Bc[ri, cj] == 0 ? "new" : (Nc[ri, cj] == 0 ? "gone" : strofreal(pct[ri, cj], "%12.2f")))
            printf("{txt}%-30s{c |}{res}%13.4f%13.4f%12s\n", abbrev(cn[cj] + " -> " + cn[ri], 30), Bc[ri, cj], Nc[ri, cj], flag)
        }
        printf("{txt}{hline 30}{c BT}{hline 38}\n")
    }
    if (ntot) {
        printf("\n{txt}Account totals beyond the threshold\n")
        for (i = 1; i <= K; i++) {
            if (abs(tpct[i]) > thr) printf("{txt}   %-22s {res}%12.4f -> %12.4f  (%8.2f%%)\n", abbrev(cn[i], 22), tB[i], tN[i], tpct[i])
        }
    }
}

void _cgemod_mat2data(string scalar mat)
{
    real matrix X
    string colvector rn, cn
    real scalar j
    X = st_matrix(mat)
    rn = st_matrixrowstripe(mat)[., 2]
    cn = st_matrixcolstripe(mat)[., 2]
    st_addobs(rows(X))
    (void) st_addvar("str32", "account")
    st_sstore(., "account", rn)
    for (j = 1; j <= cols(X); j++) {
        (void) st_addvar("double", cn[j])
        st_store(., cn[j], X[., j])
    }
}

void _cgemod_matdiff(string scalar a, string scalar b, string scalar out)
{
    real matrix A, B
    string rowvector na, nb
    real rowvector pos
    real scalar i, k
    A = st_matrix(a)
    B = st_matrix(b)
    na = st_matrixrowstripe(a)[., 2]'
    nb = st_matrixrowstripe(b)[., 2]'
    pos = J(1, cols(na), .)
    for (i = 1; i <= cols(na); i++) {
        k = _cgemod_find(na[i], nb, J(1, 0, ""))
        if (!k) {
            errprintf("account %s of %s is not in %s\n", na[i], a, b)
            exit(459)
        }
        pos[i] = k
    }
    st_matrix(out, A - B[pos, pos])
    st_matrixrowstripe(out, (J(cols(na), 1, ""), na'))
    st_matrixcolstripe(out, (J(cols(na), 1, ""), na'))
}

void _cgemod_infodata(string scalar mat, string scalar prior, string scalar stamp)
{
    real matrix X
    string colvector it, va
    X = st_matrix(mat)
    it = ("SAM" \ "Exported" \ "Accounts" \ "Total transactions" \ "Largest row-column gap" \ "Negative cells" \ "Prior SAM")
    va = (mat \ stamp \ strofreal(rows(X)) \ strofreal(sum(rowsum(X)), "%21.6f") \
          strofreal(max(abs(rowsum(X) - colsum(X)')), "%12.3e") \ strofreal(sum(X :< 0)) \ (prior != "" ? prior : "none"))
    st_addobs(rows(it))
    (void) st_addvar("str32", "item")
    (void) st_addvar("str64", "value")
    st_sstore(., "item", it)
    st_sstore(., "value", va)
}

void _cgemod_gams(string scalar mat, string scalar fn, real scalar rep, string scalar stamp)
{
    real matrix X
    string colvector rn
    real scalar fh, K, i, j
    X = st_matrix(mat)
    rn = st_matrixrowstripe(mat)[., 2]
    K = rows(X)
    if (fileexists(fn)) {
        if (rep) unlink(fn)
        else {
            errprintf("file %s already exists; specify replace\n", fn)
            exit(602)
        }
    }
    fh = fopen(fn, "w")
    fput(fh, "* Social accounting matrix " + mat + ", written by cgemod on " + stamp)
    fput(fh, "Set ac 'SAM accounts' /")
    for (i = 1; i <= K; i++) fput(fh, "    " + rn[i] + (i < K ? "," : ""))
    fput(fh, "/;")
    fput(fh, "Alias (ac, acp);")
    fput(fh, "Parameter SAM(ac,acp) 'row account receives from column account' /")
    for (i = 1; i <= K; i++) {
        for (j = 1; j <= K; j++) {
            if (X[i, j] != 0) fput(fh, "    " + rn[i] + "." + rn[j] + "    " + strtrim(strofreal(X[i, j], "%21.0g")))
        }
    }
    fput(fh, "/;")
    fclose(fh)
}

/* --------------------------------------------- SAM import and replication */
void _cgemod_samread(string scalar name, real scalar lc)
{
    string matrix D
    string rowvector cl
    string matrix rl
    real rowvector ci, cord
    real colvector ri
    real matrix V, S
    real scalar i, j, k, p
    string scalar l
    D = st_sdata(., .)
    if (rows(D) < 3 | cols(D) < 3) {
        errprintf("the file does not look like a SAM (need a label row, a label column and data)\n")
        exit(459)
    }
    if (lc < 1 | lc >= cols(D)) {
        errprintf("labelcol() must point to a column before the data\n")
        exit(198)
    }
    cl = strtrim(D[1, .])
    rl = strtrim(D[., lc])
    ci = J(1, 0, .)
    ri = J(0, 1, .)
    for (j = lc + 1; j <= cols(D); j++) {
        l = strlower(cl[j])
        if (cl[j] != "" & l != "total" & l != "totals" & l != "sum") ci = (ci, j)
    }
    for (i = 2; i <= rows(D); i++) {
        l = strlower(rl[i])
        if (rl[i] != "" & l != "total" & l != "totals" & l != "sum") ri = (ri \ i)
    }
    V = J(rows(ri), cols(ci), 0)
    for (i = 1; i <= rows(ri); i++) {
        for (j = 1; j <= cols(ci); j++) {
            l = subinstr(subinstr(strtrim(D[ri[i], ci[j]]), ",", "", .), " ", "", .)
            if (l != "" & l != "-" & l != ".") {
                V[i, j] = strtoreal(l)
                if (V[i, j] >= .) {
                    errprintf("cell (%s, %s) is not numeric: %s\n", rl[ri[i]], cl[ci[j]], D[ri[i], ci[j]])
                    exit(459)
                }
            }
        }
    }
    cl = cl[ci]
    rl = rl[ri]'
    for (j = 1; j <= cols(cl); j++) cl[j] = strtoname(cl[j])
    for (i = 1; i <= cols(rl); i++) rl[i] = strtoname(rl[i])
    if (cols(cl) != cols(rl)) {
        errprintf("the SAM has %g row accounts but %g column accounts\n", cols(rl), cols(cl))
        exit(459)
    }
    k = cols(rl)
    if (rows(uniqrows(rl')) != k) {
        errprintf("row account labels are not unique\n")
        exit(459)
    }
    cord = J(1, k, .)
    for (i = 1; i <= k; i++) {
        p = _cgemod_find(rl[i], cl, J(1, 0, ""))
        if (!p) {
            errprintf("row account %s has no matching column\n", rl[i])
            exit(459)
        }
        cord[i] = p
    }
    S = V[., cord]
    st_matrix(name, S)
    st_matrixrowstripe(name, (J(k, 1, ""), rl'))
    st_matrixcolstripe(name, (J(k, 1, ""), rl'))
    printf("{txt}read SAM {res}%s{txt}: %g accounts\n", name, k)
}

void _cgemod_sammerge(string scalar name, string scalar spec)
{
    real matrix S
    string rowvector nm, t, keep
    real scalar i, p, a, b, k
    real rowvector kp
    S = st_matrix(name)
    nm = st_matrixrowstripe(name)[., 2]'
    t = tokens(spec)
    for (i = 1; i <= cols(t); i++) {
        p = strpos(t[i], "=")
        if (!p) {
            errprintf("merge(): use SOURCE=DESTINATION, e.g. merge(DSTK=S_I)\n")
            exit(198)
        }
        a = _cgemod_find(strtoname(substr(t[i], 1, p - 1)), nm, J(1, 0, ""))
        b = _cgemod_find(strtoname(substr(t[i], p + 1, .)), nm, J(1, 0, ""))
        if (!a | !b | a == b) {
            errprintf("merge(): cannot merge %s\n", t[i])
            exit(111)
        }
        S[b, .] = S[b, .] + S[a, .]
        S[., b] = S[., b] + S[., a]
        S[a, .] = J(1, cols(S), 0)
        S[., a] = J(rows(S), 1, 0)
        S[b, b] = 0
        nm[a] = ""
        printf("{txt}merged %s into %s\n", substr(t[i], 1, p - 1), substr(t[i], p + 1, .))
    }
    kp = selectindex(nm :!= "")
    S = S[kp, kp]
    nm = nm[kp]
    k = cols(nm)
    st_matrix(name, S)
    st_matrixrowstripe(name, (J(k, 1, ""), nm'))
    st_matrixcolstripe(name, (J(k, 1, ""), nm'))
}

/* aggregate SAM accounts with a mapping file: column 1 = account, column 2 = new account */
void _cgemod_sammap(string scalar name)
{
    string matrix D
    string colvector src, dst
    string rowvector nm, nw, ord
    string scalar a, b
    real matrix S, G, V
    real scalar k, m, i, j, p, nmap, first
    D = st_sdata(., .)
    if (cols(D) < 2 | rows(D) < 1) {
        errprintf("map(): the mapping file needs two columns: account and new account\n")
        exit(459)
    }
    first = 1
    a = strlower(strtrim(D[1, 1]))
    if (a == "source" | a == "from" | a == "old" | a == "account" | a == "original") first = 2
    src = J(0, 1, "")
    dst = J(0, 1, "")
    for (i = first; i <= rows(D); i++) {
        a = strtrim(D[i, 1])
        b = strtrim(D[i, 2])
        if (a == "" | b == "") continue
        src = src \ strtoname(a)
        dst = dst \ strtoname(b)
    }
    nmap = rows(src)
    if (nmap == 0) {
        errprintf("map(): no account pairs found in the mapping file\n")
        exit(459)
    }
    S = st_matrix(name)
    nm = st_matrixrowstripe(name)[., 2]'
    k = cols(nm)
    nw = nm
    for (i = 1; i <= nmap; i++) {
        p = _cgemod_find(src[i], nm, J(1, 0, ""))
        if (!p) {
            errprintf("map(): account %s is not in the SAM\n", src[i])
            exit(111)
        }
        nw[p] = dst[i]
    }
    ord = J(1, 0, "")
    for (j = 1; j <= k; j++) {
        if (!_cgemod_in(ord, nw[j])) ord = (ord, nw[j])
    }
    m = cols(ord)
    G = J(m, k, 0)
    for (j = 1; j <= k; j++) {
        p = _cgemod_find(nw[j], ord, J(1, 0, ""))
        G[p, j] = 1
    }
    V = G*S*G'
    _diag(V, 0)
    st_matrix(name, V)
    st_matrixrowstripe(name, (J(m, 1, ""), ord'))
    st_matrixcolstripe(name, (J(m, 1, ""), ord'))
    printf("{txt}map(): %g mapping rows; %g accounts aggregated into %g (flows inside a new account removed)\n",
           nmap, k, m)
}

/* read the SAM parameter of a GAMS include file: lines "row.col value" between "Parameter ... /" and "/" */
void _cgemod_gamsread(string scalar name, string scalar fn)
{
    string colvector L, R, C
    string rowvector nm
    string scalar l, ll
    real colvector V
    real matrix S
    real scalar i, st, k, a, b
    L = cat(fn)
    st = 0
    R = J(0, 1, "")
    C = J(0, 1, "")
    V = J(0, 1, .)
    for (i = 1; i <= rows(L); i++) {
        l = strtrim(L[i])
        if (l == "" | substr(l, 1, 1) == "*") continue
        ll = strlower(l)
        if (st == 0) {
            if (substr(ll, 1, 9) == "parameter") {
                st = (strpos(l, "/") ? 2 : 1)
            }
            continue
        }
        if (st == 1) {
            if (substr(l, 1, 1) == "/") st = 2
            continue
        }
        if (substr(l, 1, 1) == "/") break
        if (ustrregexm(l, "^'?([A-Za-z0-9_\-]+)'?\s*\.\s*'?([A-Za-z0-9_\-]+)'?\s+([-+0-9.eE]+)")) {
            R = R \ strtoname(ustrregexs(1))
            C = C \ strtoname(ustrregexs(2))
            V = V \ strtoreal(ustrregexs(3))
        }
    }
    if (rows(V) == 0) {
        errprintf("no SAM entries (row.column value) found in a Parameter block of %s\n", fn)
        exit(459)
    }
    nm = J(1, 0, "")
    for (i = 1; i <= rows(V); i++) {
        if (!_cgemod_in(nm, R[i])) nm = (nm, R[i])
        if (!_cgemod_in(nm, C[i])) nm = (nm, C[i])
    }
    k = cols(nm)
    S = J(k, k, 0)
    for (i = 1; i <= rows(V); i++) {
        a = _cgemod_find(R[i], nm, J(1, 0, ""))
        b = _cgemod_find(C[i], nm, J(1, 0, ""))
        S[a, b] = S[a, b] + V[i]
    }
    st_matrix(name, S)
    st_matrixrowstripe(name, (J(k, 1, ""), nm'))
    st_matrixcolstripe(name, (J(k, 1, ""), nm'))
    printf("{txt}read SAM {res}%s{txt} from GAMS file: %g accounts, %g non-zero cells\n", name, k, rows(V))
}

real scalar _cgemod_starts(string scalar l, string rowvector pre)
{
    real scalar i
    for (i = 1; i <= cols(pre); i++) if (substr(l, 1, strlen(pre[i])) == pre[i]) return(1)
    return(0)
}

string scalar _cgemod_pick(string rowvector nm, real rowvector mask)
{
    string scalar out
    real scalar i
    out = ""
    for (i = 1; i <= cols(nm); i++) if (mask[i]) out = out + (out == "" ? "" : " ") + nm[i]
    return(out)
}

real scalar _cgemod_ug(real scalar i, real scalar j, real scalar s)
{
    return(mod(i*7919 + j*104729 + s*1299709, 1000)/1000)
}

void _cgemod_samgen(real scalar n, real scalar H, real scalar sd, string scalar name)
{
    real matrix S, V, a, psi
    real colvector X, sl, M, E, TAR, STX, Q, FD, al, be, Gv, Iv, Cc, lam, kap, Y, piv
    real rowvector iA, iC, iH
    real scalar k, iL, iK, g, ts, tt, td, si, rw, i, j, h, FDt, YL, YK, TRt, REMt
    string rowvector acc
    acc = J(1, 0, "")
    for (i = 1; i <= n; i++) acc = acc, "A_" + strofreal(i)
    for (i = 1; i <= n; i++) acc = acc, "C_" + strofreal(i)
    acc = acc, ("LAB", "CAP")
    for (h = 1; h <= H; h++) acc = acc, "HH_" + strofreal(h)
    acc = acc, ("GOV", "TAX_SAL", "TAX_TAR", "TAX_DIR", "S_I", "ROW")
    k = cols(acc)
    S = J(k, k, 0)
    iA = 1..n
    iC = (n + 1)..(2*n)
    iL = 2*n + 1
    iK = 2*n + 2
    iH = (2*n + 3)..(2*n + 2 + H)
    g = 2*n + H + 3
    ts = g + 1
    tt = g + 2
    td = g + 3
    si = g + 4
    rw = g + 5
    X = J(n, 1, .)
    sl = J(n, 1, .)
    M = J(n, 1, .)
    E = J(n, 1, .)
    al = J(n, 1, .)
    be = J(n, 1, .)
    V = J(n, n, .)
    for (i = 1; i <= n; i++) {
        X[i] = 100*(1 + _cgemod_ug(i, 0, sd))
        sl[i] = 0.4 + 0.3*_cgemod_ug(i, 1, sd)
        al[i] = 0.75 + 0.5*_cgemod_ug(i, 4, sd)
        be[i] = 0.75 + 0.5*_cgemod_ug(i, 5, sd)
    }
    for (i = 1; i <= n; i++) {
        M[i] = X[i]*(0.1 + 0.2*_cgemod_ug(i, 2, sd))
        E[i] = X[i]*(0.05 + 0.2*_cgemod_ug(i, 3, sd))
        for (j = 1; j <= n; j++) V[j, i] = 0.2 + _cgemod_ug(j, i, sd) + (i == j ? 1.5 : 0)
    }
    a = 0.4 :* V :/ colsum(V)
    S[iC, iA] = a :* X'
    S[iL, iA] = (0.6 :* X :* sl)'
    S[iK, iA] = (0.6 :* X :* (1 :- sl))'
    S[iA, iC] = diag(X)
    TAR = 0.1 :* M
    STX = 0.05 :* (X + M + TAR)
    S[rw, iC] = M'
    S[tt, iC] = TAR'
    S[ts, iC] = STX'
    S[iC, rw] = E
    Q = X + M + TAR + STX
    FD = Q - rowsum(S[iC, iA]) - E
    FDt = sum(FD)
    Gv = 0.15*FDt :* FD :* al :/ sum(FD :* al)
    Iv = 0.25*FDt :* FD :* be :/ sum(FD :* be)
    Cc = FD - Gv - Iv
    if (min(Cc) <= 0) {
        errprintf("samgen: household consumption is not positive for this seed; try another seed()\n")
        exit(459)
    }
    S[iC, g] = Gv
    S[iC, si] = Iv
    lam = J(H, 1, .)
    kap = J(H, 1, .)
    for (h = 1; h <= H; h++) {
        lam[h] = 0.5 + _cgemod_ug(h, 6, sd)
        kap[h] = 0.5 + _cgemod_ug(h, 7, sd)
    }
    lam = lam :/ sum(lam)
    kap = kap :/ sum(kap)
    YL = sum(S[iL, .])
    YK = sum(S[iK, .])
    S[iH, iL] = lam :* YL
    S[iH, iK] = kap :* YK
    TRt = 0.02*(YL + YK)
    REMt = 0.01*(YL + YK)
    S[iH, g] = TRt :* lam
    S[iH, rw] = REMt :* kap
    Y = rowsum(S[iH, .])
    piv = Y :/ sum(Y)
    psi = J(n, H, .)
    for (i = 1; i <= n; i++) {
        for (h = 1; h <= H; h++) psi[i, h] = piv[h]*(0.9 + 0.2*_cgemod_ug(i, 10 + h, sd))
    }
    psi = psi :/ rowsum(psi)
    S[iC, iH] = Cc :* psi
    S[td, iH] = 0.1 :* Y'
    S[si, iH] = Y' - colsum(S[., iH])
    if (min(S[si, iH]) <= 0) {
        errprintf("samgen: household savings are not positive for this seed; try another seed()\n")
        exit(459)
    }
    S[g, ts] = sum(STX)
    S[g, tt] = sum(TAR)
    S[g, td] = sum(S[td, .])
    S[si, g] = sum(S[g, .]) - sum(S[., g])
    S[si, rw] = sum(S[rw, .]) - sum(S[., rw])
    st_matrix(name, S)
    st_matrixrowstripe(name, (J(k, 1, ""), acc'))
    st_matrixcolstripe(name, (J(k, 1, ""), acc'))
    st_local("naccounts", strofreal(k))
    st_local("samtotal", strtrim(strofreal(sum(S), "%21.0g")))
    printf("{txt}synthetic SAM {res}%s{txt}: %g activities, %g commodities, %g households, %g accounts, total %s\n",
           name, n, n, H, k, strtrim(strofreal(sum(S), "%12.2f")))
}

void _cgemod_samroles(string scalar name)
{
    string rowvector nm, lw, role, keys, labs
    string scalar l, rest
    real scalar k, i, j, npair
    transmorphic R
    pointer() scalar p
    nm = st_matrixrowstripe(name)[., 2]'
    k = cols(nm)
    lw = strlower(nm)
    role = J(1, k, "")
    for (i = 1; i <= k; i++) {
        l = lw[i]
        if (anyof(("gov", "govt", "gvt", "government", "g"), l)) role[i] = "government"
        else if (anyof(("row", "rw", "world", "rest", "rest_of_world", "restofworld", "foreign"), l)) role[i] = "row"
        else if (anyof(("s_i", "si", "sav", "saving", "savings", "inv", "invest", "investment", "s_inv", "sav_inv", "kap", "capacc"), l)) role[i] = "savinv"
        else if (anyof(("trc", "marg", "margin", "margins", "trade_margin", "tmarg"), l)) role[i] = "margins"
        else if (_cgemod_starts(l, ("ent", "firm", "corp"))) role[i] = "enterprises"
        else if (_cgemod_starts(l, ("mtax", "imptax", "tariff", "tar_", "duty", "tax_tar", "tax_imp", "tax_m"))) role[i] = "tariff"
        else if (_cgemod_starts(l, ("etax", "exptax", "tax_exp", "tax_e"))) role[i] = "exptax"
        else if (strpos(l, "tax") | strpos(l, "vat") | _cgemod_starts(l, ("tx_", "subs"))) role[i] = "taxes"
        else if (_cgemod_starts(l, ("hh", "hhd", "h_", "hous", "rur", "urb"))) role[i] = "households"
        else if (_cgemod_starts(l, ("lab", "cap", "land", "f_", "fac", "wag", "prof", "skill", "unsk", "lnd"))) role[i] = "factors"
        else if (_cgemod_starts(l, ("a_", "act_"))) role[i] = "activities"
        else if (_cgemod_starts(l, ("c_", "com_"))) role[i] = "commodities"
        else if (_cgemod_starts(l, ("dstk", "stk", "stock", "chstk"))) role[i] = "stocks"
    }
    npair = 0
    for (i = 1; i <= k; i++) {
        if (role[i] != "") continue
        l = lw[i]
        rest = substr(l, 2, .)
        if (substr(l, 1, 1) == "a" & rest != "") {
            j = _cgemod_find("c" + rest, lw, J(1, 0, ""))
            if (j) {
                if (role[j] == "") {
                    role[i] = "activities"
                    role[j] = "commodities"
                    npair++
                }
            }
        }
    }
    if (npair) {
        for (i = 1; i <= k; i++) {
            if (role[i] != "") continue
            if (substr(lw[i], 1, 1) == "c") role[i] = "commodities"
            else if (substr(lw[i], 1, 1) == "f") role[i] = "factors"
            else if (substr(lw[i], 1, 1) == "h") role[i] = "households"
        }
    }
    keys = ("activities", "commodities", "factors", "households", "enterprises", "government", "row", "savinv",
            "taxes", "tariff", "exptax", "margins", "stocks")
    labs = ("Activities", "Commodities", "Factors", "Households", "Enterprises", "Government", "Rest of world",
            "Savings-investment", "Taxes (all)", "  of which tariffs", "  of which export", "Trade margins", "Stock changes")
    R = asarray_create()
    printf("\n{txt}Detected account roles (check them; override any role in {cmd:cgemod calibrate})\n")
    printf("{txt}{hline 20}{c TT}{hline 57}\n")
    for (j = 1; j <= cols(keys); j++) {
        rest = _cgemod_pick(nm, role :== keys[j])
        if (keys[j] == "taxes") rest = _cgemod_pick(nm, (role :== "taxes") :| (role :== "tariff") :| (role :== "exptax"))
        asarray(R, keys[j], rest)
        st_local(keys[j], rest)
        printf("{txt}%-20s{c |} {res}%s\n", labs[j], (rest == "" ? "{txt}(none)" : rest))
    }
    st_local("unassigned", _cgemod_pick(nm, role :== ""))
    if (st_local("unassigned") != "") printf("{txt}%-20s{c |} {err}%s\n", "Unassigned", st_local("unassigned"))
    printf("{txt}{hline 20}{c BT}{hline 57}\n")
    p = findexternal("_cgemod_roles")
    if (p == NULL) {
        p = crexternal("_cgemod_roles")
        *p = asarray_create()
    }
    asarray(*p, name, R)
}

void _cgemod_getroles(string scalar name)
{
    pointer() scalar p
    transmorphic R
    string rowvector keys
    real scalar j
    p = findexternal("_cgemod_roles")
    if (p == NULL) return
    if (!asarray_contains(*p, name)) return
    R = asarray(*p, name)
    keys = ("activities", "commodities", "factors", "households", "enterprises", "government", "row", "savinv",
            "taxes", "tariff", "exptax", "margins", "stocks")
    for (j = 1; j <= cols(keys); j++) if (st_local(keys[j]) == "") st_local(keys[j], asarray(R, keys[j]))
    printf("{txt}account roles taken from {cmd:cgemod samimport} for %s\n", name)
}

void _cgemod_storepov(string rowvector hh, real colvector evpct, real colvector rcons, real colvector pind,
                      real colvector econs, string rowvector fac, real colvector yfpct, real colvector wfpct, real scalar cpipct)
{
    transmorphic L
    pointer() scalar p
    L = asarray_create()
    asarray(L, "hh", hh)
    asarray(L, "evpct", evpct)
    asarray(L, "rcons", rcons)
    asarray(L, "pind", pind)
    asarray(L, "econs", econs)
    asarray(L, "fac", fac)
    asarray(L, "yfpct", yfpct)
    asarray(L, "wfpct", wfpct)
    asarray(L, "cpipct", cpipct)
    p = findexternal("_cgemod_pov")
    if (p == NULL) p = crexternal("_cgemod_pov")
    *p = L
}

void _cgemod_storelast(real matrix Mac, real matrix Act, real matrix Com, real matrix Pri, real matrix Fac,
                       real matrix Hh, string rowvector act, string rowvector com, string rowvector fac,
                       string rowvector hh, string rowvector mnm)
{
    transmorphic L
    pointer() scalar p
    real scalar i, j
    string rowvector ac, cc, pc
    L = asarray_create()
    for (i = 1; i <= cols(mnm); i++) asarray(L, mnm[i], Mac[i, 3])
    ac = ("X", "VA", "PA", "XM")
    cc = ("QX", "QD", "QE", "QM", "QQ")
    pc = ("PD", "PX", "PQ", "PE", "PM")
    for (i = 1; i <= cols(act); i++) for (j = 1; j <= 4; j++) asarray(L, ac[j] + "_" + act[i], Act[i, j])
    for (i = 1; i <= cols(com); i++) {
        for (j = 1; j <= 5; j++) {
            asarray(L, cc[j] + "_" + com[i], Com[i, j])
            asarray(L, pc[j] + "_" + com[i], Pri[i, j])
        }
    }
    for (i = 1; i <= cols(fac); i++) {
        asarray(L, "EMP_" + fac[i], Fac[i, 2])
        asarray(L, "WF_" + fac[i], Fac[i, 3])
        asarray(L, "YF_" + fac[i], Fac[i, 4])
    }
    for (i = 1; i <= cols(hh); i++) {
        asarray(L, "YH_" + hh[i], Hh[i, 1])
        asarray(L, "EH_" + hh[i], Hh[i, 2])
        asarray(L, "EV_" + hh[i], Hh[i, 3])
        asarray(L, "EVPCT_" + hh[i], Hh[i, 4])
    }
    p = findexternal("_cgemod_last")
    if (p == NULL) p = crexternal("_cgemod_last")
    *p = L
}

void _cgemod_compare(string scalar vv, string scalar vl, real scalar tol, real scalar top, real scalar show)
{
    transmorphic L
    string colvector nm
    real colvector ext, own, dif, ord
    real scalar n, i, nmiss, nfail, ncomp, k
    string scalar key
    L = *findexternal("_cgemod_last")
    nm = strtrim(st_sdata(., vv))
    ext = st_data(., vl)
    n = rows(nm)
    own = J(n, 1, .)
    nmiss = 0
    for (i = 1; i <= n; i++) {
        key = nm[i]
        if (asarray_contains(L, key)) own[i] = asarray(L, key)
        else if (asarray_contains(L, strupper(key))) own[i] = asarray(L, strupper(key))
        else nmiss++
    }
    dif = abs(own - ext)
    ncomp = sum((own :< .) :& (ext :< .))
    nfail = sum((dif :> tol) :& (dif :< .))
    st_local("ncomp", strofreal(ncomp))
    st_local("nmiss", strofreal(nmiss))
    st_local("nfail", strofreal(nfail))
    st_local("maxd", (ncomp ? strtrim(strofreal(max(select(dif, dif :< .)), "%21.0g")) : "."))
    st_local("worst", "")
    if (ncomp) {
        ord = order(-editmissing(dif, -1), 1)
        st_local("worst", nm[ord[1]])
    }
    if (!show) return
    printf("\n{txt}cgemod compare: %g results compared, %g not found, %g differ by more than %g\n", ncomp, nmiss, nfail, tol)
    printf("{txt}status: %s\n", (nfail == 0 & ncomp > 0 ? "{res}REPLICATED" : "{err}DIFFERENCES"))
    if (!ncomp) return
    printf("{txt}{hline 26}{c TT}{hline 39}\n")
    printf("{txt}%-26s{c |}%13s%13s%13s\n", "Result", "cgemod", "External", "Difference")
    printf("{txt}{hline 26}{c +}{hline 39}\n")
    k = min((top, ncomp))
    for (i = 1; i <= k; i++) {
        printf("{txt}%-26s{c |}{res}%13.5f%13.5f%13.2e\n", abbrev(nm[ord[i]], 26), own[ord[i]], ext[ord[i]], own[ord[i]] - ext[ord[i]])
    }
    printf("{txt}{hline 26}{c BT}{hline 39}\n")
    if (nmiss) printf("{txt}names not found follow the pattern RGDP, X_<activity>, QM_<commodity>, PQ_<commodity>, WF_<factor>, EV_<household>\n")
}

/* --------------------------------------------- poverty microsimulation */
real rowvector _cgemod_fgt(real colvector y, real colvector z, real colvector w)
{
    real colvector g, p, L, ys, ws, o
    real scalar W, gini
    g = (z :- y) :/ z
    g = g :* (y :< z)
    W = sum(w)
    o = order(y, 1)
    ys = y[o]
    ws = w[o]
    p = runningsum(ws) :/ W
    L = runningsum(ws :* ys) :/ sum(ws :* ys)
    gini = 1 - sum((p - (0 \ p[|1 \ rows(p) - 1|])) :* (L + (0 \ L[|1 \ rows(L) - 1|])))
    return((100*sum(w :* (y :< z))/W, 100*sum(w :* g)/W, 100*sum(w :* g :^ 2)/W, 100*gini, sum(w :* y)/W))
}

void _cgemod_poverty()
{
    transmorphic P
    string scalar touse, gv, meth, lv, mp, byv
    string rowvector hh, hhl, fac, sf, tk, labs
    string colvector gs
    real colvector y, z, w, hs, gi, fct, evp, rc, pi, yf, src, oldi, newi, tr, ynew, bc, sel
    real matrix SR, TRm, Tab, Grp, By
    real scalar n, i, j, k, ng, cpi, nb, b, show
    P = *findexternal("_cgemod_pov")
    touse = st_local("touse")
    gv = st_local("group")
    meth = st_local("method")
    show = (st_local("table") == "")
    hh = asarray(P, "hh")
    hhl = strlower(hh)
    evp = asarray(P, "evpct")
    rc = asarray(P, "rcons")
    pi = asarray(P, "pind")
    fac = asarray(P, "fac")
    yf = asarray(P, "yfpct")
    cpi = asarray(P, "cpipct")
    y = st_data(., st_local("welfare"), touse)
    n = rows(y)
    w = (st_local("weight") != "" ? st_data(., st_local("weight"), touse) : J(n, 1, 1))
    if (st_local("hhsize") != "") w = w :* st_data(., st_local("hhsize"), touse)
    lv = st_local("linevar")
    z = (lv != "" ? st_data(., lv, touse) : J(n, 1, strtoreal(st_local("line"))))
    if (min(z) <= 0 | min(w) < 0) {
        errprintf("poverty lines must be positive and weights non-negative\n")
        exit(459)
    }
    /* map survey groups to SAM households */
    gi = J(n, 1, .)
    if (st_isstrvar(gv)) {
        gs = st_sdata(., gv, touse)
        for (i = 1; i <= n; i++) {
            k = _cgemod_find(strlower(strtoname(strtrim(gs[i]))), hhl, J(1, 0, ""))
            if (!k) {
                errprintf("survey group %s is not a SAM household (%s)\n", gs[i], invtokens(hh))
                exit(459)
            }
            gi[i] = k
        }
    }
    else {
        mp = st_local("map")
        if (mp == "") {
            errprintf("numeric group(): give map(), e.g. map(1=HH_RUR 2=HH_URB)\n")
            exit(198)
        }
        tk = tokens(mp)
        bc = st_data(., gv, touse)
        for (j = 1; j <= cols(tk); j++) {
            k = strpos(tk[j], "=")
            b = 0
            if (k) b = _cgemod_find(strlower(strtoname(substr(tk[j], k + 1, .))), hhl, J(1, 0, ""))
            if (!k | !b | strtoreal(substr(tk[j], 1, k - 1)) >= .) {
                errprintf("map(): cannot read %s\n", tk[j])
                exit(198)
            }
            for (i = 1; i <= n; i++) if (bc[i] == strtoreal(substr(tk[j], 1, k - 1))) gi[i] = b
        }
        for (i = 1; i <= n; i++) {
            if (gi[i] >= .) {
                errprintf("map(): survey group code %g is not mapped to a SAM household\n", bc[i])
                exit(198)
            }
        }
    }
    /* household-specific welfare change */
    if (meth == "ev") fct = 1 :+ evp[gi] :/ 100
    else if (meth == "real") fct = 1 :+ rc[gi] :/ 100
    else {
        sf = tokens(st_local("srcfac"))
        SR = st_data(., tokens(st_local("srcvars")), touse)
        oldi = rowsum(SR)
        newi = J(n, 1, 0)
        for (j = 1; j <= cols(sf); j++) {
            k = _cgemod_find(strtoname(sf[j]), fac, J(1, 0, ""))
            if (!k) {
                errprintf("sources(): %s is not a factor of the model\n", sf[j])
                exit(111)
            }
            newi = newi + SR[., j] :* (1 + yf[k]/100)
        }
        if (st_local("transfers") != "") {
            TRm = st_data(., tokens(st_local("transfers")), touse)
            oldi = oldi + rowsum(TRm)
            newi = newi + rowsum(TRm) :* (1 + cpi/100)
        }
        fct = (newi :/ oldi) :/ (1 :+ pi[gi] :/ 100)
        fct = editmissing(fct, .)
        for (i = 1; i <= n; i++) if (oldi[i] <= 0 | fct[i] >= .) fct[i] = 1 + rc[gi[i]]/100
    }
    ynew = y :* fct
    Tab = (_cgemod_fgt(y, z, w) \ _cgemod_fgt(ynew, z, w))'
    Tab = (Tab, Tab[., 2] - Tab[., 1])
    labs = ("Headcount P0 (%)", "Poverty gap P1 (%)", "Severity P2 (%)", "Gini (x100)", "Mean welfare")
    _cgemod_post("__cgemod_pov", Tab, ("P0", "P1", "P2", "Gini", "mean")', ("before", "after", "change"))
    Grp = J(cols(hh), 4, .)
    for (k = 1; k <= cols(hh); k++) {
        sel = selectindex(gi :== k)
        if (rows(sel) == 0) continue
        Grp[k, 1] = _cgemod_fgt(y[sel], z[sel], w[sel])[1]
        Grp[k, 2] = _cgemod_fgt(ynew[sel], z[sel], w[sel])[1]
        Grp[k, 3] = 100*sum(w[sel])/sum(w)
        Grp[k, 4] = 100*(fct[sel]' * w[sel]/sum(w[sel]) - 1)
    }
    _cgemod_post("__cgemod_povgrp", Grp, hh', ("P0_before", "P0_after", "pop_share", "welfare_pct"))
    byv = st_local("bycode")
    nb = 0
    if (st_local("by") != "") {
        bc = st_data(., byv, touse)
        nb = max(bc)
        By = J(nb, 6, .)
        for (b = 1; b <= nb; b++) {
            sel = selectindex(bc :== b)
            By[b, 1..3] = (_cgemod_fgt(y[sel], z[sel], w[sel])[1], _cgemod_fgt(ynew[sel], z[sel], w[sel])[1], 0)
            By[b, 3] = By[b, 2] - By[b, 1]
            By[b, 4..6] = (_cgemod_fgt(y[sel], z[sel], w[sel])[4], _cgemod_fgt(ynew[sel], z[sel], w[sel])[4], 100*sum(w[sel])/sum(w))
        }
        st_matrix("__cgemod_povby", By)
        st_matrixcolstripe("__cgemod_povby", (J(6, 1, ""), ("P0_before", "P0_after", "P0_change", "Gini_before", "Gini_after", "pop_share")'))
        st_matrixrowstripe("__cgemod_povby", (J(nb, 1, ""), "g" :+ strofreal(1::nb)))
    }
    if (st_local("generate") != "") {
        (void) st_addvar("double", st_local("generate"))
        st_store(., st_local("generate"), touse, ynew)
    }
    st_local("npov", strofreal(n))
    if (!show) return
    printf("\n{txt}cgemod poverty: %g survey households, welfare change by %s\n", n,
           (meth == "ev" ? "equivalent variation of the SAM household group" :
           (meth == "real" ? "real consumption change of the SAM household group" :
            "income sources (factor incomes, CPI-indexed transfers) deflated by the group price index")))
    printf("{txt}{hline 26}{c TT}{hline 39}\n")
    printf("{txt}%-26s{c |}%13s%13s%13s\n", "Indicator", "Before", "After", "Change")
    printf("{txt}{hline 26}{c +}{hline 39}\n")
    for (i = 1; i <= 5; i++) printf("{txt}%-26s{c |}{res}%13.4f%13.4f%13.4f\n", labs[i], Tab[i, 1], Tab[i, 2], Tab[i, 3])
    printf("{txt}{hline 26}{c BT}{hline 39}\n")
    printf("\n{txt}By SAM household group\n")
    printf("{txt}{hline 18}{c TT}{hline 48}\n")
    printf("{txt}%-18s{c |}%12s%12s%12s%12s\n", "Group", "Pop. %", "Welfare %", "P0 before", "P0 after")
    printf("{txt}{hline 18}{c +}{hline 48}\n")
    for (k = 1; k <= cols(hh); k++) {
        if (Grp[k, 3] >= .) continue
        printf("{txt}%-18s{c |}{res}%12.2f%12.4f%12.3f%12.3f\n", abbrev(hh[k], 18), Grp[k, 3], Grp[k, 4], Grp[k, 1], Grp[k, 2])
    }
    printf("{txt}{hline 18}{c BT}{hline 48}\n")
    if (nb) {
        printf("\n{txt}By %s\n", st_local("by"))
        printf("{txt}{hline 18}{c TT}{hline 60}\n")
        printf("{txt}%-18s{c |}%10s%10s%10s%10s%10s%10s\n", "Group", "Pop. %", "P0 bef.", "P0 aft.", "Change", "Gini bef.", "Gini aft.")
        printf("{txt}{hline 18}{c +}{hline 60}\n")
        for (b = 1; b <= nb; b++) {
            printf("{txt}%-18s{c |}{res}%10.2f%10.3f%10.3f%10.3f%10.3f%10.3f\n", abbrev(st_vlmap(st_varvaluelabel(byv), b), 18),
                   By[b, 6], By[b, 1], By[b, 2], By[b, 3], By[b, 4], By[b, 5])
        }
        printf("{txt}{hline 18}{c BT}{hline 60}\n")
    }
}

void _cgemod_povdyn()
{
    transmorphic P
    string scalar touse, gv, mp
    string rowvector hh, hhl, tk
    string colvector gs
    real colvector y, z, w, gi, bc
    real matrix B, Pp, R
    real rowvector fb, fp
    real scalar n, i, j, k, b, T, per, show
    P = *findexternal("_cgemod_dynpov")
    touse = st_local("touse")
    gv = st_local("group")
    show = (st_local("table") == "")
    hh = asarray(P, "hh")
    hhl = strlower(hh)
    B = asarray(P, "base")
    Pp = asarray(P, "policy")
    T = rows(B) - 1
    y = st_data(., st_local("welfare"), touse)
    n = rows(y)
    w = (st_local("weight") != "" ? st_data(., st_local("weight"), touse) : J(n, 1, 1))
    if (st_local("hhsize") != "") w = w :* st_data(., st_local("hhsize"), touse)
    z = (st_local("linevar") != "" ? st_data(., st_local("linevar"), touse) : J(n, 1, strtoreal(st_local("line"))))
    gi = J(n, 1, .)
    if (st_isstrvar(gv)) {
        gs = st_sdata(., gv, touse)
        for (i = 1; i <= n; i++) {
            k = _cgemod_find(strlower(strtoname(strtrim(gs[i]))), hhl, J(1, 0, ""))
            if (!k) {
                errprintf("survey group %s is not a SAM household (%s)\n", gs[i], invtokens(hh))
                exit(459)
            }
            gi[i] = k
        }
    }
    else {
        mp = st_local("map")
        tk = tokens(mp)
        bc = st_data(., gv, touse)
        for (j = 1; j <= cols(tk); j++) {
            k = strpos(tk[j], "=")
            b = 0
            if (k) b = _cgemod_find(strlower(strtoname(substr(tk[j], k + 1, .))), hhl, J(1, 0, ""))
            if (!k | !b) {
                errprintf("map(): cannot read %s\n", tk[j])
                exit(198)
            }
            for (i = 1; i <= n; i++) if (bc[i] == strtoreal(substr(tk[j], 1, k - 1))) gi[i] = b
        }
        if (hasmissing(gi)) {
            errprintf("map(): some survey groups are not mapped to SAM households\n")
            exit(198)
        }
    }
    R = J(T + 1, 9, .)
    for (per = 0; per <= T; per++) {
        fb = _cgemod_fgt(y :* B[per + 1, gi]', z, w)
        fp = _cgemod_fgt(y :* Pp[per + 1, gi]', z, w)
        R[per + 1, .] = (per, fb[1], fp[1], fb[2], fp[2], fb[3], fp[3], fb[4], fp[4])
    }
    st_matrix("__cgemod_povpath", R)
    st_matrixcolstripe("__cgemod_povpath", (J(9, 1, ""), ("t", "P0_base", "P0_policy", "P1_base", "P1_policy",
                       "P2_base", "P2_policy", "Gini_base", "Gini_policy")'))
    st_matrixrowstripe("__cgemod_povpath", (J(T + 1, 1, ""), "t" :+ strofreal(0::T)))
    st_local("npov", strofreal(n))
    if (!show) return
    printf("\n{txt}cgemod poverty, dynamic: %g survey households; welfare follows real consumption per person of each SAM group\n", n)
    printf("{txt}{hline 6}{c TT}{hline 66}\n")
    printf("{txt}%6s{c |}%11s%11s%11s%11s%11s%11s\n", "t", "P0 base", "P0 policy", "P1 base", "P1 policy", "Gini base", "Gini pol.")
    printf("{txt}{hline 6}{c +}{hline 66}\n")
    for (per = 1; per <= T + 1; per++) {
        printf("{txt}%6.0f{c |}{res}%11.3f%11.3f%11.3f%11.3f%11.3f%11.3f\n", R[per, 1], R[per, 2], R[per, 3], R[per, 4], R[per, 5], R[per, 8], R[per, 9])
    }
    printf("{txt}{hline 6}{c BT}{hline 66}\n")
}

end
