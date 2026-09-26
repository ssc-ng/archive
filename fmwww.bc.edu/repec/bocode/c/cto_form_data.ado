*! version 1.0.0  24sep2026
*! cto_form_data: download SurveyCTO form data and load it into Stata
*! Part of the ctoclient package
*! Author: Gutama Girja Urago, Laterite (gurago@laterite.com)

capture program drop cto_form_data
program define cto_form_data, rclass
    version 15
    syntax anything(name=form id="form ID"), SERVER(string) USERname(string)    ///
        PASSword(string) [KEY(string) DATE(integer 946684800) SAVE(string)         ///
        REPLACE KEEPjson ALLSTRing CLEAR]

    * ---- Check the options ---------------------------------------------------
    local form `form'
    if wordcount(`"`form'"') != 1 {
        di as err "specify exactly one form ID"
        exit 198
    }

    * server(): accept "myserver", "myserver.surveycto.com" or a full URL
    local server = lower(strtrim(`"`server'"'))
    local server = subinstr(`"`server'"', "https://", "", 1)
    local server = subinstr(`"`server'"', "http://", "", 1)
    local p = strpos(`"`server'"', ".surveycto.com")
    if `p' local server = substr(`"`server'"', 1, `p' - 1)
    if !regexm(`"`server'"', "^[a-z0-9-]+$") {
        di as err "server() must be the server name, e.g. server(myserver)"
        exit 198
    }

    local user = strtrim(`"`username'"')
    if `"`user'"' == "" | `"`password'"' == "" {
        di as err "username() and password() must not be empty"
        exit 198
    }
    if strpos(`"`user'`password'"', char(34)) {
        di as err `"username() and password() cannot contain the " character"'
        exit 198
    }
    if `"`key'"' != "" confirm file `"`key'"'
    if `date' < 0 {
        di as err "date() must be a Unix timestamp in seconds (default 946684800 = 1 Jan 2000)"
        exit 198
    }
    if "`clear'" == "" & c(changed) {
        di as err "no; data in memory would be lost (specify {bf:clear})"
        exit 4
    }

    * save() and replace
    local dta ""
    local pwd = subinstr(c(pwd), char(92), "/", .)
    if "`replace'" != "" & `"`save'"' == "" {
        di as err "option replace requires save()"
        exit 198
    }
    if `"`save'"' != "" {
        mata: _ctofd_files(`"`save'"')           // sets dta, json and dirok
        if !`dirok' {
            di as err `"folder for `dta' does not exist"'
            exit 603
        }
        if "`replace'" == "" {
            confirm new file `"`dta'"'
            if "`keepjson'" != "" confirm new file `"`json'"'
        }
    }
    else local json "`pwd'/`form'.json"

    * The API expects milliseconds. The default, 1 Jan 2000, returns all submissions
    * without the 5-minute limit that SurveyCTO applies to full (date=0) downloads.
    local apidate = cond(`date' == 0, "0", "`date'000")
    local url  "https://`server'.surveycto.com/api/v2/forms/data/wide/json/`form'?date=`apidate'"
    local work "`pwd'/__cto_`form'"             // working files, deleted below

    * ---- 1. Download ------------------------------------------------------------
    di as txt _n "{bf:[1/3] Downloading `form'} from `server'.surveycto.com"
    if `date' > 0 & `date' != 946684800 {
        di as txt "      submissions after " %tc (`date' * 1000 + tc(01jan1970 00:00:00)) " UTC"
    }
    capture noisily _ctofd_get, work(`"`work'"') url(`"`url'"') user(`"`user'"') ///
        password(`"`password'"') key(`"`key'"') server(`server') form(`form')
    local rc = _rc

    * ---- 2. Parse ---------------------------------------------------------------
    if !`rc' {
        di as txt "{bf:[2/3] Parsing JSON}"
        clear
        capture noisily mata: _ctofd_parse(`"`work'.json"', `=("`allstring'" != "")')
        local rc = _rc
    }
    local keptjson ""
    if !`rc' & "`keepjson'" != "" {
        capture copy `"`work'.json"' `"`json'"', replace
        if _rc di as err `"warning: could not keep the JSON as `json'"'
        else   local keptjson `"`json'"'
    }
    capture erase `"`work'.json"'
    capture erase `"`work'.code"'
    if `rc' exit `rc'

    if _N == 0 {
        di as txt "      (no submissions returned; nothing saved)"
        return scalar N = 0
        return scalar k = 0
        exit
    }

    * ---- 3. Prepare the data in memory ----------------------------------------
    di as txt "{bf:[3/3] Preparing the data in memory}"

    * SurveyCTO date-times ("Sep 24, 2026 3:02:11 PM") -> %tc
    foreach v in SubmissionDate CompletionDate starttime endtime {
        capture confirm string variable `v'
        if _rc continue
        tempvar tc
        quietly gen double `tc' = clock(`v', "MDYhms")
        quietly count if missing(`tc') & `v' != ""
        if r(N) {
            di as txt "      (`v' left as string: `r(N)' values not in MDYhms format)"
            continue
        }
        order `tc', after(`v')
        drop `v'
        rename `tc' `v'
        format `v' %tc
    }

    capture confirm variable KEY
    if !_rc {
        capture isid KEY
        if _rc di as err "      warning: KEY does not uniquely identify submissions"
    }
    quietly compress
    di as txt "      `=_N' submissions, `=c(k)' variables"

    if `"`dta'"' != "" {
        quietly save `"`dta'"', `replace'
        di as txt `"      saved {browse "`dta'"}"'
        return local file `"`dta'"'
    }
    if `"`keptjson'"' != "" {
        di as txt `"      JSON kept as `keptjson'"'
        return local json `"`keptjson'"'
    }
    return scalar N = _N
    return scalar k = c(k)
end


* ---- Download with curl and check the server's reply ---------------------------
capture program drop _ctofd_get
program define _ctofd_get
    version 15
    syntax, work(string) url(string) user(string) password(string)    ///
        server(string) form(string) [key(string)]

    * file paths in the form the operating system shell expects
    local w "`work'"
    if c(os) == "Windows" local w = subinstr(`"`work'"', "/", char(92), .)

    local auth `"-u "`user':`password'""'
    if `"`key'"' != "" local auth `"`auth' -F "private_key=@`key'""'

    capture erase `"`work'.json"'
    capture erase `"`work'.code"'
    shell curl -sS `auth' -o "`w'.json" -w "%{http_code}" "`url'" > "`w'.code"

    * curl writes the HTTP status code to <work>.code
    capture confirm file `"`work'.code"'
    if _rc {
        di as err "curl could not be run; check that curl is installed"
        di as err "({bf:shell curl --version}) and that the working directory is writable"
        exit 601
    }
    tempname fh
    file open `fh' using `"`work'.code"', read text
    file read `fh' http
    file close `fh'
    local http = strtrim(`"`http'"')

    if `"`http'"' != "200" {
        local reply_title ""
        local reply_msg   ""
        capture confirm file `"`work'.json"'
        if !_rc mata: _ctofd_reply(`"`work'.json"')      // sets reply_title, reply_msg
        local notfound = strpos(lower(`"`reply_title'"'), "server not found") > 0

        if inlist(`"`http'"', "", "000") {
            local why "could not connect to `server'.surveycto.com; check the server name and internet connection"
        }
        else if "`http'" == "404" & `notfound' {
            local why "there is no SurveyCTO server called '`server''; check server()"
        }
        else if "`http'" == "404" local why "form '`form'' was not found on `server'; check the form ID"
        else if "`http'" == "401" local why "SurveyCTO rejected the login; check username() and password()"
        else if "`http'" == "403" local why "access denied; the user may lack permission to download data, or key() is wrong"
        else if "`http'" == "409" local why "another API request to this server is in progress; retry in a minute"
        else if "`http'" == "417" local why "full downloads (date 0) are limited to one every 5 minutes; wait or use date()"
        else if real("`http'") >= 500 local why "SurveyCTO server error; try again later"
        else local why "unexpected reply from the server"

        di as err "download failed (HTTP `http'): `why'"
        if `"`reply_msg'"' != ""        di as txt `"      server message: `reply_msg'"'
        else if `"`reply_title'"' != "" di as txt `"      server page: `reply_title'"'
        exit 601
    }

    mata: st_local("mb", strtrim(strofreal(_ctofd_size(`"`work'.json"') / 1048576, "%9.1f")))
    di as txt "      downloaded `mb' MB"
end


* ---- Mata functions (dropped first so the file can be reloaded) -------------------
version 15
capture mata: mata drop _ctofd_parse()
capture mata: mata drop _ctofd_isnum()
capture mata: mata drop _ctofd_fail()
capture mata: mata drop _ctofd_files()
capture mata: mata drop _ctofd_which()
capture mata: mata drop _ctofd_reply()
capture mata: mata drop _ctofd_safe()
capture mata: mata drop _ctofd_size()
capture mata: mata drop _ctofd_unescape()
capture mata: mata drop _ctofd_hex()
capture mata: mata drop _ctofd_keep()

mata:

void _ctofd_parse(string scalar fn, real scalar allstr)
{
    real scalar      fh, fsize, eof, started, n, i, j, m, K, nr, nrec, ncol, last
    real colvector   b, isq, inside, q, st, en, len, kk, rec, reck, col, sv, x
    real rowvector   isnum, w, idx
    string scalar    s, v, bs, carry
    string colvector keys, vals, names
    string rowvector types, vn
    string matrix    D, piece
    transmorphic     A

    bs      = char(92)                              // backslash
    A       = asarray_create()                      // key name -> column number
    asarray_notfound(A, 0)
    names   = J(0, 1, "")
    D       = J(0, 0, "")                           // submissions x variables
    nrec    = 0
    ncol    = 0
    started = 0                                     // has the opening [ been read?
    carry   = ""

    fh = fopen(fn, "r")
    fseek(fh, 0, 1)
    fsize = ftell(fh)
    fseek(fh, 0, -1)
    if (fsize == 0) _ctofd_fail(fh, "file is empty")

    while (1) {
        // 1. Read the next 8 MB and join it to the unfinished end of the last piece
        piece = fread(fh, 8388608)
        eof = (rows(piece) * cols(piece) == 0)
        if (eof) s = carry
        else s = carry + piece
        if (!started & ascii(substr(s, 1, 3)) == (239, 187, 191)) s = substr(s, 4, .)  // BOM

        // 2. Find the real quote characters (not escaped \" ones)
        s = subinstr(s, bs + bs, char(1), .)        // hide escaped backslashes \\
        b = ascii(s)'
        n = rows(b)
        if (n == 0) {
            if (eof) break
            continue
        }
        isq    = (b :== 34) :& ((0 \ b)[|1 \ n|] :!= 92)
        inside = mod(runningsum(isq), 2)            // 1 = byte is inside a "string"

        // 3. Remove whitespace outside strings, so "key" : "value" also works
        x = inside :| !(b :== 32 :| b :== 9 :| b :== 10 :| b :== 13)
        if (sum(x) < n) {
            s      = _ctofd_keep(s, x)
            b      = select(b, x)
            isq    = select(isq, x)
            inside = select(inside, x)
            n      = rows(b)
        }
        if (n == 0) {                               // piece was only whitespace
            carry = ""
            if (eof) break
            continue
        }

        // 4. Check it is a flat array of objects (SurveyCTO wide JSON)
        if (!started & b[1] != 91) _ctofd_fail(fh, "file does not start with [ ; " +
            "probably an API error message:" + char(10) + substr(s, 1, 300))
        rec = runningsum((b :== 123 :& !inside) - (b :== 125 :& !inside))
        if (sum(b :== 91 :& !inside) != !started | max(rec) > 1 | min(rec) < 0) {
            _ctofd_fail(fh, "nested JSON found; expected SurveyCTO wide JSON (a flat array of objects)")
        }

        // 5. Keep only complete submissions; carry the rest into the next piece
        x = _ctofd_which(b :== 125 :& !inside)      // every } closes a submission
        if (rows(x) == 0) {
            if (!eof) {
                carry = s
                continue
            }
            if (s != "]" & s != "[]") _ctofd_fail(fh, "JSON ends unexpectedly (incomplete download?)")
            break
        }
        last    = x[rows(x)]
        carry   = substr(s, last + 1, .)
        started = 1
        rec     = runningsum(b :== 123 :& !inside)  // submission number within this piece
        nr      = rec[last]

        // 6. Strings: first byte (st), closing quote (en); keys are followed by ':'
        K = 0
        q = _ctofd_which(isq)
        q = select(q, q :< last)
        if (rows(q)) {
            st   = q[range(1, rows(q) - 1, 2)] :+ 1
            en   = q[range(2, rows(q), 2)]
            len  = en - st
            kk   = _ctofd_which(b[en :+ 1] :== 58)
            K    = rows(kk)
        }
        if (K) {
            keys = substr(s, st[kk], len[kk])
            reck = rec[st[kk]]
            vals = J(K, 1, "")
            sv   = b[en[kk] :+ 2] :== 34            // is the value a "string"?
            x    = _ctofd_which(sv)
            if (rows(x)) vals[x] = substr(s, st[kk[x] :+ 1], len[kk[x] :+ 1])
            x    = _ctofd_which(!sv)                 // unquoted: null, numbers, true/false
            for (i = 1; i <= rows(x); i++) {
                if (regexm(substr(s, en[kk[x[i]]] + 2, 60), "^[^,}]*")) v = regexs(0)
                vals[x[i]] = (v == "null" ? "" : v)
            }
            // decode escapes (\" \n \t \uXXXX ...) only in values that contain them
            x = _ctofd_which(strpos(vals, bs) :| strpos(vals, char(1)))
            for (i = 1; i <= rows(x); i++) {
                vals[x[i]] = subinstr(_ctofd_unescape(vals[x[i]]), char(1), bs, .)
            }

            // 7. Give each distinct key a column number, in first-seen order
            col = J(K, 1, 0)
            for (i = 1; i <= K; i++) {
                j = asarray(A, keys[i])
                if (j == 0) {
                    ncol  = ncol + 1
                    j     = ncol
                    asarray(A, keys[i], j)
                    names = names \ keys[i]
                }
                col[i] = j
            }
        }

        // 8. Add this piece's submissions as new rows of the table
        if (ncol > cols(D)) D = D, J(rows(D), ncol - cols(D), "")
        D = D \ J(nr, ncol, "")
        for (i = 1; i <= K; i++) D[nrec + reck[i], col[i]] = vals[i]
        nrec = nrec + nr
    }
    fclose(fh)
    if (nrec == 0 | ncol == 0) {
        printf("{txt}(no submissions in file)\n")
        return
    }

    // 9. Decide storage types and valid Stata names ---------------------------
    isnum = J(1, ncol, 0)
    if (!allstr) {
        for (j = 1; j <= ncol; j++) isnum[j] = _ctofd_isnum(D[., j])
    }
    w     = colmax(strlen(D))
    types = J(1, ncol, "")
    vn    = J(1, ncol, "")
    A = asarray_create()
    asarray_notfound(A, 0)
    for (j = 1; j <= ncol; j++) {
        if (isnum[j])         types[j] = "double"
        else if (w[j] > 2045) types[j] = "strL"
        else                  types[j] = "str" + strofreal(max((w[j], 1)))

        vn[j] = strtoname(names[j])                  // valid name, max 32 characters
        m = 1
        while (asarray(A, vn[j])) {                  // make names unique
            m = m + 1
            vn[j] = usubstr(strtoname(names[j]), 1, 28) + "_" + strofreal(m)
        }
        asarray(A, vn[j], 1)
    }

    // 10. Create the Stata dataset in one go ----------------------------------
    (void) st_addvar(types, vn)
    st_addobs(nrec)
    idx = _ctofd_which(!isnum')'
    if (length(idx)) st_sstore(., idx, D[., idx])
    idx = _ctofd_which(isnum')'
    if (length(idx)) st_store(., idx, strtoreal(D[., idx]))
    for (j = 1; j <= ncol; j++) {
        if (vn[j] != names[j]) st_varlabel(j, usubstr(names[j], 1, 80))
    }
}

// numeric only if every non-empty value is a number, no leading zero, <= 15 chars
real scalar _ctofd_isnum(string colvector v)
{
    real colvector has

    has = v :!= ""
    if (sum(has) == 0)                          return(0)   // empty column
    if (sum(has :& strtoreal(v) :>= .))         return(0)   // some text
    if (max(strlen(v)) > 15)                    return(0)   // too long for a double
    if (sum(substr(v, 1, 1) :== "0" :& strlen(v) :> 1 :& substr(v, 2, 1) :!= ".")) return(0)
    return(1)
}

void _ctofd_fail(real scalar fh, string scalar msg)
{
    if (fh >= 0) fclose(fh)
    errprintf("%s\n", msg)
    exit(610)
}

// save(): add .dta if no extension, JSON name beside it, does the folder exist?
void _ctofd_files(string scalar fn)
{
    string scalar f, d, base

    f = subinstr(strtrim(fn), char(92), "/", .)
    if (pathsuffix(f) == "") f = f + ".dta"
    pathsplit(f, d, base)
    st_local("dta",   f)
    st_local("json",  pathrmsuffix(f) + ".json")
    st_local("dirok", strofreal(d == "" | direxists(d)))
}

// decode JSON escapes (\" \/ \n \t \r \b \f \uXXXX); all other bytes, including
// UTF-8 text such as Amharic, are copied unchanged
string scalar _ctofd_unescape(string scalar s)
{
    real rowvector b
    real scalar    i, n, st, c, cp, lo
    string scalar  out

    b   = ascii(s)
    n   = cols(b)
    out = ""
    i   = 1
    st  = 1
    while (i <= n) {
        if (b[i] != 92) {
            i++
            continue
        }
        out = out + substr(s, st, i - st)
        if (i == n) {
            st = i
            break
        }
        c = b[i + 1]
        if (c == 117 & i + 5 <= n) {                            // \uXXXX
            cp = _ctofd_hex(substr(s, i + 2, 4))
            if (cp >= 55296 & cp <= 56319 & i + 11 <= n) {       // surrogate pair
                if (b[i + 6] == 92 & b[i + 7] == 117) {
                    lo = _ctofd_hex(substr(s, i + 8, 4))
                    if (lo >= 56320 & lo <= 57343) {
                        cp = 65536 + (cp - 55296) * 1024 + (lo - 56320)
                        i = i + 6
                    }
                }
            }
            out = out + uchar(cp)
            i = i + 6
        }
        else {
            if      (c == 110) out = out + char(10)             // \n
            else if (c == 116) out = out + char(9)              // \t
            else if (c == 114) out = out + char(13)             // \r
            else if (c == 98)  out = out + char(8)              // \b
            else if (c == 102) out = out + char(12)             // \f
            else               out = out + substr(s, i + 1, 1)  // \" \/ and others
            i = i + 2
        }
        st = i
    }
    return(out + substr(s, st, .))
}

// value of a 4-digit hexadecimal string
real scalar _ctofd_hex(string scalar h)
{
    real rowvector x

    if (strlen(h) != 4) return(65533)
    x = ascii(strlower(h))
    x = (x :>= 48 :& x :<= 57) :* (x :- 48) + (x :>= 97 :& x :<= 102) :* (x :- 87)
    return(x * (4096 \ 256 \ 16 \ 1))
}

// keep the bytes of s where k is 1, copying them unchanged
string scalar _ctofd_keep(string scalar s, real colvector k)
{
    real scalar    n
    real colvector st, en

    n  = rows(k)
    st = _ctofd_which(k :& !((0 \ k)[|1 \ n|]))            // first byte of each run
    en = _ctofd_which(k :& !((k \ 0)[|2 \ n + 1|]))        // last byte of each run
    if (rows(st) == 0) return("")
    return(invtokens(substr(s, st', (en - st :+ 1)'), ""))
}

// selectindex() that always returns a column vector (0 x 1 when nothing matches)
real colvector _ctofd_which(real colvector v)
{
    if (length(v) == 0) return(J(0, 1, .))
    return(colshape(selectindex(v), 1))
}

// read a server error reply: sets locals reply_title (HTML <title>) or
// reply_msg (the "message" of a JSON error, else the first 200 characters)
void _ctofd_reply(string scalar fn)
{
    real scalar   fh
    string matrix t
    string scalar s, q, title, msg

    title = ""
    msg   = ""
    q     = char(34)
    fh = _fopen(fn, "r")
    if (fh >= 0) {
        t = fread(fh, 4000)
        fclose(fh)
        if (rows(t) * cols(t)) {
            s = t
            if (regexm(s, "<title>([^<]*)</title>"))  title = strtrim(regexs(1))
            else if (regexm(s, q + "message" + q + " *: *" + q + "([^" + q + "]*)" + q)) msg = regexs(1)
            else if (!regexm(s, "<[a-zA-Z!]")) msg = substr(s, 1, 200)
        }
    }
    st_local("reply_title", _ctofd_safe(title))
    st_local("reply_msg",   _ctofd_safe(msg))
}

// make text safe to show through a Stata macro: no quotes, `, $, or line breaks
string scalar _ctofd_safe(string scalar s)
{
    s = subinstr(s, char(34), "'", .)
    s = subinstr(s, char(96), "'", .)
    s = subinstr(s, char(36), "", .)
    s = subinstr(s, char(92), "/", .)
    s = subinstr(s, char(10), " ", .)
    s = subinstr(s, char(13), " ", .)
    return(strtrim(s))
}

// size of a file in bytes (0 if it does not exist yet)
real scalar _ctofd_size(string scalar fn)
{
    real scalar fh, n

    if (!fileexists(fn)) return(0)
    fh = _fopen(fn, "r")
    if (fh < 0) return(0)
    fseek(fh, 0, 1)
    n = ftell(fh)
    fclose(fh)
    return(n)
}


end
