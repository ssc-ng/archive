*! Private input/request preparation only; no public estimation command or fallback.
program define _cdid_baseline_reference_prepare, rclass
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
    if "`selection'"=="" local selection "none"
    if "`selmodel'"=="" local selmodel "pair_logit"
    if "`selpooling'"=="" local selpooling "separate"
    if "`seluniverse'"=="" local seluniverse "F"
    if "`selmethod'"=="" local selmethod "ipw"
    if "`gmmcovariance'"=="" local gmmcovariance "tikhonov"
    // Refuse inactive observation-design declarations without expanding/reading Q.
    local has_selection_design=(`"`selcovars'`frameselcovars'`selnoconstant'`selconstant'`selzero'"'!="")
    mata: (void) cdid_sel_norm_decl(st_local("selection"),`has_selection_design',st_local("seluniverse"), ///
        (st_local("selrho")!=""),(st_local("seljustification")!=""),st_local("selmodel"),st_local("selpooling"),st_local("seljustification"))
    if strlower(strtrim("`selection'"))!="none" | strlower(strtrim("`selmethod'"))!="ipw" {
        display as error "Baseline reference preparation requires selection(none) and selmethod(ipw)."
        exit 498
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
    tempname held input target pop plan rawrows reference fmap rawprobe probe encoded probeframe
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
        mata: _cdid_baseline_prepare_store("`input'","`store'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
            `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),st_local("ptassumption"),`ptstart',`maxentries', ///
            st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
            st_local("seljustification"),st_local("selmethod"),st_local("imppooling"),st_local("gmmcovariance"), ///
            ("`selnoconstant'"!=""),("`selconstant'"!=""),("`selzero'"!=""),st_local("outcomepooling"))
        local made_bundle=1
        mata: _cdid_bs_pop_export("`store'","`pop'","`rawrows'")
        if `"`covars'"'=="" local covars `"`framecovars'"'
        if "`wvar'"=="" local wvar "`framewvar'"
        mata: _cdid_imp_reference_map("`fmap'",st_local("covars"),st_local("framecovars"),st_local("wvar"),st_local("framewvar"))
        local frameopts ""
        if "`frame'"!="" local frameopts "frame(`frame') frameivar(`frameivar') framemap(`fmap')"
        local wopts ""
        if "`wvar'"!="" local wopts "wvar(`wvar')"
        if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
        // The unchanged evaluated static gate runs FIRST, on its actual frame
        // and every supplied historical row of the original F/A fitting scope.
        mata: st_local("bsp_xraw",invtokens(cdid_ref_formula_names(st_local("covars"))))
        local bsp_raw "`bsp_xraw' `wvar'"
        local bsp_raw : list uniq bsp_raw
        mata: _cdid_ref_capture("`pop'","`rawrows'","`rawprobe'",st_local("ivar"),st_local("time"),st_local("bsp_raw"),`maxentries')
        if "`frame'"!="" {
            frame `frame': mata: _cdid_ref_frame("`rawprobe'",st_local("frameivar"),"`fmap'")
        }
        mata: _cdid_bs_start("`store'","`rawprobe'","`probe'","`encoded'",st_local("covars"),`maxentries')
        local bs_encode_rc=0
        if `bs_ready' & !`bs_plain' {
            frame create `probeframe'
            local made_probeframe=1
            frame `probeframe' {
                mata: _cdid_bs_stage("`probe'")
                capture noisily _cdid_reference_encode,reference(`encoded') slot(1) formula(`covars')
                local bs_encode_rc=_rc
            }
            frame drop `probeframe'
            local made_probeframe=0
        }
        mata: _cdid_bs_finish("`store'","`probe'","`encoded'",st_local("time"),`bs_encode_rc')
        local bs_static_done=0
        if `bs_accepted' & "`fullreference'"=="" {
            mata: _cdid_bs_try_static_attach("`store'","`probe'",st_local("wvar"),st_local("fixweights"),st_local("time"),`maxentries')
        }
        if !`bs_static_done' {
            mata: _cdid_bs_begin_plan("`store'","`plan'",`maxentries')
            if `bs_accepted' {
                mata: _cdid_bs_reference("`store'","`probe'","`plan'","`reference'",st_local("wvar"), ///
                    st_local("fixweights"),st_local("time"),`anticipation',`maxentries')
            }
        }
        foreach bsp_object in probe rawprobe encoded {
            capture mata: rmexternal("``bsp_object''")
        }
        if !`bs_static_done' {
            if !`bs_accepted' {
                _cdid_reference_prepare, population(`pop') plan(`plan') store(`reference') rows(`rawrows') ///
                    ivar(`ivar') time(`time') route(baseline) method(`method') xform(`covars') ///
                    `noconstant' `frameopts' `wopts' anticipation(`anticipation') maxentries(`maxentries')
            }
            mata: _cdid_baseline_reference_attach("`store'","`reference'",st_local("wvar"))
        }

    }
    local rc=_rc
    if `made_probeframe' capture frame drop `probeframe'
    if `created' capture mata: rmexternal("`input'")
    foreach object in pop plan rawrows reference fmap rawprobe probe encoded {
        capture mata: rmexternal("``object''")
    }
    capture mata: mata drop `target'
    _estimates unhold `held'
    quietly set sortrngstate `sort_rng'
    if `rc' {
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
