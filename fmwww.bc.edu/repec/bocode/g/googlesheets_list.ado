*! googlesheets_list v0.1.1  2026-11-09
*! v0.1.1: the args file uses a temporary file handle (a fixed handle stayed
*!   open after an error and blocked every later googlesheets command with
*!   r(110)); text shown in the summary is not macro-expanded.
*! List the sheets (tabs) in a Google Sheet.
*!   googlesheets list, spreadsheet("<id-or-url>") [keyfile() tokenfile() verbose]
*! Returns:
*!   r(sheets) -- pipe-separated list of tab titles

program define googlesheets_list, rclass
    version 17.0
    syntax , SPReadsheet(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`macval(client_json)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(token_json)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(spreadsheet)'"')
    mata: st_local("ss", st_global("r(escaped)"))

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"list_sheets","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'""' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets list: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("sheets")
    local sheets `"`r(value)'"'

    display as result _n "[googlesheets list]"
    display as text   `"  spreadsheet: `macval(spreadsheet)'"'
    display as text   `"  tabs: `macval(sheets)'"'

    return local sheets `"`sheets'"'
end
