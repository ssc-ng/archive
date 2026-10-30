*! getref.ado v3.1 October 27,2026
*! Authors: Wu Lianghai, Wu Hanyan, Chen Liwen
*! Real Crossref literature retrieval and standards-based bibliography output
*! 鼎园会计: 科学规范，人文向善
*!
*! This version replaces simulated records with DOI-verifiable metadata.
*! It is designed for direct use with art2tex and case2tex through
*! references.bib, and writes a provenance audit file by default.

version 16

program define getref, rclass
    version 16
    syntax [anything] , SAVing(string) ///
        [Format(string) REPLACE APPend Language(string) Source(string) ///
         N(integer 10) Yearfrom(integer 2000) Yearto(integer 2026) ///
         EMAIL(string) DOI(string) SORTBY(string) TYPE(string) ///
         AUDit(string) NOAudit VERBose]

    local query `"`anything'"'
    if "`format'" == "" local format "bib"
    if "`language'" == "" local language "english"
    if "`source'" == "" local source "crossref"
    if "`type'" == "" local type "journal-article"
    local format = lower("`format'")
    local language = lower("`language'")
    local source = lower("`source'")
    local sortby = lower("`sortby'")
    local type = lower("`type'")
    local query = trim(`"`query'"')
    if substr(`"`query'"', 1, 1) == char(34) & substr(`"`query'"', length(`"`query'"'), 1) == char(34) {
        local query = substr(`"`query'"', 2, length(`"`query'"') - 2)
    }
    local doi = trim(`"`doi'"')

    if !inlist("`format'", "bib", "tex", "txt", "ris") {
        di as error "format() must be bib, tex, txt, or ris"
        di as error "docx is no longer accepted because the former demo only wrote plain text to a .docx file."
        exit 198
    }
    if !inlist("`language'", "english", "chinese") {
        di as error "language() must be english or chinese"
        exit 198
    }
    if "`source'" != "crossref" {
        di as error "Only source(crossref) provides a stable, publicly callable metadata service."
        if inlist("`source'", "cnki", "google", "semantic", "arxiv") {
            di as error "The former `source' path was simulated and has been removed."
        }
        di as error "For CNKI or other licensed collections, pass an exact DOI with doi() after verifying it."
        exit 198
    }
    if `n' < 1 | `n' > 100 {
        di as error "n() must be between 1 and 100"
        exit 198
    }
    if `yearfrom' < 1000 | `yearfrom' > 9999 | `yearto' < 1000 | `yearto' > 9999 | `yearfrom' > `yearto' {
        di as error "yearfrom() and yearto() must form a valid four-digit year range"
        exit 198
    }
    if "`append'" != "" & "`replace'" != "" {
        di as error "replace and append cannot be used together"
        exit 198
    }
    if "`audit'" != "" & lower(`"`audit'"') == lower(`"`saving'"') {
        di as error "audit() must not refer to the same file as saving()"
        exit 198
    }
    if `"`query'"' == "" & `"`doi'"' == "" {
        di as error "Provide a search query or at least one DOI in doi()."
        exit 198
    }
    if !inlist("`type'", "journal-article", "proceedings-article", "book-chapter", "book", "any") {
        di as error "type() must be journal-article, proceedings-article, book-chapter, book, or any"
        exit 198
    }
    if !inlist("`sortby'", "", "relevance", "published", "cited", "updated", "deposited") {
        di as error "sortby() must be relevance, published, cited, updated, or deposited"
        exit 198
    }

    capture confirm file `"`saving'"'
    local out_exists = (_rc == 0)
    if `out_exists' & "`replace'" == "" & "`append'" == "" {
        di as error `"File `saving' already exists. Use replace or append."'
        exit 602
    }

    local current_year = year(date(c(current_date), "DMY"))
    if `yearto' > `current_year' + 1 {
        di as text "Note: yearto(`yearto') is later than the current publication year; Crossref may return no such records."
    }

    *---------------------------------------------------------------------------
    * Resolve exact DOIs first.  Exact DOI input is the most auditable route.
    *---------------------------------------------------------------------------
    local dois ""
    local ndois = 0
    local pending `"`doi'"'
    local sep = char(31)
    local pending = ustrregexra(`"`pending'"', "[;,|][ \t]*(?=10\.)", "`sep'")
    local pending = ustrregexra(`"`pending'"', "[ \t]+(?=10\.)", "`sep'")
    while `"`pending'"' != "" {
        gettoken one pending : pending, parse("`sep'")
        local one = trim(`"`one'"')
        if `"`one'"' != "" & `"`one'"' != "`sep'" {
            if !ustrregexm(`"`one'"', "^10\.[0-9]{4,9}/.+$") {
                di as error `"Invalid DOI: `one'"'
                exit 198
            }
            if strpos(" `dois' ", " `one' ") == 0 {
                local ++ndois
                local dois "`dois' `one'"
            }
        }
    }

    *---------------------------------------------------------------------------
    * If needed, ask Crossref for DOI candidates only.  Bibliographic fields
    * are then obtained from the DOI registration record, not reconstructed
    * from search snippets.
    *---------------------------------------------------------------------------
    if `"`query'"' != "" & `ndois' < `n' {
        local qenc ""
        mata: st_local("qenc", urlencode(st_local("query")))
        local api "https://api.crossref.org/works?query.bibliographic=`qenc'&rows=`n'&select=DOI"
        local filters "from-pub-date:`yearfrom'-01-01,until-pub-date:`yearto'-12-31"
        if "`type'" != "any" local filters "`filters',type:`type'"
        local api "`api'&filter=`filters'"
        if "`sortby'" == "cited" {
            local api "`api'&sort=is-referenced-by-count&order=desc"
        }
        else if inlist("`sortby'", "published", "updated", "deposited") {
            local api "`api'&sort=`sortby'&order=desc"
        }
        if `"`email'"' != "" {
            local mailenc ""
            mata: st_local("mailenc", urlencode(st_local("email")))
            local api "`api'&mailto=`mailenc'"
        }

        tempfile jsontmp
        di as text "Searching Crossref for: `query'"
        _getref_fetch, url(`"`api'"') to(`"`jsontmp'"')
        _getref_readfile, file(`"`jsontmp'"')
        local json `"`r(content)'"'
        local json = subinstr(`"`json'"', "\/", "/", .)

        forvalues i = 1/`n' {
            local p = strpos(`"`json'"', "DOI")
            if `p' == 0 continue, break
            local json = substr(`"`json'"', `p', length(`"`json'"') - `p' + 1)
            local colon = strpos(`"`json'"', ":")
            local after_colon = substr(`"`json'"', `colon' + 1, length(`"`json'"') - `colon')
            local q1 = `colon' + strpos(`"`after_colon'"', char(34))
            local after_q1 = substr(`"`json'"', `q1' + 1, length(`"`json'"') - `q1')
            local q2 = `q1' + strpos(`"`after_q1'"', char(34))
            if `colon' == 0 | `q1' == 0 | `q2' == 0 continue, break
            local found = substr(`"`json'"', `q1' + 1, `q2' - `q1' - 1)
            local json = substr(`"`json'"', `q2' + 1, length(`"`json'"') - `q2')
            if `"`found'"' != "" & strpos(" `dois' ", " `found' ") == 0 {
                local ++ndois
                local dois "`dois' `found'"
            }
            if `ndois' >= `n' continue, break
        }
    }

    if `ndois' == 0 {
        di as error "No verified Crossref records were found."
        di as error "Broaden the query or year range, or provide exact DOIs with doi()."
        exit 603
    }
    if `ndois' > `n' {
        local dois : word 1/`n' of `dois'
        local ndois = `n'
    }

    *---------------------------------------------------------------------------
    * Write transactionally.  A failed run cannot leave a half-written final
    * bibliography in place.
    *---------------------------------------------------------------------------
    tempfile outtmp
    if "`append'" != "" & `out_exists' {
        _getref_publish, from(`"`saving'"') to(`"`outtmp'"')
    }
    else {
        tempname fh
        file open `fh' using `"`outtmp'"', write text replace
        if "`format'" != "ris" {
            file write `fh' "% getref v3.1 | Crossref-verified metadata" _n
            file write `fh' "% Dingyuan Accounting: Scientific rigor and humanistic goodwill" _n
            file write `fh' "% Generated `c(current_date)'. Verify all fields before submission." _n _n
        }
        file close `fh'
    }

    local audit_off = ("`noaudit'" != "")
    if `audit_off' {
        local auditfile ""
    }
    else if `"`audit'"' != "" {
        local auditfile `"`audit'"'
    }
    else {
        _getref_stem, file(`"`saving'"') format("`format'")
        local auditfile `"`r(stem)'_audit.csv"'
    }

    tempfile audittmp
    local audit_exists = 0
    if !`audit_off' {
        capture confirm file `"`auditfile'"'
        local audit_exists = (_rc == 0)
        if "`append'" != "" & `audit_exists' {
            _getref_publish, from(`"`auditfile'"') to(`"`audittmp'"')
        }
        else {
            tempname ah
            file open `ah' using `"`audittmp'"', write text replace
            file write `ah' "doi,citation_key,year,status,source,retrieved" _n
            file close `ah'
        }
    }

    tempname fh ah
    file open `fh' using `"`outtmp'"', write text append
    if "`append'" != "" file write `fh' _n
    if !`audit_off' file open `ah' using `"`audittmp'"', write text append

    local got = 0
    local skipped = 0
    local keys ""
    local failed ""
    forvalues i = 1/`ndois' {
        local one : word `i' of `dois'
        local skip = 0
        if "`append'" != "" & `out_exists' {
            _getref_doi_infile, doi(`"`one'"') file(`"`saving'"')
            local skip = r(found)
        }
        if `skip' {
            local ++skipped
            if "`verbose'" != "" di as text "Already present; skipped `one'"
            continue
        }

        capture noisily _getref_record, doi(`"`one'"') format("`format'") language("`language'")
        if _rc {
            local failed "`failed' `one'"
            di as error "Could not retrieve `one'; it was not added."
            continue
        }

        local content `"`r(content)'"'
        local key `"`r(key)'"'
        local year `"`r(year)'"'
        file write `fh' `"`macval(content)'"' _n _n
        if !`audit_off' {
            local akey = subinstr(`"`key'"', char(34), "", .)
            local ayear = subinstr(`"`year'"', char(34), "", .)
            file write `ah' `"`one',`akey',`ayear',verified,crossref,`c(current_date)'"' _n
        }
        local ++got
        local keys "`keys' `key'"
        if "`verbose'" != "" di as text "Verified `one' -> `key'"
    }
    file close `fh'
    if !`audit_off' file close `ah'

    if `got' == 0 {
        if `skipped' > 0 {
            di as text "All requested records are already present; no append was needed."
            return scalar n = 0
            return scalar skipped = `skipped'
            return local keys ""
            return local saving `"`saving'"'
            return local audit `"`auditfile'"'
            exit
        }
        di as error "No new verified records were written."
        if `"`failed'"' != "" {
            di as error "Failed DOIs:`failed'"
        }
        exit 603
    }

    _getref_publish, from(`"`outtmp'"') to(`"`saving'"')
    if !`audit_off' _getref_publish, from(`"`audittmp'"') to(`"`auditfile'"')

    di as text "Verified `got' Crossref record(s) written to: `saving'"
    if !`audit_off' di as text "Provenance audit written to: `auditfile'"
    if "`format'" == "bib" {
        di as text "Use r(keys) below for natbib or bibtex citation keys."
    }

    return scalar n = `got'
    return scalar skipped = `skipped'
    return local keys `"`keys'"'
    local key1 : word 1 of `keys'
    return local key "`key1'"
    return local saving `"`saving'"'
    return local audit `"`auditfile'"'
end


program define _getref_fetch
    version 16
    syntax , URL(string) TO(string) [MAXtime(integer 90)]

    local curl "curl"
    if "`c(os)'" == "Windows" local curl "curl.exe"
    local cmd `"`curl' -sS -L --fail --retry 2 --connect-timeout 20 --max-time `maxtime' -o "`to'" "`url'""'
    capture shell `cmd'

    capture confirm file `"`to'"'
    if _rc {
        di as error "Download failed: `url'"
        exit 603
    }

    tempname fh
    capture file open `fh' using `"`to'"', read
    if _rc {
        di as error "Cannot read downloaded content from `to'"
        exit 603
    }
    local first ""
    capture file read `fh' first
    local read_rc = _rc
    file close `fh'
    if `read_rc' | trim(`"`first'"') == "" {
        capture quietly erase `"`to'"'
        di as error "The server returned an empty response: `url'"
        exit 603
    }

    * Stata's text reader needs a final line break.
    file open `fh' using `"`to'"', write text append
    file write `fh' _n
    file close `fh'
end


program define _getref_publish
    version 16
    syntax , FROM(string) TO(string)
    capture confirm file `"`to'"'
    if _rc == 0 {
        capture quietly copy `"`from'"' `"`to'"', replace
    }
    else {
        capture quietly copy `"`from'"' `"`to'"'
    }
    if _rc {
        di as error `"Could not publish `from' to `to'"'
        exit _rc
    }
end


program define _getref_readfile, rclass
    version 16
    syntax , FILE(string)

    tempname fh
    file open `fh' using `"`file'"', read
    local all ""
    local line ""
    file read `fh' line
    while r(eof) == 0 {
        local all = `"`all'"' + char(10) + `"`line'"'
        file read `fh' line
    }
    file close `fh'
    return local content `"`all'"'
end


program define _getref_key, rclass
    version 16
    syntax anything(name=doi)
    local key = "doi" + ustrregexra(`"`doi'"', "[^0-9A-Za-z]+", "x")
    local key = ustrregexra("`key'", "x+", "x")
    local key = lower("`key'")
    if substr("`key'", 4, 1) == "x" {
        local key = substr("`key'", 1, 3) + substr("`key'", 5, length("`key'") - 4)
    }
    while substr("`key'", length("`key'"), 1) == "x" {
        local key = substr("`key'", 1, length("`key'") - 1)
    }
    return local key "`key'"
end


program define _getref_bibfield, rclass
    version 16
    syntax anything(name=bib) , FIELD(string)

    local bib `"`bib'"'
    local marker "`field'="
    local p = strpos(`"`bib'"', "`marker'")
    if `p' == 0 {
        return local value ""
        exit
    }
    local p = `p' + length("`marker'")
    while substr(`"`bib'"', `p', 1) == " " {
        local ++p
    }
    local open = substr(`"`bib'"', `p', 1)
    local q = char(34)
    if "`open'" == "{" {
        local ++p
        local depth = 1
        local val ""
        while `p' <= length(`"`bib'"') & `depth' > 0 {
            local ch = substr(`"`bib'"', `p', 1)
            if "`ch'" == "{" local ++depth
            else if "`ch'" == "}" {
                local --depth
                if `depth' == 0 continue, break
            }
            local val `"`val'`ch'"'
            local ++p
        }
    }
    else if "`open'" == "`q'" {
        local ++p
        local tail = substr(`"`bib'"', `p', length(`"`bib'"') - `p' + 1)
        local rel = strpos(`"`tail'"', "`q'")
        if `rel' > 0 local end = `p' + `rel' - 1
        else local end = length(`"`bib'"') + 1
        local val = substr(`"`bib'"', `p', `end' - `p')
    }
    else if "`open'" != "{" {
        local end = 0
        local tail = substr(`"`bib'"', `p', length(`"`bib'"') - `p' + 1)
        local rel = strpos(`"`tail'"', ",")
        if `rel' > 0 local end = `p' + `rel' - 1
        else {
            local rel = strpos(`"`tail'"', "}")
            if `rel' > 0 local end = `p' + `rel' - 1
        }
        if `end' == 0 local end = length(`"`bib'"') + 1
        local val = trim(substr(`"`bib'"', `p', `end' - `p'))
    }
    return local value `"`val'"'
end


program define _getref_record, rclass
    version 16
    syntax , DOI(string) FORMAT(string) LANGUAGE(string)

    if inlist("`format'", "bib", "tex") {
        local trans "application/x-bibtex"
    }
    else {
        local trans "application/x-research-info-systems"
    }
    local doienc ""
    mata: st_local("doienc", urlencode(st_local("doi")))
    local url "https://api.crossref.org/works/`doienc'/transform/`trans'"
    tempfile rawfile
    _getref_fetch, url(`"`url'"') to(`"`rawfile'"')
    _getref_readfile, file(`"`rawfile'"')
    local raw `"`r(content)'"'
    local raw = trim(`"`raw'"')
    if trim(`"`raw'"') == "" {
        di as error "Crossref returned no bibliographic metadata for `doi'"
        exit 603
    }

    _getref_key `"`doi'"'
    local key `"`r(key)'"'
    local title ""
    local year ""

    if "`format'" == "bib" {
        local bib `"`raw'"'
        local at = strpos(`"`bib'"', "@")
        local after_at = substr(`"`bib'"', `at' + 1, length(`"`bib'"') - `at')
        local openrel = strpos(`"`after_at'"', "{")
        local open = `at' + `openrel'
        if `at' == 0 | `openrel' == 0 {
            di as error "Malformed BibTeX returned for `doi'"
            exit 603
        }
        local entrytype = lower(trim(substr(`"`bib'"', `at' + 1, `open' - `at' - 1)))
        if !inlist("`entrytype'", "article", "book", "inproceedings", "incollection", ///
            "phdthesis", "mastersthesis", "techreport", "unpublished", "misc") {
            local entrytype "misc"
        }
        _getref_bibfield `"`bib'"', field(author)
        local author `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(editor)
        local editor `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(title)
        local title `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(journal)
        local journal `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(booktitle)
        local booktitle `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(year)
        local year `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(volume)
        local volume `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(number)
        local number `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(pages)
        local pages `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(publisher)
        local publisher `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(address)
        local address `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(edition)
        local edition `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(series)
        local series `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(issn)
        local issn `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(isbn)
        local isbn `"`r(value)'"'
        if "`journal'" == "" & "`booktitle'" != "" local journal `"`booktitle'"'
        local pages = subinstr(`"`pages'"', "–", "--", .)
        if strpos(`"`pages'"', "--") == 0 & strpos(`"`pages'"', "-") > 0 {
            local pages = subinstr(`"`pages'"', "-", "--", .)
        }

        local doi_bib = subinstr(`"`doi'"', "\", "", .)
        local doi_bib = subinstr(`"`doi_bib'"', "_", "\_", .)
        local doi_bib = subinstr(`"`doi_bib'"', "%", "\%", .)
        local doi_bib = subinstr(`"`doi_bib'"', "#", "\#", .)
        local doi_bib = subinstr(`"`doi_bib'"', "&", "\&", .)
        local url_bib = "https://doi.org/" + `"`doi_bib'"'

        local content = "@`entrytype'{" + "`key'" + ","
        if `"`author'"' != "" local content = `"`content'"' + char(10) + "  author = {" + `"`author'"' + "},"
        if `"`editor'"' != "" local content = `"`content'"' + char(10) + "  editor = {" + `"`editor'"' + "},"
        if `"`title'"' != "" local content = `"`content'"' + char(10) + "  title = {" + `"`title'"' + "},"
        if `"`journal'"' != "" {
            if inlist("`entrytype'", "inproceedings", "incollection") {
                local content = `"`content'"' + char(10) + "  booktitle = {" + `"`journal'"' + "},"
            }
            else {
                local content = `"`content'"' + char(10) + "  journal = {" + `"`journal'"' + "},"
            }
        }
        if `"`series'"' != "" local content = `"`content'"' + char(10) + "  series = {" + `"`series'"' + "},"
        if `"`year'"' != "" local content = `"`content'"' + char(10) + "  year = {" + `"`year'"' + "},"
        if `"`volume'"' != "" local content = `"`content'"' + char(10) + "  volume = {" + `"`volume'"' + "},"
        if `"`number'"' != "" local content = `"`content'"' + char(10) + "  number = {" + `"`number'"' + "},"
        if `"`pages'"' != "" local content = `"`content'"' + char(10) + "  pages = {" + `"`pages'"' + "},"
        if `"`edition'"' != "" local content = `"`content'"' + char(10) + "  edition = {" + `"`edition'"' + "},"
        if `"`publisher'"' != "" local content = `"`content'"' + char(10) + "  publisher = {" + `"`publisher'"' + "},"
        if `"`address'"' != "" local content = `"`content'"' + char(10) + "  address = {" + `"`address'"' + "},"
        if `"`issn'"' != "" local content = `"`content'"' + char(10) + "  issn = {" + `"`issn'"' + "},"
        if `"`isbn'"' != "" local content = `"`content'"' + char(10) + "  isbn = {" + `"`isbn'"' + "},"
        local content = `"`content'"' + char(10) + "  doi = {" + `"`doi_bib'"' + "},"
        local content = `"`content'"' + char(10) + "  url = {" + `"`url_bib'"' + "}"
        local content = `"`content'"' + char(10) + "}"
    }
    else if "`format'" == "tex" {
        local bib `"`raw'"'
        _getref_bibfield `"`bib'"', field(title)
        local title `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(author)
        local author `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(journal)
        local journal `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(year)
        local year `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(volume)
        local volume `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(number)
        local number `"`r(value)'"'
        _getref_bibfield `"`bib'"', field(pages)
        local pages `"`r(value)'"'
        local author = subinstr(`"`author'"', " and ", "; ", .)
        local pages = subinstr(`"`pages'"', "–", "--", .)
        local doi_tex = subinstr(`"`doi'"', "_", "\_", .)
        if "`language'" == "chinese" {
            local content = `"`author'. `title'[J]. "' + `"`journal'"'
            if "`year'" != "" local content = `"`content', `year'"'
            if "`volume'" != "" local content = `"`content', `volume'"'
            if "`number'" != "" local content = `"`content'(`number')"'
            if "`pages'" != "" local content = `"`content': `pages'"'
            local content = `"`content'. DOI: \texttt{`doi_tex'}."'
        }
        else {
            local content = `"`author'. (`year'). "' + `"`title'."'
            if "`journal'" != "" local content = `"`content' \textit{`journal'}"'
            if "`volume'" != "" local content = `"`content', `volume'"'
            if "`number'" != "" local content = `"`content'(`number')"'
            if "`pages'" != "" local content = `"`content', `pages'"'
            local content = `"`content'. DOI: \texttt{`doi_tex'}."'
        }
        local content = "\bibitem{`key'}" + char(10) + `"`content'"'
    }
    else if "`format'" == "ris" {
        local content `"`raw'"'
        local content = subinstr(`"`content'"', "http://dx.doi.org/", "https://doi.org/", .)
    }
    else {
        local rest `"`raw'"'
        local na = 0
        local title ""
        local journal ""
        local year ""
        local volume ""
        local number ""
        local sp ""
        local ep ""
        while `"`rest'"' != "" {
            local p = strpos(`"`rest'"', char(10))
            if `p' == 0 {
                local line `"`rest'"'
                local rest ""
            }
            else {
                local line = substr(`"`rest'"', 1, `p' - 1)
                local rest = substr(`"`rest'"', `p' + 1, length(`"`rest'"') - `p')
            }
            local line = subinstr(`"`line'"', char(13), "", .)
            if length(trim(`"`line'"')) < 7 continue
            local tag = substr(`"`line'"', 1, 2)
            local val = trim(substr(`"`line'"', 7, length(`"`line'"') - 6))
            if "`tag'" == "AU" {
                if `"`val'"' != "" {
                    local ++na
                    local au`na' `"`val'"'
                }
            }
            else if inlist("`tag'", "TI", "T1") local title `"`val'"'
            else if inlist("`tag'", "T2", "JO", "JF") local journal `"`val'"'
            else if "`tag'" == "PY" local year `"`val'"'
            else if "`tag'" == "VL" local volume `"`val'"'
            else if "`tag'" == "IS" local number `"`val'"'
            else if "`tag'" == "SP" local sp `"`val'"'
            else if "`tag'" == "EP" local ep `"`val'"'
        }

        forvalues j = 1/`na' {
            local a `"`au`j''"'
            local comma = strpos(`"`a'"', ",")
            if `comma' > 0 {
                local family = trim(substr(`"`a'"', 1, `comma' - 1))
                local given = trim(substr(`"`a'"', `comma' + 1, length(`"`a'"') - `comma'))
                if ustrregexm(`"`given'"', "^[A-Za-z][A-Za-z .-]*$") {
                    local initials ""
                    forvalues k = 1/`=wordcount("`given'")' {
                        local w : word `k' of `given'
                        local initials "`initials' `=substr("`w'", 1, 1)'."
                    }
                    local au`j' "`family',`initials'"
                }
            }
        }
        local authors ""
        if `na' == 0 local authors "Anon."
        else if `na' == 1 local authors `"`au1'"'
        else {
            forvalues j = 1/`=`na' - 1' {
                if `j' == 1 local authors `"`au`j''"'
                else local authors `"`authors', `au`j''"'
            }
            local authors `"`authors', & `au`na''"'
        }
        local authors = ustrregexra(`"`authors'"', "\.$", "")
        local pages ""
        if `"`sp'"' != "" & `"`ep'"' != "" local pages "`sp'--`ep'"
        else if `"`sp'"' != "" local pages `"`sp'"'

        local title = subinstr(`"`title'"', "–", "-", .)
        if "`language'" == "chinese" {
            local content = `"`authors'. "' + `"`title'[J]. "'
            if "`journal'" != "" local content = `"`content'`journal'"'
            if "`year'" != "" local content = `"`content', `year'"'
            if "`volume'" != "" local content = `"`content', `volume'"'
            if "`number'" != "" local content = `"`content'(`number')"'
            if "`pages'" != "" local content = `"`content': `pages'"'
            local content = `"`content'. DOI: `doi'."'
        }
        else {
            local content = `"`authors'. (`year'). `title'. "'
            if "`journal'" != "" local content = `"`content'`journal'"'
            if "`volume'" != "" local content = `"`content', `volume'"'
            if "`number'" != "" local content = `"`content'(`number')"'
            if "`pages'" != "" local content = `"`content', `pages'"'
            local content = `"`content'. https://doi.org/`doi'"'
        }
    }

    return local content `"`content'"'
    return local key `"`key'"'
    return local title `"`title'"'
    return local year `"`year'"'
end


program define _getref_stem, rclass
    version 16
    syntax , FILE(string) FORMAT(string)
    local stem = ustrregexra(`"`file'"', "\.[^./\\]+$", "")
    if `"`stem'"' == `"`file'"' & "`format'" != "" {
        local stem = subinstr(`"`file'"', ".`format'", "", 1)
    }
    return local stem `"`stem'"'
end


program define _getref_doi_infile, rclass
    version 16
    syntax , DOI(string) FILE(string)
    tempname fh
    capture file open `fh' using `"`file'"', read
    if _rc {
        return scalar found = 0
        exit
    }
    local line ""
    local found = 0
    local doi_escaped = `"`doi'"'
    local doi_escaped = subinstr(`"`doi_escaped'"', "#", "\#", .)
    local doi_escaped = subinstr(`"`doi_escaped'"', "%", "\%", .)
    local doi_escaped = subinstr(`"`doi_escaped'"', "&", "\&", .)
    local doi_escaped = subinstr(`"`doi_escaped'"', "_", "\_", .)
    file read `fh' line
    while r(eof) == 0 {
        if strpos(`"`line'"', `"`doi'"') > 0 | ///
            strpos(`"`line'"', `"`doi_escaped'"') > 0 {
            local found = 1
            continue, break
        }
        file read `fh' line
    }
    file close `fh'
    return scalar found = `found'
end
