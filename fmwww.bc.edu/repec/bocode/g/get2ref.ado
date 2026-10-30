*! get2ref.ado v4.1 October 27,2026
*! Authors: Wu Lianghai, Chen Liwen, Wu Hanyan
*! Verification-first batch bibliography builder for art2tex and case2tex
*! 鼎园会计: 科学规范，人文向善
*!
*! get2ref is the batch companion to getref.  It accepts a search query,
*! explicit DOIs, or a DOI list file, then delegates retrieval to getref's
*! live Crossref verification and transactional writer.

version 16

program define get2ref, rclass
    version 16
    syntax [anything] , SAVing(string) ///
        [Format(string) REPLACE APPend Language(string) Source(string) ///
         N(integer 10) Yearfrom(integer 2000) Yearto(integer 2026) ///
         EMAIL(string) DOI(string) DOIfile(string) SORTBY(string) ///
         TYPE(string) AUDit(string) NOAudit VERBose]

    if "`format'" == "" local format "bib"
    if "`language'" == "" local language "english"
    if "`source'" == "" local source "crossref"
    local query `"`anything'"'
    local format = lower("`format'")
    local language = lower("`language'")
    local source = lower("`source'")
    local query = trim(`"`query'"')
    if substr(`"`query'"', 1, 1) == char(34) & substr(`"`query'"', length(`"`query'"'), 1) == char(34) {
        local query = substr(`"`query'"', 2, length(`"`query'"') - 2)
    }

    if "`source'" != "crossref" {
        di as error "get2ref supports source(crossref) for verified public metadata."
        di as error "The former cnki/google/semantic/arxiv paths were simulations and are removed."
        di as error "Put licensed-database DOIs in doi() or doifile() only after verifying them."
        exit 198
    }
    if `n' < 1 | `n' > 100 {
        di as error "n() must be between 1 and 100"
        exit 198
    }
    if "`append'" != "" & "`replace'" != "" {
        di as error "replace and append cannot be used together"
        exit 198
    }

    capture which getref
    if _rc {
        di as error "getref is required. Install or update getref and get2ref together."
        exit 111
    }

    * Collect exact DOI input before the query is sent to Crossref.
    local dois `"`doi'"'
    if `"`doifile'"' != "" {
        capture confirm file `"`doifile'"'
        if _rc {
            di as error `"DOI list file not found: `doifile'"'
            exit 601
        }
        _get2ref_readdois, file(`"`doifile'"')
        local fromfile `"`r(dois)'"'
        if `"`fromfile'"' != "" {
            if `"`dois'"' == "" local dois `"`fromfile'"'
            else local dois `"`dois'|`fromfile'"'
        }
        local n_in_file = r(n)
    }
    else {
        local n_in_file = 0
    }

    if `"`query'"' == "" & `"`dois'"' == "" {
        di as error "Provide a query, doi(), or doifile()."
        exit 198
    }

    * Build one auditable call to the verified core.  The explicit DOI list
    * takes precedence and the query only fills the remaining n() slots.
    local opts `"saving(`"`saving'"') format("`format'") language("`language'") source(crossref)"'
    local opts `"`opts' n(`n') yearfrom(`yearfrom') yearto(`yearto')"'
    if "`replace'" != "" local opts `"`opts' replace"'
    if "`append'" != "" local opts `"`opts' append"'
    if `"`email'"' != "" local opts `"`opts' email(`"`email'"')"'
    if `"`dois'"' != "" local opts `"`opts' doi(`"`dois'"')"'
    if `"`sortby'"' != "" local opts `"`opts' sortby("`sortby'")"'
    if `"`type'"' != "" local opts `"`opts' type("`type'")"'
    if `"`audit'"' != "" local opts `"`opts' audit(`"`audit'"')"'
    if "`noaudit'" != "" local opts `"`opts' noaudit"'
    if "`verbose'" != "" local opts `"`opts' verbose"'

    getref "`query'", `opts'

    local nret = r(n)
    local keys `"`r(keys)'"'
    local key `"`r(key)'"'
    local saved `"`r(saving)'"'
    local auditpath `"`r(audit)'"'
    local skipped = r(skipped)

    * Keep the source label accurate even for appends to files written by an
    * earlier version.
    _get2ref_relabel, file(`"`saved'"') label("get2ref v4.1")

    return scalar n = `nret'
    return scalar skipped = `skipped'
    return local keys `"`keys'"'
    return local key `"`key'"'
    return local saving `"`saved'"'
    return local audit `"`auditpath'"'
    return scalar n_doi_file = `n_in_file'
    return local route "crossref-verified"
end


program define _get2ref_relabel, rclass
    version 16
    syntax , FILE(string) LABel(string)

    capture confirm file `"`file'"'
    if _rc {
        return scalar changed = 0
        exit
    }

    tempfile relabeltmp
    tempname fh gh
    local changed = 0
    local first = 1
    local line ""

    file open `fh' using `"`file'"', read text
    file open `gh' using `"`relabeltmp'"', write text replace
    file read `fh' line
    while r(eof) == 0 {
        if `first' {
            local first = 0
            if ustrregexm(`"`line'"', "^% (getref|get2ref) v[^|]+\| Crossref-verified metadata$") {
                file write `gh' "% `label' | Crossref-verified metadata" _n
                local changed = 1
            }
            else {
                file write `gh' `"`macval(line)'"' _n
            }
        }
        else {
            file write `gh' `"`macval(line)'"' _n
        }
        file read `fh' line
    }
    file close `fh'
    file close `gh'

    if `changed' {
        capture quietly copy `"`relabeltmp'"' `"`file'"', replace
        if _rc {
            di as error `"Could not update the source label in `file'"'
            exit _rc
        }
    }

    return scalar changed = `changed'
end


program define _get2ref_readdois, rclass
    version 16
    syntax , FILE(string)

    tempname fh
    file open `fh' using `"`file'"', read
    local line ""
    local dois ""
    local n = 0
    local iscsv = 0
    if length(`"`file'"') >= 4 & substr(lower(`"`file'"'), length(`"`file'"') - 3, 4) == ".csv" local iscsv = 1
    file read `fh' line
    while r(eof) == 0 {
        local line = trim(`"`line'"')
        local line = subinstr("`line'", char(13), "", .)
        if `"`line'"' != "" & substr(`"`line'"', 1, 1) != "#" {
            local one ""
            local lowerline = lower(`"`line'"')
            if substr(`"`lowerline'"', 1, 4) == "doi:" {
                local one = trim(substr(`"`line'"', 5, length(`"`line'"') - 4))
            }
            else if strpos("`lowerline'", "https://doi.org/") {
                local pos = strpos("`lowerline'", "https://doi.org/") + 16
                local one = trim(substr(`"`line'"', `pos', length(`"`line'"') - `pos' + 1))
            }
            else if strpos("`lowerline'", "http://dx.doi.org/") {
                local pos = strpos("`lowerline'", "http://dx.doi.org/") + 18
                local one = trim(substr(`"`line'"', `pos', length(`"`line'"') - `pos' + 1))
            }
            else if substr(`"`line'"', 1, 3) == "10." {
                local one `"`line'"'
            }

            if `"`one'"' != "" {
                if `iscsv' {
                    local comma = strpos(`"`one'"', ",")
                    if `comma' > 0 local one = substr(`"`one'"', 1, `comma' - 1)
                }
                local space = strpos(`"`one'"', " ")
                if `space' > 0 local one = substr(`"`one'"', 1, `space' - 1)
                local tab = strpos(`"`one'"', char(9))
                if `tab' > 0 local one = substr(`"`one'"', 1, `tab' - 1)
                local one = ustrregexra(`"`one'"', "\.$", "")
            }
            else if ustrregexm(`"`line'"', "10\.[0-9]{4,9}/[^[:space:],;]+") {
                local one = ustrregexs(0)
                local one = ustrregexra(`"`one'"', "\.$", "")
            }

            if `"`one'"' != "" & ustrregexm(`"`one'"', "^10\.[0-9]{4,9}/.+$") {
                if strpos(" `dois' ", " `one' ") == 0 {
                    local ++n
                    if `"`dois'"' == "" local dois `"`one'"'
                    else local dois `"`dois'|`one'"'
                }
            }
        }
        file read `fh' line
    }
    file close `fh'

    local dois = trim(`"`dois'"')
    return local dois `"`dois'"'
    return scalar n = `n'
end
