*! Private input/request preparation only; no public estimation command or fallback.
program define _cdid_selected_reference_prepare, rclass
    version 19.5
    local original0 `"`0'"'
    syntax varname(numeric) [if] [in], IVAR(varname) TIME(varname numeric) GVAR(varname numeric) STORE(name) ///
        [COVARS(string) NOCONStant FRAME(name) FRAMEIVAR(name) FRAMEGVAR(name) FRAMECOVARS(string) ///
        WVAR(varname numeric) FRAMEWVAR(name) FIXWEIGHTS(string) METHOD(string) CONTROLgroup(string) ///
        ANTICIPation(integer 0) BASEperiod(string) PTASSUMPTION(string) PTSTART(string) ///
        TARGETS(name) TARGETCOHORTS(numlist) MAXENTRIES(real 134217728) ///
        SELECTION(string) SELMODEL(string) SELPOOLING(string) ///
        SELCOVARS(string) FRAMESELCOVARS(string) SELNOCONStant SELCONStant SELZERO ///
        SELUNIVERSE(string) SELRHO(string) SELJUSTIFICATION(string) ///
        SELMETHOD(string) IMPPOOLING(string) OUTCOMEPOOLING(string) GMMCOVARIANCE(string) ///
        CLUSTER(varname) FRAMECLUSTER(name) REFERENCECHECKED FULLREFERENCE]
    if "`method'"=="" local method "dr"
    if "`controlgroup'"=="" local controlgroup "nevertreated"
    if "`baseperiod'"=="" local baseperiod "varying"
    if "`ptassumption'"=="" local ptassumption "post"
    if "`selection'"=="" local selection "conditional_mtar"
    if "`selmodel'"=="" local selmodel "pair_logit"
    if "`selpooling'"=="" local selpooling "separate"
    if "`seluniverse'"=="" local seluniverse "F"
    if "`selmethod'"=="" local selmethod "ipw"
    if "`gmmcovariance'"=="" local gmmcovariance "tikhonov"
    if !inlist(strlower(strtrim("`selection'")),"conditional_mtar","corollary1") | strlower(strtrim("`selmethod'"))!="ipw" {
        display as error "Selected reference preparation requires active conditional_mtar and selmethod(ipw)."
        exit 498
    }
    local dq=(`"`selcovars'`frameselcovars'"'!="")
    if "`selzero'"!="" & (`dq' | "`selconstant'"!="") {
        display as error "selzero (no observation-model design) cannot be combined with selcovars(), frameselcovars() or selconstant"
        exit 198
    }
    if "`selconstant'"!="" & (`dq' | "`selnoconstant'`selzero'"!="") {
        display as error "selconstant (intercept-only observation model) cannot be combined with selcovars(), frameselcovars(), selnoconstant or selzero"
        exit 198
    }
    if "`ptstart'"=="" local ptstart "."
    else confirm number `ptstart'
    if "`targets'"!="" & "`targetcohorts'"!="" {
        display as error "specify either targets() or targetcohorts(), not both"
        exit 198
    }
    if "`frameivar'"=="" local frameivar "`ivar'"
    if "`frame'"=="" & "`framegvar'`framecovars'`framewvar'`frameselcovars'`framecluster'"!="" {
        display as error "frame mappings require an explicit frame()"
        exit 198
    }
    local sort_rng `"`c(sortrngstate)'"'
    tempname held input target pop plan rawrows reference fmap rawprobe xprobe sprobe encoded probeframe
    tempvar heldsample requested
    _estimates hold `held', restore nullok varname(`heldsample')
    local created=0
    local made_bundle=0
    local made_probeframe=0
    capture noisily {
        if `"`covars'"'!="" & strpos(`"`covars'"',".")==0 & strpos(`"`covars'"',"#")==0 {
            unab covars : `covars'
        }
        if "`frame'"!="" & `"`framecovars'"'!="" & strpos(`"`framecovars'"',".")==0 & strpos(`"`framecovars'"',"#")==0 {
            frame `frame': unab framecovars : `framecovars'
        }
        if `"`selcovars'"'!="" & strpos(`"`selcovars'"',".")==0 & strpos(`"`selcovars'"',"#")==0 {
            unab selcovars : `selcovars'
        }
        if "`frame'"!="" & `"`frameselcovars'"'!="" & strpos(`"`frameselcovars'"',".")==0 & strpos(`"`frameselcovars'"',"#")==0 {
            frame `frame': unab frameselcovars : `frameselcovars'
        }
        if `"`covars'"'=="" local covars `"`framecovars'"'
        if `"`selcovars'"'=="" local selcovars `"`frameselcovars'"'
        local selform `"`selcovars'"'
        local selframe `"`frameselcovars'"'
        local si=("`selnoconstant'"=="")
        local inherited=0
        if "`selzero'"!="" {
            local selform ""
            local selframe ""
            local si=0
        }
        else if "`selconstant'"!="" {
            local selform ""
            local selframe ""
            local si=1
        }
        else if !`dq' {
            local selform `"`covars'"'
            local selframe `"`framecovars'"'
            local si=("`selnoconstant'`noconstant'"=="")
            if "`selnoconstant'"!="" local si=0
            local inherited=("`selnoconstant'"=="")
        }
        local data_rho ""
        if "`frame'"=="" & "`selrho'"!="" {
            confirm numeric variable `selrho'
            local data_rho "`selrho'"
        }
        quietly mark `requested' `if' `in'
        mata: _cdid_ci_data("`input'","`requested'","`ivar'","`time'","`varlist'","`gvar'","","","","`cluster'","`data_rho'")
        local created=1
        if "`frame'"!="" {
            frame `frame': confirm variable `frameivar'
            if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
            if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
            if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
            frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","","","","`selrho'","`framecluster'")
        }
        mata: `target'=J(0,1,.)
        if "`targets'"!="" {
            confirm matrix `targets'
            mata: `target'=st_matrix("`targets'")
        }
        else if "`targetcohorts'"!="" {
            foreach gval of local targetcohorts {
                mata: `target' = `target' \ strtoreal("`gval'")
            }
        }
        mata: _cdid_sr_prepare_store("`input'","`store'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
            `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),st_local("ptassumption"),`ptstart',`maxentries', ///
            st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
            st_local("seljustification"),st_local("gmmcovariance"),`si',`inherited',st_local("outcomepooling"))
        local made_bundle=1
        mata: _cdid_sr_reference_begin("`store'","`pop'","`plan'","`rawrows'",`maxentries')
        if `"`covars'"'=="" local covars `"`framecovars'"'
        if "`wvar'"=="" local wvar "`framewvar'"
        mata: _cdid_sr_map("`fmap'",st_local("covars"),st_local("framecovars"),st_local("selform"),st_local("selframe"),st_local("wvar"),st_local("framewvar"))
        local frameopts ""
        if "`frame'"!="" local frameopts "frame(`frame') frameivar(`frameivar') framemap(`fmap')"
        local wopts ""
        if "`wvar'"!="" local wopts "wvar(`wvar')"
        if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
        mata: st_local("sr_xraw",invtokens(cdid_ref_formula_names(st_local("covars"))))
        mata: st_local("sr_sraw",invtokens(cdid_ref_formula_names(st_local("selform"))))
        local sr_raw "`sr_xraw' `sr_sraw' `wvar'"
        local sr_raw : list uniq sr_raw
        mata: _cdid_ref_capture("`pop'","`rawrows'","`rawprobe'",st_local("ivar"),st_local("time"),st_local("sr_raw"),`maxentries')
        if "`frame'"!="" {
            frame `frame': mata: _cdid_ref_frame("`rawprobe'",st_local("frameivar"),"`fmap'")
        }
        forvalues role=1(-1)0 {
            local thisprobe "`xprobe'"
            local formula `"`covars'"'
            if `role' {
                local thisprobe "`sprobe'"
                local formula `"`selform'"'
            }
            local sr_shared=0
            if !`role' & `"`covars'"'==`"`selform'"' & `"`framecovars'"'==`"`selframe'"' {
                mata: _cdid_sr_probe_share("`store'","`sprobe'","`xprobe'",`maxentries')
            }
            if !`sr_shared' {
                mata: _cdid_sr_probe_start("`store'","`rawprobe'","`thisprobe'","`encoded'",st_local("formula"),`role',`maxentries')
                local sr_encode_rc=0
                if `bs_ready' & !`bs_plain' {
                    frame create `probeframe'
                    local made_probeframe=1
                    frame `probeframe' {
                        mata: _cdid_bs_stage("`thisprobe'")
                        capture noisily _cdid_reference_encode,reference(`encoded') slot(1) formula(`formula')
                        local sr_encode_rc=_rc
                    }
                    frame drop `probeframe'
                    local made_probeframe=0
                }
                mata: _cdid_sr_probe_finish("`thisprobe'","`encoded'",`role',`sr_encode_rc')
                capture mata: rmexternal("`encoded'")
            }
        }
        mata: _cdid_sr_reference("`store'","`rawprobe'","`xprobe'","`sprobe'","`plan'","`reference'", ///
            st_local("time"),st_local("wvar"),st_local("fixweights"),`anticipation',`maxentries')
        foreach sr_object in xprobe sprobe rawprobe {
            capture mata: rmexternal("``sr_object''")
        }
        mata: _cdid_ref_meta("`reference'",0)
        forvalues slot=1/`nslots' {
            mata: _cdid_sr_slot_meta("`reference'",`slot')
            if !`sr_encoded' {
                frame create `probeframe'
                local made_probeframe=1
                frame `probeframe' {
                    mata: _cdid_ref_stage_store("`reference'",`slot')
                    _cdid_reference_encode,reference(`reference') slot(`slot') formula(`formula')
                }
                frame drop `probeframe'
                local made_probeframe=0
            }
        }
        mata: _cdid_sr_attach("`store'","`reference'")

    }
    local rc=_rc
    if `made_probeframe' capture frame drop `probeframe'
    if `created' capture mata: rmexternal("`input'")
    foreach object in pop plan rawrows reference fmap rawprobe xprobe sprobe encoded {
        capture mata: rmexternal("``object''")
    }
    capture mata: mata drop `target'
    _estimates unhold `held'
    quietly set sortrngstate `sort_rng'
    if `rc' {
        capture mata: rmexternal("_cdid_sr_cached_plan")
        if `made_bundle' capture mata: rmexternal("`store'")
        exit `rc'
    }
    return local request_object "`store'"
    return local method "`method'"
    return local selection "`selection'"
    return scalar N_F=`pr_N'
    return scalar N_A=`pr_A'
    return scalar N_post=`pr_post'
    return scalar N_aux=`pr_aux'
    return scalar N_report=`pr_report'
end
