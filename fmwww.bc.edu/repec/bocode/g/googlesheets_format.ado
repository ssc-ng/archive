*! googlesheets_format v0.1.1  2026-11-09
*! v0.1.1: range() may name its own tab in A1 notation ('Auto'!A1:B2); the
*!   apostrophes used to stop the command with r(198) before the helper ran.
*!   The args file uses a temporary file handle.
*! Apply cell formatting (background colour, font, weight, number format)
*! to a range in a Google Sheet.
*!
*!   googlesheets format using "<id-or-url>" , sheet("Tab") range("A1:E1") ///
*!       [bgcolor("#1B2D55")] [fgcolor("#FFFFFF")] [bold]                  ///
*!       [font("Montserrat")] [fontsize(12)]                               ///
*!       [numfmt("0.0%")] [halign(left|center|right)] [wrap]               ///
*!       [keyfile() tokenfile() verbose]
*!
*! At least one styling option must be supplied.

program define googlesheets_format
    version 17.0
    syntax using/, SHeet(string) RANGE(string)              ///
        [ BGcolor(string) FGcolor(string) BOLD ITALic       ///
          FONT(string) FONTSIZE(integer 0) NUMFMT(string)   ///
          HALign(string) WRAP                               ///
          KEYfile(string) TOKENfile(string) VERBose ]

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
    file write `h' `"  "subcommand":"format_range","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "sheet":"`macval(sh)'","' _n
    file write `h' `"  "range":"`macval(rg)'""'
    if `"`macval(bgcolor)'"' != "" {
        _gs_jesc, raw(`"`macval(bgcolor)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "bgcolor":"`macval(_rx)'""'
    }
    if `"`macval(fgcolor)'"' != "" {
        _gs_jesc, raw(`"`macval(fgcolor)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "fgcolor":"`macval(_rx)'""'
    }
    if "`bold'" != ""    {
        file write `h' `","' _n `"  "bold":true"'
    }
    if "`italic'" != ""  {
        file write `h' `","' _n `"  "italic":true"'
    }
    if `"`macval(font)'"' != "" {
        _gs_jesc, raw(`"`macval(font)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "font":"`macval(_rx)'""'
    }
    if `fontsize' > 0    {
        file write `h' `","' _n `"  "font_size":`macval(fontsize)'"'
    }
    if `"`macval(numfmt)'"' != "" {
        _gs_jesc, raw(`"`macval(numfmt)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "number_format":"`macval(_rx)'""'
    }
    if `"`macval(halign)'"' != "" {
        _gs_jesc, raw(`"`macval(halign)'"')
        mata: st_local("_rx", st_global("r(escaped)"))
        file write `h' `","' _n `"  "horizontal_align":"`macval(_rx)'""'
    }
    if "`wrap'" != ""    {
        file write `h' `","' _n `"  "wrap":true"'
    }
    file write `h' _n `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets format: `r(error)' -- `r(message)'"
        exit 198
    }

    display as result _n "[googlesheets format]"
    display as text   `"  spreadsheet: `macval(using)'"'
    * A range that names its own tab ('Auto'!A1:B2) is shown as given.
    mata: st_local("_hasbang", strofreal(strpos(st_local("range"), "!") > 0))
    if `_hasbang' {
        display as text `"  range:       `macval(range)'"'
    }
    else {
        display as text `"  range:       `macval(sheet)'!`macval(range)'"'
    }
end
