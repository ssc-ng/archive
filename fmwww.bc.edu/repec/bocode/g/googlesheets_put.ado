*! googlesheets_put v0.1.3  2026-11-09
*! v0.1.3: value() is rewritten as a JSON number, so 5. and +5 no longer
*!   make the helper fail with JSONDecodeError; the args file uses a
*!   temporary file handle; text shown in the summary is not macro-expanded.
*! v0.1.2: a missing value in matrix(), or value(.), is sent as an empty
*!   string, which blanks the cell.  JSON null, sent before, tells Sheets to
*!   leave the cell as it was, so an old value stayed in place.
*! Surgical placement of a single value, formula, or matrix into specific
*! cells of a Google Sheet.  Modelled on Stata's `putexcel'.
*!
*!   googlesheets put using "<id-or-url>" , sheet("Tab") cell(A1)               ///
*!       ( value(.)   |  string("text")  |  formula("=SUM(...)")  |  matrix(M) ) ///
*!       [keyfile() tokenfile() verbose]
*!
*! Exactly one of value/string/formula/matrix must be supplied.

program define googlesheets_put
    version 17.0
    syntax using/, SHeet(string) CELL(string)             ///
        [ VALue(string) STRing(string) FORMula(string) MATrix(string) NAMES ///
          KEYfile(string) TOKENfile(string) VERBose ]

    * Validate exactly-one source.
    local _n = 0
    if `"`macval(value)'"' != ""   local _n = `_n' + 1
    if `"`macval(string)'"' != ""  local _n = `_n' + 1
    if `"`macval(formula)'"' != "" local _n = `_n' + 1
    if `"`macval(matrix)'"' != ""  local _n = `_n' + 1
    if `_n' != 1 {
        display as error "googlesheets put: pass exactly one of value() / string() / formula() / matrix()."
        exit 198
    }
    if "`names'" != "" & `"`matrix'"' == "" {
        display as error "googlesheets put: names is allowed only with matrix()."
        exit 198
    }

    * Build a 2D values list as JSON.
    if `"`macval(matrix)'"' != "" {
        capture confirm matrix `matrix'
        if _rc {
            display as error "googlesheets put: matrix(`matrix') -- no such matrix in memory"
            exit 198
        }
        local nr = rowsof(`matrix')
        local nc = colsof(`matrix')
        if "`names'" != "" {
            local _rn : rownames `matrix'
            local _cn : colnames `matrix'
        }
        local rows_json "["
        if "`names'" != "" {
            * Header row: an empty corner cell, then the column names.
            local rows_json `"`macval(rows_json)'["""'
            forvalues j = 1/`nc' {
                local _c : word `j' of `_cn'
                _gs_jesc, raw(`"`macval(_c)'"')
                mata: st_local("_rx", st_global("r(escaped)"))
                local rows_json `"`macval(rows_json)',"`macval(_rx)'""'
            }
            local rows_json `"`macval(rows_json)']"'
        }
        forvalues i = 1/`nr' {
            if `i' > 1 | "`names'" != "" {
                local rows_json `"`macval(rows_json)',"'
            }
            local rows_json `"`macval(rows_json)'["'
            if "`names'" != "" {
                local _r : word `i' of `_rn'
                _gs_jesc, raw(`"`macval(_r)'"')
                mata: st_local("_rx", st_global("r(escaped)"))
                local rows_json `"`macval(rows_json)'"`macval(_rx)'","'
            }
            forvalues j = 1/`nc' {
                local v = `matrix'[`i', `j']
                if `j' > 1 {
                    local rows_json `"`macval(rows_json)',"'
                }
                if `v' < . {
                    * JSON requires a leading 0 before the decimal -- e.g.
                    * "0.42" not ".42".  strofreal pads it correctly.
                    local _vstr = strofreal(`v', "%18.0g")
                    if substr("`_vstr'", 1, 1) == "." {
                        local _vstr "0`_vstr'"
                    }
                    else if substr("`_vstr'", 1, 2) == "-." {
                        local _vstr = "-0" + substr("`_vstr'", 2, .)
                    }
                    local rows_json `"`macval(rows_json)'`_vstr'"'
                }
                else {
                    local rows_json `"`macval(rows_json)'"""'
                }
            }
            local rows_json `"`macval(rows_json)']"'
        }
        local rows_json `"`macval(rows_json)']"'
        local range `"`cell'"'
    }
    else {
        if `"`macval(value)'"' != "" {
            * Validate numeric.  A Stata missing value (. or .a-.z) blanks
            * the cell (an empty string; JSON null would leave the old value).
            * Any other non-numeric input fails confirm and aborts.
            if ustrregexm(`"`value'"', "^\.[a-z]?$") {
                local rows_json `"[[""]]"'
            }
            else {
                confirm number `value'
                * Rewrite the number as JSON writes it: Stata accepts forms
                * such as 5. and +5 that are not valid JSON.  Then add the
                * leading zero JSON requires on .42 -> 0.42.
                local _vs = strofreal(`value', "%18.0g")
                if substr("`_vs'", 1, 1) == "."          local _vs "0`_vs'"
                else if substr("`_vs'", 1, 2) == "-."   local _vs = "-0" + substr("`_vs'", 2, .)
                local rows_json `"[[`_vs']]"'
            }
        }
        else if `"`macval(string)'"' != "" {
            _gs_jesc, raw(`"`macval(string)'"')
            mata: st_local("_rx", st_global("r(escaped)"))
            local rows_json `"[["`macval(_rx)'"]]"'
        }
        else {
            _gs_jesc, raw(`"`macval(formula)'"')
            mata: st_local("_rx", st_global("r(escaped)"))
            local rows_json `"[["`macval(_rx)'"]]"'
        }
        local range `"`cell'"'
    }

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

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

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"write_range","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "sheet":"`macval(sh)'","' _n
    file write `h' `"  "range":"`macval(rg)'","' _n
    file write `h' `"  "values":`macval(rows_json)'"' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets put: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("updatedRange")
    local upd `"`r(value)'"'

    display as result _n "[googlesheets put]"
    display as text   `"  spreadsheet: `macval(using)'"'
    display as text   `"  cell:        `macval(sheet)'!`macval(cell)'"'
    display as text   `"  updated:     `macval(upd)'"'
end
