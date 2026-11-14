*! googlesheets_runpy v0.1.2  2026-11-09
*! v0.1.2: temporary file handle; verbose is passed on to the helper, which
*!   then also writes its full payload (with any traceback) next to the
*!   result file; without verbose it no longer leaves that file behind.
*! v0.1.1: diagnose an empty helper result file (dead/interrupted first-run
*!         setup) with an actionable message instead of letting the empty
*!         blob abort downstream with the opaque "option content() required".
*! Shell into googlesheets_helper.py with an args JSON file, then surface
*! the status/message/error fields PLUS the raw result-file contents in
*! r() macros.  INTERNAL helper.
*!
*! Returns:
*!   r(status)    "ok" or "error"
*!   r(message)   error message text (empty when ok)
*!   r(error)     exception name (empty when ok)
*!   r(content)   the full result-file contents as one string -- the
*!                caller passes this to _gs_field to extract
*!                individual key=value fields.  We can't return a path
*!                because Stata frees tempfiles when the sub-program
*!                ends, deleting the underlying file before the caller
*!                gets to read it.

program define googlesheets_runpy, rclass
    version 17.0
    syntax , ARGS(string) [ VERBose ]

    capture findfile googlesheets_helper.py
    if _rc {
        display as error "googlesheets: googlesheets_helper.py not on adopath."
        display as error "  Reinstall the package."
        exit 601
    }
    local helper "`r(fn)'"

    tempfile outjson
    tempname gsfh
    quietly file open `gsfh' using `"`outjson'"', write text replace
    file close `gsfh'

    if lower("`c(os)'") == "windows" {
        local PY "python"
    }
    else {
        local PY "python3"
    }

    if "`verbose'" != "" {
        display as text `"[googlesheets] `PY' "`helper'" "`args'" "`outjson'" verbose"'
    }
    quietly shell `PY' "`helper'" "`args'" "`outjson'" `verbose'

    * The result file exists already (created above), so a helper that never
    * ran shows up as empty content, which is diagnosed below.

    * Slurp the entire result-file into a single local so it survives the
    * tempfile cleanup at end-of-program.  These files are small (a few
    * lines of key=value).
    tempname jh
    file open `jh' using `"`outjson'"', read text
    local _content ""
    file read `jh' line
    while r(eof) == 0 {
        if "`_content'" == "" {
            local _content `"`line'"'
        }
        else {
            local _content `"`_content'`=char(10)'`line'"'
        }
        file read `jh' line
    }
    file close `jh'

    if "`verbose'" != "" {
        display as text "[googlesheets] result content:"
        display as text `"`_content'"'
    }

    * A healthy helper always writes at least a `status=' line -- on success
    * AND on a caught error.  A truly empty result file therefore means the
    * helper process died before it could write anything: almost always a
    * first-run setup problem (no python3 on PATH, or the one-time helper-
    * environment build / Google sign-in did not finish) rather than a Sheets
    * error.  Diagnose it here.  Otherwise the empty string flows into the
    * _gs_field calls below and the command aborts with the opaque, misleading
    * "option content() required".
    if strtrim(`"`_content'"') == "" {
        display as error "googlesheets: the Python helper returned no output, so the command could not run."
        display as error "  This is a setup issue on this machine, not a spreadsheet error.  Check, in order:"
        display as error `"    1. A working Python: run  `PY' --version  in a terminal (Stata used `PY')."'
        display as error "    2. First-time use builds a one-time helper environment and opens a browser"
        display as error "       for Google sign-in; finish that once, then re-run.  See help googlesheets##setup."
        display as error "    3. Re-run this command with the  verbose  option to print the exact helper"
        display as error "       command, then run that command yourself in a terminal to read the real error."
        exit 198
    }

    * Extract the three universal status fields from the in-memory copy.
    _gs_field, content(`"`_content'"') key("status")
    return local status  `"`r(value)'"'
    _gs_field, content(`"`_content'"') key("message")
    return local message `"`r(value)'"'
    _gs_field, content(`"`_content'"') key("error")
    return local error   `"`r(value)'"'

    return local content `"`_content'"'
    return local helper  `"`helper'"'
end
