*! Private input/request preparation only; no public estimation command or fallback.
program define _cdid_imp_reference_prepare, rclass
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
    local pure_imputation = (strlower(strtrim("`selmethod'"))=="imputation")
    if `pure_imputation' {
        if !inlist(strlower(strtrim("`selection'")),"conditional_mtar","corollary1") | strupper(strtrim("`seluniverse'"))!="F" | `"`selrho'"'!="" {
            display as error "selmethod(imputation) requires selection(conditional_mtar) and seluniverse(F), without selrho()"
            exit 459
        }
        // These options are inactive: do not expand, confirm, read or inherit Q.
        local selcovars ""
        local frameselcovars ""
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
    tempname held input target pop plan rawrows reference fmap
    tempvar heldsample requested
    _estimates hold `held', restore nullok varname(`heldsample')
    local created=0
    local fast_static_done=0
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
        local can_fast = ("`fixweights'"=="")
        if `can_fast' & `"`covars'"'!="" {
            if strpos(`"`covars'"',".")>0 | strpos(`"`covars'"',"#")>0 local can_fast = 0
            else {
                capture confirm numeric variable `covars'
                if _rc local can_fast = 0
                else {
                    local cov_u : list uniq covars
                    local t_in_c : list time in covars
                    if `: word count `cov_u'' != `: word count `covars'' | `t_in_c' local can_fast = 0
                }
            }
        }
        if `can_fast' & "`wvar'"!="" & "`wvar'"=="`time'" local can_fast = 0
        if `can_fast' & "`frame'"!="" {
            if `"`covars'"'!="" & `"`framecovars'"'=="" local can_fast = 0
            else if "`wvar'"!="" & "`framewvar'"=="" local can_fast = 0
            else if `"`covars'"'!="" & `"`covars'"'!=`"`framecovars'"' local can_fast = 0
            else if "`wvar'"!="" & "`wvar'"!="`framewvar'" local can_fast = 0
            if `can_fast' & `"`framecovars'"'!="" {
                if strpos(`"`framecovars'"',".")>0 | strpos(`"`framecovars'"',"#")>0 local can_fast = 0
                else {
                    frame `frame': capture confirm numeric variable `framecovars'
                    if _rc local can_fast = 0
                    else {
                        local fcov_u : list uniq framecovars
                        local t_in_fc : list time in framecovars
                        if `: word count `fcov_u'' != `: word count `framecovars'' | `t_in_fc' local can_fast = 0
                    }
                }
            }
            if `can_fast' & "`framewvar'"!="" {
                if "`framewvar'"=="`time'" local can_fast = 0
                else {
                    frame `frame': capture confirm numeric variable `framewvar'
                    if _rc local can_fast = 0
                }
            }
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
        if `can_fast' {
            mata: _cdid_ci_data("`input'","`requested'","`ivar'","`time'","`varlist'","`gvar'","`covars'","`wvar'","","`cluster'","`data_rho'")
            local created=1
            if "`frame'"!="" {
                frame `frame': confirm variable `frameivar'
                if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
                if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
                if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
                frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","`framecovars'","`framewvar'","","`selrho'","`framecluster'")
            }
            mata: _cdid_try_static_prepare_store("`input'","`store'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
                `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),st_local("ptassumption"),`ptstart',`maxentries', ///
                st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
                st_local("seljustification"),st_local("selmethod"),st_local("imppooling"),st_local("gmmcovariance"), ///
                ("`selnoconstant'"!=""),("`selconstant'"!=""),("`selzero'"!=""),st_local("outcomepooling"))
            if `fast_static_done' local reference_active=1
        }
        else {
            mata: _cdid_ci_data("`input'","`requested'","`ivar'","`time'","`varlist'","`gvar'","","","","`cluster'","`data_rho'")
            local created=1
            if "`frame'"!="" {
                frame `frame': confirm variable `frameivar'
                if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
                if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
                if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
                frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","","","","`selrho'","`framecluster'")
            }
            mata: _cdid_public_prepare_store("`input'","`store'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
                `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),st_local("ptassumption"),`ptstart',`maxentries', ///
                st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
                st_local("seljustification"),st_local("selmethod"),st_local("imppooling"),st_local("gmmcovariance"), ///
                ("`selnoconstant'"!=""),("`selconstant'"!=""),("`selzero'"!=""),st_local("outcomepooling"))
        }
        if !`fast_static_done' {
            mata: _cdid_imp_reference_begin("`store'","`pop'","`plan'","`rawrows'",`maxentries')
            if `"`covars'"'=="" local covars `"`framecovars'"'
            if "`wvar'"=="" local wvar "`framewvar'"
            mata: _cdid_imp_reference_map("`fmap'",st_local("covars"),st_local("framecovars"),st_local("wvar"),st_local("framewvar"))
            local frameopts ""
            if "`frame'"!="" local frameopts "frame(`frame') frameivar(`frameivar') framemap(`fmap')"
            local wopts ""
            if "`wvar'"!="" local wopts "wvar(`wvar')"
            if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
            _cdid_reference_prepare, population(`pop') plan(`plan') store(`reference') rows(`rawrows') ///
                ivar(`ivar') time(`time') route(imputation) method(`method') xform(`covars') ///
                `noconstant' `frameopts' `wopts' anticipation(`anticipation') maxentries(`maxentries')
            mata: _cdid_imp_reference_attach("`store'","`reference'",st_local("wvar"))
        }
    }
    local rc=_rc
    if `created' capture mata: rmexternal("`input'")
    foreach object in pop plan rawrows reference fmap {
        capture mata: rmexternal("``object''")
    }
    capture mata: mata drop `target'
    _estimates unhold `held'
    quietly set sortrngstate `sort_rng'
    if `rc' {
        capture mata: rmexternal("`store'")
        exit `rc'
    }
    if !`reference_active' {
        mata: rmexternal("`store'")
        _cdid_request_prepare `original0' referencechecked
        return add
        exit
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
