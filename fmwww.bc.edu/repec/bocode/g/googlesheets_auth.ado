*! googlesheets_auth v0.1.3  2026-11-09
*! v0.1.3: the Windows default path is built with single separators (it
*!   showed doubled backslashes); when APPDATA is empty it uses
*!   USERPROFILE/AppData/Roaming, and when both are empty it stops with a
*!   message asking for keyfile() or GS_CLIENT instead of guessing
*!   C:\Users\Default.
*! v0.1.2: the default client path is built from the home directory directly,
*!   never written with "~" (handling of "~" varies by OS, Stata version and
*!   Python).  A "~" a user passes is still expanded here, as a safety net.
*! v0.1.1: expand a leading "~" in the client and token paths before they
*!   are validated or handed to the Python helper.  Stata's confirm file
*!   expands "~" itself, so a "~/..." GS_CLIENT passed the check here and
*!   then failed in Python, which does not expand it -- reported as
*!   "OAuth client JSON not found" for a file that exists.
*! Resolve the OAuth client JSON + token cache paths for googlesheets.
*! INTERNAL helper -- the user-facing googlesheets commands call this; it
*! is not meant to be invoked directly.
*!
*! Path resolution priority:
*!   1. The keyfile() option, if supplied.
*!   2. The $GS_CLIENT global, if defined.
*!   3. The platform default <home>/.config/stata-googlesheets/client.json
*!      (or %APPDATA%\stata-googlesheets\client.json on Windows).
*!
*! Token cache (refresh tokens; written silently on first auth):
*!   Same directory as the client.json, file name "token.json".
*!   Override with tokenfile() or $GS_TOKEN.
*!
*! A leading "~" in any of these is expanded to the home directory (see
*! _gs_expandtilde), so the paths returned in r() are always a form the
*! Python helper can open.

program define googlesheets_auth, rclass
    version 17.0
    syntax [, KEYfile(string) TOKENfile(string) ]

    * --- locate the OAuth client JSON ----------------------------------
    if `"`macval(keyfile)'"' == "" {
        if "$GS_CLIENT" != "" {
            local keyfile "$GS_CLIENT"
        }
        else {
            * Platform default.  c(os) returns "MacOSX" / "Unix" / "Windows".
            if lower("`c(os)'") == "windows" {
                local _home : env APPDATA
                if `"`_home'"' == "" {
                    local _up : env USERPROFILE
                    if `"`_up'"' != "" local _home `"`_up'/AppData/Roaming"'
                }
                if `"`_home'"' == "" {
                    display as error "googlesheets: cannot find the default client JSON folder (APPDATA and USERPROFILE are both empty)."
                    display as error "  Give keyfile() or set the global GS_CLIENT to the full path of the client JSON."
                    exit 601
                }
                local keyfile `"`_home'/stata-googlesheets/client.json"'
            }
            else {
                * Built from the home directory itself, not from "~".
                local _home : env HOME
                if `"`_home'"' == "" local _home : env USERPROFILE
                local keyfile `"`_home'/.config/stata-googlesheets/client.json"'
            }
        }
    }

    * Expand a leading "~" once, here, so the check below and the string
    * returned to the caller agree.  confirm file would expand it for the
    * check alone, leaving the unexpanded path to fail in Python.
    _gs_expandtilde, path(`"`keyfile'"')
    local keyfile `"`r(path)'"'

    capture confirm file `"`keyfile'"'
    if _rc {
        display as error "googlesheets: OAuth client JSON not found."
        display as error `"  Looked at: `keyfile'"'
        display as error "  Set either GS_CLIENT (global) or keyfile() to a path that exists."
        display as error "  Setup instructions: {bf:help googlesheets##setup}"
        exit 601
    }

    * --- locate (or default) the token cache ----------------------------
    if `"`macval(tokenfile)'"' == "" {
        if "$GS_TOKEN" != "" {
            local tokenfile "$GS_TOKEN"
        }
        else {
            * Sit the token next to the client JSON.  keyfile is already
            * expanded, so this derived path is absolute as well.
            local _dir = subinstr(`"`keyfile'"', "\", "/", .)
            local _slash = strrpos(`"`_dir'"', "/")
            if `_slash' > 0 {
                local tokenfile = substr(`"`_dir'"', 1, `_slash') + "token.json"
            }
            else {
                local tokenfile "token.json"
            }
        }
    }
    _gs_expandtilde, path(`"`tokenfile'"')
    local tokenfile `"`r(path)'"'

    return local client_json `"`keyfile'"'
    return local token_json  `"`tokenfile'"'
end
