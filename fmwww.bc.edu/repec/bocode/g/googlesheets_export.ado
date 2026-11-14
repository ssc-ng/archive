*! googlesheets_export v0.1.3  2026-11-09
*! v0.1.3: a float variable is sent at the precision a float holds (3.58,
*!   not 3.5799999); the args file uses a temporary file handle; text shown
*!   in the summary is not macro-expanded.
*! v0.1.2: send the column types to the helper, so a string variable stays
*!   text in the Sheet ("00123" keeps its leading zeros, "1e5" is not turned
*!   into 100000).  Numeric variables are still written as numbers.
*! v0.1.1: export the temporary file with -quote- so a string that contains a
*!   line break stays one row (it used to split into extra rows in the Sheet).
*! Export the current Stata dataset to a Google Sheet range.
*! Modelled on `export excel using ...'.
*!
*!   googlesheets export using "<id-or-url>" , sheet("Tab name") [range("A1")] ///
*!       [replace] [append] [firstrow(variables)] [keyfile() tokenfile() verbose]
*!
*! Options:
*!   sheet(name)            sheet (tab) to write to
*!   range(A1)              top-left cell (default: A1).  Ignored when append.
*!   replace                overwrite (default behaviour); kept for symmetry
*!                          with `export excel'
*!   append                 append rows to the end of the existing data
*!   firstrow(variables)    write the variable names as the first row
*!
*! The tab named in sheet() must already exist.  Create it first with
*! `googlesheets addsheet, ...' if needed.

program define googlesheets_export
    version 17.0
    syntax using/, SHeet(string) [ RANGE(string) REPLACE APPEND  ///
        FIRSTrow(string) KEYfile(string) TOKENfile(string) VERBose ]

    if "`firstrow'" != "" & "`firstrow'" != "variables" {
        display as error "firstrow() accepts only `variables' (write var names as row 1)"
        exit 198
    }
    if "`range'" == "" local range "A1"

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    * Dump current data to a temp TSV.  The helper will read it.
    tempfile datain
    quietly export delimited using `"`datain'"', delimiter(tab) quote ///
        `=cond("`firstrow'" != "", "", "novarnames")' replace

    * One letter per variable, in dataset order: s = string, f = float,
    * n = any other numeric.  The helper converts only the f and n columns
    * to numbers.  export delimited writes a float with all the digits of its
    * binary value (3.58 is written 3.5799999), so the helper writes an f
    * value as the shortest decimal that gives back the same float (3.58).
    local ctypes ""
    foreach v of varlist _all {
        local _t : type `v'
        if substr("`_t'", 1, 3) == "str"  local ctypes "`ctypes's"
        else if "`_t'" == "float"         local ctypes "`ctypes'f"
        else                              local ctypes "`ctypes'n"
    }
    local hdr = cond("`firstrow'" != "", "true", "false")

    _gs_jesc, raw(`"`macval(client_json)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(token_json)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(using)'"')
    mata: st_local("ss", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(sheet)'"')
    mata: st_local("sh", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(range)'"')
    mata: st_local("rg", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(datain)'"')
    mata: st_local("di", st_global("r(escaped)"))

    local sub = cond("`append'" != "", "append_range", "write_range")

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"`macval(sub)'","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "sheet":"`macval(sh)'","' _n
    file write `h' `"  "range":"`macval(rg)'","' _n
    file write `h' `"  "col_types":"`macval(ctypes)'","' _n
    file write `h' `"  "header_row":`macval(hdr)',"' _n
    file write `h' `"  "data_in_path":"`macval(di)'""' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets export: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("updatedRange")
    local updated `"`r(value)'"'
    _gs_field, content(`"`content'"') key("updatedCells")
    local cells `"`r(value)'"'

    display as result _n "[googlesheets export]"
    display as text   `"  spreadsheet: `macval(using)'"'
    display as text   `"  sheet:       `macval(sheet)'"'
    display as text   "  mode:        `=cond("`append'" != "", "append", "replace")'"
    display as text   `"  updated:     `macval(updated)'   (`macval(cells)' cells)"'
end
