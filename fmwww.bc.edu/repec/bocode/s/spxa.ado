*! spxa 1.0.0  21nov2026
*! Levy process algebra for Stata: exact triplet arithmetic, simulation, cumulants
*! author: Nityahapani
*!
*! Front end.  Dispatches to the internal programs _spxa_define,
*! _spxa_simulate, _spxa_report, _spxa_list, _spxa_drop and _spxa_clear.
*!
*! Parsing is done with -syntax- and -tokenize- so that everything after the
*! comma is passed through untouched: quoted parameters, commas, and brackets
*! in expr() all survive the round trip to Python.

program define spxa, rclass
    version 16.0

    syntax [anything(name=args)] [, *]

    tokenize `"`args'"'
    local sub `"`1'"'
    local target `"`2'"'

    if (`"`sub'"' == "") {
        di as err "{p}spxa requires a subcommand.{p_end}"
        di as err "{p}Valid subcommands are {bf:define}, {bf:simulate}, " ///
            "{bf:report}, {bf:list}, {bf:drop}, and {bf:clear}.{p_end}"
        di as err "{p}Type {stata help spxa} for syntax and examples.{p_end}"
        exit 198
    }

    if !inlist("`sub'", "define", "simulate", "report", "list", "drop", "clear") {
        di as err "{p}{bf:`sub'} is not a valid spxa subcommand.{p_end}"
        di as err "{p}Valid subcommands are {bf:define}, {bf:simulate}, " ///
            "{bf:report}, {bf:list}, {bf:drop}, and {bf:clear}.{p_end}"
        di as err "{p}Type {stata help spxa} for syntax and examples.{p_end}"
        exit 198
    }

    if (`"`3'"' != "") {
        di as err "{p}too many arguments: {bf:spxa `sub'} takes at most one " ///
            "{it:name}{p_end}"
        exit 198
    }

    if (`"`target'"' != "" & !inlist("`sub'", "define", "simulate", ///
        "report", "drop")) {
        di as err "{p}{bf:spxa `sub'} does not take a {it:name}{p_end}"
        exit 198
    }

    if (`"`target'"' == "" & inlist("`sub'", "define", "simulate", ///
        "report", "drop")) {
        di as err "{p}{bf:spxa `sub'} requires the {it:name} of a process.{p_end}"
        di as err "{p}For example, {stata spxa `sub' model}.{p_end}"
        exit 198
    }

    local optstr `"`*'"'
    local comma ""
    if (`"`optstr'"' != "") local comma ","

    * -capture noisily- shows everything the command prints while making the
    * return code available here; a called program's -exit- returns with _rc
    * set, and passing it on is what makes the error visible to the user.
    capture noisily _spxa_`sub' `target' `comma' `optstr'
    local rc = _rc
    if (`rc' != 0) {
        di as err ""
        di as err "{p}{bf:spxa `sub'} failed (error `rc').{p_end}"
        exit `rc'
    }

    * r() results set inside the subprogram are cleared when it ends, so they
    * are copied into the r() of this command, which is what the user sees.
    capture return add
end
