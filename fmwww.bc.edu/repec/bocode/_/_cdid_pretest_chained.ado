*! Standalone baseline/selected/imputation/augmented conditional producer; full union, no final post GMM fit.
program define _cdid_pretest_chained, rclass
    version 19.5
    syntax varname(numeric) [if] [in], IVAR(varname) TIME(varname numeric) GVAR(varname numeric) OUTPUT(name) ///
        [COVARS(string) NOCONStant FRAME(name) FRAMEIVAR(name) FRAMEGVAR(name) FRAMECOVARS(string) ///
        WVAR(varname numeric) FRAMEWVAR(name) FIXWEIGHTS(string) METHOD(string) CONTROLgroup(string) ///
        ANTICIPation(integer 0) BASEperiod(string) CLUSTER(varname) FRAMECLUSTER(name) CLUSTERVARS(string) ///
        SELECTION(string) SELMODEL(string) SELPOOLING(string) SELUNIVERSE(string) SELRHO(string) ///
        SELJUSTIFICATION(string) SELCOVARS(string) FRAMESELCOVARS(string) SELNOCONStant SELCONStant SELZERO ///
        SELMETHOD(string) IMPPOOLING(string) OUTCOMEPOOLING(string) ///
        BITERS(integer 1000) ALPHA(real .05) WORKSPACE(real 1073741824) CHUNK(string) WORKCAP(string) ///
        SIGNS(name) POSTING(string) BSTRAP(integer 1) CBAND(integer 1)]
    if "`method'"=="" local method "ipw"
    if "`controlgroup'"=="" local controlgroup "nevertreated"
    if "`baseperiod'"=="" local baseperiod "varying"
    if "`posting'"=="" local posting "matrix"
    if "`chunk'"=="" local chunk "."
    if "`workcap'"=="" local workcap "."
    if "`frameivar'"=="" local frameivar "`ivar'"
    if "`selection'"=="" local selection "none"
    if "`selmethod'"=="" local selmethod "ipw"
    if "`imppooling'"=="" local imppooling "separate"
    local entries=floor(`workspace'/8)
    local sort_rng `"`c(sortrngstate)'"'
    tempname bundle pop plan rows ref provider process grids raw fmap budget cat input target reference rawprobe probe xprobe sprobe encoded probeframe
    tempvar requested
    local made_output=0
    local made_probeframe=0
    capture noisily {
        if `"`covars'"'!="" & strpos(`"`covars'"',".")==0 & strpos(`"`covars'"',"#")==0 {
            unab covars : `covars'
        }
        if "`frame'"!="" & `"`framecovars'"'!="" & strpos(`"`framecovars'"',".")==0 & strpos(`"`framecovars'"',"#")==0 {
            frame `frame': unab framecovars : `framecovars'
        }
        if "`selmethod'"=="ipw" {
            if "`selmodel'"=="" local selmodel "pair_logit"
            if "`selpooling'"=="" local selpooling "separate"
            if "`seluniverse'"=="" local seluniverse "F"
            if "`frame'"=="" & "`framegvar'`framecovars'`framewvar'`frameselcovars'`framecluster'"!="" {
                display as error "frame mappings require an explicit frame()"
                exit 198
            }
            if "`selection'"=="none" {
                local has_selection_design=(`"`selcovars'`frameselcovars'`selnoconstant'`selconstant'`selzero'"'!="")
                mata: (void) cdid_sel_norm_decl(st_local("selection"),`has_selection_design',st_local("seluniverse"), ///
                    (st_local("selrho")!=""),(st_local("seljustification")!=""),st_local("selmodel"),st_local("selpooling"),st_local("seljustification"))
                local data_rho ""
                if "`frame'"=="" & "`selrho'"!="" {
                    confirm numeric variable `selrho'
                    local data_rho "`selrho'"
                }
                quietly mark `requested' `if' `in'
                mata: _cdid_ci_data("`input'","`requested'","`ivar'","`time'","`varlist'","`gvar'","","","","`cluster'","`data_rho'")
                if "`frame'"!="" {
                    frame `frame': confirm variable `frameivar'
                    if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
                    if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
                    if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
                    frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","","","","`selrho'","`framecluster'")
                }
                mata: `target'=J(0,1,.)
                mata: _cdid_baseline_prepare_store("`input'","`bundle'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
                    `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),"post",.,`entries', ///
                    st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
                    st_local("seljustification"),st_local("selmethod"),st_local("imppooling"),"tikhonov", ///
                    ("`selnoconstant'"!=""),("`selconstant'"!=""),("`selzero'"!=""),st_local("outcomepooling"))
                capture mata: rmexternal("`input'")
                capture mata: mata drop `target'
                mata: _cdid_pt_reference_begin("`bundle'","`pop'","`plan'","`rows'",`entries')
                if `"`covars'"'=="" local covars `"`framecovars'"'
                if "`wvar'"=="" local wvar "`framewvar'"
                mata: _cdid_imp_reference_map("`fmap'",st_local("covars"),st_local("framecovars"),st_local("wvar"),st_local("framewvar"))
                local frameopts ""
                if "`frame'"!="" local frameopts "frame(`frame') frameivar(`frameivar') framemap(`fmap')"
                local wopts ""
                if "`wvar'"!="" local wopts "wvar(`wvar')"
                if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
                mata: st_local("pt_rawvars",invtokens(cdid_ref_formula_names(st_local("covars"))))
                local bsp_raw "`pt_rawvars' `wvar'"
                local bsp_raw : list uniq bsp_raw
                mata: _cdid_ref_capture("`pop'","`rows'","`rawprobe'",st_local("ivar"),st_local("time"),st_local("bsp_raw"),`entries')
                if "`frame'"!="" {
                    frame `frame': mata: _cdid_ref_frame("`rawprobe'",st_local("frameivar"),"`fmap'")
                }
                mata: _cdid_bs_start("`bundle'","`rawprobe'","`probe'","`encoded'",st_local("covars"),`entries')
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
                mata: _cdid_bs_finish("`bundle'","`probe'","`encoded'",st_local("time"),`bs_encode_rc')
                if `bs_accepted' {
                    mata: _cdid_bs_reference("`bundle'","`probe'","`plan'","`reference'",st_local("wvar"), ///
                        st_local("fixweights"),st_local("time"),`anticipation',`entries')
                }
                mata: _cdid_pt_subset_raw("`rawprobe'","`raw'",st_local("pt_rawvars"))
                foreach bsp_object in probe rawprobe encoded {
                    capture mata: rmexternal("``bsp_object''")
                }
                if !`bs_accepted' {
                    _cdid_reference_prepare, population(`pop') plan(`plan') store(`reference') rows(`rows') ///
                        ivar(`ivar') time(`time') route(baseline) method(`method') xform(`covars') ///
                        `noconstant' `frameopts' `wopts' anticipation(`anticipation') maxentries(`entries')
                }
                mata: _cdid_baseline_reference_attach("`bundle'","`reference'",st_local("wvar"))
                capture mata: rmexternal("`reference'")
            }
            else {
                if !inlist(strlower(strtrim("`selection'")),"conditional_mtar","corollary1") {
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
                if "`frame'"!="" {
                    frame `frame': confirm variable `frameivar'
                    if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
                    if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
                    if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
                    frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","","","","`selrho'","`framecluster'")
                }
                mata: `target'=J(0,1,.)
                mata: _cdid_sr_prepare_store("`input'","`bundle'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
                    `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),"post",.,`entries', ///
                    st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
                    st_local("seljustification"),"tikhonov",`si',`inherited',st_local("outcomepooling"))
                capture mata: rmexternal("`input'")
                capture mata: mata drop `target'
                mata: _cdid_pt_reference_begin("`bundle'","`pop'","`plan'","`rows'",`entries')
                if `"`covars'"'=="" local covars `"`framecovars'"'
                if "`wvar'"=="" local wvar "`framewvar'"
                mata: _cdid_sr_map("`fmap'",st_local("covars"),st_local("framecovars"),st_local("selform"),st_local("selframe"),st_local("wvar"),st_local("framewvar"))
                mata: st_local("pt_rawvars",invtokens(cdid_ref_formula_names(st_local("covars"))))
                mata: st_local("sr_sraw",invtokens(cdid_ref_formula_names(st_local("selform"))))
                local sr_raw "`pt_rawvars' `sr_sraw' `wvar'"
                local sr_raw : list uniq sr_raw
                mata: _cdid_ref_capture("`pop'","`rows'","`rawprobe'",st_local("ivar"),st_local("time"),st_local("sr_raw"),`entries')
                if "`frame'"!="" {
                    frame `frame': mata: _cdid_ref_frame("`rawprobe'",st_local("frameivar"),"`fmap'")
                }
                forvalues role=0/1 {
                    local thisprobe "`xprobe'"
                    local formula `"`covars'"'
                    if `role' {
                        local thisprobe "`sprobe'"
                        local formula `"`selform'"'
                    }
                    mata: _cdid_sr_probe_start("`bundle'","`rawprobe'","`thisprobe'","`encoded'",st_local("formula"),`role',`entries')
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
                mata: _cdid_sr_reference("`bundle'","`rawprobe'","`xprobe'","`sprobe'","`plan'","`reference'", ///
                    st_local("time"),st_local("wvar"),st_local("fixweights"),`anticipation',`entries')
                mata: _cdid_pt_subset_raw("`rawprobe'","`raw'",st_local("pt_rawvars"))
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
                mata: _cdid_sr_attach("`bundle'","`reference'")
                capture mata: rmexternal("`reference'")
            }
        }
        else {
            local prepopts ""
            foreach option in covars frame frameivar framegvar framecovars wvar framewvar fixweights cluster framecluster outcomepooling {
                if `"``option''"'!="" local prepopts `"`prepopts' `option'(``option'')"'
            }
            if "`selmethod'"=="imputation" {
                local prepare "_cdid_imp_reference_prepare"
                foreach option in selection seluniverse selmethod imppooling {
                    if `"``option''"'!="" local prepopts `"`prepopts' `option'(``option'')"'
                }
            }
            else {
                local prepare "_cdid_aug_reference_prepare"
                foreach option in selection selmodel selpooling seluniverse selrho seljustification selcovars frameselcovars selmethod imppooling {
                    if `"``option''"'!="" local prepopts `"`prepopts' `option'(``option'')"'
                }
                local prepopts "`prepopts' `selnoconstant' `selconstant' `selzero'"
            }
            `prepare' `varlist' `if' `in',ivar(`ivar') time(`time') gvar(`gvar') ///
                store(`bundle') `prepopts' `noconstant' method(`method') controlgroup(`controlgroup') ///
                anticipation(`anticipation') baseperiod(`baseperiod') ptassumption(post) maxentries(`entries')
            mata: _cdid_pt_reference_begin("`bundle'","`pop'","`plan'","`rows'",`entries')
            if `"`covars'"'=="" local covars `"`framecovars'"'
            mata: st_local("pt_rawvars",invtokens(cdid_ref_formula_names(st_local("covars"))))
            mata: _cdid_ref_capture("`pop'","`rows'","`raw'",st_local("ivar"),st_local("time"),st_local("pt_rawvars"),`entries')
            if "`frame'"!="" {
                mata: _cdid_imp_reference_map("`fmap'",st_local("covars"),st_local("framecovars"),"","")
                frame `frame': mata: _cdid_ref_frame("`raw'",st_local("frameivar"),"`fmap'")
            }
        }
        mata: _cdid_pt_chain_begin("`bundle'","`pop'","`plan'","`ref'","`provider'","`process'", ///
            "`grids'","`budget'","`raw'","`cat'",`biters',`alpha',`workspace',`chunk',`workcap')
        if `pt_process_available' {
            forvalues cell=1/`pt_cells' {
                mata: _cdid_pt_chain_cell("`process'",`cell')
                _cdid_pretest_grid,collection(`grids') bundle(`bundle') raw(`raw') cell(`cell') ///
                    date(`pt_date') design(`pt_design') budget(`budget')
            }
        }
        mata: _cdid_pt_chain_run("`process'","`grids'","`output'",st_local("signs"),st_local("posting"), ///
            `c(max_matdim)',`bstrap',`cband',st_local("covars"),st_local("clustervars"))
        local made_output=1
    }
    local rc=_rc
    if `made_probeframe' capture frame drop `probeframe'
    capture mata: mata drop `target'
    foreach object in bundle pop plan rows ref provider process grids raw fmap budget cat input reference rawprobe probe xprobe sprobe encoded {
        capture mata: rmexternal("``object''")
    }
    quietly set sortrngstate `sort_rng'
    if `rc' {
        if `made_output' capture mata: rmexternal("`output'")
        exit `rc'
    }
    return local result_object "`output'"
end
