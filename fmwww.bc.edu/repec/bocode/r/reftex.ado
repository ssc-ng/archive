*! reftex.ado v10.0 October 28, 2026
*! Authors: Wu Lianghai, Wu Hanyan, Chen Liwen
*! Convert CNKI-style plain-text references to LaTeX or BibTeX
*! 鼎园会计: 科学规范，人文向善
*!
*! v10.0 adds deterministic deduplication, safe LaTeX escaping, stable
*! citation keys, BibTeX output, atomic writes, and return values.

version 16

capture program drop _reftex_escape
capture program drop _reftex_core
capture program drop reftex
capture program drop convert_bibliography
capture program drop process_entry
capture program drop process_english_entry
capture program drop escape_latex


program define _reftex_escape, rclass
    version 16
    args str

    local out `"`str'"'
    if `"`out'"' == "" {
        return local escaped ""
        exit
    }

    * Use control-character placeholders so newly inserted LaTeX commands
    * are not escaped again.
    local slash = char(1)
    local lbrace = char(2)
    local rbrace = char(3)
    local tilde = char(4)
    local caret = char(5)

    local out = ustrregexra(`"`out'"', "\s+", " ")
    local out = subinstr(`"`out'"', "–", "--", .)
    local out = subinstr(`"`out'"', "—", "---", .)
    local out = subinstr(`"`out'"', "\", "`slash'", .)
    local out = subinstr(`"`out'"', "{", "`lbrace'", .)
    local out = subinstr(`"`out'"', "}", "`rbrace'", .)
    local out = subinstr(`"`out'"', "~", "`tilde'", .)
    local out = subinstr(`"`out'"', "^", "`caret'", .)

    local out = subinstr(`"`out'"', "&", "\&", .)
    local out = subinstr(`"`out'"', "%", "\%", .)
    local out = subinstr(`"`out'"', "$", "\$", .)
    local out = subinstr(`"`out'"', "#", "\#", .)
    local out = subinstr(`"`out'"', "_", "\_", .)

    local out = subinstr(`"`out'"', "`slash'", "\textbackslash{}", .)
    local out = subinstr(`"`out'"', "`lbrace'", "\{", .)
    local out = subinstr(`"`out'"', "`rbrace'", "\}", .)
    local out = subinstr(`"`out'"', "`tilde'", "\textasciitilde{}", .)
    local out = subinstr(`"`out'"', "`caret'", "\textasciicircum{}", .)
    local out = subinstr(`"`out'"', "@@REFDOLLAR@@", "\char36{}", .)

    return local escaped `"`out'"'
end


program define reftex, rclass
    version 16
    syntax using/, [OUTfile(string) SAVing(string) FORMat(string) ///
        LANG(string) REPLACE NODEDUPE NOESCAPE DEBug]

    local infile `"`using'"'
    capture confirm file `"`infile'"'
    if _rc {
        di as error `"Input file not found: `infile'"'
        exit 601
    }

    if `"`outfile'"' == "" local outfile `"`saving'"'
    if `"`saving'"' == "" local saving `"`outfile'"'
    if `"`outfile'"' == "" {
        di as error "Specify outfile(filename) or saving(filename)."
        exit 198
    }
    if `"`outfile'"' != `"`saving'"' {
        di as error "outfile() and saving() must refer to the same file."
        exit 198
    }

    if "`lang'" == "" local lang "chn"
    local lang = lower("`lang'")
    if !inlist("`lang'", "chn", "eng", "mix") {
        di as error "lang() must be chn, eng, or mix."
        exit 198
    }

    if "`format'" == "" {
        local ext = lower(substr(`"`outfile'"', -4, 4))
        if "`ext'" == ".bib" local format "bib"
        else local format "tex"
    }
    local format = lower("`format'")
    if !inlist("`format'", "tex", "bib") {
        di as error "format() must be tex or bib."
        exit 198
    }

    capture confirm file `"`outfile'"'
    local out_exists = (_rc == 0)
    if `out_exists' & "`replace'" == "" {
        di as error `"File `outfile' already exists. Use replace to overwrite it."'
        exit 602
    }

    preserve
    capture noisily _reftex_core, infile(`"`infile'"') outfile(`"`outfile'"') ///
        format("`format'") lang("`lang'") ///
        `replace' `nodedupe' `noescape' `debug'
    local rc = _rc
    local n_input = r(n_input)
    local n_written = r(n)
    local n_duplicates = r(n_duplicates)
    local keys `"`r(keys)'"'
    capture quietly restore

    if `rc' {
        exit `rc'
    }

    return scalar n_input = `n_input'
    return scalar n = `n_written'
    return scalar n_duplicates = `n_duplicates'
    return local keys `"`keys'"'
    return local outfile `"`outfile'"'
    return local format "`format'"
    return local lang "`lang'"
    return local escape = cond("`noescape'" == "", "latex", "none")

    di as text "Input entries: " as result `n_input'
    di as text "Duplicates removed: " as result `n_duplicates'
    di as text "Bibliography entries written: " as result `n_written'
    di as text "Output saved to: " as result `"`outfile'"'
    di as text "Format: " as result upper("`format'") ///
        as text "   Language: " as result upper("`lang'")
end


program define _reftex_core, rclass
    version 16
    syntax , INfile(string) OUTfile(string) FORMat(string) ///
        LANG(string) [REPLACE NODEDUPE NOESCAPE DEBug]

    tempfile entries outtmp
    tempname post_entries fh
    local marker_pattern "^\s*(\[[0-9]+\]|【[0-9]+】|[0-9]+[\.、])\s*"

    * A control-character delimiter makes each physical line one field while
    * preserving literal dollar signs and other macro-like text.
    local sep = char(31)
    quietly import delimited using `"`infile'"', delimiter("`sep'") ///
        encoding("utf-8") varnames(nonames) stringcols(1) clear
    quietly rename v1 text
    quietly gen long lineno = _n
    quietly replace text = subinstr(text, char(13), "", .)
    quietly replace text = subinstr(text, char(65279), "", .)
    quietly replace text = subinstr(text, char(36), "@@REFDOLLAR@@", .)
    quietly gen byte has_marker = ustrregexm(text, "`marker_pattern'")
    quietly count if has_marker
    local marker_count = r(N)

    postfile `post_entries' long entryid str2045 raw using `"`entries'"', replace
    local current ""
    local entryid = 0

    if `marker_count' > 0 {
        forvalues i = 1/`=_N' {
            local line = text[`i']
            local trimmed = ustrtrim(text[`i'])
            if has_marker[`i'] {
                if `"`current'"' != "" {
                    local ++entryid
                    post `post_entries' (`entryid') (`"`macval(current)'"')
                }
                local current `"`line'"'
            }
            else if `"`current'"' != "" & `"`trimmed'"' != "" {
                local current `"`current' `line'"'
            }
        }
        if `"`current'"' != "" {
            local ++entryid
            post `post_entries' (`entryid') (`"`macval(current)'"')
        }
    }
    else {
        forvalues i = 1/`=_N' {
            local trimmed = ustrtrim(text[`i'])
            if `"`trimmed'"' != "" {
                local ++entryid
                post `post_entries' (`entryid') (`"`trimmed'"')
            }
        }
    }
    postclose `post_entries'

    quietly use `"`entries'"', clear
    if _N == 0 {
        di as error "No bibliography entries were found."
        di as error "Use numbered entries such as [1] ... or one entry per nonblank line."
        exit 603
    }

    quietly gen long input_order = _n
    quietly gen strL clean = ""
    quietly gen str2045 authors = ""
    quietly gen str2045 title = ""
    quietly gen str2045 journal = ""
    quietly gen str4 year = ""
    quietly gen str80 volume = ""
    quietly gen str80 issue = ""
    quietly gen str80 pages = ""
    quietly gen str2045 doi = ""
    quietly gen str20 entrytype = "misc"
    quietly gen str2045 dedupe_key = ""
    quietly gen str2045 title_key = ""
    quietly gen str3 entry_lang = ""
    quietly gen str80 basekey = ""
    quietly gen str80 key = ""

    local noescape_flag = ("`noescape'" != "")
    forvalues i = 1/`=_N' {
        if "`debug'" != "" {
            di as text "Raw entry `i': [" as result raw[`i'] as text "]"
        }
        local entry = ustrtrim(raw[`i'])
        local entry = ustrregexra(`"`entry'"', "`marker_pattern'", "")
        local entry = ustrregexra(`"`entry'"', "\s+", " ")
        quietly replace clean = `"`entry'"' in `i'

        local authors ""
        local title ""
        local journal ""
        local rtype "misc"
        local year ""
        local volume ""
        local issue ""
        local pages ""
        local doi ""
        local generic_rest ""

        if ustrregexm(`"`entry'"', "^(.+?)[.．]\s*(.+?)\s*\[([A-Z/]+)\]") {
            local authors = ustrregexs(1)
            local title = ustrregexs(2)
            local rtype = lower(ustrregexs(3))
        }
        else if ustrregexm(`"`entry'"', "^(.+?)[.．]\s*([^.．]+)[.．]\s*(.+)$") {
            local authors = ustrregexs(1)
            local title = ustrregexs(2)
            local generic_rest = ustrregexs(3)
        }
        else if ustrregexm(`"`entry'"', "^(.+?)[.．]\s*(.+)$") {
            local authors = ustrregexs(1)
            local title = ustrregexs(2)
        }
        else {
            local title = `"`entry'"'
        }

        if inlist("`rtype'", "j", "j/ol") local rtype "article"
        else if inlist("`rtype'", "m", "m/ol") local rtype "book"
        else if inlist("`rtype'", "c", "c/ol") local rtype "inproceedings"
        else if inlist("`rtype'", "d") local rtype "phdthesis"
        else if inlist("`rtype'", "r") local rtype "techreport"
        else if !inlist("`rtype'", "article", "book", "inproceedings", ///
            "phdthesis", "techreport") local rtype "misc"

        if ustrregexm(`"`entry'"', "([12][0-9]{3})") {
            local year = ustrregexs(1)
        }

        if ustrregexm(`"`entry'"', "\[[A-Z/]+\][.．]?\s*([^,，]+)") {
            local journal = ustrregexs(1)
            local journal = ustrregexra(`"`journal'"', ///
                "\s*([12][0-9]{3}).*$", "")
            local journal = ustrregexra(`"`journal'"', "[.．,，\s]+$", "")
        }
        else if `"`generic_rest'"' != "" {
            if ustrregexm(`"`generic_rest'"', "^([^,，]+)") {
                local journal = ustrregexs(1)
                local journal = ustrregexra(`"`journal'"', ///
                    "\s*([12][0-9]{3}).*$", "")
                local journal = ustrtrim(`"`journal'"')
            }
        }

        if "`year'" != "" {
            local ypos = strpos(`"`entry'"', "`year'")
            local ytail = substr(`"`entry'"', `ypos' + 4, ///
                length(`"`entry'"') - `ypos' - 3)
            local ytail = ustrregexra(`"`ytail'"', "^\s*[,，]\s*", "")

            if ustrregexm(`"`ytail'"', ///
                "^([0-9]+)\s*\(\s*([^)]+)\s*\)\s*[:：]\s*([^\.。]+)") {
                local volume = ustrregexs(1)
                local issue = ustrregexs(2)
                local pages = ustrregexs(3)
            }
            else if ustrregexm(`"`ytail'"', ///
                "^([0-9]+)\s*[:：]\s*([^\.。]+)") {
                local volume = ustrregexs(1)
                local pages = ustrregexs(2)
            }
            else if ustrregexm(`"`ytail'"', ///
                "^\(\s*([^)]+)\s*\)\s*[:：]\s*([^\.。]+)") {
                local issue = ustrregexs(1)
                local pages = ustrregexs(2)
            }
            else if ustrregexm(`"`ytail'"', "^\s*([^\.。]+)") {
                local pages = ustrregexs(1)
            }
        }

        if ustrregexm(`"`entry'"', "10\.[0-9]{4,9}/[^[:space:],;，；]+") {
            local doi = ustrregexs(0)
            local doi = ustrregexra(`"`doi'"', "[.。),，]+$", "")
        }

        local authors = ustrregexra(`"`authors'"', ///
            "^[\s,，;；]+|[\s,，;；]+$", "")
        local title = ustrregexra(`"`title'"', "^[\s.．]+|[.．\s]+$", "")
        local journal = ustrtrim(`"`journal'"')
        local pages = ustrregexra(`"`pages'"', "[.．\s]+$", "")
        local pages = ustrregexra(`"`pages'"', "\s*[-–—]\s*", "--")

        local norm_title = lower(ustrregexra(`"`title'"', ///
            "[[:space:][:punct:]]", ""))
        local norm_full = lower(ustrregexra(`"`entry'"', ///
            "[[:space:][:punct:]]", ""))
        local entry_lang "`lang'"
        if "`lang'" == "mix" {
            if ustrregexm(`"`entry'"', "[\u4e00-\u9fff]") {
                local entry_lang "chn"
            }
            else local entry_lang "eng"
        }
        local dkey ""
        if `"`doi'"' != "" local dkey = "doi:" + lower(`"`doi'"')
        else if `"`norm_title'"' != "" {
            local dkey = "title:" + `"`norm_title'"' + "|" + "`year'"
        }
        else local dkey = "full:" + `"`norm_full'"'
        local dkey = substr(`"`dkey'"', 1, 2045)
        local tkey ""
        if `"`norm_title'"' != "" {
            local tkey = "title:" + `"`norm_title'"' + "|" + "`year'"
        }
        local tkey = substr(`"`tkey'"', 1, 2045)

        quietly replace authors = `"`authors'"' in `i'
        quietly replace title = `"`title'"' in `i'
        quietly replace journal = `"`journal'"' in `i'
        quietly replace year = "`year'" in `i'
        quietly replace volume = `"`volume'"' in `i'
        quietly replace issue = `"`issue'"' in `i'
        quietly replace pages = `"`pages'"' in `i'
        quietly replace doi = `"`doi'"' in `i'
        quietly replace entrytype = "`rtype'" in `i'
        quietly replace dedupe_key = `"`dkey'"' in `i'
        quietly replace title_key = `"`tkey'"' in `i'
        quietly replace entry_lang = "`entry_lang'" in `i'

        if "`debug'" != "" {
            di as text "Entry `i': type=`rtype' year=`year' title=" ///
                as result `"`title'"'
        }
    }

    quietly drop if ustrtrim(clean) == ""
    local n_input = _N

    if "`nodedupe'" == "" {
        quietly gen byte is_duplicate = 0
        quietly sort dedupe_key input_order
        quietly by dedupe_key: replace is_duplicate = 1 if ///
            (_n > 1) & (dedupe_key != "")
        quietly sort title_key input_order
        quietly by title_key: replace is_duplicate = 1 if ///
            (_n > 1) & (title_key != "")
        quietly count if is_duplicate
        local n_duplicates = r(N)
        if "`debug'" != "" & `n_duplicates' > 0 {
            di as text "Removing `n_duplicates' duplicate entries"
            list input_order title if is_duplicate, noobs clean
        }
        quietly drop if is_duplicate
    }
    else local n_duplicates = 0

    sort input_order
    if _N == 0 {
        di as error "All entries were duplicates; no output was written."
        exit 603
    }

    local n_written = _N
    quietly gen long outid = _n
    quietly gen str2045 first_author_text = ustrregexra(authors, "[,，;；].*$", "")
    quietly gen str80 author_ascii = lower(ustrregexra(first_author_text, ///
        "[^A-Za-z0-9]", ""))
    quietly replace author_ascii = substr(author_ascii, 1, 16)
    quietly replace basekey = author_ascii + year ///
        if author_ascii != "" & year != ""
    quietly replace basekey = "ref" + string(outid, "%04.0f") + year ///
        if basekey == ""
    quietly bysort basekey (input_order): gen int keyserial = _n
    quietly replace key = basekey if keyserial == 1
    quietly replace key = basekey + "_" + string(keyserial, "%02.0f") ///
        if keyserial > 1
    quietly sort input_order
    quietly drop first_author_text author_ascii outid keyserial

    if "`format'" == "tex" {
        local formatdesc "LaTeX thebibliography output"
    }
    else local formatdesc "BibTeX"
    file open `fh' using `"`outtmp'"', write text replace
    file write `fh' "% reftex v10.0 | `formatdesc'" _n
    file write `fh' "% Dingyuan Accounting: Scientific rigor and humanistic goodwill" _n
    file write `fh' "% Source entries: `n_input'; duplicates removed: `n_duplicates'; written: `n_written'" _n
    file write `fh' "% Generated `c(current_date)'. Verify bibliography details before submission." _n _n

    if "`format'" == "tex" {
        file write `fh' "\begin{thebibliography}{99}" _n
    }

    local keys ""
    forvalues i = 1/`=_N' {
        local authors = authors[`i']
        local title = title[`i']
        local journal = journal[`i']
        local year = year[`i']
        local volume = volume[`i']
        local issue = issue[`i']
        local pages = pages[`i']
        local doi = doi[`i']
        local rtype = entrytype[`i']
        local entry_lang = entry_lang[`i']
        local key = key[`i']
        local clean = clean[`i']
        local keys = `"`keys' `key'"'

        if `noescape_flag' {
            local authors_tex = subinstr(`"`authors'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local title_tex = subinstr(`"`title'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local journal_tex = subinstr(`"`journal'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local volume_tex = subinstr(`"`volume'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local issue_tex = subinstr(`"`issue'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local pages_tex = subinstr(`"`pages'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local doi_tex = subinstr(`"`doi'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
            local clean_tex = subinstr(`"`clean'"', ///
                "@@REFDOLLAR@@", "\char36{}", .)
        }

        local doi_bib = subinstr(`"`doi'"', ///
            "@@REFDOLLAR@@", "\char36{}", .)
        else {
            _reftex_escape `"`authors'"'
            local authors_tex = `"`r(escaped)'"'
            _reftex_escape `"`title'"'
            local title_tex = `"`r(escaped)'"'
            _reftex_escape `"`journal'"'
            local journal_tex = `"`r(escaped)'"'
            _reftex_escape `"`volume'"'
            local volume_tex = `"`r(escaped)'"'
            _reftex_escape `"`issue'"'
            local issue_tex = `"`r(escaped)'"'
            _reftex_escape `"`pages'"'
            local pages_tex = `"`r(escaped)'"'
            _reftex_escape `"`doi'"'
            local doi_tex = `"`r(escaped)'"'
            _reftex_escape `"`clean'"'
            local clean_tex = `"`r(escaped)'"'
        }

        if "`format'" == "tex" {
            local label `"`authors_tex' (`year')"'
            local label = subinstr(`"`label'"', "[", "{[}", .)
            local label = subinstr(`"`label'"', "]", "{]}", .)
            file write `fh' "\bibitem[`label']{`key'}" _n

            if `"`authors_tex'"' != "" & `"`year'"' != "" {
                local content `"`authors_tex' (`year'). `title_tex'"'
                if "`entry_lang'" == "chn" {
                    if "`rtype'" == "article" local content `"`content'[J]."'
                    else if "`rtype'" == "book" local content `"`content'[M]."'
                    else if "`rtype'" == "inproceedings" local content `"`content'[C]."'
                    else if "`rtype'" == "phdthesis" local content `"`content'[D]."'
                    else local content `"`content'."'
                }
                else local content `"`content'."'

                if `"`journal_tex'"' != "" {
                    local content `"`content' \textit{`journal_tex'}, `year'"'
                }

                if `"`volume_tex'"' != "" {
                    local content `"`content', `volume_tex'"'
                    if `"`issue_tex'"' != "" {
                        local content `"`content'(`issue_tex')"'
                    }
                }
                else if `"`issue_tex'"' != "" {
                    local content `"`content'(`issue_tex')"'
                }
                if `"`pages_tex'"' != "" local content `"`content': `pages_tex'"'
                local content `"`content'."'
            }
            else local content `"`clean_tex'"'

            if `"`doi_tex'"' != "" {
                local content `"`content' DOI: `doi_tex'."'
            }
            file write `fh' `"`content'"' _n
        }
        else {
            local author_list = subinstr(`"`authors_tex'"', ";", "|", .)
            local author_list = subinstr(`"`author_list'"', "；", "|", .)
            local author_list = subinstr(`"`author_list'"', ",", "|", .)
            local author_list = subinstr(`"`author_list'"', "，", "|", .)
            local author_list = subinstr(`"`author_list'"', " and ", "|", .)
            local authors_bib = ""
            while `"`author_list'"' != "" {
                gettoken one_author author_list : author_list, parse("|")
                local one_author = ustrtrim(`"`one_author'"')
                if `"`one_author'"' != "" & `"`one_author'"' != "|" {
                    if `"`authors_bib'"' == "" {
                        local authors_bib `"{`one_author'}"'
                    }
                    else {
                        local authors_bib `"`authors_bib' and {`one_author'}"'
                    }
                }
            }

            file write `fh' "@`rtype'{`key'," _n
            if `"`authors_bib'"' != "" ///
                file write `fh' "  author = {`authors_bib'}," _n
            if `"`title_tex'"' != "" ///
                file write `fh' "  title = {`title_tex'}," _n
            if inlist("`rtype'", "article", "inproceedings") {
                if `"`journal_tex'"' != "" {
                    if "`rtype'" == "article" {
                        file write `fh' "  journal = {`journal_tex'}," _n
                    }
                    else file write `fh' "  booktitle = {`journal_tex'}," _n
                }
            }
            if "`year'" != "" file write `fh' "  year = {`year'}," _n
            if `"`volume_tex'"' != "" ///
                file write `fh' "  volume = {`volume_tex'}," _n
            if `"`issue_tex'"' != "" ///
                file write `fh' "  number = {`issue_tex'}," _n
            if `"`pages_tex'"' != "" ///
                file write `fh' "  pages = {`pages_tex'}," _n
            if `"`doi'"' != "" ///
                file write `fh' "  doi = {`doi_bib'}," _n
            file write `fh' "}" _n _n
        }
    }

    if "`format'" == "tex" {
        file write `fh' "\end{thebibliography}" _n
    }
    file close `fh'

    capture confirm file `"`outfile'"'
    if _rc == 0 capture quietly copy `"`outtmp'"' `"`outfile'"', replace
    else capture quietly copy `"`outtmp'"' `"`outfile'"'
    if _rc {
        di as error `"Could not write output file: `outfile'"'
        exit _rc
    }

    return scalar n_input = `n_input'
    return scalar n = `n_written'
    return scalar n_duplicates = `n_duplicates'
    return local keys `"`keys'"'
end


* Compatibility helper retained for earlier scripts that called this name.
program define convert_bibliography
    version 16
    args infile outfile debug replace_option lang
    local opts `"outfile(`"`outfile'"') lang("`lang'")"'
    if "`replace_option'" != "" local opts `"`opts' replace"'
    if "`debug'" != "" local opts `"`opts' debug"'
    reftex using `"`infile'"', `opts'
end
