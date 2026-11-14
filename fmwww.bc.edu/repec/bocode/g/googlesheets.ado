*! googlesheets v0.1.7  2026-11-09
*! v0.1.7: every subcommand writes its args file through a temporary file
*!   handle (import with a bad since() left a fixed handle open, so every
*!   later command failed with r(110)); apostrophes and backticks in tab
*!   names, ranges and text are passed safely ('Auto'!A1:B2 in format, a
*!   tab named Bob's data in addchart); export sends floats at float
*!   precision (3.58, not 3.5799999); put value(5.) and value(+5) work;
*!   the helper's payload sidecar is written only with verbose; Windows
*!   default client path has single separators and no C:\Users\Default guess.
*! v0.1.6: import without clear refuses when data are in memory (error 4,
*!   as import excel); multi-account URLs (/spreadsheets/u/N/d/<id>) are
*!   parsed; export keeps string variables as text; put writes a missing
*!   value as a blank cell; addchart rejects an unknown type(); a tab name
*!   with an apostrophe is quoted correctly in A1 ranges; a service-account
*!   key is recognized from the file and signs in with no browser.
*! Stata wrapper for the Google Sheets API.
*!
*! Read, write, and structurally edit Google Sheets from Stata, the way
*! `import excel' / `export excel' / `putexcel' work but against a Sheet
*! identified by URL or spreadsheet ID.  Surgical placement of values
*! and matrices, on-demand cell formatting, sheet (tab) management, and
*! filtered reads of Google Forms response sheets.
*!
*! Subcommand interface:
*!     googlesheets import      using "<id-or-url>" [, ...]
*!     googlesheets export      using "<id-or-url>" [, ...]
*!     googlesheets put         using "<id-or-url>" , cell() ...
*!     googlesheets list                            , spreadsheet()
*!     googlesheets ping                            , spreadsheet()
*!     googlesheets create                          , title() [sheettitle()]
*!     googlesheets addsheet                        , spreadsheet() title()
*!     googlesheets deletesheet                     , spreadsheet() title()
*!     googlesheets renamesheet                     , spreadsheet() ...
*!     googlesheets format      using "<id-or-url>" , sheet() range() ...
*!     googlesheets addchart    using "<id-or-url>" , sheet() type() ...
*!
*! Setup: see `help googlesheets##setup'.
*!
*! Authorship: Eric Booth, Texas 2036.  MIT-licensed.

program define googlesheets
    version 17.0
    * Subcommand may be followed immediately by a comma (no space) when
    * the user types e.g. `googlesheets ping, spreadsheet(...)'.  Use
    * parse(", ") so gettoken peels just the keyword and leaves the
    * leading comma on `0' for the subcommand handler's syntax line.
    gettoken sub 0 : 0, parse(", ")
    if "`sub'" == "" {
        display as error "googlesheets: missing subcommand"
        display as error "  Valid: create | import | export | put | format | addchart | list | ping | addsheet"
        display as error "         | deletesheet | renamesheet"
        display as error "  See {bf:help googlesheets}."
        exit 198
    }
    local sub = lower(strtrim("`sub'"))
    local _valid "create import export put list ping addsheet deletesheet renamesheet format addchart help"
    if !`:list sub in _valid' {
        display as error "googlesheets: unknown subcommand '`sub''"
        display as error "  Valid: `_valid'"
        exit 198
    }
    if "`sub'" == "help" {
        help googlesheets
        exit 0
    }
    * macval(): $ and ` in user text reach the subcommand unexpanded.
    googlesheets_`sub' `macval(0)'
end
