*! wordfreq.ado -- Bilingual (Chinese / English) keyword-frequency analysis
*!                 for PDF report corpora and in-memory text variables
*!
*! Version 1.0.0   06 October 2026
*! Authors
*!   WU Lianghai   School of Business, Anhui University of Technology (AHUT),
*!                 Ma'anshan, Anhui, China            agd2010@yeah.net
*!   WU Hanyan     Department of Accountancy, City University of Hong Kong (CityU)
*!                                                    2325476320@qq.com
*!   XU Huihui     School of Business, Anhui University of Technology (AHUT),
*!                 Ma'anshan, Anhui, China            2847844621@qq.com
*!
*! wordfreq batch-reads the PDF (or already extracted .txt) files found under
*! a user-supplied folder, counts how often each user keyword occurs in every
*! document, and returns a Stata dataset with one observation per document and
*! one word-frequency variable per keyword.  Chinese and English are supported.
*!
*! Syntax
*!   wordfreq [using/] , KEYWords(string) [options]
*!
*! Examples
*!   wordfreq using "kwf_panel.dta", path("E:\ESG_reports")            ///
*!       keywords("环境保护,碳排放,员工,董事会") language(cn) replace
*!
*!   use esg_text.dta, clear
*!   wordfreq, textvar(ESGreport) keywords("环境保护,碳排放") name(env)
*!
*! See also: qta, esgdict

program define wordfreq, rclass
    version 16.0

    syntax [using/] [, PATH(string) PATTERN(string) KEYWords(string) KWFile(string) ///
        LANGuage(string) TEXTVAR(string) NAME(string) NORMalize(real 0)          ///
        PYthon(string) SCRIPT(string) CACHEdir(string) WORKers(integer 4)        ///
        MERge NOSUBdir VERBose REPLACE ]

    *=====================================================================
    * 0.  Defaults and validation
    *=====================================================================
    if "`language'" == "" local language "cn"
    local language = lower("`language'")
    if inlist("`language'", "zh", "chinese", "cn") local language "cn"
    if inlist("`language'", "eng", "english", "en") local language "en"
    if !inlist("`language'", "cn", "en") {
        di as error "language() must be cn (Chinese) or en (English)"
        exit 198
    }

    if "`pattern'" == "" local pattern "*.pdf"
    if "`name'"    == "" local name "wordfreq"
    if `workers'   <  1  local workers 1

    if "`kwfile'" != "" {
        cap confirm file "`kwfile'"
        if _rc {
            di as error "kwfile() not found: `kwfile'"
            exit 601
        }
    }

    * ---- collect the keyword list (comma separated, or one per line) ----
    local kw_all `"`keywords'"'
    local nkw 0

    local rest `"`kw_all'"'
    while (`"`rest'"' != "") {
        gettoken tok rest2 : rest, parse(",")
        local rest `"`rest2'"'
        if (`"`tok'"' == ",") continue
        local tok = strtrim(`"`tok'"')
        if (`"`tok'"' == "") continue
        local ++nkw
        local kw`nkw' `"`tok'"'
    }

    if "`kwfile'" != "" {
        tempname kfh
        file open `kfh' using "`kwfile'", read text
        file read `kfh' line
        while r(eof) == 0 {
            local tok = strtrim(`"`line'"')
            if (`"`tok'"' != "") {
                local ++nkw
                local kw`nkw' `"`tok'"'
            }
            file read `kfh' line
        }
        file close `kfh'
    }

    if `nkw' == 0 {
        di as error "no keyword supplied: use keywords(\"...\") or kwfile(\"...\")"
        exit 198
    }

    return local  keywords  "`kw_all'"
    return scalar nkeywords = `nkw'
    return local  language  "`language'"

    *=====================================================================
    * 1.  In-memory mode: count inside a text variable (no PDF, no Python)
    *=====================================================================
    if "`textvar'" != "" {
        confirm string variable `textvar'
        if "`merge'" != "" {
            di as error "merge is not allowed together with textvar()"
            exit 198
        }

        tempvar txt nwords
        quietly gen `txt' = `textvar'
        if "`language'" == "en" {
            quietly replace `txt' = lower(`txt')
            quietly replace `txt' = ustrregexra(`txt', "[^a-z0-9]+", " ")
            quietly replace `txt' = " " + strtrim(`txt') + " "
        }

        forvalues i = 1/`nkw' {
            local ni "kw`i'"
            local w  ``ni''
            if "`language'" == "en" {
                local lw = lower(`"`w'"')
                quietly gen double `name'_`i' =                                   ///
                    (length(`txt') - length(subinstr(`txt', " `lw' ", " ", .))) / ///
                    (length("`lw'") + 1)
            }
            else {
                quietly gen double `name'_`i' =                                   ///
                    (length(`txt') - length(subinstr(`txt', `"`w'"', "", .))) /  ///
                    length(`"`w'"')
            }
            label variable `name'_`i' "Word frequency of `w' (`language')"
        }

        quietly gen double `name' = 0
        forvalues i = 1/`nkw' {
            quietly replace `name' = `name' + `name'_`i'
        }
        label variable `name' "Total keyword frequency (`nkw' keywords, `language')"

        if `normalize' > 0 {
            quietly gen double `nwords' = ustrlen(`txt')
            quietly gen double `name'_per = `normalize' * `name' / `nwords'
            quietly replace `name'_per = 0 if missing(`name'_per)
            label variable `name'_per "Keyword frequency per `normalize' characters (`language')"
        }

        quietly count if `name' > 0
        return scalar nmatched = r(N)
        return scalar nobs     = _N
        return local  varlist  "`name'"
        di as txt "wordfreq: `nkw' keyword(s) counted in `textvar' (N = " _N ")"
        exit
    }

    *=====================================================================
    * 2.  Corpus mode: batch-read PDF / txt files from a folder
    *=====================================================================
    if "`path'" == "" {
        di as error "path() is required when textvar() is not specified"
        exit 198
    }
    cap confirm file "`path'"
    if _rc {
        capture quietly dir "`path'"
        if _rc {
            di as error "path() not found: `path'"
            exit 601
        }
    }

    * ---- locate the Python helper ---------------------------------------
    if "`script'" == "" {
        cap findfile wordfreq_pdf.py
        if _rc {
            di as error "helper wordfreq_pdf.py not found on the adopath."
            di as error "Keep wordfreq_pdf.py in the folder that holds wordfreq.ado"
            di as error "and add that folder to the adopath, or use script()."
            exit 601
        }
        local script "`r(fn)'"
    }
    else {
        cap confirm file "`script'"
        if _rc {
            di as error "script() not found: `script'"
            exit 601
        }
    }

    if "`python'" == "" {
        if "${WORDFREQ_PYTHON}" != "" local python "${WORDFREQ_PYTHON}"
        else                        local python "python"
    }

    if "`cachedir'" == "" local cachedir "`c(tmpdir)'wordfreq_cache"
    local recursive 1
    if "`nosubdir'" != "" local recursive 0

    * ---- build the job specification ------------------------------------
    tempname jfh
    local spec    "`c(tmpdir)'wordfreq_job.txt"
    local outcsv  "`c(tmpdir)'wordfreq_out.csv"
    local logfile "`c(tmpdir)'wordfreq_py.log"

    quietly capture erase "`outcsv'"
    quietly capture erase "`outcsv'.status"
    quietly capture erase "`logfile'"

    file open `jfh' using "`spec'", write text replace
    file write `jfh' "cmd = count"                    _n
    file write `jfh' "path = `path'"                  _n
    file write `jfh' "pattern = `pattern'"            _n
    file write `jfh' "lang = `language'"              _n
    file write `jfh' "workers = `workers'"            _n
    file write `jfh' "recursive = `recursive'"        _n
    file write `jfh' "cache = `cachedir'"             _n
    file write `jfh' "out = `outcsv'"                 _n
    forvalues i = 1/`nkw' {
        local ni "kw`i'"
        file write `jfh' "keyword = ``ni''"           _n
    }
    file close `jfh'

    * ---- run the helper --------------------------------------------------
    local pycmd `""`python'" "`script'" --spec "`spec'" > "`logfile'" 2>&1"'
    if "`verbose'" != "" {
        di as txt `"wordfreq: `python' `script' --spec `spec'"'
        shell `pycmd'
    }
    else {
        quietly shell `pycmd'
    }

    * ---- check the status side-car ---------------------------------------
    cap confirm file "`outcsv'.status"
    if _rc {
        di as error "wordfreq: the Python helper produced no output."
        di as error "Confirm that `python' exists and has pypdf installed:"
        di as error `"   `python' -m pip install pypdf pdfminer.six"'
        cap type "`logfile'"
        exit 601
    }
    tempname sfh
    local statusline ""
    file open `sfh' using "`outcsv'.status", read text
    file read `sfh' line
    local statusline `"`line'"'
    file close `sfh'
    if trim("`statusline'") != "OK" {
        di as error "wordfreq: PDF extraction / counting failed."
        cap type "`logfile'"
        di as error "status: `statusline'"
        exit 459
    }

    * ---- read the tidy result --------------------------------------------
    tempfile wfres
    if "`merge'" != "" preserve
    import delimited using "`outcsv'", clear varnames(1) encoding("utf-8") stringcols(1 3)
    forvalues i = 1/`nkw' {
        local ni "kw`i'"
        capture rename wf`i' `name'_`i'
        capture label variable `name'_`i' "Word frequency of ``ni'' (`language')"
    }
    capture rename wf_total `name'
    capture label variable `name' "Total keyword frequency (`nkw' keywords, `language')"
    capture label variable stkcd    "Stock code"
    capture label variable year     "Year"
    capture label variable filename "Source document"
    capture label variable n_chars  "Number of characters in the document"
    capture label variable n_words  "Number of words (en) / Chinese characters (cn)"

    if `normalize' > 0 {
        capture gen double `name'_per = `normalize' * `name' / n_words
        capture label variable `name'_per "Keyword frequency per `normalize' words/characters"
    }

    if "`merge'" != "" {
        quietly save `wfres'
        restore
        capture merge 1:1 stkcd year using `wfres', keep(master match) nogenerate
        if _rc {
            di as error "merge failed: stkcd and year must exist in memory and match"
            exit _rc
        }
        di as txt "wordfreq: word-frequency variables merged 1:1 by stkcd and year"
    }

    quietly count
    return scalar ndocs   = r(N)
    return local  varlist "`name'"
    di as txt "wordfreq: `nkw' keyword(s) counted over " r(N) " document(s)" ///
        " (`language'); new variable: `name'"

    * ---- save if a filename was supplied ----------------------------------
    if `"`using'"' != "" {
        if "`replace'" == "" {
            cap confirm file `"`using'"'
            if _rc == 0 {
                di as error "file `using' already exists"
                di as error "use the {bf:replace} option to overwrite it"
                exit 602
            }
        }
        save `"`using'"', replace
        di as txt "wordfreq: dataset saved to `using'"
    }
end
