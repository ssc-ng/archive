*! Prediction at one conditional grid key using fixed fit columns.
program define _cdid_pretest_grid
    version 19.5
    syntax, COLLECTION(name) BUNDLE(name) RAW(name) CELL(integer) DATE(real) DESIGN(real) BUDGET(name)
    tempname pending encoded fr
    local made_frame=0
    capture noisily {
        mata: _cdid_pt_grid_request("`collection'","`bundle'","`raw'","`pending'","`encoded'",`cell',`date',`design')
        if !`pt_grid_cached' {
            if `pt_grid_ready' {
                // Read factor identities from the already fixed expansion;
                // do not expand a fresh i.var formula over grid-only rows.
                foreach term of local pt_grid_expanded {
                    quietly _ms_parse_parts `term'
                    local type `"`r(type)'"'
                    if "`type'"=="factor" {
                        local factor `"`r(name)'"'
                        mata: _cdid_pt_grid_factor("`pending'",st_local("factor"))
                    }
                    else if inlist("`type'","interaction","product") {
                        local count=r(k_names)
                        forvalues j=1/`count' {
                            if r(level`j')<. {
                                local factor `"`r(name`j')'"'
                                mata: _cdid_pt_grid_factor("`pending'",st_local("factor"))
                            }
                        }
                    }
                }
            }
            if `pt_grid_ready' {
                frame create `fr'
                local made_frame=1
                frame `fr' {
                    mata: _cdid_pt_grid_stage("`pending'")
                    _cdid_reference_encode,reference(`encoded') slot(1) formula(`pt_grid_expanded')
                }
                frame drop `fr'
                local made_frame=0
            }
            mata: _cdid_pt_grid_finish("`collection'","`bundle'","`pending'","`encoded'",`cell',`design',*findexternal("`budget'"))
        }
    }
    local rc=_rc
    if `made_frame' capture frame drop `fr'
    capture mata: rmexternal("`pending'")
    capture mata: rmexternal("`encoded'")
    if `rc' exit `rc'
end
