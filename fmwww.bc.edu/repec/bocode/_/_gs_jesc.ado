*! _gs_jesc v0.1.1  2026-11-09
*! v0.1.1: the escaping is done in Mata, without macro expansion, and an
*!   apostrophe or backtick is written as ' / `.  A value holding
*!   an apostrophe (a quoted tab name such as 'Auto'!A1:B2, or Bob's data)
*!   could otherwise close the compound quotes of the -file write- that puts
*!   it in the args JSON, and the command stopped with r(198).
*! JSON-escape a Stata string for embedding in a JSON value.  Internal
*! helper used by every googlesheets_* subcommand that writes the args
*! JSON file consumed by googlesheets_helper.py.
*!
*! Usage:
*!   _gs_jesc, raw("some \backslashes and \"quotes\"")
*!   local escaped `"`r(escaped)'"'
*!
*! Why a Stata wrapper instead of inline subinstr?  Because every
*! subcommand needs the same escape sequence; centralising it avoids drift
*! if (when) the escape rules change.

program define _gs_jesc, rclass
version 17.0
    syntax , [ RAW(string) ]
    mata: st_local("s", _gs_jesc_m(st_local("raw")))
    return local escaped `"`macval(s)'"'
end

mata:
// Backslash, double quote, line break, carriage return and tab are JSON
// escapes; apostrophe and backtick become ' / `, which every JSON
// reader decodes back to the same character.  Characters are built with
// char() so the source holds no escape sequences.
string scalar _gs_jesc_m(string scalar s)
{
    string scalar bs

    bs = char(92)
    s = subinstr(s, bs, bs + bs)
    s = subinstr(s, char(34), bs + char(34))
    s = subinstr(s, char(10), bs + "n")
    s = subinstr(s, char(13), bs + "r")
    s = subinstr(s, char(9),  bs + "t")
    s = subinstr(s, char(39), bs + "u0027")
    s = subinstr(s, char(96), bs + "u0060")
    return(s)
}
end
