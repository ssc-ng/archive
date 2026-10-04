*! duvmdiag 1.2.0  2026-09-29  Abdelkrim Araar
*! Pre-estimation diagnostic of the unit-value model: same syntax as duvm,
*! runs the two stages without the variance and reports what will make the
*! elasticities fragile (few reporters, tiny clusters, a correction that
*! swamps the price variation, negative quality elasticities, ill-conditioned
*! moment matrix).
program define duvmdiag, rclass
    version 14.2
    * notable (an option of duvm) is accepted: the diagnostics show no table
    syntax anything(name=namelist id="goods") [if] [in] [aweight fweight pweight iweight] , [ DEC(integer 3) noTABle * ]
    local w ""
    if "`weight'" != "" local w "[`weight'`exp']"
    capture qui duvm `namelist' `if' `in' `w', `options' vce(none) notable
    if _rc {
        * quietly hides the message of duvm: the call again, shown, then the error
        local rc = _rc
        if `rc' != 1 capture noisily duvm `namelist' `if' `in' `w', `options' vce(none) notable
        exit `rc'
    }
    duvm_estat diagnostics, dec(`dec')
    return add
end
