*!  usepackage.ado -- find, verify, and install the user-written packages (and data) a do-file needs
*!  Eric A. Booth, Sr Researcher, Texas 2036 <eric.a.booth@gmail.com>
*!  v 2.0.3   14nov2026
*!
*!  v2.0.3 changes:
*!    - net installs (github(), from(), the net search catalogue) no longer
*!      pass force, which added a duplicate stata.trk entry each time an
*!      installed package was installed again; after that, ado uninstall
*!      <pkg> failed with r(111) "criterion matches more than one package"
*!
*!  v2.0.2 changes:
*!    - update no longer uninstalls first: the working copy stays in place
*!      when the reinstall fails (network down, source moved)
*!    - useit refuses with r(4) when the data in memory have unsaved changes,
*!      unless clear is given; it used to replace them without a word
*!    - dryrun counts an inferred match as awaiting confirmation (as a real
*!      batch run would) unless noconfirm is given
*!    - scan() skips program define names, end, mata/python blocks,
*!      continuation lines and #delimit ; continuations
*!    - github(owner) reads every page of the account's repository list
*!      (100 per request, up to 1,000), not just the first
*!    - useit reads CSV with bindquote(strict); open logs are paused while
*!      the catalogue is searched; r() lists carry no leading space; a bare
*!      -usepackage- prints the syntax
*!
*!  v2.0.1 changes:
*!    - github() and data() routes now post r() like the package route
*!      (they used to exit with r() empty, so -if r(nfail) > 0- fired even
*!      after a successful github() install); r(nfail) counts failed data files
*!    - data() creates into(), including nested folders, before fetching
*!      (it used to fail every file with rc 603 when the folder was missing);
*!      a leading ~ in into() is expanded
*!
*!  v2.0.0 changes vs v1.0.0 (2011):
*!    - never installs a near-match without asking (see noconfirm)
*!    - ancillary files installed by default; noancillary skips them
*!    - reports what was found, skipped, and why, with a per-package summary
*!    - github() installs a package from a GitHub repository (layout auto-probed)
*!    - data() fetches data files from a GitHub repository
*!    - scan() reads a do-file and reports the commands it cannot resolve
*!    - dryrun reports the plan without installing anything
*!    - warns when a PERSONAL ado-file shadows the installed package
*!    - fixes: undefined macro in update path, preserve/continue leak,
*!      duplicated SSC attempts, deprecated insheet, version before syntax

program define usepackage, rclass
    version 16.0

    syntax [anything(name=pkgs)] [,          ///
        Update                               ///
        NEARest                              ///
        NOCONFirm                            ///
        NOANCillary                          ///
        DRYrun                               ///
        from(string)                         ///
        GIThub(string)                       ///
        BRanch(string)                       ///
        DATA(string)                         ///
        Files(string)                        ///
        INTO(string)                         ///
        USEit                                ///
        CLEAR                                ///
        SCAN(string)                         ///
        GHOwner(string)                      ///
        ]

    *-- nothing asked for: say how to ask, rather than return in silence
    if `"`pkgs'`github'`data'`scan'"' == "" {
        di as text "{bf:usepackage}: nothing to do.  Name one or more packages, or use"
        di as text "github(), data() or scan():"
        di as text "    usepackage {it:pkglist} [, update nearest noconfirm noancillary dryrun from() ghowner()]"
        di as text "    usepackage [{it:pkg}], github({it:owner}[/{it:repo}])"
        di as text "    usepackage, data({it:owner/repo}) [files() into() useit clear]"
        di as text "    usepackage, scan({it:filename})"
        di as text `"see {help usepackage}"'
    }

    *-- useit replaces the data in memory: refuse before fetching anything
    *-- when that would throw away unsaved changes, as -use- itself does
    if "`useit'" != "" & "`clear'" == "" & "`dryrun'" == "" & `"`data'"' != "" {
        if c(changed) == 1 {
            di as error "no; data in memory would be lost"
            di as error "usepackage: useit replaces the data in memory; save them first, or add {bf:clear}"
            exit 4
        }
    }

    *-- mutually sensible defaults -------------------------------------------
    if "`into'" == "" local into "."

    *-- Owners to fall back on when a name is on neither SSC nor the net search
    *-- catalogue.  Set once per session (or in profile.do) with e.g.
    *--     global usepackage_github "ericabooth yourorg"
    *-- so your own repositories are searched without naming them every time.
    if `"`ghowner'"' == "" local ghowner `"$usepackage_github"'

    *-- counters: every route (packages, github(), data()) posts the same r()
    local nreq   0
    local nok    0
    local nskip  0
    local ndefer 0
    local nfail  0
    local faillist ""
    local deferlist ""
    local ndreq  0
    local ndok   0
    local ndfail 0
    local dgot   ""
    local dfail  ""
    local didpkg 0
    local scanmiss ""

    *-- route: scan a do-file and report unresolved commands ------------------
    if `"`scan'"' != "" {
        _up_scan `"`scan'"'
        local scanmiss `"`r(missing)'"'
    }

    *-- route: fetch data files from a GitHub repository ----------------------
    if `"`data'"' != "" {
        _up_data,                            ///
            repo(`"`data'"')                 ///
            files(`"`files'"')               ///
            into(`"`into'"')                 ///
            branch(`"`branch'"')             ///
            `dryrun' `noconfirm' `useit'
        local ndreq  = r(nreq)
        local ndok   = r(nok)
        local ndfail = r(nfail)
        local dgot   `"`r(files)'"'
        local dfail  `"`r(failed)'"'
    }

    *-- route: install one package from a GitHub repository -------------------
    if `"`github'"' != "" {
        *-- catalogue mode: no package name, or "*", means "show me what is
        *-- there" rather than "install this"
        if "`pkgs'" == "" | "`pkgs'" == "*" | "`pkgs'" == "all" {
            _up_ghlist, target(`"`github'"') branch(`"`branch'"')
        }
        else {
            local didpkg 1
            foreach p in `pkgs' {
                local ++nreq
                _up_github `p',                  ///
                    repo(`"`github'"')           ///
                    branch(`"`branch'"')         ///
                    `update' `noancillary' `dryrun'
                if r(ok) == 1 {
                    local ++nok
                }
                else {
                    local ++nfail
                    local faillist "`faillist' `p'"
                }
            }
        }
    }
    else if "`pkgs'" != "" {
        local didpkg 1
        _up_main `pkgs', `update' `nearest' `noconfirm' `noancillary' ///
            `dryrun' from(`"`from'"') ghowner(`"`ghowner'"')
        local nreq   = r(nreq)
        local nok    = r(nok)
        local nskip  = r(nskip)
        local ndefer = r(ndefer)
        local nfail  = r(nfail)
        local faillist  `"`r(unresolved)'"'
        local deferlist `"`r(deferred)'"'
    }

    if `didpkg' & `"`github'"' != "" {
        local verb "installed"
        if "`dryrun'" != "" local verb "resolvable"
        di as text _n "{hline 60}"
        di as text "usepackage summary: " as result "`nreq' requested" as text ", " ///
            as result "`nok' `verb'" as text ", " ///
            as result "`nfail' unresolved"
        if "`faillist'" != "" di as error "  unresolved:`faillist'"
        di as text "{hline 60}"
    }

    *-- r(nfail) counts unresolved packages AND data files that failed, so the
    *-- documented guard -if r(nfail) > 0- catches either kind of failure
    local nfailall = `nfail' + `ndfail'

    *-- the lists are built with a leading space; hand them back clean
    local scanmiss  : list clean scanmiss
    local dgot      : list clean dgot
    local dfail     : list clean dfail
    local deferlist : list clean deferlist
    local faillist  : list clean faillist

    if `"`scan'"' != "" return local missing `"`scanmiss'"'
    return local datafiles  `"`dgot'"'
    return local datafailed `"`dfail'"'
    return local deferred   `"`deferlist'"'
    return local unresolved `"`faillist'"'
    return scalar ndfail = `ndfail'
    return scalar ndok   = `ndok'
    return scalar ndreq  = `ndreq'
    return scalar nfail  = `nfailall'
    return scalar nok    = `nok'
    return scalar nskip  = `nskip'
    return scalar ndefer = `ndefer'
    return scalar nreq   = `nreq'
end


*==========================================================================
*  _up_main : the SSC / net-search / owner-fallback loop over package names
*==========================================================================
program define _up_main, rclass
    syntax anything(name=pkgs) [, Update NEARest NOCONFirm NOANCillary ///
        DRYrun from(string) ghowner(string) ]

    *-- main loop over requested packages ------------------------------------
    local nreq   0
    local nok    0
    local nskip  0
    local ndefer 0
    local nfail  0
    local faillist ""
    local deferlist ""

    if "`dryrun'" != "" {
        di as text _n "{bf:usepackage} (dryrun -- nothing will be installed)"
    }
    else if "`update'" != "" {
        di as text _n "{bf:usepackage}: installing or updating packages..."
    }
    else {
        di as text _n "{bf:usepackage}: installing missing packages..."
    }

    foreach p in `pkgs' {
        local ++nreq
        di as text _n "[`nreq'] " as result "`p'"

        *-- already present, and not asked to update?
        if "`update'" == "" {
            _up_status `p'
            if r(found) {
                di as text "      already installed" _c
                if `"`r(shadow)'"' != "" {
                    di ""
                    di as text "      {bf:note:} a PERSONAL copy shadows any installed package:"
                    di as text "            `r(shadow)'"
                    di as text "            that copy wins on the adopath; "  ///
                       `"{stata "which `p'":which `p'} to inspect"'
                }
                else {
                    di as text `"  ({stata "which `p'":which `p'})"'
                }
                local ++nskip
                continue
            }
        }

        *-- explicit source given: go straight there
        if `"`from'"' != "" {
            _up_netinstall `p', from(`"`from'"') `noancillary' `dryrun' `update'
            if r(ok) {
                local ++nok
            }
            else {
                local ++nfail
                local faillist "`faillist' `p'"
            }
            continue
        }

        *-- try SSC first, then the net search catalogue
        local ghnext ""
        if `"`ghowner'"' != "" local ghnext "ghnext"
        _up_try `p', `update' `noancillary' `dryrun' `nearest' `noconfirm' `ghnext'
        if r(ok) {
            local ++nok
        }
        else if r(skipped) {
            local ++ndefer
            local deferlist "`deferlist' `p'"
        }
        else {
            *-- last resort: search any configured GitHub owners
            local rescued 0
            foreach o of local ghowner {
                if `rescued' == 0 {
                    _up_github `p', repo("`o'") ///
                        `update' `noancillary' `dryrun'
                    if r(ok) local rescued 1
                }
            }
            if `rescued' {
                local ++nok
            }
            else {
                local ++nfail
                local faillist "`faillist' `p'"
            }
        }
    }

    *-- summary --------------------------------------------------------------
    local verb "installed"
    if "`dryrun'" != "" local verb "resolvable"
    di as text _n "{hline 60}"
    di as text "usepackage summary: " as result "`nreq' requested" as text ", " ///
        as result "`nok' `verb'" as text ", " ///
        as result "`nskip' already present" as text ", " ///
        as result "`ndefer' awaiting confirmation" as text ", " ///
        as result "`nfail' unresolved"
    if "`deferlist'" != "" {
        di as text "  awaiting confirmation:" as result "`deferlist'"
        di as text "  these had an inferred (not exact) match; rerun interactively," ///
                   " or add {bf:noconfirm}."
    }
    if "`faillist'" != "" {
        di as error "  unresolved:`faillist'"
        di as text  "  try: {bf:usepackage} <name>{bf:, nearest}  to consider similar names,"
        di as text  "       or point at a source directly with {bf:from()} or {bf:github()}."
    }
    di as text "{hline 60}"

    return local deferred   "`deferlist'"
    return local unresolved "`faillist'"
    return scalar nfail  = `nfail'
    return scalar nok    = `nok'
    return scalar nskip  = `nskip'
    return scalar ndefer = `ndefer'
    return scalar nreq   = `nreq'
end


*==========================================================================
*  _up_status : is this command/package available, and is it shadowed?
*==========================================================================
program define _up_status, rclass
    args name

    local found  0
    local shadow ""
    local path   ""

    capture qui which `name'
    if _rc == 0 {
        local found 1
        local path `"`r(fn)'"'
        * r(fn) is not always set by which; fall back to a direct lookup
        if `"`path'"' == "" {
            capture qui findfile `name'.ado
            if _rc == 0 local path `"`r(fn)'"'
        }
        * a copy under PERSONAL beats anything net install writes to PLUS
        if strpos(lower(`"`path'"'), "/personal/") | strpos(lower(`"`path'"'), "\personal\") {
            local shadow `"`path'"'
        }
    }

    return scalar found = `found'
    return local  path  `"`path'"'
    return local  shadow `"`shadow'"'
end


*==========================================================================
*  _up_describe : split a package's files into installation vs ancillary
*==========================================================================
program define _up_describe, rclass
    syntax anything(name=pkg) [, from(string) ]

    *-- Read the .pkg manifest itself rather than scraping -ssc describe-.
    *-- -quietly- does NOT suppress describe output the way it does for
    *-- -net search-, so scraping it would either print to the screen or
    *-- capture nothing.  The manifest is the authoritative list anyway.
    *--
    *-- Stata decides installation-vs-ancillary purely by file extension: a
    *-- recognised ado-type extension is copied to the adopath by
    *-- -net install-, everything else (.do, .dta, .csv, .xlsx, .html, .zip,
    *-- .js ...) is ancillary and only arrives with -net get-.
    local instext "ado sthlp hlp ihlp mata mlib mo dlg idlg class scheme style py maint key"

    local ilist ""
    local alist ""

    *-- where does the manifest live?
    if `"`from'"' != "" {
        local base `"`from'"'
        if substr(`"`base'"', -1, 1) != "/" local base `"`base'/"'
        local url `"`base'`pkg'.pkg"'
    }
    else {
        local L = lower(substr("`pkg'", 1, 1))
        local url "http://fmwww.bc.edu/repec/bocode/`L'/`pkg'.pkg"
    }

    tempfile pk
    capture qui copy `"`url'"' "`pk'", replace
    if _rc {
        return scalar ok = 0
        exit 0
    }

    tempname fh
    capture file open `fh' using "`pk'", read text
    if _rc {
        return scalar ok = 0
        exit 0
    }
    file read `fh' line
    while r(eof) == 0 {
        *-- manifest file lines start with f/F (install) or g/G (ancillary)
        if regexm(`"`line'"', "^[fFgG] +(.+)$") {
            local fn = trim(regexs(1))
            local lead = substr(trim(`"`line'"'), 1, 1)
            *-- keep just the file name; manifests may carry ../dir/ prefixes
            local stub = "`fn'"
            if strpos("`stub'", "/") local stub = substr("`stub'", strrpos("`stub'", "/") + 1, .)
            local ext = lower(substr("`stub'", strrpos("`stub'", ".") + 1, .))
            if "`lead'" == "g" | "`lead'" == "G" {
                local alist `"`alist' `stub'"'
            }
            else if strpos(" `instext' ", " `ext' ") {
                local ilist `"`ilist' `stub'"'
            }
            else {
                local alist `"`alist' `stub'"'
            }
        }
        file read `fh' line
    }
    file close `fh'

    local na : word count `alist'
    local ni : word count `ilist'
    return local  instfiles `"`ilist'"'
    return local  ancfiles  `"`alist'"'
    return scalar nanc  = `na'
    return scalar ninst = `ni'
    return scalar ok = 1
end


*==========================================================================
*  _up_report_anc : tell the user what ancillary files are in play
*==========================================================================
program define _up_report_anc, rclass
    syntax anything(name=pkg) [, from(string) NOANCillary ]

    _up_describe `pkg', from(`"`from'"')
    if r(ok) == 0 exit 0
    local nanc = r(nanc)
    if `nanc' == 0 exit 0

    if "`noancillary'" != "" {
        di as text "      `nanc' ancillary file(s) available; " ///
                   "{bf:noancillary} specified, so they were not fetched"
        di as text `"      to get them later: {stata "net get `pkg'":net get `pkg'}"'
    }
    else {
        di as text "      + `nanc' ancillary file(s) fetched into the current directory"
    }
end


*==========================================================================
*  _up_netinstall : install from an explicit net source
*==========================================================================
program define _up_netinstall, rclass
    syntax anything(name=pkg) [, from(string) NOANCillary DRYrun Update ]

    local all "all"
    if "`noancillary'" != "" local all ""

    if "`dryrun'" != "" {
        di as text `"      would run: net install `pkg', from("`from'") `all' replace"'
        return scalar ok = 1
        exit 0
    }

    *-- update does NOT uninstall first: -net install, replace- overwrites
    *-- in place, and if the download fails the copy the user already has
    *-- is still there (v2.0.2).  No -force- (v2.0.3): it re-installs files
    *-- that are already up to date and adds a duplicate stata.trk entry
    *-- every time, after which -ado uninstall pkg- fails with r(111)
    capture qui net install `pkg', from(`"`from'"') `all' replace
    if _rc == 0 {
        di as text "      installed from " as result `"`from'"'
        _up_report_anc `pkg', from(`"`from'"') `noancillary'
        return scalar ok = 1
    }
    else {
        di as error "      could not install `pkg' from `from' (rc = " _rc ")"
        return scalar ok = 0
    }
end


*==========================================================================
*  _up_try : SSC, then the net search catalogue (with confirmation)
*==========================================================================
program define _up_try, rclass
    syntax anything(name=pkg) [, Update NOANCillary DRYrun NEARest NOCONFirm ///
        GHNEXT ]

    return scalar ok = 0
    return scalar skipped = 0

    local all "all"
    if "`noancillary'" != "" local all ""

    *-- 1. SSC ------------------------------------------------------------
    capture qui ssc describe `pkg'
    if _rc == 0 {
        if "`dryrun'" != "" {
            di as text "      found on SSC; would run: ssc install `pkg', `all' replace"
            return scalar ok = 1
            exit 0
        }
        *-- no uninstall first (see _up_netinstall): replace overwrites
        capture qui ssc install `pkg', `all' replace
        if _rc == 0 {
            di as text "      installed from " as result "SSC"
            _up_report_anc `pkg', `noancillary'
            return scalar ok = 1
            exit 0
        }
        else {
            di as error "      on SSC but install failed (rc = " _rc ")"
        }
    }

    *-- 2. net search catalogue -------------------------------------------
    _up_search `pkg', `nearest'
    local cand   `"`r(pkg)'"'
    local candfm `"`r(from)'"'
    local exact  = r(exact)
    local tier   `"`r(tier)'"'

    if `"`cand'"' == "" {
        di as error "      not found on SSC, and no match in the net search catalogue"
        if "`nearest'" == "" {
            di as text  "      {bf:nearest} would also consider similarly named packages"
        }
        *-- only suggest GitHub if we are not about to go looking there anyway
        if "`ghnext'" == "" {
            di as text  `"      if it lives on GitHub: {bf:usepackage `pkg', github(owner/repo)}"'
            di as text  `"      or search a whole account: {bf:usepackage `pkg', github(owner)}"'
        }
        return scalar ok = 0
        exit 0
    }

    *-- an inferred match is never installed silently ----------------------
    if `exact' == 0 {
        if "`tier'" == "command" {
            di as text "      not a package name, but " as result "`cand'" ///
                as text " ships a command called " as result "`pkg'"
        }
        else {
            di as text "      no exact match; nearest candidate is " ///
                as result "`cand'"
        }
        di as text `"          from {stata "net describe `cand', from(`candfm')":`candfm'}"'
        if "`dryrun'" != "" {
            *-- count it the way a real run would: with noconfirm it would
            *-- be installed; without, it waits for an answer
            if "`noconfirm'" != "" {
                di as text "      would install it ({bf:noconfirm} accepts the inferred match)"
                return scalar ok = 1
            }
            else {
                di as text "      would ask to install it (add {bf:noconfirm} to accept unattended)"
                return scalar ok = 0
                return scalar skipped = 1
            }
            exit 0
        }
        if "`noconfirm'" == "" {
            *-- There is nobody to answer a prompt in a batch or -do- run, and
            *-- usepackage is meant to sit at the top of a do-file, so refuse
            *-- rather than hang or install something unasked.
            if "`c(mode)'" == "batch" {
                di as text "      not installed: an inferred match needs confirmation,"
                di as text "      and this is a batch run with nobody to ask."
                di as text `"      add {bf:noconfirm} to accept inferred matches unattended, or"'
                di as text `"      name it exactly: {bf:usepackage `cand', from("`candfm'")}"'
                return scalar ok = 0
                return scalar skipped = 1
                exit 0
            }
            local ans ""
            di as text "      install it? (y/n) " _request(_upans)
            local ans = lower(trim("$_upans"))
            global _upans ""
            if "`ans'" != "y" & "`ans'" != "yes" {
                di as text "      skipped `cand' (not confirmed)"
                return scalar ok = 0
                return scalar skipped = 1
                exit 0
            }
        }
        else {
            di as text "      {bf:noconfirm} specified, accepting the inferred match"
        }
    }

    if "`dryrun'" != "" {
        di as text `"      would run: net install `cand', from("`candfm'") `all' replace"'
        return scalar ok = 1
        exit 0
    }

    *-- no uninstall first (see _up_netinstall): replace overwrites
    capture qui net install `cand', from(`"`candfm'"') `all' replace
    if _rc == 0 {
        if `exact' {
            di as text "      installed " as result "`cand'" as text " from `candfm'"
        }
        else {
            di as text "      installed near match " as result "`cand'" as text " for `pkg'"
        }
        _up_report_anc `cand', from(`"`candfm'"') `noancillary'
        return scalar ok = 1
    }
    else {
        di as error "      found `cand' at `candfm' but the install failed (rc = " _rc ")"
        return scalar ok = 0
    }
end


*==========================================================================
*  _up_search : parse net search output for an exact or nearest match
*==========================================================================
program define _up_search, rclass
    syntax anything(name=pkg) [, NEARest ]

    return local  pkg   ""
    return local  from  ""
    return scalar exact = 0
    return local  tier  "none"

    *-- capture the catalogue silently.  Run under -quietly- so nothing hits
    *-- the screen: an open log still records it, and what it records is raw
    *-- SMCL, in which each hit appears as
    *--     @net:describe PKG, from(URL)!PKG from URL@
    *-- so the package name and its site are explicitly delimited (far more
    *-- reliable than parsing the rendered two-column text).
    *-- -quietly- does not keep that raw SMCL out of the user's own open
    *-- logs, so pause every log that is on for the length of the search and
    *-- resume it afterwards.  (The Results window of a batch run is not a
    *-- log and cannot be paused; the raw lines still show there.)
    local paused ""
    capture quietly log query _all
    if _rc == 0 {
        local nlogs = r(numlogs)
        if "`nlogs'" == "" | "`nlogs'" == "." local nlogs 0
        forvalues i = 1/`nlogs' {
            if "`r(status`i')'" == "on" local paused `"`paused' `"`r(name`i')'"'"'
        }
    }
    foreach lg of local paused {
        if `"`lg'"' == "<unnamed>" capture quietly log off
        else                       capture quietly log off `lg'
    }
    tempfile log
    capture log close _upsearch
    capture qui log using "`log'", text replace name(_upsearch)
    capture qui net search `pkg'
    capture qui log close _upsearch
    foreach lg of local paused {
        if `"`lg'"' == "<unnamed>" capture quietly log on
        else                       capture quietly log on `lg'
    }

    tempname fh
    capture file open `fh' using "`log'", read text
    if _rc exit 0

    *-- The log hard-wraps at ~80 columns and marks continuations with a
    *-- leading ">".  Rejoin them before matching, or a long URL splits in two.
    *-- Everything is done in one inline pass: a candidate's description is the
    *-- run of lines after its @net:describe marker, so we just remember which
    *-- candidate we are inside and flag it the moment the requested name shows
    *-- up.  (Nothing long is passed to a subroutine -- descriptions can carry
    *-- quotes and would not survive positional argument passing.)
    local ncand 0
    local cur ""
    local pkglist ""
    local urllist ""
    local nd = lower("`pkg'")

    file read `fh' line
    local done 0
    while `done' == 0 {
        if r(eof) != 0 {
            local done 1
            local t ""
        }
        else {
            local t `"`line'"'
        }

        if substr(trim(`"`t'"'), 1, 1) == ">" & `done' == 0 {
            local rest = substr(trim(`"`t'"'), 2, .)
            local cur `"`cur'`rest'"'
        }
        else {
            *-- classify the buffered logical line
            if `"`cur'"' != "" {
                if regexm(`"`cur'"', "@net:describe ([^,]+), from\(([^)]+)\)") {
                    local ++ncand
                    local pkglist `"`pkglist' `=trim(regexs(1))'"'
                    local urllist `"`urllist' `=trim(regexs(2))'"'
                }
                else if `ncand' > 0 {
                    *-- strip SMCL markers so "help ^dropmiss^" reads as a word
                    local d `"`cur'"'
                    local d : subinstr local d "^" " ", all
                    local d : subinstr local d "{cmd:" " ", all
                    local d : subinstr local d "}" " ", all
                    local d : subinstr local d ":" " ", all
                    local d = lower(`"`d'"')
                    if regexm(`"`d'"', "(^|[^a-z0-9_])`nd'([^a-z0-9_]|$)") {
                        local hit`ncand' 1
                    }
                }
            }
            local cur `"`t'"'
        }

        if `done' == 0 file read `fh' line
    }
    file close `fh'

    if `ncand' == 0 exit 0

    *-- Choose the index FIRST, then return once, outside any loop.  (Returning
    *-- from inside forvalues is not reliable here: the loop keeps running and
    *-- each later match overwrites the earlier return, so the LAST hit wins
    *-- instead of the first.)

    *-- tier 1: a package actually named what the user asked for
    local pick 0
    forvalues i = 1/`ncand' {
        if `pick' == 0 {
            local nm : word `i' of `pkglist'
            if lower("`nm'") == lower("`pkg'") local pick `i'
        }
    }
    if `pick' > 0 {
        local nm : word `pick' of `pkglist'
        local fm : word `pick' of `urllist'
        return local  pkg   "`nm'"
        return local  from  "`fm'"
        return scalar exact = 1
        return local  tier  "name"
        exit 0
    }

    *-- tier 2: the requested name is a COMMAND shipped by one of these
    *-- packages (its description mentions the name).  This is the usual case
    *-- for Stata Journal / STB material -- dropmiss lives in dm89_2, bacon in
    *-- st0197 -- so treat it as a strong hit, but still confirm before
    *-- installing, because the mapping is inferred rather than declared.
    local pick 0
    forvalues i = 1/`ncand' {
        if `pick' == 0 {
            local flag "`hit`i''"
            if "`flag'" == "1" local pick `i'
        }
    }
    if `pick' > 0 {
        local nm : word `pick' of `pkglist'
        local fm : word `pick' of `urllist'
        return local  pkg   "`nm'"
        return local  from  "`fm'"
        return scalar exact = 0
        return local  tier  "command"
        exit 0
    }

    *-- tier 3: nothing but name similarity, and only when asked
    if "`nearest'" != "" {
        local nm : word 1 of `pkglist'
        local fm : word 1 of `urllist'
        return local  pkg   "`nm'"
        return local  from  "`fm'"
        return scalar exact = 0
        return local  tier  "nearest"
    }
end


*==========================================================================


*==========================================================================
*  _up_urlok : does this URL resolve?  (Stata has no HEAD, so try a copy)
*==========================================================================
program define _up_urlok, rclass
    args url
    tempfile t
    capture qui copy `"`url'"' "`t'", replace
    return scalar ok = (_rc == 0)
end


*==========================================================================
*  _up_github : install a package from a GitHub repository
*==========================================================================
program define _up_github, rclass
    syntax anything(name=pkg) [, repo(string) branch(string) ///
        Update NOANCillary DRYrun ]

    * Accept owner/repo, owner/repo#branch, owner/repo:subdir, a pasted URL, or
    * a bare owner.  STRIP THE URL FIRST: "https://github.com/..." contains a
    * colon of its own, so splitting on ":" before removing the scheme leaves
    * r == "https" (and that is exactly what it used to do).
    local r `"`repo'"'
    local sub ""

    local r = subinstr(`"`r'"', "https://github.com/", "", .)
    local r = subinstr(`"`r'"', "http://github.com/", "", .)
    local r = subinstr(`"`r'"', "https://raw.githubusercontent.com/", "", .)
    local r = subinstr(`"`r'"', "http://raw.githubusercontent.com/", "", .)
    local r = subinstr(`"`r'"', "https://www.github.com/", "", .)
    local r = subinstr(`"`r'"', "github.com/", "", .)

    * now the only "#" or ":" left are ours
    if strpos(`"`r'"', "#") {
        local branch = substr(`"`r'"', strpos(`"`r'"', "#") + 1, .)
        local r      = substr(`"`r'"', 1, strpos(`"`r'"', "#") - 1)
    }
    if strpos(`"`r'"', ":") {
        local sub = substr(`"`r'"', strpos(`"`r'"', ":") + 1, .)
        local r   = substr(`"`r'"', 1, strpos(`"`r'"', ":") - 1)
        if substr("`sub'", -1, 1) != "/" local sub "`sub'/"
    }

    if substr("`r'", -4, 4) == ".git" local r = substr("`r'", 1, length("`r'") - 4)
    if substr("`r'", -1, 1) == "/"    local r = substr("`r'", 1, length("`r'") - 1)
    * a pasted /tree/<branch> or /blob/<branch> tail
    if regexm("`r'", "^([^/]+/[^/]+)/(tree|blob)/([^/]+)") {
        local br2 = regexs(3)
        local r   = regexs(1)
        if "`branch'" == "" local branch "`br2'"
    }

    * bare owner: look through that owner's repositories for the package
    if !strpos("`r'", "/") {
        if "`r'" == "" {
            di as error "usepackage: github() is empty"
            return scalar ok = 0
            exit 0
        }
        _up_ghsearch, owner("`r'") pkg("`pkg'") branch("`branch'")
        if "`r(repo)'" == "" {
            return scalar ok = 0
            exit 0
        }
        local r `"`r(repo)'"'
        local found `"`r(base)'"'
        local declared = r(declared)
        di as text "      matched " as result "`r'" as text " in owner " as result "`repo'"
        if `declared' == 0 {
            *-- the repo name merely resembles the package: confirm
            if "`dryrun'" == "" & "`c(mode)'" == "batch" {
                di as text "      that repo does not ship a `pkg'.pkg, so the match is a guess;"
                di as text "      batch run, so nothing installed.  Name it exactly with"
                di as text "      github(`r') if it is right."
                return scalar ok = 0
                exit 0
            }
            else if "`dryrun'" == "" {
                di as text "      no `pkg'.pkg in that repo, so this is a guess. install? (y/n) " ///
                    _request(_upgha)
                local a = lower(trim("$_upgha"))
                global _upgha ""
                if "`a'" != "y" & "`a'" != "yes" {
                    di as text "      skipped."
                    return scalar ok = 0
                    exit 0
                }
            }
        }
        _up_netinstall `pkg', from(`"`found'"') `noancillary' `dryrun' `update'
        return scalar ok = r(ok)
        exit 0
    }

    local branches "`branch' main master"
    local subdirs  `""`sub'" "" "ado/" "src/" "stata/" "code/""'
    if "`sub'" != "" local subdirs `""`sub'""'

    di as text "      probing GitHub layout for " as result "`r'"

    local found ""
    foreach br of local branches {
        if "`found'" != "" continue
        foreach sd of local subdirs {
            if "`found'" != "" continue
            local base "https://raw.githubusercontent.com/`r'/`br'/`sd'"
            _up_urlok "`base'stata.toc"
            if r(ok) {
                local found `"`base'"'
                di as text "      found stata.toc on branch " as result "`br'" ///
                   as text cond("`sd'"=="", " at the repository root", " under `sd'")
            }
        }
    }

    if `"`found'"' == "" {
        di as error "      no stata.toc found in `r' (tried branches: `branches')"
        di as text  "      a repository needs stata.toc + <pkg>.pkg for net install;"
        di as text  "      for a data-only repository use {bf:data()} instead."
        return scalar ok = 0
        exit 0
    }

    _up_netinstall `pkg', from(`"`found'"') `noancillary' `dryrun' `update'
    return scalar ok = r(ok)
end


*==========================================================================
*  _up_ghnorm : reduce anything GitHub-shaped to owner[/repo] (+ branch, subdir)
*
*  Strips the scheme FIRST: "https://github.com/..." carries a colon of its own,
*  so splitting on ":" for the subdir form before removing it leaves "https".
*==========================================================================
program define _up_ghnorm, rclass
    syntax , target(string) [ branch(string) ]

    local r `"`target'"'
    local sub ""

    local r = subinstr(`"`r'"', "https://github.com/", "", .)
    local r = subinstr(`"`r'"', "http://github.com/", "", .)
    local r = subinstr(`"`r'"', "https://raw.githubusercontent.com/", "", .)
    local r = subinstr(`"`r'"', "http://raw.githubusercontent.com/", "", .)
    local r = subinstr(`"`r'"', "https://www.github.com/", "", .)
    local r = subinstr(`"`r'"', "github.com/", "", .)

    if strpos(`"`r'"', "#") {
        local branch = substr(`"`r'"', strpos(`"`r'"', "#") + 1, .)
        local r      = substr(`"`r'"', 1, strpos(`"`r'"', "#") - 1)
    }
    if strpos(`"`r'"', ":") {
        local sub = substr(`"`r'"', strpos(`"`r'"', ":") + 1, .)
        local r   = substr(`"`r'"', 1, strpos(`"`r'"', ":") - 1)
        if substr("`sub'", -1, 1) != "/" local sub "`sub'/"
    }

    if substr("`r'", -4, 4) == ".git" local r = substr("`r'", 1, length("`r'") - 4)
    if substr("`r'", -1, 1) == "/"    local r = substr("`r'", 1, length("`r'") - 1)
    if regexm("`r'", "^([^/]+/[^/]+)/(tree|blob)/([^/]+)") {
        local br2 = regexs(3)
        local r   = regexs(1)
        if "`branch'" == "" local branch "`br2'"
    }

    return local target `"`r'"'
    return local branch `"`branch'"'
    return local sub    `"`sub'"'
    return scalar isrepo = strpos("`r'", "/") > 0
end


*==========================================================================
*  _up_ghlist : catalogue the installable Stata packages in an account or repo
*
*  One API request per 100 repositories lists the account (with each
*  repository's default branch);
*  everything after that is raw.githubusercontent.com, which is not rate-limited.
*  A repository is installable when it carries a stata.toc, and that file names
*  the packages it offers on its "p" lines -- so the toc is the authority on what
*  is actually installable, not a guess from file names.
*==========================================================================
program define _up_ghlist
    syntax , target(string) [ branch(string) ]

    _up_ghnorm, target(`"`target'"') branch(`"`branch'"')
    local t   `"`r(target)'"'
    local br0 `"`r(branch)'"'
    local isrepo = r(isrepo)

    *-- a single repository: just read its toc
    if `isrepo' {
        di as text _n "{bf:usepackage}: Stata packages in " as result "`t'"
        _up_ghreadtoc, repo("`t'") branch(`"`br0'"')
        if "`r(pkgs)'" == "" {
            di as error "      no stata.toc found (so nothing here is net-installable)"
            di as text  "      for a data-only repository use {bf:data()}"
            exit 0
        }
        local owner = substr("`t'", 1, strpos("`t'", "/") - 1)
        di as text "      packages: " as result "`r(pkgs)'"
        if `"`r(desc)'"' != "" di as text "      " `"`r(desc)'"'
        local one : word 1 of `r(pkgs)'
        di as text `"      install with: {bf:usepackage `one', github(`t')}"'
        exit 0
    }

    *-- a whole account
    local owner "`t'"
    di as text _n "{bf:usepackage}: Stata packages owned by " as result "`owner'"

    _up_ghrepos, owner("`owner'")
    if r(ok) == 0 {
        di as error "      could not list `owner''s repositories (API unreachable or rate-limited)"
        exit 601
    }
    local repos `"`r(repos)'"'
    local brs   `"`r(branches)'"'

    local nrepo : word count `repos'
    if `nrepo' == 0 {
        di as error "      no repositories found for `owner'"
        exit 601
    }
    di as text "      `nrepo' repositor(ies); checking each for a stata.toc..."
    di as text ""
    di as text "      {hline 62}"
    di as text "      {bf:package}          {bf:repository}                      {bf:branch}"
    di as text "      {hline 62}"

    local npkg  0
    local nwith 0
    local allpkgs ""
    forvalues i = 1/`nrepo' {
        local fn : word `i' of `repos'
        local db : word `i' of `brs'
        if "`br0'" != "" local db "`br0'"
        _up_ghreadtoc, repo("`fn'") branch("`db'")
        local plist `"`r(pkgs)'"'
        if "`plist'" != "" {
            local ++nwith
            local rn = substr("`fn'", strpos("`fn'", "/") + 1, .)
            local usebr `"`r(branch)'"'
            foreach p of local plist {
                local ++npkg
                local allpkgs `"`allpkgs' `p'"'
                di as text "      " as result %-17s "`p'" ///
                   as text %-33s "`rn'" as text "`usebr'"
            }
        }
    }
    di as text "      {hline 62}"

    if `npkg' == 0 {
        di as text "      none of `owner''s repositories carry a stata.toc"
        di as text "      (a repository needs stata.toc + <pkg>.pkg to be net-installable)"
        exit 0
    }

    local nno = `nrepo' - `nwith'
    di as text "      `npkg' package(s) in `nwith' repositor(ies); " ///
               "`nno' repositor(ies) have no stata.toc"
    di as text `"      install one with: {bf:usepackage <package>, github(`owner')}"'
    di as text `"      or all of them:   {bf:usepackage`allpkgs', ghowner(`owner')}"'
end


*==========================================================================
*  _up_ghrepos : list an owner's repositories, every page of them
*
*  The API hands back at most 100 repositories per request, so keep asking
*  for the next page until one comes back short.  Capped at 10 pages (1,000
*  repositories) to stay well inside the unauthenticated budget of 60
*  requests an hour.  full_name and default_branch appear once per
*  repository, in order, so collecting each into a list and pairing by index
*  is exact.
*
*  r(ok) is 0 only when the FIRST page cannot be read; a later page that
*  fails just ends the listing with what was already collected.
*==========================================================================
program define _up_ghrepos, rclass
    syntax , owner(string)

    local repos ""
    local brs   ""
    local ok    0
    local more  1
    local pg    0
    while `more' & `pg' < 10 {
        local ++pg
        *-- $usepackage_apitest (a folder of <owner>_<page>.json files) lets the
        *-- test battery exercise paging without touching the network
        if `"$usepackage_apitest"' != "" {
            local src `"$usepackage_apitest/`owner'_`pg'.json"'
        }
        else {
            local src "https://api.github.com/users/`owner'/repos?per_page=100&page=`pg'"
        }
        tempfile js
        capture qui copy `"`src'"' "`js'", replace
        if _rc {
            local more 0
            continue
        }
        tempname fh
        capture file open `fh' using "`js'", read text
        if _rc {
            local more 0
            continue
        }
        local ok 1
        local nthis 0
        file read `fh' line
        while r(eof) == 0 {
            foreach key in full_name default_branch {
                local work `"`macval(line)'"'
                local guard 0
                local klen = length("`key'") + 2
                while strpos(`"`macval(work)'"', `""`key'""') > 0 & `guard' < 5000 {
                    local ++guard
                    local pos = strpos(`"`macval(work)'"', `""`key'""')
                    local work = substr(`"`macval(work)'"', `pos' + `klen', .)
                    if regexm(`"`macval(work)'"', `"^: *"([^"]+)""') {
                        if "`key'" == "full_name" {
                            local repos `"`repos' `=regexs(1)'"'
                            local ++nthis
                        }
                        else {
                            local brs `"`brs' `=regexs(1)'"'
                        }
                    }
                }
            }
            file read `fh' line
        }
        file close `fh'
        if `nthis' < 100 local more 0
    }

    return local  repos    `"`repos'"'
    return local  branches `"`brs'"'
    return scalar ok = `ok'
end


*==========================================================================
*  _up_ghreadtoc : read a repository's stata.toc and return the packages it names
*==========================================================================
program define _up_ghreadtoc, rclass
    syntax , repo(string) [ branch(string) ]

    return local pkgs   ""
    return local desc   ""
    return local branch ""
    return local base   ""

    *-- A program cannot read its own staged return values, so guarding on
    *-- "`r(pkgs)'" would actually test the PREVIOUS caller's r() -- which, in a
    *-- loop over repositories, silently skipped every repo after the first hit.
    *-- Use a plain local, and stop at the first branch that works so the branch
    *-- reported is the real one (raw.githubusercontent resolves "master" even
    *-- when the default branch is "main", so probing on would always end there).
    local gotit 0
    local tried ""
    foreach br in `branch' main master {
        if !strpos(" `tried' ", " `br' ") & `gotit' == 0 {
            local tried "`tried' `br'"
            foreach sd in "" "ado/" {
                if `gotit' == 0 {
                    local base "https://raw.githubusercontent.com/`repo'/`br'/`sd'"
                    tempfile toc
                    capture qui copy "`base'stata.toc" "`toc'", replace
                    if _rc == 0 {
                        local plist ""
                        local dfirst ""
                        tempname th
                        capture file open `th' using "`toc'", read text
                        if _rc == 0 {
                            file read `th' tl
                            while r(eof) == 0 {
                                if regexm(`"`tl'"', "^p +([^ ]+)") {
                                    local plist `"`plist' `=regexs(1)'"'
                                }
                                else if regexm(`"`tl'"', "^d +(.+)$") & "`dfirst'" == "" {
                                    local dfirst `"`=trim(regexs(1))'"'
                                }
                                file read `th' tl
                            }
                            file close `th'
                        }
                        if "`plist'" != "" {
                            local gotit 1
                            return local pkgs   `"`plist'"'
                            return local desc   `"`dfirst'"'
                            return local branch "`br'"
                            return local base   "`base'"
                        }
                    }
                }
            }
        }
    }
end


*==========================================================================
*  _up_ghsearch : find which of an owner's repositories ships a package
*
*  Lists the owner's repositories against the ordinary API (60/hour; one
*  request per 100 repositories), not the code-search API (about 10/minute), then narrows by name
*  before probing anything.  A repository that actually contains <pkg>.pkg is
*  treated as declared -- that is proof, not a guess -- while a repository whose
*  name merely resembles the package is offered for confirmation.
*==========================================================================
program define _up_ghsearch, rclass
    syntax , owner(string) pkg(string) [ branch(string) ]

    return local  repo     ""
    return local  base     ""
    return scalar declared = 0

    di as text "      searching repositories owned by " as result "`owner'"

    _up_ghrepos, owner("`owner'")
    if r(ok) == 0 {
        di as error "      could not list `owner''s repositories (API unreachable or rate-limited)"
        di as text  "      name the repository directly: {bf:github(`owner'/<repo>)}"
        exit 0
    }
    local repos `"`r(repos)'"'

    local nrepo : word count `repos'
    if `nrepo' == 0 {
        di as error "      no repositories found for `owner'"
        exit 0
    }
    di as text "      `nrepo' repositor(ies) listed; narrowing by name"

    *-- rank: exact repo name, then name-starts-with, then name-contains
    local P = lower("`pkg'")
    local tier1 ""
    local tier2 ""
    local tier3 ""
    foreach fn of local repos {
        local nm = substr("`fn'", strpos("`fn'", "/") + 1, .)
        local NM = lower("`nm'")
        if "`NM'" == "`P'" {
            local tier1 `"`tier1' `fn'"'
        }
        else if substr("`NM'", 1, length("`P'")) == "`P'" {
            local tier2 `"`tier2' `fn'"'
        }
        else if strpos("`NM'", "`P'") {
            local tier3 `"`tier3' `fn'"'
        }
    }
    local cands `"`tier1' `tier2' `tier3'"'
    local ncand : word count `cands'
    if `ncand' == 0 {
        di as error `"      none of `owner''s repositories look like "`pkg'""'
        di as text   "      name the repository directly: {bf:github(`owner'/<repo>)}"
        exit 0
    }

    *-- Probe the shortlist for an installable layout.  Guard every loop with a
    *-- done flag and return ONCE at the end: -exit- does not reliably break out
    *-- of a foreach here, so an early return would be overwritten by later
    *-- iterations (and would print the not-found message on success).
    local gotrepo  ""
    local gotbase  ""
    local declared 0
    local done     0

    foreach fn of local cands {
        if `done' == 0 {
            foreach br in `branch' main master {
                if `done' == 0 {
                    foreach sd in "" "ado/" "src/" "stata/" "code/" {
                        if `done' == 0 {
                            local base "https://raw.githubusercontent.com/`fn'/`br'/`sd'"
                            *-- <pkg>.pkg present means the repo DECLARES this
                            *-- package: that is proof, not a resemblance
                            _up_urlok "`base'`pkg'.pkg"
                            local haspkg = r(ok)
                            if `haspkg' {
                                _up_urlok "`base'stata.toc"
                                if r(ok) {
                                    local gotrepo  "`fn'"
                                    local gotbase  "`base'"
                                    local declared 1
                                    local done     1
                                }
                            }
                            else if "`gotrepo'" == "" {
                                _up_urlok "`base'stata.toc"
                                if r(ok) {
                                    local gotrepo "`fn'"
                                    local gotbase "`base'"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if "`gotrepo'" != "" {
        return local  repo     "`gotrepo'"
        return local  base     "`gotbase'"
        return scalar declared = `declared'
        exit 0
    }

    di as error `"      found repositories matching "`pkg'" but none carries a stata.toc"'
    di as text   "      (a data-only repository needs {bf:data()} instead)"
end


*==========================================================================
*  _up_data : fetch data files out of a GitHub repository
*==========================================================================
program define _up_data, rclass
    *-- the repository arrives as an option, not as -anything-: owner/repo is
    *-- not a valid Stata name, so -anything- rejects the slash
    syntax [anything], repo(string) [ files(string) into(string) ///
        branch(string) DRYrun NOCONFirm USEit ]

    if `"`into'"' == "" local into "."
    *-- expand a leading ~ ourselves; Stata's file commands do not
    _up_tilde `"`into'"'
    local into `"`r(path)'"'
    if substr(`"`into'"', -1, 1) == "/" & length(`"`into'"') > 1 {
        local into = substr(`"`into'"', 1, length(`"`into'"') - 1)
    }

    *-- counts posted back to usepackage (and from there to the user)
    return scalar nreq  = 0
    return scalar nok   = 0
    return scalar nfail = 0
    return local  files  ""
    return local  failed ""

    local r `"`repo'"'
    if strpos(`"`r'"', "#") {
        local branch = substr(`"`r'"', strpos(`"`r'"', "#") + 1, .)
        local r      = substr(`"`r'"', 1, strpos(`"`r'"', "#") - 1)
    }
    local r = subinstr(`"`r'"', "https://github.com/", "", .)
    local r = subinstr(`"`r'"', "http://github.com/", "", .)
    if substr("`r'", -1, 1) == "/" local r = substr("`r'", 1, length("`r'") - 1)

    if !strpos("`r'", "/") {
        di as error "usepackage: data() wants owner/repo, got `r'"
        exit 198
    }

    di as text _n "{bf:usepackage}: data from " as result "`r'"

    *-- which branch is live?
    local usebr ""
    foreach br in `branch' main master {
        if "`usebr'" != "" continue
        _up_urlok "https://raw.githubusercontent.com/`r'/`br'/README.md"
        if r(ok) {
            local usebr "`br'"
        }
    }
    if "`usebr'" == "" {
        * no README is fine -- fall back to whichever branch the API knows
        foreach br in `branch' main master {
            if "`usebr'" != "" continue
            tempfile probe
            capture qui copy "https://api.github.com/repos/`r'/git/trees/`br'" "`probe'", replace
            if _rc == 0 local usebr "`br'"
        }
    }
    if "`usebr'" == "" {
        di as error "      could not reach `r' on branch main or master"
        exit 601
    }
    di as text "      branch: " as result "`usebr'"

    local raw "https://raw.githubusercontent.com/`r'/`usebr'"

    *-- create into() (nested folders too) before any copy lands there
    if "`dryrun'" == "" {
        _up_mkdirp `"`into'"'
    }

    *-- explicit file list: just fetch it
    if `"`files'"' != "" {
        local got ""
        local bad ""
        local nf 0
        foreach f of local files {
            local ++nf
            local stub = substr("`f'", strrpos("`f'", "/") + 1, .)
            if "`dryrun'" != "" {
                di as text `"      would fetch `f' -> `into'/`stub'"'
                continue
            }
            _up_fetch, url("`raw'/`f'") dest(`"`into'/`stub'"') ///
                repo("`r'") branch("`usebr'") path("`f'")
            if r(ok) {
                di as text "      fetched " as result "`stub'" _c
                if r(lfs) {
                    di as text "  (Git LFS -- pulled from the media endpoint)"
                }
                else {
                    di ""
                }
                local got "`got' `stub'"
            }
            else if r(lfs) {
                di as error "      `f' is a Git LFS pointer and the media endpoint failed"
                local bad "`bad' `f'"
            }
            else {
                di as error "      could not fetch `f' (rc = " r(rc) ")"
                local bad "`bad' `f'"
            }
        }
        local ngot : word count `got'
        local nbad : word count `bad'
        if `nbad' > 0 & "`dryrun'" == "" {
            di as error "      `nbad' of `nf' file(s) not fetched; see r(datafailed)"
        }
        _up_useit `"`got'"' `"`into'"' "`useit'"
        return scalar nreq  = `nf'
        return scalar nok   = cond("`dryrun'" != "", `nf', `ngot')
        return scalar nfail = `nbad'
        return local  files  `"`got'"'
        return local  failed `"`bad'"'
        exit 0
    }

    *-- otherwise discover data files through the API
    di as text "      listing data files via the GitHub API..."
    tempfile js
    capture qui copy "https://api.github.com/repos/`r'/git/trees/`usebr'?recursive=1" "`js'", replace
    if _rc {
        di as error "      could not read the repository tree (API unreachable or rate-limited)"
        di as text  "      name the files directly instead, e.g. files(data/gdp.csv)"
        exit 601
    }

    tempname fh
    file open `fh' using "`js'", read text
    local cand ""
    local n 0
    local nlines 0
    *-- Stata's -copy- of the API returns MINIFIED json, the whole tree on one
    *-- line ({"path":"data/gdp.csv","mode":...}), while a browser or curl gets
    *-- it pretty-printed one path per line.  Handle both: walk every "path"
    *-- occurrence in each line.  Advancement is by strpos, which always moves
    *-- forward at least past the literal, so this cannot spin.
    file read `fh' line
    while r(eof) == 0 {
        local ++nlines
        local work `"`line'"'
        local guard 0
        while strpos(`"`work'"', `""path""') > 0 & `guard' < 20000 {
            local ++guard
            local pos = strpos(`"`work'"', `""path""')
            local work = substr(`"`work'"', `pos' + 6, .)
            if regexm(`"`work'"', `"^: *"([^"]+)""') {
                local p = regexs(1)
                local ext = lower(substr("`p'", strrpos("`p'", ".") + 1, .))
                if inlist("`ext'", "dta", "csv", "tsv", "xlsx", "xls", "txt") {
                    local ++n
                    local cand `"`cand' `p'"'
                }
            }
        }
        file read `fh' line
    }
    file close `fh'

    if `n' == 0 {
        di as error "      no .dta/.csv/.tsv/.xlsx/.txt files found in `r'"
        exit 601
    }

    di as text "      `n' data file(s) found:"
    local i 0
    foreach p of local cand {
        local ++i
        if `i' <= 20 {
            di as text "         `p'"
        }
    }
    if `n' > 20 {
        di as text "         ... and " `n' - 20 " more"
    }

    if "`dryrun'" != "" {
        di as text "      dryrun: nothing fetched"
        exit 0
    }

    if "`noconfirm'" == "" {
        if "`c(mode)'" == "batch" {
            di as text "      nothing fetched: `n' file(s) found but this is a batch run,"
            di as text "      so there is nobody to confirm a bulk download."
            di as text "      add {bf:noconfirm} to take all of them, or name them with {bf:files()}."
            exit 0
        }
        di as text "      fetch all `n' file(s) into `into'? (y/n) " _request(_updans)
        local ans = lower(trim("$_updans"))
        global _updans ""
        if "`ans'" != "y" & "`ans'" != "yes" {
            di as text "      nothing fetched (not confirmed)."
            di as text "      narrow it with files(...) to pick specific files."
            exit 0
        }
    }

    local got ""
    local bad ""
    local nlfs 0
    foreach p of local cand {
        local stub = substr("`p'", strrpos("`p'", "/") + 1, .)
        _up_fetch, url("`raw'/`p'") dest(`"`into'/`stub'"') ///
            repo("`r'") branch("`usebr'") path("`p'")
        if r(ok) {
            di as text "      fetched " as result "`stub'" _c
            if r(lfs) {
                local ++nlfs
                di as text "  (Git LFS)"
            }
            else {
                di ""
            }
            local got "`got' `stub'"
        }
        else if r(lfs) {
            di as error "      `p' is a Git LFS pointer and the media endpoint failed"
            local bad "`bad' `p'"
        }
        else {
            di as error "      could not fetch `p' (rc = " r(rc) ")"
            local bad "`bad' `p'"
        }
    }
    if `nlfs' > 0 {
        di as text "      (`nlfs' file(s) were Git LFS pointers, pulled from the media endpoint)"
    }

    _up_useit `"`got'"' `"`into'"' "`useit'"
    local ngot : word count `got'
    local nbad : word count `bad'
    return scalar nreq  = `n'
    return scalar nok   = `ngot'
    return scalar nfail = `nbad'
    return local  files  `"`got'"'
    return local  failed `"`bad'"'
end


*==========================================================================
*  _up_tilde : expand a leading ~ from HOME (Windows: USERPROFILE, then
*  HOMEDRIVE+HOMEPATH, then HOME)
*==========================================================================
program define _up_tilde, rclass
    args path
    if substr(`"`path'"', 1, 1) == "~" & inlist(substr(`"`path'"', 2, 1), "", "/", "\") {
        local home : env HOME
        if "`c(os)'" == "Windows" {
            local up : env USERPROFILE
            local hd : env HOMEDRIVE
            local hp : env HOMEPATH
            if `"`up'"' != "" local home `"`up'"'
            else if `"`hd'`hp'"' != "" local home `"`hd'`hp'"'
        }
        if `"`home'"' == "" {
            di as error "usepackage: cannot expand ~ (HOME is not set)"
            exit 601
        }
        local rest = substr(`"`path'"', 2, .)
        local path `"`home'`rest'"'
    }
    return local path `"`path'"'
end


*==========================================================================
*  _up_mkdirp : create a folder and any missing parents (Mata, no shell)
*==========================================================================
program define _up_mkdirp
    args dir
    mata: _up_mkdirp_m(st_local("dir"))
end

mata:
void _up_mkdirp_m(string scalar dir)
{
    string scalar d, built, sep
    string rowvector parts
    real scalar i

    d = subinstr(dir, "\\", "/")
    if (d == "" | direxists(d)) return
    parts = tokens(d, "/")
    built = ""
    for (i = 1; i <= cols(parts); i++) {
        sep = parts[i]
        built = built + sep
        if (sep != "/" & built != "." & built != ".." & !(strlen(built) == 2 & substr(built, 2, 1) == ":")) {
            if (!direxists(built)) mkdir(built)
        }
    }
    if (!direxists(d)) {
        errprintf("usepackage: could not create folder %s\n", dir)
        exit(603)
    }
}
end


*==========================================================================
*  _up_fetch : copy one repo file, transparently resolving Git LFS pointers
*
*  A data repository that tracks big files with Git LFS serves a ~130-byte
*  TEXT STUB from raw.githubusercontent.com, not the data:
*      version https://git-lfs.github.com/spec/v1
*      oid sha256:...
*      size 34295
*  The copy "succeeds" and you get a file Stata cannot read.  GitHub exposes
*  the real bytes at media.githubusercontent.com/media/..., so detect the stub
*  and retry there instead of handing back something broken.
*==========================================================================
program define _up_fetch, rclass
    syntax , url(string) dest(string) [ repo(string) branch(string) path(string) ]

    return scalar ok  = 0
    return scalar lfs = 0

    capture qui copy `"`url'"' `"`dest'"', replace
    if _rc {
        return scalar rc = _rc
        exit 0
    }

    *-- is what landed an LFS pointer?
    local islfs 0
    tempname fh
    capture file open `fh' using `"`dest'"', read text
    if _rc == 0 {
        file read `fh' l1
        if strpos(`"`l1'"', "git-lfs.github.com/spec") local islfs 1
        file close `fh'
    }

    if `islfs' == 0 {
        return scalar ok = 1
        exit 0
    }

    *-- retry through the LFS media endpoint
    return scalar lfs = 1
    if "`repo'" == "" | "`branch'" == "" | "`path'" == "" {
        return scalar ok = 0
        exit 0
    }
    local murl "https://media.githubusercontent.com/media/`repo'/`branch'/`path'"
    capture qui copy `"`murl'"' `"`dest'"', replace
    if _rc == 0 {
        return scalar ok = 1
    }
    else {
        return scalar rc = _rc
    }
end


*==========================================================================
*  _up_useit : load a single fetched dataset if the user asked for it
*==========================================================================
program define _up_useit
    *-- the caller has already refused (r(4)) when unsaved data would be lost
    args got into useit
    if "`useit'" == "" exit 0
    local nf : word count `got'
    if `nf' != 1 {
        di as text "      {bf:use} ignored: `nf' files fetched, so none was loaded"
        exit 0
    }
    local f : word 1 of `got'
    local ext = lower(substr("`f'", strrpos("`f'", ".") + 1, .))
    if "`ext'" == "dta" {
        use `"`into'/`f'"', clear
    }
    else if inlist("`ext'", "csv", "tsv", "txt") {
        *-- bindquote(strict): a quoted text field may hold a line break
        import delimited `"`into'/`f'"', clear varnames(1) bindquote(strict)
    }
    else if inlist("`ext'", "xlsx", "xls") {
        import excel `"`into'/`f'"', clear firstrow
    }
    else {
        di as text "      {bf:use} ignored: don't know how to read .`ext'"
        exit 0
    }
    di as text "      loaded " as result "`f'" as text " (" _N " obs, " c(k) " vars)"
end


*==========================================================================
*  _up_scan : read a do-file and report commands that do not resolve
*==========================================================================
program define _up_scan, rclass
    args dofile

    capture confirm file `"`dofile'"'
    if _rc {
        di as error "usepackage: cannot find do-file `dofile'"
        exit 601
    }

    di as text _n "{bf:usepackage}: scanning " as result `"`dofile'"' ///
        as text " for unresolved commands"

    tempname fh
    file open `fh' using `"`dofile'"', read text
    local seen ""
    local miss ""
    local defined ""          // programs the file defines itself
    local inblock 0           // inside a mata/python ... end block
    local incomm  0           // inside a /* ... */ comment
    local incont  0           // the previous line ended with ///
    local semi    0           // #delimit ; is in force
    local newstmt 1           // under #delimit ; : this line starts a statement
    local tab = char(9)
    file read `fh' line
    while r(eof) == 0 {
        *-- Lines routinely contain double quotes (paths, option strings) and
        *-- macro references.  Use -macval- with compound quotes throughout and
        *-- pull tokens with -gettoken-, which is quote-safe: evaluating
        *-- substr("`t'", ...) on a line holding a quoted path breaks the
        *-- expression and the remnant gets run as a command (that is how a
        *-- path once surfaced as "Users not found").
        local t `"`macval(line)'"'
        local t : subinstr local t "`tab'" " ", all
        local s = strtrim(`"`macval(t)'"')
        local skip 0
        local wascont `incont'

        if `inblock' {
            *-- Mata and Python code is not Stata commands; wait for -end-
            if `"`macval(s)'"' == "end" local inblock 0
            local skip 1
        }
        else if `incomm' {
            if strpos(`"`macval(s)'"', "*/") local incomm 0
            local skip 1
        }
        else if substr(`"`macval(s)'"', 1, 2) == "/*" {
            if !strpos(`"`macval(s)'"', "*/") local incomm 1
            local skip 1
        }
        else if `"`macval(s)'"' == "" | substr(`"`macval(s)'"', 1, 2) == "//" {
            local skip 1
        }
        else if substr(`"`macval(s)'"', 1, 1) == "#" {
            *-- #delimit ; / #delimit cr
            if regexm(lower(`"`macval(s)'"'), "^#d[a-z]*[ ]*;") local semi 1
            else if regexm(lower(`"`macval(s)'"'), "^#d[a-z]*([ ]+cr)?[ ]*$") local semi 0
            local newstmt 1
            local skip 1
        }
        else {
            *-- a line that only continues the one before it starts no command
            local incont = substr(`"`macval(s)'"', -3, 3) == "///"
            if `wascont' local skip 1
            if `semi' {
                if !`newstmt' local skip 1
                local newstmt = substr(`"`macval(s)'"', -1, 1) == ";"
            }
            if substr(`"`macval(s)'"', 1, 1) == "*" local skip 1
        }

        if !`skip' {
            * strip a leading "quietly"/"capture"/"noisily" stack
            local guard 0
            while `guard' < 4 {
                gettoken w1 rest : t
                local w1l = lower(`"`macval(w1)'"')
                if inlist(`"`macval(w1l)'"', "qui", "quietly", "cap", "capture", "noi", "noisily") {
                    local t `"`macval(rest)'"'
                    local ++guard
                }
                else {
                    local guard 99
                }
            }
            gettoken cmd rest : t
            *-- "coefplot, title(...)" leaves the comma glued to the name, and
            *-- "mata:" its colon; under #delimit ; a bare command ends in ";"
            if inlist(substr(`"`macval(cmd)'"', -1, 1), ",", ":", ";") {
                local cmd = substr(`"`macval(cmd)'"', 1, length(`"`macval(cmd)'"') - 1)
            }
            local cl = lower(`"`macval(cmd)'"')
            local r1 = strtrim(`"`macval(rest)'"')
            if inlist(`"`macval(cl)'"', "mata", "python") {
                *-- alone on its line it opens a block that runs to -end-;
                *-- "mata: one statement" is a single line
                if inlist(`"`macval(r1)'"', "", ":", "{") local inblock 1
            }
            else if inlist(`"`macval(cl)'"', "program", "progra", "progr", "prog", "pro", "pr") {
                *-- remember the name the file defines so it is not reported
                gettoken n1 r2 : rest
                if inlist(lower(`"`macval(n1)'"'), "define", "defin", "defi", "def", "de") {
                    gettoken n1 r2 : r2
                }
                if substr(`"`macval(n1)'"', -1, 1) == "," {
                    local n1 = substr(`"`macval(n1)'"', 1, length(`"`macval(n1)'"') - 1)
                }
                if regexm(`"`macval(n1)'"', "^[a-zA-Z_][a-zA-Z_0-9]*$") {
                    if !inlist("`n1'", "drop", "dir", "list", "di", "l") {
                        local defined "`defined' `n1'"
                    }
                }
            }
            else if `"`macval(cl)'"' == "end" {
                *-- closes a program; not a command
            }
            * a command token is bare letters/underscore/digits
            else if regexm(`"`macval(cmd)'"', "^[a-zA-Z_][a-zA-Z_0-9]*$") {
                if !strpos(" `seen' ", " `cmd' ") {
                    local seen "`seen' `cmd'"
                    capture qui which `cmd'
                    local rc1 = _rc
                    * built-ins are not files; ask Stata if it knows the name
                    capture qui _up_isbuiltin `cmd'
                    local isb = _rc
                    if `rc1' != 0 & `isb' != 0 {
                        local miss "`miss' `cmd'"
                    }
                }
            }
        }
        file read `fh' line
    }
    file close `fh'

    *-- a program the file defines itself is not something to install
    local miss : list miss - defined
    local miss : list clean miss

    if "`miss'" == "" {
        di as text "      every command in the file resolves on this machine"
    }
    else {
        di as text "      these commands did not resolve (candidates to install):"
        foreach m of local miss {
            di as text "         " as result "`m'"
        }
        di as text "      install them with: {bf:usepackage `miss'}"
    }
    return local missing "`miss'"
    *-- probing built-ins above leaves a nonzero _rc behind; clear it so a
    *-- caller's "if _rc" does not fire on a scan that worked
    capture noisily di as text ""
end


*==========================================================================
*  _up_isbuiltin : rc 0 when Stata recognises name as a built-in command
*==========================================================================
program define _up_isbuiltin
    args name
    * a built-in has a help entry but no .ado on the adopath
    capture qui findfile `name'.ado
    if _rc == 0 exit 1
    capture qui findfile `name'.sthlp
    if _rc == 0 exit 0
    capture qui findfile `name'.hlp
    if _rc == 0 exit 0
    exit 1
end
