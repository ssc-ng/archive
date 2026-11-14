*! _gs_expandtilde v0.1.0  2026-09-21
*! Expand a LEADING tilde in a path to the user's home directory.
*! INTERNAL helper for googlesheets.
*!
*! Why: Stata's confirm file, cd, and use/save expand "~" themselves, so a
*! "~/..." client or token path passes the Stata-side check -- but the
*! unexpanded string is what reaches the Python helper, and Python's Path()
*! does not expand it.  The visible symptom was "OAuth client JSON not
*! found" naming a file that exists.  Expanding once here, before anything
*! is validated or returned, fixes every subcommand at a single point.
*!
*! Only a leading "~" (the whole path) or "~/" / "~\" is expanded.  A tilde
*! anywhere else is a legal filename character, and "~otheruser/..." cannot
*! be resolved without the password database, so both are left untouched.
*!
*! Home directory, in order:
*!   Windows:  USERPROFILE, then HOMEDRIVE+HOMEPATH, then HOME.  HOME is
*!             usually unset there, and when a POSIX-style HOME leaks in
*!             from Cygwin/MSYS it names a path Windows cannot open; this
*!             order matches Python's ntpath.expanduser.
*!   else:     HOME, then the two Windows variables as a last resort.
*! If none is set the path is returned unchanged; the Python helper's
*! expanduser() is the backstop.
*!
*! Usage:   _gs_expandtilde, path(`"`p'"')      ->   r(path)

program define _gs_expandtilde, rclass
    version 17.0
    syntax , [ PATH(string) ]

    local p `"`path'"'

    * Expand only a bare "~" or a "~" followed by a separator;
    * "~otheruser/..." and a tilde anywhere else stay as-is.
    if `"`p'"' == "~" | strpos(`"`p'"', "~/") == 1 | strpos(`"`p'"', "~\") == 1 {
        if lower("`c(os)'") == "windows" {
            local order "USERPROFILE HOMEDRIVEPATH HOME"
        }
        else {
            local order "HOME USERPROFILE HOMEDRIVEPATH"
        }
        local home ""
        foreach src of local order {
            if `"`home'"' != "" continue
            if "`src'" == "HOMEDRIVEPATH" {
                local drive : env HOMEDRIVE
                local hpath : env HOMEPATH
                if `"`drive'`hpath'"' != "" local home `"`drive'`hpath'"'
            }
            else {
                local home : env `src'
            }
        }
        if `"`home'"' != "" {
            local rest = substr(`"`p'"', 2, .)
            * Join without doubling a separator.  When home is a bare root
            * ("/" or "C:\") keep it and drop the separator from rest
            * instead, so "~" alone returns the root unchanged.
            if `"`rest'"' != "" {
                local cl = substr(`"`home'"', -1, 1)
                if `"`cl'"' == "/" | `"`cl'"' == "\" {
                    if length(`"`home'"') > 1 local home = substr(`"`home'"', 1, length(`"`home'"') - 1)
                    else local rest = substr(`"`rest'"', 2, .)
                }
            }
            local p `"`home'`rest'"'
        }
    }
    return local path `"`p'"'
end
