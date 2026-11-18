*! Shared native FV expansion; consumed by static probes and reference slots.
program define _cdid_reference_encode
    version 19.5
    syntax, REFERENCE(name) SLOT(integer) [FORMULA(string)]
    tempname omitted
    capture noisily {
                local expanded ""
                if `"`formula'"'!="" {
                    quietly fvexpand `formula'
                    local expanded `"`r(varlist)'"'
                }
                local kept ""
                local keep_positions ""
                local position=0
                mata: `omitted'=J(1,0,0)
                foreach term of local expanded {
                    local ++position
                    quietly _ms_parse_parts `term'
                    local omit=r(omit)
                    mata: `omitted'=`omitted',`omit'
                    if !`omit' {
                        local kept `"`kept' `term'"'
                        local keep_positions `"`keep_positions' `position'"'
                    }
                }
                local width : word count `kept'
                mata: _cdid_ref_budget_store("`reference'",`slot',`width')
                local generated ""
                if `"`expanded'"'!="" {
                    // Preserve base context during conversion, then keep the fixed nonomitted variables.
                    quietly fvrevar `expanded'
                    local full_generated `"`r(varlist)'"'
                    local full_width : word count `full_generated'
                    if `full_width'!=`position' error 498
                    foreach keep_position of local keep_positions {
                        local generated_variable : word `keep_position' of `full_generated'
                        local generated `"`generated' `generated_variable'"'
                    }
                }
                mata: _cdid_ref_encode_store("`reference'",`slot',st_local("generated"),st_local("expanded"),`omitted')
    }
    local rc=_rc
    capture mata: mata drop `omitted'
    if `rc' exit `rc'
end
