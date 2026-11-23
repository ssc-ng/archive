*! _spxa_report 1.0.0  21nov2026
*! internal: implement -spxa report-
*! author: Nityahapani
*!
*! Displays the law of a registered process and stores the numbers in r().
*! All output and all r() results are produced by the Python adapter.

program define _spxa_report, rclass
    version 16.0

    syntax name(name=handle) [, CUMulants(integer 4) MATrix(name) STORY DETail *]

    * ---- anything else after the comma is a spelling mistake ----
    local extra `"`options'"'
    if (`"`extra'"' != "") {
        local first : word 1 of `extra'
        local paren = strpos(`"`first'"', "(")
        if (`paren' > 0) local first = substr(`"`first'"', 1, `paren' - 1)
        di as err "{p}option {bf:`first'} not allowed{p_end}"
        di as err "{p}Type {stata help spxa} for the options of {bf:spxa report}.{p_end}"
        exit 198
    }

    if (`cumulants' < 1 | `cumulants' > 20) {
        di as err "{p}{bf:cumulants()} must lie between 1 and 20{p_end}"
        exit 198
    }

    local matname `"`matrix'"'
    local usestory = 0
    if (`"`story'"' != "") local usestory = 1
    local usedetail = 0
    if (`"`detail'"' != "") local usedetail = 1

    _spxa_ensure
    local erc = r(rc)
    if (`erc' != 0) exit `erc'

    * Pre-seed the return code: if the Python call were to fail before it could
    * report back, the code below would still see a failure rather than a
    * silent success.
    capture scalar drop __spxa_rc
    scalar __spxa_rc = 499

    * -capture noisily- : the output of the block is shown, and a failure
    * still sets _rc instead of stopping the do-file.
    capture noisily python: import spxa_stata; spxa_stata.spxa_report("`handle'", `cumulants', "`matname'", `usestory', `usedetail')

    local pyrc = 499
    capture local pyrc = scalar(__spxa_rc)
    capture scalar drop __spxa_rc
    if (`pyrc' != 0) exit `pyrc'
end
