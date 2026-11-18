*! One shared raw-history/reference/FV kernel, private helper.
program define _cdid_reference_prepare, rclass
    version 19.5
    local sort0 `"`c(sortrngstate)'"'
    tempname prior_r stage fvframe omitted
    _return hold `prior_r'
    local made_stage=0
    local made_frame=0
    capture noisily {
        syntax, POPULATION(name) PLAN(name) STORE(name) IVAR(varname) TIME(varname numeric) ///
            ROUTE(string) METHOD(string) [ROWS(name) FRAME(name) FRAMEIVAR(name) FRAMEMAP(name) ///
            XFORM(string) TRTFORM(string) SELFORM(string) NOCONStant TRTNOCONStant ///
            SELNOCONStant SELCONStant SELZERO UNIVERSE(string) WVAR(name) FIXWEIGHTS(string) ///
            ANTICIPation(integer 0) MAXENTRIES(real 134217728)]
        if !inlist("`route'","baseline","selected","imputation","augmented") error 198
        if !inlist("`method'","ipw","reg","dr") error 198
        if "`universe'"=="" local universe "F"
        if "`frameivar'"=="" local frameivar "`ivar'"
        if "`frame'"=="" & "`framemap'"!="" {
            display as error "framemap() requires frame()"
            error 198
        }
        local xi=("`noconstant'"=="")
        local ti=("`trtnoconstant'"=="")
        local si=("`selnoconstant'"=="")
        if `"`trtform'"'=="" {
            local trtform `"`xform'"'
            local ti=`xi'
        }
        if inlist("`route'","selected","augmented") {
            if "`selzero'"!="" {
                if `"`selform'"'!="" error 198
                local si=0
            }
            else if "`selconstant'"!="" {
                if `"`selform'"'!="" error 198
                local si=1
            }
            else if `"`selform'"'=="" {
                local selform `"`xform'"'
                if "`selnoconstant'"=="" local si=`xi'
            }
        }
        else {
            // Inactive selection tokens are never parsed or confirmed.
            local selform ""
            local si=0
        }
        if "`method'"=="reg" {
            local trtform ""
            local ti=0
        }
        mata: st_local("xr",invtokens(cdid_ref_formula_names(st_local("xform"))))
        mata: st_local("tr",invtokens(cdid_ref_formula_names(st_local("trtform"))))
        mata: st_local("sr",invtokens(cdid_ref_formula_names(st_local("selform"))))
        local raw `"`xr' `tr' `sr' `wvar'"'
        local raw : list uniq raw
        mata: _cdid_ref_capture("`population'","`rows'","`stage'",st_local("ivar"),st_local("time"),st_local("raw"),`maxentries')
        local made_stage=1
        if "`frame'"!="" {
            frame `frame': mata: _cdid_ref_frame("`stage'",st_local("frameivar"),st_local("framemap"))
        }
        mata: _cdid_ref_finalize("`stage'","`plan'",st_local("time"),`anticipation', ///
            st_local("route"),st_local("method"),st_local("universe"),st_local("fixweights"), ///
            st_local("xform"),st_local("trtform"),st_local("selform"), ///
            st_local("xr"),st_local("tr"),st_local("sr"),`xi',`ti',`si',st_local("wvar"),`maxentries')
        mata: _cdid_ref_meta("`stage'",0)
        forvalues slot=1/`nslots' {
            mata: _cdid_ref_meta("`stage'",`slot')
            if !`slot_encoded' {
                frame create `fvframe'
                local made_frame=1
                frame `fvframe' {
                    mata: _cdid_ref_stage_store("`stage'",`slot')
                    _cdid_reference_encode,reference(`stage') slot(`slot') formula(`formula')
                }
                frame drop `fvframe'
                local made_frame=0
            }
        }
        mata: cdid_ref_publish("`stage'","`store'")
    }
    local rc=_rc
    if `made_frame' capture frame drop `fvframe'
    if `made_stage' capture mata: rmexternal("`stage'")
    capture mata: mata drop `omitted'
    quietly set sortrngstate `sort0'
    if `rc' {
        _return restore `prior_r'
        return add
        exit `rc'
    }
    _return drop `prior_r'
    return local reference_object "`store'"
    return scalar N_F=`ref_N'
    return scalar N_recipes=`ref_recipes'
    return scalar N_views=`ref_views'
    return scalar N_formula_slots=`ref_slots'
end
