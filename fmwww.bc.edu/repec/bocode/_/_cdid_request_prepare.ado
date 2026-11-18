*! Private input/request preparation only; no public estimation command or fallback.
program define _cdid_request_prepare, rclass
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
    if strlower(strtrim("`selmethod'"))=="dr" & "`referencechecked'"=="" {
        _cdid_aug_reference_prepare `original0'
        return add
        exit
    }
    local pure_imputation = (strlower(strtrim("`selmethod'"))=="imputation")
    // Cross-pair comparisons use the static covariate design on the selection universe.
    capture mata: st_local("xp_static", strofreal(cdid_xp_requested()))
    if _rc local xp_static 0
    // Covariates or weights that vary over time are read at reference dates (recipes).
    if "`xp_static'"=="1" & inlist(strlower(strtrim("`selection'")),"conditional_mtar","corollary1") & strlower(strtrim("`selmethod'"))=="ipw" & "`referencechecked'"=="" {
        tempvar xp_touse xp_gid
        quietly mark `xp_touse' `if' `in'
        quietly egen long `xp_gid' = group(`ivar') if `xp_touse'
        quietly replace `xp_touse' = 0 if missing(`xp_gid')
        mata: st_local("xp_varies", strofreal(cdid_xp_varies("`xp_gid'", st_local("covars") + " " + st_local("selcovars") + " " + st_local("wvar"), "`xp_touse'")))
        drop `xp_gid' `xp_touse'
        if `xp_varies' local xp_static 0
    }
    if inlist(strlower(strtrim("`selection'")),"conditional_mtar","corollary1") & strlower(strtrim("`selmethod'"))=="ipw" & "`referencechecked'"=="" & "`xp_static'"!="1" {
        _cdid_selected_reference_prepare `original0'
        return add
        exit
    }
    if strlower(strtrim("`selection'"))=="none" & strlower(strtrim("`selmethod'"))=="ipw" & "`referencechecked'"=="" {
        _cdid_baseline_reference_prepare `original0'
        return add
        exit
    }
    if `pure_imputation' & "`referencechecked'"=="" {
        _cdid_imp_reference_prepare `original0'
        return add
        exit
    }
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
    tempname held input target
    tempvar heldsample requested
    _estimates hold `held', restore nullok varname(`heldsample')
    local created=0
    capture noisily {
        if `"`covars'"'!="" {
            mata: _cdid_ci_check_static_tokens(st_local("covars"), "covars()")
            unab covars : `covars'
            confirm numeric variable `covars'
        }
        if `"`selcovars'"'!="" {
            mata: _cdid_ci_check_static_tokens(st_local("selcovars"), "selcovars()")
            unab selcovars : `selcovars'
            confirm numeric variable `selcovars'
        }
        local data_rho ""
        if "`frame'"=="" & "`selrho'"!="" {
            confirm numeric variable `selrho'
            local data_rho "`selrho'"
        }
        quietly mark `requested' `if' `in'
        mata: _cdid_ci_data("`input'","`requested'","`ivar'","`time'","`varlist'","`gvar'","`covars'","`wvar'","`selcovars'","`cluster'","`data_rho'")
        local created=1
        if "`frame'"!="" {
            frame `frame': confirm variable `frameivar'
            if "`framegvar'"!="" frame `frame': confirm numeric variable `framegvar'
            if `"`framecovars'"'!="" {
                mata: _cdid_ci_check_static_tokens(st_local("framecovars"), "framecovars()")
                frame `frame': unab framecovars : `framecovars'
                frame `frame': confirm numeric variable `framecovars'
            }
            if "`framewvar'"!="" frame `frame': confirm numeric variable `framewvar'
            if `"`frameselcovars'"'!="" {
                mata: _cdid_ci_check_static_tokens(st_local("frameselcovars"), "frameselcovars()")
                frame `frame': unab frameselcovars : `frameselcovars'
                frame `frame': confirm numeric variable `frameselcovars'
            }
            if "`selrho'"!="" frame `frame': confirm numeric variable `selrho'
            if "`framecluster'"!="" frame `frame': confirm variable `framecluster'
            frame `frame': mata: _cdid_ci_frame("`input'","`frameivar'","`framegvar'","`framecovars'","`framewvar'","`frameselcovars'","`selrho'","`framecluster'")
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
        mata: _cdid_public_prepare_store("`input'","`store'",st_local("method"),("`noconstant'"!=""),st_local("fixweights"), ///
            `target',st_local("controlgroup"),`anticipation',st_local("baseperiod"),st_local("ptassumption"),`ptstart',`maxentries', ///
            st_local("selection"),st_local("selmodel"),st_local("selpooling"),st_local("seluniverse"), ///
            st_local("seljustification"),st_local("selmethod"),st_local("imppooling"),st_local("gmmcovariance"), ///
            ("`selnoconstant'"!=""),("`selconstant'"!=""),("`selzero'"!=""),st_local("outcomepooling"))
    }
    local rc=_rc
    if `created' capture mata: rmexternal("`input'")
    capture mata: mata drop `target'
    _estimates unhold `held'
    quietly set sortrngstate `sort_rng'
    if `rc' exit `rc'
    return local request_object "`store'"
    return local method "`method'"
    return local selection "`selection'"
    return scalar N_F=`pr_N'
    return scalar N_A=`pr_A'
    return scalar N_post=`pr_post'
    return scalar N_aux=`pr_aux'
    return scalar N_report=`pr_report'
end
