*! version 1.0.0  24sep2026
*! cto_form_data_attachment: download SurveyCTO form data and its media files
*! Part of the ctoclient package
*! Author: Gutama Girja Urago, Laterite (gurago@laterite.com)

capture program drop cto_form_data_attachment
program define cto_form_data_attachment, rclass
    version 15
    syntax anything(name=form id="form ID"), MEDia(string) SERVER(string)   ///
        USERname(string) PASSword(string) [KEY(string) DATE(integer 946684800)  ///
        SAVE(string) REPLACE KEEPjson ALLSTRing CLEAR]

    * ---- Check media(): absolute path, created if it does not exist ----------
    local pwd   = subinstr(c(pwd), char(92), "/", .)
    local media = subinstr(strtrim(`"`media'"'), char(92), "/", .)
    if substr(`"`media'"', -1, 1) == "/" & strlen(`"`media'"') > 1 {
        local media = substr(`"`media'"', 1, strlen(`"`media'"') - 1)
    }
    mata: st_local("media", pathisabs(st_local("media")) ? st_local("media") : st_local("pwd") + "/" + st_local("media"))
    capture mkdir `"`media'"'
    mata: st_local("ok", strofreal(direxists(st_local("media"))))
    if !`ok' {
        di as err `"media() folder `media' does not exist and could not be created"'
        exit 603
    }

    * ---- Steps 1-3: download, parse and prepare the form data -----------------
    cto_form_data `form', server(`"`server'"') username(`"`username'"')              ///
        password(`"`password'"') key(`"`key'"') date(`date') save(`"`save'"') ///
        `replace' `keepjson' `allstring' `clear'
    return add
    if _N == 0 exit

    * ---- Step 4: media files ------------------------------------------------------
    di as txt "{bf:Downloading media files} to `media'"

    mata: _ctofa_find()                              // sets local mediavars
    if "`mediavars'" == "" {
        di as txt "      no media file variables found"
        return scalar n_files      = 0
        return scalar n_existing   = 0
        return scalar n_downloaded = 0
        return scalar n_failed     = 0
        exit
    }
    local nvars : word count `mediavars'
    di as txt "      `nvars' media variable(s)"

    * list the files; write a curl configuration for the missing ones
    local work "`pwd'/__cto_media_`form'"
    capture erase `"`work'.cfg"'
    capture erase `"`work'.log"'
    capture noisily {
        mata: _ctofa_scan(1)                         // sets n_files, n_have, n_new
        local n_before = `n_have'
        di as txt "      `n_files' file(s) in the data, `n_have' already present, `n_new' to download"

        local n_failed 0
        if `n_new' > 0 {
            local w "`work'"
            if c(os) == "Windows" local w = subinstr(`"`work'"', "/", char(92), .)
            shell curl --config "`w'.cfg" > "`w'.log"

            mata: _ctofa_scan(0)                     // count again: n_new = still missing
            local n_failed = `n_new'
            if `n_failed' > 0 mata: _ctofa_codes(st_local("work") + ".log")   // sets fail_codes
        }
    }
    local rc = _rc
    capture erase `"`work'.cfg"'                     // contains the password
    capture erase `"`work'.log"'
    if `rc' exit `rc'

    local n_downloaded = `n_have' - `n_before'
    di as txt "      `n_downloaded' file(s) downloaded"
    if `n_failed' > 0 {
        di as err "      `n_failed' file(s) could not be downloaded (HTTP `fail_codes')"
        if strpos(" `fail_codes' ", " 401 ") | strpos(" `fail_codes' ", " 403 ") {
            di as err "      check the user's permissions; encrypted forms need key()"
        }
        di as err "      run the command again to retry; existing files are skipped"
    }

    return local  mediavars    "`mediavars'"
    return local  media        `"`media'"'
    return scalar n_files      = `n_files'
    return scalar n_existing   = `n_before'
    return scalar n_downloaded = `n_downloaded'
    return scalar n_failed     = `n_failed'
end


* ---- Mata functions (dropped first so the file can be reloaded) -------------------
version 15
capture mata: mata drop _ctofa_find()
capture mata: mata drop _ctofa_scan()
capture mata: mata drop _ctofa_name()
capture mata: mata drop _ctofa_esc()
capture mata: mata drop _ctofa_codes()
mata:

// String variables whose every non-empty value is a SurveyCTO attachment link:
//   https://<server>.surveycto.com/api/v2/forms/<form>/submissions/uuid:<id>/attachments/<file>
// A quick text search rules out other variables; candidates are then checked value
// by value with the full regular expression.
void _ctofa_find()
{
    real scalar      i, j, ok
    real colvector   ne
    string colvector v
    string scalar    out, re

    re  = "^https://[^/]*\.surveycto\.com/api/v2/forms/[^/]*/submissions/uuid:[^/]*/attachments/[^/]*$"
    out = ""
    for (j = 1; j <= st_nvar(); j++) {
        if (!st_isstrvar(j)) continue
        v  = st_sdata(., j)
        ne = v :!= ""
        if (sum(ne) == 0) continue
        if (sum(ne :& !(strpos(v, "https://") :== 1 :& strpos(v, "/attachments/") :> 0))) continue
        v  = select(v, ne)
        ok = 1
        for (i = 1; i <= rows(v); i++) {
            if (!ustrregexm(v[i], re)) {
                ok = 0
                break
            }
        }
        if (ok) out = out + " " + st_varname(j)
    }
    st_local("mediavars", strtrim(out))
}

// List the media files of the variables in local mediavars and count those
// present in local media. If write is 1, also write the curl configuration file
// <work>.cfg that downloads the missing files, using locals username, password and key.
// Sets locals n_files, n_have and n_new.
void _ctofa_scan(real scalar write)
{
    real scalar      i, n, have, nnew, fh
    string colvector u
    string scalar    f, q, dir, key
    transmorphic     A

    q   = char(34)
    dir = st_local("media")
    key = st_local("key")
    u   = vec(st_sdata(., tokens(st_local("mediavars"))))
    u   = select(u, u :!= "")
    if (rows(u)) u = uniqrows(u)

    if (write) {
        fh = fopen(st_local("work") + ".cfg", "w")
        fput(fh, "silent")
        fput(fh, "show-error")
        fput(fh, "fail")
        fput(fh, "user = " + q + _ctofa_esc(st_local("username") + ":" + st_local("password")) + q)
        if (key != "") fput(fh, "form = " + q + "private_key=@" + _ctofa_esc(key) + q)
        fput(fh, "write-out = " + q + "%{http_code}" + char(92) + "n" + q)
    }

    A = asarray_create()
    asarray_notfound(A, 0)
    n    = 0
    have = 0
    nnew = 0
    for (i = 1; i <= rows(u); i++) {
        f = _ctofa_name(u[i])
        if (asarray(A, f)) continue                  // file name already listed
        asarray(A, f, 1)
        n = n + 1
        if (fileexists(dir + "/" + f)) have = have + 1
        else {
            nnew = nnew + 1
            if (write) {
                fput(fh, "url = "    + q + _ctofa_esc(u[i]) + q)
                fput(fh, "output = " + q + _ctofa_esc(dir + "/" + f) + q)
            }
        }
    }
    if (write) fclose(fh)

    st_local("n_files", strofreal(n))
    st_local("n_have",  strofreal(have))
    st_local("n_new",   strofreal(nnew))
}

// file name of a media link: last part of the path, without the query string,
// with characters that are not allowed in file names replaced by _
string scalar _ctofa_name(string scalar url)
{
    real scalar      i, p
    string scalar    f
    string rowvector bad

    f = url
    p = strpos(f, "?")
    if (p) f = substr(f, 1, p - 1)
    p = strpos(f, "/")
    while (p) {
        f = substr(f, p + 1, .)
        p = strpos(f, "/")
    }
    bad = (char(92), ":", "*", char(34), "<", ">", "|")
    for (i = 1; i <= cols(bad); i++) f = subinstr(f, bad[i], "_", .)
    if (f == "") f = "attachment"
    return(f)
}

// escape a value for a quoted string in a curl configuration file
string scalar _ctofa_esc(string scalar s)
{
    s = subinstr(s, char(92), char(92) + char(92), .)
    s = subinstr(s, char(34), char(92) + char(34), .)
    return(s)
}

// HTTP status codes of failed downloads, from the curl write-out log
void _ctofa_codes(string scalar fn)
{
    string colvector L

    L = J(0, 1, "")
    if (fileexists(fn)) L = cat(fn)
    if (rows(L)) L = strtrim(L)
    if (rows(L)) L = select(L, L :!= "" :& L :!= "200")
    if (rows(L)) L = uniqrows(L)
    if (rows(L)) st_local("fail_codes", invtokens(L', " "))
    else         st_local("fail_codes", "unknown")
}

end
