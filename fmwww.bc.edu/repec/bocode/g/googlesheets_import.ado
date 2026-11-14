*! googlesheets_import v0.1.4  2026-11-09
*! v0.1.4: since() is checked before the args file is opened, and that file
*!   uses a temporary handle: a since() without "=" left the fixed handle _h
*!   open, and every later googlesheets command failed with r(110).  Text
*!   shown in the summary is not macro-expanded.
*! v0.1.3: without clear, refuse (error 4, "no; data in memory would be
*!   lost") when data are in memory, as import excel does.  The data in
*!   memory are no longer dropped before the Sheet is read, so a failed read
*!   leaves them intact.  Stores r(N), r(k), r(spreadsheet), r(sheet).
*! v0.1.2: bindquote(strict), so a cell that contains line breaks (a Google
*!   Form paragraph answer, say) is read as one value, not several rows.
*! v0.1.1 2026-08-16: escape the output tempfile path into the args JSON
*!   (Windows backslash paths otherwise break json.load).
*! Import a range of cells from a Google Sheet into the current Stata
*! dataset.  Modelled on `import excel using ...'.
*!
*!   googlesheets import using "<id-or-url>" , sheet("Tab name") [range("A1:Z")]   ///
*!       [firstrow] [clear] [stringall] [since(timestamp=2026-01-01)] [tail(50)] ///
*!       [keyfile() tokenfile() verbose]
*!
*! Options:
*!   sheet(name)    sheet (tab) to read from
*!   range(A1:Z)    optional cell range (default: all cells on the sheet)
*!   firstrow       treat the first row as variable names (like `import excel')
*!   clear          replace the data in memory (like `import excel'); without
*!                  it, import refuses when data are in memory
*!   stringall      force all columns to string (skip Stata's type detection)
*!   since(col=val) keep only rows where `col' (header name or 0-based int) >= val
*!   tail(N)        keep only the last N rows (after `since' filter)
*!
*! Form-data shortcuts: combine `since' + `tail' to grab "new responses
*! since X" or "the most recent N responses" without dragging the full
*! Form Responses tab through every refresh.

program define googlesheets_import, rclass
    version 17.0
    syntax using/, SHeet(string) [ RANGE(string) FIRSTrow CLEAR STRINGall ///
        SInce(string) TAIL(integer 0) KEYfile(string) TOKENfile(string) VERBose ]

    * Same rule as import excel: any data in memory (even unchanged data)
    * need clear.  The data are replaced only after the read succeeds.
    if "`clear'" == "" & (_N > 0 | c(k) > 0 | c(changed)) {
        display as error "no; data in memory would be lost"
        exit 4
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

    * since() is parsed as "column=value".  Checked before the args file is
    * opened, so a bad since() leaves no file open.
    if `"`macval(since)'"' != "" {
        mata: st_local("_eqp", strofreal(strpos(st_local("since"), "=")))
        if `_eqp' == 0 {
            display as error "since() must be in the form column=value"
            exit 198
        }
        mata: st_local("_scol", substr(st_local("since"), 1, `_eqp' - 1))
        mata: st_local("_sval", substr(st_local("since"), `_eqp' + 1, .))
        _gs_jesc, raw(`"`macval(_scol)'"')
        mata: st_local("_scol_j", st_global("r(escaped)"))
        _gs_jesc, raw(`"`macval(_sval)'"')
        mata: st_local("_sval_j", st_global("r(escaped)"))
    }

    * Data-out path (TSV the helper will write).
    tempfile dataout

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"read_range","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "sheet":"`macval(sh)'""'
    if "`range'" != "" {
        file write `h' `","' _n `"  "range":"`macval(rg)'""'
    }
    if `tail' > 0     {
        file write `h' `","' _n `"  "tail":`macval(tail)'"'
    }
    if `"`macval(since)'"' != "" {
        file write `h' `","' _n `"  "since":{"column":"`macval(_scol_j)'","value":"`macval(_sval_j)'"}"'
    }
    * Escape the output tempfile path: on Windows it is a backslash path, and
    * an unescaped backslash is an illegal JSON string escape (\U, \A, ...),
    * which breaks json.load on the Python side.  export.ado escapes datain the
    * same way.
    _gs_jesc, raw(`"`macval(dataout)'"')
    mata: st_local("dataout_j", st_global("r(escaped)"))
    file write `h' `","' _n `"  "data_out_path":"`macval(dataout_j)'""' _n
    file write `h' `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets import: `r(error)' -- `r(message)'"
        exit 198
    }

    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("nrows")
    local nrows = real("`r(value)'")
    _gs_field, content(`"`content'"') key("ncols")
    local ncols = real("`r(value)'")

    capture confirm file `"`dataout'"'
    if _rc {
        display as error "googlesheets import: no data file written (`nrows' rows reported)."
        exit 198
    }

    * Load via import delimited.  Stata's option is varnames(#) -- 1 for
    * "row 1 holds variable names", "nonames" for "every row is data".
    local _vn = cond("`firstrow'" != "", "varnames(1)", "varnames(nonames)")
    local _sa = cond("`stringall'" != "", "stringcols(_all)", "")
    quietly import delimited using `"`dataout'"', delimiter(tab) bindquote(strict) `_vn' `_sa' clear

    display as result _n "[googlesheets import]"
    display as text   `"  spreadsheet: `macval(using)'"'
    display as text   `"  sheet:       `macval(sheet)'"'
    if `"`macval(range)'"' != "" {
        display as text `"  range:       `macval(range)'"'
    }
    if `"`macval(since)'"' != "" {
        display as text `"  since:       `macval(since)'"'
    }
    if `tail'  > 0     display as text "  tail:        `tail'"
    display as text   "  loaded:      `=_N' obs x `=c(k)' vars  (helper reported `nrows' x `ncols')"

    return scalar N = _N
    return scalar k = c(k)
    return local spreadsheet `"`using'"'
    return local sheet       `"`sheet'"'
end
