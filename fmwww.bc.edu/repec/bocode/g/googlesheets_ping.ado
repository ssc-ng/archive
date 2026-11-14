*! googlesheets_ping v0.1.1  2026-11-09
*! v0.1.1: the args file uses a temporary file handle (a fixed handle stayed
*!   open after an error and blocked every later googlesheets command with
*!   r(110)); text shown in the summary is not macro-expanded.
*! Sanity check: confirm OAuth + Sheets API both work against a target Sheet.
*! Displays the spreadsheet title and the list of sheet (tab) names.
*!
*!   googlesheets ping, spreadsheet("<id-or-url>") [keyfile() tokenfile() verbose]

program define googlesheets_ping, rclass
    version 17.0
    syntax , SPReadsheet(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    * Build the args JSON.  Escape backslashes + quotes in any string value
    * so paths with spaces, special chars, or "Shared drives" don't break
    * the JSON parser on the Python side.
    _gs_jesc, raw(`"`macval(client_json)'"')
    local cj  `"`r(escaped)'"'
    _gs_jesc, raw(`"`macval(token_json)'"')
    local tj  `"`r(escaped)'"'
    _gs_jesc, raw(`"`macval(spreadsheet)'"')
    local ss  `"`r(escaped)'"'

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"ping","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'""' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets ping: `r(error)' -- `r(message)'"
        exit 198
    }

    * Cache the in-memory result content -- subsequent _gs_field calls
    * are rclass and would otherwise overwrite r().
    local content `"`r(content)'"'

    _gs_field, content(`"`content'"') key("title")
    local title `"`r(value)'"'
    _gs_field, content(`"`content'"') key("sheets")
    local sheets_list `"`r(value)'"'

    display as result _n "[googlesheets ping]"
    display as text   `"  spreadsheet: `macval(spreadsheet)'"'
    display as text   `"  title:       `macval(title)'"'
    display as text   `"  tabs:        `macval(sheets_list)'"'
    display as text   `"  auth path:   `macval(client_json)'"'
    display as text   `"  token cache: `macval(token_json)'"'

    return local title       `"`title'"'
    return local sheets      `"`sheets_list'"'
    return local client_json `"`client_json'"'
    return local token_json  `"`token_json'"'
end
