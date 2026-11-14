*! googlesheets_renamesheet v0.1.1  2026-11-09
*! v0.1.1: the args file uses a temporary file handle (a fixed handle stayed
*!   open after an error and blocked every later googlesheets command with
*!   r(110)); text shown in the summary is not macro-expanded.
*!   googlesheets renamesheet, spreadsheet("<id-or-url>") from("Old") to("New")

program define googlesheets_renamesheet
    version 17.0
    syntax , SPReadsheet(string) FROM(string) TO(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local cj_raw `"`r(client_json)'"'
    local tj_raw `"`r(token_json)'"'

    _gs_jesc, raw(`"`macval(cj_raw)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(tj_raw)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(spreadsheet)'"')
    mata: st_local("ss", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(from)'"')
    mata: st_local("fr", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(to)'"')
    mata: st_local("to_j", st_global("r(escaped)"))

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"rename_sheet","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "old_title":"`macval(fr)'","' _n
    file write `h' `"  "new_title":"`macval(to_j)'""' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets renamesheet: `r(error)' -- `r(message)'"
        exit 198
    }
    display as result _n "[googlesheets renamesheet]"
    display as text   `"  renamed:   `macval(from)' -> `macval(to)'"'
end
