*! esgdict.ado -- Machine-learning ESG dictionary generator for qta.ado
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
*! esgdict learns the built-in E / S / G / General_ESG dictionary that qta.ado
*! needs directly from a corpus of ESG reports, instead of asking the user to
*! hard-code keywords.  Three reproducible machine-learning strategies are
*! available through method():
*!
*!   npmi     (default) normalised point-wise mutual information seed
*!            expansion -- a distributional-semantics lexicon learner that
*!            scores every candidate term by its local co-occurrence with a
*!            curated seed vocabulary.
*!   kmeans   latent semantic analysis (truncated SVD of the TF-IDF term
*!            space) followed by k-means clustering; clusters are matched to
*!            the four ESG dimensions with a Hungarian assignment against seed
*!            centroids.
*!   hybrid   average of the standardised npmi and kmeans scores.
*!
*! Syntax
*!   esgdict using "esgdict_cn.txt" [, corpus(...) language(cn) options]
*!
*! Examples
*!   esgdict using "esgdict_cn.txt", corpus("ESG_text_data.csv") ///
*!       textcol(ESGreport) language(cn) top(45) minfreq(15) replace
*!
*!   use esg_text.dta, clear
*!   esgdict using "esgdict_en.txt", textvar(ESGreport) language(en) replace
*!
*! The resulting file is consumed by qta:  qta, esgdictionary("esgdict_cn.txt")
*!
*! See also: qta, wordfreq

program define esgdict, rclass
    version 16.0

    syntax [using/] [, CORPUS(string) TEXTCol(string) TEXTDir(string) TXTVAR(string) ///
        LANGuage(string) METHOD(string) TOPics(integer 8) TOP(integer 45)              ///
        MINFreq(integer 15) MAXDF(real 0.98) MINSeed(integer 6) WINDow(integer 6)      ///
        MINCo(integer 8) MARGIN(real 0.02) SEEDs(string) COHESION REPORT(string)       ///
        SCRIPT(string) PYthon(string) MAXChars(integer 40000000) SHOW                  ///
        VERBose REPLACE ]

    *=====================================================================
    * 0.  Validation
    *=====================================================================
    if `"`using'"' == "" {
        di as error "esgdict requires an output file: esgdict using filename, ..."
        exit 198
    }
    if !ustrregexm(`"`using'"', "^([A-Za-z]:|[A-Za-z]:/|/)") {
        local using "`c(pwd)'/`using'"
    }

    if "`language'" == "" local language "cn"
    local language = lower("`language'")
    if inlist("`language'", "zh", "chinese", "cn") local language "cn"
    if inlist("`language'", "eng", "english", "en") local language "en"
    if !inlist("`language'", "cn", "en") {
        di as error "language() must be cn or en"
        exit 198
    }

    if "`method'" == "" local method "npmi"
    local method = lower("`method'")
    if !inlist("`method'", "npmi", "kmeans", "hybrid") {
        di as error "method() must be npmi, kmeans or hybrid"
        exit 198
    }

    if "`textcol'" == "" local textcol "ESGreport"

    * ---- corpus source --------------------------------------------------
    local corpusfile ""
    if "`textvar'" != "" {
        confirm string variable `textvar'
        local corpusfile "`c(tmpdir)'esgdict_corpus.csv"
        preserve
        quietly export delimited `textvar' using "`corpusfile'", replace
        restore
        di as txt "esgdict: exported `textvar' to a temporary corpus"
    }
    else if "`corpus'" != "" {
        local corpusfile `"`corpus'"'
    }
    else if "`textdir'" != "" {
        local corpusfile `"`textdir'"'
    }
    else {
        di as error "no corpus: use corpus(), textdir() or textvar()"
        exit 198
    }

    cap confirm file `"`corpusfile'"'
    if _rc {
        capture quietly dir `"`corpusfile'"'
        if _rc {
            di as error "corpus not found: `corpusfile'"
            exit 601
        }
    }

    * ---- locate the Python helper ---------------------------------------
    if "`script'" == "" {
        cap findfile esgdict_ml.py
        if _rc {
            di as error "helper esgdict_ml.py not found on the adopath."
            di as error "Keep it in the folder that holds esgdict.ado, or use script()."
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
        if "${ESGDICT_PYTHON}" != "" local python "${ESGDICT_PYTHON}"
        else                         local python "python"
    }

    if "`report'" != "" {
        if !ustrregexm(`"`report'"', "^([A-Za-z]:|[A-Za-z]:/|/)") {
            local report "`c(pwd)'/`report'"
        }
    }

    * ---- output-file overwrite protection --------------------------------
    cap confirm file `"`using'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "file `using' already exists"
        di as error "use the {bf:replace} option to overwrite it"
        exit 602
    }

    *=====================================================================
    * 1.  Build the job specification and run the helper
    *=====================================================================
    tempname jfh
    local spec    "`c(tmpdir)'esgdict_job.txt"
    local status  "`using'.status"
    local logfile "`c(tmpdir)'esgdict_py.log"

    quietly capture erase "`status'"
    quietly capture erase "`logfile'"

    file open `jfh' using "`spec'", write text replace
    file write `jfh' "corpus = `corpusfile'"            _n
    file write `jfh' "textcol = `textcol'"              _n
    file write `jfh' "lang = `language'"                _n
    file write `jfh' "method = `method'"                _n
    file write `jfh' "topics = `topics'"                _n
    file write `jfh' "top = `top'"                      _n
    file write `jfh' "minfreq = `minfreq'"              _n
    file write `jfh' "maxdf = `maxdf'"                  _n
    file write `jfh' "minseed = `minseed'"              _n
    file write `jfh' "window = `window'"                _n
    file write `jfh' "minco = `minco'"                  _n
    file write `jfh' "margin = `margin'"                _n
    file write `jfh' "maxchars = `maxchars'"            _n
    if "`cohesion'" != ""  file write `jfh' "cohesion = 1"           _n
    if "`seeds'" != ""     file write `jfh' "seeds = `seeds'"        _n
    if "`report'" != ""    file write `jfh' "report = `report'"      _n
    file write `jfh' "out = `using'"                    _n
    file close `jfh'

    local pycmd `""`python'" "`script'" --spec "`spec'" > "`logfile'" 2>&1"'
    if "`verbose'" != "" {
        di as txt `"esgdict: `python' `script' --spec `spec'"'
        shell `pycmd' 
    }
    else {
        quietly shell `pycmd'
    }

    *=====================================================================
    * 2.  Check status
    *=====================================================================
    cap confirm file "`status'"
    if _rc {
        di as error "esgdict: the Python helper produced no output."
        di as error "Confirm that `python' exists and has scikit-learn, scipy,"
        di as error "numpy and (for Chinese) jieba installed, e.g."
        di as error `"   `python' -m pip install scikit-learn scipy jieba pandas"'
        cap type "`logfile'"
        exit 601
    }
    tempname sfh
    local statusline ""
    local detail ""
    file open `sfh' using "`status'", read text
    file read `sfh' line
    local statusline `"`line'"'
    file read `sfh' line
    local detail `"`line'"'
    file close `sfh'
    if trim("`statusline'") != "OK" {
        di as error "esgdict: dictionary learning failed."
        cap type "`logfile'"
        di as error "status: `detail'"
        exit 459
    }
    quietly capture erase "`status'"
    local detail2 : subinstr local detail "{" "(", all
    local detail2 : subinstr local detail2 "}" ")", all
    local detail2 : subinstr local detail2 `"""' "'", all
    di as txt "esgdict: dictionary written to `using'"
    di as txt `"        summary: `detail2'"'

    *=====================================================================
    * 3.  Summarise and optionally display the dictionary
    *=====================================================================
    tempname dh
    local dim ""
    local n_env = 0
    local n_soc = 0
    local n_gov = 0
    local n_gen = 0
    file open `dh' using "`using'", read text
    file read `dh' line
    while r(eof) == 0 {
        local l = strtrim(`"`line'"')
        if ustrregexm(`"`l'"', "^(Environmental|Social|Governance|General_ESG)$") {
            local dim "`l'"
        }
        else if `"`l'"' != "" & !ustrregexm(`"`l'"', "^#") & "`dim'" != "" {
            if "`dim'" == "Environmental" local ++n_env
            if "`dim'" == "Social"        local ++n_soc
            if "`dim'" == "Governance"    local ++n_gov
            if "`dim'" == "General_ESG"   local ++n_gen
        }
        file read `dh' line
    }
    file close `dh'

    di _n as txt "Machine-learning ESG dictionary (`method' method, `language')"
    di as txt "  Environmental : `n_env' terms"
    di as txt "  Social        : `n_soc' terms"
    di as txt "  Governance    : `n_gov' terms"
    di as txt "  General_ESG   : `n_gen' terms"
    local ntot = `n_env' + `n_soc' + `n_gov' + `n_gen'
    di as txt "  total         : `ntot' terms"

    return local  dictionary "`using'"
    return local  method     "`method'"
    return local  language   "`language'"
    return scalar n_env = `n_env'
    return scalar n_soc = `n_soc'
    return scalar n_gov = `n_gov'
    return scalar n_gen = `n_gen'

    if "`show'" != "" {
        di _n as txt "{hline 60}"
        type "`using'"
        di as txt "{hline 60}"
    }
end
