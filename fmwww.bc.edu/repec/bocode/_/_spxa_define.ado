*! _spxa_define 1.0.0  21nov2026
*! internal: implement -spxa define-
*! author: Nityahapani
*!
*! Builds a process in the Python interpreter Stata uses and registers it under
*! a Stata handle, either from a process class plus its parameters or from an
*! expression over handles that are already defined.
*!
*! All three pieces of user text travel through global macros and are read back
*! with sfi.Macro.getGlobal(), so that quotes, commas, and brackets in params()
*! and expr() reach Python intact and are never parsed as Stata or Python code.

program define _spxa_define, rclass
    version 16.0

    syntax name(name=handle) [, PRocess(string) PARams(string) EXPr(string) *]

    * ---- Stata-side argument checks, so that errors are conventional ----
    if (`"`process'"' != "" & `"`expr'"' != "") {
        di as err "{p}specify either {bf:process()} with optional " ///
            "{bf:params()}, or {bf:expr()}, not both{p_end}"
        exit 198
    }
    if (`"`process'"' == "" & `"`expr'"' == "") {
        di as err "{p}specify {bf:process(}{it:name}{bf:)} with optional " ///
            "{bf:params(}{it:name}{bf:=}{it:#}{bf:, ...)}, or " ///
            "{bf:expr(}{it:expression}{bf:)}{p_end}"
        di as err "{p}For example, {stata spxa define myvg, process(vg) " ///
            "params(sigma=0.2, nu=0.1)}{p_end}"
        exit 198
    }
    if (`"`process'"' == "" & `"`params'"' != "") {
        di as err "{p}{bf:params()} may be specified only with {bf:process()}{p_end}"
        exit 198
    }

    * ---- anything else after the comma is a spelling mistake ----
    local extra `"`options'"'
    if (`"`extra'"' != "") {
        local first : word 1 of `extra'
        local paren = strpos(`"`first'"', "(")
        if (`paren' > 0) local first = substr(`"`first'"', 1, `paren' - 1)
        di as err "{p}option {bf:`first'} not allowed{p_end}"
        di as err "{p}The options of {bf:spxa define} are {bf:process()}, " ///
            "{bf:params()}, and {bf:expr()}.  A parameter given as " ///
            "{it:name}{bf:=}{it:#} belongs inside {bf:params()}, as in " ///
            "{stata spxa define myvg, process(vg) params(sigma=0.2, nu=0.1)}" ///
            "{p_end}"
        exit 198
    }

    * ---- environment ----
    _spxa_ensure
    local erc = r(rc)
    if (`erc' != 0) exit `erc'

    * ---- hand the text over through global macros: no quoting problems ----
    global __SPXA_PROCESS `"`process'"'
    global __SPXA_PARAMS `"`params'"'
    global __SPXA_EXPR `"`expr'"'

    * Pre-seed the return code: if the Python call were to fail before it could
    * report back, the code below would still see a failure rather than a
    * silent success.
    capture scalar drop __spxa_rc
    scalar __spxa_rc = 499

    * -capture noisily- : the output of the block is shown, and a failure
    * still sets _rc instead of stopping the do-file.
    capture noisily python: import spxa_stata; spxa_stata.spxa_define("`handle'")

    capture global __SPXA_PROCESS
    capture global __SPXA_PARAMS
    capture global __SPXA_EXPR

    local pyrc = 499
    capture local pyrc = scalar(__spxa_rc)
    capture scalar drop __spxa_rc
    if (`pyrc' != 0) exit `pyrc'
end
