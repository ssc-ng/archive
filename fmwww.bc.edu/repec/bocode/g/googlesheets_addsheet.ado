*! googlesheets_addsheet v0.1.1  2026-11-09
*! v0.1.1: the args file uses a temporary file handle (a fixed handle stayed
*!   open after an error and blocked every later googlesheets command with
*!   r(110)); text shown in the summary is not macro-expanded.
*! Add a new sheet (tab) to a Google Sheet.
*!   googlesheets addsheet, spreadsheet("<id-or-url>") title("New Tab")    ///
*!       [rows(1000) cols(26) index(0) keyfile() tokenfile() verbose]

program define googlesheets_addsheet, rclass
    version 17.0
    syntax , SPReadsheet(string) TITLE(string)              ///
        [ ROWS(integer 0) COLS(integer 0) INDex(integer -1) ///
          KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`macval(client_json)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(token_json)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(spreadsheet)'"')
    mata: st_local("ss", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(title)'"')
    mata: st_local("ti", st_global("r(escaped)"))

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"add_sheet","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "title":"`macval(ti)'""'
    if `rows' > 0  {
        file write `h' `","' _n `"  "rows":`macval(rows)'"'
    }
    if `cols' > 0  {
        file write `h' `","' _n `"  "cols":`macval(cols)'"'
    }
    if `index' >= 0 {
        file write `h' `","' _n `"  "index":`macval(index)'"'
    }
    file write `h' _n `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets addsheet: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("title")
    local new_title `"`r(value)'"'
    _gs_field, content(`"`content'"') key("sheetId")
    local new_id `"`r(value)'"'

    display as result _n "[googlesheets addsheet]"
    display as text   `"  added tab:  `macval(new_title)'  (sheetId=`macval(new_id)')"'
    display as text   `"  in:         `macval(spreadsheet)'"'

    return local title    `"`new_title'"'
    return local sheetId  `"`new_id'"'
end
