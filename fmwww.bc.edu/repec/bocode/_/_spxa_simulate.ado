*! _spxa_simulate 1.0.0  21nov2026
*! internal: implement -spxa simulate-
*! author: Nityahapani
*!
*! Simulates paths of a registered process and writes them to the current
*! dataset, replacing whatever was there (hence the -clear- requirement).
*!
*! Numbers are passed positionally; the two pieces of free text (the seed and
*! the new variable name) travel through global macros and are read back with
*! sfi.Macro.getGlobal(), so that no user input is ever pasted into Python
*! source code.

program define _spxa_simulate, rclass
    version 16.0

    syntax name(name=handle) [, PATHS(integer 1) STEPS(integer 252) T(real 1) ///
        SEED(string) GENerate(name=x) INITial(real .) LOG WIDE CLEAR *]

    * ---- argument checking, so that errors are conventional Stata errors ----
    if (`paths' < 1) {
        di as err "{p}{bf:paths()} must be at least 1{p_end}"
        exit 198
    }
    if (`steps' < 1) {
        di as err "{p}{bf:steps()} must be at least 1{p_end}"
        exit 198
    }
    if (missing(`t') | `t' <= 0) {
        di as err "{p}{bf:t()} (the terminal time) must be strictly positive{p_end}"
        exit 198
    }

    * initial() is optional; "not given" and "given as 0" mean different things
    * when -log- is used, so the distinction is carried to Python explicitly.
    local hasinit = !missing(`initial')
    if (missing(`initial')) local initial = 0

    * ---- anything else after the comma is a spelling mistake ----
    local extra `"`options'"'
    if (`"`extra'"' != "") {
        local first : word 1 of `extra'
        local paren = strpos(`"`first'"', "(")
        if (`paren' > 0) local first = substr(`"`first'"', 1, `paren' - 1)
        di as err "{p}option {bf:`first'} not allowed{p_end}"
        di as err "{p}Type {stata help spxa} for the options of " ///
            "{bf:spxa simulate}.{p_end}"
        exit 198
    }

    * ---- the command replaces the data in memory: require -clear- ----
    if (c(k) > 0 | c(N) > 0) {
        if (`"`clear'"' == "") {
            di as err "{p}{bf:spxa simulate} replaces the data in memory.{p_end}"
            di as err "{p}Specify the {bf:clear} option to proceed.{p_end}"
            error 4
        }
        quietly drop _all
    }

    * ---- seed: honour -seed()- or fall back to Stata's -set seed- ----
    local seedtxt `"`seed'"'
    if (`"`seedtxt'"' == "") local seedtxt "`c(seed)'"

    local uselog = 0
    if (`"`log'"' != "") local uselog = 1
    local usewide = 0
    if (`"`wide'"' != "") local usewide = 1

    * ---- environment ----
    _spxa_ensure
    local erc = r(rc)
    if (`erc' != 0) exit `erc'

    * ---- hand the text over through globals; numbers go in directly ----
    global __SPXA_SEED `"`seedtxt'"'
    global __SPXA_GENERATE `"`generate'"'

    * Pre-seed the return code: if the Python call were to fail before it could
    * report back, the code below would still see a failure rather than a
    * silent success.
    capture scalar drop __spxa_rc
    scalar __spxa_rc = 499

    * -capture noisily- : the output of the block is shown, and a failure
    * still sets _rc instead of stopping the do-file.
    capture noisily python: import spxa_stata; spxa_stata.spxa_simulate("`handle'", `paths', `steps', `t', `initial', `uselog', `usewide', `hasinit')

    capture global __SPXA_SEED
    capture global __SPXA_GENERATE

    local pyrc = 499
    capture local pyrc = scalar(__spxa_rc)
    capture scalar drop __spxa_rc
    if (`pyrc' != 0) exit `pyrc'

    * ---- summary, from the r() results the Python side stored ----
    local nobs = r(obs)
    local sawseed `"`seedtxt'"'
    if (`"`sawseed'"' == "") local sawseed "`c(seed)'"
    di as text ""
    di as text "{p 2 4}simulated {res:`paths'}{txt} path(s) of {res:`handle'}: " ///
        "{txt:`nobs'} observations, t in [0, " %g r(T) "]{p_end}"
    * r(stepvar) is the integer time index, the variable xtset needs
    local stepvar `"`r(stepvar)'"'
    if (`usewide') {
        di as text "{p 2 4}layout: wide; {bf:t} is the time index and " ///
            "`paths' path variable(s) follow{p_end}"
    }
    else {
        di as text "{p 2 4}layout: long; {bf:`stepvar'} is the time index and " ///
            "{bf:t} the time itself{p_end}"
    }
    if (`"`stepvar'"' != "") {
        local idvar "`stepvar'"
        if (!`usewide') local idvar "path `stepvar'"
        di as text "{p 2 8}type {stata xtset `idvar'} to use the data with " ///
            "Stata's panel and time-series commands{p_end}"
    }
    if (`"`sawseed'"' != "") {
        di as text "{p 2 4}random-number seed: `sawseed'{p_end}"
    }
end
