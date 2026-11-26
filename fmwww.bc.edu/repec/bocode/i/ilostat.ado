*! ilostat 1.0.0 19nov2026
program define ilostat
    version 16.0
    gettoken subcmd 0 : 0, parse(" ,")
    if lower("`subcmd'") == "get" {
        ilostat_get `0'
        exit
    }
    if lower("`subcmd'") == "toc" {
        ilostat_toc `0'
        exit
    }
    if lower("`subcmd'") == "metadata" {
        ilostat_metadata `0'
        exit
    }
    if lower("`subcmd'") == "datasetdic" {
        ilostat_datasetdic `0'
        exit
    }
    if lower("`subcmd'") == "dic" {
        ilostat_dic `0'
        exit
    }
    if lower("`subcmd'") == "dimensions" {
        ilostat_dimensions `0'
        exit
    }
    if lower("`subcmd'") == "info" {
        ilostat_info `0'
        exit
    }
    di as error "Unknown ilostat subcommand: `subcmd'. Supported: get, toc, metadata, dic, datasetdic, dimensions, info"
    exit 198
end

* Dataset-specific dictionaries from the lightweight Gateway endpoint.
* Only codes available for the selected dataset are returned by the API.
program define ilostat_datasetdic
    version 16.0
    syntax anything(name=id) , VAR(string) [BY(string) LANG(string) CODE(string) MATCH(string) CLEAR]

    local id = upper(strtrim(`"`id'"'))
    if !regexm(`"`id'"', "^[A-Z0-9_]+$") {
        di as error "datasetdic requires one dataset identifier (letters, digits, underscores)"
        exit 198
    }
    local dimension = lower(strtrim(`"`var'"'))
    if !regexm(`"`dimension'"', "^[a-z][a-z0-9_]*$") {
        di as error "var() requires a classification variable name"
        exit 198
    }
    local language = lower(strtrim(`"`lang'"'))
    if `"`language'"' == "" local language "en"
    if !inlist(`"`language'"', "en", "fr", "es") {
        di as error "lang() must be en, fr or es"
        exit 198
    }
    local matching = lower(strtrim(`"`match'"'))
    if `"`matching'"' == "" local matching "contains"
    if !inlist(`"`matching'"', "contains", "exact") {
        di as error "match() must be contains or exact"
        exit 198
    }
    local route = lower(strtrim(`"`by'"'))
    if `"`route'"' == "" {
        if regexm(`"`id'"', "^[A-Z][A-Z][A-Z]_[AMQ]$") local route "ref_area"
        else local route "indicator"
    }
    if !inlist(`"`route'"', "indicator", "ref_area") {
        di as error "by() must be indicator or ref_area"
        exit 198
    }
    local searchcode = strtrim(`"`code'"')
    if `"`searchcode'"' != "" {
        if !regexm(`"`searchcode'"', "^[A-Za-z0-9_:-]+$") {
            di as error "code() contains unsupported URL characters"
            exit 198
        }
    }
    if `"`clear'"' == "" & c(k) > 0 {
        di as error "Data are in memory; specify clear to replace them"
        exit 4
    }

    local url "https://rplumber.ilo.org/metadata/dataset?id=`id'&segment=`route'&var=`dimension'&lang=`language'"
    if `"`searchcode'"' != "" local url `"`url'&code=`searchcode'&match=`matching'"'
    local url `"`url'&format=.dta&channel=ilostat-stata"'
    tempfile payload
    local file `"`payload'.dta"'
    capture quietly copy `"`url'"' `"`file'"', replace
    local rc = _rc
    if `rc' {
        di as error "ILOSTAT dataset dictionary download failed (rc=`rc')"
        exit `rc'
    }
    capture quietly use `"`file'"', clear
    local rc = _rc
    if `rc' {
        di as error "Dataset dictionary response is not readable DTA (rc=`rc')"
        exit `rc'
    }
    capture confirm variable code
    if _rc {
        di as error "ILOSTAT dataset dictionary response lacks code variable"
        exit 459
    }
    capture confirm variable label
    if _rc {
        di as error "ILOSTAT dataset dictionary response lacks label variable"
        exit 459
    }
    char _dta[ilostat_url] `"`url'"'
    char _dta[ilostat_route] "metadata/dataset"
    char _dta[ilostat_id] "`id'"
    char _dta[ilostat_segment] "`route'"
    char _dta[ilostat_lang] "`language'"
	char _dta[ilostat_version] "1.0.0"
    char _dta[ilostat_retrieved] "`c(current_date)' `c(current_time)'"
    di as result "ILOSTAT: dataset dictionary `id' / `dimension' contains " %12.0fc _N " codes"
end

* General dictionaries: /metadata/dic uses var= to select a dictionary.
program define ilostat_dic
    version 16.0
    syntax anything(name=dic_id) [, LANG(string) CLEAR]
    local dic_id = strtrim(`"`dic_id'"')
    if !regexm(`"`dic_id'"', "^[A-Za-z0-9_]+$") {
        di as error "dic requires one dictionary identifier"
        exit 198
    }
    local language = lower(strtrim(`"`lang'"'))
    if `"`language'"' == "" local language "en"
    if !inlist(`"`language'"', "en", "fr", "es") {
        di as error "lang() must be en, fr or es"
        exit 198
    }
    if `"`clear'"' == "" & c(k) > 0 {
        di as error "Data are in memory; specify clear to replace them"
        exit 4
    }
    local url "https://rplumber.ilo.org/metadata/dic?var=`dic_id'&lang=`language'&format=.dta&channel=ilostat-stata"
    tempfile payload
    local file `"`payload'.dta"'
    capture quietly copy `"`url'"' `"`file'"', replace
    local rc = _rc
    if `rc' {
        di as error "ILOSTAT dictionary download failed (rc=`rc'); verify endpoint parameters"
        exit `rc'
    }
    capture quietly use `"`file'"', clear
    local rc = _rc
    if `rc' {
        di as error "Dictionary response is not readable DTA (rc=`rc'); check API format support"
        exit `rc'
    }
    * A successful download is not enough: reject mismatched dictionaries.
    capture confirm variable `dic_id'
    if _rc {
        di as error "ILOSTAT: dictionary response does not contain `dic_id'; check API selector"
        exit 459
    }
    char _dta[ilostat_url] `"`url'"'
    char _dta[ilostat_route] "metadata/dic"
    char _dta[ilostat_lang] "`language'"
    di as result "ILOSTAT: dictionary `dic_id' contains " %12.0fc _N " observations"
end

* ILOSTAT catalogues. The two segments may have different schemas.
program define ilostat_toc
    version 16.0
    syntax [, BY(string) LANG(string) INDicator(string asis) REF_area(string asis) LABel(string asis) FREQ(string) SUBJect(string asis) CLASSification(string asis) CLEAR]

    local route = lower(strtrim(`"`by'"'))
    if `"`route'"' == "" local route "indicator"
    if !inlist(`"`route'"', "indicator", "ref_area") {
        di as error "by() must be indicator or ref_area"
        exit 198
    }
    local language = lower(strtrim(`"`lang'"'))
    if `"`language'"' == "" local language "en"
    if !inlist(`"`language'"', "en", "fr", "es") {
        di as error "lang() must be en, fr or es"
        exit 198
    }
    if `"`clear'"' == "" & c(k) > 0 {
        di as error "Data are in memory; specify clear to replace them"
        exit 4
    }

    local url "https://rplumber.ilo.org/metadata/toc/`route'?lang=`language'&format=.dta&channel=ilostat-stata"
    tempfile payload
    local file `"`payload'.dta"'
    capture noisily copy `"`url'"' `"`file'"', replace
    local rc = _rc
    if `rc' {
        di as error "ILOSTAT TOC download failed (Stata return code `rc')"
        exit `rc'
    }
    capture noisily use `"`file'"', clear
    local rc = _rc
    if `rc' {
        di as error "ILOSTAT TOC could not be opened as DTA (Stata return code `rc')"
        exit `rc'
    }

    * Filters apply to available catalogue fields, never inferred columns.
    foreach dim in indicator ref_area subject classification {
        local term `"``dim''"'
        if `"`term'"' != "" {
            capture confirm string variable `dim'
            if _rc {
                di as error "The `route' catalogue has no string variable `dim'"
                exit 111
            }
            local term = subinstr(`"`term'"', char(34), "", .)
            quietly keep if strpos(ustrlower(`dim'), ustrlower(`"`term'"')) > 0
        }
    }
    if `"`label'"' != "" {
        local labelvar "`route'_label"
        capture confirm string variable `labelvar'
        if _rc {
            di as error "The `route' catalogue has no string variable `labelvar'"
            exit 111
        }
        * Stata syntax may retain quotes in string asis option values.
        local needle = subinstr(`"`label'"', char(34), "", .)
        local needle = strtrim(`"`needle'"')
        quietly keep if strpos(ustrlower(`labelvar'), ustrlower(`"`needle'"')) > 0
    }
    if `"`freq'"' != "" {
        capture confirm string variable freq
        if _rc {
            di as error "The `route' catalogue has no string variable freq"
            exit 111
        }
        quietly keep if ustrupper(freq) == ustrupper(`"`freq'"')
    }
    char _dta[ilostat_url] `"`url'"'
    char _dta[ilostat_route] "toc/`route'"
    char _dta[ilostat_lang] "`language'"
    di as result "ILOSTAT: `route' catalogue contains " %12.0fc _N " datasets"
end

* Catalogue-level metadata summary. Not the full JSON metadata resource.
program define ilostat_metadata
    version 16.0
    syntax anything(name=id) [, BY(string) LANG(string) CLEAR]

    local id = strtrim(`"`id'"')
    if !regexm(upper(`"`id'"'), "^[A-Z0-9_]+$") {
        di as error "metadata requires one valid dataset identifier"
        exit 198
    }
    local route = lower(strtrim(`"`by'"'))
    if `"`route'"' == "" {
        if regexm(upper(`"`id'"'), "^[A-Z][A-Z][A-Z]_[AMQ]$") local route "ref_area"
        else local route "indicator"
    }
    if !inlist(`"`route'"', "indicator", "ref_area") {
        di as error "by() must be indicator or ref_area"
        exit 198
    }
    local language = lower(strtrim(`"`lang'"'))
    if `"`language'"' == "" local language "en"
    if !inlist(`"`language'"', "en", "fr", "es") {
        di as error "lang() must be en, fr or es"
        exit 198
    }
    if `"`clear'"' == "" & c(k) > 0 {
        di as error "Data are in memory; specify clear to replace them"
        exit 4
    }

    quietly ilostat_toc, by(`route') lang(`language') clear
    capture confirm string variable id
    if _rc {
        di as error "The catalogue does not contain a string id variable"
        exit 111
    }
    quietly keep if id == `"`id'"'
    if _N == 0 {
        di as error "Dataset `id' not found in the `route' catalogue"
        exit 111
    }
    char _dta[ilostat_route] "metadata/toc/`route'"
    char _dta[ilostat_metadata_scope] "catalogue_summary"
    di as result "ILOSTAT: catalogue metadata for `id' (`route', `language')"
    list, noobs abbreviate(24)
end

program define ilostat_get
    version 16.0
    syntax anything(name=id) [, BY(string) INDicator(string asis) REF_area(string asis) SEX(string asis) CLASSif1(string asis) CLASSif2(string asis) REF_area_label(string asis) SEX_label(string asis) CLASSif1_label(string asis) CLASSif2_label(string asis) INDicator_label(string asis) TIMEFROM(string) TIMETO(string) TYPE(string) FORMAT(string) CLEAR]

    local id = strtrim(`"`id'"')
    if strpos(`"`id'"', " ") | strpos(`"`id'"', "&") | strpos(`"`id'"', "?") {
        di as error "Provide exactly one dataset identifier without URL metacharacters"
        exit 198
    }
    local route = lower(strtrim(`"`by'"'))
    * Conservative automatic selection for documented country-frequency IDs.
    * Other IDs retain indicator as the default; by() overrides detection.
    if `"`route'"' == "" {
        if regexm(upper(`"`id'"'), "^[A-Z][A-Z][A-Z]_[AMQ]$") local route "ref_area"
        else local route "indicator"
    }
    if !inlist(`"`route'"', "indicator", "ref_area") {
        di as error "by() must be indicator or ref_area"
        exit 198
    }
    local fmt = lower(strtrim(`"`format'"'))
    if `"`fmt'"' == "" local fmt "dta"
    if !inlist(`"`fmt'"', "dta", "csv") {
        di as error "format() must be dta or csv"
        exit 198
    }
    local typ = lower(strtrim(`"`type'"'))
    if `"`typ'"' == "" local typ "code"
    if !inlist(`"`typ'"', "code", "both", "label") {
        di as error "type() must be code, both or label"
        exit 198
    }
    if `"`clear'"' == "" & c(k) > 0 {
        di as error "Data are in memory; specify clear to replace them"
        exit 4
    }

    local labels_requested 0
    foreach dim in ref_area sex classif1 classif2 indicator {
        if `"``dim'_label'"' != "" local labels_requested 1
    }
    if `labels_requested' & "`typ'" == "code" {
        local typ "both"
        di as text "ILOSTAT: requesting type(both) for label filtering"
    }
    local url "https://rplumber.ilo.org/data/`route'?id=`id'"
    foreach key in indicator ref_area sex classif1 classif2 {
        local value `"``key''"'
        if `"`value'"' != "" {
            // Space-separated API values are encoded as +; this is verified
            // for indicator() on /data/ref_area, other parameters need tests.
            local value = strtrim(`"`value'"')
            local value : subinstr local value " " "+", all
            if strpos(`"`value'"', "&") | strpos(`"`value'"', "?") | strpos(`"`value'"', "#") {
                di as error "Unsupported URL character in `key'(); use classification codes"
                exit 198
            }
            local url `"`url'&`key'=`value'"'
        }
    }
    foreach key in timefrom timeto {
        local value `"``key''"'
        if `"`value'"' != "" {
            if strlen(`"`value'"') != 4 | !regexm(`"`value'"', "^[0-9][0-9][0-9][0-9]$") {
                di as error "`key'() requires a four-digit year"
                exit 198
            }
            local url `"`url'&`key'=`value'"'
        }
    }
    local url `"`url'&type=`typ'&format=.`fmt'&channel=ilostat-stata"'
    * Native Stata download only. No cache, curl or extra HTTP request.
    tempfile payload
    local file `"`payload'"'
    capture quietly copy `"`url'"' `"`file'"', replace
    local rc = _rc
    if `rc' {
        di as error "ILOSTAT download failed (Stata return code `rc')"
        exit `rc'
    }
    if "`fmt'" == "dta" {
        capture noisily use `"`file'"', clear
    }
    else {
        capture noisily import delimited using `"`file'"', clear varnames(1) encoding("UTF-8")
    }
    if _rc {
        di as error "ILOSTAT response could not be loaded as `fmt'. Check the API response and parameters."
        exit _rc
    }
    // Apply label filters locally: OR within each dimension, AND across.
    // tokenize respects quoted phrases, including labels containing spaces.
    foreach dim in ref_area sex classif1 classif2 indicator {
        local terms `"``dim'_label'"'
        if `"`terms'"' != "" {
            capture confirm variable `dim'_label
            if _rc {
                di as error "Requested `dim'_label() but response has no `dim'_label variable"
                exit 111
            }
            tempvar matched
            quietly generate byte `matched' = 0
            // Parse comma-separated quoted labels without splitting commas
            // inside quotes. Single-label and legacy space-separated forms
            // are also accepted for backward compatibility.
            mata: _ilostat_split_labels()
            if `"`ilostat_parse_error'"' != "" {
                di as error "`ilostat_parse_error'"
                exit 198
            }
            forvalues j = 1/`ilostat_nterms' {
                local term `"`ilostat_term_`j''"'
                quietly replace `matched' = 1 if !missing(`dim'_label) & ///
                    strpos(ustrlower(`dim'_label), ustrlower(`"`term'"')) > 0
            }
            quietly count if `matched'
            di as text "ILOSTAT: `dim'_label() matched " as result %12.0fc r(N) as text " observations before filtering"
            quietly keep if `matched'
            drop `matched'
        }
    }
    // Stata usually normalizes dots in CSV headers to underscores.
    // Preserve names already normalized by either the API or Stata.
    char _dta[ilostat_type] "`typ'"
    char _dta[ilostat_format] "`fmt'"
    char _dta[ilostat_url] `"`url'"'
    char _dta[ilostat_route] "`route'"
    * Provenance: no extra API requests and no persistent cache.
    char _dta[ilostat_id] "`id'"
    char _dta[ilostat_segment] "`route'"
    char _dta[ilostat_lang] "en"
    char _dta[ilostat_retrieved] "`c(current_date)' `c(current_time)'"
    char _dta[ilostat_version] "0.9.2-rc"
    * Source update is available separately via ilostat metadata.
    char _dta[ilostat_last_update] ""
    di as result "ILOSTAT: loaded " %12.0fc _N " observations from /data/`route'"
end

* Display provenance attached to the currently loaded Stata dataset.
program define ilostat_info
    version 16.0
    syntax
    local id : char _dta[ilostat_id]
    if `"`id'"' == "" {
        di as error "No ilostat get provenance found in the current dataset"
        exit 459
    }
    foreach field in id segment type lang format retrieved version url {
        local value : char _dta[ilostat_`field']
        if `"`value'"' != "" di as text "`field': " as result `"`value'"'
    }
    local update : char _dta[ilostat_last_update]
    if `"`update'"' != "" di as text "last_update: " as result `"`update'"'
    else di as text "last_update: not attached; use ilostat metadata for source update"
end

* Inspect actual columns; do not infer dimensions from the indicator name.
program define ilostat_dimensions
    version 16.0
    syntax
    if c(k) == 0 {
        di as error "No data in memory. Run ilostat get first."
        exit 2000
    }
    foreach dim in ref_area indicator sex classif1 classif2 {
        capture confirm variable `dim'
        if !_rc {
            di as text "`dim'" _continue
            capture confirm variable `dim'_label
            if !_rc di as result "  [label: `dim'_label]"
            else di as text "  [codes only]"
        }
    }
    capture confirm variable time
    if !_rc di as text "time available"
end

// Quote-aware parser for label option values. Reads local macro "terms"
// and sets local ilostat_term_1 ... ilostat_term_N in the caller's scope.
// Commas inside matching single/double quotes are literal characters.
mata
void _ilostat_split_labels()
{
    string scalar s, token, q, ch, err
    real scalar i, n, inquote, commas
    s = strtrim(st_local("terms"))
    token = ""
    q = ""
    n = 0
    commas = 0
    err = ""
    for (i=1; i<=strlen(s); i++) {
        ch = substr(s,i,1)
        if (q != "") {
            if (ch == q) q = ""
            else token = token + ch
        }
        else if (ch == char(34) | ch == char(39)) q = ch
        else if (ch == ",") {
            commas = 1
            token = strtrim(token)
            if (token == "") {
                err = "Empty label in label filter"
                break
            }
            n++
            st_local("ilostat_term_" + strofreal(n), token)
            token = ""
        }
        else token = token + ch
    }
    if (q != "") err = "Unclosed quote in label filter"
    token = strtrim(token)
    if (err == "" & token == "") err = "Empty label in label filter"
    if (err == "") {
        n++
        st_local("ilostat_term_" + strofreal(n), token)
    }
    st_local("ilostat_parse_error", err)
    st_local("ilostat_nterms", strofreal(n))
}
end
