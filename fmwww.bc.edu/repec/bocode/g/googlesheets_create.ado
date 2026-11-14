*! googlesheets_create v0.1.2  2026-11-09
*! v0.1.2: the args file uses a temporary file handle (a fixed handle stayed
*!   open after an error and blocked every later googlesheets command with
*!   r(110)); text shown in the summary is not macro-expanded.
*! Create a brand-new Google Sheet (spreadsheet) in the user's Drive and
*! return its id and URL, so a script can build a report from scratch.
*!   googlesheets create, title("My report") [sheettitle("Data")            ///
*!       keyfile() tokenfile() verbose]
*!
*! Returns:
*!   r(id)          the new spreadsheet id
*!   r(url)         the new spreadsheet URL (open it in a browser)
*!   r(spreadsheet) the URL as well (drop-in for later spreadsheet()/using)
*!   r(title)       the spreadsheet title

program define googlesheets_create, rclass
    version 17.0
    syntax , TITLE(string) [ SHEETtitle(string)                 ///
        KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`macval(client_json)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(token_json)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(title)'"')
    mata: st_local("ti", st_global("r(escaped)"))

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"create_spreadsheet","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "title":"`macval(ti)'""'
    if `"`macval(sheettitle)'"' != "" {
        _gs_jesc, raw(`"`macval(sheettitle)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "sheet_title":"`macval(_rx)'""'
    }
    file write `h' _n `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets create: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("spreadsheetId")
    local new_id `"`r(value)'"'
    _gs_field, content(`"`content'"') key("spreadsheetUrl")
    local new_url `"`r(value)'"'
    _gs_field, content(`"`content'"') key("title")
    local new_title `"`r(value)'"'

    display as result _n "[googlesheets create]"
    display as text   `"  created:  `macval(new_title)'"'
    display as text   `"  id:       `macval(new_id)'"'
    display as text   `"  url:      {browse "`new_url'":`new_url'}"'

    return local id          `"`new_id'"'
    return local url         `"`new_url'"'
    return local spreadsheet `"`new_url'"'
    return local title       `"`new_title'"'
end
